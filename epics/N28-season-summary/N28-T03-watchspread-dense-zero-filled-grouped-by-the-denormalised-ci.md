# N28-T03 — `watchSpread` — dense, zero-filled, grouped by the denormalised civil date

| | |
|---|---|
| **Epic** | [N28 — Season Summary](epic.md) · `00-README` §9 step 10 (3 of 4) |
| **Task** | 3 of 6 |
| **Depends on** | N28-T02 |
| **Commit** | one commit · `feat(season): watchSpread, dense and grouped by the stored civil date` |

## 1. Why this task exists

Grouped by the **denormalised local civil date** column — not computed from an instant at
query time, which would put a 23:40 lambing on the wrong day for a reader in another zone and would
make the group-by unindexable.

SQLite cannot bucket by the shepherd's civil day without a timezone database. Dart can, and did, at
write time (decision #47). Getting this wrong is a once-per-night off-by-one for a whole season, and
it is invisible: the chart still draws, the totals still add up, and every bar is in the wrong
column.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §6.9 | `watchSpread`'s statement, `DayBirths`, the four spread rules, the two `local_date` invariants |
| `docs/engineering/07-screens.md` | §12.3 | the bucketing key, the cycle line, and why it is not a SQL date function |
| `shed-book-spec.md` | §7.8 | lambing percentage, litter size, barren and assisted rates, losses, spread |
| `docs/engineering/03-data-model-and-schema.md` | §5.4 | `lambings.local_date`, its `GLOB` `CHECK` and `idx_lambing_localdate` |
| `docs/engineering/CONVENTIONS.md` | §1.1 rule 3, §3.2, §4.3, R18, R33 | what `lib/data/` may import, where a read provider lives, and how it is named |
| `docs/engineering/12-testing.md` | §5, §11.4 | the in-memory harness and the `uk-zone` run |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | the denormalised column, its index and the grouping |
| `shed-domain` | the dense zero-filled shape from N06-T06 |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/season_summary_test.dart`
- **Test** — `'the spread groups by the stored civil date and includes every day with zero births'`
- **Why it is red today** — nothing queries the spread, so the chart in T04 has no data and N06-T06's dense zero-fill has no caller.

```bash
fvm flutter test test/features/season_summary_test.dart   # expect: failing, for the reason above
```

Make the assertion carry both halves: seed lambings on 14, 16 and 17 March only, then assert
`bars` has **four** entries — 14, 15, 16, 17 — with `bars[1].births == 0`. A test that only checks
the three populated days passes against a sparse result, and sparseness is the defect: the gaps
*are* the information.

**Green.** The minimum code that passes, and nothing beyond it — the statement over the denormalised column, and the dense fill applied in the domain.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8's order

| # | File | What changes, and why |
|---|---|---|
| 1 | — **no schema step** | `lambings.local_date` and `idx_lambing_localdate` (`{season, localDate}`) were frozen in N07. This task adds no column and no index; if you are adding an index, the schema is wrong, not the query. Say so in the commit message |
| 2 | — no domain step | `DayBirths` and `lambingSpread(...)` shipped in N06. Touch `lib/domain/stats/lambing_spread.dart` only to add the value equality named in §5.3 gotcha 4 if N06 left it out |
| 3 | `lib/data/season_repository.dart` | Add `watchSpread(SeasonId season)`, beside `watchSeasonCounts`. Same repository, same reason (R18) |
| 4 | `lib/features/season/season_controller.dart` | Add the spread read provider — **and the CONVENTIONS §6 ruling that names it** (§5.3 gotcha 1). Also thread `app_settings.cycle_days` from `settingsProvider` into `SeasonSummaryState` |
| 5 | `lib/features/season/season_summary_screen.dart` | The cycle line under where the chart will go: *"32 of 48 ewes lambed in the first 17 days"* — a fact, never a judgement. The chart itself is T04 |
| 6 | `lib/l10n/app_en.arb` | The cycle-line message, with placeholders for both counts and the day count, each an ICU plural |
| 7 | `test/data/season_repository_test.dart` | Extended: the statement, the index, the DST cases |
| 8 | `test/features/season_summary_test.dart` | The anchor, extended. Written before all of the above |

### 5.2 The signatures

```dart
// lib/data/season_repository.dart — the second SeasonRepository read (R18, R33).
Stream<List<DayBirths>> watchSpread(SeasonId season) => db
    .customSelect(
      'SELECT l.local_date AS d, COUNT(lb.id) AS births, COUNT(DISTINCT l.ewe) AS ewes '
      'FROM lambings l LEFT JOIN lambs lb ON lb.lambing = l.id '
      'WHERE l.season = ?1 '
      'GROUP BY l.local_date ORDER BY l.local_date',
      variables: [Variable<int>(season.value)],
      readsFrom: {db.lambings, db.lambs},
    )
    .watch()
    .map((rows) => rows
        .map((r) => DayBirths(LocalDate.parse(r.read<String>('d')),
            r.read<int>('births'), r.read<int>('ewes')))
        .toList())
    .distinct(const ListEquality<DayBirths>().equals);   // package:collection — see gotcha 3
```

```dart
// lib/domain/stats/lambing_spread.dart — built in N06. The dense fill is HERE,
// not in SQL: a GROUP BY cannot invent a day that has no row.
({List<({LocalDate date, int dayIndex, int births, int ewes})> bars,
  int? ewesInFirstCycleDays,
  int cycleDays}) lambingSpread(List<DayBirths> rows, {int cycleDays = 17});
```

The provider follows §4.3 — read providers are named after **what they read**, never after the
screen — and lives beside `seasonFactsProvider`:

```dart
// lib/features/season/season_controller.dart
final seasonSpreadProvider =
    StreamProvider.autoDispose.family<List<DayBirths>, SeasonId>((ref, season) async* {
  final repo = await ref.watch(seasonRepositoryProvider.future);
  yield* repo.watchSpread(season);
});
```

### 5.3 The details that are easy to get wrong

1. **This provider is not in the naming authority, and shipping it unruled is the defect.**
   CONVENTIONS §3.2 lists exactly one Season Summary read provider, `seasonFactsProvider`. It has no
   row for the spread, and §3.2 is the complete catalogue. The name above follows §4.3's rule, but a
   name that is not in the catalogue is exactly the failure R26, R28 and R18 exist to prevent. **The
   first half of this commit is a numbered ruling in CONVENTIONS §6** adding the row to §3.2 and
   listing the files it touches, per the amendment rule (`CLAUDE.md`, rule 3). Do not skip it because
   it feels like paperwork; the next person greps §3.2 and finds nothing.

2. **`GROUP BY l.local_date`, never a date function on the instant.** Gate rows `time.sql_now_1` and
   `time.sql_now_2` catch `date('now')` and `datetime('now')`, but they do **not** catch
   `date(l.occurred_at / 1000, 'unixepoch')` — which is the tidy-looking, always-UTC, always-wrong
   version. `l.local_date` is the shepherd's day as it was lived, and it is indexed;
   `date(occurred_at…)` is neither.

3. **`listEquals` from `package:flutter/foundation.dart` does not belong in `lib/data/`.**
   05 §6.9's printed line reaches for it, and layer rule 3's import list for `lib/data/` does not
   include `package:flutter/*` at all — rule 4 bans only `material.dart` and `cupertino.dart`, so
   the ambiguity is real and the safe move is unambiguous: `package:collection` **is** on rule 3's
   list, so use `const ListEquality<DayBirths>().equals`. (In `lib/core/ui/`, layer rule 7 permits
   `package:flutter/*`, so T04's painter may use `listEquals` freely. Same idea, two layers, two
   spellings.)

4. **A bare `.distinct()` over a `List` compares list *identity* and filters nothing.** Two things
   are needed and both are easy to half-do: `DayBirths` writes its own `==`/`hashCode`, **and** the
   list comparison is element-wise. Get one without the other and the chart repaints on every write
   to `lambings` or `lambs` — which, during lambing, is every few minutes.

5. **`COUNT(lb.id)` and `COUNT(DISTINCT l.ewe)` are different numbers and both are needed.** Bar
   height is *lambs*; the first-cycle figure counts *ewes*. `COUNT(lb.id)` over a `LEFT JOIN`
   correctly yields `0` for a lambing with no lambs attached, which is the decision #11 state and
   must not be filtered out — the lambing happened, the lambs are not entered yet.

6. **The dense zero-fill happens in Dart, in the domain, and cannot happen in SQL.** A `GROUP BY`
   returns only days that have a row. Reaching for a recursive CTE to generate a calendar is a
   correct instinct in another product and the wrong one here: `lambingSpread` already does it, it
   is pure, and it is the tier with the thickest tests.

7. **`cycleDays` is always passed explicitly.** The `= 17` in the signature exists only so a unit
   test can omit it; the app always passes `app_settings.cycle_days`, whose column default is 17 with
   `CHECK (cycle_days BETWEEN 1 AND 60)`. Two defaults that can drift apart is one too many.

8. **`dayIndex` anchors on the first lambing, not on the season start.** It exists so T05's
   comparison lines two seasons up row for row from day 0. Anchoring on `seasons.start_date` looks
   more principled and breaks the comparison the moment two seasons start on different weekdays.

9. **`local_date` is never recomputed for historical rows.** If the device zone changes between
   insert and read, leave them: `local_date` is a record of the shepherd's day as it was lived. A
   disagreement surfaces as `WarningCode.localDateDisagrees`, which is *surfaced, not repaired*
   (§12.4).

10. **Two lambings a season apart on the same civil date are two different bars.** The `WHERE
    l.season = ?1` clause is what keeps them apart; there is no `DISTINCT` on `local_date` across
    seasons and there must not be.

11. **`LocalDate.parse` is strict and throws.** The column carries
    `CHECK (local_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')`, so a throw here means the
    schema was bypassed — do not soften the parse to a `tryParse` that returns null and lets a bar
    vanish.

### 5.4 The full test set

**`test/data/season_repository_test.dart`** — against `NativeDatabase.memory()`:

| Case | Asserts |
|---|---|
| `'watchSpread groups by local_date and returns one row per populated day'` | three lambings on two days yield two rows |
| `'watchSpread counts lambs for height and distinct ewes separately'` | a day with two ewes and five lambs reads `births == 5`, `ewes == 2` |
| `'a lambing with no lambs yields a row with births zero'` | the decision #11 state survives the `LEFT JOIN` |
| `'the statement is served by idx_lambing_localdate'` | `EXPLAIN QUERY PLAN` output names the index and contains no `SCAN lambings` |
| `'watchSpread re-emits when a lamb is attached'` | `db.lambs` is in `readsFrom:` |
| `'an unrelated write does not re-emit an equal list'` | element-wise `.distinct()` |
| `'two seasons sharing a civil date do not merge'` | season scoping |

**`test/features/season_summary_test.dart`**:

| Case | Asserts |
|---|---|
| the anchor | dense, zero-filled: gaps present as zero-birth days |
| `'a season with no lambings yields empty bars and a null first-cycle figure'` | 05 §6.9's edge case; no zero-height chart and no spinner |
| `'the cycle line reads the settings value and never a literal 17'` | set `cycle_days` to 21 and assert the rendered sentence says 21 |
| `'the cycle line states a fact and never a judgement'` | copy assertion — no evaluative word in the string |
| `'the first-cycle figure counts ewes and the bars count lambs, and both are labelled'` | the two numbers are not interchangeable |

**Time-shaped cases — tag the group `@Tags(['uk-zone'])`**, so
`TZ=Europe/London fvm flutter test --tags uk-zone` runs them. UK/Ireland is first, so the ambiguous
hour is **01:00–01:59** and the 2026 dates are 29 March (spring forward) and 25 October (clocks
back):

| Case | Asserts |
|---|---|
| `'a lambing at 01:30 BST on 25 Oct 2026 buckets to 25 October'` | not 24; the stored `local_date`, not a recomputation |
| `'a lambing at 01:30 GMT on 25 Oct 2026 buckets to 25 October as well'` | the repeated hour yields one bar with two births, not two bars |
| `'a lambing at 23:55 on 24 Oct 2026 buckets to 24 October'` | the boundary the UTC version gets wrong |
| `'a lambing at 00:05 on 25 Oct 2026 buckets to 25 October'` | the other side of the same boundary |
| `'a lambing at 01:30 on 29 Mar 2026 appears in exactly one bar'` | the spring-forward gap removes no row from the spread |

The point of every one of these is the same: the query reads a stored `TEXT` civil date and never
derives one, so the zone can move under it and the bars do not.

## 6. Constraints that bind this task

- **Group by the denormalised `local_date`, never by UTC and never by a SQL date function** (05 §6.9 rule 1). A 00:05 lambing belongs to that day; a 23:55 one to the day before.
- **Dense and zero-filled** (rule 2) — a gap day renders as a zero bar rather than being skipped.
- **Anchored on the first lambing with a `dayIndex`** (rule 3) so T05's comparison starts both seasons at day 0.
- **`combineLatest` over drift streams is a build-breaking defect** (`stream.combine`). Two families watched independently is not `combineLatest`; combining them is.
- **A new provider name requires a numbered ruling in `CONVENTIONS.md` §6, in this commit.**
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the spread groups by the stored civil date and includes every day with zero births'` passes, and was seen to fail first for the stated reason
- [ ] grouping uses the stored civil date
- [ ] every day of the season is present
- [ ] the query is indexed
- [ ] `EXPLAIN QUERY PLAN` names `idx_lambing_localdate` and shows no `SCAN lambings`
- [ ] the zero-fill happens in `lib/domain/stats/lambing_spread.dart`, not in SQL
- [ ] `.distinct()` is element-wise, and `DayBirths` has a hand-written `==`
- [ ] `lib/data/` imports `package:collection`, not `package:flutter/foundation.dart`
- [ ] the cycle line reads `app_settings.cycle_days` and no literal `17` appears in `lib/features/season/`
- [ ] the new read provider is added to `CONVENTIONS.md` §3.2 by a numbered ruling in the same commit
- [ ] the five `uk-zone` bucketing cases pass under `TZ=Europe/London`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/features/season_summary_test.dart
fvm flutter test test/data/season_repository_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
TZ=Pacific/Chatham fvm flutter test test/domain --exclude-tags uk-zone
grep -rn "date(" lib/data/season_repository.dart || echo 'no SQL-side date function'
fvm dart tool/check_policy.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(season): watchSpread, dense and grouped by the stored civil date`

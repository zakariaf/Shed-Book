# N28-T01 — `SeasonRepository.watchSeasonCounts` — `customSelect` with explicit `readsFrom:`

| | |
|---|---|
| **Epic** | [N28 — Season Summary](epic.md) · `00-README` §9 step 10 (3 of 4) |
| **Task** | 1 of 6 |
| **Depends on** | N27-T07 |
| **Commit** | one commit · `feat(season): watchSeasonCounts as one aggregate statement` |

## 1. Why this task exists

The season's counts in one `customSelect` with an explicit `readsFrom:` — **never** a
`groupBy` in a Dart view, which produces a stream that does not know what invalidates it and a summary
that goes stale in the middle of lambing.

`readsFrom:` is the whole safety mechanism. Drift re-runs a raw statement only when a table it was
*told about* changes; omit `db.eweSeasons` and the barren rate freezes at the value it had when the
screen opened, while the screen keeps rendering and nothing throws. There is no failing test, no red
build and no exception — only a wrong number, on the one screen whose entire job is being right.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §12.1 | `seasonFactsQuery` produces **raw counts only**; a SQL view cannot carry a caveat |
| `docs/engineering/05-domain-correctness.md` | §6.3 | `SeasonCounts`, the statement, `readsFrom:`, `.distinct()` and why the second statement is not `combineLatest` |
| `shed-book-spec.md` | §7.8 | lambing percentage, litter size, barren and assisted rates, losses, spread |
| `docs/engineering/03-data-model-and-schema.md` | §5.1, §5.3, §5.4, §5.5 | `seasons.ewes_to_ram`, `ewe_seasons.status`'s seven keys, `lambings.ease`, `lambs.status` |
| `docs/engineering/CONVENTIONS.md` | §2.6, §3.1, §3.2, R18, R33 | `SeasonCounts`, `seasonRepositoryProvider`, `seasonFactsProvider`, no `SeasonStatsRepository`, ids not `int` |
| `docs/engineering/01-architecture.md` | §3.1 rules 3/8, decision #12, #60 | the layer rules, one statement per screen, no `combineLatest` |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | the aggregate query and its `readsFrom:` |
| `shed-riverpod-providers` | the stream's invalidation and rebuild scope |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/season_summary_test.dart`
- **Test** — `'the season counts come from one customSelect with an explicit readsFrom and update when a lambing lands'`
- **Why it is red today** — nothing aggregates a season, so every statistic written in N06 has no reader and the Season Summary has no data to render.

```bash
fvm flutter test test/features/season_summary_test.dart   # expect: failing, for the reason above
```

Make the assertion specific enough to fail for the right reason twice over: seed a season with one
lambing, take the first emission, insert a second lambing through `LambingRepository.beginLambing`,
and assert the **stream emits again** with `lambingsTotal == 2`. A test that only reads the count
once passes against a `Future`, and a `Future` is exactly the defect this task exists to prevent.

**Green.** The minimum code that passes, and nothing beyond it — the statement, the explicit dependency list, and a test that writes a lambing and watches
the count move.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8's order

| # | File | What changes, and why |
|---|---|---|
| 1 | — **no schema step** | Every column is already frozen: `seasons.ewes_to_ram` (nullable, no default — "I did not record it", not zero), `ewe_seasons.status` (`CHECK` over seven keys, no default), `lambings.ease` (nullable, no default — blank is not "unassisted"), `lambs.status` (`alive`/`dead`/`stillborn`/`sold`). **Say so in the commit message**, as `00-README` §8 requires: this task stores nothing, and `codegen` must show no diff |
| 2 | `lib/domain/stats/season_counts.dart` | `SeasonCounts` already exists from N06. Touch it **only** if its `==`/`hashCode` do not cover every field — see the gotcha in §5.3. Pure Dart: no drift import, no `package:clock` |
| 3 | `lib/data/season_repository.dart` | Add `watchSeasonCounts(SeasonId season)`. `SeasonRepository` already owns `seasons`, `ewe_seasons` and `app_settings.current_season` (CONVENTIONS §2.13); R18 puts the season-summary **reads** here too. Do not create `SeasonStatsRepository` — a repository that only reads is a query object wearing a repository's name |
| 4 | `lib/data/providers.dart` | **No change.** `seasonRepositoryProvider` is already declared as `FutureProvider<SeasonRepository>`, keepAlive (CONVENTIONS §3.1). If you are editing this file, you have taken a wrong turn |
| 5 | `lib/features/season/season_controller.dart` | New file. Declare `seasonFactsProvider` — the read provider lives in the **feature's** controller file, one drift statement per screen (`00-README` §8 step 4) |
| 6 | `test/data/season_repository_test.dart` | New. The repository tier, against `NativeDatabase.memory()`, never a mock |
| 7 | `test/features/season_summary_test.dart` | New. The anchor, written before all of the above |

There is no controller, no UI and no ARB in this task — T02 owns them. Say that in the commit
message too.

### 5.2 The signatures, spelled as CONVENTIONS spells them

```dart
// lib/data/season_repository.dart — a SeasonRepository method (R18).
// The argument is a SeasonId, never a bare int (R33).
Stream<SeasonCounts> watchSeasonCounts(SeasonId season) => db
    .customSelect(
      '''
      SELECT
        (SELECT ewes_to_ram FROM seasons WHERE id = ?1)                       AS ewes_to_ram,
        COUNT(DISTINCT CASE WHEN lc.n > 0 THEN l.ewe END)                     AS ewes_lambed,
        COUNT(DISTINCT l.id)                                                  AS lambings_total,
        COUNT(DISTINCT CASE WHEN lc.n > 0 THEN l.id END)                      AS lambings_with_lambs,
        COUNT(DISTINCT CASE WHEN l.ease IS NOT NULL THEN l.id END)            AS lambings_scored,
        COUNT(DISTINCT CASE WHEN l.ease >= 2 THEN l.id END)                   AS lambings_scored_assisted
      FROM lambings l
      LEFT JOIN (SELECT lambing, COUNT(*) AS n FROM lambs GROUP BY lambing) lc
             ON lc.lambing = l.id
      WHERE l.season = ?1
      ''',
      variables: [Variable<int>(season.value)],
      readsFrom: {db.seasons, db.lambings, db.lambs, db.eweSeasons},
    )
    .watch()
    .map(_toCounts)
    .distinct();
```

```dart
// lib/features/season/season_controller.dart — CONVENTIONS §3.2, verbatim shape.
final seasonFactsProvider =
    StreamProvider.autoDispose.family<SeasonCounts, SeasonId>((ref, season) async* {
  final repo = await ref.watch(seasonRepositoryProvider.future);
  yield* repo.watchSeasonCounts(season);
});
```

The statement above yields **six** of the counts. The five lamb-derived counts (`lambsBorn`,
`lambsBornAlive`, `lambsReared` and the two loss tallies) and the three ewe-outcome counts
(`ewesRecordedBarren`, `ewesDiedOrSoldBeforeLambing`, `ewesWithNoRecordedOutcome`) come from a
**second `customSelect`** over `lambs` and `ewe_seasons`, read non-reactively inside the first
statement's `map` — or folded into the first with a `UNION ALL`. Never two `watch()`es combined
(§5.3, gotcha 2).

The four-way bucketing the ewe-outcome counts use is already declared and is **derived, never
stored** (R43):

```dart
// lib/domain/stats/definitions.dart — a bucketing over ewe_seasons.status's seven keys.
///   lambed                   <- 'lambed'
///   recordedBarren           <- 'barren'
///   diedOrSoldBeforeLambing  <- 'died' | 'sold' | 'aborted'
///   notRecorded              <- 'to_ram' | 'scanned' | no row
enum EweSeasonOutcome { lambed, recordedBarren, diedOrSoldBeforeLambing, notRecorded }
```

### 5.3 The details that are easy to get wrong

1. **`readsFrom:` must be the union across *both* statements, not the first one's tables.**
   `05-domain-correctness.md` §6.3's printed set is `{db.seasons, db.lambings, db.lambs}` because it
   is showing one statement. The method returns counts derived from `ewe_seasons` as well, so
   `db.eweSeasons` belongs in the set. Omit it and the barren rate silently stops updating —
   *"omit it and the Season Summary silently stops updating"* is the document's own wording.

2. **`combineLatest` is a build-breaking defect, and this is the screen that invites it.** Gate row
   `stream.combine` scans all of `lib/`. Two drift streams updated inside one transaction can emit
   at different times, and a torn Season Summary is a wrong headline number (decision #12). One
   `watch()` per screen; the second statement is read inside the first's `map`.

3. **`.distinct()` is a no-op unless `SeasonCounts` has real value equality.** `Stream.distinct()`
   compares with `==`; identity equality never matches, so every drift re-emit rebuilds the whole
   screen. N06 wrote the hand-written `==`/`hashCode` — **count the fields against the class before
   you rely on it.** `05-domain-correctness.md` §6.3's prose implies six lambing-derived plus five
   lamb-derived plus three ewe-outcome fields; CONVENTIONS §2.6 records "13 int fields". If the class
   as built does not equal the field list this method fills, settle it here with a numbered ruling in
   CONVENTIONS §6 — do not quietly ship a `==` that skips a field, because a skipped field is a
   count that never refreshes.

4. **`?1` appears twice and there is exactly one variable.** SQLite numbered parameters are
   positional-by-number, so `?1` binds once and is reused. Switch to bare `?` placeholders during a
   "tidy-up" and you need two entries in `variables:` — and the failure is a wrong season's counts,
   not an error.

5. **`customSelect(` is allowed here; `customStatement(` is not.** Gate row `layer.single_writer`
   bans `customStatement(` outside `lib/core/db/`. They look alike and only one of them is banned.

6. **`groupBy` inside a Dart-defined drift `View` is banned** (decision #60). Drift documents exactly
   one shape for Dart views and says nothing about `groupBy` inside `as()`. The `GROUP BY` in the
   derived table above is inside a raw statement, which is the sanctioned place for it.

7. **A lambing with zero lambs is normal, common and transient.** The row is created on screen
   *entry* (decision #11), so `lambings_total` and `lambings_with_lambs` diverge constantly during a
   night. Do not "fix" it by filtering: T02's average litter size needs both numbers to report its
   own coverage.

8. **`ewes_to_ram` is `int?` and must stay `int?` all the way out.** The denominator rule is
   03 §5.3's: prefer `seasons.ewes_to_ram` when non-null, otherwise
   `COUNT(ewe_seasons WHERE status = 'to_ram')`, and if both are absent the statistic is
   `notComputable`. **It never falls back to ewes lambed** — that silently changes the definition to
   a different published convention and reads high by fourteen points on the worked example. `?? 0`
   here is caught by gate row `stat.zero_default` only under `lib/features/season/`; in
   `lib/data/` nothing catches it but review.

9. **`lib/data/` may never import `lib/domain/validation/`** (`layer.data_no_validation`, R53). A
   count that looks contradictory is not this method's problem; warnings are the controller's.

10. **No `Provider<AppDatabase>` and no `overrideWithValue` in `lib/`.** The repository takes the
    database through `seasonRepositoryProvider`, which derives from `databaseProvider`
    (CONVENTIONS §3.1, §3.5).

11. **Riverpod 2.6.1 spellings only.** `StreamProvider.autoDispose.family<…>` is the 2.6.1 form; a
    `@riverpod`-generated provider, a `Ref` type annotation or a constructor-delivered family
    argument are all Riverpod 3 and fail `analyze --fatal-infos` in the `gate` job.

### 5.4 The full test set

**`test/data/season_repository_test.dart`** — against `NativeDatabase.memory()` via
`testDatabase()`, seeded with `test/support/seeds.dart` writers:

| Case | Asserts |
|---|---|
| `'watchSeasonCounts emits again when a lambing is inserted'` | first emission `lambingsTotal == 1`, second `== 2` |
| `'watchSeasonCounts emits again when an ewe_seasons row changes'` | proves `db.eweSeasons` is in `readsFrom:` — the barren count moves |
| `'watchSeasonCounts emits again when a lamb is attached'` | proves `db.lambs` is in `readsFrom:` — `lambingsWithLambs` moves |
| `'watchSeasonCounts emits again when seasons.ewes_to_ram is set'` | proves `db.seasons` is in `readsFrom:` |
| `'an unrelated write to a tracked table does not re-emit an equal SeasonCounts'` | proves `.distinct()` plus real value equality; write to a lambing's `note` and assert exactly one emission |
| `'ewes_to_ram unset yields null, never zero'` | `counts.ewesPutToRam` is `null` |
| `'a lambing with no lambs counts in lambingsTotal and not in lambingsWithLambs'` | the decision #11 state |
| `'ease null is excluded from lambingsScored and from lambingsScoredAssisted'` | blank is not "unassisted" |
| `'ease 1 is scored and not assisted; ease 2 is both'` | the `>= 2` boundary |
| `'a lamb with no tag is counted'` | identity is the row id; keep a tagless dead lamb in the seed |
| `'a fostered lamb is counted exactly once at season level'` | `birth_dam` aggregation (05 §6.10) |
| `'counts are scoped to one season and ignore a neighbouring season'` | the `WHERE l.season = ?1` clause |

**`test/features/season_summary_test.dart`** — the anchor plus:

| Case | Asserts |
|---|---|
| the anchor | one `customSelect`, explicit `readsFrom:`, the count moves when a lambing lands |
| `'seasonFactsProvider disposes when the last listener goes'` | `.autoDispose`, per CONVENTIONS §3.2 |

**Time-shaped cases — `test/domain/uk_zone/`-style tagging inside the data test file.** Tag the
group `@Tags(['uk-zone'])` so `TZ=Europe/London fvm flutter test --tags uk-zone` picks it up:

| Case | Asserts |
|---|---|
| `'two lambings inside the repeated hour on 25 Oct 2026 both count'` | 01:30 BST and 01:30 GMT are two rows and `lambingsTotal == 2`; the count is over rows, never over instants |
| `'a lambing at 01:30 on 29 Mar 2026 counts, and the non-existent wall time is a warning not a drop'` | spring-forward: the gap hour never removes a row from a count |

Nothing in this task reads the wall clock. If a test needs a fixed instant, use `atFixed()` from
`test/support/harness.dart` — `appNow()` is the only wall-clock reader in the app, and it is not on
this path.

## 6. Constraints that bind this task

- **`readsFrom:` is not optional and not a hint.** Without it drift cannot track the statement and the stream stops updating (decision #60). With the wrong set it updates for some writes and not others, which is worse.
- **One statement per screen; `combineLatest` over drift streams is a build-breaking defect** (decision #12, gate row `stream.combine`).
- **No `SeasonStatsRepository`, no `lib/data/repositories/` folder** — `lib/data/` is flat (R18).
- **Ids cross boundaries; `int` does not** (R33). `SeasonId`, always.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the season counts come from one customSelect with an explicit readsFrom and update when a lambing lands'` passes, and was seen to fail first for the stated reason
- [ ] explicit `readsFrom:`
- [ ] no `groupBy` in a Dart view
- [ ] the counts update on a write, in the same frame
- [ ] `readsFrom:` names `seasons`, `lambings`, `lambs` **and** `ewe_seasons`, and one test per table proves each one re-emits
- [ ] `.distinct()` is present **and** `SeasonCounts` has a hand-written `==` covering every field the method fills
- [ ] `ewesPutToRam` is `null` when `seasons.ewes_to_ram` is unset — never `0`, never a fallback to ewes lambed
- [ ] `combineLatest` appears nowhere in the diff; the second statement is read inside the first's `map`
- [ ] `codegen` shows no diff: this task adds no table and no column, and the commit message says so
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/features/season_summary_test.dart
fvm flutter test test/data/season_repository_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
fvm dart run tool/check_policy.dart
make gen
git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(season): watchSeasonCounts as one aggregate statement`

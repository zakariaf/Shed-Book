# N26-T01 — `flockListProvider` and `FlockRow` — one statement

| | |
|---|---|
| **Epic** | [N26 — Flock and Note Search](epic.md) · `00-README` §9 step 10 (1 of 4) |
| **Task** | 1 of 7 |
| **Depends on** | N25-T06 |
| **Commit** | one commit · `feat(flock): one statement, and search over rankTagMatches` |

## 1. Why this task exists

One statement producing the list, with the search box reusing `rankTagMatches` — the same
ranking Quick Entry uses, so a shepherd who learned it at 3am does not have to learn a second one at
11am.

Two facts make this the first task rather than a later one. `07 §1.2`'s one-query rule means the
statement's shape decides everything downstream — the filters (T02) are a `WHERE` on it, the row (T03)
is a rendering of its columns, and a second statement added later is a second thing to keep in step.
And `03 §9.1` already settled the ranking: it lives in `lib/domain/tag_match.dart` because *"the Flock
search box and the Foster screen both call it, and layer rule 6 forbids one feature importing another,
so the feature-folder placement is not merely inconsistent — it is unbuildable."*

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§3.1** (the `flockListQuery` SQL, printed in full, with its `readsFrom:` and its `:today` binding) · §3.2 (the six states, including Frame 1's six placeholders) · §1.2 (the one-query rule, stated exactly) · §1.4 (the state vocabulary) · §1.7 (headings) · §18 (both screens' place in the index) | the statement, verbatim, and the states it must render |
| `docs/engineering/CONVENTIONS.md` | **§3.2** (`flockListProvider` — `StreamProvider<List<FlockRow>>` in `lib/features/flock/flock_controller.dart`, **keepAlive**) · §3.4 (`flockControllerProvider`) · §1.1 layer rules 3, 5, 7 · §2.13 (the repository set is closed — R19) · §2.14 · §4.1–§4.3 · §5.1 (*tag*, never *number*) · **R18, R26, R27, R33, R42** | **BINDING** on the provider name, its file, its type and its dispose policy |
| `docs/engineering/03-data-model-and-schema.md` | §5.2 (`Ewes` — `tag`, `tag_digits`, `status`, `idx_ewe_tagdigits`) · §5.3 (`EweSeasons` — `status`, `scanned_count`, and why there is no default) · §5.4 (the `lambing_consistency` **view**) · §5.13 (`ewe_summaries` stores **counts only**; a cache, `LEFT JOIN`-ed) · §5.14 (`FlockRepository` owns `ewes` and `ewe_touches`) · **§9.1** (`rankTagMatches`, printed, and why FTS5 cannot do this) | every column name and the ranking function's body |
| `docs/engineering/02-state-di-navigation.md` | §4.1 (`StreamProvider` over one drift `watch()`) · **§4.2** (hub reads are keepAlive; the ticker is autoDispose) · §4.4 (`.select` and the collection trap) · §4.5 (the exhaustive `AsyncValue` switch; **loading is never a spinner**) · §4.6 (where providers are declared) · §8.1 (the push helper and the route name) | the provider shape and the rebuild scope |
| `docs/design/indelible.md` | §3.5 (**tags right-align in a fixed three-character column** — *"the reason the left column works"*) · §4.3 (the layout grid; the spine at x=68) · §4.4 (row heights) · §7.16 (the 44 px sticky page header) · §8 Screen 1 | the ordering and the column geometry the statement must feed |
| `docs/engineering/12-testing.md` | §3.1 (`testDatabase()`) · §5.1–§5.2 (`pumpApp`; **fixtures for shape at volume**) · §11.5 (`flock_400_3seasons.json`) · §11.6 (no `Future.delayed`, no wall clock) | how 400 rows get into a test |
| `docs/research/00-tech-decisions.md` | §5 only for versions · #12 (drift `watch()`; no `combineLatest`) · #35 (in-memory ranking for tags) · #47 (SQL-side time is banned) · #54 (a warning cannot be persisted) · #58 (never `?? 0` on a nullable aggregate) · #68 (`ewe_touches`) · #71 (never a spinner) · #126 (performance is measured by hand) | the decisions the statement applies |
| `shed-book-spec.md` | §7.7 | filter the flock by anything; full-text offline search |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-riverpod-providers` | one statement per screen and the search's rebuild scope |
| `shed-screens-and-routing` | the screen, its route and its keys |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/flock_test.dart`
- **Test** — `'the filter set narrows 400 ewes to currently penned in one statement'`
- **Why it is red today** — nothing lists the flock: there is no daylight route to an animal that is neither in the pens nor in the recents strip.

```bash
fvm flutter test test/features/flock_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it says something a hand-rolled list cannot fake. Restore
`flock_400_3seasons.json`, pump `FlockScreen`, and assert four things:

1. The number of rendered rows equals the active-ewe count read off the database with a
   `SELECT COUNT(*)` — never a literal `400`, because the fixture's exact split is `12 §11.5`'s to
   change and a remembered number turns a fixture edit into a mystery failure.
2. Applying the *currently penned* filter narrows the list to exactly the count of ewes with an open
   `pen_occupancies` row, again read off the database in the test.
3. **`db.executedStatements.length` grows by exactly one across the whole build.** This is `07 §1.2`'s
   one-query rule as an executable assertion. A test that only counts rows passes on an implementation
   that issues one statement per ewe.
4. `combineLatest` and `package:rxdart` appear nowhere in the diff. `02 §4.1`: two streams updated in
   one transaction can emit at different times, so their combination *"shows a state that never existed
   in the database"* (drift#3338, which its maintainer calls working as intended).

**Green.** The minimum code that passes, and nothing beyond it — one statement with an explicit `readsFrom:`, and the shared ranking.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Steps 1–3 are skipped and the commit message says so.** This task stores nothing: no table, no
column, no migration, no domain function. `03 §5.4`'s `lambing_consistency` view and `03 §9.1`'s
`rankTagMatches` both already exist — the first from N07's flock cluster, the second from N13-T02.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/flock_repository.dart` | **Edit.** Add `FlockRow`, `Stream<List<FlockRow>> watchFlock()` and `Future<WriteOutcome> touchEwe(EweId)`. The statement is `07 §3.1`'s, as **one** `customSelect` with an explicit `readsFrom:`. It goes here rather than on a new repository because R19 closes the set at twelve and `03 §5.14` already gives `FlockRepository` `ewes` **and** `ewe_touches` |
| 2 | `lib/features/flock/flock_controller.dart` | **New.** `flockListProvider` (`StreamProvider<List<FlockRow>>`, keepAlive) plus `FlockController` / `flockControllerProvider` holding **screen state**: the search text in a private field, the ranked list as a stored field, and the empty filter set T02 will populate. No drift import, no `BuildContext`, no draft |
| 3 | `lib/features/flock/flock_screen.dart` | **New.** `FlockScreen` — the 44 px page header, the search field, the scrolling ruled page, the six-placeholder Frame 1 and the empty state. The row widget is **T03's**; today the list renders `ShedAnimalRow` with a tag and a summary line and nothing else |
| 4 | `lib/routing/routes.dart` | **Edit.** Add the `Routes.flock` push helper. `RouteNames.flock` already exists — N13-T01 landed all thirteen names with **zero** push helpers, and *"each screen epic adds its own"* |
| 5 | `lib/l10n/app_en.arb` | **Edit.** The screen title, the search field label, the empty-state line and its action, each with a `description`. The **filtered**-empty string is T02's; authoring it here would make T02's anchor pass before T02 is written |
| 6 | `docs/engineering/CONVENTIONS.md` §2.14 | **Edit.** Add the `FlockRow` row. §3.2 names the provider's element type and §2 carries nothing about it; §1's own preamble says every name a document uses is either catalogued or banned by a numbered ruling. Same principle, same commit (`00-README` §10 rule 3) |
| 7 | `test/support/seeds.dart` | **Edit.** Add `seedEweSeason(db, ewe:, season:, status:, scannedCount:)` and `seedCulledEwe(db, tag:)`. Reused by T02, T03, T04 and by N27 |
| 8 | `test/data/flock_repository_test.dart` | **Edit.** The statement's own cases, against `NativeDatabase.memory()` |
| 9 | `test/features/flock_test.dart` | **New.** The anchor and the feature-side cases in §5.4 |

`drift_schemas/` must not move. If it does, something added a column to make this query easier, and
that is irreversible after N07's freeze.

### 5.2 The signatures

`FlockRow` lives in `lib/data/`, not in the feature folder: layer rule 3 forbids `lib/data/` importing
`lib/features/`, and the repository is what constructs it.

```dart
// lib/data/flock_repository.dart

/// One rendered flock row. Value equality is required: the list is handed to
/// ListView.builder and compared across emissions, and a class with identity
/// `==` makes every de-duplication a no-op (01 §4.4, drift#3295).
///
/// COUNTS ONLY, never a formatted string. 03 §5.13: a formatted string in the
/// database "would freeze both" the terminology overlay and the locale — and
/// so would one frozen into a row class. The sentence
/// "3 seasons · avg 2.0 · assisted twice" is assembled at the presentation
/// edge, in T03.
@immutable
final class FlockRow {
  const FlockRow({
    required this.ewe,
    required this.tag,
    required this.tagDigits,
    required this.status,
    required this.seasonsRecorded,
    required this.lambingsRecorded,
    required this.lambsBorn,
    required this.lambsBornAlive,
    required this.assistedLambings,
    required this.scoredLambings,
    required this.lastObservationSeason,
    required this.pennedSince,
    required this.seasonStatus,
    required this.scannedCount,
    required this.latestClearDate,
    required this.hasUnrecordedWithdrawal,
    required this.hasWarning,
  });

  final EweId ewe;                    // R33: an extension-type id, never a bare int
  final String tag;                   // exactly as typed; never normalised (03 §5.2)
  final String tagDigits;             // the projection. It RANKS; it is never shown (§5.1)
  final String status;                // ewes.status as its stored key. T04 gives it EweStatus

  // ewe_summaries, LEFT JOIN-ed. NULL means "no summary row yet", which is a
  // different fact from zero — decision #58 bans `?? 0` here.
  final int? seasonsRecorded;
  final int? lambingsRecorded;
  final int? lambsBorn;
  final int? lambsBornAlive;
  final int? assistedLambings;
  final int? scoredLambings;
  final SeasonId? lastObservationSeason;

  final Instant? pennedSince;         // open pen_occupancies.entered_at; null = not penned
  final String? seasonStatus;         // ewe_seasons.status for the CURRENT season (R42)
  final int? scannedCount;            // ewe_seasons.scanned_count
  final LocalDate? latestClearDate;   // max clear_date over live treatments. CLOCK-FREE.
  final bool hasUnrecordedWithdrawal; // a live treatment with NO withdrawal row (03 §5.8)
  final bool hasWarning;              // lambing_consistency.is_mismatched, recomputed on read

  @override
  bool operator ==(Object other) => …;   // every field
  @override
  int get hashCode => …;
}
```

The read verb — `07 §3.1`'s statement, with the four columns rulings **N1** and **N2** need:

```dart
  /// ONE statement (07 §1.2). Ewes LEFT JOIN their precomputed ewe_summaries
  /// row, plus the status columns the five §7.7 filters need.
  ///
  /// NOTHING IN THIS STATEMENT READS A CLOCK. Decision #47 bans SQL-side time,
  /// and 07 §3.1's `:today` binding is deliberately absent: a bound date is
  /// captured when the statement is built and never advances, so a phone left
  /// on this screen across midnight would filter against yesterday. The
  /// clock-free columns come back and computeWithdrawalStatus compares them in
  /// Dart, where `now` is a parameter (R24). See T02, ruling N1.
  Stream<List<FlockRow>> watchFlock() => _db
      .customSelect(
        '''
SELECT e.id, e.tag, e.tag_digits, e.status,
       s.seasons_recorded, s.lambings_recorded, s.lambs_born, s.lambs_born_alive,
       s.assisted_lambings, s.scored_lambings, s.last_observation_season,
       es.status         AS season_status,
       es.scanned_count  AS scanned_count,
       (SELECT o.entered_at FROM pen_occupancies o
         WHERE o.ewe = e.id AND o.exited_at IS NULL
         ORDER BY o.entered_at ASC LIMIT 1)                    AS penned_since,
       (SELECT MAX(w.clear_date) FROM treatments t
          JOIN treatment_withdrawals w ON w.treatment = t.id
         WHERE t.ewe = e.id AND t.voided_at IS NULL
           AND w.kind = 'days')                                AS latest_clear_date,
       EXISTS (SELECT 1 FROM treatments t
                WHERE t.ewe = e.id AND t.voided_at IS NULL
                  AND NOT EXISTS (SELECT 1 FROM treatment_withdrawals w
                                   WHERE w.treatment = t.id))  AS unrecorded_withdrawal,
       EXISTS (SELECT 1 FROM lambing_consistency lc
                 JOIN lambings lg ON lg.id = lc.lambing_id
                WHERE lg.ewe = e.id AND lc.is_mismatched = 1)  AS has_warning
  FROM ewes e
  LEFT JOIN ewe_summaries s ON s.ewe = e.id
  LEFT JOIN ewe_seasons  es ON es.ewe = e.id
                           AND es.season = (SELECT current_season FROM app_settings WHERE id = 1)
 -- Active first, struck at the bottom. 07 §3.1 writes `WHERE e.status = 'active'`
 -- and indelible.md §7.4 keeps her "in the list, at the bottom, under a printed
 -- line reading STRUCK — 1". This shape lets T03 rule N2 either way without
 -- rewriting the statement. Do not quietly pick one here.
 ORDER BY (e.status = 'active') DESC, e.tag_digits, e.tag;
''',
        readsFrom: {
          _db.ewes, _db.eweSummaries, _db.eweSeasons, _db.penOccupancies,
          _db.treatments, _db.treatmentWithdrawals, _db.lambings, _db.lambs,
          _db.appSettings,
        },
      )
      .watch()
      .map((rows) => [for (final r in rows) _toFlockRow(r)]);
```

And the touch verb, which is the whole of what a row tap does in this epic:

```dart
  /// 07 §3.3: "Open a ewe card | 1 tap | writes an `ewe_touches` row"
  /// (decision #68). This epic lands the WRITE. The push is N27-T01's, because
  /// Routes.eweCard and EweCardScreen do not exist until the Ewe Card epic.
  ///
  /// An UPSERT, never an insert: the primary key is `ewe`, one row per animal,
  /// and a plain insert() on a second touch throws a UNIQUE failure (N14-T01).
  /// `insertOnConflictUpdate` is the spelling.
  Future<WriteOutcome> touchEwe(EweId ewe);
```

The provider, on the feature side, touching no drift symbol:

```dart
// lib/features/flock/flock_controller.dart
/// CONVENTIONS §3.2: this file, this name, this type. keepAlive — the flock is
/// a hub read (02 §4.2), re-entered constantly, and disposing a 400-row query
/// on every pop is exactly the wrong trade.
final flockListProvider = StreamProvider<List<FlockRow>>((ref) async* {
  final repo = await ref.watch(flockRepositoryProvider.future);
  yield* repo.watchFlock();
});
```

The search box narrows the **streamed** rows in Dart — it never re-queries:

```dart
/// 07 §3.1: "Filters are SQL; the search box is Dart." One implementation of
/// the ranking, two call sites (decision #35, R27). Do not write a second one.
List<FlockRow> rankFlock(List<FlockRow> all, String query) {
  if (query.isEmpty) return all;
  final index = [
    for (final r in all)
      TagIndexEntry(eweId: r.ewe, tag: r.tag, digits: r.tagDigits, lastTouched: null),
  ];
  final position = {
    for (final (i, e) in rankTagMatches(index, query).indexed) e.eweId: i,
  };
  return [for (final r in all) if (position.containsKey(r.ewe)) r]
    ..sort((a, b) => position[a.ewe]!.compareTo(position[b.ewe]!));
}
```

### 5.3 The details that are easy to get wrong

- **`rankTagMatches` returns `TagIndexEntry`, not `FlockRow`, and it drops non-matches.** The naive
  call — mapping its result straight into the list — loses every column the row needs and forces a
  lookup per entry. Build the position map once, as above. `03 §9.1`'s scoring is exact → prefix →
  suffix → infix → drop, tie-broken by most-recently-touched; **`lastTouched` is null here** because
  the flock statement does not read `ewe_touches`, so the tie-break falls through to *"shorter digits
  first"*. That is correct and not a bug: on the flock page the eye runs down the tag column, and
  length ordering is what Indelible §3.5's fixed three-character column depends on.
- **`tag_digits` ranks; it is never shown.** `CONVENTIONS §5.1`: *"`tag_digits` is a projection and is
  never shown."* Rendering it — even as a fallback when `tag` is empty — is a review stop, because
  `tag` carries `CHECK (length(trim(tag)) > 0)` and cannot be empty.
- **`ORDER BY (e.status = 'active') DESC` is ruling N2's placeholder, and T03 either keeps it or
  deletes it.** `07 §3.1` writes `WHERE e.status = 'active'`; Indelible §7.4 keeps a struck ewe *"in
  the list, at the bottom, under a printed line reading `STRUCK — 1`."* The statement above selects
  both and sorts active first, which is the only shape that lets T03 rule either way without rewriting
  the query. The comment beside the `ORDER BY` names T03. Do not quietly pick a side.
- **`ewe_seasons` is joined on the *current* season and is frequently absent.** R42: barren is
  `ewe_seasons.status = 'barren'`, never an `EweObservations` row — *"the `ewe_observation` vocabulary
  has no barren key."* A ewe not yet entered into this season has no row, so `season_status` is `NULL`,
  and that is the honest answer. **Do not `COALESCE` it to `'to_ram'`**: `03 §5.3` refuses a default on
  that column for exactly this reason — *"defaulting to `to_ram` would silently assert a ewe was put to
  the ram, which is the denominator of a commercially sensitive number"* (decision #59).
- **`app_settings.current_season` is nullable.** It carries `ON DELETE SET NULL`, so deleting a season
  leaves it null and the `LEFT JOIN` matches nothing — every ewe then shows no season status, which is
  correct. A subquery inside a `JOIN … ON` clause is legal SQLite and is cheaper than a second
  statement, which `07 §1.2` would forbid anyway.
- **`ewe_summaries` is a cache and may be absent.** `03 §5.13` says so and `07 §3.1` `LEFT JOIN`s it.
  Six nullable ints follow, and decision #58 bans `?? 0` on a nullable aggregate: *an unknown is not
  zero.* The summary line renders *"no seasons recorded"*, never *"0 seasons"*. Rebuilding the cache
  inside the writes that invalidate it is **N27-T03**, not this task.
- **`lambing_consistency` is a view, and `is_mismatched` goes three-valued the moment you reimplement
  it.** `03 §5.4` guards `declared_birth_type IS NOT NULL` inside the view precisely because
  *"`COUNT(…) <> NULL` is NULL, which would make this column three-valued for every in-progress
  lambing."* Read the view. Never inline the predicate.
- **`readsFrom:` must name `lambings` and `lambs`.** `has_warning` reads a **view**, and drift cannot
  see through a view to its base tables. Omit either and adding a lamb to a lambing never clears the
  warning mark on the flock row. Same reasoning for `app_settings`, which the season subquery reads:
  changing the current season must re-run the statement.
- **`readsFrom:` must *not* name `search_docs` or `search_fts`.** They are written by SQL triggers only
  (`03 §5.14`); drift never sees those writes, so naming them buys a dependency that can never fire.
  That is T05's problem and it is solved there, differently.
- **Frame 1 is six fixed-height dark placeholders, not a spinner.** `07 §3.2` and decision #71.
  `02 §4.5`'s exhaustive switch is the only permitted way to read the `AsyncValue`: `AsyncLoading()`
  renders the placeholder box, never `CircularProgressIndicator`, which `ui.spinner` bans under
  `lib/features/` outright. The placeholder `Rect`s must equal the loaded rows' `Rect`s, or the list
  jumps when the database opens.
- **`.select` over a `List` deduplicates nothing.** `02 §4.4` states it plainly: a stored `List` field
  still has identity `==`. The screen watches `flockListProvider` directly and re-ranks in `build`; do
  not reach for `.select((rows) => …)` and expect it to save a rebuild. What saves work is that
  `rankTagMatches` is synchronous over a ~400-entry, ~16 KB in-memory list (`03 §9.1`) — the same-frame
  property is the whole point of decision #35.
- **Nothing in this file may watch `minuteTickProvider`.** `02 §4.2` makes the ticker `.autoDispose` so
  *"nothing should tick when nothing displays elapsed time"*, and both `flockListProvider` and
  `flockControllerProvider` are keepAlive — either one watching it pins the ticker for the life of the
  app. The pen-hours figure and the withdrawal day boundary are watched by the **widget**, in T02 and
  T03, where disposal follows the screen.
- **Anything the user typed lives in a private field on the notifier, not only in `state`.**
  `CONVENTIONS §4.4` rule 4 and `02 §4.4`. The ranked list is a **stored field computed in a factory**,
  never a getter that allocates — *"this rebuilds on EVERY notifier change and runs the filter once per
  comparison as well as once per build, strictly worse than no `.select`."*
- **`Routes.flock` is a push helper, and Quick Entry is still `MaterialApp.home`.** N13-T01 landed
  thirteen names and zero helpers; this is the ninth screen epic to add one. Do not add
  `onGenerateRoute`, a `routes:` map or `pushNamed` — `02 §8.4` bans all three, and `--fatal-infos`
  turns the deprecated spellings into a CI failure.
- **`headingLevel: 1`, never `Semantics(header: true)`.** `10 §3.4`: `header: true` *"is a no-op on
  both iOS and Android as of 3.44"*, still compiles and still reads correctly in review, which makes it
  *"the single most likely accessibility regression in this codebase."* Flock gets a level 1 and **no**
  level 2 (`10 §3.4`'s table).
- **`400 rows scroll without jank` is measured on a device, not asserted in CI.** `12 §1.3` and
  decision #126 put performance measurement on a real phone by hand. What the suite holds is the
  statement count and the absence of an N+1; a headless runner cannot hold a frame budget.

### 5.4 The full test set

`test/features/flock_test.dart` (widget, through `pumpApp`) and `test/data/flock_repository_test.dart`
(repository, against `NativeDatabase.memory()` through `testDatabase()` — never a mock, decision #111).

| File | Case | What it asserts |
|---|---|---|
| features | `'the filter set narrows 400 ewes to currently penned in one statement'` | **The anchor.** Row count equals the fixture's active-ewe count read off the database; the penned filter narrows it to the open-occupancy count; `db.executedStatements` grows by exactly **one**; `combineLatest` appears nowhere |
| features | `'frame 1 renders six fixed-height placeholders and no spinner'` | `AsyncLoading()` before the database opens. `find.byType(CircularProgressIndicator)` is `findsNothing`, and the placeholder `Rect`s equal the loaded rows' `Rect`s so nothing shifts |
| features | `'the empty state occupies the same box the list will, with one action'` | Zero ewes. `07 §2.2`: *"No animals yet."* + *"Add a ewe"*, at the same `tapHero` control the populated screen uses (decision #71) |
| features | `'typing 12 ranks 12, 128 and 412 in that order, in the same frame'` | `03 §9.1`'s scoring, through the screen. Assert the **order**, not the set — a raw `LIKE` returns `128` before `12`, and ranking is the actual UX problem |
| features | `'typing a query issues no additional statement'` | The search is Dart (decision #35). `db.executedStatements.length` is unchanged across five keystrokes. This is the assertion that stops somebody "improving" the search into SQL |
| features | `'a ewe with no ewe_summaries row renders no seasons recorded, not 0 seasons'` | Decision #58. The string is the ARB's; `'0'` must not appear in the rendered summary line |
| features | `'the screen carries exactly one headingLevel 1 node and no headingLevel 2'` | `10 §3.4`. `Semantics(header: true)` appears nowhere in the diff |
| features | `'Routes.flock pushes a route whose settings name is flock'` | `RouteSettings(name:)` exists for the diagnostics log and `ModalRoute.withName`, never for `pushNamed` (`02 §8.1`) |
| features | `'tapping a row writes an ewe_touches row and does not push'` | Decision #68 and the N27 boundary. `Navigator` depth is unchanged; the `ewe_touches` row exists |
| data | `'watchFlock issues one statement and re-emits when a ewe is created'` | `readsFrom:` on `ewes`. Create through `FlockRepository.createEwe` (N14-T01) and expect a second emission |
| data | `'watchFlock re-emits when a lamb is added to a contradictory lambing'` | The `readsFrom:` trap. Adding a lamb changes `lambing_consistency.is_mismatched` **through a view**; omit `lambings`/`lambs` and the mark never clears |
| data | `'watchFlock re-emits when the current season changes'` | `app_settings` in `readsFrom:`; the `ewe_seasons` join is season-scoped |
| data | `'a ewe with no ewe_seasons row for the current season has a null season status'` | R42 and `03 §5.3`. No `COALESCE` to `'to_ram'` — assert the null survives into `FlockRow` |
| data | `'latest_clear_date is the maximum over live treatments and ignores voided ones'` | `t.voided_at IS NULL`. Two treatments, the later clear date on the voided one; expect the earlier |
| data | `'unrecorded_withdrawal is true for a live treatment with no withdrawal row'` | `03 §5.8`: *"NO ROW for a target means NotRecorded."* This column is what makes ruling N1 possible in T02 |
| data | `'the statement reads no clock'` | Source text over the SQL string: no `date(`, no `datetime(`, no `CURRENT_`, no `julianday(`, no `:today`. Decision #47; `time.sql_now_*` is already a gate row |
| data | `'touchEwe upserts and a second touch does not throw'` | Primary key is `ewe`; `insertOnConflictUpdate`, one row, the later `touched_at` |
| data | `'400 rows materialise with no N+1'` | `restoreFixture`, then `db.executedStatements.length == 1` for the whole materialisation |
| data · **`@Tags(['uk-zone'])`** | `'a clear date resolves to the same LocalDate at 01:30 and 01:30 again on the clocks-back night'` | `TZ=Europe/London`, `withClock` pinned to **01:30** on the ambiguous night, read twice across the repeated hour. `clear_date` is a `TEXT` civil date and `LocalDate.of(now)` must return the same day both times. `12 §2.3` owns the hour; getting this wrong shifts every withdrawal filter by one day, once a year, in October |
| data · **`@Tags(['uk-zone'])`** | `'penned_since across the spring-forward gap yields a duration with no negative hour'` | `timeSincePenned(entered, now)` takes `now` (R24). Pin `entered` to 00:30 and `now` to 02:30 on the clocks-forward night; the elapsed figure must be one hour, not two |

### 5.5 What this task deliberately does not build

- **The five filters.** T02. The statement already returns every column they need, which is why T02 is
  a `WHERE` plus a controller field rather than a second query.
- **The 88 px row, the warning mark and the struck rendering.** T03.
- **The `+ EWE` slab.** T04.
- **The row tap's navigation.** N27-T01. Today `onTap` calls `touchEwe` and returns; write the reason
  in a comment beside it, naming N27, so nobody "fixes" it with a push to a screen that does not exist.
- **The over-cap row.** N30-T05. Nothing in this file may watch `entitlementProvider` (decision #90).

## 6. Constraints that bind this task

- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **One query per screen, and it is a rule with a mechanism** — `07 §1.2`, `02 §4.1`, decision #12.
  *"If two things must be shown together, they are one query or one view."*
- **This task stores nothing.** `00-README` §8 steps 1–3 are skipped; say so in the commit message, and
  if `drift_schemas/` moves, stop and find out why.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green.

## 7. Definition of Done

- [ ] `'the filter set narrows 400 ewes to currently penned in one statement'` passes, and was seen to fail first for the stated reason
- [ ] one statement
- [ ] the ranking is `rankTagMatches`, not a second implementation
- [ ] 400 rows scroll without jank on the smallest device
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `db.executedStatements` grows by exactly one across a full build, and by zero across a keystroke
- [ ] `readsFrom:` names `lambings` and `lambs` (the view's base tables) and `app_settings` (the season subquery), and names neither `search_docs` nor `search_fts`
- [ ] the SQL reads no clock: no `date(`, no `datetime(`, no `CURRENT_`, no `:today`
- [ ] no `?? 0` on any `ewe_summaries` column; an absent summary renders as *not recorded*, never as zero
- [ ] `tag_digits` is never rendered
- [ ] `flockListProvider` is keepAlive, and nothing in `lib/features/flock/` watches `minuteTickProvider` in this task
- [ ] `Routes.flock` exists; `onGenerateRoute`, a `routes:` map and `pushNamed` do not
- [ ] `FlockRow` has a row in `CONVENTIONS §2.14`, added in this commit
- [ ] the row tap calls `touchEwe` and does not navigate, with the reason and **N27-T01** named in a comment
- [ ] the `ORDER BY` carries the comment naming T03 and ruling N2; no side is picked here
- [ ] `drift_schemas/`, `lib/core/db/tables/` and `lib/core/db/migrations.dart` are untouched

## 8. Verification

```bash
fvm flutter test test/features/flock_test.dart
make check
make test
```

```bash
fvm flutter test test/data/flock_repository_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
fvm flutter test test/features/flock_test.dart --plain-name 'currently penned'
```

```bash
grep -rn "combineLatest\|package:rxdart" lib/                 # expect zero
grep -c "customSelect" lib/data/flock_repository.dart         # expect 2 (the deck and the flock)
grep -rn "package:drift\|core/db" lib/features/flock/         # expect zero (layer rule 5)
grep -rn "tagDigits\|tag_digits" lib/features/                # expect zero renders
grep -rn "CircularProgressIndicator" lib/features/            # expect zero (ui.spinner)
grep -rn "header: true" lib/                                  # expect zero (a11y.header_bool)
grep -rn "minuteTickProvider" lib/features/flock/             # expect zero in this task
grep -rn "?? 0" lib/features/flock/                           # expect zero (decision #58)
git diff --name-only main -- drift_schemas/ lib/core/db/      # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(flock): one statement, and search over rankTagMatches`

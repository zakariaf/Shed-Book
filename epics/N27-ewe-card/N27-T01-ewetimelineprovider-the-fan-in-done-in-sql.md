# N27-T01 — `eweTimelineProvider` — the fan-in done in SQL

| | |
|---|---|
| **Epic** | [N27 — Ewe Card](epic.md) · `00-README` §9 step 10 (2 of 4) |
| **Task** | 1 of 7 |
| **Depends on** | N26-T07 |
| **Commit** | one commit · `feat(ewe_card): the timeline as one SQL statement` |

## 1. Why this task exists

One statement producing `TimelineRow` — lambings, treatments, care events, fosters, observations, pen
occupancies and notes — with the fan-in **in SQL**, because seven drift streams combined in Dart is
the build-breaking defect `00-README` §8 step 14 names by name.

It is also the task that fixes the shape of `TimelineRow` and `TimelineKind`. `CONVENTIONS §3.2`
types `eweTimelineProvider` on `List<TimelineRow>` and no document declares the class's fields;
07 §4.1 fixes the seven **columns**, and every later task in this epic renders whatever is decided
here.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§4.1 (`eweTimelineQuery` printed arm by arm — the seven `UNION ALL` legs, the `LAG` window function on `foster_events`, the `readsFrom:` set, why there is no `LIMIT`, and the paragraph on the four arms R37 unblocked)** · §1.2 (the one-query rule stated exactly, and what a screen may watch *besides* its content statement) · §4.2 (Frame 1 is a fixed-height placeholder at the summary line's height, never a spinner) | the statement, line for line |
| `docs/engineering/03-data-model-and-schema.md` | §5.5 (`Lambings`), §5.6 (`CareEvents` — the `CHECK` is exactly one of `lambing`/`lamb`, so there is **no `ewe` column**), §5.7 (`EweObservations`), §5.8 (`Treatments` — `administered_at`, `voided_at`), §5.9 (`PenOccupancies` — `entered_at`, `ewe` nullable), §5.12 (`Notes` — `occurred_at` distinct from `created_at`, `season` **nullable**), §7 (`FosterEvents` — one `rearing_dam` plus an outcome, `corrects`, append-only), §4.2 (the quad and its two paired CHECKs) | every column name and nullability the seven arms depend on |
| `docs/engineering/01-architecture.md` | §4.4 (**one statement per screen**, `customSelect` with an explicit `readsFrom:`, `.distinct()` in the repository never in the widget, and why `combineLatest` over drift streams is build-breaking), §7.2 (bucket A — values that change with no write) | the shape of `watchEweTimeline()` and what may not be in the row |
| `docs/engineering/02-state-di-navigation.md` | §3.1 (the corrected 2.6.1 family shape, printed — and the `EweCardData` snippet this task must **not** copy), §4.1–§4.2 (`StreamProvider` over one drift `watch()`; the auto-dispose policy), §4.5 (the only permitted `AsyncValue` form), §8.1 (`Routes.eweCard(context, EweId)`) | the provider, its scope, and how the screen reads it |
| `docs/engineering/CONVENTIONS.md` | §1 (**layer rule 5** — `lib/features/` may never import `lib/core/db/` or `package:drift/*`; **rule 8** — mutating drift APIs and `customStatement(` are confined), §2.1 (`EweId`, `LambingId`, `TreatmentId`, …), §2.2 (`Instant`, `TimeSource`), §2.13 (`FlockRepository`), **§3.2 (`eweTimelineProvider` — `StreamProvider.autoDispose.family<List<TimelineRow>, EweId>` in `lib/features/flock/ewe_card_controller.dart`)**, §4.1–§4.2 (file and type names), §4.6 (`occurred_at` and its three documented exceptions), R33 (ids cross boundaries, `int` does not), R37, R38 | **BINDING** on where the statement may live, what it is called, and every column spelling |
| `docs/design/indelible.md` | §8 screen 2 (the card: the summary first, then the seasons most recent first, notes printed as ruled rows with their own margin times), §7.3 (the ruled record row and its six states) | what order the rows arrive in, and which facts each row has to carry |
| `docs/engineering/12-testing.md` | §3.3 (`expectLater(stream, emitsInOrder([...]))`), §5.1–§5.3 (`pumpApp`, the targeted seed helpers, the closed twelve-file support list), §2.3 (the ambiguous hour, 01:00–01:59, 25 Oct 2026) | how a seven-arm stream is asserted, and the time case it needs |
| `docs/research/00-tech-decisions.md` | §5.1 (`sqlite3` **3.5.0** — window functions since 3.25, so `LAG` is safe), #12, #60 | the one engine fact the `foster` arm depends on |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | the union query, its indexes and its `readsFrom:` |
| `shed-riverpod-providers` | one statement per screen and the rebuild scope |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/ewe_card_test.dart`
- **Test** — `'the timeline is one statement and renders six event kinds in one ordered list'`
- **Why it is red today** — nothing reads a ewe's history, and this is the retention feature.

```bash
fvm flutter test test/features/ewe_card_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it cannot pass by coincidence. Seed **one** in-memory database with one ewe
and one row of every kind, at seven *distinct* instants deliberately out of insertion order — a note
written last about the earliest event, a foster whose `effective_at` sits between two lambings. Then
assert three things, not one:

1. `TimelineKind.values` and the kinds actually emitted are the **same set**, so an arm that was
   silently dropped fails rather than shrinking the list;
2. the emitted `at` values are in **descending** order — which the seeding order does not produce by
   accident;
3. the repository issued **one** statement, asserted from the source text of `flock_repository.dart`
   (`customSelect` appears once inside `watchEweTimeline`; `combineLatest` appears nowhere under
   `lib/`).

The test name says *six* kinds because 07 §4.1's prose says six; the statement has **seven** arms
(`care` is the one the prose folds into lambing). Keep the name — it is the anchor, and
`00-PLAN-CRITIQUE` §11.3 quotes it — and let case 1 assert the true count.

**Green.** The minimum code that passes, and nothing beyond it — one `customSelect` union with an explicit `readsFrom:`, ordered by occurrence.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 3 (one read method on the existing repository), step 4 (the provider), step 6 item 21 (the
route helper) and step 7 (tests).** No schema — every table and index this reads was frozen at
N07-T08. No domain and no ARB string yet: T02 builds the header and T04 builds the rows. Say the
skipped layers in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/flock_repository.dart` | **Edit.** `watchEweTimeline(EweId)` — one `customSelect` (07 §4.1's statement), one `.map` to `TimelineRow`, one `.distinct` with a real list comparator. The SQL lives here because layer rule 5 forbids `lib/features/` from importing `package:drift` at all, and because 02 §3.1 already routes the card through `flockRepositoryProvider` |
| 2 | `lib/features/flock/ewe_card_controller.dart` | **New.** `enum TimelineKind`, `final class TimelineRow`, and `eweTimelineProvider` — `StreamProvider.autoDispose.family<List<TimelineRow>, EweId>`, `async*` over `repo.watchEweTimeline(id)`, exactly the shape `CONVENTIONS §3.2` fixes |
| 3 | `lib/features/flock/ewe_card_screen.dart` | **New, minimal.** `EweCardScreen({required EweId eweId})` — the class `Routes.eweCard` already names (02 §8.1) — plus a `ListView` of one line per row. T04 turns each line into a real record row; this task proves the statement reaches a widget |
| 4 | `lib/routing/routes.dart` | **Edit.** `RouteNames.eweCard` and `Routes.eweCard(BuildContext, EweId)`. Critique **S2**'s ruling is that `routes.dart` grows one helper per screen epic; 02 §8.1 prints both already, and this is the epic that makes them compile |
| 5 | `test/support/seeds.dart` | **Edit.** `seedEweObservation`, `seedNote` and `seedFosterEvent` for the arms nothing has seeded yet. `seedEwe`, `seedOpenOccupancy`, `seedTreatment`, `seedAutoLambing` and `seedEditedLambing` already exist (12 §5.3) — **do not add a thirteenth support file** |
| 6 | `test/features/ewe_card_test.dart` | **New.** The anchor plus §5.4's cases |
| 7 | `test/features/ewe_card_dst_test.dart` | **New.** `@Tags(['uk-zone'])`; the two ambiguous-hour cases in §5.4 |

### 5.2 The signatures

One enum, one value type, one repository method, one provider. `TimelineRow` carries exactly the
columns 07 §4.1 projects, plus P1's `struck` pair — nothing derived, nothing formatted.

```dart
// lib/features/flock/ewe_card_controller.dart
//
// CONVENTIONS §3.2 names TimelineRow in eweTimelineProvider's type and no
// document declares its fields. 07 §4.1 fixes the COLUMNS; this is the Dart
// shape. If a second document later needs it, the ruling belongs in
// CONVENTIONS §6.

/// The seven UNION ALL arms of 07 §4.1, in the order they are written there.
/// The stored key IS the SQL literal in each arm's first column, so the two are
/// readable off each other (CONVENTIONS §2.9's convention, applied).
enum TimelineKind {
  lambing('lambing'),
  treatment('treatment'),
  care('care'),
  foster('foster'),
  observed('observed'),
  penned('penned'),
  note('note');

  const TimelineKind(this.key);
  final String key;
  static TimelineKind fromKey(String key) => values.firstWhere((k) => k.key == key);
}

@immutable
final class TimelineRow {
  const TimelineRow({
    required this.kind,
    required this.ref,
    required this.at,
    required this.capturedAt,
    required this.timeSource,
    required this.struck,
    this.originalEffective,
    this.season,
    this.struckAt,
  });

  final TimelineKind kind;
  final int ref;              // the row id WITHIN its own table — see §5.3 item 5
  final Instant at;           // occurred_at / administered_at / entered_at / effective_at
  final Instant capturedAt;   // the §12.5 quad, all four columns, on every arm
  final Instant? originalEffective;
  final TimeSource timeSource;
  final SeasonId? season;     // NOT NULL on six arms; nullable on `note` (03 §5.12)
  final bool struck;          // P1. Nothing on this screen filters on it
  final Instant? struckAt;

  /// The §12.5 value, reconstructed — never a second switch over time_source.
  /// RecordedTime owns provenanceLabel by an exhaustive switch that can never
  /// be empty (05 §4.1). T04 renders it. See §5.3 item 7.
  RecordedTime get recorded => switch (timeSource) {
        TimeSource.autoCaptured => RecordedTime.capture(at),
        TimeSource.userEntered  => RecordedTime.entered(effective: at, now: capturedAt),
        TimeSource.userEdited   =>
            RecordedTime.entered(effective: originalEffective!, now: capturedAt).editedTo(at),
      };

  @override
  bool operator ==(Object other) => /* every field; see §5.3 item 4 */;
  @override
  int get hashCode => /* Object.hash over the same fields */;
}

final eweTimelineProvider =
    StreamProvider.autoDispose.family<List<TimelineRow>, EweId>((ref, eweId) async* {
  final repo = await ref.watch(flockRepositoryProvider.future);
  yield* repo.watchEweTimeline(eweId);
});
```

And the statement, in the repository, with 07 §4.1's `readsFrom:` set:

```dart
// lib/data/flock_repository.dart
Stream<List<TimelineRow>> watchEweTimeline(EweId ewe) => _db
    .customSelect(
      _eweTimelineSql,                     // 07 §4.1 verbatim, plus struck / struck_at
      variables: [Variable<int>(ewe.value)],
      readsFrom: {
        _db.lambings, _db.treatments, _db.careEvents, _db.lambs,
        _db.fosterEvents, _db.eweObservations, _db.penOccupancies, _db.notes,
      },
    )
    .watch()
    .map(_toTimelineRows)
    .distinct((a, b) => const ListEquality<TimelineRow>().equals(a, b));
```

### 5.3 The details that are easy to get wrong

1. **The statement cannot live in the feature folder, however much `00-README` §8 step 14 sounds like
   it can.** Layer rule 5 bans `package:drift/*` and `lib/core/db/` from `lib/features/` outright, and
   `customSelect` is a drift API. The provider lives in the feature file (`CONVENTIONS §3.2`); the
   *statement* lives in the repository. Same split 02 §5.1 prints for the pen board, same one
   N19-T02 already built.
2. **`readsFrom:` is eight tables, not seven.** The arms name seven, but the `foster` arm joins `lambs`
   for `lb.birth_dam` and the `care` arm joins `lambs` too. Miss `lambs` and a lamb row written
   anywhere else never re-runs this statement — the failure presents as *"the app is stale"*, never as
   a query error. 07 §4.1 lists all eight; the list is a test's business as well as the code's.
3. **`care_events` has no `ewe` column.** 03 §5.6's `CHECK` is *exactly one* of `lambing` / `lamb`, so
   her care events are reached through her lambings **and** through the lambs she bore —
   `WHERE lg2.ewe = :ewe OR lb2.birth_dam = :ewe`, with two `LEFT JOIN`s. `c.ewe = :ewe` does not
   compile against the real schema; writing only the lambing half silently loses every navel-dip
   recorded on a lamb.
4. **`.distinct` over a `List` does nothing unless `TimelineRow` has a real `==`.** `List` equality is
   identity, and `freezed` is banned (decision #16 — drift is the only generator), so `==` and
   `hashCode` are hand-written over every field. Without them drift re-emits on **any** write to any
   of the eight tables, and the card visibly re-lays-out while it is being read (01 §4.4).
5. **`ref` is an id *within its own table*, not a global key.** Lambing 7 and note 7 are both `ref: 7`.
   Anything keyed on a row — the widget key in T04, a `ValueKey`, a `Map` — is keyed on the **pair**
   `(kind, ref)`. A `Map<int, TimelineRow>` on this screen silently drops rows. Keep `ref` a bare
   `int` inside the row and wrap it into `LambingId` / `TreatmentId` / … at the one tap handler that
   navigates (R33).
6. **P1's `struck` / `struck_at` must be projected on every arm, and nothing may filter on them.**
   `mixin Identified` carries them on all sixteen tables (N07-T02); 07 §4.1's published statement
   predates the ruling and does not list them; and Indelible §8 screen 2 is explicit that a struck
   entry staying visible *"is the whole point of year two"*. Add the two columns to every arm in the
   same position. Do **not** add `WHERE struck = 0`.
7. **`RecordedTime` is reconstructed, not stored.** The quad comes back as four raw values;
   `TimelineRow.recorded` rebuilds the value type so the label comes from 05 §4.1's exhaustive switch
   rather than from a second `switch` in a widget. There is no public generative constructor — the
   `userEdited` arm goes through `.entered(...).editedTo(at)`, which is the only spelling that puts
   `originalEffective` back where it belongs. A test asserts the round trip preserves it. **Never**
   render a label from `time_source` directly; that is a second implementation of a §12.5 mechanism,
   and 05 §4.4 exists because an empty label must be unrepresentable.
8. **The `foster` arm needs `LAG` and needs all three of its `OR` legs.** `foster_events` has one
   `rearing_dam` and an outcome — there is no `from_ewe`. *"She lost a lamb to a foster"* is the
   **previous** rearing dam: `LAG(rearing_dam) OVER (PARTITION BY lamb ORDER BY effective_at, id)`.
   The third leg — `prev_dam IS NULL AND lamb_birth_dam = :ewe` — is the first foster off a lamb she
   bore, and dropping it loses exactly the event a shepherd opens the card to find. `sqlite3`
   **3.5.0** is bundled (decision-record §5.1) and window functions have existed since 3.25, so this
   is safe — safe *because we bundle the engine*, not because the device happens to have one.
9. **There is no `LIMIT` and there must not be one.** 07 §4.1: a ewe's whole life over five seasons is
   ~80 rows across indexed tables, sub-millisecond. A `LIMIT 50` with a "load more" affordance costs a
   tap and a decision at the one moment the product promises neither.
10. **`ORDER BY at DESC` is on the outer statement, and the result names come from the left-most
    `SELECT`** (07 §4.1's comment). Alias the first arm's columns exactly as the outer `ORDER BY`
    expects; naming a column differently in a later arm compiles and sorts the wrong thing.
11. **`combineLatest` is a build-breaking defect** (01 §4.4, decision #12), and this is the screen
    where it looks unavoidable. Seven streams merged in Dart renders a foster whose lambing has not
    arrived yet — a history that never existed in the database. drift#3338 is open and its maintainer
    calls the torn emission working as intended. Fan-in happens in SQL.
12. **02 §3.1's `EweCardController` / `EweCardData` snippet is an API demonstration, not this screen's
    architecture.** It exists to print the corrected 2.6.1 family shape after the research notes got it
    wrong, and it calls `repo.eweCard(arg)` — a method `CONVENTIONS §2.13` does not declare. Copying it
    puts **data** in a screen controller, which §4.4 rule 1 forbids outright. The data is
    `eweTimelineProvider`; `eweCardControllerProvider` is screen state and arrives in T07.
13. **`.autoDispose.family`, both of them.** `CONVENTIONS §3.2` and §3.4 fix it, and the reason is
    arithmetic: a keepAlive family holds one live stream per ewe opened — 400 of them by the end of a
    night. `EweId` is an extension type over `int` with real `==`, so the family key does not mint a
    new provider per rebuild (R33).
14. **`AsyncValue` is read as an exhaustive `switch`, never through `.value`, `.hasValue` or
    `.when`** (02 §2.2, §4.5). `AsyncLoading` renders the fixed-height placeholder at the summary
    line's exact height (07 §4.2), never a spinner — `CircularProgressIndicator` under
    `lib/features/**` is a gate row.

### 5.4 The full test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/features/ewe_card_test.dart` | `'the timeline is one statement and renders six event kinds in one ordered list'` | **The anchor.** All seven arms seeded out of order; kinds compared as a set; `at` descending; one `customSelect` |
| | `'a care event on a lamb she bore appears on her timeline'` | The `lb2.birth_dam = :ewe` half of the `care` arm — the half that is silently lost |
| | `'a care event on her lambing appears exactly once, not twice'` | Both `LEFT JOIN`s matching means a cross product; a duplicated care row is the tell |
| | `'a foster that moved a lamb away from her appears on her timeline'` | `LAG`'s `prev_dam = :ewe` leg |
| | `'the first foster off a lamb she bore appears on her timeline'` | `prev_dam IS NULL AND lamb_birth_dam = :ewe` — the third leg |
| | `'a foster of a lamb she never bore and never reared does not appear'` | The negative. Without it the three-leg predicate can be over-broad and still pass every positive case |
| | `'a struck lambing is present in the timeline and carries struck_at'` | P1, and Indelible §8 screen 2. The counterpart of N21-T02's CSV assertion |
| | `'a voided treatment is present in the timeline'` | Soft-void (decision #69) is not deletion; the medicine book keeps it and so does the card |
| | `'a note with a null season is present and its season is null'` | `notes.season` is the one nullable one (03 §5.12); T07 groups it honestly |
| | `'a note occurring at 03:20 but written at 07:00 sorts on 03:20'` | `notes.occurred_at` vs the mixin's `created_at` — R37's reason for adding the column at all |
| | `'an edited lambing round-trips original_effective through the statement'` | The quad survives SQLite, not just Dart (12 §2.4's data tier) |
| | `'writing an unrelated ewe does not re-emit an identical timeline'` | `.distinct` plus a real `==`; assert with `expectLater(stream, emitsInOrder([...]))` and a rebuild count |
| | `'recording a treatment re-emits the timeline exactly once'` | The other direction — de-duplication that swallows a real change is worse than none |
| | `'the statement declares all eight tables in readsFrom'` | Source-text assertion over `flock_repository.dart`. Cheap, and it is the failure that presents as staleness rather than as an error |
| | `'combineLatest appears nowhere under lib/'` | Duplicates the gate row deliberately, in the tier a developer runs first |
| | `'popping the card leaves eweTimelineProvider with no listeners'` | `.autoDispose.family`, proved rather than declared |
| `test/features/ewe_card_dst_test.dart` | `@Tags(['uk-zone'])` · `'a lambing at 01:30 on 25 October 2026 keeps its wall time and its position in the timeline'` | The ambiguous hour, which happens twice (12 §2.3). Assert the rendered `HH:mm` **and** the row's rank, seeded either side of the repeated hour |
| | `'a lambing at 22:00 GMT on 28 March 2026 sorts before one at 08:00 BST on 29 March'` | Spring-forward. Ordering is on epoch millis, so this only ever fails if a `LocalDate` creeps into the sort |

The DST file carries `setUpAll` asserting `DateTime(2026, 7, 1).timeZoneOffset == const Duration(hours: 1)`
so a run outside `TZ=Europe/London` fails loudly instead of passing for the wrong reason (12 §2.3).

## 6. Constraints that bind this task

- **One statement per screen** — the timeline is one `customSelect` with an explicit `readsFrom:`;
  nothing here is computed from two drift streams (07 §1.2, decision #12).
- **Layer rules** — the statement in `lib/data/`, the provider in `lib/features/flock/`, no
  sibling-feature import in either direction, and no `package:drift` under `lib/features/`.
- **Nothing derived is stored, and nothing is filtered** — struck rows stay, voided treatments stay,
  and the row carries columns, never a formatted string.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the timeline is one statement and renders six event kinds in one ordered list'` passes, and was seen to fail first for the stated reason
- [ ] one statement, no `combineLatest`
- [ ] all six event kinds present
- [ ] ordered by `occurred_at`, not by `created_at`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `TimelineKind` has exactly seven members and each carries the SQL literal of its own arm
- [ ] `TimelineRow` carries the whole §12.5 quad plus P1's `struck` / `struck_at`, with hand-written `==` / `hashCode`, and `.distinct` is proved to suppress an identical re-emission
- [ ] `readsFrom:` names all **eight** tables, `lambs` included
- [ ] `eweTimelineProvider` is `.autoDispose.family` keyed on `EweId`, and popping the card leaves it with no listeners
- [ ] `RouteNames.eweCard` and `Routes.eweCard(context, EweId)` compile, and the count still holds — thirteen names, twelve push helpers (02 §8.1)
- [ ] `test/support/` still has twelve files (12 §5.3)

## 8. Verification

```bash
# 1. Red first, for the stated reason.
fvm flutter test test/features/ewe_card_test.dart

# 2. Green, plus the zone leg — the ambiguous hour does not exist under UTC.
fvm flutter test test/features/ewe_card_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone

# 3. Both gates.
make check
make test
```

```bash
grep -n "readsFrom" lib/data/flock_repository.dart   # expect: eight tables in the timeline set
grep -rn "combineLatest" lib/                        # expect: nothing
grep -rn "package:drift" lib/features/               # expect: nothing (layer rule 5)
grep -n "struck" lib/data/flock_repository.dart      # expect: projected, never in a WHERE
grep -n "LIMIT" lib/data/flock_repository.dart       # expect: nothing in the timeline statement
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ewe_card): the timeline as one SQL statement`

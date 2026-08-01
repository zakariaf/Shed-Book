# N16-T01 — `lambingEntryProvider` — one statement for a `LambingId`

| | |
|---|---|
| **Epic** | [N16 — Lambing Entry and the P8 ruling](epic.md) · `00-README` §9 step 6 (2 of 5) |
| **Task** | 1 of 10 |
| **Depends on** | N15-T06 |
| **Commit** | one commit · `feat(lambing_entry): one statement producing LambingEntryData` |

## 1. Why this task exists

One drift statement producing `LambingEntryData` for a `LambingId`: the lambing, its
lambs, its care events and its warnings, fanned in **in SQL**.

This is the screen a shepherd is on while holding a lamb, so it cannot afford four streams combined in
Dart: the fan-in happens once, in SQL, and the screen rebuilds against one dependency list.

`07 §1.2` states the rule exactly — *"no displayed value may be computed from two drift streams; if
two streams have to agree for the screen to be correct, they are one statement."* On this screen the
derived birth type is computed from the lamb count and printed beside the declared type, so the two
**must** agree; that alone settles the shape. Everything the rest of the epic renders reads off the
value this task produces.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §6.2 (**the statement, verbatim, with its `readsFrom:` and its `LEFT JOIN` second arm**) · §1.2 (the one-query rule) · §6.3 (the state table — frame 1 is impossible here) · §1.4 (never a spinner) | the SQL, the controller shape and the states |
| `docs/engineering/CONVENTIONS.md` | §1.1 layer rules **3, 4, 5** · §2.1 (`LambingId`) · §3.2 (`lambingEntryProvider`'s type, file and dispose policy) · §3.4 (two objects per screen) · §4.1 · §4.3 · R33 (ids cross boundaries, `int` does not) | **BINDING** — where the statement may live and what everything is called |
| `docs/engineering/03-data-model-and-schema.md` | §5.4 (`Lambings`' columns) · §5.5 (`Lambs`) · §5.6 (`CareEvents` and its exactly-one `CHECK`) · §2.1 (`mixin Identified`, and P1's `struck` / `struck_at`) | every column the `SELECT` names |
| `docs/engineering/02-state-di-navigation.md` | §2.1–§2.2 (the nine banned Riverpod-3 spellings) · §3 (the 2.6.1 spelling card) · §4.2 (auto-dispose) · §4.4 (`.select`) · §8.1 (the push helper) | the provider spelling and the route |
| `docs/engineering/12-testing.md` | §2.4 (**`test/data/lambing_ambiguous_hour_test.dart`, already published**) · §3.1 (one way to build a test database) · §3.6 (`closeStreamsSynchronously`) · §5.1 (`pumpApp`) | how the statement is tested at two tiers |
| `docs/research/00-tech-decisions.md` | §5 · #12 (one statement per screen) · #19 (2.6.1 family args through `build`) · #60 (`customSelect` with explicit `readsFrom:`) · #21 (frame 1) | the decisions this shape applies |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-riverpod-providers` | one statement per screen, `.select` and the rebuild scope |
| `shed-drift-schema` | the fan-in belongs in SQL and this is its statement |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/lambing_entry_test.dart`
- **Test** — `'the screen reads one statement and no combineLatest appears in the feature'`
- **Why it is red today** — nothing reads a lambing back, and the obvious implementation combines four streams in Dart.

```bash
fvm flutter test test/features/lambing_entry_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion in two ways. Prove **one** statement rather than *not four*: seed a lambing with
two lambs and one care event, pump the screen, and assert every fact renders after a single
`pumpAndSettle` with no intermediate frame in which one of them is missing. Then assert the negative
on the **source text** of `lib/features/lambing/` — `combineLatest`, `Rx.combineLatest`, `package:drift`
and `lib/core/db/` all appear zero times. The second half is what stops the defect coming back in a
widget nobody is looking at.

**Green.** The minimum code that passes, and nothing beyond it — one `customSelect` with an explicit `readsFrom:` and a data class per screen.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step, and say so in the commit message.** The lambing cluster froze at N07-T08; this task
reads columns that already exist and stores nothing new. There is no domain step either — the
derivation lands in T02 and the validators in T06.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/lambing_repository.dart` | **Extended** (created at N14-T02 for `beginLambing`). Gains `LambingEntryData` and its three row records, and `Stream<LambingEntryData> watchLambingEntry(LambingId)` holding the one `customSelect`. It lives here and not in the feature because layer rule 5 forbids `lib/features/` from importing `package:drift` at all — see §5.3 |
| 2 | `lib/data/providers.dart` | **Unchanged, and that is the check.** `lambingRepositoryProvider` is already declared (`CONVENTIONS §3.1`, `FutureProvider<LambingRepository>`, keepAlive, taking `NotificationScheduler` + `MediaStore`). If this file moves in the diff, a second repository is being invented |
| 3 | `lib/features/lambing/lambing_entry_controller.dart` | **New.** `lambingEntryProvider` — the `StreamProvider.autoDispose.family<LambingEntryData, LambingId>` `CONVENTIONS §3.2` names, in the file `CONVENTIONS §3.2` names. Nothing else yet: `lambingEntryControllerProvider` (screen state) and `lambingWriteControllerProvider` arrive in T02, when there is state to hold and a write to guard |
| 4 | `lib/features/lambing/lambing_entry_screen.dart` | **New.** `LambingEntryScreen({required LambingId lambingId})` — the shell that watches the provider and renders the header, the lambs region and the care region as empty regions. It has to exist for the anchor test to pump something |
| 5 | `lib/routing/routes.dart` | **Extended.** `Routes.lambingEntry(BuildContext, LambingId)`, exactly as `02 §8.1` prints it. N13-T01 landed `RouteNames.lambingEntry` with the other twelve names and **only the Quick Entry helper**, with a comment saying each screen epic adds its own. This is that epic |
| 6 | `lib/l10n/app_en.arb` | **Extended.** The screen title and the two region headings, each with a `description`. `10 §3.4`: Lambing Entry deliberately gets **no `headingLevel: 2`** — it is one task and heading stops would add navigation to a screen whose whole purpose is not having any. The screen title still emits `headingLevel: 1`, because `12 §7.3`'s gate asserts at least one heading node on every variant |
| 7 | `test/support/seeds.dart` | **Extended.** `seedLambing`, `seedLamb` and `seedCareEvent`, written with drift companions against `NativeDatabase.memory()`. Every later task in this epic seeds through them |
| 8 | `test/features/lambing_entry_test.dart` | **New.** The anchor, plus the source-text negatives |
| 9 | `test/data/lambing_repository_test.dart` | **Extended** (created at N14-T02). The statement's own cases: the fan-in, the `readsFrom:` re-emission, and the pre-lamb care event |
| 10 | `test/data/lambing_ambiguous_hour_test.dart` | **Extended** (created at N14-T02 from `12 §2.4`). One read-back case in the repeated hour |

### 5.2 The signatures

The statement is `07 §6.2`'s, verbatim. Do not re-derive it and do not "tidy" the column list:

```dart
// lib/data/lambing_repository.dart
Stream<LambingEntryData> watchLambingEntry(LambingId lambing) {
  return _db
      .customSelect(
        'SELECT lg.id AS lambing_id, lg.ewe, lg.season, lg.declared_birth_type, lg.ease, '
        '       lg.occurred_at, lg.captured_at, lg.original_effective, lg.time_source, '
        '       lg.assisted_by, lg.presentation, lg.presentation_note, lg.note, '
        '       lg.struck AS lambing_struck, '
        '       l.id AS lamb_id, l.sex, l.status, l.birth_weight_g, l.tag, '
        '       l.struck AS lamb_struck, '
        '       c.id AS care_id, c.kind AS care_kind, c.volume_ml, c.method, '
        '       c.occurred_at AS care_occurred_at, c.time_source AS care_time_source, '
        '       c.struck AS care_struck '
        '  FROM lambings lg '
        '  LEFT JOIN lambs l       ON l.lambing = lg.id '
        // CareEvents' CHECK is exactly one of (lambing, lamb). This screen
        // writes every care event against a LAMB; the nullable `lambing` FK
        // exists for a care action taken before any lamb is attached, and the
        // second arm picks those up on the null-lamb row the outer LEFT JOIN
        // produces. Deleting it is silent: the rows stop appearing.
        '  LEFT JOIN care_events c ON c.lamb = l.id '
        '                          OR (l.id IS NULL AND c.lambing = lg.id) '
        ' WHERE lg.id = :lambing '
        ' ORDER BY l.id ASC, c.id ASC',
        variables: [Variable.withInt(lambing.value)],
        readsFrom: {_db.lambings, _db.lambs, _db.careEvents},
      )
      .watch()
      .map(_foldLambingEntry);
}
```

The value it produces. `LambingEntryData` is declared **in `lib/data/`**, because `lib/features/` may
import `lib/data/` and may not import `lib/core/db/`:

```dart
// lib/data/lambing_repository.dart
/// One screen, one value. Assembled from ONE statement; nothing here is
/// computed from a second stream.
final class LambingEntryData {
  const LambingEntryData({
    required this.lambing,
    required this.lambs,
    required this.lambingCare,
  });

  final LambingHeaderRow lambing;

  /// Insertion order IS stroke order — `ORDER BY l.id ASC`. Struck lambs stay
  /// in the list (Indelible rule 1: nothing disappears from the page); the
  /// widget decides how a struck stroke renders, the statement never filters.
  final List<LambEntryRow> lambs;

  /// Care events attached to the LAMBING rather than to a lamb — recorded
  /// before the first stroke. Never merged into [lambs]; they are a different
  /// fact and `care_events`' CHECK keeps them distinguishable.
  final List<CareEntryRow> lambingCare;
}

final class LambingHeaderRow {
  const LambingHeaderRow({
    required this.id, required this.ewe, required this.season,
    required this.declaredBirthType, required this.ease, required this.time,
    required this.assistedBy, required this.presentation,
    required this.presentationNote, required this.note, required this.struck,
  });
  final LambingId id;
  final EweId ewe;
  final SeasonId season;
  final BirthType? declaredBirthType;   // NULL = not declared (R6), never `single`
  final LambingEase? ease;              // NULL = not scored, never "1 — unassisted"
  final RecordedTime time;              // the whole §12.5 quad, assembled here
  final String? assistedBy;
  final String? presentation;           // a vocab_terms.key, resolved at the edge
  final String? presentationNote;
  final String? note;
  final bool struck;
}

final class LambEntryRow {
  const LambEntryRow({
    required this.id, required this.sex, required this.status,
    required this.birthWeight, required this.tag, required this.struck,
    required this.care,
  });
  final LambId id;
  final Sex? sex;                       // NULL != Sex.unknown (R45)
  final LambStatus status;
  final Grams? birthWeight;             // canonical grams, never a double
  final String? tag;
  final bool struck;
  final List<CareEntryRow> care;
}

final class CareEntryRow {
  const CareEntryRow({
    required this.id, required this.kind, required this.volumeMl,
    required this.method, required this.time, required this.struck,
  });
  final CareEventId id;
  final String kind;                    // one of the four closed CHECK values
  final int? volumeMl;
  final String? method;
  final RecordedTime time;
  final bool struck;
}
```

The provider, in 2.6.1 spelling, with the family argument delivered through `build`:

```dart
// lib/features/lambing/lambing_entry_controller.dart
final lambingEntryProvider = StreamProvider.autoDispose
    .family<LambingEntryData, LambingId>((ref, lambing) async* {
  final repo = await ref.watch(lambingRepositoryProvider.future);
  yield* repo.watchLambingEntry(lambing);
});
```

### 5.3 The details that are easy to get wrong

- **`customSelect` cannot go in the controller file, whatever `00-README` §8 step 4 says.** Step 4
  item 14 reads *"the read provider goes in the feature's controller file, one drift statement per
  screen; aggregates use `customSelect` with an explicit `readsFrom:`"* — and **layer rule 5** bans
  `lib/features/` from importing `package:drift/*` and `lib/core/db/` outright. Both are true at once
  only in the split above: the **statement** is the repository's, the **provider** is the feature's.
  The gate (`layer.features`) fails the build before the analyzer gets a word in, so you will find
  out — but you will find out after writing it the other way round.
- **`readsFrom:` is the whole subscription and a missing table is silent.** With
  `readsFrom: {lambings, lambs}` and no `careEvents`, the screen renders correctly on first load and
  then never updates when a care event lands. Nothing throws. `12 §3.3`'s pattern — write through the
  repository, then `expectLater` on the stream — is the only thing that catches it.
- **`lg.*` is banned and the reason is not style.** A `SELECT *` over a table carrying the
  `Identified` mixin silently widens every time doc 03 adds a column, and `customSelect` result
  parsing is positional-by-name — so the column list is written out, and every alias
  (`lambing_id`, `lamb_id`, `care_id`, `care_kind`, `care_occurred_at`, `care_time_source`, and the
  three `*_struck`) exists because two tables in the join spell the same column name.
- **The `LEFT JOIN`'s second arm is not redundant.** `care_events`' constraint is
  `CHECK ((lambing IS NOT NULL) + (lamb IS NOT NULL) = 1)` — *exactly one*, not at-least-one. A care
  action taken before the first stroke hangs off the lambing, and it only appears on the null-lamb
  row the outer `LEFT JOIN` produces. Drop `OR (l.id IS NULL AND c.lambing = lg.id)` and colostrum
  given at 03:22 to a lamb not yet counted vanishes from the screen while staying in the database.
- **The result set is a flat product and the fold is where the bugs are.** One lambing with three
  lambs and two care events each is six rows, every one repeating the lambing header. Fold on
  `lamb_id` with a `null` bucket for the pre-lamb care, and assert `lambs` is de-duplicated: the
  obvious `rows.map(...)` produces six lambs and a tally that reads `6 (COUNTED)` for three.
- **Struck rows stay in.** P1 was ruled at N00-T05: `struck` / `struck_at` sit on every table through
  `mixin Identified`, and Indelible rule 1 is *"if a proposal makes information disappear from the
  page, it is wrong."* The statement selects the flag and filters nothing; the **count** excludes
  struck lambs (T02), the **list** shows them ruled through (T03).
- **The family argument is `LambingId`, never a bare `int`** (R33). `07 §6.1`'s old
  `AutoDisposeFamilyAsyncNotifier<LambingEntryState, int>` is exactly the defect the ruling names. A
  bare `int` lives only inside `lib/core/db/` and as `WriteCommitted.insertedId`, which the one call
  site that reads it wraps.
- **`.autoDispose.family`, not keepAlive.** `CONVENTIONS §3.2` and `02 §4.2`: per-animal providers
  auto-dispose. A keepAlive family holds one statement per lambing the shepherd opened tonight, and a
  400-ewe flock in March is how that becomes visible.
- **Nine Riverpod-3 spellings are compile errors or gate rows here** (`02 §2`, decision #18):
  `ProviderScope.retry`, `ProviderContainer.test()`, `WidgetTester.container`, bare `Notifier` with
  `.autoDispose`, Mutations, `AsyncValue.valueOrNull`, `StateProvider`, `StateNotifierProvider`, and
  constructor-delivered family arguments. `valueOrNull` compiles on 2.6.1 and is still banned, because
  avoiding it now makes a later migration near-free. Read the `AsyncValue` with a `switch`.
- **`lambingRepositoryProvider` is a `FutureProvider`**, so the read is
  `await ref.watch(lambingRepositoryProvider.future)` inside an `async*` body. `ref.watch(p).value!`
  is the shape that compiles and then throws on the one frame that matters.
- **Frame 1 is impossible on this screen and there is still no spinner.** `07 §6.3`: the row is
  committed before the push, so the statement always has a row to find. While the future resolves,
  render a fixed-height placeholder in the same surface colour — `CircularProgressIndicator` under
  `lib/features/` is a gate row (`ui.spinner`, decision #71), not a review remark.
- **`RecordedTime` is assembled here, not in the widget.** The four columns
  (`occurred_at`, `captured_at`, `original_effective`, `time_source`) become one `RecordedTime` in the
  fold, so nothing downstream can render `occurred_at` without its provenance. That is `05 §4.3`'s
  first row — *"never a bare `03:21`"* — held by the type rather than by review.
- **The widget test needs `closeStreamsSynchronously: true`** on its `DatabaseConnection`
  (`12 §3.6`). Without it every stream-touching widget test fails on a pending timer, and the failure
  names the timer rather than the cause.
- **Do not add a second provider for the warnings.** They are computed by the controller from this
  value in T06, in Dart, from data already in hand — never a fifth stream and never a `warnings`
  column, which the schema does not have (decision #54).

### 5.4 The full test set

| File · case | What it asserts |
|---|---|
| `test/features/lambing_entry_test.dart` · `'the screen reads one statement and no combineLatest appears in the feature'` | **The anchor.** A lambing with two lambs and one care event renders every fact after one `pumpAndSettle`, and the source text of `lib/features/lambing/` contains no `combineLatest`, no `package:drift` and no `lib/core/db/` |
| `test/features/lambing_entry_test.dart` · `'the screen renders a fixed-height placeholder and never a spinner while the repository future resolves'` | `find.byType(CircularProgressIndicator)` is empty at every pumped frame, and the region heights do not shift when data lands |
| `test/features/lambing_entry_test.dart` · `'the screen title emits headingLevel 1 and no node emits headingLevel 2'` | `10 §3.4`'s table. Opens `tester.ensureSemantics()` with `addTearDown(handle.dispose)` |
| `test/data/lambing_repository_test.dart` · `'watchLambingEntry folds three lambs and six care rows into three lambs'` | The flat product is de-duplicated. Three lambs, two care events each, and `data.lambs` has length 3 |
| `test/data/lambing_repository_test.dart` · `'a care event recorded before the first lamb reads back on lambingCare'` | The `LEFT JOIN`'s second arm. Colostrum against the lambing with zero lambs attached |
| `test/data/lambing_repository_test.dart` · `'the stream re-emits when a lamb is inserted, when a care event is inserted and when the lambing is updated'` | `readsFrom:` covers all three tables. Three `expectLater` emissions, one per table |
| `test/data/lambing_repository_test.dart` · `'a struck lamb stays in the list and carries its struck flag'` | Indelible rule 1 at the data tier. The statement filters nothing |
| `test/data/lambing_repository_test.dart` · `'an undeclared birth type reads back as null and an unscored ease reads back as null'` | R6 and decision #59. Neither is defaulted, in either direction |
| `test/data/lambing_repository_test.dart` · `'the four provenance columns arrive as one RecordedTime with its label'` | The quad is assembled in the fold; `provenanceLabel` is non-empty for the auto-captured case |
| `test/data/lambing_repository_test.dart` · `'the statement names every column and no SELECT star appears in the repository'` | Source text. `SELECT *` and `lg.*` appear zero times under `lib/data/` |
| `test/data/lambing_ambiguous_hour_test.dart` · `'a lambing captured at 01:30 in the repeated hour reads back as 01:30 with local_date 25 October'` | **`uk-zone`.** `@Tags(['uk-zone'])` at the top of the library, `setUpAll` asserting the process offset, and `atFixed(DateTime(2026, 10, 25, 1, 30), …)`. The denormalised civil date must land on the 25th, not the 24th — a one-day error puts a bar in the wrong column of the only chart in the app |

The zone-pinned file runs under `TZ=Europe/London fvm flutter test --tags uk-zone`, **unscoped**
(`12 §2.5`). Scoped to `test/domain`, this file runs in the runner's zone — UTC on `ubuntu-latest`,
where there is no repeated hour and the case passes without asserting anything.

## 6. Constraints that bind this task

- **Layer rules 3, 4 and 5** — `lib/data/` may import drift and may not import `package:flutter/material.dart`; `lib/features/` may import `lib/data/` and may import neither drift nor `lib/core/db/`. The split in §5.1 is the only arrangement that satisfies all three.
- **One statement per screen** — `07 §1.2`. `combineLatest` over drift streams is a build-breaking defect, and two streams that must agree are one statement.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the screen reads one statement and no combineLatest appears in the feature'` passes, and was seen to fail first for the stated reason
- [ ] one statement
- [ ] explicit `readsFrom:`
- [ ] no `combineLatest` anywhere in the feature
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `package:drift` and `lib/core/db/` appear nowhere under `lib/features/`
- [ ] the family argument is `LambingId`, never a bare `int`, and the provider is `.autoDispose.family`
- [ ] the `LEFT JOIN`'s second arm is present, and a test records a care event with zero lambs attached
- [ ] the fold de-duplicates the flat product; three lambs with two care events each produce three lambs
- [ ] struck rows are selected and never filtered by the statement
- [ ] `SELECT *` and `lg.*` appear nowhere under `lib/data/`
- [ ] the four provenance columns arrive as one `RecordedTime`, so no widget can render a bare time
- [ ] `Routes.lambingEntry(BuildContext, LambingId)` exists and takes an extension-type id
- [ ] the ambiguous-hour read-back case exists, is tagged `uk-zone`, and asserts `local_date`
- [ ] none of the nine banned Riverpod-3 spellings appears in the diff

## 8. Verification

```bash
fvm flutter test test/features/lambing_entry_test.dart
fvm flutter test test/data/lambing_repository_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

Prove the two silent failures are actually caught — break each, watch the named test fail, revert:

```bash
# 1. drop careEvents from readsFrom: and watch the re-emission case fail
# 2. drop the LEFT JOIN's second arm and watch the pre-lamb care case fail
fvm flutter test test/data/lambing_repository_test.dart
git checkout -- lib/data/lambing_repository.dart
```

```bash
grep -rn "combineLatest\|package:drift\|core/db" lib/features/lambing/   # expect zero
grep -rn "SELECT \*\|lg\.\*" lib/data/                                   # expect zero
grep -rn "valueOrNull\|StateProvider\|StateNotifierProvider" lib/         # expect zero
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(lambing_entry): one statement producing LambingEntryData`

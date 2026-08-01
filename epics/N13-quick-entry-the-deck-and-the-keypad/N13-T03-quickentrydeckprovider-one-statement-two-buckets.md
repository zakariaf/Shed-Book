# N13-T03 — `quickEntryDeckProvider` — one statement, two buckets

| | |
|---|---|
| **Epic** | [N13 — Quick Entry: the deck and the keypad](epic.md) · `00-README` §9 step 5 (1 of 2) |
| **Task** | 3 of 7 |
| **Depends on** | N13-T02 |
| **Commit** | one commit · `feat(quick_entry): quickEntryDeckProvider, one statement and two buckets` |

## 1. Why this task exists

The deck: *in the pens* and *recents*, in **one** drift statement with an explicit
`readsFrom:`, read by the two strips through `.select` so a change to one bucket does not rebuild the
other. `combineLatest` over drift streams is a build-breaking defect — the fan-in happens in SQL.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§5.2** (the query, printed in full as SQL, with `readsFrom:`, the `IS NOT NULL` predicate and the `ewe_touches` primary-key argument) · §1.2 (the one-query rule, stated exactly) · §5.3 (the states the two strips render) | the statement, verbatim, and the rule it obeys |
| `docs/engineering/02-state-di-navigation.md` | §4.2 (hub reads are keepAlive; the deck is **one** provider, not two) · **§4.4** (`.select`, and why a stored `List` deduplicates nothing) · §4.5 (the exhaustive `AsyncValue` switch, and *loading is never a spinner*) · §10.1 (the rebuild table: neither strip rebuilds on a keystroke) | the provider shape and the rebuild contract |
| `docs/engineering/01-architecture.md` | §4.4 (persist before republish: `.distinct()` **in the repository**, `override_hash_and_equals_in_result_sets`, drift#3295, drift#3338, and why `combineLatest` is a defect) | the de-duplication mechanism and its two open upstream issues |
| `docs/engineering/CONVENTIONS.md` | **R28** (`QuickEntryDeck` is `({List<DeckEntry> penned, List<DeckEntry> recents})`; `recentEwesProvider` and `inPensProvider` are banned) · §3.2 (the provider's file) · §1.1 layer rules 3, 5, 8 · §2.13 (repository ownership) · **R19** · §4.6 (SQL naming) · §5.2 (*the deck*) | **BINDING** on the type, the provider and the file |
| `docs/engineering/03-data-model-and-schema.md` | `PenOccupancies` (`ewe` nullable, `entered_at`, `exited_at`) · `EweTouches` (`ewe` is the primary key; `@DataClassName('EweTouch')`) · `Pens` (`label`) · §5.2 `Ewes.status` | the four tables and the two shapes that make `LIMIT 6` correct |
| `docs/research/00-tech-decisions.md` | #12 (one watched statement per screen, no `combineLatest`) · #60 (`customSelect` + explicit `readsFrom:`) · #67 ("in the pens" is the same projection the Pen Board watches) · #68 (`ewe_touches`) | the four decisions this statement applies |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-riverpod-providers` | `.select`, rebuild scope and the one-statement-per-screen rule |
| `shed-drift-schema` | `customSelect` with an explicit `readsFrom:` is its idiom |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/quick_entry_test.dart`
- **Test** — `'the deck is one statement and a recents change does not rebuild the penned strip'`
- **Why it is red today** — nothing produces the deck; the obvious implementation is two streams combined in Dart.

```bash
fvm flutter test test/features/quick_entry_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so both halves are mechanical:

1. **One statement.** Install a counting `QueryInterceptor` on the test connection; subscribe to
   `quickEntryDeckProvider`; assert exactly **one** distinct SQL string was prepared for the deck, and
   that it contains `UNION ALL`.
2. **One strip rebuilds.** Give each strip a build counter (a `ValueNotifier<int>` incremented in
   `build`, or a `RenderObject`-free counting wrapper the test supplies). Snapshot both counters, write
   **one** `ewe_touches` row in a transaction, `await tester.pump()`, and assert the recents counter
   advanced by exactly one and the penned counter **did not move at all**. Then do the mirror case:
   write a `pen_occupancies` row and assert the opposite.

Half 2 is the half that fails for a subtle reason, and §5.3 explains exactly why a naive
implementation fails it even when the SQL is right. Write the reason into the `reason:` string.

**Green.** The minimum code that passes, and nothing beyond it — one `customSelect`, an explicit `readsFrom:`, and two `.select` reads.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema and no domain.** The four tables were frozen in N07. This task is data (step 3, read side),
wiring (step 4) and tests (step 7) — plus one `CONVENTIONS` row, because two files are about to use a
type the naming authority does not yet carry. Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `build.yaml` | **Edit, if not already set.** `override_hash_and_equals_in_result_sets: true` under the `drift_dev` options. `01 §4.4` requires it, and without it every generated result-set class uses identity equality and `.distinct()` silently never de-duplicates. **This regenerates `database.g.dart` — `make gen` and commit the result in this same commit**, or the `codegen` job fails on a fresh clone |
| 2 | `lib/data/flock_repository.dart` | **Edit.** Add `DeckEntry`, `typedef QuickEntryDeck` and `Stream<QuickEntryDeck> watchQuickEntryDeck()` — the `customSelect`, the explicit `readsFrom:`, the mapping and the `.distinct()`. It goes on `FlockRepository` (created in T02) rather than `PenRepository` for three reasons: both buckets are *ewes*, `ewe_touches` exists only for this read and is already this repository's table (`CONVENTIONS` §2.13), and the Foster screen reuses the same query (`07 §1.1` row 6) and is not a pen screen. **Writes to `pens` and `pen_occupancies` remain `PenRepository`'s** — this is a read across a boundary, which is normal, not a second writer |
| 3 | `lib/features/quick_entry/quick_entry_controller.dart` | **Edit.** Add `quickEntryDeckProvider` beside the controller T02 created. `CONVENTIONS` §3.2 puts it in this file; it calls the repository and touches no drift symbol |
| 4 | `docs/engineering/CONVENTIONS.md` §2.14 | **Edit.** Add the `DeckEntry` and `QuickEntryDeck` rows. R28 names `QuickEntryDeck`'s shape and `DeckEntry` inside it, but §2 carries neither, and §1.1's own preamble says every path any document names is either in the tree or banned by a numbered ruling. Same principle, same commit (`00-README` §10 rule 3) |
| 5 | `test/support/seeds.dart` | **Edit.** Add `seedPen`, `seedPenOccupancy` and `seedTouch` so a test can populate both buckets. N19 and N26 reuse them |
| 6 | `test/features/quick_entry_test.dart` | **Edit.** The anchor plus the feature-side cases in §5.4 |
| 7 | `test/data/flock_repository_test.dart` | **Edit.** The statement's own cases, against `NativeDatabase.memory()` |

`lib/l10n/app_en.arb` is **not** touched: the strips' copy is **T06**'s, authored with the widgets that
render it.

### 5.2 The signatures

`CONVENTIONS` R28 fixes the type exactly. `QuickEntryDeck` is a **record**, not a class — that is what
makes `.select((d) => d.penned)` legal and readable:

```dart
// lib/data/flock_repository.dart

/// One row of either bucket. Value equality is REQUIRED: `.distinct()` in the
/// repository compares deck to deck, and a class with identity `==` makes the
/// de-duplication a no-op (drift#3295, 01 §4.4).
@immutable
final class DeckEntry {
  const DeckEntry({
    required this.eweId,
    required this.tag,
    required this.digits,
    required this.sortAt,
    this.penLabel,
  });

  final EweId eweId;          // R33: an extension-type id, never a bare int
  final String tag;           // exactly as typed; never normalised
  final String digits;        // the tag_digits projection; ranks, never shown
  final Instant sortAt;       // penned: entered_at.  recents: touched_at.
  final String? penLabel;     // penned only; null in the recents bucket

  @override
  bool operator ==(Object other) => …;   // all five fields
  @override
  int get hashCode => …;
}

/// R28. Two buckets, one stream, one statement.
typedef QuickEntryDeck = ({List<DeckEntry> penned, List<DeckEntry> recents});
```

The read verb. `07 §5.2` prints the SQL; type it as printed, including the comment explaining the CTEs:

```dart
  /// One statement, two buckets, one stream (decision #12, #67, #68).
  /// SQLite only accepts ORDER BY/LIMIT on the FINAL arm of a compound SELECT,
  /// so each bucket is a CTE.
  Stream<QuickEntryDeck> watchQuickEntryDeck() => _db
      .customSelect(
        '''
WITH penned AS (
  SELECT 'penned' AS bucket, e.id AS ewe_id, e.tag AS tag, e.tag_digits AS tag_digits,
         o.entered_at AS sort_at, p.label AS pen_label
    FROM pen_occupancies o
    JOIN ewes e ON e.id = o.ewe
    JOIN pens p ON p.id = o.pen
   WHERE o.exited_at IS NULL AND o.ewe IS NOT NULL
   ORDER BY o.entered_at ASC           -- longest-penned first: the one you are standing next to
   LIMIT 6
), recents AS (
  SELECT 'recent', e.id, e.tag, e.tag_digits, t.touched_at, NULL
    FROM ewe_touches t
    JOIN ewes e ON e.id = t.ewe
   WHERE e.status = 'active'
   ORDER BY t.touched_at DESC
   LIMIT 6
)
SELECT * FROM penned UNION ALL SELECT * FROM recents;
''',
        readsFrom: {_db.penOccupancies, _db.eweTouches, _db.ewes, _db.pens},
      )
      .watch()
      .map(_toDeck)
      .distinct();      // see §5.3 — `_toDeck` is what makes this meaningful
```

The provider, on the feature side, touching no drift symbol:

```dart
// lib/features/quick_entry/quick_entry_controller.dart
/// R28: ONE provider for both strips. `recentEwesProvider` and `inPensProvider`
/// are banned spellings. keepAlive — this is the hub screen (02 §4.2).
final quickEntryDeckProvider = StreamProvider<QuickEntryDeck>((ref) async* {
  final repo = await ref.watch(flockRepositoryProvider.future);
  yield* repo.watchQuickEntryDeck();
});
```

And the two reads, which is the whole point of one provider:

```dart
ref.watch(quickEntryDeckProvider.select((d) => d.whenData((v) => v.penned)));
ref.watch(quickEntryDeckProvider.select((d) => d.whenData((v) => v.recents)));
```

### 5.3 The details that are easy to get wrong

- **`.select` over a `List` deduplicates nothing, and the Definition of Done depends on it doing so.**
  This is the single sharpest trap in the task. `02 §4.4` states it plainly: *"a stored `List` field
  still has identity `==`, so `.select((s) => s.matches)` deduplicates **nothing** — every new state
  instance carries a new list."* So the naive implementation fails the anchor's second half even with
  perfect SQL: penning a ewe writes `pen_occupancies`, drift re-runs the whole statement, `_toDeck`
  allocates **two** fresh lists, `.distinct()` sees a deck that genuinely changed and emits, and the
  recents strip's `.select` compares two equal-but-not-identical `List`s with identity `==` and
  rebuilds.

  The fix is not a deep-equality helper in the selector — `02 §4.4` bans that explicitly. It is in
  `_toDeck`, which is stateful by design and reuses the previous bucket's **list instance** when that
  bucket's contents are unchanged:

  ```dart
    QuickEntryDeck? _last;

    QuickEntryDeck _toDeck(List<QueryRow> rows) {
      final penned = [for (final r in rows) if (r.read<String>('bucket') == 'penned') _entry(r)];
      final recents = [for (final r in rows) if (r.read<String>('bucket') == 'recent') _entry(r)];
      final prev = _last;
      final deck = (
        // Identity is what `.select` compares, so hand back the SAME list when
        // the bucket did not change. The list comparison runs ONCE per emission
        // here, not once per rebuild in a widget (02 §4.4).
        penned: prev != null && const ListEquality<DeckEntry>().equals(prev.penned, penned)
            ? prev.penned
            : penned,
        recents: prev != null && const ListEquality<DeckEntry>().equals(prev.recents, recents)
            ? prev.recents
            : recents,
      );
      return _last = deck;
    }
  ```

  This is the same trade `01 §4.4` already makes for the pen board — *"de-duplicate in the repository,
  never in the widget"* — pushed one level finer so it works per bucket. It also makes `.distinct()`
  on the outer stream meaningful, because an unchanged deck is now identical field-for-field.
- **`DeckEntry` needs real value equality or every mechanism above is a no-op.** Hand-write `==` and
  `hashCode` over all five fields, and set `override_hash_and_equals_in_result_sets: true` in
  `build.yaml` so the generated result-set classes do the same (`01 §4.4`, drift#3295 open). A
  `DeckEntry` that compares by identity turns both `ListEquality` calls and the `.distinct()` into
  expensive ways of always returning false.
- **`combineLatest` over drift streams is a build-breaking defect** (decision #12, `01 §4.4`). Two
  `watch()` streams updated inside one transaction can emit at different times, and the maintainer's
  position on drift#3338 (still open) is that this *"generally is working as intended"*. A deck built
  from `combineLatest(penned, recents)` renders a penned ewe who has already been turned out. Fan-in
  happens **in SQL**.
- **Each bucket must be a CTE, and the reason is a real SQLite restriction.** SQLite only accepts
  `ORDER BY` and `LIMIT` on the **final** arm of a compound `SELECT`. Writing
  `SELECT … ORDER BY … LIMIT 6 UNION ALL SELECT … ORDER BY … LIMIT 6` is either a syntax error or, worse,
  parses as one ordering applied to the whole union — six rows total instead of six per bucket, and the
  penned strip silently empties on a busy night.
- **`o.ewe IS NOT NULL` is load-bearing even though the `JOIN` would drop the row anyway.** `03`'s
  `PenOccupancies.ewe` is nullable because a pen can hold lambs with no ewe. Decision #67 says the strip
  is ewes only. `07 §5.2`: without the predicate *"the `JOIN ewes` would silently drop the row anyway,
  which is the same result reached by accident rather than on purpose."*
- **`ewe_touches` has `ewe` as its PRIMARY KEY**, so there is exactly one row per ewe and
  `ORDER BY touched_at DESC LIMIT 6` really is the last six *distinct* animals. **No `GROUP BY`, no
  `DISTINCT`** — adding either is a sign someone doubted the schema instead of reading it.
- **The two buckets filter `status` differently, and that asymmetry is worth a review comment.**
  `07 §5.2`'s `recents` CTE carries `WHERE e.status = 'active'`; the `penned` CTE does not. The
  consequence: a culled ewe with an open pen occupancy appears on the deck but **cannot** be found by
  the keypad, because `tagIndexProvider` is active-only (T02). Both readings are defensible — an open
  occupancy for a culled ewe is a data state the shepherd should see, or it is an inconsistency the
  deck should not surface. **Do not silently pick one.** Implement `07`'s SQL as printed, and raise the
  question in the PR body so it is ruled rather than absorbed.
- **`readsFrom:` is what makes the stream re-emit; omit a table and it silently stops updating.** All
  four: `penOccupancies`, `eweTouches`, `ewes`, `pens`. `02 §4.2` adds the corollary — **never**
  `ref.invalidate` a drift-backed read provider. *"A manual invalidate means either the write did not
  go through drift or the query is missing a table in `readsFrom:`."* The mirror test in §5.4 (renaming
  a pen re-emits) is what proves `pens` is in the set.
- **Aggregates and `GROUP BY` go through `customSelect`, never a Dart-defined drift `View`** (decision
  #60). drift documents exactly one shape for Dart views and says nothing about `groupBy` or `where`
  inside `as()`.
- **`lib/features/` may not import `package:drift`** (layer rule 5). `CONVENTIONS` §3.2 puts
  `quickEntryDeckProvider` in `quick_entry_controller.dart`, which is a feature file — so the
  `customSelect` **cannot** live there. Read §3.2 and layer rule 5 together, not separately: the
  provider is on the feature side and the statement is on the repository. And `customStatement(` is
  banned outside `lib/core/db/` entirely (`layer.single_writer`) — `customSelect` is the read API and is
  a different symbol; do not reach for the other one.
- **Loading is never a spinner** (`02 §4.5`, decision #71). The `AsyncLoading` arm is
  `const SizedBox.shrink()` inside a `SizedBox` of the strip's reserved height, so nothing shifts when
  data lands. `CircularProgressIndicator` is banned outright under `lib/features/**` by
  `tool/check_policy.dart`'s `ui.spinner` row. Reading an `AsyncValue` is an exhaustive `switch` and
  nothing else — `valueOrNull` is Riverpod 3 and does not exist here.
- **This provider is `keepAlive`, and it is one provider.** `recentEwesProvider` and `inPensProvider`
  are banned spellings (R28). Two providers would satisfy the rebuild rule and break the one-statement
  rule; one provider with two `.select` reads satisfies both.

### 5.4 The full test set

`test/data/flock_repository_test.dart` against `NativeDatabase.memory()` (decision #111 — never a
mock); `test/features/quick_entry_test.dart` for the rebuild contract.

| Case | File | What it asserts |
|---|---|---|
| `'the deck is one statement and a recents change does not rebuild the penned strip'` | features | **The anchor.** One prepared SQL string containing `UNION ALL`; a `ewe_touches` write advances the recents counter by one and leaves the penned counter untouched |
| `'a penned change does not rebuild the recents strip'` | features | The mirror case. Both directions or neither is proved |
| `'a write that changes nothing emits nothing'` | features | Touch the same ewe with the same `touched_at`; neither counter moves. This is `.distinct()` plus `_toDeck`'s list reuse, together |
| `'combineLatest appears nowhere under lib/'` | features | Source text. Decision #12, as a grep |
| `'penned is ascending by entered_at and capped at six'` | data | Seed seven open occupancies; assert six rows, oldest first |
| `'recents is descending by touched_at and capped at six'` | data | Seed seven touches; assert six rows, newest first |
| `'a pen occupancy with a null ewe is not on the deck'` | data | A lambs-only pen. The `IS NOT NULL` predicate, named |
| `'an exited occupancy is not on the deck'` | data | Set `exited_at`; the row leaves in the same emission |
| `'one ewe touched twice appears once'` | data | `ewe_touches`'s primary key, asserted rather than assumed |
| `'a ewe can be in both buckets at once'` | data | Penned **and** recently touched. Two `DeckEntry` rows, one per bucket, and the strips render both — this is normal, not a duplicate |
| `'renaming a pen re-emits the deck'` | data | Proves `pens` is in `readsFrom:`. The one table a developer forgets, because the strip only shows its label |
| `'culling a penned ewe: 07 §5.2's SQL keeps her on the penned strip'` | data | Pins today's behaviour so the open question in §5.3 is visible in the suite rather than in someone's head |
| `'DeckEntry equality is by value over all five fields'` | data | Two instances built from the same row are `==` and share a `hashCode`. Without this, nothing above works |
| `'the deck stream yields no spinner-shaped state and the strips reserve their box while loading'` | features | `AsyncLoading` renders a fixed-height `SizedBox`; zero `CircularProgressIndicator` in the tree |
| `'hours-penned ordering is by elapsed physical time across the ambiguous DST hour'` · **`@Tags(['uk-zone'])`** | data | `TZ=Europe/London`. Two ewes penned at **01:30 BST** and **01:30 GMT** — identical wall-clock times an hour apart in real time. `entered_at` is epoch millis, so `ORDER BY entered_at ASC` must put the BST ewe first. An implementation that ever sorts on a formatted local time inverts the strip for one hour a year, and the one it inverts is *"the one you are standing next to"* |

## 6. Constraints that bind this task

- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **The deck** is the collective noun for Quick Entry's two selection strips (`CONVENTIONS` §5.2) —
  never *picker*, never *chooser*. **Penned** / **pen occupancy**, never *housed* or *in the pen* as a
  state name. **Record** is the stored fact; **entry** is the act.
- **One statement per screen** (decision #12, `07 §1.2`). The deck is Quick Entry's one *content*
  statement; `tagIndexProvider` is permitted alongside it only because it is an app-level singleton,
  and `07 §1.2` names it as one.
- **`lib/data/` may never import `lib/domain/validation/`** (R53, `layer.data_no_validation`) and may
  never import `package:flutter/material.dart` (layer rule 4).

## 7. Definition of Done

- [ ] `'the deck is one statement and a recents change does not rebuild the penned strip'` passes, and was seen to fail first for the stated reason
- [ ] one statement, not two
- [ ] `combineLatest` appears nowhere
- [ ] a change in one bucket rebuilds one strip, proved by a rebuild count
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `quickEntryDeckProvider` is `StreamProvider<QuickEntryDeck>`, keepAlive, declared in `lib/features/quick_entry/quick_entry_controller.dart`
- [ ] `recentEwesProvider` and `inPensProvider` appear nowhere (R28)
- [ ] `readsFrom:` names all four tables, and the "renaming a pen re-emits" case proves the fourth
- [ ] `DeckEntry` has hand-written value equality; `override_hash_and_equals_in_result_sets: true` is set and the regenerated files are **in this commit**
- [ ] `.distinct()` is in the repository, never in a widget, and `_toDeck` reuses an unchanged bucket's list instance
- [ ] no file under `lib/features/` imports `package:drift`; no `customStatement(` outside `lib/core/db/`
- [ ] `ref.invalidate(quickEntryDeckProvider)` appears nowhere
- [ ] `CONVENTIONS` §2.14 carries `DeckEntry` and `QuickEntryDeck`, added in this same commit
- [ ] the culled-but-penned asymmetry is raised in the PR body rather than silently resolved
- [ ] the `uk-zone` ordering case exists and fails when the `TZ=Europe/London` leg is removed

## 8. Verification

```bash
fvm flutter test test/features/quick_entry_test.dart
fvm flutter test test/data/flock_repository_test.dart
make gen                     # build.yaml changed — regenerate and commit what moves
make check
make test
```

```bash
TZ=Europe/London fvm flutter test --tags uk-zone
```

```bash
grep -rn "combineLatest" lib/                                   # expect zero
grep -rn "recentEwesProvider\|inPensProvider" lib/ test/        # expect zero
grep -rn "package:drift" lib/features/                          # expect zero
grep -rn "customStatement(" lib/ --include=*.dart | grep -v "lib/core/db/"   # expect zero
grep -n "readsFrom" lib/data/flock_repository.dart              # expect four tables
grep -n "\.distinct()" lib/data/flock_repository.dart           # expect it here, not in a widget
git status --porcelain lib/core/db/database.g.dart              # must be staged if build.yaml moved
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(quick_entry): quickEntryDeckProvider, one statement and two buckets`

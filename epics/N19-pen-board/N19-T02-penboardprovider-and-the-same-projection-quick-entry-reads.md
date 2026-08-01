# N19-T02 — `penBoardProvider` and the same projection Quick Entry reads

| | |
|---|---|
| **Epic** | [N19 — Pen Board](epic.md) · `00-README` §9 step 6 (5 of 5) |
| **Task** | 2 of 7 |
| **Depends on** | N19-T01 |
| **Commit** | one commit · `feat(pen_board): one occupancy projection, read by two screens` |

## 1. Why this task exists

The pen board reads the **same projection** as Quick Entry's *in the pens* strip. Two
queries would be two answers to *who is penned*, and the whiteboard being wrong is exactly the failure
the product exists to fix.

It is also the task that fixes the shape of `PenTile` and `PenTileStatus`. 10 §3.5 names both, lists
the ten facts the board's semantics sentence and its tap handler need, and says out loud that no
sibling document defines their fields — so every later task in this epic renders whatever is decided
here.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `shed-book-spec.md` | §7.4 (*"grid of individual pens with occupant, entry time, and hours since penned"*), §7.1 (the pens strip on the entry screen) | the facts one projection has to carry for both readers |
| `docs/engineering/07-screens.md` | §9.1 (`penBoardQuery` in full, its `readsFrom:` set, and why the `LEFT JOIN` cannot duplicate), §5.1 (`quickEntryDeckProvider` and decision #67 — one projection, two orderings), §1.2 (the one-query rule, stated exactly) | the statement and the shared-projection claim |
| `docs/engineering/03-data-model-and-schema.md` | §8 (`penBoard` and `inThePens` in `queries.drift`), §5.9 (`o.ewe` is nullable — an orphan pen), §5.7 (`lambs.status` is one of four values) | the base statement and the two nullable edges |
| `docs/engineering/01-architecture.md` | §4.4 (**one statement per screen**, `.distinct()` in the repository never in the widget, `customSelect` with an explicit `readsFrom:`, and why `combineLatest` over drift streams is a build-breaking defect), §7.2 (bucket A — values that change with no write) | the shape of `watchBoard()` and what may not be in the row |
| `docs/engineering/02-state-di-navigation.md` | §5.1 (`penBoardProvider`'s published body), §4.2 (keepAlive for hub reads), §4.4 (`.select` and the stored-field rule), §4.5 (the only permitted `AsyncValue` form) | the provider, its scope and how the screen reads it |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.5 (**`PenTile`, `PenTileStatus`, the ten facts, and the sentence they feed**) | the projection's fields, and the one document that names them |
| `docs/engineering/CONVENTIONS.md` | §1 (**layer rule 5** — `lib/features/` may never import `lib/core/db/` or `package:drift/*`; **rule 6** — no sibling-feature import), §3.2 (`penBoardProvider` is a keepAlive `StreamProvider<List<PenTile>>` in `pen_board_controller.dart`), §4.1–§4.2 (file and type names), §4.6 (named queries), R28 (the deck's banned spellings) | **BINDING** on where the statement may live and what the provider is called |
| `docs/engineering/12-testing.md` | §3.3 (stream tests use `expectLater(stream, emitsInOrder([...]))`), §5 (`pumpApp`), §1.2 (the widget tier) | how a two-screen agreement is asserted |
| `docs/design/indelible.md` | §8 screen 7 (the board is sorted by hours descending by default, with a `SORT BY PEN NUMBER` word button) | what order the rows arrive in |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-riverpod-providers` | one statement, shared, and the rebuild scope |
| `shed-drift-schema` | the projection and its explicit `readsFrom:` |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/pen_board_test.dart`
- **Test** — `'the pen board and the Quick Entry strip render the same occupancy set'`
- **Why it is red today** — nothing projects occupancy for a board.

```bash
fvm flutter test test/features/pen_board_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it cannot pass by coincidence. Seed **four** things into one in-memory
database: two occupied pens with ewes, one empty pen, and one occupancy holding lambs with **no ewe**
(the orphan pen `enterPen` already allows). Pump `PenBoardScreen`, collect the tags its rows expose;
pump `QuickEntryScreen`, collect the tags its *in the pens* strip exposes; assert the two **sets** are
equal. The orphan pen and the empty pen are what make it a real test — a naive length comparison
fails on them, and the board is required to show both while the strip is required to show neither
(decision #67, ewes only).

**Green.** The minimum code that passes, and nothing beyond it — one statement, read by both screens through `.select`.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 3 (one read method on the existing repository), step 4 (the provider) and step 7 (tests).** No
schema, no domain, no ARB string, and no screen yet — T03 builds the screen; this task builds the
thing it will read. Say the skipped layers in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/pen_repository.dart` | **Edit.** `watchBoard()` — one `customSelect` (07 §9.1's statement), one `.map` to `PenBoardRow`, one `.distinct` with a real list comparator. The SQL lives here because layer rule 5 forbids `lib/features/` from importing `package:drift` at all |
| 2 | `lib/features/pens/pen_board_controller.dart` | **New.** `enum PenTileStatus`, `final class PenTile`, and `penBoardProvider` — `StreamProvider<List<PenTile>>`, keepAlive, `async*` over `repo.watchBoard()`, exactly as 02 §5.1 prints it |
| 3 | `test/support/seeds.dart` | **Edit.** `seedLambInPen` for the orphan-pen and lamb-count cases; `seedPen` and `seedOpenOccupancy` already landed in T01 |
| 4 | `test/features/pen_board_test.dart` | **New.** The anchor plus §5.4's projection cases |

### 5.2 The signatures

Two types and one provider. `PenTile` carries 10 §3.5's ten facts; `hours` and `status` are the two
that are **resolved per frame** rather than read from SQL, because both depend on `now` and on the
user's threshold (§5.3, item 4).

```dart
// lib/features/pens/pen_board_controller.dart
//
// 10 §3.5 declares both of these and says no sibling defines their fields. The
// ten facts are its list; the shape is this file's, which is what that section
// pre-authorises ("if a sibling fixes a different shape, that shape wins").

enum PenTileStatus { settling, ready, attention, loss, empty }

@immutable
final class PenTile {
  const PenTile({
    required this.penId,
    required this.penLabel,
    required this.thresholdHours,
    this.tag,
    this.animalClass = AnimalClass.ewe,
    this.enteredAt,
    this.timeSource = TimeSource.auto,
    this.lambCount = 0,
    this.hasLoss = false,
    this.clearDate,
    this.hours = 0,
    this.status = PenTileStatus.empty,
  });

  final PenId penId;            // the tap target's argument (10 §3.5)
  final String penLabel;
  final int thresholdHours;     // the USER's number, never a constant in this file
  final String? tag;            // null ⇒ empty pen or an orphan pen
  final AnimalClass animalClass;
  final Instant? enteredAt;
  final TimeSource timeSource;  // 'edited' is what T06 marks on the board
  final int lambCount;          // tally strokes, not a digit (indelible §8 screen 7)
  final bool hasLoss;
  final LocalDate? clearDate;   // the EARLIEST open withdrawal clear date, or null
  final int hours;              // resolved per tick — see forTick
  final PenTileStatus status;   // resolved per tick — see forTick

  /// The two derived facts, for the instant the ticker just yielded. T04 writes
  /// the body; nothing stores its result.
  PenTile forTick(Instant now, {required int thresholdHours, required LocalDate today});

  /// Hand-written, because `freezed` is banned (decision #16 — drift is the one
  /// generator). Only `forTick` uses it, and only for `hours` and `status`.
  PenTile copyWith({int? hours, PenTileStatus? status});

  @override
  bool operator ==(Object other) => /* every field; see §5.3 item 3 */;
  @override
  int get hashCode => /* Object.hash over the same fields */;
}

final penBoardProvider = StreamProvider<List<PenTile>>((ref) async* {
  final repo = await ref.watch(penRepositoryProvider.future);
  yield* repo.watchBoard();
});
```

And the statement, in the repository, with the `readsFrom:` set 07 §9.1 fixes:

```dart
Stream<List<PenTile>> watchBoard() => _db
    .customSelect(
      _penBoardSql,                      // 07 §9.1, minus the :today bind — see §5.3 item 4
      readsFrom: {
        _db.pens, _db.penOccupancies, _db.penOccupancyLambs,
        _db.ewes, _db.lambs, _db.treatments, _db.treatmentWithdrawals,
      },
    )
    .watch()
    .map(_toTiles)
    .distinct((a, b) => const ListEquality<PenTile>().equals(a, b));
```

### 5.3 The details that are easy to get wrong

1. **The statement cannot live in the feature folder, however much 00-README §8 step 14 sounds like it
   can.** Layer rule 5 bans `package:drift/*` and `lib/core/db/` from `lib/features/` outright, and
   `customSelect` is a drift API. The provider lives in the feature file (CONVENTIONS §3.2) and the
   *statement* lives in the repository — which is exactly the split 02 §5.1 prints: the provider is
   three lines and awaits `penRepositoryProvider`.
2. **`readsFrom:` is not optional and not inferred.** For a `customSelect` drift cannot parse the
   dependency set, so a missing table means the stream never re-runs when that table is written and
   the board silently stops updating — the failure looks like "the app is stale", never like a query
   bug. All seven tables, every time. 07 §9.1 lists them and the list is the test's business too.
3. **`.distinct` over a `List` does nothing unless `PenTile` has a real `==`.** `List` equality is
   identity, and `freezed` is banned (decision #16 — drift is the only generator), so `==` and
   `hashCode` are hand-written over every field. Without them drift re-emits on **any** write to any
   of the seven tables — penning one ewe re-runs the whole board, and 01 §4.4's consequence is
   literal: *"the pen grid visibly re-lays-out while the shepherd is reading it in a head torch."*
   Set `override_hash_and_equals_in_result_sets: true` in `build.yaml` for the row class; write the
   `PenTile` pair by hand.
4. **Do not bind `:today` into the statement.** 07 §9.1's `under_withdrawal` arm compares
   `w.clear_date >= :today`. A bound parameter does not change at midnight, and drift re-runs a
   statement only when a tracked **table is written** — so a withdrawal that cleared at 00:00 keeps
   its badge until the next unrelated write. Project the value instead
   (`MIN(w.clear_date) FILTER (WHERE t.voided_at IS NULL AND w.kind = 'days')` as `clear_date`) and
   let the tile compare it against the day the ticker just yielded. That is the same bucket-A rule
   (01 §7.2) that keeps *hours since penned* out of SQL, applied to the other value on this row that
   changes with no write. Record the departure from 07 §9.1 in the PR body.
5. **`has_loss` tests for the two dead statuses explicitly.** `lambs.status` is one of
   `('alive','dead','stillborn','sold')`, so `<> 'alive'` counts a **sold** lamb as a loss and
   `<> 'dead'` counts a stillborn as alive. 07 §9.1 writes `IN ('dead','stillborn')` and its comment
   says why; keep both.
6. **`lamb_count` comes from `pen_occupancy_lambs`, never from the ewe's lambings.** *"Every lamb this
   ewe ever bore"* is unscoped by season and would print last year's triplets on tonight's board
   (07 §9.1's comment).
7. **The `LEFT JOIN` cannot produce two rows for one pen — because of the index, not because of the
   query.** `idx_penocc_one_open` is what makes that true (07 §9.1). If you ever find yourself adding
   a `GROUP BY p.id` to be safe, the index is missing and the safety is the bug.
8. **The board and the strip are the same projection, not the same query text.** The deck is ewes only
   (`o.ewe IS NOT NULL`) and ordered by `entered_at` **ascending** — longest penned first, the ewe you
   are standing next to (decision #67); the board keeps empty pens, keeps orphan pens, and sorts by
   hours descending (Indelible §8 screen 7). What must agree is the **set of open occupancies with a
   ewe**, and that is what the anchor asserts.
9. **`recentEwesProvider` and `inPensProvider` are banned spellings** (R28) and so is any new provider
   that reads pen occupancy. If the board needs a second thing to watch, it must be a single-row
   lookup or one of the four app-level singletons 07 §1.2 lists — nothing else.
10. **`combineLatest` is a build-breaking defect** (01 §4.4, decision #12). A board built from
    `combineLatest(pens, ewes)` renders a pen whose ewe has already moved, and the drift maintainer's
    position on drift#3338 is that the torn emission is working as intended. Fan-in happens in SQL.
11. **`penBoardProvider` is keepAlive and must stay that way** (CONVENTIONS §3.2). The board is
    re-entered constantly through a night; disposing and re-querying on every pop is exactly the wrong
    trade at 3am (02 §4.2). What it may **not** do is watch anything `.autoDispose` — see T04.
12. **`AsyncValue` is read as an exhaustive `switch` and never through `.value`, `.hasValue` or
    `.when`** (02 §2.2, §4.5). `AsyncLoading` renders the fixed-height dark placeholder rows, never a
    spinner (decision #71).
13. **`queries.drift`'s `penBoard` block becomes dead the moment this lands.** Do **not** delete it in
    this epic: `lib/core/db/` is frozen after N07-T08 and this branch's reviewer is told to expect no
    file from that folder. Name it as dead on the first line of the PR body and let the owner route
    the removal. Check `inThePens` while you are there — N13-T03 may already have superseded it the
    same way.

### 5.4 The full test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/features/pen_board_test.dart` | `'the pen board and the Quick Entry strip render the same occupancy set'` | **The anchor.** Two screens, one database, sets compared, with an orphan pen and an empty pen seeded |
| | `'an empty pen appears on the board and not in the strip'` | The board keeps its holes — *"when you are carrying a ewe you need to see where the space is"* (Indelible §8 screen 7) |
| | `'a pen holding lambs with no ewe appears on the board and not in the strip'` | The nullable `o.ewe`. Decision #67 is *ewes only* for the deck, and the board is not |
| | `'a pen deactivated with is_active = 0 leaves the board entirely'` | Not a filtered state — a different set of pens (07 §9.4) |
| | `'lamb_count counts the lambs in this occupancy, not every lamb the ewe ever bore'` | Seed a ewe with lambs from a previous season in the same database |
| | `'a stillborn lamb sets hasLoss and a sold lamb does not'` | The `IN ('dead','stillborn')` predicate, both directions |
| | `'a voided treatment does not set clearDate'` | `t.voided_at IS NULL`. A voided treatment is still in the medicine book and is not a live withdrawal |
| | `'a treatment whose withdrawal kind is not_applicable does not set clearDate'` | Only `kind = 'days'` has a date to count down |
| | `'writing an unrelated ewes row does not re-emit an identical board'` | `.distinct` plus a real `==`. Assert with `expectLater(stream, emitsInOrder([...]))` and a rebuild count |
| | `'penning a ewe re-emits the board exactly once'` | The other direction — de-duplication that swallows a real change is worse than none |
| | `'the statement declares all seven tables in readsFrom'` | Source-text assertion over `pen_repository.dart`. Cheap, and it is the failure that presents as staleness rather than as an error |
| | `'combineLatest appears nowhere under lib/'` | Duplicates the gate row deliberately, in the tier a developer runs first |

## 6. Constraints that bind this task

- **One statement per screen** — the board's whole payload is one joined statement with an explicit
  `readsFrom:`; nothing on this screen is computed from two drift streams (07 §1.2, decision #12).
- **Nothing derived is stored** — `hours` and `status` are resolved per frame, and `clear_date` is
  projected as a value rather than as a boolean, for the same reason (01 §7.2).
- **Layer rules** — the statement in `lib/data/`, the provider in `lib/features/pens/`, and no
  sibling-feature import in either direction.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the pen board and the Quick Entry strip render the same occupancy set'` passes, and was seen to fail first for the stated reason
- [ ] one statement, two readers
- [ ] the two screens are asserted to agree
- [ ] explicit `readsFrom:`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `PenTile` carries 10 §3.5's ten facts and hand-written `==` and `hashCode`, and `.distinct` is proved to suppress an identical re-emission
- [ ] `PenTileStatus` has exactly five members, spelled `settling`, `ready`, `attention`, `loss`, `empty`
- [ ] no `:today`, no `date('now')` and no SQL-side time appears in the statement
- [ ] `lib/features/pens/` imports no drift API and no other feature folder, proved by `gate` rather than by inspection
- [ ] the dead `penBoard` block in `queries.drift` is named in the PR body and left untouched in this branch

## 8. Verification

```bash
# 1. Red first, for the stated reason.
fvm flutter test test/features/pen_board_test.dart

# 2. Green, plus T01's tier — the projection must not have changed a write.
fvm flutter test test/features/pen_board_test.dart test/data/pen_repository_test.dart

# 3. Both gates.
make check
make test
```

```bash
grep -n "readsFrom" lib/data/pen_repository.dart      # expect: all seven tables, one set
grep -rn "combineLatest\|date('now')\|:today" lib/    # expect: nothing
grep -rn "inPensProvider\|recentEwesProvider" lib/    # expect: nothing (R28)
grep -rn "package:drift" lib/features/                # expect: nothing (layer rule 5)
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(pen_board): one occupancy projection, read by two screens`

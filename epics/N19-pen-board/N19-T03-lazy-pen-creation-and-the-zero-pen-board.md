# N19-T03 — Lazy pen creation and the zero-pen board

| | |
|---|---|
| **Epic** | [N19 — Pen Board](epic.md) · `00-README` §9 step 6 (5 of 5) |
| **Task** | 3 of 7 |
| **Depends on** | N19-T02 |
| **Commit** | one commit · `feat(pen_board): lazy pen creation and the zero-pen board` |

## 1. Why this task exists

A shepherd who has never made a pen sees **one** 72 pt *Add a pen* tile, not an empty
grid and not a setup wizard. Pens are created lazily, when a ewe is put in one, because *never block an
entry to make the user go and set something up first* (spec §7.1) applies to pens too.

`seedFirstRun` writes **no pens** on purpose (decision #42, 03 §10) — so day one is not an edge case
to be handled, it is the state every install starts in, and the first pen is created by the tap that
fills it.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `shed-book-spec.md` | §7.1 (*"never block an entry to make the user go and set something up first"*), §7.4 (the board is a grid of individual pens) | the sentence lazy creation exists to satisfy |
| `docs/engineering/07-screens.md` | §9.4 (**the four states**, and the zero-pen state verbatim), §9.5 (*Add a pen* is one tap and creates the next-numbered pen immediately; rename lives in the sheet and in Settings), §1.1 (the empty copy for both empty states), §20 (back is a bottom-bar button, not only the chevron) | the screen's states and its copy |
| `docs/engineering/03-data-model-and-schema.md` | §10 (`seedFirstRun` — *"NO PENS. Decision #42"*), §5.9 (`Pens`: `label` 1–24 chars, `uniqueKeys [{label}]`, `CHECK (length(trim(label)) > 0)`, `sort_order`, `is_active`) | why there are no pens, and every constraint a created pen must satisfy |
| `docs/design/indelible.md` | §8 screen 7 (the board is twelve ruled rows and a header; the corner slab reads `MOVE`), §7.5 (the pen row), §7.13 (the word button), §4.4 (88 px pen row), §1.3 (no cards, no empty state with an illustration) | what the screen is, and what the zero state may not be |
| `docs/engineering/06-design-system.md` | §6.1 (`tapMin` 60, `tapPrimary` 72, `tapHero` 88), §12 (`ShedEmptyState` — *"occupies the same box the populated content will"*, one line of copy and one action, no illustration, no spinner, no tour) | the component the zero state is built from, and its size floor |
| `docs/engineering/02-state-di-navigation.md` | §8.1 (`RouteNames.penBoard` already exists; the twelve push helpers), §8.2 (the stack: Quick Entry pushes the board), §7 (`WriteController.guard()` and the per-screen write controller), §4.5 (`AsyncLoading` is a placeholder, never a spinner) | the route, the write controller and the loading state |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree), §2.13 (`PenRepository` owns `pens`), §3.4 (`penBoardControllerProvider`, `penWriteControllerProvider`), §4.1 (a write controller may live in the screen controller's file), §4.5 (widget keys), R32 (only two verbs return an id and throw) | **BINDING** on the names this task introduces |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.4 (the board carries a level-1 title and no level-2 headings), §8.4–§8.5 (every ARB message has a `description`; no domain noun is a literal) | the heading and the strings |
| `docs/engineering/12-testing.md` | §5 (`pumpApp`), §6.4 (reachability), §10.1 (counting taps on keyed finders) | how the zero state and the tap cost are asserted |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-states-and-feedback` | the zero state and its single large target |
| `shed-write-path` | lazy creation is a write, and it commits immediately |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/pen_board_test.dart`
- **Test** — `'a flock with no pens renders one 72 pt add tile and no empty grid'`
- **Why it is red today** — nothing renders a board, and the obvious implementation shows an empty grid.

```bash
fvm flutter test test/features/pen_board_test.dart   # expect: failing, for the reason above
```

Sharpen it into the three things the name claims. Against a database seeded by `seedFirstRun` and
nothing else: exactly **one** interactive element exists on the board, found by
`find.byKey(const Key('pen_board.add_pen'))`; its rendered `Size` is at least 72 in both axes
(`tester.getSize`); and `find.byType(GridView)` finds nothing, along with zero rows carrying a pen
label. Then tap it once and assert a `pens` row exists — one tap, no confirmation, no wizard step.

**Green.** The minimum code that passes, and nothing beyond it — the zero state, the lazy create verb, and the tile.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 3 (one write verb), step 4 (the controllers), step 6 (the screen and the route) and step 7.**
No schema: `pens` was frozen in N07-T05. Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/pen_repository.dart` | **Edit.** `addPen({String? label})` plus the private `_nextPenLabel()` that picks the number. One transaction, `WriteCommitted(insertedId:)` |
| 2 | `lib/features/pens/pen_board_controller.dart` | **Edit.** `PenBoardController` (screen state — the sort order, which Indelible's `SORT BY PEN NUMBER` button flips) and `PenWriteController extends WriteController` with `addPen()`. T06 adds the other three verbs to the same class |
| 3 | `lib/features/pens/pen_board_screen.dart` | **New.** `PenBoardScreen` — a `ConsumerWidget` reading `penBoardProvider` through an exhaustive `switch`, the level-1 heading, the ruled column, and `ShedEmptyState` for the zero-pen state |
| 4 | `lib/routing/routes.dart` | **Edit, one method.** `Routes.penBoard(context)` — 02 §8.1 prints it verbatim. `RouteNames.penBoard` already exists from N13-T01; do not add a second name |
| 5 | `lib/l10n/app_en.arb` | **Edit.** Every string this screen shows, each with a `description`: the title, both empty lines, the add action, the pen label pattern |
| 6 | `test/features/pen_board_test.dart` | **Edit.** The anchor plus §5.4's cases |

### 5.2 The signatures

```dart
// lib/data/pen_repository.dart
//
// `addPen` is a new name. CONVENTIONS §2.13 fixes only the verbs more than one
// document spells; 07 §9.5 names this one in prose ("creates the next-numbered
// pen immediately") and nothing else does. It is `addPen`, not `createPen`,
// because `createEwe` is reserved for the one create the free tier can refuse
// (it takes an EntryContext); a pen is never capped. `addLamb` and `addCare`
// are the shape it follows.
Future<WriteOutcome> addPen({String? label});
```

```dart
// lib/features/pens/pen_board_controller.dart
final class PenWriteController extends WriteController {
  /// Every mutation on this screen goes through guard() — the double-tap
  /// defence (02 §7). Two cold-thumb taps on "Add a pen" must not make two pens.
  Future<void> addPen() => guard(() async {
        final repo = await ref.read(penRepositoryProvider.future);
        return repo.addPen();
      });
}

final penWriteControllerProvider =
    NotifierProvider.autoDispose<PenWriteController, WriteState>(PenWriteController.new);
```

The widget keys this task fixes, all `lower_snake`, `<screen>.<element>[.<qualifier>]` (§4.5):

```
pen_board.add_pen
pen_board.pen.<penId>          // the row target; the qualifier is the ROW ID, see §5.3
pen_board.sort_by_number
```

### 5.3 The details that are easy to get wrong

1. **`pens.label` is unique across **every** pen, including deactivated ones.** 03 §5.9 declares
   `uniqueKeys => [{label}]` with no partial predicate — unlike the tag index, which *is* partial.
   So a pen `3` that was deactivated last season still owns the string `'3'`, and
   `_nextPenLabel()` must skip labels held by any row in `pens`, not by the active ones the board
   shows. Get this wrong and the first `addPen` after a deactivation returns `WriteFailed` with a
   UNIQUE violation that the UI has no honest message for.
2. **`MAX(label) + 1` is wrong twice over.** `label` is `TEXT`, so `'10' < '9'` and the tenth pen
   would be numbered 10 forever; and a user-renamed pen (`'Shed A'`) makes the cast meaningless.
   Read the labels, keep the ones that parse as a positive integer, and take the **smallest unused**
   one — which also reuses the gap left by a deactivated pen the moment its label is free, and gives
   the shepherd the number they expect when they are counting hurdles.
3. **`sort_order` is what the board sorts by when the shepherd asks for physical order** (Indelible
   §8 screen 7's `SORT BY PEN NUMBER`), so set it to the same integer as the label. Leaving it at its
   `0` default makes every pen equal and hands the ordering to `p.label`, which sorts `'10'` before
   `'9'` for the same reason as item 2.
4. **`addPen` returns `WriteOutcome`, not a `PenId`.** R32 closes the throwing list at `beginLambing`
   and `addLamb`. The new id arrives in `WriteCommitted.insertedId` as a raw `int` (01 §5.2) and the
   caller wraps it: `PenId(outcome.insertedId!)`.
5. **Lazy creation is two verbs, not one, and that is deliberate.** *Add a pen* is `addPen`; putting a
   ewe in it is `enterPen`. Each is its own transaction (03 §5.14: *every mutation is exactly one
   `db.transaction`*). If the app dies between them the shepherd has an empty pen — a real, visible,
   harmless row, not a half-written record. A compound `enterNewPen` would be one transaction and one
   more verb on a repository whose write surface 03 §5.14 keeps deliberately small.
6. **The zero state is not a wizard, not an illustration and not a dialog.** `ShedEmptyState` occupies
   the same box the populated board will (06 §12) and offers one action at the same control class the
   populated screen uses. Indelible §1.3 bans the illustration outright and §7.14 keeps the bottom
   sheet drag-free; nothing here opens a modal.
7. **07 §9.4's "72 pt tile" is a size floor, not a shape.** Indelible has no tiles — the board is
   ruled rows at 88 px (§4.4, §7.5, §8 screen 7) — and 72 is `tapPrimary`, which an 88 px row clears.
   Build the row; do not build a tile to satisfy a number that the row already exceeds. The design
   system outranks the engineering docs on what the screen looks like (`CLAUDE.md`'s authority order).
8. **Both empty states exist and they are different sentences.** Zero pens is *"No pens yet."* with
   the add action; pens that exist but hold nothing is *"No animals penned."* with every row rendering
   its own empty encoding and staying tappable (07 §1.1, §9.4). Rendering the first sentence when
   twelve empty pens exist hides the twelve places a ewe could go, which is the one thing the
   shepherd carrying a ewe needs.
9. **A deactivated pen is not a filtered state.** `WHERE p.is_active = 1` puts it outside the set
   entirely; the board has no filter and never renders a "nothing matches" state (07 §9.4).
10. **The route helper is added here and `RouteNames.penBoard` is not.** 02 §8.1's arithmetic is a
    test: thirteen names, twelve push helpers, and the count is asserted. Adding a fourteenth name
    reddens N13-T01's test.
11. **The screen heading is level 1 and there are no level-2 headings on this screen** (10 §3.4). The
    board is one list; heading stops inside it would add navigation to a screen whose whole purpose is
    a single glance. `Semantics(header: true)` is banned — it is `headingLevel:` (10 §3.4).
12. **`AsyncLoading` renders the ruled rows in placeholder ink, not a spinner** (decision #71, 07
    §9.4's *frame 1* row: *"the same grid geometry in placeholder tiles — no shift when data lands"*).
    A spinning ring under a head torch is a flashbang.
13. **No string is a literal in the widget.** Every one goes through `app_en.arb` with a `description`,
    and the animal noun comes from `terminologyProvider`, never typed (10 §8.5). There is no later
    sweep — N33 only verifies.

### 5.4 The full test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/features/pen_board_test.dart` | `'a flock with no pens renders one 72 pt add tile and no empty grid'` | **The anchor.** One target, its measured size, and no grid |
| | `'adding a pen from the zero state costs one tap and commits immediately'` | Tap the keyed finder once, then read `pens` — no confirmation step, no Save |
| | `'two taps on add a pen produce one pen'` | The double-tap test, **with no pump between the taps** (02 §7.1 rule 4) |
| | `'the first pen created is labelled 1 and the second 2'` | The lazy numbering, in order |
| | `'a deactivated pen keeps its label, and the next pen skips it'` | The global unique key on `label` — the failure item 1 describes |
| | `'the tenth pen is labelled 10 and sorts after 9'` | The text-versus-integer trap, on `sort_order` |
| | `'pens that exist but hold nothing render every row and the no-animals-penned line'` | The second empty state, which is not the first |
| | `'a deactivated pen does not render at all'` | `is_active = 0` leaves the set |
| | `'the board renders placeholder rows while the projection is loading and never a spinner'` | `AsyncLoading`, and `find.byType(CircularProgressIndicator)` finds nothing |
| | `'the screen exposes exactly one headingLevel 1 node and no headingLevel 2'` | 10 §3.4, asserted on the semantics tree |
| | `'every string on the screen resolves through app_en.arb'` | No literal in the widget; the terminology placeholder is fed by the provider |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Never block an entry to make the user set something up first** (spec §7.1, decision #42). There is
  no pen-setup screen anywhere in this app, and adding one is not a small convenience.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'a flock with no pens renders one 72 pt add tile and no empty grid'` passes, and was seen to fail first for the stated reason
- [ ] no setup step is ever required before penning a ewe
- [ ] the add tile is at least 72 pt
- [ ] the created pen is committed immediately
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `addPen` returns `WriteOutcome` with `insertedId` set, and throws nothing (R32)
- [ ] the next label is the smallest unused positive integer across **all** pens, active or not, and `sort_order` matches it
- [ ] `Routes.penBoard` exists, `RouteNames` still has thirteen entries and `Routes` twelve push helpers
- [ ] both empty states render their own copy, and neither is a dialog, a wizard or an illustration
- [ ] `find.byType(CircularProgressIndicator)` finds nothing on any state of this screen

## 8. Verification

```bash
# 1. Red first, for the stated reason.
fvm flutter test test/features/pen_board_test.dart

# 2. Green, plus the route arithmetic N13-T01 asserts.
fvm flutter test test/features/pen_board_test.dart test/features/routes_test.dart

# 3. Both gates.
make check
make test
```

```bash
grep -rn "showDialog(\|GridView\|CircularProgressIndicator" lib/features/pens/   # expect nothing
grep -n "penBoard" lib/routing/routes.dart                                      # one name, one helper
grep -rn "'Add a pen'\|\"Add a pen\"" lib/                                      # expect nothing — it is an ARB message
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(pen_board): lazy pen creation and the zero-pen board`

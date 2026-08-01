# N19-T06 — Turn out, move and mark-as-group in one tap, and the edited marker

| | |
|---|---|
| **Epic** | [N19 — Pen Board](epic.md) · `00-README` §9 step 6 (5 of 5) |
| **Task** | 6 of 7 |
| **Depends on** | N19-T05 |
| **Commit** | one commit · `feat(pen_board): turn out, move and group in one tap, with the edited marker` |

## 1. Why this task exists

Spec §7.4's three actions, each one tap — and the **edited-entry marker** on the tile,
because a pen entry time that was corrected must say so wherever it is read (§12.5).

07 §9.6 puts it more sharply than the spec does: *"the board is what people trust; the board must not
launder an edited time as a captured one."* The marker is required whether or not this version ships
a way to make an edit, because a restored backup can carry one.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `shed-book-spec.md` | §7.4 (move, turn out and mark as group — *"in one tap"*), §12.5 (timestamps are honest) | the three verbs, and the marker the fifth safety rule requires |
| `docs/engineering/07-screens.md` | §9.5 (**the action table and its tap costs**, the sheet's configuration, and why one-tap-from-the-board is rejected), §9.6 (**§12.5 on the tile**: a `~` prefix plus the word `edited`, never the marker alone), §15.1 (undo per verb: what `exitPen`'s undo does and the condition on it), §15.2–§15.3 (the window, and why the label is only "Undo" where the record genuinely disappears) | every verb, its cost and its undo |
| `docs/design/indelible.md` | §8 screen 7 (**the inline chooser: `TURN OUT` and `MOVE TO…`; the turned-out row re-prints in place and stays for the rest of the night; `MOVE TO…` lists the empty pens; both rows print the movement with its time**), §7.14 (the bottom sheet: no drag handle, no drag, an explicit `CLOSE`), §2.7 (the edited-timestamp row: `†edited — event 03:20 as entered`), §6.2 mark 1 (the dagger), §5.4 (two ticks 60 ms apart on a commit) | what the shepherd sees and touches |
| `CLAUDE.md` | **P2** (there is no SnackBar; the confirmation **is** the committed row; undo is a time-boxed strike whose window is **stated in seconds**) | what replaces the receipt 07 §15 assumes |
| `docs/engineering/02-state-di-navigation.md` | §7 (**`PenWriteController.turnOut`'s published body**, `guard()`, and the `ref.listen` that turns `WriteDone` into feedback), §7.1 (the four rules: `guard()` prevents concurrency not repetition; `exitPen` is idempotent; **no pump between the two taps**), §8.1 (`Routes.foster`) | the controller, the double-tap contract and the one legal way out of this feature folder |
| `docs/engineering/CONVENTIONS.md` | **R63** (`turnOut` is the controller verb; `exitPen` is the repository verb), §2.13 (the canonical signatures), §3.4 (`penWriteControllerProvider` is always `.autoDispose`), §4.5 (widget keys — `pen_board.turn_out.3`), §5.1 (*turn out* is two words; the stored key is `turn_out`) | **BINDING** on the verb names and the keys |
| `docs/engineering/03-data-model-and-schema.md` | §5.9 (`idx_penocc_one_open`, and `CHECK ((exited_at IS NULL) = (exit_reason IS NULL))`), §8 (turning out is one transaction and *"the row stays forever"*) | why a move is one transaction and an undo can be refused |
| `docs/engineering/05-domain-correctness.md` | §4.2 (`RecordedTime`, `provenanceLabel`'s three strings, `editedTo`) | the marker's source of truth |
| `docs/engineering/12-testing.md` | §10.1 (counting taps on keyed finders), §7.1 (the double-tap test per destructive action) | how the tap costs are asserted |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | three verbs, each committing immediately |
| `indelible-marks-and-strikes` | the edited marker and its placement on the tile |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/pen_board_test.dart`
- **Test** — `'turn out costs one tap and a corrected entry time renders the edited marker on the tile'`
- **Why it is red today** — the board renders but does nothing.

```bash
fvm flutter test test/features/pen_board_test.dart   # expect: failing, for the reason above
```

Sharpen both halves, and read the first one precisely. **One tap** means *one tap once the row is
open* — 07 §9.5's rule is *"one tap per verb once the tile is open, and no verb has a confirmation
step"*, which is **two** taps from the board, and the one-tap-from-the-board form is rejected on
purpose. So: tap the row (1), tap `find.byKey(const Key('pen_board.turn_out.3'))` (2), and assert
`pen_occupancies.exited_at` is set with `exit_reason == 'turned_out'` — with no third tap and no
dialog in between. **The marker:** seed a second occupancy directly with `time_source = 'edited'` and
a non-null `original_effective`, pump, and assert the row renders both the dagger **and** the word —
`find.textContaining('edited')` must hit, because 07 §9.6 forbids the marker alone.

**Green.** The minimum code that passes, and nothing beyond it — the three verbs and the marker, with the tap costs asserted.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 3 (two more repository verbs), step 5 (the write controller), step 6 (the sheet and the ARB)
and step 7.** No schema and no domain. Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/pen_repository.dart` | **Edit.** `movePen(occupancy, to:)` — one transaction that closes one occupancy with `PenExitReason.moved` and opens another carrying the same lambs — and `undoExitPen(occupancy)`, which clears both exit columns and refuses when a later occupancy exists |
| 2 | `lib/features/pens/pen_board_controller.dart` | **Edit.** `PenWriteController` gains `turnOut`, `moveTo` and `penAsGroup`; `PenBoardController` gains the just-turned-out set the board prints until the route pops (§5.3 item 5) |
| 3 | `lib/features/pens/widgets/pen_action_sheet.dart` | **New.** The inline chooser: `TURN OUT`, `MOVE TO…` (the empty pens as 64 px lines), the ewe card, a 60 pt `Foster` on each lamb row, and an explicit 72 pt Cancel |
| 4 | `lib/features/pens/pen_board_screen.dart` | **Edit.** Open the sheet from a row tap; `ref.listen(penWriteControllerProvider, …)` for the three outcomes; render the turned-out row and the edited marker |
| 5 | `lib/l10n/app_en.arb` | **Edit.** The three action labels, the turned-out line with its time placeholder, the undo label and its window in seconds, and the edited marker's word. Each with a `description` |
| 6 | `docs/engineering/07-screens.md` §9.5 | **Edit, in this commit.** The widget keys this task fixes are recorded where 07 owns screen keys |
| 7 | `test/features/pen_board_test.dart` | **Edit.** The anchor plus §5.4's cases |
| 8 | `test/data/pen_repository_test.dart` | **Edit.** `movePen` and `undoExitPen`, against real SQLite |

### 5.2 The signatures

```dart
// lib/data/pen_repository.dart

/// Closes one occupancy and opens another, in ONE transaction. Not two verbs
/// from the controller: `idx_penocc_one_open` makes "in neither pen" and "in
/// both pens" representable between two transactions, and a board that renders
/// either is the failure this epic exists to prevent.
Future<WriteOutcome> movePen(PenOccupancyId occupancy, {required PenId to});

/// 07 §15.1: clears `exited_at` AND `exit_reason` together — the paired CHECK
/// makes clearing one of them unstorable — and only when no later occupancy
/// exists for that pen or that ewe, because the partial unique index would
/// otherwise refuse the re-open. Returns WriteFailed when it cannot.
Future<WriteOutcome> undoExitPen(PenOccupancyId occupancy);
```

```dart
// lib/features/pens/pen_board_controller.dart
final class PenWriteController extends WriteController {
  // `turnOut` is the UI verb and lives HERE; the repository verb is `exitPen`,
  // because the occupancy row — not the pen — is what closes (R63).
  Future<void> turnOut(PenOccupancyId occupancy) => guard(() async {
        final repo = await ref.read(penRepositoryProvider.future);
        return repo.exitPen(occupancy, reason: PenExitReason.turnedOut);
      });

  Future<void> moveTo(PenOccupancyId occupancy, PenId target) => guard(() async {
        final repo = await ref.read(penRepositoryProvider.future);
        return repo.movePen(occupancy, to: target);
      });

  /// "Mark as a group": the ewe and her lambs enter as ONE occupancy with one
  /// `pen_occupancy_lambs` row per lamb — which is also why turning the group
  /// out afterwards is a single `exitPen`. The group IS the occupancy.
  Future<void> penAsGroup(PenId pen, {required EweId ewe, required List<LambId> lambs}) =>
      guard(() async {
        final repo = await ref.read(penRepositoryProvider.future);
        return repo.enterPen(pen, ewe: ewe, lambs: lambs);
      });
}
```

Widget keys — the qualifier is the **pen row id**, never the label (§5.3 item 8):

```
pen_board.turn_out.<penId>
pen_board.move.<penId>
pen_board.move_target.<penId>
pen_board.group.<penId>
pen_board.undo_turn_out.<penId>
pen_board.sheet.cancel
```

### 5.3 The details that are easy to get wrong

1. **"One tap" is one tap *in the sheet*, and two from the board — deliberately.** 07 §9.5 rejects a
   true one-tap-from-the-board turn-out in one sentence, and the sentence is the reason: *"a brushed
   tile would turn out a ewe with a chilled lamb still under the lamp."* What the rule buys instead is
   that **no verb has a confirmation step** — the second tap is the write, not an *"are you sure"*.
2. **A move is one transaction, and the new `entered_at` is the move instant.** The tempting
   implementation carries the original entry time across so the hours keep counting; that makes
   `entered_at` a lie about the row it is on — it would say the ewe entered pen 2 at 21:00 when she
   entered at 04:12 — and §12.5 exists to keep exactly that column honest. Both rows stay forever, so
   the total time penned is recoverable from the pair. If the field night says the board should show
   cumulative hours, that is a *presentation* change over two rows and never a rewritten `entered_at`.
3. **`MOVE TO…` lists only the **empty** pens** (Indelible §8 screen 7: *"shows the empty pens as
   64 px lines; one tap completes the move"*). That is what makes the UNIQUE violation on
   `idx_penocc_one_open` unreachable from the UI, which is why T01 was allowed to leave it mapping to
   the generic failure message. If you ever offer an occupied pen as a target, T01's §5.3 item 2
   becomes a live user-facing problem and the ruling it defers becomes due.
4. **Turning out a group is one `exitPen`, not one per animal.** The lambs are rows on
   `pen_occupancy_lambs`, hanging off the occupancy; closing the occupancy closes the group. The
   *entering* half is the one that writes one row per animal, and it is one transaction (T01).
5. **The turned-out row stays on the board, and the statement does not change.** `watchBoard()` joins
   `o.exited_at IS NULL`, so the moment `exitPen` returns, the pen projects as empty. Indelible §7.5
   requires the row to re-print in place as `TURNED OUT 04:12` in `--ink-low` and stay *"for the rest
   of the night"*, adding *"the pen shows as empty on the next open."* Both are satisfied by holding
   the just-turned-out occupancies in **screen state** on `PenBoardController` — never by widening the
   statement, and never by a second query. It is the one thing on this screen that is state rather
   than data, and 02 §6 allows exactly that: a screen controller holds screen state, never data.
6. **P2 governs the confirmation: there is no SnackBar.** The receipt is the re-printed row itself.
   Undo is a time-boxed affordance in that row's margin and **its window is stated in seconds** — a
   named constant, in the ARB copy, not *"until the SnackBar is dismissed"* (07 §15.2 predates P2).
   The row stays until the route pops; the *affordance* expires on the stated number of seconds. Two
   lifetimes, both said out loud.
7. **"Undo" is the honest word here and only here.** 07 §15.3: the label is used *"only where the
   record genuinely disappears"*. Undoing a turn-out clears both exit columns and the occupancy is
   open again as though it never closed — nothing remains visible. A move is not undone; it is
   corrected forward, and both rows stay.
8. **The key qualifier is the pen's row id, not its label.** 02 §7's published test writes
   `pen_board.turn_out.3` against a pen seeded as `PenId(3)`. A label is renameable from the sheet and
   from Settings ▸ Pens (07 §9.5), so keying on it silently moves a test contract the day someone
   renames pen 3 to "Shed A" (R59: a key is a test contract).
9. **The double-tap test has no `pump` between the taps** (02 §7.1 rule 4). With a pump the first
   write completes, `state` becomes `WriteDone`, and the second tap is a legitimate second write —
   the test fails and rule 1 says it is right to. The repository half is T01's idempotent `exitPen`;
   this task's half is the guarded controller.
10. **Do not import `lib/features/lambing/` for the Foster row.** Layer rule 6 forbids a
    sibling-feature import; the sheet calls `Routes.foster(context, lambId)`, and `lib/routing/` is
    the one file allowed to know every screen (02 §8.1).
11. **The sheet is `ShedBottomSheet` and it does not drag.** `showDragHandle: false`,
    `enableDrag: false`, `isDismissible: false`, and an explicit Cancel at `tapPrimary` (07 §9.5,
    06 §12, Indelible §7.14). Drag and swipe-to-dismiss are both on the banned-gesture list and both
    are what a bottom sheet does by default.
12. **The edited marker is the mark *and* the word.** 07 §9.6 is explicit — *"a `~` prefix plus the
    word `edited` (never the marker alone)"* — and Indelible §2.7 prints it as
    `†edited — event 03:20 as entered`, with the dagger as mark 1 of the six. The string comes from
    `RecordedTime.provenanceLabel`, an exhaustive switch that can never be empty (decision #53); it is
    never re-typed in the widget.
13. **This task ships no edit verb for a pen entry time, and that is not an oversight.** The quad on
    `pen_occupancies` is what would permit one (R37), and the standing rule runs the other way — *a
    table without the quad has no edit verb*. The marker exists so a row that arrives carrying
    `time_source = 'edited'` — from a restore, or from a later epic — can never be laundered as
    auto-captured. The test seeds that row directly.
14. **Nothing here is optimistic.** The row re-prints when the transaction returns, never when the tap
    lands (decision #103). Two haptic ticks 60 ms apart mark the commit (Indelible §5.4), and they
    fire on `WriteCommitted`, not on the press.

### 5.4 The full test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/features/pen_board_test.dart` | `'turn out costs one tap and a corrected entry time renders the edited marker on the tile'` | **The anchor**, both halves |
| | `'turn out is two taps from the board and has no confirmation step'` | The cost, counted on keyed finders, and the absence of a dialog |
| | `'two taps on Turn out produce one pen exit'` | 02 §7.1's published double-tap test, verbatim, **with no pump between the taps** |
| | `'the turned-out row stays on the board with its time and is gone on the next open'` | Screen state, not a widened statement — pop and re-push to prove the second half |
| | `'undo re-opens the occupancy, and is refused once another ewe is in that pen'` | 07 §15.1's condition, both directions |
| | `'the undo affordance expires after its stated number of seconds'` | P2 — the window is a number, not a widget lifetime |
| | `'moving a ewe closes one occupancy with reason moved and opens another with entered_at now'` | The §12.5 half of item 2, asserted on both rows |
| | `'the move sheet lists only empty pens'` | The reason the UNIQUE violation is unreachable |
| | `'marking a ewe and three lambs as a group writes one occupancy and three lamb rows'` | The DoD's *one row per animal, in one transaction* |
| | `'turning out a group closes one occupancy and no lamb rows are deleted'` | The group is the occupancy |
| | `'the edited marker renders the dagger and the word, never the dagger alone'` | 07 §9.6, the sentence people miss |
| | `'a row with time_source auto renders no marker'` | The other direction — a marker on every row is a marker that means nothing |
| | `'the sheet has no drag handle, cannot be dragged and cannot be dismissed by tapping outside'` | Three defaults that all have to be turned off |
| | `'the Foster action navigates through Routes and lib/features/pens imports no sibling feature'` | Layer rule 6, in the tier that catches it before `gate` does |
| `test/data/pen_repository_test.dart` | `'movePen is one transaction: a failure to open the target leaves the source occupancy open'` | Atomicity, forced by targeting an occupied pen directly at the repository |
| | `'undoExitPen clears exited_at and exit_reason together'` | The paired CHECK |
| | `'undoExitPen is refused when a later occupancy exists for the same ewe'` | The second half of 07 §15.1's condition — the ewe, not only the pen |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Nothing is ever removed, only struck** (Indelible rule 1). No verb on this board deletes a row: a
  turn-out closes one, a move closes one and opens one, and both stay in the record forever.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'turn out costs one tap and a corrected entry time renders the edited marker on the tile'` passes, and was seen to fail first for the stated reason
- [ ] each action is one tap
- [ ] the edited marker appears wherever a corrected time is rendered
- [ ] mark-as-group writes one row per animal, in one transaction
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] every verb goes through `WriteController.guard()`, and the double-tap test has no pump between its taps
- [ ] `movePen` is one transaction, and the new occupancy's `entered_at` is the move instant
- [ ] the undo window is stated in seconds in the copy, and `showSnackBar(` appears nowhere (P2)
- [ ] the edited marker renders the mark **and** the word, from `RecordedTime.provenanceLabel`
- [ ] `lib/features/pens/` imports no other feature folder; Foster is reached through `Routes`
- [ ] the new widget keys are recorded in `07-screens.md` §9.5 in this commit

> **Read the second DoD line with 07 §9.5 open.** *One tap* is one tap **per verb, once the row is
> open** — two from the board, with no confirmation step. A literal one-tap-from-the-board turn-out is
> not a stretch goal; it is refused, and the reason is a ewe with a chilled lamb still under the lamp.

## 8. Verification

```bash
# 1. Red first, for the stated reason.
fvm flutter test test/features/pen_board_test.dart

# 2. Green, both tiers — the verbs and the screen.
fvm flutter test test/features/pen_board_test.dart test/data/pen_repository_test.dart

# 3. The receipt policy P2 fixed, which this screen must not reopen.
fvm flutter test test/policy/no_snackbar_test.dart

# 4. Both gates.
make check
make test
```

```bash
grep -rn "showSnackBar(\|Dismissible\|Draggable" lib/features/pens/   # expect nothing
grep -rn "features/lambing" lib/features/pens/                       # expect nothing (layer rule 6)
grep -rn "enableDrag\|isDismissible\|showDragHandle" lib/features/pens/widgets/pen_action_sheet.dart
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(pen_board): turn out, move and group in one tap, with the edited marker`

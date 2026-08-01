# N19-T07 — The matrix variant, the grid semantics tree and the empty state

| | |
|---|---|
| **Epic** | [N19 — Pen Board](epic.md) · `00-README` §9 step 6 (5 of 5) |
| **Task** | 7 of 7 |
| **Depends on** | N19-T06 |
| **Commit** | one commit · `test(features): the pen_board matrix variant and grid semantics` |

## 1. Why this task exists

`pen_board` joins `kPumpableVariants`, and the grid gets a **real semantics tree** — a
board that reads as twelve unlabelled buttons is unusable with a screen reader, and the grid is the one
place a naive implementation produces exactly that.

10 §3.5 calls it *"hard case A"* and gives the resolution in four rules and one published function.
This is the task that ships them, and the last chance to do so: N33 verifies the semantics gate over
every variant, it does not author labels.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `shed-book-spec.md` | §7.4 (*"works as a glanceable board"*), §5 (*"every screen must pass this"*) | why every device, scale and bold state is a cell rather than a spot check |
| `docs/engineering/10-accessibility-and-i18n.md` | **§3.5 (hard case A, in full: the list-not-table rule, the summary node first, one sentence per row, row-major tree order, `penTileSentence` printed verbatim, the `Semantics` wrapper, the ban on `MergeSemantics` and on `sortKey`, and the §12.2 tension with its exact spoken string)**, §3.3 (`spellOutTag` and `attributedLabel`), §3.4 (the board's level-1 title and no level-2), §7.3 (the semantics gate over the variants), §8.4–§8.5 (ARB rules and the terminology placeholder) | every node, every label and the one sentence asserted character-for-character |
| `docs/engineering/12-testing.md` | **§6.1–§6.2 (the variant table, `kPumpableVariants`, and the derived arithmetic)**, §6.3 (*"fix the layout, never the matrix"*), §6.4 (reachability), §7.4 (which gate iterates the table), §5.1–§5.2 (`Device`, `pumpApp`, the two seeding routes) | the table this task adds a row to, and how a cell is written |
| `docs/engineering/CONVENTIONS.md` | **R58** (the count follows the variant list, never a remembered number), R57 (the test tree), §4.1 (test file naming), §4.5 (widget keys) | **BINDING** on the count and the paths |
| `docs/engineering/07-screens.md` | §9.4 (**the four states**, including *frame 1* and both empty states), §21.2 (the matrix and the reachability assertions) | which states must pump clean |
| `docs/design/indelible.md` | §8 screen 7 (the header line — *"THE PENS · 27 JULY 04:12 · 5 OCCUPIED · 2 OVER †"* — which is the summary node in visible form), §3.6 (at 200% the row grows to 152 px), §1.3 (no empty state with an illustration) | what the summary says, and what the empty state may not be |
| `docs/engineering/06-design-system.md` | §5.4 (reflow, never clip; `FittedBox` banned), §12 (`ShedEmptyState` occupies the same box the populated content will) | the layout rules the matrix is asserting |
| `epics/00-PLAN-CRITIQUE.md` | **S3** (the fixtures arrive in N23; the matrix seeds until then), S1 (the harness grows per epic) | why this task seeds rather than restores |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-accessibility-and-copy` | the grid's semantics tree and its traversal order |
| `shed-testing` | the variant table and its derived count |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/overflow_matrix_test.dart`
- **Test** — `'pen_board pumps at every device, text scale and bold state and its grid exposes a labelled node per pen'`
- **Why it is red today** — the screen exists, the variant table does not know about it, and the grid has no semantics.

```bash
fvm flutter test test/features/overflow_matrix_test.dart   # expect: failing, for the reason above
```

Sharpen it into the two halves, and keep the count derived. **Pumps clean:** `pen_board` is the fifth
key in `kPumpableVariants`, so the generated cell count becomes
`kPumpableVariants.length * Device.all.length * kTextScales.length * kBoldStates.length` — today
**5 × 3 × 3 × 2 = 90** — computed from the same lists the loops iterate and never typed. Each cell
seeds twelve pens through `test/support/seeds.dart`, pumps, and asserts `tester.takeException()` is
null. **Labelled node per pen:** at `Device.small` × textScaler 1.0, walk the semantics tree and
assert exactly twelve nodes carrying `SemanticsRole.listItem`, each with a non-empty label, in
row-major order, preceded by the summary node.

**Green.** The minimum code that passes, and nothing beyond it — the row, the semantics tree, the empty state.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 6 (semantics and the ARB) and step 7 (tests).** No schema, no domain, no data, no new
provider. Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/features/pens/widgets/pen_tile_semantics.dart` | **New.** `penTileSentence` — 10 §3.5's published function, at the path that document gives it |
| 2 | `lib/features/pens/pen_board_screen.dart` | **Edit.** The board gains `SemanticsRole.list`, the summary node as its **first child in tree order**, and each row wrapped in `Semantics(role: listItem, button: true, attributedLabel:, onTap:, onTapHint:)` over an `ExcludeSemantics(child: ShedPenTile(...))` |
| 3 | `lib/l10n/app_en.arb` | **Edit.** `penNamed`, `penEmpty`, `pennedForHours`, `timeEditedByYou`, `penReadyThreshold`, `penClearOn`, `penLossRecorded`, `hintOpenPen` and the summary message — each with a `description`, and each taking the animal noun as a **placeholder** fed by `terminologyProvider` |
| 4 | `test/support/harness.dart` | **Edit, one line plus a ledger tick.** `RouteNames.penBoard: () => const PenBoardScreen()` — the fifth entry. Strike `pen_board` off the ledger comment N13-T07 wrote |
| 5 | `test/support/seeds.dart` | **Edit.** `seedTwelvePens(db)` — twelve pens, five occupied, two over any plausible threshold, one with a loss, one under withdrawal, one empty, one orphan. The matrix must pump the **populated** board; an empty board cannot overflow and proves nothing |
| 6 | `test/features/overflow_matrix_test.dart` | **Edit.** The anchor, and the derived count updated to five variants |
| 7 | `test/features/pen_board_test.dart` | **Edit.** §5.4's semantics and empty-state cases, which are cheaper here than in the matrix |

### 5.2 The signatures

10 §3.5 prints the function; it is copied, not re-invented, and the only change is that `t.hours` and
`t.status` arrive already resolved for this tick (T04's `forTick`):

```dart
// lib/features/pens/widgets/pen_tile_semantics.dart
/// One sentence per row. The visible row paints pen number / tag / tally /
/// hours / status; this node is what TalkBack and VoiceOver read, and the two
/// must agree word-for-word on the words that are visible (the Voice Control
/// criterion, 10 §3.2 rule 3).
String penTileSentence(BuildContext context, PenTile t, Terminology terms);
```

And the wrapper, which is the pattern and not a suggestion:

```dart
Semantics(
  container: true,
  role: SemanticsRole.listItem,
  button: true,
  attributedLabel: spellOutTag(sentence, t.tag),
  onTap: onOpen,                        // opens the pen action sheet (07 §9.5), not a route
  onTapHint: l10n.hintOpenPen,          // "…double tap to open pen"
  child: ExcludeSemantics(child: ShedPenTile(tile: t, term: term, onOpen: onOpen)),
)
```

The exact spoken sentence for a ready row, which 10 §3.5 requires the traversal test to assert
**character-for-character**:

```
Pen 4. gimmer 412. penned 26 hours. Ready — your 24 hour threshold
```

### 5.3 The details that are easy to get wrong

1. **The board is a list, not a table.** `SemanticsRole.list` on the board and
   `SemanticsRole.listItem` on each row (10 §3.5 rule 1). Pens are an unordered collection of
   independent facts; `table` invites row-and-column navigation that yields nothing, and the one place
   `table` is correct in this app is the chart's alternative view.
2. **The summary node comes first in tree order, and needs no `sortKey` because of that.**
   *"12 pens. 3 ready to turn out. 1 under withdrawal. 2 empty."* — the spoken equivalent of the
   glance, and the same content as Indelible's visible header line. Build it as the first child.
3. **`sortKey` is banned outright in v1** (`a11y.sort_key` is a gate row). `OrdinalSortKey` sorts only
   among siblings inside one semantics group and misbehaves silently when mixed with unsorted
   siblings. Tree order **is** traversal order; build the rows in the order they read.
4. **`MergeSemantics` is banned** (`a11y.merge_semantics`). It joins child labels with newlines, takes
   the first gesture handler, and gives no control over sentence order — it breaks the moment a row
   grows a badge. `Semantics(label:) + ExcludeSemantics` is the pattern, and it is the same one
   `ShedTapTarget` already uses.
5. **One node per row, not three.** *"Pen 4" + "412" + "26h"* as three nodes is a screen reader
   reading a spreadsheet aloud. The sentence is in the order a shepherd would say it, and **status
   comes last and only when true** (10 §3.5 rule 3).
6. **The §12.2 tension has one resolution and it is not "drop the word".** The visible chip reads
   `26h · READY`; Voice Control matches visible words, so the label must contain `READY`; and safety
   rule §12.2 forbids the app claiming an animal is fit to turn out. Both hold because the word and
   the disclosure travel together in both channels — the legend says *"Ready = your 24 h threshold"*
   and the spoken sentence names the threshold. 10 §3.5: **never ship a label whose only status word
   is "Ready" with no threshold, and never ship one that drops the visible word entirely.**
7. **The tag is spelled out through `spellOutTag` into `attributedLabel`, never `label`.** `412` read
   as *"four hundred and twelve"* is a different animal from `4 1 2` in a shed where tags are read
   digit by digit. 10 §3.3 requires the unit test set for it — the pen-row sentence, a bare
   `'gimmer 412'`, a tag that is a substring of the term, and a null tag — and warns that an
   off-by-one *"spells out half the sentence and nobody notices without a device."*
8. **`_penColumns` is not built and the reflow is not implemented, because there is no grid.** 10 §3.5
   closes with a `LayoutBuilder` helper dropping the board 4 → 3 → 2 → 1 as text grows; Indelible §8
   screen 7 refuses the grid outright, so the board is one ruled column at every scale (T05 §5.3).
   WCAG 1.4.10 is satisfied by construction, the matrix's 200% cells stop being the interesting ones,
   and the semantics tree the same section asks for is trivially linear. State the departure in the
   PR body — it removes code from two documents, and a reviewer who has read 10 will look for it.
9. **The count is derived, never remembered.** R58: *"the arithmetic follows the variant list."*
   `pen_board` is the **fifth** entry — after `quick_entry` (N13), `lambing_entry` (N16), `lamb_card`
   (N17) and `foster` (N18) — so the product is 90 today, and it reaches 252 over fourteen variants at
   N33-T01. Do **not** write `expect(kPumpableVariants.length, 14)` here; that assertion belongs to
   the epic that makes it true.
10. **Seed; do not `restoreFixture`.** `flock_400_3seasons.json` arrives at N23-T05 (critique S3).
    12 §6.2's printed matrix body calls it, and copying that line verbatim gives a red test that looks
    like a product bug. Use `test/support/seeds.dart`, and leave the ledger comment N13-T07 wrote
    intact.
11. **Both empty states pump too.** The zero-pen board and the pens-but-none-occupied board are
    layouts, and `ShedEmptyState` *"occupies the same box the populated content will"* (06 §12) — so
    the cell that renders it must not shift, must not overflow at 200% bold, and must keep its one
    action reachable. There is no illustration and no tour (Indelible §1.3).
12. **A failing cell is a layout to fix, never a cell to delete** (12 §6.3). Clamping `textScaler` is
    banned outright (decision #99) and `FittedBox` around user-facing text is banned in review — the
    two legitimate fixes are a scroll view off the primary-action path, or less on the screen.
13. **The board carries one `headingLevel: 1` and no level-2 headings** (10 §3.4). It is one list; a
    heading per row would add navigation stops to a screen whose entire purpose is a single glance.
14. **`ExcludeSemantics` wraps the visual, and the visual keeps its widget keys.** The keys are how
    every other test in this epic finds the row; excluding semantics does not exclude keys.

### 5.4 The full test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/features/overflow_matrix_test.dart` | `'pen_board pumps at every device, text scale and bold state and its grid exposes a labelled node per pen'` | **The anchor.** 18 new cells, plus the tree walk |
| | `'the matrix count equals kPumpableVariants.length times the device, scale and bold axes'` | N13-T07's self-check, now at five variants and 90 cells — derived, with the `reason:` naming N33-T01 as the task that makes it 252 |
| | `'every RouteNames constant whose screen exists is in the variant table'` | Membership derived from the built screens, so the table cannot silently stop covering one |
| `test/features/pen_board_test.dart` | `'the board exposes one labelled listItem per pen, in row-major order'` | Twelve nodes, twelve labels, one order |
| | `'the summary node is the first child and names the counts'` | Rule 2, and the reason no `sortKey` is needed |
| | `'the spoken sentence for a ready pen is exactly "Pen 4. gimmer 412. penned 26 hours. Ready — your 24 hour threshold"'` | 10 §3.5's character-for-character assertion, and the §12.2 resolution in one string |
| | `'an empty pen reads "Pen 2. Empty" and nothing else'` | Status last and only when true; no hours for a pen with no occupant |
| | `'a row with an edited entry time speaks the edited phrase'` | §12.5 in the second channel — the marker is not only visual |
| | `'the tag is spelled digit by digit in the attributedLabel'` | `spellOutTag`, plus its four unit cases (10 §3.3) |
| | `'no MergeSemantics and no sortKey appear under lib/'` | Two gate rows, duplicated in the tier a developer runs first |
| | `'the zero-pen state pumps clean at 200% with bold text and keeps its action reachable'` | The empty state as a layout, not as a message |
| | `'the pens-but-none-occupied state pumps clean and renders twelve tappable rows'` | The second empty state, which is the one a shepherd carrying a ewe actually needs |
| | `'the screen exposes exactly one headingLevel 1 node and no headingLevel 2'` | 10 §3.4 |

## 6. Constraints that bind this task

- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **The matrix is a gate, not a report.** A failing cell is a layout defect; deleting the cell is
  deleting the 3am test, and clamping the text scale to pass is banned outright.
- **The count follows the list** (R58). Every number in this file is computed from `kPumpableVariants`
  and the three axis lists.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'pen_board pumps at every device, text scale and bold state and its grid exposes a labelled node per pen'` passes, and was seen to fail first for the stated reason
- [ ] one labelled semantics node per pen, in a sensible traversal order
- [ ] the count stays derived
- [ ] the zero-pen state is the empty state, and it is the same box
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `pen_board` is the fifth entry in `kPumpableVariants` and the ledger comment is ticked off
- [ ] the summary node is the first child in tree order, and no `sortKey` appears anywhere under `lib/`
- [ ] `MergeSemantics` appears nowhere; every row is `Semantics(...) + ExcludeSemantics(child:)`
- [ ] the ready row's spoken sentence names the user's threshold and keeps the visible word `READY`
- [ ] the matrix cells seed through `test/support/seeds.dart`; `restoreFixture` is not referenced
- [ ] `_penColumns` does not exist, and the departure from 10 §3.5's grid helper is stated in the PR body

## 8. Verification

```bash
# 1. Red first, for the stated reason.
fvm flutter test test/features/overflow_matrix_test.dart

# 2. Green — the matrix, then the screen's own semantics cases.
fvm flutter test test/features/overflow_matrix_test.dart test/features/pen_board_test.dart

# 3. The design tier, which iterates the same table.
fvm flutter test test/design/

# 4. The whole widget tier at the cell that fails first, if one does.
fvm flutter test test/features/overflow_matrix_test.dart --plain-name 'small · scale 2.0 · bold true'

# 5. Both gates.
make check
make test
```

```bash
grep -rn "MergeSemantics\|sortKey\|FittedBox" lib/            # expect nothing
grep -rn "restoreFixture" test/features/overflow_matrix_test.dart   # expect nothing until N23-T05
grep -n "penBoard" test/support/harness.dart                  # expect: the fifth entry
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(features): the pen_board matrix variant and grid semantics`

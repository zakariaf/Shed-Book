# N19-T05 — `ShedPenTile` — five statuses, two non-colour channels each

| | |
|---|---|
| **Epic** | [N19 — Pen Board](epic.md) · `00-README` §9 step 6 (5 of 5) |
| **Task** | 5 of 7 |
| **Depends on** | N19-T04 |
| **Commit** | one commit · `feat(ui): ShedPenTile with two non-colour channels per state` |

## 1. Why this task exists

Twelve ruled rows, five statuses, and **every state carrying two non-colour channels** —
a word and a mark — because a head torch and a red-shift palette between them destroy hue
discrimination, and a board read wrong from arm's length is worse than no board.

`ShedPenTile` is one of the six components `00-PLAN-CRITIQUE` G1 places in the screen epic that needs
it rather than in N10, because its five states are this screen's and nowhere else's. It is the last
shared component the app gains.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `shed-book-spec.md` | §7.4 (*"works as a glanceable board — legible from arm's length in a head torch"*), §5 (the 3am floor) | the requirement every encoding on this row answers to |
| `docs/design/indelible.md` | **§7.5 (the pen row — *"the tile that is not a tile"*: the 44 px pen number, the tag, the tally, the hours column, `— empty —`, and the five row states)**, §8 screen 7 (the four channels of the over-threshold badge, and *"delete the colour entirely and three channels remain"*), §2.7 (status without colour, as a table), §6.2 (the six marks: the dagger, the tally, the strike), §6.3 (2 px, butt caps, `currentColor`, no fills), §3.4 (the scale, and the 14 px stamp exemption test), §4.4 (88 px row height), §5.1 (a press is a fill change only) | **what the row actually looks like**, mark by mark |
| `docs/engineering/06-design-system.md` | §11 (**the five statuses with their fixed label text**, the glanceability arithmetic at 60 cm, reflow-never-clip, `FittedBox` banned), §12 (`ShedPenTile`'s row in the component inventory: *"≥ 2 × `tapPrimary` square, reflowing; settling, ready, attention, loss, empty"*), §5.5 (tabular figures), §6.1 (the tap scale) | the status set, the label text and the sizes |
| `docs/engineering/CONVENTIONS.md` | §2.11 (the design-system type catalogue), §4.1 (`components/shed_pen_tile.dart`), §4.5 (widget keys), **R36** (*"06's five-row table, including its label text, is canonical"*), R35 (palette ids and labels), R70 (shared components live in `lib/core/ui/components/`) | **BINDING** on the name, the path and the five words |
| `docs/engineering/07-screens.md` | §9.3 (tile content: **at most three facts**, the type sizes, the status table reproduced from 06, the reflow rule), §9.4 (the empty-pen encoding) | what may and may not be on the row |
| `docs/skills/02-build-manifest.md` | §4.4 **defect 2** (`--t-stamp` 14 px fails §3.4's exemption test on `DEAD`, `AUTO-CAPTURED` and `DERIVED` — *"those three are not exempt stamps and must meet the 18 px floor"*), §4.3 (Indelible only), §4.5 (**P9** — tap separation, 16 pt versus 8–12 px, is open) | the one stamp on this row that may not be 14 px, and the open conflict not to settle here |
| `docs/engineering/10-accessibility-and-i18n.md` | §5 (colour is never the only channel), §3.5 (the visible chip and the spoken sentence must agree word-for-word on the visible words) | why the word is a channel and not decoration |
| `docs/engineering/12-testing.md` | §7.4 (the design tier and what it iterates), §7.6 (`contrast_test.dart` over the palettes), §8.2 (`pen_board_12_pens` is a golden — **and it is N33's**) | where this test lives and what it may not add |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-marks-and-strikes` | the statuses, the marks and the colour-never-alone rule |
| `indelible-page-and-screens` | the tile's geometry and the board's grid |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/components_test.dart`
- **Test** — `'every ShedPenTile status carries a word and a mark as well as a colour'`
- **Why it is red today** — no tile exists, and the obvious implementation is a coloured rectangle.

```bash
fvm flutter test test/design/components_test.dart   # expect: failing, for the reason above
```

Sharpen it so it is a property, iterated over the enum rather than written five times. For each
`PenTileStatus` value: pump the row, assert a **word** is rendered (the status text from `app_en.arb`,
found by key), assert a **non-colour mark** is present (the dagger glyph, the doubled rule, the dotted
rule or the strike, found by its own key), and assert that with the colour channel removed — pump the
same row under `ColorFiltered` with a saturation-zero matrix — the two channels are still findable.
The enum is exhaustive, so a sixth status added later fails this test until it declares its channels.

**Green.** The minimum code that passes, and nothing beyond it — the component, its five states, and the two-channel assertion per state.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 6 (UI and the ARB) and step 7.** No schema, no domain, no data, no provider — this is a pure
component plus the screen swapping to it. Say the skipped layers in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/components/shed_pen_tile.dart` | **New.** `ShedPenTile` — a `StatelessWidget` over `context.tokens`, no state, no provider, no drift, no `BuildContext` stored. It takes what it paints and nothing more |
| 2 | `lib/features/pens/pen_board_screen.dart` | **Edit.** Replace T04's private row with `ShedPenTile`; the screen keeps the tick, the threshold and the ordering |
| 3 | `lib/l10n/app_en.arb` | **Edit.** The five status words and the empty line, each with a `description`. `READY`, `DEAD`, `— empty —` and the `CLEAR {date}` pattern are messages, never literals in the widget |
| 4 | `docs/engineering/06-design-system.md` §12 | **Edit, in this commit.** The inventory row for `ShedPenTile` gains the ruled-row geometry it actually ships with; §12 is what stops the next reader building a second one (the same amendment N16-T02 made for `ShedTally`) |
| 5 | `test/design/components_test.dart` | **Edit** (created at N10). The anchor plus §5.4's cases |

### 5.2 The signatures

```dart
// lib/core/ui/components/shed_pen_tile.dart
//
// "The tile that is not a tile" (indelible.md §7.5). The board is twelve ruled
// ROWS, 88 px each, one per pen — not a grid of cards, because a grid forces
// the eye to zig-zag and a ruled column does not. The class name is 06 §12's
// and CONVENTIONS §4.1's; the geometry is Indelible's.
class ShedPenTile extends StatelessWidget {
  const ShedPenTile({
    super.key,
    required this.tile,          // PenTile, already resolved for this tick (T04)
    required this.term,          // TermLabel from terminologyProvider — never a literal noun
    required this.onOpen,        // the row is a target even when the pen is empty
  });

  final PenTile tile;
  final TermLabel term;
  final VoidCallback onOpen;
}
```

The five statuses, with 06 §11's label text and Indelible's rendering. **Every row has at least two
non-colour channels**, and the colour column is reinforcement only:

| `PenTileStatus` | Word (06 §11, R36) | Mark | Geometry | Colour |
|---|---|---|---|---|
| `settling` | the hours alone — `4h` | — | single 2 px rule beneath the row; hours in `--ink-mid` | none |
| `ready` | `26h · READY` | `†` in the margin cell, 24 px | **the rule beneath the row doubles** — two 2 px lines, 3 px apart — and the hours lift from `--ink-mid` to `--ink-full` | the dagger only |
| `attention` | `12h · CLEAR 14 JUL` | circle-slash badge on the row | dashed outline on the badge | `statusAttention` as reinforcement |
| `loss` | `DEAD` | — | printed in the lamb column in full ink; sorted above settling rows | **none, ever** |
| `empty` | `— empty —` | — | 2 px **dotted** rule where the value would be; sorted to the bottom | none |

Row anatomy, left to right (Indelible §7.5, §8 screen 7):

```
margin cell (68 px) │ pen number (44 px tabular) │ tag (32 px tabular) │ tally │ … │ hours (32 px, right-aligned)
```

### 5.3 The details that are easy to get wrong

1. **It is a row, not a tile, and the name does not change.** 06 §12 calls it `ShedPenTile` and
   CONVENTIONS §4.1 fixes the file as `components/shed_pen_tile.dart` — names are CONVENTIONS'.
   What it *looks like* is Indelible's, and Indelible §8 screen 7 refuses the grid explicitly:
   *"a grid forces the eye to zig-zag — across, down, back, across — and every hop is a chance to read
   pen 7's hours against pen 8's occupant."* So: 88 px full-width ruled rows, one column, at every
   text scale. 06 §11's *"reflow 4 → 3 → 2 → 1"* and 10 §3.5's `_penColumns` helper describe the grid
   that is not being built; the WCAG 1.4.10 requirement they exist to satisfy is met by construction.
2. **`DEAD` is not an exempt stamp and may not be 14 px.** Indelible §3.4 permits stamps below the
   18 px floor on three conditions, the third being *"no stamp is ever the sole carrier of its
   meaning"*. `DEAD` is (build-manifest §4.4 defect 2), so it renders at the 18 px floor or above.
   `OVER` — in this system's own prose for the ready row — keeps the exemption, because it sits beside
   a dagger and a doubled rule.
3. **The word for the over-threshold state is `READY`, not `OVER`.** R36 rules that 06 §11's
   five-row table *"including its label text"* is canonical, and CONVENTIONS outranks every document
   on a word. Indelible §8 screen 7 draws the same state and calls it `OVER` in its own prose; ship
   one word, and ship 06's. The legend beside it — *"Ready = your 18 h threshold"* — is what keeps
   `READY` inside §12.2, and 10 §3.5 requires the spoken sentence to carry the same visible word.
4. **A dead lamb is never red.** Indelible §2.7's table says *"none, ever"* for the lamb-dead row and
   adds the reason: *"It would be trivially easy to make a dead lamb red. It is not, and never will
   be. Death is a word."* 06 §11 assigns it `statusLoss`. On this row, ship the word, the position and
   the ink weight; if you keep 06's hatch as a second non-colour channel, keep it — what you may not
   ship is a hue that is the only thing distinguishing a loss. Record whichever you chose in the PR
   body, and amend 06 §11 in the same commit if you departed from it (the amendment rule).
5. **Five similar icons are one icon at 60 cm.** The shape encodings must be *structurally* different
   in silhouette — a doubled rule, a dotted rule, a dagger, a badge — not four variants of one glyph
   (06 §11, Indelible §6.3). The mark budget is six and *"no new mark may be added without deleting
   one"*; this row uses three of them and invents none.
6. **The verification is a grayscale read, and it is a ship gate rather than a discussion.** 06 §11:
   *"run the board under the OS grayscale filter and read it. If you cannot, it fails."* The automated
   half is the anchor's saturation-zero pump; the human half is done once, by hand, and stated in the
   PR body.
7. **At most three facts on the row: tag, hours, status.** *"Four facts at 60 cm is zero facts"*
   (06 §11). The lamb count is a **tally**, which is a fourth mark only in the sense that you do not
   read it — you see two strokes and know there are two lambs. Everything else — dam, treatments,
   the entry time itself — lives in the sheet T06 opens.
8. **Use `ShedTally`, do not draw strokes here.** `lib/core/ui/components/shed_tally.dart` landed in
   N16-T02 and that task placed it in `lib/core/ui/components/` **specifically because this row prints
   the same mark**. It takes `marks` and a required `semanticLabel`; pass `tile.lambCount`.
9. **Never construct a bare `TextStyle` for a numeral.** It drops `FontFeature.tabularFigures()` and
   the board starts jittering as `412` and `108` take different widths (06 §5.5) — silent, and the
   pen-board golden is what would eventually catch it. Go through the `TextTheme` role.
10. **`FittedBox` around user-facing text is banned and grepped** (06 §5.4). Shrinking a tag to fit is
    the opposite of legible, and it silently undoes the shepherd's own font setting.
11. **The empty row is still a target.** *"When you are carrying a ewe you need to see where the space
    is at least as urgently as where the sheep are"* (Indelible §7.5, §8 screen 7). Tapping an empty
    row opens the same sheet, pre-loaded to put an animal in.
12. **P9 is open and this task does not settle it.** 06 §6.1 asks for `gapMin` 16 between any two
    targets; Indelible stacks 88 px rows separated by a 2 px rule and nothing else. Build the rows as
    Indelible draws them, name P9 in the PR body, and if `test/design/tap_target_test.dart`'s
    separation assertion fires, route the ruling to the owner instead of inserting a gap that changes
    the density the board's whole argument rests on.
13. **No golden here.** `pen_board_12_pens` is one of the eight images (12 §8.2) and it belongs to
    N33, which owns the `goldens` job and the re-baselining runbook. A `matchesGoldenFile` call added
    on this branch would be an unbaselined image on a job that does not run.
14. **A press is a fill change — no scale, no ripple, no elevation** (Indelible §5.1, §7.5). *"A
    target that shrinks under a cold thumb is a target you miss."*

### 5.4 The full test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/design/components_test.dart` | `'every ShedPenTile status carries a word and a mark as well as a colour'` | **The anchor**, iterated over the enum, with the saturation-zero pump |
| | `'the five statuses are exhaustive and a sixth fails to compile'` | The `switch` over `PenTileStatus` has no `default:` — the day a sixth arrives, the build breaks rather than rendering nothing |
| | `'the ready row draws a doubled rule and the settling row a single one'` | Geometry as a channel, asserted on the painted rule count rather than on a colour |
| | `'the empty row renders the em-dash line, keeps its target and sits at the bottom'` | The state most likely to be optimised away |
| | `'DEAD renders at 18 px or above'` | Build-manifest §4.4 defect 2, read off the resolved `TextStyle.fontSize` |
| | `'READY renders the word READY and never the word OVER'` | R36, as a rendered-text assertion |
| | `'the row is at least 88 logical pixels tall at textScaler 1.0 and grows at 2.0'` | Indelible §3.6's row-height table — grows, never clips |
| | `'the hours numeral carries tabular figures'` | The silent 06 §5.5 regression |
| | `'no FittedBox and no raw Color appear in the component'` | Duplicates two gate rows in the tier a developer runs first |
| | `'the lamb count renders as ShedTally and not as a digit'` | The shared mark, and the reason it lives in `lib/core/ui/components/` |
| | `'a press changes the fill and not the size'` | Indelible §5.1, asserted on the painted rect |

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Colour is never the only channel** (decision #106, WCAG 1.4.1 Level A). The night palettes destroy
  the hue channel deliberately, and a red head torch destroys it before the shepherd looks.
- **Tokens only** — every colour and every metric through `context.tokens`. A raw `Color(0x…)` or a
  magic size in this file is a build-breaking defect, and `lib/core/ui/primitives.dart` is importable
  only from inside `lib/core/ui/`.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every ShedPenTile status carries a word and a mark as well as a colour'` passes, and was seen to fail first for the stated reason
- [ ] five states, each with a word and a mark
- [ ] legible from arm's length at the smallest device
- [ ] no state distinguishable by colour alone
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `DEAD` renders at 18 px or above; every other stamp on the row keeps the 14 px exemption
- [ ] the over-threshold word is `READY` (R36), and the legend beside it names the user's own number
- [ ] the row uses `ShedTally` for the lamb count and draws no strokes of its own
- [ ] `06 §12`'s inventory row for `ShedPenTile` is updated in this commit
- [ ] the board was read once, by hand, under the OS grayscale filter, and the result is stated in the PR body
- [ ] no `matchesGoldenFile` call is added — `pen_board_12_pens` is N33's

## 8. Verification

```bash
# 1. Red first, for the stated reason.
fvm flutter test test/design/components_test.dart

# 2. Green, plus the screen that now mounts it.
fvm flutter test test/design/components_test.dart test/features/pen_board_test.dart

# 3. The design tier that already exists, in case a token moved.
fvm flutter test test/design/

# 4. Both gates.
make check
make test
```

```bash
grep -rn "Color(0x\|FittedBox\|TextStyle(" lib/core/ui/components/shed_pen_tile.dart   # expect nothing
grep -rn "matchesGoldenFile" test/design/ test/features/pen_board_test.dart            # expect nothing
grep -rn "'READY'\|'DEAD'" lib/                                                        # expect nothing — ARB messages
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): ShedPenTile with two non-colour channels per state`

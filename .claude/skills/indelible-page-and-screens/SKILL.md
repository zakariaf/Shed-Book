---
name: indelible-page-and-screens
description: >-
  The page every screen is — one ruled document under twelve filters. Use when composing or laying
  out a screen, or choosing any padding, gap, width, height or target size. Do NOT use for what a
  screen shows or how it is reached (shed-screens-and-routing), or for a struck row
  (indelible-marks-and-strikes).
---

# The page

There is **one** scrolling ruled document. Twelve screens and note search are that document under a
different filter — one spine, one header, one slab, one `INDEX` button. What changes is what the
filter lets through (`docs/design/indelible.md §8`). A layout that needs a second structure is wrong.

`docs/design/indelible.md` is the design system of record; `the-register.md` and `strip-bay.md` were
**not** selected and no element of either may appear in code, bar the single graft in §2.
`docs/engineering/CONVENTIONS.md` and `docs/research/00-tech-decisions.md` §5 are BINDING and outrank
this skill on every name and version number.

## Not this skill

- A row's **struck or queried** state, the dagger, the tally, the five printer's marks →
  `indelible-marks-and-strikes`.
- **How a target is painted** — slab, key, word button, stepper, field, sheet chrome →
  `indelible-controls`.
- **What data a screen shows**, its route, its states, its tap budget, undo →
  `shed-screens-and-routing`.
- Colour, contrast, faces and type sizes → `indelible-design-system`.

## 1. The two corrections — the mockup is wrong, encode these instead

1. **The live row is a fixed layer above the bottom band. It cannot scroll away.**
   `indelible.html:1138` has `.row.live` as the last child of the scrolling `.stream`, so the open row
   can be scrolled off screen and you lose track of whose row is open. That is the design's one
   genuine safety gap (`docs/design/00-comparison.md §4.1`). Build the live row as a sibling of the
   band, not a stream child — the band is already positioned, so the live row is a second fixed layer
   above it. The stream scrolls **under** both.
2. **`DEAD`, `AUTO-CAPTURED` and `DERIVED FROM 3 STROKES` are not exempt stamps and must meet the
   18 px floor.** Each carries meaning nothing else on its line carries (`AUTO-CAPTURED` is the sole
   §12.5 provenance label; `DERIVED FROM 3 STROKES` is the sole statement of the §12.4 claim). Layout
   consequence you own: **an 18 px caps-tracked word does not fit the 68 px margin cell** — six
   characters is already ~84 px. So those three print **in the record column**, never in the margin.
   The margin keeps only the short stamps `AUTO` / `STRUCK` / `EDITED` at `--t-stamp`, which stay
   exempt because each sits beside a redundant mark (§3.4's test).

## 2. The persistent loaded subject — the one adopted graft

This idea is **Indelible's**: **the animal being written about is the largest object on the phone and
survives a cold launch** (`docs/design/00-comparison.md §4.1`). It is the one graft the manifest
allows and it is **carried unattributed** — never name its origin in code, a comment, a commit
message or a review, and never import anything else with it.

Survival is a **query, not restored UI state.** The row commits to SQLite at the first keystroke, so
tonight's page re-renders the open lambing from the database. `RestorationMixin`,
`restorationScopeId` and every `Restorable*` stay banned (decision #24), and the >2-minute resume
reset still lands on Quick Entry with nothing *selected* — the open row is printed anyway, because it
is a fact in the database.

## 3. The grid — 393 × 852 reference viewport (`indelible.md §4.3`)

| x | What |
|---|---|
| 0 – 68 | **Margin cell.** Auto-captured time, the short stamp, `†`, `?`. **68 × 64 is itself a legal tap target** — tapping a dagger or a query mark opens its explanation. |
| 68 | **The madder spine.** 2 px, `--madder-rule`. |
| 76 – 377 | **Record column**, 301 px. Starts 8 px right of the spine. |
| 377 – 393 | Right gutter, 16 px. |

- **The spine is continuous down the entire scroll.** It does not break for headers, sheets,
  sections, the sticky header or the live row; the sheet rises in front of it and the spine continues
  behind. **If a component would interrupt the spine, that component is wrong.**
- **The spine never mirrors.** A book's margin is on the left.
- Row sub-grid inside the record column: tag 76 px fixed right-aligned · body flex left · lamb tally
  132 px fixed right · trailing status fits content, min 64 px. Tags right-align on their units digit
  — that is what makes the flock page scannable, not a preference.
- The live row stops 12 px short of the slab: 301 − 160 − 12 = **129 px** of body width, which is why
  the live row prints two lines and the slab overlaps nothing.

**Radii:** record 0, sheet 0, slab 2 px. There is no third radius. **No shadows, no elevation**
anywhere; the sheet is separated by a rule rather than a shadow (`indelible.md §4.2`). Rule weights
and why a hairline is banned belong to **indelible-marks-and-strikes** — read the weight there and do
not carry a number from this file into a painter.

## 4. The spacing scale — and why a literal fails the build

Four-based, no half-steps: **4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 · 64 · 88 · 132**
(`indelible.md §4.1`; the section calls it ten steps and tabulates twelve tokens `--s-1`…`--s-12` —
use all twelve). Every padding, gap, width and height comes from that scale or from the row-height
table. Nothing else.

**These are not CSS. They enter Dart as named constants and nothing else.** `tool/check_policy.dart`
row `token.magic_size` fails any numeric literal other than 0/1 in `EdgeInsets*`, `SizedBox`,
`BoxConstraints`, `Size`, `Radius.circular`, `width:`, `height:`, `spacing:`, `strokeWidth:` anywhere
under `lib/` (`06-design-system.md §3.5`). So raw values go in `lib/core/ui/primitives.dart` — whose
existing `s04`…`s32` scale is **too short for this grid**, extend it, and it is import-banned outside
`lib/core/ui/` — and named metrics go on `ShedTokens` in `lib/core/ui/tokens.dart`, read through
`context.tokens`, named per `06 §3.4`'s prefix scheme. **Add the token; never add a literal to a
widget** (`06 §1`). `ShedTokens.lerp` snaps **every** field at t < 0.5 — colours included, amended 2026-08-01 (N09-T02,
`06 §3.3`) — so neither a metric nor a colour ever interpolates through a value nobody measured.

## 5. Row heights (`indelible.md §4.4`) and the density that follows

| Row | Height | Note |
|---|---|---|
| Record row | **64** | The standard target. 2 px bottom rule only — rows share edges, no gaps, ledger ruling. |
| Ewe row · pen row | **88** | 32 px tag + 18 px summary; 44 px pen number needs the height. |
| Chart row (one day) | **44** | The only sub-64 row. **Read-only, never a target.** |
| Page header | **44** | Sticky, read-only, never collapses, never parallaxes, never changes height. |
| Bottom band | **152** | Slab 140 + 12 clearance, above the safe-area inset. |

852 − 44 − 152 = 656 ⇒ eight 64 px rows + a 128 px live row. **That arithmetic is a consequence, not
a constant.** The smallest supported device is 375 × 667 (`07-screens.md §21.2`), where the same
subtraction yields five rows. Never hard-code "eight rows" and never assume a row count in a test.

**44 px is below the 60 pt floor, which is legal only because neither the header nor a chart row is a
target.** Put a back button, a sort control or a tap handler in the header and you have created an
illegal target — the sort and back affordances belong in the thumb band.

## 6. Reach — the binding rule (`indelible.md §4.5`)

Measured from the **bottom edge of the viewport**, right-handed default:

- **0 – 320 px, thumb band:** the slab, `INDEX`, the live row, the whole sheet, the ease group, the
  care checks, the event buttons. Everything required to record an event.
- **320 – 560 px, reach band:** filter line, secondary word buttons, rows being read back. Nothing
  here is required.
- **560 px – top, read band:** header, history, chart. Read-only.

**Nothing above 560 px from the bottom is ever required to complete an event.** If a flow needs a
control above that line, the flow is wrong — this is checkable in review with a ruler, and it is what
the reachability assertion proves at 375 × 667 × textScaler 1.3.

The bands are an **absolute distance from the bottom, never a fraction of the height.** On a 667 pt
device the read band is 107 px tall and holds the header and nothing else; do not rescale the bands
to the viewport.

**Two thumb anchors and only two:** the corner slab bottom-right (160 × 140), `INDEX` bottom-left
(96 × 64). Everything between them is one scrolling ruled page.

**Minimum-target audit.** Re-run `indelible.md §4.5`'s audit whenever a target is added or resized.
Smallest target in the app is **64 × 64**; the spec floor is 60 (`06 §6.1`), so 4 pt of headroom is
all you have. Margin cell 68 × 64, ease button 64 × 64, word button min 64 × 64, sheet `CLOSE`
88 × 64, full-width rows 393 × 64 or × 88. Enforce it with `ShedTapTarget` (`06 §6.2`) — a
`GestureDetector` contributes no semantics node and is invisible to both gates.

**Left-handed mirror** (`app_settings.left_handed`, `CONVENTIONS` R40) moves exactly three things:
the slab, the `INDEX` button, and the keypad's bottom row (`07 §14.3` row 8, `06 §12`). **The spine,
the margin cell and the record column do not move.** What changes in the record column is which side
the live row reserves its 160 px of slab clearance on.

## 7. At 200% text scale: rows grow, the grid does not move

The margin stays left, the spine stays vertical, the slab stays in its corner, the page just gets
longer (`indelible.md §3.6`). Per-element behaviour is that section's table — record row 64 → 112,
margin gutter 68 → 96 with the spine moving right and staying continuous, stamp capped at 150%, slab
at 110%, keypad growing in **height only**. The 2 px rule never scales; a rule is a physical mark,
not type. The **one** documented component wrap is the ease group, 5 × 64 → 3 + 2 at 116 × 80, at
≥150%; a second reflow is a defect. Never clamp the text scaler (`type.clamp` is a policy row) and
never `FittedBox`.

## 8. The twelve filters, plus note search

Read `indelible.md §8`'s direction for the screen you are building **before** laying it out; cite it
by screen number, never copy its prose. Screens 3 (Quick Entry) and 7 (Pen Board) carry full prose;
1, 2, 4, 5, 6, 8–12 carry one paragraph each. Structural exceptions to the default 64 px stream:
**1** and **7** are 88 px rows (7 sorted by hours descending); **10** is fourteen 44 px chart rows
under a double rule; **5** prints indented 64 px sub-rows; **4 is not a screen** — it is the live row
expanded in place.

**Note search is the thirteenth route and `indelible.md §8` does not cover it** (critique G6). Its
layout, owned here, derived from §8 Screen 1, §7.14 and §7.16: it is the book **filtered to notes** —
same document, same spine, same 64 px ruled rows each with its own margin time, no new component, no
card, no highlight colour — reached from the same keypad sheet as every other selection via its
`TEXT` toggle, with the header printing the filter including the query. It is a route (`noteSearch`)
but not a spec §9 screen, and it is one of the 14 pumpable variants behind the 252-cell overflow
matrix (`07 §21.2`). Its three distinct empty strings belong to `shed-screens-and-routing`.

## 9. P9 — OPEN. Do not silently pick a side.

`00-README.md` step 19 requires **≥ 16 pt separation** between interactive elements, and
`test/design/tap_target_test.dart` asserts `anyOf(equals(0.0), greaterThanOrEqualTo(16.0))`
(`06 §6.3`). Indelible's geometry separates targets by **8–12 px**: the keypad is
`117 × 3 + 8 × 2 = 367` inside the sheet, so 16 px gaps force the key down to ~112 px and re-cut a
documented geometry contract. The ease group is worse — five 64 px buttons need 320 px, which leaves
~10 px between them even at the full 361 px page width and **does not fit the 301 px record column at
all**.

**Escalate to the owner before** re-spacing the keypad, shrinking a key, or relaxing that assertion.
Note when you escalate that the gate already permits exactly `0.0` — targets that *share an edge*,
which is Indelible's own ruled idiom — but do not adopt that reading unilaterally. Meanwhile use
`gapMin` for every new gap you are free to choose, and leave the keypad and ease geometry as
`indelible.md §7.2` / §4.5 specify.

## Definition of done

- [ ] One document: one spine at x=68, unbroken and unmirrored; margin cell 0–68; record column
      76–377; 16 px gutters. No component interrupts the spine.
- [ ] The live row is a fixed layer above the band, not a stream child, and cannot be scrolled away.
- [ ] Every padding, gap, width and height traces to `indelible.md §4.1`'s scale or §4.4's row-height
      table; `tool/check_policy.dart` reports no `token.magic_size` hit; no new literal in a widget.
- [ ] Every interactive element ≥ 64 × 64 through `ShedTapTarget` with a `semanticLabel`; the margin
      cell is a target; the 44 px header and chart rows have no tap handler.
- [ ] Nothing required to complete an event sits above 560 px from the bottom; the reachability
      assertion passes at 375 × 667 × textScaler 1.3 with the export prompt shown.
- [ ] At textScaler 2.0 the grid is unmoved and only the ease group reflows; the 252-cell overflow
      matrix passes; no row count is hard-coded.
- [ ] `left_handed` moves the slab, `INDEX` and the keypad's bottom row only.
- [ ] `AUTO-CAPTURED`, `DERIVED FROM 3 STROKES` and `DEAD` render at ≥ 18 px in the record column.
- [ ] `flutter analyze --fatal-infos` and `tool/check_policy.dart` pass; P9 is escalated, not decided.

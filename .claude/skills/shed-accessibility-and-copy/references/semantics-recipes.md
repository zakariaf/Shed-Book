# Semantics recipes for the four hand-built widgets

Read this when adding or changing a custom-painted or composite widget. The full code listings and
the reasoning are in `docs/engineering/10-accessibility-and-i18n.md` §3.5–§3.7; this file is the
shape you build to, plus the tally, which no engineering document covers.

- [1. The pen board — a list, never a table](#1-the-pen-board--a-list-never-a-table)
- [2. The keypad](#2-the-keypad)
- [3. The tally](#3-the-tally)
- [4. The spread rows](#4-the-spread-rows)
- [5. Rules common to all four](#5-rules-common-to-all-four)

---

## 1. The pen board — a list, never a table

`SemanticsRole.list` on the board, `SemanticsRole.listItem` on each pen **row**. Pens are an unordered
collection of independent facts; `table` invites row/column navigation that yields nothing.

**There are no tiles and no grid.** Indelible's pen board is twelve ruled 88 pt rows, one per pen, in
one column (`indelible-page-and-screens` §5, `indelible-marks-and-strikes` §7); `06 §11` and
`10 §3.5`/`§5.2`'s pen-*tile* grid is superseded, so nothing here reflows by column count.

```
board  Semantics(role: list, explicitChildNodes: true)
 ├── summary node, FIRST in tree order — "12 pens. 3 ready to turn out. 1 under withdrawal. 2 empty."
 └── per pen  Semantics(container, role: listItem, button: true,
                        attributedLabel: spellOutTag(sentence, row.tag), onTap:, onTapHint:)
                └── ExcludeSemantics(child: <the painted row>)
```

`sentence` is built by `penTileSentence` (`lib/features/pens/widgets/pen_tile_semantics.dart`; the
full function is 10 §3.5). Its ordering is the ordering a shepherd would speak, and **status comes
last and only when true**:

`Pen 4` · `<term> <tag>` *or* `Empty` · `penned 26 hours` · the provenance label when the time was
edited · then one of `Ready — your 24 hour threshold` / `clear on 14 Jul` / `loss recorded` / nothing.

Three things that go wrong here:

- **One node per pen row, not three.** `Pen 4` + `412` + `26h` as separate nodes destroys the sentence.
- **`26h` is never the spoken form.** The visible cell abbreviates; the label says "penned 26 hours".
- **Never ship a status word without its threshold.** `Ready` alone is a clinical claim; `Ready —
  your 24 hour threshold` plays back the user's own rule (spec §12.2). The visible word must still be
  present in the label, or Voice Control cannot match it.

Tree order **is** the traversal order — build a `Column` (or a `ListView` with
`explicitChildNodes: true`) of full-width pen rows, in the board's own sort order. Never a
`GridView`. No `sortKey`, anywhere.

## 2. The keypad

`ShedKeypad` (`lib/core/ui/components/shed_keypad.dart`) is built from tap surfaces, so it is
invisible to assistive tech unless every element below is present (10 §3.6).

| Element | Semantics |
|---|---|
| Digit key | `ShedTapTarget(semanticLabel: '<digit>')` — **the digit alone**, not "Seven key". The glyph `Text` sits inside `ExcludeSemantics` so it is not announced twice |
| Backspace | its own label plus an `onTapHint`. **No key repeat** — repeat needs a held contact |
| The inert decimal key | `onTap: null` ⇒ `enabled: false`, and it **keeps its label**. The grid never re-legends |
| The pad container | `Semantics(container: true, explicitChildNodes: true, label: <"tag entry">)` so a user hears what they landed in |
| The entered buffer | **live region**, `role: SemanticsRole.status`, `attributedLabel` with the digits spelled out |
| The match count | **a second live region**, carrying the closest match — "3 matches, closest 412". A bare count re-announces nothing when 3 matches become a different 3 |
| The confirm bar | labelled with the **outcome** — "Use 412" / "Create 412". Never a bare tick, in pixels or in speech |

The pad may grow with text scale and take more of the screen; the filtered match list gives up rows
first. No `FittedBox`.

## 3. The tally

The tally is the lambing counter: one stroke per lamb, printed as the slab is pressed, and **the
birth type is derived from the strokes** rather than chosen (owner ruling P8). There is no minus
button — a tally that can go down is not a tally — so a mis-pressed slab is corrected by striking
one stroke, never by decrementing.

```
tally  Semantics(container: true, liveRegion: true, role: SemanticsRole.status,
                 label: <"3 lambs, triplet, counted from 3 strokes">)
        └── ExcludeSemantics(child: <the stroke marks>)
strike  one named 60 pt target per stroke — "strike lamb 3" — reachable from the lamb cell
```

Four rules:

- **The count and the derived type are one node, one sentence.** The strokes carry no individual
  meaning to a screen reader; the count does.
- **The derivation is stated in words, in both channels.** The visible line and the label both say
  the type was counted from the strokes. That string is the sole statement of the safety-rule-4
  claim, so it meets the 18 pt floor and is not an exempt 14 px stamp.
- **A struck stroke changes the sentence, not the count of what happened**: "twin, counted from 3
  strokes, 1 struck". The struck stroke stays in the tree and stays legible.
- **A declared type that contradicts the strokes is announced as a disagreement**, never
  reconciled. The label names both figures; the app adjusts neither.

## 4. The spread rows

Indelible renders the lambing spread as fourteen ruled rows of blocks, not a chart component — so
the counts are already text, and that discharges the "reasonably complete text alternative" Apple
requires of a data visualisation. Three obligations remain (10 §3.7):

1. **A visible summary sentence** — real text under the block, not a tooltip and not
   screen-reader-only, because the 3am user without glasses cannot read a 30-row spread either. It
   is one ARB message with eight placeholders, every date arriving **pre-formatted** as `d MMM` and
   every count that can be 1 an ICU plural. It states facts and never a judgement.
2. **This is a second line, not a replacement.** `07-screens.md` §12.3's cycle line ("32 of 48 ewes
   lambed in the first 17 days") also ships. Both are visible; neither replaces the other.
3. **One node per day, including days with none** — "21 Mar, 19 lambs", "18 Mar, no lambs". Never
   "bar 7 of 20". The gaps *are* the information.

`SemanticsRole.table` / `row` / `cell` with a `columnHeader` per column is correct **here and
nowhere else** in the app. If the spread ever becomes a `CustomPaint`, it must expose
`semanticsBuilder` returning one `CustomPainterSemantics` per day with a stable `ValueKey`, and
override `shouldRebuildSemantics`; a painter has no `BuildContext`, so pre-localised strings are
passed in by the widget and never fetched inside `paint`.

## 5. Rules common to all four

- Wrap, do not merge: `Semantics(label:) + ExcludeSemantics(child:)`. `MergeSemantics` joins child
  labels with newlines and takes the first handler.
- Tree order is traversal order. No `sortKey`.
- Spell out the **tag range only**, via `spellOutTag` through `attributedLabel:`.
- The user's noun comes from `terminologyProvider`; never hard-code "ewe".
- Every one of these widgets is on the 14-variant sweep. `shed-testing` owns the assertions.

---
name: indelible-marks-and-strikes
description: >-
  Rule 1 and every mark — nothing is removed, only struck. Use for any status, warning, threshold,
  unset or derived value, the tally, the birth type, any count or chart, and whenever a delete,
  hide, mute or edit is designed. Do NOT use for its mechanism (shed-safety-rules).
---

# Marks and strikes

Indelible is a ship's deck log: **never erase, never white out — rule one line through the error so
it stays legible, write the correction beside it, stamp it with the time.** Everything below follows
from that one sentence. Source of record: `docs/design/indelible.md` §1.1–1.2, §2.7, §4.2, §5.1,
§6, §7.6/7.7/7.11, §8, §9. Cite it by section; never re-transcribe its tables.

## 0. Rule 1 — nothing is removed, only struck. Read this before designing anything.

If a proposal makes information disappear from the page, it is wrong. There is no delete, no
archive, no hide, no soft-delete filter, no swipe-away, no collapse-on-complete, no fade-out.
**Undo is a strike. Mute is a strike. Un-ticking is a strike over the tick. Correcting a time prints
both times. Fostering prints the old rearing dam struck and the new one beside it.**

The strike, exactly:

- A **3px** `--madder-ink` line across the record column at 50% row height, `transform-origin: left`,
  drawn left-to-right over **180 ms, `linear`** (`--motion-strike`, §5.1). This is **the only
  animation in the app with a direction**, and the only linear curve — a pen crossing a page at
  constant speed. Here the animation *is* the meaning. Under reduce-motion it is **0 ms and already
  full width**: never skipped, never a fade.
- `STRUCK 03:41` prints in the 68px margin cell as an **unboxed** stamp. 24-hour `HH:mm`, always
  (CONVENTIONS §5.4). Two haptic ticks 120 ms apart — a different rhythm from a commit's 60 ms pair.
- **The row does not move, collapse, fade, reorder or disappear.** It stays exactly where it was,
  tonight, next year, in the ewe's history, in every filtered list, and in the CSV. Text drops to
  `--ink-low`, still above 4.5:1 — struck is dimmed, never illegible.
- In red-shift the strike **doubles** — two 2px lines, 3px gap — because the hue channel is gone.
- Every CSV carries `struck` and `struck_at`, and **every struck row is exported and marked**
  (§ screen 11). An export that drops strikes undoes the only thing this app is for.

> **P1 is UNRULED and it blocks the storage half. Do not improvise around it.** `struck` / `struck_at`
> on every table is schema-irreversible and the owner has not ruled it, so **`shed-drift-schema` may
> not add the columns**, nor a boolean `deleted`, a `DELETE` path or an "active rows" view as a
> stand-in. Everything above is the *design* rule — the shape a strike takes on the page and in an
> export — and `shed-export-and-restore` builds the export side against those two names. **If a task
> needs a strike, an undo or a mute to persist, stop and say P1 blocks it**; do not design a schema
> from this skill.

## 1. Not this skill

Do NOT use this skill for:

- **§12.4's mechanism** — `Warning` / `Reviewed<T>`, the absent `warnings` column, the ladder:
  `shed-safety-rules`. This skill owns only what the shepherd *sees*; do not restate the mechanism.
- **Undo's per-verb semantics, its labels (`Correct this`, `Void this`) and its window**:
  `shed-screens-and-routing`. This skill owns the affordance's shape, not its clock.
- **Numeric typography, ink values, contrast ratios, the token block**: `indelible-design-system`.
  This skill owns rule *weights* and mark *geometry* only.
- **The page, spine, band, live row and per-screen layout**: `indelible-page-and-screens`.

## 2. The six marks. Six is the budget.

**No new mark may be added without deleting one** (§6.3). There is no icon set: every action is a
word — `TREAT` `MOVE PEN` `STRIKE` `FOSTER` `CHANGE TYPE`. An `Icons.*` reference anywhere under
`lib/` is a defect; if you need a gate row, add one `ui.material_icon` row to the single
`tool/check_policy.dart` (CONVENTIONS §4.7 namespaces) — never a second script.

| Mark | Form | Means |
|---|---|---|
| `†` dagger | record-face glyph, 24px, margin cell | *look at this* — edited time, pen over threshold, withdrawal last day. **Always beside a word.** |
| `‡` double dagger | record-face glyph, 24px, margin | struck **and** queried. Rare by design. |
| `?` query mark | record-face glyph, 28px, margin | the record contradicts itself and the app will not fix it |
| tally stroke | inline SVG filled rect, `8 × 30px`, 3px gap | one lamb, one birth, one block |
| strike line | 3px rule, `--madder-ink` | §0 |
| `⌫` delete key | inline SVG, 2px stroke, 28 × 28 box | **a keypad backspace only** |

Drawn-mark rules: 2px stroke, `stroke-linecap: butt`, `stroke-linejoin: miter` (nothing in a printed
book has a rounded end), boxes 24 × 24 or 28 × 28 only, `currentColor` always so marks dim with a
struck row, no fills except tally strokes. **`⌫` deletes a digit you are typing; it never deletes a
record.** The two names collide, the concepts do not.

## 3. The five-bar gate — inline, because you cannot progressive-disclose a surprise

The fifth stroke of every group is **drawn diagonally across the previous four**. A shepherd
counting to fourteen lambs must not have to count to fourteen.

```svg
<svg width="132" height="30" viewBox="0 0 132 30" fill="none" aria-label="5 lambs">
  <rect x="0"  y="0" width="8" height="30" fill="currentColor"/>
  <rect x="11" y="0" width="8" height="30" fill="currentColor"/>
  <rect x="22" y="0" width="8" height="30" fill="currentColor"/>
  <rect x="33" y="0" width="8" height="30" fill="currentColor"/>
  <path d="M-3 27 L46 3" stroke="currentColor" stroke-width="4" stroke-linecap="butt"/>
</svg>
```

Groups of four plus a crossing bar, repeating. In Flutter this is a `CustomPainter` or laid
`Container`s taking their ink from `context.tokens` — never `Text('||||')`, never an icon font,
never a digit standing in for the strokes. The tally column is 132px fixed, right-aligned.

**A struck lamb keeps its rect** and takes a 3px `--madder-ink` line through that one stroke; the
count re-prints as `TWIN (COUNTED, 1 STRUCK)`. **There is no minus button on a tally** — a tally
that can go down is not a tally. A mis-pressed slab opens the lamb cell's chooser:
`LAMB 3 — STRIKE THIS LAMB`.

## 4. Birth type is derived and labelled. There is no chooser. (ruling P8)

Nobody ever picks "triplet" from a list. Press the slab once per lamb as each arrives; the strokes
print; the type re-prints beneath them as `TRIPLET (COUNTED)`, `COUNTED` an unboxed stamp. That is
what turns safety rule §12.4 from a validation routine into structure.

- **`06 §12`'s `ShedChoiceRow` for birth type is superseded.** It survives only where a genuine
  choice exists with no derivable answer — **lambing ease 1–5** is the case that keeps it. Any
  birth-type selector, segmented control, dropdown or stepper is a defect.
- `CHANGE TYPE` is one word-button, reachable only from the type cell or from a `?`, for the one
  legitimate case: writing up at 7am when you never pressed the slab. It writes
  `Lambings.declaredBirthType` (nullable — CONVENTIONS R6, R46), and **a declared type that
  contradicts the strokes prints a `?` and adjusts nothing** — not the strokes, not the type.

**The app never picks.** Tapping the `?` (the whole 68 × 64 margin cell is the target) offers
**exactly two options and never a third**: `CHANGE THE BIRTH TYPE` or `LEAVE IT — TWO IS RIGHT`.
Choosing the second prints `QUERIED · LEFT AS ENTERED 03:47` **and the query mark stays.** A 2px
madder underline sits under the offending cell. No "resolve", no auto-fix, no dismiss.

## 5. Rules, weights and what each one means

Every rule is **2px, never 1px.** A hairline shimmers, aliases or vanishes on a mid-range Android at
low brightness, and here the ruling is load-bearing structure. `--rule-w` never scales with text — a
rule is a physical mark, not type (§3.6).

| Token | Weight | Meaning it carries |
|---|---|---|
| `--rule-w` | 2px | every horizontal rule, every button border, the spine |
| `--rule-strike-w` | **3px** | the strike. Heavier than a rule on purpose, so it can never be read as a row boundary |
| `--rule-double-gap` | 3px | the **doubled rule** — a total, a boundary, a threshold crossed. Readable in peripheral vision from across the shed |
| `--rule-dot` | `2px 6px` | **the value was never entered.** Never solid, so an empty field can never be confused with an entered one |

A dotted rule always carries `— NOT RECORDED` (and `· SKIPPABLE` where it is). **Never a blank line,
never `0`, never `—` alone**: a blank reads as missing data, a dotted rule reads as *nothing
happened*, and they are different facts. A zero day in the chart is a dotted rule with `0` printed.

## 6. Stamps: boxed is the animal, unboxed is the record

`ShedStatusBadge` (06 §12) is a **stamp set in words, not an icon-plus-word** — there is no icon set
to draw from. All-caps control face, 0.14em tracking, `--ink-full`, 24px tall, 8px inline padding.

- **Boxed** (2px border, 2px radius) = *a state of the animal*: `PENNED` `LAMBED` `BARREN`
  `WITHDRAWAL` `TO LAMB` `DEAD` `ALIVE` `PET LAMB` `OVER` `PERMANENT` `YOUR ENTRY`.
- **Unboxed** = *a note about the record itself*: `AUTO` `EDITED` `DERIVED` `COUNTED` `STRUCK`
  `MUTED` `QUERIED` `NOT RECORDED`. `STRUCK` and `QUERIED` are the only madder stamps.

You must be able to tell from ten feet whether a stamp is talking about the sheep or the writing.

**Three stamps are not stamps and must meet the 18px body floor** — the mockup's 14px scale is a
known defect; encode the corrected rule. `DERIVED FROM 3 STROKES` (the sole statement of the §12.4
claim on its line), `DEAD` (the sole carrier of the fact on the lamb row), and `AUTO-CAPTURED` (the
sole §12.5 provenance label — `shed-safety-rules` owns the rest of it). The 14px exemption holds
only while a stamp is *never the sole carrier of its meaning on its line*. Apply that test to every
new stamp before you size it.

## 7. Every state carries at least two non-colour channels

Colour may reinforce; it may never be the only channel (§1.2 Rule 3, §2.7;
`docs/engineering/10-accessibility-and-i18n.md` §5). The gate is not a discussion: **turn on the OS
grayscale filter and read the screen.** If you cannot, it fails. The full state table is §2.7 —
read it, do not copy it. Three rows are always got wrong:

- **`DEAD` is a word, in full ink, with no colour, ever.** No red, no hatch fill, no greyed-out card,
  and the lamb is never removed from the litter count.
- **Over threshold** is four channels — `OVER`, a `†`, a **doubled rule**, and the hours lifting from
  `--ink-mid` to `--ink-full`. Delete the colour and three remain.
- **Unset** is a dotted rule plus `— NOT RECORDED`, in the pixels the value would have occupied.

`06 §11` and `10 §5.2`'s pen-tile encodings — thick left bar, filled corner triangle, circle-slash
badge, diagonal hatch — are **superseded**. There are no tiles; the pen board is ruled rows, and its
channels are word + dagger + doubled rule + ink density.

## 8. Undo is a time-boxed strike affordance in the row's own margin (ruling P2)

There is no SnackBar anywhere, so undo can no longer be defined as "until the SnackBar is dismissed".
The affordance lives **in the committed row's own margin cell** — not a floating bar, not an overlay,
nothing to dismiss, nothing that can scroll away from its row. **State the window in seconds**, never
in terms of a widget's lifetime; the value and the per-verb labels belong to
`shed-screens-and-routing`. Taking it back **strikes**; it never erases. The receipt is the committed
row itself, in ink, one line above the one being written.

## 9. Edits, mutes, checks, and the only two honest deletes

- **Edited time prints both times.** The margin re-prints as two lines — `07:02 †edited` over
  `event 03:20 as entered` — and the `AUTO` stamp becomes `EDITED`. The original is never
  overwritten, in the record or the export.
- **`MUTE` on a reminder is a strike**: `MUTED 03:44` and a line through the row, which stays in the
  list — a muted reminder is a decision you made and may want to see at 6am. **`TURN OUT` re-prints
  in place** as `TURNED OUT 04:12` and stays on the board for the night.
- **Un-ticking a care check is a strike**: `D̶O̶N̶E̶ ̶0̶3̶:̶2̶4̶ · UNDONE 03:31`. Rule 1 applies to a
  checkbox exactly as it applies to a lambing.
- **Exactly two honest deletes exist**, both in Settings under a double rule, each requiring the
  season year or the word `EVERYTHING` typed into a field, each printed above the sentence
  `THIS IS THE ONLY DELETE IN SHED BOOK. IT IS NOT A STRIKE. THE ROWS DO NOT STAY.` These are the
  only places the word *delete* appears in the product. Everywhere else the word is `STRIKE`.

## 10. Counts and charts: no chart library, ever

The lamb tally, the withdrawal day tally and the lambing spread are **the same mark at three
scales**, so a shepherd who learns one has learned all three.

- **Withdrawal day tally** (§7.6): one `2px × 12px` `--ink-mid` mark per remaining day, 4px gaps,
  capped at 28 with `+n` after. Last day adds `†`, one mark, `LAST DAY` and a doubled rule. Cleared
  replaces the tally with a solid 2px rule the width the tally was, and **the row stays in the
  medicine book forever**.
- **Lambing spread** (§7.11): fourteen **44px** ruled rows, one `8 × 24px` `--ink-full` block per
  birth, 3px gaps, from x=76, closed by a double rule and `67 EWES LAMBED · 14 NIGHTS`. **One block
  = one birth, literally, at every zoom level** — no axis because there is no scaling, therefore no
  pinch-zoom. No gridline, legend, tooltip, colour or animation: it draws at full length in the
  first painted frame. The year comparison is **a second set of fourteen rows** below a double rule,
  headed `2025 · 172%` — never overlaid, never a second colour.
- **Every chart package is banned** — `fl_chart`, `syncfusion_*`, `charts_flutter`, `graphic`, any
  successor. `ShedSpreadChart` is a hand-rolled `CustomPainter` with a `semanticsBuilder` (06 §12).
  A new dependency needs a `dep.*` row in the one gate, not an exception.
- **The 44px chart row is the only sub-64 row in the system** because it is read-only. A bar is
  never a tap target; do not wrap one in `ShedTapTarget` to satisfy a tap-target gate.

## Gotchas

- **`TextDecoration.lineThrough` is not the strike.** It strikes only the text extent, cannot be
  3px, cannot span the record column, and cannot animate left-to-right. Draw the strike as its own
  painted rule with a `scaleX` transform from `transform-origin: left`.
- **Never filter struck rows out of a query.** `WHERE struck IS NULL` is the reflex and it is the
  defect — every list, every ewe history, every count's denominator and every export includes them,
  marked.
- **Numbers never animate.** No count-up, no odometer, no ticking tally. A number mid-animation is a
  number you can misread, and this app is a record of numbers.
- **Rows never reorder, slide or crossfade.** A filter change re-prints the page instantly; a
  crossfade at 3am reads as lag and lag reads as "it didn't save".
- **The `?` is not an error state.** It never blocks a write, never colours the row, never appears in
  a validation summary. It is a mark in the margin and the row is saved.
- **Striking a lamb does not decrement anything.** `TWIN (COUNTED, 1 STRUCK)` still shows three
  strokes, one of them ruled through.
- **A stamp under 18px must survive the sole-carrier test**, and `--t-stamp` caps at 150% text scale
  while everything else scales linearly — a 28px tracked stamp is wider than the margin cell.

## Definition of done

- [ ] Nothing this change adds can make a row, a stroke, a tick or a reminder leave the page. Every
      removal is a strike with a `STRUCK HH:mm` margin stamp.
- [ ] The strike is a 3px painted rule drawn left-to-right in 180 ms `linear`, 0 ms and full-width
      under reduce-motion. No `lineThrough`, no fade, no collapse.
- [ ] No new mark was added; six still. No `Icons.*`, no icon font, no chart package.
- [ ] No birth-type chooser exists anywhere; the type prints as `<TYPE> (COUNTED)` from the strokes,
      and a contradicting declared type prints `?` and adjusts nothing.
- [ ] Every new state has two non-colour channels and reads under the OS grayscale filter.
- [ ] Every unset value prints a dotted rule and `— NOT RECORDED` — never blank, never `0`.
- [ ] Every new stamp is boxed for an animal state, unboxed for a record note, and meets 18px unless
      it passes the sole-carrier test.
- [ ] Undo renders in the row's own margin, with its window stated in seconds.
- [ ] Struck rows appear in every list and in the CSV with `struck` / `struck_at` set — or, while P1
      is unruled, the task was stopped and P1 named rather than a schema invented.
- [ ] `dart run tool/check_policy.dart` is clean; any new rule is a row in that one gate.

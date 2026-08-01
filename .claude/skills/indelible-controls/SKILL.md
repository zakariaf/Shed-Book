---
name: indelible-controls
description: >-
  Every pressable thing — the slab, the word button and the ease group. Use for any button, input,
  field, form, picker, chooser, keypad, slider, stepper, sheet or toggle. Do NOT use for rows or
  marks (indelible-marks-and-strikes).
---

# Controls — every pressable thing in the book

There are **seven pressable forms and one overlay**, and no eighth. Two act (corner slab, word button), one
navigates (`INDEX`), four capture a value (keypad key, ease group, stepper, ruled field) plus the check
control, which captures a *time*. What you are about to invent is one of the seven.

Authorities: `docs/design/indelible.md` §7 (inventory), §5.1/§5.4 (press motion, haptics), §4.5 (target
audit); `docs/engineering/06-design-system.md` §8 (keypad) and §12; `docs/engineering/CONVENTIONS.md` §2.11 +
R70 for class names and files. CONVENTIONS is BINDING — read §2.11 before naming a widget and 06 §8 before
touching `ShedKeypad`.

**Do NOT use this skill for:** rows, tallies, stamps, daggers, query marks or the strike line —
**indelible-marks-and-strikes**. The page grid, the thumb bands, which screen a control sits on —
**indelible-page-and-screens**. The save receipt, upgrade row, empty and error states —
**indelible-states-and-feedback**.

## The four laws that hold for every control

1. **A press is a fill change and nothing else.** `--motion-press` 40ms, `--slab` → `--slab-pressed` for
   buttons, `--row-pressed` in the stream. **No scale, no lift, no ripple, no shadow** (§5.1) — a target that
   shrinks under a cold thumb is a target you miss. It survives `prefers-reduced-motion` unchanged (§5.3): it
   is the only visual proof a gloved press registered.
2. **Almost nothing is ever disabled.** Keypad key, check control, stepper, text field and countdown all state
   *"Disabled — never"* (§7.2, §7.8, §7.10, §7.12): a dead key under a cold thumb is indistinguishable from a
   missed tap. A control that cannot act keeps its full target and **does something useful** (see the slab),
   or prints the reason beside it in `--ink-low` under a dotted underline (§7.13) — never a greyed-out no-op.
3. **One discrete tap, always.** No drag, swipe, long-press, pinch, hold-to-repeat or `Slider`; the ban table
   with a replacement for each is 06 §7.
4. **Every target is a `ShedTapTarget`** (`lib/core/ui/components/shed_tap_target.dart`) with a required
   `semanticLabel` and `Semantics(onTap:)` — the only sanctioned tap surface (CONVENTIONS §2.11, 06 §6.2).
   Colour and metrics come from `context.tokens`; `colorScheme` is banned under `lib/features/` and
   `lib/core/ui/components/`.

## How each form is painted

At 100% text scale. No radius but the 2px on buttons (§4.2); no cards, chips, shadows, elevation.

| Form | Size | Type | Ground |
|---|---|---|---|
| Corner slab | 160 × 140, bottom-right, 16px from the edge, 12px above the safe area | `--t-slab` 26px control caps 0.06em | `--slab`, 2px `--ink-mid` border, 2px radius |
| Word button | min 64 × 64, 12px inline padding, min-width 64 | `--t-ctl` 20px, `--t-ctl-lg` 22px primary | filled → `--slab` + 2px `--ink-mid`; **in-stream → no fill, no border, a 2px `--rule` underline the width of the word** |
| Keypad key | 117 × 84, 3 × 4, 8px gaps | digit in the **record** face, `--t-tag` 32px tabular | `--slab`, 2px `--rule` |
| Ease button | 64 × 64 × 5, 8px gaps | record face, 32px tabular | `--page` + 2px `--rule`; selected → `--slab` + 2px `--ink-full` |
| Stepper | `[−] 64×64` · `[value] 88×64` · `[+] 64×64` = 216 | value record face 32px; signs control face 32px | shared 2px `--rule` borders |
| Text field | 64px line, record-column width | label **above**, control caps `--t-ctl-sm` 19px; value **on** the rule, record face 20px | rule below — dotted unset, solid `--ink-full` focused |
| Check control | 393 × 64 ruled line, right half a 64 × 64 target | label control face `--t-ctl` 20px | underline dotted unset, solid `--ink-full` done |

## The two action forms

**The corner slab (§7.1).** Its label is a verb set by the page — `+ LAMB`, `+ EVENT`, `+ EWE`, `+ DOSE`,
`+ NOTE`, `MOVE`, or absent on Season/Export/Settings/Reminders where only `INDEX` is pinned. Read §7.1's
table; never guess a verb. Three of its five states are the point:

- **Armed** (a tag has landed, next press writes a lamb) — 2px `--ink-full` border, plus a 3px × 24px
  `--madder-rule` tick at the top-left corner.
- **Disabled** (no subject loaded) — reads `TAG FIRST` in `--ink-low` behind a **dashed** border, at the full
  160 × 140, and **pressing it opens the tag sheet** rather than doing nothing.
- **Warning** (the press would contradict a declared birth type) — **the slab never refuses a press.** It
  fires, prints the stroke, prints a `?` in the margin, and never blocks, shakes or opens a dialog. Safety
  rule §12.4 built as geometry.

**The word button (§7.13).** Filled for a primary; in-stream (underline only) inside the document; selected as
a filter means an `--ink-full` underline and label while siblings sit at `--ink-mid`; **destructive means
label and underline in `--madder-ink` — never a filled red button**, which is a thing you press by accident.
`STRIKE` is the canonical case; indelible-marks-and-strikes owns it.

## The controls that capture a value

**The keypad (§7.2, 06 §8).** `ShedKeypad`, `lib/core/ui/components/shed_keypad.dart` — R70:
`features/quick_entry/widgets/big_keypad.dart` does not exist; Lambing Entry, Treatments and Settings share
this one pad. **No key is ever disabled.** Haptic is `HapticFeedback.selectionClick()` fired **on down, before
the state change** (06 §8), so the finger feels the key and not the result. No key repeat on backspace — a
visible Clear instead, and clear-all is never a long press. No OCR key and no microphone key (both cut from
v1). Digits sit in the **record** face — the one documented breach of the two-voice rule (§3.5) — so the digit
you press and the digit that prints are the same shape. **Selection is one tap**: pressing a recents or match
line *is* the selection, never a press then a confirm; `ShedConfirmBar` exists only for the create case,
labelled with the outcome (`Create 412`), never a bare tick (06 §12).

**The ease group (§7.9).** Five 64 × 64 buttons. Selected = `--slab` fill, 2px `--ink-full` border, **plus a
2px `--madder-rule` underline the full 64px width**, plus the description to the right in the control voice
(`EASE 3 · SOME ASSISTANCE`). Unset = five unselected buttons under one dotted rule labelled
`EASE — NOT RECORDED · SKIPPABLE`.

> **RULING P8 — there is no birth-type chooser anywhere in the product.** Birth type is **derived from the
> tally strokes** and printed `TRIPLET (COUNTED)`, `COUNTED` as an unboxed stamp; nobody ever chooses
> "triplet" from a list. `ShedChoiceRow` (06 §12) survives **only** where a genuine choice exists with no
> derivable answer, and lambing ease 1–5 is the case that keeps it — 06 §12's "birth type" entry is struck.
> A `CHANGE TYPE` word button exists for the 7am write-up, reachable only from the type cell or a query
> mark; a declared type contradicting the strokes prints a `?` in the margin, **adjusts nothing**, and the
> app never picks. Before building any segmented control, prove the answer is not derivable.

**The stepper (§7.8).** Replaces every slider in the app, for birth weight and pet-lamb feed count; step 0.1
kg. **No repeat-on-hold** — one press, one step. At the floor `−` drops to `--ink-low` and does not fire: no
error, no shake, no toast. Unset prints `—·—` over a dotted rule with `NOT RECORDED · SKIPPABLE` above. No
warning state — there is no such thing as an implausible birth weight. **Tapping the value opens the keypad
sheet**, which is how it coexists with R70 (`ShedKeypad` is the only number route).

**The text field (§7.12).** `ShedFieldRow`, label above the value so it survives 200% text. **There is never
placeholder text inside a field, system-wide** — in the dark a grey placeholder is indistinguishable from an
entered value, and in the withdrawal-days field a placeholder number is a food-chain risk. Hints live in the
label, above the line. Unset is a **dotted** rule and no glyph, a visible gap and never a hidden field;
focused turns the rule solid `--ink-full` with a 2px caret and nothing else. The withdrawal case is safety
rule §12.1 as a component, copied exactly: label `DAYS — READ FROM THE BOTTLE. YOUR ENTRY.` with `YOUR ENTRY`
**boxed**, and **no default, no last-value autofill, no placeholder, no suggestion, no unit pre-fill**.
`REPEAT LAST TREATMENT` copies everything except the days and prints `DAYS NOT COPIED — READ THE BOTTLE`; the
arithmetic belongs to **shed-withdrawal**.

**The check control (§7.10).** Colostrum, navel, tubed, warmed. **There is no checkbox glyph** — ticking
`colostrum given` at 03:24 records that you ticked it at 03:24, so done is the label lifting to `--ink-full`
over a solid underline with `DONE 03:24` in the right cell. Undone is not an erasure: the stamp is struck and
`UNDONE 03:31` prints beside it.

## The bottom sheet — the only overlay

`ShedBottomSheet` (§7.14). Rises 160ms, translate-Y only, no fade, no blur. `--sheet` ground, **0 radius**,
separated from the page by a **2px `--ink-full` top rule instead of a shadow**; 60% viewport for the keypad,
content height for a chooser. The spine continues *behind* it.

- **Exactly three contents, ever**: the tag keypad + recents; the index; an inline cell chooser. A fourth kind
  of sheet is a design error, not a new feature.
- **No drag handle** — a handle advertises a gesture the app does not support. Closing is an 88 × 64 `CLOSE`
  word button, top-right. Flutter's defaults are all permissive, so **type all three on every sheet**:
  `showDragHandle: false`, `enableDrag: false`, `isDismissible: false` (06 §7, §12).
- Recents are **six full-width 64px ruled lines, not chips** — 06 §12 calls `ShedRecentsStrip` "6 chips", and
  a chip is a container with a radius, which this system does not have. The name stays, the form is ruled
  lines (§7.15), height fixed at frame 1 so nothing shifts.
- `INDEX` (§7.17) is a 96 × 64 filled word button pinned bottom-left; it opens eight 64px ruled lines, each
  the book under a different filter. No tab bar, no rail, no back button — choosing a filter is always one
  press *deeper*.

## Capture surfaces — photo and voice note

`indelible.md` §7 has **no image and no audio component** (gap G5, conflict P12). These rules are derived from
the system's own laws — apply them, and do not let a card creep in.

- **A captured photo is a ruled cell**, record-column width, image inside, time in the margin. **Never a card,
  never a rounded thumbnail, never a grid.** `ShedPhoto` (`lib/core/ui/components/shed_photo.dart`) is the
  **only** `ColorFiltered` in the app — a global one is banned (06 §4.7) — and its tint is null in `night` and
  both high-contrast palettes. The viewer keeps a permanent **"Show in full colour"** control: a shepherd
  looking at a prolapse needs the colour, and the app never interprets what it shows.
- Flow: `CameraService.pick(CaptureSource)` → `MediaStore` compresses and rehomes → `NoteRepository` inserts
  the `media_assets` row (R47, 08 §3.1); `pick` returns `({String path, bool recovered})?`. When `recovered`
  is true, print an ≥18px line saying so beside the cell with the normal Remove control — **never a dialog**;
  attaching a recovered photo silently attributes one record's photo to another.
- **The voice note is a tap-to-start / tap-to-stop toggle**, ≥64 × 64, with an unmissable label change;
  press-and-hold is banned. The level meter comes from `VoiceRecorder.levelDbfs`, drawn in the tally's own
  blocks, and elapsed seconds print as a tabular figure — **no ring, no arc, no progress bar**, those forms do
  not exist here (§7.6). A note whose `byte_size` is still `0` renders **"Recording interrupted"** and offers
  Delete, not Play. Gateway internals, including `kVoiceNoteMaxSeconds` in `lib/data/media_limits.dart`,
  belong to **shed-platform-gateways**.

## Gotchas

- **Controls do print 14px stamps** (`DONE 03:24`, `YOUR ENTRY`) — legal only while all three §3.4
  exemption conditions hold: ≤12 characters, caps at 0.14em, `--ink-full`, never the sole carrier of its
  meaning. The three labels that **fail** the third condition and must meet the 18px floor are `DEAD`,
  `AUTO-CAPTURED` and `DERIVED FROM 3 STROKES` (**indelible-marks-and-strikes**). Apply the test to
  every new stamp *before* you size it.
- **`NOT RECORDED · SKIPPABLE` fails the first condition, not the third** — it is 23 characters against
  §3.4's ≤12, and §7.8/§7.9 print it at `--t-stamp` anyway. That is a discrepancy inside `indelible.md`,
  not a licence: it survives at 14px only because the dotted rule beside it carries the same fact
  (**indelible-states-and-feedback** §4). **Do not cite it as precedent for a new long stamp** — a
  stamp over 12 characters is a label and takes an ≥18px role.
- **There is no Save button on any screen**, so no control is ever a submit; every cell writes on press, and a
  "Done" in an app bar pops the route and commits nothing (**shed-write-path**).
- **No loading state anywhere** (decision #71) — no spinner, skeleton or shimmer on any control.
- Left-handed mode mirrors the slab, `INDEX` and the keypad's bottom row only. **The spine never moves.** It
  is a Settings switch, never a gesture.
- The Warning state exists on the slab and nowhere else here — a control that argues with the shepherd is
  wrong; print a mark and move on.

## Open conflict — do not silently pick

Indelible §7.2 puts `NEW TAG` on the keypad's **bottom-right** key; 06 §8 says bottom-right is **always** the
decimal key, inert when integer-only, and that the grid never re-legends — and weights need that decimal
(decision #57). Indelible §8 Screen 3 resolves it: create-on-the-fly is **the last printed line of the match
list** (`no such tag — write 12 into the book`), never a modal, never a confirm. Build that, keep bottom-right
as the decimal, and raise §7.2 with the owner.

## Banned outright

`Slider` · `RangeSlider` · `CupertinoPicker` · `Switch` · `Checkbox` · any `hintText` or placeholder in a
field · a birth-type chooser · a drag handle · `enableDrag: true` · `isDismissible: true` · a second overlay
of any kind (dialog, modal, interstitial, popup menu, `Tooltip`) · a filled red destructive button · a
greyed-out no-op · hold-to-repeat · a spinner · a card, chip, pill or rounded container · scale, ripple or
shadow on press · `showSnackBar(` anywhere, including `feedback.dart`.

## Definition of done

- [ ] Every pressable thing is one of the seven forms at the size in the table, no radius but the 2px on
      buttons, and press feedback is a fill change only, 40ms, surviving reduce-motion.
- [ ] Every one is a `ShedTapTarget` with a `semanticLabel`; every enabled one exposes `SemanticsAction.tap`.
- [ ] No keypad key, check control, stepper or field is disabled; the slab's disabled state is a full-size
      target reading `TAG FIRST` that opens the tag sheet, and the slab refuses no press.
- [ ] `grep` finds no `Slider`, no `hintText`, no `placeholder` and no birth-type chooser under `lib/`; the
      stepper has no repeat-on-hold and its value cell opens `ShedKeypad`.
- [ ] The withdrawal days field ships empty behind the `YOUR ENTRY` boxed stamp, with no default.
- [ ] Every bottom sheet sets `showDragHandle: false`, `enableDrag: false`, `isDismissible: false`, closes
      through the 88 × 64 `CLOSE` button, and carries one of the three permitted contents; recents render as
      six 64px ruled lines and one press completes the selection.
- [ ] A photo renders in a ruled cell through `ShedPhoto` with a permanent "Show in full colour" control, and
      a recovered photo says so in a printed line, not a dialog; the voice note is a tap/tap toggle with a
      level meter and no ring, and a zero-byte note offers Delete, not Play.

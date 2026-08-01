# Indelible — design system specification

**Shed Book direction 1 of 3.** Offline lambing notebook, iOS + Android, dark-first.
Version 1.0 · Written against `shed-book-spec.md` v1.0.

---

## 1. Thesis and principles

### 1.1 The thesis

A shed at 3am is not a database. It is a night that will be impossible to reconstruct in the morning.

The discipline for exactly that problem is four hundred years old and it is identical everywhere it matters — a ship's deck log, a pilot's logbook, a nurse's drug chart, every GxP-regulated record on earth. The rule is absolute: **never erase, never white out. Strike one line through the error so it stays legible, write the correction beside it, initial it and date it.** That is not bureaucracy. It is a design pattern for a record kept by an exhausted human at 4am, and it is precisely what the product spec's safety rule 4 already demands ("never silently correct a user's entry").

So Shed Book is a **book of nights**. One ruled page per night. One row per event. A madder-red margin rule down the left carrying the auto-captured time. Nothing needs a Save button, because the row commits at the first keystroke and you can *see* it, in ink, one line above the one you are writing — which removes the real 3am failure mode. The real failure mode is not slowness. It is doubt: *did that go in?*

Two consequences follow, and they are the whole product.

**There is no delete.** The delete button rules a single madder line through the entry and prints `STRUCK 03:41` in the margin. The struck row stays on the page, in the ewe's history, and in the CSV export, forever. Swipe-to-delete is not merely banned by the spec here — the concept of erasure does not exist in the product. The only true deletion in Shed Book is "delete a season" and "delete everything" in Settings, and those two screens say out loud that they are not strikes.

**Nobody ever chooses "triplet".** A lambing is a forty-minute window, not a form-filling event. So the row stays open. You press one enormous corner slab once per lamb as each one arrives, like a tally counter, and the strokes print in the lamb column. The birth type is *derived from the strokes* and labelled `TRIPLET (COUNTED)`. Safety rule 4 stops being a validation routine and becomes structure.

### 1.2 The four rules that resolve any future disagreement

When two people on this team disagree about a design decision, these settle it, in order.

**Rule 1 — Nothing is ever removed, only struck.**
If a proposal makes information disappear from the page, it is wrong. Undo is a strike. Mute is a strike. Un-ticking a checkbox is a strike over the tick, not the absence of a tick. Correcting a time prints both times. Fostering a lamb prints the old rearing dam struck and the new one beside it. If you cannot see what was there before, this is not Indelible.

**Rule 2 — The record is set in the book face; the controls are set in the machine face.**
Serif means *it happened*. Sans means *it is a thing you can press*. There is exactly one documented exception (the keypad digits, §3.5). Any new component must declare which voice it is in before it gets a size. If a component wants to be both, it is two components.

**Rule 3 — Meaning is carried by form first, hue never alone.**
A strike is a line through a row. Over-threshold is a dagger, a word, and a doubled rule. Dead is the word `DEAD`. Colour is permitted to *reinforce* — it may never be the only channel. There is one hue in this app and it is allowed three jobs. If a proposal needs a fourth colour, the answer is a word.

**Rule 4 — The floor is measurement, not taste.**
Every text pair is measured against its actual surface and must reach 4.5:1. Every rule and mark must reach 3:1. No exceptions for "it looks better dimmer" — a design that looks better on a calibrated laptop at 400 nits and fails on a five-year-old Android at 30% brightness through a wet freezer bag has failed at the only moment it exists for. This rule has already overruled the direction's own first palette twice (§2.4).

### 1.3 What this system is not

No cards. No containers. No corner radius in the record. No shadows, no elevation, no glass, no gradient, no texture, no fake paper grain. No status colour palette. No icon set. No empty states with an illustration. No modal dialogs. No tab bar, no navigation rail, no navigation stack. No spinner, no skeleton, no launch screen. No onboarding. The ornament in this system *is* the ruling.

---

## 2. Colour

### 2.1 The method

All ratios below are WCAG 2.2 contrast ratios, computed as `(L1 + 0.05) / (L2 + 0.05)` where L is relative luminance:

```
for each channel c in {R,G,B}:  c' = c/255
                                c_lin = c'/12.92                if c' <= 0.03928
                                c_lin = ((c' + 0.055)/1.055)^2.4 otherwise
L = 0.2126·R_lin + 0.7152·G_lin + 0.0722·B_lin
```

Worked example, `--ink-full` `#EDE8DC`:
`R' = 237/255 = 0.92941 → ((0.92941+0.055)/1.055)^2.4 = 0.84376`
`G' = 232/255 = 0.90980 → 0.80220`
`B' = 220/255 = 0.86275 → 0.71569`
`L = 0.2126(0.84376) + 0.7152(0.80220) + 0.0722(0.71569) = 0.80885`
`--page` `#0A0A0B`: `L = 0.00306`
`ratio = (0.80885 + 0.05) / (0.00306 + 0.05) = 0.85885 / 0.05306 = **16.19:1**`

### 2.2 Surfaces (dark — the default and primary theme)

The page is **not pure black**. White-on-black is the worst halation case at low luminance, and roughly 47% of adults have some degree of astigmatism, for whom high-contrast light-on-dark type blooms and smears. `#0A0A0B` is one step off black, warm-neutral, and is the **first painted frame** — there is no launch screen, no splash, no white flash, ever.

| Role | Token | Hex | Relative luminance |
|---|---|---|---|
| The page | `--page` | `#0A0A0B` | 0.00306 |
| A row under the thumb | `--row-pressed` | `#131315` | 0.00658 |
| The bottom sheet (keypad / index / chooser) | `--sheet` | `#141416` | 0.00707 |
| A button fill (the only filled shapes in the app) | `--slab` | `#1C1C1F` | 0.01176 |
| A button under the thumb | `--slab-pressed` | `#2A2A2E` | 0.02345 |

There are five surfaces and there will never be a sixth. They are not an elevation system — nothing casts a shadow. They exist because a button must be visibly a *filled shape* in a document made entirely of rules.

### 2.3 Inks and marks (dark)

Three ink densities and one hue. That is the entire palette.

| Role | Token | Hex | Luminance | Voice / job |
|---|---|---|---|---|
| Full ink — the record | `--ink-full` | `#EDE8DC` | 0.80885 | Tags, record body, control labels, stamps |
| Mid ink — secondary record | `--ink-mid` | `#A8A296` | 0.36368 | Summaries, units, unselected control labels, margin times |
| Low ink — struck and unset | `--ink-low` | `#8F8A7E` | 0.25523 | Struck text, gap labels, cleared countdowns |
| Rule — non-text only | `--rule` | `#6B675F` | 0.13653 | The 2px horizontal ruling, dotted unset rules, button borders |
| Margin rule — non-text only | `--madder-rule` | `#B94A40` | 0.15582 | The vertical spine, the ease-selected underline, the live-row tick |
| Madder ink — marks | `--madder-ink` | `#D4685C` | 0.24670 | The strike line, `STRUCK`, the query mark `?`, the dagger `†` |

### 2.4 What measurement overruled

Two values from the original direction did not survive rule 4, and it is worth recording why:

- **`#6B675F` as struck-text ink** measures **3.52:1** on the page. In a system whose entire claim is that a struck row *stays legible forever*, 3.52:1 is a contradiction of the thesis, not just an accessibility miss. The struck ink is lifted to `#8F8A7E` (**5.75:1**) and `#6B675F` is demoted to what it is genuinely good at — a 2px non-text rule at 3.52:1, comfortably over the 3:1 non-text floor.
- **`#A63A32` as the madder** measures **3.08:1** on the page and **2.65:1** on a slab. It is a beautiful madder and it cannot carry a strike-through. The hue is preserved (same red-orange family, same chroma character); the luminance is raised until it measures. Two values result: `#B94A40` for the non-text spine (3.88:1 everywhere it is drawn) and `#D4685C` for anything that carries meaning as a mark or as text (4.80:1 worst case).

One hue, three jobs, two densities. **Red anywhere means the record has something to say about itself.**

### 2.5 Contrast table — dark theme

Every pair that occurs in the twelve screens. AA = ≥4.5:1, AAA = ≥7:1, NT = non-text ≥3:1.

| Foreground | Hex | Background | Hex | Ratio | Grade |
|---|---|---|---|---|---|
| `--ink-full` | `#EDE8DC` | `--page` `#0A0A0B` | | **16.19** | AAA |
| `--ink-full` | `#EDE8DC` | `--row-pressed` `#131315` | | **15.18** | AAA |
| `--ink-full` | `#EDE8DC` | `--sheet` `#141416` | | **15.05** | AAA |
| `--ink-full` | `#EDE8DC` | `--slab` `#1C1C1F` | | **13.91** | AAA |
| `--ink-full` | `#EDE8DC` | `--slab-pressed` `#2A2A2E` | | **11.69** | AAA |
| `--ink-mid` | `#A8A296` | `--page` `#0A0A0B` | | **7.80** | AAA |
| `--ink-mid` | `#A8A296` | `--row-pressed` `#131315` | | **7.31** | AAA |
| `--ink-mid` | `#A8A296` | `--sheet` `#141416` | | **7.25** | AAA |
| `--ink-mid` | `#A8A296` | `--slab` `#1C1C1F` | | **6.70** | AA |
| `--ink-mid` | `#A8A296` | `--slab-pressed` `#2A2A2E` | | **5.63** | AA |
| `--ink-low` | `#8F8A7E` | `--page` `#0A0A0B` | | **5.75** | AA |
| `--ink-low` | `#8F8A7E` | `--row-pressed` `#131315` | | **5.39** | AA |
| `--ink-low` | `#8F8A7E` | `--sheet` `#141416` | | **5.35** | AA |
| `--ink-low` | `#8F8A7E` | `--slab` `#1C1C1F` | | **4.94** | AA |
| `--madder-ink` | `#D4685C` | `--page` `#0A0A0B` | | **5.59** | AA |
| `--madder-ink` | `#D4685C` | `--row-pressed` `#131315` | | **5.24** | AA |
| `--madder-ink` | `#D4685C` | `--sheet` `#141416` | | **5.20** | AA |
| `--madder-ink` | `#D4685C` | `--slab` `#1C1C1F` | | **4.80** | AA |
| `--rule` (non-text) | `#6B675F` | `--page` `#0A0A0B` | | **3.52** | NT |
| `--rule` (non-text) | `#6B675F` | `--sheet` `#141416` | | **3.27** | NT |
| `--rule` (non-text) | `#6B675F` | `--slab` `#1C1C1F` | | **3.02** | NT |
| `--madder-rule` (non-text) | `#B94A40` | `--page` `#0A0A0B` | | **3.88** | NT |
| `--madder-rule` (non-text) | `#B94A40` | `--sheet` `#141416` | | **3.61** | NT |
| `--madder-rule` (non-text) | `#B94A40` | `--slab` `#1C1C1F` | | **3.33** | NT |

**Every text pair in the system is ≥ 4.5:1.** The pairs at **≥ 7:1 (AAA)** are: `ink-full` on all five surfaces (11.69–16.19), and `ink-mid` on `page`, `row-pressed` and `sheet` (7.25–7.80). Everything the shepherd reads as *record* is AAA on the page.

**Two placement rules fall out of the measurement and are binding:**
1. **`--ink-low` and `--rule` are never drawn on `--slab-pressed`** (they measure 4.16 and 2.54). A pressed slab carries `--ink-full` only, and its border goes to `--ink-mid`. Pressed state is a 40ms flash under a thumb; it must not be the moment legibility drops.
2. **`--madder-rule` is never set as text and never carries a glyph.** It is a 2px line and nothing else.

### 2.6 Red-shift variant

Red-shift exists to preserve scotopic dark adaptation — long wavelengths only, at roughly half peak display luminance (set through the platform brightness API, *not* a CSS `filter`, because a filter would also dim the press feedback and would be a lie about what the display is doing).

In this system red-shift is **nearly a no-op**, and that is the point: the palette was already ink and rule, and nothing was ever encoded by hue, so switching themes changes six values and breaks nothing.

| Role | Token | Dark | Red-shift | Luminance (RS) |
|---|---|---|---|---|
| Page | `--page` | `#0A0A0B` | `#080605` | 0.00193 |
| Row pressed | `--row-pressed` | `#131315` | `#0F0B09` | 0.00361 |
| Sheet | `--sheet` | `#141416` | `#120D0A` | 0.00438 |
| Slab | `--slab` | `#1C1C1F` | `#1A1310` | 0.00723 |
| Slab pressed | `--slab-pressed` | `#2A2A2E` | `#261C17` | 0.01304 |
| Full ink | `--ink-full` | `#EDE8DC` | `#E4A896` | 0.46701 |
| Mid ink | `--ink-mid` | `#A8A296` | `#B8846F` | 0.27841 |
| Low ink | `--ink-low` | `#8F8A7E` | `#A4756A` | 0.21656 |
| Rule | `--rule` | `#6B675F` | `#8A6053` | 0.11102 |
| Margin rule | `--madder-rule` | `#B94A40` | `#C9564A` | 0.19567 |
| Madder ink | `--madder-ink` | `#D4685C` | `#F2C4AE` | 0.61413 |

**Red-shift contrast table**

| Foreground | Hex | Background | Ratio | Grade |
|---|---|---|---|---|
| `--ink-full` | `#E4A896` | `--page` `#080605` | **9.96** | AAA |
| `--ink-full` | `#E4A896` | `--row-pressed` `#0F0B09` | **9.64** | AAA |
| `--ink-full` | `#E4A896` | `--sheet` `#120D0A` | **9.51** | AAA |
| `--ink-full` | `#E4A896` | `--slab` `#1A1310` | **9.03** | AAA |
| `--ink-full` | `#E4A896` | `--slab-pressed` `#261C17` | **8.20** | AAA |
| `--ink-mid` | `#B8846F` | `--page` `#080605` | **6.32** | AA |
| `--ink-mid` | `#B8846F` | `--sheet` `#120D0A` | **6.04** | AA |
| `--ink-mid` | `#B8846F` | `--slab` `#1A1310` | **5.74** | AA |
| `--ink-mid` | `#B8846F` | `--slab-pressed` `#261C17` | **5.21** | AA |
| `--ink-low` | `#A4756A` | `--page` `#080605` | **5.13** | AA |
| `--ink-low` | `#A4756A` | `--sheet` `#120D0A` | **4.90** | AA |
| `--ink-low` | `#A4756A` | `--slab` `#1A1310` | **4.66** | AA |
| `--madder-ink` | `#F2C4AE` | `--page` `#080605` | **12.79** | AAA |
| `--madder-ink` | `#F2C4AE` | `--slab` `#1A1310` | **11.61** | AAA |
| `--rule` (NT) | `#8A6053` | `--page` `#080605` | **3.73** | NT |
| `--rule` (NT) | `#8A6053` | `--sheet` `#120D0A` | **3.57** | NT |
| `--rule` (NT) | `#8A6053` | `--slab` `#1A1310` | **3.39** | NT |
| `--madder-rule` (NT) | `#C9564A` | `--page` `#080605` | **4.73** | NT (passes AA too) |
| `--madder-rule` (NT) | `#C9564A` | `--slab` `#1A1310` | **4.29** | NT |

Every red-shift text pair is ≥ 4.5:1. AAA pairs: `ink-full` on all five surfaces (8.20–9.96) and `madder-ink` on all surfaces (10.53–12.79). The same two placement rules apply: `--ink-low` off `--slab-pressed` (4.23), `--rule` off `--slab-pressed` (2.55).

One deliberate inversion: in dark, `--madder-ink` is *dimmer* than `--ink-full` and is identified by hue. In red-shift there is no hue channel left to identify with, so `--madder-ink` becomes the **brightest mark on the page** (L 0.614 vs 0.467) and is identified by luminance. The rule that governs it: **madder is identified by hue where hue exists and by luminance where it does not, and in both cases the form carries the meaning on its own.**

### 2.7 How status is encoded without relying on colour

There is no status palette. Not because of an accessibility checkbox, but because a colour-coded death reads wrong at 4am through a wet freezer bag — and because a shepherd wearing a red head torch is, optically, already colour-blind.

Every state in the twelve screens is carried by **at least two non-colour channels**:

| State | Channel 1 — a word | Channel 2 — a mark | Channel 3 — geometry | Colour (reinforcement only) |
|---|---|---|---|---|
| Struck entry | `STRUCK 03:41` in the margin | a 3px line through the row | text drops to `--ink-low` | line and stamp in `--madder-ink` |
| Contradiction | tapping prints the sentence | `?` query mark in the margin | 2px underline under the offending cell | `--madder-ink` |
| Edited timestamp | `†edited — event 03:20 as entered` | `†` dagger before the time | second time printed on a second line | `--madder-ink` dagger |
| Auto timestamp | `AUTO` stamp, 14px caps | — | in the margin column, never in the row | none — full ink |
| Pen over threshold | `OVER` stamp + `31h` | `†` dagger in the margin | **doubled rule** under the row; hours jump from `--ink-mid` to `--ink-full` | `--madder-ink` dagger only |
| Under withdrawal | `WITHDRAWAL · CLEARS 12 AUG` | day tally marks (9 strokes) | — | none |
| Last day of withdrawal | `LAST DAY` | `†` + one tally mark | — | `--madder-ink` dagger only |
| Lamb dead | the word `DEAD` | — | printed in the lamb row, full ink | **none, ever** |
| Lamb alive | the word `ALIVE` | — | — | none |
| Barren | the word `BARREN` in a 2px stamp box | — | — | none |
| Unset / skipped field | `— NOT RECORDED` label | 2px **dotted** rule where the value would be | a visible gap in the column | none |
| Derived value | `(COUNTED)` after the value | the tally strokes themselves | — | none |
| Selected (ease, filter) | — | 2px solid underline, full width of the target | fill goes `--page` → `--slab` | madder underline on ease only |

Note the row for *dead*. It would be trivially easy to make a dead lamb red. It is not, and never will be. Death is a word.

---

## 3. Typography

### 3.1 Two voices, strictly separated

The system is built on a stated, visible, learnable distinction: **serif = record, sans = control.** This is not a stylistic preference — it is the fastest possible disambiguation at 3am, faster than colour (which the red torch destroys), faster than position (which scrolls), faster than size. Even at a glance in the dark, from the shape of the letterforms alone, you can tell history from target.

The app says so about itself, in Settings, in one printed line:

> THE RECORD IS SET IN THE BOOK FACE. THE BUTTONS ARE SET IN THE MACHINE FACE.
> IF IT IS SERIF, IT HAPPENED. IF IT IS SANS, IT IS A THING YOU CAN PRESS.

### 3.2 The stacks

Both faces are **bundled**, not requested from the system. The product spec's §11 already budgets for this ("payload dominated by fonts"), and the whole design fails if the two voices collapse into one on a device without the right fonts installed.

```
--face-record:  "Source Serif 4", "Source Serif Pro", Charter, "Bitstream Charter",
                ui-serif, "New York", "Noto Serif", Georgia, serif;

--face-control: "Source Sans 3", "Source Sans Pro", ui-sans-serif, "SF Pro Text",
                Roboto, "Segoe UI", system-ui, sans-serif;
```

**Record face: Source Serif 4** (OFL 1.1, variable). Chosen for sturdy vertical stress, a large x-height, low stroke contrast — which survives halation — and, critically, true **tabular lining figures**. Its `1` has a full foot serif and a strong flag; its `7` has a flat top and no descending curve; its `6` and `8` have distinctly different upper bowls. That is the acceptance test for any future replacement face: **the 1/7 and 6/8 test, read at 32px, at 30% screen brightness, through a sandwich bag.** If a face fails that, it does not go in the record, however handsome it is.

**Control face: Source Sans 3** (OFL 1.1, variable). Humanist, not a square grotesque — the MIT AgeLab glance-legibility work found humanist letterforms read accurately in roughly 9–12% shorter glances than square grotesques, which is exactly the difference between reading a button and guessing at it. It is also cut in the same workshop as Source Serif 4, which means the two faces are *related but unmistakably different* — the correct relationship for a two-voice system. Two families, four instances, whole payload under 700 kB.

The fallback stacks are a documented failure mode, not part of the design. On iOS the first fallback pair (`ui-serif` / `ui-sans-serif` → New York / SF Pro) still separates; on Android (`Noto Serif` / `Roboto`) it separates less well. Bundle the fonts.

### 3.3 Weight policy

Light type on a dark ground bleeds outward and gains apparent weight. Every weight in this system is set **one step lighter than its light-mode equivalent** and both faces are used as variable fonts so the step is real, not a synthetic approximation.

| Token | Value | Use |
|---|---|---|
| `--w-record` | `390` | Record body, margin times, struck text |
| `--w-record-strong` | `420` | Tags at 32px and above, big figures |
| `--w-control` | `520` | Button labels, index words, field labels |
| `--w-control-strong` | `600` | The corner slab label, stamps |

**Nothing is italic, anywhere, ever.** Italic serifs smear under halation at low luminance — the thin joins in an italic `e` or `a` disappear entirely at 30% brightness. Emphasis is achieved by face swap, by a 2px rule, or by a stamp. Never by slope. There is also no small-caps: stamps are true all-caps with positive tracking.

### 3.4 The scale

Body text minimum is **20px** for the record and **19px** for controls — both above the spec's 18pt floor, with `--t-record-sm` / `--t-margin` at 18px as an absolute hard floor used only for a summary line that sits directly under a 32px tag it explains.

| Token | px | Line height | Face | Tracking | Use |
|---|---|---|---|---|---|
| `--t-figure` | 56 | 60 | record, tabular | 0 | `187%`, `1.9`, season figures |
| `--t-tag-xl` | 44 | 48 | record, tabular | 0 | Pen number, live-row tag, ewe-card tag |
| `--t-tag` | 32 | 36 | record, tabular | 0 | Tag in a row, keypad digit, ease digit, hours, days |
| `--t-slab` | 26 | 28 | control caps | 0.06em | The corner slab: `+ LAMB` |
| `--t-ctl-lg` | 22 | 26 | control | 0.01em | Primary word buttons: `TURN OUT`, `FOSTER` |
| `--t-record` | 20 | 28 | record | 0.006em | **The record body.** Everything that happened. |
| `--t-ctl` | 20 | 24 | control | 0.01em | Standard button labels, index words |
| `--t-ctl-sm` | 19 | 23 | control | 0.01em | Field labels, filter words — control floor |
| `--t-record-sm` | 18 | 24 | record | 0.006em | Secondary record line — record floor |
| `--t-margin` | 18 | 22 | record, tabular | 0 | Margin timestamps |
| `--t-head` | 16 | 20 | control caps | 0.10em | Page header: `NIGHT OF 27 JULY 2026 · PAGE 3` |
| `--t-stamp` | 14 | 17 | control caps | 0.14em | `AUTO` `STRUCK` `DERIVED` `OVER` `YOUR ENTRY` |

`--track-record: 0.006em` is a small positive tracking applied only in dark themes: light-on-dark counters close up under halation, and six thousandths of an em reopens them without the text reading as spaced.

**The 14px stamp and the 18pt rule.** Stamps are the only thing in the system below 18px, and they are permitted for three reasons, all of which must hold: (a) a stamp is never body text — it is a label of provenance, always ≤ 12 characters, always all-caps at 0.14em tracking, which is the most glanceable configuration available at small sizes; (b) a stamp is always set in `--ink-full` at 16.19:1, the highest contrast in the app; (c) **no stamp is ever the sole carrier of its meaning** — `STRUCK` sits beside a line through the row, `OVER` beside a dagger and a doubled rule, `AUTO` beside a time that is obviously the current time. Remove every stamp from the app and it still works. That is the test that keeps 14px honest.

### 3.5 Tabular numerals policy

1. **Every figure in the record is tabular lining.** `font-variant-numeric: tabular-nums lining-nums`, no exceptions. Tags, times, weights, hours, days, percentages, counts.
2. **Every figure in a control is tabular too.** The keypad digits, the ease digits, the stepper value. A digit must never change width or shape between the button you press and the row it prints into.
3. **Oldstyle / proportional figures are used nowhere.** There is no place in this app where a number is decorative.
4. **Tags right-align in a fixed three-character column.** This is what makes the flock page scannable: `12`, `77` and `91` sit under the units column of `412`, `128` and `305`, so the eye runs straight down the numerals with no zig-zag. Right-alignment of the tag column is not a preference, it is the reason the left column works.
5. **The one exception to Rule 2 (§1.2): the keypad digits are set in the record face, not the control face.** They are the only sans-shaped thing that would become serif-shaped the instant you press it, and the shepherd is matching a digit on a key against a digit already printed in the recents list and in the row above. Same shape, same width, no translation step. This exception is documented in Settings alongside the two-voices line, because an unexplained exception is a bug.

### 3.6 At 200% text scale

Both platforms scale text and this system must not reflow into a different structure when they do. The commitment: **rows grow, the grid does not move.** The margin stays at the left, the spine stays vertical, the slab stays in the corner, the page simply gets longer.

| Element | 100% | 200% | Behaviour |
|---|---|---|---|
| `--t-record` | 20px | 40px | Linear |
| `--t-tag` | 32px | 64px | Linear |
| `--t-figure` | 56px | 112px | Linear; the season figure wraps to its own row |
| `--t-stamp` | 14px | 21px | **Capped at 150%.** A caps-tracked 28px stamp would be wider than the margin cell, and the stamp is never the sole carrier of meaning (§3.4) |
| `--t-head` | 16px | 32px | Linear |
| Record row height | 64px | 112px | Grows to contain the text |
| Ewe row height | 88px | 156px | Grows |
| Pen row height | 88px | 152px | Grows |
| Margin gutter | 68px | 96px | Grows to hold a 36px tabular time; the spine moves right with it and stays continuous |
| Keypad key | 117 × 84 | 117 × 108 | **Height only.** The 3-column grid is preserved — a 64px tabular digit is ~35px wide and fits comfortably |
| Corner slab | 160 × 140 | 176 × 154 | **Capped at 110%.** It is a thumb target, not a reading target, and it is already the largest target in the app |
| Ease 1–5 group | 5 × 64px in a row | **3 + 2, at 116 × 80** | The one documented component wrap in the system, triggered at ≥150% scale. The page structure does not change; one component re-lays |
| Rows visible at once | 8 + the live row | 5 + the live row | Density is a consequence of the grid, not a fixed target |

The `--rule-w: 2px` never scales. A rule is a physical mark, not type.

---

## 4. Space, geometry and grid

### 4.1 Spacing scale

Four-based, ten steps, no half-steps.

| Token | px | Typical use |
|---|---|---|
| `--s-1` | 4 | Tally stroke gap, stamp box padding |
| `--s-2` | 8 | Gap between segmented buttons, key gaps |
| `--s-3` | 12 | Word-button inline padding, slab-to-row gap |
| `--s-4` | 16 | Page gutter, right edge |
| `--s-5` | 20 | Inside a row, between tag and body |
| `--s-6` | 24 | Between component groups within a row |
| `--s-7` | 32 | Between record sections |
| `--s-8` | 40 | Above a double rule |
| `--s-9` | 48 | Below a page header |
| `--s-10` | 64 | Standard row height, standard target |
| `--s-11` | 88 | Tall row height (ewe, pen) |
| `--s-12` | 132 | Slab height minus its border |

### 4.2 Geometry

**Radii.** `--radius-record: 0`, `--radius-sheet: 0`, `--radius-slab: 2px`. Nothing in the record has a corner radius, because a document has no corners. Buttons get 2px — enough to read as a cut block of type rather than a hole in the page, small enough that at arm's length it reads as square. There is no third radius and there will not be one.

**Strokes.** All rules are **2px, never 1px.** A hairline shimmers, aliases, or vanishes entirely on a mid-range Android at low brightness — and in this design the ruling is load-bearing structure, not decoration. Raising it to 2px is the single cheapest legibility win in the system.

| Token | Value | Use |
|---|---|---|
| `--rule-w` | 2px | Every horizontal rule, every button border, the vertical spine |
| `--rule-strike-w` | 3px | The strike-through line. Heavier than a rule on purpose — it must never be mistaken for a row boundary |
| `--rule-double-gap` | 3px | The gap between the two lines of a double rule (totals, over-threshold) |
| `--rule-dot` | `2px 6px` | The dash pattern for an unset field. Never a solid rule, so an empty field can never be confused with an entered one |

**Shadows: none.** Elevation: none. The bottom sheet is separated from the page by a 2px `--ink-full` top rule, at 16.19:1, which is more visible in the dark than any blur would be and does not lift the black level.

### 4.3 The layout grid

Reference viewport: **393 × 852** (iPhone 15/16 logical; a Pixel 8 at 412 × 915 gains 19px of record column and one more visible row).

```
 0                68  76                                     377   393
 │                │   │                                        │    │
 ├────────────────┼───┼────────────────────────────────────────┼────┤
 │  MARGIN CELL   │ ▌ │            RECORD COLUMN               │gut │
 │  68px          │2px│            301px                       │16px│
 │                │spine                                            │
 │  03:20         │   │  412  triplets · ease 3 · assisted   ┃┃┃    │
 │  AUTO          │   │                                             │
 ├────────────────┼───┼────────────────────────────────────────┼────┤
```

- `--gutter: 16px` — page edge inset, left and right.
- **`--margin-rule-x: 68px`** — the vertical madder spine. 2px wide, `--madder-rule`, **continuous down the entire scroll**. It does not break for headers, sheets, sections or the live row. It is what makes this a book and not a list; if a component would interrupt it, that component is wrong.
- **Margin cell: 0 → 68px.** Holds the auto-captured time (18px tabular, `--ink-mid`), the `AUTO` / `STRUCK` / `EDITED` stamp, the dagger `†` and the query mark `?`. Because it is 68 × 64px it is also a legal tap target — tapping a dagger or a query mark in the margin opens its explanation.
- **`--record-x: 76px`** — the record column starts 8px right of the spine and runs to 377px. 301px wide.
- **The spine never mirrors.** A book's margin is on the left. Left-handed mode moves the slab, not the spine (§4.5).

**Row sub-grid** (inside the record column, for a lambing row):

| Cell | Width | Alignment | Face |
|---|---|---|---|
| Tag | 76px fixed (3 tabular digits at 32px) | right | record |
| Body | flex | left | record |
| Lamb tally | 132px fixed | right | filled marks |
| Trailing status | fits content, min 64px | right | control caps |

The live row stops 12px short of the corner slab; its usable width is 301 − 160 − 12 = **129px** for the body when the slab is present, which is exactly why the live row prints in two lines (tag + tally on line 1, derived type + optional cells on line 2) and the slab is allowed to overlap nothing.

### 4.4 Row heights

| Row | Height | Reason |
|---|---|---|
| Record row | **64px** | One line of 20px record + margin time; the standard target |
| Ewe row | **88px** | 32px tag + an 18px summary line beneath it |
| Pen row | **88px** | 44px pen number needs the height |
| Chart row (one day) | **44px** | Not a target, read-only; the only sub-64 row in the system |
| Page header | **44px** | Sticky, read-only |
| Bottom band | **152px** | Slab (140) + 12 clearance, above `env(safe-area-inset-bottom)` |

Eight 64px rows plus the live row fill the space between the header and the bottom band (852 − 44 − 152 = 656 ⇒ 8 rows at 64 = 512, plus a 128px two-line live row, plus 16px). That is the density target: **a page reads as a table without ever being a screen of small text.**

### 4.5 Reach zones for one thumb

Measured from the bottom of the 852px viewport, right-handed default:

| Band | Distance from bottom | What is allowed to live here |
|---|---|---|
| **Thumb band** | 0 – 320px | The corner slab, the `INDEX` button, the live row, the whole bottom sheet (keypad, recents, choosers), the ease group, the care checks, the event buttons. **Everything required to record an event.** |
| **Reach band** | 320 – 560px | Filter line, secondary word buttons, the rows you are reading back. Tappable with a grip shift. Nothing here is required. |
| **Read band** | 560 – 852px | Page header, history rows, chart. **Read-only.** |

**The binding rule: nothing above 560px from the bottom is ever required to complete an event.** If a flow needs a control above that line, the flow is wrong. This is checkable in review with a ruler.

Two thumb anchors, and only two:

- **Bottom-right: the corner slab.** 160 × 140px, the largest target in any of the three directions, because it is the one pressed hundreds of times in a season.
- **Bottom-left: `INDEX`.** 96 × 64px word-button. Opens the index as a bottom sheet of ruled lines.

Everything between them is one scrolling ruled page.

**Left-handed mirror** (`[data-hand="left"]`): the slab moves to bottom-left, `INDEX` to bottom-right. **The spine does not move.** The record column narrows on the other side. Set in Settings, no gesture.

**Minimum target audit.** Every interactive element in the system, at 100% scale: corner slab 160 × 140 · keypad key 117 × 84 · record row 393 × 64 · ewe row 393 × 88 · pen row 393 × 88 · ease button 64 × 64 · stepper ± 64 × 64 · stepper value 88 × 64 · check control 393 × 64 (its right half a 64 × 64 target) · word button min 64 × 64 (12px inline padding, min-width 64px so `ALL` is still a legal target) · margin cell 68 × 64 · recents line 393 × 64 · index line 393 × 64 · sheet `CLOSE` 88 × 64. **The smallest target in the app is 64 × 64.** The spec floor is 60.

---

## 5. Motion

The premise: **ink appears, it does not travel.** Nothing in a book slides. Motion in this system exists for exactly one reason — to confirm that a mark was made — and it is spent almost entirely on the two moments that matter.

### 5.1 What animates

| Token | Duration | Curve | What |
|---|---|---|---|
| `--motion-press` | 40ms | `--ease-out` | A slab or key filling from `--slab` to `--slab-pressed`. Fill only; **no scale, no lift, no ripple** — a target that shrinks under a cold thumb is a target you miss |
| `--motion-ink` | 120ms | `--ease-out` | A newly printed glyph fading 0 → 1 opacity: a tally stroke landing, a tag printing into the row, a stamp appearing. **Opacity only. Zero translation.** |
| `--motion-sheet` | 160ms | `--ease-out` | The bottom sheet rising. Translate-Y only, no fade, no backdrop blur, no scrim animation |
| `--motion-strike` | 180ms | `linear` | The strike line drawing left-to-right, `scaleX(0) → scaleX(1)`, `transform-origin: left` |

`--motion-strike` is **the only animation in the app with a direction**, and it is linear rather than eased because the gesture being represented is a pen drawn across a page at constant speed. It is the one place in the system where the animation *is* the meaning: you watch the line go through the row, and you understand that the entry has not gone anywhere.

### 5.2 What must never animate

- **Numbers.** No count-ups, no odometers, no ticking. Ever. A number that is mid-animation is a number you can misread, and this app is a record of numbers.
- **The chart.** The lambing spread draws at full length in the first painted frame. A bar that grows is a bar you cannot read for 400ms.
- **Rows.** Rows never reorder, never slide, never crossfade. The page only grows downward. When a filter changes, the page **re-prints instantly** with no transition — a crossfade at 3am reads as a lag, and a lag reads as "it didn't save".
- **Launch.** There is no splash screen, no logo, no fade-in. The **first painted frame is `--page` with tonight's page already on it**. This is a hard requirement, not a target: no white flash, ever, on either platform.
- **Scroll.** No parallax, no sticky header collapse, no elastic header. The page header is 44px and stays 44px.
- **The spine.** The madder margin rule is drawn once and never moves, transitions or animates. It is the one fixed thing on the screen and its stillness is doing work.

### 5.3 Reduce-motion

Under `prefers-reduced-motion: reduce`:

| Token | Reduced value |
|---|---|
| `--motion-ink` | `0ms` — the glyph is simply there |
| `--motion-sheet` | `0ms` — the sheet is simply there |
| `--motion-strike` | `0ms` — the line is drawn full-width instantly |
| `--motion-press` | **`40ms`, unchanged** |

The press flash survives reduce-motion deliberately. It is a fill change under a thumb, not motion, and it is the confirmation that a press through a glove and a freezer bag registered. Removing it would remove the only visual feedback available to a user who cannot feel the screen.

### 5.4 Haptics — the motion that works through a bag

Under a wet nitrile glove, inside a freezer bag, in the dark, with the phone at arm's length while you hold a lamb, **haptics are the primary feedback channel and the visual press state is the backup.**

| Event | Haptic |
|---|---|
| Tally stroke printed (slab press) | One 10ms tick |
| Keypad digit | One 10ms tick |
| Tag lands / row commits | Two ticks, 60ms apart |
| Strike applied | Two ticks, 120ms apart — deliberately slower, a different rhythm from a commit |
| Threshold crossed while the app is open (pen hits 24h) | One tick. Nothing else. No banner, no sound |
| Anything else | Nothing |

Haptics are **not** disabled by reduce-motion (they are not motion) and are individually disableable in Settings. There is no sound anywhere in the app — at 3am in a shed with lambs, sound is either useless or unwelcome.

---

## 6. Iconography

### 6.1 The approach: printer's marks and numerals. There is no icon set.

Every action in this app is a **word**: `TREAT` · `MOVE PEN` · `ADD NOTE` · `TURN OUT` · `FOSTER` · `STRIKE` · `TAG` · `WEIGH` · `REPEAT LAST` · `EXPORT` · `CHANGE TYPE`. Words are unambiguous in a language the shepherd already speaks, they survive being read at arm's length, and they cannot be mistaken for each other the way a pictogram of a syringe and a pictogram of a thermometer can. An icon set would also be the single biggest payload item in a product that is proud of being under 20 MB.

What remains is six **marks**, drawn from the same four-hundred-year-old tradition as the strike-through. Four are glyphs set in the record face; two are inline SVG.

### 6.2 The six marks

**1. The dagger `†`** — record face glyph, 24px, `--madder-ink`. Printed in the margin cell. Means *look at this*: an edited timestamp, a pen over the turn-out threshold, a withdrawal on its last day. Always accompanied by a word.

**2. The double dagger `‡`** — record face glyph, 24px, `--madder-ink`. A second-order flag: an entry that is both struck and queried. Rare by design.

**3. The query mark `?`** — record face glyph, 28px, `--madder-ink`, in the margin. A real auditor's mark. Means *the record contradicts itself and I am not going to fix it for you.* Tapping it offers exactly two options and never a third.

**4. The tally stroke** — inline SVG, filled rect, `--ink-full`. `8px × 30px`, 3px gap. The fifth stroke of any group is drawn diagonally across the previous four — a true five-bar gate, because a shepherd counting to fourteen lambs in a night should not have to count to fourteen.

```svg
<svg width="132" height="30" viewBox="0 0 132 30" fill="none" aria-label="3 lambs">
  <rect x="0"  y="0" width="8" height="30" fill="currentColor"/>
  <rect x="11" y="0" width="8" height="30" fill="currentColor"/>
  <rect x="22" y="0" width="8" height="30" fill="currentColor"/>
</svg>
```

Five-bar form (the fifth stroke crosses):

```svg
<svg width="132" height="30" viewBox="0 0 132 30" fill="none" aria-label="5 lambs">
  <rect x="0"  y="0" width="8" height="30" fill="currentColor"/>
  <rect x="11" y="0" width="8" height="30" fill="currentColor"/>
  <rect x="22" y="0" width="8" height="30" fill="currentColor"/>
  <rect x="33" y="0" width="8" height="30" fill="currentColor"/>
  <path d="M-3 27 L46 3" stroke="currentColor" stroke-width="4" stroke-linecap="butt"/>
</svg>
```

A **struck** tally stroke (a lamb entered in error) keeps its rect and takes a 3px `--madder-ink` line through it. The count printed beside it reads `TWIN (COUNTED, 1 STRUCK)`.

**5. The strike line** — a 3px `--madder-ink` rule across the record column at 50% row height, `transform-origin: left`. Rendered as a `<div>`/border rather than SVG so it can animate `scaleX` cheaply. In red-shift it is **doubled** — two 2px lines with a 3px gap — because red-shift removes the hue channel and the form has to work harder.

**6. The delete key `⌫`** — the only drawn glyph in the app, on the keypad, because the word `DELETE` takes longer to find on a key than a shape does. Inline SVG, 2px stroke, butt caps, miter joins, 28 × 28 box, `currentColor`.

```svg
<svg width="28" height="28" viewBox="0 0 28 28" fill="none" stroke="currentColor"
     stroke-width="2" stroke-linecap="butt" stroke-linejoin="miter" aria-label="delete">
  <path d="M9 4 L26 4 L26 24 L9 24 L2 14 Z"/>
  <path d="M13 10 L20 18 M20 10 L13 18"/>
</svg>
```

### 6.3 Stroke and size rules

- All drawn marks: **2px stroke** — the same weight as every rule in the system, so a mark and a rule read as having come from the same pen. The tally stroke is the exception at 8px wide because it is a filled block of ink, not a line.
- `stroke-linecap: butt`, `stroke-linejoin: miter`. No rounded ends. Nothing in a printed book has a rounded end.
- Boxes: 24 × 24 or 28 × 28 only. Never 16, never 20.
- `currentColor` always, so a mark inherits its ink from the row it sits in and a struck row's marks dim with the text.
- No fills except the tally strokes.
- **No new mark may be added without deleting one.** Six is the budget.

---

## 7. Component inventory

All dimensions at 100% text scale on a 393px viewport. Every component's default state assumes `--page` as its ground unless stated.

### 7.1 Corner slab — the primary action target

The largest target in the system. `160 × 140px`, bottom-right (mirrorable), 12px above `env(safe-area-inset-bottom)`, 16px from the right edge. Fill `--slab`, 2px `--ink-mid` border, 2px radius. Label in `--face-control` at `--t-slab` (26px), `--w-control-strong`, all-caps, 0.06em tracking, `--ink-full` (13.91:1).

Its verb changes with what the page is:

| Page | Label |
|---|---|
| Tonight, live lambing row open | `+ LAMB` |
| Tonight, no row open | `+ EVENT` |
| Flock | `+ EWE` |
| Treatments | `+ DOSE` |
| Ewe card | `+ NOTE` |
| Pen board | `MOVE` |
| Season, Export, Settings, Reminders | *absent — only `INDEX` is pinned* |

| State | Rendering |
|---|---|
| **Default** | Fill `--slab`, 2px `--ink-mid` border, label `--ink-full` |
| **Armed** (a tag has landed; the next press writes a lamb) | Border goes 2px `--ink-full`; a 3px `--madder-rule` tick, 24px long, prints at the slab's top-left corner |
| **Pressed** | Fill `--slab-pressed` for `--motion-press` 40ms, border to `--ink-mid`, label stays `--ink-full` (11.69:1). No scale change, no ripple. One haptic tick |
| **Disabled** (no subject selected) | Fill `--page`, 2px `--rule` **dashed** border (`--rule-dot`), label `--ink-low` (5.75:1) reading `TAG FIRST`. Still a 160 × 140 target — pressing it opens the tag sheet rather than doing nothing |
| **Warning** (pressing would contradict a declared birth type) | Fires normally, prints the stroke, and prints a `?` in the margin. **The slab never refuses a press.** The record takes what the shepherd did and flags it |

### 7.2 Keypad key

`117 × 84px`. Grid of 3 × 4 inside the sheet: `117 × 3 + 8 × 2 = 367`, plus 12px sheet padding each side and 2px of slack = 393. Row gap 8px, total keypad height `84 × 4 + 8 × 3 = 360px`.

Digit in **`--face-record`** (the documented exception, §3.5) at `--t-tag` 32px, tabular, `--w-record-strong`, `--ink-full`. Fill `--slab`, 2px `--rule` border, 2px radius.

Bottom row: `⌫` · `0` · `NEW TAG`. `NEW TAG` is the create-on-the-fly action, set in `--face-control` at `--t-ctl-sm` 19px caps — it is a control, so it wears the machine face even sitting in a grid of record-face digits, which is precisely how you tell at a glance that it is not a digit.

| State | Rendering |
|---|---|
| **Default** | Fill `--slab`, 2px `--rule`, digit `--ink-full` (13.91:1) |
| **Pressed** | Fill `--slab-pressed`, border `--ink-mid`, digit `--ink-full` (11.69:1). 40ms. One haptic tick |
| **Disabled** | Never. No key is ever disabled — a dead key under a cold thumb is indistinguishable from a missed tap |
| **Warning** | n/a |

### 7.3 Ruled record row

Full width, **64px**, 2px `--rule` bottom border only (rows share edges; there is no top border and no gap — the ruling is continuous, like a ledger).

Layout: margin cell 0–68px (time at `--t-margin` 18px tabular `--ink-mid`, stamp beneath at `--t-stamp` 14px `--ink-full`) · spine at x=68 · record column 76–377 · tag right-aligned in a 76px column at `--t-tag` 32px `--ink-full` · body at `--t-record` 20px `--ink-mid` · tally right-aligned in 132px.

| State | Rendering |
|---|---|
| **Default** | As above |
| **Live** (open row, being written) | Bottom border goes 2px `--ink-full` instead of `--rule`; a 3px × 64px `--madder-rule` tick prints on the spine beside it. Two lines, 128px tall. The row above it is fully visible — this is the "you can see it, in ink, one line above" mechanism |
| **Pressed** | Fill `--row-pressed` `#131315` for 40ms. Text unchanged (15.18:1 / 7.31:1). No border change |
| **Struck** | 3px `--madder-ink` line across the record column at 50% height (5.59:1); all row text drops from `--ink-full`/`--ink-mid` to `--ink-low` (**5.75:1 — still fully legible, permanently**); margin prints `STRUCK 03:41` at `--t-stamp` in `--madder-ink`. The row **stays in position** — it does not move, collapse, or fade |
| **Queried** | `?` at 28px `--madder-ink` in the margin cell; 2px `--madder-ink` underline beneath the offending cell only. Row otherwise unchanged and fully legible |
| **Unset cell** | Where a value would be: a 2px `--rule` dotted line (`--rule-dot` 2px 6px), 40px long, with a 14px caps `--ink-low` label above it. **A visible gap, never a hidden field.** The record is honest about its own thinness |

### 7.4 Ewe row (flock list)

Full width, **88px**, 2px `--rule` bottom border.

- Tag: `--t-tag` 32px, tabular, `--w-record-strong`, `--ink-full`, **right-aligned in a fixed 76px column** ending at x=152. So `412` `128` `305` `77` `219` `12` `340` `91` all align on their units digit.
- Summary line beneath: `--t-record-sm` 18px, `--ink-mid` (7.80:1) — *"3 seasons · avg 2.0 · assisted twice"*.
- Trailing column, right-aligned: the state as a word at `--t-ctl-sm` 19px caps `--ink-mid`, plus a figure at `--t-tag` 32px tabular where there is one (`31h`, `9d`).

| State | Rendering |
|---|---|
| **Default** | As above |
| **Pressed** | `--row-pressed`, 40ms |
| **Warning** (over threshold / last withdrawal day) | `†` in the margin, the trailing figure lifts from `--ink-mid` to `--ink-full`, and a **doubled 2px rule** replaces the single rule beneath the row |
| **Struck** (ewe removed from the flock) | Line through, `--ink-low`, `STRUCK 12 MAR` in the margin. She stays in the list, at the bottom, under a printed line reading `STRUCK — 1` |

### 7.5 Pen tile — the tile that is not a tile

The pen board is the one screen where the obvious answer is a grid of cards, and this system does not have cards. It has rules. So the pen board is **twelve ruled rows, one per pen, 88px each**, and it is more legible from arm's length than a grid of tiles would be, because a grid forces the eye to zig-zag and a ruled column does not.

- Pen number: `--t-tag-xl` **44px** tabular `--ink-full`, in a fixed 68px column immediately right of the spine. Readable across a shed.
- Occupant: ewe tag at `--t-tag` 32px + lamb tally marks.
- Hours: `--t-tag` 32px tabular, right-aligned, hard against x=377 so the hours form their own scannable column down the page.
- Empty pens print `— empty —` at `--t-record` 20px `--ink-low` (5.75:1). They are not blank, and they are not hidden.

| State | Rendering |
|---|---|
| **Default (occupied, under threshold)** | Hours in `--ink-mid` (7.80:1), single 2px `--rule` beneath |
| **Empty** | `— empty —` in `--ink-low`; the row is still a target (tapping it moves a ewe in) |
| **Warning (over the user-set threshold)** | **Four channels, one of them colour:** (1) the word `OVER` as a boxed stamp; (2) `†` in the margin in `--madder-ink`; (3) hours lift from `--ink-mid` to `--ink-full`; (4) the rule beneath the row **doubles** — two 2px lines, 3px apart. Delete the colour entirely and three channels remain |
| **Pressed** | `--row-pressed`, 40ms |
| **Turned out** | The row prints `TURNED OUT 04:12` in `--ink-low` and **stays on the page for the rest of the night.** The pen shows as empty on the next open. Nothing vanishes under your hand |

### 7.6 Countdown — withdrawal

Not a bar. Not a ring. Not a progress arc. A ruled row plus a **tally of days**, in the same visual language as the lamb column, so a shepherd who has learned one thing has learned both.

```
 77   ALAMYCIN LA · CLEARS 12 AUG 2026        │ │ │ │ │ │ │ │ │      9d
```

- 88px row. Product name at `--t-record` 20px `--ink-mid`; `CLEARS <date>` at `--t-ctl-sm` 19px caps `--ink-mid`.
- Day tally: one 2px × 12px `--ink-mid` mark per remaining day, 4px gaps, capped at 28 marks with `+n` printed after.
- Days figure: `--t-tag` 32px tabular `--ink-full`, right-aligned.

| State | Rendering |
|---|---|
| **Default** | As above |
| **Last day** | `†` in the margin, one tally mark, the word `LAST DAY` at `--t-stamp` in `--ink-full`, doubled rule beneath. No colour change to the figure |
| **Cleared** | `CLEARED 4 AUG` in `--ink-low`, tally replaced by a 2px solid rule the width the tally used to be. **The row stays in the medicine book forever** |
| **Pressed** | `--row-pressed` |
| **Disabled** | Never |

### 7.7 Status badge — the stamp

There is no badge. There is a stamp, and it is set in words.

`--t-stamp` 14px, `--face-control`, `--w-control-strong`, all-caps, 0.14em tracking, `--ink-full` (16.19:1), 24px tall, 8px inline padding.

Two forms, and the difference is meaningful:

- **Boxed** (2px `--rule` border, 2px radius) = *a state of the animal*: `PENNED` `LAMBED` `BARREN` `WITHDRAWAL` `TO LAMB` `DEAD` `ALIVE` `PET LAMB` `OVER`.
- **Unboxed** (no border) = *a note about the record itself*: `AUTO` `EDITED` `DERIVED` `COUNTED` `YOUR ENTRY` `STRUCK` `MUTED` `NOT RECORDED`.

You can tell from ten feet away whether a stamp is talking about the sheep or about the writing.

| State | Rendering |
|---|---|
| **Default** | `--ink-full`, boxed or unboxed per above |
| **Madder** | `STRUCK`, `QUERIED` only — `--madder-ink` (5.59:1), unboxed |
| **On a struck row** | Drops to `--ink-low` with the rest of the row (5.75:1) |
| **Pressed** | Stamps are not targets, except the margin stamp, whose target is the whole 68 × 64 margin cell |

### 7.8 Number stepper

For birth weight and pet-lamb feed count. **Never a slider** — the spec bans thin sliders, and a slider with a cold finger is a random number generator.

`[ − ] [ 4.1 ] [ + ]` — `64 × 64` · `88 × 64` · `64 × 64`, shared 2px `--rule` borders, total 216px. Value in `--face-record` at `--t-tag` 32px tabular. `−` and `+` in `--face-control` at 32px. Step 0.1 kg (0.2 lb).

Tapping the **value** opens the keypad sheet for direct entry — because stepping from 0 to 4.1 is 41 presses and the shepherd knows the number.

| State | Rendering |
|---|---|
| **Default** | Value `--ink-full`, signs `--ink-mid` |
| **Pressed** | The pressed half fills `--slab-pressed`, 40ms, one haptic tick. **No repeat-on-hold** — long-press-only behaviour is banned and hold-to-repeat is its cousin. One press, one step |
| **At floor** | `−` drops to `--ink-low` and does not fire. No error, no shake, no toast |
| **Unset** | Value prints `—·—` in `--ink-low` over a 2px dotted rule, with `NOT RECORDED · SKIPPABLE` at `--t-stamp` above. It is honest that it is empty |
| **Warning** | n/a. There is no such thing as an implausible birth weight, and the app does not have opinions |

### 7.9 Segmented choice

**Lambing ease 1–5.** Five buttons, `64 × 64` each, 8px gaps: `64 × 5 + 8 × 4 = 352`, inside the 361px available. Digits in `--face-record` (a recorded value) at `--t-tag` 32px tabular.

| State | Rendering |
|---|---|
| **Default (unselected)** | Fill `--page`, 2px `--rule` border, digit `--ink-mid` (7.80:1) |
| **Selected** | Fill `--slab`, 2px `--ink-full` border, digit `--ink-full` (13.91:1), **plus a 2px `--madder-rule` underline the full 64px width beneath the button**, plus the description printed to the right in `--face-control`: `EASE 3 · SOME ASSISTANCE` |
| **Pressed** | `--slab-pressed`, 40ms, haptic tick |
| **Unset (the group)** | All five unselected and a 2px dotted `--rule` under the whole group labelled `EASE — NOT RECORDED · SKIPPABLE` |
| **Warning** | n/a |

**Birth type: there is no segmented control, because there is no choice.** This is the signature of the direction and it must not be softened. The birth type is derived from the tally strokes and printed as `TRIPLET (COUNTED)` with `COUNTED` as an unboxed stamp. A `CHANGE TYPE` word-button exists, reachable only from the type cell or from a query mark, and it is used for one legitimate case: writing up at 7am when you know it was triplets and you never pressed the slab. **Declaring a type that contradicts the strokes prints a `?` in the margin. It does not adjust the strokes, and the strokes do not adjust it.** Safety rule 4, as geometry.

### 7.10 Check control — a stamp with a time on it

Care checkboxes: colostrum given, navel dipped, stomach tubed, warmed.

Full-width **64px** ruled line. Label left in `--face-control` at `--t-ctl` 20px. Right half is a `64 × 64` target.

There is no checkbox glyph, because a tick is a state and this system does not record states — it records events. **Ticking `colostrum given` at 03:24 records that you ticked it at 03:24**, which is a materially better record and costs nothing.

| State | Rendering |
|---|---|
| **Unset** | Label `--ink-mid`; 2px dotted `--rule` under the label, 64px long |
| **Done** | Label lifts to `--ink-full` with a **2px solid `--ink-full` underline**; the right cell prints `DONE 03:24` — `DONE` as a `--t-stamp` unboxed stamp, the time in `--face-record` tabular at `--t-margin` 18px |
| **Pressed** | `--row-pressed`, 40ms, haptic tick |
| **Undone** | You pressed it by mistake. The `DONE 03:24` stamp is **struck**, and `UNDONE 03:31` prints beside it: `D̶O̶N̶E̶ ̶0̶3̶:̶2̶4̶ · UNDONE 03:31`. Rule 1 applies to a checkbox exactly as it applies to a lambing |
| **Disabled** | Never |

### 7.11 Chart — small multiples of the ruled row

The lambing spread is not a chart component. It is **fourteen ruled rows**, the same rows as everything else, and each one's bar is built from the same filled blocks as the lamb tally. There is no axis, no gridline, no legend, no tooltip, no colour, and no animation.

Each day row: **44px** (the only sub-64px row in the system — it is read-only). Day number in the margin cell at `--t-margin` 18px tabular. Bar from x=76: one `8 × 24px` `--ink-full` block per birth, 3px gaps. Count right-aligned at `--t-record` 20px tabular `--ink-mid`.

The widest day is day 4 at 14 births: `14 × 11 − 3 = 151px`, well inside the 301px record column. The scale is therefore **one block = one birth, literally**, at every zoom level — there is no axis because there is no scaling.

```
 1 │ ██ ██                                                    2
 2 │ ██ ██ ██ ██ ██                                           5
 3 │ ██ ██ ██ ██ ██ ██ ██ ██ ██                               9
 4 │ ██ ██ ██ ██ ██ ██ ██ ██ ██ ██ ██ ██ ██ ██               14
 5 │ ██ ██ ██ ██ ██ ██ ██ ██ ██ ██ ██                        11
 ...
13 │ ·································                        0
14 │ ██                                                       1
   ╞══════════════════════════════════════════════════════════
     67 EWES LAMBED · 14 NIGHTS
```

| State | Rendering |
|---|---|
| **Default** | As above |
| **Zero day** | A 2px dotted `--rule` the full record width with `0` printed. Never a blank line — a blank line reads as missing data, a dotted line reads as *nothing happened*, and they are different facts |
| **Comparison (2025)** | Printed as a second set of fourteen rows below a double rule, headed `2025 · 172%`. Never overlaid, never a second colour — the whole point of small multiples is that two colours are unnecessary |
| **Pressed** | Not a target |
| **Disabled / empty season** | Fourteen dotted rows and `NO LAMBINGS RECORDED IN THIS SEASON` |

### 7.12 Text field

Never a rounded box. A **64px line** with the label above and a rule below.

- Label above: `--face-control`, `--t-ctl-sm` 19px, caps, `--ink-mid`.
- Value: `--face-record`, `--t-record` 20px, `--ink-full`, sitting **on** the rule.
- The rule: 2px, full record-column width.

**There is never placeholder text inside a field.** In the dark, a grey placeholder is indistinguishable from an entered value — and in the withdrawal-days field, a placeholder number is a food-chain risk. Hints live in the label, above the line, in the control voice, where they cannot be mistaken for content.

| State | Rendering |
|---|---|
| **Unset** | 2px **dotted** `--rule` (3.52:1) and no glyph. The visible gap |
| **Focused** | Rule goes 2px solid `--ink-full`; 2px `--ink-full` caret. No glow, no fill, no colour change |
| **Filled** | 2px solid `--rule`, value in `--ink-full` |
| **Your entry** (withdrawal days) | Label reads `DAYS — READ FROM THE BOTTLE. YOUR ENTRY.` with `YOUR ENTRY` as a **boxed** stamp. No default, no last-value autofill, no placeholder, no suggestion, no unit pre-fill. Empty until the shepherd types |
| **Struck** | Line through the value; the previous value stays visible in `--ink-low` and the new one prints on the line below |
| **Disabled** | Never |

### 7.13 Word button

The universal control. Min `64 × 64`, 12px inline padding, min-width 64px (so `ALL` is still a legal target). `--face-control` at `--t-ctl` 20px (or `--t-ctl-lg` 22px for a primary), caps for actions, `--ink-full`.

| State | Rendering |
|---|---|
| **Default (primary)** | Fill `--slab`, 2px `--ink-mid` border |
| **Default (in-stream)** | No fill, no border, 2px `--rule` underline the width of the word |
| **Selected** (a filter) | Underline goes 2px `--ink-full`; label `--ink-full` while siblings sit at `--ink-mid` |
| **Pressed** | `--slab-pressed` (filled) or `--row-pressed` (in-stream), 40ms |
| **Destructive** (`STRIKE`) | Label and underline in `--madder-ink` (5.59:1). Never a filled red button — a filled red button is a thing you press by accident |
| **Disabled** | Avoided. Where genuinely impossible, `--ink-low` with a dotted underline and a printed reason beside it |

### 7.14 Bottom sheet

The **only overlay in the app**. Rises from the bottom, `--sheet` `#141416`, 0 radius, **2px `--ink-full` top rule** (15.05:1) instead of a shadow. Height 60% of the viewport (511px) for the keypad, content-height for choosers. **No drag handle** — drag is banned, and a handle that cannot be dragged is a lie. Closing is an 88 × 64 `CLOSE` word-button in the sheet's top-right.

Exactly three contents, ever: the tag keypad + recents; the index; an inline cell chooser. The spine continues *behind* the sheet; the sheet does not cover the margin column above its own top edge.

### 7.15 Recents line

Inside the sheet. Full-width **64px** ruled line, six of them. `412 · penned 2h · twin last year` — tag at `--t-tag` 32px `--ink-full` in the record face, the rest at `--t-record-sm` 18px `--ink-mid` (7.25:1). Pressed: `--row-pressed`.

### 7.16 Page header

Sticky, **44px**, `--t-head` 16px caps 0.10em `--ink-mid`, with a **double rule** (2px + 2px, 3px apart) beneath. Always prints what the book is currently filtered to:
`NIGHT OF 27 JULY 2026 · PAGE 3` · `EWE 412 · ALL SEASONS` · `MEDICINE BOOK · 2026` · `THE PENS · 27 JULY 04:12`.

It never collapses, never parallaxes, never changes height.

### 7.17 Index button and index sheet

`INDEX`, 96 × 64px, pinned bottom-left, `--face-control` `--t-ctl` 20px caps, 2px `--ink-mid` border, fill `--slab`. Opens the index as eight 64px ruled lines in the sheet:

```
TONIGHT          27 JULY · 4 EVENTS
FLOCK            8 EWES
THE PENS         5 OCCUPIED · 2 OVER †
MEDICINE BOOK    2 ACTIVE WITHDRAWALS
REMINDERS        1 OVERDUE †
SEASON 2026      187%
EXPORT           LAST 3 DAYS AGO
SETTINGS
```

Each line is the book under a different filter. There is no tab bar, no rail, no stack, and no back button — pressing `INDEX` and choosing another filter is always one press deeper, never one press *back*.

---

## 8. Per-screen layout direction

Every screen below is **the same page under a different filter.** There is one scrolling ruled document, one spine, one header, one slab, one index button. What changes is what the filter lets through.

---

### Screen 3 — Quick Entry · the 3am screen

*This is the app. Everything else is reading it back.*

**There is no Quick Entry screen, and that is the design.** Opening Shed Book lands you on tonight's page — `NIGHT OF 27 JULY 2026 · PAGE 3` — with tonight's four events already printed above, and **a fresh ruled row already drawn at the bottom, with the auto-captured time already inked in the red margin, stamped `AUTO`.** The pen is already on the page. You are not creating a record; you are filling one in. That single decision is what removes the Save button, removes the empty state, removes the "new entry" modal, and removes the doubt.

The live row sits welded 152px above the bottom edge, directly under the last committed row, which is fully legible one line above it. Below-left: `INDEX`. Below-right: the slab, 160 × 140, currently disabled and reading `TAG FIRST`.

**Tap the TAG cell.** The sheet rises 160ms into the bottom half. The six recents print as full-width 64px ruled lines — `412 · penned 2h · twin last year`, `128 · lambed yesterday · twins`, `305 · rearing a fostered lamb`, `77 · withdrawal 9d`, `219 · not yet lambed`, `12 · barren` — with the keypad's twelve 117 × 84 keys beneath them. One press of a recent line is the whole selection. That is the common case and it costs one tap.

**Or type.** Mid-entry, `12` is on the keypad's display line and the recents list has re-printed as the three matches, in tag order, partial-matching anywhere in the tag:

```
 412   penned 2h · pen 4 · 31h †
 128   lambed yesterday · twins · pen 1 · 9h
  12   barren 2026
──────────────────────────────────────────
 no such tag — write 12 into the book
```

Three things about that block. First, the matches are **ruled lines, not a dropdown** — they are the same 64px row as everything else, in the same place, so there is nothing new to learn under stress. Second, the create-on-the-fly option is **the last printed line, never a modal, never a confirm**: `no such tag — write 12 into the book`. It is always present, even when there are matches, because at 3am the ewe you are holding might genuinely be a tag you have never entered and the app must never stop to make you go and set something up first. Third, the tags are right-aligned on a tabular grid, so `12` sits under the `12` of `412` and `128` and the match is visible as a shape before you have read a single digit.

**The tag lands.** Three things happen inside 120ms, all of them opacity-only, none of them moving: the tag prints into the row in the serif at 44px; the sheet drops; **the slab arms** — its border goes to `--ink-full`, a madder tick prints at its corner, and its label changes to `+ LAMB`. And, invisibly but most importantly, **the row commits to SQLite at that first keystroke.** There is no draft. There is nothing to lose. If the phone dies in the next second, the record says a lambing began for ewe 412 at 03:20 and that is a true and useful thing to have.

**Press the slab.** One stroke prints in the lamb column with a 10ms haptic tick, and the row is now a complete, valid, honestly timestamped lambing:

```
03:20 │ 412  lambing                            │              1
AUTO  │      SINGLE (COUNTED)                   │
```

Three taps. About six seconds. Well inside the fifteen.

**Then the crucial part: the row stays open.** A lambing is a forty-minute window, not a form-filling event. You put the phone in your pocket, deliver the second lamb, take the phone out again, and **press the same slab without reselecting anyone.** A second stroke prints. The derived type re-prints as `TWIN (COUNTED)`. Ten minutes later, a third: `TRIPLET (COUNTED)`. **Nobody ever chooses "triplet" from a list.** The birth type is a count of things that happened, labelled as derived, which is exactly what safety rule 4 asks for — turned from a validation routine into the structure of the interaction. The row closes on its own at the season's configured window (default 90 minutes of no strokes) or when you press `CLOSE ROW`, and closing is itself a printed, timestamped line.

**Everything else is optional and prints as a visible gap.** Below the live row, inside the thumb band, sit the optional cells as 64px inline targets: the ease group (five 64 × 64 buttons), sex per lamb, the four care checks, the assistance detail, the note. Unset cells print a dotted rule and a `NOT RECORDED · SKIPPABLE` label — the record is honest about its own thinness instead of nagging you to fill it. A footer line beneath prints: `EVERY CELL BELOW MAY BE LEFT BLANK. A BLANK CELL PRINTS AS A GAP, NOT AS AN ERROR.`

**The event buttons** — `LAMBING · TREATMENT · NOTE · DEATH · MOVE PEN` — are five in-stream word buttons on a single 64px ruled line directly above the live row, at the top of the thumb band. Lambing is pre-selected on tonight's page because that is what tonight is; pressing another changes what the open row *is*, and the change is printed, not silent.

**Deferred entry.** Tap the time cell in the margin. The margin re-prints as two lines: `07:02 †edited` on top and `event 03:20 as entered` beneath. Both times stay. The `AUTO` stamp is replaced by `EDITED`. Safety rule 5, with nothing hidden.

**Striking.** `STRIKE` is an in-stream word button in `--madder-ink` on the row's chooser. Pressing it draws a 3px madder line left-to-right across the row over 180ms and prints `STRUCK 03:41` in the margin. **The row does not move, collapse, fade or disappear.** It stays where it was, legible at 5.75:1, tonight, next year, and in the CSV. And a mis-pressed slab is not undone by a decrement — the lamb cell opens a chooser reading `LAMB 3 — STRIKE THIS LAMB`, which rules a line through the third stroke and prints `TWIN (COUNTED, 1 STRUCK)`. There is no minus button on the tally, because a tally that can go down is not a tally.

**The contradiction case.** If a birth type has been *declared* (via `CHANGE TYPE`, the deferred-entry path) as triplet and only two strokes exist, a `?` prints in the margin in madder and a 2px madder underline appears under the type cell. Tapping the `?` offers exactly two options and no third: `CHANGE THE BIRTH TYPE` or `LEAVE IT — TWO IS RIGHT`. Choosing the second prints `QUERIED · LEFT AS ENTERED 03:47` and the query mark stays. The app never picks.

---

### Screen 7 — Pen Board · the digital whiteboard

*The screen you read from six feet away with a head torch, while carrying something.*

The obvious answer is a 3 × 4 grid of tiles. This system does not have tiles, and refusing them is the right call rather than a stylistic tax. A grid forces the eye to zig-zag — across, down, back, across — and every hop is a chance to read pen 7's hours against pen 8's occupant. **A ruled column does not zig-zag.** So the pen board is twelve ruled rows, one per pen, 88px each, in the same document as everything else, and it is genuinely more legible at arm's length than a grid would be.

Header: `THE PENS · 27 JULY 04:12 · 5 OCCUPIED · 2 OVER †`. Beneath it, the spine, and twelve rows. Eight fit above the bottom band; the remaining four are one scroll away, and the board is **sorted by hours descending by default**, so the pens that need you are the pens you can already see. (An in-stream `SORT BY PEN NUMBER` word button restores physical order for when you are walking the row of pens.)

Each row carries three columns and nothing else, and each column is a straight vertical read down the page:

```
      │  4   412  ┃┃                              31h  OVER †
══════╪═══════════════════════════════════════════════════════
      │  5   305  ┃┃┃                             26h  OVER †
══════╪═══════════════════════════════════════════════════════
      │  3    91  ┃                               18h
──────┼───────────────────────────────────────────────────────
      │  1   128  ┃┃                               9h
──────┼───────────────────────────────────────────────────────
      │  2   — empty —
──────┼───────────────────────────────────────────────────────
```

- **Pen number** at 44px tabular, hard against the spine. This is the number you shout across the shed and it is the biggest thing in the row.
- **Occupant**: ewe tag at 32px tabular, then the lambs as **tally marks**, not a digit. Two strokes means two lambs. You count them at a glance without reading, which is the entire argument for tallies, and it is the same mark the slab prints — one visual language for "how many lambs", used identically in the entry flow and the board.
- **Hours** at 32px tabular, right-aligned hard against x=377, forming a clean numeric column down the right edge. Under threshold: `--ink-mid`. Over: `--ink-full`.

**The over-threshold badge, without colour alone.** Pens 4 (412, 31h) and 5 (305, 26h) are past the user's 24h turn-out threshold. Four independent channels mark them, and any three of the four are sufficient:

1. **A word.** `OVER` as a boxed stamp — 14px caps, tracked, `--ink-full` at 16.19:1.
2. **A mark.** `†` in the margin cell, 24px, the same dagger used for every "look at this" in the app.
3. **Geometry.** The rule beneath the row **doubles** — two 2px lines, 3px apart. This is the strongest signal of the four, because it is visible in peripheral vision from across the shed at a distance where you cannot yet read `OVER`, and because a doubled rule is the printer's convention for a total, a boundary, a thing that has come to an end.
4. **Ink density.** The hours figure lifts from `--ink-mid` (7.80:1) to `--ink-full` (16.19:1).

Colour appears only in the dagger. Turn the phone monochrome, put a red torch on it, hand it to someone with deuteranopia, and the board reads identically.

Empty pens print `— empty —` in `--ink-low` and are still rows and still targets — because when you are carrying a ewe you need to see where the space *is* at least as urgently as where the sheep are, and a grid that hides its holes is useless for that.

**One-tap move and turn out.** Tapping any row opens the inline chooser in the sheet with two word buttons at 22px: `TURN OUT` and `MOVE TO…`. `TURN OUT` writes immediately and the row **re-prints in place** as `TURNED OUT 04:12` in `--ink-low` — it does not animate away, does not collapse, does not slide. It stays on the board for the rest of the night, because a pen you emptied ninety seconds ago is information, and because nothing in this app disappears from under your hand. `MOVE TO…` shows the empty pens as 64px lines; one tap completes the move, and both the old and new pen rows print the movement with its time.

The corner slab on this page reads `MOVE`, and pressing it opens the same chooser pre-loaded with the most recently touched ewe — which, at 04:12, is nearly always the one you are holding.

---

### Screen 1 — Flock

The book **grouped by ewe** rather than by night: one 88px row each, sorted by most recently touched, tags right-aligned on a fixed three-digit tabular column so `12`, `77` and `91` sit directly under the units of `412`, `128` and `305` and the eye runs straight down the numerals. Each row is a tag at 32px, a one-line summary at 18px `--ink-mid`, and a trailing state word plus figure: `412 · 3 seasons · avg 2.0 · assisted twice — PEN 4 31h †` · `128 · lambed yesterday · twins — PEN 1 9h` · `305 · rearing a fostered lamb — PEN 5 26h †` · `77 · Alamycin LA · clears 12 Aug — WITHDRAWAL 9d` · `219 · not yet lambed · scanned twins — TO LAMB` · `12 · barren 2026 — BARREN` · `340 · not yet lambed — TO LAMB` · `91 · lambed · single — PEN 3 18h`. The filters are not chips — chips are containers with a radius, and this system has neither — but a single horizontally scrolling 64px ruled line of words with counts printed after them: `ALL 8 · NOT YET LAMBED 2 · IN THE PENS 4 · UNDER TREATMENT 1 · BARREN 1`. The active filter carries a 2px `--ink-full` underline; the rest sit at `--ink-mid`. Search is the same keypad sheet as everywhere else, with a `TEXT` toggle for note search. Quick-add is the corner slab, reading `+ EWE`.

### Screen 2 — Ewe Card · 412

The book filtered to one animal: `EWE 412 · ALL SEASONS`. The one-line summary is printed **first, above everything, on its own 64px row in the record face at 20px** — *"3 seasons · avg 2.0 · assisted twice · prolapsed 2025"* — because the spec says it must be visible before anything else and the single-stream model makes that literal rather than a design flourish. Beneath it, a current-status row: `IN PEN 4 · 31h †` with the dagger and the doubled rule, exactly as it renders on the pen board — the same fact wears the same clothes wherever it appears. Then the seasons, most recent first, each under a printed sub-head and a double rule: `SEASON 2026` → the 03:20 lambing row with `TRIPLET (COUNTED)`, three tally marks, `EASE 3`, `ASSISTED`, and three lamb rows (`ewe lamb · alive · 4.1kg`, `ram lamb · alive · 3.8kg`, `ram lamb · dead`); `SEASON 2025` → `TWINS · EASE 2 · PROLAPSED AFTER LAMBING`; `SEASON 2024` → `TWINS · EASE 1`. Notes print as ruled rows with their own timestamps in the margin — a note is an event like any other. The four actions sit as in-stream word buttons on one 64px line inside the thumb band: `RECORD EVENT · TREAT · MOVE PEN · ADD NOTE`. The slab reads `+ NOTE`. Any struck entry in her history is still here, ruled through, at 5.75:1 — which is the whole point of year two.

### Screen 4 — Lambing Entry · ewe 412

Not a screen. **The live row from screen 3, expanded in place**, still welded to the bottom of tonight's page, with the previous rows still visible above it. The margin prints `03:20` over `AUTO`, and tapping it re-prints as `07:02 †edited` / `event 03:20 as entered`. Birth type is not a control: it prints as `TRIPLET (COUNTED)` beside three tally marks, with `COUNTED` as an unboxed stamp, and it changes only by pressing the slab again. Ease is the five 64 × 64 buttons with `3` selected — filled `--slab`, 2px `--ink-full` border, madder underline, and `EASE 3 · SOME ASSISTANCE` printed to the right. The three lambs print as three indented 64px sub-rows under the parent row, each with its own margin time, each carrying sex, status and weight as inline 64px cells: `LAMB 1 · EWE LAMB · ALIVE · 4.1kg`, `LAMB 2 · RAM LAMB · ALIVE · 3.8kg`, `LAMB 3 · RAM LAMB · DEAD` — with `DEAD` as a word in full ink and **no colour whatsoever**. The four care checks are 64px lines that stamp a time when pressed: `NAVEL DIPPED · DONE 03:26`. Assistance detail and the note are text fields with the label above and a dotted rule below. Every unset cell prints its gap and its `NOT RECORDED · SKIPPABLE` label, and the section footer prints the sentence about blank cells. There is no Save button anywhere on this screen and nothing to lose.

### Screen 5 — Lamb Card

`LAMB 1 OF 412 · BORN 03:20 TODAY`. A summary row first, in the record face: *"ewe lamb · 4.1kg · alive · born 03:20 today"*. Then the parentage, on two ruled rows that are the heart of this screen: `BIRTH DAM 412 — PERMANENT` (the word `PERMANENT` as a boxed stamp; the cell is not a target and cannot be edited, ever) and `REARING DAM 305 — FOSTERED 06:10 †`. Pet-lamb status is a boxed stamp toggled by a word button, and the feed count is the number stepper — but pressing `+` also **prints a timestamped row into the stream**: `FEED 4 — 06:40`. Every feed is an event; the count is just their total. Actions on one 64px line: `TAG · WEIGH · FOSTER · RECORD DEATH`. `RECORD DEATH` opens the cause chooser (starvation, hypothermia, watery mouth, joint ill, crushed, stillborn, unknown, other — editable) as ruled sheet lines, and writes a dated row. It does not turn the card red, it does not grey it out, and it does not remove the lamb from the ewe's litter count. It prints the word `DEAD` and a date.

### Screen 6 — Foster

Not a screen either — **an inline chooser on the lamb's rearing-dam cell.** Tap 1: the `REARING DAM` cell on lamb 3 of ewe 412 (a 64px target). The sheet rises with the same six recents and the same keypad. Tap 2: `305`. Done — two taps, which is the number the spec says this flow must not exceed, and the reason it works is that it reuses the identical selection component as everything else in the app rather than inventing a foster flow. What prints is the argument: the row re-prints as `REARING DAM 4̶1̶2̶ → 305 · FOSTERED 06:10 †` with a struck madder line through the old value, and directly above it, immutable, `BIRTH DAM 412 — PERMANENT`. **The birth dam is a cell with no target on it**; there is no path through the UI that changes it, which is a stronger guarantee than a warning dialog. Both ewes' cards re-print immediately: 412's litter still reads three lambs born, 305's card gains a line reading `REARING 1 FOSTERED · FROM 412 · 06:10`. The lamb is counted as born to one ewe and reared by another, forever, in the record and in the CSV, because that is the truth and because the season summary's arithmetic depends on the distinction.

### Screen 8 — Treatments

The medicine book is not a separate view — it is **the book filtered to treatments**, `MEDICINE BOOK · 2026`, one ruled row per dose, chronological, in the same document. The entry form is the live row with different cells, and one cell is unlike any other in the app. Product name, dose, route and batch number are ordinary text fields with labels above and rules below. The withdrawal field is printed **blank, under a dotted rule, labelled `DAYS — READ FROM THE BOTTLE. YOUR ENTRY.`** with `YOUR ENTRY` as a boxed stamp. There is no default, no suggestion, no last-value autofill, no placeholder number, no unit hint, and no "same as last time" — and the reason is printed in the label rather than in a tooltip, because a placeholder number in that cell is a food-chain risk. `REPEAT LAST TREATMENT` is a prominent word button that copies product, dose, route and batch, and **explicitly leaves the withdrawal days blank**, printing `DAYS NOT COPIED — READ THE BOTTLE` where the value would be. Active withdrawals print above a double rule as countdown rows: `77 · ALAMYCIN LA · CLEARS 12 AUG 2026 │││││││││ 9d` and `219 · FOOTBATH · CLEARS 4 AUG ││ 1d †` with `LAST DAY`, its dagger, and its doubled rule. The app states dose and date back to the shepherd and never comments on either.

### Screen 9 — Reminders

The book filtered to **rows that have not been written yet** — the future part of the page, which is a genuinely useful idea rather than a conceit. Overdue rows print at the top, above the ordinary ruling, each with a `†` in the margin: `NAVEL DIP · LAMB 3 OF 412 · 40 MIN AGO †`. Then due, under the header `DUE`: `COLOSTRUM WINDOW · LAMB 3 OF 412 · IN 20 MIN` and `TURN OUT PEN 4 · EWE 412 · NOW · 31h †`. Then a **double rule marked `NOT YET WRITTEN`**, and beneath it the upcoming: `WITHDRAWAL ENDS · EWE 77 · 12 AUG`, `TAG BY · 128'S LAMBS · 6 AUG`. Each row carries two in-stream word buttons in the thumb band when tapped: `DONE` and `MUTE`. `DONE` prints a timestamp and moves the row into tonight's page as a real event. `MUTE` **does not remove it** — it prints `MUTED 03:44` and strikes the row, which stays in the list at 5.75:1, because a muted reminder is a decision you made and you may want to see it at 6am. Nothing nags twice: a fired reminder never re-fires, and there is no badge count anywhere in the app.

### Screen 10 — Season Summary · 2026

Not a dashboard — **the book's totals footer**, printed after a double rule, in exactly the typographic manner of a ledger's foot. The headline figure prints at `--t-figure` 56px in the record face — `187%` — and directly beneath it, at 19px in the control face, its definition, visible without tapping anything: `LAMBS BORN PER EWE PUT TO RAM` with a `CHANGE DEFINITION` word button beside it, because a lambing percentage whose definition is hidden is a number two shepherds will argue about. Then the rest as ruled rows with figures right-aligned in a tabular column: `AVERAGE LITTER 1.9` · `BARREN RATE 4%` · `ASSISTED 12%`. Losses print as their own small block under a sub-head, as words and counts, never as a pie chart and never in colour: `STARVATION 2 · HYPOTHERMIA 1 · STILLBORN 3 · CRUSHED 1`. The lambing spread is fourteen 44px ruled rows built from the same filled blocks as the lamb tally — one block per birth, no axis, no gridline, no animation — closed by a double rule and `67 EWES LAMBED · 14 NIGHTS`. The 2025 comparison prints as a **second set of fourteen rows** below, headed `2025 · 172%`, never overlaid and never in a second colour, which is the entire argument for small multiples and also the reason this system does not need a chart library.

### Screen 11 — Export

A short page of word buttons and a long printed footer. Six actions as 64px in-stream lines with the shape stated in the record face beneath each: `CSV — ONE ROW PER LAMB`, `CSV — ONE ROW PER EWE`, `CSV — ONE ROW PER TREATMENT`, `PDF — FLOCK BOOK 2026`, `PDF — MEDICINE RECORD`, `JSON — FULL BACKUP`. All go to the system share sheet; nothing leaves the device any other way. Above them, the honest status in the record face: `LAST EXPORTED 3 DAYS AGO · 41 ENTRIES SINCE`, and beneath it, at 20px in full ink and not as a dismissible tip: `A LOST PHONE IS LOST DATA. THERE IS NO CLOUD COPY.` Every CSV carries a `struck` and a `struck_at` column and **every struck row is included and marked**, because an export that quietly drops the strikes would undo the one thing this app is for. The printed footer, present on every PDF and as a comment row in every CSV: `SHED BOOK IS A NOTEBOOK, NOT A COMPLIANCE RECORD. IT IS NOT A HOLDING REGISTER, A MOVEMENT RECORD, OR A STATUTORY MEDICINE BOOK. STRUCK ENTRIES ARE INCLUDED AND MARKED STRUCK. NOTHING HAS BEEN REMOVED.` The gentle end-of-day export prompt is a printed line at the foot of tonight's page, once a day, dismissible for the season — never a modal, never a notification.

### Screen 12 — Settings

Ruled rows, one setting per row, every control a word button or a text field. Units `KG / LB` and temperature `°C / °F` as two-word segmented lines. Terminology as five text fields with the label above — `EWE`, `GIMMER`, `SHEARLING`, `THEAVE`, `HOGGET` — freely editable, because these vary by county let alone by country, and whatever the shepherd types is what the app then prints everywhere including the exports. Reminder intervals as number steppers. Season start date and a `SWITCH SEASON` line. Theme as two word buttons, `DARK` and `RED-SHIFT`, and directly beneath them the line that makes the whole system legible: `THE RECORD IS SET IN THE BOOK FACE. THE BUTTONS ARE SET IN THE MACHINE FACE. IF IT IS SERIF, IT HAPPENED. IF IT IS SANS, IT IS A THING YOU CAN PRESS.` — plus the one documented exception, that the keypad digits are set in the book face so the digit you press is the shape that prints. `WRITING HAND · RIGHT / LEFT` mirrors the slab and the index button and states that the margin does not move. At the very bottom, under a double rule, the two destructive actions — and they are the only place in the product where the word *delete* is used honestly: `DELETE SEASON 2026` and `DELETE EVERYTHING`, each requiring the season year or the word `EVERYTHING` typed into a field, each printed above the sentence `THIS IS THE ONLY DELETE IN SHED BOOK. IT IS NOT A STRIKE. THE ROWS DO NOT STAY.`

---

## 9. The 3am compliance table

| Spec §5 rule | The mechanism in Indelible |
|---|---|
| **One thumb, one hand** | Two pinned thumb anchors and nothing else: the 160 × 140 slab bottom-right, `INDEX` 96 × 64 bottom-left, both mirrorable. The live row is welded 152px above the bottom edge so the page reads *upward* into history while the thumb only ever works at the bottom. Binding rule: nothing above 560px from the bottom is ever required to complete an event (§4.5) |
| **Gloves, wet hands, phone in a bag — min 60 × 60pt** | Smallest target in the entire app is **64 × 64**. Slab 160 × 140, keypad key 117 × 84, every row 64 or 88, word buttons min-width 64 with 12px padding, the 68 × 64 margin cell is itself a target. Audited component by component in §4.5 |
| **Banned: swipe-to-delete** | **There is no delete.** Not banned — absent. Striking is a visible word button that draws a line. The concept of erasure does not exist in the product (§1.1, Rule 1) |
| **Banned: drag** | No drag anywhere. Fostering is two taps on a cell chooser, not a drag between ewes. Moving a pen is two taps on a list. The bottom sheet has **no drag handle** and closes via an 88 × 64 `CLOSE` button |
| **Banned: long-press-only** | No long-press is bound to anything. The stepper explicitly has **no repeat-on-hold** — one press, one step |
| **Banned: pinch / force touch** | The chart has no zoom because it has no scale — one block is one birth at all times. No force-touch bindings exist |
| **Cold fingers, poor capacitance** | No sliders anywhere; the stepper replaces every one. No small drag handles (no handles at all). 8–12px minimum gaps between adjacent targets. Targets never shrink on press — the press state is a **fill change only**, no scale, no ripple, because a target that shrinks under a cold thumb is a target you miss |
| **Head torch or total darkness; dark is default** | Dark is the only default; there is no light theme and no system-follow. `--page` `#0A0A0B`, one step off black to limit halation for the ~47% of adults with some astigmatism. **The first painted frame is the page colour** — no splash, no logo, no white flash on either platform (§5.2) |
| **High-contrast type, min 18pt body** | Record body **20px**, control floor **19px**, absolute floor 18px, everything measured: **every text pair ≥ 4.5:1**, with `--ink-full` at 16.19:1 and `--ink-mid` at 7.80:1 on the page (both AAA). Rules raised from 1px to **2px** because a hairline shimmers or vanishes on a mid-range Android at low brightness and the ruling here is load-bearing |
| **Optional red-shift mode** | A six-value override (§2.6). It is nearly a no-op *by construction* — nothing was ever encoded by hue, so switching themes breaks nothing. Every red-shift text pair is ≥ 4.5:1; `--ink-full` is AAA on all five surfaces. Where the hue channel disappears, the strike line **doubles** so form takes over from colour |
| **Under 15 seconds from unlock to a saved lambing** | The row is **already drawn** when the app opens, with the auto time already inked. Tap TAG → tap a recent → press the slab. **Three taps, about six seconds**, and the record committed at tap two, not tap three |
| **Zero interruptions** | No ads, no rating prompt, no onboarding, no what's-new, no notification permission nag, no badge count, no toast, no snackbar, no modal dialog anywhere in the app. The one recurring prompt permitted by the spec — the export reminder — is a printed line at the foot of tonight's page, once a day, dismissible for the season |
| **Assume the phone dies; every write commits immediately; no draft state** | **There is no Save button in this app, on any screen.** The row commits to SQLite at the first keystroke of the tag; every later cell is its own immediate write; every care check writes the time you pressed it. This is why the live row is drawn *before* you touch anything and why the row above it stays visible — you can see the last thing you wrote, in ink, one line up, which removes the 3am failure mode. That failure mode was never slowness. It was doubt |

### Safety rules (spec §12) — where each one lives

| Rule | Mechanism |
|---|---|
| **1. Never default a withdrawal period** | The days cell prints blank under a dotted rule labelled `DAYS — READ FROM THE BOTTLE. YOUR ENTRY.` No default, no placeholder, no last-value autofill, no unit hint. `REPEAT LAST TREATMENT` copies everything **except** the days and prints `DAYS NOT COPIED — READ THE BOTTLE`. The text-field component forbids placeholder text system-wide (§7.12) so this cannot regress by accident |
| **2. Never give veterinary advice** | No dose suggestions, no cause inference, no thresholds the app chose, no "you should" copy anywhere. The only opinion the app is permitted to hold is the turn-out threshold, and the shepherd sets it. Ease descriptions are the spec's own generic husbandry vocabulary, printed as labels, never as recommendations |
| **3. Never present as a compliance record** | Printed footer on every PDF and as a comment row in every CSV (§ screen 11), stating it is a notebook, naming the three things it is not, and stating that struck entries are included |
| **4. Never silently correct** | Birth type is **derived from the tally and labelled `(COUNTED)`**, so the most common contradiction is structurally impossible rather than caught by validation. Where a type has been declared and disagrees, a madder `?` prints in the margin, the row stays exactly as entered, and tapping the mark offers two options — change it, or leave it — and the app never picks |
| **5. Timestamps are honest** | The margin carries the time and its provenance stamp: `AUTO` for auto-captured, `EDITED` with a `†` for edited, and an edited row prints **both** times — `07:02 †edited` over `event 03:20 as entered`. The original is never overwritten, in the record or in the export |

---

## 10. The CSS `:root` token block

Complete and ready to paste into the mockup.

```css
:root {
  color-scheme: dark;

  /* ============ 1 · INK AND PAPER — dark, the default theme ============ */
  /* surfaces */
  --page:             #0A0A0B;   /* L 0.00306 — first painted frame, never pure black */
  --row-pressed:      #131315;   /* L 0.00658 */
  --sheet:            #141416;   /* L 0.00707 */
  --slab:             #1C1C1F;   /* L 0.01176 — buttons are the only filled shapes */
  --slab-pressed:     #2A2A2E;   /* L 0.02345 */

  /* three ink densities + one hue */
  --ink-full:         #EDE8DC;   /* 16.19:1 on page · AAA */
  --ink-mid:          #A8A296;   /*  7.80:1 on page · AAA */
  --ink-low:          #8F8A7E;   /*  5.75:1 on page · AA — struck text stays legible */
  --rule:             #6B675F;   /*  3.52:1 · NON-TEXT ONLY, never carries a glyph */
  --madder-rule:      #B94A40;   /*  3.88:1 · NON-TEXT ONLY — the spine */
  --madder-ink:       #D4685C;   /*  5.59:1 on page · AA — strike, STRUCK, ?, † */

  /* semantic aliases — components reference these, never the raw values */
  --ink-record:       var(--ink-full);
  --ink-secondary:    var(--ink-mid);
  --ink-struck:       var(--ink-low);
  --ink-gap:          var(--ink-low);
  --ink-stamp:        var(--ink-full);
  --ink-control:      var(--ink-full);
  --ink-control-off:  var(--ink-mid);
  --spine:            var(--madder-rule);
  --mark-strike:      var(--madder-ink);
  --mark-query:       var(--madder-ink);
  --mark-dagger:      var(--madder-ink);
  --mark-double:      none;      /* red-shift flips this to `block` (2nd strike line) */

  /* ============ 2 · TYPE ============ */
  --face-record:  "Source Serif 4","Source Serif Pro",Charter,"Bitstream Charter",
                  ui-serif,"New York","Noto Serif",Georgia,serif;
  --face-control: "Source Sans 3","Source Sans Pro",ui-sans-serif,"SF Pro Text",
                  Roboto,"Segoe UI",system-ui,sans-serif;

  --w-record:          390;  /* one step lighter than light-mode — dark type blooms */
  --w-record-strong:   420;
  --w-control:         520;
  --w-control-strong:  600;

  --t-figure:     56px;  --lh-figure:     60px;  /* 187% */
  --t-tag-xl:     44px;  --lh-tag-xl:     48px;  /* pen number, live-row tag */
  --t-tag:        32px;  --lh-tag:        36px;  /* row tag, keypad digit, hours */
  --t-slab:       26px;  --lh-slab:       28px;  /* + LAMB */
  --t-ctl-lg:     22px;  --lh-ctl-lg:     26px;
  --t-record:     20px;  --lh-record:     28px;  /* THE RECORD BODY */
  --t-ctl:        20px;  --lh-ctl:        24px;
  --t-ctl-sm:     19px;  --lh-ctl-sm:     23px;  /* control floor */
  --t-record-sm:  18px;  --lh-record-sm:  24px;  /* record floor */
  --t-margin:     18px;  --lh-margin:     22px;
  --t-head:       16px;  --lh-head:       20px;
  --t-stamp:      14px;  --lh-stamp:      17px;  /* never the sole carrier of meaning */

  --track-stamp:   0.14em;
  --track-head:    0.10em;
  --track-slab:    0.06em;
  --track-ctl:     0.01em;
  --track-record:  0.006em;  /* reopens counters against halation on dark */

  --figures: tabular-nums lining-nums;  /* every numeral, record and control alike */

  /* ============ 3 · SPACE ============ */
  --s-1:   4px;  --s-2:   8px;  --s-3:  12px;  --s-4:  16px;  --s-5:  20px;
  --s-6:  24px;  --s-7:  32px;  --s-8:  40px;  --s-9:  48px;  --s-10: 64px;
  --s-11: 88px;  --s-12: 132px;

  /* ============ 4 · GEOMETRY ============ */
  --rule-w:           2px;      /* never 1px — a hairline vanishes at low brightness */
  --rule-strike-w:    3px;
  --rule-double-gap:  3px;
  --rule-dot:         2px 6px;  /* dash pattern — an unset field is always dotted */
  --radius-record:    0;
  --radius-slab:      2px;
  --radius-sheet:     0;
  --shadow:           none;     /* there are no shadows in this system */

  --gutter:         16px;
  --margin-rule-x:  68px;   /* the spine — continuous, never mirrors */
  --record-x:       76px;
  --record-w:       calc(100% - var(--record-x) - var(--gutter));

  --row-h:          64px;
  --row-h-tall:     88px;
  --row-h-chart:    44px;
  --head-h:         44px;
  --bottom-band:   152px;   /* slab 140 + 12, above the safe-area inset */

  --tap-min:        60px;   /* spec floor */
  --tap:            64px;   /* system floor — nothing is smaller than this */
  --slab-w:        160px;
  --slab-h:        140px;
  --index-w:        96px;
  --key-w:         117px;
  --key-h:          84px;
  --tally-w:         8px;
  --tally-h:        30px;
  --tally-gap:       3px;
  --daymark-w:       2px;
  --daymark-h:      12px;

  --zone-thumb:    320px;   /* from the bottom — everything required lives here */
  --zone-reach:    560px;   /* nothing above this is ever required */

  /* ============ 5 · MOTION ============ */
  --motion-press:   40ms;   /* fill only — never scale, never ripple */
  --motion-ink:    120ms;   /* opacity only — ink appears, it does not travel */
  --motion-sheet:  160ms;
  --motion-strike: 180ms;   /* the only animation with a direction */
  --ease-out:      cubic-bezier(0.2, 0, 0, 1);
  --ease-strike:   linear;
}

/* ============ RED-SHIFT ============ */
/* Six surfaces, six inks. Everything else inherits, because nothing was ever
   encoded by hue. Peak luminance is halved through the platform brightness API,
   not a CSS filter — a filter would dim the press feedback and lie about the display. */
:root[data-theme="red-shift"] {
  --page:          #080605;   /* L 0.00193 */
  --row-pressed:   #0F0B09;
  --sheet:         #120D0A;
  --slab:          #1A1310;
  --slab-pressed:  #261C17;

  --ink-full:      #E4A896;   /*  9.96:1 · AAA */
  --ink-mid:       #B8846F;   /*  6.32:1 · AA  */
  --ink-low:       #A4756A;   /*  5.13:1 · AA  */
  --rule:          #8A6053;   /*  3.73:1 · non-text */
  --madder-rule:   #C9564A;   /*  4.73:1 · non-text */
  --madder-ink:    #F2C4AE;   /* 12.79:1 · AAA — brightest mark on the page, because
                                 with no hue channel left, luminance carries it */
  --mark-double:   block;     /* the strike line doubles when hue can no longer help */
}

/* ============ LEFT-HANDED ============ */
/* The slab and the index button swap. The spine does not move — a book's margin
   is on the left. */
:root[data-hand="left"] {
  --slab-side:  left;
  --index-side: right;
}
:root { --slab-side: right; --index-side: left; }

/* ============ REDUCE MOTION ============ */
/* The 40ms press flash survives: it is a fill change under a thumb, not motion,
   and it is the only visual confirmation available through a glove and a bag. */
@media (prefers-reduced-motion: reduce) {
  :root {
    --motion-ink:    0ms;
    --motion-sheet:  0ms;
    --motion-strike: 0ms;
    --motion-press:  40ms;
  }
}

/* ============ BASE ============ */
html, body { background: var(--page); }
body {
  font-family: var(--face-record);
  font-variant-numeric: var(--figures);
  font-weight: var(--w-record);
  font-size: var(--t-record);
  line-height: var(--lh-record);
  letter-spacing: var(--track-record);
  color: var(--ink-record);
  font-style: normal;             /* nothing in this system is ever italic */
  -webkit-text-size-adjust: 100%;
  padding-bottom: env(safe-area-inset-bottom);
}
button, .control, .stamp, .word-btn, label {
  font-family: var(--face-control);
  font-weight: var(--w-control);
  font-variant-numeric: var(--figures);
  letter-spacing: var(--track-ctl);
  border-radius: var(--radius-slab);
  min-height: var(--tap);
  min-width:  var(--tap);
}
```

---

## 11. Acceptance tests for this system

Anything shipped under Indelible must pass all of these, and each is checkable in a review without a debate:

1. **The strike test.** Every destructive-looking action in the app draws a line and prints a time. Search the codebase for `DELETE`, `remove`, `splice`, `hidden`; the only legal hits are Settings' two season-level actions.
2. **The ruler test.** Put a ruler on the mockup at 560px from the bottom. Nothing required to record an event sits above it.
3. **The 64 test.** Every target ≥ 64 × 64. No exceptions, not even the margin dagger.
4. **The monochrome test.** Screenshot every screen, desaturate it fully, and read it. Nothing has become ambiguous — over-threshold, struck, dead, queried and selected all still read.
5. **The 1/7 test.** Every tag on the flock and pen pages, at 32px, at 30% brightness, through a sandwich bag. If `412` could be `417`, the face is wrong.
6. **The two-voice test.** Point at any element and say "record" or "control" without hesitating. If you hesitate, its face is wrong.
7. **The Save test.** Search for the string `Save`. Zero hits in the UI.
8. **The placeholder test.** No input in the app renders placeholder text inside the field. Zero hits on `placeholder=`.
9. **The first-frame test.** Cold launch on both platforms, recorded at 240fps. Frame one is `--page`. No white, no logo, no fade.
10. **The measurement test.** Re-run the contrast script (`§2.1`) against the shipped token block. Every text pair ≥ 4.5:1 in both themes. This is rule 4 and it is not negotiable by taste.

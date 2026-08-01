# Strip Bay — Design System Specification

**Shed Book · Direction 1 of 3 · v1.0**
Offline-only lambing notebook, iOS + Android. Dark-primary, one-thumb, 3am.

---

## 0. How to read this document

**Units.** All sizes are in **points (pt)**. On iOS 1 pt = 1 CSS px at 1×; on Android 1 pt = 1 dp. The mockup is built at **390 × 844** (iPhone 14/15 logical frame). Secondary target 412 × 915 (Pixel 8) — the rail stays 88 pt, the board column widens from 302 to 324, nothing else changes.

**Canonical clock.** The twelve screens are **one night, not one instant**. This is deliberate: the product is used at 4am for entry and at breakfast for read-back, and the mockups should show both.

| Screens | Clock |
|---|---|
| 1, 2, 3, 4, 7, 9 | **04:00, Monday 3 August 2026** |
| 5, 6 | **06:15, Monday 3 August 2026** |
| 8, 10, 11, 12 | **09:40, Monday 3 August 2026** |

Everything in the brief's dataset resolves against this clock: 412 lambed 03:20 (40 min ago), penned 31 h (entered 21:00 Sat 1 Aug), navel dip for lamb 3 overdue 40 min, colostrum window closes 04:20, 77's withdrawal clears 12 Aug (9 days), 219's footbath clears 4 Aug (1 day), 128's lambs tag-by 6 Aug.

**One deliberate contradiction is left in the data.** The brief records lamb 3 of 412 as **dead** (screen 4, 04:00) and then **fosters lamb 3 to ewe 305** (screen 6, 06:15). The system does not resolve this and does not block it. It clips a red `CHECK` tab on the strip reading `LAMB 3 · RECORDED DEAD 04:07 · FOSTERED 06:15 — CHECK`. That is safety rule 12.4 working exactly as written: flagged, never silently fixed. Use it.

**Invented data.** Pens 6–12 need occupants the brief does not supply. Mockup-only additions: pen 7 = ewe **156** + 2 lambs, 4 h; pen 9 = ewe **88** + 1 lamb, 12 h; pen 11 = ewe **271** + 2 lambs, 21 h. Pens 2, 6, 8, 10, 12 empty. No other data is invented anywhere.

---

## 1. Thesis and principles

### 1.1 The thesis

A list is a filing decision. A shed is a place.

Air traffic control kept paper flight progress strips for forty years after everyone predicted their death, because **position carries meaning**. Each aircraft is a strip in a holder; the arrangement *is* the mental picture; controllers do not search, they look. Shed Book is a strip bay. Every animal in play is one horizontal strip in a labelled bay. You never look **for** her. You look **at the wall**.

Two inversions make this beat the whiteboard it replaces.

**First: strips are never wiped, they are FILED.** Turning out slides a strip off the board and into the book. By morning the board is clean and not one record is lost. That is the single thing paper genuinely cannot do, and it is the whole argument for the app.

**Second: dark-board discipline, borrowed from nuclear control rooms.** A bay with nothing wrong in it renders as **flat black** — a header, a count of zero, no fill. On a quiet night the board is nearly empty, and that emptiness *is the reading*. The app is telling you, in the strongest visual language available, go back to bed.

### 1.2 The four rules that settle any future argument

When two people on this team disagree about a screen, these decide it, in order.

> **R1 — POSITION BEFORE TEXT.**
> Which bay a strip sits in must tell you its state before you read a single character. If a design needs a label to say what the position already had to say, the position is wrong. Corollary: **there is no "All" view.** A view that contains everything contains no information.

> **R2 — NOTHING IS EVER PENDING.**
> Every press is a committed SQLite write with its own timestamp. Therefore: no Save button, no draft, no OK/Cancel dialog, no "unsaved changes" state, no form that must be completed. The word *Save* does not exist in this product's vocabulary. Correction is a **new write that supersedes and is visible alongside the old one** — never a silent edit, never a destructive undo.

> **R3 — BLACK MEANS FINE.**
> Anything that is not asking for a decision emits nothing. No fill, no glow, no chrome, no decoration, no icon. If you can see it at 4am, it is because it wants something from you. Ink budget is a design constraint the same way a byte budget is.

> **R4 — REDUNDANT OR IT DOESN'T SHIP.**
> Every colour is redundant with a printed word. Every flash is redundant with a printed word. Every position is redundant with a printed word. This is why the red-shift theme can throw away all six hues and lose nothing — and it is also, not coincidentally, why the design is accessible.

### 1.3 Two corollaries worth stating out loud

**There is no navigation.** No tabs, no home, no back stack, no breadcrumbs. There is **one board that morphs** and **one drawer that pushes up over it**. Secondary functions (medicine book, season, export, settings) never replace the board. You never go anywhere; the board changes what it is showing you. Consequence for engineering: navigation state is one enum and one integer, so a cold launch after a dead battery restores exactly where you were with no serialisation.

**The board never leaves.** When the keypad rises for tag entry, unlit strips drop to 20 % but **every lit strip stays at full brightness through the dim**. The ewe you are standing over — already penned, already timing, already under treatment — is a single 72 pt tap away while you are still typing. That is this system's recents strip: derived from the shed's live state rather than from touch history, which at 3am is usually more right, because the ewe you are handling is usually the ewe the shed is already worried about.

---

## 2. Colour

### 2.1 Method

All ratios below are WCAG 2.2 contrast ratios computed from sRGB relative luminance:

```
C_lin = C_8bit / 255
C     = C_lin / 12.92                      if C_lin <= 0.04045
C     = ((C_lin + 0.055) / 1.055) ^ 2.4    otherwise
L     = 0.2126·R + 0.7152·G + 0.0722·B
ratio = (L_lighter + 0.05) / (L_darker + 0.05)
```

**Worked example, ink on board.**

`#E9E5DC` = (233, 229, 220)
R: 233/255 = 0.913725 → ((0.913725 + 0.055)/1.055)^2.4 = **0.814847**
G: 229/255 = 0.898039 → ((0.898039 + 0.055)/1.055)^2.4 = **0.783538**
B: 220/255 = 0.862745 → ((0.862745 + 0.055)/1.055)^2.4 = **0.715694**
L = 0.2126(0.814847) + 0.7152(0.783538) + 0.0722(0.715694) = **0.785296**

`#0C0D0E` = (12, 13, 14)
R: 12/255 = 0.047059 → 0.003677  ·  G: 13/255 = 0.050980 → 0.004025  ·  B: 14/255 = 0.054902 → 0.004391
L = **0.003977**

ratio = (0.785296 + 0.05) / (0.003977 + 0.05) = **15.47 : 1**

### 2.2 Dark theme — surfaces

An instrument panel needs surfaces that are *separated by rules, not by luminance*. These five surfaces are deliberately within 1.15 : 1 of one another; the 2 pt bay rule does the separating. This is why the board reads as one flat black object rather than as a stack of grey cards.

| Token | Hex | L | Role |
|---|---|---|---|
| `--board` | `#0C0D0E` | 0.00398 | The wall. Everything sits on this. An empty bay is this and nothing else. |
| `--bay-well` | `#101315` | 0.00630 | Interior of a bay that has content. `+N MORE` row, typed-tag readout. |
| `--holder` | `#16191B` | 0.00945 | The strip holder recess; also the keypad key face. |
| `--strip` | `#1A1D20` | 0.01203 | The strip face. The primary reading surface of the app. |
| `--strip-lift` | `#23272B` | 0.01983 | A strip lifted to centre stage. Also the face of a selected slab. |
| `--drawer` | `#0F1113` | 0.00549 | The drawer layer (medicine book, season, export, settings). |
| `--key-pressed` | `#2E3338` | 0.03234 | 90 ms press state on any key or slab. |

### 2.3 Dark theme — ink

Never pure white. Light-on-dark halation blurs glyph edges, and the effect is worst at maximum luminance for the substantial share of adults with uncorrected astigmatism. `#E9E5DC` is a warm bone that sits 15.47 : 1 on the board and still reads clean at 44 pt.

| Token | Hex | L | Role |
|---|---|---|---|
| `--ink` | `#E9E5DC` | 0.78530 | Tags, digits, all primary type, focus ring, threshold ticks. |
| `--ink-2` | `#B9B4A8` | 0.45784 | Bay labels, state words, hours-bar fill, chart bars, secondary prose. |
| `--ink-3` | `#9E988E` | 0.31679 | Captions, hints, empty-bay counts, unit suffixes. Floor for text. |
| `--ink-disabled` | `#6E6960` | 0.15236 | **Disabled controls only.** Exempt from 1.4.3 per WCAG "inactive components". Never used for readable content. |

### 2.4 Dark theme — computed contrast, every text pair

Every pair is ≥ 4.5 : 1. **Pairs marked AAA are ≥ 7 : 1.**

| Text | Hex | On surface | Hex | L(text) | L(surf) | Ratio | Band |
|---|---|---|---|---|---|---|---|
| ink | `#E9E5DC` | board | `#0C0D0E` | 0.78530 | 0.00398 | **15.47 : 1** | AAA |
| ink-2 | `#B9B4A8` | board | `#0C0D0E` | 0.45784 | 0.00398 | **9.41 : 1** | AAA |
| ink-3 | `#9E988E` | board | `#0C0D0E` | 0.31679 | 0.00398 | **6.80 : 1** | AA |
| ink | `#E9E5DC` | bay-well | `#101315` | 0.78530 | 0.00630 | **14.84 : 1** | AAA |
| ink-2 | `#B9B4A8` | bay-well | `#101315` | 0.45784 | 0.00630 | **9.02 : 1** | AAA |
| ink-3 | `#9E988E` | bay-well | `#101315` | 0.31679 | 0.00630 | **6.51 : 1** | AA |
| ink | `#E9E5DC` | holder / key | `#16191B` | 0.78530 | 0.00945 | **14.05 : 1** | AAA |
| ink-2 | `#B9B4A8` | holder / key | `#16191B` | 0.45784 | 0.00945 | **8.54 : 1** | AAA |
| ink-3 | `#9E988E` | holder / key | `#16191B` | 0.31679 | 0.00945 | **6.17 : 1** | AA |
| ink | `#E9E5DC` | strip | `#1A1D20` | 0.78530 | 0.01203 | **13.47 : 1** | AAA |
| ink-2 | `#B9B4A8` | strip | `#1A1D20` | 0.45784 | 0.01203 | **8.19 : 1** | AAA |
| ink-3 | `#9E988E` | strip | `#1A1D20` | 0.31679 | 0.01203 | **5.91 : 1** | AA |
| ink | `#E9E5DC` | strip-lift | `#23272B` | 0.78530 | 0.01983 | **11.96 : 1** | AAA |
| ink-2 | `#B9B4A8` | strip-lift | `#23272B` | 0.45784 | 0.01983 | **7.27 : 1** | AAA |
| ink-3 | `#9E988E` | strip-lift | `#23272B` | 0.31679 | 0.01983 | **5.25 : 1** | AA |
| ink | `#E9E5DC` | drawer | `#0F1113` | 0.78530 | 0.00549 | **15.05 : 1** | AAA |
| ink-2 | `#B9B4A8` | drawer | `#0F1113` | 0.45784 | 0.00549 | **9.15 : 1** | AAA |
| ink-3 | `#9E988E` | drawer | `#0F1113` | 0.31679 | 0.00549 | **6.61 : 1** | AA |
| ink | `#E9E5DC` | key-pressed | `#2E3338` | 0.78530 | 0.03234 | **10.14 : 1** | AAA |
| ink-2 | `#B9B4A8` | key-pressed | `#2E3338` | 0.45784 | 0.03234 | **6.17 : 1** | AA |

**Worst text pair in the dark theme: 5.25 : 1.** Fourteen of the twenty pairs are AAA. `--ink-3` is never placed on `--key-pressed` (pressed keys carry `--ink` only), which is the one pair that would have landed at 3.77 : 1.

### 2.5 Dark theme — the strip boot (semantic hues)

Colour is confined **absolutely** to an 8 pt strip-holder left edge — the plastic strip boot, from ATC directional coding and raddle-crayon convention — and is **never applied to type**. Every boot is redundant with a printed state word in the strip's state cell.

Load-bearing graphics must clear **3 : 1** (WCAG 1.4.11). The boot abuts the board on its left and the strip face on its right, so both are checked.

| Token | Hex | L | vs board | vs strip | Printed word | Meaning |
|---|---|---|---|---|---|---|
| `--edge-pen` | `#6E7B8B` | 0.19345 | **4.51 : 1** | **3.92 : 1** | `IN PEN 4` | Individually penned, under threshold |
| `--edge-watch` | `#C8892E` | 0.30368 | **6.55 : 1** | **5.70 : 1** | `OVER 40m` / `DUE` | Watch, flagged, overdue reminder |
| `--edge-ready` | `#4E8C55` | 0.21032 | **4.82 : 1** | **4.20 : 1** | `READY 31h` | Past the user's turn-out threshold |
| `--edge-withdrawal` | `#96607D` | 0.16330 | **3.95 : 1** | **3.44 : 1** | `WITHDRAWAL` | Under a withdrawal period |
| `--edge-filed` | `#9A958A` | 0.30200 | **6.52 : 1** | **5.67 : 1** | `FILED 04:41` | Filed off the board tonight |
| `--edge-flag` | `#C4453B` | 0.16308 | **3.95 : 1** | **3.44 : 1** | `CHECK` | **Unresolved contradiction. Nothing else, ever.** |

**Two corrections to the brief's stated hues, made because the arithmetic failed:**

- Plum `#7A4A63` computes to **2.77 : 1** against the board and **2.41 : 1** against the strip face — it fails 1.4.11 in both. Lifted to `#96607D` (same hue family, H ≈ 325°, +28 lightness) giving 3.95 / 3.44.
- Flag red `#B0342C` computes to 3.13 : 1 against the board (pass) but **2.72 : 1 against the strip face** (fail) — and the flag is the one colour in the app that must never be missed. Lifted to `#C4453B` giving 3.95 / 3.44.

### 2.6 Dark theme — rules and structure

| Token | Hex | vs board | Role |
|---|---|---|---|
| `--rule-bay` | `#626A6E` | **3.53 : 1** | 2 pt. Bay dividers, key separators, field underlines. Load-bearing — meets 1.4.11. |
| `--rule-strong` | `#848C91` | **5.69 : 1** | 2 pt. Bay-header underline, centre-stage frame, check-box border, locked-cell frame. |
| `--rule-cell` | `#363B3F` | 1.72 : 1 | 1 pt. Cell divisions *inside* a strip, and the hours-bar track. **Decorative only** — never the sole carrier of any information; every cell it divides is also separated by position and by a printed label. |
| `--bar-fill` | `#B9B4A8` | **9.41 : 1** | Hours-penned fill, withdrawal depletion, chart bars. |
| `--focus` | `#E9E5DC` | **15.47 : 1** | 4 pt focus ring, offset 2 pt. Never less than 10 : 1 on any surface in the app. |

### 2.7 The dimmed layer

When the keypad rises, **unlit** strips render at 20 % opacity over the board. Composited, `--ink` at 20 % over `--board` = `#383837` = **1.66 : 1**.

This is stated openly and is not a violation, because of three rules that are enforced in code:

1. A dimmed strip is **context, never information**. Nothing that only exists in the dim layer is ever the only place a fact appears.
2. A dimmed strip is still a full 72 pt target. Tapping one restores it to 100 % *before* the tap resolves, so nothing is ever actioned while unreadable.
3. **Any strip in any state — penned, ready, under withdrawal, flagged — is "lit" and never dims.** Only a strip with no state dims. In practice at 4am, everything on the board is lit; the dim layer usually contains nothing at all.

### 2.8 Red-shift theme

Red-shift is not a filter over the dark theme. It is a second, fully specified palette with the same role names, in which **all six semantic hues collapse into a single ordinal luminance ramp**. No information is lost, because of R4: every boot was already redundant with a printed word, and the printed word does not change.

**Surfaces and ink.**

| Token | Hex | L |
|---|---|---|
| `--board` | `#0A0708` | 0.00234 |
| `--bay-well` | `#0E0A0B` | 0.00335 |
| `--holder` / `--key` | `#140E0F` | 0.00497 |
| `--strip` | `#181112` | 0.00639 |
| `--strip-lift` | `#231819` | 0.01081 |
| `--drawer` | `#0D0909` | 0.00301 |
| `--key-pressed` | `#241818` | 0.01094 |
| `--ink` | `#E0A896` | 0.46055 |
| `--ink-2` | `#C69080` | 0.33511 |
| `--ink-3` | `#B07C6C` | 0.24728 |
| `--ink-disabled` | `#6A483F` | 0.09216 |

**Every text pair, red-shift.**

| Text | On | Ratio | Band | | Text | On | Ratio | Band |
|---|---|---|---|---|---|---|---|---|
| ink | board | **9.75 : 1** | AAA | | ink-2 | strip | **6.83 : 1** | AA |
| ink-2 | board | **7.36 : 1** | AAA | | ink-3 | strip | **5.27 : 1** | AA |
| ink-3 | board | **5.68 : 1** | AA | | ink | strip-lift | **8.40 : 1** | AAA |
| ink | bay-well | **9.57 : 1** | AAA | | ink-2 | strip-lift | **6.33 : 1** | AA |
| ink-2 | bay-well | **7.22 : 1** | AAA | | ink-3 | strip-lift | **4.89 : 1** | AA |
| ink-3 | bay-well | **5.57 : 1** | AA | | ink | drawer | **9.63 : 1** | AAA |
| ink | holder / key | **9.29 : 1** | AAA | | ink-2 | drawer | **7.27 : 1** | AAA |
| ink-2 | holder / key | **7.01 : 1** | AAA | | ink-3 | drawer | **5.61 : 1** | AA |
| ink-3 | holder / key | **5.41 : 1** | AA | | ink | key-pressed | **8.38 : 1** | AAA |
| ink | strip | **9.05 : 1** | AAA | | ink-2 | key-pressed | **6.32 : 1** | AA |
| | | | | | ink-3 | key-pressed | **4.88 : 1** | AA |

**Worst text pair in red-shift: 4.88 : 1.** Ten of twenty-three pairs are AAA.

**The ordinal ramp** (replaces the six hues; brighter = more urgent):

| Token | Hex | L | vs board | vs strip | Step vs previous | Printed word (unchanged) |
|---|---|---|---|---|---|---|
| `--edge-filed` | `#3A2622` | 0.02401 | 1.41 : 1 | 1.31 : 1 | — | `FILED 04:41` |
| `--edge-pen` | `#55352E` | 0.04675 | 1.85 : 1 | 1.72 : 1 | 1.31 : 1 | `IN PEN 4` |
| `--edge-withdrawal` | `#6E453B` | 0.07887 | 2.46 : 1 | 2.29 : 1 | 1.33 : 1 | `WITHDRAWAL` |
| `--edge-ready` | `#96604F` | 0.15414 | **3.90 : 1** | **3.62 : 1** | 1.58 : 1 | `READY 31h` |
| `--edge-watch` | `#B87A63` | 0.25010 | **5.73 : 1** | **5.32 : 1** | 1.47 : 1 | `OVER 40m` / `DUE` |
| `--edge-flag` | `#E0A896` | 0.46055 | **9.75 : 1** | **9.05 : 1** | 1.70 : 1 | `CHECK` |

The bottom three steps sit below 3 : 1 **on purpose**. This is R3 applied through the ramp: *calm should not attract a dark-adapted eye.* WCAG 1.4.11 governs graphics "required to understand the content"; here they are not, because the state word beside every boot reads at ≥ 4.89 : 1 in every case. The three steps that mean **act now** — ready, watch, flag — all clear 3 : 1 comfortably. This exemption is claimed explicitly rather than accidentally, and it is the only one in the document.

Red-shift rules: `--rule-bay` `#78594E` (**3.19 : 1** vs board), `--rule-strong` `#9A7263` (**4.74 : 1**), `--rule-cell` `#2C1F1E` (1.26 : 1, decorative), `--bar-fill` `#C69080` (**7.36 : 1**), `--focus` `#E0A896` (**9.75 : 1**).

**Emission.** Red-shift ink `#E0A896` has L = 0.46055 against dark-theme ink at L = 0.78530 — a **41.4 % reduction in emitted photopic luminance**. The board itself drops from L = 0.00398 to L = 0.00234, also **−41.2 %**. More importantly for dark adaptation: the **blue-channel luminance contribution falls 57.4 %** (0.05167 → 0.02202), and scotopic/melanopic sensitivity peaks near 500 nm, so blue suppression is what actually protects the shepherd's night vision. The remaining reduction to roughly half of dark-theme peak is a **screen-brightness recommendation surfaced in Settings**, not a CSS filter — a `brightness()` filter would silently invalidate every ratio in this document, which is exactly the kind of thing this system does not do.

### 2.9 How status is encoded without colour

Five redundant channels. Any one of them alone is sufficient to read the board.

| # | Channel | Example |
|---|---|---|
| 1 | **Position** (R1). Which bay the strip is in. | 412 sits in `READY`, not in `PENS`. |
| 2 | **The printed state word.** 18 pt condensed caps in the strip's state cell. | `READY 31h`, `WITHDRAWAL`, `IN PEN 4`, `BARREN`, `DRY`, `FILED 04:41` |
| 3 | **The clip tab.** A 6 pt-outlined rectangle on the strip's right edge carrying a word. | `CHECK` · `OVER` · `DUE` · `RX` · `SEEN 04:12` |
| 4 | **The hours bar.** A 6 pt fill along the strip's bottom edge with a 3 pt tick at the user's own threshold. Time is a shape, readable at three metres. | 412's fill is past the tick; 128's is not. |
| 5 | **Flash rate** (the boot only, and only in red-shift or when the OS reports a colour-vision setting): 1 Hz caution, 2 Hz warning. | `CHECK` flashes at 2 Hz; `OVER` at 1 Hz. |

Colour is channel six and is the only one that can be thrown away.

**Flash safety.** 2 Hz is well under the WCAG 2.3.1 three-flashes-per-second threshold, and the flashing region — a single 8 × 72 pt boot plus a 56 × 40 pt tab — is far below 25 % of any 10° visual field at arm's length. Under `prefers-reduced-motion` flashing stops entirely (§5.4).

---

## 3. Typography

### 3.1 The stacks

Three faces, one job each. Bundled, subset, offline — the app has no network and cannot fetch a font.

```css
--font-tag:   "Roboto Condensed", "Archivo Narrow", "Oswald",
              "Barlow Condensed", "Arial Narrow", "Helvetica Neue Condensed",
              system-ui, sans-serif;

--font-mono:  "IBM Plex Mono", "Roboto Mono", ui-monospace, "SF Mono",
              "DejaVu Sans Mono", Menlo, monospace;

--font-prose: "Source Sans 3", "Frutiger", "Segoe UI", -apple-system,
              "Helvetica Neue", system-ui, sans-serif;
```

**Why each.**

- **Heavy condensed grotesque for identity.** A strip has a fixed width and the tag must be enormous. Condensed buys cap height per horizontal point — that is the entire reason. Roboto Condensed Bold at 44 pt fits a four-digit tag in a 96 pt cell where a normal-width grotesque needs 128 pt.
- **Tabular monospace for duration.** Every time and every elapsed hour, everywhere, without exception. A column of `31h / 26h / 18h / 9h` down a bay must scan as a **shape**, not as prose. Monospace makes the digit stack rectangular so the eye can compare heights instead of reading values.
- **Humanist sans for prose.** Notes, hints, captions, the withdrawal disclaimer. Humanist letterforms have more distinct character skeletons than square grotesques — the MIT AgeLab / Monotype driving-simulator work reported roughly a 10 % reduction in total glance time for humanist over square grotesque, though the effect was significant only for male participants and should be treated as directional rather than settled. It is enough to justify the choice: everything read at arm's length under a head torch is a **glance**, not a read. Condensed is used only for known short numerals and single words; **never for a sentence**.

**Payload.** Roboto Condensed Bold subset to digits + A–Z + `·+−°%/.:` ≈ 28 kB woff2. IBM Plex Mono Regular + Medium, same subset ≈ 40 kB. Source Sans 3 Regular + SemiBold, full Latin-1 ≈ 150 kB. Total ≈ 220 kB, consistent with spec §11 ("payload dominated by fonts").

**Platform note.** iOS 16+ exposes a condensed width on SF Pro (`.fontWidth(.condensed)`). It is an acceptable emergency fallback but is **not** authoritative: the bundled face is, because the tag cell is a fixed 96 pt and the numeral advance width must be byte-identical on both platforms or every strip on the board misaligns.

### 3.2 The scale

| Token | Face | Size | Weight | Line-height | Computed box | Tracking | Used for |
|---|---|---|---|---|---|---|---|
| `--type-tag-xl` | tag | **44 pt** | 700 | 1.00 | 44.0 | −0.01em | Tag numerals on a strip; keypad digits; slab numerals |
| `--type-tag-lg` | tag | **34 pt** | 700 | 1.00 | 34.0 | −0.01em | Tag in a compact context; `+N MORE`; big stat values |
| `--type-tag-md` | tag | **26 pt** | 700 | 1.00 | 26.0 | 0 | Sub-strip tags (lamb rows); `DEL` |
| `--type-bay` | tag | **20 pt** | 700 | 1.00 | 20.0 | +0.14em | Bay labels. **Never abbreviated below four letters.** |
| `--type-mono-lg` | mono | **26 pt** | 500 | 1.10 | 28.6 | 0 | Centre-stage timers, countdown day counts |
| `--type-mono` | mono | **22 pt** | 400 | 1.15 | 25.3 | 0 | All times, all elapsed hours, all dates |
| `--type-mono-sm` | mono | **18 pt** | 400 | 1.20 | 21.6 | 0 | Timestamps on slabs and checks; chart day labels |
| `--type-prose-lg` | prose | **21 pt** | 400 | 1.40 | 29.4 | 0 | Ewe-card one-line summary; drawer body |
| `--type-prose` | prose | **19 pt** | 400 | 1.45 | 27.6 | 0 | **Body.** Notes, hints, captions, disclaimers |
| `--type-label` | tag | **18 pt** | 700 | 1.20 | 21.6 | +0.08em | State words, clip-tab words, key legends, field labels |

**The 18 pt floor is absolute.** There is no token below 18 pt in this system. Not for captions, not for footnotes, not for the export disclaimer, not for chart axis labels. Anything that cannot be said at 18 pt is not said. This is the single most consequential typographic decision in the direction and it is what forces the chart to become a bay (§7.14) and the board to cap at nine rows (§4.5).

### 3.3 Legibility arithmetic

At 3× on a 460 ppi device, 1 logical pt = **0.1657 mm**. Roboto Condensed cap height = 0.710 em.

| Size | Cap height | @ 400 mm | @ 600 mm (arm) | @ 1000 mm (across a pen) |
|---|---|---|---|---|
| **44 pt** | 5.18 mm | 44.5′ | **29.7′** | **17.8′** |
| 34 pt | 4.00 mm | 34.4′ | 22.9′ | 13.7′ |
| 26 pt | 3.06 mm | 26.3′ | 17.5′ | 10.5′ |
| 22 pt | 2.59 mm | 22.2′ | 14.8′ | 8.9′ |
| 20 pt | 2.35 mm | 20.2′ | 13.5′ | 8.1′ |
| 19 pt | 2.23 mm | 19.2′ | 12.8′ | 7.7′ |
| 18 pt | 2.12 mm | 18.2′ | 12.1′ | 7.3′ |

ISO 9241-303 gives a **16′ minimum** and a **20–22′ preferred** band for character height.

**The honest reading, correcting the direction brief.** The brief claimed a 44 pt cap subtends ~38′ at one metre. It does not; it subtends **17.8′**. The correct claims are:

- At **arm's length (600 mm)** — the actual pen-board use case, spec §7.4 — a 44 pt tag subtends **29.7′**, which is **1.35× the ISO preferred band** and **1.85× the ISO minimum**. This is the claim the pen board rests on and it holds comfortably.
- At **one metre across a pen**, 44 pt subtends **17.8′** — still above the ISO 16′ minimum, but below preferred. So the honest statement is: *the tag is readable across a pen, and comfortable at arm's length.* Do not over-claim it.
- Every other token in the scale falls below 16′ at one metre. That is fine and intended: **only the tag has to survive one metre.** Everything else is a glance at arm's length, where 18 pt still clears 12.1′ against a 16′ minimum — which is why the board also carries the hours **bar** (a shape, §2.9 channel 4), readable at three metres, for the one datum that must survive distance.

### 3.4 Numerals policy

| Context | Face | Figures | Feature settings | Why |
|---|---|---|---|---|
| **Tags** (412, 128, 12) | tag | **Proportional lining** | `"tnum" 0` | A tag is a name, not a column. Alignment comes from the fixed 96 pt tag cell, left-aligned; the cell edge does the aligning, not the digit advance. Proportional Roboto Condensed digits are wider and more distinct than its tabular set. |
| **Times, durations, dates, weights, counts, days** | mono | **Tabular lining** | `"tnum" 1, "zero" 1` | The column must scan as a shape. Slashed zero because batch numbers mix letters and digits (`B0X4471`) and `0`/`O` confusion in a medicine record is a safety issue. |
| **Prose** | prose | Proportional lining | default | Never tabular in a sentence. |
| **Slab numerals** (birth type, ease 1–5) | tag | Proportional lining | `"tnum" 0` | They are labels on buttons, not a column. |

**Rule:** never tabular in prose, never proportional in a time or a duration. Any time or duration rendered in a non-monospace face is a bug.

### 3.5 At 200 % text scale

The app honours iOS Dynamic Type to AX5 and Android `fontScale 2.0`. Nothing is capped, nothing is clipped, nothing truncates — **the system has no ellipsis, anywhere.**

| Token | 100 % | Box | 200 % | Box @2× |
|---|---|---|---|---|
| `--type-tag-xl` | 44 | 44.0 | **88** | 88.0 |
| `--type-tag-lg` | 34 | 34.0 | **68** | 68.0 |
| `--type-tag-md` | 26 | 26.0 | **52** | 52.0 |
| `--type-bay` | 20 | 20.0 | **40** | 40.0 |
| `--type-mono-lg` | 26 | 28.6 | **52** | 57.2 |
| `--type-mono` | 22 | 25.3 | **44** | 50.6 |
| `--type-mono-sm` | 18 | 21.6 | **36** | 43.2 |
| `--type-prose-lg` | 21 | 29.4 | **42** | 58.8 |
| `--type-prose` | 19 | 27.6 | **38** | 55.1 |
| `--type-label` | 18 | 21.6 | **36** | 43.2 |

**What structurally changes at 200 %:**

1. **The strip goes two-line.** 72 pt → **148 pt**. Line 1: tag (88 pt box) + clip tab. Line 2: state word + hours + litter, all at 36 pt. The 8 pt boot and the 6 pt hours bar do **not** scale — they are physical instruments, not type.
2. **The board holds four rows instead of nine.** 695 / 148 = 4.7. Bays past the first two collapse to header-only with their count and a `+N MORE` row. Bay order is unchanged, so the most urgent bay is still first: at 200 % you see `CHECK` and `READY` in full and `PENS +2` / `WITHDRAWAL +2` collapsed. **The information hierarchy degrades gracefully because it was ordinal to begin with.**
3. **The rail widens 88 → 132 pt** and the board column narrows 302 → 258. Rail legends are one word and may wrap to two lines at 36 pt (43.2 box × 2 = 86.4, inside a 132 pt-tall key — rail keys grow 72 → 132 and the rail becomes a 4-key stack with the fifth on a `MORE` press). `NEW` never moves and never collapses.
4. **The motor grid drops from 3 columns to 2.** 258 pt / 2 = 129 pt cells. Birth type becomes 3 rows of 2 (`SINGLE TWIN / TRIPLET QUAD / MORE —`); ease becomes 3 rows of 2. Slab height 110 → 176.
5. **The keypad keys grow to 129 × 108** and the keypad block to 4 rows = 440 pt. The LIVE bay above it shows **two** strips plus `+3 MORE`. This is the one place 200 % genuinely costs something, and it is accepted: at AX5 the user is choosing legibility over density and the system should not argue.

---

## 4. Space, geometry and grid

### 4.1 Spacing scale

4 pt base. Only these values exist.

```
0 · 2 · 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 · 64 · 96
```

`2` exists only as a rule weight and as the inset that separates two cells sharing a boundary. There is no 6, no 10, no 14. If a layout wants one, the layout is wrong.

### 4.2 Radii

```
--radius: 0
--radius-lip: 4   /* the drawer's top two corners. Nothing else. */
```

**Zero radius everywhere else, without exception.** A rectangle inside a rectangle inside a rectangle: the strip, its holder, its bay. The 4 pt lip on the drawer is the only soft edge in the product and it exists so that you can tell at a glance that the drawer is a *different object* sitting over the board, not part of it.

### 4.3 Stroke weights

| Token | Weight | Colour | Role |
|---|---|---|---|
| `--stroke-hair` | 1 pt | `--rule-cell` | Cell division inside a strip. Decorative. |
| `--stroke-rule` | 2 pt | `--rule-bay` | Bay dividers, key separators, field underlines. **Bay dividers are rules, not gaps.** |
| `--stroke-heavy` | 3 pt | `--ink` | Threshold tick on the hours bar; the check tick; chart peak marker. |
| `--stroke-frame` | 4 pt | `--ink` / `--rule-strong` | Focus ring; centre-stage frame; selected-slab frame. |
| `--stroke-tab` | 6 pt | boot colour | Clip-tab outline. |
| `--stroke-boot` | 8 pt | boot colour | The strip-holder left edge. |

No shadow. No gradient. No glow. No blur. No texture. Nothing that is not also a boundary.

### 4.4 The layout frame

```
390 pt wide, 844 pt tall

┌─────────────────────────────────────┬───────────┐  y=0
│                                     │           │
│  status bar / notch inset           │           │  y=59
├─────────────────────────────────────┤           │
│  BOARD HEADER            56 pt      │           │
├─────────────────────────────────────┤           │  y=115
│                                     │           │
│  BOARD VIEWPORT                     │  RAIL     │
│  302 pt wide × 695 pt tall          │  COLUMN   │
│  content 300 pt (1 pt bleed each)   │  88 pt    │
│                                     │           │
│                                     │  ┌─────┐  │  y=418
│                                     │  │ NEW │  │
│                                     │  ├─────┤  │
│                                     │  │ key │  │
│                                     │  ├─────┤  │
│                                     │  │ key │  │
│                                     │  ├─────┤  │
│                                     │  │ key │  │
│                                     │  ├─────┤  │
│                                     │  │ key │  │
│                                     │  └─────┘  │  y=786
├─────────────────────────────────────┴───────────┤  y=810
│  home indicator inset          34 pt            │
└─────────────────────────────────────────────────┘  y=844
```

- **Rail column: 88 pt, right edge, mirrorable to the left in Settings.** Five 72 × 72 pt softkeys with 8 pt side insets and 2 pt `--rule-bay` separators. A 2 pt `--rule-strong` runs the full height of the rail's inner edge — that rule is the only thing separating rail from board, and it is the app's one permanent piece of chrome.
- **The rail block is bottom-anchored**, occupying y 418–786. `NEW` is its topmost key, exactly as the direction requires, and the whole block still sits inside the thumb arc. See §4.6.
- **Board viewport: 695 pt.** Strip pitch is **72 pt**, not 74 — the 2 pt bay divider is drawn as the strip's own bottom border so it costs no height.

### 4.5 The vertical budget (why the board never scrolls)

| Row type | Height |
|---|---|
| Board header | 56 |
| Bay header | 28 (20 pt caps + 4 + 4) |
| Strip | 72 (includes its 2 pt bottom rule) |
| Sub-strip (lamb, treatment, reminder) | 60, inset 24 pt from the left |
| `+N MORE` row | 60 |
| Empty pen slot | 24 |

The default board at 04:00 with the brief's data:

```
CHECK        28 +  1 × 72  = 100     412 · NAVEL DIP OVER 40m
READY        28 +  2 × 72  = 172     412 (31h) · 305 (26h)
PENS         28 +  2 × 72  = 172     91 (18h) · 128 (9h)
WITHDRAWAL   28 +  2 × 72  = 172     77 (clear 12 Aug) · 219 (clear 4 Aug)
NEW               1 × 72  =  72      (no header — the strip is self-labelling)
                            ─────
                             688      of 695 available.  7 pt slack.
```

**Capacity rule.** The board holds **9 rows with 3 bays, 8 with 4, 7 with 5** — always ≥ 7 full 72 pt strips, always without scrolling. If content exceeds the budget, the **lowest-urgency bay collapses to a header plus a `+N MORE` row**; it never scrolls and it never reorders. Bays themselves cap at **five strips plus a `+N MORE`** so that no single bay can push another off the board.

> A board that scrolls is a list wearing a costume. This is the one rule that separates Strip Bay from the thing it is arguing against, and it is enforced by arithmetic, not by hope.

### 4.6 The motor grid

The board's 300 pt content width divides **four ways and only four ways**:

| Division | Cell width | Used by |
|---|---|---|
| 1 × 300 | 300 | Strip, sub-strip, text field, countdown, action strip |
| 2 × 150 | 150 | Care checks, comparison gauges, drawer rows |
| 3 × 100 | 100 | **Keypad keys, litter slabs, ease slabs, action slabs** |
| 4 × 75 | 75 | Number-stepper keys only |

**Never five across.** Five 60 pt cells would meet the letter of the 60 × 60 rule with zero separation between them, and a cold finger with poor capacitance needs *space between* targets more than it needs each target to be nominally legal. This one rule is why birth type and lambing ease are laid out **3 + 2**, not 5 across, and it is the single most visible consequence of the cold-fingers requirement.

**Every interactive cell in the app lands on this grid.** The keypad key, the litter slab, the ease slab, the action slab and the stepper key are all the same geometry at different divisions. The thumb learns one motor map and reuses it on every screen.

### 4.7 Targets and reach

Minimum target: **60 × 60 pt**. Actual minimums in this system:

| Component | Size | Margin over minimum |
|---|---|---|
| Strip | 300 × 72 | 5× area |
| Sub-strip | 276 × 60 | 2.8× |
| Rail softkey | 72 × 72 | 1.44× |
| Keypad key | 100 × 72 | 2× |
| Litter / ease slab | 100 × 110 | 3.1× |
| Care check | 150 × 76 | 3.2× |
| Stepper key | 75 × 72 | 1.5× |
| `+N MORE` row | 300 × 60 | 5× |

**Hit slop.** Every target extends its touch region 8 pt beyond its visual bounds on all sides *except* where it abuts another target, where the boundary is the 2 pt rule and neither side steals. Adjacent targets are separated by a **2 pt rule and never less**; non-adjacent controls are separated by **≥ 16 pt** of board.

**Reach zones**, right thumb, 390 × 844, phone held high over a pen:

| Zone | Region | Contains | Rule |
|---|---|---|---|
| **A — comfortable** | y 430–790 | Rail keys 1–5, the `NEW` strip, keypad rows 2–4, all centre-stage action slabs | Every action that has to happen at 4am lives here. |
| **B — reachable with a shift** | y 250–430 | Upper bays, keypad row 1 | Reachable; nothing here is time-critical. |
| **C — stretch** | y 59–250 | Board header, top bay | **Read-only in every state.** Nothing in Zone C is ever the only way to do anything. |

**The `NEW` pair.** `NEW` exists twice and both are always present: the topmost rail key (y 418, the muscle-memory constant — same word, same place, in every state of the app) and the permanent empty strip at the bottom of the board (y ≈ 738, dead centre of the thumb arc). The rail key is the one you *remember*; the bottom strip is the one you *reach*. Neither ever moves.

**Mirroring.** A single Settings toggle moves the rail to the left edge and mirrors every horizontal layout — the boot moves to the right edge of the strip, the clip tab to the left, cell order reverses. There is no separate left-handed asset; it is one `direction`-style flip.

---

## 5. Motion

### 5.1 Tokens

```
--dur-press:  90ms    --ease-mech: cubic-bezier(0.2, 0, 0, 1)
--dur-lift:  140ms    --flash-caution: 1000ms   /* 1 Hz */
--dur-rise:  180ms    --flash-warning:  500ms   /* 2 Hz */
--dur-file:  260ms
--dur-close: 120ms
```

One easing curve. `cubic-bezier(0.2, 0, 0, 1)` — fast out, hard settle, **no overshoot**. A strip in a holder does not bounce. There are no springs in this product.

### 5.2 What animates

| Motion | Duration | Property | Note |
|---|---|---|---|
| Key / slab press | 90 ms | `background-color` | To `--key-pressed` and back. Fires the haptic on **down**, not on up. |
| Strip lifts to centre stage | 140 ms | `height`, `transform: translateY` | The strip grows to 144 pt in place; the rest of the board fades to 35 % in the same 140 ms. |
| Board dims for the keypad | 90 ms | `opacity` on unlit strips only | Lit strips do not animate and do not change. |
| Keypad rises | 180 ms | `transform: translateY` | Over the board, never replacing it. |
| Drawer rises | 180 ms | `transform: translateY` | Same motion, different layer. |
| **A strip files off the board** | **260 ms** | `transform: translateX(+100%)` then `height → 0` over 120 ms | **The one expressive motion in the product.** It is earned: it is the entire argument. The strip slides right, off the wall, and the bay closes the gap behind it. The `FILED` count in the board header increments as it goes. |
| Clip-tab flash | 1 Hz / 2 Hz | `opacity` 1.0 ↔ 0.35 on the tab outline and boot only | Never on type. Never on a whole strip. |

### 5.3 What must never animate

- **Numerals.** No count-up, no roll, no odometer. A number that is animating is a number you cannot read, and at 4am you are reading it once.
- **The hours-penned fill bar.** It steps once per minute in a single frame. There is no tween. A bar that is creeping implies precision the data does not have.
- **The boot colour.** A strip that crosses the turn-out threshold **snaps** from slate to green. A state change is discrete; rendering it as a fade says it is gradual, which is a lie.
- **Bay membership during an entry.** If a strip would change bay while the user is mid-entry, the move is **queued and applied when the entry closes**. Nothing may move under the thumb. This is non-negotiable.
- **Board scroll position.** It is never programmatically scrolled. See §4.5 — it does not scroll at all in the `SHED` morph.
- **Chart bars.** They are drawn at final length on first paint.
- **Launch.** There is no splash screen, no logo, no fade-in. The board is painted on the first frame from SQLite. Cold-start budget: **400 ms to first meaningful paint**, achievable because there is no network, no auth and no layout that depends on a measured font.

### 5.4 Under `prefers-reduced-motion: reduce`

All durations go to **0 ms** except one: the file-off becomes a **220 ms opacity fade** so that the user still sees *which* strip left the board. Removing that entirely would lose information, and reduce-motion is not a licence to lose information.

**Flashing stops completely.** It is replaced by a static, equally loud treatment:

- The clip tab gains a **double outline**: 6 pt outer + 2 pt inner, 4 pt apart.
- The tab word gains a live elapsed count in `--type-mono-sm`: `CHECK` becomes `CHECK 12m`, `OVER` becomes `OVER 40m`. The count re-renders once a minute with no transition.

Both treatments ship together in red-shift regardless of the motion setting, because the ramp already carries urgency by luminance and the double outline is the belt to its braces.

### 5.5 Haptics and sound

Not strictly motion, but the same budget.

- **Every committed write fires one sharp impact.** iOS `UIImpactFeedbackGenerator(.rigid)`, Android `HapticFeedbackConstants.CONFIRM`. Through a wet glove or a freezer bag, the haptic is frequently the **only** reliable confirmation the shepherd gets — the screen may be smeared, the finger may not feel the glass.
- **A file-off fires a double impact.** Different event, different signature: a strip has left the wall.
- **A rejected press fires nothing.** Silence is the signal that nothing was written. There is no error buzz.
- **No sound. Ever.** No taps, no chimes, no confirmations. It is 4am and there is a house fifty metres away with people asleep in it.

---

## 6. Iconography

### 6.1 The approach: none

**This system has no icons.** No icon font, no icon set, no third-party glyphs, no illustrations, no logo inside the app. Every affordance in Shed Book is one of exactly three things:

1. **A word**, in condensed caps — `NEW`, `MOVE`, `FILE`, `FIND`, `BOOK`, `DEL`, `CREATE`, `TURN OUT`, `FOSTER`, `CHECK`, `SEEN`.
2. **A numeral** — the tag, the ease score, the litter count, the hour.
3. **A rule** — a boot, a divider, a tab outline, a threshold tick, a fill bar.

The delete key is the word `DEL`, not `⌫`. The share action is the word `SHARE`, not a box-with-an-arrow. The settings drawer is the word `SETTINGS`, not a cog. A word survives a head torch, a cracked screen, a language change and a user who has never seen the app before. A 24 pt glyph does not, and this audience has no patience for learning a symbol vocabulary at 3am.

### 6.2 The two drawn marks

There are exactly **two** SVG paths in the entire product.

**1. The check tick.** Used only inside a care checkbox and the export-confirmation row.

```svg
<svg viewBox="0 0 24 24" width="24" height="24" aria-hidden="true" focusable="false">
  <path d="M3 12.5 L9.5 19 L21 5.5"
        fill="none"
        stroke="currentColor"
        stroke-width="3"
        stroke-linecap="butt"
        stroke-linejoin="miter"/>
</svg>
```

**2. The nudge triangle.** Used only on the four arrange-bays keys (`ARRANGE` mode, §8.7). Solid, no stroke — a stroked triangle at 24 pt loses its point.

```svg
<svg viewBox="0 0 24 24" width="24" height="24" aria-hidden="true" focusable="false">
  <path d="M12 4 L21 19 L3 19 Z" fill="currentColor"/>
</svg>
```

Rendered at 32 pt inside its 72 pt key (rotate `0 / 90 / 180 / 270` for up / right / down / left). Every nudge key **also** carries its word underneath at `--type-label`: `UP` `DOWN` `IN` `OUT`. The triangle is redundant, per R4.

### 6.3 Stroke and size rules for the two marks

- 24 × 24 viewBox, always. Rendered at **24 pt** inside a check box, **32 pt** inside a rail key.
- Stroke weight **3** in viewBox units at 24 pt render = 3 pt on glass, matching `--stroke-heavy`.
- `stroke-linecap: butt`, `stroke-linejoin: miter`. **No rounding anywhere** — the geometry rule (§4.2) applies to drawn marks too.
- `fill="none"` on the tick, `fill="currentColor"` on the triangle. Colour is always inherited, never hard-coded, so both marks follow the theme.
- Both carry `aria-hidden="true"`. The accessible name comes from the word beside them, which always exists.

### 6.4 The threshold tick and the fill bar

Not SVG — CSS boxes, because they are instrument parts, not drawings.

```
hours bar:      300 × 6 pt,  track --rule-cell,  fill --bar-fill (left-aligned)
threshold tick:   3 × 6 pt,  --ink,  positioned at (threshold_hours / scale_max) × 300
```

The scale runs 0 → 48 h by default (user-settable alongside the threshold). At the default 24 h threshold the tick sits at 150 pt — dead centre — so *"past halfway"* is the shape you learn, and it stays correct if the user moves the threshold because the tick moves with it.

---

## 7. Component inventory

All dimensions in pt at 100 % text scale. Every component's press state is 90 ms to `--key-pressed` plus one rigid haptic, unless stated otherwise.

### 7.1 Strip — `300 × 72`

The atom of the system. Everything else is a variation on it.

```
┌─┬────────────┬──────────────┬────────┬────────────┬──────┐
│ │            │              │        │            │      │
│8│   412      │  READY 31h   │ 3 LMB  │      31h   │ OVER │  72
│ │            │              │        │            │      │
├─┴────────────┴──────────────┴────────┴────────────┴──────┤
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░│  6 (hours bar, tick at 150)
└──────────────────────────────────────────────────────────┘
 boot  tag cell    state cell    litter   time cell   tab
 8pt   96pt        108pt         40pt     56pt        56×40
```

| Cell | Width | Content | Type token |
|---|---|---|---|
| Boot | 8 | Colour only. Full height. | — |
| Tag | 96 (from x=16) | `412` left-aligned, proportional | `--type-tag-xl` |
| State | 108 | `READY 31h` / `IN PEN 4` / `WITHDRAWAL` / `BARREN` / `DRY` / `FILED 04:41` | `--type-label`, `--ink-2` |
| Litter | 40 | `3` + `LMB` stacked | `--type-mono` + `--type-label` |
| Time | 56, right | `31h` or `03:20` | `--type-mono`, `--ink` |
| Tab | 56 × 40, right edge, overlapping | `CHECK` / `OVER` / `DUE` / `RX` / `SEEN` | `--type-label` |
| Hours bar | 300 × 6, bottom edge | Track + fill + 3 pt tick | — |

**States**

| State | Rendering |
|---|---|
| **Default** | Face `--strip`. Boot per state. Bottom border 2 pt `--rule-bay`. |
| **Pressed** | Face `--key-pressed` for 90 ms. **Boot does not change** — the state did not change, only the touch. |
| **Lifted** | 300 × 144, face `--strip-lift`, 4 pt `--rule-strong` frame, tag at 44 pt, timers at `--type-mono-lg`, action slabs beneath. Rest of board at 35 %. |
| **Dimmed** | 20 % opacity. **Only ever a strip with no state.** Restores to 100 % on touch-down, before the tap resolves. |
| **Flagged** | Clip tab present. Boot and tab outline flash (1 Hz caution / 2 Hz warning). Printed word carries the same fact. |
| **Acknowledged** | Tab widens to 96 × 40, outline drops to `--rule-strong`, flashing stops, word becomes `SEEN 04:12`. **The acknowledgement is its own timestamped write.** The underlying condition is unchanged and the strip stays lit until it actually clears. Seen is not done; the app never claims something was done because you looked at it. |
| **Disabled** | Does not exist. A strip is never disabled. If an action is unavailable the *action key* disables, never the animal. |

### 7.2 Sub-strip — `276 × 60`, inset 24 from the left

Lambs under a ewe, treatments under an animal, reminders under a subject. Face `--holder`. The parent's boot remains visible in the 24 pt inset, so a sub-strip is visibly *held by* the strip above it. Tag `--type-tag-md`, prose `--type-prose`, times `--type-mono`.

### 7.3 `+N MORE` row — `300 × 60`

Face `--bay-well`. `+1 MORE` at `--type-tag-lg`, then the tags it holds at `--type-mono`: `+1 MORE · 12`. **It prints the tags it is hiding**, so nothing is ever concealed — the row is a summary, not a truncation. Pressed: the bay expands to a full-board single-bay view. The board still does not scroll; it *changes what it is showing*.

### 7.4 Bay header — `300 × 28`

2 pt `--rule-bay` above. Label at `--type-bay`, `--ink-2`, `+0.14em`, never abbreviated below four letters (`CHECK` `READY` `PENS` never `PEN`, `WITHDRAWAL`, `LIVE`, `MATCH`, `FILED`, `BARREN`, `DRY`). Count right-aligned at `--type-mono`, `--ink-3`.

**Empty bay = header only.** No fill, no strips, count reads `0`. This is R3 made concrete and it is the whole dark-board argument: a quiet night is a screen of black rules and zeroes that emits almost nothing at a dark-adapted eye.

### 7.5 Rail softkey — `72 × 72` in an 88 pt column

Legend at `--type-label`, centred, max two lines, never truncated.

| State | Rendering |
|---|---|
| Default | No fill (board shows through). Legend `--ink`. |
| Pressed | Face `--key-pressed`, 90 ms, rigid haptic. |
| Latched (mode active, e.g. `MOVE`) | 4 pt `--ink` inset frame + face `--holder`. Legend `--ink`. Persists until the mode ends. |
| Disabled | Legend `--ink-disabled`. No fill, no press feedback, no haptic. |

**Legends by context** (this is the whole navigation model):

| Context | 1 (top) | 2 | 3 | 4 | 5 (bottom) |
|---|---|---|---|---|---|
| Board — `SHED` | `NEW` | `MOVE` | `FILE` | `FIND` | `BOOK` |
| Strip lifted | `NEW` | `LAMB` | `TREAT` | `MOVE` | `CLOSE` |
| Keypad up | `NEW` | `WORDS` | `VOICE` | `SCAN` | `CANCEL` |
| Lamb lifted | `NEW` | `FOSTER` | `WEIGH` | `TAG` | `CLOSE` |
| Move in flight | `NEW` | `PEN` | `GROUP` | `OUT` | `CANCEL` |
| Drawer open | `NEW` | `SEASON` | `EXPORT` | `SETUP` | `CLOSE` |
| Arrange | `NEW` | `UP` | `DOWN` | `ORDER` | `DONE` |

`NEW` is key 1 in all seven. That is the constant.

### 7.6 Keypad key — `100 × 72`

Face `--holder`, 2 pt `--rule-bay` separators. Digit at `--type-tag-xl`, `--ink`. Layout:

```
┌─────┬─────┬─────┐
│  1  │  2  │  3  │
├─────┼─────┼─────┤
│  4  │  5  │  6  │
├─────┼─────┼─────┤
│  7  │  8  │  9  │
├─────┼─────┼─────┤
│ DEL │  0  │CREATE│
└─────┴─────┴─────┘
   4 rows × 72 + 3 × 2 = 294
```

`DEL` at `--type-tag-md`. `CREATE` at `--type-label`, **disabled** (`--ink-disabled`, no press feedback) until at least one digit is typed. No hold-to-repeat on `DEL` — a repeat that fires on hold is a long-press action in disguise, and long-press-only actions are banned. One press, one digit.

### 7.7 Segmented choice — the slab, `100 × 110`

Birth type and lambing ease. **3 + 2 grid, never 5 across** (§4.6).

```
┌──────────┬──────────┬──────────┐
│    3     │    2     │    1     │   ← numeral, --type-tag-xl
│ TRIPLET  │  TWIN    │ SINGLE   │   ← word, --type-label
│  04:02   │          │          │   ← stamp, --type-mono-sm  (blank when unselected)
├──────────┼──────────┴──────────┤
│    4     │         5+          │
│  QUAD    │        MORE         │
│          │                     │
└──────────┴─────────────────────┘
```

Constant 110 pt height whether selected or not, so selection causes **zero reflow**.

| State | Rendering |
|---|---|
| Default | Face `--holder`, 2 pt `--rule-bay` separators, ink `--ink`. |
| Pressed | Face `--key-pressed`, 90 ms, rigid haptic. |
| **Selected** | Face `--strip-lift`, 4 pt `--ink` inset frame, **and line 3 prints the write time** (`04:02`). The timestamp is the confirmation and the proof: selection is not a UI state, it is a row in SQLite. |
| Superseded | If the user changes their mind, the new slab is selected and the old slab's stamp becomes `WAS 04:02` at `--ink-3`. Both remain visible. Nothing is silently corrected (rule 12.4) and the timestamp trail is honest (rule 12.5). |
| Disabled | Ink `--ink-disabled`, no frame, no press. |
| **Warning** | If the selection contradicts the record (birth type `TWIN` with three lamb rows attached), a red `CHECK` tab clips to the *strip*, not to the slab, and the slab gains a 4 pt `--edge-flag` frame. The selection is **not** reverted. |

Ease slabs carry a descriptor as line 2: `1 UNASSISTED`, `2 EASY PULL`, `3 HARD PULL`, `4 MALPRESENT`, `5 VET / CAES`. These are the authored terms from spec §11; the app supplies vocabulary, never advice.

### 7.8 Check control — `150 × 76`, 2-up

```
┌──────────────────────┬──────────────────────┐
│ ┌──┐                 │ ┌──┐                 │
│ │✓ │ COLOSTRUM       │ │  │ NAVEL DIPPED    │   76
│ └──┘ 04:03           │ └──┘                 │
└──────────────────────┴──────────────────────┘
        150                     150
```

Box 36 × 36 hard square, 2 pt `--rule-strong` border, at x = 12. Label `--type-label`. Line 2 `--type-mono-sm`.

| State | Rendering |
|---|---|
| Unchecked | Empty box, line 2 blank. |
| Pressed | Cell face `--key-pressed`, 90 ms. |
| **Checked** | Box fills `--ink`; tick SVG in `--board`; **line 2 prints the time of the write**. Boot on the parent strip is unaffected. |
| Unchecked-after-checked | Box empties, line 2 becomes `UNDONE 04:09` at `--ink-3`. Both events are rows; neither is deleted. |
| Disabled | Border `--ink-disabled`, no press. |

**The checked state carries its own proof.** This is why the check control needs no separate confirmation, no toast and no Save: the timestamp appearing under the label *is* the write, visible.

### 7.9 Number stepper — `300 × 148`

For birthweight and for withdrawal days.

```
┌────────────────────────────────────────────┐
│  BIRTH WEIGHT                              │   label --type-label
│  4.1  kg                                   │   value --type-tag-lg + unit --type-label
├──────────┬──────────┬──────────┬───────────┤   76
│  − 0.5   │  − 0.1   │  + 0.1   │  + 0.5    │   72   (4 × 75)
└──────────┴──────────┴──────────┴───────────┘
```

Four 75 × 72 keys. **No hold-to-repeat** — the coarse/fine pair replaces acceleration, because a hold is a long-press. Direct entry is available by pressing `NEW` (rail key 1) which raises the same keypad the whole app uses. Disabled at the range limit: key ink `--ink-disabled`, no press feedback.

**Withdrawal-days variant.** Identical geometry, but the value cell **starts empty** showing the hint, and the steps are `−1 / +1 / +7 / +28`. See §7.11.

### 7.10 Countdown — `276 × 72` sub-strip

```
┌─┬──────────────────────────────────────────────────┐
│ │  WITHDRAWAL          9 DAYS                      │
│▓│  CLEAR ON 12 AUG 2026 · AS ENTERED BY YOU        │   72
│ ├──────────────────────────────────────────────────┤
│ │▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│▓│   6
└─┴──────────────────────────────────────────────────┘
```

Boot `--edge-withdrawal`. `WITHDRAWAL` at `--type-label`; `9 DAYS` at `--type-mono-lg`. Line 2 at `--type-mono-sm` / `--type-label` mix; the phrase **`AS ENTERED BY YOU` is not optional and cannot be dismissed** (safety rule 12.1). Depletion bar fill = elapsed / total, tick at 100 %.

At zero days: boot snaps to `--edge-ready` (no transition, §5.3), printed word becomes `WITHDRAWAL CLEAR`, and the strip moves to the `READY` bay at the next board settle.

**Blank-withdrawal state.** If the user files a treatment with the days field empty, the countdown renders `WITHDRAWAL — · NOT ENTERED` with the boot in `--edge-flag` and a `CHECK` tab. The app does **not** guess, does not suggest, does not offer a default, and does not block the write. It records what happened and flags what is missing.

### 7.11 Text field — `300 × 76`

```
  PRODUCT NAME                          ← --type-label, --ink-2
  Alamycin LA                           ← --type-prose, --ink
  ──────────────────────────────────    ← 2 pt --rule-strong
```

| State | Rendering |
|---|---|
| Empty | Value line shows the hint at `--ink-3`. |
| Focused | Bottom rule 4 pt `--ink`; 4 pt `--focus` ring at 2 pt offset. |
| Filled | As above. Any change is a superseding write; the field never "holds" an unsaved value — it commits on blur *and* on every 2 s idle. |
| Disabled | Label and value `--ink-disabled`, rule `--rule-cell`. |
| **Warning** | Rule 4 pt `--edge-flag`, plus a 300 × 36 caption beneath. |

**The withdrawal-days variant** is the most safety-critical control in the product and is drawn differently on purpose:

```
  WITHDRAWAL DAYS
  ______                                ← empty. always. no default. no suggestion.
  · · · · · · · · · · · · · · · ·       ← 2 pt DOTTED --rule-strong
  READ IT FROM THE BOTTLE LABEL          ← --type-prose, --ink-3
  NO DEFAULT · AS ENTERED BY YOU         ← --type-label, --ink-2
```

The **dotted rule is unique in the entire app** — it is the only dotted line anywhere, and it means *this app has nothing to offer here; the number must come from you.* It appears nowhere else, so it cannot be confused with anything else. There is no autocomplete, no recent-values list, no "last time you entered 28", and no per-product memory for this field. `REPEAT LAST TREATMENT` (§8.8) copies product, dose, route and batch — **and leaves withdrawal days empty**, because a different bottle is a different bottle.

### 7.12 Pen holder — occupied `300 × 72` / empty `300 × 24`

**Occupied:** a standard strip with the boot region extended to 44 pt — 8 pt colour boot plus a 36 pt clip cell carrying the pen number at `--type-tag-md`. Tag cell shifts to x = 52.

**Empty:** a 24 pt slot. No fill. 1 pt `--rule-cell` bottom rule. Pen number at `--type-label` `--ink-3` left; the word `EMPTY` at `--type-label` `--ink-3` right. **Not a target at 24 pt** — and it does not need to be, because an empty pen is not something you act on.

**Empty slots expand to 72 pt the instant a move is in flight**, and only then. Destinations become full-size targets exactly when they are destinations, and shrink back when they are not. This is the cleanest answer to "how do you fit twelve pens on a phone" that does not compromise the 60 pt rule for a single frame.

### 7.13 Status badge / clip tab — `56 × 40` (`96 × 40` acknowledged)

6 pt outline, no fill, word at `--type-label`, positioned on the strip's right edge, overlapping 8 pt so it reads as clipped *onto* the strip rather than printed on it.

| Word | Outline | Flash | Meaning |
|---|---|---|---|
| `CHECK` | `--edge-flag` | 2 Hz | Unresolved contradiction. **The only red in the app.** |
| `OVER` | `--edge-watch` | 1 Hz | An overdue reminder is attached. |
| `DUE` | `--edge-watch` | 1 Hz | A reminder is due within the window. |
| `RX` | `--edge-withdrawal` | steady | Under withdrawal. |
| `SEEN 04:12` | `--rule-strong` | none | Acknowledged. Condition unchanged. |

**Acknowledge is not clear.** Tapping a flashing strip turns it steady — that means *I have seen it*. It writes an `acknowledged_at` row, and the strip stays lit until the real condition clears. Annunciator practice, and it is the deepest 3am detail in the system: the app never claims something was done because you looked at it.

### 7.14 Chart — the lambing spread, drawn as a bay

Because the type floor is 18 pt (§3.2), fourteen vertical bars across 300 pt cannot carry legible labels — a 21 pt column cannot hold `14` at 18 pt mono. So the chart is not a bar chart in a card; **it is a bay of fourteen day-strips**, which is also the only chart form this system could honestly contain.

```
LAMBING SPREAD · 2026                                         ← bay header, 28
 D1  ████                                    2                ← 24 pt read-only row
 D2  ██████████                              5
 D3  ██████████████████                      9
 D4  ████████████████████████████│          14                ← 3 pt peak tick
 D5  ██████████████████████                 11
 D6  ████████████████                        8
 D7  ████████████                            6
 D8  ████████                                4
 D9  ██████                                  3
 D10 ████                                    2
 D11 ██                                      1
 D12 ██                                      1
 D13                                         0                ← no bar. black means fine.
 D14 ██                                      1
┌────────────────────────────────────────────────┐
│                  SHOW DAYS                     │  72 — turns the 14 rows into 72 pt strips
└────────────────────────────────────────────────┘
```

Row 24 pt: day label 40 pt at `--type-mono-sm`; track 200 × 12 at `--rule-cell`; fill `--bar-fill`; count 40 pt right at `--type-mono-sm`. Peak day carries a 3 pt `--ink` tick at the bar end — same tick as the hours-bar threshold, same meaning: *this is the mark that matters*.

24 pt rows are **read-only and therefore exempt from the 60 pt target rule**. `SHOW DAYS` (300 × 72) re-renders the fourteen days as tappable 72 pt strips in a bay, each opening the ewes that lambed that day. That is how a small readout becomes an interactive one without ever shipping a small target.

**Comparison gauge** — `300 × 72`, two of them:

```
┌────────────────────────────────────────────────┐
│ 2026            187%                           │  value --type-tag-lg
│ ████████████████████████████████████░░░░░│░░░░ │  gauge, scale 0-200%, tick at 2025
└────────────────────────────────────────────────┘
┌────────────────────────────────────────────────┐
│ 2025            172%          +15 PTS ON 2025  │  delta --type-mono
└────────────────────────────────────────────────┘
```

The delta is a **word and a number**, never a colour and never an arrow. `+15 PTS ON 2025`. No green, no up-chevron, no judgement — the app does not tell a shepherd whether 187 % is good.

### 7.15 Drawer — `390 × ≤620`

Face `--drawer`, `--radius-lip: 4` on the top two corners only, 2 pt `--rule-strong` top edge. A 96 × 4 `--edge-filed` lip bar sits centred at the top. **The lip is decorative and is explicitly not a drag handle** — there is no drag in this app. The drawer is opened by rail key `BOOK` and closed by rail key 5 `CLOSE`. Rows inside are 300 × 76 on the 1 × 300 division, or 150 × 76 on the 2 × 150.

The drawer **never fills the screen**. At its maximum 620 pt there are still ~130 pt of board visible above it, which is one bay header plus a strip. You can always see that the shed is still there.

### 7.16 What does not exist

Deliberate omissions, listed so nobody adds them back:

- No Save button. No OK/Cancel dialog. No modal. (R2)
- No toast, no snackbar, no banner. Confirmation is the timestamp appearing.
- No FAB, no pill, no capsule, no rounded card.
- No tab bar, no nav bar, no back chevron, no title bar.
- No spinner, no skeleton, no progress bar. Local SQLite reads do not need one.
- No swipe, no drag, no long-press, no pinch, no force touch, no shake, no double-tap.
- No empty-state illustration. An empty bay is a header and a zero, and that is the *point*.
- No onboarding, no tooltip, no coach mark, no "what's new", no rating prompt, no ad.

---

## 8. Per-screen layout direction

### 8.1 Flock — the `FIND` morph

Rail key 4 `FIND` morphs the board so that **the brief's filter chips become the bays themselves**. There is no chip row and no "All" tab, because R1 says a view containing everything contains no information. Bays top to bottom, urgency descending: `IN THE PENS` (412 · 305 · 91 · 128 — boots slate and green), `UNDER TREATMENT` (77 · 219, plum boots, each with an `RX` tab and its clear date in the time cell), `NOT YET LAMBED` (219 · 340 — 219 appears in two bays because she is genuinely in two states, and the design says so rather than picking one), `BARREN` (12, no boot at all — flat board with a hairline, because a barren ewe is not asking for anything), and finally the permanent `NEW` strip. Bays past the vertical budget collapse to a header plus `+N MORE`, which prints the tags it holds. The quick-add affordance is the `NEW` strip, which is on this screen because it is on **every** screen. Numeric search is the keypad; prose search across notes is `WORDS` (rail key 2 while the keypad is up), which raises the OS keyboard into a single text field on the drawer — a daylight function, deliberately not on the 4am path.

### 8.2 Ewe Card — 412

A card is a lifted strip, grown. Tap 412 anywhere and her strip lifts out of its bay to 300 × 144 at centre stage, the rest of the board holding at 35 % so you never lose the shed. Beneath the lifted strip, the **one-line summary comes first and alone**, on its own 300 × 76 row at `--type-prose-lg`: *3 seasons · avg 2.0 · assisted twice · prolapsed 2025.* Nothing precedes it — not a photo, not a name, not a header. Then a 300 × 60 status row: `IN PEN 4 · 31h` with her hours bar past its tick. Then `THIS SEASON` as a bay header with sub-strips: `2026 · TRIPLET · EASE 3 · ASSISTED · 03:20 AUTO` and three lamb sub-strips (`L1 EWE 4.1kg ALIVE`, `L2 RAM 3.8kg ALIVE`, `L3 RAM DEAD`). Then `PREVIOUS` with `2025 · TWIN · EASE 2 · PROLAPSED AFTER` and `2024 · TWIN · EASE 1`. Then `NOTES`. The action row is the rail, re-legended `NEW · LAMB · TREAT · MOVE · CLOSE`, plus a `NOTE` slab in the action row beneath the card — five actions, four of them under the thumb, none of them hidden in a menu.

### 8.3 Quick Entry — the 3am screen

**This is the screen the product is.** Everything else is read-back.

The single most important thing about it: **the board does not go away.** Press `NEW` — the topmost rail key or the permanent empty strip at the bottom of the board, same word, same result — and the board *dims to 20 %* while a keypad rises over the bottom 294 pt. But every **lit** strip stays at full brightness through the dim. The layout at 04:00:

```
┌──────────────────────────────────┬────────┐
│ SHED    04:00  MON 3 AUG    FILED 0       │  56
├──────────────────────────────────┤        │
│ LIVE                          5  │        │  28   ← bay header
├──────────────────────────────────┤        │
│▓ 412   READY 31h    3LMB   31h ⌐OVER      │  72   ← full brightness
│▓ 128   IN PEN 1     2LMB    9h            │  72
│▓ 305   READY 26h    3LMB   26h            │  72
│▓ 77    WITHDRAWAL          12 AUG  ⌐RX    │  72
│▓ 219   WITHDRAWAL           4 AUG  ⌐RX    │  72
├──────────────────────────────────┤  NEW   │
│ 12                      3 MATCH  │  WORDS │  72   ← typed readout
├────────┬────────┬────────┤       │  VOICE │
│   1    │   2    │   3    │       │  SCAN  │  72
├────────┼────────┼────────┤       │ CANCEL │
│   4    │   5    │   6    │       │        │  72
├────────┼────────┼────────┤       │        │
│   7    │   8    │   9    │       │        │  72
├────────┼────────┼────────┤       │        │
│  DEL   │   0    │ CREATE │       │        │  72
└────────┴────────┴────────┴───────┴────────┘
```

**The recents strip is not a recents strip.** The `LIVE` bay is derived from the shed's live state, not from touch history — ordered `CHECK` first, then `READY` by hours descending, then `PENS`, then `WITHDRAWAL`. At 04:00 that is exactly 412, 128, 305, 77, 219. The brief's sixth recent, **ewe 12, is barren** — she is not in play, so she is not on the live board at all, and a history-based recents list would have wrongly offered her. She is two keystrokes away instead. That is the thesis working, not a compromise: *the ewe you are handling is usually the ewe the shed is already worried about.*

So there are two paths, and the fast one is one tap. **If she is lit, tap her strip.** 412 is a 300 × 72 target at full brightness through the dim — the largest target on the screen, requiring no typing at all. **If she is not, type.** The keypad is the *fallback*, never the front door.

**Mid-entry, the brief's state: `12` typed.** The `LIVE` bay is replaced by `MATCH` — 412, 128, 12, three full 72 pt strips, partial-matching anywhere in the tag. The typed readout strip above the keypad shows `12` at 44 pt with `3 MATCH` at 22 pt mono and a 2 pt caret rule. If the typed tag matched nothing, the first row of `MATCH` would instead be a full strip reading **`CREATE 999 AND CARRY ON`** with an `--edge-filed` boot — a strip, not a dialog, not a confirmation, not a modal. Create-on-the-fly is a row on the board like everything else.

**The instant the tag resolves, the strip is real.** Tapping 412 in `MATCH` writes to SQLite immediately — the empty `NEW` strip fills in, the keypad drops, the strip lifts to centre stage, and its time cell carries `03:20` stamped `AUTO`. **There is no Save because nothing was ever pending.** Beneath the lifted strip: five 100 × 110 litter slabs (`1 SINGLE` `2 TWIN` `3 TRIPLET` on row 1, `4 QUAD` `5+ MORE` on row 2) and, beneath those, five ease slabs in the same 3 + 2 geometry. Every press is its own committed write with its own timestamp printed on the slab. **Abandoning after one press leaves a legitimately correct one-tap record**: ewe, time, birth type — which is a better record than the shepherd would have written at 7am from memory.

The event buttons the brief asks for (`Lambing / Treatment / Note / Death / Move pen`) are the rail, re-legended `NEW · LAMB · TREAT · MOVE · CLOSE`, with `NOTE` and `DEATH` on the action row beneath the lifted strip. They are not a grid of buttons on this screen, because on this screen the animal comes first and the event second — that is the core loop from spec §6, in that order.

**The budget:** unlock (biometric ≈ 1.5 s) → board already painted, no launch screen (≈ 0.4 s) → tap the lit strip (0.8 s) → tap `3 TRIPLET` (0.8 s) = **≈ 3.5 s to a valid, saved lambing event**. Full record with ease and three lamb rows ≈ 8.7 s. Keypad path, if she is not lit: 1.5 + 0.4 + 0.8 (`NEW`) + 0.18 (rise) + 1.8 (three digits) + 0.8 (tap match) + 0.8 (`TRIPLET`) = **≈ 6.1 s**. Both comfortably inside fifteen.

### 8.4 Lambing Entry — ewe 412

The lifted strip stays at the top, so you never lose sight of which animal you are recording. Directly beneath it, the time cell is its own 300 × 60 row: `03:20` at `--type-mono-lg` with the word **`AUTO`** at `--type-label` beside it and a `CHANGE` slab. If changed, the label becomes `EDITED 04:11 · WAS 03:20 AUTO` — the original is never overwritten, and both stamps are visible forever (rule 12.5). Then the birth-type slabs, `3 TRIPLET` selected and carrying its stamp. Then the ease slabs, `3 HARD PULL` selected. Then three 276 × 60 lamb sub-strips, each pre-created by the triplet press and each independently editable: `L1 · EWE · ALIVE · 4.1kg`, `L2 · RAM · ALIVE · 3.8kg`, `L3 · RAM · DEAD`. Then care checks 2-up at 150 × 76: `COLOSTRUM`, `NAVEL DIPPED`, `STOMACH TUBED`, `WARMED`, each stamping its own time when pressed. Then assistance detail and note as text fields. **Skippability is made visible structurally, not with the word "optional":** birth type is the only control on the screen whose bay header reads `REQUIRED · 1 TAP`; every subsequent bay header reads `SKIPPABLE` at `--type-bay` `--ink-3`. You can see, from the bay labels alone, exactly where the record stops being mandatory — which is after one tap. If the user then presses `2 TWIN` while three lamb rows exist, a red `CHECK` tab clips onto 412's strip and the slab gains a red frame. Nothing is reverted, nothing is fixed, nothing is blocked; the contradiction is recorded and flagged, removable only by opening the strip and choosing which number is right.

### 8.5 Lamb Card — lamb 1 of ewe 412

A lamb is a sub-strip, so its card is a **lifted sub-strip** — same motion, one level in. It grows to 276 × 144 and its dam's strip stays visible above it at 35 %, still showing `412`, so the parentage is on screen the entire time. The card's second row is the summary line: `EWE LAMB · 4.1kg · ALIVE · BORN 03:20 TODAY`. Then the two dam cells, side by side on the 2 × 150 division and drawn deliberately differently:

```
┌─────────────────────┬─────────────────────┐
│ BIRTH DAM    [LOCK] │ REARING DAM         │
│ 412                 │ 305                 │
│ NEVER CHANGES       │ FOSTERED 06:10      │
└─────────────────────┴─────────────────────┘
```

The birth-dam cell has a 2 pt `--rule-strong` frame all the way round and **no press state at all** — it is a locked cell, the only one in the app, and it is drawn as locked so that the rule is visible rather than merely enforced. The rearing-dam cell is an ordinary target. Beneath: a pet-lamb control — a 150 × 76 check plus a 150 × 76 stepper readout showing `FEEDS 4` with `−1 / +1` keys, because a bottle count is incremented at 2am with one thumb and nothing else. Actions are the rail: `NEW · FOSTER · WEIGH · TAG · CLOSE`, with `RECORD DEATH` as a 300 × 76 action slab beneath — separated from the rail by 24 pt of board, because it is the one action you must not hit by accident, and separation is the only protection this system will use (no confirm dialog, R2).

### 8.6 Foster — two taps, and the board does the explaining

The lamb sub-strip is already lifted from §8.5. Press rail key 2 `FOSTER` — that is tap one. The board morphs instantly to a single bay headed **`REARING DAM · PICK ONE`**, listing every ewe that can take a lamb as an ordinary 72 pt strip: 305 (`3 LMB · READY 26h`), 128 (`2 LMB · IN PEN 1`), 91 (`1 LMB · IN PEN 3`). Tap 305 — that is tap two, and it is written. No confirmation, no dialog, no "are you sure", because R2. Throughout both taps, a fixed 300 × 60 header sits above the destination bay and does not scroll away:

```
  BIRTH DAM 412 — STAYS 412 FOREVER
  MOVING: REARING DAM ONLY
```

That sentence is the entire safety argument of the screen, stated in words at 19 pt rather than implied by a diagram. After the write, the lamb's sub-strip re-clips beneath **305's** strip, 305's litter cell increments to `4 LMB`, and 412's lamb count is **unchanged** — because she still gave birth to three. Two counts, two truths, both on the board. Per §0, fostering lamb 3 (recorded dead at 04:07) is exactly the case where a red `CHECK` tab clips on: `LAMB 3 · RECORDED DEAD 04:07 · FOSTERED 06:15 — CHECK`. The system does not stop you and does not fix it. It writes what you did and marks it for you to sort out in daylight.

### 8.7 Pen Board — the digital whiteboard

**The pen board is the thesis at full strength**, and the one screen where the app's advantage over the whiteboard on the pen wall is undeniable — not because it is prettier, but because turning out **files** the strip instead of wiping it.

The twelve pens are **not laid out as a floor plan and not sorted by pen number.** They are sorted by time-in-pen, descending, into bays — because at 4am you do not want the map, you want the one that needs you, and R1 says the position must carry that. Pen number rides in a 36 pt clip cell at the left of each strip, so the number is always legible without being the organising principle.

```
OVER 24h                                   2      ← bay header, 28
┌──┬─┬──────────────────────────────────────────┐
│ 4│▓│ 412    READY 31h   2 LMB    31h   ⌐OVER │  72   green boot, OVER tab, 1 Hz
│  │ │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│▓▓▓▓▓▓▓▓▓▓│   6   fill past the tick
├──┼─┼──────────────────────────────────────────┤
│ 5│▓│ 305    READY 26h   3 LMB    26h   ⌐OVER │  72
│  │ │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│▓▓▓▓▓▓▓  │   6
├──┴─┴──────────────────────────────────────────┤
PENNED                                     5
│ 11│▓│ 271   IN PEN 11  2 LMB    21h          │  72   slate boot, no tab
│  3│▓│  91   IN PEN 3   1 LMB    18h          │  72
│  9│▓│  88   IN PEN 9   1 LMB    12h          │  72
│  1│▓│ 128   IN PEN 1   2 LMB     9h          │  72
│  7│▓│ 156   IN PEN 7   2 LMB     4h          │  72
├───────────────────────────────────────────────┤
EMPTY                                      5
│  2  EMPTY   6  EMPTY   8  EMPTY  10  EMPTY  12  EMPTY │  24 each, no fill
└───────────────────────────────────────────────┘
```

Seven occupied strips at 72 = 504, plus five collapsed empty slots at 24 = 120, plus two bay headers at 28 = 56 → **680 of 695. It fits, exactly, with no scrolling.** That is not luck; it is why empty pens collapse. An empty pen is not asking for anything, so per R3 it emits a hairline, a number and the word `EMPTY` and nothing else. A shed with every pen empty renders as five lines of grey text on black — the strongest possible statement that there is nothing to do.

**Over-threshold is badged four ways, none of them colour alone:** the strip sits in the `OVER 24h` **bay** (position), the state cell prints `READY 31h` (word), an `OVER` **clip tab** is clipped to the right edge (word), and the **hours bar has crossed its 3 pt threshold tick** (shape, readable at three metres). The green boot is the fifth channel and the only one red-shift throws away.

**Legibility at arm's length**, which spec §7.4 explicitly demands: the 44 pt tag subtends **29.7′ at 600 mm** — 1.35× the ISO 9241-303 preferred band, 1.85× its minimum (§3.3). At one metre across a pen it is 17.8′, still above the ISO minimum, which is why the *bar* rather than the *number* is what has to carry hours at distance.

**One-tap move and turn out.** Tap a strip: it lifts, the rail re-legends `NEW · PEN · GROUP · OUT · CANCEL`. Press `OUT` and the strip **files**: it slides 260 ms to the right, off the wall, the bay closes the gap in 120 ms behind it, the `FILED` count in the board header increments, and a double haptic fires. Two taps total. The pen slot it left collapses to 24 pt in the same frame. Press `PEN` instead and every empty slot expands from 24 to 72 pt — destinations become full-size targets exactly when they are destinations — and a second tap lands her. Never a drag; ATC's own digital-strip research found the drag is precisely what fails under load, and gloves make it worse.

`ARRANGE` (available from the board's `MOVE` key held latched) re-legends the rail to four nudge keys plus `DONE`, and lets the user reorder bays or switch the pen board to literal pen-number order if they want the floor plan after all. Four keys, no drag, no handles.

And the argument the whole product turns on: **by morning this board is black and every one of tonight's records is in the book.** The whiteboard on the pen wall cannot do that. It gets wiped.

### 8.8 Treatments

Two bays. `ACTIVE WITHDRAWAL` holds two countdown sub-strips: 77 · `ALAMYCIN LA` · `9 DAYS` · `CLEAR ON 12 AUG 2026 · AS ENTERED BY YOU`, depletion bar 22 % elapsed; and 219 · `FOOTBATH` · `1 DAY` · `CLEAR ON 4 AUG 2026 · AS ENTERED BY YOU`, bar nearly full. Below, the entry form on the 1 × 300 division: `PRODUCT NAME`, `DOSE`, `ROUTE` (a 3 × 100 slab row — `INJ` / `ORAL` / `TOPICAL`, the authored terms from spec §11), `BATCH NUMBER` (mono, slashed zero), `DATE` (auto-captured, labelled `AUTO`, editable), and last, deliberately last and deliberately drawn unlike anything else in the app, **`WITHDRAWAL DAYS` — empty, dotted rule, hint `READ IT FROM THE BOTTLE LABEL`, caption `NO DEFAULT · AS ENTERED BY YOU`** (§7.11). `REPEAT LAST TREATMENT` is a 300 × 76 slab at the top of the form; it copies product, dose, route and batch — **and leaves withdrawal days empty**, because a different bottle is a different bottle, and the one thing this app will never do is guess a number that puts meat into the food chain. `MEDICINE BOOK` is a 300 × 76 slab that pushes the drawer up over the board, listing every treatment chronologically as sub-strips for export. The board stays visible above the drawer the whole time.

### 8.9 Reminders

Reminders are not a separate screen; they are **strips in bays and tabs on animals**, which is why an overdue reminder is already visible on the default board without going anywhere. In the `REMIND` morph the bays are `OVERDUE`, `DUE`, `UPCOMING`. `OVERDUE` (1): `L3 of 412 · NAVEL DIP · OVER 40m` — amber boot, `OVER` tab, 1 Hz flash. `DUE` (2): `L3 of 412 · COLOSTRUM WINDOW · IN 20m`; `PEN 4 · 412 · TURN OUT · NOW 31h`. `UPCOMING` (2): `77 · WITHDRAWAL ENDS · 12 AUG`; `128's LAMBS · TAG BY · 6 AUG`. Each strip lifts to a three-slab action row on the 3 × 100 grid: **`SEEN` · `DONE` · `MUTE`** — and the split between the first two is the point. `SEEN` acknowledges: it stops the flash, writes `acknowledged_at`, prints `SEEN 04:12` on the tab, and **the reminder stays lit and stays due**. `DONE` completes: it writes `completed_at` and files the strip off the board. `MUTE` silences this one reminder for good, per spec §7.6 ("all reminders individually mutable; nothing nags twice"). Seen is not done, and the acknowledgement is itself a timestamped fact — the app never claims something was done because you looked at it.

### 8.10 Season Summary — 2026

Pushed up as a drawer over the board (`BOOK` → `SEASON`), so the shed is still visible above it. Top row is the headline on the 1 × 300 division: **`187%`** at `--type-tag-xl` with, directly beneath it and never hidden behind a tooltip, its definition in prose at 19 pt: *lambs born per ewe put to ram*. Beside it a `CHANGE DEFINITION` slab offering the four combinations from spec §7.8 (born/reared × per ewe to ram/per ewe lambed); changing it recomputes and prints `DEFINITION CHANGED 09:41` beneath. Then a 2 × 150 stat grid: `AVG LITTER 1.9`, `BARREN 4%`, `ASSISTED 12%`, `EWES TO RAM 98`. Then `LOSSES BY CAUSE` as four sub-strips with mini-bars — `STARVATION 2`, `STILLBORN 3`, `HYPOTHERMIA 1`, `CRUSHED 1` — sorted by count descending, no colour, no pie chart. Then the lambing spread as a bay of fourteen day-strips (§7.14), peak at D4 = 14 carrying the 3 pt tick, and D13 = 0 rendering as a label and a zero with **no bar at all**, because black means fine even in a chart. Then the two comparison gauges, `2026 · 187%` and `2025 · 172% · +15 PTS ON 2025`. No colour anywhere in this screen except the boots on the loss sub-strips, and no judgement anywhere at all.

### 8.11 Export

Drawer, `BOOK` → `EXPORT`. Header row prints the honest state in mono: `LAST EXPORTED · 3 DAYS AGO · 31 JUL 2026`. Immediately beneath, at 19 pt prose in `--ink` — not a footnote, not grey, not small, because the 18 pt floor means there is no such thing as small here:

> **There is no cloud. If this phone is lost, this data is lost. Export tonight.**

Then six 300 × 76 rows, each a plain visible button: `CSV · ONE ROW PER LAMB`, `CSV · ONE ROW PER EWE`, `CSV · ONE ROW PER TREATMENT`, `PDF · FLOCK BOOK 2026`, `PDF · MEDICINE RECORD`, `JSON · FULL BACKUP`. Each prints its row count in mono on line 2 (`412 ROWS`) so you know what you are about to send. Pressing one opens the system share sheet directly — no picker, no format dialog, no intermediate screen. On return the row stamps `EXPORTED 09:44` with a check tick, and the header updates to `LAST EXPORTED · JUST NOW`. At the bottom, framed by a 2 pt `--rule-strong` box so it cannot be mistaken for chrome, the footer text that also appears at the foot of every generated PDF and as a comment row in every CSV:

> **This is a notebook, not a regulatory record. It is not a holding register, a movement record or a statutory medicine book.**

### 8.12 Settings

Drawer, `BOOK` → `SETUP`. Rows on the 1 × 300 division with their controls on 2 × 150 or 3 × 100, so every control lands on the motor grid. `UNITS` — two 150 pt slabs `KG` / `LB`. `TEMPERATURE` — `°C` / `°F`. `TERMINOLOGY` — five text fields, each pre-filled with the current label and fully editable: `EWE`, `GIMMER`, `SHEARLING`, `THEAVE`, `HOGGET`; changing one re-legends every strip in the app immediately, because these vary by county let alone by country. `REMINDER INTERVALS` — a bay of sub-strips, each with a stepper: colostrum window, navel dip, turn out, tag by, second dose, withdrawal end. `TURN-OUT THRESHOLD` — a stepper in hours; changing it moves the 3 pt tick on every hours bar in the app, which is visible on the board behind the drawer as you change it. `SEASON` — current season 2026 with a `SWITCH SEASON` slab and a season start date. `THEME` — two 150 pt slabs, `DARK` / `RED-SHIFT`, plus a `MIRROR RAIL` check for left-handed use. Then, separated by 48 pt of board and framed in `--edge-flag`, the two destructive rows: `DELETE SEASON 2026` and `DELETE EVERYTHING`. Neither uses a dialog (R2). Both raise **the same keypad the rest of the app uses** and require the user to type the season year, or the total ewe count, before the key legend changes from disabled to `DELETE`. Type-to-confirm, on the app's one input surface, with no OK button anywhere.

---

## 9. The 3am compliance table

| Spec §5 rule | Mechanism in Strip Bay |
|---|---|
| **One thumb, one hand.** | The rail block is bottom-anchored at y 418–786, entirely inside the right-thumb arc (§4.7). `NEW` exists twice — rail key 1 for muscle memory, the permanent bottom strip for reach — and neither ever moves. Zone C (y < 250) is **read-only in every state**: nothing up there is ever the only way to do anything. A single Settings toggle mirrors the whole layout for a left hand. |
| **Gloves, wet hands, or a phone in a bag.** | Minimum target 60 × 60. Actual minimum in the system is the 72 × 72 rail key (1.44× area) and the 75 × 72 stepper key (1.5×); the primary target — the strip — is **300 × 72, five times the minimum area**. Every write also fires a rigid haptic, which through a wet glove or a freezer bag is frequently the only confirmation that reaches the user. |
| **No swipe-to-delete, no drag, no long-press, no pinch, no force touch.** | The system has **no gesture vocabulary at all** — one primitive, `tap`, and nothing else. Moving a strip is *tap the strip, tap the destination* (§8.7); ATC's own digital-strip research found the drag is exactly what fails under load. Arranging bays uses four nudge keys. Deleting is a plain visible slab plus type-to-confirm. `DEL` on the keypad has **no hold-to-repeat**, because a repeat-on-hold is a long-press action wearing a costume. The drawer's lip is decorative and is explicitly not a drag handle. |
| **Cold fingers — poor capacitance, big targets, generous spacing, no thin sliders.** | **Never five across** (§4.6): five 60 pt cells would be nominally legal and practically wrong, so birth type and ease are 3 + 2 at 100 × 110. Adjacent targets are separated by a 2 pt rule and never less; non-adjacent controls by ≥ 16 pt. Every target carries 8 pt of hit slop beyond its visual bounds. **There is not one slider, one drag handle, one scrubber or one thin control in the product.** Continuous values use a four-key coarse/fine stepper on the 4 × 75 division. |
| **Head torch or total darkness. Dark is default, not an option.** | There is one dark palette and one darker red-shift palette; there is **no light theme to accidentally load**. Board `#0C0D0E` at L = 0.00398. Empty bays have no fill at all, so a quiet night emits almost nothing at a dark-adapted eye (R3). |
| **No white flash on launch.** | No splash screen, no logo, no fade. The board is painted from SQLite on the first frame; cold-start budget 400 ms to first meaningful paint, achievable because there is no network, no auth and no font metric to measure. The launch storyboard / theme background is `--board`, so even the OS-drawn pre-launch frame is `#0C0D0E`. |
| **High-contrast type, minimum 18 pt body.** | Worst text pair in the dark theme **5.25 : 1**; worst in red-shift **4.88 : 1**; 14 of 20 dark pairs are ≥ 7 : 1 (§2.4, §2.8). **There is no type token below 18 pt in the system** — not for captions, not for the export disclaimer, not for chart labels. That floor is why the chart became a bay (§7.14) and why the board caps at nine rows (§4.5). |
| **Optional red-shift (night-vision) mode.** | A fully specified second palette, not a filter (§2.8). Emitted photopic luminance −41.4 %, **blue-channel contribution −57.4 %**, which is what actually protects dark adaptation. All six hues collapse to one ordinal luminance ramp and **nothing is lost**, because R4 guaranteed every hue was already redundant with a printed word. |
| **Under fifteen seconds from unlock to a saved lambing event.** | **≈ 3.5 s** when the ewe is already lit on the board — unlock 1.5, paint 0.4, tap her 300 × 72 strip 0.8, tap `3 TRIPLET` 0.8. **≈ 6.1 s** via the keypad for an animal not on the board. Full record with ease and three lamb rows ≈ 8.7 s (§8.3). The path is short because the board never goes away: the keypad rises *over* it and the lit strips stay at full brightness through the dim, so the ewe the shed is already worried about is one tap away while you are still typing. |
| **Zero interruptions.** | No ads, no rating prompt, no onboarding, no coach mark, no tooltip, no "what's new", no notification-permission nag, no update banner, no upsell, no spinner, no toast, no modal, no dialog (§7.16). The one prompt permitted by spec §7.9 — the end-of-day export nudge — is a **line in the board header**, not an overlay: `LAST EXPORTED 3 DAYS AGO`, dismissible for the season, never blocking, never covering a strip. |
| **Assume the phone dies. Every write commits immediately; there is no draft state.** | R2, followed all the way down. **No Save button anywhere; the word does not exist in the product.** No OK/Cancel dialog, because a Cancel implies something pending. Every slab press, every check, every stepper tick is its own SQLite row with its own timestamp, and the timestamp **prints on the control** — the confirmation *is* the write, made visible, which is why the system needs no toast. Correction is a superseding write with both values visible (`TRIPLET 04:02 · WAS TWIN 04:01 EDITED`), never a destructive undo and never a silent fix. The `NEW` strip is not a draft; it is an empty holder, and the instant a tag resolves the row exists. Navigation state is one enum plus one integer, so a cold launch after a dead battery restores the exact strip you were on. **Abandoning an entry after a single press leaves a legitimately correct one-tap record** — ewe, auto-captured time, birth type — which is a better record than the one that would have been written at 7am from memory. |

### 9.1 Safety rules (spec §12) — where each one lives

| Rule | Mechanism |
|---|---|
| **12.1 Never default a withdrawal period.** | The field ships empty, sits **last** in the treatment form, and is the only control in the app drawn with a **dotted** rule (§7.11) — a mark that appears nowhere else and means *this app has nothing to offer here.* Hint `READ IT FROM THE BOTTLE LABEL`; caption `NO DEFAULT · AS ENTERED BY YOU`. No autocomplete, no recent values, no per-product memory. `REPEAT LAST TREATMENT` copies everything **except** this field. The phrase `AS ENTERED BY YOU` is printed on every countdown strip forever and cannot be dismissed. |
| **12.2 Never give veterinary advice.** | The app ships ~40 authored **vocabulary** terms (ease descriptors, death causes, routes) and zero recommendations. No suggested dose, no diagnosis, no threshold advice, no "you should", and — notably — **no judgement on the season summary**: `187%` is printed beside `+15 PTS ON 2025` with no green, no arrow and no comment. |
| **12.3 Never present as a compliance record.** | The export footer is inside a 2 pt framed box at 19 pt (§8.11), and the same sentence is written into the foot of every PDF and as a comment row in every CSV. |
| **12.4 Never silently correct.** | The red `CHECK` tab, and `--edge-flag` is reserved for it **and nothing else in the entire app** (§7.13). Contradictions are written, flagged and left standing — including the dead-lamb foster in §0 and the twin-with-three-lambs case in §8.4. A `CHECK` tab is removable only by opening the strip and choosing which number is right. |
| **12.5 Timestamps are honest.** | Auto-captured time prints the word `AUTO` beside it. An edited time prints `EDITED 04:11 · WAS 03:20 AUTO` — the original is never overwritten and both remain visible. Acknowledgement is its own timestamped write (`SEEN 04:12`) and is **visibly distinct from completion** (§8.9): seen is not done, and the app never claims something was done because you looked at it. |

---

## 10. The CSS `:root` token block

```css
/* ══════════════════════════════════════════════════════════════════
   STRIP BAY — Shed Book design tokens v1.0
   Dark is the default and only base theme. Red-shift is a full
   palette swap on [data-theme="red-shift"], never a filter.
   All contrast ratios computed per WCAG 2.2 relative luminance.
   Worst text pair: dark 5.25:1 · red-shift 4.88:1.
   ══════════════════════════════════════════════════════════════════ */

:root {
  color-scheme: dark;

  /* ── SURFACES ──────────────────────────────────────────────────
     Deliberately within 1.15:1 of each other. Rules separate them,
     not luminance. The board reads as one flat black object.       */
  --board:            #0C0D0E;   /* L 0.00398  the wall             */
  --bay-well:         #101315;   /* L 0.00630  bay interior         */
  --holder:           #16191B;   /* L 0.00945  holder + keypad key  */
  --strip:            #1A1D20;   /* L 0.01203  strip face           */
  --strip-lift:       #23272B;   /* L 0.01983  centre stage         */
  --drawer:           #0F1113;   /* L 0.00549  drawer layer         */
  --key-pressed:      #2E3338;   /* L 0.03234  90ms press state     */

  /* ── INK ───────────────────────────────────────────────────────
     Never pure white: halation blurs glyph edges for astigmatism.  */
  --ink:              #E9E5DC;   /* 15.47:1 board · 13.47:1 strip   */
  --ink-2:            #B9B4A8;   /*  9.41:1 board ·  8.19:1 strip   */
  --ink-3:            #9E988E;   /*  6.80:1 board ·  5.25:1 lift    */
  --ink-disabled:     #6E6960;   /*  3.57:1 — DISABLED CONTROLS ONLY */

  /* ── STRIP BOOT (semantic hues) ────────────────────────────────
     8pt left edge only. NEVER applied to type. Every boot is
     redundant with a printed state word (rule R4).                 */
  --edge-pen:         #6E7B8B;   /* 4.51:1 board · 3.92:1 strip · "IN PEN 4"    */
  --edge-watch:       #C8892E;   /* 6.55:1 board · 5.70:1 strip · "OVER"/"DUE"  */
  --edge-ready:       #4E8C55;   /* 4.82:1 board · 4.20:1 strip · "READY 31h"   */
  --edge-withdrawal:  #96607D;   /* 3.95:1 board · 3.44:1 strip · "WITHDRAWAL"  */
  --edge-filed:       #9A958A;   /* 6.52:1 board · 5.67:1 strip · "FILED 04:41" */
  --edge-flag:        #C4453B;   /* 3.95:1 board · 3.44:1 strip · "CHECK"
                                    ONE USE ONLY: unresolved contradiction.     */

  /* ── RULES AND STRUCTURE ───────────────────────────────────────*/
  --rule-bay:         #626A6E;   /* 3.53:1 — 2pt, load-bearing      */
  --rule-strong:      #848C91;   /* 5.69:1 — 2pt, headers + frames  */
  --rule-cell:        #363B3F;   /* 1.72:1 — 1pt, DECORATIVE ONLY   */
  --bar-track:        #363B3F;
  --bar-fill:         #B9B4A8;   /* 9.41:1                          */
  --focus:            #E9E5DC;   /* 15.47:1 — never below 10:1      */

  /* ── TYPE STACKS ───────────────────────────────────────────────*/
  --font-tag:   "Roboto Condensed","Archivo Narrow","Oswald",
                "Barlow Condensed","Arial Narrow",
                "Helvetica Neue Condensed",system-ui,sans-serif;
  --font-mono:  "IBM Plex Mono","Roboto Mono",ui-monospace,"SF Mono",
                "DejaVu Sans Mono",Menlo,monospace;
  --font-prose: "Source Sans 3","Frutiger","Segoe UI",-apple-system,
                "Helvetica Neue",system-ui,sans-serif;

  /* ── TYPE SCALE (pt == px at 1x) ───────────────────────────────
     HARD FLOOR: no token below 18. No exceptions anywhere.         */
  --type-tag-xl:      44px;  --lh-tag-xl:      1.00;  /* tags, keypad digits  */
  --type-tag-lg:      34px;  --lh-tag-lg:      1.00;  /* +N MORE, stat values */
  --type-tag-md:      26px;  --lh-tag-md:      1.00;  /* sub-strip tags, DEL  */
  --type-bay:         20px;  --lh-bay:         1.00;  /* bay labels           */
  --type-mono-lg:     26px;  --lh-mono-lg:     1.10;  /* centre-stage timers  */
  --type-mono:        22px;  --lh-mono:        1.15;  /* all times/durations  */
  --type-mono-sm:     18px;  --lh-mono-sm:     1.20;  /* stamps, chart labels */
  --type-prose-lg:    21px;  --lh-prose-lg:    1.40;  /* ewe-card summary     */
  --type-prose:       19px;  --lh-prose:       1.45;  /* BODY                 */
  --type-label:       18px;  --lh-label:       1.20;  /* state words, legends */

  --wt-tag:    700;  --wt-mono:    400;  --wt-mono-md: 500;
  --wt-prose:  400;  --wt-prose-b: 600;
  --tr-tag:   -0.01em;  --tr-bay: 0.14em;  --tr-label: 0.08em;

  /* Numerals: tabular + slashed zero for the mono face only.
     Tags stay proportional — the fixed 96pt cell does the aligning. */
  --num-mono: "tnum" 1, "zero" 1;
  --num-tag:  "tnum" 0;

  /* ── SPACE (4pt base — only these values exist) ────────────────*/
  --s-0:   0px;  --s-2:   2px;  --s-4:   4px;  --s-8:   8px;
  --s-12: 12px;  --s-16: 16px;  --s-20: 20px;  --s-24: 24px;
  --s-32: 32px;  --s-40: 40px;  --s-48: 48px;  --s-64: 64px;  --s-96: 96px;

  /* ── GEOMETRY ──────────────────────────────────────────────────
     Zero radius everywhere. The drawer lip is the only soft edge.  */
  --radius:           0px;
  --radius-lip:       4px;

  --stroke-hair:      1px;   /* cell division, decorative           */
  --stroke-rule:      2px;   /* bay dividers, key separators        */
  --stroke-heavy:     3px;   /* threshold tick, check tick          */
  --stroke-frame:     4px;   /* focus ring, centre-stage frame      */
  --stroke-tab:       6px;   /* clip-tab outline                    */
  --stroke-boot:      8px;   /* the strip-holder left edge          */

  /* ── LAYOUT (390 x 844 baseline) ───────────────────────────────*/
  --frame-w:        390px;   --frame-h:        844px;
  --inset-top:       59px;   --inset-bottom:    34px;
  --rail-w:          88px;   --rail-key:        72px;
  --board-w:        302px;   --board-content:  300px;
  --board-header:    56px;   --board-viewport: 695px;

  --bay-header:      28px;
  --strip-h:         72px;   /* includes its own 2pt bottom rule    */
  --substrip-h:      60px;   --substrip-inset: 24px;
  --more-row-h:      60px;
  --pen-empty-h:     24px;
  --strip-lift-h:   144px;

  /* Motor grid: 300pt divides four ways and only four ways.
     NEVER five across — five 60pt cells is legal and wrong.        */
  --grid-1:         300px;   --grid-2:         150px;
  --grid-3:         100px;   --grid-4:          75px;

  --key-h:           72px;   /* keypad key   100 x 72               */
  --slab-h:         110px;   /* litter/ease  100 x 110              */
  --check-h:         76px;   /* care check   150 x 76               */
  --field-h:         76px;   /* text field   300 x 76               */
  --tab-w:           56px;   --tab-h:  40px;  --tab-w-seen: 96px;
  --hours-bar-h:      6px;   --hit-slop: 8px;
  --target-min:      60px;   /* HARD MINIMUM. Nothing is smaller.   */

  /* ── MOTION ────────────────────────────────────────────────────*/
  --ease-mech:      cubic-bezier(0.2, 0, 0, 1);  /* no overshoot    */
  --dur-press:       90ms;
  --dur-lift:       140ms;
  --dur-rise:       180ms;
  --dur-file:       260ms;   /* the one expressive motion           */
  --dur-close:      120ms;
  --flash-caution: 1000ms;   /* 1 Hz                                */
  --flash-warning:  500ms;   /* 2 Hz — under WCAG 2.3.1 threshold   */
  --dim-unlit:       0.20;   /* unlit strips under the keypad       */
  --dim-board:       0.35;   /* board behind a lifted strip         */
}

/* ══════════════════════════════════════════════════════════════════
   RED-SHIFT — a full palette, not a filter. All six hues collapse
   to one ordinal luminance ramp (brighter = more urgent). Nothing
   is lost: every boot was already redundant with a printed word.
   Emitted luminance -41.4%. Blue-channel contribution -57.4%.
   ══════════════════════════════════════════════════════════════════ */

:root[data-theme="red-shift"] {
  --board:            #0A0708;   /* L 0.00234                       */
  --bay-well:         #0E0A0B;
  --holder:           #140E0F;
  --strip:            #181112;
  --strip-lift:       #231819;
  --drawer:           #0D0909;
  --key-pressed:      #241818;

  --ink:              #E0A896;   /* 9.75:1 board · 8.40:1 lift      */
  --ink-2:            #C69080;   /* 7.36:1 board · 6.33:1 lift      */
  --ink-3:            #B07C6C;   /* 5.68:1 board · 4.89:1 lift      */
  --ink-disabled:     #6A483F;   /* disabled controls only          */

  /* Ordinal urgency ramp. The bottom three sit below 3:1 ON PURPOSE
     (rule R3: calm must not attract a dark-adapted eye). The three
     that mean ACT NOW all clear 3:1. State words carry identity.   */
  --edge-filed:       #3A2622;   /* 1.41:1 · "FILED 04:41"          */
  --edge-pen:         #55352E;   /* 1.85:1 · "IN PEN 4"             */
  --edge-withdrawal:  #6E453B;   /* 2.46:1 · "WITHDRAWAL"           */
  --edge-ready:       #96604F;   /* 3.90:1 · "READY 31h"            */
  --edge-watch:       #B87A63;   /* 5.73:1 · "OVER" / "DUE"         */
  --edge-flag:        #E0A896;   /* 9.75:1 · "CHECK" + 2 Hz flash   */

  --rule-bay:         #78594E;   /* 3.19:1                          */
  --rule-strong:      #9A7263;   /* 4.74:1                          */
  --rule-cell:        #2C1F1E;   /* decorative                      */
  --bar-track:        #2C1F1E;
  --bar-fill:         #C69080;   /* 7.36:1                          */
  --focus:            #E0A896;   /* 9.75:1                          */
}

/* ══════════════════════════════════════════════════════════════════
   REDUCE MOTION — all durations to zero EXCEPT the file-off, which
   fades so the user still sees WHICH strip left the board. Flashing
   stops entirely and is replaced by a double outline plus a live
   printed elapsed count ("CHECK 12m"). Reduce-motion is not a
   licence to lose information.
   ══════════════════════════════════════════════════════════════════ */

@media (prefers-reduced-motion: reduce) {
  :root {
    --dur-press:       0ms;
    --dur-lift:        0ms;
    --dur-rise:        0ms;
    --dur-close:       0ms;
    --dur-file:      220ms;   /* opacity only, no transform         */
    --flash-caution:   0ms;   /* 0 = static double outline + count  */
    --flash-warning:   0ms;
  }
}

/* ══════════════════════════════════════════════════════════════════
   NO LIGHT THEME EXISTS. prefers-color-scheme: light is ignored on
   purpose — there is nothing to fall back to and nothing to flash.
   The OS launch background is --board so even the pre-launch frame
   the system draws is #0C0D0E.
   ══════════════════════════════════════════════════════════════════ */
```

---

## Appendix — quick reference for the mockup build

**Bay order on the default board (urgency descending, never reordered):**
`CHECK` → `READY` → `PENS` → `WITHDRAWAL` → `NEW`

**Board morphs (rail-driven, no navigation):**
`SHED` (default) · `FIND` (flock) · `PENS` (pen board) · `REMIND` · `MATCH` (keypad up) · `MOVE` / `FOSTER` (destination picking) · `ARRANGE` · plus the drawer for book / season / export / setup.

**The five redundant status channels:** position · printed word · clip tab · hours-bar shape · flash rate. Colour is the sixth and the only disposable one.

**Three sentences that appear verbatim in the UI and must not be reworded:**
1. `NO DEFAULT · AS ENTERED BY YOU` (withdrawal days)
2. `BIRTH DAM 412 — STAYS 412 FOREVER` (foster)
3. `This is a notebook, not a regulatory record.` (export footer, every PDF, every CSV)

**Words that must never appear anywhere in this product:** *Save · Cancel · Submit · Confirm · Are you sure · Loading · Oops · Welcome · Got it · Upgrade · Sync.*

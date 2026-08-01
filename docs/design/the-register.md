# The Register

**Shed Book — design system specification, direction 1 of 3.**
Design systems lead: this document. Version 1.0. Reference device: **393 × 852 pt** (iPhone 15 / Pixel 8 class), safe-area insets 59 top / 34 bottom, giving a **759 pt content box**. Throughout this document **1 pt = 1 CSS px = 1 Android dp**; the mockup viewport is 393 CSS px wide.

---

## 1. Thesis and principles

### 1.1 The thesis

**You do not navigate to an animal. You load her.**

Ewe 412 sits in a register at the top of the instrument and stays there — across events, across modes, across a cold launch, across the phone going in your pocket and coming out again — until you deliberately clear her. She is the largest object on the phone at all times: a 120 px numeral with a phosphor bloom, findable in peripheral vision while your eyes are on a lamb.

This structurally eliminates the single most dangerous error at 3am: **recording a lambing against the wrong ewe.** Every other design in this competition asks the shepherd to *re-establish* who they are working on at the start of each interaction. This one asks them to establish it once and then never lie about it.

Below the register are **twelve keys that never move for the life of the app**. And the rule that makes a re-legending instrument safe rather than lethal:

> ### A DIGIT ALWAYS MEANS A NUMBER.

Press `2` and you have said *two*. The loaded context decides whether two is lambs, or ease, or days off, and a welded mode line says which, in words, at 26 px. The keys never change meaning — only what the number is attached to.

This is the direction that believes a shepherd on night eleven is an **operator**, not a user, and that the highest respect you can show an operator is a control layout that never moves. Recall is a **readout**, never a document. History is a value, not a page.

### 1.2 The signature move

The ewe stays loaded and the keys never move — and because a digit always means a number, there is no mode in which pressing `2` can mean something other than two. After three nights, **"412, LAMBED, two"** is a thumb shape you can perform with the phone at your hip and your eyes on the lamb.

### 1.3 The five laws

These resolve every future disagreement. They are ordered; a lower-numbered law beats a higher-numbered one.

**LAW 1 — A digit always means a number.**
No key on the digit block ever re-legends. Not for a mode, not for a screen, not for an OEM, not for a v2 feature. If a proposed feature requires `7` to mean "footbath", the feature is wrong, not the law. Non-numeric choices live on slabs, never on keys.

**LAW 2 — The number is attached to something printed as a number on the face.**
If you can press `3` and something happens, then a `3` is visible on screen at that moment, next to the thing that will happen. Birth type prints `1 SINGLE 2 TWIN 3 TRIPLET 4 QUAD 5 MORE`. Care checks print `1 COLOSTRUM 2 NAVEL 3 TUBED 4 WARMED`. Reminders print `1 …` `2 …` `3 …`. If nothing numbered is on the face, **the keys go inert** — recessed, unpressable, and the mode line says `NOTHING TO NUMBER`. This closes the mode-error hazard completely: you can always see, before you press, what your number will land on.

**LAW 3 — The subject is loaded, not navigated to.**
There is no navigation stack, no tab bar, no back button, no modal, no push transition. There is one instrument face with five welded zones. The loaded subject persists until explicitly cleared or replaced, including across process death. Secondary functions are **readouts summoned onto the same face**, never separate screens. If a design proposal contains the word "screen" meaning "a place you go", it is out of system.

**LAW 4 — Nothing is ever pending.**
Every press is its own committed write to SQLite. There is no draft, no form, no transaction, therefore **no Save button, no Cancel, no Done, no discard dialog, and nothing that can be lost when the phone dies mid-lambing.** Walking away leaves exactly what you pressed on disk. Correction is a new write, printed as a new line, never a silent overwrite of a pending state.
*One exception, and only one: destruction.* `DELETE EVERYTHING` is the sole pending action in the product, because the cost of an accidental commit is unbounded. It is stated as an exception so nobody generalises from it.

**LAW 5 — The controls never move.**
The key block is dimensionally frozen: same size, same position, at every text scale, on every device, in every mode, forever. All reflow — text scaling, small screens, long readouts — is absorbed by the register head, which is the one zone that is never a tap target. Muscle memory is the product's most valuable asset and it is not spendable.

### 1.4 Two corollaries worth writing down

- **The instrument never picks.** Where the operator's entry contradicts itself, the face flags it, prints both facts, and offers both resolutions. There is never a third slab that resolves it automatically, and there is never a default focus ring on the "sensible" one. (Spec §12.4.)
- **The instrument never suggests a quantity it did not measure.** Auto-captured time is a measurement and is labelled `TIME AUTO`. A withdrawal period is not a measurement; it is on a bottle label in the operator's hand, and the field starts empty and stays empty until they type it. (Spec §12.1, §12.5.)

### 1.5 One amendment to the brief, stated openly

The brief specified **four zones and fourteen targets**. Twelve screens of contact with reality broke the arithmetic: five event types plus a MORE affordance cannot live in two action slabs without a carousel, and a carousel is a control that moves — the one thing Law 5 forbids above all else.

The amendment: **five welded zones and eighteen fixed positions** — twelve keys that never re-legend, one primary slab (which may split into two or three), and **five permanent event slabs that never re-legend for the life of the app**. This strengthens the thesis rather than diluting it: the event is now chosen by a slab that is always in the same place, and *never* by a digit. Everything else in the direction is unchanged.

---

## 2. Colour

### 2.1 The strategy in one line

**An amber-phosphor instrument.** One hue at four luminance steps carries the entire interface. Plus a commit green that exists for exactly 800 ms per write and nowhere else, and exactly one red used for exactly two things in the whole product. Because the system is monochrome by construction, **red-shift is the same design rotated, not a second design to learn.**

### 2.2 The ground rule

`#0A0806` — dead phosphor glass. Never pure black (pure black on OLED produces a visible pixel-off shear at low brightness and makes the bevels read as floating), never blue-black.

**It is the first painted frame.** There is no launch screen and no white flash, ever:

- iOS: `LaunchScreen.storyboard` is a single view filled with `#0A0806` carrying the static head chrome and the twelve key bevels. The app boots *into* the instrument.
- Android: `windowBackground` and `windowSplashScreenBackground` are both `#0A0806`, `windowSplashScreenAnimatedIcon` is absent, `postSplashScreenTheme` is the same colour. `SplashScreen.setKeepOnScreenCondition` is never used.
- Neither platform is permitted a light-theme resource of any kind. There is no light theme. Dark is not the default — it is the only one, plus red-shift.

### 2.3 How the contrast numbers were computed

WCAG 2.2 relative luminance, sRGB:

```
For each channel c in {R,G,B}:  c' = c/255
  c_lin = c'/12.92                      if c' <= 0.04045
  c_lin = ((c' + 0.055)/1.055) ^ 2.4    otherwise
L = 0.2126·R_lin + 0.7152·G_lin + 0.0722·B_lin
Contrast = (L_lighter + 0.05) / (L_darker + 0.05)
```

Worked example — `--reg-ink-1` `#FFB000` on `--reg-ground` `#0A0806`:

```
#FFB000 → R'=1.0000  G'=0.6902  B'=0.0000
          R_lin=1.00000  G_lin=0.43415  B_lin=0.00000
          L = 0.2126(1.00000) + 0.7152(0.43415) + 0.0722(0.00000) = 0.52311

#0A0806 → R'=0.03922 G'=0.03137 B'=0.02353   (all ≤ 0.04045, linear branch)
          R_lin=0.003035  G_lin=0.002428  B_lin=0.001821
          L = 0.2126(0.003035) + 0.7152(0.002428) + 0.0722(0.001821) = 0.002514

Contrast = (0.52311 + 0.05) / (0.002514 + 0.05) = 0.57311 / 0.052514 = 10.91 : 1
```

All figures below are computed the same way, to two decimal places.

### 2.4 Surfaces (amber theme)

| Token | Hex | L | Role |
|---|---|---|---|
| `--reg-ground` | `#0A0806` | 0.00251 | The face. Dead gutters between keys. First painted frame. |
| `--reg-panel` | `#14100A` | 0.00541 | The readout pane inside the register head. Chart plot area. |
| `--reg-keyface` | `#1C160E` | 0.00852 | Raised key faces and slab faces at rest. |
| `--reg-keypress` | `#2A2114` | 0.01630 | Key/slab face while held. |
| `--reg-well` | `#050302` | 0.00125 | Recessed operator keys (LOAD, DEL) and inert plates. |

Surface separation is deliberately tiny (keyface vs. ground = 1.11:1). **The key boundary is not carried by the fill — it is carried by the bevel**, which is a non-text graphical object with its own 3:1 obligation. See §2.6.

### 2.5 Text and signal roles (amber theme)

Every value is the computed ratio of the ink against that surface. **Every pair listed is ≥ 4.5:1.** Pairs at **≥ 7:1** are marked ✦.

| Token | Hex | on `ground` | on `panel` | on `keyface` | on `keypress` |
|---|---|---|---|---|---|
| `--reg-ink-1` (primary) | `#FFB000` | **10.91** ✦ | **10.34** ✦ | **9.79** ✦ | **8.64** ✦ |
| `--reg-ink-2` (secondary) | `#C98A00` | **6.78** | **6.42** | **6.08** | **5.37** |
| `--reg-commit` | `#3FBF6F` | **8.47** ✦ | **8.02** ✦ | **7.60** ✦ | **6.71** |
| `--reg-alarm` | `#FF3B1F` | **5.62** | **5.32** | **5.04** | *4.45 — forbidden, see below* |

Inversions (ground ink on a solid fill), used for every selected, committed and alarmed state:

| Pair | Ratio |
|---|---|
| `--reg-ground` on `--reg-ink-1` (selected slab, armed row) | **10.91** ✦ |
| `--reg-ground` on `--reg-commit` (commit flash) | **8.47** ✦ |
| `--reg-ground` on `--reg-alarm` (withdrawal band, DIED pressed) | **5.62** |

**The one forbidden pair.** `--reg-alarm` on `--reg-keypress` is 4.45:1 — three hundredths short. This is exactly why **the DIED slab inverts on press** instead of brightening: the pressed state is ground ink on solid red at 5.62:1, so alarm red never sits on a lifted face anywhere in the product. The failure produced the interaction rule; the rule is now permanent.

**The bloom.** The register tag carries a 2 px phosphor bloom — the only ornament in the system, and functional: it is how the operator finds the readout with peripheral vision while looking at a lamb. It is a text-shadow of `--reg-ink-1` at **α 0.22**, which composites to `#402D05` in the halo. Worst-case contrast of the numeral against its own halo: **7.18:1** ✦. The bloom is on the register numerals *only* — key legends stay crisp so they never halate.

### 2.6 Structural steps — non-text, with their own 3:1 obligation

WCAG 1.4.11 requires 3:1 for the boundary of a control. These two steps carry no text, ever.

| Token | Hex | vs `ground` | vs `keyface` | Role |
|---|---|---|---|---|
| `--reg-bevel` | `#8A5E00` | **3.51** ✔ | **3.15** ✔ | 1 px top-light bevel. **This is the load-bearing key boundary.** |
| `--reg-etch` | `#6B4A00` | 2.48 | 2.23 | 2 px bottom shadow rule, chart gridlines, dead hairlines. Secondary depth only; never the sole carrier of a boundary. |

**Why the boundary is always drawn against the ground, never against the face.** A key at rest has its 1 px bevel on its *top* edge, where it meets the ground: 3.51:1. On press the key face lifts to `--reg-keypress` and **the bevel migrates to the bottom edge** — again against the ground: 3.51:1. The boundary is therefore never evaluated against a lifted face (where `--reg-bevel` would fall to 2.78:1). The bevel inversion is also the press feedback, which means the pressed state is legible as *geometry* and not as brightness — the correct choice when the operator's eyes are on a lamb.

Note that `--reg-ink-2` at 6.78:1 is the dimmest thing in the system that carries a word. **There is no third text colour.** Where something must read as inert (the `NO DEFAULT VALUES` plate), it is made inert by *geometry* — recessed into `--reg-well`, no bevel, no press response — not by dimming it below legibility. Dimming a warning is how warnings get missed.

### 2.7 The red-shift variant

Same roles, same geometry, same components. The hue is rotated and the peak luminance is cut to preserve dark adaptation.

**An honest note on "half luminance".** A literal 50 % luminance rotation of the amber ramp puts the secondary ink at L ≈ 0.153, which is **3.87:1** on the red-shift ground — a failure. So the rotation halves the *peak* and then **re-floors the secondary at the 4.5:1 line**. Red-shift is dimmer, but it is not less legible.

| Token | Hex | L | on `rs-ground` | on `rs-panel` | on `rs-keyface` | on `rs-keypress` |
|---|---|---|---|---|---|---|
| `--reg-ink-1` | `#FF6B3D` | 0.32112 | **7.20** ✦ | **6.97** | **6.84** | **6.23** |
| `--reg-ink-2` | `#E0532A` | 0.22200 | **5.28** | **5.11** | **5.01** | **4.57** |
| `--reg-commit` | `#FF9E6B` | 0.46770 | **10.04** ✦ | **9.73** ✦ | **9.54** ✦ | **8.69** ✦ |
| `--reg-alarm` | `#FF3B1F` | 0.24487 | **5.72** | **5.54** | **5.43** | *4.95 — still inverted on press* |

Surfaces: `--reg-ground` `#0A0402` (L 0.00156) · `--reg-panel` `#150705` (0.00322) · `--reg-keyface` `#1A0905` (0.00426) · `--reg-keypress` `#2C1109` (0.00956) · `--reg-well` `#050201`.
Structural: `--reg-bevel` `#B44018` — **3.58** vs ground, **3.40** vs keyface, **3.10** vs keypress ✔ · `--reg-etch` `#7A1400` (1.87, depth only).
Bloom in red-shift drops to **α 0.12** (halo `#271009`, numeral **6.37:1**) because the whole point of red-shift is less light on the retina.

**Commit in red-shift is not green.** Green destroys dark adaptation, which defeats the entire mode. In red-shift the commit signal is `#FF9E6B` at **10.04:1** — the only colour in the red-shift palette brighter than the primary ink — *and* the slab fully inverts. The commit is therefore identified by **inversion plus a printed word**, with hue as a third, redundant channel. Which is the general rule:

### 2.8 Status is never encoded by colour alone

Every state in the product carries at least two non-colour channels. This is not a compliance afterthought; in red-shift, where everything is a shade of red, it is the *only* thing that works.

| State | Colour channel | Non-colour channel 1 | Non-colour channel 2 |
|---|---|---|---|
| **Over turn-out threshold** (pen 4, 31 h) | none — amber like everything else | printed token `!! OVER` | a **4 px double rule** welded across the top of the tile (2 px + 2 px gap + 2 px) |
| **Active withdrawal** (ewe 77) | solid `--reg-alarm` band | the word `WITHDRAWAL` + `CLEAR 12 AUG · 9 DAYS` | a **45° hatch end-cap**, 20 px wide, at the band's left edge |
| **Withdrawal days not yet entered** | solid `--reg-alarm` band | `WITHDRAWAL — DAYS NOT ENTERED` | hatch end-cap **plus** a `___` empty-field glyph in the head |
| **Dead lamb** | `--reg-alarm` on the DIED slab only | the word `DEAD` printed in every line the lamb appears in | the lamb's numeral is **overstruck** with a 3 px rule, everywhere in the app, forever |
| **Committed write** | 800 ms `--reg-commit` | the word `WROTE` printed into the echo stack with a timestamp | a double haptic thunk |
| **Contradiction** (twin vs 3 lambs) | none | `!! DECLARED TWIN · 3 LAMBS ON RECORD` | the head's frame becomes a **4 px double rule**; the primary slab splits in two |
| **Selected** (birth type 3, ease 3) | inverted fill | the cell is **inverted** — ground ink on solid ink-1 | a `▮` marker printed inside the cell |
| **Unselected / not done** | — | outline only | a `▯` marker |
| **Inert control** | no colour change | **recessed** into `--reg-well`, bevel absent | does not respond to press at all |
| **Auto vs edited time** | none | the words `TIME AUTO` / `TIME EDITED` | edited times print the prior value: `TIME EDITED 03:20 (WAS 03:47)` |
| **Value on record vs blank** | none | a value prints; a blank prints `___` | blanks are never shown as `0` |

Note the last row. **A withdrawal field must never render as `0`.** `0` is a number a shepherd could believe. `___` is not.

---

## 3. Typography

### 3.1 The two families

Both are **bundled with the app**, not fetched — this is an offline product and the payload is budgeted for it (spec §11: "under 20 MB, dominated by fonts").

```css
--reg-font-machine:
  "JetBrains Mono", "Berkeley Mono", ui-monospace, "SF Mono",
  "IBM Plex Mono", "Roboto Mono", Menlo, Consolas, monospace;

--reg-font-prose:
  "Source Sans 3", -apple-system, BlinkMacSystemFont, "SF Pro Text",
  "Segoe UI", Roboto, "Helvetica Neue", sans-serif;
```

**Machine (mono) is the default voice.** Tags, figures, key digits, mode line, legends, readout rows, echo stack, chart labels. All-caps, tracked, tabular.

**Prose (humanist) is the exception**, used for exactly three things: mode prose (the sentence under a mode line), the operator's own free-text notes, and the export footer. The rationale is the MIT AgeLab / Monotype glance-time work (Reimer, Mehler et al.), which found humanist letterforms were read from a glance measurably faster than square grotesques — on the order of ~10 % shorter total glance time in the reported conditions. Numerals in this app are recognised by *shape*; a **word** in this app is always read in a hurry, by someone who is cold and half-asleep, and it gets the humanist face.

**Lowercase exists only inside a free-text note.** Everything the machine says, the machine says in caps.

### 3.2 Numeral policy — specified before the letters

A confused numeral is how a wrong withdrawal period gets into the food chain. The numerals are therefore a safety requirement, not a style choice.

- **Tabular figures everywhere, no exceptions.** `font-variant-numeric: tabular-nums;` plus `font-feature-settings: "tnum" 1`. A column of hours on the pen board must align to the digit.
- **Slashed zero.** JetBrains Mono's default zero is dotted; the slashed form is an OpenType alternate. Because this is safety-critical, **the shipped build bakes the disambiguated numerals into the default glyph set** rather than relying on a feature tag surviving a renderer, a subsetter, or an OEM font-fallback path. The app never renders a numeral it did not draw.
- **Flat-topped `1` with a full foot serif** — so `1` cannot be read as `7` or as `l` in tag `128`.
- **Crossed `7`** — so `7` cannot be read as `1` in tag `77`.
- **`0` vs `O`**: the machine face never sets a capital O adjacent to a figure. Where a batch number legitimately mixes them (`AL-0O42`), the batch field is set in the machine face at 20 px and is the only place a mixed alphanumeric string appears.
- Figures are never animated, never tweened, never rolled. See §5.

### 3.3 The scale

`M` = machine (mono) · `P` = prose (humanist). Tracking in em.

| Token | Size | Line height | Weight | Track | Case | Family | Used for |
|---|---|---|---|---|---|---|---|
| `--reg-t-tag` | **120** | 108 | 700 | −0.02 | figures | M | The register tag. One key module tall. |
| `--reg-t-tag-suffix` | **56** | 60 | 700 | 0 | figures | M | The lamb suffix: `412` `/3` |
| `--reg-t-key` | **56** | 56 | 500 | 0 | figures | M | The ten digit keys |
| `--reg-t-figure` | **34** | 38 | 700 | 0 | figures | M | Pen tile tags, stat figures, candidate rack |
| `--reg-t-slab` | **28** | 32 | 700 | 0.10 | UPPER | M | The primary slab legend |
| `--reg-t-mode` | **26** | 30 | 700 | 0.12 | UPPER | M | **The welded mode line** |
| `--reg-t-machine` | **20** | 24 | 500 | 0.04 | UPPER + figures | M | Identity line, readout rows, chart labels |
| `--reg-t-prose` | **19** | 26 | 400 | 0 | Sentence | P | Mode prose, notes, export footer |
| `--reg-t-legend` | **18** | 22 | 500 | 0.10 | UPPER | M | Event slabs, LOAD / DEL legends, echo stack |

**The floor is 18 px and nothing in the product is smaller.** The brief proposed 17 px key legends; the 3am rule outranks the brief, so it is 18 and the rule is written here so it never drifts back. The brief proposed a 24 px mode line; it is **26**, because the mode line is the single most safety-critical string in the product — it is the thing standing between "press 2" and "two of the wrong quantity" — and it earns the extra two points.

There is no small text. There is no caption style. There is no disabled-grey. If a piece of information does not deserve 18 px, it does not deserve to be on a phone in a lambing shed.

### 3.4 Behaviour at 200 % text scale

Two response classes, plus one absolute rule.

**Class A — reading text. Scales linearly to 200 %.**

| Token | 100 % | 150 % | 200 % |
|---|---|---|---|
| `--reg-t-prose` | 19 | 29 | **38** |
| `--reg-t-machine` | 20 | 30 | **40** |
| `--reg-t-legend` | 18 | 27 | **36** |
| `--reg-t-mode` | 26 | 39 | **52** |
| `--reg-t-slab` | 28 | 42 | **56** |

**Class B — display figures. Already ≥ 3× the 18 px floor at rest; scales at a capped rate.**

| Token | 100 % | 150 % | 200 % | Multiple of the 18 px floor at 100 % |
|---|---|---|---|---|
| `--reg-t-tag` | 120 | 128 | **132** | 6.7× |
| `--reg-t-key` | 56 | 60 | **64** | 3.1× |
| `--reg-t-figure` | 34 | 42 | **48** | 1.9× |

**The absolute rule (Law 5): the key block is dimensionally frozen at 116 × 76 with a 10 px gutter at every text scale.** All reflow is absorbed by the register head, which is not a tap target. This is a documented, deliberate deviation from a literal reading of WCAG 1.4.4 for the ten digit keys only, argued on the ground that a 56 px digit is *already* 311 % of the 18 px accessibility floor before the user scales anything — the intent of 1.4.4 is satisfied at rest. Everything that is genuinely reading text scales fully.

**How the 759 pt budget absorbs 200 %:**

| Zone | 100 % | 200 % | How |
|---|---|---|---|
| Register head | 199 | **151** | Echo stack (3 lines) suppressed; recall moves under MORE. Tag band 108 + one 40/43 identity line. |
| Mode line | 48 | **60** | Grows with the type. |
| Key block | **334** | **334** | Frozen. |
| Action band | 154 | **190** | Primary slab 84→96; event slabs 60→84 with two-line legends. |
| Zone gutters | 24 | 24 | Fixed. |
| **Total** | **759** | **759** | |

At 150 % the echo stack drops from three lines to one, and readouts print their first four rows plus `+ N MORE — TYPE MORE DIGITS TO NARROW`. Nothing scrolls. Nothing moves.

---

## 4. Space, geometry and grid

### 4.1 The five welded zones

```
┌───────────────────────────────────────────────┐  y=0    (below top safe area)
│  ZONE 1 · REGISTER HEAD                199 pt │
│     412            ◄ 120px, bloom             │
│     412 · 3 SEASONS · AVG 2.0 · ASSISTED x2   │
│     ─ echo stack, 3 lines, never scrolls ─    │
├───────────────────────────────────────────────┤  y=207
│  ZONE 2 · MODE LINE (welded)            48 pt │
│     LITTER — HOW MANY LAMBS?                  │
├───────────────────────────────────────────────┤  y=263
│  ZONE 3 · KEY BLOCK  3 × 4             334 pt │
│    ┌────┐ ┌────┐ ┌────┐                       │
│    │ 1  │ │ 2  │ │ 3  │   116 × 76, gutter 10 │
│    ├────┤ ├────┤ ├────┤                       │
│    │ 4  │ │ 5  │ │ 6  │                       │
│    ├────┤ ├────┤ ├────┤                       │
│    │ 7  │ │ 8  │ │ 9  │                       │
│    ├────┤ ├────┤ ├────┤                       │
│    │LOAD│ │ 0  │ │ DEL│   ◄ recessed = operator│
│    └────┘ └────┘ └────┘                       │
├───────────────────────────────────────────────┤  y=605
│  ZONE 4 · PRIMARY SLAB      368 × 84          │
│  ┌─────────────────────────────────────────┐  │
│  │        L A M B E D                      │  │
│  └─────────────────────────────────────────┘  │
├───────────────────────────────────────────────┤  y=699
│  ZONE 5 · EVENT RAIL  5 × (64 × 60)     60 pt │
│  [TREAT][NOTE][DIED][ PEN ][MORE]             │
└───────────────────────────────────────────────┘  y=759
```

**Eighteen fixed positions. Twelve keys, one primary slab (which may split into two or three), five event slabs.** The only additional targets that ever exist are **candidate slabs in the register head during LOAD**, and they vanish the instant a subject is loaded.

**Vertical budget on the 393 × 852 reference (759 pt content box):**

| Zone | Height | Cumulative |
|---|---|---|
| Register head | 199 | 199 |
| gutter | 8 | 207 |
| Mode line | 48 | 255 |
| gutter | 8 | 263 |
| Key block (4 × 76 + 3 × 10) | 334 | 597 |
| gutter | 8 | 605 |
| Primary slab | 84 | 689 |
| gutter | 10 | 699 |
| Event rail | 60 | **759** |

**Devices shorter than 812 pt logical** (iPhone SE, 13 mini): the echo stack drops to one line and the primary slab clamps to 76. This is the *only* permitted responsive change; the key block never reflows. Devices taller than 852: the surplus goes entirely to the echo stack, up to five lines.

### 4.2 The spacing scale

Built on a 2 pt base. There are nine values and no others.

| Token | px | Use |
|---|---|---|
| `--sp-1` | 2 | Optical nudges, bevel offsets |
| `--sp-2` | 4 | Inside a badge, between a `▮` and its label |
| `--sp-3` | 6 | Between the tag and the identity line |
| `--sp-4` | 8 | **Zone gutter.** Between the five welded zones |
| `--sp-5` | **10** | **The dead gutter.** Between keys and between slabs. |
| `--sp-6` | 12 | Face margin (left/right), event-rail gutter |
| `--sp-7` | 16 | Inside the readout pane, row padding |
| `--sp-8` | 24 | Between readout groups |
| `--sp-9` | 32 | Between the readout header and its rows |

**Why 10 pt is called the dead gutter.** It is not decoration and it is not rhythm. It is the guaranteed non-responsive band that makes it physically impossible for a gloved fingertip — contact patch 14–20 mm through a nitrile glove or a freezer bag — to straddle two keys and produce an ambiguous press. There is no hit-slop extension into the gutter. A press that lands in the gutter does nothing, silently, and that is the correct behaviour: **a null press is recoverable; a wrong press against a loaded ewe is not.**

### 4.3 Geometry

**Radii — nothing above 4 px anywhere in the product.**

| Token | px | Applied to |
|---|---|---|
| `--r-0` | 0 | Bands, rules, the withdrawal band, chart bars, the readout pane |
| `--r-1` | 2 | Inert plates, badges, check cells |
| `--r-2` | **4** | Keys, slabs, pen tiles. The maximum. |

A soft corner is a soft affordance. This instrument is hard-edged because the operator needs to know where a control stops, not to be reassured that it is friendly.

**Strokes.**

| Token | px | Use |
|---|---|---|
| `--stroke-hair` | 1 | The top-light bevel. The load-bearing key boundary. |
| `--stroke-rule` | 2 | Bottom shadow rule; readout row separators; chart bar outlines |
| `--stroke-heavy` | 3 | The overstrike through a dead lamb's numeral; the DIED slab border |
| `--stroke-double` | 4 | `2 + 2 gap + 2` — the over-threshold badge and the contradiction frame |

**The bevel, precisely.** A key at rest: `border-top: 1px solid var(--reg-bevel)` and `box-shadow: inset 0 -2px 0 var(--reg-etch), 0 2px 0 #000`. On press: face lifts to `--reg-keypress`, the 1 px bevel moves to `border-bottom`, and the outer 2 px black shadow is removed — the key visibly sinks into the face. At 10 nits of screen brightness this is the difference between a key that reads as an object and a rectangle that reads as a picture of one.

### 4.4 Reach and the thumb arc

A one-handed right grip on a 393 × 852 device pivots at roughly **(330, 800)** in content coordinates, with a comfortable thumb sweep of ~300 pt radius and a maximum of ~360 pt.

- **Primary slab** (y 605–689) and **event rail** (y 699–759): dead centre of the comfortable arc. The single most important target in the product — `LAMBED` at 368 × 84 — is the easiest thing on the phone to hit.
- **Key rows 4 (LOAD/0/DEL) and 3 (7/8/9)**: 60–160 pt from the pivot. Trivially inside.
- **Key row 1 (1/2/3)**, y 263–339: 290–340 pt from the pivot — the edge of comfortable, inside maximum. This is a *conscious* trade.

**Why keep the phone-dialler layout instead of a calculator layout.** Putting `789` on the top row would move the most-used digits closer to the thumb. It is rejected: multi-digit tag entry is the only sustained typing in the product, and the operator's phone-dialler muscle memory is decades deep and pre-existing. Inventing a new digit layout to recover 40 pt of reach spends the exact asset — muscle memory — that Law 5 exists to protect.

**Operator keys at the bottom corners.** `LOAD` bottom-left, `DEL` bottom-right, both on the row nearest the pivot, so both are inside the comfortable arc for either hand. They are recessed rather than raised, so a thumb finds them by *feel of the layout* as much as by sight: the bottom row is the only row where the outer two keys are holes rather than blocks.

**Zone 1 is never a tap target while a subject is loaded.** The top 199 pt of the display — the hardest region to reach one-handed — carries only reading. This is not an accident of layout; it is the layout.

---

## 5. Motion

### 5.1 The doctrine

**An instrument does not animate. It changes state.** Every millisecond of transition in this product is a millisecond in which the display is showing something that is not true. On a screen where a number can be a withdrawal period, that is unacceptable.

The system therefore has **one** animation.

### 5.2 The complete inventory of motion

| What | Duration | Curve | Notes |
|---|---|---|---|
| **Commit flash** | 0 ms in, hold **800 ms**, 120 ms out | linear out | `--reg-commit` fills the written value in the head and a 4 px rule across the head's top edge. The only animation in the product. |
| Key press-in | **0 ms** | — | Applied on `pointerdown`. Instant, always. |
| Key press-out | **0 ms** | — | Applied on `pointerup`. Instant, always. |
| Slab press | **0 ms** in, **120 ms** out | linear | The 120 ms release is a courtesy so a fast double-press is visible as two presses. |

That is the entire list.

### 5.3 What must never animate

- **Numerals never tween, roll, count or odometer.** A withdrawal counter rolling from 10 to 9 shows every integer between them; one of those frames is a number a tired operator can read and believe. Figures change by **hard print**.
- **The register head never crossfades.** A new subject replaces the old at 0 ms. A half-faded `412` over a half-faded `128` is exactly the wrong-ewe error the whole direction exists to prevent.
- **No page transitions**, because there are no pages. Summoning a readout is a hard cut.
- **Banned outright:** spinners and activity indicators (there is nothing to wait for — every write is a local synchronous SQLite commit), skeleton shimmer, progress bars, spring physics, bounce, parallax, pull-to-refresh, hero transitions, confetti, haptic-free "success" checkmarks, and every form of celebratory feedback. A shepherd who has just recorded a dead lamb is not to be congratulated.
- The **hours counters** (pen board, head status line) reprint once per minute, hard cut, no tween.

### 5.4 Haptics carry what motion would

The instrument talks to the thumb, not the eye, because the eye is on the lamb.

| Event | Haptic |
|---|---|
| Digit key press | Light impact (iOS `.light` / Android `KEYBOARD_TAP`) |
| Unique tag prefix auto-resolves | **Heavy impact — the thunk.** This is the "she is loaded" signal. |
| Any committed write | Double impact, medium, 90 ms apart |
| Contradiction flagged | Triple impact, heavy |
| Press landed in a dead gutter | **Nothing.** Silence is the signal that nothing happened. |

### 5.5 Under `prefers-reduced-motion: reduce`

- The commit flash **holds 1200 ms instead of 800** and releases at 0 ms — a hard cut in, a hard cut out. Longer, because there is no motion to catch the eye.
- The 120 ms slab release becomes 0 ms.
- Nothing else changes, **because there is nothing else.** Reduce-motion is close to a no-op in this system by construction, which is the strongest possible statement that the system did not need motion in the first place.

---

## 6. Iconography

### 6.1 The approach: there are no icons

Not "few icons". **None.** No pictograms, no glyph font, no line-art sheep, no syringe, no clipboard. Every affordance in this product is a **numeral or a word**.

The argument is not aesthetic. An icon is a symbol that must be learned and then recognised at speed under a head torch. A numeral is a symbol the operator learned at age five and has recognised several million times since. There is no icon in any icon set that a cold, tired shepherd will parse faster than the character `3`.

### 6.2 The five drawn primitives

Five marks exist. All are drawn as **inline SVG**, never as font glyphs, so they cannot be lost to a font-fallback path. All use `currentColor` so they inherit the theme and never need a red-shift variant. Stroke rule: **all strokes are 2 px, square-capped, on a 32 × 32 viewBox**, except the overstrike which is 3 px.

**1 — The check cell** (care checkboxes, pet-lamb toggle, settings booleans). 32 × 32, `--r-1`.

```svg
<!-- OFF -->
<svg width="32" height="32" viewBox="0 0 32 32" aria-hidden="true">
  <rect x="1" y="1" width="30" height="30" rx="2" fill="none"
        stroke="currentColor" stroke-width="2"/>
</svg>

<!-- ON — filled, not ticked. A tick is a picture; a filled cell is a state. -->
<svg width="32" height="32" viewBox="0 0 32 32" aria-hidden="true">
  <rect x="1" y="1" width="30" height="30" rx="2" fill="none"
        stroke="currentColor" stroke-width="2"/>
  <rect x="6" y="6" width="20" height="20" fill="currentColor"/>
</svg>
```

**2 — The armed caret**, printed at the head of the readout row a digit is about to act on. 32 × 32.

```svg
<svg width="32" height="32" viewBox="0 0 32 32" aria-hidden="true">
  <path d="M10 6 L24 16 L10 26 Z" fill="currentColor"/>
</svg>
```

**3 — The 45° hatch**, the non-colour channel of every alarm band. Tiled as an SVG `<pattern>`; 20 px wide end-cap only, never behind text.

```svg
<svg width="0" height="0" aria-hidden="true">
  <defs>
    <pattern id="reg-hatch" width="10" height="10"
             patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
      <rect width="10" height="10" fill="none"/>
      <line x1="0" y1="0" x2="0" y2="10" stroke="currentColor" stroke-width="4"/>
    </pattern>
  </defs>
</svg>
<!-- usage: <rect width="20" height="44" fill="url(#reg-hatch)"/> -->
```

**4 — The overstrike**, drawn through the numeral of any dead lamb, everywhere in the app, permanently. 3 px, ink-1, drawn as an absolutely positioned SVG so it survives text scaling.

```svg
<svg width="100%" height="100%" viewBox="0 0 100 40" preserveAspectRatio="none"
     aria-hidden="true">
  <line x1="0" y1="20" x2="100" y2="20" stroke="currentColor" stroke-width="3"/>
</svg>
```

**5 — The double rule**, the over-threshold badge and the contradiction frame. Pure CSS where possible (`border-top: 2px` + `::before` 2 px offset 4 px), SVG where it must span a tile:

```svg
<svg width="116" height="6" viewBox="0 0 116 6" aria-hidden="true">
  <line x1="0" y1="1" x2="116" y2="1" stroke="currentColor" stroke-width="2"/>
  <line x1="0" y1="5" x2="116" y2="5" stroke="currentColor" stroke-width="2"/>
</svg>
```

### 6.3 Typographic marks in the machine face

Three characters do symbolic work and are set in the machine font, at machine sizes:

- `!!` — the warning token. Always leads the string it warns about. Never used decoratively.
- `▮ ▯` — filled and hollow cell, printed *inline* in machine text where an SVG cell would be overkill (echo lines, readout summaries).
- `___` — the empty-value glyph. Three underscores. Reserved exclusively for a field the operator has not filled. **Never rendered as `0`.**

---

## 7. Component inventory

Real dimensions, on the 393 × 852 reference. Every interactive component clears 60 × 60 pt with margin.

### 7.1 KEY — digit (×10)

**116 × 76 pt.** `--r-2`. Face `--reg-keyface`. 1 px `--reg-bevel` top border, `inset 0 -2px --reg-etch`, `0 2px 0 #000`. Digit centred, `--reg-t-key` (56 px), `--reg-ink-1`. **No legend** — a caption reading "FOUR" under a `4` is an insult.

| State | Rendering |
|---|---|
| Default | As above. Boundary 3.51:1 against ground. |
| Pressed | Face → `--reg-keypress`; bevel migrates to the bottom border; outer shadow removed; digit stays `--reg-ink-1` (8.64:1). Light haptic. 0 ms in and out. |
| Inert | Face → `--reg-well`; no bevel; digit → `--reg-ink-2`; no press response, no haptic. Occurs only when nothing on the face is numbered (Law 2). |
| Warning | Never. A key is never a warning. Warnings live in the head. |

### 7.2 KEY — operator (LOAD, DEL)

**116 × 76 pt**, same module, **recessed instead of raised**: face `--reg-well`, 1 px `--reg-bevel` on the *bottom* border, `inset 0 2px 0 #000`. Legend `--reg-t-legend` (18 px, tracked 0.10, caps), `--reg-ink-1`.

The geometry inversion is the point: **raised keys are values, recessed keys are operators.** You can tell them apart by shape in near-darkness, which means you can never mistake `LOAD` for a digit.

- **`LOAD`** — permanent, live in **every state of the app without exception**. Clears the entry buffer and puts the head into candidate mode. This is the escape hatch that makes an always-loaded subject safe: you are never more than one press from changing who you are writing about.
- **`DEL`** — one invariant meaning: **remove the last thing you did.** With digits in the buffer, that is the last digit. With no digits in the buffer, that is the last committed value in the current mode, and the echo prints `UNWROTE LITTER 2 · 03:24`. Never silent, never a bulk undo.

### 7.3 PRIMARY SLAB — the primary action target

**368 × 84 pt** full width, or split into **2 × 179** or **3 × 116**, gutter 10. `--r-2`. Face `--reg-keyface`, 1 px `--reg-bevel` top, legend `--reg-t-slab` (28 px, tracked 0.10, caps), `--reg-ink-1` at 9.79:1.

| State | Rendering |
|---|---|
| Default | Above. Legend names the write in full: `LAMBED`, `CREATE 412 AND CARRY ON`, `TURN OUT PEN 4`. |
| Pressed | Inverts: face `--reg-ink-1`, legend `--reg-ground` at **10.91:1**. 0 ms in, 120 ms out. Double haptic. |
| Committing | Face `--reg-commit`, legend `--reg-ground` at **8.47:1**, 800 ms. In red-shift: face `--reg-commit` `#FF9E6B`, legend `--reg-ground` at **10.04:1**. |
| Disabled | Face `--reg-well`, no bevel, legend `--reg-ink-2`, **and the legend states the reason**: `NOTHING LOADED — PRESS LOAD`. A disabled control that does not say why is a dead end. |
| Warning | 3 px `--reg-alarm` border + `!!` prefix. Used by `DELETE EVERYTHING — CANNOT BE UNDONE` and by the two contradiction slabs. |

### 7.4 EVENT SLAB — the permanent rail (×5)

**64 × 60 pt**, 12 pt gutters, `--r-2`. Legends `TREAT` · `NOTE` · `DIED` · `PEN` · `MORE`, `--reg-t-legend` (18 px). **These five legends never change for the life of the app.** Live in every state where a subject is loaded.

`DIED` is the one slab with a permanent 3 px `--reg-alarm` border and `--reg-alarm` legend (5.62:1). **On press it inverts to ground-on-red (5.62:1)** rather than lifting, because `--reg-alarm` on `--reg-keypress` is 4.45:1 and would fail. This is one of the two places red appears in the entire product.

### 7.5 REGISTER HEAD

**368 × 199 pt.** Face `--reg-panel`. Never a tap target while a subject is loaded. Composed of:

- **Tag band, 108 pt.** `--reg-t-tag` (120 px), `--reg-ink-1`, bloom α 0.22 (worst case 7.18:1). Optional lamb suffix at `--reg-t-tag-suffix` (56 px), baseline-aligned right of the tag: `412` `/3`.
- **Identity line, 24 pt.** `--reg-t-machine` (20 px), `--reg-ink-1`. One dense machine string: `412 · 3 SEASONS · AVG 2.0 · ASSISTED x2 · PROLAPSED 2025`.
- **Echo stack, 3 × 22 pt.** `--reg-t-legend` (18 px), `--reg-ink-2` at 6.42:1. **Non-scrolling, capped at three lines, forever.** Content is state-dependent and occupies the same three positions either way: when idle-loaded it prints the three most recent *seasons* (recall); mid-mode it prints the three most recent *writes* (confirmation). Same lines, same place, two jobs.

Warning states: the head's frame becomes `--stroke-double` and a `!!` string prints on the top echo line.

### 7.6 CANDIDATE RACK SLAB

**116 × 64 pt**, up to 6, in the head, **only during LOAD**. Face `--reg-keyface`, 1 px bevel, figure `--reg-t-figure` (34 px). Carries the recents strip (412, 128, 305, 77, 219, 12), the "in the pens" list, and partial-match candidates. Vanishes the instant a subject resolves — the head returns to being untappable.

### 7.7 EWE ROW — readout

**368 × 48 pt**, 2 px `--reg-etch` bottom rule, `--sp-7` horizontal padding. Set in `--reg-t-machine` (20 px), tabular. Structure, left to right:

`▸ | index | tag | state | figures`

Example rows, verbatim:

```
1  412   PEN 4 · 31H   !! OVER   TRIPLET 03:20   2 LIVE 1 DEAD
2  128   LAMBED YESTERDAY         TWIN            2 LIVE
3  305   PEN 7 · 26H   !! OVER   REARING FOSTER  3 LAMBS
4   77   UNDER TREATMENT · WITHDRAWAL CLEAR 12 AUG · 9 DAYS
5  219   NOT YET LAMBED · SCANNED TWIN
6   12   BARREN
7  340   NOT YET LAMBED
8   91   PEN 3 · 18H              SINGLE          1 LIVE
```

| State | Rendering |
|---|---|
| Default | `--reg-ink-1` for the tag, `--reg-ink-2` for the state string (6.42:1). |
| Armed (a digit has selected it) | Full-row inversion: `--reg-ground` on `--reg-ink-1`, **10.91:1**, plus the `▸` caret. |
| Warning | The state string carries `!!` and the row gains a 2 px `--reg-alarm` left edge. |
| Withdrawal | The row's right 140 pt becomes the withdrawal band (§7.9). |

Rows are readouts, not buttons — you act on a row by pressing its **number**, which is printed on it. (Law 2.)

### 7.8 PEN TILE

**116 × 56 pt**, `--r-2`, in a **3 × 4 grid** inside the head — the same shape as the key block, deliberately. Face `--reg-keyface`, 1 px bevel.

```
┌──────────────┐        ┌══════════════┐   ← 4px double rule = OVER
│ 4            │        │ 4            │
│ 412          │        │ 412       !! │
│ 2L · 31H     │        │ 2L · 31H     │
└──────────────┘        └══════════════┘
```

- Pen number top-left, `--reg-t-legend` (18 px), `--reg-ink-2`.
- Occupant tag, `--reg-t-figure` (**34 px**), `--reg-ink-1` — the number you read from arm's length.
- Lamb count + hours, `--reg-t-legend` (18 px), `--reg-ink-1`.

| State | Rendering |
|---|---|
| Occupied | As above. |
| Empty | Face `--reg-well`, no bevel, prints `2` and `EMPTY` in `--reg-ink-2`. Recessed, so an empty pen reads as a *hole* in the board at a glance. |
| Over threshold | 4 px double rule welded across the top edge **plus** the printed token `!! OVER` **plus** the hours in an inverted 44 × 22 cell (10.91:1). Three channels, none of them colour. |
| Armed | Whole tile inverts: `--reg-ground` on `--reg-ink-1`, 10.91:1. |

### 7.9 COUNTDOWN / WITHDRAWAL BAND

**368 × 44 pt** full width in the head, or **140 × 40 pt** inline in an ewe row. `--r-0` — square, because it is a band, not a control.

Fill solid `--reg-alarm` `#FF3B1F`, text `--reg-ground` at **5.62:1**, `--reg-t-machine` (20 px). A **20 pt 45° hatch end-cap** on the left, never behind text.

```
▨▨│ !! WITHDRAWAL · ALAMYCIN LA · CLEAR 12 AUG 2026 · 9 DAYS
▨▨│ !! WITHDRAWAL — DAYS NOT ENTERED · ___
```

| State | Rendering |
|---|---|
| Active | Days remaining, tabular, reprinted once per day at midnight. Hard cut. |
| Days not entered | Prints `___`, never `0`. The band persists on that animal in every readout until a number is typed. |
| Clearing today | `CLEAR TODAY` — no colour change, the *word* changes. |
| Cleared | The band is removed and a `--reg-ink-2` echo line remains: `WITHDRAWAL CLEARED 12 AUG · ALAMYCIN LA`. History is never deleted. |

### 7.10 STATUS BADGE

Not a pill, not a dot. **A printed token** in `--reg-t-legend` (18 px, tracked 0.10) with a 2 px `--reg-ink-1` box, `--r-1`, 4 pt padding — minimum **44 × 26 pt**. The complete vocabulary, and it is closed:

`!! OVER` · `!! MISMATCH` · `PENNED` · `LAMBED` · `BARREN` · `TREATED` · `FOSTERED` · `DEAD` · `NEW` · `TIME AUTO` · `TIME EDITED` · `PET`

A badge is always a **word**. There is no badge whose meaning must be inferred from its colour or its position.

### 7.11 NUMBER STEPPER

**This component does not exist as a widget, and that is the design.** A stepper is a small drag-adjacent target with two 24 pt hit areas — precisely the control the 3am test bans (thin targets, cold fingers, poor capacitance).

Every quantity in the product is **typed on the twelve keys**. Where a conventional design would reach for a stepper — pet-lamb feed count, reminder interval, turn-out threshold hours — the value is typed, and where an increment genuinely helps (feed count, which goes up by one many times a day), the primary slab **splits into a two-slab stepper**:

**2 × 179 × 84 pt**, gutter 10. Legends `−1 FEED` and `+1 FEED`, `--reg-t-slab` (28 px). The current value prints in the head at `--reg-t-tag` — a feed count of `4` is a 120 px numeral, which is absurd and correct: you can see it from the pen gate.

| State | Rendering |
|---|---|
| Default / Pressed / Committing | Exactly as the primary slab (§7.3). Every press is its own write. |
| Disabled | `−1` disables at zero and its legend becomes `−1 FEED — ALREADY 0`. |

### 7.12 SEGMENTED CHOICE

There are **two kinds**, and only the second is a real control.

**(a) Numeric choice — birth type, lambing ease.** Not a control at all: a **numbered readout strip** in the head, 368 × 56 pt, that tells you what your keys currently mean. You choose by pressing the key.

```
BIRTH TYPE   1 SINGLE   2 TWIN   ▮3 TRIPLET   4 QUAD   5 MORE
EASE         1 ▯   2 ▯   ▮3   4 ▯   5 ▯     3 = ASSISTED, EASY CORRECTION
```

Each cell is 68 × 56 pt (birth type) or 68 × 48 pt (ease). Selected cell: **inverted**, `--reg-ground` on `--reg-ink-1` at 10.91:1, **plus** the `▮` marker. Unselected: outline 2 px `--reg-etch`, label `--reg-ink-2`, `▯` marker. Two non-colour channels.

**(b) Non-numeric binary — sex, alive/dead, units, temperature.** These are genuinely not numbers, so under Law 1 they may not be on keys. They occupy the **primary slab split in two**: `2 × 179 × 84 pt`, `EWE LAMB` / `RAM LAMB`, `ALIVE` / `DEAD`, `KG` / `LB`. Selected slab is inverted and carries `▮`. Pressing either is a write.

### 7.13 CHECK CONTROL

A **numbered check row**, 368 × 48 pt, 2 px `--reg-etch` bottom rule. Cell is the 32 × 32 SVG from §6.2, `--sp-2` from its label.

```
CARE — PRESS 1-4 TO TOGGLE. EACH PRESS IS A WRITE.
1  ▮  COLOSTRUM GIVEN        03:26
2  ▯  NAVEL DIPPED
3  ▮  STOMACH TUBED          03:31
4  ▯  WARMED
```

| State | Rendering |
|---|---|
| Off | Hollow cell, label `--reg-ink-2` (6.42:1) |
| On | Filled cell, label `--reg-ink-1` (10.34:1), **and the time of the write prints** — because it was a write, and writes are timestamped |
| Pressed | Row inverts for the duration of the press |
| Warning | Never. A care check cannot be wrong. |

Note that the check row is not tappable. **You toggle it by pressing its number**, which is printed on it. This is Law 2 doing real work: the four care items and the digits `1-4` are the same object.

### 7.14 CHART — the lambing spread

**368 × 140 pt** inside the readout pane. Face `--reg-panel`. 14 columns across 368 pt: bar **18 pt** wide, gutter **8 pt**, 4 pt end margins.

- **2026 bars:** solid `--reg-ink-1` fill, **10.34:1** on panel. Peak 14 → 112 pt tall (8 pt per lamb).
- **2025 comparison:** a **2 px outline** overlay in `--reg-ink-2`, **6.42:1** on panel. Filled vs. outline is the differentiator — not hue, not opacity.
- **Baseline:** 2 px `--reg-etch`. Gridlines at 5 and 10: 1 px `--reg-etch`, dashed 2/6.
- **Day labels:** `--reg-t-legend` (18 px) under every bar, `--reg-ink-2`.
- **No value labels above the bars** — 14 of them at 18 px will not fit and shrinking them below 18 px is forbidden. Instead: `TYPE A DAY 1-14` on the mode line, and pressing `4` arms day 4, which **inverts that bar** and prints the value into the head at 120 px: `DAY 4 · 14 BORN`. The chart is a shape; the keypad is the readout.

| State | Rendering |
|---|---|
| Default | As above |
| Armed day | That bar inverts to a 2 px `--reg-ground` outline on solid `--reg-ink-1`; its day label inverts too |
| Zero day (day 13) | A 2 px `--reg-etch` stub on the baseline **plus** the label `0` — a zero must be visibly a measured zero, not a missing bar |

### 7.15 TEXT FIELD — the detour

Free text exists for exactly four things: notes, product names, batch numbers, and the `DELETE` confirmation word. It is **explicitly announced as a detour**, because summoning the OS keyboard destroys the instrument face and that must never happen by accident.

**368 × 96 pt.** Face `--reg-well`, 2 px `--reg-etch` border, `--r-1`. Input `--reg-t-prose` (19 px humanist, sentence case — **the only place lowercase exists**), `--reg-ink-1` at 10.91:1 on well. Placeholder is never grey-on-grey: it is `--reg-ink-2` and it is a full instruction.

The mode line above it reads, at 26 px: **`TEXT — THE KEYS ARE GONE. PRESS DONE TO GET THEM BACK.`**

| State | Rendering |
|---|---|
| Default | Empty, showing `___` and the placeholder instruction |
| Focused | 2 px border → `--reg-ink-1`; the key block goes **inert** (recessed, `NOTHING TO NUMBER` on the mode line) because the OS keyboard now owns input |
| Committed | On dismiss, the text writes immediately and prints into the echo. There is no Save. |
| Warning | The batch-number field warns `!! CHECK 0 AND O` if the string mixes them — flagged, never corrected (§1.4 corollary / spec §12.4) |

### 7.16 INERT PLATE

**368 × 44 pt.** Face `--reg-well`, no bevel, no press response, no haptic, `--r-1`, text `--reg-t-machine` (20 px) `--reg-ink-2` at 6.42:1 — dim, but never below legibility.

There is exactly one in the product and it appears in exactly one place: the DAYS OFF mode, where it reads **`[ NO DEFAULT VALUES ]`**. It exists to occupy, visibly and permanently, the space where every competitor's app puts a helpful suggestion. Its inertness *is* the message.

### 7.17 MODE LINE

**368 × 48 pt**, welded, always present, never a tap target. `--reg-t-mode` (26 px, tracked 0.12, caps), `--reg-ink-1` at 10.91:1, centred, 2 px `--reg-etch` rules above and below.

Where a mode needs a sentence, the mode line grows a second line at `--reg-t-prose` (19 px humanist) and the head gives up one echo line to pay for it. This is the *only* place the zone budget flexes at runtime, and it flexes into the head — never into the keys.

Complete mode-line vocabulary (closed set, one per mode):

```
412 LOADED — WHAT HAPPENED?
LOAD — TYPE A TAG
LITTER — HOW MANY LAMBS?
EASE 1-5 — HOW HARD WAS IT?
LAMB 1 SEX
LAMB 1 ALIVE OR DEAD
LAMB 1 WEIGHT KG — SKIPPABLE
CARE — PRESS 1-4 TO TOGGLE
DOSE — HOW MUCH?
ROUTE — PRESS 1-6
DAYS OFF — READ IT FROM THE BOTTLE. YOUR ENTRY.
PEN — TYPE A PEN NUMBER 1-12
TIME — TYPE HHMM
SPREAD — TYPE A DAY 1-14
NOTHING TO NUMBER
TEXT — THE KEYS ARE GONE. PRESS DONE TO GET THEM BACK.
```

---

## 8. Per-screen layout direction

There are no screens. There are **twelve states of one instrument face**, and in every one of them the twelve keys are in the same place and mean the same thing.

Readouts summoned by `MORE` print into **zones 1–2** (head + mode line, 255 pt). They never cover the keys. The keys stay live underneath, because on almost every readout there is something numbered to press.

---

### Screen 1 · FLOCK

The flock is **not a list**. A list is a document, and this direction does not have documents. It is a **count board**: five numbered filters, each with its membership printed as pressable numerals.

```
FLOCK 2026 · 8 EWES ON REGISTER
1  ALL                 8
2  NOT YET LAMBED      2    219  340
3  IN THE PENS         3    412  305  128
4  UNDER TREATMENT     2    77   219
5  BARREN              1    12
```
`MODE: FLOCK — PRESS 1-5 TO FILTER, OR TYPE A TAG TO LOAD`

Press `3` and the head fills with the members of "in the pens" as a **candidate rack** of 34 px numerals, each one a slab — one tap loads that ewe and the head becomes her card. Or ignore the filters entirely and just type `4` `1` `2`, which is what an operator who knows their flock actually does. **The quick-add affordance is the same gesture**: type a tag that does not exist and the head prints `412 NEW` with the primary slab legended `CREATE 412 AND CARRY ON` — you never leave to go and set something up first.

Full-text search across notes is a detour (§7.15), reached by `MORE → 9 SEARCH`; results print as a numbered readout capped at four rows plus `+ N MORE — TYPE MORE DIGITS TO NARROW`. Filtering by typing is always faster than filtering by pressing, and the system rewards that.

---

### Screen 2 · EWE CARD — 412

**There is no ewe card. The register head *is* the ewe card**, and it has been on screen the whole time. This is the direction's single hardest claim and its biggest payoff: at 3am you do not open a record, you read the thing that is already the largest object on the phone.

```
        412                                    ← 120px, bloom
412 · 3 SEASONS · AVG 2.0 · ASSISTED x2 · PROLAPSED 2025
PEN 4 · 31H · !! OVER · TRIPLET 03:20 TODAY · 2 LIVE 1 DEAD
2026  TRIPLET  EASE 3  ASSISTED  03:20 TODAY  2 LIVE 1 DEAD
2025  TWIN     EASE 2  PROLAPSED AFTER LAMBING
2024  TWIN     EASE 1
```
`MODE: 412 LOADED — WHAT HAPPENED?`
`SLAB: [ L A M B E D ]`   `RAIL: [TREAT][NOTE][DIED][PEN][MORE]`

The one-line summary the product spec demands (§7.7) is line 2, above everything, at 20 px tabular. Three seasons of history are the echo stack — three lines, no scroll, no expand, no "view all". **The fourth season, when it exists, does not push the third off a page; it pushes it off the *readout*,** and older seasons are reached by `MORE → 4 SEASONS`, which prints them the same way. History is a value, not a document.

Actions are already on the face and always have been: `LAMBED` on the primary slab, and `TREAT` / `NOTE` / `PEN` on the permanent rail. **Zero taps of navigation to a ewe you were already holding.**

---

### Screen 3 · QUICK ENTRY — the 3am screen

This screen does not exist either, and that is the entire thesis. **Quick entry is not a mode you enter. It is what the instrument is when nothing else is happening.**

**Cold launch.** You press the side button. The first painted frame is `#0A0806` carrying the head chrome and the twelve bevels — no splash, no logo, no white flash, no "welcome back". The clock is already running. The keys are already live. **And 412 is still loaded**, because she was loaded eleven minutes ago when you last touched the phone and nothing has told the register to let her go. State restoration is not a nicety here; it is the mechanism.

**If it is her — which at 3am it usually is.** Press the 368 × 84 `LAMBED` slab. **That press is the commit.** There is no confirmation, no "are you sure", no next screen. The head prints:

```
412 · LAMBED 03:24 · TIME AUTO
```

commit green for 800 ms, double haptic, and you can put the phone in your pocket. **A correct thin record exists after one press, in under two seconds.** Everything from here is optional enrichment of a record that is already on disk.

**If it is not her.** Press `LOAD` — bottom-left, recessed, permanent, live in every state the app can be in. The head clears to a candidate rack and the mode line reads `LOAD — TYPE A TAG`.

Now type. Show the keypad **mid-entry with `12` typed**:

```
                12___                          ← the buffer, 120px, bloom
MATCHES 3
┌──────┐ ┌──────┐ ┌──────┐
│ 412  │ │ 128  │ │  12  │       ← candidate slabs, 116 × 64, 34px
│PEN 4 │ │LAMBED│ │BARREN│
└──────┘ └──────┘ └──────┘
RECENTS   412  128  305  77  219  12
```
`MODE: LOAD — TYPE A TAG`

Partial matching is on every position, not just the prefix (§7.1 of the product spec: typing `12` surfaces 412, 128, 12). Up to three candidates stack in the head as tappable slabs; the six recents sit beneath as a second rack — **the ewe you just handled is usually the ewe you are still handling**, and "in the pens" occupants sort to the front of that rack because a penned ewe is the one you are standing next to.

**A unique prefix auto-resolves with a heavy haptic thunk** — no confirm press. Type `3` `0` `5` and if 305 is the only match, she loads on the third digit and the thumb feels it. Four presses from a cold phone to a loaded ewe.

**An unknown tag never blocks.** Type `4` `7` `7` where no 477 exists and the head reads `477 NEW`, the primary slab legends `CREATE 477 AND CARRY ON`, and one press creates her and loads her. Nothing in this app ever sends you away to set something up first.

**Then the mode chain, and this is where the direction earns its name.** Press `LAMBED` — the lambing is already written. *Only then* does the mode line change:

| Mode line (26 px, welded) | You press | What is written |
|---|---|---|
| `412 LOADED — WHAT HAPPENED?` | `LAMBED` slab | Lambing event, `TIME AUTO 03:24` |
| `LITTER — HOW MANY LAMBS?` | `2` | birth_type = twin |
| `EASE 1-5 — HOW HARD WAS IT?` | `3` | ease = 3 |
| `LAMB 1 SEX` | `EWE LAMB` slab | lamb 1 sex |
| `LAMB 1 WEIGHT KG — SKIPPABLE` | `4` `1` | 4.1 kg (tenths implicit, printed live) |

**The keys did not move and did not change meaning.** In every row of that table, pressing `2` means *two*. The mode line — 26 px, all caps, welded between the head and the keys, impossible to miss and impossible to be somewhere else — says in words what the two is attached to. This is the whole safety argument compressed into one line of type.

**Every press is its own committed write.** Walking away after `LAMBED` leaves a lambing. Walking away after `2` leaves a lambing with twins. There is no Save, because nothing was ever pending, because the phone is going to die at some point tonight and this app has already assumed it.

**Timing.** Unlock → she is already loaded → `LAMBED` → `2` → `3`. **Four presses. About six seconds.** Against the spec's fifteen-second budget, with nine seconds of headroom for a ewe who needs re-loading.

**The event rail** carries the other four: `TREAT`, `NOTE`, `DIED`, `PEN`. They are in the same five positions in every state of the app. `LAMBING` is not on the rail because it is the 3am event and it gets the whole 368 pt width to itself.

**In `TREAT` mode**, the mode line reads `DAYS OFF — READ IT FROM THE BOTTLE. YOUR ENTRY.` over an empty field showing `___`. The head carries the inert `[ NO DEFAULT VALUES ]` plate, and the ewe wears a red `WITHDRAWAL — DAYS NOT ENTERED` band until a number is typed. (Spec §12.1.)

**On a contradiction** — a declared twin against three lambs on record — the head's frame becomes a 4 px double rule, a triple heavy haptic fires, and it prints:

```
!! DECLARED TWIN · 3 LAMBS ON RECORD
```

The primary slab splits into exactly two: `CHANGE TO TRIPLET` and `LEAVE IT — 3 IS RIGHT`. **There is no third slab and the app never picks.** Neither is pre-focused. Neither is styled as recommended. If the operator walks away, the flag stays on the record as `!! MISMATCH` and prints in every readout that ewe appears in, forever, until they resolve it. (Spec §12.4.)

---

### Screen 4 · LAMBING ENTRY — ewe 412

The lambing entry is the mode chain from screen 3, continued. It has no separate face. The head does the recording and the mode line does the asking.

```
        412                                    ← still her, still 120px
412 · LAMBED 03:20 · TIME AUTO · EDITABLE
BIRTH TYPE   1 SINGLE  2 TWIN  ▮3 TRIPLET  4 QUAD  5 MORE
EASE         1 ▯  2 ▯  ▮3  4 ▯  5 ▯
WROTE TRIPLET 03:21  ·  WROTE EASE 3 03:21  ·  WROTE LAMB 1 03:22
```
`MODE: EASE 1-5 — HOW HARD WAS IT?`

Birth type and ease are **numbers**, so they are the keypad. Sex and alive/dead are **not** numbers, so under Law 1 they are slab pairs. Weight is tenths on the keypad. Care is a numbered check strip. Assistance detail and the note are text detours, announced.

**Every field except birth type is skippable, and the face makes that structurally obvious**: the mode chain never blocks, `LOAD` is live at every step, and a skipped field simply prints `___` in the readout instead of a value. There is no required-field asterisk, no validation on advance, no greyed-out Next. The three lamb rows print as:

```
LAMB 1  EWE LAMB   ALIVE   4.1 KG
LAMB 2  RAM LAMB   ALIVE   3.8 KG
LAMB 3  RAM LAMB   D̶E̶A̶D̶    ___          ← overstruck, permanently
```

The auto-captured time carries the token `TIME AUTO`. Press it — sorry, *press `MORE → 2 TIME`* — and the mode becomes `TIME — TYPE HHMM`; type `0` `3` `2` `0` and the record thereafter prints `TIME EDITED 03:20 (WAS 03:47)`. The original is never destroyed. (Spec §12.5.)

---

### Screen 5 · LAMB CARD — lamb 1 of 412

A lamb is addressed as **dam-slash-order**: `412/1`. With 412 loaded, press `LOAD` a second time and the mode line reads `LAMB OF 412 — WHICH ONE? 1-3`; press `1`. The head carries the dam tag at 120 px and the suffix at 56 px, so **you can never lose track of whose lamb you are looking at** — the dam is still the largest object on the phone.

```
        412 /1
412/1 · EWE LAMB · 4.1 KG · ALIVE · BORN 03:20 TODAY
BIRTH DAM 412 — PERMANENT
REARING DAM 305 — FOSTERED 06:10 TODAY
PET ▮ · FEEDS 4
```
`MODE: 412/1 LOADED — WHAT HAPPENED?`
`SLAB: [ −1 FEED ][ +1 FEED ]`   `RAIL: [TREAT][NOTE][DIED][PEN][MORE]`

Tag, weigh and foster live under `MORE` (`1 TAG`, `2 WEIGH`, `3 FOSTER`). Death is on the permanent rail as `DIED` — the only red key in the product — because a lamb dying at 4am is not a thing to go looking for in a menu. Pressing it puts the mode line into `CAUSE — PRESS 1-8` over the numbered cause list from the product spec (starvation, hypothermia, watery mouth, joint ill, crushed, stillborn, unknown, other). Eight causes, eight digits, Law 2 satisfied.

---

### Screen 6 · FOSTER

The flow most likely to be abandoned if it takes five taps, so it takes **two**.

With `412/3` loaded, press `MORE` then `3 FOSTER`. The head immediately prints the thing that matters:

```
        412 /3
BIRTH DAM 412 — PERMANENT, NEVER CHANGES
REARING DAM 412 → ___ 
RECENTS   305  128  77  219  12  91
```
`MODE: FOSTER — TYPE THE REARING DAM'S TAG`

Tap `305` in the recents rack. **That is tap two.** The primary slab confirms and commits in one:

```
[ FOSTER 412/3 TO 305 ]
```

After the write, the head prints permanently:

```
BIRTH DAM 412 — PERMANENT · REARING DAM 305 — FOSTERED 06:10 TODAY
```

The word `PERMANENT` is set in the machine face next to the birth dam in every state, on every readout, forever. **The two fields are never merged, never collapsed into "dam", and never presented as one editable value** — which is the entire reason the product spec insists on them separately. 412's lambing percentage counts three lambs. 305's rearing record counts three lambs. Neither number lies.

---

### Screen 7 · PEN BOARD

The digital whiteboard, and the feature paper genuinely cannot match. This screen gets the second-largest share of design attention, and it produces the system's happiest accident.

**The pen board is the same shape as the keypad.** Twelve pens in a 3 × 4 grid in the readout pane; twelve keys in a 3 × 4 grid below. Pen 4 is the first tile of the second row. Key `4` is the first key of the second row. They sit in the same column, one above the other, 340 pt apart. **You do not tap a pen. You look at where it is on the board and press the key in the same place.** After two nights this is not a lookup, it is a reach.

```
PEN BOARD · 12 PENS · 9 OCCUPIED · 2 OVER 24H
┌──────────┐ ┌──────────┐ ┌──────────┐
│1         │ │2         │ │3         │
│  128     │ │  EMPTY   │ │   91     │
│2L · 9H   │ │          │ │1L · 18H  │
└──────────┘ └╌╌╌╌╌╌╌╌╌╌┘ └──────────┘
┌══════════┐ ┌══════════┐ ┌──────────┐
│4      !! │ │5      !! │ │6         │
│  412     │ │  305     │ │  EMPTY   │
│2L ·[31H] │ │3L ·[26H] │ │          │
└══════════┘ └══════════┘ └╌╌╌╌╌╌╌╌╌╌┘
┌──────────┐ ┌╌╌╌╌╌╌╌╌╌╌┐ ┌──────────┐
│7         │ │8         │ │9         │
│  219     │ │  EMPTY   │ │  340     │
│0L · 3H   │ │          │ │0L · 1H   │
└──────────┘ └╌╌╌╌╌╌╌╌╌╌┘ └──────────┘
┌──────────┐ ┌╌╌╌╌╌╌╌╌╌╌┐ ┌╌╌╌╌╌╌╌╌╌╌┐
│10        │ │11        │ │12        │
│   77     │ │  EMPTY   │ │  EMPTY   │
│1L · 6H   │ │          │ │          │
└──────────┘ └╌╌╌╌╌╌╌╌╌╌┘ └╌╌╌╌╌╌╌╌╌╌┘
```
`MODE: PEN — TYPE A PEN NUMBER 1-12`

**Legibility from arm's length under a head torch** is the design requirement (product spec §7.4), and the tile is built for it: the occupant tag is **34 px** — nearly twice the body floor — and it is the only bright thing on the tile. Pen number, lamb count and hours are 18 px `--reg-ink-2`. From two metres you read `128 · 91 · 412 · 305 · 219 · 340 · 77` as a shape, exactly as you read a whiteboard, and the empty pens read as recessed holes in the grid rather than as tiles you have to check.

**Pen 4 is over the 24-hour turn-out threshold, and it is flagged three times over, none of them by colour** (§2.8): a **4 px double rule** welded across the tile's top edge, the printed token `!! OVER`, and the hours in an **inverted cell** — `31H` as ground ink on solid ink-1 at 10.91:1. Pen 5 at 26 h is flagged identically. In red-shift, in monochrome, through a scratched screen protector with wet fingers, the two over-threshold pens are the two tiles with lines across the top and a black-on-amber number. **A colour-blind operator, an amber-only display and a dying backlight all give the same reading.**

**Acting on a pen takes two presses.** Press `4` — the tile inverts wholesale (10.91:1, unmissable) and the primary slab splits:

```
[ TURN OUT PEN 4 ]  [ MOVE 412 TO … ]
```

Press `TURN OUT PEN 4` and it is written: 412 and both lambs leave the pen, the tile becomes recessed and `EMPTY`, the pen's turn-out reminder cancels itself, and the echo prints `TURNED OUT PEN 4 · 412 + 2L · 31H`. Two presses, no dialog, no confirm, no undo — because `DEL` immediately after prints `UNWROTE TURN OUT PEN 4`.

**Pens 10, 11, 12 need two digits and the face handles it without a timer.** Press `1` and pen 1 arms and the slab reads `TURN OUT PEN 1`. Press `0` and pen 10 arms and the slab reads `TURN OUT PEN 10`. The slab always names the pen it will act on, live, so there is no ambiguous window and no 400 ms settle to wait through. The commit is the slab, never the digit.

**The board is also a readout of time.** The hours reprint once a minute, hard cut, tabular, right-aligned so the column of `9H · 18H · 31H · 26H · 3H · 1H · 6H` is scannable as a column. That column *is* the pen board's argument against the whiteboard: a whiteboard can tell you who is in pen 4, but it cannot tell you she has been there thirty-one hours.

---

### Screen 8 · TREATMENTS

Press `TREAT` on the permanent rail with a ewe loaded. The mode chain runs: product name (a **text detour**, announced) → dose (keys) → route (a numbered readout, `1 SUBCUT 2 IM 3 ORAL 4 TOPICAL 5 FOOTBATH 6 OTHER`) → batch number (detour) → date (`TIME AUTO`, editable) → **days off**.

The DAYS OFF state is the most carefully designed thing in the product after screen 3, because a wrong number here puts meat into the food chain:

```
         77
77 · ALAMYCIN LA · 12 ML · SUBCUT · BATCH AL-7734
[      N O   D E F A U L T   V A L U E S      ]   ← inert plate, recessed
▨▨│ !! WITHDRAWAL — DAYS NOT ENTERED · ___
```
`MODE: DAYS OFF — READ IT FROM THE BOTTLE. YOUR ENTRY.`
`      (19px prose) The app ships no withdrawal periods and will not suggest one.`

The field shows `___`, never `0`. The inert plate occupies — permanently, visibly, unpressably — the exact rectangle where every competing product puts a helpful suggestion. The ewe carries the red band in every readout until a number is typed. Only once a digit exists does the primary slab wake up, and its legend is an assertion by the operator, not by the app: **`WRITE 28 DAYS — I HAVE READ THE BOTTLE`**.

Active withdrawals print as bands in the readout pane:

```
ACTIVE WITHDRAWALS · 2
▨▨│ 77   ALAMYCIN LA   CLEAR 12 AUG 2026   9 DAYS
▨▨│ 219  FOOTBATH      CLEAR 4 AUG 2026    1 DAY
```

**Repeat last treatment** is the primary slab in `TREAT` mode when the last treatment is under an hour old: `[ REPEAT: ALAMYCIN LA 12 ML SUBCUT 28 DAYS ]` — the whole prescription is in the legend, including the days, so a batch treatment is one press per ewe and the operator can see exactly what they are repeating. The **medicine book** is `MORE → 5 MEDICINE BOOK`: a chronological numbered readout, four rows plus `+ N MORE`, and `MORE → 8 EXPORT` from there.

---

### Screen 9 · REMINDERS

A numbered readout in three welded groups. The number *is* the control.

```
REMINDERS · 1 OVERDUE · 3 DUE · 2 UPCOMING
OVERDUE
1  !! NAVEL DIP        412/3        40 MIN AGO
DUE
2  COLOSTRUM WINDOW    412/3        IN 20 MIN
3  TURN OUT PEN 4      412          NOW · 31H
UPCOMING
4  WITHDRAWAL ENDS     77           12 AUG
5  TAG BY              128'S LAMBS  6 AUG
```
`MODE: REMINDERS — PRESS 1-5`

Press `2` and the row inverts (10.91:1) and the primary slab splits three ways: `[ DONE ]  [ MUTE THIS ONE ]  [ SNOOZE 30 ]`. Each reminder is **individually mutable** exactly as the product spec requires, and muting one never mutes its class. `MUTE THIS ONE` writes immediately and the row reprints as `2  MUTED  COLOSTRUM WINDOW  412/3` — muted, still visible, never deleted, because a reminder you silenced is information about your night.

Nothing nags twice: a reminder fires once, appears here, and waits. There is no badge count on an app icon, no red dot, no second notification. (Spec §5: zero interruptions.)

---

### Screen 10 · SEASON SUMMARY — 2026

The register head is the wrong shape for a dashboard, so it does not become one. The tag position — the biggest numeral on the phone — takes the **headline figure**, and everything else is machine text and one chart.

```
        187%                                   ← 120px, bloom
187% = LAMBS BORN 187 / EWES TO RAM 100 · PRESS 1 TO CHANGE THE DEFINITION
2025  172%   ·   +15 POINTS
AVG LITTER 1.9  ·  BARREN 4%  ·  ASSISTED 12%
LOSSES 7   STARVATION 2 · HYPOTHERMIA 1 · STILLBORN 3 · CRUSHED 1
[ spread chart, 14 bars, 2026 solid, 2025 outlined ]
```
`MODE: SPREAD — TYPE A DAY 1-14`

**The lambing percentage carries its own definition on the line beneath it**, in words, with the arithmetic shown — because "187%" means four different things to four different shepherds and the product spec makes it configurable for exactly that reason. Press `1` and the mode becomes `DEFINITION — PRESS 1-4` over the four numbered definitions (born/reared × per ewe to ram/per ewe lambed). The headline reprints instantly. **The number never changes without the definition changing visibly at the same time.**

The chart (§7.14) has no value labels, because fourteen of them cannot fit at 18 px and shrinking them is forbidden. Instead the keypad reads the chart: press `4` and the fourth bar inverts and the head prints `DAY 4 · 14 BORN`. The 2025 comparison is an outline overlay — filled versus outlined, not two hues — so the shape of a tight tup versus a loose one is legible in red-shift and in monochrome.

---

### Screen 11 · EXPORT

Because there is no cloud, this is a safety feature, and the face is blunt about it.

```
EXPORT · LAST EXPORT 3 DAYS AGO · 24 JUL 2026
1  CSV — ONE ROW PER LAMB          412 ROWS
2  CSV — ONE ROW PER EWE           104 ROWS
3  CSV — ONE ROW PER TREATMENT      38 ROWS
4  PDF — FLOCK BOOK 2026           18 PAGES
5  PDF — MEDICINE RECORD 2026       4 PAGES
6  JSON — FULL BACKUP              1.2 MB
```
`MODE: EXPORT — PRESS 1-6`
`SLAB: [ SEND VIA SHARE SHEET ]`

Under the numbered list, in 19 px humanist prose — the only sentence on the face, and it is set in the face that is read fastest from a glance:

> **This phone is the only copy. If you lose it, drop it in a water trough, or it stops working, everything in it is gone. Export tonight.**

And the footer, which is printed here and **baked verbatim into every CSV header, every PDF footer and the JSON metadata**:

> *Shed Book is a private notebook. It is not a holding register, not a statutory medicine book, and not a regulatory or compliance record. Withdrawal periods in this file were entered by the keeper from the product label and have not been verified by this application.*

(Spec §12.1 and §12.3. The second sentence exists so that a printed page that leaves this app cannot be mistaken for something it is not, even by someone who never saw the app.)

Export goes out through the system share sheet — the one place the OS takes over the display, and the instrument face is restored the instant it dismisses.

---

### Screen 12 · SETTINGS

Eight settings, eight digits. Law 2 is satisfied by construction and there is no scrolling, no grouping, no search, no "advanced".

```
SETTINGS
1  UNITS               ▮KG   ▯LB
2  TEMPERATURE         ▮C    ▯F
3  TERMINOLOGY         EWE · GIMMER · SHEARLING · THEAVE · HOGGET
4  REMINDER INTERVALS  COLOSTRUM 2H · NAVEL 1H · TURN OUT 24H · TAG 7D
5  SEASON              2026 · STARTED 1 JAN 2026 · SWITCH
6  THEME               ▮AMBER   ▯RED-SHIFT
7  DELETE A SEASON
8  DELETE EVERYTHING
```
`MODE: SETTINGS — PRESS 1-8`

Binary settings (`1`, `2`, `6`) toggle on the press and write immediately — no sub-page. `6 THEME` rotates the whole ramp with a hard cut, no transition, because a fade from amber to red-shift is 300 ms of a colour that is neither. `3 TERMINOLOGY` and `4 REMINDER INTERVALS` open numbered sub-readouts in the same pane; terminology labels are text detours because they are words the operator's county uses and nobody else's.

**`8 DELETE EVERYTHING` is the single exception to Law 4.** It is the only pending action in the product. Pressing `8` puts the mode line into `DELETE EVERYTHING — TYPE THE WORD DELETE`, summons the text detour, and the primary slab stays disabled with the honest legend `WAITING FOR THE WORD DELETE`. Only when the word is typed does it wake to `[ !! DELETE EVERYTHING — 104 EWES, 197 LAMBS, 3 SEASONS. CANNOT BE UNDONE ]` with a 3 px alarm border. The legend counts what will die, because a number is the only warning this operator will actually read.

---

## 9. The 3am compliance table

Each rule from product spec §5, and the specific mechanism in this system that satisfies it.

| Rule (spec §5) | Mechanism in The Register |
|---|---|
| **One thumb, one hand.** The other hand is holding a wet lamb. | Five welded zones with the keys and slabs owning the **lower 65 %** of the display, centred on a right- or left-thumb arc pivoting at ~(330, 800). The register head — the hardest region to reach — is never a tap target while a subject is loaded, so nothing important is ever above the arc. The single most-used control in the product, `LAMBED` at 368 × 84, sits dead centre of the comfortable sweep. |
| **Gloves, wet hands, phone in a freezer bag. Min 60 × 60 pt.** | Smallest interactive target in the entire product is the event slab at **64 × 60**. Keys are **116 × 76**. The primary slab is **368 × 84**. Candidate rack slabs are **116 × 64**. Nothing smaller exists. |
| **Banned: swipe-to-delete, drag, long-press-only, pinch, force touch.** | The system has **no gesture recognisers at all** beyond a single tap. Delete is the `DEL` key. Reordering does not exist. Zoom does not exist (text scale is the OS setting). Foster is two taps, not a drag. Turn-out is two presses, not a swipe. There is not one interaction in this product that a mitten cannot perform. |
| **Every action is a plain visible button.** | Eighteen fixed positions, all of them visible, all of them legended in words or numerals at ≥ 18 px. There is no hidden affordance, no edge gesture, no shake-to-undo, no hamburger, no overflow menu with unknown contents — `MORE` prints a numbered list. |
| **Cold fingers = poor capacitance. Big targets, generous spacing, no thin sliders, no small drag handles.** | **The 10 pt dead gutter** (§4.2): a guaranteed non-responsive band between every pair of adjacent targets, with **no hit-slop extension into it**, so a 14–20 mm gloved contact patch cannot straddle two keys. A press in the gutter does nothing and gives no haptic — silence being the signal. There are **no sliders** in the product (the number stepper is explicitly deleted, §7.11) and **no drag handles** of any kind. |
| **Head torch or total darkness. Dark theme default and primary.** | There is **no light theme**, on either platform, in any resource folder. Ground is `#0A0806` — dead phosphor glass, not pure black, so the bevels read as objects at 10 nits. |
| **No white flash.** | `#0A0806` is the **first painted frame**: iOS LaunchScreen storyboard and Android `windowSplashScreenBackground` are both the ground colour, with no animated icon and no `setKeepOnScreenCondition`. The app boots *into* the instrument, with the keys already drawn. |
| **High-contrast type.** | Every text pair in the product is **≥ 4.5:1**, computed and tabulated in §2.5 and §2.7. Primary ink is **10.91:1** on ground (AAA). The dimmest word in the system is 6.42:1. There is no third text colour and no disabled grey — inertness is expressed by geometry, never by dimming below legibility. |
| **Minimum 18 pt body text.** | The type floor is **18 px and nothing in the product is smaller** — no captions, no footnotes, no legends, no chart labels. Body prose is 19, machine text 20, mode line 26, key digits 56, the register tag 120. |
| **Optional red-shift (night-vision) mode.** | The design is **monochrome by construction**, so red-shift is the same instrument with the ramp rotated (§2.7) — not a second design to learn. Every role, every component and every contrast obligation is re-verified in red mode, including a re-floored secondary ink at 5.28:1 and a bevel at 3.58:1. Commit becomes an **inversion plus `#FF9E6B`** rather than green, because green destroys dark adaptation and would defeat the mode. |
| **Under 15 seconds from unlock to a saved lambing event.** | **Four presses, about six seconds**, because the ewe is already loaded on unlock and the first press *is* the commit: unlock → `LAMBED` (written, 2 s) → `2` → `3`. Nine seconds of headroom to `LOAD` and type a tag if she is not the one on the register. A unique tag prefix auto-resolves on the last digit with a heavy haptic, saving a confirm press. |
| **Zero interruptions.** | No ads, no accounts, no network stack to prompt about. No onboarding — the instrument face *is* the onboarding, and it is identical on night one and night eleven. No "what's new", no rating prompt, no upgrade nag, no badge count, no second notification for a reminder that already fired. The daily export prompt is a single line inside the export readout the operator summoned, never a modal. |
| **Assume the phone dies. Every write commits immediately; no draft state; no "Save" that can be lost.** | **Law 4.** Every press is its own SQLite commit, confirmed by an 800 ms flash, a double haptic and a printed `WROTE` line in the echo. Consequently the UI contains **no Save button, no Cancel, no Done, no form, no wizard, no progress indicator and no discard dialog** — there is no transaction to have one about. Correction is a *new write* via `DEL`, printed as `UNWROTE`, never a silent rollback. The mode chain never blocks and `LOAD` is live at every step, so abandoning halfway through a lambing leaves exactly the fields you pressed, on disk, correct as far as they go. |

### 9.1 Safety rules (spec §12) — where each one lives

| Rule | Mechanism |
|---|---|
| Withdrawal period never pre-filled or suggested | Field renders `___`, never `0` (§2.8). Permanent inert `[ NO DEFAULT VALUES ]` plate (§7.16). Mode line `DAYS OFF — READ IT FROM THE BOTTLE. YOUR ENTRY.` Commit legend `WRITE 28 DAYS — I HAVE READ THE BOTTLE`. Red band on the animal until entered. |
| No veterinary advice | No suggested doses. No diagnosis. The mode-line vocabulary is a **closed set** (§7.17) and contains no imperative sentence about husbandry. The ease scale ships descriptions of what a score *means*, never what to *do*. |
| Notebook, not a compliance record | Footer text printed on screen 11 **and baked verbatim into every CSV, PDF and JSON export** (§8, screen 11). |
| Contradictions flagged, never silently fixed | 4 px double frame, triple heavy haptic, printed `!! DECLARED TWIN · 3 LAMBS ON RECORD`, primary slab splits into exactly two, **no third slab, no default focus, no recommendation**. Unresolved flags print as `!! MISMATCH` on the record forever. |
| Honest timestamps | `TIME AUTO` and `TIME EDITED` are badges in the closed vocabulary (§7.10) and print on every readout. An edited time always shows the original: `TIME EDITED 03:20 (WAS 03:47)`. |

---

## 10. The `:root` token block

Complete and ready to paste.

```css
/* ============================================================
   THE REGISTER — Shed Book design tokens
   Direction 1 of 3. Amber-phosphor instrument, dark-only.
   1pt = 1 CSS px = 1 dp. Reference device 393 x 852.
   ============================================================ */

:root {

  /* ---- SURFACES ------------------------------------------- */
  --reg-ground:        #0A0806;  /* the face; first painted frame     */
  --reg-panel:         #14100A;  /* readout pane, chart plot area     */
  --reg-keyface:       #1C160E;  /* raised key + slab faces, at rest  */
  --reg-keypress:      #2A2114;  /* key + slab face, held             */
  --reg-well:          #050302;  /* recessed operator keys, inert     */

  /* ---- INK ------------------------------------------------- */
  --reg-ink-1:         #FFB000;  /* 10.91:1 on ground  AAA            */
  --reg-ink-2:         #C98A00;  /*  6.78:1 on ground  AA             */
  --reg-ink-inverse:   #0A0806;  /* 10.91:1 on ink-1   AAA            */

  /* ---- SIGNAL ---------------------------------------------- */
  --reg-commit:        #3FBF6F;  /*  8.47:1 on ground  AAA · 800ms    */
  --reg-alarm:         #FF3B1F;  /*  5.62:1 on ground  AA             */
                                 /* alarm is used TWICE in the whole  */
                                 /* product: the DIED slab, and a     */
                                 /* live withdrawal band. Nowhere else*/

  /* ---- STRUCTURE (non-text; 3:1 obligation) ---------------- */
  --reg-bevel:         #8A5E00;  /*  3.51:1 vs ground · 3.15 vs face  */
                                 /*  the load-bearing key boundary    */
  --reg-etch:          #6B4A00;  /*  2.48:1 — depth only, never a     */
                                 /*  boundary, never carries a word   */
  --reg-shadow:        #000000;

  /* ---- BLOOM (register numerals only) ---------------------- */
  --reg-bloom-alpha:   0.22;
  --reg-bloom:         0 0 2px rgba(255,176,0,0.22),
                       0 0 8px rgba(255,176,0,0.14);

  /* ---- HATCH (non-colour channel of every alarm) ----------- */
  --reg-hatch-w:       20px;
  --reg-hatch-angle:   45deg;

  /* ---- TYPE FAMILIES --------------------------------------- */
  --reg-font-machine: "JetBrains Mono","Berkeley Mono",ui-monospace,
                      "SF Mono","IBM Plex Mono","Roboto Mono",
                      Menlo,Consolas,monospace;
  --reg-font-prose:   "Source Sans 3",-apple-system,BlinkMacSystemFont,
                      "SF Pro Text","Segoe UI",Roboto,
                      "Helvetica Neue",sans-serif;
  --reg-numeric:      tabular-nums slashed-zero;

  /* ---- TYPE SCALE (px) — floor is 18, nothing is smaller --- */
  --reg-t-tag:          120px;  --reg-lh-tag:         108px;
  --reg-t-tag-suffix:    56px;  --reg-lh-tag-suffix:   60px;
  --reg-t-key:           56px;  --reg-lh-key:          56px;
  --reg-t-figure:        34px;  --reg-lh-figure:       38px;
  --reg-t-slab:          28px;  --reg-lh-slab:         32px;
  --reg-t-mode:          26px;  --reg-lh-mode:         30px;
  --reg-t-machine:       20px;  --reg-lh-machine:      24px;
  --reg-t-prose:         19px;  --reg-lh-prose:        26px;
  --reg-t-legend:        18px;  --reg-lh-legend:       22px;

  /* ---- WEIGHTS + TRACKING ---------------------------------- */
  --reg-w-display:      700;
  --reg-w-machine:      500;
  --reg-w-prose:        400;
  --reg-tr-tag:      -0.02em;
  --reg-tr-mode:      0.12em;
  --reg-tr-slab:      0.10em;
  --reg-tr-legend:    0.10em;
  --reg-tr-machine:   0.04em;

  /* ---- SPACE (2pt base; nine values, no others) ------------ */
  --sp-1:  2px;
  --sp-2:  4px;
  --sp-3:  6px;
  --sp-4:  8px;   /* zone gutter                                */
  --sp-5: 10px;   /* THE DEAD GUTTER — no hit-slop crosses it   */
  --sp-6: 12px;   /* face margin, event-rail gutter             */
  --sp-7: 16px;
  --sp-8: 24px;
  --sp-9: 32px;

  /* ---- RADII (4px is the ceiling, everywhere) -------------- */
  --r-0: 0px;
  --r-1: 2px;
  --r-2: 4px;

  /* ---- STROKES --------------------------------------------- */
  --stroke-hair:   1px;   /* top-light bevel                    */
  --stroke-rule:   2px;   /* shadow rule, row separators        */
  --stroke-heavy:  3px;   /* dead-lamb overstrike, DIED border  */
  --stroke-double: 4px;   /* 2 + 2 gap + 2: OVER, contradiction */

  /* ---- THE FACE: five welded zones, 393 x 852 -------------- */
  --face-w:            393px;
  --face-margin:        12px;
  --face-content-w:    368px;   /* 3 x 116 + 2 x 10             */
  --face-content-h:    759px;   /* 852 - 59 top - 34 bottom     */

  --zone-head-h:       199px;
  --zone-mode-h:        48px;
  --zone-keys-h:       334px;   /* 4 x 76 + 3 x 10              */
  --zone-slab-h:        84px;
  --zone-rail-h:        60px;

  /* ---- MODULES --------------------------------------------- */
  --key-w:             116px;   --key-h:        76px;
  --key-gutter:         10px;
  --slab-w:            368px;   --slab-h:       84px;
  --slab-split-2:      179px;   --slab-split-3: 116px;
  --event-w:            64px;   --event-h:      60px;
  --event-gutter:       12px;
  --rack-w:            116px;   --rack-h:       64px;
  --pen-tile-w:        116px;   --pen-tile-h:   56px;
  --row-h:              48px;   /* ewe row, check row           */
  --band-h:             44px;   /* withdrawal band, inert plate */
  --chart-h:           140px;
  --chart-bar-w:        18px;   --chart-bar-gutter: 8px;
  --field-h:            96px;
  --tap-min:            60px;   /* enforced floor; nothing under */

  /* ---- MOTION (the complete inventory) --------------------- */
  --mo-instant:          0ms;   /* every key press, in and out   */
  --mo-slab-release:   120ms;
  --mo-commit-hold:    800ms;
  --mo-ease:           linear; /* the only curve in the product */
}

/* ============================================================
   RED-SHIFT — the same instrument, ramp rotated, peak halved.
   Not a second design: every role, component and contrast
   obligation is identical. Green is removed because it
   destroys dark adaptation; commit becomes inversion + #FF9E6B.
   ============================================================ */

:root[data-theme="red-shift"] {
  --reg-ground:        #0A0402;
  --reg-panel:         #150705;
  --reg-keyface:       #1A0905;
  --reg-keypress:      #2C1109;
  --reg-well:          #050201;

  --reg-ink-1:         #FF6B3D;  /*  7.20:1 on ground  AAA       */
  --reg-ink-2:         #E0532A;  /*  5.28:1 on ground  AA        */
  --reg-ink-inverse:   #0A0402;  /*  7.20:1 on ink-1   AAA       */

  --reg-commit:        #FF9E6B;  /* 10.04:1 on ground  AAA       */
  --reg-alarm:         #FF3B1F;  /*  5.72:1 on ground  AA        */

  --reg-bevel:         #B44018;  /*  3.58 vs ground · 3.40 vs face */
  --reg-etch:          #7A1400;  /*  1.87 — depth only            */

  --reg-bloom-alpha:   0.12;
  --reg-bloom:         0 0 2px rgba(255,107,61,0.12),
                       0 0 8px rgba(255,107,61,0.08);
}

/* ---- Reduce motion: near no-op, because there is near nothing */
@media (prefers-reduced-motion: reduce) {
  :root {
    --mo-slab-release: 0ms;
    --mo-commit-hold:  1200ms;  /* longer, since nothing moves   */
  }
}

/* ---- There is no light theme. This is deliberate and final.   */
@media (prefers-color-scheme: light) { /* intentionally empty */ }

/* ---- Global floor: tabular, slashed, dark, no overscroll ---- */
html {
  background: var(--reg-ground);
  color: var(--reg-ink-1);
  font-variant-numeric: var(--reg-numeric);
  font-feature-settings: "tnum" 1, "zero" 1, "ss01" 1;
  -webkit-text-size-adjust: 100%;
  overscroll-behavior: none;      /* nothing to pull, nothing to refresh */
}
```

---

## 11. Governance

Three questions settle any future proposal, in order.

1. **Does it move a key?** Then no. (Law 5.)
2. **Does it make a digit mean something that is not a number, or attach a number to something not printed as a number?** Then no. (Laws 1 and 2.)
3. **Does it introduce something that can be pending, other than destruction?** Then no. (Law 4.)

If a proposal survives all three, it must still fit in eighteen fixed positions and the 759 pt budget without touching the key block — which means it costs echo lines, and echo lines are recall, and recall is what makes the app irreplaceable in season two. **Anything added to this instrument is paid for out of memory.** That price is the point.

---
name: indelible-design-system
description: >-
  The front door to Indelible — the four rules, serif means it happened and sans means it is
  pressed. Use before any pixel, colour, hex, contrast ratio, token, font, size, weight, spacing,
  gesture, motion or haptic is chosen, and when fixing a contrast failure. Do NOT use for the gate
  that asserts a value (shed-testing) or the data on a screen (shed-screens-and-routing).
---

# Indelible — the design system of record

**Indelible is the only direction.** `docs/design/the-register.md` and `docs/design/strip-bay.md` were
not selected; no element of either may enter the product, a skill or a review comment. The one graft is
already Indelible's and is never attributed: the **persistent loaded subject** — the animal being written
about is the largest object on the phone and survives a cold launch. `docs/design/indelible.md` and
`docs/engineering/06-design-system.md` are BINDING and outrank this skill: carry the rule from here, cite
the section (`per indelible.md §3.4`), and read the file for the reasoning and the full tables.

## The four rules (§1.2) — they settle any disagreement, in this order

1. **Nothing is ever removed, only struck.** If a proposal makes information disappear from the page it
   is wrong. Undo is a strike, mute is a strike, un-ticking is a strike over the tick. Correcting a time
   prints both times.
2. **The record is set in the book face; the controls are set in the machine face.** Serif means *it
   happened*, sans means *it is a thing you can press*. **Declare a component's voice before you give it
   a size.** If it wants to be both, it is two components. One documented exception, §3.5.
3. **Meaning is carried by form first, hue never alone.** One hue, three jobs; every state carries at
   least two non-colour channels (§2.7). If a proposal needs a fourth colour, the answer is a word.
4. **The floor is measurement, not taste.** Every text pair reaches **4.5:1** on its actual surface;
   every rule and mark reaches **3:1**. "It looks better dimmer" has already lost twice (§2.4).

## The palette — eleven tokens, closed (§2.2–§2.5)

Five surfaces and there will never be a sixth. Not an elevation system — nothing casts a shadow; a
button is a filled shape only because everything else is a rule.

**Precedence:** `indelible.md §2.2`–`§2.5` is the source of these values and `lib/core/ui/primitives.dart`
becomes authoritative the moment it exists. The table below is a working copy for deciding *before*
the file exists — if it ever disagrees with either, the table is the thing that is wrong.

| Token | Hex | Job | Worst measured |
|---|---|---|---|
| `--page` | `#0A0A0B` | the page; the **first painted frame** | — |
| `--row-pressed` | `#131315` | a row under the thumb | — |
| `--sheet` | `#141416` | the bottom sheet | — |
| `--slab` | `#1C1C1F` | a button fill | — |
| `--slab-pressed` | `#2A2A2E` | a button under the thumb | — |
| `--ink-full` | `#EDE8DC` | tags, record body, control labels, stamps | 11.69 |
| `--ink-mid` | `#A8A296` | summaries, units, margin times | 5.63 |
| `--ink-low` | `#8F8A7E` | struck text, gap labels | 4.94 on slab |
| `--rule` | `#6B675F` | **non-text only** — 2px rules, borders | 3.02 (NT) |
| `--madder-rule` | `#B94A40` | **non-text only** — spine, selected underline | 3.33 (NT) |
| `--madder-ink` | `#D4685C` | the strike, `STRUCK`, `?`, `†` | 4.80 |

**Two binding placement rules, straight out of the measurement:** (1) `--ink-low` and `--rule` are
**never** drawn on `--slab-pressed` (4.16 and 2.54) — a pressed slab carries `--ink-full` only and its
border goes to `--ink-mid`; (2) `--madder-rule` is **never set as text and never carries a glyph**, it
is a 2px line and nothing else.

**Do not "restore" the prettier value (§2.4).** `#6B675F` as struck ink measures 3.52:1 and `#A63A32`
as the madder 3.08:1. Both look better; both were overruled by rule 4. Red anywhere means the record has
something to say about itself. **Red-shift (§2.6) overrides token values and nothing else** — §9 calls it
a six-value override, and it is nearly a no-op by construction because nothing was ever encoded by hue.
Every red-shift text pair is still ≥4.5:1. One inversion: `--madder-ink` becomes the **brightest** mark
on the page, since no hue channel is left to identify it with, and the strike **doubles** so form takes
over from colour.

**Before proposing any colour, run** `python3 scripts/contrast.py <fg-hex> <bg-hex>` (add `--non-text`
for a rule or mark) — **execute it, do not read it.** It prints the WCAG ratio and pass/fail against 4.5
and 3.0. Proposals only: shipped tokens are proved by `dart test test/design/contrast_test.dart`, and a
second implementation of the formula that could disagree with the Dart one is a liability. §2.1 prints
the method; in Dart, `Color.computeLuminance()` **is** the WCAG relative-luminance formula, so
`test/design/wcag.dart` adds only the ratio — never re-derive `pow(c, 2.4)` by hand.

**How it lands in code.** `06 §1` fixes token *names* and the two-tier structure; a direction owns
*values*. Indelible's hexes are authored into `lib/core/ui/primitives.dart`, composed in `palettes.dart`
and read **only** through `context.tokens` (`CONVENTIONS §2.11`). If Indelible needs something
`ShedTokens` lacks, add the field — never a literal in a widget. `Color(0x`, `Colors.`,
`Color.fromARGB/RGBO`, `ColorScheme.fromSeed` and any read of `colorScheme` are `check_policy` rows under
`lib/` (**R55**); `[exempt]` has exactly four lines (**R56**) and a fifth is a review conversation, not
an edit. `ShedPaletteId`, its stored keys `night`/`amber`/`red` and the four Settings labels are frozen
(**R35**) — supply values, never a new palette id. There is no light theme and no code path may produce
one (`06 §2.1`).

## Typography

**Two faces, bundled, never fetched (§3.2).** Record: **Source Serif 4**. Control: **Source Sans 3**.
Both OFL 1.1 variable, both with true tabular lining figures, whole payload under 700 kB, licence
registered via `LicenseRegistry.addLicense`. `google_fonts` is banned and grepped — it fetches at
runtime, a network path in an app that ships without `INTERNET`. The fallback stacks are a documented
failure mode, not part of the design. The test for a replacement face is the **1/7 and 6/8 test**: read
at 32px, 30% brightness, through a sandwich bag.

> **P7's first half is OPEN — the typeface itself. Do not resolve it here, and do not ship a
> `pubspec.yaml` `fonts:` block until it is ruled.** Indelible §3.2 needs **two** related-but-distinct
> families, because Rule 2 (serif = record, sans = control) *is* the design and collapses without
> them. The engineering set bundles **one**: decision **#98** names Atkinson Hyperlegible Next,
> `CONVENTIONS §1` (BINDING on paths) puts `assets/fonts/AtkinsonHyperlegibleNext[wght].ttf + OFL.txt`
> in the tree, `06 §5.2` declares the family `AtkinsonNext`, `09 §4.2` embeds that same file in every
> PDF, and `12 §8.3` loads it in `test/flutter_test_config.dart`. Both sides are cited; neither is a
> name this skill may change. Closing it needs an owner ruling plus the checks already written down —
> `REFERENCES §22` **C1** (Atkinson's real file size, `wght` range and figure features; it was never
> downloaded) and **B8** (whether `pdf` accepts a variable font at all). Until then: **carry the
> conflict into the PR**, and note that "two faces" moves four artefacts together — the `assets/fonts/`
> tree line, the `fonts:` block, the embedded PDF TTF and the golden font loader — plus roughly 700 kB
> against `13 §6`'s under-5 MB asset budget.

The scale is twelve tokens, split by voice — which is how Rule 2 becomes checkable (§3.4):

- **Record face, all tabular:** `--t-figure` 56 (season figures) · `--t-tag-xl` 44 (pen number, live-row
  tag) · `--t-tag` 32 (tag in a row, keypad digit, ease digit, hours) · `--t-record` 20, tracking
  0.006em — **the record body** · `--t-record-sm` 18 — **record floor** · `--t-margin` 18 (margin times).
- **Control face:** `--t-slab` 26 caps/0.06em (`+ LAMB`) · `--t-ctl-lg` 22 (primary word buttons) ·
  `--t-ctl` 20 (button labels, index words) · `--t-ctl-sm` 19 — **control floor** · `--t-head`
  **18** caps/0.10em (page header — corrected below) · `--t-stamp` 14 caps/0.14em, **exempt stamps only**.

**The 18px floor correction — the mockup is the defect, not the spec.** `mockups/indelible.html` uses
`--t-stamp: 14px` 49 times and `--t-head: 16px` 13 times. §3.4 permits 14px only when all three of its
conditions hold, and the third is *no stamp is ever the sole carrier of its meaning*. That fails on
**`DEAD`**, on **`AUTO-CAPTURED`** (the sole §12.5 provenance label), on **`DERIVED FROM 3 STROKES`**
(the sole statement of the §12.4 claim), and on the page header, the only statement of which night you
are on. **Those strings are not stamps and take a ≥18px role**; every other stamp keeps the exemption,
and a fourth string that turns out to be the sole carrier of its meaning is not a stamp either. `06 §5.1`
collapses `bodySmall`/`labelSmall` into the 18 floor, so the exempt stamp is the one role below it — a
**named role in `buildShedTextTheme`**, never a literal `fontSize: 14`, which is a
`token.literal_font_size` hit anywhere under `lib/`.

**Weights (§3.3): 390 / 420 / 520 / 600** — one step lighter than a light-mode equivalent, because light
type on a dark ground bleeds outward and gains apparent weight.

> **P7's second half is OPEN too. Do not pick it, and do not silently round 390 to 400.** Flutter's
> `FontWeight` is w100–w900 in hundreds, so 390 and 420 cannot be expressed as a `FontWeight` at all —
> they need `FontVariation('wght', 390)` on a live variable axis, and `06 §5.2` records the bundled
> axis requirement as **500–700**, which excludes both. Closing it takes three things, none a desk
> decision: read the real `wght` range off whichever files the typeface ruling above lands on
> (`fc-query`, `ttx -l`) into `docs/perf/measurements.md`; decide how Bold Text is honoured, since `Text.build`
> merges `FontWeight.bold` into `fontWeight` and **does not touch `fontVariations`**, so a
> variation-set weight ignores the user's accessibility setting; and an owner ruling. Until then, state
> the conflict in the PR rather than ship a number. `FontWeight.w800`/`w900` are banned outright
> (`type.weight_cap`) — they render *lighter* under Bold Text, flutter#139712.

**Nothing is italic, anywhere, ever** — italic serifs smear under halation and the thin joins vanish at
30% brightness. No small-caps; stamps are true all-caps with positive tracking. Emphasis is a face swap,
a 2px rule or a stamp. Never slope.

**Tabular lining figures everywhere (§3.5)** — every figure in the record *and* in a control, keypad
digits, ease digits and the stepper included, because a digit must never change width between the button
you press and the row it prints into. Oldstyle and proportional figures appear nowhere. **Tags
right-align in a fixed three-character column**, which is the whole reason the flock page scans: `12`,
`77` and `91` sit under the units of `412`. The failure is silent — a freshly constructed `TextStyle`
for a numeral drops `fontFeatures` and the board starts jittering (`06 §5.4`), so go through the role.

**The one documented exception to Rule 2:** the **keypad digits are set in the record face**. The
shepherd matches a key against a digit already printed in the row above — same shape, same width, no
translation step. Settings prints the exception beside the two-voices line, because an unexplained
exception is a bug.

**At 200% (§3.6): rows grow, the grid does not move.** The per-element behaviour — what caps, what
re-lays and the one documented component wrap — is **indelible-page-and-screens**', because it is a
layout fact; do not re-derive it here. What this skill binds is the type half: **never clamp.**
`textScaleFactor`, `TextScaler.clamp`, `withClampedTextScaling` and `FittedBox` are banned and grepped
(`06 §5.5`), and a rule is a physical mark rather than type, so it never scales with the text.

## The gesture ban — complete (§9, `06 §7`)

Every action is reachable by single discrete taps on ≥64 × 64 targets. Banned with no exception:
**swipe actions of any kind** (there is nothing to swipe-delete — erasure does not exist in the product),
**drag and drag-to-reorder**, **drag handles**, **any binding whose only route is a long press**,
**pinch**, **force touch** (the hardware does not exist), **hold-to-repeat** (the stepper is one press,
one step), **sliders** (`Slider`, `RangeSlider`, `CupertinoPicker`), `PageView`/`TabBarView`,
pull-to-refresh, shake-to-undo and `Tooltip`. The replacement is always two taps on a list. Every bottom
sheet types all three of `showDragHandle: false`, `enableDrag: false`, `isDismissible: false`, because
Flutter's defaults are permissive. **Vertical scrolling is the one permitted tracked gesture**, and **no
action is ever reachable only behind a scroll**. Enforcement is rows in `tool/check_policy.dart`
(`06 §3.5`): decisions #9/#10 mandate one source-scanning gate, one allowlist, one exit code, so a new
prohibition is one more row and never a second script.

## Motion (§5.1–§5.3) — ink appears, it does not travel

Four durations and no fifth: press **40ms** (fill only — no scale, no lift, no ripple, because a target
that shrinks under a cold thumb is a target you miss), ink **120ms** (opacity only, zero translation),
sheet **160ms** (translate-Y only), strike **180ms linear** left-to-right, the only animation in the app
with a direction. **Never animate:** numbers (no count-ups, no odometers), the chart, rows (they never
reorder, slide or crossfade — a filter change re-prints instantly), launch (**the first painted frame is
`--page` with tonight's page already on it**: no splash, no logo, no white flash, either platform),
scroll, and the spine. Under reduce-motion, ink/sheet/strike go to 0ms and **press stays at 40ms** — it
is a fill change under a thumb and the only visual feedback left to someone who cannot feel the screen.
In Flutter: `themeAnimationDuration: Duration.zero` (`06 §2.1`), reduce-motion via
`lib/core/ui/motion.dart`.

## Haptics — the primary feedback channel

Through a wet glove inside a freezer bag, haptics lead and the visual press state is the backup. Two
rules bind and are not in dispute: **the success haptic fires when the transaction returns, never on the
tap** — a false receipt is worse than no receipt — and `HapticFeedback.vibrate()` is banned (on Android
it is a long buzz). Haptics are *not* disabled by reduce-motion (they are not motion), are individually
disableable in Settings, and there is no sound anywhere in v1.

> **P10 is OPEN. Do not pick it.** `06 §10.1` and its definition of done say the vocabulary has exactly
> **four** entries (`selectionClick`, `successNotification`, `warningNotification`,
> `errorNotification`). `indelible.md §5.4` lists **five** events with distinct rhythms (one 10ms tick;
> two ticks 60ms apart on commit; two ticks 120ms apart on a strike). Separately,
> `HapticFeedback.successNotification()` is carried as **unverified** on this SDK by `00-README §10`;
> `REFERENCES.md §22.E` E1 is the five-minute check that closes it. Run that check before writing the
> call, and take an owner ruling on four-versus-five.

## What this system does not have (§1.3)

No cards, containers, corner radius in the record, shadows, elevation, glass, gradient, texture or fake
paper grain. No status colour palette. **No icon set** — every action is a word (`TREAT`, `MOVE PEN`,
`TURN OUT`, `STRIKE`). What remains is six marks: 2px stroke, butt caps, miter joins, 24 × 24 or 28 × 28
boxes, `currentColor`, and **no new mark may be added without deleting one** (§6.1, §6.3). No
empty-state illustration, no modal dialog, no toast, no snackbar. No tab bar, navigation rail or
navigation stack. No spinner, skeleton or launch screen. No onboarding. **No Save button anywhere** —
every write commits immediately. The ornament in this system *is* the ruling.

## Where to go next

| You are deciding | Skill |
|---|---|
| Where anything sits: grid, spine, spacing, row heights, target sizes, the twelve screens as one page | `indelible-page-and-screens` |
| Any pressable thing: slab, word button, `INDEX`, keypad, ease group, stepper, field, sheet | `indelible-controls` |
| Any mark or state: strike, tally, dagger, query mark, stamp, derived value, chart | `indelible-marks-and-strikes` |
| Empty, first frame, error, receipt, banner, prompt | `indelible-states-and-feedback` |
| What data a screen shows, routes, undo's per-verb window | `shed-screens-and-routing` |
| Asserting any of this in a test | `shed-testing` |
| Copy, semantics labels, one word per concept | `shed-accessibility-and-copy` |

This skill owns no component's states table, no position on the page, and no screen's data.

## Done when — the ten acceptance tests (§11)

- [ ] **Strike.** Every destructive-looking action draws a line and prints a time; the only legal hits on
      `DELETE`/`remove`/`splice`/`hidden` are Settings' two season-level actions.
- [ ] **Ruler.** Nothing required to record an event sits above 560px from the bottom.
- [ ] **64.** Every target ≥ 64 × 64 — not even the margin dagger is excepted.
- [ ] **Monochrome.** Fully desaturated, over-threshold, struck, dead, queried and selected all still read.
- [ ] **1/7.** Every tag at 32px, 30% brightness, through a bag. If `412` could be `417`, the face is wrong.
- [ ] **Two-voice.** Point at any element and say "record" or "control" without hesitating.
- [ ] **Save.** Zero hits on the string `Save` in the UI.
- [ ] **Placeholder.** No input renders placeholder text inside the field.
- [ ] **First frame.** Cold launch both platforms at 240fps; frame one is `--page`. No white, no logo, no fade.
- [ ] **Measurement.** `dart test test/design/contrast_test.dart` passes — every text pair ≥ 4.5:1 and
      every rule and mark ≥ 3:1, in both themes. Rule 4 does not negotiate with taste.
- [ ] `dart tool/check_policy.dart` prints `policy ok`; no second script exists; `[exempt]` still has
      four lines.
- [ ] Nothing renders below 18px except a stamp that passes all three §3.4 conditions.
- [ ] P7 (**both halves** — the typeface, and the `FontVariation` weight axis) and P10 are still
      stated as open, or a numbered owner ruling closed them in the same commit. No `fonts:` block,
      `assets/fonts/` path or golden font loader was changed on this skill's authority.

# N09-T01 — `primitives.dart` — raw hexes, importable nowhere else

| | |
|---|---|
| **Epic** | [N09 — The design system foundation](epic.md) · `00-README` §9 step 4 (1 of 3) |
| **Task** | 1 of 9 |
| **Depends on** | N08-T07 |
| **Commit** | one commit · `feat(ui): primitives.dart — the only raw hexes in the app` |

## 1. Why this task exists

The only file in the app permitted to contain a raw hex or a raw scale value, with its
two `[exempt]` allowlist lines. Everything else reads `context.tokens`. A raw `Color(0x…)` outside this
file is a build-breaking defect and N03-T05's rule already refuses it.

Dart has no directory-private visibility, so the language cannot hold this rule and the gate does:
`token.primitives_import` fails any import of `core/ui/primitives.dart` from outside `lib/core/ui/`
(`06 §3.1`). Read `06 §3.5`'s four-line `[exempt]` block as the whole access-control story for colour
— **one file declares hexes, one file composes them into palettes, everything else reads
`context.tokens`.** Two of those four lines are created here, and they are the irreversible part of
this commit.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §3.1 (the file layout, and why the gate is the mechanism) · §3.2 (tier 1 — the constant list, value-named and meaning-free) · §3.5 (the two widened rows, the `_bannedPattern` table, the four `[exempt]` lines) · §9.4 (`launch.colour_parity` parses `nSurface04` out of this file) | the path, the constant naming scheme, the two allowlist lines |
| `docs/design/indelible.md` | §2.2 (five surfaces) · §2.3 (three inks, one hue) · §2.4 (**what measurement overruled** — do not restore either value) · §2.6 (the red-shift override) · §4.1 (the twelve-step spacing scale) · §4.2 (strokes and radii) | every hex and every raw scale value this file holds |
| `docs/engineering/CONVENTIONS.md` | §1 (`lib/core/ui/primitives.dart` is in the tree) · §1.1 layer rule 7 · §4.7 (the `[exempt]` block, four lines) · R55, R56 | the path, what the file may import, the exact allowlist keys |
| `docs/research/00-tech-decisions.md` | §5 · #94, #97, #127 | Flutter 3.44.8 / Dart 3.12.2; the two-tier token structure; the asset budget |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-design-system` | it carries the eleven-token palette and forbids restoring the two values measurement overruled |
| `shed-conventions` | the file's location, layer rule 7, and the `'<path> :: <id>'` allowlist key format |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/primitives_are_private_test.dart`
- **Test** — `'primitives.dart is imported by no file outside lib/core/ui/ and has exactly two allowlist lines'`
- **Why it is red today** — no primitives file exists, so the first colour would be typed into a widget.

```bash
fvm flutter test test/policy/primitives_are_private_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. The test reads `lib/**/*.dart` as **text**,
collects every file whose source matches
`RegExp(r'''import\s+['"][^'"]*core/ui/primitives\.dart''')` — the same pattern the gate's
`token.primitives_import` row uses — and asserts that set is empty outside `lib/core/ui/`. It then
reads `tool/policy_allowlist.txt`, takes the `[exempt]` section, and asserts it contains exactly the
two keys this task adds: `lib/core/ui/primitives.dart :: token.raw_color` and
`lib/core/ui/palettes.dart :: token.primitives_import`. Skip `*.g.dart` and `*.drift.dart`, exactly as
the gate's own driver does.

**Green.** The minimum code that passes, and nothing beyond it — the raw values from `indelible.md` only, and the import test.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

This task reaches **UI and tests only**. There is no schema step (it stores nothing), no domain step
(it computes nothing), no data step, no wiring, no controller and no ARB entry (it has no user-facing
string). `00-README` §8 says to say so out loud when you skip a layer — that sentence goes in the
commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/primitives.dart` | **New.** The raw colour ramps and the raw scales. The only file under `lib/` that may hold `Color(0x…)` besides `night_error_panel.dart`, which is exempted for a different reason: `06 §2.4` — it renders with no `Theme`, no `MediaQuery` and no `Directionality` in scope, so it cannot read a token |
| 2 | `tool/policy_allowlist.txt` | The `[exempt]` section gains its **third and fourth** lines. It has exactly four after this task, and never a fifth (R56) |
| 3 | `tool/check_policy.dart` | **Only if N03-T05 did not already land them.** `token.raw_color` and `token.material_color` must apply under `lib/`, not `lib/features/` (R55), and `token.primitives_import` must exist as a `_bannedPattern` row. Check before you add: a duplicate rule is *"a rule that gets weakened twice"* (R54) |
| 4 | `test/policy/primitives_are_private_test.dart` | **New.** The anchor. Written before any of the above |

Nothing else. This task deliberately does **not** touch `tokens.dart`: the mapping from Indelible's
eleven tokens onto `ShedTokens`' fields is T02's decision, and this file is meaning-free so that it
cannot pre-empt it.

### 5.2 The signatures

`06 §3.2` fixes the shape: **top-level `const`s, value-named, meaning-free, one import.**

```dart
// lib/core/ui/primitives.dart
// Raw values only. Nothing outside lib/core/ui/ imports this file.
// Every hex carries its measured WCAG ratio on the surface it is designed for;
// test/design/contrast_test.dart recomputes all of them.
import 'dart:ui' show Color;
```

That import line, and no other. **Never `package:flutter/material.dart`** — it pulls `Colors.` into
scope in the one file that must not have it, and `token.material_color` is a gate row under `lib/`
with no exempt line for this path.

The night ramp's values are `indelible.md` §2.2 and §2.3, with the luminance each was measured at:

| Indelible token | Hex | Relative luminance | Ratio on `--page` | Job |
|---|---|---|---|---|
| `--page` | `#0A0A0B` | 0.00306 | — | the page; the first painted frame. **Not pure black** — white-on-black is the worst halation case, and ~47% of adults have some astigmatism (§2.2) |
| `--row-pressed` | `#131315` | 0.00658 | — | a row under the thumb |
| `--sheet` | `#141416` | 0.00707 | — | the bottom sheet |
| `--slab` | `#1C1C1F` | 0.01176 | — | a button fill — the only filled shapes in the app |
| `--slab-pressed` | `#2A2A2E` | 0.02345 | — | a button under the thumb |
| `--ink-full` | `#EDE8DC` | 0.80885 | **16.19** | tags, record body, control labels, stamps |
| `--ink-mid` | `#A8A296` | 0.36368 | **7.80** | summaries, units, unselected control labels, margin times |
| `--ink-low` | `#8F8A7E` | 0.25523 | **5.75** | struck text, gap labels, cleared countdowns |
| `--rule` | `#6B675F` | 0.13653 | **3.52** | **non-text only** — the 2 px ruling, dotted rules, button borders |
| `--madder-rule` | `#B94A40` | 0.15582 | **3.88** | **non-text only** — the vertical spine, the ease underline |
| `--madder-ink` | `#D4685C` | 0.24670 | **5.59** | the strike line, `STRUCK`, the query mark `?`, the dagger `†` |

The red-shift ramp is §2.6's eleven values, in the same order: `#080605` · `#0F0B09` · `#120D0A` ·
`#1A1310` · `#261C17` · `#E4A896` · `#B8846F` · `#A4756A` · `#8A6053` · `#C9564A` · `#F2C4AE`.

The amber ramp and the high-contrast additions have **no Indelible table** — Indelible ships two
themes and `06 §4` ships six palettes (this is conflict **P6**, and R35 freezes the ids and labels but
not the values). Take these from `06 §3.2` verbatim:

```dart
// ---- amber night-shift ramp (base #000000) --------------------------------
const aSurface00  = Color(0xFF000000);
const aSurface04  = Color(0xFF140D00);
const aSurface08  = Color(0xFF1F1400);
const aAmber95    = Color(0xFFFFE0A3); // 16.44:1
const aAmber85    = Color(0xFFFFC46B); // 13.36:1
const aAmber70    = Color(0xFFFFB000); // 11.46:1
const aAmber55    = Color(0xFFD68F00); //  7.79:1
const aAmber45    = Color(0xFFC98400); //  6.78:1
const aAmber30    = Color(0xFFA66E00); //  4.85:1 — outline / non-text only

// ---- high-contrast additions ----------------------------------------------
const hOutline    = Color(0xFF7A7A7A); //  4.89:1 on #000000
const hGreen      = Color(0xFFA8F0C6); // 15.94:1
const hAmber      = Color(0xFFFFE08A); // 16.28:1
const hSalmon     = Color(0xFFFFC7BD); // 14.16:1
```

**The naming scheme is `06 §3.2`'s and it is value-named, not meaning-named:** a palette letter, a
hue-or-role word, and the approximate luminance step — `nSurface04`, `nInk92`, `aAmber70`,
`nSalmon80`. Name Indelible's two reds the same way, by hue and step. `nPage`, `nInkStruck`,
`nMadderStrike` and `nSpine` are all wrong here: what a value *means* is `tokens.dart`'s job, and a
primitive that already knows it is the strike colour has skipped a tier.

The raw scales are the second half of the file:

```dart
// ---- spacing scale (logical pixels) ---------------------------------------
const s04 = 4.0, s08 = 8.0, s12 = 12.0, s16 = 16.0, s24 = 24.0, s32 = 32.0;

// ---- tap scale (logical pixels) -------------------------------------------
const tapMin     = 60.0; // spec §5 floor      ≈ 9.5 mm
const tapPrimary = 72.0; // keypad, tiles      ≈ 11.4 mm
const tapHero    = 88.0; // the five 3am acts  ≈ 14.0 mm
const gapMin     = 16.0;
const gapDestructive = 32.0;
```

`06 §3.2`'s spacing scale has **six** steps. `indelible.md` §4.1's has **twelve** — 4 · 8 · 12 · 16 ·
20 · 24 · 32 · 40 · 48 · 64 · 88 · 132, four-based, no half-steps. Add the six missing steps here
rather than typing `20.0` into a widget in N10; `06 §1` is explicit that *"if a direction needs a
token this system does not have, add the token to `ShedTokens` — do not add a literal to a widget"*,
and the same applies one tier down. Indelible's geometry constants belong here for the same reason:
`--rule-w` 2, `--rule-strike-w` 3, `--rule-double-gap` 3, `--radius-slab` 2, `--radius-record` 0,
`--radius-sheet` 0.

### 5.3 The details that are easy to get wrong

- **`tapMin` is 60 and Indelible's floor is 64, and both are correct.** `06 §6.1` sets 60 as the spec
  floor (Parhi/Karlson/Bederson's 9.5 mm, *for a bare warm dry thumb in a lab*); `indelible.md` §4.5's
  minimum-target audit puts the smallest thing in the whole app at 64 × 64. Four points of headroom is
  the entire margin. Author **both** constants — the gate asserts 60 because that is the contract, the
  components build to 64 because that is the design. Collapsing them to one number loses information
  nobody can recover later.
- **P14 is open and this file is where it lands.** `nSurface04` is `#0B0D0E` in `06 §3.2`,
  `CONVENTIONS §2.11` and `13 §5.4`; `--page` is `#0A0A0B` in `indelible.md` §2.2 and §10. One hex,
  and it is the **first painted frame** — the no-white-flash claim is measured at 240 fps, and
  `launch.colour_parity` (`06 §9.4`) parses this exact constant out of this exact file and compares it
  to `android/app/src/main/res/values/colors.xml`. **N11-T04 rules P14 and amends `CONVENTIONS §2.11`
  and `13 §5.4` together.** This task authors the value, names the conflict in a comment on that line,
  and carries it into the PR body. Picking silently is what leaves the error panel and the first frame
  one hex apart with no test between them.
- **Do not "restore" the prettier value.** `#6B675F` as struck ink measures **3.52:1**; `#A63A32` as
  the madder measures **3.08:1** on the page and **2.65:1** on a slab. Both look better and both were
  overruled by Indelible rule 4 — §2.4 records why: *"in a system whose entire claim is that a struck
  row stays legible forever, 3.52:1 is a contradiction of the thesis, not just an accessibility
  miss."* `#6B675F` is demoted to a non-text rule; `#8F8A7E` (5.75:1) carries struck text.
- **Two placement rules travel with these values and belong in comments here**, because they are the
  first thing a component author in N10 gets wrong: `--ink-low` and `--rule` are **never** drawn on
  `--slab-pressed` (4.16 and 2.54 — a pressed slab carries `--ink-full` only and its border goes to
  `--ink-mid`), and `--madder-rule` is **never set as text and never carries a glyph** — it is a 2 px
  line and nothing else.
- **The allowlist key must name a rule id the rule table actually declares.** The key format is
  `'<path> :: <id>'` (`01 §3.2`). A line naming an id no row uses exempts nothing, silently, and looks
  correct in a diff forever. Before committing, grep `tool/check_policy.dart` for both ids and confirm
  they exist with those exact spellings — `CONVENTIONS §4.7` fixes the namespaces as
  `token`/`theme`/`type`/`gesture`/`a11y`/`ui`/`launch`, so if N03 landed a different spelling, the
  key follows the gate, and the mismatch is a defect worth raising there.
- **The reason for each `[exempt]` line goes in the commit message, not in a code comment.**
  `00-README` §7.4 makes it its own rule: an `[exempt]` line *"deletes a rule for one file, forever,
  silently, and the reason goes in the commit message that adds it."* Two lines, two reasons, one
  commit.
- **`Color.fromARGB` and `Color.fromRGBO` are banned here too.** They are a separate row
  (`token.raw_color_ctor`) with **no** exempt line for this path, so the exemption you are adding does
  not cover them. Every value in this file is a `Color(0x…)` literal.
- **`token.magic_size` does not fire on a bare `const s04 = 4.0;`** — its regex targets `width:`,
  `height:`, `spacing:`, `strokeWidth:`, `SizedBox(`, `EdgeInsets.…(` and friends followed by a digit
  other than 0 or 1. If it does misfire, do not widen the exempt line to silence it: `13`'s
  gate-integrity rule says say so and stop.
- **Nothing from `the-register.md` or `strip-bay.md`.** Neither direction was selected and neither
  contributes a value, a name or a comment (`02-build-manifest.md` §4.3).

### 5.4 The full test set

`test/policy/primitives_are_private_test.dart` — a source-text test. No widget pump, no database, no
`ProviderScope`.

| Case | What it asserts |
|---|---|
| `'primitives.dart is imported by no file outside lib/core/ui/ and has exactly two allowlist lines'` | **The anchor.** Walks `lib/**/*.dart` (skipping `*.g.dart` and `*.drift.dart`), matches the primitives-import regex, expects the out-of-directory set to be empty; then reads `tool/policy_allowlist.txt`'s `[exempt]` section and expects the two keys this task adds |
| `'the [exempt] section has exactly four lines and every id it names exists in the rule table'` | R56's count, plus the silent-typo case — each key's `<id>` half is present in `tool/check_policy.dart`'s source |
| `'primitives.dart imports only dart:ui'` | Exactly one `import` line, and it is `dart:ui`. Catches the `package:flutter/material.dart` slip before `token.material_color` has to |
| `'no const in primitives.dart is named after its job'` | Every declared identifier matches the value-naming scheme and none contains `page`, `strike`, `struck`, `spine`, `border`, `disabled` or `error`. The tier boundary, made executable |
| `'every colour literal under lib/ is in primitives.dart or night_error_panel.dart'` | The positive form of the gate row, so a failure names the offending file rather than a rule id |
| `'no two constants carry the same hex'` | A duplicated value means the next tier picks one arbitrarily and the palette gains an invisible alias that survives every rename |
| `'every surface, ink, rule and mark value in indelible.md §2.2, §2.3 and §2.6 appears in the file'` | The eleven dark values and the eleven red-shift values are all present — a ramp that is one value short compiles and fails only when a component reaches for the missing one |

**Nothing in this task is time-shaped**, so there is no `test/domain/uk_zone/` case and no
`@Tags(['uk-zone'])` here. The first time-shaped file in this epic is T06's `formatters.dart`, and its
DST case is written there.

## 6. Constraints that bind this task

- **3am** — this file authors the numbers the whole floor rests on: `tapMin` 60 alongside Indelible's
  64, the surfaces that make the app dark-only, and the inks that make every text pair ≥ 4.5:1. A
  wrong constant here is a wrong constant on twelve screens, and nothing downstream can correct it.
- **One tier per fact.** A primitive is a value; its meaning is T02's and its composition is T03's. If
  you want to write a comment explaining what a constant is *for*, that comment belongs one file up.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan)
  stay green; this file adds no dependency at all, which is the point of writing twelve lines of
  arithmetic rather than importing a colour package.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'primitives.dart is imported by no file outside lib/core/ui/ and has exactly two allowlist lines'` passes, and was seen to fail first for the stated reason
- [ ] no file outside `lib/core/ui/` imports it
- [ ] exactly two allowlist lines, each with its reason in the commit message
- [ ] no value from either unselected design direction appears anywhere
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the file's only import is `dart:ui`, and `Color.fromARGB` / `Color.fromRGBO` appear nowhere in it
- [ ] `tool/policy_allowlist.txt`'s `[exempt]` section has **four** lines, and every id it names exists in `tool/check_policy.dart`'s rule table
- [ ] every hex carries its measured ratio in a trailing comment; `#6B675F` and `#A63A32` are not restored to text roles
- [ ] both `tapMin` 60 and Indelible's 64 floor are represented, and the twelve-step spacing scale is complete
- [ ] **P14 is named in a comment on `nSurface04` and carried into the PR body** — it is ruled in N11-T04, not here
- [ ] the commit message names the `00-README` §8 layers this task skipped and why

## 8. Verification

```bash
fvm flutter test test/policy/primitives_are_private_test.dart
dart tool/check_policy.dart          # prints `policy ok`; G2 + G3
make check
make test
```

Then confirm by hand what the gate proves — seeing it fire once is worth more than trusting it:

```bash
grep -rn "Color(0x" lib/ --include='*.dart' | grep -v '\.g\.dart' | grep -v '\.drift\.dart'
# expect two files only: lib/core/ui/primitives.dart and lib/core/ui/night_error_panel.dart

grep -rn "core/ui/primitives.dart" lib/ --include='*.dart'
# expect zero importers today; exactly one — lib/core/ui/palettes.dart — after T03

sed -n '/^\[exempt\]/,$p' tool/policy_allowlist.txt | grep -c '::'
# expect 4
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): primitives.dart — the only raw hexes in the app`

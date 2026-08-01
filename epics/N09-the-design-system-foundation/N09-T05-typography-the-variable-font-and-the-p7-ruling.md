# N09-T05 — Typography, the variable font, and the P7 ruling

| | |
|---|---|
| **Epic** | [N09 — The design system foundation](epic.md) · `00-README` §9 step 4 (1 of 3) |
| **Task** | 5 of 9 |
| **Depends on** | N09-T04 |
| **Commit** | one commit · `feat(ui): typography, the variable font axis, and the P7 ruling` |

## 1. Why this task exists

The two voices, the variable font asset, the scale with an 18 px absolute floor, the
weight cap and tabular figures. **This task rules P7**: the design system asks for 390 / 420 / 520 /
600 weights, which need `FontVariation`, while `06 §5.2` records the Atkinson axis as 500–700. Rule it
against the real font file and amend whichever document is wrong, in this commit.

It also lands `02-build-manifest.md` §4.4's **defect 2**: the Indelible artefact sets `--t-stamp` at
14 px (49 uses) and `--t-head` at 16 px (13 uses), and §3.4's own third exemption condition — *"no
stamp is ever the sole carrier of its meaning"* — fails on `DEAD`, on `AUTO-CAPTURED` (the sole §12.5
provenance label), on `DERIVED FROM N STROKES` (the sole statement of the §12.4 claim) and on the page
header. Those four are not exempt stamps and take a ≥ 18 px role. Every other stamp keeps the
exemption.

This is the epic's **irreversible** commit: a binary asset enters git history and a `pubspec.yaml`
`fonts:` block enters four other artefacts' assumptions.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §5.1 (the fifteen roles and `buildShedTextTheme`'s body) · §5.2 (**the font asset and the checks that must run before the pubspec entry**) · §5.3 (the w700 cap and flutter#139712) · §5.4 (tabular figures and the silent failure) · §5.5 (never clamp; what the no-clamp rule costs and how it is paid) | the scale, the family declaration, the cap, the ban list |
| `docs/design/indelible.md` | §3.1–§3.2 (two voices, the two stacks, the 1/7 and 6/8 test) · §3.3 (**390 / 420 / 520 / 600**, nothing italic, no small caps) · §3.4 (the twelve-token scale and **the three-part stamp exemption test**) · §3.5 (tabular numerals policy, and the one documented exception) · §3.6 (at 200%, rows grow and the grid does not move) | every size, tracking and weight; the exemption test this task corrects |
| `docs/engineering/REFERENCES.md` | §22 **C1** (Atkinson's real file size, `wght` range and figure features — never downloaded) · §22 **B8** (whether `pdf` accepts a variable font at all) | the two checks that must run before the pubspec entry is written |
| `docs/research/00-tech-decisions.md` | §5 · #98 (bundled Atkinson Hyperlegible Next, 18 pt floor, w700 cap) · #99 (never clamp) · #127 (< 5 MB bundled assets) | the decision rows the P7 ruling may have to amend |
| `docs/engineering/CONVENTIONS.md` | §1 (`assets/fonts/` holds the TTF and `OFL.txt`) · §4.7 (`type.*` rule ids) | the paths |
| `epics/00-PLAN.md` | E08-T05 | defect 2's exact three strings |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-design-system` | it owns the two-voice law, the scale, the weights, and it states P7 as open rather than picking |
| `shed-accessibility-and-copy` | the 18 px floor, the never-clamp rule and the text-scaling behaviour the scale must survive |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/typography_test.dart`
- **Test** — `'every weight the app uses exists on the shipped variable font axis'`
- **Why it is red today** — P7 is an open conflict and the two documents disagree about the axis range.

```bash
fvm flutter test test/design/typography_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it cannot pass on a remembered number: the test **reads the shipped file**.
`flutter test` runs with the package root as its working directory, so
`File('assets/fonts/<name>.ttf').readAsBytesSync()` reaches the committed asset; parse the `fvar`
table's `wght` axis minimum and maximum out of those bytes, collect every weight
`buildShedTextTheme` actually emits, and assert each one falls inside the range. A test that compares
two constants proves the constants agree with each other and nothing about the font.

**Green.** The minimum code that passes, and nothing beyond it — load the shipped font, enumerate the axis, rule the conflict, amend the losing document
per the amendment rule, and let the test read the font file rather than a constant.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Assets, UI, docs and tests.** No schema, no domain, no data, no wiring, no controller. There is no
ARB entry either — the two-voices sentence Settings prints (`indelible.md` §3.1, §12) is N29's ARB
message, not this task's. Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `assets/fonts/<face>[wght].ttf` | **New, binary, irreversible.** Taken from the Google Fonts OFL distribution. Which file(s) depends on the P7 ruling below |
| 2 | `assets/fonts/OFL.txt` | **New.** Committed beside the face, per `06 §5.2`. One per family if the ruling lands on two |
| 3 | `pubspec.yaml` | The `flutter: fonts:` block. **One variable file per family, no per-weight asset entries and no `FontVariation` lists** — post-3.41 `FontWeight` drives the `wght` axis |
| 4 | `docs/perf/measurements.md` | **The byte count and the `wght` axis range, read off the actual file, with the download date.** `06 §5.2` requires both *before* the pubspec entry is written |
| 5 | `lib/core/ui/theme.dart` | `buildShedTextTheme` gains `fontFamily`, the weight policy the ruling settles, and the corrected exempt-stamp role. T04 landed its structure |
| 6 | `docs/design/indelible.md` **or** `docs/engineering/06-design-system.md` | The **P7 amendment**, in this commit, on whichever document the measurement contradicts |
| 7 | `docs/research/00-tech-decisions.md` | Decision **#98**'s row, if the ruling changes it. `00-README` §10: the decision record and every document that applies it move in the **same change** |
| 8 | `test/design/typography_test.dart` | **New.** The anchor and the cases in §5.4 |

**The licence registration has no home yet.** `06 §5.2` requires `LicenseRegistry.addLicense`, and the
call site is `main()`, which is **N11-T03**. Either land a top-level registration function in
`theme.dart` for N11 to call, or commit `OFL.txt` here and record the obligation in the PR body so
N11-T03 picks it up. Do not leave the licence uncommitted either way — the font is OFL 1.1 and
shipping it without its licence is a distribution defect, not a housekeeping one.

### 5.2 The signatures

`06 §5.1`'s body, with the family filled in by the ruling:

```dart
// lib/core/ui/theme.dart
TextTheme buildShedTextTheme(ShedTokens t) {
  const List<FontFeature> tabular = <FontFeature>[FontFeature.tabularFigures()];
  // No weightBump parameter exists. Bold Text is the framework's job (§5.3).
  TextStyle s(double size, FontWeight w, {List<FontFeature>? f}) => TextStyle(
        fontFamily: 'AtkinsonNext',
        fontSize: size,
        fontWeight: w,          // 3.41+: FontWeight drives the wght axis directly
        color: t.textPrimary,
        height: 1.4,            // headroom for WCAG 1.4.12; see §5.5
        fontFeatures: f,
      );
  final double n = t.numeralSize;   // 40, or 44 in a night-shift palette
  final double b = t.bodySize;      // 18, or 20 in a night-shift palette
  return TextTheme(
    displayLarge:  s(n + 24, FontWeight.w700, f: tabular),
    displayMedium: s(n + 8,  FontWeight.w700, f: tabular),
    displaySmall:  s(n,      FontWeight.w700, f: tabular),
    headlineLarge: s(32,     FontWeight.w700, f: tabular),
    headlineMedium:s(28,     FontWeight.w600),
    headlineSmall: s(24,     FontWeight.w600),
    titleLarge:    s(24,     FontWeight.w600),
    titleMedium:   s(b + 2,  FontWeight.w600),
    titleSmall:    s(b,      FontWeight.w600),
    bodyLarge:     s(b + 2,  FontWeight.w500),
    bodyMedium:    s(b,      FontWeight.w500),
    bodySmall:     s(b,      FontWeight.w500),
    labelLarge:    s(b + 2,  FontWeight.w700),
    labelMedium:   s(b,      FontWeight.w600),
    labelSmall:    s(b,      FontWeight.w600),
  );
}
```

The `pubspec.yaml` block, for the one-family case:

```yaml
flutter:
  fonts:
    - family: AtkinsonNext
      fonts:
        # One variable file. Post-3.41 FontWeight drives the wght axis, so
        # there are no per-weight asset entries and no FontVariation lists.
        - asset: assets/fonts/AtkinsonHyperlegibleNext[wght].ttf
```

The scale itself is `indelible.md` §3.4's twelve tokens, split by voice — which is how rule 2 becomes
checkable rather than a matter of taste:

- **Record face, all tabular:** `--t-figure` 56 · `--t-tag-xl` 44 · `--t-tag` 32 · `--t-record` 20
  (tracking 0.006em — the record body) · `--t-record-sm` 18 (record floor) · `--t-margin` 18.
- **Control face:** `--t-slab` 26 caps / 0.06em · `--t-ctl-lg` 22 · `--t-ctl` 20 · `--t-ctl-sm` 19
  (control floor) · `--t-head` **18** caps / 0.10em (**corrected from 16**) · `--t-stamp` 14 caps /
  0.14em, **exempt stamps only**.

### 5.3 The details that are easy to get wrong

- **P7 is two conflicts and closing one is not closing P7.**
  - *Half one — the typeface.* `indelible.md` §3.2 requires **two** bundled families, Source Serif 4
    and Source Sans 3, because rule 2 (serif = record, sans = control) **is** the design and collapses
    without them; whole payload under 700 kB. The engineering set bundles **one**: decision #98 names
    Atkinson Hyperlegible Next, `CONVENTIONS §1` puts
    `assets/fonts/AtkinsonHyperlegibleNext[wght].ttf + OFL.txt` in the tree, `06 §5.2` declares the
    family `AtkinsonNext`, `09 §4.2` embeds that same file in every PDF and `12 §8.3` loads it in
    `test/flutter_test_config.dart`. **Two faces moves four artefacts together** and adds ~700 kB
    against `13 §6`'s under-5 MB budget.
  - *Half two — the axis.* Flutter's `FontWeight` is w100–w900 in hundreds, so 390 and 420 cannot be
    expressed as a `FontWeight` at all; they need `FontVariation('wght', 390)` on a live variable
    axis, and `06 §5.2` records the required axis as **500–700**, which excludes both.
- **`Text.build` merges `FontWeight.bold` and does not touch `fontVariations`.** This is the trap
  inside half two. When `MediaQuery.boldTextOf(context)` is true the framework merges
  `const TextStyle(fontWeight: FontWeight.bold)` and `merge` wins — but a weight expressed as a
  `FontVariation` is not a `fontWeight`, so it is **not** merged, and the user's Bold Text setting is
  silently ignored on every string that uses one. Whichever way the ruling lands, state how Bold Text
  is honoured. `06 §5.3`'s w700 cap exists for the mirror-image bug: w800/w900 render *lighter* under
  Bold Text (flutter#139712), and `type.weight_cap` greps for them.
- **Run `REFERENCES §22` C1 *before* the pubspec entry is written**, because the font was never
  downloaded while `06` was authored. Three separate unknowns, and the third is a legibility question
  a desk cannot answer: (a) the file size, since decision-record §5 does not carry the font and there
  is no authoritative number to copy; (b) the `wght` axis range; (c) the claim that it has **no**
  `zero` / slashed-zero feature and no `ss01`/`cv` variants and separates `0` from `O` by counter
  shape and width alone. Check (c) on a real device under a head torch. If it fails, the documented
  fallback is **Inter** with `FontFeature.slashedZero()`.
- **`REFERENCES §22` B8 is a downstream blocker you can close cheaply here.** Whether `package:pdf`
  accepts a *variable* font at all is unverified — it has its own TTF parser and `fvar`/`gvar` may be
  ignored, mis-rendered or rejected. Twenty minutes: build a one-page document with
  `pw.Font.ttf(...)`, open it in Preview **and** Acrobat. The fallback is two static instances, which
  changes what this task commits. Note the outcome even though the PDF work is N21.
- **`theme.dart` may not import `primitives.dart`.** The `token.primitives_import` rule applies under
  all of `lib/` and the only exempt path is `palettes.dart`. So every number `buildShedTextTheme` uses
  must arrive as a `ShedTokens` field (`t.bodySize`, `t.numeralSize`) — that is why `06 §5.1`'s body
  reads the way it does, and it is also why **the exempt-stamp size cannot be a literal here**.
- **The exempt-stamp role has no free `TextTheme` slot.** `06 §5.1` uses all fifteen and collapses
  `bodySmall` and `labelSmall` into the 18 floor. The 14 px stamp is therefore a **named `TextStyle`
  beside `buildShedTextTheme`**, never an inline size at a call site — `token.literal_font_size` greps
  `fontSize:\s*[0-9]` under `lib/` with no exempt line, so its size arrives as a `ShedTokens` field
  too. Declare the name in this commit the way `10 §9.1` declared `formatShed*`: a new name, stated by
  its owning document.
- **The three strings that lose the exemption, and the header.** `DEAD`, `AUTO-CAPTURED` and
  `DERIVED FROM N STROKES` each fail §3.4's third condition — each is the **sole** carrier of its
  meaning on its line — and the page header is the only statement of which night you are looking at.
  All four take a ≥ 18 px role. The three strings' *call sites* are N16-T02/T07 and
  N11's first-frame work; **this task lands the corrected exemption test**, so that when those tasks
  arrive the rule is already executable.
- **Indelible's 150% cap on `--t-stamp` at 200% scale is a clamp, and clamps are banned.**
  `indelible.md` §3.6 caps the stamp at 150% because *"a caps-tracked 28 px stamp would be wider than
  the margin cell"*; `06 §5.5` and decision #99 ban every form of clamping —
  `withClampedTextScaling`, `TextScaler.clamp` and `FittedBox` are all gate rows (`type.clamp`,
  `type.fitted_box`). The layout pays instead: `Wrap`, label-above-value, `Flexible` with
  `softWrap: true`, `ConstrainedBox(minHeight:)`. Name this in the PR; the layout consequence is
  `indelible-page-and-screens`' and lands in N10/N13, but the *rule* is settled here.
- **Nothing is italic, anywhere, ever.** Italic serifs smear under halation and the thin joins in an
  italic `e` or `a` vanish at 30% brightness. There is no small-caps either — stamps are true all-caps
  with positive tracking. Emphasis is a face swap, a 2 px rule or a stamp; never slope.
- **Every figure is tabular lining, in the record *and* in a control**, keypad digits and ease digits
  included, because a digit must never change width between the button you press and the row it prints
  into. The failure is silent: a freshly constructed `TextStyle` for a numeral drops `fontFeatures`
  and the pen board starts jittering as `412` and `108` take different widths. Go through the role.
- **The one documented exception to the two-voice rule:** the **keypad digits are set in the record
  face**. The shepherd is matching a key against a digit already printed in the row above — same
  shape, same width, no translation step. Settings prints the exception beside the two-voices line,
  because an unexplained exception is a bug.
- **`google_fonts` is banned and grepped** (`type.google_fonts`): 8.2.0 depends on `http` and fetches
  at runtime by default, which is a network path in an app that ships without `INTERNET`.
- **The filename contains square brackets.** `AtkinsonHyperlegibleNext[wght].ttf` is a glob pattern in
  most shells — quote it in every command, and expect `ls assets/fonts/*[wght]*` to behave oddly.
  Dart's `File()` takes it literally and is fine.

### 5.4 The full test set

`test/design/typography_test.dart`.

| Case | What it asserts |
|---|---|
| `'every weight the app uses exists on the shipped variable font axis'` | **The anchor.** Reads the committed TTF's bytes, parses `fvar`'s `wght` min/max, and checks every weight `buildShedTextTheme` emits |
| `'the committed font's byte count matches docs/perf/measurements.md'` | The recorded measurement is the one on disk, so a silent font swap fails rather than passes |
| `'no role in buildShedTextTheme is below 18 except the named stamp role'` | Iterates all fifteen roles at textScaler 1.0 in every palette |
| `'the stamp role is the only style below 18 anywhere under lib/'` | Source text plus role inspection. The exemption is one role, not a habit |
| `'DEAD, AUTO-CAPTURED and DERIVED FROM N STROKES resolve to a role at or above 18'` | Defect 2, executable — written now so N16 and N11 inherit a passing rule rather than a prose note |
| `'the page header role is at least 18'` | `--t-head`'s correction from 16 |
| `'no style exceeds FontWeight.w700'` | The cap. flutter#139712 makes w800/w900 render *lighter* under Bold Text |
| `'every aligned-numeral role carries FontFeature.tabularFigures'` | `displayLarge`, `displayMedium`, `displaySmall`, `headlineLarge` at minimum |
| `'no style is italic and none uses small caps'` | `fontStyle` is never `FontStyle.italic` under `lib/` |
| `'at textScaler 2.0 every role scales linearly and none is clamped'` | Pump a `MediaQuery` with `TextScaler.linear(2.0)`; every role doubles. Catches a re-introduced clamp before N33's matrix does |
| `'google_fonts appears in neither pubspec.yaml nor lib/'` | The offline contract, at the type layer |
| `'textScaleFactor, TextScaler.clamp, withClampedTextScaling and FittedBox appear nowhere under lib/'` | Decision #99 and `06 §5.5`, as one source-text sweep |
| `'the P7 ruling is recorded and the losing document agrees with the code'` | Reads the amended section and the family name out of `pubspec.yaml`; if the ruling is deferred, this case names it as deferred rather than passing silently |
| `'each declared family has an OFL.txt beside it'` | One licence per family in `assets/fonts/` |

**Nothing here is time-shaped.** No `uk-zone` case; T06 has the epic's only one.

## 6. Constraints that bind this task

- **3am** — the 18 px body floor is a floor, not a target: record body 20 px, control floor 19 px,
  absolute floor 18 px. The 1/7 and 6/8 test is the acceptance test for any face: read at 32 px, at
  30% screen brightness, through a sandwich bag. If `412` could be `417`, the face is wrong however
  handsome it is.
- **Offline** — no network path may be added. `google_fonts` fetches at runtime and is a gate row; the
  face is **bundled**, and G2 (the dependency allowlist) and G3 (the import scan) stay green.
- **Irreversible** — a binary asset and a `pubspec.yaml` `fonts:` block. Read the `pubspec.lock` diff
  if there is one. Four artefacts assume this decision: `assets/fonts/`, the `fonts:` block, the PDF's
  embedded TTF (`09 §4.2`) and the golden font loader (`12 §8.3`).
- **The amendment rule** — if the ruling changes decision #98, `docs/research/00-tech-decisions.md`
  §2's row is struck **with its reason** and every document that names #98 changes in this same
  commit. A superseded decision is never quietly rewritten.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every weight the app uses exists on the shipped variable font axis'` passes, and was seen to fail first for the stated reason
- [ ] the ruling is written and the losing document is amended in this commit
- [ ] no text style falls below 18 px
- [ ] figures are tabular wherever a number is compared down a column
- [ ] the test reads the shipped font, not a table
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] **both halves of P7 are addressed** — the typeface *and* the `FontVariation` weight axis — and the ruling says how Bold Text is honoured
- [ ] `REFERENCES §22` **C1** has been run: the byte count, the `wght` range and the `0`/`O` check are recorded in `docs/perf/measurements.md` with the download date
- [ ] `OFL.txt` is committed beside every declared family, and the `LicenseRegistry.addLicense` call site is named
- [ ] `DEAD`, `AUTO-CAPTURED`, `DERIVED FROM N STROKES` and the page header take a role at or above 18 px; every other stamp keeps the exemption
- [ ] no style exceeds `FontWeight.w700`; nothing is italic; `google_fonts` appears nowhere
- [ ] `textScaleFactor`, `TextScaler.clamp`, `withClampedTextScaling` and `FittedBox` appear nowhere under `lib/`
- [ ] if decision #98 changed, its row is struck with its reason and every document naming it changed in this commit

## 8. Verification

Read the font before anything else — the measurement is the ruling's evidence:

```bash
ls -l 'assets/fonts/AtkinsonHyperlegibleNext[wght].ttf'    # byte count → docs/perf/measurements.md
fc-query -f '%{fontversion}\n%{variable}\n' 'assets/fonts/AtkinsonHyperlegibleNext[wght].ttf'
ttx -t fvar -o - 'assets/fonts/AtkinsonHyperlegibleNext[wght].ttf' | grep -A2 'wght'
# read the wght axis minValue / maxValue out of fvar, not out of a document
```

Then:

```bash
fvm flutter pub get
fvm flutter test test/design/typography_test.dart
fvm flutter test test/design/
make check
make test
```

```bash
grep -rn "GoogleFonts\|google_fonts" lib/ pubspec.yaml                       # expect zero
grep -rn "FontWeight.w800\|FontWeight.w900\|FontStyle.italic" lib/ --include='*.dart'   # expect zero
grep -rn "textScaleFactor\|TextScaler.clamp\|withClampedTextScaling\|FittedBox" lib/ --include='*.dart'  # expect zero
grep -rn "fontSize: *[0-9]" lib/ --include='*.dart'                          # expect zero — roles only
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): typography, the variable font axis, and the P7 ruling`

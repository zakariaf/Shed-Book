# N09-T03 — `palettes.dart` — night, amber and deep red, each with a high-contrast variant

| | |
|---|---|
| **Epic** | [N09 — The design system foundation](epic.md) · `00-README` §9 step 4 (1 of 3) |
| **Task** | 3 of 9 |
| **Depends on** | N09-T02 |
| **Commit** | one commit · `feat(ui): the six palettes, measured against 4.5:1 and 3:1` |

## 1. Why this task exists

Six palettes, **measured rather than chosen**: every text pair recomputed to 4.5:1 and
every rule and mark to 3:1, in code, by the test — not by eye and not by a design tool's report.

This is the epic's honest demo and the whole argument for Indelible rule 4: *"a design that looks
better on a calibrated laptop at 400 nits and fails on a five-year-old Android at 30% brightness
through a wet freezer bag has failed at the only moment it exists for."* `06 §3.5` says the same from
the other side: *"if a number in this document and the test disagree, the test is right and the
document is stale — which is the only reason it is safe to print sixty ratios in prose at all."*

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §2.3 (the hand-authored `ColorScheme` and its three rules) · §3.5 (`wcag.dart`, `contrast_test.dart`, the exact assertions) · §4.1 (`resolvePalette`, `shedPalettes`, the frozen Settings labels) · §4.2–§4.5 (the four published ramp tables) · §9 (why `launchSurface` is duplicated in the test) | the file, the six literals, every assertion |
| `docs/design/indelible.md` | §2.1 (the method, worked) · §2.4 (**what measurement overruled**) · §2.5 (the dark contrast table) · §2.6 (red-shift, and the one deliberate inversion) · §2.7 (there is no status palette) | the values, and the floors that outrank taste |
| `docs/engineering/CONVENTIONS.md` | §2.11 · §4.7 (`palettes.dart :: token.primitives_import` is one of the four `[exempt]` lines) · R35 | the path, and the one file allowed to import `primitives.dart` |
| `docs/engineering/12-testing.md` | §7.6 | why the pixel-sampling half of this file is 42 runs, tagged `slow`, and belongs to N33 |
| `docs/research/00-tech-decisions.md` | §5 · #94, #95, #96 | hand-authored schemes; four theme slots; amber **and** deep red ship, labelled honestly |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-design-system` | the palette and the measured floors are its subject, and it forbids restoring either overruled value |
| `shed-testing` | the gate that recomputes rather than trusts, and where each half of it lives |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/contrast_test.dart`
- **Test** — `'every text pair in all six palettes reaches 4.5 to 1 and every rule and mark 3 to 1'`
- **Why it is red today** — no palettes exist and no arithmetic checks them.

```bash
fvm flutter test test/design/contrast_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion: the test **names the failing pair**. `expect(contrastRatio(fg, bg),
greaterThanOrEqualTo(floor), reason: '${p.name}: <fg-token> on <bg-token>')` — a bare
`Expected: a value greater than or equal to <4.5>` over six palettes and forty pairs tells you
nothing at 9am.

**Green.** The minimum code that passes, and nothing beyond it — the six palettes plus `wcag.dart`'s relative-luminance arithmetic, and a test that
iterates every pair.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**UI and tests only.** No schema, no domain, no data, no wiring, no controller, no ARB string — the
four Settings labels are frozen by R35 but the Settings *screen* is N29. Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/palettes.dart` | **New.** Six `ShedPalette` literals, six `ColorScheme` literals, `resolvePalette` and the `shedPalettes` list. **The only file in the app that imports `primitives.dart`** — its `[exempt]` line was added in T01 |
| 2 | `test/design/wcag.dart` | **New.** `relativeLuminance`, `contrastRatio`, `peakLuminance`, `launchSurface`. Twelve lines of arithmetic, no package. Not a `_test.dart` file, so the runner does not execute it directly |
| 3 | `test/design/contrast_test.dart` | **New.** The anchor and the whole arithmetic half. The **pixel-sampling** `textContrastGuideline` group is a second `group` in this same file and lands at N33, tagged `slow` (`12 §7.6`) — leave a comment saying so, so nobody creates a second file |

T08 completes the gate set (`tap_target_test.dart`, `reduce_motion_test.dart`) and adds the comment in
each file naming N33 as the home of the sweeps. `wcag.dart` and `contrast_test.dart` land **here**,
because this task's anchor cannot run without them.

### 5.2 The signatures

```dart
// lib/core/ui/palettes.dart  (allowlisted for raw primitives — 06 §3.5)
ShedPalette resolvePalette(ShedPaletteId id, {required bool highContrast}) =>
    switch ((id, highContrast)) {
      (ShedPaletteId.night,   false) => nightPalette,
      (ShedPaletteId.night,   true)  => nightHcPalette,
      (ShedPaletteId.amber,   false) => amberPalette,
      (ShedPaletteId.amber,   true)  => amberHcPalette,
      (ShedPaletteId.deepRed, false) => deepRedPalette,
      (ShedPaletteId.deepRed, true)  => deepRedHcPalette,
    };

/// The same six, as a list, so the contrast suite cannot silently skip one.
/// A switch over (enum, bool) is exhaustive and a missing arm is a compile
/// error; a list is not, so this is the one place the count is asserted.
const List<ShedPalette> shedPalettes = <ShedPalette>[
  nightPalette,   nightHcPalette,
  amberPalette,   amberHcPalette,
  deepRedPalette, deepRedHcPalette,
];
```

Six top-level `const ShedPalette` literals — `nightPalette`, `nightHcPalette`, `amberPalette`,
`amberHcPalette`, `deepRedPalette`, `deepRedHcPalette` — each with its `name` string (`'night'`,
`'night-hc'`, `'amber'`, `'amber-hc'`, `'red'`, `'red-hc'`; the `name` is what the test group prints).
Beside each, a `const ColorScheme` literal in `06 §2.3`'s shape:

```dart
const ColorScheme nightScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: nInk92,          onPrimary: nSurface04,        // 16.16:1
  primaryContainer: nSurface18, onPrimaryContainer: nInk92,
  secondary: nInk72,        onSecondary: nSurface04,      // 10.29:1
  secondaryContainer: nSurface12, onSecondaryContainer: nInk92,
  tertiary: nInk72,         onTertiary: nSurface04,
  // `error` is Material's own destructive role. It is NOT statusLoss: a lamb
  // that died is a recorded fact, not an application error (spec §12.2).
  error: nSalmon80,         onError: nSurface04,          // 11.47:1
  errorContainer: nSurface18, onErrorContainer: nSalmon80,
  surface: nSurface04,      onSurface: nInk92,            // 16.16:1
  surfaceDim: nSurface04,   surfaceBright: nSurface18,
  surfaceContainerLowest: nSurface04, surfaceContainerLow: nSurface08,
  surfaceContainer: nSurface08, surfaceContainerHigh: nSurface12,
  surfaceContainerHighest: nSurface18,
  onSurfaceVariant: nInk72,                               // 10.29:1
  outline: nInk40,          outlineVariant: nInk40,       //  6.11:1
  inverseSurface: nInk92,   onInverseSurface: nSurface04,
  inversePrimary: nSurface04,
  shadow: nSurface04,       scrim: nSurface04,
  surfaceTint: nSurface04,
);
```

`test/design/wcag.dart` is `06 §3.5`'s file, unchanged:

```dart
double relativeLuminance(Color c) => c.computeLuminance();

double contrastRatio(Color a, Color b) {
  final double la = relativeLuminance(a), lb = relativeLuminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

double peakLuminance(ShedPalette p) => [ … ].map(relativeLuminance).reduce(math.max);

/// The native launch colour, §9. Duplicated here deliberately: if someone
/// edits nSurface04 without editing the native config, this test must fail.
const Color launchSurface = Color(0xFF0B0D0E);
```

### 5.3 The details that are easy to get wrong

- **`Color.computeLuminance()` *is* the WCAG 2.0 relative-luminance formula** — 0.2126R + 0.7152G +
  0.0722B over linearised sRGB, citing the W3C definition in `dart:ui`'s own source. Re-deriving
  `pow(c, 2.4)` by hand buys nothing and is *"one typo away from a palette that passes a wrong test."*
  `wcag.dart` adds the ratio and the two aggregates and nothing else. Equally: **do not import a
  colour package** — twelve lines of arithmetic would have to clear the G2 dependency allowlist and
  the offline contract for no gain.
- **The night-shift luminance assertion and Indelible's deliberate inversion collide.** `06 §3.5`
  asserts `peakLuminance(p) < 0.70 * peakLuminance(nightPalette)` for both night-shift palettes, over
  `textNumeric`, `textPrimary` and the three status tokens. Indelible §2.6 says that in red-shift
  *"`--madder-ink` becomes the **brightest** mark on the page (L 0.614 vs 0.467)"*, because with no hue
  channel left, luminance is what identifies it. Night's `--ink-full` is L 0.80885, so the threshold is
  0.566 — and a `statusLoss` mapped to the red-shift madder at L 0.614 **fails**. This is a real
  collision, you will hit it, and the wrong fix is to relax the 0.70 factor: that is the
  edit-the-gate-to-make-it-green anti-pattern `13` names by name. The two honest fixes are (a) T02's
  mapping does not put the madder in a `status*` field, or (b) the assertion is re-derived over the
  body-text tokens only, with the inversion documented — and either way `06 §3.5` is amended in this
  commit per `00-README` §10.
- **Never `ColorScheme.fromSeed`.** It is a gate row (`token.seeded_scheme`), and the reason is not
  taste: Flutter 3.41 changed `onPrimaryContainer`, `onSecondaryContainer`, `onTertiaryContainer` and
  `onErrorContainer` for every generated scheme, and *"you cannot ask a seed for ≥ 12:1 on the base
  surface."* Here legibility is a safety property, not a brand property.
- **The deprecated roles are never set.** `background`, `onBackground` and `surfaceVariant` are
  deprecated on this SDK. Setting one is an analyzer **info**, and the `gate` job runs
  `flutter analyze --fatal-infos`, so it is a CI failure — which is the mechanism, not a nicety.
  There is also a gate row scoped to `lib/core/ui/` (`theme.deprecated_scheme_role`).
- **Widgets never read `colorScheme`; Material's own widgets have no choice.** That is the entire
  reason to author one. `SnackBar`, `AlertDialog`, the text-selection handles and toolbar,
  `InkSparkle`, the `GlobalMaterialLocalizations` pickers, `Scrollbar` and every `ThemeData`
  sub-theme fallback read it. If it is not authored it is generated. `token.color_scheme_read` bans
  the identifier under `lib/features/` and `lib/core/ui/components/`, but not here.
- **`error` never doubles as `statusLoss`.** Conflating them paints a recorded death in the same
  pixels as a failed write — a spec §12.2 problem wearing a palette's clothes. Indelible §2.7 is
  blunter still: for a dead lamb, colour is *"none, ever."*
- **`surfaceTint` equal to the base surface makes the M3 elevation blend a no-op.** Elevation in this
  app is the explicit surface ramp, not an overlay nobody measured. Indelible has no elevation at all —
  *"nothing casts a shadow"* — so this is the pinning that makes the two systems agree.
- **The ramp is a hint, not a separator, and the outline is what does the work under a torch.**
  1.07:1 and 1.18:1 between surface steps are far below the 3:1 WCAG asks of a non-text boundary,
  deliberately: *"a bright card edge is a light source you are staring at for four hours."* Any
  boundary that must be findable under a head torch carries an `outline` **as well as** a ramp step.
  A direction may widen the ramp; it may not drop the outline.
- **The AA exception is written in the code, beside the assertion, and applies to one palette.**
  `final double bodyFloor = p.id == ShedPaletteId.deepRed && !p.highContrast ? 4.5 : 7.0;` with a
  comment pointing at `06 §4.4`. No spectrally clean long-wavelength palette reaches AAA and stays
  spectrally clean — `#FF0000` on black is 5.25:1. **Do not relax the suite globally to hide it**, and
  do not "improve" deep red by pushing further toward orange: that buys contrast by adding green
  energy, which bleaches rhodopsin faster and defeats the palette's only purpose.
- **Compensation in the night-shift palettes is bought with size, never weight.** `bodySize` 18 → 20
  and `numeralSize` 40 → 44 in **both** night-shift palettes, not just deep red, so switching between
  the honest pair never reflows the screen. Bumping weight instead walks into flutter#139712.
- **P6 is live in this file.** Indelible ships two themes (dark, red-shift); `06 §4` ships six
  palettes with ids, stored keys and Settings labels frozen by R35. Indelible publishes **no amber
  table and no high-contrast variant**. So: `night` takes Indelible §2.2–§2.5, the `deepRed` pair
  takes Indelible §2.6's red-shift override, and `amber` plus the three HC siblings take `06 §4.3` and
  §4.5. **Supply values; never invent a palette id.** Every value, from either document, is
  re-measured by the test rather than trusted — and the PR body says which document each palette came
  from.
- **`launchSurface` is duplicated on purpose and P14 will move it.** `wcag.dart`'s
  `const Color launchSurface = Color(0xFF0B0D0E)` is a second copy of the native launch colour so that
  editing `nSurface04` without editing `android/app/src/main/res/values/colors.xml` fails this test.
  N11-T04 rules P14 (`#0B0D0E` vs `#0A0A0B`); when it does, this constant and the native config move
  together. Write the assertion as *"no palette's `surfaceBase` is brighter than the native launch
  colour"* so it still means something whichever way P14 lands.
- **The count assertion exists because the switch cannot make it.** `switch ((id, highContrast))` is
  exhaustive and a missing arm is a compile error; `shedPalettes` is a plain list and is not. Open the
  test with `expect(shedPalettes, hasLength(6))` **and** a check that every `(id, highContrast)` pair
  appears exactly once — otherwise a seventh palette added in season two gets its ratios published in
  a document and never tested.
- **Two placement rules are not palette values and cannot be expressed as one.** `--ink-low` and
  `--rule` are never drawn on `--slab-pressed` (4.16 and 2.54), and `--madder-rule` never carries a
  glyph. They bind *components*, so they cannot be a `contrast_test` assertion over a pair that is
  legal — which is why the test set below asserts the forbidden pairs measure **below** the floor. It
  is the rule's own evidence, and it stops a future reviewer "fixing" the placement rule as an
  oversight.

### 5.4 The full test set

`test/design/contrast_test.dart` — pure arithmetic. No pump, no database, no `ensureSemantics`.

| Case | What it asserts |
|---|---|
| `'every text pair in all six palettes reaches 4.5 to 1 and every rule and mark 3 to 1'` | **The anchor.** Iterates `shedPalettes`, and every failure names the palette and the pair |
| `'shedPalettes has six entries and every (id, highContrast) pair appears exactly once'` | The one place the count is asserted (`06 §4.1`) |
| `'<palette>: numerals clear the floor on base, raised and fill'` | Per-palette group, 7.0 except standard deep red at 4.5 |
| `'<palette>: primary and secondary text clear the palette floor'` | `textPrimary` at the floor, `textSecondary` at 4.5 |
| `'<palette>: chrome text clears AA and is never used for data'` | 4.5 minimum — and the name is the contract: chrome is never a value the shepherd must read |
| `'<palette>: outline clears the 3:1 non-text requirement'` | Including deep red's `#CC2200` at 3.80:1, which is outline-only and never carries a glyph |
| `'<palette>: status fills are legible with onStatus text'` | `contrastRatio(onStatus, statusX) >= 4.5` for all three |
| `'<palette>: the tap floor is never below spec §5 and bodySize never below 18'` | `tapMin >= 60.0`, `bodySize >= 18.0` — the 3am floor, asserted where the values live |
| `'no palette is brighter than the native launch colour'` | `relativeLuminance(p.tokens.surfaceBase) <= relativeLuminance(launchSurface)` for all six |
| `'the night-shift palettes drop luminance, not just hue'` | Both peak below 70% of `night`'s peak — see the collision in §5.3 before you write it |
| `'the two placement rules are load-bearing'` | `contrastRatio(textChrome, surfaceSlabPressed) < 4.5` and `contrastRatio(outline, surfaceSlabPressed) < 3.0`. The forbidden pairs, measured, so the rule reads as arithmetic rather than folklore |
| `'every ratio printed in 06 §4.2–§4.5 is reproduced'` | Spot-check the published figures — 16.16, 10.29, 6.11, 13.36, 11.46, 7.45, 6.08, 21.00, 4.89. `06 §3.5`: if a printed number and the test disagree, the test is right and the document is stale |
| `'the AA exception applies to standard-contrast deepRed and to nothing else'` | The floor is 7.0 for the other five. A globally relaxed suite is the failure this case exists to catch |
| `'no ColorScheme sets background, onBackground or surfaceVariant'` | Source text over `palettes.dart`, so the failure names the role rather than arriving as an analyzer info |
| `'every ColorScheme sets the nine required M3 roles and the pinned ones'` | A missing pinned role is a computed default nobody chose |

**Nothing here is time-shaped.** No `uk-zone` case, no `atFixed`, no clock. The pixel-sampling
`textContrastGuideline` group — 14 variants × 3 standard-contrast palettes on `Device.small` at
textScaler 1.0, **42 runs, tagged `slow`** — goes in this same file at N33, never in a second file
(`12 §7.6`). Leave the comment that says so.

## 6. Constraints that bind this task

- **3am** — this is the file the whole floor is measured in. `contrast_test.dart` is Indelible
  acceptance test 10 and `06`'s Definition of done in one artefact.
- **Rule 4 does not negotiate with taste.** `#6B675F` as struck ink (3.52:1) and `#A63A32` as the
  madder (3.08:1) both look better and both already lost, twice (`indelible.md` §2.4).
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan)
  stay green: `wcag.dart` is hand-written arithmetic precisely so no package has to clear the
  allowlist.
- **Colour is never the only channel** (decision #106). The status tokens exist for `ShedStatusBadge`;
  Indelible §2.7 still requires a word and a mark alongside, and a dead lamb gets no colour at all.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every text pair in all six palettes reaches 4.5 to 1 and every rule and mark 3 to 1'` passes, and was seen to fail first for the stated reason
- [ ] all six palettes present
- [ ] every pair recomputed by the test, with the failing pair named
- [ ] the red-shift palette meets the same floor as night — a red-shift exemption is how the 3am test dies
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `palettes.dart` is the **only** file that imports `primitives.dart`, and its `[exempt]` line is the one T01 added
- [ ] `ColorScheme.fromSeed` appears nowhere; every scheme is a literal constructor call
- [ ] no scheme sets `background`, `onBackground` or `surfaceVariant`, and `flutter analyze --fatal-infos` is green
- [ ] `error` is Material's error role only, and never carries `statusLoss`
- [ ] `wcag.dart` uses `Color.computeLuminance()` and imports no package beyond `dart:math` and `dart:ui`
- [ ] the night-shift luminance assertion passes **without** the 0.70 factor being relaxed; if it could not, `06 §3.5` is amended in this commit
- [ ] the PR body records which document supplied each palette's values (P6)

## 8. Verification

```bash
fvm flutter test test/design/contrast_test.dart
fvm flutter test test/design/
make check
make test
```

Prove the gate is alive rather than merely green — change one hex by one digit, watch the named pair
fail, then revert:

```bash
# temporarily edit one ink value in lib/core/ui/primitives.dart
fvm flutter test test/design/contrast_test.dart    # expect a failure naming the palette and the pair
git checkout -- lib/core/ui/primitives.dart
```

```bash
grep -rn "primitives.dart" lib/ --include='*.dart'   # expect exactly one importer: palettes.dart
grep -n "fromSeed\|surfaceVariant\|onBackground" lib/core/ui/palettes.dart   # expect zero
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): the six palettes, measured against 4.5:1 and 3:1`

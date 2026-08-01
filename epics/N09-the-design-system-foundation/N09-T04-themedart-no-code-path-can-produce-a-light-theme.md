# N09-T04 — `theme.dart` — no code path can produce a light theme

| | |
|---|---|
| **Epic** | [N09 — The design system foundation](epic.md) · `00-README` §9 step 4 (1 of 3) |
| **Task** | 4 of 9 |
| **Depends on** | N09-T03 |
| **Commit** | one commit · `feat(ui): buildShedTheme, with no light path` |

## 1. Why this task exists

`buildShedTheme` and `ShedThemeSet`, with **no** code path that can produce
`Brightness.light`. Dark-only is not a default here; it is the absence of an alternative.

A light theme that exists but is never selected is one `themeMode` away from being selected — by a
future contributor, by a system setting, or by a framework upgrade — and a white screen at 03:20 costs
a shepherd ten minutes of night vision.

The other half of this task is quieter and just as load-bearing: `buildShedTheme` is where Material's
own defaults get corrected. `MaterialTapTargetSize`, `VisualDensity` and the predictive-back gutter
colour are all wrong for this app out of the box, and each of them is wrong in a way that is invisible
on a developer's machine.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §2.1 (`ShedThemeSet`, the banned spellings, why `fromSeed` is banned) · §2.2 (**`buildShedTheme` — the defaults M3 gets wrong**) · §2.5 (the flags the theme layer reads) · §5.1 (`buildShedTextTheme`'s fifteen roles) · §9.3 (the Flutter layer of the no-white-flash recipe) | the file, both signatures, every pinned `ThemeData` field |
| `docs/design/indelible.md` | §5.1 (press is a **fill change only** — no scale, no lift, no ripple) · §5.2 (the first painted frame is `--page` with tonight's page already on it) · §9 (dark is the only default; there is no system-follow) | the press behaviour and the first-frame requirement |
| `docs/engineering/CONVENTIONS.md` | §1 (`theme.dart` holds `ShedThemeSet` · `buildShedTheme` · `buildShedTextTheme`) · §1.1 layer rule 7 · §2.11 · R34 | the path, the type names, and what this file may **not** import |
| `CLAUDE.md` | **P2 — there is no SnackBar** | why `06 §2.2`'s `snackBarTheme` block is not authored |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-design-system` | the dark-only rule, the first painted frame, and the no-ripple press |
| `shed-conventions` | the type names, layer rule 7, and which file owns `themeProvider` (not this one) |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/theme_test.dart`
- **Test** — `'no code path in buildShedTheme can produce Brightness.light'`
- **Why it is red today** — no theme exists; `MaterialApp` would fall back to its own.

```bash
fvm flutter test test/design/theme_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it covers both halves of the claim: for **every** entry in `shedPalettes`,
`buildShedTheme(p).brightness == Brightness.dark` **and**
`buildShedTheme(p).colorScheme.brightness == Brightness.dark`; then a source-text pass over `lib/`
asserting `Brightness.light`, `ThemeMode.system`, `ThemeMode.light`, `ColorScheme.light`,
`ThemeData.light` and `platformBrightnessOf` appear zero times. A theme object that is dark while a
`themeMode` can still follow the system is not dark-only.

**Green.** The minimum code that passes, and nothing beyond it — the builder, the set, and a test that constructs the theme under every palette and
asserts the brightness.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**UI and tests only.** No schema, no domain, no data, no wiring, no controller, no ARB string. Say so
in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/theme.dart` | **New.** `ShedThemeSet`, `buildShedTheme(ShedPalette)` and `buildShedTextTheme(ShedTokens)`. Imports `package:flutter/material.dart`, `tokens.dart` and `palettes.dart` — nothing else |
| 2 | `test/design/theme_test.dart` | **New.** The anchor plus the pinned-defaults cases in §5.4 |

**Not in this task, and the boundaries matter:**

- `lib/app.dart` and `ShedBookApp` are **N11-T05's** (`CONVENTIONS` R34, `01 §6.3`). `06 §2.1` prints
  the widget for context; this task owns only `theme.dart`.
- `themeProvider` is **N12's**, in `lib/data/providers.dart` (`CONVENTIONS §3.1`). It could not live
  here even if you wanted it to: layer rule 7 allows `lib/core/ui/` to import `lib/core/ui/`,
  `lib/domain/`, `package:flutter/*` and `package:intl` — and **not** `package:*riverpod/*`.
- The font asset, the `wght` axis and the P7 ruling are **T05's**. This task lands
  `buildShedTextTheme`'s *structure*; T05 lands its *face*.

### 5.2 The signatures

```dart
// lib/core/ui/theme.dart
/// The pair every palette resolves to. `highContrast` is a genuinely different
/// palette, never the same object as `theme` (decision #95).
typedef ShedThemeSet = ({ThemeData theme, ThemeData highContrast});

ThemeData buildShedTheme(ShedPalette p);
TextTheme buildShedTextTheme(ShedTokens t);
```

`buildShedTheme`'s body is `06 §2.2`, and every line in it is a correction of a Material default:

```dart
ThemeData buildShedTheme(ShedPalette p) {
  final ShedTokens t = p.tokens;
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: p.colorScheme,          // hand-authored literal, T03
    extensions: <ThemeExtension<dynamic>>[t],
    scaffoldBackgroundColor: t.surfaceBase,
    canvasColor: t.surfaceBase,

    // MaterialTapTargetSize.padded is 48, not 60. It is a floor under our
    // floor, not the rule: the 60 pt contract comes from ShedTapTarget (§6).
    materialTapTargetSize: MaterialTapTargetSize.padded,
    // adaptivePlatformDensity is negative on some platforms and silently
    // subtracts up to 4 px per axis from every Material control. Pin it.
    visualDensity: VisualDensity.standard,

    textTheme: buildShedTextTheme(t),
    filledButtonTheme: FilledButtonThemeData(style: shedPrimaryButtonStyle(t)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: shedSecondaryButtonStyle(t)),
    iconButtonTheme: IconButtonThemeData(style: shedIconButtonStyle(t)),

    // Predictive back is the default Android page transition on this SDK and
    // paints a gutter behind the outgoing page. Without fallbackColor that
    // gutter is the platform default — i.e. light.
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      TargetPlatform.android:
          PredictiveBackPageTransitionsBuilder(fallbackColor: t.surfaceBase),
      TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
    }),
  );
}
```

`ShedThemeSet` is consumed in exactly one place, `ShedBookApp.build` in N11-T05, and both brightness
slots hold the **same object** so that no `Brightness` change, no `Theme` widget in a test harness and
no platform event can select light:

```dart
theme: t.theme,
darkTheme: t.theme,
highContrastTheme: t.highContrast,
highContrastDarkTheme: t.highContrast,
themeMode: ThemeMode.dark,
color: t.theme.scaffoldBackgroundColor,
themeAnimationDuration: Duration.zero,
```

Write that block as a doc comment on `ShedThemeSet` so N11 does not have to re-derive it.

### 5.3 The details that are easy to get wrong

- **`PredictiveBackPageTransitionsBuilder` is plural — "Transitions".**
  `PredictiveBackPageTransitionBuilder` does not exist and is *"the single easiest compile error to
  make in this file"* (`06 §2.2`). It also **must** carry `fallbackColor`: predictive back is the
  default Android page transition on 3.44 and paints a gutter behind the outgoing page, and without
  the parameter that gutter is the platform default — which is light. This is a white flash that only
  appears on a real Android device, mid-navigation, and no test in this project catches it.
- **Do not author `06 §2.2`'s `snackBarTheme` block.** It configures `SnackBarThemeData` with
  `actionOverflowThreshold: 0` so that `SnackBarAction` clears the 60 pt floor. **P2 supersedes it:**
  `CLAUDE.md` records the owner ruling that *"there is no SnackBar — `showSnackBar(` is banned
  everywhere, including in `feedback.dart`"*, and N03-T05 already landed the gate row. Theming a
  widget that cannot be constructed is dead configuration that reads as permission. Say in the commit
  message that `06 §2.2`'s `snackBarTheme` was deliberately not authored, and cite P2.
- **`splashFactory` is a live conflict, and you must choose visibly.** `06 §2.2` sets
  `InkSparkle.splashFactory`; `indelible.md` §5.1 says a press is a **fill change only** — *"no scale,
  no lift, no ripple — a target that shrinks under a cold thumb is a target you miss."* `06 §1` gives
  the direction *"the visual form of a target"*, so Indelible has the stronger claim and
  `NoSplash.splashFactory` is the consistent value. Whichever you take, put the reason in the commit
  message; do not leave `InkSparkle` in place unremarked because it was in the printed snippet.
- **`buildShedTextTheme` must not be stubbed.** A `TextTheme()` that compiles and returns the M3
  defaults renders `bodyLarge` at **16.0**, below the 18 pt floor, and nothing in this epic catches
  it — the overflow matrix and the pixel-sampling contrast run are both N33. Land the full fifteen
  roles here, wired to `t.bodySize` and `t.numeralSize` per `06 §5.1`, with
  `FontFeature.tabularFigures()` on the roles §5.1 marks tabular. T05 adds `fontFamily`, the weight
  axis and the corrected 18 px exemption on top of that structure.
- **Every role goes through the helper, and no numeral gets a bare `TextStyle`.** `06 §5.4`: the
  failure is silent — *"constructing a fresh `TextStyle` instead of copying one drops `fontFeatures`,
  and the pen board starts jittering as `412` and `108` take different widths."*
- **`MaterialTapTargetSize.padded` is 48 and it is not our floor.** Pin it anyway; it is a floor under
  our floor. The 60 pt contract comes from `ShedTapTarget` (T07) and the 64 × 64 build box comes from
  `indelible.md` §4.5. Do not read `padded` as "handled".
- **`VisualDensity.adaptivePlatformDensity` is negative on some platforms** and silently subtracts up
  to 4 px per axis from every Material control. On a 60 pt floor with 4 pt of headroom that is the
  whole margin. Pin `VisualDensity.standard` and never accept the adaptive default.
- **`extensions:` takes a `List<ThemeExtension<dynamic>>` with exactly one entry.** Two entries — or a
  second extension added later "just for typography" — reintroduces the five-object shape `06 §3.3`
  rejected, and `Theme.of(context).extension<T>()` becomes a map lookup that can miss.
- **`themeAnimationDuration: Duration.zero` is not a nicety.** `06 §4.8`: a 200 ms lerp between night
  and deep red *"drags every colour through a desaturated, low-contrast midpoint."* It is also what
  makes T02's `lerp` unreachable in the app, which is the argument that made full snapping free.
- **The first painted frame's colour has a name and this task fixes it.** It is
  `nightPalette.tokens.surfaceBase`, reached three ways that must agree: `scaffoldBackgroundColor`,
  `canvasColor` and `MaterialApp.color`. The native halves — `windowBackground`,
  `windowSplashScreenBackground`, `LaunchScreen.storyboard` and `Main.storyboard` — are N11-T06 and
  N11-T07, and `launch.colour_parity` (N11-T08) is what keeps them equal.
- **`highContrast` is genuinely a different palette, never the same object as `theme`.** Decision #95;
  `06 §4.5` calls the alternative *"dead plumbing while claiming to honour the flag."* Because the
  `highContrast` flag only fires on **iOS**, the same variant is also reachable from a Settings switch
  on both platforms (N29).
- **`accessibleNavigation` is timing only — never branch the layout on it** (`06 §2.5`). And
  `BackdropFilter`, frosted bars and any translucency are banned outright: Flutter 3.44 exposes no
  reduced-transparency flag, so the only safe answer is not to ship blur.

### 5.4 The full test set

`test/design/theme_test.dart` — theme construction is pure, so most cases need no pump.

| Case | What it asserts |
|---|---|
| `'no code path in buildShedTheme can produce Brightness.light'` | **The anchor.** All six palettes, `ThemeData.brightness` and `ColorScheme.brightness`, plus the source-text sweep for the six banned spellings |
| `'every palette installs exactly one ThemeExtension and it is ShedTokens'` | `extensions` has length 1 and `theme.extension<ShedTokens>()` is non-null for all six |
| `'theme and highContrast are never the same object'` | `identical(set.theme, set.highContrast)` is false for all three palette ids (decision #95) |
| `'scaffoldBackgroundColor, canvasColor and colorScheme.surface are the same token'` | Three routes to the first painted frame, one value. A mismatch is a one-frame flash of the wrong surface |
| `'themeAnimationDuration is Duration.zero'` | Asserted on the `MaterialApp` configuration documented on `ShedThemeSet`, so the doc comment cannot drift from the code |
| `'materialTapTargetSize is padded and visualDensity is standard'` | The two silent shrink vectors, pinned |
| `'the Android page transition carries a fallbackColor equal to surfaceBase'` | The predictive-back gutter. Reach it through `pageTransitionsTheme.builders[TargetPlatform.android]` |
| `'buildShedTextTheme returns all fifteen roles and none is below 18'` | Structure only — T05 asserts the face and the axis. `bodySmall` and `labelSmall` are **collapsed into the floor**, not left at 12 and 11 |
| `'every tabular role carries FontFeature.tabularFigures'` | The roles `06 §5.1` marks tabular: `displayLarge`, `displayMedium`, `displaySmall`, `headlineLarge` |
| `'the night-shift palettes build a theme with bodySize 20 and numeralSize 44'` | The size-not-weight compensation survives theme construction |
| `'no snackBarTheme is configured'` | P2, made executable. A theme that styles a banned widget is a theme that invites it back |
| `'Brightness.light appears nowhere under lib/'` | Source text over `lib/**/*.dart`, skipping generated files |

**Nothing here is time-shaped.** No `uk-zone` case; T06 is the first task in this epic with one.

## 6. Constraints that bind this task

- **3am** — dark only, at every layer, with no alternative reachable: `themeMode` pinned,
  both brightness slots holding one object, `Brightness.light` unreachable, and the predictive-back
  gutter painted in the base surface. *"A white screen at 03:20 costs a shepherd ten minutes of night
  vision."*
- **The first painted frame is the product's promise** (`00-README` §9 step 4). This file names its
  colour; N11 makes the native layers agree.
- **Layer rule 7** — `lib/core/ui/` may import `lib/core/ui/`, `lib/domain/`, `package:flutter/*` and
  `package:intl` (in `formatters.dart` only). No riverpod, no drift, no `lib/data/`.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'no code path in buildShedTheme can produce Brightness.light'` passes, and was seen to fail first for the stated reason
- [ ] `Brightness.light` appears nowhere under `lib/`
- [ ] there is no `themeMode` that could follow the system
- [ ] the first painted frame's colour is a token, named here
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `PredictiveBackPageTransitionsBuilder` is spelled with the plural and carries `fallbackColor`
- [ ] `materialTapTargetSize: MaterialTapTargetSize.padded` and `visualDensity: VisualDensity.standard` are both pinned
- [ ] `extensions` holds exactly one entry and it is `ShedTokens`
- [ ] `buildShedTextTheme` returns all fifteen roles with nothing below 18 — no stub, no `const TextTheme()`
- [ ] **no `snackBarTheme` block is authored, and the commit message cites P2**
- [ ] the `splashFactory` decision is made explicitly and its reason is in the commit message
- [ ] `theme.dart` imports no riverpod, no drift and nothing under `lib/data/`

## 8. Verification

```bash
fvm flutter test test/design/theme_test.dart
fvm flutter test test/design/
make check
make test
```

```bash
grep -rn "Brightness.light\|ThemeMode.system\|ThemeMode.light\|ColorScheme.light\|ThemeData.light\|platformBrightnessOf" lib/ --include='*.dart'
# expect zero hits

grep -n "PredictiveBackPageTransition" lib/core/ui/theme.dart      # expect the plural, with fallbackColor
grep -n "snackBar\|SnackBar" lib/core/ui/theme.dart                 # expect zero — P2
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): buildShedTheme, with no light path`

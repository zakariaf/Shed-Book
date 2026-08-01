# 05 — Design system, theming, and the 3am interaction model

**Project:** Shed Book (offline-only lambing notebook, iOS + Android)
**Toolchain researched against:** Flutter 3.44.6 stable / Dart 3.12.2 / Xcode 26.6 / macOS arm64
**Research date:** 2026-07-27
**Spec authority:** `/Users/zakariafatahi/50-apps-challenge/E01/shed-book-spec.md` — §5 (the 3am test), §7.1, §7.4, §9, §12

> Every version number, API name and constant in this document was fetched from a primary
> source on 2026-07-27. Nothing here is recalled from memory. Where I could not verify
> something I say so explicitly.

---

## Bottom line

| # | Decision | Confidence | Why (one line) |
|---|---|---|---|
| 1 | **Hand-author the `ColorScheme`. Do not use `ColorScheme.fromSeed`.** | High | The seed algorithm is not a stable contract — Flutter 3.41 changed four `on*Container` colours out from under apps ([breaking change](https://docs.flutter.dev/release/breaking-changes/material-color-utilities)). Legibility here is a safety property, not a brand property. |
| 2 | **Three themes, all dark.** `night` (default), `redShift`, `daylight`. `themeMode` pinned to `ThemeMode.dark`; `theme` and `darkTheme` both set to the same resolved object. | High | System light appearance can then never leak in, at any point, on any platform. |
| 3 | **Base surface `#0B0D0E`, not `#000000` and not `#121212`.** Pure black reserved for the red-shift scrim only. | Medium | OLED near-black keeps the power/contrast win but avoids black-smear and halation; #0B0D0E vs #E8EAED = **16.16:1**. Both #000 and #121212 have real evidence behind them; see §2.3. |
| 4 | **Two-tier design tokens (primitive → semantic) via a single `ThemeExtension`.** Raw `Color(0x…)`, `Colors.*` and magic sizes in widgets are build-breaking defects. | High | It is the only way one widget tree can serve three palettes including red-shift. |
| 5 | **CI gate = a plain Dart script in `tool/`, not `custom_lint`.** | High | `invertase/dart_custom_lint` was **archived 2026-03-24**; latest publish 0.8.1 (2025-09-09) pins `analyzer ^8.0.0` while analyzer 14.1.0 is current. A zero-dependency script cannot rot. |
| 6 | **Red-shift = a third hand-authored `ColorScheme` + semantic token set. NOT a global `ColorFiltered`.** Photos get a *local* `ColorFiltered` only. | High | `ColorFilter` triggers `saveLayer` — Flutter explicitly names it as expensive ([perf best practices](https://docs.flutter.dev/perf/best-practices)); a global filter also destroys per-token contrast control. |
| 7 | **Red-shift must also drop luminance, not just hue.** | Medium-High | Naval/aviation research: at low instrument-lighting levels the red-vs-white advantage largely disappears — *intensity matters more than colour*. Baking dimness into the palette is the real win. |
| 8 | **No white flash: configure it manually at 4 layers. Skip `flutter_native_splash`.** | Medium-High | Flutter already holds the Android launch screen until the first frame ([migration doc](https://docs.flutter.dev/release/breaking-changes/splash-screen-migration)); the whole job is ~25 lines of XML/plist. The package's maintainer [publicly asked for a new owner](https://github.com/jonbhanson/flutter_native_splash/issues/821) in March 2026. |
| 9 | **Tap targets: 60pt floor, 72–88pt for the five primary 3am actions, 16pt minimum gap.** | High | 60pt ≈ **9.5 mm**, which is exactly Parhi et al.'s 9.2/9.6 mm optimum for a *bare* thumb in ideal conditions. Gloves + cold are worse than ideal, so primary actions go bigger. |
| 10 | **No volume-button shortcuts.** Spec open question 4 is answered: no. | High | App Store Review Guideline **2.5.9** rejects apps that "alter or disable the functions of standard switches, such as the Volume Up/Down". Android permits it; a shortcut that exists on one platform only is worse than none. |
| 11 | **Bundle Atkinson Hyperlegible Next (SIL OFL 1.1). Never add `google_fonts`.** | High | `google_fonts` 8.2.0 depends on `http` and fetches over the network at runtime — a network path in an app that ships with no INTERNET permission. AH Next's variable file is **114 KB** and I verified by byte-inspecting the TTF that it ships the `tnum` feature. |
| 12 | **Body text 18pt minimum → override the whole M3 `TextTheme`.** M3 `bodyLarge` is 16.0. | High | Verified from `typography.dart` on the stable branch. |
| 13 | **Never clamp `textScaler`.** Design the pen board to survive 200%. | High | Android 14+ scales to 200% non-linearly; clamping defeats the system's own curve ([Flutter migration doc](https://docs.flutter.dev/release/breaking-changes/android-14-nonlinear-text-scaling-migration)). |
| 14 | **Custom in-app numeric keypad, not the system keyboard.** | High | The system keypad's key size is fixed by the OS, is unreachable one-handed at the top row, and cannot be made 72pt. |
| 15 | **"Saved" proof = commit-then-confirm, with three redundant channels** (haptic + persistent snackbar with Undo + list mutation). | High | `HapticFeedback` is real on both platforms but silently degrades; it can never be the only proof. |

---

## 0. What the 3am test actually demands of the UI layer

Restating §5 as engineering constraints, because everything below is judged against these:

| Spec clause | Engineering constraint |
|---|---|
| "One thumb, one hand" | Every primary action inside the bottom ~45% of the screen. No top-right save. |
| "Gloves, wet hands, or a phone in a bag. Minimum tap target 60×60 pt" | 60pt floor enforced by widget + test; ban on swipe/drag/long-press-only/pinch/force-touch. |
| "Cold fingers. Poor capacitance" | Bigger targets *and* generous inter-target gaps; no thin sliders; no precision gestures. |
| "Head torch or darkness. Dark default. No white flash. Optional red-shift. Min 18pt body" | Dark-only theming at every layer including native launch; a real third palette. |
| "Under fifteen seconds from unlock" | No splash animation, no async gate before first paint beyond a synchronous settings read. |
| "Zero interruptions" | No rating prompt, no what's-new, no theme-change animation that blocks input. |
| "Assume the phone dies. Every write commits immediately" | The UI must not show success before the DB transaction returns. No optimistic UI. |

And from §12: **timestamps must be honest**, **never silently correct**, **never look like a regulatory record**. Those are UI obligations as much as data obligations — see §12 of this doc.

---

## 1. Material 3 in Flutter 3.44 — the actual current state

### 1.1 What is true today

- `ThemeData.useMaterial3` **defaults to `true`** and has since Flutter 3.16 ([docs](https://docs.flutter.dev/release/breaking-changes/material-3-default)). There is no flag to set. M2 is legacy.
- `ColorScheme` now carries the full M3 role set (~45 colours): the accent families with `*Container`/`*Fixed`/`*FixedDim`, plus the surface ramp `surfaceDim`, `surfaceBright`, `surfaceContainerLowest/Low/‑/High/Highest`, plus `outline`, `outlineVariant`, `shadow`, `scrim`, `inverseSurface`, `inversePrimary` ([API](https://api.flutter.dev/flutter/material/ColorScheme-class.html)).
- **Deprecated `ColorScheme` members you must not use:** `background` → `surface`; `onBackground` → `onSurface`; `surfaceVariant` → `surfaceContainerHighest`.
- `MaterialStateProperty` has been superseded by **`WidgetStateProperty`** in the `widgets` library ([API](https://api.flutter.dev/flutter/widgets/WidgetStateProperty-class.html)). Write `WidgetStateProperty` / `WidgetState` in new code.
- `ColorScheme.fromSeed` signature: `seedColor` (required), `brightness` (default light), `dynamicSchemeVariant` (default `tonalSpot`), `contrastLevel` (default 0.0).

### 1.2 What changed recently — verified against the breaking-change list

| Release | Change | Relevance to Shed Book |
|---|---|---|
| 3.41 | **[Material 3 tokens update](https://docs.flutter.dev/release/breaking-changes/material-color-utilities)** — `material_color_utilities` 0.11.1 → 0.13.0 changed `onPrimaryContainer`, `onSecondaryContainer`, `onTertiaryContainer`, `onErrorContainer` for every scheme produced by `fromSeed` / `fromImageProvider`. | **Decisive.** This is the argument against `fromSeed` (§1.3). |
| 3.41 | **[`FontWeight` now drives the `wght` axis of variable fonts](https://docs.flutter.dev/release/breaking-changes/font-weight-variation)**. `FontWeight` accepts any integer 1–1000; `FontWeight.index` deprecated in favour of `FontWeight.value`. | Lets us ship **one** variable font file and drive weight with plain `FontWeight`. No `FontVariation` boilerplate. |
| 3.38 | **[SnackBar with an action no longer auto-dismisses](https://docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update)**. New `SnackBar.persist` (`null` = new behaviour, `true` = never, `false` = old behaviour). | Directly useful: an "Saved. Undo" snackbar now *stays* until acknowledged. Exactly right at 3am. |
| 3.38 | **[UISceneDelegate adoption](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate)** — `UIApplicationSceneManifest` in Info.plist, `FlutterSceneDelegate`, plugin registration moves to `didInitializeImplicitFlutterEngine`. CLI auto-migrates from 3.41. | Touches the iOS launch path. Verify `flutter build ios` prints `Finished migration to UIScene lifecycle` and that `UILaunchStoryboardName` still resolves. |
| 3.38 | **[Predictive back is the default Android page transition](https://docs.flutter.dev/release/breaking-changes/default-android-page-transition)**. | 3.44 added `fallbackColor` for the predictive-back transition builders (PR 182690) — set it to the dark surface or you get a light gutter behind the sliding page. |
| 3.44 | `ThemeMode` gained `isDark` / `isLight` / `isSystem` getters (PR 181475). | Cosmetic. |
| 3.44 | `RoundedSuperellipseInputBorder` added (PR 177220); `MenuAnchor` animations; `IconData` marked `final`. | `IconData` being final matters if you were subclassing it for a custom icon font — don't. |
| 3.44 | P3→sRGB conversion fixed to operate in linear light (PR 181720). | Wide-gamut displays will render your authored hexes slightly differently than on 3.41. Re-check the palette on device after upgrading. |

### 1.3 Contrarian call: **do not use `ColorScheme.fromSeed`**

The community default is `ColorScheme.fromSeed(seedColor: …, brightness: Brightness.dark)`. For Shed Book that is wrong, and the evidence is Flutter's own breaking-change page:

> "Flutter 3.41 updated `package:material_color_utilities` from v0.11.1 to v0.13.0… The algorithm changes impact these four `ColorScheme` properties: `onPrimaryContainer`, `onSecondaryContainer`, `onTertiaryContainer`, `onErrorContainer`."
> — [Material 3 tokens update](https://docs.flutter.dev/release/breaking-changes/material-color-utilities)

Three consequences:

1. **The seed algorithm is not a stable contract.** A minor SDK bump silently changed foreground colours. In a normal app that is a cosmetic surprise. In an app whose legibility target is "readable under a head torch by a cold, tired person", it is a regression in a safety property that no test would have caught.
2. **Tonal-palette generation optimises for harmony, not for measured contrast.** You cannot ask `fromSeed` for "≥ 12:1 on the base surface". You can only ask for a hue and hope. `contrastLevel` (−1.0…1.0) nudges it but does not let you *specify* a ratio.
3. **The red-shift palette is not a tonal palette at all.** It is a deliberately near-monochrome long-wavelength ramp. `fromSeed(seedColor: Colors.red)` produces a *Material* red scheme with blue-ish neutrals and a full surface ramp — precisely the thing we are trying to avoid emitting.

**Therefore:** author all three `ColorScheme`s as literal constructor calls, with the measured WCAG ratio recorded as a comment next to each pair, and a unit test that recomputes those ratios so a paste error can't ship. `fromSeed` is a fine tool for a brand-driven consumer app. It is the wrong tool when contrast is a requirement rather than an outcome.

### 1.4 Material 3 Expressive: not available, and don't wait for it

Flutter's own umbrella issue [flutter/flutter#168813](https://github.com/flutter/flutter/issues/168813) says (14 May 2025):

> "We are not actively developing Material 3 Expressive, and we will not be accepting contributions for Expressive features or updates at this time."

And as of 29 July 2025 the material/cupertino libraries are being **decoupled into standalone packages** so design-system work can ship off the SDK cadence (tracked in flutter/packages; the 3.44 announcement mentions the decoupling). Practical read for Shed Book:

- Do not adopt any third-party "M3 Expressive" package. It is a network-free app with a 12-screen surface; the value of expressive shapes and spring motion here is zero, and the maintenance risk is real.
- Do expect `package:material` to eventually move out of the SDK. Keep Material usage shallow and token-driven so that migration is mechanical. **This is another argument for the `ThemeExtension` token layer**: if `ColorScheme` becomes a package type, our widgets read `ShedTokens`, not `ColorScheme`.

---

## 2. Dark-first theming

### 2.1 Making dark the *primary* theme, not the fallback

The bug everyone ships: `MaterialApp(theme: light, darkTheme: dark, themeMode: ThemeMode.system)`. On a phone in light mode, at 3am, that is a flashbang.

`MaterialApp.themeMode: ThemeMode.dark` selects `darkTheme` if non-null, else falls back to `theme`. The bulletproof form sets **both** slots to the same object, so there is no code path — including a `Theme` widget higher in a test harness, or a platform brightness change mid-session — that can produce a light frame:

```dart
// lib/app/shed_app.dart
class ShedApp extends StatelessWidget {
  const ShedApp({super.key, required this.palette});

  /// Resolved synchronously before runApp(). See §5.4.
  final ShedPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = buildShedTheme(palette);
    return MaterialApp(
      title: 'Shed Book',
      // Both slots, same object: system Brightness can never select a light theme.
      theme: theme,
      darkTheme: theme,
      highContrastTheme: theme,
      highContrastDarkTheme: theme,
      themeMode: ThemeMode.dark,
      // Painted behind the app before/while the first route builds.
      color: palette.surfaceBase,
      builder: (context, child) => _ShedMediaOverrides(child: child!),
      home: const QuickEntryScreen(),
    );
  }
}
```

Note `highContrastTheme` / `highContrastDarkTheme`: on iOS, `MediaQueryData.highContrast` reflects the *Increase Contrast* accessibility setting, and `MaterialApp` will swap to those slots when it is on. Leaving them null means a user with Increase Contrast enabled gets… `theme`, which is fine here because everything is the same object. Setting them explicitly makes that intentional rather than accidental. (Better still: honour `highContrast` by selecting a higher-contrast *palette* — see §2.5.)

### 2.2 Should a light theme exist at all?

Spec §5 says dark is "the default, not an option" and §7.10 lists "Dark / red-shift theme" in settings. It does not mandate a light theme, and the shepherd's canonical context is a dark shed.

**Recommendation: ship three palettes, none of them a system light theme.**

| Palette | When | Base surface | Character |
|---|---|---|---|
| `night` (default) | the shed, indoors, any time | `#0B0D0E` | Near-black, cool neutrals, high contrast |
| `redShift` | deep night, preserving dark adaptation | `#000000` | Long-wavelength only, deliberately dim |
| `daylight` | outdoors in sun — reading the pen board or a ewe card in a bright June yard | `#101418` still dark, but **maximum** foreground luminance and heaviest weights | A *high-legibility-in-glare* theme, not a light theme |

The reason `daylight` is still dark: an OLED panel outdoors is fighting ambient light with emitted light either way, and a light-background theme forces the panel to its power ceiling for the whole screen. What actually helps in glare is **maximum foreground contrast and heavier glyph weight**, which a dark theme delivers at a fraction of the power. This is a judgement call, not a cited fact — flag it for the field trial in spec §17 Q1.

**What we explicitly do not build:** a Material light theme, or `ThemeMode.system`. There is no state in which "the OS thinks it's daytime" should change this app's appearance.

### 2.3 Pure black vs near-black — the honest version

This is genuinely contested. Both sides have evidence.

**For `#000000`:**
- On OLED, a black pixel is an *off* pixel. Zero emission means zero light reaching the shepherd's dark-adapted eye from those regions — which is the actual goal at 3am, more than any contrast number.
- Maximum possible contrast ratio: white on black = **21:1** (computed with the [WCAG relative luminance formula](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum)).
- Google's own dark-theme guidance acknowledges the power argument: pure black "allows system apps to use as little power as possible on OLED displays."

**Against `#000000`:**
- Google Material's dark-theme guidance recommends **`#121212`** as the standard dark surface, on two grounds: complex content against pure black produces contrast "much higher, which can increase eye strain", and elevation/shadow is not expressible against `#000` (there is nothing darker to cast onto). Components are then built as semi-transparent overlays on `#121212`, opacity rising with elevation.
- **Black smear** on OLED: pixels transitioning out of the fully-off state have a slower response, producing a visible trailing smear during scrolling. This is well-attested in display-enthusiast and design literature but I did **not** find a peer-reviewed or vendor-primary source quantifying it — treat as *plausible, unverified*.
- **Halation**: high-luminance glyphs on a zero-luminance field bloom, and for the substantial fraction of the population with uncorrected astigmatism the glyph edges ghost. Again, widely reported in design literature; I did not find a primary clinical citation. *Plausible, unverified.*
- **WCAG 2.x contrast maths is unreliable near black.** This one *is* well sourced. From the APCA documentation:
  > "WCAG 2.x overstates contrast for dark colors to the point that 4.5:1 can be functionally unreadable when one of the colors in a pair is near black… WCAG 2.x contrast cannot be used for guidance designing 'dark mode'."
  > — [APCA in a Nutshell](https://git.apcacontrast.com/documentation/APCA_in_a_Nutshell.html)

  WCAG 2's ratio is polarity-blind: `#FFF` on `#000` and `#000` on `#FFF` both compute to 21:1, but human vision is not symmetric. APCA (destined for WCAG 3) uses `Lc`, where **Lc 90** is preferred for body text (18px/w300 or 14px/w400) and **Lc 75** is the *minimum* for body columns.

**Decision:** base surface **`#0B0D0E`** for `night`.

- It is 4.9% luminance-above-zero — visually indistinguishable from black in a dark shed, so the emission argument is essentially preserved.
- It gives a surface ramp to work with (`#0B0D0E` → `#12161A` → `#1A2025` → `#242B31`) so cards, the pen board grid and the keypad can be separated by *surface*, not by outlines.
- Measured: `#E8EAED` on `#0B0D0E` = **16.16:1** (vs 17.42:1 on pure black). We give up 7% of a number that the APCA authors say is not meaningful in this range anyway, and buy an elevation system.
- Pure `#000000` is used deliberately in exactly one place: the `redShift` base surface, where minimising total emission genuinely is the objective and there is no complex content to contrast against (§4).

**Measured ratios for the proposed `night` palette** (computed with the WCAG formula, `L = 0.2126R + 0.7152G + 0.0722B` after sRGB linearisation, ratio `(L1+0.05)/(L2+0.05)`):

| Pair | Ratio | Verdict |
|---|---|---|
| `#E8EAED` on `#0B0D0E` (body) | **16.16:1** | AAA (7:1) with huge margin |
| `#FFFFFF` on `#0B0D0E` (numerals, keypad) | **19.48:1** | max practical |
| `#B7BDC4` on `#0B0D0E` (secondary) | **10.29:1** | AAA |
| `#8A9199` on `#0B0D0E` (tertiary / hint) | **6.11:1** | AA only — **use for non-essential text only** |
| `#7DD3A0` on `#0B0D0E` (success / "ready to turn out") | **10.85:1** | AAA |
| `#FFD54F` on `#0B0D0E` (warning / withdrawal active) | **13.80:1** | AAA |
| `#FFB4AB` on `#0B0D0E` (error / loss) | **11.47:1** | AAA |

Deliberately no colour below ~10:1 carries meaning. `#8A9199` is the *only* sub-AAA token and it must never be used for a value the shepherd needs to read — only for chrome like "tap to add a note".

### 2.4 A dark theme does not mean a dark `ThemeData` with no work

`ThemeData(brightness: Brightness.dark, colorScheme: …)` still leaves a dozen defaults that fight the 3am test. Set these explicitly:

```dart
ThemeData buildShedTheme(ShedPalette p) {
  final scheme = p.colorScheme;               // hand-authored, see §1.3
  final tokens = p.tokens;                    // ThemeExtension, see §3

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: tokens.surfaceBase,
    canvasColor: tokens.surfaceBase,

    // Cold thumbs: never shrink a tap target below 48 even before our own 60 floor.
    materialTapTargetSize: MaterialTapTargetSize.padded,
    // VisualDensity.compact would silently subtract up to 4px per axis. Never here.
    visualDensity: VisualDensity.standard,

    // Splash/ripple is our only "you hit it" signal when the screen is wet.
    splashFactory: InkSparkle.splashFactory,

    textTheme: buildShedTextTheme(tokens),    // §8
    extensions: <ThemeExtension<dynamic>>[tokens],

    filledButtonTheme: FilledButtonThemeData(style: shedPrimaryButtonStyle(tokens)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: shedSecondaryButtonStyle(tokens)),
    iconButtonTheme: IconButtonThemeData(style: shedIconButtonStyle(tokens)),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: tokens.surfaceRaised,
      contentTextStyle: TextStyle(fontSize: 20, color: tokens.textPrimary),
      // 3.38+: an action-bearing SnackBar already persists; be explicit.
      // insetPadding must clear the bottom action bar — see §11.
      insetPadding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
    ),

    // Predictive back (default on Android since 3.38) paints a gutter behind the
    // outgoing page. Without this it is the platform default — i.e. light.
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      TargetPlatform.android: PredictiveBackPageTransitionBuilder(
        fallbackColor: tokens.surfaceBase,   // added in 3.44, PR 182690
      ),
      TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
    }),
  );
}
```

`VisualDensity.standard` is not the framework default on desktop-class devices — `VisualDensity.adaptivePlatformDensity` is what `flutter create` templates often use, and on some platforms it is negative, shrinking every Material control. Pin it.

### 2.5 Honouring accessibility flags that actually matter here

`MediaQueryData` exposes ([API](https://api.flutter.dev/flutter/widgets/MediaQueryData-class.html)):

| Flag | Platform | What Shed Book does |
|---|---|---|
| `boldText` | iOS + Android | Add +100 to every weight token. Free legibility win under a head torch. |
| `highContrast` | iOS ("Increase Contrast") | Swap to a max-contrast variant of the active palette (white-on-black foregrounds, thicker outlines). |
| `disableAnimations` | iOS + Android | Set all durations to `Duration.zero`. Also the correct default for the theme *switch* — see Pitfall P7. |
| `invertColors` | iOS ("Classic Invert") | **Do not fight it**, but wrap photographs in `ExcludeSemantics`-adjacent handling; Smart Invert already excludes images system-side. |
| `accessibleNavigation` | both | VoiceOver/TalkBack active → keep the SnackBar persistent, never auto-advance focus. |
| `textScaler` | both | Never clamp. §8. |

```dart
class _ShedMediaOverrides extends StatelessWidget {
  const _ShedMediaOverrides({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      // Floor the text scale at 1.0 (never shrink) but NEVER cap it.
      data: mq.copyWith(
        textScaler: _AtLeast(mq.textScaler, 1.0),
      ),
      child: child,
    );
  }
}

/// Raises the scale to at least [min] without ever capping it.
/// Preserves the platform's non-linear curve above 1.0.
class _AtLeast extends TextScaler {
  const _AtLeast(this._inner, this._min);
  final TextScaler _inner;
  final double _min;

  @override
  double scale(double fontSize) =>
      math.max(_inner.scale(fontSize), fontSize * _min);

  @override
  double get textScaleFactor => math.max(_inner.textScaleFactor, _min);
}
```

Flooring is safe and useful (a shepherd who set 85% text on a big phone still gets 18pt body). Capping is not — see §8.2.

**How this serves the 3am test:** every one of these flags is set by a user who has already told the OS "I cannot read the default". Ignoring them is the single most common way an app that looks great in the simulator fails on a real person's phone in a dark barn.

---

## 3. Design tokens in Flutter

### 3.1 Why a raw colour literal in a widget is a defect, not a style issue

Shed Book has **three palettes over one widget tree**. Any widget that writes `Color(0xFF1E88E5)` or `Colors.blue` or `const TextStyle(fontSize: 14)` is a widget that:

1. cannot render in red-shift mode (it will emit blue light in the middle of a red-shift screen — a functional failure, not a cosmetic one);
2. cannot honour `highContrast`;
3. cannot be audited — you cannot prove the app's contrast floor if colours are scattered across 40 files;
4. cannot survive the eventual `package:material` decoupling (§1.4).

Treat it exactly like a hard-coded SQL string: a review-blocking defect with a CI gate.

### 3.2 Two tiers: primitives are private, semantics are public

```
lib/design/
  primitives.dart      // private. Raw hexes and a raw spacing scale. Never imported by widgets.
  tokens.dart          // ShedTokens extends ThemeExtension<ShedTokens>. The only public surface.
  palettes.dart        // night / redShift / daylight -> (ColorScheme, ShedTokens)
  theme.dart           // buildShedTheme()
  components/          // ShedPrimaryButton, ShedKeypad, PenTile … all read ShedTokens only.
```

**Tier 1 — primitives.** Value-named, meaning-free, `library`-private so the analyzer itself enforces the boundary.

```dart
// lib/design/primitives.dart
// PRIVATE. Nothing outside lib/design/ may import this file.
// Every hex below is annotated with its measured WCAG ratio on the surface it
// is designed for; theme_contrast_test.dart recomputes these.
library shed.design.primitives;

// ---- neutral ramp (night) -------------------------------------------------
const nNeutral00 = Color(0xFF000000);
const nNeutral04 = Color(0xFF0B0D0E); // base surface,   16.16:1 vs nNeutral92
const nNeutral08 = Color(0xFF12161A); // raised
const nNeutral12 = Color(0xFF1A2025); // pressed / selected
const nNeutral18 = Color(0xFF242B31); // outline-ish fill
const nNeutral40 = Color(0xFF8A9199); //  6.11:1 — chrome only, never data
const nNeutral72 = Color(0xFFB7BDC4); // 10.29:1
const nNeutral92 = Color(0xFFE8EAED); // 16.16:1
const nNeutral100 = Color(0xFFFFFFFF); // 19.48:1 — numerals

// ---- semantic accents (night) ---------------------------------------------
const nGreen70  = Color(0xFF7DD3A0); // 10.85:1
const nAmber70  = Color(0xFFFFD54F); // 13.80:1
const nSalmon80 = Color(0xFFFFB4AB); // 11.47:1

// ---- long-wavelength ramp (red-shift) -------------------------------------
// Note the ceiling: the brightest usable red on black is ~6:1. See §4.3.
const rRed100 = Color(0xFFFF6B4A); //  7.36:1 on rSurface — reserved for numerals
const rRed80  = Color(0xFFFF4400); //  6.08:1 — primary text
const rRed60  = Color(0xFFE62200); //  4.59:1 — secondary, AA only
const rRed20  = Color(0xFF4D0D00); //  1.37:1 — fills/outlines, never text
const rSurface = Color(0xFF000000);

// ---- spacing / size scale (logical pixels) --------------------------------
const s04 = 4.0;
const s08 = 8.0;
const s16 = 16.0;
const s24 = 24.0;
const s32 = 32.0;

// ---- tap target scale ------------------------------------------------------
const tapMin      = 60.0; // spec §5 floor  (≈ 9.5 mm)
const tapPrimary  = 72.0; // one-thumb primary actions (≈ 11.4 mm)
const tapHero     = 88.0; // the five 3am actions (≈ 14.0 mm)
```

**Tier 2 — semantics.** A single `ThemeExtension`. One extension, not five: `Theme.of(context).extension<T>()` is a map lookup per call, and one flat object is far easier to diff, lerp and test than a graph.

```dart
// lib/design/tokens.dart
import 'package:flutter/material.dart';

@immutable
class ShedTokens extends ThemeExtension<ShedTokens> {
  const ShedTokens({
    // surfaces
    required this.surfaceBase,
    required this.surfaceRaised,
    required this.surfacePressed,
    required this.surfaceFill,
    // text
    required this.textNumeric,
    required this.textPrimary,
    required this.textSecondary,
    required this.textChrome,
    // status (always paired with a shape/label — see §12)
    required this.statusReady,
    required this.statusAttention,
    required this.statusLoss,
    required this.onStatus,
    // metrics
    required this.tapMin,
    required this.tapPrimary,
    required this.tapHero,
    required this.gapMin,
    required this.bodySize,
    required this.numeralSize,
    // weight bump driven by MediaQuery.boldText
    required this.weightBump,
    required this.motion,
  });

  final Color surfaceBase, surfaceRaised, surfacePressed, surfaceFill;
  final Color textNumeric, textPrimary, textSecondary, textChrome;
  final Color statusReady, statusAttention, statusLoss, onStatus;
  final double tapMin, tapPrimary, tapHero, gapMin, bodySize, numeralSize;
  final int weightBump;          // 0 or 100
  final Duration motion;         // Duration.zero when disableAnimations

  @override
  ShedTokens copyWith({
    Color? surfaceBase, Color? surfaceRaised, Color? surfacePressed,
    Color? surfaceFill, Color? textNumeric, Color? textPrimary,
    Color? textSecondary, Color? textChrome, Color? statusReady,
    Color? statusAttention, Color? statusLoss, Color? onStatus,
    double? tapMin, double? tapPrimary, double? tapHero, double? gapMin,
    double? bodySize, double? numeralSize, int? weightBump, Duration? motion,
  }) {
    return ShedTokens(
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfacePressed: surfacePressed ?? this.surfacePressed,
      surfaceFill: surfaceFill ?? this.surfaceFill,
      textNumeric: textNumeric ?? this.textNumeric,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textChrome: textChrome ?? this.textChrome,
      statusReady: statusReady ?? this.statusReady,
      statusAttention: statusAttention ?? this.statusAttention,
      statusLoss: statusLoss ?? this.statusLoss,
      onStatus: onStatus ?? this.onStatus,
      tapMin: tapMin ?? this.tapMin,
      tapPrimary: tapPrimary ?? this.tapPrimary,
      tapHero: tapHero ?? this.tapHero,
      gapMin: gapMin ?? this.gapMin,
      bodySize: bodySize ?? this.bodySize,
      numeralSize: numeralSize ?? this.numeralSize,
      weightBump: weightBump ?? this.weightBump,
      motion: motion ?? this.motion,
    );
  }

  // Signature per api.flutter.dev: ThemeExtension<T> lerp(covariant ThemeExtension<T>? other, double t)
  @override
  ShedTokens lerp(covariant ShedTokens? other, double t) {
    if (other == null) return this;
    return ShedTokens(
      surfaceBase: Color.lerp(surfaceBase, other.surfaceBase, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfacePressed: Color.lerp(surfacePressed, other.surfacePressed, t)!,
      surfaceFill: Color.lerp(surfaceFill, other.surfaceFill, t)!,
      textNumeric: Color.lerp(textNumeric, other.textNumeric, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textChrome: Color.lerp(textChrome, other.textChrome, t)!,
      statusReady: Color.lerp(statusReady, other.statusReady, t)!,
      statusAttention: Color.lerp(statusAttention, other.statusAttention, t)!,
      statusLoss: Color.lerp(statusLoss, other.statusLoss, t)!,
      onStatus: Color.lerp(onStatus, other.onStatus, t)!,
      // Metrics do NOT interpolate. A tap target that is 63.4pt mid-animation
      // is a tap target that fails the 60pt contract for 150ms.
      tapMin: t < 0.5 ? tapMin : other.tapMin,
      tapPrimary: t < 0.5 ? tapPrimary : other.tapPrimary,
      tapHero: t < 0.5 ? tapHero : other.tapHero,
      gapMin: t < 0.5 ? gapMin : other.gapMin,
      bodySize: t < 0.5 ? bodySize : other.bodySize,
      numeralSize: t < 0.5 ? numeralSize : other.numeralSize,
      weightBump: t < 0.5 ? weightBump : other.weightBump,
      motion: t < 0.5 ? motion : other.motion,
    );
  }
}

/// The ONLY way a widget gets a colour or a size.
extension ShedTokensX on BuildContext {
  ShedTokens get tokens => Theme.of(this).extension<ShedTokens>()!;
}
```

Usage in a widget is then unambiguous and greppable:

```dart
@override
Widget build(BuildContext context) {
  final t = context.tokens;
  return Container(
    constraints: BoxConstraints(minWidth: t.tapHero, minHeight: t.tapHero),
    color: t.surfaceRaised,
    child: Text('412', style: TextStyle(color: t.textNumeric, fontSize: t.numeralSize)),
  );
}
```

### 3.3 The CI gate — and why it is a script, not `custom_lint`

The popular answer is `custom_lint`. I checked it and it is the wrong answer here:

- `custom_lint` latest is **0.8.1, published 2025-09-09**, publisher invertase.io ([pub.dev](https://pub.dev/packages/custom_lint)).
- The upstream repo **`invertase/dart_custom_lint` is archived — `archived: true`, last push 2026-03-24** (GitHub API).
- 0.8.1's changelog entry is literally "Support analyzer 8.0.0", and it depends on `analyzer ^8.0.0`. **`analyzer` is at 14.1.0 (2026-07-13).** There is an open request ([#379](https://github.com/invertase/dart_custom_lint/issues/379), Jan 2026) to bump it, in an archived repo.

Adding an archived analyzer plugin, pinned to an analyzer six major versions behind, to a project that must still build in 2031, is a bad trade for a rule you can express in 40 lines.

**Recommended gate:** `tool/check_tokens.dart`, run by `dart run tool/check_tokens.dart` in CI and in a pre-commit hook. Zero dependencies beyond the SDK.

```dart
// tool/check_tokens.dart
// Fails the build if a widget file hard-codes a colour or a size.
// Run: dart run tool/check_tokens.dart
import 'dart:io';

/// Files allowed to contain raw values.
const _allowlist = <String>{
  'lib/design/primitives.dart',
  'lib/design/palettes.dart',
};

final _rules = <({RegExp re, String message})>[
  (re: RegExp(r'Color\(0x'),          message: 'raw Color(0x…) literal'),
  (re: RegExp(r'\bColors\.'),         message: 'Material Colors.* palette'),
  (re: RegExp(r'\bColor\.fromARGB'),  message: 'Color.fromARGB literal'),
  (re: RegExp(r'\bColorScheme\.fromSeed'), message: 'ColorScheme.fromSeed (see docs/research 05 §1.3)'),
  (re: RegExp(r'fontSize:\s*\d'),     message: 'literal fontSize (use tokens)'),
  (re: RegExp(r'\bGoogleFonts\b'),    message: 'google_fonts is a network path'),
  (re: RegExp(r'onLongPress:'),       message: 'long-press action (spec §5 bans long-press-only)'),
  (re: RegExp(r'\bDismissible\b'),    message: 'swipe-to-dismiss (spec §5)'),
  (re: RegExp(r'\bDraggable\b'),      message: 'drag (spec §5)'),
  (re: RegExp(r'onScaleUpdate:'),     message: 'pinch (spec §5)'),
];

void main() {
  final failures = <String>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final rel = entity.path.replaceAll(r'\', '/');
    if (_allowlist.contains(rel)) continue;
    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trimLeft().startsWith('//')) continue;
      if (line.contains('// design-ok:')) continue; // explicit, reviewed escape hatch
      for (final rule in _rules) {
        if (rule.re.hasMatch(line)) {
          failures.add('$rel:${i + 1}  ${rule.message}\n    ${line.trim()}');
        }
      }
    }
  }
  if (failures.isEmpty) {
    stdout.writeln('design tokens: OK');
    return;
  }
  stderr.writeln('design token violations (${failures.length}):\n');
  failures.forEach(stderr.writeln);
  exit(1);
}
```

Two things make this good enough despite being regex-based:

- It runs on **our** code, which we control and keep stylistically uniform. It is not trying to parse arbitrary Dart.
- The `// design-ok:` escape hatch means false positives cost one comment and leave an audit trail, rather than causing someone to delete the check.

Pair it with a **semantic** test that the regex cannot express:

```dart
// test/design/contrast_test.dart
void main() {
  for (final palette in <ShedPalette>[nightPalette, redShiftPalette, daylightPalette]) {
    group(palette.name, () {
      final t = palette.tokens;
      test('numerals meet AAA on base surface', () {
        expect(contrastRatio(t.textNumeric, t.surfaceBase), greaterThanOrEqualTo(7.0));
      });
      test('primary text meets AAA on base and raised surfaces', () {
        expect(contrastRatio(t.textPrimary, t.surfaceBase), greaterThanOrEqualTo(7.0));
        expect(contrastRatio(t.textPrimary, t.surfaceRaised), greaterThanOrEqualTo(7.0));
      });
      test('every status colour meets AA-large against its own surface', () {
        for (final c in [t.statusReady, t.statusAttention, t.statusLoss]) {
          expect(contrastRatio(c, t.surfaceBase), greaterThanOrEqualTo(3.0));
        }
      });
      test('tap floor is never below the spec §5 minimum', () {
        expect(t.tapMin, greaterThanOrEqualTo(60.0));
      });
    });
  }
}
```

`contrastRatio` is 15 lines implementing the WCAG formula — write it, don't import it. Note the red-shift palette will need a **relaxed** numeric threshold (see §4.3); encode that as an explicit, commented exception in the test rather than lowering the bar for all palettes.

---

## 4. Red-shift / night-vision mode

### 4.1 The actual physiology, and the caveat everyone omits

The mechanism is real:

- Scotopic (low-light) vision is rod-mediated; rods use **rhodopsin**, which bleaches under light and must regenerate ([StatPearls, *Physiology, Night Vision*](https://www.ncbi.nlm.nih.gov/books/NBK545246/)).
- Rods are least sensitive at long wavelengths (~620–700 nm), so deep red light bleaches rhodopsin far more slowly than white, blue or green.
- Dark adaptation is slow and expensive to lose. Webvision's *Light and Dark Adaptation* chapter: rod-pathway sensitivity "improves considerably after 5–10 minutes in the dark" and the curve "asymptotes to a minimum (absolute threshold)… **after about forty minutes** in the dark" ([Webvision](https://www.webvision.pitt.edu/book/part-viii-gabac-receptors/light-and-dark-adaptation/)).

Forty minutes. That is the whole argument for red-shift: a shepherd who checks the app on a white screen has, in principle, thrown away up to forty minutes of adaptation, on night eleven, in a shed where the difference between seeing and not seeing a lamb that isn't breathing matters.

**The caveat.** Aviation and naval-medical research on red vs white cockpit lighting finds the red advantage largely evaporates at low illumination levels — the differences "become relatively small when the stimulation prior to dark-adaptation is of low intensity", to the point that one study concluded there was **no difference** in dark-adaptation time after red or white at ~3 ft-C. Modern cockpits have largely moved to low-intensity white or greenish-blue because red costs colour discrimination and accommodation. The summary from that literature is blunt: *intensity matters more than colour*.

**Design consequence, and this is the important one:** a red-shift mode that is merely *red* and just as bright as the normal theme is close to useless. The mode must be **red AND dim**. Cap the maximum luminance of every token in the red palette. That is exactly what a token-based palette lets you do and a global colour filter does not.

There is a secondary, non-physiological benefit worth stating: a red screen in a dark shed is also less likely to spook stock and less visible from the yard.

### 4.2 Four implementation options, evaluated

| Option | Contrast control | Photos | Per-frame cost | Verdict |
|---|---|---|---|---|
| **A. Third `ColorScheme` + third `ShedTokens`** | Full — every pair is authored and unit-tested | Untouched (full colour) unless individually filtered | **Zero.** It is just different colours in the same widget tree | **Recommended** |
| **B. Global `ColorFiltered` over `MaterialApp`** | None. You get whatever the matrix produces; a 16:1 pair can become 3:1 | Destroyed — a lamb photo becomes a red smear | A full-screen `saveLayer` **every frame** | Rejected |
| **C. Fragment shader over the whole tree** | None (same as B) | Same as B | `ImageFilter.shader` is **Impeller-only** and there is *no* API to apply a shader to a widget subtree — you'd need `BackdropFilter`, which composites the whole backdrop | Rejected |
| **D. Physical red screen protector / OS colour filter** | N/A | N/A | Zero | Mention in the help text; not our code |

The performance objection to B and C is not hand-waving. Flutter's own performance guidance names `ColorFilter` among the widgets that call `saveLayer`, and says of `saveLayer`:

> "Calling `saveLayer()` allocates an offscreen buffer and drawing content into the offscreen buffer might trigger a render target switch… On mobile GPUs this is particularly disruptive to rendering throughput."
> — [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices)

A full-screen offscreen buffer on every frame, on a five-year-old Android phone in a cold shed, to achieve something we can achieve for free by choosing different constants, is indefensible.

The *correctness* objection is worse than the performance one. A red monochrome matrix maps luminance to the red channel. Our carefully-measured 16.16:1 body pair `#E8EAED` on `#0B0D0E` becomes `#F0…` red on `#0C…` red — the *luminance* relationship survives, but the achievable red gamut ceiling means the bright end clips and the whole UI ends up in a narrow luminance band. Worse, our status colours — green `#7DD3A0`, amber `#FFD54F`, salmon `#FFB4AB` — collapse to three nearly identical reds, silently destroying the colour channel of the pen board's status encoding. That is a WCAG 1.4.1 failure introduced by the accessibility feature. (Mitigated in our design because status is *also* shape-encoded — §12 — but a mode that destroys one of two redundant channels is still worse than one that preserves both.)

### 4.3 The recommended implementation

**The palette.** Author it, don't derive it. Measured ratios on `#000000`:

| Token | Hex | Ratio on `#000` | Use |
|---|---|---|---|
| `textNumeric` | `#FF6B4A` | **7.36:1** | tag numbers, keypad digits, timers |
| `textPrimary` | `#FF4400` | **6.08:1** | body |
| `textSecondary` | `#E62200` | **4.59:1** | labels — AA only, by necessity |
| `textChrome` | `#CC2200` | **3.80:1** | non-essential chrome |
| `surfaceRaised` | `#1A0503` | 1.07:1 vs base | cards, keypad keys |
| `surfaceFill` | `#2A0806` | 1.14:1 vs base | pressed/selected |
| `statusReady` / `statusAttention` / `statusLoss` | `#FF9E80` / `#FF6B4A` / `#FF2A00` | 10.45 / 7.36 / 5.58 | **must be shape-differentiated**, see §12 |

**Honest limitation, state it in the doc and in the app:** a genuinely long-wavelength palette has a hard contrast ceiling. Pure `#FF0000` on black is only **5.25:1**. Pushing toward orange buys contrast (`#FF4400` → 6.08:1) at the cost of adding green energy that bleaches rhodopsin faster. There is no red palette that reaches AAA (7:1) for body text and stays spectrally clean. Our choice sits at ~6:1 for body, which clears WCAG AA (4.5:1) but not AAA. **The red-shift contrast test must therefore assert AA, not AAA, with a comment pointing at this section.** Do not quietly relax the *whole* suite to hide this — the trade-off is real and belongs in the code.

**Compensate by size, not by colour.** Red-shift mode bumps `bodySize` from 18 → 20 and `numeralSize` from 40 → 44, and adds `weightBump: 100`. WCAG's own large-text allowance (3:1 for ≥18pt or ≥14pt bold) is the principle: when you cannot buy contrast, buy stroke.

**Photos.** In red-shift, wrap only image widgets:

```dart
// lib/design/components/shed_photo.dart
/// The ONLY place in the app that ColorFiltered is permitted.
/// Cost is bounded to the image's own bounds, not the screen.
class ShedPhoto extends StatelessWidget {
  const ShedPhoto({super.key, required this.image});
  final ImageProvider image;

  /// Maps luminance to the red channel; zeroes green and blue.
  /// Matrix is 4x5 row-major (dart:ui ColorFilter.matrix), interpreted as 5x5
  /// with an identity fifth row. Luminance coefficients are the sRGB/Rec.709
  /// weights, matching the WCAG relative-luminance definition.
  static const _redMono = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      0, 0,
    0,      0,      0,      0, 0,
    0,      0,      0,      1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final img = Image(image: image, fit: BoxFit.cover);
    if (!ShedTheme.of(context).isRedShift) return img;
    return ColorFiltered(colorFilter: _redMono, child: img);
  }
}
```

Add an explicit, 72pt "Show in full colour" toggle on the photo viewer. A shepherd looking at a photo of a prolapse needs the colour information; a red-only view of tissue is medically useless. This is a good example of the mode being *optional per-surface* rather than global.

**Switching.** Instant. No cross-fade — set `ShedTokens.motion` to `Duration.zero` for the switch itself. `AnimatedTheme`'s default 200ms lerp over a red↔neutral transition drags every colour through a desaturated mid-point, which is both ugly and, briefly, a low-contrast frame.

**Reachability of the toggle.** Spec §7.10 puts it in Settings. That is not enough: the shepherd decides they need red-shift *while standing in the dark*, not while sitting in the kitchen. Put a 72pt toggle in the bottom bar of the Quick Entry screen too, and make it the only chrome-coloured control there.

---

## 5. No white flash on launch

There are **four** layers, and a white frame at any one of them ruins it. In order of appearance:

```
[1] OS window background   →  [2] native launch screen  →  [3] Flutter's first frame  →  [4] first route
     (Android theme /             (LaunchTheme /              (MaterialApp.color)          (Scaffold bg)
      iOS window)                  LaunchScreen.storyboard)
```

### 5.1 Android

**Key fact that simplifies everything:**

> "Flutter now automatically keeps the Android launch screen displayed until it draws the first frame."
> — [Deprecated Splash Screen API Migration](https://docs.flutter.dev/release/breaking-changes/splash-screen-migration)

So on Android there is **no gap** between the launch screen and Flutter's first frame — provided you do not reintroduce one. Concretely:

`android/app/src/main/res/values/styles.xml` — note this is the *non*-night folder; the launch background must be dark even when the phone is in light mode:

```xml
<resources>
    <!-- Shown from process start until Flutter's first frame. -->
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@color/shed_surface_base</item>
        <item name="android:navigationBarColor">@color/shed_surface_base</item>
        <item name="android:statusBarColor">@color/shed_surface_base</item>
        <item name="android:forceDarkAllowed">false</item>
        <item name="android:enforceStatusBarContrast">false</item>
        <item name="android:enforceNavigationBarContrast">false</item>
    </style>

    <!-- Applied after the first frame; also shown during rotation/resume. -->
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@color/shed_surface_base</item>
        <item name="android:forceDarkAllowed">false</item>
    </style>
</resources>
```

`android/app/src/main/res/values/colors.xml`:

```xml
<resources>
    <color name="shed_surface_base">#FF0B0D0E</color>
</resources>
```

**Do not create `values-night/`.** The whole point is that the launch background is the same dark colour in every system configuration. (This is the opposite of Android's general dark-theme advice, which tells you to use `?android:attr/colorBackground` so the splash follows the system theme — correct for a normal app, wrong for a dark-only one.)

`android/app/src/main/res/values-v31/styles.xml` — Android 12+ replaces `windowBackground` with the SplashScreen API, which [cannot be opted out of](https://developer.android.com/develop/ui/views/launch/splash-screen):

```xml
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowSplashScreenBackground">@color/shed_surface_base</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/ic_splash_mono</item>
        <item name="android:windowSplashScreenAnimationDuration">0</item>
        <item name="android:forceDarkAllowed">false</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@color/shed_surface_base</item>
        <item name="android:forceDarkAllowed">false</item>
    </style>
</resources>
```

`AndroidManifest.xml`:

```xml
<activity
    android:name=".MainActivity"
    android:theme="@style/LaunchTheme"
    android:configChanges="uiMode|orientation|screenSize|screenLayout|smallestScreenSize|keyboardHidden|density"
    android:exported="true">
    <meta-data
        android:name="io.flutter.embedding.android.NormalTheme"
        android:resource="@style/NormalTheme" />
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
</activity>
```

**Two manifest checks that are easy to get wrong:**

1. There must be **no** `io.flutter.embedding.android.SplashScreenDrawable` meta-data. It has been deprecated since Flutter 2.5 and the migration doc says leaving it "can cause a crash".
2. There must be **no** `<uses-permission android:name="android.permission.INTERNET"/>` in `src/main/`. Flutter's generated `src/debug/AndroidManifest.xml` and `src/profile/AndroidManifest.xml` *do* declare INTERNET (the tooling needs it for hot reload and the VM service) and the manifest merger folds them in for those build types only. Release must have none. **Add a CI step that runs `aapt2 dump permissions` (or unzips and greps the merged manifest) on the release AAB and fails if `android.permission.INTERNET` appears** — that is the only way to catch a transitive dependency quietly merging it in.

**Killing the Android 12+ fade.** The SplashScreen API fades its icon out; if Flutter's first frame is not identical to the splash you get a visible cross-fade. Flutter's docs give the fix:

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { view -> view.remove() }
        }
        super.onCreate(savedInstanceState)
    }
}
```

Because our splash is a solid `#0B0D0E` field with a small monochrome icon, and our first frame is a solid `#0B0D0E` field, removing the exit animation outright produces a genuinely seamless handoff.

### 5.2 iOS

iOS is stricter (a launch storyboard is mandatory for App Store submission) and simpler.

1. **`ios/Runner/Info.plist` — force dark appearance:**
   ```xml
   <key>UIUserInterfaceStyle</key>
   <string>Dark</string>
   ```
   This makes the system ignore the user's Light/Dark preference for this app. Because Shed Book has no light theme, this is honest rather than hostile — and it means the system-drawn window background, the keyboard (if any), share sheets and alerts are all dark too.

2. **`LaunchScreen.storyboard`** — set the root view's background colour to `#0B0D0E` (sRGB 11/13/14). Delete the default `LaunchImage` image view, or replace it with a small monochrome mark. Do not use a `UIColor` named colour that resolves differently per appearance — with `UIUserInterfaceStyle = Dark` it cannot, but a literal removes the question.

3. **`UILaunchStoryboardName` = `LaunchScreen`** must remain in Info.plist. Separately, the **UIScene migration** (Flutter 3.38, auto-migrated by the CLI from 3.41) adds `UIApplicationSceneManifest` with `UISceneStoryboardFile = Main`. These are *different keys for different storyboards* — `UILaunchStoryboardName` is the launch screen, `UISceneStoryboardFile` is the main scene. Verify both survive the migration; run `flutter build ios` once and confirm the log line `Finished migration to UIScene lifecycle`.

4. **`ios/Runner/Base.lproj/Main.storyboard`** — the `FlutterViewController`'s view background. Set it to the same hex. This is the surface shown between the launch screen tearing down and Flutter's first frame, and it defaults to white in the Flutter template.

5. If you ever add a custom `AppDelegate`, per the UIScene breaking change do plugin registration in `didInitializeImplicitFlutterEngine(_:)`, not `application(_:didFinishLaunchingWithOptions:)`, and never touch `FlutterViewController` in the latter — the doc warns it "causes crashes".

### 5.3 The Flutter layers

```dart
MaterialApp(
  color: tokens.surfaceBase,          // window colour before the first route paints
  theme: theme,                       // scaffoldBackgroundColor + canvasColor = surfaceBase
  ...
)
```

and set the system bars from the first frame:

```dart
// Android 15+/16 enforce edge-to-edge; statusBarColor/systemNavigationBarColor are
// no-ops there. Icon brightness still applies, and it is what we actually need:
// light icons on our dark surface.
SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
  statusBarIconBrightness: Brightness.light,     // Android
  statusBarBrightness: Brightness.dark,          // iOS (describes the *background*)
  systemNavigationBarIconBrightness: Brightness.light,
));
```

Prefer `AnnotatedRegion<SystemUiOverlayStyle>` or `AppBar.systemOverlayStyle` per the API docs; a one-shot `setSystemUIOverlayStyle` at startup is fine for a single-appearance app.

### 5.4 The startup sequence — and the one async gap that matters

The theme choice lives in `Settings` (spec §10), i.e. in SQLite. Reading it asynchronously after `runApp` gives you one or more frames at the *default* theme. That's fine here **because every theme is dark** — a wrong first frame is a dark first frame. This is a deliberate property of the design, not luck.

Still, the clean sequence is:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep the native launch screen up while we do this. On Android, Flutter
  // holds it until the first frame; we simply do not schedule a frame yet.
  final settings = await SettingsStore.open();          // opens the SQLite db
  final palette = resolvePalette(settings.themeId);     // pure, synchronous
  runApp(ShedApp(palette: palette));
}
```

Budget: opening SQLite and reading one row is single-digit milliseconds. If it ever isn't, the fallback is to cache the theme id in a tiny file read synchronously — **not** `shared_preferences`, whose Android implementation is async and would reintroduce the gap.

**Do not add an artificial minimum splash duration.** Spec §5: under fifteen seconds from unlock to a saved event. Every millisecond of vanity splash is stolen from that budget.

### 5.5 `flutter_native_splash` — verdict

| Field | Value |
|---|---|
| Version | **2.4.8** |
| Published | **2026-05-29T20:03:33Z** (verified via `pub.dev/api/packages/flutter_native_splash`) |
| Publisher | jonhanson.net (verified publisher) |
| Platforms | Android, iOS, Web |
| Licence | MIT |
| Discontinued | No |
| SDK | Dart `>=3.0.0 <4.0.0`, Flutter `>=2.5.0` |

**Verdict: `avoid` for this project** (it is a competent package; it is simply the wrong shape for this job).

- It is a **code generator** that rewrites your `styles.xml`, `colors.xml`, `LaunchScreen.storyboard` and drawables from `flutter_native_splash.yaml`. Everything in §5.1–5.2 above is hand-written and reviewed; a generator that overwrites it introduces a second source of truth and a `flutter pub run flutter_native_splash:create` step someone will forget.
- Our splash is a **solid colour and one small icon**. That is ~25 lines of XML/plist. The package's value is highest when you need multi-density image generation across three platforms plus Android 12 branding images — none of which we want.
- **Maintenance signal:** on 2026-03-06 the maintainer opened [issue #821](https://github.com/jonbhanson/flutter_native_splash/issues/821): *"I have been working in other domains and have not had enough time to maintain this package, so I would like to find a new project owner."* Still open. There are also open issues about Android 12+ colour application (#814) and colours not being applied correctly (#809) — precisely the failure mode we cannot tolerate.
- It is a `dev_dependency`, so it ships no runtime code and adds no permission — that part is fine. The objection is purely about owning the artifact we depend on.

**If you disagree and use it anyway:** pin the exact version, commit the generated files, and add a CI check that regenerating produces no diff.

---

## 6. Tap targets of 60×60 pt

### 6.1 The baselines, from primary sources

| Authority | Minimum | Source |
|---|---|---|
| Apple HIG / UI Design Dos and Don'ts | **44 × 44 pt** — "Create controls that measure at least 44 points x 44 points so they can be accurately tapped with a finger." Also: "A button needs a hit region of at least 44x44 pt — in visionOS, 60x60 pt". | [developer.apple.com/design/tips](https://developer.apple.com/design/tips/) |
| Android / Material 3 | **48 × 48 dp** — "we recommend that each interactive UI element have a focusable area… of at least 48dp×48dp. Larger is even better." Separated by **8dp** or more. | [Android accessibility](https://developer.android.com/guide/topics/ui/accessibility/apps) |
| WCAG 2.2 SC 2.5.8 (AA) | **24 × 24 CSS px**, or a 24px-diameter no-overlap spacing exception | [W3C](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html) |
| WCAG 2.2 SC 2.5.5 (AAA) | **44 × 44 CSS px** | [W3C](https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced.html) |
| Flutter | `kMinInteractiveDimension = 48.0`; `kMinInteractiveDimensionCupertino = 44.0` | [api.flutter.dev](https://api.flutter.dev/flutter/material/kMinInteractiveDimension-constant.html) |

### 6.2 Why 60pt is right, with the arithmetic

Logical pixels convert to physical size at the reference densities (Android 1dp = 1/160 in; iOS 1pt ≈ 1/163 in):

| Logical px | Android mm | iOS mm |
|---|---|---|
| 44 | 6.99 | 6.86 |
| 48 | 7.62 | 7.48 |
| **60** | **9.52** | **9.35** |
| 72 | 11.43 | 11.22 |
| 88 | 13.97 | 13.71 |

Now the empirical work:

- **Parhi, Karlson & Bederson, MobileHCI 2006** — the canonical one-handed-thumb study. Two phases, discrete and serial tapping, target position varied. Conclusion, verbatim: *"target size of 9.2 mm for discrete tasks and targets of 9.6 mm for serial tasks should be sufficiently large for one-handed thumb use on touchscreen-based handhelds without degrading performance and preference."* ([Microsoft Research](https://www.microsoft.com/en-us/research/publication/target-size-study-for-one-handed-thumb-use-on-small-touchscreen-devices/))

  **60 logical px ≈ 9.4 mm.** The spec's number is, to within measurement noise, the *empirical optimum for a bare, warm, dry thumb in a lab*. That is the correct reading of it: 60pt is not a generous margin, it is the baseline for ideal conditions. Note also that Parhi's *serial* recommendation (9.6 mm, i.e. ~61pt) is the larger of the two — and the keypad is a serial task.

- **Touch-screen performance with and without motor control disabilities** (button sizes 10/15/20/25/30 mm, gaps 1 and 3 mm): non-disabled misses plateaued at 20 mm; the disabled group kept improving — 19% misses at 20 mm, 12% at 25 mm, 8% at 30 mm — and the authors recommend *"at least 30mm"* for tasks with low error tolerance. ([PMC3572909](https://pmc.ncbi.nlm.nih.gov/articles/PMC3572909/))

  Cold fingers, gloves and a wet screen are not a motor-control disability, but they degrade the same variables: contact-patch fidelity, tremor, and proprioceptive precision. And **lambing entry is a low-error-tolerance task** — a mis-tap that records a stillbirth on the wrong ewe is a record that stays wrong for five years. That study's 30 mm ≈ **189 logical px**, which is a whole-screen button. Impractical; but it justifies pushing the *primary* actions well past 60.

**Therefore, the Shed Book scale:**

| Class | Size | mm | Where |
|---|---|---|---|
| `tapMin` | **60** | 9.5 | Absolute floor. Every interactive thing, everywhere, including settings rows. |
| `tapPrimary` | **72** | 11.4 | Keypad digits; recents-strip chips; pen tiles; ease-score buttons. |
| `tapHero` | **88** | 14.0 | The five 3am actions: *Lambed*, *Save*, *Turn out*, *Treat*, *Dead*. |
| `gapMin` | **16** | 2.5 | Between any two targets. Double Material's 8dp. |
| `gapDestructive` | **32** | 5.1 | Between a destructive target and its nearest neighbour. |

### 6.3 Enforcing it in Flutter

`MaterialTapTargetSize.padded` only gets you to 48. `ThemeData.materialTapTargetSize` is [documented as expanding "the minimum tap target size to 48px by 48px"](https://api.flutter.dev/flutter/material/MaterialTapTargetSize.html). To get 60 you must say so:

```dart
// lib/design/components/shed_button.dart
ButtonStyle shedPrimaryButtonStyle(ShedTokens t) => FilledButton.styleFrom(
  minimumSize: Size(t.tapPrimary * 2, t.tapHero),   // wide AND tall
  padding: const EdgeInsets.symmetric(horizontal: s24, vertical: s16),
  textStyle: TextStyle(fontSize: t.bodySize + 4, fontWeight: FontWeight.w700),
  backgroundColor: t.surfaceFill,
  foregroundColor: t.textPrimary,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
).copyWith(
  // ButtonStyle.tapTargetSize only offers the padded/shrinkWrap enum; the real
  // floor comes from minimumSize above. Keep padded so nothing shrinks below 48
  // even if minimumSize is overridden at a call site.
  tapTargetSize: MaterialTapTargetSize.padded,
  visualDensity: VisualDensity.standard,
);
```

For anything that is not a Material button — a pen tile, a recents chip, a lamb row — wrap it. This widget is the single enforcement point and the thing the CI test looks for:

```dart
/// Guarantees a >= [minSize] square hit region regardless of the child's
/// painted size, and makes the whole region opaque to hit testing so a tap
/// in the transparent margin still counts (this is the "hit slop").
class ShedTapTarget extends StatelessWidget {
  const ShedTapTarget({
    super.key,
    required this.onTap,
    required this.child,
    this.minSize,
    this.semanticLabel,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double? minSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final size = minSize ?? t.tapMin;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        // opaque => the padding around the child is part of the hit region.
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: size, minHeight: size),
          child: Center(child: child),
        ),
      ),
    );
  }
}
```

**Hit slop beyond the visual bounds.** Two mechanisms, both needed:

1. *Inside the layout* — `HitTestBehavior.opaque` + `ConstrainedBox` above. The visual glyph can be 32pt inside an 88pt hit region.
2. *Outside the layout* — Flutter clips hit testing to a parent's bounds by default. If a target must overflow its parent's box (rare; avoid), the parent needs a `Stack` with `clipBehavior: Clip.none` **and** the child still inside the parent's hit-test rect, or the taps are silently dropped. **Prefer restructuring the layout over relying on overflow hit-testing** — this is a class of bug that only shows up on a real device.

**Spacing.** Enforce with layout, not with vigilance:

```dart
class ShedActionColumn extends StatelessWidget {
  const ShedActionColumn({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final gap = context.tokens.gapMin;
    return Column(
      mainAxisSize: MainAxisSize.min,
      // Flutter 3.27+ : Column/Row/Flex take `spacing`. No more SizedBox soup.
      spacing: gap,
      children: children,
    );
  }
}
```

**Never place a destructive action adjacent to a frequent one.** *Delete lamb* must not be `gapMin` away from *Save*. Put destructive actions on a different screen edge, behind a confirm, at `gapDestructive` minimum. The spec bans swipe-to-delete, which removes the usual place people hide destruction — good; that means deletion is an explicit, deliberate, two-step act, which is correct for a record that must not be silently lost (spec §12.4, "never silently correct").

### 6.4 Testing it

`flutter_test` ships `MinimumTapTargetGuideline` as a **public, const-constructible** class taking `{required Size size, required String link}` ([API](https://api.flutter.dev/flutter/flutter_test/MinimumTapTargetGuideline-class.html)). So the app's own stricter rule becomes a first-class guideline:

```dart
// test/design/tap_target_test.dart
const shedTapTargetGuideline = MinimumTapTargetGuideline(
  size: Size(60, 60),
  link: 'docs/research/raw/05-design-system-3am.md#6-tap-targets-of-6060-pt',
);

void main() {
  for (final screen in shedScreensUnderTest) {
    testWidgets('${screen.name} meets the 60pt tap floor', (tester) async {
      await tester.pumpWidget(screen.build());
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(shedTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('${screen.name} survives 200% text scale', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(screen.build());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);   // no RenderFlex overflow
      await expectLater(tester, meetsGuideline(shedTapTargetGuideline));
    });
  }
}
```

The other three built-in guidelines are `androidTapTargetGuideline` (48×48), `iOSTapTargetGuideline` (44×44), and `textContrastGuideline` (WCAG). Ours strictly dominates the first two, so run ours plus `labeledTapTargetGuideline` (every tappable node has a label — also what makes VoiceOver usable) and `textContrastGuideline`.

---

## 7. Wet hands, gloves, and a phone in a freezer bag

### 7.1 What the physics actually says

Modern phones use **projected mutual-capacitance** sensing: a grid of transmit/receive electrodes, where a grounded conductor (a finger) near an intersection steals field lines and reduces the measured mutual capacitance. Consequences that matter here:

- **A dry glove is a dielectric spacer.** It does not block the field, it attenuates the coupling, roughly with separation. Industrial touch-panel guidance puts the practical limit at gloves "no thicker than **5 mm**" for panels not specifically tuned for it ([Focus LCDs](https://focuslcds.com/journals/using-capacitive-touch-panels-with-gloves/)) — and a typical phone panel is tuned far tighter than an industrial one. A wet nitrile lambing glove is thin (~0.1 mm) and, being wet, partly conductive: **it usually works**. A dry wool or leather glove usually does not.
- **A freezer bag is also just a dielectric spacer.** LDPE film is ~0.05 mm; the attenuation is small. In practice ziplock-bag operation *mostly works* and degrades when the bag is loose (air gap adds separation) or doubled.
- **Water on the screen is the real enemy**, and it is a different failure mode: water is conductive and grounded-ish, so it produces *phantom* touches and merges contact patches. Panels ship water-rejection heuristics that respond by *raising* the detection threshold — i.e. becoming less sensitive exactly when a gloved finger needs more sensitivity. This is why "wet + gloved" is much worse than either alone.
- **Cold reduces contact area and increases tremor** — a cold, stiff finger presents a smaller, less stable patch.

**None of this is under app control.** Flutter sees `PointerDownEvent`s or it doesn't. What *is* under app control:

1. **Target size and dwell.** A bigger target tolerates a smaller, noisier contact patch. This is the entire mitigation.
2. **Single discrete taps only.** Every gesture that requires the panel to *track* a contact over time or space is a gesture that fails when the contact is marginal.
3. **Telling the user about the OS setting.** Both major Android vendors ship a sensitivity boost:
   - Samsung: **Settings → Display → Touch sensitivity**. Samsung's own support page: it "increases touch sensitivity for a more responsive experience" for screen protectors and gloves, and warns that "loose or damaged screen protectors, wet screens, and gloves can still impact performance" ([Samsung](https://www.samsung.com/ca/support/mobile-devices/activate-touch-sensitivity-on-your-samsung-galaxy/)).
   - Pixel: the same feature is called **Screen protector mode**.
   - **iOS has no equivalent user setting.** This is a genuine platform asymmetry worth knowing.

   Shed Book should surface this once, in a Help screen, with the exact menu path per platform. It costs nothing and is probably the single highest-leverage thing the app can say to a user having trouble.

### 7.2 Validating the spec's gesture ban

Spec §5 bans swipe-to-delete, drag, long-press-only, pinch and force touch. Each ban is correct, for a specific reason:

| Banned | Why it fails at 3am |
|---|---|
| **Swipe-to-delete** | Requires a tracked contact over ~100pt of travel with the contact never dropping. A marginal gloved/bagged contact drops mid-swipe → the gesture is interpreted as a tap (opening the row) or nothing. Also: it is *destructive* and *invisible*, which conflicts with spec §12.4. |
| **Drag** | Same tracking requirement, longer duration, plus it needs precision at the drop target. |
| **Long-press-only** | Requires the contact to be held ≥500 ms *without moving more than the touch slop*. A cold, tremoring finger through plastic exceeds the slop and cancels. Worse: a long-press-only action is **undiscoverable** — the spec is right that it can be an *additional* affordance but never the only route. |
| **Pinch** | Needs two simultaneous tracked contacts. One hand is holding a lamb. Non-starter regardless of capacitance. |
| **Force touch** | **The hardware does not exist.** Apple removed 3D Touch across the iPhone line starting with iPhone XR / iPhone 11; "Haptic Touch" is a long press with haptic feedback, not a pressure sensor. Android never had a broadly-deployed equivalent. So this ban costs nothing and would have been a correctness bug. |

**What survives:** the single discrete tap. Design the entire app so that every action is reachable by a sequence of taps on ≥60pt targets. That is a real constraint on the navigation model — e.g. reordering pens must be "tap pen → tap *Move to…* → tap destination", not drag-and-drop.

**One permitted exception, argued:** vertical *scrolling* is a tracked gesture and cannot be avoided in a flock list. Mitigations: (a) the Quick Entry screen must fit without scrolling at 100% text scale on the smallest supported device; (b) provide tap-based paging (an A–Z / numeric jump strip of 60pt targets) alongside scrolling on the flock list; (c) never put an action *only* behind a scroll.

### 7.3 Hardware button shortcuts — spec open question 4, answered

**Verdict: no. Do not build volume-button shortcuts.**

**iOS: prohibited.** App Store Review Guideline **2.5.9**:

> "Apps that alter or disable the functions of standard switches, such as the Volume Up/Down and Ring/Silent switches, or other native user interface elements or behaviors will be rejected."
> — [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

The common workaround (KVO on `AVAudioSession.outputVolume` to *detect* a press) does not "alter or disable" the button, so it is arguably compliant — but it (a) requires an active audio session, (b) cannot suppress the volume HUD, (c) drifts when the volume hits 0 or 1 and there is no more travel, and (d) is exactly the pattern reviewers flag. Guideline 2.5.1 additionally requires APIs be used "for their intended purposes". Building a core interaction on a mechanism whose legality depends on a reviewer's mood is not acceptable for an app whose entire pitch is "it cannot break".

**Android: technically possible.** `Activity.onKeyDown` receives `KeyEvent.KEYCODE_VOLUME_UP` / `KEYCODE_VOLUME_DOWN`, and returning `true` consumes the event so the volume does not change ([KeyEvent](https://developer.android.com/reference/android/view/KeyEvent)). It would need a platform channel — Flutter's `HardwareKeyboard` does not surface volume keys, because the embedding consumes them at the Android view layer.

**Why "possible on one platform" is worse than "not at all":**

- A shepherd who learns "volume-down = new lambing" on an Android phone and then replaces it with an iPhone loses a muscle-memory action. Muscle memory is the entire point of a 3am shortcut.
- Consuming volume-down breaks the user's ability to silence the phone — in a shed, at night, next to sleeping stock. That is a real harm, not a theoretical one.
- It only works while the app is foregrounded and unlocked, so it does not actually shorten the "phone-unlock to saved event" path that spec §15 measures.

**Build this instead** (all of it cheaper and cross-platform):

1. **iOS Home Screen quick actions / Android app shortcuts** — long-press the app icon → "New lambing". This is an OS affordance, is legal, is symmetric, and *does* shorten the unlock-to-entry path. Verify the plugin used adds no network capability before adopting.
2. **A single fixed launch destination.** The app always opens on Quick Entry. No "resume where you left off", no deep-link restoration. Predictability beats cleverness at 3am.
3. **The recents strip** (spec §7.1) — six 72pt one-tap targets. The ewe you just handled is the ewe you're still handling. This is the real "shortcut".

Record in the spec that open question 4's answer is: *bag operation generally works; the interaction model does not need volume buttons; verify on real hardware during the field night (§17 Q1).*

---

## 8. Typography

### 8.1 18pt body means overriding the entire M3 scale

Verified from `packages/flutter/lib/src/material/typography.dart` on the stable branch, `_M3Typography.englishLike`:

| Role | M3 default size | weight | Shed Book |
|---|---|---|---|
| displayLarge | 57.0 | w400 | 64 / w700 — the keypad's entered tag |
| displayMedium | 45.0 | w400 | 48 / w700 |
| displaySmall | 36.0 | w400 | 40 / w700 — pen tile tag number |
| headlineLarge | 32.0 | w400 | 32 / w700 |
| headlineMedium | 28.0 | w400 | 28 / w600 |
| headlineSmall | 24.0 | w400 | 24 / w600 |
| titleLarge | 22.0 | w400 | 24 / w600 — screen titles |
| titleMedium | 16.0 | w500 | **20** / w600 |
| titleSmall | 14.0 | w500 | **18** / w600 |
| **bodyLarge** | **16.0** | w400 | **20** / w500 |
| **bodyMedium** | **14.0** | w400 | **18** / w500 — the floor |
| **bodySmall** | **12.0** | w400 | **18** / w500 — collapsed into bodyMedium |
| labelLarge | 14.0 | w500 | **20** / w700 — button text |
| labelMedium | 12.0 | w500 | **18** / w600 |
| labelSmall | 11.0 | w500 | **18** / w600 — collapsed |

Two decisions embedded there:

- **Nothing is smaller than 18.** `bodySmall` and `labelSmall` are *deleted* as distinct sizes. If a piece of text isn't worth 18pt, it isn't worth showing at 3am. This costs information density; the pen board compensates with layout, not with 12pt type.
- **Weights go up one step across the board.** Stroke width is the other legibility lever, and on a dark background heavier strokes read better (they partially counteract halation).

```dart
TextTheme buildShedTextTheme(ShedTokens t) {
  TextStyle s(double size, FontWeight w, {List<FontFeature>? f}) => TextStyle(
        fontFamily: 'AtkinsonNext',
        fontSize: size,
        // 3.41+: FontWeight alone drives the variable font's wght axis.
        fontWeight: FontWeight.values.firstWhere(
          (x) => x.value == (w.value + t.weightBump).clamp(100, 900),
        ),
        color: t.textPrimary,
        height: 1.35,
        fontFeatures: f,
      );

  const tabular = <FontFeature>[FontFeature.tabularFigures()];

  return TextTheme(
    displayLarge:  s(64, FontWeight.w700, f: tabular),
    displayMedium: s(48, FontWeight.w700, f: tabular),
    displaySmall:  s(40, FontWeight.w700, f: tabular),
    headlineLarge: s(32, FontWeight.w700),
    headlineMedium:s(28, FontWeight.w600),
    headlineSmall: s(24, FontWeight.w600),
    titleLarge:    s(24, FontWeight.w600),
    titleMedium:   s(20, FontWeight.w600),
    titleSmall:    s(18, FontWeight.w600),
    bodyLarge:     s(20, FontWeight.w500),
    bodyMedium:    s(18, FontWeight.w500),
    bodySmall:     s(18, FontWeight.w500),
    labelLarge:    s(20, FontWeight.w700),
    labelMedium:   s(18, FontWeight.w600),
    labelSmall:    s(18, FontWeight.w600),
  );
}
```

### 8.2 Never clamp `textScaler`

- `textScaleFactor` is deprecated in favour of `TextScaler` ([migration](https://docs.flutter.dev/release/breaking-changes/deprecate-textscalefactor)), specifically to support **Android 14's non-linear scaling to 200%**.
- Android: "Starting in Android 14, the system supports font scaling up to 200%… the system applies a nonlinear scaling curve" so large text grows less than small text. Google explicitly says `scaledDensity` is no longer accurate and `fontScale` is "for informational purposes only".
- Flutter's own migration note is unambiguous that manually clamping bypasses the platform curve.
- iOS Dynamic Type goes further still with the accessibility sizes.

**So: no `MediaQuery.withClampedTextScaling`, no `TextScaler.clamp(maxScaleFactor: …)`, anywhere.** The floor-only override in §2.5 is the only permitted manipulation.

What that costs you, and how to pay it:

- The pen board grid must reflow, not clip. Use `LayoutBuilder` + a target *minimum tile width*, letting the column count drop from 4 → 3 → 2 → 1 as text grows. Never a fixed `GridView.count`.
- Every `Row` containing a label and a value becomes a `Wrap` or a `Column` above a threshold. `LayoutBuilder` + `MediaQuery.textScalerOf(context).scale(18) > 30` is a serviceable switch.
- Test at 2.0 in widget tests (§6.4) and check `tester.takeException()` is null — `RenderFlex overflowed` is thrown as an exception in tests, so this genuinely catches it.

**`boldText`.** `MediaQueryData.boldText` is "whether the platform is requesting that text be drawn with a bold font weight." Feed it into `ShedTokens.weightBump` (0 or 100). Because we ship a *variable* font with a 200–800 `wght` axis, this is free and continuous rather than a fake-bold synthesis.

### 8.3 Font choice — what actually matters under a head torch

The failure cases are specific and numeric, because **the primary content is a three-digit ewe tag**:

- `1` vs `7` — a `1` with no base serif and a short flag reads as `7` at an angle.
- `0` vs `O` — tags are numeric, so a `0` misread as `O` is only a problem in free text, but `0` vs `8` at low contrast is a real one.
- `6` vs `8` vs `B`, `5` vs `S`, `3` vs `8` — closed vs open counters decide these.
- **Tabular figures.** A pen board where `412` and `108` occupy different widths is a board whose columns jitter. Tabular (monospaced) figures are non-negotiable for anything in a grid or a countdown.

**Recommendation: bundle Atkinson Hyperlegible Next.**

| Field | Value |
|---|---|
| Source | [Braille Institute](https://www.brailleinstitute.org/freefont/); distributed via [google/fonts `ofl/atkinsonhyperlegiblenext`](https://github.com/google/fonts/tree/main/ofl/atkinsonhyperlegiblenext) |
| Licence | **SIL Open Font License 1.1** (`OFL.txt` present in the Google Fonts repo; METADATA.pb `license: OFL`) — bundling in a commercial app is unambiguously permitted |
| Designers | Braille Institute, Applied Design Works, Elliott Scott, Megan Eiswerth, Letters From Sweden |
| Files | `AtkinsonHyperlegibleNext[wght].ttf` + `AtkinsonHyperlegibleNext-Italic[wght].ttf`, variable `wght` **200–800** |
| Size | **114,552 bytes** for the upright variable file (measured by download) — trivial against the spec's <20 MB payload |
| OpenType features | **Verified by direct byte-inspection of the GSUB table**: `aalt, case, ccmp, frac, locl, ordn, pnum, sups, tnum`. **`tnum` (tabular figures) is present.** |
| Design intent | Purpose-built for low vision: "similarly-shaped upright letters are distinctly different", "matching letter pairs are clearer and easier to identify", "large areas inside letters, called counters, keep characters clear", "angled spurs and longer tails help increase differentiation" |
| Validation | 2019 Fast Company Innovation by Design Award; 2024 Cooper Hewitt permanent collection; 2025 Webby honoree for Accessible Technology |

**Caveats found, stated honestly:**
- There is **no `zero` (slashed zero) feature** and no `ss01`/`cv` character variants in the GSUB table. AH Next differentiates `0` from `O` by shape (counter and width) rather than by a slash. Verify this is sufficient on a real device under a head torch before locking it in — that is a five-minute test.
- The Braille Institute's own download page mentions an EULA; the **Google Fonts distribution is OFL 1.1**, which is the copy to vendor. Take the font from `github.com/google/fonts/ofl/atkinsonhyperlegiblenext`, commit `OFL.txt` alongside it in `assets/fonts/`, and reference it in the app's licence page via `LicenseRegistry.addLicense`.

**Runner-up: Inter** ([rsms/inter](https://github.com/rsms/inter)) — also OFL 1.1, and its README documents "slashed zero for when you need to disambiguate '0' from 'o', [and] tabular numbers." If the AH Next `0`/`O` test fails, Inter with `FontFeature.slashedZero()` is the fallback. Inter is a general-purpose UI face; AH Next is a legibility-first face. For this app, legibility wins.

**pubspec:**

```yaml
flutter:
  fonts:
    - family: AtkinsonNext
      fonts:
        # A single variable file. Post-3.41, FontWeight drives the wght axis
        # directly, so no per-weight asset entries and no FontVariation lists.
        - asset: assets/fonts/AtkinsonHyperlegibleNext[wght].ttf
```

**Never `google_fonts`.** Verified: `google_fonts` **8.2.0** (published **2026-07-15**, publisher flutter.dev) declares a dependency on **`http ^1.0.0`** and its README describes "HTTP fetching at runtime". It can be configured to prefer bundled assets and `GoogleFonts.config.allowRuntimeFetching = false` exists — but in an app that ships with *no* INTERNET permission on Android, a font library whose default is a network fetch is a latent failure and a permission-audit hazard. Bundle the TTF; delete the dependency. The `check_tokens.dart` gate greps for `GoogleFonts`.

---

## 9. The giant numeric keypad

### 9.1 Custom keypad vs the system keyboard — the argument

The obvious implementation is `TextField(keyboardType: TextInputType.number)`. It is wrong here, for five reasons:

1. **You cannot control key size.** The system numeric keypad's key geometry is fixed by the OS. It is roughly 44–50pt tall on a typical iPhone — *below our 60pt floor and below Parhi's 9.2 mm optimum*. The spec's "digits at least 40 pt" (§7.1) refers to the *glyph*, which implies a key far bigger than the system provides.
2. **You cannot control layout.** iOS puts the numeric keypad's `1` at the *top*, ~250pt up the screen, well outside the one-thumb zone (§11). Our keypad puts the most-used affordances at the bottom.
3. **The keyboard steals half the screen** and animates in. On the Quick Entry screen we need the filtered flock list, the recents strip *and* the keypad visible simultaneously. A system keyboard makes that impossible on a 5.5" phone.
4. **You cannot add domain keys.** Our keypad needs a *Create ewe 412* key, a *Clear* key and a backspace, all in the thumb zone, all sized to our tokens. A system keyboard has none of that (`TextInputAction` gives you one blue button in a corner).
5. **Appearance risk.** `TextField.keyboardAppearance` is honoured on **iOS only** ([API](https://api.flutter.dev/flutter/material/TextField/keyboardAppearance.html)); on Android the keyboard's appearance is the IME's business, and a third-party IME can and will render a bright keyboard in a dark shed. That is a white-flash vector we cannot close. (`UIUserInterfaceStyle = Dark` closes it on iOS.)

Cost of the custom keypad: you also lose the system keyboard's dictation button. Spec §7.1 wants "optional voice tag entry using OS on-device speech recognition" — that becomes an explicit 72pt mic key on our keypad wired to an on-device recogniser, which is better anyway because we can require on-device-only recognition rather than whatever the IME does.

### 9.2 Widget-level design

```dart
/// 3 x 4 grid. Bottom row: [backspace] [0] [confirm].
/// - Backspace is bottom-LEFT and confirm bottom-RIGHT by default (right-handed);
///   both mirror when Settings.leftHanded is true.
/// - No key is ever narrower than tapPrimary (72) or shorter than tapPrimary.
/// - Keys are separated by gapMin (16) so a 9mm contact patch centred on a gap
///   still resolves to exactly one key.
class ShedKeypad extends StatelessWidget {
  const ShedKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onConfirm,
    required this.confirmLabel,
    this.leftHanded = false,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onConfirm;
  final String confirmLabel;      // "Use 412" / "Create 412" — never just a tick
  final bool leftHanded;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bottom = <Widget>[
      _Key(icon: Icons.backspace_outlined, onTap: onBackspace, semantic: 'Backspace'),
      _Key(digit: 0, onTap: () => onDigit(0)),
      _Key(label: confirmLabel, onTap: onConfirm, emphasis: true),
    ];

    return Column(
      spacing: t.gapMin,
      children: [
        for (final row in const [[1,2,3],[4,5,6],[7,8,9]])
          Row(spacing: t.gapMin, children: [
            for (final d in row)
              Expanded(child: _Key(digit: d, onTap: () => onDigit(d))),
          ]),
        Row(
          spacing: t.gapMin,
          children: [
            for (final w in (leftHanded ? bottom.reversed.toList() : bottom))
              Expanded(child: w),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({this.digit, this.label, this.icon, required this.onTap,
              this.emphasis = false, this.semantic});

  final int? digit;
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool emphasis;
  final String? semantic;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ShedTapTarget(
      minSize: t.tapPrimary,                    // 72
      semanticLabel: semantic ?? label ?? '$digit',
      onTap: () {
        // Fires before the state change so the finger feels the key, not the result.
        HapticFeedback.selectionClick();
        onTap();
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: emphasis ? t.surfaceFill : t.surfaceRaised,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Center(
          child: digit != null
              // 44pt glyph: comfortably above the spec's "at least 40 pt".
              ? Text('$digit', style: Theme.of(context).textTheme.displaySmall!
                    .copyWith(fontSize: 44, color: t.textNumeric))
              : icon != null
                  ? Icon(icon, size: 32, color: t.textPrimary)
                  : Text(label!, style: Theme.of(context).textTheme.labelLarge),
        ),
      ),
    );
  }
}
```

Design notes that matter:

- **Backspace placement.** Right-handed thumbs rest bottom-right, so the *most consequential* key (confirm) goes there and backspace goes bottom-left, away from the resting position. Left-handed mirrors it. Hoober's observational data supports this asymmetry: of one-handed users, **67% used the right thumb, 33% the left** — a third of users is far too many to ignore, so make it a setting rather than picking a side.
- **Confirm is labelled with the outcome**, not a tick: *"Use 412"* if the tag exists, *"Create 412"* if it doesn't (spec §7.1 create-on-the-fly). A glanceable label is the only defence against creating a duplicate ewe at 3am.
- **Haptic fires on down, before the state change.** `HapticFeedback.selectionClick()` maps to `UISelectionFeedbackGenerator` on iOS and `HapticFeedbackConstants.CLOCK_TICK` on Android (verified from the engine sources) — the lightest tick on both, which is what a keypad wants.
- **No key repeat on backspace.** Key repeat requires a held contact — banned by §7.2's reasoning.
- **The keypad never covers the recents strip.** Layout order top-to-bottom: entered tag (huge) → filtered matches (max 3 rows) → recents strip → keypad. If it doesn't fit, drop the filtered matches to 2 rows, never the keypad.

---

## 10. Feedback you can perceive without looking

Three independent channels, because each one fails silently on some device.

### 10.1 Haptics — real, but never load-bearing

`HapticFeedback` (in `package:flutter/services.dart`) offers `lightImpact`, `mediumImpact`, `heavyImpact`, `selectionClick`, `successNotification`, `warningNotification`, `errorNotification`, `vibrate`. Verified engine mappings:

| Flutter API | iOS | Android |
|---|---|---|
| `lightImpact()` | `UIImpactFeedbackGenerator(.light)` | `HapticFeedbackConstants.VIRTUAL_KEY` |
| `mediumImpact()` | `UIImpactFeedbackGenerator(.medium)` | `HapticFeedbackConstants.KEYBOARD_TAP` |
| `heavyImpact()` | `UIImpactFeedbackGenerator(.heavy)` | `HapticFeedbackConstants.CONTEXT_CLICK` |
| `selectionClick()` | `UISelectionFeedbackGenerator` | `HapticFeedbackConstants.CLOCK_TICK` |
| `successNotification()` | `UINotificationFeedbackGenerator(.success)` | `HapticFeedbackConstants.CONFIRM` (API 30+) |
| `warningNotification()` | `UINotificationFeedbackGenerator(.warning)` | `HapticFeedbackConstants.KEYBOARD_TAP` (API 30+) |
| `errorNotification()` | `UINotificationFeedbackGenerator(.error)` | `HapticFeedbackConstants.REJECT` (API 30+) |
| `vibrate()` | `AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)` | — |

What is **actually distinguishable**:

- **iOS (Taptic Engine): three or four patterns are reliably distinguishable.** `selectionClick` (tiny tick), `mediumImpact` (a thud), and the notification triad (`success` = ta-*tap*, `warning` = two beats, `error` = three sharp beats) are genuinely different sensations even through a glove.
- **Android: assume two.** Vendor LRA quality varies enormously; on many mid-range devices `VIRTUAL_KEY`, `KEYBOARD_TAP` and `CLOCK_TICK` all resolve to the same short buzz. `CONFIRM` and `REJECT` only exist on API 30+ and are only meaningfully distinct on good hardware.
- **All of it can be off.** Android's *Touch feedback* / *Vibration* system settings silence it; iOS's *System Haptics* toggle does the same. An app cannot detect or override this.

**Therefore the haptic vocabulary is deliberately tiny:**

| Event | Haptic |
|---|---|
| Key press / selection change | `selectionClick()` |
| **Record committed to SQLite** | `successNotification()` |
| Validation flag (e.g. "twin" with 3 lambs — spec §12.4) | `warningNotification()` |
| Action refused (free-tier cap reached) | `errorNotification()` |

Nothing else. If a user cannot learn the vocabulary in one night, it is too big.

### 10.2 Audio in a noisy shed

`SystemSound.play(SystemSoundType.click)` is implemented on both platforms — iOS via `AudioServicesPlaySystemSound(1306)` (the keyboard click), Android via `view.playSoundEffect(SoundEffectConstants.CLICK)`. `SystemSoundType.tick` is iOS-only; `SystemSoundType.alert` is desktop-only.

**But:** the keyboard click respects the system keyboard-click setting and the ringer/silent switch, and it is a *quiet* sound designed to be unobtrusive. In a shed with a ventilation fan, a generator and ewes, it is inaudible.

**Recommendation: no audio in v1.** Reasons:

1. A confirmation loud enough to hear over a shed is loud enough to disturb stock and anyone asleep in the house.
2. Making it work requires a real audio plugin (bundled WAV, own audio session, ducking behaviour, silent-switch policy). Every candidate is a new dependency with platform code — against the offline/minimal-surface posture, for a benefit we cannot demonstrate.
3. Spec §5 says "zero interruptions". Sound is the most interrupting channel.

**Revisit only if the field night (§17 Q1) shows haptics are unreliable on the shepherd's actual phone.** If so, the right shape is an opt-in, off-by-default, single short tone via a minimal audio plugin — and verify that plugin merges no INTERNET permission.

### 10.3 The "saved" affordance — proof, not optimism

Spec §5: "Every write is committed immediately… assume the phone dies." That forbids optimistic UI. The order is:

```
tap → write → await transaction → THEN change the UI
```

not `tap → change UI → write in background`. On a local SQLite write this costs single-digit milliseconds, so there is no UX reason to be optimistic and a hard correctness reason not to be.

The confirmation is **three redundant signals**:

1. **Haptic** `successNotification()` — perceivable with the phone in a pocket or a bag, eyes on the lamb.
2. **A persistent SnackBar** with the committed fact and an Undo. Since Flutter 3.38 an action-bearing SnackBar no longer auto-dismisses, which is exactly right: it stays until acknowledged.
   ```dart
   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
     // persist defaults to "stay because there is an action" since 3.38.
     content: Text('412 · triplets · 03:24', style: theme.textTheme.bodyLarge),
     action: SnackBarAction(label: 'UNDO', onPressed: () => repo.undo(id)),
     duration: const Duration(days: 1),   // belt and braces
   ));
   ```
   `SnackBarAction` must be ≥60pt tall — override it in `snackBarTheme` or use a custom overlay; the default Material `SnackBarAction` is not.
3. **A visible state change in the underlying list.** The ewe moves to the top of the recents strip; her card gains today's event. This is the only signal that is still true five seconds later, and it is the one that proves the *database* changed rather than a toast being shown.

**Undo is the replacement for swipe-to-delete.** The spec bans swipe-to-delete; a persistent Undo on a 60pt target gives back the recoverability without the gesture. And it satisfies spec §12.4 ("never silently correct") — Undo removes the record the user just made, it never rewrites it.

---

## 11. One-handed reachability

Hoober's 1,333-observation field study ([UXmatters, 2013](https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php)) found, among people actually touching the screen: **49% one-handed, 36% cradled, 15% two-handed**; of one-handed users, **67% right thumb, 33% left**; **90% portrait**. He also cautions that people "change the way they're holding their phone very often — sometimes every few seconds", so a rigid thumb-arc model over-claims.

For Shed Book the distribution collapses: spec §5 says **one hand, always**, because the other hand is holding a lamb. So design for the 49% case exclusively and treat two-handed as a bonus.

**Layout rules:**

1. **Every primary action lives in the bottom third.** A persistent bottom action bar, ≥88pt tall plus safe-area inset, on Quick Entry, Lambing Entry, Foster and Pen Board.
2. **A top-right save button is wrong here, and it is worth being explicit about why.** The top-right corner is the *furthest* point from a right thumb's pivot on a modern 6.1–6.7" phone; reaching it requires either a two-handed grip or a hand-shuffle that risks dropping the phone. Both platforms' conventions put "Done" there (iOS navigation bars, Material `AppBar` actions), so this is a deliberate departure from platform convention — justified because the platform convention assumes two free hands and a warm, dry environment. **Do not fight it with iOS Reachability**: it is a system gesture (a swipe/tap on the home indicator) that the user must have enabled, and it is exactly the sort of tracked gesture that fails through a bag.
3. **The top of the screen is for information only** — the ewe's tag, the timestamp, the "3 seasons · avg 2.0" summary line from spec §7.7. Read-only content is fine up there because reading does not require reaching.
4. **Back navigation is a bottom-bar button**, not only the AppBar chevron or the Android system back. Predictive back (default since 3.38) is an *edge-swipe*, i.e. a tracked gesture — keep it working, but never make it the only route.
5. **Modal sheets over full-screen pages.** A `showModalBottomSheet` anchors its content to the bottom, i.e. to the thumb. Full-screen routes push content upward. Use bottom sheets for foster, ease-score, birth-type, death-cause — all the short pick-one flows. Set `showDragHandle: false` (a drag handle implies a banned gesture) and `isDismissible: false` with an explicit 72pt Cancel.
6. **`SnackBar` collides with the bottom bar.** Set `snackBarTheme.insetPadding` bottom to clear it (≥96), or the Undo target sits under your action bar.
7. **Mirror for left-handers.** One boolean in Settings flips the keypad's bottom row (§9.2) and the action bar's primary/secondary order. 33% of one-handed users is not an edge case.

---

## 12. Glanceability of the pen board

Spec §7.4: "Works as a glanceable board — legible from arm's length in a head torch." That is a ~60 cm viewing distance in a narrow, high-contrast pool of light.

**Type scale.** At 60 cm, the limiting factor is angular size. A 40pt numeral on a ~460 ppi phone is about 5.5 mm tall, subtending roughly 0.5° — about 5× the acuity threshold for a normally-sighted eye at high contrast, which is a sane margin for a tired one under a torch. So:

- Pen tag number: `displaySmall` (40pt, w700, **tabular figures**).
- Hours-since-penned: 32pt, w700, tabular. *This is the number the board exists to show* and it must be the second-largest thing on the tile.
- Everything else on a tile: 18pt.
- A tile shows **at most three facts**. Tag, hours, status. Lamb count goes on the detail view.

**Colour-plus-shape redundancy — non-negotiable.** WCAG SC 1.4.1 (Level A):

> "Color is not used as the only visual means of conveying information, indicating an action, prompting a response, or distinguishing a visual element."
> — [W3C](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html)

Three independent reasons this binds harder than usual here:

1. Colour-vision deficiency affects roughly 1 in 12 men — and this user base skews male.
2. **Red-shift mode destroys the colour channel entirely.** Green/amber/salmon all become reds (§4.2). A board that encodes status only in colour is *unreadable* in the mode we shipped for exactly this environment.
3. A head torch's colour temperature shifts perceived hue.

So every pen status carries **three** encodings:

| Status | Colour | Shape | Text |
|---|---|---|---|
| Settling (< threshold) | `textSecondary` | plain tile, no border | `4h` |
| **Ready to turn out** (≥ user threshold, §7.4) | `statusReady` | **thick 3pt left bar + filled corner triangle** | `26h · READY` |
| Needs attention (treatment due, withdrawal active) | `statusAttention` | **dashed outline** | `12h · TREATING` |
| Loss recorded | `statusLoss` | **diagonal hatch fill** | `DEAD` |

The shape encodings must be *structurally different* (border weight, outline style, fill pattern, corner marker), not four variants of one glyph — under a torch at 60 cm, four similar icons are one icon.

**Reflow, don't clip.** The tile grid is `LayoutBuilder`-driven on a minimum tile width that itself scales with `MediaQuery.textScalerOf(context).scale(40)`. At 200% text the board goes to one or two columns and scrolls. That is correct: a shepherd who needs 200% text needs a bigger `26h`, not a board that still fits four across with clipped numbers.

**Timers are computed at build, from a ticking clock, and never cached.** "Hours since penned" is derived from `entered_at` and `DateTime.now()`. Drive it with a single app-level `Stream.periodic(Duration(minutes: 1))` rather than a timer per tile.

**Spec §12.5 (honest timestamps) shows up here.** A pen entry time that was edited must be visibly marked on the tile — a small `~` prefix or an "edited" chip — not just on the detail screen. The board is what people trust; the board must not launder an edited time as a captured one.

---

## Rejected alternatives

| Rejected | In favour of | Why it lost |
|---|---|---|
| `ColorScheme.fromSeed` | Hand-authored `ColorScheme` × 3 | Flutter 3.41 changed four generated colours as a breaking change. Generated schemes cannot be given a contrast floor, and the red-shift palette is not a tonal palette at all. (§1.3) |
| `ThemeMode.system` with a light + dark pair | `ThemeMode.dark`, `theme == darkTheme` | Any code path that can produce a light frame is a code path that can blind the user. (§2.1) |
| Pure `#000000` base surface | `#0B0D0E` for `night`; `#000000` only for `redShift` | Keeps ~95% of the emission benefit, gains a surface elevation ramp, avoids black-smear/halation. Both positions are defensible; this one is reversible with a one-line token change. (§2.3) |
| Material's `#121212` | `#0B0D0E` | `#121212` is tuned for a *content* app on an OLED phone in a lit room. In a dark shed the extra 2% emission buys nothing. (§2.3) |
| Global `ColorFiltered` for red-shift | Third palette + local filter on photos only | Full-screen `saveLayer` every frame; destroys per-token contrast; collapses the pen board's status colours into one hue. (§4.2) |
| Fragment shader for red-shift | Same | `ImageFilter.shader` is Impeller-only and there is no subtree-shader API; same contrast problems as the filter, plus a GLSL asset to maintain. (§4.2) |
| `screen_brightness` (2.1.11, 2026-06-16, **unverified uploader**) to dim in red-shift | Bake dimness into the red palette | An unverified-publisher plugin with platform code, to change a system-level property the user did not ask us to change. The palette achieves the same emission reduction with zero dependencies. |
| `flutter_native_splash` 2.4.8 | Hand-written native config | ~25 lines of XML/plist vs a generator that owns files we want to review; maintainer publicly seeking a new owner since March 2026. (§5.5) |
| `custom_lint` 0.8.1 for the token gate | `tool/check_tokens.dart` | Upstream repo archived 2026-03-24; pinned to `analyzer ^8.0.0` vs current 14.1.0. A build-blocking dev tool must not be the thing that rots. (§3.3) |
| `google_fonts` 8.2.0 | Bundled Atkinson Hyperlegible Next TTF | Depends on `http`; default behaviour is a runtime network fetch. Categorically wrong in a no-INTERNET app. (§8.3) |
| System numeric keyboard for tag entry | Custom `ShedKeypad` | Key size fixed below our floor; `1` at the top of the screen on iOS; consumes half the viewport; no domain keys; Android IME appearance uncontrollable. (§9.1) |
| Volume-button shortcuts | Home-screen quick actions + recents strip | App Store 2.5.9 rejects altering volume switches; Android-only asymmetry destroys muscle memory; breaks silencing the phone in a shed at night. (§7.3) |
| Swipe-to-delete + drag-to-reorder | Explicit tap flows + persistent Undo | Tracked gestures fail with a marginal capacitive contact; destructive and invisible. Spec §5 bans them and the physics agrees. (§7.2) |
| Audio confirmation in v1 | Haptic + persistent SnackBar + list mutation | Inaudible at a polite volume, disruptive at a useful one; needs a new plugin with platform code. Revisit after the field night. (§10.2) |
| Clamping `textScaler` to keep layouts tidy | Reflowing layouts, no cap | Defeats Android 14's non-linear curve; Flutter's own migration doc says don't. (§8.2) |
| Third-party M3 Expressive packages | Plain Material 3 + our tokens | Flutter is not shipping Expressive; the app has no need for expressive motion; the material library is being decoupled anyway. (§1.4) |
| `AnimatedTheme` cross-fade on theme switch | Instant swap | Drags every colour through a low-contrast desaturated midpoint; violates "zero interruptions". (§4.3) |

---

## Pitfalls

**P1 — A light frame leaks in from a layer nobody tested.**
There are seven surfaces that default to white: Android `LaunchTheme`, Android `NormalTheme`, Android 12+ `windowSplashScreenBackground`, iOS `LaunchScreen.storyboard`, iOS `Main.storyboard` root view, `MaterialApp.color`, `Scaffold.backgroundColor`. Plus the predictive-back transition gutter (3.44's `fallbackColor`).
*Mitigation:* one `#0B0D0E` constant duplicated into every one of those places, and a manual cold-launch check in a genuinely dark room on both platforms as a release-checklist item. A screenshot test will not catch it — the flash is on the native side, before Flutter runs.

**P2 — `values-night/` reintroduces a light launch background.**
The Android dark-theme guide tells you to use `?android:attr/colorBackground` so the splash follows the system theme. For a dark-only app that is exactly wrong: a phone in light mode then launches white.
*Mitigation:* no `values-night/` folder; literal dark colour in `values/`; `android:forceDarkAllowed="false"`.

**P3 — INTERNET permission arrives transitively.**
Flutter's generated `src/debug/` and `src/profile/` manifests declare INTERNET. A plugin can also merge it. Then the "no network path" property is silently false in release.
*Mitigation:* CI job that inspects the **merged release manifest** in the AAB and fails on `android.permission.INTERNET`. Also fail on `ACCESS_NETWORK_STATE`.

**P4 — `MaterialTapTargetSize.padded` is mistaken for the 60pt rule.**
It is 48. Reviewers see `padded` in the theme and assume the floor is enforced.
*Mitigation:* the `shedTapTargetGuideline` widget test on every screen, and `ShedTapTarget` as the only sanctioned way to make something tappable.

**P5 — `Expanded` inside a `Row` silently shrinks a keypad key below 60pt on a small device.**
`Expanded` overrides `minWidth`. On a 320pt-wide phone, three 72pt keys plus two 16pt gaps needs 248pt — fine — but add horizontal page padding of 24 each side and it's 272 of 272. One more token bump and keys go under-size with no error.
*Mitigation:* the 200%-text widget test at the smallest supported size (320×568), asserting `shedTapTargetGuideline`. Consider `IntrinsicWidth`/explicit `SizedBox` rather than `Expanded` for the keypad specifically.

**P6 — Red-shift is judged by a screenshot on a bright desk monitor.**
It will look wrong. Red-shift is only assessable in an actually dark room by an actually dark-adapted eye, after ~10 minutes.
*Mitigation:* explicit acceptance procedure — sit in the dark for ten minutes, then open the app. Anyone reviewing red-shift colour choices from a screenshot is not reviewing red-shift.

**P7 — Theme switch animation blocks or flickers.**
`MaterialApp` wraps in `AnimatedTheme` (200ms default). Switching night→red-shift drags through a desaturated midpoint.
*Mitigation:* set `ShedTokens.motion` to zero for the switch; honour `MediaQueryData.disableAnimations` globally.

**P8 — A ewe tag renders with proportional figures somewhere.**
`FontFeature.tabularFigures()` lives on `TextStyle.fontFeatures`, and any `copyWith` that constructs a fresh `TextStyle` instead of copying loses it. The pen board then jitters.
*Mitigation:* never construct a bare `TextStyle` for numerals — go through the `TextTheme` roles, which carry the feature. Add a golden test on the pen board.

**P9 — Contrast is verified with WCAG 2.x maths and assumed sufficient.**
The APCA authors state WCAG 2.x "cannot be used for guidance designing 'dark mode'" because it overstates contrast near black.
*Mitigation:* use WCAG 2.x as a **floor** (it is what `textContrastGuideline` checks, and it is what accessibility auditors will ask for), but do the acceptance test with human eyes in a dark room. Do not treat "16:1, passes AAA" as proof of legibility.

**P10 — `boldText` doubles up with an already-heavy scale.**
Our base weights are already one step above M3. `boldText` adds another 100, so `labelLarge` w700 → w800. AH Next's axis tops out at 800, so it clamps rather than breaking — but on a font with a 700 ceiling it would silently synthesise.
*Mitigation:* the `.clamp(100, 900)` in `buildShedTextTheme`, plus a visual check at max weight.

**P11 — UIScene auto-migration breaks the launch storyboard.**
The 3.38/3.41 UIScene migration adds `UISceneStoryboardFile = Main`. It is easy to conflate that with `UILaunchStoryboardName` and delete the wrong one, producing a white default launch screen — an App Store rejection *and* a flashbang.
*Mitigation:* after the first `flutter build ios` on this toolchain, diff `Info.plist` and assert both keys are present.

**P12 — The free-tier cap (spec §14, ~15 ewes) degrades the 3am flow.**
The spec says the cap "must not degrade the 3am experience". A modal paywall at the moment of creating ewe #16, at 03:20, is the single worst thing this app could do.
*Mitigation:* the cap blocks *creation*, never *recording*. It surfaces as a persistent, non-modal banner on the Flock screen well before the limit, and the block itself is `errorNotification()` + an inline message on the keypad's confirm key — never a dialog, never on the Quick Entry path if it can be avoided.

**P13 — Someone adds a `Tooltip`.**
`Tooltip` is triggered by long-press on touch — a banned interaction, and its content is invisible to a user who can't discover it.
*Mitigation:* add `Tooltip` to the `check_tokens.dart` banned list alongside `Dismissible` and `Draggable`.

**P14 — Impeller renders the authored hexes differently after 3.44's P3→sRGB fix.**
PR 181720 changed P3-to-sRGB conversion to operate in linear light. On wide-gamut displays the palette may shift slightly versus 3.41.
*Mitigation:* re-verify the palette on a real wide-gamut device after any SDK bump; the contrast unit test operates on the source hexes and will *not* catch a rendering shift.

---

## How this serves the 3am test and the offline-only constraint

**Offline-only.** Nothing in this document introduces a network path:

- No `google_fonts` (which would). The font is a 114 KB OFL file in `assets/`.
- No dynamic colour from a server, no remote theme, no A/B config.
- `flutter_native_splash` rejected — and it was a `dev_dependency` anyway.
- `custom_lint` rejected — the token gate is a `dart:io` script.
- `screen_brightness` rejected.
- The only runtime dependencies this topic adds are **zero**. Everything is `package:flutter` plus one TTF.
- The recommended CI check actively *defends* the property by failing the build if `android.permission.INTERNET` appears in the merged release manifest.

**The 3am test.** Mapping the decisions back to spec §5:

| §5 clause | Served by |
|---|---|
| One thumb, one hand | §11 bottom-anchored actions; bottom sheets; left-handed mirror; no top-right save |
| 60×60 pt minimum; no swipe/drag/long-press/pinch/force-touch | §6 token-enforced scale with a `MinimumTapTargetGuideline(Size(60,60))` test; §7.2 evidence-backed gesture ban; §3.3 regex gate on `Dismissible`/`Draggable`/`onLongPress`/`onScaleUpdate` |
| Cold fingers, poor capacitance | §6.2 72/88pt primaries justified from Parhi and the motor-control study; §6.3 hit slop; 16pt gaps; §7.1 in-app guidance to Samsung/Pixel touch-sensitivity settings |
| Head torch or darkness; dark default; no white flash; optional red-shift; ≥18pt body | §2 dark-only at every layer; §5 four-layer launch config; §4 a real third palette that is red *and dim*; §8 an 18pt floor with `bodySmall` deleted |
| Under fifteen seconds | §5.4 no artificial splash delay, synchronous settings read; §9 keypad + recents on one screen with no keyboard animation |
| Zero interruptions | §10.2 no audio; §4.3 instant theme switch; §12 (Pitfall P12) no modal paywall on the entry path |
| Assume the phone dies | §10.3 commit-then-confirm, never optimistic UI; three redundant proofs of commit |

**And the safety rules (§12).** Two of them are UI obligations this document discharges: honest timestamps must be visible **on the pen board tile**, not just the detail screen (§12 of this doc); and "never silently correct" is why validation surfaces as a `warningNotification()` + a visible flag rather than an auto-fix, and why Undo (removes) replaces swipe-to-delete (hides).

---

## Sources

Every URL below was fetched on 2026-07-27.

**Flutter — release, breaking changes, API**
- https://docs.flutter.dev/release/release-notes
- https://docs.flutter.dev/release/release-notes/release-notes-3.44.0
- https://docs.flutter.dev/release/breaking-changes
- https://docs.flutter.dev/release/breaking-changes/material-color-utilities
- https://docs.flutter.dev/release/breaking-changes/font-weight-variation
- https://docs.flutter.dev/release/breaking-changes/uiscenedelegate
- https://docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update
- https://docs.flutter.dev/release/breaking-changes/splash-screen-migration
- https://docs.flutter.dev/release/breaking-changes/android-14-nonlinear-text-scaling-migration
- https://docs.flutter.dev/release/breaking-changes/material-3-default
- https://raw.githubusercontent.com/flutter/flutter/stable/CHANGELOG.md
- https://raw.githubusercontent.com/flutter/flutter/stable/packages/flutter/lib/src/material/typography.dart
- https://raw.githubusercontent.com/flutter/flutter/stable/engine/src/flutter/shell/platform/android/io/flutter/plugin/platform/PlatformPlugin.java
- https://raw.githubusercontent.com/flutter/flutter/stable/engine/src/flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformPlugin.mm
- https://api.flutter.dev/flutter/material/ColorScheme-class.html
- https://api.flutter.dev/flutter/material/ThemeExtension-class.html
- https://api.flutter.dev/flutter/material/ThemeExtension/lerp.html
- https://api.flutter.dev/flutter/material/ThemeData/extensions.html
- https://api.flutter.dev/flutter/material/kMinInteractiveDimension-constant.html
- https://api.flutter.dev/flutter/cupertino/kMinInteractiveDimensionCupertino-constant.html
- https://api.flutter.dev/flutter/material/MaterialTapTargetSize.html
- https://api.flutter.dev/flutter/material/ButtonStyle-class.html
- https://api.flutter.dev/flutter/widgets/WidgetStateProperty-class.html
- https://api.flutter.dev/flutter/widgets/MediaQueryData-class.html
- https://api.flutter.dev/flutter/widgets/MediaQuery/textScalerOf.html
- https://api.flutter.dev/flutter/painting/TextScaler-class.html
- https://api.flutter.dev/flutter/services/HapticFeedback-class.html
- https://api.flutter.dev/flutter/services/SystemSound-class.html
- https://api.flutter.dev/flutter/services/SystemSoundType.html
- https://api.flutter.dev/flutter/services/SystemChrome/setSystemUIOverlayStyle.html
- https://api.flutter.dev/flutter/widgets/ColorFiltered-class.html
- https://api.flutter.dev/flutter/dart-ui/ColorFilter/ColorFilter.matrix.html
- https://api.flutter.dev/flutter/dart-ui/FontFeature-class.html
- https://api.flutter.dev/flutter/material/TextField/keyboardAppearance.html
- https://api.flutter.dev/flutter/flutter_test/AccessibilityGuideline-class.html
- https://api.flutter.dev/flutter/flutter_test/MinimumTapTargetGuideline-class.html
- https://docs.flutter.dev/perf/best-practices
- https://docs.flutter.dev/perf/impeller
- https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility
- https://docs.flutter.dev/ui/design/text/typography
- https://docs.flutter.dev/ui/design/graphics/fragment-shaders
- https://docs.flutter.dev/platform-integration/android/splash-screen
- https://docs.flutter.dev/platform-integration/ios/launch-screen
- https://github.com/flutter/flutter/issues/168813
- https://github.com/flutter/flutter/issues/71568
- https://github.com/flutter/samples/tree/main/android_splash_screen

**pub.dev (versions and dates verified via `pub.dev/api/packages/<name>`)**
- https://pub.dev/packages/flutter_native_splash — 2.4.8, 2026-05-29
- https://pub.dev/packages/flutter_native_splash/versions
- https://pub.dev/api/packages/flutter_native_splash
- https://pub.dev/packages/google_fonts — 8.2.0, 2026-07-15
- https://pub.dev/packages/custom_lint — 0.8.1, 2025-09-09
- https://pub.dev/packages/custom_lint/changelog
- https://pub.dev/packages/flutter_lints — 6.0.0, 2025-05-27
- https://pub.dev/packages/screen_brightness — 2.1.11, 2026-06-16
- `pub.dev/api/packages/analyzer` — 14.1.0, 2026-07-13
- `pub.dev/api/packages/lints` — 6.1.0, 2026-01-30
- https://github.com/invertase/dart_custom_lint/issues (+ GitHub API: `archived: true`, pushed 2026-03-24)
- https://github.com/jonbhanson/flutter_native_splash/issues
- https://github.com/jonbhanson/flutter_native_splash/issues/821

**Apple**
- https://developer.apple.com/design/tips/
- https://developer.apple.com/app-store/review/guidelines/ (2.5.1, 2.5.3, **2.5.9**)

**Android / Material**
- https://developer.android.com/guide/topics/ui/accessibility/apps
- https://developer.android.com/develop/ui/views/launch/splash-screen
- https://developer.android.com/develop/ui/views/theming/darktheme
- https://developer.android.com/reference/android/view/KeyEvent
- https://m3.material.io/blog/android-dark-theme-tutorial
- https://www.samsung.com/ca/support/mobile-devices/activate-touch-sensitivity-on-your-samsung-galaxy/

**W3C / accessibility standards**
- https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
- https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
- https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced.html
- https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html
- https://git.apcacontrast.com/documentation/APCA_in_a_Nutshell.html

**Vision science and HCI research**
- https://www.ncbi.nlm.nih.gov/books/NBK545246/ — StatPearls, *Physiology, Night Vision*
- https://www.webvision.pitt.edu/book/part-viii-gabac-receptors/light-and-dark-adaptation/ — Webvision, *Light and Dark Adaptation*
- https://www.microsoft.com/en-us/research/publication/target-size-study-for-one-handed-thumb-use-on-small-touchscreen-devices/ — Parhi, Karlson & Bederson, MobileHCI 2006
- https://pmc.ncbi.nlm.nih.gov/articles/PMC3572909/ — Touch screen performance with and without motor control disabilities
- https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php — Hoober, 1,333 observations

**Fonts**
- https://www.brailleinstitute.org/freefont/
- https://github.com/googlefonts/atkinson-hyperlegible (OFL 1.1)
- https://github.com/google/fonts/tree/main/ofl/atkinsonhyperlegiblenext
- https://raw.githubusercontent.com/google/fonts/main/ofl/atkinsonhyperlegiblenext/METADATA.pb
- `AtkinsonHyperlegibleNext[wght].ttf` — downloaded and GSUB table byte-inspected on 2026-07-27; features: `aalt ccmp case frac locl ordn pnum sups tnum`
- https://github.com/rsms/inter (OFL 1.1, `tnum` + slashed zero)

**Touch hardware**
- https://focuslcds.com/journals/using-capacitive-touch-panels-with-gloves/ — vendor engineering note (~5 mm glove limit). *Trade note, not peer-reviewed.*

**Sources consulted but not usable as evidence**
- `apps.dtic.mil/sti/tr/pdf/ADA148883.pdf` (Naval Submarine Medical Research Laboratory, red vs white lighting and dark adaptation) — **HTTP 403**, could not fetch. The "intensity matters more than colour" finding in §4.1 is reported from secondary summaries of this and related DTIC reports and is therefore **medium confidence**; obtain the primary PDF before treating it as settled.
- `m2.material.io/design/color/dark-theme.html`, `developer.apple.com/design/human-interface-guidelines/*`, `m3.material.io/foundations/*` — JavaScript-rendered; WebFetch returned titles only. Material's `#121212` guidance and Apple's 44pt figure in §2.3/§6.1 are corroborated from `developer.apple.com/design/tips/`, `m3.material.io/blog/android-dark-theme-tutorial`, and search-surfaced quotations rather than direct fetches of those specific pages.
- Blog/Medium sources on OLED black smear and halation — treated as leads only; the §2.3 claims about smear and halation are marked *plausible, unverified*.

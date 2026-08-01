# 06 — Design system

This document governs the *structure* of Shed Book's design system: how themes, tokens, type, tap targets, feedback and the shared components are organised, and which of those rules CI enforces. It does not choose the visual direction — three candidate directions are specced in `../design/00-directions.md`, and this system is built so any of them drops in by replacing constants, never by replacing structure. You need this document before you write your first widget, and again every time you are tempted to type a hex.

**Toolchain.** Flutter **3.44.8** stable, Dart **3.12.2**, pinned via FVM (decision #1). Every API in this document was checked against that SDK; where a name is easy to mistype the check is noted inline. Versions come only from decision-record §5 — never from memory.

> **Decisions applied:** #94 hand-authored `ColorScheme` · #95 four theme slots, all dark, real high-contrast slot · #96 night mode ships amber **and** deep red, labelled honestly · #97 two-tier tokens via one `ThemeExtension` · #98 18 pt body floor, bundled Atkinson Hyperlegible Next, w700 weight cap · #99 never clamp `textScaler`, `textScaleFactor` banned everywhere · #100 60×60 pt tap floor + a second geometric gate · #101 gesture ban · #103 commit-then-confirm with three channels · #104 `headingLevel`, never `header:` · #105 the `reduceMotion` OR-resolver · #106 colour is never the only channel · #10 one CI gate (`tool/check_policy.dart`) · #14 dark `ErrorWidget.builder` · #21 first frame is a static dark Quick Entry shell · #57 the in-app keypad is used for weights too · #66 one app-level 60 s ticker · #71 empty states occupy the content box · #92 the upgrade affordance is two static rows and never a modal · #127 bundled assets < 5 MB.
>
> **Owner rulings applied (decision-record §7.0), none of them open:** tag OCR and voice tag entry are **cut from v1**, so the keypad in §8 is the only tag-entry route this document designs for; tags are unique among **active** animals only; region one is **UK / Ireland** — `en_GB`, kg, °C, 24-hour clock, `dd/MM/yyyy`, week starts Monday, ambiguous DST hour 01:00–01:59, AHDB lambing-percentage convention; the free tier is **season-primary, ewe cap secondary, never mid-entry, never between 22:00 and 06:00** (§12).

---

## 1. What this document fixes, and what a visual direction may change

| Fixed here — a direction may not change it | Free — a direction owns it |
|---|---|
| Token **names** and the two-tier structure | Token **values** (hexes, radii, tile proportions) |
| Contrast **floors** and the requirement that every pair is computed and tested | Which hue carries which status |
| The 60 / 72 / 88 pt tap scale and the 16 / 32 pt gaps | Slab, strip, row or key as the visual form of a target |
| The 18 pt body floor, the w700 cap, tabular figures for aligned numerals | The type *faces*, the display sizes above 18, tracking, casing |
| Dark-only at every layer; the four-layer launch recipe | The base surface hex, provided it is no brighter than `#0B0D0E` |
| The gesture ban and the keypad's geometry contract | Key legends, bevel/rule/border ornament |
| The haptic vocabulary and commit-then-confirm | The visual form of the receipt |
| Colour + shape + text redundancy on every status | Which shapes |

If a direction needs a token this system does not have, add the token to `ShedTokens` — do not add a literal to a widget.

---

## 2. Theming: dark is the primary theme, not the fallback

### 2.1 Rule — there is no light theme, and no code path can produce one

`ThemeMode.system` with a light/dark pair is a flashbang at 3am. Set every slot, pin the mode, and make the light branch unreachable rather than unlikely.

```dart
// lib/core/ui/theme.dart
/// The pair every palette resolves to. `highContrast` is a genuinely different
/// palette, never the same object as `theme` (decision #95).
typedef ShedThemeSet = ({ThemeData theme, ThemeData highContrast});
```

```dart
// lib/app.dart — the theme half of the file.
// 01-architecture.md §6 owns main() and the post-frame boot kick;
// 02-state-di-navigation.md owns themeProvider, Routes and the
// WidgetsBindingObserver on this State. main() constructs this widget as
// `const ShedBookApp()`, so it takes no theme parameters.
//
// It is a ConsumerStatefulWidget, not a ConsumerWidget (CONVENTIONS R34):
// 01 §6.3 needs initState for the post-frame boot kick and 02 §9.1 needs
// WidgetsBindingObserver on the State. This document owns the theme half of
// build(), never the widget's kind.
class ShedBookApp extends ConsumerStatefulWidget {
  const ShedBookApp({super.key});

  @override
  ConsumerState<ShedBookApp> createState() => _ShedBookAppState();
}

class _ShedBookAppState extends ConsumerState<ShedBookApp>
    with WidgetsBindingObserver {
  // initState, dispose and didChangeAppLifecycleState belong to 01 §6.3 and
  // 02 §9.1 and are not restated here.

  @override
  Widget build(BuildContext context) {
    // themeProvider is a SYNCHRONOUS Provider<ShedThemeSet>, never an
    // AsyncValue and never awaited: the first frame paints before the database
    // is open (decision #21). Until settingsProvider emits, it returns the
    // const `night` pair. Because every palette is dark, the later swap to the
    // user's palette is invisible rather than a flash.
    final ShedThemeSet t = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Shed Book',
      navigatorKey: Routes.navigatorKey,
      // Both brightness slots hold the same object: no Brightness change,
      // no Theme widget in a test harness, no platform event can select light.
      theme: t.theme,
      darkTheme: t.theme,
      // iOS "Increase Contrast" swaps to these. On Android the flag never
      // fires, so the same object is also reachable from Settings (§4.5).
      highContrastTheme: t.highContrast,
      highContrastDarkTheme: t.highContrast,
      themeMode: ThemeMode.dark,
      // Painted by the framework behind the app before the first route paints.
      color: t.theme.scaffoldBackgroundColor,
      // Theme changes are instant: a 200 ms lerp between night and deep red
      // drags every colour through a desaturated, low-contrast midpoint.
      themeAnimationDuration: Duration.zero,
      home: const QuickEntryScreen(),
    );
  }
}
```

**Banned, with a grep each (§3.5):** `ThemeMode.system`, `ThemeMode.light`, `Brightness.light`, `MediaQuery.platformBrightnessOf`, `ColorScheme.light`, `ThemeData.light`, `ColorScheme.fromSeed`.

Why `fromSeed` is banned rather than merely discouraged: Flutter 3.41 changed `onPrimaryContainer`, `onSecondaryContainer`, `onTertiaryContainer` and `onErrorContainer` for every generated scheme. Here legibility is a safety property, not a brand property, and you cannot ask a seed for "≥ 12:1 on the base surface" (decision #94).

### 2.2 `buildShedTheme` — the defaults M3 gets wrong for this app

```dart
// lib/core/ui/theme.dart
ThemeData buildShedTheme(ShedPalette p) {
  final ShedTokens t = p.tokens;
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: p.colorScheme,          // hand-authored literal, see §4
    extensions: <ThemeExtension<dynamic>>[t],
    scaffoldBackgroundColor: t.surfaceBase,
    canvasColor: t.surfaceBase,

    // MaterialTapTargetSize.padded is 48, not 60. It is a floor under our
    // floor, not the rule: the 60 pt contract comes from ShedTapTarget (§6).
    materialTapTargetSize: MaterialTapTargetSize.padded,
    // adaptivePlatformDensity is negative on some platforms and silently
    // subtracts up to 4 px per axis from every Material control. Pin it.
    visualDensity: VisualDensity.standard,
    splashFactory: InkSparkle.splashFactory,

    textTheme: buildShedTextTheme(t),    // §5
    filledButtonTheme: FilledButtonThemeData(style: shedPrimaryButtonStyle(t)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: shedSecondaryButtonStyle(t)),
    iconButtonTheme: IconButtonThemeData(style: shedIconButtonStyle(t)),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: t.surfaceRaised,
      contentTextStyle: TextStyle(fontSize: t.bodySize + 2, color: t.textPrimary),
      // Clear the persistent bottom action bar or the Undo target sits under it.
      insetPadding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      // 0 => the action always wraps to its own full-width line, which is the
      // only way SnackBarAction gets near the 60 pt floor. Verified by the
      // tap-target guideline test, not by inspection (§10.3).
      actionOverflowThreshold: 0,
    ),

    // Predictive back is the default Android page transition on this SDK and
    // paints a gutter behind the outgoing page. Without fallbackColor that
    // gutter is the platform default — i.e. light.
    // The class name is PredictiveBackPageTransitionsBuilder — plural
    // "Transitions". `PredictiveBackPageTransitionBuilder` does not exist and
    // is the single easiest compile error to make in this file.
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      TargetPlatform.android:
          PredictiveBackPageTransitionsBuilder(fallbackColor: t.surfaceBase),
      TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
    }),
  );
}
```

### 2.3 The hand-authored `ColorScheme`

Widgets in this app read `ShedTokens`, never `ColorScheme` (§3) — so why author a `ColorScheme` at all? Because **Material's own widgets read it and there is no way to stop them**: `SnackBar`, `AlertDialog`, the text-selection handles and toolbar, `InkSparkle`, the `GlobalMaterialLocalizations` date and time pickers, `Scrollbar`, and every `ThemeData` sub-theme fallback. If it is not authored it is generated, and `ColorScheme.fromSeed` is banned by decision #94. So every scheme is a literal constructor call, one per palette, sitting beside the token set it belongs to.

```dart
// lib/core/ui/palettes.dart  (allowlisted for raw primitives — §3.5)
// M3 requires nine roles; the rest are pinned because a Material widget WILL
// reach for one of them at 3am and the default is computed, not chosen.
const ColorScheme nightScheme = ColorScheme(
  brightness: Brightness.dark,

  // Primary = the surface a primary control paints with. Not a brand colour:
  // this app has no brand in the UI, only legibility.
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

  // Elevation tint blends the surface toward surfaceTint as elevation rises.
  // Setting it equal to the base surface makes that blend a no-op, because
  // elevation in this app is carried by the explicit surface ramp (§4.2),
  // not by an M3 overlay whose result nobody measured.
  surfaceTint: nSurface04,
);
```

Three rules bind every scheme:

1. **The deprecated roles are never set.** `background`, `onBackground` and `surfaceVariant` are deprecated on this SDK (`surface`, `onSurface`, `surfaceContainerHighest` replace them). Setting them is an analyzer info on `--fatal-infos`, which is a CI failure.
2. **Every `on*` / role pair in the literal carries its measured ratio in a trailing comment**, and `test/design/contrast_test.dart` recomputes the four that carry text — `onSurface`/`surface`, `onPrimary`/`primary`, `onSecondary`/`secondary`, `onError`/`error` (§3.5).
3. **`error` is Material's error role and nothing else.** It never doubles as `statusLoss`. Conflating them would paint a recorded death in the same pixels as a failed write, which is a spec §12.2 problem, not a palette problem.

### 2.4 The error widget renders outside any theme

`ErrorWidget.builder` (decision #14) may be invoked when no `Theme`, no `MediaQuery` and no `Directionality` is in scope, so it cannot read tokens and cannot read a `TextTheme` either. `NightErrorPanel` in `lib/core/ui/night_error_panel.dart` therefore hard-codes the base surface `#0A0A0B` (P14, N11-T04) and near-white text, supplies its own `Directionality`, and is the **one file exempted from the raw-colour rule** — allowlist line `lib/core/ui/night_error_panel.dart :: token.raw_color`. The default red-on-yellow `ErrorWidget` is a flashbang under a head torch; ours is the base surface, one line of near-white text, the route name, and exactly one action: *"Save a copy of my records"*. `01-architecture.md` §5.5 owns the panel and its widget test; this document owns only the colour it must use.

### 2.5 Accessibility flags the theme layer reads

| Flag | Where it works | What the design system does |
|---|---|---|
| `boldText` | iOS; Android 12+ | Nothing manual. `Text` merges `FontWeight.bold` itself. Our cap at w700 (§5.3) is what keeps that merge from making text *lighter*. |
| `highContrast` | **iOS only** | Selects the `highContrastTheme` slot. Because Android never sets it, the same palette is also a Settings row (§4.5). |
| `disableAnimations` (Android) / `reduceMotion` (iOS) | No overlap between platforms | One resolver, ORing both, feeding `ShedTokens.motion`. |
| `accessibleNavigation` | Both (iOS = VoiceOver **or** Switch Control) | Timing only: never auto-dismiss, never steal focus. **Never branch the layout on it.** |
| `invertColors` | iOS only | Not fought. Photos are never the sole carrier of meaning. |
| `textScaler` | Both | Never touched. §5.5. |

```dart
// lib/core/ui/motion.dart
/// The only correct cross-platform reduce-motion check on Flutter 3.44:
/// iOS never sets disableAnimations; Android never sets reduceMotion; and
/// MediaQueryData has no reduceMotion property at all. (Decision #105.)
bool prefersReducedMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;
```

**Banned:** reading only one of the two flags; `BackdropFilter`, frosted app bars and any translucency — Flutter 3.44 exposes no reduced-transparency flag, so the only safe answer is not to ship blur.

---

## 3. Two-tier tokens

### 3.1 File layout

The design system lives in **`lib/core/ui/`** — layer L1 in `01-architecture.md` §2.2, whose rule 7 already says a shared widget may import `lib/domain/` and `package:flutter/*` and may never import `lib/data/`, `lib/core/db/` or `package:drift/*`. There is no `lib/design/` folder; putting tokens anywhere else would create a ninth layer the dependency script does not know about.

```
lib/core/ui/
  primitives.dart        # raw hexes + raw scales. Imported ONLY inside lib/core/ui/.
  tokens.dart            # ShedTokens extends ThemeExtension<ShedTokens>. The public surface.
  palettes.dart          # the six authored (ColorScheme, ShedTokens) pairs
  theme.dart             # ShedThemeSet, buildShedTheme, buildShedTextTheme
  motion.dart            # prefersReducedMotion
  formatters.dart        # date/number formatting at the presentation edge
  feedback.dart          # confirmSaved · showFailure · showCapRow  (§10.3)
  night_error_panel.dart # dark ErrorWidget.builder (raw-colour exemption, §2.4)
  components/            # ShedTapTarget, ShedKeypad, ShedPenTile … tokens only.
```

**Every shared component lives here, not under a feature.** `01-architecture.md` §2.2's tree sketched `big_keypad.dart` under `features/quick_entry/widgets/`; that placement cannot survive layer rule 6, because Lambing Entry, Treatments and Settings all need the same pad and a feature may never import a sibling. CONVENTIONS R70 settles it: the file is `lib/core/ui/components/shed_keypad.dart` and `big_keypad.dart` does not exist. The keypad, the tap target, the pen tile, the receipt bar and everything else in §12 are `lib/core/ui/components/`. A widget that only ever appears on one screen stays in that feature's `widgets/`.

Dart cannot make `primitives.dart` private to a directory, so the gate does: `tool/check_policy.dart` fails any import of `core/ui/primitives.dart` from outside `lib/core/ui/`.

### 3.2 Tier 1 — primitives are value-named and meaning-free

```dart
// lib/core/ui/primitives.dart
// Raw values only. Nothing outside lib/core/ui/ imports this file.
// Every hex carries its measured WCAG ratio on the surface it is designed for;
// test/design/contrast_test.dart recomputes all of them.
import 'dart:ui' show Color;

// ---- night neutral ramp ----------------------------------------------------
const nSurface04  = Color(0xFF0A0A0B); // base   (L = 0.00306) — P14, N11-T04
const nSurface08  = Color(0xFF12161A); // raised
const nSurface12  = Color(0xFF1A2025); // pressed
const nSurface18  = Color(0xFF242B31); // fill
const nInk40      = Color(0xFF8A9199); //  6.11:1 on base — chrome only
const nInk72      = Color(0xFFB7BDC4); // 10.29:1
const nInk92      = Color(0xFFE8EAED); // 16.16:1
const nInk100     = Color(0xFFFFFFFF); // 19.48:1 — numerals

// ---- night accents ---------------------------------------------------------
const nGreen70    = Color(0xFF7DD3A0); // 10.85:1
const nAmber70    = Color(0xFFFFD54F); // 13.80:1
const nSalmon80   = Color(0xFFFFB4AB); // 11.47:1

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

// ---- deep-red night-shift ramp (base #000000) ------------------------------
const rSurface00  = Color(0xFF000000);
const rSurface04  = Color(0xFF1A0503);
const rSurface08  = Color(0xFF2A0806);
const rRed75      = Color(0xFFFF9E80); // 10.45:1
const rRed60      = Color(0xFFFF6B4A); //  7.45:1
const rRed50      = Color(0xFFFF4400); //  6.08:1
const rRed40      = Color(0xFFE62200); //  4.59:1
const rRed30      = Color(0xFFCC2200); //  3.80:1 — outline / non-text only

// ---- high-contrast additions ----------------------------------------------
const hOutline    = Color(0xFF7A7A7A); //  4.89:1 on #000000
const hGreen      = Color(0xFFA8F0C6); // 15.94:1
const hAmber      = Color(0xFFFFE08A); // 16.28:1
const hSalmon     = Color(0xFFFFC7BD); // 14.16:1

// ---- spacing scale (logical pixels) ---------------------------------------
const s04 = 4.0, s08 = 8.0, s12 = 12.0, s16 = 16.0, s24 = 24.0, s32 = 32.0;

// ---- tap scale (logical pixels) -------------------------------------------
const tapMin     = 60.0; // spec §5 floor      ≈ 9.5 mm
const tapPrimary = 72.0; // keypad, tiles      ≈ 11.4 mm
const tapHero    = 88.0; // the five 3am acts  ≈ 14.0 mm
const gapMin     = 16.0;
const gapDestructive = 32.0;
```

### 3.3 Tier 2 — one `ThemeExtension`, flat

One extension, not five: `Theme.of(context).extension<T>()` is a map lookup per call, and a flat object is trivially diffable, lerpable and testable.

```dart
// lib/core/ui/tokens.dart
import 'package:flutter/material.dart';

/// The member and the stored key are the same string, so `app_settings.palette`
/// can be read off the enum and back (CONVENTIONS R35). 03's CHECK is
/// `IN ('night','amber','red')`; `deepRed`'s key is `'red'`.
enum ShedPaletteId {
  night('night'),
  amber('amber'),
  deepRed('red');

  const ShedPaletteId(this.key);
  final String key;
}

/// One authored palette: an M3 scheme for the framework's own widgets (§2.3)
/// and the token set every Shed Book widget actually reads. Six exist.
@immutable
final class ShedPalette {
  const ShedPalette({
    required this.id,
    required this.highContrast,
    required this.name,
    required this.colorScheme,
    required this.tokens,
  });

  final ShedPaletteId id;
  final bool highContrast;
  final String name;             // 'night', 'night-hc', 'amber', … — test group names
  final ColorScheme colorScheme;
  final ShedTokens tokens;
}

@immutable
final class ShedTokens extends ThemeExtension<ShedTokens> {
  const ShedTokens({
    required this.id,
    required this.highContrast,
    // surfaces
    required this.surfaceBase,
    required this.surfaceRaised,
    required this.surfacePressed,
    required this.surfaceFill,
    required this.outline,
    // ink
    required this.textNumeric,
    required this.textPrimary,
    required this.textSecondary,
    required this.textChrome,
    // status — never used without a shape and a word (§11)
    required this.statusReady,
    required this.statusAttention,
    required this.statusLoss,
    required this.onStatus,
    // metrics
    required this.tapMin,
    required this.tapPrimary,
    required this.tapHero,
    required this.gapMin,
    required this.gapDestructive,
    required this.outlineWidth,
    required this.radiusControl,
    required this.bodySize,
    required this.numeralSize,
    // behaviour
    required this.motion,
    required this.photoTint,
  });

  final ShedPaletteId id;
  final bool highContrast;
  final Color surfaceBase, surfaceRaised, surfacePressed, surfaceFill, outline;
  final Color textNumeric, textPrimary, textSecondary, textChrome;
  final Color statusReady, statusAttention, statusLoss, onStatus;
  final double tapMin, tapPrimary, tapHero, gapMin, gapDestructive;
  final double outlineWidth, radiusControl, bodySize, numeralSize;
  final Duration motion;

  /// Non-null only in the night-shift palettes. Applied by ShedPhoto and by
  /// nothing else — see §4.7.
  final ColorFilter? photoTint;

  /// Only `motion` and `highContrast` are ever overridden at runtime, so the
  /// signature is narrow on purpose: a wide copyWith invites a widget to build
  /// a one-off token set, which is exactly what the two tiers exist to stop.
  @override
  ShedTokens copyWith({Duration? motion, bool? highContrast}) => ShedTokens(
        id: id, highContrast: highContrast ?? this.highContrast,
        motion: motion ?? this.motion,
        /* …every other field passed through verbatim… */
        surfaceBase: surfaceBase, surfaceRaised: surfaceRaised,
        surfacePressed: surfacePressed, surfaceFill: surfaceFill,
        outline: outline, textNumeric: textNumeric, textPrimary: textPrimary,
        textSecondary: textSecondary, textChrome: textChrome,
        statusReady: statusReady, statusAttention: statusAttention,
        statusLoss: statusLoss, onStatus: onStatus, tapMin: tapMin,
        tapPrimary: tapPrimary, tapHero: tapHero, gapMin: gapMin,
        gapDestructive: gapDestructive, outlineWidth: outlineWidth,
        radiusControl: radiusControl, bodySize: bodySize,
        numeralSize: numeralSize, photoTint: photoTint,
      );

  // Signature per api.flutter.dev:
  //   ThemeExtension<T> lerp(covariant ThemeExtension<T>? other, double t)
  @override
  ShedTokens lerp(covariant ShedTokens? other, double t) {
    if (other == null) return this;
    // Every field snaps, colours included: one operand or the other, never a
    // third value. See the amendment note below.
    return t < 0.5 ? this : other;
  }
}

/// The ONLY way a widget gets a colour or a size.
extension ShedTokensX on BuildContext {
  ShedTokens get tokens => Theme.of(this).extension<ShedTokens>()!;
}
```

**Amended 2026-08-01 (N09-T02), two changes, both narrowings.**

**1 — `lerp` snaps the `Color` fields too.** The body above previously read:

> ~~`surfaceBase: Color.lerp(surfaceBase, other.surfaceBase, t)!,`~~ and the same for the other
> eleven `Color` fields — *"Colours interpolate with `Color.lerp`. Metrics and identity NEVER do."*

Struck, with its reason: **a colour produced by interpolation is a colour nobody measured for
contrast.** The entire claim of the two-tier structure is that every colour on screen is one somebody
measured, and `Color.lerp` manufactures values outside that set — at `t = 0.5` between `night` and
`deepRed`, `textChrome` lands on a hex that appears in no palette and in no row of §4's contrast
tables. Indelible rule 4 does not have a "for 150 ms" exemption, and `00-README` §2.3's hierarchy
prefers *unrepresentable* over *documented*.

The cost is zero: §2.1 and §4.8 already pin `themeAnimationDuration: Duration.zero`, precisely
because *"a 200 ms lerp between night and deep red drags every colour through a desaturated,
low-contrast midpoint"* — so no intermediate `t` is ever produced in the running app. This change
removes the possibility instead of relying on that setting staying where it is.

The metric sentence survives unchanged and is the half this always got right: a tap target that is
63.4 pt for 150 ms breaks the 60 pt contract for 150 ms.

`CONVENTIONS §2.11` and `.claude/skills/indelible-page-and-screens/SKILL.md` §4 both said *"snaps
every non-`Color` field"* and were amended in the same commit.

**2 — a fifth surface was added and then withdrawn, in the same epic.** Recorded rather than erased,
because the reasoning is the useful part.

`surfaceFillPressed` was added on the reading that `indelible.md` §2.2 supplied the palette values: it
publishes five surfaces to this section's four, and `--slab-pressed` had nowhere to go. **Decision
#95 overturned that reading** — it fixes the base surface at `#0B0D0E` and names `#000000` and
`#121212` in its rejected column, so §3.2's ramp is the one the decision record backs and §4.2–§4.5
is the only complete six-palette specification in the doc set. That ramp has four steps and publishes
no fifth hex, so the field had no value to hold, and inventing one is precisely what the two tiers
exist to prevent. It was removed in the same epic that added it; `ShedTokens` has four surfaces.

This is one half of **P6**, which is carried into N09's pull request as open with both sides cited
rather than settled on a task's authority. `indelible.md` is not struck here.

If a component genuinely needs a pressed slab distinct from a pressed row, the fix is a fifth value
in §4.2–§4.5 — not a literal in a widget, and not a field with nothing behind it.

Usage is then greppable and palette-proof:

```dart
@override
Widget build(BuildContext context) {
  final t = context.tokens;
  return DecoratedBox(
    decoration: BoxDecoration(
      color: t.surfaceRaised,
      border: Border.all(color: t.outline, width: t.outlineWidth),
      borderRadius: BorderRadius.all(Radius.circular(t.radiusControl)),
    ),
    child: Text('412', style: Theme.of(context).textTheme.displaySmall),
  );
}
```

### 3.4 Naming scheme

| Prefix | Meaning | Examples |
|---|---|---|
| `surface*` | something the app paints *under* content | `surfaceBase`, `surfaceRaised`, `surfacePressed`, `surfaceFill` |
| `text*` | something the app paints *as* glyphs | `textNumeric`, `textPrimary`, `textSecondary`, `textChrome` |
| `status*` | a domain state, always paired with a shape and a word | `statusReady`, `statusAttention`, `statusLoss` |
| `on*` | a foreground guaranteed legible on the named background | `onStatus` |
| `tap*` / `gap*` | interaction geometry | `tapMin`, `tapHero`, `gapDestructive` |
| `body*` / `numeral*` | type metrics that a palette may shift | `bodySize`, `numeralSize` |

Two hard naming rules: **no token is named after a colour** (`amberWarning` is banned — it is `statusAttention`), and **no token is named after a screen** (`penTileBorder` is banned — the pen tile uses `outline`).

### 3.5 The CI gate — rows in the one policy script

There is exactly one source-scanning gate (decision #10): `tool/check_policy.dart`, one rule table, one allowlist file, one exit code. `01-architecture.md` §3.2 owns the driver, the tuple shape and the allowlist format; this document **adds rows**, it does not add a script and it does not invent a second escape hatch.

Seven design rows are already in 01's `_bannedText`: `token.raw_color`, `token.material_color`, `a11y.scale_factor`, `a11y.header_bool`, `gesture.dismissible`, `gesture.draggable`, `gesture.tooltip`. **Two of them change scope here.** `token.raw_color` and `token.material_color` are scoped to `lib/features/` in 01, which leaves a raw hex in `lib/core/ui/components/` uncaught — the one place a shared widget would hide one. Widen both to `lib/`:

```dart
// tool/check_policy.dart — amended rows in _bannedText (01 §3.2).
//   (id, literal text, path prefix it applies under, why)
('token.raw_color',     'Color(0x', 'lib/', 'read ShedTokens — #97'),
('token.material_color','Colors.',  'lib/', 'read ShedTokens — #97'),
```

The rest of the design rules are patterns, not literals, so they go in a second table with the **same tuple shape, the same rule ids and the same allowlist keys** (`'<path> :: <id>'`). It is `final`, not `const`, because `RegExp` has no const constructor; the driver loop is one extra `for` over `_bannedPattern` beside the existing one over `_bannedText`.

```dart
// tool/check_policy.dart
/// (id, pattern, path prefix it applies under, why)
/// Same driver, same allowlist keys, same exit code as _bannedText.
final _bannedPattern = <(String, RegExp, String, String)>[
  // -- tokens ---------------------------------------------------------------
  ('token.raw_color_ctor', RegExp(r'Color\.from(ARGB|RGBO)\('), 'lib/',
      'raw colour literal — read ShedTokens — #97'),
  ('token.seeded_scheme', RegExp(r'ColorScheme\.fromSeed'), 'lib/',
      'generated scheme; 3.41 changed four on*Container roles — #94'),
  ('token.literal_font_size', RegExp(r'fontSize:\s*[0-9]'), 'lib/',
      'literal fontSize — use a TextTheme role — §5.1'),
  ('token.color_scheme_read', RegExp(r'\bcolorScheme\b'), 'lib/features/',
      'widgets read ShedTokens, not ColorScheme — §3.3'),
  ('token.color_scheme_read_ui', RegExp(r'\bcolorScheme\b'), 'lib/core/ui/components/',
      'components read ShedTokens, not ColorScheme — §3.3'),
  ('token.primitives_import',
      RegExp(r'''import\s+['"][^'"]*core/ui/primitives\.dart'''), 'lib/',
      'primitives are private to lib/core/ui/ — §3.1'),
  // 0 and 1 are not magic; everything else is a token you failed to name.
  ('token.magic_size', RegExp(
      r'(EdgeInsets\.\w+\(|SizedBox\(|BoxConstraints\(|Size\(|'
      r'(?:Border)?Radius\.circular\(|'
      r'(?:width|height|minWidth|minHeight|maxWidth|maxHeight|spacing|'
      r'strokeWidth|elevation|letterSpacing):)'
      r'\s*(?![01](?:\.0+)?\s*[,)])[0-9]'), 'lib/',
      'magic size — use the spacing or tap scale — §3.2'),

  // -- themes ---------------------------------------------------------------
  ('theme.mode', RegExp(r'ThemeMode\.(system|light)'), 'lib/', 'no light theme exists — §2.1'),
  ('theme.brightness', RegExp(r'Brightness\.light'), 'lib/', 'no light theme exists — §2.1'),
  ('theme.platform_brightness', RegExp(r'platformBrightnessOf'), 'lib/',
      'the OS brightness never changes this app — §2.1'),
  ('theme.light_factory', RegExp(r'ColorScheme\.light|ThemeData\.light'), 'lib/',
      'no light theme exists — §2.1'),
  ('theme.deprecated_scheme_role', RegExp(r'\b(background|onBackground|surfaceVariant):'),
      'lib/core/ui/', 'deprecated ColorScheme role — §2.3'),

  // -- typography -----------------------------------------------------------
  ('type.google_fonts', RegExp(r'\bGoogleFonts\b|google_fonts'), 'lib/',
      'runtime font fetch = a network path — §5.2'),
  ('type.clamp', RegExp(r'withClampedTextScaling|TextScaler\.clamp'), 'lib/',
      'never clamp text scale — #99'),
  ('type.weight_cap', RegExp(r'FontWeight\.w(8|9)00|FontWeight\.(black|extraBold)'), 'lib/',
      'w800/w900 render LIGHTER under Bold Text (flutter#139712) — §5.3'),
  ('type.fitted_box', RegExp(r'\bFittedBox\b'), 'lib/',
      'FittedBox undoes the user text size — §5.5'),

  // -- gestures (§7) --------------------------------------------------------
  ('gesture.long_press_draggable', RegExp(r'\bLongPressDraggable\b'), 'lib/', 'banned gesture — #101'),
  ('gesture.interactive_viewer', RegExp(r'\bInteractiveViewer\b|\bReorderableListView\b'),
      'lib/', 'banned gesture — #101'),
  ('gesture.refresh', RegExp(r'\bRefreshIndicator\b'), 'lib/',
      'pull-to-refresh: there is nothing to refresh — §7'),
  ('gesture.long_press', RegExp(r'onLongPress(Start|End|MoveUpdate)?:'), 'lib/',
      'long-press-only is banned — §7'),
  ('gesture.scale', RegExp(r'onScale(Start|Update|End):|onForcePress'), 'lib/',
      'pinch / force touch — §7'),
  ('gesture.drag', RegExp(r'on(Horizontal|Vertical|Pan)Drag(Start|Update|End):'), 'lib/',
      'drag — §7'),
  ('gesture.drag_handle', RegExp(r'showDragHandle:\s*true'), 'lib/',
      'a drag handle advertises a banned gesture — §7'),
  ('gesture.sheet_drag', RegExp(r'enableDrag:\s*true'), 'lib/',
      'drag-to-dismiss is a drag; sheets set enableDrag: false — §7'),
  ('gesture.slider', RegExp(r'\bSlider\b|\bRangeSlider\b|\bCupertinoPicker\b'), 'lib/',
      'drag-only control; use the keypad or a Wrap of 60 pt choices — §7'),
  ('gesture.horizontal_swipe', RegExp(r'\bPageView\b|\bTabBarView\b'), 'lib/',
      'horizontal swipe; vertical scrolling is the only tracked gesture — §7'),
  // Every receipt goes through confirmSaved in lib/core/ui/feedback.dart —
  // the one file permitted to call showSnackBar( (R30) and the only place that
  // may set dismissDirection / persist correctly. A balanced-paren regex over
  // a multi-line SnackBar(...) is not writable; forbidding the call site is.
  ('gesture.raw_snackbar', RegExp(r'showSnackBar\('), 'lib/features/',
      'call confirmSaved — a bare SnackBar is swipe-dismissible — §10.3'),

  // -- semantics (details in 10-accessibility-and-i18n.md) ------------------
  ('a11y.announce', RegExp(r'SemanticsService\.announce'), 'lib/',
      'no-op on Android — use a liveRegion — #103'),
];
```

Rules apply to `lib/**`, skipping `*.g.dart` and `*.drift.dart`, exactly as 01's driver already does. The escape hatch is 01's allowlist file and nothing else: a line in `tool/policy_allowlist.txt`'s `[exempt]` section, keyed `'<path> :: <id>'`, which is reviewable in a diff and cannot be pasted into a widget at 3am. **This section adds exactly two `[exempt]` lines**, so the day-one total is four, not the two `01-architecture.md`'s Definition of Done counts — that list predates this section and is corrected here:

```
[exempt]
lib/core/time/app_clock.dart          :: time.dart_clock
lib/core/ui/night_error_panel.dart    :: token.raw_color
lib/core/ui/primitives.dart           :: token.raw_color          # the ONE file that holds a hex
lib/core/ui/palettes.dart             :: token.primitives_import  # the ONE file that composes them
```

Read that block as the whole access-control story for colour: one file declares hexes, one file composes them into palettes, everything else reads `context.tokens`.

The regex gate cannot express contrast. Its companion is a semantic test:

`test/design/` is an addition to `01-architecture.md` §2.2's test tree (`domain · data · drift · features · policy · fixtures`) — add it to the `mkdir` line there. It holds three files: `wcag.dart` (the formula), `contrast_test.dart` (the palettes) and `tap_target_test.dart` (§6.3).

```dart
// test/design/contrast_test.dart
void main() {
  for (final p in shedPalettes) {          // the six-entry const list in palettes.dart
    group(p.name, () {
      final t = p.tokens;
      final double bodyFloor = p.id == ShedPaletteId.deepRed && !p.highContrast
          ? 4.5   // §4.4: no spectrally clean red reaches AAA. Stated, not hidden.
          : 7.0;
      test('numerals clear AAA on base, raised and fill', () {
        for (final s in [t.surfaceBase, t.surfaceRaised, t.surfaceFill]) {
          expect(contrastRatio(t.textNumeric, s), greaterThanOrEqualTo(bodyFloor));
        }
      });
      test('primary and secondary text clear the palette floor', () {
        expect(contrastRatio(t.textPrimary, t.surfaceBase), greaterThanOrEqualTo(bodyFloor));
        expect(contrastRatio(t.textSecondary, t.surfaceBase), greaterThanOrEqualTo(4.5));
      });
      test('chrome text clears AA and is never used for data', () {
        expect(contrastRatio(t.textChrome, t.surfaceBase), greaterThanOrEqualTo(4.5));
      });
      test('outline clears the 3:1 non-text requirement', () {
        expect(contrastRatio(t.outline, t.surfaceBase), greaterThanOrEqualTo(3.0));
      });
      test('status chips are legible with onStatus text', () {
        for (final c in [t.statusReady, t.statusAttention, t.statusLoss]) {
          expect(contrastRatio(t.onStatus, c), greaterThanOrEqualTo(4.5));
        }
      });
      test('the tap floor is never below spec §5', () {
        expect(t.tapMin, greaterThanOrEqualTo(60.0));
        expect(t.bodySize, greaterThanOrEqualTo(18.0));
      });
    });
  }
  test('no palette is brighter than the native launch colour', () {
    for (final p in shedPalettes) {
      expect(relativeLuminance(p.tokens.surfaceBase),
          lessThanOrEqualTo(relativeLuminance(launchSurface)));  // §9
    }
  });
  test('the night-shift palettes drop luminance, not just hue', () {
    final peakNight = peakLuminance(nightPalette);
    for (final p in [amberPalette, deepRedPalette]) {
      expect(peakLuminance(p), lessThan(0.70 * peakNight));
    }
  });
}
```

`contrastRatio`, `relativeLuminance`, `peakLuminance` and `launchSurface` live in `test/design/wcag.dart`. Write them; do not import them — a colour package would have to pass the offline dependency allowlist for twelve lines of arithmetic.

```dart
// test/design/wcag.dart — WCAG 2.x relative luminance and contrast ratio.
import 'dart:math' as math;
import 'dart:ui' show Color;

/// dart:ui's Color.computeLuminance() IS the WCAG 2.0 relative-luminance
/// formula — 0.2126R + 0.7152G + 0.0722B over linearised sRGB components,
/// citing the W3C definition in its own source. Re-deriving `pow(c, 2.4)` by
/// hand buys nothing and is one typo away from a palette that passes a wrong
/// test. The only thing this file adds is the ratio and the two aggregates.
double relativeLuminance(Color c) => c.computeLuminance();

double contrastRatio(Color a, Color b) {
  final double la = relativeLuminance(a), lb = relativeLuminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The brightest ink a palette normally puts on screen — the quantity §4.3's
/// "red-shift drops luminance as well as hue" rule is about.
///
/// AMENDED 2026-08-01 (N09-T03): body text only. See the note below.
double peakLuminance(ShedPalette p) => [
      p.tokens.textNumeric, p.tokens.textPrimary,
    ].map(relativeLuminance).reduce(math.max);

/// The brightest status mark, asserted separately so §4.3's deliberate
/// exception stays visible and stays BOUNDED.
double peakStatusLuminance(ShedPalette p) => [
      p.tokens.statusReady, p.tokens.statusAttention, p.tokens.statusLoss,
    ].map(relativeLuminance).reduce(math.max);

/// The native launch colour, §9. Duplicated here deliberately: if someone
/// edits nSurface04 without editing the native config, this test must fail.
const Color launchSurface = Color(0xFF0B0D0E);
```

**Amended 2026-08-01 (N09-T03) — `peakLuminance` measures body text, not status marks.**

The version above previously read:

> ~~`p.tokens.textNumeric, p.tokens.textPrimary, p.tokens.statusReady, p.tokens.statusAttention,
> p.tokens.statusLoss`~~

Struck with its reason: **that version cannot pass against §4.3's own table.** `amber`'s `statusLoss`
is `#FFE0A3` at L 0.772, and the ceiling is 0.70 × `night`'s peak of 1.000 = 0.700. The palette was
not wrong; the assertion was measuring the wrong quantity.

The collision is between two rules in this document, and §4.3 already resolves it against itself. Its
rule 1 says *"in a one-hue palette, urgency is luminance"* — loss is **deliberately** the brightest
token, because the colour channel is nearly gone and the luminance channel is what is left to spend
on the thing that needs a shepherd's attention. Then its own arithmetic two paragraphs later computes
the drop as *"1.000 → 0.618"*, and **0.618 is amber's `textNumeric`, not its `statusLoss` at 0.772**.
§4.3 was already measuring body text. §3.5's list was the stale half.

Relaxing the 0.70 factor was the other way out and is the edit-the-gate-to-make-it-green anti-pattern
`13` names by name. **The factor is untouched.** The exception is bounded rather than waived:
`peakStatusLuminance` is asserted separately, so a status mark still may not exceed `night`'s body-text
peak — past that point a night-shift palette is emitting more light than the palette it exists to be
dimmer than.

**Every ratio printed in §4 was computed with exactly this formula on 2026-07-27** and is reproduced by the test above. If a number in this document and the test disagree, the test is right and the document is stale — which is the only reason it is safe to print sixty ratios in prose at all.

---

## 4. The palettes

### 4.1 The registry

Six authored token sets: three palettes × two contrast levels. Every one is a literal constructor call (decision #94). The user picks a palette in Settings; the contrast level comes from iOS's Increase Contrast **or** the in-app High contrast switch, ORed.

```dart
// lib/core/ui/palettes.dart
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

`test/design/contrast_test.dart` opens with `expect(shedPalettes, hasLength(6))` and with a check that every `(id, highContrast)` pair appears exactly once — otherwise a seventh palette added in season two gets its ratios published in this document and never tested.

Settings labels are fixed by decision #96 and must be typed exactly:

- **Night** — the default.
- **Amber (recommended)**
- **Deep red (best for night vision, hardest to read)**
- **High contrast** — a switch, not a fourth palette.

The honest sentence beside the pair, which the Settings screen shows and the doc set does not paraphrase: deep red is the best long-wavelength choice for preserving dark adaptation and the worst choice for reading. `#FF0000` on `#121212` measures **4.69:1** for a normal observer and materially worse for a protanope; `#FFB000` on the same surface measures **10.23:1**. Amber is still long-wavelength, so most of the night-vision benefit survives. That is why amber is the recommendation and red still ships — spec §5 and §7.10 both name red-shift, so dropping it would be an undeclared spec deviation.

(Those two figures are the decision record's own measurements, taken against `#121212`, which is the surface decision #95 **rejects** as a base. They are quoted unchanged because they are what the ruling was made on. Against Shed Book's actual night-shift base, `#000000`, the same pair measures 5.25:1 and 11.46:1 — the gap is the same size and points the same way. §4.4 carries the `#000000` figures.)

### 4.2 `night` — the default palette

**Base surface `#0A0A0B` — amended 2026-08-01 (N11-T04), closing P14.** This section published `#0B0D0E` and cited decision #95. §1's own fixed-versus-free table puts *"the base surface hex, provided it is no brighter than `#0B0D0E`"* in the **free** column, and §9 calls `#0B0D0E` *"the brightest base any palette may have"* — so it is a **ceiling**, not an exact value. `indelible.md` §2.2's `#0A0A0B` measures L 0.00306 against `#0B0D0E`'s 0.00391, i.e. **darker**, so it is inside the ceiling this document set. Every ratio in the table below was recomputed against it; the raised-surface trio is unchanged because it does not touch the base.

The rejected bases stand: Not `#000000`: a base of exactly zero has nothing to build a surface ramp on, so elevation would have to be carried by outlines everywhere. Not `#121212`: in a dark shed the extra emission buys nothing.

| Token | Hex | Ratio on `surfaceBase` | Use |
|---|---|---|---|
| `surfaceBase` | `#0A0A0B` | — (L = 0.00306) | scaffold, keypad gutters |
| `surfaceRaised` | `#12161A` | 1.09:1 vs base | cards, keys, tiles |
| `surfacePressed` | `#1A2025` | 1.20:1 vs base | pressed / selected |
| `surfaceFill` | `#242B31` | 1.38:1 vs base | emphasis fills, chart bars |
| `outline` | `#8A9199` | **6.21:1** | borders (decoration; meaning is in the label) |
| `textNumeric` | `#FFFFFF` | **19.79:1** | tags, keypad digits, timers |
| `textPrimary` | `#E8EAED` | **16.42:1** | body |
| `textSecondary` | `#B7BDC4` | **10.45:1** | labels |
| `textChrome` | `#8A9199` | **6.21:1** | AA only — **never a value the shepherd must read** |
| `statusReady` | `#7DD3A0` | **11.02:1** | ready to turn out |
| `statusAttention` | `#FFD54F` | **14.02:1** | withdrawal active, treatment due |
| `statusLoss` | `#FFB4AB` | **11.66:1** | loss recorded |
| `onStatus` | `#0A0A0B` | 11.02 / 14.02 / 11.66 on the three fills | text inside a status chip |

**The ramp is a hint, not a separator.** 1.07:1 and 1.18:1 are far below the 3:1 WCAG asks of a non-text boundary — deliberately, because a bright card edge is a light source you are staring at for four hours. So the rule is: **any boundary that must be findable under a head torch carries an `outline` as well as a ramp step.** The ramp does the work in a dark room; the outline does it in a bright pool of torchlight. Cards, keys, pen tiles and sheets are all outlined. A direction may widen the ramp; it may not drop the outline.

Also measured on the raised surface, because half the app's text sits there: `#E8EAED` on `#12161A` = **15.08:1**; `#B7BDC4` = **9.60:1**; `#8A9199` = **5.70:1**. Anything below 7:1 on `surfaceRaised` is chrome by definition.

### 4.3 `amber` — the recommended night-shift palette

Base `#000000`. In a night-shift palette the base is pure black because minimising *total emission* is the point and there is no complex content to separate by tint; separation comes from the outline instead.

| Token | Hex | Ratio on `#000000` | Rel. luminance |
|---|---|---|---|
| `surfaceRaised` | `#140D00` | 1.09:1 vs base | 0.0044 |
| `surfacePressed` | `#1F1400` | 1.16:1 vs base | 0.0079 |
| `outline` | `#A66E00` | **4.85:1** | 0.193 |
| `textNumeric` | `#FFC46B` | **13.36:1** | 0.618 |
| `textPrimary` | `#FFB000` | **11.46:1** | 0.523 |
| `textSecondary` | `#D68F00` | **7.79:1** | 0.339 |
| `textChrome` | `#C98400` | **6.78:1** | 0.289 |
| `statusLoss` | `#FFE0A3` | **16.44:1** | 0.772 |
| `statusAttention` | `#FFB000` | **11.46:1** | 0.523 |
| `statusReady` | `#C98400` | **6.78:1** | 0.289 |
| `onStatus` | `#000000` | 16.44 / 11.46 / 6.78 | 0.000 |

Two rules embedded in that table:

1. **In a one-hue palette, urgency is luminance.** Loss is the brightest token, then attention, then ready. The colour channel is nearly gone; the luminance channel is what is left, and it must be spent on the thing that needs a shepherd's attention. Shape and text carry the rest (§11).
2. **Red-shift drops luminance as well as hue.** Peak token luminance falls from 1.000 (night `textNumeric` = white) to 0.618. The naval/aviation finding is that at low instrument-lighting levels the red-vs-white advantage largely disappears — *intensity matters more than colour* — so a night mode that is merely red and just as bright is close to useless. That is a testable property, and §3.5 tests it.

### 4.4 `deepRed` — shipped, and honestly labelled

Base `#000000`.

| Token | Hex | Ratio on `#000000` | Rel. luminance |
|---|---|---|---|
| `surfaceRaised` | `#1A0503` | 1.07:1 vs base | 0.0034 |
| `surfacePressed` | `#2A0806` | 1.14:1 vs base | 0.0068 |
| `outline` | `#CC2200` | **3.80:1** | 0.140 |
| `textNumeric` | `#FF6B4A` | **7.45:1** | 0.323 |
| `textPrimary` | `#FF4400` | **6.08:1** | 0.254 |
| `textSecondary` | `#E62200` | **4.59:1** | 0.180 |
| `textChrome` | `#E62200` | **4.59:1** | 0.180 |
| `statusLoss` | `#FF9E80` | **10.45:1** | 0.473 |
| `statusAttention` | `#FF6B4A` | **7.45:1** | 0.323 |
| `statusReady` | `#FF4400` | **6.08:1** | 0.254 |
| `onStatus` | `#000000` | 10.45 / 7.45 / 6.08 | 0.000 |

**The honest limitation, stated in the code and in the app.** A spectrally clean long-wavelength palette has a hard contrast ceiling: pure `#FF0000` on black is only **5.25:1**, and pushing toward orange buys contrast (`#FF4400` → 6.08:1) at the cost of adding green energy that bleaches rhodopsin faster. No red palette reaches AAA (7:1) for body text and stays spectrally clean. So:

- `textChrome` and `textSecondary` are deliberately the same value — nothing dimmer clears AA, and inventing a fourth ink step here would mean shipping unreadable text.
- `#CC2200` (3.80:1) is `outline` only. It never carries a glyph.
- The contrast test asserts **AA (4.5:1)** for this palette and only this palette, with a comment pointing at this section. The suite is not relaxed globally to hide it.
- Compensation is bought with **size, never weight**: `bodySize` 18 → 20 and `numeralSize` 40 → 44 in both night-shift palettes. Both, not just deep red, so switching between the honest pair never reflows the screen. Bumping weight instead would walk into flutter#139712 (§5.3).

### 4.5 The high-contrast variants

`highContrastDarkTheme` is not a copy of `darkTheme` — that would be dead plumbing while claiming to honour the flag. Each palette has a genuinely higher-contrast sibling, and because `highContrast` only ever fires on iOS, the same variant is reachable from a Settings switch on both platforms.

| Palette | HC base | HC `textPrimary` | Ratio | HC `outline` | Ratio |
|---|---|---|---|---|---|
| night | `#000000` | `#FFFFFF` | **21.00:1** | `#7A7A7A` | **4.89:1** |
| amber | `#000000` | `#FFC46B` | **13.36:1** | `#A66E00` | **4.85:1** |
| deepRed | `#000000` | `#FF6B4A` | **7.45:1** | `#CC2200` | **3.80:1** |

Each HC variant is the same ramp shifted one step brighter, plus a load-bearing outline (`surfaceRaised == surfaceBase`, so cards are separated by border, not tint — a few percent of luminance disappears under a head torch). Night HC statuses: ready `#A8F0C6` **15.94:1**, attention `#FFE08A` **16.28:1**, loss `#FFC7BD` **14.16:1**.

Note the trade the deep-red HC variant makes: it reaches AAA for body (7.45:1) by emitting more light, which is exactly what a night-vision palette is trying to avoid. Say so in the Settings row; do not silently resolve it for the user.

### 4.6 What is not in v1

Note 05 proposed a fourth `daylight` palette for reading the pen board in a bright June yard. The decision record does not carry it and its rationale is explicitly flagged there as a judgement call rather than a cited fact. **It is not in v1.** If the field night (open question 1) shows a need, it enters as a seventh registry entry and changes nothing structural.

### 4.7 Photos — the only place `ColorFiltered` is permitted

A **global** `ColorFiltered` over the app is banned (decision #96). Three reasons, in order of severity: it collapses `statusReady` / `statusAttention` / `statusLoss` into three near-identical hues, which is a WCAG 1.4.1 failure introduced *by* the accessibility feature; it destroys per-token contrast control; and it triggers a full-screen `saveLayer` every frame, which Flutter's own performance guidance names as disruptive to rendering throughput on mobile GPUs.

```dart
// lib/core/ui/components/shed_photo.dart
/// The ONLY sanctioned ColorFiltered in the app. Cost is bounded to the
/// image's own bounds. In night and high-contrast palettes photoTint is null
/// and this widget is a plain Image.
class ShedPhoto extends StatelessWidget {
  const ShedPhoto({super.key, required this.image});
  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    final Widget img = Image(image: image, fit: BoxFit.cover);
    final ColorFilter? tint = context.tokens.photoTint;
    return tint == null ? img : ColorFiltered(colorFilter: tint, child: img);
  }
}
```

The photo viewer carries a permanent `tapHero` **"Show in full colour"** control. A shepherd looking at a photo of a prolapse needs the colour information, and a tinted view of tissue is useless. This also keeps the app on the right side of spec §12.2: the app shows what was photographed; it never interprets it.

### 4.8 Switching palettes

Instant. `themeAnimationDuration: Duration.zero` (§2.1) and `ShedTokens.motion` = `Duration.zero` for the switch itself. The palette toggle is reachable from the bottom bar of Quick Entry as well as from Settings — a shepherd decides they need deep red while standing in the dark, not while sitting in the kitchen.

**Acceptance procedure for any night-shift palette change:** sit in a genuinely dark room for ten minutes, then open the app. Anyone reviewing a night-shift palette from a screenshot on a lit monitor is not reviewing it.

---

## 5. Typography

### 5.1 The scale

M3's `bodyLarge` is 16.0. Spec §5 says 18 pt minimum body, so the whole `TextTheme` is overridden — `bodySmall` and `labelSmall` are collapsed into the 18 pt floor rather than kept as distinct sizes. If a piece of text is not worth 18 pt at 3am, it is not worth showing.

| Role | M3 default | Shed Book | Weight | Tabular | Use |
|---|---|---|---|---|---|
| `displayLarge` | 57 / w400 | **64** | w700 | ✓ | the entered tag on the keypad |
| `displayMedium` | 45 / w400 | **48** | w700 | ✓ | ewe card tag |
| `displaySmall` | 36 / w400 | **40** (`numeralSize`) | w700 | ✓ | pen tile tag, keypad digits |
| `headlineLarge` | 32 / w400 | **32** | w700 | ✓ | hours-since-penned |
| `headlineMedium` | 28 / w400 | **28** | w600 | — | |
| `headlineSmall` | 24 / w400 | **24** | w600 | — | |
| `titleLarge` | 22 / w400 | **24** | w600 | — | screen titles (`headingLevel: 1`) |
| `titleMedium` | 16 / w500 | **20** | w600 | — | section headings (`headingLevel: 2`) |
| `titleSmall` | 14 / w500 | **18** | w600 | — | |
| `bodyLarge` | 16 / w400 | **20** | w500 | — | primary body |
| `bodyMedium` | 14 / w400 | **18** (`bodySize`) | w500 | — | **the floor** |
| `bodySmall` | 12 / w400 | **18** | w500 | — | collapsed |
| `labelLarge` | 14 / w500 | **20** | w700 | — | button text |
| `labelMedium` | 12 / w500 | **18** | w600 | — | |
| `labelSmall` | 11 / w500 | **18** | w600 | — | collapsed |

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

### 5.2 The font asset

Bundle **Atkinson Hyperlegible Next** (SIL OFL 1.1, ~114 KB for the upright variable file, ships `tnum` — decision #98). Take it from the Google Fonts OFL distribution, commit `OFL.txt` beside it in `assets/fonts/`, and register it via `LicenseRegistry.addLicense`.

**Verified on download, 2026-08-01 (N09-T05), before the pubspec entry was written.** This paragraph previously said *"nothing in this document has confirmed the published range"* and gave the requirement as *"the axis must cover at least 500–700"*. It has now been read off the file:

| | Recorded here | **Measured** |
|---|---|---|
| Byte count | ~114 KB | **114 552** bytes — 2.2% of decision #127's < 5 MB budget |
| `wght` axis | *"must cover at least 500–700"*, range unconfirmed | **200 – 800**, default 400, one axis, seven named instances |
| `tnum` | claimed by #98 | **present** — confirmed |
| slashed zero | *"unverified"* | **absent**, and there is no `ss01`/`cv` variant either |

Full readings, including the GSUB/GPOS feature lists and what is still **not** measured, are in `docs/perf/measurements.md`.

**The axis is wider than this document assumed, and that matters for P7.** `indelible.md §3.3`'s 390 / 420 / 520 / 600 are all *reachable* on a 200–800 axis — the axis was never the obstacle. What rules them out is the mechanism they would need: `Text.build` merges `FontWeight.bold` for the Bold Text accessibility setting and does **not** touch `fontVariations`, so a weight set through `FontVariation('wght', 390)` silently ignores that setting, on exactly the users who turned it on. `FontVariation` is therefore banned outright under `lib/` and a test holds it. See N09-T05's commit for the ruling.

Record any re-measurement in `docs/perf/measurements.md` with its date.

```yaml
flutter:
  fonts:
    - family: AtkinsonNext
      fonts:
        # One variable file. Post-3.41 FontWeight drives the wght axis, so
        # there are no per-weight asset entries and no FontVariation lists.
        - asset: assets/fonts/AtkinsonHyperlegibleNext[wght].ttf
```

**`google_fonts` is banned** and grepped for: 8.2.0 depends on `http` and fetches at runtime by default, which is categorically wrong in an app that ships with no `INTERNET` permission.

If the chosen direction needs a second face (an editorial serif, a condensed grotesque, a monospace instrument face), it must be an OFL/SIL-licensed TTF bundled the same way, added to `ShedTokens` as a `fontFamily*` token, and counted against the < 5 MB bundled-asset budget (decision #127). It may not be fetched, and it must ship `tnum` if it renders any numeral that aligns.

**Unverified:** Atkinson Hyperlegible Next has no `zero` (slashed-zero) feature and no `ss01`/`cv` variants; it separates `0` from `O` by counter shape and width alone. Confirm on a real device under a head torch before the font is locked in. If it fails, Inter (also OFL 1.1) with `FontFeature.slashedZero()` is the documented fallback.

### 5.3 The weight cap — w700, no exceptions

`Text.build` merges `const TextStyle(fontWeight: FontWeight.bold)` when `MediaQuery.boldTextOf(context)` is true, and `merge` wins. `FontWeight.bold` is **w700**. So any style set at w800/w900 renders *lighter* — at w700 — precisely when the user has asked for heavier text (flutter#139712, open since Dec 2023).

**Rule: no text style in Shed Book exceeds `FontWeight.w700`.** Hierarchy comes from size and colour. There is no `weightBump` token; note 05's is deleted (decision #98, correction §6). Very heavy weights also bloom badly on OLED in the dark, so this costs nothing.

### 5.4 Tabular figures

Every numeral that must align vertically or hold a column width uses a `TextTheme` role that carries `FontFeature.tabularFigures()`: pen tile tags, hours-since-penned, keypad digits, the withdrawal countdown, the medicine book, CSV-adjacent readouts, chart axis labels.

The failure mode is silent: constructing a fresh `TextStyle` instead of copying one drops `fontFeatures`, and the pen board starts jittering as `412` and `108` take different widths. **Never construct a bare `TextStyle` for a numeral.** Go through the role; the golden on the pen board catches a regression.

### 5.5 Text scaling — never clamp, and no `TextScaler` subclass exists

`textScaleFactor` is deprecated and **must not appear anywhere in the repo, including the theme layer**. `MediaQuery.withClampedTextScaling` and `TextScaler.clamp` are banned. Android 14+ scales to 200% along a non-linear curve; clamping defeats the system's own curve and forfeits Apple's Larger Text criterion.

Shed Book applies **no `TextScaler` manipulation at all**, with one exception: `MediaQuery.withNoTextScaling` around icon fonts and fixed-geometry glyph art, where scaling would make an icon overlap its own box. The target around such an icon is still ≥ 60 pt.

There is deliberately **no floor** at 1.0, and that resolves an apparent conflict with spec §5's 18 pt minimum: 18 pt is the design floor at scale 1.0. A user who has *deliberately* set 85% text on the OS has told the system they read smaller type, and honouring that beats enforcing our floor over their choice. If a `TextScaler` subclass is ever added it must override `scale()` only, implement `==`/`hashCode` (otherwise `MediaQuery.updateShouldNotify` sees a changed scaler on **every** rebuild and invalidates every MediaQuery dependant in the tree), and be hoisted out of `build()`.

What the no-clamp rule costs, and how it is paid:

| Pattern | Instead of |
|---|---|
| `LayoutBuilder` choosing the pen-board column count from `MediaQuery.textScalerOf(context).scale(numeralSize)` | `GridView.count(crossAxisCount: 4)` |
| `Wrap` for the ease 1–5 row and any chip row | `Row` + `Expanded` |
| Label **above** value | label-left / value-right two-column rows |
| `Flexible` + `softWrap: true` + `maxLines: null` | `maxLines: 1, overflow: ellipsis` |
| `ConstrainedBox(minHeight:)` | `SizedBox(height: 56)` |
| Icon **and** text stacked vertically in a button | icon + text in a `Row` |
| `Column` + `SingleChildScrollView` for every form | a fixed-height `Card` |

`FittedBox` around user-facing text is banned and grepped: it visually undoes the user's font setting.

The 252-cell overflow matrix (14 pumpable variants × 3 sizes × textScaler {1.0, 1.3, 2.0} × boldText {false, true}) is the gate. It lives in `12-testing.md`; this document owes it layouts that pass. *(Decision #114's 216 counted 12 screens; note search and the export-banner variant are the two additions, and the arithmetic follows the variant list — CONVENTIONS R58.)*

---

## 6. Tap targets, hit slop and separation

### 6.1 The scale, and why 60 is the floor rather than a margin

| Class | Size | ≈ mm | Where |
|---|---|---|---|
| `tapMin` | **60** | 9.5 | absolute floor — every interactive thing, including Settings rows |
| `tapPrimary` | **72** | 11.4 | keypad keys, recents chips, pen tiles, ease buttons |
| `tapHero` | **88** | 14.0 | the five 3am actions: *Lambed*, *Turn out*, *Treat*, *Dead*, *Confirm* |
| `gapMin` | **16** | 2.5 | between any two targets — double Material's 8 dp |
| `gapDestructive` | **32** | 5.1 | between a destructive target and its nearest neighbour |

**The mm column comes from one conversion, used everywhere in this document:** a logical pixel is 1/160 inch = **0.15875 mm** by definition on Android, and an iOS point is within 2% of it on every shipping device. Screen ppi does not enter the calculation — that is the whole point of a logical pixel — so "9.5 mm on a 460 ppi phone" and "9.5 mm on a 326 ppi phone" are the same statement. §11 uses the same conversion for glyph height.

Apple asks for 44×44 pt, Android for 48×48 dp, WCAG 2.2 AAA for 44×44 px. 60 pt is bigger than all three, and the reason is not generosity: Parhi, Karlson & Bederson measured 9.2 mm (discrete) and 9.6 mm (serial) as sufficient for one-handed thumb use — **for a bare, warm, dry thumb in a lab**. 60 pt ≈ 9.5 mm, so the spec's number is the *ideal-conditions optimum*, not a margin over it. Gloves, cold and a wet screen are all worse than ideal, and the keypad is a serial task (the larger of the two figures). Lambing entry is also a low-error-tolerance task — a mis-tap that records a stillbirth against the wrong ewe stays wrong for five years — which is what justifies pushing primaries to 72 and heroes to 88.

### 6.2 `ShedTapTarget` is the only sanctioned way to make something tappable

```dart
// lib/core/ui/components/shed_tap_target.dart
/// Guarantees a >= [minSize] hit region regardless of the child's painted size,
/// and makes the whole region opaque to hit testing so a tap in the transparent
/// margin still counts. That margin IS the hit slop.
class ShedTapTarget extends StatelessWidget {
  const ShedTapTarget({
    super.key,
    required this.onTap,
    required this.child,
    required this.semanticLabel,
    this.minSize,
    this.onTapHint,
  });

  final VoidCallback? onTap;
  final Widget child;
  final String semanticLabel;   // required: an unlabelled node is an unnamed
  final double? minSize;        // stop in a Switch Control scan
  final String? onTapHint;

  @override
  Widget build(BuildContext context) {
    final double size = minSize ?? context.tokens.tapMin;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      // MANDATORY, and easy to leave out. ExcludeSemantics below drops the
      // GestureDetector's own SemanticsAction.tap, so without this line the
      // node announces as a button and then does nothing when VoiceOver or
      // Switch Control activates it — and `onTapHint` is inert, because a hint
      // overrides the verb of an action that has to exist first.
      onTap: onTap,
      onTapHint: onTapHint,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: size, minHeight: size),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
```

`labeledTapTargetGuideline` in §6.3 catches a missing label. Nothing in `flutter_test` catches a missing *action*, so the geometric gate below also asserts that every `ShedTapTarget` node with `onTap != null` exposes `SemanticsAction.tap`.

Two rules about hit slop:

1. **Inside the layout** — `HitTestBehavior.opaque` plus the `ConstrainedBox`. A 32 pt glyph can sit inside an 88 pt hit region.
2. **Outside the layout** — Flutter clips hit testing to a parent's bounds. If a target overflows its parent, the taps are silently dropped even with `Clip.none`. **Restructure the layout instead.** This is a class of bug that only appears on a real device.

Spacing is enforced by layout, not vigilance — `Column`/`Row`/`Flex` take `spacing:` since 3.27, so use `spacing: t.gapMin` rather than `SizedBox` soup.

**Never put a destructive target `gapMin` from a frequent one.** *Delete lamb* is not 16 pt from *Confirm*. Destructive actions go on a different screen edge, behind a confirm, at `gapDestructive` minimum. Because swipe-to-delete is banned there is no place left to hide destruction, which is correct: deletion becomes explicit and two-step.

### 6.3 The two gates

`MinimumTapTargetGuideline` alone is not sufficient — it silently skips nodes flush with a screen edge and nodes with no semantics at all, and those are exactly the bugs. So there are two (decision #100):

```dart
// test/design/tap_target_test.dart
const shedTapTargetGuideline = MinimumTapTargetGuideline(
  size: Size(60, 60),
  link: 'docs/engineering/06-design-system.md#6-tap-targets-hit-slop-and-separation',
);

testWidgets('${screen.name}: semantic gate', (tester) async {
  // WITHOUT this handle semanticsOwner is null and the guideline throws
  // instead of asserting — the gate silently cannot do its job.
  final handle = tester.ensureSemantics();
  addTearDown(handle.dispose);
  await tester.pumpWidget(screen.build());
  await tester.pumpAndSettle();
  await expectLater(tester, meetsGuideline(shedTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
});

testWidgets('${screen.name}: geometric gate', (tester) async {
  final handle = tester.ensureSemantics();
  addTearDown(handle.dispose);
  await tester.pumpWidget(screen.build());
  await tester.pumpAndSettle();
  final elements = find.byType(ShedTapTarget).evaluate().toList();
  final rects = <Rect>[
    for (final e in elements) tester.getRect(find.byElementPredicate((x) => x == e)),
  ];
  for (final r in rects) {
    expect(r.width, greaterThanOrEqualTo(60.0), reason: 'target narrower than the floor');
    expect(r.height, greaterThanOrEqualTo(60.0));
  }
  for (var i = 0; i < rects.length; i++) {
    for (var j = i + 1; j < rects.length; j++) {
      expect(gapBetween(rects[i], rects[j]), anyOf(equals(0.0), greaterThanOrEqualTo(16.0)),
          reason: 'targets closer than gapMin without touching');
    }
  }
  // No built-in guideline checks this: an enabled button node with no tap
  // ACTION announces correctly and then refuses to activate (§6.2).
  for (final e in elements) {
    if ((e.widget as ShedTapTarget).onTap == null) continue;
    final node = tester.getSemantics(find.byElementPredicate((x) => x == e));
    expect(node.hasAction(SemanticsAction.tap), isTrue,
        reason: 'ShedTapTarget "${node.label}" is a button with no tap action');
  }
});
```

Two things about that test that are easy to get wrong. **`find.byWidget` is not usable here**: two keypad keys can be equal `Widget`s, and `getRect` throws on a finder that matches more than one element — match on the `Element` identity instead. And **`getSemantics` needs the same live `SemanticsHandle`** the guideline run needs, so both tests open one.

`accessibility_tools` runs in debug alongside these; its 48×48 default is *below* our floor, so it complements and never replaces the house assertion.

---

## 7. The gesture ban

Every action in Shed Book is reachable by a sequence of single discrete taps on ≥60 pt targets. That is a real constraint on the navigation model: reordering pens is "tap pen → tap *Move to…* → tap destination", never a drag.

| Banned | Why it fails at 3am | The replacement |
|---|---|---|
| Swipe-to-delete | Needs a tracked contact over ~100 pt of travel; a marginal gloved contact drops mid-swipe and the gesture reads as a tap. Also destructive *and* invisible, against spec §12.4 | An explicit Delete/Strike control inside the record + persistent Undo (§10.3) |
| Drag / drag-to-reorder | Same tracking requirement, longer, plus precision at the drop target | Two-tap move; nudge buttons |
| Long-press-only | Needs ≥500 ms held within the touch slop; a cold, tremoring finger through plastic cancels it. Also undiscoverable | A visible button. A long press may never be the *only* route |
| Pinch | Two simultaneous tracked contacts. One hand is holding a lamb | OS text scale drives board density (§5.5) |
| Force touch | **The hardware does not exist** — 3D Touch was removed across the iPhone line; Haptic Touch is a long press | — |
| `Tooltip` | Triggered by hover or long press, neither of which exists here | A visible label |
| Pull-to-refresh | There is nothing to refresh; it is offline | — |
| Shake-to-undo | Undiscoverable, and unavailable to a phone in a pocket | The Undo action on the receipt |
| Horizontal swipe between pages (`PageView`, `TabBarView`) | It is a drag, and it makes "which screen am I on" a thing you discover by accident | A tap-based segment row of ≥60 pt targets |
| `Slider` / `RangeSlider` / `CupertinoPicker` | Drag-only by construction. There is no tap-only route to a value | The keypad (§8) or a `Wrap` of 60 pt choices |
| Swipe-to-dismiss a sheet or a receipt (`enableDrag`, `dismissDirection`) | Same tracking requirement as swipe-to-delete, and it can throw away the one on-screen proof that a record committed | An explicit ≥72 pt Cancel / Dismiss control |

**The one permitted tracked gesture is vertical scrolling**, with three mitigations: (a) Quick Entry fits without scrolling at 100% text scale on the smallest supported device, asserted by the reachability half of the overflow matrix; (b) long lists get tap-based paging (a jump strip of 60 pt targets) alongside scrolling; (c) **no action is ever reachable only behind a scroll.**

Enforcement is the rule table in §3.5 plus review. Three settings are not defaults and must be typed on every bottom sheet, because Flutter's defaults are all permissive: **`showDragHandle: false`** (a handle advertises a gesture the app does not support), **`enableDrag: false`** (the default is `true`, and it is drag-to-dismiss), **`isDismissible: false`** (a scrim tap is not a labelled target). The sheet closes through an explicit `tapPrimary` Cancel — this is the same rule `07-screens.md` §20.3 states from the layout side.

**Reopened, not answered:** volume-button shortcuts (spec §17.4) are contingent on whether the target hardware registers taps through a freezer bag. That is a hardware test, not a desk decision, and it is open. If the bag test fails, this whole section changes.

---

## 8. The custom numeric keypad

### 8.1 Why it exists instead of the system keyboard

1. **Key size is fixed by the OS** at roughly 44–50 pt — below our floor and below Parhi's optimum. Spec §7.1's "digits at least 40 pt" is about the *glyph*, which implies a key far larger than the system provides.
2. **Layout is fixed by the OS.** iOS puts `1` at the top of the pad, ~250 pt up the screen, outside the one-thumb zone.
3. **It steals half the viewport** and animates in. Quick Entry needs the filtered flock list, the recents strip *and* the pad visible at once.
4. **No domain keys.** We need a decimal key that always emits `.` (decision #57) and a confirm key labelled with its outcome.
5. **Appearance risk.** `TextField.keyboardAppearance` is honoured on iOS only; a third-party Android IME can and will render a bright keyboard in a dark shed. That is a white-flash vector we cannot close.

### 8.2 The geometry contract

```
┌───────┬───────┬───────┐   • 3 columns × 4 rows, fixed for the life of the app.
│   1   │   2   │   3   │   • Every cell ≥ tapPrimary (72) square.
├───────┼───────┼───────┤   • Cells separated by gapMin (16), so a 9 mm contact
│   4   │   5   │   6   │     patch centred on a gutter still resolves to one key.
├───────┼───────┼───────┤   • Bottom-left is ALWAYS backspace.
│   7   │   8   │   9   │   • Bottom-right is ALWAYS the decimal key; it renders
├───────┼───────┼───────┤     inert (surfaceRaised, textChrome, onTap null) when
│   ⌫   │   0   │   .   │     the field is integer-only. The grid never re-legends.
└───────┴───────┴───────┘   • leftHanded mirrors the bottom row only.
┌───────────────────────┐   • Confirm is a separate full-width tapHero (88) bar,
│      Create 412       │     labelled with the OUTCOME — "Use 412" / "Create 412"
└───────────────────────┘     — never a bare tick.
```

The component is `lib/core/ui/components/shed_keypad.dart` — **not** `features/quick_entry/widgets/`. Lambing Entry, Treatments and Settings all use it and layer rule 6 forbids a sibling import (§3.1).

Rules the component owns:

- **Digit glyph is `displaySmall` = `numeralSize`** — **40 pt** at text scale 1.0 in `night`, **44 pt** in either night-shift palette (§4.4), larger at any OS text scale above 1.0. Spec §7.1 asks for "digits at least 40 pt" and this meets it exactly at the smallest configuration the app can be in. It is the same role the pen tile uses for a tag (§11), which is deliberate: the digit you type and the digit you read back are the same size. *(A bare "44 pt" in a layout sketch elsewhere in the set is this role in a night-shift palette; the binding statement is the role, not the number.)*
- **The key box tracks the glyph**: `side = max(tapPrimary, scaler.scale(glyph) * 1.6)`. At scale 1.0 that is `max(72, 64) = 72`, so the floor governs until roughly 112% text scale, after which the pad grows. The pad is allowed to consume more screen as text grows; the list above it scrolls. **Never `FittedBox`.**
- **Haptic fires on down, before the state change**: `HapticFeedback.selectionClick()` — the lightest tick on both platforms — so the finger feels the *key*, not the result.
- **No key repeat on backspace.** Key repeat requires a held contact. A separate visible **Clear** control exists; clear-all is never a long press.
- **Layout order top to bottom:** entered tag (huge) → filtered matches (max 3 rows) → recents strip → keypad → confirm bar. If it does not fit, drop the matches to 2 rows. Never the keypad, never the recents strip.
- `Expanded` inside the keypad `Row` overrides `minWidth` and will silently shrink a key below the floor on a 320 pt device once page padding is added. Use explicit sizing plus the geometric gate at 320×568 (§6.3).
- Semantics: each key is a `ShedTapTarget` with `semanticLabel: '<digit>'` and the visible glyph inside — which is what gives it both the label and the tap action (§6.2). The pad is a labelled container; the tag buffer and the match count are live regions. Details in `10-accessibility-and-i18n.md`.
- **There is no OCR key and no microphone key.** Tag OCR and voice tag entry are cut from v1 (owner ruling §7.0); the pad is the only tag-entry route and must be designed as such, not as a fallback for something else. `08-platform-integration.md` records both as v2 candidates.

Every numeric entry in the app uses this pad — tags, litter counts, ease scores, days, **and weights** (decision #57). Free-text numeric fields reject ambiguity (`4,3` with both separators) rather than guessing; see `05-domain-correctness.md`.

---

## 9. No white flash: four layers, one colour

There are four layers in the launch sequence and a white frame at any one of them ruins the whole effort. There is no Dart-side fix for the first two — by the time Dart runs, the flash has happened.

```
[1] OS window background  →  [2] native launch screen  →  [3] Flutter first frame  →  [4] first route
    Android windowBackground   LaunchTheme /                MaterialApp.color          Scaffold background
    iOS Main.storyboard        SplashScreen API /            (theme.scaffoldBackgroundColor)
                               LaunchScreen.storyboard
```

**The single constant is `#0A0A0B`** — the `night` palette's base surface after N11-T04's P14 ruling, i.e. the *brightest* base any palette may have. (`#0B0D0E` remains the CEILING this document sets in §1; the shipped value is darker than it.) Every other palette is pure black, so the handoff can only ever go darker. `test/design/contrast_test.dart` asserts that invariant (§3.5).

### 9.1 Android

`android/app/src/main/res/values/colors.xml`:

```xml
<resources>
    <color name="shed_surface_base">#FF0B0D0E</color>
</resources>
```

`android/app/src/main/res/values/styles.xml` — note this is the **non-night** folder; the launch background must be dark even when the phone is in light mode:

```xml
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@color/shed_surface_base</item>
        <item name="android:statusBarColor">@color/shed_surface_base</item>
        <item name="android:navigationBarColor">@color/shed_surface_base</item>
        <item name="android:forceDarkAllowed">false</item>
        <item name="android:enforceStatusBarContrast">false</item>
        <item name="android:enforceNavigationBarContrast">false</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@color/shed_surface_base</item>
        <item name="android:forceDarkAllowed">false</item>
    </style>
</resources>
```

`android/app/src/main/res/values-v31/styles.xml` — Android 12+ replaces `windowBackground` with the SplashScreen API, which cannot be opted out of:

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

Kill the Android 12+ splash fade, because our splash and our first frame are the same solid field:

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

**There must be no `values-night/` folder.** Android's general dark-theme advice — use `?android:attr/colorBackground` so the splash follows the system theme — is exactly wrong for a dark-only app: a phone in light mode then launches white. **There must be no `io.flutter.embedding.android.SplashScreenDrawable` meta-data**; it has been deprecated since Flutter 2.5 and the migration doc says leaving it can cause a crash. Flutter already holds the Android launch screen until it draws the first frame, so there is no gap to fill — only gaps to avoid reintroducing.

### 9.2 iOS

There is no `colors.xml` equivalent on iOS, so the same three components are typed in three places and the parity gate (§9.4) is what keeps them equal. `11/13/14` is `#0B0D0E` in decimal; as storyboard floats it is **`red="0.043137"` `green="0.050980"` `blue="0.054902"` `alpha="1"` `colorSpace="custom" customColorSpace="sRGB"`**.

**1. `ios/Runner/Info.plist`** — three keys, none of them optional:

```xml
<key>UIUserInterfaceStyle</key>
<string>Dark</string>                     <!-- also darkens share sheets, alerts, any IME -->
<key>UILaunchStoryboardName</key>
<string>LaunchScreen</string>             <!-- the launch screen -->
<key>UIApplicationSceneManifest</key>          <!-- verbatim from the 3.44 template -->
<dict>
  <key>UIApplicationSupportsMultipleScenes</key><false/>
  <key>UISceneConfigurations</key>
  <dict>
    <key>UIWindowSceneSessionRoleApplication</key>
    <array><dict>
      <key>UISceneClassName</key><string>UIWindowScene</string>
      <key>UISceneConfigurationName</key><string>flutter</string>
      <key>UISceneDelegateClassName</key>
      <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
      <key>UISceneStoryboardFile</key><string>Main</string>   <!-- the app window -->
    </dict></array>
  </dict>
</dict>
```

`UILaunchStoryboardName` and `UISceneStoryboardFile` are **different keys naming different storyboards.** The UIScene migration adds the second; it does not replace the first — the 3.44 template ships both, alongside a `Runner/SceneDelegate.swift` that is an empty subclass of `FlutterSceneDelegate`. Deleting the wrong key produces a white launch screen *and* an App Store rejection. After the first `flutter build ios` on this toolchain, diff `Info.plist` and assert both survive.

**2. `ios/Runner/Base.lproj/LaunchScreen.storyboard`** — the root view's `backgroundColor`, written as a literal:

```xml
<view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
  <color key="backgroundColor" red="0.043137" green="0.050980" blue="0.054902"
         alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
</view>
```

Delete the template's `LaunchImage` image view or replace it with a small monochrome mark. **Never a named `UIColor`** (`systemBackgroundColor` and friends resolve per appearance and will hand you white on a phone in light mode).

**3. `ios/Runner/Base.lproj/Main.storyboard`** — the `FlutterViewController`'s view, same three floats. **This defaults to white in the Flutter template**, and it is the surface shown in the gap between the launch screen tearing down and Flutter's first frame. It is the layer people forget, because it is invisible on a fast device and a white flash on a cold one.

### 9.3 Flutter

`MaterialApp.color` and `theme.scaffoldBackgroundColor`/`canvasColor` are already the base surface (§2.1–2.2). Set the system bars once from the first frame:

```dart
SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
  statusBarIconBrightness: Brightness.light,          // Android
  statusBarBrightness: Brightness.dark,               // iOS (describes the background)
  systemNavigationBarIconBrightness: Brightness.light,
));
```

The first frame is a **static dark Quick Entry shell with a fully interactive keypad and no data** (decision #21). Nothing is awaited before `runApp()`. Because every palette is dark, a wrong first frame is a dark first frame — that is a deliberate property, not luck. Frame-1 placeholders (recents strip, "in the pens" list) are fixed-height `surfaceRaised` blocks so nothing shifts when data arrives, and **there is never a spinner**.

**Do not add a minimum splash duration**, and do not adopt `flutter_native_splash`: it is a generator that would own the files above as a second source of truth, and its maintainer has been publicly seeking a new owner since March 2026.

### 9.4 The parity gate

`tool/check_policy.dart` gains a `launch.colour_parity` rule — the one rule in the script that reads outside `lib/`. It parses the `nSurface04` hex out of `lib/core/ui/primitives.dart` and asserts:

- `android/app/src/main/res/values/colors.xml` declares `shed_surface_base` with that exact ARGB string;
- both `values/styles.xml` and `values-v31/styles.xml` reference `@color/shed_surface_base` and never a literal;
- no `values-night/` directory exists;
- `AndroidManifest.xml` contains no `io.flutter.embedding.android.SplashScreenDrawable` meta-data;
- `Info.plist` contains `UIUserInterfaceStyle = Dark`, `UILaunchStoryboardName = LaunchScreen`, and a `UIApplicationSceneManifest` whose `UISceneStoryboardFile` is `Main`.

The iOS storyboard *colour components* are stored as floats and parsing them is the fragile part of this gate; compare to within 1/255 and, if that proves brittle in practice, downgrade that one assertion to the release checklist rather than weakening the rest. **Mark as needing verification: the storyboard-parsing half has not been run.** Either way, the manual check stays: a cold launch on both platforms in a genuinely dark room, every release. A screenshot test cannot catch this — the flash is on the native side, before Flutter runs.

---

## 10. Feedback you can perceive without looking

Three channels, because each one fails silently on some device.

### 10.1 Haptics — real, never load-bearing

The vocabulary is deliberately tiny. On iOS three or four patterns are genuinely distinguishable through a glove; on Android assume two, because vendor LRA quality varies enormously and `CONFIRM`/`REJECT` only exist on API 30+. All of it can be switched off system-wide, and an app cannot detect that.

| Event | Haptic | Fires when |
|---|---|---|
| Key press / selection change | `HapticFeedback.selectionClick()` | pointer **down**, before the state change |
| **Record committed to SQLite** | `HapticFeedback.successNotification()` | the transaction **returned** `WriteCommitted` |
| Warning raised (spec §12.4 — e.g. "twin" with three lambs) | `HapticFeedback.warningNotification()` | the write committed **and** the controller's `List<Warning>` is non-empty |
| Write refused | `HapticFeedback.errorNotification()` | the transaction returned `WriteFailed` |

Nothing else — four patterns, and the table above is the whole vocabulary. If a shepherd cannot learn it in one night, it is too big. **The success haptic fires on the transaction returning, never on the tap** — a false receipt is worse than no receipt. `HapticFeedback.vibrate()` is banned: on Android it is a long buzz.

Two things the vocabulary deliberately has no entry for:

- **The free-tier cap never fires a haptic.** Both gated actions are calm-UI (adding ewe #16 from Flock, starting a second season — decision #91); a buzz would turn a calm gate into a rebuke, and `EntryContext.liveEntry` is structurally incapable of being blocked at all. See §12.
- **A contradiction is never "fixed" by a haptic.** The warning pattern says *"this is recorded and it disagrees with something"*, not *"try again"*. Both values are preserved verbatim (spec §12.4); the haptic is the same one whether or not the shepherd looks.

`successNotification`, `warningNotification` and `errorNotification` are real members of `HapticFeedback` on this SDK alongside `selectionClick` and the three impact levels — checked, because the iOS-only-sounding names invite the assumption that they are not.

### 10.2 Audio — none in v1

`SystemSound.play(SystemSoundType.click)` exists on both platforms but is a quiet, unobtrusive sound designed to disappear; in a shed with a ventilation fan it is inaudible. A confirmation loud enough to hear over a shed is loud enough to disturb stock and anyone asleep in the house, and anything better needs a real audio plugin with platform code, its own audio session and a silent-switch policy — a new dependency that must pass the offline allowlist, for a benefit we cannot demonstrate. Spec §5 also says "zero interruptions", and sound is the most interrupting channel.

**Revisit only if the field night shows haptics are unreliable on the shepherd's actual phone.** If so, the shape is an opt-in, off-by-default single tone, and the plugin must merge no `INTERNET` permission.

### 10.3 The "saved" affordance — proof, not optimism

There is no Save button in this app (decision #11), so the receipt *is* the confirmation that the row exists. The order is fixed:

```
tap → write → await the transaction → THEN change the UI
```

Never `tap → change UI → write in background`. A local SQLite write is single-digit milliseconds, so there is no UX case for optimism and a hard correctness case against it (spec §5, "assume the phone dies").

Three redundant channels (decision #103):

1. **Haptic** `successNotification()`, or `warningNotification()` when the controller passed a non-empty `List<Warning>` (§10.1) — perceivable with the phone in a bag and eyes on the lamb.
2. **A persistent SnackBar carrying the committed fact and an Undo.** On this SDK `SnackBar.persist` defaults to `action != null`, so an action-bearing SnackBar does not auto-dismiss — verified in the constructor, not assumed from a release note. Flutter already wraps `SnackBar` in `Semantics(container: true, liveRegion: true)`, which is the sanctioned announcement path on both platforms — **`SemanticsService.announce` is a no-op on Android**, where `NO_ANNOUNCE` is set unconditionally, and Android 16 deprecates announcements outright in favour of live regions.
3. **A visible state change in the underlying list.** The ewe moves to the top of the recents strip; her card gains today's event. This is the only signal still true five seconds later, and the only one that proves the *database* changed rather than a toast being shown.

**The three confirmation channels are functions, and they have exactly three names** (CONVENTIONS R10, R30): `confirmSaved`, `showFailure` and `showCapRow`. All three live in `lib/core/ui/feedback.dart`, which is the one file in the app permitted to call `showSnackBar(`. `showShedReceipt` and `showShedFailure` are banned spellings. `components/shed_receipt.dart` keeps the `ShedReceiptBar` *widget* and nothing else.

```dart
// lib/core/ui/feedback.dart
//
// The ONLY call site of showSnackBar in the app. lib/features/** is grepped
// for showSnackBar( so a screen cannot hand-roll a receipt that misses one of
// the three channels or re-admits swipe-to-dismiss (§3.5, gesture.raw_snackbar).
// A feedback function holds a BuildContext and nothing else: no WidgetRef, no
// provider read, no navigation.

/// What a receipt says. `at` is pre-formatted `HH:mm`, 24-hour, en_GB (owner
/// ruling §7.0 #3) by lib/core/ui/formatters.dart, never here. `undoLabel`
/// exists because the label is not always "UNDO": it is "Correct this" on a
/// foster and "Void this" on a treatment (07-screens.md §15.3).
@immutable
final class SaveReceipt {
  const SaveReceipt({
    required this.term,
    required this.tag,
    required this.summary,
    required this.at,
    this.undo,
    this.undoLabel = 'UNDO',
  });

  final String term, tag, summary, at;
  final VoidCallback? undo;
  final String undoLabel;
}

/// Channels 1 and 2 for a committed record. `warnings` comes from the
/// CONTROLLER, which runs lib/domain/validation/ against the freshly-watched
/// row — a repository structurally cannot produce one (CONVENTIONS R53).
/// Empty list => the success haptic; non-empty => the warning haptic (§10.1).
void confirmSaved(
  BuildContext context,
  SaveReceipt receipt,
  List<Warning> warnings,
) {
  if (warnings.isEmpty) {
    HapticFeedback.successNotification();
  } else {
    HapticFeedback.warningNotification();
  }
  // The live region only re-fires on didChangeLabel(). Two saves in ten seconds
  // is normal during triplets, so the text MUST differ every time: tag +
  // summary + wall-clock time guarantees it.
  final String message =
      '${receipt.term} ${receipt.tag} · ${receipt.summary} · ${receipt.at}';
  final VoidCallback? undo = receipt.undo;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message, style: Theme.of(context).textTheme.bodyLarge),
    // SnackBarAction.onPressed is non-nullable, so a verb with no undo gets no
    // action at all — and, because `persist` defaults to `action != null`, that
    // receipt is the one case that obeys `duration`.
    action: undo == null
        ? null
        : SnackBarAction(label: receipt.undoLabel, onPressed: undo),
    // `persist` defaults to `action != null` on this SDK, so an action-bearing
    // SnackBar already ignores `duration`. Stated, not set: a `duration:` line
    // here reads as if it were load-bearing and would mislead the next reader.
    // Swipe-to-dismiss is a banned gesture (§7) and is NOT the default.
    dismissDirection: DismissDirection.none,
  ));
}

/// The failure channel. `failure.userMessage` is one of the six strings on
/// ShedFailure (01-architecture.md §5.1) — plain, actionable, no codes, no
/// blame. This function never composes its own copy and never shows a dialog.
void showFailure(BuildContext context, ShedFailure failure) {
  HapticFeedback.errorNotification();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content:
        Text(failure.userMessage, style: Theme.of(context).textTheme.bodyLarge),
    dismissDirection: DismissDirection.none,
  ));
}

/// The free tier's only feedback channel — calm, static, never a modal, and the
/// one channel with NO haptic (§10.1): both gated actions are calm-UI, and
/// EntryContext.liveEntry is structurally incapable of being refused (§12).
void showCapRow(BuildContext context, RefusalReason reason) {
  // No haptic, no scrim, no dialog, no auto-dismiss: it is the ShedBanner row
  // of §12 — two `tapMin` actions, textSecondary on surfaceRaised, no accent,
  // no badge — shown through ScaffoldMessenger.showMaterialBanner, the one
  // non-modal persistent surface the framework offers. It leaves the screen
  // only when one of the row's own actions is tapped, and it is a no-op
  // between 22:00 and 06:00 on every screen (§12).
  // 11-monetization-and-store.md owns the copy each RefusalReason maps to;
  // this file owns the channel and the guarantee that it is never a modal.
}
```

**The receipt has exactly three ways to leave the screen**, none of them a swipe: the Undo is tapped, the next receipt replaces it, or the route pops. That is also the Undo window — **it does not survive process death and the copy must not imply it does.** Undo replaces swipe-to-delete and is defined per verb in the repository, not generically; see `07-screens.md`.

`SnackBarAction`'s default target does not meet the 60 pt floor. The theme sets `actionOverflowThreshold: 0` so the action always takes its own full-width line (§2.2), and the Quick Entry tap-target test runs with a receipt visible. **If that still fails the guideline, replace `SnackBar` with a house `ShedReceiptBar` in an `OverlayEntry`** — the three channels are the requirement, `SnackBar` is only the current implementation. A `ShedReceiptBar` must then carry its own `Semantics(liveRegion: true)` with the same uniqueness rule and its own ≥60 pt Dismiss, because it inherits none of `SnackBar`'s framework wrapping.

---

## 11. Pen-board glanceability

Spec §7.4: "legible from arm's length in a head torch" — a ~60 cm viewing distance in a narrow, high-contrast pool of light.

**Type scale.** At 60 cm the limiting factor is angular size, and the arithmetic is worth writing down because it is the only justification the numbers in this table have.

Using §6.1's conversion — 1 logical pixel = 0.15875 mm, independent of screen ppi — a `numeralSize` of 40 is a **6.35 mm em box**. Digit height is roughly the cap height of the face, ~0.72 em for a humanist sans, so the painted numeral is about **4.6 mm**. At 600 mm that subtends 4.6/600 = 0.0076 rad ≈ **26 arc-minutes**. A letter subtending 5 arc-minutes is 20/20 acuity by definition, so the pen-tile tag is about **5× the threshold size** for a normally-sighted eye at high contrast — the margin that has to absorb tiredness, a moving torch beam, and a screen that is not perpendicular to the eye.

Two honest caveats on that number. The 0.72 em cap-height figure is a typical value, not a measurement of Atkinson Hyperlegible Next; measure it once when the font is locked in (§5.2) and update this paragraph rather than leaving a plausible number standing. And 26 arc-minutes is the *angular* answer only — it says nothing about legibility at 4.69:1 contrast in the deep-red palette, which is why §4.4 buys stroke back with size.

| Element | Role | Size |
|---|---|---|
| Tag number | `displaySmall`, tabular | `numeralSize` (40 / 44) |
| Hours since penned | `headlineLarge`, tabular | 32 |
| Everything else | `bodyMedium` | `bodySize` (18 / 20) |

**A tile shows at most three facts: tag, hours, status.** Lamb count, dam, treatments all live on the detail view. Four facts at 60 cm is zero facts.

**Colour is never the only channel** (decision #106, WCAG 1.4.1 Level A). Three reasons bind harder here than usual: colour-vision deficiency affects roughly 1 in 12 men and this user base skews male; the night-shift palettes deliberately destroy the hue channel; and a head torch's colour temperature shifts perceived hue anyway. So every status carries four encodings:

| Status | Colour token | Shape | Text | Position |
|---|---|---|---|---|
| Settling (< threshold) | `textSecondary` | plain tile, no border | `4h` | default order |
| Ready to turn out | `statusReady` | thick left bar + filled corner triangle | `26h · READY` | sorted to top |
| Under withdrawal / treating | `statusAttention` | dashed outline + circle-slash badge | `12h · CLEAR 14 JUL` | badge on cell |
| Loss recorded | `statusLoss` | diagonal hatch fill | `DEAD` | sorted to top |
| Empty pen | `outline` only | dashed border, no fill | `—` | sorted to bottom |

The shapes must be **structurally different in silhouette** — bar, triangle, dashed outline, hatch, dash — not four variants of one glyph. Under a torch at 60 cm, four similar icons are one icon. Verification is not a discussion: run the board under the OS grayscale filter and read it. If you cannot, it fails.

**Reflow, never clip.** The grid is `LayoutBuilder`-driven on a minimum tile width derived from `MediaQuery.textScalerOf(context).scale(numeralSize)`, so the column count drops 4 → 3 → 2 → 1 as text grows and the board scrolls in one axis only. A shepherd at 200% text needs a bigger `26h`, not a four-across board with clipped numbers. The board stops being glanceable at that scale, and that is the correct trade.

**Timers come from one app-level, boundary-aligned 60 s ticker** (decision #66) — `minuteTickProvider`, `StreamProvider.autoDispose<Instant>` in `lib/core/time/ticker.dart`, owned by `02-state-di-navigation.md`. Not a `Timer.periodic` per tile: 30 timers is measurable overnight battery, and a grid whose cells update at different moments reads as noise under a head torch. Display granularity is hours, so a 30 s tick buys nothing.

**Honest timestamps reach the tile** (spec §12.5). A pen entry time that was edited is marked *on the board* — a `~` prefix or an "edited" chip — not only on the detail screen. The board is what people trust, so the board must not launder an edited time as a captured one. Provenance labels come from `RecordedTime.provenanceLabel`; see `05-domain-correctness.md`.

---

## 12. Component inventory

Everything the 12 screens need. Every one of them lives in `lib/core/ui/components/` (§3.1). All dimensions are logical pixels at scale 1.0; all colours are token names. States are: **default / pressed / disabled / selected**; there is no hover, no focus ring driven by a mouse, and **no loading state anywhere** (decision #71: never a spinner).

| Component | Size contract | States | Notes |
|---|---|---|---|
| `ShedTapTarget` | ≥ `tapMin` both axes | default, pressed, disabled | The only sanctioned tap surface. Required `semanticLabel`; `Semantics(onTap:)` set (§6.2). |
| `ShedPrimaryButton` | ≥ `tapHero` tall, ≥ 2 × `tapPrimary` wide | default, pressed, disabled | `labelLarge`, `surfaceFill` on `surfaceBase`. |
| `ShedSecondaryButton` | ≥ `tapPrimary` tall | default, pressed, disabled | Outlined at `outlineWidth`. |
| `ShedDestructiveButton` | ≥ `tapPrimary` tall | default, pressed, disabled, **confirming** | Never within `gapDestructive` of a frequent action; two-step. |
| `ShedKeypad` | 3 cols × 4 rows, cells ≥ `tapPrimary`, gutters `gapMin` | key default/pressed, decimal inert | §8. Fixed geometry; mirrors on `leftHanded`. Glyph is `displaySmall`. |
| `ShedConfirmBar` | full width × `tapHero` | default, pressed, disabled | Labelled with the outcome ("Create 412"). |
| `ShedRecentsStrip` | 6 chips × `tapPrimary` | chip default/pressed/selected, **placeholder** | Fixed height at frame 1 so nothing shifts. |
| `ShedAnimalRow` | ≥ `tapPrimary` tall, full width | default, pressed, selected | Tag `displaySmall` tabular + one summary line. |
| `ShedPenTile` | ≥ 2 × `tapPrimary` square, reflowing | settling, ready, attention, loss, empty | §11. Four encodings per status. |
| `ShedStatusBadge` | ≥ 24 tall inside a ≥ `tapMin` parent | one per status | Icon **and** word, always. Never colour alone. |
| `ShedCountdown` | `headlineLarge` tabular | active, clear, **not recorded** | "Not recorded" is a first-class state — never `0`, never blank. |
| `ShedChoiceRow` | n × `tapPrimary`, wraps | default, pressed, selected | Birth type, ease 1–5, death cause. `Wrap`, not `Row`. |
| `ShedFieldRow` | ≥ `tapMin` tall | default, pressed, empty | Label **above** value, so it survives 200%. |
| `ShedSectionHeading` | `titleMedium` | — | Emits `headingLevel: 2`; screen titles emit `1`. `header:` is banned. |
| `ShedBottomSheet` | content anchored to the bottom | — | `showDragHandle: false`, **`enableDrag: false`**, `isDismissible: false`, explicit `tapPrimary` Cancel (§7). |
| `ShedReceiptBar` | ≥ `tapHero` tall incl. the Undo | visible, dismissed | §10.3. The widget only — the three functions live in `feedback.dart`. Live region; text unique per save; `dismissDirection: none`. |
| `ShedBanner` | ≥ `tapHero` tall, two `tapMin` actions | visible, dismissed | Export prompt, upgrade row. Never modal, never on the 3am path, never 22:00–06:00. |
| `ShedEmptyState` | **occupies the same box the populated content will** | one per screen | One line of copy + one action, at the same `tapHero` control the populated screen uses. No illustration, no spinner, no tour. |
| `ShedPhoto` | fills its box | tinted, full colour | §4.7. The only `ColorFiltered`. |
| `ShedSpreadChart` | ≥ `tapMin` per bar; scrolls rather than shrinking | — | Hand-rolled `CustomPainter` with `semanticsBuilder`; 18 pt minimum labels, no hover tooltips. Spec in `07-screens.md`. |
| `NightErrorPanel` | full screen | — | `ErrorWidget.builder`. Hard-coded hexes, own `Directionality`, no `Theme`/`MediaQuery` (§2.4). |

**What the design system contributes to the free tier.** The tier is **season-primary, with the ewe cap as a calm secondary gate** (owner ruling §7.0 #8). Three constraints fall out of that and are this document's to enforce, not `11-monetization-and-store.md`'s:

1. **`ShedBanner` is the only monetization component that exists.** There is no modal, no interstitial, no self-appearing sheet, no badge and no colour change (decision #92). If a visual direction proposes an accent for the upgrade row, it is refused: the row renders in `textSecondary` on `surfaceRaised` like any other row.
2. **It never renders on Quick Entry, Lambing Entry, Lamb Card, Foster or Pen Board** — the five 3am screens (decision #90). It renders in exactly two places, the Flock screen and Settings, in the same pixels at 0 ewes as at 15.
3. **It never renders between 22:00 and 06:00**, on any screen, at any ewe count. That is the ruling, not a nicety: the whole product thesis is that nothing interrupts a lambing night. The widget test that proves it sets the clock, not the entitlement.

---

## Definition of done

Tick every line before calling the design system finished.

**Tokens**
- [ ] The design system is under `lib/core/ui/`; there is no `lib/design/` folder and no shared component under a feature's `widgets/`.
- [ ] `lib/core/ui/primitives.dart` is the only file in the app containing a colour literal, and only `palettes.dart` imports it; the policy gate proves both.
- [ ] `ShedTokens` is the only `ThemeExtension`, is flat, and its `lerp` switches metrics at `t < 0.5` rather than interpolating them.
- [ ] `context.tokens` is the only way a widget obtains a colour or a metric; `colorScheme` appears nowhere under `lib/features/` or `lib/core/ui/components/`.
- [ ] Every design rule in §3.5 is a row in `tool/check_policy.dart`'s `_bannedText` or `_bannedPattern`, using 01's tuple shape and allowlist keys; there is no second script and no inline comment escape hatch.
- [ ] `tool/policy_allowlist.txt`'s `[exempt]` section has exactly the four lines in §3.5 — no more.
- [ ] The script exits non-zero on a seeded violation of each design rule.

**Palettes**
- [ ] Six palettes authored as literal constructor calls; `ColorScheme.fromSeed` appears nowhere.
- [ ] Every `ColorScheme` sets the nine required M3 roles plus the pinned ones in §2.3, and sets none of the deprecated ones (`background`, `onBackground`, `surfaceVariant`).
- [ ] `test/design/contrast_test.dart` recomputes every published ratio and passes, including the documented AA exception for standard-contrast deep red.
- [ ] The luminance test passes: both night-shift palettes peak below 70% of `night`'s peak.
- [ ] No palette's `surfaceBase` is brighter than the native launch colour.
- [ ] Settings shows exactly the four labels in §4.1, verbatim.
- [ ] Both night-shift palettes have been reviewed after ten minutes of dark adaptation, not from a screenshot.

**Type**
- [ ] `AtkinsonHyperlegibleNext[wght].ttf` and `OFL.txt` are committed; `LicenseRegistry.addLicense` registers the licence; `google_fonts` is absent from `pubspec.yaml` and from `lib/`.
- [ ] The font's byte count and `wght` axis range have been read off the actual file and recorded in `docs/perf/measurements.md`; the axis covers 500–700.
- [ ] The whole M3 `TextTheme` is overridden; nothing renders below 18.
- [ ] No style exceeds `FontWeight.w700`; the grep proves it.
- [ ] Every aligned numeral goes through a tabular role; the pen-board golden proves it.
- [ ] `textScaleFactor`, `TextScaler.clamp` and `withClampedTextScaling` appear nowhere; `withNoTextScaling` appears only around icon fonts.
- [ ] The 0/O legibility check has been run on a real device under a head torch.

**Interaction**
- [ ] `ShedTapTarget` is the only tap surface; every instance carries a `semanticLabel`, and every enabled instance exposes `SemanticsAction.tap`.
- [ ] Both tap-target gates run on all 12 screens, and every `meetsGuideline` and `getSemantics` run begins with `tester.ensureSemantics()` + `addTearDown`.
- [ ] The geometric gate passes at 320×568 with textScaler 2.0.
- [ ] Every banned gesture has a rule row and zero hits, including `enableDrag: true`, `Slider`, `PageView` and a bare `showSnackBar(` in `lib/features/`.
- [ ] Every bottom sheet sets `showDragHandle: false`, `enableDrag: false` and `isDismissible: false`.
- [ ] No action anywhere is reachable only by scrolling.

**Launch**
- [ ] Cold launch verified by eye on both platforms in a dark room; no frame is brighter than `#0B0D0E`.
- [ ] No `values-night/`; no `SplashScreenDrawable` meta-data; `UIUserInterfaceStyle = Dark`; both iOS storyboard keys present after the UIScene migration.
- [ ] The `launch.colour_parity` rule passes (or its storyboard half is explicitly deferred to the release checklist, in writing).

**Feedback and the board**
- [ ] The haptic vocabulary has exactly four entries and the success haptic fires after the transaction returns.
- [ ] The receipt text is unique per save, the Undo target measures ≥ 60 pt, and the receipt cannot be swiped away.
- [ ] `showSnackBar(` appears in exactly one file, `lib/core/ui/feedback.dart`, which holds `confirmSaved`, `showFailure` and `showCapRow` and no others; `showShedReceipt` and `showShedFailure` appear nowhere.
- [ ] No optimistic UI anywhere: no screen shows a committed fact before the write returns.
- [ ] The pen board is readable under the OS grayscale filter.
- [ ] Every pen status carries colour **and** shape **and** text **and** position.
- [ ] One 60 s app-level ticker drives every timer; no per-tile timers exist.
- [ ] An edited pen entry time is visibly marked on the tile.

**Free tier (the design system's half of it)**
- [ ] `ShedBanner` is the only monetization component; there is no modal, interstitial or self-appearing sheet anywhere in `lib/`.
- [ ] It renders on exactly two screens, in the same pixels at 0 ewes as at 15, with no accent colour and no badge.
- [ ] A widget test with the clock set to 23:30 renders no upgrade row on any screen.

---

## References

Fetched 2026-07-27 unless noted.

**Checked against the SDK, not against a doc page.** Every Flutter symbol in this document was resolved in a local Flutter **3.44** checkout on 2026-07-27: `HapticFeedback.{selectionClick, successNotification, warningNotification, errorNotification}`, `PredictiveBackPageTransitionsBuilder({fallbackColor})` (plural — the singular does not exist), `SnackBar.{persist, dismissDirection}`, `SnackBarThemeData.{insetPadding, actionOverflowThreshold}`, `MinimumTapTargetGuideline({size, link})`, `labeledTapTargetGuideline`, `textContrastGuideline`, `WidgetTester.getSemantics`, `SemanticsNode.hasAction`, `Semantics.{onTap, onTapHint, headingLevel}`, `ThemeExtension.lerp(covariant …)`, `ColorScheme`'s nine required roles and its three deprecated ones, `Color.{r, g, b, computeLuminance}`, `Flex.spacing`, `MediaQuery.{disableAnimationsOf, withNoTextScaling, withClampedTextScaling}`, `TextScaler.clamp`, `FontFeature.tabularFigures`, `InkSparkle.splashFactory`, `VisualDensity.standard`, and the iOS `Info.plist` UIScene keys, which are quoted from `flutter_tools/templates/app/ios.tmpl/Runner/Info.plist.tmpl`. The pinned toolchain is 3.44.8; the checkout available was 3.44.6, whose SDK pins decision-record §5 records as identical, so no symbol below is version-sensitive within 3.44.

**Flutter — breaking changes and API**
- Material 3 tokens update (`material_color_utilities`, the version Flutter 3.44 pins is 0.13.0) — https://docs.flutter.dev/release/breaking-changes/material-color-utilities
- `FontWeight` drives the `wght` axis — https://docs.flutter.dev/release/breaking-changes/font-weight-variation
- SnackBar-with-action no longer auto-dismisses — https://docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update
- Deprecated splash-screen API migration — https://docs.flutter.dev/release/breaking-changes/splash-screen-migration
- Android 14 non-linear text scaling — https://docs.flutter.dev/release/breaking-changes/android-14-nonlinear-text-scaling-migration
- `textScaleFactor` deprecation — https://docs.flutter.dev/release/breaking-changes/deprecate-textscalefactor
- `header` / `headingLevel` behaviour change — https://docs.flutter.dev/release/breaking-changes/semantics-header-heading-level
- UIScene delegate adoption — https://docs.flutter.dev/release/breaking-changes/uiscenedelegate
- `ThemeExtension` — https://api.flutter.dev/flutter/material/ThemeExtension-class.html
- `MinimumTapTargetGuideline` — https://api.flutter.dev/flutter/flutter_test/MinimumTapTargetGuideline-class.html
- `MaterialTapTargetSize` — https://api.flutter.dev/flutter/material/MaterialTapTargetSize.html
- `HapticFeedback` — https://api.flutter.dev/flutter/services/HapticFeedback-class.html
- `MediaQueryData` — https://api.flutter.dev/flutter/widgets/MediaQueryData-class.html
- `TextScaler` — https://api.flutter.dev/flutter/painting/TextScaler-class.html
- `FontFeature` — https://api.flutter.dev/flutter/dart-ui/FontFeature-class.html
- `ColorFilter.matrix` — https://api.flutter.dev/flutter/dart-ui/ColorFilter/ColorFilter.matrix.html
- Performance best practices (`saveLayer`) — https://docs.flutter.dev/perf/best-practices
- flutter#139712 — Bold Text makes extra-bold text *less* bold — https://github.com/flutter/flutter/issues/139712

**Platform**
- Apple UI design tips (44×44 pt) — https://developer.apple.com/design/tips/
- App Store Review Guidelines (2.5.9, volume switches) — https://developer.apple.com/app-store/review/guidelines/
- Android accessibility (48 dp, 8 dp separation) — https://developer.android.com/guide/topics/ui/accessibility/apps
- Android 12+ splash screen — https://developer.android.com/develop/ui/views/launch/splash-screen
- Android dark theme — https://developer.android.com/develop/ui/views/theming/darktheme
- Android 16 behaviour changes (announcement deprecation) — https://developer.android.com/about/versions/16/behavior-changes-all

**Standards**
- WCAG 2.2 contrast minimum — https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
- WCAG 2.2 use of colour (1.4.1) — https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html
- WCAG 2.2 target size minimum / enhanced — https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html · https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced.html
- APCA in a Nutshell (WCAG 2.x overstates contrast near black) — https://git.apcacontrast.com/documentation/APCA_in_a_Nutshell.html

**Vision science and HCI**
- StatPearls, *Physiology, Night Vision* — https://www.ncbi.nlm.nih.gov/books/NBK545246/
- Webvision, *Light and Dark Adaptation* (~40 min to absolute threshold) — https://www.webvision.pitt.edu/book/part-viii-gabac-receptors/light-and-dark-adaptation/
- Parhi, Karlson & Bederson, MobileHCI 2006 (9.2 / 9.6 mm) — https://www.microsoft.com/en-us/research/publication/target-size-study-for-one-handed-thumb-use-on-small-touchscreen-devices/
- Touch-screen performance with and without motor control disabilities — https://pmc.ncbi.nlm.nih.gov/articles/PMC3572909/
- Hoober, *How Do Users Really Hold Mobile Devices?* (67% right thumb / 33% left) — https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php

**Fonts**
- Atkinson Hyperlegible Next, OFL 1.1 — https://github.com/google/fonts/tree/main/ofl/atkinsonhyperlegiblenext
- Braille Institute free font page — https://www.brailleinstitute.org/freefont/
- Inter (fallback; OFL 1.1, `tnum` + slashed zero) — https://github.com/rsms/inter

**Sources that could not be verified, carried forward as such**
- The naval/aviation red-vs-white dark-adaptation finding ("intensity matters more than colour") is reported from secondary summaries; the primary DTIC report returned HTTP 403 and was never fetched. Treated as medium confidence in §4.3.
- OLED black smear and halation claims are design-literature leads with no primary clinical citation. They inform the choice of `#0B0D0E` over `#000000` but are not load-bearing — the surface-ramp argument is.
- Note 05 §4.3 printed **7.36:1** for `#FF6B4A` on `#000000`; recomputation with the WCAG formula on 2026-07-27 gives **7.45:1**. Every ratio in §4 above is the recomputed value, and `test/design/contrast_test.dart` is the authority. The night palette's three surface-ramp steps were also recomputed and are **1.07 / 1.18 / 1.36**, not the 1.08 / 1.20 / 1.42 an earlier draft printed.
- **Atkinson Hyperlegible Next's file size and `wght` axis range are unverified** — the font was never downloaded while this document was written. §5.2 states the check that must run before the pubspec entry is written. Decision-record §5 does not carry the font, so there is no authoritative number to copy.
- **The 0.72 em cap-height figure in §11 is a typical value for a humanist sans, not a measurement of this face.** Everything downstream of it — 4.6 mm, 26 arc-minutes, "~5× threshold" — inherits that uncertainty. Measure it when the font is locked in.
- **The storyboard-parsing half of the `launch.colour_parity` gate has not been run** (§9.4). The Android half is trivial string matching; the iOS half compares floats parsed out of XML and may prove brittle.
- **Whether the deep-red palette is usable at 4.59:1 for secondary text under a real head torch is not a desk question.** §4.8's ten-minute dark-adaptation procedure is the only test that answers it, and it has not been run.

**Sibling documents**
`00-README.md` · `01-architecture.md` (the folder tree, the policy-script harness, `main()`, `NightErrorPanel`) · `02-state-di-navigation.md` (`ShedBookApp`, `themeProvider`, `Routes`) · `05-domain-correctness.md` (`RecordedTime`, units, `StatResult`) · `07-screens.md` (per-screen briefs, empty-state copy, undo per verb) · `08-platform-integration.md` (why OCR and voice tag entry are v2) · `10-accessibility-and-i18n.md` (semantics, headings, live regions, ARB) · `11-monetization-and-store.md` (the free-tier policy object behind §12's three constraints) · `12-testing.md` (the 252-cell matrix, goldens, the a11y gates) · `13-build-ci-release.md` (CI shape, size budget) · `../design/00-directions.md` (the three candidate visual directions).

**Three edits this document requires in `01-architecture.md`,** flagged here rather than made silently. The first two are settled: §2.2's tree adds `test/design/` to the `mkdir` line (CONVENTIONS R57) and moves `big_keypad.dart` to `core/ui/components/shed_keypad.dart` (R70); and its Definition of Done counts **four** `[exempt]` allowlist lines, not two (R56, and §4.7 of CONVENTIONS prints the four).

The third is **open and belongs to 01, which owns the layer table.** `showFailure(BuildContext, ShedFailure)` is canonical (CONVENTIONS §2.11, R10/R30) and lives in `lib/core/ui/feedback.dart`, but `ShedFailure` is declared in `lib/core/failure.dart` and CONVENTIONS §1.1 gives `_mayImport['lib/core/ui/'] = {'lib/core/ui/', 'lib/domain/'}` — which forbids the import the canonical signature requires. R16 made exactly this amendment for `lib/core/db/`; the same amendment is needed here, or `feedback.dart` does not compile. This document does not make it: the signature above is the binding one either way.

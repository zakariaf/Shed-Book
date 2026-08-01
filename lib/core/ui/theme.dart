// lib/core/ui/theme.dart — where Material's defaults get corrected.
//
// DARK-ONLY IS NOT A DEFAULT HERE; IT IS THE ABSENCE OF AN ALTERNATIVE. A light
// theme that exists but is never selected is one `themeMode` away from being
// selected — by a future contributor, by a system setting, or by a framework
// upgrade — and a white screen at 03:20 costs a shepherd ten minutes of night
// vision.
//
// The quieter half of this file is just as load-bearing: `MaterialTapTargetSize`,
// `VisualDensity` and the predictive-back gutter colour are all wrong for this
// app out of the box, and each is wrong in a way that is invisible on a
// developer's machine.
//
// Layer rule 7: this file may import lib/core/ui/, lib/domain/,
// package:flutter/* and package:intl. No riverpod, no drift, nothing under
// lib/data/ — which is why `themeProvider` is N12's and could not live here even
// if it were wanted.
// CupertinoPageTransitionsBuilder lives in src/cupertino/route.dart and is NOT
// exported by material.dart on this SDK — 06 §2.2's snippet assumes it is, and
// the compile error names the type rather than the missing import. Scoped with
// a show clause so the rest of Cupertino stays out of this file.
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/palettes.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// The pair every palette id resolves to.
///
/// `highContrast` is a genuinely different palette and **never the same object**
/// as `theme` (decision #95); 06 §4.5 calls the alternative *"dead plumbing
/// while claiming to honour the flag"*. Because the `highContrast` flag only
/// ever fires on iOS, the same variant is also reachable from a Settings switch
/// on both platforms (N29).
///
/// ## How `ShedBookApp` consumes this (N11-T05)
///
/// Written here so N11 does not have to re-derive it. Both brightness slots hold
/// the **same object**, so no `Brightness` change, no `Theme` widget in a test
/// harness and no platform event can select light:
///
/// ```dart
/// theme: t.theme,
/// darkTheme: t.theme,
/// highContrastTheme: t.highContrast,
/// highContrastDarkTheme: t.highContrast,
/// themeMode: ThemeMode.dark,
/// color: t.theme.scaffoldBackgroundColor,
/// themeAnimationDuration: Duration.zero,
/// ```
///
/// `themeAnimationDuration: Duration.zero` is not a nicety. 06 §4.8: a 200 ms
/// lerp between night and deep red *"drags every colour through a desaturated,
/// low-contrast midpoint"*. It is also what makes `ShedTokens.lerp` unreachable
/// in the running app, which is the argument that made full snapping free.
typedef ShedThemeSet = ({ThemeData theme, ThemeData highContrast});

/// Both halves of one palette id, ready for `ShedBookApp`.
ShedThemeSet buildShedThemeSet(ShedPaletteId id) => (
  theme: buildShedTheme(resolvePalette(id, highContrast: false)),
  highContrast: buildShedTheme(resolvePalette(id, highContrast: true)),
);

/// Every line in this body is a correction of a Material default.
ThemeData buildShedTheme(ShedPalette p) {
  final ShedTokens t = p.tokens;
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: p.colorScheme,
    extensions: <ThemeExtension<dynamic>>[t],

    // The first painted frame's colour, reached three ways that must agree.
    // The native halves — windowBackground, windowSplashScreenBackground,
    // LaunchScreen.storyboard and Main.storyboard — are N11-T06 and N11-T07,
    // and launch.colour_parity (N11-T08) is what keeps them equal to this.
    scaffoldBackgroundColor: t.surfaceBase,
    canvasColor: t.surfaceBase,

    // MaterialTapTargetSize.padded is 48, not 60. It is a floor UNDER our
    // floor, not the rule: the 60 pt contract comes from ShedTapTarget (T07)
    // and the 64 x 64 build box from indelible.md §4.5. Do not read `padded`
    // as "handled".
    materialTapTargetSize: MaterialTapTargetSize.padded,

    // adaptivePlatformDensity is NEGATIVE on some platforms and silently
    // subtracts up to 4 px per axis from every Material control. On a 60 pt
    // floor with 4 pt of headroom that is the whole margin.
    visualDensity: VisualDensity.standard,

    // indelible.md §5.1: a press is a FILL CHANGE ONLY — no scale, no lift, no
    // ripple, because "a target that shrinks under a cold thumb is a target you
    // miss". 06 §2.2 printed InkSparkle.splashFactory; 06 §1 gives the design
    // direction authority over "the visual form of a target", so indelible.md
    // has the stronger claim and this is the consistent value. A ripple would
    // also animate under reduce-motion, which T09 has to resolve to zero.
    splashFactory: NoSplash.splashFactory,

    textTheme: buildShedTextTheme(t),

    // Predictive back is the DEFAULT Android page transition on this SDK and
    // paints a gutter behind the outgoing page. Without fallbackColor that
    // gutter is the platform default — i.e. light. This is a white flash that
    // appears only on a real Android device, mid-navigation, and no test in
    // this project catches it.
    //
    // The type is PLURAL — PredictiveBackPageTransitionsBuilder. The singular
    // does not exist and is the single easiest compile error to make here.
    pageTransitionsTheme: PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(fallbackColor: t.surfaceBase),
        TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
      },
    ),

    // NOT AUTHORED, DELIBERATELY:
    //
    //   * the snackBarTheme block 06 §2.2 prints. P2 supersedes it — there is
    //     no SnackBar in this product, and theming a widget that cannot be
    //     constructed is dead configuration that reads as permission.
    //   * filledButtonTheme / outlinedButtonTheme / iconButtonTheme. 06 §2.2
    //     wires them to shedPrimaryButtonStyle, shedSecondaryButtonStyle and
    //     shedIconButtonStyle, which are N10's components and do not exist yet.
    //     They arrive with the widgets they style; adding a stub here would put
    //     a second source of button geometry one epic ahead of the first.
  );
}

/// M3's `bodyLarge` is 16.0 and spec §5 says 18 pt minimum body, so the **whole**
/// `TextTheme` is overridden.
///
/// `bodySmall` and `labelSmall` are **collapsed into the 18 pt floor** rather
/// than kept as distinct sizes: if a piece of text is not worth 18 pt at 3am, it
/// is not worth showing.
///
/// Every role goes through [s]. 06 §5.4: constructing a fresh `TextStyle`
/// instead of copying one drops `fontFeatures`, and the pen board starts
/// jittering as `412` and `108` take different widths — a failure that is silent
/// and only visible in motion.
///
/// **This is structure, not face.** T05 lands `fontFamily`, the variable weight
/// axis and the P7 ruling on top of it. There is deliberately no `fontFamily`
/// here: naming a family before its asset is committed renders every glyph in
/// the platform fallback and hides exactly the problem T05 exists to solve.
TextTheme buildShedTextTheme(ShedTokens t) {
  const List<FontFeature> tabular = <FontFeature>[FontFeature.tabularFigures()];

  // Named rather than written inline, because the literal form fires the gate's
  // token.magic_size row — and the row is RIGHT to fire: its remedy is "use the
  // spacing or tap scale", which is to say, name the value. (This comment
  // describes the literal rather than quoting it, because the row scans this
  // file and a quoted example is indistinguishable from the real thing.) It
  // cannot come from
  // primitives.dart — token.primitives_import allows exactly one importer and
  // that is palettes.dart — and it is not a palette value, so it is not on
  // ShedTokens either. A private const in the file that owns the type scale is
  // where 06 §5.5's line height actually belongs.
  const double lineHeight = 1.4; // headroom for WCAG 1.4.12 — 06 §5.5

  // No weightBump parameter exists. Bold Text is the framework's job (06 §5.3).
  //
  // fontWeight, never FontVariation. The wght axis MEASURES 200–800, so
  // indelible.md §3.3's 390 / 420 / 520 / 600 are all reachable — the axis was
  // never the obstacle, and 06 §5.2's "500–700" record was simply wrong. What
  // rules them out is the mechanism they would need: Text.build merges
  // FontWeight.bold for the Bold Text accessibility setting and does NOT touch
  // fontVariations, so a weight set through FontVariation('wght', 390) silently
  // ignores that setting. The bug is invisible on a developer's device and
  // lands on exactly the users who turned the setting on. See the P7 ruling in
  // N09-T05's commit.
  TextStyle s(double size, FontWeight w, {List<FontFeature>? f}) => TextStyle(
    fontFamily: 'AtkinsonNext',
    fontSize: size,
    fontWeight: w,
    color: t.textPrimary,
    height: lineHeight,
    fontFeatures: f,
  );

  final double n = t.numeralSize; // 40, or 44 in a night-shift palette
  final double b = t.bodySize; // 18, or 20 in a night-shift palette

  return TextTheme(
    displayLarge: s(n + 24, FontWeight.w700, f: tabular),
    displayMedium: s(n + 8, FontWeight.w700, f: tabular),
    displaySmall: s(n, FontWeight.w700, f: tabular),
    headlineLarge: s(32, FontWeight.w700, f: tabular),
    headlineMedium: s(28, FontWeight.w600),
    headlineSmall: s(24, FontWeight.w600),
    titleLarge: s(24, FontWeight.w600),
    titleMedium: s(b + 2, FontWeight.w600),
    titleSmall: s(b, FontWeight.w600),
    bodyLarge: s(b + 2, FontWeight.w500),
    bodyMedium: s(b, FontWeight.w500),
    bodySmall: s(b, FontWeight.w500),
    labelLarge: s(b + 2, FontWeight.w700),
    labelMedium: s(b, FontWeight.w600),
    labelSmall: s(b, FontWeight.w600),
  );
}

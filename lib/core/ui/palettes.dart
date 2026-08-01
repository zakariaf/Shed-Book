// lib/core/ui/palettes.dart — the six authored palettes.
//
// THE ONLY FILE IN THE APP THAT IMPORTS primitives.dart. Its `[exempt]` line —
// `lib/core/ui/palettes.dart :: token.primitives_import` — is one of the four
// R56 fixes at four, and the whole access-control story for colour is: one file
// declares hexes, this file composes them into palettes, everything else reads
// `context.tokens`.
//
// Every value here is 06 §4.2–§4.5's, and every ratio in the comments is
// RECOMPUTED by test/design/contrast_test.dart rather than trusted. 06 §3.5: if
// a number in that document and the test disagree, the test is right and the
// document is stale — which is the only reason it is safe to print sixty ratios
// in prose at all.
//
// Which document supplied these values, and why, is P6. The short form:
// decision #95 fixes the base surface at #0B0D0E, indelible.md publishes no
// amber table, no high-contrast variant and (§2.7) no status palette at all, and
// 06 §4 is the only complete six-palette specification in the doc set. The long
// form is in primitives.dart's header and in N09's pull request.
import 'package:flutter/material.dart';

import 'package:shed_book/core/ui/primitives.dart';
import 'package:shed_book/core/ui/tokens.dart';

// ---------------------------------------------------------------------------
// The registry
// ---------------------------------------------------------------------------

/// The user picks a palette in Settings; the contrast level comes from iOS's
/// Increase Contrast **or** the in-app High contrast switch, ORed.
///
/// A `switch` over `(enum, bool)` is exhaustive, so a missing arm is a compile
/// error. [shedPalettes] below is a plain list and is not — which is why the
/// count is asserted there and only there.
ShedPalette resolvePalette(ShedPaletteId id, {required bool highContrast}) =>
    switch ((id, highContrast)) {
      (ShedPaletteId.night, false) => nightPalette,
      (ShedPaletteId.night, true) => nightHcPalette,
      (ShedPaletteId.amber, false) => amberPalette,
      (ShedPaletteId.amber, true) => amberHcPalette,
      (ShedPaletteId.deepRed, false) => deepRedPalette,
      (ShedPaletteId.deepRed, true) => deepRedHcPalette,
    };

/// The same six, as a list, so the contrast suite cannot silently skip one.
const List<ShedPalette> shedPalettes = <ShedPalette>[
  nightPalette,
  nightHcPalette,
  amberPalette,
  amberHcPalette,
  deepRedPalette,
  deepRedHcPalette,
];

// ---------------------------------------------------------------------------
// Shared metrics
// ---------------------------------------------------------------------------

/// The base animation duration. `--motion-ink`, 120 ms: a newly printed glyph
/// fading 0 → 1. T09 lands the rest of the vocabulary and the reduce-motion
/// resolver; this is the one value a palette carries.
const Duration _motion = Duration(milliseconds: 120);

/// Night-shift compensation is bought with **size, never weight** (06 §4.4).
/// Both night-shift palettes take the larger pair, not just deep red, so
/// switching between the honest pair never reflows the screen. Bumping weight
/// instead walks into flutter#139712.
const double _bodyNight = 18.0;
const double _numeralNight = 40.0;
const double _bodyShift = 20.0;
const double _numeralShift = 44.0;

// ---------------------------------------------------------------------------
// night — the default palette (06 §4.2)
// ---------------------------------------------------------------------------

/// Hand-authored. A **seeded** scheme is banned — the gate row is
/// `token.seeded_scheme`, and this comment describes the banned constructor
/// rather than spelling it, because the row scans this file and a quoted
/// prohibition is indistinguishable from the thing prohibited.
///
/// The reason is not taste: Flutter 3.41 changed `onPrimaryContainer`,
/// `onSecondaryContainer`, `onTertiaryContainer` and `onErrorContainer` for
/// every generated scheme, and you cannot ask a seed for ≥ 12:1 on the base
/// surface. Here legibility is a safety property, not a brand property (#94).
///
/// Widgets never read `colorScheme`; **Material's own widgets have no choice**,
/// and that is the entire reason to author one. `AlertDialog`, the text-selection
/// handles and toolbar, `InkSparkle`, the `GlobalMaterialLocalizations` pickers,
/// `Scrollbar` and every `ThemeData` sub-theme fallback read it. If it is not
/// authored it is generated.
///
/// `surfaceTint` equals the base surface, which makes the M3 elevation blend a
/// no-op. Elevation in this app is the explicit surface ramp, and indelible.md
/// has no elevation at all — *"nothing casts a shadow"*.
///
/// `background`, `onBackground` and `surfaceVariant` are never set: they are
/// deprecated on this SDK, and `flutter analyze --fatal-infos` turns an
/// analyzer info into a CI failure. That is the mechanism, not a nicety.
const ColorScheme _nightScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: nInk92,
  onPrimary: nSurface04,
  primaryContainer: nSurface18,
  onPrimaryContainer: nInk92,
  secondary: nInk72,
  onSecondary: nSurface04,
  secondaryContainer: nSurface12,
  onSecondaryContainer: nInk92,
  tertiary: nInk72,
  onTertiary: nSurface04,
  // Material's own destructive role. It is NOT statusLoss: a lamb that died is
  // a recorded fact, not an application error (spec §12.2). Conflating them
  // paints a recorded death in the same pixels as a failed write.
  error: nSalmon80,
  onError: nSurface04,
  errorContainer: nSurface18,
  onErrorContainer: nSalmon80,
  surface: nSurface04,
  onSurface: nInk92,
  surfaceDim: nSurface04,
  surfaceBright: nSurface18,
  surfaceContainerLowest: nSurface04,
  surfaceContainerLow: nSurface08,
  surfaceContainer: nSurface08,
  surfaceContainerHigh: nSurface12,
  surfaceContainerHighest: nSurface18,
  onSurfaceVariant: nInk72,
  outline: nInk40,
  outlineVariant: nInk40,
  inverseSurface: nInk92,
  onInverseSurface: nSurface04,
  inversePrimary: nSurface04,
  shadow: nSurface04,
  scrim: nSurface04,
  surfaceTint: nSurface04,
);

const ShedPalette nightPalette = ShedPalette(
  id: ShedPaletteId.night,
  highContrast: false,
  name: 'night',
  colorScheme: _nightScheme,
  tokens: ShedTokens(
    id: ShedPaletteId.night,
    highContrast: false,
    surfaceBase: nSurface04,
    surfaceRaised: nSurface08,
    surfacePressed: nSurface12,
    surfaceFill: nSurface18,
    outline: nInk40,
    textNumeric: nInk100,
    textPrimary: nInk92,
    textSecondary: nInk72,
    textChrome: nInk40,
    statusReady: nGreen70,
    statusAttention: nAmber70,
    statusLoss: nSalmon80,
    onStatus: nSurface04,
    tapMin: tapMin,
    tapPrimary: tapPrimary,
    tapHero: tapHero,
    gapMin: gapMin,
    gapDestructive: gapDestructive,
    outlineWidth: ruleW,
    radiusControl: radiusSlab,
    bodySize: _bodyNight,
    numeralSize: _numeralNight,
    motion: _motion,
    photoTint: null,
  ),
);

// ---------------------------------------------------------------------------
// night, high contrast (06 §4.5)
// ---------------------------------------------------------------------------
// The same ramp shifted one step brighter, plus a load-bearing outline:
// surfaceRaised == surfaceBase, so cards are separated by BORDER rather than
// tint, because a few percent of luminance disappears under a head torch.

const ColorScheme _nightHcScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: nInk100,
  onPrimary: aSurface00,
  primaryContainer: nSurface12,
  onPrimaryContainer: nInk100,
  secondary: nInk92,
  onSecondary: aSurface00,
  secondaryContainer: nSurface08,
  onSecondaryContainer: nInk100,
  tertiary: nInk92,
  onTertiary: aSurface00,
  error: hSalmon,
  onError: aSurface00,
  errorContainer: nSurface12,
  onErrorContainer: hSalmon,
  surface: aSurface00,
  onSurface: nInk100,
  surfaceDim: aSurface00,
  surfaceBright: nSurface12,
  surfaceContainerLowest: aSurface00,
  surfaceContainerLow: aSurface00,
  surfaceContainer: nSurface08,
  surfaceContainerHigh: nSurface08,
  surfaceContainerHighest: nSurface12,
  onSurfaceVariant: nInk92,
  outline: hOutline,
  outlineVariant: hOutline,
  inverseSurface: nInk100,
  onInverseSurface: aSurface00,
  inversePrimary: aSurface00,
  shadow: aSurface00,
  scrim: aSurface00,
  surfaceTint: aSurface00,
);

const ShedPalette nightHcPalette = ShedPalette(
  id: ShedPaletteId.night,
  highContrast: true,
  name: 'night-hc',
  colorScheme: _nightHcScheme,
  tokens: ShedTokens(
    id: ShedPaletteId.night,
    highContrast: true,
    surfaceBase: aSurface00,
    surfaceRaised: aSurface00,
    surfacePressed: nSurface08,
    surfaceFill: nSurface12,
    outline: hOutline,
    textNumeric: nInk100,
    textPrimary: nInk100,
    textSecondary: nInk92,
    textChrome: nInk72,
    statusReady: hGreen,
    statusAttention: hAmber,
    statusLoss: hSalmon,
    onStatus: aSurface00,
    tapMin: tapMin,
    tapPrimary: tapPrimary,
    tapHero: tapHero,
    gapMin: gapMin,
    gapDestructive: gapDestructive,
    outlineWidth: ruleW,
    radiusControl: radiusSlab,
    bodySize: _bodyNight,
    numeralSize: _numeralNight,
    motion: _motion,
    photoTint: null,
  ),
);

// ---------------------------------------------------------------------------
// amber — the recommended night-shift palette (06 §4.3)
// ---------------------------------------------------------------------------
// Base is pure black: minimising TOTAL EMISSION is the point, and there is no
// complex content to separate by tint — separation comes from the outline.
//
// 06 §4.3 publishes THREE surface steps (#000000, #140D00, #1F1400) where
// ShedTokens has four, so surfaceFill reuses surfaceRaised's brighter
// neighbour. Recorded rather than invented: a fourth night-shift surface is a
// value for 06 §4.3 to publish, not for this file to make up.

const ColorScheme _amberScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: aAmber70,
  onPrimary: aSurface00,
  primaryContainer: aSurface08,
  onPrimaryContainer: aAmber70,
  secondary: aAmber55,
  onSecondary: aSurface00,
  secondaryContainer: aSurface04,
  onSecondaryContainer: aAmber70,
  tertiary: aAmber55,
  onTertiary: aSurface00,
  error: aAmber95,
  onError: aSurface00,
  errorContainer: aSurface08,
  onErrorContainer: aAmber95,
  surface: aSurface00,
  onSurface: aAmber70,
  surfaceDim: aSurface00,
  surfaceBright: aSurface08,
  surfaceContainerLowest: aSurface00,
  surfaceContainerLow: aSurface04,
  surfaceContainer: aSurface04,
  surfaceContainerHigh: aSurface08,
  surfaceContainerHighest: aSurface08,
  onSurfaceVariant: aAmber55,
  outline: aAmber30,
  outlineVariant: aAmber30,
  inverseSurface: aAmber70,
  onInverseSurface: aSurface00,
  inversePrimary: aSurface00,
  shadow: aSurface00,
  scrim: aSurface00,
  surfaceTint: aSurface00,
);

/// **In a one-hue palette, urgency is luminance.** Loss is the brightest token,
/// then attention, then ready. The colour channel is nearly gone; the luminance
/// channel is what is left, and it is spent on the thing that needs a shepherd's
/// attention. Shape and text carry the rest — the ordering is not a licence to
/// use colour alone (decision #106).
const ShedPalette amberPalette = ShedPalette(
  id: ShedPaletteId.amber,
  highContrast: false,
  name: 'amber',
  colorScheme: _amberScheme,
  tokens: ShedTokens(
    id: ShedPaletteId.amber,
    highContrast: false,
    surfaceBase: aSurface00,
    surfaceRaised: aSurface04,
    surfacePressed: aSurface08,
    surfaceFill: aSurface08,
    outline: aAmber30,
    textNumeric: aAmber85,
    textPrimary: aAmber70,
    textSecondary: aAmber55,
    textChrome: aAmber45,
    statusReady: aAmber45,
    statusAttention: aAmber70,
    statusLoss: aAmber95,
    onStatus: aSurface00,
    tapMin: tapMin,
    tapPrimary: tapPrimary,
    tapHero: tapHero,
    gapMin: gapMin,
    gapDestructive: gapDestructive,
    outlineWidth: ruleW,
    radiusControl: radiusSlab,
    bodySize: _bodyShift,
    numeralSize: _numeralShift,
    motion: _motion,
    photoTint: null,
  ),
);

// ---------------------------------------------------------------------------
// amber, high contrast (06 §4.5)
// ---------------------------------------------------------------------------

const ColorScheme _amberHcScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: aAmber85,
  onPrimary: aSurface00,
  primaryContainer: aSurface08,
  onPrimaryContainer: aAmber85,
  secondary: aAmber70,
  onSecondary: aSurface00,
  secondaryContainer: aSurface04,
  onSecondaryContainer: aAmber85,
  tertiary: aAmber70,
  onTertiary: aSurface00,
  error: aAmber95,
  onError: aSurface00,
  errorContainer: aSurface08,
  onErrorContainer: aAmber95,
  surface: aSurface00,
  onSurface: aAmber85,
  surfaceDim: aSurface00,
  surfaceBright: aSurface08,
  surfaceContainerLowest: aSurface00,
  surfaceContainerLow: aSurface00,
  surfaceContainer: aSurface04,
  surfaceContainerHigh: aSurface04,
  surfaceContainerHighest: aSurface08,
  onSurfaceVariant: aAmber70,
  outline: aAmber30,
  outlineVariant: aAmber30,
  inverseSurface: aAmber85,
  onInverseSurface: aSurface00,
  inversePrimary: aSurface00,
  shadow: aSurface00,
  scrim: aSurface00,
  surfaceTint: aSurface00,
);

const ShedPalette amberHcPalette = ShedPalette(
  id: ShedPaletteId.amber,
  highContrast: true,
  name: 'amber-hc',
  colorScheme: _amberHcScheme,
  tokens: ShedTokens(
    id: ShedPaletteId.amber,
    highContrast: true,
    surfaceBase: aSurface00,
    surfaceRaised: aSurface00,
    surfacePressed: aSurface04,
    surfaceFill: aSurface08,
    outline: aAmber30,
    textNumeric: aAmber95,
    textPrimary: aAmber85,
    textSecondary: aAmber70,
    textChrome: aAmber55,
    statusReady: aAmber70,
    statusAttention: aAmber85,
    statusLoss: aAmber95,
    onStatus: aSurface00,
    tapMin: tapMin,
    tapPrimary: tapPrimary,
    tapHero: tapHero,
    gapMin: gapMin,
    gapDestructive: gapDestructive,
    outlineWidth: ruleW,
    radiusControl: radiusSlab,
    bodySize: _bodyShift,
    numeralSize: _numeralShift,
    motion: _motion,
    photoTint: null,
  ),
);

// ---------------------------------------------------------------------------
// deepRed — shipped, and honestly labelled (06 §4.4)
// ---------------------------------------------------------------------------
// THE HONEST LIMITATION, stated here and in the app. A spectrally clean
// long-wavelength palette has a hard contrast ceiling: pure #FF0000 on black is
// only 5.25:1, and pushing toward orange buys contrast at the cost of green
// energy that bleaches rhodopsin faster. No red palette reaches AAA for body
// text and stays spectrally clean.
//
// So textSecondary and textChrome are DELIBERATELY the same value — nothing
// dimmer clears AA, and inventing a fourth ink step here would mean shipping
// unreadable text. The contrast test asserts AA (4.5:1) for this palette and
// only this palette. The suite is not relaxed globally to hide it.
//
// There is no rSurface00: both night-shift palettes are based on pure black and
// one value gets one name, so the base is aSurface00.

const ColorScheme _deepRedScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: rRed50,
  onPrimary: aSurface00,
  primaryContainer: rSurface08,
  onPrimaryContainer: rRed50,
  secondary: rRed40,
  onSecondary: aSurface00,
  secondaryContainer: rSurface04,
  onSecondaryContainer: rRed50,
  tertiary: rRed40,
  onTertiary: aSurface00,
  error: rRed75,
  onError: aSurface00,
  errorContainer: rSurface08,
  onErrorContainer: rRed75,
  surface: aSurface00,
  onSurface: rRed50,
  surfaceDim: aSurface00,
  surfaceBright: rSurface08,
  surfaceContainerLowest: aSurface00,
  surfaceContainerLow: rSurface04,
  surfaceContainer: rSurface04,
  surfaceContainerHigh: rSurface08,
  surfaceContainerHighest: rSurface08,
  onSurfaceVariant: rRed40,
  outline: rRed30,
  outlineVariant: rRed30,
  inverseSurface: rRed50,
  onInverseSurface: aSurface00,
  inversePrimary: aSurface00,
  shadow: aSurface00,
  scrim: aSurface00,
  surfaceTint: aSurface00,
);

const ShedPalette deepRedPalette = ShedPalette(
  id: ShedPaletteId.deepRed,
  highContrast: false,
  name: 'red',
  colorScheme: _deepRedScheme,
  tokens: ShedTokens(
    id: ShedPaletteId.deepRed,
    highContrast: false,
    surfaceBase: aSurface00,
    surfaceRaised: rSurface04,
    surfacePressed: rSurface08,
    surfaceFill: rSurface08,
    outline: rRed30,
    textNumeric: rRed60,
    textPrimary: rRed50,
    textSecondary: rRed40,
    textChrome: rRed40,
    statusReady: rRed50,
    statusAttention: rRed60,
    statusLoss: rRed75,
    onStatus: aSurface00,
    tapMin: tapMin,
    tapPrimary: tapPrimary,
    tapHero: tapHero,
    gapMin: gapMin,
    gapDestructive: gapDestructive,
    outlineWidth: ruleW,
    radiusControl: radiusSlab,
    bodySize: _bodyShift,
    numeralSize: _numeralShift,
    motion: _motion,
    photoTint: null,
  ),
);

// ---------------------------------------------------------------------------
// deepRed, high contrast (06 §4.5)
// ---------------------------------------------------------------------------
// Note the trade this variant makes: it reaches AAA for body (7.45:1) by
// EMITTING MORE LIGHT, which is exactly what a night-vision palette is trying to
// avoid. Say so in the Settings row; do not silently resolve it for the user.

const ColorScheme _deepRedHcScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: rRed60,
  onPrimary: aSurface00,
  primaryContainer: rSurface08,
  onPrimaryContainer: rRed60,
  secondary: rRed50,
  onSecondary: aSurface00,
  secondaryContainer: rSurface04,
  onSecondaryContainer: rRed60,
  tertiary: rRed50,
  onTertiary: aSurface00,
  error: rRed75,
  onError: aSurface00,
  errorContainer: rSurface08,
  onErrorContainer: rRed75,
  surface: aSurface00,
  onSurface: rRed60,
  surfaceDim: aSurface00,
  surfaceBright: rSurface08,
  surfaceContainerLowest: aSurface00,
  surfaceContainerLow: aSurface00,
  surfaceContainer: rSurface04,
  surfaceContainerHigh: rSurface04,
  surfaceContainerHighest: rSurface08,
  onSurfaceVariant: rRed50,
  outline: rRed30,
  outlineVariant: rRed30,
  inverseSurface: rRed60,
  onInverseSurface: aSurface00,
  inversePrimary: aSurface00,
  shadow: aSurface00,
  scrim: aSurface00,
  surfaceTint: aSurface00,
);

const ShedPalette deepRedHcPalette = ShedPalette(
  id: ShedPaletteId.deepRed,
  highContrast: true,
  name: 'red-hc',
  colorScheme: _deepRedHcScheme,
  tokens: ShedTokens(
    id: ShedPaletteId.deepRed,
    highContrast: true,
    surfaceBase: aSurface00,
    surfaceRaised: aSurface00,
    surfacePressed: rSurface04,
    surfaceFill: rSurface08,
    outline: rRed30,
    textNumeric: rRed75,
    textPrimary: rRed60,
    textSecondary: rRed50,
    textChrome: rRed50,
    statusReady: rRed50,
    statusAttention: rRed60,
    statusLoss: rRed75,
    onStatus: aSurface00,
    tapMin: tapMin,
    tapPrimary: tapPrimary,
    tapHero: tapHero,
    gapMin: gapMin,
    gapDestructive: gapDestructive,
    outlineWidth: ruleW,
    radiusControl: radiusSlab,
    bodySize: _bodyShift,
    numeralSize: _numeralShift,
    motion: _motion,
    photoTint: null,
  ),
);

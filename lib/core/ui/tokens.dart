// lib/core/ui/tokens.dart — tier 2.
//
// This file holds no value at all. T01 authored values with no meaning; this
// tier gives each one its job, and it is the last point at which the mapping is
// cheap to change — everything from N10 onward reads these field names.
//
// It must not import primitives.dart. If a hex seems to be wanted here, the
// field being added belongs in T03's palette literals instead.
import 'package:flutter/material.dart';

/// The member and the stored key are the same string, so `app_settings.palette`
/// can be read off the enum and back (CONVENTIONS R35). The frozen schema's
/// CHECK is `IN ('night','amber','red')`; `deepRed`'s key is `'red'` and it is
/// the one member whose key is not its name.
enum ShedPaletteId {
  night('night'),
  amber('amber'),
  deepRed('red');

  const ShedPaletteId(this.key);

  final String key;
}

/// One authored palette: an M3 scheme for the framework's own widgets (§2.3) and
/// the token set every Shed Book widget actually reads. Six exist.
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

  /// `'night'`, `'night-hc'`, `'amber'`, … — the test group names.
  final String name;
  final ColorScheme colorScheme;
  final ShedTokens tokens;
}

/// The token set every widget reads, as ONE flat extension rather than five
/// nested ones: `Theme.of(context).extension<T>()` is a map lookup per call, and
/// a flat object is trivially diffable, lerpable and testable.
///
/// ## The Indelible → `ShedTokens` mapping
///
/// It is not one-to-one, and the places it is not are where the decisions are.
/// test/design/tokens_test.dart parses this table, so it cannot rot.
///
/// | Indelible | field | note |
/// |---|---|---|
/// | `--page` | `surfaceBase` | the first painted frame |
/// | `--row-pressed` | `surfacePressed` | a row under the thumb, 40 ms |
/// | `--sheet` | `surfaceRaised` | the bottom sheet, the only overlay in the app |
/// | `--slab` | `surfaceFill` | button fills — the only filled shapes |
/// | `--slab-pressed` | `none` | **NOT REPRESENTED, and that is the honest answer rather than an oversight.** 06 §4's ramp has four surface steps and publishes no fifth hex. This field briefly existed, on the reading that indelible.md supplied the values; decision #95 overturned that reading (see primitives.dart's header, and P6 in the PR body), and a field with no authored value would have forced a hex to be invented here — which is exactly what two tiers exist to prevent. If a component in N10 genuinely needs a pressed slab distinct from a pressed row, the fix is a value in 06 §4, not a literal in a widget |
/// | `--rule` | `outline` | **non-text only**, 3.52:1 |
/// | `--ink-full` | `textPrimary` | |
/// | `--ink-full` | `textNumeric` | the same ink. Indelible has no separate numeral colour — the tabular figure comes from the ROLE, not from a hue — and the field exists so a palette could shift it without touching a `TextStyle` |
/// | `--ink-mid` | `textSecondary` | |
/// | `--ink-low` | `textChrome` | |
/// | `--madder-rule` | `statusAttention` | non-text only, and never the only channel |
/// | `--madder-ink` | `statusLoss` | see the warning below |
///
/// `textChrome` carries struck text, and 06 §4.2 defines chrome as *"never a
/// value the shepherd must read"* — which struck text plainly is, forever. The
/// mapping is kept because indelible.md §7.3 gives struck text `--ink-low` and
/// the ink is what matters; the NAME is 06's and is the weaker half of the two
/// documents here. Flagged rather than renamed, because a rename is twenty-one
/// components.
///
/// ## The status fields are not a licence
///
/// indelible.md §2.7 is explicit that there is no status palette: a lamb that
/// died prints the word `DEAD`, in full ink, with *"colour: none, ever"*. These
/// four fields exist because 06 §12's `ShedStatusBadge` and contrast_test.dart's
/// `contrastRatio(onStatus, statusX)` both need something to name — **the field
/// existing does not license a component to use colour as the only channel.**
/// Colour + shape + text + position, always (06 §11, decision #106, WCAG 1.4.1
/// Level A). `statusLoss` is the trap: when in doubt it is full ink and the word
/// carries the meaning.
///
/// ## No `TextStyle`, ever
///
/// `bodySize` and `numeralSize` are `double`s. `buildShedTextTheme` turns them
/// into roles. A `TextStyle` here would be a second place a font size could come
/// from, and `token.literal_font_size` exists precisely because there must be
/// one.
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

  /// Non-null only in the night-shift palettes. Applied by `ShedPhoto` and by
  /// nothing else (06 §4.7). indelible.md §2.6 rejects a filter as the MECHANISM
  /// for red shift — peak luminance is halved through the platform brightness
  /// API, because a filter would also dim the press feedback and would be a lie
  /// about what the display is doing. A global `ColorFiltered` over the app is
  /// banned outright.
  final ColorFilter? photoTint;

  /// Only `motion` and `highContrast` are ever overridden at runtime, so the
  /// signature is narrow on purpose: a wide `copyWith` invites a widget to build
  /// a one-off token set, which is exactly what the two tiers exist to stop. The
  /// narrowness is the feature, and a source-text test holds it.
  @override
  ShedTokens copyWith({Duration? motion, bool? highContrast}) => ShedTokens(
    id: id,
    highContrast: highContrast ?? this.highContrast,
    motion: motion ?? this.motion,
    surfaceBase: surfaceBase,
    surfaceRaised: surfaceRaised,
    surfacePressed: surfacePressed,
    surfaceFill: surfaceFill,
    outline: outline,
    textNumeric: textNumeric,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textChrome: textChrome,
    statusReady: statusReady,
    statusAttention: statusAttention,
    statusLoss: statusLoss,
    onStatus: onStatus,
    tapMin: tapMin,
    tapPrimary: tapPrimary,
    tapHero: tapHero,
    gapMin: gapMin,
    gapDestructive: gapDestructive,
    outlineWidth: outlineWidth,
    radiusControl: radiusControl,
    bodySize: bodySize,
    numeralSize: numeralSize,
    photoTint: photoTint,
  );

  /// **This snaps every field, including the colours** — one operand or the
  /// other, never a third value.
  ///
  /// That is a deliberate narrowing of 06 §3.3, which interpolated the `Color`
  /// fields with `Color.lerp` and snapped only the rest. 06 §3.3 was amended in
  /// the same commit that wrote this. The argument is Indelible rule 4 applied
  /// one level harder: **a colour produced by interpolation is a colour nobody
  /// measured for contrast**, and the whole point of two tiers is that every
  /// colour on screen is one somebody did. 00-README §2.3 prefers
  /// *unrepresentable* over *documented*, and this makes the unmeasured colour
  /// unrepresentable.
  ///
  /// The cost is zero. 06 §2.1 and §4.8 already pin
  /// `themeAnimationDuration: Duration.zero` — *"a 200 ms lerp between night and
  /// deep red drags every colour through a desaturated, low-contrast midpoint"* —
  /// so no intermediate `t` is ever produced in the running app. This removes
  /// the possibility rather than relying on that setting staying put.
  ///
  /// The 06 §3.3 sentence that survives unchanged is the metric one: a tap
  /// target that is 63.4 pt for 150 ms breaks the 60 pt contract for 150 ms.
  ///
  /// `covariant` is not optional. The framework signature is
  /// `ThemeExtension<T> lerp(covariant ThemeExtension<T>? other, double t)`, and
  /// writing it without the keyword is an invalid override whose error message
  /// points at the parameter type rather than at the missing word.
  @override
  ShedTokens lerp(covariant ShedTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

/// The ONLY way a widget gets a colour or a size.
///
/// The `!` is intentional. A `MaterialApp` built without the extension must fail
/// loudly on the first build rather than paint a fallback colour nobody
/// measured.
///
/// The consequence lands on tests: every widget test in this project pumps
/// through `pumpApp` (N12-T05), which installs the extension. A bare
/// `tester.pumpWidget(MaterialApp(home: …))` throws a null check on a widget
/// deep in the tree, and **the message does not mention tokens** — so if a test
/// fails that way, this is why.
extension ShedTokensX on BuildContext {
  ShedTokens get tokens => Theme.of(this).extension<ShedTokens>()!;
}

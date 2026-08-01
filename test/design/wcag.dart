// test/design/wcag.dart — WCAG 2.x relative luminance and contrast ratio.
//
// Not a `_test.dart` file, so the runner does not execute it directly.
//
// Twelve lines of arithmetic rather than a package, and that is a decision
// rather than an omission: a colour package would have to clear the G2
// dependency allowlist and the offline contract to do what `dart:ui` already
// does. See 06 §3.5.
import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:shed_book/core/ui/tokens.dart';

/// `dart:ui`'s `Color.computeLuminance()` **is** the WCAG 2.0 relative-luminance
/// formula — 0.2126R + 0.7152G + 0.0722B over linearised sRGB components, citing
/// the W3C definition in its own source. Re-deriving `pow(c, 2.4)` by hand buys
/// nothing and is one typo away from a palette that passes a wrong test.
double relativeLuminance(Color c) => c.computeLuminance();

double contrastRatio(Color a, Color b) {
  final double la = relativeLuminance(a), lb = relativeLuminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The brightest ink a palette normally puts on screen — the quantity 06 §4.3's
/// *"red-shift drops luminance as well as hue"* rule is about.
///
/// **Amended 2026-08-01 (N09-T03): body text only.** 06 §3.5 printed this over
/// `textNumeric`, `textPrimary` **and the three status tokens**, and that
/// version cannot pass against 06 §4.3's own table — `amber`'s `statusLoss` is
/// `#FFE0A3` at L 0.772, and the ceiling is 0.70 × night's peak of 1.000.
///
/// The collision is between two rules in the same document, and §4.3 resolves it
/// against itself. Its rule 1 says **"in a one-hue palette, urgency is
/// luminance"** — loss is *deliberately* the brightest token, because the colour
/// channel is nearly gone and the luminance channel is what is left to spend on
/// the thing that needs a shepherd's attention. Then its own arithmetic two
/// paragraphs later computes the drop as *"1.000 → 0.618"*, and 0.618 is amber's
/// `textNumeric`, not its `statusLoss` at 0.772. So §4.3 was already measuring
/// body text; §3.5's list was the stale half.
///
/// Relaxing the 0.70 factor would have been the other way out, and it is the
/// edit-the-gate-to-make-it-green anti-pattern 13 names by name. The factor is
/// untouched.
///
/// The exception is bounded rather than waived: `peakStatusLuminance` below is
/// asserted separately, so a status token cannot become arbitrarily bright.
double peakLuminance(ShedPalette p) =>
    <Color>[p.tokens.textNumeric, p.tokens.textPrimary].map(relativeLuminance).reduce(math.max);

/// The brightest status mark. Separated from [peakLuminance] so that §4.3's
/// deliberate exception stays visible and stays bounded.
double peakStatusLuminance(ShedPalette p) => <Color>[
  p.tokens.statusReady,
  p.tokens.statusAttention,
  p.tokens.statusLoss,
].map(relativeLuminance).reduce(math.max);

/// The native launch colour, 06 §9.
///
/// **Duplicated deliberately.** If someone edits `nSurface04` without editing
/// `android/app/src/main/res/values/colors.xml`, this constant is what makes the
/// test fail. A test that imported the value it is checking would agree with
/// itself forever.
///
/// **P14 was ruled at N11-T04 in favour of `#0A0A0B`**, and this constant moved
/// with it. The assertion stays written as *"no palette's `surfaceBase` is
/// brighter than the native launch colour"* rather than as an equality, so it
/// keeps meaning something if the two ever diverge again.
const Color launchSurface = Color(0xFF0A0A0B);

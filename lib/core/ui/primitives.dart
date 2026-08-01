// lib/core/ui/primitives.dart — tier 1.
//
// Raw values only. Nothing outside lib/core/ui/ imports this file, and the gate
// row `token.primitives_import` is what holds that — Dart has no
// directory-private visibility, so the language cannot.
//
// ---------------------------------------------------------------------------
// WHICH DOCUMENT SUPPLIED THESE VALUES — P6, AND WHY IT LANDED THIS WAY
// ---------------------------------------------------------------------------
//
// The COLOUR ramps are 06 §3.2's, backed by decision #95. The SCALES below them
// are indelible.md's. That split is not a compromise; it is the authority order
// in CLAUDE.md applied to a conflict bigger than the epic described.
//
// N09-T01's own source table says indelible.md §2.2/§2.3 binds every hex, and
// this file was first authored that way — a warm ink-on-paper ramp based on
// `#0A0A0B` with madder marks. That was wrong, and the thing that settles it is
// rank 1 of the authority order rather than a preference:
//
//   decision #95 — "Base surface #0B0D0E." It is a CEILING rather than an
//   exact value (see nSurface04 below and 06 §1); its rejected column names
//   `#121212` AND `#000000` as the base. It is not struck, so it stands, and
//   nothing below the decision record can overturn it by publishing a different
//   table.
//
// Two further facts made the split the only workable reading:
//
//   1. indelible.md CANNOT supply six palettes. It publishes two themes, no
//      amber table, no high-contrast variant, and §2.7 explicitly refuses a
//      status palette at all — while ShedTokens needs statusReady,
//      statusAttention, statusLoss and onStatus in all six. 06 §4.2–§4.5 is the
//      only complete, per-token, fully measured six-palette specification in the
//      doc set.
//   2. Every ratio N09-T03's test set asks to reproduce — 16.16, 10.29, 6.11,
//      13.36, 11.46, 7.45, 6.08, 21.00, 4.89 — is a 06 §4 figure. The epic's own
//      verification is written against this ramp.
//
// P6 AND P14 ARE THEREFORE CARRIED INTO THE PR BODY AS OPEN, WITH BOTH SIDES
// CITED, and indelible.md is NOT struck here. Striking the colour half of the
// document CLAUDE.md calls "the one design system" is an owner's ruling, not a
// task's — and §2.4's overruled values and §7.3's placement rules are written
// against its own ramp, so they would be orphaned by a silent edit. What
// indelible.md keeps binding, and does bind below: the twelve-step spacing
// scale, the geometry, the 64 pt target floor, the two-voice type scale, motion
// and haptics.
//
// P14 IS NOW CLOSED — see nSurface04 below for the ruling. The short form: 06 §1
// leaves the base surface hex FREE below a ceiling, and indelible.md's value is
// darker than that ceiling, so it ships. 06 §9.4's `launch.colour_parity` parses
// `nSurface04` out of this file to compare with
// android/app/src/main/res/values/colors.xml.
//
// ---------------------------------------------------------------------------
//
// THE NAMING SCHEME IS VALUE-NAMED, NOT MEANING-NAMED (06 §3.2): a palette
// letter, a hue-or-role word, and the approximate luminance step. Never `nPage`,
// `nInkStruck`, `nSpine` — what a value is FOR is tokens.dart's decision, one
// tier up, and a primitive that already knows it is the strike colour has
// pre-empted it.
//
// Every hex carries its measured ratio on the surface it is designed for.
// test/design/contrast_test.dart recomputes all of them from these constants.
import 'dart:ui' show Color;

// ---- night neutral ramp (06 §4.2) ------------------------------------------
// The ramp is a HINT, NOT A SEPARATOR: 1.07:1 and 1.18:1 between steps are far
// below the 3:1 WCAG asks of a non-text boundary, deliberately — a bright card
// edge is a light source you stare at for four hours. Any boundary that must be
// findable under a head torch carries an outline AS WELL AS a ramp step. A
// direction may widen the ramp; it may not drop the outline.

/// Decision #95's base surface. Not `#000000` — a base of exactly zero has
/// nothing to build a surface ramp on, so elevation would have to be carried by
/// outlines everywhere. Not `#121212` — in a dark shed the extra emission buys
/// nothing.
///
/// **P14 IS CLOSED (N11-T04) AND indelible.md's `#0A0A0B` WON.** 06 §1's own
/// fixed-versus-free table puts *"the base surface hex, provided it is no
/// brighter than `#0B0D0E`"* in the FREE column, and 06 §9 calls `#0B0D0E`
/// *"the brightest base any palette may have"* — so it is a CEILING, not an
/// exact value. `#0A0A0B` measures L 0.00306 against `#0B0D0E`'s 0.00391, so it
/// is inside the ceiling 06 itself set. Applying 06's rule, not overruling it.
///
/// This is the FIRST PAINTED FRAME, and `launch.colour_parity` parses this exact
/// constant out of this exact file.
const Color nSurface04 = Color(0xFF0A0A0B); // L = 0.00306 — P14, ruled at N11-T04
const Color nSurface08 = Color(0xFF12161A); // 1.07:1 vs base
const Color nSurface12 = Color(0xFF1A2025); // 1.18:1 vs base
const Color nSurface18 = Color(0xFF242B31); // 1.36:1 vs base

const Color nInk40 = Color(0xFF8A9199); //  6.11:1 on nSurface04 — chrome only
const Color nInk72 = Color(0xFFB7BDC4); // 10.29:1
const Color nInk92 = Color(0xFFE8EAED); // 16.16:1

/// 19.48:1, and indelible.md §2.2 objects to it: white-on-black is the worst
/// halation case and roughly 47% of adults have some astigmatism. 06 §4.2
/// nevertheless assigns it to `textNumeric`, and decision #95 backs 06's ramp,
/// so it is authored — but it is the one value in this file where the two
/// documents disagree about a JOB rather than a hex, and it belongs in the P6
/// discussion rather than being quietly softened here.
const Color nInk100 = Color(0xFFFFFFFF);

// ---- night accents (06 §4.2) -----------------------------------------------
// indelible.md §2.7 refuses a status palette outright — a lamb that died prints
// the word DEAD in full ink, with "colour: none, ever". These three exist
// because ShedTokens has the fields and ShedStatusBadge needs something to name.
// Their existence is not a licence: colour is never the only channel (#106).

const Color nGreen70 = Color(0xFF7DD3A0); // 10.85:1
const Color nAmber70 = Color(0xFFFFD54F); // 13.80:1
const Color nSalmon80 = Color(0xFFFFB4AB); // 11.47:1

// ---- amber night-shift ramp (06 §4.3) --------------------------------------
// Base is pure black: in a night-shift palette, minimising TOTAL EMISSION is the
// point and there is no complex content to separate by tint. Separation comes
// from the outline instead. In a one-hue palette URGENCY IS LUMINANCE — loss is
// the brightest token, then attention, then ready.

const Color aSurface00 = Color(0xFF000000);
const Color aSurface04 = Color(0xFF140D00); // 1.09:1 vs base
const Color aSurface08 = Color(0xFF1F1400); // 1.16:1 vs base

const Color aAmber95 = Color(0xFFFFE0A3); // 16.44:1
const Color aAmber85 = Color(0xFFFFC46B); // 13.36:1
const Color aAmber70 = Color(0xFFFFB000); // 11.46:1
const Color aAmber55 = Color(0xFFD68F00); //  7.79:1
const Color aAmber45 = Color(0xFFC98400); //  6.78:1
const Color aAmber30 = Color(0xFFA66E00); //  4.85:1 — outline / non-text only

// ---- deep-red night-shift ramp (06 §4.4) -----------------------------------
// There is deliberately no `rSurface00`: both night-shift palettes are based on
// pure black, and one value gets one name. deepRed's base IS aSurface00, and
// the comment is the whole mechanism — a second constant holding #000000 would
// give the palette an invisible alias that survives every rename.
//
// The honest limitation, and it is stated in the app as well as here: a
// spectrally clean long-wavelength palette has a hard contrast ceiling. Pure
// #FF0000 on black is only 5.25:1, and pushing toward orange buys contrast at
// the cost of green energy that bleaches rhodopsin faster. No red palette
// reaches AAA for body text and stays spectrally clean.

const Color rSurface04 = Color(0xFF1A0503); // 1.07:1 vs black
const Color rSurface08 = Color(0xFF2A0806); // 1.14:1 vs black

const Color rRed75 = Color(0xFFFF9E80); // 10.45:1
const Color rRed60 = Color(0xFFFF6B4A); //  7.45:1
const Color rRed50 = Color(0xFFFF4400); //  6.08:1

/// 4.59:1. `textSecondary` AND `textChrome` are deliberately this same value —
/// nothing dimmer clears AA, and inventing a fourth ink step here would mean
/// shipping unreadable text (06 §4.4).
const Color rRed40 = Color(0xFFE62200);

/// 3.80:1 — outline ONLY. It never carries a glyph.
const Color rRed30 = Color(0xFFCC2200);

// ---- high-contrast additions (06 §4.5) -------------------------------------
// Each HC variant is the same ramp shifted one step brighter, plus a
// load-bearing outline: surfaceRaised == surfaceBase, so cards are separated by
// border rather than tint, because a few percent of luminance disappears under a
// head torch.

const Color hOutline = Color(0xFF7A7A7A); //  4.89:1 on black
const Color hGreen = Color(0xFFA8F0C6); // 15.94:1
const Color hAmber = Color(0xFFFFE08A); // 16.28:1
const Color hSalmon = Color(0xFFFFC7BD); // 14.16:1

// ---- spacing scale (logical pixels) — indelible.md §4.1 --------------------
// TWELVE steps, four-based, no half-steps. 06 §3.2 prints six of them; the other
// six are here rather than typed into a widget in N10, because 06 §1 is explicit
// that a direction needing a token this system does not have adds the token — it
// does not add a literal to a widget. The same applies one tier down.

const double s04 = 4.0;
const double s08 = 8.0;
const double s12 = 12.0;
const double s16 = 16.0;
const double s20 = 20.0;
const double s24 = 24.0;
const double s32 = 32.0;
const double s40 = 40.0;
const double s48 = 48.0;
const double s64 = 64.0;
const double s88 = 88.0;
const double s132 = 132.0;

// ---- tap scale (logical pixels) ---------------------------------------------

/// 06 §6.1's spec floor — Parhi/Karlson/Bederson's 9.5 mm, measured for a bare
/// warm dry thumb in a lab. This is the number the GATE asserts, because it is
/// the contract.
const double tapMin = 60.0; // ≈  9.5 mm

/// indelible.md §4.5's minimum-target audit puts the smallest thing in the whole
/// app at 64 × 64. This is the number COMPONENTS build to, because it is the
/// design. Four points is the entire margin, and collapsing the two into one
/// number loses information nobody can recover afterwards.
const double tapIndelible = 64.0;

const double tapPrimary = 72.0; // keypad, tiles     ≈ 11.4 mm
const double tapHero = 88.0; // the five 3am acts ≈ 14.0 mm
const double gapMin = 16.0;
const double gapDestructive = 32.0;

// ---- geometry (logical pixels) — indelible.md §4.2 -------------------------
// Radii are 0 everywhere but the slab, and the slab's 2 is what makes it read as
// a printed block rather than a card. Nothing casts a shadow: there is no
// elevation in this app, which is why 06 §2.3 pins surfaceTint to the base
// surface and makes the M3 elevation blend a no-op.

const double ruleW = 2.0;
const double ruleStrikeW = 3.0;
const double ruleDoubleGap = 3.0;
const double radiusSlab = 2.0;
const double radiusRecord = 0.0;
const double radiusSheet = 0.0;

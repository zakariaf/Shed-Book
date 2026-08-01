// lib/core/ui/primitives.dart — tier 1.
//
// Raw values only. Nothing outside lib/core/ui/ imports this file, and the gate
// row `token.primitives_import` is what holds that — Dart has no
// directory-private visibility, so the language cannot.
//
// Every hex carries its measured WCAG ratio on the surface it is designed for.
// The ratios were RECOMPUTED from the hexes on 2026-08-01, not copied: all six
// night figures, all six amber figures and the four high-contrast figures
// reproduce indelible.md §2.3 and 06 §3.2 exactly. test/design/contrast_test.dart
// recomputes all of them again, from these constants, on every run.
//
// THE NAMING SCHEME IS VALUE-NAMED, NOT MEANING-NAMED (06 §3.2): a palette
// letter, a hue-or-role word, and the approximate luminance step. `nSurface04`,
// `nInk92`, `aAmber70`. Never `nPage`, `nInkStruck`, `nMadderStrike`, `nSpine` —
// what a value is FOR is tokens.dart's decision, one tier up, and a primitive
// that already knows it is the strike colour has pre-empted it. The step is CIE
// L*, measured: #EDE8DC is L* 92.1, hence nInk92.
//
// Two placement rules travel with these values and are the first thing a
// component author gets wrong:
//
//   1. nInk58 and nInk44 are NEVER drawn on nSurface17. They measure 4.16 and
//      2.54 there. A slab under the thumb carries nInk92 only, and its border
//      goes to nInk67.
//   2. nMadder46 is NEVER set as text and NEVER carries a glyph. It is a 2 px
//      line and nothing else.
//
// Do not restore either value measurement overruled (indelible.md §2.4). Both
// look better. Rule 4 does not negotiate with taste.
import 'dart:ui' show Color;

// ---- night ramp (base nSurface04) -----------------------------------------
// indelible.md §2.2 (five surfaces) and §2.3 (three inks, one hue).

/// P14 IS OPEN AND THIS IS THE LINE. indelible.md §2.2 and §10 publish
/// `#0A0A0B`; 06 §3.2, CONVENTIONS §2.11 and 13 §5.4 publish `#0B0D0E`. One hex,
/// and it is the FIRST PAINTED FRAME — 06 §9.4's `launch.colour_parity` parses
/// this exact constant out of this exact file and compares it to
/// android/app/src/main/res/values/colors.xml, so the two cannot drift apart
/// quietly. **N11-T04 rules P14 and amends CONVENTIONS §2.11 and 13 §5.4
/// together.** This task authors indelible.md's value, because the epic's own
/// source table makes indelible.md binding on every hex and 06 binding on every
/// name — which is why the name still reads `04` while the value measures L*
/// 2.8. That mismatch is the conflict, left visible on purpose.
///
/// Not pure black: white-on-black is the worst halation case, and roughly 47% of
/// adults have some astigmatism (§2.2).
const Color nSurface04 = Color(0xFF0A0A0B); // L*  2.8

/// L* 5.94. Named 06 rather than 07 only because it is the lower of the pair —
/// see nSurface07. The numbers ORDER the ramp; they do not encode it.
const Color nSurface06 = Color(0xFF131315); // L*  5.9

/// L* 6.39, which rounds to 06 as well. It takes 07 because nSurface06 is
/// already spoken for, and two constants with one name is worse than one
/// constant with an approximate one.
const Color nSurface07 = Color(0xFF141416); // L*  6.4
const Color nSurface10 = Color(0xFF1C1C1F); // L* 10.4 — the only filled shapes
const Color nSurface17 = Color(0xFF2A2A2E); // L* 17.2

const Color nInk92 = Color(0xFFEDE8DC); // 16.19:1 on nSurface04
const Color nInk67 = Color(0xFFA8A296); //  7.80:1
const Color nInk58 = Color(0xFF8F8A7E); //  5.75:1

/// 3.52:1 — NON-TEXT ONLY. This is the value indelible.md §2.4 records as
/// overruled *for text*: in a system whose entire claim is that a struck row
/// stays legible forever, 3.52:1 is a contradiction of the thesis rather than an
/// accessibility miss. It survives demoted to a rule; nInk58 carries struck text.
const Color nInk44 = Color(0xFF6B675F); //  3.52:1

const Color nMadder46 = Color(0xFFB94A40); //  3.88:1 — NON-TEXT ONLY
const Color nMadder57 = Color(0xFFD4685C); //  5.59:1

// ---- red-shift ramp (base rSurface02) --------------------------------------
// indelible.md §2.6's eleven values, in the same order as the night ramp: five
// surfaces, three inks, one rule, two marks. The override exists because a red
// head torch is the one light a shepherd already carries.

const Color rSurface02 = Color(0xFF080605); // L*  1.7
const Color rSurface03 = Color(0xFF0F0B09); // L*  3.3
const Color rSurface04 = Color(0xFF120D0A); // L*  4.0
const Color rSurface07 = Color(0xFF1A1310); // L*  6.5
const Color rSurface11 = Color(0xFF261C17); // L* 11.3

const Color rInk74 = Color(0xFFE4A896); //  9.96:1 on rSurface02
const Color rInk60 = Color(0xFFB8846F); //  6.32:1
const Color rInk54 = Color(0xFFA4756A); //  5.13:1
const Color rInk45 = Color(0xFF8A6053); //  3.73:1 — NON-TEXT ONLY

const Color rMadder51 = Color(0xFFC9564A); //  4.73:1 — NON-TEXT ONLY
const Color rSalmon83 = Color(0xFFF2C4AE); // 12.79:1

// ---- amber night-shift ramp (base aSurface00) ------------------------------
// 06 §3.2 verbatim. There is NO indelible.md table for amber: indelible ships
// two themes and 06 §4 ships six palettes. That is conflict P6, and R35 freezes
// the ids and the labels but not the values, so these are 06's to give.

const Color aSurface00 = Color(0xFF000000);
const Color aSurface04 = Color(0xFF140D00);
const Color aSurface08 = Color(0xFF1F1400);

const Color aAmber95 = Color(0xFFFFE0A3); // 16.44:1 on aSurface00
const Color aAmber85 = Color(0xFFFFC46B); // 13.36:1
const Color aAmber70 = Color(0xFFFFB000); // 11.46:1
const Color aAmber55 = Color(0xFFD68F00); //  7.79:1
const Color aAmber45 = Color(0xFFC98400); //  6.78:1
const Color aAmber30 = Color(0xFFA66E00); //  4.85:1 — outline / non-text only

// ---- high-contrast additions ------------------------------------------------

const Color hOutline = Color(0xFF7A7A7A); //  4.89:1 on aSurface00
const Color hGreen = Color(0xFFA8F0C6); // 15.94:1
const Color hAmber = Color(0xFFFFE08A); // 16.28:1
const Color hSalmon = Color(0xFFFFC7BD); // 14.16:1

// ---- spacing scale (logical pixels) ----------------------------------------
// indelible.md §4.1's TWELVE steps, four-based, no half-steps. 06 §3.2 prints
// six of them; the other six are here rather than typed into a widget in N10,
// because 06 §1 is explicit that a direction needing a token this system does
// not have adds the token — it does not add a literal to a widget. The same
// applies one tier down.

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

// ---- geometry (logical pixels) ----------------------------------------------
// indelible.md §4.2. Radii are 0 everywhere but the slab, and the slab's 2 is
// what makes it read as a printed block rather than a card.

const double ruleW = 2.0;
const double ruleStrikeW = 3.0;
const double ruleDoubleGap = 3.0;
const double radiusSlab = 2.0;
const double radiusRecord = 0.0;
const double radiusSheet = 0.0;

// lib/core/ui/control_voice.dart
//
// **THE CONTROL VOICE, WHICH WAS RULED AND THEN NEVER BUILT.**
//
// `indelible.md §1.2` Rule 2 is *the record is set in the book face; the
// controls are set in the machine face* — serif means it happened, sans means it
// is a thing you can press. Two typefaces carried it.
//
// **P7 CLOSED THAT AT ONE FAMILY** (2026-08-02). Decision #98 bundles Atkinson
// Hyperlegible Next, which is a sans, so a second face for controls would have
// been sans against sans: the letterform distinction collapses either way and
// the ~700 kB buys nothing it was chosen for. The ruling replaced it —
// `indelible.md §3.1`, amended in the same change:
//
//   > **capitals and `w600`/`w700` are control; sentence case and `w500` is
//   > record.**
//
// **HALF OF THAT SHIPPED.** `buildShedTextTheme` builds the weight ladder and
// `typography_test.dart` asserts it at every palette. The case half did not, and
// that test says so in as many words: *"the case half is a review question,
// because a TextTheme cannot know whether a label was written in capitals."*
//
// A review question is a rule that has dropped to merely documented, and
// `CLAUDE.md` is blunt about what that means: **a rule that has dropped to
// merely documented has been deleted, whatever the prose says.** Measured
// 2026-08-08 across `lib/core/ui/components/`: eight control components —
// the word button, the corner slab, the section heading, the band, the status
// badge and the three buttons — rendered sentence case. Only the page header
// uppercased anything.
//
// So the app shipped with ONE voice. Every screenshot the owner called *"really
// bad"* and *"not even the standards of the UI from ten years ago"* was a page
// where a pressable word and a recorded fact were typographically identical, and
// the mechanism meant to tell them apart had been ruled, written down, and left
// out of the code.
//
// ---------------------------------------------------------------------------
// WHY THE COMPONENT UPPERCASES AND THE STRING DOES NOT
// ---------------------------------------------------------------------------
//
// **Flutter has no `text-transform`**, so somebody has to call `toUpperCase()`.
// The ARB is the wrong place, and `quickEntryPageHeader`'s description has said
// so since it was written: *"the widget applies toUpperCase(); do not store
// shouty caps here, because the caps are a typographic decision owned by the
// design system."*
//
// Three reasons it is not merely a preference:
//
//   1. **A translator cannot see a typographic rule.** A string stored SHOUTING
//      arrives in the next locale shouting, in a script that may have no case at
//      all — and `toUpperCase()` on a locale-free string is the one place Dart
//      quietly does the wrong thing for Turkish dotted i. This function takes
//      the caps decision away from the copy and leaves the copy readable.
//   2. **A screen reader must not shout.** `ShedTapTarget` announces
//      `semanticLabel`, which stays sentence case; only the glyphs change. A
//      label stored in capitals is announced letter-by-letter by some engines.
//   3. **It is idempotent**, which is what makes adopting it safe. 159 ARB values
//      are currently authored in capitals; `toUpperCase()` of those is
//      themselves, so every one of them renders exactly as it does today and the
//      copy can be un-shouted later, string by string, with no visual change.
library;

import 'package:flutter/material.dart';

/// `indelible.md §3.4`'s tracking, as fractions of the font size.
///
/// **CAPITALS WITHOUT TRACKING ARE WORSE THAN NO CAPITALS.** Uppercase letters
/// have no ascenders or descenders to separate them, so the word becomes one
/// rectangle — and a rectangle read through a head torch at 30% brightness is a
/// shape you match rather than a word you read. The tracking is what keeps the
/// counters open; §3.4 gives a different value per role because the smaller the
/// caps, the more they need.
const double kTrackControl = 0.01; // `--t-ctl` 20, `--t-ctl-lg` 22, `--t-ctl-sm` 19
const double kTrackSlab = 0.06; // `--t-slab` 26 — the corner slab
const double kTrackHead = 0.10; // `--t-head` — the page header
const double kTrackStamp = 0.14; // `--t-stamp` — `AUTO`, `STRUCK`, `OVER`

/// The control voice: **capitals**.
///
/// `toUpperCase()` with no locale argument, deliberately: Dart's locale-aware
/// form lives on `intl` and `lib/core/ui/` may not import it (`layer.core_ui`),
/// and the app ships `en` only. The day a second locale lands, this is the one
/// function that has to learn about it — which is the whole reason the transform
/// is here rather than in nine call sites.
String controlCase(String label) => label.toUpperCase();

/// [style] in the control voice: capitals **and** the tracking that makes them
/// legible.
///
/// Returns `null` for a null style so a caller can pass a `TextTheme` role
/// straight through without a bang.
TextStyle? controlStyle(TextStyle? style, {double track = kTrackControl}) => style?.copyWith(
  // **A FRACTION OF THE SIZE, NEVER A FIXED NUMBER OF PIXELS.** §3.4 states the
  // tracking in `em` for a reason: at 200% text scale a fixed 0.2 pt of tracking
  // is invisible, and the caps close back up on exactly the device whose owner
  // turned the text up because they were struggling to read it.
  letterSpacing: (style.fontSize ?? 0) * track,
);

// lib/core/ui/motion.dart — the reduce-motion resolver.
//
// T09 adds the motion TOKENS and the haptic vocabulary to this file on top of
// what is here.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The only correct cross-platform reduce-motion check on Flutter 3.44, and it
/// is an OR because **neither flag alone is enough** (decision #105):
///
///   * iOS never sets `disableAnimations`;
///   * Android never sets `reduceMotion`;
///   * `MediaQueryData` has no `reduceMotion` property at all.
///
/// A developer working on one platform never exercises the other branch, which
/// is why the canary in reduce_motion_test.dart writes the simplified form down
/// as a failing expectation — so nobody "tidies" the OR away.
///
/// **Depending on `MediaQuery.disableAnimationsOf` is also what makes this
/// live.** `_MediaQueryFromView` implements `didChangeAccessibilityFeatures`, so
/// any accessibility-flag change — including the iOS-only one, which is read off
/// the platform dispatcher rather than off `MediaQuery` — invalidates
/// `MediaQuery` and rebuilds this widget with it. Read the dispatcher alone and
/// the value is correct once and then stale forever.
bool prefersReducedMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;

/// What a reduced token resolves to.
///
/// **`Duration.zero`, never merely shorter.** indelible.md §5.3: the glyph is
/// simply there, the sheet is simply there, the strike is drawn full-width
/// instantly. A 40 ms compromise on the ink token would pass a
/// `lessThan(50)` assertion and still be an animation to somebody who asked for
/// none.
///
/// Its one consumer is `ShedTokens.motion`, reached through the narrow `copyWith`
/// T02 authored:
///
/// ```dart
/// t.copyWith(motion: prefersReducedMotion(context) ? Duration.zero : t.motion)
/// ```
///
/// **That wiring is N11/N12's**, in `themeProvider` and `ShedBookApp`. This file
/// lands the resolver; the obligation to wire it is named in N09's pull request
/// so it is not lost between epics.
Duration resolveMotion(Duration normal, {required bool reduced}) =>
    reduced ? Duration.zero : normal;

// ---------------------------------------------------------------------------
// The motion tokens — indelible.md §5.1. FOUR durations and no fifth.
// ---------------------------------------------------------------------------
//
// These are named constants rather than three more per-palette fields because
// they DO NOT VARY BY PALETTE. `ShedTokens.motion` stays as the one theme-level
// duration the resolver zeroes; the four below are the vocabulary.
//
// The mismatch is stated rather than left implicit: 06 §3.3 gives the extension
// one `motion` field and indelible.md §5.1 has four durations. 06 §1's rule —
// add the token, never a literal in a widget — applies just as much to a
// duration typed into an AnimatedOpacity as to a hex.

/// The press flash, and it is **40 ms whether or not motion is reduced**.
///
/// indelible.md §5.3's deliberate exception: it is the only visual feedback left
/// to somebody who cannot feel the screen, and it is a fill change rather than a
/// movement — nothing translates, scales or lifts, so there is nothing for
/// reduce-motion to be protecting against.
///
/// A slab or key filling from `surfaceFill` to `surfacePressed`. **Fill only —
/// no scale, no lift, no ripple.**
const Duration kPressFlash = Duration(milliseconds: 40);

/// A newly printed glyph fading 0 → 1: a tally stroke landing, a tag printing
/// into the row, a stamp appearing. **Opacity only. Zero translation.**
const Duration kMotionInk = Duration(milliseconds: 120);

/// The bottom sheet rising. **Translate-Y only** — no fade, no backdrop blur, no
/// scrim animation.
const Duration kMotionSheet = Duration(milliseconds: 160);

/// The strike line drawing left to right, `scaleX(0) → scaleX(1)`, origin left.
const Duration kMotionStrike = Duration(milliseconds: 180);

/// `cubic-bezier(0.2, 0, 0, 1)`. Every token but the strike.
const Cubic kEaseOut = Cubic(0.2, 0, 0, 1);

/// **Linear, and it is the only linear curve in the app.** indelible.md §5.1:
/// *"the gesture being represented is a pen drawn across a page at constant
/// speed"*. It is the only animation with a direction, and the one place the
/// animation **is** the meaning — an eased strike reads as a UI effect rather
/// than as a line being drawn.
const Curve kEaseStrike = Curves.linear;

// ---------------------------------------------------------------------------
// The haptic vocabulary — 06 §10.1, and the P10 ruling
// ---------------------------------------------------------------------------
//
// P10 ASKED "FOUR HAPTICS OR FIVE" AND THE TWO LISTS ARE NOT THE SAME KIND OF
// LIST, which is the whole substance of the ruling.
//
//   * 06 §10.1's FOUR are API MEMBERS KEYED TO WRITE OUTCOMES — a vocabulary of
//     what the database just did.
//   * indelible.md §5.4's FIVE are RHYTHMS KEYED TO EVENTS — one 10 ms tick for
//     a tally stroke or keypad digit; two ticks 60 ms apart when a tag lands or
//     a row commits; two ticks 120 ms apart for a strike, "deliberately slower,
//     a different rhythm from a commit"; one tick when a pen crosses the
//     turn-out threshold. Ruling "four" or "five" without saying OF WHAT settles
//     nothing.
//
// RULED: the four API members. Two reasons, and neither is taste.
//
//   1. Flutter has no two-ticks-60 ms-apart primitive. Sequencing two
//      selectionClick() calls behind a Future.delayed is a custom pattern.
//   2. 06 §10.1 on what it would be worth: "on iOS three or four patterns are
//      genuinely distinguishable through a glove; on Android assume TWO, because
//      vendor LRA quality varies enormously and CONFIRM/REJECT only exist on
//      API 30+." A five-rhythm vocabulary that resolves to two perceivable
//      patterns on half the target devices is a vocabulary in the document and
//      not in the shed.
//
// indelible.md §5.4's rhythms survive as the DESIGN INTENT the four members
// express — the strike being a different rhythm from a commit is exactly why
// warningNotification and errorNotification are separate entries below.
//
// REFERENCES §22 E1 WAS RUN against the installed 3.44.8 SDK on 2026-08-01:
// successNotification, warningNotification and errorNotification all exist in
// packages/flutter/lib/src/services/haptic_feedback.dart. The documented
// fallback — degrading the commit haptic to heavyImpact() — is NOT needed.
//
// Every member is referenced AS A SYMBOL, never as a string. A symbol is a
// compile-time existence proof; 'successNotification' in a map key is a runtime
// hope.

/// What the write did. Named here rather than taken from `WriteOutcome` because
/// that type is N11-T01's — when it lands, this becomes a switch over it and the
/// mapping stops being expressible any other way.
enum ShedWriteSignal {
  /// The transaction **returned** `WriteCommitted` with no warnings.
  committed,

  /// It committed **and** the controller's `List<Warning>` is non-empty. A
  /// committed-with-warnings write is **not** a failure, and conflating the two
  /// would tell a shepherd to try again after a record that already exists.
  committedWithWarnings,

  /// The transaction returned `WriteFailed`.
  refused,
}

/// The haptic for a completed write.
///
/// **It cannot be called without stating an outcome**, which is what makes 06
/// §10.1's *"fires when the transaction returned"* structural rather than a
/// comment. There is no argument-free `hapticSuccess()` a gesture callback could
/// reach for — *"a false receipt is worse than no receipt"*.
Future<void> hapticForWrite(ShedWriteSignal signal) => switch (signal) {
  ShedWriteSignal.committed => HapticFeedback.successNotification(),
  ShedWriteSignal.committedWithWarnings => HapticFeedback.warningNotification(),
  ShedWriteSignal.refused => HapticFeedback.errorNotification(),
};

/// A key press or selection change.
///
/// Fires on pointer **down, before the state change**, so the finger feels the
/// *key* rather than the result. That is the exact opposite timing from
/// [hapticForWrite], and swapping the two is the mistake.
Future<void> hapticSelection() => HapticFeedback.selectionClick();

// TWO EVENTS DELIBERATELY HAVE NO ENTRY, and the omissions are decisions:
//
//   * THE FREE-TIER CAP NEVER FIRES ONE (decision #90). Both gated actions are
//     calm-UI, and "a buzz would turn a calm gate into a rebuke".
//     EntryContext.liveEntry is structurally incapable of being blocked at all.
//   * HapticFeedback.vibrate() IS BANNED. On Android it is a long buzz, not a
//     tick.
//
// Haptics are NOT disabled by reduce-motion — they are not motion
// (indelible.md §5.4). They are individually disableable in Settings (N29), and
// an app CANNOT DETECT that they are switched off system-wide, which is why they
// are one of three redundant channels and never the only one (06 §10.3,
// decision #103).

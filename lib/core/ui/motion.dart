// lib/core/ui/motion.dart — the reduce-motion resolver.
//
// T09 adds the motion TOKENS and the haptic vocabulary to this file on top of
// what is here.
import 'package:flutter/material.dart';

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

/// The press flash, and it is **40 ms whether or not motion is reduced**.
///
/// indelible.md §5.3's deliberate exception: it is the only visual feedback left
/// to somebody who cannot feel the screen, and it is a fill change rather than a
/// movement — nothing translates, scales or lifts, so there is nothing for
/// reduce-motion to be protecting against.
const Duration kPressFlash = Duration(milliseconds: 40);

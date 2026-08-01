// test/design/reduce_motion_test.dart — reduce-motion resolves to ZERO, not to
// shorter.
//
// Nothing here is time-shaped: a Duration is a span, not a clock reading, and no
// wall time is read. T06's formatters_dst_test.dart has the epic's only uk-zone
// group.
//
// The sweeps this file does NOT contain: it tests one resolver, not fourteen
// screens. Nothing in test/design/ iterates kPumpableVariants until N33-T02 and
// N33-T03.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/ui/motion.dart';

/// The three animated tokens, at their normal durations (indelible.md §5.3).
const Duration _ink = Duration(milliseconds: 120);
const Duration _sheet = Duration(milliseconds: 160);
const Duration _strike = Duration(milliseconds: 180);

/// Pumps [child] with the two accessibility flags set independently.
///
/// The Android flag rides on `MediaQuery`; the iOS one is on the platform
/// dispatcher and is set through `tester.platformDispatcher`, which is why the
/// two branches cannot be exercised the same way.
Future<void> _pumpWithFlags(
  WidgetTester tester, {
  required bool android,
  required bool ios,
  required void Function(BuildContext) onBuild,
}) async {
  // FakeAccessibilityFeatures is flutter_test's own, exported from
  // src/window.dart. Hand-rolling an `implements AccessibilityFeatures` class
  // was the first attempt and it does not compile: the interface carries
  // supportsAnnounce, autoPlayVideos, autoPlayAnimatedImages and
  // deterministicCursor as well, and a hand-written fake has to be updated
  // every time the engine adds a feature.
  tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
    reduceMotion: ios,
  );
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: android),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (BuildContext context) {
            onBuild(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('every animation resolves to zero duration when reduce-motion is on', (
    WidgetTester tester,
  ) async {
    // THE ANCHOR. Ink, sheet and strike all collapse.
    late bool reduced;
    await _pumpWithFlags(
      tester,
      android: true,
      ios: false,
      onBuild: (BuildContext c) => reduced = prefersReducedMotion(c),
    );

    expect(reduced, isTrue);
    for (final Duration normal in <Duration>[_ink, _sheet, _strike]) {
      expect(resolveMotion(normal, reduced: reduced), Duration.zero);
    }
  });

  testWidgets('android flag alone reduces motion', (WidgetTester tester) async {
    // 10 §2.3's first branch. Android never sets reduceMotion, so this is the
    // only signal there is on that platform.
    late bool reduced;
    await _pumpWithFlags(
      tester,
      android: true,
      ios: false,
      onBuild: (BuildContext c) => reduced = prefersReducedMotion(c),
    );
    expect(reduced, isTrue);
  });

  testWidgets('ios flag alone reduces motion', (WidgetTester tester) async {
    // The reverse, and THE BRANCH A DEVELOPER ON ONE PLATFORM NEVER EXERCISES.
    // iOS never sets disableAnimations, so a resolver reading only MediaQuery
    // returns false here — silently, for every iOS user who asked for less
    // motion.
    late bool reduced;
    await _pumpWithFlags(
      tester,
      android: false,
      ios: true,
      onBuild: (BuildContext c) => reduced = prefersReducedMotion(c),
    );
    expect(reduced, isTrue);
  });

  testWidgets('both flags off leaves motion unreduced', (WidgetTester tester) async {
    // The negative case, so the resolver is not simply returning true.
    late bool reduced;
    await _pumpWithFlags(
      tester,
      android: false,
      ios: false,
      onBuild: (BuildContext c) => reduced = prefersReducedMotion(c),
    );

    expect(reduced, isFalse);
    expect(resolveMotion(_ink, reduced: reduced), _ink);
    expect(resolveMotion(_sheet, reduced: reduced), _sheet);
    expect(resolveMotion(_strike, reduced: reduced), _strike);
  });

  test('the press flash survives reduce-motion at 40 ms', () {
    // indelible.md §5.3's deliberate exception. It is the only visual feedback
    // left to somebody who cannot feel the screen, and it is a FILL CHANGE
    // rather than a movement — nothing translates, scales or lifts, so there is
    // nothing for reduce-motion to protect against.
    expect(kPressFlash, const Duration(milliseconds: 40));
    // It is a constant rather than something resolveMotion touches, which is
    // what makes the exception structural instead of a forgotten branch.
    expect(resolveMotion(kPressFlash, reduced: true), Duration.zero);
    expect(
      kPressFlash,
      const Duration(milliseconds: 40),
      reason: 'the token itself is unchanged — call sites do not resolve it',
    );
  });

  test('reduced is Duration.zero and not merely shorter', () {
    // Exact equality. `lessThan(50)` would pass a 40 ms compromise on the ink
    // token, which is still an animation to somebody who asked for none.
    for (final Duration normal in <Duration>[_ink, _sheet, _strike]) {
      final Duration got = resolveMotion(normal, reduced: true);
      expect(got, Duration.zero);
      expect(got.inMicroseconds, 0);
    }
  });

  testWidgets('a change to the accessibility flag rebuilds the dependent widget', (
    WidgetTester tester,
  ) async {
    // _MediaQueryFromView implements didChangeAccessibilityFeatures, so the
    // MediaQuery dependency is what makes the resolver LIVE rather than
    // read-once. Read the platform dispatcher alone and the value is correct
    // once and then stale forever.
    final List<bool> seen = <bool>[];

    Widget host({required bool android}) => MediaQuery(
      data: MediaQueryData(disableAnimations: android),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (BuildContext context) {
            seen.add(prefersReducedMotion(context));
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pumpWidget(host(android: false));
    await tester.pumpWidget(host(android: true));

    expect(seen.first, isFalse);
    expect(seen.last, isTrue, reason: 'the resolver did not see the flag change');
  });

  testWidgets('CANARY: a resolver reading only disableAnimationsOf fails the iOS branch', (
    WidgetTester tester,
  ) async {
    // THE ANTI-PATTERN, WRITTEN DOWN AS A FAILING EXPECTATION so nobody
    // "simplifies" the OR away. If this case ever passes, either Flutter started
    // mirroring the iOS flag onto MediaQuery — in which case decision #105 is
    // stale and should be re-read — or the harness stopped setting it, in which
    // case the three cases above are proving nothing.
    late bool naive;
    late bool correct;

    await _pumpWithFlags(
      tester,
      android: false,
      ios: true,
      onBuild: (BuildContext c) {
        naive = MediaQuery.disableAnimationsOf(c);
        correct = prefersReducedMotion(c);
      },
    );

    expect(naive, isFalse, reason: 'the naive resolver would have missed this user');
    expect(correct, isTrue);
  });

  test('haptics are not gated on reduce-motion', () {
    // The vocabulary is T09's. This asserts the resolver is not wired to it:
    // reduce-motion is about MOVEMENT, and a tick is not movement. Somebody who
    // turned motion off still gets the confirmation they can feel — which for a
    // gloved hand at 03:20 may be the only one they get.
    //
    // Source text, because the claim is an absence.
    const String motionFile = 'lib/core/ui/motion.dart';
    final String source = File(
      motionFile,
    ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

    // AMENDED BY T09. When T08 wrote this case, motion.dart held only the
    // resolver, so "the file names no haptic" was a fair proxy. T09 adds the
    // vocabulary to the same file — which is the epic's stated ordering — so the
    // proxy is now false while the RULE is unchanged.
    //
    // The rule was never "they live apart". It is that the resolver and the
    // vocabulary are never JOINED: no line reads a reduce-motion flag and a
    // haptic together. That is what is asserted now, and it is the stronger
    // claim — a file split would have satisfied the old form while a single
    // gated call site broke the actual rule.
    expect(source, isNot(matches(RegExp(r'prefersReducedMotion[^\n]*Haptic'))));
    expect(source, isNot(matches(RegExp(r'Haptic[^\n]*prefersReducedMotion'))));
    expect(source, isNot(matches(RegExp(r'reduced[^\n]*Haptic'))));
    expect(source, isNot(contains('vibrat')));
  });
}

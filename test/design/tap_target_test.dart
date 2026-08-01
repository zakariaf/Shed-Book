// test/design/tap_target_test.dart — the 60 pt contract, measured.
//
// THIS FILE ITERATES NO VARIANT TABLE, AND THAT IS DELIBERATE.
//
// 12 §7.4's geometric sweep and semantics_gate_test.dart's sweep both iterate
// kPumpableVariants — a fourteen-entry Map declared in test/support/harness.dart,
// which is N12-T05 and is not complete until N33. Writing either here would mean
// a gate that iterates an empty list and passes forever, which is critique
// defect S7 by name. The sweeps are N33-T02 and N33-T03, and the geometric half
// extends THIS file rather than creating a second one.
//
// What this file proves is one widget, thoroughly. Nothing here is time-shaped.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/palettes.dart';
import 'package:shed_book/core/ui/theme.dart';

const String _component = 'lib/core/ui/components/shed_tap_target.dart';

/// The 60 pt contract, not indelible.md's 64 build box. 06 §6.1 sets 60 as the
/// spec floor — Parhi/Karlson/Bederson's 9.5 mm, measured for a bare warm dry
/// thumb in a lab — and that is what the guideline asserts.
final MinimumTapTargetGuideline shedTapTargetGuideline = MinimumTapTargetGuideline(
  size: const Size(60, 60),
  link: 'docs/engineering/06-design-system.md#6-tap-targets-hit-slop-and-separation',
);

/// A real theme, because `ShedTapTarget` reads `context.tokens.tapMin` and the
/// accessor ends in `!` — a bare `MaterialApp` throws a null check on a widget
/// deep in the tree with a message that does not mention tokens.
Widget _host(Widget child, {TextScaler scaler = TextScaler.noScaling}) => MaterialApp(
  theme: buildShedTheme(nightPalette),
  home: MediaQuery(
    data: MediaQueryData(textScaler: scaler),
    child: Scaffold(body: Center(child: child)),
  ),
);

String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

void main() {
  testWidgets('ShedTapTarget lays out at least 64 by 64 and requires a semanticLabel', (
    WidgetTester tester,
  ) async {
    // THE ANCHOR. A 20 px child inside a target that measures at least 64 — the
    // margin around it is the hit slop, and it is the whole point of the widget.
    await tester.pumpWidget(
      _host(
        ShedTapTarget(
          onTap: () {},
          semanticLabel: 'Lambing',
          minSize: 64,
          child: const SizedBox.square(dimension: 20),
        ),
      ),
    );

    final Size size = tester.getSize(find.byType(ShedTapTarget));
    expect(size.width, greaterThanOrEqualTo(64.0));
    expect(size.height, greaterThanOrEqualTo(64.0));
  });

  testWidgets('the box is never below 64 at textScaler 1.0, 1.3 and 2.0', (
    WidgetTester tester,
  ) async {
    // The box grows with text and never shrinks. Decision #99 — never clamp —
    // means a 200% user is a real user, and a target that shrank to fit would
    // break the contract in exactly the accessibility mode that needs it.
    for (final double factor in <double>[1.0, 1.3, 2.0]) {
      await tester.pumpWidget(
        _host(
          ShedTapTarget(
            onTap: () {},
            semanticLabel: 'Lambing',
            minSize: 64,
            child: const Text('412'),
          ),
          scaler: TextScaler.linear(factor),
        ),
      );

      final Size size = tester.getSize(find.byType(ShedTapTarget));
      expect(size.width, greaterThanOrEqualTo(64.0), reason: 'textScaler $factor');
      expect(size.height, greaterThanOrEqualTo(64.0), reason: 'textScaler $factor');
    }
  });

  testWidgets('a tap in the transparent margin fires onTap', (WidgetTester tester) async {
    // HitTestBehavior.opaque is what makes the margin a target rather than a
    // hole. Without it, the 22 points of empty space around a 20 px child are
    // dead — and at 03:20 that is most of what a cold thumb actually hits.
    int taps = 0;
    await tester.pumpWidget(
      _host(
        ShedTapTarget(
          onTap: () => taps++,
          semanticLabel: 'Lambing',
          minSize: 64,
          child: const SizedBox.square(dimension: 20),
        ),
      ),
    );

    final Rect rect = tester.getRect(find.byType(ShedTapTarget));
    // Two points in from the corner: inside the target, well outside the child.
    await tester.tapAt(rect.topLeft + const Offset(2, 2));
    await tester.pump();

    expect(taps, 1, reason: 'the hit slop is not opaque');
  });

  testWidgets('an enabled target exposes SemanticsAction.tap', (WidgetTester tester) async {
    // THE FAILURE NO BUILT-IN GUIDELINE CATCHES. ExcludeSemantics strips the
    // GestureDetector's own tap action, so a ShedTapTarget missing the
    // Semantics(onTap:) line announces as a button and then does nothing when
    // VoiceOver or Switch Control activates it.
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        ShedTapTarget(
          onTap: () {},
          semanticLabel: 'Lambing',
          minSize: 64,
          child: const SizedBox.square(dimension: 20),
        ),
      ),
    );

    final SemanticsNode node = tester.getSemantics(find.byType(ShedTapTarget));
    final SemanticsData data = node.getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);

    handle.dispose();
  });

  testWidgets('a disabled target announces enabled false and still measures 64 by 64', (
    WidgetTester tester,
  ) async {
    // It is still a target. It is just not an action — the size and the label
    // survive, so the scan still stops there and still says what it is.
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        const ShedTapTarget(
          onTap: null,
          semanticLabel: 'Lambing',
          minSize: 64,
          child: SizedBox.square(dimension: 20),
        ),
      ),
    );

    final SemanticsNode node = tester.getSemantics(find.byType(ShedTapTarget));
    final SemanticsData data = node.getSemanticsData();
    expect(data.flagsCollection.isEnabled, Tristate.isFalse);
    expect(data.hasAction(SemanticsAction.tap), isFalse);

    final Size size = tester.getSize(find.byType(ShedTapTarget));
    expect(size.width, greaterThanOrEqualTo(64.0));
    expect(size.height, greaterThanOrEqualTo(64.0));

    handle.dispose();
  });

  testWidgets('the semantics label is exactly the string passed and carries no role word', (
    WidgetTester tester,
  ) async {
    // 10 §3.2 rule 1. The platform already announces the role; a label ending in
    // "button" makes the user hear it twice.
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        ShedTapTarget(
          onTap: () {},
          semanticLabel: 'Lambing',
          minSize: 64,
          child: const SizedBox.square(dimension: 20),
        ),
      ),
    );

    final SemanticsNode node = tester.getSemantics(find.byType(ShedTapTarget));
    expect(node.label, 'Lambing');
    for (final String role in <String>['button', 'link', 'tab']) {
      expect(node.label.toLowerCase().endsWith(role), isFalse, reason: role);
    }

    handle.dispose();
  });

  testWidgets('onTapHint reaches the node only alongside a tap action', (
    WidgetTester tester,
  ) async {
    // A hint on an action-less node is inert AND misleading: it renames a verb
    // that is not there.
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        ShedTapTarget(
          onTap: () {},
          semanticLabel: 'Lambing',
          onTapHint: 'record a lambing',
          minSize: 64,
          child: const SizedBox.square(dimension: 20),
        ),
      ),
    );

    final SemanticsNode node = tester.getSemantics(find.byType(ShedTapTarget));
    final SemanticsData data = node.getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue, reason: 'the hint has no verb to rename');
    expect(node.hintOverrides?.onTapHint, 'record a lambing');

    handle.dispose();
  });

  testWidgets('the target passes shedTapTargetGuideline and labeledTapTargetGuideline', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        ShedTapTarget(
          onTap: () {},
          semanticLabel: 'Lambing',
          minSize: 64,
          child: const SizedBox.square(dimension: 20),
        ),
      ),
    );

    await expectLater(tester, meetsGuideline(shedTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });

  testWidgets('CANARY: a deliberately 40x40 target FAILS the 60 pt guideline', (
    WidgetTester tester,
  ) async {
    // 12 §7.5. This calls evaluate() DIRECTLY rather than wrapping
    // meetsGuideline in an isNot: meetsGuideline is an AsyncMatcher, asserting
    // that something fails one is easy to get subtly wrong, and "a canary you
    // cannot read is not a canary".
    //
    // Without this, a guideline that silently stopped evaluating anything would
    // keep every other case in this file green forever.
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        GestureDetector(
          onTap: () {},
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.square(dimension: 40, child: Text('x')),
        ),
      ),
    );

    final Evaluation result = await shedTapTargetGuideline.evaluate(tester);
    expect(result.passed, isFalse, reason: 'the 60 pt guideline no longer detects a 40 pt target');

    handle.dispose();
  });

  test('ShedTapTarget uses no InkWell and binds no banned gesture', () {
    // CLAUDE.md's absolute list. A ripple is also an animation on a target,
    // which reduce-motion would have to resolve to zero — so avoiding InkWell
    // here means the rule does not depend on theme.dart's NoSplash pin holding.
    final String source = _declarations(_component);
    for (final String banned in <String>[
      'InkWell',
      'onLongPress',
      'onPan',
      'onScale',
      'onForcePress',
      'Dismissible',
      'Draggable',
      'Tooltip',
    ]) {
      expect(source, isNot(contains(banned)), reason: banned);
    }
  });

  test('semanticLabel is a required non-nullable String', () {
    // Source text, because the mechanism is the TYPE. A runtime assert would be
    // stripped in release — precisely the build where nobody is watching.
    expect(_declarations(_component), contains('required this.semanticLabel'));
    expect(_declarations(_component), contains('final String semanticLabel;'));
    expect(
      _declarations(_component),
      isNot(contains('String? semanticLabel')),
      reason: 'a nullable label is an unnamed stop in a Switch Control scan',
    );
  });

  test('this file iterates no variant table', () {
    // S7, held open. When N33 extends this file with the geometric sweep, this
    // case is what has to be deliberately removed — which is the moment somebody
    // checks that kPumpableVariants is actually populated.
    final String self = File('test/design/tap_target_test.dart').readAsStringSync();
    final String body = self
        .split('\n')
        .where((String l) => !l.trimLeft().startsWith('//'))
        .join('\n');

    // The needle is SPLIT ACROSS TWO ADJACENT LITERALS on purpose. Dart
    // concatenates them at compile time, so the runtime value is the whole
    // identifier while this file's own source text never contains it — without
    // that, this case fires on itself, which it did on the first run.
    const String needle =
        'kPumpable'
        'Variants';

    expect(body, isNot(contains(needle)));
    expect(self, contains('N33-T02'));
    expect(self, contains('N33-T03'));
  });
}

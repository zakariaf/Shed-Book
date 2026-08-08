// test/design/tap_target_test.dart — the 60 pt contract, measured.
//
// **TWO GATES, AND THE SECOND ONE IS THE ONLY GATE THAT SEES THE APP'S MOST
// IMPORTANT BUTTON.**
//
// Gate 1 is `MinimumTapTargetGuideline`, and `12 §7.3` rule 4 is explicit that
// it **silently skips** any node whose painted rect touches the view boundary.
// `07 §20.1` puts the primary action of Quick Entry, Lambing Entry, Foster and
// Pen Board in a full-bleed bottom action bar. So decision #100's *"plus a
// second geometric gate"* is not belt and braces: without gate 2, the slab is
// never measured by anything.
//
// Gate 2 is N33-T03's sweep at the foot of this file — every `ShedTapTarget`'s rect
// across `kPumpableVariants`, at three devices and two text scales. It measures
// rects and reads one semantics action; it runs no tree-walking guideline
// (N33-T02's `semantics_gate_test.dart` owns those) and no contrast check
// (`contrast_test.dart`, `12 §7.6`). Two costs against one table, split on
// purpose.
//
// The rest of the file proves one widget, thoroughly. Nothing here is
// time-shaped.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/palettes.dart';
import 'package:shed_book/core/ui/theme.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/features/quick_entry/quick_entry_screen.dart';

import '../support/harness.dart';
import 'wcag.dart';

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

  // ── GATE 2: THE GEOMETRIC SWEEP ───────────────────────────────────────────
  //
  // **P9 IS RULED HERE AND THE NUMBER IS A TOKEN.** `CONVENTIONS §6` R86 records
  // it: 16 pt wins, and the two legal gaps are **0 or ≥ `gapMin`**. The
  // assertion reads `t.gapMin` off the pumped tree rather than typing `16.0`,
  // because a ruling whose whole value is that it changes one place must not be
  // copied into the test that enforces it.
  //
  // **Sixty-six runs, not eighty-four.** `12 §7.4`'s table is fourteen variants;
  // three of those are `v1.1.0` screens with nothing behind them (N33-T01).
  // Eleven × 3 devices × 2 scales, derived from the same lists the loops read.

  for (final MapEntry<String, PumpableVariant> variant in kPumpableVariants.entries) {
    for (final Device device in Device.all) {
      for (final double scale in const <double>[1.0, 2.0]) {
        testWidgets('${variant.key} · ${device.name} · scale $scale — geometry', (
          WidgetTester tester,
        ) async {
          // `getSemantics` needs a live handle exactly as the guidelines do.
          // Without it the tap-action check below throws instead of asserting.
          final SemanticsHandle handle = tester.ensureSemantics();

          final AppDatabase db = await fixtureDatabase('flock_400_3seasons.json');

          // The same pin as the overflow matrix, for the same reason: a static
          // fixture read against a moving clock grows an unbounded number, and
          // an elapsed-hours string that widens every day is a target that
          // starts failing on a Tuesday for nobody's change.
          await atFixed(DateTime.utc(2026, 2, 11, 8), () async {
            final Map<String, int> ids = await variant.value.seed(db);
            await tester.pumpApp(
              variant.value.build(ids),
              db: db,
              device: device,
              textScale: scale,
            );
          });
          // **THE CLEAN-UP IS IN A `finally`, AND THE DIFFERENCE IS TEN
          // MINUTES.** The first red this sweep produced threw at the separation
          // assertion, skipped `closeApp()`, left the provider container
          // undisposed, and the case sat until flutter_test's ten-minute
          // timeout — a one-line layout defect reported as a `TimeoutException`
          // with the real failure scrolled off the top.
          //
          // **And it cannot be `addTearDown`**, which is the obvious repair and
          // is wrong for a reason `harness.dart` already wrote down at
          // `closeApp`: an `UncontrolledProviderScope` does not own its
          // container, so a tear-down disposes it AFTER `_verifyInvariants` has
          // already run. The same is true of the semantics handle, which
          // flutter_test verifies at the end of the BODY. Both have to happen
          // here.
          try {
            final ShedTokens t = tester.element(find.byType(Scaffold).first).tokens;

            // **`find.byWidget` IS UNUSABLE AND THE TEMPTING REPAIR IS WORSE.**
            // Two keypad keys can be equal `Widget`s, and `getRect` throws on a
            // finder matching more than one element. Narrowing the finder by key
            // would quietly stop measuring the twelve keys that most need
            // measuring. Match on `Element` identity.
            final List<Element> targets = find.byType(ShedTapTarget).evaluate().toList();
            final List<Rect> rects = <Rect>[
              for (final Element e in targets)
                tester.getRect(find.byElementPredicate((Element x) => x == e)),
            ];

            for (int i = 0; i < rects.length; i++) {
              final ShedTapTarget w = targets[i].widget as ShedTapTarget;
              // A DISABLED TARGET IS STILL SIZE-CHECKED. It becomes enabled
              // without moving, so it must already be big enough when it does.
              expect(
                rects[i].width,
                greaterThanOrEqualTo(t.tapMin),
                reason: '"${w.semanticLabel}" is ${rects[i].width} wide',
              );
              expect(
                rects[i].height,
                greaterThanOrEqualTo(t.tapMin),
                reason: '"${w.semanticLabel}" is ${rects[i].height} tall',
              );
            }

            // **THE SEPARATION RULE APPLIES TO WHAT IS ON SCREEN TOGETHER, AND
            // THE SIZE RULE ABOVE APPLIES TO EVERYTHING.** That split is not a
            // convenience — it is the difference between the two rules. A target's
            // size is intrinsic and wrong whether or not it has been scrolled to;
            // separation is a fact about two things a thumb can hit *right now*.
            //
            // The first red this gate produced was Quick Entry's export banner
            // reported 3.5 pt from a pen row. Both rects were real and the finding
            // was not: `07 §16.2` puts the banner INSIDE the record column's
            // scroll view, its two actions lay below the `ClipRect`, and
            // `getRect` reports an unclipped layout rect for a target no thumb can
            // reach. Comparing it against a visible row is comparing two things
            // that are never on screen together.
            //
            // Hit-testing is the honest test of *"can this be pressed where it
            // is"*, and it is the same question the rule is about. It also catches
            // a real bug for free — `06 §6.2` rule 2's target that overflows its
            // parent and has its taps silently dropped shows up here as a target
            // that measures fine and cannot be hit.
            // **AND THE PAIR MUST SHARE A SCROLL CONTEXT.** The remaining four
            // reds were all one shape: the corner slab floating over a scrolling
            // list, with some row's bottom edge landing 5 to 10 pt above it.
            //
            // That gap is not a fact about the layout — it is a fact about where
            // the list happened to stop. `indelible.md §4.3` is explicit that
            // *the stream scrolls under both*, so the intended state of that pair
            // is OVERLAP, which the rule already allows; scroll one row further
            // and the same pair measures 0, then 88, then 0 again. A rule that
            // fires on a transient of scroll offset can never be satisfied by a
            // floating affordance over a list, at any gap, because every value
            // between 0 and one row height occurs.
            //
            // What the rule is actually about is two targets a DESIGNER put next
            // to each other. Same scrollable — two rows in one list, two buttons
            // in one `Wrap` — is that; an overlay against a row underneath it is
            // not, and the overlay is opaque and on top, so the tap it receives
            // is never ambiguous about which target it reached.
            Element? scrollOf(Element target) {
              Element? found;
              target.visitAncestorElements((Element a) {
                if (a.widget is Scrollable) {
                  found = a;
                  return false;
                }
                return true;
              });
              return found;
            }

            final List<Element?> scopes = <Element?>[for (final Element e in targets) scrollOf(e)];

            bool reachable(int i) {
              final HitTestResult result = HitTestResult();
              WidgetsBinding.instance.hitTestInView(result, rects[i].center, tester.view.viewId);
              final RenderObject? render = targets[i].renderObject;
              return render != null &&
                  result.path.any((HitTestEntry<HitTestTarget> e) => e.target == render);
            }

            for (int i = 0; i < rects.length; i++) {
              if (!reachable(i)) {
                continue;
              }
              for (int j = i + 1; j < rects.length; j++) {
                if (scopes[i] != scopes[j]) {
                  continue;
                }
                if (!couldBeAdjacent(rects[i], rects[j], t.gapMin) || !reachable(j)) {
                  continue;
                }
                final double g = gapBetween(rects[i], rects[j]);
                expect(
                  g,
                  // **`precisionErrorTolerance`, AND IT IS NOT A LOOSENING.**
                  // `15.999999999999986` failed six Settings cells: the row lays
                  // its children out by dividing an available width, and the
                  // rounding lands 1.4e-14 short of a gap that IS `gapMin`. A
                  // gate that reports a fourteenth-decimal-place error as a
                  // separation defect is a gate whose output has to be triaged
                  // before it can be read, and the band this rule forbids is
                  // eight pixels wide.
                  anyOf(equals(0.0), greaterThanOrEqualTo(t.gapMin - precisionErrorTolerance)),
                  reason:
                      'gap $g between "${(targets[i].widget as ShedTapTarget).semanticLabel}" '
                      '${rects[i]} and "${(targets[j].widget as ShedTapTarget).semanticLabel}" '
                      '${rects[j]} — R86: 0 or >= ${t.gapMin}',
                );
              }
            }

            // **NO BUILT-IN GUIDELINE CHECKS THIS.** An enabled button node with
            // no tap ACTION announces perfectly and then refuses to activate
            // (`06 §6.2`) — a screen reader user is told the button is there and
            // cannot press it.
            for (final Element e in targets) {
              if ((e.widget as ShedTapTarget).onTap == null) {
                continue;
              }
              final SemanticsData node = tester
                  .getSemantics(find.byElementPredicate((Element x) => x == e))
                  .getSemanticsData();
              expect(
                node.hasAction(SemanticsAction.tap),
                isTrue,
                reason: '"${node.label}" is a button with no tap action',
              );
            }
          } finally {
            handle.dispose();
            await tester.closeApp();
          }
        });
      }
    }
  }

  testWidgets('CANARY: two targets 8 pt apart fail the separation rule', (
    WidgetTester tester,
  ) async {
    // **THIS IS WHAT STOPS R86 BEING QUIETLY REVERTED BY A `spacing: 8`.** 8 px
    // is `indelible.md` §9's number and it sits squarely inside the band the
    // published assertion already forbade — touching is legal, ≥ 16 is legal,
    // and between them is not. Without this case, a screen re-spaced to 8 would
    // fail 66 runs with no statement anywhere of what the rule is.
    const Rect a = Rect.fromLTWH(0, 0, 64, 64);
    const Rect b = Rect.fromLTWH(72, 0, 64, 64);

    expect(gapBetween(a, b), 8.0);
    expect(couldBeAdjacent(a, b, 16), isTrue, reason: 'the rule must look at this pair');
    expect(
      const <double>[8.0].single,
      isNot(anyOf(equals(0.0), greaterThanOrEqualTo(16.0))),
      reason: 'if 8 ever satisfies the rule, the 66 runs above are asserting nothing',
    );

    // And the diagonal case the helper exists for: one full key on each axis is
    // NOT the hypotenuse.
    const Rect diag = Rect.fromLTWH(80, 80, 64, 64);
    expect(gapBetween(a, diag), 16.0, reason: 'the larger axis gap, never hypot');
  });

  testWidgets('the bottom action bar is measured even though the guideline skips it', (
    WidgetTester tester,
  ) async {
    // **THE PROOF THAT GATE 2 IS NOT REDUNDANT.** `12 §7.3` rule 4 skips any
    // node whose painted rect touches the view boundary, and Quick Entry's slab
    // is in a full-bleed bottom bar. If this ever fails, either the bar stopped
    // being full-bleed or gate 1 grew the ability to see it — and in the second
    // case this whole file's second half could be deleted.
    final SemanticsHandle handle = tester.ensureSemantics();

    final AppDatabase db = await fixtureDatabase('flock_400_3seasons.json');
    await atFixed(DateTime.utc(2026, 2, 11, 8), () async {
      await tester.pumpApp(const QuickEntryScreen(), db: db, device: Device.small);
    });
    final List<Element> targets = find.byType(ShedTapTarget).evaluate().toList();
    expect(targets, isNotEmpty, reason: 'a screen with no targets measures nothing');

    // The slab sits at the bottom of the viewport, inside `pumpApp`'s 34 pt home
    // indicator inset — which is what keeps it OFF the boundary so gate 1 will
    // look at it at all. A run that zeroes that padding disables both halves at
    // once, which is why the inset is not a per-cell parameter.
    final double viewHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final Iterable<Rect> bottom = targets
        .map((Element e) => tester.getRect(find.byElementPredicate((Element x) => x == e)))
        .where((Rect r) => r.bottom > viewHeight - 200);
    expect(bottom, isNotEmpty, reason: 'nothing is in the thumb band — 07 §20.1');

    handle.dispose();
    await tester.closeApp();
  });
}

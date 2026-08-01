// test/design/components_test.dart — the component inventory.
//
// ONE FILE FOR THE WHOLE EPIC. Each of N10's eight tasks extends this file
// rather than adding a ninth; `_pumpComponent` below is the shared helper all of
// them use, and it is a private top-level function here rather than a thirteenth
// file in test/support/, because 12 §5.3 closes that list.
//
// No sweep. These are component cases, not screen cases — N33-T02 and N33-T03
// own the sweeps over kPumpableVariants, which does not exist until N12-T05.
library;

import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/ui/components/shed_primary_button.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/palettes.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/core/ui/theme.dart';

/// Pumps one component inside a real theme.
///
/// A real theme is not optional: every component reads `context.tokens`, and the
/// accessor ends in `!` — a bare `MaterialApp` throws a null check on a widget
/// deep in the tree with a message that never mentions tokens.
///
/// [scale] and [boldText] exist because the anchor runs at 200% with Bold Text
/// on. Decision #99 says never clamp, so a 200% user is a real user, and the
/// framework's bold-text merge is exactly what a hand-built `TextStyle` would
/// silently drop.
Future<void> _pumpComponent(
  WidgetTester tester,
  Widget component, {
  double scale = 1.0,
  bool boldText = false,
  ShedPalette palette = nightPalette,
}) => tester.pumpWidget(
  MaterialApp(
    theme: buildShedTheme(palette),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale), boldText: boldText),
      child: Scaffold(body: Center(child: component)),
    ),
  ),
);

String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

ShedPrimaryButton _slab({
  ShedPrimaryButtonState state = ShedPrimaryButtonState.ready,
  String label = '+ LAMB',
}) => ShedPrimaryButton(label: label, onTap: () {}, semanticLabel: 'Add a lamb', state: state);

void main() {
  const String file = 'lib/core/ui/components/shed_primary_button.dart';

  testWidgets('ShedPrimaryButton renders at textScale 2.0 with boldText, has a '
      'semanticLabel, and no dimension below 64', (WidgetTester tester) async {
    // THE ANCHOR, and it runs at the hard end of the range on purpose: 200% text
    // with Bold Text on is where a slab either holds its box or overflows.
    final SemanticsHandle handle = tester.ensureSemantics();

    await _pumpComponent(tester, _slab(), scale: 2.0, boldText: true);

    expect(tester.takeException(), isNull, reason: 'the slab overflowed or threw');

    final Rect rect = tester.getRect(find.byType(ShedPrimaryButton));
    expect(rect.height, greaterThanOrEqualTo(88.0), reason: 'tapHero');
    expect(rect.width, greaterThanOrEqualTo(144.0), reason: '2 x tapPrimary');
    expect(rect.shortestSide, greaterThanOrEqualTo(64.0), reason: "indelible.md §4.5's build box");

    final SemanticsNode node = tester.getSemantics(find.byType(ShedTapTarget));
    expect(node.label, isNotEmpty);

    handle.dispose();
  });

  testWidgets('the slab is one ShedTapTarget and the gates can find it', (
    WidgetTester tester,
  ) async {
    // N33's two sweeps find targets BY TYPE. A control built on a bare InkWell
    // is invisible to every one of them — it would pass this epic and vanish
    // from the geometric gate, silently, forever.
    await _pumpComponent(tester, _slab());
    expect(find.byType(ShedTapTarget), findsOneWidget);
  });

  testWidgets('every ShedPrimaryButtonState exposes SemanticsAction.tap', (
    WidgetTester tester,
  ) async {
    // THE EXECUTABLE FORM OF "NEVER REFUSES A PRESS", including `refusing`
    // itself. indelible.md §7.1: still a target — pressing it opens the tag
    // sheet rather than doing nothing.
    final SemanticsHandle handle = tester.ensureSemantics();

    for (final ShedPrimaryButtonState state in ShedPrimaryButtonState.values) {
      await _pumpComponent(tester, _slab(state: state));
      final SemanticsData data = tester.getSemantics(find.byType(ShedTapTarget)).getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue, reason: '$state');
      expect(data.flagsCollection.isEnabled, Tristate.isTrue, reason: '$state');
    }

    handle.dispose();
  });

  testWidgets('the refusing state changes the label and the outline, never the '
      'enabled flag', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await _pumpComponent(tester, _slab(label: '+ LAMB'));
    final Rect ready = tester.getRect(find.byType(ShedPrimaryButton));

    await _pumpComponent(tester, _slab(state: ShedPrimaryButtonState.refusing, label: 'TAG FIRST'));

    final SemanticsData data = tester.getSemantics(find.byType(ShedTapTarget)).getSemanticsData();
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    expect(find.text('TAG FIRST'), findsOneWidget);
    expect(find.text('+ LAMB'), findsNothing);

    // Same box. The state changes the verb and the outline, not the geometry —
    // a slab that resized as it refused would move under a thumb already in
    // flight.
    expect(tester.getRect(find.byType(ShedPrimaryButton)).size, ready.size);

    handle.dispose();
  });

  testWidgets('a press changes fill and nothing else', (WidgetTester tester) async {
    // Catches an AnimatedScale or a Transform added later. indelible.md §5.1: a
    // press is a fill change only — "a target that shrinks under a cold thumb is
    // a target you miss".
    await _pumpComponent(tester, _slab());
    final Rect before = tester.getRect(find.byType(ShedPrimaryButton));

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(ShedPrimaryButton)),
    );
    await tester.pump(const Duration(milliseconds: 40));

    expect(tester.getRect(find.byType(ShedPrimaryButton)), before);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('the label goes through labelLarge and never a constructed TextStyle', (
    WidgetTester tester,
  ) async {
    // 06 §5.4's silent failure: a fresh TextStyle drops fontFeatures, and the
    // pen board starts jittering as 412 and 108 take different widths.
    late TextStyle expected;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildShedTheme(nightPalette),
        home: Builder(
          builder: (BuildContext context) {
            expected = Theme.of(context).textTheme.labelLarge!;
            return Scaffold(body: Center(child: _slab()));
          },
        ),
      ),
    );

    final Text text = tester.widget<Text>(find.text('+ LAMB'));
    expect(text.style!.fontSize, expected.fontSize);
    expect(text.style!.fontWeight, expected.fontWeight);
    expect(text.style!.fontFamily, expected.fontFamily);
  });

  testWidgets('no dimension shrinks between textScale 1.0, 1.3 and 2.0', (
    WidgetTester tester,
  ) async {
    // A box that shrinks as text grows is the FittedBox bug wearing a different
    // hat.
    Size? previous;
    for (final double scale in <double>[1.0, 1.3, 2.0]) {
      await _pumpComponent(tester, _slab(), scale: scale);
      final Size size = tester.getSize(find.byType(ShedPrimaryButton));
      if (previous != null) {
        expect(size.width, greaterThanOrEqualTo(previous.width), reason: 'scale $scale');
        expect(size.height, greaterThanOrEqualTo(previous.height), reason: 'scale $scale');
      }
      previous = size;
    }
  });

  test('ShedPrimaryButton constructs with no nullable onTap', () {
    // THE NARROWING IS THE FEATURE. ShedTapTarget takes VoidCallback? and sets
    // Semantics(enabled: onTap != null); passing null here would announce a
    // disabled button, make 06 §6.3's geometric gate SKIP it, and leave a
    // shepherd tapping a live-looking rectangle that does nothing.
    final String source = _declarations(file);
    expect(source, contains('required this.onTap'));
    expect(source, contains('final VoidCallback onTap;'));
    expect(source, isNot(contains('VoidCallback?')));
    expect(source, isNot(contains('onTap: null')));
  });

  test('the component file contains no colorScheme, no raw colour and no literal fontSize', () {
    // The gate proves this repo-wide; this case is what tells you WHICH
    // component broke it. The raw-colour needle is split across two adjacent
    // literals so this file does not fire on itself.
    const String rawColour =
        'Color'
        '(0x';
    final String source = _declarations(file);

    expect(source, isNot(contains('colorScheme')));
    expect(source, isNot(contains(rawColour)));
    expect(source, isNot(matches(RegExp(r'fontSize:\s*[0-9]'))));
  });

  test('the file imports no provider, no localisation and nothing under lib/data', () {
    // Layer rule 7 lists what lib/core/ui/ may import, and a component file is
    // where the first violation gets introduced — a widget that reaches for a
    // provider is a widget that cannot be pumped without a ProviderScope.
    final String imports = _declarations(
      file,
    ).split('\n').where((String l) => l.trimLeft().startsWith('import ')).join('\n');

    for (final String forbidden in <String>['riverpod', 'l10n', 'data/', 'drift']) {
      expect(imports, isNot(contains(forbidden)), reason: forbidden);
    }
  });
}

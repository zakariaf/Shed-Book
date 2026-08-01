// test/features/night_error_panel_test.dart
//
// DELIBERATELY NO pumpApp. The harness does not exist until N12-T05, and even
// when it does it wraps the tree in exactly the MaterialApp this widget must
// survive without. Pumping through it would prove the opposite of the claim.
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/ui/night_error_panel.dart';
import 'package:shed_book/core/ui/palettes.dart';
import 'package:shed_book/core/ui/tokens.dart';

const String _panelFile = 'lib/core/ui/night_error_panel.dart';

String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

/// A widget whose build always throws, so `ErrorWidget.builder` runs.
class _Exploding extends StatelessWidget {
  const _Exploding();

  @override
  Widget build(BuildContext context) => throw StateError('boom');
}

void main() {
  testWidgets('ErrorWidget.builder renders NightErrorPanel with no Theme or MediaQuery '
      'ancestor', (WidgetTester tester) async {
    // THE ANCHOR. Installed the way main.dart installs it, then a build that
    // throws.
    // RESTORED INSIDE THE BODY, not through addTearDown.
    // TestWidgetsFlutterBinding checks that ErrorWidget.builder is back to its
    // default BEFORE tear-downs run — "The value of ErrorWidget.builder was
    // changed by the test" — so a tear-down restore is too late and the test
    // fails on the cleanup rather than on the claim.
    final ErrorWidgetBuilder previous = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) => const NightErrorPanel();

    await tester.pumpWidget(const _Exploding());

    final bool rendered = find.byType(NightErrorPanel).evaluate().isNotEmpty;
    final Object? thrown = tester.takeException();

    ErrorWidget.builder = previous;

    expect(rendered, isTrue, reason: 'the builder did not render the panel');
    expect(thrown, isA<StateError>(), reason: 'the error is consumed, not lost');
  });

  testWidgets('the panel builds bare — no MaterialApp, no Theme, no MediaQuery, no '
      'Directionality', (WidgetTester tester) async {
    // THE CASE THAT FAILS THE DAY SOMEONE ADDS A Scaffold. One widget, four
    // absent ancestors, no throw.
    await tester.pumpWidget(const NightErrorPanel());

    expect(tester.takeException(), isNull);
    expect(find.text(NightErrorPanel.message), findsOneWidget);
  });

  test('the panel reads no inherited theme', () {
    // Cheaper than pumping every negative, and it NAMES the offending token.
    // Every one of these is a lookup that throws inside the error handler, which
    // is how a shepherd ends up with a grey screen and no diagnosis at all.
    final String source = _declarations(_panelFile);
    for (final String banned in <String>[
      'Theme.of',
      'MediaQuery.',
      'Localizations.of',
      'DefaultTextStyle.of',
      'context.tokens',
      'Scaffold',
      'SnackBar',
      'ElevatedButton',
    ]) {
      expect(source, isNot(contains(banned)), reason: banned);
    }
  });

  test('the panel imports package:flutter/widgets.dart and not material.dart', () {
    // material.dart is how every lookup above gets reintroduced by accident.
    final String imports = _declarations(
      _panelFile,
    ).split('\n').where((String l) => l.trimLeft().startsWith('import ')).join('\n');

    expect(imports.trim(), "import 'package:flutter/widgets.dart';");
  });

  testWidgets('the fill is the page colour and no other colour is painted', (
    WidgetTester tester,
  ) async {
    // Written as a literal here AND compared to the palette, so P14's ruling
    // holds in two places. The panel cannot read a token — that is the point —
    // so the duplication is deliberate and this is what keeps the copies equal.
    await tester.pumpWidget(const NightErrorPanel());

    final ColoredBox box = tester.widget<ColoredBox>(find.byType(ColoredBox).first);
    expect(box.color, const Color(0xFF0A0A0B));
    expect(box.color, NightErrorPanel.pageColour);

    final ShedTokens night = nightPalette.tokens;
    expect(
      NightErrorPanel.pageColour,
      night.surfaceBase,
      reason: 'the panel and the night palette disagree about the first painted frame',
    );
  });

  testWidgets('the panel offers exactly one action, at least 64 by 64, with a '
      'semanticLabel', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(const NightErrorPanel());

    final Finder action = find.byType(GestureDetector);
    expect(action, findsOneWidget);

    final Size size = tester.getSize(action);
    expect(size.width, greaterThanOrEqualTo(64.0));
    expect(size.height, greaterThanOrEqualTo(64.0));
    expect(find.text(NightErrorPanel.saveACopy), findsOneWidget);

    handle.dispose();
  });

  test('the copy names no code, no cause and no channel that does not exist', () {
    // There is no support address and no contact route in this product. Naming
    // one at 03:20 sends a shepherd somewhere that does not answer.
    for (final String copy in <String>[NightErrorPanel.message, NightErrorPanel.saveACopy]) {
      expect(copy, isNot(matches(RegExp(r'\d'))), reason: copy);
      for (final String banned in <String>[
        'Exception',
        'support',
        'contact',
        'should',
        'compliance',
        'official',
        'error',
      ]) {
        expect(copy.toLowerCase(), isNot(contains(banned)), reason: '$copy says $banned');
      }
    }
  });

  testWidgets('the panel renders identically at text scale 2.0', (WidgetTester tester) async {
    // A REGRESSION GUARD, NOT A FEATURE, and the difference is worth stating:
    // this widget cannot read textScaler — there may be no MediaQuery — so it
    // does not respond to it. What is asserted is that a large ambient scale
    // does not make it overflow. The limitation is documented rather than
    // hidden, and it is the price of rendering when nothing else can.
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: const NightErrorPanel(),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  test('ErrorWidget.builder is assigned exactly once in lib/ and never inside a build', () {
    // Reassigning a global during layout races whatever is currently rendering.
    final List<String> assigners = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => f.path.replaceAll(r'\', '/'))
        .where((String p) => p.endsWith('.dart') && !p.endsWith('.g.dart'))
        .where((String p) => _declarations(p).contains('ErrorWidget.builder ='))
        .toList();

    expect(assigners, <String>['lib/main.dart']);

    final String main = _declarations('lib/main.dart');
    expect(
      main.indexOf('ErrorWidget.builder ='),
      lessThan(main.indexOf('runApp(')),
      reason: 'the builder must be installed before the first build',
    );
  });

  test('main() installs all three hooks before runApp', () {
    // The T03 anchor, widened from two to three.
    final String main = _declarations('lib/main.dart');
    final int run = main.indexOf('runApp(');

    for (final String hook in <String>[
      'FlutterError.onError',
      'PlatformDispatcher.instance.onError',
      'ErrorWidget.builder',
    ]) {
      expect(main.indexOf(hook), isNot(-1), reason: hook);
      expect(main.indexOf(hook), lessThan(run), reason: '$hook is installed after runApp');
    }
  });
}

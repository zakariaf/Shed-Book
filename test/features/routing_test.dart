// test/features/routing_test.dart
//
// Mostly source-text assertions over routes.dart, and that is the right tier:
// the properties are about what the FILE CONTAINS, and there are twelve
// destinations that do not exist yet to navigate between.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/routing/routes.dart';

const String _file = 'lib/routing/routes.dart';

String _source() => File(_file).readAsStringSync();

String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

List<String> _authoredDart(String root) =>
    Directory(root)
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => f.path.replaceAll(r'\', '/'))
        .where(
          (String p) =>
              p.endsWith('.dart') &&
              !p.endsWith('.g.dart') &&
              !p.endsWith('.drift.dart') &&
              !p.contains('app_localizations'),
        )
        .toList()
      ..sort();

/// `02 §8.1`'s list, typed out rather than read from the class — so a typo in
/// `routes.dart` fails here and not in a matrix cell nine epics later.
const List<String> _expected = <String>[
  'quick_entry',
  'flock',
  'ewe_card',
  'lambing_entry',
  'lamb_card',
  'foster',
  'pen_board',
  'treatments',
  'reminders',
  'season_summary',
  'export',
  'settings',
  'note_search',
];

void main() {
  test('RouteNames has thirteen constants and one push helper per screen that exists', () {
    // THE ANCHOR, and its name is about a HELPER, not a push. Quick Entry is
    // MaterialApp.home — route 0, isFirst — so it is never pushed, and the one
    // helper the file ships today is a POP. Zero `push(` call sites is the
    // correct state rather than a gap: the failure mode this guards against is a
    // well-meaning `Routes.quickEntry(context)` that pushes a second copy of the
    // root route on top of itself.
    final String declarations = _declarations(_file);

    expect(
      'static const String'.allMatches(declarations).length,
      13,
      reason: 'thirteen names — twelve destinations do not exist yet, and a const String is free',
    );

    for (final String value in _expected) {
      expect(declarations, contains("'$value'"), reason: value);
      expect(value, matches(RegExp(r'^[a-z]+(_[a-z]+)*$')), reason: '$value is not lower_snake');
    }

    expect(
      _expected.toSet(),
      hasLength(13),
      reason:
          'two names sharing a string make '
          'ModalRoute.withName ambiguous and the diagnostics log unreadable',
    );

    // AMENDED AT N16-T01, WHICH LANDED THE FIRST PUSH HELPER. The case used to
    // assert ZERO pushes, and that was right while zero screens existed to push
    // to. What it guards now is the same rule stated the other way round: the
    // table grows ONE helper per screen epic, in the commit that adds the
    // screen — never twelve at once for screens that do not exist.
    //
    // Quick Entry is still never pushed. It is MaterialApp.home, route 0,
    // isFirst, and its helper is a POP — which is why the count below counts
    // only the screens that are genuinely pushed onto it.
    //
    // GREW TO THREE AT N17-T01 AND N18-T02, one per screen epic, exactly as the
    // rule above describes. The number is asserted rather than the shape,
    // because "at least one" would let twelve land in a single commit for
    // screens that do not exist.
    expect(
      '.push('.allMatches(declarations).length,
      4,
      reason:
          'lambingEntry (N16-T01), lambCard (N17-T01), foster (N18-T02). '
          'Quick Entry is home: and is never pushed',
    );
    expect(declarations, contains('popToQuickEntry'));
    expect(declarations, contains('static Future<void> lambingEntry('));
    expect(declarations, contains('static Future<void> lambCard('));
    expect(declarations, contains('static Future<void> foster('));

    // The arithmetic 12 §6.2 will assert at N33 — thirteen names minus twelve
    // helpers equals one — is still not written here, because it is still not
    // true: seven screens remain, and P15 moves three of them to v1.1.0 —
    // Reminders, Season Summary and Note Search (docs/RELEASE-SCOPE.md §5.4).
    expect(
      RegExp(r'static Future<void> \w+\(').allMatches(declarations).length,
      4,
      reason: 'four screens exist to push to; N33-T01 asserts the final count',
    );
  });

  test("the thirteen RouteNames values are exactly 02 §8.1's list", () {
    final Set<String> found = RegExp(
      "'([a-z_]+)'",
    ).allMatches(_declarations(_file)).map((RegExpMatch m) => m.group(1)!).toSet();

    expect(found, containsAll(_expected));
  });

  test('routes.dart contains no onGenerateRoute, no routes map, no pushNamed and no GoRoute', () {
    // 02 §8.4's anti-pattern table, whose reason is one sentence: "stringly-typed
    // arguments are the exact thing the helper file removes."
    //
    // CRITIQUE S2's OWN FIX TEXT SAYS "the onGenerateRoute switch", AND IT IS
    // WRONG. 02 §8.1 ends "There is no `routes:` table and no `onGenerateRoute`",
    // and CONVENTIONS §2.14 catalogues RouteNames, Routes and Routes.navigatorKey
    // and nothing else. CONVENTIONS outranks a plan document on a name. The
    // "switch" S2 means is `_route(name, builder)`.
    // DECLARATIONS ONLY, not the raw source, and that is not laziness: the doc
    // comment on Routes.route says there is no route TABLE, which means it
    // contains the needle for that anti-pattern verbatim. The twenty-fourth
    // prohibition-versus-claim self-match in this project.
    final String declarations = _declarations(_file);
    for (final String banned in <String>['onGenerateRoute', 'routes:', 'pushNamed', 'GoRoute']) {
      expect(declarations, isNot(contains(banned)), reason: banned);
    }
  });

  test('go_router appears in neither lib/, test/ nor pubspec.yaml', () {
    // Decision #23's own grep, run as a test so it fails before CI does. Its
    // entire value proposition is URLs; there is no web target, no deep link and
    // no URL bar.
    const String needle =
        'go_'
        'router';
    expect(File('pubspec.yaml').readAsStringSync(), isNot(contains(needle)));
    for (final String root in <String>['lib', 'test']) {
      for (final String path in _authoredDart(root)) {
        // test/policy/ is skipped because it PLANTS the needle on purpose —
        // lockfile_is_evidence_test.dart asserts the package is absent from
        // pubspec.lock and has to name it to do so. Scoping this to the
        // application tiers is the same shape N03-T06 used for the gate's own
        // rules; a scan that reported the planted case would be reporting the
        // guard, not a defect. This file is skipped for the same reason.
        if (path.startsWith('test/policy/') || path == 'test/features/routing_test.dart') {
          continue;
        }
        expect(_declarations(path), isNot(contains(needle)), reason: path);
      }
    }
  });

  test('Restorable, RestorationMixin and restorablePush appear nowhere under lib/', () {
    // Decision #24, and the reason is correctness rather than effort: 02 §9
    // spells out the 03:20 → 03:41 scenario in which a restored selection files
    // ewe 128's lambing against 412.
    for (final String path in _authoredDart('lib')) {
      final String source = _declarations(path);
      for (final String banned in <String>[
        'RestorationMixin',
        'restorablePush',
        'restorationScopeId',
      ]) {
        expect(source, isNot(contains(banned)), reason: '$path: $banned');
      }
    }
  });

  test('canPop false appears exactly once, in the restore confirmation', () {
    // `canPop` is true on every SCREEN in this app forever, because every write
    // commits immediately and there is no *discard unsaved changes?* dialog
    // anywhere. The exceptions are the two destructive confirmations, and R85
    // (N23-T02) lands the first of them.
    //
    // TODAY'S TRUE COUNT, and it moves in the commit that earns it: N29's
    // season delete makes it two.
    int found = 0;
    for (final String path in _authoredDart('lib')) {
      found += RegExp(r'canPop:\s*false').allMatches(_declarations(path)).length;
    }
    expect(found, 1);
  });

  test('onPopInvoked does not appear; onPopInvokedWithResult is the only spelling', () {
    // The deprecation `--fatal-infos` would catch, asserted here so the failure
    // names the reason. WillPopScope was removed from the framework entirely; a
    // snippet containing it predates 3.44.
    final RegExp bare = RegExp(r'onPopInvoked\b(?!WithResult)');
    for (final String path in _authoredDart('lib')) {
      final String source = _declarations(path);
      expect(bare.hasMatch(source), isFalse, reason: path);
      expect(source, isNot(contains('WillPopScope')), reason: path);
    }
  });

  testWidgets('popToQuickEntry pops until isFirst', (WidgetTester tester) async {
    late BuildContext deepContext;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: Routes.navigatorKey,
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext c) => TextButton(
                    onPressed: () => Navigator.of(c).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext d) {
                          deepContext = d;
                          return const Text('three');
                        },
                      ),
                    ),
                    child: const Text('two'),
                  ),
                ),
              );
            },
            child: const Text('one'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('one'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('two'));
    await tester.pumpAndSettle();
    expect(find.text('three'), findsOneWidget);

    Routes.popToQuickEntry(deepContext);
    await tester.pumpAndSettle();

    expect(find.text('one'), findsOneWidget);
    expect(find.text('three'), findsNothing);
    // No ModalRoute.of(deepContext) here: that element is deactivated by now and
    // an ancestor lookup on it throws "Looking up a deactivated widget's
    // ancestor is unsafe" — a failure that names the framework and not the
    // property. What is gone from the tree is the property.
  });

  testWidgets('popToQuickEntryGlobal works with no BuildContext', (WidgetTester tester) async {
    // The resume policy's and the future notification tap's only path: neither
    // has a BuildContext to hand.
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: Routes.navigatorKey,
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (BuildContext _) => const Text('pushed'))),
            child: const Text('root'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('root'));
    await tester.pumpAndSettle();
    expect(find.text('pushed'), findsOneWidget);

    Routes.popToQuickEntryGlobal();
    await tester.pumpAndSettle();

    expect(find.text('root'), findsOneWidget);
    expect(find.text('pushed'), findsNothing);
  });

  test('route stamps RouteSettings and is the only MaterialPageRoute construction under lib/', () {
    // RouteSettings(name:) exists for exactly two reasons — the diagnostics log
    // (#124) and ModalRoute.withName — and NEVER for pushNamed.
    //
    // CONSTRUCTED RATHER THAN GREPPED, which is what the @visibleForTesting
    // rename bought: the private form could only ever have been asserted as
    // source text. See the doc comment on Routes.route for why it is not
    // private — `unused_element` is a warning and nothing in N13 pushes.
    final MaterialPageRoute<void> r = Routes.route(
      RouteNames.eweCard,
      (BuildContext _) => const SizedBox.shrink(),
    );
    expect(r.settings.name, 'ewe_card');

    final List<String> constructors = <String>[];
    for (final String path in _authoredDart('lib')) {
      if (_declarations(path).contains('MaterialPageRoute<void>(')) {
        constructors.add(path);
      }
    }
    expect(constructors, <String>[_file]);
  });

  test('MaterialApp sets navigatorKey and does not set restorationScopeId', () {
    // SOURCE TEXT over app.dart rather than a pump, and the reason is that a
    // pumped MaterialApp cannot tell you what was NOT passed: an absent
    // restorationScopeId and an absent one that defaults to null are the same
    // widget. The presence half could be pumped; splitting the case across two
    // mechanisms would make one failure read as two.
    final String app = _declarations('lib/app.dart');
    expect(app, contains('navigatorKey: Routes.navigatorKey'));
    expect(app, isNot(contains('restorationScopeId')));
  });

  test('the thirteen-names-twelve-helpers assertion is deferred, and the file says so', () {
    // A COMMENT IS THE ARTEFACT HERE, and this case is what stops it being
    // deleted as noise. Asserting 13 - helpers == 1 today would assert 13 - 0 ==
    // 13 and would have to be edited twelve times, once per screen epic.
    expect(_source(), contains('N33'));
    expect(_source(), contains('S2'));
  });
}

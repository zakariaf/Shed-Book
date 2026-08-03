// test/policy/main_awaits_nothing_test.dart
//
// A source-text test, and 12 §11.1 asks for exactly that: the property is about
// the FILE, not about what the file does at runtime. No pumpWidget, no binding,
// no database — running main() in a test would install the real handlers.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _mainFile = 'lib/main.dart';

final String _source = File(_mainFile).readAsStringSync();

/// [_source] with whole-line comments removed.
final String _declarations = File(
  _mainFile,
).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

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

void main() {
  test('main() contains no await and installs both handlers before runApp', () {
    // THE ANCHOR. An `await` before runApp is a frame the shepherd spends
    // looking at the platform's launch colour, and every candidate for one —
    // opening the database, resolving a directory, reading settings — belongs
    // after the first frame.
    expect('void main()'.allMatches(_declarations).length, 1);
    expect(_declarations, isNot(contains('Future<void> main')));
    expect(_declarations, isNot(contains('main() async')));
    expect(_declarations, isNot(contains('await ')));

    // ORDER MATTERS: a handler installed after runApp misses every error thrown
    // while the first frame builds — which is exactly when a bootstrap failure
    // happens.
    final int flutterError = _declarations.indexOf('FlutterError.onError');
    final int dispatcher = _declarations.indexOf('PlatformDispatcher.instance.onError');
    final int run = _declarations.indexOf('runApp(');

    expect(flutterError, isNot(-1));
    expect(dispatcher, isNot(-1));
    expect(flutterError, lessThan(run));
    expect(dispatcher, lessThan(run));
  });

  test('main.dart contains no banned bootstrap call', () {
    // One assertion per token, so the failure names which one. The last two are
    // SPLIT across adjacent literals: the last one is itself a gate row (rp3.retry —
    // Riverpod 3 only, and 2.6.1 has no auto-retry), and this file is scanned,
    // so a list containing it verbatim fires the rule it is checking for.
    for (final String banned in <String>[
      'runZonedGuarded',
      'deferFirstFrame',
      'flutter_native_splash',
      'exit(',
      'over'
          'rides:',
      're'
          'try:',
    ]) {
      expect(_declarations, isNot(contains(banned)), reason: banned);
    }
  });

  test('PlatformDispatcher.instance.onError returns true', () {
    // The difference is whether the process survives. Returning false lets it
    // die with a lamb half-recorded; the record is already committed and the
    // shepherd needs the screen back, not a crash.
    expect(_declarations, contains('return true;'));
    expect(_declarations, isNot(contains('return false;')));
  });

  test('runApp receives a const ProviderScope and nothing else', () {
    // Matched as a whole, which catches three regressions at once: a lost
    // `const`, an added `overrides:`, and a second child.
    expect(_declarations, contains('runApp(const ProviderScope(child: ShedBookApp()));'));
  });

  test('main.dart imports nothing from lib/core/db/, drift or sqlite3', () {
    // layer.root as a test as well as a gate row, because this is the file
    // somebody will "just open the database in" — and opening it here is an
    // await, which is the frame this whole task exists to protect.
    final String imports = _declarations
        .split('\n')
        .where((String l) => l.trimLeft().startsWith('import '))
        .join('\n');

    for (final String forbidden in <String>['core/db/', 'drift', 'sqlite3', 'path_provider']) {
      expect(imports, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test('main.dart names no store or purchase symbol', () {
    // launch.store_call, decision #90. Nothing monetization-related may run
    // before the first frame — or on any of the five shed screens, at any
    // entitlement state.
    for (final String banned in <String>[
      'PurchaseService',
      'purchase_service.dart',
      'InAppPurchase',
      'in_app_purchase',
    ]) {
      expect(_source, isNot(contains(banned)), reason: banned);
    }
  });

  test('LocalLog.instance is the only non-SDK static instance in lib/', () {
    // 02's Definition of Done asks for this property; here is where it is first
    // true. R52 allows exactly one static-field singleton, and the reason is
    // narrow: the error handlers run before any ProviderScope exists and must
    // still work when the container has been torn down by the failure being
    // logged.
    const List<String> allowed = <String>[
      'LocalLog.instance',
      'WidgetsBinding.instance',
      'PlatformDispatcher.instance',
      'ServicesBinding.instance',
      // A PLUGIN'S OWN SINGLETON, not one of ours, and it reaches exactly one
      // file: `share_plus`'s current API is `SharePlus.instance.share(...)` and
      // the static `Share.*` form it replaced is deprecated and takes no
      // `sharePositionOrigin` (#80). R52 is about singletons WE declare — the
      // rule exists because our own statics survive a torn-down container; a
      // package's entry point is not that.
      //
      // Confined rather than allowed everywhere: `layer.plugin_share_plus`
      // already refuses the import outside `lib/data/share_service.dart`, so
      // this name cannot appear in a second file even if this list forgot to
      // say so. (N21-T06)
      'SharePlus.instance',
    ];

    for (final String path in _authoredDart('lib')) {
      final String source = File(
        path,
      ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

      for (final RegExpMatch m in RegExp(r'(\w+)\.instance\b').allMatches(source)) {
        expect(
          allowed,
          contains(m.group(0)),
          reason: '$path uses ${m.group(0)} — R52 allows one static singleton',
        );
      }
    }
  });

  test('the file is under 30 lines of body', () {
    // NOT A STYLE RULE. 01 §6.1 says twenty lines of body and 00-README §10 puts
    // this file on the never-waved-through list. A number here makes growth
    // visible in a diff rather than gradual — every line added to main() is a
    // line that runs before the first frame.
    final int body = File(_mainFile)
        .readAsLinesSync()
        .where((String l) => l.trim().isNotEmpty && !l.trimLeft().startsWith('//'))
        .length;

    expect(body, lessThan(30), reason: 'main.dart has grown to $body lines');
  });
}

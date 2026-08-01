// test/policy/one_failure_mapping_site_test.dart
//
// One mapping site, held as a set rather than as a rule. The value of this file
// is its failure message: it names the file that JOINED, which a gate row
// scoped to a directory cannot.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Generated output and the committed gen-l10n files are not authored, so they
/// are not held to authored-code rules.
bool _isAuthored(String path) =>
    !path.endsWith('.g.dart') &&
    !path.endsWith('.drift.dart') &&
    !path.contains('app_localizations');

List<String> _dartFiles() => <String>[
  for (final String root in <String>['lib', 'test'])
    ...Directory(root)
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => f.path.replaceAll(r'\', '/'))
        .where((String p) => p.endsWith('.dart') && _isAuthored(p)),
]..sort();

String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

void main() {
  test('no file under lib/ but the mapping site names a driver exception, and '
      'shedFailureFrom is declared once', () {
    // Needles split across adjacent literals so this file does not appear in its
    // own result set — the failure mode every source-text test in this project
    // has hit at least once.
    const String sqliteType =
        'Sqlite'
        'Exception';
    const String driftType =
        'DriftRemote'
        'Exception';

    // SCOPED TO lib/, AND THE TASK FILE IS WRONG TO SAY "EXACTLY TWO FILES".
    //
    // MEASURED: five of N07's schema tests already name the type —
    // schema_flock, schema_lambing, schema_pens_treatments, schema_ancillary and
    // tag_uniqueness — and they are RIGHT to. A test that asserts a CHECK
    // constraint or a partial unique index actually fired has to name the
    // exception it caught; that is the assertion, not a leak.
    //
    // What matters is PRODUCTION code: nothing under lib/ outside the mapping
    // site may know what the driver throws, because every such place is a place
    // that classifies it differently. Narrowing the scope is what makes this
    // rule true and keeps it worth enforcing.
    final List<String> namers = _dartFiles().where((String p) => p.startsWith('lib/')).where((
      String p,
    ) {
      final String source = _declarations(p);
      return source.contains(sqliteType) || source.contains(driftType);
    }).toList();

    expect(namers, <String>[
      'lib/data/failure_mapping.dart',
    ], reason: 'a second file under lib/ now knows what the driver throws');

    // And the function itself exists once.
    // Split, like the two above: without it this file declares the function as
    // far as a substring search is concerned.
    const String declaration =
        'ShedFailure shed'
        'FailureFrom(';
    final List<String> declarers = _dartFiles()
        .where((String p) => _declarations(p).contains(declaration))
        .toList();
    expect(declarers, <String>['lib/data/failure_mapping.dart']);
  });

  test('no file outside the mapping site catches a driver exception by type', () {
    // The rule that actually bites: `on SqliteException catch (e)` never matches
    // in production, because drift_flutter wraps the original in a
    // DriftRemoteException on a background isolate. A catch clause written that
    // way passes every test and classifies nothing on a phone.
    const String clause =
        'on Sqlite'
        'Exception';

    for (final String path in _dartFiles()) {
      if (path == 'lib/data/failure_mapping.dart') {
        continue;
      }
      expect(_declarations(path), isNot(contains(clause)), reason: path);
    }
  });
}

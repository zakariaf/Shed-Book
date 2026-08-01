// test/policy/gate_rules_test.dart — the one file every rule in tool/check_policy.dart
// is proved in. 00-README §9 step 1: a rule nobody has seen fire is
// indistinguishable from a broken rule, so a row and the case that watches it
// fire land in the same commit — always.
//
// Every planted violation lives in a **temp tree**, never as a literal in this
// file. `test/` is a scanned root, so a banned literal written here would trip
// the gate on the gate's own proving test.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ignore: always_use_package_imports
import '../../tool/check_policy.dart';

/// The smallest allowlist the gate will accept: four sections, no entries.
const String _emptyAllowlist = '''
[dependencies]
[dev_dependencies]
[transitive]
[exempt]
''';

/// Writes [files] into a throwaway tree, runs the gate over it, returns the
/// violations. The planted text lives in the temp tree, never in this file.
List<String> gateOn(Map<String, String> files, {String allowlist = _emptyAllowlist}) {
  final Directory temp = _tree(files, allowlist: allowlist);
  try {
    return runPolicy(root: temp.path);
  } finally {
    temp.deleteSync(recursive: true);
  }
}

/// The same tree, handed back unrun — for the cases that read the allowlist
/// directly or assert on the walk.
Directory _tree(Map<String, String> files, {String? allowlist}) {
  final Directory temp = Directory.systemTemp.createTempSync('shed_gate_');
  if (allowlist != null) {
    _write(temp, 'tool/policy_allowlist.txt', allowlist);
  }
  files.forEach((String path, String content) => _write(temp, path, content));
  return temp;
}

void _write(Directory root, String path, String content) {
  final File file = File('${root.path}/$path');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

/// A literal a later rule will ban, assembled from halves so this file never
/// contains it whole. `time.dart_clock` bans it under `lib/` from N03-T06.
final String _willBeBanned =
    'DateTime'
    '.now()';

void main() {
  test('check_policy exits 0 on a clean tree and skips every generated file', () {
    // One ordinary file, plus one of each of 00-README §7.3's four generated
    // shapes — three of which are not *.g.dart and are not skipped by the
    // driver as 01 §3.2 prints it. Every generated one carries a literal a
    // later rule bans.
    final List<String> violations = gateOn(<String, String>{
      'lib/main.dart': 'void main() {}\n',
      'lib/core/db/database.g.dart': 'final x = $_willBeBanned;\n',
      'lib/core/db/search.drift.dart': 'final x = $_willBeBanned;\n',
      'lib/l10n/app_localizations_en.dart': 'final x = $_willBeBanned;\n',
      'test/drift/generated/schema_v1.dart': 'final x = $_willBeBanned;\n',
    });
    expect(violations, isEmpty);
  });

  test('a missing allowlist file is exit 2, not exit 0', () {
    final Directory temp = _tree(<String, String>{'lib/main.dart': 'void main() {}\n'});
    addTearDown(() => temp.deleteSync(recursive: true));
    expect(
      () => runPolicy(root: temp.path),
      throwsA(
        isA<PolicyConfigProblem>().having(
          (PolicyConfigProblem p) => p.message,
          'message',
          contains('tool/policy_allowlist.txt'),
        ),
      ),
      reason: 'a gate that cannot read its own configuration has failed to run, not passed',
    );
  });

  test('an allowlist line outside any section is refused with its line number', () {
    expect(
      () => gateOn(const <String, String>{}, allowlist: 'drift\n[dependencies]\n'),
      throwsA(
        isA<PolicyConfigProblem>().having(
          (PolicyConfigProblem p) => p.message,
          'message',
          allOf(contains('line 1'), contains('drift')),
        ),
      ),
      reason: "01 §3.2's parser swallows this line with a null-aware call on an absent map entry",
    );
  });

  test('an unknown section header is refused', () {
    expect(
      () => gateOn(const <String, String>{}, allowlist: '[deps]\ndrift\n'),
      throwsA(
        isA<PolicyConfigProblem>().having(
          (PolicyConfigProblem p) => p.message,
          'message',
          allOf(contains('line 1'), contains('deps')),
        ),
      ),
      reason: '[deps] for [dependencies] would empty an entire allowlist section silently',
    );
  });

  test('an exempt line with no :: separator is refused', () {
    expect(
      () => gateOn(
        const <String, String>{},
        allowlist: '$_emptyAllowlist lib/core/time/app_clock.dart time.dart_clock\n',
      ),
      throwsA(
        isA<PolicyConfigProblem>().having(
          (PolicyConfigProblem p) => p.message,
          'message',
          contains('::'),
        ),
      ),
    );
  });

  test('a column-aligned exempt line matches the driver lookup key', () {
    final Directory temp = _tree(
      const <String, String>{},
      allowlist:
          '$_emptyAllowlist'
          'lib/core/time/app_clock.dart       ::   time.dart_clock\n',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    expect(
      readAllowlist(temp.path)['exempt'],
      contains('lib/core/time/app_clock.dart :: time.dart_clock'),
      reason:
          '01 §3.2 prints the file padded for readability and looks it up unpadded; '
          'storing the raw line makes every exemption ever written silently inert',
    );
  });

  test('comments and blank lines are ignored, and # ends a line', () {
    final Directory temp = _tree(
      const <String, String>{},
      allowlist: '''
# a whole-line comment
[dependencies]

drift            # the only generator
[dev_dependencies]
[transitive]
http             # via timezone AND via package_info_plus. Two regular edges.
[exempt]
''',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    final Map<String, Set<String>> allow = readAllowlist(temp.path);
    expect(allow['dependencies'], equals(<String>{'drift'}));
    expect(allow['transitive'], equals(<String>{'http'}));
    expect(allow['dev_dependencies'], isEmpty);
  });

  test('the walk is not affected by filesystem order', () {
    // Two trees holding the same files, created in opposite order. The gate
    // sorts before it reports, so the answer must not depend on the order the
    // filesystem hands them back — which differs between macOS and the runner.
    const List<String> paths = <String>[
      'lib/zebra.dart',
      'lib/core/alpha.dart',
      'test/policy/mid.dart',
    ];
    List<String> walk(Iterable<String> order) {
      final Directory temp = _tree(<String, String>{
        for (final String p in order) p: 'void main() {}\n',
      }, allowlist: _emptyAllowlist);
      addTearDown(() => temp.deleteSync(recursive: true));
      return scannedFiles(temp.path);
    }

    expect(walk(paths), equals(walk(paths.reversed)));
    expect(walk(paths), orderedEquals(<String>[...paths]..sort()));
  });

  test('policyRuleIds is empty in this commit', () {
    // The inventory hook exists and is honest. N03-T07 turns it into an
    // assertion with teeth: every id here has a case in this file.
    expect(policyRuleIds, isEmpty);
  });
}

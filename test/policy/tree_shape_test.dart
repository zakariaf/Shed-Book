// The tree IS `CONVENTIONS §1.1`'s eight layer rules made visible: every
// directory here is one the gate will later police the imports of, and a
// directory invented outside §1 is a layer rule with no rule id.
//
// This is a `test/policy/` artefact test and not a `tool/check_policy.dart`
// rule, deliberately. `12 §1.4`'s rule — *if the assertion can be made by
// reading source text, it belongs in the gate* — is about source under `lib/`
// and `test/`, which is the only thing the gate walks. `.gitignore` and the
// directory tree are outside that walk, so they are §1.4's second bullet:
// behaviour and artefacts are tests.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every leaf `CONVENTIONS §1`'s `mkdir -p` block creates, expanded.
const List<String> requiredDirectories = <String>[
  'lib/l10n',
  'lib/domain/time',
  'lib/domain/units',
  'lib/domain/withdrawal',
  'lib/domain/stats',
  'lib/domain/validation',
  'lib/domain/terminology',
  'lib/domain/policy',
  'lib/core/db/tables',
  'lib/core/db/seed',
  'lib/core/time',
  'lib/core/log',
  'lib/core/ui/components',
  'lib/data',
  'lib/routing',
  'lib/features/quick_entry/widgets',
  'lib/features/flock/widgets',
  'lib/features/lambing/widgets',
  'lib/features/pens/widgets',
  'lib/features/treatments/widgets',
  'lib/features/reminders/widgets',
  'lib/features/season/widgets',
  'lib/features/export/widgets',
  'lib/features/settings/widgets',
  'tool',
  'drift_schemas',
  'assets/fonts',
  'assets/content',
  'test/domain/uk_zone',
  'test/data',
  'test/drift/generated',
  'test/design',
  'test/features',
  'test/policy',
  'test/support',
  'test/fixtures',
  'integration_test',
];

/// R57 and `12 §4.2`. Each is banned because its content already has a home.
const Map<String, String> bannedTestDirectories = <String, String>{
  'test/screens': 'test/features/ — the widget tier mirrors lib/features/',
  'test/integration':
      'integration_test/ at the top level — the directory name the SDK package requires',
  'test/ui': 'test/design/ for tokens and contrast, test/features/ for widgets',
  'test/fakes':
      'test/support/ — the seven hand-written fakes live beside harness.dart',
  'test/golden':
      'test/features/goldens/*.png, beside the widget tests that produce them',
};

/// `00-README §7.1`. Every one of these looks like build output and every one
/// must survive a fresh clone. The schema snapshots are the only loss §7.1
/// calls **unrecoverable** — they are the migration tests' one baseline and
/// there is no server-side copy of anybody's phone.
const List<String> mustNeverBeIgnored = <String>[
  'pubspec.lock',
  '.fvmrc',
  'Makefile',
  'analysis_options.yaml',
  'build.yaml',
  'l10n.yaml',
  'dart_test.yaml',
  'drift_schemas/drift_schema_v1.json',
  'lib/core/db/database.g.dart',
  'lib/core/db/schema_versions.dart',
  'lib/l10n/app_localizations.dart',
  'test/drift/generated/schema_v1.dart',
  'test/features/goldens/quick_entry.png',
  'test/fixtures/flock_400_3seasons.json',
  'tool/policy_allowlist.txt',
  'android/expected_permissions.txt',
  'ios/Runner/PrivacyInfo.xcprivacy',
];

/// The other direction. `.fvm/` is ignored and `.fvmrc` is committed — they
/// differ by one character and the failure is silent both ways.
const List<String> mustBeIgnored = <String>[
  'android/key.properties',
  'android/upload.jks',
  '.fvm/flutter_sdk',
  'build/app',
  '.dart_tool/package_config.json',
  'coverage/lcov.info',
  'symbols-archive/x',
];

/// `git check-ignore` exits 0 when a path is ignored and 1 when it is not. It
/// works on paths that do not exist yet, and it answers for **every**
/// `.gitignore` in the repository — `flutter create` also wrote
/// `android/.gitignore` and `ios/.gitignore`, so a test that reads the text of
/// the root file alone is testing one of three files.
bool isGitIgnored(String path) =>
    Process.runSync('git', <String>['check-ignore', path]).exitCode == 0;

void main() {
  test('every directory in CONVENTIONS §1 exists and none of the five banned '
      'test directories does', () {
    // Both directions in one case, because a test that only checks presence
    // passes on a tree that also has test/screens/.
    final List<String> missing = requiredDirectories
        .where((String d) => !Directory(d).existsSync())
        .toList();
    expect(missing, isEmpty, reason: 'missing from CONVENTIONS §1\'s tree');

    final List<String> present = bannedTestDirectories.keys
        .where((String d) => Directory(d).existsSync())
        .map((String d) => '$d (its content belongs in ${bannedTestDirectories[d]})')
        .toList();
    expect(present, isEmpty, reason: 'banned by R57');
  });

  test('every leaf directory that holds no Dart file holds a .gitkeep', () {
    // git tracks files, not directories. Without these a fresh clone
    // reproduces lib/, test/ and four others and none of the twenty-odd
    // leaves — and the anchor passes locally and fails on CI.
    final List<String> unreproducible = <String>[];
    for (final String path in requiredDirectories) {
      final Directory directory = Directory(path);
      if (!directory.existsSync()) {
        continue;
      }
      final List<FileSystemEntity> entries = directory.listSync();
      final bool holdsAFile = entries.whereType<File>().isNotEmpty;
      if (!holdsAFile) {
        unreproducible.add(path);
      }
    }
    expect(unreproducible, isEmpty,
        reason: 'these directories hold no file at all, so a clone will not '
            'reproduce them');
  });

  test('no path 00-README §7.1 requires committed is git-ignored', () {
    // The unrecoverable-loss case, and the more valuable half of this file.
    // An ignore line for any directory named `generated` reads as tidy and
    // silently drops test/drift/generated; `*localizations*` drops the
    // committed gen-l10n output; a bare `*.json` drops drift_schemas AND
    // test/fixtures. Every one is invisible until somebody clones.
    final List<String> ignored =
        mustNeverBeIgnored.where(isGitIgnored).toList();
    expect(ignored, isEmpty,
        reason: 'these are required by 00-README §7.1 to be committed and a '
            '.gitignore is dropping them');
  });

  test('.gitignore refuses the keystore, .fvm, build output, coverage and the '
      'symbols archive', () {
    final List<String> notIgnored =
        mustBeIgnored.where((String p) => !isGitIgnored(p)).toList();
    expect(notIgnored, isEmpty,
        reason: 'these must never be committable. Losing an obfuscation '
            'symbols directory makes every stack trace in every diagnostics '
            'log a user ever sends for that build permanently unreadable — it '
            'is ignored AND kept off the laptop, and the ignore line exists so '
            'nobody solves the second half by committing it');
  });

  test('the flutter create samples are gone', () {
    expect(File('test/widget_test.dart').existsSync(), isFalse);

    final File main = File('lib/main.dart');
    expect(main.existsSync(), isTrue,
        reason: 'flutter build apk --debug needs an entry point');
    final String source = main.readAsStringSync();
    for (final String sample in <String>[
      'MyApp',
      'MyHomePage',
      '_counter',
      'MainApp',
      'Hello World',
    ]) {
      expect(source.contains(sample), isFalse,
          reason: 'lib/main.dart still carries generated sample code: $sample');
    }
  });
}

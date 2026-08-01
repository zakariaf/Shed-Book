// `00-README` §9 lists the ARB as one of exactly two things that run in
// parallel from day one and not at the end. Every string goes through
// `app_en.arb` from the first one, because the cost is ten seconds per string
// now and a full-app sweep later — N33 only **verifies**; there is no epic that
// adds descriptions afterwards.
//
// `build.yaml` freezes something irreversible: `store_date_time_values_as_text`
// must be absent and stay absent. Setting it forces one storage representation
// onto instants and civil dates, which are different kinds (#29), and it
// becomes permanent at the first snapshot in N07.
@Tags(<String>['policy'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _buildYaml = 'build.yaml';
const String _l10nYaml = 'l10n.yaml';
const String _arb = 'lib/l10n/app_en.arb';
const String _generated = 'lib/l10n/app_localizations.dart';
const String _generatedEn = 'lib/l10n/app_localizations_en.dart';

/// The default English labels behind `AnimalClass`'s seven stable keys. A
/// domain noun never appears literally inside an ARB message — it arrives as a
/// `{term}` placeholder fed by `terminologyProvider` (10 §8.5). These words
/// vary by county, let alone by country.
const List<String> animalNouns = <String>[
  'ewe',
  'gimmer',
  'theave',
  'shearling',
  'hogget',
  'tup',
  'ram',
  'wether',
  'lamb',
];

/// `plural` is an ICU keyword; a placeholder that shadows it parses today and
/// stops parsing on the next gen-l10n release.
const List<String> bannedPlaceholderNames = <String>['singular', 'plural'];

void main() {
  final List<String> build = File(_buildYaml).existsSync()
      ? File(_buildYaml).readAsLinesSync()
      : <String>[];
  final List<String> l10n = File(_l10nYaml).existsSync()
      ? File(_l10nYaml).readAsLinesSync()
      : <String>[];

  bool declaresIn(List<String> lines, String needle) => lines.any((String l) {
    final String trimmed = l.trimLeft();
    return !trimmed.startsWith('#') && trimmed.contains(needle);
  });

  Map<String, dynamic> readArb() {
    final Object? parsed = jsonDecode(File(_arb).readAsStringSync());
    expect(parsed, isA<Map<String, dynamic>>());
    return parsed! as Map<String, dynamic>;
  }

  test('app_en.arb exists, every key has a description, and the generated '
      'app_localizations.dart is committed', () {
    expect(File(_arb).existsSync(), isTrue, reason: '$_arb does not exist');

    final Map<String, dynamic> arb = readArb();
    final List<String> messageIds = arb.keys.where((String k) => !k.startsWith('@')).toList();
    expect(messageIds, isNotEmpty, reason: 'the ARB carries no message');

    for (final String id in messageIds) {
      final Object? meta = arb['@$id'];
      expect(meta, isA<Map<String, dynamic>>(), reason: '$id has no @-metadata at all');
      final Object? description = (meta! as Map<String, dynamic>)['description'];
      expect(description, isA<String>(), reason: '$id has no description');
      expect((description! as String).trim(), isNotEmpty, reason: id);
    }

    // The third half, and the one that catches a gitignored generation. The
    // output is committed so a stale generation shows up in a diff instead of
    // hiding in a build directory.
    for (final String path in <String>[_generated, _generatedEn]) {
      expect(File(path).existsSync(), isTrue, reason: '$path is not committed');
      final int ignored = Process.runSync('git', <String>['check-ignore', path]).exitCode;
      expect(ignored, isNot(0), reason: '$path is git-ignored');
    }
  });

  test('l10n.yaml sets required-resource-attributes, nullable-getter false and '
      'use-named-parameters', () {
    // The three keys that decide the call-site shape, asserted before there
    // are call sites.
    //
    // `required-resource-attributes: true` is kept, but it holds only HALF the
    // rule. Measured on 3.44.8: it fails generation when the `@key` block is
    // missing entirely — "Resource attribute "@withdrawalSource" was not
    // found" — and PASSES when the block is present with no `description`. The
    // description half is held by this file's anchor, above. 10 §8.4 used to
    // claim the flag was the whole mechanism; it is not, and the document has
    // been corrected.
    expect(declaresIn(l10n, 'required-resource-attributes: true'), isTrue);
    expect(declaresIn(l10n, 'nullable-getter: false'), isTrue);
    expect(declaresIn(l10n, 'use-named-parameters: true'), isTrue);
  });

  test('l10n.yaml never mentions synthetic-package, in either polarity', () {
    // Anti-pattern 31. Its own help text on Flutter 3.44 reads "DEPRECATED.
    // This flag cannot be enabled and should be removed". Any tutorial that
    // sets it predates 3.32.
    expect(l10n.any((String l) => l.contains('synthetic-package')), isFalse);
  });

  test('build.yaml is spelled build.yaml, configures drift_dev and declares '
      'modules fts5', () {
    // NOT build.yml. A drift discussion exists solely because somebody lost a
    // day to that typo and FTS5 silently stayed disabled — build_runner does
    // not warn about a config file it never found.
    expect(File(_buildYaml).existsSync(), isTrue);
    expect(
      File('build.yml').existsSync(),
      isFalse,
      reason: 'build.yml is the typo that silently disables everything here',
    );
    expect(declaresIn(build, 'drift_dev:'), isTrue);
    expect(declaresIn(build, '- fts5'), isTrue);
  });

  test('build.yaml carries no store_date_time_values_as_text and sets '
      'override_hash_and_equals_in_result_sets', () {
    // The irreversible key, absent. It forces one representation onto instants
    // (INTEGER UTC epoch millis) and civil dates (TEXT 'YYYY-MM-DD'), which
    // decision #2 keeps separate, and the mistake becomes permanent at N07.
    expect(build.any((String l) => l.contains('store_date_time_values_as_text')), isFalse);
    // The equality option, present: it is what makes `.distinct()` in the
    // repository actually suppress duplicate stream emissions (#12).
    expect(declaresIn(build, 'override_hash_and_equals_in_result_sets: true'), isTrue);
  });

  test('build.yaml schema_dir and test_dir name directories that exist', () {
    // Point them anywhere else and make-migrations at N08 writes the snapshots
    // into a path nothing commits — and losing a schema snapshot is the one
    // loss 00-README §7.1 calls unrecoverable.
    for (final String key in <String>['schema_dir', 'test_dir']) {
      final String line = build.firstWhere(
        (String l) => l.trimLeft().startsWith('$key:'),
        orElse: () => '',
      );
      expect(line, isNotEmpty, reason: 'build.yaml declares no $key');
      final String path = line.split(':').last.trim();
      expect(
        Directory(path).existsSync(),
        isTrue,
        reason: '$key points at "$path", which does not exist',
      );
    }
  });

  test('no AnimalClass noun appears literally in any ARB message value', () {
    // 10 §8.5. "Turn out ewe {tag}?" is the failure mode that survives code
    // review; "Turn out {term} {tag}?" is the fix.
    final Map<String, dynamic> arb = readArb();
    for (final MapEntry<String, dynamic> entry in arb.entries) {
      if (entry.key.startsWith('@')) {
        continue;
      }
      final String value = entry.value.toString().toLowerCase();
      for (final String noun in animalNouns) {
        expect(
          RegExp('\\b$noun\\b').hasMatch(value),
          isFalse,
          reason:
              '"${entry.key}" carries the literal noun "$noun". Domain '
              'nouns arrive as a {term} placeholder fed by '
              'terminologyProvider, because they vary by county',
        );
      }
    }

    // And the placeholder-name half of the same rule.
    for (final MapEntry<String, dynamic> entry in arb.entries) {
      if (!entry.key.startsWith('@')) {
        continue;
      }
      final Object? meta = entry.value;
      if (meta is! Map<String, dynamic>) {
        continue;
      }
      final Object? placeholders = meta['placeholders'];
      if (placeholders is! Map<String, dynamic>) {
        continue;
      }
      for (final String name in placeholders.keys) {
        expect(
          bannedPlaceholderNames.contains(name),
          isFalse,
          reason:
              '${entry.key} uses the placeholder name "$name". Use '
              'singularTerm and pluralTerm — `plural` is an ICU keyword and '
              'a placeholder that shadows it stops parsing on the next '
              'gen-l10n release',
        );
      }
    }
  });
}

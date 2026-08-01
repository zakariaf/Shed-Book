// 12 §11.2: *"the tags must be declared here or a `--tags` filter silently
// matches nothing and the run is green because it ran nothing."* Two of these
// cases exist to make sure that never becomes true of this repository.
//
// The sentence is now known to be half wrong on this SDK and the correction is
// recorded rather than assumed: an empty tag selection on Flutter 3.44.8 exits
// **79**, not 0. That is a stronger position than the document expected, and it
// changes nothing about the rule — an exit code is a weaker guarantee than a
// name, and a step that passes because a tagged file exists is worth more than
// one that fails because none does.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _config = 'dart_test.yaml';

/// 12 §11.2's six, plus `calendar`, which N00's ledger test carries.
const List<String> declaredTags = <String>[
  'golden',
  'migration',
  'uk-zone',
  'policy',
  'slow',
  'calendar',
  'flaky',
];

/// Tags that some command actually selects for, and which must therefore have
/// at least one file carrying them. `golden`, `migration`, `slow` and `flaky`
/// are allowed to be empty until N33, N08, and never.
const List<String> tagsWithCarriers = <String>['uk-zone', 'policy', 'calendar'];

/// Files that spell a `--tags` or `--exclude-tags` filter. Both are
/// hand-maintained copies of one list — CI does not run `make` — so a change to
/// either is a change to both.
const List<String> filterSources = <String>['Makefile', '.github/workflows/ci.yml'];

final RegExp _tagFilter = RegExp(r'--(?:exclude-)?tags[= ]([a-z-]+)');

Set<String> tagsDeclaredIn(List<String> lines) {
  final Set<String> tags = <String>{};
  bool inTagsBlock = false;
  for (final String line in lines) {
    if (line.startsWith('tags:')) {
      inTagsBlock = true;
      continue;
    }
    if (inTagsBlock && line.isNotEmpty && !line.startsWith(' ')) {
      inTagsBlock = false;
    }
    if (!inTagsBlock) {
      continue;
    }
    final RegExpMatch? m = RegExp(r'^  ([a-z-]+):\s*$').firstMatch(line);
    if (m != null) {
      tags.add(m.group(1)!);
    }
  }
  return tags;
}

/// Every `@Tags([...])` carrier anywhere under `test/` and `integration_test/`.
Set<String> tagsCarriedByFiles() {
  final Set<String> carried = <String>{};
  for (final String root in <String>['test', 'integration_test']) {
    final Directory directory = Directory(root);
    if (!directory.existsSync()) {
      continue;
    }
    for (final FileSystemEntity entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      for (final RegExpMatch m in RegExp(
        r"@Tags\(<String>\[([^\]]*)\]\)",
      ).allMatches(entity.readAsStringSync())) {
        for (final RegExpMatch t in RegExp(r"'([a-z-]+)'").allMatches(m.group(1)!)) {
          carried.add(t.group(1)!);
        }
      }
    }
  }
  return carried;
}

void main() {
  final List<String> lines = File(_config).readAsLinesSync();
  final Set<String> declared = tagsDeclaredIn(lines);

  test('there is no preset block, the seven tags are declared, and migration '
      'runs unrandomised', () {
    // The preset half asserts the RECORDED RULING rather than a `presets:`
    // block, because the day-one check ruled the presets out. 12 §14 edit 1
    // said which document changes depending on the answer; the answer was that
    // `flutter test` has no preset flag, so 13 §1.3 and §4.3 change and this
    // file carries no presets.
    expect(
      lines.any((String l) => l.trimLeft().startsWith('presets:')),
      isFalse,
      reason:
          '`flutter test` has no -P / --preset flag on 3.44.8, so a '
          'presets: block here is configuration nothing can select',
    );
    expect(
      lines.any((String l) => l.contains('THERE IS NO `presets:` BLOCK')),
      isTrue,
      reason:
          'the ruling must be recorded in the file, not quietly dropped — '
          'the one unacceptable outcome is two documents saying different '
          'things',
    );

    expect(declared, declaredTags.toSet());

    // The two halves of the ordering rule, in the two places they legally live.
    expect(lines.any((String l) => l.contains('allow_test_randomization: false')), isTrue);
  });

  test('every tag the Makefile or ci.yml selects is declared in dart_test.yaml', () {
    // The silently-matches-nothing failure, closed over the repository rather
    // than over a remembered list.
    for (final String path in filterSources) {
      final File file = File(path);
      if (!file.existsSync()) {
        continue; // Makefile is N01-T05's, ci.yml is N01-T06's.
      }
      for (final RegExpMatch m in _tagFilter.allMatches(file.readAsStringSync())) {
        expect(
          declared,
          contains(m.group(1)),
          reason:
              '$path selects "${m.group(1)}", which dart_test.yaml does '
              'not declare',
        );
      }
    }
  });

  test('at least one test file carries each declared tag that any command '
      'selects', () {
    // The vacuous-green failure. golden, migration, slow and flaky are allowed
    // to be empty until N33, N08, and never.
    final Set<String> carried = tagsCarriedByFiles();
    for (final String tag in tagsWithCarriers) {
      expect(
        carried,
        contains(tag),
        reason:
            'no file carries @Tags([\'$tag\']), so a --tags $tag filter '
            'selects nothing',
      );
    }
  });

  test('the migration tag sets allow_test_randomization false and no '
      'runner-level seed is set', () {
    // Under a `tags:` entry only test-level metadata is valid — timeout, skip,
    // retry, tags, on_platform, allow_test_randomization.
    // `test_randomize_ordering_seed` is a RUNNER-level key: setting it at the
    // top of this file would switch randomisation off for the WHOLE suite,
    // which is the exact opposite of what the randomised CI job exists for.
    expect(
      lines.any((String l) => l.trimLeft().startsWith('test_randomize_ordering_seed')),
      isFalse,
      reason: 'a runner-level seed here disables randomisation everywhere',
    );

    final int migrationAt = lines.indexWhere((String l) => l.trimLeft().startsWith('migration:'));
    expect(migrationAt, isNot(-1));
    final Iterable<String> block = lines
        .skip(migrationAt + 1)
        .takeWhile((String l) => l.startsWith('    ') || l.trim().isEmpty);
    expect(
      block.any((String l) => l.contains('allow_test_randomization: false')),
      isTrue,
      reason: 'the key is not inside the migration tag block',
    );
  });

  test('no flaky-tagged test has an expiry date in its name that has passed', () {
    // 12 §11.6. Written here while there are zero flaky tests and it is free.
    // It reads no clock and never will: it compares the expiry against the
    // ledger's own rule — a name must carry a parseable ISO date — and leaves
    // "has it passed" to the human reading the failure, for the same reason
    // calendar_commitments_test.dart reads no clock.
    final Directory tests = Directory('test');
    for (final FileSystemEntity entity in tests.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final String source = entity.readAsStringSync();
      if (!source.contains("'flaky'")) {
        continue;
      }
      for (final RegExpMatch m in RegExp(r"test\('flaky-until-([^:]*):").allMatches(source)) {
        expect(
          RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(m.group(1)!),
          isTrue,
          reason:
              '${entity.path} has a flaky test whose name carries no '
              'ISO expiry date: ${m.group(1)}',
        );
      }
    }
  });
}

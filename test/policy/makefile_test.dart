// `CLAUDE.md` names five project commands — make gen, make check, make test,
// dart tool/check_policy.dart, python3 tool/validate_skills.py — and until
// N01-T05 none of them existed. The two Python validators were declared project
// commands that nothing ran, which is critique gap G4.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _makefile = 'Makefile';

/// `check`'s canonical order, cheapest failure first. The anchor asserts the
/// recipe is a **subsequence** of this and not equal to it, so it holds both
/// before and after N03 inserts the gate — see the option-C note below — and
/// still fails the moment somebody puts `analyze` before `format`.
/// Matched against the recipe text, which uses `$(DART)` and `$(FLUTTER)`
/// rather than the bare command names — `?=` is what lets CI override them.
const List<String> checkOrder = <String>[
  'tool/check_policy.dart',
  'validate',
  'format --output=none',
  'analyze',
];

/// Eight counted by this task's title. `perf` is 13 §1.3's seventh and ships
/// with them, because 13 §1.3 is verbatim-binding and a Makefile missing one of
/// its targets contradicts the document that owns the file. Nine recipes,
/// eight counted.
const List<String> requiredTargets = <String>[
  'gen',
  'check',
  'test',
  'goldens',
  'goldens-update',
  'integration',
  'validate',
  'all',
];

/// Anything that would put a network fetch inside a recipe. The one genuine
/// cold-cache fetch is `package:sqlite3`'s build hook, which is documented in
/// README.md and is not a step this file adds.
const List<String> networkCommands = <String>['curl', 'wget', 'git clone', 'pub global activate'];

/// The recipe body of a target: every TAB-indented line under it.
List<String> recipeFor(List<String> lines, String target) {
  final int at = lines.indexWhere((String l) => l.startsWith('$target:'));
  if (at < 0) {
    return <String>[];
  }
  return lines
      .skip(at + 1)
      .takeWhile((String l) => l.startsWith('\t') || l.trim().isEmpty)
      .where((String l) => l.trim().isNotEmpty)
      .toList();
}

void main() {
  final List<String> lines = File(_makefile).readAsLinesSync();

  test('make check runs check_policy, validate_skills and validate_epics '
      'before analyze, and goldens never re-baselines', () {
    final List<String> check = recipeFor(lines, 'check');
    expect(check, isNotEmpty, reason: 'the Makefile has no check target');

    // Subsequence, not equality. N01-T05 takes option C from that task's §5.3:
    // every line here EXCEPT `dart tool/check_policy.dart`, which N03 adds
    // in the same commit that makes the script exist — so `main` is never red
    // for a whole epic over a script that is not there yet.
    int cursor = 0;
    for (final String line in check) {
      while (cursor < checkOrder.length && !line.contains(checkOrder[cursor])) {
        cursor++;
      }
      expect(
        cursor,
        lessThan(checkOrder.length),
        reason: 'check runs steps out of order at: $line',
      );
      cursor++;
    }

    // And when check_policy IS present it is first — the cheapest step.
    final int policyAt = check.indexWhere((String l) => l.contains('tool/check_policy.dart'));
    if (policyAt >= 0) {
      expect(policyAt, 0, reason: 'the gate is the cheapest step and runs first');
    }

    // goldens VERIFIES. A target called `goldens` that silently passes
    // --update-goldens is the easiest way there is to green a broken golden,
    // because you type it to check and it always agrees with you.
    expect(recipeFor(lines, 'goldens').join('\n'), isNot(contains('--update-goldens')));
  });

  test('every command CLAUDE.md names is a real target or a real script', () {
    // Closes critique gap G4: the two Python validators had no runner.
    for (final String target in requiredTargets) {
      expect(
        lines.any((String l) => l.startsWith('$target:')),
        isTrue,
        reason: 'no $target target',
      );
    }
    for (final String script in <String>['tool/validate_skills.py', 'tool/validate_epics.py']) {
      expect(File(script).existsSync(), isTrue, reason: '$script is missing');
      expect(
        lines.any((String l) => l.contains(script)),
        isTrue,
        reason: '$script is a declared project command that nothing runs',
      );
    }
  });

  test('goldens carries no --update-goldens and goldens-update carries exactly '
      'one', () {
    expect(recipeFor(lines, 'goldens').join('\n'), isNot(contains('--update-goldens')));
    final String update = recipeFor(lines, 'goldens-update').join('\n');
    expect('--update-goldens'.allMatches(update).length, 1);
  });

  test('every recipe line is indented with a tab', () {
    // A space-indented recipe fails with "missing separator" and the message
    // names the line, not the cause. Most editors convert tabs to spaces by
    // default.
    for (final String target in requiredTargets) {
      final int at = lines.indexWhere((String l) => l.startsWith('$target:'));
      if (at < 0) {
        continue;
      }
      for (int i = at + 1; i < lines.length; i++) {
        final String line = lines[i];
        if (line.trim().isEmpty) {
          continue;
        }
        if (!line.startsWith(' ') && !line.startsWith('\t')) {
          break; // the next target or a top-level line
        }
        expect(
          line.startsWith('\t'),
          isTrue,
          reason: '$target has a space-indented recipe line: "$line"',
        );
      }
    }
  });

  test('test runs two commands and the second sets TZ=Europe/London with no '
      'path', () {
    final List<String> recipe = recipeFor(lines, 'test');
    expect(
      recipe,
      hasLength(2),
      reason:
          'test is two commands because TZ is per-process — a --tags '
          'filter selects files, it cannot change the zone the runner '
          'started in',
    );

    expect(recipe.first, contains('--exclude-tags'));
    expect(recipe.first, contains('--test-randomize-ordering-seed random'));

    expect(recipe.last, contains('TZ=Europe/London'));
    expect(recipe.last, contains('--tags uk-zone'));
    // 12 §2.5 note 1 and §14 amendment A: the zone step must be UNSCOPED. Two
    // zone-pinned files land in test/data/ and test/features/ later, and a
    // test/domain scope would run them in the runner's own zone — UTC — where
    // a spring-forward test passes because there is no spring forward.
    expect(recipe.last, isNot(contains('test/')), reason: 'the zone command carries a path scope');
  });

  test('no recipe fetches anything over the network', () {
    for (final String line in lines.where((String l) => l.startsWith('\t'))) {
      for (final String command in networkCommands) {
        expect(line, isNot(contains(command)), reason: 'a recipe fetches over the network: $line');
      }
    }
  });
}

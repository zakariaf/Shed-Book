// CI does not run `make`: `ci.yml` spells its steps out. So the workflow and
// the `Makefile` are two hand-maintained copies of one list, and one case here
// asserts they agree — that is the case that fires when N01-T04's day-one check
// is applied to one file and not the other.
//
// The previous plan created the `test` job in no task at all (critique gap G2),
// which is why the one line between a working and a red CI on day one —
// `libsqlite3-dev` on the runner — had no owner.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _workflow = '.github/workflows/ci.yml';
const String _makefile = 'Makefile';
const String _fvmrc = '.fvmrc';

/// Both become required status checks. Renaming one silently un-requires it and
/// every subsequent pull request goes green on nothing.
const List<String> jobNames = <String>['gate', 'test'];

final RegExp _tagFilter = RegExp(r'--(?:exclude-)?tags\s+(?:"([^"]+)"|([^\s\\]+))');

/// The steps of a job: everything from `  <name>:` to the next job at the same
/// indent.
List<String> jobBlock(List<String> lines, String job) {
  final int at = lines.indexWhere((String l) => l == '  $job:');
  if (at < 0) {
    return <String>[];
  }
  return lines.skip(at + 1).takeWhile((String l) => !RegExp(r'^  [a-z_-]+:$').hasMatch(l)).toList();
}

/// Every tag selector a file spells, normalised to a set of tag names.
Set<String> tagSelectorsIn(String text) {
  final Set<String> tags = <String>{};
  for (final RegExpMatch m in _tagFilter.allMatches(text)) {
    for (final String part in (m.group(1) ?? m.group(2)!).split('||')) {
      final String tag = part.trim();
      if (tag.isNotEmpty && !tag.startsWith(r'$')) {
        tags.add(tag);
      }
    }
  }
  return tags;
}

void main() {
  final List<String> allLines = File(_workflow).readAsLinesSync();

  /// YAML comment lines. Every assertion here is about what the workflow DOES,
  /// and the workflow explains its own rules in comments — an unfiltered scan
  /// finds the documentation rather than the step.
  bool isComment(String line) => line.trimLeft().startsWith('#');

  final List<String> lines = allLines.where((String l) => !isComment(l)).toList();
  final String workflow = lines.join('\n');

  test('ci.yml declares gate and test, both blocking, on push and '
      'pull_request', () {
    for (final String job in jobNames) {
      expect(lines.any((String l) => l == '  $job:'), isTrue, reason: 'no $job job');
    }
    expect(workflow, contains('pull_request:'));
    expect(workflow, contains('branches: [main]'));

    // Blocking means blocking. A continue-on-error step is a green check that
    // proved nothing.
    expect(workflow, isNot(contains('continue-on-error')));

    // codegen ARRIVED with N08-T06, in the commit that gave it something to run
    // against. Inverted rather than deleted: the pair is what stops it being
    // removed in a tidy-up with a green suite.
    expect(
      lines.any((String l) => l == '  codegen:'),
      isTrue,
      reason: 'codegen lands with N08-T06',
    );

    // **INVERTED AT N31-T03, WHICH IS THE TASK THAT LANDED IT.** The case used
    // to assert `android:` was ABSENT, and that was right while there was no
    // platform artefact to build — the same shape `codegen` above went through.
    // The pair is what stops the job being removed in a tidy-up with a green
    // suite.
    expect(
      lines.any((String l) => l == '  android:'),
      isTrue,
      reason: 'the android job lands with N31-T03',
    );
  });

  test('the android job blocks on the three jobs above it and archives G4', () {
    // **`needs: [gate, codegen, test]`** — an artefact is worth inspecting only
    // once the source it was built from has passed. Building a bundle from
    // source that fails the gate wastes twenty minutes to tell you something the
    // gate said in fifty seconds.
    final List<String> block = jobBlock(lines, 'android');
    expect(block.join('\n'), contains('needs: [gate, codegen, test]'));
    expect(block.join('\n'), contains('timeout-minutes: 30'));

    // **G1 RUNS THE SCRIPT RATHER THAN INLINING IT.** `release.yml` (N34) runs
    // the same gate, and two copies of a permission comparison is one copy that
    // goes stale on the release path — which is the path nobody watches until a
    // release.
    expect(block.join('\n'), contains('bash tool/assert_permissions.sh'));

    // **`if: always()` IS G4, NOT TIDINESS.** The merger report is the only
    // artefact that names which dependency contributed a permission, and the run
    // you need it from is the run that just went red.
    final int upload = block.indexWhere((String l) => l.contains('upload-artifact'));
    expect(upload, greaterThan(0), reason: 'the android job archives nothing');
    expect(
      block.skip(upload).take(3).join('\n'),
      contains('if: always()'),
      reason: 'the report would be archived exactly when nobody needs it',
    );
    expect(block.join('\n'), contains('manifest-merger-release-report.txt'));
  });

  test('the release bundle is obfuscated and splits its debug symbols', () {
    // A release built without `--obfuscate` ships readable Dart, and one built
    // without `--split-debug-info` cannot have a stack trace symbolicated later
    // — and there is no crash reporter in this app, so the symbols are the only
    // route from a shepherd's screenshot to a line number.
    final String block = jobBlock(lines, 'android').join('\n');
    expect(block, contains('--obfuscate'));
    expect(block, contains('--split-debug-info=build/symbols/android'));
    expect(block, contains('build/symbols/android'), reason: 'the symbols are not archived');
  });

  test('the test job installs libsqlite3-dev before it runs any test', () {
    final List<String> block = jobBlock(lines, 'test');
    expect(block, isNotEmpty);

    final int sqlite = block.indexWhere((String l) => l.contains('libsqlite3-dev'));
    final int firstTest = block.indexWhere((String l) => l.contains('flutter test'));
    expect(
      sqlite,
      isNot(-1),
      reason:
          '12 §3.2: the host must supply sqlite3, because flutter test '
          'runs on the HOST and the plugin is never applied',
    );
    expect(firstTest, isNot(-1));
    expect(sqlite, lessThan(firstTest));
  });

  test('the zone-pinned step carries no path and the hostile step excludes '
      'uk-zone', () {
    final List<String> block = jobBlock(lines, 'test');

    final String zoneStep = block.firstWhere(
      (String l) => l.contains('TZ=Europe/London'),
      orElse: () => '',
    );
    expect(zoneStep, isNotEmpty);
    expect(zoneStep, contains('--tags uk-zone'));
    // 12 §14 amendment A. A test/domain scope would run the two zone-pinned
    // files 12 §2.4 adds later under the runner's UTC, where they pass
    // vacuously.
    expect(zoneStep, isNot(contains('test/')), reason: 'the zone step must be unscoped');

    final String hostile = block.firstWhere(
      (String l) => l.contains('TZ=Pacific/Chatham'),
      orElse: () => '',
    );
    expect(hostile, isNotEmpty);
    // 12 §14 amendment B. Without the exclusion this step is red on every run,
    // for the right reason — and that is how a correct gate gets deleted.
    expect(hostile, contains('--exclude-tags uk-zone'));
  });

  test('every job that installs Flutter asserts the pin against .fvmrc', () {
    final int installs = 'subosito/flutter-action'.allMatches(workflow).length;
    expect(installs, greaterThan(0));

    // True for this file today, and the reason it stays true when N33 and N34
    // add two more workflows. Inside ci.yml one assert covers both jobs because
    // `test` has `needs: gate`.
    expect(
      workflow,
      contains(r'''grep -o '"flutter": *"[^"]*"' .fvmrc'''),
      reason:
          'no job reads .fvmrc, so a green CI could be building a '
          'toolchain nobody has locally',
    );
    expect(
      jobBlock(lines, 'test').any((String l) => l.contains('needs: gate')),
      isTrue,
      reason:
          'test does not need gate, so gate\'s single assert does not '
          'cover it',
    );
  });

  test('the workflow FLUTTER_VERSION equals the version in .fvmrc', () {
    // The four-places problem, closed by a test that reads both.
    final RegExpMatch? env = RegExp(r"FLUTTER_VERSION: '([^']+)'").firstMatch(workflow);
    expect(env, isNotNull);

    final RegExpMatch? pinned = RegExp(
      r'"flutter": *"([^"]+)"',
    ).firstMatch(File(_fvmrc).readAsStringSync());
    expect(pinned, isNotNull);

    expect(
      env!.group(1),
      pinned!.group(1),
      reason:
          '.fvmrc says ${pinned.group(1)}, the workflow says '
          '${env.group(1)}',
    );
    expect(env.group(1), isNot('stable'));
  });

  test('the Makefile and ci.yml spell the same test filters', () {
    // Two hand-maintained copies of one list.
    final Set<String> inWorkflow = tagSelectorsIn(workflow);
    final List<String> makefileLines = File(
      _makefile,
    ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('#')).toList();
    final Set<String> inMakefile = tagSelectorsIn(makefileLines.join('\n'));

    // The Makefile hides its broad list behind BROAD_EXCLUDE, so read that too.
    final RegExpMatch? broad = RegExp(
      r'BROAD_EXCLUDE \?= (.+)',
    ).firstMatch(makefileLines.join('\n'));
    expect(broad, isNotNull, reason: 'the Makefile declares no BROAD_EXCLUDE');
    inMakefile.addAll(broad!.group(1)!.split('||').map((String s) => s.trim()));

    expect(inWorkflow, inMakefile, reason: 'the two copies of one filter list have drifted apart');
  });

  test('coverage is uploaded with if always and no step gates on it', () {
    expect(workflow, contains('upload-artifact'));
    expect(
      workflow,
      contains('if: always()'),
      reason:
          'coverage must upload from a FAILING run, which is the run you '
          'want it from',
    );
    // #119: reported, never gated. No threshold, no codecov, no network call
    // in a project whose central claim is that it makes none.
    for (final String gated in <String>[
      'codecov',
      'min-coverage',
      'coverage-threshold',
      'fail_ci_if_error',
    ]) {
      expect(
        workflow,
        isNot(contains(gated)),
        reason: 'coverage that gates is coverage that gets gamed',
      );
    }
  });
}

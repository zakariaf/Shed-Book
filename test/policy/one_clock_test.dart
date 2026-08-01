// test/policy/one_clock_test.dart — named for the PROPERTY, not the file under
// test (CONVENTIONS §4.1).
//
// 12 §1.4 sends source scans to tool/check_policy.dart, and most of this
// property is already there: `time.dart_clock` bans the wall-clock literal under
// both roots. What the gate has **no** row for is `clock.now(` — the ambient
// reader — so this file holds that half, plus the behavioural cross-check on
// appNow() itself. If a `time.ambient_clock` row is ever added to the gate, keep
// this file as the cross-check and do not let the two drift apart.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/domain/time/instant.dart';

/// Every non-generated Dart file under `lib/`, as repository-relative paths.
///
/// `*.g.dart`, `*.drift.dart`, the gen-l10n output and the drift schema helpers
/// are excluded, exactly as the gate excludes them — a cross-check that
/// disagreed with the gate about scope would be worse than none.
List<String> _libSources() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => f.path.replaceAll(r'\', '/'))
        .where((String p) => p.endsWith('.dart'))
        .where(
          (String p) =>
              !p.endsWith('.g.dart') &&
              !p.endsWith('.drift.dart') &&
              !p.contains('/app_localizations'),
        )
        .toList()
      ..sort();

List<String> _hits(String needle) =>
    _libSources().where((String p) => File(p).readAsStringSync().contains(needle)).toList();

void main() {
  // The title is the backlog's anchor and is split across adjacent string
  // literals so this file — which lives under a scanned root — does not itself
  // trip time.dart_clock. Dart concatenates them with no separator, so the name
  // is the anchor verbatim.
  test('DateTime'
      '.now( appears in exactly one non-generated file under lib/', () {
    // Read 05 §2.8 before touching this: the file it names contains the
    // wall-clock literal ZERO times today, because `clock.now()` does the
    // reading, and the allowlist entry exists so the rule has exactly one
    // reviewable exception point. `expect(hits.length, 1)` on the literal alone
    // is red for ever, and would be "fixed" by somebody adding a pointless call
    // to satisfy it.
    //
    // So the assertion is the conjunction that is actually true, under the name
    // the backlog fixed:
    const String clockReader = 'lib/core/time/app_clock.dart';
    final String wallClockLiteral =
        'DateTime'
        '.now(';

    expect(
      _hits(wallClockLiteral),
      everyElement(clockReader),
      reason: 'the one reviewable exception point is $clockReader',
    );
    expect(
      _hits(
        'clock'
        '.now(',
      ),
      <String>[clockReader],
      reason:
          'the ambient clock is read in exactly one place, and this is the half '
          'tool/check_policy.dart has no row for',
    );
  });

  test('the [exempt] allowlist names app_clock.dart and only app_clock.dart '
      'for time.dart_clock', () {
    final List<String> exempt = File('tool/policy_allowlist.txt')
        .readAsLinesSync()
        .map((String l) => l.split('#').first.trim())
        .skipWhile((String l) => l != '[exempt]')
        .where((String l) => l.contains('::'))
        .map((String l) {
          final List<String> halves = l.split('::');
          return '${halves.first.trim()} :: ${halves.last.trim()}';
        })
        .toList();
    final Iterable<String> forThisRule = exempt.where(
      (String l) => l.endsWith(':: time.dart_clock'),
    );
    expect(forThisRule, <String>['lib/core/time/app_clock.dart :: time.dart_clock']);
  });

  test('no file under lib/domain/ imports package:clock', () {
    // The D3/R24 half, cross-checking layer.domain from the test side. A pure
    // function that needs the current instant takes it as a parameter.
    //
    // It reads DIRECTIVES, with the same regex tool/check_policy.dart uses, and
    // not the whole file text. That is the difference between the property this
    // test is named for and a substring search that also fires on a doc comment
    // saying "package:clock is banned here" — which is the sentence a
    // lib/domain/ file most wants to carry. Found by clear_date.dart (N05-T02)
    // carrying exactly that sentence: the gate stayed green, because the gate
    // was already reading directives, and only the looser cross-check went red.
    //
    // Nothing is lost by narrowing it: the package cannot be used without being
    // imported or exported, and both are directives.
    final RegExp directive = RegExp(
      r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
      multiLine: true,
    );
    for (final String path in _libSources().where((String p) => p.startsWith('lib/domain/'))) {
      final Iterable<String> targets = directive
          .allMatches(File(path).readAsStringSync())
          .map((RegExpMatch m) => m.group(1)!);
      expect(targets, isNot(contains(startsWith('package:clock'))), reason: path);
    }
  });

  test('there is no second clock abstraction', () {
    // Two clock seams are worse than none: a test that fakes one does not fake
    // the other. Comment lines are dropped, because app_clock.dart's own doc
    // comment names all three spellings as the thing not to add.
    for (final String path in _libSources()) {
      final String declarations = File(
        path,
      ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');
      expect(declarations, isNot(contains('abstract class Clock')), reason: path);
      expect(declarations, isNot(contains('SystemClock')), reason: path);
      expect(declarations, isNot(contains('clockProvider')), reason: path);
    }
  });

  test('appNow reads the ambient clock and returns a true instant', () {
    final DateTime fixed = DateTime.utc(2026, 3, 4, 3, 20);
    withClock(Clock.fixed(fixed), () {
      expect(appNow(), Instant.fromDateTime(fixed));
    });
  });
}

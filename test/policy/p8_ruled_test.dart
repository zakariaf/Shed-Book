// test/policy/p8_ruled_test.dart
//
// P8, as an executable assertion. `test/policy/` files are named for the
// PROPERTY rather than the file under test (`CONVENTIONS §4.1`), and the
// property here is that the ruling reached the documents rather than only the
// code.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The key the abolished chooser published. Split across two literals: this
/// file names it in order to ban it, and it lives under a scanned root. The
/// thirty-third prohibition-versus-claim self-match in this project.
const String _abolished =
    'birth_'
    'type.twin';

/// A line carrying strike-through is the AMENDMENT RULE WORKING, not a
/// violation: `00-README` §10 requires a superseded decision to be struck with
/// its reason rather than quietly deleted, so the old key survives inside `~~`
/// on purpose and this scan has to see the difference.
String _liveText(File f) => f
    .readAsLinesSync()
    .where((String l) => !l.contains('~~') && !l.trimLeft().startsWith('//'))
    .join('\n');

Iterable<File> _markdown(String root) => Directory(
  root,
).listSync(recursive: true).whereType<File>().where((File f) => f.path.endsWith('.md'));

void main() {
  test('no engineering document still publishes a key for the abolished chooser', () {
    // A NAMING AUTHORITY THAT PUBLISHES A KEY FOR A CONTROL THE PRODUCT DOES NOT
    // HAVE IS WORSE THAN A MISSING EXAMPLE, because a fixer applies it
    // mechanically — which is exactly how the sixth tap would come back.
    for (final File f in _markdown('docs/engineering')) {
      expect(_liveText(f), isNot(contains(_abolished)), reason: f.path);
    }
  });

  test('no skill prescribes a birth-type chooser', () {
    // Amendment rule step 2: grep the doc set AND the skills. A skill never
    // outranks a document, but it is what an agent reads first.
    for (final File f in _markdown('.claude/skills')) {
      final String live = _liveText(f);
      expect(live, isNot(contains(_abolished)), reason: f.path);
      expect(
        live,
        isNot(contains('five big buttons')),
        reason: '${f.path} describes the abolished chooser',
      );
    }
  });

  test('no widget key under lib/ contains the abolished segment', () {
    // The tree-walking canary in lambing_entry_test.dart holds this at runtime
    // over the pumped tree; this holds it over the SOURCE, so a key on a screen
    // no test pumps yet is caught too.
    const String segment =
        'birth_'
        'type';

    for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart') || f.path.endsWith('.g.dart')) {
        continue;
      }
      for (final RegExpMatch m in RegExp(r"Key\('([^']+)'\)").allMatches(f.readAsStringSync())) {
        expect(m.group(1), isNot(contains(segment)), reason: '${f.path}: ${m.group(1)}');
      }
    }
  });

  test('the ruling is recorded in the decision record, not only in the code', () {
    // Amendment rule step 1: the row exists FIRST and everything else is
    // downstream of it. A ruling that lives only in a commit message is a
    // ruling the next reader re-opens.
    final String decisions = File('docs/research/00-tech-decisions.md').readAsStringSync();
    expect(decisions, contains('P8 — the birth-type chooser'));
    expect(decisions, contains('lambing_entry.tally.stroke'));
  });
}

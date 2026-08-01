// P1 — `struck` / `struck_at` — is the last of the schema-irreversible rulings
// and the one with the widest blast radius. Adding the pair after the first
// snapshot is a cheap `ALTER TABLE … ADD COLUMN` and an expensive re-reading of
// every query, every export shape, every statistic and every restore mapping
// written in the meantime, because each of them silently assumed no row could
// be struck.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _conventions = 'docs/engineering/CONVENTIONS.md';
const String _schema = 'docs/engineering/03-data-model-and-schema.md';
const String _exports = 'docs/engineering/09-export-formats.md';
const String _manifest = 'docs/skills/02-build-manifest.md';

/// The ruling's own heading in `CONVENTIONS §6`. Ruling numbers are allocated
/// in order and R74 was the highest before N00-T04 took R75–R78.
final RegExp _rulingHeading =
    RegExp(r'^### R(\d+) — .*\bstruck\b.*$', multiLine: true);

/// `**Tables (N):**` — the stated count, beside the list it must match.
final RegExp _tableCount = RegExp(r'\*\*Tables \((\d+)\):\*\*');

/// Everything from [heading] to the next heading of the same level.
String _ruling(String document) {
  final RegExpMatch? start = _rulingHeading.firstMatch(document);
  if (start == null) {
    return '';
  }
  final int from = start.start;
  final int next = document.indexOf('\n### ', from + 1);
  return document.substring(from, next < 0 ? document.length : next);
}

/// The table names in `@DriftDatabase(tables: [...])`.
Set<String> _schemaTables(String document) {
  final int open = document.indexOf('@DriftDatabase(');
  final int listStart = document.indexOf('tables: [', open);
  final int listEnd = document.indexOf(']', listStart);
  return document
      .substring(listStart + 'tables: ['.length, listEnd)
      .split(RegExp(r'[,\s]+'))
      .where((String s) => s.isNotEmpty)
      .toSet();
}

void main() {
  final String conventions = File(_conventions).readAsStringSync();
  final String ruling = _ruling(conventions);

  test('CONVENTIONS §6 carries a numbered ruling for struck and struck_at and '
      'names every table it applies to', () {
    final RegExpMatch? heading = _rulingHeading.firstMatch(conventions);
    expect(heading, isNotNull,
        reason: 'CONVENTIONS §6 has no numbered ruling naming `struck`');

    final int number = int.parse(heading!.group(1)!);
    expect(number, greaterThanOrEqualTo(75),
        reason: 'R74 was the highest ruling before this backlog started');

    expect(ruling, contains('struck_at'),
        reason: 'the ruling names only one of the two columns');
    expect(_tableCount.hasMatch(ruling), isTrue,
        reason: 'the ruling states no table count, so nothing can check the '
            'list against it');
  });

  test('the ruling names a table count and the list matches it', () {
    // A list that drifts from its own count is how a table gets missed at N07.
    final int stated = int.parse(_tableCount.firstMatch(ruling)!.group(1)!);
    final int listed = RegExp(r'^\s*\d+\.\s+`(\w+)`', multiLine: true)
        .allMatches(ruling)
        .length;
    expect(listed, stated,
        reason: 'the ruling says $stated tables and lists $listed');
  });

  test('every listed table exists in 03\'s @DriftDatabase tables block', () {
    final Set<String> schema = _schemaTables(File(_schema).readAsStringSync());
    expect(schema, isNotEmpty, reason: 'could not read the tables block');

    for (final RegExpMatch m
        in RegExp(r'^\s*\d+\.\s+`(\w+)`', multiLine: true).allMatches(ruling)) {
      expect(schema, contains(m.group(1)),
          reason: 'the ruling names a table the schema does not have: '
              '${m.group(1)}');
    }
  });

  test('02-build-manifest.md §4.5 no longer lists P1 as blocking', () {
    final String manifest = File(_manifest).readAsStringSync();
    for (final String line in manifest.split('\n')) {
      if (!line.contains('P1')) {
        continue;
      }
      for (final String marker in <String>[
        'blocking conflict',
        'remaining blocking',
        'must land before',
      ]) {
        expect(line, isNot(contains(marker)),
            reason: 'the manifest and the ruling disagree:\n$line');
      }
    }
    expect(manifest, contains('P1'),
        reason: 'P1 was deleted rather than moved; §4 keeps ruled items with '
            'the same shape it uses for P2 and P8');
  });

  test('the three CSV shapes in 09 carry struck and struck_at', () {
    // Indelible screen 11: "every CSV carries a `struck` and a `struck_at`
    // column and every struck row is included and marked, because an export
    // that quietly drops the strikes would undo the one thing this app is for."
    final List<String> lines = File(_exports).readAsLinesSync();

    // Line-scoped throughout, so a failure names what is missing rather than
    // printing the whole document back.
    for (final String shape in <String>[
      'lambs.csv',
      'ewes.csv',
      'treatments.csv',
    ]) {
      expect(lines.any((String l) => l.contains(shape)), isTrue,
          reason: '09 does not name $shape');
    }
    for (final String column in <String>['struck', 'struck_at']) {
      expect(lines.any((String l) => l.contains(column)), isTrue,
          reason: '09 does not carry the $column column on any shape');
    }
    for (final String line in lines) {
      expect(line, isNot(contains('WHERE struck = 0')),
          reason: 'an export query that filters struck rows out is a defect:\n'
              '$line');
    }
  });

  test('the ruling states the count-versus-history default', () {
    // N06's eight statistics are the dangerous readers: a struck lambing must
    // leave BOTH the numerator and the denominator, or striking a mistyped
    // record changes a number the shepherd compares against last year.
    expect(ruling.toLowerCase(), contains('excluded from every count'),
        reason: 'the ruling does not say which side struck rows fall on, so '
            'N06 has to guess');
    expect(ruling.toLowerCase(), contains('included in every history'),
        reason: 'the ruling does not state the history half of the default');
  });
}

// Four open questions become migrations on somebody else's phone if they
// survive the freeze in N07-T08. After that point the only remaining answer to
// any of them is a migration running unattended, in April, in an app whose only
// backup is one the user remembered to make.
//
// The parser is `test/support/decision_record.dart`, lifted there in this
// task's Refactor step when this file became its second consumer.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/decision_record.dart';

/// Decision-record §7.1 items 10, 11, 13 and 15. Named, so the anchor cannot
/// pass on a §7.1 where nobody has tagged anything yet.
const List<int> schemaShapedQuestions = <int>[10, 11, 13, 15];

/// The three columns `03 §2` point 5 forbids a `DEFAULT` on, because a default
/// there would encode veterinary advice. §12.1 is held at *unpersistable* by
/// the absence of a default; a default drops it to *documented*, which means
/// deleted.
const List<String> adviceColumns = <String>['days', 'ease', 'status'];

/// Every place the lambing-ease upper bound is spelled. Five spellings of one
/// number is how a scale widens by accident.
const List<String> easeBoundSources = <String>[
  decisionRecordPath,
  'docs/engineering/03-data-model-and-schema.md',
  'docs/engineering/CONVENTIONS.md',
];

final RegExp _tableDotColumn = RegExp(r'\b([a-z][a-z0-9_]*)\.([a-z][a-z0-9_]*)\b');

/// Suffixes that make a `foo.bar` match a file path rather than a column.
const List<String> _fileSuffixes = <String>[
  'dart', 'md', 'yaml', 'yml', 'json', 'png', 'sqlite', 'arb', 'txt', 'kts',
];

bool namesATableAndColumn(String text) => _tableDotColumn
    .allMatches(text)
    .any((RegExpMatch m) => !_fileSuffixes.contains(m.group(2)));

void main() {
  final String record = readDecisionRecord();
  final List<OpenQuestion> questions =
      parseOpenQuestions(section(record, '### 7.1 Still open'));
  final Set<int> settled =
      parseSettledNumbers(section(record, '### 7.0 SETTLED BY THE OWNER'));

  final List<OpenQuestion> schemaShaped = questions
      .where((OpenQuestion q) => q.shapes.contains('schema-shaped'))
      .toList();

  test('every decision-record row marked schema-shaped carries a ruling and '
      'a date', () {
    expect(
      schemaShaped.map((OpenQuestion q) => q.number).toSet(),
      containsAll(schemaShapedQuestions),
      reason: 'items $schemaShapedQuestions are the four that expire at the '
          'first schema snapshot',
    );

    expect(
      schemaShaped
          .where((OpenQuestion q) => !q.isRuled)
          .map((OpenQuestion q) => q.number)
          .toList(),
      isEmpty,
      reason: 'these expire at N07-T08 and carry no RULED line; after the '
          'freeze the only answer left is a migration on a shepherd\'s phone',
    );
  });

  test('each schema-shaped ruling names a table and a column', () {
    for (final OpenQuestion q in schemaShaped) {
      expect(q.ruledReason, isNotNull, reason: 'item ${q.number}');
      expect(
        namesATableAndColumn(q.ruledReason!),
        isTrue,
        reason: 'item ${q.number}\'s ruling names no snake_case table.column, '
            'so N07 has nothing to implement:\n${q.ruledReason}',
      );
    }
  });

  test('no ruling introduces a DEFAULT on an advice column', () {
    for (final OpenQuestion q in schemaShaped) {
      final String text = q.text;
      for (final String column in adviceColumns) {
        // Word-bounded: an unanchored `contains('ease')` also matches
        // "release", "increase" and "please", which is a false red waiting to
        // happen in prose about a culled ewe releasing her tag.
        final RegExp word = RegExp('\\b$column\\b');
        for (final String spelling in <String>['withDefault', 'DEFAULT']) {
          // Only a defaulted advice column is a violation; the words may
          // legitimately appear apart. Both on one line is the failure.
          for (final String line in text.split('\n')) {
            if (line.contains(spelling) && word.hasMatch(line)) {
              fail('item ${q.number} puts a default on the $column column, '
                  'which drops §12.1 from unpersistable to documented:\n$line');
            }
          }
        }
      }
    }
  });

  test('the lambing ease bound is stated once', () {
    final Set<String> bounds = <String>{};
    for (final String path in easeBoundSources) {
      for (final String line in File(path).readAsLinesSync()) {
        final String lower = line.toLowerCase();
        if (!lower.contains('ease')) {
          continue;
        }
        for (final RegExpMatch m
            in RegExp(r'BETWEEN 1 AND (\d+)').allMatches(line)) {
          bounds.add(m.group(1)!);
        }
        for (final RegExpMatch m in RegExp(r'\b1\.\.(\d+)').allMatches(line)) {
          bounds.add(m.group(1)!);
        }
      }
    }
    expect(bounds, isNotEmpty, reason: 'no ease bound found at all');
    expect(bounds, <String>{'5'},
        reason: 'the ease scale is spelled with more than one upper bound: '
            '$bounds. Five spellings of one number is how a scale widens by '
            'accident');
  });

  test('§7.0 and §7.1 agree', () {
    for (final OpenQuestion q in schemaShaped) {
      expect(settled, contains(q.number),
          reason: 'item ${q.number} is ruled in §7.1 with no SETTLED row in '
              '§7.0');
    }
  });

  test('no engineering document still calls one of the four open', () {
    const List<String> openMarkers = <String>[
      'still open',
      'owner-blocked',
      'unresolved',
      'undecided',
      'is open',
      'remains open',
      'not settled',
    ];

    final Directory docs = Directory('docs/engineering');
    for (final FileSystemEntity entity in docs.listSync()) {
      if (entity is! File || !entity.path.endsWith('.md')) {
        continue;
      }
      for (final String line in entity.readAsLinesSync()) {
        final String lower = line.toLowerCase();
        for (final int number in schemaShapedQuestions) {
          final bool namesIt = lower.contains('§7.1 #$number') ||
              lower.contains('§7.1 q$number') ||
              lower.contains('open question $number') ||
              lower.contains('question $number');
          if (!namesIt) {
            continue;
          }
          for (final String marker in openMarkers) {
            expect(lower, isNot(contains(marker)),
                reason: '${entity.path} still calls question $number open:\n'
                    '$line');
          }
        }
      }
    }
  });
}

// The two dependency-shaped open questions expire the moment `pubspec.yaml`
// closes in N00-T03. This file holds the property that neither can survive it:
// a §7.1 item tagged `dependency-shaped` with no ruling beneath it is a
// question somebody is about to answer by accident.
//
// The parser lived privately in this file until N00-T04 became its second
// consumer; it is now `test/support/decision_record.dart` and this file is one
// of its two callers.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/decision_record.dart';

/// The placeholder outcomes that do not count as a reason.
const List<String> placeholderReasons = <String>['TBD', 'TODO', 'pending', '?'];

void main() {
  final String record = readDecisionRecord();
  final String stillOpen = section(record, '### 7.1 Still open');
  final String settled = section(record, '### 7.0 SETTLED BY THE OWNER');
  final List<OpenQuestion> questions = parseOpenQuestions(stillOpen);

  test('no decision-record row marked dependency-shaped is still open', () {
    expect(questions, isNotEmpty, reason: '§7.1 parsed to nothing');

    final List<OpenQuestion> dependencyShaped = questions
        .where((OpenQuestion q) => q.shapes.contains('dependency-shaped'))
        .toList();

    // Named, so the anchor cannot pass on a §7.1 where nobody has tagged
    // anything yet. A filter over an empty set is green having checked nothing,
    // which is the failure mode this whole backlog is written against.
    expect(
      dependencyShaped.map((OpenQuestion q) => q.number).toSet(),
      containsAll(<int>[16, 18]),
      reason: 'in-app printing (16) and the voice-note cap (18) are the two '
          'questions that expire when pubspec.yaml closes',
    );

    expect(
      dependencyShaped
          .where((OpenQuestion q) => !q.isRuled)
          .map((OpenQuestion q) => q.number)
          .toList(),
      isEmpty,
      reason: 'these dependency-shaped questions expire when pubspec.yaml '
          'closes and carry no RULED line',
    );
  });

  test('every ruled row carries a reason and an ISO date', () {
    for (final OpenQuestion q in questions.where((OpenQuestion q) => q.isRuled)) {
      expect(q.ruledDate, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')),
          reason: 'item ${q.number}');
      expect(q.ruledReason, isNotNull, reason: 'item ${q.number}');
      expect(q.ruledReason!.length, greaterThan(20),
          reason: 'item ${q.number}: a ruling without a reason gets reopened');
      for (final String placeholder in placeholderReasons) {
        expect(q.ruledReason, isNot(equals(placeholder)),
            reason: 'item ${q.number}');
      }
    }
  });

  test('a ruled row is struck, not deleted', () {
    // §6 of the decision record exists so a re-read of a raw research note
    // cannot reinstate an overturned claim. Deleting a ruled row is how the
    // question gets reopened from the notes in three months.
    for (final OpenQuestion q in questions.where((OpenQuestion q) => q.isRuled)) {
      expect(q.isStruck, isTrue,
          reason: 'item ${q.number} is ruled but its question text is gone');
    }
  });

  test('every surviving question carries exactly one shape tag', () {
    for (final OpenQuestion q in questions) {
      expect(q.shapes, hasLength(1),
          reason: 'item ${q.number} carries ${q.shapes}; one shape decides '
              'which artefact it expires into');
    }
  });

  test('§7.0 and §7.1 agree', () {
    final Set<int> settledIn70 = parseSettledNumbers(settled);
    for (final OpenQuestion q in questions.where((OpenQuestion q) => q.isRuled)) {
      expect(settledIn70, contains(q.number),
          reason: 'item ${q.number} is struck in §7.1 with no SETTLED row '
              'in §7.0');
    }
  });

  test('no document still calls either question open', () {
    // Item 16 is in-app printing; item 18 is the voice-note cap.
    const Map<int, List<String>> references = <int, List<String>>{
      16: <String>['§7.1 #16', '§7.1 q16', 'question 16', 'open question 16'],
      18: <String>['§7.1 #18', '§7.1 q18', 'question 18', 'open question 18'],
    };
    const List<String> openMarkers = <String>[
      'still open',
      'owner-blocked',
      'unresolved',
      'undecided',
      'is open',
      'remains open',
    ];
    const List<String> documents = <String>[
      'docs/engineering/09-export-formats.md',
      'docs/engineering/04-migrations-media-backup-restore.md',
    ];

    for (final String path in documents) {
      final List<String> lines = File(path).readAsLinesSync();

      // Line-scoped, so a failure names the offending line rather than
      // printing the document.
      for (final String line in lines) {
        expect(line, isNot(contains('owner-blocked')),
            reason: '$path still marks something owner-blocked:\n$line');
      }

      for (final String line in lines) {
        final String lower = line.toLowerCase();
        for (final MapEntry<int, List<String>> entry in references.entries) {
          final bool namesIt =
              entry.value.any((String r) => lower.contains(r.toLowerCase()));
          if (!namesIt) {
            continue;
          }
          for (final String marker in openMarkers) {
            expect(lower, isNot(contains(marker)),
                reason: '$path still calls question ${entry.key} open:\n$line');
          }
        }
      }
    }
  });

  test('the ruled cap is one value, and 04 no longer offers two', () {
    final String media =
        File('docs/engineering/04-migrations-media-backup-restore.md')
            .readAsStringSync();
    expect(media, isNot(contains('60 s or 120 s')),
        reason: '04 §4.4 still poses the question the record has ruled');
  });
}

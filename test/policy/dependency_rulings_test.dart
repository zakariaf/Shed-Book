// The two dependency-shaped open questions expire the moment `pubspec.yaml`
// closes in N00-T03. This file holds the property that neither can survive it:
// a §7.1 item tagged `dependency-shaped` with no ruling beneath it is a
// question somebody is about to answer by accident.
//
// The parser here is deliberately private. N00-T04 is its second consumer and
// lifts it to `test/support/decision_record.dart` in that task's Refactor step.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _decisionRecord = 'docs/research/00-tech-decisions.md';

/// The shape tag every surviving §7.1 item carries. A question is answered by
/// whoever owns the artefact it expires into: the pubspec, the schema freeze,
/// somebody else's diary, or the product.
const List<String> shapeTags = <String>[
  'dependency-shaped',
  'schema-shaped',
  'calendar-shaped',
  'product-shaped',
];

/// The placeholder outcomes that do not count as a reason.
const List<String> _placeholderReasons = <String>['TBD', 'TODO', 'pending', '?'];

/// One numbered item of decision-record §7.1.
class OpenQuestion {
  const OpenQuestion({
    required this.number,
    required this.shapes,
    required this.isStruck,
    required this.ruledDate,
    required this.ruledReason,
    required this.text,
  });

  final int number;
  final List<String> shapes;
  final bool isStruck;
  final String? ruledDate;
  final String? ruledReason;
  final String text;

  bool get isRuled => ruledDate != null;
}

/// Everything between a heading and the next heading or horizontal rule.
String _section(String document, String heading) {
  final List<String> lines = document.split('\n');
  final int start = lines.indexWhere((String l) => l.trim() == heading);
  if (start < 0) {
    fail('$_decisionRecord has no heading "$heading"');
  }
  final int end = lines.indexWhere(
    (String l) => l.startsWith('## ') || l.trim() == '---',
    start + 1,
  );
  return lines.sublist(start + 1, end < 0 ? lines.length : end).join('\n');
}

final RegExp _itemStart = RegExp(r'^(\d+)\.\s');
// multiLine, because a `RULED` line is not always the last line of its item —
// the last item in §7.1 is followed by a blank line before the horizontal rule.
final RegExp _ruled =
    RegExp(r'RULED (\d{4}-\d{2}-\d{2}) — (.+?)\**\s*$', multiLine: true);

/// Parses §7.1's numbered prose list into items. §7.1 is prose and not a table,
/// so the shape tag and the `RULED` line are what make it machine-readable at
/// all — that is why N00-T02 introduces them rather than tidying them.
List<OpenQuestion> ruledRows(String section) {
  final List<OpenQuestion> items = <OpenQuestion>[];
  final List<String> lines = section.split('\n');

  int? number;
  List<String> body = <String>[];

  void flush() {
    if (number == null) {
      return;
    }
    final String text = body.join('\n');
    final RegExpMatch? ruled = _ruled.firstMatch(text);
    items.add(OpenQuestion(
      number: number!,
      shapes: shapeTags.where((String t) => text.contains('`$t`')).toList(),
      isStruck: text.contains('~~'),
      ruledDate: ruled?.group(1),
      ruledReason: ruled?.group(2)?.trim(),
      text: text,
    ));
  }

  for (final String line in lines) {
    final RegExpMatch? start = _itemStart.firstMatch(line);
    if (start != null) {
      flush();
      number = int.parse(start.group(1)!);
      body = <String>[line];
    } else if (number != null) {
      body.add(line);
    }
  }
  flush();
  return items;
}

/// The question numbers §7.0's SETTLED table claims. Its `#` cell carries forms
/// like `5 + 6`, so every integer in the cell counts.
Set<int> settledNumbers(String section) {
  final Set<int> numbers = <int>{};
  for (final String line in section.split('\n')) {
    if (!line.startsWith('|') || line.contains('---')) {
      continue;
    }
    final List<String> cells = line.split('|');
    if (cells.length < 2) {
      continue;
    }
    final String cell = cells[1].trim();
    if (cell == '#') {
      continue;
    }
    numbers.addAll(
      RegExp(r'\d+').allMatches(cell).map((Match m) => int.parse(m.group(0)!)),
    );
  }
  return numbers;
}

void main() {
  final String record = File(_decisionRecord).readAsStringSync();
  final String stillOpen = _section(record, '### 7.1 Still open');
  final String settled = _section(record, '### 7.0 SETTLED BY THE OWNER');
  final List<OpenQuestion> questions = ruledRows(stillOpen);

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
      for (final String placeholder in _placeholderReasons) {
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
    final Set<int> settledIn70 = settledNumbers(settled);
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

// The decision record's §7 parser, lifted here in N00-T04's Refactor step when
// `schema_shaped_rulings_test.dart` became its second consumer. It lived
// privately inside `dependency_rulings_test.dart` until then, which was the
// right place for one caller.
//
// §7.1 is a numbered prose list rather than a table, and a test cannot reliably
// parse "OPEN" out of prose. The two markers it reads instead — a shape tag in
// backticks and a `RULED <date> — <sentence>` line — were introduced by N00-T02
// for exactly this reason. Both anchors parse the identical markers, so getting
// the shape wrong costs two tasks rather than one.
library;

import 'dart:io';

/// Repository-relative, because `flutter test`'s working directory is the
/// repository root.
const String decisionRecordPath = 'docs/research/00-tech-decisions.md';

/// The shape tag every surviving §7.1 item carries. A question is answered by
/// whoever owns the artefact it expires into: the pubspec, the schema freeze,
/// somebody else's diary, or the product.
const List<String> shapeTags = <String>[
  'dependency-shaped',
  'schema-shaped',
  'calendar-shaped',
  'product-shaped',
];

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

/// Thrown when the record's shape has changed under the parser. Failing loudly
/// beats returning an empty list, which every filter in every caller would
/// then pass vacuously.
class DecisionRecordFormatException implements Exception {
  DecisionRecordFormatException(this.message);
  final String message;
  @override
  String toString() => 'DecisionRecordFormatException: $message';
}

String readDecisionRecord() => File(decisionRecordPath).readAsStringSync();

/// Everything between [heading] and the next `## ` heading or horizontal rule.
String section(String document, String heading) {
  final List<String> lines = document.split('\n');
  final int start = lines.indexWhere((String l) => l.trim() == heading);
  if (start < 0) {
    throw DecisionRecordFormatException(
        '$decisionRecordPath has no heading "$heading"');
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

/// Parses §7.1's numbered prose list into items.
List<OpenQuestion> parseOpenQuestions(String stillOpenSection) {
  final List<OpenQuestion> items = <OpenQuestion>[];
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

  for (final String line in stillOpenSection.split('\n')) {
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

  if (items.isEmpty) {
    throw DecisionRecordFormatException('§7.1 parsed to no items');
  }
  return items;
}

/// The question numbers §7.0's SETTLED table claims. Its `#` cell carries forms
/// like `5 + 6`, so every integer in the cell counts.
Set<int> parseSettledNumbers(String settledSection) {
  final Set<int> numbers = <int>{};
  for (final String line in settledSection.split('\n')) {
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

// The pull request is where the safety review happens. Spec §12 says the five
// rules *"should be visible in the code review checklist"*, and a checklist is
// the WEAKEST mechanism in 00-README §2.3's hierarchy — unrepresentable →
// unconstructible → unpersistable → caught by a test on the source text →
// documented. Each of the five is already pushed as far up it as it will go.
// This template is the residue: the part no type and no CHECK constraint can
// hold, in front of the one person who can.
//
// Nothing enforces a tick, and that is not a defect to be engineered away.
// GitHub does not block a merge on an unchecked box and no CI job can read
// intent. The template's job is to make the question unavoidable, not to make
// the answer mandatory.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _template = '.github/pull_request_template.md';
const String _spec = 'shed-book-spec.md';

/// `CODE-REVIEW-CHECKLIST` §2.2–§2.6, the five rules in their diff-shaped form.
/// The statement alone is a rule; the question is a review.
const List<String> diffShapedQuestions = <String>[
  'Does anything in this diff put a number in a withdrawal field that the user '
      'did not read off the bottle?',
  'Does this diff originate a number or a judgement, rather than transform one '
      'the user supplied?',
  'Does this diff produce an artefact a shepherd could hand to an inspector, '
      'without the footer that says it is not one?',
  'Does this diff change a value the user entered, on the way in or on the way '
      'out?',
  'Does every event time this diff writes or renders carry its provenance?',
];

/// `CODE-REVIEW-CHECKLIST` §3.1, in order. The case that fires when somebody
/// re-sorts it alphabetically.
const List<String> readingOrder = <String>[
  'pubspec.yaml',
  'lib/core/db/tables/**',
  'lib/data/**',
  'lib/domain/withdrawal/',
  'lib/l10n/app_en.arb',
  'lib/features/**',
];

/// `CONVENTIONS §5.3`. The ban is on OUR OWN PROSE claiming to be one of these,
/// never on quoting the spec rule that forbids it — so §12.3's quoted sentence
/// is excluded before this list is applied.
const List<String> bannedWords = <String>[
  'draft',
  'isDirty',
  'save()',
  'commit()',
  'submit()',
  'sync',
  'offline-first',
  'your data never leaves your phone',
  'official record',
];

/// Spec §12's five numbered rules, read at RUN TIME. Hard-coding them here
/// would make the test and the template two copies that agree with each other
/// and can both drift from the spec.
List<String> specSafetyRules() {
  final List<String> lines = File(_spec).readAsLinesSync();
  final int start = lines.indexWhere((String l) => l.startsWith('## 12. Safety'));
  // A throw and not an `expect`: this runs at main() top level, outside any
  // test, where `expect` raises OutsideTestException and the whole file fails
  // to load rather than failing usefully.
  if (start < 0) {
    throw StateError('$_spec has no §12');
  }
  final int end = lines.indexWhere((String l) => l.startsWith('## 13.'), start);

  final List<String> rules = <String>[];
  for (final String line in lines.sublist(start, end < 0 ? lines.length : end)) {
    final RegExpMatch? m = RegExp(r'^\d+\.\s+(.*)$').firstMatch(line);
    if (m != null) {
      // Strip the `**` emphasis; the template wraps the same text differently.
      rules.add(m.group(1)!.replaceAll('**', '').trim());
    }
  }
  return rules;
}

void main() {
  final String template = File(_template).readAsStringSync();

  /// Emphasis stripped from BOTH sides and whitespace collapsed, so the
  /// comparison is about the words and not about where markdown puts its
  /// asterisks. The template writes `**§12.1 — Never default …**`, which puts
  /// a `**` between "period." and "The user" and breaks contiguity with the
  /// spec's own sentence.
  String normalise(String s) =>
      s.replaceAll('**', '').replaceAll('*', '').replaceAll(RegExp(r'\s+'), ' ');

  final String flat = normalise(template);
  final List<String> rules = specSafetyRules();

  test('the template carries all five §12 questions verbatim', () {
    expect(rules, hasLength(5), reason: 'spec §12 parsed to ${rules.length}');
    for (final String rule in rules) {
      // Character for character, whitespace-normalised so the template may
      // wrap where it likes. A spec edit turns this red until the template
      // follows, which is the point.
      // `isTrue` and not `contains`, so a failure prints the missing RULE
      // rather than the whole template back at you.
      expect(
        flat.contains(normalise(rule)),
        isTrue,
        reason: 'the template paraphrases or omits:\n$rule',
      );
    }
  });

  test('the template asks each rule as a question of the diff', () {
    for (final String question in diffShapedQuestions) {
      expect(
        flat.contains(normalise(question)),
        isTrue,
        reason: 'missing the diff-shaped question:\n$question',
      );
    }
  });

  test('the template carries the six-row irreversibility reading order, in '
      'order', () {
    int cursor = -1;
    for (final String entry in readingOrder) {
      final int at = template.indexOf(entry, cursor + 1);
      expect(
        at,
        greaterThan(cursor),
        reason:
            '"$entry" is missing or out of order. The order is '
            'irreversibility, not the order the diff prints',
      );
      cursor = at;
    }
  });

  test('the template carries the one Quick Entry question', () {
    // §3.4 — the question that decides whether a change lands on the 3am path
    // at all.
    expect(
      flat.contains('Does the shepherd have to do anything new before the record exists?'),
      isTrue,
    );
  });

  test('exactly one pull request template exists in the repository', () {
    // GitHub's rules here are a trap. A single file at
    // .github/pull_request_template.md is applied automatically. A DIRECTORY
    // named .github/PULL_REQUEST_TEMPLATE/ means MULTIPLE templates and none
    // is applied by default — the author has to pass a query parameter. The
    // repository root and docs/ are also searched. Two is undefined behaviour;
    // a directory is silence.
    final List<String> found = <String>[];
    for (final String directory in <String>['.github', '.', 'docs']) {
      final Directory d = Directory(directory);
      if (!d.existsSync()) {
        continue;
      }
      for (final FileSystemEntity entity in d.listSync()) {
        final String name = entity.uri.pathSegments
            .where((String s) => s.isNotEmpty)
            .last
            .toLowerCase();
        if (name.replaceAll('-', '_').startsWith('pull_request_template')) {
          found.add(entity.path);
        }
      }
    }
    expect(found, hasLength(1), reason: 'found: $found');
    expect(
      Directory('.github/PULL_REQUEST_TEMPLATE').existsSync(),
      isFalse,
      reason:
          'a PULL_REQUEST_TEMPLATE directory means none is applied by '
          'default',
    );
  });

  test('the template contains no banned word', () {
    // CONVENTIONS §5.3 over the template's OWN prose. The quoted spec §12.3
    // sentence is excluded first: the ban is on our prose claiming to be a
    // compliance record, not on quoting the rule that forbids it.
    final List<String> quotedSpec = rules.map(normalise).toList();
    String ownProse = flat;
    for (final String quoted in quotedSpec) {
      ownProse = ownProse.replaceAll(quoted, ' ');
    }

    for (final String banned in bannedWords) {
      expect(
        RegExp('\\b${RegExp.escape(banned)}', caseSensitive: false).hasMatch(ownProse),
        isFalse,
        reason: 'the template uses the banned word "$banned"',
      );
    }
  });
}

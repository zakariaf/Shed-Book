// `@Tags` is a library annotation and must be the FIRST thing in the file,
// above every import, followed by a bare `library;`. Put it after an import and
// it is silently ignored — the test still runs, the tag does not exist, and the
// exclusion N01-T05 and N01-T06 rely on quietly does nothing.
@Tags(<String>['calendar'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// This file is EXPECTED TO FAIL until N32 closes the last commitment, and its
// failure message is the deliverable. "Green" for N00-T06 means it compiles,
// parses the ledger, and names the incomplete rows by key rather than counting
// them.
//
// A row is never deleted to make it pass.
// ─────────────────────────────────────────────────────────────────────────────

const String _ledger = 'docs/calendar.md';

/// The seven the plan critique names. The key set is asserted to equal this
/// exactly, so a row cannot be quietly dropped.
const List<String> commitmentKeys = <String>[
  'field_night',
  'twelve_testers',
  'ziplock_capacitance',
  'developer_accounts',
  'apple_sbp_enrolment',
  'price_and_territories',
  'store_identifiers',
];

/// Cells that look filled in and are not.
const List<String> placeholderOutcomes = <String>[
  '—',
  '-',
  'TBD',
  '?',
  'pending',
  'TODO',
  'n/a',
  'N/A',
];

final RegExp _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Spec §3's channels. The audience is smallholders and small commercial
/// flocks, 20–400 ewes, lambing indoors or in a field within walking distance,
/// one or two people doing all the work, often alongside a day job.
const List<String> recruitmentChannels = <String>[
  'The Farming Forum',
  'Accidental Smallholder',
  'r/sheep',
  'r/homestead',
  'National Sheep Association',
  'breed societ',
  'NFU',
  'young farmer',
];

/// `recorded := an ISO civil date, YYYY-MM-DD, and nothing else`.
bool isRecordedDate(String cell) => _isoDate.hasMatch(cell.trim());

/// `outcome := a non-empty cell that is not a placeholder`.
bool isRealOutcome(String cell) {
  final String trimmed = cell.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  return !placeholderOutcomes
      .any((String p) => p.toLowerCase() == trimmed.toLowerCase());
}

class Commitment {
  const Commitment({
    required this.key,
    required this.commitment,
    required this.owner,
    required this.due,
    required this.recorded,
    required this.outcome,
    required this.consequence,
  });

  final String key;
  final String commitment;
  final String owner;
  final String due;
  final String recorded;
  final String outcome;
  final String consequence;

  bool get isComplete =>
      owner.trim().isNotEmpty && isRecordedDate(recorded) && isRealOutcome(outcome);

  /// What is missing, for the failure message. Named, never counted.
  String get missing {
    final List<String> gaps = <String>[
      if (owner.trim().isEmpty) 'no owner',
      if (!isRecordedDate(recorded)) 'no date',
      if (!isRealOutcome(outcome)) 'no outcome',
    ];
    return gaps.isEmpty ? 'complete' : gaps.join(', ');
  }
}

/// Splits the Markdown table on `|`. Not a regex over prose: a row's key is
/// `snake_case` inside backticks so a later commit can say "turn
/// `ziplock_capacitance` green" and mean exactly one row.
List<Commitment> parseLedger(String markdown) {
  final List<Commitment> rows = <Commitment>[];
  for (final String line in markdown.split('\n')) {
    if (!line.startsWith('| `')) {
      continue;
    }
    final List<String> cells =
        line.split('|').map((String c) => c.trim()).toList();
    // A leading and a trailing empty cell come from the outer pipes.
    if (cells.length < 9) {
      continue;
    }
    rows.add(Commitment(
      key: cells[1].replaceAll('`', '').trim(),
      commitment: cells[2],
      owner: cells[3],
      due: cells[4],
      recorded: cells[5],
      outcome: cells[6],
      consequence: cells[7],
    ));
  }
  return rows;
}

void main() {
  final List<Commitment> ledger =
      parseLedger(File(_ledger).readAsStringSync());

  test('every commitment in docs/calendar.md has an owner, a date and an '
      'outcome', () {
    expect(ledger, isNotEmpty, reason: '$_ledger parsed to no rows');

    final List<Commitment> incomplete =
        ledger.where((Commitment c) => !c.isComplete).toList();
    if (incomplete.isEmpty) {
      return;
    }

    final int width = incomplete
        .map((Commitment c) => c.key.length)
        .reduce((int a, int b) => a > b ? a : b);
    final String named = incomplete
        .map((Commitment c) => '  ${c.key.padRight(width)} — ${c.missing}')
        .join('\n');

    fail('${incomplete.length} of ${ledger.length} commitments are not '
        'recorded:\n$named');
  });

  test('the ledger carries exactly the seven commitments the critique names',
      () {
    expect(ledger.map((Commitment c) => c.key).toSet(),
        commitmentKeys.toSet(),
        reason: 'a row was added or dropped; a row is never deleted to make '
            'the anchor pass');
  });

  test('a recorded date is an ISO civil date', () {
    // The predicate, not the file — so it holds while the cells are empty.
    expect(isRecordedDate('2026-03-11'), isTrue);
    for (final String notADate in <String>[
      '11 Mar 2026',
      'Mar 2026',
      'soon',
      '11/03/2026',
      '2026-3-11',
      '',
    ]) {
      expect(isRecordedDate(notADate), isFalse, reason: '"$notADate"');
    }
  });

  test('a placeholder outcome does not count as recorded', () {
    expect(isRealOutcome('Booked at Ty Coch, 180 ewes, ~8 lambings'), isTrue);
    for (final String placeholder in placeholderOutcomes) {
      expect(isRealOutcome(placeholder), isFalse, reason: '"$placeholder"');
    }
    expect(isRealOutcome('   '), isFalse);
  });

  test('every row states what happens if it does not happen', () {
    // A commitment with no consequence is a wish.
    for (final Commitment c in ledger) {
      expect(c.consequence.trim(), isNotEmpty, reason: c.key);
      expect(isRealOutcome(c.consequence), isTrue, reason: c.key);
    }
  });

  // ───────────────────────────────────────────────────────────────────────
  // N00-T07 — the field night and the twelve testers.
  // ───────────────────────────────────────────────────────────────────────

  Commitment row(String key) =>
      ledger.firstWhere((Commitment c) => c.key == key);

  test('the field night row and the twelve-tester row both carry a date', () {
    for (final String key in <String>['field_night', 'twelve_testers']) {
      expect(row(key).isComplete, isTrue,
          reason: '$key — ${row(key).missing}');
    }
  });

  test('the field night row names a location', () {
    // A night with no shed named has not been booked. Deliberately NOT a
    // check that the date is in the future: see 'the test reads no clock'.
    final String outcome = row('field_night').outcome;
    expect(isRealOutcome(outcome), isTrue,
        reason: 'field_night — ${row('field_night').missing}');
    expect(outcome.length, greaterThan(20),
        reason: 'the outcome must name the shed, the flock size and roughly '
            'how many lambings are expected. A night with two lambings is a '
            'visit, not an observation');
  });

  test('the twelve-tester row names at least one channel from spec §3', () {
    // So that "posted somewhere" cannot pass. Deliberately NOT `count >= 12`:
    // that would go red every time somebody drops out, in an epic that merged
    // months earlier, on a `main` everyone expects to be green.
    final String outcome = row('twelve_testers').outcome;
    expect(isRealOutcome(outcome), isTrue,
        reason: 'twelve_testers — ${row('twelve_testers').missing}');
    expect(
      recruitmentChannels.any(
          (String c) => outcome.toLowerCase().contains(c.toLowerCase())),
      isTrue,
      reason: 'the outcome names no channel from spec §3. It should also carry '
          'both numbers — said yes, and opted in — because they diverge and '
          'the second is the one N32-T03 needs',
    );
  });

  test('the test reads no clock', () {
    // A policy test on a policy test, and it earns its place: it is what stops
    // somebody adding a recency check in six months and making the suite fail
    // once a year, for an hour, in the ambiguous 01:00–01:59.
    final String source =
        File('test/policy/calendar_commitments_test.dart').readAsStringSync();
    // Assembled from halves so the needles do not appear contiguously in this
    // file and make the scan find itself. A self-matching source scan is
    // permanently red for the one reason that is not a defect.
    for (final String forbidden in <String>[
      'DateTime' '.now(',
      'clock' '.now(',
      'DateTime' '.timestamp(',
    ]) {
      expect(source.contains(forbidden), isFalse,
          reason: 'this test reads a clock: $forbidden');
    }
  });
}

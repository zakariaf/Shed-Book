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
  // **THE EIGHTH, ADDED AT N31-T04 AND NOT ONE OF THE CRITIQUE'S SEVEN.** G5's
  // observation half is the only claim in this project that no test can make:
  // G1 reads the permission set off a built artefact and G3 reads the imports,
  // and NEITHER WATCHES THE APP RUN. A dependency opening a socket from a
  // background isolate passes both.
  //
  // It is in the ledger rather than in a test because that is what the ledger is
  // for — a commitment somebody has to keep, with a named consequence if they do
  // not.
  'g5_observation',
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

/// The same shape, unanchored — a date quoted inside an outcome sentence.
final RegExp _isoDateAnywhere = RegExp(r'\d{4}-\d{2}-\d{2}');

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
  return !placeholderOutcomes.any((String p) => p.toLowerCase() == trimmed.toLowerCase());
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
    final List<String> cells = line.split('|').map((String c) => c.trim()).toList();
    // A leading and a trailing empty cell come from the outer pipes.
    if (cells.length < 9) {
      continue;
    }
    rows.add(
      Commitment(
        key: cells[1].replaceAll('`', '').trim(),
        commitment: cells[2],
        owner: cells[3],
        due: cells[4],
        recorded: cells[5],
        outcome: cells[6],
        consequence: cells[7],
      ),
    );
  }
  return rows;
}

void main() {
  final List<Commitment> ledger = parseLedger(File(_ledger).readAsStringSync());

  test('every commitment in docs/calendar.md has an owner, a date and an '
      'outcome', () {
    expect(ledger, isNotEmpty, reason: '$_ledger parsed to no rows');

    final List<Commitment> incomplete = ledger.where((Commitment c) => !c.isComplete).toList();
    if (incomplete.isEmpty) {
      return;
    }

    final int width = incomplete
        .map((Commitment c) => c.key.length)
        .reduce((int a, int b) => a > b ? a : b);
    final String named = incomplete
        .map((Commitment c) => '  ${c.key.padRight(width)} — ${c.missing}')
        .join('\n');

    fail(
      '${incomplete.length} of ${ledger.length} commitments are not '
      'recorded:\n$named',
    );
  });

  test('the ledger carries exactly the eight commitments — the critique seven plus G5', () {
    expect(
      ledger.map((Commitment c) => c.key).toSet(),
      commitmentKeys.toSet(),
      reason:
          'a row was added or dropped; a row is never deleted to make '
          'the anchor pass. Eight since N31-T04: the critique names seven and '
          'G5s observation half is the eighth',
    );
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

  Commitment row(String key) => ledger.firstWhere((Commitment c) => c.key == key);

  test('the field night row and the twelve-tester row both carry a date', () {
    for (final String key in <String>['field_night', 'twelve_testers']) {
      expect(row(key).isComplete, isTrue, reason: '$key — ${row(key).missing}');
    }
  });

  test('the field night row names a location', () {
    // A night with no shed named has not been booked. Deliberately NOT a
    // check that the date is in the future: see 'the test reads no clock'.
    final String outcome = row('field_night').outcome;
    expect(isRealOutcome(outcome), isTrue, reason: 'field_night — ${row('field_night').missing}');
    expect(
      outcome.length,
      greaterThan(20),
      reason:
          'the outcome must name the shed, the flock size and roughly '
          'how many lambings are expected. A night with two lambings is a '
          'visit, not an observation',
    );
  });

  test('the twelve-tester row names at least one channel from spec §3', () {
    // So that "posted somewhere" cannot pass. Deliberately NOT `count >= 12`:
    // that would go red every time somebody drops out, in an epic that merged
    // months earlier, on a `main` everyone expects to be green.
    final String outcome = row('twelve_testers').outcome;
    expect(
      isRealOutcome(outcome),
      isTrue,
      reason: 'twelve_testers — ${row('twelve_testers').missing}',
    );
    expect(
      recruitmentChannels.any((String c) => outcome.toLowerCase().contains(c.toLowerCase())),
      isTrue,
      reason:
          'the outcome names no channel from spec §3. It should also carry '
          'both numbers — said yes, and opted in — because they diverge and '
          'the second is the one N32-T03 needs',
    );
  });

  // ───────────────────────────────────────────────────────────────────────
  // N00-T08 — the ziplock-bag capacitance test.
  // ───────────────────────────────────────────────────────────────────────

  test('the ziplock row carries a date, a device and an outcome', () {
    expect(
      row('ziplock_capacitance').isComplete,
      isTrue,
      reason: 'ziplock_capacitance — ${row('ziplock_capacitance').missing}',
    );
  });

  test('the ziplock outcome names a device and an OS version', () {
    // "Passed" alone does not pass. Touch rejection and moisture heuristics
    // are firmware, and the same handset behaves differently across a major
    // OS release.
    final String outcome = row('ziplock_capacitance').outcome;
    expect(
      isRealOutcome(outcome),
      isTrue,
      reason: 'ziplock_capacitance — ${row('ziplock_capacitance').missing}',
    );
    expect(
      RegExp(r'\d+(\.\d+)?').hasMatch(outcome),
      isTrue,
      reason:
          'the outcome carries no version number, so it records a model '
          'and not a device',
    );
  });

  test('the ziplock row states its consequence', () {
    // By number, so a future reader cannot mistake the scope. This case can
    // pass before the measurement happens — the consequence is written BEFORE
    // the result is known, so the result cannot be argued with afterwards.
    final String consequence = row('ziplock_capacitance').consequence;
    for (final String decision in <String>['#100', '#101', '#102']) {
      expect(
        consequence,
        contains(decision),
        reason: 'the consequence does not name decision $decision',
      );
    }
  });

  // ───────────────────────────────────────────────────────────────────────
  // N00-T09 — the store accounts, SBP, price and territories.
  // ───────────────────────────────────────────────────────────────────────

  test('the developer-account, SBP, price and territories rows each carry a '
      'date and an outcome', () {
    for (final String key in <String>[
      'developer_accounts',
      'apple_sbp_enrolment',
      'price_and_territories',
      'store_identifiers',
    ]) {
      expect(row(key).isComplete, isTrue, reason: '$key — ${row(key).missing}');
    }
  });

  test('the developer-account row answers the 13 November 2023 question', () {
    // Explicitly yes or no, because the schedule downstream of it is different
    // in each case: a personal Play account created after that date must run a
    // twelve-tester, fourteen-day closed test before production access.
    final String outcome = row('developer_accounts').outcome.toLowerCase();
    expect(
      isRealOutcome(outcome),
      isTrue,
      reason: 'developer_accounts — ${row('developer_accounts').missing}',
    );
    expect(
      outcome.contains('yes') || outcome.contains('no'),
      isTrue,
      reason:
          'the outcome does not answer the 13 November 2023 question '
          'either way',
    );
  });

  test('the price row records where the store rate was read and when', () {
    // A rate from a secondary source is what 11 §10 warns against by name:
    // Google's own 30 June 2026 post does not state a one-time-product rate,
    // and the quoted 20% + 5% figure is secondary reporting.
    final Commitment price = row('price_and_territories');
    expect(
      isRealOutcome(price.outcome),
      isTrue,
      reason: 'price_and_territories — ${price.missing}',
    );
    expect(
      price.outcome.toLowerCase(),
      contains('play console'),
      reason: 'the outcome does not say the rate was read in Play Console',
    );
    expect(
      _isoDateAnywhere.hasMatch(price.outcome),
      isTrue,
      reason: 'the outcome does not carry the date the rate was read',
    );
  });

  test('the test reads no clock', () {
    // A policy test on a policy test, and it earns its place: it is what stops
    // somebody adding a recency check in six months and making the suite fail
    // once a year, for an hour, in the ambiguous 01:00–01:59.
    final String source = File('test/policy/calendar_commitments_test.dart').readAsStringSync();
    // Assembled from halves so the needles do not appear contiguously in this
    // file and make the scan find itself. A self-matching source scan is
    // permanently red for the one reason that is not a defect.
    for (final String forbidden in <String>[
      'DateTime'
          '.now(',
      'clock'
          '.now(',
      'DateTime'
          '.timestamp(',
    ]) {
      expect(source.contains(forbidden), isFalse, reason: 'this test reads a clock: $forbidden');
    }
  });
}

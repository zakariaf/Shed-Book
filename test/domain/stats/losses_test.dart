// test/domain/stats/losses_test.dart — lossesBreakdown.
//
// Relational: every age is a day OFFSET from the lambing date, never a
// wall-clock literal, so the hostile-zone run at UTC+12:45 reads the same.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/stats/losses.dart';
import 'package:shed_book/domain/stats/season_counts.dart';
import 'package:shed_book/domain/time/local_date.dart';

final LocalDate _born = LocalDate(2026, 3, 4);

LambOutcome _lamb({
  int id = 1,
  LambStatus status = LambStatus.dead,
  int? diedAfterDays = 0,
  String? causeKey,
}) => (
  lambId: id,
  status: status,
  lambingDate: _born,
  deathDate: diedAfterDays == null ? null : _born.plusDays(diedAfterDays),
  causeKey: causeKey,
);

void main() {
  test('stillborn is its own bucket and is never sameDay', () {
    // A stillborn lamb has no age at death. Folding it into "died at age 0"
    // double-counts against any "first 24 h losses" figure.
    final LossesBreakdown r = lossesBreakdown(<LambOutcome>[
      _lamb(status: LambStatus.stillborn, diedAfterDays: 0),
      _lamb(id: 2, diedAfterDays: 0),
    ]);

    expect(r.byAge[AgeBucket.stillborn], 1);
    expect(r.byAge[AgeBucket.sameDay], 1);
    expect(r.total, 2);
  });

  test('a death with no death_date is unknownAge and still counted in the total', () {
    final LossesBreakdown r = lossesBreakdown(<LambOutcome>[_lamb(diedAfterDays: null)]);

    expect(r.byAge[AgeBucket.unknownAge], 1);
    expect(r.total, 1, reason: 'the death is a fact even when the day is not');
  });

  test('a death with no cause is tallied under unattributed, never under unknown', () {
    final LossesBreakdown r = lossesBreakdown(<LambOutcome>[_lamb()]);

    expect(r.byCause[kUnattributed], 1);
    expect(r.byCause.containsKey('dc_unknown'), isFalse);
    expect(r.byCause.containsKey('unknown'), isFalse);
  });

  test('unattributed and dc_unknown are separate rows', () {
    // dc_unknown is a cause the user PICKED — "I looked and could not tell".
    // unattributed is "nobody has said". Merging them destroys the difference
    // between a shepherd who investigated and one who has not got to it yet.
    final LossesBreakdown r = lossesBreakdown(<LambOutcome>[
      _lamb(),
      _lamb(id: 2, causeKey: 'dc_unknown'),
      _lamb(id: 3, causeKey: 'dc_unknown'),
    ]);

    expect(r.byCause[kUnattributed], 1);
    expect(r.byCause['dc_unknown'], 2);
    expect(r.byCause.keys.length, 2);
  });

  test('a death_date before the lambing gives unknownAge plus a caveat', () {
    final LossesBreakdown r = lossesBreakdown(<LambOutcome>[_lamb(diedAfterDays: -1)]);

    expect(r.byAge[AgeBucket.unknownAge], 1);
    expect(r.total, 1);
    expect(
      r.caveats,
      contains('1 lamb has a death date before its lambing. Its age is not counted.'),
    );
    // The WarningCode.deathBeforeBirth half is checkLambing's (N06-T03), on the
    // record. This function reports the same fact as coverage on the tally, and
    // neither of them corrects the date.
  });

  test('a tagless dead lamb is counted', () {
    // Identity is the row id; there is no tag in LambOutcome at all, which is
    // the strongest form of "a tag cannot affect this arithmetic".
    final LossesBreakdown r = lossesBreakdown(<LambOutcome>[_lamb(id: 99)]);
    expect(r.total, 1);
  });

  test('day boundaries: 0→sameDay, 1 and 3→day1to3, 4 and 7→day4to7, '
      '8 and 30→day8to30, 31→over30', () {
    // Both ends of every bucket. The splits match Teagasc's published breakdown
    // — day 1–3 and day 4–7 — so a shepherd can compare our number to theirs
    // without arithmetic nobody does at the kitchen table.
    const Map<int, AgeBucket> expected = <int, AgeBucket>{
      0: AgeBucket.sameDay,
      1: AgeBucket.day1to3,
      3: AgeBucket.day1to3,
      4: AgeBucket.day4to7,
      7: AgeBucket.day4to7,
      8: AgeBucket.day8to30,
      30: AgeBucket.day8to30,
      31: AgeBucket.over30,
      400: AgeBucket.over30,
    };

    for (final MapEntry<int, AgeBucket> e in expected.entries) {
      final LossesBreakdown r = lossesBreakdown(<LambOutcome>[_lamb(diedAfterDays: e.key)]);
      expect(r.byAge[e.value], 1, reason: 'day ${e.key}');
      expect(r.byAge.keys.single, e.value, reason: 'day ${e.key} lands in exactly one bucket');
    }
  });

  test('a fostered lamb that died is counted once at season level', () {
    // Season-level counts are one row per lamb, and LambOutcome carries no
    // rearing dam — so there is no way for this function to count one twice. The
    // per-dam split ("lambs born to her that died" versus "lambs lost while
    // rearing") is a query's job, and never one number.
    final LossesBreakdown r = lossesBreakdown(<LambOutcome>[_lamb(id: 7, diedAfterDays: 2)]);

    expect(r.total, 1);
    expect(r.byAge.values.fold<int>(0, (int a, int b) => a + b), 1);
  });

  test('byAge totals equal total', () {
    final LossesBreakdown r = lossesBreakdown(<LambOutcome>[
      _lamb(diedAfterDays: 0),
      _lamb(id: 2, status: LambStatus.stillborn),
      _lamb(id: 3, diedAfterDays: null),
      _lamb(id: 4, diedAfterDays: 12, causeKey: 'dc_watery_mouth'),
      _lamb(id: 5, diedAfterDays: -2),
    ]);

    expect(r.byAge.values.fold<int>(0, (int a, int b) => a + b), r.total);
    expect(r.byCause.values.fold<int>(0, (int a, int b) => a + b), r.total);
    expect(r.total, 5);
  });

  test('alive and sold lambs are not losses', () {
    final LossesBreakdown r = lossesBreakdown(<LambOutcome>[
      _lamb(status: LambStatus.alive, diedAfterDays: null),
      _lamb(id: 2, status: LambStatus.sold, diedAfterDays: null),
      _lamb(id: 3),
    ]);

    expect(r.total, 1);
  });
}

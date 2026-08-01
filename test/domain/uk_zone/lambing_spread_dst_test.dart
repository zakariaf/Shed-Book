// test/domain/uk_zone/lambing_spread_dst_test.dart — the spread across both UK
// transitions.
//
// This is the file that catches a range generated with `DateTime` + Duration
// instead of LocalDate.plusDays. That bug produces a duplicated or a skipped
// civil day once a year — in the middle of lambing — and is invisible in every
// other zone-agnostic case.
@Tags(<String>['uk-zone'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/stats/lambing_spread.dart';
import 'package:shed_book/domain/stats/season_counts.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';

void main() {
  setUpAll(() {
    // A SUMMER date: under Europe/London 1 July is BST so the offset is +1. A
    // winter date's expected value is Duration.zero, which is also UTC's, so the
    // guard would pass on the ubuntu-latest runner and the tier would go green
    // in the wrong zone.
    expect(
      DateTime(2026, 7).timeZoneOffset,
      const Duration(hours: 1),
      reason:
          'Run this file with TZ=Europe/London. '
          'Found ${DateTime(2026, 7).timeZoneName} '
          '(${DateTime(2026, 7).timeZoneOffset})',
    );
  });

  test('a season spanning 29 March 2026 has exactly one bar per civil day, '
      'with no duplicate and no gap', () {
    // The spring-forward. 29 March is 23 hours long, so a range built by adding
    // Duration(days: 1) to a local DateTime lands twice on the 28th or skips the
    // 29th entirely.
    final LocalDate start = LocalDate(2026, 3, 25);
    final LocalDate end = LocalDate(2026, 4, 2);

    final LambingSpread s = lambingSpread(
      <DayBirths>[DayBirths(LocalDate(2026, 3, 29), 4, 3)],
      seasonStart: start,
      seasonEnd: end,
    );

    expect(s.bars.length, 9);
    expect(s.bars.map((SpreadBar b) => b.date.iso).toList(), <String>[
      '2026-03-25',
      '2026-03-26',
      '2026-03-27',
      '2026-03-28',
      '2026-03-29',
      '2026-03-30',
      '2026-03-31',
      '2026-04-01',
      '2026-04-02',
    ]);
    expect(
      s.bars.map((SpreadBar b) => b.date.iso).toSet().length,
      9,
      reason: 'no duplicate civil day',
    );
    expect(s.bars.singleWhere((SpreadBar b) => b.date.iso == '2026-03-29').births, 4);
  });

  test('a season spanning 25 October 2026 does the same', () {
    // The fall-back. 25 October is 25 hours long, and the same local-DateTime
    // bug skips the 26th.
    final LocalDate start = LocalDate(2026, 10, 22);
    final LocalDate end = LocalDate(2026, 10, 28);

    final LambingSpread s = lambingSpread(
      <DayBirths>[DayBirths(LocalDate(2026, 10, 25), 2, 2)],
      seasonStart: start,
      seasonEnd: end,
    );

    expect(s.bars.length, 7);
    expect(s.bars.map((SpreadBar b) => b.date.iso).toList(), <String>[
      '2026-10-22',
      '2026-10-23',
      '2026-10-24',
      '2026-10-25',
      '2026-10-26',
      '2026-10-27',
      '2026-10-28',
    ]);
    expect(s.bars.singleWhere((SpreadBar b) => b.date.iso == '2026-10-25').births, 2);
  });

  test('a lambing at 01:30 on 25 Oct 2026, the ambiguous hour, lands on the '
      '25 Oct bar exactly once', () {
    // 01:30 happens twice that night. Whichever instant Dart chose, LocalDate.of
    // gives 25 October, so the lambing lands on one bar — and on the right one.
    final Instant ambiguous = Instant.fromDateTime(DateTime(2026, 10, 25, 1, 30));
    expect(LocalDate.of(ambiguous), LocalDate(2026, 10, 25));

    final LambingSpread s = lambingSpread(
      <DayBirths>[DayBirths(LocalDate.of(ambiguous), 1, 1)],
      seasonStart: LocalDate(2026, 10, 24),
      seasonEnd: LocalDate(2026, 10, 26),
    );

    expect(s.bars.where((SpreadBar b) => b.births > 0), hasLength(1));
    expect(s.bars.singleWhere((SpreadBar b) => b.births > 0).date, LocalDate(2026, 10, 25));
  });

  test('a 23:55 lambing and a 00:05 lambing five minutes apart land on different bars', () {
    // 05 §6.9's own fixture case, and the reason the grouping is on the
    // denormalised local_date rather than on UTC or a SQL date function. Getting
    // it wrong is a once-per-night off-by-one for a whole season.
    final Instant lateNight = Instant.fromDateTime(DateTime(2026, 3, 10, 23, 55));
    final Instant justAfterMidnight = Instant.fromDateTime(DateTime(2026, 3, 11, 0, 5));

    expect(justAfterMidnight.difference(lateNight), const Duration(minutes: 10));
    expect(LocalDate.of(lateNight), LocalDate(2026, 3, 10));
    expect(LocalDate.of(justAfterMidnight), LocalDate(2026, 3, 11));

    final LambingSpread s = lambingSpread(
      <DayBirths>[
        DayBirths(LocalDate.of(lateNight), 1, 1),
        DayBirths(LocalDate.of(justAfterMidnight), 2, 1),
      ],
      seasonStart: LocalDate(2026, 3, 9),
      seasonEnd: LocalDate(2026, 3, 12),
    );

    expect(s.bars.singleWhere((SpreadBar b) => b.date.iso == '2026-03-10').births, 1);
    expect(s.bars.singleWhere((SpreadBar b) => b.date.iso == '2026-03-11').births, 2);
  });
}

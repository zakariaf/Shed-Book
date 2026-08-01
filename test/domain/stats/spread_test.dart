// test/domain/stats/spread_test.dart — the lambing spread.
//
// Relational throughout, because CI runs this directory again under
// TZ=Pacific/Chatham (UTC+12:45, with its own DST). "This list is dense", "these
// two dates are eleven apart" — never a wall-clock literal. The wall-clock
// literals are in test/domain/uk_zone/lambing_spread_dst_test.dart, which the
// hostile run excludes.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/stats/lambing_spread.dart';
import 'package:shed_book/domain/stats/season_counts.dart';
import 'package:shed_book/domain/time/local_date.dart';

final LocalDate _start = LocalDate(2026, 3, 1);
final LocalDate _end = LocalDate(2026, 3, 20);

void main() {
  test('the lambing spread is dense and zero-filled across every day of the season', () {
    // Two births, eleven days apart, in a season that runs 1–20 March. The
    // sparse implementation is the obvious one and it is the defect: it returns
    // two bars, and the GAPS are the information, because "was my tupping
    // tight?" is a statement about gaps.
    final List<DayBirths> rows = <DayBirths>[
      DayBirths(_start.plusDays(4), 3, 2),
      DayBirths(_start.plusDays(15), 1, 1),
    ];

    final LambingSpread s = lambingSpread(
      rows,
      seasonStart: _start,
      seasonEnd: _end,
      cycleDays: 17,
    );

    expect(s.bars.length, 20, reason: 'every civil day, not two');
    expect(s.bars.where((SpreadBar b) => b.births == 0).length, 18);
    expect(s.bars.map((SpreadBar b) => b.dayIndex).toList(), List<int>.generate(20, (int i) => i));
  });

  test("dayIndex is anchored at 0 on the season's first day so two seasons overlay", () {
    // The task file's own case name settles an ambiguity in 05 §6.9, whose rule
    // 3 says "anchored on the first lambing". Anchoring on the first lambing
    // would make dayIndex 0 fall on a different civil day in each season, which
    // is precisely what stops two curves overlaying. Anchored on the season's
    // first day, §7.8's comparison works.
    final List<DayBirths> lateStart = <DayBirths>[DayBirths(_start.plusDays(9), 2, 2)];

    final LambingSpread s = lambingSpread(lateStart, seasonStart: _start, seasonEnd: _end);

    expect(s.bars.first.dayIndex, 0);
    expect(s.bars.first.date, _start);
    expect(s.bars[9].births, 2, reason: 'the first lambing is on day 9, not day 0');
  });

  test('a season with no lambings returns empty bars and a null first-cycle count', () {
    // A NAMED STATE, not an error. The chart renders its named empty state —
    // never a spinner, never a zero-height chart.
    final LambingSpread s = lambingSpread(
      const <DayBirths>[],
      seasonStart: _start,
      seasonEnd: _end,
    );

    expect(s.bars, isEmpty);
    expect(s.ewesInFirstCycleDays, isNull);
    expect(s.cycleDays, 17);
  });

  test('ewesInFirstCycleDays counts ewes, not lambs', () {
    // Two different units in one chart: bar height is LAMBS, the first-cycle
    // figure is EWES. Never sum across them.
    final List<DayBirths> rows = <DayBirths>[
      DayBirths(_start.plusDays(0), 5, 2),
      DayBirths(_start.plusDays(3), 4, 3),
      DayBirths(_start.plusDays(18), 2, 1),
    ];

    final LambingSpread s = lambingSpread(
      rows,
      seasonStart: _start,
      seasonEnd: _end,
      cycleDays: 17,
    );

    expect(s.ewesInFirstCycleDays, 5, reason: '2 + 3 ewes inside the window, not 9 lambs');
    expect(s.bars.fold<int>(0, (int a, SpreadBar b) => a + b.births), 11);
  });

  test('the cycle length used is the one passed in, not the signature default', () {
    final List<DayBirths> rows = <DayBirths>[
      DayBirths(_start.plusDays(0), 1, 1),
      DayBirths(_start.plusDays(18), 1, 1),
    ];

    final LambingSpread twentyOne = lambingSpread(
      rows,
      seasonStart: _start,
      seasonEnd: _end,
      cycleDays: 21,
    );
    final LambingSpread seventeen = lambingSpread(
      rows,
      seasonStart: _start,
      seasonEnd: _end,
      cycleDays: 17,
    );

    expect(twentyOne.cycleDays, 21);
    expect(twentyOne.ewesInFirstCycleDays, 2, reason: 'day 18 is inside a 21-day window');
    expect(seventeen.ewesInFirstCycleDays, 1, reason: 'and outside a 17-day one');
  });

  test('a day with births but no distinct ewe change still renders its own bar', () {
    // One ewe, two lambings on the same day — or two ewes, whichever the query
    // counted. The bar exists because the DAY exists, not because a count
    // changed.
    final List<DayBirths> rows = <DayBirths>[DayBirths(_start.plusDays(2), 3, 1)];

    final LambingSpread s = lambingSpread(rows, seasonStart: _start, seasonEnd: _end);

    expect(s.bars[2].births, 3);
    expect(s.bars[2].ewes, 1);
    expect(s.bars[2].date, _start.plusDays(2));
  });

  test('a row outside the season bounds is not silently dropped into a bar', () {
    // The season bounds generate the range; the rows fill it. A row that falls
    // outside has nowhere to go, and folding it into the nearest bar would move
    // a lambing to a day it did not happen on.
    final List<DayBirths> rows = <DayBirths>[
      DayBirths(_start.plusDays(-3), 9, 9),
      DayBirths(_start.plusDays(2), 3, 1),
    ];

    final LambingSpread s = lambingSpread(rows, seasonStart: _start, seasonEnd: _end);

    expect(s.bars.fold<int>(0, (int a, SpreadBar b) => a + b.births), 3);
    expect(s.bars.first.births, 0);
  });
}

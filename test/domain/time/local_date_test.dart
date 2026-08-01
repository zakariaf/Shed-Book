// test/domain/time/local_date_test.dart — mirrors lib/domain/time/local_date.dart.
//
// Zone-agnostic: identically green under TZ=Pacific/Chatham. The ambiguous-hour
// counterpart, where LocalDate.of(Instant) must land on 25 October and not 24,
// is DST-2 in test/domain/uk_zone/ (N04-T08).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/time/local_date.dart';

void main() {
  test('LocalDate.parse throws on 2026-02-30 and never accepts a PartialDate', () {
    expect(() => LocalDate.parse('2026-02-30'), throwsFormatException);
    // A year-only value has its own type and no path into this one. The two
    // never meet: PartialDate is never widened to a full date, so LocalDate
    // must not know how to accept one.
    expect(
      File('lib/domain/time/local_date.dart').readAsStringSync(),
      isNot(contains('PartialDate')),
      reason: 'a widening path here is the 1-January bug with a call site',
    );
  });

  test('parse rejects every malformed shape', () {
    for (final String bad in <String>[
      '2026-2-3',
      '26-02-03',
      '2026/02/03',
      '2026-02-03T00:00',
      '20260203',
      '2026-02-03 ',
      '',
      '20x6-02-03',
    ]) {
      expect(() => LocalDate.parse(bad), throwsFormatException, reason: bad);
    }
  });

  test('parse rejects every impossible date', () {
    // The shape regex accepts all seven. The round trip through DateTime.utc is
    // what kills them.
    for (final String bad in <String>[
      '2026-13-01',
      '2026-00-10',
      '2026-02-30',
      '2025-02-29',
      '2026-04-31',
      '2026-01-32',
      '2026-01-00',
    ]) {
      expect(() => LocalDate.parse(bad), throwsFormatException, reason: bad);
    }
  });

  test('parse accepts the boundaries', () {
    for (final String good in <String>['2024-02-29', '2000-02-29', '2026-12-31', '0001-01-01']) {
      expect(LocalDate.parse(good).iso, good);
    }
  });

  test('the constructor throws where parse would', () {
    // It does NOT roll to 2 March. Safety rule §12.4 at the unconstructible
    // level: there is no non-throwing path to an impossible date.
    expect(() => LocalDate(2026, 2, 30), throwsArgumentError);
    expect(() => LocalDate(2026, 13, 1), throwsArgumentError);
    expect(() => LocalDate(2025, 2, 29), throwsArgumentError);
  });

  test('a single-digit month and day are zero-padded', () {
    // The property ORDER BY local_date depends on.
    expect(LocalDate(7, 1, 1).iso, '0007-01-01');
  });

  test('plusDays crosses a month, a year and a leap day', () {
    expect(LocalDate.parse('2026-01-31').plusDays(1), LocalDate.parse('2026-02-01'));
    expect(LocalDate.parse('2026-12-31').plusDays(1), LocalDate.parse('2027-01-01'));
    expect(LocalDate.parse('2024-02-28').plusDays(1), LocalDate.parse('2024-02-29'));
    expect(LocalDate.parse('2026-03-01').plusDays(-1), LocalDate.parse('2026-02-28'));
  });

  test('daysUntil is exact and signed', () {
    final LocalDate a = LocalDate.parse('2026-03-01');
    final LocalDate b = LocalDate.parse('2026-03-08');
    expect(a.daysUntil(b), 7);
    expect(b.daysUntil(a), -7);
    expect(a.daysUntil(a), 0);
  });

  test('plusDays and daysUntil are inverses', () {
    final LocalDate d = LocalDate.parse('2026-03-04');
    for (int n = -400; n <= 400; n++) {
      expect(d.plusDays(n).daysUntil(d), -n, reason: 'n = $n');
    }
  });

  test('compareTo sorts lexically and chronologically at once', () {
    final List<String> shuffled = <String>[
      '2026-03-04',
      '0007-01-01',
      '2025-12-31',
      '2026-01-01',
      '2024-02-29',
      '2026-03-05',
      '2026-02-28',
      '2027-01-01',
      '2026-03-03',
      '2026-12-31',
    ];
    final List<LocalDate> byCompare = shuffled.map(LocalDate.parse).toList()
      ..sort((LocalDate a, LocalDate b) => a.compareTo(b));
    final List<String> byString = <String>[...shuffled]..sort();
    expect(byCompare.map((LocalDate d) => d.iso).toList(), byString);
  });

  test('LocalDate is a safe Map key', () {
    expect(<LocalDate, String>{LocalDate(2026, 3, 4): 'a'}[LocalDate.parse('2026-03-04')], 'a');
  });

  test('startOfDayLocal round-trips through LocalDate.of', () {
    // Zone-sensitive in principle: it holds in every zone that has a local
    // midnight on the day in question. The spring-forward form is N04-T08's.
    for (final String iso in <String>[
      '2026-01-01',
      '2026-03-04',
      '2026-06-21',
      '2026-10-25',
      '2026-12-31',
    ]) {
      final LocalDate d = LocalDate.parse(iso);
      expect(LocalDate.of(d.startOfDayLocal()), d, reason: iso);
    }
  });

  test('plusDays across the UK spring-forward is still exactly one civil day', () {
    // Proves the UTC routing, and passes identically under TZ=Pacific/Chatham.
    final LocalDate before = LocalDate.parse('2026-03-28');
    expect(before.plusDays(1), LocalDate.parse('2026-03-29'));
    expect(before.daysUntil(LocalDate.parse('2026-03-29')), 1);
  });
}

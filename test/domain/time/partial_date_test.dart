// test/domain/time/partial_date_test.dart — mirrors lib/domain/time/partial_date.dart.
//
// Zone-agnostic, and more strongly than the rest of this epic: every case is a
// fact about strings and integers, because this type carries no instant at all.
// That is why it needs no `uk-zone` tag while every other time type here does.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/partial_date.dart';

void main() {
  test('a PartialDate with no month cannot be read as a LocalDate', () {
    final PartialDate d = PartialDate.parse('2022');
    expect(d.year, 2022);
    expect(d.month, isNull);
    expect(d.exactDate, isNull);
  });

  test('the year-month form knows its month and still has no exact date', () {
    final PartialDate d = PartialDate.parse('2022-03');
    expect(d.year, 2022);
    expect(d.month, 3);
    expect(d.exactDate, isNull);
  });

  test('only the full form yields an exactDate', () {
    expect(PartialDate.parse('2022-03-14').exactDate, LocalDate(2022, 3, 14));
  });

  test('no member on the type returns a non-null LocalDate from a partial', () {
    // The one-line bug this type exists to prevent is
    // `LocalDate(year, month ?? 1, day ?? 1)`. It reads as tidy null-safety
    // hygiene and turns "born sometime in 2022" into "born 1 January 2022" for
    // ever. Asserted on the source, because a return type cannot be reflected.
    // Comment lines are dropped first: the doc comment for `exactDate`
    // legitimately spells out the bug it prevents, and a scan that cannot tell
    // a declaration from prose warning about one is the same failure as a scan
    // that cannot tell a prohibition from a claim.
    final String source = File(
      'lib/domain/time/partial_date.dart',
    ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');
    expect(
      RegExp(r'\bLocalDate\s+get\b').hasMatch(source),
      isFalse,
      reason: 'a non-nullable LocalDate getter is a widening path',
    );
    expect(
      RegExp(r'\?\?\s*1\b').hasMatch(source),
      isFalse,
      reason: 'a ?? 1 next to a LocalDate construction is the 1-January bug',
    );
    // And the other direction, asserted by N04-T02's anchor too: LocalDate must
    // not learn about PartialDate.
    expect(
      File('lib/domain/time/local_date.dart').readAsStringSync(),
      isNot(contains('PartialDate')),
    );
  });

  test('parse rejects malformed input', () {
    for (final String bad in <String>[
      '20x6',
      '2022-3',
      '2022-',
      '2022-03-',
      '2022-13',
      '2022-00',
      '2022-02-30',
      '22',
      '2022/03',
      '',
      '2022-03-14T00:00',
    ]) {
      expect(() => PartialDate.parse(bad), throwsFormatException, reason: bad);
    }
  });

  test('parse accepts every real boundary', () {
    for (final String good in <String>['2022', '2022-01', '2022-12', '2024-02-29', '0001-01-01']) {
      expect(PartialDate.parse(good).iso, good);
    }
  });

  test('ordering is total and least-precise-first', () {
    final List<String> isos = <String>['2022-04', '2022-03-14', '2022', '2022-03', '2021-12-31'];
    final List<PartialDate> sorted = isos.map(PartialDate.parse).toList()
      ..sort((PartialDate a, PartialDate b) => a.compareTo(b));
    expect(sorted.map((PartialDate d) => d.iso).toList(), <String>[
      '2021-12-31',
      '2022',
      '2022-03',
      '2022-03-14',
      '2022-04',
    ]);
    // Antisymmetric over every pair, which is what makes the sort total rather
    // than merely ordered on this one list.
    for (final String a in isos) {
      for (final String b in isos) {
        final int ab = PartialDate.parse(a).compareTo(PartialDate.parse(b));
        final int ba = PartialDate.parse(b).compareTo(PartialDate.parse(a));
        expect(ab.sign, -ba.sign, reason: '$a vs $b');
      }
    }
  });

  test('ordering never throws on a mixed-precision list', () {
    // Equal-then-unstable is what makes a flock list reorder itself between
    // builds under the randomised ordering `make test` uses.
    final List<String> isos = <String>['2022-04', '2022-03-14', '2022', '2022-03', '2021-12-31'];
    for (int seed = 0; seed < 10; seed++) {
      final List<String> shuffled = <String>[...isos];
      // A deterministic rotation, so the case does not need a random source.
      for (int i = 0; i < seed; i++) {
        shuffled.add(shuffled.removeAt(0));
      }
      final List<PartialDate> sorted = shuffled.map(PartialDate.parse).toList()
        ..sort((PartialDate a, PartialDate b) => a.compareTo(b));
      expect(sorted.map((PartialDate d) => d.iso).toList(), <String>[
        '2021-12-31',
        '2022',
        '2022-03',
        '2022-03-14',
        '2022-04',
      ], reason: 'rotation $seed');
    }
  });

  test('display never invents a month or a day', () {
    expect(PartialDate.parse('2022').display, '2022');
    expect(PartialDate.parse('2022-03').display, 'March 2022');
    expect(PartialDate.parse('2022-03-14').display, '14 March 2022');
    // No placeholder, no padding, no invented January.
    final String yearOnly = PartialDate.parse('2022').display;
    expect(yearOnly, isNot(contains('Jan')));
    expect(yearOnly, isNot(contains('01')));
    expect(yearOnly, isNot(contains('?')));
  });

  test('equality comes from the representation', () {
    expect(PartialDate.parse('2022'), PartialDate.parse('2022'));
    // "the year 2022" and "January 2022" are different facts.
    expect(PartialDate.parse('2022') == PartialDate.parse('2022-01'), isFalse);
  });

  test('the three shapes are exactly the three the schema GLOB accepts', () {
    // The executable form of the contract N07's CHECK must match.
    expect(PartialDate.parse('2022').iso.length, 4);
    expect(PartialDate.parse('2022-03').iso.length, 7);
    expect(PartialDate.parse('2022-03-14').iso.length, 10);
    for (final String other in <String>['2022-03-14-01', '2', '202', '2022-03-1']) {
      expect(() => PartialDate.parse(other), throwsFormatException, reason: other);
    }
  });

  test('a partial date is unaffected by the ambiguous hour', () {
    final PartialDate d = PartialDate.parse('2026-10-25');
    expect(d.iso, '2026-10-25');
    expect(d.year, 2026);
    expect(d.month, 10);
    expect(d.exactDate, LocalDate(2026, 10, 25));
  });
}

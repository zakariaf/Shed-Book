// test/domain/stats/season_counts_test.dart — mirrors
// lib/domain/stats/season_counts.dart.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/stats/season_counts.dart';
import 'package:shed_book/domain/time/local_date.dart';

/// Every field distinct, so a `==` that compares the wrong pair of fields still
/// fails the loop below. All-equal values would let a transposition pass.
const SeasonCounts _base = SeasonCounts(
  ewesPutToRam: 1,
  ewesLambed: 2,
  lambingsTotal: 3,
  lambingsWithLambs: 4,
  lambingsScored: 5,
  lambingsScoredAssisted: 6,
  lambsBorn: 7,
  lambsBornAlive: 8,
  lambsReared: 9,
  ewesRecordedBarren: 10,
  ewesDiedOrSoldBeforeLambing: 11,
  ewesWithNoRecordedOutcome: 12,
);

/// One entry per field: its name, and the same counts with only that field
/// changed. A field added to the class and forgotten in `==` fails here, which
/// is the point — in N28 it would present as a rebuild storm nobody attributes
/// to this file.
const List<(String, SeasonCounts)> _oneFieldChanged = <(String, SeasonCounts)>[
  (
    'ewesPutToRam',
    SeasonCounts(
      ewesPutToRam: 99,
      ewesLambed: 2,
      lambingsTotal: 3,
      lambingsWithLambs: 4,
      lambingsScored: 5,
      lambingsScoredAssisted: 6,
      lambsBorn: 7,
      lambsBornAlive: 8,
      lambsReared: 9,
      ewesRecordedBarren: 10,
      ewesDiedOrSoldBeforeLambing: 11,
      ewesWithNoRecordedOutcome: 12,
    ),
  ),
  (
    'ewesLambed',
    SeasonCounts(
      ewesPutToRam: 1,
      ewesLambed: 99,
      lambingsTotal: 3,
      lambingsWithLambs: 4,
      lambingsScored: 5,
      lambingsScoredAssisted: 6,
      lambsBorn: 7,
      lambsBornAlive: 8,
      lambsReared: 9,
      ewesRecordedBarren: 10,
      ewesDiedOrSoldBeforeLambing: 11,
      ewesWithNoRecordedOutcome: 12,
    ),
  ),
  (
    'lambingsTotal',
    SeasonCounts(
      ewesPutToRam: 1,
      ewesLambed: 2,
      lambingsTotal: 99,
      lambingsWithLambs: 4,
      lambingsScored: 5,
      lambingsScoredAssisted: 6,
      lambsBorn: 7,
      lambsBornAlive: 8,
      lambsReared: 9,
      ewesRecordedBarren: 10,
      ewesDiedOrSoldBeforeLambing: 11,
      ewesWithNoRecordedOutcome: 12,
    ),
  ),
  (
    'lambingsWithLambs',
    SeasonCounts(
      ewesPutToRam: 1,
      ewesLambed: 2,
      lambingsTotal: 3,
      lambingsWithLambs: 99,
      lambingsScored: 5,
      lambingsScoredAssisted: 6,
      lambsBorn: 7,
      lambsBornAlive: 8,
      lambsReared: 9,
      ewesRecordedBarren: 10,
      ewesDiedOrSoldBeforeLambing: 11,
      ewesWithNoRecordedOutcome: 12,
    ),
  ),
  (
    'lambingsScored',
    SeasonCounts(
      ewesPutToRam: 1,
      ewesLambed: 2,
      lambingsTotal: 3,
      lambingsWithLambs: 4,
      lambingsScored: 99,
      lambingsScoredAssisted: 6,
      lambsBorn: 7,
      lambsBornAlive: 8,
      lambsReared: 9,
      ewesRecordedBarren: 10,
      ewesDiedOrSoldBeforeLambing: 11,
      ewesWithNoRecordedOutcome: 12,
    ),
  ),
  (
    'lambingsScoredAssisted',
    SeasonCounts(
      ewesPutToRam: 1,
      ewesLambed: 2,
      lambingsTotal: 3,
      lambingsWithLambs: 4,
      lambingsScored: 5,
      lambingsScoredAssisted: 99,
      lambsBorn: 7,
      lambsBornAlive: 8,
      lambsReared: 9,
      ewesRecordedBarren: 10,
      ewesDiedOrSoldBeforeLambing: 11,
      ewesWithNoRecordedOutcome: 12,
    ),
  ),
  (
    'lambsBorn',
    SeasonCounts(
      ewesPutToRam: 1,
      ewesLambed: 2,
      lambingsTotal: 3,
      lambingsWithLambs: 4,
      lambingsScored: 5,
      lambingsScoredAssisted: 6,
      lambsBorn: 99,
      lambsBornAlive: 8,
      lambsReared: 9,
      ewesRecordedBarren: 10,
      ewesDiedOrSoldBeforeLambing: 11,
      ewesWithNoRecordedOutcome: 12,
    ),
  ),
  (
    'lambsBornAlive',
    SeasonCounts(
      ewesPutToRam: 1,
      ewesLambed: 2,
      lambingsTotal: 3,
      lambingsWithLambs: 4,
      lambingsScored: 5,
      lambingsScoredAssisted: 6,
      lambsBorn: 7,
      lambsBornAlive: 99,
      lambsReared: 9,
      ewesRecordedBarren: 10,
      ewesDiedOrSoldBeforeLambing: 11,
      ewesWithNoRecordedOutcome: 12,
    ),
  ),
  (
    'lambsReared',
    SeasonCounts(
      ewesPutToRam: 1,
      ewesLambed: 2,
      lambingsTotal: 3,
      lambingsWithLambs: 4,
      lambingsScored: 5,
      lambingsScoredAssisted: 6,
      lambsBorn: 7,
      lambsBornAlive: 8,
      lambsReared: 99,
      ewesRecordedBarren: 10,
      ewesDiedOrSoldBeforeLambing: 11,
      ewesWithNoRecordedOutcome: 12,
    ),
  ),
  (
    'ewesRecordedBarren',
    SeasonCounts(
      ewesPutToRam: 1,
      ewesLambed: 2,
      lambingsTotal: 3,
      lambingsWithLambs: 4,
      lambingsScored: 5,
      lambingsScoredAssisted: 6,
      lambsBorn: 7,
      lambsBornAlive: 8,
      lambsReared: 9,
      ewesRecordedBarren: 99,
      ewesDiedOrSoldBeforeLambing: 11,
      ewesWithNoRecordedOutcome: 12,
    ),
  ),
  (
    'ewesDiedOrSoldBeforeLambing',
    SeasonCounts(
      ewesPutToRam: 1,
      ewesLambed: 2,
      lambingsTotal: 3,
      lambingsWithLambs: 4,
      lambingsScored: 5,
      lambingsScoredAssisted: 6,
      lambsBorn: 7,
      lambsBornAlive: 8,
      lambsReared: 9,
      ewesRecordedBarren: 10,
      ewesDiedOrSoldBeforeLambing: 99,
      ewesWithNoRecordedOutcome: 12,
    ),
  ),
  (
    'ewesWithNoRecordedOutcome',
    SeasonCounts(
      ewesPutToRam: 1,
      ewesLambed: 2,
      lambingsTotal: 3,
      lambingsWithLambs: 4,
      lambingsScored: 5,
      lambingsScoredAssisted: 6,
      lambsBorn: 7,
      lambsBornAlive: 8,
      lambsReared: 9,
      ewesRecordedBarren: 10,
      ewesDiedOrSoldBeforeLambing: 11,
      ewesWithNoRecordedOutcome: 99,
    ),
  ),
];

void main() {
  test('two SeasonCounts with identical fields are equal and share a hashCode', () {
    // NOT `const`, deliberately. Two const instances with equal fields are
    // canonicalised to the same object, so `identical` would be true and the
    // case would prove nothing about `==`. Written non-const, it is a genuine
    // second object — which is the only form in which value equality is a claim.
    final SeasonCounts same = SeasonCounts(
      ewesPutToRam: 1,
      ewesLambed: 2,
      lambingsTotal: 3,
      lambingsWithLambs: 4,
      lambingsScored: 5,
      lambingsScoredAssisted: 6,
      lambsBorn: 7,
      lambsBornAlive: 8,
      lambsReared: 9,
      ewesRecordedBarren: 10,
      ewesDiedOrSoldBeforeLambing: 11,
      ewesWithNoRecordedOutcome: 12,
    );

    expect(same, _base);
    expect(same.hashCode, _base.hashCode);
    expect(identical(same, _base), isFalse, reason: 'value equality, not identity');
  });

  test('changing any ONE of the twelve fields breaks equality', () {
    // Without this, a forgotten field in `==` is invisible until N28, where it
    // presents as a rebuild storm rather than as a wrong comparison.
    for (final (String, SeasonCounts) changed in _oneFieldChanged) {
      expect(changed.$2, isNot(_base), reason: changed.$1);
    }
    expect(
      _oneFieldChanged,
      hasLength(12),
      reason: 'one entry per field — add a field, add an entry',
    );
  });

  test('ewesPutToRam null and ewesPutToRam 0 are not equal', () {
    // The load-bearing null. "I did not record it" and "none went to the ram"
    // are different facts, and every statistic that divides by it must refuse
    // rather than substitute.
    const SeasonCounts notEntered = SeasonCounts(
      ewesPutToRam: null,
      ewesLambed: 2,
      lambingsTotal: 3,
      lambingsWithLambs: 4,
      lambingsScored: 5,
      lambingsScoredAssisted: 6,
      lambsBorn: 7,
      lambsBornAlive: 8,
      lambsReared: 9,
      ewesRecordedBarren: 10,
      ewesDiedOrSoldBeforeLambing: 11,
      ewesWithNoRecordedOutcome: 12,
    );
    const SeasonCounts zero = SeasonCounts(
      ewesPutToRam: 0,
      ewesLambed: 2,
      lambingsTotal: 3,
      lambingsWithLambs: 4,
      lambingsScored: 5,
      lambingsScoredAssisted: 6,
      lambsBorn: 7,
      lambsBornAlive: 8,
      lambsReared: 9,
      ewesRecordedBarren: 10,
      ewesDiedOrSoldBeforeLambing: 11,
      ewesWithNoRecordedOutcome: 12,
    );

    expect(notEntered, isNot(zero));
  });

  test('DayBirths has value equality', () {
    final DayBirths a = DayBirths(LocalDate(2026, 3, 4), 3, 2);
    final DayBirths b = DayBirths(LocalDate(2026, 3, 4), 3, 2);

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(DayBirths(LocalDate(2026, 3, 5), 3, 2)));
    expect(a, isNot(DayBirths(LocalDate(2026, 3, 4), 4, 2)));
    expect(a, isNot(DayBirths(LocalDate(2026, 3, 4), 3, 3)));
  });

  test('LambStatus keys are alive, dead, stillborn, sold', () {
    expect(LambStatus.values.map((LambStatus s) => s.key).toList(), <String>[
      'alive',
      'dead',
      'stillborn',
      'sold',
    ]);
    for (final LambStatus s in LambStatus.values) {
      expect(LambStatus.fromKey(s.key), s);
    }
    expect(() => LambStatus.fromKey('died'), throwsFormatException);
  });

  test('stillborn is its own status, not a dead lamb with an age of zero', () {
    // The distinction AgeBucket depends on: a stillborn lamb has no age at
    // death, and folding it into "died at age 0" double-counts against any
    // "first 24 h losses" figure.
    expect(LambStatus.stillborn, isNot(LambStatus.dead));
    expect(AgeBucket.stillborn, isNot(AgeBucket.sameDay));
    expect(AgeBucket.values, hasLength(7));
  });
}

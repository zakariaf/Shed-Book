// test/domain/stats/barren_rate_test.dart — barrenRate, and the formula it
// refuses to use.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/stats/definitions.dart';
import 'package:shed_book/domain/stats/season_counts.dart';
import 'package:shed_book/domain/stats/barren_rate.dart';

SeasonCounts _counts({
  int? ewesPutToRam = 10,
  int ewesLambed = 6,
  int ewesRecordedBarren = 1,
  int ewesDiedOrSoldBeforeLambing = 0,
  int ewesWithNoRecordedOutcome = 3,
}) => SeasonCounts(
  ewesPutToRam: ewesPutToRam,
  ewesLambed: ewesLambed,
  lambingsTotal: ewesLambed,
  lambingsWithLambs: ewesLambed,
  lambingsScored: 0,
  lambingsScoredAssisted: 0,
  lambsBorn: 0,
  lambsBornAlive: 0,
  lambsReared: 0,
  ewesRecordedBarren: ewesRecordedBarren,
  ewesDiedOrSoldBeforeLambing: ewesDiedOrSoldBeforeLambing,
  ewesWithNoRecordedOutcome: ewesWithNoRecordedOutcome,
);

void main() {
  test('only ewes recorded barren are counted', () {
    final StatResult r = barrenRate(_counts());

    expect(r.numerator, 1);
    expect(r.denominator, 10);
    expect(r.value, 10.0);
    expect(r.definition, kBarrenRateDefinition);
  });

  test('absence of a lambing is never barren', () {
    // The rejected formula, asserted to give a DIFFERENT answer on the same
    // counts — so a future "simplification" to it fails here rather than
    // quietly quadrupling a commercially sensitive number.
    final SeasonCounts c = _counts();
    final double rejected = (c.ewesPutToRam! - c.ewesLambed) / c.ewesPutToRam! * 100;

    expect(rejected, 40.0, reason: 'what (toRam − lambed)/toRam would have said');
    expect(barrenRate(c).value, 10.0, reason: 'what the recorded facts say');
    expect(barrenRate(c).value, isNot(rejected));
  });

  test('a blank ewes_to_ram returns notComputable', () {
    final StatResult r = barrenRate(_counts(ewesPutToRam: null));

    expect(r.value, isNull);
    expect(r.value, isNot(0));
    expect(r.notComputableReason, kEwesToRamNotEntered);
  });

  test('ewes with no recorded outcome are not barren and are named in a caveat', () {
    final StatResult r = barrenRate(_counts(ewesWithNoRecordedOutcome: 4));

    expect(r.numerator, 1, reason: 'the four unrecorded ewes are not swept in');
    expect(r.caveats, contains('4 ewes have no recorded outcome. They are not counted as barren.'));

    final StatResult one = barrenRate(_counts(ewesWithNoRecordedOutcome: 1));
    expect(one.caveats, contains('1 ewe has no recorded outcome. It is not counted as barren.'));
  });

  test('ewes that died or were sold stay in the denominator', () {
    // AHDB's denominator is ewes put to the tup, so they stay — and they are
    // named, because a shepherd comparing numerator to denominator will
    // otherwise wonder where they went.
    final StatResult r = barrenRate(_counts(ewesDiedOrSoldBeforeLambing: 2));

    expect(r.denominator, 10, reason: 'not 8');
    expect(
      r.caveats,
      contains('2 ewes died or were sold before lambing. They stay in the denominator.'),
    );
  });

  test('a zero ewes_to_ram returns notComputable, not a division by zero', () {
    final StatResult r = barrenRate(_counts(ewesPutToRam: 0, ewesLambed: 0));

    expect(r.value, isNull);
    expect(r.notComputableReason, kDenominatorIsZero);
  });
}

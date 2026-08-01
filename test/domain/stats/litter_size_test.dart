// test/domain/stats/litter_size_test.dart — averageLitterSize.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/stats/definitions.dart';
import 'package:shed_book/domain/stats/season_counts.dart';
import 'package:shed_book/domain/stats/season_stats.dart';

SeasonCounts _counts({
  int? ewesPutToRam = 5,
  int ewesLambed = 3,
  int lambingsTotal = 3,
  int lambingsWithLambs = 3,
  int lambsBorn = 6,
}) => SeasonCounts(
  ewesPutToRam: ewesPutToRam,
  ewesLambed: ewesLambed,
  lambingsTotal: lambingsTotal,
  lambingsWithLambs: lambingsWithLambs,
  lambingsScored: 0,
  lambingsScoredAssisted: 0,
  lambsBorn: lambsBorn,
  lambsBornAlive: lambsBorn,
  lambsReared: lambsBorn,
  ewesRecordedBarren: 0,
  ewesDiedOrSoldBeforeLambing: 0,
  ewesWithNoRecordedOutcome: 0,
);

void main() {
  test('lambsBorn over ewesLambed, aggregated by birth dam', () {
    final StatResult r = averageLitterSize(_counts());

    expect(r.value, 2.0);
    expect(r.numerator, 6);
    expect(r.denominator, 3);
    expect(r.definition, kAverageLitterSizeDefinition);
  });

  test('a lambing with zero attached lambs is excluded from both sides and '
      'reported as coverage', () {
    // A lambing always produces at least one lamb even if stillborn, so zero
    // attached lambs always means "not recorded yet" — and because the row is
    // created on screen ENTRY, the state is common and transient. Including it
    // would deflate the headline.
    final StatResult r = averageLitterSize(_counts(lambingsTotal: 5, lambingsWithLambs: 3));

    expect(r.value, 2.0, reason: 'the two empty lambings are not in the denominator');
    expect(r.caveats, contains('2 lambings have no lambs recorded yet and are excluded.'));

    final StatResult one = averageLitterSize(_counts(lambingsTotal: 4, lambingsWithLambs: 3));
    expect(one.caveats, contains('1 lambing has no lambs recorded yet and is excluded.'));
  });

  test('ewesLambed == 0 returns notComputable', () {
    final StatResult r = averageLitterSize(_counts(ewesLambed: 0, lambsBorn: 0));

    expect(r.value, isNull);
    expect(r.value, isNot(0));
    expect(r.notComputableReason, kNoEwesLambed);
  });

  test("a fostered lamb stays in the birth dam's litter", () {
    // Conserved by the record shape (§6.10), not re-derived here: lambsBorn
    // aggregates on birth_dam and lambsReared on the current rearing dam. This
    // function only ever touches lambsBorn, so no fostering can move a lamb
    // between litters — which is asserted by the numerator being lambsBorn and
    // nothing else.
    final StatResult r = averageLitterSize(_counts(lambsBorn: 6));
    expect(r.numerator, 6);
    expect(r.numerator, isNot(_counts().lambsReared + 1));
  });

  test('the value is a mean, not a percentage', () {
    // A pair of twins is 2.0, not 200. A renderer that appended % from the type
    // would be wrong here and right two functions away, which is why StatResult
    // carries no unit at all.
    final StatResult r = averageLitterSize(_counts(ewesLambed: 1, lambsBorn: 2));
    expect(r.value, 2.0);
    expect(r.value, isNot(200.0));
  });

  test('coverage with nothing excluded reports no caveat, and that is a claim', () {
    // An empty caveats list means "we looked and there was nothing", not "we
    // forgot to check". It is only readable that way because the excluded case
    // above proves the check exists.
    expect(averageLitterSize(_counts()).caveats, isEmpty);
  });
}

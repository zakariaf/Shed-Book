// test/domain/stats/lambing_percentage_test.dart — the statistic shepherds
// differ about most, and the four conventions it can be computed under.
//
// No uk-zone case: these functions take COUNTS, not instants. The season bounds
// that produce those counts are N06-T06's, and that is where the 01:00–01:59
// cases live.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/stats/definitions.dart';
import 'package:shed_book/domain/stats/season_counts.dart';
import 'package:shed_book/domain/stats/season_stats.dart';

/// 05 §6's toy season: 5 to the ram, 3 lambed, 6 born, 1 stillborn, 1 dead at
/// two days. So born = 6, born alive = 5, reared = 4.
const SeasonCounts _toySeason = SeasonCounts(
  ewesPutToRam: 5,
  ewesLambed: 3,
  lambingsTotal: 3,
  lambingsWithLambs: 3,
  lambingsScored: 3,
  lambingsScoredAssisted: 1,
  lambsBorn: 6,
  lambsBornAlive: 5,
  lambsReared: 4,
  ewesRecordedBarren: 0,
  ewesDiedOrSoldBeforeLambing: 0,
  ewesWithNoRecordedOutcome: 2,
);

void main() {
  test('lambing percentage states its verbatim definition and both AHDB choices', () {
    expect(
      lambingPercentage(_toySeason, LambingPercentageChoice.bornAlivePerEweToRam).value,
      100.0,
    );
    expect(
      lambingPercentage(_toySeason, LambingPercentageChoice.bornAlivePerEweToRam).definition,
      'lambs born alive per ewe put to the ram',
    );
    expect(
      lambingPercentage(_toySeason, LambingPercentageChoice.bornInclStillbornPerEweToRam).value,
      120.0,
    );
    expect(
      lambingPercentage(
        _toySeason,
        LambingPercentageChoice.bornInclStillbornPerEweToRam,
      ).definition,
      'lambs born incl. stillborn per ewe put to the ram',
    );
  });

  test('the toy season reads 120, 100, 167 and 80 under the four offered choices', () {
    // Computed by hand before this was written. If any of them reads 200 the
    // implementation has built the pair that is NOT offered — born incl.
    // stillborn per ewe lambed, 6/3, OMAFRA's convention and 05 §6's epigraph.
    expect(
      lambingPercentage(_toySeason, LambingPercentageChoice.bornInclStillbornPerEweToRam).value,
      120.0,
    );
    expect(
      lambingPercentage(_toySeason, LambingPercentageChoice.bornAlivePerEweToRam).value,
      100.0,
    );
    expect(
      lambingPercentage(_toySeason, LambingPercentageChoice.bornAlivePerEweLambed).value,
      closeTo(166.67, 0.01),
    );
    expect(lambingPercentage(_toySeason, LambingPercentageChoice.rearedPerEweToRam).value, 80.0);

    // And the fifth pair is unreachable: there is no choice that computes 6/3.
    expect(
      LambingPercentageChoice.values
          .map((LambingPercentageChoice c) => lambingPercentage(_toySeason, c).value)
          .toList(),
      isNot(contains(200.0)),
    );
  });

  test('a blank ewes_to_ram returns notComputableReason and never falls back to ewesLambed', () {
    const SeasonCounts blank = SeasonCounts(
      ewesPutToRam: null,
      ewesLambed: 3,
      lambingsTotal: 3,
      lambingsWithLambs: 3,
      lambingsScored: 3,
      lambingsScoredAssisted: 1,
      lambsBorn: 6,
      lambsBornAlive: 5,
      lambsReared: 4,
      ewesRecordedBarren: 0,
      ewesDiedOrSoldBeforeLambing: 0,
      ewesWithNoRecordedOutcome: 0,
    );

    final StatResult r = lambingPercentage(blank, LambingPercentageChoice.bornAlivePerEweToRam);

    expect(r.value, isNull);
    expect(r.value, isNot(0));
    expect(r.notComputableReason, kEwesToRamNotEntered);
    // The fallback that must not happen: 5/3 = 166.67 is what ewesLambed would
    // have given, and it is a DIFFERENT published convention reading high by
    // every barren, sold, dead or unentered ewe.
    expect(r.value, isNot(closeTo(166.67, 0.01)));
    expect(r.denominator, 0, reason: 'a structural placeholder, never rendered');

    // The other denominator is still computable on the same counts, which is how
    // we know the refusal is about the missing number and not about the season.
    expect(
      lambingPercentage(blank, LambingPercentageChoice.bornAlivePerEweLambed).value,
      closeTo(166.67, 0.01),
    );
  });

  test('a zero denominator returns notComputable, not NaN', () {
    const SeasonCounts nothingYet = SeasonCounts(
      ewesPutToRam: 0,
      ewesLambed: 0,
      lambingsTotal: 0,
      lambingsWithLambs: 0,
      lambingsScored: 0,
      lambingsScoredAssisted: 0,
      lambsBorn: 0,
      lambsBornAlive: 0,
      lambsReared: 0,
      ewesRecordedBarren: 0,
      ewesDiedOrSoldBeforeLambing: 0,
      ewesWithNoRecordedOutcome: 0,
    );

    for (final LambingPercentageChoice choice in LambingPercentageChoice.values) {
      final StatResult r = lambingPercentage(nothingYet, choice);
      expect(r.value, isNull, reason: choice.key);
      expect(r.notComputableReason, kDenominatorIsZero, reason: choice.key);
    }
  });

  test('more ewes lambed than recorded to the ram computes anyway and attaches the caveat', () {
    // Over 100% is normal for this metric. Warn, do not fix.
    const SeasonCounts moreLambed = SeasonCounts(
      ewesPutToRam: 2,
      ewesLambed: 3,
      lambingsTotal: 3,
      lambingsWithLambs: 3,
      lambingsScored: 3,
      lambingsScoredAssisted: 0,
      lambsBorn: 6,
      lambsBornAlive: 6,
      lambsReared: 6,
      ewesRecordedBarren: 0,
      ewesDiedOrSoldBeforeLambing: 0,
      ewesWithNoRecordedOutcome: 0,
    );

    final StatResult r = lambingPercentage(
      moreLambed,
      LambingPercentageChoice.bornAlivePerEweToRam,
    );

    expect(r.value, 300.0, reason: 'computed, not clamped to 100');
    expect(r.caveats, contains('3 ewes have lambed but only 2 were recorded as put to the ram.'));
  });

  test('a ewe with no recorded outcome changes no numerator and is named in a caveat', () {
    final StatResult r = lambingPercentage(
      _toySeason,
      LambingPercentageChoice.bornAlivePerEweToRam,
    );

    expect(r.numerator, 5, reason: 'the two unaccounted ewes contribute no lambs');
    expect(r.value, 100.0);
    expect(r.caveats, contains('2 ewes have no recorded outcome.'));
  });

  test('a tagless dead lamb is counted', () {
    // Lamb identity is the row id; `tag` is nullable at every layer. Anything
    // else loses exactly the losses that matter most. SeasonCounts holds counts,
    // so this is asserted where it is observable: the lamb is inside lambsBorn
    // and outside lambsBornAlive, and nothing about a tag enters the arithmetic.
    const SeasonCounts withTaglessDead = SeasonCounts(
      ewesPutToRam: 5,
      ewesLambed: 3,
      lambingsTotal: 3,
      lambingsWithLambs: 3,
      lambingsScored: 3,
      lambingsScoredAssisted: 0,
      lambsBorn: 6,
      lambsBornAlive: 5,
      lambsReared: 4,
      ewesRecordedBarren: 0,
      ewesDiedOrSoldBeforeLambing: 0,
      ewesWithNoRecordedOutcome: 2,
    );

    expect(
      lambingPercentage(
        withTaglessDead,
        LambingPercentageChoice.bornInclStillbornPerEweToRam,
      ).numerator,
      6,
    );
  });

  test('a fostered lamb is counted once', () {
    // Fostering is conserved by the RECORD SHAPE (§6.10) and must not be
    // re-derived here: every born count aggregates on birth_dam, every reared
    // count on the current rearing dam, and the two are never mixed in one
    // query. SeasonCounts hands over both, so a fostered lamb appears exactly
    // once in lambsBorn and exactly once in lambsReared.
    expect(_toySeason.lambsBorn, 6);
    expect(_toySeason.lambsReared, 4);
    expect(
      lambingPercentage(_toySeason, LambingPercentageChoice.rearedPerEweToRam).numerator,
      4,
      reason: 'no double count, and no third tally invented here',
    );
  });

  test('the definition string is choice.definition, character for character', () {
    for (final LambingPercentageChoice choice in LambingPercentageChoice.values) {
      expect(
        lambingPercentage(_toySeason, choice).definition,
        choice.definition,
        reason: choice.key,
      );
      // …including when the statistic refuses. A refusal still says what it was
      // refusing to compute.
      const SeasonCounts blank = SeasonCounts(
        ewesPutToRam: null,
        ewesLambed: 0,
        lambingsTotal: 0,
        lambingsWithLambs: 0,
        lambingsScored: 0,
        lambingsScoredAssisted: 0,
        lambsBorn: 0,
        lambsBornAlive: 0,
        lambsReared: 0,
        ewesRecordedBarren: 0,
        ewesDiedOrSoldBeforeLambing: 0,
        ewesWithNoRecordedOutcome: 0,
      );
      expect(lambingPercentage(blank, choice).definition, choice.definition, reason: choice.key);
    }
  });

  test('the value is a percentage and StatResult cannot say so', () {
    // Recorded because a renderer that appended % from the TYPE would print
    // "200%" for a pair of twins in averageLitterSize. The unit lives in the
    // definition string and in the doc comment, and nowhere else.
    expect(
      lambingPercentage(_toySeason, LambingPercentageChoice.bornAlivePerEweToRam).value,
      100.0,
    );
    expect(averageLitterSize(_toySeason).value, 2.0, reason: 'a mean, on the same season');
  });
}

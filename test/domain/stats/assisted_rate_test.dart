// test/domain/stats/assisted_rate_test.dart — assistedRate.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/stats/assisted_rate.dart';
import 'package:shed_book/domain/stats/definitions.dart';
import 'package:shed_book/domain/stats/season_counts.dart';

SeasonCounts _counts({
  int lambingsTotal = 3,
  int lambingsScored = 3,
  int lambingsScoredAssisted = 1,
}) => SeasonCounts(
  ewesPutToRam: 5,
  ewesLambed: 3,
  lambingsTotal: lambingsTotal,
  lambingsWithLambs: lambingsTotal,
  lambingsScored: lambingsScored,
  lambingsScoredAssisted: lambingsScoredAssisted,
  lambsBorn: 6,
  lambsBornAlive: 6,
  lambsReared: 6,
  ewesRecordedBarren: 0,
  ewesDiedOrSoldBeforeLambing: 0,
  ewesWithNoRecordedOutcome: 0,
);

void main() {
  test('no lambing has an ease score → notComputable, not 0%', () {
    // A blank ease is NOT a 1. Sheep Genetics: "a blank score indicates the
    // lambing ease was not scored." Returning 0% would say every lambing was
    // unassisted, which is the silent inference §12.4 forbids — and it is the
    // reading a shepherd would act on.
    final StatResult r = assistedRate(_counts(lambingsScored: 0, lambingsScoredAssisted: 0));

    expect(r.value, isNull);
    expect(r.value, isNot(0));
    expect(r.notComputableReason, kNoLambingsScored);
  });

  test('ease >= 2 is assisted; ease 1 is not', () {
    expect(assistedRate(_counts(lambingsScoredAssisted: 1)).value, closeTo(33.33, 0.01));
    expect(assistedRate(_counts(lambingsScoredAssisted: 0)).value, 0.0);
    expect(
      assistedRate(_counts(lambingsScoredAssisted: 3)).value,
      100.0,
      reason: 'a genuine 0% is representable and is not the same as a refusal',
    );
  });

  test('unscored lambings are excluded from BOTH sides', () {
    // Ten lambings, three scored, one assisted. The rate is 1/3, never 1/10.
    final StatResult r = assistedRate(
      _counts(lambingsTotal: 10, lambingsScored: 3, lambingsScoredAssisted: 1),
    );

    expect(r.numerator, 1);
    expect(r.denominator, 3);
    expect(r.value, closeTo(33.33, 0.01));
    expect(r.value, isNot(closeTo(10.0, 0.01)), reason: '1/10 is what blank-as-1 would give');
  });

  test('partial coverage attaches the "1 of 3 lambings has no ease score" caveat', () {
    final StatResult r = assistedRate(_counts(lambingsTotal: 3, lambingsScored: 2));

    expect(
      r.caveats,
      contains('1 of 3 lambings has no ease score and is excluded from both sides.'),
    );

    final StatResult two = assistedRate(_counts(lambingsTotal: 4, lambingsScored: 2));
    expect(
      two.caveats,
      contains('2 of 4 lambings have no ease score and are excluded from both sides.'),
    );
  });

  test('full coverage attaches no caveat, and that is a claim', () {
    expect(assistedRate(_counts()).caveats, isEmpty);
  });

  test('the definition string says per lambing', () {
    // SRUC and Sheep Genetics score per LAMB; the spec puts ease on the Lambing.
    // Saying so is what stops a future consumer reading it as a per-lamb figure.
    expect(assistedRate(_counts()).definition, kAssistedRateDefinition);
    expect(kAssistedRateDefinition, contains('per lambing'));
  });
}

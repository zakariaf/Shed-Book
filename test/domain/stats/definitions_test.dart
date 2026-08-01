// test/domain/stats/definitions_test.dart — mirrors lib/domain/stats/definitions.dart.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/stats/definitions.dart';

void main() {
  test('LambingPercentageChoice has exactly four members', () {
    // The pair (LambCount, FlockDenominator) admits six combinations. Only four
    // are offered, because the column's CHECK admits four — so an unstorable
    // pair is unconstructible.
    expect(LambingPercentageChoice.values, hasLength(4));
  });

  test("the four keys are the four strings in app_settings.percentage_definition's CHECK", () {
    // PINNED LITERALLY, and deliberately so. 05's definition of done asks for a
    // test against the committed schema JSON; there is no
    // drift_schemas/drift_schema_v1.json until N07-T08. N07-T08's freeze must
    // ADD that cross-check — and must not delete this literal freeze as a
    // duplicate when it does. Two independent statements of the same four
    // strings is the point: one is the domain's, one is the schema's, and the
    // whole risk is that they drift.
    expect(
      LambingPercentageChoice.values.map((LambingPercentageChoice c) => c.key).toList(),
      <String>[
        'born_alive_per_ewe_to_ram',
        'born_incl_stillborn_per_ewe_to_ram',
        'born_alive_per_ewe_lambed',
        'reared_per_ewe_to_ram',
      ],
    );
  });

  test('the four definition strings are frozen', () {
    // R61. They are printed into CSVs and PDFs that outlive the app: a
    // shepherd's 2027 season file quotes the 2026 wording, and changing one
    // means §6.11 refuses to compare two seasons — which is correct behaviour
    // and still a support conversation nobody can have, because there is no
    // support channel.
    expect(
      LambingPercentageChoice.values.map((LambingPercentageChoice c) => c.definition).toList(),
      <String>[
        'lambs born alive per ewe put to the ram',
        'lambs born incl. stillborn per ewe put to the ram',
        'lambs born alive per ewe lambed',
        'lambs reared per ewe put to the ram',
      ],
    );
  });

  test('ahdbDefault is bornAlivePerEweToRam', () {
    // Decision-record §7.0 ruling 3: UK/Ireland first, so the default follows
    // AHDB. It stays user-configurable per §7.8.
    expect(LambingPercentageChoice.ahdbDefault, LambingPercentageChoice.bornAlivePerEweToRam);
    expect(LambingPercentageChoice.ahdbDefault.definitionParts.count, LambCount.bornAlive);
    expect(LambingPercentageChoice.ahdbDefault.definitionParts.per, FlockDenominator.ewesPutToRam);
  });

  test('definitionParts returns the (count, per) pair for each choice', () {
    expect(
      LambingPercentageChoice.values.map((LambingPercentageChoice c) => c.definitionParts).toList(),
      <LambingPercentageDefinition>[
        (count: LambCount.bornAlive, per: FlockDenominator.ewesPutToRam),
        (count: LambCount.born, per: FlockDenominator.ewesPutToRam),
        (count: LambCount.bornAlive, per: FlockDenominator.ewesLambed),
        (count: LambCount.reared, per: FlockDenominator.ewesPutToRam),
      ],
    );
  });

  test('LambCount and FlockDenominator keys are born/born_alive/reared and '
      'ewes_to_ram/ewes_lambed', () {
    expect(LambCount.values.map((LambCount c) => c.key).toList(), <String>[
      'born',
      'born_alive',
      'reared',
    ]);
    expect(FlockDenominator.values.map((FlockDenominator d) => d.key).toList(), <String>[
      'ewes_to_ram',
      'ewes_lambed',
    ]);
  });

  test('EweSeasonOutcome buckets all seven ewe_seasons.status keys, and an absent row, '
      'to exactly one member each', () {
    expect(eweSeasonOutcomeFor('lambed'), EweSeasonOutcome.lambed);
    expect(eweSeasonOutcomeFor('barren'), EweSeasonOutcome.recordedBarren);
    expect(eweSeasonOutcomeFor('died'), EweSeasonOutcome.diedOrSoldBeforeLambing);
    expect(eweSeasonOutcomeFor('sold'), EweSeasonOutcome.diedOrSoldBeforeLambing);
    expect(eweSeasonOutcomeFor('aborted'), EweSeasonOutcome.diedOrSoldBeforeLambing);
    expect(eweSeasonOutcomeFor('to_ram'), EweSeasonOutcome.notRecorded);
    expect(eweSeasonOutcomeFor('scanned'), EweSeasonOutcome.notRecorded);
    expect(eweSeasonOutcomeFor(null), EweSeasonOutcome.notRecorded);

    // 'to_ram' and 'scanned' are NOT barren. Absence of a lambing is never
    // evidence of barrenness, and at 3am on night eleven the absence of data
    // overwhelmingly means "not recorded yet".
    expect(eweSeasonOutcomeFor('to_ram'), isNot(EweSeasonOutcome.recordedBarren));
    expect(() => eweSeasonOutcomeFor('nonsense'), throwsFormatException);
  });

  test('EweSeasonOutcome is a bucketing and has four members over seven keys', () {
    expect(EweSeasonOutcome.values, hasLength(4));
  });
}

import 'package:shed_book/domain/stats/caveats.dart';
import 'package:shed_book/domain/stats/definitions.dart';
import 'package:shed_book/domain/stats/season_counts.dart';

/// Lambs per ewe, **as a percentage** — `× 100`.
///
/// [StatResult] cannot express a unit and does not try. Lambing percentage,
/// barren rate and assisted rate are `× 100`; average litter size is a plain
/// mean. A renderer that appended `%` from the type would print *"200%"* for a
/// pair of twins, so the unit lives in the definition string and in these doc
/// comments.
///
/// The numerator comes from `choice.definitionParts.count` and the denominator
/// from `.per`. **[StatResult.definition] is `choice.definition` verbatim** —
/// never rebuilt from the parts at the call site, or two call sites word it
/// differently and §6.11 refuses to compare two identical seasons.
///
/// **Only four of the six possible pairs are offered.** `app_settings.percentage_definition`
/// stores four. The fifth pair — *born incl. stillborn per ewe lambed*, OMAFRA's
/// published convention — is the 200% in 05 §6's epigraph, and the app
/// deliberately does not offer it. Completing the matrix would be a `CHECK`
/// violation in N07 and a broken comparison in §6.11.
StatResult lambingPercentage(SeasonCounts c, LambingPercentageChoice choice) {
  final LambingPercentageDefinition parts = choice.definitionParts;

  final int numerator = switch (parts.count) {
    LambCount.born => c.lambsBorn,
    LambCount.bornAlive => c.lambsBornAlive,
    LambCount.reared => c.lambsReared,
  };

  // **Never fall back to ewesLambed.** That silently swaps in a different
  // published convention and reads high by every barren, sold, dead or unentered
  // ewe — fourteen points on 05 §6.2's worked contrast. And never return 0: zero
  // and "not entered" are different facts.
  final int? denominator = switch (parts.per) {
    FlockDenominator.ewesPutToRam => c.ewesPutToRam,
    FlockDenominator.ewesLambed => c.ewesLambed,
  };

  if (denominator == null) {
    return StatResult.notComputable(definition: choice.definition, reason: kEwesToRamNotEntered);
  }
  if (denominator == 0) {
    return StatResult.notComputable(definition: choice.definition, reason: kDenominatorIsZero);
  }

  return StatResult(
    value: numerator / denominator * 100,
    definition: choice.definition,
    numerator: numerator,
    denominator: denominator,
    caveats: <String>[
      // Over 100% is NORMAL for this metric, so more ewes lambed than were
      // recorded to the ram is computed anyway and carries a fact. Warn, do not
      // fix.
      if (parts.per == FlockDenominator.ewesPutToRam && c.ewesLambed > denominator)
        '${c.ewesLambed} ewes have lambed but only $denominator were '
            'recorded as put to the ram.',
      if (c.ewesWithNoRecordedOutcome > 0)
        ewesPhrase(
          c.ewesWithNoRecordedOutcome,
          'has no recorded outcome.',
          'have no recorded outcome.',
        ),
    ],
  );
}

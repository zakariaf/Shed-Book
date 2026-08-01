import 'package:shed_book/domain/stats/caveats.dart';
import 'package:shed_book/domain/stats/definitions.dart';
import 'package:shed_book/domain/stats/season_counts.dart';

/// **Frozen for the same reason `LambingPercentageChoice.definition` is** (R61).
const String kBarrenRateDefinition = 'ewes recorded barren per ewe put to the ram';

/// Ewes recorded barren per ewe put to the ram, **as a percentage** — `× 100`.
///
/// **Only ewes the user has EXPLICITLY marked barren are counted. Absence of a
/// lambing is never evidence of barrenness.**
///
/// The rejected alternative — `(ewesToRam − ewesLambed) / ewesToRam` — is the
/// one you will reach for, and it sweeps in ewes that died, were sold, aborted
/// or were simply never entered. It is a silent inference (§12.4) about a
/// commercially sensitive number (spec §4.5), and at 3am on night eleven the
/// absence of data overwhelmingly means *"not recorded yet"*.
StatResult barrenRate(SeasonCounts c) {
  final int? denominator = c.ewesPutToRam;
  if (denominator == null) {
    return StatResult.notComputable(
      definition: kBarrenRateDefinition,
      reason: kEwesToRamNotEntered,
    );
  }
  if (denominator == 0) {
    return StatResult.notComputable(definition: kBarrenRateDefinition, reason: kDenominatorIsZero);
  }

  return StatResult(
    value: c.ewesRecordedBarren / denominator * 100,
    definition: kBarrenRateDefinition,
    numerator: c.ewesRecordedBarren,
    denominator: denominator,
    caveats: <String>[
      if (c.ewesWithNoRecordedOutcome > 0)
        ewesPhrase(
          c.ewesWithNoRecordedOutcome,
          'has no recorded outcome. It is not counted as barren.',
          'have no recorded outcome. They are not counted as barren.',
        ),
      // AHDB's denominator is ewes put to the tup, so these stay in it — and are
      // named, because a shepherd comparing the numerator to the denominator
      // will otherwise wonder where they went.
      if (c.ewesDiedOrSoldBeforeLambing > 0)
        ewesPhrase(
          c.ewesDiedOrSoldBeforeLambing,
          'died or was sold before lambing. It stays in the denominator.',
          'died or were sold before lambing. They stay in the denominator.',
        ),
    ],
  );
}

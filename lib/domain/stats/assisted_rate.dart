import 'package:shed_book/domain/stats/definitions.dart';
import 'package:shed_book/domain/stats/season_counts.dart';

/// **Frozen** (R61), and it says *per lambing* on purpose.
///
/// SRUC and Sheep Genetics score lambing ease per **lamb**; the spec puts it on
/// the `Lambing`, and for a notebook that is right. Saying so in the definition
/// string — and labelling the CSV column `lambing_ease_1_5` — is what stops a
/// future consumer reading it as a per-lamb figure.
const String kAssistedRateDefinition = 'assisted lambings per lambing with an ease score';

/// Lambings scored 2 or more, per lambing that has an ease score — **as a
/// percentage**, `× 100`.
///
/// **Denominator = lambings WITH an ease score. Both sides exclude unscored
/// lambings, and coverage is always reported.**
///
/// A blank ease is **not** *"1 — unassisted"*. Sheep Genetics is explicit: *"a
/// blank score indicates the lambing ease was not scored."* Treating blank as 1
/// deflates the rate and is exactly the silent inference §12.4 forbids — so no
/// lambing scored returns [StatResult.notComputable], never `0%`.
///
/// Ease 1 is no assistance; 2 and above is assisted. The 1–5 scale stays at five
/// (ruled 2026-08-01, decision-record §7.0 row 15, with point 5 documented as
/// covering elective caesarean).
StatResult assistedRate(SeasonCounts c) {
  if (c.lambingsScored == 0) {
    return StatResult.notComputable(definition: kAssistedRateDefinition, reason: kNoLambingsScored);
  }

  final int unscored = c.lambingsTotal - c.lambingsScored;

  return StatResult(
    value: c.lambingsScoredAssisted / c.lambingsScored * 100,
    definition: kAssistedRateDefinition,
    numerator: c.lambingsScoredAssisted,
    denominator: c.lambingsScored,
    caveats: <String>[
      // Coverage, always. An empty caveats list here means "every lambing is
      // scored", not "we did not look".
      if (unscored > 0)
        unscored == 1
            ? '1 of ${c.lambingsTotal} lambings has no ease score and is excluded '
                  'from both sides.'
            : '$unscored of ${c.lambingsTotal} lambings have no ease score and are '
                  'excluded from both sides.',
    ],
  );
}

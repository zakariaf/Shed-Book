import 'package:shed_book/domain/stats/definitions.dart';
import 'package:shed_book/domain/stats/season_counts.dart';

/// **Frozen for the same reason `LambingPercentageChoice.definition` is** (R61):
/// printed under the number, into the CSV and into the PDF, and quoted by a
/// season file that outlives the app.
const String kAverageLitterSizeDefinition = 'lambs born per ewe lambed';

/// Lambs born per ewe lambed, **as a plain mean** — not a percentage.
///
/// **Always `lambsBorn ÷ ewesLambed`, always aggregated by birth dam. Not
/// configurable** — *"litter size"* has one meaning, and offering a choice here
/// invents a disagreement the industry does not have.
///
/// A fostered lamb stays in the **birth** dam's litter and never moves to the
/// receiving ewe's. That is already conserved by the record shape (§6.10) and
/// must not be re-derived here: every *born* count aggregates on `birth_dam`,
/// every *reared* count on the current rearing dam, and the two are never mixed.
StatResult averageLitterSize(SeasonCounts c) {
  if (c.ewesLambed == 0) {
    return StatResult.notComputable(
      definition: kAverageLitterSizeDefinition,
      reason: kNoEwesLambed,
    );
  }

  // A lambing with zero attached lambs is excluded from BOTH sides. A lambing
  // always produces at least one lamb even if stillborn, so zero attached lambs
  // always means "not recorded yet" — and because the row is created on screen
  // ENTRY (decision #11), the state is common and transient. Including it would
  // deflate the headline.
  final int notYetRecorded = c.lambingsTotal - c.lambingsWithLambs;

  return StatResult(
    value: c.lambsBorn / c.ewesLambed,
    definition: kAverageLitterSizeDefinition,
    numerator: c.lambsBorn,
    denominator: c.ewesLambed,
    caveats: <String>[
      if (notYetRecorded > 0)
        notYetRecorded == 1
            ? '1 lambing has no lambs recorded yet and is excluded.'
            : '$notYetRecorded lambings have no lambs recorded yet and are excluded.',
    ],
  );
}

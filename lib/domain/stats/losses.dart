import 'package:shed_book/domain/stats/season_counts.dart';

/// Our word for a blank cause field.
///
/// **Never merged with a cause the user can pick.** `dc_unknown` is a
/// `vocab_terms` key a shepherd chose deliberately — *"I looked and could not
/// tell"*. This is *"nobody has said"*. They are two different facts and two
/// separate rows (CONVENTIONS §5.1).
///
/// Give it a prominent row rather than hiding it: in a *studied* population
/// Teagasc still records 19% of deaths as *"diagnosis not reached"*, so a large
/// unattributed share is something real, not a personal failing.
const String kUnattributed = 'unattributed';

typedef LossesBreakdown = ({
  int total,
  Map<String, int> byCause,
  Map<AgeBucket, int> byAge,
  List<String> caveats,
});

/// Every lamb that was lost, tallied by cause and by age at death.
///
/// A loss is [LambStatus.dead] or [LambStatus.stillborn]. [LambStatus.sold] is
/// not a loss, and [LambStatus.alive] is not either.
///
/// **A tagless dead lamb is counted, fully.** Lamb identity is the row id and
/// `tag` is nullable at every layer; anything else loses exactly the losses that
/// matter most.
///
/// **A fostered lamb that died is counted ONCE at season level.** On a ewe card
/// there are two different numbers, labelled differently — *"lambs born to her
/// that died"* on the birth dam and *"lambs lost while rearing"* on the current
/// rearing dam — and never one number. That distinction is a per-dam query's,
/// not this function's.
///
/// A loss *rate* needs a denominator and must state it: lambs lost ÷
/// `LambCount.born`. Prefer the counts; a rate here is easy to quote wrongly.
LossesBreakdown lossesBreakdown(List<LambOutcome> lambs) {
  final Map<String, int> byCause = <String, int>{};
  final Map<AgeBucket, int> byAge = <AgeBucket, int>{};
  int total = 0;
  int beforeBirth = 0;

  for (final LambOutcome lamb in lambs) {
    if (lamb.status != LambStatus.dead && lamb.status != LambStatus.stillborn) {
      continue;
    }
    total++;

    // A blank cause is `unattributed`, never `unknown`.
    byCause.update(lamb.causeKey ?? kUnattributed, (int n) => n + 1, ifAbsent: () => 1);

    final AgeBucket bucket;
    if (lamb.status == LambStatus.stillborn) {
      // Its own bucket, never "died at age 0". A stillborn lamb has no age at
      // death, and folding it in double-counts against any "first 24 h losses"
      // figure.
      bucket = AgeBucket.stillborn;
    } else if (lamb.deathDate == null) {
      // Counted in the total regardless — the death is a fact even when the day
      // is not.
      bucket = AgeBucket.unknownAge;
    } else {
      final int days = lamb.lambingDate.daysUntil(lamb.deathDate!);
      if (days < 0) {
        beforeBirth++;
        bucket = AgeBucket.unknownAge;
      } else {
        bucket = _bucketFor(days);
      }
    }
    byAge.update(bucket, (int n) => n + 1, ifAbsent: () => 1);
  }

  return (
    total: total,
    byCause: byCause,
    byAge: byAge,
    caveats: <String>[
      if (beforeBirth > 0)
        beforeBirth == 1
            ? '1 lamb has a death date before its lambing. Its age is not counted.'
            : '$beforeBirth lambs have a death date before their lambing. '
                  'Their ages are not counted.',
    ],
  );
}

/// **Boundaries matched to Teagasc's published breakdown, not invented.**
///
/// Teagasc splits at day 1–3 and day 4–7, with *"the first three days after
/// birth account for 74% of lamb mortality."* A `day1to2` / `day3to7` split
/// straddles that boundary and makes the comparison impossible without
/// arithmetic nobody does at the kitchen table. [AgeBucket.day8to30] and
/// [AgeBucket.over30] subdivide Teagasc's single *">day 7"* band; summing them
/// recovers it exactly.
///
/// Day 0 is *"born and died the same day"*, **never** *"under 24 hours"*.
/// `death_date` has day resolution, and claiming the hour would be exactly the
/// silent precision inflation §12.4 forbids.
AgeBucket _bucketFor(int days) => switch (days) {
  0 => AgeBucket.sameDay,
  >= 1 && <= 3 => AgeBucket.day1to3,
  >= 4 && <= 7 => AgeBucket.day4to7,
  >= 8 && <= 30 => AgeBucket.day8to30,
  _ => AgeBucket.over30,
};

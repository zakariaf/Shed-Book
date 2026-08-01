import 'package:shed_book/domain/stats/definitions.dart';
import 'package:shed_book/domain/stats/season_counts.dart';

/// **Frozen for the same reason [LambingPercentageChoice.definition] is** (R61):
/// printed under the number, into the CSV and into the PDF, and quoted by a
/// season file that outlives the app.
const String kAverageLitterSizeDefinition = 'lambs born per ewe lambed';

const String kBarrenRateDefinition = 'ewes recorded barren per ewe put to the ram';

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
        _ewes(c.ewesWithNoRecordedOutcome, 'has no recorded outcome.', 'have no recorded outcome.'),
    ],
  );
}

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
        _ewes(
          c.ewesWithNoRecordedOutcome,
          'has no recorded outcome. It is not counted as barren.',
          'have no recorded outcome. They are not counted as barren.',
        ),
      // AHDB's denominator is ewes put to the tup, so these stay in it — and are
      // named, because a shepherd comparing the numerator to the denominator
      // will otherwise wonder where they went.
      if (c.ewesDiedOrSoldBeforeLambing > 0)
        _ewes(
          c.ewesDiedOrSoldBeforeLambing,
          'died or was sold before lambing. It stays in the denominator.',
          'died or were sold before lambing. They stay in the denominator.',
        ),
    ],
  );
}

/// A caveat is a **fact, never a judgement**. *"32 of 48 ewes lambed in the
/// first 17 days"* is a fact; *"your tupping was tight"* is a judgement, is
/// banned by §12.2, and would trip `copy.vet_advice` in N06-T09.
///
/// The inflection is here rather than at four call sites so the wording exists
/// once. 10 §8.5 eventually moves these sentences into ARB messages with
/// placeholders; until then the domain hands over the numbers and keeps the
/// sentence plain.
String _ewes(int n, String singular, String plural) =>
    n == 1 ? '1 ewe $singular' : '$n ewes $plural';

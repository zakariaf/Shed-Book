/// The reasons a statistic can refuse, held once each.
///
/// `notComputableReason` is a `String?` rather than an enum (05 §6.1,
/// CONVENTIONS §2.6), and *"a closed set with display text"* is satisfied by
/// these: named, referenced, never re-typed. Two call sites that word the same
/// refusal differently produce two statistics that §6.11 then refuses to
/// compare — which is the failure this exists to prevent.
///
/// They are sentences because they render **in place of the number**, not
/// beside it. No blank cell, no `NaN`, no em-dash that might mean zero.
library;

const String kEwesToRamNotEntered =
    'The number of ewes put to the ram has not been entered for this season.';

const String kNoEwesLambed = 'No ewes have lambed in this season yet.';

const String kNoLambingsScored = 'No lambings have an ease score yet.';

const String kDenominatorIsZero = 'There is nothing to divide by yet.';

/// What every statistic returns.
///
/// **There is no constructor without [definition]** (05 §9 row 21), and that is
/// the mechanism rather than a convention: a bare percentage cannot be
/// constructed, so it cannot be rendered.
///
/// The UI and export contract, all four parts mandatory (05 §6.1):
///
///   1. [definition] renders **under every headline number, always** — not
///      behind an info icon.
///   2. [numerator] / [denominator] renders too (*"6 / 5"*). It is the cheapest
///      possible way for a shepherd to sanity-check a number that looks wrong,
///      and at 18 pt it costs one line.
///   3. The CSV and PDF carry [definition] **verbatim** beside the value.
///   4. [notComputableReason] is displayed as the value's replacement.
final class StatResult {
  const StatResult({
    required this.value,
    required this.definition,
    required this.numerator,
    required this.denominator,
    this.notComputableReason,
    this.caveats = const <String>[],
  });

  /// [numerator] and [denominator] stay at 0 as **structural placeholders, not
  /// counts**. Nothing may render them when [value] is null: *"0 / 0"* printed
  /// beside a refusal reads as a real measurement.
  const StatResult.notComputable({
    required this.definition,
    required String reason,
    this.numerator = 0,
    this.denominator = 0,
    this.caveats = const <String>[],
  }) : value = null,
       notComputableReason = reason;

  /// **null means NOT COMPUTABLE. Never 0 as a stand-in for unknown.**
  ///
  /// Zero and *cannot be computed* are different facts, and a shepherd reading a
  /// barren rate needs to know which one they are looking at. A measured `0 / 4`
  /// is a real zero and is representable; an absent denominator is not.
  final double? value;

  /// Human-readable, rendered under the number and exported verbatim.
  final String definition;

  final int numerator;
  final int denominator;
  final String? notComputableReason;

  /// What is true about the number that the number does not say. Warn, never
  /// fix: an over-100% lambing percentage is computed anyway and carries a
  /// caveat, because over 100% is normal for that metric.
  final List<String> caveats;
}

/// Which lambs count.
enum LambCount {
  /// All lambs delivered, alive or dead (Sheep Ireland).
  born('born'),

  /// Excludes stillborn (AHDB).
  bornAlive('born_alive'),

  /// Alive at the end of the season (AHDB rearing %).
  reared('reared');

  const LambCount(this.key);

  final String key;
}

/// What they are counted per.
enum FlockDenominator {
  /// AHDB, and Penn State's *"more accurate"* method.
  ewesPutToRam('ewes_to_ram'),

  /// Prolificacy.
  ewesLambed('ewes_lambed');

  const FlockDenominator(this.key);

  final String key;
}

/// The **computation** input, not the stored value.
typedef LambingPercentageDefinition = ({LambCount count, FlockDenominator per});

/// The four offered lambing-percentage conventions.
///
/// The pair [LambingPercentageDefinition] admits six combinations and only four
/// are offered, because `app_settings.percentage_definition` is a
/// `CHECK`-constrained key (03 §5.13). Modelling the four as a closed enum makes
/// an unstorable pair unconstructible, and gives the exported definition string
/// exactly one spelling per choice.
///
/// **Why the choice exists at all.** On one flock — 100 to the ram, 92 lambed,
/// 165 born — OMAFRA's convention reads **179%** and AHDB-style reads **165%**.
/// Fourteen points apart, both correct, both called *"lambing percentage"* in
/// ordinary speech. *Born alive* versus *born incl. stillborn* is the choice
/// shepherds differ on first, before they differ on the denominator, because it
/// is the less visible one — which is why stillborn treatment is in the
/// definition string itself and not a footnote.
enum LambingPercentageChoice {
  bornAlivePerEweToRam(
    'born_alive_per_ewe_to_ram',
    LambCount.bornAlive,
    FlockDenominator.ewesPutToRam,
    'lambs born alive per ewe put to the ram',
  ),
  bornInclStillbornPerEweToRam(
    'born_incl_stillborn_per_ewe_to_ram',
    LambCount.born,
    FlockDenominator.ewesPutToRam,
    'lambs born incl. stillborn per ewe put to the ram',
  ),
  bornAlivePerEweLambed(
    'born_alive_per_ewe_lambed',
    LambCount.bornAlive,
    FlockDenominator.ewesLambed,
    'lambs born alive per ewe lambed',
  ),
  rearedPerEweToRam(
    'reared_per_ewe_to_ram',
    LambCount.reared,
    FlockDenominator.ewesPutToRam,
    'lambs reared per ewe put to the ram',
  );

  const LambingPercentageChoice(this.key, this._count, this._per, this.definition);

  /// Stable storage/export key. **Byte-identical** to the strings in
  /// `app_settings.percentage_definition`'s `CHECK`, which N07-T08 freezes.
  final String key;

  /// Rendered under the number and exported verbatim. **Frozen by a test**
  /// (R61): a shepherd's 2027 season file quotes the 2026 wording, and changing
  /// one means two seasons no longer compare.
  final String definition;

  final LambCount _count;
  final FlockDenominator _per;

  LambingPercentageDefinition get definitionParts => (count: _count, per: _per);

  /// Settled by the owner (decision-record §7.0 ruling 3): UK/Ireland first, so
  /// the default follows AHDB. The setting remains user-configurable per §7.8.
  static const LambingPercentageChoice ahdbDefault = bornAlivePerEweToRam;
}

/// A **derived** four-way bucketing over `ewe_seasons.status`'s seven stored
/// keys, used only by the statistics functions.
///
/// It never round-trips to the database and never replaces the stored keys,
/// which stay canonical (R43):
///
/// ```
/// lambed                   <- 'lambed'
/// recordedBarren           <- 'barren'
/// diedOrSoldBeforeLambing  <- 'died' | 'sold' | 'aborted'
/// notRecorded              <- 'to_ram' | 'scanned' | no row
/// ```
///
/// If you find yourself writing `EweSeasonOutcome.name` into anything that
/// reaches SQLite, stop.
enum EweSeasonOutcome { lambed, recordedBarren, diedOrSoldBeforeLambing, notRecorded }

/// The seven stored keys, bucketed. An absent row is [EweSeasonOutcome.notRecorded].
///
/// **Absence of a lambing is never evidence of barrenness** — only `'barren'`,
/// which the user set deliberately, reaches [EweSeasonOutcome.recordedBarren].
EweSeasonOutcome eweSeasonOutcomeFor(String? storedStatus) => switch (storedStatus) {
  'lambed' => EweSeasonOutcome.lambed,
  'barren' => EweSeasonOutcome.recordedBarren,
  'died' || 'sold' || 'aborted' => EweSeasonOutcome.diedOrSoldBeforeLambing,
  'to_ram' || 'scanned' || null => EweSeasonOutcome.notRecorded,
  _ => throw FormatException('Unknown ewe season status', storedStatus),
};

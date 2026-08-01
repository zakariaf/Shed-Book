import 'package:shed_book/domain/time/local_date.dart';

/// Everything the season statistics divide, in one value.
///
/// **The field count disagrees across three documents and this is the reading
/// taken, raised rather than resolved silently.** 05 §6.3's printed class has
/// **twelve** fields and is the list reproduced here; its own prose one
/// paragraph later implies fourteen (*"the five lamb-derived counts … and the
/// two loss tallies"*), and CONVENTIONS §2.6 says *"13 int fields"* — which is
/// also wrong about the type, since [ewesPutToRam] is nullable. The printed
/// class wins because it is the only one of the three that is self-consistent
/// with §6.8: losses are computed by `lossesBreakdown` from `LambOutcome` rows,
/// not from a season-level tally, so there are no loss tallies to hold here. All
/// four statistics in N06-T05 and N06-T06 index these twelve by name and need no
/// thirteenth.
///
/// **Hand-written value equality over every field, and it is not decoration.**
/// `Stream.distinct()` compares with `==`; identity equality never matches; so
/// without this, every drift re-emit on any tracked table rebuilds the whole
/// Season Summary. A missing field in `==` is a stale headline number. It
/// presents as a performance bug and is a correctness bug.
final class SeasonCounts {
  const SeasonCounts({
    required this.ewesPutToRam,
    required this.ewesLambed,
    required this.lambingsTotal,
    required this.lambingsWithLambs,
    required this.lambingsScored,
    required this.lambingsScoredAssisted,
    required this.lambsBorn,
    required this.lambsBornAlive,
    required this.lambsReared,
    required this.ewesRecordedBarren,
    required this.ewesDiedOrSoldBeforeLambing,
    required this.ewesWithNoRecordedOutcome,
  });

  /// **null = not entered for this season**, and the null is load-bearing. It is
  /// not zero, and it is not *"the same as ewes lambed"* (03 §5.6). Every
  /// statistic that divides by it must refuse rather than substitute — falling
  /// back to [ewesLambed] silently changes the definition to a different
  /// published convention and reads high by however many ewes were barren, sold,
  /// died or were never entered.
  final int? ewesPutToRam;

  /// Distinct birth dams with ≥ 1 lambing carrying ≥ 1 lamb.
  final int ewesLambed;

  final int lambingsTotal;
  final int lambingsWithLambs;

  /// Ease score present.
  final int lambingsScored;

  /// Ease ≥ 2. A blank ease is **not** *"1 — unassisted"*: it means not scored,
  /// and it is excluded from both sides of the assisted rate.
  final int lambingsScoredAssisted;

  /// Alive + dead + stillborn.
  final int lambsBorn;

  /// Excludes stillborn.
  final int lambsBornAlive;

  /// Alive at season end.
  final int lambsReared;

  /// Only ewes the user explicitly marked barren. **Absence of a lambing is
  /// never evidence of barrenness.**
  final int ewesRecordedBarren;

  final int ewesDiedOrSoldBeforeLambing;
  final int ewesWithNoRecordedOutcome;

  @override
  bool operator ==(Object other) =>
      other is SeasonCounts &&
      other.ewesPutToRam == ewesPutToRam &&
      other.ewesLambed == ewesLambed &&
      other.lambingsTotal == lambingsTotal &&
      other.lambingsWithLambs == lambingsWithLambs &&
      other.lambingsScored == lambingsScored &&
      other.lambingsScoredAssisted == lambingsScoredAssisted &&
      other.lambsBorn == lambsBorn &&
      other.lambsBornAlive == lambsBornAlive &&
      other.lambsReared == lambsReared &&
      other.ewesRecordedBarren == ewesRecordedBarren &&
      other.ewesDiedOrSoldBeforeLambing == ewesDiedOrSoldBeforeLambing &&
      other.ewesWithNoRecordedOutcome == ewesWithNoRecordedOutcome;

  // Twelve arguments, so `Object.hash` is correct here — it takes up to twenty.
  // Count the fields before changing this: past twenty it silently needs
  // `Object.hashAll`.
  @override
  int get hashCode => Object.hash(
    ewesPutToRam,
    ewesLambed,
    lambingsTotal,
    lambingsWithLambs,
    lambingsScored,
    lambingsScoredAssisted,
    lambsBorn,
    lambsBornAlive,
    lambsReared,
    ewesRecordedBarren,
    ewesDiedOrSoldBeforeLambing,
    ewesWithNoRecordedOutcome,
  );
}

/// One bar of the lambing spread.
///
/// It writes its own `==` for [SeasonCounts]'s reason, and a `List<DayBirths>`
/// needs `listEquals` **on top**: a bare `.distinct()` over a `List` compares
/// list *identity* and filters nothing (05 §6.9). That is N28's call site; the
/// equality it depends on is here.
final class DayBirths {
  const DayBirths(this.date, this.births, this.ewes);

  final LocalDate date;
  final int births;
  final int ewes;

  @override
  bool operator ==(Object other) =>
      other is DayBirths && other.date == date && other.births == births && other.ewes == ewes;

  @override
  int get hashCode => Object.hash(date, births, ewes);
}

/// Stable keys, matching the `CHECK` on `lambs.status`.
enum LambStatus {
  alive('alive'),
  dead('dead'),
  stillborn('stillborn'),
  sold('sold');

  const LambStatus(this.key);

  final String key;

  static LambStatus fromKey(String k) => LambStatus.values.firstWhere(
    (LambStatus s) => s.key == k,
    orElse: () => throw FormatException('Unknown lamb status', k),
  );
}

/// The plain record the domain takes. **No drift row reaches the statistics.**
///
/// [causeKey] null means *never categorised*, and it is tallied as
/// **`unattributed`** — never under *"unknown"*. *Unknown* is a cause the user
/// can pick; *unattributed* is our word for a blank field. Never merge the two.
typedef LambOutcome = ({
  int lambId,
  LambStatus status,
  LocalDate lambingDate,
  LocalDate? deathDate,
  String? causeKey,
});

/// **The boundaries match Teagasc's published breakdown, not our invention.**
///
/// Teagasc splits at day 1–3 and day 4–7, with *"the first three days after
/// birth account for 74% of lamb mortality."* A `day1to2` / `day3to7` split
/// straddles that boundary and makes the comparison impossible without
/// arithmetic nobody does at the kitchen table. [day8to30] and [over30]
/// subdivide Teagasc's single *">day 7"* band; summing them recovers it exactly.
///
/// [stillborn] is its **own bucket**, never *"died at age 0"* — a stillborn lamb
/// has no age at death, and folding it in double-counts against any *"first 24 h
/// losses"* figure.
///
/// [sameDay] is labelled *"born and died the same day"*, **never** *"under 24
/// hours"*. Teagasc can split 0 h from < 24 h because a research post-mortem has
/// a death *time*; a civil `death_date` does not, and claiming it would be
/// exactly the silent precision inflation §12.4 forbids.
enum AgeBucket { stillborn, sameDay, day1to3, day4to7, day8to30, over30, unknownAge }

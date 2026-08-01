import 'package:shed_book/domain/ids.dart';

/// What happened to a lamb that left its birth dam (R64).
///
/// Sealed with three variants rather than an enum plus a nullable ewe id,
/// because **`setRearingDam(lambId, eweId?)` is a banned signature** — it is the
/// shape you will reach for the first time you use this type, and a nullable ewe
/// id merges *"to a bottle"* (null by intent) with *"not recorded"* (null by
/// omission). N06-T06's rearing-credit numbers differ between the two, so the
/// merge is a wrong statistic rather than an untidy API.
sealed class FosterOutcome {
  const FosterOutcome();

  /// The stored key in `foster_events.outcome`. **Frozen** by N07.
  String get key;
}

/// Fostered onto a named ewe, who becomes the **rearing dam**. The birth dam is
/// unchanged and stays recorded — that is what makes the two-dam model work.
final class ToEwe extends FosterOutcome {
  const ToEwe(this.ewe);

  final EweId ewe;

  @override
  String get key => 'to_ewe';
}

/// Reared on a bottle. There is no ewe, and that is knowledge, not absence.
final class ToBottle extends FosterOutcome {
  const ToBottle();

  @override
  String get key => 'to_bottle';
}

/// Removed from the birth dam, and where it went was not recorded.
final class RemovedUnknown extends FosterOutcome {
  const RemovedUnknown();

  @override
  String get key => 'removed_unknown';
}

import 'package:shed_book/domain/foster_outcome.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/validation/warning.dart';

/// Everything questionable about one fostering. It cannot fix any of it.
///
/// **It compares against the CURRENT REARING DAM, never the birth dam.** The
/// birth dam is immutable (decision #33) and fostering never touches it;
/// [WarningCode.fosterToSelf] is about the ewe the lamb is already on. Comparing
/// against the birth dam would warn on every ordinary re-foster and stay silent
/// on the one case this exists for.
///
/// [currentRearingDam] being null is a **third state**, not a match. A lamb with
/// `rearing_dam IS NULL` is on a bottle or unrecorded; moving it to a bottle is
/// not moving it to itself, so it is silent. This is the same distinction
/// [FosterOutcome] is sealed to keep — a nullable ewe id merges *"to a bottle"*
/// with *"not recorded"*, and N06-T06's rearing credit differs between them.
///
/// [lamb] is unused today and is in the signature because the warning is about a
/// specific animal and every future check here needs it. It is not a call-site
/// convenience: a check that cannot say which lamb it is about cannot be
/// rendered beside one.
List<Warning> checkFoster({
  required LambId lamb,
  required EweId? currentRearingDam,
  required FosterOutcome outcome,
}) {
  return switch (outcome) {
    ToEwe(:final EweId ewe) when currentRearingDam != null && ewe == currentRearingDam => <Warning>[
      const Warning(
        WarningCode.fosterToSelf,
        'That lamb is already on this ewe.',
        fieldPath: 'rearing_dam',
      ),
    ],
    // `const []`, never `[]`: this runs on every render of a foster row.
    ToEwe() || ToBottle() || RemovedUnknown() => const <Warning>[],
  };
}

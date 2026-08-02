// lib/features/lambing/foster_write_controller.dart
//
// EVERY COMMIT GOES THROUGH `guard()`. One tap is one appended event, and a
// double-fired tap appends one row rather than two (decision #22).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/write_action.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/foster_outcome.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/validation/foster_checks.dart';

final class FosterWriteController extends WriteController {
  /// **The whole screen is this one call.** `07 §8.2`'s budget is ONE tap from
  /// the Foster screen to a committed reassignment, and every intermediate step
  /// anybody is tempted to add — a confirm, a chooser, a review line — spends
  /// that budget. Spec §7.3 names this as the flow most likely to be abandoned
  /// if it takes five taps, and an abandoned foster is a lamb whose rearing
  /// nobody can account for in April.
  /// [currentRearingDam] is passed in rather than read here, because the screen
  /// already watches it and a second read would be a second answer to the same
  /// question one frame apart.
  Future<void> recordFoster(
    LambId lamb,
    FosterOutcome outcome, {
    required EweId? currentRearingDam,
  }) => guard(() async {
    final WriteOutcome result = await ref
        .read(fosterRepositoryProvider)
        .recordFoster(lamb, outcome);

    // **THE VALIDATOR RUNS HERE, NOT IN THE REPOSITORY** (R53), and it runs
    // AFTER the write. `05 §7.5` guarantee 3 is absolute: a warning never gates
    // a write. Fostering a lamb onto the ewe she is already on is a thing a
    // shepherd does at 03:20 by mistake, and refusing it would lose the record
    // of an action they took.
    return switch (result) {
      // The id is destructured from the pattern rather than re-read, which is
      // what makes the nested switch the analyzer flagged unnecessary.
      WriteCommitted(:final int? insertedId) => WriteCommitted(
        insertedId: insertedId,
        warnings: checkFoster(lamb: lamb, currentRearingDam: currentRearingDam, outcome: outcome),
      ),
      WriteFailed() || WriteRefused() => result,
    };
  });
}

/// **Always `.autoDispose`** for a write controller (`CONVENTIONS §3.4`).
final AutoDisposeNotifierProvider<FosterWriteController, WriteState> fosterWriteControllerProvider =
    NotifierProvider.autoDispose<FosterWriteController, WriteState>(FosterWriteController.new);

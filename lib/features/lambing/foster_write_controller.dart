// lib/features/lambing/foster_write_controller.dart
//
// EVERY COMMIT GOES THROUGH `guard()`. One tap is one appended event, and a
// double-fired tap appends one row rather than two (decision #22).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/write_action.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/foster_outcome.dart';
import 'package:shed_book/domain/ids.dart';

final class FosterWriteController extends WriteController {
  /// **The whole screen is this one call.** `07 §8.2`'s budget is ONE tap from
  /// the Foster screen to a committed reassignment, and every intermediate step
  /// anybody is tempted to add — a confirm, a chooser, a review line — spends
  /// that budget. Spec §7.3 names this as the flow most likely to be abandoned
  /// if it takes five taps, and an abandoned foster is a lamb whose rearing
  /// nobody can account for in April.
  Future<void> recordFoster(LambId lamb, FosterOutcome outcome) =>
      guard(() => ref.read(fosterRepositoryProvider).recordFoster(lamb, outcome));
}

/// **Always `.autoDispose`** for a write controller (`CONVENTIONS §3.4`).
final AutoDisposeNotifierProvider<FosterWriteController, WriteState> fosterWriteControllerProvider =
    NotifierProvider.autoDispose<FosterWriteController, WriteState>(FosterWriteController.new);

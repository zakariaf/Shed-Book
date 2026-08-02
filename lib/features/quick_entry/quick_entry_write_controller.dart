// lib/features/quick_entry/quick_entry_write_controller.dart
//
// CONVENTIONS §4.1's <feature>_write_controller.dart. Two verbs, both through
// guard(), which is N12-T04's double-tap defence getting its first real caller.
//
// `lambingWriteControllerProvider` IS THE WRONG CONTROLLER FOR THE LAMBING TAP,
// and using it does not build. 07 §6.1 names it and CONVENTIONS §3.4 declares
// it, but it lives in lib/features/lambing/ — Quick Entry importing it is a
// layer.sibling violation (rule 6), the gate fails, and it should. That
// controller is N16's, for writes made FROM Lambing Entry. This one reaches the
// repository through lib/data/, which layer rule 5 permits.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/write_action.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/ids.dart';

/// `final` because [WriteController] is `base`: Dart requires every subtype of a
/// base class to be `base`, `final` or `sealed`.
final class QuickEntryWriteController extends WriteController {
  /// The confirm key's "Create 412" arm.
  ///
  /// **`EntryContext.liveEntry` is not a default and not a convention** — it is
  /// the parameter that makes a refusal unreachable on this screen (decision
  /// #91). A shepherd mid-lambing is never told to pay.
  Future<void> createEwe(String tag) => guard(() async {
    final FlockRepository repo = ref.read(flockRepositoryProvider);
    return repo.createEwe(tag: tag, context: EntryContext.liveEntry);
  });

  /// The "Lambing" tap. **The row exists before any screen is pushed.**
  ///
  /// THE TWO SIGNATURES DO NOT COMPOSE, AND THE OBVIOUS RESOLUTION IS THE WRONG
  /// ONE. `beginLambing` returns a `LambingId` and throws; `guard()` takes a
  /// `Future<WriteOutcome> Function()`. `07 §6.1`'s printed snippet calls the
  /// verb in a bare try/catch OUTSIDE any guard — which deletes the double-tap
  /// defence on the product's central write. `07 §6.1` is amended in this
  /// commit.
  ///
  /// The adaptation is not an invention: R33 says a bare `int` appears "as
  /// `WriteCommitted.insertedId`, which the single reading call site wraps."
  /// This is that call site. A throw from the repository is caught by `guard()`
  /// and surfaces as `WriteFailed(UnexpectedFailure)`, never as silence.
  ///
  /// N16 pushes `LambingEntryScreen` from here, using the id this outcome
  /// already carries — so it is not re-plumbed later. There is no route helper
  /// for a screen that does not exist yet (critique S2).
  Future<void> beginLambing(EweId ewe) => guard(() async {
    final LambingRepository repo = ref.read(lambingRepositoryProvider);
    final LambingId id = await repo.beginLambing(ewe);
    return WriteCommitted(insertedId: id.value);
  });
}

/// `.autoDispose`, always, for a write controller (`02 §4.2`,
/// `CONVENTIONS §3.4`).
final AutoDisposeNotifierProvider<QuickEntryWriteController, WriteState>
quickEntryWriteControllerProvider =
    NotifierProvider.autoDispose<QuickEntryWriteController, WriteState>(
      QuickEntryWriteController.new,
    );

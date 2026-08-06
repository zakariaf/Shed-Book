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

  /// One press of the slab: **one lamb**.
  ///
  /// **THIS IS THE PRODUCT'S CENTRAL ACT AND THE SLAB HAD NO HANDLER AT ALL** —
  /// `onSlab: () {}`. `indelible.md §8`: *"Press the slab. One stroke prints in
  /// the lamb column with a 10ms haptic tick, and the row is now a complete,
  /// valid, honestly timestamped lambing. Three taps. About six seconds."* The
  /// three taps existed; the third did nothing.
  ///
  /// **THE SAME VERB OPENS THE ROW AND ADDS TO IT**, which is what makes the
  /// forty-minute window work. The first press begins the lambing and lands lamb
  /// one; every press after it lands another lamb on that same row, and the birth
  /// type re-derives from the count — `SINGLE`, then `TWIN (COUNTED)`, then
  /// `TRIPLET (COUNTED)`. **Nobody ever chooses "triplet" from a list** (P8), and
  /// that is why there is no chooser here to choose it from.
  ///
  /// Both writes are inside **one** `guard()`, so a double tap on a cold thumb
  /// cannot open a lambing twice — which would file a set of twins as two singles
  /// and is the exact failure the guard exists for.
  Future<void> addLamb({required EweId ewe, LambingId? into}) => guard(() async {
    final LambingRepository repo = ref.read(lambingRepositoryProvider);
    final LambingId lambing = into ?? await repo.beginLambing(ewe);
    await repo.addLamb(lambing);
    return WriteCommitted(insertedId: lambing.value);
  });

  /// Strikes a lambing the shepherd has just committed.
  ///
  /// It goes through `guard()` like every other write: a double tap on the
  /// strike word must not strike twice, and the second one would be striking a
  /// row that is already struck.
  Future<void> strike(LambingId id) => guard(() async {
    final LambingRepository repo = ref.read(lambingRepositoryProvider);
    return repo.strikeLambing(id);
  });
}

/// `.autoDispose`, always, for a write controller (`02 §4.2`,
/// `CONVENTIONS §3.4`).
final AutoDisposeNotifierProvider<QuickEntryWriteController, WriteState>
quickEntryWriteControllerProvider =
    NotifierProvider.autoDispose<QuickEntryWriteController, WriteState>(
      QuickEntryWriteController.new,
    );

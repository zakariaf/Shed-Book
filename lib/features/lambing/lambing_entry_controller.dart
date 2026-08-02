// lib/features/lambing/lambing_entry_controller.dart
//
// ONE PROVIDER TODAY, and the emptiness is deliberate.
// `lambingEntryControllerProvider` (screen state) and
// `lambingWriteControllerProvider` arrive in T02, when there is state to hold
// and a write to guard. Declaring them now would be declaring two providers
// nobody reads.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/write_action.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/care_kind.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/lambing_ease.dart';

/// The screen's one read.
///
/// **`.family` on a `LambingId`**, because the screen is opened for one lambing
/// and the id arrives through the route rather than through state.
///
/// **`.autoDispose`**, because unlike Quick Entry's deck this is not a hub: the
/// shepherd opens a lambing, fills it in and leaves, and a subscription that
/// outlived the screen would keep a statement live on a phone in a pocket.
final AutoDisposeStreamProviderFamily<LambingEntryData, LambingId> lambingEntryProvider =
    StreamProvider.autoDispose.family<LambingEntryData, LambingId>((ref, LambingId id) async* {
      await ref.watch(databaseProvider.future);
      yield* ref.watch(lambingRepositoryProvider).watchLambingEntry(id);
    });

/// The screen's writes.
///
/// `lambingControllerProvider` is a banned spelling (`07 §6.1`): the noun is
/// **write controller**, and a name that drops the word invites a second
/// controller holding read state.
final class LambingWriteController extends WriteController {
  /// `addLamb` throws rather than returning a `WriteOutcome`, so the guard body
  /// converts.
  ///
  /// **The id is discarded here on purpose** — the stream re-emits with the new
  /// row, so the screen learns about the lamb the same way it learns about
  /// every other change. A controller that held the id would be a second source
  /// of truth about what is on the page.
  ///
  /// A failure reaches `guard()`'s catch-all as an `UnexpectedFailure`, which is
  /// correct: a lamb that will not insert is a bug, not a storage condition the
  /// shepherd can act on.
  Future<void> addLamb(LambingId lambing) => guard(() async {
    await ref.read(lambingRepositoryProvider).addLamb(lambing);
    return const WriteCommitted();
  });

  /// One tap is one committed score. There is no Save button and no draft, and
  /// `guard()` refuses to run concurrently — so a double-fired tap (decision
  /// #22) commits one value rather than two.
  Future<void> setEase(LambingId lambing, LambingEase ease) =>
      guard(() => ref.read(lambingRepositoryProvider).setEase(lambing, ease));

  /// One press is one committed care event. `guard()` refuses to run
  /// concurrently, so a double-fired press writes one row.
  Future<void> addCare(
    CareSubject subject, {
    required CareKind kind,
    int? volumeMl,
    ColostrumMethod? method,
  }) => guard(
    () => ref
        .read(lambingRepositoryProvider)
        .addCare(subject, kind: kind, volumeMl: volumeMl, method: method),
  );

  /// Strikes rather than deletes — see `LambingRepository.removeCare`.
  Future<void> removeCare(CareEventId id) =>
      guard(() => ref.read(lambingRepositoryProvider).removeCare(id));
}

/// **Always `.autoDispose`** for a write controller (`CONVENTIONS §3.4`).
final AutoDisposeNotifierProvider<LambingWriteController, WriteState>
lambingWriteControllerProvider = NotifierProvider.autoDispose<LambingWriteController, WriteState>(
  LambingWriteController.new,
);

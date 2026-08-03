// lib/features/treatments/treatments_controller.dart
//
// ONE STATEMENT, WITH THE MODE BOUND RATHER THAN BRANCHED. Two providers — one
// per mode — would be two dependency lists that can disagree about when the
// screen is stale, and a screen that went stale in one mode only is the hardest
// kind of bug to believe.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/data/treatment_repository.dart';

/// Which segment is showing. **Screen state, and nothing else** — it is not
/// persisted, because which segment a shepherd left the screen on says nothing
/// about what they want next time.
final class TreatmentModeController extends AutoDisposeNotifier<TreatmentMode> {
  @override
  TreatmentMode build() => TreatmentMode.countdown;

  void show(TreatmentMode mode) => state = mode;
}

/// **COUNTDOWN FIRST.** The screen opens on what is still running, because that
/// is the question a shepherd has at the gate — *can she go?* The book is what
/// they open in the office.
final AutoDisposeNotifierProvider<TreatmentModeController, TreatmentMode> treatmentModeProvider =
    NotifierProvider.autoDispose<TreatmentModeController, TreatmentMode>(
      TreatmentModeController.new,
    );

/// The list, for the mode showing.
///
/// **`.family` ON THE MODE** rather than reading `treatmentModeProvider` inside,
/// so switching segments is a new subscription with its own statement rather
/// than a re-run of one that was watching the other.
final AutoDisposeStreamProviderFamily<List<TreatmentRow>, TreatmentMode> treatmentsProvider =
    StreamProvider.autoDispose.family<List<TreatmentRow>, TreatmentMode>((
      ref,
      TreatmentMode mode,
    ) async* {
      await ref.watch(databaseProvider.future);
      yield* ref.watch(treatmentRepositoryProvider).watchTreatments(mode);
    });

/// One treatment's stored withdrawals, watched.
///
/// **A FAMILY ON THE ID, NOT A NESTED STREAM.** The first version awaited this
/// inside an `await for` over the treatments stream, and it never emitted —
/// drift serialises, so a stream consumed inside another stream's loop can wait
/// on a connection the outer loop is holding. It is also the wrong shape: the
/// previous treatment is already in the list the screen watches, so the only
/// thing left to look up is its periods.
final AutoDisposeStreamProviderFamily<List<StoredWithdrawal>, TreatmentId>
storedWithdrawalsProvider = StreamProvider.autoDispose.family<List<StoredWithdrawal>, TreatmentId>((
  ref,
  TreatmentId treatment,
) async* {
  await ref.watch(databaseProvider.future);
  yield* ref.watch(treatmentRepositoryProvider).watchWithdrawals(treatment);
});

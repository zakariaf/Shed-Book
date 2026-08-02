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
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/domain/birth_type.dart';
import 'package:shed_book/domain/care_kind.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/lambing_ease.dart';
import 'package:shed_book/domain/stats/season_counts.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/units/grams.dart';
import 'package:shed_book/domain/validation/lambing_checks.dart';
import 'package:shed_book/domain/validation/warning.dart';

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

  /// Corrects the header time. The warnings recompute on the next emission —
  /// `lambingWarningsProvider` watches the same statement, so nothing needs to
  /// be invalidated and nothing may be (`02 §4.1`).
  Future<void> correctOccurredAt(LambingId lambing, Instant when) =>
      guard(() => ref.read(lambingRepositoryProvider).correctOccurredAt(lambing, when));

  /// The deliberate declaration. **Writes the type and leaves the lambs alone.**
  Future<void> setBirthType(LambingId lambing, BirthType type) =>
      guard(() => ref.read(lambingRepositoryProvider).setBirthType(lambing, type));
}

/// The warnings for one lambing, recomputed on every emission.
///
/// **THE CONTROLLER RUNS THE VALIDATOR; THE REPOSITORY STRUCTURALLY CANNOT**
/// (R53, `05 §7.5` guarantee 4). There is no `warnings` column and there never
/// will be — decision #54 closes that door permanently — so this is derived, not
/// stored, and it is derived from the SAME statement the screen already watches
/// rather than from a second read.
///
/// **`checkLambing` IS NOT REIMPLEMENTED HERE.** It was written at N06-T03 and
/// this provider only feeds it. If a comparison appears in this file, a
/// validator is being reinvented at the screen.
///
/// Two mechanisms exist and neither is the other's cache: `lambing_consistency`
/// (the view) drives the persistent badge on the flock list and the ewe card —
/// *"a contradiction found at 3am is still findable at 9am"* — and this drives
/// the mark on this screen. Neither may write.
final AutoDisposeProviderFamily<List<Warning>, LambingId> lambingWarningsProvider = Provider
    .autoDispose
    .family<List<Warning>, LambingId>((ref, LambingId id) {
      final LambingEntryData? data = ref.watch(lambingEntryProvider(id)).value;
      if (data == null) {
        return const <Warning>[];
      }

      return checkLambing(
        // NULL IS NOT A CONTRADICTION (R6, `03 §5.4`). No declaration, no query
        // mark — the view guards this explicitly because `COUNT(…) <> NULL` is
        // NULL, which would make `is_mismatched` three-valued for every
        // in-progress lambing, and the Dart side needs the same guard.
        declaredBirthType: data.lambing.declaredBirthType,
        // STRUCK LAMBS ARE EXCLUDED, and the label already says so: a
        // `TWIN (COUNTED, 1 STRUCK)` row has three `lambs` rows and two strokes.
        // Comparing against the raw row count puts a mark on a record the
        // shepherd has already corrected.
        lambCount: data.lambs.where((LambEntryRow l) => !l.struck).length,
        time: data.lambing.time,
        storedLocalDate: LocalDate.of(data.lambing.time.effective),
        // FROM THE HEADER, WHICH THE ONE STATEMENT ALREADY CARRIES. A second
        // read for the season start would be a second content statement, and
        // `07 §1.2` allows one.
        seasonStart: data.lambing.seasonStart,
        now: appNow(),
        birthWeights: <Grams?>[
          for (final LambEntryRow l in data.lambs)
            if (!l.struck) l.birthWeight,
        ],
        lambOutcomes: <({LocalDate? deathDate, bool isDead})>[
          for (final LambEntryRow l in data.lambs)
            if (!l.struck)
              (
                deathDate: null,
                isDead: l.status == LambStatus.dead || l.status == LambStatus.stillborn,
              ),
        ],
      );
    });

/// **Always `.autoDispose`** for a write controller (`CONVENTIONS §3.4`).
final AutoDisposeNotifierProvider<LambingWriteController, WriteState>
lambingWriteControllerProvider = NotifierProvider.autoDispose<LambingWriteController, WriteState>(
  LambingWriteController.new,
);

// lib/features/flock/flock_controller.dart
//
// ONE STATEMENT PRODUCES THE LIST (`07 §1.2`), and the filters narrow it in SQL
// rather than in Dart. A `.where` over the streamed rows would look identical on
// a six-ewe test database and read all four hundred rows off the disk on a real
// one — which is the difference the fixture exists to expose.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/core/write_action.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/domain/ewe_status.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/data/providers.dart';

export 'package:shed_book/data/flock_repository.dart' show FlockFilter, FlockFilters, FlockRow;

/// Which of `spec §7.7`'s five filters are on. **Screen state**, not persisted:
/// a filter a shepherd left on last night is a filter that hides animals from
/// them tonight without saying why.
final class FlockFilterController extends AutoDisposeNotifier<FlockFilters> {
  @override
  FlockFilters build() => const FlockFilters();

  void toggle(FlockFilter f) => state = state.toggle(f);

  void clear() => state = const FlockFilters();
}

/// How many ewes each filter would leave, for the counts Indelible prints after
/// each word.
///
/// **ONE STATEMENT PER FILTER, AND THAT IS SIX RATHER THAN ONE — SAID OUT LOUD
/// BECAUSE `07 §1.2` IS A RULE ABOUT THE LIST.** The rule binds the list the
/// screen renders; the counts are a separate, unfiltered read that exists so a
/// shepherd knows a filter is empty BEFORE tapping it. They are derived from the
/// single unfiltered result set in Dart rather than by six round trips.
final AutoDisposeProvider<FlockFilterCounts?>
flockFilterCountsProvider = Provider.autoDispose<FlockFilterCounts?>((ref) {
  // **SWITCHED ON THE ASYNCVALUE** (#18, `rp3.value_or_null` — and that rule scans comments, so the banned accessor is not spelled here either). Coalescing
  // an absent list to an empty one would print `BARREN 0` against a flock
  // whose statement has not returned yet — a count that is *not computed*
  // rendered as a count that is *zero*, which is #58 wearing another hat.
  // Null means the line has nothing true to print, and the screen reserves
  // its height instead.
  final List<FlockRow> all = switch (ref.watch(flockListProvider(const FlockFilters()))) {
    AsyncData<List<FlockRow>>(value: final List<FlockRow> rows) => rows,
    _ => const <FlockRow>[],
  };
  if (all.isEmpty) {
    return null;
  }
  final Instant now = appNow();
  return FlockFilterCounts(
    notYetLambed: all.where((FlockRow r) => r.notYetLambed).length,
    currentlyPenned: all.where((FlockRow r) => r.isPenned).length,
    underTreatment: all.where((FlockRow r) => r.isUnderTreatment(now)).length,
    tripletBearing: all.where((FlockRow r) => r.tripletBearing).length,
    barren: all.where((FlockRow r) => r.barren).length,
  );
});

/// Creating a ewe from the Flock screen, and setting her status.
///
/// **`EntryContext.calm`, AND THAT IS THE POINT OF THE TASK.** This is the one
/// place the cap may honestly speak: daylight work, nobody holding a lamb. Quick
/// Entry passes `liveEntry`, where a refusal is unreachable by construction —
/// *"a shepherd mid-lambing is never told to pay"* (#91).
///
/// **EVERY VERB THROUGH `guard()`**, which is the double-tap defence: a cold
/// thumb on capacitive glass through a bag double-fires, and without it the
/// second fire is a second ewe. The outcome arrives as *state* — these are event
/// verbs returning `Future<void>`, never a value the caller reads back.
///
/// `final` because [WriteController] is `base`.
final class FlockWriteController extends WriteController {
  /// **THROUGH THE PROVIDER, NOT A CONSTRUCTOR.** `lib/features/` may not import
  /// `lib/core/db/` (`layer.features`), and the first draft built a
  /// `FlockRepository` here from a raw `AppDatabase` — which the gate refused. A
  /// feature does not get to know a database exists; `flockRepositoryProvider`
  /// is the seam, and it already carries the policy this needs.
  Future<void> createEwe(String tag) => guard(
    () => ref.read(flockRepositoryProvider).createEwe(tag: tag, context: EntryContext.calm),
  );

  /// R41 — a **set**, not an edit, and there is no undo verb for it. It is
  /// guarded like every other write because culling is destructive: a double tap
  /// must write one status change, not two.
  Future<void> setStatus(EweId ewe, EweStatus status) =>
      guard(() => ref.read(flockRepositoryProvider).setStatus(ewe, status));

  /// **THE CARD'S VERBS LIVE HERE, AND THAT IS A LAYER FACT RATHER THAN A
  /// PREFERENCE.** Layer rule 6 forbids `lib/features/flock/` from importing
  /// `lib/features/lambing/` or `lib/features/pens/`, so
  /// `lambingWriteControllerProvider` is unreachable from the Ewe Card.
  /// `CONVENTIONS §4.4` rule 2 — one write controller per **feature** — is what
  /// makes that fine: the Flock screen and the Ewe Card are one feature folder.
  /// N14-T03 hit the identical wall on Quick Entry; this is its resolution,
  /// unchanged.
  Future<void> recordObservation(EweId ewe, {required String kind, String? note}) => guard(
    () => ref.read(lambingRepositoryProvider).recordObservation(ewe, kind: kind, note: note),
  );

  /// R32: `beginLambing` returns an id and **throws**. It is adapted to
  /// `guard()`'s `Future<WriteOutcome>` exactly as N14-T03 adapted it — the id
  /// travels back as `WriteCommitted.insertedId`, R33's single permitted call
  /// site, and a throw surfaces as `WriteFailed(UnexpectedFailure)` rather than
  /// as silence.
  ///
  /// **THE ROW EXISTS BEFORE ANY SCREEN IS PUSHED.** There is no draft and
  /// nothing to lose if the phone dies between the tap and the push.
  Future<void> beginLambing(EweId ewe) => guard(() async {
    final LambingId id = await ref.read(lambingRepositoryProvider).beginLambing(ewe);
    return WriteCommitted(insertedId: id.value);
  });

  /// R42 — **barren is a season participation outcome**, `ewe_seasons.status`,
  /// owned by `SeasonRepository`. It is not a status change and it is not an
  /// observation; three different columns, three different facts.
  Future<void> recordBarren(EweId ewe) =>
      guard(() => ref.read(seasonRepositoryProvider).setEweSeasonStatus(ewe, 'barren'));
}

/// `.autoDispose`, always, for a write controller (`CONVENTIONS §3.4`).
final AutoDisposeNotifierProvider<FlockWriteController, WriteState> flockWriteControllerProvider =
    NotifierProvider.autoDispose<FlockWriteController, WriteState>(FlockWriteController.new);

/// The five counts, all five present or it does not compile.
final class FlockFilterCounts {
  const FlockFilterCounts({
    required this.notYetLambed,
    required this.currentlyPenned,
    required this.underTreatment,
    required this.tripletBearing,
    required this.barren,
  });

  final int notYetLambed;
  final int currentlyPenned;
  final int underTreatment;
  final int tripletBearing;
  final int barren;
}

final AutoDisposeNotifierProvider<FlockFilterController, FlockFilters> flockFilterProvider =
    NotifierProvider.autoDispose<FlockFilterController, FlockFilters>(FlockFilterController.new);

/// The list.
///
/// **`keepAlive`, per `CONVENTIONS §3.2`** — Flock is a hub read (`02 §4.2`), so
/// it survives a push to a ewe card and back rather than re-running its
/// statement over four hundred rows every time a shepherd looks at one animal.
///
/// **`.family` on the filters** rather than reading `flockFilterProvider` inside:
/// ticking a filter becomes a new subscription with its own statement, instead of
/// a re-run of one that was watching the previous set.
final StreamProviderFamily<List<FlockRow>, FlockFilters> flockListProvider =
    StreamProvider.family<List<FlockRow>, FlockFilters>((ref, FlockFilters filters) async* {
      // **ONE STREAM. NO `rxdart`, AND NOTHING THAT MERGES TWO OF THEM**
      // (decision #12, `02 §4.1`). Two streams updated in one transaction can
      // emit at different times, so a merged view shows a state that never
      // existed in the database — drift#3338, which its maintainer calls working
      // as intended.
      //
      // The banned operator is deliberately not spelled here: `stream.combine`
      // scans source text, COMMENTS INCLUDED, and failed the build on the draft
      // of this paragraph that named it. The draft after that cited
      // `media_sweeper_test.dart`'s split clock literal by name and tripped
      // `time.dart_clock` the same way. Two rules, two comments, both of them
      // mine — the gate does not read intent, and that is the point of it.
      // **RULING N1: `underTreatment` IS APPLIED HERE, NOT IN SQL.** It is the
      // one filter whose answer depends on today, and a date bound into a
      // `watch()` statement is bound once and never advances — a phone left on
      // this page overnight would filter against yesterday. The statement returns
      // `latest_clear_date` and `unrecorded_withdrawal`, both clock-free, and
      // `FlockRow.isUnderTreatment` compares them against `appNow()`.
      //
      // **A ewe whose withdrawal nobody typed is UNKNOWN, and stays in the list**
      // (§12.1). Hiding her would be the app deciding she is clear.
      yield* watchFlockList(await ref.watch(databaseProvider.future), filters).map(
        (List<FlockRow> rows) => filters.underTreatment
            ? rows.where((FlockRow r) => r.isUnderTreatment(appNow())).toList()
            : rows,
      );
    });

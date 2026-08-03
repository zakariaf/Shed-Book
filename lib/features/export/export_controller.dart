// lib/features/export/export_controller.dart
//
// WHAT THE SCREEN STATES BEFORE ANYTHING IS TAPPED, and the state of what is
// being built.
//
// The counts are read from **one** drift statement, never fanned in from four —
// `07 §1.2`'s one-query rule, and `00-README` §8 step 14 makes combining drift
// streams in Dart a build-breaking defect rather than a preference: drift's open
// issue #3338 tears state across combined streams.
//
// The banned combinator is not named here; `stream.combine` scans the source
// text, so a comment naming it fails the rule that forbids it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/data/export_repository.dart';
import 'package:shed_book/data/models.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';

/// `09 §1.2`'s record, and the two media fields are `09 §1.3`'s amendment to
/// `07 §13.1` rather than an addition: the *share photos* row needs a count and
/// a size, and the table they come from has to be in `readsFrom` or the row is
/// stale until an unrelated write happens.
typedef ExportCounts = ({
  int ewes,
  int lambs,
  int treatments,
  int mediaAssets,
  int mediaBytes,
  Instant? lastExportedAt,
  int seasonYear,
});

/// **`.autoDispose`** (`CONVENTIONS §3.2`). A screen the shepherd visits in
/// daylight, twice a season, has no business holding a database listener open
/// for the rest of the night.
final AutoDisposeStreamProvider<ExportCounts> exportCountsProvider =
    StreamProvider.autoDispose<ExportCounts>((ref) async* {
      final SeasonId season = await ref.watch(currentSeasonProvider.future);
      final ExportRepository repo = await ref.watch(exportRepositoryProvider.future);
      yield* repo.watchCounts(season);
    });

/// The season every artefact on this screen is scoped to.
///
/// `09 §1.1`: **every artefact except the backup is one season.** The year the
/// file names are built from is not read here — it rides along inside the counts
/// statement, so the name and the counts can never be one frame apart.
final FutureProvider<SeasonId> currentSeasonProvider = FutureProvider<SeasonId>((ref) async {
  // THE DATABASE IS AWAITED FIRST, and it is not ceremony. `settingsProvider`
  // reads `settingsRepositoryProvider`, which calls `requireValue` on the
  // database synchronously — so watching settings before the database has opened
  // throws `Tried to call requireValue on an AsyncValue that has no value`.
  //
  // Measured: without this line the Export screen paints its rows, `counts`
  // stays null for ever, and the share button silently does nothing. No
  // exception reaches the test, because the failure is inside a provider whose
  // value the screen reads as `.value` — which is `null` on error exactly as it
  // is on loading. `pen_board_screen.dart` records the same trap for
  // `settleThresholdHoursProvider`.
  await ref.watch(databaseProvider.future);
  final AppSetting settings = await ref.watch(settingsProvider.future);
  final int? current = settings.currentSeason;
  if (current == null) {
    throw StateError('no current season');
  }
  return SeasonId(current);
});

/// Which artefact is being assembled, if any.
///
/// **A row-level state, not a screen-level one.** `07 §13.2` says the screen
/// never blocks and never covers itself with a modal: the building state is
/// determinate progress *on the row that was tapped*, and every other row stays
/// live. A single `isBusy` bool on the screen would be the modal in disguise.
final class ExportController extends AutoDisposeNotifier<String?> {
  @override
  String? build() => null;

  void building(String rowKey) => state = rowKey;

  void idle() => state = null;
}

final AutoDisposeNotifierProvider<ExportController, String?> exportControllerProvider =
    NotifierProvider.autoDispose<ExportController, String?>(ExportController.new);

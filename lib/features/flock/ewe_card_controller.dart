// lib/features/flock/ewe_card_controller.dart
//
// **THE RETENTION FEATURE.** In year two, *"what did 412 do last year?"* takes
// one second instead of an evening with a shoebox — and `00-README` §9 says out
// loud that this is the one calm screen that is not filler.
//
// `CONVENTIONS §3.2` types `eweTimelineProvider` on `List<TimelineRow>` and no
// document declares that class's fields; `07 §4.1` fixes the seven **columns**.
// This file is the Dart shape, and every later task in the epic renders whatever
// is decided here.
//
// **THE STATEMENT IS NOT HERE AND CANNOT BE.** Layer rule 5 bans
// `package:drift/*` and `lib/core/db/` from `lib/features/` outright, and
// `customSelect` is a drift API — so the SQL lives in `FlockRepository` and the
// provider lives here. Same split `02 §5.1` prints for the pen board.
//
// **`02 §3.1`'s `EweCardController` / `EweCardData` snippet is not this screen's
// architecture.** It exists to print the corrected 2.6.1 family shape after the
// research notes got it wrong, and it calls `repo.eweCard(arg)` — a method
// `CONVENTIONS §2.13` does not declare. Copying it would put DATA in a screen
// controller, which `§4.4` rule 1 forbids outright.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';

/// **THE TWO TYPES LIVE IN THE REPOSITORY, RE-EXPORTED HERE.** `CONVENTIONS §3.2`
/// puts `eweTimelineProvider` in this file and the task text drafts the classes
/// beside it — but `layer.data` forbids `lib/data/` from naming a screen, so a
/// repository method returning a type declared under `lib/features/` does not
/// build. `FlockRow` already sits on the other side of that seam for the same
/// reason, and the export is what makes the split invisible to a screen.
export 'package:shed_book/data/flock_repository.dart'
    show EarlierAnimal, EweSummaryCounts, TimelineKind, TimelineRow;

/// Her whole history, one statement, most recent first.
///
/// **`.autoDispose.family`, both of them** (`CONVENTIONS §3.2`, §3.4), and the
/// reason is arithmetic: a `keepAlive` family holds one live stream per ewe
/// opened — four hundred of them by the end of a night. `EweId` is an extension
/// type over `int` with real `==`, so the family key does not mint a new
/// provider per rebuild (R33).
final AutoDisposeStreamProviderFamily<List<TimelineRow>, EweId> eweTimelineProvider = StreamProvider
    .autoDispose
    .family<List<TimelineRow>, EweId>((ref, EweId eweId) async* {
      // **THE DATABASE IS AWAITED FIRST, AND IT IS NOT CEREMONY.**
      // `flockRepositoryProvider` reads `requireValue` on `databaseProvider`, so
      // reading it before the database has opened throws — and on a
      // `StreamProvider` a throw is an `AsyncError`, which renders the error
      // panel on the first frame of a card that is about to work perfectly well.
      // Awaiting the future is what makes the loading arm mean *loading*.
      await ref.watch(databaseProvider.future);
      yield* ref.read(flockRepositoryProvider).watchEweTimeline(eweId);
    });

/// The four counts behind the summary line, straight off `ewe_summaries`.
///
/// **A SINGLE-ROW LOOKUP RATHER THAN A SECOND CONTENT STATEMENT** — `07 §1.2`
/// permits exactly this beside the timeline, because the line *"must never wait
/// for an aggregate"*.
final AutoDisposeStreamProviderFamily<EweSummaryCounts?, EweId> eweSummaryProvider = StreamProvider
    .autoDispose
    .family<EweSummaryCounts?, EweId>((ref, EweId eweId) async* {
      await ref.watch(databaseProvider.future);
      yield* ref.read(flockRepositoryProvider).watchEweSummary(eweId);
    });

/// The four clauses **as numbers**. Nothing here formats, and nothing here reads
/// a clock, a locale or a `Terminology` — that is the widget's half.
///
/// The split is deliberate: the arithmetic is testable without a widget tree and
/// the wording is testable without arithmetic.
@immutable
final class EweSummaryFacts {
  const EweSummaryFacts({
    required this.seasonsRecorded,
    required this.lambingsRecorded,
    required this.assistedLambings,
    required this.scoredLambings,
    this.averageLitterSize,
    this.lastObservationKind,
    this.lastObservationYear,
  });

  final int seasonsRecorded;
  final int lambingsRecorded;
  final int assistedLambings;
  final int scoredLambings;

  /// **`null` MEANS NOT COMPUTABLE, AND IT IS NEVER `0.0`** (`05 §6.5`). A ewe
  /// with one lambing and no lambs recorded yet is a common, transient state —
  /// the row is created on screen entry (#11) — and `avg 0.0` would be the app
  /// asserting something false about a live animal. The clause is dropped.
  final double? averageLitterSize;

  /// A `vocab_terms` key, e.g. `obs_prolapse`. **Resolved at the presentation
  /// edge**, never here: `lib/features/` may reach `AppLocalizations`, and this
  /// class is the arithmetic half.
  final String? lastObservationKind;
  final int? lastObservationYear;

  /// `05 §6.7`: **coverage is ALWAYS reported when it is partial.** A blank ease
  /// leaves both sides of the assisted count — reading it as *unassisted*
  /// deflates the number and is the silent inference §12.4 forbids.
  bool get assistedCoverageIsPartial => scoredLambings < lambingsRecorded;

  /// `null` when no lambing carries an ease score at all — `notComputable`,
  /// **not** `0`. The clause is absent rather than zero.
  bool get assistedIsComputable => scoredLambings > 0;
}

/// The one place the arithmetic lives.
///
/// **`newestObservation` COMES FROM THE TIMELINE THE SCREEN IS ALREADY
/// WATCHING**, not from a second statement and not from a new column.
/// `ewe_summaries` stores `last_observation_season` — a season foreign key, not
/// a kind — so the *"prolapsed 2025"* clause has no column behind it and adding
/// one would be a migration.
///
/// Two consequences fall out of that column set, and they are not a conflict:
///
///   * the **Flock row** has only `last_observation_season`, so it honestly
///     renders **three** clauses — which is what `indelible.md §7.4` draws;
///   * the **card** has the timeline, so it renders **four** — which is what
///     `§8` screen 2 draws.
EweSummaryFacts eweSummaryFacts(
  EweSummaryCounts? summary, {
  ({String kind, int year})? newestObservation,
}) {
  if (summary == null) {
    // **NOT A ROW OF ZEROES.** No row means nothing has been summarised yet, and
    // every count here is *not recorded* rather than *none*. The widget prints
    // "No seasons recorded"; a zeroed average would print `avg 0.0`.
    return EweSummaryFacts(
      seasonsRecorded: 0,
      lambingsRecorded: 0,
      assistedLambings: 0,
      scoredLambings: 0,
      lastObservationKind: newestObservation?.kind,
      lastObservationYear: newestObservation?.year,
    );
  }

  return EweSummaryFacts(
    seasonsRecorded: summary.seasonsRecorded,
    lambingsRecorded: summary.lambingsRecorded,
    assistedLambings: summary.assistedLambings,
    scoredLambings: summary.scoredLambings,
    // **DIVIDED BY LAMBINGS, NOT BY SEASONS** (`05 §6.5`: litter size is
    // `lambsBorn ÷ ewesLambed`, aggregated by birth dam). A ewe with three
    // recorded seasons and two lambings has an average over 2 — dividing by
    // seasons deflates it, and there is no note on the card saying so.
    averageLitterSize: summary.lambingsRecorded == 0
        ? null
        : summary.lambsBorn / summary.lambingsRecorded,
    lastObservationKind: newestObservation?.kind,
    lastObservationYear: newestObservation?.year,
  );
}

/// The animals who held this card's tag before her.
///
/// **KEYED ON THE TAG, NOT ON THE EWE, AND THAT IS DELIBERATE.** The screen
/// already holds the tag — it is what the shepherd tapped to get here — so
/// keying on it avoids a lookup whose only purpose would be to read back a
/// string the caller already has. The ewe id is what the query EXCLUDES.
///
/// `07 §1.2` permits a single-row-shaped lookup beside the content statement.
/// What it does not permit is merging this with the timeline in Dart: they are
/// two independent widgets watching two independent providers, which is the
/// shape §1.2 explicitly allows.
final AutoDisposeStreamProviderFamily<List<EarlierAnimal>, ({EweId ewe, String tag})>
earlierAnimalsProvider = StreamProvider.autoDispose
    .family<List<EarlierAnimal>, ({EweId ewe, String tag})>((
      ref,
      ({EweId ewe, String tag}) key,
    ) async* {
      await ref.watch(databaseProvider.future);
      yield* ref
          .read(flockRepositoryProvider)
          .watchEarlierAnimalsWithTag(key.tag, excluding: key.ewe);
    });

/// Her history, grouped by the season each row was filed under.
///
/// **THE SEASON IS A STORED FOREIGN KEY, NOT A YEAR DERIVED FROM THE INSTANT.**
/// A lambing at 01:30 on the clocks-back night belongs to the season it was
/// filed under, whatever the wall clock did that night — and `season_year` comes
/// from a join for exactly that reason.
///
/// **A NOTE WITH NO SEASON IS ITS OWN GROUP, NOT FOLDED INTO THE NEWEST ONE.**
/// `notes.season` is the one nullable one (`03 §5.12`); attaching a seasonless
/// note to whichever season happened to be current when it was read would be the
/// app filing a record the shepherd did not file.
///
/// Groups come back **newest first**, matching the timeline's own order, and the
/// rows inside each keep the order the statement produced them in — no second
/// sort, and no assumption that one is needed.
List<({int? year, List<TimelineRow> rows})> groupBySeason(List<TimelineRow> rows) {
  final List<({int? year, List<TimelineRow> rows})> groups =
      <({int? year, List<TimelineRow> rows})>[];
  for (final TimelineRow r in rows) {
    if (groups.isNotEmpty && groups.last.year == r.seasonYear) {
      groups.last.rows.add(r);
      continue;
    }
    groups.add((year: r.seasonYear, rows: <TimelineRow>[r]));
  }
  return groups;
}

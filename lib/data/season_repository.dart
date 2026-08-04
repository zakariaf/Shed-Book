// lib/data/season_repository.dart — the season, and a ewe's participation in it.
//
// **CREATED HERE RATHER THAN AT N28, AND THE REASON IS A SCOPE HOLE THIS TASK
// FOUND.** `CONVENTIONS §2.13` gives this repository `ewe_seasons`, and R42 puts
// *barren* there — `ewe_seasons.status = 'barren'`, never a `ewes.status` value
// and never an observation. The Flock screen has shipped a **barren filter**
// since N26-T02, and until something can write the row that filter is
// permanently empty: a control that can never match anything, on the one screen
// a shepherd uses to find animals.
//
// N28 (Season Summary) is `v1.1.0` and owns this repository's **reads** — the
// summary statistics, R18's *"there is no SeasonStatsRepository"*. Creating the
// file now with one write verb pre-empts none of that: R19 fixes the repository
// set at twelve and closed, and this is one of the twelve, so the file was
// always going to exist under exactly this name.
library;

import 'package:drift/drift.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/failure.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/failure_mapping.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';

final class SeasonRepository {
  /// `db:` is the name `CONVENTIONS §2.13` prints, and the initializing-formal
  /// lint is suppressed rather than obeyed: `this._db` would make the PUBLIC
  /// parameter name `_db`, so every caller would be writing a private name.
  // ignore_for_file: prefer_initializing_formals
  SeasonRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  /// A ewe's outcome for the **current** season.
  ///
  /// **BARREN IS A SEASON PARTICIPATION OUTCOME, NOT A STATUS AND NOT AN
  /// OBSERVATION** (R42). `ewes.status` has four values and `barren` is not one
  /// of them; the `ewe_observation` vocabulary has no barren key and must not
  /// gain one. Three different columns, three different facts — an animal can be
  /// active, barren this season, and have prolapsed last season, all at once.
  ///
  /// **UPSERT ON `(season, ewe)`, WHICH THE SCHEMA'S UNIQUE KEY MAKES POSSIBLE.**
  /// A ewe scanned in-lamb and later found barren has one participation row per
  /// season that changes its answer, not two rows disagreeing — and the shepherd
  /// correcting themselves is an ordinary act, not a duplicate.
  ///
  /// **THE APP NEVER INFERS IT.** *"No lambing recorded"* is not barren; it is
  /// *not recorded*, and the flock filters keep those two apart deliberately
  /// (N26-T02). Only this verb, called from a tap, writes the row.
  Future<WriteOutcome> setEweSeasonStatus(EweId ewe, String status) async {
    try {
      final Instant now = appNow(); // ONE instant per mutation
      return await _db.transaction(() async {
        final AppSetting settings = await _db.select(_db.appSettings).getSingle();
        final int? season = settings.currentSeason;
        if (season == null) {
          // **NOT A SILENT NO-OP.** A season is the shepherd's first act; with
          // none there is nothing to be barren *in*, and writing nothing while
          // reporting success would leave a tap that looks like it worked.
          return WriteFailed(const NoCurrentSeason());
        }

        // **THE CONFLICT TARGET IS `(season, ewe)`, NOT THE PRIMARY KEY, AND
        // THE DIFFERENCE IS THE WHOLE VERB.** `insertOnConflictUpdate` defaults
        // to the primary key — `id`, which a fresh insert never collides on — so
        // the second call violated the `(season, ewe)` unique key instead of
        // updating the row. Found by the correction case: the first barren wrote
        // fine and *"scanned in-lamb, later found barren"* failed.
        //
        // `createdAt` and `uid` are deliberately absent from the update set: the
        // row's identity and the moment it was first written do not change
        // because the shepherd corrected its answer.
        await _db
            .into(_db.eweSeasons)
            .insert(
              EweSeasonsCompanion.insert(
                season: season,
                ewe: ewe.value,
                status: status,
                uid: newUid(),
                createdAt: now,
                updatedAt: now,
              ),
              onConflict: DoUpdate<$EweSeasonsTable, EweSeason>(
                ($EweSeasonsTable _) => EweSeasonsCompanion(
                  status: Value<String>(status),
                  updatedAt: Value<Instant>(now),
                ),
                target: <Column<Object>>[_db.eweSeasons.season, _db.eweSeasons.ewe],
              ),
            );
        return const WriteCommitted();
      });
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }
}

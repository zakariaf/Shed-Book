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
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/data/entitlement_repository.dart';
import 'package:shed_book/data/failure_mapping.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';

final class SeasonRepository {
  /// `db:` is the name `CONVENTIONS §2.13` prints, and the initializing-formal
  /// lint is suppressed rather than obeyed: `this._db` would make the PUBLIC
  /// parameter name `_db`, so every caller would be writing a private name.
  // ignore_for_file: prefer_initializing_formals
  SeasonRepository({required AppDatabase db, EntitlementRepository? entitlements})
    : _db = db,
      _entitlements = entitlements;

  final AppDatabase _db;

  /// The entitlement, read through its owner. See `FlockRepository`'s field of
  /// the same name for why it is optional and why the fallback cannot disagree.
  final EntitlementRepository? _entitlements;

  /// **THE SECOND AND LAST GATED WRITE** (`11 §7.2`, `11 §7.3`). `createEwe` is
  /// the other; `beginLambing` and `addLamb` are never gated, at any entitlement
  /// state, at any hour.
  ///
  /// **THE DECISION AND THE INSERT ARE IN ONE TRANSACTION**, so the season count
  /// cannot move between them — reading a count outside and inserting inside is
  /// a race with the restore path and with a second start.
  ///
  /// **THE NEW SEASON BECOMES CURRENT IN THE SAME TRANSACTION.** A season
  /// created but not current is a season every write verb ignores — the shepherd
  /// would tap *"start season"*, see it appear, and record the night's lambings
  /// against last year.
  ///
  /// The cap is **not** a schema `CHECK`: one would fire on a paying user
  /// mid-lambing and there would be no way to tell it apart from corruption. It
  /// is not a UI check either — a UI check is one refactor away from being
  /// bypassed and cannot be tested without pumping a widget.
  Future<WriteOutcome> startSeason({
    required String label,
    required LocalDate startDate,
    required EntryContext context,
    required FreeTierPolicy policy,
  }) async {
    try {
      final Instant now = appNow(); // ONE instant per mutation
      return await _db.transaction(() async {
        final int seasons = (await _db.select(_db.seasons).get()).length;
        final CapDecision decision = policy.decide(
          context: context,
          now: now,
          unlocked: await _readUnlocked(),
          // **POST-WRITE COUNTS, WHICH IS THE CONTRACT** (`11 §7.2`). Backwards,
          // you either refuse the second season or let the third through — and
          // the free tier's boundary is the one number a paying user notices.
          ewesInCurrentSeason: 0,
          seasonCount: seasons + 1,
        );

        // NO `default:`. `CapDecision` is sealed with two variants, and the day
        // a third appears every switch must fail to compile rather than swallow
        // it.
        switch (decision) {
          case BlockedByCap(:final RefusalReason reason):
            return WriteRefused(reason);
          case Allow():
            final int id = await _db
                .into(_db.seasons)
                .insert(
                  SeasonsCompanion.insert(
                    year: startDate.year,
                    label: label,
                    startDate: startDate,
                    uid: newUid(),
                    createdAt: now,
                    updatedAt: now,
                  ),
                );
            await (_db.update(_db.appSettings)..where(($AppSettingsTable t) => t.id.equals(1)))
                .write(AppSettingsCompanion(currentSeason: Value<int?>(id)));
            return WriteCommitted(insertedId: id);
        }
      });
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  Future<bool> _readUnlocked() async => _entitlements != null
      ? (await _entitlements.read()).unlocked
      : (await _db.select(_db.entitlements).getSingle()).unlocked;

  /// Which season the app is writing into.
  ///
  /// **`app_settings.current_season` HAS TWO PLAUSIBLE OWNERS AND THIS COMMIT
  /// PICKS ONE.** `03 §5.14` assigns the column to `SeasonRepository`;
  /// `SettingsRepository.setCurrentSeason` shipped at N12-T02 because the row is
  /// `app_settings`. Both readings are defensible and two writers are not.
  ///
  /// **Ruled here: `SeasonRepository` owns the SWITCH, and `SettingsRepository`'s
  /// verb stays as the low-level column write it always was.** The reason is that
  /// switching seasons is a season-shaped act with season-shaped rules — the
  /// target has to exist — and `SettingsRepository` cannot check that without
  /// reaching into a table `§2.13` does not give it. Nothing calls the settings
  /// verb from a screen any more.
  ///
  /// **NOTHING IS INVALIDATED.** Every screen reads its season through
  /// `settingsProvider`, which is a stream over `app_settings` — so writing this
  /// column re-runs every dependent statement on its own. A `ref.invalidate`
  /// here would be the easy way, and it is the one that leaves a screen showing
  /// last season's numbers whenever the invalidation list falls behind.
  Future<WriteOutcome> switchSeason(SeasonId season) async {
    try {
      return await _db.transaction(() async {
        final Season? target = await (_db.select(
          _db.seasons,
        )..where(($SeasonsTable t) => t.id.equals(season.value))).getSingleOrNull();
        if (target == null) {
          // Not a silent no-op: an id that matches nothing means the caller is
          // holding a season that is not there, and reporting success would
          // leave the shepherd writing into the one they thought they left.
          return WriteFailed(const SeasonNotFound());
        }
        await (_db.update(_db.appSettings)..where(($AppSettingsTable t) => t.id.equals(1))).write(
          AppSettingsCompanion(currentSeason: Value<int?>(season.value)),
        );
        return const WriteCommitted();
      });
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

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

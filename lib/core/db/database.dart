import 'package:drift/drift.dart';
import 'package:shed_book/core/db/converters.dart';
import 'package:shed_book/core/db/migrations.dart';
import 'package:shed_book/core/db/seed/first_run.dart';
import 'package:shed_book/core/db/tables/ancillary.dart';
import 'package:shed_book/core/db/tables/flock.dart';
import 'package:shed_book/core/db/tables/lambing.dart';
import 'package:shed_book/core/db/tables/pens.dart';
import 'package:shed_book/core/db/tables/treatments.dart';
import 'package:shed_book/core/db/tables/seasons.dart';
// The generated part file references these by bare name, so the library that
// owns the part has to import them. Adding one here is what a new converter on
// a new column costs.
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/partial_date.dart';

part 'database.g.dart';

/// **Bumped by exactly one per schema change** (04 §2.4).
///
/// A top-level `const` that captures nothing, because it is read on the
/// background isolate too.
const int kSchemaVersion = 1;

/// **The table list grows one cluster per task**, and N07-T06 completes it.
///
/// Pasting 03 §1.4's complete 23-table list here would name twenty-two classes
/// that do not exist yet, `build_runner` would fail, and it would stay failing
/// until T06 — which is precisely the defect the fourteen-into-eight re-cut
/// existed to remove.
@DriftDatabase(
  include: <String>{'views.drift', 'search.drift', 'queries.drift'},
  tables: <Type>[
    // N07-T03 — the flock cluster.
    Seasons,
    Ewes,
    EweSeasons,
    EweTouches,
    EweObservations,
    // N07-T04 — the lambing cluster.
    Lambings,
    Lambs,
    // N07-T05 — the pen and treatment clusters.
    Treatments,
    TreatmentWithdrawals,
    Pens,
    PenOccupancies,
    PenOccupancyLambs,
    // N07-T06 — the ancillary cluster.
    CareEvents,
    FosterEvents,
    Reminders,
    ReminderRules,
    Notes,
    MediaAssets,
    VocabTerms,
    TerminologyOverrides,
    AppSettings,
    Entitlements,
    EweSummaries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e, {this.seedOnCreate = true, this.schemaVersionOverride = kSchemaVersion});

  /// False on exactly two paths — restore, and `tool/seed.dart`.
  final bool seedOnCreate;

  /// R14. **Production never passes it**: it exists so a migration test can open
  /// the database at an older version without a second class.
  ///
  /// The task file spells this `@visibleForTesting`. The annotation lives in
  /// `package:meta`, which is a TRANSITIVE dependency here, not a direct one —
  /// importing it trips `depend_on_referenced_packages` under --fatal-infos, and
  /// promoting it to a direct dependency is a decision-record §5 change rather
  /// than something to slip into a schema commit. The constraint is held by this
  /// comment, by R14, and by the fact that `openAppDatabase()` does not pass it.
  /// Raised in the pull request.
  final int schemaVersionOverride;

  /// **THE RESTORE'S TWO PRAGMAS, AND THEY LIVE HERE FOR A REASON.**
  ///
  /// `customStatement(` is banned outside `lib/core/db/` (layer rule 8) because a
  /// raw statement bypasses drift's stream tracking. N23-T01 asked for these as
  /// named `.drift` queries instead — and **drift cannot express a `PRAGMA` as
  /// one**: the generator parses SQL it can type, and a pragma is neither a
  /// SELECT nor an INSERT. Measured, not assumed.
  ///
  /// So they are methods on the database class, which is inside the directory
  /// the rule permits. `lib/data/` calls them and says no raw SQL of its own.
  ///
  /// **`defer_foreign_keys`, NOT `foreign_keys = OFF`.** The second is a
  /// **no-op inside a transaction** and drift wraps the import in one, so the
  /// code that reaches for it compiles, runs, and enforces nothing (`04 §2.6`).
  Future<void> deferForeignKeys() => customStatement('PRAGMA defer_foreign_keys = ON');

  /// Asked **before** the commit, so a failure names the table rather than
  /// arriving as a commit error nobody can attribute.
  Future<List<QueryRow>> foreignKeyCheck() => customSelect('PRAGMA foreign_key_check').get();

  /// `PRAGMA wal_checkpoint(TRUNCATE)` — step 8.
  ///
  /// **Not *close and hope*.** A staging file swapped in with its own `-wal`
  /// still beside it is `04 §8.1`'s corruption from the other direction, and it
  /// looks like a working database until it does not.
  Future<void> walCheckpointTruncate() => customStatement('PRAGMA wal_checkpoint(TRUNCATE)');

  /// One restored row, with its columns supplied at runtime.
  ///
  /// **IT LIVES HERE FOR THE SAME REASON THE PRAGMAS DO.** A 21-table import
  /// cannot name its columns statically, and `RawValuesInsertable<dynamic>` does
  /// not survive drift's typed `validateIntegrity` — measured: *"type
  /// `RawValuesInsertable<dynamic>` is not a subtype of `Insertable<Season>`"*.
  /// So the writer is raw, and raw belongs inside `lib/core/db/` (layer rule 8),
  /// where the ban does not reach and where every other raw statement in the app
  /// already lives.
  ///
  /// `lib/data/restore_service.dart` calls this and writes no SQL of its own,
  /// which is what the rule is protecting.
  Future<int> insertRestoredRow(String table, Map<String, Object?> columns) async {
    await customStatement(
      'INSERT INTO $table (${columns.keys.join(', ')}) '
      'VALUES (${List<String>.filled(columns.length, '?').join(', ')})',
      columns.values.toList(),
    );
    return (await customSelect('SELECT last_insert_rowid() AS id').getSingle()).read<int>('id');
  }

  /// `app_settings` is a singleton and is imported **onto** its existing row
  /// rather than inserted beside it — one of the five tables with no `uid`
  /// (`09 §5.3`).
  Future<void> updateRestoredSingleton(String table, Map<String, Object?> columns) =>
      customStatement(
        'UPDATE $table SET ${columns.keys.map((String c) => '$c = ?').join(', ')} WHERE id = 1',
        columns.values.toList(),
      );

  @override
  int get schemaVersion => schemaVersionOverride;

  /// The bodies live next door in `migrations.dart`, which is the one
  /// hand-edited file in this package (04 §2.5) and the one that carries the
  /// five rules where somebody will read them.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Decision #42: the seed is part of creating the database, not a step the
      // first screen performs. It is skipped on exactly two paths — a restore
      // and tool/seed.dart — both of which are about to write their own rows.
      if (seedOnCreate) {
        await seedFirstRun(this);
      }
    },
    onUpgrade: shedStepByStep(),
  );
}

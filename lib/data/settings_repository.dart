// lib/data/settings_repository.dart
//
// THE ONLY WRITER OF app_settings (CONVENTIONS §2.13).
//
// Pulled forward from N29 because N21's end-of-day export banner writes three of
// these columns, and CONVENTIONS §2.13 gives ExportRepository "nothing — read
// and artefact assembly only" (critique defect S6).
//
// It is also THE FIRST REPOSITORY IN THE PROJECT, so its shape is the shape the
// other eleven copy: a concrete `final class` taking `AppDatabase`, no
// interface, EVENT VERBS returning `WriteOutcome`, one transaction each, and no
// `Clock` parameter — a repository that knows the time is a repository that
// cannot be tested without controlling it.
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/failure_mapping.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/stats/definitions.dart';
import 'package:shed_book/domain/terminology/animal_class.dart';
import 'package:shed_book/domain/terminology/term_label.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/units/weight_unit.dart';

final class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  /// The one row. `03 §5.13`: `CHECK (id = 1)`, seeded by `seedFirstRun`.
  static const int rowId = 1;

  Stream<AppSetting> watch() => (_db.select(
    _db.appSettings,
  )..where(($AppSettingsTable t) => t.id.equals(rowId))).watchSingle();

  /// All forty vocabulary rows, in `sort_order`, as [VocabEntry] records.
  ///
  /// **NOT `Stream<List<VocabTerm>>`, AND THE GATE IS WHY.** N16-T04's file
  /// table prescribes `StreamProvider<List<VocabTerm>>`, but `VocabTerm` is a
  /// drift row class and `layer.features` forbids `lib/features/` from importing
  /// `lib/core/db/` at all — so a provider carrying that type is unbuildable at
  /// its only call site. Caught by the gate on the first run, and recorded here
  /// rather than worked around: the shape is the same one `LambingEntryData`
  /// already uses, where the data layer declares the type the feature reads.
  ///
  /// Two fields and not the whole row, because two is what the presentation edge
  /// can use: `key` is the frozen foreign key and `label` is the user's
  /// override, where **NULL means render the shipped default** (`03 §3`). The
  /// other five columns — id, uid, list, sort_order, origin, hidden_at — are
  /// either device-local or belong to the Settings screen that edits them.
  Stream<List<VocabEntry>> watchVocab() =>
      (_db.select(_db.vocabTerms)..orderBy(<OrderClauseGenerator<$VocabTermsTable>>[
            ($VocabTermsTable t) => OrderingTerm(expression: t.sortOrder),
          ]))
          .watch()
          .map(
            (List<VocabTerm> rows) => <VocabEntry>[
              for (final VocabTerm r in rows) (key: r.key, label: r.label),
            ],
          );

  Future<AppSetting> read() =>
      (_db.select(_db.appSettings)..where(($AppSettingsTable t) => t.id.equals(rowId))).getSingle();

  // -- display and units — N29's screen --------------------------------------

  /// **THE SEAM THE DIAGNOSTICS ROW READS THROUGH.** `lib/features/` may not
  /// import `lib/core/db/` (layer rule 5), so a widget cannot ask the database
  /// anything directly — and `PRAGMA quick_check` is a raw statement, which is
  /// confined to `lib/core/db/` besides (rule 8). Two rules, one seam.
  ///
  /// It returns a plain `bool` rather than a `WriteOutcome` because it is a
  /// read: nothing is written, nothing can be refused, and a failure to run it
  /// at all is a `false` the row renders as *the file reported a problem* —
  /// which is the honest reading of a check that could not complete.
  Future<bool> checkDatabase() => _db.quickCheck();

  /// The two numbers `13 §8.5` prints beside the integrity check.
  ///
  /// **RECORDS AND ANIMALS, NOT ROWS AND EWES.** A shepherd sending a
  /// diagnostics note needs a size, not a schema: *"1,240 records · 87 animals"*
  /// tells whoever reads it whether the file is a test flock or four seasons of
  /// work. `records` is every append-only fact — lambings, lambs, treatments,
  /// notes — and deliberately not a table count, which would mean nothing to
  /// either of them.
  ///
  /// Through the repository because two layer rules say so: `lib/features/` may
  /// not import `lib/core/db/`, and the raw statement is confined to
  /// `lib/core/db/` besides.
  Future<({int records, int animals})> diagnosticCounts() async {
    final int lambings = (await _db.select(_db.lambings).get()).length;
    final int lambs = (await _db.select(_db.lambs).get()).length;
    final int treatments = (await _db.select(_db.treatments).get()).length;
    final int notes = (await _db.select(_db.notes).get()).length;
    final int ewes = (await _db.select(_db.ewes).get()).length;
    return (records: lambings + lambs + treatments + notes, animals: ewes + lambs);
  }

  /// A copy of the records file, written where it can be shared from.
  ///
  /// **`VACUUM INTO`, WHICH IS THE ONE WAY THIS PROJECT COPIES A DATABASE**
  /// (`09 §6.2`) — the same verb the restore path uses, so there is one answer
  /// to *how do you copy it* rather than two that drift.
  ///
  /// **THE WORD IS `snapshot` AND IT IS NEVER `backup`** (`CLAUDE.md`): a backup
  /// is the JSON a shepherd restores from, and a snapshot is a `.sqlite` file
  /// for somebody debugging. Swapping them is how a shepherd sends the wrong one
  /// and cannot restore it.
  Future<File> writeSnapshot(Directory into) async {
    final File out = File('${into.path}/shed-book-diagnostics.sqlite');
    if (out.existsSync()) {
      out.deleteSync();
    }
    await _db.snapshotInto(out.path);
    return out;
  }

  Future<WriteOutcome> setWeightUnit(WeightUnit unit) =>
      _write(AppSettingsCompanion(weightUnit: Value<String>(unit.key)));

  Future<WriteOutcome> setPalette(String paletteKey) =>
      _write(AppSettingsCompanion(palette: Value<String>(paletteKey)));

  Future<WriteOutcome> setHighContrast({required bool on}) =>
      _write(AppSettingsCompanion(highContrast: Value<bool>(on)));

  Future<WriteOutcome> setLeftHanded({required bool on}) =>
      _write(AppSettingsCompanion(leftHanded: Value<bool>(on)));

  Future<WriteOutcome> setWakelockEnabled({required bool on}) =>
      _write(AppSettingsCompanion(wakelockEnabled: Value<bool>(on)));

  // NO setTemperatureUnit, AND ITS ABSENCE IS DELIBERATE. N12-T02 §5.2 prints
  // one, but there is no `temperature_unit` column: R68 rules that no
  // temperature unit ships while decision-record §7.1 #11 is open, and 03 §5.13
  // has no such column to write. A setter for a column that does not exist is a
  // compile error at best and a silent no-op at worst. "An unused setting is a
  // 3am tax."

  // -- display arithmetic the user controls, never advice (03 §5.13) ---------

  Future<WriteOutcome> setTurnOutThresholdHours(int hours) =>
      _write(AppSettingsCompanion(turnOutThresholdHours: Value<int>(hours)));

  /// Read by Season Summary's `lambingSpread` (N28, `v1.1.0`) and by nothing in
  /// `v1.0.0`.
  ///
  /// **THEY WERE DELETED ON 2026-08-05 AND RESTORED THE SAME DAY**, and the
  /// round trip is worth the four lines it costs. The reasoning that removed
  /// them was the project's own — *the epic that writes the class adds it in the
  /// same commit* — and it was wrong here for a reason the deletion surfaced:
  /// their callers are the cases in `settings_repository_test.dart` that assert
  /// these columns **round-trip**, which is exactly what has to be true for a
  /// `v1.0.0` backup to restore into `v1.1.0` unchanged (P15, all 21 tables
  /// whole).
  ///
  /// A verb whose only caller is the test that states a rule is not dead code.
  Future<WriteOutcome> setCycleDays(int days) =>
      _write(AppSettingsCompanion(cycleDays: Value<int>(days)));

  Future<WriteOutcome> setPercentageDefinition(LambingPercentageChoice choice) =>
      _write(AppSettingsCompanion(percentageDefinition: Value<String>(choice.key)));

  // -- season pointer — N28 reads it, N23's restore rewrites it --------------

  // **`setCurrentSeason` WAS DELETED HERE ON 2026-08-05, AND ITS ABSENCE IS
  // THE RULE.** `03 §5.14` assigns `app_settings.current_season` to
  // `SeasonRepository`, which owns it through `switchSeason` — a verb that also
  // checks the season exists before pointing at it. This one wrote the column
  // raw, from a second class, and had no caller: a second writer for one column
  // is `layer.single_writer` waiting to happen, and keeping it "for later" is
  // how the second one eventually gets used.

  // -- the export banner's three columns — N21 (critique defect S6) ----------

  /// **Stamped on `ShareOutcome.completed` AND on `unknown`, never on
  /// `dismissed`, and never before the share sheet opens** (`09 §8.3`, `08 §11`).
  ///
  /// Stamping early tells a shepherd their season left the phone when it did
  /// not — and the banner they then stop seeing is the only thing that would
  /// have told them otherwise.
  Future<WriteOutcome> recordExported(Instant at) =>
      _write(AppSettingsCompanion(lastExportedAt: Value<Instant>(at)));

  Future<WriteOutcome> recordExportPrompted(Instant at) =>
      _write(AppSettingsCompanion(lastExportPromptedAt: Value<Instant>(at)));

  Future<WriteOutcome> dismissExportPromptForSeason(SeasonId season) =>
      _write(AppSettingsCompanion(exportPromptDismissedForSeason: Value<int?>(season.value)));

  /// Written by `ReminderReconciler.reconcile()` in the same transaction that
  /// records the projection (R40) — N24.
  ///
  /// **DELETED ON 2026-08-05 AND RESTORED THE SAME DAY**, on the same reasoning
  /// as the two setters above: its caller is the case asserting that
  /// `last_reconcile_scheduled` round-trips, and that column is in the backup —
  /// which is exactly what has to hold for a `v1.0.0` backup to restore into
  /// `v1.1.0` unchanged (P15, all 21 tables whole).
  Future<WriteOutcome> recordReconcileScheduled(Instant at) =>
      _write(AppSettingsCompanion(lastReconcileScheduled: Value<Instant>(at)));

  /// One transaction, one `shedFailureFrom`.
  ///
  /// **It returns `WriteFailed` rather than throwing** (`01 §5.2`): a caller
  /// inside a controller has to decide what the shepherd sees, and an exception
  /// crossing a repository boundary is a decision made somewhere that cannot
  /// make it.
  Future<WriteOutcome> _write(AppSettingsCompanion patch) async {
    try {
      final int rows = await _db.transaction(
        () => (_db.update(
          _db.appSettings,
        )..where(($AppSettingsTable t) => t.id.equals(rowId))).write(patch),
      );
      return WriteCommitted(insertedId: rows > 0 ? rowId : null);
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  // -- vocabulary and terminology — N29 EDITS them; N12 only READS -----------

  Stream<List<VocabTerm>> watchVocabulary(String list) =>
      (_db.select(_db.vocabTerms)..where(($VocabTermsTable t) => t.list.equals(list))).watch();

  /// The overrides a shepherd has typed. **Empty is the normal case** — the
  /// default labels come from `lib/domain/terminology/`, and an override is only
  /// ever an addition to them.
  Stream<Map<AnimalClass, TermLabel>> watchTerminologyOverrides() => _db
      .select(_db.terminologyOverrides)
      .watch()
      .map(
        (List<TerminologyOverride> rows) => <AnimalClass, TermLabel>{
          for (final TerminologyOverride r in rows)
            // A row whose key names no AnimalClass is SKIPPED rather than
            // thrown on. The table is an overlay a restore can carry forward
            // from an older schema, and a settings read that throws is a
            // settings read that stops the app opening.
            if (AnimalClass.values.any((AnimalClass c) => c.name == r.key))
              AnimalClass.values.firstWhere((AnimalClass c) => c.name == r.key): TermLabel(
                r.singular,
                r.plural,
              ),
        },
      );
}

/// One vocabulary row, as far as a screen is concerned.
///
/// `label` is the shepherd's override and **`null` means *render the shipped
/// default*** — which is not the same as an empty label. A user who renames ease
/// 3 writes `vocab_terms.label`; no locale change and no app update touches it.
typedef VocabEntry = ({String key, String? label});

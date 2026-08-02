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

  Future<WriteOutcome> setCycleDays(int days) =>
      _write(AppSettingsCompanion(cycleDays: Value<int>(days)));

  Future<WriteOutcome> setPercentageDefinition(LambingPercentageChoice choice) =>
      _write(AppSettingsCompanion(percentageDefinition: Value<String>(choice.key)));

  // -- season pointer — N28 reads it, N23's restore rewrites it --------------

  Future<WriteOutcome> setCurrentSeason(SeasonId? season) =>
      _write(AppSettingsCompanion(currentSeason: Value<int?>(season?.value)));

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

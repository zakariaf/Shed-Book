import 'package:drift/drift.dart';
import 'package:shed_book/core/db/converters.dart';
import 'package:shed_book/core/db/tables/common.dart';
import 'package:shed_book/core/db/tables/flock.dart';
import 'package:shed_book/core/db/tables/lambing.dart';
import 'package:shed_book/core/db/tables/seasons.dart';
import 'package:shed_book/core/db/tables/treatments.dart';

/// Checkbox state on the Lambing Entry screen is `EXISTS(…)`, **never a boolean
/// column** — that keeps *"colostrum given at 03:22"* recoverable, and it gives
/// the colostrum reminder something to be completed *from*.
@TableIndex(name: 'idx_care_lambing_kind', columns: <Symbol>{#lambing, #kind})
@TableIndex(name: 'idx_care_lamb_kind', columns: <Symbol>{#lamb, #kind})
@TableIndex(name: 'idx_care_season', columns: <Symbol>{#season})
class CareEvents extends Table with Identified, Struckable {
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();
  late final lambing = integer().nullable().references(
    Lambings,
    #id,
    onDelete: KeyAction.cascade,
  )();
  late final lamb = integer().nullable().references(Lambs, #id, onDelete: KeyAction.cascade)();

  late final kind = text()();

  // A care event is exactly as deferrable as a lambing, so it carries the same
  // §12.5 provenance quad.
  late final occurredAt = integer().map(const InstantConverter())();
  late final capturedAt = integer().map(const InstantConverter())();
  late final originalEffective = integer().map(const InstantConverter()).nullable()();
  late final timeSource = text().withDefault(const Constant('auto'))();

  late final volumeMl = integer().nullable()();
  late final method = text().nullable()();
  late final note = text().nullable()();

  @override
  List<String> get customConstraints => <String>[
    'CHECK ((lambing IS NOT NULL) + (lamb IS NOT NULL) = 1)',
    "CHECK (kind IN ('colostrum','navel_dip','stomach_tube','warmed'))",
    "CHECK (method IS NULL OR method IN ('teat','tube','bottle'))",
    // An ml-versus-litres UNIT-SLIP guard. Not a dose recommendation (§12.2).
    'CHECK (volume_ml IS NULL OR volume_ml BETWEEN 1 AND 2000)',
    'CHECK (occurred_at BETWEEN 946684800000 AND 4102444800000)',
    'CHECK (captured_at BETWEEN 946684800000 AND 4102444800000)',
    "CHECK (time_source IN ('auto','entered','edited'))",
    "CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))",
    'CHECK (struck IN (0,1))',
    'CHECK ((struck = 1) = (struck_at IS NOT NULL))',
    'CHECK (unknown_json IS NULL OR json_valid(unknown_json))',
  ];

  @override
  bool get isStrict => true;
}

@TableIndex(name: 'idx_foster_lamb_time', columns: <Symbol>{#lamb, #effectiveAt})
@TableIndex(name: 'idx_foster_rearingdam', columns: <Symbol>{#rearingDam})
@TableIndex(name: 'idx_foster_season', columns: <Symbol>{#season})
@TableIndex(name: 'idx_foster_corrects', columns: <Symbol>{#corrects})
@TableIndex(name: 'idx_foster_method', columns: <Symbol>{#method})
class FosterEvents extends Table with Identified, Struckable {
  late final lamb = integer().references(Lambs, #id, onDelete: KeyAction.cascade)();
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();

  /// NULL when the lamb leaves a rearing dam without gaining a new one.
  late final rearingDam = integer().nullable().references(
    Ewes,
    #id,
    onDelete: KeyAction.restrict,
  )();

  /// `'to_ewe'` | `'to_bottle'` | `'removed_unknown'`.
  ///
  /// Bottle (null by intent) and unknown (null by omission) are **different
  /// facts** and the rearing-credit numbers differ. Do not merge them — which is
  /// also why `setRearingDam(lambId, eweId?)` is a banned signature.
  late final outcome = text()();

  /// Decision #69: undo for a foster is a **compensating event** pointing at the
  /// one it reverses, visible in history. The log is append-only; nothing is
  /// ever deleted from it.
  late final corrects = integer().nullable().references(
    FosterEvents,
    #id,
    onDelete: KeyAction.restrict,
  )();

  /// The third documented exception to the `occurred_at` column-name rule
  /// (R37): a graft is dated by when it took effect.
  late final effectiveAt = integer().map(const InstantConverter())();

  late final capturedAt = integer().map(const InstantConverter())();
  late final originalEffective = integer().map(const InstantConverter()).nullable()();
  late final timeSource = text().withDefault(const Constant('auto'))();

  /// **Forward reference, deferred to the VocabTerms declaration below** — it is
  /// in this same file, so it lands with it.
  late final method = text().nullable().references(
    VocabTerms,
    #key,
    onDelete: KeyAction.restrict,
  )();

  late final note = text().nullable()();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (outcome IN ('to_ewe','to_bottle','removed_unknown'))",
    "CHECK ((outcome = 'to_ewe') = (rearing_dam IS NOT NULL))",
    'CHECK (effective_at BETWEEN 946684800000 AND 4102444800000)',
    'CHECK (captured_at BETWEEN 946684800000 AND 4102444800000)',
    "CHECK (time_source IN ('auto','entered','edited'))",
    "CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))",
    'CHECK (struck IN (0,1))',
    'CHECK ((struck = 1) = (struck_at IS NOT NULL))',
    'CHECK (unknown_json IS NULL OR json_valid(unknown_json))',
  ];

  @override
  bool get isStrict => true;
}

/// **There is no `os_notification_id` column, and adding one is a defect.**
///
/// Under decision #63 the OS projection is a rebuildable cache produced by
/// `cancelAll()` + rebuild, not a durable fact — a stored OS id would be a
/// second source of truth that goes stale on every reconcile. The id handed to
/// `flutter_local_notifications` is derived from `reminders.id` at projection
/// time.
///
/// [kind] is a closed `CHECK` because each value maps to an Android channel id
/// frozen at release.
@TableIndex(name: 'idx_reminder_due_open', columns: <Symbol>{#dueAt, #completedAt})
@TableIndex(name: 'idx_reminder_season', columns: <Symbol>{#season})
@TableIndex(name: 'idx_reminder_ewe', columns: <Symbol>{#ewe})
@TableIndex(name: 'idx_reminder_lamb', columns: <Symbol>{#lamb})
@TableIndex(name: 'idx_reminder_lambing', columns: <Symbol>{#lambing})
@TableIndex(name: 'idx_reminder_treatment', columns: <Symbol>{#treatment})
class Reminders extends Table with Identified, Struckable {
  late final season = integer().nullable().references(Seasons, #id, onDelete: KeyAction.cascade)();
  late final ewe = integer().nullable().references(Ewes, #id, onDelete: KeyAction.cascade)();
  late final lamb = integer().nullable().references(Lambs, #id, onDelete: KeyAction.cascade)();
  late final lambing = integer().nullable().references(
    Lambings,
    #id,
    onDelete: KeyAction.cascade,
  )();
  late final treatment = integer().nullable().references(
    Treatments,
    #id,
    onDelete: KeyAction.cascade,
  )();

  late final kind = text()();
  late final title = text()();
  late final dueAt = integer().map(const InstantConverter())();
  late final completedAt = integer().map(const InstantConverter()).nullable()();
  late final muted = boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (kind IN ('colostrum','navel','turn_out','tag_by',"
        "'ring_dock_castrate','second_dose','withdrawal_end','custom'))",
    'CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) + (lambing IS NOT NULL)'
        ' + (treatment IS NOT NULL) <= 1)',
    'CHECK (due_at BETWEEN 946684800000 AND 4102444800000)',
    'CHECK (struck IN (0,1))',
    'CHECK ((struck = 1) = (struck_at IS NOT NULL))',
    'CHECK (unknown_json IS NULL OR json_valid(unknown_json))',
  ];

  @override
  bool get isStrict => true;
}

class ReminderRules extends Table {
  late final kind = text()();
  late final enabled = boolean().withDefault(const Constant(true))();
  late final offsetMinutes = integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{kind};

  @override
  bool get isStrict => true;
}

@TableIndex(name: 'idx_note_ewe', columns: <Symbol>{#ewe})
@TableIndex(name: 'idx_note_lamb', columns: <Symbol>{#lamb})
@TableIndex(name: 'idx_note_lambing', columns: <Symbol>{#lambing})
@TableIndex(name: 'idx_note_season', columns: <Symbol>{#season})
class Notes extends Table with Identified, Struckable {
  late final ewe = integer().nullable().references(Ewes, #id, onDelete: KeyAction.cascade)();
  late final lamb = integer().nullable().references(Lambs, #id, onDelete: KeyAction.cascade)();
  late final lambing = integer().nullable().references(
    Lambings,
    #id,
    onDelete: KeyAction.cascade,
  )();
  late final season = integer().nullable().references(Seasons, #id, onDelete: KeyAction.cascade)();

  late final body = text()();

  /// **`occurred_at` is WHEN THE THING HAPPENED** and is distinct from the
  /// mixin's `created_at`, which is when the row was written: a note typed at
  /// 06:00 about 03:20 has two different instants, and the timeline sorts on the
  /// first.
  late final occurredAt = integer().map(const InstantConverter())();
  late final capturedAt = integer().map(const InstantConverter())();
  late final originalEffective = integer().map(const InstantConverter()).nullable()();
  late final timeSource = text().withDefault(const Constant('auto'))();

  @override
  List<String> get customConstraints => <String>[
    'CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) + (lambing IS NOT NULL)'
        ' + (season IS NOT NULL) >= 1)',
    'CHECK (length(trim(body)) > 0)',
    'CHECK (occurred_at BETWEEN 946684800000 AND 4102444800000)',
    'CHECK (captured_at BETWEEN 946684800000 AND 4102444800000)',
    "CHECK (time_source IN ('auto','entered','edited'))",
    "CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))",
    'CHECK (struck IN (0,1))',
    'CHECK ((struck = 1) = (struck_at IS NOT NULL))',
    'CHECK (unknown_json IS NULL OR json_valid(unknown_json))',
  ];

  @override
  bool get isStrict => true;
}

/// **No `Struckable`** (R79): removal is 04 §4.8's `.trash/` path.
@TableIndex(name: 'idx_media_ewe', columns: <Symbol>{#ewe})
@TableIndex(name: 'idx_media_lamb', columns: <Symbol>{#lamb})
@TableIndex(name: 'idx_media_lambing', columns: <Symbol>{#lambing})
@TableIndex(name: 'idx_media_note', columns: <Symbol>{#note})
class MediaAssets extends Table with Identified {
  /// **RELATIVE to the media root**, e.g. `"2026/03/019524f7-….jpg"`.
  ///
  /// The iOS container UUID is not stable across launches, so an absolute path
  /// 404s after every restore, update and re-install — and never reproduces on
  /// the developer's Android phone.
  late final relativePath = text()();

  late final kind = text()();
  late final byteSize = integer()();
  late final durationMs = integer().nullable()();
  late final sha256 = text().nullable()();

  late final ewe = integer().nullable().references(Ewes, #id, onDelete: KeyAction.cascade)();
  late final lamb = integer().nullable().references(Lambs, #id, onDelete: KeyAction.cascade)();
  late final lambing = integer().nullable().references(
    Lambings,
    #id,
    onDelete: KeyAction.cascade,
  )();
  late final note = integer().nullable().references(Notes, #id, onDelete: KeyAction.cascade)();

  /// Set when a sweep finds the file gone. **The row is NEVER deleted**:
  /// *"photo taken 14 March, file missing"* is more honest than silence.
  late final missingSince = integer().map(const InstantConverter()).nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{relativePath},
  ];

  @override
  List<String> get customConstraints => <String>[
    "CHECK (kind IN ('photo','voice'))",
    'CHECK (byte_size >= 0)',
    // All three, and they MUST be here before the v1 snapshot (R62): a CHECK
    // cannot be added by ALTER TABLE afterwards without a full rebuild of the
    // one table that points at the user's photographs.
    // Never absolute; always YYYY/MM/<file>; never deeper than that.
    "CHECK (relative_path NOT LIKE '/%')",
    "CHECK (relative_path GLOB '[0-9][0-9][0-9][0-9]/[0-9][0-9]/*.*')",
    "CHECK (relative_path NOT GLOB '*/*/*/*')",
    'CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) + (lambing IS NOT NULL)'
        ' + (note IS NOT NULL) = 1)',
    'CHECK (unknown_json IS NULL OR json_valid(unknown_json))',
  ];

  @override
  bool get isStrict => true;
}

/// **No `Struckable`** (R79): labels are edited, not struck.
@TableIndex(name: 'idx_vocab_list', columns: <Symbol>{#list, #sortOrder})
class VocabTerms extends Table with Identified {
  late final list = text()();

  /// Globally unique, list-prefixed, ASCII, **stable forever**. This is what
  /// goes in the database, the CSV and the JSON. It is never translated and
  /// never edited. Foreign keys point at it, which is why it is `UNIQUE` on its
  /// own.
  late final key = text().unique()();

  /// The user's override. **NULL means "use the shipped en-GB default for this
  /// key"**, so a locale change or an app update cannot overwrite a user's
  /// wording, and the data layer never touches `AppLocalizations`.
  late final label = text().nullable()();

  late final sortOrder = integer()();
  late final origin = text()();

  /// Hidden, **never deleted** — a term in use is referenced by a foreign key.
  late final hiddenAt = integer().map(const InstantConverter()).nullable()();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (list IN ('death_cause','malpresentation','treatment_route',"
        "'ewe_observation','lambing_ease','foster_method'))",
    "CHECK (origin IN ('seeded','user'))",
    // A user-added term has no shipped default, so it MUST carry a label.
    "CHECK (origin = 'seeded' OR label IS NOT NULL)",
    'CHECK (length(trim(key)) > 0)',
    'CHECK (unknown_json IS NULL OR json_valid(unknown_json))',
  ];

  @override
  bool get isStrict => true;
}

/// A closed `AnimalClass` enum lives in the domain; this table is the overlay.
class TerminologyOverrides extends Table {
  late final key = text()();
  late final singular = text()();
  late final plural = text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};

  @override
  bool get isStrict => true;
}

/// The only table exempt from the hand-indexed-FK rule: one row, so an index on
/// `current_season` costs more than the scan it replaces. It is exempt **by
/// name** in `test/data/every_fk_is_indexed_test.dart`.
///
/// There is deliberately **no locale, date-format or first-day-of-week column**.
/// §7.0 ruling 3 is delivered by `flutter_localizations` and the
/// `supportedLocales` ordering, not by a settings row — a stored copy would go
/// stale the moment the user changes their phone's region.
@DataClassName('AppSetting')
class AppSettings extends Table {
  late final id = integer().withDefault(const Constant(1))();

  /// Keys are `WeightUnit`'s, byte-identical (R68).
  late final weightUnit = text().withDefault(const Constant('kg'))();

  // No temperature_unit. Ruled 2026-08-01 (§7.0 row 11): no v1 table stores a
  // temperature, so the setting is a 3am tax on a screen that has to stay small.
  // MilliCelsius still ships; the column does not.

  /// Byte-identical to `ShedPaletteId`'s keys (R35): `night` · `amber` · `red`.
  /// **There is no `dark` key** — the palette that used to be called that is
  /// `night`, and the enum and the column must spell it the same way.
  late final palette = text().withDefault(const Constant('night'))();

  late final highContrast = boolean().withDefault(const Constant(false))();
  late final wakelockEnabled = boolean().withDefault(const Constant(false))();

  /// Mirrors the primary action column for a left-handed shepherd (R40). A
  /// layout preference, **never a capability switch**.
  late final leftHanded = boolean().withDefault(const Constant(false))();

  late final currentSeason = integer().nullable().references(
    Seasons,
    #id,
    onDelete: KeyAction.setNull,
  )();

  late final percentageDefinition = text().withDefault(
    const Constant('born_alive_per_ewe_to_ram'),
  )();

  /// A **display** threshold the user sets, never a recommendation. It decides
  /// when the pen tile shows its badge and nothing else — not in any export, and
  /// no other column is derived from it. A blank threshold would mean no badge
  /// ever.
  late final turnOutThresholdHours = integer().withDefault(const Constant(24))();

  /// Used only to zero-fill the lambing-spread histogram's first-cycle bucket.
  /// Display arithmetic, never advice.
  late final cycleDays = integer().withDefault(const Constant(17))();

  /// Nullable: *"never reconciled"* is a real state, and it is what the honest
  /// reminder line reads. **Not** a cache of the projection itself.
  late final lastReconcileScheduled = integer().map(const InstantConverter()).nullable()();

  // Decision #72: the end-of-day export banner.
  late final lastExportedAt = integer().map(const InstantConverter()).nullable()();
  late final lastExportPromptedAt = integer().map(const InstantConverter()).nullable()();
  late final exportPromptDismissedForSeason = integer().nullable().references(
    Seasons,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// An unknown *table* in a backup is preserved here under its table name
  /// (04 §6.4). Never dropped silently.
  late final unknownJson = text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<String> get customConstraints => <String>[
    'CHECK (id = 1)',
    "CHECK (weight_unit IN ('kg','lb'))",
    // No 'light'. Spec §5: dark is the default, not an option.
    "CHECK (palette IN ('night','amber','red'))",
    "CHECK (percentage_definition IN ("
        "'born_alive_per_ewe_to_ram','born_incl_stillborn_per_ewe_to_ram',"
        "'born_alive_per_ewe_lambed','reared_per_ewe_to_ram'))",
    'CHECK (turn_out_threshold_hours BETWEEN 1 AND 336)',
    'CHECK (cycle_days BETWEEN 1 AND 60)',
    'CHECK (unknown_json IS NULL OR json_valid(unknown_json))',
  ];

  @override
  bool get isStrict => true;
}

/// Decision #88. Written once, never revoked by the app. **EXCLUDED from the
/// JSON backup and IGNORED on import** — restoring your neighbour's backup must
/// not unlock your app. Never in `shared_preferences`.
class Entitlements extends Table {
  late final id = integer().withDefault(const Constant(1))();
  late final unlocked = boolean().withDefault(const Constant(false))();
  late final unlockedAt = integer().map(const InstantConverter()).nullable()();
  late final purchaseInFlightAt = integer().map(const InstantConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<String> get customConstraints => <String>['CHECK (id = 1)'];

  @override
  bool get isStrict => true;
}

/// The §7.7 one-line summary, precomputed so the first thing on the ewe card
/// never waits for an aggregate. **A cache**: rebuildable, excluded from the
/// backup, rebuilt wholesale after a restore.
///
/// It stores **counts only — never a percentage, never a formatted string**. The
/// sentence is assembled in Dart with the terminology overlay and the locale
/// applied, because a formatted string in the database would freeze both.
@DataClassName('EweSummary')
@TableIndex(name: 'idx_ewesummary_lastobs', columns: <Symbol>{#lastObservationSeason})
class EweSummaries extends Table {
  late final ewe = integer().references(Ewes, #id, onDelete: KeyAction.cascade)();
  late final seasonsRecorded = integer()();
  late final lambingsRecorded = integer()();
  late final lambsBorn = integer()();
  late final lambsBornAlive = integer()();

  /// Stored as a **pair** with [scoredLambings] so the assisted rate can exclude
  /// unscored lambings from *both* sides and report coverage (decision #59).
  late final assistedLambings = integer()();
  late final scoredLambings = integer()();

  /// A real foreign key, not a loose integer. *"prolapsed 2025"* is rendered
  /// from the season this points at; a dangling id would render a blank year on
  /// the one line the retention feature is built on. Cache or not, convention 2
  /// has no exceptions.
  late final lastObservationSeason = integer().nullable().references(
    Seasons,
    #id,
    onDelete: KeyAction.setNull,
  )();

  late final rebuiltAt = integer().map(const InstantConverter())();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{ewe};

  @override
  bool get isStrict => true;
}

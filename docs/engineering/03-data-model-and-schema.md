# 03 — Data model and schema

This document governs the SQLite file: how it is opened, every table in it, the constraints that encode the domain invariants, and the first-run seed. It is the freeze point for the schema — decisions #29 (time storage), #32 (ID strategy) and the tag-uniqueness ruling are irreversible once the first migration snapshot is committed, so read this before you write `dart run drift_dev make-migrations` for the first time. Migration mechanics, media files and restore live in [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md); the value types that sit on top of these columns live in [`05-domain-correctness.md`](05-domain-correctness.md).

> **Decisions applied:** #25 drift over SQLite via `package:sqlite3` build hooks · #26 no direct `sqlite3_flutter_libs` · #27 database in application support · #28 WAL + `synchronous = FULL` + `foreign_keys = ON` · #29/#30 instants as `INTEGER` epoch millis, civil dates as `TEXT 'YYYY-MM-DD'`, no drift `dateTime()` columns · #31 `STRICT` / real FKs / hand-indexed / history tables · #32 dual-key `id` + `uid` (UUID v7) · #33 immutable birth dam + append-only `FosterEvents` + rearing view · #34 pen occupancy as history with a partial unique index · #35/#36 FTS5 for notes, in-memory ranking for tags, FTS5 as a startup assertion · #39 debug schema self-check · #42 first-run seed in `onCreate` · #43 `CareEvents` · #44 `EweObservations` · #50/#51 stored `clear_date` and the `treatment_withdrawals` child table · #53 `RecordedTime` as columns · #56 canonical grams and milli-°C · #59 statistic inputs (`ewes_to_ram`, unscored ease) · #61 terminology overlay · #68 `ewe_touches` · #69 soft-void treatments · #88 entitlement row · #91 the free-tier `over_free_cap` columns · **§7.0 ruling 3: UK/Ireland first — `en_GB`, kg, °C, 24-hour, `dd/MM/yyyy`, week starts Monday, ambiguous DST hour 01:00–01:59, AHDB's lambs-born-**alive** percentage convention** · **§7.0 ruling 7: tags are unique among ACTIVE animals only** · **§7.0 ruling 8: the free tier is season-primary, the ewe cap secondary.** Rulings 5 and 6 (OCR and voice tag entry, both cut from v1) touch this document only in that `media_assets.kind` is `('photo','voice')` — the voice *note* ships, the voice *tag entry* does not, and there is no speech-derived column anywhere in the schema.

---

## 1. The drift setup

### 1.1 Packages and versions

Every version is from decision-record §5. Nothing else goes in.

```yaml
# pubspec.yaml — the persistence slice only
dependencies:
  drift: 2.34.2
  drift_flutter: 0.3.1
  sqlite3: 3.5.0
  path_provider: 2.1.6
  uuid: 4.6.0
  clock: 1.1.2

dev_dependencies:
  drift_dev: 2.34.5
  build_runner: ">=2.15.0 <2.15.2"
```

1. **Never add `sqlite3_flutter_libs` or `sqlcipher_flutter_libs`.** They arrive transitively from `drift_flutter` 0.3.1 as no-op `+eol` shims. Seeing them in `pubspec.lock` is expected and correct. They are **not** flagged discontinued on pub.dev, so do not write a CI check keyed on that flag — it will never fire (decision #26).
2. **`sqlite3` bundles the engine through Dart build hooks.** No Podfile edit, no `build.gradle` edit, no `.podspec`. The bundled build guarantees `SQLITE_ENABLE_FTS5` and SQLite ≥ 3.37 (which `STRICT` requires) on every device, which is the entire reason `sqflite` was rejected.
3. **The build hook downloads sha256-verified binaries from GitHub at build time.** The *build machine* needs network; the shipped app does not. Say so in the README so a plane-mode `flutter clean && flutter build` failure is not mistaken for a regression.

### 1.2 `build.yaml`

```yaml
# build.yaml — NOT build.yml. A drift discussion exists solely because
# someone lost a day to that typo and FTS5 silently stayed disabled.
targets:
  $default:
    builders:
      drift_dev:
        options:
          sql:
            dialect: sqlite
            options:
              modules:
                - fts5
          # Result sets get value equality so `.distinct()` in the repository
          # actually suppresses duplicate stream emissions (decision #12).
          override_hash_and_equals_in_result_sets: true
          databases:
            shed_book: lib/core/db/database.dart
          schema_dir: drift_schemas/
          test_dir: test/drift/
```

**`store_date_time_values_as_text` is absent and stays absent.** Setting it is irreversible after the first snapshot and it forces one representation onto both instants and civil dates, which are different kinds (decision #29). CI greps `build.yaml` for the key; a match fails the build.

### 1.3 Where the file lives, and the connection

```dart
// lib/core/db/connection.dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';

/// MUST be top-level, and PUBLIC. `DriftNativeOptions.setup` is sent across an
/// isolate boundary, so it must capture nothing — a closure over `this` throws
/// at open — and a private name cannot be referenced from a test.
void configureConnection(CommonDatabase db) {
  // Persistent in the file header; setting it again costs microseconds.
  db.execute('PRAGMA journal_mode = WAL;');

  // FULL, not NORMAL. sqlite.org: WAL + NORMAL "does lose durability…
  // might roll back following a power loss". Spec §5 says assume the phone
  // dies. One extra fsync per commit at ~10 writes/minute is free.
  db.execute('PRAGMA synchronous = FULL;');

  // Per-connection, NOT persistent. Without this every ON DELETE below is
  // decorative — SQLite disables FK enforcement by default.
  db.execute('PRAGMA foreign_keys = ON;');

  // A VACUUM INTO snapshot can briefly contend with a write.
  db.execute('PRAGMA busy_timeout = 5000;');

  // Caps the WAL after a checkpoint so a bulk restore does not leave a
  // permanently swollen -wal file beside the database (doc 04 §2.8).
  db.execute('PRAGMA journal_size_limit = 4194304;');
  db.execute('PRAGMA temp_store = MEMORY;');

  // Per-connection, NOT persistent. Required so that rows removed by an
  // ON DELETE CASCADE still fire the AFTER DELETE triggers that keep
  // search_docs in sync (§9.2). Nothing in this schema fires itself, so
  // there is no recursion to bound.
  db.execute('PRAGMA recursive_triggers = ON;');

  _assertEngineCapabilities(db);
  _snapshotBeforeMigration(db);   // VACUUM INTO, bounded, never rethrows — doc 04 §2.8
}

/// Decision #36: a startup assertion that fails loudly, never a runtime
/// capability probe with a LIKE fallback. If this throws, the bundled
/// binary is not the one `package:sqlite3` documents and nothing downstream
/// is trustworthy.
void _assertEngineCapabilities(CommonDatabase db) {
  final fts5 = db.select(
    "SELECT 1 FROM pragma_compile_options WHERE compile_options = 'ENABLE_FTS5'",
  );
  if (fts5.isEmpty) {
    throw StateError('SQLite build has no FTS5. Expected the bundled sqlite3 build.');
  }
}

QueryExecutor openConnection() {
  return driftDatabase(
    name: 'shed_book',
    native: const DriftNativeOptions(
      // drift_flutter defaults to Documents. Override it.
      databaseDirectory: getApplicationSupportDirectory,
      setup: configureConnection,
    ),
  );
}
```

The same file holds `Future<AppDatabase> openAppDatabase()` — the app's single entry point into the database, which asserts it is not running under `flutter_test` and names the override to add. It is declared and owned by [`01-architecture.md`](01-architecture.md); this document owns only `openConnection()` and `configureConnection` (CONVENTIONS §2.8, R12).

**The pragma set above is the union of this document's list and doc 04's, in that order, and nothing may be dropped from it** (R13). `journal_size_limit` and `temp_store` are load-bearing for restore and migration (doc 04 §2.8); `foreign_keys` and `recursive_triggers` are load-bearing for this schema. A connection configured with a subset of them is a different database.

**Why application support and not documents** (decision #27): if `UIFileSharingEnabled` is ever set so users can grab exports from Files, all of `Documents/` becomes user-visible and user-*deletable*. A shepherd tidying up and deleting `shed_book.sqlite` is a product-ending bug. Both directories are equally backed up, so the choice costs nothing.

> **Needs verification (week one):** that `pragma_compile_options` is itself available in the bundled build. If it is compiled out, replace the assertion with `db.execute('CREATE VIRTUAL TABLE temp.fts5_probe USING fts5(x)')` inside a `try`/`rethrow` — still an assertion, still fails loudly, still not a fallback branch. Record which one shipped.

**No read pool, whatever `drift_flutter` offers.** A 400-ewe database has no read-concurrency problem, and every extra connection is another place `PRAGMA foreign_keys` and `PRAGMA recursive_triggers` can be forgotten — both are per-connection, neither is in the file header. `openConnection()` above is the only construction site, which is what makes that provable (`tool/check_policy.dart`, §1.5).

### 1.4 The database class

```dart
// lib/core/db/database.dart
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart'; // NOT api/migrations.dart
import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;

import 'schema_versions.dart'; // generated by `drift_dev schema steps`

part 'database.g.dart';

/// Read on the background isolate too, so it is a top-level const that
/// captures nothing. Bumped by exactly one per schema change (doc 04 §2.4).
const kSchemaVersion = 1;

@DriftDatabase(
  tables: [
    Seasons, Ewes, EweSeasons, Lambings, Lambs, FosterEvents,
    CareEvents, EweObservations,
    Pens, PenOccupancies, PenOccupancyLambs,
    Treatments, TreatmentWithdrawals,
    Reminders, ReminderRules,
    Notes, MediaAssets,
    VocabTerms, TerminologyOverrides,
    AppSettings, Entitlements,
    EweTouches, EweSummaries,
  ],
  include: {'search.drift', 'views.drift', 'queries.drift'},
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e, {
    this.seedOnCreate = true,
    this.schemaVersionOverride = kSchemaVersion,
  });

  /// False on exactly two paths — the restore/import staging database
  /// (doc 04 §7) and `tool/seed.dart` — where the rows come from a backup
  /// rather than from first-run defaults. Defaulted to the safe value: a
  /// restore that seeds would hand the user a phantom "2026 lambing"
  /// season nobody created.
  final bool seedOnCreate;

  /// Migration tests open the database at an historical version. Production
  /// never passes it. Owned by doc 04 §2.4.
  @visibleForTesting
  final int schemaVersionOverride;

  @override
  int get schemaVersion => schemaVersionOverride;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          if (seedOnCreate) await seedFirstRun(this); // §10
        },
        onUpgrade: stepByStep(/* see 04-migrations-media-backup-restore.md */),
        beforeOpen: (details) async {
          // Decision #39. validateDatabaseSchema is an EXTENSION MEMBER on
          // GeneratedDatabase returning Future<void>. Wrapping it in a sync
          // assert() starts the check and returns true immediately, so a
          // mismatch surfaces as an unhandled async error long afterwards.
          if (kDebugMode) {
            await validateDatabaseSchema();
          }
        },
      );
}
```

This class is shared with [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) §2.3, which owns `kSchemaVersion`, the `stepByStep` callbacks and the `seedOnCreate` restore path. Edit it in one place; the two documents must not drift apart.

`lib/core/db/` may import `package:flutter/foundation.dart` (for `kDebugMode`) but never `package:flutter/material.dart` — see [`01-architecture.md`](01-architecture.md) for the eight layer rules and the `tool/check_policy.dart` gate.

> **Settled — the schema package and the class name.** The schema lives in **`lib/core/db/`** and the class is **`AppDatabase`**, opened by **`openAppDatabase()`** (CONVENTIONS R1, R2; decision-record #9 says `core/db/` verbatim and #20 says `FutureProvider<AppDatabase>`). `lib/data/db/` and `ShedBookDatabase` are banned spellings and appear nowhere in this document. The same strings are in `tool/check_policy.dart`'s `_layers` table, in `lib/data/models.dart`'s re-export and in the `mkdir` line in doc 01 §2.2; a split tree would make rule 8 (`customStatement(` confined to the schema folder) unenforceable, so the three must never diverge again.

> **Needs verification:** importing `package:drift_dev/api/migrations_native.dart` from `lib/` pulls a dev-time package into the app's import graph. Confirm from the `--analyze-size` artifact (see [`13-build-ci-release.md`](13-build-ci-release.md)) that the release build tree-shakes it, and record the measured delta. Keep the import in this one file so any regression is attributable.

### 1.5 Anti-patterns, and how they are caught

| Banned | Why | Caught by |
|---|---|---|
| `sqlite3_flutter_libs` in `pubspec.yaml` | No-op EOL shim; arrives transitively anyway | G2 direct-dependency allowlist |
| `store_date_time_values_as_text` in `build.yaml` | Irreversible; wrong kind model | `tool/check_policy.dart` text rule |
| Any drift `dateTime()` column | Same | `tool/check_policy.dart` text rule on `lib/core/db/tables/` |
| `PRAGMA synchronous = NORMAL` outside the bulk-import helper | Loses the last lambing on a flat battery | `tool/check_policy.dart` allowlisted file |
| A second `NativeDatabase`/`QueryExecutor` construction site | Somewhere `foreign_keys = ON` or `recursive_triggers = ON` will be missed, and both are per-connection | `tool/check_policy.dart`: `driftDatabase(` appears in one file |
| A boolean `current_*` column beside a history table (`pens.occupant_ewe`, `lambs.rearing_dam`) | A dual write a future code path gets wrong; the list screen and the history then disagree (decisions #33, #34) | Review — the schema has no such column, and adding one is the defect |
| `File.copy` of `*.sqlite` | WAL means the DB is three files; the copy is corrupt or stale | `tool/check_policy.dart` text rule |

---

## 2. Conventions every table obeys

1. **Every table is `STRICT`** (`bool get isStrict => true;`). SQLite's dynamic typing will happily store `'twin'` in an INTEGER column. `STRICT` makes the database refuse garbage instead of storing it and pretending, which is spec §12.4 at the storage layer.
2. **Every relationship is a real foreign key with an explicit `ON DELETE`.** Never `KeyAction.noAction` by laziness — choose `cascade` or `restrict` and mean it. `cascade` means "this row has no meaning without its parent" (a lamb without its lambing). `restrict` means "the parent is referenced by a record someone may show a vet" (a ewe with treatments).
3. **Every foreign key is hand-indexed.** SQLite creates no child-key index for you; without one, deleting a season linear-scans every child table and every `RESTRICT` check is a full scan. This includes the `vocab_terms(key)` references, which are the ones people forget because they are nullable and mostly NULL — they are exactly the columns a `RESTRICT` has to scan when a user hides a term. A composite `PRIMARY KEY` or `uniqueKeys` entry counts as the index **only for its leading column**: `{occupancy, lamb}` indexes `occupancy` and does nothing for `lamb`. **One exemption, allowlisted by table name in the test: `app_settings`,** which holds exactly one row, so an index on `current_season` would be pure cost. Nothing else is exempt.
4. **History tables, never a mutable "current" field.** Fostering and pen occupancy are append-only logs with a derived current state.
5. **No column that could encode veterinary advice carries a `DEFAULT` or a `clientDefault`.** Withdrawal days, lambing ease and `ewe_seasons.status` all have no default, because a default is the app answering on the user's behalf.
6. **Closed vocabularies are `CHECK (x IN (…))`. User-editable vocabularies are a foreign key to `vocab_terms(key)`.** That single discriminator decides every enum-shaped column in the schema. If the user may add a term, the schema cannot enumerate it. A foreign key constrains the *key*, never the *list*: nothing in SQL stops `ewe_observations.kind` holding `'dc_starvation'`. The list is enforced in exactly one place — the repository picks from `SELECT key FROM vocab_terms WHERE list = ? AND hidden_at IS NULL`, and `test/data/vocab_list_scope_test.dart` asserts, per column, that every stored key belongs to that column's list. Do not add a trigger; it would fire on restore.
   One list has no foreign key pointing at it: **`lambing_ease`.** `lambings.ease` is an ordinal `INTEGER 1..5` with a `CHECK` (§10.1), and the five `ease_*` vocab rows exist only to carry the user-editable *labels* for those five integers. That is deliberate, not an oversight — widening the scale must be a migration someone has to think about.
7. **`customConstraints` uses SQL column names**, not Dart names — drift converts `birthDam` to `birth_dam`. Write the constraints as literal strings; do not factor them into a helper function, because drift_dev reads them from source and whether it can constant-fold an expression there is unverified and not worth discovering mid-schema.
8. **`NULL` and an explicit "unknown" value are different facts** and both are modelled where both exist. `lambs.sex IS NULL` means not recorded; `lambs.sex = 'unknown'` means the shepherd looked and could not tell. Same shape as `WithdrawalNotRecorded` vs `WithdrawalNotApplicable`. Never collapse them.
9. **Any table whose name does not singularise by dropping one `s` carries an explicit `@DataClassName`.** drift's default is literally "strip the trailing `s`", so `PenOccupancies` generates `PenOccupancie`, `EweTouches` generates `EweTouche` and `EweSummaries` generates `EweSummarie`. Those names then have to appear in `lib/data/models.dart`'s re-export (doc 01 §2.3), in every repository signature and in every test. Name them once, at the table: `@DataClassName('PenOccupancy')`, `@DataClassName('EweTouch')`, `@DataClassName('EweSummary')`. Check any new table against the rule before you commit it — renaming a row class after the first migration snapshot is a whole-codebase edit for zero behaviour change.

### 2.1 The `Identified` mixin

```dart
// lib/core/db/tables/common.dart
import 'package:drift/drift.dart';

/// Carried by every table whose rows cross the export boundary.
/// NOT carried by caches (`ewe_touches`, `ewe_summaries`, `search_docs`),
/// by singletons (`app_settings`, `entitlements`), or by pure join tables.
mixin Identified on Table {
  /// Joins and foreign keys. Device-local. NEVER exported. (§3)
  late final id = integer().autoIncrement()();

  /// UUID v7. The identity that survives export → re-import.
  late final uid = text().withLength(min: 36, max: 36).unique()();

  /// Instants: UTC epoch millis. See §4.
  late final createdAt = integer().map(const InstantConverter())();
  late final updatedAt = integer().map(const InstantConverter())();
}
```

`autoIncrement()` emits `INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT`. The `AUTOINCREMENT` keyword (as opposed to a bare rowid alias) guarantees ids are never reused after a delete, which is what stops a recreated ewe inheriting a culled ewe's notes through a stale foreign key in an old export. Keep it; the `sqlite_sequence` overhead is one row.

---

## 3. The dual-key ID strategy

**`id INTEGER PRIMARY KEY AUTOINCREMENT` for joins. `uid TEXT UNIQUE` holding a UUID v7 for identity.**

```dart
// lib/core/db/uid.dart — the ONE package:uuid call site in the app (R15).
const _uuid = Uuid();
String newUid() => _uuid.v7();
```

The extension-type ids that wrap `id` at every boundary above this layer — `EweId`, `LambingId`, `LambId`, `PenOccupancyId`, `TreatmentId`, `SeasonId` and the rest — live in **`lib/domain/ids.dart`** (R5): the ids are domain vocabulary, and layer rule 1 keeps `lib/domain/` pure, which is also why `newUid()` cannot live beside them. This document owns *which* ids exist (one per table whose rows cross a repository boundary); [`05-domain-correctness.md`](05-domain-correctness.md) owns their shape. `lib/data/ids.dart` does not exist.

| | `id` | `uid` |
|---|---|---|
| Used for | joins, foreign keys, FTS5 `content_rowid`, drift companions | export, re-import, JSON/CSV foreign keys |
| Scope | this database file, this device | universal, forever |
| Crosses the export boundary | **never** | always, as the first column/field |
| Stable across a restore | no | yes |

**Why an autoincrement id must never appear in a backup file.** A backup is restored onto a *different* database — a new phone, or the same phone after a wipe. Row 47 there is not row 47 here. If the JSON carried integer foreign keys, restore would have to renumber everything and rewrite every reference, which is a bug farm; and a two-year-old export re-imported after the user culled and recreated ewe 412 would attach the old ewe's notes to the new animal through a coincidentally-matching integer. Import is an **upsert on `uid`, never on `tag`** — tags get corrected and reused (§5); uids never change. That makes re-importing the same file twice a no-op, which matters because "I'll just import my backup again and see" is a real user behaviour.

Foreign keys in an export are the parent's `uid`: `birth_dam_uid`, not `birth_dam`. See [`09-export-formats.md`](09-export-formats.md).

**UUID v7, settled.** v7's 48-bit millisecond prefix keeps the `uid` index appending rather than scattering. v4 and ULID were weighed and rejected in decision #32; do not re-open them. `uuid` 4.6.0 implements RFC 9562 v7.

**Gate.** `test/policy/export_carries_no_row_ids_test.dart` seeds a database through `tool/seed.dart`, produces the JSON backup and every CSV, and asserts: no JSON object contains a key named `id`; no CSV header contains a bare `id` column; every reference field name ends in `_uid`.

---

## 4. Time and unit storage

### 4.1 The two kinds

**If it is a moment that happened, it is an instant. If it is a square on a calendar, it is a civil date.** They get different SQLite types and different Dart types, and the difference is visible in the column declaration.

| Kind | SQLite | Dart | Converter |
|---|---|---|---|
| Instant | `INTEGER` UTC epoch **millis** | `extension type const Instant(int epochMillis)` | `InstantConverter` |
| Civil date | `TEXT 'YYYY-MM-DD'` | `extension type const LocalDate._(String iso)` | `LocalDateConverter` |
| Partial civil date (ewe DOB) | `TEXT 'YYYY'` / `'YYYY-MM'` / `'YYYY-MM-DD'` | `extension type const PartialDate._(String iso)` | `PartialDateConverter` |

`Instant`, `LocalDate` and `PartialDate` are defined in [`05-domain-correctness.md`](05-domain-correctness.md) §2; the three converters below are the only thing this document owns. All three are `const`, because a `TypeConverter` is constructed once per column declaration.

```dart
// lib/core/db/converters.dart — ONE FILE, not a folder (R21).
class InstantConverter extends TypeConverter<Instant, int> {
  const InstantConverter();
  @override Instant fromSql(int fromDb) => Instant(fromDb);
  @override int toSql(Instant value) => value.epochMillis;
}

class LocalDateConverter extends TypeConverter<LocalDate, String> {
  const LocalDateConverter();
  @override LocalDate fromSql(String fromDb) => LocalDate.parse(fromDb);
  @override String toSql(LocalDate value) => value.iso;
}

/// Used by exactly one column, `ewes.date_of_birth`. `fromSql` uses the
/// strict parser for the same reason `LocalDateConverter` does: a row
/// holding '2026-2' throws on read instead of becoming a plausible date.
/// It NEVER widens 'YYYY' to 'YYYY-01-01' — partial precision is the fact.
class PartialDateConverter extends TypeConverter<PartialDate, String> {
  const PartialDateConverter();
  @override PartialDate fromSql(String fromDb) => PartialDate.parse(fromDb);
  @override String toSql(PartialDate value) => value.iso;
}
```

Rules:

1. **Drift `dateTime()` columns are banned everywhere.** The integer mode is *seconds* and drift "always returns a non-UTC value, so even when UTC date times are stored, this information is lost"; the text mode mixes instant and civil semantics in one column. Both are a single global build flag applied to every column in the app.
2. **`store_date_time_values_as_text` is never set** (§1.2). Irreversible after the first snapshot.
3. **`ORDER BY` a civil-date column is correct as written** — ISO-8601 sorts lexicographically. That is why the format is fixed to `YYYY-MM-DD` and enforced with a `GLOB` CHECK rather than left to convention.
4. **No SQL-side time.** `CURRENT_TIMESTAMP`, `CURRENT_DATE`, `CURRENT_TIME`, `date('now')` and `datetime('now')` are banned (decision #47). SQL compares and orders opaque integers and lexically-sortable strings; every piece of time arithmetic happens in Dart behind `appNow()`, the single wall-clock reader (`lib/core/time/app_clock.dart`, R23). The bare tokens `strftime` and `datetime` are *not* banned — they false-positive and the rule gets weakened.
5. **Consequence, stated so nobody hunts for it:** the schema cannot express `CHECK (clear_date >= date(administered_at))`, because that needs a SQL date function. That invariant is enforced by the single `clearDateFor()` function at write time and surfaced afterwards as the `WarningCode.clearDateDisagrees` warning — shown, never applied. See [`05-domain-correctness.md`](05-domain-correctness.md).

### 4.2 The two schema-level date/instant guards

Every civil-date column carries a format CHECK:

```
CHECK (start_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')
```

Every instant column carries a sanity band:

```
CHECK (occurred_at BETWEEN 946684800000 AND 4102444800000)   -- 2000-01-01 .. 2100-01-01 UTC
```

The band exists to catch a **seconds-vs-millis unit slip**, which is the one time bug that produces a plausible-looking row (a 2026 lambing filed in 1970). It is deliberately far wider than any real lambing record. Never narrow either guard to something a shepherd could legitimately trip.

**The §12.5 provenance quad, and which tables carry it.** Every table whose rows the user can date carries four columns together — the event time, `captured_at`, `original_effective`, `time_source` — plus the two paired CHECKs (`time_source IN ('auto','entered','edited')` and `(time_source = 'edited') = (original_effective IS NOT NULL)`). They are the columns `RecordedTime` maps onto (doc 05 §4.2). Seven tables carry it: `Lambings`, `Treatments`, `CareEvents`, `EweObservations`, `PenOccupancies`, `FosterEvents` and `Notes` (R37). The event-time column is `occurred_at` with exactly three documented exceptions — `treatments.administered_at`, `pen_occupancies.entered_at`, `foster_events.effective_at` — and the provenance columns are never renamed per table: `original_effective`, never `original_effective_at`. **This must land before the first schema snapshot:** adding a `NOT NULL` column afterwards is a full table rebuild on tables that point at the user's records. Until it does, the standing rule is absolute — **a table without the quad has no edit verb.**

### 4.3 Units

**Canonical mass is integer grams. Canonical temperature is integer milli-°C.** No `unit` column on any measurement.

The two wrapper types are `Grams` (`lib/domain/units/grams.dart`) and `MilliCelsius` (`lib/domain/units/milli_celsius.dart`), both `extension type const …(int value)`, declared and owned by [`05-domain-correctness.md`](05-domain-correctness.md) §2.3 along with their conversions. This document owns only the storage decision: `lambs.birth_weight_g INTEGER` holds grams, and no display unit ever reaches a column.

Measured, and the reason this is not a taste question: storing mass at 0.1 kg resolution silently rewrites **132 of 241** lb entries; storing temperature at 0.1 °C rewrites **89 of 201** °F entries. Both are spec §12.4 violations produced purely by a storage choice, invisible in code review, in over half of possible entries. Conversion happens at the display edge only; the edit form is seeded from canonical and parses the *typed text* back to canonical.

> **Ruled 2026-08-01 (decision-record §7.0 row 11): temperature appears nowhere, and the setting is dropped.** **No v1 table stores a temperature**, and `app_settings.temperature_unit` does not exist either — nor its `CHECK (temperature_unit IN ('c','f'))`, nor the Settings °C/°F row, nor `temperatureUnitProvider`. An unused setting is a 3am tax, and this was the only window in which removing the column was free: migrations are forward-only and never destructive (#37), so before the first snapshot the column can simply never exist, and after it, it ships forever unread.
>
> `MilliCelsius` **still ships** and is not deleted (`05 §5.2`): the measured reason it exists — storing temperature at 0.1 °C silently rewrites 89 of 201 °F entries — is independent of whether a v1 column uses it. If a future version rules that lamb body temperature ships, it lands as `temp_mc INTEGER NULL` on `care_events` (the `warmed` kind is its obvious home) plus a `CHECK (temp_mc IS NULL OR temp_mc BETWEEN 25000 AND 45000)` unit-slip guard, and `temperature_unit` comes back with it — as an additive migration, which is what forward-only allows.

---

## 5. The tables

Files: `lib/core/db/tables/*.dart`, one file per cluster. Indices are listed with each table; every one is deliberate.

### 5.1 Seasons — the scoping spine

```dart
// lib/core/db/tables/seasons.dart
@TableIndex(name: 'idx_season_start', columns: {#startDate})
class Seasons extends Table with Identified {
  late final year = integer()();
  late final label = text().withLength(min: 1, max: 60)();
  late final startDate = text().map(const LocalDateConverter())();
  late final endDate = text().map(const LocalDateConverter()).nullable()();

  /// The lambing-percentage denominator. NO DEFAULT: a season with a blank
  /// ewes_to_ram is "I did not record it", not zero and not "same as lambed".
  late final ewesToRam = integer().nullable()();
  late final scanningResult = integer().nullable()();
  late final notes = text().nullable()();

  /// Decision #91 and §7.0 ruling 8: the free tier is SEASON-primary, so
  /// this is the column that matters — the second season is the gate, and
  /// `ewes.over_free_cap` is the calm secondary one. Rows over the cap are
  /// real rows, flagged, never hidden, greyed out or made read-only.
  /// Cleared in one transaction on unlock.
  late final overFreeCap = boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => [
        "CHECK (start_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
        "CHECK (end_date IS NULL OR end_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
        'CHECK (end_date IS NULL OR end_date >= start_date)',
        'CHECK (ewes_to_ram IS NULL OR ewes_to_ram >= 0)',
        'CHECK (scanning_result IS NULL OR scanning_result >= 0)',
        'CHECK (year BETWEEN 2000 AND 2100)',
        'CHECK (length(trim(label)) > 0)',
      ];

  @override
  bool get isStrict => true;
}
```

`end_date >= start_date` is a plain string comparison and correct *because* the format is fixed and GLOB-checked. That is the whole payoff of the TEXT civil-date convention.

**A season is not a foreign key on `Ewe`.** A ewe is a physical animal that persists across seasons — that is the retention feature. Season scopes the *events*: `EweSeasons`, `Lambings`, `PenOccupancies`, `Treatments`, `Reminders`, `CareEvents`, `EweObservations`, `FosterEvents`.

### 5.2 Ewes

```dart
@TableIndex(name: 'idx_ewe_status', columns: {#status})
@TableIndex(name: 'idx_ewe_tagdigits', columns: {#tagDigits})
@TableIndex.sql(
  // §7.0 ruling 7: unique among ACTIVE animals only. A culled 412 releases
  // the tag; a new 412 is a new row with its own uid and its own history.
  "CREATE UNIQUE INDEX idx_ewe_tag_active ON ewes (tag) WHERE status = 'active'",
)
class Ewes extends Table with Identified {
  /// Exactly as typed. Never normalised on write — spec §12.4.
  late final tag = text().withLength(min: 1, max: 32)();

  /// Digits-only projection of [tag], written in the same statement.
  /// A projection, not a correction: the typed value is preserved verbatim
  /// alongside it, so the `normalize*` ban does not apply (decision #55).
  late final tagDigits = text().withLength(min: 0, max: 32)();

  late final eid = text().withLength(min: 0, max: 32).nullable()();
  late final breed = text().nullable()();

  /// Partial precision is a real state. Do not pad a year to 1 January.
  late final dateOfBirth = text().map(const PartialDateConverter()).nullable()();

  late final source = text().nullable()();
  late final status = text().withDefault(const Constant('active'))();
  late final notes = text().nullable()();
  late final overFreeCap = boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => [
        "CHECK (status IN ('active','sold','dead','culled'))",
        'CHECK (length(trim(tag)) > 0)',
        "CHECK (date_of_birth IS NULL"
            " OR date_of_birth GLOB '[0-9][0-9][0-9][0-9]'"
            " OR date_of_birth GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]'"
            " OR date_of_birth GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
      ];

  @override
  bool get isStrict => true;
}
```

### 5.3 EweSeasons — what the spec's `seasons[]` hides

Barren rate is not computable from lambings, because a barren ewe *has no lambing row*. You need an explicit participation record.

```dart
@TableIndex(name: 'idx_eweseason_season', columns: {#season})
@TableIndex(name: 'idx_eweseason_ewe', columns: {#ewe})
class EweSeasons extends Table with Identified {
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();
  late final ewe = integer().references(Ewes, #id, onDelete: KeyAction.cascade)();

  /// NO DEFAULT. Defaulting to 'to_ram' would silently assert a ewe was put
  /// to the ram, which is the denominator of a commercially sensitive number
  /// (decision #59). Every writer knows which status it is asserting.
  late final status = text()();

  late final scannedCount = integer().nullable()();
  late final notes = text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{season, ewe}];

  @override
  List<String> get customConstraints => [
        "CHECK (status IN ('to_ram','scanned','lambed','barren','aborted','died','sold'))",
        'CHECK (scanned_count IS NULL OR scanned_count BETWEEN 0 AND 6)',
      ];

  @override
  bool get isStrict => true;
}
```

`ON DELETE CASCADE` from `Seasons` is right: deleting a season removes that season's participation records and must not remove the ewes. `ON DELETE CASCADE` from `Ewes` is right for the same reason in reverse.

**Denominator rule for lambing percentage:** prefer `seasons.ewes_to_ram` when non-null; otherwise `COUNT(ewe_seasons WHERE status = 'to_ram')`; if both are absent the statistic is `notComputable`. It **never** falls back to ewes lambed (decision #59).

### 5.4 Lambings

```dart
@TableIndex(name: 'idx_lambing_season_time', columns: {#season, #occurredAt})
@TableIndex(name: 'idx_lambing_ewe_time', columns: {#ewe, #occurredAt})
@TableIndex(name: 'idx_lambing_localdate', columns: {#season, #localDate})
@TableIndex(name: 'idx_lambing_presentation', columns: {#presentation})
class Lambings extends Table with Identified {
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();
  late final ewe = integer().references(Ewes, #id, onDelete: KeyAction.restrict)();

  // --- The §12.5 provenance quad. See RecordedTime in doc 05. ---
  late final occurredAt = integer().map(const InstantConverter())();
  late final capturedAt = integer().map(const InstantConverter())();
  late final originalEffective =
      integer().map(const InstantConverter()).nullable()();
  late final timeSource = text().withDefault(const Constant('auto'))();

  /// Denormalised local civil date of [occurredAt], written in the same
  /// statement. The grouping key for the lambing-spread histogram: SQLite
  /// cannot bucket by the shepherd's civil day without a tz database, Dart can.
  late final localDate = text().map(const LocalDateConverter())();

  /// EXACTLY what the shepherd tapped. 1=single … 4=quad, 5="more".
  /// The number of Lamb rows is NOT forced to agree — spec §12.4.
  ///
  /// NULLABLE, and this is load-bearing (R6): the lambing row is written on
  /// the FIRST tap, before any birth type has been offered, and the record
  /// must survive being interrupted at any point. NULL means "not yet
  /// tapped", which is a different fact from any of 1..5 and is never
  /// defaulted to `single`. See `BirthType` in `lib/domain/birth_type.dart`
  /// for the enum that carries these codes.
  late final declaredBirthType = integer().nullable()();

  /// 1..5. NO DEFAULT and nullable: a blank score means "not scored",
  /// which is a different fact from "unassisted" (decision #59).
  late final ease = integer().nullable()();

  late final assistedBy = text().nullable()();
  late final presentation =
      text().nullable().references(VocabTerms, #key, onDelete: KeyAction.restrict)();
  late final presentationNote = text().nullable()();
  late final note = text().nullable()();

  @override
  List<String> get customConstraints => [
        'CHECK (occurred_at BETWEEN 946684800000 AND 4102444800000)',
        'CHECK (captured_at BETWEEN 946684800000 AND 4102444800000)',
        "CHECK (time_source IN ('auto','entered','edited'))",
        "CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))",
        "CHECK (local_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
        'CHECK (declared_birth_type IS NULL OR declared_birth_type BETWEEN 1 AND 5)',
        'CHECK (ease IS NULL OR ease BETWEEN 1 AND 5)',
      ];

  @override
  bool get isStrict => true;
}
```

The contradiction from spec §12.4 surfaces as a **view**, never a trigger and never a correction:

```sql
-- lib/core/db/views.drift
CREATE VIEW lambing_consistency AS
SELECT
  l.id                  AS lambing_id,
  l.declared_birth_type AS declared,
  COUNT(lb.id)          AS recorded,
  -- declared = 5 means "more than four, count not declared", so five or more
  -- attached lambs is NOT a mismatch. Getting this wrong shows a false badge
  -- on every large litter.
  -- declared IS NULL means "not tapped yet" (R6) — no contradiction is
  -- possible, and the guard is explicit because `COUNT(…) <> NULL` is NULL,
  -- which would make this column three-valued for every in-progress lambing.
  (l.declared_birth_type IS NOT NULL
     AND COUNT(lb.id) <> l.declared_birth_type
     AND NOT (l.declared_birth_type = 5 AND COUNT(lb.id) >= 5)) AS is_mismatched
FROM lambings l
LEFT JOIN lambs lb ON lb.lambing = l.id
GROUP BY l.id;
```

Both numbers are preserved verbatim. There is no `warnings` column anywhere in this schema and no `fix()` anywhere in the codebase: a warning cannot be persisted because there is nowhere to persist it, and cannot mutate because it holds no writer (decision #54).

### 5.5 Lambs

```dart
@TableIndex(name: 'idx_lamb_lambing', columns: {#lambing})
@TableIndex(name: 'idx_lamb_birthdam', columns: {#birthDam})
@TableIndex(name: 'idx_lamb_tagdigits', columns: {#tagDigits})
@TableIndex(name: 'idx_lamb_deathcause', columns: {#deathCause})
// Ruled 2026-08-01 (§7.0 row 13). SQLite creates no child-key index
// automatically (#31), and the ewe card reads this the other way round —
// "which lamb was she?" — on every retained ewe.
@TableIndex(name: 'idx_lamb_became_ewe', columns: {#becameEwe})
@TableIndex.sql(
  "CREATE UNIQUE INDEX idx_lamb_tag_alive ON lambs (tag) "
  "WHERE tag IS NOT NULL AND status = 'alive'",
)
class Lambs extends Table with Identified {
  late final lambing = integer().references(Lambings, #id, onDelete: KeyAction.cascade)();

  /// Immutable, denormalised from lambings.ewe at insert. Enforced by a
  /// BEFORE UPDATE trigger, not by Dart. See §7.
  late final birthDam = integer().references(Ewes, #id, onDelete: KeyAction.restrict)();

  late final tag = text().nullable()();
  late final tagDigits = text().nullable()();

  /// NULL = not recorded. 'unknown' = the shepherd looked and could not tell.
  /// The Dart side is `enum Sex { female('f'), male('m'), unknown('unknown') }`
  /// in `lib/domain/sex.dart` (R45); `NULL` is modelled as `Sex?`, never as
  /// `Sex.unknown`.
  late final sex = text().nullable()();

  late final birthWeightG = integer().nullable()();
  late final status = text().withDefault(const Constant('alive'))();

  /// Civil date: the shepherd knows the day, not the minute. Forcing a time
  /// would invent precision the mortality buckets then over-claim.
  late final deathDate = text().map(const LocalDateConverter()).nullable()();
  late final deathCause =
      text().nullable().references(VocabTerms, #key, onDelete: KeyAction.restrict)();

  late final petLamb = boolean().withDefault(const Constant(false))();
  late final bottleFeeds = integer().withDefault(const Constant(0))();
  late final notes = text().nullable()();

  /// The retained lamb, promoted to the breeding flock. Ruled 2026-08-01
  /// (decision-record §7.0 row 13). NULL for every lamb that was not kept,
  /// which is nearly all of them. `setNull` and not `cascade`: deleting the
  /// ewe row must not delete the lamb she was, because the lamb is a record of
  /// a birth that happened. Hand-indexed below — SQLite creates no child-key
  /// index automatically (#31).
  late final becameEwe =
      integer().nullable().references(Ewes, #id, onDelete: KeyAction.setNull)();

  @override
  List<String> get customConstraints => [
        "CHECK (sex IS NULL OR sex IN ('f','m','unknown'))",
        "CHECK (status IN ('alive','dead','stillborn','sold'))",
        // A death date implies a death. A death does NOT imply a date —
        // "died, date not recorded" is a real state and lands in unknownAge.
        "CHECK (death_date IS NULL OR status IN ('dead','stillborn'))",
        "CHECK (death_cause IS NULL OR status IN ('dead','stillborn'))",
        "CHECK (death_date IS NULL OR death_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
        // A unit-slip guard (5 g vs 5 kg), NOT a husbandry opinion.
        // Never narrow this to a range a vet would recognise — spec §12.2.
        'CHECK (birth_weight_g IS NULL OR birth_weight_g BETWEEN 200 AND 20000)',
        'CHECK (bottle_feeds >= 0)',
      ];

  @override
  bool get isStrict => true;
}
```

**A lamb that died before tagging is counted, fully.** Lamb identity is the row, never the tag; `tag` is nullable at every layer. Anything else loses exactly the losses that matter most.

### 5.6 CareEvents (spec §7.2)

Checkbox state on the Lambing Entry screen is `EXISTS(…)`, never a boolean column — that keeps "colostrum given at 03:22" recoverable, and it gives the colostrum reminder something to be completed *from*. Completing the reminder writes the `CareEvent`; it is the same tap.

```dart
@TableIndex(name: 'idx_care_lambing_kind', columns: {#lambing, #kind})
@TableIndex(name: 'idx_care_lamb_kind', columns: {#lamb, #kind})
@TableIndex(name: 'idx_care_season', columns: {#season})
class CareEvents extends Table with Identified {
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();
  late final lambing =
      integer().nullable().references(Lambings, #id, onDelete: KeyAction.cascade)();
  late final lamb =
      integer().nullable().references(Lambs, #id, onDelete: KeyAction.cascade)();

  late final kind = text()();

  // A care event is exactly as deferrable as a lambing, so it carries the
  // same §12.5 provenance quad.
  late final occurredAt = integer().map(const InstantConverter())();
  late final capturedAt = integer().map(const InstantConverter())();
  late final originalEffective =
      integer().map(const InstantConverter()).nullable()();
  late final timeSource = text().withDefault(const Constant('auto'))();

  late final volumeMl = integer().nullable()();
  late final method = text().nullable()();
  late final note = text().nullable()();

  @override
  List<String> get customConstraints => [
        'CHECK ((lambing IS NOT NULL) + (lamb IS NOT NULL) = 1)',
        "CHECK (kind IN ('colostrum','navel_dip','stomach_tube','warmed'))",
        "CHECK (method IS NULL OR method IN ('teat','tube','bottle'))",
        // ml-vs-litres unit-slip guard. Not a dose recommendation. §12.2.
        'CHECK (volume_ml IS NULL OR volume_ml BETWEEN 1 AND 2000)',
        'CHECK (occurred_at BETWEEN 946684800000 AND 4102444800000)',
        'CHECK (captured_at BETWEEN 946684800000 AND 4102444800000)',
        "CHECK (time_source IN ('auto','entered','edited'))",
        "CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))",
      ];

  @override
  bool get isStrict => true;
}
```

`kind` is a **closed** CHECK, not a vocabulary FK: these four are the ones spec §7.2 names and each is wired to a notification channel id frozen at release (decision #65). Adding a fifth is a schema migration and a channel decision, which is the correct amount of friction.

### 5.7 EweObservations (spec §7.7)

"3 seasons · avg 2.0 · assisted twice · prolapsed 2025" is not computable from free text, and "filter the flock by anything" cannot include a free-text field. Mothering, prolapse and mastitis are not derivable from anything else in the schema, so they get a table.

```dart
@TableIndex(name: 'idx_eweobs_ewe_time', columns: {#ewe, #occurredAt})
@TableIndex(name: 'idx_eweobs_season_kind', columns: {#season, #kind})
@TableIndex(name: 'idx_eweobs_kind', columns: {#kind})
@TableIndex(name: 'idx_eweobs_lambing', columns: {#lambing})
class EweObservations extends Table with Identified {
  late final ewe = integer().references(Ewes, #id, onDelete: KeyAction.cascade)();
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();
  late final lambing =
      integer().nullable().references(Lambings, #id, onDelete: KeyAction.setNull)();

  /// User-editable vocabulary → FK, not CHECK (convention 6).
  late final kind = text().references(VocabTerms, #key, onDelete: KeyAction.restrict)();

  // The §12.5 provenance quad (R37). An observation is as deferrable as a
  // lambing — "she prolapsed about midnight" is entered at 06:00 — so the
  // quad is not optional, and it must land before the first snapshot.
  late final occurredAt = integer().map(const InstantConverter())();
  late final capturedAt = integer().map(const InstantConverter())();
  late final originalEffective =
      integer().map(const InstantConverter()).nullable()();
  late final timeSource = text().withDefault(const Constant('auto'))();

  late final note = text().nullable()();

  @override
  List<String> get customConstraints => [
        'CHECK (occurred_at BETWEEN 946684800000 AND 4102444800000)',
        'CHECK (captured_at BETWEEN 946684800000 AND 4102444800000)',
        "CHECK (time_source IN ('auto','entered','edited'))",
        "CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))",
      ];

  @override
  bool get isStrict => true;
}
```

> **The §12.2 boundary, and it belongs in this table's doc comment in the source too:** the app records *what the shepherd observed*. It never infers `poor_mothering` from a lamb death, never infers `no_milk` from a bottle-fed lamb, and never writes a row on the user's behalf.

### 5.8 Treatments and withdrawals (spec §7.5, §12.1)

```dart
@TableIndex(name: 'idx_treatment_ewe_time', columns: {#ewe, #administeredAt})
@TableIndex(name: 'idx_treatment_lamb_time', columns: {#lamb, #administeredAt})
@TableIndex(name: 'idx_treatment_season_time', columns: {#season, #administeredAt})
@TableIndex(name: 'idx_treatment_route', columns: {#route})
class Treatments extends Table with Identified {
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();

  // Polymorphic subject as two nullable FKs + a CHECK. A (type, id) pair
  // cannot be a foreign key, so SQLite could not enforce that the animal
  // exists, could not cascade, and could not stop an orphan — in a record
  // that may be shown to a vet, an orphan is worse than useless.
  //
  // RESTRICT on `ewe`, CASCADE on `lamb`, and the asymmetry is deliberate.
  // Convention 2: a ewe with treatments is a record someone may show a vet,
  // so she cannot be deleted out from under it — and she never needs to be,
  // because a ewe leaves the flock by `status = 'culled'`, not by DELETE.
  // A lamb cannot be RESTRICT: deleting a season CASCADEs seasons → lambings
  // → lambs, and a RESTRICT here would abort that delete from a child table
  // the user never sees. The medicine book is preserved on the path that
  // matters (never losing a row while the animal exists) and season deletion
  // stays possible — it is the one destructive flow, it has no undo, and
  // decision #69 already guards it with the app's only `canPop: false`.
  late final ewe =
      integer().nullable().references(Ewes, #id, onDelete: KeyAction.restrict)();
  late final lamb =
      integer().nullable().references(Lambs, #id, onDelete: KeyAction.cascade)();

  late final productName = text().withLength(min: 1, max: 120)();
  late final doseText = text().nullable()();
  late final route =
      text().nullable().references(VocabTerms, #key, onDelete: KeyAction.restrict)();
  late final batchNo = text().nullable()();

  late final administeredAt = integer().map(const InstantConverter())();
  late final capturedAt = integer().map(const InstantConverter())();
  late final originalEffective =
      integer().map(const InstantConverter()).nullable()();
  late final timeSource = text().withDefault(const Constant('auto'))();

  /// Decision #69: undo for a treatment is a SOFT VOID, because the row may
  /// already have been printed into a medicine book handed to a vet. The
  /// medicine book shows the void; it never loses the row.
  late final voidedAt = integer().map(const InstantConverter()).nullable()();

  late final note = text().nullable()();

  @override
  List<String> get customConstraints => [
        'CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) = 1)',
        'CHECK (length(trim(product_name)) > 0)',
        'CHECK (administered_at BETWEEN 946684800000 AND 4102444800000)',
        'CHECK (captured_at BETWEEN 946684800000 AND 4102444800000)',
        "CHECK (time_source IN ('auto','entered','edited'))",
        "CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))",
      ];

  @override
  bool get isStrict => true;
}
```

There is **no `withdrawal_days` column on `treatments`** and **no medicines lookup table anywhere**. A nullable `int?` conflates "the label says 0 days" with "I didn't look", and `0` is a real label value. Withdrawals are a child table, 0..n rows per treatment:

```dart
@TableIndex(name: 'idx_withdrawal_clear', columns: {#clearDate})
class TreatmentWithdrawals extends Table with Identified {
  late final treatment =
      integer().references(Treatments, #id, onDelete: KeyAction.cascade)();

  /// 'meat' | 'milk'. One product routinely prints different figures.
  late final target = text()();

  /// 'days' | 'not_applicable'. NO ROW for a target means NotRecorded.
  late final kind = text()();

  /// NO DEFAULT. NO clientDefault. The app physically cannot write this
  /// row without the user having typed a number off the bottle. Spec §12.1
  /// enforced by the schema, not by a code review.
  late final days = integer().nullable()();

  /// The one stored derived value (decision #50). Computed exactly once at
  /// write time by clearDateFor(); its inputs live alongside it forever.
  /// This is a record of what the app TOLD the user and printed into the
  /// medicine-book PDF, not a cache.
  late final clearDate = text().map(const LocalDateConverter()).nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{treatment, target}];

  @override
  List<String> get customConstraints => [
        "CHECK (target IN ('meat','milk'))",
        "CHECK (kind IN ('days','not_applicable'))",
        "CHECK ((kind = 'days') = (days IS NOT NULL))",
        "CHECK ((kind = 'days') = (clear_date IS NOT NULL))",
        'CHECK (days IS NULL OR days >= 0)',
        "CHECK (clear_date IS NULL OR clear_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
      ];

  @override
  bool get isStrict => true;
}
```

**The two gates that prove "never default a withdrawal" (decision #52) — and only these two:**

1. `test/policy/withdrawal_has_no_default_test.dart` parses the committed `drift_schemas/drift_schema_v1.json` and asserts `defaultValue` and `clientDefault` are both null for `treatment_withdrawals.days`.
2. A widget test that the Treatment entry screen renders no pre-filled number in the withdrawal field.

Do not add a source heuristic banning numeric literals near "withdrawal" — it fires on these very `CHECK` constraints and on test fixtures.

### 5.9 Pens and occupancy

```dart
class Pens extends Table with Identified {
  late final label = text().withLength(min: 1, max: 24)();
  late final sortOrder = integer().withDefault(const Constant(0))();
  late final isActive = boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column>> get uniqueKeys => [{label}];

  @override
  List<String> get customConstraints => ['CHECK (length(trim(label)) > 0)'];

  @override
  bool get isStrict => true;
}

// drift's default data-class name strips a trailing 's': `PenOccupancies`
// would generate `PenOccupancie`. Name it explicitly — `lib/data/models.dart`
// re-exports `PenOccupancy` (doc 01 §2.3).
@DataClassName('PenOccupancy')
@TableIndex(name: 'idx_penocc_pen_time', columns: {#pen, #enteredAt})
@TableIndex(name: 'idx_penocc_ewe', columns: {#ewe})
@TableIndex(name: 'idx_penocc_season', columns: {#season})
@TableIndex.sql(
  // The database physically refuses two ewes in pen 3 at once. This is
  // "the whiteboard gets wiped" solved at the storage layer.
  'CREATE UNIQUE INDEX idx_penocc_one_open '
  'ON pen_occupancies (pen) WHERE exited_at IS NULL',
)
class PenOccupancies extends Table with Identified {
  late final pen = integer().references(Pens, #id, onDelete: KeyAction.restrict)();
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();
  late final ewe =
      integer().nullable().references(Ewes, #id, onDelete: KeyAction.restrict)();

  /// The event time. One of the three documented exceptions to the
  /// `occurred_at` column-name rule, alongside `treatments.administered_at`
  /// and `foster_events.effective_at` (R37).
  late final enteredAt = integer().map(const InstantConverter())();

  // The rest of the §12.5 provenance quad (R37): the pen tile renders an
  // entry time, and every displayed event time carries its provenance label.
  late final capturedAt = integer().map(const InstantConverter())();
  late final originalEffective =
      integer().map(const InstantConverter()).nullable()();
  late final timeSource = text().withDefault(const Constant('auto'))();

  late final exitedAt = integer().map(const InstantConverter()).nullable()();

  /// The stored keys of `enum PenExitReason { turnedOut('turned_out'),
  /// moved('moved'), died('died'), other('other') }` in
  /// `lib/domain/penning.dart`. Not optional when `exited_at` is set — the
  /// paired CHECK below is what makes `exitPen`'s `required reason` storable.
  late final exitReason = text().nullable()();

  @override
  List<String> get customConstraints => [
        'CHECK (entered_at BETWEEN 946684800000 AND 4102444800000)',
        'CHECK (captured_at BETWEEN 946684800000 AND 4102444800000)',
        "CHECK (time_source IN ('auto','entered','edited'))",
        "CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))",
        'CHECK (exited_at IS NULL OR exited_at >= entered_at)',
        "CHECK (exit_reason IS NULL OR exit_reason IN ('turned_out','moved','died','other'))",
        'CHECK ((exited_at IS NULL) = (exit_reason IS NULL))',
      ];

  @override
  bool get isStrict => true;
}

// The composite primary key indexes `occupancy` (leading column) and nothing
// else, so `lamb` needs its own index — convention 3.
@TableIndex(name: 'idx_penocclamb_lamb', columns: {#lamb})
class PenOccupancyLambs extends Table {
  late final occupancy =
      integer().references(PenOccupancies, #id, onDelete: KeyAction.cascade)();
  late final lamb = integer().references(Lambs, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {occupancy, lamb};

  @override
  bool get isStrict => true;
}
```

`ON DELETE RESTRICT` on `pen` means a pen with history cannot be deleted. Correct: the pen board is a record, not a whiteboard. Deactivate it (`is_active = 0`) instead.

See §8 for the live-board query and the hours-since-penned rule.

### 5.10 Reminders

```dart
@TableIndex(name: 'idx_reminder_due_open', columns: {#dueAt, #completedAt})
@TableIndex(name: 'idx_reminder_season', columns: {#season})
@TableIndex(name: 'idx_reminder_ewe', columns: {#ewe})
@TableIndex(name: 'idx_reminder_lamb', columns: {#lamb})
@TableIndex(name: 'idx_reminder_lambing', columns: {#lambing})
@TableIndex(name: 'idx_reminder_treatment', columns: {#treatment})
class Reminders extends Table with Identified {
  late final season =
      integer().nullable().references(Seasons, #id, onDelete: KeyAction.cascade)();
  late final ewe =
      integer().nullable().references(Ewes, #id, onDelete: KeyAction.cascade)();
  late final lamb =
      integer().nullable().references(Lambs, #id, onDelete: KeyAction.cascade)();
  late final lambing =
      integer().nullable().references(Lambings, #id, onDelete: KeyAction.cascade)();
  late final treatment =
      integer().nullable().references(Treatments, #id, onDelete: KeyAction.cascade)();

  late final kind = text()();
  late final title = text()();
  late final dueAt = integer().map(const InstantConverter())();
  late final completedAt = integer().map(const InstantConverter()).nullable()();
  late final muted = boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => [
        "CHECK (kind IN ('colostrum','navel','turn_out','tag_by',"
            "'ring_dock_castrate','second_dose','withdrawal_end','custom'))",
        'CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) + (lambing IS NOT NULL)'
            ' + (treatment IS NOT NULL) <= 1)',
        'CHECK (due_at BETWEEN 946684800000 AND 4102444800000)',
      ];

  @override
  bool get isStrict => true;
}

class ReminderRules extends Table {
  late final kind = text()();
  late final enabled = boolean().withDefault(const Constant(true))();
  late final offsetMinutes = integer()();

  @override
  Set<Column> get primaryKey => {kind};
  @override
  bool get isStrict => true;
}
```

**There is no `os_notification_id` column, and adding one is a defect.** Under decision #63 the OS projection is a rebuildable cache produced by `cancelAll()` + rebuild, not a durable fact — a stored OS id would be a second source of truth that goes stale on every reconcile. The id handed to `flutter_local_notifications` is derived from `reminders.id` at projection time. `kind` is a closed CHECK because each value maps to an Android channel id frozen at release.

### 5.11 Notes and media

```dart
@TableIndex(name: 'idx_note_ewe', columns: {#ewe})
@TableIndex(name: 'idx_note_lamb', columns: {#lamb})
@TableIndex(name: 'idx_note_lambing', columns: {#lambing})
@TableIndex(name: 'idx_note_season', columns: {#season})
class Notes extends Table with Identified {
  late final ewe =
      integer().nullable().references(Ewes, #id, onDelete: KeyAction.cascade)();
  late final lamb =
      integer().nullable().references(Lambs, #id, onDelete: KeyAction.cascade)();
  late final lambing =
      integer().nullable().references(Lambings, #id, onDelete: KeyAction.cascade)();
  late final season =
      integer().nullable().references(Seasons, #id, onDelete: KeyAction.cascade)();

  late final body = text()();

  // The §12.5 provenance quad (R37). `occurred_at` is WHEN THE THING
  // HAPPENED and is distinct from the mixin's `created_at`, which is when the
  // row was written: a note typed at 06:00 about 03:20 has two different
  // instants and the timeline sorts on the first.
  late final occurredAt = integer().map(const InstantConverter())();
  late final capturedAt = integer().map(const InstantConverter())();
  late final originalEffective =
      integer().map(const InstantConverter()).nullable()();
  late final timeSource = text().withDefault(const Constant('auto'))();

  @override
  List<String> get customConstraints => [
        'CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) + (lambing IS NOT NULL)'
            ' + (season IS NOT NULL) >= 1)',
        'CHECK (length(trim(body)) > 0)',
        'CHECK (occurred_at BETWEEN 946684800000 AND 4102444800000)',
        'CHECK (captured_at BETWEEN 946684800000 AND 4102444800000)',
        "CHECK (time_source IN ('auto','entered','edited'))",
        "CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))",
      ];

  @override
  bool get isStrict => true;
}

@TableIndex(name: 'idx_media_ewe', columns: {#ewe})
@TableIndex(name: 'idx_media_lamb', columns: {#lamb})
@TableIndex(name: 'idx_media_lambing', columns: {#lambing})
@TableIndex(name: 'idx_media_note', columns: {#note})
class MediaAssets extends Table with Identified {
  /// RELATIVE to the media root, e.g. "2026/03/019524f7-….jpg".
  /// The iOS container UUID is not stable across launches, so an absolute
  /// path 404s after every restore, update and re-install — and never
  /// reproduces on the developer's Android phone.
  late final relativePath = text()();
  late final kind = text()();
  late final byteSize = integer()();
  late final durationMs = integer().nullable()();
  late final sha256 = text().nullable()();

  late final ewe =
      integer().nullable().references(Ewes, #id, onDelete: KeyAction.cascade)();
  late final lamb =
      integer().nullable().references(Lambs, #id, onDelete: KeyAction.cascade)();
  late final lambing =
      integer().nullable().references(Lambings, #id, onDelete: KeyAction.cascade)();
  late final note =
      integer().nullable().references(Notes, #id, onDelete: KeyAction.cascade)();

  /// Set when a sweep finds the file gone. The row is NEVER deleted:
  /// "photo taken 14 March, file missing" is more honest than silence.
  late final missingSince = integer().map(const InstantConverter()).nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{relativePath}];

  @override
  List<String> get customConstraints => [
        "CHECK (kind IN ('photo','voice'))",
        'CHECK (byte_size >= 0)',
        // All three, and they must be here before the v1 snapshot (R62): a
        // CHECK cannot be added by ALTER TABLE afterwards without a full
        // rebuild of the one table that points at the user's photographs.
        // Never absolute; always YYYY/MM/<file>; never deeper than that.
        "CHECK (relative_path NOT LIKE '/%')",
        "CHECK (relative_path GLOB '[0-9][0-9][0-9][0-9]/[0-9][0-9]/*.*')",
        "CHECK (relative_path NOT GLOB '*/*/*/*')",
        'CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) + (lambing IS NOT NULL)'
            ' + (note IS NOT NULL) = 1)',
      ];

  @override
  bool get isStrict => true;
}
```

Media layout, sweeps and the trash folder are in [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md).

### 5.12 Vocabulary and terminology

```dart
@TableIndex(name: 'idx_vocab_list', columns: {#list, #sortOrder})
class VocabTerms extends Table with Identified {
  late final list = text()();

  /// Globally unique, list-prefixed, ASCII, stable forever. This is what
  /// goes in the DB, the CSV and the JSON. It is never translated and
  /// never edited. FKs point at it, which is why it is UNIQUE on its own.
  late final key = text().unique()();

  /// The user's override. NULL means "use the shipped en-GB default for
  /// this key". A locale change or an app update therefore cannot overwrite
  /// a user's wording, and the data layer never touches AppLocalizations.
  late final label = text().nullable()();

  late final sortOrder = integer()();
  late final origin = text()();

  /// Hidden, never deleted — a term in use is referenced by an FK.
  late final hiddenAt = integer().map(const InstantConverter()).nullable()();

  @override
  List<String> get customConstraints => [
        "CHECK (list IN ('death_cause','malpresentation','treatment_route',"
            "'ewe_observation','lambing_ease','foster_method'))",
        "CHECK (origin IN ('seeded','user'))",
        // A user-added term has no shipped default, so it MUST carry a label.
        "CHECK (origin = 'seeded' OR label IS NOT NULL)",
        'CHECK (length(trim(key)) > 0)',
      ];

  @override
  bool get isStrict => true;
}

/// "ewe / gimmer / shearling / theave / hogget" — spec §7.10. A closed
/// AnimalClass enum lives in the domain; this table is the overlay.
class TerminologyOverrides extends Table {
  late final key = text()();
  late final singular = text()();
  late final plural = text()();

  @override
  Set<Column> get primaryKey => {key};

  @override
  bool get isStrict => true;
}
```

### 5.13 Settings, entitlement, and the two caches

```dart
/// The only table exempt from convention 3's hand-indexed-FK rule: one row,
/// so an index on `current_season` costs more than the scan it replaces.
/// It is exempt BY NAME in `test/data/every_fk_is_indexed_test.dart`.
///
/// There is deliberately no locale, date-format or first-day-of-week column.
/// §7.0 ruling 3 (UK/Ireland first: en_GB, 24-hour, dd/MM/yyyy, week starts
/// Monday) is delivered by `flutter_localizations` and the `supportedLocales`
/// ordering in decision #108, not by a settings row — a stored copy would go
/// stale the moment the user changes their phone's region.
@DataClassName('AppSetting')
class AppSettings extends Table {
  late final id = integer().withDefault(const Constant(1))();

  /// Keys are `WeightUnit`'s, byte-identical (R68):
  /// `enum WeightUnit { kg('kg'), lb('lb') }` in
  /// `lib/domain/units/weight_unit.dart`.
  late final weightUnit = text().withDefault(const Constant('kg'))();
  // No temperature_unit. Ruled 2026-08-01 (decision-record §7.0 row 11): no v1
  // table stores a temperature, so the setting is a 3am tax on a screen that
  // has to stay small. MilliCelsius still ships; the column does not. If a
  // temperature column ever lands, this column comes back with it as an
  // additive migration, which is what forward-only allows.
  /// Stored keys are byte-identical to `ShedPaletteId`'s keys (R35):
  /// `night` · `amber` · `red`. There is no `dark` key — the palette that
  /// used to be called that is `night`, and the enum and the column must
  /// spell it the same way.
  late final palette = text().withDefault(const Constant('night'))();
  late final highContrast = boolean().withDefault(const Constant(false))();
  late final wakelockEnabled = boolean().withDefault(const Constant(false))();

  /// Mirrors the primary action column for a left-handed shepherd (R40).
  /// A layout preference, never a capability switch.
  late final leftHanded = boolean().withDefault(const Constant(false))();

  late final currentSeason =
      integer().nullable().references(Seasons, #id, onDelete: KeyAction.setNull)();
  late final percentageDefinition =
      text().withDefault(const Constant('born_alive_per_ewe_to_ram'))();

  /// A DISPLAY threshold the user sets, never a recommendation. It decides
  /// when the pen tile shows its "ready to turn out" badge and nothing else:
  /// it is not in any export, any CSV, any PDF, and no other column is
  /// derived from it. Convention 5's ban is on defaults that answer a
  /// veterinary question on the user's behalf; "how long before you nudge
  /// me" is not one, and a blank threshold would mean no badge ever.
  late final turnOutThresholdHours = integer().withDefault(const Constant(24))();

  /// The oestrus-cycle length used only to zero-fill the lambing-spread
  /// histogram's "first 17 days" bucket (decision #59). Same rule: display
  /// arithmetic, never advice.
  late final cycleDays = integer().withDefault(const Constant(17))();

  /// Written by `ReminderReconciler.reconcile()` in the same transaction that
  /// records the OS projection (R40). Nullable: "never reconciled" is a real
  /// state, and it is what the honest reminder line on the Reminders screen
  /// reads. NOT a cache of the projection itself.
  late final lastReconcileScheduled =
      integer().map(const InstantConverter()).nullable()();

  // Decision #72: the end-of-day export banner.
  late final lastExportedAt = integer().map(const InstantConverter()).nullable()();
  late final lastExportPromptedAt = integer().map(const InstantConverter()).nullable()();
  late final exportPromptDismissedForSeason =
      integer().nullable().references(Seasons, #id, onDelete: KeyAction.setNull)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'CHECK (id = 1)',
        "CHECK (weight_unit IN ('kg','lb'))",
        // No 'light'. Spec §5: dark is the default, not an option.
        "CHECK (palette IN ('night','amber','red'))",
        "CHECK (percentage_definition IN ("
            "'born_alive_per_ewe_to_ram','born_incl_stillborn_per_ewe_to_ram',"
            "'born_alive_per_ewe_lambed','reared_per_ewe_to_ram'))",
        'CHECK (turn_out_threshold_hours BETWEEN 1 AND 336)',
        'CHECK (cycle_days BETWEEN 1 AND 60)',
      ];

  @override
  bool get isStrict => true;
}

/// Decision #88. Written once, never revoked by the app. EXCLUDED from the
/// JSON backup and IGNORED on import — restoring your neighbour's backup must
/// not unlock your app. Never in shared_preferences.
class Entitlements extends Table {
  late final id = integer().withDefault(const Constant(1))();
  late final unlocked = boolean().withDefault(const Constant(false))();
  late final unlockedAt = integer().map(const InstantConverter()).nullable()();
  late final purchaseInFlightAt = integer().map(const InstantConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
  @override
  List<String> get customConstraints => ['CHECK (id = 1)'];
  @override
  bool get isStrict => true;
}

/// Recents strip (decision #68). "Touched" includes looking at a ewe card
/// without writing anything, so it is an observation and is not derivable.
/// One row per ewe, upserted: a UI cache, not a record. The history-table rule
/// applies to facts, and "she was looked at twice" is not one.
@DataClassName('EweTouch')   // default would be `EweTouche`
class EweTouches extends Table {
  late final ewe = integer().references(Ewes, #id, onDelete: KeyAction.cascade)();
  late final touchedAt = integer().map(const InstantConverter())();

  @override
  Set<Column> get primaryKey => {ewe};
  @override
  bool get isStrict => true;
}

/// The §7.7 one-line summary, precomputed so the first thing on the ewe card
/// never waits for an aggregate. A CACHE: rebuildable, excluded from the
/// backup, rebuilt wholesale after a restore.
@DataClassName('EweSummary')   // default would be `EweSummarie`
@TableIndex(name: 'idx_ewesummary_lastobs', columns: {#lastObservationSeason})
class EweSummaries extends Table {
  late final ewe = integer().references(Ewes, #id, onDelete: KeyAction.cascade)();
  late final seasonsRecorded = integer()();
  late final lambingsRecorded = integer()();
  late final lambsBorn = integer()();
  late final lambsBornAlive = integer()();
  late final assistedLambings = integer()();
  late final scoredLambings = integer()();

  /// A real FK, not a loose integer. "prolapsed 2025" is rendered from the
  /// season this points at; a dangling id would render a blank year on the
  /// one line the retention feature is built on. Cache or not, convention 2
  /// has no exceptions.
  late final lastObservationSeason =
      integer().nullable().references(Seasons, #id, onDelete: KeyAction.setNull)();

  late final rebuiltAt = integer().map(const InstantConverter())();

  @override
  Set<Column> get primaryKey => {ewe};
  @override
  bool get isStrict => true;
}
```

**`ewe_summaries` stores counts only — never a percentage, never a formatted string.** The sentence "3 seasons · avg 2.0 · assisted twice · prolapsed 2025" is assembled in Dart from these counts with the terminology overlay and the locale applied, because a formatted string in the database would freeze both. `assistedLambings` and `scoredLambings` are stored as a pair so the assisted rate can exclude unscored lambings from *both* sides and report coverage (decision #59).

### 5.14 Who writes what

Repository methods are event verbs, never `save(aggregate)`. One repository owns writes to each table; nothing else may `insert`/`update` it.

| Repository | Owns writes to |
|---|---|
| `SeasonRepository` | `seasons`, `ewe_seasons`, `app_settings.current_season`. Also owns the season-summary **reads** — `watchSeasonCounts` and `watchSpread` are its methods; there is no `SeasonStatsRepository` (R18). |
| `FlockRepository` | `ewes`, `ewe_touches` |
| `LambingRepository` | `lambings`, `lambs`, `care_events`, `ewe_observations`, `ewe_summaries` |
| `FosterRepository` | `foster_events` |
| `PenRepository` | `pens`, `pen_occupancies`, `pen_occupancy_lambs` |
| `TreatmentRepository` | `treatments`, `treatment_withdrawals` |
| `ReminderRepository` | `reminders`, `reminder_rules` |
| `NoteRepository` | `notes`, `media_assets` |
| `SettingsRepository` | `app_settings`, `vocab_terms`, `terminology_overrides` |
| `EntitlementRepository` | `entitlements` |
| `ExportRepository` | nothing — read + artifact assembly only (R19) |
| *(nobody — SQL triggers)* | `search_docs`, `search_fts`. The one exception is `SeasonRepository`, which runs `sweepSearchDocs` + `rebuild` inside the season-delete transaction (§9.2). No other Dart code may write either table. |
| `RestoreService` | all of them, once, into a **new** file (doc 04) |

Twelve entries, and the set is closed (R19): a thirteenth repository is a schema-review conversation, not an edit.

**Every mutation is exactly one `db.transaction`, and no `await` inside it waits on a human.** The Lambing Entry screen writes the lambing row on the *first* tap and each subsequent field is its own small `UPDATE` transaction: there is no Save button because a Save button is a draft, and spec §5 says there is no draft state to lose. Nothing side-effecting goes inside a transaction either — no notification call, no file write, no share sheet (doc 01 §4.3).

> **Needs verification (week one), because a plausible claim was written here from memory and removed:** whether drift 2.34.2 opens `transaction()` with `BEGIN` or `BEGIN IMMEDIATE`. It matters only for the deferred-to-write upgrade case, which needs two concurrent writers, which this app does not have — one connection, one writer layer (§1.3). Read it off `PRAGMA` + a statement log once and record the answer here. If it is a deferred `BEGIN`, the `busy_timeout = 5000` set in `configureConnection` is what covers the `VACUUM INTO` overlap, and nothing else changes.

---

## 6. Tag uniqueness — settled

**Ruling (decision-record §7.0 #7): tags are unique among ACTIVE animals only.** A partial unique index, not a global one. Real flocks reuse tag numbers after culls.

```sql
CREATE UNIQUE INDEX idx_ewe_tag_active  ON ewes  (tag) WHERE status = 'active';
CREATE UNIQUE INDEX idx_lamb_tag_alive  ON lambs (tag) WHERE tag IS NOT NULL AND status = 'alive';
```

Follow it through:

1. **Uniqueness is on `tag` as typed, not on `tag_digits`.** Making `tag_digits` unique would refuse `0412` because `412` exists, which is the app deciding two tags are the same animal. `tag_digits` ranks matches; it never decides identity.
2. **Create-on-the-fly matches active animals only.** Typing `412` when the only 412 is culled produces **zero matches**, so the "Create 412" action appears and one tap creates a new ewe with a new `uid`. No dialog, no disambiguation, nothing between the shepherd and the entry. This is the whole reason the ruling matters: it moves the "412 — culled 2025 — use anyway?" prompt *off* the 03:20 path, which spec §7.1 and the bottom-sheet rules both demand.
3. **The ewe card surfaces the history, later, in daylight.** The new 412's card shows a quiet row — *"An earlier animal also used tag 412 (culled March 2025). View her record."* — fed by:

   ```sql
   -- lib/core/db/queries.drift
   earlierAnimalsWithTag(:tag AS TEXT, :excludeId AS INT):
   SELECT e.id, e.uid, e.tag, e.status, e.updated_at
   FROM ewes e
   WHERE e.tag = :tag AND e.id <> :excludeId
   ORDER BY e.updated_at DESC;
   ```

   It is a link, never a merge offer. The two animals are two animals.
4. **Culling is what releases a tag.** `UPDATE ewes SET status = 'culled'` drops the row out of the partial index in the same statement. Nothing else needs to happen.
5. **Cross-table collisions are deliberately not enforced, and that survives lamb→ewe promotion.** A lamb tagged `412` and an active ewe tagged `412` can coexist, because they are different tables. Decision-record §7.0 row 13 ruled on 2026-08-01 that a retained lamb **does** become a `Ewe` row, via `lambs.became_ewe`, so the old wording — *"v1 has no lamb→ewe promotion"* — is no longer the reason. The reason now is that **promotion writes a `ewes` row through the same create-on-the-fly path every other ewe uses**, so the tag it takes is checked against the partial unique index on active ewes exactly like any other, and the lamb row keeps the tag it was born with because it is a record of a birth that happened. The two rows are two animals with one `became_ewe` link between them, which is precisely what point 3's link-never-merge rule already describes. **Do not add a cross-table trigger to paper over it** — that instruction is unchanged and is now permanent rather than provisional.

**The test that pins the behaviour** — `test/data/tag_uniqueness_test.dart`:

```dart
test('a culled ewe releases her tag, and the new ewe is a new animal', () async {
  // createEwe returns a WriteOutcome and never an id — only beginLambing and
  // addLamb mint an id and throw (CONVENTIONS §2.13, R32). The single call
  // site that reads `insertedId` is the one that wraps it in an EweId (R33).
  final first = await flock.createEwe(tag: '412', context: EntryContext.calm)
      as WriteCommitted;
  final oldId = EweId(first.insertedId!);
  await flock.setStatus(oldId, EweStatus.culled);

  // The index permits it; create-on-the-fly does not prompt.
  expect(await flock.matchActive('412'), isEmpty);
  final second = await flock.createEwe(tag: '412', context: EntryContext.calm)
      as WriteCommitted;
  final newId = EweId(second.insertedId!);

  expect(newId, isNot(oldId));
  final rows = await db.select(db.ewes).get();
  expect(rows.map((e) => e.uid).toSet(), hasLength(2));

  // And the card can still find the earlier one.
  expect(await flock.earlierAnimalsWithTag('412', excluding: newId), hasLength(1));
});

test('two ACTIVE ewes cannot share a tag', () async {
  await flock.createEwe(tag: '412', context: EntryContext.calm);
  // Asserted against the DATABASE, not through the repository: the repository
  // maps SqliteException to WriteFailed through shedFailureFrom, so a
  // repository-level assertion would also pass on a schema with no index.
  // expectLater + await, never a bare expect() on a Future: an unawaited
  // throwsA leaks the failure into the next test as an unhandled async error.
  await expectLater(
    db.into(db.ewes).insert(EwesCompanion.insert(
          uid: newUid(), tag: '412', tagDigits: '412',
          createdAt: appNow(), updatedAt: appNow(),
        )),
    throwsA(isA<SqliteException>()),
  );
});
```

The second test asserting on the *database* rather than on a Dart guard is the point: the constraint is in the file, so it survives a bulk restore and any code path written in 2029.

---

## 7. Fostering

**Birth is a fact. Rearing is a history.**

`lambs.birth_dam` is an immutable column, enforced in SQL:

```sql
-- lib/core/db/views.drift
CREATE TRIGGER lamb_birth_dam_is_immutable
BEFORE UPDATE OF birth_dam ON lambs
WHEN old.birth_dam IS NOT new.birth_dam
BEGIN
  SELECT RAISE(ABORT, 'birth_dam is immutable; record a foster instead');
END;
```

There is **no `rearing_dam` column**. The decision record rejects it explicitly (#33): a denormalised current-rearing-dam column is a dual write that a future code path will get wrong, producing a lamb whose history says "fostered to 128" while the list screen says "412". Spec §7.3's "birth dam and rearing dam as separate fields" is satisfied at the *domain* level by `LambDams(birthDamId, rearingDamId)`, whose rearing side is projected from the log.

```dart
@TableIndex(name: 'idx_foster_lamb_time', columns: {#lamb, #effectiveAt})
@TableIndex(name: 'idx_foster_rearingdam', columns: {#rearingDam})
@TableIndex(name: 'idx_foster_season', columns: {#season})
@TableIndex(name: 'idx_foster_corrects', columns: {#corrects})
@TableIndex(name: 'idx_foster_method', columns: {#method})
class FosterEvents extends Table with Identified {
  late final lamb = integer().references(Lambs, #id, onDelete: KeyAction.cascade)();
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();

  /// NULL when the lamb leaves a rearing dam without gaining a new one.
  late final rearingDam =
      integer().nullable().references(Ewes, #id, onDelete: KeyAction.restrict)();

  /// 'to_ewe' | 'to_bottle' | 'removed_unknown' — the three stored keys of
  /// `sealed class FosterOutcome { ToEwe(EweId) | ToBottle() | RemovedUnknown() }`
  /// in `lib/domain/foster_outcome.dart` (R64). bottle (null by intent) and
  /// unknown (null by omission) are different facts and the rearing-credit
  /// numbers differ. Do not merge them — which is also why
  /// `setRearingDam(lambId, eweId?)` is a banned signature.
  late final outcome = text()();

  /// Decision #69: undo for a foster is a COMPENSATING event pointing at the
  /// one it reverses, visible in history. The log is append-only; nothing is
  /// ever deleted from it.
  late final corrects =
      integer().nullable().references(FosterEvents, #id, onDelete: KeyAction.restrict)();

  /// The event time. The third documented exception to the `occurred_at`
  /// column-name rule (R37): a graft is dated by when it took effect.
  late final effectiveAt = integer().map(const InstantConverter())();

  // The rest of the §12.5 provenance quad (R37).
  late final capturedAt = integer().map(const InstantConverter())();
  late final originalEffective =
      integer().map(const InstantConverter()).nullable()();
  late final timeSource = text().withDefault(const Constant('auto'))();

  late final method =
      text().nullable().references(VocabTerms, #key, onDelete: KeyAction.restrict)();
  late final note = text().nullable()();

  @override
  List<String> get customConstraints => [
        "CHECK (outcome IN ('to_ewe','to_bottle','removed_unknown'))",
        "CHECK ((outcome = 'to_ewe') = (rearing_dam IS NOT NULL))",
        'CHECK (effective_at BETWEEN 946684800000 AND 4102444800000)',
        'CHECK (captured_at BETWEEN 946684800000 AND 4102444800000)',
        "CHECK (time_source IN ('auto','entered','edited'))",
        "CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))",
      ];

  @override
  bool get isStrict => true;
}
```

Current rearing dam, derived:

```sql
CREATE VIEW lamb_rearing AS
SELECT
  lb.id        AS lamb_id,
  lb.birth_dam AS birth_dam,
  COALESCE(
    (SELECT fe.rearing_dam
       FROM foster_events fe
      WHERE fe.lamb = lb.id
      ORDER BY fe.effective_at DESC, fe.id DESC
      LIMIT 1),
    -- No foster event: she is rearing what she bore. That is a fact at
    -- birth, not a guess.
    CASE WHEN EXISTS (SELECT 1 FROM foster_events fe2 WHERE fe2.lamb = lb.id)
         THEN NULL ELSE lb.birth_dam END
  ) AS rearing_dam,
  EXISTS (SELECT 1 FROM foster_events fe3 WHERE fe3.lamb = lb.id) AS was_fostered
FROM lambs lb;
```

**The invariant that keeps the birth ewe's litter size honest.** Every *born* count aggregates `lambs` by `birth_dam`. Every *reared* count aggregates the **same rows** by `lamb_rearing.rearing_dam`. The two are never mixed in one query, so a lamb cannot appear twice in either:

```sql
-- born: never changes when a lamb moves
SELECT birth_dam AS ewe, COUNT(*) AS born FROM lambs GROUP BY birth_dam;

-- reared: changes freely, and excludes bottle lambs, which belong to no ewe
SELECT rearing_dam AS ewe, COUNT(*) AS reared
FROM lamb_rearing WHERE rearing_dam IS NOT NULL GROUP BY rearing_dam;
```

This matches the established industry model: a grafted lamb keeps its **birth type** and gains a new **rear type**; the biological dam gets credit for having the lamb and not for raising it. `lambings.declared_birth_type` is a property of the lambing event and fostering must never touch it — a plausible implementation of "move a lamb" recomputes the litter, and that is the bug.

**The conservation test** — `test/data/fostering_conservation_test.dart`:

```dart
test('total lambs is invariant under any sequence of fosters', () async {
  final total = await repo.countLambs();
  for (final move in randomFosterSequence(seed: 42, moves: 200)) {
    await foster.apply(move);
  }
  expect(await repo.countLambs(), total);
  expect((await repo.bornCountsByDam()).values.fold(0, (a, b) => a + b), total);
});

test('the birth dam cannot be updated', () async {
  await expectLater(
    db.customStatement('UPDATE lambs SET birth_dam = ? WHERE id = ?', [otherEwe, lambId]),
    throwsA(isA<SqliteException>()),
  );
});
```

**Not blocked, only warned:** fostering onto a ewe who has not lambed (a real practice with a ewe who lost her own lambs — and spec §7.1 forbids making the user go and record her lambing first), and fostering more lambs onto a ewe than she has teats.

---

## 8. Pen occupancy, the live board and hours-since-penned

The partial unique index (§5.9) is the mechanism; these two queries are the whole Pen Board and the Quick Entry "in the pens" list.

```sql
-- lib/core/db/queries.drift

-- The Pen Board. One statement, one watch() stream, one screen.
penBoard:
SELECT
  p.id            AS pen_id,
  p.label         AS pen_label,
  p.sort_order    AS sort_order,
  o.id            AS occupancy_id,
  o.ewe           AS ewe_id,
  e.tag           AS ewe_tag,
  o.entered_at    AS entered_at,
  (SELECT COUNT(*) FROM pen_occupancy_lambs pol WHERE pol.occupancy = o.id) AS lamb_count
FROM pens p
LEFT JOIN pen_occupancies o ON o.pen = p.id AND o.exited_at IS NULL
LEFT JOIN ewes e            ON e.id = o.ewe
WHERE p.is_active = 1
ORDER BY p.sort_order, p.label;

-- Decision #67: the same projection, ordered by entered_at ASCENDING, ewes
-- only. The ewe penned longest is the one most likely to need turning out
-- and the one you are most likely standing next to. Lambs are one tap away.
inThePens:
SELECT o.id AS occupancy_id, o.ewe AS ewe_id, e.tag AS ewe_tag,
       o.entered_at AS entered_at, p.label AS pen_label
FROM pen_occupancies o
JOIN pens p ON p.id = o.pen
JOIN ewes e ON e.id = o.ewe
WHERE o.exited_at IS NULL AND o.ewe IS NOT NULL
ORDER BY o.entered_at ASC;
```

**Hours since penned is never stored and never computed in SQL.**

```dart
// lib/domain/penning.dart — pure, and it takes `now` rather than reading a
// clock: `package:clock` is banned in lib/domain/ (layer rule 1, R24).
// The caller passes appNow(), or the value the minute ticker just yielded.
Duration timeSincePenned(Instant enteredAt, Instant now) =>
    now.difference(enteredAt);
```

`sincePenned` is a banned name.

Three rules that follow:

1. **It is elapsed physical time, computed from epoch millis**, so it is correct across a DST transition. A ewe penned at 22:00 on the Saturday before UK spring-forward and seen at 08:00 Sunday has been penned **9 hours**, not the 10 the wall clock suggests. The UK/Ireland ambiguous hour is 01:00–01:59; that is the hour the regression test targets.
2. **One app-level, boundary-aligned ticker at 60 s** drives the recompute (decision #66) — `minuteTickProvider`, `StreamProvider.autoDispose<Instant>`, in `lib/core/time/ticker.dart`, and it is the only ticker in the app. Not a `Timer.periodic` per row — that is 30 timers and measurable overnight battery — and not 30 s, because the display granularity is hours. Cells updating at different moments read as noise under a head torch.
3. **The "ready to turn out" badge compares against `app_settings.turn_out_threshold_hours`** — through `isReadyToTurnOut(...)` in `lib/domain/penning.dart`, which takes the threshold as an argument and holds no opinion about it — and carries icon + text + position as well as colour (decision #106).

**Turning out is one transaction:** `UPDATE pen_occupancies SET exited_at = ?, exit_reason = 'turned_out' WHERE id = ?`. The row stays forever. That is the answer to "the whiteboard gets wiped".

---

## 9. Search — two different problems

### 9.1 Partial tag matching is not a search problem

The spec's own example — typing `12` surfaces 412, 128, 12 — is an **infix** match on a **2-character** query, and it is FTS5's documented counter-example: *"substrings consisting of fewer than 3 unicode characters do not match any rows"*. `LIKE '%12%'` works but cannot use an index.

At 400 ewes, none of that matters. **Hold the tags in memory and rank in Dart.**

```dart
// lib/domain/tag_match.dart — pure, synchronous, and it holds TagIndexEntry
// too (R27). NOT a feature folder: the Flock search box and the Foster screen
// both call it, and layer rule 6 forbids one feature importing another, so a
// feature-folder placement is not merely inconsistent — it is unbuildable.
// Catalogued in CONVENTIONS.md §2.14 and owned by 05-domain-correctness.md
// (§1.1 assigns it tag_match.dart, R27); the ranking below is this document's
// contribution to it.
/// Fed by `tagIndexProvider`, a drift watch() over the ewes table filtered to
/// ACTIVE animals (§6). ~400 entries × ~40 bytes ≈ 16 KB.
List<TagIndexEntry> rankTagMatches(List<TagIndexEntry> all, String query) {
  final q = query.replaceAll(RegExp(r'\D'), '');
  if (q.isEmpty) return const [];

  int score(TagIndexEntry e) {
    final d = e.digits;
    if (d == q) return 0;            // exact
    if (d.startsWith(q)) return 1;   // prefix
    if (d.endsWith(q)) return 2;     // suffix
    if (d.contains(q)) return 3;     // infix
    return 99;
  }

  return [for (final e in all) if (score(e) < 99) e]..sort((a, b) {
      final s = score(a).compareTo(score(b));
      if (s != 0) return s;
      final ra = a.lastTouched, rb = b.lastTouched;   // then most-recently-touched
      if (ra != null && rb != null) return rb.compareTo(ra);
      if (ra != null) return -1;
      if (rb != null) return 1;
      return a.digits.length.compareTo(b.digits.length);
    });
}
```

Why in-memory beats even an adequate `LIKE` query: it is **synchronous**, so every keypad tap re-filters inside the same frame, with no `await` and no frame where the list is empty. A SQL round-trip through drift's background isolate lands one or two frames late. It also gives ranking for free, and ranking is the actual UX problem — a raw `LIKE` returns `128` before `12` in rowid order.

**Banned on the keypad path:** FTS5, the trigram tokenizer, `LIKE`, and any debounce. The 200 ms debounce belongs to note search and nowhere else. `tag_digits` stays in the schema because it makes `WHERE tag_digits LIKE ?` trivially available to export and report code, and it costs nothing.

### 9.2 Full-text note search is FTS5 over one fan-in table

One MATCH, one `bm25()` ordering, one `snippet()`. FTS5 cannot be declared in Dart, so it lives in `lib/core/db/search.drift`.

```sql
CREATE TABLE search_docs (
  id           INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  subject_kind TEXT    NOT NULL,
  subject_id   INTEGER NOT NULL,
  ewe_id       INTEGER,
  season_id    INTEGER,
  title        TEXT    NOT NULL,
  body         TEXT    NOT NULL,
  occurred_at  INTEGER NOT NULL,
  UNIQUE (subject_kind, subject_id)
) STRICT;

CREATE VIRTUAL TABLE search_fts USING fts5(
  title,
  body,
  content='search_docs',
  content_rowid='id',
  tokenize='porter unicode61 remove_diacritics 2',
  prefix='2 3'
);

-- The three sqlite.org external-content sync triggers.
CREATE TRIGGER search_docs_ai AFTER INSERT ON search_docs BEGIN
  INSERT INTO search_fts(rowid, title, body) VALUES (new.id, new.title, new.body);
END;
CREATE TRIGGER search_docs_ad AFTER DELETE ON search_docs BEGIN
  INSERT INTO search_fts(search_fts, rowid, title, body)
  VALUES ('delete', old.id, old.title, old.body);
END;
CREATE TRIGGER search_docs_au AFTER UPDATE ON search_docs BEGIN
  INSERT INTO search_fts(search_fts, rowid, title, body)
  VALUES ('delete', old.id, old.title, old.body);
  INSERT INTO search_fts(rowid, title, body) VALUES (new.id, new.title, new.body);
END;
```

The index stays in sync through **SQL triggers on the source tables**, not Dart:

```sql
CREATE TRIGGER notes_search_ai AFTER INSERT ON notes BEGIN
  INSERT INTO search_docs (subject_kind, subject_id, ewe_id, season_id,
                           title, body, occurred_at)
  -- new.occurred_at, NOT new.created_at: the timeline sorts on when the
  -- thing happened, not on when the row was written (§4.2, R37).
  VALUES ('note', new.id, new.ewe, new.season, 'note',
          COALESCE(new.body, ''), new.occurred_at);
END;
CREATE TRIGGER notes_search_au AFTER UPDATE OF body ON notes BEGIN
  UPDATE search_docs SET body = COALESCE(new.body, '')
   WHERE subject_kind = 'note' AND subject_id = new.id;
END;
CREATE TRIGGER notes_search_ad AFTER DELETE ON notes BEGIN
  DELETE FROM search_docs WHERE subject_kind = 'note' AND subject_id = old.id;
END;
```

| `subject_kind` | `title` | `body` |
|---|---|---|
| `ewe` | the tag | `ewes.notes` |
| `lambing` | tag + local date | `note` + `presentation_note` + `assisted_by` |
| `lamb` | the tag or `''` | `lambs.notes` |
| `treatment` | `product_name` | `dose_text` + `batch_no` + `note` |
| `note` | `'note'` | `notes.body` |

The other four trigger trios have exactly this shape, plus one rule that is not optional: **`search_docs.title` and `search_docs.body` are `NOT NULL` and every source column in that table is nullable**, so every value a trigger writes is wrapped in `COALESCE(…, '')` and the multi-column bodies are `COALESCE(a,'') || ' ' || COALESCE(b,'')`. Miss it once and creating a ewe with no notes aborts the insert with a `NOT NULL` failure — at 03:20, on the create-on-the-fly path, from a trigger nobody was looking at.

**The decisive argument for triggers over repository code is restore:** a restore bulk-inserts thousands of rows through whatever path is fastest, and that is precisely where a Dart-side "also update the index" call gets skipped and the user's five seasons come back unsearchable. `search_docs` is therefore excluded from the JSON backup and repopulates itself.

**But "a trigger cannot be skipped" is not quite true, and the exception is the one destructive flow this app has.** Rows removed by an `ON DELETE CASCADE` do not reliably fire the child table's `AFTER DELETE` trigger unless `PRAGMA recursive_triggers` is on — which is why `configureConnection` sets it (§1.3). Two consequences, and both are required:

1. **The pragma is per-connection.** If it is ever missed, deleting a season silently leaves `search_docs` rows for notes that no longer exist, and `search_fts` — an external-content index — starts returning rows whose content is gone.
2. **The season-delete path does not rely on the pragma at all.** In the same transaction as the delete, after it, it runs the orphan sweep and then rebuilds, so the index is correct whichever way the pragma question resolves:

```sql
-- lib/core/db/queries.drift — both run by SeasonRepository, in that order,
-- inside the season-delete transaction.
sweepSearchDocs:
DELETE FROM search_docs
 WHERE (subject_kind = 'note'      AND subject_id NOT IN (SELECT id FROM notes))
    OR (subject_kind = 'ewe'       AND subject_id NOT IN (SELECT id FROM ewes))
    OR (subject_kind = 'lamb'      AND subject_id NOT IN (SELECT id FROM lambs))
    OR (subject_kind = 'lambing'   AND subject_id NOT IN (SELECT id FROM lambings))
    OR (subject_kind = 'treatment' AND subject_id NOT IN (SELECT id FROM treatments));

rebuildSearchIndex:
INSERT INTO search_fts(search_fts) VALUES('rebuild');
```

> **Needs verification (week one), and it is a five-minute test:** insert a note, delete its season, and assert `search_docs` is empty and `INSERT INTO search_fts(search_fts) VALUES('integrity-check')` does not throw — once with `recursive_triggers` on and once with it off. Record which behaviour the bundled SQLite actually has. The sweep above makes the app correct either way; the answer decides only whether the pragma stays load-bearing or becomes belt-and-braces.

Query the index from `search.drift`; never build FTS5 syntax by string concatenation without tokenising first, because a note containing the word `OR` is an FTS5 operator and throws a syntax error at 3am:

```sql
searchAll(:query AS TEXT, :limit AS INT):
SELECT d.subject_kind, d.subject_id, d.ewe_id, d.title,
       snippet(f, 1, '[', ']', '…', 12) AS excerpt,
       bm25(f, 2.0, 1.0)                AS rank_score
FROM search_fts f
JOIN search_docs d ON d.id = f.rowid
WHERE f MATCH :query
ORDER BY rank_score
LIMIT :limit;
```

**Two spelling traps in those eight lines, both of which fail at runtime rather than at codegen:**

1. **Once the virtual table is aliased, only the alias is in scope.** `WHERE search_fts MATCH …`, `snippet(search_fts, …)` and `bm25(search_fts, …)` alongside `FROM search_fts f` all fail with *no such column: search_fts*. Use `f` in all three places, or drop the alias and use the table name in all three. Never mix.
2. **`rank` is FTS5's own auto-generated column**, so `… AS rank` shadows it and `ORDER BY rank` becomes ambiguous to a reader even though SQLite resolves the output alias. The result column is called `rank_score` for that reason alone.

`bm25()` returns a negative score where smaller is better, so ascending `ORDER BY rank_score` is correct. Weighting `title` at 2.0 puts a ewe's own records above a passing mention in someone else's note.

> **Two things to prototype in week one, before the schema is frozen.** Both are unverified and both change the design if they fail.
> 1. **drift#3322 is open:** drift's SQL analyser does not fully model FTS5's special INSERT commands (`INSERT INTO t(t) VALUES('delete')`, `VALUES('rebuild')`). If drift refuses to generate for `search_docs_ad`/`_au` or for `rebuildSearchIndex`, there are exactly two ways out and you take one of them, not a third.
>    **Fallback A — keep external content, hide the statements from the analyser:** move the two triggers and the rebuild out of `search.drift` and into a `customStatement` in `onCreate` and in `SeasonRepository`, where drift never parses them. Keeps the index storage-free; costs the type-safe query API and puts raw SQL in `lib/core/db/`, which rule 8 permits only there.
>    **Fallback B — drop external content:** remove `content='search_docs'` and let `search_fts` store its own copy of the text, so `DELETE FROM search_fts WHERE rowid = old.id` is ordinary SQL with no special commands at all. The corpus is a few hundred KB, so the duplicate copy costs nothing, and the whole cascade-vs-`recursive_triggers` question above stops mattering for `search_fts` because there is nothing to keep consistent with.
>    **Take B if A costs more than half a day**, and record which one shipped, here and in doc 04.
> 2. **FTS5 shadow tables** (`search_fts_data`, `_idx`, `_docsize`, `_config`) appear in `sqlite_schema`, and schema-diffing tools in other ecosystems have historically choked on them. Write the migration test with FTS5 present **on day one**, before the schema has any content, so you find out immediately whether `SchemaVerifier` tolerates them. See [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md).

FTS5 has no fuzzy matching and `spellfix1` is not in the bundled build. `watry` returns zero rows. The mitigations, in order: prefix-match the last token (covers truncation, the common cold-fingers error), porter stemming (covers inflection), and a bounded Dart-side pass over `search_docs.body` offering "Did you mean…" when FTS returns nothing. Do **not** add a second trigram index for typos.

---

## 10. First run

Nothing is asked of the user. Spec §5 forbids onboarding after first run and §7.1 forbids blocking an entry to make someone set something up first — and every event table has `season NOT NULL`, so without this the first keypad tap cannot insert a lambing.

```dart
// lib/core/db/seed/first_run.dart

/// Runs inside the migration's onCreate, in the same transaction as
/// createAll(). Not in UI code. Not in a provider. Not on first paint.
/// Skipped when `AppDatabase.seedOnCreate` is false (§1.4) — the
/// restore staging database and `tool/seed.dart` get their season from the
/// backup, and a phantom "2026 lambing" alongside it is a support ticket.
Future<void> seedFirstRun(AppDatabase db) async {
  final now = appNow();          // the ONE wall-clock reader (R23)
  final today = LocalDate.of(now);

  final seasonId = await db.into(db.seasons).insert(SeasonsCompanion.insert(
        uid: newUid(),
        year: today.year,
        label: '${today.year} lambing',   // renameable in Settings
        startDate: today,                 // re-datable in Settings
        createdAt: now,
        updatedAt: now,
      ));

  await db.into(db.appSettings).insert(
        AppSettingsCompanion.insert(currentSeason: Value(seasonId)),
      );
  await db.into(db.entitlements).insert(const EntitlementsCompanion());

  await _seedVocabulary(db, now);   // §10.1 — keys only, labels NULL
  await _seedReminderRules(db);     // the §7.6 intervals, all enabled

  // NO PENS. Decision #42: pens are created lazily and implicitly — the
  // first time a ewe is penned the app offers 1…n and creates the row on
  // tap, so the board fills as the shed fills. The zero-pen board shows a
  // single 72 pt "Add a pen" tile, never an empty grid.
}
```

> **Isolate gotcha, and it will bite a test before it bites production.** `withClock()` installs a zone value, and zone values do not cross isolate boundaries — so a `withClock` wrapper in a test does **not** reach the migration if the database was opened through `driftDatabase()`'s background connection. Migration and seed tests must use an in-process `NativeDatabase.memory()`. See [`12-testing.md`](12-testing.md).

### 10.1 The ~40 authored terms (spec §11)

Spec §11: *"roughly 40 authored terms… all generic husbandry vocabulary written from scratch"*, under the heading **"None that is licensed."** Six lists, forty keys:

| `list` | Count | Keys |
|---|---|---|
| `lambing_ease` | 5 | `ease_1` … `ease_5` |
| `death_cause` | 8 | `dc_starvation`, `dc_hypothermia`, `dc_watery_mouth`, `dc_joint_ill`, `dc_crushed`, `dc_stillborn`, `dc_unknown`, `dc_other` |
| `malpresentation` | 8 | `mp_head_back`, `mp_one_leg_back`, `mp_both_legs_back`, `mp_breech`, `mp_backwards`, `mp_twins_together`, `mp_ringwomb`, `mp_other` |
| `treatment_route` | 8 | `rt_subcutaneous`, `rt_intramuscular`, `rt_oral`, `rt_topical`, `rt_intranasal`, `rt_intravenous`, `rt_intraperitoneal`, `rt_other` |
| `ewe_observation` | 6 | `obs_prolapse`, `obs_mastitis`, `obs_poor_mothering`, `obs_good_mothering`, `obs_no_milk`, `obs_other` |
| `foster_method` | 5 | `fm_wet_adopt`, `fm_skin`, `fm_crate`, `fm_bottle`, `fm_other` |

**Where the two halves live, and why they are split:**

- **The keys** are inserted here, by `_seedVocabulary`, with `origin = 'seeded'`, `label = NULL`, and a `sort_order`. They are ASCII identifiers, not prose. They go into the database, the CSV and the JSON, and they never change.
- **The English labels** are ARB messages in `lib/l10n/`, owned by [`10-accessibility-and-i18n.md`](10-accessibility-and-i18n.md). `label IS NULL` means "render the shipped default for this key".

That split is what makes the vocabulary **user-editable without ever being overwritten**: a user's edit writes `vocab_terms.label`, which no locale change and no app update touches; and the data layer inserts the rows without importing `AppLocalizations`, which the layer rules forbid. Adding a term writes a row with `origin = 'user'`, a generated `key`, and a mandatory `label`. Removing one sets `hidden_at` — never a `DELETE`, because a term in use is the target of a foreign key with `ON DELETE RESTRICT`.

Two constraints on the writing itself, which are not this document's deliverable but are its dependency:

1. **`lambing_ease` descriptions are paraphrased, not adopted.** The SRUC technical note cited in the research is image-based; its text and its licence terms **could not be verified** and the "adopt them verbatim" instruction is overturned. Write the 1–5 scale in the app's own words at the same semantic granularity. The *concept* of a five-point assistance scale is not ownable; the sentences are.
2. **Every list carries a provenance line stating it was authored**, and CI runs the "no verbatim third-party copy" check alongside the §12.2 content-policy scan. That check scans **both** `assets/content/` and `lib/l10n/` (R66) — the provenance lines live in the first, the forty labels live in the second, and a check pointed at only one of them misses whichever half the copy was pasted into. Every seeded key must have a matching ARB message — a test asserts the two sets are equal, so a key added without a label fails the build rather than rendering blank at 3am.

Spec §7.8's *lambing ease 1–5 vs SRUC's 6* was **ruled on 2026-08-01 (decision-record §7.0 row 15, `CONVENTIONS` R78): five**, with point 5 documented as covering elective caesarean. `lambings.ease` is an ordinal `INTEGER` with a `CHECK`, not a vocabulary FK, precisely so that widening the scale is a migration someone has to think about.

---

## 11. Definition of done

- [ ] `flutter pub get` resolves against decision-record §5 on Flutter 3.44.8 / Dart 3.12.2, and `pubspec.lock` is committed.
- [ ] `build.yaml` exists (not `build.yml`), declares `modules: [fts5]` and `override_hash_and_equals_in_result_sets: true`, and contains **no** `store_date_time_values_as_text`.
- [ ] `grep -r "dateTime()" lib/core/db/` returns nothing.
- [ ] Every table declares `isStrict => true`. A test asserts every `CREATE TABLE` in `drift_schemas/drift_schema_v1.json` ends in `STRICT`.
- [ ] Every foreign key has an explicit `onDelete:` and a matching index. `test/data/every_fk_is_indexed_test.dart` enumerates `PRAGMA foreign_key_list` per table, asserts an index whose **leading** column is the child key, and carries exactly one allowlisted table: `app_settings`. A second entry in that allowlist is a review conversation, not an edit.
- [ ] `PRAGMA foreign_keys` returns 1 on a freshly opened connection; `PRAGMA journal_mode` returns `wal`; `PRAGMA synchronous` returns 2; `PRAGMA recursive_triggers` returns 1.
- [ ] Generated data-class names match `lib/data/models.dart`'s re-export list: `PenOccupancy`, `EweTouch`, `EweSummary`, `AppSetting` are `@DataClassName`d, and the app compiles without a single `…ie`/`…che` row class.
- [ ] `treatment_withdrawals.days` has null `defaultValue` and null `clientDefault` in the committed schema JSON.
- [ ] **The three irreversible-before-the-first-snapshot items are in `drift_schemas/drift_schema_v1.json`, asserted by a test that reads the JSON, not the source:** `lambings.declared_birth_type` is nullable and a lambing inserts with no birth type (R6); all seven quad-carrying tables (§4.2) have `captured_at`, `original_effective`, `time_source` and both paired CHECKs (R37); `media_assets.relative_path` carries all three CHECKs (R62). Each one is a full table rebuild if it is found afterwards.
- [ ] `app_settings.palette` accepts `night`, `amber`, `red` and rejects `dark`; the stored key and `ShedPaletteId.key` are the same string (R35).
- [ ] The two partial unique indexes exist; both tag-uniqueness tests pass, including the culled-tag reuse case.
- [ ] Deleting a ewe who has a treatment row is **refused** by the database (`RESTRICT`), and deleting a season that contains a treated lamb **succeeds**. Both assertions, in one test — they are the two halves of §5.8's `ON DELETE` asymmetry and each one alone passes the wrong schema.
- [ ] `UPDATE lambs SET birth_dam = …` throws; the foster conservation test passes over 200 random moves.
- [ ] Two ewes cannot occupy one pen: an insert of a second open `pen_occupancies` row for the same pen throws.
- [ ] The FTS5 startup assertion fires on a build without FTS5 (verify by pointing at a stock OS SQLite once, then revert).
- [ ] `SchemaVerifier` tolerates the FTS5 shadow tables — or Fallback B shipped and is recorded here and in doc 04.
- [ ] Creating a ewe, a lamb and a lambing with **every optional text field left blank** succeeds. This is the `COALESCE` trap in the fan-in triggers (§9.2) and it fails on the create-on-the-fly path, which is the 3am path.
- [ ] `searchAll` returns rows. It is the query where an alias mismatch (§9.2) passes codegen and fails at runtime, so it needs one real execution, not just a compile.
- [ ] Deleting a season leaves **zero** `search_docs` rows whose subject no longer exists, and `INSERT INTO search_fts(search_fts) VALUES('integrity-check')` does not throw afterwards.
- [ ] `onCreate` on an empty file yields exactly one season, one `app_settings` row, one `entitlements` row, 40 `vocab_terms` rows, the reminder rules, and **zero** pens.
- [ ] `AppDatabase(conn, seedOnCreate: false)` on an empty file yields the same schema and **zero** seasons — the restore path's precondition (doc 04 §7).
- [ ] Every seeded vocabulary key has an ARB message; the set-equality test passes. `test/data/vocab_list_scope_test.dart` asserts every stored vocabulary FK holds a key from that column's own `list`.
- [ ] The export round trip contains no integer row ids and no `id` keys.
- [ ] `dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42` produces a database, through the restore path, on which the pen board, the ewe card and note search all return in one frame.
- [ ] All **five** items flagged *needs verification* — §1.3 (`pragma_compile_options` exists in the bundled build), §1.4 (`drift_dev` is tree-shaken out of the release tree), §5.14 (`BEGIN` vs `BEGIN IMMEDIATE`), §9.2 (drift#3322 and the FTS5 shadow tables), §9.2 (cascade deletes vs `recursive_triggers`) — have been resolved and their answers written into this file. A doc that still says "needs verification" at v1.0 is a doc nobody finished.
- [x] The one item flagged **open** — §4.3, whether a temperature field ships at all (decision-record §7.1 #11) — **has an owner ruling, taken 2026-08-01 in N00-T04: it does not ship, and `app_settings.temperature_unit` is dropped with it.** It was the only thing in this document that could not be closed by a developer, and because it was a schema decision it closed **before** the first `make-migrations` run rather than after. Three more schema-shaped rulings landed with it and are reflected above: `WithdrawalTarget.milk` ships (§5.8), `lambs.became_ewe` ships (§5.5, §6 point 5), and lambing ease stays 1..5 (§5.4).

---

## References

- Decision record — `docs/research/00-tech-decisions.md` §1, §2.D, §2.E, §5, §6, §7.0
- Product spec — `shed-book-spec.md` §5, §7.1–7.10, §10, §11, §12
- drift — setup and `DriftNativeOptions`: https://drift.simonbinder.eu/setup/
- drift — DateTime storage modes: https://drift.simonbinder.eu/guides/datetime-migrations/
- drift — runtime schema inspection (`validateDatabaseSchema`): https://drift.simonbinder.eu/docs/advanced-features/schema_inspection/
- drift — `VerifySelf.validateDatabaseSchema` (extension member): https://pub.dev/documentation/drift_dev/latest/api_migrations_native/VerifySelf.html
- drift issue #3322 — FTS5 special INSERT commands in the analyser: https://github.com/simolus3/drift/issues/3322
- `package:sqlite3` build hooks and bundled compile options: https://github.com/simolus3/sqlite3.dart/blob/main/sqlite3/doc/hook.md
- SQLite — STRICT tables: https://sqlite.org/stricttables.html
- SQLite — foreign key support (no automatic child index; enforcement off by default): https://www.sqlite.org/foreignkeys.html
- SQLite — FTS5, external content tables and the trigram tokenizer limit: https://sqlite.org/fts5.html
- SQLite — `PRAGMA synchronous` and WAL durability: https://sqlite.org/pragma.html#pragma_synchronous
- SQLite — WAL: https://sqlite.org/wal.html
- SQLite — the LIKE optimisation: https://sqlite.org/optoverview.html#the_like_optimization
- SQLite — how to corrupt a database file: https://www.sqlite.org/howtocorrupt.html
- RFC 9562 (UUID v7), via `uuid` 4.6.0: https://pub.dev/packages/uuid
- Flutter issue #23957 — unstable iOS container UUID: https://github.com/flutter/flutter/issues/23957
- Genet Sel Evol 2015 (PMC4489108) — birth type vs rearing type as distinct traits: https://pmc.ncbi.nlm.nih.gov/articles/PMC4489108/
- NSIP, *Recording Orphan and Foster Lambs* — the grafted lamb keeps its birth type: https://nsip.org/wp-content/uploads/2026/04/Recording-Orphan-and-Foster-Lambs-4-Aug-2020-RLB-Edits.pdf
- Sheep Ireland — foster lambs are assigned to the genetic dam: https://www.sheep.ie/recording-foster-and-pet-lambs-properly-is-crucial/
- AHDB — lamb sector KPIs (the default percentage convention): https://ahdb.org.uk/key-performance-indicators-kpis-for-lamb-sector
- National Sheep Association, *Terms to know* (why terminology is an overlay, not a taxonomy): https://nationalsheep.org.uk/terms-to-know/

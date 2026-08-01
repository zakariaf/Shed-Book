# N07-T02 — `database.dart`, `converters.dart`, `uid.dart` and `mixin Identified`

| | |
|---|---|
| **Epic** | [N07 — The schema and the freeze](epic.md) · `00-README` §9 step 3 (1 of 2) |
| **Task** | 2 of 8 |
| **Depends on** | N07-T01 |
| **Commit** | one commit · `feat(db): AppDatabase, converters, uid and mixin Identified` |

## 1. Why this task exists

The `AppDatabase` class, `kSchemaVersion`, the type converters (`Instant`, `LocalDate`,
`Grams`, `MilliCelsius` — every one of them mapping to decision #2's storage shape), `newUid()` for the
export identity, and `mixin Identified` carrying P1's `struck` / `struck_at` onto every table.

Everything the next five tasks write hangs off this file. `@DriftDatabase`'s table list, the four
mixin columns and the three converters are the vocabulary every cluster is spelled in, and all three
are frozen by T08's snapshot.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | §1.4 | `AppDatabase`, `kSchemaVersion`, `seedOnCreate`, `schemaVersionOverride`, `beforeOpen` and the `validateDatabaseSchema` trap |
| `docs/engineering/03-data-model-and-schema.md` | §2, §2.1, §3, §4.1 | the nine conventions every table obeys, `mixin Identified`, the dual-key id strategy, and the three converters |
| `docs/engineering/04-migrations-media-backup-restore.md` | §2.3 | the same class from the migration side — `stepByStep`, the historical `schema` argument, the `drift_dev` import note |
| `docs/engineering/CONVENTIONS.md` | §2.8, §2.9, R2, R7, R14, R15, R20, R21 | the class name, the constructor, `newUid()`'s home, one converters file, the four `@DataClassName`s |
| `docs/research/00-tech-decisions.md` | §5 | `uuid` 4.6.0 (RFC 9562 v7) · `drift_dev` 2.34.5 · `build_runner` `">=2.15.0 <2.15.2"` |
| `epics/N00-.../N00-T05` | the ruling | P1's exact column names, types and paired CHECK for `struck` / `struck_at` |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | the database class, the converters and the mixin |
| `shed-conventions` | P1's ruling in §6 says exactly which tables carry the mixin |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/database_test.dart`
- **Test** — `'every table mixes in Identified and carries struck and struck_at'`
- **Assertion, spelled out** — enumerate `db.allTables`; for each table **not** on the exclusion
  allowlist of 03 §2.1 (caches, singletons and pure join tables, named one by one), assert the column
  set contains `id`, `uid`, `created_at`, `updated_at`, `struck` and `struck_at`. The allowlist is a
  literal in the test and every entry carries the reason it is exempt.
- **Why it is red today** — there is no database class and P1 is ruled but unimplemented.

```bash
fvm flutter test test/data/database_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the class, the converters, the uid, the mixin — then
`dart run build_runner build --delete-conflicting-outputs` **only**. `make gen` in full runs once, in
T08.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/core/db/converters.dart` | **New.** `InstantConverter`, `LocalDateConverter`, `PartialDateConverter`. **One file, not a folder** (R21). All three `const` — a `TypeConverter` is constructed once per column declaration. |
| 2 | `lib/core/db/uid.dart` | **New.** `String newUid()` and the single `const _uuid = Uuid();`. The **only** `package:uuid` call site in the app (R15), which is why it is here and not beside the id extension types in `lib/domain/ids.dart`. |
| 3 | `lib/core/db/tables/common.dart` | **New.** `mixin Identified on Table` — `id`, `uid`, `createdAt`, `updatedAt`, plus P1's two columns. Nothing else goes in this file. |
| 4 | `lib/core/db/database.dart` | **New.** `kSchemaVersion`, `@DriftDatabase(...)`, `class AppDatabase extends _$AppDatabase`, `part 'database.g.dart';`. The table list starts empty and grows one cluster per task — see 5.3. |
| 5 | `lib/core/db/connection.dart` | Gains `Future<AppDatabase> openAppDatabase()` — the app's single entry point, deferred from T01 because it needs the class this task creates. It asserts it is not running under `flutter_test` and throws naming the override to add (R12; owned by `01-architecture.md`). |
| 6 | `lib/data/models.dart` | **New, and empty of names.** Create the file with the `export … show` line and no names in it yet; T03–T06 add row classes as their clusters land. `lib/features/` cannot import `lib/core/db/`, so this re-export is the only way a screen ever sees a row class (R20). |
| 7 | `tool/policy_allowlist.txt` | Add the one `lib/` import of a dev dependency: `lib/core/db/database.dart` imports `package:drift_dev/api/migrations_native.dart`. Decision #127 wants the release `--analyze-size` delta recorded at the next release; note the allowlist line's reason in the commit message, per `00-README` §7.4. |
| 8 | `test/support/harness.dart` | The T01 connection helper becomes `Future<AppDatabase> testDatabase({bool seedOnCreate = true})` — 12 §3.1, with `closeStreamsSynchronously: true` and `addTearDown(db.close)` inside the helper. |
| 9 | `test/data/database_test.dart` | **New.** The anchor test plus the cases in 5.4. |
| 10 | `test/data/converters_test.dart` | **New.** The three converters, round-tripped, including the DST case. |

### 5.2 The signatures

```dart
// lib/core/db/database.dart
/// Read on the background isolate too, so it is a top-level const that
/// captures nothing. Bumped by exactly one per schema change (04 §2.4).
const kSchemaVersion = 1;

@DriftDatabase(tables: [/* grows one cluster per task — see 5.3 */])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e, {
    this.seedOnCreate = true,
    this.schemaVersionOverride = kSchemaVersion,
  });

  final bool seedOnCreate;                 // false on exactly two paths — restore, tool/seed.dart
  @visibleForTesting final int schemaVersionOverride;   // R14; production never passes it

  @override int get schemaVersion => schemaVersionOverride;
}
```

```dart
// lib/core/db/uid.dart — the ONE package:uuid call site in the app (R15).
const _uuid = Uuid();
String newUid() => _uuid.v7();
```

```dart
// lib/core/db/converters.dart — ONE FILE, not a folder (R21).
class InstantConverter    extends TypeConverter<Instant, int>       { const InstantConverter(); }
class LocalDateConverter  extends TypeConverter<LocalDate, String>  { const LocalDateConverter(); }
class PartialDateConverter extends TypeConverter<PartialDate, String> { const PartialDateConverter(); }
```

```dart
// lib/core/db/tables/common.dart
mixin Identified on Table {
  late final id        = integer().autoIncrement()();
  late final uid       = text().withLength(min: 36, max: 36).unique()();
  late final createdAt = integer().map(const InstantConverter())();
  late final updatedAt = integer().map(const InstantConverter())();
  // + P1's `struck` / `struck_at`, spelled exactly as N00-T05's ruling spells them.
}
```

### 5.3 The details that are easy to get wrong

1. **Do not paste 03 §1.4's complete 23-table list into `@DriftDatabase`.** Twenty-two of those
   classes do not exist yet, `build_runner` fails, and it stays failing until T06 — which is precisely
   the defect the fourteen-into-eight re-cut existed to remove (`00-PLAN-CRITIQUE` §7:
   *"E06: does not compile between T01 and T13"*). **The table list grows one cluster per task.**
   Whatever the final list looks like, it is T06 that completes it.
2. **Do not import `schema_versions.dart` and do not write `onUpgrade: stepByStep(...)` here.**
   `schema_versions.dart` is generated by `drift_dev schema steps`, which is part of `make gen`, which
   runs once, in T08. `migrations.dart` and the `stepByStep` scaffold are
   [N08-T01](../N08-the-migration-harness-and-the-codegen-job/N08-T01-migrationsdart-the-stepbystep-scaffold.md),
   the next epic. Add the import there. If you add it here the tree does not compile for six commits.
3. **`onCreate` is `await m.createAll();` and nothing else in this commit.** `seedFirstRun` does not
   exist until T07; the `if (seedOnCreate) await seedFirstRun(this);` line lands with it. `seedOnCreate`
   is declared now because it is a constructor parameter the harness already needs.
4. **There is no `GramsConverter` and no `MilliCelsiusConverter`.** §1 above names four kinds; 03 §4.1
   and R21 name **three** converters, and that is not an omission. `Grams` and `MilliCelsius` are
   `extension type const …(int value)` over `int`, so `lambs.birth_weight_g` is a plain
   `integer().nullable()()` and the wrapping happens above this layer. Adding a converter for them
   would put a domain type in the column declaration for no storage benefit. Related: **no v1 table
   stores a temperature at all** (03 §4.3) unless N00-T04 ruled otherwise — check the ruling before you
   reach for `MilliCelsius`.
5. **`import 'package:drift_dev/api/migrations_native.dart'` — not `api/migrations.dart`.** The
   non-native path is a different library and `validateDatabaseSchema` is not on it.
6. **`validateDatabaseSchema()` is an *extension member* on `GeneratedDatabase` returning
   `Future<void>`.** Wrapping it in a synchronous `assert()` starts the check, returns `true`
   immediately, and surfaces a mismatch as an unhandled async error long after `beforeOpen` completed.
   Write `if (kDebugMode) { await validateDatabaseSchema(); }`. `kDebugMode` is a compile-time
   constant, so the branch and everything it reaches are tree-shaken out of release.
7. **Keep `AUTOINCREMENT`.** `integer().autoIncrement()()` emits
   `INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT`, not a bare rowid alias. The keyword guarantees ids are
   never reused after a delete, which is what stops a recreated ewe inheriting a culled ewe's notes
   through a stale foreign key in an old export. The cost is one `sqlite_sequence` row.
8. **`id` never crosses the export boundary; `uid` always does.** They are not two spellings of one
   thing (03 §3). `uid` is a UUID **v7** — its 48-bit millisecond prefix keeps the index appending
   rather than scattering. v4 and ULID were weighed and rejected in decision #32; do not re-open them.
9. **"Every table" in the DoD is not literally 23.** 03 §2.1 states the exclusions in the mixin's own
   doc comment: `Identified` is **not** carried by caches (`ewe_touches`, `ewe_summaries`,
   `search_docs`), by singletons (`app_settings`, `entitlements`), or by pure join tables
   (`pen_occupancy_lambs`) — and `reminder_rules` and `terminology_overrides` declare their own
   `primaryKey`. That is 16 tables with the mixin and 7 without. **P1's ruling in `CONVENTIONS §6`
   names the tables `struck` / `struck_at` apply to — read that list, do not infer it from the mixin.**
   If the ruling puts the two columns somewhere the mixin does not reach, they are declared per table,
   and that is a decision to make now, not after the snapshot.
10. **The anchor test is vacuous today and that is deliberate.** With no tables registered,
    `db.allTables` is empty and the enumeration passes over nothing. It starts asserting in T03 and
    T06 adds `'the registered table count equals 23'` so vacuity cannot survive the epic. A test that
    passes over an empty list is not evidence — write the count assertion into T06's file the moment
    you write this one, or it will be forgotten.
11. **`store_date_time_values_as_text` is never set and no drift `dateTime()` column ever exists.**
    Both are irreversible after T08's snapshot and both are a single global flag applied to every
    column in the app. `build.yaml` is N01-T03's file; `check_policy` greps it. The integer mode is
    *seconds*, and drift "always returns a non-UTC value, so even when UTC date times are stored, this
    information is lost" — which is the whole reason the three converters above exist.

### 5.4 The test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/data/database_test.dart` | `'every table mixes in Identified and carries struck and struck_at'` | The anchor; enumerates `allTables` against the 03 §2.1 exclusion allowlist. |
| | `'kSchemaVersion is 1 and schemaVersion returns the override'` | R14 — `AppDatabase(conn, schemaVersionOverride: 1)` is the only path that differs, and N08-T04's downgrade test depends on it existing. |
| | `'opening an empty file runs createAll and beforeOpen without throwing'` | The `validateDatabaseSchema` await, in debug. |
| | `'AppDatabase(conn, seedOnCreate: false) opens the same schema'` | 04 §7's restore precondition. It asserts nothing about rows yet — T07 adds the zero-seasons half. |
| `test/data/converters_test.dart` | `'InstantConverter round-trips epoch millis exactly'` | `Instant → int → Instant` identity. |
| | `'LocalDateConverter round-trips YYYY-MM-DD and throws on 2026-2'` | The strict parser: a row holding `'2026-2'` throws on read instead of becoming a plausible date. |
| | `'PartialDateConverter never widens YYYY to YYYY-01-01'` | Partial precision is the fact, not a gap to fill. Used by exactly one column, `ewes.date_of_birth`. |
| `test/domain/uk_zone/converters_dst_test.dart` | `'an instant inside the ambiguous hour round-trips its epoch millis unchanged'` | `@Tags(['uk-zone'])`, `TZ=Europe/London`. 25 Oct 2026 **01:30** happens twice; the converter stores whichever instant Dart resolved and must not normalise it. Pair it with `'a civil date on 29 March 2026 round-trips as 2026-03-29 with no time component'` — the spring-forward day, where a `LocalDate` must not acquire an hour. |
| `test/data/uid_test.dart` | `'newUid returns a 36-character RFC 9562 v7 string and 10,000 are distinct'` | Version nibble is `7`; length is exactly 36, which the `withLength(min: 36, max: 36)` column enforces on the way in. |

### 5.5 Verification that the generated names are right

After `build_runner`, grep `lib/core/db/database.g.dart` for `class Identified` — there should be none;
a mixin is not a table. The row classes that matter are checked in T05 and T06, where the four
`@DataClassName`s land (`PenOccupancy`, `EweTouch`, `EweSummary`, `AppSetting`) — drift's default is
literally "strip the trailing `s`", and `PenOccupancie` in a repository signature is a whole-codebase
edit once the snapshot exists.

## 6. Constraints that bind this task

- **Irreversibility** — `kSchemaVersion`, the mixin's column set and the three converters' storage
  shapes are all frozen by T08. Decision #2 (instants `INTEGER` epoch millis, civil dates `TEXT`) is
  the one `00-README` §4 marks *irreversible after the first migration snapshot*.
- **Layering** — `lib/core/db/` may import `lib/core/`, `lib/domain/`, `package:drift`,
  `package:sqlite3`, `package:uuid`, `package:clock` and `package:flutter/foundation.dart` (R15, R16).
  Never `package:flutter/material.dart`, never `lib/data/`.
- **One generator is the budget** (decision #16) — drift only. No `freezed`, no `json_serializable`,
  no `riverpod_generator`.
- **This commit runs `build_runner` only.** `drift_dev make-migrations` is T08's, alone.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every table mixes in Identified and carries struck and struck_at'` passes, and was seen to fail first for the stated reason
- [ ] every converter maps to decision #2's shape and no drift `dateTime()` column exists
- [ ] `store_date_time_values_as_text` is never set
- [ ] every table declared from here on mixes in `Identified`
- [ ] this commit runs `build_runner` only — no snapshot is written
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
# 1. Red first.
fvm flutter test test/data/database_test.dart

# 2. Generate — build_runner ONLY. Never make gen in this task.
dart run build_runner build --delete-conflicting-outputs

# 3. Nothing under drift_schemas/ or test/drift/generated/ may have moved.
git status --short drift_schemas/ test/drift/

# 4. The new tests, including the London-zone pair.
fvm flutter test test/data/
TZ=Europe/London fvm flutter test --tags uk-zone

# 5. Both gates.
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(db): AppDatabase, converters, uid and mixin Identified`

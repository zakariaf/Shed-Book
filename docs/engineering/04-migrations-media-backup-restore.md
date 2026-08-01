# 04 — Migrations, media, backup and restore

This document governs everything that can destroy a shepherd's five seasons of records: the schema migration that runs unattended on the launch after an app update, the media files that live outside the database, the JSON backup that is the only recovery path the product has, and the restore that replaces everything on the phone with the contents of a file. There is no server, no cloud copy and no support channel that can fix a bad migration on someone else's phone in April. Every rule below exists because the failure it prevents is unrecoverable. If you are adding a column, attaching a photo, or touching the import path, this is your document.

> **Decisions applied:** #13 writes return a sealed `WriteOutcome` · #25 persistence layer (drift over bundled SQLite) · #27 database location (application support) · #28 connection pragmas (WAL + `synchronous = FULL`) · #29 DateTime storage (`INTEGER` instants, `TEXT` civil dates) · #30 the cost of #29 (rewrite note 03's `dateTime()` columns before the first snapshot) · #31 table conventions (`STRICT`, real FKs, no advice-bearing defaults) · #32 ID strategy (dual key, `uid` UUID v7 as the export identity) · #35 FTS5 over `search_docs` · #37 migrations (forward-only, additive, never destructive) · #38 migration test scope (full from→to matrix + no-diff CI check) · #39 debug schema self-check · #40 media storage (filesystem, relative paths only) · #42 first-run bootstrap in `onCreate` · #46 one clock · #47 SQL-side time banned · #51/#52 the withdrawal sealed type and its two gates · #53 timestamp provenance · #62 the single disclaimer constant · #63 reminder reconcile · #73 restore (replace everything, atomically) · #74 seed data through the restore path · #76 the voice *note* ships, voice tag entry does not · #77 image capture and compression · #80 share sheet · #81 file import · #84 backup format (JSON is the backup; `VACUUM INTO` is a diagnostics snapshot) · #85 media in the backup (records-only for v1) · #86 export is never gated · #88 entitlement excluded from the backup · #93 store privacy declarations · #108 never an all-numeric date in front of a human · #123 diagnostics · #124 redaction rules · #125 off-isolate work · #127 app-size budget.
>
> **Owner rulings honoured (decision-record §7.0, settled 2026-07-27):** OCR and voice tag entry are cut from v1, so the only media this document stores is a photo and a plain local recording. Tags are unique among **active** animals only, which is why a media filename is a `uid` and never a tag (§4.2). UK/Ireland is first, so every date a human reads here is `d MMM y` and every civil date stored or filed is `YYYY-MM-DD`. The free tier is season-primary, and **export is never gated by it** (§6.1). None of these four is open; nothing below reopens them.

**Sibling documents:** [`01-architecture.md`](01-architecture.md) (layers, the folder tree, `WriteOutcome`, `ShedFailure`, `main()`), [`02-state-di-navigation.md`](02-state-di-navigation.md) (Riverpod 2.6.1 shapes, `WriteController`), [`03-data-model-and-schema.md`](03-data-model-and-schema.md) (the tables this document migrates), [`05-domain-correctness.md`](05-domain-correctness.md) (`Instant`, `LocalDate`, `RecordedTime`, `appNow()`), [`08-platform-integration.md`](08-platform-integration.md) (camera, recorder, share sheet, notifications), [`09-export-formats.md`](09-export-formats.md) (CSV, PDF, and the disclaimer footers), [`12-testing.md`](12-testing.md) (the in-memory drift harness), [`13-build-ci-release.md`](13-build-ci-release.md) (the CI job that runs these gates).

> **Naming: settled, not open.** [`CONVENTIONS.md`](CONVENTIONS.md) is the binding naming authority for this doc set and outranks this document on any name, path, type shape, signature or word.
> (a) The schema package is **`lib/core/db/`** (R1) — decision #9 says `core/db/` verbatim and `01-architecture.md` owns the folder tree. Every path below, including the `build.yaml` `databases:` entry, the `drift_dev schema dump` target and the `git add` line, is written that way.
> (b) The database class is **`AppDatabase`** and the opener is **`openAppDatabase()`** (R2). Everywhere else — `lib/data/media_store.dart`, `lib/data/note_repository.dart`, `lib/core/time/app_clock.dart` — this document follows the canonical tree in `CONVENTIONS.md` §1 exactly.

---

## 1. The four things you cannot undo

Read this section before you write a line of schema code.

| # | The irreversible thing | The rule | Where it is decided |
|---|---|---|---|
| 1 | The **first committed schema snapshot** freezes the storage representation of every column in it. | Instants are `INTEGER` UTC epoch millis; civil dates are `TEXT 'YYYY-MM-DD'`. `store_date_time_values_as_text` is **never** set in `build.yaml` and drift's `dateTime()` column builder appears **nowhere** in the project. | Decision #29, #30 |
| 2 | A **released migration step** is on someone's phone forever. | You never edit a committed step or a committed snapshot. A mistake is repaired by a *new* step at the next version. | Decision #37, §2.9 below |
| 3 | An **absolute media path** written to the database is dead the moment the app is updated on iOS. | Only relative paths are ever stored, and the database physically refuses anything else. | Decision #40, §4.3 below |
| 4 | A **restore** destroys everything on the phone. | Replace-everything, atomically, through one code path, with a sentinel file that makes a crash mid-swap recoverable. | Decision #73, §7 below |

Everything else in this document is a rule you can change in week two. These four are not.

---

## 2. The migration ritual

### 2.1 The five rules

1. **Forward-only.** `schemaVersion` goes up by exactly one, never down, never by two. A downgrade must **fail loudly**, never run: a sideloaded older build reading a newer file is silent corruption. `stepByStep` is understood to throw on a downgrade, but the version that introduced that behaviour is not in the decision record's §5 table and is not quoted here from memory — **the guarantee is ours, asserted by the test in §3.5**, on the pinned `drift` 2.34.2 / `drift_dev` 2.34.5.
2. **Additive by default.** `m.createTable`, `m.addColumn`, `m.createIndex`. That is the whole vocabulary of a normal migration.
3. **Never destructive on user data.** No `DROP COLUMN`, no `DROP TABLE`, ever, on a table that has held a shepherd's records. If a column truly must die, stop writing it and leave it. If a table truly must die, rename it to `<name>_deprecated_v<N>` and delete it no earlier than two major versions later. Storage is free; a 2027 season is not. That eventual `DROP TABLE` is the one exception to the `db.destructive_ddl` rule in §2.10, and it is taken the only way exceptions are taken here: a line in `tool/policy_allowlist.txt` naming the exact table, the schema version that deprecated it and the schema version that drops it. No allowlist line, no drop.
4. **Never change a column's meaning in place.** New meaning ⇒ new column ⇒ new name. A column that meant "kg × 10" and now means "grams" is a silent data-corruption event that no test will catch and no user will notice until the season summary is wrong.
5. **Bump, generate and test in one commit.** `schemaVersion`, the new step, the regenerated snapshot and the regenerated test helpers land together or not at all. CI enforces this by re-running the generators and failing on any diff (§3.6).

**Why these are stricter than a normal app's rules.** A user can sit on v1.0 for two seasons and update straight to v2.4. There is no server to run a backfill, no way to push a hotfix to a phone that has never been online, and no cloud copy to restore from if a migration eats a table. The only backup is one the user chose to make, and most will not have made one. A red migration test is ship-blocking (#37).

### 2.2 Setup: `build.yaml`

```yaml
# build.yaml  — the file must be named build.yaml, not build.yml.
targets:
  $default:
    builders:
      drift_dev:
        options:
          # FTS5 must be understood by drift's SQL analyser (search.drift).
          sql:
            dialect: sqlite
            options:
              modules:
                - fts5
          # make-migrations needs all three of these.
          databases:
            shed_book: lib/core/db/database.dart
          schema_dir: drift_schemas/
          test_dir: test/drift/
          # Row equality without hand-written == on every generated class.
          override_hash_and_equals_in_result_sets: true
```

**What must never appear in this file:**

```yaml
          store_date_time_values_as_text: true   # BANNED — decision #29
```

Note 03 §2.6 ships that line and marks it "irreversible". It is: setting it changes how *every* `dateTime()` column is stored, and drift's own documentation says the mode is not compatible with an existing schema. Decision #29 overturned it because an instant and a civil date are different kinds and one global flag forces one representation onto both. The practical consequence for you: **there are no `dateTime()` columns in this project at all**, so the flag has nothing to act on. `integer()` + an `InstantConverter`, or `text()` + a `LocalDateConverter`. See [`05-domain-correctness.md`](05-domain-correctness.md).

`build_runner` is pinned to `">=2.15.0 <2.15.2"` (decision #3). `^2.15.2` does not resolve on this stack; do not "fix" it.

### 2.3 The database class

```dart
// lib/core/db/database.dart
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
// The ONE place lib/ imports a dev dependency. See the note below.
import 'package:drift_dev/api/migrations_native.dart';

import 'schema_versions.dart'; // generated by `drift_dev schema steps`

/// Read by the connection setup on the background isolate as well, so it is a
/// top-level const and captures nothing.
const kSchemaVersion = 1;

@DriftDatabase(
  tables: [/* see 03-data-model-and-schema.md */],
  include: {'search.drift', 'views.drift', 'queries.drift'},   // CONVENTIONS R22
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(
    super.e, {
    this.seedOnCreate = true,
    this.schemaVersionOverride = kSchemaVersion,
  });

  /// False only on the restore path (§7) and in `tool/seed.dart`,
  /// where the rows come from the backup rather than from first-run defaults.
  final bool seedOnCreate;

  /// Always `kSchemaVersion` in the app. The one caller that passes anything
  /// else is the downgrade test in §3.5, which needs a build that believes it
  /// is a version behind. There is no setter and no path from the UI.
  @visibleForTesting
  final int schemaVersionOverride;

  @override
  int get schemaVersion => schemaVersionOverride;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          if (seedOnCreate) await seedFirstRun(this); // decision #42
        },
        onUpgrade: stepByStep(
          // from1To2: (m, schema) async {
          //   await m.addColumn(schema.ewes, schema.ewes.eid);
          // },
        ),
        beforeOpen: (details) async {
          // decision #39 — an extension member returning Future<void>.
          // Never wrap it in a synchronous assert(): that starts the check,
          // returns true immediately, and surfaces a mismatch as an unhandled
          // async error long after beforeOpen completed.
          if (kDebugMode) {
            await validateDatabaseSchema();
          }
        },
      );
}
```

Three things about this class:

- **`beforeOpen` stays near-empty.** It runs on every open, migration or not, and it is on the cold-start path. `kDebugMode` is a compile-time constant, so the branch and the `drift_dev` code it reaches are tree-shaken out of release. This is the only `lib/` import of a dev dependency in the project: add the file to the policy allowlist and confirm at the next release that the `--analyze-size` total did not move (#127).
- **`seedOnCreate`.** Decision #42 puts the first-run season seed in `onCreate`, not in UI code. The import path must create the same schema *without* the seed, or the restored database ends up with a phantom "2026 lambing" season nobody created. One boolean, defaulted to the safe value.
- **`stepByStep` callbacks take a historical `schema`.** Migration code references `schema.ewes`, never `db.ewes` and never the generated table class from today's `database.dart`. That is the entire mechanism that stops a v1→v2 migration breaking on the day you add a column in v9.

### 2.4 The ritual, verbatim

Every schema change, without exception:

```bash
# 0. Start from a clean tree. `git status` is empty.

# 1. Edit the tables in lib/core/db/tables/*.dart.

# 2. Bump kSchemaVersion in lib/core/db/database.dart by exactly one.

# 3. Add the new callback to stepByStep(...) — from<N>To<N+1>.

# 4. Regenerate the drift code, then the migration artefacts.
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev make-migrations

# 5. Run the matrix. A red migration test is ship-blocking.
flutter test test/drift/

# 6. Commit code + snapshots + generated helpers TOGETHER.
git add lib/core/db drift_schemas/ test/drift/
git commit -m "schema v<N+1>: add <thing>"
```

`make-migrations` is a wrapper. When you need to understand what it did, or when you need one part of it, these are the three underlying commands (they take the paths from `build.yaml`, so keep them consistent):

```bash
# Write drift_schemas/drift_schema_v<N>.json for the current schema.
dart run drift_dev schema dump lib/core/db/database.dart drift_schemas/

# Write the compressed step definitions used by stepByStep().
dart run drift_dev schema steps drift_schemas/ lib/core/db/schema_versions.dart

# Write the test helpers (GeneratedHelper, per-version data classes and
# companions) that the from->to matrix and the data-integrity test use.
dart run drift_dev schema generate --data-classes --companions \
    drift_schemas/ test/drift/generated/
```

**Nothing under `drift_schemas/` or `test/drift/generated/` is ever hand-edited.** They are generated evidence, committed so CI can diff them and so `SchemaVerifier` can build a v1 database in 2029.

### 2.5 What each artefact is

| Path | What it is | Committed? | Hand-edited? |
|---|---|---|---|
| `drift_schemas/drift_schema_v<N>.json` | The exact shape of the schema at version N. The input to `SchemaVerifier`. | Yes | **Never** |
| `lib/core/db/schema_versions.dart` | The `stepByStep(...)` signature and the compressed historical schemas the callbacks receive. | Yes | **Never** |
| `test/drift/generated/schema.dart` | `GeneratedHelper` — builds a real database at any past version. | Yes | **Never** |
| `test/drift/generated/schema_v<N>.dart` | Per-version data classes and companions, for writing v1 rows in a test. | Yes | **Never** |
| `lib/core/db/database.g.dart` | Normal drift codegen. | Yes | **Never** |
| `lib/core/db/migrations.dart` | The `from<N>To<N+1>` callback bodies, if you split them out of `database.dart`. | Yes | Yes — this is the only file here you write |

### 2.6 When `ALTER TABLE` is not enough

Changing a `CHECK`, tightening a type, adding a `NOT NULL`, or altering a foreign key all require SQLite's 12-step table-rebuild procedure. **Do not hand-roll it.** sqlite.org warns that the naive "rename old, create new, copy, drop" ordering risks corrupting references in triggers, views and foreign-key constraints. Use drift's `TableMigration`, which implements the documented order:

```dart
from3To4: (m, schema) async {
  // v4 tightens media_assets' CHECK from `byte_size >= 0` to `byte_size > 0`:
  // a zero-byte photo is a failed write, not a photo. A CHECK cannot be
  // altered by ALTER TABLE, so the table is rebuilt.
  //
  // NO columnTransformer. Every column keeps its storage and its value; the
  // rebuild copies them across untouched. This is what almost every rebuild
  // in this project will look like.
  await m.alterTable(TableMigration(schema.mediaAssets));
},
```

**A `columnTransformer` is only ever for a column whose SQL *storage* changes** — an `INTEGER` widening, a text encoding, a column split into two. It is never a way to supply a value. On this schema no storage change is planned at all, because decision #29 froze the temporal representations at v1 (§1 row 1), which is most of what makes such a change necessary elsewhere.

And when one does turn up, the transformation stays inside §2.7's structural list: `0`, `NULL`, `''`, a value copied from another column. What it must never be — the concrete case, because this is the table people reach for:

```dart
// NEVER. This is what a §12.1 violation looks like as a migration.
schema.treatmentWithdrawals.target:
    const CustomExpression<String>("COALESCE(target, 'meat')"),
```

Backfilling a withdrawal *target* — or, worse, a withdrawal *period* — invents a domain value the shepherd never entered. `treatment_withdrawals` has no default on `days` and never will (#51, #52); a treatment with no withdrawal row reads as `WithdrawalNotRecorded`, and that is the correct answer, not a gap to fill. If a rebuild on a safety table seems to need a `COALESCE` of a domain column, the migration is wrong, not the constraint.

Two hazards, both real:

- **`PRAGMA foreign_keys` is a no-op inside a transaction, and drift wraps migrations in a transaction.** If a step needs deferred FK behaviour, use `PRAGMA defer_foreign_keys = ON` inside the transaction, and run `PRAGMA foreign_key_check` at the end of the step. The matrix test asserts it returns zero rows for every path (§3.3).
- **A table rewrite is exactly the kind of migration that loses data.** Any step containing `alterTable` automatically pulls in a data-integrity test for that hop (#38), not just a schema-validation test.

### 2.7 What a migration may and may not write

A migration may write **structural** values: `0`, `NULL`, an empty string, a value copied from another column, a `uid` generated with `newUid()`, a timestamp from `appNow()` (§5.2 — never `DateTime.now()`, never SQL-side time).

A migration may **never** write a *domain* value the user did not enter. Concretely, and non-negotiably:

- Never write a withdrawal period. No default, no inference, no "the old column said 7 so put 7 in the meat row". Spec §12.1. If a migration cannot populate a withdrawal without guessing, the correct migration leaves no row, which the sealed type reads as `WithdrawalNotRecorded` (#51).
- Never infer a lambing ease, a birth type, a cause of death, or a `barren` outcome from the absence of data. Barren is `ewe_seasons.status = 'barren'` (CONVENTIONS R42), and a migration may not write it. Spec §12.4, decision #59.
- Never "repair" a contradiction. If a v1 database has three lambs against a birth type of `twin`, the v2 database has three lambs against a birth type of `twin`. The badge is computed on read (#54).
- Never rewrite a timestamp or its provenance. A migration that moves an instant between columns copies `effective`, `capturedAt`, `originalEffective` and `TimeSource` as a unit (#53).
- Never use SQL-side time. `CURRENT_TIMESTAMP`, `date('now')` and `datetime('now')` are banned everywhere including migrations (#47).

CI catches the SQL-side time ban and the `DROP` ban (§2.9). It cannot catch "invented a domain value" — that is a line in [`CODE-REVIEW-CHECKLIST.md`](CODE-REVIEW-CHECKLIST.md) and it is the reason migrations get reviewed at all.

### 2.8 The pre-migration snapshot

Before drift touches a database whose `user_version` is behind the app, take a byte-faithful copy. This is thirty lines and it is the difference between "we shipped a bad migration" and "we shipped a bad migration and destroyed five seasons".

```dart
// lib/core/db/connection.dart — this file also holds `openAppDatabase()` (the
// app entry point, 01) and `openConnection()` (the only driftDatabase( call
// site, 03). CONVENTIONS R12.
// `configureConnection` MUST be top-level and public: DriftNativeOptions.setup
// is sent across isolates, must not capture anything, and a private name cannot
// be referenced from a test.
void configureConnection(CommonDatabase db) {
  db.execute('PRAGMA journal_mode = WAL;');        // persistent, in the header
  db.execute('PRAGMA synchronous = FULL;');        // per-connection — decision #28
  db.execute('PRAGMA foreign_keys = ON;');         // per-connection, OFF by default
  db.execute('PRAGMA busy_timeout = 5000;');
  db.execute('PRAGMA journal_size_limit = 4194304;');
  db.execute('PRAGMA temp_store = MEMORY;');
  db.execute('PRAGMA recursive_triggers = ON;');   // 03 §1.3 — the FTS5 sync triggers

  _assertEngineCapabilities(db);   // FTS5, fails loudly — 03 §1.3
  _snapshotBeforeMigration(db);
}

void _snapshotBeforeMigration(CommonDatabase db) {
  final current = db.userVersion;
  // 0 == a database we are about to create. Nothing to protect.
  if (current == 0 || current >= kSchemaVersion) return;

  // The main file's path, from the connection itself — no path_provider on
  // this isolate, no captured variables.
  final row = db.select('PRAGMA database_list;').firstWhere(
        (r) => r['name'] == 'main',
        orElse: () => throw StateError('no main database'),
      );
  final mainPath = row['file'] as String?;
  if (mainPath == null || mainPath.isEmpty) return; // :memory:

  final mainFile = File(mainPath);
  // Bounded: never spend a minute copying at launch.
  if (mainFile.lengthSync() > 250 * 1024 * 1024) return;

  final dir = Directory(p.join(p.dirname(mainPath), 'pre_migration'))
    ..createSync(recursive: true);
  final out = File(p.join(dir.path, 'shed_book-v$current.sqlite'));
  // VACUUM INTO refuses to overwrite an existing non-empty file.
  if (out.existsSync()) out.deleteSync();

  try {
    db.execute('VACUUM INTO ?;', [out.path]);
  } on SqliteException {
    // Disk full, or the file is already damaged. Do not block the launch;
    // the diagnostics log records it. Never rethrow from setup.
  }
}
```

Rules that make this safe:

- **The pragma list is the union of 03's set and this document's, in the order above** (CONVENTIONS R13). Every one of the seven is load-bearing in one of the two documents; dropping any is a regression. `recursive_triggers` and `_assertEngineCapabilities` come from 03, `journal_size_limit`, `temp_store` and the snapshot from here.
- It runs **before** drift's migration, on the same connection, outside any transaction. `VACUUM` cannot run inside a transaction; `setup` is the one place where it is legal on the launch path.
- It runs **once per upgrade**, not per launch: `userVersion < kSchemaVersion` is only true on the first launch after an update.
- `pre_migration/` holds at most one file. Delete it on the first clean launch where `userVersion == kSchemaVersion` **and** the app has completed one successful write, so it survives a crash loop.
- It is **not** an in-app restore path. There is one restore path and it is JSON (#84, #73). The snapshot is bytes: the user shares it out from Settings ▸ Diagnostics, and `tool/snapshot_to_backup.dart` (committed, developer-run) converts it into a JSON backup that the normal restore accepts. Two restore paths would be two migration surfaces; a developer-side conversion tool is not a code path on the phone.

### 2.9 When you get it wrong

You cannot un-ship a migration. The recovery procedure, in order:

1. **Stop the rollout.** Halt the staged release / phased release on both stores before writing any code.
2. **Reproduce it from a snapshot, in a test, before touching anything.** Start at the last-good version with `verifier.startAt(N)`, apply the released step, and assert the damage. If you cannot write that test, you do not yet understand the bug.
3. **Never edit the committed step or the committed snapshot.** Phones that already ran it will not run it again, so an edit makes the fleet diverge into two schemas with the same version number — the worst state this system can be in.
4. **Ship the repair as a new step at N+1.** It may create the missing column, re-derive a structural value, or add an index. It may not invent a domain value (§2.7).
5. **If data was destroyed, say so.** The repair step marks the affected rows (a nullable `repair_note` on the affected table, or a row in the diagnostics log), and the UI shows what happened on the affected records. Spec §12.4 forbids silent correction; it equally forbids silent loss. "Six treatments from before 14 March lost their batch number in an update" is a true sentence the app must be able to say.
6. **The user's own recovery** is: share the `pre_migration/` snapshot from Diagnostics, or restore their last JSON export. Both are worse than not shipping the bug. Neither is nothing.
7. **Add the regression test permanently.** The from→to matrix now has a hop that is known-hostile; the data-integrity test for it is not optional (#38).

### 2.10 Anti-patterns and the gates that catch them

| Banned | Why | Caught by |
|---|---|---|
| `DROP TABLE` / `DROP COLUMN` anywhere in `lib/core/db/` | Destroys user data with no recovery path | `tool/check_policy.dart` rule `db.destructive_ddl` |
| `store_date_time_values_as_text` in `build.yaml` | Irreversibly changes the storage of every temporal column (#29) | `tool/check_policy.dart` rule `db.banned_build_option` |
| `dateTime()` in any table definition | Same, and it forces one representation onto instants and civil dates | `check_policy` rule `db.drift_datetime` |
| `db.` or a today-schema table class inside a `from*To*` callback | The step breaks the day you add a column in v9 | `check_policy` rule `db.migration_today_schema` |
| `CURRENT_TIMESTAMP`, `date('now')`, `datetime('now')` in any `.dart`/`.drift` file | Decision #47; time arithmetic happens in Dart | `check_policy` rule `time.sql_now_*` — **01's existing rule; this document adds no duplicate** (R54) |
| Bumping `schemaVersion` by two | `stepByStep` has no callback for the skipped hop | Test: snapshot file count == `kSchemaVersion` |
| Regenerating in a follow-up commit | The repo has a schema no snapshot describes | CI no-diff check (§3.6) |
| `assert(() { validateDatabaseSchema(); return true; }())` | Starts a `Future` and returns `true` immediately (#39) | `check_policy` rule `db.async_in_assert` |

---

## 3. The from→to migration test matrix

### 3.1 Why every pair, and not just the last hop

Because a real user's path is not the last hop. A shepherd who bought the app in February 2026 and opens it again in February 2029 runs 1→2→3→…→N in one launch, unattended, with no backup, at the start of the only three weeks of the year the app matters.

`stepByStep` composes edges, so in theory testing each edge is enough. It is not, for two reasons that have both happened to other people:

1. **Steps are not order-independent in practice.** A step that rewrites a table (`TableMigration`, §2.6) copies data with a generated `SELECT`; a later step that changes what "the current schema" means can invalidate an assumption baked into the earlier one. The matrix is where that surfaces.
2. **`migrateAndValidate` validates the terminus, not the path.** It extracts every `CREATE` statement from `sqlite_schema` and compares it semantically against the expected schema at `to`. Only running the real composition proves the real composition lands where you think.

The matrix costs one nested loop and N²/2 sub-second tests. At N = 8 that is 28 tests. There is no version of "we saved time" here.

### 3.2 The test

```dart
// test/drift/migration_matrix_test.dart
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';

import 'generated/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  // Every from -> to pair, not just N-1 -> N. Decision #38.
  for (var from = 1; from < kSchemaVersion; from++) {
    for (var to = from + 1; to <= kSchemaVersion; to++) {
      test('migrates v$from -> v$to', () async {
        final connection = await verifier.startAt(from);
        final db = AppDatabase(connection, seedOnCreate: false);
        addTearDown(db.close);

        await verifier.migrateAndValidate(db, to);

        // Referential integrity, on every path. No generator gives you this.
        final violations =
            await db.customSelect('PRAGMA foreign_key_check;').get();
        expect(violations, isEmpty,
            reason: 'FK violations after v$from -> v$to');

        // The file is still a database, not a pile of pages.
        final quick = await db.customSelect('PRAGMA quick_check;').getSingle();
        expect(quick.data.values.first, 'ok');
      });
    }
  }
}
```

Notes on the API, against the pinned `drift` 2.34.2 / `drift_dev` 2.34.5 (decision-record §5 — no version in this project comes from anywhere else):

- `SchemaVerifier` and `migrateAndValidate` come from `package:drift_dev/api/migrations_native.dart`. The deprecated `api/migrations.dart` is banned (#39).
- `verifier.startAt(from)` returns a `DatabaseConnection` already at that schema version; you hand it to the real database class so the real `MigrationStrategy` runs.
- `seedOnCreate: false` matters: `startAt` does not call `onCreate`, but keeping the flag explicit in tests documents that the seed is not part of what is being validated.

### 3.3 Data integrity — scoped, not universal

`testWithDataIntegrity`-style coverage applies to **the N-1→N pair and to any step containing `alterTable`** (#38). Quadratic data-integrity tests at v1 are busywork; the from→to *schema* matrix is the high-value half.

Write it explicitly rather than through a generated helper whose signature you have not read:

```dart
// import 'generated/schema_v1.dart' as v1s;   <- the per-version companions

test('v1 data survives migration to head', () async {
  final schema = await verifier.schemaAt(1);

  // Write real rows using the v1 companions from test/drift/generated/.
  // These are RAW SQL types: `schema generate` does not apply type
  // converters, so startDate is a String here and an Instant is an int.
  final v1 = v1s.DatabaseAtV1(schema.newConnection());
  await v1.into(v1.seasons).insert(v1s.SeasonsCompanion.insert(
        uid: '019524f7-8a1c-7b3e-9f04-2c9a1e7d55b0',
        year: 2026,
        label: '2026 lambing',
        startDate: '2026-02-01',            // TEXT civil date — decision #29
      ));
  await v1.into(v1.ewes).insert(v1s.EwesCompanion.insert(
        uid: '019524f8-1d02-7c11-8e77-3ab0c4d19e21',
        tag: '412',
        tagDigits: '412',                   // required: no default (03 §5.2)
      ));
  await v1.close();

  final db = AppDatabase(schema.newConnection(), seedOnCreate: false);
  addTearDown(db.close);
  await verifier.migrateAndValidate(db, kSchemaVersion);

  // The uid is the identity that must survive. Not the integer id.
  final ewe = await (db.select(db.ewes)
        ..where((t) => t.uid.equals('019524f8-1d02-7c11-8e77-3ab0c4d19e21')))
      .getSingle();
  expect(ewe.tag, '412');
  expect(ewe.status, 'active');   // the v1 column default survived the hops
});
```

The generated `testWithDataIntegrity` helper is permitted here, on one condition: **read its signature out of `test/drift/generated/schema.dart` before you call it.** Never copy a signature from this document, from note 03, or from a blog post — it is generated code and it tracks the `drift_dev` version you are pinned to.

### 3.4 FTS5 shadow tables — **UNVERIFIED, check on day one**

The `search_docs` fan-in table is indexed by the external-content FTS5 virtual table `search_fts` (#35; declared in `lib/core/db/search.drift`, owned by [`03-data-model-and-schema.md`](03-data-model-and-schema.md) §7). FTS5 creates shadow tables — `search_fts_data`, `search_fts_idx`, `search_fts_docsize`, `search_fts_config` — that appear in `sqlite_schema`. Schema-diffing tools in other ecosystems have historically choked on exactly these ([prisma#8106](https://github.com/prisma/prisma/issues/8106), [rails#52354](https://github.com/rails/rails/pull/52354)).

**Nobody has verified whether drift's `SchemaVerifier` tolerates them.** Therefore:

- Write the matrix test **with FTS5 present in schema v1**, before there is a single real row, so you find out in week one rather than at v4.
- If the verifier rejects the shadow tables, that is the trigger to move note search behind a plain `search_docs` table with a `LIKE`-free ranked query, or to exclude the virtual table from the snapshot — decide it then, with the error in front of you, and record the outcome in this section.
- Do not paper over it by disabling the assertion.

### 3.5 Downgrade

A user who sideloads an older build must get a clear failure. The alternative is a v4 database being read by v2 code, which is silent corruption. The failure surfaces through the global error net (#14) as a dark error screen with one instruction: update the app.

`stepByStep` is understood to throw when `user_version` exceeds `schemaVersion`, but that is library behaviour on a pinned dependency, and this document does not quote a version number it cannot source from §5 of the decision record. **Own the guarantee**:

```dart
// test/drift/downgrade_test.dart
// AppDatabase exposes `schemaVersionOverride` ONLY in this test file's
// eyes: it is a @visibleForTesting final field defaulting to kSchemaVersion,
// and `int get schemaVersion => schemaVersionOverride`.
test('opening a newer file with older code throws, never migrates', () async {
  final verifier = SchemaVerifier(GeneratedHelper());
  final connection = await verifier.startAt(kSchemaVersion);   // the newer file

  // The same file, opened by a build that believes it is one version behind.
  final old = AppDatabase(connection,
      seedOnCreate: false, schemaVersionOverride: kSchemaVersion - 1);
  addTearDown(old.close);

  await expectLater(
    old.customSelect('SELECT 1;').getSingle(),   // forces the open
    throwsA(anything),
  );
});
```

Skip this test while `kSchemaVersion == 1` — there is no lower version to pretend to be — and make it unskippable in the same commit that introduces v2.

### 3.6 The CI no-diff check

```bash
# .github/workflows/ci.yml — the "codegen freshness" step
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev make-migrations
git diff --exit-code -- \
    lib/core/db/ drift_schemas/ test/drift/generated/ \
  || { echo "::error::Generated schema artefacts are stale. Run make-migrations and commit."; exit 1; }
```

This is the single most valuable line of CI in the project. It proves that the committed snapshot describes the committed schema — which is the assumption every other migration test rests on.

### 3.7 Gates

| Gate | Asserts | Blocking |
|---|---|---|
| `test/drift/migration_matrix_test.dart` | Every from→to pair validates; `foreign_key_check` empty; `quick_check` ok | Yes, every push |
| N-1→N data-integrity test | Rows written at N-1 are readable and correct at N | Yes |
| `test/drift/downgrade_test.dart` (§3.5) | Opening a v(N) file with v(N-1) code throws instead of migrating | Yes, from schema v2 onward |
| Snapshot-count test | `drift_schemas/` contains exactly `kSchemaVersion` files | Yes |
| Codegen freshness (§3.6) | `make-migrations` produces no diff | Yes |
| `check_policy` migration rules (§2.10) | No destructive DDL, no today-schema references, no SQL-side time | Yes |

---

## 4. Media

### 4.1 Filesystem, not BLOBs

Photos are 300 KB – 5 MB and voice notes 100 KB – 1 MB. SQLite's own measurements ([fasterthanfs.html](https://www.sqlite.org/fasterthanfs.html)) find small BLOBs *faster* than files and a crossover somewhere in the hundreds of KB, varying with page size and platform; **the exact figure is not worth pinning down here**, because every asset this app stores is several times larger than the highest crossover that page reports. Three app-specific reasons make it decisive anyway (#40): `VACUUM INTO` copies the whole database, so inline photos would make every diagnostics snapshot gigabytes; Android Auto Backup caps at 25 MB per app, so inline photos would silently kill the backup of the *records* too; and a loose file can be recovered by hand from a device backup even when the database is broken, while a BLOB cannot.

**The database holds the index. The filesystem holds the bytes.**

### 4.2 The layout

```
<getApplicationSupportDirectory()>/
  shed_book.sqlite
  shed_book.sqlite-wal
  shed_book.sqlite-shm
  media/
    2026/03/019524f7-8a1c-7b3e-9f04-2c9a1e7d55b0.jpg
    2026/03/019524f8-1d02-7c11-8e77-3ab0c4d19e21.m4a
    .trash/
      2026-07-27/2026/03/019523aa-....jpg
  pre_migration/
    shed_book-v3.sqlite            # §2.8, at most one file
  restore_staging/                 # §7, exists only during a restore
  restore_rollback/                # §7, the previous database, one launch
  diagnostics/
    shed_book.log                  # #123, 256 KB cap, one rotation
```

- **Same container as the database.** They ride the same OS backup and the same device restore. Split them across `Documents/` and `Application Support/` and you will one day restore a database whose photos are all missing.
- **Year/month shards** keep any single directory to a few hundred entries, which keeps the orphan sweep's directory walk fast.
- **Filename = the media asset's UUID v7 + extension.** Never the tag number (tags get corrected, and a rename orphans the row). Never a sequence number (collisions after a restore). v7's time-ordered prefix means a directory listing sorts chronologically for free.
- **Exports never go here.** CSV, PDF and JSON are written to `getTemporaryDirectory()` and handed straight to the share sheet; that directory is excluded from iCloud and from Android Auto Backup, so stale exports never inflate a user's backup. Sweep it at launch, off the critical path.

### 4.3 The relative-path rule

**Never store an absolute path.** On iOS the data container is `/var/mobile/Containers/Data/Application/<UUID>/…` and that UUID is not stable — [flutter/flutter#23957](https://github.com/flutter/flutter/issues/23957) reports three *different* container UUIDs across successive launches of the same app. Apple's File System Programming Guide is prescriptive about it: locate the directory through the system frameworks first, then build the path.

It bites after an app update, after a device restore, after every re-install from Xcode during development, and after a device-to-device transfer. On Android the path happens to be stable (`/data/data/<pkg>/files/`), **which is exactly why this bug ships** — it never reproduces on the developer's Android phone.

```dart
// lib/data/media_store.dart  (one of the six gateways — CONVENTIONS §2.12)
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/db/uid.dart';           // newUid() — the one uuid v7 source (R15)
import '../core/time/app_clock.dart';   // appNow() — the one clock, #46

/// The only type that knows where media bytes live.
/// lib/features/** never constructs a File. See 01-architecture.md.
final class MediaStore {
  Directory? _rootCache;

  /// Resolved fresh every run. Deliberately never persisted anywhere.
  Future<Directory> root() async {
    final cached = _rootCache;
    if (cached != null) return cached;
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'media'));
    await dir.create(recursive: true);
    return _rootCache = dir;
  }

  /// The ONLY string that ever reaches the database.
  /// Always POSIX-separated: "2026/03/019524f7-…-55b0.jpg".
  String newRelativePath(String extension) {
    // appNow() is the single wall-clock reader (#46). .local because the
    // shard is a human-legible YYYY/MM, not an instant.
    final now = appNow().local;
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    return p.posix.join(year, month, '${newUid()}.$extension');
  }

  /// Defence in depth. The three `CHECK`s below make an escaping path
  /// unstorable, but a resolver that *can* leave its root is not a resolver.
  Future<File> resolve(String relativePath) async {
    final rootDir = await root();
    final full = p.normalize(p.join(rootDir.path, relativePath));
    if (!p.isWithin(rootDir.path, full)) {
      throw ArgumentError.value(
          relativePath, 'relativePath', 'escapes the media root');
    }
    return File(full);
  }

  /// Write bytes to a temp name, fsync, then rename. Rename within one
  /// filesystem is atomic, so a reader never sees a half-written photo.
  Future<File> writeAtomically(String relativePath, List<int> bytes) async {
    final target = await resolve(relativePath);
    await target.parent.create(recursive: true);
    final staging = File('${target.path}.part');
    final handle = await staging.open(mode: FileMode.writeOnly);
    try {
      await handle.writeFrom(bytes);
      await handle.flush();
    } finally {
      await handle.close();
    }
    return staging.rename(target.path);
  }
}
```

The database refuses anything else. `media_assets` is owned by [`03-data-model-and-schema.md`](03-data-model-and-schema.md) §5.11 and must carry all three of these before the first snapshot is generated:

```sql
CHECK (relative_path NOT LIKE '/%')                                -- no absolute path
CHECK (relative_path GLOB '[0-9][0-9][0-9][0-9]/[0-9][0-9]/*.*')   -- YYYY/MM/<name>.<ext>
CHECK (relative_path NOT GLOB '*/*/*/*')                           -- exactly two separators
```

> **Divergence to close.** 03 §5.11 currently lists only the first of the three. The other two must be added **there**, in the commit before `drift_schemas/drift_schema_v1.json` is generated — a `CHECK` cannot be added by `ALTER TABLE` afterwards without the full table rebuild of §2.6, on the one table whose rows point at the user's photographs.

Be precise about what each buys, because it is easy to overclaim here. SQLite's `GLOB` `*` **matches `/`**, so the second `CHECK` alone does *not* rule out `2026/03/../../x.jpg`. The third one does: two separators are already spent on `YYYY/MM/`, so no further path segment exists to traverse with. Absolute paths and Windows separators fall to the first and second. All three are asserted against the committed schema JSON in `test/policy/`, so a future refactor cannot quietly drop them — and none of them is the real defence, which is that `relative_path` is never user-authored: it comes only from `MediaStore.newRelativePath()`, and `MediaStore.resolve()` re-checks containment above.

**`missingSince` is an `INTEGER` instant**, not a `dateTime()` column. Note 03 §4.10 declares `missingSince = dateTime().nullable()()`; decision #30 says every `dateTime()` in that schema must be rewritten before the first snapshot is generated. 03 §5.11 already ships the rewritten form, and this is the spelling to copy — converter first, `nullable()` second:

```dart
late final missingSince =
    integer().map(const InstantConverter()).nullable()();
```

### 4.4 Capture

The capture flow is three hops, and each hop is owned by exactly one class (CONVENTIONS R47, §2.12): **`CameraService.pick()` → `MediaStore` compresses and writes → `NoteRepository` inserts the `media_assets` row.** `CameraService` and `VoiceRecorder` each wrap exactly one plugin, so the hand-written fake in `test/support/` exercises the real path.

**Photos** (#77, #40). `image_picker` gives you the system camera UI and the system photo picker and merges **zero** Android permissions. `flutter_image_compress` downscales natively; its `keepExif` defaults to `false`, which strips GPS — keep the default.

```dart
// Step 1 — lib/data/camera_service.dart, the ONE image_picker call site
// (R9, R47). CameraService owns `pickImage` and `retrieveLostData` and
// nothing else.
final picked = await _camera.pick();     // ImagePicker().pickImage(camera)
if (picked == null) return null;

// Step 2 — lib/data/media_store.dart. MediaStore owns the media root,
// newRelativePath, resolve, writeAtomically and the flutter_image_compress
// downscale (R47). It never touches image_picker, so nothing else in lib/
// constructs a media File and there is one answer to "where does a photo go?".
final relative = newRelativePath('jpg');
final target = await resolve(relative);
await target.parent.create(recursive: true);

final result = await FlutterImageCompress.compressAndGetFile(
  picked.path,
  '${target.path}.part',
  minWidth: 2048,
  minHeight: 2048,
  quality: 80,
  format: CompressFormat.jpeg,
  // keepExif defaults to false. Do not set it true: it re-attaches GPS.
);

// Step 3 — lib/data/note_repository.dart inserts the media_assets row (§4.6).
```

> **Needs verification before shipping.** `flutter_image_compress`'s `minWidth`/`minHeight` are documented as *minimums*, not caps: the plugin scales proportionally and will not produce an image smaller than either bound. Passing `2048/2048` may therefore cap the **shorter** edge and leave the longer edge above 2048. Decision #40 specifies *longest edge 2048 px*. Measure it on one portrait and one landscape photo from a real phone; if the parameters behave as floors, derive the pair from the source aspect ratio before compressing. Ship the assertion either way: a test opens the output and fails if `max(width, height) > 2048` or `bytes > 900 KB`.

Also from #77 and #125: `retrieveLostData()` is a `CameraService` method and is called on resume (Android can kill the app while the camera activity is foreground), and initialise `BackgroundIsolateBinaryMessenger.ensureInitialized` if you ever run the compressor off the root isolate.

**Voice notes** (#76, `record` 7.1.1). The class is `AudioRecorder`, not `Record`. AAC-LC in `.m4a`, mono. **Never Opus** — its container differs per platform, which breaks a cross-platform restore (#40).

```dart
// lib/data/voice_recorder.dart — the ONE `record` call site (R9, R47).
// VoiceRecorder wraps exactly one plugin; MediaStore still supplies the path.
final recorder = AudioRecorder();
final relative = _store.newRelativePath('m4a');
final target = await _store.resolve(relative);
await target.parent.create(recursive: true);

await recorder.start(
  const RecordConfig(
    encoder: AudioEncoder.aacLc,
    bitRate: 32000,
    numChannels: 1,
    sampleRate: 44100,
  ),
  path: target.path,
);
```

> **Open, owner-blocked (§7.1 #18): the voice-note cap is 60 s or 120 s.** Implement it as a single constant `kVoiceNoteMaxSeconds` in `lib/data/media_limits.dart`, referenced everywhere including the storage-budget test, so the answer is a one-line change. The budget below is given at both values. Until the owner answers, ship 60 s: it is the lower storage figure and the recoverable mistake — raising a cap orphans nothing, lowering one makes existing recordings unreproducible.

Write `byte_size` into the row at capture so Settings ▸ Diagnostics can show "Photos: 187 MB (412 files)" without walking the filesystem.

> **`media_assets.sha256` is `NULL` in v1.** There is no hash package in the verified dependency table (§5 of the decision record), and no package enters this project that is not in that table. If a content hash becomes necessary, audit `crypto` by c1's method — pub.dev API, publisher, transitive graph, merged manifest — and record the verified version in §5 first. See §6.6 for the dependency-free integrity check the backup uses instead.

### 4.5 The write ordering rule

**The record commits first. The media attaches second.** This is what makes "assume the phone dies" (spec §5) true in the presence of a 700 KB file write.

1. Commit the event row. ~500 bytes; succeeds on a phone with 200 KB free.
2. The UI shows the event as saved. **The shepherd can walk away here and nothing is lost.**
3. Compress and write the media to `<relative>.part`, then `rename` into place (atomic within one filesystem).
4. Commit a second, tiny transaction inserting the `media_assets` row.

If step 3 or 4 fails, the lambing record already exists and is correct. Show a persistent, dismissible chip on the record — *"Photo not saved — storage full"* — and offer **Retry photo** on the ewe card, so recovery after freeing space costs one tap instead of re-entering the event. Never a modal on Quick Entry (spec §5).

### 4.6 Disk full at 3am

Writes return a sealed `WriteOutcome` (#13), so a full disk is a value, not an exception escaping into the UI. The `media_assets` insert of §4.5 step 4 is the write most likely to meet a full disk, and it is an ordinary `_write` verb:

```dart
// lib/data/note_repository.dart — NoteRepository owns writes to `notes` and
// `media_assets` (CONVENTIONS §2.13, R47).
// _write() is defined once in 01-architecture.md §5.3; shedFailureFrom(Object)
// lives in lib/data/failure_mapping.dart (R4).
// This repository holds a MediaStore; it does not open files itself.
Future<WriteOutcome> attachPhoto(
  LambingId lambing, {
  required String relativePath,     // relative only — §4.3
  required int byteSize,
}) {
  final now = appNow();             // read the clock once per mutation
  return _write(() async {
    await _db.into(_db.mediaAssets).insert(
          MediaAssetsCompanion.insert(
            uid: newUid(),          // lib/core/db/uid.dart — R15
            createdAt: now,
            updatedAt: now,
            relativePath: relativePath,
            kind: 'photo',
            byteSize: byteSize,
            lambing: Value(lambing.value),
          ),
        );
  });
}
```

Three things that snippet is deliberately **not** doing, each of which is a bug people write here:

- **It does not write `on SqliteException catch (e)`.** `drift_flutter` runs SQLite on a background isolate, so the exception arrives wrapped in a `DriftRemoteException` and a bare `on SqliteException` clause **never matches**. `shedFailureFrom(Object)` in `lib/data/failure_mapping.dart` (01 §5.3, R4 — there is no `ShedFailure.from`) unwraps once, then maps `SQLITE_FULL` (13) and `SQLITE_IOERR` (10) to `DiskFull`, whose `userMessage` is the sentence the SnackBar shows. Log `resultCode`/`extendedResultCode`, never the message (#124).
- **It does not `rethrow`.** A write verb that sometimes throws and sometimes returns forces every call site to handle both.
- **It does not return an id.** `beginLambing` and `addLamb` are the only two verbs that return an id and **throw** instead (01 §4.2) — a full disk there lands on the global error net, which is correct: there is no id to hand back and the screen cannot open. Every other write, including this one, returns `WriteOutcome` — the **non-generic** sealed type in `lib/core/write_outcome.dart`, whose committed variant is `WriteCommitted({int? insertedId, List<Warning> warnings})` (R3). There is no `WriteOutcome<T>`, and `warnings` is populated by the controller, never here (R53).

The transaction rolls back atomically, so there is no half-written record. The controller **holds the in-memory record and does not navigate away**, so a retry after the user deletes a video costs one tap. `PRAGMA temp_store = MEMORY` (§2.8) removes a whole class of `SQLITE_FULL` that fires even with free space on the main partition, because temp files landed elsewhere.

Storage warnings, all non-blocking (#123, note 08 §9.3):

| Condition | Action |
|---|---|
| App media > 1 GB | A line in Settings ▸ Diagnostics: "Photos: 1.2 GB. You can export and delete a past season." Never a modal. |
| Device free < 500 MB | One banner, on the Export screen, when it is next opened |
| Device free < 100 MB | Disable **new photo attachment** only — grey the camera button with the reason on it. Text entry keeps working. |
| `SQLITE_FULL` | The sheet above, with Retry and "Free up space" |

Free-space figures need ~20 lines of platform channel (`StatFs.getAvailableBytes()` / `NSFileManager.attributesOfFileSystem(forPath:)`); `disk_space_plus` is rejected (unverified uploader, decision-record §5.3). Until that channel exists, the two free-space rows above are not implemented and the Diagnostics screen says so rather than showing a wrong number. **When it does land, `PrivacyInfo.xcprivacy` gains the `E174.1` disk-space reason code in the same commit** (#93) — it is declared *only if* free space is actually queried, so shipping the channel and forgetting the manifest is an App Review finding.

### 4.7 The storage budget, 400 ewes, one season

| Item | Assumption | Size |
|---|---|---|
| Database, one 400-ewe season (~5,000 rows) | records only | **2–5 MB** |
| Database, ten seasons (~50,000 rows) | | **20–50 MB** |
| Photo, 2048 px longest edge, JPEG q80 | **estimate — measure it** | **500–900 KB** |
| Voice note, AAC-LC mono 32 kbps, 60 s | | ~240 KB |
| Voice note, 120 s | | ~480 KB |

| Season scenario (400 ewes) | Media | Total |
|---|---|---|
| Conservative — 25 % of lambings get one photo | 100 × 700 KB | **~70 MB** |
| Typical — every lambing gets a photo, 10 % a 120 s voice note | 400 × 700 KB + 40 × 480 KB | **~300 MB** |
| Heavy — 3 photos per lambing, 25 % voice notes | 1200 × 700 KB + 100 × 480 KB | **~890 MB** |
| **If you ever store the camera original** | 1200 × 3 MB | **~3.6 GB** |

The last row is the failure case and it is entirely self-inflicted. **Downscale at capture; never keep the original.** The photo-size figures are extrapolated from note 08's measurements at 1600 px and must be re-measured at 2048 px on a real device before they are quoted anywhere user-facing.

The ratio — **~300 MB of media against a ~5 MB database** — is why media is not in the database, why media is excluded from Android cloud backup (§9), and why the v1 JSON backup is records-only (#85).

### 4.8 Deleting media

Media is never deleted synchronously in response to a user action, and never deleted at all by a sweep. It is **moved to `.trash/<yyyy-MM-dd>/<original relative path>`** and purged from there after 30 days, or sooner if `.trash` exceeds 100 MB (oldest first). Settings shows "Recoverable files: 12 (deleted 3 days ago)". This is spec §12.4 applied to bytes: the app does not silently destroy the user's things.

### 4.9 Anti-patterns and gates

| Banned | Why | Caught by |
|---|---|---|
| An absolute path, a Windows separator or a `..` segment in `media_assets.relative_path` | Dead after every iOS update and restore; the last one leaves the container | The three `CHECK`s (§4.3); `MediaStore.resolve()`'s containment check; a schema-JSON policy test; a unit test per shape asserting the insert throws |
| `BLOB` columns for photos or audio | §4.1 | `check_policy` rule `db.blob_column` |
| `getApplicationSupportDirectory()` outside `connection.dart` and `media_store.dart` | Two roots means two answers | `check_policy` rule `layer.path_provider` |
| `File(` anywhere under `lib/features/**` | The UI layer does not know the filesystem exists (#9) | `check_policy` rule `layer.features` |
| Storing the camera original | 3.6 GB per season | Output-size assertion in the capture test |
| `AudioEncoder.opus` | Container differs per platform → broken cross-platform restore | `check_policy` rule `media.opus` — one row per banned identifier (R54) |
| `DateTime.now()` in path construction | Decision #46 | `check_policy` rule `time.dart_clock` — **01's existing rule; this document adds no duplicate** (R54) |
| Deleting a `media_assets` row because the file is gone | Makes the app lie by omission | Review checklist; the sweep test asserts the row survives |

---

## 5. Orphan sweeps

Media and rows can diverge in both directions, and both directions are normal, not exceptional. Neither sweep deletes anything.

### 5.1 Direction 1 — files with no row

Causes: capture wrote the file and the process died before the attach transaction; a restore brought files the new database does not reference; a `.part` file left by a killed write.

```dart
// lib/data/media_sweeper.dart
Future<SweepReport> sweepOrphanFiles() async {
  final root = await _store.root();
  final known = await _db.allMediaRelativePaths(); // one SELECT, a Set<String>
  final today = LocalDate.of(appNow()).iso;        // 'YYYY-MM-DD' — 05 §2.4
  var moved = 0;

  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final rel = p.posix.joinAll(
        p.split(p.relative(entity.path, from: root.path)));
    if (rel.startsWith('.trash/')) continue;
    if (rel.endsWith('.part')) {
      // A killed write. Nothing ever referenced it. Safe to remove.
      await entity.delete();
      continue;
    }
    if (known.contains(rel)) continue;

    final grave = File(p.join(root.path, '.trash', today, rel));
    await grave.parent.create(recursive: true);
    await entity.rename(grave.path);   // never delete — §4.8
    moved++;
  }
  return SweepReport(orphanFilesTrashed: moved);
}
```

### 5.2 Direction 2 — rows with no file

Causes: the user wiped the container; an Android cloud restore that excluded `media/` (§9); a records-only JSON restore (§7.7).

```dart
Future<SweepReport> sweepMissingFiles() async {
  final assets = await _db.mediaAssetsNotYetMissing(); // WHERE missing_since IS NULL
  var flagged = 0;

  await _db.transaction(() async {
    for (final asset in assets) {
      final file = await _store.resolve(asset.relativePath);
      if (await file.exists()) continue;
      await _db.flagMediaMissing(asset.id, appNow());
      flagged++;
    }
  });
  return SweepReport(rowsFlaggedMissing: flagged);
}
```

`appNow()` is the app's single wall-clock reader, defined once in `lib/core/time/app_clock.dart` as `Instant(clock.now().millisecondsSinceEpoch)` — see [`05-domain-correctness.md`](05-domain-correctness.md) §1.3. **Every clock read in this document goes through it**: the media shard in §4.3, the trash date above, the snapshot filename in §8.2. There is no `Instant.now()`, no second clock abstraction and no `DateTime.now()` outside `app_clock.dart` (#46).

**Do not delete the row.** *"Photo taken 14 March 03:22 — file no longer on this phone"* is a true statement and a useful one; deleting it makes the app lie by omission. Spec §12.4 applied to media. A row that is later found again (the user restored the container) is un-flagged by the same sweep — set `missing_since` back to `NULL` when the file reappears, because "it is here now" is also true.

### 5.3 When the sweeps run

- **Never before the first frame.** Nothing in the startup sequence may sit between the shepherd's thumb and a saved lambing event (#21). Both sweeps run from a post-frame callback after the first real screen has rendered, and both yield: the file walk is chunked so no single microtask exceeds ~8 ms.
- **Once per launch**, and once after a restore completes (§7.7). Not on resume: a 20-minute pocket gap does not create orphans.
- **Not while a write is in flight.** The sweeper is handed the one `AppDatabase` instance every repository already uses, so its statements queue behind writes on the same connection. It never opens a second connection, and it lives in `lib/data/`, which is the only layer permitted to write (01 §3, rule 8).
- **Reported, not announced.** The counts go to Settings ▸ Diagnostics. A sweep that trashes 3 files does not interrupt anyone.

### 5.4 Gates

| Gate | Asserts |
|---|---|
| Sweep test: file with no row | The file lands in `.trash/<date>/<rel>` and is **not** deleted |
| Sweep test: row with no file | `missing_since` is set; the row still exists; the ewe card renders the "not on this phone" state |
| Sweep test: file reappears | `missing_since` returns to `NULL` |
| Sweep test: `.part` file | Deleted, and no row is touched |
| Startup trace | Neither sweep appears before `timeToFirstFrameMicros` in `build/start_up_info.json` |

---

## 6. The backup format

### 6.1 What the backup is

**JSON is *the* backup and *the* restore format** (#84). Spec §7.9 names JSON only. It is cross-device, inspectable in a text editor, and the only format that survives a schema change between the exporting app and the importing app. `VACUUM INTO` is not a backup (§8). `File.copy` of the database is a bug (§8.1). Export is never gated by the free tier, ever (#86) — paywalling the only backup mechanism in an app with no cloud is a data-hostage pattern.

**Records-only for v1** (#85). Media bytes are not in the backup. The export screen says so in plain words, and the backup header records what was left behind so the restore screen can say it too.

### 6.2 The backup header

The `format` / `formatVersion` / `schema` / `counts` / `checksum` block below is the **`BackupHeader`** (CONVENTIONS §2.8, R65). It is never called "the envelope": `ExportEnvelope` is a different type — the disclaimer-bearing value in `lib/domain/policy/export_envelope.dart` that every export writer takes ([`05-domain-correctness.md`](05-domain-correctness.md)). `BackupHeader` lives in `lib/data/`; [`09-export-formats.md`](09-export-formats.md) places the file.

```jsonc
{
  "format": "shed-book-backup",
  "formatVersion": 1,              // the HEADER's version, independent of `schema`
  "schema": 3,                     // the database schemaVersion this was written from
  "appVersion": "1.2.0+41",
  "exportedAtUtc": "2026-07-27T21:04:11.482Z",
  "exportedAtOffsetMinutes": 60,   // context only — the phone's offset at export
  "exportedAtZoneAbbreviation": "IST",
  "notice": "…Disclaimers.exportFooter, referenced never retyped…",
  "checksum": { "algorithm": "fnv1a64", "value": "9f2b1c04a77e3d51" },
  "counts": { "seasons": 3, "ewes": 412, "lambings": 398, "lambs": 861,
              "treatments": 145, "media_assets": 452 },
  "media": {
    "included": false,             // v1 is records-only — decision #85
    "count": 452,
    "bytes": 297103882
  },
  "tables": {
    "seasons":   [ /* flat objects; keys are the SQLite column names */ ],
    "ewes":      [],
    "ewe_seasons": [],
    "lambings":  [],
    "lambs":     [],
    "foster_events": [],
    "pens": [], "pen_occupancies": [], "pen_occupancy_lambs": [],
    "treatments": [], "treatment_withdrawals": [],
    "care_events": [], "ewe_observations": [],
    "reminders": [], "notes": [], "media_assets": [],
    "ewe_touches": [],
    "app_settings": [], "terminology_overrides": [], "reminder_rules": []
  }
}
```

### 6.3 Field rules

| Rule | Detail |
|---|---|
| **Column names are SQLite column names.** | `snake_case`, exactly as in the schema. No renaming layer, no camelCase, no "friendly" names. The importer maps by name; a rename layer is a second schema to keep in sync. The one mechanical exception is the FK rule in the next row, and it is mechanical precisely so it needs no map. |
| **Identity is `uid`, never `id`.** | Integer primary keys are re-issued on import, so no integer FK is exported. Each FK column is emitted under its own name with any trailing `_id` replaced by `_uid`, and a bare column name (`ewe`, `lambing`, `note` — 03's convention) gaining `_uid`: `ewe` → `ewe_uid`, `lambing` → `lambing_uid`. The value is the **parent row's** `uid`. Decision #32: import is an upsert on `uid`, never on `tag`. |
| **Instants are ISO-8601 UTC with milliseconds and a `Z`.** | `"2026-03-14T03:20:42.015Z"`. Stored as `INTEGER` epoch millis (#29); the round trip `Instant → ISO → Instant` is exact and is property-tested. Legibility in 2036 is worth the four extra bytes. |
| **Civil dates are `"YYYY-MM-DD"`,** unchanged from storage. | A civil date is not an instant and never acquires a time or a zone on the way through the file. |
| **Timestamp provenance travels as a unit.** | `effective`, `capturedAt`, `originalEffective`, `source` — all four columns or none. A backup that drops the provenance columns launders an edited timestamp into an auto-captured one, which is a spec §12.5 violation committed by the file format. |
| **There are no floating-point numbers in a backup.** | Mass is integer grams, temperature integer milli-°C (#56); statistics are derived and not stored. This is asserted by a test over the encoded body, and it removes the hardest canonicalisation problem in §6.6. |
| **`NULL` is `null`, and absent means absent.** | An omitted key and an explicit `null` are treated identically by the importer. Do not invent a sentinel. |
| **Booleans are `0`/`1`,** matching `STRICT` INTEGER storage. | No `true`/`false`; the column is an INTEGER and the file mirrors the column. |

### 6.4 What is in, and what is not

| Included | Excluded, and why |
|---|---|
| Every table that holds a user-authored fact: seasons, ewes, ewe-seasons, lambings, lambs, foster events, pens, pen occupancies, treatments, treatment withdrawals, care events, ewe observations, reminders, notes, media asset **rows**, ewe touches, app settings, terminology overrides, reminder rules | **Media bytes** — records-only for v1 (#85). The header records the count and total size so restore can be honest about it. |
| | **The entitlement / purchase row** — never exported, and ignored if present on import (#88). Restoring your neighbour's backup must not unlock your app. |
| | **`search_docs`, `search_fts` and every FTS5 shadow table** — derived. `search_docs` is refilled by the source-table triggers as the notes, treatments and observations are inserted at §7.2 step 6; `search_fts` is then rebuilt in one statement at step 7. Exporting them would double-index on restore. |
| | **SQL views** (`current_rearing_dam`, `ewe_summary`, …) — derived by definition. |
| | **The diagnostics log** — it is a redacted local file with its own explicit share action (#123). It is not part of the user's records. |
| | **`sqlite_sequence`** — an implementation detail of `AUTOINCREMENT`; the importer re-issues integer ids anyway. |

The rule to remember: **every non-derived table is exported except the three named exceptions.** If you add a table, it is in the backup unless you write down why it is not, in this table, in the same commit.

### 6.5 Forward compatibility

| Situation | Behaviour |
|---|---|
| `formatVersion` > the app's known `BackupHeader` version | **Refuse.** "This backup was made by a newer version of Shed Book. Update the app and try again." |
| `schema` > the app's `kSchemaVersion` | **Refuse**, with the same wording (#73). Guessing at a newer schema is spec §12.4 applied to restore. |
| `schema` < the app's `kSchemaVersion` | **Accept.** This is the normal case: a backup taken in 2027 restored onto a 2029 app. The importer writes into today's schema (§6.7). |
| A column in the file that today's table does not have | **Preserve it** into the row's `unknown_json` column rather than dropping it, and re-emit it on the next export. |
| A column today's table has that the file does not | Apply the declared import default (§6.7). |
| An unknown *table* in `tables` | Preserve the whole array into `app_settings.unknown_json` under its table name, and log it. Never drop it silently. |

**`unknown_json`** is a nullable `TEXT` column on every restorable table, `NULL` in the normal case, carrying a JSON object of unrecognised keys after an import, with `CHECK (unknown_json IS NULL OR json_valid(unknown_json))`. (Decision #73 writes it "a `_unknown` JSON column"; `unknown_json` is that column, spelled to 03's `snake_case`-no-leading-underscore convention. One column, not two.) Its job is narrow and worth stating: it makes an **import → export round trip lossless**, so a user who restores onto an older build and re-exports has not silently destroyed a newer field. It is not a mechanism for importing from the future — that is refused above.

*Rejected: a single side table `import_residue(table_name, row_uid, json)`.* One table instead of eighteen columns, but it needs a join on every export and its rows cannot have a foreign key to a parent in an arbitrary table, so they go stale the moment a parent row is deleted. The column wins.

### 6.6 Integrity

The backup carries a **corruption check, not a tamper check**, and the export screen must not imply otherwise.

- `counts` per table must equal the number of rows actually parsed, and then the number of rows actually inserted. Two independent comparisons.
- `checksum.value` is FNV-1a 64-bit over the UTF-8 bytes of the **canonical** encoding of the `tables` value: object keys sorted ascending by code unit, no insignificant whitespace, integers only (§6.3 guarantees no doubles). ~15 lines of Dart, no dependency, deterministic, and it catches the failure it exists for: a truncated file from a share sheet, an email client that mangled the bytes, a half-written file from a full disk.
- A cryptographic digest would need `crypto`, which is **not in the verified dependency table**, so it is not in this app. If a real digest is ever required, audit `crypto` by c1's method and record it in §5 of the decision record first. Until then the export screen says *"checks the file is complete"* and never *"verifies the file is authentic"*.
- Any failure aborts before the confirmation screen is ever shown, with the reason. **Refuse a corrupt file; never half-import one.**

### 6.7 How the format survives a schema migration

The exporter always writes today's schema. The importer always writes into today's schema. The only hard case is a column that exists today and did not exist in the backup, and it has exactly one rule:

> **Any migration that adds a `NOT NULL` column with no database default must add an entry to `lib/data/import_defaults.dart` in the same commit.**

```dart
// lib/data/import_defaults.dart
/// Value written when a restored row predates the column.
/// STRUCTURAL values only — never a domain value the user did not enter (§2.7).
const importDefaults = <String, Map<String, Object?>>{
  'lambings': {
    // Added in schema v3. Older backups have no such column.
    'recorded_source': 'auto',      // matches what v2 rows already meant
  },
  'treatments': {
    'voided_at': null,              // nullable — listed for documentation only
  },
};
```

CI proves the map is complete: a test reads the committed `drift_schemas/drift_schema_v<kSchemaVersion>.json`, enumerates every `NOT NULL` column with no `defaultValue` and no `clientDefault`, and asserts each one is either a primary key, a `uid`, or present in `importDefaults`. That single test is what stops a v4 app from refusing to restore a v2 backup on the night it matters.

Two more rules that keep this tractable:

- **Column renames are banned** (§2.1 rule 4). A rename would need a per-version alias map, which is a second migration surface.
- **A column's fallback may never be a domain value.** `withdrawal_days` has no default and never will (#51, #52): a treatment row imported from a schema that predates `treatment_withdrawals` produces **no** withdrawal row, which the sealed type reads as `WithdrawalNotRecorded`. That is the correct answer and it is the only correct answer.

### 6.8 Size and where it runs

400 ewes of text over three seasons is low single-digit MB; ten seasons is plausibly 20–50 MB of JSON. At that size `jsonEncode` on the UI isolate is milliseconds-to-tens-of-milliseconds and does not need an isolate (#125 — only PDF generation and image downscaling go off-isolate).

**The tripwire:** if the encoded backup ever exceeds 20 MB, measure it before assuming it is still fine. Peak heap during `jsonEncode` is roughly twice the output, and an OOM kill during "export my season" is precisely the moment the user is trying to protect their data. If it grows past the tripwire, the fix is a streaming writer that emits one table at a time to an `IOSink` — not an isolate, because a drift connection cannot cross an isolate boundary (#125).

### 6.9 Anti-patterns and gates

| Banned | Why | Caught by |
|---|---|---|
| Exporting integer primary keys as identity | Renumbering on import rewrites every FK — a bug farm | Round-trip test: ids differ, `uid`s match |
| Base64 media inline | 130 MB → ~175 MB inside one JSON string, built in memory | `check_policy` rule `copy.base64_backup` |
| Exporting the entitlement row | Restoring a neighbour's backup would unlock the app | Fixture test: a backup with `unlocked: 1` imports to `unlocked = 0` |
| A `double` anywhere in the body | Breaks canonical encoding and the checksum | Test over the encoded body |
| Re-typing the disclaimer string | Decision #62 | `check_policy` rule `copy.disclaimer_retyped` |
| Adding a `NOT NULL` column without an `importDefaults` entry | A future app cannot restore an older backup | The completeness test in §6.7 |
| A "merge" import option | A merge UI at 3am is a data-loss generator (#73) | Review; there is no merge code to call |

---

## 7. Restore

Restore is the most destructive operation in the app and the only recovery path that exists. Design it as if it will be run, once, at 04:00, by an exhausted person on a new phone, with one file and no second chance — because that is the only time anyone will ever run it.

### 7.1 The rule

**Replace everything, atomically, through one code path** (#73). Import into a *new* SQLite file beside the live one, validate it completely, and only then swap. Never merge into the live database. Never offer merge as an option.

`tool/seed.dart` writes its deterministic fixtures **through this same path** (#74):

```bash
dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42
```

That is not convenience. It makes the seed script a continuous test of the one code path where a bug loses five seasons, and it is why `test/fixtures/flock_400_3seasons.json` and `flock_15_at_cap.json` are committed backup files rather than ad-hoc fixtures.

### 7.2 The flow

| # | Step | Destructive? | If it fails |
|---|---|---|---|
| 0 | Entered only from Settings ▸ Backup & Restore. Never reachable from Quick Entry, Lambing Entry or the Pen Board. The action runs through `WriteController.guard()` so a cold-fingered double-tap cannot start two restores (#22). | No | — |
| 1 | Pick the file with `file_selector` (`ACTION_OPEN_DOCUMENT` / `UIDocumentPickerViewController`, no storage permission — #81). **Copy it immediately** to `<temp>/restore/incoming.json`; on Android the picked URI can be a one-shot grant. | No | Abort, nothing said |
| 2 | **Sniff the first 512 bytes** (#81 — accept `application/octet-stream` and validate ourselves): first non-whitespace byte `{` → JSON; `PK\x03\x04` → a ZIP, refuse with *"This looks like a photo archive. Shed Book restores the records file (.json)."*; `SQLite format 3\0` → refuse with *"This is a diagnostics copy of a database, not a backup. It cannot be restored in the app."*; anything else → refuse. | No | Abort with the reason |
| 3 | Parse and validate the `BackupHeader`: `format`, `formatVersion`, `schema ≤ kSchemaVersion`, `checksum`, `counts` (§6.5, §6.6). | No | Abort with the reason |
| 4 | **Confirmation screen** (§7.3). | No | Abort |
| 5 | Delete any stale `restore_staging/`. Create `<appSupport>/restore_staging/shed_book.sqlite` and open it as `AppDatabase(conn, seedOnCreate: false)`, so `onCreate` builds today's schema with **no** first-run season. | No | Abort; delete staging |
| 6 | Import in **one transaction**, parents before children in a fixed topological order, `PRAGMA defer_foreign_keys = ON` inside the transaction (never `foreign_keys = OFF`, which is a no-op inside a transaction). Resolve every `*_uid` to the new integer id from a map built as each parent is inserted. Entitlement rows are skipped and logged. **If the backup carries no season, `seedFirstRun` runs at the end of this same transaction** (#42, #74): a restored database is never seasonless, because every event table's `season` is `NOT NULL`. | No | Roll back; delete staging; live database untouched |
| 7 | **Validate the staging database, still before any destruction:** per-table `COUNT(*)` equals `counts`; `PRAGMA foreign_key_check` returns zero rows; `PRAGMA quick_check` returns `ok`; `app_settings` has exactly one row; `current_season` resolves to an existing season; rebuild the FTS index (`INSERT INTO search_fts(search_fts) VALUES('rebuild')`) and assert a probe query returns the expected count. | No | Abort; delete staging; live database untouched |
| 8 | `PRAGMA wal_checkpoint(TRUNCATE)` on staging, `close()`, then assert no `-wal`/`-shm` remains beside it. A stale `-wal` next to a swapped-in main file is corruption. | No | Abort; delete staging |
| 9 | Cancel every scheduled OS notification (`cancelAll()`), then close the live database. | Reversible | Abort; reminders are rebuilt by `reconcile()` (#63) |
| 10 | Write the sentinel `<appSupport>/restore.pending` with `writeAsStringSync(..., flush: true)`. **This is the last non-destructive step.** | No | Abort |
| 11 | Rename live `shed_book.sqlite`, `-wal`, `-shm` into `<appSupport>/restore_rollback/`. | **Yes** | Recovered at next launch from the sentinel (§7.5) |
| 12 | Rename `restore_staging/shed_book.sqlite` → `<appSupport>/shed_book.sqlite`. | **Yes** | Recovered at next launch from the sentinel |
| 13 | Delete the sentinel. Delete `restore_staging/`. | No | Harmless residue; swept at next launch |
| 14 | Reopen: `ref.invalidate(databaseProvider)` and pop to the root route. Every screen re-watches its own query; there is no cached pre-restore state anywhere (#12, #20). | No | — |
| 15 | Off the critical path, after the first frame of the restored app: `sweepMissingFiles()`, `sweepOrphanFiles()`, `reconcile()` for reminders, `PRAGMA optimize`. | No | Reported in Diagnostics |
| 16 | Keep `restore_rollback/` until the **next clean launch after one successful write**, then delete it. Diagnostics shows "Previous records kept until you record something new." | No | — |

Steps 11 and 12 are the only destructive operations, they are two adjacent `rename` calls within one filesystem, and the sentinel written at step 10 makes the window between them recoverable.

### 7.3 The confirmation

Two-step, never a gesture, both controls at least 60×60 pt (#100, #101). The screen states, in this order:

1. **What is in the backup:** "3 seasons, 412 ewes, 861 lambs, 145 treatments. Made on 14 Jul 2026 by Shed Book 1.1.0." (`d MMM y`, never `14/07/2026` — decision #108 bans an all-numeric date anywhere a human reads it, and this screen is read once, at 4am, by someone about to destroy their records.)
2. **What is on this phone now:** "1 season, 38 ewes, 41 lambs, 6 treatments."
3. **The destruction sentence, unhedged:** *"Restoring will delete everything now on this phone and replace it with the backup. This cannot be undone from inside the app."*
4. **The media sentence:** *"Photos and voice notes are not part of a backup. 452 were recorded on the other phone and will show as 'not on this phone'."*
5. Step one: a 60 pt **"I understand — continue"**. Step two: a 72 pt **"Replace everything"**, disabled until step one is taken, on the opposite side of the screen from Cancel.

No typed-word confirmation. A word to type is a keyboard, and this is the app that exists because keyboards are hard with wet hands; two deliberate taps in different places carry the same intent and survive gloves. Decision #73 permits either.

The restore screen is the one place in the app that may look scary. Everywhere else, calm.

### 7.4 Failure modes

| Failure | What the user loses | What the app does |
|---|---|---|
| Wrong file type (ZIP, `.sqlite`, an image) | Nothing | Refuse at step 2 with the specific reason |
| `schema` newer than the app | Nothing | Refuse at step 3: "This backup was made by a newer version of Shed Book." Never partially import it |
| Checksum or counts mismatch | Nothing | Refuse at step 3: "This file is incomplete — it may have been cut off when it was sent." Suggest re-sending the original |
| Disk full while building staging | Nothing | Abort at step 6, delete staging, report free space needed (roughly 2× the JSON) |
| FK violation after import | Nothing | Abort at step 7. This is a bug in the exporter or the importer; the diagnostics log records which table |
| Crash during the swap (steps 11–13) | Nothing | The sentinel routine in §7.5 finishes it, reverses it, or reports that it never started — four outcomes, and the app names the one that happened |
| Restore of an *older* schema | Nothing | Normal path: migrations run on the restored file at the next open |
| User restores their own current data | Nothing | Legal and idempotent; the round-trip test asserts it |

### 7.5 What a partial restore must never leave behind

The recovery routine runs on every launch, before the database is opened, and is the reason the sentinel exists. There are **four** reachable states, not two, and conflating them is how an app tells someone their records were restored when they were not:

```dart
// lib/data/restore_service.dart — the only file that renames the live
// database. Called from the post-first-frame bootstrap, before
// databaseProvider resolves (#20, #21).
// LocalLog.instance is the app's one diagnostics sink (R52); `_diagnostics`
// is a banned identifier, and `\.instance\b` matches exactly one symbol in lib/.
Future<RestoreOutcome> completeInterruptedRestore(Directory support) async {
  final sentinel = File(p.join(support.path, 'restore.pending'));
  if (!sentinel.existsSync()) return RestoreOutcome.nothingToDo;

  final live = File(p.join(support.path, 'shed_book.sqlite'));
  final rollback =
      File(p.join(support.path, 'restore_rollback', 'shed_book.sqlite'));
  final staging =
      File(p.join(support.path, 'restore_staging', 'shed_book.sqlite'));

  final outcome = switch ((live.existsSync(), rollback.existsSync())) {
    // Crashed after the sentinel (10) but before the first rename (11).
    // Nothing was destroyed. The live file is the ORIGINAL, and saying
    // "restored" here would be a lie about the user's own data.
    (true, false) => RestoreOutcome.notStarted,

    // Crashed between 11 and 12: the live file is gone, the original is
    // in restore_rollback/. Put it back.
    (false, true) => await _moveInto(rollback, live, RestoreOutcome.rolledBack),

    // Step 12 completed; we crashed before deleting the sentinel (13).
    // The new file was fully validated at step 7, so this is a success
    // we simply failed to record.
    (true, true) => RestoreOutcome.completed,

    // Both gone. Only reachable if the OS died mid-rename or the container
    // was tampered with. Staging is the one file validated at step 7.
    (false, false) => staging.existsSync()
        ? await _moveInto(staging, live, RestoreOutcome.completed)
        : RestoreOutcome.lostBothFiles,
  };

  LocalLog.instance.record('restore.${outcome.name}');   // no row contents (#124)
  await sentinel.delete();
  try {
    // Invariant 6 below: restore_staging/ never survives a launch, whichever
    // way this went. There is no "resume an interrupted restore" — the user
    // picks the file again, and picking a file is one tap.
    await Directory(p.join(support.path, 'restore_staging'))
        .delete(recursive: true);
  } on FileSystemException {
    // Residue only. The launch sweep clears it; never block a launch.
  }
  return outcome;                                   // shown on the next screen
}

/// Moves a database and BOTH sidecars, because step 11 moved all three and a
/// main file reunited with a stale -wal is the corruption of §8.1.
Future<RestoreOutcome> _moveInto(File from, File to, RestoreOutcome then) async {
  for (final suffix in const ['', '-wal', '-shm']) {
    final source = File('${from.path}$suffix');
    if (source.existsSync()) await source.rename('${to.path}$suffix');
  }
  return then;
}
```

`RestoreOutcome.lostBothFiles` is the only branch that reaches the corruption screen of §8.4: no main file exists, so the app opens a fresh empty database, keeps everything else in the container untouched, and says so. It must be **impossible in a test to reach it without deleting a file by hand** — if the interrupted-restore test ever produces it, the swap ordering has regressed.

Every outcome is a sentence the app says out loud on the next screen. `notStarted` is *"The restore did not start. Your records are unchanged."* — the one an app that only knew two states would have reported as success.

After any restore — completed, rolled back or aborted — none of the following may exist:

1. A database containing rows from two different backups. *(Prevented by: staging is a fresh file; the swap is a rename.)*
2. A `-wal` or `-shm` from the previous database sitting beside the new main file. *(Prevented by: step 8's checkpoint, and step 11 moving all three files.)*
3. Media rows pointing at files that are gone, without `missing_since` set. *(Prevented by: step 15's sweep.)*
4. Files in `media/` that no row references, silently deleted. *(Prevented by: the sweep trashes, never deletes.)*
5. The `restore.pending` sentinel. *(Prevented by: the routine above.)*
6. `restore_staging/`. *(Prevented by: step 13, and a launch-time sweep of the directory as a belt.)*
7. OS notifications scheduled from the pre-restore data. *(Prevented by: `cancelAll()` at step 9 and `reconcile()` at step 15 — #63.)*
8. Any in-memory cache of pre-restore rows. *(Prevented by: invalidating `databaseProvider`; every repository and every screen depends on it — #20.)*
9. An entitlement that came out of a backup file. *(Prevented by: the importer skipping it — #88.)*

### 7.6 Media after restore

The v1 backup carries no bytes (#85), so after a records-only restore the sweep flags every media row `missing_since` and the completion screen says exactly that:

> **Your records are back.** 452 photos and voice notes were recorded on the other phone. Photos are not part of a backup in this version — they stay on the phone that took them. Each one still shows in the record it belongs to, marked "not on this phone".

Other restore routes behave differently, and the app should say which one happened when it can tell:

| Route | Database | Media |
|---|---|---|
| **JSON restore (this flow)** | Complete | Rows present, files absent → all flagged `missing_since` |
| **iOS iCloud device restore** | Complete, in a new container UUID | Complete. Relative paths resolve against the new root — this is the entire payoff for §4.3 |
| **Android Auto Backup restore** | Complete (under 25 MB) | Absent by configuration (§9.2) → all flagged `missing_since` |
| **Android device-to-device transfer** | Complete | Complete (`<device-transfer>` includes everything) |

**Media is not importable in v1.** The Export screen offers "Share photos from this season" — the files handed straight to the share sheet, no ZIP — and labels it plainly as a copy-out, not a restorable backup. Batch at **50 files per share**: that is a chosen bound, not a documented platform limit (`share_plus` 13.3.0 publishes none), picked so one `ShareParams` never carries more than ~35 MB of `XFile` paths through the platform channel. If a real limit is found on either OS, it replaces this number and the source goes in §11. A media ZIP is blocked on verifying `ZipFileEncoder`'s incremental-write behaviour in `package:archive/archive_io.dart` (#85, still unverified); do not design one until that check is done and recorded.

### 7.7 What restore never does

- **Never merges.** There is no merge code, so there is no merge to accidentally expose.
- **Never unlocks.** The entitlement is never imported (#88).
- **Never runs from the 3am path.** Settings only.
- **Never touches `media/`.** Not on success, not on abort. The only thing that moves media is a sweep, and a sweep only ever moves to `.trash`.
- **Never leaves the user without an explanation.** Every abort names the reason in one sentence a shepherd can act on.

### 7.8 Gates

| Gate | Asserts |
|---|---|
| Round-trip property test | Seeded 400-ewe / 3-season database → export → restore → identical row counts and column-by-column equality on every table; `uid`s preserved; integer ids allowed to differ |
| `tool/seed.dart` in CI | The seed path is the restore path (#74) and it stays green |
| Refusal fixtures | Newer `schema`; newer `formatVersion`; truncated file; a ZIP; a `.sqlite`; a backup with an entitlement row — each aborts at the documented step with the documented state left behind |
| Interrupted-restore test | Simulate a crash at each of the three windows — 10/11, 11/12, 12/13 — and assert the routine returns `notStarted`, `rolledBack`, `completed` respectively, with the correct file in place each time. `lostBothFiles` is unreachable without deleting a file by hand |
| Post-restore invariants | The nine items in §7.5, asserted directly |
| Widget test | The confirmation screen requires two taps; no `Dismissible`, no `Draggable`, both controls ≥ 60×60 pt (#100, #101) |

---

## 8. `VACUUM INTO` — the diagnostics snapshot

### 8.1 Why `File.copy` of the database is wrong

In WAL mode the database is **three** files. sqlite.org/wal.html: the `-wal` file is *"part of the persistent state of the database"*, and *"if a database file is separated from its WAL file, then transactions that were previously committed to the database might be lost, or the database file might become corrupted."* howtocorrupt.html adds the case directly: a backup taken mid-transaction *"might contain some old and some new content, and thus be corrupt."*

A naive `File(dbPath).copy(exportPath)` therefore produces, best case, a database missing the last few hours of a lambing night; worst case, a corrupt file the user believes is their backup. **This is the single most dangerous line of code anyone could write in this app.** `check_policy` bans `.copy(` anywhere under `lib/core/db/`.

There is exactly one allowlisted exception, and it is §8.4 step 4: copying the **closed, already-damaged** three files out for a bug report. It is named line-by-line in `tool/policy_allowlist.txt` with the rule id and the reason. If a second exception is ever proposed, the answer is no.

### 8.2 The mechanism

The mechanism is SQL, not a library call. From sqlite.org/lang_vacuum.html: *"VACUUM INTO is an alternative to the backup API for generating backup copies of a live database"*; *"the file named by the INTO clause must not previously exist, or else it must be an empty file"*; and *"if interrupted by an unplanned shutdown or power loss, the generated output database might be incomplete and corrupt."* Unlike a plain `VACUUM`, it does not need exclusive access, so it runs while the app is in use.

`VACUUM INTO` is chosen over SQLite's C-level online-backup API for three reasons that hold regardless of what the binding exposes: it is one statement issued through the connection drift already owns; it needs no second open handle on a WAL database; and its output is a single fully-checkpointed file with no sidecars, which is exactly what the share sheet needs.

> **Unverified, check in commit #1.** Whether `package:sqlite3` 3.5.0 surfaces the online-backup API on `CommonDatabase` has not been confirmed against the published API. It does not change the decision — #84 names `VACUUM INTO`, and the reasons above are independent — but do not write "there is no `backup()` method" in a code comment on the strength of this document. Look, then record what you found here.

```dart
// lib/core/db/diagnostics_snapshot.dart — inside lib/core/db/, because
// customStatement( is banned outside the database package (01 §3, rule 8).
/// Produces a single, fully-checkpointed .sqlite file with no -wal/-shm
/// sidecars, safe to hand to the share sheet.
/// Diagnostics only — this is NOT the user's backup (decision #84).
Future<File> snapshotDatabase() async {
  final tmp = await getTemporaryDirectory();
  final dir = Directory(p.join(tmp.path, 'diagnostics'))
    ..createSync(recursive: true);
  final stamp = appNow().utc.toIso8601String().replaceAll(':', '-'); // #46
  final out = File(p.join(dir.path, 'shed-book-$stamp.sqlite'));

  // VACUUM INTO refuses to overwrite. Clear any stale file first.
  if (out.existsSync()) out.deleteSync();

  // Bind the path; never interpolate into SQL.
  // NEVER inside db.transaction() — VACUUM cannot run in a transaction.
  await _db.customStatement('VACUUM INTO ?;', [out.path]);
  return out;
}
```

Then out through the share sheet (#80). `share_plus` is reached only through the `ShareService` gateway (CONVENTIONS §2.12) — this is what that one call site does:

```dart
// lib/data/share_service.dart — the ONE share_plus call site.
await SharePlus.instance.share(ShareParams(
  files: [XFile(file.path)],
  fileNameOverrides: const ['shed-book-diagnostics.sqlite'],
  sharePositionOrigin: originRect, // required on iPad
));
```

Rules:

- It writes to `getTemporaryDirectory()`, which Apple documents as not backed up and Android excludes from Auto Backup, so stale snapshots never inflate anyone's iCloud. Sweep that directory at launch.
- It runs off the paint frame, behind an explicit button in Settings ▸ Diagnostics, with a progress indicator — never automatically, never on the launch path.
- It never runs inside `db.transaction()`.

### 8.3 What it is for, and what it is not

| It is | It is not |
|---|---|
| The mechanism behind Settings ▸ Diagnostics ▸ "Save a copy of the database" | The user-facing backup. That is JSON (#84) |
| The pre-migration safety copy (§2.8) | Restorable from inside the app. There is exactly one restore path |
| The thing you attach to a bug report, after checking §9's redaction rules apply — **it contains the user's records, so it is never shared automatically and never without the user choosing to** (#123, #124) | Something the export screen advertises |

### 8.4 When the database is already damaged

On `SQLITE_CORRUPT` (11) or `SQLITE_NOTADB` (26) at open, `VACUUM INTO` will usually fail too. The procedure (note 08 §6.4):

1. **Never delete anything.** Rename `shed_book.sqlite` and its `-wal`/`-shm` to `shed_book.corrupt-<timestamp>.*`, all three together.
2. Open a fresh empty database so the app is usable **tonight**.
3. Show a blunt, non-technical screen: *"Some of your records could not be read. The damaged file has been kept. Tap to save a copy of it."*
4. That save copies **all three files together** into a folder in temp and shares them. This is the one place a raw file copy is correct, precisely because the database is closed and damaged and there is nothing to be consistent with. Label it "damaged copy"; it is never restorable in-app.
5. Log the extended result code to Diagnostics. Never the exception message — SQLite messages echo SQL and sometimes bound values (#124).

`PRAGMA integrity_check` is a full-database scan and never runs at startup. `PRAGMA quick_check` sits behind a button in Diagnostics.

---

## 9. OS-level backup, and the honest wording

### 9.1 What actually happens by default

**iOS.** Apple's File System Programming Guide: `Library/Application Support/` — *"In iOS, the contents of this directory are backed up by iTunes and iCloud."* With the database in application support (#27), **it is in the user's iCloud backup by default, with no code**. `Caches/` and `tmp/` are not backed up, which is why exports are staged in temp.

**Android.** Auto Backup is enabled by default for apps targeting API 23+; `android:allowBackup` defaults to `true`; it covers `getFilesDir()` — which is what `getApplicationSupportDirectory()` maps to — and excludes the cache directories. The limit is **25 MB per app per user**, and when an app exceeds it, backup **stops, quietly**.

### 9.2 What the app configures

Leave Auto Backup on — turning it off makes the product strictly worse for no gain — but declare intent explicitly instead of inheriting defaults.

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<application
    android:allowBackup="true"
    android:fullBackupContent="@xml/backup_rules"
    android:dataExtractionRules="@xml/data_extraction_rules"
    ... >
```

```xml
<!-- android/app/src/main/res/xml/data_extraction_rules.xml -->
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
  <!-- Cloud backup: 25 MB cap. Records only. ~300 MB of photos would blow
       the quota and silently kill the backup of the records too. -->
  <cloud-backup>
    <include domain="file" path="shed_book.sqlite" />
    <include domain="file" path="shed_book.sqlite-wal" />
    <!-- -shm is deliberately absent. It is transient shared memory, not
         persistent state; SQLite rebuilds it from the -wal on first open,
         and restoring a stale one is a corruption risk for no benefit. -->
    <exclude domain="file" path="media" />
    <exclude domain="file" path="pre_migration" />
    <exclude domain="file" path="restore_staging" />
    <exclude domain="file" path="restore_rollback" />
    <exclude domain="file" path="diagnostics" />
  </cloud-backup>

  <!-- Device-to-device transfer: local, not Drive-quota-bound. Take it all. -->
  <device-transfer>
    <include domain="file" path="." />
  </device-transfer>
</data-extraction-rules>
```

`backup_rules.xml` (Android ≤ 11) mirrors the `<cloud-backup>` rules in the older `<full-backup-content>` syntax.

**Bound the `-wal` so the OS captures less torn state.** The OS copies files at a moment of its choosing, not atomically, so a cloud backup can in principle capture a main file and a `-wal` from different instants. Two mitigations, both cheap: `PRAGMA journal_size_limit = 4194304` (§2.8), and a `PRAGMA wal_checkpoint(TRUNCATE)` when the app reaches `AppLifecycleState.hidden`, off the paint frame — see [`08-platform-integration.md`](08-platform-integration.md) for the lifecycle seam. This reduces the risk; it does not eliminate it, which is the whole reason §9.4's wording never promises anything about the OS backup.

**iOS.** Do nothing to the database — leave it eligible for iCloud backup. Do **not** exclude `media/`: iCloud has no equivalent of Android's 25 MB app cap and losing the photos is a real loss. Setting `isExcludedFromBackupKey` on `.trash` would need a platform channel for `NSURL.setResourceValue`, and v1 does not ship one; instead `.trash` is bounded — 30 days, 100 MB, oldest purged first (§4.8) — which achieves the same thing with no native code.

> **Two things to verify on-device before shipping, both currently unverified.** (a) Google documents the 25 MB limit for Auto Backup to Drive; it is *not* documented as applying to local device-to-device transfer. Confirm empirically before any UI text implies media transfers. (b) Google's own docs note that on Android 12+, `android:allowBackup="false"` "may only disable cloud backups but not device-to-device transfers, depending on the device manufacturer" — another reason to configure rather than disable.

### 9.3 Should the app rely on OS backup? No.

Two structural reasons: it is **invisible** — the app cannot query "when was my data last backed up?" on either platform, so it cannot tell the user anything true about it — and it **restores to a device, not to an app**, so there is no in-app "restore from iCloud" button that could ever exist. The export flow remains the only *claimable* backup. The OS backup is silent good luck and is described as such.

### 9.4 The export-screen wording

The spec (§7.9) says the app "must be honest that a lost phone is lost data unless the user exports." That claim needs qualifying, because it is not true by default: the database is in the OS backup on both platforms without any code. The honest version is stronger, not weaker — it tells the truth about how unreliable that backup is, and it does not reduce the pressure to export:

> **Your records live on this phone.**
> Your phone's own backup (iCloud or Google) usually includes them — but it may be switched off, out of date, or too small to include your photos, and you can't check what's in it.
> **The only backup you control is an export.** Send yourself a copy.

Everything in that paragraph is checkable: iCloud Backup can be off or full; Android's 25 MB cap is real and silent; Auto Backup runs only when the device is idle, charging and on Wi-Fi — a phone at 4 % in a shed at 3am is none of those, so night eleven may simply not be in the most recent backup; neither backup is user-inspectable; and restore is all-or-nothing at device setup.

Below it, unchanged and referenced from the single constant (#62), sits `Disclaimers.exportFooter`. It is never re-typed here or anywhere else — see [`09-export-formats.md`](09-export-formats.md).

**Wording that is banned on this screen:** "a lost phone is lost data" without the qualification above (it is false); "your data never leaves your phone" (it does, the moment they AirDrop a CSV — decision-record §3.1); "verified" or "secure" about the checksum (§6.6); and any implication that a `.sqlite` diagnostics copy is a backup (§8.3).

---

## 10. Definition of done

Tick every line before calling this area finished.

**Migrations**

- [ ] `build.yaml` has `databases`, `schema_dir`, `test_dir` and the FTS5 module, and does **not** have `store_date_time_values_as_text`.
- [ ] `grep -r "dateTime()" lib/` returns nothing.
- [ ] `kSchemaVersion` is a top-level const readable from the background isolate.
- [ ] `drift_schemas/` contains exactly `kSchemaVersion` snapshot files, all committed, none hand-edited.
- [ ] `beforeOpen` awaits `validateDatabaseSchema()` behind `kDebugMode`, with no `assert(() {...}())` anywhere near it.
- [ ] `seedOnCreate` exists and the import path passes `false`.
- [ ] A downgrade throws rather than migrating, **proven by the §3.5 test on the pinned drift**, not assumed from a version number.
- [ ] No `TableMigration` in the repo supplies a value for a withdrawal column, a lambing ease, a birth type, a cause of death or `ewe_seasons.status = 'barren'` (§2.7). Reviewed by a human; CI cannot see it.
- [ ] The pre-migration `VACUUM INTO` runs from `setup`, is bounded by file size, and its output is deleted after one clean launch.
- [ ] The from→to matrix runs every pair, asserts `foreign_key_check` empty and `quick_check` ok.
- [ ] The N-1→N data-integrity test exists, plus one for every step containing `alterTable`.
- [ ] FTS5 shadow tables have been proven to pass or fail `SchemaVerifier` **on a real run**, and the outcome is written into §3.4.
- [ ] CI fails on a `make-migrations` diff.
- [ ] `check_policy` rules for destructive DDL, historical-schema use and SQL-side time are written and firing.

**Media**

- [ ] `media_assets.relative_path` carries all **three** `CHECK`s (§4.3) in `03-data-model-and-schema.md` **before** the v1 snapshot is generated, and tests prove the database rejects an absolute path, a Windows-separated path and `2026/03/../../x.jpg`.
- [ ] `MediaStore.resolve()` throws on a path that leaves the media root, with a test.
- [ ] `MediaStore` is the only place `getApplicationSupportDirectory()` is called outside `connection.dart`.
- [ ] Nothing under `lib/features/**` constructs a `File`.
- [ ] Photo output is asserted at ≤ 2048 px longest edge and ≤ 900 KB, **measured on a real device**, with the `minWidth`/`minHeight` semantics confirmed (§4.4).
- [ ] Voice notes are AAC-LC `.m4a`, mono; `kVoiceNoteMaxSeconds` is one constant; the owner has answered §7.1 #18.
- [ ] Row-then-media ordering is implemented, and the disk-full path leaves the record intact with a Retry affordance.
- [ ] Both sweeps run post-frame, trash rather than delete, and un-flag a file that reappears.
- [ ] `.trash` is purged at 30 days / 100 MB.

**Backup and restore**

- [ ] The `BackupHeader` carries `format`, `formatVersion`, `schema`, `counts`, `checksum`, `media.included=false`, and the referenced disclaimer.
- [ ] No `double` appears in an encoded backup, and a test proves it.
- [ ] Every `NOT NULL` column with no database default is in `importDefaults`, proven by the schema-JSON test.
- [ ] The round-trip test passes on the 400-ewe / 3-season fixture.
- [ ] `tool/seed.dart` goes through the restore path and runs in CI.
- [ ] All six refusal fixtures abort at the documented step, leaving the live database untouched.
- [ ] The interrupted-restore recovery routine is tested at all **three** crash windows (10/11, 11/12, 12/13) and never reports `completed` for a swap that did not start.
- [ ] The restore confirmation screen renders its date as `d MMM y` (#108), and a widget test greps the rendered text for `/`.
- [ ] The nine post-restore invariants are asserted.
- [ ] The confirmation screen needs two taps, has no banned gestures, and states the media consequence.
- [ ] `cancelAll()` + `reconcile()` run across a restore.
- [ ] An entitlement row in a backup file does not unlock the app.

**Snapshots and OS backup**

- [ ] `.copy(` is banned under `lib/core/db/` and the ban is enforced.
- [ ] `VACUUM INTO` writes to temp, is never inside a transaction, and temp is swept at launch.
- [ ] The corruption path renames all three files, opens a fresh database, and offers the damaged copy.
- [ ] `data_extraction_rules.xml` and `backup_rules.xml` exist, are referenced from the manifest, and exclude `media/`, `pre_migration/`, `restore_*` and `diagnostics/` from cloud backup.
- [ ] A `wal_checkpoint(TRUNCATE)` runs on `hidden`.
- [ ] D2D size behaviour and the `allowBackup=false` caveat have been checked on a real device and the result recorded in §9.2.
- [ ] The export screen uses the §9.4 wording verbatim and contains none of the banned phrases.

---

## 11. References

**Project documents**

- [`docs/research/00-tech-decisions.md`](../research/00-tech-decisions.md) — the canonical decision record (decisions #13, #25, #27–#32, #35, #37–#42, #46, #47, #51, #52, #53, #62, #63, #73, #74, #76, #77, #80, #81, #84–#86, #88, #93, #108, #123–#125, #127; **§5 is the only source of any version number in this document**; §7.0 owner rulings; §7.1 open items)
- [`shed-book-spec.md`](../../shed-book-spec.md) — §5 (the 3am test), §7.9 (export and backup), §12 (safety rules), §17 (open questions)
- Research notes: `docs/research/raw/03-persistence.md` §8–§11, `docs/research/raw/08-performance-and-reliability.md` §6, §9, `docs/research/critique/c3-consistency.md` A4, D1, D2, §E

**SQLite**

- Write-Ahead Logging — https://www.sqlite.org/wal.html
- `VACUUM` and `VACUUM INTO` — https://sqlite.org/lang_vacuum.html
- How To Corrupt An SQLite Database File — https://www.sqlite.org/howtocorrupt.html
- PRAGMA reference (`synchronous`, `foreign_keys`, `defer_foreign_keys`, `journal_size_limit`, `temp_store`, `wal_checkpoint`, `quick_check`, `foreign_key_check`) — https://www.sqlite.org/pragma.html
- Result codes (`SQLITE_FULL`, `SQLITE_CORRUPT`, `SQLITE_NOTADB`) — https://www.sqlite.org/rescode.html
- `ALTER TABLE` and the 12-step table-rebuild procedure — https://sqlite.org/lang_altertable.html
- STRICT tables — https://sqlite.org/stricttables.html
- FTS5 — https://sqlite.org/fts5.html
- 35% Faster Than The Filesystem (the blob/file crossover) — https://www.sqlite.org/fasterthanfs.html

**drift**

- Migrations, `stepByStep`, `make-migrations`, `TableMigration` — https://drift.simonbinder.eu/migrations/
- Setup and `driftDatabase` / `DriftNativeOptions` — https://drift.simonbinder.eu/setup/
- Runtime schema inspection (`validateDatabaseSchema`) — https://drift.simonbinder.eu/docs/advanced-features/schema_inspection/
- `build.yaml` naming footgun — https://github.com/simolus3/drift/discussions/2670
- FTS5 shadow tables breaking schema diffing, in other ecosystems — https://github.com/prisma/prisma/issues/8106 · https://github.com/rails/rails/pull/52354

**Platform**

- iOS container UUID instability — https://github.com/flutter/flutter/issues/23957
- Apple, File System Programming Guide (Application Support is backed up; file reference URLs are not safe to persist) — https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/AccessingFilesandDirectories/AccessingFilesandDirectories.html
- Android Auto Backup (25 MB cap, what is included, `data_extraction_rules`) — https://developer.android.com/identity/data/autobackup
- Android app-specific storage (cache volatility) — https://developer.android.com/training/data-storage/app-specific

**Packages** (versions come from §5 of the decision record and nowhere else)

- `drift` 2.34.2 / `drift_dev` 2.34.5 / `drift_flutter` 0.3.1 — https://pub.dev/packages/drift
- `sqlite3` 3.5.0 — https://pub.dev/packages/sqlite3
- `path_provider` 2.1.6 — https://pub.dev/packages/path_provider
- `uuid` 4.6.0 — https://pub.dev/packages/uuid
- `image_picker` 1.2.3 — https://pub.dev/packages/image_picker
- `flutter_image_compress` 2.5.1 — https://pub.dev/packages/flutter_image_compress
- `record` 7.1.1 — https://pub.dev/packages/record
- `file_selector` 1.1.0 — https://pub.dev/packages/file_selector
- `share_plus` 13.3.0 — https://pub.dev/packages/share_plus
- `archive` 4.0.9 (streaming encode still unverified — #85) — https://pub.dev/packages/archive

**Unverified at the time of writing, and flagged in the text**

- Whether drift's `SchemaVerifier` tolerates FTS5 shadow tables (§3.4)
- Whether `stepByStep` on the pinned `drift` 2.34.2 throws on a downgrade — owned by the §3.5 test rather than quoted from a version number (§2.1, §3.5)
- Whether `package:sqlite3` 3.5.0 exposes the online-backup API on `CommonDatabase` (§8.2). It does not change the decision; do not assert either way until it is checked
- Any real platform limit on the number of `XFile`s in one `ShareParams` — the 50-file batch in §7.6 is a chosen bound, not a documented one
- `flutter_image_compress`'s `minWidth`/`minHeight` cap-versus-floor semantics (§4.4)
- Photo size at 2048 px q80 on a real device (§4.7)
- Android device-to-device transfer size behaviour, and `allowBackup="false"` versus D2D (§9.2)
- `ZipFileEncoder` incremental-write behaviour in `package:archive/archive_io.dart` (§7.6)
- The voice-note cap, 60 s or 120 s — owner question §7.1 #18 (§4.4)

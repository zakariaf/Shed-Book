# 03 — Local persistence, schema, search, migrations, media

**App:** Shed Book (offline-only lambing notebook, iOS + Android)
**Toolchain assumed:** Flutter 3.44.6 stable · Dart 3.12.2 · Xcode 26.6 · macOS arm64
**Research date:** 2026-07-27. Every version below was read off a live pub.dev page or repo on that date. Re-verify before you `pub add` anything.

> The organising principle for this whole document: **the SQLite file is the product.** It is not a cache in front of a server, because there is no server. It is the only copy of five seasons of a shepherd's flock history. Every decision below is biased towards *durability and legibility of that file in ten years*, and against *cleverness that makes the file harder to recover*.

---

## Bottom line

| Question | Decision | Confidence |
|---|---|---|
| Persistence layer | **Drift `2.34.2`** (+ `drift_dev 2.34.5`, `drift_flutter 0.3.1`) over SQLite | High |
| Native SQLite library | **`package:sqlite3` `3.5.0` only.** `sqlite3_flutter_libs` is **EOL / no-op** (`0.6.0+eol`). Do **not** add it. | High |
| SQLite build | The one `package:sqlite3` bundles via Dart **build hooks** — FTS5, math funcs, `SQLITE_DQS=0`, SQLite 3.53.3+. Never the OS copy. | High |
| Table style | `STRICT` on every table, FKs on every relationship, `PRAGMA foreign_keys=ON` per connection | High |
| DateTime storage | **ISO-8601 TEXT** (`store_date_time_values_as_text: true`), set on day 0, never changed | High |
| ID strategy | **Dual key**: `INTEGER PRIMARY KEY` (rowid alias) for joins/FKs + `uid TEXT UNIQUE` (UUID v7) as the export/re-import identity | High |
| Fostering | Immutable `birth_dam_id` on `Lamb` + append-only `FosterEvents` history + a SQL **view** for the current rearing dam. No mutable "current" column. | High |
| Pen occupancy | Append-only `PenOccupancies` history + partial unique index `WHERE exited_at IS NULL`. No mutable `occupant_ewe` column. | High |
| Full-text search | FTS5 external-content over a single `search_docs` fan-in table, kept in sync by **SQL triggers**, `porter unicode61` tokenizer, `prefix='2 3'` | Medium |
| Partial tag matching (`12` → `412`) | **Not an FTS problem.** Trigram FTS5 physically cannot match a 2-char query. At 400 ewes: in-memory ranked filter over a cached tag list. | High |
| Journal mode | `WAL` | High |
| `synchronous` | **`FULL`, not `NORMAL`.** Contrarian vs. the usual mobile advice; justified by "assume the phone dies". | Medium-High |
| DB snapshot for backup | `VACUUM INTO` into the temp dir, then share sheet. **Never** `File.copy` the `.sqlite`. | High |
| Migrations | Drift `make-migrations` + generated schema snapshots + `stepByStep` + a **full from→to matrix** of migration tests. Forward-only. | High |
| Media | Filesystem, in `<appSupport>/media/…`. **Store relative paths only** — the iOS container UUID changes. | High |
| OS backup | **Leave it on.** Declare `dataExtractionRules` explicitly. But the app's copy must stay honest: OS backup is not a backup the user controls. | High |
| Encryption at rest | **No.** Rely on platform FDE. Any key is a way the app fails to open at 3am. | High |

---

## 0. Verified package inventory

All fetched from pub.dev on 2026-07-27.

| Package | Version | Last publish | Publisher | Status | Verdict |
|---|---|---|---|---|---|
| [`drift`](https://pub.dev/packages/drift) | 2.34.2 | ~12 days ago | simonbinder.eu ✔ | active, 160 pts, 2.44k likes | **adopt** |
| [`drift_dev`](https://pub.dev/packages/drift_dev) | 2.34.5 | ~4 days ago | simonbinder.eu ✔ | active | **adopt** (dev dep) |
| [`drift_flutter`](https://pub.dev/packages/drift_flutter) | 0.3.1 | ~16 days ago | simonbinder.eu ✔ | active | **adopt-with-care** (see §2.3) |
| [`sqlite3`](https://pub.dev/packages/sqlite3) | 3.5.0 | ~8 days ago | simonbinder.eu ✔ | active | **adopt** |
| [`sqlite3_flutter_libs`](https://pub.dev/packages/sqlite3_flutter_libs) | 0.6.0**+eol** | ~5 months ago | simonbinder.eu ✔ | **discontinued / no-op** | **do not add** |
| [`sqlcipher_flutter_libs`](https://pub.dev/packages/sqlcipher_flutter_libs) | 0.7.0**+eol** | ~5 months ago | simonbinder.eu ✔ | **discontinued / no-op** | **do not add** |
| [`path_provider`](https://pub.dev/packages/path_provider) | 2.1.6 | ~41 days ago | flutter.dev ✔ | active | **adopt** |
| [`uuid`](https://pub.dev/packages/uuid) | 4.6.0 | ~11 days ago | yuli.dev ✔ | active, RFC 9562 v6/v7/v8 | **adopt** |
| [`share_plus`](https://pub.dev/packages/share_plus) | 13.3.0 | ~3 days ago | fluttercommunity.dev ✔ | active | adopt (export path) |
| [`sqflite`](https://pub.dev/packages/sqflite) | 2.4.3 | ~54 days ago | tekartik.com ✔ | active | **reject** for this app (§1.3) |
| [`sqlite_async`](https://pub.dev/packages/sqlite_async) | 0.14.4 | ~5 days ago | powersync.com ✔ | active, 160 pts | **reject** (§1.4) |
| [`objectbox`](https://pub.dev/packages/objectbox) | 5.3.2 | ~2 months ago | ObjectBox.io ✔ | active | **reject** (§1.5) |
| [`isar`](https://pub.dev/packages/isar) | 3.1.0+1 | **~3 years ago** | isar.dev ✔ | stable stalled; 4.0.0-dev.14 prerelease only | **avoid** |
| [`hive`](https://pub.dev/packages/hive) | 2.2.3 | **~4 years ago** | isar.dev ✔ | stalled; 4.0.0-dev.2 prerelease only | **avoid** |
| [`hive_ce`](https://pub.dev/packages/hive_ce) | 2.19.3 | ~5 months ago | iodesignteam.com ✔ | active community fork | not needed here |
| [`realm`](https://pub.dev/packages/realm) | 20.2.0 | ~10 months ago | realm.io ✔ | **deprecation notice on the pub.dev page** | **avoid** |
| [`sembast`](https://pub.dev/packages/sembast) | 3.8.9+1 | ~30 days ago | tekartik.com ✔ | active | **reject** (§1.7) |
| [`ulid`](https://pub.dev/packages/ulid) | 2.0.1 | ~22 months ago | agilord.com ✔ | active-ish | rejected in favour of UUIDv7 |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | 10.3.1 | ~2 months ago | steenbakker.dev ✔ | active | **not used** (§12) |

---

## 1. Which persistence layer in 2026

### 1.1 The call: Drift over SQLite

Drift 2.34.2, published 12 days before this research, verified publisher, 160/160 pub points, 1.03M downloads. It is the healthiest package in this space by a wide margin, and it is maintained by the same person who maintains `package:sqlite3` — which matters enormously in 2026 because that person just executed a coordinated breaking change across both (see §2).

The reasons that are *specific to this app*, not generic:

1. **The file must be a plain, boring SQLite database.** Ten years from now, a shepherd (or their kid, or a vet) must be able to open `shed_book.sqlite` in the `sqlite3` CLI or DB Browser and read the flock history without Shed Book existing. Drift's output is exactly that: `CREATE TABLE ... STRICT` with real foreign keys. Isar/ObjectBox/Hive files are opaque proprietary formats — if the vendor dies, the data is stranded. For an app whose *entire pitch* is "no company going out of business in 2029 taking five seasons of flock history with it" (spec §4.3), a proprietary on-disk format is a direct contradiction of the product positioning.

2. **The domain is relational.** Season → Ewe ↔ Lambing → Lamb → Foster → Pen → Treatment → Reminder. Section 7.8 needs `GROUP BY`, `COUNT`, `AVG`, date bucketing for the lambing-spread chart, and cross-season comparison. That is SQL. Doing it in a document store means loading everything into Dart and computing by hand, which is slower, more code, and more places to get "lambing percentage" subtly wrong.

3. **Migrations are the highest-risk part of this product.** No server means no backfill script, no "we'll fix it in the next deploy". A user can be on v1.0 for two seasons, then update to v2.3 in one jump. Drift has generated schema snapshots, `stepByStep` migrations, and a `SchemaVerifier` that can test *every* from→to path — [documented here](https://drift.simonbinder.eu/migrations/tests/). Nothing else in the Dart ecosystem has this. This alone is close to decisive.

4. **Reactive queries.** The Pen Board (spec §7.4) is a live view with "hours since penned". Drift's `.watch()` streams re-emit on table change, so the board and the flock list update without manual invalidation.

5. **Zero network surface.** Drift is a compiler + a `dart:ffi` binding. No sockets, no HTTP client in the dependency tree, no manifest permissions merged in. Verified: the Flutter app template puts `android.permission.INTERNET` **only** in `android/app/src/debug/AndroidManifest.xml` and `.../profile/AndroidManifest.xml`, not in `main` — so a release build of a Drift app genuinely ships with no INTERNET permission. (Read from `flutter/flutter` → `packages/flutter_tools/templates/app/android.tmpl/app/src/{main,debug,profile}/AndroidManifest.xml.tmpl`.)

**Cost of Drift, stated honestly:** code generation. You will run `build_runner` and you will occasionally fight it. Cold generation on a schema this size is tens of seconds. That is a development-time cost, not a runtime cost, and it buys compile-time-checked SQL — which for a solo developer with no QA team is the cheapest bug-prevention available.

### 1.2 Rejected: Isar

`isar` 3.1.0+1 was **last published roughly three years ago**. The only newer thing on the page is `4.0.0-dev.14`, a prerelease. There is no discontinued marker, but a stable release that has not moved in three years while a "dev.14" prerelease dangles is, for a single developer building something meant to last a decade, a maintenance liability, not a database. There is also no way to read an Isar file without Isar.

**Verdict: avoid.** Do not build a ten-year data store on a prerelease.

### 1.3 Rejected: raw `sqflite`

`sqflite` 2.4.3 is genuinely healthy (tekartik.com, 160 pts, 2.51M downloads). It loses on one specific, disqualifying fact, stated in its own docs:

> "`sqflite` uses the SQLite available on the platform. It does not ship/bundle any additional SQLite library."
> — [`sqflite/doc/version.md`](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/version.md)

That document then lists the version table: Android API 27 → SQLite 3.19, API 24 → 3.9; iOS 13.1.3 → 3.28.0. **`STRICT` tables require SQLite ≥ 3.37.0** ([sqlite.org/stricttables.html](https://sqlite.org/stricttables.html)). FTS5's trigram tokenizer needs ≥ 3.34. Neither is guaranteed on the OS copy, and worse, *you cannot know which SQLite a given phone has* until runtime. For an app that must behave identically on a 2019 budget Android and a 2026 iPhone, that is unacceptable. Google agrees, for its own stack:

> "The recommended implementation to use is `BundledSQLiteDriver` … It includes the SQLite library compiled from source, offering the most up-to-date version and consistency across all the supported KMP platforms."
> — [developer.android.com/kotlin/multiplatform/sqlite](https://developer.android.com/kotlin/multiplatform/sqlite)

Secondary loss: no type-safe queries, no migration snapshot tooling, no reactive streams. You would rebuild all of that by hand.

### 1.4 Rejected: `sqlite_async`

`sqlite_async` 0.14.4 (powersync.com) is a good package: 160 pts, actively published, depends on `sqlite3 ^3.5.0`, no PowerSync requirement, async-by-default with a read/write connection pool. If you wanted raw SQL with sane concurrency and no codegen, this is the package.

It loses to Drift on exactly one axis, and it's the axis that matters most here: **migration tooling.** `sqlite_async` gives you a migration runner; Drift gives you generated per-version schema snapshots, a `SchemaVerifier` that semantically diffs `sqlite_schema`, and generated tests. For an app where a botched migration silently eats a shepherd's 2027 season with no server-side backup to restore from, that difference is the whole ballgame.

Second loss: raw SQL strings are not compile-checked, and this schema has ~14 tables with polymorphic references and CHECK constraints. Drift's analyser catches a typo'd column at build time; `sqlite_async` catches it at 3am.

Worth noting for the record: `sqlite_async` remains the right answer for a project that has strong reasons to avoid `build_runner`.

### 1.5 Rejected: ObjectBox

`objectbox` 5.3.2, verified publisher, active. Fast, genuinely. Rejected because:
- **Proprietary on-disk format.** Same argument as Isar — violates spec §4.3.
- **Not pure Dart**; requires a native C library, and the pub.dev page notes it must be downloaded separately for Dart Native projects. Extra build fragility for zero gain.
- **Data Sync is a paid add-on.** Its presence in the SDK is a permanent temptation and a permanent "does this thing phone home?" question. For an app whose selling point is that it *cannot* phone home, the cleanest answer is not to link the code at all.
- The relational modelling above (fostering history, pen occupancy history, polymorphic treatment subjects) is awkward in an object database and trivial in SQL.

### 1.6 Rejected: Realm

The pub.dev page for `realm` 20.2.0 carries a deprecation notice:

> "We announced the deprecation of Atlas Device Sync + Realm SDKs in September 2024."

Last publish ~10 months ago. **Do not start a 2026 greenfield project on a deprecated SDK.** Closed.

### 1.7 Rejected: Hive / hive_ce / Sembast

- `hive` 2.2.3: last published ~4 years ago, stable frozen, `4.0.0-dev.2` prerelease only. Same publisher as Isar (isar.dev). Avoid.
- `hive_ce` 2.19.3 is a healthy community continuation (803k weekly downloads, 160 pts) and is the right choice *if you already have Hive boxes*. Shed Book has none.
- `sembast` 3.8.9+1 is healthy but is a document store that **holds the whole database in memory when opened**. It has no SQL, no FTS, no relational integrity, and no migration test tooling.

All three are key-value/document stores. Shed Book's hard problems are relational aggregation, full-text search, and multi-year migration safety. Wrong tool.

### 1.8 The one place the popular answer is right, and one where it isn't

Popular answer: *"use Drift"* — right, for the reasons above.
Popular answer: *"add `sqlite3_flutter_libs`"* — **wrong as of 2026.** See next section. This is the single most likely way a developer working from a 2024 blog post or from LLM memory will produce a broken or redundant setup.

---

## 2. The native SQLite library on Flutter in 2026 — this changed, and it changed recently

### 2.1 `sqlite3_flutter_libs` is dead

Read the package's own page. `sqlite3_flutter_libs` is at **`0.6.0+eol`**, last published ~5 months ago, with a caution banner:

> "This package relates to version 2.x of `package:sqlite3`, and is obsolete after upgrading."
> "Starting from version `0.6.0`, this package no longer does anything."

Its changelog:

> "Deprecate this package. Starting from versions 3.x of the `sqlite3` package, `sqlite3_flutter_libs` is no longer necessary." … "removes all code from this package. It can be used to require that the old Flutter-specific scripts are no longer used."

`sqlcipher_flutter_libs` is the same story at `0.7.0+eol`.

### 2.2 What replaced it: Dart build hooks

`package:sqlite3` 3.0.0's changelog entry is explicit:

> "Use [build hooks](https://dart.dev/tools/hooks) to load SQLite instead of `DynamicLibrary`" — and — "drop your dependencies on `sqlite3_flutter_libs` and `sqlcipher_flutter_libs` when upgrading."

The README:

> "Because this library uses hooks, it bundles SQLite with your application and doesn't require any external dependencies or build configuration."

Build hooks are **stable**, not experimental: [dart.dev/tools/hooks](https://dart.dev/tools/hooks) — "Support for build hooks was introduced in Dart 3.10." Flutter-side: [docs.flutter.dev/platform-integration/bind-native-code](https://docs.flutter.dev/platform-integration/bind-native-code) — "Since Flutter 3.38, the recommended way to bind to native code is to use the `flutter create --template=package_ffi` command. This template uses build hooks…". Our toolchain (Dart 3.12.2 / Flutter 3.44.6) is comfortably past both. `sqlite3`'s own pubspec requires `sdk: '>=3.10.0 <4.0.0'`.

**Practical consequence for the pubspec:** there is no Podfile edit, no `build.gradle` edit, no `CMakeLists.txt`, no `.podspec`. You add `sqlite3` (transitively, via `drift_flutter`) and the `.so`/`.framework` appears in your app bundle.

### 2.3 What `drift_flutter` still drags in, and why it's harmless

`drift_flutter 0.3.1` still declares `sqlite3_flutter_libs: ^0.6.0+eol` and `sqlcipher_flutter_libs: ^0.7.0+eol` as dependencies. Those are the *empty* EOL versions — they exist precisely so that a resolver forces you off the old Gradle/CocoaPods scripts. You will see them in `pubspec.lock`. **Do not add them to your own `pubspec.yaml`**, and do not be alarmed that they're in the lockfile.

### 2.4 What you actually get in the bundled build

From [`sqlite3/doc/hook.md`](https://github.com/simolus3/sqlite3.dart/blob/main/sqlite3/doc/hook.md), which opens with the exact argument for bundling:

> "Most operating systems make copies of SQLite as a native library available to applications. However, these libraries are inconsistent in their compile-time options (resulting in different SQLite features being available on different platforms) and are often outdated. To avoid this inconsistency, `package:sqlite3/` bundles a copy of SQLite with your application by default, and it will prefer to use that copy over the one from the operating system."

Compile-time options of the shipped binaries (verbatim from that doc, abridged to what matters here):

```
SQLITE_ENABLE_FTS5            ← full-text search: available, guaranteed, on every device
SQLITE_ENABLE_MATH_FUNCTIONS  ← useful for the season-summary stats
SQLITE_ENABLE_RTREE
SQLITE_ENABLE_DBSTAT_VTAB
SQLITE_DQS=0                  ← ⚠ double-quoted string literals DISABLED (see Pitfalls)
SQLITE_STRICT_SUBTYPE=1
SQLITE_TEMP_STORE=2
SQLITE_OMIT_SHARED_CACHE
SQLITE_ENABLE_SESSION / SQLITE_ENABLE_PREUPDATE_HOOK
```

SQLite version bundled: **3.53.3** as of `sqlite3` 3.4.0, with 3.53.4 in the unreleased `3.5.1-wip`. That is far past the 3.37.0 needed for `STRICT` and the 3.34 needed for the trigram tokenizer. Architectures: Android armv7a/aarch64/x86/x64; iOS arm64 device + arm64/x64 simulator.

**Why this matters for Shed Book specifically:** `STRICT` tables and FTS5 stop being "maybe available" and become guaranteed. You can write the schema once and know it behaves identically on a 2019 Android 10 handset in a Welsh valley and a 2026 iPhone.

### 2.5 The one real operational catch

The build hook **downloads** prebuilt binaries from the package's GitHub releases at build time, verified against sha256 hashes baked into the published package (hook.md). Implications:

- Your *build machine* needs network access on a cold build. Your *app* does not — this is entirely build-time. The shipped binary has no network code path.
- CI/offline builds: `hook.md` documents `url_pattern` to point at an internal artifact mirror.
- `sqlite3` 3.3.4 changelog: "Build hook: Fix assets being re-downloaded too often." — so caching works, but expect a slow first build after `flutter clean`.
- `sqlite3` 3.1.1: "Hooks: Respect `HTTPS_PROXY` and related environment variables when downloading SQLite (requires Dart 3.11 or later)."

Document this in the repo README so a future you doesn't panic when a plane-mode `flutter clean && flutter build` fails.

### 2.6 The pubspec, concretely

```yaml
name: shed_book
environment:
  sdk: ^3.12.0
  flutter: ">=3.44.0"

dependencies:
  flutter:
    sdk: flutter
  drift: ^2.34.2
  drift_flutter: ^0.3.1
  path_provider: ^2.1.6
  path: ^1.9.0
  uuid: ^4.6.0
  share_plus: ^13.3.0
  # NOT sqlite3_flutter_libs  (EOL, no-op)
  # NOT sqlcipher_flutter_libs (EOL, no-op)

dev_dependencies:
  drift_dev: ^2.34.5
  build_runner: ^2.15.2
  test: any
```

`build.yaml`:

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          # Guarantees FTS5 is understood by drift's SQL analyser.
          sql:
            dialect: sqlite
            options:
              modules:
                - fts5
          # ISO-8601 text timestamps. Set on day 0. Changing this later
          # is a data migration, not a config change.
          store_date_time_values_as_text: true
          # Where make-migrations writes snapshots and generated tests.
          databases:
            shed_book: lib/data/db/database.dart
          schema_dir: drift_schemas/
          test_dir: test/drift/
```

> ⚠ The file must be named `build.yaml`, not `build.yml`. A [drift discussion](https://github.com/simolus3/drift/discussions/2670) exists solely because someone lost a day to that typo and FTS5 silently stayed disabled.

---

## 3. Opening the database

### 3.1 Where the file goes

`drift_flutter`'s default is `getApplicationDocumentsDirectory()` (confirmed by reading `drift_flutter/lib/src/native.dart`). **Override it to Application Support.** Drift's own setup docs show exactly this:

```dart
return driftDatabase(
  name: 'my_database',
  native: const DriftNativeOptions(
    databaseDirectory: getApplicationSupportDirectory,
  ),
);
```
— [drift.simonbinder.eu/setup](https://drift.simonbinder.eu/setup/)

Why Application Support and not Documents, for this app:

- Apple's guidance is that Application Support is "a good place to store files that might be in your Documents directory but that shouldn't be seen by users, such as a database that your app needs but that the user would never open manually."
- Both are backed up: Apple's File System Programming Guide states `Documents/` — "The contents of this directory are backed up by iTunes and iCloud" — and `Library/Application Support/` — "In iOS, the contents of this directory are backed up by iTunes and iCloud." So choosing Application Support costs **nothing** in backup coverage.
- The deciding factor is a foot-gun: if you ever set `UIFileSharingEnabled` / `LSSupportsOpeningDocumentsInPlace` (e.g. so users can grab exports from the Files app), the entire `Documents/` folder becomes user-visible and user-*deletable*. A shepherd tidying up their phone and deleting `shed_book.sqlite` is a product-ending bug. Exports go to the temp directory and out through the share sheet; the database stays somewhere nobody can browse to.

There is a genuine counter-argument to note: `path_provider`'s own doc comment for `getApplicationSupportDirectory` says *"Your app should not use this directory for user data files"*, and this database is unambiguously user data. Apple's own wording contradicts that for the specific case of an app-managed database. I'm siding with Apple and with Drift's docs. Record the reasoning so it isn't relitigated.

Android mapping (for the backup section later): `getApplicationSupportDirectory` → the engine's `PathUtils.getFilesDir`, i.e. `Context.getFilesDir()` → `/data/data/<pkg>/files/`. `getApplicationDocumentsDirectory` → `PathUtils.getDataDirectory` → `/data/data/<pkg>/app_flutter/`. Both are inside internal storage and both are covered by Android Auto Backup by default.

### 3.2 The connection, with pragmas

`drift_flutter` already does two useful things for you (read from `drift_flutter/lib/src/native.dart`):
- it sets `sqlite3.tempDirectory` to `getTemporaryDirectory()`, because `/tmp` is inaccessible to sandboxed apps;
- it uses `NativeDatabase.createBackgroundConnection(...)`, so SQLite runs on a background isolate and never janks the UI.

It does **not** set `journal_mode`, `synchronous`, `foreign_keys`, or `busy_timeout`. You must.

```dart
// lib/data/db/connection.dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';

/// MUST be a top-level (or static) function.
///
/// `DriftNativeOptions.setup` is documented as: "This function is sent across
/// isolates because that's where connections are actually opened, so this
/// function must not capture closed variables that can't be sent over
/// isolates." A closure over `this` will throw at open time.
void _configureConnection(CommonDatabase db) {
  // WAL is persistent in the file header, but setting it is idempotent and
  // costs microseconds. See sqlite.org/wal.html.
  db.execute('PRAGMA journal_mode = WAL;');

  // See §7. FULL, not NORMAL. This is a deliberate, contrarian choice.
  db.execute('PRAGMA synchronous = FULL;');

  // Per-connection, NOT persistent, NOT changeable inside a transaction.
  // Without this, every ON DELETE CASCADE below is decorative.
  db.execute('PRAGMA foreign_keys = ON;');

  // Export/VACUUM INTO can briefly contend with a write.
  db.execute('PRAGMA busy_timeout = 5000;');
}

QueryExecutor openConnection() {
  return driftDatabase(
    name: 'shed_book',
    native: const DriftNativeOptions(
      databaseDirectory: getApplicationSupportDirectory,
      setup: _configureConnection,
    ),
  );
}
```

`DriftNativeOptions`'s real signature (read from source, drift_flutter 0.3.1):

```dart
const DriftNativeOptions({
  bool shareAcrossIsolates = false,
  bool isolateDebugLog = false,
  Future<String> Function()? databasePath,
  Future<Object> Function()? databaseDirectory,
  Future<String?> Function()? tempDirectoryPath,
  void Function()? isolateSetup,
  void Function(CommonDatabase db)? setup,
});
```

Note there is **no** `readPool` on `DriftNativeOptions`. If you later want a read pool you drop to `NativeDatabase.createInBackground(file, readPool: n, setup: ...)` directly. Shed Book does not need one: a 400-ewe database has no read concurrency problem worth solving, and every extra connection is another place `PRAGMA foreign_keys` can be forgotten.

### 3.3 `beforeOpen`: schema self-check in debug only

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: stepByStep(/* see §9 */),
  beforeOpen: (details) async {
    // Cheap insurance against a migration that "succeeded" but produced a
    // schema that doesn't match the Dart definitions.
    assert(() {
      validateDatabaseSchema(this);
      return true;
    }());
  },
);
```

`validateDatabaseSchema` "validates that the schema of a database at runtime matches what one would expect" and is documented as debug-only because "it pulls in a fair amount of code that's not needed elsewhere" ([drift runtime schema inspection docs](https://drift.simonbinder.eu/docs/advanced-features/schema_inspection/)).

---

## 4. The schema

Design rules applied throughout:

1. **Every table is `STRICT`.** SQLite's dynamic typing is a liability in a ten-year data store — it will silently accept `'twin'` in an INTEGER column. `STRICT` "removes the freedom to specify a column without a datatype" and restricts types to `INT, INTEGER, REAL, TEXT, BLOB, ANY` ([sqlite.org/stricttables.html](https://sqlite.org/stricttables.html)). This directly serves safety rule 12.4: the database refuses garbage rather than storing it and pretending.
2. **Every relationship has a real FK with an explicit `ON DELETE`.** Never `noAction` by default-through-laziness — pick `cascade` or `restrict` and mean it.
3. **History tables, not mutable "current" fields**, wherever the spec cares about *when* something changed (fostering, pen occupancy). A mutable field destroys the answer to "what did 412 do last year?", which spec §1 calls the product's lasting value.
4. **Timestamps are two columns, not one.** Safety rule 12.5 ("timestamps are honest") is a schema requirement, not a UI requirement.
5. **No column that could encode veterinary advice has a DEFAULT.** Safety rule 12.1 is enforced by `NOT NULL` with no default, plus a CHECK on the provenance column.

### 4.1 Shared conventions

```dart
// lib/data/db/tables/common.dart
import 'package:drift/drift.dart';

/// Every entity carries:
///  - `id`   : INTEGER PRIMARY KEY (a rowid alias). Fast joins, small indexes,
///             and it is what FTS5 external-content tables need.
///  - `uid`  : UUID v7 text. The identity that survives export → re-import.
///  - audit  : when the row was written, and by which app version.
mixin Identified on Table {
  late final id = integer().autoIncrement()();
  late final uid = text().withLength(min: 36, max: 36).unique()();
  late final createdAt = dateTime()();
  late final updatedAt = dateTime()();
}
```

> `autoIncrement()` in Drift emits `INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT`. `AUTOINCREMENT` (as opposed to a bare `INTEGER PRIMARY KEY`) guarantees ids are never reused after a delete. For a record book where a deleted-then-recreated ewe must not inherit the old ewe's notes via a stale foreign key in an old export, that guarantee is worth the small `sqlite_sequence` overhead. Keep it.

### 4.2 Season — the scoping spine

```dart
@TableIndex(name: 'idx_season_start', columns: {#startDate})
class Seasons extends Table with Identified {
  late final year = integer()();                       // 2026
  late final label = text().withLength(min: 1, max: 60)();  // "2026 indoor"
  late final startDate = dateTime()();
  late final endDate = dateTime().nullable()();
  late final ewesToRam = integer().nullable()();       // denominator option A
  late final scanningResult = integer().nullable()();  // scanned lambs
  late final notes = text().nullable()();

  @override
  List<String> get customConstraints => [
    'CHECK (ewes_to_ram IS NULL OR ewes_to_ram >= 0)',
    'CHECK (scanning_result IS NULL OR scanning_result >= 0)',
    'CHECK (end_date IS NULL OR end_date >= start_date)',
  ];

  @override
  bool get isStrict => true;
}
```

**How Season scopes everything:** a Season is *not* a foreign key on `Ewe`. A ewe is a physical animal that persists across seasons; that is the whole point of the retention feature (§7.7). Season scopes the *events*: `Lambing`, `PenOccupancy`, `Treatment`, `Reminder`, and the `EweSeason` participation record.

### 4.3 Ewe

```dart
@TableIndex(name: 'idx_ewe_tag', columns: {#tag}, unique: true)
@TableIndex(name: 'idx_ewe_status', columns: {#status})
class Ewes extends Table with Identified {
  /// As typed by the user. Never normalised on write — safety rule 12.4.
  late final tag = text().withLength(min: 1, max: 32)();

  /// Digits-only projection of [tag], written in the same transaction.
  /// Used ONLY for the numeric keypad filter. Never shown to the user.
  late final tagDigits = text().withLength(min: 0, max: 32)();

  late final eid = text().withLength(min: 0, max: 32).nullable()();
  late final breed = text().nullable()();
  late final dateOfBirth = dateTime().nullable()();
  late final yearBorn = integer().nullable()();
  late final source = text().nullable()();      // "bought at Ruthin 2024"
  late final status = text().withDefault(const Constant('active'))();
  late final notes = text().nullable()();

  @override
  List<String> get customConstraints => [
    "CHECK (status IN ('active','sold','dead','culled'))",
    "CHECK (length(trim(tag)) > 0)",
  ];

  @override
  bool get isStrict => true;
}
```

`tag` is `UNIQUE`. Real flocks do reuse tag numbers across years after culls — but the spec's create-on-the-fly flow (§7.1) *requires* a tag to resolve to exactly one animal, at 3am, with no disambiguation dialog. So: unique tag, and when a user types a tag belonging to a culled ewe, the app surfaces her ("412 — culled 2025 — use anyway? / new animal?") rather than silently creating a duplicate. That is safety rule 12.4 applied to identity.

### 4.4 EweSeason — the thing the spec's `seasons[]` hides

The spec's shorthand `Ewe(… seasons[])` looks like a derived list. It isn't, and treating it as derived makes §7.8 impossible. You cannot compute a **barren rate** from lambings, because a barren ewe *has no lambing row*. You need an explicit "this ewe was put to the ram this season" record.

```dart
@TableIndex(name: 'idx_eweseason_season', columns: {#season})
class EweSeasons extends Table with Identified {
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();
  late final ewe = integer().references(Ewes, #id, onDelete: KeyAction.cascade)();

  /// 'to_ram' | 'scanned' | 'lambed' | 'barren' | 'aborted' | 'died' | 'sold'
  late final status = text().withDefault(const Constant('to_ram'))();
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

`ON DELETE CASCADE` from Season is correct here: "delete a season" (spec §7.10) should remove that season's participation records but must **not** remove the ewes.

### 4.5 Lambing — with honest timestamps

```dart
@TableIndex(name: 'idx_lambing_season_time', columns: {#season, #occurredAt})
@TableIndex(name: 'idx_lambing_ewe', columns: {#ewe})
class Lambings extends Table with Identified {
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();
  late final ewe = integer().references(Ewes, #id, onDelete: KeyAction.restrict)();

  /// When the lambing happened, per the record. Editable.
  late final occurredAt = dateTime()();

  /// Immutable. Set once, on insert, from the device clock. Never edited.
  late final capturedAt = dateTime()();

  /// Safety rule 12.5 made structural: 'auto' until the user edits the time,
  /// then 'edited' forever. The UI reads this to label the timestamp.
  late final timeSource = text().withDefault(const Constant('auto'))();

  /// EXACTLY what the user tapped: 1 = single … 5 = quad+, as declared.
  /// The number of Lamb rows is NOT forced to agree. Safety rule 12.4.
  late final declaredBirthType = integer()();

  late final ease = integer().nullable()();          // 1..5
  late final assistedBy = text().nullable()();
  late final presentationNote = text().nullable()();
  late final note = text().nullable()();

  @override
  List<String> get customConstraints => [
    "CHECK (time_source IN ('auto','edited'))",
    'CHECK (declared_birth_type BETWEEN 1 AND 5)',
    'CHECK (ease IS NULL OR ease BETWEEN 1 AND 5)',
    'CHECK (captured_at <= updated_at)',
  ];

  @override
  bool get isStrict => true;
}
```

The mismatch flag from safety rule 12.4 is a **view**, not a trigger and not a correction:

```sql
-- lib/data/db/views.drift
CREATE VIEW lambing_consistency AS
SELECT
  l.id                     AS lambing_id,
  l.declared_birth_type    AS declared,
  COUNT(lb.id)             AS recorded,
  (COUNT(lb.id) <> l.declared_birth_type) AS is_mismatched
FROM lambings l
LEFT JOIN lambs lb ON lb.lambing = l.id
GROUP BY l.id;
```

The Lambing Entry screen reads `is_mismatched` and shows a non-blocking badge. It never writes.

### 4.6 Lamb, and the birth-dam / rearing-dam split

This is the piece the spec calls out as "the flow most likely to be abandoned if it takes five taps" (§7.3), and it's the piece most likely to be modelled wrong.

**The rule: birth is a fact, rearing is a history.**

```dart
@TableIndex(name: 'idx_lamb_lambing', columns: {#lambing})
@TableIndex(name: 'idx_lamb_birthdam', columns: {#birthDam})
@TableIndex(name: 'idx_lamb_tag', columns: {#tag})
class Lambs extends Table with Identified {
  late final lambing = integer().references(Lambings, #id, onDelete: KeyAction.cascade)();

  /// Immutable. Denormalised from lambing.ewe at insert time so that
  /// "who bore this lamb" is a single indexed column and cannot drift.
  /// Never updated after insert — enforced by a trigger (below).
  late final birthDam = integer().references(Ewes, #id, onDelete: KeyAction.restrict)();

  late final tag = text().nullable()();
  late final tagDigits = text().nullable()();
  late final sex = text().nullable()();                  // 'f' | 'm' | 'unknown'
  late final birthWeightGrams = integer().nullable()();
  late final status = text().withDefault(const Constant('alive'))();
  late final deathAt = dateTime().nullable()();
  late final deathCause = text().nullable()();
  late final petLamb = boolean().withDefault(const Constant(false))();
  late final bottleFeeds = integer().withDefault(const Constant(0))();
  late final notes = text().nullable()();

  @override
  List<String> get customConstraints => [
    "CHECK (sex IS NULL OR sex IN ('f','m','unknown'))",
    "CHECK (status IN ('alive','dead','stillborn','sold'))",
    "CHECK ((status IN ('dead','stillborn')) = (death_at IS NOT NULL) OR status = 'stillborn')",
    'CHECK (birth_weight_grams IS NULL OR birth_weight_grams BETWEEN 200 AND 20000)',
    'CHECK (bottle_feeds >= 0)',
  ];

  @override
  bool get isStrict => true;
}
```

> The weight CHECK range is deliberately absurdly wide (0.2 kg – 20 kg). It exists to catch a unit slip (`5` entered meaning 5 kg vs 5 g), not to police husbandry. **Never narrow a CHECK to a range that encodes a veterinary opinion** — safety rule 12.2.

The immutability of `birth_dam` is enforced in SQL, not in Dart:

```sql
CREATE TRIGGER lamb_birth_dam_is_immutable
BEFORE UPDATE OF birth_dam ON lambs
WHEN old.birth_dam IS NOT new.birth_dam
BEGIN
  SELECT RAISE(ABORT, 'birth_dam is immutable; record a foster instead');
END;
```

Fostering is an append-only event log:

```dart
@TableIndex(name: 'idx_foster_lamb_time', columns: {#lamb, #effectiveAt})
class FosterEvents extends Table with Identified {
  late final lamb = integer().references(Lambs, #id, onDelete: KeyAction.cascade)();
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();

  /// NULL = removed from a rearing dam without assigning a new one
  /// (pet lamb / bottle / hospital pen).
  late final rearingDam = integer().nullable()
      .references(Ewes, #id, onDelete: KeyAction.restrict)();

  late final effectiveAt = dateTime()();
  late final method = text().nullable()();   // 'wet_adopt' | 'skin' | 'crate' | 'bottle' | 'other'
  late final note = text().nullable()();

  @override
  List<String> get customConstraints => [
    "CHECK (method IS NULL OR method IN ('wet_adopt','skin','crate','bottle','other'))",
  ];

  @override
  bool get isStrict => true;
}
```

And "who is rearing this lamb right now" is **derived**, not stored:

```sql
-- No mutable `rearing_dam_id` column anywhere. There is exactly one source
-- of truth (the event log) and therefore exactly zero ways for the cached
-- value and the history to disagree.
CREATE VIEW lamb_rearing AS
SELECT
  lb.id AS lamb_id,
  lb.birth_dam,
  COALESCE(
    (SELECT fe.rearing_dam
       FROM foster_events fe
      WHERE fe.lamb = lb.id
      ORDER BY fe.effective_at DESC, fe.id DESC
      LIMIT 1),
    lb.birth_dam
  ) AS rearing_dam,
  EXISTS (SELECT 1 FROM foster_events fe WHERE fe.lamb = lb.id) AS was_fostered
FROM lambs lb;
```

**Trade-off, stated:** a denormalised `lambs.rearing_dam` column would make the Ewe Card query one join shorter. It would also introduce a dual-write that a future code path will eventually get wrong, producing a lamb whose history says "fostered to 128" while the list screen says "412". At ~800 lambs the correlated subquery is microseconds against an index on `(lamb, effective_at)`. **Take the view.** If profiling ever says otherwise, add the cache *then*, maintained by a trigger on `foster_events`, never by Dart.

**Two-tap foster flow, in one transaction:**

```dart
Future<void> fosterLamb({
  required int lambId,
  required int seasonId,
  required int? toRearingDamId,
  String? method,
}) {
  return transaction(() async {
    final now = DateTime.now();
    await into(fosterEvents).insert(FosterEventsCompanion.insert(
      uid: uuid.v7(),
      lamb: lambId,
      season: seasonId,
      rearingDam: Value(toRearingDamId),
      effectiveAt: now,
      method: Value(method),
      createdAt: now,
      updatedAt: now,
    ));
    await (update(lambs)..where((l) => l.id.equals(lambId)))
        .write(LambsCompanion(updatedAt: Value(now)));
  });
}
```

Drift 2.34.0 changed transactions to begin with `BEGIN IMMEDIATE` (per its changelog), which takes the write lock up front and eliminates the mid-transaction upgrade-to-write deadlock class entirely. That is a free win for the "assume the phone dies" requirement.

### 4.7 Pen — occupancy as history

```dart
class Pens extends Table with Identified {
  late final label = text().withLength(min: 1, max: 24)();   // "3", "A2"
  late final sortOrder = integer().withDefault(const Constant(0))();
  late final isActive = boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column>> get uniqueKeys => [{label}];

  @override
  bool get isStrict => true;
}

@TableIndex(name: 'idx_penocc_pen_time', columns: {#pen, #enteredAt})
@TableIndex.sql(
  // Exactly one open occupancy per pen — enforced by the database, not by Dart.
  'CREATE UNIQUE INDEX idx_penocc_one_open '
  'ON pen_occupancies (pen) WHERE exited_at IS NULL',
)
class PenOccupancies extends Table with Identified {
  late final pen = integer().references(Pens, #id, onDelete: KeyAction.restrict)();
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();
  late final ewe = integer().nullable().references(Ewes, #id, onDelete: KeyAction.restrict)();

  late final enteredAt = dateTime()();
  late final exitedAt = dateTime().nullable()();
  /// 'turned_out' | 'moved' | 'died' | 'other'
  late final exitReason = text().nullable()();

  @override
  List<String> get customConstraints => [
    'CHECK (exited_at IS NULL OR exited_at >= entered_at)',
    "CHECK (exit_reason IS NULL OR exit_reason IN ('turned_out','moved','died','other'))",
    'CHECK ((exited_at IS NULL) = (exit_reason IS NULL))',
  ];

  @override
  bool get isStrict => true;
}

class PenOccupancyLambs extends Table {
  late final occupancy = integer()
      .references(PenOccupancies, #id, onDelete: KeyAction.cascade)();
  late final lamb = integer().references(Lambs, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {occupancy, lamb};

  @override
  bool get isStrict => true;
}
```

The partial unique index is the important bit. It is the whole "the whiteboard gets wiped" problem solved at the storage layer: the database will physically refuse to record two ewes in pen 3 at once, and "hours since penned" (§7.4) is `now - entered_at` on the open row — a computed value that cannot go stale.

`ON DELETE RESTRICT` on `pen` means you can't delete a pen that has history. Correct: the pen board is a record, not a whiteboard.

### 4.8 Treatment — where safety rule 12.1 lives

```dart
@TableIndex(name: 'idx_treatment_clear', columns: {#clearAt})
@TableIndex(name: 'idx_treatment_ewe', columns: {#ewe})
@TableIndex(name: 'idx_treatment_lamb', columns: {#lamb})
class Treatments extends Table with Identified {
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();

  // Polymorphic subject, done with two nullable FKs + a CHECK, so that
  // referential integrity and ON DELETE still work. See note below.
  late final ewe = integer().nullable().references(Ewes, #id, onDelete: KeyAction.cascade)();
  late final lamb = integer().nullable().references(Lambs, #id, onDelete: KeyAction.cascade)();

  late final productName = text().withLength(min: 1, max: 120)();
  late final dose = text().nullable()();          // free text: "2 ml"
  late final route = text().nullable()();         // 'sc','im','oral','topical','intranasal',…
  late final batchNo = text().nullable()();
  late final administeredAt = dateTime()();

  /// NOT NULL, NO DEFAULT. The app cannot write this row without the user
  /// having typed a number off the bottle. Safety rule 12.1, enforced by
  /// the schema rather than by a code review.
  late final withdrawalDays = integer()();

  /// Provenance. Constrained so that only one value is ever legal, which
  /// makes it impossible for a future feature to quietly add a suggested
  /// default without a schema migration and this comment being read.
  late final withdrawalSource =
      text().withDefault(const Constant('user_entered'))();

  /// administered_at + withdrawal_days, materialised so it is indexable
  /// and so the exported medicine book shows exactly what the app showed.
  late final clearAt = dateTime()();

  late final note = text().nullable()();

  @override
  List<String> get customConstraints => [
    'CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) = 1)',
    'CHECK (withdrawal_days >= 0)',
    "CHECK (withdrawal_source = 'user_entered')",
    'CHECK (clear_at >= administered_at)',
    'CHECK (length(trim(product_name)) > 0)',
  ];

  @override
  bool get isStrict => true;
}
```

**Why two nullable FKs and not `(subject_type TEXT, subject_id INT)`:** the type/id pair cannot be a foreign key, so SQLite cannot enforce that the referenced animal exists, cannot cascade on delete, and cannot stop an orphan. In a record that may be shown to a vet or an inspector, a treatment pointing at a deleted animal is worse than useless. The cost is one extra nullable column per subject type; the `CHECK ((a IS NOT NULL) + (b IS NOT NULL) = 1)` idiom keeps it honest.

Also note: **no `medicines` lookup table with pre-filled withdrawal periods.** Spec §11 says the app ships no medicine database. A `recent_products` view over `treatments` gives the "repeat last treatment" shortcut (§7.5) without ever shipping a number the user didn't type.

### 4.9 Reminder

```dart
@TableIndex(name: 'idx_reminder_due', columns: {#dueAt, #completedAt})
class Reminders extends Table with Identified {
  late final season = integer().nullable()
      .references(Seasons, #id, onDelete: KeyAction.cascade)();
  late final ewe = integer().nullable().references(Ewes, #id, onDelete: KeyAction.cascade)();
  late final lamb = integer().nullable().references(Lambs, #id, onDelete: KeyAction.cascade)();
  late final lambing = integer().nullable()
      .references(Lambings, #id, onDelete: KeyAction.cascade)();
  late final treatment = integer().nullable()
      .references(Treatments, #id, onDelete: KeyAction.cascade)();

  /// 'colostrum'|'navel'|'turn_out'|'tag_by'|'ring_dock_castrate'|'second_dose'|'withdrawal_end'|'custom'
  late final kind = text()();
  late final title = text()();
  late final dueAt = dateTime()();
  late final completedAt = dateTime().nullable()();
  late final muted = boolean().withDefault(const Constant(false))();

  /// The id handed to flutter_local_notifications, so a mute/complete can
  /// cancel the right OS notification. Nullable because scheduling can fail.
  late final osNotificationId = integer().nullable()();

  @override
  List<String> get customConstraints => [
    "CHECK (kind IN ('colostrum','navel','turn_out','tag_by',"
        "'ring_dock_castrate','second_dose','withdrawal_end','custom'))",
    'CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) + (lambing IS NOT NULL) '
        '+ (treatment IS NOT NULL) <= 1)',
  ];

  @override
  bool get isStrict => true;
}
```

### 4.10 Note, MediaAsset

```dart
@TableIndex(name: 'idx_note_created', columns: {#createdAt})
class Notes extends Table with Identified {
  late final ewe = integer().nullable().references(Ewes, #id, onDelete: KeyAction.cascade)();
  late final lamb = integer().nullable().references(Lambs, #id, onDelete: KeyAction.cascade)();
  late final lambing = integer().nullable()
      .references(Lambings, #id, onDelete: KeyAction.cascade)();
  late final season = integer().nullable()
      .references(Seasons, #id, onDelete: KeyAction.cascade)();

  late final body = text()();

  @override
  List<String> get customConstraints => [
    'CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) + (lambing IS NOT NULL) '
        '+ (season IS NOT NULL) >= 1)',
    'CHECK (length(trim(body)) > 0)',
  ];

  @override
  bool get isStrict => true;
}

class MediaAssets extends Table with Identified {
  /// RELATIVE to the media root. e.g. "2026/03/019524f7-...jpg".
  /// NEVER an absolute path — see §10.
  late final relativePath = text()();
  late final kind = text()();                 // 'photo' | 'voice'
  late final byteSize = integer()();
  late final durationMs = integer().nullable()();   // voice notes
  late final sha256 = text().nullable()();

  late final ewe = integer().nullable().references(Ewes, #id, onDelete: KeyAction.cascade)();
  late final lamb = integer().nullable().references(Lambs, #id, onDelete: KeyAction.cascade)();
  late final lambing = integer().nullable()
      .references(Lambings, #id, onDelete: KeyAction.cascade)();
  late final note = integer().nullable().references(Notes, #id, onDelete: KeyAction.cascade)();

  /// Set when a startup sweep finds the file gone. The row is NOT deleted —
  /// "photo taken 14 March, file missing" is more honest than silence.
  late final missingSince = dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{relativePath}];

  @override
  List<String> get customConstraints => [
    "CHECK (kind IN ('photo','voice'))",
    'CHECK (byte_size >= 0)',
    "CHECK (relative_path NOT LIKE '/%')",   // paranoia: reject absolute paths
    'CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) + (lambing IS NOT NULL) '
        '+ (note IS NOT NULL) = 1)',
  ];

  @override
  bool get isStrict => true;
}
```

### 4.11 Settings — three tables, not one JSON blob

```dart
/// Single-row typed settings. CHECK(id = 1) makes a second row impossible.
class AppSettings extends Table {
  late final id = integer().withDefault(const Constant(1))();
  late final weightUnit = text().withDefault(const Constant('kg'))();
  late final temperatureUnit = text().withDefault(const Constant('c'))();
  late final theme = text().withDefault(const Constant('dark'))();
  late final currentSeason = integer().nullable()
      .references(Seasons, #id, onDelete: KeyAction.setNull)();
  late final percentageDefinition =
      text().withDefault(const Constant('reared_per_ewe_to_ram'))();
  late final turnOutThresholdHours = integer().withDefault(const Constant(24))();
  late final exportPromptDismissedForSeason = integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (id = 1)',
    "CHECK (weight_unit IN ('kg','lb'))",
    "CHECK (temperature_unit IN ('c','f'))",
    "CHECK (theme IN ('dark','red_shift'))",     // no 'light' — spec §5
    "CHECK (percentage_definition IN ("
        "'born_per_ewe_to_ram','born_per_ewe_lambed',"
        "'reared_per_ewe_to_ram','reared_per_ewe_lambed'))",
    'CHECK (turn_out_threshold_hours BETWEEN 1 AND 336)',
  ];

  @override
  bool get isStrict => true;
}

/// "ewe / gimmer / shearling / theave / hogget" — spec §7.10.
class TerminologyOverrides extends Table {
  late final key = text()();          // 'ewe', 'lamb', 'pen', 'tup', …
  late final label = text()();
  @override
  Set<Column> get primaryKey => {key};
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

**Why not a JSON blob or SharedPreferences:** (a) a typed table participates in Drift's schema snapshots and migration tests, a blob does not; (b) settings live in the same file as the data, so one `VACUUM INTO` snapshot restores a complete, coherent app state — with SharedPreferences you would silently lose the user's units and terminology on restore, which is exactly the kind of small betrayal that makes someone go back to the notebook.

### 4.12 What `DateTime` actually stores

With `store_date_time_values_as_text: true`, Drift stores `DateTime.toIso8601String()`-based text: UTC values unchanged (`2026-03-14T03:20:42.015Z`), local values with the UTC offset appended (`2026-03-14T03:20:42.015 +00:00`) — see [DateTime storage](https://drift.simonbinder.eu/guides/datetime-migrations/), which states plainly that "ISO-8601 Strings are recommended for most applications due to its higher precision and timezone awareness" and that Unix timestamps remain the default only "for backward compatibility reasons".

For Shed Book this is the right choice for three reasons:
1. **Legibility.** Someone opening the file in 2036 reads `2026-03-14T03:20:42Z`, not `1773458442`.
2. **Millisecond precision**, so two lambings in the same minute sort deterministically.
3. **Offset preservation.** "3am" is a load-bearing fact in this product. Store local `DateTime`s and the offset comes along; a Unix timestamp throws it away and you can never reconstruct whether a March entry was made at 03:20 GMT or 03:20 BST.

⚠ **Set this before the first release and never change it.** Drift's docs: "Changing the datetime storage mode is not compatible with existing database schemas."

---

## 5. ID strategy

**Decision: dual key.** `id INTEGER PRIMARY KEY AUTOINCREMENT` for all internal joins and foreign keys; `uid TEXT UNIQUE` holding a **UUID v7** for export identity.

### Why not integer-only

The JSON backup (spec §7.9) exists so a user can restore onto a new phone. If ids are only integers, then:
- restoring a backup into a database that already has rows means renumbering everything and rewriting every FK — a bug farm;
- merging two backups (phone + tablet, or a partial restore) is impossible without a stable identity;
- a second export of the same data produces different ids after any local delete/recreate, so diffing two backups is meaningless.

A stable `uid` makes import an **upsert on `uid`**, which is idempotent: importing the same file twice is a no-op. That property is worth a lot when the user's mental model is "I'll just import my backup again and see."

### Why not UUID-only

- A `TEXT PRIMARY KEY` on a rowid table costs an extra index lookup for every join (SQLite still keeps a hidden rowid; your PK becomes a unique index that maps to it). With ~14 tables and joins on every screen, that is a real cost paid on every 3am tap.
- `WITHOUT ROWID` avoids the double lookup but then **FTS5 external-content tables lose their natural `content_rowid`** — FTS5 wants an INTEGER rowid to map back to the content table. Our search design (§6) depends on that.
- 36-char text keys inflate every index and every foreign key column, roughly 4-9× vs an integer. On a phone that is cheap; but the DB file is also the backup, and bloat makes `VACUUM INTO` snapshots bigger for no user benefit.

### Why UUID v7 over v4 and over ULID

| | v4 | **v7** | ULID |
|---|---|---|---|
| Standardised | RFC 9562 | **RFC 9562** | community spec |
| Time-ordered | no | **yes (48-bit ms prefix)** | yes |
| Text length | 36 | 36 | 26 |
| Dart package health | `uuid` 4.6.0, 11 days ago, verified | **same** | `ulid` 2.0.1, ~22 months ago |
| Index locality on insert | poor (random) | **good (monotonic prefix)** | good |
| Readable by every other tool | yes | **yes** | needs a decoder |

v7's monotonic prefix means the `uid` unique index appends rather than scattering — fewer page splits during a busy lambing night. ULID is a fine format and 20% shorter, but it is a community spec on a package last touched ~22 months ago, and its Crockford-base32 form is *less* recognisable to a human opening the CSV. Standard wins.

Privacy note that does **not** apply here: UUIDv7 leaks a creation timestamp. Irrelevant — the row already has `created_at`, and the file never leaves the device unless the user sends it.

```dart
// One instance, app-wide.
final uuid = const Uuid();
String newUid() => uuid.v7();
```

### The export contract

CSV and JSON exports both carry `uid` as the first column/field, plus a header row identifying the schema version:

```json
{
  "shed_book_backup": 1,
  "schema_version": 7,
  "exported_at": "2026-07-27T14:02:11.000Z",
  "app_version": "1.4.2",
  "ewes": [ { "uid": "019524f7-...", "tag": "412", … } ]
}
```

Import matches on `uid`, never on `tag` (tags get corrected; uids never change). Import of an unknown `schema_version` **higher** than the app's own must refuse with a clear message rather than guess — safety rule 12.4 applied to restore.

---

## 6. Search — two completely different problems

The spec asks for two things that sound alike and are not:

| | §7.7 full-text search | §7.1 partial tag matching |
|---|---|---|
| Input | words, phrases, "watery mouth" | 1–4 digits, `12` |
| Corpus | notes, treatments, lambing notes | ~400 short tag strings |
| Wanted | ranked results, snippets | instant list filter, ranked by shape |
| Right tool | **FTS5** | **in-memory filter** |
| Wrong tool | LIKE scan (no ranking, no snippets) | **FTS5 — physically cannot do it** |

### 6.1 Partial tag matching: the honest answer

**It is not an FTS problem, and the trigram trick people reach for does not work here.**

The spec's literal example is: *typing `12` surfaces 412, 128, 12.* That is an **infix** match on a **2-character** query.

- **Default FTS5 tokenizers (`unicode61`, `ascii`, `porter`) cannot do infix at all.** They tokenise `412` as the single token `412`. `MATCH '12*'` is a *prefix* query — it finds `128`, not `412`.
- **The trigram tokenizer can do infix, but not at 2 characters.** [sqlite.org/fts5.html](https://sqlite.org/fts5.html#the_trigram_tokenizer): *"Substrings consisting of fewer than 3 unicode characters do not match any rows when used with a full-text query."* Typing `12` into a trigram index returns **nothing**. The spec's own example is the counter-example.
- **`LIKE '%12%'` works but cannot use a B-tree index.** [sqlite.org/optoverview.html](https://sqlite.org/optoverview.html#the_like_optimization): the LIKE optimisation requires a pattern "that does not begin with a wildcard character." So it is a full table scan.

Now the honest scaling question: **at 400 ewes, who cares?** A full scan of 400 rows, each ~10 bytes of tag, is well under a millisecond — it's a few pages of a B-tree read from page cache. The database will never be the bottleneck; the keyboard will.

**Recommendation:** hold the tag list in memory and filter in Dart.

```dart
/// Loaded once at app start into a Riverpod provider and refreshed by a
/// drift `.watch()` on the ewes table. ~400 entries × ~40 bytes = ~16 KB.
class TagIndexEntry {
  final int eweId;
  final String tag;        // as typed by the user
  final String digits;     // digits-only projection
  final DateTime? lastTouched;
  const TagIndexEntry(this.eweId, this.tag, this.digits, this.lastTouched);
}

/// Rank matches by SHAPE, because that is what a shepherd's thumb expects:
///   exact  > prefix > suffix > infix, then most-recently-touched first.
List<TagIndexEntry> rankTagMatches(List<TagIndexEntry> all, String query) {
  final q = query.replaceAll(RegExp(r'\D'), '');
  if (q.isEmpty) return const [];

  int score(TagIndexEntry e) {
    final d = e.digits;
    if (d == q) return 0;
    if (d.startsWith(q)) return 1;
    if (d.endsWith(q)) return 2;
    if (d.contains(q)) return 3;
    return 99;
  }

  final hits = [
    for (final e in all)
      if (score(e) < 99) e,
  ]..sort((a, b) {
      final s = score(a).compareTo(score(b));
      if (s != 0) return s;
      final ra = a.lastTouched, rb = b.lastTouched;
      if (ra != null && rb != null) return rb.compareTo(ra);
      if (ra != null) return -1;
      if (rb != null) return 1;
      return a.digits.length.compareTo(b.digits.length);
    });
  return hits;
}
```

Why in-memory beats even the (perfectly adequate) `LIKE '%12%'` query:

1. **No async.** No `await`, no frame where the list is empty. Every keypad tap re-filters synchronously inside the same frame. That is what makes the "under fifteen seconds" number achievable.
2. **You get ranking for free**, and ranking is the actual UX problem. A raw `LIKE` returns `128` and `412` in rowid order; the shepherd wants `12` first.
3. **Works identically in the free tier and at 400 ewes** — no behaviour cliff.

Scaling honesty: this design is fine to roughly 20,000 tags (a 20k-element `contains` sweep is ~1 ms). Shed Book's stated ceiling is 400. If someone ever showed up with 50,000 animals, the fix is a trigram FTS5 index for ≥3-character queries with the in-memory path retained for 1–2 characters — but that is a v3 problem for a different product.

Keep `tag_digits` in the schema anyway: it makes the fallback SQL query (`WHERE tag_digits LIKE ?`) trivially available for the export/report paths, and it costs nothing.

### 6.2 Full-text search: FTS5, one fan-in table

The requirement is "full-text offline search across every note, tag, and treatment" returning **one ranked list**. Two shapes are possible:

- **(a) One FTS table per source table.** Then a unified search is a `UNION ALL` of N MATCH queries with N different `bm25()` scales that aren't comparable. Ugly.
- **(b) One fan-in `search_docs` table + one FTS index over it.** One MATCH, one `bm25()` ordering, one `snippet()`. **Take (b).**

FTS5 cannot be declared in Dart — drift's own docs: *"It's not possible to declare fts5 tables, or queries on fts5 tables, in Dart."* So this lives in a `.drift` file.

```sql
-- lib/data/db/search.drift

-- Fan-in table: a normal STRICT drift table, one row per searchable thing.
CREATE TABLE search_docs (
  id           INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  subject_kind TEXT    NOT NULL,
  subject_id   INTEGER NOT NULL,
  ewe_id       INTEGER,                -- for "filter to this ewe" searches
  season_id    INTEGER,
  title        TEXT    NOT NULL,       -- "412 · treatment · Alamycin"
  body         TEXT    NOT NULL,
  occurred_at  TEXT    NOT NULL,
  UNIQUE (subject_kind, subject_id)
) STRICT;

-- The index. External content: FTS5 stores only the inverted index and
-- reads column values back out of search_docs when it needs them.
--  * porter  -> "lambed"/"lambing" both match "lamb"
--  * unicode61 remove_diacritics 2 -> accent-insensitive
--  * prefix='2 3' -> "wat*" is indexed, so typing three letters is fast
CREATE VIRTUAL TABLE search_fts USING fts5(
  title,
  body,
  content='search_docs',
  content_rowid='id',
  tokenize='porter unicode61 remove_diacritics 2',
  prefix='2 3'
);

-- The three standard sqlite.org sync triggers.
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

That trigger pattern is exactly the one [sqlite.org/fts5.html](https://sqlite.org/fts5.html) prescribes for external-content tables.

Then, **triggers on the source tables that maintain `search_docs` with plain SQL** — no FTS5 special commands involved, so drift's analyser is happy:

```sql
CREATE TRIGGER notes_search_ai AFTER INSERT ON notes BEGIN
  INSERT INTO search_docs (subject_kind, subject_id, ewe_id, season_id,
                           title, body, occurred_at)
  VALUES ('note', new.id, new.ewe, new.season,
          'note', new.body, new.created_at);
END;

CREATE TRIGGER notes_search_au AFTER UPDATE OF body ON notes BEGIN
  UPDATE search_docs SET body = new.body
   WHERE subject_kind = 'note' AND subject_id = new.id;
END;

CREATE TRIGGER notes_search_ad AFTER DELETE ON notes BEGIN
  DELETE FROM search_docs WHERE subject_kind = 'note' AND subject_id = old.id;
END;

-- …and the equivalent trio for treatments, lambings, lambs, ewes.
```

**Triggers vs application code — the actual trade-off:**

| | SQL triggers | Dart repository code |
|---|---|---|
| Can be bypassed | only by a raw `customStatement` | by **any** new code path, forever |
| Runs in the write transaction | yes, atomically | yes, if you remember `transaction()` |
| Survives a bulk import / restore | yes, automatically | only if the import path calls it |
| Debuggable | painful (`RAISE`, log statements) | easy |
| Visible in schema snapshots / migration tests | yes | no |
| Analyser friction with FTS5 special commands | some (see below) | none |

**Verdict: triggers.** The decisive case is JSON restore. On restore you will bulk-insert thousands of rows through whatever path is fastest, and *that* is precisely when a Dart-side "also update the search index" call gets skipped and the user's five seasons come back unsearchable. Triggers cannot be skipped.

**Known friction to prototype in week one:** drift's SQL analyser does not fully model FTS5's special INSERT commands — [drift#3322](https://github.com/simolus3/drift/issues/3322) is open, reporting that `INSERT INTO t(t) VALUES('optimize')` produces *"Some columns are required but not present here."* The `'delete'` command in `search_docs_ad`/`_au` is the same family. If drift refuses to generate for those triggers:
- **Fallback A:** create those three triggers via `customStatement` in `onCreate` and in the corresponding migration step, and add the same statements to the generated migration-test path.
- **Fallback B:** drop external content — make `search_fts` a plain FTS5 table that stores its own copy of the text. `DELETE FROM search_fts WHERE rowid = old.id` then works as ordinary SQL with no special commands at all. Costs a duplicate copy of the note text, which for this corpus (a few hundred KB) is nothing.

Fallback B is honestly the lower-risk option for a solo developer, and I would take it if Fallback A costs more than half a day. Note it and move on — do not let the search index block the core loop.

**Searching, from Dart:**

```dart
/// FTS5 has its own query syntax: bare `AND`, `OR`, `NOT`, `NEAR`, `*`, `-`,
/// `:` and `"` are operators. User text MUST be tokenised and quoted or a
/// note containing "OR" will throw a syntax error at 3am.
String toFts5Query(String raw) {
  final tokens = raw
      .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return '';
  // Quote each token; prefix-match the last one so results appear while typing.
  return [
    for (var i = 0; i < tokens.length; i++)
      i == tokens.length - 1 ? '"${tokens[i]}"*' : '"${tokens[i]}"',
  ].join(' ');
}
```

```sql
-- lib/data/db/search.drift  (drift generates a typed method for this)
searchAll(:query AS TEXT, :limit AS INT):
SELECT
  d.subject_kind,
  d.subject_id,
  d.ewe_id,
  d.title,
  snippet(search_fts, 1, '[', ']', '…', 12) AS excerpt,
  bm25(search_fts, 2.0, 1.0)                AS rank
FROM search_fts f
JOIN search_docs d ON d.id = f.rowid
WHERE search_fts MATCH :query
ORDER BY rank
LIMIT :limit;
```

`bm25(search_fts, 2.0, 1.0)` weights `title` twice as heavily as `body`, so a search for `412` ranks that ewe's own records above a passing mention in someone else's note. Note that `bm25()` returns a *negative* score where smaller is better, so `ORDER BY rank` ascending is correct.

**How it degrades with typos: it doesn't degrade, it fails.** FTS5 has no fuzzy matching and `spellfix1` is not in the bundled build's compile options. `watry` returns zero rows. Mitigations, in order of cost:
1. **Prefix matching on the last token** (above) covers truncation, which is the most common cold-fingers error — `wate` finds `watery`.
2. **Porter stemming** covers inflection — `lambed`/`lambing`/`lambs` all match `lamb`.
3. **Zero-results fallback:** when FTS returns nothing, run a bounded Dart-side Levenshtein/bigram pass over `search_docs.body` (≤ a few thousand short rows) and offer *"Did you mean…"*. This is affordable **only** because the corpus is tiny — say so in the code comment so nobody ports it to a bigger app.
4. Do **not** add a second trigram index just for typos. It roughly doubles index size and still won't fix a transposition.

---

## 7. Crash safety — and the one place I disagree with the common advice

### 7.1 WAL

Set `PRAGMA journal_mode = WAL`. From [sqlite.org/wal.html](https://sqlite.org/wal.html): "WAL is significantly faster in most scenarios", "readers do not block writers and a writer does not block readers", fewer `fsync()`s, and it is persistent — "If a process sets WAL mode, then closes and reopens the database, the database will come back in WAL mode."

The documented disadvantages are all irrelevant here: no network filesystem (it's an app sandbox), no >100 MB transactions, no multi-process access.

### 7.2 `synchronous`: FULL, not NORMAL

This is the contrarian call in this document.

The universal mobile advice — repeated in the SQLite docs themselves — is `WAL` + `synchronous=NORMAL`. [sqlite.org/pragma.html](https://sqlite.org/pragma.html#pragma_synchronous) says:

> "WAL mode is always consistent with synchronous=NORMAL, but WAL mode does lose durability. A transaction committed in WAL mode with synchronous=NORMAL might roll back following a power loss or system crash."

and adds that NORMAL "provides the best balance between performance and safety for most applications running in WAL mode" because "You lose durability across power loss with synchronous NORMAL in WAL mode, but that is not important for most applications."

**Shed Book is not most applications.** Read spec §5 again: *"Assume the phone dies. Every write is committed immediately. There is no draft state to lose."* And §2: the entire product exists because entries deferred by ninety minutes come out wrong. The failure mode `synchronous=NORMAL` permits is: shepherd records a triplet lambing at 03:20, phone's battery — already at 4% because it's night eleven — dies at 03:21, and on reboot the last transaction is gone. Not corrupt. Just *silently absent*. The shepherd will not know, and will not re-enter it, because as far as they're concerned they already did.

That is the exact class of failure the product was built to eliminate. Trading it away for microseconds is the wrong trade.

**What FULL costs:** one extra `fsync()` of the WAL per commit. On modern phone flash that is single-digit milliseconds. Shed Book's write rate is *one transaction per user action* — a tap, not a keystroke. Even a busy lambing night is a few hundred commits. Total added cost across a whole season: under a second.

**Where to relax it:** bulk operations. JSON restore and CSV import write thousands of rows; there, wrap the whole import in a single transaction and drop to `synchronous = NORMAL` for its duration, then restore FULL. A failed import is re-runnable (idempotent on `uid`, §5); a lost lambing entry is not.

```dart
Future<void> runBulkImport(Future<void> Function() body) async {
  await customStatement('PRAGMA synchronous = NORMAL;');
  try {
    await transaction(body);
  } finally {
    await customStatement('PRAGMA synchronous = FULL;');
    await customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
  }
}
```

**Caveat on the whole discussion, from sqlite.org itself:** [howtocorrupt.html](https://www.sqlite.org/howtocorrupt.html) notes that "most consumer-grade mass storage devices lie about syncing." `synchronous=FULL` narrows the window; it does not close it on hardware that ignores the barrier. It is still strictly better than NORMAL, and it is the strongest guarantee available from userspace.

### 7.3 One transaction per mutation

The rule: **every user-visible action is exactly one transaction, opened and closed inside a single Dart async function with no `await` on anything the user does.**

```dart
// GOOD — atomic, short, commits before the UI even rebuilds.
Future<int> recordLambing({...}) => transaction(() async {
  final lambingId = await into(lambings).insert(...);
  for (final l in lambs) { await into(this.lambs).insert(...); }
  await into(reminders).insert(colostrumReminder(lambingId));
  return lambingId;
});

// BAD — a transaction held open across a UI round-trip. The write lock is
// held while a human decides something. Never do this.
Future<void> bad() => transaction(() async {
  await into(lambings).insert(...);
  final tag = await showTagDialog();      // ← human latency inside a txn
  await into(lambs).insert(...);
});
```

Two consequences that matter:
- **Multi-step UI is multi-step persistence.** The Lambing Entry screen writes the lambing row on the *first* tap (birth type), then each subsequent field is its own small `UPDATE` transaction. There is no "Save" button, because a Save button is a draft, and spec §5 says there is no draft state. Every field the shepherd touches is on disk before their thumb leaves the glass.
- Drift 2.34.0 opens transactions with `BEGIN IMMEDIATE`, so a transaction that will write takes the lock immediately rather than upgrading mid-flight. No `SQLITE_BUSY` upgrade failures.

### 7.4 What "assume the phone dies" actually costs

| Design choice | Cost | What it buys |
|---|---|---|
| `synchronous=FULL` | ~1 extra fsync/commit, low single-digit ms | The last entry survives a flat battery |
| One txn per field edit | more commits, all tiny | No draft, nothing to lose |
| No "Save" button | slightly more code (write-on-change) | Passes the 3am test |
| WAL | +2 sidecar files | Reader never blocks the writer; export can run while typing |
| `busy_timeout=5000` | up to 5 s stall in the worst case | Export/VACUUM never throws `SQLITE_BUSY` at the user |

---

## 8. Backing the file up safely (and what WAL does to that)

### 8.1 Never `File.copy` the database

In WAL mode the database is **three** files: `shed_book.sqlite`, `shed_book.sqlite-wal`, `shed_book.sqlite-shm`. sqlite.org/wal.html: the `-wal` file is "part of the persistent state of the database" and "If a database file is separated from its WAL file, then transactions that were previously committed to the database might be lost, or the database file might become corrupted."

howtocorrupt.html reinforces it:

> "Systems that run automatic backups in the background might try to make a backup copy of an SQLite database file while it is in the middle of a transaction. The backup copy then might contain some old and some new content, and thus be corrupt."

A naive `File(dbPath).copy(exportPath)` therefore produces, best case, a database missing the last few hours of a lambing night; worst case, a corrupt file the user believes is their backup. **This is the single most dangerous piece of code someone could write in this app.**

### 8.2 `VACUUM INTO` is the answer

`package:sqlite3`'s `CommonDatabase` exposes no `backup()` method (checked the [API docs](https://pub.dev/documentation/sqlite3/latest/common/CommonDatabase-class.html) — `execute`, `select`, `prepare`, `createFunction`, `userVersion`, `close`, streams; no `backup`). The online-backup API is not surfaced. So the mechanism is SQL:

From [sqlite.org/lang_vacuum.html](https://sqlite.org/lang_vacuum.html):
> "VACUUM INTO is an alternative to the backup API for generating backup copies of a live database."
> "The file named by the INTO clause must not previously exist, or else it must be an empty file, or the VACUUM INTO command will fail with an error."
> "If interrupted by an unplanned shutdown or power loss, the generated output database might be incomplete and corrupt."

Unlike a plain `VACUUM`, `VACUUM INTO` does not need exclusive access, so it runs happily while the app is in use.

```dart
/// Produces a single, self-contained, fully-checkpointed .sqlite file with
/// no -wal/-shm sidecars, safe to hand to the share sheet.
Future<File> snapshotDatabase() async {
  final tmp = await getTemporaryDirectory();
  final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final out = File(p.join(tmp.path, 'shed-book-$stamp.sqlite'));

  // VACUUM INTO refuses to overwrite. Clear any stale file first.
  if (await out.exists()) await out.delete();

  // Bind the path — never interpolate a user-influenced string into SQL.
  await customStatement('VACUUM INTO ?', [out.path]);
  return out;
}
```

Then:

```dart
final file = await snapshotDatabase();
await SharePlus.instance.share(ShareParams(
  files: [XFile(file.path)],
  fileNameOverrides: const ['shed-book-backup.sqlite'],
));
```
(`share_plus` 13.3.0's current API is `SharePlus.instance.share(ShareParams(...))`; the old static `Share.shareXFiles` is deprecated.)

Because the export lands in `getTemporaryDirectory()` — which Apple documents as *not* backed up and which Android excludes from Auto Backup — stale snapshots don't inflate the user's iCloud usage. Sweep the temp dir on app start.

### 8.3 Two export formats, two purposes — be explicit about which is which

| Format | Purpose | Survives without Shed Book? |
|---|---|---|
| **JSON backup** | Restore onto a new device; the spec's stated safety net | Yes — plain text, self-describing, readable in a text editor in 2036 |
| **`VACUUM INTO` .sqlite** | Byte-faithful snapshot; fastest and most complete restore | Yes — any SQLite tool opens it |
| CSV × 3 | Hand to a spreadsheet, a vet, an accountant | Yes |
| PDF flock book / medicine book | Print, show to an inspector | Yes (with the §12.3 disclaimer footer) |

Ship JSON as the *primary* backup because it is the format most likely to still be interpretable if the schema has moved on by five versions. Ship the `.sqlite` snapshot as the *fast* path because restoring it is a file copy plus a migration run, and it cannot lose a field the JSON serialiser forgot about.

---

## 9. Migrations

### 9.1 The rule for an app with no server

**Forward-only, additive-by-default, never destructive.** A user can be on v1.0 for two seasons and jump straight to v2.4. There is no server to run a backfill, no way to push a hotfix to a phone that never goes online, and no cloud copy to restore from if a migration eats a table. Therefore:

1. **Never `DROP COLUMN` on a column that has held user data.** Add the new column, backfill, stop writing the old one, and leave it. Storage is free; a shepherd's 2027 season is not.
2. **Never `DROP TABLE`** for the same reason. Rename to `x_deprecated_v5` if it truly must go, and only delete it two major versions later.
3. **Never change a column's meaning in place.** New meaning ⇒ new column.
4. **Every migration is tested from every prior version**, not just N-1.
5. **Bump `schemaVersion` and regenerate the snapshot in the same commit.** Add a CI step that runs `make-migrations` and fails if it produces a diff.

Drift helps: as of 2.31.0, "Step-by-step migrations now automatically throw an error if a database downgrade is attempted" — so a user who somehow sideloads an older build gets a clear failure instead of a silently mangled database.

### 9.2 Setup

`build.yaml` already declares `schema_dir: drift_schemas/` and `test_dir: test/drift/` (§2.6). Then:

```bash
dart run drift_dev make-migrations
```

Per [the migrations guide](https://drift.simonbinder.eu/migrations/), this "generates schema snapshot files and a `.steps.dart` file containing compressed schema versions" plus test scaffolding.

### 9.3 The database class

```dart
@DriftDatabase(
  tables: [
    Seasons, Ewes, EweSeasons, Lambings, Lambs, FosterEvents,
    Pens, PenOccupancies, PenOccupancyLambs,
    Treatments, Reminders, Notes, MediaAssets,
    AppSettings, TerminologyOverrides, ReminderRules,
  ],
  include: {'search.drift', 'views.drift'},
)
class ShedBookDatabase extends _$ShedBookDatabase {
  ShedBookDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaults();
    },
    onUpgrade: stepByStep(
      // from1To2: (m, schema) async {
      //   await m.addColumn(schema.ewes, schema.ewes.eid);
      // },
    ),
    beforeOpen: (details) async {
      assert(() { validateDatabaseSchema(this); return true; }());
    },
  );
}
```

`stepByStep` gives each callback "a `schema` parameter that gives you access to the schema at the version you're migrating to" — meaning migration code references the *historical* table shape, not today's Dart classes. That is the mechanism that stops a v1→v2 migration from silently breaking the day you add a column in v9.

For anything `ALTER TABLE` can't do — changing a CHECK, tightening a type, adding a NOT NULL — use `m.alterTable(TableMigration(...))`, which implements SQLite's [12-step procedure](https://sqlite.org/lang_altertable.html) (create new table → copy → drop old → rename). Drift's docs are explicit that the *order* matters, and sqlite.org warns that the naive "rename old, create new, copy, drop" order "risks corrupting references in triggers, views, and foreign key constraints." Let Drift do it; don't hand-roll.

⚠ The 12-step procedure requires `PRAGMA foreign_keys=OFF` for its duration, and **`PRAGMA foreign_keys` is a no-op inside a transaction.** Drift wraps migrations in a transaction. If you find yourself needing FK-off behaviour, use `PRAGMA defer_foreign_keys = ON` inside the transaction instead, and run `PRAGMA foreign_key_check` after.

### 9.4 Testing every path

```bash
dart run drift_dev schema generate --data-classes --companions \
    drift_schemas/ test/generated_migrations/
```

```dart
// test/drift/migration_matrix_test.dart
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  // The whole point: not just N-1 -> N. Every from -> to.
  const latest = 1; // keep in sync with schemaVersion
  for (var from = 1; from < latest; from++) {
    for (var to = from + 1; to <= latest; to++) {
      test('migrates v$from -> v$to', () async {
        final connection = await verifier.startAt(from);
        final db = ShedBookDatabase(connection);
        // migrateAndValidate extracts all CREATE statements from
        // sqlite_schema and semantically compares them against the
        // expected schema at `to`.
        await verifier.migrateAndValidate(db, to);
        await db.close();
      });
    }
  }

  test('data written at v1 survives migration to head', () async {
    final schema = await verifier.schemaAt(1);
    // ... insert a season, a ewe, a lambing, two lambs, a foster event
    //     using the generated v1 companions ...
    final db = ShedBookDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, latest);
    // ... assert the ewe's tag, the lamb count, and the foster history
    //     are all still there and still linked ...
    await db.close();
  });
}
```

Add one more test that no generator gives you and that this app specifically needs:

```dart
test('every migration path preserves referential integrity', () async {
  // After migrating, PRAGMA foreign_key_check must return zero rows.
  final rows = await db.customSelect('PRAGMA foreign_key_check;').get();
  expect(rows, isEmpty);
});
```

⚠ **FTS5 + the schema verifier.** FTS5 virtual tables create shadow tables (`search_fts_data`, `_idx`, `_docsize`, `_config`) which appear in `sqlite_schema`. Schema-diffing tools across ecosystems have historically choked on these ([prisma#8106](https://github.com/prisma/prisma/issues/8106), [rails#52354](https://github.com/rails/rails/pull/52354) are the same bug in other stacks). **Write the migration test with FTS5 present on day one**, before the schema has any real content, so you find out immediately whether Drift's verifier tolerates the shadow tables. If it doesn't, that's the trigger to switch to §6.2 Fallback B.

---

## 10. Media files

### 10.1 Filesystem, not BLOBs

SQLite's own benchmark ([fasterthanfs.html](https://www.sqlite.org/fasterthanfs.html)) shows the database winning for *small* blobs — "SQLite reads and writes small blobs (for example, thumbnail images) 35% faster than the same blobs can be read from or written to individual files" — with the test using **10 KB** blobs, and citing Gray's finding that the crossover is somewhere between 250 KiB and 1 MiB.

Lambing photos are 300 KB – 5 MB. Voice notes are 100 KB – 1 MB. We are on the wrong side of the crossover, and three app-specific reasons make it worse:

1. **`VACUUM INTO` copies the whole database.** With photos inline, every "export backup" rewrites gigabytes. Without them, the DB stays a few MB and the snapshot is instant — which is what makes the daily export prompt (§7.9) something a user will actually accept.
2. **Android Auto Backup caps at 25 MB per app.** A database with photos inline blows past that and the *entire* backup — including the irreplaceable records — silently stops happening.
3. **A media file can be recovered by hand from a device backup even if the database is broken.** A BLOB cannot.

**Decision: filesystem. The database holds the index; the filesystem holds the bytes.**

### 10.2 Layout

```
<getApplicationSupportDirectory()>/
  shed_book.sqlite
  shed_book.sqlite-wal
  shed_book.sqlite-shm
  media/
    2026/03/019524f7-8a1c-7b3e-9f04-2c9a1e7d55b0.jpg
    2026/03/019524f8-1d02-7c11-8e77-3ab0c4d19e21.m4a
    .trash/
      2026-07-27/019523aa-....jpg
```

- **Same container as the DB.** They ride the same OS backup and the same restore. Splitting them across Documents and Application Support is how you end up restoring a database whose photos are all missing.
- **Year/month shards** keep any one directory under a few hundred entries, which keeps directory listing (used by the orphan sweep) fast.
- **Filename = the media asset's UUIDv7 + extension.** Never the tag number: tags get corrected, and a rename would orphan the row. Never a sequence number: collisions after a restore.

### 10.3 THE iOS GOTCHA — store relative paths only

**Never store an absolute path in the database.** On iOS the app's data container is `/var/mobile/Containers/Data/Application/<UUID>/…`, and that UUID is not stable. [flutter/flutter#23957](https://github.com/flutter/flutter/issues/23957) is a report of `getApplicationDocumentsDirectory()` returning three *different* container UUIDs across successive launches of the same app:

```
/var/mobile/Containers/Data/Application/8A4BEDFC-FD32-4783-8468-03CCD8F83AA3/Documents
/var/mobile/Containers/Data/Application/28ECEAF4-E764-4368-A79E-D5E5C15CD3C6/Documents
/var/mobile/Containers/Data/Application/1BDF398C-C0F1-43DE-B977-EA4ECA27B6A0/Documents
```

Apple's own guidance says the same thing prescriptively. From the [File System Programming Guide](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/AccessingFilesandDirectories/AccessingFilesandDirectories.html):

> "When you need to locate a file in one of the standard directories, use the system frameworks to locate the directory first and then use the resulting URL to build a path to the file."

> "**Important:** Although they are safe to use while your app is running, file reference URLs are not safe to store and reuse between launches of your app because a file's ID may change if the system is rebooted. If you want to store the location of a file persistently between launches of your app, create a bookmark."

Bookmarks are an Apple-only concept with no clean Flutter equivalent, and we don't need them: the files are inside our own container. **The correct portable answer is: store the path relative to the media root, and resolve it against a freshly-obtained root on every access.**

When it bites you if you get it wrong: after an app update, after a device restore, after every re-install from Xcode during development, and after a device-to-device transfer. On Android the path happens to be stable (`/data/data/<pkg>/files/`), which is exactly why this bug ships — it never reproduces on the dev's Android phone.

```dart
class MediaStore {
  Directory? _rootCache;

  /// Resolved fresh per app run. Deliberately NOT persisted anywhere.
  Future<Directory> _root() async {
    final cached = _rootCache;
    if (cached != null) return cached;
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'media'));
    await dir.create(recursive: true);
    return _rootCache = dir;
  }

  /// The ONLY thing that ever goes into the database.
  String newRelativePath(String extension) {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    return p.join(y, m, '${uuid.v7()}.$extension');
  }

  Future<File> resolve(String relativePath) async =>
      File(p.join((await _root()).path, relativePath));
}
```

Add the belt-and-braces CHECK from §4.10 — `CHECK (relative_path NOT LIKE '/%')` — so the database physically rejects an absolute path if someone regresses this in eighteen months.

### 10.4 Size limits

Enforce at capture, not at export:

| Asset | Cap | Rough size | Why |
|---|---|---|---|
| Photo | longest edge 2048 px, JPEG q80 | 300–600 KB | Legible on any phone; 10× smaller than raw |
| Voice note | 120 s, AAC mono 32 kbps | ~480 KB | A lambing note is a sentence, not a podcast |

Sanity check at the stated ceiling: 400 ewes × 1 lambing × 1 photo ≈ 400 × 500 KB ≈ **200 MB** of media against a **~5 MB** database. That ratio is exactly why media must not be in the DB, and exactly why media must be excluded from Android cloud backup (§11).

Write the byte size into `media_assets.byte_size` on capture so Settings can show "Photos: 187 MB (412 files)" without walking the filesystem.

### 10.5 Orphan cleanup — two directions, both non-destructive

**Direction 1 — files with no row** (capture crashed after writing the file, before the transaction committed; or a restore brought files the DB doesn't reference):

```dart
Future<void> sweepOrphanFiles() async {
  final root = await _root();
  final known = (await db.select(db.mediaAssets).get())
      .map((a) => a.relativePath).toSet();

  await for (final entity in root.list(recursive: true)) {
    if (entity is! File) continue;
    final rel = p.relative(entity.path, from: root.path);
    if (rel.startsWith('.trash')) continue;
    if (known.contains(rel)) continue;

    // Move to .trash with a date stamp. NEVER delete immediately.
    // Rule 12.4: the app does not silently destroy the user's things.
    final grave = File(p.join(root.path, '.trash',
        DateTime.now().toIso8601String().split('T').first, rel));
    await grave.parent.create(recursive: true);
    await entity.rename(grave.path);
  }
}
```

Purge `.trash/<date>/` folders older than 30 days. Surface the total in Settings as "Recoverable files: 12 (deleted 3 days ago)".

**Direction 2 — rows with no file** (user deleted the container contents; a partial restore; iCloud evicted something):

```dart
Future<void> sweepMissingFiles() async {
  for (final asset in await db.select(db.mediaAssets).get()) {
    if (asset.missingSince != null) continue;
    final f = await mediaStore.resolve(asset.relativePath);
    if (!await f.exists()) {
      await (db.update(db.mediaAssets)..where((t) => t.id.equals(asset.id)))
          .write(MediaAssetsCompanion(missingSince: Value(DateTime.now())));
    }
  }
}
```

**Do not delete the row.** "Photo taken 14 March 03:22 — file no longer on this phone" is a true statement and a useful one. Deleting it makes the app lie by omission. This is safety rule 12.4 applied to media.

Run both sweeps **off the critical path** — on a post-frame callback after the first screen renders, not before. Nothing in the startup sequence may sit between the user's thumb and a saved lambing event.

### 10.6 What happens on restore

- **iOS iCloud restore:** the whole container comes back, DB + media, in a new container UUID. Relative paths resolve correctly against the new root. Absolute paths would all 404. This is the payoff for §10.3.
- **Android Auto Backup restore:** if media is excluded from `<cloud-backup>` (recommended, §11), the DB comes back and every media row gets flagged `missing_since` by the first sweep. The user sees "187 photos are not on this phone" — honest, and recoverable if they still have the old device.
- **Android device-to-device transfer:** include media in `<device-transfer>` and everything comes across.
- **JSON backup restore:** JSON carries `relative_path` but not the bytes. Either (a) ship media as a companion ZIP alongside the JSON, or (b) accept that JSON restore is records-only and say so on the export screen in plain words. **Pick (b) for v1** — a ZIP export of 200 MB through a share sheet is a bad experience, and the records are what's irreplaceable.

---

## 11. OS-level backup: is "a lost phone is lost data" actually true?

**Short answer: no, not by default — and the spec's copy needs adjusting, but its instinct is right.**

### 11.1 What actually happens today

**iOS.** Apple's File System Programming Guide:
- `Documents/` — "The contents of this directory are backed up by iTunes and iCloud."
- `Library/Application Support/` — "In iOS, the contents of this directory are backed up by iTunes and iCloud."
- `Library/Caches/` — "In iOS 2.2 and later, the contents of this directory are not backed up by iTunes or iCloud."
- `tmp/` — "The contents of this directory are not backed up by iTunes or iCloud."

So with the DB in Application Support, **it is in the user's iCloud backup by default**, no code required.

**Android.** [developer.android.com/identity/data/autobackup](https://developer.android.com/identity/data/autobackup): Auto Backup is **enabled by default** for apps targeting API 23+; `android:allowBackup` defaults to `true`; the backup includes shared preferences, "files from internal storage (`getFilesDir()`, `getDir()`)", and databases; it excludes `getCacheDir()`, `getCodeCacheDir()`, and `getNoBackupFilesDir()`. Limit: **25 MB per app per user**, stored in a private Drive folder that doesn't count against the user's quota; only the most recent backup is kept.

`getApplicationSupportDirectory()` on Android is `Context.getFilesDir()` → **backed up by default**.

### 11.2 Why the spec's warning is still substantially correct

1. **iCloud Backup can be off, or full.** A user with 5 GB of free iCloud and 40 GB of photos has had backups failing for months and does not know.
2. **Android's 25 MB cap is brutal for this app.** Add media to internal storage and you sail past 25 MB within a single season. When an app exceeds the quota, backup stops — quietly.
3. **Backups are not fresh.** Android Auto Backup runs when the device is idle, charging, and on Wi-Fi. A shepherd's phone at 4% battery in a shed at 3am is none of those. Night eleven's entries may simply not be in the most recent backup.
4. **Neither is user-controlled or user-inspectable.** The user cannot see what's in it, cannot restore selectively, and cannot open it on a laptop.
5. **Restore is all-or-nothing at device setup.** You cannot pull last week's flock records back onto a working phone; you have to erase and restore the whole device.

### 12.3-compliant copy for the export screen, which is honest in both directions:

> **Your records live on this phone.**
> Your phone's own backup (iCloud or Google) usually includes them — but it may be switched off, out of date, or too small to include your photos, and you can't check what's in it.
> **The only backup you control is an export.** Send yourself a copy.

That is more accurate than "a lost phone is lost data", and — importantly — it does **not** reduce the pressure to export, because it tells the truth about how unreliable the OS backup is.

### 11.3 What to configure

**Leave Auto Backup on.** Turning it off makes the product strictly worse for zero gain. But declare intent explicitly rather than inheriting defaults:

`android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:allowBackup="true"
    android:fullBackupContent="@xml/backup_rules"          <!-- Android ≤ 11 -->
    android:dataExtractionRules="@xml/data_extraction_rules" <!-- Android 12+ -->
    ... >
```

`android/app/src/main/res/xml/data_extraction_rules.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
  <!-- Cloud backup: 25 MB cap. Records only; photos would blow the quota
       and silently kill the backup of the records too. -->
  <cloud-backup>
    <include domain="file" path="shed_book.sqlite" />
    <include domain="file" path="shed_book.sqlite-wal" />
    <exclude domain="file" path="media" />
  </cloud-backup>

  <!-- Device-to-device transfer: local, not Drive-quota-bound. Take it all. -->
  <device-transfer>
    <include domain="file" path="." />
  </device-transfer>
</data-extraction-rules>
```

Two caveats to verify on-device before shipping:
- **Verify the D2D size behaviour.** Google documents the 25 MB limit for Auto Backup to Drive; it is not documented as applying to local device transfer, but confirm empirically before promising anything in the UI.
- **`android:allowBackup="false"` may not stop D2D.** Google's docs note that on Android 12+ this "may only disable cloud backups but not device-to-device transfers, depending on the device manufacturer." Another reason to configure rather than disable.

**iOS.** Do nothing to the database — leave it eligible for iCloud backup. Consider setting `isExcludedFromBackupKey` on:
- `media/.trash/` (deleted-pending files shouldn't consume the user's iCloud);
- the export staging area (already in `tmp/`, so already excluded).

Do **not** exclude `media/` on iOS. iCloud Backup has no equivalent of Android's 25 MB app cap, and losing the photos is a real loss.

### 11.4 Should the app *rely* on OS backup?

**No.** Two reasons, both structural:
- It is invisible. The app cannot query "when was my data last backed up?" on either platform, so it cannot tell the user anything true about it.
- It restores to a device, not to an app. There is no in-app "restore from iCloud" button to build.

So the export flow remains the app's only *claimable* backup, exactly as the spec says. The OS backup is silent good luck, and should be described as such.

---

## 12. Encryption at rest

### 12.1 What the platforms already give you for free

**iOS.** Third-party app files default to the `NSFileProtectionCompleteUntilFirstUserAuthentication` Data Protection class — Apple's [Data Protection classes](https://support.apple.com/guide/security/data-protection-classes-secb010e978a/web) documentation states this is "the default class for all third-party app data not otherwise assigned to a Data Protection class", that "the file is stored in an encrypted format on disk and cannot be accessed until after the device has booted", and that its protection "has similar properties to desktop full-volume encryption, and protects data from attacks that involve a reboot."

**Android.** File-Based Encryption with Credential Encrypted storage is the default for app internal storage on all modern devices; data is unreadable until the user first unlocks after boot.

So on a lost, powered-off, passcode-protected phone — **the actual threat model for a shepherd** — the database is already encrypted with a hardware-bound key. SQLCipher would be a second layer over the same bytes.

### 12.2 What SQLCipher / SQLite3MultipleCiphers would cost now

The **build** cost has collapsed, which is genuinely new in 2026. Per [`sqlite3/doc/hook.md`](https://github.com/simolus3/sqlite3.dart/blob/main/sqlite3/doc/hook.md) and [drift's encryption page](https://drift.simonbinder.eu/platforms/encryption/), it is now one pubspec stanza:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc     # or `sqlcipher`
```

plus a `PRAGMA key` in the setup callback and a runtime sanity check:

```dart
bool _debugCheckHasCipher(Database database) =>
    database.select('PRAGMA cipher;').isNotEmpty;
```

The **operational** cost has not collapsed at all:

1. **The key has to live somewhere, and that somewhere fails.** The realistic store is `flutter_secure_storage` (10.3.1) → Keychain / Android Keystore. That package's own pub.dev page documents the exact failure: *"Android backups data on Google Drive. It can cause exception `java.security.InvalidKeyException: Failed to unwrap key`"*, with the recommended mitigation being to **disable autobackup or exclude shared preferences**. Put that together with §11: the OS restores your encrypted database *and* fails to restore its key. The user gets a perfect, complete, permanently unreadable copy of five seasons of flock history. That is a worse outcome than no encryption in every respect.
2. **Export becomes a dilemma.** `VACUUM INTO` from an encrypted database either produces a plaintext copy (so the "sensitive" data leaves the device unprotected anyway, defeating the purpose) or an encrypted copy the user cannot open anywhere. Neither is a backup a shepherd can use.
3. **Licensing and binary weight.** hook.md warns: "While SQLite3 is released into the public domain, SQLite3 Multiple Ciphers and SQLCipher have their own licenses. Additionally, the SQLCipher build links OpenSSL on Windows, Linux and Android." And: "The SQLCipher build included in `package:sqlite3` releases may include an older SQLite version than the default" — i.e. choosing SQLCipher can cost you SQLite features.
4. **Performance.** Page-level encryption adds work to every page read and write. I have not measured it on this workload and will not quote a number I haven't verified — but the direction is unambiguous and it is pure cost with no user-visible benefit here.

### 12.3 The decisive argument is the 3am test

Any at-rest encryption implies a key. Any key implies a state in which the app **cannot open the database**: keychain not yet available after reboot, biometric prompt, passphrase entry, keystore invalidated because the user changed their screen lock.

Spec §5: *"At 3am there is no patience for a password… no spinner."* An encrypted Shed Book has a failure mode where a shepherd with a lamb in one hand gets a passphrase prompt, or worse, an error. That is not a degraded experience; it is total product failure at the exact moment the product exists for.

Meanwhile the asset being protected is *"losses, barren rates and treatment records"* (spec §4.5) — commercially sensitive in the sense that a neighbour shouldn't see them, not in the sense that a determined forensic attacker with the unlocked phone is in the threat model. Platform FDE covers the realistic threat completely.

### 12.4 The call

**No encryption at rest in v1.** Rely on iOS Data Protection and Android FBE. Say so plainly in the privacy copy: *"Your records are stored on this phone, protected by your phone's own encryption. Nothing is sent anywhere."*

If a real user segment ever demands more, the right shape is:
- **not** whole-database encryption;
- an **opt-in, off by default** "lock Shed Book" that gates the *UI* behind biometrics while leaving the database openable — because that is revocable, recoverable, and cannot brick the data;
- with a **mandatory export before enabling**, and copy that says in so many words: *lose the passphrase, lose the records.*

Even that has a 3am cost (Face ID through a head torch, Touch ID with wet gloves), so it should be a Settings toggle a user opts into with their eyes open, never a default.

---

## Rejected alternatives (consolidated)

| Rejected | Why it lost |
|---|---|
| **Isar** | Stable release ~3 years stale; only a `4.0.0-dev.14` prerelease moves. Proprietary file format strands the data if the project dies — directly contradicts spec §4.3. |
| **Hive** | Stable ~4 years stale. Key-value store; no SQL, no FTS, no migration testing. |
| **hive_ce** | Healthy fork, but still a KV store. Right answer only for existing Hive users. |
| **Realm** | pub.dev page carries a deprecation notice ("We announced the deprecation of Atlas Device Sync + Realm SDKs in September 2024"). Closed. |
| **ObjectBox** | Healthy and fast, but proprietary format + native lib download + a paid Sync feature linked into an app whose promise is that it cannot sync. |
| **Sembast** | Healthy, but a document store that holds the DB in memory. No SQL, no FTS, no migration tooling. |
| **Raw sqflite** | Uses the *OS* SQLite: no guarantee of `STRICT` (needs 3.37+) or FTS5 trigram (3.34+). Google's own KMP guidance says bundle, don't inherit. |
| **sqlite_async** | Good package, right architecture, but no generated schema snapshots and no `SchemaVerifier`. Migration safety is the highest-stakes property here. |
| **`sqlite3_flutter_libs`** | `0.6.0+eol` — the package literally "no longer does anything". Superseded by build hooks in `sqlite3` 3.x. |
| **UUID as PRIMARY KEY** | Extra index hop on every join; kills FTS5 external-content's natural `content_rowid`; bloats every FK column and every index. |
| **ULID** | Fine format, but a community spec on a package last published ~22 months ago, and less recognisable in an exported CSV than a standard UUID. |
| **`synchronous = NORMAL`** | The standard mobile advice, and wrong here: sqlite.org states a NORMAL/WAL commit "might roll back following a power loss", and "assume the phone dies" is a spec requirement, not a nice-to-have. |
| **Trigram FTS5 for tag matching** | sqlite.org: substrings under 3 characters "do not match any rows". The spec's own example (`12`) is 2 characters. Dead on arrival. |
| **`LIKE '%12%'` for tag matching** | Works, but async, unranked, and unnecessary at 400 rows. In-memory is synchronous and rankable. |
| **Mutable `lambs.rearing_dam` column** | Dual write against `foster_events`; a future code path will desync them and the Ewe Card will contradict the history. Use the view. |
| **Mutable `pens.occupant_ewe` column** | Destroys "hours since penned" history and can't express "who was in pen 3 last Tuesday". Occupancy is a log. |
| **`(subject_type, subject_id)` polymorphic FK** | Not enforceable as a foreign key: orphan treatments and no cascade. Two nullable FKs + a CHECK is strictly better. |
| **Media as BLOBs in the DB** | Photos are far past SQLite's own crossover point; makes every `VACUUM INTO` snapshot gigabytes; blows Android's 25 MB backup cap and kills the backup of the *records* too. |
| **Absolute media paths** | The iOS container UUID changes across installs/restores (flutter#23957); Apple says to resolve directories at runtime. Guaranteed to ship broken because it never reproduces on Android. |
| **SQLCipher / sqlite3mc** | Build cost is now trivial, but key loss on OS restore is a documented failure of the key store, export becomes a dilemma, and any key means a 3am state where the app can't open. Platform FDE already covers the real threat. |
| **SharedPreferences for settings** | Lives outside the DB file, so a `VACUUM INTO` snapshot restores data but silently loses units, terminology and reminder intervals. |
| **Storing settings as one JSON blob** | Invisible to Drift's schema snapshots, so settings changes are untested across migrations. |

---

## Pitfalls

| # | Pitfall | Why it happens | Mitigation |
|---|---|---|---|
| 1 | Adding `sqlite3_flutter_libs` to `pubspec.yaml` | Every blog post and every LLM trained before 2026 says to | It's `0.6.0+eol` and does nothing. Depend on `drift_flutter`/`sqlite3` only. Put a comment in the pubspec saying why. |
| 2 | `PRAGMA foreign_keys` never set | It's per-connection, not persistent, and Drift doesn't set it | Set it in `DriftNativeOptions.setup`, which runs per opened connection. Add a startup `assert` that `PRAGMA foreign_keys` returns 1. |
| 3 | `setup` callback captures `this` | It reads like a normal closure | Drift's docs: it "is sent across isolates … must not capture closed variables". Make it a **top-level** function. |
| 4 | `File.copy` of the `.sqlite` for export | The obvious thing to write | Silently drops the `-wal`; may produce a corrupt "backup". Use `VACUUM INTO`. Add a lint/grep in CI for `.copy(` near the db path. |
| 5 | `VACUUM INTO` fails on the second export | "The file named by the INTO clause must not previously exist" | Delete the target first; use a timestamped filename; sweep the temp dir on launch. |
| 6 | Double-quoted string literals in hand-written SQL | Habit from other databases | The bundled build sets `SQLITE_DQS=0`. `WHERE status = "active"` fails. **Single quotes for strings, double quotes for identifiers.** |
| 7 | FTS5 syntax error from user input | `MATCH` treats `AND`, `OR`, `NOT`, `-`, `*`, `"`, `:` as operators | Tokenise and quote every term (`toFts5Query`, §6.2). A ewe note containing "OR" must not crash search. |
| 8 | Drift analyser rejects the FTS5 `'delete'` trigger | [drift#3322](https://github.com/simolus3/drift/issues/3322): special INSERT commands aren't modelled | Prototype in week 1. Fallbacks: `customStatement` in `onCreate` + migration, or drop external content (§6.2 Fallback B). |
| 9 | Migration test suite chokes on FTS5 shadow tables | `search_fts_data`/`_idx`/`_docsize`/`_config` show up in `sqlite_schema` | Write the migration test **with FTS5 present from day one**, before there's real content to lose. |
| 10 | Absolute media paths in the database | Works perfectly on the dev's Android phone | Relative paths only, resolved per run. Enforce with `CHECK (relative_path NOT LIKE '/%')`. |
| 11 | Android backup silently stops | The app exceeded the 25 MB Auto Backup cap because media is in `getFilesDir()` | Exclude `media/` from `<cloud-backup>` in `dataExtractionRules`; include it in `<device-transfer>`. |
| 12 | Changing `store_date_time_values_as_text` after launch | Someone reads the docs late and "fixes" it | Drift: "not compatible with existing database schemas". Set it in the very first commit; add a comment in `build.yaml` forbidding changes. |
| 13 | `schemaVersion` bumped without regenerating snapshots | Easy to forget in a fast commit | CI step: `dart run drift_dev make-migrations` then `git diff --exit-code`. |
| 14 | Only N-1 → N migrations tested | It's what the generated test scaffolding starts you with | Loop the full from→to matrix (§9.4). Offline users skip many versions. |
| 15 | A transaction held open across a UI prompt | Feels natural when the flow is multi-step | Never `await` user input inside `transaction()`. Multi-step UI = multiple small transactions. |
| 16 | Orphan sweep runs before first paint | It's easy to `await` it in `main()` | Nothing may sit between unlock and a saved event. Run sweeps in a post-frame callback. |
| 17 | Cold `flutter build` fails with no network | The `sqlite3` build hook downloads binaries | Document it; use `url_pattern` for an internal mirror in CI; `HTTPS_PROXY` is respected (sqlite3 3.1.1). |
| 18 | `build.yml` instead of `build.yaml` | One character | FTS5 silently stays disabled and `.drift` files fail to parse `CREATE VIRTUAL TABLE`. Cost someone a day in [drift#2670](https://github.com/simolus3/drift/discussions/2670). |
| 19 | Deleting a season cascades into ewes | `ON DELETE CASCADE` chosen without thinking | Season → EweSeason/Lambing/Treatment = `cascade`. Lambing → Ewe and Treatment → Ewe = `restrict`. Write a test that deletes a season and asserts the ewe count is unchanged. |
| 20 | Adding a "suggested withdrawal period" | A well-meaning future feature | `CHECK (withdrawal_source = 'user_entered')` makes it a schema migration, forcing the safety rule back into view. Safety rule 12.1. |

---

## How this serves the 3am test and the offline-only constraint

**3am test:**
- **In-memory tag index** → the keypad filters synchronously inside one frame. No `await`, no spinner, no empty-list flash between taps. This is the single biggest contributor to "under fifteen seconds".
- **Write-on-change, one transaction per field** → there is no Save button, so there is nothing to forget to press and nothing to lose when the battery dies mid-entry.
- **`synchronous = FULL`** → the last thing the shepherd typed is on the flash chip before their thumb lifts.
- **Partial unique index on open pen occupancy** → the pen board cannot show a lie, so a glance from arm's length is trustworthy.
- **CHECK constraints instead of silent coercion** → the database refuses nonsense rather than storing something plausible-but-wrong that surfaces in March as a bad season summary.
- **Background isolate** (`createBackgroundConnection`, free from `drift_flutter`) → no dropped frames on the flock list while a write commits.
- **Two-tap foster** → one INSERT into an append-only log, no read-modify-write, no conflict resolution.
- **No key, no unlock, no biometric** → the app opens straight into the database, every time, in every condition.

**Offline-only:**
- Drift + `package:sqlite3` are a code generator and a `dart:ffi` binding. There is no HTTP client anywhere in the dependency tree.
- The release `AndroidManifest.xml` from the Flutter template contains **no** `INTERNET` permission (verified in the SDK templates); nothing in this stack merges one in. The strongest version of "offline" — an APK that physically cannot open a socket — is achievable and should be verified with `aapt dump permissions` in CI.
- The only network in the entire stack is the `sqlite3` **build hook**, at build time, on the developer's machine. Nothing ships.
- No cloud backup path exists in the code, so none can be accidentally enabled.
- `VACUUM INTO` + the system share sheet means the *user* chooses the destination — AirDrop, email, a USB stick — and the app never learns what they chose.
- The output is a plain SQLite file with a plain, documented schema, so the promise in spec §4.3 ("no company going out of business in 2029 taking five seasons of flock history with it") is literally true: even if Shed Book is abandoned, `sqlite3 shed_book.sqlite` still works.

---

## Open questions for the app owner

1. **Tag uniqueness.** Is a tag globally unique for all time, or unique among *active* animals (allowing reuse after a cull)? This changes the unique index to a partial one (`WHERE status = 'active'`) and changes the create-on-the-fly flow. Needs a shepherd, not a developer.
2. **Does a lamb that is later kept as a breeding ewe become a `Ewe` row?** If yes, `Lambs` needs a nullable `became_ewe` FK and the retention story gets much better ("her dam was 412"). If no, that lineage is lost. This is a v1 schema decision with v3 consequences.
3. **JSON restore semantics: merge or replace?** Merge-on-`uid` is implemented for free by the ID design, but "I restored my backup and now I have two flocks" is a real risk. Needs a decision and explicit UI.
4. **Does the free tier cap (15 ewes / one season) live in the schema or the UI?** Recommendation: **UI only**. A schema-level cap is a `CHECK` that will one day fire on a paying user mid-lambing.
5. **Which `ewes_to_ram` is authoritative** when `seasons.ewes_to_ram` and `COUNT(ewe_seasons)` disagree? Affects the lambing-percentage denominator. Safety rule 12.4 says flag, don't fix — but the summary screen must still show *a* number.
6. **Media in the JSON backup: records-only, or a companion ZIP?** Recommended records-only for v1; needs owner sign-off because it changes what "full backup" means in the export screen copy.
7. **Ziplock-bag taps (spec §17.4)** — if the target hardware doesn't register taps through a freezer bag, the interaction model changes and the tag-index/keypad design in §6.1 may need to become a volume-button stepper. Nothing in the storage layer changes, but the search UX does.

---

## Sources

Every URL below was fetched during this research on 2026-07-27.

**pub.dev package pages**
- https://pub.dev/packages/drift
- https://pub.dev/packages/drift/changelog
- https://pub.dev/packages/drift_dev
- https://pub.dev/packages/drift_flutter
- https://pub.dev/packages/sqlite3
- https://pub.dev/packages/sqlite3/changelog
- https://pub.dev/packages/sqlite3_flutter_libs
- https://pub.dev/packages/sqlite3_flutter_libs/changelog
- https://pub.dev/packages/sqlcipher_flutter_libs
- https://pub.dev/packages/sqflite
- https://pub.dev/packages/sqlite_async
- https://pub.dev/packages/objectbox
- https://pub.dev/packages/isar
- https://pub.dev/packages/hive
- https://pub.dev/packages/hive_ce
- https://pub.dev/packages/realm
- https://pub.dev/packages/sembast
- https://pub.dev/packages/path_provider
- https://pub.dev/packages/uuid
- https://pub.dev/packages/ulid
- https://pub.dev/packages/share_plus
- https://pub.dev/packages/flutter_secure_storage

**Dart/Flutter API docs**
- https://pub.dev/documentation/drift/latest/drift/Table-class.html
- https://pub.dev/documentation/drift/latest/drift/KeyAction.html
- https://pub.dev/documentation/drift/latest/drift/TableIndex-class.html
- https://pub.dev/documentation/drift/latest/native/NativeDatabase-class.html
- https://pub.dev/documentation/drift_flutter/latest/drift_flutter/driftDatabase.html
- https://pub.dev/documentation/drift_flutter/latest/drift_flutter/DriftNativeOptions-class.html
- https://pub.dev/documentation/sqlite3/latest/common/CommonDatabase-class.html
- https://pub.dev/documentation/path_provider/latest/path_provider/path_provider-library.html
- https://pub.dev/documentation/path_provider/latest/path_provider/getApplicationSupportDirectory.html
- https://pub.dev/documentation/path_provider/latest/path_provider/getApplicationDocumentsDirectory.html

**Drift documentation**
- https://drift.simonbinder.eu/setup/
- https://drift.simonbinder.eu/dart_api/tables/
- https://drift.simonbinder.eu/sql_api/extensions/
- https://drift.simonbinder.eu/sql_api/drift_files/
- https://drift.simonbinder.eu/platforms/vm/
- https://drift.simonbinder.eu/platforms/encryption/
- https://drift.simonbinder.eu/migrations/
- https://drift.simonbinder.eu/migrations/api/
- https://drift.simonbinder.eu/migrations/step_by_step/
- https://drift.simonbinder.eu/migrations/tests/
- https://drift.simonbinder.eu/guides/datetime-migrations/
- https://drift.simonbinder.eu/docs/advanced-features/schema_inspection/

**GitHub (source and issues read directly)**
- https://github.com/simolus3/sqlite3.dart — `sqlite3/README.md`, `sqlite3/CHANGELOG.md`, `sqlite3/pubspec.yaml`, `sqlite3/doc/hook.md`, `sqlite3/doc/native.md`
- https://github.com/simolus3/drift — `drift_flutter/lib/drift_flutter.dart`, `drift_flutter/lib/src/connect.dart`, `drift_flutter/lib/src/native.dart`
- https://github.com/simolus3/drift/issues/3322
- https://github.com/simolus3/drift/discussions/2670
- https://github.com/flutter/flutter/issues/23957
- https://github.com/flutter/flutter — `packages/flutter_tools/templates/app/android.tmpl/app/src/{main,debug,profile}/AndroidManifest.xml.tmpl`
- https://github.com/tekartik/sqflite/blob/master/sqflite/doc/version.md
- https://github.com/prisma/prisma/issues/8106
- https://github.com/rails/rails/pull/52354

**sqlite.org**
- https://sqlite.org/wal.html
- https://sqlite.org/pragma.html#pragma_synchronous
- https://sqlite.org/fts5.html
- https://sqlite.org/fts5.html#the_trigram_tokenizer
- https://sqlite.org/stricttables.html
- https://sqlite.org/lang_vacuum.html
- https://sqlite.org/lang_altertable.html
- https://sqlite.org/optoverview.html#the_like_optimization
- https://www.sqlite.org/howtocorrupt.html
- https://www.sqlite.org/fasterthanfs.html

**Apple**
- https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html
- https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/AccessingFilesandDirectories/AccessingFilesandDirectories.html
- https://support.apple.com/guide/security/data-protection-classes-secb010e978a/web

**Android / Google**
- https://developer.android.com/identity/data/autobackup
- https://developer.android.com/kotlin/multiplatform/sqlite

**dart.dev / docs.flutter.dev**
- https://dart.dev/tools/hooks
- https://docs.flutter.dev/platform-integration/bind-native-code

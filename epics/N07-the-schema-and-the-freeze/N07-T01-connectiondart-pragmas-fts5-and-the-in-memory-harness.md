# N07-T01 — `connection.dart` — pragmas, FTS5 and the in-memory harness

| | |
|---|---|
| **Epic** | [N07 — The schema and the freeze](epic.md) · `00-README` §9 step 3 (1 of 2) |
| **Task** | 1 of 8 |
| **Depends on** | N06-T11 |
| **Commit** | one commit · `feat(db): openConnection, the seven pragmas and the FTS5 assertion` |

## 1. Why this task exists

`openConnection` with the seven pragmas in `R13`'s order — `synchronous = FULL` among
them, because *assume the phone dies* is a durability setting before it is a slogan — the FTS5
availability assertion, and the in-memory harness every `test/data/` file will open against.

Two of the seven are **per-connection and not persistent**: `foreign_keys` and `recursive_triggers`.
Without the first, every `ON DELETE` written in the next six tasks is decorative. Without the second,
deleting a season silently leaves `search_docs` rows for notes that no longer exist. Neither is in the
file header, so both are re-applied on every open, from exactly one construction site — which is what
makes "we never forgot one" provable rather than asserted.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | §1.3 | `configureConnection`, the pragma bodies with their reasons, `openConnection()`, `_assertEngineCapabilities`, application support over Documents, and the no-read-pool rule |
| `docs/engineering/03-data-model-and-schema.md` | §1.1, §1.5 | the packages and versions; the five banned things and what catches each |
| `docs/engineering/04-migrations-media-backup-restore.md` | §2.8 | why `journal_size_limit` and `temp_store` are in the union, and where `_snapshotBeforeMigration` lands (N08-T07) |
| `docs/engineering/12-testing.md` | §3.1, §3.2 | `NativeDatabase.memory()`, `closeStreamsSynchronously`, `addTearDown`, and the host sqlite3 floor |
| `docs/engineering/CONVENTIONS.md` | §2.8, R12, R13, R16 | the file, the three function names, the pragma order, and `lib/core/db/` → `lib/core/` |
| `docs/research/00-tech-decisions.md` | §5 | `drift` 2.34.2 · `drift_flutter` 0.3.1 · `sqlite3` 3.5.0 · `path_provider` 2.1.6 — the only source of these numbers |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | connections, pragmas and the database file are its subject |
| `shed-testing` | its `references/harness.md` owns `NativeDatabase.memory()` and the `closeStreamsSynchronously` trap, which is half of this task |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/connection_test.dart`
- **Test** — `'an opened connection reports synchronous=2, foreign_keys=1 and compiles an FTS5 table'`
- **Assertions, spelled out** — after `configureConnection` has run: `PRAGMA journal_mode` → `wal`,
  `PRAGMA synchronous` → `2`, `PRAGMA foreign_keys` → `1`, `PRAGMA recursive_triggers` → `1`,
  `PRAGMA busy_timeout` → `5000`, `PRAGMA journal_size_limit` → `4194304`, `PRAGMA temp_store` → `2`;
  and `CREATE VIRTUAL TABLE temp.probe USING fts5(x)` does not throw.
- **Why it is red today** — nothing opens a database: `connection.dart` does not exist, so there is no connection to read a pragma from and no FTS5 probe to fail loudly on a build without it.

```bash
fvm flutter test test/data/connection_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the open function, the pragma sequence, the FTS5 probe that throws a readable error, and
`testDatabase()` over `NativeDatabase.memory()`.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

This task reaches step 1 (schema) and step 7 (tests) only. There is no domain, data, wiring,
controller, UI or ARB layer in it — say so in the commit body.

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/core/db/connection.dart` | **New.** The whole task. Holds `configureConnection`, the private `_assertEngineCapabilities`, and `openConnection()`. It is the only `driftDatabase(` call site in the app (R12) and the only place the seven pragmas are written. |
| 2 | `test/support/harness.dart` | Gains the in-memory connection helper, beside `atFixed` (12 §2.1). This is the file every `test/data/` file will import for the next six tasks. |
| 3 | `test/data/connection_test.dart` | **New.** The anchor test above. |
| 4 | `test/data/host_sqlite_version_test.dart` | **New.** `expect(sqlite3.version.versionNumber, greaterThanOrEqualTo(3041000))` — 12 §3.2. Land it here, because from T03 onward a host below the floor fails as a mystery instead of a named assertion. |
| 5 | `tool/policy_allowlist.txt` | Only if `check_policy`'s `driftDatabase(`-appears-once rule needs this file named. It should not — the rule counts occurrences, and this is the first. Touch it only if the gate says so, and say why in the commit message. |

### 5.2 The signatures

`configureConnection` is **top-level and public**, and both properties are load-bearing (R12).
`DriftNativeOptions.setup` is sent across an isolate boundary, so it must capture nothing — a closure
over `this` throws at open — and a private name cannot be referenced from `connection_test.dart`.

```dart
// lib/core/db/connection.dart
void configureConnection(CommonDatabase db);          // public, top-level, captures nothing
void _assertEngineCapabilities(CommonDatabase db);    // private — decision #36
QueryExecutor openConnection();                       // the ONLY driftDatabase( call site
```

The pragma order is `R13`'s, which is the **union** of 03 §1.3's list and 04 §2.8's, and nothing may
be dropped from it:

```
journal_mode = WAL · synchronous = FULL · foreign_keys = ON · busy_timeout = 5000
journal_size_limit = 4194304 · temp_store = MEMORY · recursive_triggers = ON
_assertEngineCapabilities(db)
_snapshotBeforeMigration(db)          // N08-T07 adds this line — do NOT stub it here
```

`openConnection()` overrides `drift_flutter`'s default directory. `driftDatabase` defaults to
Documents; the database goes in **application support** (decision #27):

```dart
QueryExecutor openConnection() => driftDatabase(
      name: 'shed_book',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
        setup: configureConnection,
      ),
    );
```

The harness helper for this task returns a connection, not a database — see 5.3:

```dart
// test/support/harness.dart
DatabaseConnection testConnection();   // NativeDatabase.memory(setup: configureConnection)
```

### 5.3 The details that are easy to get wrong

1. **`openAppDatabase()` is not in this commit.** `CONVENTIONS` §2.8 homes all three functions in this
   file, but `Future<AppDatabase> openAppDatabase()` needs `AppDatabase`, which T02 creates. Write it
   in T02, with its `flutter_test` assertion and the name of the override to add. Writing a stub here
   is a compile error you will carry for one commit for nothing.
2. **`testDatabase()` cannot exist yet either, for the same reason.** 12 §3.1's helper returns
   `Future<AppDatabase>`. What this task can land is a connection helper over
   `NativeDatabase.memory(setup: configureConnection)`, which is enough to read a pragma. T02 wraps it
   in `testDatabase({bool seedOnCreate = true})` with `closeStreamsSynchronously: true` and
   `addTearDown(db.close)`. Do not invent a second harness entry point — grow the one.
3. **`synchronous = FULL`, never `NORMAL`.** sqlite.org: WAL + `NORMAL` *"does lose durability… might
   roll back following a power loss."* Spec §5 says assume the phone dies. One extra `fsync` per
   commit at ~10 writes a minute is free. A `PRAGMA synchronous = NORMAL` anywhere outside the
   allowlisted bulk-import helper is a `check_policy` failure, not a tuning decision.
4. **`recursive_triggers = ON` is not about recursion.** It is what makes rows removed by an
   `ON DELETE CASCADE` fire the child table's `AFTER DELETE` trigger, which is what keeps `search_docs`
   in step with the notes (03 §9.2). Nothing in this schema fires itself, so there is no recursion to
   bound — and that is exactly why a reviewer will want to delete this line. It stays.
5. **`_assertEngineCapabilities` is an assertion, not a capability probe.** It throws a `StateError`
   naming the expectation. There is no `LIKE` fallback branch and no runtime "if FTS5 then… else…"
   anywhere in the codebase (decision #36). A fallback that silently degrades search is worse than a
   crash on a build nobody should be shipping.
6. **The probe may need to change shape, and 03 §1.3 says which way.** If
   `pragma_compile_options` is itself compiled out of the bundled build, replace the `SELECT` with
   `db.execute('CREATE VIRTUAL TABLE temp.fts5_probe USING fts5(x)')` inside a `try` that rethrows —
   still an assertion, still loud, still not a fallback. **Record which one shipped, in 03 §1.3, in
   this commit.** It is one of that document's five `needs verification` items.
7. **One connection, no read pool, whatever `drift_flutter` offers.** 400 ewes have no
   read-concurrency problem, and every extra connection is another place `foreign_keys` and
   `recursive_triggers` can be missed. `openConnection()` being the sole construction site is what
   `tool/check_policy.dart` counts.
8. **Never add `sqlite3_flutter_libs` or `sqlcipher_flutter_libs`.** They arrive transitively from
   `drift_flutter` 0.3.1 as no-op `+eol` shims, and seeing them in `pubspec.lock` is expected and
   correct. They are **not** flagged discontinued on pub.dev, so do not write a CI check keyed on that
   flag — it will never fire (decision #26).
9. **The build hook needs a network on a cold cache.** `package:sqlite3` downloads a sha256-verified
   binary from GitHub at build time. The *build machine* needs network; the shipped app does not. A
   plane-mode `flutter clean && flutter build` failure is not a regression — say so in the README so
   nobody loses an evening to it (03 §1.1 item 3, 13 §1.3).
10. **`lib/core/db/` may import `package:flutter/foundation.dart` but never `package:flutter/material.dart`**
    (layer rule 2, R16). `lib/core/` is importable from here, so `LocalLog` is reachable; `lib/core/ui/`
    is not.

### 5.4 The test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/data/connection_test.dart` | `'an opened connection reports synchronous=2, foreign_keys=1 and compiles an FTS5 table'` | The anchor. All seven pragmas read back, and the FTS5 probe. |
| | `'configureConnection captures nothing and can be passed as a bare function reference'` | The isolate-boundary rule in R12 — pass `configureConnection` itself, not a closure, and confirm the analyzer accepts a tear-off. |
| | `'a connection without configureConnection reports foreign_keys=0'` | Proves the assertion is measuring something. Without this, the pragma test passes on a build where SQLite happened to default the way you wanted. |
| | `'_assertEngineCapabilities throws a StateError naming the bundled build when FTS5 is absent'` | Exercise the failure arm. 03 §11 wants this verified once against a stock OS SQLite, then reverted; record the result in the commit body. |
| `test/data/host_sqlite_version_test.dart` | `'the host sqlite is new enough for STRICT and FTS5'` | ≥ 3.41.0. `STRICT` needs ≥ 3.37; the floor has headroom and is a number CI can prove. |

Nothing in this task is time-shaped: `configureConnection` reads no clock and stores no instant, so
there is no `test/domain/uk_zone/` case here. The first DST case in this epic is T03's.

### 5.5 Verification that the layers are right

`lib/core/db/connection.dart` imports `package:drift/drift.dart`,
`package:drift_flutter/drift_flutter.dart`, `package:path_provider/path_provider.dart` and
`package:sqlite3/common.dart` — and nothing from `lib/data/`, `lib/features/` or `lib/core/ui/`. Run
the gate before the test; it is sub-second and it fails cheaper.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. The `package:sqlite3` build hook's fetch happens on the
  build machine, never in the app's process; G2 (the dependency allowlist) and G3 (the import scan)
  stay green.
- **Assume the phone dies** (`00-README` §2.4) — `synchronous = FULL` on every connection is the
  mechanism, and it is a one-line regression away at any time.
- **One construction site** — a second `driftDatabase(` or `NativeDatabase(` in `lib/` is a
  `check_policy` failure, not a refactor.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'an opened connection reports synchronous=2, foreign_keys=1 and compiles an FTS5 table'` passes, and was seen to fail first for the stated reason
- [ ] all seven pragmas applied in `R13`'s order
- [ ] `synchronous = FULL` on every connection
- [ ] the FTS5 probe fails loudly on a build without it
- [ ] no test in this epic uses a mock
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
# 1. Red first — the anchor test, before any of lib/ exists.
fvm flutter test test/data/connection_test.dart

# 2. The host can run the rest of this epic at all.
fvm flutter test test/data/host_sqlite_version_test.dart

# 3. The whole new-file set.
fvm flutter test test/data/

# 4. Cheapest failure first: the gate, then format, then analyze.
make check

# 5. The suite, randomised, plus the London zone pass.
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(db): openConnection, the seven pragmas and the FTS5 assertion`

# N08-T07 — `_snapshotBeforeMigration` and `diagnostics_snapshot.dart`

| | |
|---|---|
| **Epic** | [N08 — The migration harness and the `codegen` job](epic.md) · `00-README` §9 step 3 (2 of 2) |
| **Task** | 7 of 7 |
| **Depends on** | N08-T06 |
| **Commit** | one commit · `feat(db): snapshot before migration, bounded and never fatal` |

## 1. Why this task exists

`VACUUM INTO` a snapshot before a migration runs, bounded in size and count, and
**never rethrowing** — a failed snapshot must not stop the app opening. This is the closest thing to a
safety net the product has when the only backup is one the user remembered to make.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/04-migrations-media-backup-restore.md` | §2.8, §8.1–§8.4, §9.2 | the pre-migration snapshot verbatim and its five rules · why `File.copy` of a WAL database is the most dangerous line in the app · the `VACUUM INTO` mechanism and its unverified note · the damaged-database procedure · what must be excluded from cloud backup |
| `docs/engineering/CONVENTIONS.md` | §1, §2.8, §5.2, R12, R13, R52 | `diagnostics_snapshot.dart` is in `lib/core/db/` · `configureConnection`'s fixed order · *snapshot* is `VACUUM INTO` and the schema JSON, never the backup · `LocalLog.instance` is the one diagnostics sink |
| `docs/engineering/03-data-model-and-schema.md` | §1.3 | the seven pragmas, `_assertEngineCapabilities` and the isolate rule the snapshot runs inside |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | `VACUUM INTO` and the snapshot vocabulary |
| `shed-bootstrap-and-errors` | the never-rethrow rule and where the failure is logged |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/diagnostics_snapshot_test.dart`
- **Test** — `'VACUUM INTO writes a bounded snapshot and never rethrows'`
- **Why it is red today** — a migration runs with nothing behind it.

```bash
fvm flutter test test/data/diagnostics_snapshot_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the snapshot call, the bound, the retention rule and the swallowed-but-logged failure; the output is a single fully-checkpointed file with no `-wal` or `-shm` sidecar beside it.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

Step 1 (the open path) and Step 7. `lib/core/db/` may not import `lib/data/` (layer rule 2), and
`customStatement(` is legal only inside `lib/core/db/` (layer rule 8) — which is why both halves of
this task live in that package even though the anchor test sits under `test/data/`.

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/core/db/connection.dart` | **Edit.** `_snapshotBeforeMigration(CommonDatabase db)` gains its real body: the version guard, the path read off the connection, the size bound, the `pre_migration/` directory and the `VACUUM INTO`. R13 already puts the call last in `configureConnection`; this task fills it in. Also the named size constant — see §5.3. |
| 2 | `lib/core/db/diagnostics_snapshot.dart` | **New.** `Future<File> snapshotDatabase()` — the Settings ▸ Diagnostics half. Writes to `getTemporaryDirectory()`, never inside a transaction, never automatically. |
| 3 | `lib/core/db/database.dart` | **Read only.** `kSchemaVersion` is what `_snapshotBeforeMigration` compares `db.userVersion` against, and it is a top-level const precisely so the background isolate can read it. |
| 4 | `test/data/diagnostics_snapshot_test.dart` | **New.** The anchor and the cases in §5.4. Uses a **real temp file**, never `NativeDatabase.memory()`. |
| 5 | `test/data/snapshot_ambiguous_hour_test.dart` | **New.** `@Tags(['uk-zone'])`, following `12 §2.4`'s file-per-zone pattern, with the loud `setUpAll` offset assertion. |
| 6 | `tool/policy_allowlist.txt` | **Read only, unless §5.3's `.copy(` question arises.** `04 §8.1` bans `.copy(` under `lib/core/db/` with exactly one allowlisted exception, and that exception is `04 §8.4` step 4 — not this task. |

### 5.2 The signatures

```dart
// lib/core/db/connection.dart — 04 §2.8. Runs from configureConnection, which
// crosses an isolate boundary and must capture nothing (R12). Everything here
// is SYNCHRONOUS: no await, no path_provider, no Future.
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
  if (mainPath == null || mainPath.isEmpty) return;   // :memory:

  final mainFile = File(mainPath);
  if (mainFile.lengthSync() > kPreMigrationSnapshotMaxBytes) return;  // never a minute at launch

  final dir = Directory(p.join(p.dirname(mainPath), 'pre_migration'))
    ..createSync(recursive: true);
  final out = File(p.join(dir.path, 'shed_book-v$current.sqlite'));
  if (out.existsSync()) out.deleteSync();   // VACUUM INTO refuses a non-empty target

  try {
    db.execute('VACUUM INTO ?;', [out.path]);
  } on SqliteException {
    // Disk full, or the file is already damaged. Do not block the launch;
    // the diagnostics log records it. NEVER rethrow from setup.
  }
}
```

```dart
// lib/core/db/diagnostics_snapshot.dart — 04 §8.2.
/// Produces a single, fully-checkpointed .sqlite file with no -wal/-shm
/// sidecars, safe to hand to the share sheet.
/// Diagnostics only — this is NOT the user's backup (decision #84).
Future<File> snapshotDatabase() async {
  final tmp = await getTemporaryDirectory();
  final dir = Directory(p.join(tmp.path, 'diagnostics'))
    ..createSync(recursive: true);
  final stamp = appNow().utc.toIso8601String().replaceAll(':', '-');   // #46
  final out = File(p.join(dir.path, 'shed-book-$stamp.sqlite'));

  if (out.existsSync()) out.deleteSync();

  // Bind the path; never interpolate into SQL.
  // NEVER inside db.transaction() — VACUUM cannot run in a transaction.
  await _db.customStatement('VACUUM INTO ?;', [out.path]);
  return out;
}
```

### 5.3 The details that are easy to get wrong

- **`NativeDatabase.memory()` cannot exercise this code at all.** On an in-memory database
  `PRAGMA database_list` returns an empty `file`, and `_snapshotBeforeMigration` returns
  immediately — so a test written against the standard `testDatabase()` harness passes while
  asserting nothing. Every case here opens a real file under `Directory.systemTemp`, and the first
  assertion is that the early return did **not** fire.
- **The 250 MB bound is a magic size, and the Definition of Done bans those.** `04 §2.8` writes
  `250 * 1024 * 1024` as a literal. Name it — `const kPreMigrationSnapshotMaxBytes` — and keep it in
  `lib/core/db/`: `lib/data/media_limits.dart` is where the other caps live, and `lib/core/db/`
  may not import `lib/data/` (layer rule 2). One constant, one file, one place to change it.
- **The doc's `catch` is narrower than the doc's rule.** `04 §2.8` catches `on SqliteException`, but
  `createSync` on a full disk throws `FileSystemException`, and `lengthSync` on a file that
  disappeared throws too — neither is a `SqliteException`, so both escape `configureConnection`,
  and a throw from `setup` takes the app down **at launch**. That is precisely the failure the
  snapshot exists to survive. Widen the catch to cover the file-system failures, log both, rethrow
  neither, and write the reason in the comment so nobody narrows it back.
- **`LocalLog.instance` is a static, and this code runs on a different isolate.** `configureConnection`
  is sent across an isolate boundary (R12), so a static singleton reached from inside it is a
  *different instance* from the app's, and two isolates appending to one rolling log file is a
  corrupted log. Decide it here and write it down: either the snapshot failure is recorded in a form
  the main isolate drains later, or `LocalLog` is made safe for this one call site. Do not simply
  call `LocalLog.instance.warn(...)` because R52 says there is one sink.
- **`VACUUM` cannot run inside a transaction, and drift wraps migrations in one.** The snapshot runs
  from `setup`, on the same connection, **before** drift's migration and outside any transaction —
  that is the only place on the launch path where it is legal. `snapshotDatabase()` has the same
  rule and no excuse: it is never inside `db.transaction()`.
- **`VACUUM INTO` refuses to overwrite.** sqlite.org: *"the file named by the INTO clause must not
  previously exist, or else it must be an empty file."* Delete the stale target first, in both
  functions. Forgetting it means the snapshot silently stops being taken from the second upgrade
  onward — the failure is invisible until the day it matters.
- **`File.copy` of the database is the single most dangerous line anyone could write in this app.**
  In WAL mode the database is three files; a copy taken mid-transaction can be corrupt, and one
  separated from its `-wal` can lose committed transactions. `check_policy` bans `.copy(` under
  `lib/core/db/` with exactly one allowlisted exception, and it is not this task's (`04 §8.1`,
  `§8.4` step 4).
- **It runs once per upgrade, not once per launch.** `userVersion < kSchemaVersion` is only true on
  the first launch after an update. `pre_migration/` holds **at most one file**, and it is deleted
  on the first clean launch where `userVersion == kSchemaVersion` **and** the app has completed one
  successful write — the second half is what makes it survive a crash loop, and it is the half
  everyone drops.
- **It is not a restore path.** There is one restore and it is JSON (#84, #73). The user shares the
  snapshot out of Settings ▸ Diagnostics and `tool/snapshot_to_backup.dart` — committed,
  developer-run, not on the phone — converts it. Two restore paths would be two migration surfaces.
- **The word.** *Snapshot* is `VACUUM INTO` and the drift schema JSON. *Backup* is the JSON the user
  makes. `CONVENTIONS §5.2` fixes both, and `sync` and `dump` are banned outright (§5.3). The DoD
  checks this and so does the reviewer.
- **`getTemporaryDirectory()` is chosen for what it is not.** Apple documents it as not backed up
  and Android excludes it from Auto Backup, so stale snapshots never inflate anyone's iCloud. Sweep
  that directory at launch. `pre_migration/` sits beside the database in application support, so it
  must be named in `data_extraction_rules.xml` and `backup_rules.xml` as excluded — that is N31's
  file, and this task's contribution is the directory name, spelled once.
- **One unverified line to close while you are here.** `04 §8.2` carries: whether `package:sqlite3`
  3.5.0 surfaces the online-backup API on `CommonDatabase` has not been confirmed. It does not
  change the decision — #84 names `VACUUM INTO` — but do not write *"there is no `backup()` method"*
  in a comment on the strength of the document. Look, then record what you found in `04 §8.2`.

### 5.4 The test set

`test/data/diagnostics_snapshot_test.dart`

| Case | Asserts |
|---|---|
| `'VACUUM INTO writes a bounded snapshot and never rethrows'` | **anchor.** A real temp-file database at `user_version` one behind `kSchemaVersion`; opening it writes exactly one file under `pre_migration/`; that file opens as a database and `PRAGMA quick_check` returns `'ok'`; and the open completed rather than throwing. |
| `'the snapshot has no -wal or -shm sidecar beside it'` | the output directory holds one file. This is what distinguishes `VACUUM INTO` from a copy, and it is what the share sheet needs. |
| `'a database at or above kSchemaVersion is not snapshotted'` | the two early returns: `current >= kSchemaVersion`, and `current == 0` for a database about to be created. A snapshot on every launch is a bug that only shows up as a slow cold start. |
| `'a file larger than the bound is not snapshotted and the launch is not delayed'` | a database padded past `kPreMigrationSnapshotMaxBytes` is skipped; the constant is read from source, not retyped in the test |
| `'a failing VACUUM INTO is logged and never rethrown'` | make the target unwritable, provoke the failure, assert the open still completed and the diagnostics log carries the event. Repeat for the file-system failure, which is the one `04 §2.8`'s narrow catch misses. |
| `'pre_migration holds at most one file'` | two consecutive upgrades leave one file, not two |
| `'the snapshot is deleted only after a clean launch and one successful write'` | a clean launch alone leaves the file; a clean launch plus one committed write removes it. The crash-loop case is the reason this is two conditions and not one. |
| `'snapshotDatabase writes into the temporary directory and never inside a transaction'` | the path is under `getTemporaryDirectory()`; calling it from within `db.transaction()` throws rather than silently producing a corrupt file |
| `'a stale target file is deleted before VACUUM INTO runs'` | pre-create a non-empty file at the target path; the snapshot still succeeds |
| `'nothing in lib/core/db/ calls .copy( on the database'` | the gate holds this; the test's job is to confirm the rule is present in the rule table, not to re-scan the source (`12 §1.4`) |

`test/data/snapshot_ambiguous_hour_test.dart` — `@Tags(['uk-zone'])`, `setUpAll` asserting
`DateTime(2026, 7, 1).timeZoneOffset == Duration(hours: 1)` with the reason
*"Run this file with TZ=Europe/London"*.

| Case | Asserts |
|---|---|
| `'two snapshots taken an hour apart in the repeated hour get two distinct filenames'` | `appNow()` fixed at **01:30 on 25 October 2026** and again at 01:30 one real hour later — the same wall-clock time, twice. Because the stamp is `appNow().utc`, the two names differ and the second does not overwrite the first. A "tidy-up" to local time makes the second snapshot destroy the first, on the one night of the year when a shepherd is most likely to be in the shed. |
| `'the stamp contains no colon and no local offset'` | `replaceAll(':', '-')` is applied and the string is the UTC form — a colon in a filename is illegal on some targets and a local offset makes two files sort wrongly |
| `'a snapshot taken in the nonexistent hour still produces a valid filename'` | `appNow()` at 01:30 on 29 March 2026, an hour that never happens locally. The instant is opaque; the filename is UTC; nothing throws. |

### 5.5 Verification, in order

```bash
fvm flutter test test/data/diagnostics_snapshot_test.dart
TZ=Europe/London fvm flutter test test/data/snapshot_ambiguous_hour_test.dart
fvm flutter test test/drift/                 # the migration tier still green with a snapshot in the open path
dart tool/check_policy.dart              # .copy( ban and the magic-size rule
make check
make test
```

## 6. Constraints that bind this task

- **Never rethrow from setup.** A failed snapshot must not stop the app opening. This is the whole
  point of the task and the easiest thing to lose in a refactor.
- **Never `File.copy` a live database.** Three files in WAL mode; `04 §8.1` bans it under
  `lib/core/db/` with one allowlisted exception that is not this one.
- **One word per concept** — *snapshot* here, *backup* for the JSON, never *dump* and never *sync*.
- **No magic size** — the bound is a named constant in `lib/core/db/`.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'VACUUM INTO writes a bounded snapshot and never rethrows'` passes, and was seen to fail first for the stated reason
- [ ] the snapshot is bounded in size and in count
- [ ] a failure is logged and never rethrown
- [ ] the word *snapshot* is used for this and never for the JSON backup
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/data/diagnostics_snapshot_test.dart
TZ=Europe/London fvm flutter test test/data/snapshot_ambiguous_hour_test.dart
fvm flutter test test/drift/
dart tool/check_policy.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(db): snapshot before migration, bounded and never fatal`

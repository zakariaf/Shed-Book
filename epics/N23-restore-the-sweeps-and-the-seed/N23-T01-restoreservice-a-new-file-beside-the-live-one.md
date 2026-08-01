# N23-T01 — `RestoreService` — a new file beside the live one

| | |
|---|---|
| **Epic** | [N23 — Restore, the sweeps and the seed](epic.md) · `00-README` §9 step 8 (3 of 3) |
| **Task** | 1 of 7 |
| **Depends on** | N22-T05 |
| **Commit** | one commit · `feat(restore): RestoreService with an atomic swap and a resume path` |

## 1. Why this task exists

Restore never writes into the live database. It builds a **new file beside it**, validates
it, swaps, reopens — and `completeInterruptedRestore` finishes the job if the phone died mid-swap.
Anything else risks a half-restored database, which is the one state from which a shepherd cannot
recover by hand.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/04-migrations-media-backup-restore.md` | **§7.1** (replace everything, atomically, through one code path) · **§7.2** (the sixteen steps, which two are destructive, and what each failure leaves behind) · **§7.5** (the resume routine printed in full, its four states, and the nine post-restore invariants) · §7.4 (the eight failure modes) · §7.7 (what restore never does) · §7.8 (the gate table) · §8.1 (`File.copy` is *"the single most dangerous line of code anyone could write in this app"*) · §1 row 4 | the flow, verbatim — do not re-derive a step |
| `docs/engineering/09-export-formats.md` | §5.3 (the five tables with no `uid`, and the vocabulary-FK exception) · §5.5 (accept older, refuse newer) · §5.6 (`importDefaults`) · **§7.2 items 3, 7, 8, 9, 12, 13** (uid identity, every column emitted, `unknown_json` merged at the top level, symmetric exclusions, ids re-issued, nothing re-stamped) | what the importer must and must not do to a row |
| `docs/engineering/CONVENTIONS.md` | **§2.8** (`RestoreService` · `RestoreOutcome` · `completeInterruptedRestore(Directory)`; `AppDatabase`'s constructor; `BackupHeader`) · §2.4 (`WriteOutcome`, non-generic) · §2.5 (the six `ShedFailure` variants and `shedFailureFrom`) · §2.13 (`RestoreService` owns writes to all tables, once, into a **new** file) · §3.1 (`restoreServiceProvider`, `databaseProvider`) · §1.1 layer rules 3, 4, 8 · **R12, R13, R14, R52, R65** · §5 (vocabulary) | **BINDING** on every name in this diff |
| `docs/engineering/12-testing.md` | §3.1 (`testDatabase()`) · §3.3 (repository tests use real SQL, never a mock) · §2.3 (the ambiguous hour) · §11.6 (no `Future.delayed`, no wall-clock assertion) | how the anchor is written |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · **#73** (replace everything, atomically) · #13 (`WriteOutcome`) · #20 (`databaseProvider` is a `FutureProvider`) · #21 (nothing awaited in `main()`) · #27 (application support) · #28 (`synchronous = FULL`) · #42 (`seedFirstRun` in `onCreate`) · #63 (`cancelAll()` then `reconcile()`) · #88 (the entitlement is never imported) · #123, #124 (what the diagnostics log may record) | the decisions this task applies |
| `CLAUDE.md` | the vocabulary table — **restore**, never *merge*; *the backup* is JSON and *the snapshot* is `VACUUM INTO`, and the two are never swapped · the banned words · the authority order | the words that may not appear |
| `epics/00-PLAN-CRITIQUE.md` | the E19 split ruling — *"a format (reviewable) and the app's most destructive code path (not)"* | why this task is alone in its risk class |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-export-and-restore` | restore replaces everything and there is no merge |
| `shed-bootstrap-and-errors` | the reopen, the interrupted-restore detection and the failure surface |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/restore_test.dart`
- **Test** — `'a restore interrupted before the swap leaves the live database untouched and completes on next launch'`
- **Why it is red today** — nothing restores, and every simpler design writes into the live file.

```bash
fvm flutter test test/features/restore_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it cannot pass by accident. The test must:

1. Build a live database **on disk** with known rows, and a backup file with **different** known rows.
2. Inject the fault **between step 10 (the sentinel is written) and step 11 (the first rename)** —
   through a seam the service exposes for exactly this, or a subclass declared in the test file. Not a
   `try`/`catch` wrapped round the whole flow: that proves nothing about ordering.
3. Assert the live file still holds the **original** rows.
4. Call `completeInterruptedRestore(support)` — the launch path — and assert it returns
   **`RestoreOutcome.notStarted`**. Not `completed`, not `rolledBack`.
5. Assert `restore.pending` is gone, `restore_staging/` is gone, and the live file is *still* the
   original. Nothing was destroyed, and nothing pretends otherwise.

**Green.** The minimum code that passes, and nothing beyond it — the new-file build, the validate, the atomic swap, the reopen, and the resume path.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step.** N23 adds no table and no column; `drift_schemas/` must not move. Say so in the
commit message. `unknown_json` and `lib/data/import_defaults.dart` are already in the tree — N07
landed the column, N22-T03 landed the map. Read both; re-create neither.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/db/queries.drift` | **Edit.** Step 7's validation statements and step 8's checkpoint, as named queries, because `customStatement(` is banned outside `lib/core/db/` (layer rule 8): `foreignKeyCheck`, `quickCheck`, `rebuildSearchIndex` (`INSERT INTO search_fts(search_fts) VALUES('rebuild')`) and `walCheckpointTruncate`. This regenerates `database.g.dart`, and that regeneration is **in this commit** |
| 2 | `lib/data/restore_service.dart` | **New.** The whole of this task's `lib/` surface: `RestoreService` with its two halves (§5.2), `enum RestoreOutcome`, and the top-level `completeInterruptedRestore(Directory)`. It is the only file in the product that renames the live database |
| 3 | `lib/data/failure_mapping.dart` | **Edit, only if needed.** `shedFailureFrom` already unwraps `DriftRemoteException` and maps `SQLITE_FULL` (13) and `SQLITE_IOERR` (10) to `DiskFull`. Building staging on a full disk is the likeliest failure in this diff — confirm the existing mapping covers it rather than adding a second one |
| 4 | `lib/data/providers.dart` | **Edit.** `restoreServiceProvider` (`FutureProvider<RestoreService>`, keepAlive — `CONVENTIONS` §3.1), and the one line inside `databaseProvider` that awaits `completeInterruptedRestore(support)` **before** `openAppDatabase()`. `04 §7.5`: *"called from the post-first-frame bootstrap, before `databaseProvider` resolves"* (#20, #21) |
| 5 | `docs/engineering/CONVENTIONS.md` | **Edit.** §2.8's `RestoreService` row gains the verb and the result type this task introduces. A verb two files call and the naming authority does not carry is how a second spelling is born |
| 6 | `test/features/restore_test.dart` | **New.** The anchor and its neighbours (§5.4). T02 appends its widget cases to this same file |

Nothing under `lib/features/` changes. There is no screen yet; the entry point is T02.

### 5.2 The signatures

**The split is the point of this task.** The import half writes rows into a database it is handed; the
swap half owns the files. If they are one method, `restoreFixture` (T05) cannot exist — it restores
into an already-open in-memory database with no files to rename — and the overflow matrix cannot use
the committed fixtures, which re-opens critique **S3** in the epic that was meant to close it.

```dart
// lib/data/restore_service.dart — the ONLY file that renames the live database.

/// The FOUR reachable states of an interrupted swap, plus "nothing to do".
/// This enum belongs to the RESUME routine and to nothing else: `09 §7.3` —
/// "RestoreOutcome is 04's enum, not a value with a database on it."
/// `notStarted` must never become a legal answer to "did the restore work?".
enum RestoreOutcome { nothingToDo, notStarted, rolledBack, completed, lostBothFiles }

final class RestoreService {
  /// The support directory is INJECTED. `getApplicationSupportDirectory()` is
  /// banned outside connection.dart and media_store.dart (check_policy rule
  /// `layer.path_provider`, 04 §4.9) — and injecting it is what makes
  /// tool/seed.dart (a plain Dart script with no Flutter bindings) and every
  /// test able to call this code at all.
  RestoreService(this._support, this._notifications);

  final Directory _support;
  final NotificationScheduler _notifications;

  /// HALF ONE — 04 §7.2 steps 6 and 7, against a database that is already open.
  /// One transaction, parents before children in a fixed topological order,
  /// `PRAGMA defer_foreign_keys = ON` inside it. Resolves every `*_uid` to the
  /// new integer id from a map built as each parent is inserted; skips the
  /// entitlement row and records that it did (#88); runs `seedFirstRun` at the
  /// END of the same transaction if and only if the backup carries no season
  /// (#42, #74). Then validates: per-table COUNT(*) against `counts`,
  /// `foreign_key_check` empty, `quick_check` ok, `app_settings` has exactly one
  /// row, `current_season` resolves, the FTS index rebuilt and probed.
  ///
  /// This is the half `restoreFixture` (N23-T05) calls, and it must never touch
  /// a file. It throws on a validation failure; the caller decides what that
  /// means, because the two callers mean different things by it.
  Future<void> importInto(
    AppDatabase target,
    BackupHeader header,
    Map<String, List<Map<String, Object?>>> tables,
  );

  /// HALF TWO — the whole of 04 §7.2 steps 5 to 14, including the two renames.
  /// Returns `WriteCommitted()` on success and `WriteFailed(ShedFailure)` on an
  /// abort, so one call site handles one shape (#13). The verb is `restore`
  /// because the vocabulary has exactly one word for this act — `import`,
  /// `apply` and `load` are ambiguous or banned (CLAUDE.md, CONVENTIONS §5.1).
  Future<WriteOutcome> restore({
    required File incoming,
    required BackupHeader header,
  });
}

/// Runs on EVERY launch, before the database is opened, from databaseProvider.
/// 04 §7.5 prints this in full — copy it, do not paraphrase it.
Future<RestoreOutcome> completeInterruptedRestore(Directory support) async {
  final sentinel = File(p.join(support.path, 'restore.pending'));
  if (!sentinel.existsSync()) return RestoreOutcome.nothingToDo;
  // … the switch over (live.existsSync(), rollback.existsSync()) …
  LocalLog.instance.record('restore.${outcome.name}');   // no row contents (#124)
}

/// Moves a database and BOTH sidecars, because step 11 moved all three and a
/// main file reunited with a stale -wal is the corruption of 04 §8.1.
Future<RestoreOutcome> _moveInto(File from, File to, RestoreOutcome then);
```

The four-state switch is the part people get wrong, so write out what each arm *means*:

| `(live, rollback)` | Crashed | Outcome | The sentence the app says next |
|---|---|---|---|
| `(true, false)` | after step 10, before step 11 | `notStarted` | *"The restore did not start. Your records are unchanged."* |
| `(false, true)` | between 11 and 12 | `rolledBack` | the original is moved back, and the app says the restore was undone |
| `(true, true)` | after 12, before 13 | `completed` | the new file was fully validated at step 7 — a success we merely failed to record |
| `(false, false)` | mid-`rename`, or tampering | `completed` from staging, else `lostBothFiles` | `lostBothFiles` is the only branch that reaches `04 §8.4`'s corruption screen |

An app that knows only two states reports the first row as **success**. That is the specific lie this
enum exists to prevent.

### 5.3 The details that are easy to get wrong

- **Steps 11 and 12 are the only destructive operations, and step 10 is the last non-destructive one.**
  Everything up to and including step 9 can be abandoned with nothing lost. Anything that moves a
  destructive act earlier — deleting the live file to "make room", truncating it, opening it read-write
  before validation — makes the sentinel useless and the four states unreachable.
- **`_moveInto` moves three files, not one.** Main, `-wal`, `-shm`, together, in both directions.
  `04 §8.1`, quoting sqlite.org: *"if a database file is separated from its WAL file, then transactions
  that were previously committed to the database might be lost, or the database file might become
  corrupted."*
- **`PRAGMA wal_checkpoint(TRUNCATE)` at step 8, then assert no `-wal`/`-shm` remains beside staging.**
  Not "close and hope". A staging file swapped in with its own sidecars still beside it is the same
  corruption from the other direction.
- **`PRAGMA foreign_keys = OFF` is a no-op inside a transaction**, and drift wraps the import in one.
  The correct pragma is `PRAGMA defer_foreign_keys = ON` issued *inside* the transaction, followed by
  `PRAGMA foreign_key_check` at the end, which must return **zero rows**. `04 §2.6` states this about
  migrations; it is exactly as true here, and this is where people reach for `foreign_keys = OFF`.
- **`seedOnCreate: false` on staging, and `seedFirstRun` only when the backup has no season.**
  `AppDatabase(conn, seedOnCreate: false)` at step 5 so `onCreate` builds today's schema with **no**
  first-run season; then run `seedFirstRun` at the end of the *same* transaction as the import if and
  only if `tables['seasons']` is empty — every event table's `season` is `NOT NULL`, so a seasonless
  restored database cannot accept a lambing. Get the condition backwards and every restored database
  gains a phantom `"<year> lambing"` nobody created, and T07's round trip fails on the first table.
- **Nothing is re-stamped.** `created_at` and `updated_at` are written exactly as they appear in the
  file; the importer never substitutes `appNow()`. `09 §7.2` item 13: freshening `updated_at` breaks
  byte equality on every row in the database at once **and** destroys the only evidence of when a
  record was actually made.
- **Identity is `uid`; integer ids are re-issued.** Build the `uid → new id` map as each parent is
  inserted and resolve every `<parent>_uid` against it. The five **vocabulary** FKs are the exception
  and carry a `vocab_terms.key`, not a uid: `lambings.presentation`, `lambs.death_cause`,
  `treatments.route`, `ewe_observations.kind`, `foster_events.method`. Treating one of those as a uid
  fails `foreign_key_check` at step 7, which is the good outcome; treating it as unknown and writing
  `NULL` is a silently empty column, which is not.
- **Five tables have no `uid`, and each has a written natural key** (`09 §5.3`): `app_settings` (a
  singleton, imported onto the single row), `ewe_touches` (`ewe_uid`), `pen_occupancy_lambs`
  (`occupancy_uid` + `lamb_uid`), `reminder_rules` (`kind`), `terminology_overrides` (`key`). An
  importer that assumes `uid` everywhere drops all five and the restore still passes `quick_check`.
- **The entitlement row is skipped, and the skip is recorded** (#88). Restoring your neighbour's backup
  must not unlock your app. A fixture whose `unlocked` is `1` imports to `unlocked = 0`.
- **`vocab_terms` is in the backup, and it is the cautionary tale.** `09 §5.4`: it was missing from
  04's original list, and a user-added term (`origin = 'user'`) that is not restored makes the restore
  fail its own `foreign_key_check` — on the night someone is restoring onto a replacement phone.
  Every non-derived table is imported except the named exclusions: `entitlements`, `ewe_summaries`,
  `search_docs`/`search_fts` and the shadow tables, the views, and `sqlite_sequence`.
- **`unknown_json` is merged into the row at the top level, and the column itself is never emitted.**
  Unknown keys go into it on the way in and are splatted back out *before* the keys are sorted on the
  way out. Emitting the container as well writes every preserved field twice and nests it again on the
  second export — `09 §7.2` item 8, and precisely what T07's byte equality catches.
- **`cancelAll()` at step 9, before the live database closes.** Otherwise notifications scheduled from
  pre-restore data fire against rows that no longer exist. `reconcile()` at step 15 rebuilds them and
  **does not exist yet** — write the call site as `// TODO(N24): reconcile()` with the reason beside
  it, so the missing half is visible rather than forgotten.
- **`ref.invalidate(databaseProvider)` at step 14, then pop to the root route.** Every screen re-watches
  its own query and there is no cached pre-restore state anywhere (#12, #20). Do not "refresh"
  individual providers; that is how one screen keeps a pre-restore row.
- **Never `on SqliteException catch (e)`.** `drift_flutter` runs SQLite on a background isolate, so the
  exception arrives wrapped in a `DriftRemoteException` and a bare `on SqliteException` clause **never
  matches**. `shedFailureFrom(Object)` in `lib/data/failure_mapping.dart` unwraps once (R4). There is
  no `ShedFailure.from`.
- **`RestoreService` never calls `getApplicationSupportDirectory()`.** The rule already bans it
  (`layer.path_provider`), and injecting the directory is what makes T04 and T06 possible at all. If
  you find yourself wanting it, stop: you are one line away from making the seed script and the test
  harness impossible to write.
- **Log the outcome, never the rows.** `LocalLog.instance.record('restore.${outcome.name}')` and
  nothing more. `LocalLog.instance` is the one diagnostics sink (R52), `_diagnostics` is a banned
  identifier, and #124's redaction list excludes tags, note text, product names, batch numbers,
  withdrawal periods and media paths.
- **`RestoreOutcome` is the resume enum only.** The live flow returns `WriteOutcome`. If a reviewer
  sees `RestoreOutcome.notStarted` returned from `restore(...)`, the two have merged and `notStarted`
  has become a legal answer to *"did my records come back?"*.

### 5.4 The full test set

`test/features/restore_test.dart`. T02 appends its widget cases to the same file, so the mechanics and
the screen read in one place — which is what `04 §7.8`'s gate table describes.

| Case | What it asserts |
|---|---|
| `'a restore interrupted before the swap leaves the live database untouched and completes on next launch'` | **The anchor.** Fault between 10 and 11 → the live file still holds the original rows → `completeInterruptedRestore` returns `notStarted` → sentinel and `restore_staging/` gone |
| `'a restore interrupted between the two renames rolls the original back'` | Fault between 11 and 12 → `rolledBack`, and the live file holds the **original** rows |
| `'a restore interrupted after the swap reports completed'` | Fault between 12 and 13 → `completed`, and the live file holds the **backup's** rows |
| `'lostBothFiles is unreachable without deleting a file by hand'` | Loop the three windows and assert the outcome is never `lostBothFiles`; then delete both files explicitly and assert that it is |
| `'the live database is never written during a restore'` | Compare the live file's bytes before the flow and immediately before step 11: identical |
| `'no -wal or -shm remains beside the staging file after the checkpoint'` | Directory listing after step 8 |
| `'the swap moves the main file and both sidecars together'` | Seed a live `-wal` and `-shm`; after step 11 all three are in `restore_rollback/` |
| `'a backup carrying no season runs seedFirstRun inside the same transaction'` | Exactly one season afterwards, `current_season` resolves, and it was created inside the import transaction |
| `'a backup carrying seasons does not run seedFirstRun'` | No phantom `"<year> lambing"`; the season count equals the backup's |
| `'integer ids are re-issued and every uid survives'` | `idsOf(restored) != idsOf(source)`, `uidsOf(restored) == uidsOf(source)` — `09 §7.2` items 3 and 12 |
| `'a backup with unlocked = 1 imports to unlocked = 0'` | Decision #88 |
| `'a vocabulary FK is restored by key, never as a uid'` | A user-added `vocab_terms` row (`origin = 'user'`); `treatments.route` still reads `rt_subcutaneous` afterwards |
| `'the five tables with no uid are restored by their natural keys'` | One row each in `app_settings`, `ewe_touches`, `pen_occupancy_lambs`, `reminder_rules`, `terminology_overrides` |
| `'created_at and updated_at are restored verbatim'` | Equal to the file's values to the millisecond; nothing re-stamped |
| `'a foreign_key_check violation aborts at step 7 and leaves the live database untouched'` | A deliberately broken backup: staging deleted, live file unchanged, the failing table named in the diagnostics record and nothing else recorded |
| `'a full disk while building staging aborts and deletes staging'` | Injected `SQLITE_FULL` → `WriteFailed(DiskFull)`; live file unchanged |
| `'the nine post-restore invariants hold'` | `04 §7.5`'s list asserted directly: no two-backup database · no stale sidecar · no un-flagged missing media row · nothing silently deleted from `media/` · no sentinel · no `restore_staging/` · no pre-restore OS notification · no cached pre-restore row · no imported entitlement |
| `'restoring the phone's own current data is idempotent'` | `04 §7.4`'s last row. T07 asserts it again as a property |
| `'a restore that crosses the ambiguous hour preserves every instant'` · **`@Tags(['uk-zone'])`** | `TZ=Europe/London`, fault-free, with rows whose `occurred_at` is **01:30 on 25 October 2026** — the hour that happens twice. The stored epoch millis, the denormalised `local_date` and the `TimeSource` are identical before and after. An importer that re-parses an instant through a local `DateTime` lands an hour out here and nowhere else |

### 5.5 What this task does **not** build

The file picker and the magic-byte sniff (steps 1–2) are N22-T05's; the `BackupHeader` parse and its
refusals (step 3) are N22-T01 and N22-T04's. The confirmation (step 4) is T02. The sweeps (step 15)
are T03. `reconcile()` (step 15) is N24. Building any of them here makes the diff unreviewable in the
one place in the product where the review *is* the safety mechanism.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **The word *merge* is banned here more sharply than anywhere else.** Decision #73 forbids the feature
  and `CONVENTIONS` §5.1 forbids the word. There is no `mergeInto`, no `_merge`, and no comment
  explaining why we do not merge in a file whose every line already says so.
- **The pragma set is `configureConnection`'s, in R13's order.** Staging opens through the same setup
  function as the live database. A staging file opened with different pragmas is not the file you
  validated.
- **Layer rule 8** — `customStatement(` is banned outside `lib/core/db/`. Every pragma and every
  validation statement in this task is a named query in `queries.drift`.

## 7. Definition of Done

- [ ] `'a restore interrupted before the swap leaves the live database untouched and completes on next launch'` passes, and was seen to fail first for the stated reason
- [ ] the live database is never written during a restore
- [ ] the swap is atomic
- [ ] an interrupted restore completes or rolls back on next launch, never leaves a half state
- [ ] the word *merge* appears nowhere — there is no merge
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `importInto` and `restore` are separate members, and `importInto` touches no file
- [ ] `RestoreOutcome` is returned by `completeInterruptedRestore` and by nothing else
- [ ] all four resume states are reachable in a test, and `lostBothFiles` only by deleting a file by hand
- [ ] the swap moves the main file, `-wal` and `-shm` together, in both directions
- [ ] `getApplicationSupportDirectory(` does not appear in `lib/data/restore_service.dart`
- [ ] `seedFirstRun` runs if and only if the backup carries no season, inside the import transaction
- [ ] the entitlement row is skipped and the skip is recorded
- [ ] `CONVENTIONS.md` §2.8 carries the verb and the result type this task introduces
- [ ] `drift_schemas/` is unchanged, and `database.g.dart`'s regeneration is in this commit

## 8. Verification

```bash
fvm flutter test test/features/restore_test.dart
make check
make test
```

```bash
# The DST leg — the ambiguous-hour case only runs under this zone.
TZ=Europe/London fvm flutter test --tags uk-zone

# The three crash windows, reproduced one at a time (12 §6.3's protocol).
fvm flutter test test/features/restore_test.dart --plain-name 'interrupted before the swap'
fvm flutter test test/features/restore_test.dart --plain-name 'between the two renames'
fvm flutter test test/features/restore_test.dart --plain-name 'after the swap'
```

```bash
grep -rn "merge" lib/                                       # expect zero
grep -rn "getApplicationSupportDirectory" lib/              # expect exactly two files
grep -rn "customStatement(" lib/ --include=*.dart | grep -v "^lib/core/db/"   # expect zero
grep -rn "\.copy(" lib/core/db/                             # expect zero (04 §8.1)
grep -n  "on SqliteException" lib/data/restore_service.dart # expect zero
grep -n  "RestoreOutcome" lib/data/restore_service.dart     # the resume routine only
grep -n  "foreign_keys = OFF" lib/                          # expect zero — defer_foreign_keys is the pragma
git diff --stat -- drift_schemas/                           # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(restore): RestoreService with an atomic swap and a resume path`

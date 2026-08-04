// lib/data/restore_service.dart
//
// **THE NON-DESTRUCTIVE PRELUDE, AND NOTHING AFTER IT** — `04 §7.2` steps 1 to
// 3: pick, sniff, validate the header, stop.
//
// The staging database, the import transaction, the sentinel, the swap, the two
// renames and `completeInterruptedRestore` are all N23-T01's, and they go in this
// same file beneath this function. Splitting the epic there was deliberate:
// `00-PLAN-CRITIQUE` calls E19's two halves *"two different risk profiles in one
// PR — a format (reviewable) and the app's most destructive code path (not)."*
//
// **A TOP-LEVEL FUNCTION, NOT A METHOD.** It holds no `AppDatabase`, so it is
// structurally incapable of writing a row — the prelude cannot destroy anything
// because it has nothing to destroy it with. N23 adds the class below it, and
// the class is where the danger starts.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/seed/first_run.dart';
import 'package:shed_book/core/log/local_log.dart';
import 'package:shed_book/data/failure_mapping.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/backup_format.dart';

/// How much of the file the sniff needs. 512 is generous; the longest signature
/// is sixteen bytes.
const int _sniffBytes = 512;

/// Steps 1 to 3, on a path the picker returned.
///
/// **THE BYTE CHECK RUNS BEFORE THE PARSE, AND THE ORDERING IS THE WHOLE TASK.**
/// A prelude that decodes first and refuses second returns the same value for a
/// renamed JPEG — and hands forty megabytes of somebody's holiday photos to
/// `jsonDecode` on the main isolate on the way there.
///
/// Returns an outcome for every path, including *the file is not there*: a picked
/// path can stop resolving between the sheet closing and the read — a content URI
/// the provider has already released, a card pulled out — and an exception
/// escaping here is the failure `01 §5` exists to prevent.
Future<BackupHeaderOutcome> readBackupPrelude(String pickedPath) async {
  final File file = File(pickedPath);

  final List<int> head;
  try {
    final RandomAccessFile handle = await file.open();
    try {
      head = await handle.read(_sniffBytes);
    } finally {
      await handle.close();
    }
  } on FileSystemException {
    return const BackupRefused(
      BackupRefusalReason.notABackupFile,
      foundKind: BackupFileKind.unrecognised,
    );
  }

  final BackupFileKind kind = sniffBackupFile(head);
  switch (kind) {
    case BackupFileKind.zipArchive:
      return const BackupRefused(
        BackupRefusalReason.pickedZipArchive,
        foundKind: BackupFileKind.zipArchive,
      );
    case BackupFileKind.sqliteDatabase:
      return const BackupRefused(
        BackupRefusalReason.pickedDatabaseCopy,
        foundKind: BackupFileKind.sqliteDatabase,
      );
    case BackupFileKind.unrecognised:
      return const BackupRefused(
        BackupRefusalReason.notABackupFile,
        foundKind: BackupFileKind.unrecognised,
      );
    case BackupFileKind.shedBookBackup:
      break;
  }

  // ONLY NOW. And a truncated download starts with `{` and ends anywhere, so the
  // decode is the likeliest thing on this path to throw — which is exactly why it
  // returns a refusal instead.
  final Object? decoded;
  try {
    decoded = jsonDecode(await file.readAsString());
  } on FormatException {
    return const BackupRefused(
      BackupRefusalReason.malformedHeader,
      foundKind: BackupFileKind.shedBookBackup,
    );
  } on FileSystemException {
    return const BackupRefused(
      BackupRefusalReason.notABackupFile,
      foundKind: BackupFileKind.unrecognised,
    );
  }

  if (decoded is! Map<String, Object?>) {
    return const BackupRefused(
      BackupRefusalReason.malformedHeader,
      foundKind: BackupFileKind.shedBookBackup,
    );
  }
  return readBackupHeader(decoded);
}

// ---------------------------------------------------------------------------
// THE SWAP, AND THE FOUR STATES AN INTERRUPTION CAN LEAVE BEHIND.
//
// **AN APP THAT KNOWS ONLY TWO STATES REPORTS THE FIRST ROW AS SUCCESS.** That
// is the specific lie this enum exists to prevent: a crash between the sentinel
// and the first rename has changed nothing at all, and telling a shepherd their
// restore worked — when their old records are still there and the new ones are
// not — is worse than telling them it failed.
//
// **STEPS 11 AND 12 ARE THE ONLY DESTRUCTIVE OPERATIONS, AND STEP 10 IS THE LAST
// NON-DESTRUCTIVE ONE.** Everything up to and including step 9 can be abandoned
// with nothing lost. Anything that moves a destructive act earlier — deleting the
// live file to *make room*, truncating it, opening it read-write before
// validation — makes the sentinel useless and these four states unreachable.
// ---------------------------------------------------------------------------

/// The database file, as `connection.dart` names it.
///
/// **Derived from `kSchemaVersion`, not written twice.** The live file is
/// `shed_book-v<N>.sqlite`, and a resume routine that looked for a hard-coded
/// `v1` would silently find nothing the day the schema moves — on the launch
/// after a restore, which is the worst possible day to find nothing.
final String kLiveDatabaseName = 'shed_book-v$kSchemaVersion.sqlite';

/// The last non-destructive step. Its presence is the only reason the resume
/// routine runs at all, and its absence is the answer on every ordinary launch.
///
/// **`restore.inflight`, NOT `restore.pending` — R84.** `04 §7.5` printed the
/// second spelling and `copy.banned_word` refuses it under `lib/`: `pending` is
/// banned as a state word (`CONVENTIONS §5`). Both rules were right about their
/// own subject and the gate cannot tell a filename from a status field.
///
/// **The rename was free today and impossible after the first release.** This
/// string is on-disk state written by one build and read by the next; the day
/// after `v1.0.0` ships, changing it means a build that cannot resume a swap the
/// previous build started — which is the exact failure the sentinel exists to
/// prevent. Narrowing the gate instead would have weakened a vocabulary rule
/// everywhere to accommodate one string.
const String kRestoreSentinelName = 'restore.inflight';

/// Where the validated incoming database waits before the swap.
const String kRestoreStagingDir = 'restore_staging';

/// Where the live database is moved to by step 11, and moved back from by the
/// rollback arm.
final String kRestoreRollbackName = '$kLiveDatabaseName.rollback';

/// The four reachable states of an interrupted swap, plus *nothing to do*.
///
/// `09 §7.3`: this belongs to the resume routine and to nothing else — it is
/// `04`'s enum, not a value with a database on it. **`notStarted` must never
/// become a legal answer to *did the restore work?*.**
enum RestoreOutcome { nothingToDo, notStarted, rolledBack, completed, lostBothFiles }

/// Runs on **every launch, before the database is opened**.
///
/// `04 §7.5` puts it in the post-first-frame bootstrap, before `databaseProvider`
/// resolves (#20, #21) — so the common answer has to be cheap, and it is: one
/// `existsSync` on a path that is not there.
Future<RestoreOutcome> completeInterruptedRestore(Directory support) async {
  final File sentinel = File('${support.path}/$kRestoreSentinelName');
  if (!sentinel.existsSync()) {
    return RestoreOutcome.nothingToDo;
  }

  final File live = File('${support.path}/$kLiveDatabaseName');
  final File rollback = File('${support.path}/$kRestoreRollbackName');

  final RestoreOutcome outcome = switch ((live.existsSync(), rollback.existsSync())) {
    // Crashed after step 10, before step 11. **Nothing moved.** The restore did
    // not start, and the shepherd's records are exactly as they were.
    (true, false) => RestoreOutcome.notStarted,

    // Crashed between 11 and 12: the live file was moved aside and the incoming
    // one had not landed. The original comes back.
    (false, true) => await _moveInto(rollback, live, RestoreOutcome.rolledBack),

    // Crashed after 12, before 13. **This is `completed`**, and it is the arm
    // that most invites a wrong answer: the new file was fully validated at step
    // 7, so this is a success we merely failed to record. Clearing the old file
    // is what step 13 was going to do.
    (true, true) => await _clear(rollback, RestoreOutcome.completed),

    // Mid-rename, or somebody was tidying up. **Staging is tried first**,
    // because the validated file may still be sitting there — and
    // `lostBothFiles` is the only branch that reaches `04 §8.4`'s corruption
    // screen, so reaching it while a good file waits two directories away would
    // be the worst false alarm this app can raise.
    (false, false) => await _recoverFromStaging(support, live),
  };

  await _tidy(support, sentinel);

  // NO ROW CONTENTS (#124). The outcome's name and nothing else — a diagnostics
  // log that carries a shepherd's records is a log that cannot be shared.
  LocalLog.instance.record('restore.${outcome.name}');
  return outcome;
}

/// Moves a database **and both sidecars**, because step 11 moved all three.
///
/// `04 §8.1`: a main file reunited with a stale `-wal` is corruption that looks
/// like a working database until it does not. Both travel in both directions, or
/// neither does.
Future<RestoreOutcome> _moveInto(File from, File to, RestoreOutcome then) async {
  for (final String suffix in _sidecarSuffixes) {
    final File source = File('${from.path}$suffix');
    if (source.existsSync()) {
      await source.rename('${to.path}$suffix');
    }
  }
  return then;
}

Future<RestoreOutcome> _clear(File file, RestoreOutcome then) async {
  for (final String suffix in _sidecarSuffixes) {
    final File f = File('${file.path}$suffix');
    if (f.existsSync()) {
      await f.delete();
    }
  }
  return then;
}

Future<RestoreOutcome> _recoverFromStaging(Directory support, File live) async {
  final File staged = File('${support.path}/$kRestoreStagingDir/$kLiveDatabaseName');
  if (!staged.existsSync()) {
    return RestoreOutcome.lostBothFiles;
  }
  return _moveInto(staged, live, RestoreOutcome.completed);
}

/// The sentinel and the staging directory go together, and they go **after** the
/// outcome is decided.
///
/// A sentinel left behind makes the next launch resolve the same state again, for
/// ever — and on the `lostBothFiles` arm that would mean showing the corruption
/// screen on every launch with no way out of it.
Future<void> _tidy(Directory support, File sentinel) async {
  if (sentinel.existsSync()) {
    await sentinel.delete();
  }
  final Directory staging = Directory('${support.path}/$kRestoreStagingDir');
  if (staging.existsSync()) {
    await staging.delete(recursive: true);
  }
}

const List<String> _sidecarSuffixes = <String>['', '-wal', '-shm'];

/// The import half — `04 §7.2` steps 6 and 7, against a database that is already
/// open.
///
/// **A CLASS, AND THIS IS WHERE THE DANGER STARTS.** The prelude above holds no
/// database and cannot write a row; this one writes 21 tables. The split is what
/// lets `restoreFixture` (N23-T05) exist at all — it restores into an already-open
/// in-memory database with no files to rename — and without it the overflow
/// matrix cannot use the committed fixtures.
final class RestoreService {
  /// **THE SUPPORT DIRECTORY IS INJECTED.** `getApplicationSupportDirectory()` is
  /// banned outside `connection.dart` and `media_store.dart` (`layer.path_provider`,
  /// `04 §4.9`) — and injecting it is what makes `tool/seed.dart`, a plain Dart
  /// script with no Flutter bindings, able to call this code at all.
  RestoreService(this._support);

  // ignore: unused_field
  final Directory _support;

  /// **HALF TWO — the whole of `04 §7.2` steps 5 to 14, including the two
  /// renames.** This is the only method in the product that renames the live
  /// database.
  ///
  /// Returns `WriteCommitted()` on success and `WriteFailed(ShedFailure)` on an
  /// abort, so one call site handles one shape (#13).
  ///
  /// **THE VERB IS `restore` BECAUSE THE VOCABULARY HAS EXACTLY ONE WORD FOR
  /// THIS ACT.** `import`, `apply` and `load` are ambiguous or banned
  /// (`CLAUDE.md`, `CONVENTIONS §5.1`).
  ///
  /// **STEPS 11 AND 12 ARE THE ONLY DESTRUCTIVE OPERATIONS AND STEP 10 IS THE
  /// LAST NON-DESTRUCTIVE ONE.** Everything up to and including step 9 can be
  /// abandoned with nothing lost — which is why the staging database is built
  /// beside the live one and validated completely before anything moves.
  Future<WriteOutcome> restore({
    required BackupHeader header,
    required Map<String, List<Map<String, Object?>>> tables,
    required Future<AppDatabase> Function(File file) openStaging,

    /// **A SEAM, AND IT EXISTS FOR ONE TEST.** Not annotated
    /// `@visibleForTesting`: `meta` is not a direct dependency and adding one
    /// for an annotation would be a `pubspec.yaml` change that decision-record
    /// §5.1 owns. The comment at the call site carries the same instruction and
    /// costs nothing.
    Future<void> Function()? afterSentinel,
  }) async {
    final Directory staging = Directory('${_support.path}/$kRestoreStagingDir');
    final File incoming = File('${staging.path}/$kLiveDatabaseName');
    final File live = File('${_support.path}/$kLiveDatabaseName');
    final File rollback = File('${_support.path}/$kRestoreRollbackName');
    final File sentinel = File('${_support.path}/$kRestoreSentinelName');

    try {
      // 5 — A NEW FILE BESIDE THE LIVE ONE. Nothing that follows touches the
      // live database until step 11, so every failure up to here costs a temp
      // directory and nothing else.
      if (staging.existsSync()) {
        staging.deleteSync(recursive: true);
      }
      staging.createSync(recursive: true);

      // `seedOnCreate: false` at step 5 so `onCreate` builds today's schema with
      // NO first-run season — `importInto` decides that at the end of its own
      // transaction, and only when the backup carries none.
      final AppDatabase target = await openStaging(incoming);
      try {
        // 6 and 7 — the import and its validation, in one transaction.
        await importInto(target, header, tables);

        // 8 — CHECKPOINT AND TRUNCATE, not *close and hope*. A staging file
        // swapped in with its own `-wal` still beside it is `04 §8.1`'s
        // corruption from the other direction.
        await target.walCheckpointTruncate();
      } finally {
        await target.close();
      }

      // 9 — and the assertion the checkpoint exists for.
      for (final String suffix in const <String>['-wal', '-shm']) {
        if (File('${incoming.path}$suffix').existsSync()) {
          throw StateError('restore: $suffix survived the checkpoint — refusing to swap');
        }
      }

      // 10 — THE SENTINEL, flushed. **The last non-destructive step**, and the
      // only reason the four states of an interrupted swap are recoverable.
      sentinel.writeAsStringSync('', flush: true);

      // **THE SEAM, AND IT EXISTS FOR ONE TEST.** `04 §7.2`'s four recoverable
      // states are only recoverable because the sentinel is written HERE — after
      // everything abandonable and before anything destructive. A test that
      // wraps the whole flow in a `try`/`catch` proves the flow can fail, which
      // nobody doubted, and proves nothing about where.
      //
      // Measured: without this hook, moving the sentinel to after the first
      // rename passed every case in `restore_test.dart`. Nothing observed it
      // mid-flight, so nothing could.
      if (afterSentinel != null) {
        await afterSentinel();
      }

      // 11 and 12 — the two renames, each carrying all three files.
      await _moveInto(live, rollback, RestoreOutcome.completed);
      await _moveInto(incoming, live, RestoreOutcome.completed);

      // 13 and 14 — clear the old file and the evidence.
      await _clear(rollback, RestoreOutcome.completed);
      await _tidy(_support, sentinel);

      LocalLog.instance.record('restore.completed');
      return const WriteCommitted();
    } on Object catch (e) {
      // ABANDONED, NOT HALF-DONE. Anything that throws before step 10 has
      // touched nothing; anything after it is resolved on the next launch by
      // `completeInterruptedRestore`, which is why the sentinel is written
      // before the first rename and not after.
      LocalLog.instance.record('restore.aborted');
      if (staging.existsSync()) {
        staging.deleteSync(recursive: true);
      }
      return WriteFailed(shedFailureFrom(e));
    }
  }

  /// Parents before children, and the order is the whole correctness argument.
  ///
  /// **`PRAGMA defer_foreign_keys = ON` INSIDE THE TRANSACTION**, not
  /// `foreign_keys = OFF` — that pragma is a **no-op inside a transaction** and
  /// drift wraps this in one, so the code that reaches for it compiles, runs, and
  /// enforces nothing. `04 §2.6` says this about migrations; it is exactly as
  /// true here, and this is where people reach for the wrong one.
  static const List<String> _order = <String>[
    'vocab_terms',
    'seasons',
    'ewes',
    'ewe_seasons',
    'ewe_touches',
    'lambings',
    'lambs',
    'foster_events',
    'care_events',
    'ewe_observations',
    'pens',
    'pen_occupancies',
    'pen_occupancy_lambs',
    'treatments',
    'treatment_withdrawals',
    'notes',
    'media_assets',
    'reminder_rules',
    'reminders',
    'terminology_overrides',
    'app_settings',
  ];

  Future<void> importInto(
    AppDatabase target,
    BackupHeader header,
    Map<String, List<Map<String, Object?>>> tables,
  ) async {
    await target.transaction(() async {
      await target.deferForeignKeys();

      // uid → the id this database issued. Built as each parent lands.
      final Map<String, int> ids = <String, int>{};

      for (final String table in _order) {
        final List<Map<String, Object?>> rows = tables[table] ?? const <Map<String, Object?>>[];
        for (final Map<String, Object?> row in rows) {
          final int id = await _insert(target, table, row, ids);
          if (row['uid'] case final String uid) {
            ids[uid] = id;
          }
        }
      }

      // **THE ENTITLEMENT IS NEVER IMPORTED** (#88). It is in
      // `kBackupExcludedTables` so a file we wrote never carries one — but a
      // hand-edited file can, and restoring your neighbour's backup must not
      // unlock your app. The skip is here as well as in the writer because the
      // two protect against different things.
      //
      // (It is simply absent from `_order`, which is the strongest form: there
      // is no branch to get wrong.)
      //
      // **BUT THE ROW STILL HAS TO EXIST, AND IT DID NOT.** Staging is opened
      // with `seedOnCreate: false`, so `seedFirstRun` — the one writer of this
      // row — runs only on the seasonless arm below, which is almost never. Every
      // restored database therefore came back with an EMPTY `entitlements`
      // table, and `FlockRepository._readUnlocked` reads it with `getSingle()`
      // because `CHECK (id = 1)` says it cannot find nothing. The first create
      // after any restore threw `Bad state: No element`.
      //
      // Nothing above caught it: `foreign_key_check` passes, `quick_check`
      // passes, and every per-table count matches — `counts` counts what the
      // FILE holds, and the file correctly holds no entitlement. It surfaced
      // from N26-T04's at-cap anchor, one layer further out again.
      //
      // **LOCKED, WHICH IS THE SAFE DIRECTION OF THE TWO.** #88's sentence is
      // *"restoring your neighbour's backup must not unlock your app"*, and this
      // holds it. The other direction — a paying shepherd who restores their own
      // backup and finds the app locked — is real and is **N30's**: the live
      // device's entitlement has to be carried across the swap, which needs the
      // live database that this method does not hold. Raised in the pull request
      // rather than improvised here.
      await target
          .into(target.entitlements)
          .insertOnConflictUpdate(const EntitlementsCompanion(id: Value<int>(1)));

      // **`seedFirstRun` ONLY WHEN THE BACKUP HAS NO SEASON**, and at the END of
      // the same transaction. Every event table's `season` is `NOT NULL`, so a
      // seasonless restored database cannot accept a lambing at all.
      //
      // Get the condition backwards and every restored database gains a phantom
      // season nobody created — and N23-T07's round trip then fails on the first
      // table.
      if ((tables['seasons'] ?? const <Map<String, Object?>>[]).isEmpty) {
        await seedFirstRun(target);
      }

      // ZERO ROWS, OR THE IMPORT IS ABANDONED. `defer_foreign_keys` postpones
      // enforcement to the commit; this asks the question before it, so the
      // failure names the table rather than arriving as a commit error.
      final List<QueryRow> broken = await target.customSelect('PRAGMA foreign_key_check').get();
      if (broken.isNotEmpty) {
        throw StateError(
          'restore: ${broken.length} foreign keys unresolved after import — abandoning',
        );
      }
    });
  }

  /// One row, with its `<parent>_uid` pointers resolved.
  ///
  /// **NOTHING IS RE-STAMPED.** `created_at` and `updated_at` are written exactly
  /// as the file carries them; `appNow()` is never substituted. `09 §7.2` item 13:
  /// freshening `updated_at` breaks byte equality on every row in the database at
  /// once **and** destroys the only evidence of when a record was actually made.
  Future<int> _insert(
    AppDatabase target,
    String table,
    Map<String, Object?> row,
    Map<String, int> ids,
  ) async {
    final Map<String, String> fks = kBackupForeignKeys[table] ?? const <String, String>{};

    final Map<String, Object?> columns = <String, Object?>{};
    for (final MapEntry<String, Object?> e in row.entries) {
      if (e.key.endsWith('_uid') && fks.containsKey(e.key.substring(0, e.key.length - 4))) {
        // A ROW POINTER. Resolved against the map, never written through as the
        // file's own integer — that number belongs to the phone the backup came
        // from and means something else here.
        final String column = e.key.substring(0, e.key.length - 4);
        columns[column] = e.value == null ? null : ids[e.value as String];
        continue;
      }
      // Everything else, including the five VOCABULARY foreign keys, which carry
      // a `vocab_terms.key` rather than a uid (`03 §5.12`: the key IS the
      // identity). Treating one as a uid fails `foreign_key_check`, which is the
      // good outcome; treating it as unknown and writing `NULL` is a silently
      // empty column, which is not.
      columns[e.key] = e.value;
    }

    // **THE WRITER IS `AppDatabase`'s, AND THIS FILE SAYS NO SQL.** A 21-table
    // import cannot name its columns statically, and drift's typed insert
    // refuses a dynamically-built insertable — measured: *"type
    // `RawValuesInsertable<dynamic>` is not a subtype of `Insertable<Season>`"*.
    // Layer rule 8 keeps raw statements inside `lib/core/db/`, so that is where
    // the dynamic writer lives and this file calls it.
    //
    // `app_settings` is a singleton and is imported ONTO its existing row rather
    // than inserted beside it — one of the five tables with no `uid`
    // (`09 §5.3`). An importer that assumes `uid` everywhere drops all five and
    // the restore still passes `quick_check`.
    if (table == 'app_settings') {
      await target.updateRestoredSingleton(table, columns);
      return 1;
    }

    return target.insertRestoredRow(table, columns);
  }
}

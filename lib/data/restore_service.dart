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

import 'package:shed_book/core/db/database.dart' show kSchemaVersion;
import 'package:shed_book/core/log/local_log.dart';
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

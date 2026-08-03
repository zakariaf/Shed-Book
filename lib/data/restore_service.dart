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

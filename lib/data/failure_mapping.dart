// lib/data/failure_mapping.dart — the ONE exception mapping site.
// `package:drift/remote.dart` is marked experimental and `gate` runs
// --fatal-warnings, so the import needs an ignore. It is scoped to this one
// line, with the reason, rather than relaxed in analysis_options.yaml:
// DriftRemoteException has no non-experimental home, 01 §5.3 requires unwrapping
// it, and drift_flutter produces it on every real device. Widening the analyzer
// config would hide the next experimental API too.
import 'dart:io' show FileSystemException, OSError;

// ignore: experimental_member_use
import 'package:drift/remote.dart' show DriftRemoteException;
import 'package:shed_book/core/failure.dart';
import 'package:sqlite3/common.dart' show SqliteException;

/// Turns whatever the database threw into something a shepherd can act on.
///
/// **`on SqliteException catch (e)` NEVER MATCHES IN PRODUCTION AND ALWAYS
/// MATCHES IN A TEST.** `drift_flutter` runs SQLite on a background isolate, so
/// the original arrives wrapped in a `DriftRemoteException`; an in-process
/// `NativeDatabase.memory()` does not wrap it at all. A `catch` clause written
/// against the bare type therefore passes every test and classifies nothing on a
/// phone. Unwrapping once, here, is why there is one mapping site.
///
/// **It is TOTAL.** There is no input for which it throws — not a bare `String`,
/// not a `StateError`, not `null`-shaped nonsense. A mapping function that can
/// itself fail is a mapping function that fails inside a `catch`.
///
/// **It never renders the exception's message** (`13 §8.4`). A SQLite exception's
/// `toString()` embeds the failing SQL, and the failing SQL embeds the shepherd's
/// tags, note text and batch numbers. Log `resultCode`, `extendedResultCode` and
/// an identifier you control — never `e.toString()`.
///
/// `MediaWriteFailed` is **not reachable from here**: it is a
/// `FileSystemException` from `MediaStore`, mapped at that gateway (`01 §5.1`).
/// Adding a `FileSystemException` arm would put media IO behind a SQLite-shaped
/// door.
ShedFailure shedFailureFrom(Object error) {
  final Object e = error is DriftRemoteException ? error.remoteCause : error;
  // The signature takes no stack — R4 fixes it at one argument — so the stack is
  // captured here rather than asked for. Callers are inside a catch and the
  // frame they would pass is this one anyway.
  final StackTrace s = StackTrace.current;

  return switch (e) {
    SqliteException(:final int resultCode, :final int extendedResultCode) => switch (resultCode) {
      13 => const DiskFull(), // SQLITE_FULL
      10 => const StorageWriteFailed(), // SQLITE_IOERR
      11 || 26 => DatabaseUnreadable(resultCode, extendedResultCode), // CORRUPT / NOTADB
      8 || 3 || 14 => const StorageReadOnly(), // READONLY / PERM / CANTOPEN
      // A constraint violation (19) lands here on purpose: a duplicate active
      // tag is a PROGRAMMER error, not a storage one. The write path is meant to
      // have checked, and telling a shepherd to free space would be a lie.
      _ => UnexpectedFailure(e, s),
    },

    // THE FILESYSTEM, WHICH IS A DIFFERENT SURFACE FROM THE DATABASE. A photo
    // is bytes on disk written outside any transaction, so it fails on its own
    // terms and has its own two outcomes.
    //
    // ENOSPC is 28 on both Linux and macOS/iOS; Android is Linux. The code is
    // matched rather than the message, because the message is localised by the
    // OS and a shepherd's phone may not be in English.
    FileSystemException(:final OSError? osError) =>
      osError?.errorCode == _enospc ? const DiskFull() : const MediaWriteFailed(),

    _ => UnexpectedFailure(e, s),
  };
}

/// `ENOSPC`. 28 on Linux and on Darwin, and Android is Linux.
const int _enospc = 28;

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/time/app_clock.dart';

/// A single, fully-checkpointed `.sqlite` file with **no `-wal`/`-shm`
/// sidecars**, safe to hand to the share sheet.
///
/// **Diagnostics only. This is NOT the user's backup** (decision #84). The
/// backup is the JSON export, which a person can read, re-import and keep — a
/// `.sqlite` file is something only this app can open, and offering it as a
/// backup is offering a promise the format cannot keep.
///
/// `VACUUM INTO` is what produces the single file: a plain copy of the database
/// while WAL is on leaves the recent writes in a sidecar, so the file that
/// arrives at the other end is missing exactly the rows the shepherd was asking
/// about.
///
/// **Never inside `db.transaction()`** — `VACUUM` cannot run in one.
Future<File> snapshotDatabase(AppDatabase db) async {
  final Directory tmp = await getTemporaryDirectory();
  final Directory dir = Directory('${tmp.path}${Platform.pathSeparator}diagnostics')
    ..createSync(recursive: true);

  // Decision #46: UTC, so two snapshots taken either side of a clocks change
  // sort in the order they were taken. The colons come out because they are not
  // legal in a filename on every platform a share sheet may land on.
  final String stamp = appNow().utc.toIso8601String().replaceAll(':', '-');
  final File out = File('${dir.path}${Platform.pathSeparator}shed-book-$stamp.sqlite');

  if (out.existsSync()) {
    out.deleteSync();
  }

  // The path is BOUND, never interpolated into the SQL. A temporary directory
  // is not attacker-controlled, but the habit is what matters: the one time a
  // path does come from somewhere else, this line will already be right.
  await db.customStatement('VACUUM INTO ?;', <Object?>[out.path]);
  return out;
}

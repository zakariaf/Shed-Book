import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:sqlite3/common.dart';

/// The seven pragmas, in R13's order — the **union** of 03 §1.3's list and
/// 04 §2.8's, from which nothing may be dropped.
///
/// **Top-level and public, and both properties are load-bearing** (R12).
/// `DriftNativeOptions.setup` is sent across an isolate boundary, so it must
/// capture nothing — a closure over `this` throws at open — and a private name
/// could not be referenced from `connection_test.dart`.
///
/// **Two of the seven are per-connection and not persistent**, so nothing in the
/// file header carries them and both are re-applied on every open, from exactly
/// one construction site. That is what makes *"we never forgot one"* provable
/// rather than asserted:
///
///   * without `foreign_keys`, every `ON DELETE` written in this epic is
///     decorative;
///   * without `recursive_triggers`, deleting a season silently leaves
///     `search_docs` rows for notes that no longer exist.
void configureConnection(CommonDatabase db) {
  db.execute('PRAGMA journal_mode = WAL;');

  // FULL, never NORMAL. sqlite.org on WAL + NORMAL: it "does lose durability …
  // might roll back following a power loss". Spec §5 says assume the phone dies,
  // and one extra fsync per commit at roughly ten writes a minute is free.
  db.execute('PRAGMA synchronous = FULL;');

  db.execute('PRAGMA foreign_keys = ON;');
  db.execute('PRAGMA busy_timeout = 5000;');
  db.execute('PRAGMA journal_size_limit = 4194304;');
  db.execute('PRAGMA temp_store = MEMORY;');

  // NOT about recursion. Nothing in this schema fires itself, so there is no
  // recursion to bound — which is exactly why a reviewer will want to delete
  // this line. It is what makes rows removed by an ON DELETE CASCADE fire the
  // child table's AFTER DELETE trigger, which is what keeps search_docs in step
  // with the notes (03 §9.2). It stays.
  db.execute('PRAGMA recursive_triggers = ON;');

  assertEngineCapabilities(db);
  _snapshotBeforeMigration(db);
}

/// The bound on a pre-migration snapshot.
///
/// Named rather than written as `250 * 1024 * 1024` at the one site that uses
/// it: a magic size is a magic size even when it appears once, and this is the
/// number somebody will want to change when a shepherd with four seasons of
/// photographs reports a slow launch. It lives here rather than in
/// `lib/data/media_limits.dart` with the other caps, because `lib/core/db/` may
/// not import `lib/data/` (layer rule 2).
const int kPreMigrationSnapshotMaxBytes = 250 * 1024 * 1024;

/// `VACUUM INTO` a copy of the database **before** a migration runs.
///
/// The closest thing to a safety net this product has, in an app whose only
/// backup is one the user remembered to make.
///
/// **It never rethrows.** A failed snapshot must not stop the app opening —
/// that would turn a full disk into a phone that cannot record a lambing.
///
/// **The catch is wider than 04 §2.8's, deliberately.** That section catches
/// `on SqliteException`, but `createSync` on a full disk throws a
/// `FileSystemException`, and `lengthSync` on a file that vanished throws too.
/// Neither is a `SqliteException`, so both would escape `configureConnection` —
/// and a throw from `setup` takes the app down **at launch**, which is precisely
/// the failure this function exists to survive. Do not narrow it back.
///
/// **Everything here is synchronous**: no `await`, no `path_provider`, no
/// `Future`. It runs from [configureConnection], which crosses an isolate
/// boundary and must capture nothing (R12) — so the main file's path comes from
/// the connection itself.
void _snapshotBeforeMigration(CommonDatabase db) {
  try {
    final int current = db.userVersion;
    // 0 means a database we are about to CREATE. There is nothing to protect,
    // and >= means there is no migration about to run.
    if (current == 0 || current >= kSchemaVersion) {
      return;
    }

    final String? mainPath = _mainDatabasePath(db);
    // Empty for `:memory:`. Nothing to copy, and nowhere to copy it to.
    if (mainPath == null || mainPath.isEmpty) {
      return;
    }

    final File mainFile = File(mainPath);
    // Bounded, because a snapshot at launch must never cost a minute.
    if (mainFile.lengthSync() > kPreMigrationSnapshotMaxBytes) {
      return;
    }

    // Composed with dart:io rather than `package:path`, which is a TRANSITIVE
    // dependency here — importing it trips depend_on_referenced_packages under
    // --fatal-infos, and promoting it to a direct dependency is a
    // decision-record §5 change rather than something to slip into this commit.
    // `File.parent` and the platform separator do the same job for a path this
    // simple.
    final Directory dir = Directory('${mainFile.parent.path}${Platform.pathSeparator}pre_migration')
      ..createSync(recursive: true);
    final File out = File('${dir.path}${Platform.pathSeparator}shed_book-v$current.sqlite');
    // VACUUM INTO refuses a target that already exists.
    if (out.existsSync()) {
      out.deleteSync();
    }

    db.execute('VACUUM INTO ?;', <Object?>[out.path]);
  } on Object {
    // Disk full, a damaged file, a directory that cannot be created. The
    // diagnostics log records it on the main isolate; nothing is rethrown here.
    // NEVER rethrow from setup.
  }
}

/// The `main` database's file path, read off the connection.
String? _mainDatabasePath(CommonDatabase db) {
  for (final Map<String, Object?> row in db.select('PRAGMA database_list;')) {
    if (row['name'] == 'main') {
      return row['file'] as String?;
    }
  }
  return null;
}

/// **An assertion, not a capability probe** (decision #36).
///
/// It throws a [StateError] naming the expectation. There is no `LIKE` fallback
/// branch and no runtime *"if FTS5 then … else …"* anywhere in the codebase: a
/// fallback that silently degrades search is worse than a build that refuses to
/// start, because nobody notices it.
///
/// Public only so the failure arm can be exercised from
/// `test/data/connection_test.dart`. Decision #36 spells it private; a private
/// name here would leave the arm that matters untested, which is the one thing
/// this function exists for. Raised in the pull request rather than taken
/// silently.
void assertEngineCapabilities(CommonDatabase db) {
  try {
    db.execute('CREATE VIRTUAL TABLE temp.shed_book_fts_probe USING fts5(x);');
    db.execute('DROP TABLE temp.shed_book_fts_probe;');
  } on Object catch (e) {
    throw StateError(
      'Shed Book needs FTS5, and this sqlite3 build does not provide it. '
      'Note search is not optional and there is no fallback: a degraded search '
      'is worse than a build that refuses to start. Underlying error: $e',
    );
  }
}

/// The **only** `driftDatabase(` call site in the app (R12).
///
/// It overrides `drift_flutter`'s default directory: `driftDatabase` defaults to
/// Documents, and the database goes in **application support** (decision #27) —
/// Documents is user-visible on iOS and is where the user's own exports belong,
/// not the database.
QueryExecutor openConnection() => driftDatabase(
  name: 'shed_book',
  native: const DriftNativeOptions(
    databaseDirectory: getApplicationSupportDirectory,
    setup: configureConnection,
  ),
);

/// The app's single entry point to the database.
///
/// Deferred from N07-T01 because it needs [AppDatabase], which N07-T02 creates.
///
/// **It refuses to run under `flutter_test`** (R12). A widget test that reached
/// this would open the real on-device database in the application-support
/// directory, and the failure — a test that passes locally and writes to a real
/// file — is the kind nobody attributes to the right cause. The override to add
/// is `databaseProvider`, pointed at `testDatabase()`.
Future<AppDatabase> openAppDatabase() async {
  assert(
    !Platform.environment.containsKey('FLUTTER_TEST'),
    'openAppDatabase() opens the real on-device database. Under flutter_test, '
    'override databaseProvider with testDatabase() from test/support/harness.dart.',
  );
  return AppDatabase(openConnection());
}

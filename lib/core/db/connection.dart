import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
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

  // N08-T07 adds _snapshotBeforeMigration(db) on the line below. Do not stub it.
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

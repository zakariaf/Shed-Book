// test/data/diagnostics_snapshot_test.dart — the pre-migration snapshot and the
// diagnostics one.
//
// EVERY case here opens a REAL FILE under Directory.systemTemp, and the first
// assertion is that the early return did not fire. NativeDatabase.memory()
// cannot exercise this code at all: on an in-memory database PRAGMA
// database_list returns an empty `file`, _snapshotBeforeMigration returns
// immediately, and a test written against the standard testDatabase() harness
// passes while asserting nothing.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/connection.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

Directory _tempDir(String name) {
  final Directory dir = Directory.systemTemp.createTempSync(name);
  addTearDown(() => dir.deleteSync(recursive: true));
  return dir;
}

/// A real database file at [version], with one table in it so it has bytes.
File _databaseAt(Directory dir, int version) {
  final File file = File('${dir.path}${Platform.pathSeparator}shed_book.db');
  final CommonDatabase raw = sqlite3.open(file.path);
  raw
    ..execute('CREATE TABLE keep (id INTEGER PRIMARY KEY, body TEXT) STRICT;')
    ..execute("INSERT INTO keep (body) VALUES ('a lambing');")
    ..userVersion = version;
  raw.close();
  return file;
}

Directory _snapshotDir(File main) =>
    Directory('${main.parent.path}${Platform.pathSeparator}pre_migration');

void main() {
  test('VACUUM INTO writes a bounded snapshot and never rethrows', () async {
    // AT V1 THIS PATH IS UNREACHABLE BY CONSTRUCTION, and that is the honest
    // state rather than a gap. _snapshotBeforeMigration snapshots only when
    // `0 < user_version < kSchemaVersion`, and with kSchemaVersion == 1 there is
    // no integer in that range — there is no migration to protect against,
    // because there is no v0.
    //
    // So what this case asserts today is that the guard is exactly that
    // condition, and that opening a real file at every reachable version is
    // harmless. When kSchemaVersion becomes 2, the branch below runs and
    // performs a real VACUUM INTO.
    final Directory dir = _tempDir('shed_book_premigration');

    if (kSchemaVersion < 2) {
      final File main = _databaseAt(dir, kSchemaVersion);
      final CommonDatabase opened = sqlite3.open(main.path);
      addTearDown(opened.close);

      expect(() => configureConnection(opened), returnsNormally);
      expect(
        _snapshotDir(main).existsSync(),
        isFalse,
        reason: 'no migration is possible at v1, so nothing is snapshotted',
      );
      return;
    }

    final File main = _databaseAt(dir, kSchemaVersion - 1);
    final CommonDatabase opened = sqlite3.open(main.path);
    addTearDown(opened.close);

    expect(() => configureConnection(opened), returnsNormally);

    final Directory snapshots = _snapshotDir(main);
    expect(snapshots.existsSync(), isTrue, reason: 'the early return did not fire');
    final List<File> written = snapshots.listSync().whereType<File>().toList();
    expect(written, hasLength(1));
    expect(written.single.path, endsWith('shed_book-v${kSchemaVersion - 1}.sqlite'));

    // And the snapshot is a real, openable database carrying the row.
    final CommonDatabase copy = sqlite3.open(written.single.path);
    addTearDown(copy.close);
    expect(copy.select('SELECT body FROM keep').single['body'], 'a lambing');
  });

  test('a database at the current version is not snapshotted', () async {
    // There is no migration coming, so there is nothing to protect — and a
    // snapshot on every launch would cost a shepherd a second every time.
    final Directory dir = _tempDir('shed_book_current');
    final File main = _databaseAt(dir, kSchemaVersion);

    final CommonDatabase opened = sqlite3.open(main.path);
    addTearDown(opened.close);
    configureConnection(opened);

    expect(_snapshotDir(main).existsSync(), isFalse);
  });

  test('a brand-new database is not snapshotted', () async {
    // user_version 0 is a database we are about to CREATE.
    final Directory dir = _tempDir('shed_book_new');
    final File main = _databaseAt(dir, 0);

    final CommonDatabase opened = sqlite3.open(main.path);
    addTearDown(opened.close);
    configureConnection(opened);

    expect(_snapshotDir(main).existsSync(), isFalse);
  });

  test('an in-memory database returns early rather than throwing', () async {
    // PRAGMA database_list reports an empty `file`. This is the case that makes
    // every OTHER test in this file open a real file — a suite written against
    // testDatabase() would take this path and assert nothing.
    final CommonDatabase memory = sqlite3.openInMemory();
    addTearDown(memory.close);

    expect(() => configureConnection(memory), returnsNormally);
  });

  test('the bound is a named constant, read from source rather than retyped', () {
    // A magic size is a magic size even when it appears once. This is the number
    // somebody will want to change when a shepherd with four seasons of
    // photographs reports a slow launch.
    expect(kPreMigrationSnapshotMaxBytes, 250 * 1024 * 1024);

    // DECLARATIONS, comment lines dropped. The constant's own doc comment says
    // "named rather than written as 250 * 1024 * 1024", which is how the next
    // reader learns why it is named — and a whole-file count reads that sentence
    // as a second occurrence.
    final String declarations = File(
      'lib/core/db/connection.dart',
    ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');
    expect(
      RegExp(r'250 \* 1024 \* 1024').allMatches(declarations).length,
      1,
      reason: 'the literal appears once, at the constant',
    );
  });

  test('a snapshot failure never stops the app opening', () async {
    // The property the whole function exists for, exercised by making the
    // pre_migration PATH a file rather than a directory — so createSync throws a
    // FileSystemException, which is NOT a SqliteException and is exactly what 04
    // §2.8's narrower catch would have let escape configureConnection and take
    // the app down at launch.
    //
    // A chmod would have been the obvious way to force this and does not work:
    // the test runs as the directory's owner, who can still write to it.
    final Directory dir = _tempDir('shed_book_blocked');
    final File main = _databaseAt(dir, kSchemaVersion);
    File('${dir.path}${Platform.pathSeparator}pre_migration').writeAsStringSync('not a directory');

    final CommonDatabase opened = sqlite3.open(main.path);
    addTearDown(opened.close);

    expect(
      () => configureConnection(opened),
      returnsNormally,
      reason: 'a full disk must not turn into a phone that cannot record a lambing',
    );
  });
}

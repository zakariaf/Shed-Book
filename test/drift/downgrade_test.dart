// test/drift/downgrade_test.dart — a database written by a NEWER schema must
// fail loudly and never open.
//
// Silently opening it is how a shepherd loses a season: the newer columns are
// invisible, the next write drops them, and the backup that would have saved it
// was never made.
//
// The guarantee is OURS. It is asserted here rather than quoted from a drift
// version number, because "drift throws on a downgrade" is a claim about
// somebody else's code that nothing in this repository would notice changing.
@Tags(<String>['migration'])
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/connection.dart';
import 'package:shed_book/core/db/database.dart';

/// A fresh temporary directory, removed when the test ends.
Directory _tempDir(String name) {
  final Directory dir = Directory.systemTemp.createTempSync(name);
  addTearDown(() => dir.deleteSync(recursive: true));
  return dir;
}

void main() {
  test('a database written by a newer schema fails loudly and never opens', () async {
    // A real FILE, and two independent opens.
    //
    // An in-memory database CANNOT show this, and the first version of this test
    // proved it by passing for the wrong reason: closing the first connection
    // destroys the data, so the second open throws "already closed" and the case
    // goes green without ever exercising a downgrade. The control case below is
    // what makes that distinction visible from now on.
    final File file = File('${_tempDir('shed_book_downgrade').path}/shed_book.db');

    final AppDatabase newer = AppDatabase(
      NativeDatabase(file, setup: configureConnection),
      schemaVersionOverride: kSchemaVersion + 1,
    );
    await newer.customStatement('SELECT 1');
    await newer.close();

    // The file now carries user_version = kSchemaVersion + 1, exactly as a newer
    // build would have left it.
    expect(file.existsSync(), isTrue);

    final AppDatabase older = AppDatabase(NativeDatabase(file, setup: configureConnection));
    addTearDown(older.close);

    await expectLater(
      older.customStatement('SELECT 1'),
      throwsA(anything),
      reason:
          "today's build must refuse a file written by a newer schema. Opening "
          'it makes the newer columns invisible, and the next write drops them.',
    );
  });

  test('the same file at the SAME version opens fine, so the case above is not vacuous', () async {
    // The control, and it is the whole reason the case above can be trusted.
    // Without it, "the second open throws" passes on any failure at all — a
    // missing file, a locked file, an executor somebody already closed.
    final File file = File('${_tempDir('shed_book_same').path}/shed_book.db');

    final AppDatabase first = AppDatabase(NativeDatabase(file, setup: configureConnection));
    await first.customStatement('SELECT 1');
    await first.close();

    final AppDatabase second = AppDatabase(NativeDatabase(file, setup: configureConnection));
    addTearDown(second.close);

    await expectLater(second.customStatement('SELECT 1'), completes);
  });

  test('kSchemaVersion goes up by exactly one, never down and never by two', () {
    // Rule 1, as a readable assertion rather than only a comment. stepByStep has
    // no callback for a skipped hop, so a version bumped by two ships a
    // migration that throws on a shepherd's phone during an upgrade — months
    // later, with no way to push a fix.
    expect(kSchemaVersion, greaterThanOrEqualTo(1));
    expect(kSchemaVersion, 1, reason: 'when this changes, it changes by one');
  });
}

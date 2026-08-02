// test/data/media_store_test.dart
//
// The gateway, against a real in-memory SQLite and a real temp directory.
//
// The anchor is NOT about the column — N07-T06 already proved the CHECKs fire.
// It is about the GATEWAY BEING STRUCTURALLY INCAPABLE of producing anything
// the column would refuse.
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/data/media_store.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import 'package:shed_book/domain/ids.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

/// The real shape a naive implementation produces: the absolute path the photo
/// picker handed back.
const String _absolute =
    '/var/mobile/Containers/Data/Application/8F2A/Library/Application Support/'
    'media/2026/03/019524f7-8a1c-7b3e-9f04-2c9a1e7d55b0.jpg';

/// Every asset hangs off EXACTLY ONE subject —
/// `CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) + (lambing IS NOT NULL) + (note IS NOT NULL) = 1)`.
/// A photo of nothing is a photo nobody can find again.
Future<int> _insert(AppDatabase db, String relativePath, EweId ewe) {
  final Instant now = Instant.fromDateTime(DateTime.utc(2026, 3, 1, 3, 20));
  return db
      .into(db.mediaAssets)
      .insert(
        MediaAssetsCompanion.insert(
          relativePath: relativePath,
          kind: 'photo',
          byteSize: 1024,
          ewe: Value<int?>(ewe.value),
          uid: newUid(),
          createdAt: now,
          updatedAt: now,
        ),
      );
}

void main() {
  test('an absolute path is rejected by the relative_path CHECK', () async {
    // THE ANCHOR, BOTH HALVES, IN ONE CASE.
    final AppDatabase db = testDatabase();
    final EweId ewe = await seedEwe(db, tag: '412');

    // The negative: the shape a naive implementation produces.
    await expectLater(() => _insert(db, _absolute, ewe), throwsA(isA<SqliteException>()));

    // The positive, for the SAME captured instant: what the gateway produces
    // inserts without throwing. That is the claim — not that the column is
    // strict, but that the gateway cannot reach it.
    final MediaStore store = MediaStore(supportDirectory: () async => freshSupportDir());
    final String produced = store.newRelativePath('jpg');
    expect(await _insert(db, produced, ewe), greaterThan(0));
  });

  test('every path the gateway produces satisfies all three CHECKs', () async {
    // Not one sample — a hundred, because the uid is random and the shape claim
    // is about every path rather than a lucky one.
    final AppDatabase db = testDatabase();
    final EweId ewe = await seedEwe(db, tag: '412');
    final MediaStore store = MediaStore(supportDirectory: () async => freshSupportDir());

    for (int i = 0; i < 100; i++) {
      final String p = store.newRelativePath('jpg');
      expect(p, isNot(startsWith('/')), reason: p);
      expect(p, matches(RegExp(r'^\d{4}/\d{2}/[^/]+\.[^/]+$')), reason: p);
      expect('/'.allMatches(p).length, 2, reason: p);
      expect(await _insert(db, p, ewe), greaterThan(0));
    }
  });

  test('resolve refuses a path that could leave the root', () async {
    // Defence in depth. The CHECKs make an escaping path unstorable, but a
    // resolver that CAN leave its root is not a resolver.
    final MediaStore store = MediaStore(supportDirectory: () async => freshSupportDir());

    for (final String bad in <String>[
      '/absolute/2026/03/x.jpg',
      '2026/03/../../escape.jpg',
      '../2026/03/x.jpg',
      '2026/03/sub/dir/x.jpg',
      '2026/3/x.jpg',
      'x.jpg',
    ]) {
      await expectLater(() => store.resolve(bad), throwsA(isA<ArgumentError>()), reason: bad);
    }
  });

  test('writeAtomically leaves no .part file behind', () async {
    // Write to <target>.part, flush, rename. Rename within one filesystem is
    // atomic, so a reader never sees a half-written photo — which at 03:20 is
    // the difference between a picture of a malpresentation and a grey
    // rectangle nobody can explain.
    final Directory support = freshSupportDir();
    final MediaStore store = MediaStore(supportDirectory: () async => support);

    final String path = store.newRelativePath('jpg');
    final File written = await store.writeAtomically(path, Uint8List.fromList(<int>[1, 2, 3]));

    expect(written.existsSync(), isTrue);
    expect(await written.readAsBytes(), <int>[1, 2, 3]);
    expect(File('${written.path}.part').existsSync(), isFalse);
  });

  test('the shard directory is created on demand', () async {
    final Directory support = freshSupportDir();
    final MediaStore store = MediaStore(supportDirectory: () async => support);

    final File written = await store.writeAtomically(
      store.newRelativePath('jpg'),
      Uint8List.fromList(<int>[9]),
    );
    expect(written.parent.existsSync(), isTrue);
  });

  test('the root is never persisted anywhere', () {
    // On iOS the container path carries a UUID that changes between installs.
    // A stored absolute path is a path that stops resolving on somebody else's
    // phone, months later, with their photos behind it.
    final String source = File('lib/data/media_store.dart').readAsStringSync();
    expect(source, isNot(contains('SharedPreferences')));
    expect(source, isNot(contains('app_settings')));
  });
}

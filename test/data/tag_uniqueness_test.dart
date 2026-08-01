// test/data/tag_uniqueness_test.dart — the owner's tag ruling, at the level that
// actually enforces it.
//
// 03 §6's printed test calls FlockRepository, which does not exist until N14.
// The DATABASE-level halves land here and N14 adds the repository halves — and
// the database-level assertion is the load-bearing one anyway: the repository
// maps SqliteException to WriteFailed through shedFailureFrom, so a
// repository-level assertion would also pass on a schema with no index at all.
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:sqlite3/common.dart';

import '../support/harness.dart';

Future<int> _ewe(AppDatabase db, String tag, {String status = 'active'}) => db
    .into(db.ewes)
    .insert(
      EwesCompanion.insert(
        uid: newUid(),
        createdAt: appNow(),
        updatedAt: appNow(),
        tag: tag,
        tagDigits: tag.replaceAll(RegExp(r'\D'), ''),
        status: Value<String>(status),
      ),
    );

void main() {
  test('a sold or dead ewe also releases her tag, not only a culled one', () async {
    // All three non-active statuses, because the index says `status = 'active'`
    // and a test that only tries 'culled' passes on an index that spelled it
    // `status <> 'culled'`.
    for (final String gone in <String>['sold', 'dead', 'culled']) {
      final AppDatabase db = testDatabase();
      await _ewe(db, '412', status: gone);
      await expectLater(_ewe(db, '412'), completes, reason: gone);
    }
  });

  test('0412 and 412 are two different tags', () async {
    // Uniqueness is on `tag` as typed. Making tag_digits unique would refuse
    // 0412 because 412 exists — the app deciding two tags are the same animal.
    final AppDatabase db = testDatabase();

    await _ewe(db, '412');
    await expectLater(_ewe(db, '0412'), completes);

    final List<Ewe> both = await db.select(db.ewes).get();
    expect(both.map((Ewe e) => e.tag).toList(), <String>['412', '0412']);
    expect(both.map((Ewe e) => e.tagDigits).toList(), <String>['412', '0412']);
  });

  test('a blank or whitespace-only tag is refused', () async {
    final AppDatabase db = testDatabase();

    await expectLater(_ewe(db, '   '), throwsA(isA<SqliteException>()));
  });

  test('two ACTIVE ewes with the same tag are refused whatever order they arrive in', () async {
    final AppDatabase db = testDatabase();
    await _ewe(db, 'A12');
    await expectLater(_ewe(db, 'A12'), throwsA(isA<SqliteException>()));
  });
}

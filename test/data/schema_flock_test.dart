// test/data/schema_flock_test.dart — the flock cluster, against a real SQLite.
//
// No mock anywhere in this epic: a mock of a database cannot refuse a duplicate
// tag, cannot cascade a delete and cannot enforce a CHECK, which is all any of
// these cases are about.
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:sqlite3/common.dart';

import '../support/harness.dart';

Future<int> _insertEwe(AppDatabase db, {required String tag, String status = 'active'}) => db
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

Future<int> _insertSeason(AppDatabase db, {String label = '2026'}) => db
    .into(db.seasons)
    .insert(
      SeasonsCompanion.insert(
        uid: newUid(),
        createdAt: appNow(),
        updatedAt: appNow(),
        year: 2026,
        label: label,
        startDate: LocalDate(2026, 3, 1),
      ),
    );

void main() {
  test('the partial unique index refuses a second ACTIVE ewe with tag 412 '
      'and permits a culled one', () async {
    // Both halves in one case, deliberately: either alone passes the wrong
    // schema. "Refuses a duplicate" passes on a plain UNIQUE(tag), which would
    // then refuse a new 412 for ever; "permits after culling" passes on a schema
    // with no index at all.
    final AppDatabase db = testDatabase();

    final int first = await _insertEwe(db, tag: '412');

    // await expectLater, never a bare expect on a Future: an unawaited throwsA
    // leaks the failure into the next test as an unhandled async error, and the
    // test that actually broke is not the one that reports red.
    await expectLater(
      _insertEwe(db, tag: '412'),
      throwsA(isA<SqliteException>()),
      reason: 'two ACTIVE animals cannot share a tag',
    );

    await (db.update(db.ewes)..where(($EwesTable t) => t.id.equals(first))).write(
      const EwesCompanion(status: Value<String>('culled')),
    );

    final int second = await _insertEwe(db, tag: '412');

    final List<Ewe> both = await db.select(db.ewes).get();
    expect(both, hasLength(2));
    expect(both.map((Ewe e) => e.uid).toSet(), hasLength(2), reason: 'distinct identities');
    expect(second, isNot(first));
  });

  test('the active-tag index carries both predicates', () async {
    final AppDatabase db = testDatabase();
    final List<QueryRow> rows = await db
        .customSelect("SELECT sql FROM sqlite_master WHERE name = 'idx_ewe_tag_active'")
        .get();

    final String sql = rows.single.read<String>('sql');
    expect(sql, contains("status = 'active'"));
    expect(sql, contains('struck = 0'), reason: 'R79 §f — a struck typo releases its tag at once');
    expect(sql, contains('UNIQUE'));
  });

  test('a tag is stored exactly as typed, and tag_digits rides beside it', () async {
    final AppDatabase db = testDatabase();
    await _insertEwe(db, tag: ' 0412a ');

    final Ewe e = await db.select(db.ewes).getSingle();
    expect(e.tag, ' 0412a ', reason: 'never normalised on write — spec §12.4');
    expect(e.tagDigits, '0412', reason: 'a projection, written in the same statement');
  });

  test('ewes_to_ram has no default: a blank season is not a zero one', () async {
    final AppDatabase db = testDatabase();
    await _insertSeason(db);

    final Season s = await db.select(db.seasons).getSingle();
    expect(s.ewesToRam, isNull, reason: 'decision #59 — null is "I did not record it"');
    expect(s.overFreeCap, isFalse);
  });

  test('ewe_seasons.status has no default and every writer names it', () async {
    final AppDatabase db = testDatabase();
    final int season = await _insertSeason(db);
    final int ewe = await _insertEwe(db, tag: '1');

    await db
        .into(db.eweSeasons)
        .insert(
          EweSeasonsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            season: season,
            ewe: ewe,
            status: 'to_ram',
          ),
        );

    expect((await db.select(db.eweSeasons).getSingle()).status, 'to_ram');

    // And the CHECK refuses a status nobody ruled.
    await expectLater(
      db
          .into(db.eweSeasons)
          .insert(
            EweSeasonsCompanion.insert(
              uid: newUid(),
              createdAt: appNow(),
              updatedAt: appNow(),
              season: season,
              ewe: ewe,
              status: 'maybe',
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('every flock table is STRICT', () async {
    // STRICT is what makes a text column refuse an integer. Without it SQLite's
    // type affinity quietly converts, and a tag of 412 comes back as an int on
    // one row and a string on the next.
    final AppDatabase db = testDatabase();
    final List<QueryRow> rows = await db
        .customSelect(
          "SELECT name, sql FROM sqlite_master WHERE type = 'table' AND sql IS NOT NULL",
        )
        .get();

    for (final QueryRow row in rows) {
      final String name = row.read<String>('name');
      final String sql = row.read<String>('sql');
      if (name.startsWith('sqlite_')) {
        continue;
      }
      // FTS5's virtual table and its four shadow tables. A virtual table has no
      // STRICT to declare — its storage is the module's — and the shadow tables
      // are created by SQLite, not by us. Skipping them by SHAPE rather than by
      // name means a sixth shadow table in a future SQLite is skipped too.
      if (sql.toUpperCase().contains('CREATE VIRTUAL TABLE') || name.startsWith('search_fts')) {
        continue;
      }
      expect(row.read<String>('sql').toUpperCase(), contains('STRICT'), reason: name);
    }
    expect(rows, isNotEmpty);
  });

  test('deleting a season cascades its ewe_seasons and leaves the ewes alone', () async {
    // The cascade is only real because configureConnection turns foreign_keys
    // ON — without that pragma every ON DELETE in this cluster is decorative.
    final AppDatabase db = testDatabase();
    final int season = await _insertSeason(db);
    final int ewe = await _insertEwe(db, tag: '7');
    await db
        .into(db.eweSeasons)
        .insert(
          EweSeasonsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            season: season,
            ewe: ewe,
            status: 'to_ram',
          ),
        );

    await (db.delete(db.seasons)..where(($SeasonsTable t) => t.id.equals(season))).go();

    expect(await db.select(db.eweSeasons).get(), isEmpty, reason: 'cascade');
    expect(
      await db.select(db.ewes).get(),
      hasLength(1),
      reason: 'a ewe is a physical animal and persists across seasons',
    );
  });

  test('the struck pair is unstorable in a half state', () async {
    final AppDatabase db = testDatabase();
    final int ewe = await _insertEwe(db, tag: '9');

    await expectLater(
      (db.update(db.ewes)..where(($EwesTable t) => t.id.equals(ewe))).write(
        const EwesCompanion(struck: Value<bool>(true)),
      ),
      throwsA(isA<SqliteException>()),
      reason: 'struck = 1 with a null struck_at says a strike happened at no moment',
    );

    await (db.update(db.ewes)..where(($EwesTable t) => t.id.equals(ewe))).write(
      EwesCompanion(struck: const Value<bool>(true), struckAt: Value<Instant>(appNow())),
    );
    expect((await db.select(db.ewes).getSingle()).struck, isTrue);
  });
}

// test/data/lambing_repository_test.dart
//
// beginLambing, against a real in-memory SQLite. The contract has two halves and
// they fail differently: on success it returns a LambingId, and on failure it
// THROWS rather than returning a WriteFailed — because there is no id to hand
// back and the screen cannot open.
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import '../support/harness.dart';
import '../support/reads.dart';
import '../support/seeds.dart';

Future<SeasonId> _seedSeason(AppDatabase db) async {
  final Instant now = Instant.fromDateTime(DateTime.utc(2026, 3, 1, 3, 20));
  final int id = await db
      .into(db.seasons)
      .insert(
        SeasonsCompanion.insert(
          year: 2026,
          label: '2026',
          startDate: LocalDate(2026, 1, 1),
          uid: newUid(),
          createdAt: now,
          updatedAt: now,
        ),
      );
  await (db.update(db.appSettings)..where(($AppSettingsTable t) => t.id.equals(1))).write(
    AppSettingsCompanion(currentSeason: Value<int?>(id)),
  );
  return SeasonId(id);
}

void main() {
  late AppDatabase db;
  late LambingRepository repo;

  setUp(() {
    db = testDatabase();
    repo = LambingRepository(db: db);
  });

  test('beginLambing commits a row and throws on failure, returning a LambingId', () async {
    // THE ANCHOR, BOTH HALVES.
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');

    // SUCCESS. The return type is a LambingId, not a WriteOutcome (R32).
    final LambingId id = await repo.beginLambing(ewe);
    expect(id, isA<LambingId>());
    expect(await countLambings(db), 1);

    final Lambing row = await readLambing(db, id);

    // P8: NOTHING ON THE FIVE-TAP PATH DECLARES A BIRTH TYPE. It is derived from
    // the tally strokes and labelled (COUNTED), which is what makes §12.4
    // structural rather than procedural.
    expect(row.declaredBirthType, isNull);
    expect(row.ease, isNull, reason: 'a blank ease means NOT SCORED, never unassisted');

    // The §12.5 provenance quad, coherent for a row written as it happened.
    expect(row.timeSource, 'auto');
    expect(row.originalEffective, isNull);
    expect(row.occurredAt, row.capturedAt);

    // FAILURE. foreign_keys = ON, so an unseeded ewe cannot get a lambing — and
    // the verb THROWS rather than returning a WriteFailed.
    await expectLater(
      () => repo.beginLambing(const EweId(999999)),
      throwsA(isA<SqliteException>()),
    );

    // NOTHING SURVIVES, and the honest reading of WHY is worth writing down.
    // MEASURED by drilling: replacing the transaction with a bare async closure
    // does NOT redden this, because the foreign-key failure lands on the FIRST
    // statement — there is nothing written yet to roll back. So these two
    // assertions are true, and they are not what holds the transaction.
    //
    // The behavioural version needs a LATER statement to fail while an earlier
    // one has already written, and this verb has no failure mode with that
    // shape: the touch cannot fail once the lambing succeeded. The mechanism is
    // asserted where it can be — on the source — and the day N24 adds reminder
    // rows inside this transaction, a real rollback case becomes writable.
    expect(await countLambings(db), 1, reason: 'the failed call left no row');
    expect((await db.select(db.eweTouches).get()).length, 1, reason: 'nor a touch');

    expect(
      File('lib/data/lambing_repository.dart').readAsStringSync(),
      contains('_db.transaction('),
      reason: 'the writes are one transaction — N24 puts the reminder rows inside it',
    );
  });

  test('local_date is derived from occurred_at in Dart, in the same statement', () async {
    // SQLite cannot bucket by a local civil day without a tz database, so the
    // derivation is Dart's. A local_date read from a SECOND clock is how the
    // lambing-spread histogram acquires a one-row-off bug that nobody sees until
    // the season summary.
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');

    final Lambing row = await readLambing(db, await repo.beginLambing(ewe));
    expect(row.localDate, LocalDate.of(row.occurredAt));
  });

  test('the uid is a real one and the row is findable by it', () async {
    // The uid is the identity that survives export and re-import (#32), so it is
    // read back through the same helper the export path will use.
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId id = await repo.beginLambing(ewe);

    final Lambing row = await readLambing(db, id);
    expect(row.uid, hasLength(36));
    expect((await readLambingByUid(db, row.uid)).id, id.value);
  });

  test('beginLambing touches the ewe, so she is findable from the recents strip', () async {
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    await repo.beginLambing(ewe);

    final EweTouch touch = await (db.select(
      db.eweTouches,
    )..where(($EweTouchesTable t) => t.ewe.equals(ewe.value))).getSingle();
    expect(touch.touchedAt, isNotNull);
  });

  test('beginLambing never creates a season', () async {
    // A verb that invented one would give the shepherd a season they did not
    // start, on the 3am path, silently — and the season is the unit the whole
    // free tier is priced on. Quick Entry must not offer a lambing without one.
    final EweId ewe = await seedEwe(db, tag: '412');
    await expectLater(() => repo.beginLambing(ewe), throwsA(isA<StateError>()));
    expect(await db.select(db.seasons).get(), isEmpty);
  });

  test('two lambings for the same ewe are two rows', () async {
    // There is no upsert here and there must not be: a ewe lambs in more than
    // one season, and collapsing them would delete a year of history.
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');

    final LambingId first = await repo.beginLambing(ewe);
    final LambingId second = await repo.beginLambing(ewe);

    expect(first.value, isNot(second.value));
    expect(await countLambings(db), 2);
  });
}

// test/data/schema_lambing_test.dart — the lambing cluster.
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:sqlite3/common.dart';

import '../support/harness.dart';

Future<int> _season(AppDatabase db) => db
    .into(db.seasons)
    .insert(
      SeasonsCompanion.insert(
        uid: newUid(),
        createdAt: appNow(),
        updatedAt: appNow(),
        year: 2026,
        label: '2026',
        startDate: LocalDate(2026, 3, 1),
      ),
    );

Future<int> _ewe(AppDatabase db, String tag) => db
    .into(db.ewes)
    .insert(
      EwesCompanion.insert(
        uid: newUid(),
        createdAt: appNow(),
        updatedAt: appNow(),
        tag: tag,
        tagDigits: tag,
      ),
    );

Future<int> _lambing(AppDatabase db, int season, int ewe, {int? declared}) => db
    .into(db.lambings)
    .insert(
      LambingsCompanion.insert(
        uid: newUid(),
        createdAt: appNow(),
        updatedAt: appNow(),
        season: season,
        ewe: ewe,
        occurredAt: appNow(),
        capturedAt: appNow(),
        localDate: LocalDate(2026, 3, 4),
        declaredBirthType: Value<int?>(declared),
      ),
    );

Future<int> _lamb(AppDatabase db, int lambing, int birthDam, {String? tag}) => db
    .into(db.lambs)
    .insert(
      LambsCompanion.insert(
        uid: newUid(),
        createdAt: appNow(),
        updatedAt: appNow(),
        lambing: lambing,
        birthDam: birthDam,
        tag: Value<String?>(tag),
      ),
    );

void main() {
  test('birth_dam is immutable, and SQLite is what says so', () async {
    // The one rule in this schema enforced by the engine rather than by Dart. A
    // Dart guard is one repository method away from being bypassed, and a lamb
    // whose birth dam moved has lost the fact the two-dam model exists to keep.
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int dam = await _ewe(db, '412');
    final int other = await _ewe(db, '128');
    final int lambing = await _lambing(db, season, dam);
    final int lamb = await _lamb(db, lambing, dam);

    await expectLater(
      (db.update(db.lambs)..where(($LambsTable t) => t.id.equals(lamb))).write(
        LambsCompanion(birthDam: Value<int>(other)),
      ),
      throwsA(
        isA<SqliteException>().having(
          (SqliteException e) => e.message,
          'message',
          contains('birth_dam is immutable'),
        ),
      ),
    );

    expect((await db.select(db.lambs).getSingle()).birthDam, dam);
  });

  test('a lambing row exists before any birth type is tapped', () async {
    // R6, and it is the whole write path: the row is created on screen ENTRY
    // (decision #11), so NULL means "not yet tapped" — a different fact from any
    // of 1..5, and never defaulted to single.
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int ewe = await _ewe(db, '412');

    await _lambing(db, season, ewe);

    final Lambing l = await db.select(db.lambings).getSingle();
    expect(l.declaredBirthType, isNull);
    expect(l.ease, isNull, reason: 'blank is "not scored", not "unassisted"');
  });

  test('a declared twin with three lambs is STORED, not refused', () async {
    // Spec §12.4's worked example at the schema level: both numbers are
    // preserved verbatim. There is no CHECK forcing them to agree, no trigger
    // correcting either, and no warnings column to persist the contradiction
    // into.
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int ewe = await _ewe(db, '412');
    final int lambing = await _lambing(db, season, ewe, declared: 2);

    for (int i = 0; i < 3; i++) {
      await _lamb(db, lambing, ewe);
    }

    expect((await db.select(db.lambings).getSingle()).declaredBirthType, 2);
    expect(await db.select(db.lambs).get(), hasLength(3));
  });

  test('no table in the schema has a warnings column', () async {
    // Guarantee 2 of 05 §7.5, at the level that would have to hold it. A warning
    // cannot be persisted because there is nowhere to persist it.
    final AppDatabase db = testDatabase();

    for (final TableInfo<Table, dynamic> table in db.allTables) {
      expect(
        table.$columns.map((GeneratedColumn<Object> c) => c.name),
        isNot(contains('warnings')),
        reason: table.actualTableName,
      );
    }
  });

  test('the birth-weight CHECK is a unit-slip guard, not a husbandry opinion', () async {
    // 200 g and 20 000 g both store. A range a vet would recognise — say
    // 2 000–7 000 — would refuse a real hill twin and a real caesarean single,
    // and would be the app holding a husbandry opinion (§12.2). The band a
    // shepherd actually sees is kPlausibleBirthWeight, and it WARNS.
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int ewe = await _ewe(db, '412');
    final int lambing = await _lambing(db, season, ewe);

    for (final int grams in <int>[200, 999, 20000]) {
      await expectLater(
        db
            .into(db.lambs)
            .insert(
              LambsCompanion.insert(
                uid: newUid(),
                createdAt: appNow(),
                updatedAt: appNow(),
                lambing: lambing,
                birthDam: ewe,
                birthWeightG: Value<int?>(grams),
              ),
            ),
        completes,
        reason: '$grams g',
      );
    }

    await expectLater(
      db
          .into(db.lambs)
          .insert(
            LambsCompanion.insert(
              uid: newUid(),
              createdAt: appNow(),
              updatedAt: appNow(),
              lambing: lambing,
              birthDam: ewe,
              birthWeightG: const Value<int?>(5),
            ),
          ),
      throwsA(isA<SqliteException>()),
      reason: '5 g is a unit slip, not a lamb',
    );
  });

  test('a death cause without a death is refused; a death without a date is not', () async {
    // A death date implies a death. A death does NOT imply a date — "died, date
    // not recorded" is a real state and lands in unknownAge.
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int ewe = await _ewe(db, '412');
    final int lambing = await _lambing(db, season, ewe);

    await expectLater(
      db
          .into(db.lambs)
          .insert(
            LambsCompanion.insert(
              uid: newUid(),
              createdAt: appNow(),
              updatedAt: appNow(),
              lambing: lambing,
              birthDam: ewe,
              deathDate: Value<LocalDate?>(LocalDate(2026, 3, 5)),
            ),
          ),
      throwsA(isA<SqliteException>()),
      reason: "status defaults to 'alive'",
    );

    await expectLater(
      db
          .into(db.lambs)
          .insert(
            LambsCompanion.insert(
              uid: newUid(),
              createdAt: appNow(),
              updatedAt: appNow(),
              lambing: lambing,
              birthDam: ewe,
              status: const Value<String>('dead'),
            ),
          ),
      completes,
      reason: 'died, date not recorded',
    );
  });

  test('a tagless lamb is storable, and two of them coexist', () async {
    // Lamb identity is the ROW, never the tag. Anything else loses exactly the
    // losses that matter most — the ones that died before anybody tagged them.
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int ewe = await _ewe(db, '412');
    final int lambing = await _lambing(db, season, ewe);

    await _lamb(db, lambing, ewe);
    await _lamb(db, lambing, ewe);

    expect(await db.select(db.lambs).get(), hasLength(2));
  });

  test('two ALIVE lambs cannot share a tag, and a dead one releases it', () async {
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int ewe = await _ewe(db, '412');
    final int lambing = await _lambing(db, season, ewe);

    final int first = await _lamb(db, lambing, ewe, tag: 'L1');
    await expectLater(_lamb(db, lambing, ewe, tag: 'L1'), throwsA(isA<SqliteException>()));

    await (db.update(db.lambs)..where(($LambsTable t) => t.id.equals(first))).write(
      const LambsCompanion(status: Value<String>('dead')),
    );
    await expectLater(_lamb(db, lambing, ewe, tag: 'L1'), completes);
  });

  test('a ewe with lambings cannot be deleted, and a season delete still works', () async {
    // The RESTRICT/CASCADE asymmetry. A ewe with lambings is a record someone
    // may show a vet; she leaves the flock by status, not by DELETE. A lamb
    // cannot be RESTRICT, or deleting a season would abort from a child table
    // the user never sees.
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int ewe = await _ewe(db, '412');
    final int lambing = await _lambing(db, season, ewe);
    await _lamb(db, lambing, ewe);

    await expectLater(
      (db.delete(db.ewes)..where(($EwesTable t) => t.id.equals(ewe))).go(),
      throwsA(isA<SqliteException>()),
    );

    await (db.delete(db.seasons)..where(($SeasonsTable t) => t.id.equals(season))).go();
    expect(await db.select(db.lambings).get(), isEmpty);
    expect(await db.select(db.lambs).get(), isEmpty, reason: 'seasons → lambings → lambs');
    expect(await db.select(db.ewes).get(), hasLength(1));
  });
}

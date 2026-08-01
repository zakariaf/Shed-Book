// test/data/schema_pens_treatments_test.dart — the pen and treatment clusters.
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

Future<int> _pen(AppDatabase db, String label) => db
    .into(db.pens)
    .insert(
      PensCompanion.insert(uid: newUid(), createdAt: appNow(), updatedAt: appNow(), label: label),
    );

Future<int> _occupy(AppDatabase db, int pen, int season, int ewe) => db
    .into(db.penOccupancies)
    .insert(
      PenOccupanciesCompanion.insert(
        uid: newUid(),
        createdAt: appNow(),
        updatedAt: appNow(),
        pen: pen,
        season: season,
        ewe: Value<int?>(ewe),
        enteredAt: appNow(),
        capturedAt: appNow(),
      ),
    );

Future<int> _treatment(AppDatabase db, int season, {int? ewe, int? lamb}) => db
    .into(db.treatments)
    .insert(
      TreatmentsCompanion.insert(
        uid: newUid(),
        createdAt: appNow(),
        updatedAt: appNow(),
        season: season,
        ewe: Value<int?>(ewe),
        lamb: Value<int?>(lamb),
        productName: 'the bottle',
        administeredAt: appNow(),
        capturedAt: appNow(),
      ),
    );

void main() {
  test('the database physically refuses two ewes in one pen at once', () async {
    // "The whiteboard gets wiped" solved at the storage layer. A Dart guard here
    // would be correct until the first race between the pen board and an undo.
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int pen = await _pen(db, '3');
    final int first = await _occupy(db, pen, season, await _ewe(db, '412'));
    final int second = await _ewe(db, '128');

    await expectLater(_occupy(db, pen, season, second), throwsA(isA<SqliteException>()));

    // …and the pen frees when the occupancy closes. Both halves, because either
    // alone passes the wrong schema.
    await (db.update(
      db.penOccupancies,
    )..where(($PenOccupanciesTable t) => t.id.equals(first))).write(
      PenOccupanciesCompanion(
        exitedAt: Value<Instant?>(appNow()),
        exitReason: const Value<String?>('turned_out'),
      ),
    );
    await expectLater(_occupy(db, pen, season, second), completes);
  });

  test('an exit time without a reason is unstorable, and so is the reverse', () async {
    // The paired CHECK is what makes exitPen's `required reason` storable rather
    // than merely conventional.
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int pen = await _pen(db, '1');
    final int occupancy = await _occupy(db, pen, season, await _ewe(db, '412'));

    await expectLater(
      (db.update(db.penOccupancies)..where(($PenOccupanciesTable t) => t.id.equals(occupancy)))
          .write(PenOccupanciesCompanion(exitedAt: Value<Instant?>(appNow()))),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      (db.update(db.penOccupancies)..where(($PenOccupanciesTable t) => t.id.equals(occupancy)))
          .write(const PenOccupanciesCompanion(exitReason: Value<String?>('moved'))),
      throwsA(isA<SqliteException>()),
    );
  });

  test('a pen with history cannot be deleted; it is deactivated instead', () async {
    // The pen board is a record, not a whiteboard.
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int pen = await _pen(db, '1');
    await _occupy(db, pen, season, await _ewe(db, '412'));

    await expectLater(
      (db.delete(db.pens)..where(($PensTable t) => t.id.equals(pen))).go(),
      throwsA(isA<SqliteException>()),
    );

    await (db.update(db.pens)..where(($PensTable t) => t.id.equals(pen))).write(
      const PensCompanion(isActive: Value<bool>(false)),
    );
    expect((await db.select(db.pens).getSingle()).isActive, isFalse);
  });

  test('a treatment has exactly one subject — never both, never neither', () async {
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int ewe = await _ewe(db, '412');

    await expectLater(_treatment(db, season, ewe: ewe), completes);
    await expectLater(_treatment(db, season), throwsA(isA<SqliteException>()));

    final int lambing = await db
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
          ),
        );
    final int lamb = await db
        .into(db.lambs)
        .insert(
          LambsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            lambing: lambing,
            birthDam: ewe,
          ),
        );
    await expectLater(
      _treatment(db, season, ewe: ewe, lamb: lamb),
      throwsA(isA<SqliteException>()),
      reason: 'both subjects is not a treatment of two animals, it is a modelling error',
    );
  });

  test('NO ROW is how a withdrawal is not recorded', () async {
    // §12.1 at the unpersistable level. There is no column whose default could
    // quietly mean zero, because there is no row at all.
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int treatment = await _treatment(db, season, ewe: await _ewe(db, '412'));

    expect(await db.select(db.treatmentWithdrawals).get(), isEmpty);

    // And there is no withdrawal_days column on treatments to fall back to.
    expect(
      db.treatments.$columns.map((GeneratedColumn<Object> c) => c.name),
      isNot(contains('withdrawal_days')),
    );
    expect(treatment, isPositive);
  });

  test('kind = days requires both a number and a clear date', () async {
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int treatment = await _treatment(db, season, ewe: await _ewe(db, '412'));

    await expectLater(
      db
          .into(db.treatmentWithdrawals)
          .insert(
            TreatmentWithdrawalsCompanion.insert(
              uid: newUid(),
              createdAt: appNow(),
              updatedAt: appNow(),
              treatment: treatment,
              target: 'meat',
              kind: 'days',
            ),
          ),
      throwsA(isA<SqliteException>()),
      reason: 'kind = days with no number is exactly what §12.1 forbids',
    );

    await expectLater(
      db
          .into(db.treatmentWithdrawals)
          .insert(
            TreatmentWithdrawalsCompanion.insert(
              uid: newUid(),
              createdAt: appNow(),
              updatedAt: appNow(),
              treatment: treatment,
              target: 'meat',
              kind: 'days',
              days: const Value<int?>(7),
              clearDate: Value<LocalDate?>(LocalDate(2026, 3, 12)),
            ),
          ),
      completes,
    );
  });

  test('zero days is storable, because zero is a real label value', () async {
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int treatment = await _treatment(db, season, ewe: await _ewe(db, '412'));

    await expectLater(
      db
          .into(db.treatmentWithdrawals)
          .insert(
            TreatmentWithdrawalsCompanion.insert(
              uid: newUid(),
              createdAt: appNow(),
              updatedAt: appNow(),
              treatment: treatment,
              target: 'meat',
              kind: 'days',
              days: const Value<int?>(0),
              clearDate: Value<LocalDate?>(LocalDate(2026, 3, 5)),
            ),
          ),
      completes,
    );
  });

  test('not_applicable carries neither a number nor a clear date', () async {
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int treatment = await _treatment(db, season, ewe: await _ewe(db, '412'));

    await expectLater(
      db
          .into(db.treatmentWithdrawals)
          .insert(
            TreatmentWithdrawalsCompanion.insert(
              uid: newUid(),
              createdAt: appNow(),
              updatedAt: appNow(),
              treatment: treatment,
              target: 'milk',
              kind: 'not_applicable',
            ),
          ),
      completes,
    );

    await expectLater(
      db
          .into(db.treatmentWithdrawals)
          .insert(
            TreatmentWithdrawalsCompanion.insert(
              uid: newUid(),
              createdAt: appNow(),
              updatedAt: appNow(),
              treatment: treatment,
              target: 'meat',
              kind: 'not_applicable',
              days: const Value<int?>(7),
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('one bottle carries one row per target and no more', () async {
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int treatment = await _treatment(db, season, ewe: await _ewe(db, '412'));

    Future<int> insert(String target) => db
        .into(db.treatmentWithdrawals)
        .insert(
          TreatmentWithdrawalsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            treatment: treatment,
            target: target,
            kind: 'not_applicable',
          ),
        );

    await insert('meat');
    await insert('milk');
    await expectLater(insert('meat'), throwsA(isA<SqliteException>()));
    expect(await db.select(db.treatmentWithdrawals).get(), hasLength(2));
  });

  test('a treatment is voided, never struck', () async {
    // R79: treatments carry voided_at rather than struck/struck_at, because the
    // row may already have been printed into a medicine book handed to a vet.
    final AppDatabase db = testDatabase();

    final Set<String> columns = db.treatments.$columns
        .map((GeneratedColumn<Object> c) => c.name)
        .toSet();
    expect(columns, contains('voided_at'));
    expect(columns, isNot(contains('struck')));
  });
}

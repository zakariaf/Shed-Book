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
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/domain/care_kind.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/sex.dart';
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

/// A season that is NOT current, seeded only to push the real one's id off 1.
///
/// Without it, `SeasonId(1)` and "the season this lambing is actually in" are
/// the same number, and a verb that never reads the parent passes every
/// assertion about seasons in this file. Drilled — see the care cases.
Future<SeasonId> _seedDecoySeason(AppDatabase db) async {
  final Instant now = Instant.fromDateTime(DateTime.utc(2025, 3, 1, 3, 20));
  final int id = await db
      .into(db.seasons)
      .insert(
        SeasonsCompanion.insert(
          year: 2025,
          label: '2025',
          startDate: LocalDate(2025, 1, 1),
          uid: newUid(),
          createdAt: now,
          updatedAt: now,
        ),
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

  test('strikeLambing marks the row and leaves it in place', () async {
    // A STRIKE IS NOT A DELETE AND NOT A SOFT-DELETE. The row keeps its
    // position, its legibility and its place in every query that is not
    // explicitly filtering. Indelible Rule 1: nothing is ever removed.
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId id = await repo.beginLambing(ewe);

    expect(await repo.strikeLambing(id), isA<WriteCommitted>());

    final Lambing row = await readLambing(db, id);
    expect(row.struck, isTrue);
    expect(row.struckAt, isNotNull);
    expect(await countLambings(db), 1, reason: 'the row STAYS — there is no delete');
  });

  test('a struck row still carries its provenance quad unchanged', () async {
    // struck_at is a MACHINE FACT ABOUT THE STRIKE, not an event time. It takes
    // no provenance quad of its own and must not disturb the one the lambing
    // already has — a strike that rewrote occurred_at would be the app editing
    // when the lamb was born.
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId id = await repo.beginLambing(ewe);

    final Lambing before = await readLambing(db, id);
    await repo.strikeLambing(id);
    final Lambing after = await readLambing(db, id);

    expect(after.occurredAt, before.occurredAt);
    expect(after.capturedAt, before.capturedAt);
    expect(after.timeSource, before.timeSource);
    expect(after.originalEffective, before.originalEffective);
  });

  test('striking twice is idempotent at the row level', () async {
    // guard() stops a double tap, and the schema stops the rest: the
    // paired-nullable CHECK makes a struck row with no time unrepresentable, so
    // a second strike can only ever rewrite the same two columns.
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId id = await repo.beginLambing(ewe);

    await repo.strikeLambing(id);
    await repo.strikeLambing(id);

    expect((await readLambing(db, id)).struck, isTrue);
    expect(await countLambings(db), 1);
  });

  test(
    'addLamb returns a LambId, throws on failure, and commits before the widget rebuilds',
    () async {
      // THE ANCHOR, ALL THREE CLAUSES.
      await _seedSeason(db);
      final EweId ewe = await seedEwe(db, tag: '412');
      final LambingId lambing = await repo.beginLambing(ewe);

      // RETURNS — the static type is Future<LambId>, asserted by USING the value
      // as one without a cast. A test that only checked `isA<LambId>()` would
      // pass against a dynamic.
      final LambId lamb = await repo.addLamb(lambing);
      final int raw = lamb.value;
      expect(raw, greaterThan(0));

      // COMMITS BEFORE THE REBUILD — read back with a second select on the same
      // database, BEFORE any pump, so the assertion is about the TRANSACTION and
      // not about the frame.
      final Lamb row = await (db.select(
        db.lambs,
      )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();
      expect(row.lambing, lambing.value);

      // THROWS — not a WriteFailed. R32 fixes the set of throwing verbs at
      // two, and this is one of them: there is no id to hand back on failure.
      //
      // MEASURED, AND IT IS A StateError RATHER THAN THE SqliteException THE
      // TASK PREDICTS. The task expects `foreign_keys = ON` (#28) to refuse the
      // insert. The verb never gets that far: it reads birth_dam FROM THE
      // LAMBING FIRST, inside the same transaction — which is the design the
      // task itself specifies — and `getSingle()` on a missing parent throws
      // before any insert is attempted.
      //
      // The earlier failure is the better one. It names the missing lambing
      // rather than a constraint on a column the caller never mentioned, and it
      // cannot be reached by a half-written row. `throwsA(anything)` would have
      // hidden which of the two fired, so the type is named.
      await expectLater(
        () => repo.addLamb(const LambingId(999999)),
        throwsA(isA<StateError>()),
        reason: 'the parent read fails before the foreign key can',
      );
    },
  );

  test('birth_dam is read from the lambing inside the same transaction', () async {
    // NOT REDUNDANCY. A lamb's birth dam never changes, while a FOSTER moves
    // the rearing dam — so reading the birth dam through the lambing would make
    // a foster look like a rewrite of history.
    //
    // THE DECOYS ARE LOAD-BEARING. With one ewe and one lambing both rows are
    // id 1, and `birthDam: lambing.value` — a real confusion between the two
    // ids, and the exact defect this case exists to catch — passes against it.
    // Drilled, and it did.
    //
    // THREE DECOY EWES AND ONE DECOY LAMBING, not two and two: seeding a
    // lambing per ewe keeps the two counters in LOCKSTEP, so ewe 3 still lambs
    // as lambing 3 and the decoys buy nothing. Drilled that too. The counts
    // have to differ, and the guard below is what says they did.
    await _seedSeason(db);
    for (final String decoy in <String>['001', '002', '003']) {
      final EweId other = await seedEwe(db, tag: decoy);
      if (decoy == '001') await repo.beginLambing(other);
    }
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await repo.beginLambing(ewe);
    expect(ewe.value, isNot(lambing.value), reason: 'the decoys must have worked');

    final LambId lamb = await repo.addLamb(lambing);
    final Lamb row = await (db.select(
      db.lambs,
    )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();

    expect(row.birthDam, ewe.value);
  });

  test('sex is absent unless given, and absent is not unknown', () async {
    // R45. Not recorded and recorded-as-unknown are different facts, and a verb
    // that defaulted would answer a question the shepherd did not.
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await repo.beginLambing(ewe);

    final LambId blank = await repo.addLamb(lambing);
    final LambId known = await repo.addLamb(lambing, sex: Sex.female);

    final List<Lamb> rows = await db.select(db.lambs).get();
    expect(rows.firstWhere((Lamb l) => l.id == blank.value).sex, isNull);
    expect(rows.firstWhere((Lamb l) => l.id == known.value).sex, 'f');
  });

  test('a lamb starts alive, and that default is the schema saying so', () async {
    // `status` has withDefault('alive') at the table. It is the one default in
    // the lamb row that encodes nothing veterinary: a lamb that was born is
    // alive until the shepherd says otherwise, and stillborn is a thing they
    // record rather than a thing the app guesses.
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await repo.beginLambing(ewe);

    final LambId lamb = await repo.addLamb(lambing);
    final Lamb row = await (db.select(
      db.lambs,
    )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();

    expect(row.status, 'alive');
    expect(row.birthWeightG, isNull, reason: 'a weight is recorded, never assumed');
    expect(row.tag, isNull, reason: 'a lamb is tagged later, in daylight');
  });

  test('each lamb gets its own uid, and the ids ascend in stroke order', () async {
    // Insertion order IS stroke order, and the uid is the identity that
    // survives export and re-import (#32). Two lambs sharing one uid would
    // collapse into a single row on restore.
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await repo.beginLambing(ewe);

    final List<LambId> added = <LambId>[for (int i = 0; i < 3; i++) await repo.addLamb(lambing)];

    expect(added[0].value, lessThan(added[1].value));
    expect(added[1].value, lessThan(added[2].value));

    final List<Lamb> rows = await db.select(db.lambs).get();
    expect(rows.map((Lamb l) => l.uid).toSet(), hasLength(3));
  });

  test('addCare copies the season from the parent and writes the provenance quad', () async {
    // TWO CLAIMS THAT ONLY A REPOSITORY TEST CAN MAKE.
    //
    // SEASON — `care_events.season` is NOT NULL, and it is read from the parent
    // INSIDE the transaction rather than handed in. Reading it from the screen's
    // copy is one frame stale, and getting it wrong scopes the row into the
    // wrong season's statistics forever.
    //
    // PROVENANCE — the quad is what §12.5 is made of. `auto` here is honest: the
    // shepherd pressed a line and the app read the clock.
    //
    // THE DECOY SEASON IS LOAD-BEARING. With one season every id is 1, and
    // `return const SeasonId(1)` — a verb that never walks to the parent at all
    // — passes. Drilled, and it did. A prior season pushes the real one to 2.
    await _seedDecoySeason(db);
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await repo.beginLambing(ewe);

    final WriteOutcome outcome = await repo.addCare(
      CareForLambing(lambing),
      kind: CareKind.colostrum,
    );
    expect(outcome, isA<WriteCommitted>());

    final CareEvent row = await db.select(db.careEvents).getSingle();
    final Lambing parent = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();

    expect(row.season, parent.season, reason: 'copied from the parent, not guessed');
    expect(row.timeSource, 'auto');
    expect(row.originalEffective, isNull);
    expect(row.occurredAt.epochMillis, row.capturedAt.epochMillis, reason: 'one instant');
    expect(row.uid, isNotEmpty, reason: 'export identity — #32');
  });

  test('a volume over the guard is a failure, never a correction', () async {
    // `volume_ml BETWEEN 1 AND 2000` IS A UNIT-SLIP GUARD AND NEVER A DOSE
    // (`03 §5.6`). 3000 trips the CHECK and comes back as a WriteFailed.
    //
    // THE THREE THINGS IT MUST NOT DO are each asserted, because each is §12.4
    // with a helpful face on: clamping to 2000, rounding, or silently dropping
    // the column would all leave a row on disk that the shepherd never entered.
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await repo.beginLambing(ewe);

    final WriteOutcome outcome = await repo.addCare(
      CareForLambing(lambing),
      kind: CareKind.colostrum,
      volumeMl: 3000,
    );

    expect(outcome, isA<WriteFailed>());
    expect(
      await db.select(db.careEvents).get(),
      isEmpty,
      reason: 'not clamped to 2000, not rounded, and not written without the column',
    );
  });

  test('a volume inside the guard is stored exactly as typed', () async {
    // THE OTHER ARM, and without it the case above passes against a verb that
    // rejects EVERY volume. A guard that refuses everything is not a guard.
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await repo.beginLambing(ewe);

    await repo.addCare(
      CareForLambing(lambing),
      kind: CareKind.colostrum,
      volumeMl: 250,
      method: ColostrumMethod.tube,
    );

    final CareEvent row = await db.select(db.careEvents).getSingle();
    expect(row.volumeMl, 250, reason: 'exactly as typed — no rounding, no clamping');
    expect(row.method, 'tube');
  });

  test('care against a lamb sets lamb and leaves lambing null, and the reverse', () async {
    // `CHECK ((lambing IS NOT NULL) + (lamb IS NOT NULL) = 1)` — EXACTLY one.
    // `CareSubject` is sealed so the two unstorable combinations, both set and
    // neither set, are UNCONSTRUCTIBLE rather than caught by the CHECK at 03:20.
    // This case is what proves the two arms actually differ.
    await _seedDecoySeason(db);
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await repo.beginLambing(ewe);
    final LambId lamb = await repo.addLamb(lambing);

    await repo.addCare(CareForLamb(lamb), kind: CareKind.navelDip);
    await repo.addCare(CareForLambing(lambing), kind: CareKind.warmed);

    final List<CareEvent> rows = await db.select(db.careEvents).get();
    final CareEvent forLamb = rows.firstWhere((CareEvent c) => c.kind == 'navel_dip');
    final CareEvent forLambing = rows.firstWhere((CareEvent c) => c.kind == 'warmed');

    expect(forLamb.lamb, lamb.value);
    expect(forLamb.lambing, isNull);
    expect(forLambing.lambing, lambing.value);
    expect(forLambing.lamb, isNull);

    // AND THE LAMB ARM STILL FOUND THE SEASON, two joins up. A verb that only
    // knew how to walk from a lambing would have written NULL here and tripped
    // NOT NULL — or worse, defaulted. The decoy above is what makes "found it"
    // distinguishable from "returned 1".
    expect(forLamb.season, forLambing.season);
    expect(forLamb.season, isNot(1), reason: 'walked to the parent, not assumed');
  });

  test('removeCare strikes the row and keeps its original time', () async {
    // P1 OVER `07 §15.1`. That document says the undo of this verb is "re-insert
    // with the original RecordedTime", which implies the row was deleted — and a
    // deleted row cannot render indelible.md §7.10's Undone state, which prints
    // the STRUCK done stamp beside the new one. `care_events` carries
    // `Struckable`, so the row survives.
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await repo.beginLambing(ewe);
    await repo.addCare(CareForLambing(lambing), kind: CareKind.warmed);

    final CareEvent before = await db.select(db.careEvents).getSingle();
    await repo.removeCare(CareEventId(before.id));

    final CareEvent after = await db.select(db.careEvents).getSingle();
    expect(after.struck, isTrue);
    expect(after.struckAt, isNotNull);
    expect(
      after.occurredAt.epochMillis,
      before.occurredAt.epochMillis,
      reason: 'the time it was pressed is not rewritten by unpressing it',
    );
    expect(after.timeSource, before.timeSource, reason: '§12.5 — undoing is not editing');
  });
}

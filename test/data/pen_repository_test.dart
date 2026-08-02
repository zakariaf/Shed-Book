// test/data/pen_repository_test.dart
//
// The pen board's write path. `pen_occupancies` landed at N07-T05 and nothing
// has written it since — so its partial unique index has never been exercised by
// anything, and this file is where that stops being true.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/failure.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/pen_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/penning.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import '../support/harness.dart';
import '../support/seeds.dart';

void main() {
  late AppDatabase db;
  late PenRepository repo;

  setUp(() async {
    db = testDatabase();
    repo = PenRepository(db);
    // A PEN HAS NO SEASON OF ITS OWN, but an occupancy does — and every write
    // verb reads the current season from settings. Nothing else in this file's
    // setup creates one.
    await seedSeason(db);
  });

  test('the partial unique index refuses a second open occupancy for pen 3', () async {
    // THE ANCHOR, AND IT IS SHARPENED UNTIL A DART GUARD CANNOT PASS IT.
    //
    // A case that only asserted `WriteFailed` would be green against an `if
    // (alreadyOccupied) return WriteFailed(...)` in the repository — which is
    // the implementation this task exists to forbid, because a Dart guard is
    // absent from `RestoreService`, absent from a future import path, and absent
    // from anything written by somebody who has not read this file.
    //
    // So the assertion names the MECHANISM: extended result code 2067, which is
    // SQLITE_CONSTRAINT_UNIQUE, plus the table and column SQLite reports.
    //
    // MEASURED: SQLite does NOT name the index in the message — it names the
    // indexed column, `pen_occupancies.pen`. The task's own wording expects
    // `idx_penocc_one_open` and that string never appears. Asserting on what the
    // engine actually says is the point: a Dart guard produces neither the code
    // nor the column, so the claim holds and the wording is corrected rather
    // than the assertion loosened.
    final PenId pen = await seedPen(db, label: '3');
    final EweId first = await seedEwe(db, tag: '412');
    final EweId second = await seedEwe(db, tag: '077');

    expect(await repo.enterPen(pen, ewe: first), isA<WriteCommitted>());

    final WriteOutcome refused = await repo.enterPen(pen, ewe: second);
    expect(refused, isA<WriteFailed>());

    final ShedFailure failure = (refused as WriteFailed).failure;
    expect(failure, isA<UnexpectedFailure>(), reason: 'a constraint is a bug, not a storage state');

    final Object cause = (failure as UnexpectedFailure).error;
    expect(cause, isA<SqliteException>());
    // 2067 is SQLITE_CONSTRAINT_UNIQUE. A Dart guard produces neither this code
    // nor the column name below.
    expect((cause as SqliteException).extendedResultCode, 2067);
    expect(cause.toString(), contains('UNIQUE constraint failed'));
    expect(cause.toString(), contains('pen_occupancies.pen'));

    // AND IT REFUSES A SECOND **OPEN** ROW, NEVER A SECOND ROW. Close the first
    // and the pen is free again — which is the whole point of a PARTIAL index,
    // and the half a full unique index would get wrong.
    final PenOccupancy? open = await repo.openOccupancyFor(pen);
    expect(open, isNotNull);
    expect(
      await repo.exitPen(PenOccupancyId(open!.id), reason: PenExitReason.turnedOut),
      isA<WriteCommitted>(),
    );

    expect(await repo.enterPen(pen, ewe: second), isA<WriteCommitted>());
    expect(await db.select(db.penOccupancies).get(), hasLength(2), reason: 'two rows, one open');
  });

  test('exitPen is idempotent once closed', () async {
    // `02 §7.1` RULE 1, AND IT IS THE DOUBLE-TAP DEFENCE AT THE LAYER THAT CAN
    // HOLD IT. `guard()` prevents CONCURRENCY, not REPETITION — two deliberate
    // taps two seconds apart both reach the verb, and the second must not
    // rewrite `exited_at` to a later time. A pen that closed at 06:10 did not
    // close again at 06:12 because a thumb slipped.
    final PenId pen = await seedPen(db, label: '3');
    final EweId ewe = await seedEwe(db, tag: '412');

    await repo.enterPen(pen, ewe: ewe);
    final PenOccupancy open = (await repo.openOccupancyFor(pen))!;

    await repo.exitPen(PenOccupancyId(open.id), reason: PenExitReason.turnedOut);
    final PenOccupancy closed = await (db.select(
      db.penOccupancies,
    )..where(($PenOccupanciesTable t) => t.id.equals(open.id))).getSingle();

    final WriteOutcome again = await repo.exitPen(
      PenOccupancyId(open.id),
      // A DIFFERENT REASON, deliberately: if the second call wrote anything at
      // all, this is the value that would prove it.
      reason: PenExitReason.died,
    );
    expect(again, isA<WriteCommitted>());

    final PenOccupancy after = await (db.select(
      db.penOccupancies,
    )..where(($PenOccupanciesTable t) => t.id.equals(open.id))).getSingle();

    expect(after.exitedAt, closed.exitedAt, reason: 'the time it closed does not move');
    expect(after.exitReason, closed.exitReason, reason: 'nor does the reason');
  });

  test('the half-written closed form is unstorable', () async {
    // `CHECK ((exited_at IS NULL) = (exit_reason IS NULL))` — an EQUALITY, so
    // both halves are impossible on their own. This is why `exitPen` takes a
    // required reason rather than an optional one: the type makes the call
    // impossible to get wrong, and the CHECK makes the row impossible to store.
    final PenId pen = await seedPen(db, label: '3');
    final EweId ewe = await seedEwe(db, tag: '412');
    await repo.enterPen(pen, ewe: ewe);
    final PenOccupancy open = (await repo.openOccupancyFor(pen))!;

    for (final String statement in <String>[
      'UPDATE pen_occupancies SET exited_at = 1772335200000 WHERE id = ?',
      "UPDATE pen_occupancies SET exit_reason = 'turned_out' WHERE id = ?",
    ]) {
      await expectLater(
        () => db.customStatement(statement, <Object?>[open.id]),
        throwsA(isA<SqliteException>()),
        reason: statement,
      );
    }
  });

  test('a pen may hold lambs with no ewe', () async {
    // AN ORPHAN PEN. `03 §5.9` declares the ewe column nullable for exactly
    // this, and it is not a rare case: a ewe that dies leaves lambs that still
    // need penning, and at 03:20 that is the pen the shepherd is standing at.
    final PenId pen = await seedPen(db, label: '3');
    final EweId dam = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, dam);
    final LambId a = await seedLamb(db, lambing, dam);
    final LambId b = await seedLamb(db, lambing, dam);

    expect(await repo.enterPen(pen, lambs: <LambId>[a, b]), isA<WriteCommitted>());

    final PenOccupancy open = (await repo.openOccupancyFor(pen))!;
    expect(open.ewe, isNull);

    final List<PenOccupancyLamb> penned = await db.select(db.penOccupancyLambs).get();
    expect(penned.map((PenOccupancyLamb l) => l.lamb).toSet(), <int>{a.value, b.value});
  });

  test('openOccupancyFor returns null once the pen is empty', () async {
    // The read the board is built on. `null` is *the pen is free*, which is a
    // real answer and the commonest one before lambing starts.
    final PenId pen = await seedPen(db, label: '3');
    final EweId ewe = await seedEwe(db, tag: '412');

    expect(await repo.openOccupancyFor(pen), isNull, reason: 'free before anything happens');

    await repo.enterPen(pen, ewe: ewe);
    expect(await repo.openOccupancyFor(pen), isNotNull);

    final PenOccupancy open = (await repo.openOccupancyFor(pen))!;
    await repo.exitPen(PenOccupancyId(open.id), reason: PenExitReason.moved);
    expect(await repo.openOccupancyFor(pen), isNull, reason: 'free again');
  });
}

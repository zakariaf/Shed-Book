// test/data/durability_test.dart — `12 §3.5`.
//
// THE ONE PROMISE THE PRODUCT MAKES ABOUT POWER LOSS: *"Assume the phone dies.
// Every write is committed immediately. There is no draft state to lose."*
//
// Every other test in this project runs against `NativeDatabase.memory()`, which
// CANNOT falsify that sentence — an in-memory database has no file to survive
// into, so a repository that never committed at all would pass all of them. This
// file is the only one that opens a database ON DISK, closes it, and opens it
// again, which is as close to a flat battery as a unit test gets.
//
// It is deliberately small. One case per write path, no rendering, no providers.
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/connection.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/sex.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

/// A database backed by a real file in a temp directory that dies with the test.
///
/// **Not in `harness.dart`.** `12 §5` is explicit that the harness has one way
/// to get a database, and a second entry point is how two tests end up
/// disagreeing about what a fresh database means. This one is local because
/// exactly one file wants it: everything else is in-memory ON PURPOSE, since a
/// file-backed database is slower and, more importantly, would let a test leave
/// state behind for the next.
///
/// `synchronous = FULL` — the setting that makes the sentence above true rather
/// than probable — arrives through [configureConnection], the same function the
/// app opens with. Passing a different setup here would test a database the
/// shepherd never runs.
AppDatabase _diskDatabase(File file, {bool seedOnCreate = true}) {
  final AppDatabase db = AppDatabase(
    DatabaseConnection(
      NativeDatabase(file, setup: configureConnection),
      closeStreamsSynchronously: true,
    ),
    seedOnCreate: seedOnCreate,
  );
  addTearDown(db.close);
  return db;
}

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
  test('a lambing and its lambs survive a close and a cold reopen', () async {
    // THE ANCHOR. Two databases, one file, no overlap in their lifetimes.
    //
    // THE `db.close()` IS THE POINT, and it is also the weakness: a close
    // FLUSHES, so a test that only closes cleanly proves less than a power cut
    // does. What it does prove is that the rows were in the file and not in a
    // transaction still waiting for a `save()` that never comes — which is the
    // failure this project's write path is shaped to make impossible, and the
    // one a reviewer can actually check. A true power-cut case needs a killed
    // process and belongs to the release runbook, not to `flutter test`.
    final Directory dir = freshSupportDir();
    final File file = File('${dir.path}/shed_book.sqlite');

    final int lambingId;
    final List<int> lambIds;

    // ---- the shed: three strokes at 03:20 ---------------------------------
    {
      final AppDatabase db = _diskDatabase(file);
      final LambingRepository repo = LambingRepository(db: db);
      await _seedSeason(db);
      final EweId ewe = await seedEwe(db, tag: '412');

      final LambingId lambing = await repo.beginLambing(ewe);
      lambingId = lambing.value;
      lambIds = <int>[
        (await repo.addLamb(lambing, sex: Sex.female)).value,
        (await repo.addLamb(lambing, sex: Sex.male)).value,
        (await repo.addLamb(lambing)).value,
      ];

      await db.close();
    }

    expect(file.existsSync(), isTrue, reason: 'there is a file to reopen');
    expect(file.lengthSync(), greaterThan(0));

    // ---- the kitchen table, next morning ----------------------------------
    {
      // `seedOnCreate: false` — the second open is a REOPEN, and saying so is
      // what makes this test the shape of the real second launch.
      //
      // DRILLED, AND PASSING `true` HERE CHANGES NOTHING: the seed hangs off
      // drift's `onCreate`, which does not fire on a database that already has
      // a schema. So this flag is documentation rather than a guard, and the
      // claim that it PREVENTS a re-seed would have been false. What actually
      // holds that line is `onCreate` itself; if the seed ever moves to
      // `beforeOpen`, this argument starts mattering and this comment is wrong.
      final AppDatabase db = _diskDatabase(file, seedOnCreate: false);

      final Lambing lambing = await (db.select(
        db.lambings,
      )..where(($LambingsTable t) => t.id.equals(lambingId))).getSingle();
      expect(lambing.id, lambingId);

      final List<Lamb> lambs =
          await (db.select(db.lambs)
                ..where(($LambsTable t) => t.lambing.equals(lambingId))
                ..orderBy(<OrderClauseGenerator<$LambsTable>>[
                  ($LambsTable t) => OrderingTerm(expression: t.id),
                ]))
              .get();

      expect(lambs.map((Lamb l) => l.id), lambIds, reason: 'all three, in stroke order');

      // THE SEX COLUMN ACROSS THE REOPEN, because it is the one field here that
      // can be absent, and absent-versus-unknown (R45) is the distinction most
      // likely to be quietly lost by a round trip through a file.
      expect(lambs[0].sex, 'f');
      expect(lambs[1].sex, 'm');
      expect(lambs[2].sex, isNull, reason: 'not recorded, and still not recorded');

      // The uids are the export identity (#32). Two lambs sharing one would
      // collapse into a single row on restore, and a reopen is the cheapest
      // place to notice a uid that was never written.
      expect(lambs.map((Lamb l) => l.uid).toSet(), hasLength(3));
      expect(lambs.every((Lamb l) => l.uid.isNotEmpty), isTrue);
    }
  });

  test('the provenance quad survives the reopen intact', () async {
    // §12.5 is UNREPRESENTABLE in memory and merely four columns on disk. If a
    // reopen lost `time_source`, `RecordedTime` would rebuild as something the
    // shepherd never did — which is the exact failure §12.5 exists to prevent,
    // and it would be invisible to every in-memory test in the project.
    final Directory dir = freshSupportDir();
    final File file = File('${dir.path}/shed_book.sqlite');

    final int lambingId;
    final String sourceBefore;
    final int occurredBefore;

    {
      final AppDatabase db = _diskDatabase(file);
      final LambingRepository repo = LambingRepository(db: db);
      await _seedSeason(db);
      final EweId ewe = await seedEwe(db, tag: '412');

      final LambingId lambing = await repo.beginLambing(ewe);
      lambingId = lambing.value;

      final Lambing row = await (db.select(
        db.lambings,
      )..where(($LambingsTable t) => t.id.equals(lambingId))).getSingle();
      sourceBefore = row.timeSource;
      occurredBefore = row.occurredAt.epochMillis;

      await db.close();
    }

    {
      final AppDatabase db = _diskDatabase(file, seedOnCreate: false);
      final Lambing row = await (db.select(
        db.lambings,
      )..where(($LambingsTable t) => t.id.equals(lambingId))).getSingle();

      expect(row.timeSource, sourceBefore);
      expect(row.occurredAt.epochMillis, occurredBefore, reason: 'to the millisecond');
      expect(
        row.originalEffective,
        isNull,
        reason: 'nothing was edited, so there is no original to keep',
      );
    }
  });
}

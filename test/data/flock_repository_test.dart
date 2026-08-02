// test/data/flock_repository_test.dart
//
// The deck statement, against a real in-memory SQLite. The properties here are
// about SQL and about list IDENTITY, and neither is observable from a mock.
library;

import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

/// A real instant, because every timestamp column carries
/// `CHECK (… BETWEEN 946684800000 AND 4102444800000)` — the year-2000-to-2100
/// window. A test that reaches for `_at(0)` fails on the constraint, not
/// on its claim, and that is the schema doing its job.
Instant _at(int minutes) =>
    Instant.fromDateTime(DateTime.utc(2026, 3, 1, 3, 20)).plus(Duration(minutes: minutes));

/// Counts the DISTINCT SQL strings the deck prepares.
class _StatementRecorder extends QueryInterceptor {
  final List<String> selects = <String>[];

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    selects.add(statement);
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  late AppDatabase db;
  late FlockRepository repo;

  setUp(() {
    db = testDatabase();
    repo = FlockRepository(db);
  });

  test('the deck is one statement and it is a UNION ALL', () async {
    // FIRST HALF OF THE ANCHOR. One statement, because two would be two streams,
    // and two streams updated in one transaction can emit at different times.
    final _StatementRecorder rec = _StatementRecorder();
    final AppDatabase counted = AppDatabase(
      testConnection().interceptWith(rec),
      seedOnCreate: true,
    );
    addTearDown(counted.close);

    final PenId pen = await seedPen(counted, label: 'A');
    final EweId ewe = await seedEwe(counted, tag: '412');
    await seedPenOccupancy(counted, pen, ewe);
    await seedTouch(counted, ewe);

    rec.selects.clear();
    final QuickEntryDeck deck = await FlockRepository(counted).watchQuickEntryDeck().first;

    final Set<String> deckStatements = rec.selects
        .where((String s) => s.contains('UNION ALL'))
        .toSet();
    expect(deckStatements, hasLength(1), reason: 'one statement, two buckets');
    expect(deck.penned, hasLength(1));
    expect(deck.recents, hasLength(1));
  });

  test('a recents change hands back the SAME penned list instance', () async {
    // SECOND HALF OF THE ANCHOR, AND IT IS THE ONE THAT FAILS FOR A SUBTLE
    // REASON. Identity is what `.select` compares: a fresh list that is EQUAL to
    // the old one still rebuilds the strip, because List's `==` is identity. So
    // the assertion is `same`, not `equals` — with `equals` this case passes
    // against the naive implementation and proves nothing.
    final PenId pen = await seedPen(db, label: 'A');
    final EweId penned = await seedEwe(db, tag: '412');
    final EweId other = await seedEwe(db, tag: '128');
    await seedPenOccupancy(db, pen, penned);
    await seedTouch(db, penned, touchedAt: _at(0));

    final Stream<QuickEntryDeck> stream = repo.watchQuickEntryDeck();
    final List<QuickEntryDeck> seen = <QuickEntryDeck>[];
    final StreamSubscription<QuickEntryDeck> sub = stream.listen(seen.add);
    addTearDown(sub.cancel);

    await pumpEventQueue();
    expect(seen, hasLength(1));

    // ONE write, to the recents bucket only.
    await seedTouch(db, other, touchedAt: _at(10));
    await pumpEventQueue();

    expect(seen.length, greaterThan(1), reason: 'the recents bucket did change');
    expect(
      seen.last.penned,
      same(seen.first.penned),
      reason:
          'the penned bucket did not change, so the strip must not rebuild — '
          'a fresh equal list still rebuilds it, because List == is identity',
    );
    expect(seen.last.recents, isNot(same(seen.first.recents)));
  });

  test('a penned change hands back the SAME recents list instance', () async {
    // The mirror case. Both directions, because a mechanism that only works one
    // way is a coincidence.
    final PenId pen = await seedPen(db, label: 'A');
    final EweId a = await seedEwe(db, tag: '412');
    final EweId b = await seedEwe(db, tag: '128');
    await seedTouch(db, a, touchedAt: _at(0));

    final List<QuickEntryDeck> seen = <QuickEntryDeck>[];
    final StreamSubscription<QuickEntryDeck> sub = repo.watchQuickEntryDeck().listen(seen.add);
    addTearDown(sub.cancel);

    await pumpEventQueue();
    expect(seen, hasLength(1));

    await seedPenOccupancy(db, pen, b);
    await pumpEventQueue();

    expect(seen.length, greaterThan(1));
    expect(seen.last.recents, same(seen.first.recents));
    expect(seen.last.penned, isNot(same(seen.first.penned)));
  });

  test('the penned bucket is longest-penned first and carries the pen label', () async {
    // "The one you are standing next to" — ORDER BY entered_at ASC. A pen board
    // sorted the other way puts the ewe who has just gone in at the top, which is
    // the one the shepherd is least likely to be looking at.
    final PenId one = await seedPen(db, label: 'A');
    final PenId two = await seedPen(db, label: 'B');
    final EweId early = await seedEwe(db, tag: '412');
    final EweId late = await seedEwe(db, tag: '128');

    await seedPenOccupancy(db, one, early, enteredAt: _at(0));
    await seedPenOccupancy(db, two, late, enteredAt: _at(10));

    final QuickEntryDeck deck = await repo.watchQuickEntryDeck().first;
    expect(deck.penned.map((DeckEntry e) => e.tag), <String>['412', '128']);
    expect(deck.penned.first.penLabel, 'A');
    expect(deck.penned.last.penLabel, 'B');
  });

  test('a turned-out ewe leaves the penned bucket', () async {
    final PenId pen = await seedPen(db, label: 'A');
    final EweId ewe = await seedEwe(db, tag: '412');
    final PenOccupancyId occ = await seedPenOccupancy(db, pen, ewe, enteredAt: _at(0));

    expect((await repo.watchQuickEntryDeck().first).penned, hasLength(1));

    await (db.update(
      db.penOccupancies,
    )..where(($PenOccupanciesTable t) => t.id.equals(occ.value))).write(
      PenOccupanciesCompanion(
        exitedAt: Value<Instant?>(_at(60)),
        // PAIRED-NULLABLE: `CHECK ((exited_at IS NULL) = (exit_reason IS
        // NULL))`. The schema will not let a ewe leave a pen for no stated
        // reason, which is the same idiom §12.1 uses for a withdrawal.
        exitReason: const Value<String?>('turned_out'),
      ),
    );

    expect((await repo.watchQuickEntryDeck().first).penned, isEmpty);
  });

  test('the recents bucket is newest first and holds active animals only', () async {
    final EweId older = await seedEwe(db, tag: '412');
    final EweId newer = await seedEwe(db, tag: '128');
    final EweId culled = await seedEwe(db, tag: '999');

    await seedTouch(db, older, touchedAt: _at(0));
    await seedTouch(db, newer, touchedAt: _at(10));
    await seedTouch(db, culled, touchedAt: _at(20));

    await (db.update(db.ewes)..where(($EwesTable t) => t.id.equals(culled.value))).write(
      const EwesCompanion(status: Value<String>('culled')),
    );

    final QuickEntryDeck deck = await repo.watchQuickEntryDeck().first;
    expect(deck.recents.map((DeckEntry e) => e.tag), <String>['128', '412']);
  });

  test('each bucket caps at six independently', () async {
    // THE CTE'S WHOLE REASON. SQLite accepts ORDER BY/LIMIT only on the final arm
    // of a compound SELECT, so writing the limits inline gives six rows TOTAL —
    // and the penned strip silently empties on a busy night, which is the night
    // it matters.
    // EIGHT PENS, NOT ONE, and the schema is why: `idx_penocc_one_open` is a
    // partial unique index on `pen` where `exited_at IS NULL`, so a pen holds one
    // open occupancy at a time. A test that put eight ewes in pen A would fail on
    // that constraint rather than on the limit it is asserting.
    for (int i = 0; i < 8; i++) {
      final PenId pen = await seedPen(db, label: 'PEN$i');
      final EweId e = await seedEwe(db, tag: '10$i');
      await seedPenOccupancy(db, pen, e, enteredAt: _at(i));
      await seedTouch(db, e, touchedAt: _at(100 + i));
    }

    final QuickEntryDeck deck = await repo.watchQuickEntryDeck().first;
    expect(deck.penned, hasLength(6));
    expect(deck.recents, hasLength(6));
  });

  test('a pen holding lambs and no ewe contributes nothing', () async {
    // pen_occupancies.ewe is nullable because a pen can hold lambs with no ewe,
    // and decision #67 says the strip is ewes only. The JOIN would drop the row
    // anyway — the predicate is what makes that on purpose rather than by
    // accident.
    final PenId ewePen = await seedPen(db, label: 'A');
    final EweId ewe = await seedEwe(db, tag: '412');

    // One real occupancy, which also creates the season the lamb-only row needs.
    await seedPenOccupancy(db, ewePen, ewe, enteredAt: _at(0));
    final int season = (await db.select(db.seasons).get()).single.id;

    // ITS OWN PEN: `idx_penocc_one_open` is a partial unique index on `pen` where
    // `exited_at IS NULL`, so a pen holds one open occupancy at a time.
    final PenId lambPen = await seedPen(db, label: 'LAMBS');
    final Instant at = _at(5);
    await db
        .into(db.penOccupancies)
        .insert(
          PenOccupanciesCompanion.insert(
            pen: lambPen.value,
            season: season,
            // No `ewe`. This is the row decision #67 says the strip skips.
            enteredAt: at,
            capturedAt: at,
            uid: 'lamb-only-occupancy-uid-000000000000',
            createdAt: at,
            updatedAt: at,
          ),
        );

    final QuickEntryDeck deck = await repo.watchQuickEntryDeck().first;
    expect(deck.penned.map((DeckEntry e) => e.tag), <String>['412']);
  });
}

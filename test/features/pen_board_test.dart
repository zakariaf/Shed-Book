// test/features/pen_board_test.dart
//
// The pen board reads the same occupancy the Quick Entry strip does, and this
// file is where "the same" stops being a claim.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/data/pen_repository.dart';
import 'package:shed_book/domain/penning.dart';
import 'package:shed_book/domain/ids.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

void main() {
  test('the board and the Quick Entry strip project the same occupancy set', () async {
    // THE ANCHOR, AND FOUR THINGS ARE SEEDED SO IT CANNOT PASS BY COINCIDENCE:
    // two occupied pens with ewes, one EMPTY pen, and one ORPHAN occupancy
    // holding lambs with no ewe.
    //
    // Those last two are what make it a real test. A naive length comparison
    // fails on them, and the two projections are required to DISAGREE about
    // them in a specific way: the board shows both, and the strip shows neither,
    // because decision #67 makes the strip ewes-only.
    //
    // So the assertion is about the EWE set — the part they must agree on —
    // plus two explicit claims about the part they must not.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final PenRepository repo = PenRepository(db);

    final EweId a = await seedEwe(db, tag: '412');
    final EweId b = await seedEwe(db, tag: '077');
    final EweId orphanDam = await seedEwe(db, tag: '900');

    final PenId penA = await seedPen(db, label: '1');
    final PenId penB = await seedPen(db, label: '2');
    final PenId penEmpty = await seedPen(db, label: '3');
    final PenId penOrphan = await seedPen(db, label: '4');

    await repo.enterPen(penA, ewe: a);
    await repo.enterPen(penB, ewe: b);

    final LambingId lambing = await seedLambing(db, orphanDam);
    final LambId orphan = await seedLamb(db, lambing, orphanDam);
    await repo.enterPen(penOrphan, lambs: <LambId>[orphan]);

    final List<PenBoardRow> board = await repo.watchBoard().first;

    // THE BOARD DRAWS THE SHED, so every active pen is a tile — including the
    // empty one, which is the pen the shepherd is about to use.
    expect(board, hasLength(4), reason: 'four pens, four tiles');
    expect(board.map((PenBoardRow r) => r.pen).toSet(), <PenId>{penA, penB, penEmpty, penOrphan});

    // THE TWO PROJECTIONS AGREE ON THE EWES.
    final Set<String> boardEwes = board
        .map((PenBoardRow r) => r.eweTag)
        .whereType<String>()
        .toSet();
    // THE STRIP'S OWN PROJECTION, read through the repository Quick Entry
    // reads — not re-derived here. Re-deriving it would compare this file's
    // idea of the strip against the board, which proves nothing about the app.
    final QuickEntryDeck deck = await FlockRepository(
      db: db,
      policy: const FreeTierPolicy(),
    ).watchQuickEntryDeck().first;
    final Set<String> stripEwes = deck.penned.map((DeckEntry e) => e.tag).toSet();

    expect(boardEwes, stripEwes, reason: 'one occupancy, two readers, one answer');
    expect(boardEwes, <String>{'412', '077'});

    // AND THEY DISAGREE EXACTLY WHERE THEY SHOULD.
    final PenBoardRow empty = board.firstWhere((PenBoardRow r) => r.pen == penEmpty);
    expect(empty.occupancy, isNull, reason: 'an empty pen is a tile with no occupancy');
    expect(empty.eweTag, isNull);

    final PenBoardRow orphanTile = board.firstWhere((PenBoardRow r) => r.pen == penOrphan);
    expect(orphanTile.occupancy, isNotNull, reason: 'an ORPHAN pen is occupied');
    expect(
      orphanTile.eweTag,
      isNull,
      reason: 'and has no ewe — which is a different tile from an empty pen',
    );
    expect(orphanTile.lambCount, 1, reason: 'the lambs are what is in it');

    // The strip shows neither, because decision #67 makes it ewes-only.
    expect(stripEwes, isNot(contains('900')));
  });

  test('a pen empties and fills again, and the board follows', () async {
    // THE PARTIAL INDEX FROM THE BOARD'S SIDE. A tile that kept the old ewe
    // after turn-out is the failure a shepherd notices at 06:00 and cannot
    // explain, and it is exactly what a stale `readsFrom:` produces.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final PenRepository repo = PenRepository(db);

    final PenId pen = await seedPen(db, label: '1');
    final EweId first = await seedEwe(db, tag: '412');
    final EweId second = await seedEwe(db, tag: '077');

    await repo.enterPen(pen, ewe: first);
    expect((await repo.watchBoard().first).single.eweTag, '412');

    final PenOccupancy open = (await repo.openOccupancyFor(pen))!;
    await repo.exitPen(PenOccupancyId(open.id), reason: PenExitReason.turnedOut);
    expect(
      (await repo.watchBoard().first).single.eweTag,
      isNull,
      reason: 'turned out, so the tile is empty again',
    );

    await repo.enterPen(pen, ewe: second);
    expect((await repo.watchBoard().first).single.eweTag, '077');
  });

  test('a struck or inactive pen is not on the board', () async {
    // The board is the shed as it is TODAY. A pen taken out of service is not a
    // tile, and a struck one is not either — but neither is deleted, because
    // nothing in this app deletes: last season's occupancies still reference it.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final PenRepository repo = PenRepository(db);

    final PenId live = await seedPen(db, label: '1');
    final PenId retired = await seedPen(db, label: '2');

    await (db.update(db.pens)..where(($PensTable t) => t.id.equals(retired.value))).write(
      const PensCompanion(isActive: Value<bool>(false)),
    );

    final List<PenBoardRow> board = await repo.watchBoard().first;
    expect(board.map((PenBoardRow r) => r.pen).toSet(), <PenId>{live});
  });

  test('the next pen label is the smallest unused number, not MAX + 1', () async {
    // `MAX(label) + 1` IS WRONG TWICE OVER, and both halves are here. `label` is
    // TEXT, so `'10' < '9'` and a tenth pen would be numbered 10 forever; and a
    // renamed pen makes the cast meaningless.
    //
    // GAP-FILLING IS THE POINT, not a side effect: a shed whose pens run 1..12
    // stays 1..12 rather than drifting to 1..40 over three seasons — and the
    // number on the tile is the number chalked on the hurdle.
    expect(nextPenLabel(const <String>[]), '1', reason: 'the first pen');
    expect(nextPenLabel(const <String>['1', '2', '3']), '4');
    expect(nextPenLabel(const <String>['1', '3']), '2', reason: 'the gap is filled');

    // THE TEXT-SORT TRAP, stated directly.
    expect(
      nextPenLabel(const <String>['1', '2', '3', '4', '5', '6', '7', '8', '9']),
      '10',
      reason: "MAX over TEXT would answer '9' here forever",
    );

    // A RENAMED PEN IS IGNORED, not skipped over. It holds its own string in the
    // unique index and nothing else; it does not push the numbering along.
    expect(nextPenLabel(const <String>['Shed A', 'Back pen']), '1');
    expect(nextPenLabel(const <String>['1', 'Shed A', '3']), '2');

    // AND SO ARE NON-POSITIVE NUMBERS, which cannot be a pen.
    expect(nextPenLabel(const <String>['0', '-1']), '1');
  });

  test('a deactivated pen still owns its label', () async {
    // `03 §5.9` DECLARES `uniqueKeys => [{label}]` WITH NO PARTIAL PREDICATE —
    // unlike the tag index, which IS partial. So a pen deactivated last season
    // still owns its string, and choosing the next label from the ACTIVE pens
    // makes the first `addPen` after a deactivation fail with a UNIQUE violation
    // the UI has no honest message for.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final PenRepository repo = PenRepository(db);

    await repo.addPen();
    await repo.addPen();

    final Pen second = (await db.select(db.pens).get()).last;
    await (db.update(db.pens)..where(($PensTable t) => t.id.equals(second.id))).write(
      const PensCompanion(isActive: Value<bool>(false)),
    );

    // The BOARD shows one pen; the LABELS still count two.
    expect(await repo.watchBoard().first, hasLength(1));
    expect(await repo.addPen(), isA<WriteCommitted>(), reason: 'and it does not collide');

    final List<String> labels = (await db.select(db.pens).get()).map((Pen p) => p.label).toList();
    expect(labels, <String>['1', '2', '3']);
  });

  test('addPen is one tap and needs no name', () async {
    // The shepherd is standing in front of a pen at 03:20. Asking what to call
    // it is asking for a decision they do not have and do not want — so the
    // number is chosen for them and renaming happens in daylight.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final PenRepository repo = PenRepository(db);

    expect(await repo.watchBoard().first, isEmpty, reason: 'a flock starts with no pens');

    expect(await repo.addPen(), isA<WriteCommitted>());

    final List<PenBoardRow> board = await repo.watchBoard().first;
    expect(board, hasLength(1));
    expect(board.single.label, '1');
    expect(board.single.occupancy, isNull, reason: 'created empty, ready to use');
  });
}

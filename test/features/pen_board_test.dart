// test/features/pen_board_test.dart
//
// The pen board reads the same occupancy the Quick Entry strip does, and this
// file is where "the same" stops being a claim.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:shed_book/core/db/database.dart';
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
}

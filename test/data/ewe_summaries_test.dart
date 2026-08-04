// test/data/ewe_summaries_test.dart
//
// **THE COUNTS ARE MAINTAINED BY THE WRITES THAT CHANGE THEM, INSIDE THEIR OWN
// TRANSACTIONS.** Not on a timer, not on launch, not by a second transaction —
// because the premise of this whole write path is *"assume the phone dies"*, and
// a window in which the lambing exists and the summary does not is a card that
// is wrong forever with no error anywhere.
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/lambing_ease.dart';
import 'package:shed_book/domain/sex.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

Future<EweSummary?> _summary(AppDatabase db, EweId ewe) => (db.select(
  db.eweSummaries,
)..where(($EweSummariesTable t) => t.ewe.equals(ewe.value))).getSingleOrNull();

void main() {
  test('a new lambing updates ewe_summaries inside the same transaction', () async {
    // **THE ANCHOR, AND IT IS TWO HALVES.** The counts move — and a failure
    // inside the transaction leaves NEITHER row. A summary maintained by a
    // second transaction passes half one and fails half two, and half two is the
    // one that matters.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingRepository repo = LambingRepository(db: db);

    expect(await _summary(db, ewe), isNull, reason: 'nothing has been recorded about her yet');

    await repo.beginLambing(ewe);

    final EweSummary? after = await _summary(db, ewe);
    expect(after, isNotNull);
    expect(after!.lambingsRecorded, 1);
    expect(after.seasonsRecorded, 1);
    expect(after.lambsBorn, 0, reason: 'the row exists before any lamb is attached — #11');

    // **HALF TWO: THE TRANSACTION IS ONE UNIT.** A write that throws part-way
    // leaves nothing behind, which is only true if the summary is written inside
    // it. Forced by asking the database to violate a foreign key from within the
    // same transaction the lambing is written in.
    Object? thrown;
    try {
      await db.transaction(() async {
        await repo.beginLambing(ewe);
        // A season that does not exist. `defer_foreign_keys` is off here, so
        // this fails immediately and takes the enclosing transaction with it.
        await db
            .into(db.lambings)
            .insert(
              LambingsCompanion.insert(
                uid: 'x',
                createdAt: appNow(),
                updatedAt: appNow(),
                ewe: ewe.value,
                season: 999999,
                occurredAt: appNow(),
                capturedAt: appNow(),
                localDate: LocalDate.of(after.rebuiltAt),
              ),
            );
      });
    } on Object catch (e) {
      thrown = e;
    }

    expect(thrown, isNotNull, reason: 'the foreign key must have refused the second insert');
    expect(
      (await _summary(db, ewe))!.lambingsRecorded,
      1,
      reason: 'the aborted transaction left neither the lambing nor a moved count',
    );
    expect((await db.select(db.lambings).get()), hasLength(1));

    await db.close();
  });

  test('lambs_born and lambs_born_alive move together, and stillborn is its own bucket', () async {
    // **THE PREDICATE PEOPLE WRITE FIRST IS `= 'alive'`, AND IT IS WRONG TWICE.**
    // It loses every lamb born alive that later died, and every lamb sold. The
    // opposite reflex, `<> 'alive'`, counts a sold lamb as never born alive.
    // `CONVENTIONS §5.1`: stillborn is its own bucket, never folded into day-0
    // deaths — so the only correct predicate is `<> 'stillborn'`.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingRepository repo = LambingRepository(db: db);

    final LambingId lambing = await repo.beginLambing(ewe);
    await repo.addLamb(lambing, sex: Sex.female);
    await repo.addLamb(lambing, sex: Sex.male);
    await repo.addLamb(lambing);
    await repo.addLamb(lambing);

    // One stillborn, one dead at day three, one sold, one alive.
    final List<Lamb> lambs = await db.select(db.lambs).get();
    for (final ({int i, String status}) row in <({int i, String status})>[
      (i: 0, status: 'stillborn'),
      (i: 1, status: 'dead'),
      (i: 2, status: 'sold'),
      (i: 3, status: 'alive'),
    ]) {
      await (db.update(db.lambs)..where(($LambsTable t) => t.id.equals(lambs[row.i].id))).write(
        LambsCompanion(status: Value<String>(row.status)),
      );
    }
    // A recompute, because the statuses were set outside a write verb.
    await writeEweSummary(db, ewe, appNow());

    final EweSummary s = (await _summary(db, ewe))!;
    expect(s.lambsBorn, 4, reason: 'every lamb she bore, whatever became of him');
    expect(s.lambsBornAlive, 3, reason: 'the stillborn one and only the stillborn one is excluded');

    await db.close();
  });

  test('an unscored lambing raises lambings_recorded and not scored_lambings', () async {
    // Decision #59, and the input T02's coverage clause needs. In SQLite
    // `ease >= 2` on a NULL is NULL and the row is correctly dropped — but a
    // `CASE WHEN ease >= 2 THEN 1 END` inside `COUNT(*)` counts it, and this is
    // the case that tells the two apart.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingRepository repo = LambingRepository(db: db);

    final LambingId scored = await repo.beginLambing(ewe);
    await repo.beginLambing(ewe); // never scored
    expect(await repo.setEase(scored, const LambingEase(4)), isA<WriteCommitted>());

    final EweSummary s = (await _summary(db, ewe))!;
    expect(s.lambingsRecorded, 2);
    expect(s.scoredLambings, 1, reason: 'a blank ease is NOT RECORDED, never unassisted');
    expect(s.assistedLambings, 1);

    await db.close();
  });

  test('ease 1 counts as scored and not as assisted', () async {
    // 1 is *no assistance*. An off-by-one on the threshold is silent — the
    // number just runs high for ever, and nothing on the card says so.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingRepository repo = LambingRepository(db: db);

    final LambingId easy = await repo.beginLambing(ewe);
    await repo.setEase(easy, const LambingEase(1));

    final EweSummary s = (await _summary(db, ewe))!;
    expect(s.scoredLambings, 1);
    expect(s.assistedLambings, 0, reason: 'ease 1 is no assistance');

    await db.close();
  });

  test('the recompute is idempotent, which is what makes the rebuild trustworthy', () async {
    // **RECOMPUTE, NEVER INCREMENT.** A `+1` is faster and is wrong within one
    // night: an undo hard-deletes the lambing and a missed decrement leaves the
    // count permanently high. Running the same body twice must change nothing —
    // that property is the only reason the post-restore rebuild can be trusted.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingRepository repo = LambingRepository(db: db);
    final LambingId lambing = await repo.beginLambing(ewe);
    await repo.addLamb(lambing, sex: Sex.female);

    final EweSummary once = (await _summary(db, ewe))!;
    await writeEweSummary(db, ewe, once.rebuiltAt);
    await writeEweSummary(db, ewe, once.rebuiltAt);
    final EweSummary thrice = (await _summary(db, ewe))!;

    expect(thrice, once, reason: 'the recompute is not idempotent');
    expect(await db.select(db.eweSummaries).get(), hasLength(1), reason: 'one row per ewe');

    await db.close();
  });

  test('deleting a lambing returns the counts to their previous values', () async {
    // The hard-delete path (`07 §15.1`) and the reason the write is a recompute
    // rather than an increment: nothing has to remember to decrement.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingRepository repo = LambingRepository(db: db);

    await repo.beginLambing(ewe);
    final LambingId second = await repo.beginLambing(ewe);
    expect((await _summary(db, ewe))!.lambingsRecorded, 2);

    await (db.delete(db.lambings)..where(($LambingsTable t) => t.id.equals(second.value))).go();
    await writeEweSummary(db, ewe, appNow());

    expect((await _summary(db, ewe))!.lambingsRecorded, 1);

    await db.close();
  });

  test('a struck lambing stays in the count', () async {
    // **`indelible.md §6`: a struck row is in every list, every ewe history and
    // EVERY COUNT'S DENOMINATOR.** Filtering it out here would make the summary
    // disagree with the timeline printed directly beneath it, and the crossing-
    // out is the record of a night that happened.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingRepository repo = LambingRepository(db: db);

    final LambingId lambing = await repo.beginLambing(ewe);
    expect(await repo.strikeLambing(lambing), isA<WriteCommitted>());
    await writeEweSummary(db, ewe, appNow());

    expect((await _summary(db, ewe))!.lambingsRecorded, 1);

    await db.close();
  });

  test('rebuildAllEweSummaries fills an empty table for every ewe', () async {
    // **THE REPAIR VERB, AND THE RESTORE IS WHY IT EXISTS.** `ewe_summaries` is
    // excluded from the backup (`09 §6`), so a restored database has an empty
    // summary table and every card reads "No seasons recorded" against an animal
    // with six years of history.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId a = await seedEwe(db, tag: '412');
    final EweId b = await seedEwe(db, tag: '77');
    final LambingRepository repo = LambingRepository(db: db);
    await repo.beginLambing(a);
    await repo.beginLambing(b);
    await repo.beginLambing(b);

    // Wipe it, exactly as a restore leaves it.
    await db.delete(db.eweSummaries).go();
    expect(await db.select(db.eweSummaries).get(), isEmpty);

    await rebuildAllEweSummaries(db, appNow());

    expect(await db.select(db.eweSummaries).get(), hasLength(2));
    expect((await _summary(db, a))!.lambingsRecorded, 1);
    expect((await _summary(db, b))!.lambingsRecorded, 2);

    await db.close();
  });

  test('rebuilt_at is the caller\'s instant, not a second clock read', () async {
    // `01 §4.2`: one `appNow()` per mutation. A second read here writes a
    // `rebuilt_at` later than the event that caused it — harmless right up until
    // somebody orders anything by it.
    final AppDatabase db = testDatabase();
    final Instant pinned = Instant.fromDateTime(DateTime.utc(2026, 3, 14, 3, 20));
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    await writeEweSummary(db, ewe, pinned);

    expect((await _summary(db, ewe))!.rebuiltAt, pinned);

    await db.close();
  });
}

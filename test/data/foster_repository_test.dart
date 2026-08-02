// test/data/foster_repository_test.dart
//
// A FOSTER MOVES THE REARING DAM AND NEVER THE BIRTH DAM. That is the whole
// epic in one sentence, and this file is where it stops being a sentence.
library;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/foster_repository.dart';
import 'package:shed_book/domain/foster_outcome.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';

import '../support/harness.dart';
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

Future<Lamb> _readLamb(AppDatabase db, LambId lamb) =>
    (db.select(db.lambs)..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();

void main() {
  late AppDatabase db;
  late FosterRepository repo;

  setUp(() {
    db = testDatabase();
    repo = FosterRepository(db);
  });

  test('recordFoster leaves birth_dam unchanged and appends a FosterEvent', () async {
    // THE ANCHOR, THREE ASSERTIONS IN ORDER.
    //
    // The third is the one the epic exists for. A lamb has ONE birth dam,
    // forever — no verb in this app moves it, and `lamb_birth_dam_is_immutable`
    // is the trigger that says so at the database. The obvious implementation
    // updates the lamb's dam column, and it would make every foster look like a
    // rewrite of history: in year two the shepherd would read that 412 threw a
    // lamb she never carried.
    //
    // `birthDamBefore` IS CAPTURED FROM THE ROW, never written as a literal.
    // `412` is a TAG; an `EweId` is a row id; and under the active-only
    // uniqueness ruling a tag is not even unique across time.
    await _seedSeason(db);
    final EweId birthDam = await seedEwe(db, tag: '412');
    final EweId other = await seedEwe(db, tag: '077');
    final LambingId lambing = await seedLambing(db, birthDam);
    final LambId lamb = await seedLamb(db, lambing, birthDam);

    final int birthDamBefore = (await _readLamb(db, lamb)).birthDam;

    final WriteOutcome outcome = await repo.recordFoster(lamb, ToEwe(other));

    expect(outcome, isA<WriteCommitted>());

    final FosterEvent event = await db.select(db.fosterEvents).getSingle();
    expect(event.outcome, 'to_ewe');
    expect(event.rearingDam, other.value);

    expect(
      (await _readLamb(db, lamb)).birthDam,
      birthDamBefore,
      reason: 'a foster moves the REARING dam; the birth dam is a fact about birth',
    );
  });

  test('the three outcomes are three different facts on disk', () async {
    // `setRearingDam(LambId, EweId?)` IS A BANNED SIGNATURE (`07 §8.4` rule 1),
    // and this case is why. That signature merges `to_bottle` — null BY INTENT,
    // the shepherd put the lamb on a bottle — with `removed_unknown` — null BY
    // OMISSION, the lamb came off a ewe and where it went was not recorded.
    //
    // The rearing-credit numbers differ between those two, so merging them
    // silently changes a season's figures. `FosterOutcome` being sealed is what
    // makes the merge unconstructible rather than merely discouraged.
    await _seedSeason(db);
    final EweId birthDam = await seedEwe(db, tag: '412');
    final EweId other = await seedEwe(db, tag: '077');
    final LambingId lambing = await seedLambing(db, birthDam);

    final LambId a = await seedLamb(db, lambing, birthDam);
    final LambId b = await seedLamb(db, lambing, birthDam);
    final LambId c = await seedLamb(db, lambing, birthDam);

    await repo.recordFoster(a, ToEwe(other));
    await repo.recordFoster(b, const ToBottle());
    await repo.recordFoster(c, const RemovedUnknown());

    final List<FosterEvent> rows = await db.select(db.fosterEvents).get();
    final Map<String, FosterEvent> byOutcome = <String, FosterEvent>{
      for (final FosterEvent e in rows) e.outcome: e,
    };

    expect(byOutcome.keys.toSet(), <String>{'to_ewe', 'to_bottle', 'removed_unknown'});

    // THE `CHECK ((outcome = 'to_ewe') = (rearing_dam IS NOT NULL))` IS AN
    // EQUALITY, so both directions are asserted: a dam without `to_ewe` is as
    // impossible as `to_ewe` without a dam.
    expect(byOutcome['to_ewe']!.rearingDam, other.value);
    expect(byOutcome['to_bottle']!.rearingDam, isNull);
    expect(byOutcome['removed_unknown']!.rearingDam, isNull);
  });

  test('the event carries the provenance quad and the lamb\'s own season', () async {
    // THE SEASON IS THE LAMB'S, walked to inside the transaction. Reading it
    // from a screen's copy is one frame stale, and getting it wrong scopes the
    // foster into the wrong season's rearing figures forever.
    await _seedSeason(db);
    final EweId birthDam = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, birthDam);
    final LambId lamb = await seedLamb(db, lambing, birthDam);

    await repo.recordFoster(lamb, const ToBottle());

    final FosterEvent event = await db.select(db.fosterEvents).getSingle();
    final Lambing parent = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();

    expect(event.season, parent.season, reason: 'walked to, not guessed');
    expect(event.timeSource, 'auto');
    expect(event.originalEffective, isNull);
    expect(event.effectiveAt.epochMillis, event.capturedAt.epochMillis, reason: 'one instant');
    expect(event.uid, isNotEmpty, reason: 'export identity — #32');
  });

  test('the birth dam is immutable at the database, not merely by convention', () async {
    // THE MECHANISM, PROVED WITH A RAW UPDATE. Everything above proves the
    // REPOSITORY does not move the birth dam; this proves NOTHING can. The
    // trigger is what holds the line against a verb written in three epics'
    // time by somebody who has not read this file.
    await _seedSeason(db);
    final EweId birthDam = await seedEwe(db, tag: '412');
    final EweId other = await seedEwe(db, tag: '077');
    final LambingId lambing = await seedLambing(db, birthDam);
    final LambId lamb = await seedLamb(db, lambing, birthDam);

    await expectLater(
      () => db.customStatement('UPDATE lambs SET birth_dam = ? WHERE id = ?', <Object?>[
        other.value,
        lamb.value,
      ]),
      // NAMED, NOT `anything`. `throwsA(anything)` passes when the statement
      // fails for a reason that has nothing to do with the trigger — a typo in
      // the SQL, a missing column — and the case would then be green while the
      // mechanism it claims to prove had been deleted.
      throwsA(isA<SqliteException>()),
      reason: 'lamb_birth_dam_is_immutable — a fact about birth cannot be edited',
    );

    expect((await _readLamb(db, lamb)).birthDam, birthDam.value);
  });
}

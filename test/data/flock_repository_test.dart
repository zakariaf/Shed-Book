// test/data/flock_repository_test.dart
//
// The deck statement, against a real in-memory SQLite. The properties here are
// about SQL and about list IDENTITY, and neither is observable from a mock.
library;

import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';

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
    repo = FlockRepository(db: db, policy: const FreeTierPolicy());
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
    final QuickEntryDeck deck = await FlockRepository(
      db: counted,
      policy: const FreeTierPolicy(),
    ).watchQuickEntryDeck().first;

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

  test('createEwe with EntryContext.liveEntry never returns BlockedByCap and marks the row '
      'over_free_cap', () async {
    // THE ANCHOR, ASSERTED WITH THE VALUES RATHER THAN THE SHAPE. A case that
    // only checks "did not throw" passes against a verb that silently swallowed
    // the decision.
    //
    // Decision #91: a shepherd mid-lambing is never told to pay. The row is
    // REAL, it is FLAGGED, and it is never hidden, greyed out or made
    // read-only — the cap constrains the next write, never the existing records.
    for (final int seeded in <int>[0, 15, 16, 400]) {
      final AppDatabase own = testDatabase();
      addTearDown(own.close);
      final FlockRepository r = FlockRepository(db: own, policy: const FreeTierPolicy());

      final SeasonId season = await _seedSeason(own);
      for (int i = 0; i < seeded; i++) {
        await _seedEweInSeason(own, season, tag: 'S$i');
      }

      final WriteOutcome outcome = await r.createEwe(tag: '412', context: EntryContext.liveEntry);

      expect(outcome, isA<WriteCommitted>(), reason: 'seeded=$seeded');
      expect((outcome as WriteCommitted).insertedId, isNotNull, reason: 'seeded=$seeded');

      final Ewe row = await (own.select(
        own.ewes,
      )..where(($EwesTable t) => t.tag.equals('412'))).getSingle();
      expect(row.overFreeCap, seeded + 1 > 15, reason: 'seeded=$seeded');
    }
  });

  test('createEwe stores the tag exactly as typed and projects the digits beside it', () async {
    // Spec §12.4 and decision #55. `0412` stores `0412`; the projection is
    // written in the SAME statement and is never a correction. A unique
    // tag_digits would refuse `0412` while `412` exists, which is the app
    // deciding two tags are one animal.
    await _seedSeason(db);
    await repo.createEwe(tag: '0412', context: EntryContext.liveEntry);
    await repo.createEwe(tag: 'RED', context: EntryContext.liveEntry);

    final List<Ewe> rows = await db.select(db.ewes).get();
    expect(rows.firstWhere((Ewe e) => e.tag == '0412').tagDigits, '0412');
    expect(rows.firstWhere((Ewe e) => e.tag == 'RED').tagDigits, isEmpty);
  });

  test('createEwe writes the ewe_touches row in the same transaction', () async {
    // The recents strip is built from ewe_touches, so a ewe created and not
    // touched is a ewe the shepherd cannot find again without typing the tag —
    // at 03:20, one-handed.
    await _seedSeason(db);
    final WriteOutcome outcome = await repo.createEwe(tag: '412', context: EntryContext.liveEntry);

    final int id = (outcome as WriteCommitted).insertedId!;
    final EweTouch touch = await (db.select(
      db.eweTouches,
    )..where(($EweTouchesTable t) => t.ewe.equals(id))).getSingle();
    expect(touch.touchedAt, isNotNull);
  });

  test('the calm path refuses a second season and the live path never does', () async {
    // The asymmetry IS the decision (#91). Both arms are asserted, because a
    // policy that refused nothing would pass the live-entry case on its own.
    //
    // **PINNED TO 14:00, AND IT WAS NOT — THIS TEST FAILED EVERY NIGHT.**
    // `FreeTierPolicy.decide` runs `isQuietHours(now)` before it refuses
    // anything: *"the app does not solicit at night, even in a calm context."*
    // So the calm arm ALLOWS the write between 22:00 and 06:00, and this case
    // read the real clock — green by day, red by night, which is the half of the
    // day this product is used in. Found at 22:32 on an unrelated run.
    //
    // A single-instant assertion, so `atFixed` is the right tool (`12 §2.2`) and
    // 14:00 is chosen for being nowhere near either quiet-hours boundary.
    await atFixed(DateTime.utc(2026, 3, 14, 14), () async {
      await _seedSeason(db);
      await _seedSeason(db, year: 2027);

      expect(
        await repo.createEwe(tag: '900', context: EntryContext.calm),
        isA<WriteRefused>(),
        reason: 'two seasons, not unlocked — the calm path is where the gate lands',
      );
      expect(
        await repo.createEwe(tag: '901', context: EntryContext.liveEntry),
        isA<WriteCommitted>(),
        reason: 'a shepherd mid-lambing is never told to pay',
      );
    });
  });

  test('an unlocked flock is never over the cap', () async {
    await _seedSeason(db);
    await (db.update(db.entitlements)..where(($EntitlementsTable t) => t.id.equals(1))).write(
      const EntitlementsCompanion(unlocked: Value<bool>(true)),
    );

    final SeasonId season = (await db.select(db.seasons).get())
        .map((Season s) => SeasonId(s.id))
        .first;
    for (int i = 0; i < 40; i++) {
      await _seedEweInSeason(db, season, tag: 'U$i');
    }

    await repo.createEwe(tag: '412', context: EntryContext.liveEntry);
    final Ewe row = await (db.select(
      db.ewes,
    )..where(($EwesTable t) => t.tag.equals('412'))).getSingle();
    expect(row.overFreeCap, isFalse);
  });
}

/// A season, made current, because the cap counts ewes IN THE CURRENT SEASON.
Future<SeasonId> _seedSeason(AppDatabase db, {int year = 2026}) async {
  final Instant now = _at(0);
  final int id = await db
      .into(db.seasons)
      .insert(
        SeasonsCompanion.insert(
          year: year,
          label: '$year',
          startDate: LocalDate(year, 1, 1),
          // `uid` is CHECK-constrained to exactly 36 characters, so a
          // hand-written one has to be counted rather than eyeballed. newUid()
          // is the real generator and there is no reason for a test to fake it.
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

/// A ewe AND her participation row — the cap counts `ewe_seasons`, not `ewes`,
/// because a barren ewe has no lambing and must still be counted.
Future<void> _seedEweInSeason(AppDatabase db, SeasonId season, {required String tag}) async {
  final EweId ewe = await seedEwe(db, tag: tag);
  final Instant now = _at(0);
  await db
      .into(db.eweSeasons)
      .insert(
        EweSeasonsCompanion.insert(
          season: season.value,
          ewe: ewe.value,
          status: 'to_ram',
          uid: newUid(),
          createdAt: now,
          updatedAt: now,
        ),
      );
}

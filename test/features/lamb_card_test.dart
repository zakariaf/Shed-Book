// test/features/lamb_card_test.dart
//
// The Lamb Card. `07 §7.1` fixes its dependency set at ONE statement; this file
// is where that claim is checked from the outside.
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/units/weight_unit.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/features/lambing/lamb_card_screen.dart';

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

void main() {
  testWidgets('the rearing dam is read from lamb_rearing and changes when a foster event is '
      'appended', (WidgetTester tester) async {
    // THE ANCHOR, AND THE THIRD ASSERTION IS THE ONE THAT MATTERS.
    //
    // The rearing dam is PROJECTED by the `lamb_rearing` view, never COPIED onto
    // the lamb row. So appending a foster event must move what the card renders
    // while leaving `lambs.birth_dam` and `lambs.updated_at` exactly where they
    // were — and it is `updated_at` that proves it, because a copy would have
    // had to write the row to change the answer.
    //
    // The foster event is inserted DIRECTLY against the in-memory database
    // rather than through a verb, because the claim is about the READ path.
    // Going through `recordFoster` (N18) would test that verb instead.
    final AppDatabase db = testDatabase();
    final SeasonId season = await _seedSeason(db);
    final EweId birthDam = await seedEwe(db, tag: '412');
    final EweId fosterDam = await seedEwe(db, tag: '077');
    final LambingId lambing = await seedLambing(db, birthDam);
    final LambId lamb = await seedLamb(db, lambing, birthDam);

    await tester.pumpApp(LambCardScreen(lambId: lamb), db: db);
    await tester.pumpAndSettle();

    // BEFORE: unfostered, so the rearing dam IS the birth dam — that is what
    // the view's COALESCE says, and it is not the same as "no rearing dam".
    expect(find.textContaining('412'), findsWidgets);

    final Lamb before = await (db.select(
      db.lambs,
    )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();

    await db
        .into(db.fosterEvents)
        .insert(
          FosterEventsCompanion.insert(
            uid: newUid(),
            createdAt: Instant.fromDateTime(DateTime.utc(2026, 3, 14, 5)),
            updatedAt: Instant.fromDateTime(DateTime.utc(2026, 3, 14, 5)),
            lamb: lamb.value,
            season: season.value,
            rearingDam: Value<int?>(fosterDam.value),
            outcome: 'to_ewe',
            effectiveAt: Instant.fromDateTime(DateTime.utc(2026, 3, 14, 5)),
            capturedAt: Instant.fromDateTime(DateTime.utc(2026, 3, 14, 5)),
          ),
        );
    await tester.pumpAndSettle();

    // AFTER: the card follows, with no write to the lamb.
    expect(find.textContaining('077'), findsWidgets, reason: 'the projection moved');

    final Lamb after = await (db.select(
      db.lambs,
    )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();

    expect(after.birthDam, before.birthDam, reason: 'a lamb has one birth dam, forever');
    expect(
      after.updatedAt,
      before.updatedAt,
      reason: 'PROJECTED, not copied — a copy would have had to write this row',
    );

    await tester.closeApp();
  });

  // A PLAIN `test`, NOT `testWidgets`. Measured: as a widget test this hung —
  // it pumps nothing, so the binding never completes a frame and the file reads
  // sit behind it. A source-text claim needs no widget tree, and saying so is
  // cheaper than diagnosing the hang a second time.
  test('the card reads one statement and the feature imports no drift symbol', () {
    // `07 §7.1`'s dependency set, held as a SOURCE-TEXT claim rather than by
    // counting streams at runtime. Two statements would be two dependency lists
    // that can disagree about when the card is stale.
    final String controller = _read('lib/features/lambing/lamb_card_controller.dart');
    final String screen = _read('lib/features/lambing/lamb_card_screen.dart');

    for (final String source in <String>[controller, screen]) {
      expect(source, isNot(contains('package:drift')));
      // The stream-combining helpers, described rather than named where the
      // needle would match this file's own text.
      expect(source, isNot(contains('combineLatest')));
      expect(source, isNot(contains('Rx.combine')));
      expect(source, isNot(contains('customSelect')));
    }
  });
  // ---------------------------------------------------------------------------
  // T02 — sex and a birthweight on the app's own keypad
  // ---------------------------------------------------------------------------

  for (final ({WeightUnit unit, List<String> digits, String back}) c
      in <({WeightUnit unit, List<String> digits, String back})>[
        (unit: WeightUnit.kg, digits: <String>['4', '.', '1'], back: '4.1 kg'),
        (unit: WeightUnit.lb, digits: <String>['9', '.', '0'], back: '9 lb 0 oz'),
      ]) {
    testWidgets('a weight typed in ${c.unit.name} comes back as the digits that went in', (
      WidgetTester tester,
    ) async {
      // THE WIDGET HALF OF T02'S ANCHOR, and the task's own sharpening: exercise
      // the FULL entry path, not just the conversion. Type the digits, read the
      // committed `birth_weight_g`, and assert what the cell renders afterwards
      // is what was typed — in both units, because a round trip that only holds
      // in kg is a round trip that mislabels every lb user's flock.
      //
      // The lb case is the one that caught the "3 lb 16 oz" defect: 9 lb stores
      // as 4082 g, and the old decomposition printed 8 lb 16 oz.
      final AppDatabase db = testDatabase();
      await _seedSeason(db);
      final EweId ewe = await seedEwe(db, tag: '412');
      final LambingId lambing = await seedLambing(db, ewe);
      final LambId lamb = await seedLamb(db, lambing, ewe);

      await (db.update(db.appSettings)..where(($AppSettingsTable t) => t.id.equals(1))).write(
        AppSettingsCompanion(weightUnit: Value<String>(c.unit.key)),
      );

      await tester.pumpApp(LambCardScreen(lambId: lamb), db: db);
      await tester.pumpAndSettle();

      final Finder cell = find.byKey(const Key('lamb_card.weight'));
      await tester.ensureVisible(cell);
      await tester.pumpAndSettle();
      await tester.tap(cell);
      await tester.pumpAndSettle();

      for (final String d in c.digits) {
        final Finder key = find.byKey(
          Key(d == '.' ? 'quick_entry.keypad.decimal' : 'quick_entry.keypad.digit_$d'),
        );
        await tester.ensureVisible(key);
        await tester.pumpAndSettle();
        await tester.tap(key);
        await tester.pump();
      }

      final Finder confirm = find.byKey(const Key('lamb_card.weight.confirm'));
      await tester.ensureVisible(confirm);
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      // CANONICAL GRAMS IN THE COLUMN — never the typed unit (#42, R68).
      final Lamb row = await (db.select(
        db.lambs,
      )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();
      expect(row.birthWeightG, isNotNull);

      // AND THE DIGITS THAT COME BACK ARE THE ONES THAT WENT IN.
      expect(find.text(c.back), findsOneWidget, reason: '${c.unit.name} round trip');

      await tester.closeApp();
    });
  }

  testWidgets('a lamb sex offers three answers and clearing is the fourth', (
    WidgetTester tester,
  ) async {
    // R45 ON SCREEN, AND THE FOURTH STATE IS REACHED BY TAPPING THE SELECTED
    // ONE. `null` is *not recorded*; `Sex.unknown` is *the shepherd looked and
    // could not tell*. Two different facts, neither the other's default — and
    // without the clear there is no way back after a mis-tap, which would leave
    // the app holding an answer the shepherd disowned.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId lamb = await seedLamb(db, lambing, ewe);

    await tester.pumpApp(LambCardScreen(lambId: lamb), db: db);
    await tester.pumpAndSettle();

    Future<void> tapSex(String key) async {
      final Finder f = find.byKey(Key('lamb_card.sex.$key'));
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    Future<String?> storedSex() async {
      final Lamb row = await (db.select(
        db.lambs,
      )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();
      return row.sex;
    }

    expect(await storedSex(), isNull, reason: 'a lamb starts not recorded');

    await tapSex('f');
    expect(await storedSex(), 'f');

    await tapSex('unknown');
    expect(await storedSex(), 'unknown', reason: 'looked and could not tell — a real answer');

    await tapSex('unknown');
    expect(
      await storedSex(),
      isNull,
      reason: 'tapping the selected one clears it, back to nothing said',
    );

    await tester.closeApp();
  });
  // ---------------------------------------------------------------------------
  // T03 — death date, cause, stillborn, and deathBeforeBirth
  // ---------------------------------------------------------------------------

  testWidgets('a death date before the birth prints deathBeforeBirth and stores both dates '
      'unchanged', (WidgetTester tester) async {
    // THE ANCHOR, AND THE SECOND CLAUSE IS WHAT SEPARATES A WARNING FROM A
    // CORRECTION. A case that only asserted the badge appeared would pass just
    // as happily against an app that quietly moved the death date forward to the
    // birth — which is exactly §12.4's failure, and it would be invisible: the
    // screen would look right and the record would be a lie.
    //
    // So BOTH dates are read back out of the database AFTER the badge renders.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId lamb = await seedLamb(db, lambing, ewe);

    // Born on the 14th, dead on the 10th — impossible, and the shepherd's to
    // resolve rather than the app's.
    await (db.update(db.lambings)..where(($LambingsTable t) => t.id.equals(lambing.value))).write(
      LambingsCompanion(localDate: Value<LocalDate>(LocalDate(2026, 3, 14))),
    );
    await (db.update(db.lambs)..where(($LambsTable t) => t.id.equals(lamb.value))).write(
      LambsCompanion(
        status: const Value<String>('dead'),
        deathDate: Value<LocalDate?>(LocalDate(2026, 3, 10)),
      ),
    );

    await tester.pumpApp(LambCardScreen(lambId: lamb), db: db);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lamb_card.warning.death_before_birth')), findsOneWidget);

    final Lamb lambAfter = await (db.select(
      db.lambs,
    )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();
    final Lambing lambingAfter = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();

    expect(lambAfter.deathDate, LocalDate(2026, 3, 10), reason: 'not moved forward');
    expect(lambingAfter.localDate, LocalDate(2026, 3, 14), reason: 'and not moved back either');

    await tester.closeApp();
  });

  testWidgets('a same-day death is ordinary and prints no mark', (WidgetTester tester) async {
    // EQUAL DATES ARE NOT A CONTRADICTION. A stillborn lamb and a same-day loss
    // both die on the day they were born, and a mark there would land on the
    // saddest ordinary record in the book. Only STRICTLY BEFORE is impossible.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId lamb = await seedLamb(db, lambing, ewe);

    await (db.update(db.lambings)..where(($LambingsTable t) => t.id.equals(lambing.value))).write(
      LambingsCompanion(localDate: Value<LocalDate>(LocalDate(2026, 3, 14))),
    );
    await (db.update(db.lambs)..where(($LambsTable t) => t.id.equals(lamb.value))).write(
      LambsCompanion(
        status: const Value<String>('stillborn'),
        deathDate: Value<LocalDate?>(LocalDate(2026, 3, 14)),
      ),
    );

    await tester.pumpApp(LambCardScreen(lambId: lamb), db: db);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lamb_card.warning.death_before_birth')), findsNothing);

    await tester.closeApp();
  });

  testWidgets('recording a death moves status, date and cause together', (
    WidgetTester tester,
  ) async {
    // ONE TRANSACTION, BECAUSE THE CHECKS MAKE IT ONE MOVE. A row that is `dead`
    // with no date, or carries a date while `alive`, is a state the database
    // refuses — so three separate writes would each have to pass through an
    // invalid intermediate.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId lamb = await seedLamb(db, lambing, ewe);

    await tester.pumpApp(LambCardScreen(lambId: lamb), db: db);
    await tester.pumpAndSettle();

    Future<void> tap(String key) async {
      final Finder f = find.byKey(Key(key));
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    await tap('lamb_card.status.dead');

    Lamb row = await (db.select(
      db.lambs,
    )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();
    expect(row.status, 'dead');
    expect(
      row.deathDate,
      isNull,
      reason:
          'THE DATE IS NOT INVENTED — defaulting to today would answer a question '
          'the shepherd has not been asked yet',
    );

    await tap('lamb_card.death_date.minus_0');

    row = await (db.select(
      db.lambs,
    )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();
    expect(row.deathDate, isNotNull, reason: 'now they have said which day');

    // AND BACK TO ALIVE CLEARS BOTH.
    await tap('lamb_card.status.alive');

    row = await (db.select(
      db.lambs,
    )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();
    expect(row.status, 'alive');
    expect(row.deathDate, isNull, reason: 'a living lamb did not die on Tuesday');
    expect(row.deathCause, isNull);

    await tester.closeApp();
  });

  testWidgets('the death detail is absent while the lamb is alive', (WidgetTester tester) async {
    // NOT TIDINESS. A date field on a living lamb is a field that can be filled
    // in, and the CHECK would then refuse the write at 03:20 — which is the
    // worst possible moment to discover a control that should not have been on
    // screen.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId lamb = await seedLamb(db, lambing, ewe);

    await tester.pumpApp(LambCardScreen(lambId: lamb), db: db);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lamb_card.status')), findsOneWidget);
    expect(find.byKey(const Key('lamb_card.death_date')), findsNothing);

    await tester.closeApp();
  });
  // ---------------------------------------------------------------------------
  // T04 — pet lamb status and the feeding count
  // ---------------------------------------------------------------------------

  testWidgets('incrementing the feeding count commits immediately and the control is at least '
      '64 by 64', (WidgetTester tester) async {
    // THE ANCHOR, WITH BOTH SHARPENINGS THE TASK ASKS FOR.
    //
    // COMMITS IMMEDIATELY — `lambs.bottle_feeds` is read back out of the
    // database with no Save button pressed and no route popped.
    //
    // 64 BY 64 — MEASURED WITH `getSize`, never asserted against the constant
    // that was passed in. A size assertion that reads its own input proves
    // nothing: it passes against a widget whose parent has squeezed it flat.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId lamb = await seedLamb(db, lambing, ewe);

    await tester.pumpApp(LambCardScreen(lambId: lamb), db: db);
    await tester.pumpAndSettle();

    Future<void> tap(String key) async {
      final Finder f = find.byKey(Key(key));
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    Future<Lamb> row() async =>
        (db.select(db.lambs)..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();

    // THE COUNT IS ABSENT UNTIL SHE IS ON THE BOTTLE, and it is not a zero.
    expect(find.byKey(const Key('lamb_card.feeds.add')), findsNothing);
    expect(find.textContaining('SKIPPABLE'), findsWidgets);

    await tap('lamb_card.pet_lamb');
    expect((await row()).petLamb, isTrue);

    final Size add = tester.getSize(find.byKey(const Key('lamb_card.feeds.add')));
    expect(add.width, greaterThanOrEqualTo(64.0));
    expect(add.height, greaterThanOrEqualTo(64.0));

    await tap('lamb_card.feeds.add');
    expect((await row()).bottleFeeds, 1);

    await tap('lamb_card.feeds.add');
    await tap('lamb_card.feeds.add');
    expect((await row()).bottleFeeds, 3, reason: 'each tap is one feed');

    await tester.closeApp();
  });

  testWidgets('coming off the bottle keeps the feeds that were given', (WidgetTester tester) async {
    // THE INSTINCT IS TO TIDY, AND IT IS WRONG. If she is no longer a pet lamb
    // the feeds look meaningless — but *which lambs cost them six weeks of
    // bottles* is exactly the April question, and a lamb weaned off the bottle is
    // still a lamb that was on it. Unlike the death columns there is no CHECK
    // forcing these two to move together, so this is a choice, and this case is
    // where the choice is recorded.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId lamb = await seedLamb(db, lambing, ewe);

    await (db.update(db.lambs)..where(($LambsTable t) => t.id.equals(lamb.value))).write(
      const LambsCompanion(petLamb: Value<bool>(true), bottleFeeds: Value<int>(42)),
    );

    await tester.pumpApp(LambCardScreen(lambId: lamb), db: db);
    await tester.pumpAndSettle();

    final Finder toggle = find.byKey(const Key('lamb_card.pet_lamb'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    final Lamb row = await (db.select(
      db.lambs,
    )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();

    expect(row.petLamb, isFalse);
    expect(row.bottleFeeds, 42, reason: 'six weeks of bottles is a fact, not a status');

    await tester.closeApp();
  });
  // ---------------------------------------------------------------------------
  // T05 — the matrix variant and the empty state
  // ---------------------------------------------------------------------------

  testWidgets('a freshly-born lamb renders every region and no death detail', (
    WidgetTester tester,
  ) async {
    // THE STATE THE CARD OPENS IN. A lamb tapped from a lambing seconds after it
    // was tallied has a birth dam, a rearing dam and one history row, and
    // nothing else — and every region must still be there, because a card that
    // rendered nothing until the shepherd filled something in would make the tap
    // look like it failed.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId lamb = await seedLamb(db, lambing, ewe);

    await tester.pumpApp(LambCardScreen(lambId: lamb), db: db);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lamb_card.title')), findsOneWidget);
    expect(find.byKey(const Key('lamb_card.summary')), findsOneWidget);
    expect(find.byKey(const Key('lamb_card.birth_dam')), findsOneWidget);
    expect(find.byKey(const Key('lamb_card.rearing_dam')), findsOneWidget);
    expect(find.byKey(const Key('lamb_card.sex')), findsOneWidget);
    expect(find.byKey(const Key('lamb_card.status')), findsOneWidget);
    expect(find.byKey(const Key('lamb_card.pet_lamb')), findsOneWidget);

    // NOT AN EMPTY STATE — the `born` arm always yields one row, so the line
    // says nothing ELSE has been recorded, which is the true statement.
    expect(find.byKey(const Key('lamb_card.nothing_else')), findsOneWidget);

    // AND NO DEATH DETAIL, because she is alive.
    expect(find.byKey(const Key('lamb_card.death_date')), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing, reason: '07 §1.4 — no spinner');

    await tester.closeApp();
  });

  testWidgets('every act on the card is reachable at the smallest device and textScaler 1.3', (
    WidgetTester tester,
  ) async {
    // `12 §6.2`'s REACHABILITY CLAIM, which is not the overflow matrix's claim.
    // The matrix proves nothing is clipped; this proves everything can still be
    // REACHED — a control pushed below the fold on a 375 pt phone at 130% text
    // is not clipped, it is gone. 1.3 is the Android 14+ ceiling most users
    // reach.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId lamb = await seedLamb(db, lambing, ewe);

    await tester.pumpApp(
      LambCardScreen(lambId: lamb),
      db: db,
      device: Device.small,
      textScale: 1.3,
    );
    await tester.pumpAndSettle();

    for (final String key in <String>[
      'lamb_card.sex.f',
      'lamb_card.sex.m',
      'lamb_card.sex.unknown',
      'lamb_card.weight',
      'lamb_card.status.alive',
      'lamb_card.status.dead',
      'lamb_card.status.stillborn',
      'lamb_card.pet_lamb',
    ]) {
      final Finder act = find.byKey(Key(key));
      expect(act, findsOneWidget, reason: key);
      await tester.ensureVisible(act);
      await tester.pumpAndSettle();
    }

    await tester.closeApp();
  });
}

String _read(String path) => File(path).readAsStringSync();

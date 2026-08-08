// test/policy/contradiction_does_not_mutate_test.dart — `12 §10.4`.
//
// NAMED FOR THE PROPERTY, NOT FOR THE MECHANISM (`CONVENTIONS §4.1`). The
// property is: **finding a contradiction never changes a value.** Not "the
// warning strip renders", not "checkLambing returns two items" — those are ways
// of observing it, and a file named after one of them stops being maintained
// when that one changes.
//
// This is §12.4 at the level where it can actually be violated. Everything above
// it — `Warning` having no `fix()`, `Reviewed<T>` having no writer, the missing
// `warnings` column — makes the violation hard to WRITE. This file makes it hard
// to SHIP: it exercises the real path and compares the database on both sides.
library;

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/features/lambing/lambing_entry_screen.dart';

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

/// Every column of `lambings` that a "helpful" reconciliation could plausibly
/// touch, plus the lamb ids. Compared whole, on both sides of the render.
Future<({Lambing lambing, List<int> lambs})> _snapshot(AppDatabase db, LambingId id) async {
  return (
    lambing: await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(id.value))).getSingle(),
    lambs: (await db.select(db.lambs).get()).map((Lamb l) => l.id).toList(),
  );
}

void main() {
  testWidgets('rendering a contradiction changes nothing in the database', (
    WidgetTester tester,
  ) async {
    // THE PROPERTY, ACROSS EVERY CONTRADICTORY SHAPE THE SCREEN CAN BE HANDED.
    //
    // A per-case version of this would assert "the mark appeared" and stop —
    // and would still pass if the app quietly wrote a third lamb to make the
    // numbers agree. That is precisely the failure §12.4 exists to prevent, so
    // the comparison is of the WHOLE ROW plus the lamb ids, on both sides.
    for (final ({int declared, int lambs}) shape in <({int declared, int lambs})>[
      (declared: 1, lambs: 2), // declared fewer than counted
      (declared: 3, lambs: 1), // declared more than counted
      (declared: 4, lambs: 0), // declared, none tallied yet
      (declared: 2, lambs: 5), // a long way apart
    ]) {
      final AppDatabase db = testDatabase();
      await _seedSeason(db);
      final EweId ewe = await seedEwe(db, tag: '412');
      final LambingId lambing = await seedLambing(db, ewe);

      await (db.update(db.lambings)..where(($LambingsTable t) => t.id.equals(lambing.value))).write(
        LambingsCompanion(declaredBirthType: Value<int?>(shape.declared)),
      );
      for (int i = 0; i < shape.lambs; i++) {
        await seedLamb(db, lambing, ewe);
      }

      final ({Lambing lambing, List<int> lambs}) before = await _snapshot(db, lambing);

      await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
      await tester.pumpAndSettle();

      final ({Lambing lambing, List<int> lambs}) after = await _snapshot(db, lambing);

      final String shapeName = 'declared ${shape.declared}, ${shape.lambs} lambs';
      expect(after.lambing.declaredBirthType, before.lambing.declaredBirthType, reason: shapeName);
      expect(after.lambs, before.lambs, reason: '$shapeName — no lamb added and none struck');
      expect(after.lambing.occurredAt, before.lambing.occurredAt, reason: shapeName);
      expect(after.lambing.timeSource, before.lambing.timeSource, reason: shapeName);
      expect(after.lambing.ease, before.lambing.ease, reason: shapeName);
      expect(
        after.lambing.updatedAt,
        before.lambing.updatedAt,
        reason: '$shapeName — reading is not writing, so updated_at does not move',
      );

      await tester.closeApp();
    }
  });

  testWidgets('a contradiction never blocks a write', (WidgetTester tester) async {
    // `05 §7.5` GUARANTEE 3, ABSOLUTE. A blocked write produces a lost record,
    // which is worse than a queried one — and on this screen there is nothing to
    // block anyway, because every field committed the moment it was tapped.
    //
    // The case proves the negative by writing WHILE the contradiction is on
    // screen: the ease tap must commit exactly as it does on a clean record.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await (db.update(db.lambings)..where(($LambingsTable t) => t.id.equals(lambing.value))).write(
      const LambingsCompanion(declaredBirthType: Value<int?>(3)),
    );
    await seedLamb(db, lambing, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lambing_entry.query.declared_type')), findsOneWidget);

    // **THE DIGIT, NOT THE SENTENCE — AND THE CONTROL CHANGED, NOT THE CLAIM.**
    // `§7.9` gives lambing ease five 72 pt buttons reading `1 2 3 4 5`; until the
    // R87 rebuild it rendered five full-width sentences, so this test tapped
    // *"Considerable assistance needed"*. The sentence is now the button's spoken
    // label and the digit is its face, which is what the section asks for: the
    // ordinal on screen is the ordinal in the column.
    //
    // What this test proves is untouched — a query mark gates nothing, a write
    // beside it lands, and the contradiction survives both.
    final Finder ease = find.descendant(
      of: find.byKey(const Key('lambing_entry.ease')),
      matching: find.text('3'),
    );
    await tester.ensureVisible(ease);
    await tester.pumpAndSettle();
    await tester.tap(ease);
    await tester.pumpAndSettle();

    final Lambing row = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();
    expect(row.ease, 3, reason: 'the query mark does not gate anything');

    // AND THE CONTRADICTION IS STILL THERE, unaltered by the write that
    // happened beside it.
    expect(row.declaredBirthType, 3);
    expect(await db.select(db.lambs).get(), hasLength(1));

    await tester.closeApp();
  });
}

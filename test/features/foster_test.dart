// test/features/foster_test.dart
//
// The Foster screen's own file. The one-tap budget lives in
// `tap_budget_test.dart` because that is where budgets live; this is everything
// else the screen promises.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/foster_repository.dart';
import 'package:shed_book/domain/foster_outcome.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/lambing/foster_screen.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

Future<void> _tap(WidgetTester tester, String key) async {
  final Finder f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String digits) async {
  for (final String d in digits.split('')) {
    await tester.tap(find.byKey(Key('quick_entry.keypad.digit_$d')));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('fostering to the birth dam warns, commits, and changes nothing else', (
    WidgetTester tester,
  ) async {
    // THE ANCHOR, AND ALL FOUR ASSERTIONS ARE IN ONE CASE BECAUSE THE POINT IS
    // THAT THEY HOLD TOGETHER. A warning that blocked would satisfy the first
    // and fail the second; a warning that "helpfully" fixed the dam would
    // satisfy the first two and fail the third.
    //
    // The lamb has NO foster events, so her current rearing dam IS her birth dam
    // by arm 1 of `lamb_rearing` — which is the common case at 3am and the
    // reason `fosterToSelf` must compare against the CURRENT rearing dam rather
    // than against the birth dam.
    final AppDatabase db = testDatabase();
    final EweId birthDam = await seedEwe(db, tag: '412');
    final PenId pen = await seedPen(db, label: 'A');
    await seedPenOccupancy(db, pen, birthDam);
    final LambingId lambing = await seedLambing(db, birthDam);
    final LambId lamb = await seedLamb(db, lambing, birthDam);

    final Lamb lambBefore = await (db.select(
      db.lambs,
    )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();
    final Lambing lambingBefore = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();

    await tester.pumpApp(FosterScreen(lambId: lamb), db: db);
    await tester.pumpAndSettle();
    await _type(tester, '412');
    await _tap(tester, 'foster.target.412');

    // 1 — THE WARNING RENDERS.
    expect(find.byKey(const Key('foster.warning.to_self')), findsOneWidget);

    // 2 — AND THE WRITE STILL COMMITTED. `05 §7.5` guarantee 3: a warning never
    // gates a write, because a blocked write produces a lost record.
    final FosterEvent event = await db.select(db.fosterEvents).getSingle();
    expect(event.outcome, 'to_ewe');
    expect(event.rearingDam, birthDam.value);

    // 3 — THE BIRTH DAM IS UNCHANGED.
    final Lamb lambAfter = await (db.select(
      db.lambs,
    )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();
    expect(lambAfter.birthDam, lambBefore.birthDam);

    // 4 — AND NOTHING ELSE MOVED. Asserted on `updated_at`, not on a screenshot:
    // a helpful correction somewhere else would have had to write a row.
    expect(lambAfter.updatedAt, lambBefore.updatedAt);
    final Lambing lambingAfter = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();
    expect(lambingAfter.updatedAt, lambingBefore.updatedAt);

    await tester.closeApp();
  });

  testWidgets('fostering back to the birth dam after a foster does NOT warn', (
    WidgetTester tester,
  ) async {
    // THE INVERSE CASE, AND IT IS THE ONE THAT CATCHES PEOPLE. After a foster to
    // B, the lamb's current rearing dam is B — so putting her back with her
    // mother is a move to a DIFFERENT ewe and nothing about it is a self-foster.
    //
    // A `birthDam == target` implementation passes the anchor and fails here,
    // which is exactly why this case exists.
    final AppDatabase db = testDatabase();
    final EweId birthDam = await seedEwe(db, tag: '412');
    final EweId other = await seedEwe(db, tag: '077');
    // TWO PENS, BECAUSE A PEN HOLDS ONE EWE. `pen_occupancies` has a UNIQUE on
    // the pen and the first version of this case tripped it — which is the
    // schema saying what a lambing pen IS, rather than a constraint to work
    // around.
    final PenId penA = await seedPen(db, label: 'A');
    final PenId penB = await seedPen(db, label: 'B');
    await seedPenOccupancy(db, penA, birthDam);
    await seedPenOccupancy(db, penB, other);
    final LambingId lambing = await seedLambing(db, birthDam);
    final LambId lamb = await seedLamb(db, lambing, birthDam);

    await FosterRepository(db).recordFoster(lamb, ToEwe(other));

    await tester.pumpApp(FosterScreen(lambId: lamb), db: db);
    await tester.pumpAndSettle();
    await _type(tester, '412');
    await _tap(tester, 'foster.target.412');

    expect(
      find.byKey(const Key('foster.warning.to_self')),
      findsNothing,
      reason: 'her rearing dam was 077; 412 is a different ewe',
    );
    expect(await db.select(db.fosterEvents).get(), hasLength(2));

    await tester.closeApp();
  });

  testWidgets('a bottle on a lamb already on a bottle does not warn', (WidgetTester tester) async {
    // `rearing_dam IS NULL` IS A THIRD STATE, NOT A MATCH. Null-by-intent is not
    // *already on this ewe*, and there is no ewe to be on — an implementation
    // that treated null as "same as the target" would warn here, which would be
    // the app objecting to a shepherd recording a second bottle feed's worth of
    // truth.
    final AppDatabase db = testDatabase();
    final EweId birthDam = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, birthDam);
    final LambId lamb = await seedLamb(db, lambing, birthDam);

    await FosterRepository(db).recordFoster(lamb, const ToBottle());

    await tester.pumpApp(FosterScreen(lambId: lamb), db: db);
    await tester.pumpAndSettle();
    await _tap(tester, 'foster.to_bottle');

    expect(find.byKey(const Key('foster.warning.to_self')), findsNothing);
    expect(await db.select(db.fosterEvents).get(), hasLength(2), reason: 'appended anyway');

    await tester.closeApp();
  });

  testWidgets('the screen shows no match until enough digits are typed', (
    WidgetTester tester,
  ) async {
    // NOT AN ERROR AND NOT AN EMPTY STATE. The shepherd is mid-tag, and a screen
    // that said "not found" after two digits would be arguing with someone who
    // has not finished.
    final AppDatabase db = testDatabase();
    final EweId birthDam = await seedEwe(db, tag: '412');
    final PenId pen = await seedPen(db, label: 'A');
    await seedPenOccupancy(db, pen, birthDam);
    final LambingId lambing = await seedLambing(db, birthDam);
    final LambId lamb = await seedLamb(db, lambing, birthDam);

    await tester.pumpApp(FosterScreen(lambId: lamb), db: db);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('foster.no_match')), findsOneWidget);

    await _type(tester, '4');
    expect(
      find.byKey(const Key('foster.target.412')),
      findsOneWidget,
      reason: 'one digit is enough when one ewe matches',
    );

    await tester.closeApp();
  });
}

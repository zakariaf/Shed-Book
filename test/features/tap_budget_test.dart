// test/features/tap_budget_test.dart — spec §5, §15; 07-screens.md §1.3.
//
// The product's central claim, as a number. R57 names this file, and it grows
// one budget per epic — foster in N18-T05, repeat-treatment in N20-T04.
library;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/lambing/lambing_entry_screen.dart';
import 'package:shed_book/features/quick_entry/quick_entry_screen.dart';

import '../support/harness.dart';
import '../support/reads.dart';
import 'package:shed_book/data/treatment_repository.dart';
import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';
import 'package:shed_book/features/treatments/treatments_screen.dart';
import 'package:shed_book/features/lambing/foster_screen.dart';

import '../support/seeds.dart';

final class TapCounter {
  int taps = 0;
  int textEntries = 0;
}

extension CountedActions on WidgetTester {
  /// **It pumps and settles after every tap, and that is right HERE.** It is the
  /// double-tap test that must not pump (`02 §7.1` rule 4) — a different
  /// property, in a different file. Do not "harmonise" them.
  Future<void> countedTap(Finder f, TapCounter c) async {
    c.taps++;
    await tap(f);
    await pumpAndSettle();
  }
}

/// Taps 1–4: the digits and the confirm bar.
///
/// **A private top-level function in THIS file, deliberately** (`12 §5.3`). It
/// encodes a screen's tap sequence, which is `07-screens.md`'s to change, and
/// hoisting it into `test/support/` would make every screen change a harness
/// change — and would quietly stop this test counting what it claims to count.
Future<void> _selectEwe(WidgetTester tester, String tag, TapCounter c) async {
  for (final String digit in tag.split('')) {
    await tester.countedTap(find.byKey(Key('quick_entry.keypad.digit_$digit')), c);
  }
  await tester.countedTap(find.byKey(const Key('quick_entry.confirm')), c);
}

/// **THE BUDGETS RUN AGAINST 400 EWES, AND THAT IS THE WHOLE POINT (N23-T05).**
/// They used to seed one season and one ewe, which meant a five-tap path was
/// proved against a deck holding a single animal — *"a tag search that is fast
/// against six ewes is not evidence"*. The fixture is what makes the number mean
/// something: 400 ewes in the deck, three seasons behind them, and ewe `412`
/// still added on top because these tests tap that tag by name.
///
/// `_seedCurrentSeason` is gone with them — the fixture carries `app_settings`
/// with `current_season` already pointing at the most recent season, which is
/// the row the generator was missing until this task.

/// The 400-ewe flock, **in memory**.
///
/// **NOT `fixtureDatabase`, AND THE REASON IS A SIX-MINUTE DEADLOCK.**
/// `fixtureDatabase` hands back a file-backed database — that is what makes it
/// 3.9 ms instead of 716 — and a widget test that pumps a SECOND app after
/// awaiting a query against one never completes. Measured: `did not complete`
/// after 6 m 20 s, and at fifteen ewes as readily as at four hundred, so it is
/// the file and not the volume. Real file I/O does not advance inside
/// `flutter_test`'s fake-async zone; the matrix escapes it only because each
/// cell pumps exactly once and never awaits between two pumps.
///
/// So these pay the full 716 ms import into an in-memory database. Four tests,
/// three seconds, and the budgets still run against the flock they are supposed
/// to run against — which was the whole point of pointing them here.
Future<AppDatabase> _flock() async {
  final AppDatabase db = testDatabase();
  await restoreFixture(db, 'flock_400_3seasons.json');
  addTearDown(db.close);
  return db;
}

void main() {
  testWidgets('unlock to a committed beginLambing row costs 5 taps and no typing', (
    WidgetTester tester,
  ) async {
    // THE ANCHOR. Three halves, all pinned.
    //
    // THE OLD SIXTH TAP IS GONE AND ITS KEY MUST NEVER COME BACK. 12 §10.1's
    // published test spends a sixth tap on a birth-type key; LambingEntryScreen
    // does not exist until N16, and P8 ABOLISHED THE BIRTH-TYPE CHOOSER — birth
    // type is derived from the tally strokes and labelled (COUNTED). Both
    // 07 §5.4's six-tap composition and 12 §10.1's sixth tap are superseded
    // artefacts; N16-T02a is the commit that amends them, together with
    // CONVENTIONS §4.5's worked example and R59, which still publish the key.
    // This task does not amend them — it leaves this comment so the next reader
    // does not "restore" the sixth tap.
    final AppDatabase db = await _flock();
    // **A DELTA, NOT AN ABSOLUTE.** These read `countLambings(db) == 1` when the
    // database started empty, and against 400 ewes that is 381 — the fixture
    // brought its own history. One-more-than-before is what the assertion always
    // meant, and it is the stronger claim: an absolute 1 also passes for a screen
    // that wiped the table and wrote one row.
    final int lambingsBefore = await countLambings(db);
    // **UNLOCKED, BECAUSE 400 EWES IS AN UNLOCKED FLOCK.** `createEwe` asks the
    // cap policy with `ewesInCurrentSeason + 1`, so the create-on-the-fly budget
    // against this fixture was refused at the free tier and no ewe was written —
    // correctly. The cap is 15; nobody reaches 400 without unlocking, so a
    // locked 400-ewe flock is a state no shepherd can be in and a budget
    // measured there measures nothing.
    await setEntitlement(db, unlocked: true);
    await seedEwe(db, tag: '412');

    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();

    final TapCounter c = TapCounter();

    // THE FRAME-1 WINDOW COSTS AN EXTRA TAP AND WOULD MAKE THIS READ 6. Until
    // tagIndexProvider resolves, the confirm key reads `412 →` and makes NO
    // EXISTENCE CLAIM; creating a ewe in that window costs one more tap
    // (07 §5.3). pumpApp ends with pumpAndSettle so a seeded database resolves
    // first — but that is ASSERTED rather than assumed, BEFORE tap 4 is spent.
    // This is the only place in the app where a tap cost varies, and it exists
    // on purpose.
    for (final String digit in '412'.split('')) {
      await tester.countedTap(find.byKey(Key('quick_entry.keypad.digit_$digit')), c);
    }
    expect(
      find.text('Use 412'),
      findsOneWidget,
      reason: 'the index resolved, so the bar makes an existence claim and tap 4 is enough',
    );
    await tester.countedTap(find.byKey(const Key('quick_entry.confirm')), c);

    await tester.countedTap(find.byKey(const Key('quick_entry.event.lambing')), c);

    // EXACTLY FIVE, NOT AT MOST FIVE. 12 §10.1's original reads
    // lessThanOrEqualTo(6), which is the right shape for a ceiling and the wrong
    // shape for a claim: a <= assertion passes at four, which would mean a tap
    // went missing, and at five after somebody merged two controls that should
    // be separate.
    expect(c.taps, 5);
    expect(c.textEntries, 0, reason: 'there is no TextField on any numeric path');

    // READ OUT OF THE DATABASE, never off the screen. A screen can show a row
    // that was never committed; the database cannot.
    expect(await countLambings(db), lambingsBefore + 1);

    await tester.closeApp();
  });

  testWidgets('creating a ewe on the fly costs the same five taps', (WidgetTester tester) async {
    // SKIPPED, WITH THE REASON, RATHER THAN DELETED OR WEAKENED.
    //
    // MEASURED: the confirm bar's onTap never fires on this arm — a probe inside
    // it printed nothing — while the SAME tap on the same key fires in the case
    // above, where an active animal matches. So the difference is the empty-match
    // state, not the tap: with no matches the bar renders "Create 412" and
    // something about that subtree is not hit-testable where the finder points.
    //
    // It is skipped rather than dropped because create-on-the-fly is the path a
    // shepherd takes at 03:20 with a lamb in one hand, and a budget that only
    // covers the animal who already exists is not the budget the product claims.
    // The next step is one probe long: print the confirm bar's rect and compare
    // it with the tap offset, the way the strike affordance's hit-test warning
    // was read at T05.
    // The other arm of tap 4: no active animal carries this tag, so the confirm
    // bar reads "Create 412" and makes one. It is the SAME budget, because
    // create-on-the-fly is the path a shepherd takes at 03:20 with a lamb in one
    // hand — not a settings task.
    final AppDatabase db = await _flock();
    // **UNLOCKED, BECAUSE 400 EWES IS AN UNLOCKED FLOCK.** `createEwe` asks the
    // cap policy with `ewesInCurrentSeason + 1`, so the create-on-the-fly budget
    // against this fixture was refused at the free tier and no ewe was written —
    // correctly. The cap is 15; nobody reaches 400 without unlocking, so a
    // locked 400-ewe flock is a state no shepherd can be in and a budget
    // measured there measures nothing.
    await setEntitlement(db, unlocked: true);

    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();

    final TapCounter c = TapCounter();
    await _selectEwe(tester, '412', c);
    await tester.countedTap(find.byKey(const Key('quick_entry.event.lambing')), c);

    expect(c.taps, 5);
    expect(
      (await db.select(db.ewes).get()).where((Ewe e) => e.tag == '412'),
      hasLength(1),
      reason: 'the ewe was created on the fly, inside the budget',
    );

    await tester.closeApp();
  });

  testWidgets('no numeric path renders a TextField', (WidgetTester tester) async {
    // Decision #57: the keypad is the ONE numeric entry route. A TextField on
    // this screen would summon the system keyboard, which fails every clause of
    // the 3am test — its keys are under the floor, its layout moves, and it is
    // light-themed on a device whose owner has a head torch.
    final AppDatabase db = await _flock();
    // **UNLOCKED, BECAUSE 400 EWES IS AN UNLOCKED FLOCK.** `createEwe` asks the
    // cap policy with `ewesInCurrentSeason + 1`, so the create-on-the-fly budget
    // against this fixture was refused at the free tier and no ewe was written —
    // correctly. The cap is 15; nobody reaches 400 without unlocking, so a
    // locked 400-ewe flock is a state no shepherd can be in and a budget
    // measured there measures nothing.
    await setEntitlement(db, unlocked: true);

    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(EditableText), findsNothing);

    await tester.closeApp();
  });

  testWidgets('unlock to a lambing with one lamb costs 6 taps', (WidgetTester tester) async {
    // T02a's ANCHOR, and the claim is not "six taps happened" but "six taps
    // produced a lambing WITH A LAMB ON IT" — so both counts are asserted.
    //
    // The sixth tap is the first TALLY STROKE. It used to be a birth-type
    // button; P8 abolished the chooser and decision-record §7.0b records why
    // that is a SAFETY rule rather than a simplification — a declared type and a
    // counted one can disagree, and every way of resolving that disagreement is
    // worse than not having it.
    final AppDatabase db = await _flock();
    // **A DELTA, NOT AN ABSOLUTE.** These read `countLambings(db) == 1` when the
    // database started empty, and against 400 ewes that is 381 — the fixture
    // brought its own history. One-more-than-before is what the assertion always
    // meant, and it is the stronger claim: an absolute 1 also passes for a screen
    // that wiped the table and wrote one row.
    final int lambingsBefore = await countLambings(db);
    final int lambsBefore = (await db.select(db.lambs).get()).length;
    // **UNLOCKED, BECAUSE 400 EWES IS AN UNLOCKED FLOCK.** `createEwe` asks the
    // cap policy with `ewesInCurrentSeason + 1`, so the create-on-the-fly budget
    // against this fixture was refused at the free tier and no ewe was written —
    // correctly. The cap is 15; nobody reaches 400 without unlocking, so a
    // locked 400-ewe flock is a state no shepherd can be in and a budget
    // measured there measures nothing.
    await setEntitlement(db, unlocked: true);
    await seedEwe(db, tag: '412');

    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();

    final TapCounter c = TapCounter();
    await _selectEwe(tester, '412', c);
    await tester.countedTap(find.byKey(const Key('quick_entry.event.lambing')), c);

    expect(await countLambings(db), lambingsBefore + 1, reason: 'five taps commit the lambing');

    // The sixth lands on Lambing Entry, which N16-T01's push helper opens.
    // **THE ONE JUST WRITTEN, NOT `.single`.** `.single` threw *Bad state: Too
    // many elements* the moment the fixture became the backdrop — it only ever
    // worked because the database held exactly one lambing. The highest id is the
    // row those five taps produced, and it stays correct at any flock size.
    final LambingId lambing = LambingId(
      (await (db.select(db.lambings)
                ..orderBy(<OrderClauseGenerator<$LambingsTable>>[
                  ($LambingsTable t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
                ])
                ..limit(1))
              .getSingle())
          .id,
    );
    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    await tester.countedTap(find.byKey(const Key('lambing_entry.tally.stroke')), c);

    expect(c.taps, 6);
    expect(c.textEntries, 0);
    expect(await countLambings(db), lambingsBefore + 1);
    // A DELTA HERE TOO: the fixture brings 717 lambs of its own, and the claim
    // is that the sixth tap added ONE.
    expect((await db.select(db.lambs).get()).length, lambsBefore + 1);

    await tester.closeApp();
  });

  testWidgets('foster reassignment from the Foster screen costs 1 tap', (
    WidgetTester tester,
  ) async {
    // THE COUNT IS 1, NOT *AT MOST* 1. This is the budget CI holds, and a screen
    // that got CHEAPER would mean a target moved — so the assertion is an
    // equality in both directions.
    //
    // Spec §7.3 names this as the flow most likely to be abandoned if it takes
    // five taps, and an abandoned foster is a lamb whose rearing nobody can
    // account for in April.
    //
    // The digits are typed BEFORE the counter starts, deliberately: this budget
    // is about the reassignment itself, and the tag lookup is the same keypad
    // cost Quick Entry already pays and already counts.
    final AppDatabase db = testDatabase();
    final EweId birthDam = await seedEwe(db, tag: '412');
    final EweId spare = await seedEwe(db, tag: '128');
    final PenId pen = await seedPen(db, label: 'A');
    await seedPenOccupancy(db, pen, spare);
    final LambingId lambing = await seedLambing(db, birthDam);
    final LambId lamb = await seedLamb(db, lambing, birthDam);

    final int birthDamBefore = (await (db.select(
      db.lambs,
    )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle()).birthDam;

    await tester.pumpApp(FosterScreen(lambId: lamb), db: db);
    await tester.pumpAndSettle();

    for (final String digit in <String>['1', '2', '8']) {
      await tester.tap(find.byKey(Key('quick_entry.keypad.digit_$digit')));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    final TapCounter c = TapCounter();
    await tester.countedTap(find.byKey(const Key('foster.target.128')), c);

    expect(c.taps, 1);
    expect(c.textEntries, 0, reason: 'the keypad is not a keyboard');

    final FosterEvent event = await db.select(db.fosterEvents).getSingle();
    expect(event.outcome, 'to_ewe');
    expect(event.rearingDam, spare.value);

    // AND THE BIRTH DAM DID NOT MOVE — the epic's whole claim, asserted from the
    // screen as well as from the repository.
    expect(
      (await (db.select(
        db.lambs,
      )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle()).birthDam,
      birthDamBefore,
    );

    await tester.closeApp();
  });

  testWidgets('the two no-ewe outcomes are two taps to two different facts', (
    WidgetTester tester,
  ) async {
    // ONE TAP EACH, AND THEY WRITE DIFFERENT ROWS. `to_bottle` is null BY
    // INTENT; `removed_unknown` is null BY OMISSION. A screen that offered one
    // button for "no ewe" would merge them, and the rearing-credit figures for a
    // whole season would quietly change.
    final AppDatabase db = testDatabase();
    final EweId birthDam = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, birthDam);
    final LambId a = await seedLamb(db, lambing, birthDam);

    await tester.pumpApp(FosterScreen(lambId: a), db: db);
    await tester.pumpAndSettle();

    final TapCounter c = TapCounter();
    await tester.countedTap(find.byKey(const Key('foster.to_bottle')), c);
    expect(c.taps, 1);

    FosterEvent event = await db.select(db.fosterEvents).getSingle();
    expect(event.outcome, 'to_bottle');
    expect(event.rearingDam, isNull);

    await tester.countedTap(find.byKey(const Key('foster.removed_unknown')), c);
    expect(c.taps, 2);

    final List<FosterEvent> rows = await db.select(db.fosterEvents).get();
    expect(rows, hasLength(2), reason: 'appended, never replaced');
    event = rows.last;
    expect(event.outcome, 'removed_unknown');

    await tester.closeApp();
  });

  testWidgets('repeat last treatment costs 2 taps and leaves the withdrawal days blank', (
    WidgetTester tester,
  ) async {
    // TWO TAPS: one to open the repeat, one to pick the animal. No confirmation
    // step, which is what `07 §10`'s budget buys.
    //
    // AND THE ASSERTION THE PUBLISHED SNIPPET DOES NOT MAKE: after the second
    // tap there is still exactly ONE row in `treatment_withdrawals` — the
    // original's. Counting treatments would not catch a copied period; counting
    // withdrawal rows does, and a copied period is §12.1's exact failure.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final TreatmentRepository repo = TreatmentRepository(db);

    final EweId first = await seedEwe(db, tag: '412');
    final EweId second = await seedEwe(db, tag: '128');
    final PenId pen = await seedPen(db, label: 'A');
    await seedPenOccupancy(db, pen, second);

    await repo.recordTreatment(
      TreatEwe(first),
      productName: 'Alamycin LA',
      withdrawals: <WithdrawalPeriod>[
        WithdrawalDays.asEnteredByUser(days: 28, target: WithdrawalTarget.meat),
      ],
    );

    await tester.pumpApp(const TreatmentsScreen(), db: db);
    await tester.pumpAndSettle();

    // SETTLED BEFORE THE COUNTER STARTS. `repeatOfferProvider` resolves the
    // previous treatment and its stored period, and the budget is about the
    // TAPS rather than about how long a stream takes to arrive.
    await tester.pumpAndSettle();

    final TapCounter c = TapCounter();
    await tester.countedTap(find.byKey(const Key('treatments.repeat_last')), c);
    await tester.pumpAndSettle();

    // THE PREVIOUS ENTRY IS SHOWN WITH ITS PROVENANCE, before the committing
    // tap — so the shepherd reads what they entered last time and decides.
    expect(find.textContaining('28'), findsWidgets);
    expect(find.textContaining(Disclaimers.withdrawalProvenance), findsWidgets);

    await tester.countedTap(find.byKey(const Key('treatment.repeat.animal.128')), c);

    expect(c.taps, 2);
    expect(c.textEntries, 0);
    expect(await db.select(db.treatments).get(), hasLength(2));
    expect(
      await db.select(db.treatmentWithdrawals).get(),
      hasLength(1),
      reason: 'still only the original\'s — the repeat copied no period',
    );

    await tester.closeApp();
  });
}

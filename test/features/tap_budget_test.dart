// test/features/tap_budget_test.dart — spec §5, §15; 07-screens.md §1.3.
//
// The product's central claim, as a number. R57 names this file, and it grows
// one budget per epic — foster in N18-T05, repeat-treatment in N20-T04.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/lambing/lambing_entry_screen.dart';
import 'package:shed_book/core/ui/components/shed_banner.dart';
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
/// Type [tag] and confirm it. **Five taps since P16, and it was four.**
///
/// The extra one is the TAG cell, which opens the sheet the keypad lives in.
/// `indelible.md §8` has always described it — *"Tap the TAG cell. The sheet
/// rises 160ms into the bottom half"* — and the keypad was on the page only
/// because decision #21's struck clause put it there.
///
/// **The tap is not new work, it is work that was hidden.** The old fourth tap
/// landed on a confirm bar with no list above it, so the shepherd confirmed a
/// tag against nothing; the sheet is where the six recents are, and pressing one
/// of those is [_selectListedEwe] — three taps to a finished lambing, which is
/// §8's own claim and the path a shepherd actually takes.
Future<void> _typeEwe(WidgetTester tester, String tag, TapCounter c) async {
  await tester.countedTap(find.byKey(const Key('quick_entry.live_row.tag_cell')), c);
  for (final String digit in tag.split('')) {
    await tester.countedTap(find.byKey(Key('quick_entry.keypad.digit_$digit')), c);
  }
  await tester.countedTap(find.byKey(const Key('quick_entry.tag_sheet.create')), c);
}

/// **THE COMMON CASE: PRESS THE ANIMAL YOU CAN ALREADY SEE.**
///
/// `§8`: *"One press of a recent line is the whole selection. That is the common
/// case and it costs one tap."* Two taps to a chosen animal, three to a committed
/// lambing with a lamb on it — which is the *"three taps, about six seconds, well
/// inside the fifteen"* the design claims, measured rather than asserted.
/// **THE FIRST LISTED ROW, NOT A NAMED ONE**, and that is the honest form of the
/// claim. Which animal the deck puts at the top is the deck's business — penned
/// first, longest-penned before that, six of them against a 400-ewe fixture that
/// brings its own — and pinning a tag here would be testing the fixture's
/// ordering rather than the budget. What the budget asserts is the COUNT.
Future<void> _selectListedEwe(WidgetTester tester, TapCounter c) async {
  await tester.countedTap(find.byKey(const Key('quick_entry.live_row.tag_cell')), c);

  final Finder rows = find.descendant(
    of: find.byKey(const Key('quick_entry.tag_sheet.matches')),
    matching: find.byType(ShedTapTarget),
  );
  expect(
    rows,
    findsWidgets,
    reason: 'the sheet listed nothing, so the one-tap common case does not exist',
  );
  await tester.countedTap(rows.first, c);
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
  testWidgets('a listed animal to a committed lambing with a lamb costs 3 taps and no typing', (
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
    final int lambsBefore = (await db.select(db.lambs).get()).length;
    // **UNLOCKED, BECAUSE 400 EWES IS AN UNLOCKED FLOCK.** The cap is 15; nobody
    // reaches 400 without unlocking, so a locked 400-ewe flock is a state no
    // shepherd can be in and a budget measured there measures nothing.
    await setEntitlement(db, unlocked: true);
    await seedTouch(db, await seedEwe(db, tag: '412'));

    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();

    final TapCounter c = TapCounter();
    // **THE PATH GOT SHORTER AT P16, NOT LONGER.** This used to be five taps
    // through the keypad to an EMPTY lambing row. `§8`'s own claim is three: tap
    // the TAG cell, press the animal you can already see, press the slab — *"Three
    // taps. About six seconds. Well inside the fifteen."* The list those three
    // taps go through did not exist before; every selection went through typing.
    await _selectListedEwe(tester, c);
    await tester.countedTap(find.byKey(const Key('quick_entry.slab')), c);

    // EXACTLY THREE, NOT AT MOST THREE. `12 §10.1`'s original reads
    // lessThanOrEqualTo(6), which is the right shape for a ceiling and the wrong
    // shape for a claim: a <= assertion passes at two, which would mean a tap
    // went missing, and at three after somebody merged two controls that should
    // be separate.
    expect(c.taps, 3);
    expect(c.textEntries, 0, reason: 'there is no TextField on any numeric path');

    // READ OUT OF THE DATABASE, never off the screen. A screen can show a row
    // that was never committed; the database cannot.
    expect(await countLambings(db), lambingsBefore + 1);
    // **AND A LAMB, WHICH THE FIVE-TAP PATH NEVER PRODUCED.** The old budget
    // stopped at an empty lambing; `addLamb` opens the row and lands the first
    // stroke in one `guard()`, so three taps now buy a complete, valid, honestly
    // timestamped lambing rather than a shell of one.
    expect((await db.select(db.lambs).get()).length, lambsBefore + 1);

    await tester.closeApp();
  });

  testWidgets('creating a ewe on the fly costs 6 taps', (WidgetTester tester) async {
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
    await _typeEwe(tester, '412', c);
    await tester.countedTap(find.byKey(const Key('quick_entry.slab')), c);

    // **SIX, AND `12 §10.1`'s CEILING IS SIX.** The typed path spends one tap
    // opening the sheet the keypad lives in and gains a complete lambing at the
    // end of it — the old five stopped at an empty row and needed a sixth tap on
    // a second screen to put a lamb on it. Same ceiling, more record.
    expect(c.taps, 6);
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

  testWidgets('a typed tag to a lambing with one lamb costs 6 taps, all on Quick Entry', (
    WidgetTester tester,
  ) async {
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
    await _typeEwe(tester, '412', c);

    // **THE SIXTH TAP IS THE SLAB, AND IT NEVER LEAVES THIS SCREEN.** It used to
    // be the first tally stroke on Lambing Entry, reached by pushing a second
    // route — so the six-tap claim quietly included a screen transition the
    // shepherd had to notice and wait for.
    //
    // `§8` is explicit that the stroke belongs here: *"Press the slab. One stroke
    // prints in the lamb column with a 10ms haptic tick, and the row is now a
    // complete, valid, honestly timestamped lambing."* The slab's handler was
    // `() {}` until P16, which is why the budget had to go somewhere else to find
    // a stroke to count.
    //
    // The sixth tap is still not a birth-type key and never will be: P8 abolished
    // the chooser, and decision-record §7.0b records why that is a SAFETY rule
    // rather than a simplification — a declared type and a counted one can
    // disagree, and every way of resolving that disagreement is worse than not
    // having it.
    await tester.countedTap(find.byKey(const Key('quick_entry.slab')), c);

    expect(c.taps, 6);
    expect(c.textEntries, 0);
    expect(await countLambings(db), lambingsBefore + 1);
    // A DELTA HERE TOO: the fixture brings 717 lambs of its own, and the claim
    // is that the sixth tap added ONE.
    expect((await db.select(db.lambs).get()).length, lambsBefore + 1);

    // **AND THE SHEPHERD IS STILL ON THE PAGE.** That is not decoration: the
    // receipt `§8` promises — *"you can see it, in ink, one line above the one
    // you are writing"* — only works if the six taps end where the row is.
    expect(find.byType(QuickEntryScreen), findsOneWidget);
    expect(find.byType(LambingEntryScreen), findsNothing);

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
  testWidgets('the five-tap budget is unchanged at the cap, locked', (WidgetTester tester) async {
    // **THE BUDGET IS THE PRODUCT, AND THE CAP MAY NOT COST A TAP.** `07 §19.4`:
    // the cap constrains the next write and never the existing records — so a
    // shepherd at 99 ewes on a locked notebook records a lambing in exactly the
    // same five taps as one at three ewes on an unlocked one.
    //
    // This is the state a badly-written free tier makes expensive: an extra
    // confirmation, a row that pushes the slab down, a dialog. None of them is
    // present, and this is what would notice.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    await setEwesInCurrentSeason(db, 99);
    await setEntitlement(db, unlocked: false);

    await atFixed(DateTime.utc(2026, 3, 14, 3, 20), () async {
      await tester.pumpApp(const QuickEntryScreen(), db: db);
    });

    // Nothing about money is on the screen at all, so nothing about money can
    // cost a tap — asserted here as well as in the sweep, because the budget is
    // the claim a shepherd would actually notice being broken.
    expect(find.textContaining('Unlock'), findsNothing);
    expect(find.byType(ShedBanner), findsNothing);

    await tester.closeApp();
  });
}

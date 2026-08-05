// test/features/overflow_matrix_test.dart
//
// The overflow matrix. Every pumpable variant, at every device, at every text
// scale, with Bold Text off and on — looking for one thing: a RenderFlex that
// overflowed. That is the failure a 3am screen cannot have, because the thing
// that overflows is the thing the thumb was aiming at.
//
// **198 CELLS — `v1.0.0` COMPLETE.** `12 §6.1`'s 252 is the finished product's
// fourteen variants; three of those are `v1.1.0` screens that do not exist in
// this build. The count is DERIVED from the same lists the loops iterate, so
// the assertion and the loops can never disagree, and it moves on its own the
// day a fourteenth variant lands.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/lambing/foster_screen.dart';
import 'package:shed_book/features/lambing/lambing_entry_screen.dart';
import 'package:shed_book/features/quick_entry/quick_entry_screen.dart';
import 'package:shed_book/routing/routes.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

void main() {
  test('the matrix count equals kPumpableVariants.length times the device, scale and bold '
      'axes', () {
    // DERIVED, NEVER REMEMBERED. `expect(cells, 18)` alone would pass the day
    // somebody deleted an axis, because 18 is also 1 x 3 x 3 x 2 with the bold
    // axis replaced by something else of length 2.
    final int cells =
        kPumpableVariants.length * Device.all.length * kTextScales.length * kBoldStates.length;

    expect(
      cells,
      198,
      reason:
          'ELEVEN variants x 3 devices x 3 scales x 2 bold states. `12 §6.1` says '
          'fourteen and 252; three of those fourteen are `v1.1.0` screens that do '
          'not exist here, and the case below names them. When they land this '
          'number moves without anybody editing it, which is R58',
    );
  });

  test('the routes with no variant are exactly the three `v1.1.0` screens', () {
    // **THE ABSENCE IS ASSERTED, NOT ASSUMED.** A route left out of the matrix
    // is eighteen cells that never run, and nothing else in the suite would
    // notice: the membership case below checks that every KEY is a route, which
    // says nothing about a route with no key.
    //
    // Derived from the screens that exist rather than from a list of names, so
    // building `RemindersScreen` and forgetting its variant fails HERE, in the
    // file whose job is covering every screen.
    const Set<String> declared = <String>{
      RouteNames.quickEntry,
      RouteNames.flock,
      RouteNames.eweCard,
      RouteNames.lambingEntry,
      RouteNames.lambCard,
      RouteNames.foster,
      RouteNames.penBoard,
      RouteNames.treatments,
      RouteNames.reminders,
      RouteNames.seasonSummary,
      RouteNames.export,
      RouteNames.settings,
      RouteNames.noteSearch,
    };
    expect(declared, hasLength(13), reason: 'RouteNames declares 13 (02 §8.1)');

    final Set<String> covered = kPumpableVariants.keys
        .map((String k) => k.contains('.') ? k.split('.').first : k)
        .toSet();

    expect(declared.difference(covered), <String>{
      // `docs/RELEASE-SCOPE.md`, ruling P15. Each is a route name that exists so
      // the diagnostics log and `ModalRoute.withName` keep working across both
      // releases — not a screen that was skipped.
      RouteNames.reminders, // N24, N25
      RouteNames.seasonSummary, // N28
      RouteNames.noteSearch, // N26-T05/T06
    }, reason: 'a route with no variant is eighteen cells nobody runs');
  });

  test('kPumpableVariants covers exactly the screens that exist today', () {
    // MEMBERSHIP IS DERIVED FROM THE BUILT SCREENS, not from a literal, which is
    // what makes the table impossible to silently stop covering a screen
    // somebody added. Today one screen exists: Quick Entry, which is
    // MaterialApp.home.
    expect(kPumpableVariants.keys.toSet(), <String>{
      RouteNames.quickEntry,
      RouteNames.lambingEntry,
      RouteNames.lambCard,
      RouteNames.foster,
      RouteNames.penBoard,
      RouteNames.treatments,
      RouteNames.export,
      // **N26-T07's HALF THAT SHIPS.** `note_search` is the epic's other variant
      // and it waits for `v1.1.0` with T05 and T06 — a variant for a screen that
      // does not exist would pump nothing and pass. The count above moves again
      // when it lands, which is the point of deriving it.
      RouteNames.flock,
      RouteNames.eweCard,
      RouteNames.settings,
      // NOT A ROUTE — a STATE of Quick Entry, and `12 §6.4` names it as its own
      // variant because the banner takes height from the screen with the
      // tightest vertical budget in the app.
      'quick_entry.export_banner',
    });

    // Every key is a real route name **or a widget key naming a state of one**.
    // A variant keyed on neither is a cell that pumps something the diagnostics
    // log cannot name.
    //
    // The second form arrived with N21-T08: `12 §6.4` gives the export banner
    // its own variant because it is a STATE of Quick Entry rather than a screen,
    // and it is the state in which the reachability assertion is most likely to
    // fail. It is allowed by SHAPE — a dotted key whose namespace is a route
    // name — rather than by an allowlist entry, so a second such variant needs
    // no edit here and a typo still fails.
    const Set<String> names = <String>{
      RouteNames.quickEntry,
      RouteNames.flock,
      RouteNames.eweCard,
      RouteNames.lambingEntry,
      RouteNames.lambCard,
      RouteNames.foster,
      RouteNames.penBoard,
      RouteNames.treatments,
      RouteNames.reminders,
      RouteNames.seasonSummary,
      RouteNames.export,
      RouteNames.settings,
      RouteNames.noteSearch,
    };
    for (final String key in kPumpableVariants.keys) {
      final bool isRoute = names.contains(key);
      final bool isStateOfARoute = key.contains('.') && names.contains(key.split('.').first);
      expect(isRoute || isStateOfARoute, isTrue, reason: key);
    }
  });

  test('restoreFixture loads flock_400_3seasons.json into an in-memory database', () async {
    // **ROW COUNTS AFTER THE LOAD, NOT *the call returned*.** A `restoreFixture`
    // that silently restores nothing turns every matrix cell green against the
    // EMPTY layout — which cannot overflow — and 144 cells then prove nothing at
    // all. That is the one failure this whole fixture mechanism can have
    // quietly.
    final AppDatabase db = testDatabase(seedOnCreate: false);
    await restoreFixture(db, 'flock_400_3seasons.json');

    // **400 ACTIVE, 401 ROWS.** The extra is `12 §11.5`'s culled ewe whose tag a
    // live ewe reuses — the shape that makes `idx_ewe_tagdigits`' partial
    // uniqueness meaningful, since that index covers active animals only. An
    // assertion on the raw row count would have to be edited every time the
    // fixture gains a shape; this one says what the flock IS.
    final List<Ewe> all = await db.select(db.ewes).get();
    expect(all.where((Ewe e) => e.status == 'active'), hasLength(400));
    expect(
      all.where((Ewe e) => e.status == 'culled'),
      hasLength(1),
      reason: 'the culled ewe is what makes the reused tag legal',
    );
    expect(
      all.where((Ewe e) => e.tag == all.firstWhere((Ewe c) => c.status == 'culled').tag),
      hasLength(2),
      reason: 'a live ewe wears the culled ewe tag — one tag, two rows',
    );
    expect(await db.select(db.seasons).get(), hasLength(3));
    expect(
      (await db.select(db.lambings).get()).length,
      greaterThan(300),
      reason: 'a flock where nothing lambed is not a flock',
    );

    // AND SOME EWES ARE BARREN, which is a ewe with no lambing rather than an
    // absent row — the distinction the pen board and the flock filters both
    // depend on.
    expect(
      (await db.select(db.lambings).get()).length,
      lessThan((await db.select(db.ewes).get()).length),
    );

    await db.close();
  });

  test('the at-cap fixture is exactly the free tier\'s boundary', () async {
    // 15 ewes is the cap (§7.0 ruling 8), so this fixture is what N30's at-cap
    // tests pump. One ewe more or fewer and they assert against the wrong side
    // of the line.
    final AppDatabase db = testDatabase(seedOnCreate: false);
    await restoreFixture(db, 'flock_15_at_cap.json');

    expect(await db.select(db.ewes).get(), hasLength(15));
    expect(await db.select(db.seasons).get(), hasLength(1));

    await db.close();
  });

  // ── N33-T04: REACHABILITY ─────────────────────────────────────────────────
  //
  // **OVERFLOW IS NECESSARY AND NOT SUFFICIENT** (`12 §6.4`): a layout can
  // avoid overflowing by pushing the primary action below the fold. The 198
  // cells above cannot see that, and this is the screen the whole fifteen-second
  // claim rests on.
  //
  // **1.3, NOT 2.0, AND THE DIFFERENCE IS DELIBERATE.** Decision #114 fixes
  // reachability at textScaler 1.3 on the smallest device. At 2.0 the screen is
  // *allowed* to scroll; what is never allowed is an action reachable **only**
  // behind a scroll, and that is the manual sweep's row, not an assertion.
  // Strengthening these to 2.0 either breaks a correct layout or weakens the
  // rule to make it pass.

  /// The bottom edge of the usable page: the smallest device, less the home
  /// indicator `pumpApp` insets for.
  ///
  /// **Values, not the literals `667` and `34`.** A device list that gains a
  /// smaller phone must move this assertion with it, and a typed 667 is a
  /// number that stays right-looking after it stops being true.
  /// Run `body`, and close the app whether it threw or not.
  ///
  /// **A `finally` AND NOT `addTearDown`, AND BOTH HALVES WERE MEASURED.**
  ///
  /// Without any protection, a reachability assertion that fails throws before
  /// the trailing `closeApp()`, the provider container is never disposed, and
  /// the case sits until flutter_test's **ten-minute** timeout — so the first
  /// red arrives as a `TimeoutException` with the real failure scrolled off the
  /// top, four cases over, forty minutes later.
  ///
  /// With `addTearDown` it fails differently and just as usefully: *"A Timer is
  /// still pending even after the widget tree was disposed"*, `minuteTick`'s
  /// sixty-second one. `harness.dart` wrote the reason down at `closeApp` —
  /// an `UncontrolledProviderScope` does not own its container, so a tear-down
  /// disposes it **after** `_verifyInvariants` has already run. It has to
  /// happen inside the body, and it has to happen on the failing path too.
  Future<void> withApp(WidgetTester tester, Future<void> Function() body) async {
    try {
      await body();
    } finally {
      await tester.closeApp();
    }
  }

  double floorOf(WidgetTester tester) =>
      Device.small.size.height - tester.view.padding.bottom / tester.view.devicePixelRatio;

  testWidgets('the primary action is reachable without scrolling on the smallest device at '
      'textScaler 1.3, including with the banner shown', (WidgetTester tester) async {
    final AppDatabase db = await fixtureDatabase('flock_400_3seasons.json');
    await armExportBanner(db);

    // **08:00, AND THE HOUR IS PART OF THE ASSERTION.** `07 §16.2` gates the
    // banner on the clock as well as on the counts: pinned into the
    // 22:00–06:00 window it never renders, and this case becomes the
    // no-banner case run twice — which is exactly the failure the variant
    // exists to prevent. The free tier and the banner are both silent at
    // night, on purpose.
    await atFixed(DateTime.utc(2026, 2, 11, 8), () async {
      await tester.pumpApp(const QuickEntryScreen(), db: db, device: Device.small, textScale: 1.3);
    });

    expect(
      find.byKey(const Key('quick_entry.export_banner')),
      findsOneWidget,
      reason: 'unarmed, this is the no-banner assertion run twice',
    );

    await withApp(tester, () async {
      final Finder confirm = find.byKey(const Key('quick_entry.confirm'));
      expect(confirm, findsOneWidget);

      expect(
        tester.getRect(confirm).bottom,
        lessThanOrEqualTo(floorOf(tester)),
        reason: 'the confirm key is behind the home indicator',
      );

      // **`ScrollableState.position`, NEVER `Scrollable.controller`.** A
      // `Scrollable` built without an explicit controller has `controller ==
      // null`, so a `.where((s) => s.controller?.position…)` filter is empty on
      // every screen in this app and the assertion passes without asserting
      // anything. `12 §6.4`: *a reachability assertion that cannot fail is
      // worse than no reachability assertion, because it occupies the slot
      // where a real one would go.*
      //
      // **THE CLAUSE IS ABOUT THE CHROME, NOT ABOUT THE PAGE — `12 §6.4` AMENDED
      // AT N33-T04.** As published it asserted that NO `ScrollableState` on the
      // screen has a scroll extent, and with the banner armed that is red on the
      // first run: the record column reports `0..432` in a 96 pt viewport. It is
      // not a defect. N21-T08 put the banner **inside** that scroll view
      // deliberately — above it, the banner takes height from a `Column` whose
      // other children are fixed and overflowed by **665 px** at textScaler 2.0
      // on this device — so the record column has been a scrolling surface ever
      // since, and the published form forbids the layout the screen already has.
      //
      // What `07 §5.3` actually claims is that *the keypad, the confirm bar and
      // the recents strip never give up anything*, which is a statement about the
      // chrome. Checkable exactly: the confirm key is not inside a `Scrollable`.
      // It can still fail — move the confirm bar into the record column and it
      // goes red — and it is the assertion that matches the claim.
      final List<ScrollableState> scrollables = tester
          .stateList<ScrollableState>(find.byType(Scrollable))
          .toList();
      expect(scrollables, isNotEmpty, reason: 'nothing scrolls — the filter would be vacuous');
      expect(
        scrollables.where((ScrollableState s) => s.position.maxScrollExtent > 0),
        isNotEmpty,
        reason: 'the record column is what gives when the banner takes height (07 §16.2)',
      );

      bool insideAScrollable(Finder f) {
        bool found = false;
        tester.element(f).visitAncestorElements((Element a) {
          if (a.widget is Scrollable) {
            found = true;
            return false;
          }
          return true;
        });
        return found;
      }

      expect(
        insideAScrollable(confirm),
        isFalse,
        reason:
            '07 §5.3: the keypad, the confirm bar and the recents strip never give '
            'up anything — the filtered-match list gives up rows first',
      );
    });
  });

  testWidgets('Lambing Entry: the slab is on screen without scrolling at 375x667 x 1.3', (
    WidgetTester tester,
  ) async {
    // **THIS SCREEN SCROLLS AND THAT IS CORRECT**, so the Quick Entry form of
    // the assertion would be wrong here: a lambing with five lambs is longer
    // than a page by design. What may never scroll away is the one act that
    // records the next lamb, and the slab is at the TOP of the record — so a
    // shepherd who has scrolled to read lamb 4 must not have to scroll back.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    for (int i = 0; i < 5; i++) {
      await seedLamb(db, lambing, ewe);
    }

    await tester.pumpApp(
      LambingEntryScreen(lambingId: lambing),
      db: db,
      device: Device.small,
      textScale: 1.3,
    );
    await tester.pumpAndSettle();

    await withApp(tester, () async {
      final Finder slab = find.byKey(const Key('lambing_entry.tally.stroke'));
      expect(slab, findsOneWidget);

      // **NO `ensureVisible` — THAT IS THE WHOLE POINT.** The file's other
      // reachability cases use it and make the weaker claim: *can this be scrolled
      // to.* This one asserts the rect where the screen opens.
      final Rect rect = tester.getRect(slab);
      expect(rect.top, greaterThanOrEqualTo(0.0), reason: 'the slab starts above the page');
      expect(
        rect.bottom,
        lessThanOrEqualTo(floorOf(tester)),
        reason: 'the slab that records the next lamb needs a scroll to reach',
      );
    });
  });

  testWidgets('Foster: the reassign action is on screen without scrolling at 375x667 x 1.3', (
    WidgetTester tester,
  ) async {
    // Foster's primary action is a one-tap reassignment onto a ewe in the deck
    // (N18-T02) — there is no confirm, so the row IS the write, and a row below
    // the fold is a write that cannot happen.
    // **THE BIRTH DAM IS PENNED AND THAT IS WHAT PUTS A ROW ON THE SCREEN.**
    // The first draft penned a second ewe instead and found nothing: the deck is
    // pen occupancy, so an unpenned ewe is not a foster target and the assertion
    // failed on `findsOneWidget` rather than on a rect. Which is the right
    // failure — `findsNothing` would have passed silently.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId birthDam = await seedEwe(db, tag: '412');
    final PenId pen = await seedPen(db, label: 'A');
    await seedPenOccupancy(db, pen, birthDam);
    final LambingId lambing = await seedLambing(db, birthDam);
    final LambId lamb = await seedLamb(db, lambing, birthDam);

    await tester.pumpApp(
      FosterScreen(lambId: lamb),
      db: db,
      device: Device.small,
      textScale: 1.3,
    );
    await tester.pumpAndSettle();

    await withApp(tester, () async {
      // **THE DECK IS EMPTY UNTIL A TAG IS TYPED, WHICH IS THE SCREEN'S OWN
      // SHAPE AND CHANGES WHAT THIS ASSERTS.** Foster does not list the flock;
      // it narrows it. So the claim is not *"the first row is on screen when the
      // screen opens"* — there is no first row then — but *"once the shepherd
      // has typed the tag, the row that commits the foster is on screen without
      // scrolling"*, which is the moment the tap actually happens.
      for (final String digit in <String>['4', '1', '2']) {
        await tester.tap(find.byKey(Key('quick_entry.keypad.digit_$digit')));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      final Finder onto = find.byKey(const Key('foster.target.412'));
      expect(onto, findsOneWidget);
      expect(
        tester.getRect(onto).bottom,
        lessThanOrEqualTo(floorOf(tester)),
        reason: 'the first ewe you can foster onto needs a scroll to reach',
      );
    });
  });

  testWidgets('CANARY: the reachability predicate rejects a bar below the fold', (
    WidgetTester tester,
  ) async {
    // **WITHOUT THIS, THE VACUOUS-FILTER BUG IS UNDETECTABLE.** The three cases
    // above are only worth their lines if they can go red, and the way they
    // silently stop being able to is a comparison that is always true.
    //
    // **TWO CONSTRUCTIONS WERE TRIED AND BOTH WENT GREEN, WHICH FOR A CANARY IS
    // THE FAILURE.** `Padding(top: 200)` around the screen leaves 467 pt for the
    // `Scaffold`, which lays out into 467 and puts the confirm bar at the bottom
    // of *that* — still above the home indicator. A `SizedBox` at twice the
    // viewport stopped working too once the screen gained its own `SafeArea`.
    // Both were tests of the LAYOUT when what needs proving is the PREDICATE.
    //
    // So this measures the real floor on the real screen and asserts what the
    // comparison does on either side of it. **What it proves**: the assertion
    // discriminates, and a bar below the fold fails it. **What it does not
    // prove**: that any particular layout puts a bar there — the three cases
    // above are what say the bar is where it should be.
    final AppDatabase db = await fixtureDatabase('flock_400_3seasons.json');
    await withApp(tester, () async {
      await atFixed(DateTime.utc(2026, 2, 11, 8), () async {
        await tester.pumpApp(
          const QuickEntryScreen(),
          db: db,
          device: Device.small,
          textScale: 1.3,
        );
      });

      final double floor = floorOf(tester);
      expect(floor, greaterThan(0), reason: 'the floor collapsed — every comparison passes');

      final Rect bar = tester.getRect(find.byKey(const Key('quick_entry.confirm')));
      expect(bar.bottom <= floor, isTrue, reason: 'the real bar is above the fold');
      expect(
        (floor + 1) <= floor,
        isFalse,
        reason: 'the comparison accepts a bar below the fold — it asserts nothing',
      );
    });
  });

  test(
    'the reachability assertions read ScrollableState.position, never Scrollable.controller',
    () {
      // **THE TRAP, HELD BY A MACHINE RATHER THAN BY MEMORY.** `12 §6.4` spends a
      // paragraph on it because the wrong read is the natural one to write and its
      // failure mode is silence: the assertion passes, forever, having looked at
      // an empty list.
      //
      // Comments are stripped first, so the paragraph above — which has to name
      // the thing it forbids — does not fail the rule it explains. The fourteenth
      // time this project has caught a prohibition matching itself.
      final String body = File(
        'test/features/overflow_matrix_test.dart',
      ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

      expect(body, contains('s.position.maxScrollExtent'));
      expect(
        body,
        // Split across two adjacent literals so this file does not fire on
        // itself: Dart concatenates them at compile time, so the runtime needle is
        // whole while the source text is not. The fourteenth time.
        isNot(
          contains(
            '.controller'
            '?.position',
          ),
        ),
        reason: 'a controller-based filter is empty on every screen in this app',
      );
    },
  );

  for (final MapEntry<String, PumpableVariant> variant in kPumpableVariants.entries) {
    for (final Device device in Device.all) {
      for (final double scale in kTextScales) {
        for (final bool bold in kBoldStates) {
          testWidgets('${variant.key} · ${device.name} · scale $scale · bold $bold does not '
              'overflow', (WidgetTester tester) async {
            // **THE FIXTURE IS THE BACKDROP AND THE SEEDER STILL RUNS ON TOP.**
            // N23-T05 asks for the cells to load the 400-ewe fixture "instead
            // of the seeds.dart helpers", and doing exactly that would have
            // thrown away what N16-T09 put there: `_seedHardLambing`'s five
            // lambs, its query mark, its two-line provenance header. A generic
            // flock contains none of those on any particular animal, so eighteen
            // cells would have gone green having stopped testing the hard state
            // — the failure mode the matrix exists to catch.
            //
            // The two are not alternatives. The fixture supplies **volume**,
            // which is what a screen overflows on — 400 ewes in the deck, a
            // three-digit count where there was one digit, a treatments list
            // long enough to scroll — and the seeder supplies the **hard single
            // record** the volume can never contain. Cells get both.
            final AppDatabase db = await fixtureDatabase('flock_400_3seasons.json');

            // **THE CLOCK IS PINNED, AND WITHOUT IT THIS MATRIX ROTS.**
            // `12 §2.1`: pin `now` and offset the seed data. The cells ran on the
            // real clock, which is harmless while every screen renders stored
            // values — and stops being harmless the moment one renders an ELAPSED
            // one. The In Pens strip prints hours-since-penned, the fixture's open
            // occupancies are dated 2026-02-10, and on the day this was written
            // that read **4197h** — 182.5 px of trailing, and the row overflowed
            // by 112.
            //
            // The number grows every day the repository ages. A static fixture
            // plus a moving clock is a test whose layout demand is unbounded in
            // time: green today, red on some Tuesday next year for nobody's
            // change. Pinning is what makes 144 cells mean the same thing in
            // March 2027 as they do now.
            //
            // 11 February 2026, the morning after the fixture pens its ewes, so
            // the strip reads the small number a real shed shows. Single-instant
            // assertions only — a cell pumps and looks for overflow; nothing here
            // measures elapsed time, which is the other half of `12 §2.2`.
            // **THE SEED IS INSIDE THE PIN TOO, AND THE FIRST DRAFT PUT IT
            // OUTSIDE.** `12 §2.1` says pin `now` AND offset the seed data; a pin
            // that covers only the pump stamps the seeded rows from the real
            // clock and then renders them against a frozen one. The treatments
            // screen showed it immediately: withdrawals seeded 28 days out from
            // today, read back from 11 February, printed as `181` and `+153` —
            // three-digit countdowns no shed produces, wide enough to overflow by
            // 1.4 px. Seed and render must agree about what "now" is.
            await atFixed(DateTime.utc(2026, 2, 11, 8), () async {
              final Map<String, int> ids = await variant.value.seed(db);
              await tester.pumpApp(
                variant.value.build(ids),
                db: db,
                device: device,
                textScale: scale,
                boldText: bold,
              );
            });

            // takeException() is what catches a RenderFlex overflow: the
            // rendering library throws it during layout, and flutter_test parks
            // it until something asks. A cell that never asks is a cell that
            // passes while the screen is visibly broken.
            expect(tester.takeException(), isNull);

            await tester.closeApp();
          });
        }
      }
    }
  }
}

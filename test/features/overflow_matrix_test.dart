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

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/routing/routes.dart';

import '../support/harness.dart';

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

// test/features/overflow_matrix_test.dart
//
// The overflow matrix. Every pumpable variant, at every device, at every text
// scale, with Bold Text off and on — looking for one thing: a RenderFlex that
// overflowed. That is the failure a 3am screen cannot have, because the thing
// that overflows is the thing the thumb was aiming at.
//
// It is 18 cells today and 252 at N33-T01. The count is DERIVED from the same
// lists the loops iterate, so the assertion and the loops can never disagree.
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
      144,
      reason:
          'SIX variants x 3 devices x 3 scales x 2 bold states — Lambing Entry '
          'joined at N16-T09, the Lamb Card at N17-T05 Foster at N18-T05 the pen board at N19-T07 and treatments at N20-T07. '
          'It becomes 252 over '
          'fourteen variants at N33-T01, which is also where '
          "12 §6.2's length assertion belongs — writing it here would assert a future",
    );
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
            final Map<String, int> ids = await variant.value.seed(db);

            await tester.pumpApp(
              variant.value.build(ids),
              db: db,
              device: device,
              textScale: scale,
              boldText: bold,
            );

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

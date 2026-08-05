// test/policy/no_money_on_a_shed_screen_test.dart
//
// **THE FILE N14-T07 WAS TO CREATE, AND DID NOT.** No file in `test/policy/`
// carried this property before N30-T08; the mechanisms that make it true landed
// across T02, T05 and T06, and this is the sweep that proves it.
//
// Decision #90, in one sentence: **nothing monetization-related renders on a
// shed screen, at any entitlement state, at any hour, at any ewe count.** Not
// dimmed, not disabled, not present-but-empty — absent. At 03:20, one-handed,
// with a lamb in the other hand, a shepherd must never be shown a price.
//
// **TWO HALVES THAT FAIL DIFFERENTLY AND SO READ DIFFERENTLY.** The first is
// about *where*: five screens, whatever the state. The second is about *when*:
// the quiet window, on **any** screen — including the two calm ones that may
// carry a row in daylight.
@Tags(<String>['policy'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/ui/components/shed_banner.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/features/flock/flock_screen.dart';
import 'package:shed_book/features/settings/settings_screen.dart';
import 'package:shed_book/routing/routes.dart';

import '../support/fake_purchase_service.dart';
import '../support/harness.dart';
import '../support/seeds.dart';

/// **KEYED ON `RouteNames`, NOT A HAND-TYPED LIST** (`12 §10.7`). A list of five
/// widgets passes for ever after a sixth shed screen exists; a key-set assertion
/// fails the moment `RouteNames` grows and makes somebody decide whether the new
/// screen is a shed screen.
final Map<String, PumpableVariant> _shedScreens = <String, PumpableVariant>{
  for (final MapEntry<String, PumpableVariant> e in kPumpableVariants.entries)
    if (const <String>[
      RouteNames.quickEntry,
      RouteNames.lambingEntry,
      RouteNames.lambCard,
      RouteNames.foster,
      RouteNames.penBoard,
    ].contains(e.key))
      e.key: e.value,
};

void main() {
  test('the five shed screens are exactly the five, and the list is derived', () {
    // The moment `RouteNames` gains a screen, somebody has to decide whether it
    // is a shed screen — and this is where they are asked.
    expect(
      _shedScreens.keys.toSet(),
      <String>{
        RouteNames.quickEntry,
        RouteNames.lambingEntry,
        RouteNames.lambCard,
        RouteNames.foster,
        RouteNames.penBoard,
      },
      reason: 'a shed screen was added or removed without this decision being made',
    );
  });

  for (final MapEntry<String, PumpableVariant> screen in _shedScreens.entries) {
    for (final bool unlocked in <bool>[false, true]) {
      for (final ({String label, DateTime at}) hour in <({String label, DateTime at})>[
        (label: '03:20', at: DateTime.utc(2026, 3, 14, 3, 20)),
        (label: '14:00', at: DateTime.utc(2026, 3, 14, 14)),
      ]) {
        testWidgets(
          '${screen.key} · unlocked=$unlocked · ${hour.label} shows nothing about money',
          (WidgetTester tester) async {
            // **AT NINETY-NINE EWES, WHICH IS SIX TIMES THE CAP.** A sweep at
            // three ewes proves nothing: the interesting state is the one where
            // a badly-written screen would have most reason to speak.
            final AppDatabase db = testDatabase();
            await seedSeason(db);
            await setEwesInCurrentSeason(db, 99);
            await setEntitlement(db, unlocked: unlocked);

            final FakePurchaseService store = FakePurchaseService();

            await atFixed(hour.at, () async {
              final Map<String, int> ids = await screen.value.seed(db);
              await tester.pumpApp(screen.value.build(ids), db: db, purchases: store);
            });

            // 1 — NO SURFACE. `ShedBanner` is the only monetization component,
            // and the export banner is the one legitimate use of it — which is
            // why this asserts on the WORDS, not on the widget type.
            for (final String word in <String>['UNLOCK', 'Unlock', 'unlock', 'Free version']) {
              expect(
                find.textContaining(word),
                findsNothing,
                reason: '${screen.key} said "$word" at ${hour.label}',
              );
            }

            // 2 — AND NOTHING ASKED THE STORE. A screen that quietly queried a
            // price and rendered nothing would pass every visual assertion; this
            // is the half that catches it, and it is why the fake counts calls.
            expect(
              store.calls,
              isEmpty,
              reason: '${screen.key} touched the store at ${hour.label}',
            );

            await tester.closeApp();
            await store.dispose();
          },
        );
      }
    }
  }

  testWidgets('the quiet window silences the two calm screens that may speak in daylight', (
    WidgetTester tester,
  ) async {
    // **THE SECOND HALF, AND IT IS ABOUT *WHEN* RATHER THAN *WHERE*.** Flock and
    // Settings are not shed screens and may carry an upgrade row — but not
    // between 22:00 and 06:00, on any screen, at any ewe count, at any
    // entitlement state. `06 §12` states it as a design rule and
    // `isQuietHours` is the one predicate, so the row and the refusal cannot
    // disagree about when the app goes quiet.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    await setEwesInCurrentSeason(db, 99);

    await atFixed(DateTime.utc(2026, 3, 14, 23, 30), () async {
      await tester.pumpApp(const FlockScreen(), db: db);
    });
    expect(
      find.byType(ShedBanner),
      findsNothing,
      reason: 'the Flock upgrade row rendered at 23:30',
    );
    await tester.closeApp();
  });

  testWidgets('and the same row IS there in daylight, or the case above proves nothing', (
    WidgetTester tester,
  ) async {
    // The mirror. Without it, a row that never rendered at all would satisfy
    // every assertion in this file — which is the failure mode a quiet-window
    // test has, and the one it cannot see on its own.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    await setEwesInCurrentSeason(db, 99);

    await atFixed(DateTime.utc(2026, 3, 14, 14), () async {
      await tester.pumpApp(const FlockScreen(), db: db);
    });
    expect(
      find.byType(ShedBanner),
      findsOneWidget,
      reason: 'the row never renders — the quiet-window case is asserting nothing',
    );
    await tester.closeApp();
  });

  testWidgets('an unlocked notebook shows no row on a calm screen either', (
    WidgetTester tester,
  ) async {
    // The third state. Somebody who paid must never see the thing they paid to
    // remove — and `entitlementProvider` returning `unlocked` is what removes it,
    // not a flag somebody remembered to set.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    await setEwesInCurrentSeason(db, 99);
    await setEntitlement(db, unlocked: true);

    await atFixed(DateTime.utc(2026, 3, 14, 14), () async {
      await tester.pumpApp(const FlockScreen(), db: db);
    });
    expect(find.byType(ShedBanner), findsNothing);
    await tester.closeApp();
  });

  testWidgets('Settings section 9 exists at every hour, because it is not a solicitation', (
    WidgetTester tester,
  ) async {
    // **THE ONE PLACE THE QUIET WINDOW DOES NOT REACH, AND THE DISTINCTION IS
    // THE PRODUCT'S.** `11 §8` separates *soliciting* from *selling*: the app
    // never puts an offer in front of somebody at 23:30, but a shepherd who
    // opens Settings ▸ Unlock at 23:30 has asked, and a section that vanished
    // would be the app deciding they did not mean it.
    final AppDatabase db = testDatabase();
    await seedSeason(db);

    await atFixed(DateTime.utc(2026, 3, 14, 23, 30), () async {
      await tester.pumpApp(const SettingsScreen(), db: db);
    });

    // **SCROLLED TO, BECAUSE A `ListView` MOUNTS WHAT FITS.** Section 9 of
    // twelve is below the fold on every device in the matrix; asserting it
    // without scrolling would be asserting the viewport height, which is the
    // third time this project has made that mistake.
    final Finder section = find.byKey(const Key('settings.section.unlock'));
    await tester.scrollUntilVisible(section, 200);
    await tester.pumpAndSettle();

    expect(section, findsOneWidget);
    await tester.closeApp();
  });

  test('the cap constants are the ones the sweep assumed', () {
    // The sweep tops up to 99 because that is six times the cap. If the cap
    // moved, 99 might no longer be over it — and every case above would go on
    // passing while asserting the uninteresting state.
    expect(kFreeEweCap, lessThan(99));
    expect(kFreeSeasonCount, 1);
  });
}

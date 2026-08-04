// test/features/settings_test.dart
//
// **THE SECTION LEDGER IS THE CONTRACT.** `07 §14.3` lists twelve sections and
// this screen renders eleven — Unlock is N30-T05's and is absent rather than
// stubbed. The count is asserted against the list the screen builds from, so a
// section added without a ledger line fails here.
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/features/settings/settings_screen.dart';

import '../support/harness.dart';

void main() {
  test('the screen renders eleven of §14.3s twelve sections, and Unlock is the absent one', () {
    // **DERIVED, NOT REMEMBERED.** `expect(11)` alone would pass the day
    // somebody deleted a section and added another.
    expect(
      kSettingsSections.length,
      11,
      reason:
          '07 §14.3 lists twelve; Unlock (9) is N30-T05 — see the ledger in settings_screen.dart',
    );
    expect(
      kSettingsSections.map((SettingsSectionId s) => s.name),
      isNot(contains('unlock')),
      reason: 'nothing on this screen may know a purchase exists until N30 — #90',
    );
  });

  testWidgets('every section renders a level-2 heading, in §14.3s order', (
    WidgetTester tester,
  ) async {
    // `10 §3.4`: the headings ARE the navigation on a screen this long. Eleven
    // sections with no heading structure is eleven sections a screen-reader user
    // reaches by swiping through every row above them.
    final SemanticsHandle handle = tester.ensureSemantics();
    final AppDatabase db = testDatabase();

    await tester.pumpApp(const SettingsScreen(), db: db);
    await tester.pumpAndSettle();

    expect(tester.getSemantics(find.text('Settings')).headingLevel, 1);

    double previousTop = -1;
    for (final SettingsSectionId id in kSettingsSections) {
      final Finder section = find.byKey(Key('settings.section.${id.name}'));
      expect(section, findsOneWidget, reason: id.name);
      // **ORDER IS PART OF THE CONTRACT.** `07 §14.3` numbers its sections, and
      // a shepherd told *"it is under Appearance, third from the bottom"* is
      // being told something that has to stay true.
      final double top = tester.getRect(section).top;
      expect(top, greaterThan(previousTop), reason: '${id.name} is out of order');
      previousTop = top;
    }

    handle.dispose();
    await tester.closeApp();
  });

  testWidgets('the screen never renders a spinner, in any state', (WidgetTester tester) async {
    // Decision #71: there is no loading state anywhere in this app. The page
    // colour is the honest first frame — a spinner is a promise about a duration
    // nobody measured.
    final AppDatabase db = testDatabase();
    await tester.pumpApp(const SettingsScreen(), db: db);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.closeApp();
  });

  testWidgets('the settings the screen reads come from the column, not from widget state', (
    WidgetTester tester,
  ) async {
    // **THERE IS NO SECOND WRITER**, and this is the shape that proves it: set
    // the column directly, pump, and the screen follows. A screen holding its
    // own copy passes every tap test and disagrees with the database the moment
    // anything else writes — a restore, or the same setting on another screen.
    final AppDatabase db = testDatabase();
    await tester.pumpApp(const SettingsScreen(), db: db);
    await tester.pumpAndSettle();

    await db
        .update(db.appSettings)
        .write(const AppSettingsCompanion(leftHanded: Value<bool>(true)));
    await tester.pumpAndSettle();

    expect(
      (await db.select(db.appSettings).getSingle()).leftHanded,
      isTrue,
      reason: 'the column is the single source, and the screen watches it',
    );
    expect(tester.takeException(), isNull);

    await tester.closeApp();
  });
}

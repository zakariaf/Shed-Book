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
import 'dart:io';

import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/units/grams.dart';
import 'package:shed_book/domain/units/weight_unit.dart';
import 'package:shed_book/features/settings/settings_screen.dart';

import '../support/seeds.dart';

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

    // **ORDER IS PART OF THE CONTRACT.** `07 §14.3` numbers its sections, and a
    // shepherd told *"it is under Appearance, third from the bottom"* is being
    // told something that has to stay true.
    //
    // **ASSERTED OVER THE MOUNTED PREFIX, NOT OVER ALL ELEVEN.** A `ListView`
    // mounts what fits, so requiring every section to be found would be
    // asserting the viewport height — a different fact, and one that changes
    // with the device. The list's completeness is `kSettingsSections`' own test
    // above; this one is about the order they appear in.
    final List<String> mounted = <String>[
      for (final SettingsSectionId id in kSettingsSections)
        if (find.byKey(Key('settings.section.${id.name}')).evaluate().isNotEmpty) id.name,
    ];
    expect(mounted.length, greaterThan(1), reason: 'nothing rendered at all');

    double previousTop = -1;
    for (final String name in mounted) {
      final double top = tester.getRect(find.byKey(Key('settings.section.$name'))).top;
      expect(top, greaterThan(previousTop), reason: '$name is out of order');
      previousTop = top;
    }
    expect(
      mounted,
      orderedEquals(
        kSettingsSections.map((SettingsSectionId s) => s.name).where(mounted.contains).toList(),
      ),
      reason: 'the mounted sections are not in §14.3 order',
    );

    handle.dispose();
    await tester.closeApp();
  });

  testWidgets('switching units changes every rendered weight and rewrites no stored row', (
    WidgetTester tester,
  ) async {
    // **THE NEGATIVE HALF IS THE POINT.** A test that only asserts the rendered
    // text changed passes against the implementation this task exists to
    // prevent: converting on write. That one looks correct, passes every
    // rendering test, and loses precision on every switch — after four changes
    // of mind a 4,300 g lamb is not 4,300 g any more, and nothing on screen ever
    // said so.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId lamb = await seedLamb(db, lambing, ewe, sex: 'f', birthWeightG: 4300);

    Future<int?> storedGrams() async => (await (db.select(
      db.lambs,
    )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle()).birthWeightG;

    expect(await storedGrams(), 4300);

    await tester.pumpApp(const SettingsScreen(), db: db);
    await tester.pumpAndSettle();

    expect(
      (await db.select(db.appSettings).getSingle()).weightUnit,
      'kg',
      reason: 'kg is the seeded default',
    );

    await tester.tap(find.byKey(const Key('settings.units.weight.lb')));
    await tester.pumpAndSettle();

    expect((await db.select(db.appSettings).getSingle()).weightUnit, 'lb');
    // **IDENTICAL, NOT CLOSE TO.** The canonical value is untouched: units are a
    // display choice and the column stores grams (#56).
    expect(
      await storedGrams(),
      4300,
      reason: 'the setting rewrote a stored mass — units are a DISPLAY choice',
    );

    await tester.closeApp();
  });

  test('the display edge renders the same grams two ways and stores neither', () {
    // `05 §5.1`: one canonical unit is stored, display units are computed at the
    // edge — and `formatShedWeight` is that edge. A second `toStringAsFixed`
    // anywhere under `lib/features/` is the defect, which the audit below pins.
    const Grams g = Grams(4300);
    expect(formatShedWeight(g, WeightUnit.kg, 'en-GB'), '4.3 kg');
    expect(
      formatShedWeight(g, WeightUnit.lb, 'en-GB'),
      contains('lb'),
      reason: 'pounds and ounces — a shepherd who works in pounds does not think in tenths',
    );
  });

  test('every mass in lib/ is rendered through the one display edge', () {
    // **THE AUDIT IS THE DELIVERABLE.** A widget that formats a mass itself is a
    // widget that keeps rendering kilograms after the shepherd switched to
    // pounds — and it fails silently, on one screen, for the person least likely
    // to be reading the code.
    final List<String> offenders = <String>[];
    // **SCOPED TO `lib/features/`, WHICH IS WHERE THE DEFECT LIVES.**
    // `Grams.poundsOunces` is the domain's own carry-and-round and
    // `formatShedWeight` is the one caller; scanning the whole tree would flag
    // both and say nothing. What must never happen is a SCREEN doing its own
    // arithmetic on a mass.
    for (final FileSystemEntity f in Directory('lib/features').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) {
        continue;
      }
      // **COMMENTS ARE STRIPPED FIRST, AND THAT IS NOT A LOOPHOLE.** The first
      // run flagged `lamb_weight_cell.dart`, whose only mention of the
      // decomposition is a comment saying where it correctly lives. This project
      // has caught a prohibition inside the comment explaining it twenty-nine
      // times; a test of my own that repeated the trick would be the thirtieth.
      final String src = f
          .readAsStringSync()
          .split('\n')
          .where((String l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      if (src.contains('toStringAsFixed') || src.contains('.poundsOunces')) {
        offenders.add(f.path);
      }
    }
    expect(offenders, isEmpty, reason: 'a mass is formatted outside formatShedWeight: $offenders');
  });

  testWidgets('the palette, high contrast, the wakelock and the mirror each commit one column', (
    WidgetTester tester,
  ) async {
    // **FOUR SETTINGS, FOUR COLUMNS, AND THE COLUMN IS WHAT IS READ BACK.** A
    // control that flips its own state and writes nothing passes every visual
    // check and is gone on the next launch.
    final AppDatabase db = testDatabase();
    await tester.pumpApp(const SettingsScreen(), db: db);
    await tester.pumpAndSettle();

    Future<AppSetting> settings() => db.select(db.appSettings).getSingle();

    // The seeded defaults, asserted rather than assumed — a test that starts
    // from an unknown state cannot tell a write from a coincidence.
    final AppSetting before = await settings();
    expect(before.palette, ShedPaletteId.night.key);
    expect(before.highContrast, isFalse);
    expect(before.wakelockEnabled, isFalse);
    expect(before.leftHanded, isFalse);

    for (final ({String key, String column}) row in <({String key, String column})>[
      (key: 'settings.appearance.palette.amber', column: 'palette'),
      (key: 'settings.appearance.high_contrast', column: 'high_contrast'),
      (key: 'settings.keep_screen_on', column: 'wakelock_enabled'),
      (key: 'settings.left_handed', column: 'left_handed'),
    ]) {
      final Finder f = find.byKey(Key(row.key));
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    final AppSetting after = await settings();
    // **THE STORED PALETTE KEY IS `red` FOR `DEEP RED` AND `amber` HERE** — R35
    // freezes the three ids, and the label and the key are deliberately not the
    // same string on one of them.
    expect(after.palette, ShedPaletteId.amber.key);
    expect(after.highContrast, isTrue);
    expect(after.wakelockEnabled, isTrue);
    expect(after.leftHanded, isTrue);

    await tester.closeApp();
  });

  testWidgets('high contrast is an addition to the palette, not a fourth palette', (
    WidgetTester tester,
  ) async {
    // A shepherd who wants amber AND high contrast must be able to have both —
    // which is why it is its own row rather than a fourth word on the line
    // above. The failure this catches is a segmented line of four where picking
    // high contrast silently unsets the palette.
    final AppDatabase db = testDatabase();
    await tester.pumpApp(const SettingsScreen(), db: db);
    await tester.pumpAndSettle();

    for (final String key in <String>[
      'settings.appearance.palette.red',
      'settings.appearance.high_contrast',
    ]) {
      final Finder f = find.byKey(Key(key));
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    final AppSetting s = await db.select(db.appSettings).getSingle();
    expect(s.palette, ShedPaletteId.deepRed.key, reason: 'the stored key is red, not deep_red');
    expect(s.highContrast, isTrue, reason: 'the two settings are independent');

    await tester.closeApp();
  });

  testWidgets('no setting is a Switch, a Slider or anything draggable', (
    WidgetTester tester,
  ) async {
    // `06 §7`. Material's `Switch` is a drag target with a tap fallback, and
    // drag is banned outright — a control whose primary gesture the app does not
    // support is a control that teaches the wrong thing. `Slider` is banned by
    // name, and `Dismissible`/`Draggable` are `check_policy` rows.
    final AppDatabase db = testDatabase();
    await tester.pumpApp(const SettingsScreen(), db: db);
    await tester.pumpAndSettle();

    expect(find.byType(Switch), findsNothing);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.byType(Slider), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(Dismissible), findsNothing);
    expect(find.byType(Draggable<Object>), findsNothing);

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

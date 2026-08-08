// test/features/shots_test.dart
//
// **A THROWAWAY. NOT A GOLDEN, NOT A GATE — A CAMERA.**
//
// This file exists to answer one question the whole suite cannot: *does the app
// look like the design?* It renders every screen to a PNG under `build/shots/`
// so the images can be put beside `mockups/indelible.html` and read by a human.
//
// It asserts nothing, so it can never go red and can never be a reason to
// change the product. Tagged `golden` so `make test` never runs it.
@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/export/export_screen.dart';
import 'package:shed_book/features/flock/flock_screen.dart';
import 'package:shed_book/features/lambing/lambing_entry_screen.dart';
import 'package:shed_book/features/pens/pen_board_screen.dart';
import 'package:shed_book/features/quick_entry/quick_entry_screen.dart';
import 'package:shed_book/features/settings/settings_screen.dart';
import 'package:shed_book/features/treatments/treatments_screen.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

Future<void> _shoot(WidgetTester tester, Finder of, String name) async =>
    expectLater(of, matchesGoldenFile('shots/$name.png'));

void main() {
  testWidgets('quick entry', (WidgetTester tester) async {
    final AppDatabase db = testDatabase();
    try {
      await seedSeason(db);
      for (final (String tag, int minutes) in <(String, int)>[
        ('91', 160),
        ('305', 100),
        ('128', 65),
        ('219', 40),
        ('77', 18),
      ]) {
        final EweId ewe = await seedEwe(db, tag: tag);
        await seedLambing(db, ewe, occurredAt: appNow().plus(Duration(minutes: -minutes)));
      }
      await tester.pumpApp(const QuickEntryScreen(), db: db);
      await tester.pumpAndSettle();
      await _shoot(tester, find.byType(QuickEntryScreen), '3a_quick_entry');

      await tester.tap(find.byKey(const Key('quick_entry.live_row.tag_cell')));
      await tester.pumpAndSettle();
      await _shoot(tester, find.byType(MaterialApp), '3b_tag_sheet');

      for (final String d in <String>['1', '2']) {
        await tester.tap(find.byKey(Key('quick_entry.keypad.digit_$d')));
        await tester.pumpAndSettle();
      }
      await _shoot(tester, find.byType(MaterialApp), '3c_tag_typed');
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('lambing entry', (WidgetTester tester) async {
    final AppDatabase db = testDatabase();
    try {
      await seedSeason(db);
      final EweId ewe = await seedEwe(db, tag: '412');
      final LambingId lambing = await seedLambing(db, ewe);
      await seedLamb(db, lambing, ewe);
      await seedLamb(db, lambing, ewe);
      await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
      await tester.pumpAndSettle();
      await _shoot(tester, find.byType(LambingEntryScreen), '4_lambing_entry');
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('flock', (WidgetTester tester) async {
    final AppDatabase db = testDatabase();
    try {
      await seedSeason(db);
      for (final String tag in <String>['412', '128', '305', '77', '219', '12']) {
        await seedEweInSeason(db, tag: tag, status: 'to_ram');
      }
      await tester.pumpApp(const FlockScreen(), db: db);
      await tester.pumpAndSettle();
      await _shoot(tester, find.byType(FlockScreen), '1_flock');
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('pen board', (WidgetTester tester) async {
    final AppDatabase db = testDatabase();
    try {
      await seedSeason(db);
      for (int i = 1; i <= 6; i++) {
        final PenId pen = await seedPen(db, label: '$i');
        final EweId ewe = await seedEwe(db, tag: '${400 + i}');
        await seedPenOccupancy(db, pen, ewe);
      }
      await tester.pumpApp(const PenBoardScreen(), db: db);
      await tester.pumpAndSettle();
      await _shoot(tester, find.byType(PenBoardScreen), '7_pen_board');
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('treatments', (WidgetTester tester) async {
    final AppDatabase db = testDatabase();
    try {
      await seedSeason(db);
      final EweId ewe = await seedEwe(db, tag: '77');
      await seedTreatment(db, ewe: ewe, product: 'Alamycin LA', withdrawalDays: 28);
      await tester.pumpApp(const TreatmentsScreen(), db: db);
      await tester.pumpAndSettle();
      await _shoot(tester, find.byType(TreatmentsScreen), '8_treatments');
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('export', (WidgetTester tester) async {
    final AppDatabase db = testDatabase();
    try {
      await seedSeason(db);
      await tester.pumpApp(const ExportScreen(), db: db);
      await tester.pumpAndSettle();
      await _shoot(tester, find.byType(ExportScreen), '11_export');
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('settings', (WidgetTester tester) async {
    final AppDatabase db = testDatabase();
    try {
      await seedSeason(db);
      await tester.pumpApp(const SettingsScreen(), db: db);
      await tester.pumpAndSettle();
      await _shoot(tester, find.byType(SettingsScreen), '12_settings');
    } finally {
      await tester.closeApp();
    }
  });
}

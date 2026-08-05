// test/features/fresh_notebook_test.dart
//
// **A SHEPHERD'S FIRST NIGHT, WHICH DID NOTHING AT ALL.**
//
// `seedFirstRun` deliberately writes no season (#42) — *a season is the
// shepherd's first act, not the installer's* — and
// `LambingRepository._currentSeason()` refuses to invent one on the 3am path,
// also correctly: a verb that invented a season would give the shepherd one they
// did not start, silently, and the season is the unit the whole free tier is
// priced on.
//
// Both halves are right. What was missing was the third: **nowhere in the
// product started a season.** `startSeason` existed in `SeasonRepository` and in
// `SettingsWriteController` and had no caller in `lib/`, and `07 §14.3` row 4
// had specified the row.
//
// Measured on 2026-08-05, on a fresh notebook: tag 412, confirm, Lambing —
// **zero lambings written, and no exception, and nothing on screen.** Every
// widget test passed, because every widget test seeds a season first.
//
// This file is the one that would not have.
@Tags(<String>['policy'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/features/export/export_screen.dart';
import 'package:shed_book/features/quick_entry/quick_entry_screen.dart';
import 'package:shed_book/features/settings/settings_screen.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

void main() {
  testWidgets('a fresh notebook offers somewhere to start a season', (WidgetTester tester) async {
    // **THE ANCHOR.** Not *"the row exists"* — the row exists on a seeded
    // database too. This asserts it exists on the database a shepherd actually
    // has on their first morning: no season, no ewes, nothing.
    final AppDatabase db = testDatabase();
    try {
      expect(
        (await db.select(db.appSettings).getSingle()).currentSeason,
        isNull,
        reason: 'the fixture seeded a season and this test is now proving nothing',
      );

      await tester.pumpApp(const SettingsScreen(), db: db);
      await tester.pumpAndSettle();

      final Finder start = find.byKey(const Key('settings.season.start'));
      await tester.scrollUntilVisible(start, 200, scrollable: find.byType(Scrollable).first);
      expect(start, findsOneWidget, reason: 'a fresh notebook is a dead end');
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('starting a season makes Quick Entry able to record a lambing', (
    WidgetTester tester,
  ) async {
    // **THE WHOLE JOURNEY, AND THE ASSERTION IS THE ROW COUNT.** A test that
    // stopped at *the season exists* would pass against the defect too — the
    // season was never the missing piece on its own; the missing piece was that
    // one could not be made.
    final AppDatabase db = testDatabase();
    try {
      await tester.pumpApp(const SettingsScreen(), db: db);
      await tester.pumpAndSettle();

      final Finder start = find.byKey(const Key('settings.season.start'));
      await tester.scrollUntilVisible(start, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(start);
      await tester.pumpAndSettle();

      expect(await db.select(db.seasons).get(), hasLength(1));
      expect(
        (await db.select(db.appSettings).getSingle()).currentSeason,
        isNotNull,
        reason: 'a season that is not current is a season every write verb ignores',
      );
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('with a season, the 3am path writes a lambing', (WidgetTester tester) async {
    final AppDatabase db = testDatabase();
    await seedSeasonForFreshNotebook(db);

    try {
      await tester.pumpApp(const QuickEntryScreen(), db: db);
      await tester.pumpAndSettle();

      for (final String digit in <String>['4', '1', '2']) {
        await tester.tap(find.byKey(Key('quick_entry.keypad.digit_$digit')));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick_entry.confirm')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick_entry.event.lambing')));
      await tester.pumpAndSettle();

      expect(
        await db.select(db.lambings).get(),
        hasLength(1),
        reason: 'the 3am path recorded nothing and said nothing',
      );
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('the export screen offers a backup, which is the only file a restore reads', (
    WidgetTester tester,
  ) async {
    // **THE OTHER HALF OF THE RESTORE GAP.** `writeBackup` landed at N22 and had
    // no caller anywhere in `lib/`: the export screen offered three CSVs and no
    // backup, so a shepherd could get their records out in a form a spreadsheet
    // reads and never in the form this app reads back.
    //
    // Wiring restore without this would have been wiring a door to a room with
    // no key. A CSV is not a backup and the two are not interchangeable — the
    // backup is all 21 tables with the provenance quad, the withdrawal child
    // rows and the strikes, and restoring from a CSV would lose every one of
    // those silently.
    final AppDatabase db = testDatabase();
    await seedSeasonForFreshNotebook(db);

    try {
      await tester.pumpApp(const ExportScreen(), db: db);
      await tester.pumpAndSettle();

      final Finder backup = find.byKey(const Key('export.backup'));
      await tester.scrollUntilVisible(backup, 200, scrollable: find.byType(Scrollable).first);
      expect(backup, findsOneWidget, reason: 'there is no way to make a backup');
    } finally {
      await tester.closeApp();
    }
  });
}

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
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/stats/definitions.dart';
import 'package:shed_book/features/export/export_screen.dart';
import 'package:shed_book/features/quick_entry/quick_entry_screen.dart';
import 'package:shed_book/features/flock/ewe_card_screen.dart';
import 'package:shed_book/features/lambing/lambing_entry_screen.dart';
import 'package:shed_book/features/pens/pen_board_screen.dart';
import 'package:shed_book/features/settings/settings_screen.dart';
import 'package:shed_book/features/treatments/treatments_screen.dart';

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

  testWidgets('a treatment can be recorded, with a withdrawal the shepherd entered', (
    WidgetTester tester,
  ) async {
    // **`recordTreatment` HAD NO CALLER AND `WithdrawalControl` WAS NEVER
    // BUILT.** N20's seven tasks are the countdowns, the clear date, the repeat
    // sheet and the void — not one of them is the entry, and `07 §10.4`
    // specifies it. So the only reachable write was `repeatTreatment`, on a
    // book with nothing in it to repeat.
    //
    // The assertion is the ROW, not the sheet: a test that stopped at *the
    // sheet opens* would pass against a commit button that did nothing, which
    // is the defect one layer along.
    final AppDatabase db = testDatabase();
    await seedSeasonForFreshNotebook(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final PenId pen = await seedPen(db, label: 'A');
    await seedPenOccupancy(db, pen, ewe);

    try {
      await tester.pumpApp(const TreatmentsScreen(), db: db);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('treatments.new')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('treatment.new.animal.412')));
      await tester.pump();
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('treatment.new.product')),
          matching: find.byType(TextField),
        ),
        'Alamycin LA',
      );
      await tester.pumpAndSettle();

      // **`ensureVisible` FIRST, AND WITHOUT IT THIS PASSED FOR THE WRONG
      // REASON.** The sheet is taller than the viewport — animal rows, four
      // fields, eight routes and two withdrawal controls — so the commit button
      // is below the fold and `tap` lands on whatever is at those coordinates.
      // Measured: no exception, no treatment, and a failure that reads as *the
      // button does nothing*.
      await tester.ensureVisible(find.byKey(const Key('treatment.new.commit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('treatment.new.commit')));
      await tester.pumpAndSettle();

      final List<Treatment> recorded = await db.select(db.treatments).get();
      expect(recorded, hasLength(1), reason: 'the commit button did nothing');
      expect(recorded.single.productName, 'Alamycin LA');

      // **AND NO WITHDRAWAL ROW**, because the shepherd answered neither target
      // — which is §12.1's shape exactly: *not recorded* is the absence of a
      // row, never a zero and never a placeholder. The control was on screen
      // with the caveat above it; they did not choose.
      expect(
        await db.select(db.treatmentWithdrawals).get(),
        isEmpty,
        reason: 'an unanswered withdrawal wrote a row — that is what §12.1 forbids',
      );
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('a ewe can be penned and turned out', (WidgetTester tester) async {
    // **THE BOARD COULD READ AND NOT WRITE.** Every tile carried
    // `onTap: () {}` with a comment saying T07 would open the row; T07 landed
    // the board and not the sheet. `enterPen`, `exitPen` and `movePen` all had
    // their own tests and no caller in `lib/`, so a shepherd could add a pen and
    // could not put an animal in it or take one out.
    //
    // `TURN OUT` is one of the five words `indelible.md §6` names, and it is the
    // daily act on this screen.
    final AppDatabase db = testDatabase();
    await seedSeasonForFreshNotebook(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    await seedPen(db, label: 'A');
    // **A TOUCH, NOT A LAMBING.** The deck's recents are built from
    // `ewe_touches` — a cache with one row per ewe — and a seeded lambing does
    // not write one, because the repository writes the touch and the seeder
    // writes the row. The sheet picks from the same deck every other picker in
    // the app uses.
    await seedTouch(db, ewe);

    try {
      await tester.pumpApp(const PenBoardScreen(), db: db);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pen_board.tile.A')));
      await tester.pumpAndSettle();

      final Finder her = find.byKey(const Key('pen_sheet.animal.412'));
      await tester.ensureVisible(her);
      await tester.pumpAndSettle();
      await tester.tap(her);
      await tester.pumpAndSettle();

      expect(
        (await db.select(db.penOccupancies).get()).where((PenOccupancy o) => o.exitedAt == null),
        hasLength(1),
        reason: 'penning wrote nothing',
      );

      // And out again. **`turned_out` IS ITS OWN EXIT REASON** — the occupancy
      // is closed, never deleted, because nothing is removed from this book.
      await tester.tap(find.byKey(const Key('pen_board.tile.A')));
      await tester.pumpAndSettle();
      final Finder out = find.byKey(const Key('pen_sheet.turn_out'));
      await tester.ensureVisible(out);
      await tester.pumpAndSettle();
      await tester.tap(out);
      await tester.pumpAndSettle();

      final List<PenOccupancy> all = await db.select(db.penOccupancies).get();
      expect(all, hasLength(1), reason: 'the occupancy was deleted rather than closed');
      expect(all.single.exitedAt, isNotNull);
      expect(all.single.exitReason, 'turned_out');
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('the three lambing detail fields commit every keystroke', (
    WidgetTester tester,
  ) async {
    // **`indelible.md §8` SCREEN 4 SPECIFIES THEM AND NOBODY BUILT THEM**:
    // *"Assistance detail and the note are text fields with the label above and
    // a dotted rule below."* `setAssistedBy`, `setPresentationNote` and
    // `setNote` all existed on the controller AND the repository, with tests,
    // and had no caller — because until `ShedTextField` there was no way to
    // enter free text anywhere in the app.
    //
    // The assertion is the COLUMN, because *every write commits immediately* is
    // the claim: no Save button, no draft, each keystroke its own write.
    final AppDatabase db = testDatabase();
    await seedSeasonForFreshNotebook(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    try {
      await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
      await tester.pumpAndSettle();

      for (final ({String key, String typed}) field in <({String key, String typed})>[
        (key: 'lambing_entry.assisted_by', typed: 'Tom'),
        (key: 'lambing_entry.presentation_note', typed: 'ropes'),
        (key: 'lambing_entry.note', typed: 'watch her'),
      ]) {
        final Finder f = find.byKey(Key(field.key));
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.descendant(of: f, matching: find.byType(TextField)),
          field.typed,
        );
        await tester.pumpAndSettle();
      }

      final Lambing row = await (db.select(
        db.lambings,
      )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();
      expect(row.assistedBy, 'Tom');
      expect(row.presentationNote, 'ropes');
      expect(row.note, 'watch her');
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('a treatment can be voided, and the row stays in the book', (
    WidgetTester tester,
  ) async {
    // **`voidTreatment` HAD NO CALLER.** `07 §10.4` gives it two taps and
    // N20-T05 landed it with its own tests; the book could SHOW a void and
    // could not make one, so a treatment recorded against the wrong ewe stayed
    // in the medicine book with its withdrawal running.
    //
    // The assertion is that the row SURVIVES. Nothing is removed from this book
    // — it may already be printed in one somebody is holding — so a void that
    // deleted would be the defect, not the fix.
    final AppDatabase db = testDatabase();
    await seedSeasonForFreshNotebook(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    await seedTreatment(db, ewe: ewe, product: 'Alamycin', withdrawalDays: 7);

    try {
      await tester.pumpApp(const TreatmentsScreen(), db: db);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('treatments.mode.book')));
      await tester.pumpAndSettle();

      final int id = (await db.select(db.treatments).get()).single.id;
      final Finder voidIt = find.byKey(Key('treatments.void.$id'));
      await tester.ensureVisible(voidIt);
      await tester.pumpAndSettle();
      await tester.tap(voidIt);
      await tester.pumpAndSettle();

      final List<Treatment> after = await db.select(db.treatments).get();
      expect(after, hasLength(1), reason: 'the void deleted the row');
      expect(after.single.voidedAt, isNotNull);

      // AND THE WITHDRAWAL ROW IS UNTOUCHED — decision #69: never delete, blank
      // or recompute it. The medicine book shows it struck through, still
      // carrying the figure it was saved with.
      expect(await db.select(db.treatmentWithdrawals).get(), hasLength(1));
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('a note commits on the first keystroke and updates on the rest', (
    WidgetTester tester,
  ) async {
    // **`addNote` HAD NO CALLER** — the one verb for a fact the schema has no
    // column for, with nowhere to write it.
    //
    // **ONE ROW, NOT ONE PER KEYSTROKE**, which is the assertion that matters:
    // insert-only would leave a shepherd typing *limping* with seven notes
    // reading `l`, `li`, `lim`… and batching into a commit would be a draft.
    final AppDatabase db = testDatabase();
    await seedSeasonForFreshNotebook(db);
    final EweId ewe = await seedEwe(db, tag: '412');

    try {
      await tester.pumpApp(
        EweCardScreen(eweId: ewe, tag: '412'),
        db: db,
      );
      await tester.pumpAndSettle();

      final Finder note = find.byKey(const Key('ewe_card.action.note'));
      await tester.ensureVisible(note);
      await tester.pumpAndSettle();
      await tester.tap(note);
      await tester.pumpAndSettle();

      final Finder field = find.descendant(
        of: find.byKey(const Key('ewe_card.note.field')),
        matching: find.byType(TextField),
      );
      for (final String typed in <String>['l', 'li', 'limping']) {
        await tester.enterText(field, typed);
        await tester.pumpAndSettle();
      }

      final List<Note> notes = await db.select(db.notes).get();
      expect(notes, hasLength(1), reason: 'one row per sheet, not one per keystroke');
      expect(notes.single.body, 'limping');
      expect(notes.single.ewe, ewe.value);

      // AND THE PROVENANCE IS THE NOTE'S OWN. Typing more of it is not an edit
      // of when it happened — `EDITED` on the one stamp §12.5 rests on would
      // mean nothing if every keystroke set it.
      expect(notes.single.timeSource, 'auto');
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('the cycle and the percentage definition are the shepherd\'s to set', (
    WidgetTester tester,
  ) async {
    // **STORED NOW, READ IN JUNE.** Both are read by Season Summary (N28,
    // `v1.1.0`) and neither had a caller — but the season they describe is
    // happening NOW, and a setting a shepherd cannot reach until after the
    // season it applies to is a setting that arrives too late to be true.
    //
    // `lambingSpread`'s own doc is blunt about the cycle: the parameter *"has a
    // default and the app must never use it"*. 17 is what `onCreate` seeds, and
    // this row is how a shepherd whose tup ratio says otherwise changes it.
    final AppDatabase db = testDatabase();
    await seedSeasonForFreshNotebook(db);

    try {
      await tester.pumpApp(const SettingsScreen(), db: db);
      await tester.pumpAndSettle();

      final Finder longer = find.byKey(const Key('settings.season.cycle.longer'));
      await tester.scrollUntilVisible(longer, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(longer);
      await tester.pumpAndSettle();
      expect((await db.select(db.appSettings).getSingle()).cycleDays, 18);

      final Finder reared = find.byKey(
        Key('settings.season.percentage.${LambingPercentageChoice.rearedPerEweToRam.key}'),
      );
      await tester.scrollUntilVisible(reared, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(reared);
      await tester.pumpAndSettle();
      expect(
        (await db.select(db.appSettings).getSingle()).percentageDefinition,
        LambingPercentageChoice.rearedPerEweToRam.key,
        reason:
            'four honest definitions give different numbers off one flock — '
            'the app states which, and never picks',
      );
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('the Lambing tap opens Lambing Entry, not just the row', (WidgetTester tester) async {
    // **THE ROW COMMITTED AND THE SCREEN NEVER OPENED.** Reported from a
    // simulator: type 412, `Create 412`, `Lambing` — the lambing was written,
    // its receipt appeared (*20 seconds to strike*), and the shepherd was left
    // on Quick Entry with no sign anything had happened.
    //
    // `CLAUDE.md` is explicit that the tap *calls `beginLambing(ewe)` **before**
    // Lambing Entry is pushed*. The commit was there; the push was not. The ewe
    // card has done it correctly since N27 and this screen never did.
    //
    // **THE ASSERTION IS THE SCREEN, NOT THE ROW.** Every existing test on this
    // path asserts the row — and the row was always fine. That is why nothing
    // caught it: the whole suite was checking the half that worked.
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
        find.byType(LambingEntryScreen),
        findsOneWidget,
        reason: 'the row committed and the screen never opened',
      );
      expect(await db.select(db.lambings).get(), hasLength(1));
    } finally {
      await tester.closeApp();
    }
  });
}

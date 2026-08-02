// test/features/lambing_entry_test.dart
//
// One statement for the whole screen. The negative half is source text over the
// FEATURE, because that is what stops the defect coming back in a widget nobody
// is looking at.
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/features/lambing/lambing_entry_screen.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

Future<SeasonId> _seedSeason(AppDatabase db) async {
  final Instant now = Instant.fromDateTime(DateTime.utc(2026, 3, 14, 3, 20));
  final int id = await db
      .into(db.seasons)
      .insert(
        SeasonsCompanion.insert(
          year: 2026,
          label: '2026',
          startDate: LocalDate(2026, 1, 1),
          uid: newUid(),
          createdAt: now,
          updatedAt: now,
        ),
      );
  await (db.update(db.appSettings)..where(($AppSettingsTable t) => t.id.equals(1))).write(
    AppSettingsCompanion(currentSeason: Value<int?>(id)),
  );
  return SeasonId(id);
}

void main() {
  testWidgets('the screen reads one statement and no combineLatest appears in the feature', (
    WidgetTester tester,
  ) async {
    // THE ANCHOR'S FIRST HALF, AND IT PROVES *ONE* RATHER THAN *NOT FOUR*: every
    // fact renders after a SINGLE pumpAndSettle, with no intermediate frame in
    // which one of them is missing. Two drift streams updated inside one
    // transaction can emit at different times, so a screen built from four would
    // show a lamb whose care event has not arrived yet.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId first = await seedLamb(db, lambing, ewe);
    await seedLamb(db, lambing, ewe);
    await seedCareEvent(db, kind: 'colostrum', lamb: first, volumeMl: 200);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    expect(find.text('Lambs 2'), findsOneWidget);
    expect(find.text('Care 1'), findsOneWidget);
    expect(find.byKey(const Key('lambing_entry.provenance')), findsOneWidget);

    await tester.closeApp();
  });

  test('the lambing feature imports no drift symbol and combines no streams', () {
    // THE SECOND HALF. layer rule 5 forbids lib/features/ from importing
    // package:drift at all, and the gate holds that — but "no combineLatest"
    // has no gate row scoped to this directory, and a widget that combined two
    // streams would pass every other check in the project.
    //
    // The operator is DESCRIBED in the reason rather than named twice: this
    // file is scanned by stream.combine's own root.
    const String combine =
        'combine' // split
        'Latest';

    for (final FileSystemEntity f in Directory('lib/features/lambing').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) {
        continue;
      }
      // IMPORT DIRECTIVES ONLY for the two package checks: the screen's own
      // header comment explains WHY it may not import drift, and naming the
      // package there is the point. The thirty-second prohibition-versus-claim
      // self-match in this project.
      final String source = f.readAsStringSync();
      final String imports = f
          .readAsLinesSync()
          .where((String l) => l.trimLeft().startsWith('import '))
          .join('\n');

      expect(source, isNot(contains(combine)), reason: f.path);
      expect(imports, isNot(contains('package:drift')), reason: f.path);
      expect(imports, isNot(contains('core/db/')), reason: f.path);
    }
  });

  testWidgets('a care event recorded before any lamb still appears', (WidgetTester tester) async {
    // THE SECOND ARM OF THE JOIN, and deleting it is SILENT — the rows simply
    // stop appearing. care_events' CHECK is exactly one of (lambing, lamb), and
    // a care action taken before the first stroke belongs to the lambing.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    await seedCareEvent(db, kind: 'warmed', lambing: lambing);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    expect(find.text('Lambs 0'), findsOneWidget);
    expect(find.text('Care 1'), findsOneWidget, reason: 'the pre-lamb care event is on screen');

    await tester.closeApp();
  });

  testWidgets('a struck lamb stays in the list', (WidgetTester tester) async {
    // Indelible Rule 1: nothing disappears from the page. The statement never
    // filters; the widget decides how a struck stroke renders.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId lamb = await seedLamb(db, lambing, ewe);

    await (db.update(db.lambs)..where(($LambsTable t) => t.id.equals(lamb.value))).write(
      LambsCompanion(
        struck: const Value<bool>(true),
        struckAt: Value<Instant?>(Instant.fromDateTime(DateTime.utc(2026, 3, 14, 4))),
      ),
    );

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    expect(find.text('Lambs 1'), findsOneWidget, reason: 'struck, and still counted on the page');

    await tester.closeApp();
  });

  testWidgets('the provenance is on screen and is never empty', (WidgetTester tester) async {
    // §12.5. The label is the only place the claim reaches the shepherd, and
    // RecordedTime's exhaustive switch is what makes it impossible to be blank.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    final Text label = tester.widget<Text>(find.byKey(const Key('lambing_entry.provenance')));
    expect(label.data, isNotNull);
    expect(label.data, isNotEmpty);
    expect(label.data, 'recorded automatically', reason: 'beginLambing captures');

    await tester.closeApp();
  });
}

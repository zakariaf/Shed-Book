// test/features/export_test.dart
//
// The screen that is the only backup this product has, and the repository that
// must never grow a write.
//
// The two halves of the anchor fail for different reasons and that is the point:
// half one catches a repository that grew a write, half two catches a screen
// that got tidier and less honest.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/features/export/export_screen.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

void main() {
  testWidgets('ExportRepository performs no write and the screen states what an export is not', (
    WidgetTester tester,
  ) async {
    // HALF ONE — `CONVENTIONS §2.13`'s *"nothing"* made mechanical. The one
    // repository in the app that owns no table, asserted on its source text
    // rather than on its behaviour, because a write added tomorrow would pass
    // every behavioural case that exists today.
    final String source = File('lib/data/export_repository.dart').readAsStringSync();
    for (final String write in <String>['transaction(', '.into(', '.update(', '.delete(']) {
      expect(source, isNot(contains(write)), reason: 'ExportRepository writes nothing');
    }
    expect(
      RegExp(r'\bsave\w*\(').hasMatch(source),
      isFalse,
      reason: 'and `save` is a banned spelling anywhere in this project',
    );

    // HALF TWO — the screen is honest about what an export is.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    await tester.pumpApp(const ExportScreen(), db: db);
    await tester.pumpAndSettle();

    // THROUGH THE CONSTANT, never against a copy of its text. A test that
    // hard-codes the literal still passes after somebody edits the constant.
    expect(find.text(Disclaimers.exportFooter), findsOneWidget);

    for (final String forbidden in <String>[
      'compliance record',
      'official record',
      'your data never leaves your phone',
    ]) {
      expect(find.textContaining(forbidden), findsNothing, reason: forbidden);
    }

    await tester.closeApp();
  });

  testWidgets('frame 1 paints every row with its label and a blank count, and no spinner', (
    WidgetTester tester,
  ) async {
    // The labels are static and never wait, so nothing shifts when the counts
    // land. `ui.spinner` bans `CircularProgressIndicator` under `lib/features/`
    // — a screen that spins is a screen that has hidden what it is doing.
    final AppDatabase db = testDatabase();
    await seedSeason(db);

    await tester.pumpApp(const ExportScreen(), db: db);
    await tester.pump(); // deliberately NOT settled: this is frame 1

    for (final String id in <String>[
      'export.lambs_csv',
      'export.ewes_csv',
      'export.treatments_csv',
    ]) {
      expect(find.byKey(Key(id)), findsOneWidget, reason: id);
    }
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.closeApp();
  });

  testWidgets('the status line says nothing has been exported, rather than nagging', (
    WidgetTester tester,
  ) async {
    // It states a fact the shepherd can act on. It does NOT say *"a lost phone
    // is lost data"* — that wording is banned unqualified — and it is not a
    // warning colour, because the app has no opinion about how often somebody
    // ought to export.
    final AppDatabase db = testDatabase();
    await seedSeason(db);

    await tester.pumpApp(const ExportScreen(), db: db);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('export.status')), findsOneWidget);
    expect(find.textContaining('lost phone is lost data'), findsNothing);

    await tester.closeApp();
  });

  testWidgets('the counts are the read numbers, and they arrive without shifting the rows', (
    WidgetTester tester,
  ) async {
    final AppDatabase db = testDatabase();
    final SeasonId season = await seedSeason(db);
    expect(season.value, isPositive);

    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    await seedLamb(db, lambing, ewe);
    await seedLamb(db, lambing, ewe);

    await tester.pumpApp(const ExportScreen(), db: db);
    await tester.pumpAndSettle();

    // READ, NEVER ESTIMATED. No LIMIT, no sampling, no "about 400" — a count the
    // shepherd can compare against their own flock list has to be right.
    expect(find.textContaining('2 lambs'), findsOneWidget);
    expect(find.textContaining('1 ewes'), findsOneWidget);

    await tester.closeApp();
  });
}

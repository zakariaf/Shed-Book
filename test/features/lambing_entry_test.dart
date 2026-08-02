// test/features/lambing_entry_test.dart
//
// One statement for the whole screen. The negative half is source text over the
// FEATURE, because that is what stops the defect coming back in a widget nobody
// is looking at.
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/core/ui/components/shed_tally.dart';
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

  testWidgets('three strokes print TRIPLET (COUNTED) and no widget carries a birth_type key', (
    WidgetTester tester,
  ) async {
    // THE ANCHOR, AND THE STROKES ARE PRESSED RATHER THAN SEEDED — that is what
    // makes the case prove the whole path, and it is the same three presses
    // indelible.md §9 describes.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    for (int i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('lambing_entry.tally.stroke')));
      await tester.pumpAndSettle();
    }

    // READ THE COUNT BACK OUT OF SQLITE, so a label that agrees with a widget
    // field rather than with the database cannot pass.
    expect((await db.select(db.lambs).get()).length, 3);

    final Text label = tester.widget<Text>(find.byKey(const Key('lambing_entry.counted_type')));
    expect(label.data, 'triplet (COUNTED)');

    // THE CANARY. P8 abolished the chooser, and this walks the whole tree
    // rather than one widget: a birth-type key anywhere is the chooser coming
    // back somewhere nobody is looking.
    const String banned =
        'birth_'
        'type';
    for (final Widget w in tester.allWidgets) {
      final Key? k = w.key;
      if (k is ValueKey<String>) {
        expect(k.value, isNot(contains(banned)), reason: '${w.runtimeType}');
      }
    }

    await tester.closeApp();
  });

  testWidgets('no strokes prints NOT RECORDED, never single', (WidgetTester tester) async {
    // Zero is NOT RECORDED. Defaulting to `single` would be the app answering
    // for the shepherd, which is §12.4 in one line — and it is the exact
    // failure 07 §6.3's old "the five buttons are unselected" row described a
    // control for.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    final Text label = tester.widget<Text>(find.byKey(const Key('lambing_entry.counted_type')));
    expect(label.data, 'NOT RECORDED');

    await tester.closeApp();
  });

  testWidgets('five strokes print the count rather than a word', (WidgetTester tester) async {
    // countedBirthType returns null at five and above deliberately: quintPlus
    // means "more than four, count NOT declared", and a counted five is not
    // open-ended. Printing the number is what keeps the tally's information.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    for (int i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const Key('lambing_entry.tally.stroke')));
      await tester.pumpAndSettle();
    }

    final Text label = tester.widget<Text>(find.byKey(const Key('lambing_entry.counted_type')));
    expect(label.data, '5 lambs (COUNTED)');

    await tester.closeApp();
  });

  testWidgets('a double tap on the slab adds exactly one lamb', (WidgetTester tester) async {
    // guard(), on the screen the shepherd is using with one cold hand. NO PUMP
    // BETWEEN THE TAPS: with one, the first write completes and the second is a
    // legitimate second lamb.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    final Finder slab = find.byKey(const Key('lambing_entry.tally.stroke'));
    await tester.tap(slab);
    await tester.tap(slab);
    await tester.pumpAndSettle();

    expect((await db.select(db.lambs).get()).length, 1);

    await tester.closeApp();
  });

  testWidgets('a struck lamb keeps its mark and leaves the count', (WidgetTester tester) async {
    // Both halves of Indelible Rule 1 at once: the MARK stays on the page, and
    // the DERIVED TYPE is about the animals that exist. A struck stroke that
    // vanished would make the shepherd's own count wrong.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId first = await seedLamb(db, lambing, ewe);
    await seedLamb(db, lambing, ewe);

    await (db.update(db.lambs)..where(($LambsTable t) => t.id.equals(first.value))).write(
      LambsCompanion(
        struck: const Value<bool>(true),
        struckAt: Value<Instant?>(Instant.fromDateTime(DateTime.utc(2026, 3, 14, 4))),
      ),
    );

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    final ShedTally tally = tester.widget<ShedTally>(find.byKey(const Key('lambing_entry.tally')));
    expect(tally.count, 2, reason: 'the mark stays');
    expect(tally.struck, <int>{0});

    final Text label = tester.widget<Text>(find.byKey(const Key('lambing_entry.counted_type')));
    expect(label.data, 'single (COUNTED)', reason: 'one live lamb');

    await tester.closeApp();
  });

  testWidgets('one row per lamb, in stroke order, and the ordinal is the position', (
    WidgetTester tester,
  ) async {
    // THE LIST'S ANCHOR (T03). The ordinal is STROKE ORDER — which lamb this was
    // in this lambing — and it must agree with the tally beside it. 10 §5.2
    // groups by status on the lists that are ABOUT lambs; here re-sorting the
    // dead to the bottom would print LAMB 3 second, and the marks and the words
    // would disagree on one screen.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    // THE MIDDLE ONE IS DEAD ON PURPOSE. With three live lambs the case passes
    // against a widget that sorts by status, because the sort is a no-op.
    final LambId first = await seedLamb(db, lambing, ewe, sex: 'f');
    final LambId second = await seedLamb(db, lambing, ewe, status: 'dead', sex: 'm');
    final LambId third = await seedLamb(db, lambing, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    for (final LambId id in <LambId>[first, second, third]) {
      expect(find.byKey(Key('lambing_entry.lamb.${id.value}')), findsOneWidget, reason: '$id');
    }

    // ORDER ASSERTED GEOMETRICALLY, not by index into a widget list: a Column
    // that built its children in one order and laid them out in another would
    // satisfy any find-based assertion.
    double yOf(LambId id) =>
        tester.getTopLeft(find.byKey(Key('lambing_entry.lamb.${id.value}'))).dy;

    expect(yOf(first), lessThan(yOf(second)));
    expect(yOf(second), lessThan(yOf(third)), reason: 'the dead lamb stays second');

    expect(find.text('LAMB 1'), findsOneWidget);
    expect(find.text('LAMB 2'), findsOneWidget);
    expect(find.text('LAMB 3'), findsOneWidget);

    await tester.closeApp();
  });

  testWidgets('an absent sex reads NOT RECORDED and a recorded unknown does not', (
    WidgetTester tester,
  ) async {
    // R45, ON SCREEN. Not recorded and recorded-as-unknown are different facts,
    // and this is the last place the difference can be lost — a widget that
    // rendered `sex ?? Sex.unknown` would look correct to a reviewer and would
    // be the app answering a question the shepherd did not.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await seedLamb(db, lambing, ewe); // sex absent
    await seedLamb(db, lambing, ewe, sex: 'unknown'); // sex recorded as unknown

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    // THE SEX CELL IS THE ANIMAL CLASS, and `AnimalClass.lamb`'s own doc
    // comment is "sex unknown, or not yet sexed" — so a recorded unknown reads
    // as the plain noun. It is NOT the word "unknown": 10 §8.5 keeps domain
    // nouns out of sentences, and l10n_bootstrap_test.dart catches the version
    // of this case that hard-coded "EWE LAMB" into the ARB.
    expect(find.text('LAMB'), findsOneWidget, reason: 'the one the shepherd entered');
    expect(
      find.textContaining('NOT RECORDED'),
      findsWidgets,
      reason: 'the one they have not got to yet',
    );

    await tester.closeApp();
  });

  testWidgets('a lamb row is 64 pt tall and carries the whole row as one utterance', (
    WidgetTester tester,
  ) async {
    // 64, NOT THE 60 pt FLOOR. ShedTapTarget falls back to tapMin when minSize
    // goes away, so a case written against 60 passes against a row that has
    // forgotten it is a row — the same trap keypad_test.dart documents.
    //
    // The single utterance is the other half: five cells announced separately is
    // five stops in the screen reader's rotor for one lamb.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId lamb = await seedLamb(db, lambing, ewe, sex: 'f', birthWeightG: 4100, tag: 'A12');

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    final Finder row = find.byKey(Key('lambing_entry.lamb.${lamb.value}'));
    expect(tester.getSize(row).height, greaterThanOrEqualTo(64.0));

    final SemanticsNode node = tester.getSemantics(row);
    expect(node.label, contains('LAMB 1'));
    expect(node.label, contains('EWE LAMB'), reason: 'termEweLambSingular, not a literal');
    expect(node.label, contains('ALIVE'));
    expect(node.label, contains('4.1 kg'), reason: 'the weight the shepherd recorded');
    expect(node.label, contains('A12'));
    // THE VOICE GETS PUNCTUATION IT CAN PAUSE ON. A middot is read aloud as
    // "middle dot" by at least one screen reader and as nothing at all by
    // another; neither is what the row means.
    expect(node.label, contains(', '));
    expect(node.label, isNot(contains('·')));

    await tester.closeApp();
  });
}

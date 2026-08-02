// test/features/lambing_entry_test.dart
//
// One statement for the whole screen. The negative half is source text over the
// FEATURE, because that is what stops the defect coming back in a widget nobody
// is looking at.
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;
import 'package:shed_book/data/recorded_time_columns.dart';
import 'package:shed_book/domain/time/recorded_time.dart';
import 'package:shed_book/domain/care_kind.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/core/ui/components/shed_tally.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/features/lambing/widgets/ease_row.dart';
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

  // ---------------------------------------------------------------------------
  // T04 — lambing ease 1–5
  // ---------------------------------------------------------------------------

  testWidgets('selecting ease 3 commits immediately and renders its authored description', (
    WidgetTester tester,
  ) async {
    // THE ANCHOR, AND BOTH CLAUSES ARE SHARPENED.
    //
    // COMMITS IMMEDIATELY — `lambings.ease` is read back out of the SAME
    // database in this test, with no Save button pressed and no route popped.
    // There is no Save button to press: the tap is the write.
    //
    // ITS AUTHORED DESCRIPTION — the string comes from the seeded vocabulary
    // through the ARB, not from a Dart literal. The next case is what makes
    // that binding, by renaming the term and watching the screen follow.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Considerable assistance needed'));
    await tester.pumpAndSettle();

    final Lambing row = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();
    expect(row.ease, 3, reason: 'in the database, with nothing saved');

    await tester.closeApp();
  });

  testWidgets('a user label on ease_3 overrides the shipped default and survives', (
    WidgetTester tester,
  ) async {
    // `NULL` MEANS RENDER THE SHIPPED DEFAULT, and it is not the same as an
    // empty label. `vocabLabel` is `userLabel ?? shipped` and nothing cleverer:
    // a `label?.isEmpty ?? true` check would let an accidental blank fall
    // silently back to the shipped word, hiding an edit the shepherd made —
    // §12.4 in its smallest possible form.
    //
    // THIS CASE IS WHAT MAKES THE ANCHOR BINDING. A test that only matched the
    // English sentence would pass just as happily against a Dart literal, which
    // is the one implementation this task must refuse.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await (db.update(db.vocabTerms)..where(($VocabTermsTable t) => t.key.equals('ease_3'))).write(
      const VocabTermsCompanion(label: Value<String?>('Had to get the ropes')),
    );

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    expect(find.text('Had to get the ropes'), findsOneWidget);
    expect(find.text('Considerable assistance needed'), findsNothing);

    // AND BACK. Clearing the override returns the shipped word — no app update
    // and no locale change was involved in either direction.
    await (db.update(db.vocabTerms)..where(($VocabTermsTable t) => t.key.equals('ease_3'))).write(
      const VocabTermsCompanion(label: Value<String?>(null)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Considerable assistance needed'), findsOneWidget);
    expect(find.text('Had to get the ropes'), findsNothing);

    // AN EMPTY LABEL IS THE SHEPHERD'S EDIT, NOT AN ABSENT ONE, and this is the
    // clause that distinguishes `userLabel ?? shipped` from
    // `(userLabel?.isEmpty ?? true) ? shipped : userLabel`.
    //
    // DRILLED, AND THE isEmpty VERSION PASSED EVERY OTHER CASE IN THIS FILE —
    // which is exactly how a §12.4 violation ships: an accidental blank falls
    // silently back to the shipped word, the screen looks right, and the
    // shepherd's own edit has been overruled by the app without a word.
    await (db.update(db.vocabTerms)..where(($VocabTermsTable t) => t.key.equals('ease_3'))).write(
      const VocabTermsCompanion(label: Value<String?>('')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Considerable assistance needed'),
      findsNothing,
      reason: 'blank is what they typed; the app does not overrule it',
    );

    await tester.closeApp();
  });

  testWidgets('the row offers exactly five values and no sixth', (WidgetTester tester) async {
    // The N00-T04 ruling, held as a widget property. `lambings.ease` carries
    // CHECK (ease IS NULL OR ease BETWEEN 1 AND 5) in a FROZEN schema, so a
    // sixth button is a migration on somebody else's phone.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    for (final String shipped in <String>[
      'No assistance',
      'Slight assistance by hand',
      'Considerable assistance needed',
      'Veterinary assistance needed',
      'Caesarean section',
    ]) {
      expect(find.text(shipped), findsOneWidget, reason: shipped);
    }
    expect(kEaseKeys, hasLength(5));

    await tester.closeApp();
  });

  testWidgets('an unscored ease prints NOT RECORDED and never 1', (WidgetTester tester) async {
    // DECISION #59. `05 §6.7`'s assisted rate excludes an unscored lambing from
    // BOTH the numerator and the denominator; inferring "1 — unassisted" would
    // inflate the unassisted count and deflate the rate, invisibly, for years.
    // There is nothing to render as zero either.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    // SCOPED TO THE EASE GROUP, and the drill is why. A bare
    // `find.textContaining('NOT RECORDED')` passed against `selected: 1`,
    // because the TALLY ROW prints its own NOT RECORDED for an underived birth
    // type one region above — so the case was asserting that some other widget
    // was on screen. `find.descendant` pins it to the group under test.
    expect(
      find.descendant(
        of: find.byKey(const Key('lambing_entry.ease')),
        matching: find.textContaining('NOT RECORDED'),
      ),
      findsOneWidget,
    );

    // AND THE DATABASE AGREES. A widget that printed the unset label while the
    // column held 1 would pass a screen-only assertion.
    final Lambing row = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();
    expect(row.ease, isNull, reason: 'unscored, not 1 and not 0');

    await tester.closeApp();
  });

  testWidgets('selecting ease writes only ease and updated_at', (WidgetTester tester) async {
    // A `copyWith` that rewrote the provenance quad on an unrelated edit is the
    // kind of defect that only surfaces in an export months later, and §12.5 is
    // what it would break. Asserted column by column rather than by eye.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    final Lambing before = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Caesarean section'));
    await tester.pumpAndSettle();

    final Lambing after = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();

    expect(after.ease, 5);
    expect(after.occurredAt, before.occurredAt);
    expect(after.capturedAt, before.capturedAt);
    expect(after.timeSource, before.timeSource);
    expect(after.originalEffective, before.originalEffective);
    expect(after.declaredBirthType, before.declaredBirthType);
    expect(after.ewe, before.ewe);
    expect(after.season, before.season);
    expect(after.uid, before.uid);
    expect(after.createdAt, before.createdAt);

    await tester.closeApp();
  });

  testWidgets('re-tapping a different value corrects forward and leaves no second value', (
    WidgetTester tester,
  ) async {
    // THERE IS NO CLEAR AFFORDANCE AND NO UNDO VERB (`07 §15.1`). A mis-tap is
    // corrected forward by tapping the right value; one UPDATE replaces the
    // other, so the two are never both present. A sixth "not scored" button
    // would put a chooser on screen for the ABSENCE of a value, when NULL is
    // already how absence is stored.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    await tester.tap(find.text('No assistance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Veterinary assistance needed'));
    await tester.pumpAndSettle();

    final Lambing row = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();
    expect(row.ease, 4, reason: 'the correction, not the mis-tap');

    // ONE ROW, ONE COLUMN — there is no second value anywhere to hold the first.
    expect(await db.select(db.lambings).get(), hasLength(1));

    await tester.closeApp();
  });

  testWidgets('a double-fired ease tap commits one value', (WidgetTester tester) async {
    // DECISION #22, and the shape of the case is the assertion: `guard()`
    // refuses to run concurrently, so there is NO PUMP BETWEEN THE TWO TAPS.
    // Pumping between them would make this a test of two separate taps, which
    // is a different and much weaker claim.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    final Finder ease2 = find.text('Slight assistance by hand');
    await tester.tap(ease2);
    await tester.tap(ease2, warnIfMissed: false);
    await tester.pumpAndSettle();

    final Lambing row = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();
    expect(row.ease, 2);

    await tester.closeApp();
  });

  testWidgets('the ease group wraps at 150% text scale and every button clears 64 by 64', (
    WidgetTester tester,
  ) async {
    // indelible.md §3.6's ONE DOCUMENTED COMPONENT WRAP: at ≥150% the five
    // buttons re-lay as 3 + 2. The page structure does not change; one
    // component re-lays.
    //
    // The text is NOT clamped to avoid it — `textScaleFactor`, `TextScaler.clamp`
    // and `withClampedTextScaling` are banned outright (decision #99) and defeat
    // Android 14+'s own non-linear curve. The layout is what gives way.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(
      LambingEntryScreen(lambingId: lambing),
      db: db,
      textScale: 1.5,
      device: Device.small,
    );
    await tester.pumpAndSettle();

    final Finder group = find.byKey(const Key('lambing_entry.ease'));
    expect(group, findsOneWidget);

    // THE FLOOR SURVIVES THE WRAP. This is the half a wrap usually breaks: the
    // buttons get narrower to fit, and the narrowest one falls under the target
    // size on the smallest phone.
    for (final String shipped in <String>['No assistance', 'Caesarean section']) {
      final Size size = tester.getSize(
        find.ancestor(of: find.text(shipped), matching: find.byType(ShedTapTarget)).first,
      );
      expect(size.height, greaterThanOrEqualTo(64.0), reason: shipped);
      expect(size.width, greaterThanOrEqualTo(64.0), reason: shipped);
    }

    await tester.closeApp();
  });

  testWidgets('the ease semantics node carries no state word in its label', (
    WidgetTester tester,
  ) async {
    // `10 §3.2` RULE 2: a screen reader announces state itself, so "Ease 3,
    // selected" is the doubled announcement users report as noise. The label
    // says the ordinal and the description and stops.
    final SemanticsHandle handle = tester.ensureSemantics();
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Considerable assistance needed'));
    await tester.pumpAndSettle();

    final SemanticsNode node = tester.getSemantics(
      find
          .ancestor(
            of: find.text('Considerable assistance needed'),
            matching: find.byType(ShedTapTarget),
          )
          .first,
    );

    expect(node.label, contains('Ease 3'));
    for (final String stateWord in <String>['selected', 'Selected', 'chosen', 'active']) {
      expect(node.label, isNot(contains(stateWord)), reason: stateWord);
    }

    handle.dispose();
    await tester.closeApp();
  });

  // ---------------------------------------------------------------------------
  // T05 — care events as EXISTS
  // ---------------------------------------------------------------------------

  testWidgets('an unrecorded care event renders as not recorded, never as no', (
    WidgetTester tester,
  ) async {
    // THE ANCHOR, AND THE FAILURE MODE IS NOT A MISSING LABEL — IT IS A
    // PLAUSIBLE WRONG ONE. Decision #43 and `07 §6.2`: a shepherd who did not
    // dip a navel has recorded NOTHING, and the app must not turn that into a
    // claim. There is no way to record "no" anywhere in this product.
    //
    // So the case asserts the unset line's own words AND that the three
    // plausible wrong ones appear on no care line at all.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    for (final CareKind kind in CareKind.values) {
      final Finder line = find.byKey(Key('lambing_entry.care.${kind.key}'));
      expect(line, findsOneWidget, reason: kind.key);

      // THE STATE IS IN THE SEMANTIC LABEL, which is where a screen reader
      // finds it and where the eye finds the same words.
      final SemanticsNode node = tester.getSemantics(line);
      expect(node.label, contains('NOT RECORDED'), reason: kind.key);

      for (final String wrong in <String>['No', 'Not given', '0', 'None']) {
        expect(
          node.label.split(RegExp(r'[ ,]')).contains(wrong),
          isFalse,
          reason: '"\$wrong" on \${kind.key} would be a claim the shepherd never made',
        );
      }
    }

    await tester.closeApp();
  });

  testWidgets('recording colostrum prints DONE with the time it was pressed', (
    WidgetTester tester,
  ) async {
    // THE TIME IS WHEN THEY PRESSED IT, not when the lambing was — that is the
    // fact being recorded, and it is what makes an event better than a tick.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    // SCROLLED INTO VIEW FIRST, BECAUSE THE PAGE SCROLLS FROM T04. This is not
    // test ceremony: the care lines sit below the ease group on a real phone,
    // and a case that tapped them without scrolling would be testing a layout
    // no shepherd has.
    final Finder colostrum = find.byKey(const Key('lambing_entry.care.colostrum'));
    await tester.ensureVisible(colostrum);
    await tester.pumpAndSettle();
    await tester.tap(colostrum);
    await tester.pumpAndSettle();

    // COLOSTRUM OPENS ITS DETAIL SHEET; the other three lines commit on the tap.
    // Volume and method exist only for colostrum, and a sheet in front of a
    // navel dip would add a decision to a one-tap act at 03:20 for a field that
    // does not exist.
    // SCROLLED TO, BECAUSE THE SHEET SCROLLS TOO. `indelible.md §7.14` gives it
    // 60% of the viewport and the keypad does not leave room for the button
    // below it — measured. The pad is what must not shrink, so the sheet scrolls.
    final Finder record = find.byKey(const Key('lambing_entry.colostrum.record'));
    expect(record, findsOneWidget);
    await tester.ensureVisible(record);
    await tester.pumpAndSettle();
    await tester.tap(record);
    await tester.pumpAndSettle();

    // THE ROW EXISTS, and its subject is the LAMBING rather than a lamb —
    // exactly one of the two, which is what the CHECK constrains and what
    // `CareSubject` makes unconstructible any other way.
    final CareEvent row = await db.select(db.careEvents).getSingle();
    expect(row.kind, 'colostrum');
    expect(row.lambing, lambing.value);
    expect(row.lamb, isNull);
    expect(row.volumeMl, isNull, reason: 'no default volume — 05 §7.3');
    expect(row.method, isNull, reason: 'no default method');

    final SemanticsNode node = tester.getSemantics(
      find.byKey(const Key('lambing_entry.care.colostrum')),
    );
    expect(node.label, contains('DONE'));
    expect(node.label, isNot(contains('NOT RECORDED')));

    await tester.closeApp();
  });

  testWidgets('removing a care event leaves DONE struck and prints UNDONE with its own time', (
    WidgetTester tester,
  ) async {
    // `indelible.md §7.10`'s UNDONE STATE. The line does NOT revert to unset:
    // both times stay on the page, because the shepherd pressed it at one time
    // and unpressed it at another and both are true. Rule 1 applies to a
    // checkbox exactly as it applies to a lambing.
    //
    // THIS IS ALSO WHERE `07 §15.1` LOSES. It says the undo of removeCare is
    // "re-insert with the original RecordedTime", which implies a delete — and a
    // deleted row has no stamp to strike. P1 put `struck` / `struck_at` on
    // care_events, so the row survives and the rendering is possible.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    final Finder line = find.byKey(const Key('lambing_entry.care.navel_dip'));
    await tester.ensureVisible(line);
    await tester.pumpAndSettle();
    await tester.tap(line);
    await tester.pumpAndSettle();
    await tester.tap(line);
    await tester.pumpAndSettle();

    // THE ROW IS STRUCK, NOT GONE. A delete would satisfy a screen-only
    // assertion about the line reverting, which is why the database is checked.
    final CareEvent row = await db.select(db.careEvents).getSingle();
    expect(row.struck, isTrue);
    expect(row.struckAt, isNotNull);

    expect(find.textContaining('UNDONE'), findsOneWidget);
    expect(
      find.textContaining('DONE'),
      findsWidgets,
      reason: 'the struck DONE stamp stays on the page',
    );

    // AND IT IS ACTUALLY STRUCK. Drilled: removing `TextDecoration.lineThrough`
    // left every other assertion in this case passing, because "the stamp is on
    // the page" and "the stamp is struck" are different claims and only the
    // first was being made. indelible.md §7.10 prints `D̶O̶N̶E̶ ̶0̶3̶:̶2̶4̶ · UNDONE
    // 03:31` — the strike IS the state, not decoration on it.
    final Text doneStamp = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('lambing_entry.care.navel_dip')),
        matching: find.textContaining('DONE').first,
      ),
    );
    expect(
      doneStamp.style?.decoration,
      TextDecoration.lineThrough,
      reason: 'a DONE stamp beside an UNDONE stamp must be struck through',
    );

    await tester.closeApp();
  });

  testWidgets('no care line renders a checkbox glyph and no care line is ever disabled', (
    WidgetTester tester,
  ) async {
    // TWO CLAIMS, BOTH MECHANICAL.
    //
    // NO CHECKBOX: `indelible.md §7.10` — "a tick is a state and this system
    // does not record states, it records events". Asserted against the WIDGET
    // TYPE and against the glyphs, because a Unicode tick in a Text is the
    // version of this that passes a `find.byType(Checkbox)` check.
    //
    // NEVER DISABLED: a dead control under a cold thumb is indistinguishable
    // from a missed tap. Asserted the way keypad_test.dart asserts it — the node
    // announces enabled AND carries a tap action AND actually fires.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(Switch), findsNothing);
    for (final String glyph in <String>['✓', '☑', '☐', '✔']) {
      expect(find.textContaining(glyph), findsNothing, reason: glyph);
    }

    for (final CareKind kind in CareKind.values) {
      final Finder line = find.byKey(Key('lambing_entry.care.${kind.key}'));
      await tester.ensureVisible(line);
      await tester.pumpAndSettle();
      final SemanticsData sd = tester.getSemantics(line).getSemanticsData();
      expect(sd.flagsCollection.isEnabled, Tristate.isTrue, reason: kind.key);
      expect(sd.hasAction(SemanticsAction.tap), isTrue, reason: kind.key);
      expect(
        tester.getSize(line).height,
        greaterThanOrEqualTo(64.0),
        reason: '${kind.key} is a 64 pt line',
      );
    }

    await tester.closeApp();
  });

  testWidgets('a double-fired care press writes one row', (WidgetTester tester) async {
    // DECISION #22. `guard()` refuses to run concurrently, so there is NO PUMP
    // BETWEEN THE TWO TAPS — pumping would make this a test of a press and an
    // undo, which is the previous case and a different claim.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    final Finder line = find.byKey(const Key('lambing_entry.care.warmed'));
    await tester.ensureVisible(line);
    await tester.pumpAndSettle();
    await tester.tap(line);
    await tester.tap(line, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(await db.select(db.careEvents).get(), hasLength(1));

    await tester.closeApp();
  });

  testWidgets('closing the colostrum sheet without a volume still records the feed', (
    WidgetTester tester,
  ) async {
    // THE SHEET ASKS FOR DETAIL, NEVER FOR PERMISSION. The shepherd pressed
    // COLOSTRUM, which means they gave colostrum; dismissing the sheet must not
    // discard that, and the dismiss word says so in as many words.
    //
    // This is the case that would be missing if the sheet were treated as a
    // form — and the row it protects is the one that matters most on this
    // screen, because a lamb that did not get colostrum is the one a shepherd
    // goes back for.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    final Finder colostrum = find.byKey(const Key('lambing_entry.care.colostrum'));
    await tester.ensureVisible(colostrum);
    await tester.pumpAndSettle();
    await tester.tap(colostrum);
    await tester.pumpAndSettle();

    await tester.tap(find.text('CLOSE'));
    await tester.pumpAndSettle();

    final CareEvent row = await db.select(db.careEvents).getSingle();
    expect(row.kind, 'colostrum');
    expect(row.volumeMl, isNull, reason: 'no volume, because they did not give one');
    expect(row.method, isNull);

    await tester.closeApp();
  });

  testWidgets('a volume typed on the keypad is stored exactly, with no placeholder before it', (
    WidgetTester tester,
  ) async {
    // TWO CLAIMS.
    //
    // THE FIELD IS EMPTY UNTIL THEY TYPE (`indelible.md §7.12`): in the dark a
    // grey placeholder is indistinguishable from an entered value, so there is
    // no "e.g. 200", no ghosted last value and no default. Asserted by reading
    // the field's own Text before any key is pressed.
    //
    // THE NUMBER GOES THROUGH THE KEYPAD (decision #57, R70). It is the only
    // number-entry route in the app; a TextField with a numeric keyboard is the
    // thing it exists to replace.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    final Finder colostrum = find.byKey(const Key('lambing_entry.care.colostrum'));
    await tester.ensureVisible(colostrum);
    await tester.pumpAndSettle();
    await tester.tap(colostrum);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing, reason: 'decision #57 — the keypad or nothing');

    final Text field = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('lambing_entry.colostrum.volume')),
        matching: find.byType(Text),
      ),
    );
    expect(field.data, isEmpty, reason: 'empty is empty — no placeholder, no default');

    // ensureVisible PER KEY. `0` is on the bottom row, which starts below the
    // fold in a 60% sheet — and the first version of this case recorded `2`
    // rather than `200`, because the two zero taps landed on nothing and the
    // hit-test warning is not a failure. The assertion caught it; the scroll is
    // what fixes it.
    for (final String digit in <String>['2', '0', '0']) {
      final Finder key = find.byKey(Key('quick_entry.keypad.digit_$digit'));
      await tester.ensureVisible(key);
      await tester.pumpAndSettle();
      await tester.tap(key);
      await tester.pump();
    }
    final Finder tube = find.byKey(const Key('lambing_entry.colostrum.method.Tube'));
    await tester.ensureVisible(tube);
    await tester.pumpAndSettle();
    await tester.tap(tube);
    await tester.pump();

    final Finder record = find.byKey(const Key('lambing_entry.colostrum.record'));
    await tester.ensureVisible(record);
    await tester.pumpAndSettle();
    await tester.tap(record);
    await tester.pumpAndSettle();

    final CareEvent row = await db.select(db.careEvents).getSingle();
    expect(row.volumeMl, 200, reason: 'exactly as typed');
    expect(row.method, 'tube');

    await tester.closeApp();
  });

  // ---------------------------------------------------------------------------
  // T06 — the query mark, which adjusts nothing
  // ---------------------------------------------------------------------------

  testWidgets('a declared type contradicting the strokes prints a query mark and leaves '
      'both values unchanged in the database', (WidgetTester tester) async {
    // THE ANCHOR, AND THE SECOND CLAUSE IS THE ONE THAT MATTERS. A case that
    // only asserted the mark appeared would still pass if the app quietly
    // wrote a third lamb — and that is precisely the failure §12.4 exists to
    // prevent. So `declared_birth_type` AND the lamb ids are captured BEFORE
    // the mark renders, and both are re-read afterwards and compared.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    // Declared TRIPLET, two lambs on the ground. The contradiction is real
    // and the shepherd is the only one allowed to resolve it.
    await (db.update(db.lambings)..where(($LambingsTable t) => t.id.equals(lambing.value))).write(
      const LambingsCompanion(declaredBirthType: Value<int?>(3)),
    );
    await seedLamb(db, lambing, ewe);
    await seedLamb(db, lambing, ewe);

    final Lambing typeBefore = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();
    final List<int> lambsBefore = (await db.select(db.lambs).get()).map((Lamb l) => l.id).toList();

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lambing_entry.query.declared_type')), findsOneWidget);

    final Lambing typeAfter = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();
    final List<int> lambsAfter = (await db.select(db.lambs).get()).map((Lamb l) => l.id).toList();

    expect(typeAfter.declaredBirthType, typeBefore.declaredBirthType, reason: 'not adjusted');
    expect(lambsAfter, lambsBefore, reason: 'no third lamb was quietly written');

    await tester.closeApp();
  });

  testWidgets('no declaration is not a contradiction and prints no mark', (
    WidgetTester tester,
  ) async {
    // R6 AND `03 §5.4`. The view guards NULL explicitly because `COUNT(…) <>
    // NULL` is NULL, which would make `is_mismatched` three-valued for every
    // in-progress lambing; the Dart side needs the same guard. Every lambing on
    // this screen starts undeclared, so getting this wrong would put a query
    // mark on the whole product.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    await seedLamb(db, lambing, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lambing_entry.query.declared_type')), findsNothing);

    await tester.closeApp();
  });

  testWidgets('six lambs on a declared quad-or-more print no mark', (WidgetTester tester) async {
    // THE WHOLE LARGE-LITTER STORY, IN ONE CASE. `expectedLambCount` returns
    // null for `quintPlus` because a declared "quad or more" is OPEN-ENDED, so
    // a contradiction is UNDEFINED rather than false. Encoding it as exactly 5
    // would put a false query mark on every set of sextuplets — the litters a
    // shepherd is most likely to be looking at.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await (db.update(db.lambings)..where(($LambingsTable t) => t.id.equals(lambing.value))).write(
      const LambingsCompanion(declaredBirthType: Value<int?>(5)),
    );
    for (int i = 0; i < 6; i++) {
      await seedLamb(db, lambing, ewe);
    }

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lambing_entry.query.declared_type')), findsNothing);

    await tester.closeApp();
  });

  testWidgets('a struck lamb is not counted against the declaration', (WidgetTester tester) async {
    // THE LABEL ALREADY SAYS SO. A `TWIN (COUNTED, 1 STRUCK)` row has three
    // `lambs` rows and two strokes; comparing against the raw row count puts a
    // mark on a record the shepherd has already corrected — which is the app
    // arguing with a correction it was told about.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await (db.update(db.lambings)..where(($LambingsTable t) => t.id.equals(lambing.value))).write(
      const LambingsCompanion(declaredBirthType: Value<int?>(2)),
    );
    await seedLamb(db, lambing, ewe);
    await seedLamb(db, lambing, ewe);
    final LambId struck = await seedLamb(db, lambing, ewe);
    await (db.update(db.lambs)..where(($LambsTable t) => t.id.equals(struck.value))).write(
      LambsCompanion(
        struck: const Value<bool>(true),
        struckAt: Value<Instant?>(Instant.fromDateTime(DateTime.utc(2026, 3, 14, 4))),
      ),
    );

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('lambing_entry.query.declared_type')),
      findsNothing,
      reason: 'two live lambs against a declared twin is not a contradiction',
    );

    await tester.closeApp();
  });

  testWidgets('changing the birth type writes the declaration and leaves the lambs alone', (
    WidgetTester tester,
  ) async {
    // BOTH HALVES. The sheet offers exactly two ways out and NEITHER adjusts
    // anything: CHANGE writes the declaration and leaves the lambs; LEAVE IT
    // writes nothing to either. There is no third button, because a third button
    // would be the app proposing a fix.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await (db.update(db.lambings)..where(($LambingsTable t) => t.id.equals(lambing.value))).write(
      const LambingsCompanion(declaredBirthType: Value<int?>(3)),
    );
    await seedLamb(db, lambing, ewe);
    await seedLamb(db, lambing, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    final Finder mark = find.byKey(const Key('lambing_entry.query.declared_type'));
    await tester.ensureVisible(mark);
    await tester.pumpAndSettle();
    await tester.tap(mark);
    await tester.pumpAndSettle();

    // THE FIVE VALUES ARE A SECOND STEP, deliberately: putting them on the first
    // screen would make declaring the easy path and leaving it the awkward one,
    // which is backwards.
    expect(find.byKey(const Key('lambing_entry.declare.type_2')), findsNothing);
    await tester.tap(find.byKey(const Key('lambing_entry.declare.change')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('lambing_entry.declare.type_2')));
    await tester.pumpAndSettle();

    final Lambing after = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();
    expect(after.declaredBirthType, 2, reason: 'the shepherd declared it');
    expect(await db.select(db.lambs).get(), hasLength(2), reason: 'the lambs were left alone');

    // AND THE MARK IS GONE, because the contradiction is gone — not because
    // anything was suppressed.
    expect(find.byKey(const Key('lambing_entry.query.declared_type')), findsNothing);

    await tester.closeApp();
  });

  testWidgets('leaving it writes nothing to either value', (WidgetTester tester) async {
    // THE OTHER BRANCH, and without it the case above passes against a sheet
    // whose second button is wired to the first.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await (db.update(db.lambings)..where(($LambingsTable t) => t.id.equals(lambing.value))).write(
      const LambingsCompanion(declaredBirthType: Value<int?>(3)),
    );
    await seedLamb(db, lambing, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    final Finder mark = find.byKey(const Key('lambing_entry.query.declared_type'));
    await tester.ensureVisible(mark);
    await tester.pumpAndSettle();
    await tester.tap(mark);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lambing_entry.declare.leave')));
    await tester.pumpAndSettle();

    final Lambing after = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();
    expect(after.declaredBirthType, 3, reason: 'unchanged');
    expect(await db.select(db.lambs).get(), hasLength(1), reason: 'unchanged');

    // THE MARK STAYS, because the contradiction is still true. A mark that
    // vanished on acknowledgement would be the app forgetting a fact the
    // shepherd looked at and accepted.
    expect(find.byKey(const Key('lambing_entry.query.declared_type')), findsOneWidget);

    await tester.closeApp();
  });

  testWidgets('one mark per field, however many codes fire on it', (WidgetTester tester) async {
    // NEVER TWICE FOR ONE FIELD (`07 §6.3`). Two codes can fire on the same cell
    // — a header time can be both `lambingInFuture` and
    // `lambingLongBeforeCapture` — and the shepherd gets one mark with both
    // findings behind it, not two marks in a column.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await (db.update(db.lambings)..where(($LambingsTable t) => t.id.equals(lambing.value))).write(
      const LambingsCompanion(declaredBirthType: Value<int?>(4)),
    );
    await seedLamb(db, lambing, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lambing_entry.query.declared_type')), findsOneWidget);
    expect(find.text('?'), findsOneWidget, reason: 'one glyph, not one per code');

    await tester.closeApp();
  });

  testWidgets('a warning on another field does not leak into the birth type mark', (
    WidgetTester tester,
  ) async {
    // THE GROUPING IS BY `fieldPath`, AND THIS IS THE CASE THAT MAKES THAT
    // CLAIM. Drilled: `_warningsOn` returning EVERY warning regardless of field
    // passed every other case in this file, because no other case has two
    // warnings on two different cells at once. Here the header time is in the
    // future AND the declaration contradicts the strokes, so a mark that
    // ignored `fieldPath` would list the time finding under the birth type.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await (db.update(db.lambings)..where(($LambingsTable t) => t.id.equals(lambing.value))).write(
      LambingsCompanion(
        declaredBirthType: const Value<int?>(3),
        occurredAt: Value<Instant>(Instant.fromDateTime(DateTime.utc(2030, 3, 14, 3, 20))),
      ),
    );
    await seedLamb(db, lambing, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    final Finder mark = find.byKey(const Key('lambing_entry.query.declared_type'));
    await tester.ensureVisible(mark);
    await tester.pumpAndSettle();
    await tester.tap(mark);
    await tester.pumpAndSettle();

    // The sheet lists what was found ON THIS CELL and nothing else.
    expect(find.textContaining('future'), findsNothing, reason: 'that is the time cell\'s finding');

    await tester.closeApp();
  });

  // ---------------------------------------------------------------------------
  // T07 — correctOccurredAt and the provenance header
  // ---------------------------------------------------------------------------

  testWidgets('a corrected time renders both the captured and the corrected time with the '
      'provenance label', (WidgetTester tester) async {
    // THE ANCHOR. Three clauses, and the third is the one that survives an
    // edit to the wording: the label is compared against
    // `RecordedTime.provenanceLabel` — THE GETTER — and never against a
    // literal. `12 §10.1`'s `Disclaimers.withdrawalProvenance` case is the
    // same trick for the same reason.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    final Finder header = find.byKey(const Key('lambing_entry.provenance_header'));
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    await tester.tap(header);
    await tester.pumpAndSettle();

    for (final String digit in <String>['0', '3', '2', '0']) {
      final Finder key = find.byKey(Key('quick_entry.keypad.digit_$digit'));
      await tester.ensureVisible(key);
      await tester.pumpAndSettle();
      await tester.tap(key);
      await tester.pump();
    }

    final Finder confirm = find.byKey(const Key('lambing_entry.time_editor.confirm'));
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    // THE CORRECTED TIME, 24-hour en_GB.
    expect(find.text('03:20'), findsOneWidget);

    // AND THE ORIGINAL, because a label saying a time was edited without
    // saying what it was edited FROM is true and useless.
    expect(find.byKey(const Key('lambing_entry.provenance_was')), findsOneWidget);
    expect(find.byKey(const Key('lambing_entry.provenance_dagger')), findsOneWidget);

    // THE LABEL IS THE GETTER'S, not a literal in this file.
    final Lambing row = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();
    final RecordedTime stored = recordedTimeFromColumns(
      effective: row.occurredAt,
      capturedAt: row.capturedAt,
      originalEffective: row.originalEffective,
      sourceKey: row.timeSource,
    );
    expect(stored.source, TimeSource.userEdited);
    expect(find.text(stored.provenanceLabel), findsOneWidget);

    await tester.closeApp();
  });

  testWidgets('the header is on screen before anything is corrected', (WidgetTester tester) async {
    // ALWAYS VISIBLE (`07 §4`'s screen matrix). §12.5 is unrepresentable in the
    // domain — RecordedTime has no constructor that makes a time without a
    // source — and this header is the one place that claim reaches the shepherd.
    // A header that only appeared after an edit would make the mechanism true
    // and the product silent about it.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lambing_entry.provenance')), findsOneWidget);
    expect(find.byKey(const Key('lambing_entry.provenance_time')), findsOneWidget);

    // AND THE EDIT MARKS ARE ABSENT, because nothing was edited. An always-on
    // dagger would make the mark meaningless.
    expect(find.byKey(const Key('lambing_entry.provenance_dagger')), findsNothing);
    expect(find.byKey(const Key('lambing_entry.provenance_was')), findsNothing);

    await tester.closeApp();
  });

  testWidgets('the time editor is the app keypad, never a Material picker', (
    WidgetTester tester,
  ) async {
    // THE SINGLE MOST LIKELY SHORTCUT ON THIS SCREEN, held mechanically. Three
    // rules forbid the Material pickers: both are dialog call sites and the gate
    // bans those outside two destructive files; the time picker defaults to the
    // DIAL, which is a drag gesture banned outright (#101); and its input mode is
    // a text field with a numeric keyboard, which #57 replaced.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    final Finder header = find.byKey(const Key('lambing_entry.provenance_header'));
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    await tester.tap(header);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quick_entry.keypad')), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(Dialog), findsNothing);

    await tester.closeApp();
  });

  testWidgets('an impossible time commits nothing and is never clamped', (
    WidgetTester tester,
  ) async {
    // §12.4. Silently turning 25:99 into 23:59 is a correction the shepherd did
    // not make, and it would be invisible: the field would simply show a
    // different time from the one they typed. The button stays live — a greyed
    // control at 03:20 reads as a broken app — and pressing it does nothing.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    final Lambing before = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();

    await tester.pumpApp(LambingEntryScreen(lambingId: lambing), db: db);
    await tester.pumpAndSettle();

    final Finder header = find.byKey(const Key('lambing_entry.provenance_header'));
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    await tester.tap(header);
    await tester.pumpAndSettle();

    for (final String digit in <String>['2', '5', '9', '9']) {
      final Finder key = find.byKey(Key('quick_entry.keypad.digit_$digit'));
      await tester.ensureVisible(key);
      await tester.pumpAndSettle();
      await tester.tap(key);
      await tester.pump();
    }

    final Finder confirm = find.byKey(const Key('lambing_entry.time_editor.confirm'));
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    final Lambing after = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();

    expect(after.occurredAt, before.occurredAt, reason: 'not clamped to 23:59');
    expect(after.timeSource, 'auto', reason: 'nothing was edited');
    expect(after.originalEffective, isNull);

    await tester.closeApp();
  });
}

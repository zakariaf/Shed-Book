// test/features/quick_entry_test.dart
//
// The tag index and the Quick Entry controller. The anchor has two halves that
// fail independently, and that split is the point: a `LIKE '%12%'` implementation
// passes the ORDER half and fails the STATEMENT-COUNT half, which is precisely
// the implementation 03 §9.1 rules out.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/domain/tag_match.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:flutter/material.dart';
import 'package:shed_book/features/quick_entry/quick_entry_controller.dart';
import 'package:shed_book/core/ui/components/shed_animal_row.dart';
import 'package:shed_book/core/ui/feedback.dart';
import 'package:shed_book/features/quick_entry/quick_entry_screen.dart';
import 'package:shed_book/features/quick_entry/quick_entry_write_controller.dart';

import '../support/harness.dart';
import '../support/reads.dart';
import '../support/seeds.dart';

/// Counts every statement that reaches the database.
///
/// The anchor's second half is mechanical because of this: "no database read"
/// is a NUMBER, not a claim about the shape of the code.
class _CountingInterceptor extends QueryInterceptor {
  int statements = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    statements += 1;
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = testDatabase();
    container = shedContainer(db);
  });

  Future<List<TagIndexEntry>> settledIndex() async {
    // fireImmediately keeps the keepAlive provider subscribed for the test's
    // life the way a mounted hub screen does.
    container.listen<AsyncValue<List<TagIndexEntry>>>(
      tagIndexProvider,
      (AsyncValue<List<TagIndexEntry>>? p, AsyncValue<List<TagIndexEntry>> n) {},
      fireImmediately: true,
    );
    return container.read(tagIndexProvider.future);
  }

  test('typing 12 reorders the match list in the same frame with no database read', () async {
    // THE ANCHOR.
    await seedEwe(db, tag: '412');
    await seedEwe(db, tag: '128');
    await seedEwe(db, tag: '12');

    await settledIndex();

    container.listen<QuickEntryState>(
      quickEntryControllerProvider,
      (QuickEntryState? p, QuickEntryState n) {},
      fireImmediately: true,
    );
    final QuickEntryController controller = container.read(quickEntryControllerProvider.notifier);

    // FIRST HALF — SAME FRAME. No await between the keystrokes and the read: an
    // asynchronous implementation still holds the old list at this moment and
    // fails on the order, which is the right failure.
    controller.appendDigit('1');
    controller.appendDigit('2');

    expect(
      container.read(quickEntryControllerProvider).matches.map((TagIndexEntry e) => e.tag).toList(),
      <String>['12', '128', '412'],
      reason: 'exact, then prefix, then suffix, then infix — 03 §9.1',
    );
  });

  test('the two keystrokes issue exactly zero statements', () async {
    // SECOND HALF OF THE ANCHOR, in its own case so the two failure modes never
    // hide each other. Counting is what makes the claim mechanical.
    final _CountingInterceptor counter = _CountingInterceptor();
    final AppDatabase counted = AppDatabase(
      testConnection().interceptWith(counter),
      seedOnCreate: true,
    );
    addTearDown(counted.close);

    final ProviderContainer own = shedContainer(counted);
    await seedEwe(counted, tag: '412');
    await seedEwe(counted, tag: '128');
    await seedEwe(counted, tag: '12');

    own.listen<AsyncValue<List<TagIndexEntry>>>(
      tagIndexProvider,
      (AsyncValue<List<TagIndexEntry>>? p, AsyncValue<List<TagIndexEntry>> n) {},
      fireImmediately: true,
    );
    await own.read(tagIndexProvider.future);

    own.listen<QuickEntryState>(
      quickEntryControllerProvider,
      (QuickEntryState? p, QuickEntryState n) {},
      fireImmediately: true,
    );
    final QuickEntryController controller = own.read(quickEntryControllerProvider.notifier);

    // THE COUNTER IS PROVED NON-VACUOUS FIRST. A zero delta means nothing if the
    // interceptor was never wired — that is exactly how a "no database read"
    // case passes against an implementation that reads the database on every
    // keystroke through a connection the test is not watching.
    expect(counter.statements, greaterThan(0), reason: 'the interceptor must be counting');

    final int before = counter.statements;
    controller.appendDigit('1');
    controller.appendDigit('2');
    final int after = counter.statements;

    expect(
      after - before,
      0,
      reason: 'ranking is pure Dart over an in-memory list; a LIKE implementation fails here',
    );
  });

  test('the index holds active animals only', () async {
    // Decision-record §7.0 ruling 7, and it is not a filter for tidiness: the
    // partial unique index and the create-on-the-fly match are the SAME
    // active-only set, so typing 412 can never surface two live candidates and
    // never needs a disambiguation dialog at 03:20.
    final EweId culled = await seedEwe(db, tag: '412');
    await seedEwe(db, tag: '413');

    await (db.update(db.ewes)..where(($EwesTable t) => t.id.equals(culled.value))).write(
      const EwesCompanion(status: Value<String>('culled')),
    );

    final List<TagIndexEntry> index = await settledIndex();
    expect(index.map((TagIndexEntry e) => e.tag), <String>['413']);
  });

  test('an entry whose digits are empty is in the index and never scores', () async {
    // ewes.tag_digits is withLength(min: 0), so a tag like RED projects to ''.
    // It is unreachable by keypad, which is correct — and it must not crash the
    // ranking or be filtered out, because the Flock screen's search box reuses
    // this index at N26 and does show it.
    await seedEwe(db, tag: 'RED');
    await seedEwe(db, tag: '412');

    final List<TagIndexEntry> index = await settledIndex();
    expect(index.map((TagIndexEntry e) => e.tag), containsAll(<String>['RED', '412']));
    expect(index.firstWhere((TagIndexEntry e) => e.tag == 'RED').digits, isEmpty);

    expect(rankTagMatches(index, '4').map((TagIndexEntry e) => e.tag), <String>['412']);
  });

  test('backspace and clearSelection walk the query back down', () async {
    await seedEwe(db, tag: '412');
    await settledIndex();

    container.listen<QuickEntryState>(
      quickEntryControllerProvider,
      (QuickEntryState? p, QuickEntryState n) {},
      fireImmediately: true,
    );
    final QuickEntryController c = container.read(quickEntryControllerProvider.notifier);

    c.appendDigit('4');
    c.appendDigit('1');
    expect(container.read(quickEntryControllerProvider).query, '41');

    c.backspace();
    expect(container.read(quickEntryControllerProvider).query, '4');

    c.clearSelection();
    expect(container.read(quickEntryControllerProvider).query, isEmpty);
    expect(container.read(quickEntryControllerProvider).selected, isNull);
  });

  _shellTests();
  _stripTests();
  _writePathTests();

  test('an empty query matches nothing', () async {
    // rankTagMatches returns const [] for an empty query — the deck shows the
    // recents strip, not the whole flock, and a 400-row list under a thumb at
    // 03:20 is not a starting state.
    await seedEwe(db, tag: '412');
    await settledIndex();

    container.listen<QuickEntryState>(
      quickEntryControllerProvider,
      (QuickEntryState? p, QuickEntryState n) {},
      fireImmediately: true,
    );

    expect(container.read(quickEntryControllerProvider).query, isEmpty);
    expect(container.read(quickEntryControllerProvider).matches, isEmpty);
  });
}

/// The named boxes the shell reserves. A failure names WHICH box moved, which is
/// the whole reason they are enumerated rather than compared as a tree.
const List<String> _shellBoxes = <String>[
  'quick_entry.page_header',
  'quick_entry.spine',
  'quick_entry.margin_cell',
  'quick_entry.penned_strip',
  'quick_entry.recents_strip',
  'quick_entry.keypad',
  'quick_entry.confirm',
  'quick_entry.bottom_band',
  'quick_entry.slab',
];

void _shellTests() {
  for (final Device device in Device.all) {
    for (final double scale in <double>[1.0, 1.3]) {
      testWidgets('frame 1 with no data occupies the same boxes as frame 2 with data — '
          '${device.name} at $scale', (WidgetTester tester) async {
        // THE ANCHOR. Rect equality on NAMED boxes, and EXACT rather than
        // approximate: the claim is that nothing moves under a thumb, and a 3 pt
        // shift is enough to mis-target a 64 pt key. The thumb is already
        // committed by the time the data arrives.
        //
        // Run at all three devices, because a box that is stable at 390 x 844
        // and shifts at 375 x 667 is the bug this exists for.
        final AppDatabase db = testDatabase();

        await tester.pumpApp(const QuickEntryScreen(), db: db, device: device, textScale: scale);
        final Map<String, Rect> frameOne = <String, Rect>{
          for (final String id in _shellBoxes) id: tester.getRect(find.byKey(Key(id))),
        };

        final PenId pen = await seedPen(db, label: 'A');
        for (int i = 0; i < 6; i++) {
          final EweId e = await seedEwe(db, tag: '40$i');
          await seedTouch(db, e);
          if (i == 0) {
            await seedPenOccupancy(db, pen, e);
          }
        }
        await tester.pumpAndSettle();

        for (final String id in _shellBoxes) {
          expect(
            tester.getRect(find.byKey(Key(id))),
            frameOne[id],
            reason: '$id moved between frame 1 and frame 2 — ${device.name} at $scale',
          );
        }

        await tester.closeApp();
      });
    }
  }

  test('the shell watches nothing, which is why its boxes cannot move', () {
    // THE STRUCTURAL GUARANTEE, AND A DRILL IS WHY IT IS HERE. Planting a
    // data-dependent height on a strip did NOT redden the rect anchor — because
    // the anchor compares frame 1 to frame 2 on the SAME device, and a height
    // that varies with anything other than the deck is invisible to it.
    //
    // What actually makes the boxes immovable is that this screen has no channel
    // to move them through: a StatelessWidget that watches nothing cannot be
    // rebuilt by a keystroke or by an emission (02 §10.1). That is source text,
    // and it is the assertion the anchor cannot make for itself.
    final String source = File(
      'lib/features/quick_entry/quick_entry_screen.dart',
    ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

    // AMENDED AT N14-T03, AND THE PROPERTY SHARPENED RATHER THAN WEAKENED. The
    // write path needs one `ref.listen`, which lives in a private child
    // (_QuickEntryPage) so QuickEntryScreen itself stays a StatelessWidget.
    //
    // What actually makes the boxes immovable is that NOTHING ON THIS SCREEN
    // REBUILDS FROM A WRITE: `ref.listen` fires a callback and does not rebuild,
    // and there is no `ref.watch` in this file at all. The two strips watch one
    // level down, inside boxes whose height is fixed — so a rebuild there moves
    // nothing above it.
    // AMENDED AGAIN AT N14-T06. The confirm bar is a ConsumerWidget that WATCHES
    // the typed query — it has to, because its label is "Use 412" or "Create
    // 412" depending on what has been typed. So `no ref.watch in the file` is no
    // longer the property.
    //
    // What still holds, and is what the boxes actually rest on: QuickEntryScreen
    // is a StatelessWidget, and every watch in this file is inside a widget whose
    // box is FIXED — the confirm bar's height is tapHero whatever it renders, so
    // a rebuild there cannot move anything above or below it.
    expect(source, contains('class QuickEntryScreen extends StatelessWidget'));
    expect(source, isNot(contains('ConsumerStatefulWidget')));

    // Every watcher sits inside a SizedBox with a literal height from _Grid or
    // the tap scale. Asserted structurally: the page's own build has no watch.
    final int pageBuildStart = source.indexOf('class _QuickEntryPage');
    final int pageBuildEnd = source.indexOf('class _StrikeAffordance');
    expect(
      source.substring(pageBuildStart, pageBuildEnd),
      isNot(contains('ref.watch')),
      reason: 'a watch in the PAGE would rebuild every box on every emission',
    );
  });

  testWidgets('the live row does not scroll away', (WidgetTester tester) async {
    // THIS TASK OWNS THE CORRECTION. indelible.html:1138 puts the live row inside
    // the scrolling stream, so the open row scrolls away — the audit block's
    // Indelible artefact defect 1. The corrected rule is that it is a FIXED layer
    // welded above the bottom band, and the reason is the mechanism §8 describes:
    // "you can see it, in ink, one line above." A row you have to scroll to find
    // is not a receipt.
    final AppDatabase db = testDatabase();
    await tester.pumpApp(const QuickEntryScreen(), db: db);

    final Rect before = tester.getRect(find.byKey(const Key('quick_entry.live_row')));

    await tester.drag(find.byKey(const Key('quick_entry.record_column')), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byKey(const Key('quick_entry.live_row'))), before);
    await tester.closeApp();
  });

  testWidgets('the spine is continuous and does not mirror', (WidgetTester tester) async {
    // indelible.md §4.3: it does not break for headers, sheets, sections or the
    // live row, and left-handed mode moves the SLAB, not the spine.
    final AppDatabase db = testDatabase();
    await tester.pumpApp(const QuickEntryScreen(), db: db);

    final Rect spine = tester.getRect(find.byKey(const Key('quick_entry.spine')));
    final Rect header = tester.getRect(find.byKey(const Key('quick_entry.page_header')));
    final Rect band = tester.getRect(find.byKey(const Key('quick_entry.bottom_band')));

    expect(spine.top, lessThanOrEqualTo(header.top));
    expect(spine.bottom, greaterThanOrEqualTo(band.bottom));
    expect(spine.width, greaterThan(0));
    await tester.closeApp();
  });

  testWidgets('frame 1 is interactive — the keypad works before the database opens', (
    WidgetTester tester,
  ) async {
    // Decision #21's whole promise, and the reason the sheet is OPEN on frame 1
    // rather than waiting for a tap. The keypad watches nothing and needs
    // nothing, so it is usable on the first painted frame.
    final AppDatabase db = testDatabase();
    await tester.pumpApp(const QuickEntryScreen(), db: db);

    expect(find.byKey(const Key('quick_entry.entry_sheet')), findsOneWidget);
    expect(find.byKey(const Key('quick_entry.keypad')), findsOneWidget);
    await tester.tap(find.byKey(const Key('quick_entry.keypad.digit_4')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.closeApp();
  });
}

void _stripTests() {
  testWidgets('the penned strip is ascending by entered_at and each strip has its own empty '
      'copy', (WidgetTester tester) async {
    // THE ANCHOR, in two halves that fail separately.
    //
    // HALF 1 — ORDERING. Four occupancies seeded in a deliberately shuffled
    // order, read top to bottom. The oldest must be first, because the
    // longest-penned ewe is the one you are standing next to (07 §5.2).
    // Rendering both strips newest-first feels tidier and is wrong.
    final AppDatabase db = testDatabase();
    final Instant base = Instant.fromDateTime(DateTime.utc(2026, 3, 1, 3, 20));

    final List<(String, int)> shuffled = <(String, int)>[
      ('twelve', -12 * 60),
      ('thirtyOne', -31 * 60),
      ('forty', -40),
      ('four', -4 * 60),
    ];
    for (final (String label, int mins) in shuffled) {
      final PenId pen = await seedPen(db, label: label);
      final EweId e = await seedEwe(db, tag: '${100 - mins}');
      await seedPenOccupancy(db, pen, e, enteredAt: base.plus(Duration(minutes: mins)));
    }

    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();

    final List<String> pens = tester
        .widgetList<ShedAnimalRow>(
          find.descendant(
            of: find.byKey(const Key('quick_entry.penned_strip')),
            matching: find.byType(ShedAnimalRow),
          ),
        )
        .map((ShedAnimalRow r) => r.summary)
        .toList();

    // A PREFIX, NOT THE WHOLE LIST, AND THE REASON IS A CONFLICT WORTH NAMING.
    // indelible.md §7.15 wants SIX full-width 64 px ruled lines per bucket —
    // 384 pt each, 768 for both — and the page has 96 pt per strip to give
    // before it over-commits the viewport again (see the screen's own header for
    // that arithmetic). So the box shows one or two rows and the ListView builds
    // only those.
    //
    // What this case is FOR is the ORDERING, and the prefix tests it completely:
    // if the strip were descending, the first row would be `forty`. The bucket's
    // full six-row content is asserted at the repository tier, where no box
    // clips it.
    expect(
      pens.first,
      'thirtyOne',
      reason: 'longest-penned first — the one you are standing next to (07 §5.2)',
    );
    expect(
      pens,
      <String>['thirtyOne', 'twelve', 'four', 'forty'].take(pens.length).toList(),
      reason: 'ascending, in order, as far as the box shows',
    );

    await tester.closeApp();
  });

  testWidgets('the two empty strings are distinct and land in the right box', (
    WidgetTester tester,
  ) async {
    // HALF 2. A single shared "Nothing here yet" passes a careless test and is
    // the defect this case exists to catch: it tells a shepherd nothing about
    // WHICH list is empty.
    final AppDatabase db = testDatabase();

    // Neither bucket.
    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();
    expect(find.text('Nothing penned yet.'), findsOneWidget);
    expect(find.text('No recent animals.'), findsOneWidget);
    await tester.closeApp();

    // Recents only.
    final AppDatabase db2 = testDatabase();
    final EweId e = await seedEwe(db2, tag: '412');
    await seedTouch(db2, e);
    await tester.pumpApp(const QuickEntryScreen(), db: db2);
    await tester.pumpAndSettle();
    expect(find.text('Nothing penned yet.'), findsOneWidget);
    expect(find.text('No recent animals.'), findsNothing);
    await tester.closeApp();

    // Penned only. A pen occupancy does not touch the ewe, so recents stays
    // empty — which is what makes this the mirror case rather than a repeat.
    final AppDatabase db3 = testDatabase();
    final PenId pen = await seedPen(db3, label: 'A');
    final EweId e3 = await seedEwe(db3, tag: '128');
    await seedPenOccupancy(db3, pen, e3);
    await tester.pumpApp(const QuickEntryScreen(), db: db3);
    await tester.pumpAndSettle();
    expect(find.text('Nothing penned yet.'), findsNothing);
    expect(find.text('No recent animals.'), findsOneWidget);
    await tester.closeApp();
  });

  testWidgets('neither strip scrolls horizontally', (WidgetTester tester) async {
    // THE RULING, ASSERTED. 07 §5.1 draws the strips as "fixed height,
    // horizontally scrolling"; indelible.md §7.15 draws six full-width ruled
    // lines, and CLAUDE.md's gesture ban names "drag and drag handles". A
    // lateral drag on a 64 pt element is that gesture, and NO GATE ROW CATCHES
    // IT — a horizontal scroll direction is not a banned identifier, so it would
    // have shipped silently. Both buckets are LIMIT 6 in SQL, so there is
    // nothing to scroll to.
    final AppDatabase db = testDatabase();
    final PenId pen = await seedPen(db, label: 'A');
    final EweId e = await seedEwe(db, tag: '412');
    await seedPenOccupancy(db, pen, e);
    await seedTouch(db, e);

    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();

    for (final Scrollable s in tester.widgetList<Scrollable>(find.byType(Scrollable))) {
      expect(s.axisDirection, isNot(AxisDirection.right), reason: 'no horizontal scroll');
      expect(s.axisDirection, isNot(AxisDirection.left), reason: 'no horizontal scroll');
    }

    await tester.closeApp();
  });

  testWidgets('the recents strip watches no ticker', (WidgetTester tester) async {
    // 07 §5.2: the recents strip shows no time at all, so watching the minute
    // tick there would rebuild six rows every sixty seconds to change nothing.
    // Source text, because "does not watch" has no runtime signature.
    final String source = File(
      'lib/features/quick_entry/widgets/recents_strip.dart',
    ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

    expect(source, isNot(contains('minuteTickProvider')));
    expect(source, isNot(contains('ticker')));
  });
}

void _writePathTests() {
  testWidgets('a double tap on the lambing verb creates exactly one lambing', (
    WidgetTester tester,
  ) async {
    // THE ANCHOR, AND THE SHAPE OF THE TAPS IS THE TEST. NO PUMP BETWEEN THEM:
    // 02 §7.1 rule 4 spells out why — with a pump in the middle the first write
    // completes, state becomes WriteDone, and the second tap legitimately
    // produces a second row. The test would fail and rule 1 says it is right to.
    //
    // A cold thumb on capacitive glass through a bag double-fires. It is
    // hardware, not user error, and without guard() the second fire is a second
    // lambing record — a data-integrity bug produced by hardware, in the one
    // part of the product that exists to eliminate exactly that.
    final AppDatabase db = testDatabase();
    final SeasonId season = await _seedCurrentSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    expect(season, isA<SeasonId>());

    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();

    // Select her first — the verb is a no-op with nothing selected, which is
    // itself the "does the shepherd have to do anything new?" answer.
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('quick_entry.keypad'))),
    );
    container.read(quickEntryControllerProvider.notifier).select(ewe);
    await tester.pump();

    final Finder lambing = find.byKey(const Key('quick_entry.event.lambing'));
    await tester.tap(lambing);
    await tester.tap(lambing);
    await tester.pumpAndSettle();

    expect(await countLambings(db), 1);
    await tester.closeApp();
  });

  testWidgets('a second tap after the first completes creates a second lambing', (
    WidgetTester tester,
  ) async {
    // 02 §7.1 rule 1: guard() prevents CONCURRENCY, NOT REPETITION. Stated as a
    // test so nobody adds a cooldown to make the anchor "safer" — a cooldown
    // would drop a legitimate second lambing, and a ewe lambs in more than one
    // season.
    final AppDatabase db = testDatabase();
    await _seedCurrentSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');

    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('quick_entry.keypad'))),
    );
    container.read(quickEntryControllerProvider.notifier).select(ewe);
    await tester.pump();

    final Finder lambing = find.byKey(const Key('quick_entry.event.lambing'));
    await tester.tap(lambing);
    await tester.pumpAndSettle();
    await tester.tap(lambing);
    await tester.pumpAndSettle();

    expect(await countLambings(db), 2);
    await tester.closeApp();
  });

  testWidgets('the lambing verb is a no-op with nothing selected', (WidgetTester tester) async {
    // Not a disabled button — no key is ever disabled. Pressing it with no
    // animal chosen simply writes nothing, because there is nothing to write it
    // against, and a dead-looking control under a cold thumb is worse than one
    // that does nothing quietly.
    final AppDatabase db = testDatabase();
    await _seedCurrentSeason(db);

    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quick_entry.event.lambing')));
    await tester.pumpAndSettle();

    expect(await countLambings(db), 0);
    expect(tester.takeException(), isNull);
    await tester.closeApp();
  });

  testWidgets('createEwe through the controller commits even at two seasons over the cap', (
    WidgetTester tester,
  ) async {
    // THE liveEntry PARAMETER, ASSERTED AS BEHAVIOUR — a drill found this
    // missing: swapping it for EntryContext.calm reddened nothing, because no
    // case exercised the controller's own choice.
    //
    // Two seasons and not unlocked is the state where the calm path refuses.
    // Here it must commit, because decision #91 says a shepherd mid-lambing is
    // never told to pay.
    //
    // **AND THAT DRILL ONLY HOLDS OUTSIDE QUIET HOURS.** `FreeTierPolicy.decide`
    // runs `isQuietHours(now)` BEFORE it refuses anything — *"the app does not
    // solicit at night, even in a calm context"* — so between 22:00 and 06:00 the
    // calm path commits too, and this case stops being able to tell the two
    // contexts apart. It reads the real clock through the controller's
    // `appNow()`, so for eight hours a day it was asserting nothing at all: green
    // either way, which is worse than red.
    //
    // The sibling of this bug was a genuine failure rather than a weakening —
    // `flock_repository_test`'s calm arm asserts the REFUSAL, so it went red
    // every night. That one is what led here.
    //
    // 14:00, nowhere near either boundary. A single-instant assertion, so the
    // freeze is the right tool (`12 §2.2`) and nothing here measures elapsed time.
    final AppDatabase db = testDatabase();
    await _seedCurrentSeason(db);
    await _seedCurrentSeason(db, year: 2027);

    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('quick_entry.keypad'))),
    );
    await atFixed(
      DateTime.utc(2026, 3, 14, 14),
      () => container.read(quickEntryWriteControllerProvider.notifier).createEwe('412'),
    );
    await tester.pumpAndSettle();

    expect(
      (await db.select(db.ewes).get()).where((Ewe e) => e.tag == '412'),
      hasLength(1),
      reason: 'EntryContext.liveEntry makes a refusal unreachable here',
    );
    await tester.closeApp();
  });

  testWidgets('the undo window is stated in seconds and does not survive a restart', (
    WidgetTester tester,
  ) async {
    // THE ANCHOR, IN TWO HALVES.
    final AppDatabase db = testDatabase();
    await _seedCurrentSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');

    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('quick_entry.keypad'))),
    );
    container.read(quickEntryControllerProvider.notifier).select(ewe);
    await tester.pump();

    await tester.tap(find.byKey(const Key('quick_entry.event.lambing')));
    await tester.pumpAndSettle();

    // HALF 1 — STATED IN SECONDS, read from the CONSTANT and never a literal, so
    // a changed constant changes the copy or this fails.
    expect(find.byKey(const Key('quick_entry.strike')), findsOneWidget);
    expect(find.textContaining('${kStrikeWindow.inSeconds}'), findsOneWidget);

    // The window is tied to the widget, not to a timer that outlives the screen.
    await tester.pump(kStrikeWindow + const Duration(seconds: 1));
    expect(
      find.byKey(const Key('quick_entry.strike')),
      findsNothing,
      reason: 'the window closes and the affordance goes with it',
    );

    await tester.closeApp();

    // HALF 2 — IT DOES NOT SURVIVE A RESTART. Same database, fresh tree: the row
    // is still there and the affordance is not. 01 §4.5 and 07 §15.4 — there is
    // no state restoration, no undo affordance is ever rebuilt from storage, and
    // no copy anywhere may say "you can undo this later".
    expect(await countLambings(db), 1);

    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quick_entry.strike')), findsNothing);
    expect(await countLambings(db), 1, reason: 'the row survives; the affordance does not');

    await tester.closeApp();
  });

  testWidgets('striking leaves the row in place', (WidgetTester tester) async {
    // A STRIKE IS NOT A DELETE. The row keeps its position and its legibility,
    // permanently — Indelible Rule 1.
    final AppDatabase db = testDatabase();
    await _seedCurrentSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');

    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('quick_entry.keypad'))),
    );
    container.read(quickEntryControllerProvider.notifier).select(ewe);
    await tester.pump();

    await tester.tap(find.byKey(const Key('quick_entry.event.lambing')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick_entry.strike')));
    await tester.pumpAndSettle();

    expect(await countLambings(db), 1);
    final Lambing row = (await db.select(db.lambings).get()).single;
    expect(row.struck, isTrue);
    expect(row.struckAt, isNotNull);

    await tester.closeApp();
  });

  test('the strike window is a constant, and the copy reads it', () {
    final String arb = File('lib/l10n/app_en.arb').readAsStringSync();
    expect(arb, contains(r'{seconds}s to strike'));
    expect(arb, isNot(contains('20s to strike')));

    final String screen = File(
      'lib/features/quick_entry/quick_entry_screen.dart',
    ).readAsStringSync();
    expect(screen, contains('kStrikeWindow.inSeconds'));
  });

  test('no copy anywhere promises a later undo', () {
    // MESSAGE VALUES ONLY, never the descriptions — the thirtieth
    // prohibition-versus-claim self-match: quickEntryStrikeWindow's own
    // description explains why no copy may promise a later undo, and to do that
    // it says the phrase.
    final Map<String, dynamic> arb =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;

    for (final MapEntry<String, dynamic> e in arb.entries) {
      if (e.key.startsWith('@') || e.value is! String) {
        continue;
      }
      final String value = (e.value as String).toLowerCase();
      for (final String phrase in <String>['undo this later', 'you can undo', 'undo it later']) {
        expect(value, isNot(contains(phrase)), reason: '${e.key}: $phrase');
      }
    }
  });

  test('the screen listens once and its switch has no default arm', () {
    // The exhaustive switch is the mechanism: WriteOutcome is sealed with three
    // variants, and a `default:` would swallow the fourth on the day it lands.
    // Source text, because "has no default" has no runtime signature.
    final String source = File(
      'lib/features/quick_entry/quick_entry_screen.dart',
    ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

    expect('ref.listen'.allMatches(source).length, 1, reason: '02 §7: one place feedback happens');
    // Matched on the CASE KEYWORD rather than the empty-parens form: N14-T04
    // gave each arm a destructuring pattern, so `case WriteCommitted()` is no
    // longer the literal in the file. What the case guards is that all three
    // arms exist and none of them is a default.
    expect(source, contains('case WriteCommitted('));
    expect(source, contains('case WriteFailed('));
    expect(source, contains('case WriteRefused('));
    expect(source, isNot(contains('default:')));
  });

  test('Quick Entry does not import the lambing feature', () {
    // layer.sibling (rule 6). 07 §6.1 names lambingWriteControllerProvider for
    // this tap; it lives in lib/features/lambing/, so Quick Entry importing it
    // fails the gate — and it should. That controller is N16's, for writes made
    // FROM Lambing Entry.
    for (final FileSystemEntity f in Directory(
      'lib/features/quick_entry',
    ).listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) {
        continue;
      }
      // IMPORT DIRECTIVES ONLY. The write controller's own doc comment explains
      // why it is not lambingWriteControllerProvider, and naming the path there
      // is the point — the twenty-eighth prohibition-versus-claim self-match.
      final String imports = f
          .readAsLinesSync()
          .where((String l) => l.trimLeft().startsWith('import '))
          .join('\n');
      expect(imports, isNot(contains('features/lambing/')), reason: f.path);
    }
  });
}

/// A season, made current. `beginLambing` never creates one.
Future<SeasonId> _seedCurrentSeason(AppDatabase db, {int year = 2026}) async {
  final Instant now = Instant.fromDateTime(DateTime.utc(2026, 3, 1, 3, 20));
  final int id = await db
      .into(db.seasons)
      .insert(
        SeasonsCompanion.insert(
          year: year,
          label: '$year',
          startDate: LocalDate(year, 1, 1),
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

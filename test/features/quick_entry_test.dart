// test/features/quick_entry_test.dart
//
// The tag index and the Quick Entry controller. The anchor has two halves that
// fail independently, and that split is the point: a `LIKE '%12%'` implementation
// passes the ORDER half and fails the STATEMENT-COUNT half, which is precisely
// the implementation 03 §9.1 rules out.
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/tag_match.dart';
import 'package:flutter/material.dart';
import 'package:shed_book/features/quick_entry/quick_entry_controller.dart';
import 'package:shed_book/features/quick_entry/quick_entry_screen.dart';

import '../support/harness.dart';
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

    expect(source, contains('class QuickEntryScreen extends StatelessWidget'));
    expect(source, isNot(contains('ConsumerWidget')));
    expect(source, isNot(contains('ref.watch')));
    expect(source, isNot(contains('ConsumerStatefulWidget')));
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
  });
}

// test/features/quick_entry_test.dart
//
// The tag index and the Quick Entry controller. The anchor has two halves that
// fail independently, and that split is the point: a `LIKE '%12%'` implementation
// passes the ORDER half and fails the STATEMENT-COUNT half, which is precisely
// the implementation 03 §9.1 rules out.
library;

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/tag_match.dart';
import 'package:shed_book/features/quick_entry/quick_entry_controller.dart';

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

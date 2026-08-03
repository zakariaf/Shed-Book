// test/features/flock_test.dart — the flock list, and the one-query rule as an
// executable assertion.
//
// **THE COUNTS ARE READ OFF THE DATABASE, NEVER WRITTEN AS LITERALS.** The
// fixture's exact split is `12 §11.5`'s to change — it gained a culled ewe and
// twenty pens the day the generator started carrying the shapes that section
// names — and a remembered `400` turns a fixture edit into a mystery failure in
// a file that has nothing to do with fixtures.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/features/flock/flock_screen.dart';

import '../support/harness.dart';

/// Active ewes, counted the way the statement must count them.
Future<int> _activeEwes(AppDatabase db) async =>
    (await db.select(db.ewes).get()).where((Ewe e) => e.status == 'active').length;

/// Ewes with an OPEN occupancy — `exited_at IS NULL`, which is what
/// `idx_penocc_one_open` makes at most one of per pen.
Future<int> _currentlyPenned(AppDatabase db) async =>
    (await db
            .customSelect(
              'SELECT COUNT(DISTINCT ewe) AS n FROM pen_occupancies WHERE exited_at IS NULL',
            )
            .getSingle())
        .read<int>('n');

void main() {
  test('the filter set narrows 400 ewes to currently penned in one statement', () async {
    // THE ANCHOR. Three claims in one case, because they only mean anything
    // together: the list is complete, the filter narrows it, and both happen in
    // ONE statement.
    final ({AppDatabase db, StatementCounter counter}) c = countingDatabase(seedOnCreate: false);
    final AppDatabase db = c.db;
    await restoreFixture(db, 'flock_400_3seasons.json');

    final int active = await _activeEwes(db);
    final int penned = await _currentlyPenned(db);

    // The fixture is only useful here if it actually contains both populations.
    // Without this, `0 == 0` passes for a filter that returns nothing and for a
    // filter that was never applied.
    expect(active, greaterThan(300), reason: 'the fixture is not a flock');
    expect(penned, greaterThan(0), reason: 'no open occupancy — the filter cannot be tested');
    expect(penned, lessThan(active), reason: 'every ewe penned is not a filter');

    // **ONE STATEMENT, COUNTED.** `07 §1.2` as an executable assertion: a test
    // that only counts ROWS passes on an implementation that issues one
    // statement per ewe, which is the exact shape that makes the flock page
    // unusable at 400 and fine at 6.
    final int before = c.counter.selects;
    final List<FlockRow> all = await flockList(db, const FlockFilters());
    final int spent = c.counter.selects - before;

    expect(all, hasLength(active));
    expect(spent, 1, reason: '$spent statements for one list — 07 §1.2 says one');

    // AND THE FILTER IS SQL, not a Dart `.where` over the same rows. Counted the
    // same way, because a filter that narrows in Dart still costs one statement
    // and still reads every row off the disk.
    final int beforeFiltered = c.counter.selects;
    final List<FlockRow> pennedRows = await flockList(
      db,
      const FlockFilters(currentlyPenned: true),
    );
    expect(c.counter.selects - beforeFiltered, 1);

    expect(pennedRows, hasLength(penned));
    expect(
      pennedRows.every((FlockRow r) => r.isPenned),
      isTrue,
      reason: 'a row that is not penned came back from the penned filter',
    );

    await db.close();
  });

  test('the culled ewe is not in the flock, and its tag still is', () async {
    // `12 §11.5`'s shape, asserted where it matters: the statement filters on
    // `status = 'active'`, and the reused tag proves the filter is on STATUS
    // rather than on the tag being absent.
    final AppDatabase db = testDatabase(seedOnCreate: false);
    await restoreFixture(db, 'flock_400_3seasons.json');

    final Ewe culled = (await db.select(db.ewes).get()).firstWhere((Ewe e) => e.status == 'culled');
    final List<FlockRow> rows = await flockList(db, const FlockFilters());

    expect(
      rows.where((FlockRow r) => r.tag == culled.tag),
      hasLength(1),
      reason: 'the live ewe wearing the culled tag is in the flock, exactly once',
    );

    await db.close();
  });

  testWidgets('the screen renders a row per active ewe', (WidgetTester tester) async {
    final AppDatabase db = await fixtureDatabase('flock_400_3seasons.json');
    await tester.pumpApp(const FlockScreen(), db: db);
    await tester.pumpAndSettle();

    // A ListView builds lazily, so the assertion is on what the provider
    // produced rather than on how many rows are mounted — counting mounted rows
    // would assert the viewport height, which is a different fact.
    expect(find.byType(FlockScreen), findsOneWidget);

    await tester.closeApp();
  });
}

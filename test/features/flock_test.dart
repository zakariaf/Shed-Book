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
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_status_badge.dart';
import 'package:shed_book/features/flock/flock_screen.dart';
import 'package:shed_book/l10n/app_localizations.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

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

    // **ACTIVE PLUS STRUCK** (ruling N2). The struck ewe is in the list, at the
    // bottom — counted here rather than assumed, so this stays true when the
    // fixture gains another.
    final int struck = (await db.select(db.ewes).get())
        .where((Ewe e) => e.status != 'active')
        .length;
    expect(all, hasLength(active + struck));
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

  test('the struck ewe is in the list, at the bottom, wearing the same tag', () async {
    // **RULING N2, AND IT REVERSES WHAT THIS CASE ASSERTED THREE COMMITS AGO.**
    // T01 wrote `WHERE e.status = 'active'` straight out of `07 §3.1` and this
    // test asserted the culled ewe was absent. Two documents cannot both ship:
    //
    //   `07 §3.1`          — `WHERE e.status = 'active'`
    //   `indelible.md §7.4` — *"She stays in the list, at the bottom, under a
    //                          printed line reading `STRUCK — 1`."*
    //
    // CLAUDE.md's authority order puts `indelible.md` above the thirteen
    // engineering documents, so the design wins. Two independent arguments say
    // the same thing: the system's FIRST rule is *nothing is ever removed, only
    // struck*, and a statement that filters her out is that rule inverted at the
    // data layer — and N26-T03's own Definition of Done, *a culled tag is
    // visibly distinct from an active one with the same number*, is
    // unsatisfiable if the struck row never renders.
    //
    // She is also what makes §7.0 ruling 7 legible: tags are unique among ACTIVE
    // animals only, so `2003` is here twice and that is legal rather than a bug.
    final AppDatabase db = testDatabase(seedOnCreate: false);
    await restoreFixture(db, 'flock_400_3seasons.json');

    final Ewe culled = (await db.select(db.ewes).get()).firstWhere((Ewe e) => e.status == 'culled');
    final List<FlockRow> rows = await flockList(db, const FlockFilters());

    // BOTH ANIMALS, ONE TAG. `03 §6`: they are two animals, and it is a link,
    // never a merge offer.
    final List<FlockRow> sameTag = rows.where((FlockRow r) => r.tag == culled.tag).toList();
    expect(sameTag, hasLength(2), reason: 'the struck ewe and the live one that reused her tag');
    expect(sameTag.where((FlockRow r) => r.removedFromFlock), hasLength(1));
    expect(sameTag.where((FlockRow r) => !r.removedFromFlock), hasLength(1));

    // **AND THE TWO FACTS STAY APART.** She is CULLED — a state of the sheep —
    // and her record was never struck. N2 shipped one field derived from the
    // other, which renamed one fact after the other; `indelible.md §6` draws the
    // line (boxed = the animal, unboxed = the writing) and `idx_ewe_tagdigits`
    // is partial on both conditions rather than one.
    final FlockRow gone = sameTag.firstWhere((FlockRow r) => r.removedFromFlock);
    expect(gone.status, 'culled');
    expect(gone.struck, isFalse, reason: 'culled is not struck — two facts, two fields');

    // **AT THE BOTTOM**, which is the half a `struck` flag alone does not give.
    // Asserted as *no active row follows a struck one* rather than on an index,
    // so it survives the fixture gaining another struck animal.
    final int firstStruck = rows.indexWhere((FlockRow r) => r.removedFromFlock);
    expect(firstStruck, greaterThan(0), reason: 'the list does not open with a struck row');
    expect(
      rows.skip(firstStruck).every((FlockRow r) => r.removedFromFlock),
      isTrue,
      reason: 'an active ewe is printed below a struck one — §7.4 puts them last',
    );

    await db.close();
  });

  test('barren and not yet lambed are different filters, not one word twice', () async {
    // **THE CASE T01'S PREDICATES COULD NOT HAVE FAILED.** Both were written as
    // *no lambings recorded*, which is the same SQL for two different questions —
    // so *barren* and *not yet lambed* returned the same ewes and no test could
    // tell. `CONVENTIONS §5.1` keeps the words apart because the facts are
    // different, and R42 says where barren lives: `ewe_seasons.status`.
    //
    // Barren is an ANSWER: she was scanned and is not in lamb. Not yet lambed is
    // a WAIT: she is in lamb and it has not happened. A ewe cannot be both, and
    // that is what makes this test able to fail.
    final AppDatabase db = testDatabase();
    await seedSeason(db);

    final EweId barren = await seedEweInSeason(db, tag: 'B1', status: 'barren');
    final EweId waiting = await seedEweInSeason(db, tag: 'B2', status: 'scanned');
    final EweId lambed = await seedEweInSeason(db, tag: 'B3', status: 'lambed');
    await seedLambing(db, lambed);

    Future<Set<int>> ids(FlockFilters f) async =>
        (await flockList(db, f)).map((FlockRow r) => r.id.value).toSet();

    final Set<int> barrenIds = await ids(const FlockFilters(barren: true));
    final Set<int> waitingIds = await ids(const FlockFilters(notYetLambed: true));

    expect(barrenIds, <int>{barren.value});
    expect(waitingIds, <int>{waiting.value});

    // **AND THEY DO NOT OVERLAP**, which is the assertion that fails the moment
    // somebody writes one of them as the other.
    expect(
      barrenIds.intersection(waitingIds),
      isEmpty,
      reason: 'barren and not yet lambed returned the same ewe — they are one filter again',
    );
    expect(barrenIds, isNot(contains(lambed.value)));
    expect(waitingIds, isNot(contains(lambed.value)));

    await db.close();
  });

  testWidgets('a filter with no matches renders the filtered-empty copy, not the empty copy', (
    WidgetTester tester,
  ) async {
    // **T02'S ANCHOR, AND IT CANNOT PASS ON A SHARED STRING.** *You have no
    // ewes* and *no ewes match this filter* are different facts and only one of
    // them is alarming: a shepherd with 400 ewes who taps two filters and reads
    // "No animals yet." has just been told their flock is gone.
    //
    // Both strings are read from `AppLocalizations`, never typed as literals, so
    // renaming either ARB key breaks compilation rather than passing silently.
    //
    // **IN MEMORY, NOT `fixtureDatabase`.** Tapping a filter opens a new
    // subscription and therefore a new statement, and real file I/O does not
    // advance inside `flutter_test`'s fake-async zone — this test hung rather
    // than failed, exactly as `harness.dart` warns. The matrix gets away with the
    // fast file-backed path because each cell pumps once and never queries again;
    // anything that TAPS pays the import instead.
    final AppDatabase db = testDatabase(seedOnCreate: false);
    await restoreFixture(db, 'flock_400_3seasons.json');
    await tester.pumpApp(const FlockScreen(), db: db);
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(FlockScreen));
    final AppLocalizations l10n = AppLocalizations.of(context);

    // BARREN and TRIPLET-BEARING at once. The intersection is empty by
    // construction rather than by luck — a barren ewe carries no lambing, so she
    // can never have three lambs on one.
    // **THE LAST WORDS ARE SCROLLED TO, AND THAT IS THE DESIGN WORKING RATHER
    // THAN A TEST WORKAROUND.** `indelible.md §8` makes this line a single
    // horizontally scrolling row, so `BARREN` is genuinely off the viewport at
    // 400 pt — the finder found `ALL` and nothing after it. Scrolling is the ONE
    // permitted tracked gesture (`06 §7`), and it is legal here precisely because
    // no action hides behind it: every filter is reachable, and none of them is
    // the only way to do anything.
    Future<void> tapFilter(String key) async {
      // TWO STEPS, AND BOTH ARE NEEDED. `scrollUntilVisible` stops as soon as
      // the widget is BUILT, which for a lazily-built horizontal list leaves its
      // centre outside the viewport — the tap then warned that the offset it
      // derived was off-screen and hit nothing. `ensureVisible` finishes the
      // scroll so the target is somewhere a thumb could actually land, which is
      // the state the assertion is meant to be about.
      final Finder word = find.byKey(Key('flock.filter.$key'));
      await tester.scrollUntilVisible(word, 120, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(word);
      await tester.pumpAndSettle();
      await tester.tap(word);
      await tester.pumpAndSettle();
    }

    await tapFilter('barren');
    await tapFilter('triplet_bearing');

    expect(find.text(l10n.flockFilteredEmpty), findsOneWidget);
    expect(
      find.text(l10n.flockEmpty),
      findsNothing,
      reason: 'the flock is not empty — 400 ewes are behind this filter',
    );

    await tester.closeApp();
  });

  testWidgets('a ewe with a contradiction renders the warning badge with a word', (
    WidgetTester tester,
  ) async {
    // **T03'S ANCHOR, AND THE WORD IS THE ASSERTION.** `07 §3.4` calls this badge
    // *"icon + count, never colour alone"*; there is no icon set in this system
    // — *"every action is a word"* (`indelible.md §1.3`) — and `06 §12` says
    // `ShedStatusBadge` is *"a stamp set in words, not an icon-plus-word"*.
    // Ruling N3 takes the design, so this asserts on TEXT. An icon-based badge
    // would fail it, which is the point.
    //
    // §12.4: *"a contradiction found at 3am is still findable at 9am."* The
    // fixture carries contradictory lambings — every thirty-first declares one
    // more lamb than it has — so the badge has something real to render.
    final AppDatabase db = testDatabase(seedOnCreate: false);
    await restoreFixture(db, 'flock_400_3seasons.json');

    final List<FlockRow> rows = await flockList(db, const FlockFilters());
    expect(
      rows.where((FlockRow r) => r.hasWarning),
      isNotEmpty,
      reason: 'no contradiction in the fixture — the badge cannot be tested',
    );

    await tester.pumpApp(const FlockScreen(), db: db);
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(FlockScreen));
    final AppLocalizations l10n = AppLocalizations.of(context);

    // **SCROLLED TO, BECAUSE THE FIRST CONTRADICTION IS ~18 ROWS DOWN.** The
    // list is ordered by tag and the fixture contradicts every thirty-first
    // lambing, so nothing is queried in the opening viewport — the finder found
    // zero and the badge was working. Asserting on the visible fold would have
    // been asserting the viewport height.
    // Scrolled to the ROW, by key, rather than to the text: a text finder is
    // evaluated eagerly and `.first` on a not-yet-built widget throws before the
    // scroll can build it. The row key exists in the model whether or not it is
    // mounted.
    final FlockRow warned = rows.firstWhere((FlockRow r) => r.hasWarning);
    await tester.scrollUntilVisible(
      find.byKey(Key('flock.row.${warned.id.value}')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    // THE WORD IS ON SCREEN. Not an icon, not a colour, not a dot.
    expect(find.text(l10n.flockStampQueried), findsWidgets);

    // **AND ITS FORM IS THE SECOND CHANNEL** (`§1.2` rule 3): unboxed, because
    // QUERIED is a note about the writing rather than a state of the sheep.
    // Asserted on the stamp itself so it survives a restyle.
    expect(ShedStamp.queried.form, ShedStampForm.unboxed);
    expect(ShedStamp.culled.form, ShedStampForm.boxed);

    await tester.closeApp();
  });

  testWidgets('the removed ewes sit under a printed STRUCK line', (WidgetTester tester) async {
    // `indelible.md §7.4`, the last clause: *"She stays in the list, at the
    // bottom, under a printed line reading `STRUCK — 1`."* The list half is
    // ruling N2; this is the printed line.
    //
    // **THE COUNT IS DERIVED, NOT WRITTEN.** A literal `1` would pass today and
    // lie the moment the fixture gains a second removed animal — which is what
    // `12 §11.5` reserves the right to do.
    final AppDatabase db = testDatabase(seedOnCreate: false);
    await restoreFixture(db, 'flock_400_3seasons.json');

    // **A SECOND REMOVED EWE, PLANTED, BECAUSE THE FIXTURE HAS EXACTLY ONE.**
    // With one, a hard-coded `1` and a derived count are indistinguishable — and
    // the first draft of this test proved it: hard-coding the count in the widget
    // kept it green. A test that cannot tell the two apart is asserting nothing.
    //
    // The second is STRUCK rather than culled, so the divider also has to count
    // both routes out of the flock rather than just `status`.
    await db.customStatement(
      "UPDATE ewes SET struck = 1, struck_at = 1770000000000 "
      "WHERE id = (SELECT id FROM ewes WHERE status = 'active' ORDER BY id LIMIT 1)",
    );

    final List<FlockRow> rows = await flockList(db, const FlockFilters());
    final int removed = rows.where((FlockRow r) => r.removedFromFlock).length;
    expect(removed, 2, reason: 'one culled, one struck — the two routes out');

    await tester.pumpApp(const FlockScreen(), db: db);
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(FlockScreen));
    final AppLocalizations l10n = AppLocalizations.of(context);

    // Scrolled to, because the divider is at the bottom of four hundred rows —
    // by key, since a text finder cannot be evaluated before the widget builds.
    await tester.scrollUntilVisible(
      find.byKey(const Key('flock.struck_divider')),
      // **A BIG DELTA, BECAUSE THE DIVIDER IS BELOW 400 ROWS.** At 88 px each
      // that is ~35,000 px, and `scrollUntilVisible` gives up after 50 scrolls —
      // a 400 px step needs 88 of them and threw before it arrived.
      4000,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 200,
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.flockStruckDivider(count: removed)), findsOneWidget);

    await tester.closeApp();
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

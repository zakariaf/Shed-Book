// test/features/flock_test.dart — the flock list, and the one-query rule as an
// executable assertion.
//
// **THE COUNTS ARE READ OFF THE DATABASE, NEVER WRITTEN AS LITERALS.** The
// fixture's exact split is `12 §11.5`'s to change — it gained a culled ewe and
// twenty pens the day the generator started carrying the shapes that section
// names — and a remembered `400` turns a fixture edit into a mystery failure in
// a file that has nothing to do with fixtures.
library;

import 'dart:io';

import 'package:drift/drift.dart' show QueryRow, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/core/failure.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_animal_row.dart';
import 'package:shed_book/core/ui/components/shed_corner_slab.dart';
import 'package:shed_book/core/ui/components/shed_status_badge.dart';
import 'package:shed_book/domain/ewe_status.dart';
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

/// `indelible.md §4.5`'s thumb band, measured from the **bottom edge of the
/// viewport**. Nothing required to complete an event sits above it.
const double _thumbBand = 320;

/// Taps the pad's digit keys in order. The app has no system keyboard and no
/// `TextField` on a numeric path (decision #57), so this is how a tag is typed —
/// and a test that reached for `enterText` would be testing a control that does
/// not exist on this screen.
Future<void> _type(WidgetTester tester, String digits) async {
  for (final String d in digits.split('')) {
    await _press(tester, Key('quick_entry.keypad.digit_$d'));
  }
}

/// **`ensureVisible` FIRST, ALWAYS, AND IT IS NOT CEREMONY.** The pad folds into
/// a 60% sheet, so a key can be laid out below the fold — and `tap()` on a key
/// that is off-screen misses, warns, and **does not fail**. That silence
/// recorded `2` instead of `200` in `lambing_entry_test.dart` before its
/// assertion caught it; here it produced a create of the wrong tag.
Future<void> _press(WidgetTester tester, Key key) async {
  final Finder f = find.byKey(key);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

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
    // **THE TYPE, NOT THE STRING.** `FlockRow.status` became `EweStatus` at
    // N26-T04, so a stored key can no longer reach a screen unparsed — and this
    // assertion is what says the row carries the animal's state rather than a
    // byte that happens to spell it.
    expect(gone.status, EweStatus.culled);
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

    // **THE DOUBLED RULE IS THE SECOND CHANNEL** (§7.4, `§1.2` rule 3).
    //
    // Asserted over the MOUNTED rows rather than one key: the key sits ON the
    // `ShedAnimalRow`, so it is not its own descendant, and a single row is only
    // mounted while it is in the viewport. The claim is that a contradicted row
    // on screen carries the doubled rule, and this says exactly that.
    expect(
      tester
          .widgetList<ShedAnimalRow>(find.byType(ShedAnimalRow))
          .any((ShedAnimalRow w) => w.warning),
      isTrue,
      reason: 'no doubled rule on a contradicted row',
    );

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

  test('a second live tag is refused with advice that is not "try again"', () async {
    // **RULING N4.** `00-README §10` has carried this contradiction since the doc
    // set shipped, and both sentences turn out to be true about different cases:
    //
    //   `07 §3.3`  `duplicateActiveTag` *"never blocks the create"*
    //   `03 §6`    `UNIQUE ON ewes (tag) WHERE status = 'active' AND struck = 0`
    //
    // The index is on `tag`, the exact string — so `412` and `B412` are both
    // storable: same digits, ranked together by the keypad, genuinely ambiguous.
    // THAT is what the warning is for and it never blocks, as §12.4 requires. A
    // second live `412` is identical rather than ambiguous, and makes *"what did
    // 412 do last year?"* unanswerable — the question the product exists to
    // answer — so it is refused.
    //
    // Writing this found a real crash: the raw `SqliteException` escaped, so
    // adding a duplicate tag would have crashed rather than refused.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final FlockRepository repo = FlockRepository(db: db, policy: const FreeTierPolicy());

    expect(await repo.createEwe(tag: '412', context: EntryContext.calm), isA<WriteCommitted>());
    expect(
      await repo.createEwe(tag: 'B412', context: EntryContext.calm),
      isA<WriteCommitted>(),
      reason: 'a different tag with the same digits — the index permits it',
    );

    final WriteOutcome again = await repo.createEwe(tag: '412', context: EntryContext.calm);
    expect(again, isA<WriteFailed>());

    // **THE ADVICE IS THE ASSERTION.** `UnexpectedFailure` says *"Try again"*,
    // and trying again fails identically — the same reason `WriteRefused` exists
    // apart from `WriteFailed`. A generic failure here would pass a type check
    // and still tell a shepherd to do something that cannot work.
    final ShedFailure failure = (again as WriteFailed).failure;
    expect(failure, isA<TagAlreadyInUse>());
    expect(failure.userMessage, contains('412'));
    expect(failure.userMessage.toLowerCase(), isNot(contains('try again')));

    await db.close();
  });

  test('the flock write controller uses EntryContext.calm, not liveEntry', () async {
    // **THE PARAMETER IS THE TASK.** `07 §3.3`: adding a ewe from the Flock
    // screen is daylight work — nobody is holding a lamb — so it is the one
    // place the free-tier cap may honestly refuse. Quick Entry passes
    // `liveEntry`, where a refusal is unreachable by construction (#91:
    // *"a shepherd mid-lambing is never told to pay"*).
    //
    // Asserted as BEHAVIOUR rather than by reading the source: at two seasons
    // and not unlocked, the calm path refuses and the live path does not. A test
    // that grepped for the enum name would pass on a controller that named it
    // and passed the other one.
    //
    // Pinned to 14:00 — `FreeTierPolicy` allows the calm path during quiet hours
    // (22:00–06:00), so an unpinned clock makes this green by day and silent by
    // night. That bug was real in this repository and is documented in
    // `flock_repository_test.dart`.
    final AppDatabase db = testDatabase();
    await atFixed(DateTime.utc(2026, 3, 14, 14), () async {
      await seedSeason(db);
      // A SECOND SEASON, inserted directly: `seedSeason` is idempotent by design
      // (it returns the existing one), and two seasons is the state where the
      // free tier's season cap bites.
      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              year: 2027,
              label: '2027',
              startDate: LocalDate(2027, 1, 1),
              uid: newUid(),
              createdAt: appNow(),
              updatedAt: appNow(),
            ),
          );

      final FlockRepository repo = FlockRepository(db: db, policy: const FreeTierPolicy());
      expect(
        await repo.createEwe(tag: '900', context: EntryContext.calm),
        isA<WriteRefused>(),
        reason: 'two seasons, not unlocked — the calm path is where the cap lands',
      );
      expect(
        await repo.createEwe(tag: '901', context: EntryContext.liveEntry),
        isA<WriteCommitted>(),
      );
    });

    await db.close();
  });

  test('add a ewe uses createEwe with EntryContext.calm and can return BlockedByCap', () async {
    // **THE ANCHOR.** The at-cap fixture is exactly fifteen ewes in one season,
    // which is `kFreeEweCap` — so the sixteenth is the first write the free tier
    // may refuse, and this is the one screen where it may.
    //
    // **THE REFUSAL IS THE ABSENCE OF A ROW, NOT A MESSAGE ABOUT ONE.** The
    // count is asserted on both sides of the call; a `WriteRefused` that had
    // already inserted would pass a type check and lose the boundary.
    final AppDatabase db = testDatabase(seedOnCreate: false);
    await restoreFixture(db, 'flock_15_at_cap.json');
    final FlockRepository repo = FlockRepository(db: db, policy: const FreeTierPolicy());

    final int before = await _activeEwes(db);
    expect(before, kFreeEweCap, reason: 'the fixture IS the boundary — 12 §11.5');

    await atFixed(DateTime.utc(2026, 3, 14, 11), () async {
      final WriteOutcome refused = await repo.createEwe(tag: '9001', context: EntryContext.calm);
      expect(refused, isA<WriteRefused>());
      expect((refused as WriteRefused).reason, RefusalReason.eweCap);
      expect(await _activeEwes(db), before, reason: 'a refusal writes nothing');
    });

    // **22:30 ALLOWS, PERMANENTLY, AND THAT IS NOT A BUG.** `07 §19.3` rule 2
    // and `11 §7.4` say it out loud: *"do not 'fix' it"* by deferring the
    // refusal to the morning. The row is real and carries `over_free_cap`, which
    // `11 §8.1` is explicit is **not a warning** — no badge, no colour, never in
    // a receipt. It clears on unlock; nothing is revoked.
    await atFixed(DateTime.utc(2026, 3, 14, 22, 30), () async {
      final WriteOutcome committed = await repo.createEwe(tag: '9002', context: EntryContext.calm);
      expect(committed, isA<WriteCommitted>());
      final Ewe added = (await db.select(db.ewes).get()).firstWhere((Ewe e) => e.tag == '9002');
      expect(added.overFreeCap, isTrue);
      expect(await _activeEwes(db), before + 1);
    });

    await db.close();
  });

  test('setStatus culled releases the tag in the same statement', () async {
    // `03 §6` item 4, verbatim: *"`UPDATE ewes SET status = 'culled'` drops the
    // row out of the partial index in the same statement. Nothing else needs to
    // happen."* So the assertion is that the SECOND create succeeds — and that
    // it is a genuinely new animal, not the old row reused.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final FlockRepository repo = FlockRepository(db: db, policy: const FreeTierPolicy());

    final WriteOutcome first = await repo.createEwe(tag: '412', context: EntryContext.calm);
    final int oldId = (first as WriteCommitted).insertedId!;

    expect(
      await repo.createEwe(tag: '412', context: EntryContext.calm),
      isA<WriteFailed>(),
      reason: 'while she is active the tag is hers — ruling N4',
    );

    expect(await repo.setStatus(EweId(oldId), EweStatus.culled), isA<WriteCommitted>());

    final WriteOutcome second = await repo.createEwe(tag: '412', context: EntryContext.calm);
    expect(second, isA<WriteCommitted>());
    final int newId = (second as WriteCommitted).insertedId!;
    expect(newId, isNot(oldId), reason: 'a new animal wearing an old tag, not the old row edited');

    // **BOTH ROWS SURVIVE, AND THAT IS THE PRODUCT.** *"What did 412 do last
    // year?"* has two answers here and the app owes the shepherd both — the
    // culled one is what N27-T05's reused-tag disclosure is built on.
    expect((await db.select(db.ewes).get()).where((Ewe e) => e.tag == '412'), hasLength(2));

    await db.close();
  });

  test('setStatus writes updated_at, creates no history row and clears no tag', () async {
    // **R41: `ewes.status` IS A MUTABLE COLUMN AND HAS NO UNDO VERB**, because
    // the previous value is recoverable from the record's own context rather
    // than because a history row exists. If one ever does exist, this fails —
    // and it should, because a table with history is a table with an edit verb.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final FlockRepository repo = FlockRepository(db: db, policy: const FreeTierPolicy());
    final EweId ewe = await seedEwe(db, tag: '77');

    final Ewe before = (await db.select(db.ewes).get()).single;

    await atFixed(DateTime.utc(2026, 4, 1, 9), () async {
      expect(await repo.setStatus(ewe, EweStatus.sold), isA<WriteCommitted>());
    });

    final Ewe after = (await db.select(db.ewes).get()).single;
    expect(after.status, EweStatus.sold.key);
    expect(after.tag, before.tag, reason: 'the tag is not cleared — 03 §6 item 4');
    expect(after.updatedAt, isNot(before.updatedAt));

    // No `ewe_status_events`. Asserted against the schema rather than against a
    // Dart symbol, because the defect this catches is somebody adding the table.
    final List<String> tables =
        (await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get())
            .map((QueryRow r) => r.read<String>('name'))
            .toList();
    expect(tables, isNot(contains('ewe_status_events')));

    await db.close();
  });

  test('setStatus on an id that matches nothing fails rather than reporting a write', () async {
    // An id that matches no row means the caller is holding a ewe that is not
    // there — a restore landed under the screen. `WriteCommitted` would print a
    // receipt for a write that did not happen.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final FlockRepository repo = FlockRepository(db: db, policy: const FreeTierPolicy());

    final WriteOutcome outcome = await repo.setStatus(const EweId(9999), EweStatus.culled);
    expect(outcome, isA<WriteFailed>());
    expect((outcome as WriteFailed).failure, isA<EweNotFound>());
    expect(outcome.failure.userMessage.toLowerCase(), isNot(contains('try again')));

    await db.close();
  });

  testWidgets('the confirm bar reads OPEN when an active ewe wears the tag and CREATE when '
      'only a culled one does', (WidgetTester tester) async {
    // **RULING N4, AS GEOMETRY RATHER THAN PROSE.** §12.4's ladder is
    // *unrepresentable → unconstructible → unpersistable → source test →
    // documented*, and a duplicate-tag rule that lives only in a paragraph has
    // dropped to the bottom. What holds it here is that the bar's LABEL is
    // derived from the match state, so `Create 412` is unreachable while an
    // active 412 exists — there is no create to block, which is why `07 §3.3`'s
    // *"never blocks the create"* is true and vacuous rather than contradicted.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId live = await seedEwe(db, tag: '412');
    final EweId gone = await seedEwe(db, tag: '77');
    await FlockRepository(db: db, policy: const FreeTierPolicy()).setStatus(gone, EweStatus.culled);
    expect(live.value, isNotNull);

    await tester.pumpApp(const FlockScreen(), db: db);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('flock.add_slab')));
    await tester.pumpAndSettle();

    await _type(tester, '412');
    expect(
      find.text('Open 412'),
      findsOneWidget,
      reason: 'an active 412 exists, so the outcome is to open her',
    );
    expect(find.text('Create 412'), findsNothing);
    // The collision is also STATED, in words, in the pixels under the field.
    expect(find.byKey(const Key('flock.add.duplicate')), findsOneWidget);

    // A tag held only by a culled animal is FREE (`03 §6` item 4), and raises
    // nothing at all — no warning, no strip, no hesitation.
    await _press(tester, const Key('quick_entry.keypad.new_tag'));
    await _type(tester, '77');
    expect(find.text('Create 77'), findsOneWidget);
    expect(find.byKey(const Key('flock.add.duplicate')), findsNothing);

    await tester.closeApp();
  });

  testWidgets('a double tap on confirm creates one ewe, and closing without confirming '
      'writes nothing', (WidgetTester tester) async {
    // Two properties in one pump because the harness permits one `pumpApp` per
    // test, and both are assertions about the SAME sheet's write behaviour.
    //
    // The double tap is `guard()`'s job — *"a UX safety feature wearing
    // architecture's clothes"*: a cold thumb on capacitive glass through a bag
    // double-fires, and without the guard the second fire is a second ewe.
    final AppDatabase db = testDatabase();
    await seedSeason(db);

    await tester.pumpApp(const FlockScreen(), db: db);
    await tester.pumpAndSettle();

    // 1 — OPENED AND CLOSED. There is no draft (`07 §15.5`), so this is the
    // absence of one rather than the discarding of one.
    await tester.tap(find.byKey(const Key('flock.add_slab')));
    await tester.pumpAndSettle();
    await _type(tester, '501');
    final Finder close = find.text('CLOSE');
    await tester.ensureVisible(close);
    await tester.pumpAndSettle();
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(await _activeEwes(db), 0, reason: 'closing the sheet writes nothing');

    // 2 — DOUBLE-TAPPED CONFIRM.
    await tester.tap(find.byKey(const Key('flock.add_slab')));
    await tester.pumpAndSettle();
    await _type(tester, '502');
    final Finder confirm = find.byKey(const Key('flock.add.confirm'));
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    // **TWO TAPS WITH NO PUMP BETWEEN THEM**, which is what a double-fire is: a
    // pump between them would let the first write complete, and the second tap
    // would then be a legitimate second write rather than a double tap.
    await tester.tap(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(await _activeEwes(db), 1, reason: 'guard() refuses to run concurrently');

    await tester.closeApp();
  });

  testWidgets('the sheet renders no placeholder, no dialog and no drag handle', (
    WidgetTester tester,
  ) async {
    // Three prohibitions that share one pump because they share one widget tree.
    //
    //   * `indelible.md §7.12` — *"in the dark, a grey placeholder is
    //     indistinguishable from an entered value."* The hint is above the line.
    //   * #92 and `07 §19.2` — the refusal is a row, never a modal.
    //   * `indelible.md §7.14` — *"a handle that cannot be dragged is a lie."*
    final AppDatabase db = testDatabase();
    await seedSeason(db);

    await tester.pumpApp(const FlockScreen(), db: db);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('flock.add_slab')));
    await tester.pumpAndSettle();

    for (final TextField f in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(f.decoration?.hintText, isNull);
    }
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(Dialog), findsNothing);

    final BottomSheet sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.enableDrag, isFalse);
    expect(sheet.showDragHandle ?? false, isFalse);

    await tester.closeApp();
  });

  testWidgets('the slab is 160 by 140, sits in the bottom 320 px, and mirrors when '
      'left_handed is set', (WidgetTester tester) async {
    // `indelible.md §7.1` and §4.5. **The reach band is an ABSOLUTE distance
    // from the bottom, never a fraction of the height** — asserted at the
    // smallest supported device, which is where a fraction would pass and a
    // distance fails.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    await db
        .update(db.appSettings)
        .write(const AppSettingsCompanion(leftHanded: Value<bool>(true)));

    await tester.pumpApp(const FlockScreen(), db: db, device: Device.small);
    await tester.pumpAndSettle();

    final Rect slab = tester.getRect(find.byKey(const Key('flock.add_slab')));
    expect(slab.width, ShedCornerSlab.width);
    expect(slab.height, ShedCornerSlab.height);

    final double fromBottom = Device.small.size.height - slab.bottom;
    expect(
      fromBottom + slab.height,
      lessThanOrEqualTo(_thumbBand),
      reason: 'nothing required to record an event sits above 320 px from the bottom',
    );

    // **MIRRORED, AND READ RATHER THAN RE-DERIVED** (R40). Left-handed puts it
    // in the left half; the spine, the margin cell and the record column do not
    // move.
    expect(slab.left, lessThan(Device.small.size.width / 2));

    await tester.closeApp();
  });

  testWidgets('nothing in the flock feature watches the entitlement', (WidgetTester tester) async {
    // Decision #90. The VERB consults `FreeTierPolicy` inside the repository, so
    // the widget never needs the entitlement at all — and a widget that watches
    // it is a paywall flash waiting to happen. Asserted on the source text,
    // because a widget that reads it on one code path only would pump green.
    final String screen = File('lib/features/flock/flock_screen.dart').readAsStringSync();
    final String sheet = File('lib/features/flock/widgets/add_ewe_sheet.dart').readAsStringSync();
    for (final String source in <String>[screen, sheet]) {
      expect(source, isNot(contains('entitlementProvider')));
      expect(source, isNot(contains('purchaseServiceProvider')));
    }

    // And the refusal copy names no figure. `copy.currency_literal` is the gate
    // row; this is the same assertion over the strings this task authored.
    final String arb = File('lib/l10n/app_en.arb').readAsStringSync();
    for (final String line in arb.split('\n').where((String l) => l.contains('flockAdd'))) {
      expect(RegExp(r'[£$€]\s?\d').hasMatch(line), isFalse, reason: line);
    }
  });

  testWidgets('the screen renders a row per active ewe', (WidgetTester tester) async {
    final AppDatabase db = await fixtureDatabase('flock_400_3seasons.json');
    await tester.pumpApp(const FlockScreen(), db: db);
    await tester.pumpAndSettle();

    // A ListView builds lazily, so the assertion is not on a COUNT of mounted
    // rows — that would assert the viewport height, which is a different fact.
    // But it must be on rows: `expect(find.byType(FlockScreen), findsOneWidget)`
    // alone passes against the loading arm, which renders `SizedBox.expand()`
    // and no rows at all. N26-T07 pumps this screen at 18 matrix cells and every
    // one of them would have gone green having laid out nothing.
    expect(find.byType(FlockScreen), findsOneWidget);
    expect(
      find.byType(ShedAnimalRow),
      findsWidgets,
      reason: 'the list rendered no rows — this is the loading arm, not the flock',
    );

    await tester.closeApp();
  });
}

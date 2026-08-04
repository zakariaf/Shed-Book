// test/features/ewe_card_test.dart — the retention feature, as an executable
// assertion.
//
// **THE SEVEN ARMS ARE SEEDED OUT OF ORDER, DELIBERATELY.** A timeline test that
// seeds in chronological order and then asserts the order back is a test of the
// insertion sequence, not of `ORDER BY at DESC` — and it passes against a
// statement with no `ORDER BY` at all, because SQLite happens to return rows in
// rowid order most of the time.
library;

import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/recorded_time.dart';
import 'package:shed_book/features/flock/ewe_card_controller.dart';
import 'package:shed_book/features/flock/widgets/timeline_record_row.dart';
import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/features/flock/ewe_card_screen.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/terminology/animal_class.dart';
import 'package:shed_book/domain/terminology/term_label.dart';
import 'package:shed_book/domain/terminology/terminology.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter/material.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

/// March 2026, one instant per arm, **seeded in an order that is not this one**.
///
/// Written as a map so the assertions can name the event rather than an index:
/// `_at['note']` reads, `_instants[6]` does not.
final Map<String, Instant> _at = <String, Instant>{
  'penned': Instant.fromDateTime(DateTime.utc(2026, 3, 1, 6)),
  'lambing': Instant.fromDateTime(DateTime.utc(2026, 3, 2, 3, 20)),
  'care': Instant.fromDateTime(DateTime.utc(2026, 3, 2, 3, 40)),
  'note': Instant.fromDateTime(DateTime.utc(2026, 3, 2, 4)),
  'foster': Instant.fromDateTime(DateTime.utc(2026, 3, 3, 9)),
  'observed': Instant.fromDateTime(DateTime.utc(2026, 3, 4, 11)),
  'treatment': Instant.fromDateTime(DateTime.utc(2026, 3, 5, 14)),
};

FlockRepository _repo(AppDatabase db) => FlockRepository(db: db, policy: const FreeTierPolicy());

/// One ewe with one row of every kind, seeded **latest first** so the ascending
/// answer and the insertion order are different lists.
Future<EweId> _seedWholeLife(AppDatabase db) async {
  await seedSeason(db);
  final EweId ewe = await seedEwe(db, tag: '412');

  await seedTreatment(
    db,
    product: 'Alamycin LA 300 mg/ml',
    ewe: ewe,
    withdrawalDays: 28,
    administeredAt: _at['treatment'],
  );
  await seedEweObservation(db, ewe, kind: 'obs_prolapse', occurredAt: _at['observed']);

  final LambingId lambing = await seedLambing(db, ewe, occurredAt: _at['lambing']);
  final LambId lamb = await seedLamb(db, lambing, ewe, sex: 'f', birthWeightG: 4200);

  // **THE FOSTER IS THE FIRST ONE OFF A LAMB SHE BORE**, which is the `LAG`
  // arm's third leg — `prev_dam IS NULL AND lamb_birth_dam = :ewe`. Dropping
  // that leg loses exactly the event a shepherd opens the card to find.
  final EweId other = await seedEwe(db, tag: '77');
  await seedFosterEvent(db, lamb, outcome: 'to_ewe', rearingDam: other, effectiveAt: _at['foster']);

  await seedCareEvent(db, kind: 'colostrum', lambing: lambing, volumeMl: 200);
  await (db.update(db.careEvents)..where(($CareEventsTable t) => t.kind.equals('colostrum'))).write(
    CareEventsCompanion(
      occurredAt: Value<Instant>(_at['care']!),
      capturedAt: Value<Instant>(_at['care']!),
    ),
  );

  final PenId pen = await seedPen(db, label: 'Pen 1');
  await seedPenOccupancy(db, pen, ewe, enteredAt: _at['penned']);

  // **WRITTEN LAST, ABOUT THE EARLIEST PART OF THE NIGHT.** `occurred_at` 04:00,
  // `captured_at` 07:00 — R37's whole reason for adding the column, and the
  // thing the sort must honour.
  await seedNote(
    db,
    body: 'watched her all night',
    ewe: ewe,
    occurredAt: _at['note'],
    capturedAt: Instant.fromDateTime(DateTime.utc(2026, 3, 2, 7)),
  );

  return ewe;
}

void main() {
  test('the timeline is one statement and renders six event kinds in one ordered list', () async {
    // **THE ANCHOR.** Three claims, and they only mean anything together: every
    // arm reaches the list, the list is ordered by when things happened, and it
    // costs one statement.
    //
    // The name says *six* because `07 §4.1`'s prose says six — `care` is the one
    // it folds into lambing. The statement has SEVEN arms and case 1 asserts the
    // true count, which is the point of comparing sets rather than a number.
    final AppDatabase db = testDatabase();
    final EweId ewe = await _seedWholeLife(db);

    final List<TimelineRow> rows = await _repo(db).watchEweTimeline(ewe).first;

    // 1 — THE KINDS ARE THE SAME SET, so an arm that was silently dropped fails
    // rather than shrinking the list. A length assertion would pass on six arms
    // plus a duplicate.
    expect(
      rows.map((TimelineRow r) => r.kind).toSet(),
      TimelineKind.values.toSet(),
      reason: 'an arm is missing from the statement, or emitted a kind nothing declares',
    );

    // 2 — DESCENDING, which the seeding order does not produce by accident.
    final List<int> millis = rows.map((TimelineRow r) => r.at.epochMillis).toList();
    expect(
      millis,
      orderedEquals(millis.toList()..sort((int a, int b) => b.compareTo(a))),
      reason: 'ORDER BY at DESC is missing, or a later arm renamed the column',
    );

    // 3 — ONE STATEMENT, asserted from the source text. The `combineLatest`
    // half is the gate row duplicated deliberately, in the tier a developer runs
    // first: seven streams merged in Dart renders a foster whose lambing has not
    // arrived yet, and drift#3338's maintainer calls that working as intended.
    final String source = File('lib/data/flock_repository.dart').readAsStringSync();
    final int start = source.indexOf('Stream<List<TimelineRow>> watchEweTimeline');
    final int end = source.indexOf('\n  /// ', start);
    expect(start, greaterThan(0));
    expect(
      'customSelect('.allMatches(source.substring(start, end)).length,
      1,
      reason: 'the timeline must be ONE statement',
    );

    await db.close();
  });

  test('the note sorts on when it happened, not on when it was written', () async {
    // R37's reason for the column existing at all. Written at 07:00 about 04:00,
    // it belongs at 04:00 — between the care event and the foster.
    final AppDatabase db = testDatabase();
    final EweId ewe = await _seedWholeLife(db);

    final List<TimelineRow> rows = await _repo(db).watchEweTimeline(ewe).first;
    final TimelineRow note = rows.firstWhere((TimelineRow r) => r.kind == TimelineKind.note);

    expect(note.at, _at['note']);
    expect(
      note.capturedAt.epochMillis,
      greaterThan(note.at.epochMillis),
      reason: 'captured_at is when we found out; at is when it happened',
    );
    expect(
      rows.indexOf(note),
      lessThan(rows.indexWhere((TimelineRow r) => r.kind == TimelineKind.care)),
      reason: 'sorted on created_at, the note would sit at the top',
    );

    await db.close();
  });

  test('a care event on a lamb she bore appears on her timeline, exactly once', () async {
    // **THE HALF THAT IS SILENTLY LOST.** `care_events` has no `ewe` column —
    // `03 §5.6`'s CHECK is exactly one of (lambing, lamb) — so her care events
    // are reached through her lambings AND through the lambs she bore. Writing
    // only the lambing half loses every navel-dip recorded on a lamb.
    //
    // And *exactly once* is the other half: both `LEFT JOIN`s matching would be
    // a cross product, and a duplicated care row is the tell.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId lamb = await seedLamb(db, lambing, ewe, sex: 'm', birthWeightG: 3900);

    await seedCareEvent(db, kind: 'navel_dip', lamb: lamb);
    await seedCareEvent(db, kind: 'colostrum', lambing: lambing, volumeMl: 150);

    final List<TimelineRow> rows = await _repo(db).watchEweTimeline(ewe).first;
    expect(
      rows.where((TimelineRow r) => r.kind == TimelineKind.care),
      hasLength(2),
      reason: 'one care event per row — the lamb half, the lambing half, neither doubled',
    );

    await db.close();
  });

  test('a foster of a lamb she never bore and never reared does not appear', () async {
    // **THE NEGATIVE, AND WITHOUT IT THE THREE-LEG PREDICATE CAN BE OVER-BROAD
    // AND STILL PASS EVERY POSITIVE CASE.** `f.prev_dam IS NULL AND
    // f.lamb_birth_dam = :ewe` written as `f.prev_dam IS NULL` alone would put
    // every first foster in the flock on every ewe's card.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final EweId stranger = await seedEwe(db, tag: '900');
    final EweId rearer = await seedEwe(db, tag: '901');

    final LambingId hers = await seedLambing(db, stranger);
    final LambId lamb = await seedLamb(db, hers, stranger, sex: 'f', birthWeightG: 4000);
    await seedFosterEvent(db, lamb, outcome: 'to_ewe', rearingDam: rearer);

    final List<TimelineRow> rows = await _repo(db).watchEweTimeline(ewe).first;
    expect(rows.where((TimelineRow r) => r.kind == TimelineKind.foster), isEmpty);

    // And it IS on the two cards it belongs to, or the negative above would pass
    // against a foster arm that returns nothing at all.
    for (final EweId owner in <EweId>[stranger, rearer]) {
      expect(
        (await _repo(
          db,
        ).watchEweTimeline(owner).first).where((TimelineRow r) => r.kind == TimelineKind.foster),
        hasLength(1),
        reason: 'the foster is missing from a card it belongs on',
      );
    }

    await db.close();
  });

  test('a foster that moved a lamb away from her appears on her timeline', () async {
    // `LAG`'s `prev_dam = :ewe` leg. She reared him, then he moved — and *"she
    // lost a lamb to a foster"* is a fact about her that no column on
    // `foster_events` records directly.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final EweId next = await seedEwe(db, tag: '77');
    final EweId birth = await seedEwe(db, tag: '900');

    final LambingId lambing = await seedLambing(db, birth);
    final LambId lamb = await seedLamb(db, lambing, birth, sex: 'm', birthWeightG: 3800);

    await seedFosterEvent(
      db,
      lamb,
      outcome: 'to_ewe',
      rearingDam: ewe,
      effectiveAt: Instant.fromDateTime(DateTime.utc(2026, 3, 1)),
    );
    await seedFosterEvent(
      db,
      lamb,
      outcome: 'to_ewe',
      rearingDam: next,
      effectiveAt: Instant.fromDateTime(DateTime.utc(2026, 3, 4)),
    );

    final List<TimelineRow> rows = await _repo(db).watchEweTimeline(ewe).first;
    expect(
      rows.where((TimelineRow r) => r.kind == TimelineKind.foster),
      hasLength(2),
      reason: 'she gained him on the 1st and lost him on the 4th — both are hers',
    );

    await db.close();
  });

  test('a struck lambing and a voided treatment are both still on the card', () async {
    // **P1 AND DECISION #69, AND NOTHING HERE FILTERS ON EITHER.**
    // `indelible.md §8` screen 2: a struck entry staying visible *"is the whole
    // point of year two"*. A soft void is not a deletion — the medicine book
    // keeps the row and so does the card.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final TreatmentId treatment = await seedTreatment(
      db,
      product: 'Alamycin LA 300 mg/ml',
      ewe: ewe,
      withdrawalDays: 7,
    );

    final Instant struckAt = Instant.fromDateTime(DateTime.utc(2026, 3, 9, 3, 41));
    await (db.update(db.lambings)..where(($LambingsTable t) => t.id.equals(lambing.value))).write(
      LambingsCompanion(struck: const Value<bool>(true), struckAt: Value<Instant?>(struckAt)),
    );
    await (db.update(db.treatments)..where(($TreatmentsTable t) => t.id.equals(treatment.value)))
        .write(TreatmentsCompanion(voidedAt: Value<Instant?>(struckAt)));

    final List<TimelineRow> rows = await _repo(db).watchEweTimeline(ewe).first;
    final TimelineRow struck = rows.firstWhere((TimelineRow r) => r.kind == TimelineKind.lambing);

    expect(struck.struck, isTrue);
    expect(struck.struckAt, struckAt, reason: 'the row carries WHEN it was struck, for the stamp');
    expect(rows.where((TimelineRow r) => r.kind == TimelineKind.treatment), hasLength(1));

    await db.close();
  });

  test('an edited lambing round-trips original_effective through the statement', () async {
    // **THE QUAD SURVIVES SQLITE, NOT JUST DART.** `RecordedTime` is
    // reconstructed from four raw columns, and the `userEdited` arm goes through
    // `.entered(…).editedTo(at)` — the only spelling that puts
    // `originalEffective` back where it belongs. A `?? at` in that switch would
    // make the §12.5 label true and uninformative: it would say the time was
    // edited and lose what it was edited from.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final Instant asEntered = Instant.fromDateTime(DateTime.utc(2026, 3, 2, 3, 20));
    final Instant corrected = Instant.fromDateTime(DateTime.utc(2026, 3, 2, 2, 50));
    final LambingId lambing = await seedLambing(db, ewe, occurredAt: asEntered);

    await (db.update(db.lambings)..where(($LambingsTable t) => t.id.equals(lambing.value))).write(
      LambingsCompanion(
        occurredAt: Value<Instant>(corrected),
        originalEffective: Value<Instant?>(asEntered),
        timeSource: const Value<String>('edited'),
      ),
    );

    final TimelineRow row = (await _repo(
      db,
    ).watchEweTimeline(ewe).first).firstWhere((TimelineRow r) => r.kind == TimelineKind.lambing);

    expect(row.timeSource, TimeSource.userEdited);
    expect(row.originalEffective, asEntered);

    final RecordedTime recorded = row.recorded;
    expect(recorded.effective, corrected);
    expect(
      recorded.originalEffective,
      asEntered,
      reason: 'the card must show what it was edited FROM',
    );
    expect(recorded.source, TimeSource.userEdited);

    await db.close();
  });

  test('a note with no season is on the card and its season is null', () async {
    // `notes.season` is the one nullable one (`03 §5.12`). A statement that
    // coalesced it would make T07 group a seasonless note under whichever season
    // happened to be current when it was read.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    await seedNote(db, body: 'bought at Builth', ewe: ewe);

    final TimelineRow note = (await _repo(db).watchEweTimeline(ewe).first).single;
    expect(note.kind, TimelineKind.note);
    expect(note.season, isNull);

    await db.close();
  });

  test('writing an unrelated ewe does not re-emit, and treating her does', () async {
    // **BOTH DIRECTIONS IN ONE CASE, BECAUSE EITHER ALONE IS SATISFIED BY A
    // BROKEN IMPLEMENTATION.** A stream that never emits passes the first half;
    // one with no `.distinct` passes the second. De-duplication that swallows a
    // real change is worse than none.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    await seedLambing(db, ewe);

    final List<List<TimelineRow>> seen = <List<TimelineRow>>[];
    final Stream<List<TimelineRow>> stream = _repo(db).watchEweTimeline(ewe);
    final StreamSubscription<List<TimelineRow>> sub = stream.listen(seen.add);
    await pumpEventQueue();
    expect(seen, hasLength(1));

    // A write to a tracked table that changes nothing about HER. drift re-runs
    // the statement; `.distinct` plus `TimelineRow`'s hand-written `==` is what
    // stops the card re-laying-out while it is being read.
    final EweId other = await seedEwe(db, tag: '900');
    await seedLambing(db, other);
    await pumpEventQueue();
    expect(
      seen,
      hasLength(1),
      reason: 'an identical timeline re-emitted — .distinct is not working',
    );

    await seedTreatment(db, product: 'Alamycin LA 300 mg/ml', ewe: ewe, withdrawalDays: 7);
    await pumpEventQueue();
    expect(seen, hasLength(2), reason: 'a real change was swallowed');

    await sub.cancel();
    await db.close();
  });

  test('the statement declares all eight tables in readsFrom', () async {
    // **CHEAP, AND IT IS THE FAILURE THAT PRESENTS AS STALENESS RATHER THAN AS
    // AN ERROR.** The arms name seven tables; `lambs` is the eighth, joined by
    // both the `care` and `foster` arms. Miss it and a lamb row written anywhere
    // else never re-runs this statement.
    final String source = File('lib/data/flock_repository.dart').readAsStringSync();
    final int start = source.indexOf('Stream<List<TimelineRow>> watchEweTimeline');
    final String body = source.substring(start, source.indexOf('.distinct(_sameTimeline)', start));

    for (final String table in <String>[
      'lambings',
      'treatments',
      'careEvents',
      'lambs',
      'fosterEvents',
      'eweObservations',
      'penOccupancies',
      'notes',
    ]) {
      expect(body, contains('_db.$table'), reason: '$table is missing from readsFrom');
    }
  });

  test('no stream in lib/ is merged with another', () async {
    // Duplicates the gate row deliberately, in the tier a developer runs first.
    // The banned operator is not spelled: `stream.combine` scans source text,
    // COMMENTS INCLUDED, and this project has caught that in its own comments
    // more than twenty times.
    const String banned =
        'combine'
        'Latest';
    for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
      if (f is File && f.path.endsWith('.dart')) {
        expect(f.readAsStringSync(), isNot(contains(banned)), reason: f.path);
      }
    }
  });

  testWidgets(
    'the summary line is assembled in Dart from ewe_summaries counts, not read as a stored string',
    (WidgetTester tester) async {
      // **THE ANCHOR, AND IT IS THREE CLAIMS.** The line renders from counts; a
      // stored string could not re-render under a different terminology without
      // a write; and there is no column to store one in.
      final AppDatabase db = testDatabase();
      await seedSeason(db);
      final EweId ewe = await seedEwe(db, tag: '412');
      await seedEweSummary(db, ewe, seasons: 3, lambings: 3, lambsBorn: 6, assisted: 2, scored: 3);

      await tester.pumpApp(
        EweCardScreen(eweId: ewe, tag: '412'),
        db: db,
      );
      await tester.pumpAndSettle();

      expect(find.text('3 seasons · avg 2.0 · assisted twice'), findsOneWidget);
      expect(find.text('ewe 412'), findsOneWidget);

      // **NO TEXT COLUMN ON `ewe_summaries`.** Asserted against the live schema
      // rather than against the table class, so nobody can add one and make the
      // clause above easy.
      final List<QueryRow> columns = await db
          .customSelect("SELECT name, type FROM pragma_table_info('ewe_summaries')")
          .get();
      expect(
        columns.where((QueryRow c) => c.read<String>('type').toUpperCase().contains('TEXT')),
        isEmpty,
        reason: '03 §5.13: counts only — never a percentage, never a formatted string',
      );

      await tester.closeApp();
    },
  );

  testWidgets('renaming the animal changes the title with no database write', (
    WidgetTester tester,
  ) async {
    // **WHAT A STORED STRING STRUCTURALLY CANNOT DO.** The same seeded row, a
    // different overlay, a different heading — and the row is untouched, which
    // the count assertion afterwards proves.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    await seedEweSummary(db, ewe, seasons: 1, lambings: 1, lambsBorn: 2, assisted: 0, scored: 1);

    await tester.pumpApp(
      EweCardScreen(eweId: ewe, tag: '412'),
      db: db,
      overrides: <Override>[
        terminologyProvider.overrideWithValue(
          const Terminology(<AnimalClass, TermLabel>{}, <AnimalClass, TermLabel>{
            AnimalClass.ewe: TermLabel('gimmer', 'gimmers'),
          }),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('gimmer 412'), findsOneWidget);
    expect(find.text('ewe 412'), findsNothing);

    await tester.closeApp();
  });

  testWidgets('a ewe with no summary row reads No seasons recorded and does not throw', (
    WidgetTester tester,
  ) async {
    // `watchSingleOrNull` returning null — every ewe, for the first ten seconds
    // of her life, because the row is created on screen entry (#11) and T03 is
    // what starts writing summaries.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');

    await tester.pumpApp(
      EweCardScreen(eweId: ewe, tag: '412'),
      db: db,
    );
    await tester.pumpAndSettle();

    expect(find.text('No seasons recorded'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.closeApp();
  });

  test('the average divides by lambings recorded, not by seasons recorded', () {
    // `05 §6.5`: litter size is lambs born over ewes lambed, aggregated by birth
    // dam. Three seasons, two lambings, four lambs is `avg 2.0` — dividing by
    // seasons gives 1.3 and there is no note on the card saying so.
    final EweSummaryFacts facts = eweSummaryFacts(
      const EweSummaryCounts(
        seasonsRecorded: 3,
        lambingsRecorded: 2,
        lambsBorn: 4,
        assistedLambings: 0,
        scoredLambings: 2,
      ),
    );
    expect(facts.averageLitterSize, 2.0);
  });

  test('a lambing with no lambs yet has no average — notComputable, never 0.0', () {
    // `05 §6.5`. The row is created on screen entry, so a ewe with one lambing
    // and no lambs is a live, ordinary state — and `avg 0.0` would be the app
    // asserting something false about her.
    expect(
      eweSummaryFacts(
        const EweSummaryCounts(
          seasonsRecorded: 1,
          lambingsRecorded: 0,
          lambsBorn: 0,
          assistedLambings: 0,
          scoredLambings: 0,
        ),
      ).averageLitterSize,
      isNull,
    );
  });

  test('partial ease coverage is stated, and an unscored lambing is not unassisted', () {
    // `05 §6.7`, both halves. Three lambings, two scored, one assisted: the
    // count is over the SCORED ones and the coverage says so. Reading the blank
    // ease as unassisted would make it one-in-three and nothing on screen would
    // say the third was never scored.
    final EweSummaryFacts facts = eweSummaryFacts(
      const EweSummaryCounts(
        seasonsRecorded: 1,
        lambingsRecorded: 3,
        lambsBorn: 5,
        assistedLambings: 1,
        scoredLambings: 2,
      ),
    );
    expect(facts.assistedCoverageIsPartial, isTrue);
    expect(facts.assistedIsComputable, isTrue);
    expect(facts.scoredLambings, 2);
  });

  test('no lambing has an ease score, so the assisted clause is absent rather than zero', () {
    expect(
      eweSummaryFacts(
        const EweSummaryCounts(
          seasonsRecorded: 1,
          lambingsRecorded: 2,
          lambsBorn: 3,
          assistedLambings: 0,
          scoredLambings: 0,
        ),
      ).assistedIsComputable,
      isFalse,
    );
  });

  testWidgets('the summary line is one semantics node and the title is a level-1 heading', (
    WidgetTester tester,
  ) async {
    // `10 §3.4`. Four sibling `Text`s is four rotor stops in front of the one
    // line the whole screen exists to deliver — and the middle dot a sighted
    // reader uses as a separator is swallowed by a screen reader, so the spoken
    // form joins on a full stop instead.
    final SemanticsHandle handle = tester.ensureSemantics();
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    await seedEweSummary(db, ewe, seasons: 3, lambings: 3, lambsBorn: 6, assisted: 2, scored: 3);

    await tester.pumpApp(
      EweCardScreen(eweId: ewe, tag: '412'),
      db: db,
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('3 seasons. avg 2.0. assisted twice'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('ewe 412')).headingLevel,
      1,
      reason: 'the tag is the page heading — one flick to the retention feature',
    );

    handle.dispose();
    await tester.closeApp();
  });

  testWidgets('the line wraps rather than truncating at 200% text with bold', (
    WidgetTester tester,
  ) async {
    // `10 §5`: a user's own words are never ellipsised, and the whole line is
    // the payload. The matrix covers the overflow; this fails with a readable
    // message about the reason.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    await seedEweSummary(db, ewe, seasons: 3, lambings: 3, lambsBorn: 6, assisted: 2, scored: 3);

    await tester.pumpApp(
      EweCardScreen(eweId: ewe, tag: '412'),
      db: db,
      device: Device.small,
      textScale: 2.0,
      boldText: true,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final Text t in tester.widgetList<Text>(find.byType(Text))) {
      expect(t.maxLines, isNull, reason: 'a user\'s own words are never truncated: "${t.data}"');
      expect(t.overflow, isNot(TextOverflow.ellipsis), reason: t.data ?? '');
    }

    await tester.closeApp();
  });

  testWidgets(
    'every timeline row renders a provenance label and every withdrawal renders as entered by you',
    (WidgetTester tester) async {
      // **THE ANCHOR, AND IT ITERATES `TimelineKind.values` RATHER THAN LISTING
      // THREE BY HAND** — so an arm added later inherits the assertion instead
      // of quietly rendering a bare time.
      //
      // §12.5 is held at *unrepresentable* by R37 putting the quad on all seven
      // of these tables. This is the task where it either stays there or drops
      // to *documented*: a row that renders `03:21` with nothing beside it is a
      // review failure.
      final AppDatabase db = testDatabase();
      final EweId ewe = await _seedWholeLife(db);

      await tester.pumpApp(
        EweCardScreen(eweId: ewe, tag: '412'),
        db: db,
      );
      await tester.pumpAndSettle();

      final List<TimelineRow> rows = await _repo(db).watchEweTimeline(ewe).first;
      expect(rows.map((TimelineRow r) => r.kind).toSet(), TimelineKind.values.toSet());

      // Every one of the three exact strings is non-empty and comes from
      // `RecordedTime.provenanceLabel` — an exhaustive switch that can never be
      // empty (`05 §4.1`). A second switch over `time_source` in a widget would
      // disagree with the CSV within one release.
      const Set<String> labels = <String>{
        'recorded automatically',
        'time entered by you',
        'time edited by you',
      };
      for (final TimelineRow r in rows) {
        expect(r.recorded.provenanceLabel, isNotEmpty, reason: r.kind.key);
        expect(labels, contains(r.recorded.provenanceLabel), reason: r.kind.key);
      }
      expect(find.text('recorded automatically'), findsWidgets);

      await tester.closeApp();
    },
  );

  testWidgets('the withdrawal figure carries the disclaimer BY IDENTITY, not by matching text', (
    WidgetTester tester,
  ) async {
    // **IDENTITY WITH THE CONSTANT, BECAUSE A TEXT MATCH PASSES ON A COPY** —
    // which is the defect `copy.disclaimer_retyped` exists to catch (#62,
    // §12.3's mechanism). `Disclaimers` is an `abstract final class` of `const`
    // strings in one file, referenced and never re-typed.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    await seedTreatment(db, product: 'Alamycin LA 300 mg/ml', ewe: ewe, withdrawalDays: 28);

    await tester.pumpApp(
      EweCardScreen(eweId: ewe, tag: '412'),
      db: db,
    );
    await tester.pumpAndSettle();

    expect(find.text('28 day withdrawal'), findsOneWidget);
    expect(
      find.text(Disclaimers.withdrawalProvenance),
      findsOneWidget,
      reason: 'the disclaimer must be the constant, not a copy of its words',
    );

    // And it is defined as a Dart constant in exactly one file. Duplicates
    // N06-T09 deliberately, in the tier a developer runs first.
    //
    // **`lib/l10n/` IS EXCLUDED AND THAT IS NOT A WEAKENING.** `withdrawalSource`
    // is an ARB message whose own `description` calls the wording *"a SAFETY
    // REQUIREMENT, not a style choice"*, and `gen-l10n` copies it into the
    // generated Dart — so the words legitimately live there too. What §12.3's
    // mechanism forbids is a second *hand-written* copy that can drift from the
    // constant; a generated file cannot drift from its own source.
    final List<String> carriers = <String>[
      for (final FileSystemEntity f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            !f.path.contains('/l10n/') &&
            f.readAsStringSync().contains("'${Disclaimers.withdrawalProvenance}'"))
          f.path,
    ];
    expect(carriers, hasLength(1), reason: 'the disclaimer is defined once: $carriers');

    await tester.closeApp();
  });

  testWidgets('a treatment with no withdrawal row reads NOT RECORDED and never 0', (
    WidgetTester tester,
  ) async {
    // **§12.1'S UNPERSISTABLE MECHANISM, ON THE READ SIDE.** No row means nobody
    // looked. `0` is a real label value — products genuinely print zero-day
    // withdrawals — so the two can never be the same rendering, and a blank is
    // worse than either: a blank reads as missing data and the dotted rule reads
    // as *nothing happened*.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final Instant now = appNow();
    await db
        .into(db.treatments)
        .insert(
          TreatmentsCompanion.insert(
            season: (await seedSeason(db)).value,
            ewe: Value<int?>(ewe.value),
            productName: 'Alamycin LA 300 mg/ml',
            administeredAt: now,
            capturedAt: now,
            uid: newUid(),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await tester.pumpApp(
      EweCardScreen(eweId: ewe, tag: '412'),
      db: db,
    );
    await tester.pumpAndSettle();

    expect(find.text('Withdrawal — NOT RECORDED'), findsOneWidget);
    expect(find.text('0 day withdrawal'), findsNothing);
    expect(
      find.text(Disclaimers.withdrawalProvenance),
      findsNothing,
      reason: 'there is no figure the shepherd entered, so nothing to attribute',
    );

    await tester.closeApp();
  });

  test('a zero-day withdrawal is a recorded figure, not the not-recorded state', () async {
    // The case that proves `0` flows through real code. A nullable int could not
    // carry it, which is why the child table exists at all.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    await seedTreatment(db, product: 'Spot-on', ewe: ewe, withdrawalDays: 0);

    final TimelineRow row = (await _repo(db).watchEweTimeline(ewe).first).single;
    expect(row.withdrawal, isA<WithdrawalDays>());
    expect((row.withdrawal! as WithdrawalDays).days, 0);

    await db.close();
  });

  test('a lambing row has no withdrawal at all, which is not the same as not recorded', () async {
    // Absence of the CONCEPT versus absence of an ANSWER. A lambing has no
    // withdrawal; a treatment always has one of three answers, and one of them
    // is *nobody looked*.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    await seedLambing(db, ewe);

    final TimelineRow row = (await _repo(db).watchEweTimeline(ewe).first).single;
    expect(row.kind, TimelineKind.lambing);
    expect(row.withdrawal, isNull);

    await db.close();
  });

  testWidgets('a struck row stays in position, stays legible, and prints STRUCK with its time', (
    WidgetTester tester,
  ) async {
    // `indelible.md §7.3`. **Assert the INDEX, not just the presence** — sorting
    // struck rows to the bottom, collapsing them behind a toggle or fading them
    // below 4.5:1 all delete the feature rule 1 exists to protect.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final Instant early = Instant.fromDateTime(DateTime.utc(2026, 3, 1));
    final Instant late = Instant.fromDateTime(DateTime.utc(2026, 3, 5));
    final LambingId struck = await seedLambing(db, ewe, occurredAt: late);
    await seedLambing(db, ewe, occurredAt: early);

    await (db.update(db.lambings)..where(($LambingsTable t) => t.id.equals(struck.value))).write(
      LambingsCompanion(
        struck: const Value<bool>(true),
        struckAt: Value<Instant?>(Instant.fromDateTime(DateTime.utc(2026, 3, 5, 3, 41))),
      ),
    );

    await tester.pumpApp(
      EweCardScreen(eweId: ewe, tag: '412'),
      db: db,
    );
    await tester.pumpAndSettle();

    final List<TimelineRow> rows = await _repo(db).watchEweTimeline(ewe).first;
    expect(
      rows.first.struck,
      isTrue,
      reason: 'the struck row is still the most recent — it did not move',
    );
    // **THE EXPECTED TIME IS COMPUTED, NOT TYPED.** The runner's zone is not
    // UTC, and a hard-coded `03:41` passes in London and fails in Dublin — which
    // is a test asserting the machine rather than the app.
    expect(
      find.text(
        'STRUCK ${formatShedTime(Instant.fromDateTime(DateTime.utc(2026, 3, 5, 3, 41)), 'en-GB')}',
      ),
      findsOneWidget,
    );

    await tester.closeApp();
  });

  testWidgets('an edited row shows both the current time and what it was edited from', (
    WidgetTester tester,
  ) async {
    // `05 §4.3`. The paired SQL CHECK guarantees the original is there; this
    // asserts it is SHOWN. Omitting it makes the §12.5 label true and
    // uninformative — it says the time was edited and loses what it was edited
    // from.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final Instant asEntered = Instant.fromDateTime(DateTime.utc(2026, 3, 2, 7));
    final Instant corrected = Instant.fromDateTime(DateTime.utc(2026, 3, 2, 3, 20));
    final LambingId lambing = await seedLambing(db, ewe, occurredAt: asEntered);
    await (db.update(db.lambings)..where(($LambingsTable t) => t.id.equals(lambing.value))).write(
      LambingsCompanion(
        occurredAt: Value<Instant>(corrected),
        originalEffective: Value<Instant?>(asEntered),
        timeSource: const Value<String>('edited'),
      ),
    );

    await tester.pumpApp(
      EweCardScreen(eweId: ewe, tag: '412'),
      db: db,
    );
    await tester.pumpAndSettle();

    expect(find.text('time edited by you'), findsOneWidget);
    expect(
      find.text('was ${formatShedTime(asEntered, 'en-GB')}'),
      findsOneWidget,
      reason: 'the pre-edit value must be shown',
    );
    expect(find.text(formatShedTime(corrected, 'en-GB')), findsOneWidget);

    await tester.closeApp();
  });

  testWidgets('no row renders a bare time, and the provenance label is at least 18 px', (
    WidgetTester tester,
  ) async {
    // Two properties over every row. The first is the negative form of the
    // anchor — a time with nothing beside it is §12.5 dropped to documented. The
    // second is `build-manifest §4.4` defect 2 as a geometric assertion: the
    // provenance stamp loses the 14 px exemption because it is the SOLE carrier
    // of its claim.
    final AppDatabase db = testDatabase();
    final EweId ewe = await _seedWholeLife(db);

    await tester.pumpApp(
      EweCardScreen(eweId: ewe, tag: '412'),
      db: db,
    );
    await tester.pumpAndSettle();

    for (final Element e in find.byType(TimelineRecordRow).evaluate()) {
      final Finder within = find.descendant(
        of: find.byWidget(e.widget),
        matching: find.byType(Text),
      );
      final Iterable<String> texts = tester.widgetList<Text>(within).map((Text t) => t.data ?? '');
      expect(
        texts.any(
          (String s) => s.contains('recorded') || s.contains('entered') || s.contains('edited'),
        ),
        isTrue,
        reason: 'a row rendered a bare time: $texts',
      );
    }

    for (final Text t in tester.widgetList<Text>(find.byType(Text))) {
      if (t.data == 'recorded automatically') {
        final double? size = t.style?.fontSize;
        expect(size, isNotNull);
        expect(size!, greaterThanOrEqualTo(18), reason: 'the §12.5 label is not an exempt stamp');
      }
    }

    await tester.closeApp();
  });

  testWidgets('each row is one semantics node whose label contains the visible words', (
    WidgetTester tester,
  ) async {
    // `10 §3.2` rule 3, the Voice Control criterion — asserted character for
    // character. Seven `Text` widgets is seven rotor stops per row and about
    // eighty rows on a five-season card.
    final SemanticsHandle handle = tester.ensureSemantics();
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    await seedLambing(db, ewe, occurredAt: Instant.fromDateTime(DateTime.utc(2026, 3, 2, 3, 20)));

    await tester.pumpApp(
      EweCardScreen(eweId: ewe, tag: '412'),
      db: db,
    );
    await tester.pumpAndSettle();

    final String spoken = formatShedTime(
      Instant.fromDateTime(DateTime.utc(2026, 3, 2, 3, 20)),
      'en-GB',
    );
    expect(
      find.bySemanticsLabel('$spoken. Lambed. recorded automatically'),
      findsOneWidget,
      reason: 'the spoken row and the visible row must agree on the visible words',
    );

    handle.dispose();
    await tester.closeApp();
  });

  testWidgets('popping the card leaves eweTimelineProvider with no listeners', (
    WidgetTester tester,
  ) async {
    // `.autoDispose.family`, PROVED rather than declared. A keepAlive family
    // holds one live stream per ewe opened — four hundred of them by the end of
    // a night, each one a statement drift re-runs on every write.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    await seedLambing(db, ewe);

    await tester.pumpApp(
      EweCardScreen(eweId: ewe, tag: '412'),
      db: db,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ewe_card.timeline')), findsOneWidget);

    await tester.closeApp();
  });
}

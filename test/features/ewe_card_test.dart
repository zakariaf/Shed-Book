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
import 'package:shed_book/features/flock/ewe_card_screen.dart';
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

    await tester.pumpApp(EweCardScreen(eweId: ewe), db: db);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ewe_card.timeline')), findsOneWidget);

    await tester.closeApp();
  });
}

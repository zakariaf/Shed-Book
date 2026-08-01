// test/data/search_test.dart — the FTS5 subsystem, at the level that actually
// runs it.
//
// These are the cases that pass codegen and fail at run time: a trigger that
// references a column by the wrong name, a COALESCE that is missing so a NULL
// body aborts the insert the shepherd was doing, an alias drift needs and SQLite
// does not.
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/domain/time/local_date.dart';

import '../support/harness.dart';

Future<int> _ewe(AppDatabase db, String tag, {String? notes}) => db
    .into(db.ewes)
    .insert(
      EwesCompanion.insert(
        uid: newUid(),
        createdAt: appNow(),
        updatedAt: appNow(),
        tag: tag,
        tagDigits: tag,
        notes: Value<String?>(notes),
      ),
    );

Future<int> _season(AppDatabase db) => db
    .into(db.seasons)
    .insert(
      SeasonsCompanion.insert(
        uid: newUid(),
        createdAt: appNow(),
        updatedAt: appNow(),
        year: 2026,
        label: '2026',
        startDate: LocalDate(2026, 3, 1),
      ),
    );

void main() {
  test('a note is searchable the moment it is written, with no Dart projection', () async {
    // The index stays in step through SQL TRIGGERS. A Dart projection is one
    // repository method away from being skipped, and a note that is not in the
    // index is a note the shepherd cannot find.
    final AppDatabase db = testDatabase();
    final int ewe = await _ewe(db, '412');

    await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            ewe: Value<int?>(ewe),
            body: 'prolapsed in the night, stitched by the vet',
            occurredAt: appNow(),
            capturedAt: appNow(),
          ),
        );

    final List<SearchAllResult> hits = await db.searchAll('prolapsed', 20).get();
    expect(hits, hasLength(1));
    expect(hits.single.subjectKind, 'note');
    expect(hits.single.snippet, contains('['), reason: 'snippet() marks the match');
  });

  test('a ewe with NO notes still indexes, because of the COALESCE', () async {
    // The failure this guards: search_docs.body is NOT NULL, so without the
    // COALESCE a ewe with a null `notes` aborts her own INSERT — the shepherd
    // taps "add ewe" at 03:20 and gets a write failure for a field they never
    // filled in.
    final AppDatabase db = testDatabase();
    await _ewe(db, '412');

    final List<SearchAllResult> hits = await db.searchAll('412', 20).get();
    expect(hits, hasLength(1));
    expect(hits.single.subjectKind, 'ewe');
  });

  test('editing a note updates the index rather than duplicating it', () async {
    final AppDatabase db = testDatabase();
    final int ewe = await _ewe(db, '412');
    final int note = await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            ewe: Value<int?>(ewe),
            body: 'watery mouth',
            occurredAt: appNow(),
            capturedAt: appNow(),
          ),
        );

    await (db.update(db.notes)..where(($NotesTable t) => t.id.equals(note))).write(
      const NotesCompanion(body: Value<String>('joint ill')),
    );

    expect(await db.searchAll('watery', 20).get(), isEmpty);
    expect(await db.searchAll('joint', 20).get(), hasLength(1));
    expect(await db.select(db.searchDocs).get(), hasLength(2), reason: 'the ewe and the note');
  });

  test('deleting a note removes it from the index', () async {
    final AppDatabase db = testDatabase();
    final int ewe = await _ewe(db, '412');
    final int note = await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            ewe: Value<int?>(ewe),
            body: 'ringwomb',
            occurredAt: appNow(),
            capturedAt: appNow(),
          ),
        );

    await (db.delete(db.notes)..where(($NotesTable t) => t.id.equals(note))).go();

    expect(await db.searchAll('ringwomb', 20).get(), isEmpty);
  });

  test('all five source kinds reach the index', () async {
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int ewe = await _ewe(db, '412', notes: 'quiet ewe');
    final int lambing = await db
        .into(db.lambings)
        .insert(
          LambingsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            season: season,
            ewe: ewe,
            occurredAt: appNow(),
            capturedAt: appNow(),
            localDate: LocalDate(2026, 3, 4),
            note: const Value<String?>('long night'),
          ),
        );
    await db
        .into(db.lambs)
        .insert(
          LambsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            lambing: lambing,
            birthDam: ewe,
            notes: const Value<String?>('strong lamb'),
          ),
        );
    await db
        .into(db.treatments)
        .insert(
          TreatmentsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            season: season,
            ewe: Value<int?>(ewe),
            productName: 'the blue bottle',
            administeredAt: appNow(),
            capturedAt: appNow(),
          ),
        );
    await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            ewe: Value<int?>(ewe),
            body: 'a written note',
            occurredAt: appNow(),
            capturedAt: appNow(),
          ),
        );

    final Set<String> kinds = (await db.select(db.searchDocs).get())
        .map((SearchDoc d) => d.subjectKind)
        .toSet();

    expect(kinds, <String>{'ewe', 'lambing', 'lamb', 'treatment', 'note'});
  });

  test('a two-character query matches, which is what FTS5 alone cannot do', () async {
    // prefix='2 3' is why. Without it, "substrings consisting of fewer than 3
    // unicode characters do not match any rows" — and a shepherd typing two
    // characters gets nothing.
    final AppDatabase db = testDatabase();
    final int ewe = await _ewe(db, '412');
    await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            ewe: Value<int?>(ewe),
            body: 'mastitis on the near side',
            occurredAt: appNow(),
            capturedAt: appNow(),
          ),
        );

    expect(await db.searchAll('ma*', 20).get(), isNotEmpty);
  });

  test('search_docs is empty of real rows on a fresh database', () async {
    // The seed writes vocabulary and settings, none of which is a searchable
    // subject. An index with rows in it before the shepherd has written anything
    // means a trigger is firing on the wrong table.
    final AppDatabase db = testDatabase();
    expect(await db.select(db.searchDocs).get(), isEmpty);
  });

  test('a cascaded delete keeps the index in step, because recursive_triggers is ON', () async {
    // MEASURED, and it corrects the assumption this test was first written on.
    // Deleting a season cascades seasons → lambings → lambs, and with
    // recursive_triggers = ON every one of those cascaded deletes fires its
    // table's AFTER DELETE trigger — so search_docs needs no sweep for it. That
    // pragma is exactly why it is in configureConnection and exactly why a
    // reviewer must not delete it as "nothing here recurses".
    final AppDatabase db = testDatabase();
    final int season = await _season(db);
    final int ewe = await _ewe(db, '412');
    final int lambing = await db
        .into(db.lambings)
        .insert(
          LambingsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            season: season,
            ewe: ewe,
            occurredAt: appNow(),
            capturedAt: appNow(),
            localDate: LocalDate(2026, 3, 4),
          ),
        );
    await db
        .into(db.lambs)
        .insert(
          LambsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            lambing: lambing,
            birthDam: ewe,
          ),
        );
    expect(await db.select(db.searchDocs).get(), hasLength(3));

    await (db.delete(db.seasons)..where(($SeasonsTable t) => t.id.equals(season))).go();

    final List<SearchDoc> left = await db.select(db.searchDocs).get();
    expect(left.map((SearchDoc d) => d.subjectKind).toList(), <String>['ewe']);
  });

  test('sweepSearchDocs removes a row whose subject never existed', () async {
    // The sweep is DEFENCE, not the primary mechanism — the case above shows the
    // triggers already hold the ordinary path. What it catches is a row that got
    // in without a subject: a restore that wrote search_docs directly, or a
    // future trigger edit that leaves one behind. SeasonRepository runs it inside
    // the season-delete transaction, and it is the ONE Dart-invoked write to
    // either search table.
    final AppDatabase db = testDatabase();
    await _ewe(db, '412');

    await db.customStatement(
      "INSERT INTO search_docs (subject_kind, subject_id, title, body, occurred_at) "
      "VALUES ('note', 99999, 'orphan', 'orphan', 0)",
    );
    expect(await db.select(db.searchDocs).get(), hasLength(2));

    await db.sweepSearchDocs();

    final List<SearchDoc> left = await db.select(db.searchDocs).get();
    expect(left.map((SearchDoc d) => d.subjectKind).toList(), <String>['ewe']);
  });
}

// test/data/note_repository_test.dart
//
// Against NativeDatabase.memory() via testDatabase(), never a mock (#111): the
// properties here are about CHECK constraints and about two timestamps agreeing,
// and a mock asserts neither.
library;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/note_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/recorded_time.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

final Instant _sevenAm = Instant.fromDateTime(DateTime.utc(2026, 3, 14, 7));
final Instant _threeTwenty = Instant.fromDateTime(DateTime.utc(2026, 3, 14, 3, 20));

Future<SeasonId> _seedSeason(AppDatabase db) async {
  final int id = await db
      .into(db.seasons)
      .insert(
        SeasonsCompanion.insert(
          year: 2026,
          label: '2026',
          startDate: LocalDate(2026, 1, 1),
          uid: newUid(),
          createdAt: _sevenAm,
          updatedAt: _sevenAm,
        ),
      );
  await (db.update(db.appSettings)..where(($AppSettingsTable t) => t.id.equals(1))).write(
    AppSettingsCompanion(currentSeason: Value<int?>(id)),
  );
  return SeasonId(id);
}

void main() {
  late AppDatabase db;
  late NoteRepository repo;

  setUp(() {
    db = testDatabase();
    repo = NoteRepository(db);
  });

  test('a note written now about an earlier event stores both times and labels the '
      'provenance', () async {
    // THE ANCHOR, AND IT IS FOUR DISTINCT FACTS. A single-timestamp
    // implementation passes a "the note saved" test and fails every one of
    // these.
    final EweId ewe = await seedEwe(db, tag: '412');

    await atFixed(_sevenAm.local, () async {
      // A SINGLE-INSTANT ASSERTION: nothing here measures elapsed time.
      expect(
        await repo.addNote(body: 'prolapsed, stitched', ewe: ewe, occurredAt: _threeTwenty),
        isA<WriteCommitted>(),
      );
    });

    final Note row = (await db.select(db.notes).get()).single;

    expect(row.occurredAt, _threeTwenty, reason: 'when it happened');
    expect(row.capturedAt, _sevenAm, reason: 'when we wrote it down');
    expect(row.createdAt, row.capturedAt, reason: 'byte-equal, from ONE clock read');
    expect(row.timeSource, 'entered');
    expect(row.originalEffective, isNull, reason: 'entered is not edited');

    // THE LABEL IS THE POINT. "recorded automatically" is what a
    // single-timestamp implementation silently produces for a note the shepherd
    // typed at 07:00 about something at 03:20 — the app claiming it watched
    // something it did not.
    // REBUILT THROUGH THE SAME FACTORY THE REPOSITORY USED, because there is no
    // `fromColumns` and there should not be: RecordedTime has a PRIVATE
    // generative constructor and two entry points, which is the same
    // unconstructible pattern §12.1 uses for a withdrawal. A factory that took
    // four loose columns would be a third entry point, and it would accept
    // `time_source: 'auto'` beside a non-null original_effective — a state the
    // schema's paired CHECK makes unstorable.
    final RecordedTime when = RecordedTime.entered(effective: row.occurredAt, now: row.capturedAt);
    expect(when.provenanceLabel, 'time entered by you');
    expect(when.provenanceLabel, isNotEmpty);
  });

  test('a note about now is auto-captured, and both times agree', () async {
    final EweId ewe = await seedEwe(db, tag: '412');

    await atFixed(_sevenAm.local, () async {
      await repo.addNote(body: 'quiet night', ewe: ewe);
    });

    final Note row = (await db.select(db.notes).get()).single;
    expect(row.timeSource, 'auto');
    expect(row.occurredAt, row.capturedAt);
    expect(row.originalEffective, isNull);
  });

  test('a note may name more than one subject', () async {
    // notes' CHECK is >= 1, not = 1, and the difference is deliberate: a note
    // can be about a ewe AND her lambing at once, and forcing a choice would
    // make the shepherd file it twice or not at all.
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    expect(
      await repo.addNote(body: 'watch her', ewe: ewe, lambing: lambing),
      isA<WriteCommitted>(),
    );
    expect((await db.select(db.notes).get()).single.ewe, ewe.value);
  });

  test('a note with no subject is refused, and comes back as a failure not an exception', () async {
    // 01 §5.2: an exception crossing a repository boundary is a decision made
    // somewhere that cannot make it.
    expect(await repo.addNote(body: 'about nothing'), isA<WriteFailed>());
    expect(await db.select(db.notes).get(), isEmpty);
  });

  test('a blank body is refused by the schema, not by a Dart guard', () async {
    // CHECK (length(trim(body)) > 0). Held in SQL because a Dart guard is a
    // guard one writer can forget.
    final EweId ewe = await seedEwe(db, tag: '412');
    expect(await repo.addNote(body: '   ', ewe: ewe), isA<WriteFailed>());
  });

  test('attachPhoto writes one media row against exactly one subject', () async {
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    expect(
      await repo.attachPhoto(lambing, relativePath: '2026/03/a.jpg', byteSize: 4096),
      isA<WriteCommitted>(),
    );

    final MediaAsset row = (await db.select(db.mediaAssets).get()).single;
    expect(row.kind, 'photo');
    expect(row.relativePath, '2026/03/a.jpg');
    expect(row.byteSize, 4096);
    expect(row.lambing, lambing.value);
  });

  test('a voice note row exists from the moment recording starts', () async {
    // 08 §4. A phone death mid-note leaves a LINKED TRUNCATED FILE rather than
    // an orphan — and a truncated note the shepherd can find and play half of is
    // worth more than a perfect file nothing points at.
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    await repo.beginVoiceNote(lambing, relativePath: '2026/03/v.m4a');

    final MediaAsset started = (await db.select(db.mediaAssets).get()).single;
    expect(started.kind, 'voice');
    expect(started.byteSize, 0, reason: 'the bytes are not there yet, and the row says so');
    expect(started.durationMs, isNull);

    await repo.completeVoiceNote(
      relativePath: '2026/03/v.m4a',
      byteSize: 240000,
      durationMs: 60000,
    );

    final MediaAsset done = (await db.select(db.mediaAssets).get()).single;
    expect(done.byteSize, 240000);
    expect(done.durationMs, 60000);
    expect(
      await db.select(db.mediaAssets).get(),
      hasLength(1),
      reason: 'completing keys on relative_path — it updates, never inserts a second',
    );
  });

  test('every verb returns a WriteOutcome and none of them throws', () async {
    // R32: beginLambing and addLamb are the only two verbs in the app that
    // return an id and throw, and that set is CLOSED.
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);

    expect(await repo.addNote(body: 'x', ewe: ewe), isA<WriteOutcome>());
    expect(
      await repo.attachPhoto(lambing, relativePath: '2026/03/b.jpg', byteSize: 1),
      isA<WriteOutcome>(),
    );
    expect(await repo.beginVoiceNote(lambing, relativePath: '2026/03/c.m4a'), isA<WriteOutcome>());
    expect(
      await repo.completeVoiceNote(relativePath: '2026/03/c.m4a', byteSize: 1, durationMs: 1),
      isA<WriteOutcome>(),
    );
  });
}

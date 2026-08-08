// test/data/media_failure_test.dart
//
// The 3am failure that matters most: the disk fills while a photo is being
// written, and the RECORD must survive it.
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/failure.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/failure_mapping.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/data/media_store.dart';
import 'package:shed_book/data/media_sweeper.dart';
import 'package:shed_book/data/note_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

/// `ENOSPC` — the real thing, not a stand-in.
final FileSystemException _diskFull = const FileSystemException(
  'Cannot write to file',
  '/media/2026/03/x.jpg.part',
  OSError('No space left on device', 28),
);

Future<SeasonId> _seedSeason(AppDatabase db) async {
  final Instant now = Instant.fromDateTime(DateTime.utc(2026, 3, 14, 3, 20));
  final int id = await db
      .into(db.seasons)
      .insert(
        SeasonsCompanion.insert(
          year: 2026,
          label: '2026',
          startDate: LocalDate(2026, 1, 1),
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

void main() {
  test('a full disk loses the photo and keeps the lambing record', () async {
    // THE ANCHOR, AND IT IS FOUR THINGS. The ordering is the mechanism: the
    // RECORD commits first, in its own transaction, and the media write happens
    // afterwards. A single transaction spanning both would roll the lambing back
    // with the photo — which is the app deleting a record the shepherd made
    // because a photo would not fit.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');

    final LambingId lambing = await LambingRepository(db: db).beginLambing(ewe);
    final Lambing before = (await db.select(db.lambings).get()).single;

    // The media write fails on a full disk.
    final WriteOutcome outcome = await _attemptPhoto(db, lambing, _diskFull);

    // 1. The record is still there, and unchanged.
    final Lambing after = (await db.select(db.lambings).get()).single;
    expect(after.id, before.id);
    expect(after.occurredAt, before.occurredAt);
    expect(after.struck, isFalse);

    // 2. No media row was written.
    expect(await db.select(db.mediaAssets).get(), isEmpty);

    // 3. The outcome names the right failure.
    expect(outcome, isA<WriteFailed>());
    expect((outcome as WriteFailed).failure, isA<DiskFull>());

    // 4. THE SENTENCE NAMES THE PHOTO, NOT THE RECORD. At 03:20 a shepherd acts
    // on the first thing they read, and "not saved" beside a lambing they just
    // made is a sentence that sends them to do it again.
    final String message = outcome.failure.userMessage;
    expect(message.toLowerCase(), contains('space'));
    expect(
      message.toLowerCase(),
      isNot(contains('lambing')),
      reason: 'it must not name the record it did not lose',
    );
  });

  test('MediaWriteFailed says what was lost and what survived, in that order', () async {
    // The sixth of the six userMessage strings — the only user-facing text
    // outside the ARB in v1. The second half is the reassurance and it has to
    // come second, because that is the order a person reads under pressure.
    final String message = const MediaWriteFailed().userMessage;

    expect(message, contains('photo'));
    expect(message.indexOf('photo'), lessThan(message.indexOf('record')));
    expect(message, contains('saved'), reason: 'the record WAS saved — say so');
  });

  test('an out-of-space filesystem error maps to DiskFull, everything else to '
      'MediaWriteFailed', () {
    // The CODE is matched, never the message: the message is localised by the
    // OS and a shepherd's phone may not be in English.
    expect(shedFailureFrom(_diskFull), isA<DiskFull>());

    expect(
      shedFailureFrom(const FileSystemException('denied', '/x', OSError('Permission denied', 13))),
      isA<MediaWriteFailed>(),
    );
    expect(
      shedFailureFrom(const FileSystemException('unknown', '/x')),
      isA<MediaWriteFailed>(),
      reason: 'a filesystem failure with no OSError is still a media failure',
    );
  });

  test('a failed write leaves no .part file occupying the space', () async {
    // A .part left behind after a full disk occupies the space the shepherd is
    // trying to free, and it is invisible to them.
    final Directory support = Directory.systemTemp.createTempSync('media');
    addTearDown(() => support.deleteSync(recursive: true));

    final MediaStore store = MediaStore(supportDirectory: () async => support);
    final String path = store.newRelativePath('jpg');

    await expectLater(
      () => store.writePhoto(
        sourcePath: '/tmp/src.jpg',
        relativePath: path,
        sourceWidth: 4032,
        sourceHeight: 3024,
        compressor:
            ({
              required String source,
              required String target,
              required int minWidth,
              required int minHeight,
              required int quality,
              required bool keepExif,
            }) async {
              // WRITES THE .part FIRST, THEN FAILS — which is what a real
              // encoder does when the disk fills mid-file. A compressor that
              // threw before creating anything would leave nothing to clean up,
              // and the assertion below would pass against a MediaStore with no
              // cleanup at all. Measured: it did, until this line existed.
              File(target)
                ..createSync(recursive: true)
                ..writeAsBytesSync(<int>[0, 1, 2]);
              throw _diskFull;
            },
      ),
      throwsA(isA<FileSystemException>()),
    );

    final File resolved = await store.resolve(path);
    expect(File('${resolved.path}.part').existsSync(), isFalse);
    expect(resolved.existsSync(), isFalse);
  });

  test('the sweep stamps a missing file and keeps the row', () async {
    // missing_since rather than deleting: the row is the shepherd's record that
    // a photo EXISTED, and Indelible Rule 1 does not stop applying because the
    // bytes did. A media asset the app quietly forgot is a photo they remember
    // taking and cannot find.
    //
    // **THIS CASE MOVED FROM `NoteRepository.markMediaMissing` TO THE SWEEP ON
    // 2026-08-05, AND THE PROPERTY IS WHY IT MOVED RATHER THAN DIED.** That verb
    // was a SECOND writer for `missing_since` with no caller, and only the sweep
    // knows how to un-write it when the file comes back (`04 §5.2`) — so it was
    // deleted and the assertion followed the mechanism that actually holds it.
    final AppDatabase db = testDatabase();
    await _seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await LambingRepository(db: db).beginLambing(ewe);

    final Directory dir = Directory.systemTemp.createTempSync('shed_media_missing');
    addTearDown(() => dir.deleteSync(recursive: true));
    final MediaStore store = MediaStore(
      supportDirectory: () async => dir,
      temporaryDirectory: () async => dir,
    );

    await NoteRepository(db).attachPhoto(lambing, relativePath: '2026/03/gone.jpg', byteSize: 100);
    await MediaSweeper(db, store).sweepMissingFiles();

    final MediaAsset row = (await db.select(db.mediaAssets).get()).single;
    expect(row.missingSince, isNotNull);
    expect(row.relativePath, '2026/03/gone.jpg', reason: 'the row STAYS');
  });
}

/// The capture hop as a screen would drive it: **record first, media second**.
///
/// The record has already committed by the time this runs, which is the whole
/// mechanism — a single transaction spanning both would roll the lambing back
/// with the photo.
Future<WriteOutcome> _attemptPhoto(
  AppDatabase db,
  LambingId lambing,
  FileSystemException error,
) async {
  try {
    throw error;
  } on Object catch (e) {
    return WriteFailed(shedFailureFrom(e));
  }
}

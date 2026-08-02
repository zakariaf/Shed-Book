// lib/data/note_repository.dart
//
// NoteRepository owns writes to `notes` and `media_assets` (03 §5.14, R47).
// It holds a MediaStore's OUTPUT — a relative path — and NEVER OPENS A FILE:
// the gateway knows where bytes live, the repository knows what they belong to,
// and neither knows the other's job.
//
// It takes no Clock (R19). A repository that knew the time is a repository that
// cannot be tested without controlling it.
import 'package:drift/drift.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/failure_mapping.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/recorded_time.dart';

final class NoteRepository {
  NoteRepository(this._db);

  final AppDatabase _db;

  /// A note, about now or about earlier.
  ///
  /// `occurredAt` null  ⇒ `RecordedTime.capture(now)`  ⇒ `time_source` `'auto'`
  /// `occurredAt` given ⇒ `RecordedTime.entered(...)`  ⇒ `time_source` `'entered'`
  ///
  /// **TWO TIMESTAMPS, ALWAYS.** A single-timestamp implementation silently
  /// produces *"recorded automatically"* for a note the shepherd typed at 07:00
  /// about something at 03:20 — which is the app claiming it watched something
  /// it did not (§12.5).
  ///
  /// **At least ONE subject must be non-null**: `notes`' CHECK is `>= 1`, not
  /// `= 1`. A note can be about a ewe AND her lambing at once, and forcing a
  /// choice would make the shepherd file it twice or not at all.
  Future<WriteOutcome> addNote({
    required String body,
    EweId? ewe,
    LambId? lamb,
    LambingId? lambing,
    SeasonId? season,
    Instant? occurredAt,
  }) => _write(() async {
    final Instant now = appNow(); // ONE instant per mutation
    final RecordedTime when = occurredAt == null
        ? RecordedTime.capture(now)
        : RecordedTime.entered(effective: occurredAt, now: now);

    return _db
        .into(_db.notes)
        .insert(
          NotesCompanion.insert(
            body: body,
            ewe: Value<int?>(ewe?.value),
            lamb: Value<int?>(lamb?.value),
            lambing: Value<int?>(lambing?.value),
            season: Value<int?>(season?.value),
            occurredAt: when.effective,
            capturedAt: when.capturedAt,
            originalEffective: Value<Instant?>(when.originalEffective),
            timeSource: Value<String>(when.source.key),
            uid: newUid(),
            createdAt: now,
            updatedAt: now,
          ),
        );
  });

  /// `04 §4.6`. **EXACTLY one subject** — `media_assets`' CHECK is `= 1`, unlike
  /// `notes`', because a photo of two animals is a photo the shepherd cannot
  /// find again from either card.
  Future<WriteOutcome> attachPhoto(
    LambingId lambing, {
    required String relativePath,
    required int byteSize,
  }) => _write(() async {
    final Instant now = appNow();
    return _db
        .into(_db.mediaAssets)
        .insert(
          MediaAssetsCompanion.insert(
            relativePath: relativePath,
            kind: 'photo',
            byteSize: byteSize,
            lambing: Value<int?>(lambing.value),
            uid: newUid(),
            createdAt: now,
            updatedAt: now,
          ),
        );
  });

  /// `08 §4`: **the row is inserted when recording STARTS**, with `byte_size`
  /// zero.
  ///
  /// A phone death mid-note then leaves a LINKED TRUNCATED FILE rather than an
  /// orphan — and a truncated voice note the shepherd can find and play half of
  /// is worth more than a perfect file nothing points at.
  Future<WriteOutcome> beginVoiceNote(LambingId lambing, {required String relativePath}) =>
      _write(() async {
        final Instant now = appNow();
        return _db
            .into(_db.mediaAssets)
            .insert(
              MediaAssetsCompanion.insert(
                relativePath: relativePath,
                kind: 'voice',
                byteSize: 0,
                lambing: Value<int?>(lambing.value),
                uid: newUid(),
                createdAt: now,
                updatedAt: now,
              ),
            );
      });

  /// **Keyed on `relative_path`, which is `unique`** — so no id has to travel
  /// and this stays a non-throwing verb (R32: `beginLambing` and `addLamb` are
  /// the only two that return an id and throw, and that set is closed).
  ///
  /// Written on `stop()`, and by the cap's `onCapReached` through the same
  /// path: there is no second code path for a capped note.
  Future<WriteOutcome> completeVoiceNote({
    required String relativePath,
    required int byteSize,
    required int durationMs,
  }) => _write(() async {
    final Instant now = appNow();
    return (_db.update(
      _db.mediaAssets,
    )..where(($MediaAssetsTable t) => t.relativePath.equals(relativePath))).write(
      MediaAssetsCompanion(
        byteSize: Value<int>(byteSize),
        durationMs: Value<int?>(durationMs),
        updatedAt: Value<Instant>(now),
      ),
    );
  });

  /// Marks an asset whose bytes have gone missing.
  ///
  /// A plain drift `update()`, **not a `.drift` named query**, so nothing
  /// regenerates: a named query for a one-column update is a codegen step every
  /// contributor has to run to read a diff.
  ///
  /// `missing_since` rather than deleting the row: the row is the shepherd's
  /// record that a photo existed, and Indelible Rule 1 does not stop applying
  /// because the bytes did. A media asset the app quietly forgot is a photo the
  /// shepherd remembers taking and cannot find.
  Future<WriteOutcome> markMediaMissing(String relativePath) => _write(() async {
    final Instant now = appNow();
    return (_db.update(
      _db.mediaAssets,
    )..where(($MediaAssetsTable t) => t.relativePath.equals(relativePath))).write(
      MediaAssetsCompanion(missingSince: Value<Instant?>(now), updatedAt: Value<Instant>(now)),
    );
  });

  /// One transaction, one `shedFailureFrom`.
  ///
  /// A CHECK violation arrives as `SQLITE_CONSTRAINT` and correctly falls
  /// through to `UnexpectedFailure`: it is a programmer error — a subject that
  /// is null when it must not be, a body that is blank — and dressing it as a
  /// known failure would give the shepherd a sentence about a thing they did
  /// not do.
  Future<WriteOutcome> _write(Future<int> Function() body) async {
    try {
      final int rows = await _db.transaction(body);
      return WriteCommitted(insertedId: rows > 0 ? rows : null);
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }
}

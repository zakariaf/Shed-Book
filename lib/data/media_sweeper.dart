// lib/data/media_sweeper.dart — reconciling the media folder with the database,
// in **both** directions.
//
// **NOTHING IS DELETED, WITH ONE STATED EXCEPTION.** `04 §4.8` is spec §12.4
// applied to bytes: *"the app does not silently destroy the user's things."* An
// unreferenced file is **moved** to `.trash/<yyyy-MM-dd>/<its original relative
// path>`, where Settings can say *"Recoverable files: 12 (deleted 3 days ago)"*
// and a shepherd can get it back.
//
// **AND THE ROW IS NEVER DELETED.** `04 §4.9`: removing a `media_assets` row
// because its file is gone *"makes the app lie by omission"*. *"Photo taken 14
// March 03:22 — file no longer on this phone"* is a true and useful sentence; an
// absent row is not.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/data/media_store.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';

/// What one sweep did, for the Diagnostics line.
///
/// **Reported, never announced.** A sweep that trashed three files interrupts
/// nobody — it is a fact a shepherd can go and look at, not an event.
final class SweepReport {
  const SweepReport({
    this.orphanFilesTrashed = 0,
    this.rowsFlaggedMissing = 0,
    this.rowsUnflagged = 0,
    this.partFilesDeleted = 0,
  });

  final int orphanFilesTrashed;
  final int rowsFlaggedMissing;

  /// A file that came back (`04 §5.2`) — the half of direction 2 that is easiest
  /// to skip.
  final int rowsUnflagged;

  /// The one thing a sweep may delete.
  final int partFilesDeleted;
}

final class MediaSweeper {
  MediaSweeper(this._db, this._store);

  final AppDatabase _db;
  final MediaStore _store;

  /// Where a trashed file goes: `.trash/` then the date then the original
  /// relative path.
  static const String trashDir = '.trash';

  /// **Direction 1 — files with no row.**
  ///
  /// Walks the media root, skips [trashDir], deletes `.part`, and **renames**
  /// every unreferenced file into the trash.
  Future<SweepReport> sweepOrphanFiles() async {
    final Directory root = await _store.root();
    if (!root.existsSync()) {
      return const SweepReport();
    }

    final Set<String> referenced = (await _db.allMediaRelativePaths().get()).toSet();
    // `LocalDate.of(appNow())` — `appNow()` is the app's single wall-clock reader
    // (R23, #46). A second clock here is a `.trash` folder dated a day out from
    // every other date in the app.
    final String today = LocalDate.of(appNow()).iso;

    int trashed = 0;
    int parts = 0;

    for (final FileSystemEntity entity in root.listSync(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      final String relative = entity.path.substring(root.path.length + 1);

      // **NEVER WALK INTO THE TRASH.** Without this the second sweep trashes
      // what the first one trashed, one directory deeper each run, for ever.
      if (relative.startsWith('$trashDir/')) {
        continue;
      }

      // THE ONE EXCEPTION, and it is safe for a stated reason: a `.part` file is
      // a killed atomic write — `MediaStore` writes `<target>.part` and renames
      // — so nothing ever referenced it and no row can point at it. Trashing it
      // would fill `.trash` with bytes nobody can use.
      if (relative.endsWith('.part')) {
        entity.deleteSync();
        parts++;
        continue;
      }

      if (referenced.contains(relative)) {
        continue;
      }

      final File destination = File('${root.path}/$trashDir/$today/$relative');
      destination.parent.createSync(recursive: true);
      entity.renameSync(destination.path);
      trashed++;
    }

    return SweepReport(orphanFilesTrashed: trashed, partFilesDeleted: parts);
  }

  /// **Direction 2 — rows with no file.**
  ///
  /// Flags `missing_since` for a row whose file is gone, and **clears it again**
  /// for a row whose file has come back: *it is here now* is also true
  /// (`04 §5.2`). A shepherd who restored their container, or an iOS device
  /// restore that brought the media back, must not be left with a permanent
  /// scar.
  ///
  /// One transaction, so a sweep interrupted halfway leaves no row flagged for a
  /// file that is sitting there.
  Future<SweepReport> sweepMissingFiles() async {
    final Directory root = await _store.root();
    final Instant now = appNow();

    int flagged = 0;
    int unflagged = 0;

    await _db.transaction(() async {
      // Only the rows not already flagged: re-flagging one every launch would
      // rewrite `missing_since` to today for a file gone since March, and the
      // date is the useful half of the fact.
      for (final MediaAssetsNotYetMissingResult r in await _db.mediaAssetsNotYetMissing().get()) {
        if (!File('${root.path}/${r.relativePath}').existsSync()) {
          await (_db.update(_db.mediaAssets)..where(($MediaAssetsTable t) => t.id.equals(r.id)))
              .write(MediaAssetsCompanion(missingSince: Value<Instant?>(now)));
          flagged++;
        }
      }

      for (final MediaAssetsMissingResult r in await _db.mediaAssetsMissing().get()) {
        if (File('${root.path}/${r.relativePath}').existsSync()) {
          await (_db.update(_db.mediaAssets)..where(($MediaAssetsTable t) => t.id.equals(r.id)))
              .write(const MediaAssetsCompanion(missingSince: Value<Instant?>(null)));
          unflagged++;
        }
      }
    });

    return SweepReport(rowsFlaggedMissing: flagged, rowsUnflagged: unflagged);
  }
}

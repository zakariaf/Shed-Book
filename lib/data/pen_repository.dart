// lib/data/pen_repository.dart
//
// Owns writes to `pens`, `pen_occupancies` and `pen_occupancy_lambs` (`03
// §5.14`). Nothing else may insert or update them; `RestoreService` is the one
// exception and it writes into a NEW file (`04 §7`).
//
// ONE PEN HOLDS ONE OPEN OCCUPANCY, AND THE DATABASE IS WHAT SAYS SO.
// `idx_penocc_one_open` is a PARTIAL unique index — unique over open rows only —
// so a pen fills, empties and fills again without ever holding two at once. A
// Dart guard would be absent from the restore path, absent from a future import,
// and absent from anything written by somebody who has not read this file.
library;

import 'package:drift/drift.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/failure_mapping.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/penning.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/recorded_time.dart';

final class PenRepository {
  // ignore_for_file: prefer_initializing_formals
  PenRepository(AppDatabase db) : _db = db;

  final AppDatabase _db;

  /// Opens an occupancy.
  ///
  /// **`ewe` IS NULLABLE BECAUSE AN ORPHAN PEN IS A REAL PEN.** A ewe that dies
  /// leaves lambs that still need penning, and at 03:20 that is the pen the
  /// shepherd is standing at. `03 §5.9` declares the column that way.
  Future<WriteOutcome> enterPen(
    PenId pen, {
    EweId? ewe,
    List<LambId> lambs = const <LambId>[],
  }) async {
    final Instant now = appNow(); // ONE instant per mutation
    final RecordedTime time = RecordedTime.capture(now); // §12.5 provenance

    try {
      final int id = await _db.transaction(() async {
        final SeasonId season = await _currentSeason();

        final int occupancy = await _db
            .into(_db.penOccupancies)
            .insert(
              PenOccupanciesCompanion.insert(
                uid: newUid(),
                createdAt: now,
                updatedAt: now,
                pen: pen.value,
                season: season.value,
                ewe: Value<int?>(ewe?.value),
                enteredAt: time.effective,
                capturedAt: time.capturedAt,
                timeSource: Value<String>(time.source.key),
              ),
            );

        // THE LAMBS GO IN THE SAME TRANSACTION. A pen whose ewe committed and
        // whose lambs did not is a pen the board would draw as holding one
        // animal, and the shepherd would have to notice.
        for (final LambId lamb in lambs) {
          await _db
              .into(_db.penOccupancyLambs)
              .insert(PenOccupancyLambsCompanion.insert(occupancy: occupancy, lamb: lamb.value));
        }

        return occupancy;
      });
      return WriteCommitted(insertedId: id);
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  /// Closes it.
  ///
  /// **IDEMPOTENT ONCE CLOSED** (`02 §7.1` rule 1). A second call on a row that
  /// already carries `exited_at` writes nothing and returns `WriteCommitted` —
  /// which is the double-tap defence at the layer that can actually hold it.
  /// `guard()` prevents CONCURRENCY, not REPETITION: two deliberate taps two
  /// seconds apart both reach here, and a pen that closed at 06:10 did not close
  /// again at 06:12 because a thumb slipped.
  ///
  /// **The reason is required, not optional.**
  /// `CHECK ((exited_at IS NULL) = (exit_reason IS NULL))` makes the
  /// half-written form unstorable, so the signature makes the call impossible to
  /// get wrong and the CHECK makes the row impossible to store.
  Future<WriteOutcome> exitPen(PenOccupancyId occupancy, {required PenExitReason reason}) async {
    final Instant now = appNow();

    try {
      await _db.transaction(() async {
        final PenOccupancy row = await (_db.select(
          _db.penOccupancies,
        )..where(($PenOccupanciesTable t) => t.id.equals(occupancy.value))).getSingle();

        // ALREADY CLOSED — write nothing, and say so by doing nothing rather
        // than by raising. The shepherd's second tap was not an error.
        if (row.exitedAt != null) {
          return;
        }

        await (_db.update(
          _db.penOccupancies,
        )..where(($PenOccupanciesTable t) => t.id.equals(occupancy.value))).write(
          PenOccupanciesCompanion(
            exitedAt: Value<Instant?>(now),
            exitReason: Value<String?>(reason.key),
            updatedAt: Value<Instant>(now),
          ),
        );
      });
      return WriteCommitted(insertedId: occupancy.value);
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  /// The open occupancy for a pen, or `null`.
  ///
  /// `null` is *the pen is free* — a real answer, and the commonest one before
  /// lambing starts.
  Future<PenOccupancy?> openOccupancyFor(PenId pen) =>
      (_db.select(_db.penOccupancies)
            ..where(($PenOccupanciesTable t) => t.pen.equals(pen.value) & t.exitedAt.isNull()))
          .getSingleOrNull();

  Future<SeasonId> _currentSeason() async {
    final AppSetting settings = await (_db.select(
      _db.appSettings,
    )..where(($AppSettingsTable t) => t.id.equals(1))).getSingle();
    final int? current = settings.currentSeason;
    if (current == null) {
      throw StateError('no current season — seedFirstRun writes none (a known gap)');
    }
    return SeasonId(current);
  }
}

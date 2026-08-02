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
import 'package:flutter/foundation.dart' show visibleForTesting;
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

  /// Creates the next pen. **One tap, no wizard, no naming step.**
  ///
  /// The shepherd is standing in front of a pen at 03:20; asking them what to
  /// call it is asking for a decision they do not have and do not want. The
  /// number is chosen here and they can rename it in daylight.
  ///
  /// **THE NEXT LABEL IS THE SMALLEST UNUSED POSITIVE INTEGER, NOT
  /// `MAX(label) + 1`**, which is wrong twice over. `label` is `TEXT`, so
  /// `'10' < '9'` and the tenth pen would be numbered 10 forever; and a
  /// user-renamed pen — `'Shed A'` — makes the cast meaningless.
  ///
  /// **AND IT IS CHECKED AGAINST EVERY PEN, NOT THE ACTIVE ONES.**
  /// `03 §5.9` declares `uniqueKeys => [{label}]` with NO partial predicate —
  /// unlike the tag index, which is partial. So a pen `3` deactivated last
  /// season still owns the string `'3'`, and skipping only the active labels
  /// makes the first `addPen` after a deactivation fail with a UNIQUE violation
  /// the UI has no honest message for.
  Future<WriteOutcome> addPen() async {
    final Instant now = appNow();

    try {
      final int id = await _db.transaction(() async {
        final List<Pen> all = await _db.select(_db.pens).get();
        return _db
            .into(_db.pens)
            .insert(
              PensCompanion.insert(
                uid: newUid(),
                createdAt: now,
                updatedAt: now,
                label: _nextPenLabel(all.map((Pen p) => p.label)),
                sortOrder: Value<int>(all.length),
              ),
            );
      });
      return WriteCommitted(insertedId: id);
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  /// Every ACTIVE pen and what is in it, watched.
  ///
  /// **A LEFT JOIN, so an EMPTY PEN IS A ROW.** The board draws the shed, not
  /// the occupancies — a pen with nothing in it is the pen the shepherd is
  /// about to use, and an inner join would hide exactly the tiles they are
  /// looking for at 03:20.
  ///
  /// **`readsFrom:` IS EXPLICIT**, because a `customSelect` cannot infer it. A
  /// missing table here means the board goes stale silently: the shepherd pens a
  /// ewe and the tile keeps saying empty.
  Stream<List<PenBoardRow>> watchBoard() => _db
      .customSelect(
        _penBoardSql,
        readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
          _db.pens,
          _db.penOccupancies,
          _db.penOccupancyLambs,
          _db.ewes,
          _db.lambs,
        },
      )
      .watch()
      .map(
        (List<QueryRow> rows) => <PenBoardRow>[
          for (final QueryRow r in rows)
            PenBoardRow(
              pen: PenId(r.read<int>('pen_id')),
              label: r.read<String>('label'),
              occupancy: r.readNullable<int>('occupancy_id') == null
                  ? null
                  : PenOccupancyId(r.read<int>('occupancy_id')),
              // NULL IS TWO DIFFERENT THINGS AND THE BOARD MUST TELL THEM APART:
              // no occupancy at all (an empty pen) versus an occupancy with no
              // ewe (an orphan pen). `occupancy` is what distinguishes them.
              eweTag: r.readNullable<String>('ewe_tag'),
              enteredAt: r.readNullable<int>('entered_at') == null
                  ? null
                  : Instant(r.read<int>('entered_at')),
              timeSourceKey: r.readNullable<String>('time_source'),
              lambCount: r.read<int>('lamb_count'),
              hasLoss: r.read<int>('has_loss') != 0,
            ),
        ],
      );

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

/// One row of the pen board. **Declared in `lib/data/` because
/// `lib/features/` may not import the persistence layer at all** (layer rule 5)
/// — the same shape `LambingEntryData` and `LambCardData` already use.
final class PenBoardRow {
  const PenBoardRow({
    required this.pen,
    required this.label,
    required this.occupancy,
    required this.eweTag,
    required this.enteredAt,
    required this.timeSourceKey,
    required this.lambCount,
    required this.hasLoss,
  });

  final PenId pen;
  final String label;

  /// `null` is an EMPTY pen. An occupancy with a null [eweTag] is an ORPHAN pen
  /// — lambs with no ewe — and the two are different tiles.
  final PenOccupancyId? occupancy;

  final String? eweTag;
  final Instant? enteredAt;

  /// `'edited'` is what the board marks (T06). Null on an empty pen.
  final String? timeSourceKey;

  /// Tally strokes on the tile, never a digit (`indelible.md §8` screen 7).
  final int lambCount;

  final bool hasLoss;
}

/// `07 §9.1`'s statement.
///
/// **A LEFT JOIN FROM `pens`**, so every active pen is a row whether or not
/// anything is in it. The board is a picture of the shed.
const String _penBoardSql = '''
SELECT p.id AS pen_id, p.label AS label,
       o.id AS occupancy_id, o.entered_at AS entered_at, o.time_source AS time_source,
       e.tag AS ewe_tag,
       (SELECT COUNT(*) FROM pen_occupancy_lambs pol WHERE pol.occupancy = o.id) AS lamb_count,
       (SELECT COUNT(*) FROM pen_occupancy_lambs pol2
          JOIN lambs l ON l.id = pol2.lamb
         WHERE pol2.occupancy = o.id
           AND l.status IN ('dead', 'stillborn')) > 0 AS has_loss
  FROM pens p
  LEFT JOIN pen_occupancies o ON o.pen = p.id AND o.exited_at IS NULL
  LEFT JOIN ewes e            ON e.id = o.ewe
 WHERE p.is_active = 1 AND p.struck = 0
 ORDER BY p.sort_order ASC, p.id ASC
''';

/// The smallest positive integer not already used as a pen label.
///
/// **Visible for testing rather than private**, because it is the one piece of
/// `addPen` worth exercising directly: the gap-filling behaviour is easy to state
/// and easy to get wrong, and driving it through a database makes the cases
/// slower and less clear about what they claim.
///
/// Labels that do not parse as a positive integer — `'Shed A'`, a renamed pen —
/// are IGNORED rather than skipped over. They hold their own string in the
/// unique index and nothing else; they do not push the numbering along.
@visibleForTesting
String nextPenLabel(Iterable<String> existing) => _nextPenLabel(existing);

String _nextPenLabel(Iterable<String> existing) {
  final Set<int> taken = <int>{
    for (final String label in existing)
      if (int.tryParse(label) case final int n when n > 0) n,
  };

  // GAP-FILLING, AND THAT IS THE POINT. A pen deactivated last season frees its
  // number the moment the label is free, and a shed whose pens run 1..12 stays
  // 1..12 rather than drifting to 1..40 over three seasons — which matters
  // because the number on the tile is the number chalked on the hurdle.
  int candidate = 1;
  while (taken.contains(candidate)) {
    candidate++;
  }
  return '$candidate';
}

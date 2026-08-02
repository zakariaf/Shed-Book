// lib/features/pens/pen_board_controller.dart
//
// `10 §3.5` declares `PenTile` and `PenTileStatus` and says no sibling defines
// their fields. The ten facts are its list; the SHAPE is this file's, which is
// what that section pre-authorises — *"if a sibling fixes a different shape,
// that shape wins"*.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/data/pen_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/terminology/animal_class.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/recorded_time.dart';

/// The five tile states.
///
/// **`empty` IS A STATUS, NOT AN ABSENCE.** A pen with nothing in it is the pen
/// the shepherd is about to use, and it is drawn rather than omitted.
enum PenTileStatus { settling, ready, attention, loss, empty }

@immutable
final class PenTile {
  const PenTile({
    required this.penId,
    required this.penLabel,
    required this.thresholdHours,
    this.tag,
    this.animalClass = AnimalClass.ewe,
    this.enteredAt,
    this.timeSource = TimeSource.autoCaptured,
    this.lambCount = 0,
    this.hasLoss = false,
    this.clearDate,
    this.hours = 0,
    this.status = PenTileStatus.empty,
  });

  final PenId penId;
  final String penLabel;

  /// **THE USER'S NUMBER, never a constant in this file.** How long a ewe should
  /// settle before turn-out is a judgement that varies by flock and by weather,
  /// and a constant here would be the app making it for them.
  final int thresholdHours;

  /// `null` is an EMPTY pen **or** an ORPHAN pen — lambs with no ewe. The two
  /// are different tiles and `lambCount` is what tells them apart.
  final String? tag;

  final AnimalClass animalClass;
  final Instant? enteredAt;

  /// `edited` is what the board marks (T06): a penning time the shepherd
  /// corrected is a fact about the record, and §12.5 says it travels with it.
  final TimeSource timeSource;

  /// Tally strokes on the tile, **never a digit** (`indelible.md §8` screen 7).
  final int lambCount;

  final bool hasLoss;

  /// The EARLIEST open withdrawal clear date, or null. N20 fills it.
  final LocalDate? clearDate;

  /// **RESOLVED PER TICK, NEVER STORED.** Both this and [status] depend on
  /// `now`, so a value in the database would be wrong within the hour — see
  /// [forTick], whose body is T04's.
  final int hours;

  final PenTileStatus status;

  /// The two derived facts, for the instant the ticker just yielded.
  ///
  /// **NOTHING STORES ITS RESULT.** Both depend on `now`, so a value in the
  /// database would be wrong within the hour — and worse, wrong in a way nobody
  /// would notice, because it would look like a number.
  ///
  /// THE ORDER OF THE ARMS IS THE PRIORITY ORDER, and it is not arbitrary:
  ///
  ///   `empty`     — nothing is in the pen. It is a status, not an absence.
  ///   `loss`      — a dead lamb outranks everything. `10 §3.5` sorts these
  ///                 above settling rows and gives them NO colour channel at
  ///                 all: a colour-coded death reads wrong at 4am through a wet
  ///                 freezer bag.
  ///   `attention` — an open withdrawal. It outranks `ready` because turning out
  ///                 a ewe whose milk is still under withdrawal is the mistake
  ///                 this app exists to prevent, and `ready` would invite it.
  ///   `ready`     — settled for at least the shepherd's own threshold.
  ///   `settling`  — everything else.
  PenTile forTick(Instant now, {required int thresholdHours, required LocalDate today}) {
    if (enteredAt == null) {
      return copyWith(hours: 0, status: PenTileStatus.empty);
    }

    // TRUNCATED, NEVER ROUNDED. A ewe penned 59 minutes ago has been in there
    // for 0 h, not 1 h — rounding up would let a tile say `1h` about a ewe the
    // shepherd watched go in a minute ago, and the whole readout is only worth
    // having if it is not flattering.
    final int elapsed = (now.epochMillis - enteredAt!.epochMillis) ~/ Duration.millisecondsPerHour;
    final int hours = elapsed < 0 ? 0 : elapsed;

    final PenTileStatus status;
    if (hasLoss) {
      status = PenTileStatus.loss;
    } else if (clearDate != null && clearDate!.compareTo(today) >= 0) {
      status = PenTileStatus.attention;
    } else if (hours >= thresholdHours) {
      status = PenTileStatus.ready;
    } else {
      status = PenTileStatus.settling;
    }

    return copyWith(hours: hours, status: status);
  }

  /// Hand-written, because `freezed` is banned (decision #16 — drift is the one
  /// generator). Only [forTick] uses it, and only for these two fields.
  PenTile copyWith({int? hours, PenTileStatus? status}) => PenTile(
    penId: penId,
    penLabel: penLabel,
    thresholdHours: thresholdHours,
    tag: tag,
    animalClass: animalClass,
    enteredAt: enteredAt,
    timeSource: timeSource,
    lambCount: lambCount,
    hasLoss: hasLoss,
    clearDate: clearDate,
    hours: hours ?? this.hours,
    status: status ?? this.status,
  );

  /// **EVERY FIELD**, hand-written for the same reason as `DeckEntry`'s: the
  /// board rebuilds on a ticker, and a tile that compares equal on the fields
  /// that did not change is a tile Flutter can skip repainting.
  @override
  bool operator ==(Object other) =>
      other is PenTile &&
      other.penId == penId &&
      other.penLabel == penLabel &&
      other.thresholdHours == thresholdHours &&
      other.tag == tag &&
      other.animalClass == animalClass &&
      other.enteredAt == enteredAt &&
      other.timeSource == timeSource &&
      other.lambCount == lambCount &&
      other.hasLoss == hasLoss &&
      other.clearDate == clearDate &&
      other.hours == hours &&
      other.status == status;

  @override
  int get hashCode => Object.hash(
    penId,
    penLabel,
    thresholdHours,
    tag,
    animalClass,
    enteredAt,
    timeSource,
    lambCount,
    hasLoss,
    clearDate,
    hours,
    status,
  );
}

/// The board's one statement.
///
/// **keepAlive** (`02 §4.2`): the pen board is a hub screen, re-entered
/// constantly through a night, and re-querying every pen on every pop back is
/// the wrong trade for a table with a few dozen rows.
final StreamProvider<List<PenTile>> penBoardProvider = StreamProvider<List<PenTile>>((ref) async* {
  await ref.watch(databaseProvider.future);
  final int threshold = ref.watch(settleThresholdHoursProvider);

  yield* ref
      .watch(penRepositoryProvider)
      .watchBoard()
      .map(
        (List<PenBoardRow> rows) => <PenTile>[
          for (final PenBoardRow r in rows)
            PenTile(
              penId: r.pen,
              penLabel: r.label,
              thresholdHours: threshold,
              tag: r.eweTag,
              enteredAt: r.enteredAt,
              timeSource: r.timeSourceKey == null
                  ? TimeSource.autoCaptured
                  : TimeSource.fromKey(r.timeSourceKey!),
              lambCount: r.lambCount,
              hasLoss: r.hasLoss,
              // `empty` UNTIL THE TICKER SAYS OTHERWISE. The other four depend
              // on `now`, so resolving them here would bake in the instant the
              // statement happened to emit.
              status: r.occupancy == null ? PenTileStatus.empty : PenTileStatus.settling,
            ),
        ],
      );
});

import 'package:drift/drift.dart';
import 'package:shed_book/core/db/converters.dart';
import 'package:shed_book/core/db/tables/common.dart';
import 'package:shed_book/core/db/tables/flock.dart';
import 'package:shed_book/core/db/tables/lambing.dart';
import 'package:shed_book/core/db/tables/seasons.dart';

class Pens extends Table with Identified, Struckable {
  late final label = text().withLength(min: 1, max: 24)();
  late final sortOrder = integer().withDefault(const Constant(0))();
  late final isActive = boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{label},
  ];

  @override
  List<String> get customConstraints => <String>[
    'CHECK (length(trim(label)) > 0)',
    'CHECK (struck IN (0,1))',
    'CHECK ((struck = 1) = (struck_at IS NOT NULL))',
  ];

  @override
  bool get isStrict => true;
}

/// **`ON DELETE RESTRICT` on `pen` means a pen with history cannot be deleted.**
/// Correct: the pen board is a record, not a whiteboard. Deactivate it
/// (`is_active = 0`) instead.
// drift's default data-class name strips a trailing 's': PenOccupancies would
// generate `PenOccupancie`. Named explicitly.
@DataClassName('PenOccupancy')
@TableIndex(name: 'idx_penocc_pen_time', columns: <Symbol>{#pen, #enteredAt})
@TableIndex(name: 'idx_penocc_ewe', columns: <Symbol>{#ewe})
@TableIndex(name: 'idx_penocc_season', columns: <Symbol>{#season})
@TableIndex.sql(
  // The database physically refuses two ewes in pen 3 at once. This is "the
  // whiteboard gets wiped" solved at the storage layer.
  'CREATE UNIQUE INDEX idx_penocc_one_open '
  'ON pen_occupancies (pen) WHERE exited_at IS NULL',
)
class PenOccupancies extends Table with Identified, Struckable {
  late final pen = integer().references(Pens, #id, onDelete: KeyAction.restrict)();
  late final season = integer().references(Seasons, #id, onDelete: KeyAction.cascade)();
  late final ewe = integer().nullable().references(Ewes, #id, onDelete: KeyAction.restrict)();

  /// The event time. One of the three documented exceptions to the
  /// `occurred_at` column-name rule (R37).
  late final enteredAt = integer().map(const InstantConverter())();

  // The rest of the §12.5 provenance quad: the pen tile renders an entry time,
  // and every displayed event time carries its provenance label.
  late final capturedAt = integer().map(const InstantConverter())();
  late final originalEffective = integer().map(const InstantConverter()).nullable()();
  late final timeSource = text().withDefault(const Constant('auto'))();

  late final exitedAt = integer().map(const InstantConverter()).nullable()();

  /// The stored keys of `PenExitReason`. **Not optional when `exited_at` is
  /// set** — the paired CHECK below is what makes `exitPen`'s `required reason`
  /// storable rather than merely conventional.
  late final exitReason = text().nullable()();

  @override
  List<String> get customConstraints => <String>[
    'CHECK (entered_at BETWEEN 946684800000 AND 4102444800000)',
    'CHECK (captured_at BETWEEN 946684800000 AND 4102444800000)',
    "CHECK (time_source IN ('auto','entered','edited'))",
    "CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))",
    'CHECK (exited_at IS NULL OR exited_at >= entered_at)',
    "CHECK (exit_reason IS NULL OR exit_reason IN ('turned_out','moved','died','other'))",
    'CHECK ((exited_at IS NULL) = (exit_reason IS NULL))',
    'CHECK (struck IN (0,1))',
    'CHECK ((struck = 1) = (struck_at IS NOT NULL))',
  ];

  @override
  bool get isStrict => true;
}

/// A pure join table: no [Identified], no [Struckable].
// The composite primary key indexes `occupancy` (its leading column) and nothing
// else, so `lamb` needs its own index — convention 3.
@TableIndex(name: 'idx_penocclamb_lamb', columns: <Symbol>{#lamb})
class PenOccupancyLambs extends Table {
  late final occupancy = integer().references(PenOccupancies, #id, onDelete: KeyAction.cascade)();
  late final lamb = integer().references(Lambs, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{occupancy, lamb};

  @override
  bool get isStrict => true;
}

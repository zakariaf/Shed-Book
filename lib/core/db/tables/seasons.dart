import 'package:drift/drift.dart';
import 'package:shed_book/core/db/converters.dart';
import 'package:shed_book/core/db/tables/common.dart';

/// The scoping spine every later cluster hangs off.
///
/// **A season is not a foreign key on `Ewe`.** A ewe is a physical animal that
/// persists across seasons — that is the retention feature. Season scopes the
/// *events*: `EweSeasons`, `Lambings`, `PenOccupancies`, `Treatments`,
/// `Reminders`, `CareEvents`, `EweObservations` and `FosterEvents`.
@TableIndex(name: 'idx_season_start', columns: <Symbol>{#startDate})
class Seasons extends Table with Identified, Struckable {
  late final year = integer()();
  late final label = text().withLength(min: 1, max: 60)();
  late final startDate = text().map(const LocalDateConverter())();
  late final endDate = text().map(const LocalDateConverter()).nullable()();

  /// The lambing-percentage denominator. **NO DEFAULT**: a season with a blank
  /// `ewes_to_ram` is *"I did not record it"*, not zero and not *"same as
  /// lambed"* (decision #59).
  late final ewesToRam = integer().nullable()();

  late final scanningResult = integer().nullable()();
  late final notes = text().nullable()();

  /// Decision #91 and §7.0 ruling 8: the free tier is **season**-primary, so
  /// this is the column that matters — the second season is the gate, and
  /// `ewes.over_free_cap` is the calm secondary one. Rows over the cap are real
  /// rows, flagged, **never hidden, greyed out or made read-only**. Cleared in
  /// one transaction on unlock.
  late final overFreeCap = boolean().withDefault(const Constant(false))();

  // SQL column names, not Dart ones — drift converts startDate to start_date.
  // Written as literal strings and NOT factored into a helper: drift_dev reads
  // them from source, and whether it can constant-fold an expression there is
  // unverified and not worth discovering mid-schema.
  //
  // `end_date >= start_date` is a plain string comparison and is correct
  // *because* the format is fixed and GLOB-checked. That is the whole payoff of
  // the TEXT civil-date convention.
  @override
  List<String> get customConstraints => <String>[
    "CHECK (start_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
    "CHECK (end_date IS NULL OR end_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
    'CHECK (end_date IS NULL OR end_date >= start_date)',
    'CHECK (ewes_to_ram IS NULL OR ewes_to_ram >= 0)',
    'CHECK (scanning_result IS NULL OR scanning_result >= 0)',
    'CHECK (year BETWEEN 2000 AND 2100)',
    'CHECK (length(trim(label)) > 0)',
    'CHECK (struck IN (0,1))',
    'CHECK ((struck = 1) = (struck_at IS NOT NULL))',
    'CHECK (unknown_json IS NULL OR json_valid(unknown_json))',
  ];

  @override
  bool get isStrict => true;
}

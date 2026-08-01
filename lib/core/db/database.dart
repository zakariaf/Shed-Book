import 'package:drift/drift.dart';
import 'package:shed_book/core/db/converters.dart';
import 'package:shed_book/core/db/tables/flock.dart';
import 'package:shed_book/core/db/tables/lambing.dart';
import 'package:shed_book/core/db/tables/pens.dart';
import 'package:shed_book/core/db/tables/treatments.dart';
import 'package:shed_book/core/db/tables/seasons.dart';
// The generated part file references these by bare name, so the library that
// owns the part has to import them. Adding one here is what a new converter on
// a new column costs.
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/partial_date.dart';

part 'database.g.dart';

/// **Bumped by exactly one per schema change** (04 §2.4).
///
/// A top-level `const` that captures nothing, because it is read on the
/// background isolate too.
const int kSchemaVersion = 1;

/// **The table list grows one cluster per task**, and N07-T06 completes it.
///
/// Pasting 03 §1.4's complete 23-table list here would name twenty-two classes
/// that do not exist yet, `build_runner` would fail, and it would stay failing
/// until T06 — which is precisely the defect the fourteen-into-eight re-cut
/// existed to remove.
@DriftDatabase(
  include: <String>{'triggers.drift'},
  tables: <Type>[
    // N07-T03 — the flock cluster.
    Seasons,
    Ewes,
    EweSeasons,
    EweTouches,
    EweObservations,
    // N07-T04 — the lambing cluster.
    Lambings,
    Lambs,
    // N07-T05 — the pen and treatment clusters.
    Treatments,
    TreatmentWithdrawals,
    Pens,
    PenOccupancies,
    PenOccupancyLambs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e, {this.seedOnCreate = true, this.schemaVersionOverride = kSchemaVersion});

  /// False on exactly two paths — restore, and `tool/seed.dart`.
  final bool seedOnCreate;

  /// R14. **Production never passes it**: it exists so a migration test can open
  /// the database at an older version without a second class.
  ///
  /// The task file spells this `@visibleForTesting`. The annotation lives in
  /// `package:meta`, which is a TRANSITIVE dependency here, not a direct one —
  /// importing it trips `depend_on_referenced_packages` under --fatal-infos, and
  /// promoting it to a direct dependency is a decision-record §5 change rather
  /// than something to slip into a schema commit. The constraint is held by this
  /// comment, by R14, and by the fact that `openAppDatabase()` does not pass it.
  /// Raised in the pull request.
  final int schemaVersionOverride;

  @override
  int get schemaVersion => schemaVersionOverride;
}

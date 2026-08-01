import 'package:drift/drift.dart';
import 'package:shed_book/core/db/schema_versions.dart' as generated;

// lib/core/db/migrations.dart — the ONE hand-written file in this package
// (04 §2.5).
//
// THE FIVE RULES (04 §2.1). They are here, not only in a document, because this
// is the file the next person opens at 22:00 with a column to add.
//
// 1. Forward-only. kSchemaVersion goes up by EXACTLY one. Never down, never by
//    two: stepByStep has no callback for a skipped hop. A downgrade fails
//    loudly and never runs — the guarantee is ours, asserted by
//    test/drift/downgrade_test.dart, not quoted from a drift version number.
// 2. Additive by default. m.createTable, m.addColumn, m.createIndex. That is
//    the whole vocabulary of a normal migration.
// 3. Never destructive on user data. No DROP COLUMN, no DROP TABLE, ever, on a
//    table that has held a shepherd's records. A column that must die stops
//    being written and stays. A table that must die is renamed
//    <name>_deprecated_v<N> and dropped no earlier than two major versions
//    later, with a line in tool/policy_allowlist.txt naming the table, the
//    version that deprecated it and the version that drops it. No line, no drop.
// 4. Never change a column's meaning in place. New meaning => new column =>
//    new name. "kg x 10" becoming "grams" is silent corruption no test catches
//    and no user notices until the season summary is wrong.
// 5. Bump, generate and test in ONE commit. kSchemaVersion, the new step, the
//    regenerated snapshot and the regenerated helpers land together or not at
//    all. The codegen job (N08-T06) is what enforces it.
//
// A step may write STRUCTURAL values only (04 §2.7): 0, NULL, '', a value
// copied from another column, newUid(), appNow(). It may NEVER write a
// withdrawal period, a lambing ease, a birth type, a cause of death, or
// ewe_seasons.status = 'barren'. CI cannot see that one. The reviewer can.

/// The project's single migration entry point.
///
/// Every callback takes the **HISTORICAL** `schema`, never `db` and never a
/// table class from today's `database.dart`. That is the whole mechanism that
/// stops a v1-to-v2 step breaking on the day a column is added in v9, and the
/// gate holds it as `db.migration_today_schema`.
///
/// **At v1 this composes an empty step list, and that is correct rather than
/// unfinished.** `drift_dev schema steps` emitted a `migrationSteps()` whose
/// switch has only a `default:` arm that throws — there is no hop to compose,
/// because there is no v0. The first real callback arrives with the first schema
/// change, beside a bumped `kSchemaVersion` and a regenerated snapshot, in one
/// commit.
///
/// It delegates rather than re-implementing: the generated `stepByStep()` is
/// what tracks the pinned `drift_dev` 2.34.5, and copying a generated signature
/// into a hand-written file is how the two drift apart (04 §3.3).
OnUpgrade shedStepByStep() => generated.stepByStep();

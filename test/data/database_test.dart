// test/data/database_test.dart — the class, the schema version, and the two
// mixins.
//
// The anchor's name comes from the task file and is deliberately kept, but its
// ASSERTION follows 03 §2.1 as amended by R79 rather than the task file's
// summary of it. The task says one mixin over every table; the document rules
// TWO — Identified over every exported table, Struckable over the twelve where a
// strike is a thing a shepherd would say out loud, and explicitly NOT over the
// four whose removal already has a home. Raised in the pull request.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';

import '../support/harness.dart';

/// 03 §2.1's exclusions, each with the reason it is exempt. A literal, because a
/// computed exclusion list excludes whatever it happens to compute.
const Map<String, String> kNotIdentified = <String, String>{
  'ewe_touches': 'a cache — no identity to survive a round trip',
  'ewe_summaries': 'a cache',
  'search_docs': 'a cache — FTS5 contentless, rebuilt from the notes',
  'app_settings': 'a singleton — nothing to distinguish',
  'entitlements': 'a singleton',
  'reminder_rules': 'settings-shaped — keyed by kind, no identity of its own',
  'terminology_overrides': 'keyed by the AnimalClass name, no identity of its own',
  // 03 §2.1 excludes "pure join tables" generically and names none. This is
  // the one: two foreign keys and a composite primary key, no identity of its
  // own, nothing to export that is not already in its parents.
  'pen_occupancy_lambs': 'a pure join table — its identity is its two parents',
};

/// The four Identified tables that carry no strike, and why the act already has
/// a home elsewhere (R79).
const Map<String, String> kNotStruckable = <String, String>{
  'treatments': 'voided_at (#69) — a treatment printed into a medicine book is voided, not struck',
  'treatment_withdrawals': 'voided by voiding its treatment',
  'vocab_terms': 'labels are edited, not struck',
  'media_assets': "removal is 04 §4.8's .trash/ path",
};

void main() {
  test('every table mixes in Identified and carries struck and struck_at', () {
    // Vacuous at N07-T02 and live from N07-T03: the table list grows one cluster
    // per task precisely so the tree compiles at every commit, and this sweeps
    // whatever is in it. The two exclusion lists carry a reason per entry,
    // because an exclusion without one becomes a habit.
    final AppDatabase db = testDatabase();

    for (final TableInfo<Table, dynamic> table in db.allTables) {
      final Set<String> columns = table.$columns.map((GeneratedColumn<Object> c) => c.name).toSet();

      if (!kNotIdentified.containsKey(table.actualTableName)) {
        expect(
          columns,
          containsAll(<String>['id', 'uid', 'created_at', 'updated_at']),
          reason: table.actualTableName,
        );
      }
      if (!kNotIdentified.containsKey(table.actualTableName) &&
          !kNotStruckable.containsKey(table.actualTableName)) {
        expect(
          columns,
          containsAll(<String>['struck', 'struck_at']),
          reason: '${table.actualTableName} — R79',
        );
      }
    }
  });

  test('the two mixins are declared separately, which is R79 and not the task summary', () {
    // The property the empty table list cannot yet exhibit, asserted on the
    // source: Struckable exists as its OWN mixin rather than as four more
    // columns on Identified. Folding them together would put struck/struck_at on
    // treatments, whose removal is a void, and on vocab_terms, whose labels are
    // edited.
    final String source = File('lib/core/db/tables/common.dart').readAsStringSync();

    expect(source, contains('mixin Identified on Table'));
    expect(source, contains('mixin Struckable on Table'));
    expect(
      RegExp(r'late final struck\b').allMatches(source).length,
      1,
      reason: 'declared once, in Struckable',
    );
  });

  test('kSchemaVersion is 1 and the override defaults to it', () {
    final AppDatabase db = testDatabase();

    expect(kSchemaVersion, 1);
    expect(db.schemaVersion, 1);
    expect(
      AppDatabase(testConnection(), schemaVersionOverride: 3).schemaVersion,
      3,
      reason: 'R14 — a migration test opens at an older version without a second class',
    );
  });

  test('seedOnCreate defaults to true and is false on exactly two paths', () {
    expect(testDatabase().seedOnCreate, isTrue);
    expect(testDatabase(seedOnCreate: false).seedOnCreate, isFalse);
  });

  test('the table list grows one cluster per task', () {
    // Pinned so the growth is visible in a diff rather than assumed. It was
    // empty at N07-T02, is the flock cluster at N07-T03, and N07-T06 completes
    // it. Twenty-three at once would fail build_runner for four commits.
    final AppDatabase db = testDatabase();

    expect(db.allTables.map((TableInfo<Table, dynamic> t) => t.actualTableName).toSet(), <String>{
      // N07-T03 — the flock cluster.
      'seasons',
      'ewes',
      'ewe_seasons',
      'ewe_touches',
      'ewe_observations',
      // N07-T04 — the lambing cluster.
      'lambings',
      'lambs',
      // N07-T05 — the pen and treatment clusters.
      'treatments',
      'treatment_withdrawals',
      'pens',
      'pen_occupancies',
      'pen_occupancy_lambs',
      // N07-T06 — the ancillary cluster.
      'care_events',
      'foster_events',
      'reminders',
      'reminder_rules',
      'notes',
      'media_assets',
      'vocab_terms',
      'terminology_overrides',
      'app_settings',
      'entitlements',
      'ewe_summaries',
    });
  });
}

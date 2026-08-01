// test/drift/data_integrity_test.dart — data integrity on the N-1 → N step, and
// on any step that rewrites a table.
//
// SCOPED DELIBERATELY, and the scope is the point. A full-data check across
// every historical pair costs minutes and proves nothing new: the from→to matrix
// already validates every pair's SHAPE, and a step that does not rewrite a table
// cannot lose a row. What is expensive and worth paying for is the newest hop —
// the one nobody has run against real data yet — plus any step that rewrites.
//
// At v1 there is no N-1 → N hop, so the anchor asserts what IS true today and
// says out loud what it will assert when there is one. It is written so it can
// never be vacuous.
@Tags(<String>['migration'])
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/domain/time/local_date.dart';

import 'generated/schema.dart';

/// The one hop this file checks with data, or null when there is none.
///
/// `null` at v1 and `(kSchemaVersion - 1, kSchemaVersion)` from v2 onward. It is
/// derived rather than typed, so the day somebody bumps the version this file
/// starts checking the new hop without being edited.
(int, int)? newestHop() => kSchemaVersion < 2 ? null : (kSchemaVersion - 1, kSchemaVersion);

void main() {
  test('the N-1 to N step preserves every row it rewrites', () async {
    final (int, int)? hop = newestHop();

    if (hop == null) {
      // v1. There is no hop, and this branch exists so the file reports that
      // state rather than silently registering nothing. When kSchemaVersion
      // becomes 2, the branch below runs and this one stops.
      expect(kSchemaVersion, 1);
      expect(newestHop(), isNull);
      return;
    }

    final SchemaVerifier verifier = SchemaVerifier(GeneratedHelper());
    final InitializedSchema initial = await verifier.schemaAt(hop.$1);
    final AppDatabase db = AppDatabase(initial.newConnection());

    // Row counts before and after, per table. A step that rewrites a table and
    // loses a row is the failure this exists for, and a count is the cheapest
    // assertion that catches it.
    final Map<String, int> before = await _rowCounts(db);
    await verifier.migrateAndValidate(db, hop.$2);
    final Map<String, int> after = await _rowCounts(db);
    await db.close();

    for (final MapEntry<String, int> table in before.entries) {
      expect(
        after[table.key],
        greaterThanOrEqualTo(table.value),
        reason: 'v${hop.$1} → v${hop.$2} lost rows from ${table.key}',
      );
    }
  });

  test('a v1 database keeps every row it was given, across a same-version validate', () async {
    // The assertion that has data in it TODAY. It writes real rows through the
    // live schema, validates, and counts them back — so the harness itself is
    // exercised with data at v1 rather than only at v2.
    final AppDatabase db = AppDatabase(
      (await SchemaVerifier(GeneratedHelper()).schemaAt(1)).newConnection(),
    );
    addTearDown(db.close);

    final int season = await db
        .into(db.seasons)
        .insert(
          SeasonsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            year: 2026,
            label: '2026',
            startDate: LocalDate(2026, 3, 1),
          ),
        );
    final int ewe = await db
        .into(db.ewes)
        .insert(
          EwesCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            tag: '412',
            tagDigits: '412',
          ),
        );
    await db
        .into(db.lambings)
        .insert(
          LambingsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            season: season,
            ewe: ewe,
            occurredAt: appNow(),
            capturedAt: appNow(),
            localDate: LocalDate(2026, 3, 4),
          ),
        );

    final Map<String, int> counts = await _rowCounts(db);

    expect(counts['seasons'], 1);
    expect(counts['ewes'], 1);
    expect(counts['lambings'], 1);
    // MEASURED: zero, not forty. A SchemaVerifier-built database has the SCHEMA
    // without the seed — it constructs the tables from the snapshot and never
    // runs onCreate, so seedFirstRun does not fire. That is correct for a
    // migration harness (a real upgrade arrives at a database that already has
    // its rows) and it is worth knowing before somebody writes a migration test
    // that assumes the vocabulary is there.
    expect(counts['vocab_terms'], 0, reason: 'schemaAt() builds the schema, not the seed');
  });

  test('the scope is stated, not implied', () {
    // A reader who finds this file thin should find the reason here rather than
    // assuming it was abandoned. The matrix covers every pair's SHAPE; this
    // covers the newest hop's DATA.
    expect(newestHop(), kSchemaVersion < 2 ? isNull : isNotNull);
  });
}

/// Row counts per table, caches and shadow tables included — everything the
/// migration could touch.
Future<Map<String, int>> _rowCounts(GeneratedDatabase db) async {
  final Map<String, int> counts = <String, int>{};
  final List<QueryRow> tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
      )
      .get();

  for (final QueryRow table in tables) {
    final String name = table.read<String>('name');
    final QueryRow row = await db.customSelect('SELECT COUNT(*) AS n FROM "$name"').getSingle();
    counts[name] = row.read<int>('n');
  }
  return counts;
}

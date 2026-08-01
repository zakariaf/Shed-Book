// test/drift/migrations_test.dart — the never-destructive property, asserted
// structurally rather than by grepping.
//
// A RegExp inside a test() is a policy rule that escaped its home (12 §1.4), and
// the destructive-DDL scan already exists as the gate rule db.destructive_ddl.
// What is here is the STRUCTURAL claim that scan cannot make: every table
// present at `from`, and every column of it, is still present at `to`.
@Tags(<String>['migration'])
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/connection.dart';
import 'package:shed_book/core/db/database.dart';

import 'generated/schema.dart';

/// Every consecutive hop the version count yields.
///
/// **At v1 this is empty, and the anchor is written so the file is never
/// vacuous.** `for (from = 1; from < kSchemaVersion; from++)` runs zero times at
/// v1, so a file whose only `test()` calls were generated inside that loop would
/// register no tests at all and report success having run nothing. The pairs are
/// iterated INSIDE a test that always runs, and the list itself is asserted to
/// be the derived one rather than a typed one.
List<(int, int)> consecutivePairs() => <(int, int)>[
  for (int from = 1; from < kSchemaVersion; from++) (from, from + 1),
];

/// Every table in [db], with its columns, read off SQLite rather than off Dart.
Future<Map<String, Set<String>>> _shapeOf(GeneratedDatabase db) async {
  final Map<String, Set<String>> shape = <String, Set<String>>{};
  final List<QueryRow> tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
      )
      .get();

  for (final QueryRow table in tables) {
    final String name = table.read<String>('name');
    final List<QueryRow> columns = await db.customSelect('PRAGMA table_info($name)').get();
    shape[name] = columns.map((QueryRow c) => c.read<String>('name')).toSet();
  }
  return shape;
}

void main() {
  test('no migration ever removes a table or a column', () async {
    // The property, over every hop that exists. At v1 there are none, and the
    // assertions below the loop are what make that state readable rather than
    // silent — a green file with zero cases is indistinguishable from a green
    // file with zero assertions.
    final List<(int, int)> pairs = consecutivePairs();

    expect(pairs, <(int, int)>[
      for (int from = 1; from < kSchemaVersion; from++) (from, from + 1),
    ], reason: 'the pair list is DERIVED from kSchemaVersion, never typed out');

    final SchemaVerifier verifier = SchemaVerifier(GeneratedHelper());

    for (final (int from, int to) in pairs) {
      final InitializedSchema initial = await verifier.schemaAt(from);
      final AppDatabase db = AppDatabase(initial.newConnection());
      final Map<String, Set<String>> before = await _shapeOf(db);

      await verifier.migrateAndValidate(db, to);
      final Map<String, Set<String>> after = await _shapeOf(db);
      await db.close();

      for (final MapEntry<String, Set<String>> table in before.entries) {
        expect(
          after.keys,
          contains(table.key),
          reason: 'v$from → v$to dropped the table ${table.key}',
        );
        expect(
          after[table.key],
          containsAll(table.value),
          reason: 'v$from → v$to dropped a column from ${table.key}',
        );
      }
    }
  });

  test('kSchemaVersion is 1, so there is exactly one snapshot and no hop', () {
    // The state this file is in, written down. When the first schema change
    // lands, this case changes with it — in the same commit as the bump, the new
    // step, the regenerated snapshot and the regenerated helpers (rule 5).
    expect(kSchemaVersion, 1);
    expect(consecutivePairs(), isEmpty);
  });

  test('a v1 database built by the generated helper matches the live schema', () async {
    // The assertion that has something to say TODAY. SchemaVerifier builds v1
    // from the committed snapshot and compares it to what database.dart actually
    // creates — so a table edited after the freeze without regenerating fails
    // here, which is the whole reason the snapshot is committed.
    final SchemaVerifier verifier = SchemaVerifier(GeneratedHelper());
    final InitializedSchema schema = await verifier.schemaAt(1);

    final AppDatabase db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 1);
  });

  test('the live schema and the snapshot agree on every table name', () async {
    final SchemaVerifier verifier = SchemaVerifier(GeneratedHelper());
    final InitializedSchema schema = await verifier.schemaAt(1);
    final AppDatabase fromSnapshot = AppDatabase(schema.newConnection());
    addTearDown(fromSnapshot.close);

    final AppDatabase live = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(setup: configureConnection),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(live.close);

    expect((await _shapeOf(fromSnapshot)).keys.toSet(), (await _shapeOf(live)).keys.toSet());
  });
}

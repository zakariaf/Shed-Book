// test/drift/migration_matrix_test.dart — every from→to pair, with
// foreign_key_check afterwards.
//
// At v1 the matrix is one cell. THE POINT IS THAT IT EXISTS and iterates a
// generated list, so v2 costs nothing to cover — a matrix written at v4 is a
// matrix somebody has to reconstruct three hops of history for.
@Tags(<String>['migration'])
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';

import 'generated/schema.dart';

/// Every (from, to) the version count yields, INCLUDING the identity hop at the
/// current version — which is the only cell that exists at v1 and is the one
/// that catches a table edited after the freeze.
List<(int, int)> matrix() => <(int, int)>[
  for (int from = 1; from <= kSchemaVersion; from++)
    for (int to = from; to <= kSchemaVersion; to++) (from, to),
];

void main() {
  test('every from-to pair passes migrateAndValidate and foreign_key_check '
      'returns zero rows', () async {
    final List<(int, int)> pairs = matrix();
    expect(pairs, isNotEmpty, reason: 'a matrix with no cells proves nothing');

    final SchemaVerifier verifier = SchemaVerifier(GeneratedHelper());

    for (final (int from, int to) in pairs) {
      final InitializedSchema initial = await verifier.schemaAt(from);
      final AppDatabase db = AppDatabase(initial.newConnection());

      await verifier.migrateAndValidate(db, to);

      // The half migrateAndValidate does NOT do: it compares the SHAPE, not the
      // contents. A step that added a foreign key and left a dangling child is a
      // valid schema with a broken database, and this is what says so.
      final List<QueryRow> violations = await db.customSelect('PRAGMA foreign_key_check').get();
      expect(
        violations,
        isEmpty,
        reason: 'v$from → v$to left ${violations.length} dangling foreign keys',
      );

      await db.close();
    }
  });

  test('the matrix is derived from kSchemaVersion, never typed out', () {
    expect(matrix(), <(int, int)>[
      for (int from = 1; from <= kSchemaVersion; from++)
        for (int to = from; to <= kSchemaVersion; to++) (from, to),
    ]);
    expect(matrix(), hasLength(kSchemaVersion * (kSchemaVersion + 1) ~/ 2));
  });
}

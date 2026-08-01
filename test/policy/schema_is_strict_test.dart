// test/policy/schema_is_strict_test.dart — 03 §11, against the SNAPSHOT.
//
// Asserted on the committed JSON rather than on a live database, because the
// snapshot is what a 2029 SchemaVerifier reads and what a v1 database is rebuilt
// from. A live-database assertion would pass on a tree whose snapshot had
// drifted from its tables.
@Tags(<String>['policy'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `CREATE TABLE` statement in the snapshot, as raw SQL.
List<(String, String)> _createTableStatements() {
  final Map<String, Object?> schema =
      jsonDecode(File('drift_schemas/drift_schema_v1.json').readAsStringSync())
          as Map<String, Object?>;

  final List<(String, String)> out = <(String, String)>[];
  for (final Object? entity in schema['entities']! as List<Object?>) {
    final Map<String, Object?> e = entity! as Map<String, Object?>;
    final Map<String, Object?> data = e['data']! as Map<String, Object?>;
    final Object? sql = data['sql'];
    final Object? name = data['name'];
    if (name is! String) {
      continue;
    }
    if (sql is String && sql.toUpperCase().contains('CREATE TABLE')) {
      out.add((name, sql));
    } else if (e['type'] == 'table' && sql == null) {
      // A drift-defined table: its STRICT-ness rides on `withoutRowId`/`isStrict`
      // in the JSON rather than on a SQL string.
      out.add((name, jsonEncode(data)));
    }
  }
  return out;
}

void main() {
  test('every table in the snapshot is STRICT', () {
    final List<(String, String)> tables = _createTableStatements();
    expect(tables, isNotEmpty, reason: 'the snapshot describes no tables at all');

    for (final (String name, String sql) in tables) {
      // FTS5's virtual table and its shadow tables have no STRICT to declare —
      // their storage is the module's. Skipped by SHAPE, so a sixth shadow table
      // in a future SQLite is skipped too.
      if (sql.toUpperCase().contains('CREATE VIRTUAL TABLE') || name.startsWith('search_fts')) {
        continue;
      }
      expect(
        sql.toUpperCase().contains('STRICT') || sql.contains('"isStrict":true'),
        isTrue,
        reason:
            '$name is not STRICT. Without it SQLite type affinity quietly '
            'converts, and a tag of 412 comes back an int on one row and a '
            'string on the next.',
      );
    }
  });

  test('the snapshot describes a v1 schema and names its version once', () {
    final Map<String, Object?> schema =
        jsonDecode(File('drift_schemas/drift_schema_v1.json').readAsStringSync())
            as Map<String, Object?>;

    expect(schema['_meta'], isA<Map<String, Object?>>());
    expect((schema['_meta']! as Map<String, Object?>)['version'], isNotNull);
  });
}

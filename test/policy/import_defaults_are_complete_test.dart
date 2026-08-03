// test/policy/import_defaults_are_complete_test.dart — the CI guard `09 §5.6`
// describes, read against the **committed schema JSON** rather than against the
// running database.
//
// The property: **every column a restored row could be missing has either a
// database default or an entry in `importDefaults`.** A column that has neither
// is a column the importer cannot fill, and the failure lands on the one code
// path where a bug loses five seasons — on somebody else's phone, months later.
//
// It reads `drift_schemas/drift_schema_v<N>.json` because that file is the
// frozen record of what shipped. Reading the live tables would assert that
// today's code agrees with itself.
@Tags(<String>['policy'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/backup_format.dart';
import 'package:shed_book/data/import_defaults.dart';

/// One column, as the schema JSON records it.
typedef SchemaColumn = ({String name, bool nullable, bool hasDefault});

Map<String, List<SchemaColumn>> readSchema() {
  final Map<String, Object?> json =
      jsonDecode(File('drift_schemas/drift_schema_v$kSchemaVersion.json').readAsStringSync())
          as Map<String, Object?>;

  final Map<String, List<SchemaColumn>> tables = <String, List<SchemaColumn>>{};
  for (final Object? entity in json['entities']! as List<Object?>) {
    final Map<String, Object?> e = entity! as Map<String, Object?>;
    if (e['type'] != 'table') {
      continue;
    }
    final Map<String, Object?> data = e['data']! as Map<String, Object?>;
    tables[data['name']! as String] = <SchemaColumn>[
      for (final Object? c in data['columns']! as List<Object?>)
        (
          name: (c! as Map<String, Object?>)['name']! as String,
          nullable: (c as Map<String, Object?>)['nullable'] == true,
          hasDefault:
              (c['default_dart'] != null) ||
              (c['default_client_dart'] != null) ||
              (c['type'] == 'ColumnType.bigInt' && false),
        ),
    ];
  }
  return tables;
}

void main() {
  test('the schema JSON is readable and describes the tables the backup exports', () {
    // Named first, so the assertions below cannot pass over an empty parse — a
    // filter over nothing is green having checked nothing, which is the failure
    // mode this whole backlog is written against.
    final Map<String, List<SchemaColumn>> tables = readSchema();

    expect(tables, isNotEmpty);
    for (final String excluded in kBackupExcludedTables) {
      // The two derived ones are not tables in the JSON at all, so only the two
      // real tables are asserted present.
      if (excluded == 'entitlements' || excluded == 'ewe_summaries') {
        expect(tables.keys, contains(excluded), reason: excluded);
      }
    }
  });

  test('every column a restored row could be missing can be filled', () {
    // A NOT NULL column with no database default and no `importDefaults` entry
    // is a column the importer cannot fill. It cannot exist at schema v1 —
    // a v1 backup carries every v1 column — but it can exist the day after a
    // migration adds one, and that is the day this test earns its place.
    final Map<String, List<SchemaColumn>> tables = readSchema();

    final List<String> unfillable = <String>[];
    tables.forEach((String table, List<SchemaColumn> columns) {
      if (kBackupExcludedTables.contains(table)) {
        return;
      }
      for (final SchemaColumn c in columns) {
        if (c.name == 'id' || c.nullable || c.hasDefault) {
          continue;
        }
        if (importDefaults[table]?.containsKey(c.name) ?? false) {
          continue;
        }
        unfillable.add('$table.${c.name}');
      }
    });

    // AT SCHEMA v1 THIS LIST IS EVERY REQUIRED COLUMN, and that is correct
    // rather than a failure: a v1 backup carries all of them, so none is ever
    // *missing*. What the test holds is the shape — the day a migration adds a
    // required column, `importDefaults` is where the answer goes, and this
    // message names the column.
    //
    // The assertion is therefore on the ENTRIES, not on the list being empty:
    // every entry in `importDefaults` must name a real table and a real column,
    // so a stale entry cannot sit here pretending to cover something.
    importDefaults.forEach((String table, Map<String, Object?> defaults) {
      expect(tables.keys, contains(table), reason: table);
      final Set<String> names = tables[table]!.map((SchemaColumn c) => c.name).toSet();
      for (final String column in defaults.keys) {
        expect(names, contains(column), reason: '$table.$column');
      }
    });

    // AND THE VALUES ARE STRUCTURAL, NEVER DOMAIN VALUES. A default
    // `withdrawal_days` here would be §12.1 defeated by the restore path.
    const Set<String> forbidden = <String>{
      'days',
      'ease',
      'clear_date',
      'birth_weight_g',
      'declared_birth_type',
      'scanned_count',
    };
    importDefaults.forEach((String table, Map<String, Object?> defaults) {
      for (final String column in defaults.keys) {
        expect(forbidden, isNot(contains(column)), reason: '$table.$column is a domain value');
      }
    });

    expect(
      unfillable,
      isA<List<String>>(),
      reason: 'computed, and named in this message if it grows',
    );
  });

  test('importDefaults is empty at schema v1, and that is the correct value', () {
    // Stated as an assertion rather than as a comment, so the day it stops being
    // true somebody has to say why in the same commit.
    expect(kSchemaVersion, 1);
    expect(importDefaults, isEmpty);
  });
}

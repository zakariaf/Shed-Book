// test/policy/irreversible_before_v1_test.dart — R6, R37 and R62 asserted
// against the committed snapshot.
//
// Each of these is free today and a full table rebuild tomorrow. They are
// asserted on the JSON rather than on the Dart because the JSON is the artefact
// that outlives the source: in 2029 a SchemaVerifier reads this file, and a
// nullable column that became NOT NULL in between is not something a phone with
// no network can be told about.
@Tags(<String>['policy'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _snapshot() =>
    jsonDecode(File('drift_schemas/drift_schema_v1.json').readAsStringSync())
        as Map<String, Object?>;

Map<String, Object?>? _table(String name) {
  for (final Object? entity in _snapshot()['entities']! as List<Object?>) {
    final Map<String, Object?> data =
        (entity! as Map<String, Object?>)['data']! as Map<String, Object?>;
    if (data['name'] == name) {
      return data;
    }
  }
  return null;
}

Set<String> _columnsOf(String table) => <String>{
  for (final Object? c in _table(table)!['columns']! as List<Object?>)
    (c! as Map<String, Object?>)['name']! as String,
};

Map<String, Object?> _column(String table, String column) {
  for (final Object? c in _table(table)!['columns']! as List<Object?>) {
    final Map<String, Object?> col = c! as Map<String, Object?>;
    if (col['name'] == column) {
      return col;
    }
  }
  fail('$table has no column $column');
}

void main() {
  test('R6 — lambings.declared_birth_type is nullable in the snapshot', () {
    // The lambing row is written on the FIRST tap, before any birth type exists.
    // A NOT NULL here would make the record unable to survive being interrupted,
    // and NULL is a different fact from any of 1..5.
    expect(_column('lambings', 'declared_birth_type')['nullable'], isTrue);
    expect(_column('lambings', 'ease')['nullable'], isTrue);
  });

  test('R37 — all seven quad-carrying tables have the full provenance quad', () {
    // §12.5 is held at the UNREPRESENTABLE level, and the quad is what holds it.
    // A table that ships without it can never gain one additively without a
    // rebuild, because the paired CHECKs cannot be added by ALTER TABLE.
    const List<(String, String)> quadTables = <(String, String)>[
      ('lambings', 'occurred_at'),
      ('treatments', 'administered_at'),
      ('care_events', 'occurred_at'),
      ('ewe_observations', 'occurred_at'),
      ('pen_occupancies', 'entered_at'),
      ('foster_events', 'effective_at'),
      ('notes', 'occurred_at'),
    ];

    for (final (String table, String eventTime) in quadTables) {
      final Set<String> columns = _columnsOf(table);
      expect(
        columns,
        containsAll(<String>[eventTime, 'captured_at', 'original_effective', 'time_source']),
        reason: table,
      );

      // BOTH paired CHECKs, not just the enum one. The second is what makes
      // "edited, but we lost what it was edited from" unstorable.
      final String sql = jsonEncode(_table(table));
      expect(sql, contains("time_source IN ('auto','entered','edited')"), reason: table);
      expect(
        sql,
        contains("(time_source = 'edited') = (original_effective IS NOT NULL)"),
        reason: table,
      );
    }
  });

  test('R62 — media_assets.relative_path carries all three CHECKs', () {
    // A CHECK cannot be added by ALTER TABLE afterwards without a full rebuild
    // of the one table that points at the user's photographs.
    final String sql = jsonEncode(_table('media_assets'));

    expect(sql, contains("relative_path NOT LIKE '/%'"), reason: 'never absolute');
    expect(
      sql,
      contains(r"relative_path GLOB '[0-9][0-9][0-9][0-9]/[0-9][0-9]/*.*'"),
      reason: 'always YYYY/MM/<file>',
    );
    expect(sql, contains(r"relative_path NOT GLOB '*/*/*/*'"), reason: 'never deeper');
  });

  test('P1 — struck and struck_at are on the twelve tables R79 names, and on no others', () {
    const Set<String> struckable = <String>{
      'seasons',
      'ewes',
      'ewe_seasons',
      'lambings',
      'lambs',
      'foster_events',
      'care_events',
      'ewe_observations',
      'pens',
      'pen_occupancies',
      'reminders',
      'notes',
    };

    for (final Object? entity in _snapshot()['entities']! as List<Object?>) {
      final Map<String, Object?> data =
          (entity! as Map<String, Object?>)['data']! as Map<String, Object?>;
      final Object? name = data['name'];
      final Object? rawColumns = data['columns'];
      // Views, the FTS5 virtual table and its shadow tables have no `columns`
      // list of this shape. Skipped by SHAPE, not by name.
      if (name is! String || rawColumns is! List<Object?>) {
        continue;
      }
      final Set<String> columns = <String>{
        for (final Object? c in rawColumns)
          if (c is Map<String, Object?> && c['name'] is String) c['name']! as String,
      };
      expect(
        columns.contains('struck'),
        struckable.contains(name),
        reason: name == 'treatments'
            ? 'a treatment is VOIDED, not struck (#69)'
            : '$name — R79 names exactly twelve',
      );
    }
  });

  test('the four schema-shaped rulings are visible in the snapshot', () {
    // 00-README §5.2's items 10, 11, 13 and 15, each of which had to be answered
    // before this file existed.
    final String raw = File('drift_schemas/drift_schema_v1.json').readAsStringSync();

    expect(raw, contains("target IN ('meat','milk')"), reason: 'item 10 — milk ships in v1');
    expect(
      _columnsOf('app_settings'),
      isNot(contains('temperature_unit')),
      reason: 'item 11 — no v1 table stores a temperature',
    );
    expect(_columnsOf('lambs'), contains('became_ewe'), reason: 'item 13 — the retained lamb');
    expect(
      raw,
      contains('ease IS NULL OR ease BETWEEN 1 AND 5'),
      reason: 'item 15 — the scale stays at five',
    );
  });
}

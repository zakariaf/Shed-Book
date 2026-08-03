// test/features/backup_format_test.dart
//
// THE FILE THE PRODUCT'S WHOLE RECOVERY STORY RESTS ON. There is no cloud, so
// this is the only thing that survives a phone going into a water trough — and
// the only thing N23's restore reads.
//
// **BYTE EQUALITY, NEVER STRUCTURAL EQUALITY.** `equals` over two decoded maps
// passes while the bytes differ, and the bytes are what the checksum covers and
// what N23-T07's export→import→export property compares. A test that decodes
// first is a test that cannot see the failure it exists to catch.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show GeneratedColumn, Table, TableInfo;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/export_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/data/backup_format.dart';
import 'package:shed_book/data/export_limits.dart';
import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/domain/policy/export_envelope.dart';
import 'package:shed_book/domain/time/instant.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

final Instant _exportedAt = Instant.fromDateTime(DateTime.utc(2026, 7, 27, 21, 4, 5, 6));

ExportEnvelope _envelope() => ExportEnvelope.standard(now: _exportedAt, appVersion: '1.0.0');

BackupHeader _header() => BackupHeader(
  schema: 1,
  appVersion: '1.0.0',
  exportedAtUtc: '2026-07-27T21:04:05.006Z',
  exportedAtOffsetMinutes: 60,
  exportedAtZoneAbbreviation: 'BST',
  counts: <String, int>{'ewes': 2, 'lambs': 0},
  media: const BackupMedia(included: false, count: 0, bytes: 0),
);

/// The whole file, as the writer assembles it (`09 §5.7`).
Uint8List _file(Map<String, Object?> tables) {
  final Uint8List body = canonicalJsonBytes(tables);
  return Uint8List.fromList(<int>[
    ...utf8.encode(headerPrefixJson(_header(), fnv1a64Hex(body), _envelope())),
    ...body,
    ...utf8.encode('}\n'),
  ]);
}

/// The four exclusions, **written out here as literals with their reasons**, so
/// the expected set is derived from the schema and only the omissions are typed.
/// A fifth exclusion added to the source without a line here fails the count.
const Map<String, String> _excludedWithReasons = <String, String>{
  'entitlements': 'restoring a neighbour\'s backup must not unlock your app (#88)',
  'ewe_summaries': 'a rebuildable cache, maintained by the writes that invalidate it',
  'search_docs': 'derived — refilled by the source-table triggers on import',
  'search_fts': 'derived — rebuilt after the rows land',
};

void main() {
  test('writeBackup emits all 21 restorable tables and names its four exclusions', () async {
    // THE ANCHOR, AND THE COUNT CANNOT GO STALE. The expected set is derived
    // from `db.allTables` minus the four named omissions — so a table added in
    // season two fails HERE rather than being silently dropped from every
    // backup, which is a failure nobody notices until a restore.
    final AppDatabase db = testDatabase();
    final Set<String> expected = db.allTables
        .map((TableInfo<Table, dynamic> t) => t.actualTableName)
        .where((String n) => !_excludedWithReasons.containsKey(n))
        .toSet();

    expect(expected, hasLength(21));
    expect(
      _excludedWithReasons.keys.toSet(),
      kBackupExcludedTables,
      reason: 'the source and this test name the same four, with reasons',
    );

    final Directory dir = Directory.systemTemp.createTempSync('shed_backup');
    addTearDown(() => dir.deleteSync(recursive: true));

    final ExportArtifact artifact = await ExportRepository(
      db,
    ).writeBackup(envelope: _envelope(), outputDir: dir);

    final Map<String, Object?> file =
        jsonDecode(File(artifact.path).readAsStringSync()) as Map<String, Object?>;

    // IN BOTH DIRECTIONS. A superset is a table nobody meant to export; a subset
    // is a table a restore will not find.
    expect((file['tables']! as Map<String, Object?>).keys.toSet(), expected);

    // AND `counts` HAS THE SAME 21 KEYS OVER AN EMPTY DATABASE, zeros included.
    // `09 §5.2`: the check *"is per table and cannot be partial: a table absent
    // from `counts` is a table nothing verifies."* This is the case that catches
    // a `counts` map built by iterating rows instead of tables.
    final Map<String, Object?> counts = file['counts']! as Map<String, Object?>;
    expect(counts.keys.toSet(), expected);

    // EVERY COUNT EQUALS ITS TABLE'S LENGTH, which is the invariant a restore
    // actually verifies — and it holds for the empty tables too, which is the
    // half a `counts` map built by iterating ROWS silently omits.
    //
    // Not `every value is 0`: a fresh database is not empty. `testDatabase()`
    // runs the first-run seed, so `app_settings` has its one row and
    // `vocab_terms` has forty. The first draft asserted zeros and failed on the
    // seed — which is the seed doing its job.
    final Map<String, Object?> tables = file['tables']! as Map<String, Object?>;
    for (final String name in expected) {
      expect(counts[name], (tables[name]! as List<Object?>).length, reason: name);
    }
    expect(counts['app_settings'], 1, reason: 'the first-run row');
    expect(counts['lambs'], 0, reason: 'and an empty table is still counted');

    await db.close();
  });

  test('no row carries an id or a raw integer foreign key', () async {
    // Integer primary keys are RE-ISSUED on import (#32), so a file carrying one
    // carries a pointer that stops pointing. Every row-pointing column is
    // replaced by `<column>_uid`, resolved through a join.
    final AppDatabase db = testDatabase();
    final SeasonId season = await seedSeason(db);
    expect(season.value, isPositive);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    await seedLamb(db, lambing, ewe);

    final Directory dir = Directory.systemTemp.createTempSync('shed_backup');
    addTearDown(() => dir.deleteSync(recursive: true));

    final Map<String, Object?> tables =
        (jsonDecode(
                  File(
                    (await ExportRepository(
                      db,
                    ).writeBackup(envelope: _envelope(), outputDir: dir)).path,
                  ).readAsStringSync(),
                )
                as Map<String, Object?>)['tables']!
            as Map<String, Object?>;

    final Map<String, Object?> lamb =
        ((tables['lambs']! as List<Object?>).single as Map<String, Object?>);

    expect(lamb.containsKey('id'), isFalse);
    expect(lamb.containsKey('lambing'), isFalse, reason: 'the raw integer is gone');
    expect(lamb.containsKey('birth_dam'), isFalse);
    expect(lamb['lambing_uid'], isA<String>());
    expect(lamb['birth_dam_uid'], isA<String>());

    // `unknown_json` IS A CONTAINER, NOT A FACT, and is skipped here on purpose:
    // T03 splats its contents at the row's top level, and emitting it now would
    // let every byte-equality case pass while the format is wrong.
    expect(lamb.containsKey('unknown_json'), isFalse);

    // AND EVERY OTHER COLUMN IS EMITTED, `null` INCLUDED. An omitted key and an
    // explicit null mean the same thing to the importer, but only one of them
    // round-trips byte for byte (`09 §7.2` rule 7).
    expect(lamb.containsKey('tag'), isTrue);
    expect(lamb.containsKey('death_date'), isTrue);

    await db.close();
  });

  test('a vocabulary foreign key keeps its own name and its own value', () async {
    // `03 §5.12`: the key IS the identity — *"globally unique, list-prefixed,
    // ASCII, stable forever… never translated and never edited."* So it is
    // `"route": "rt_subcutaneous"`, never `"route_uid"`. The five vocabulary
    // columns are deliberately absent from `kBackupForeignKeys`.
    for (final String table in <String>[
      'lambings',
      'lambs',
      'treatments',
      'ewe_observations',
      'foster_events',
    ]) {
      final Map<String, String> fks = kBackupForeignKeys[table] ?? const <String, String>{};
      for (final String vocab in <String>[
        'presentation',
        'death_cause',
        'route',
        'kind',
        'method',
      ]) {
        expect(fks.containsKey(vocab), isFalse, reason: '$table.$vocab is a vocabulary key');
      }
    }
  });

  test('every declared foreign key names a column that exists', () async {
    // THE COMPLETENESS MECHANISM, and it exists because the first draft of
    // `kBackupForeignKeys` was written from memory: it gave `care_events` an
    // `ewe` column it does not have, and the SELECT failed at runtime with
    // `no such column: t.ewe`. A map of format facts has to be checkable against
    // the schema, or it is a map that is wrong in exactly one place.
    final AppDatabase db = testDatabase();
    final Map<String, Set<String>> columns = <String, Set<String>>{
      for (final TableInfo<Table, dynamic> t in db.allTables)
        t.actualTableName: t.$columns.map((GeneratedColumn<Object> c) => c.name).toSet(),
    };

    kBackupForeignKeys.forEach((String table, Map<String, String> fks) {
      expect(columns.keys, contains(table), reason: table);
      for (final MapEntry<String, String> fk in fks.entries) {
        expect(columns[table], contains(fk.key), reason: '$table.${fk.key}');
        expect(columns.keys, contains(fk.value), reason: 'points at ${fk.value}');
      }
    });

    // AND EVERY ORDER KEY NAMES A TABLE THAT IS EXPORTED.
    for (final String table in kBackupOrderKeys.keys) {
      expect(kBackupExcludedTables, isNot(contains(table)), reason: table);
      expect(columns.keys, contains(table), reason: table);
    }

    await db.close();
  });

  test('the backup file name carries the date AND the time', () async {
    // `09 §8.1`. The one all-numeric date this app writes, and it is deliberate:
    // a shepherd who exports before and after a night would otherwise overwrite
    // the morning's file. ISO-ordered so it is unambiguous, and a file name
    // rather than a sentence a human reads — so R60 stands.
    final AppDatabase db = testDatabase();
    final Directory dir = Directory.systemTemp.createTempSync('shed_backup');
    addTearDown(() => dir.deleteSync(recursive: true));

    final ExportArtifact a = await ExportRepository(
      db,
    ).writeBackup(envelope: _envelope(), outputDir: dir);

    expect(a.shareName, startsWith('shed-book-backup-'));
    expect(a.shareName, endsWith('.json'));
    expect(
      RegExp(r'^shed-book-backup-\d{4}-\d{2}-\d{2}-\d{4}\.json$').hasMatch(a.shareName),
      isTrue,
      reason: a.shareName,
    );
    expect(a.byteSize, isPositive);

    await db.close();
  });

  test('two exports of identical data are byte-identical and _disclaimer is the first key', () {
    // THE ANCHOR, and it has three halves that fail differently.
    final Map<String, Object?> tables = <String, Object?>{
      'ewes': <Object?>[
        <String, Object?>{'uid': 'b', 'tag': '412'},
      ],
      'lambs': const <Object?>[],
    };

    final Uint8List a = _file(tables);
    final Uint8List b = _file(tables);

    // ONE — byte for byte, through `orderedEquals`.
    expect(a, orderedEquals(b));

    final String text = utf8.decode(a);

    // TWO — `{` at index 0 and the §12.3 disclaimer's key at index 1. **No
    // byte-order mark**: that belongs to `csv_writer.dart` and nowhere else, and
    // a leading mark here makes `jsonDecode` throw or folds itself into the
    // first key — which is this one.
    expect(a.first, 0x7B, reason: '{');
    expect(text.indexOf('"_disclaimer"'), 1);

    // THREE — the value is the constant, character for character, read THROUGH
    // it rather than against a copy of its text.
    expect((jsonDecode(text) as Map<String, Object?>)['_disclaimer'], Disclaimers.exportFooter);
  });

  test('insertion order does not survive into the file', () {
    // The half of canonicality a single export cannot show. Two maps with the
    // same content and opposite insertion order must produce the same bytes —
    // otherwise the checksum depends on the order a `SELECT` happened to return
    // columns in, which is not a property SQLite promises.
    final Map<String, Object?> forwards = <String, Object?>{
      'a': 1,
      'b': <String, Object?>{'x': 1, 'y': 2},
    };
    final Map<String, Object?> backwards = <String, Object?>{
      'b': <String, Object?>{'y': 2, 'x': 1},
      'a': 1,
    };

    expect(canonicalJsonBytes(forwards), orderedEquals(canonicalJsonBytes(backwards)));
  });

  test('the sort is at every level, not only the top', () {
    // A one-level sort passes every other case in this file and fails first at
    // T03 — three commits later, with a much bigger diff to bisect. `09 §7.2`
    // rule 2: canonical order applies *at every level inside the `tables`
    // value*.
    final String nested = utf8.decode(
      canonicalJsonBytes(<String, Object?>{
        'rows': <Object?>[
          <String, Object?>{
            'zeta': 1,
            'alpha': 2,
            'mid': <String, Object?>{'z': 1, 'a': 2},
          },
        ],
      }),
    );

    expect(nested.indexOf('"alpha"'), lessThan(nested.indexOf('"zeta"')));
    expect(nested.indexOf('"a"'), lessThan(nested.indexOf('"z"')));
  });

  test('the sort is by code unit, and Z sorts before a', () {
    // NOT locale-aware and NOT case-folded. `SplayTreeMap`'s default comparator
    // is `Comparable.compare`, which for `String` is `compareTo`, which is
    // UTF-16 code-unit order — exactly what `09 §5.7` specifies. A case-folding
    // comparator would put `a` first and every file written before the fix would
    // carry a checksum nothing can reproduce.
    final String s = utf8.decode(canonicalJsonBytes(<String, Object?>{'a': 1, 'Z': 2}));
    expect(s.indexOf('"Z"'), lessThan(s.indexOf('"a"')));
  });

  test('the file is compact and ends in exactly one newline', () {
    // Not pretty-printed: indentation roughly doubles the bytes and the peak
    // heap at exactly the moment the 20 MB tripwire is about to bite. And the
    // `tables` value as it appears in the file **is** the canonical encoding,
    // byte for byte, so a shepherd with `jq` and `xxd` can reproduce the
    // checksum by hand.
    final String text = utf8.decode(_file(<String, Object?>{'ewes': const <Object?>[]}));

    expect(text.endsWith('}\n'), isTrue);
    expect(text.endsWith('}\n\n'), isFalse);
    expect(text, isNot(contains('\n  ')), reason: 'no indentation');
  });

  test('the thirteen header keys are in the order 09 §5.2 fixes', () {
    final String text = utf8.decode(_file(<String, Object?>{'ewes': const <Object?>[]}));

    const List<String> order = <String>[
      '_disclaimer',
      '_withdrawalNotice',
      'format',
      'formatVersion',
      'schema',
      'appVersion',
      'exportedAtUtc',
      'exportedAtOffsetMinutes',
      'exportedAtZoneAbbreviation',
      'checksum',
      'counts',
      'media',
      'tables',
    ];

    int previous = -1;
    for (final String key in order) {
      final int at = text.indexOf('"$key"');
      expect(at, isNot(-1), reason: key);
      expect(at, greaterThan(previous), reason: '$key is out of order');
      previous = at;
    }

    // `tables` IS LAST so the writer can stream it without buffering it twice,
    // and `_disclaimer` is first so a truncated file still carries §12.3.
    expect(order.last, 'tables');
  });

  test('the header carries both disclosures, referenced never re-typed', () {
    final Map<String, Object?> file =
        jsonDecode(utf8.decode(_file(<String, Object?>{'ewes': const <Object?>[]})))
            as Map<String, Object?>;

    expect(file['_disclaimer'], Disclaimers.exportFooter);
    expect(file['_withdrawalNotice'], Disclaimers.withdrawalCaveat);
  });

  test('format and formatVersion are frozen, and formatVersion is not schema', () {
    // They are both `1` on day one, which is exactly why merging them is
    // invisible until v2 — and by then every file ever written carries the
    // mistake (`09 §5.2`).
    final Map<String, Object?> file =
        jsonDecode(utf8.decode(_file(<String, Object?>{'ewes': const <Object?>[]})))
            as Map<String, Object?>;

    expect(file['format'], 'shed-book-backup');
    expect(file['formatVersion'], kBackupFormatVersion);
    expect(file['schema'], 1);

    // THE ASSERTION THAT ACTUALLY HOLDS THE PROPERTY. The first draft compared
    // the two values with `identical`, which is true for any two small ints in
    // Dart — it asserted nothing at all. Moving the schema alone is what shows
    // they are two fields rather than one written twice.
    final Map<String, Object?> v7 =
        jsonDecode(
              utf8.decode(
                Uint8List.fromList(<int>[
                  ...utf8.encode(
                    headerPrefixJson(
                      BackupHeader(
                        schema: 7,
                        appVersion: '1.0.0',
                        exportedAtUtc: '2026-07-27T21:04:05.006Z',
                        exportedAtOffsetMinutes: 60,
                        exportedAtZoneAbbreviation: 'BST',
                        counts: const <String, int>{},
                        media: const BackupMedia(included: false, count: 0, bytes: 0),
                      ),
                      'deadbeefdeadbeef',
                      _envelope(),
                    ),
                  ),
                  ...utf8.encode('{}}\n'),
                ]),
              ),
            )
            as Map<String, Object?>;

    expect(v7['schema'], 7);
    expect(
      v7['formatVersion'],
      1,
      reason: 'the header version did not follow the database version',
    );
  });

  test('v1 is records-only and the file says so', () {
    // Decision #85. `included: false` is not a placeholder for a feature — it is
    // the honest statement that photos and voice notes are NOT in this file, and
    // a restore that found `true` here would be a restore expecting bytes that
    // were never written.
    final Map<String, Object?> media =
        (jsonDecode(utf8.decode(_file(<String, Object?>{'ewes': const <Object?>[]})))
                as Map<String, Object?>)['media']!
            as Map<String, Object?>;

    expect(media['included'], isFalse);
  });

  test('the checksum covers the tables bytes and not the header', () {
    // It looks inconsistent and it is deliberate: the header carries
    // `exportedAtUtc`, so it legitimately differs between two exports of the
    // same database — covering it would make the checksum non-reproducible by
    // construction.
    final Map<String, Object?> tables = <String, Object?>{'ewes': const <Object?>[]};
    final String expected = fnv1a64Hex(canonicalJsonBytes(tables));

    final Map<String, Object?> file =
        jsonDecode(utf8.decode(_file(tables))) as Map<String, Object?>;

    expect(file['checksum'], expected);
  });

  test('the size tripwire is a number to measure against, not a limit', () {
    // It refuses nothing and must not: crossing 20 MB means *measure before
    // assuming it is still fine*. The fix, if it is ever needed, is a streaming
    // writer emitting one table at a time to the same sink — never an isolate,
    // because a drift connection cannot cross an isolate boundary (#125).
    expect(kBackupSizeTripwireBytes, 20 * 1024 * 1024);
  });

  test('backup_format.dart writes no byte-order mark and formats no number', () {
    // The BOM belongs to `csv_writer.dart` and to nothing else (`09 §2.4`), and
    // `export.intl_in_writer` will point at this file from N22 onward. The gate
    // is the build; this is the reason.
    final String source = File('lib/data/backup_format.dart').readAsStringSync();
    for (final String banned in <String>['0xEF', 'package:intl', 'toStringAsFixed']) {
      expect(source, isNot(contains(banned)), reason: banned);
    }
  });
}

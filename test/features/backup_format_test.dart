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

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/data/backup_format.dart';
import 'package:shed_book/data/export_limits.dart';
import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/domain/policy/export_envelope.dart';
import 'package:shed_book/domain/time/instant.dart';

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

void main() {
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

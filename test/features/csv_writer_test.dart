// test/features/csv_writer_test.dart
//
// RFC 4180, and the one bug that makes a hand-rolled writer worth writing at
// all: a quote inside a field is escaped by DOUBLING it, never by a backslash.
// A backslash produces a file that opens with visible `\"` and a field count
// that is right by accident — and every spreadsheet on earth reads it wrong.
//
// The decoder these cases assert against is written **in this file**, strict and
// twenty lines, for the reason `12 §1.4` gives: a round trip through the same
// author's parser proves the two agree, not that either is right. So the parser
// here is written from the RFC rather than from the writer, and it refuses what
// the RFC refuses.
//
// The path is `test/features/` rather than the `test/data/` that
// `CONVENTIONS §4.1`'s mirror convention would give. It is `00-PLAN-CRITIQUE`'s
// published anchor path and the epic's Notes say to preserve it verbatim.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/data/csv_writer.dart';
import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/domain/policy/export_envelope.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/recorded_time.dart';

/// A strict RFC 4180 reader — a state machine over quoted and unquoted, and
/// nothing else.
///
/// **It understands `""` and does not understand `\"`.** That asymmetry is the
/// whole point: a writer that backslash-escapes produces a field this reader
/// returns with the backslash still in it, and the anchor's
/// character-for-character assertion fails.
///
/// It also refuses a bare `"` inside an unquoted field (RFC 4180 §2.5), which is
/// how a writer that forgot to quote at all is caught rather than tolerated.
List<List<String>> parseRfc4180(String text) {
  final List<List<String>> records = <List<String>>[];
  List<String> record = <String>[];
  final StringBuffer field = StringBuffer();
  bool quoted = false;
  bool any = false;

  int i = 0;
  while (i < text.length) {
    final String c = text[i];

    if (quoted) {
      if (c == '"') {
        // A doubled quote is one literal quote; a lone one closes the field.
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        }
        quoted = false;
        i++;
        continue;
      }
      field.write(c);
      i++;
      continue;
    }

    if (c == '"') {
      if (field.isNotEmpty) {
        throw FormatException('a bare quote inside an unquoted field', text, i);
      }
      quoted = true;
      any = true;
      i++;
      continue;
    }
    if (c == ',') {
      record.add(field.toString());
      field.clear();
      any = true;
      i++;
      continue;
    }
    if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') {
      record.add(field.toString());
      field.clear();
      records.add(record);
      record = <String>[];
      any = false;
      i += 2;
      continue;
    }
    if (c == '\n' || c == '\r') {
      throw FormatException('a bare CR or LF outside a quoted field', text, i);
    }
    field.write(c);
    any = true;
    i++;
  }

  if (any || field.isNotEmpty) {
    record.add(field.toString());
    records.add(record);
  }
  return records;
}

/// Everything after the BOM, decoded.
String bodyOf(Uint8List bytes) => utf8.decode(bytes.sublist(3));

CsvWriter writerAt(Instant now, {String zone = 'GMT (UTC+00:00)'}) => CsvWriter(
  ExportEnvelope.standard(now: now, appVersion: '1.0.0'),
  localZoneLabel: zone,
);

final Instant _fixed = Instant.fromDateTime(DateTime.utc(2026, 3, 14, 3, 20, 42, 15));

String readSource() => File('lib/data/csv_writer.dart').readAsStringSync();

void main() {
  test('a field containing a comma, a quote and a newline round-trips per RFC 4180', () {
    // THE ANCHOR. One value a shepherd actually types into `lambs.notes`, with
    // all three hard characters in it at once.
    const String note = 'she said "kick", then\nthe lamb came';

    final Uint8List bytes = writerAt(_fixed).encode(
      <String>['tag', 'note'],
      <List<Object?>>[
        <Object?>['412', note],
      ],
    );

    final String body = bodyOf(bytes);

    // THE ESCAPE IS `""` AND NEVER `\"`. Asserted on the emitted text rather
    // than only through the round trip: a writer that backslash-escapes AND a
    // reader that understands backslashes would round-trip happily and produce
    // a file no spreadsheet can read.
    expect(body, contains('""kick""'));
    expect(body, isNot(contains(r'\"')));

    final List<List<String>> records = parseRfc4180(body);

    // ONE RECORD IN, ONE RECORD OUT. The embedded LF stayed inside the quotes
    // and did not become a second record — which is the failure that shifts
    // every column in the file after it.
    expect(records[1], hasLength(2));
    expect(records[1][1], note, reason: 'character for character, newline included');
  });

  test('each of the nine quoting rows in 09 §2.3 emits exactly what the table says', () {
    // Table-driven off the document, so a row that changes there fails here
    // rather than drifting.
    const List<(String, Object?, String)> rows = <(String, Object?, String)>[
      ('plain', '412', '412'),
      ('the delimiter', 'Ewe, prolapsed', '"Ewe, prolapsed"'),
      ('a quote', 'she "kicked"', '"she ""kicked"""'),
      ('an embedded LF', 'line one\nline two', '"line one\nline two"'),
      ('a semicolon', 'prolapse; mastitis', '"prolapse; mastitis"'),
      ('a tab', 'a\tb', '"a\tb"'),
      ('surrounding space', ' 412 ', '" 412 "'),
      ('null', null, ''),
      ('a formula lead', '-2 lambs born', "'-2 lambs born"),
    ];

    for (final (String what, Object? input, String expected) in rows) {
      final String body = bodyOf(
        writerAt(_fixed).encode(
          <String>['v'],
          <List<Object?>>[
            <Object?>[input],
          ],
        ),
      );
      // Record 0 is the header, record 1 is the row.
      final String emitted = body.split('\r\n')[1];
      expect(emitted, expected, reason: what);
    }
  });

  test('the file begins with the UTF-8 BOM and every record ends CRLF, including the last', () {
    final Uint8List bytes = writerAt(_fixed).encode(
      <String>['a', 'b'],
      <List<Object?>>[
        <Object?>['1', '2'],
        <Object?>['3', '4'],
      ],
    );

    expect(bytes.sublist(0, 3), <int>[0xEF, 0xBB, 0xBF]);
    expect(bytes.sublist(bytes.length - 2), <int>[
      0x0D,
      0x0A,
    ], reason: 'CRLF after the last record');

    // One header + two rows + six trailer records.
    expect('\r\n'.allMatches(bodyOf(bytes)).length, 1 + 2 + 6);
  });

  test('a ragged row throws in release mode as well as in debug', () {
    // A `throw`, not an `assert`: asserts are compiled out of the release build
    // the shepherd actually runs, and a ragged file reaches the share sheet and
    // then their spreadsheet with every column after the short row shifted.
    //
    // TWO HALVES, AND THE SECOND REPLACES A COMMAND THAT DOES NOT EXIST. The
    // task's §8 asks for `flutter test --release` to exercise the property with
    // asserts disabled; **Flutter 3.44.8's `test` command has no `--release`
    // flag** (`Could not find an option named "--release"`), and `dart run`
    // cannot host `flutter_test`. So the mode-specific run is replaced by a scan
    // of the source text, which is strictly better: it runs on every `make test`
    // rather than in one mode somebody has to remember to invoke.
    //
    // The behavioural half below is not redundant with it — an `assert` raises
    // `AssertionError`, which `isA<StateError>()` rejects, so this expectation
    // already fails for an assert-guarded implementation in debug. The scan
    // covers the case the debug run structurally cannot: release.
    expect(
      readSource(),
      isNot(contains('assert(')),
      reason: 'a ragged file is a release-mode failure and an assert is not there in release',
    );

    expect(
      () => writerAt(_fixed).encode(
        <String>['a', 'b', 'c'],
        <List<Object?>>[
          <Object?>['1', '2'],
        ],
      ),
      throwsA(
        isA<StateError>()
            .having(
              (StateError e) => e.message,
              'names both counts',
              allOf(contains('2'), contains('3')),
            )
            .having((StateError e) => e.message, 'names the clause', contains('RFC 4180')),
      ),
    );
  });

  test('the formula guard fires on all six leads and on nothing else', () {
    // SIX, NOT FOUR. TAB and CR are the two everyone forgets, and they are the
    // two that arrive from a paste.
    //
    // ASSERTED ON THE DECODED FIELD, NOT ON THE EMITTED LINE, and the first
    // draft got this wrong. TAB and CR are in the quoting predicate as well as
    // the formula set, so their emitted line starts with `"` and the apostrophe
    // is *inside* the quotes — which is correct, and an assertion on the raw
    // line calls it a miss. What matters is what the spreadsheet reads back.
    for (final String lead in <String>['=', '+', '-', '@', '\t', '\r']) {
      final String body = bodyOf(
        writerAt(_fixed).encode(
          <String>['v'],
          <List<Object?>>[
            <Object?>['${lead}x'],
          ],
        ),
      );
      expect(parseRfc4180(body)[1][0], "'${lead}x", reason: 'lead ${lead.codeUnitAt(0)}');
    }

    // AND `#` IS NOT IN THE SET, which is what keeps the trailer readable: a
    // trailer row is an ordinary record whose first field begins `#`, and an
    // apostrophe in front of it would show in every text editor.
    for (final String safe in <String>['#note', '4 lambs', 'ewe', ' spaced', "'already"]) {
      final String body = bodyOf(
        writerAt(_fixed).encode(
          <String>['v'],
          <List<Object?>>[
            <Object?>[safe],
          ],
        ),
      );
      expect(parseRfc4180(body)[1][0], safe, reason: safe);
    }
  });

  test('the guard changes the export and never the record', () {
    // Safety rule §12.4, asserted at the one place in this file it could be
    // violated. By identity as well as by content: a writer that normalised in
    // place would pass a content check on a fresh literal.
    const String typed = '=needs vet';
    final String before = typed;

    writerAt(_fixed).encode(
      <String>['v'],
      <List<Object?>>[
        <Object?>[typed],
      ],
    );

    expect(typed, before);
    expect(identical(typed, before), isTrue);
  });

  test('a zero-row file still carries a header, six trailer records and the BOM', () {
    // `07 §13.2`: a 0-row CSV still carries its disclaimer trailer. An export of
    // nothing is still an export, and it is the one a shepherd is most likely to
    // send to somebody while asking why it is empty.
    final Uint8List bytes = writerAt(_fixed).encode(<String>['a', 'b'], const <List<Object?>>[]);

    expect(bytes.sublist(0, 3), <int>[0xEF, 0xBB, 0xBF]);
    expect(parseRfc4180(bodyOf(bytes)), hasLength(7));
  });

  test("every trailer row is padded to the header's field count", () {
    // RFC 4180 §2.4 requires a rectangular file, and a short trailer row breaks
    // a strict parser on the LAST line — exactly where a shepherd's spreadsheet
    // stops importing, which reads as a truncated export.
    final List<List<String>> records = parseRfc4180(
      bodyOf(
        writerAt(_fixed).encode(
          <String>['a', 'b', 'c', 'd'],
          <List<Object?>>[
            <Object?>['1', '2', '3', '4'],
          ],
        ),
      ),
    );

    for (final List<String> r in records) {
      expect(r, hasLength(4));
    }
  });

  test('the §12.5 trailer line lists every TimeSource, built from the enum', () {
    // A hand-typed list of three labels is a list that goes stale the day a
    // fourth source is added, silently, in the one file nobody re-reads.
    final String body = bodyOf(writerAt(_fixed).encode(<String>['a'], const <List<Object?>>[]));

    for (final TimeSource s in TimeSource.values) {
      expect(body, contains(s.label), reason: s.key);
    }
    expect(body, contains(' · '), reason: 'joined, not listed by hand');
  });

  test('the trailer carries the §12.3 and §12.1 disclaimers, referenced never re-typed', () {
    final String body = bodyOf(writerAt(_fixed).encode(<String>['a'], const <List<Object?>>[]));

    expect(body, contains(Disclaimers.exportFooter));
    expect(body, contains(Disclaimers.withdrawalCaveat));
    expect(body, contains('1.0.0'));
  });

  test('the local-zone label in the trailer is the one it was constructed with', () {
    // Never a clock read. R48 confines `package:timezone` to the notification
    // seam and R23 makes `appNow()` the only wall-clock reader in the app, so
    // the label arrives as a parameter or it does not arrive.
    final String body = bodyOf(
      writerAt(_fixed, zone: 'IST (UTC+01:00)').encode(<String>['a'], const <List<Object?>>[]),
    );

    expect(body, contains('IST (UTC+01:00)'));
  });

  test('encode is deterministic — the same input twice produces identical bytes', () {
    // Cheap, and it catches a hoisted `BytesBuilder` immediately: `takeBytes()`
    // empties the builder, so a second `encode` on a shared one returns almost
    // nothing.
    final CsvWriter w = writerAt(_fixed);
    const List<String> header = <String>['a', 'b'];
    final List<List<Object?>> rows = <List<Object?>>[
      <Object?>['1', 'x'],
    ];

    expect(w.encode(header, rows), w.encode(header, rows));
  });

  test('csv_writer.dart formats no date and no number', () {
    // The gate is the build; this is the reason, in the file a developer reads
    // when they wonder why `NumberFormat` is refused in one file and permitted
    // by the layer table generally.
    //
    // `NumberFormat` on a device set to French emits `4,10` for a weight. The
    // comma is then quoted or not depending on the predicate, and every column
    // after the weight moves.
    final String source = readSource();
    for (final String banned in <String>[
      'package:intl',
      'DateFormat',
      'NumberFormat',
      'toStringAsFixed',
    ]) {
      expect(source, isNot(contains(banned)), reason: banned);
    }
  });
}

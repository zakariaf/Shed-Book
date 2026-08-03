// lib/data/csv_writer.dart
//
// RFC 4180 — https://www.rfc-editor.org/rfc/rfc4180
//
// HAND-ROLLED, AND THE QUOTING RULES ARE THE WHOLE JOB. `csv` 8.0.0 is rejected
// in decision-record §5.3 for a specific reason rather than a taste: an
// unverified uploader shipping a fresh breaking rewrite, for roughly fifty lines
// of behaviour the RFC specifies completely. Three of the properties this app
// needs are byte-level and no general-purpose package gives all three at once —
// the UTF-8 BOM, CRLF line endings, and a quoting predicate that also fires on
// `;` and TAB.
//
// **THIS FILE IS THE ONLY PRODUCER OF CSV BYTES IN THE APP**, held by the gate
// row `export.csv_bytes`. That is what makes the §12.3 trailer structural rather
// than habitual: a writer that cannot be bypassed is a writer whose footer
// cannot be forgotten. The trailer is appended by `encode` itself, not by its
// caller, and it is on a zero-row file too.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/domain/policy/export_envelope.dart';
import 'package:shed_book/domain/time/recorded_time.dart';

final class CsvWriter {
  /// The envelope is not optional and the disclaimer is not a parameter of it
  /// (`05 §7.4`). **A `CsvWriter` that cannot emit the footer cannot be
  /// constructed**, which is safety rule §12.3 at the unconstructible level.
  const CsvWriter(this.envelope, {required this.localZoneLabel});

  final ExportEnvelope envelope;

  /// e.g. `IST (UTC+01:00)`.
  ///
  /// **A PARAMETER, NEVER A CLOCK READ.** R48 confines `package:timezone` to the
  /// notification seam and R23 makes `appNow()` the only wall-clock reader in
  /// the app, so the label is derived from `envelope.generatedAt` by the caller
  /// — which is also what makes an export of a winter instant say `GMT` when it
  /// is run in summer.
  final String localZoneLabel;

  static const String _eol = '\r\n'; // RFC 4180 §2.1
  static const List<int> _bom = <int>[0xEF, 0xBB, 0xBF]; // UTF-8 BOM, for Excel

  /// `;` and TAB are in the set on purpose: quoting them is what makes the
  /// comma-delimited file survive a reopen in a semicolon-delimited European
  /// Excel. There is no `sep=;` line and no delimiter setting — decision #82
  /// rejects the first as Microsoft-proprietary and breaking of strict parsers,
  /// and the second is a second file format to test.
  static final RegExp _needsQuote = RegExp(r'[",\r\n;\t]');

  /// **SIX LEADS, NOT FOUR.** Excel, Numbers and Google Sheets evaluate a field
  /// beginning with any of these as a formula. The two everyone forgets — TAB
  /// and CR — are the two that arrive from a paste.
  ///
  /// `#` is deliberately absent: RFC 4180 has no comment syntax, so the trailer
  /// rows are ordinary records whose first field begins `#`. Put `#` in this set
  /// and every trailer row reads `'#` in a text editor.
  static final RegExp _formulaLead = RegExp(r'^[=+\-@\t\r]');

  /// One field, quoted per RFC 4180 §2.6 and escaped per §2.7.
  ///
  /// **No `DateTime` arm and no `double` arm, and that is a design decision.**
  /// Every value handed to the encoder is already a `String`, an `int` or
  /// `null`, because formatting is the caller's and a formatter hidden inside an
  /// encoder is a locale bug waiting for a Welsh name (`09 §2.5`). Adding a
  /// `DateTime` arm here is how a locale-aware number formatter eventually gets
  /// imported — and on a device set to French it emits a comma decimal, which is
  /// then quoted or not depending on the predicate, shifting every column after
  /// the weight.
  ///
  /// The two identifiers that would do it are not spelled here, and that is not
  /// fussiness: `csv_writer_test.dart` scans this file's source text for them,
  /// so a comment naming the thing it forbids fails the case that forbids it.
  /// It caught the first draft of this comment.
  String _field(Object? v) {
    if (v == null) {
      // EMPTY, never the string `null`, never `N/A`, never `-` — and `-` would
      // trip the formula guard, which is how you would find out.
      return '';
    }
    String s = v.toString();
    if (_formulaLead.hasMatch(s)) {
      s = "'$s";
    }
    // TWO JOBS, AND THE SECOND IS EASY TO DELETE WHILE "SIMPLIFYING":
    // `s.trim() == s` quotes surrounding whitespace, so `" 412 "` survives a
    // parser that would otherwise trim it into a different tag.
    if (!_needsQuote.hasMatch(s) && s.trim() == s) {
      return s;
    }
    return '"${s.replaceAll('"', '""')}"'; // RFC 4180 §2.7 — doubled, never `\"`
  }

  /// Bytes, not a `String`: the BOM is a byte-level concern and a `String`
  /// cannot carry it without lying about its own length.
  ///
  /// Throws a [StateError] naming both counts if any row's field count differs
  /// from the header's.
  Uint8List encode(List<String> header, Iterable<List<Object?>> rows) {
    // CONSTRUCTED HERE AND NEVER HOISTED TO A FIELD. `takeBytes()` empties the
    // builder and returns a view over its internal buffer, so a shared builder
    // makes the second `encode` return almost nothing — and the determinism
    // case is what catches it.
    final BytesBuilder b = BytesBuilder(copy: false)..add(_bom);
    void line(List<Object?> r) => b.add(utf8.encode(r.map(_field).join(',') + _eol));

    line(header);
    for (final List<Object?> r in rows) {
      // A REAL CHECK, NOT AN `assert`. Asserts are stripped in release, and a
      // ragged file is a release-mode failure: it reaches the share sheet, it
      // reaches the shepherd's spreadsheet, and every column after the short row
      // is shifted. One integer comparison per row is not a cost.
      if (r.length != header.length) {
        throw StateError(
          'ragged row: ${r.length} fields, expected ${header.length} (RFC 4180 §2.4)',
        );
      }
      line(r);
    }
    for (final String t in _trailer()) {
      // PADDED TO RECTANGULAR. RFC 4180 §2.4 requires every record to have the
      // same field count, and a short trailer row breaks a strict parser on the
      // LAST line — exactly where a shepherd's spreadsheet stops importing,
      // which reads as a truncated export.
      line(<Object?>[t, ...List<Object?>.filled(header.length - 1, null)]);
    }
    return b.takeBytes();
  }

  /// Seven records, on **every** CSV including a zero-row one (`07 §13.2`).
  ///
  /// Every string here is REFERENCED from [Disclaimers] and none is re-typed;
  /// `copy.disclaimer_retyped` fails the build if a second file spells one out.
  List<String> _trailer() => <String>[
    '# ${envelope.disclaimer}', // §12.3
    '# ${Disclaimers.withdrawalCaveat}', // §12.1
    // R79 / screen 11. Its own const rather than an amendment to the footer —
    // see `Disclaimers.strikeNotice` for why, and note that this row is why the
    // trailer is seven records and not six.
    '# ${Disclaimers.strikeNotice}',
    // BUILT FROM THE ENUM (§12.5). A fourth `TimeSource` changes this line with
    // no edit here; a hand-typed list of three would not.
    '# Times are exported in UTC. Each event carries its source: '
        '${TimeSource.values.map((TimeSource s) => s.label).join(' · ')}.',
    '# Local times in this file were rendered in $localZoneLabel at export. '
        'The UTC columns are exact.',
    // THE GUARD DECLARES ITSELF, in the file, in plain words — one of the three
    // reasons it is not a §12.4 violation. The other two: the record is
    // untouched, and the JSON backup never calls this class.
    "# Fields beginning = + - @ a tab or a carriage return are prefixed with ' "
        'in this file so a spreadsheet does not evaluate them. '
        'The stored record is unchanged.',
    '# Shed Book ${envelope.appVersion}.',
  ];
}

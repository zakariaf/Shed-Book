// lib/data/backup_format.dart
//
// THE JSON BACKUP ENVELOPE. `09 §5` owns every rule in this file, and the file
// is the product's whole recovery story: there is no cloud, so this is the only
// thing that survives a phone going into a water trough.
//
// **NO BYTE-ORDER MARK.** That belongs to `csv_writer.dart` and to nothing else
// (`09 §2.4`): a leading mark makes `jsonDecode` throw or folds itself into the
// first key — and the first key here is the §12.3 disclaimer.
//
// **NO LOCALE-AWARE FORMATTER.** `export.intl_in_writer` points at this file
// from N22 onward, and a decimal comma would shift the bytes the checksum
// covers. Every number written here is an integer.
//
// **P15 (decision record §7.0c): THE FORMAT SHIPS WHOLE IN `v1.0.0`** — all 21
// restorable tables, including the ones no `v1.0.0` screen reads and which will
// be empty. T03's forward-compatibility contract carries an unknown *column*
// through `unknown_json`; **it does not carry an unknown *table***. Ship it
// short and a `v1.0.0` backup restored into `v1.1.0` is a restore that has to
// invent a missing table, on the one code path where a bug loses five seasons.
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/domain/policy/export_envelope.dart';

/// The `format` value. **Frozen** — a restore reads it to decide whether the
/// file is ours at all, so changing it orphans every file ever written.
const String kBackupFormat = 'shed-book-backup';

/// The **header's** version, and it is not the database's.
///
/// They are both `1` on day one, which is exactly why merging them is invisible
/// until v2 — and by then every file ever written carries the mistake
/// (`09 §5.2`).
const int kBackupFormatVersion = 1;

/// `CONVENTIONS §2.8`, R65 — the `format` / `formatVersion` / `schema` /
/// `counts` / `checksum` block.
///
/// **It is never called "the envelope".** `ExportEnvelope` is the
/// disclaimer-bearing value in `lib/domain/policy/`, and *the envelope* is the
/// whole file. If a sentence here would read the same with two of the three
/// swapped, it is wrong.
final class BackupHeader {
  const BackupHeader({
    required this.schema,
    required this.appVersion,
    required this.exportedAtUtc,
    required this.exportedAtOffsetMinutes,
    required this.exportedAtZoneAbbreviation,
    required this.counts,
    required this.media,
    this.format = kBackupFormat,
    this.formatVersion = kBackupFormatVersion,
  });

  final String format;
  final int formatVersion;

  /// The database's `kSchemaVersion` **at export**. A restore refuses a file
  /// written by a higher schema, which is the one direction migrations cannot
  /// run.
  final int schema;

  final String appVersion;

  /// ISO-8601, milliseconds, trailing `Z`.
  final String exportedAtUtc;

  /// The offset **at the export instant**, never the offset now.
  ///
  /// Inside the ambiguous 01:00–01:59 hour the two answers differ by sixty
  /// minutes, and this field is the only record of which side of the boundary
  /// the export happened on.
  final int exportedAtOffsetMinutes;

  /// Context only — nothing reads it back on import.
  ///
  /// It comes from `DateTime.timeZoneName`, and `09 §10` item 6 records that
  /// this returns an abbreviation on some platforms and a full name on others.
  /// That is a known, accepted looseness in a context-only field; do not "fix"
  /// it by pulling in `package:timezone`, which R48 confines to the notification
  /// seam.
  final String exportedAtZoneAbbreviation;

  /// One entry per key in `tables` — **21, zeros included**. A table with no
  /// rows is a fact; a table with no entry is a file somebody has to guess
  /// about.
  final Map<String, int> counts;

  final BackupMedia media;
}

/// v1 is **records-only** (#85).
///
/// [included] is `false` and it is not a placeholder for a feature: it is the
/// honest statement that photos and voice notes are not in this file. A restore
/// that found `true` would be a restore expecting bytes nobody wrote.
final class BackupMedia {
  const BackupMedia({required this.included, required this.count, required this.bytes});

  final bool included;
  final int count;
  final int bytes;
}

/// The canonical encoding: object keys sorted ascending by code unit, **at every
/// level**, no insignificant whitespace, integers only.
///
/// This is the only encode of `tables` in the app, and the checksum covers
/// exactly these bytes (`09 §5.7`).
///
/// **`jsonEncode` does not sort keys and no flag makes it**, so the sorted
/// structure is built here. `SplayTreeMap`'s default comparator is
/// `Comparable.compare`, which for `String` is `compareTo`, which is UTF-16
/// code-unit order — exactly what `09 §5.7` specifies. Not locale-aware and not
/// case-folded: `Z` sorts before `a`, and a case-folding comparator would make
/// every file written before the fix carry a checksum nothing can reproduce.
///
/// **Recursive, and the recursion is the load-bearing half.** A one-level sort
/// passes every case a first commit writes and fails first three commits later.
Uint8List canonicalJsonBytes(Object? value) =>
    Uint8List.fromList(utf8.encode(jsonEncode(_canonical(value))));

Object? _canonical(Object? value) => switch (value) {
  final Map<String, Object?> m => SplayTreeMap<String, Object?>.of(<String, Object?>{
    for (final MapEntry<String, Object?> e in m.entries) e.key: _canonical(e.value),
  }),
  // A LIST'S ORDER IS DATA AND IS NEVER SORTED. Row order is what a restore
  // writes back, and re-ordering rows would make the file disagree with the
  // database it came from.
  final List<Object?> l => <Object?>[for (final Object? e in l) _canonical(e)],
  _ => value,
};

/// `{"_disclaimer":…,"tables":` — the fixed-order prefix, ending in the open key
/// with **no value and the object still open**. The caller appends the canonical
/// bytes and then `}\n`.
///
/// **THE ENVELOPE IS A REQUIRED PARAMETER, AND THAT IS A DELIBERATE DIVERGENCE
/// FROM `09 §5.7`**, whose illustrative call takes two arguments. With it here,
/// no call path can produce a header prefix without the §12.3 string, and
/// `ExportEnvelope`'s private generative constructor means no caller can pass a
/// hollow one — §12.3 at the *unconstructible* level rather than by a reviewer
/// noticing. Copying the strings onto [BackupHeader] would make a
/// disclaimer-free header constructible and put a second copy of the string one
/// refactor away from `copy.disclaimer_retyped`. §5.7's snippet is an
/// illustration of the *write order*, which is unchanged.
///
/// **Only the `tables` value is canonical; this header is hand-ordered and
/// outside the checksum.** That looks inconsistent and it is deliberate: the
/// header carries [BackupHeader.exportedAtUtc], so it legitimately differs
/// between two exports of the same database, and covering it would make the
/// checksum non-reproducible by construction.
String headerPrefixJson(BackupHeader header, String checksumHex, ExportEnvelope envelope) {
  // INSERTION ORDER IS THE CONTRACT HERE, and a Dart map literal preserves it —
  // `09 §5.2`'s thirteen keys, in the order they are written. `_disclaimer`
  // first so a truncated file still carries §12.3; `tables` last so the writer
  // can stream it without buffering it twice.
  final Map<String, Object?> head = <String, Object?>{
    // REFERENCED, NEVER RE-TYPED (#62). `copy.disclaimer_retyped` fails the
    // build if a second file spells either of these out.
    '_disclaimer': envelope.disclaimer,
    '_withdrawalNotice': Disclaimers.withdrawalCaveat,
    'format': header.format,
    'formatVersion': header.formatVersion,
    'schema': header.schema,
    'appVersion': header.appVersion,
    'exportedAtUtc': header.exportedAtUtc,
    'exportedAtOffsetMinutes': header.exportedAtOffsetMinutes,
    'exportedAtZoneAbbreviation': header.exportedAtZoneAbbreviation,
    'checksum': checksumHex,
    'counts': header.counts,
    'media': <String, Object?>{
      'included': header.media.included,
      'count': header.media.count,
      'bytes': header.media.bytes,
    },
  };

  final String encoded = jsonEncode(head);
  // ASSERTED, NOT TRUSTED. A silent mis-slice produces valid JSON with the
  // §12.3 disclaimer nested inside the wrong object — a file that looks right
  // to every reader except the one that matters.
  if (!encoded.endsWith('}')) {
    throw StateError('header prefix did not end in } — refusing to slice');
  }
  return '${encoded.substring(0, encoded.length - 1)},"tables":';
}

/// FNV-1a, 64-bit, lower-case hex. **T04 owns the body**; the signature is here
/// so this task's writer compiles against the real one rather than against a
/// placeholder that later changes shape.
String fnv1a64Hex(List<int> bytes) {
  // 64-bit arithmetic in Dart is exact on the VM and on AOT; `int` is 64-bit
  // there and wraps on overflow, which is what FNV wants.
  int hash = 0xcbf29ce484222325;
  for (final int b in bytes) {
    hash ^= b & 0xff;
    hash *= 0x100000001b3;
  }
  // `toRadixString` on a negative int prints a sign, so the value is read as
  // unsigned through its two 32-bit halves.
  final int high = (hash >> 32) & 0xffffffff;
  final int low = hash & 0xffffffff;
  return high.toRadixString(16).padLeft(8, '0') + low.toRadixString(16).padLeft(8, '0');
}

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

import 'package:shed_book/core/db/database.dart' show kSchemaVersion;
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
    // AN OBJECT, NOT A BARE STRING. The algorithm travels with the value so a
    // reader knows which arithmetic to run — and so a second algorithm, if one
    // is ever needed, is a new value rather than a silent reinterpretation of
    // this one.
    'checksum': <String, Object?>{'algorithm': kBackupChecksumAlgorithm, 'value': checksumHex},
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

/// The algorithm's name as it appears in the file. Frozen: a restore reads it
/// to know which arithmetic to run, and a second algorithm would be a second
/// value this one cannot recompute.
const String kBackupChecksumAlgorithm = 'fnv1a64';

const int _fnvOffsetBasis = 0xcbf29ce484222325; // 14695981039346656037
const int _fnvPrime = 0x100000001b3; // 1099511628211

/// FNV-1a, 64-bit, lower-case hex. Fifteen lines, no dependency, deterministic.
///
/// **NOT `package:crypto`.** It is in the lockfile because `pdf` declares it,
/// and decision-record §5.1 does not list it as a direct dependency (`09 §5.7`).
/// Reaching for it here would add a direct edge for fifteen lines of arithmetic.
///
/// **AND IT IS NOT A SECURITY FUNCTION.** FNV-1a detects a truncated download, a
/// half-written file and a corrupted card. It detects nothing an author intended,
/// and the copy that describes it says so — `offline_wording_test.dart` refuses
/// six words in this file and in every message that talks about it.
String fnv1a64Hex(List<int> bytes) {
  int hash = _fnvOffsetBasis;
  for (final int byte in bytes) {
    hash ^= byte;
    hash *= _fnvPrime; // wraps mod 2^64 on the Dart VM — that IS the algorithm
  }
  return _hex64(hash);
}

/// A Dart `int` is a **signed** 64-bit value, so `hash.toRadixString(16)` prints
/// a minus sign for half of all inputs — and `toUnsigned(64)` is a no-op at
/// width 64, so it does not help. Split it into two 32-bit halves and pad each.
String _hex64(int v) =>
    ((v >> 32) & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0') +
    (v & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');

/// What checking a file's integrity produced.
///
/// **Two independent comparisons, in one place because they are one decision:**
/// the checksum over the canonical `tables` bytes, and `counts` per table against
/// the number of rows actually parsed. N23's importer runs the count comparison a
/// second time, against the rows actually *inserted* — the two catch different
/// failures, and neither substitutes for the other.
sealed class BackupIntegrityOutcome {
  const BackupIntegrityOutcome();
}

final class BackupIntact extends BackupIntegrityOutcome {
  const BackupIntact();
}

final class BackupIncomplete extends BackupIntegrityOutcome {
  const BackupIncomplete({this.table, this.expected, this.parsed});

  /// `null` when it is the checksum that disagreed rather than a count.
  final String? table;
  final int? expected;
  final int? parsed;
}

BackupIntegrityOutcome checkBackupIntegrity({
  required BackupHeader header,
  required String checksumHex,
  required Uint8List canonicalTablesBytes,
  required Map<String, int> parsedCounts,
}) {
  if (fnv1a64Hex(canonicalTablesBytes) != checksumHex) {
    return const BackupIncomplete();
  }

  // PER TABLE, AND IT CANNOT BE PARTIAL (`09 §5.2`). A table absent from
  // `counts` is a table nothing verifies, so a missing key is a mismatch rather
  // than a skip.
  for (final MapEntry<String, int> e in header.counts.entries) {
    final int parsed = parsedCounts[e.key] ?? -1;
    if (parsed != e.value) {
      return BackupIncomplete(table: e.key, expected: e.value, parsed: parsed);
    }
  }
  return const BackupIntact();
}

/// The four tables that are **not** in a backup, each with its reason here.
///
/// `09 §5.4`'s rule is one sentence: **if you add a table it is exported unless
/// you write down why not, in the same commit.** A file listing four names and
/// no reasons is a file the fifth exclusion joins silently.
const Set<String> kBackupExcludedTables = <String>{
  // Never exported and ignored on import (#88). Restoring your neighbour's
  // backup must not unlock your app — and the entitlement is a fact about a
  // purchase, not about a flock.
  'entitlements',
  // A rebuildable cache (`03 §5.13`). Its writers maintain it inside the writes
  // that invalidate it, so a restore that carried it would carry a snapshot of
  // counts that the restored rows may not agree with.
  'ewe_summaries',
  // Derived — refilled by the source-table triggers as the rows land.
  'search_docs',
  // Derived — the FTS5 index over `search_docs`, rebuilt after the rows land.
  'search_fts',
};

/// The `ORDER BY` for each table, so two exports of one database agree.
///
/// **`ORDER BY id` IS THE BUG THIS WHOLE MAP EXISTS TO AVOID.** Integer primary
/// keys are re-issued on import (#32), so an id-ordered export makes the *second*
/// export a permutation of the first — and byte equality then fails somewhere in
/// the middle of a 40,000-row file, with a diff nobody can read.
///
/// Sixteen tables carry `uid` and order by it, so they are not listed. These five
/// do not (`09 §5.3`), and each orders by the natural key that stands in for it —
/// **resolved to the PARENT'S uid, never to the local integer**, which means a
/// join. `ORDER BY ewe` on `ewe_touches` compiles, runs, and is stable on the
/// exporting phone; it is a different order after a restore.
///
/// **This rule is about the backup only.** The three CSVs order by the keys
/// `09 §3` names, because a CSV is read by a human in the order a shepherd thinks
/// in, and no CSV is ever re-imported.
const Map<String, List<String>> kBackupOrderKeys = <String, List<String>>{
  'app_settings': <String>[], // exactly one row
  'ewe_touches': <String>['ewe_uid'],
  'pen_occupancy_lambs': <String>['occupancy_uid', 'lamb_uid'],
  'reminder_rules': <String>['kind'], // a stored key
  'terminology_overrides': <String>['key'],
};

/// Every foreign key that points at a **row**, per table: the SQLite column name
/// mapped to the table it points at.
///
/// The emitted key is the column name with `_uid` appended and the value is the
/// parent row's uid (#32). The raw integer is never written: it is re-issued on
/// import, so a file carrying it carries a pointer that stops pointing.
///
/// **THE FIVE VOCABULARY FOREIGN KEYS ARE DELIBERATELY ABSENT.**
/// `lambings.presentation`, `lambs.death_cause`, `treatments.route`,
/// `ewe_observations.kind` and `foster_events.method` point at `vocab_terms.key`,
/// and the key *is* the identity — `03 §5.12`: *"globally unique, list-prefixed,
/// ASCII, stable forever… never translated and never edited."* So the column
/// keeps its own name and its own value: `"route": "rt_subcutaneous"`, never
/// `"route_uid"`.
const Map<String, Map<String, String>> kBackupForeignKeys = <String, Map<String, String>>{
  'app_settings': <String, String>{
    'current_season': 'seasons',
    'export_prompt_dismissed_for_season': 'seasons',
  },
  // `care_events` has NO `ewe` column — the first draft of this map guessed one
  // and the SELECT failed with `no such column: t.ewe`. That is why
  // `backup_format_test.dart` asserts every declared column exists on its table:
  // a map written from memory is a map that is wrong in exactly one place.
  'care_events': <String, String>{'season': 'seasons', 'lambing': 'lambings', 'lamb': 'lambs'},
  'ewe_observations': <String, String>{'ewe': 'ewes', 'season': 'seasons', 'lambing': 'lambings'},
  'ewe_seasons': <String, String>{'season': 'seasons', 'ewe': 'ewes'},
  'ewe_touches': <String, String>{'ewe': 'ewes'},
  'foster_events': <String, String>{'lamb': 'lambs', 'season': 'seasons', 'rearing_dam': 'ewes'},
  'lambings': <String, String>{'season': 'seasons', 'ewe': 'ewes'},
  'lambs': <String, String>{'lambing': 'lambings', 'birth_dam': 'ewes', 'became_ewe': 'ewes'},
  'media_assets': <String, String>{'ewe': 'ewes', 'lamb': 'lambs', 'lambing': 'lambings'},
  'notes': <String, String>{
    'ewe': 'ewes',
    'lamb': 'lambs',
    'lambing': 'lambings',
    'season': 'seasons',
  },
  'pen_occupancies': <String, String>{'pen': 'pens', 'ewe': 'ewes', 'season': 'seasons'},
  'pen_occupancy_lambs': <String, String>{'occupancy': 'pen_occupancies', 'lamb': 'lambs'},
  'reminders': <String, String>{
    'ewe': 'ewes',
    'lamb': 'lambs',
    'lambing': 'lambings',
    'treatment': 'treatments',
    'season': 'seasons',
  },
  'treatment_withdrawals': <String, String>{'treatment': 'treatments'},
  'treatments': <String, String>{'season': 'seasons', 'ewe': 'ewes', 'lamb': 'lambs'},
};

/// A container, not a fact (`09 §5.3`) — and it is **never emitted as a column**.
///
/// T03 splats its contents at the row's top level. Emitting it here "for now"
/// would make every byte-equality case pass while the format is wrong.
const String kUnknownJsonColumn = 'unknown_json';

/// The integer primary key, dropped from every emitted row: it is re-issued on
/// import, so writing it writes a number that means something different on the
/// next phone.
const String kRowIdColumn = 'id';

// ---------------------------------------------------------------------------
// FORWARD COMPATIBILITY (`09 §5.3`, §5.5, §7.2 rule 8).
//
// A shepherd who installs `v1.1.0` on a new phone and restores a `v1.0.0` file
// must lose nothing — and the shepherd who goes the other way must lose nothing
// either. A column this build has never heard of rides through in
// `unknown_json` and comes back out at the row's top level, unchanged.
//
// **This carries an unknown COLUMN. It does not carry an unknown TABLE** — which
// is why P15 requires the format to ship whole in `v1.0.0`, all 21 tables, even
// the empty ones.
// ---------------------------------------------------------------------------

/// What reading a file's header produced.
///
/// **An outcome rather than an exception** (`01 §5`): a refusal is a value the
/// restore screen renders. `ShedFailure` is not the type for it either — that is
/// for a database the app could not read, and this is a file it read perfectly
/// well and declined to act on.
sealed class BackupHeaderOutcome {
  const BackupHeaderOutcome();
}

final class BackupHeaderAccepted extends BackupHeaderOutcome {
  const BackupHeaderAccepted(this.header);
  final BackupHeader header;
}

final class BackupRefused extends BackupHeaderOutcome {
  const BackupRefused(this.reason, {this.foundFormatVersion, this.foundSchema, this.foundKind});

  final BackupRefusalReason reason;

  /// What the first bytes said the file was. **Both kinds are carried** — found
  /// and expected — because a refusal that names neither is a refusal a shepherd
  /// cannot act on.
  final BackupFileKind? foundKind;

  BackupFileKind get expectedKind => BackupFileKind.shedBookBackup;

  /// What the file says.
  final int? foundFormatVersion;
  final int? foundSchema;

  /// What this build reads. **Both numbers are shown**, so a shepherd on the
  /// phone to a friend can say which build wrote the file.
  int get readsFormatVersion => kBackupFormatVersion;
  int get readsSchema => kSchemaVersion;
}

/// **`BackupRefusalReason`, not `RefusalReason`** — that name is already
/// `lib/domain/free_tier.dart`'s, and two enums with one name is the kind of
/// collision that is resolved by an import alias and then forgotten.
enum BackupRefusalReason {
  /// `format` is absent or is not the frozen string. *This is not a Shed Book
  /// backup* and *this is one and it is damaged* send a shepherd to two
  /// different next steps, so they are two reasons.
  notShedBookFormat,

  /// `09 §5.5` row 1.
  newerFormatVersion,

  /// `09 §5.5` row 2.
  newerSchema,

  /// Ours, and a required key is missing or the wrong type.
  malformedHeader,

  // -- the three by-name wrong-kind reasons (`04 §7.2` step 2) ---------------
  //
  // Three reasons rather than one, because each sends a shepherd somewhere
  // different: find the `.json`, use the developer tool, or pick a different
  // file entirely. *"Invalid file"* at 02:00 is not an instruction.
  /// A photo archive. Media is not part of a v1 backup (#85), so one is never
  /// restorable.
  pickedZipArchive,

  /// The `VACUUM INTO` snapshot from Settings → Diagnostics — deliberately not
  /// an in-app restore path (`04 §2.8`). `tool/snapshot_to_backup.dart` converts
  /// it, and that is a developer tool rather than a code path on a phone.
  pickedDatabaseCopy,

  /// The catch-all for an unrecognised first byte — most often a photo somebody
  /// renamed.
  notABackupFile,
}

/// What the first bytes of a picked file say it is.
enum BackupFileKind {
  /// First non-whitespace byte is `{`.
  shedBookBackup,

  /// `50 4B 03 04`.
  zipArchive,

  /// `SQLite format 3\0` — sixteen bytes.
  sqliteDatabase,

  /// Everything else, including a renamed JPEG.
  unrecognised,
}

/// **PURE, AND NO `dart:io` ANYWHERE NEAR IT.** The whole magic-byte decision is
/// testable against a byte list, which is what lets the *ordering* be proved
/// rather than asserted: the prelude sniffs before it parses, and a test can show
/// it by handing over a file whose tail would throw if anything read it.
///
/// **THE PICKER IS NEVER TRUSTED ON ITS OWN.** Android MIME filtering is
/// unreliable enough that the type group has to accept `application/octet-stream`
/// — so the file that arrives may be anything at all, and these bytes are the
/// only thing that decides.
BackupFileKind sniffBackupFile(List<int> firstBytes) {
  if (_startsWith(firstBytes, const <int>[0x50, 0x4B, 0x03, 0x04])) {
    return BackupFileKind.zipArchive;
  }
  if (_startsWith(firstBytes, 'SQLite format 3'.codeUnits)) {
    return BackupFileKind.sqliteDatabase;
  }

  // LEADING WHITESPACE IS TOLERATED. The app never writes it, but a shepherd who
  // has opened the file in an editor and saved it might — and refusing their own
  // backup over a newline is the worst false negative available on this path.
  for (final int b in firstBytes) {
    if (b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D) {
      continue;
    }
    return b == 0x7B ? BackupFileKind.shedBookBackup : BackupFileKind.unrecognised;
  }
  return BackupFileKind.unrecognised;
}

bool _startsWith(List<int> bytes, List<int> prefix) {
  if (bytes.length < prefix.length) {
    return false;
  }
  for (int i = 0; i < prefix.length; i++) {
    if (bytes[i] != prefix[i]) {
      return false;
    }
  }
  return true;
}

/// Validates the thirteen header keys and nothing else.
///
/// It touches no file and no database, so it is unit-testable against a decoded
/// map — which is why the restore path can be reasoned about before any of it
/// exists.
BackupHeaderOutcome readBackupHeader(Map<String, Object?> decoded) {
  if (decoded['format'] != kBackupFormat) {
    return const BackupRefused(BackupRefusalReason.notShedBookFormat);
  }

  final Object? formatVersion = decoded['formatVersion'];
  final Object? schema = decoded['schema'];
  if (formatVersion is! int || schema is! int) {
    return const BackupRefused(BackupRefusalReason.malformedHeader);
  }

  // THE APP READS DOWN, NEVER UP. Guessing at a newer schema is §12.4 applied to
  // restore, and a partial import destroys records rather than declining to
  // touch them. Do not soften this to *may not be compatible*.
  if (formatVersion > kBackupFormatVersion) {
    return BackupRefused(
      BackupRefusalReason.newerFormatVersion,
      foundFormatVersion: formatVersion,
      foundSchema: schema,
    );
  }
  if (schema > kSchemaVersion) {
    return BackupRefused(
      BackupRefusalReason.newerSchema,
      foundFormatVersion: formatVersion,
      foundSchema: schema,
    );
  }

  return BackupHeaderAccepted(
    BackupHeader(
      schema: schema,
      appVersion: decoded['appVersion'] as String? ?? '',
      exportedAtUtc: decoded['exportedAtUtc'] as String? ?? '',
      exportedAtOffsetMinutes: decoded['exportedAtOffsetMinutes'] as int? ?? 0,
      exportedAtZoneAbbreviation: decoded['exportedAtZoneAbbreviation'] as String? ?? '',
      counts: const <String, int>{},
      media: const BackupMedia(included: false, count: 0, bytes: 0),
      formatVersion: formatVersion,
    ),
  );
}

/// Merges a stored row's `unknown_json` into the row **before** the keys are
/// sorted, and never emits the column itself.
///
/// **THE ORDER IS THE WHOLE THING.** Merging after the sort produces a file that
/// decodes correctly, reads correctly and looks right in `jq` — and whose key
/// order is wrong, so the second export is not byte-identical to the first. Only
/// T01's byte-equality assertion catches it.
///
/// The container is never emitted under its own name: doing that as well writes
/// every preserved field twice, and the next export nests it again, one level
/// deeper each time (`09 §9`).
Map<String, Object?> splatUnknownJson(Map<String, Object?> row) {
  final Object? container = row[kUnknownJsonColumn];
  final Map<String, Object?> out = <String, Object?>{
    for (final MapEntry<String, Object?> e in row.entries)
      if (e.key != kUnknownJsonColumn) e.key: e.value,
  };

  if (container is! String || container.isEmpty) {
    return out;
  }

  final Object? parsed = jsonDecode(container);
  if (parsed is! Map<String, Object?>) {
    return out;
  }

  for (final MapEntry<String, Object?> e in parsed.entries) {
    // **THE LIVE COLUMN WINS, AND THE DECISION IS IN CODE.** In theory this
    // cannot happen — if the column exists today the key is not unknown. In
    // practice it happens the moment somebody hand-edits a backup, or a column
    // is added and an older file is replayed through a build that has since
    // gained it. Letting map-merge order settle it would settle it silently, and
    // differently depending on which way the merge was written.
    if (out.containsKey(e.key)) {
      continue;
    }
    // PASSED THROUGH, NEVER RE-PARSED. A preserved key whose value looks like an
    // instant is a *string* to this build; the build that wrote it knows what it
    // means and this one does not.
    out[e.key] = e.value;
  }
  return out;
}

/// The inverse, for N23's importer: every key the target table does not have is
/// lifted out into the container.
///
/// Returns `null` for a row with nothing unknown — **never `'{}'`**, because
/// `'{}'` and `NULL` are different bytes on the next export, and almost every
/// row has nothing to preserve.
({Map<String, Object?> row, String? unknownJson}) captureUnknownColumns(
  Map<String, Object?> incoming,
  Set<String> knownColumns,
) {
  final Map<String, Object?> row = <String, Object?>{};
  final Map<String, Object?> unknown = <String, Object?>{};

  for (final MapEntry<String, Object?> e in incoming.entries) {
    if (knownColumns.contains(e.key)) {
      row[e.key] = e.value;
    } else {
      unknown[e.key] = e.value;
    }
  }

  // A JSON **object** or `NULL`. The column's
  // `CHECK (unknown_json IS NULL OR json_valid(unknown_json))` throws a
  // `SqliteException` on a bare string, an empty string or an array — from the
  // importer, at the one moment nothing may throw.
  return (row: row, unknownJson: unknown.isEmpty ? null : jsonEncode(unknown));
}

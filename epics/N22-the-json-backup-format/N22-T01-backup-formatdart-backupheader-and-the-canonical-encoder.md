# N22-T01 — `backup_format.dart` — `BackupHeader` and the canonical encoder

| | |
|---|---|
| **Epic** | [N22 — The JSON backup format](epic.md) · `00-README` §9 step 8 (2 of 3) |
| **Task** | 1 of 5 |
| **Depends on** | N21-T08 |
| **Commit** | one commit · `feat(backup): the header and the canonical encoder` |

## 1. Why this task exists

The header, the canonical encoder — stable key order, stable number formatting, so two
exports of the same data are byte-identical and the round-trip property in N23-T07 can be an equality
— and `_disclaimer` as the **first key** in the file, so it is the first thing anyone opening it in a
text editor reads.

Byte equality is not tidiness. It is the only form of the round-trip claim a test can hold without a
hand-written comparator, and a hand-written comparator over 21 tables is a second implementation of the
format that will drift from the first. Get the encoder deterministic here and N23-T07 is four lines; get
it approximately deterministic and N23-T07 becomes a permanent maintenance surface that passes for the
wrong reason.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/09-export-formats.md` | §5.1 (three things, three words — envelope vs `BackupHeader` vs `ExportEnvelope`) · §5.2 (the thirteen header keys, verbatim and in order) · §5.3 (header keys are `camelCase`; keys inside `tables` are SQLite column names) · §5.7 (the canonical rule, and the writer that encodes `tables` **once**) · §2.4 (the byte-order mark is CSV-only) · §8.1 (the share name) · §9 (`export.intl_in_writer`) | the file, the type, the key order, the encoding |
| `docs/engineering/04-migrations-media-backup-restore.md` | §6.2 (the header block — its `"notice"` spelling is stale; 09 §1.3 replaces it with `_disclaimer`, **first**) · §6.3 (the field rules) · §6.8 (the 20 MB tripwire) | the header's own document |
| `docs/engineering/CONVENTIONS.md` | §1 (`lib/data/` is flat, R18) · §2.8 (`BackupHeader` — *"the `format`/`formatVersion`/`schema`/`counts`/`checksum` block. **Not** `ExportEnvelope`"*) · §2.14 (`Disclaimers`) · §4.2 (class and type naming) · §5.2 · R65 | **BINDING** on the type name and on what it may never be called |
| `docs/engineering/05-domain-correctness.md` | §7.4 (`Disclaimers` and `ExportEnvelope`; the §12.3 string is placed as a top-level `_disclaimer` key and the golden test is written against it) | why the disclaimer is first, and why it is not a parameter |
| `CLAUDE.md` | the offline-purity section | the words that may never be used about the checksum |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-export-and-restore` | the format, the header and the canonical encoding |
| `shed-safety-rules` | the disclaimer's position is a §12.3 decision |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/backup_format_test.dart`
- **Test** — `'two exports of identical data are byte-identical and _disclaimer is the first key'`
- **Why it is red today** — nothing defines the format, so two exports of the same data would differ by key order and the round-trip equality in N23-T07 could never be written.

```bash
fvm flutter test test/features/backup_format_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion with values, not shape. Encode the same `tables` map twice and assert the two
`Uint8List`s are identical with `orderedEquals` — never `equals` over a decoded structure, which is the
comparison that passes while the bytes differ. Then assert `utf8.decode(bytes).indexOf('"_disclaimer"')`
is exactly **1**: index 0 is `{`, and there is no byte-order mark in front of it. Then assert the
disclaimer's value equals `Disclaimers.exportFooter` character for character. Finally build the same map
with its keys inserted in reverse and assert the bytes are unchanged — insertion order must not survive
into the file.

**Green.** The minimum code that passes, and nothing beyond it — the header, the encoder, and a byte-equality property.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema, no domain, no wiring, no controller, no UI, no ARB.** This task stores nothing and adds no
user-facing string — say so in the commit message, per §8's instruction. `unknown_json` already exists on
all 21 restorable tables (N07-T06) and the disclaimer already exists as a `const` on `Disclaimers`. The
whole task is two files in `lib/data/` and one test.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/backup_format.dart` | **New.** `BackupHeader`, `BackupMedia`, `canonicalJsonBytes`, `headerPrefixJson`, `fnv1a64Hex`'s declaration site (its body is T04's) and the two format constants. 09 §1.2 places this file explicitly, because `CONVENTIONS` §1 does not list it |
| 2 | `lib/data/export_limits.dart` | Edit. N21-T05 created it for `kPdfRowsPerVolume`; this task adds `kBackupSizeTripwireBytes` (20 MB — 09 §5.7, 04 §6.8). One file for both caps, because 09 §1.2 names one file for both |
| 3 | `test/features/backup_format_test.dart` | **New.** The anchor plus the cases in §5.4 |

`pubspec.yaml` and `pubspec.lock` are **not** touched. Everything here is `dart:convert`,
`dart:typed_data` and `dart:io`. A lockfile diff in a PR that does not also change `pubspec.yaml` is a
review stop (`00-README` §7.1).

The anchor lives under `test/features/` because that is where the plan anchors it and the id is
preserved. It pumps no widget: it drives the encoder directly and uses the in-memory drift harness for
the database half. Do not add a `pumpApp` to make it look like its neighbours.

### 5.2 The signatures

09 §5.2's thirteen header keys, in the order they are written, are the contract:

```
_disclaimer · _withdrawalNotice · format · formatVersion · schema · appVersion ·
exportedAtUtc · exportedAtOffsetMinutes · exportedAtZoneAbbreviation ·
checksum · counts · media · tables
```

`_disclaimer` first (05 §7.4 fixes it), `_withdrawalNotice` second (09's own ruling — 05 places only the
§12.3 string), `tables` last so the writer can stream it without buffering it twice.

```dart
// lib/data/backup_format.dart
// The JSON backup envelope. 09 §5 owns every rule in this file.
// NO package:intl here — `export.intl_in_writer` is a gate row, and a locale
// decimal comma would shift the file. NO byte-order mark either: this file
// never touches CsvWriter's `_bom` (09 §2.4).
import 'dart:convert';
import 'dart:typed_data';

const String kBackupFormat = 'shed-book-backup';   // the "format" value, frozen
const int kBackupFormatVersion = 1;                // the HEADER's version, NOT the schema's

/// The `format` / `formatVersion` / `schema` / `counts` / `checksum` block
/// (CONVENTIONS §2.8, R65). It is never called "the envelope": `ExportEnvelope`
/// is the disclaimer-bearing value in lib/domain/policy/, and "the envelope" is
/// the whole file. If a sentence here would read the same with two of the three
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
  final int schema;                       // the database's kSchemaVersion at export
  final String appVersion;                // from ExportEnvelope.appVersion
  final String exportedAtUtc;             // ISO-8601, milliseconds, trailing Z
  final int exportedAtOffsetMinutes;      // the phone's offset AT the export instant
  final String exportedAtZoneAbbreviation;
  final Map<String, int> counts;          // one entry per key in `tables` — 21, zeros included
  final BackupMedia media;                // v1 is records-only
}

final class BackupMedia {
  const BackupMedia({required this.included, required this.count, required this.bytes});
  final bool included;                    // always false in v1 (decision #85)
  final int count;
  final int bytes;
}

/// The canonical encoding: object keys sorted ascending by code unit, at every
/// level, no insignificant whitespace, integers only. This is the ONLY encode of
/// `tables` in the app, and the checksum covers exactly these bytes (09 §5.7).
Uint8List canonicalJsonBytes(Object? value);

/// '{"_disclaimer":…,"tables":' — the fixed-order prefix, ending in the open key
/// with no value. It deliberately does not close the object; the caller appends
/// the canonical bytes and then '}\n'.
String headerPrefixJson(BackupHeader header, String checksumHex, ExportEnvelope envelope);

/// T04's body. Declared here so this task's writer compiles against the real
/// signature rather than a placeholder that later changes shape.
String fnv1a64Hex(List<int> bytes);
```

And the writer 09 §5.7 fixes — T02 calls it, and its shape is not re-opened later:

```dart
final tablesBytes = canonicalJsonBytes(tables);            // the only encode
final checksum    = fnv1a64Hex(tablesBytes);
final sink = File(outPath).openWrite();
sink.add(utf8.encode(headerPrefixJson(header, checksum, envelope)));
sink.add(tablesBytes);
sink.add(utf8.encode('}\n'));
await sink.close();
```

**Names this task coins**, because `CONVENTIONS` §1–§3 do not list them and 09 §1.2 delegates the file:
`kBackupFormat`, `kBackupFormatVersion`, `BackupMedia`. All three follow `CONVENTIONS` §4.2 — a
`k`-prefixed `const`, a `final class` in `UpperCamel`. `BackupHeader`, `canonicalJsonBytes`,
`fnv1a64Hex`, `headerPrefixJson` and `kBackupSizeTripwireBytes` are **not** coined: every one is spelled
in 09 §1.2, §5.7 or `CONVENTIONS` §2.8, and those spellings are binding.

**One deliberate divergence, and it is the only one:** 09 §5.7's illustrative call is
`headerPrefixJson(header, checksum)` — two arguments. This task adds a third, the `ExportEnvelope`,
rather than copying the disclaimer strings into `BackupHeader`. The reason is the safety level: with the
envelope as a required parameter, no call path can produce a header prefix without the §12.3 string, and
`ExportEnvelope`'s own private constructor means no caller can pass a hollow one. Copying the strings
onto `BackupHeader` would make it possible to construct a disclaimer-free header and would put a second
copy of the string one refactor away from `copy.disclaimer_retyped`. Record the divergence in the PR
body; 09 §5.7's snippet is an illustration of the *write order*, which is unchanged.

### 5.3 The details that are easy to get wrong

- **`jsonEncode` does not sort keys, and no flag makes it.** `canonicalJsonBytes` has to build the sorted
  structure itself. Use a `SplayTreeMap<String, Object?>` per object, recursively, then encode the
  result — `SplayTreeMap`'s default comparator is `Comparable.compare`, which for `String` is
  `compareTo`, which is UTF-16 code-unit order, which is exactly what 09 §5.7 specifies. Do **not** use a
  locale-aware comparator and do not fold case first: `Z` sorts before `a` by code unit, and that is
  correct.
- **The sort has to be recursive.** The `unknown_json` splat (T03) produces nested objects inside a row,
  and 09 §7.2 rule 2 says canonical order applies *"at every level inside the `tables` value"*. A
  one-level sort passes every case this task writes and fails first at T03 — three commits later, with a
  much bigger diff to bisect.
- **Only the `tables` *value* is canonical; the header is hand-ordered and outside the checksum.** This
  looks inconsistent and it is deliberate: the header carries `exportedAtUtc`, so it legitimately differs
  between two exports of the same database, and covering it would make the checksum non-reproducible by
  construction. Put that sentence in the file, or the next reader will "fix" it.
- **Do not build the header prefix by encoding a map and hoping.** Dart map literals are
  insertion-ordered and `jsonEncode` respects that, so the *order* is fine — but the writer needs a
  prefix ending in `,"tables":` with the object still open. Build the map in the documented order,
  encode it, then slice off the final `}` and append `,"tables":`. Assert the sliced character actually
  was `}` rather than trusting it; a silent mis-slice produces valid JSON with the §12.3 disclaimer
  nested inside the wrong object.
- **No byte-order mark, ever.** It belongs to `csv_writer.dart` and to nothing else (09 §2.4): a leading
  mark makes `jsonDecode` throw or folds itself into the first key, and the first key here is the §12.3
  disclaimer. The anchor asserts `bytes.first == 0x7B` — `{`.
- **One trailing newline, and the file is compact.** Not pretty-printed. Indentation roughly doubles the
  bytes and the peak heap at exactly the moment the 20 MB tripwire is about to bite — and, more usefully,
  the `tables` value as it appears in the file **is** the canonical encoding, byte for byte, so a
  shepherd with `jq` and `xxd` can reproduce the checksum by hand.
- **`exportedAtOffsetMinutes` is the offset at the *export instant*, not the offset now.** Derive it from
  `envelope.generatedAt.local.timeZoneOffset.inMinutes`, never from `DateTime.now().timeZoneOffset`.
  Inside the ambiguous 01:00–01:59 hour the two answers differ by sixty minutes, and this field is the
  only record of which side of the boundary the export happened on. Both zone fields are **context
  only** — nothing reads them back on import.
- **`package:timezone` is banned here.** R48 confines it to `lib/data/notification_scheduler.dart`.
  `exportedAtZoneAbbreviation` comes from `DateTime.timeZoneName`, and 09 §10 item 6 records that this
  returns an abbreviation on some platforms and a full name on others. That is a known, accepted
  looseness in a context-only field; do not "fix" it by pulling in the timezone database.
- **`formatVersion` is not `schema`.** One is the header's version, one is the database's
  `kSchemaVersion` at export time. They are both `1` on day one, which is exactly why merging them is
  invisible until v2 — and by then every file ever written carries the mistake (09 §5.2).
- **The share name is the one all-numeric date this app writes, and it is deliberate.**
  `shed-book-backup-2026-07-27-2104.json` (09 §8.1) carries date **and** time, because a shepherd who
  exports before and after a night would otherwise overwrite the morning's file. It is ISO-ordered so it
  is unambiguous, and it is a file name rather than a sentence a human reads, so R60 is not violated.
  Build it by hand with `padLeft(2, '0')`: `package:intl` is a gate row in this file.
- **`ExportEnvelope` is not optional and `disclaimer` is not a parameter of it.** Its generative
  constructor is private and `ExportEnvelope.standard({required Instant now, required String appVersion})`
  is the only factory (R65). `headerPrefixJson` therefore cannot be called without a disclaimer — §12.3
  held at the *unconstructible* level rather than by a reviewer noticing.
- **`Disclaimers.exportFooter` is referenced, never re-typed** (decision #62, `copy.disclaimer_retyped`),
  and the same goes for `Disclaimers.withdrawalCaveat` behind `_withdrawalNotice`. The single-definition
  test counts one literal in the whole codebase and uses `joinedStringLiterals`, because Dart wraps long
  strings across adjacent literals and a naive `contains` misses them (09 §6.4).
- **`kBackupSizeTripwireBytes` is a tripwire, not a limit.** It refuses nothing and must not. Crossing
  20 MB means *measure before assuming it is still fine*; the fix, if it is ever needed, is a streaming
  writer emitting one table at a time to the same `IOSink` — **not** an isolate, because a drift
  connection cannot cross an isolate boundary (decision #125).

### 5.4 The full test set

`test/features/backup_format_test.dart`. No widget pump; the database half uses the in-memory harness.

| Case | What it asserts |
|---|---|
| `'two exports of identical data are byte-identical and _disclaimer is the first key'` | **The anchor.** Identical `Uint8List`s over `tables`, `"_disclaimer"` at index 1, its value equal to `Disclaimers.exportFooter` |
| `'insertion order does not survive into the file'` | The same map built forwards and backwards encodes to the same bytes |
| `'object keys are sorted ascending by code unit at every level'` | Includes a nested object, and a key pair where uppercase sorts before lowercase |
| `'the header keys are the thirteen of 09 §5.2, in that order'` | Read the raw text in order; never decode into a `Map` and guess |
| `'_withdrawalNotice is the second key and equals Disclaimers.withdrawalCaveat'` | 09's own ruling, distinct from 05's |
| `'the file has no byte-order mark and exactly one trailing newline'` | `bytes.first == 0x7B`; `bytes.last == 0x0A`; no second newline |
| `'the file is compact — no insignificant whitespace anywhere'` | No newline and no two consecutive spaces inside the `tables` value |
| `'formatVersion is independent of schema'` | A header with `formatVersion: 1, schema: 4` reads back as two distinct numbers |
| `'tables is the last key and the prefix ends in an open value'` | `headerPrefixJson` ends with `,"tables":` and the object is still open |
| `'the disclaimer is unconstructible-empty'` | No call path builds a header prefix without an `ExportEnvelope`, and `Disclaimers.exportFooter` appears as a literal exactly once in `lib/` |
| `'no package:intl and no NumberFormat appears in backup_format.dart'` | Source text over the one file — `export.intl_in_writer` made executable here rather than waiting for the gate |
| `'the share name carries date and time and is ISO-ordered'` | The `2026-07-27-2104` shape, built with `padLeft`, no `DateFormat` |
| `'kBackupSizeTripwireBytes is 20 MB and refuses nothing'` | The constant's value, and that no code path throws on crossing it |

**The `uk-zone` group.** Put it in `group('DST', …, tags: 'uk-zone')` and assert the ambient zone **first
and loudly**, so it can never pass for the wrong reason. The `test` job runs
`TZ=Europe/London --tags uk-zone` over the whole suite, so a tagged group under `test/features/` is
picked up; an untagged case runs under the runner's own zone, which is UTC, and proves nothing about an
offset field.

| Case | What it asserts |
|---|---|
| `'this group requires TZ=Europe/London'` | Fails loudly under a wrong `TZ` rather than silently asserting UTC |
| `'DST: two exports an hour apart in the ambiguous 01:00–01:59 hour carry different exportedAtUtc values'` | The clocks-back night: two distinct instants, one local `01:30` |
| `'DST: exportedAtOffsetMinutes is 60 on the first pass through 01:30 and 0 on the second'` | The field is derived from the export instant's own offset, never from a second clock read |
| `'DST: the tables bytes are identical across both of those exports'` | The header moves; the body does not. This is the property the checksum depends on |
| `'DST: exportedAtUtc always ends in Z and always carries milliseconds'` | No local ISO string, no offset suffix, no truncated fraction |

## 6. Constraints that bind this task

- **The five safety rules — §12.3, held at *unconstructible*.** `ExportEnvelope`'s generative constructor
  is private and `disclaimer` is not a parameter of its only factory, so no caller can pass an empty
  string, a placeholder, or a "short version for this one file". If that ever becomes a parameter the
  rule has dropped to *documented*, which means it has been deleted, whatever the prose says.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. Nothing here needs a package: `dart:convert` sorts, encodes and escapes.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. Three more bind this file: **the backup** is the JSON file and never *the dump* or *the snapshot*; **the snapshot** is `VACUUM INTO` and the drift schema JSON and never *the backup*; and the header type is **`BackupHeader`**, never *the envelope* (R65).

## 7. Definition of Done

- [ ] `'two exports of identical data are byte-identical and _disclaimer is the first key'` passes, and was seen to fail first for the stated reason
- [ ] byte-identical for identical data
- [ ] `_disclaimer` is the first key
- [ ] the schema version is in the header, not inferred
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `lib/data/backup_format.dart` exists at 09 §1.2's path and `lib/data/` gains no subfolder (R18)
- [ ] the thirteen header keys appear in 09 §5.2's order, `_disclaimer` first and `tables` last
- [ ] `formatVersion` and `schema` are separate fields with separate meanings
- [ ] keys inside `tables` are sorted ascending by code unit **at every level**, and the sort is recursive
- [ ] the file is compact, carries no byte-order mark, and ends with exactly one newline
- [ ] `canonicalJsonBytes` is the only encode of `tables`, and `headerPrefixJson` cannot be called without an `ExportEnvelope`
- [ ] `Disclaimers.exportFooter` and `Disclaimers.withdrawalCaveat` are referenced, never re-typed
- [ ] `package:intl` and `NumberFormat` appear nowhere in `backup_format.dart`
- [ ] **the `uk-zone` DST group exists, is tagged, fails loudly under a wrong `TZ`, and covers the 01:00–01:59 ambiguous hour**
- [ ] `pubspec.yaml` and `pubspec.lock` are unchanged

## 8. Verification

```bash
fvm flutter test test/features/backup_format_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

```bash
grep -n "package:intl\|NumberFormat\|package:crypto" lib/data/backup_format.dart   # expect zero
grep -n "0xEF, 0xBB, 0xBF" lib/data/backup_format.dart                             # expect zero
git diff --stat -- pubspec.yaml pubspec.lock drift_schemas/ lib/core/db/           # expect empty
```

Then read one real file by hand, because the format is a promise to a person and not only to a test.
Export a backup from a debug build, share it to the machine, and confirm the first key printed is
`_disclaimer` and that byte 0 is `{` with nothing in front of it:

```bash
head -c 200 backup.json
xxd -l 4 backup.json          # expect 7b22 5f64 — '{"_d', no byte-order mark
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(backup): the header and the canonical encoder`

# 09 — Export formats

This document governs every byte that leaves the phone: the hand-rolled RFC 4180 CSV writer and its three shapes, the two PDF documents, the JSON backup envelope, and the spec §12 disclaimer strings that all six artifacts must carry. It is written for the developer building `lib/features/export/` and `lib/data/export_repository.dart`, and for anyone touching `RestoreService` — the backup format is a two-sided contract and half of it is here. Export is the only backup this app has (spec §7.9: *"a safety feature, not a convenience"*), so an export that is silently wrong is the worst bug in the product.

> **Decisions applied:** #80 (share sheet: `SharePlus.instance.share(ShareParams(...))`, always a path, `sharePositionOrigin` on iPad), #82 (hand-rolled RFC 4180 writer; BOM, CRLF, quoting set, formula-injection guard, three shapes, the §12.1 + §12.3 trailers), #83 (`pdf` only; always an embedded TTF; `compute()`; temp file; no photos; split rather than crash), #84 (JSON is *the* backup and *the* restore format), #85 (records-only for v1; media is a separate share), #86 (export is never gated by the free tier), #62 (`Disclaimers` is a `const` in exactly one file, referenced never re-typed), #50 (`clear_date` is stored and is what the app told the user), #53 (`RecordedTime` provenance travels as a unit), #54 (contradictions are warned about, never fixed), #56 (canonical grams / milli-°C — no floats), #59/#61 (statistic `definition` strings, verbatim), #29 (integer instants, text civil dates), #32 (identity is `uid`; import upserts on `uid`), #73 (refuse a newer file; preserve unknown columns), #88 (the entitlement row is never exported and ignored on import), #108 (never render an all-numeric date to a human; numeric dates only inside CSV beside an ISO-8601 column), #125 (only PDF generation and image downscaling go off-isolate), #127 (bundled assets < 5 MB). Owner rulings §7.0: UK/Ireland first (`en_GB`, kg, °C, 24 h, `dd/MM/yyyy`, Monday); export is never gated by the cap. `CONVENTIONS.md` R65 (`ExportEnvelope` vs `BackupHeader`), R60 (no all-numeric human-facing date), R32/R33 (ids cross boundaries), R18 (`lib/data/` is flat).

---

## 1. What this document owns

### 1.1 The six artifacts

| Artifact | Writer | Scope | Share name | Importable? |
|---|---|---|---|---|
| `lambs.csv` | `CsvWriter` + `ExportRepository.writeLambsCsv` | one season | `shed-book-2026-lambs.csv` | no |
| `ewes.csv` | `CsvWriter` + `ExportRepository.writeEwesCsv` | one season | `shed-book-2026-ewes.csv` | no |
| `treatments.csv` | `CsvWriter` + `ExportRepository.writeTreatmentsCsv` | one season | `shed-book-2026-treatments.csv` | no |
| Flock book PDF | `buildFlockBookPdf` (isolate) | one season, **two volumes** | `shed-book-2026-flock-book-ewes.pdf`, `…-lambs.pdf` | no |
| Medicine record PDF | `buildMedicineRecordPdf` (isolate) | one season | `shed-book-2026-medicine-record.pdf` | no |
| JSON backup | `ExportRepository.writeBackup` | **the whole database** | `shed-book-backup-2026-07-27-2104.json` | **yes — `RestoreService`** |

**Only the JSON backup has an importer.** There is no CSV import and no PDF import, and there never will be: a CSV import is a merge, and there is no merge (`CONVENTIONS` §5.2). This is why §7's round-trip property is stated over the backup and over nothing else.

**Scope rule.** Every artifact except the backup is scoped to exactly one season — the one the user is looking at, defaulting to `app_settings.current_season`. The backup is the whole database, every season, because it is the thing that restores a new phone. A season-scoped backup would be a data-loss generator dressed as a safety feature.

### 1.2 The files this document adds

`lib/data/` is flat (R18). These are new file names; they follow `CONVENTIONS` §4.1 and are **called out** here because `CONVENTIONS` §1 does not list them:

```
lib/data/csv_writer.dart        # CsvWriter — the ONLY producer of CSV bytes
lib/data/pdf_writer.dart        # the ONLY file that may say pw.Document( or pw.MultiPage(
lib/data/backup_format.dart     # BackupHeader (R65 gives 09 the placement) + the canonical encoder
lib/data/export_limits.dart     # kPdfRowsPerVolume, kBackupSizeTripwireBytes
lib/data/export_repository.dart # already in CONVENTIONS §1 — the reads and the assembly
```

New type names, all following `CONVENTIONS` §4.2, all called out for the same reason:

| Name | File | Shape |
|---|---|---|
| `CsvWriter` | `lib/data/csv_writer.dart` | `final class`; constructed with an `ExportEnvelope`; `Uint8List encode(List<String> header, Iterable<List<Object?>> rows)` |
| `BackupHeader` | `lib/data/backup_format.dart` | the `format`/`formatVersion`/`schema`/`counts`/`checksum` block (R65 names it; R65 leaves the file to 09) |
| `ExportArtifact` | `lib/data/export_repository.dart` | `typedef ExportArtifact = ({String path, String shareName, int byteSize});` |
| `ExportCounts` | `lib/features/export/export_controller.dart` | `typedef ExportCounts = ({int ewes, int lambs, int treatments, int mediaAssets, int mediaBytes, Instant? lastExportedAt});` — `CONVENTIONS` §3.2 names `exportCountsProvider` but no document shapes its element |

### 1.3 Edits this document requires in siblings

Do these in the same commit as the first export code, not later.

| File | Edit | Why |
|---|---|---|
| `04-…-backup-restore.md` §6.2 | `"notice"` → **`"_disclaimer"`, and it is the first key** | `05-domain-correctness.md` §7.4 fixes the placement as a top-level `_disclaimer` key and the golden test is written against it. 05 owns `Disclaimers`. |
| `04-…-backup-restore.md` §6.2 | add **`vocab_terms`** to `tables` | `lambings.presentation`, `lambs.death_cause`, `treatments.route`, `ewe_observations.kind` and `foster_events.method` are `RESTRICT` foreign keys onto `vocab_terms.key`. A user-added term (`origin = 'user'`, 03 §5.12) that is not in the backup makes the restore fail its own foreign-key check. This is a restore-breaking omission, not a tidiness point. |
| `04-…-backup-restore.md` §6.4 | name **`ewe_summaries`** in the "Excluded" column, and correct the view names to **`lamb_rearing`** and **`lambing_consistency`** | 03 §5.13 excludes `ewe_summaries` (a rebuildable cache) and 04's own header omits it, but 04's stated rule is "every non-derived table is exported except the three named exceptions" — which does not cover it. Four exceptions, written down. The same cell names the views `current_rearing_dam` and `ewe_summary`; neither exists — 03 §7 defines `lamb_rearing`, 03 §5.4 defines `lambing_consistency`, and `ewe_summaries` is a table, not a view. An exclusion list that names things that do not exist excludes nothing. |
| `03-data-model-and-schema.md` §5 | add **`unknown_json`** — `text().nullable()` plus `CHECK (unknown_json IS NULL OR json_valid(unknown_json))` — to **all 21 restorable tables** | 04 §6.5 and §5.5 below are both written against this column and **03 does not declare it on any table**. It is nullable, so a migration *could* add it later, but until it lands the forward-compatibility rule is inert: a column from a newer backup has nowhere to go and is dropped silently. Land it before the first schema snapshot. This is the same class of restore-breaking omission as the `vocab_terms` row above. |
| `05-domain-correctness.md` §4.1 | add `String get label` to `enum TimeSource`; `RecordedTime.provenanceLabel => source.label` | §6.3 below builds the CSV's §12.5 trailer line from the three labels without a `RecordedTime` instance. Moving the exhaustive switch onto the enum keeps the same compiler check and makes the labels reachable. One line. |
| `07-screens.md` §13.1 | `readsFrom` gains **`mediaAssets`** | `ExportCounts` (§1.2) carries `mediaAssets` and `mediaBytes`, because §8.4's "Share photos from this season" row needs a count and a size. 07's `readsFrom: {lambs, ewes, treatments, appSettings}` does not track the table those come from, so the row would render a stale count until an unrelated write happened to invalidate the stream. |
| `CONVENTIONS.md` §1.1 rule 3 | `lib/data/`'s permitted packages gain `package:pdf` | `lib/data/pdf_writer.dart` needs it. `share_plus` is already there by precedent (`ShareService`). |
| `CONVENTIONS.md` §2.2 | `TimeSource`'s shape gains `String get label` | §2.2 pins that enum's shape and CONVENTIONS outranks every other document on a type shape. The 05 edit above is not applied until the catalogue records it, or the next fixer reverts it as a stray name. |
| `CONVENTIONS.md` §4.7 | add the `export` namespace and the five rows in §9 | Policy rule ids are dotted `namespace.name` (R54); the namespace list is a living list that §4.7 already extends. |

---

## 2. The CSV writer

### 2.1 Hand-rolled, and why that is not laziness

`csv` 8.0.0 is rejected (decision-record §5.3): an unverified uploader shipping a fresh breaking rewrite — `CsvCodec` → `Csv`, no longer a `dart:convert` `Codec`, `CsvEncoder` moved from `Converter` to `StreamTransformerBase` — for roughly fifty lines of behaviour that RFC 4180 specifies completely. Three properties this app needs are byte-level and a general-purpose package will not give you all three at once: the UTF-8 BOM, CRLF line endings, and a quoting predicate that also fires on `;` and TAB. Writing the encoder costs an afternoon and one test file; taking the dependency costs a review every time it breaks.

**The writer is the only producer of CSV bytes in the app.** That is a policy rule (`export.csv_bytes`, §9), and it is what makes "every CSV carries its trailer" a structural property rather than a habit.

### 2.2 The encoder

```dart
// lib/data/csv_writer.dart
// RFC 4180 — https://www.rfc-editor.org/rfc/rfc4180
import 'dart:convert';
import 'dart:typed_data';

import '../domain/policy/disclaimers.dart';
import '../domain/policy/export_envelope.dart';
import '../domain/time/recorded_time.dart';   // for TimeSource.label

final class CsvWriter {
  /// The envelope is not optional and the disclaimer is not a parameter of it
  /// (05 §7.4). A CsvWriter that cannot emit the footer cannot be constructed.
  const CsvWriter(this.envelope, {required this.localZoneLabel});

  final ExportEnvelope envelope;

  /// e.g. "IST (UTC+01:00)". Built from `envelope.generatedAt.local`, never
  /// from a clock read and never from package:timezone (R48 confines tz to
  /// the notification seam).
  final String localZoneLabel;

  static const String _eol = '\r\n';                 // RFC 4180 §2.1
  static const List<int> _bom = [0xEF, 0xBB, 0xBF];  // UTF-8 BOM, for Excel

  static final RegExp _needsQuote = RegExp(r'[",\r\n;\t]');

  /// Excel, Numbers and Google Sheets evaluate a field beginning with one of
  /// these as a formula. `=` `+` `-` `@` TAB CR — the full set, not the four
  /// obvious ones. See §2.6: this is a transformation of the EXPORT.
  static final RegExp _formulaLead = RegExp(r'^[=+\-@\t\r]');

  String _field(Object? v) {
    if (v == null) return '';
    var s = v.toString();
    if (_formulaLead.hasMatch(s)) s = "'$s";
    if (!_needsQuote.hasMatch(s) && s.trim() == s) return s;
    return '"${s.replaceAll('"', '""')}"';           // RFC 4180 §2.7
  }

  /// Bytes, not a String: the BOM is a byte-level concern and a String cannot
  /// carry it without lying about its own length.
  Uint8List encode(List<String> header, Iterable<List<Object?>> rows) {
    final b = BytesBuilder(copy: false)..add(_bom);
    void line(List<Object?> r) =>
        b.add(utf8.encode(r.map(_field).join(',') + _eol));

    line(header);
    for (final r in rows) {
      // A real check, NOT an `assert`. Asserts are stripped in release, and a
      // ragged file is a release-mode failure: it reaches the share sheet, it
      // reaches the shepherd's spreadsheet, and every column after the short
      // row is shifted. One integer comparison per row is not a cost.
      if (r.length != header.length) {
        throw StateError('ragged row: ${r.length} fields, expected '
            '${header.length} (RFC 4180 §2.4)');
      }
      line(r);
    }
    for (final t in _trailer()) {
      line([t, ...List.filled(header.length - 1, null)]);   // pad to rectangular
    }
    return b.takeBytes();
  }

  List<String> _trailer() => [
        '# ${envelope.disclaimer}',                          // §12.3
        '# ${Disclaimers.withdrawalCaveat}',                 // §12.1
        '# Times are exported in UTC. Each event carries its source: '
            '${TimeSource.values.map((s) => s.label).join(' · ')}.',   // §12.5
        '# Local times in this file were rendered in $localZoneLabel at export. '
            'The UTC columns are exact.',
        "# Fields beginning = + - @ a tab or a carriage return are prefixed "
            "with ' in this file so a spreadsheet does not evaluate them. "
            'The stored record is unchanged.',
        '# Shed Book ${envelope.appVersion}.',
      ];
}
```

Note what `_field` does **not** do: no `DateTime` branch, no `double` branch. Every value handed to the encoder is already a `String`, an `int` or `null`, because formatting is the caller's decision and a formatter hidden inside an encoder is a locale bug waiting for a Welsh name (§2.5).

### 2.3 The quoting rules

| Input field | Emitted | Rule |
|---|---|---|
| `412` | `412` | no quote needed |
| `Ewe, prolapsed` | `"Ewe, prolapsed"` | contains the delimiter — RFC 4180 §2.6 |
| `she "kicked"` | `"she ""kicked"""` | `"` → `""`, **never** `\"`. This is the single most common hand-rolled CSV bug |
| `line one⏎line two` | `"line one⏎line two"` | embedded CR or LF — RFC 4180 §2.6. The bytes stay CRLF-agnostic inside the quotes: whatever the shepherd typed is what is written |
| `prolapse; mastitis` | `"prolapse; mastitis"` | `;` is quoted so the same bytes survive a semicolon-delimited reopen in a European Excel |
| `a⇥b` | `"a⇥b"` | TAB, same reason |
| `` ` 412 ` `` (leading space) | `" 412 "` | leading/trailing whitespace is quoted so a parser cannot trim it away |
| `` (null) `` | *(empty)* | `NULL` is an empty field. It is never the string `null`, never `N/A`, never `-` |
| `-2 lambs born` | `'-2 lambs born` | formula guard, §2.6 |

Embedded newlines in a free-text note are the case that separates a real writer from a `join(',')`: a shepherd's note typed on a phone keyboard at 03:20 routinely contains a line break, and an unquoted one turns one record into two and shifts every column after it. The rectangularity check on `r.length == header.length` catches the other half of the same failure (RFC 4180 §2.4 requires every record to have the same field count) before a ragged file reaches a share sheet — and it is a `throw`, not an `assert`, because an `assert` is compiled out of the release build the shepherd actually runs.

### 2.4 UTF-8, the BOM, and the line ending

- **UTF-8, always.** `utf8.encode`, no other codec, no platform default.
- **The BOM is on, always.** Excel on Windows decodes a BOM-less UTF-8 file as the ANSI code page, which mangles every `°`, `£`, `é`, every Welsh `ŵ` and every Irish `Ó`. Numbers, Google Sheets and every Dart/Python parser cope with the BOM. The trade is one-sided.
- **The BOM is CSV-only.** JSON must not carry it: a leading BOM makes `jsonDecode` fail or turns it into part of the first key. `backup_format.dart` never touches `_bom`.
- **CRLF line endings** (RFC 4180 §2.1), including after the last record. Every parser accepts CRLF; some Excel versions still prefer it.
- **No `sep=;` line.** Excel's sniffing line is Microsoft-proprietary and breaks strict RFC 4180 parsers. Decision #82 rejects it explicitly. The semicolon-delimited reader is served by the quoting rule above, not by a header hack.
- **Delimiter is `,`, and there is no delimiter setting in v1.** A per-user delimiter is a second file format to test; the quoting rule already makes the comma-delimited file survive a semicolon reopen.

### 2.5 Dates and numbers — the `en_GB` rule, and the rule above it

CSV is an interchange format, not a display format. That single sentence decides every formatting question here.

| Value | CSV column(s) | Format | Never |
|---|---|---|---|
| Instant | `*_at_utc` | `2026-03-14T03:20:42.015Z` — ISO-8601, UTC, milliseconds, `Z` | a local ISO string; an epoch integer; a `DateTime.toString()` |
| Instant, human-readable | `*_at_local` | `14/03/2026 03:20` — `dd/MM/yyyy HH:mm`, 24 h, device zone at export | 12-hour; `d MMM y` (that is the *screen* format, R60); a zone-less claim |
| Civil date | `*_date`, `clear_date`, `death_date` | `2026-03-14` — the stored `TEXT` value, passed through untouched | re-parsed, re-formatted, or widened from a `PartialDate` |
| Partial date | `date_of_birth` | `2023`, `2023-04` or `2023-04-11` — exactly as stored | padded to 1 January. Partial precision is a real state (03 §5.2) |
| Mass | `birth_weight_g` **and** `birth_weight_kg` | integer grams; and kg to exactly two decimals with a `.` separator | a locale decimal comma; a thousands separator; the user's display unit |
| Count | every `*_count`, `*_recorded`, `days` | plain integer | `NumberFormat`; a grouping separator |
| Boolean | `pet_lamb`, `is_voided`, `*_disagrees` | `0` / `1` | `true`/`false`; `Y`/`N` |

Three consequences worth saying out loud:

1. **`package:intl` is banned inside `csv_writer.dart`.** `dd/MM/yyyy HH:mm` is built by hand from `Instant.local`'s components with zero-padding; `NumberFormat` would emit a comma decimal on a device set to French and silently shift every column after the weight. Policy rule `export.intl_in_writer` (§9).
2. **`d MMM y` never appears in a CSV, and an all-numeric date never appears on a screen *or in a PDF*.** `CONVENTIONS` §5.4 and R60: numeric dates exist only inside CSV, and only beside an ISO-8601 column. The header ordering in §3 enforces the "beside" half — `born_at_utc` is always immediately left of `born_at_local`. A PDF has no ISO column to sit beside, so it never gets the numeric form; §4.6 and §4.7 spell out what it gets instead.
3. **The user's `WeightUnit` does not change the file.** The header is fixed for all time; two exports from two phones concatenate cleanly; the round-trip and the golden tests have one shape to assert. The unit is in the column name, so nothing is ambiguous. **The PDF is the opposite** — it is a document a human reads, so it renders `4.10 kg` or `9 lb 0 oz` per `unitsProvider` (§4.6). That is the whole rule: *CSV is interchange, PDF is display.*

### 2.6 The formula-injection guard, and why it is not a §12.4 violation

A note that begins `-2 lambs`, `=needs vet` or `+1 more` is an executable formula the moment the file opens in Excel or Google Sheets. Prefixing with `'` neutralises it — Excel consumes the apostrophe as a text marker, a plain-text viewer shows it.

Spec §12.4 forbids silently correcting a user's entry, and this does not:

- The **record** is untouched. SQLite holds the exact bytes the shepherd typed, and so does the JSON backup — the guard lives only in `csv_writer.dart`, which the backup writer never calls.
- The transformation is **declared in the file itself**, in the trailer, in plain words.
- It cannot corrupt a numeric column, because **no exported numeric column can be negative**: every numeric `CHECK` in 03 is `>= 0` (`days`, `birth_weight_g`, `scanned_count`, `bottle_feeds`, `byte_size`, `volume_ml`, `ewes_to_ram`). If a future column can hold a negative number, the guard must become per-column rather than global — write that down in the same commit as the column.

Anti-pattern: applying the guard in the PDF or JSON writer "for consistency". It would put an apostrophe into the vet's medicine book and break the backup round trip.

### 2.7 The trailer

Six records, appended by `encode` itself, on **every** CSV including a zero-row one (07 §13.2: *"a 0-row CSV still carries its disclaimer trailer"*). Each is padded with empty fields to the header's column count, because RFC 4180 §2.4 requires a rectangular file and a two-field trailer row breaks a strict parser on the last line — which is exactly where a shepherd's spreadsheet stops importing.

`#` is not an RFC 4180 comment marker; there is no such thing. These are ordinary records whose first field begins with `#`, which every parser reads as data and every human reads as a note. `#` is not in the formula-lead set, so it is never apostrophe-prefixed.

---

## 3. The three shapes

Spec §7.9: one row per lamb, one row per ewe, one row per treatment. Every column below names its source column or view; anything marked *derived* is computed in Dart at export time and the derivation is stated.

Ordering is deterministic in every shape: `ORDER BY` the stable key named under each table. Never `ORDER BY id` — integer ids are re-issued on import (#32) and an unordered export makes every diff between two exports unreadable.

### 3.1 `lambs.csv` — one row per lamb

Rows: every `lambs` row whose `lambings.season` is the exported season, **including dead, stillborn and untagged lambs**. A lamb that died before tagging is counted, fully (03 §5.5); an export that drops it loses exactly the losses that matter most. Order: `lambings.occurred_at`, then `lambs.uid`.

| # | Column | Source | Format |
|---|---|---|---|
| 1 | `lamb_uid` | `lambs.uid` | UUID v7 text |
| 2 | `season_year` | `seasons.year` | integer |
| 3 | `season_label` | `seasons.label` | text, verbatim |
| 4 | `lamb_tag` | `lambs.tag` | text verbatim; blank when untagged |
| 5 | `sex` | `lambs.sex` | `f` / `m` / `unknown`; **blank ≠ `unknown`** — blank is "not recorded", `unknown` is "looked and could not tell" (R45). Never merge them |
| 6 | `birth_dam_tag` | `ewes.tag` via `lambs.birth_dam` | text verbatim |
| 7 | `birth_dam_uid` | `ewes.uid` | UUID |
| 8 | `rearing_dam_tag` | `lamb_rearing.rearing_dam` → `ewes.tag` | blank when the lamb is on the bottle or the outcome is `removed_unknown` |
| 9 | `rearing_dam_uid` | same | UUID or blank |
| 10 | `was_fostered` | `lamb_rearing.was_fostered` | `0` / `1` |
| 11 | `lambing_uid` | `lambings.uid` | UUID |
| 12 | `born_at_utc` | `lambings.occurred_at` | ISO-8601 UTC ms `Z` |
| 13 | `born_at_local` | *derived* from col 12 in the export-time zone | `dd/MM/yyyy HH:mm` |
| 14 | `born_local_date` | `lambings.local_date` — the civil date **stored at write time** | `YYYY-MM-DD` |
| 15 | `local_date_disagrees` | *derived*: col 14 ≠ the civil date of col 12 in the export-time zone | `0` / `1`. `WarningCode.localDateDisagrees` (`CONVENTIONS` §2.6). Both values are printed; neither is corrected — §12.4 |
| 16 | `time_source` | `lambings.time_source` | `auto` / `entered` / `edited` |
| 17 | `time_provenance` | `TimeSource.label` | `recorded automatically` / `time entered by you` / `time edited by you` |
| 18 | `time_captured_at_utc` | `lambings.captured_at` | ISO-8601 UTC ms `Z` |
| 19 | `time_original_effective_utc` | `lambings.original_effective` | ISO or blank. **Blank iff `time_source` ≠ `edited`** — the paired CHECK travels into the file |
| 20 | `declared_birth_type` | `lambings.declared_birth_type` | `1`–`5`, exactly as tapped |
| 21 | `lambs_recorded_for_lambing` | `lambing_consistency.recorded` | integer |
| 22 | `birth_type_mismatch` | `lambing_consistency.is_mismatched` | `0` / `1`. Both numbers ship; the file never reconciles them |
| 23 | `lambing_ease` | `lambings.ease` | `1`–`5` or blank. Blank is "not scored", which is not "unassisted" |
| 24 | `assisted_by` | `lambings.assisted_by` | text |
| 25 | `presentation_key` | `lambings.presentation` | `mp_*` vocabulary key, stable forever |
| 26 | `presentation_label` | resolved label (§3.4) | text |
| 27 | `birth_weight_g` | `lambs.birth_weight_g` | integer grams, canonical |
| 28 | `birth_weight_kg` | *derived*: `Grams.inKilograms` | two decimals, `.` separator, e.g. `4.10` |
| 29 | `status` | `lambs.status` | `alive` / `dead` / `stillborn` / `sold` |
| 30 | `death_date` | `lambs.death_date` | `YYYY-MM-DD` or blank. A death with no date is a real state |
| 31 | `death_cause_key` | `lambs.death_cause` | `dc_*` key |
| 32 | `death_cause_label` | resolved label | text. Blank is **unattributed**, never `unknown` — `dc_unknown` is a cause the user picked |
| 33 | `pet_lamb` | `lambs.pet_lamb` | `0` / `1` |
| 34 | `bottle_feeds` | `lambs.bottle_feeds` | integer |
| 35 | `notes` | `lambs.notes` | free text — the column that exercises every quoting rule |

### 3.2 `ewes.csv` — one row per ewe

Rows: every `ewe_seasons` row for the exported season joined to `ewes`, **union** every ewe with `status = 'active'` who has no participation row for that season, emitted with a blank `season_status`. An export that silently omits an animal the shepherd can see in her flock list is the failure this format exists to prevent; a blank cell is honest, an absent row is not. Order: `ewes.tag_digits`, then `ewes.tag`, then `ewes.uid`.

| # | Column | Source | Format |
|---|---|---|---|
| 1 | `ewe_uid` | `ewes.uid` | UUID v7 |
| 2 | `tag` | `ewes.tag` | text **exactly as typed** — never normalised (03 §5.2). `tag_digits` is a projection and is never a CSV column. It *is* in the JSON backup, because the backup carries every column of every exported table (§5.3) and restore writes rows verbatim rather than recomputing them |
| 3 | `eid` | `ewes.eid` | text |
| 4 | `breed` | `ewes.breed` | text |
| 5 | `date_of_birth` | `ewes.date_of_birth` | `PartialDate` as stored: `2023`, `2023-04` or `2023-04-11` |
| 6 | `source` | `ewes.source` | text |
| 7 | `status` | `ewes.status` | `active` / `sold` / `dead` / `culled` |
| 8 | `season_year` | `seasons.year` | integer |
| 9 | `season_label` | `seasons.label` | text |
| 10 | `season_status` | `ewe_seasons.status` | one of the seven stored keys `to_ram` / `scanned` / `lambed` / `barren` / `aborted` / `died` / `sold`; blank when there is no participation row. **Never the four-way `EweSeasonOutcome` bucketing** (R43) — that is a derived view for statistics and does not round-trip |
| 11 | `scanned_count` | `ewe_seasons.scanned_count` | integer or blank |
| 12 | `lambings_recorded` | *derived*: count of her `lambings` in the season | integer |
| 13 | `lambings_scored` | *derived*: `ease IS NOT NULL` | integer |
| 14 | `lambings_scored_assisted` | *derived*: `ease >= 2` | integer. Paired with col 13 so an assisted rate can exclude unscored lambings from **both** sides |
| 15 | `lambs_born` | *derived*: `lambs` by `birth_dam`, all statuses | integer |
| 16 | `lambs_born_alive` | *derived*: excludes `stillborn` | integer |
| 17 | `lambs_stillborn` | *derived* | integer. Its own bucket, never folded into day-0 deaths |
| 18 | `lambs_reared` | *derived*: `lamb_rearing.rearing_dam`, `status = 'alive'` at season end | integer. Aggregated by **rearing** dam, never mixed with cols 15–17, which are by **birth** dam |
| 19 | `first_lambing_at_utc` | *derived*: `MIN(occurred_at)` | ISO or blank |
| 20 | `first_lambing_local_date` | *derived*: `MIN(local_date)` | `YYYY-MM-DD` or blank |
| 21 | `last_lambing_at_utc` | *derived*: `MAX(occurred_at)` | ISO or blank |
| 22 | `observations` | `ewe_observations.kind` labels for the season, `; `-joined | quoted by the `;` rule. `prolapse; poor mothering` |
| 23 | `treatments_recorded` | *derived*: non-voided `treatments` in the season | integer |
| 24 | `latest_meat_clear_date` | *derived*: `MAX(treatment_withdrawals.clear_date)` where `target='meat'` | `YYYY-MM-DD` or blank. **The stored value** (#50) — never recomputed here |
| 25 | `latest_milk_clear_date` | same, `target='milk'` | as above |
| 26 | `notes` | `ewes.notes` | free text |

`ewes.over_free_cap` is **not** exported. It is a monetization marker, not a fact about a sheep. It is in the JSON backup, because the backup is the record and the CSV is a report — and that distinction settles every "does this column belong in the CSV?" argument.

`ewes.csv` carries **counts, not statistics.** No `StatResult` is written into any CSV in v1, so no `definition` string is needed in a CSV trailer. The flock book PDF does render statistics, and it carries the definition verbatim under each one (§4.6). If a future CSV ever carries a computed rate, `CONVENTIONS` §5.4 applies without exception: the `LambingPercentageChoice.definition` string ships beside it, verbatim.

### 3.3 `treatments.csv` — one row per treatment

Rows: every `treatments` row in the season, **including voided ones**. Decision #69: undo for a treatment is a soft void, because the row may already have been printed into a medicine book handed to a vet. The medicine book shows the void; it never loses the row — and neither does the CSV. Order: `administered_at`, then `treatments.uid`.

A treatment has 0..2 `treatment_withdrawals` rows (meat, milk). They are **pivoted into columns**, not unpivoted into rows, because the spec says one row per treatment and because the shepherd reading the file wants one line per bottle.

| # | Column | Source | Format |
|---|---|---|---|
| 1 | `treatment_uid` | `treatments.uid` | UUID v7 |
| 2 | `season_year` | `seasons.year` | integer |
| 3 | `season_label` | `seasons.label` | text |
| 4 | `animal_kind` | *derived* from the two nullable FKs | `ewe` or `lamb`. Exactly one is non-null (03's CHECK) |
| 5 | `animal_tag` | `ewes.tag` or `lambs.tag` | text; blank for an untagged lamb |
| 6 | `animal_uid` | `ewes.uid` or `lambs.uid` | UUID |
| 7 | `product_name` | `treatments.product_name` | text verbatim |
| 8 | `dose_text` | `treatments.dose_text` | text verbatim. **Never parsed, never normalised, never split into a number and a unit.** The app has no opinion about a dose (§12.2) |
| 9 | `route_key` | `treatments.route` | `rt_*` vocabulary key |
| 10 | `route_label` | resolved label | text |
| 11 | `batch_no` | `treatments.batch_no` | text verbatim |
| 12 | `administered_at_utc` | `treatments.administered_at` | ISO-8601 UTC ms `Z` |
| 13 | `administered_at_local` | *derived* | `dd/MM/yyyy HH:mm` |
| 14 | `time_source` | `treatments.time_source` | `auto` / `entered` / `edited` |
| 15 | `time_provenance` | `TimeSource.label` | text |
| 16 | `time_captured_at_utc` | `treatments.captured_at` | ISO |
| 17 | `time_original_effective_utc` | `treatments.original_effective` | ISO or blank |
| 18 | `meat_withdrawal_state` | `treatment_withdrawals.kind` for the `meat` row; *derived* only in the no-row case | `days` / `not_applicable` — the two stored `kind` keys, verbatim — or **`not_recorded`** when the child row is absent. The three states of `WithdrawalPeriod`, never collapsed to a nullable integer |
| 19 | `meat_withdrawal_days` | `treatment_withdrawals.days` | integer or blank. **Blank is never `0`** — `0` is a real label value |
| 20 | `meat_clear_date` | `treatment_withdrawals.clear_date` | `YYYY-MM-DD` or blank. The **stored** value: a record of what the app told the user on the day (#50), never recomputed at export |
| 21 | `meat_withdrawal_source` | `Disclaimers.withdrawalProvenance` when state = `days`, else blank | `as entered by you` |
| 22 | `milk_withdrawal_state` | as col 18 | |
| 23 | `milk_withdrawal_days` | as col 19 | |
| 24 | `milk_clear_date` | as col 20 | |
| 25 | `milk_withdrawal_source` | as col 21 | |
| 26 | `clear_date_disagrees` | *derived*: stored `clear_date` ≠ `clearDateFor(administered_at, days)` | `0` / `1`. `WarningCode.clearDateDisagrees`. **Shown, never applied** (#50) — the export prints the warning column and keeps the stored date |
| 27 | `is_voided` | `treatments.voided_at IS NOT NULL` | `0` / `1` |
| 28 | `voided_at_utc` | `treatments.voided_at` | ISO or blank |
| 29 | `note` | `treatments.note` | free text |

### 3.4 The header rows, verbatim

These three strings are the contract. They are `const` in `export_repository.dart`, asserted by a golden test, and **frozen**: adding a column appends to the end of the list, renaming one is a breaking change to every spreadsheet a shepherd has built on top of it.

```
lamb_uid,season_year,season_label,lamb_tag,sex,birth_dam_tag,birth_dam_uid,rearing_dam_tag,rearing_dam_uid,was_fostered,lambing_uid,born_at_utc,born_at_local,born_local_date,local_date_disagrees,time_source,time_provenance,time_captured_at_utc,time_original_effective_utc,declared_birth_type,lambs_recorded_for_lambing,birth_type_mismatch,lambing_ease,assisted_by,presentation_key,presentation_label,birth_weight_g,birth_weight_kg,status,death_date,death_cause_key,death_cause_label,pet_lamb,bottle_feeds,notes
```

```
ewe_uid,tag,eid,breed,date_of_birth,source,status,season_year,season_label,season_status,scanned_count,lambings_recorded,lambings_scored,lambings_scored_assisted,lambs_born,lambs_born_alive,lambs_stillborn,lambs_reared,first_lambing_at_utc,first_lambing_local_date,last_lambing_at_utc,observations,treatments_recorded,latest_meat_clear_date,latest_milk_clear_date,notes
```

```
treatment_uid,season_year,season_label,animal_kind,animal_tag,animal_uid,product_name,dose_text,route_key,route_label,batch_no,administered_at_utc,administered_at_local,time_source,time_provenance,time_captured_at_utc,time_original_effective_utc,meat_withdrawal_state,meat_withdrawal_days,meat_clear_date,meat_withdrawal_source,milk_withdrawal_state,milk_withdrawal_days,milk_clear_date,milk_withdrawal_source,clear_date_disagrees,is_voided,voided_at_utc,note
```

35, 26 and 29 fields. Every `*_key` column is the stable ASCII vocabulary key that never changes; every `*_label` column is the resolved human wording, which the user may have edited. Both ship, because the key is what a machine joins on and the label is what a human reads, and neither substitutes for the other.

**Where the labels come from.** `lib/data/` cannot reach `AppLocalizations` (layer rule 4 keeps Flutter's widget layer out, and there is no `BuildContext` down there). Neither can a controller: `CONVENTIONS` §4.4 rule 3 says a controller holds no `BuildContext`, and `AppLocalizations.of(context)` needs one. So the resolution happens one layer further out, and the ownership is exact:

1. **The Export screen** — the only object here with a `BuildContext` — builds `Map<String, String> vocabLabels` by walking `vocab_terms` and taking `label ?? <the ARB message for that key>`, the same `label ?? default` rule the rest of the app uses (03 §5.12, decision #61).
2. It passes that map into `ExportWriteController`, which passes it into `ExportRepository` as a parameter.
3. `ExportRepository` treats it as opaque data and never asks where a label came from.

A repository — or a controller — that reached for a localisation would be a layer violation and a lie about where terminology lives. This is the same placement decision #61 already made for vocabulary seeding: the one component that legitimately has a `BuildContext` does the resolving, and hands strings down.

---

## 4. The PDF build

### 4.1 `pdf`, and not `printing`

`pdf` 3.13.0 (nfet.net, verified) — pure Dart, deps `archive`, `barcode`, `bidi`, `crypto`, `image`, `meta`, `path_parsing`, `vector_math`, `xml`. **No HTTP client.**

`printing` 5.15.0 is rejected (decision #83, and it is one of the drops the offline claim in decision-record §3.1 tier 2 depends on): it declares `http >=0.13.0 <2.0.0` and hands every future contributor a one-liner — `PdfGoogleFonts.robotoRegular()`, `networkImage(...)` — that quietly turns the app into a networked app on iOS, where there is no permission gate to stop it. Gate G3 greps for both identifiers on every push.

The cost is stated honestly and is not hidden: **there is no in-app print dialog** (decision-record §4, spec §7.9 "printable" is *degraded*). Delivery is the share sheet; printing is the OS Print action from inside it. See §8.2.

### 4.2 The font — embedding is mandatory, not an optimisation

The base-14 PDF fonts (`Font.helvetica()`, `Font.times()`, `Font.courier()`, …) are Latin-1/WinAnsi only. `°` (U+00B0) and `£` (U+00A3) happen to be inside Latin-1 and survive. What does not: the curly quotes and en-dashes an iOS keyboard inserts *automatically* (`'`, `"`, `–`), the ellipsis `…`, `℃` (U+2103), Welsh `ŵ`/`ŷ`, Irish fadas, and any emoji. `dart_pdf`'s own Fonts Management wiki says to switch to a Unicode font "as soon as you need specific accents"; issues [#810](https://github.com/DavBfr/dart_pdf/issues/810), [#252](https://github.com/DavBfr/dart_pdf/issues/252) and [#405](https://github.com/DavBfr/dart_pdf/issues/405) are the resulting crash — *"Helvetica has no Unicode support"*, *"Can not decode the string to Latin1"*.

A shepherd typing a free-text note at 3am on a phone keyboard will produce all of those. **A crash while exporting the medicine record for a vet visit is a catastrophic failure of the one safety feature the app has.** So:

> **Always embed a TTF. Never construct a base-14 font anywhere in this app.** Policy rule `export.base_14_font` (§9) bans `Font.helvetica`, `Font.times`, `Font.courier`, `Font.symbol` and `Font.zapfDingbats` under `lib/`.

**Which TTF.** Reuse the app's own face — `assets/fonts/AtkinsonHyperlegibleNext[wght].ttf` (decision #98, SIL OFL 1.1) — rather than shipping a second family against the < 5 MB asset budget (#127).

**Unverified, and it must be checked before the flock book is written:** whether `pdf` 3.13.0's TTF parser accepts a *variable* font file, and if so which instance it embeds. The `pdf` package has its own parser; a `[wght]` variable file carries `fvar`/`gvar` tables that a static-only parser may ignore, mis-render or reject. The check is twenty minutes: build a one-page document with `pw.Font.ttf(ByteData.sublistView(fontBytes))`, write it, open it in Preview and in Acrobat, and confirm the glyphs and the metrics.

> **`ByteData.sublistView(fontBytes)`, never `fontBytes.buffer.asByteData()`.** `.buffer` hands back the *whole* backing store and throws away the view's `offsetInBytes` and `lengthInBytes`. A `Uint8List` is a *view*, not necessarily a whole buffer: one derived from the `ByteData` that `rootBundle.load(...)` returns, or from any slice, is not guaranteed to start at offset 0 — and when it does not, the parser is handed the wrong bytes and fails somewhere deep inside a table offset, with an error that names neither the font nor the offset. The same rule runs in the other direction on the way in: `Uint8List.sublistView(byteData)`, never `byteData.buffer.asUint8List()` (§4.4).

- **If it works:** build the whole document at one weight. Hierarchy comes from size, rules and spacing, not from bold. This is not a compromise — decision #98 already caps weight at w700 and `pdf` has no synthetic bold, so a single-weight document is the honest design either way.
- **If it does not:** commit two static instances (`AtkinsonHyperlegibleNext-Regular.ttf`, `-Bold.ttf`) beside the variable file, use them for the PDF only, and count the extra ~200–400 KB against the asset budget in `docs/perf/measurements.md`.

**Also unverified:** whether `pdf` subsets the embedded face or writes the whole thing into every document. If it does not subset, every generated PDF carries the full font (~114 KB for the variable file, more for two static faces). Acceptable either way — but measure it before promising a printable flock book by email, because the number lands in someone's inbox.

`OFL.txt` ships beside the font and `LicenseRegistry.addLicense` registers it (06 §5.2). Nothing is fetched, ever.

### 4.3 One builder, and the gate that enforces it

`lib/data/pdf_writer.dart` is the **only** file in the app permitted to say `pw.Document(` or `pw.MultiPage(`. That is policy rule `export.pdf_document`, and it is the mechanism that makes "every page of every PDF carries the disclaimer" a structural property rather than a review item:

```dart
// lib/data/pdf_writer.dart — the only pw.Document( / pw.MultiPage( site.
Future<Uint8List> _buildDocument({
  required ExportEnvelope envelope,
  required String title,
  required List<pw.Widget> Function(pw.Context) body,
  required pw.Font base,
  pw.Widget? titleBoxUnderHeading,          // medicine record only (§4.7)

  // TEST ONLY. §6.4's byte assertion needs an uncompressed document.
  // NOT annotated @visibleForTesting: that annotation has no parameter
  // target and the analyzer rejects it there. The guard is the review of
  // the one file `export.pdf_document` confines this code to.
  bool compress = true,
}) {
  final doc = pw.Document(
    title: title,
    author: 'Shed Book ${envelope.appVersion}',
    subject: envelope.disclaimer,           // greppable in the bytes — see §6.4
    compress: compress,
  );
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    theme: pw.ThemeData.withFont(base: base),
    header: (c) => _runningHeader(c, title),
    footer: (c) => _runningFooter(c, envelope),   // NOT optional, NOT a parameter
    build: (c) => [
      // The box is page-1 furniture, so it is prepended here rather than
      // being the caller's job to remember. `pageNumber` is 1-based.
      if (titleBoxUnderHeading != null && c.pageNumber == 1) titleBoxUnderHeading,
      ...body(c),
    ],
  ));
  return doc.save();   // Future<Uint8List> — materialises the whole document (§4.9)
}
```

`footer:` is set inside `_buildDocument` and is not reachable from a caller. There is no code path that produces a Shed Book PDF without it. The `subject:` line is the second belt: PDF document-information strings are written as string objects rather than as glyphs, so a byte-level test can prove the disclaimer is in the file even though the *drawn* text is glyph-indexed and therefore not greppable (§6.4). **That last step is unverified against `pdf` 3.13.0 itself** — it follows from the PDF format, not from a measurement of the package — and it is §10 row 13.

`compress:` is a parameter for exactly one reason — §6.4's byte assertion runs against an uncompressed document. Nothing else about the signature is optional, and nothing else about it is reachable from a caller.

### 4.4 Off the UI isolate

Decision #125: **only** PDF generation and image downscaling run off-isolate. CSV and JSON at this volume are milliseconds and stay on the main isolate; isolating them would buy nothing and cost a copy.

A drift connection cannot cross an isolate boundary. So the split is:

1. **Main isolate** — `ExportRepository` runs the reads and materialises plain data. The domain value types are already sendable *because* they are extension types over `int` and `String`: an `Instant` is an `int` at runtime, a `LocalDate` is a `String`. Nothing needs converting.
2. **Main isolate** — the export write controller loads the font with `rootBundle.load(...)`, which returns a `ByteData`, and converts it with `Uint8List.sublistView(data)` — not `data.buffer.asUint8List()`, for the offset reason in §4.2. `rootBundle` needs the root isolate's binary messenger; it is never called from `compute`.
3. **`compute(buildFlockBookPdf, payload)`** — the isolate builds the document **and writes the file**, returning only `({String path, int byteSize})`.

Point 3 is the part that is easy to get wrong. Returning `Uint8List` from `compute` copies it across the isolate boundary, so a 40 MB document costs 80 MB at the exact moment you are trying not to run out of memory. The isolate has `dart:io`; let it write. **Nothing but a path and a byte count crosses back.**

```dart
// lib/data/pdf_writer.dart — a top-level function, as compute() requires.
typedef PdfJob = ({
  String outPath,
  String title,
  ExportEnvelope envelope,
  Uint8List fontBytes,
  List<List<String>> rows,        // already formatted; no domain logic here
  List<String> columnHeaders,
  List<(String label, String value, String definition)> stats,
});

Future<({String path, int byteSize})> buildFlockBookPdf(PdfJob job) async {
  final bytes = await _buildDocument(
    envelope: job.envelope,
    title: job.title,
    base: pw.Font.ttf(ByteData.sublistView(job.fontBytes)),   // §4.2, not .buffer
    body: (c) => _flockBookBody(job),
  );
  final f = await File(job.outPath).writeAsBytes(bytes, flush: true);
  return (path: f.path, byteSize: bytes.length);
}
```

`rows` is `List<List<String>>` — fully formatted before it crosses. The isolate does no unit conversion, no date formatting and no terminology resolution, because it has no `WeightUnit`, no `Terminology` and no ARB. Formatting on the main isolate and shipping strings is also what keeps the isolate payload free of anything that could throw halfway through a document.

### 4.5 Page furniture

Every Shed Book PDF has the same anatomy. A4 landscape, because §7.0 rules UK/Ireland first; if the first market ever changes, `PdfPageFormat.letter` is a one-line change and belongs beside the locale defaults, not scattered.

| Element | Content |
|---|---|
| **Front matter** (page 1 only) | Title: `Shed Book — <season label>` and the document name. Generated: `27 Jul 2026 21:04 (IST, UTC+01:00)` — `d MMM y HH:mm`, never all-numeric (R60). App version. Row counts. For the flock book: the season statistics block (§4.6) |
| **Running header** (every page) | `<season label> · <document name> · part N of M` if split, left; nothing else. One hairline rule under it |
| **Table header row** | Repeated on every page the table spans. `pw.TableHelper.fromTextArray(headerCount: 1, …)` — **verify against `pdf` 3.13.0**: `Table.fromTextArray` moved to `TableHelper` in an earlier major and the header-repeat behaviour inside `MultiPage` is the specific thing to confirm |
| **Rows** | Hairline rule between rows. **No fills, no zebra striping** — grey fills cost toner and reduce contrast on the cheap mono laser this will actually be printed on |
| **Running footer** (every page) | `Disclaimers.exportFooter` at 7 pt across the full width, left; `Page N of M` right. Set by `_buildDocument`, unreachable from a caller |

Text sizes: 9 pt table body, 8 pt for the widest tables, 7 pt footer, 16 pt title. These are **print** sizes and have nothing to do with the 18 pt on-screen floor (decision #98) — a document read in daylight at arm's length is not a screen read at 3am with wet gloves. Say so in the code comment, because the next reader will otherwise "fix" it.

Photos are **never** embedded in any PDF (decision #83). Media goes out as a separate share (§8.4).

### 4.6 The flock book

**Two volumes, always** — `flock-book-ewes` and `flock-book-lambs`. This is the shape, not a fallback: a combined 400-ewe/900-lamb book is the OOM case, and the two documents have different readers (the ewe book is the flock record; the lamb book is the season's output).

**Front matter, ewes volume — the statistics block.** One line per statistic, and every line prints:

```
Lambing percentage            165%
                              lambs born alive per ewe put to the ram
                              660 lambs born alive ÷ 400 ewes put to the ram
```

The middle line is `StatResult.definition`, **verbatim**, from `LambingPercentageChoice.definition` (R61). It is not paraphrased, not shortened, and not replaced by a formula — the formula may appear *alongside* it, as the third line does. This string outlives the app: someone will read this PDF in 2033 and needs to know which of the two conventions produced 165%. When `StatResult.value` is null, the line prints `not computable — <notComputableReason>` and never `0` and never `—`. `?? 0` on a nullable aggregate is a review-blocking defect.

**Ewes volume table** — order `tag_digits`, `tag`:

| Tag | Born | Breed | Status | Season outcome | Lambings | Born | Alive | Reared | Assisted | Observations |

**Lambs volume table** — order birth dam, then birth time:

| Tag | Birth dam | Rearing dam | Born | Sex | Birth type | Ease | Weight | Status | Died | Cause | Note |

`Born` is **`d MMM HH:mm`** — `14 Mar 03:20` — with a provenance mark: an asterisk suffix for `entered`, a dagger for `edited`, nothing for `auto`, and a legend in the front matter spelling out all three using `TimeSource.label`. **Not `dd/MM HH:mm`.** A PDF is read by a human, so R60 and decision #108 apply with no exception: numeric dates exist only inside a CSV, beside an ISO-8601 column, and there is no ISO column in a PDF. The year is omitted rather than abbreviated because the volume is season-scoped and the season label is in the running header on every page. `Weight` is the **display** unit from `unitsProvider` — `4.10 kg` or `9 lb 0 oz` — because a PDF is a document a human reads (§2.5). `Sex` renders `—` for a null and `unknown` for the recorded `unknown`; the two are never merged.

### 4.7 The medicine record

The one somebody hands to a vet or an inspector, which makes it the artifact where §12.1 and §12.3 matter most.

Under the title, a **boxed statement** — required by 05 §7.4 for this document and no other:

```
┌──────────────────────────────────────────────────────────────────────────┐
│ Shed Book is a personal notebook. It is not a statutory medicine record,  │
│ holding register, or movement record, and must not be presented as one.   │
│ All entries are as recorded by the user.                                  │
│                                                                           │
│ Withdrawal period as entered by you from the product label. Shed Book     │
│ does not know any product and suggests no value. Check the label.         │
└──────────────────────────────────────────────────────────────────────────┘
```

Both strings are `Disclaimers.exportFooter` and `Disclaimers.withdrawalCaveat`, referenced. The box is in addition to the running footer, not instead of it.

**Table** — order `administered_at` ascending:

| Date | Animal | Product | Dose | Route | Batch | Meat withdrawal | Clear (meat) | Milk withdrawal | Clear (milk) | Note |

- `Date` is `d MMM y HH:mm` plus the provenance mark (R60 — no all-numeric human-facing date, and this is the document where a misread date is worst).
- `Meat withdrawal` renders `28 days (as entered by you)`, `not applicable`, or `not recorded`. The parenthetical is `Disclaimers.withdrawalProvenance`. There is no fourth rendering and there is never a blank cell that a reader could take for zero.
- `Clear (meat)` is the **stored** `clear_date`, formatted `d MMM y`. If `clear_date_disagrees`, the cell renders the stored date followed by `(see app)` — the PDF warns, it does not recompute (#50, §12.4).
- A voided treatment renders with a strike-through and a `VOID <d MMM y>` marker in the Note column. **The row is never removed.**

Row counts here are tens, not thousands, so the medicine record is never split.

### 4.8 Splitting and the row cap

```dart
// lib/data/export_limits.dart
/// UNVERIFIED. A working bound until peak RSS is measured on the low-end
/// target device (§10). At 8 pt landscape A4 this is roughly 50 pages.
const int kPdfRowsPerVolume = 2000;
```

When a volume exceeds the cap, split on a row boundary into `…-lambs-1.pdf`, `…-lambs-2.pdf`, each with `part N of M` in the running header, and tell the user plainly on the Export screen: *"This season is too large for one file. Exporting as 3 files."* An honest message beats a crash; a crash during "export my season" is precisely the moment the user is trying to protect their data.

Never truncate silently. Never render "and 431 more rows". Every row that exists goes into a file.

### 4.9 Memory

`pw.Document.save()` materialises the whole document as a `Uint8List`, and `pw.MultiPage` builds its widget tree before paginating. A 400-ewe / ~900-lamb season is roughly 60–120 pages of text-only tables: the output PDF is a few MB, but peak Dart heap during layout is **plausibly 100–200 MB** (decision #83; the figure is an estimate, not a measurement). On a €150 Android phone in a cold shed with the camera app still resident, that is an OOM kill.

The five mitigations, all cheap, all already stated above: no photos ever; two volumes always; the row cap; build on a `compute` isolate; and the isolate writes the file so no byte list is copied back. Do not add a sixth mechanism before measuring — §10 names the measurement.

---

## 5. The JSON backup envelope

### 5.1 What it is

JSON is *the* backup and *the* restore format (decision #84; spec §7.9 names JSON only). It is cross-device, inspectable in a text editor, and the only format that survives a schema change between the exporting app and the importing app. `VACUUM INTO` is a diagnostics snapshot, not a backup (04 §8). `File.copy` of the database is a bug — in WAL mode the database is three files.

**Records-only for v1** (decision #85). Media bytes are not in the file; the header records what was left behind so the restore screen can be honest about it. `ZipFileEncoder` does exist in `package:archive/archive_io.dart` alongside `OutputFileStream`, but its incremental-write behaviour is **still unverified** — no media-in-ZIP design is attempted until that check is done and recorded (§10).

**Three things, three words, because R65 exists precisely to stop two of them merging.** The **envelope** is the whole `.json` file, header and `tables` together — it is the word the spec and decision-record §8 use for this document's scope and it names a file, never a type. **`BackupHeader`** is the type behind the header block (`format` / `formatVersion` / `schema` / `counts` / `checksum`); 04's prose calls it "the backup header" and never "the envelope" (R65). **`ExportEnvelope`** is a third, unrelated thing: the disclaimer-bearing value in `lib/domain/policy/export_envelope.dart` that *every* writer takes, CSV and PDF included. If a sentence in this document would read the same with two of those three swapped, it is wrong.

### 5.2 The envelope, top to bottom

```jsonc
{
  "_disclaimer": "Shed Book is a personal notebook. It is not a statutory medicine record, holding register, or movement record, and must not be presented as one. All entries are as recorded by the user.",
  "_withdrawalNotice": "Withdrawal period as entered by you from the product label. Shed Book does not know any product and suggests no value. Check the label.",
  "format": "shed-book-backup",
  "formatVersion": 1,
  "schema": 3,
  "appVersion": "1.2.0+41",
  "exportedAtUtc": "2026-07-27T21:04:11.482Z",
  "exportedAtOffsetMinutes": 60,
  "exportedAtZoneAbbreviation": "IST",
  "checksum": { "algorithm": "fnv1a64", "value": "9f2b1c04a77e3d51" },
  // ONE ENTRY PER KEY IN `tables` — all 21, always, zeros included. Elided
  // here for length. §5.7's count check is per table and cannot be partial:
  // a table absent from `counts` is a table nothing verifies.
  "counts": { "seasons": 3, "ewes": 412, "ewe_seasons": 1204, "lambings": 398,
              "lambs": 861, "treatments": 145, "media_assets": 452, … },
  "media": { "included": false, "count": 452, "bytes": 297103882 },
  "tables": {
    "app_settings": [ … ], "care_events": [ … ], "ewe_observations": [ … ],
    "ewe_seasons": [ … ], "ewe_touches": [ … ], "ewes": [ … ],
    "foster_events": [ … ], "lambings": [ … ], "lambs": [ … ],
    "media_assets": [ … ], "notes": [ … ], "pen_occupancies": [ … ],
    "pen_occupancy_lambs": [ … ], "pens": [ … ], "reminder_rules": [ … ],
    "reminders": [ … ], "seasons": [ … ], "terminology_overrides": [ … ],
    "treatment_withdrawals": [ … ], "treatments": [ … ], "vocab_terms": [ … ]
  }
}
```

Twenty-one tables. Two of the twenty-three row classes in `lib/data/models.dart` are excluded (§5.4), and the FTS5 pair are not row classes at all.

`_disclaimer` is the **first** key — 05 §7.4 fixes that placement and the golden test is written against it — and `_withdrawalNotice` is the second, which is 09's own ruling, not 05's: 05 places only the §12.3 string. 04 §6.2's `"notice"` is a stale spelling and must change (§1.3). `formatVersion` is the *header's* version and is independent of `schema`, which is the database's `kSchemaVersion`; conflating them is what makes a format unfixable later.

**Key order in the header is fixed by hand, and only the header.** The thirteen header keys are written in the order printed above by `headerPrefixJson` (§5.7) — that is what puts `_disclaimer` first and `tables` last, and last is what lets the writer stream `tables` straight out without buffering it twice. Canonical key sorting applies to the `tables` **value** and nothing else, because that is the only part the checksum covers.

### 5.3 A real row, and the two key conventions

**Header keys are `camelCase`. Every key inside `tables` is a SQLite column name in `snake_case`.** That is a rule, not an accident: the header is our metadata and the table rows are the database's, and a reader can tell which is which at a glance.

The keys below are in **canonical order — sorted ascending by code unit**, which is the order they appear in the file and the order the checksum is computed over. Reading them in schema order would be friendlier and would make the printed example a lie; a developer must be able to hold this row beside `jq` output and see the same sequence.

```jsonc
"treatments": [
  {
    "administered_at": "2026-03-14T03:20:42.015Z",
    "batch_no": "A7742",
    "captured_at": "2026-03-14T03:20:42.015Z",
    "created_at": "2026-03-14T03:20:42.015Z",
    "dose_text": "6 ml",
    "ewe_uid": "019523ab-2f81-7c04-9a13-6de0b1c48e92",
    "lamb_uid": null,
    "note": "left flank",
    "original_effective": null,
    "product_name": "Alamycin LA",
    "route": "rt_subcutaneous",          // a vocabulary key, NOT route_uid
    "season_uid": "019523aa-4c10-7ff2-b8d1-0a4e9c2f1b77",
    "time_source": "auto",
    "uid": "019524f7-8a1c-7b3e-9f04-2c9a1e7d55b0",
    "updated_at": "2026-03-14T03:20:42.015Z",
    "voided_at": null
  }
]
```

There is no `"id"` and no `"unknown_json"`. Both omissions are rules, below.

The field rules, from 04 §6.3, restated as instructions because half of them are export-side:

| Rule | Instruction |
|---|---|
| Identity is `uid`, never `id` | Integer primary keys are **never** written. Each FK column pointing at a row is emitted with `_uid` appended to 03's bare-noun name: `ewe` → `ewe_uid`, `lambing` → `lambing_uid`, `season` → `season_uid`, `birth_dam` → `birth_dam_uid`. The value is the parent row's `uid`. Import is an upsert on `uid` (#32), never on `tag` |
| **A vocabulary FK is the exception, and it is not a `_uid`** | `lambings.presentation`, `lambs.death_cause`, `treatments.route`, `ewe_observations.kind` and `foster_events.method` are foreign keys onto **`vocab_terms.key`**, not onto a row id. The key *is* the identity — 03 §5.12: "globally unique, list-prefixed, ASCII, stable forever… it is never translated and never edited" — so the column keeps its own name and its own value: `"route": "rt_subcutaneous"`, never `"route_uid"`. Rewriting them as uids would make the file unreadable to a human and would re-key on the one column guaranteed never to change |
| **Five tables have no `uid`, and each has a written natural key** | `with Identified` is not on every table (03 §5). For these five the natural key is emitted instead and the integer `id`, where one exists, still is not: **`app_settings`** — a singleton, PK `id = 1`, emitted as one keyless object and imported onto the single row; **`ewe_touches`** — PK `{ewe}` → `ewe_uid`; **`pen_occupancy_lambs`** — PK `{occupancy, lamb}` → `occupancy_uid` + `lamb_uid`; **`reminder_rules`** — PK `{kind}` → `kind`, a stored key; **`terminology_overrides`** — PK `{key}` → `key`. These are also the five tables §7.2's `ORDER BY uid` does not cover |
| Instants are ISO-8601 UTC | `"2026-03-14T03:20:42.015Z"` — always milliseconds, always `Z`. Stored as `INTEGER` epoch millis (#29); the round trip is exact and property-tested. `created_at` and `updated_at` are the mixin's own instants and follow the same rule |
| Civil dates pass through | `"2026-03-14"`. A civil date never acquires a time or a zone on the way through the file |
| Provenance travels as a unit | `occurred_at` / `captured_at` / `original_effective` / `time_source` — all four or none. A backup that drops them launders an edited timestamp into an auto-captured one: a §12.5 violation committed by the file format |
| No floating-point numbers | Mass is integer grams, temperature integer milli-°C (#56); statistics are derived, never stored. Asserted by a test over the encoded body — and it removes the hardest canonicalisation problem in §5.7 |
| Booleans are `0`/`1` | The column is `INTEGER` under `STRICT`; the file mirrors the column |
| Every column is emitted, `null` included | Never omit a null column. An omitted key and an explicit `null` mean the same thing to the importer, but only one of them round-trips byte-for-byte (§7.2) |
| **`unknown_json` is the one column never emitted under its own name** | It is a container, not a fact. Its parsed contents are merged into the row object at the top level *before* the keys are sorted, so a field this build does not understand comes back out exactly where it went in (§5.5, §7.2 item 8). Emitting the column itself as well would write every preserved field twice — once splatted, once as a JSON string inside `"unknown_json"` — and the second export would nest it again |
| Text is verbatim | No trimming, no case folding, no Unicode normalisation. `dart:convert`'s minimal escaping and nothing more |

### 5.4 What is in, and what is out

| Excluded | Why |
|---|---|
| **Media bytes** | Records-only for v1 (#85). The header carries the count and total size so restore can say what is missing |
| **`entitlements`** | Never exported, ignored if present on import (#88). Restoring your neighbour's backup must not unlock your app. Tested in both directions with a fixture whose `unlocked` is `1` |
| **`ewe_summaries`** | A rebuildable cache (03 §5.13), rebuilt wholesale after a restore. Exporting it would also break §7's round trip immediately, because `rebuilt_at` moves |
| **`search_docs`, `search_fts` and the FTS5 shadow tables** | Derived. `search_docs` refills from the source-table triggers as rows are inserted; `search_fts` is rebuilt in one statement afterwards. Exporting them double-indexes on restore |
| **SQL views** (`lamb_rearing`, `lambing_consistency`, …) | Derived by definition |
| **The diagnostics log** | A redacted local file with its own explicit share action (#123). Not part of the user's records |
| **`sqlite_sequence`** | An `AUTOINCREMENT` implementation detail; the importer re-issues integer ids anyway |

**Every other table is in the backup.** If you add a table, it is exported unless you write down why not, in this list, in the same commit. `vocab_terms` is the cautionary tale: it was missing from 04's original list, and a user-added vocabulary term (`origin = 'user'`) that is not in the file makes the restore fail its own `PRAGMA foreign_key_check` — the failure lands on the night someone is restoring onto a replacement phone.

### 5.5 Forward compatibility

| Situation | Behaviour |
|---|---|
| `formatVersion` > the app's known `BackupHeader` version | **Refuse.** *"This backup was made by a newer version of Shed Book. Update the app and try again."* |
| `schema` > the app's `kSchemaVersion` | **Refuse**, same wording (#73). Guessing at a newer schema is §12.4 applied to restore |
| `schema` < the app's `kSchemaVersion` | **Accept.** This is the normal case — a 2027 backup restored onto a 2029 app. The importer writes into today's schema (§5.6) |
| A column in the file that today's table does not have | **Preserve** it into that row's `unknown_json` and **re-emit** it on the next export |
| A column today's table has that the file does not | Apply the declared `importDefaults` entry (§5.6) |
| An unknown *table* in `tables` | Preserve the whole array into `app_settings.unknown_json` under its table name, and log it. Never drop it silently |

The asymmetry is the point and it is worth stating plainly: **a newer file opened by an older app is refused; an older file opened by a newer app is accepted.** Refusing forward is the only §12.4-compatible answer — an older app cannot know what a newer column means, and guessing is silently corrupting a record. Accepting backward is what makes the backup a backup at all.

`unknown_json` is a nullable `TEXT` column on every restorable table, `NULL` in the normal case, with `CHECK (unknown_json IS NULL OR json_valid(unknown_json))`. Its narrow job: it makes an **import → export round trip lossless**, so a user who restores onto an older build and re-exports has not silently destroyed a newer field. It is not a mechanism for importing from the future.

**It is not in 03's schema yet.** 04 §6.5 and this section are both written against a column no table declares — see the 03 row in §1.3. Every "Preserve" cell in the table above is inert until it lands, and "preserve" silently degrades to "drop", which is the exact failure the column exists to prevent. It is nullable, so a later migration would work; land it in schema v1 anyway, because until then the forward-compatibility contract is a promise the file format cannot keep.

### 5.6 Surviving a schema migration

The exporter always writes today's schema; the importer always writes into today's schema. The only hard case is a column that exists today and did not exist in the backup, and it has one rule:

> **Any migration that adds a `NOT NULL` column with no database default must add an entry to `lib/data/import_defaults.dart` in the same commit.**

CI proves the map is complete: a test reads `drift_schemas/drift_schema_v<kSchemaVersion>.json`, enumerates every `NOT NULL` column with no `defaultValue` and no `clientDefault`, and asserts each is a primary key, a `uid`, or present in `importDefaults`. That single test is what stops a v4 app refusing to restore a v2 backup on the night it matters.

Two rules keep it tractable: **column renames are banned** (a rename needs a per-version alias map, which is a second migration surface), and **a column's fallback may never be a domain value**. A treatment imported from a schema that predates `treatment_withdrawals` produces **no** withdrawal row, which the sealed type reads as `WithdrawalNotRecorded`. That is the correct answer and the only correct answer — §12.1 is enforced by the *absence* of a row, and an import default would be the one place it could be defeated.

### 5.7 The checksum, and how the file is written

The backup carries a **corruption check, not a tamper check**, and neither the export screen nor this document may imply otherwise. Banned words: "verified", "secure", "authentic" (`CONVENTIONS` §5.3).

- `checksum.value` is FNV-1a 64-bit over the UTF-8 bytes of the **canonical** encoding of the `tables` value: object keys sorted ascending by code unit, no insignificant whitespace, integers only (§5.3 guarantees no doubles). About fifteen lines of Dart, no dependency, deterministic.
- A cryptographic digest would need `crypto`, which is **not a direct dependency in decision-record §5.1**. It does sit in the lockfile — `pdf` declares it (§4.1) — and that is precisely why the rule has to be stated rather than assumed: gate G2's transitive allowlist records what is *in the graph*, and it is not a licence to import from it. Reaching for a transitive dependency is how a package becomes load-bearing without ever being audited. If a real digest is ever required, audit `crypto` by c1's method and promote it into decision-record §5.1 first.
- `counts` per table must equal the number of rows parsed, and then the number of rows inserted. Two independent comparisons.
- Any failure aborts **before** the restore confirmation screen is shown, with the reason. Refuse a corrupt file; never half-import one.

**The whole file is written compactly, with a single trailing newline, and the `tables` value is written in canonical form.** Not pretty-printed. Two reasons: indentation roughly doubles the bytes and the peak heap at exactly the moment 04 §6.8's 20 MB tripwire is about to bite, and — more usefully — the `tables` value as it appears in the file *is* the canonical encoding, byte for byte, so the checksum is reproducible by a human with `jq` and `xxd`. The header is the fixed-order prefix of §5.2 and is deliberately outside the canonical rule and outside the checksum; it is the part that legitimately differs between two exports of the same database.

The writer encodes `tables` **once**:

```dart
final tablesBytes = canonicalJsonBytes(tables);            // the only encode
final checksum    = fnv1a64Hex(tablesBytes);
final sink = File(outPath).openWrite();
sink.add(utf8.encode(headerPrefixJson(header, checksum))); // '{"_disclaimer":…,"tables":'
sink.add(tablesBytes);
sink.add(utf8.encode('}\n'));
await sink.close();
```

Encoding `tables` twice — once for the checksum and once for the file — is the obvious implementation and it doubles peak memory on the largest artifact the app produces. It is also how the two can silently diverge.

At 400 ewes over three seasons the file is low single-digit MB and `jsonEncode` is milliseconds; ten seasons is plausibly 20–50 MB. **The tripwire:** if the encoded backup exceeds `kBackupSizeTripwireBytes` (20 MB), measure before assuming it is still fine. If it grows past it, the fix is a streaming writer emitting one table at a time to the `IOSink` above — not an isolate, because a drift connection cannot cross an isolate boundary (#125).

---

## 6. The §12 disclaimer footers

### 6.1 The exact strings

They live in **one file**, `lib/domain/policy/disclaimers.dart`, as `const`s on an `abstract final class` — which cannot be instantiated *or* extended, so nobody can subclass it and shadow a string. They are deliberately **not** in the ARB: a translator can soften or drop an ARB message and the app has no mechanism to notice.

```dart
abstract final class Disclaimers {
  /// Spec §12.3 — never present the app as a compliance or regulatory record.
  static const String exportFooter =
      'Shed Book is a personal notebook. It is not a statutory medicine '
      'record, holding register, or movement record, and must not be '
      'presented as one. All entries are as recorded by the user.';

  /// Spec §12.1 — the withdrawal period's provenance, four words.
  static const String withdrawalProvenance = 'as entered by you';

  /// Spec §12.1, long form.
  static const String withdrawalCaveat =
      'Withdrawal period as entered by you from the product label. '
      'Shed Book does not know any product and suggests no value. '
      'Check the label.';
}
```

### 6.2 Why they cannot be dropped from an export

Not "remember to append the footer" — three structural mechanisms, in order of strength:

1. **`ExportEnvelope` cannot be constructed without the disclaimer.** Its generative constructor is private and `ExportEnvelope.standard({required Instant now, required String appVersion})` is the only factory. `disclaimer` is not a parameter of it, so no caller can pass an empty string, a placeholder, or a "short version for this one file".
2. **Every writer signature takes an `ExportEnvelope`.** `CsvWriter`'s constructor takes one; `_buildDocument` takes one; `ExportRepository.writeBackup` takes one. There is no writer that does not.
3. **Each writer emits the footer from its own frame, not from its caller's.** `CsvWriter.encode` appends the trailer itself; `_buildDocument` sets `footer:` itself, and `pw.Document(`/`pw.MultiPage(` may not appear anywhere else. A caller cannot forget what it was never asked to do.

Plus the ban on re-typing: `ContentPolicy.allowlist` is keyed by `Disclaimers.exportFooter` rather than by a literal, and the `copy.disclaimer_retyped` policy rule enforces it. This caught a real duplication while the research was being written — the banned-phrase allowlist had re-typed the string it exists to permit.

### 6.3 Placement per artifact

| Artifact | §12.3 `exportFooter` | §12.1 `withdrawalCaveat` / `withdrawalProvenance` | §12.5 |
|---|---|---|---|
| `lambs.csv` | trailer row 1 | trailer row 2 (decision #82: the §12.1 **and** §12.3 trailers on all three shapes) | trailer row 3 + the `time_source` / `time_provenance` columns |
| `ewes.csv` | trailer row 1 | trailer row 2 | trailer row 3 |
| `treatments.csv` | trailer row 1 | trailer row 2, plus `Disclaimers.withdrawalProvenance` as the value of `meat_withdrawal_source` / `milk_withdrawal_source` | trailer row 3 + the four provenance columns |
| Flock book PDF | **footer on every page**, 7 pt | — | the provenance mark on every `Born` cell + a legend in the front matter |
| Medicine record PDF | **footer on every page + a boxed statement under the title** | both strings in the box; `withdrawalProvenance` in every withdrawal cell | provenance mark on every `Date` cell + the legend |
| JSON backup | `"_disclaimer"`, the **first** top-level key | `"_withdrawalNotice"`, the second | the four provenance columns on every table that has them |
| Export screen | verbatim, above the buttons (07 §13.4) | on the treatments and medicine-book rows | one line of copy |

The §12.5 trailer line is **built from `TimeSource.values.map((s) => s.label)`**, not typed out. If a fourth `TimeSource` is ever added, the trailer updates itself and the exhaustive-switch test in 05 §4.4 catches anything that did not. A hand-typed list of three labels is a list that goes stale silently.

### 6.4 The tests that prove it

Three, in `test/policy/`, named for the property rather than the file (`CONVENTIONS` §4.1):

```dart
// test/policy/disclaimer_is_defined_once_test.dart  — 05 §7.4's test, unchanged.
test('SAFETY RULE 3: the disclaimer exists in exactly one file', () {
  final hits = dartFilesUnder('lib/')
      .where((f) => joinedStringLiterals(f)
          .contains(RegExp(r'statutory\s+medicine|holding\s+register')))
      .toList();
  expect(hits, ['lib/domain/policy/disclaimers.dart']);
});
```

> **The gotcha, found during the research and not theorised:** a naive `file.contains('some long phrase')` scan **misses long strings**, because Dart wraps them across adjacent string literals and the phrase is never contiguous in the source. `joinedStringLiterals` extracts literals and joins them before matching. Any scanner in this project that greps for a sentence has the same bug unless it does this.

```dart
// test/policy/every_export_carries_the_footer_test.dart
// One fixture DB with three lambings, one treatment with a meat withdrawal,
// and ONE EMPTY DB. Six artifacts × 2 databases = 12 assertions.
for (final artifact in allArtifactKinds) {
  test('$artifact carries the §12.3 footer, empty database included', () async {
    for (final db in [seededDb, emptyDb]) {
      final bytes = await buildArtifact(artifact, db);
      expect(containsDisclaimer(artifact, bytes), isTrue);
    }
  });
}
```

`containsDisclaimer` is per-format, and the PDF case is the one that surprises people:

- **CSV / JSON** — a UTF-8 byte search for `Disclaimers.exportFooter` finds it directly.
- **PDF** — **a byte search for the drawn text does not work.** Text drawn with an embedded TTF is written as glyph indices into that font's encoding, so the sentence is simply not present in the bytes, compressed or not. This is why `_buildDocument` also puts the string in the document-information `subject:`, which `pdf` writes as a PDF string object. The test builds the same document with `compress: false` (the test-only parameter in §4.3 exists for this and nothing else) and asserts the raw bytes contain the UTF-8 of `subject`. That proves the string reached the file; the *drawn* footer is proved structurally instead, by `export.pdf_document` (§9) — there is exactly one `pw.MultiPage(` in the codebase and it always sets `footer:`, so a reviewer checks one line, once.

  **The byte assertion depends on `Disclaimers.exportFooter` being pure ASCII, and today it is.** A PDF string object holds non-ASCII text as UTF-16BE behind a byte-order mark, at which point a UTF-8 search finds nothing and the test goes green for the wrong reason — a silently passing safety test is worse than a failing one. So: the §12.3 string stays ASCII, a test asserts `exportFooter.codeUnits.every((c) => c < 128)`, and if that assertion is ever deliberately broken the PDF arm of `containsDisclaimer` is rewritten in the same commit.

```dart
// test/policy/withdrawal_is_never_defaulted_in_an_export_test.dart
test('a treatment with no withdrawal row exports three blanks and "not_recorded"', () async {
  final row = await singleTreatmentRow(withNoWithdrawal);
  expect(row['meat_withdrawal_state'], 'not_recorded');
  expect(row['meat_withdrawal_days'], '');
  expect(row['meat_clear_date'], '');
  expect(row['meat_withdrawal_source'], '');   // NOT "as entered by you"
});
```

That last one matters more than it looks: emitting `0` for an absent withdrawal — or emitting the provenance phrase beside a blank — would be the app asserting a withdrawal period it was never told, in the artifact somebody hands to a vet.

---

## 7. The export → import → export round trip

### 7.1 The property

> Export a database to a backup, restore that backup into a fresh database, export again. **The `tables` value of the two files is byte-identical, and therefore the two `checksum.value`s are equal.**

Stated over `tables` and nothing else, because `exportedAtUtc` differs by construction and the header is not part of the claim. Both exports are produced by the same app version; a cross-version claim is not made and would not be true (§5.5 exists precisely because it is not).

This is the property that says the backup is a backup. It is also the cheapest way to catch nine different classes of bug at once.

### 7.2 What must be true for it to hold

Each of these is a way the round trip breaks, and each has a home:

1. **Deterministic row order.** Every backup query over a table that has a `uid` is `ORDER BY uid`. Not `ORDER BY id` — integer ids are re-issued on import, so id-ordering makes the second export a permutation of the first. The five tables without a `uid` (§5.3) order by the natural key that stands in for it: `ewe_touches` by `ewe_uid`, `pen_occupancy_lambs` by `occupancy_uid` then `lamb_uid`, `reminder_rules` by `kind`, `terminology_overrides` by `key`, and `app_settings` not at all — it has exactly one row. **This rule is about the backup only.** The three CSVs order by the keys §3 names, because a CSV is read by a human in the order a shepherd thinks in, and no CSV is ever re-imported.
2. **Canonical encoding of `tables`.** Object keys sorted ascending by code unit, no insignificant whitespace, at every level inside the `tables` value. The header is a fixed-order prefix and is outside both the canonical rule and the checksum (§5.2, §5.7).
3. **Identity is `uid`; integer ids are never written.** FKs onto a row are `<parent>_uid` carrying the parent row's `uid` (#32); FKs onto `vocab_terms.key` carry the vocabulary key itself (§5.3).
4. **No floating-point numbers anywhere.** Grams and milli-°C are integers, booleans are `0`/`1`. A `double` reintroduces the hardest canonicalisation problem in the format and the checksum starts flapping across platforms.
5. **Instants round-trip exactly.** `Instant → ISO-8601 ms Z → Instant` is lossless; covered by an explicit table of cases (decision #118 as amended 2026-08-01 — `glados` is struck from §5.2 because it does not resolve).
6. **Civil dates pass through as strings** and are never re-parsed into a `DateTime` and back.
7. **Every column is emitted, `null` included.** An omitted key on the way in and an explicit `null` on the way out is a real diff even though the importer treats them identically.
8. **`unknown_json` is re-emitted at the row's top level**, merged into the row object *before* the keys are sorted, and the column itself is never emitted under its own name (§5.3) — otherwise the second export writes every preserved field twice and nests the container again.
9. **Excluded tables are excluded symmetrically.** `entitlements`, `ewe_summaries`, `search_docs`, `search_fts`, views and `sqlite_sequence` are absent from both exports. `ewe_summaries` is the one that would fail loudest: it is rebuilt after restore with a fresh `rebuilt_at`.
10. **Text is byte-verbatim** — no trimming, no Unicode normalisation, and the CSV formula guard is nowhere near this code path.
11. **Nothing derived is written.** No statistic, no `lamb_rearing.rearing_dam`, no `lambing_consistency.is_mismatched`. Those are CSV and PDF columns; the backup carries the inputs.
12. **`AUTOINCREMENT` is doing its job.** A recreated ewe must not inherit a culled ewe's notes through a stale integer FK in an old export — which is why ids are re-issued and why they are never the identity (#32).
13. **Nothing is re-stamped on the way in or out.** `created_at` and `updated_at` are imported exactly as they appear in the file; the importer never substitutes `appNow()`. A restore that freshened `updated_at` would break byte equality on every row in the database at once, and it would destroy the only evidence of when a record was actually made. The same rule in the other direction is what keeps `app_settings` stable: `last_exported_at` is stamped **after** the artifact is written (§8.3), so it is never inside the file that describes it.

### 7.3 The test

`test/policy/backup_round_trip_test.dart`, driven by the hand-rolled seeded generator decision #118 authorises for exactly this (and for nothing else — do not extend it):

```dart
test('export → restore → export is byte-identical over `tables`', () async {
  final source = await seededFlock(seed: 42, ewes: 120, seasons: 2);
  final first  = await exportRepo(source).writeBackup(envelope: env);

  // `restoreInto` is the harness wrapper around 04 §7.2's flow — staging file,
  // validate, swap, reopen — and it returns the reopened AppDatabase. 04 owns
  // that entry point's name and signature; 09 does not get to invent one, and
  // `RestoreOutcome` is 04's enum, not a value with a database on it.
  final restored = await restoreInto(freshSupportDir(), File(first.path));
  final second   = await exportRepo(restored).writeBackup(envelope: env);

  expect(tablesBytesOf(second), tablesBytesOf(first));
  expect(headerOf(second).checksum.value, headerOf(first).checksum.value);

  // 04 §6.9's assertion, restated here because it is the same property:
  expect(idsOf(restored), isNot(idsOf(source)));   // integers were re-issued
  expect(uidsOf(restored), uidsOf(source));        // identity survived
});

test('a backup with unlocked = 1 imports to unlocked = 0', () async { … });  // #88
```

Run it over the two committed fixtures as well as the generator: `test/fixtures/flock_400_3seasons.json` and `flock_15_at_cap.json`.

---

## 8. Delivery

### 8.1 The share sheet, and only the share sheet

Every artifact leaves through `ShareService` → `share_plus` 13.3.0. Nothing is written to a user-visible folder, nothing is opened in place, and there is no "save to Files" path of our own.

```dart
await SharePlus.instance.share(ShareParams(
  files: [XFile(artifact.path)],
  fileNameOverrides: [artifact.shareName],
  subject: 'Shed Book export — $seasonLabel',
  sharePositionOrigin: originRect,   // REQUIRED on iPad
));
```

Four operational rules:

- **Always a file path, never `XFile.fromData`.** `fromData` writes a temp copy you then have to find and delete yourself.
- **`sharePositionOrigin` is required on iPad** — the README is explicit that omitting it "may cause crashes or unresponsive UI". It is a `Rect` from the tapped row's render box; the Export screen supplies it and there is no default.
- **The static `Share.share*` API is deprecated.** Policy rule `export.share_static` (§9).
- **Artifacts are written to `getTemporaryDirectory()`**, never to the media root (04 §4.2). That directory is excluded from iCloud and from Android Auto Backup, so stale exports never inflate a user's backup. It is swept at launch, off the critical path.

**File naming.** The temp file name is a uid; the human name is `fileNameOverrides`. Names are built from `seasons.year` (an integer), never from `seasons.label` — a user-authored label can contain `/` and a filename is the one place this app would otherwise have to sanitise user text. The backup name carries date **and time** (`shed-book-backup-2026-07-27-2104.json`) because a shepherd who exports before and after a night would otherwise overwrite the morning's file in Downloads.

### 8.2 Printing

**There is no in-app print dialog, and the Export screen does not pretend otherwise.** Spec §7.9's "printable" is degraded (decision-record §4): `printing` 5.15.0 depends on `http` and re-admitting it would break the tier-2 offline claim that gate G3 exists to prove. Delivery is share sheet → the OS Print action, which the iOS share sheet offers directly and which every Android PDF viewer offers.

**This is settled, not provisional.** Decision-record §7.0 row 16, ruled **2026-08-01** before `pubspec.yaml` closed: printing from inside the app is not required, `printing` stays in §5.3's rejected list, and G3's `PdfGoogleFonts` and `networkImage` greps stay **blocking** rather than advisory. Reversing it is an amendment to the decision record under `00-README` §10, not a preference — and the price of admission would be re-arguing §3.1's tier-2 claim in writing for a package whose whole job is talking to a print service.

The Export screen copy says what is true: the PDF goes to the share sheet, and printing happens from there. It does not say "printable" and leave the user hunting for a button.

### 8.3 `lastExportedAt`, and the banner that depends on it

The end-of-day export banner (decision #72, 07 §16) reads `app_settings.last_exported_at`. Getting the write wrong makes the app's one safety nag either useless or a liar.

- The stamp is written **after** the share sheet returns, in its own single-statement transaction, by `SettingsRepository` — never inside the artifact build, and never inside any transaction that also does something side-effecting (01 §4.3).
- **Stamp on success. Do not stamp on dismissed. Stamp on unavailable.** A dismissed share means the file did not leave; suppressing the banner would be a lie. "Unavailable" means the platform declined to report, and telling a shepherd who exports every night that they "have not exported since 2 March" is the fastest way to teach them to ignore the one banner that matters.
- **Unverified:** the exact `ShareResultStatus` member names and their per-platform semantics in `share_plus` 13.3.0. Read them off the package before relying on the three-way branch, and record what each platform actually returns (§10). `ShareService` owns the mapping — 08 owns that signature; what 09 requires is that the result reaches the caller at all, rather than being swallowed into a `Future<void>`.

Export is **never gated by the free tier, in any state** (decision #86). Not the CSVs, not the PDFs, not the backup, not over the ewe cap, not in season two. Paywalling the only backup mechanism in an app with no cloud is a data-hostage pattern, and 07 §13.2's over-cap row for this screen reads, in full, "nothing".

### 8.4 Media

Media is **not** in the backup in v1 (#85). The Export screen offers "Share photos from this season" as a separate action: the files handed straight to the share sheet, no ZIP, batched at 50 per share (04 §7.6 — a chosen bound, not a documented platform limit). It is labelled plainly as a copy-out, not a restorable backup, because **there is no media import**: a restore brings back `media_assets` rows whose files are gone, and those rows render as "photo taken 14 March, file missing", which is more honest than silence.

A media ZIP is blocked on verifying `ZipFileEncoder`'s incremental-write behaviour (§10). Do not design one until that check is done and written down.

---

## 9. Anti-patterns, and the gates that catch them

| Banned | Why | Caught by |
|---|---|---|
| `package:csv` | Unverified uploader, fresh breaking rewrite, for 50 lines you need byte control over | G2 dependency allowlist |
| CSV bytes produced outside `csv_writer.dart` | The trailer stops being structural | `export.csv_bytes` — `\r\n` literal or the BOM triple outside that file |
| `pw.Document(` / `pw.MultiPage(` outside `pdf_writer.dart` | A PDF without the footer becomes constructible | `export.pdf_document` |
| `Font.helvetica` / `.times` / `.courier` / `.symbol` / `.zapfDingbats` | Latin-1 only — **throws** on a curly quote, while exporting the vet's medicine book | `export.base_14_font` |
| `Share.share`, `Share.shareXFiles` (static) | Deprecated API | `export.share_static` |
| `package:intl` inside `csv_writer.dart` / `pdf_writer.dart` / `backup_format.dart` | A locale decimal comma shifts every column after the weight | `export.intl_in_writer` |
| `package:printing`, `PdfGoogleFonts`, `networkImage` | Puts a live HTTP client in the graph; breaks the tier-2 offline claim | G3, every push |
| Base64 media inline in the backup | 130 MB → ~175 MB inside one JSON string, built in memory | `copy.base64_backup` |
| Re-typing a `Disclaimers` string | Decision #62 | `copy.disclaimer_retyped` + the single-definition test |
| Exporting integer primary keys as identity | Renumbering on import rewrites every FK | The round-trip test (§7.3) |
| Rewriting a `vocab_terms.key` FK as a `_uid` | Re-keys the one column 03 guarantees is stable forever, and makes the file unreadable | The round-trip test; the header golden (§3.4) for the CSV side |
| Emitting `unknown_json` under its own name | Every preserved field is written twice and the container nests on the next export | The round-trip test (§7.3), which fails on the second export |
| Re-stamping `created_at` / `updated_at` on import | Breaks byte equality on every row at once, and erases when the record was actually made | The round-trip test (§7.3) |
| An all-numeric date drawn in a PDF | R60 — a PDF has no ISO column beside it, so `14/03` is ambiguous to half the planet | Review + the `dd/MM` grep over `pdf_writer.dart` in the DoD |
| An `assert` as the only guard on a ragged CSV row | Stripped in release; the ragged file reaches the share sheet | Review; §2.2 uses a `throw` |
| A `double` anywhere in the backup body | Breaks canonical encoding and the checksum | A test over the encoded body |
| Adding a `NOT NULL` column without an `importDefaults` entry | A future app cannot restore an older backup | The completeness test (§5.6) |
| A "merge" import option | A merge UI at 3am is a data-loss generator (#73) | Review; there is no merge code to call |
| Pretty-printing the backup | Doubles bytes and peak heap at the tripwire; decouples the file from the checksum | Review + the byte-equality assertion in §7.3 |
| Gating any export behind the cap | Data hostage (#86) | `test/features/no_monetization_test.dart` |
| `?? 0` on a nullable aggregate in the statistics block | Prints `0%` where the honest answer is "not computable" | `CODE-REVIEW-CHECKLIST.md`; `StatResult.notComputable` exists for it |

The five `export.*` rows are **new** and require the one-line addition to `CONVENTIONS` §4.7's namespace list named in §1.3.

---

## 10. Open and unverified

Nothing below is papered over. Each has an owner and a check.

| # | Item | Check | Blocks |
|---|---|---|---|
| 1 | Does `pdf` 3.13.0 accept `AtkinsonHyperlegibleNext[wght].ttf` (a variable font), and which instance does it embed? | Build a one-page document, open it in Preview and Acrobat, inspect the glyphs and metrics | The flock book. Fallback in §4.2 is two static instances |
| 2 | Does `pdf` subset the embedded face? | Generate a 1-row and a 500-row document; diff the file sizes | Nothing, but the number belongs in `docs/perf/measurements.md` before anyone promises a PDF by email |
| 3 | `pw.TableHelper.fromTextArray(headerCount: 1)` header repeat across `MultiPage` pages in 3.13.0 | Generate a 5-page table and look at page 3 | The page furniture in §4.5 |
| 4 | `kPdfRowsPerVolume = 2000` | Measure peak RSS on the low-end target device generating a 2,000-row volume | The split threshold. The 100–200 MB figure in §4.9 is an estimate, not a measurement |
| 5 | `ShareResultStatus` member names and per-platform semantics in `share_plus` 13.3.0 | Read the package; then run the airplane-mode pass on both OSes and record what each returns | §8.3's three-way branch |
| 6 | `DateTime.timeZoneName` returns an abbreviation on some platforms and a full name on others | Log it on both OSes | The CSV trailer's zone line and `exportedAtZoneAbbreviation`. Never `package:timezone` here — R48 confines it to the notification seam |
| 7 | `ZipFileEncoder`'s incremental-write behaviour in `package:archive/archive_io.dart` | Empirical: encode 200 MB and watch RSS | Any media-in-ZIP design (#85). Until then, media is a separate share |
| 8 | Peak heap for `jsonEncode` at the 20 MB tripwire | Measure at the tripwire, not before | Whether the streaming writer in §5.7 is ever needed |
| 9 | **Decision-record §7.1 q9** — does the app replace the paper record entirely, or sit alongside it for the first season? | Owner, with a shepherd | How hard the export has to work, and whether records-only JSON is acceptable at all |
| 10 | ~~Is printing *from inside the app* required?~~ **Closed 2026-08-01 — no.** Decision-record §7.0 row 16 | Ruled by the owner before `pubspec.yaml` closed; nothing left to check | Nothing. `printing` stays rejected, delivery stays share sheet → OS Print, and §8.2 carries the ruling |
| 11 | **Decision-record §7.1 q11** — does a temperature column ship? | Owner, before schema v1 | If yes, `milli_celsius` gains CSV columns on the same integer-canonical rule as grams |
| 12 | **Decision-record §7.1 q10** — is the target market ever a dairy flock? | Owner | The `milk_*` columns in `treatments.csv` ship regardless, because `WithdrawalTarget.milk` is in the v1 sealed type; the v1 UI may never write one |
| 13 | Does `pdf` 3.13.0 write the document-information `subject:` as a plain literal PDF string, findable as UTF-8 in an uncompressed document? §6.4's PDF assertion is built entirely on this and it is **asserted from the format, not measured from the package** | Build a two-page document with `compress: false` and `grep` the raw bytes for the first six words of `Disclaimers.exportFooter`. Then repeat with `compress: true` and record whether it still hits — if it does, the test does not need the parameter at all | `every_export_carries_the_footer_test.dart`'s PDF arm. If the string is not findable, the fallback is a structural assertion only, and §6.3's "footer on every page" loses its byte-level proof — say so rather than deleting the row |

---

## Definition of done

- [ ] `lib/data/csv_writer.dart` exists, is the only producer of CSV bytes in the app, and `export.csv_bytes` proves it.
- [ ] The encoder emits the UTF-8 BOM, CRLF line endings, `""` escaping, and quotes on `,` `"` CR LF `;` TAB and any leading or trailing whitespace. A test covers each of the nine rows in §2.3, including an embedded newline and an embedded comma in a note.
- [ ] A row whose field count differs from the header's raises, in release as well as debug — the check is a `throw`, not an `assert`. A test runs it with `dart --no-asserts` or its `flutter test --release` equivalent.
- [ ] The formula-injection guard fires on `= + - @` TAB and CR, is disclosed in the trailer in those same terms, and appears in no other writer. A test asserts the stored record is unchanged.
- [ ] No `package:intl` and no `NumberFormat` in `csv_writer.dart`, `pdf_writer.dart` or `backup_format.dart`; `export.intl_in_writer` proves it.
- [ ] The three header rows match §3.4 byte for byte. A golden test freezes them.
- [ ] Every CSV emits its six trailer records, padded to the header's field count, **including from an empty database**.
- [ ] `birth_weight_g` and `birth_weight_kg` both ship; the file does not change when `weight_unit` changes; the PDF renders the user's unit.
- [ ] `sex` blank and `sex = unknown` are distinct in the file; `death_cause_label` blank is unattributed and is not written as `unknown`.
- [ ] `meat_withdrawal_state` renders `not_recorded` with three blank companions when there is no withdrawal row, and never `0`.
- [ ] Voided treatments are exported with `is_voided = 1`; the medicine record shows the void and keeps the row.
- [ ] `lib/data/pdf_writer.dart` is the only `pw.Document(` / `pw.MultiPage(` site; `export.pdf_document` proves it; `footer:` is set inside `_buildDocument` and is not a parameter.
- [ ] No base-14 font is constructed anywhere; `export.base_14_font` proves it; item 1 of §10 has been run and its answer recorded in §4.2.
- [ ] The PDF is built by `compute()`, the isolate writes the file, and only `({String path, int byteSize})` crosses back.
- [ ] The flock book always splits into ewes and lambs volumes; a volume over `kPdfRowsPerVolume` splits further with `part N of M` and an honest on-screen message; nothing is ever truncated.
- [ ] Every statistic in the flock book prints `StatResult.definition` verbatim; a null value prints `not computable — <reason>` and never `0`.
- [ ] No date drawn in a PDF is all-numeric (R60): the flock book's `Born` is `d MMM HH:mm`, the medicine record's `Date` is `d MMM y HH:mm`, and `dd/MM` appears in no `pdf_writer.dart` format string.
- [ ] The medicine record carries the boxed statement under the title **and** the running footer, and `titleBoxUnderHeading` is composed inside `_buildDocument` rather than left to the caller's `build:`.
- [ ] The backup envelope matches §5.2: `_disclaimer` first, `_withdrawalNotice` second, `formatVersion` distinct from `schema`, 21 tables including `vocab_terms`, and one `counts` entry per table in `tables` — 21 of them, zeros included.
- [ ] `entitlements` and `ewe_summaries` are absent from the backup; a fixture with `unlocked: 1` imports to `unlocked = 0`.
- [ ] Header keys are `camelCase`; every key inside `tables` is a SQLite column name; every row-pointing FK is `<parent>_uid`; every `vocab_terms.key` FK keeps its own name and its key value; no integer primary key is written; the five `uid`-less tables emit the natural keys §5.3 names.
- [ ] `unknown_json` exists on all 21 restorable tables (the 03 edit in §1.3), is never emitted under its own name, and its contents are merged into the row before the keys are sorted.
- [ ] No `double` appears anywhere in the encoded body; a test over the bytes proves it.
- [ ] `created_at` and `updated_at` survive a restore unchanged — no importer re-stamps them.
- [ ] The file is compact JSON with one trailing newline, the `tables` value is canonical and encoded exactly once, and the checksum is reproducible by hand from the file.
- [ ] A newer `formatVersion` or `schema` is refused with the §5.5 wording; an older `schema` is accepted; unknown columns land in `unknown_json` and are re-emitted.
- [ ] The `importDefaults` completeness test is green against the committed `drift_schema_v<kSchemaVersion>.json`.
- [ ] `Disclaimers.exportFooter` appears as a literal exactly once in the codebase; `disclaimer_is_defined_once_test.dart` names the file and uses `joinedStringLiterals`.
- [ ] `every_export_carries_the_footer_test.dart` covers all six artifacts against both a seeded and an empty database, with the PDF asserted through document metadata built at `compress: false`, and a companion test asserts `Disclaimers.exportFooter` is pure ASCII.
- [ ] `backup_round_trip_test.dart` is green over the seeded generator and both committed fixtures: `tables` bytes identical, checksums equal, ids re-issued, `uid`s preserved.
- [ ] Every **backup** query over a table that has a `uid` is `ORDER BY uid`; the five `uid`-less tables order by the natural keys in §5.3; no backup query orders by `id`. The CSV orderings are §3's and are deliberately different.
- [ ] Every artifact goes out through `ShareService` with a file path, `fileNameOverrides` and `sharePositionOrigin`; artifacts are written to `getTemporaryDirectory()` and swept at launch.
- [ ] `last_exported_at` is stamped after the share result, in its own transaction, per §8.3's three-way rule.
- [ ] Nothing on the Export screen is gated by the free tier at any entitlement state.
- [ ] The **nine** sibling edits in §1.3 have been applied — including `unknown_json` in 03, before the first schema snapshot — and the five `export.*` rules are in `tool/check_policy.dart` and in `CONVENTIONS` §4.7.

---

## References

**Specifications and standards**
- RFC 4180, *Common Format and MIME Type for CSV Files* — https://www.rfc-editor.org/rfc/rfc4180
- RFC 9562, *UUIDs* (v7, used for `uid`) — https://www.rfc-editor.org/rfc/rfc9562

**Packages** (versions from decision-record §5 only — never from memory)
- `pdf` 3.13.0 — https://pub.dev/packages/pdf
- `share_plus` 13.3.0 — https://pub.dev/packages/share_plus
- `archive` 4.0.9 — https://pub.dev/packages/archive
- `csv` 8.0.0 (**rejected**, decision-record §5.3) — https://pub.dev/packages/csv
- `printing` 5.15.0 (**rejected**, decision #83) — https://pub.dev/packages/printing

**`dart_pdf` font behaviour** (the evidence that base-14 fonts throw)
- Fonts Management wiki — https://github.com/DavBfr/dart_pdf/wiki/Fonts-Management
- Issue #810 — https://github.com/DavBfr/dart_pdf/issues/810
- Issue #252 — https://github.com/DavBfr/dart_pdf/issues/252
- Issue #405 — https://github.com/DavBfr/dart_pdf/issues/405

**Fonts**
- Atkinson Hyperlegible Next, SIL OFL 1.1 — https://github.com/google/fonts/tree/main/ofl/atkinsonhyperlegiblenext

**Project documents**
- `../research/00-tech-decisions.md` — §2H (decisions #82–#86), §3 (the offline contract), §4 (what is degraded), §5 (the verified dependency table), §7.0–§7.1
- `CONVENTIONS.md` — §1 (the tree), §2.8 (`BackupHeader`), §2.14 (`Disclaimers`, `ExportEnvelope`), §4.7 (policy rule ids), §5.4 (copy conventions), R60, R61, R65
- `03-data-model-and-schema.md` — every column named in §3 and §5
- `04-migrations-media-backup-restore.md` — §4.2 (where exports are written), §6 (the backup format), §7 (restore), §8 (`VACUUM INTO` is not a backup)
- `05-domain-correctness.md` — §4 (`RecordedTime`), §6.2 (the four `definition` strings), §7.3 (`ContentPolicy`), §7.4 (`Disclaimers`, `ExportEnvelope`)
- `07-screens.md` — §13 (the Export screen), §16 (the end-of-day banner)
- `08-platform-integration.md` — `ShareService`'s signature and the share result
- `12-testing.md` — where `test/policy/` lives and how goldens are re-baselined

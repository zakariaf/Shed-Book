---
name: shed-export-and-restore
description: >-
  Every route records leave or re-enter the phone by — CSV, PDF and the JSON backup. Use for any
  export, backup, import, or restoring a backup file. Do NOT use for restoring a purchase
  (shed-monetization) or the share seam (shed-platform-gateways).
---

# Export, backup and restore

Export is the only backup this app has (spec §7.9: *a safety feature, not a convenience*), so an
export that is silently wrong is the worst bug in the product. Restore is the most destructive
operation in the app and the only recovery path that exists.

Authorities, BINDING and outranking this skill — open the section, never re-derive it:
`docs/engineering/09-export-formats.md` (writers, the three shapes, the envelope, delivery);
`docs/engineering/04-migrations-media-backup-restore.md` §4–§8 (media, sweeps, backup, restore,
`VACUUM INTO`); `docs/engineering/CONVENTIONS.md` (R60, R62, R65, §2.12, §4.7);
`docs/research/00-tech-decisions.md` §5.1 for the `pdf`, `share_plus` and `archive` pins — the only
source of a version number, and **shed-dependencies-and-toolchain** owns changing one.

**Do NOT use this skill for:** the share-sheet plugin seam — `ShareService`, `ShareParams`,
`sharePositionOrigin`, the `ShareResultStatus` mapping — **shed-platform-gateways**; schema
migrations, `stepByStep`, the from→to matrix — **shed-migrations**; what a column stores or its
CHECKs — **shed-drift-schema**.

## Six artefacts, one importer

Three CSVs (`lambs`, `ewes`, `treatments`), two PDFs (flock book — **always two volumes** — and the
medicine record), one JSON backup. **Only the JSON backup has an importer**, and there never will be
another: an import that is not a whole-database replace is a merge, and there is no merge. Every
artefact except the backup is one season; the backup is the whole database, because it is the thing
that restores a new phone. Files, all under flat `lib/data/` (09 §1.2): `csv_writer.dart` ·
`pdf_writer.dart` · `backup_format.dart` (`BackupHeader`) · `export_limits.dart` ·
`export_repository.dart` · `restore_service.dart` · `media_store.dart` · `media_sweeper.dart`.

## Struck rows leave the phone — blocked on P1

- **Every CSV and every PDF carries `struck` and `struck_at`, and every struck row is included and marked.** An
  export that quietly drops the strikes undoes the one thing this app is for.
- The three header rows in 09 §3.4 are **frozen**. New columns **append to the end**, never insert — a rename or a
  reorder breaks every spreadsheet a shepherd has built on the file.
- The CSV trailer gains a record saying struck entries are included and marked and nothing has been removed,
  placed immediately after the §12.3 statement (shifting 09 §6.3's "row 2"/"row 3" by one). It is a new `const` on
  `Disclaimers` — a different safety rule from §12.3, so a different string — referenced, never typed into a
  writer.
- A struck row never counts toward a litter size or any aggregate; it always appears in the file.
- **P1 owns the storage side**: which tables carry the pair, the spelling, the window in seconds. Until it lands,
  build the export side against `struck` / `struck_at`; do not invent a schema.

## The CSV writer

`lib/data/csv_writer.dart` is the **only producer of CSV bytes in the app** (`export.csv_bytes`),
which is what makes "every CSV carries its trailer" structural rather than a habit. `package:csv` is
banned.

- **UTF-8 BOM, always** — Excel on Windows reads a BOM-less UTF-8 file as the ANSI code page and mangles every
  `°`, `£`, Welsh `ŵ` and Irish fada. **CSV only:** a BOM in JSON breaks `jsonDecode`.
- **CRLF**, including after the last record. No `sep=;` line, no delimiter setting. Quote on `,` `"` CR LF `;` TAB
  and any leading or trailing whitespace; `"` escapes to `""`, **never `\"`**.
- **Formula guard:** prefix `'` on a field beginning `=` `+` `-` `@` TAB or CR — the full set, not the four
  obvious ones. It transforms the *export*, is declared in the trailer in those terms, and never appears in the
  PDF or JSON writer: an apostrophe in the vet's medicine book, and a broken round trip.
- A row whose field count differs from the header's **throws**, not `assert`s — asserts are stripped from the
  release build the shepherd runs, and a ragged file reaches her spreadsheet.
- `null` is an empty field, never `null` / `N/A` / `-`. Blank `sex` ≠ `unknown` (R45); blank `death_cause_label`
  is unattributed, not `dc_unknown`; blank withdrawal days is never `0`.
- `encode` emits the trailer itself on **every** CSV including a zero-row one, each record padded to the header's
  column count so the file stays rectangular.
- **No `package:intl`, no `NumberFormat`** in any writer (`export.intl_in_writer`): a French device emits a comma
  decimal and shifts every column after the weight. Zero-pad `dd/MM/yyyy HH:mm` by hand.
- CSV is **interchange** — `birth_weight_g` *and* `birth_weight_kg` ship and the file never changes with the
  user's `WeightUnit`; the PDF is **display** and renders `unitsProvider`'s unit.
- Vocabulary labels are resolved by the **Export screen** (the only object with a `BuildContext`) into a
  `Map<String, String>` passed down; `lib/data/` cannot reach `AppLocalizations`.

- **One export-time zone per file.** `born_at_local` is *derived* from `born_at_utc` in the zone the
  export ran in, and `local_date_disagrees` is `born_local_date ≠` that same render (09 §3 cols 13–15).
  So every row in one file carries the **same** offset, the trailer's zone line names that one zone,
  and a `1` in col 15 means the stored civil date and the fresh render genuinely differ — never that
  two rows were rendered differently. Both values print; neither is corrected (§12.4).

**Read `examples/lambs.csv` before writing or changing any CSV shape** — real BOM, real CRLF, every
quoting case, the struck pair, the padded trailer. Prose cannot settle it.

## The PDF build

- `package:pdf` at decision-record §5.1's pin, and nothing else. **`printing` is banned**: it declares `http` and hands a contributor `PdfGoogleFonts` /
  `networkImage`, breaking the offline claim gate G3 exists to prove. There is no in-app print dialog; printing
  happens from the OS share sheet and the screen copy says so.
- **Always embed a TTF; never construct a base-14 font** (`export.base_14_font`) — `Font.helvetica` and friends
  are Latin-1 and **throw** on the curly quotes, en-dashes and ellipses an iOS keyboard inserts automatically,
  mid-export of the medicine record for a vet visit.
- `pw.Font.ttf(ByteData.sublistView(bytes))`, **never `bytes.buffer.asByteData()`** — `.buffer` discards the
  view's offset and feeds the parser the wrong bytes.
- `lib/data/pdf_writer.dart` is the **only** `pw.Document(` / `pw.MultiPage(` site (`export.pdf_document`);
  `footer:` is set inside `_buildDocument` and is unreachable from a caller, so no code path produces a Shed Book
  PDF without the §12.3 footer.
- **`compute()`, and the isolate writes the file.** Only `({String path, int byteSize})` crosses back — returning
  `Uint8List` copies it and doubles peak memory exactly when you are trying not to OOM. Rows cross pre-formatted
  as `List<List<String>>`; the isolate has no units, terminology or ARB.
- Never truncate. Two volumes always; past `kPdfRowsPerVolume` split on a row boundary with `part N of M` and say
  so plainly on screen. **No photos in any PDF, ever.**
- **No all-numeric date is drawn in a PDF** (R60): `d MMM HH:mm` in the flock book, `d MMM y HH:mm` in the
  medicine record, each with its provenance mark and a legend.
- Every statistic prints `StatResult.definition` **verbatim** (R61); a null prints `not computable — <reason>`.
  `?? 0` on a nullable aggregate is a review-blocking defect.
- The medicine record carries the boxed §12.1 + §12.3 statement under the title **and** the running footer. A
  voided treatment renders struck with a `VOID` marker; the row is never removed.

## The JSON backup

- **`BackupHeader` is not `ExportEnvelope` (R65).** The *envelope* is the whole file; `BackupHeader` is the
  `format`/`formatVersion`/`schema`/`counts`/`checksum` block; `ExportEnvelope` is the disclaimer-bearing value
  **every** writer takes, and it cannot be constructed without the disclaimer.
- `_disclaimer` first, `_withdrawalNotice` second. Header keys `camelCase`; every key inside `tables` is a SQLite
  column name in `snake_case`. `formatVersion` is the header's, independent of `schema`.
- 21 tables, `vocab_terms` included — a user-added term missing from the file makes the restore fail its own
  `PRAGMA foreign_key_check`. One `counts` entry per table, zeros included.
- **Identity is `uid`, never `id`.** Row FKs are `<parent>_uid`; a `vocab_terms.key` FK keeps its own name and its
  key value (`"route": "rt_subcutaneous"`, never `route_uid`).
- No doubles; booleans `0`/`1`; instants ISO-8601 UTC ms `Z`; civil dates pass through; every column emitted
  including `null`; text byte-verbatim. `unknown_json` is merged into the row before its keys are sorted and is
  **never emitted under its own name**.
- `checksum` is FNV-1a 64 over the canonical `tables` encoding — sorted keys, no whitespace. Encode `tables`
  **once**: a second encode doubles peak heap and can silently diverge. It is a **corruption check, not a tamper
  check**; "verified", "secure" and "authentic" are banned words, and `crypto` being transitively present is not a
  licence to import it.
- **Refuse a newer `formatVersion` or `schema`; accept an older `schema`.** Guessing at a newer schema is §12.4
  applied to restore.
- Excluded symmetrically on both sides: media bytes, `entitlements` (a neighbour's backup must never unlock the
  app), `ewe_summaries`, `search_docs`/`search_fts`, views, `sqlite_sequence`.
- **The round trip is the property that says the backup is a backup:** export → restore → export is byte-identical
  over `tables`, checksums equal, integer ids re-issued, `uid`s preserved.

## Media on disk, and the sweeps

The database holds the index; the filesystem holds the bytes. **Never store an absolute path** — the
iOS container UUID changes between launches, and the path is stable on Android, which is exactly why
the bug ships. `relative_path` is POSIX `YYYY/MM/<uid>.<ext>` and carries all three CHECKs (R62);
`MediaStore` is the only thing that mints or resolves one.

**The record commits first; the media attaches second.** An orphaned file is garbage a sweep collects;
an orphaned row is a broken record. Media is never deleted, only moved to `.trash/<date>/`; a row
whose file is gone is flagged `missing_since`, never deleted — dropping it makes the app lie by
omission. Exports go to `getTemporaryDirectory()`, **never** the media root, and are swept at launch.

## Restore — replace everything, never a merge

Import into a **new** SQLite file beside the live one, validate it completely, then swap with two
adjacent renames guarded by a sentinel. Never merge into the live database, never offer merge as an
option, and never reach restore from the 3am path — Settings only.

`tool/seed.dart` writes its demo database **through this same path**
(`dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42`). Not convenience: it makes the seed a
continuous test of the one code path where a bug loses five seasons, and it is the precondition for
400-ewe profiling, the overflow matrix, the goldens and the at-cap tests. No second seeding path.

**Read `references/restore-and-sweeps.md` when touching restore, import or media on disk** — the
16-step sequence, the four interrupted-restore outcomes, the nine things a partial restore must never
leave behind, and both sweep directions.

## Gotchas

- **A `file.contains('long sentence')` scan misses long strings** — Dart wraps them across adjacent literals, so
  the phrase is never contiguous in source. Extract and join the literals first; every sentence-grepping scanner
  here has this bug unless it does.
- **A byte search for drawn PDF text never matches** — an embedded TTF writes glyph indices, not characters. The
  disclaimer is proved through the document-information `subject:`, asserted against a document built with the
  test-only `compress: false`, which is why that parameter exists.
- **`Disclaimers.exportFooter` must stay pure ASCII.** A non-ASCII PDF string object is UTF-16BE behind a BOM, the
  UTF-8 search finds nothing, and the safety test goes green for the wrong reason.
- Backup queries are `ORDER BY uid` (natural key for the five `uid`-less tables), **never `ORDER BY id`** — ids
  are re-issued on import. CSV orderings are deliberately different and human-facing.
- **Nothing is re-stamped on import**: substituting `appNow()` for a file's `created_at`/`updated_at` breaks byte
  equality on every row at once and erases when the record was made.
- `last_exported_at` is stamped **after** the share result, in its own transaction: on success and on unavailable,
  **never on dismissed** — the file did not leave, and a banner that lies gets ignored.
- **Export is never gated by the free tier in any entitlement state** — not the CSVs, the PDFs, the backup, nor
  over the ewe cap. Paywalling the only backup in an app with no cloud is data hostage.
- A migration adding a `NOT NULL` column with no database default needs a `lib/data/import_defaults.dart` entry in
  the same commit, and a fallback may never be a domain value: a treatment predating `treatment_withdrawals`
  yields **no** withdrawal row, read as `WithdrawalNotRecorded` — that absence is how §12.1 is enforced.
- `VACUUM INTO` is a diagnostics snapshot, never a backup, and never runs inside a transaction. `File.copy` of the
  live database is a bug — in WAL mode the database is three files.

## Banned outright

`package:csv` · `package:printing` / `PdfGoogleFonts` / `networkImage` · base-14 fonts · CSV bytes
outside `csv_writer.dart` · `pw.Document(` outside `pdf_writer.dart` · `package:intl` in any writer ·
base64 media in the backup · pretty-printing the backup · re-typing a `Disclaimers` string · exporting
integer primary keys, `entitlements` or `ewe_summaries` · a `double` in the backup body · a merge
import · truncating or omitting any row · gating any export behind the cap.

## Definition of done

- [ ] `csv_writer.dart` is the only CSV byte producer, `pdf_writer.dart` the only `pw.Document(` site, and the five `export.*` rules are in `tool/check_policy.dart` and `CONVENTIONS` §4.7.
- [ ] The three header rows match 09 §3.4 byte for byte plus appended `struck` / `struck_at`, frozen by a golden test; every struck row is in every CSV and PDF, marked, and in no aggregate.
- [ ] Every CSV emits its padded trailer **from an empty database**, struck record included; a ragged row throws in release; the formula guard fires on `= + - @` TAB CR and nowhere else.
- [ ] The PDF is built by `compute()`, the isolate writes the file, only `({path, byteSize})` returns, and `dd/MM` appears in no `pdf_writer.dart` format string.
- [ ] `every_export_carries_the_footer_test.dart` passes for all six artefacts against a seeded **and** an empty database; a companion test asserts `exportFooter` is pure ASCII.
- [ ] `backup_round_trip_test.dart` is green over the generator and both committed fixtures: `tables` bytes identical, checksums equal, ids re-issued, `uid`s preserved, `unlocked` → 0.
- [ ] Refusal fixtures abort at the documented step: newer `schema`, newer `formatVersion`, a truncated file, a ZIP, a `.sqlite`.
- [ ] The interrupted-restore test returns `notStarted` / `rolledBack` / `completed` for the three crash windows, and the nine §7.5 invariants are asserted directly.
- [ ] `dart run tool/seed.dart` writes through `RestoreService` and is green in CI.
- [ ] No absolute path, `..` segment or Windows separator reaches `media_assets.relative_path`; both sweeps trash or flag and never delete.

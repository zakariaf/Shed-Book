# N22-T05 — File import through `file_selector`, with the magic bytes validated by us

| | |
|---|---|
| **Epic** | [N22 — The JSON backup format](epic.md) · `00-README` §9 step 8 (2 of 3) |
| **Task** | 5 of 5 |
| **Depends on** | N22-T04 |
| **Commit** | one commit · `feat(backup): file import with magic bytes validated by us` |

## 1. Why this task exists

Import through the platform picker, and **we** validate the magic bytes — not the picker's
extension filter, which on Android is a suggestion and on iOS is a document type nobody honours. A
wrong file selected at 2am must be refused before anything is touched.

This task lands the three **non-destructive** steps of 04 §7.2 and stops there: pick the file, sniff the
first bytes, validate the header. Steps 5 to 16 — the staging database, the import transaction, the
sentinel and the swap — are N23-T01, and the two-step confirmation screen between them is N23-T02. The
split is deliberate: everything in this task can be reviewed by reading a parser.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/08-platform-integration.md` | §6 (`file_selector` **1.1.0**, the `XTypeGroup`, why the MIME filter is not trusted, why `file_picker` was rejected, why `.zip` is not accepted in v1) · §1 (the `layer.plugin_file_selector` row and the one permitted call site) · §11 checklist (*"`file_selector` is imported in exactly one file … and `RestoreService` takes a `File`"*) | the seam, and the single-call-site rule |
| `docs/engineering/04-migrations-media-backup-restore.md` | §7.2 steps 0–3 (guard, pick, copy, sniff, validate — with the exact refusal sentences) · §7.4 (the failure table: what the user loses in each case, which is nothing) · §4.9 (`File(` is banned anywhere under `lib/features/**`) | the flow this task implements, and where it stops |
| `docs/engineering/09-export-formats.md` | §5.2 (the header the validator parses) · §5.5 (the refusals T03 already built) · §2.4 (JSON must not carry a byte-order mark) | what a valid file looks like |
| `docs/engineering/CONVENTIONS.md` | §1 (`lib/data/restore_service.dart` is in the tree) · §1.1 layer rules 3, 5 · §2.8 (`RestoreService` + `RestoreOutcome` + `completeInterruptedRestore`) · §2.13 | where each piece is allowed to live |
| `docs/engineering/10-accessibility-and-i18n.md` | §8.4 (ARB house rules) | the three by-name refusals |
| `docs/research/00-tech-decisions.md` | §5 (`file_selector` **1.1.0**) · #81 (validate magic bytes ourselves) · #85 (media is not in the v1 backup, so `.zip` is not accepted) | the version and the ruling |
| `CLAUDE.md` | the offline-purity section | the words that may never be used about the checksum |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | the picker seam and its fake |
| `shed-export-and-restore` | the format's own validation |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/backup_import_test.dart`
- **Test** — `'a renamed JPEG is refused by the magic-byte check before any parse begins'`
- **Why it is red today** — nothing imports a file, and the picker's filter is the obvious thing to trust.

```bash
fvm flutter test test/features/backup_import_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it proves the ordering and not only the outcome. Write a real JPEG's first
bytes — `FF D8 FF E0` — to a temp file named `flock.json`, hand its path to the prelude, and assert
three things: the outcome is `BackupRefused` with reason `notABackupFile`; the refusal names both the
kind found and the kind expected; and `jsonDecode` was never reached, proved by making the file's *tail*
syntactically broken JSON so that any parse attempt would throw a `FormatException` rather than return a
refusal. A test that only asserts "refused" passes for a parser that parses first and refuses second.

**Green.** The minimum code that passes, and nothing beyond it — the gateway, the byte check first, then the parse.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema, no domain, no wiring, no controller.** Nothing here writes to the database, and that is a
property of the signatures rather than a promise — say so in the commit message. There is no Settings
screen yet either: Settings is N29 and the confirmation is N23-T02, so this task lands the functions and
nothing renders them.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/backup_format.dart` | Edit. `BackupFileKind` and `sniffBackupFile(List<int>)` — pure, no I/O, so the whole magic-byte decision is unit-testable against a byte list. Plus the three wrong-kind reasons on `BackupRefusalReason` |
| 2 | `lib/data/restore_service.dart` | **New**, and only the non-destructive prelude: a **top-level** `readBackupPrelude(String pickedPath)`. N23-T01 adds the class, `RestoreOutcome` and `completeInterruptedRestore` to this same file |
| 3 | `lib/features/settings/restore_flow.dart` | **New.** The **one** `file_selector` call site in the app — `pickBackupFile()` and the `XTypeGroup` — and nothing else. `layer.plugin_file_selector` fails the build on a second import anywhere |
| 4 | `lib/l10n/app_en.arb` | Edit. The three by-name refusals, each with a `description` naming the file kind it is about |
| 5 | `lib/l10n/app_localizations*.dart` | Regenerated by gen-l10n and **committed in this same commit** — the `codegen` job diffs `lib/` |
| 6 | `test/features/backup_import_test.dart` | **New.** The anchor plus the cases in §5.4 |

### 5.2 The signatures

```dart
// lib/features/settings/restore_flow.dart — the ONE file_selector call site.
// It returns the picked path and touches nothing else. It constructs no File:
// `File(` under lib/features/** is banned by `layer.features` (04 §4.9),
// because the UI layer does not know the filesystem exists.
const _backupType = XTypeGroup(
  label: 'Shed Book backup',
  extensions: ['json'],
  // Android MIME filtering is unreliable; some providers report a file as
  // octet-stream. Accept too much and reject clearly rather than greying out
  // the shepherd's own backup.
  mimeTypes: ['application/json', 'application/octet-stream'],
  uniformTypeIdentifiers: ['public.json'],
);

Future<XFile?> pickBackupFile() => openFile(acceptedTypeGroups: [_backupType]);
```

```dart
// lib/data/backup_format.dart — pure, no dart:io, no I/O of any kind.
enum BackupFileKind {
  shedBookBackup,   // first non-whitespace byte is '{'
  zipArchive,       // 50 4B 03 04
  sqliteDatabase,   // "SQLite format 3\0" — 16 bytes
  unrecognised,     // everything else, including a renamed JPEG
}

/// Takes the first bytes of the file — 512 is enough and fewer is legal.
BackupFileKind sniffBackupFile(List<int> firstBytes);
```

```dart
// lib/data/restore_service.dart — 04 §7.2 steps 1 to 3, and nothing after them.
// A TOP-LEVEL function, not a method: it holds no AppDatabase, so it is
// structurally incapable of writing a row. N23-T01 adds the class below it.
Future<BackupHeaderOutcome> readBackupPrelude(String pickedPath);
```

The three refusals, verbatim from 04 §7.2 step 2:

```json
"restoreRefusedZip": "This looks like a photo archive. Shed Book restores the records file (.json).",
"@restoreRefusedZip": {
  "description": "Shown when the picked file starts with the ZIP magic bytes. Media is not part of a v1 backup (decision 85), so a photo archive is never restorable. Name what was picked and what was expected; never 'invalid file'."
},
"restoreRefusedDatabaseCopy": "This is a diagnostics copy of a database, not a backup. It cannot be restored in the app.",
"@restoreRefusedDatabaseCopy": {
  "description": "Shown for a file starting 'SQLite format 3'. That is the VACUUM INTO snapshot from Settings, Diagnostics — deliberately not an in-app restore path (04 2.8). tool/snapshot_to_backup.dart converts it, and that is a developer tool, not a code path on the phone."
},
"restoreRefusedNotABackup": "This file is not a Shed Book backup. Choose the .json file the app shared when you exported.",
"@restoreRefusedNotABackup": {
  "description": "The catch-all for an unrecognised first byte — most often a photo the shepherd renamed. It says what to pick instead, because at 2am 'unsupported format' is not an instruction."
}
```

### 5.3 The details that are easy to get wrong

- **The byte check runs before the parse, and the ordering is the whole task.** A parser that decodes
  first and validates second gives a shepherd a `FormatException` for a photo, and — worse — decodes an
  arbitrary attacker-shaped or corrupt file before deciding it was never a backup. Sniff, then decode,
  then validate the header. The anchor's broken-JSON tail is what proves the order rather than the
  outcome.
- **`readAsBytes()` on the picked file is the one-line trap.** The shepherd picked a file at 2am; it may
  be a 4 GB video. Open it with `RandomAccessFile`, `read(512)`, close it. And **copy by streaming** —
  `File(picked).openRead().pipe(sink)` — never `writeAsBytes(await readAsBytes())`, which materialises
  the whole file at exactly the moment the phone is short of memory.
- **Fewer than 512 bytes is legal and must not be assumed away.** `read(512)` returns what it has. A
  0-byte file is `unrecognised`. A file shorter than 16 bytes cannot be a SQLite database, and the sniff
  must not index past the end to find that out.
- **"First non-whitespace byte" means JSON whitespace, which is four bytes and not five.** Space `0x20`,
  tab `0x09`, line feed `0x0A`, carriage return `0x0D`. Vertical tab and form feed are **not** JSON
  whitespace, and treating them as such accepts a file `jsonDecode` will then reject.
- **A leading byte-order mark is a decision this task has to take, not skip.** This app never writes one
  (09 §2.4), so `EF BB BF {` is not a file we produced — but it is exactly what an email client or a text
  editor produces from a file we did. **Rule: skip a leading `EF BB BF` before sniffing and strip it
  before decoding, and log that it was present.** The cost of the strict reading is a shepherd losing
  their records over three bytes somebody else's software added; the cost of the permissive one is a
  logged oddity. Write the reason beside the branch, and test both a file with the mark and one without.
- **`restore_flow.dart` may not construct a `File`.** `File(` anywhere under `lib/features/**` is banned
  (04 §4.9, `layer.features`). It returns the `XFile` from the picker and hands the **path** down;
  `lib/data/` builds the `File`. That is also how 08 §11's *"`RestoreService` takes a `File`"* is
  satisfied without a plugin type crossing a layer: the seam carries a `String`.
- **`file_selector` has no gateway class, and that is the one deliberate exception** (08 §6). The
  single-call-site guarantee that a gateway would buy is bought instead by `layer.plugin_file_selector`,
  which is the same guarantee by the same mechanism. Do **not** invent an eighth seam to make it look
  like its neighbours — `CONVENTIONS` §2.12 fixes the list at seven and adding one is a ruling.
- **A cancelled picker is not a failure.** `openFile` returns `null` and the flow aborts saying nothing
  (04 §7.2 step 1). No banner, no log line, no *"restore cancelled"* toast.
- **The Android URI grant can be one-shot**, which is why the copy happens immediately and before
  anything else looks at the file. On iOS the picked path may be security-scoped for the same practical
  reason. Copy to `<temp>/restore/incoming.json`, then work only from the copy.
- **`.zip` is not accepted in v1, on purpose.** Media is not in a v1 backup (#85), so a photo archive can
  never be restorable — and the refusal says exactly that rather than "unsupported". Adding `.zip` later
  is one line in the `XTypeGroup` and one branch in the sniff, and both are blocked on verifying
  `ZipFileEncoder`'s incremental-write behaviour first (09 §10 item 7).
- **The `SQLite format 3` branch is not paranoia — that file exists and a shepherd can reach it.**
  `VACUUM INTO` writes a diagnostics snapshot the user can share out of Settings ▸ Diagnostics (04 §2.8),
  and it is deliberately **not** an in-app restore path. Two restore paths would be two migration
  surfaces. The refusal names it by what it is, and `tool/snapshot_to_backup.dart` is the developer-side
  converter.
- **Nothing is written to the database during validation, and the signature is why.**
  `readBackupPrelude` is a top-level function holding no `AppDatabase`; `sniffBackupFile` takes a byte
  list. Neither *can* write a row, so the DoD item is structural rather than a habit.
- **`WriteController.guard()` belongs to the confirmation, not here** (04 §7.2 step 0). It is the
  double-tap defence on the destructive action, and the destructive action is N23-T02's. Note the
  boundary in the file rather than adding a guard around a read.
- **The refusal names what was chosen and what was expected.** *"This file is not a Shed Book backup"*
  alone leaves a shepherd hunting; the sentence that helps says what to pick instead. Every one of the
  three carries the found kind on the value as well, for the diagnostics log.
- **`file_selector` merges no permission on either platform** — Android's `ACTION_OPEN_DOCUMENT` returns a
  per-file grant, iOS uses `UIDocumentPickerViewController`. That is the reason it was chosen over
  `file_picker`, whose headline feature is cloud picking: *"a restore picker that invites the shepherd
  into Google Drive actively undercuts the thing the product is sold on."* If the `android` job's G1
  assertion moves on this branch, that is the finding.

### 5.4 The full test set

`test/features/backup_import_test.dart`. Real temp files, no picker: `pickBackupFile()` is a one-line
call into the plugin and has nothing to unit-test — everything below the picker takes a path.

| Case | What it asserts |
|---|---|
| `'a renamed JPEG is refused by the magic-byte check before any parse begins'` | **The anchor.** `FF D8 FF E0` head, deliberately broken JSON tail, `BackupRefused(notABackupFile)`, and no `FormatException` |
| `'a ZIP is refused by name'` | `50 4B 03 04` → the photo-archive sentence, not the catch-all |
| `'a SQLite database is refused by name'` | `SQLite format 3\0` → the diagnostics-copy sentence |
| `'a zero-byte file is refused and does not throw'` | The empty case, which is the one that indexes past the end |
| `'a file shorter than the SQLite header is refused and does not throw'` | Eight bytes of `SQLite f` |
| `'leading JSON whitespace is skipped and the file is accepted'` | Space, tab, LF and CR before the brace |
| `'a vertical tab before the brace is refused'` | Not JSON whitespace; accepting it accepts a file `jsonDecode` rejects |
| `'a leading byte-order mark is skipped, stripped and logged'` | The decision in §5.3, with the log line asserted |
| `'a valid backup is accepted and its header is returned'` | The path the shepherd actually takes |
| `'the picked file is copied before it is read'` | The copy exists at `<temp>/restore/incoming.json` and the original is untouched |
| `'the copy is streamed, not materialised'` | Source text: no `readAsBytes` and no `writeAsBytes` on the import path |
| `'only 512 bytes are read for the sniff'` | A large fixture; assert the read length, not the file length |
| `'a cancelled pick aborts and says nothing'` | A null path produces no refusal, no log line and no banner |
| `'nothing is written to the database during validation'` | Run the whole prelude against a seeded in-memory database and assert every table's row count is unchanged |
| `'readBackupPrelude holds no AppDatabase'` | It is a top-level function; the signature is the proof |
| `'package:file_selector is imported by exactly one file'` | Source text over `lib/**`, naming the file — `layer.plugin_file_selector` made executable here rather than waiting for the gate |
| `'no File( appears under lib/features/'` | The `layer.features` rule, asserted where it is most likely to be broken |
| `'each refusal names the kind found and the kind expected'` | Over all four kinds |

**The `uk-zone` group.**

| Case | What it asserts |
|---|---|
| `'this group requires TZ=Europe/London'` | Fails loudly under a wrong `TZ` |
| `'DST: a header written in the ambiguous 01:00–01:59 hour is accepted with its own offset, not re-derived'` | `exportedAtOffsetMinutes` of both `60` and `0` are accepted for the same local `01:30`, and neither is recomputed from the importing phone's clock |
| `'DST: exportedAtUtc is read as an instant and never re-rendered'` | The header's characters survive into the outcome unchanged |

## 6. Constraints that bind this task

- **The five safety rules — §12.4, held by ordering.** Refusing before parsing, and parsing before
  touching anything, is what makes *"refuse a corrupt file; never half-import one"* structural. The
  destructive half is N23's, and nothing on this branch can reach it.
- **The 3am test** — the refusal is read once, by a tired person, on the phone they just bought. It names
  what they picked and what to pick instead. `showDialog(` is allowlisted for exactly two files and this
  is not one of them; nothing here renders anyway.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. `file_selector` **1.1.0** merges **no** permission on either platform, and the `android` job's G1 assertion must not move on this branch.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. **Restore** is the word for replacing everything; *import* and *merge* are not synonyms for it, and there is no merge.

## 7. Definition of Done

- [ ] `'a renamed JPEG is refused by the magic-byte check before any parse begins'` passes, and was seen to fail first for the stated reason
- [ ] the byte check runs before any parse
- [ ] the refusal names what was chosen and what was expected
- [ ] nothing is written to the database during validation
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `package:file_selector` is imported by exactly one file, `lib/features/settings/restore_flow.dart`
- [ ] no `File(` appears anywhere under `lib/features/`, and the seam between the picker and `lib/data/` carries a `String`
- [ ] `sniffBackupFile` is pure and does no I/O; `readBackupPrelude` is a top-level function holding no `AppDatabase`
- [ ] a ZIP and a SQLite database are each refused **by name**, not by the catch-all
- [ ] a zero-byte file, an eight-byte file and a file with only whitespace are all refused without throwing
- [ ] the leading byte-order-mark decision is taken, written down beside the branch, and covered in both directions
- [ ] the picked file is copied by streaming before it is read; `readAsBytes` appears nowhere on the import path
- [ ] a cancelled pick aborts silently — no refusal, no log line, no banner
- [ ] every added ARB message has a `description` and the regenerated `lib/l10n/app_localizations*.dart` is committed in this commit
- [ ] **the `uk-zone` DST group exists, is tagged, fails loudly under a wrong `TZ`, and covers the 01:00–01:59 ambiguous hour**
- [ ] the diff adds no permission to either platform and the `android` job stays green

## 8. Verification

```bash
fvm flutter test test/features/backup_import_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

```bash
grep -rn "package:file_selector" lib/       # expect exactly one file
grep -rEn "[^X]File\(" lib/features/        # expect zero — XFile( is share_plus's and is not a File
grep -rn "readAsBytes" lib/data/restore_service.dart lib/features/settings/restore_flow.dart   # expect zero
git diff -- android/ ios/                   # expect empty
```

Then try it by hand on a real device build, because a picker is the one thing a unit test cannot prove:
pick a photo and confirm the refusal names it; pick the diagnostics snapshot from Settings ▸ Diagnostics
and confirm it is refused by name; pick a real backup and confirm the header is read.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(backup): file import with magic bytes validated by us`

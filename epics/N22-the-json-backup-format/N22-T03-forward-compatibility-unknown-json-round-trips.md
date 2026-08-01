# N22-T03 — Forward compatibility — `unknown_json` round-trips

| | |
|---|---|
| **Epic** | [N22 — The JSON backup format](epic.md) · `00-README` §9 step 8 (2 of 3) |
| **Task** | 3 of 5 |
| **Depends on** | N22-T02 |
| **Commit** | one commit · `feat(backup): forward compatibility through unknown_json` |

## 1. Why this task exists

A column a **newer** build wrote survives a round trip through an older one: it lands in
`unknown_json` and is re-emitted at the row's top level. And a backup from a higher schema version is
**refused clearly** — in words a shepherd can act on, not a stack trace.

The asymmetry is the whole design and it is worth stating plainly: **a newer file opened by an older app
is refused; an older file opened by a newer app is accepted.** Refusing forward is the only
§12.4-compatible answer — an older app cannot know what a newer column means, and guessing is silently
corrupting a record. Accepting backward is what makes the backup a backup at all: a 2027 file restored
onto a 2029 app is the *normal* case, not an edge one.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/09-export-formats.md` | §5.5 (the six-row behaviour table and the refusal wording, verbatim) · §5.6 (surviving a schema migration, `importDefaults`, and the two rules that keep it tractable) · §5.3 (`unknown_json` is the one column never emitted under its own name) · §7.2 rule 8 (merged **before** the keys are sorted) · §9 (the anti-pattern row and what catches it) | the contract, word for word |
| `docs/engineering/04-migrations-media-backup-restore.md` | §6.5 (the same table, plus the rejected side-table design) · §6.7 (`import_defaults.dart` and its completeness test) · §7.2 step 3 (validate the header) · §7.4 (what the user loses in each failure, which is nothing) | the second statement, and the import side |
| `docs/engineering/03-data-model-and-schema.md` | §5 (`unknown_json` on all 21 restorable tables — `text().nullable()` plus `CHECK (unknown_json IS NULL OR json_valid(unknown_json))`) | the column this task consumes |
| `docs/engineering/10-accessibility-and-i18n.md` | §8.4 (ARB house rules — `lowerCamel` ids, a `description` on every message carrying the safety rationale) · §8.7 (the closed list of strings that are **not** ARB messages) | where the refusal wording lives |
| `docs/engineering/CONVENTIONS.md` | §2.5 (`ShedFailure` is sealed with six variants — this is not a seventh) · §2.10 (`RefusalReason` is already taken by the free tier) · §5.3 (banned words: no `Error` as a failure-type name) | what the refusal may and may not be called |
| `epics/00-PLAN-CRITIQUE.md` | §11.3 | this task's anchor id and file |
| `CLAUDE.md` | the offline-purity section | the words that may never be used about the checksum |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-export-and-restore` | forward compatibility is the format's hardest promise |
| `shed-bootstrap-and-errors` | the refusal's wording and its failure type |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/backup_forward_compat_test.dart`
- **Test** — `'an unknown column survives into unknown_json and is re-emitted at the row top level'`
- **Why it is red today** — nothing preserves unknown columns, so an older build silently drops a newer one's data.

```bash
fvm flutter test test/features/backup_forward_compat_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it cannot pass by accident. Take a real exported row, add a key today's schema
does not have — `{"tupping_ram_tag": "R7"}` — hand it to the row reader, and assert three things: the
row's `unknown_json` column holds exactly `{"tupping_ram_tag":"R7"}`; the **next** export emits
`tupping_ram_tag` at the row's **top level**, sorted into place between `treatment_uid` and
`updated_at`, not appended; and the string `"unknown_json"` appears **zero** times in the whole file.
Then export the same row twice and assert the bytes are identical — a splat that merges *after* the sort
produces a correct-looking file whose key order is wrong, and only byte equality catches it.

**Green.** The minimum code that passes, and nothing beyond it — the capture, the re-emission, and the higher-schema refusal.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema.** `unknown_json` already exists on all 21 restorable tables with its `json_valid` `CHECK`
(N07-T06) — this task is the first code that uses it. Say so in the commit message: the schema step is
skipped because the column was landed at the freeze, deliberately, so that this contract would not be
inert. No domain, no wiring, no controller.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/backup_format.dart` | Edit. Adds the splat on the way out, the capture on the way in, and the header validation with its refusal type. The capture belongs here rather than in the importer, because it is a *format* rule and N23's `RestoreService` calls it |
| 2 | `lib/data/import_defaults.dart` | **New.** `const importDefaults` (`CONVENTIONS` §1 already names the path). Empty at schema v1 and correctly so; the value is the completeness test beside it |
| 3 | `lib/data/export_repository.dart` | Edit. The row reader now merges the parsed container before sorting, and never emits the column |
| 4 | `lib/l10n/app_en.arb` | Edit. The refusal messages, each with a `description` carrying the reason it may not be softened |
| 5 | `lib/l10n/app_localizations*.dart` | Regenerated by gen-l10n and **committed in this same commit** (`00-README` §7.1) — the `codegen` job diffs `lib/` |
| 6 | `test/features/backup_forward_compat_test.dart` | **New.** The anchor plus the cases in §5.4 |
| 7 | `test/policy/import_defaults_are_complete_test.dart` | **New.** The CI guard 09 §5.6 describes, read against the committed schema JSON |

### 5.2 The signatures

```dart
// lib/data/backup_format.dart

/// Parsed from the file's first thirteen keys, before anything else happens.
/// Returns an outcome rather than throwing: a refusal is a value the restore
/// screen renders, not an exception escaping into the UI (01 §5).
sealed class BackupHeaderOutcome { const BackupHeaderOutcome(); }

final class BackupHeaderAccepted extends BackupHeaderOutcome {
  const BackupHeaderAccepted(this.header);
  final BackupHeader header;
}

final class BackupRefused extends BackupHeaderOutcome {
  const BackupRefused(this.reason, {this.foundFormatVersion, this.foundSchema});
  final BackupRefusalReason reason;
  final int? foundFormatVersion;    // what the file says
  final int? foundSchema;           // what the file says
  int get readsFormatVersion => kBackupFormatVersion;   // what this build reads
  int get readsSchema => kSchemaVersion;
}

enum BackupRefusalReason {
  notShedBookFormat,     // `format` is absent or is not the frozen string
  newerFormatVersion,    // formatVersion > kBackupFormatVersion  — 09 §5.5 row 1
  newerSchema,           // schema      > kSchemaVersion          — 09 §5.5 row 2
  malformedHeader,       // a required key is missing or the wrong type
}

/// Validates the thirteen header keys and nothing else. It touches no file and
/// no database, so it is unit-testable against a String.
BackupHeaderOutcome readBackupHeader(Map<String, Object?> decoded);

/// Merges a row's parsed `unknown_json` into the row object BEFORE the keys are
/// sorted, and never emits the column itself (09 §5.3, §7.2 rule 8).
Map<String, Object?> splatUnknownJson(Map<String, Object?> row);

/// The inverse, used by N23's importer: every key the target table does not have
/// is lifted out into the container. Returns the row plus its `unknown_json`.
({Map<String, Object?> row, String? unknownJson}) captureUnknownColumns(
  Map<String, Object?> incoming, Set<String> knownColumns);
```

```dart
// lib/data/import_defaults.dart
/// Value written when a restored row predates the column (09 §5.6, 04 §6.7).
/// STRUCTURAL values only — never a domain value the user did not enter.
/// EMPTY at schema v1, and that is the correct value: a v1 backup carries every
/// v1 column, so nothing can be missing yet.
const importDefaults = <String, Map<String, Object?>>{};
```

The refusal wording, verbatim from 09 §5.5 and 04 §6.5, as one ARB message plus one detail message:

```json
"restoreRefusedNewerApp": "This backup was made by a newer version of Shed Book. Update the app and try again.",
"@restoreRefusedNewerApp": {
  "description": "Shown when formatVersion or schema in the file is higher than this build can read. Do not soften this to 'may not be compatible': guessing at a newer schema is spec 12.4 applied to restore, and a partial import would destroy records. 09-export-formats.md 5.5."
},
"restoreRefusedNewerAppDetail": "This file: format {foundFormat}, records {foundSchema}. This app reads format {readsFormat}, records {readsSchema}.",
"@restoreRefusedNewerAppDetail": {
  "description": "The second line under restoreRefusedNewerApp. Named numbers, so a shepherd on the phone to a friend can say which build wrote the file. Never replaces the sentence above it.",
  "placeholders": {
    "foundFormat":  { "type": "int" },
    "foundSchema":  { "type": "int" },
    "readsFormat":  { "type": "int" },
    "readsSchema":  { "type": "int" }
  }
}
```

### 5.3 The details that are easy to get wrong

- **The splat happens *before* the sort, and this is the single easiest thing to get wrong here.** Merge
  the parsed container into the row map, then sort the merged result. Merging after the sort produces a
  file that decodes correctly, reads correctly and looks right in `jq` — and whose key order is wrong, so
  the second export is not byte-identical to the first. Only T01's byte-equality assertion catches it,
  which is why that assertion is worth having.
- **The container is never emitted under its own name.** Emitting `unknown_json` *as well* writes every
  preserved field twice — once splatted, once as a JSON string inside the container — and the next export
  nests it again, one level deeper each time. 09 §9 lists this as its own anti-pattern row for that
  reason.
- **A preserved key that collides with a live column: the live column wins, and the collision is
  logged.** In theory it cannot happen — if the column exists today, the key is not unknown. In practice
  it happens the moment someone hand-edits a backup or a column is added and the older file is replayed
  through a build that has since gained it. Decide it in code rather than letting map-merge order decide
  it silently, and write the reason beside the line.
- **Preserved values are passed through, never re-parsed.** A preserved key whose value looks like an
  instant is a *string* to this build. Do not `DateTime.parse` it, do not normalise it, do not re-render
  it. The build that wrote it knows what it means; this one does not, and the entire point of the
  container is to carry it without interpreting it.
- **An unknown *table* goes into `app_settings.unknown_json` under its table name, and is logged.** It is
  never dropped silently. `app_settings` is the singleton with exactly one row, which is why it is the
  home for a table-level residue that has no parent to hang off.
- **`json_valid` must actually hold.** The column has `CHECK (unknown_json IS NULL OR json_valid(unknown_json))`,
  so writing a bare string, an empty string or a JSON array will throw a `SqliteException` from the
  importer. Write a JSON **object** or write `NULL` — and `NULL` for a row with nothing unknown, never
  `'{}'`, because `'{}'` and `NULL` are different bytes on the next export.
- **`ShedFailure` is not the type for this.** It is sealed with six variants (`CONVENTIONS` §2.5, R8) and
  its `userMessage` strings are deliberately outside the ARB, because they must render when the database
  is unreadable. A refused backup is a *validation outcome* on a file the app could read perfectly well;
  it gets its own sealed type in `backup_format.dart`, and its wording is an ARB message.
- **`RefusalReason` is already taken.** `lib/domain/free_tier.dart` declares
  `enum RefusalReason { secondSeason, eweCap }` (`CONVENTIONS` §2.10). This enum is `BackupRefusalReason`
  and there is no import that could make the two collide, which is exactly how a reader ends up believing
  they are the same concept.
- **No type here may be named `…Error`.** `Error` as a failure-type name is a banned word
  (`CONVENTIONS` §5.3). `BackupRefused` says what happened.
- **The refusal names its numbers, and the sentence stays verbatim.** 09 §5.5 fixes the sentence; the
  four numbers ride on `BackupRefused` and render as the second line, and they also go to
  `LocalLog.instance` (R52) as `restore.refused.<reason>` with no row contents (#124). Do not fold the
  numbers into the sentence — a translator would then be editing a safety string.
- **The refusal happens before anything is touched.** *"Any failure aborts before the restore
  confirmation screen is ever shown, with the reason. Refuse a corrupt file; never half-import one."*
  `readBackupHeader` takes a decoded map and touches neither the filesystem nor the database, which is
  what makes that structural rather than a matter of call order.
- **`schema` lower than `kSchemaVersion` is the normal case and must be accepted.** A test that only
  covers the refusals leaves the accept path unproven, and the accept path is the one a real shepherd
  uses on a new phone in 2029.
- **The `importDefaults` completeness test, read literally, is red at v1 for correct reasons.** 09 §5.6
  says: enumerate every `NOT NULL` column with no `defaultValue` and no `clientDefault` and assert each
  is a primary key, a `uid`, or in `importDefaults`. At schema v1 that set includes `ewes.tag`,
  `ewes.tag_digits`, `seasons.year` and a dozen more — none of which needs an import default, because a
  v1 backup carries every v1 column. **The set the rule is about is the difference:** columns present in
  `drift_schema_v<kSchemaVersion>.json` and absent from `drift_schema_v1.json`. At v1 that difference is
  empty and the test is trivially green; at v2 it becomes the thing that stops a v4 app refusing to
  restore a v2 backup. Write it as the difference, and put this paragraph in the test file so the next
  reader does not "fix" it back.
- **A column's fallback may never be a domain value.** A treatment imported from a schema that predates
  `treatment_withdrawals` produces **no** withdrawal row, which the sealed type reads as
  `WithdrawalNotRecorded`. That is the correct answer and the only correct answer — §12.1 is enforced by
  the *absence* of a row, and an import default would be the one place it could be defeated.
- **Column renames are banned** (09 §5.6, 04 §2.1 rule 4). A rename needs a per-version alias map, which
  is a second migration surface. New meaning means new column means new name.

### 5.4 The full test set

`test/features/backup_forward_compat_test.dart`, plus one file in `test/policy/`.

| Case | What it asserts |
|---|---|
| `'an unknown column survives into unknown_json and is re-emitted at the row top level'` | **The anchor.** Capture, storage, re-emission, sorted into place, and `"unknown_json"` absent from the file |
| `'two exports of a row carrying a preserved column are byte-identical'` | The splat ran before the sort. The case that catches merge-after-sort |
| `'a preserved value is never re-parsed'` | A preserved instant-shaped string comes back byte-identical, not re-rendered |
| `'a row with nothing unknown stores NULL, not an empty object'` | `NULL` and `'{}'` are different bytes on the next export |
| `'unknown_json is rejected by the CHECK when it is not a JSON object'` | Writing a bare string throws `SqliteException` — the schema holds it, not the writer |
| `'a preserved key that collides with a live column loses, and the collision is logged'` | The decided behaviour, rather than whatever map-merge order happens to do |
| `'an unknown table lands in app_settings.unknown_json under its table name and is logged'` | Never dropped silently (09 §5.5 row 6) |
| `'a file with formatVersion 2 is refused with reason newerFormatVersion'` | And `foundFormatVersion` is 2, `readsFormatVersion` is 1 |
| `'a file with schema kSchemaVersion + 1 is refused with reason newerSchema'` | Derived from the constant, never a typed number |
| `'a file with a lower schema is accepted'` | The normal 2027-onto-2029 case |
| `'a file whose format is not the frozen string is refused with reason notShedBookFormat'` | Some other application's JSON |
| `'a header missing a required key is refused with reason malformedHeader, not an exception'` | A truncated header is a value, not a crash |
| `'readBackupHeader touches no file and no database'` | It takes a decoded map; the signature is the proof |
| `'the refusal sentence is the ARB message verbatim and carries its four numbers on the value'` | The sentence is not edited to contain the numbers |
| `'every refusal is logged as restore.refused.<reason> with no row contents'` | `LocalLog.instance` (R52), redaction rules (#124) |
| `'importDefaults is complete against the committed schema JSON'` | `test/policy/import_defaults_are_complete_test.dart` — the **difference** between v1 and head, empty at v1 |
| `'no import default is a domain value'` | Every value in the map is `0`, `null`, `''` or a copy of another column |

**The `uk-zone` group.**

| Case | What it asserts |
|---|---|
| `'this group requires TZ=Europe/London'` | Fails loudly under a wrong `TZ` |
| `'DST: a preserved instant-shaped string in the ambiguous 01:00–01:59 hour is passed through, not re-parsed'` | `2026-10-25T01:30:00.000Z` in, the same characters out. Re-parsing it would resolve the ambiguity this build has no right to resolve |
| `'DST: a preserved civil date is never widened into an instant'` | `2026-10-25` in, `2026-10-25` out, no time and no zone acquired |

## 6. Constraints that bind this task

- **The five safety rules — §12.4, held structurally.** Refusing a newer file is §12.4 applied to
  restore: guessing what a newer column means is silently corrupting a record. Preserving an unknown
  column rather than dropping it is the same rule pointed the other way — the app does not silently
  destroy what it does not understand. Both are held by the format, not by a reviewer.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies. The refusal messages' descriptions carry the reason they may not be softened, per 10 §8.4 rule 2.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. **Restore** never becomes *import* or *merge* — there is no merge, and there is no merge code to call.

## 7. Definition of Done

- [ ] `'an unknown column survives into unknown_json and is re-emitted at the row top level'` passes, and was seen to fail first for the stated reason
- [ ] unknown columns survive a full round trip
- [ ] a higher-schema file is refused with actionable words
- [ ] the refusal names the version it found and the one it can read
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the splat runs **before** the keys are sorted, proved by byte equality across two exports
- [ ] `"unknown_json"` appears zero times in an exported file
- [ ] a preserved value is passed through and never re-parsed, re-rendered or normalised
- [ ] a row with nothing unknown stores `NULL`, never `'{}'`
- [ ] an unknown table lands in `app_settings.unknown_json` under its table name and is logged
- [ ] a lower `schema` is **accepted** — the normal case has a test, not only the refusals
- [ ] the refusal is a sealed value in `backup_format.dart`, not a seventh `ShedFailure`, and nothing is named `…Error`
- [ ] `readBackupHeader` touches no file and no database
- [ ] `lib/data/import_defaults.dart` exists, is empty at schema v1, and its completeness test is green over the **difference** between v1 and head
- [ ] every added ARB message has a `description` and the regenerated `lib/l10n/app_localizations*.dart` is committed in this commit
- [ ] **the `uk-zone` DST group exists, is tagged, fails loudly under a wrong `TZ`, and covers the 01:00–01:59 ambiguous hour**

## 8. Verification

```bash
fvm flutter test test/features/backup_forward_compat_test.dart
fvm flutter test test/policy/import_defaults_are_complete_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

```bash
grep -rn "unknown_json" lib/data/export_repository.dart   # expect: only the skip and the splat
grep -rn "Error\b" lib/data/backup_format.dart            # expect zero failure-type names
git diff --name-only | grep app_localizations             # expect: regenerated, in THIS commit
```

Then prove the round trip by hand on one file, because the promise is to a person:

```bash
jq -r '[.tables[][] | keys[]] | map(select(. == "unknown_json")) | length' backup.json   # expect 0
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(backup): forward compatibility through unknown_json`

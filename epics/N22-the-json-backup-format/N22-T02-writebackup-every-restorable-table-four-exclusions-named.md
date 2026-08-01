# N22-T02 — `writeBackup` — every restorable table, four exclusions named

| | |
|---|---|
| **Epic** | [N22 — The JSON backup format](epic.md) · `00-README` §9 step 8 (2 of 3) |
| **Task** | 2 of 5 |
| **Depends on** | N22-T01 |
| **Commit** | one commit · `feat(backup): writeBackup over every restorable table` |

## 1. Why this task exists

All 21 restorable tables including `vocab_terms` — a shepherd who renamed *ewe* to *gimmer*
and edited the death-cause list must get those back — with the four exclusions **named in the source**
and **no base64**, because a backup nobody can read in a text editor is a backup nobody can salvage by
hand at 2am.

`vocab_terms` is the cautionary tale rather than a nicety: five columns are `RESTRICT` foreign keys onto
`vocab_terms.key`, so a user-added term that is not in the file makes the restore fail its own
`PRAGMA foreign_key_check` — on the night someone is restoring onto a replacement phone. It was missing
from 04 §6.2's list and 09 §1.3 put it back. That is what an omission here costs.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/09-export-formats.md` | §5.2 (the twenty-one table keys, listed) · §5.3 (a real row, the identity rule, the vocabulary exception, the five `uid`-less tables, every column emitted `null` included, no floats) · §5.4 (what is in and what is out, with reasons) · §7.2 rules 1, 3, 4, 7, 9, 11, 12, 13 (what must be true for the round trip) · §9 (`copy.base64_backup`) | which tables, which columns, which order |
| `docs/engineering/04-migrations-media-backup-restore.md` | §6.2 (the header's illustrative `tables` block — twenty entries, missing `vocab_terms`; 09 §1.3 corrects it) · §6.3 (the field rules) · §6.4 (in and out) · §6.9 (the anti-pattern table) | the second statement of the same rules, and where it is stale |
| `docs/engineering/03-data-model-and-schema.md` | §5 (every column of every table) · §5.12 (`vocab_terms.key` — globally unique, list-prefixed, ASCII, **stable forever**) · §5.13 (`ewe_summaries` is a rebuildable cache) | what each column means and why two tables are out |
| `docs/engineering/CONVENTIONS.md` | §1.1 layer rules 3, 4, 8 · §2.8 (`lib/data/models.dart` re-exports all 23 row classes) · §2.13 (`ExportRepository` owns writes to **nothing** — read and assembly only) · R18, R20 | the layer this runs in, and the 23 the 21 come out of |
| `docs/engineering/12-testing.md` | §10.6 (the equality property and the header trap) · §4 (the in-memory drift harness) | how the test is built |
| `CLAUDE.md` | the offline-purity section | the words that may never be used about the checksum |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-export-and-restore` | what is in a backup and what is deliberately not |
| `shed-drift-schema` | the restorable table list and `unknown_json` |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/backup_format_test.dart`
- **Test** — `'writeBackup emits all 21 restorable tables and names its four exclusions'`
- **Why it is red today** — nothing writes a backup: the header exists but no table is emitted, so a restore would have nothing to read.

```bash
fvm flutter test test/features/backup_format_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so the count cannot go stale. Derive the expected set from `db.allTables` minus
the four exclusions **named as literals with their reasons in the test**, assert its length is 21, and
assert `decoded['tables'].keys` equals that set exactly — in both directions, so a table added in season
two fails here rather than being silently dropped from every backup. Then assert `counts` has the same
21 keys, zeros included, over an **empty** database: a table absent from `counts` is a table nothing
verifies.

**Green.** The minimum code that passes, and nothing beyond it — the writer, the table list derived from the schema, and the exclusions with their
reasons.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema, no domain, no wiring, no controller, no UI, no ARB.** The schema is frozen at N07 and this
task adds nothing to it — say so in the commit message. `exportRepositoryProvider` already exists
(`CONVENTIONS` §3.1, wired at N21-T07); this task adds a verb to the class behind it, not a provider.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/backup_format.dart` | Edit. Adds the four named exclusions, the backup order key per table, and the declared foreign-key map. All three are *format* facts, so they live with the format and not with the repository |
| 2 | `lib/data/export_repository.dart` | Edit. Adds `writeBackup`, the per-table `customSelect`, the row-to-map conversion and the `ExportArtifact` it returns. This class writes nothing to the database (`CONVENTIONS` §2.13) and this verb does not change that |
| 3 | `test/features/backup_format_test.dart` | Edit. Adds the anchor and the cases in §5.4 to T01's file — one file, not a second |

### 5.2 The signatures

```dart
// lib/data/export_repository.dart — 09 §1.1's verb, 12 §10.6's call shape.
Future<ExportArtifact> writeBackup({required ExportEnvelope envelope});
// typedef ExportArtifact = ({String path, String shareName, int byteSize});  (09 §1.2)
```

```dart
// lib/data/backup_format.dart

/// The four tables that are NOT in a backup. Each carries its reason here,
/// because 09 §5.4's rule is: if you add a table it is exported unless you
/// write down why not, in the same commit.
const Set<String> kBackupExcludedTables = {
  'entitlements',   // never exported, ignored on import — restoring your
                    // neighbour's backup must not unlock your app (#88)
  'ewe_summaries',  // a rebuildable cache (03 §5.13); its rebuilt_at moves,
                    // which would break byte equality on every export
  'search_docs',    // derived — refilled by the source-table triggers on import
  'search_fts',     // derived — rebuilt in one statement after the rows land
};

/// The ORDER BY for each table, so two exports of one database agree.
/// Sixteen tables carry `uid` and order by it. These five do not (09 §5.3),
/// and each orders by the natural key that stands in for it — resolved to the
/// PARENT'S uid, never to the local integer.
const Map<String, List<String>> kBackupOrderKeys = {
  'app_settings':        <String>[],                    // exactly one row
  'ewe_touches':         ['ewe_uid'],
  'pen_occupancy_lambs': ['occupancy_uid', 'lamb_uid'],
  'reminder_rules':      ['kind'],                      // a stored key
  'terminology_overrides': ['key'],
};

/// Every foreign key that points at a ROW, per table: the SQLite column name
/// mapped to the table it points at. The emitted key is the column name with
/// `_uid` appended and the value is the parent row's uid (#32).
/// Vocabulary foreign keys are deliberately absent — see the gotchas.
/// Completeness is proved against drift_schemas/drift_schema_v<N>.json.
const Map<String, Map<String, String>> kBackupForeignKeys = { /* … */ };
```

The five vocabulary foreign keys are the exception and are **not** in that map. `lambings.presentation`,
`lambs.death_cause`, `treatments.route`, `ewe_observations.kind` and `foster_events.method` point at
`vocab_terms.key`, and the key *is* the identity — 03 §5.12: *"globally unique, list-prefixed, ASCII,
stable forever… never translated and never edited."* So the column keeps its own name and its own value:
`"route": "rt_subcutaneous"`, never `"route_uid"`.

The twenty-one table keys, in the order they appear in the file (canonical, ascending by code unit):

```
app_settings · care_events · ewe_observations · ewe_seasons · ewe_touches · ewes ·
foster_events · lambings · lambs · media_assets · notes · pen_occupancies ·
pen_occupancy_lambs · pens · reminder_rules · reminders · seasons ·
terminology_overrides · treatment_withdrawals · treatments · vocab_terms
```

### 5.3 The details that are easy to get wrong

- **`ORDER BY id` is the bug this whole task is built to avoid.** Integer primary keys are re-issued on
  import (#32), so an id-ordered export makes the *second* export a permutation of the first and byte
  equality fails somewhere in the middle of a 40,000-row file, with a diff nobody can read. Every table
  with a `uid` is `ORDER BY uid`. **This rule is about the backup only** — the three CSVs order by the
  keys 09 §3 names, because a CSV is read by a human in the order a shepherd thinks in and no CSV is
  ever re-imported.
- **The five `uid`-less tables order by the *parent's* `uid`, which means a join.** `ORDER BY ewe` on
  `ewe_touches` compiles, runs, and is stable on the exporting phone — and is a different order after a
  restore. Join to `ewes` and order by `ewes.uid`. Same for `pen_occupancy_lambs`, which needs two joins
  and orders by `occupancy_uid` then `lamb_uid`.
- **Code-unit order is not the alphabetical order you would write by hand.** `_` is 0x5F and `s` is
  0x73, so `ewe_touches` sorts **before** `ewes`, `pen_occupancies` and `pen_occupancy_lambs` both sort
  before `pens`, and `treatment_withdrawals` sorts **before** `treatments`. A sort that strips
  underscores, or a hand-typed list in "sensible" order, produces a file that is one byte-comparison away
  from correct and fails only once both tables are non-empty.
- **`counts` must have one entry per key in `tables` — 21, zeros included.** 09 §5.2 is explicit that
  the check *"is per table and cannot be partial: a table absent from `counts` is a table nothing
  verifies."* The empty-database case is the one that catches a `counts` map built by iterating rows
  instead of tables.
- **Read raw storage values, not typed row classes.** `customSelect(...).get()` returns `QueryRow`s whose
  `data` is a `Map<String, Object?>` keyed by the exact SQLite column name — which is precisely the shape
  09 §5.3 asks for. `db.select(db.treatments)` applies the type converters and gives you `camelCase`
  fields, and drift's generated `toJson()` emits `camelCase` keys. Both are wrong: **every key inside
  `tables` is a SQLite column name in `snake_case`.** `customSelect` is permitted here; `customStatement(`
  outside `lib/core/db/` is the banned one (layer rule 8).
- **Instants are the one conversion, and it is `int` → ISO-8601 UTC with milliseconds and a `Z`.** Raw
  storage gives you epoch millis (#29). `2026-03-14T03:20:42.015Z` — always three fractional digits,
  always `Z`, never a local ISO string and never a bare epoch integer. Civil dates are already
  `'YYYY-MM-DD'` `TEXT` and pass through **untouched**: never re-parsed into a `DateTime` and back, and
  a `PartialDate` (`2023`, `2023-04`, `2023-04-11`) is never padded to 1 January.
- **Which columns are instants has to be provable, not remembered.** Derive it from the generated table
  metadata where drift 2.34.2 lets you — a column declared `integer().map(const InstantConverter())` is a
  `GeneratedColumnWithTypeConverter` — and back it with a test that reads
  `drift_schemas/drift_schema_v<kSchemaVersion>.json` and asserts every `INTEGER` column carrying that
  converter is in the set. **Verify the runtime check against the pinned drift before relying on it**; if
  it does not hold, the declared set plus the schema-JSON completeness test is the mechanism, and that is
  the same shape the `importDefaults` completeness test already has (09 §5.6).
- **No `id` and no raw integer foreign key is ever written.** `SELECT *` gives you both. Drop `id`, drop
  each row-pointing foreign key's own column, and add the `<column>_uid` alias in its place.
- **`unknown_json` is skipped in this task, and skipped deliberately.** It is a container, not a fact
  (09 §5.3). T03 splats its contents at the row's top level; here it is simply not in the emitted column
  list. Do not emit it "for now" — every one of T01's byte-equality cases would then pass while the
  format is wrong.
- **Every other column is emitted, `null` included.** An omitted key and an explicit `null` mean the same
  thing to the importer, but only one of them round-trips byte for byte (09 §7.2 rule 7). Do not "tidy"
  nulls out of the row.
- **Booleans are `0`/`1`, not `true`/`false`.** The column is `INTEGER` under `STRICT` and the file
  mirrors the column. Raw storage already gives you the integer; the trap is a `toJson` that helpfully
  converts it.
- **No floating-point numbers, anywhere.** Mass is integer grams, temperature integer milli-°C (#56), and
  statistics are derived rather than stored. One `double` and canonical encoding has its hardest problem
  back and the checksum starts flapping across platforms.
- **Nothing derived is written.** No statistic, no `lamb_rearing.rearing_dam`, no
  `lambing_consistency.is_mismatched`. Those are CSV and PDF columns; the backup carries the inputs. And
  `ewes.over_free_cap` **is** in the backup even though it is not in the CSV — it is a column on a row,
  and the backup is the record while the CSV is a report. That distinction settles every "does this
  column belong?" argument.
- **The formula-injection guard is nowhere near this code path.** It lives in `csv_writer.dart` and only
  there. Applying it here "for consistency" would put an apostrophe into the backup and break the round
  trip (09 §2.6).
- **No base64, ever.** Media bytes are not in a v1 backup (#85); `media.included` is `false` and the
  header carries the count and total size so the restore screen can be honest about what was left behind.
  Inline base64 turns 130 MB into ~175 MB inside one JSON string, built in memory —
  `copy.base64_backup` is a gate row precisely because it is the obvious next idea.
- **Topological order is an *import* concern, not an export one.** The `tables` object is sorted by code
  unit and the importer resolves parents before children from its own fixed order (04 §7.2 step 6).
  Do not reorder the emitted object to be "restore-friendly": that breaks the canonical rule and buys
  nothing.
- **`writeBackup` writes a file and returns its path.** It does not return bytes. `ExportArtifact` is
  `({String path, String shareName, int byteSize})`, the file goes to `getTemporaryDirectory()` (04 §4.2,
  never the media root), and `last_exported_at` is stamped **after** the share sheet returns and never
  inside this verb — otherwise the stamp is inside the file that describes it (09 §7.2 rule 13).

### 5.4 The full test set

`test/features/backup_format_test.dart` — the same file T01 created.

| Case | What it asserts |
|---|---|
| `'writeBackup emits all 21 restorable tables and names its four exclusions'` | **The anchor.** The set derived from `db.allTables` minus four literals, length 21, equal in both directions to the emitted keys |
| `'counts has one entry per table in tables, zeros included, on an empty database'` | 21 entries, all zero. The case that catches a `counts` built from rows |
| `'entitlements is absent even when unlocked is 1'` | A seeded entitlement row does not reach the file (#88) |
| `'ewe_summaries is absent even when it has been rebuilt'` | The cache is out; `rebuilt_at` would break equality (03 §5.13) |
| `'search_docs and search_fts are absent'` | Derived; exporting them double-indexes on restore |
| `'vocab_terms is present and carries a user-added term with origin user'` | The restore-breaking omission 09 §1.3 corrected, as a test |
| `'no id column and no raw integer foreign key appears anywhere in the body'` | Walk every row of every table |
| `'every row-pointing foreign key is emitted as <column>_uid carrying the parent uid'` | `ewe` → `ewe_uid`, `lambing` → `lambing_uid`, `birth_dam` → `birth_dam_uid` |
| `'a vocabulary foreign key keeps its own name and its own key value'` | `"route": "rt_subcutaneous"`, and `route_uid` appears nowhere |
| `'kBackupForeignKeys is complete against the committed schema JSON'` | Read `drift_schemas/drift_schema_v<kSchemaVersion>.json`; every foreign key onto a table with a `uid` is in the map |
| `'every table with a uid is ordered by uid'` | Source text over the query builder, plus a two-row ordering assertion per table |
| `'the five uid-less tables order by their natural keys'` | `ewe_touches` by `ewe_uid`; `pen_occupancy_lambs` by `occupancy_uid` then `lamb_uid`; `reminder_rules` by `kind`; `terminology_overrides` by `key`; `app_settings` has one row |
| `'table keys are in code-unit order, so treatment_withdrawals precedes treatments'` | The ordering trap, made explicit |
| `'every column is emitted, null included'` | A row with every nullable column null still has every key |
| `'booleans are 0 and 1, never true and false'` | `pet_lamb`, `over_free_cap`, `included` |
| `'no double appears anywhere in the encoded body'` | Decode and walk; fail on the first `double` |
| `'no base64 and no media bytes appear in the file'` | `media.included` is `false`; the body has no long opaque string |
| `'unknown_json is not emitted under its own name'` | Zero occurrences of the key. T03 adds the splat; this asserts the container never ships |
| `'the provenance quad travels as a unit'` | `occurred_at`, `captured_at`, `original_effective` and `time_source` are all present on a lambing row, or the test fails naming the missing one |
| `'created_at and updated_at are emitted exactly as stored'` | No re-stamping on the way out |
| `'writeBackup returns a path in the temporary directory, not bytes'` | `ExportArtifact.path`, `byteSize` matches the file length, nothing under the media root |

**The `uk-zone` group** — added to T01's group in the same file.

| Case | What it asserts |
|---|---|
| `'DST: a lambing at 01:30 BST and one at 01:30 GMT serialise to two different Z instants'` | The clocks-back night. Two distinct rows, one local wall time, two distinct `occurred_at` values in the file |
| `'DST: those two rows keep their order under ORDER BY uid across two exports'` | Ordering is by identity, not by time, so the ambiguous hour cannot permute the file |
| `'DST: local_date passes through as stored and is never re-derived from occurred_at'` | The civil date written at 03:20 is a fact; recomputing it at export would silently disagree in the repeated hour |

## 6. Constraints that bind this task

- **The five safety rules — §12.1 and §12.5 both land here.** §12.1: a treatment with no
  `treatment_withdrawals` row produces **no** withdrawal row in the file. The absence is the answer, and
  it is what the sealed type reads as `WithdrawalNotRecorded`; there is no `0`, no placeholder and no
  import default (09 §5.6). §12.5: `occurred_at`, `captured_at`, `original_effective` and `time_source`
  travel as a unit or not at all — a backup that drops the quad launders an edited timestamp into an
  auto-captured one, a §12.5 violation committed by the file format.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. This task adds no package: it is `customSelect` plus T01's encoder.
- **The single writer** — `ExportRepository` owns writes to **nothing** (`CONVENTIONS` §2.13). `writeBackup` reads and assembles; it opens no transaction, mutates no row, and stamps no column. `last_exported_at` is `SettingsRepository`'s, after the share sheet returns.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. **The backup** is this file; **the snapshot** is `VACUUM INTO` and the drift schema JSON, and the two words never swap.

## 7. Definition of Done

- [ ] `'writeBackup emits all 21 restorable tables and names its four exclusions'` passes, and was seen to fail first for the stated reason
- [ ] 21 tables, derived from the schema, never a typed list
- [ ] the four exclusions are named with reasons in the source
- [ ] no base64 anywhere in the file
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `counts` has one entry per key in `tables` — 21, zeros included, proved on an empty database
- [ ] no `id` and no raw integer foreign key is written; every row-pointing foreign key is `<column>_uid` carrying the parent's `uid`
- [ ] the five vocabulary foreign keys keep their own names and their own key values
- [ ] every table with a `uid` is ordered by `uid`; the five without order by the natural keys 09 §5.3 names, resolved to the parent's `uid`
- [ ] every column is emitted, `null` included; booleans are `0`/`1`; no `double` appears in the body
- [ ] `unknown_json` is not emitted under its own name
- [ ] the provenance quad is present or absent as a unit on every table that has it
- [ ] `writeBackup` opens no transaction and mutates no row, and `ExportRepository` still writes to nothing
- [ ] `kBackupForeignKeys` is proved complete against the committed `drift_schemas/drift_schema_v<kSchemaVersion>.json`
- [ ] the diff contains no file under `drift_schemas/` or `lib/core/db/`

## 8. Verification

```bash
fvm flutter test test/features/backup_format_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

```bash
grep -n "ORDER BY id\|orderBy.*\.id\b" lib/data/export_repository.dart   # expect zero
grep -n "base64\|customStatement(" lib/data/export_repository.dart       # expect zero
git diff --stat -- drift_schemas/ lib/core/db/                           # expect empty
```

Then read one file with `jq`, because 21 keys is a number a person should confirm once by hand:

```bash
jq -r '.tables | keys | length' backup.json     # expect 21
jq -r '.counts | keys | length' backup.json     # expect 21
jq -r '[.tables[][] | keys[]] | map(select(. == "id" or . == "unknown_json")) | length' backup.json   # expect 0
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(backup): writeBackup over every restorable table`

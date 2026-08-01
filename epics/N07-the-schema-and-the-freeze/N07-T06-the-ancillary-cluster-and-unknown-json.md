# N07-T06 — The ancillary cluster and `unknown_json`

| | |
|---|---|
| **Epic** | [N07 — The schema and the freeze](epic.md) · `00-README` §9 step 3 (1 of 2) |
| **Task** | 6 of 8 |
| **Depends on** | N07-T05 |
| **Commit** | one commit · `feat(db): the ancillary cluster and unknown_json on every restorable table` |

## 1. Why this task exists

`reminders`, `reminder_rules`, `notes`, `media_assets`, `vocab_terms`,
`terminology_overrides`, `app_settings`, `entitlements`, `ewe_summaries` — plus `unknown_json` on all
21 restorable tables, which is what lets a backup written by a **newer** build round-trip through an
older one without losing the columns it does not know about. `media_assets` stores a **relative** path
and a `CHECK` refuses anything else.

This task completes the 23. It is also the last chance to add a column, a CHECK or a table before the
snapshot: everything here that is missing on the morning of T08 becomes a migration on somebody else's
phone in April.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | §5.10 | `Reminders`, `ReminderRules`, the closed `kind` CHECK, and why there is **no** `os_notification_id` |
| `docs/engineering/03-data-model-and-schema.md` | §5.11 | `Notes` (with `occurred_at`), `MediaAssets` and its three path CHECKs |
| `docs/engineering/03-data-model-and-schema.md` | §5.12, §5.13 | `VocabTerms`, `TerminologyOverrides`, `AppSettings`, `Entitlements`, `EweTouches`, `EweSummaries` |
| `docs/engineering/04-migrations-media-backup-restore.md` | §6.4, §6.5 | what is in the backup and what is not, and `unknown_json`'s exact shape and job |
| `docs/engineering/04-migrations-media-backup-restore.md` | §4.2, §4.3 | the `YYYY/MM/<uuid>.<ext>` media layout the GLOB encodes, and why an absolute path is dead on iOS |
| `docs/engineering/CONVENTIONS.md` | R7, R20, R29, R35, R40, R62, R66, R68 | the two remaining `@DataClassName`s, the `AppSetting` row class, the palette keys, the two extra settings columns, the three path CHECKs |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | the remaining tables and the forward-compatibility column |
| `shed-export-and-restore` | `unknown_json` exists for the backup format and nothing else |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/schema_ancillary_test.dart`
- **Test** — `'media_assets refuses an absolute path and unknown_json exists on all 21 restorable tables'`
- **Assertion, spelled out** — inserting a `relative_path` that begins with a slash — an absolute iOS
  container path, which is what a `MediaStore` storing `resolve()`'s output would produce — throws
  `SqliteException`; inserting `'2026/03/019524f7-….jpg'` succeeds. Then, over `db.allTables`
  **minus** the two non-restorable tables named as literals with their reasons, assert every remaining
  table has an `unknown_json` column — and assert the count is **21**, derived from the enumeration,
  never typed as a bare number beside a hand-written list.
- **Why it is red today** — nine tables missing and no forward-compatibility column anywhere.

```bash
fvm flutter test test/data/schema_ancillary_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the tables, the `CHECK`, the `unknown_json` column on each restorable table — then
`build_runner` only.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/core/db/tables/reminders.dart` | **New.** `Reminders`, `ReminderRules`. |
| 2 | `lib/core/db/tables/notes.dart` | **New.** `Notes`, `MediaAssets`. |
| 3 | `lib/core/db/tables/vocab.dart` | **New.** `VocabTerms`, `TerminologyOverrides`. Declared **before** the FKs that point at it are completed. |
| 4 | `lib/core/db/tables/settings.dart` | **New.** `AppSettings` (`@DataClassName('AppSetting')`), `Entitlements`, `EweSummaries` (`@DataClassName('EweSummary')`). |
| 5 | `lib/core/db/tables/flock.dart` | Edit: complete `ewe_observations.kind` → `VocabTerms(#key)`, `ON DELETE RESTRICT`. |
| 6 | `lib/core/db/tables/lambing.dart` | Edit: complete `lambings.presentation`, `lambs.death_cause` and `foster_events.method` → `VocabTerms(#key)`, `ON DELETE RESTRICT`. |
| 7 | `lib/core/db/tables/treatments.dart` | Edit: complete `treatments.route` → `VocabTerms(#key)`, `ON DELETE RESTRICT`. |
| 8 | *every table file* | Add `unknown_json` to the 21 restorable tables — see 5.3 gotcha 1 for why it cannot ride on `Identified`. |
| 9 | `lib/core/db/database.dart` | Register the last nine tables. `@DriftDatabase(tables: [...])` now holds **23**. |
| 10 | `lib/data/models.dart` | Add the last nine row classes. The `export … show` list is now all 23 (R20). |
| 11 | `test/data/schema_ancillary_test.dart` | **New.** The anchor plus the cases in 5.4. |
| 12 | `test/data/database_test.dart` | Edit: add `'the registered table count equals 23'` — the assertion that stops T02's enumeration from ever being vacuous again. |
| 13 | `test/data/vocab_list_scope_test.dart` | **New.** Per column, every stored vocabulary key belongs to that column's own `list`. |

Then `dart run build_runner build --delete-conflicting-outputs`.

### 5.2 The signatures

```dart
class Reminders           extends Table with Identified { … }  // six indexes, incl. idx_reminder_due_open
class ReminderRules       extends Table { … }                  // primaryKey {kind}; NO Identified
class Notes               extends Table with Identified { … }  // idx_note_ewe/lamb/lambing/season
class MediaAssets         extends Table with Identified { … }  // idx_media_ewe/lamb/lambing/note;
                                                               // uniqueKeys [{relativePath}]
class VocabTerms          extends Table with Identified { … }  // idx_vocab_list; key is .unique()
class TerminologyOverrides extends Table { … }                 // primaryKey {key}; NO Identified
@DataClassName('AppSetting')
class AppSettings         extends Table { … }                  // primaryKey {id}; CHECK (id = 1)
class Entitlements        extends Table { … }                  // primaryKey {id}; CHECK (id = 1)
@DataClassName('EweSummary')
class EweSummaries        extends Table { … }                  // primaryKey {ewe}; idx_ewesummary_lastobs
```

`unknown_json`, identical on all 21 restorable tables:

```dart
late final unknownJson = text().nullable()();
// customConstraints: "CHECK (unknown_json IS NULL OR json_valid(unknown_json))"
```

The columns that carry a rule:

| Column | Declaration | Why it is exactly this |
|---|---|---|
| `notes.occurred_at` | quad event time, `NOT NULL` | **Distinct from the mixin's `created_at`** (R37). A note typed at 06:00 about 03:20 has two different instants and the timeline sorts on the first. Getting this wrong makes the timeline sort by typing order. |
| `media_assets.relative_path` | `text()()` + **three** CHECKs | `NOT LIKE '/%'` · `GLOB '[0-9][0-9][0-9][0-9]/[0-9][0-9]/*.*'` · `NOT GLOB '*/*/*/*'` (R62). All three before the snapshot: a `CHECK` cannot be added by `ALTER TABLE` afterwards without a full rebuild of the one table that points at the user's photographs. |
| `media_assets.missing_since` | `integer().map(const InstantConverter()).nullable()()` | Set when a sweep finds the file gone. **The row is never deleted** — *"photo taken 14 March, file missing"* is more honest than silence. |
| `vocab_terms.key` | `text().unique()()` | Globally unique, list-prefixed, ASCII, **frozen forever**. It is what goes in the database, the CSV and the JSON; it is never translated and never edited. Five foreign keys point at it, which is why it is unique on its own and not just within its list. |
| `vocab_terms.label` | `text().nullable()()` | `NULL` means *"use the shipped en-GB default for this key"*. A locale change or an app update therefore cannot overwrite a user's wording, and the data layer never imports `AppLocalizations`. |
| `vocab_terms.hidden_at` | nullable instant | Hidden, **never deleted** — a term in use is the target of an `ON DELETE RESTRICT` foreign key. |
| `app_settings.palette` | `CHECK (palette IN ('night','amber','red'))` | Byte-identical to `ShedPaletteId`'s keys (R35). **There is no `dark` key and no `light` value** — spec §5: dark is the default, not an option. |
| `app_settings.turn_out_threshold_hours` | `withDefault(const Constant(24))()` | A **display** threshold the user sets. It decides when the pen tile shows its badge and nothing else: not in any export, any CSV, any PDF, and no other column is derived from it. Convention 5 bans defaults that answer a *veterinary* question; *"how long before you nudge me"* is not one, and a blank threshold would mean no badge ever. |
| `app_settings.last_reconcile_scheduled`, `left_handed` | R40 | The honest reminder line has no data source without the first; the second mirrors the primary action column for a left-handed shepherd. Both must exist before the snapshot. |
| `entitlements.unlocked` | `boolean().withDefault(const Constant(false))()` | Written once, never revoked by the app. **Excluded from the backup and ignored on import** — restoring your neighbour's backup must not unlock your app (decision #88). Never in `shared_preferences`. |
| `ewe_summaries.*` | seven integer counts + one FK + `rebuilt_at` | **Counts only — never a percentage, never a formatted string.** The §7.7 sentence is assembled in Dart with the terminology overlay and the locale applied; a formatted string in the database would freeze both. `assisted_lambings` and `scored_lambings` are stored as a **pair** so the assisted rate can exclude unscored lambings from *both* sides and report coverage. |

### 5.3 The details that are easy to get wrong

1. **`unknown_json` cannot ride on `mixin Identified`, and this is the single largest trap in the
   task.** The mixin reaches 16 tables. Five of the 21 restorable tables do **not** carry it —
   `pen_occupancy_lambs`, `reminder_rules`, `terminology_overrides`, `app_settings`, `ewe_touches` —
   and every one of them is in the backup (04 §6.2). Declare the column explicitly per table, or
   introduce a second mixin and apply it to exactly 21. Putting it on `Identified` silently gives you
   16 and the count assertion is the only thing that will tell you.
2. **The arithmetic that makes 21 the right number:** 23 tables, minus `entitlements` (never exported,
   ignored on import — decision #88) and `ewe_summaries` (a cache, rebuilt wholesale after a restore).
   `search_docs` and `search_fts` are derived and are not in the 23 at all — they arrive in T07 from
   `search.drift` and they get **no** `unknown_json`. Note that 04 §6.2's illustrative `tables` block
   lists twenty entries and omits `vocab_terms`; `vocab_terms` is the twenty-first and it is restorable
   — it holds the user's own added terms and their labels.
3. **`json_valid()` needs the JSON1 extension.** It is compiled in by default from SQLite 3.38, so the
   bundled `sqlite3` 3.5.0 build and the ≥ 3.41.0 host floor both clear it — but if
   `test/data/host_sqlite_version_test.dart` was ever lowered, this CHECK is where it surfaces, as a
   `no such function: json_valid` at `createAll()`.
4. **`notes`' parent CHECK is `>= 1`, not `= 1`.** A note may hang off a ewe **and** a lambing at once.
   `care_events` and `treatments` use `= 1`, `reminders` uses `<= 1`. Three different sums in three
   neighbouring tables, each correct for its own reason — copy each from 03 §5.6, §5.8, §5.10 and §5.11
   rather than from the table above it.
5. **`reminders` has four nullable subject FKs and the CHECK is `<= 1`,** because a season-wide reminder
   has none of them. `season` is a fifth FK and is *not* in the sum.
6. **There is no `os_notification_id` column, and adding one is a defect** (decision #63). The OS
   projection is a rebuildable cache produced by `cancelAll()` + rebuild, not a durable fact. A stored
   OS id is a second source of truth that goes stale on every reconcile. The id handed to
   `flutter_local_notifications` is derived from `reminders.id` at projection time.
7. **`reminders.kind` is a closed CHECK, not a vocabulary FK,** because each value maps to an Android
   channel id frozen at release. Eight values, and adding a ninth is a migration *and* a channel
   decision.
8. **Closed vocabulary versus user-editable vocabulary is one discriminator and it decides every
   enum-shaped column in the schema.** *If the user may add a term, the schema cannot enumerate it.*
   `CHECK (x IN (…))` for closed; a foreign key to `vocab_terms(key)` for editable. A foreign key
   constrains the **key**, never the **list** — nothing in SQL stops `ewe_observations.kind` holding
   `'dc_starvation'`. That is enforced in exactly one place: the repository picks from
   `SELECT key FROM vocab_terms WHERE list = ? AND hidden_at IS NULL`, and
   `test/data/vocab_list_scope_test.dart` asserts per column that every stored key belongs to that
   column's list. **Do not add a trigger — it would fire on restore.**
9. **`lambing_ease` is the one list with no foreign key pointing at it.** `lambings.ease` is an ordinal
   `INTEGER 1..5` with a CHECK; the five `ease_*` rows exist only to carry the user-editable *labels*.
   Deliberate, not an oversight (R44).
10. **`app_settings` is the one table exempt from the hand-indexed-FK rule** — one row, so an index on
    `current_season` costs more than the scan it replaces. It is exempt **by name** in
    `every_fk_is_indexed_test.dart`. A second entry in that allowlist is a review conversation.
11. **There is deliberately no locale, date-format or first-day-of-week column.** UK/Ireland first is
    delivered by `flutter_localizations` and the `supportedLocales` ordering (decision #108); a stored
    copy goes stale the moment the user changes their phone's region.
12. **`EweTouche`, `EweSummarie`, `AppSetting`** — drift's default data-class name strips one trailing
    `s`. Two of the four `@DataClassName`s land in this task. Renaming a row class after the snapshot is
    a whole-codebase edit for zero behaviour change.
13. **The media path GLOB encodes the *local* civil month, not the UTC one.** `MediaStore.newRelativePath`
    (04 §4.2, built in N15) derives `YYYY/MM` from `appNow()`'s local date. The CHECK only enforces the
    shape — but write the test case that proves a photo captured just after local midnight at a month
    boundary lands in the new month, because the failure mode is a directory that quietly disagrees with
    the shepherd's calendar.
14. **Nothing in this task is a time-relative value.** No `days_until_clear`, no `hours_penned`, no
    `is_overdue` (01 §7.2). If a column would be wrong within a minute of being written, it does not
    exist.

### 5.4 The test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/data/schema_ancillary_test.dart` | `'media_assets refuses an absolute path and unknown_json exists on all 21 restorable tables'` | The anchor, both halves, with the count derived from the enumeration. |
| | `'media_assets refuses 2026/03/x, 03/2026/x.jpg and 2026/03/a/b.jpg'` | The three CHECKs, one near-miss each: no extension, wrong order, too deep. |
| | `'media_assets accepts 2026/03/019524f7-8a1c-7b3e-9f04-2c9a1e7d55b0.m4a'` | The real shape, with a real v7 uid and the voice extension. |
| | `'two media_assets rows cannot share a relative_path'` | `uniqueKeys [{relativePath}]`. |
| | `'a media_asset with missing_since set is still selectable and still linked'` | The row is never deleted. |
| | `'notes.occurred_at and created_at are independently settable and differ'` | The whole point of R37's addition to this table. |
| | `'notes rejects a row with no ewe, lamb, lambing or season, and accepts one with two of them'` | `>= 1`, both directions. |
| | `'notes rejects an empty body and a whitespace-only body'` | `length(trim(body)) > 0`. |
| | `'reminders accepts a season-only row and rejects one with both a ewe and a lamb'` | `<= 1`, both directions. |
| | `'reminders rejects kind = turnout'` | The closed CHECK, with the exact near-miss `CONVENTIONS` §5.1 warns about — the stored key is `turn_out`. |
| | `'vocab_terms rejects origin = user with a NULL label, and accepts origin = seeded with one'` | A user-added term has no shipped default, so it must carry a label. |
| | `'vocab_terms rejects a duplicate key across two different lists'` | `key` is unique globally, not per list. |
| | `'app_settings rejects palette = dark and accepts night, amber and red'` | R35 — the value that used to be called `dark` is `night`, and the enum and the column must spell it the same way. |
| | `'app_settings rejects a second row'` | `CHECK (id = 1)`. |
| | `'entitlements rejects a second row and defaults unlocked to 0'` | The safe default. |
| | `'unknown_json rejects the string not-json and accepts {"a":1} and NULL'` | `json_valid`, all three states. |
| | `'ewe_summaries stores counts and has no percentage or text column'` | Enumerate the column types; assert no `REAL` and no free-text summary column exists. |
| | `'deleting a season sets ewe_summaries.last_observation_season to NULL rather than orphaning it'` | `ON DELETE SET NULL` — *"prolapsed 2025"* renders a blank year instead of a dangling id. |
| `test/data/database_test.dart` | `'the registered table count equals 23'` | Ends T02's vacuity for good. |
| `test/data/vocab_list_scope_test.dart` | `'every stored vocabulary key belongs to its own column list'` | One case per column: `lambings.presentation` → `malpresentation`, `lambs.death_cause` → `death_cause`, `ewe_observations.kind` → `ewe_observation`, `treatments.route` → `treatment_route`, `foster_events.method` → `foster_method`. |
| | `'a key from the wrong list is storable and the test is what catches it'` | Proves the assertion is measuring something the FK cannot. |
| `test/domain/uk_zone/schema_ancillary_dst_test.dart` | `'a note occurring at 01:30 on 25 October 2026 and captured at 06:00 keeps both instants and time_source auto'` | `@Tags(['uk-zone'])`, `TZ=Europe/London`. The ambiguous hour, and the `occurred_at` / `captured_at` gap the timeline sorts on. |
| | `'a relative_path derived from 00:30 BST on 1 April 2026 is 2026/04/…, not 2026/03/…'` | The instant is 23:30 UTC on 31 March. The shard follows the shepherd's civil month. |

### 5.5 Verification that the 23 are complete and correctly named

```bash
grep -c "@DataClassName" lib/core/db/tables/*.dart   # expect four in total
```

`PenOccupancy`, `EweTouch`, `EweSummary`, `AppSetting` — and the app compiles without a single
`…ie`/`…che` row class.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan)
  stay green, and the permission set never changes without G0's recorded evidence.
- **Never present as a regulatory record** — nothing in `app_settings` or `entitlements` is a
  compliance flag, and there is no "signed", "approved" or "official" column anywhere.
- **The backup is the only recovery path this product has** — `unknown_json` is what makes an
  import → export round trip lossless. It is **not** a mechanism for importing from the future: a
  backup with a higher `schema` or `formatVersion` is **refused**, in words a shepherd can act on.
- **Irreversibility** — R62's three CHECKs and R40's two columns are both *"before the first snapshot"*
  rulings. This is the last task that can add either.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'media_assets refuses an absolute path and unknown_json exists on all 21 restorable tables'` passes, and was seen to fail first for the stated reason
- [ ] `occurred_at` is distinct from `created_at` on `notes`
- [ ] `media_assets.relative_path` has a `CHECK` refusing a leading slash or a drive letter
- [ ] `missing_since` exists so a swept-away file is a fact, not a crash
- [ ] `unknown_json` is on exactly the 21 restorable tables and the test counts them
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
# 1. Red first.
fvm flutter test test/data/schema_ancillary_test.dart

# 2. build_runner ONLY.
dart run build_runner build --delete-conflicting-outputs

# 3. The 23 are registered, the vocabulary FKs are scoped, and nothing regressed.
fvm flutter test test/data/
TZ=Europe/London fvm flutter test --tags uk-zone

# 4. Every FK in all 23 tables is indexed, with one allowlisted table.
fvm flutter test test/data/every_fk_is_indexed_test.dart

# 5. Nothing under drift_schemas/ has moved — the freeze is T08's.
git status --short drift_schemas/ test/drift/

# 6. Both gates.
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(db): the ancillary cluster and unknown_json on every restorable table`

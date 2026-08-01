# N07-T03 — The flock cluster

| | |
|---|---|
| **Epic** | [N07 — The schema and the freeze](epic.md) · `00-README` §9 step 3 (1 of 2) |
| **Task** | 3 of 8 |
| **Depends on** | N07-T02 |
| **Commit** | one commit · `feat(db): the flock cluster and the active-only tag index` |

## 1. Why this task exists

`seasons`, `ewes`, `ewe_seasons`, `ewe_touches`, `ewe_observations` — with the
**active-only partial unique index** on `tag`, which is the owner's ruling made structural: a tag is
unique among ACTIVE animals only, so 412 can be culled and a new 412 can arrive next season without
the database refusing her.

`seasons` is the scoping spine every later cluster hangs off: `ewe_seasons`, `lambings`,
`pen_occupancies`, `treatments`, `reminders`, `care_events`, `ewe_observations` and `foster_events` all
carry a `season` foreign key. **A season is not a foreign key on `Ewe`** — a ewe is a physical animal
that persists across seasons, and that is the retention feature.

`ewe_seasons` exists because **barren rate is not computable from lambings**: a barren ewe has no
lambing row. Without an explicit participation record the number cannot be produced at all.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | §5.1–§5.3, §5.7 | `Seasons`, `Ewes`, `EweSeasons`, `EweObservations` — every column, CHECK and index, verbatim |
| `docs/engineering/03-data-model-and-schema.md` | §5.13 | `EweTouches` — the recents cache, its `@DataClassName` and why it is not a history table |
| `docs/engineering/03-data-model-and-schema.md` | §6 | tag uniqueness, all five consequences, and the two tests that pin it |
| `docs/engineering/03-data-model-and-schema.md` | §2, §4.2 | the nine table conventions, the two date/instant guards, and the seven quad-carrying tables |
| `docs/engineering/CONVENTIONS.md` | §4.6, R7, R37, R38, R41, R42, R45 | column and index naming, `@DataClassName('EweTouch')`, the quad, and barren as a participation outcome |
| `docs/research/00-tech-decisions.md` | §7.0 ruling 7 | tags are unique among **ACTIVE** animals only |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | tables, indexes and the partial-index idiom |
| `shed-conventions` | every column name and every index name is settled in §2 and §4 |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/schema_flock_test.dart`
- **Test** — `'the partial unique index refuses a second ACTIVE ewe with tag 412 and permits a culled one'`
- **Assertion, spelled out** — insert ewe `412`; a second insert of `412` with `status = 'active'`
  throws `SqliteException`; set the first to `status = 'culled'`; the same second insert now succeeds;
  both rows exist with distinct `uid`s. Both halves in one test — either alone passes the wrong schema.
- **Why it is red today** — no tables exist yet, so there is no `ewes` table, no index, and nothing that could refuse a second active 412.

```bash
fvm flutter test test/data/schema_flock_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — five tables, `STRICT`, real foreign keys with explicit `ON DELETE`, a hand-written index
per foreign key, the provenance quad where the row can be edited — then `build_runner` only.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/core/db/tables/seasons.dart` | **New.** `Seasons` — the one path 03 §5.1 spells verbatim. Seven `customConstraints`, one `@TableIndex`. |
| 2 | `lib/core/db/tables/flock.dart` | **New.** `Ewes`, `EweSeasons`, `EweTouches`, `EweObservations`. Cluster file names are free (`tables/<cluster>.dart`, CONVENTIONS §4.1); table and column names are not. |
| 3 | `lib/core/db/database.dart` | Register the five tables in `@DriftDatabase(tables: [...])`. The list grows here for the first time. |
| 4 | `lib/data/models.dart` | Add `Season`, `Ewe`, `EweSeason`, `EweTouch`, `EweObservation` to the `export … show` list (R20). |
| 5 | `test/data/schema_flock_test.dart` | **New.** The anchor test. |
| 6 | `test/data/tag_uniqueness_test.dart` | **New**, database-level halves only — see gotcha 6. |
| 7 | `test/data/every_fk_is_indexed_test.dart` | **New.** Enumerates `PRAGMA foreign_key_list` per table and asserts an index whose **leading** column is the child key. It grows silently as T04–T06 land tables, which is why it belongs here rather than at the end. |
| 8 | `test/domain/uk_zone/schema_flock_dst_test.dart` | **New.** The two time-shaped cases in 5.4. |

Then `dart run build_runner build --delete-conflicting-outputs` — **not** `make gen`.

### 5.2 The signatures

Table classes, indexes and the columns that carry a rule. Everything else is 03 §5.1–§5.3 and §5.7
verbatim; do not paraphrase a `CHECK`.

```dart
class Seasons          extends Table with Identified { … }   // idx_season_start
class Ewes             extends Table with Identified { … }   // idx_ewe_status, idx_ewe_tagdigits,
                                                             // idx_ewe_tag_active (partial, .sql)
class EweSeasons       extends Table with Identified { … }   // idx_eweseason_season, idx_eweseason_ewe
@DataClassName('EweTouch')
class EweTouches       extends Table { … }                   // primaryKey {ewe}; NO Identified (a cache)
class EweObservations  extends Table with Identified { … }   // idx_eweobs_ewe_time, idx_eweobs_season_kind,
                                                             // idx_eweobs_kind, idx_eweobs_lambing
```

The partial unique index cannot be written with `@TableIndex`; it is raw SQL:

```dart
@TableIndex.sql(
  "CREATE UNIQUE INDEX idx_ewe_tag_active ON ewes (tag) WHERE status = 'active'",
)
```

The columns that carry a rule, and the rule:

| Column | Declaration | Why it is exactly this |
|---|---|---|
| `seasons.ewes_to_ram` | `integer().nullable()()` | **No default.** A blank is *"I did not record it"*, not zero and not "same as lambed". It is the lambing-percentage denominator (decision #59). |
| `seasons.over_free_cap` | `boolean().withDefault(const Constant(false))()` | Decision #91 — the free tier is **season**-primary. Rows over the cap are real rows, flagged, never hidden or read-only. |
| `ewes.tag` | `text().withLength(min: 1, max: 32)()` | Exactly as typed. **Never normalised on write** (spec §12.4). |
| `ewes.tag_digits` | `text().withLength(min: 0, max: 32)()` | A digits-only **projection** written in the same statement, not a correction — the typed value survives beside it (decision #55). `min: 0`, because a tag can be all letters. |
| `ewes.date_of_birth` | `text().map(const PartialDateConverter()).nullable()()` | Partial precision is a real state. Three GLOBs — `YYYY`, `YYYY-MM`, `YYYY-MM-DD`. Never padded to 1 January. |
| `ewes.status` | `text().withDefault(const Constant('active'))()` | `CHECK (status IN ('active','sold','dead','culled'))`. A default here is fine: it encodes nothing veterinary. |
| `ewe_seasons.status` | `text()()` — **no default** | Defaulting to `'to_ram'` would silently assert a ewe was put to the ram, which is the denominator of a commercially sensitive number. Seven stored keys. |
| `ewe_observations.kind` | FK to `vocab_terms(key)`, `ON DELETE RESTRICT` | Convention 6: a **user-editable** vocabulary is a foreign key, never a `CHECK`. See gotcha 4 for when the FK is actually added. |
| `ewe_observations` quad | `occurred_at`, `captured_at`, `original_effective`, `time_source` | R37. *"She prolapsed about midnight"* is entered at 06:00. Both paired CHECKs, and the quad **must land before the snapshot**. |

The two schema-level guards, on every column of their kind:

```
CHECK (start_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')
CHECK (occurred_at BETWEEN 946684800000 AND 4102444800000)   -- 2000-01-01 .. 2100-01-01 UTC
```

### 5.3 The details that are easy to get wrong

1. **Uniqueness is on `tag` as typed, never on `tag_digits`.** Making `tag_digits` unique would refuse
   `0412` because `412` exists — the app deciding two tags are the same animal. `tag_digits` ranks
   matches; it never decides identity.
2. **`customConstraints` uses SQL column names**, not Dart names — drift converts `birthDam` to
   `birth_dam`. Write them as literal strings and **do not factor them into a helper function**:
   drift_dev reads them from source, and whether it can constant-fold an expression there is
   unverified and not worth discovering mid-schema.
3. **`ON DELETE` is chosen, never defaulted.** `KeyAction.noAction` by laziness is the defect.
   `cascade` means *"this row has no meaning without its parent"*; `restrict` means *"the parent is
   referenced by a record someone may show a vet."* Both directions on `ewe_seasons` are `cascade`,
   and each has its own reason.
4. **Two forward references in this cluster do not compile yet, and that is expected.**
   `ewe_observations` points at tables later tasks create. Declare the columns now, add the
   `.references(...)` when the parent exists — nothing is frozen until T08, so editing a T03 table in
   T06 is free:

   | Column | Parent table | `.references(...)` lands in |
   |---|---|---|
   | `ewe_observations.lambing` | `Lambings` (`ON DELETE SET NULL`) | T04 |
   | `ewe_observations.kind` | `VocabTerms(#key)` (`ON DELETE RESTRICT`) | T06 |

   The indexes (`idx_eweobs_lambing`, `idx_eweobs_kind`) go in now — an index needs no parent table.
5. **A composite `PRIMARY KEY` or `uniqueKeys` entry indexes its *leading* column only.**
   `{season, ewe}` on `ewe_seasons` indexes `season` and does nothing for `ewe`, which is why
   `idx_eweseason_ewe` exists as well. `every_fk_is_indexed_test.dart` asserts the leading column
   specifically, and it carries exactly one allowlisted table — `app_settings`, one row. **A second
   entry in that allowlist is a review conversation, not an edit.**
6. **The 03 §6 tag-uniqueness test as printed calls `FlockRepository`, which does not exist until
   N14.** Land the database-level halves here — `db.into(db.ewes).insert(EwesCompanion.insert(...))`
   with `newUid()` and `appNow()` — and let N14 add the repository halves. The database-level
   assertion is the load-bearing one anyway: *"the repository maps `SqliteException` to `WriteFailed`
   through `shedFailureFrom`, so a repository-level assertion would also pass on a schema with no
   index."*
7. **`await expectLater(...)`, never a bare `expect()` on a `Future`.** An unawaited `throwsA` leaks
   the failure into the next test as an unhandled async error, and the test that actually broke is not
   the one that reports red.
8. **A tag collision across tables is deliberately not enforced.** A lamb tagged `412` and an active
   ewe tagged `412` coexist: different tables, and v1 has no lamb→ewe promotion. Do **not** add a
   cross-table trigger. That is tied to `00-README` §5.2 item 13 (`lambs.became_ewe`), which N00-T04
   ruled — read the ruling before you touch it.
9. **`ewes.status` stays a mutable column. There is no `ewe_status_events` table** (R41). A history row
   per status change was proposed and struck; `updated_at` moves and that is the record. If the
   retention story turns out to need *"culled in March, un-culled in April"*, that is a schema
   addition and it must land **before T08** and be escalated to the owner, not decided here.
10. **Barren is `ewe_seasons.status = 'barren'`, never an observation** (R42). The `ewe_observation`
    vocabulary has no barren key — it is `obs_prolapse`, `obs_mastitis`, `obs_poor_mothering`,
    `obs_good_mothering`, `obs_no_milk`, `obs_other`.
11. **`ewe_touches` is a cache and carries no `Identified`, no quad and no history.** One row per ewe,
    upserted. *"She was looked at twice"* is not a fact the product keeps. Its `@DataClassName('EweTouch')`
    is not optional: drift's default strips one `s` and produces `EweTouche`, which would then appear in
    `lib/data/models.dart`, in every repository signature and in every test.
12. **Never narrow either guard.** `year BETWEEN 2000 AND 2100` and the instant band exist to catch a
    seconds-vs-millis unit slip — the one time bug that produces a plausible-looking row (a 2026
    lambing filed in 1970). They are deliberately far wider than any real record.
13. **`end_date >= start_date` is a plain string comparison and is correct** *because* the format is
    fixed and GLOB-checked. That is the entire payoff of the `TEXT` civil-date convention — and it is
    also why no `CHECK` in this schema may call a SQL date function (decision #47).

### 5.4 The test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/data/schema_flock_test.dart` | `'the partial unique index refuses a second ACTIVE ewe with tag 412 and permits a culled one'` | The anchor, both directions. |
| | `'every flock table is STRICT and refuses a text value in an integer column'` | Insert `'twin'` into `ewe_seasons.scanned_count`; expect `SqliteException`. Without `STRICT`, SQLite stores it. |
| | `'ewe_seasons refuses a status outside the seven stored keys'` | The `CHECK`, not a Dart enum. |
| | `'ewe_seasons has no default status — an insert omitting it fails'` | Convention 5 in a column definition. |
| | `'seasons.ewes_to_ram accepts NULL and rejects -1'` | *Not recorded* is a state; a negative denominator is not. |
| | `'ewes.date_of_birth accepts 2024, 2024-03 and 2024-03-11 and rejects 2024-3'` | All three GLOBs, plus the near-miss that a lenient parser would swallow. |
| | `'a ewe with the same tag in two DIFFERENT statuses coexists'` | `culled` + `active`, then `sold` + `active`. The index is `WHERE status = 'active'`, so only the active pair collides. |
| | `'deleting a season cascades ewe_seasons and leaves the ewes'` | The asymmetry both `ON DELETE CASCADE`s exist for. |
| | `'ewe_observations rejects time_source = edited with original_effective NULL, and the reverse'` | The paired CHECK, in both directions. One direction alone passes a broken schema. |
| | `'an instant of 1771286400 (seconds) is rejected by the sanity band'` | The unit-slip guard, with a number that looks plausible. |
| `test/data/tag_uniqueness_test.dart` | `'two ACTIVE ewes cannot share a tag'` | Asserted against the **database**, per 03 §6. |
| | `'a culled ewe releases her tag, and the new ewe is a new animal'` | Distinct `uid`s; the earlier animal is still findable. |
| `test/data/every_fk_is_indexed_test.dart` | `'every foreign key has an index whose leading column is the child key'` | Enumerates `PRAGMA foreign_key_list`; allowlist = `['app_settings']` with its reason inline. |
| `test/domain/uk_zone/schema_flock_dst_test.dart` | `'an ewe_observation stored at 01:30 on 25 October 2026 reads back at 01:30 with its quad intact'` | `@Tags(['uk-zone'])`, `TZ=Europe/London`. The ambiguous hour happens twice; the column stores whichever instant Dart resolved, and `time_source` must still be `'auto'` — nothing was corrected. |
| | `'a season starting 2026-03-29 stores start_date as 2026-03-29 and passes the GLOB'` | Spring-forward day. A civil date must not acquire an hour, a zone, or a shift to the 28th. |

### 5.5 Verification that the names are right

After `build_runner`, grep `database.g.dart` for `EweTouche` and `Seasone` — neither may appear. Then
read the generated `CREATE TABLE` strings and confirm every one ends in `STRICT`; T08 asserts the same
thing off the schema JSON, but finding it here costs one regeneration instead of a re-freeze.

## 6. Constraints that bind this task

- **The five safety rules** — §12.4 at the storage layer (`STRICT`, so the database refuses garbage
  instead of storing it and pretending) and §12.5 (`ewe_observations` carries the full provenance quad;
  **a table without the quad has no edit verb**).
- **Never silently correct an entry** — `tag` is stored exactly as typed; `tag_digits` is a projection
  written beside it, never over it.
- **Irreversibility** — the quad on `ewe_observations` and every `NOT NULL` in this cluster are frozen
  by T08. Adding a `NOT NULL` column afterwards is a full table rebuild.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the partial unique index refuses a second ACTIVE ewe with tag 412 and permits a culled one'` passes, and was seen to fail first for the stated reason
- [ ] `STRICT` on every table
- [ ] an index for every foreign key
- [ ] the partial unique index is `WHERE status = 'active'` and is proved in both directions
- [ ] the provenance quad is present on every table that will gain an edit verb
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
# 1. Red first.
fvm flutter test test/data/schema_flock_test.dart

# 2. build_runner ONLY — the snapshot is T08's.
dart run build_runner build --delete-conflicting-outputs

# 3. The three data tests, then the London-zone pair.
fvm flutter test test/data/schema_flock_test.dart test/data/tag_uniqueness_test.dart \
                 test/data/every_fk_is_indexed_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone

# 4. Nothing generated for the migration harness may have moved.
git status --short drift_schemas/ test/drift/

# 5. Both gates.
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(db): the flock cluster and the active-only tag index`

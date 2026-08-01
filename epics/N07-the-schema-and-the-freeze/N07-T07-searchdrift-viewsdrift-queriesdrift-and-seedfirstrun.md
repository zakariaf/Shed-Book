# N07-T07 — `search.drift`, `views.drift`, `queries.drift` and `seedFirstRun`

| | |
|---|---|
| **Epic** | [N07 — The schema and the freeze](epic.md) · `00-README` §9 step 3 (1 of 2) |
| **Task** | 7 of 8 |
| **Depends on** | N07-T06 |
| **Commit** | one commit · `feat(db): search, views, queries and the first-run seed` |

## 1. Why this task exists

FTS5 present in **v1** with zero real rows — so the shadow-table question is answered in
week one rather than at v4 with a shepherd's data in the file — plus the views, the named queries, and
`seedFirstRun` in `onCreate`, which seeds the current season and the ~40 authored terms from
`assets/content/`. A first run that has to ask *"which season is this?"* has already failed the 3am
test.

Every event table has `season NOT NULL`. Without the seed, the very first keypad tap cannot insert a
lambing — and spec §5 forbids onboarding after first run while §7.1 forbids blocking an entry to make
someone set something up first.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | §9.2 | `search_docs`, `search_fts`, the three external-content triggers, the five source-table trigger trios, `searchAll`, and **both spelling traps** |
| `docs/engineering/03-data-model-and-schema.md` | §9.1 | why the keypad path uses none of this — in-memory ranking, and what is banned there |
| `docs/engineering/03-data-model-and-schema.md` | §6, §8 | `earlierAnimalsWithTag`, `penBoard`, `inThePens` |
| `docs/engineering/03-data-model-and-schema.md` | §10, §10.1 | `seedFirstRun` in full, the isolate gotcha, and the six lists / forty keys |
| `docs/engineering/CONVENTIONS.md` | R22, R23, R66, §4.6 | the three `.drift` files and what each holds, `appNow()`, the three homes of the ~40 terms, query naming |
| `docs/engineering/12-testing.md` | §2.1, §3.1 | why a seed test must use an in-process `NativeDatabase.memory()` |
| `epics/00-PLAN-CRITIQUE.md` | §8 `[audit]` row on R66 | the ARB half and its set-equality test land **in this commit** |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | the `.drift` files and `onCreate` are its subject |
| `shed-conventions` | no `customStatement(` may live outside `lib/core/db/` |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/seed_first_run_test.dart`
- **Test** — `'onCreate seeds a season, the ~40 vocab terms, and FTS5 with zero real rows'`
- **Assertion, spelled out** — on an empty in-process `NativeDatabase.memory()`: exactly **one**
  `seasons` row whose `label` is `'<year> lambing'` and whose `start_date` is today's local civil date;
  exactly one `app_settings` row with `current_season` pointing at it; exactly one `entitlements` row
  with `unlocked = 0`; **40** `vocab_terms` rows, all `origin = 'seeded'` and all `label IS NULL`; the
  reminder rules present and enabled; **zero** `pens`; and `SELECT count(*) FROM search_fts` returns
  `0` while `INSERT INTO search_fts(search_fts) VALUES('integrity-check')` does not throw.
- **Why it is red today** — there is no search table, no view and no seed; a fresh install opens to an app that cannot record anything without setup.

```bash
fvm flutter test test/data/seed_first_run_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the three `.drift` files and the seed — then `build_runner` only.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/core/db/search.drift` | **New.** `CREATE TABLE search_docs … STRICT`, `CREATE VIRTUAL TABLE search_fts USING fts5(…)`, the three external-content triggers sqlite.org specifies, the **five** source-table trigger trios, and the `searchAll` named query. |
| 2 | `lib/core/db/queries.drift` | **New.** `penBoard`, `inThePens`, `earlierAnimalsWithTag`, `sweepSearchDocs`, `rebuildSearchIndex`. |
| 3 | `lib/core/db/views.drift` | Already holds T04's trigger and two views (R22). Add nothing unless a non-search table trigger was deferred; confirm the file is still the only home for `CREATE VIEW`. |
| 4 | `lib/core/db/database.dart` | `include: {'search.drift', 'views.drift', 'queries.drift'}` — the set is complete for the first time. Add `if (seedOnCreate) await seedFirstRun(this);` to `onCreate`, after `m.createAll()`. |
| 5 | `lib/core/db/seed/first_run.dart` | **New.** `Future<void> seedFirstRun(AppDatabase db)`, plus the private `_seedVocabulary` and `_seedReminderRules`. |
| 6 | `lib/l10n/app_en.arb` | Add one message per seeded vocabulary key, each with a `description`. R66's second home; `00-PLAN-CRITIQUE` §8 puts it in this commit because nothing else creates it. |
| 7 | `assets/content/` | One **provenance line per vocabulary list**, plus any lambing-ease description too long to be a label. Not the forty labels — those are ARB (R66). |
| 8 | `test/data/seed_first_run_test.dart` | **New.** The anchor plus the seed cases in 5.4. |
| 9 | `test/data/search_test.dart` | **New.** The trigger, `COALESCE` and alias cases — the ones that pass codegen and fail at runtime. |
| 10 | `test/policy/vocab_labels_are_complete_test.dart` | **New.** Set equality between the seeded keys and the ARB messages. Named for the **property**, per `CONVENTIONS` §4.1. |

Then `dart run build_runner build --delete-conflicting-outputs`.

### 5.2 The signatures

```dart
// lib/core/db/seed/first_run.dart
/// Runs inside the migration's onCreate, in the same transaction as
/// createAll(). Not in UI code. Not in a provider. Not on first paint.
Future<void> seedFirstRun(AppDatabase db);
Future<void> _seedVocabulary(AppDatabase db, Instant now);   // keys only — labels NULL
Future<void> _seedReminderRules(AppDatabase db);             // the §7.6 intervals, all enabled
```

The named queries, `lowerCamel` per `CONVENTIONS` §4.6:

| Query | File | What it is |
|---|---|---|
| `penBoard` | `queries.drift` | The whole Pen Board. One statement, one `watch()` stream, one screen. `LEFT JOIN` so an empty pen still renders. |
| `inThePens` | `queries.drift` | The same projection, `ORDER BY entered_at ASC`, ewes only. The ewe penned longest is the one most likely to need turning out. |
| `earlierAnimalsWithTag` | `queries.drift` | *"An earlier animal also used tag 412."* A **link**, never a merge offer. |
| `sweepSearchDocs` | `queries.drift` | The orphan delete, run inside the season-delete transaction, after the delete. |
| `rebuildSearchIndex` | `queries.drift` | `INSERT INTO search_fts(search_fts) VALUES('rebuild');` |
| `searchAll` | `search.drift` | One `MATCH`, one `bm25()` ordering, one `snippet()`. |

The FTS5 declaration, exactly:

```sql
CREATE VIRTUAL TABLE search_fts USING fts5(
  title, body,
  content='search_docs', content_rowid='id',
  tokenize='porter unicode61 remove_diacritics 2',
  prefix='2 3'
);
```

The five `subject_kind` rows, and what each writes:

| `subject_kind` | `title` | `body` |
|---|---|---|
| `ewe` | the tag | `ewes.notes` |
| `lambing` | tag + local date | `note` + `presentation_note` + `assisted_by` |
| `lamb` | the tag or `''` | `lambs.notes` |
| `treatment` | `product_name` | `dose_text` + `batch_no` + `note` |
| `note` | `'note'` | `notes.body` |

The six lists and forty keys (03 §10.1) — `lambing_ease` 5 (`ease_1`…`ease_5`), `death_cause` 8,
`malpresentation` 8, `treatment_route` 8, `ewe_observation` 6, `foster_method` 5.

### 5.3 The details that are easy to get wrong

1. **The `COALESCE` trap, and it fails at 03:20 on the create-on-the-fly path.** `search_docs.title`
   and `search_docs.body` are `NOT NULL`, and **every source column feeding them is nullable**. Every
   value a trigger writes is `COALESCE(…, '')`, and a multi-column body is
   `COALESCE(a,'') || ' ' || COALESCE(b,'')`. Miss it once and creating a ewe with no notes aborts the
   insert with a `NOT NULL` failure, from a trigger nobody was looking at, on the one path the product
   exists for. 03 §11 makes it a definition-of-done line: *creating a ewe, a lamb and a lambing with
   every optional text field left blank succeeds.*
2. **Two spelling traps in `searchAll`'s eight lines, and both pass codegen and fail at runtime.**
   (a) Once the virtual table is aliased, **only the alias is in scope** — `WHERE search_fts MATCH …`,
   `snippet(search_fts, …)` and `bm25(search_fts, …)` alongside `FROM search_fts f` all fail with
   *no such column: search_fts*. Use `f` in all three places, or drop the alias and use the table name
   in all three. **Never mix.** (b) `rank` is FTS5's own auto-generated column, so `… AS rank` shadows
   it; the result column is `rank_score` for that reason alone. This query needs **one real execution**
   in a test, not just a compile.
3. **`bm25()` returns a negative score where smaller is better**, so ascending `ORDER BY rank_score` is
   correct and looks wrong. Weighting `title` at 2.0 puts a ewe's own records above a passing mention
   in someone else's note.
4. **The note triggers use `new.occurred_at`, not `new.created_at`.** The timeline sorts on when the
   thing happened, not on when the row was written (R37).
5. **drift#3322 is open and it may block this task.** drift's SQL analyser does not fully model FTS5's
   special INSERT commands (`INSERT INTO t(t) VALUES('delete')`, `VALUES('rebuild')`). If it refuses to
   generate for `search_docs_ad` / `search_docs_au` or for `rebuildSearchIndex`, there are exactly two
   ways out and you take one of them, not a third:
   - **Fallback A — keep external content, hide the statements from the analyser.** Move the two
     triggers and the rebuild into a `customStatement` in `onCreate` and in `SeasonRepository`. Keeps
     the index storage-free; costs the type-safe query API and puts raw SQL in `lib/core/db/`, which
     layer rule 8 permits **only** there.
   - **Fallback B — drop external content.** Remove `content='search_docs'` and let `search_fts` store
     its own copy, so `DELETE FROM search_fts WHERE rowid = old.id` is ordinary SQL with no special
     commands at all. The corpus is a few hundred KB.

   **Take B if A costs more than half a day**, and **record which one shipped, in this commit, in
   03 §9.2 and in doc 04.**
6. **`recursive_triggers` is per-connection, and the season-delete path does not rely on it.** Rows
   removed by an `ON DELETE CASCADE` do not reliably fire the child table's `AFTER DELETE` trigger
   without it. In the same transaction as the delete, **after** it, run `sweepSearchDocs` then
   `rebuildSearchIndex`, so the index is correct whichever way the pragma question resolves. 03 §9.2
   asks for a five-minute test — insert a note, delete its season, assert `search_docs` is empty and
   `integrity-check` does not throw, once with the pragma on and once with it off — and asks you to
   **record which behaviour the bundled SQLite actually has.**
7. **`search_docs` and `search_fts` get no `unknown_json` and are not in the backup.** They are derived:
   `search_docs` refills itself from the source-table triggers as rows are inserted during a restore,
   and `search_fts` is rebuilt in one statement afterwards. Exporting them would double-index on
   restore. They are also not in `@DriftDatabase(tables:)` — they arrive through `include:`.
8. **Nothing in this task touches the keypad path.** Partial tag matching is not a search problem:
   typing `12` to surface 412, 128 and 12 is an **infix** match on a two-character query, which is
   FTS5's documented counter-example. `rankTagMatches` (N06-T07) is in-memory, synchronous and pure so
   every keypad tap re-filters inside the same frame. **Banned on that path: FTS5, the trigram
   tokenizer, `LIKE`, and any debounce.** The 200 ms debounce belongs to note search and nowhere else.
9. **FTS5 has no fuzzy matching and `spellfix1` is not in the bundled build.** `watry` returns zero
   rows. The mitigations, in order: prefix-match the last token, porter stemming, and a bounded
   Dart-side pass offering *"Did you mean…"*. **Do not add a second trigram index for typos.**
10. **The isolate gotcha, and it will bite this test before it bites production.** `withClock()`
    installs a **zone value**, and zone values do not cross isolate boundaries — so a `withClock`
    wrapper does **not** reach the migration if the database was opened through `driftDatabase()`'s
    background connection. **Migration and seed tests must use an in-process `NativeDatabase.memory()`.**
    Every seed assertion about *today's* date depends on this.
11. **`seedFirstRun` creates no pens** (decision #42). Pens are created lazily and implicitly — the
    first time a ewe is penned the app offers 1…n and creates the row on tap, so the board fills as the
    shed fills. The zero-pen board shows a single 72 pt "Add a pen" tile, never an empty grid. A seeded
    pen list is a wrong guess about somebody's shed.
12. **The seed calls `appNow()` once** (R23) and derives both the year and the civil date from it. Two
    reads can straddle midnight and produce a season labelled for one year starting in another.
13. **`seedOnCreate` is `false` on exactly two paths** — the restore/import staging database (04 §7) and
    `tool/seed.dart` — where the rows come from a backup. A restore that seeds hands the user a phantom
    *"2026 lambing"* season nobody created, which is a support ticket, not a bug report.
14. **R66 versus the DoD's wording, resolved.** The ~40 terms have **three** homes and no overlap:
    **keys** → `lib/core/db/seed/first_run.dart` (`origin='seeded'`, `label=NULL`, a `sort_order`);
    **labels** → `lib/l10n/app_en.arb`, one message per key; **`assets/content/`** → only authored prose
    too long to be a UI string, plus one provenance line per list. `00-PLAN-CRITIQUE` §8 carries this as
    an `[audit]` correction of an earlier reading. So the keys **are** Dart in `first_run.dart` — the
    DoD line means the user-visible wording never appears as a Dart literal, and it does not.
15. **`lambing_ease` descriptions are paraphrased, never adopted.** The SRUC technical note cited in the
    research is image-based; its text and its licence terms **could not be verified**, and the "adopt
    them verbatim" instruction is overturned. Write the 1–5 scale in the app's own words at the same
    semantic granularity. The *concept* of a five-point assistance scale is not ownable; the sentences
    are. The "no verbatim third-party copy" CI check scans **both** `assets/content/` and `lib/l10n/`
    (R66) — a check pointed at one of them misses whichever half the copy was pasted into.
16. **No `customStatement(` outside `lib/core/db/`** (layer rule 8, `layer.single_writer`). Fallback A
    above is the only thing in this epic that adds one, and it is inside the permitted folder.

### 5.4 The test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/data/seed_first_run_test.dart` | `'onCreate seeds a season, the ~40 vocab terms, and FTS5 with zero real rows'` | The anchor, every count. |
| | `'AppDatabase(conn, seedOnCreate: false) yields the same schema and zero seasons'` | 04 §7's restore precondition — completes the half T02 opened. |
| | `'the seeded season label is <year> lambing and start_date is today'` | The one string a user sees on first run, and it is renameable in Settings. |
| | `'the seed creates zero pens'` | Decision #42, asserted so a well-meaning later change is caught. |
| | `'every seeded vocab_term has origin = seeded, label NULL and a sort_order'` | The three properties the ARB overlay depends on. |
| | `'the six lists hold 5, 8, 8, 8, 6 and 5 keys'` | Per list, not just the total — a total of 40 can be reached with the wrong distribution. |
| | `'seeding twice on the same file is impossible because onCreate runs once'` | The seed is not idempotent and does not need to be; assert the mechanism, not a retry. |
| `test/data/search_test.dart` | `'creating a ewe, a lamb and a lambing with every optional text field blank succeeds'` | **The `COALESCE` trap.** The single most valuable case in this task. |
| | `'searchAll returns a row for a note containing the query term'` | One **real execution** — the alias and `rank_score` traps pass codegen. |
| | `'searchAll orders a title match above a body-only match'` | `bm25(f, 2.0, 1.0)` ascending. |
| | `'a note containing the word OR does not throw'` | `OR` is an FTS5 operator. Tokenise before building syntax; this is the case that fails at 3am. |
| | `'updating a note body updates the excerpt and deleting it removes the row'` | The `_au` and `_ad` trigger arms — the two drift#3322 may refuse. |
| | `'deleting a season leaves zero search_docs rows whose subject no longer exists'` | The cascade-versus-`recursive_triggers` question, from both directions of the pragma. |
| | `'INSERT INTO search_fts(search_fts) VALUES(''integrity-check'') does not throw after a season delete'` | The FTS5 self-check, which is the only thing that sees an external-content index whose rows no longer match their content table. |
| | `'search_fts holds zero rows on a freshly seeded database'` | FTS5 present in v1 with nothing in it — the whole reason it ships now. |
| `test/policy/vocab_labels_are_complete_test.dart` | `'every seeded vocabulary key has an ARB message and every message has a key'` | Set equality **both ways**. A key without a label renders blank at 3am; a label without a key is dead copy. |
| `test/data/vocab_list_scope_test.dart` | (from T06) now runs against seeded rows | The scope assertion has real data to work on for the first time. |
| `test/domain/uk_zone/seed_first_run_dst_test.dart` | `'a first run at 00:30 BST on 29 March 2026 seeds start_date 2026-03-29'` | `@Tags(['uk-zone'])`, `TZ=Europe/London`, in-process memory database. The instant is 23:30 UTC on the **28th**. |
| | `'a first run at 01:30 on 25 October 2026 seeds one season, not two'` | The ambiguous hour happens twice; `appNow()` is read **once**. |
| | `'a first run at 00:30 on 1 January 2027 seeds year 2027, not 2026'` | Year boundary — the label and the `year` column must agree. |

### 5.5 Verification that the `.drift` files are actually wired

`include:` is a set of file names resolved relative to `database.dart`. A typo produces a
`build_runner` error naming the missing file; a file that exists but is **not** in the set produces no
error at all and no table — which is why `'search_fts holds zero rows'` is an assertion and not an
assumption. After `build_runner`, confirm `database.g.dart` contains a `searchAll` method and a
`penBoard` method.

## 6. Constraints that bind this task

- **The 3am test** — *"a first run that has to ask which season is this has already failed it."*
  Nothing here asks the user anything, and nothing blocks an entry to make someone set something up
  first.
- **Never give veterinary advice** — the seeded terms are generic husbandry vocabulary written from
  scratch: no product name, no dose, no diagnosis, no *should*. `ContentPolicy`'s scan covers both
  `assets/content/` and `lib/l10n/`.
- **Offline** — no network path may be added; the seed reads only the device clock and the shipped
  content.
- **Every string a user reads goes through `app_en.arb` with a `description`** (`00-README` §8 step 22).
  The forty labels are the largest single ARB addition in the project.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'onCreate seeds a season, the ~40 vocab terms, and FTS5 with zero real rows'` passes, and was seen to fail first for the stated reason
- [ ] FTS5 exists in v1 and holds zero real rows
- [ ] the seed creates the current season from the device's civil date
- [ ] the ~40 terms come from `assets/content/`, not from a Dart literal
- [ ] no `customStatement(` outside `lib/core/db/`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

> **Read the fourth DoD line through R66 and `00-PLAN-CRITIQUE` §8's `[audit]` correction** (gotcha 14):
> the ASCII **keys** are Dart in `first_run.dart`, the user-visible **labels** are ARB messages, and
> `assets/content/` carries the provenance line per list plus any prose too long to be a label. No
> user-facing wording is a Dart literal, which is what the line is protecting.

## 8. Verification

```bash
# 1. Red first — and note the in-process memory database, not driftDatabase().
fvm flutter test test/data/seed_first_run_test.dart

# 2. build_runner ONLY — it also parses all three .drift files.
dart run build_runner build --delete-conflicting-outputs

# 3. The search traps and the seed, then the ARB set-equality gate.
fvm flutter test test/data/search_test.dart test/data/seed_first_run_test.dart
fvm flutter test test/policy/vocab_labels_are_complete_test.dart

# 4. The London-zone seed cases.
TZ=Europe/London fvm flutter test --tags uk-zone

# 5. The one grep layer rule 8 turns on.
grep -rn "customStatement(" lib/ --include=*.dart | grep -v "^lib/core/db/"   # expect: nothing

# 6. Nothing under drift_schemas/ has moved — the freeze is the next commit.
git status --short drift_schemas/ test/drift/

# 7. Both gates.
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(db): search, views, queries and the first-run seed`

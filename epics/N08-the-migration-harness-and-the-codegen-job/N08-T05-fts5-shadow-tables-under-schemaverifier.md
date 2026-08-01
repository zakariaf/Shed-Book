# N08-T05 — FTS5 shadow tables under `SchemaVerifier`

| | |
|---|---|
| **Epic** | [N08 — The migration harness and the `codegen` job](epic.md) · `00-README` §9 step 3 (2 of 2) |
| **Task** | 5 of 7 |
| **Depends on** | N08-T04 |
| **Commit** | one commit · `test(drift): answer the FTS5 shadow-table question in week one` |

## 1. Why this task exists

The day-one unverified claim, checked: does `SchemaVerifier` choke on FTS5 shadow
tables? Answer it now, with zero rows, and **write the answer down** — because discovering it at v4
with real data is a different problem entirely.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/04-migrations-media-backup-restore.md` | §3.4, §3.2, §10 | the unverified claim verbatim, the two named outcomes, and the Definition-of-Done line that says the answer is written into §3.4 |
| `docs/engineering/03-data-model-and-schema.md` | §9.2 | `search_docs`, `search_fts`, the four shadow tables, the six sync triggers, and drift#3322's fallbacks A and B |
| `docs/research/00-tech-decisions.md` | #35, #36, §5.1, §5.2 | FTS5 over one fan-in table · FTS5 is a startup assertion, not a probe · `sqlite3` 3.5.0 bundles the engine · `drift_dev` 2.34.5 owns `SchemaVerifier` |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | the verifier's treatment of shadow tables |
| `shed-testing` | the tier and the recorded outcome |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/drift/fts5_shadow_tables_test.dart`
- **Test** — `'SchemaVerifier accepts a schema containing FTS5 shadow tables'`
- **Why it is red today** — the claim is unverified and `04` records it as such.

```bash
fvm flutter test test/drift/fts5_shadow_tables_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the test, then the answer recorded in `04-migrations-media-backup-restore.md` in the same
commit — including the workaround if the answer is no. Name all four shadow tables in the assertion, so a partial tolerance reads as a partial pass.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

Step 7 (tests) plus one documentation edit that `04 §3.4` explicitly asks for. Production code moves
**only** if the answer is no — see §5.3.

| # | File | What changes, and why |
|---|---|---|
| 1 | `test/drift/fts5_shadow_tables_test.dart` | **New.** `@Tags(['migration'])`. Drives the verifier and `validateDatabaseSchema()` against the frozen v1 schema, which already carries `search_fts`. |
| 2 | `docs/engineering/04-migrations-media-backup-restore.md` §3.4 | **Edit, in this same commit.** The heading loses **UNVERIFIED, check on day one**; the section gains the answer, the pinned versions it was measured on, the date, and — if the answer is no — which workaround shipped. `04 §10` has a Definition-of-Done line that reads *"FTS5 shadow tables have been proven to pass or fail `SchemaVerifier` on a real run, and the outcome is written into §3.4"*; tick it here. |
| 3 | `docs/engineering/03-data-model-and-schema.md` §9.2 | **Edit, if and only if the answer changes the schema.** Its closing block carries the same question and names fallbacks A and B. Under the amendment rule both documents change together or neither does. |
| 4 | `lib/core/db/search.drift` | **Touched only if the answer is no.** Excluding the virtual table from the snapshot, or moving note search behind a plain `search_docs` table, is a schema change — see §5.3's warning about what that costs at this point in the build order. |

### 5.2 What is actually being asked

`search_fts` is an **external-content** FTS5 virtual table over `search_docs` (`03 §9.2`, #35):

```sql
-- lib/core/db/search.drift, frozen into drift_schemas/drift_schema_v1.json by N07-T08
CREATE VIRTUAL TABLE search_fts USING fts5(
  title,
  body,
  content='search_docs',
  content_rowid='id',
  tokenize='porter unicode61 remove_diacritics 2',
  prefix='2 3'
);
```

SQLite materialises four shadow tables for it, and all four appear in `sqlite_schema`:
`search_fts_data`, `search_fts_idx`, `search_fts_docsize`, `search_fts_config`. Schema-diffing tools
in other ecosystems have historically choked on exactly these — `04 §3.4` cites prisma#8106 and
rails#52354. **Nobody has verified whether `drift_dev` 2.34.5's `SchemaVerifier` tolerates them.**

Two different comparisons must both be exercised, because they read different sources and either
could tolerate what the other rejects:

| Mechanism | Compares | Reached from |
|---|---|---|
| `verifier.migrateAndValidate(db, kSchemaVersion)` | the live `sqlite_schema` against `drift_schemas/drift_schema_v1.json` | `SchemaVerifier(GeneratedHelper())` in `package:drift_dev/api/migrations_native.dart` |
| `db.validateDatabaseSchema()` | the live `sqlite_schema` against the expected schema generated into `database.g.dart` | decision #39's `beforeOpen` self-check, the same extension member |

### 5.3 The details that are easy to get wrong

- **At v1 the matrix runs zero pairs, so the matrix does not answer this.** `migrateAndValidate` is
  never called by `test/drift/migration_matrix_test.dart` while `kSchemaVersion == 1`. That is
  precisely why this is its own task: `startAt(1)` followed by `migrateAndValidate(db, 1)` runs no
  migration step but **does** run the validation half, and validation is the half the shadow-table
  question lives in. If you skip this task because "the matrix is green", the matrix was green
  because it ran nothing.
- **`04 §3.4` names the two acceptable outcomes and forbids a third.** If the verifier rejects the
  shadow tables, the choices are (a) move note search behind a plain `search_docs` table with a
  ranked, `LIKE`-free query, or (b) exclude the virtual table from the snapshot. *"Do not paper over
  it by disabling the assertion."* Deleting the expectation, wrapping it in a `try`, or adding a
  tolerant comparator is the failure mode this task exists to prevent.
- **Option (a) is a schema change, and the schema was frozen one epic ago.** N07-T08 committed
  `drift_schemas/drift_schema_v1.json` — `04 §1` row 1 calls the first committed snapshot
  irreversible. If the answer is no and (a) is chosen, this stops being a `test(drift)` commit and
  becomes a schema decision routed to the owner (`CLAUDE.md` amendment rule item 4). Do not
  regenerate the v1 snapshot to "fix" it; a snapshot committed twice is the state the freeze exists
  to prevent. The clean path if the schema must change is a v2 with its own step, its own
  `make gen`, and its own commit.
- **The shadow tables are not the only FTS5 hazard in flight.** `03 §9.2` carries drift#3322: the
  SQL analyser does not fully model FTS5's special INSERT commands
  (`INSERT INTO t(t) VALUES('delete')`, `VALUES('rebuild')`), with fallbacks A and B and a
  half-day budget. That question is N07-T07's and should already be answered by the time you get
  here — read what it recorded before you start, because if fallback B shipped there is no
  `content='search_docs'` and this test is asserting against a different schema.
- **`recursive_triggers` is per-connection and it is in the pragma list for a reason.** If the
  harness builds a connection without `configureConnection`, the FTS5 sync triggers behave
  differently and the shadow tables can hold rows that `search_docs` does not. Use the project's own
  open path, not a bare `NativeDatabase.memory()`.
- **Zero rows is the point, not a shortcut.** `04 §3.4`: write the test *"with FTS5 present in
  schema v1, before there is a single real row"*. An empty `search_fts` still materialises all four
  shadow tables, so the structural question is fully answered with no data — and answering it with
  data would only make the failure slower to reproduce.
- **Record the versions with the answer.** The finding is *"on `drift` 2.34.2 / `drift_dev` 2.34.5 /
  `sqlite3` 3.5.0"*, not *"drift tolerates it"*. Decision-record §5 is the only source of those
  numbers. An answer without its versions is an answer that expires silently at the next bump.
- **Nothing here is time-shaped.** No instant, no civil date, no `appNow()` — no ambiguous-hour case
  in this task.

### 5.4 The test set

`test/drift/fts5_shadow_tables_test.dart` — `@Tags(['migration'])`.

| Case | Asserts |
|---|---|
| `'SchemaVerifier accepts a schema containing FTS5 shadow tables'` | **anchor.** `startAt(kSchemaVersion)` → `AppDatabase(connection, seedOnCreate: false)` → `migrateAndValidate(db, kSchemaVersion)` completes without throwing, with `search_fts` present. |
| `'validateDatabaseSchema accepts the same schema'` | decision #39's `beforeOpen` self-check, run explicitly. It compares against `database.g.dart`'s expected schema rather than the snapshot JSON, so it can disagree with the anchor — and if it does, that disagreement is the finding. |
| `'all four shadow tables are present in sqlite_schema'` | `search_fts_data`, `search_fts_idx`, `search_fts_docsize`, `search_fts_config` — named individually, so partial tolerance is visible rather than averaged away |
| `'the v1 snapshot describes search_fts'` | reads `drift_schemas/drift_schema_v1.json` and asserts the virtual table is in it. If it is absent, the verifier's tolerance is vacuous — it is agreeing about a table it never knew existed. |
| `'the FTS5 index round-trips through a migrate-and-validate'` | one row into `search_docs`, the trigger populates `search_fts`, `migrateAndValidate` runs, then `INSERT INTO search_fts(search_fts) VALUES('integrity-check')` does not throw. Proves validation did not leave the index inconsistent. |
| `'the engine has FTS5 at all'` | the `pragma_compile_options` probe `03 §1.3` uses. A red anchor caused by a host build without `SQLITE_ENABLE_FTS5` is a completely different problem, and this case is what tells the two apart in one line. |

### 5.5 Verification, in order

```bash
fvm flutter test test/drift/fts5_shadow_tables_test.dart
fvm flutter test test/drift/                        # the tier, with the answer in hand
git diff --stat docs/engineering/                   # the answer landed in the document, not only the test name
make check
make test
```

## 6. Constraints that bind this task

- **The answer is written down, in the document, in this commit.** A finding that lives only in a
  test name is a finding the next developer re-derives at v4 with real data.
- **Do not disable the assertion.** `04 §3.4` forbids it by name; the two named workarounds are the
  only acceptable outcomes if the answer is no.
- **The schema is frozen.** Touching `drift_schemas/` here is a ruling, not a fix.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'SchemaVerifier accepts a schema containing FTS5 shadow tables'` passes, and was seen to fail first for the stated reason
- [ ] the answer is recorded in the document, not only in a test name
- [ ] if it chokes, the workaround is implemented here and not deferred
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/drift/fts5_shadow_tables_test.dart
fvm flutter test test/drift/
git diff --stat docs/engineering/
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(drift): answer the FTS5 shadow-table question in week one`

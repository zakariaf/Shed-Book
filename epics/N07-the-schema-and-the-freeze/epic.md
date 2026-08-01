# N07 — The schema and the freeze

| | |
|---|---|
| **`00-README` §9 step** | 3 (1 of 2) |
| **Depends on** | N06 |
| **Size** | XL |
| **Was** | E06, re-cut from fourteen tasks to eight |
| **Branch** | `epic/n07-schema-and-freeze` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `test` |

## Goal

The 23 tables of `03-data-model-and-schema.md` §5, in four clusters, each `STRICT`, each foreign key
explicit and hand-indexed, both partial unique indexes, the birth-dam immutability trigger, the two
views, FTS5 over `search_docs` with zero real rows, the first-run seed — and **the first committed
schema snapshot**, `drift_schemas/drift_schema_v1.json`, written once and never again.

## Why this epic sits here

`00-README` §9 step 3: *"The freeze point. Everything the open questions in §5.2 marked schema-shaped
must land here or be accepted as a future migration. Discovering that `SchemaVerifier` chokes on FTS5
shadow tables at v4 with real data is a different problem than discovering it in week one with none."*

The two facts §9 opens with set the order and both point here: **Quick Entry is the product**, and
**the schema cannot be changed later** — there is no server-side backfill, no remote kill switch, and
the only backup is one the user remembered to make. So the sequence front-loads the irreversible and
the invisible-when-wrong. Step 2 (N04–N06) put the pure domain in first because it compiles before
Flutter is involved; this step turns those value types into columns. Step 4 (N09–N11) cannot start
until there is something to read.

Three things must land **inside** this epic or become a full table rebuild on a phone in April:

| Must land before the snapshot | Ruling |
|---|---|
| `lambings.declared_birth_type` nullable, no default | `CONVENTIONS` **R6** |
| The §12.5 provenance quad on all seven quad-carrying tables | `CONVENTIONS` **R37** |
| All three `media_assets.relative_path` CHECKs | `CONVENTIONS` **R62** |

Plus `struck` / `struck_at` (**P1**, ruled in [N00-T05](../N00-decisions-rulings-and-the-calendar/N00-T05-rule-p1-struck-struck-at-on-every-table.md))
and the four schema-shaped questions ruled in
[N00-T04](../N00-decisions-rulings-and-the-calendar/N00-T04-rule-the-four-schema-shaped-questions.md).
Both are upstream dependencies of this epic for exactly that reason.

## Why this is one pull request

`00-README` §9 step 3 says it in one breath and `04 §1` makes the first committed snapshot the
irreversible event. Splitting the tables across pull requests would either commit a snapshot twice or
invent migration steps for a schema no phone will ever hold, and those steps live in
`schema_versions.dart` forever.

**This epic takes the stated exception to one-commit-per-task** (`00-PLAN-CRITIQUE` §9 row 13 and its
delivery-rule table). Each of T01–T07 ends in `dart run build_runner build --delete-conflicting-outputs`
only, so the tree compiles at each commit but the snapshot is not written. `make gen` in full —
`build_runner` **plus** `drift_dev make-migrations`, which is what writes the snapshot — runs exactly
once, alone, in T08. That task is `kSchemaVersion`, `drift_schemas/drift_schema_v1.json`,
`schema_versions.dart` and `test/drift/generated/**` and nothing else, per `00-README` §7.4's rule
that a schema change must not be split.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | §1–§10 | every table, column, index, view, trigger, constraint and the seed |
| `docs/engineering/04-migrations-media-backup-restore.md` | §1, §2.2–§2.5, §6.5 | the four irreversible things, the ritual, the artefacts, `unknown_json` |
| `docs/engineering/00-README.md` | §7.1, §7.3, §7.4, §8 step 1, §9 step 3 | what is committed, `make gen`, what may not be split, the schema step's order |
| `docs/engineering/12-testing.md` | §2.3, §3.1–§3.3 | the ambiguous hour, the in-memory harness, no mocks |
| `docs/engineering/CONVENTIONS.md` | §1, §2.8, §4.6, R6, R12–R16, R21, R22, R37, R38, R40, R62, R66 | every path, class, column and index name |
| `docs/research/00-tech-decisions.md` | §5 | the only source of `drift` 2.34.2 / `drift_dev` 2.34.5 / `sqlite3` 3.5.0 / `uuid` 4.6.0 |

## Tasks

| Task | One line | Depends on |
|---|---|---|
| [N07-T01](N07-T01-connectiondart-pragmas-fts5-and-the-in-memory-harness.md) | `connection.dart` — the seven pragmas in R13's order, the FTS5 assertion, `testDatabase()` | N06, last task |
| [N07-T02](N07-T02-databasedart-convertersdart-uiddart-and-mixin-identified.md) | `database.dart`, `converters.dart`, `uid.dart` and `mixin Identified` | N07-T01 |
| [N07-T03](N07-T03-the-flock-cluster.md) | The flock cluster — and the active-only partial unique index on `tag` | N07-T02 |
| [N07-T04](N07-T04-the-lambing-cluster.md) | The lambing cluster — the birth-dam trigger and the two views | N07-T03 |
| [N07-T05](N07-T05-the-pen-and-treatment-clusters.md) | The pen and treatment clusters — no `DEFAULT` on withdrawal days | N07-T04 |
| [N07-T06](N07-T06-the-ancillary-cluster-and-unknown-json.md) | The ancillary cluster and `unknown_json` on all 21 restorable tables | N07-T05 |
| [N07-T07](N07-T07-searchdrift-viewsdrift-queriesdrift-and-seedfirstrun.md) | `search.drift`, `views.drift`, `queries.drift` and `seedFirstRun` | N07-T06 |
| [N07-T08](N07-T08-the-freeze-alone.md) | **The freeze, alone** — `make gen` once, the v1 snapshot | N07-T07 |

The chain is strictly linear: every task registers tables in the same `@DriftDatabase` annotation, so
two of them in flight at once is a merge conflict in the one file that must not be wrong.

## What is observably true when this epic merges

Run these against the merged `main`. Each one is a claim a developer or the owner can check.

1. **A real SQLite file opens with the right pragmas.**
   `fvm flutter test test/data/connection_test.dart` — `journal_mode` is `wal`, `synchronous` is `2`,
   `foreign_keys` is `1`, `recursive_triggers` is `1`, and a build without FTS5 throws a readable
   `StateError` instead of silently degrading.
2. **The database refuses garbage rather than storing it.** Every table is `STRICT`; `'twin'` in an
   INTEGER column is an error, not a row.
3. **The database refuses two ACTIVE ewes on tag 412 — and permits a culled one.**
   `test/data/schema_flock_test.dart` proves both directions.
4. **The database refuses two ewes in pen 3.** `idx_penocc_one_open` — an index, not a Dart check.
5. **`UPDATE lambs SET birth_dam = …` throws.** The trigger, not a repository guard.
6. **A `treatment_withdrawals` row cannot be written without a number the user typed.** No `DEFAULT`,
   no `clientDefault`, and the committed schema JSON proves it.
7. **A fresh install has a season without being asked.** `onCreate` on an empty file yields exactly
   one `seasons` row, one `app_settings` row, one `entitlements` row, the ~40 `vocab_terms` rows, the
   reminder rules, and **zero** pens.
8. **`AppDatabase(conn, seedOnCreate: false)` yields the same schema and zero seasons** — the restore
   path's precondition (04 §7).
9. **`drift_schemas/drift_schema_v1.json` is committed — once.**
   `git log --oneline -- drift_schemas/` prints exactly one commit.
10. **`make gen` produces no git diff on a clean checkout.** Run it, then `git status --short`.

Nothing is demoable on screen: there is no `main()` yet (N11) and no repository (N12+). The
demonstration for this epic is a green `make test` and a schema JSON a human has read.

## The pull request, concretely

**Cut the branch from a green `main`.**

```bash
git switch main && git pull --ff-only
make check && make test        # main must be green BEFORE you branch
git switch -c epic/n07-schema-and-freeze
```

**One commit per task, T01 → T08, in order.** For each: write the anchor test named in the task's §4,
run it, see it fail for the stated reason, make it pass, then `/simplify` → `/code-review` →
`/shed-code-review` → `git commit` with the exact message in the task's header. T01–T07 run
`dart run build_runner build --delete-conflicting-outputs` and commit `database.g.dart` /
`*.drift.dart`; **none of them runs `drift_dev make-migrations`.**

**Open the PR after T08 and not before.**

```bash
git push -u origin epic/n07-schema-and-freeze
gh pr create --base main --title "N07 — the schema and the freeze"
```

Answer the five §12 questions that `.github/pull_request_template.md` (N01-T07) puts in the body
verbatim. For this epic §12.1 and §12.5 are the two that carry real weight: name
`treatment_withdrawals.days` and the seven quad-carrying tables in your own words.

**Wait for the pipelines. Two jobs run on this epic and each proves something different.**

| Job | Runner | What it runs | What it proves for N07 |
|---|---|---|---|
| `gate` | `ubuntu-latest` | toolchain pin vs `.fvmrc` · `flutter pub get` · `tool/check_policy.dart` (G2 + G3) · `dart format --set-exit-if-changed` · `flutter analyze --fatal-infos --fatal-warnings` · the ATS text check | No `dateTime()` column, no `store_date_time_values_as_text`, no `customStatement(` outside `lib/core/db/`, no `driftDatabase(` second call site, no banned dependency, no `DateTime.now(` outside `app_clock.dart`, and `lib/core/db/` importing nothing it may not |
| `test` | `ubuntu-latest` **+ `libsqlite3-dev`** | `flutter test -P ci-fast` randomised · `TZ=Europe/London flutter test --tags uk-zone` · `TZ=Pacific/Chatham flutter test test/domain --exclude-tags uk-zone` · coverage artefact (reported, never gated) | Every constraint, index and trigger in this epic, executed against **real** SQLite — the only tier that can see a partial index or a `BEFORE UPDATE` trigger at all |

```bash
gh pr checks --watch
```

**The `codegen` job does not exist yet.** It is [N08-T06](../N08-the-migration-harness-and-the-codegen-job/N08-T06-the-codegen-ci-job.md),
the *next* epic. Until it does, nothing in CI re-runs the generators and diffs them, so a stale
`database.g.dart` or a snapshot that does not regenerate byte-identically is **invisible on this PR**.
That is the single largest hole in this epic's coverage; the compensating control is manual and
belongs in the PR body:

```bash
make gen && git status --short   # must print nothing
```

**`libsqlite3-dev` on the runner is the one line between a working and a red CI on day one**
(12 §3.2). `test/data/host_sqlite_version_test.dart` asserts the host build is ≥ 3.41.0. If it fails,
the fix is the runner image — never the assertion. Lowering it to whatever the runner happens to ship
is how `STRICT` stops being tested.

**Merge with a merge commit, not a squash.**

```bash
gh pr merge --merge --delete-branch
```

A squash collapses T01–T08 into one commit and makes *"the snapshot was committed exactly once"*
unprovable from `git log -- drift_schemas/` for the life of the project. The eight commits are the
evidence; keep them.

**Then, and only then, cut N08.**

```bash
git switch main && git pull --ff-only
make check && make test        # main green after the merge
git switch -c epic/n08-migration-harness
```

## Risks, and what is irreversible

> ### ⚠ `drift_schemas/drift_schema_v1.json` is written once, in T08, and can never be rewritten.
>
> `04 §1` item 1: the first committed snapshot **freezes the storage representation of every column
> in it**. Not the file — the *representation*. Every later version is diffed against this file by
> `SchemaVerifier`, forever, including in 2029 on a phone that has never been online. There is no
> server-side backfill and no way to push a hotfix to a device that never connects. Deleting or
> hand-editing this file is unrecoverable: `00-README` §7.1 — *"Losing these is unrecoverable."*
>
> The other three of `04 §1`'s four irreversible things are also decided in this epic: instants as
> `INTEGER` epoch millis and civil dates as `TEXT` (item 1, decisions #29/#30); relative media paths
> enforced by three CHECKs (item 3, R62); and the shape restore will replace wholesale (item 4).

| Risk | Why it bites here | What holds it |
|---|---|---|
| A column that should have been nullable is `NOT NULL` | Adding a `NOT NULL` column afterwards is a full table rebuild on tables that point at the user's records | R6, R37, R62 land in T03–T06; T08 asserts all three off the **JSON**, not off the source |
| A `DEFAULT` on `treatment_withdrawals.days` | Spec §12.1 defeated in a column definition, invisible in review | Two gates and only these two (03 §5.8): the schema-JSON test in T08, and a widget test in N20 |
| `store_date_time_values_as_text` set, or a drift `dateTime()` column | Both are irreversible after the snapshot and both are a single global flag over every column | `check_policy` text rules; `gate` fails the build |
| A missing foreign-key index | Deleting a season linear-scans every child table; every `RESTRICT` check is a full scan | `test/data/every_fk_is_indexed_test.dart` — exactly one allowlisted table, `app_settings` |
| The `codegen` job does not exist during this epic | A stale generated file is invisible locally and lethal on a fresh clone | `make gen && git status --short` before every commit, and again before the PR opens |
| drift#3322 — the analyser may refuse FTS5's special INSERT commands | Discovered in T07, one task before the freeze | Fallback A or Fallback B, decided in T07 and recorded there and in doc 04. Take B if A costs more than half a day |
| `SchemaVerifier` may choke on the FTS5 shadow tables | Not provable until N08-T05, one epic later | FTS5 is present in v1 **with zero real rows** precisely so this is a week-one problem with nothing to lose |
| A schema-shaped open question survives the freeze | `00-README` §5.2 items 10, 11, 13 and 15 all expire here | N00-T04 rules all four before this epic starts. If one is still open, **stop** — do not guess |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `test`
- [ ] `make gen` on a clean checkout leaves `git status --short` empty
- [ ] `git log --oneline -- drift_schemas/` prints exactly one commit
- [ ] R6, R37 and R62 are each asserted against `drift_schemas/drift_schema_v1.json`, not against the Dart source
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`

## Demoable on merge

A real SQLite file opens with `STRICT`, refuses garbage, seeds a season nobody was asked
about, and `drift_schemas/drift_schema_v1.json` is committed — once.

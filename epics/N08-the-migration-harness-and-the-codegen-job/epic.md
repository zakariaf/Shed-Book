# N08 — The migration harness and the `codegen` job

| | |
|---|---|
| **`00-README` §9 step** | 3 (2 of 2) |
| **Ships in** | `v1.0.0` |
| **Depends on** | N07 |
| **Size** | M |
| **Was** | E07 |
| **Branch** | `epic/n08-migration-harness` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

The from→to matrix, the scoped data-integrity test, the loud downgrade, the FTS5 shadow-table
question answered in week one, and the CI job that makes a stale generated file impossible.

## Why the epic sits here

`00-README` §9 makes step 3 the **freeze point**: *"Everything the open questions in §5.2 marked
schema-shaped must land here or be accepted as a future migration. Discovering that `SchemaVerifier`
chokes on FTS5 shadow tables at v4 with real data is a different problem than discovering it in week
one with none."* N07 did the first half — every table, every constraint, and the one committed
`drift_schemas/drift_schema_v1.json`. N08 is the second half: the machinery that keeps that snapshot
honest for the next five years.

Two of §9's stated reasons bear directly on the ordering. The schema cannot be changed later,
because the only backup is one the user remembered to make — so the harness that proves a migration
is safe must exist before the first migration does, not after. And the epic reaches pixels never:
nothing here renders, so it is the last point in the build order where a mistake costs a day rather
than a rewrite.

It also closes the second of `13 §4.2`'s four blocking jobs. `gate` and `test` arrived with N01;
`codegen` arrives here, because it has nothing to diff until generated schema artefacts exist;
`android` waits for N31.

## What is observably true when this epic merges

Run these on a clean clone of the merged `main` and watch them pass:

```bash
make gen && git status --porcelain     # silent — the committed artefacts describe the committed schema
fvm flutter test test/drift/           # the whole migration tier, unrandomised, green
```

Concretely, after the merge:

- **Every from→to pair the version count yields runs `SchemaVerifier.migrateAndValidate`**, with
  `PRAGMA foreign_key_check` empty and `PRAGMA quick_check` returning `'ok'` after each hop — with
  the FTS5 virtual table and its four shadow tables present, and zero real rows.
- **The FTS5 shadow-table question has an answer, written into `04 §3.4`** with the drift and sqlite3
  versions it was measured on. It is no longer a paragraph headed *UNVERIFIED*.
- **A stale generated file cannot merge.** Push a commit with an edited `database.g.dart` or an
  unadded `drift_schema_v2.json` and the `codegen` job goes red with a named annotation.
- **Rows written with the v1 companions survive a migration and are found again by `uid`**, with
  their provenance quad byte-identical — including a lambing recorded at 01:30 on 25 October 2026,
  an hour that happens twice.
- **A database written by a newer schema refuses to open**, leaving `user_version`, the file length
  and `sqlite_schema` untouched, and surfaces a failure that tells the shepherd to update the app.
- **An upgrade leaves one byte-faithful snapshot in `pre_migration/`** before drift touches
  anything, bounded in size and count, and a snapshot that fails does not stop the app opening.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/04-migrations-media-backup-restore.md` | §1, §2, §3, §8 | the four irreversible things · the migration ritual and the five rules · the from→to matrix, the scoped data test, the downgrade and the no-diff check · `VACUUM INTO` |
| `docs/engineering/12-testing.md` | §1.4, §3.2, §3.4, §11.2 | a source scan is the gate, never a `test()` · the host sqlite3 floor · the migration tier · the `migration` tag and the two unverified `dart_test.yaml` questions |
| `docs/engineering/13-build-ci-release.md` | §1.1, §1.3, §4.2, §4.3 | the toolchain pin · `make gen` · the four-job matrix · `ci.yml`'s `codegen` job |
| `docs/engineering/CONVENTIONS.md` | §1, §2.5, §2.8, §4.7, R12–R14, R52 | the tree · the failure catalogue · the database names · the connection file and its fixed pragma order · one diagnostics sink |
| `docs/research/00-tech-decisions.md` | §5, #37, #38, #39, #84 | the only source of a version number · forward-only migrations · the matrix and the no-diff check · the debug self-check · JSON is the backup, `VACUUM INTO` is a snapshot |

## Tasks

Strictly sequential, one commit each. T01 begins on a branch cut from the merged N07 — the schema
freeze — and each task depends on the one above it.

| Task | Depends on | One line |
|---|---|---|
| [N08-T01](N08-T01-migrationsdart-the-stepbystep-scaffold.md) | N07, merged | `migrations.dart` — the `stepByStep` scaffold, and the five rules in the source |
| [N08-T02](N08-T02-the-from-to-matrix.md) | N08-T01 | The from→to matrix — every pair, `foreign_key_check` empty, `quick_check` ok |
| [N08-T03](N08-T03-testwithdataintegrity-scoped.md) | N08-T02 | `testWithDataIntegrity`, scoped to N-1→N and to any step that rewrites a table |
| [N08-T04](N08-T04-the-loud-downgrade.md) | N08-T03 | The loud downgrade — a newer file never opens, and the message says what to do |
| [N08-T05](N08-T05-fts5-shadow-tables-under-schemaverifier.md) | N08-T04 | FTS5 shadow tables under `SchemaVerifier` — answered in week one, written down |
| [N08-T06](N08-T06-the-codegen-ci-job.md) | N08-T05 | The `codegen` CI job — regenerate, then refuse any diff and any untracked artefact |
| [N08-T07](N08-T07-snapshotbeforemigration-and-diagnostics-snapshotdart.md) | N08-T06 | `_snapshotBeforeMigration` and `diagnostics_snapshot.dart` — bounded, never fatal |

## The pull request, concretely

1. **Cut the branch from the merged `main`**, after N07's pull request is merged and `main` is green:
   `git switch main && git pull && git switch -c epic/n08-migration-harness`. Not from N07's branch.
2. **One commit per task**, in order T01 → T07, using the commit line printed in each task file.
   Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
   **`/shed-code-review`**. No task is started before the one above it is committed.
3. **After each commit, run `make gen` and `git status --porcelain`.** Until T06 lands there is no
   `codegen` job, so a stale or unadded generated artefact on commits 1–5 is caught by nobody. This
   is thirty seconds per commit and it is the difference between a green branch and a red one at
   step 5.
4. **`/shed-code-review` once more over the whole branch** before the pull request opens, read in
   `00-README` §10's irreversibility order: allowlist and dependency files → `lib/core/db/tables/**`
   and `drift_schemas/` → `lib/data/**` → `lib/domain/` → `lib/l10n/app_en.arb` → `lib/features/**`.
   `drift_schemas/**` is never waved through, however small the diff.
5. **Open the pull request** and answer the five §12 questions in
   `.github/pull_request_template.md` in the body — verbatim, not paraphrased.
6. **Wait for the pipelines. Do not merge on a pending check.** Three jobs run for this epic:

   | Job | Runner | What it proves here |
   |---|---|---|
   | `gate` | `ubuntu-latest` | the toolchain pin agrees with `.fvmrc`; `flutter pub get` resolves; `tool/check_policy.dart` passes **G2** (the dependency allowlist over `pubspec.lock`) and **G3** (the import scan); `dart format --set-exit-if-changed`; `analyze --fatal-infos --fatal-warnings`; no `NSAppTransportSecurity`. For this epic the rules that matter are `db.destructive_ddl`, `db.migration_today_schema`, `db.async_in_assert` and `time.sql_now_*` — no `DROP`, no today-schema reference inside a `from*To*` callback, no `Future` in an `assert`, no SQL-side time. |
   | `codegen` | `ubuntu-latest`, `needs: gate` | regenerates with `build_runner build --delete-conflicting-outputs` and `drift_dev make-migrations`, then refuses any diff over `lib/`, `drift_schemas/` and `test/drift/generated/`. **This is its first run in the project's history**, and it is proving that the snapshot N07 committed genuinely describes the schema N07 committed. |
   | `test` | `ubuntu-latest` **+ `libsqlite3-dev`** | `flutter test` with randomised ordering, then `TZ=Europe/London --tags uk-zone`, then `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone`. For this epic it is the migration tier — the matrix, the data-integrity cases, the downgrade, FTS5 and the snapshot — plus the two ambiguous-hour files. Coverage is uploaded and never gated. |

   `android` is N31's and does not exist yet. Goldens are not a per-PR gate — the macOS runner bills
   at a 10× multiplier — and run on a `v*` tag or manual dispatch.
7. **Merge, then delete the branch.** `git push origin --delete epic/n08-migration-harness` and
   remove the local copy.
8. **Confirm `main` is green after the merge**, then and only then cut the next epic's branch from
   the merged `main`. One epic, one pull request, no overlap.

## Risks specific to this epic

- **Three of the seven tasks can pass by running nothing, and that is the biggest risk here.** At
  `kSchemaVersion == 1` the matrix loop yields zero pairs, there is no N-1 for the data-integrity
  case, and the downgrade test has no lower version to pretend to be. An epic that merges green
  having asserted nothing is worse than a red one. Each task file states the countermeasure: an
  anchor that always runs and iterates inside its body, a degenerate case that still proves the
  converters read what raw SQL wrote, and a self-cancelling skip that fails the moment v2 lands.
- **The `-P ci-fast` disagreement is live and this epic is where it bites.** `12 §11.2` says
  `flutter test` has no `-P` flag and declines to declare presets; `13 §1.3` and `§4.3` invoke
  `-P ci-fast` and `-P ci-golden`. The same check answers whether the `migration` tag's
  `allow_test_randomization: false` takes effect at all. N08-T02 runs it and fixes whichever
  document is wrong. Leaving it means a `Makefile` and a CI job that disagree about which tests ran.
- **The host sqlite3 floor is unverified on the runner image.** `12 §3.2` pins ≥ 3.41.0 and says so
  explicitly: an older LTS image can ship below it, and the symptom is a red
  `test/data/host_sqlite_version_test.dart`, not a mystery. If it fails, the fix is the runner image.
  Lowering the assertion is how `STRICT` quietly stops being tested.
- **The FTS5 answer can force a schema change one epic after the freeze.** If `SchemaVerifier`
  rejects the shadow tables, `04 §3.4`'s two named outcomes both touch the schema, and the schema was
  frozen in N07. That stops being a test commit and becomes an owner decision.
- **A seventh `ShedFailure` variant is a doc-set amendment, not a refactor.** N08-T04 needs a
  message that says *update the app*, and none of the six existing `userMessage` strings does.
  Adding one changes `CONVENTIONS §2.5` and `01 §5` under a numbered ruling.

## Irreversible in this epic — read this before you start

- **`drift_schemas/drift_schema_v1.json` is already frozen and is not touched here.** `04 §1` row 1:
  the first committed snapshot freezes the storage representation of every column in it. If anything
  in this epic seems to require regenerating it, stop — a snapshot committed twice is the state the
  freeze exists to prevent. The correct path is a v2 with its own step, its own `make gen` and its
  own commit.
- **`lib/core/db/schema_versions.dart` is forever.** A released migration step is on someone's phone
  and will never run again. You never edit a committed step; a mistake is repaired by a *new* step at
  the next version (`04 §2.9`).
- **`pre_migration/` is a directory name that ships.** It is written beside the database in
  application support on real phones, and N31's `data_extraction_rules.xml` and `backup_rules.xml`
  must exclude it by that exact name. Renaming it later strands snapshots on devices that already
  wrote them.
- **The `codegen` job's diff paths are a contract with every future commit.** Narrow them and a
  stale artefact merges; the failure is invisible locally and lethal on a fresh clone.

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] `make gen` on the merged `main` leaves `git status --porcelain` silent
- [ ] the `codegen` job was watched going red twice — once on an edited artefact, once on an unadded one — and reverted
- [ ] the FTS5 shadow-table answer is written into `04 §3.4` with the versions it was measured on
- [ ] the `dart_test.yaml` day-one check has been run and its answer recorded in `12 §11.2`
- [ ] `drift_schemas/` is byte-identical to what N07 merged

## Demoable on merge

Every from→to pair runs `migrateAndValidate` with FTS5 present and zero rows, and `make gen`
produces no git diff in CI.

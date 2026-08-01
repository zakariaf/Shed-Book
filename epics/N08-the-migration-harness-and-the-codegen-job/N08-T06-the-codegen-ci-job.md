# N08-T06 — The `codegen` CI job

| | |
|---|---|
| **Epic** | [N08 — The migration harness and the `codegen` job](epic.md) · `00-README` §9 step 3 (2 of 2) |
| **Task** | 6 of 7 |
| **Depends on** | N08-T05 |
| **Commit** | one commit · `ci: the codegen job — regenerate and refuse any diff` |

## 1. Why this task exists

Regenerate, then `git diff --exit-code` over `lib/`, `drift_schemas/` and
`test/drift/generated/`. `00-README` §7.3 calls it the most valuable step in the pipeline after G1,
because a stale generated file is invisible locally and lethal on a fresh clone.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §1.1, §1.3, §4.2, §4.3 | the toolchain pin and its four homes · `make gen`'s two commands · the job table and its `needs:` graph · `ci.yml`'s `codegen` job verbatim, including the action versions |
| `docs/engineering/00-README.md` | §7.1, §7.3, §8 step 9 | what is committed and why · `make gen` is the only way generated code changes · the four jobs a pull request must pass |
| `docs/engineering/04-migrations-media-backup-restore.md` | §2.4, §2.5, §3.6, §2.10 | the ritual's step 6 (*commit code and snapshots together*) · what each artefact is · the no-diff check · *"regenerating in a follow-up commit"* as a named anti-pattern |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-dependencies-and-toolchain` | the CI job matrix and the generator's invocation |
| `shed-drift-schema` | what `make gen` writes and therefore what the diff must cover |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/ci_jobs_test.dart`
- **Test** — `'ci.yml declares a blocking codegen job that diffs lib/, drift_schemas/ and test/drift/generated/'`
- **Why it is red today** — only `gate` and `test` exist; a stale `database.g.dart` would merge unnoticed.

```bash
fvm flutter test test/policy/ci_jobs_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the job, the three paths, and the policy test that parses the workflow for them; the staleness check must also catch a **newly generated file that was never added to the index**, which a bare `git diff` does not see.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

Step 7 (tests) and Step 9 (the pipeline). No schema, no domain, no data, no UI, no ARB — say so in
the commit body.

| # | File | What changes, and why |
|---|---|---|
| 1 | `.github/workflows/ci.yml` | **Edit.** N01-T06 authored `gate` and `test`. This adds a third job, `codegen`, `needs: gate`, `runs-on: ubuntu-latest`, `timeout-minutes: 20`. It is the third of the four jobs `00-README` §8 step 9 lists; `android` arrives in N31. |
| 2 | `test/policy/ci_jobs_test.dart` | **Edit, not create.** The file already exists from N01-T06, where its case is `'ci.yml declares gate and test, both blocking, on push and pull_request'`. This task appends the anchor and the cases in §5.4 to the same file. |
| 3 | `Makefile` | **Read only.** `make gen` is already `build_runner build --delete-conflicting-outputs` then `drift_dev make-migrations` (`13 §1.3`). The job runs the two commands directly, as `13 §4.3` writes them, so a `Makefile` edit can never silently change what CI proves. |

### 5.2 The job

`13 §4.3`, verbatim in shape:

```yaml
  codegen:
    runs-on: ubuntu-latest
    needs: gate
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with: { channel: stable, flutter-version: '${{ env.FLUTTER_VERSION }}', cache: true }
      - run: flutter pub get

      # Generated files ARE committed, so a clean checkout builds. CI proves they
      # match their sources. This is the single most valuable step in the pipeline
      # after G1: the failure is invisible locally and lethal on a fresh clone.
      - name: Regenerate
        run: |
          dart run build_runner build --delete-conflicting-outputs
          dart run drift_dev make-migrations

      - name: Generated code and schema artefacts are fresh
        run: |
          git add -A -- lib/ drift_schemas/ test/drift/generated/
          git diff --cached --exit-code -- lib/ drift_schemas/ test/drift/generated/ || {
            echo "::error::Generated artefacts are stale. Run 'make gen' and commit."
            exit 1; }
```

The three paths, and what each one holds (`04 §2.5`, `00-README` §7.1):

| Path | What regeneration writes there |
|---|---|
| `lib/` | `lib/core/db/database.g.dart`, the `*.drift.dart` files, `lib/core/db/schema_versions.dart`, and `lib/l10n/app_localizations*.dart` |
| `drift_schemas/` | `drift_schema_v<N>.json` — the input to `SchemaVerifier`. Losing one is unrecoverable |
| `test/drift/generated/` | `schema.dart` (`GeneratedHelper`) and `schema_v<N>.dart` (per-version data classes and companions) |

### 5.3 The details that are easy to get wrong

- **`git diff --exit-code` cannot see a file that was never added.** This is the hole, and it is the
  one that matters. Bump `kSchemaVersion` to 2, run `make gen`, forget to `git add
  drift_schemas/drift_schema_v2.json`, push: the new file is **untracked**, a plain `git diff` is
  clean, the job is green, and the repository now has a schema no snapshot describes — which is
  exactly the state `04 §2.10` lists as an anti-pattern. `13 §4.3` as published has this hole.
  Close it with `git add -A` over the three paths followed by `git diff --cached --exit-code`, or
  with an equivalent `git status --porcelain` assertion. Say in the step's comment which failure it
  closes, or someone will "simplify" it back.
- **The diff path is `lib/`, not `lib/core/db/`.** `04 §3.6` writes `lib/core/db/`; `13 §4.3`,
  `13 §4.2` and `00-README` §7.3 all write `lib/`. Take the broader one: `lib/l10n/app_localizations*.dart`
  is generated and committed (`00-README` §7.1) and sits outside `lib/core/db/`, so the narrow path
  merges a stale localisation file without complaint. Do not "correct" it to match 04 — 04 is the
  one that is behind, and CI is `13`'s document.
- **`codegen` does not install `libsqlite3-dev`, and that is deliberate.** `13 §4.2`'s table gives
  the host-sqlite3 line to `test` alone, because `flutter test` runs on the host and `codegen` runs
  no tests. If `make-migrations` turns out to need the engine on a bare runner, the fix is one
  `apt-get` line in this job — not moving the diff into `test`, where it would be one failure among
  hundreds instead of a job whose name is the diagnosis.
- **`needs: gate` is not `needs: [gate, test]`.** `13 §4.3` runs `codegen` and `test` in parallel
  behind `gate`, so a stale artefact and a red test surface in the same minute rather than in
  series. Adding a dependency here costs wall-clock time on every push and buys nothing.
- **The action versions are read, not remembered.** `actions/checkout` v7.0.1,
  `subosito/flutter-action` **v2.23.0 on the v2 major tag — there is no v3**. `13 §4.3` states this
  and states that these are **not** covered by decision-record §5, which is a pub.dev table.
  Re-verify before the first run; anyone who tells you `flutter-action@v3` exists is remembering.
- **`FLUTTER_VERSION` comes from the workflow-level `env:` block that already exists.** Do not add a
  second one to the job. The version lives in exactly four places — `.fvmrc` and one `env:` per
  workflow — and the assert in `gate` is what makes four safe (`13 §1.1`).
- **The policy test parses text, and adds no dependency.** `package:yaml` is not in decision-record
  §5, and §5 is the only source of a dependency in this project — adding it means an allowlist line
  and a G2 conversation. `test/policy/ci_jobs_test.dart` already reads `.github/workflows/ci.yml`
  as a string; follow what N01-T06 did rather than introducing a second style in the same file.
- **This job is why "regenerate in a follow-up commit" stops being possible.** `04 §2.1` rule 5 and
  `00-README` §7.4 both say a schema change lands as one commit: `kSchemaVersion`, the step, the
  snapshot and the helpers together or not at all. Nothing enforces that except this job. When you
  write the step's comment, write that sentence.
- **Watch it fail before you trust it.** The DoD line is *"watched once"*, and it means two
  different reds: an **edited** committed generated file, and an **untracked** newly generated one.
  A job that catches only the first is the job `13 §4.3` shipped.
- **Nothing here is time-shaped.** No instant, no civil date, no `appNow()` — no ambiguous-hour case
  in this task.

### 5.4 The test set

`test/policy/ci_jobs_test.dart` — extended, not replaced. The existing N01-T06 case stays green.

| Case | Asserts |
|---|---|
| `'ci.yml declares a blocking codegen job that diffs lib/, drift_schemas/ and test/drift/generated/'` | **anchor.** A job named `codegen` exists; it runs on `ubuntu-latest`; it is not `continue-on-error`; it runs both generator commands; and all three paths appear in the diff step. |
| `'the codegen job runs on every push and every pull request'` | it inherits the workflow-level `on:` block and is not gated behind a path filter, a tag condition or a manual dispatch |
| `'the staleness step fails on an untracked generated file'` | the step's command includes the index-aware form, not a bare `git diff --exit-code`. This is the hole in §5.3 held as an assertion rather than as a comment. |
| `'the codegen job needs gate and nothing else'` | `needs: gate` exactly — the parallel shape `13 §4.2` specifies |
| `'the job uses the pinned action versions and the workflow-level FLUTTER_VERSION'` | `actions/checkout@v7`, `subosito/flutter-action@v2`, and no second `env:` block declaring a Flutter version |
| `'every job named in 13 §4.2 that exists today is declared'` | the inventory: `gate`, `codegen`, `test`. `android` is N31's and is asserted absent-with-a-reason, so its arrival is a deliberate edit here rather than a silent gap. |

### 5.5 Verification, in order

```bash
make gen                                        # regenerate locally, exactly as CI will
git status --porcelain                          # MUST be empty — catches untracked, which git diff does not
git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/
fvm flutter test test/policy/ci_jobs_test.dart
make check
make test
```

Then watch it go red, twice, on a scratch branch, and revert each:

1. **Edited artefact.** Append a blank line to `lib/core/db/database.g.dart`, commit, push. The
   `codegen` job must fail on the diff step with the `::error::` annotation.
2. **Untracked artefact.** `git rm --cached test/drift/generated/schema_v1.dart`, commit, push.
   Regeneration recreates the file as untracked; a bare `git diff --exit-code` stays green and the
   index-aware form goes red. If your job passes this one, you have the wrong command.

## 6. Constraints that bind this task

- **Generated files are never hand-edited** (`00-README` §7.3). This job is what makes that
  enforceable rather than aspirational.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'ci.yml declares a blocking codegen job that diffs lib/, drift_schemas/ and test/drift/generated/'` passes, and was seen to fail first for the stated reason
- [ ] the job is blocking
- [ ] all three paths are diffed
- [ ] a deliberately stale generated file turns the job red — watched once
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
make gen
git status --porcelain
git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/
fvm flutter test test/policy/ci_jobs_test.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `ci: the codegen job — regenerate and refuse any diff`

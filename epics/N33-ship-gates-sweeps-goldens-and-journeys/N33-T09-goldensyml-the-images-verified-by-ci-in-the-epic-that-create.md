# N33-T09 — `goldens.yml` — the images verified by CI in the epic that created them

| | |
|---|---|
| **Epic** | [N33 — Ship gates: the sweeps, the matrix, the goldens and the journeys](epic.md) · `00-README` §9 step cross-cutting, before 12 |
| **Task** | 9 of 9 |
| **Depends on** | N33-T08 |
| **Commit** | one commit · `ci: goldens.yml, on tags and dispatch only` |

## 1. Why this task exists

macOS, on a tag or manual dispatch only — never a per-PR gate, because the macOS runner
bills at a 10× multiplier and a per-push job burns the free monthly quota in a week. Moved here from the
release epic so the eight images are verified by CI **in the epic that creates them**, not two epics
later.

The critique's ruling is one line: E28 *"generates eight PNGs that nothing in CI verifies until E30-T06
adds `goldens.yml`. Move the workflow into this epic."* Eight binary artefacts with no machine looking
at them for two epics is eight artefacts nobody would notice going stale.

This task also lands T07's finding: **the golden job must pin a time zone.** `13 §4.5`'s published
workflow sets none, the GitHub runner is UTC, and every image in this app carries a local time.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | **§4.5** (`goldens.yml`, printed verbatim — the file this task lands, plus the `TZ` line it lacks) · **§4.2** (the job table: `goldens` · tag `v*` **or** `workflow_dispatch` · `macos-latest` · *"Yes when it runs"*) · **§4.1** (the macOS budget arithmetic) · **§1.1** (the toolchain pin lives in `.fvmrc` plus one `env:` block per workflow — four places — and *"`goldens.yml` is the one people forget, because it is the only macOS job and the only one that never runs on a PR"*) · §1.3 (the `Makefile`'s two golden targets) · §4.6 (the CI anti-patterns) | the workflow, its triggers, its runner and its assert |
| `docs/engineering/12-testing.md` | **§8.4** (the five rules that pin OS and font sensitivity — one runner, one OS, one exact version; tagged and excluded from the fast job; not a per-PR gate; `--update-goldens` never on CI; `failures/` is an artefact) · §8.5 (the re-baselining ritual) · §11.2 (`dart_test.yaml`, the declared tags, and the **`-P` versus `--tags` dispute**) · §11.4 (the two Makefile targets) | what the job may and may not run |
| `docs/research/00-tech-decisions.md` | §5 only for versions · **#116** (goldens are **not** a per-PR gate; a tag-triggered or manually dispatched macOS job plus `make goldens` locally before tagging) · #121 (the CI shape) · #119 (coverage is reported, never gated) | the decision that fixes the triggers |
| `docs/engineering/00-README.md` | §7.4 (*"the golden job runs on `v*` or manual dispatch"*) · §9 step 1 (*"prove each rule fires once — plant a violation, confirm the failure, delete the file"*) | the discipline this task applies to a workflow |
| `docs/engineering/CONVENTIONS.md` | §4.1 (`lower_snake` for the names outside the Dart tree) · §1 · §5 | **BINDING** on the file name |
| `epics/N01-.../N01-T06` | §5.4 (`test/policy/ci_jobs_test.dart`'s seven cases, including *"every job that installs Flutter asserts the pin against `.fvmrc`"* — written to stay true *"when N33 and N34 add two more workflows"*) | the test file this task extends, and the case that was written for it |
| `epics/00-PLAN-CRITIQUE.md` | §5 E28 · §5 E30 · §11.2 N33 T09 | why the workflow moved into this epic |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-goldens-rebaseline` | runbook, invoked by name — it owns the workflow's ritual |
| `shed-dependencies-and-toolchain` | the CI job matrix and the runner cost rule |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/ci_jobs_test.dart`
- **Test** — `'goldens.yml runs on tags and workflow_dispatch only, never on push or pull_request'`
- **Why it is red today** — the eight images exist and nothing in CI ever verifies them.

```bash
fvm flutter test test/policy/ci_jobs_test.dart   # expect: failing, for the reason above
```

Sharpen it so it fails on the shape that costs money rather than on the file's absence. Assert three
things separately: that `on:` has a `push:` key whose **only** child is `tags: ['v*']` — a `branches:`
key alongside it is ORed, not ANDed, and turns the job into a per-push macOS build; that
`workflow_dispatch` is a **top-level** key of `on:` — misindented under `push:` it silently never
registers and the manual button never appears; and that `pull_request` appears nowhere. Each gets its
own `reason:` naming the consequence, because *"the triggers are wrong"* does not tell you which of the
three it was.

**Green.** The minimum code that passes, and nothing beyond it — the workflow, its trigger list, and the policy assertion.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No `lib/` layer is reached.** One workflow, one `Makefile` edit, one test file extended, one document
amendment — say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `.github/workflows/goldens.yml` | **New.** `13 §4.5` verbatim, plus the `TZ=Europe/London` on the test step that T07's zone case proved is load-bearing. `lower_snake`, per `CONVENTIONS §4.1`, and `13`'s own name list |
| 2 | `Makefile` | **Edit.** `goldens` and `goldens-update` both gain `TZ=Europe/London`. If CI pins the zone and the developer's machine does not, the first local re-baseline after this commit moves all eight images |
| 3 | `test/policy/ci_jobs_test.dart` | **Edit.** The anchor plus the six cases below. N01-T06 wrote *"every job that installs Flutter asserts the pin against `.fvmrc`"* over `ci.yml` and said in as many words that it stays true *"when N33 and N34 add two more workflows"* — widen its file list here rather than writing a second case |
| 4 | `docs/engineering/13-build-ci-release.md` §4.5 | **Amended, in this commit.** The printed workflow gains the `TZ` line and one sentence of reason. `13` owns the CI job matrix; a published workflow that differs from the committed one is the kind of drift that gets discovered during a release |

### 5.2 The signature

The workflow. Every line in the `on:` block has a consequence, so each carries its reason:

```yaml
# .github/workflows/goldens.yml
name: Goldens

on:
  push:
    tags: ['v*']            # NO `branches:` key. push.branches and push.tags are
                            # ORed, not ANDed — adding one makes this a per-push
                            # macOS build and burns the month's quota in a week.
  workflow_dispatch:        # TOP-LEVEL. Misindented under `push:` it silently
                            # never registers and the manual button never appears.
                            # There is deliberately no `pull_request:` (#116).

env:
  FLUTTER_VERSION: '3.44.8'   # must equal .fvmrc — asserted below. Never 'stable'.

jobs:
  goldens:
    runs-on: macos-latest        # 10x multiplier. This is why it is not per-PR.
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with: { channel: stable, flutter-version: '${{ env.FLUTTER_VERSION }}', cache: true }

      # 13 §1.1. This is the workflow where the pin matters MOST — a golden diff
      # caused by a Flutter version bump reads as a design regression, and the
      # developer spends an hour looking at the wrong thing.
      - name: Toolchain pin agrees with .fvmrc
        run: |
          PINNED=$(grep -o '"flutter": *"[^"]*"' .fvmrc | sed 's/.*"\([0-9][^"]*\)"/\1/')
          [ "$PINNED" = "$FLUTTER_VERSION" ] || { echo "::error::.fvmrc=$PINNED workflow=$FLUTTER_VERSION"; exit 1; }
          flutter --version | grep -q "Flutter $FLUTTER_VERSION"

      - run: flutter pub get

      # TZ is pinned because every one of the eight images carries a LOCAL time.
      # pumpApp pins the locale and atFixed pins the instant, but Instant.local
      # reads the PROCESS zone: a London re-baseline at 03:20 renders 02:20 on a
      # UTC runner and all eight images diff with no code change. (N33-T07.)
      - run: TZ=Europe/London flutter test -P ci-golden --reporter github

      # 13 §4.5 writes the path as a wide glob. Narrow it: LocalFileComparator
      # writes into `failures/` beside its basedir, and basedir is
      # test/features/ — the wide form matches nothing extra and hides where
      # the images actually land.
      - uses: actions/upload-artifact@v7
        if: failure()
        with: { name: golden-failures, path: test/features/failures/** }
```

### 5.3 The details that are easy to get wrong

- **The trigger block is the only irreversible thing in this task, and it is irreversible because it is
  billing.** GitHub bills macOS at a **10× multiplier**; the Free plan's 2,000 minutes is **200 macOS
  minutes a month**. An `on: push` with a `branches:` key, or an `on: pull_request`, burns the month in
  a week — and reverting the file does not give the minutes back. Read the block twice before you push.
- **`push.branches` and `push.tags` are ORed.** This is the specific mistake: adding
  `branches: [main]` "for safety" alongside `tags: ['v*']` does not narrow the trigger, it widens it to
  every push to `main`.
- **`workflow_dispatch` must be a top-level key of `on:`.** Indented one level too far it is parsed as
  a key of `push:`, the workflow still validates, and the **Run workflow** button never appears. You
  discover it the first time you want to dispatch, which is the day you needed it.
- **This is the workflow that forgets the pin assert.** `13 §1.1` says so by name: the version lives in
  `.fvmrc` plus one `env:` block per workflow — four places — and *"every workflow runs it, in the
  first job that installs Flutter. Within `ci.yml` that is `gate`, and every other job in the file
  `needs:` it… `release.yml` and `goldens.yml` have one job each and carry their own. A workflow that
  installs Flutter without it is the defect, and `goldens.yml` is the one people forget."*
- **`TZ=Europe/London` on the test step, and on both `Makefile` targets.** This is T07's finding and it
  lands here. Pinning it in only one of the two places is worse than pinning it in neither: the images
  then depend on who ran the command last.
- **The filter spelling must match the `Makefile` exactly.** `12 §11.2` carries an unresolved dispute:
  `flutter test` may not accept `-P`/`--preset` at all, in which case `-P ci-golden` becomes
  `--tags golden` everywhere. N01-T04's day-one check decided it; `ci_jobs_test.dart` already has a
  case asserting the `Makefile` and `ci.yml` spell the same filters, and this task extends that case to
  `goldens.yml`. Whichever way it landed, all three files say the same thing or none of them is
  written.
- **`--update-goldens` never runs on CI** (`12 §8.4` rule 4). Regeneration is a local, reviewed act. A
  `goldens.yml` that re-baselines is a workflow that agrees with every change you make.
- **`if: failure()` on the artefact upload, and the path is a glob.** `LocalFileComparator` writes four
  images per failure — master, test, isolated diff, masked diff — into `failures/` beside the test
  file, which makes review trivial. Without `if: failure()` the step fails every green run because
  there is nothing to upload.
- **"Yes when it runs" is not "required".** `13 §4.2` marks the job blocking **when it runs** — meaning
  no `continue-on-error` — but it must **never** be a required status check on pull requests, or every
  PR blocks forever on a job that was never triggered. That setting lives in branch protection, not in
  the file, so it goes in the PR body as a step someone has to take in the browser.
- **Watch it go red once.** `00-README` §9 step 1's discipline applied to a workflow: *"plant a
  violation, confirm the failure, delete the file."* Corrupt one committed PNG by 5 %, dispatch,
  download the `golden-failures` artefact, revert. This is the only workflow in the project that never
  runs on a PR, so it is the only one whose first real execution would otherwise be during a release.
- **`ci.yml` must not run the `golden` tag.** `12 §8.4` rule 2: `--exclude-tags golden` on
  `ubuntu-latest` every push, `--tags golden` on the macOS job. An untagged golden test would run in
  the fast job on Linux and fail on font rendering — the confusing failure T07's tag case prevents from
  the test side and this case prevents from the workflow side.
- **A tag that `dart_test.yaml` does not declare matches nothing and the run is green because it ran
  nothing** (`12 §11.2`). `golden` is declared at N01-T04; verify the count in the log rather than
  trusting the exit code. Eight tests, not "No tests ran".
- **`actions/checkout@v7`, `subosito/flutter-action@v2`, `actions/upload-artifact@v7`** — the versions
  `13 §4.3` and §4.5 use. Do not float them; a floating action version reproduces the toolchain-pin
  problem one layer up.

### 5.4 The full test set

| File · case | What it asserts |
|---|---|
| `test/policy/ci_jobs_test.dart` · `'goldens.yml runs on tags and workflow_dispatch only, never on push or pull_request'` | **The anchor.** `push:` has only a `tags: ['v*']` child; `workflow_dispatch` is top-level; `pull_request` appears nowhere — three assertions, three reasons |
| `…` · `'goldens.yml runs on macos-latest'` | The runner, by name. Decision #116's whole cost argument depends on it |
| `…` · `'every workflow that installs Flutter asserts the pin against .fvmrc'` | **Widened**, not duplicated. N01-T06 wrote this case for `ci.yml` and said it would cover N33's and N34's workflows; add `goldens.yml` to its file list |
| `…` · `'every workflow FLUTTER_VERSION equals the version in .fvmrc'` | The four-places problem, closed by a test that reads both. Now three workflows |
| `…` · `'no workflow passes --update-goldens'` | *edge.* `12 §8.4` rule 4, held by a machine rather than by memory |
| `…` · `'goldens.yml pins TZ=Europe/London on its test step'` | *edge.* T07's finding, asserted where it is easiest to lose |
| `…` · `'the Makefile's goldens targets pin the same zone as goldens.yml'` | *edge, `uk-zone`-shaped.* The two halves of one property, in two hand-maintained files. If they ever disagree, the images depend on who ran the command last — and the disagreement is invisible except on the clocks-change weekend, when a re-baseline in the ambiguous hour renders a different local time from the same instant |
| `…` · `'the Makefile and goldens.yml spell the same golden filter'` | *edge.* Extends N01-T06's existing filter-agreement case to the third file. `-P ci-golden` or `--tags golden`, whichever N01-T04 decided |
| `…` · `'ci.yml excludes the golden tag'` | *edge.* The other side: goldens never run on ubuntu |
| `…` · `'no job in goldens.yml carries continue-on-error'` | *edge.* `13 §4.6`: *"if it is not worth failing on, delete it"* |
| `…` · `'the failure artefact step is guarded by if: failure()'` | *edge.* Otherwise every green run fails on an empty upload |
| `…` · `'goldens.yml uses pinned action versions, not floating ones'` | *edge.* `@v7` / `@v2`, never `@main` |

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. The workflow's own network use — `actions/checkout`, the Flutter install, `pub get` — is build-machine network, which is a different claim from the shipped app's and the only kind permitted here.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'goldens.yml runs on tags and workflow_dispatch only, never on push or pull_request'` passes, and was seen to fail first for the stated reason
- [ ] triggers are `v*` tags and manual dispatch only
- [ ] the job runs on macOS
- [ ] a deliberately broken golden turns it red — watched once
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `push:` carries **no** `branches:` key, and `workflow_dispatch` is a top-level key of `on:`
- [ ] the workflow runs the three-line pin assert before `pub get`, and `ci_jobs_test.dart`'s existing pin case was **widened** rather than duplicated
- [ ] the test step and both `Makefile` golden targets pin `TZ=Europe/London`, and `13 §4.5` is amended to match
- [ ] `--update-goldens` appears in no workflow
- [ ] the failure artefact step is guarded by `if: failure()` and uploads `test/features/failures/**`
- [ ] `goldens.yml` is **not** added to branch protection's required checks — noted as a browser step in the PR body
- [ ] the dispatched run reported **eight** tests, not "No tests ran"
- [ ] the action versions are pinned

## 8. Verification

```bash
fvm flutter test test/policy/ci_jobs_test.dart
make check
make test
```

Then exercise the workflow, which is the only way to know it works — it never runs on a PR:

```bash
gh workflow run goldens.yml && gh run watch
gh run view --log --job goldens | grep -c "All tests passed"     # and check the test COUNT is 8
```

Watch it go red, once:

```bash
python3 - <<'PY'
# Corrupt ~5% of one image so the tolerance cannot absorb it.
p='test/features/goldens/quick_entry_default.png'
b=bytearray(open(p,'rb').read())
for i in range(len(b)//20, len(b)//20*2): b[i] ^= 0xFF
open(p,'wb').write(b)
PY
git add -A && git commit -m 'temp: break one golden' && git push
gh workflow run goldens.yml && gh run watch        # expect: FAIL
gh run download --name golden-failures             # expect: four images
git reset --hard HEAD~1 && git push --force-with-lease
```

```bash
grep -n "branches:" .github/workflows/goldens.yml       # expect zero
grep -n "pull_request" .github/workflows/goldens.yml    # expect zero
grep -rn "update-goldens" .github/workflows/            # expect zero
grep -n "TZ=Europe/London" .github/workflows/goldens.yml Makefile   # expect three hits
diff <(grep -A2 'goldens:' Makefile) <(grep -A2 'flutter test -P ci-golden' .github/workflows/goldens.yml) || true
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `ci: goldens.yml, on tags and dispatch only`

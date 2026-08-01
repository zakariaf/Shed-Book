# N01-T06 — `.github/workflows/ci.yml` — the `gate` and `test` jobs

| | |
|---|---|
| **Epic** | [N01 — The tree, the configs and the CI shell](epic.md) · `00-README` §9 step 1 |
| **Task** | 6 of 7 |
| **Depends on** | N01-T05 |
| **Commit** | one commit · `ci: gate and test jobs, blocking, on every push and pull request` |

## 1. Why this task exists

Two blocking jobs on every push and every pull request. `gate`: the toolchain pin agrees
with `.fvmrc`, `pub get`, `check_policy` (G2 + G3), `format --set-exit-if-changed`,
`analyze --fatal-infos --fatal-warnings`, and no `NSAppTransportSecurity`. `test`: **`libsqlite3-dev`
installed on the runner** (`12 §3.2`), `-P ci-fast` with randomised ordering,
`TZ=Europe/London --tags uk-zone`, and `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone`.
Coverage is uploaded as an artefact and never gated.

The previous plan created the `test` job in no task at all — critique gap G2 — which is why a job
that installs `libsqlite3-dev` on the runner, the *"one line between a working and a red CI on day
one"*, had no owner.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §4.2, §4.3 | the job matrix and `ci.yml` verbatim, including the action versions and their read dates |
| `docs/engineering/13-build-ci-release.md` | §1.1, §2.7 | the four places the toolchain version appears and the assert that makes it safe; G5's text half |
| `docs/engineering/12-testing.md` | §3.2, §2.5, §13, §14 A and B | `libsqlite3-dev`; the three commands; the unscoped zone step and the hostile step's exclusion |
| `docs/research/00-tech-decisions.md` | §5 #48, #119, #121, #126 | the hostile zone, coverage reported never gated, the CI shape |
| `epics/00-PLAN-CRITIQUE.md` | §9 change 4 | `test` here, `codegen` in N08, `android` in N31 — which is why this file has two jobs and not four |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-dependencies-and-toolchain` | the `gate` job is the toolchain contract executed |
| `shed-testing` | the `test` job's three commands and the runner's sqlite dependency are its subject |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/ci_jobs_test.dart`
- **Test** — `'ci.yml declares gate and test, both blocking, on push and pull_request'`
- **Why it is red today** — there is no workflow file, and the previous plan created the `test` job in no task at all — critique gap G2.

```bash
fvm flutter test test/policy/ci_jobs_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — author both jobs; the test reads the workflow as text and asserts the job names, the
trigger list, the `libsqlite3-dev` step, the three test commands and that the same filter spellings
appear in the `Makefile`.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No `lib/` layer is reached. One workflow file, one test.

| # | Path | What changes, and why |
|---|---|---|
| 1 | `.github/workflows/ci.yml` | new. 13 §4.3's `gate` and `test` jobs. `codegen` and `android` are deliberately absent — see §5.3 |
| 2 | `.github/dependabot.yml` | new, one ecosystem, `github-actions`, monthly. **Not** pointed at pub: a plugin bump can change the merged manifest or a privacy manifest, so pub updates go through `flutter pub outdated` read by a human, never a bot that opens a green PR |
| 3 | `test/policy/ci_jobs_test.dart` | the anchor, written first, carrying `@Tags(['policy'])` |

### 5.2 The workflow

13 §4.3 verbatim for the two jobs this task owns. Every comment in it is load-bearing and is kept.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
    tags: ['v*']
  pull_request:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

env:
  FLUTTER_VERSION: '3.44.8'   # must equal .fvmrc — asserted in the first step. Never 'stable'.

jobs:
  gate:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with: { channel: stable, flutter-version: '${{ env.FLUTTER_VERSION }}', cache: true }

      - name: Toolchain pin agrees with .fvmrc
        run: |
          PINNED=$(grep -o '"flutter": *"[^"]*"' .fvmrc | sed 's/.*"\([0-9][^"]*\)"/\1/')
          [ "$PINNED" = "$FLUTTER_VERSION" ] || { echo "::error::.fvmrc=$PINNED workflow=$FLUTTER_VERSION"; exit 1; }
          flutter --version | grep -q "Flutter $FLUTTER_VERSION"

      - run: flutter pub get

      # N03-T07 inserts the policy gate (G2 + G3) here, as the cheapest step,
      # in the commit that makes tool/check_policy.dart exist. See §5.3.

      - name: Format
        run: dart format --output=none --set-exit-if-changed .

      - name: Analyze
        run: flutter analyze --fatal-infos --fatal-warnings

      # G5, the half a text check can do.
      - name: iOS has no ATS exception
        run: |
          if grep -q NSAppTransportSecurity ios/Runner/Info.plist; then
            echo "::error::NSAppTransportSecurity must not appear in Info.plist"; exit 1
          fi

  test:
    runs-on: ubuntu-latest
    needs: gate
    timeout-minutes: 25
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with: { channel: stable, flutter-version: '${{ env.FLUTTER_VERSION }}', cache: true }

      # `flutter test` runs on the HOST, so sqlite3_flutter_libs (a plugin, and an
      # EOL no-op shim anyway) is never applied and the host must supply sqlite3.
      # This is the one line between a working and a red CI on day one.
      # 12-testing.md §3.2.
      - name: Host sqlite3
        run: sudo apt-get install -y libsqlite3-dev

      - run: flutter pub get

      - name: Test
        run: |
          flutter test -P ci-fast \
            --reporter github \
            --test-randomize-ordering-seed random \
            --coverage

      # NOT scoped to test/domain: 12 §2.4 puts two zone-pinned files in
      # test/data/ and test/features/, and a path scope would run them in the
      # runner's own zone (UTC), where a spring-forward test passes because
      # there is no spring forward.
      - name: Zone-pinned tests in the target zone
        run: TZ=Europe/London flutter test --tags uk-zone --reporter github

      # The hostile zone: +12:45/+13:45, a non-hour offset, DST in the southern
      # summer. Decision #48. uk-zone files are EXCLUDED: they assert the process
      # offset and fail loudly under any other zone, which is the behaviour 12
      # wants and would be a false red here.
      - name: Domain tests in a hostile zone
        run: TZ=Pacific/Chatham flutter test test/domain --exclude-tags uk-zone --reporter github

      # Coverage is REPORTED, never gated (#119).
      - uses: actions/upload-artifact@v7
        if: always()
        with: { name: coverage, path: coverage/lcov.info }
```

### 5.3 What is easy to get wrong here

- **This file has two jobs on purpose, and the other two are not forgotten.** 13 §4.2's matrix has
  four blocking jobs. `codegen` re-runs `build_runner` and `drift_dev make-migrations` and diffs —
  there is no `lib/core/db/database.dart` to generate from until N07, so it lands in **N08**.
  `android` builds a release AAB and runs G1 against `android/expected_permissions.txt`, which does
  not exist until G0 is closed — so it lands in **N31**. `00-PLAN-CRITIQUE` §9 change 4 is the
  ruling. Adding either now produces a job that is red for reasons no task in this epic can fix.
- **The `check_policy` step is N03-T07's, by name.** That epic's last task is *"wire the gate into
  CI"*. Leave the comment above in place so the insertion point is not a guess, and take the same
  option in the `Makefile` (N01-T05 §5.3) so the two files agree.
- **The job names become the required status checks.** Once branch protection requires `gate` and
  `test`, renaming a job in this file silently un-requires it and every subsequent PR goes green on
  nothing. Fix `gate` and `test` now; if a job must ever be renamed, update the protection rule in
  the same change.
- **`grep -q` exits 1 when the pattern is absent, and absent is the pass.** That is why the ATS check
  is written as an `if` block and not as `plutil -p … | grep -c … = 0` under `set -e` — the naive
  form fails the step on the *good* outcome. 13 §2.7 states the check both ways; only the `if` form
  is safe inside a workflow step.
- **The pin assert is copied verbatim into every workflow that installs Flutter, and deliberately
  not factored into a composite action** — a composite action would be a fifth place the version
  could hide. The version lives in exactly four: `.fvmrc` and one `env:` block per workflow. Inside
  `ci.yml`, `test` has `needs: gate`, so one assert covers the file. `release.yml` and `goldens.yml`
  arrive in N34 and N33 with one job each and carry their own — **`goldens.yml` is the one people
  forget**, because it is the only macOS job and the only one that never runs on a PR.
- **A push to this epic's branch triggers nothing.** The `push` trigger is scoped to `main` and
  `v*`; a topic branch runs CI only through `pull_request`. Open the pull request after the first
  commit, not after the last, or the first time you see this workflow run is the merge.
- **The zone step must have no path.** `TZ=Europe/London flutter test --tags uk-zone`. 12 §14
  amendment A: the two zone-pinned files 12 §2.4 adds later live in `test/data/` and
  `test/features/`, and a `test/domain` scope runs them under the runner's UTC, where they pass
  vacuously.
- **The hostile step must carry `--exclude-tags uk-zone`.** 12 §14 amendment B: without it the step
  is red on every single run, for the right reason — `test/domain/uk_zone/` asserts its own offset
  and fails loudly rather than skipping — and *"that is how a correct gate gets deleted"*.
- **A green zone step that ran nothing is the failure mode this epic already paid to avoid.**
  N01-T04 lands the tagged canary; assert here that the step's output does not read "No tests ran".
- **Action versions are not covered by decision-record §5**, which is a pub.dev table. 13 §4.3 read
  them off the GitHub API on stated dates: `actions/checkout` v7.0.1, `actions/upload-artifact`
  v7.0.1, `actions/setup-java` v5, and `subosito/flutter-action` **v2.23.0 on the v2 major tag —
  there is no v3**. Re-verify before the first run; anyone who tells you a v3 exists is remembering,
  not checking.
- **Coverage is an artefact and never a gate** (#119), and `if: always()` is what makes it upload
  from a failing run, which is the run you want it from.
- **Do not add a `codecov` or any other upload action.** It is a network call in a project whose
  central claim is that it makes none, and coverage that gates is coverage that gets gamed.
- **The host sqlite version floor is a real assertion and it is not this task's.**
  `test/data/host_sqlite_version_test.dart` (12 §3.2) pins `>= 3041000` so a
  Mac-passes-CI-fails split surfaces as a named failure rather than a mystery. It arrives with the
  drift harness in N07. If the assertion ever fails, the fix is the runner image, never the number.

### 5.4 The test set

`test/policy/ci_jobs_test.dart` — one file, seven cases, reading `.github/workflows/ci.yml` and
`Makefile` as text.

| Test | What it holds |
|---|---|
| `'ci.yml declares gate and test, both blocking, on push and pull_request'` | the anchor. Job names, triggers, and that neither carries `continue-on-error` |
| `'the test job installs libsqlite3-dev before it runs any test'` | 12 §3.2's one line, and its position — after the checkout, before the first `flutter test` |
| `'the zone-pinned step carries no path and the hostile step excludes uk-zone'` | 12 §14 amendments A and B, both directions, in one case |
| `'every job that installs Flutter asserts the pin against .fvmrc'` | true for this file today and the reason it stays true when N33 and N34 add two more workflows |
| `'the workflow FLUTTER_VERSION equals the version in .fvmrc'` | the four-places problem, closed by a test that reads both |
| `'the Makefile and ci.yml spell the same test filters'` | the two hand-maintained copies of one list. This is the case that fires when N01-T04's day-one check is applied to one file and not the other |
| `'coverage is uploaded with if always and no step gates on it'` | #119, in both directions |

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. The workflow's own network use — `actions/checkout`, the Flutter install, `apt-get`, `pub get` — is build-machine network, which is a different claim from the shipped app's, and it is the only kind permitted here.
- **G5, the half a text check can do** — `ios/Runner/Info.plist` must not contain `NSAppTransportSecurity`. The rest of G5 is construction plus observation and is honestly labelled as not mechanically enforced.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'ci.yml declares gate and test, both blocking, on push and pull_request'` passes, and was seen to fail first for the stated reason
- [ ] `gate` and `test` both run on `push` and `pull_request` and both are required
- [ ] the test runner installs `libsqlite3-dev`
- [ ] the third command runs the domain tier under `TZ=Pacific/Chatham`, proving the suite is not accidentally London-only
- [ ] coverage is an artefact, never a gate
- [ ] the `uk-zone` step's log shows a test count, not "No tests ran"
- [ ] branch protection requires exactly the two job names this file declares
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/ci_jobs_test.dart
git push
gh run watch
gh run view --log --job gate
gh run view --log --job test
```

Then push the branch and read the two job logs. A job that has never been watched to fail is indistinguishable from a broken job.

Make each one fail once, on purpose, and watch it: change `FLUTTER_VERSION` to `3.44.7` and confirm
the pin assert names both numbers; add `NSAppTransportSecurity` to `ios/Runner/Info.plist` and
confirm the ATS step exits 1; delete the `libsqlite3-dev` step and confirm the first `flutter test`
fails on a missing sqlite3 rather than on a test. Revert all three.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `ci: gate and test jobs, blocking, on every push and pull request`

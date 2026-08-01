# N31-T03 — `tool/assert_permissions.sh` (G1), the `android` job and the G4 archive

| | |
|---|---|
| **Epic** | [N31 — Platform artefacts, G1, G4 and G5](epic.md) · `00-README` §9 step 12 (1 of 3) |
| **Task** | 3 of 4 |
| **Depends on** | N31-T02 |
| **Commit** | one commit · `ci: G1 — assert the shipped permission set, and archive G4` |

## 1. Why this task exists

G1 executable: build the release AAB in CI, dump its merged manifest, and diff against
`expected_permissions.txt`. The G4 merger report is archived on every run, so the day a dependency adds
a permission there is a record of which one and when.

This is the fourth and last blocking job in `13 §4.2`'s matrix, and it is the only one in the
repository that reads a **built artefact** rather than source. That distinction is the whole design:
`13 §2.3` opens by saying G1 *"reads the built artefact, never the source manifest, because the source
manifest is not what ships — the merger blends in every library's manifest with no warning."* It also
asserts **exact set equality**, not the absence of `INTERNET`: *"the failure mode this gate exists for
is a plugin bump in month six quietly merging a new permission; a grep for one string cannot see that."*

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §2.3 | the script **printed in full**, its three exit codes, the `tr '<' '\n'` reason, and the `bundletool` fetch step |
| `docs/engineering/13-build-ci-release.md` | §2.6, §2.8 | G4 is diagnostic and non-blocking · the four named anti-patterns, including grepping `build/app/intermediates/` and `apkanalyzer` on an APK |
| `docs/engineering/13-build-ci-release.md` | §4.2, §4.3 | the job matrix row and the `android` job verbatim — `needs`, the runner, the build flags, the artefact list and the action versions with their read dates |
| `docs/engineering/13-build-ci-release.md` | §4.4, §9.1, §9.1.1 | `release.yml` calls the same script on a tag (N34) · the build-number rule · the two `--dart-define`s that must mirror the two build flags |
| `docs/engineering/13-build-ci-release.md` | §12 item 1 | reading the shipped permission list by hand stays a release-checklist item **even when G1 is green** |
| `docs/research/00-tech-decisions.md` | §3.2, §3.4 | G1's row, and why no gate may ever assert *"no `http` in `pubspec.lock`"* |
| `docs/engineering/12-testing.md` | §1.4, §10.2 | gate versus test; *"almost none of it"* belongs in `test/`, and G1 is a CI shell step owned by 13 |
| `epics/00-PLAN-CRITIQUE.md` | §9 change 4 | `test` in N01-T06, `codegen` in N08, `android` **here** |
| `epics/N01-.../N01-T06-...md` | §5.3, §5.4 | the insertion point left in `ci.yml`, the seven existing cases in `test/policy/ci_jobs_test.dart`, and the rule that job names become required status checks |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | the manifest assertion and the merger report |
| `shed-testing` | the job's place in the blocking set |
| `shed-release` | typed by name, never auto-firing; its description is the only one naming the offline gates G0 to G5 against a real release bundle |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/permission_set_test.dart`
- **Test** — `'expected_permissions.txt matches G0 exactly and contains no INTERNET'`
- **Why it is red today** — nothing checks the shipped permission set; the claim rests on a document.

```bash
fvm flutter test test/policy/permission_set_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the script, the blocking `android` job, and the archived report. The second `test()` in
this file asserts the *normalisation contract*: every uncommented line of `android/expected_permissions.txt`,
once its inline comment is stripped the way the script strips it, is a bare permission name with no
whitespace and no `#`; and `tool/assert_permissions.sh` performs that stripping, compares by set
equality rather than by substring, and exits `2` on each of the three "could not run" conditions.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step. `_expectedEntries()`
already exists in this file from N31-T01 and is reused unchanged — the new case must normalise
**exactly** as the shell does, or the Dart tier is asserting a contract the gate does not implement.

## 5. What you build

### 5.1 The files this task touches, in order

No layer is reached; say so in the commit message. The order is irreversibility order: the script that
can make a red build green first, the workflow that runs it second, the documents last.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `test/policy/permission_set_test.dart` | **Extended.** A second `test()` in the file N31-T01 created, plus the normalisation helper it shares with the script. One file, two properties |
| 2 | `tool/assert_permissions.sh` | **New.** `13 §2.3`'s script with the three corrections in §5.2. Zero dependencies beyond `bash`, `java` and the coreutils already on the runner |
| 3 | `.github/workflows/ci.yml` | **Edited.** The `android` job, `13 §4.3` verbatim, appended after `test`. `needs: [gate, codegen, test]`, `timeout-minutes: 30`, and the artefact upload with `if: always()` |
| 4 | `test/policy/ci_jobs_test.dart` | **Extended.** Three new cases for the fourth job, plus **one existing case whose scope must be corrected** — see §5.4 |
| 5 | `.gitignore` | **Edited.** The three files the script writes into the repository root: `merged-manifest.xml`, `actual-permissions.txt`, `expected-sorted.txt`. Each entry anchored with a leading solidus so it matches at the root and nowhere else |
| 6 | `docs/engineering/13-build-ci-release.md` | **Edited, §2.3.** The published script is amended with the three corrections. `00-README` §10's amendment rule applies to a shell script exactly as it applies to a decision: fix it where it is printed, in the same commit, or `release.yml` (N34) copies the broken form |

Nothing under `lib/`, nothing under `android/`, nothing under `ios/`.

### 5.2 The script

`13 §2.3`'s, with three corrections. The comments in the published form are load-bearing and are kept
verbatim; the corrected lines are marked.

```bash
#!/usr/bin/env bash
# tool/assert_permissions.sh — gate G1.
# Not a violation of decision #10 (one *source-scanning* gate): this reads a built
# artefact and needs the Android toolchain, so it can never live in check_policy.dart.
set -euo pipefail

AAB="${1:-build/app/outputs/bundle/release/app-release.aab}"
EXPECTED="android/expected_permissions.txt"
BUNDLETOOL="${BUNDLETOOL:-bundletool.jar}"

# CORRECTION 1 — the three exit-2 conditions §2.3 documents, all three implemented.
[ -f "$EXPECTED" ]   || { echo "::error::$EXPECTED is missing — gate G0 has not been closed."; exit 2; }
[ -f "$BUNDLETOOL" ] || { echo "::error::$BUNDLETOOL is missing — the gate could not run."; exit 2; }
[ -f "$AAB" ]        || { echo "::error::$AAB is missing — build the release bundle first."; exit 2; }

java -jar "$BUNDLETOOL" dump manifest --bundle "$AAB" > merged-manifest.xml

# Split on '<' and select the uses-permission elements, then read their android:name.
# Do NOT filter on the substring "permission": com.android.vending.BILLING does not
# contain it, and that is the one entry a careless filter would silently drop.
# The '^uses-permission' prefix also catches <uses-permission-sdk-23>, deliberately.
#
# CORRECTION 2 — `set -o pipefail` turns an empty grep into a silent death. Capture,
# then decide, so "no uses-permission elements at all" is a named failure and not a
# script that stops mid-pipe with no message.
tr '<' '\n' < merged-manifest.xml \
  | grep '^uses-permission' \
  | grep -o 'android:name="[^"]*"' \
  | sed 's/.*"\(.*\)"/\1/' | sort -u > actual-permissions.txt || true

[ -s actual-permissions.txt ] || {
  echo "::error::No uses-permission elements were read from $AAB."
  echo "Either the bundle is not what you think it is, or bundletool's dump format moved."
  exit 2; }

# CORRECTION 3 — strip the inline provenance comment before comparing.
# 13 §2.2 REQUIRES every line of the expected file to name its contributing library,
# so every line carries a trailing `# <library>`. Stripping only whole-line comments
# leaves that text on the line and diffs it against a bare permission name — which is
# red on the first run, for a reason that has nothing to do with permissions.
# Strip the comment, then the trailing whitespace, then drop the empties.
sed 's/#.*//' "$EXPECTED" | sed 's/[[:space:]]*$//' \
  | grep -v '^$' | sort -u > expected-sorted.txt

if ! diff -u expected-sorted.txt actual-permissions.txt; then
  echo "::error::The shipped bundle's permission set does not match $EXPECTED."
  echo "Lines starting '-' are missing; lines starting '+' were added by a dependency."
  echo "Find the contributor in build/app/outputs/logs/manifest-merger-release-report.txt (gate G4)."
  echo "Do NOT edit $EXPECTED to make this pass without understanding what changed."
  exit 1
fi
echo "G1 ok — permission set matches exactly."
```

Exit codes, unchanged from `13 §2.3`: **0** match · **1** set mismatch · **2** the gate could not run —
*"which is still a failure, never a skip."*

### 5.3 The `android` job

`13 §4.3`'s, appended to `.github/workflows/ci.yml` after the `test` job. N01-T06 left the file with
two jobs and named this one as N31's by number, so there is no insertion comment to find — it goes at
the end.

```yaml
  android:
    runs-on: ubuntu-latest
    needs: [gate, codegen, test]
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-java@v5
        with: { distribution: temurin, java-version: '17' }
      - uses: subosito/flutter-action@v2
        with: { channel: stable, flutter-version: '${{ env.FLUTTER_VERSION }}', cache: true }
      - run: flutter pub get

      - name: Build release bundle
        run: |
          flutter build appbundle --release \
            --build-number=${{ github.run_number }} \
            --dart-define=APP_VERSION=ci --dart-define=APP_BUILD=${{ github.run_number }} \
            --obfuscate --split-debug-info=build/symbols/android

      - name: Fetch bundletool
        run: curl -sSL -o bundletool.jar \
             https://github.com/google/bundletool/releases/latest/download/bundletool-all.jar

      - name: G1 — the shipped permission set is exactly the expected set
        run: bash tool/assert_permissions.sh

      - uses: actions/upload-artifact@v7
        if: always()
        with:
          name: android-${{ github.run_number }}
          path: |
            build/app/outputs/bundle/release/app-release.aab
            build/app/outputs/logs/manifest-merger-release-report.txt   # G4
            build/symbols/android
            merged-manifest.xml
```

`if: always()` on the upload is the entire mechanism of G4. The run you most want the merger report
from is the run where G1 just went red, and that is the run a default `if` skips.

### 5.4 The details that are easy to get wrong

- **The published script is red on its first run, and the reason is not permissions.** This is the
  headline. `13 §2.3` writes `grep -v '^\s*#' "$EXPECTED"`, which removes whole-line comments and
  leaves inline ones. Every line of `android/expected_permissions.txt` carries an inline comment,
  because `13 §2.2` requires every line to name its contributing library. So `expected-sorted.txt`
  holds `android.permission.VIBRATE                 # flutter_local_notifications (merged)` and
  `actual-permissions.txt` holds `android.permission.VIBRATE`, and `diff` reports fourteen changed
  lines on a bundle that is perfectly correct. **The instinctive fix — delete the comments from the
  expected file — deletes the provenance the file exists for**, and it is the fix a tired developer
  makes at the end of a long CI loop. Correct the script (correction 3), amend `13 §2.3` in the same
  commit, and say so in the commit message.
- **`set -o pipefail` plus `grep` is a silent exit.** If the dump contains no `uses-permission`
  element, `grep` exits 1, the pipeline exits 1, `set -e` kills the script, and the job log shows a
  failed step with no `::error::` line and no explanation. It fails **closed**, which is the right
  direction, but "the gate could not run" and "the permissions changed" are different diagnoses and
  the log must say which. Correction 2 makes it say so.
- **Only one of the three documented exit-2 conditions is implemented in the published form.** A
  missing `bundletool.jar` dies inside `java -jar` with exit 1, which the caller reads as *"the
  permission set changed"* — the single most misleading failure this gate can produce. Correction 1
  closes it.
- **`bundletool dump manifest` emits XML on very few lines.** A line-oriented `grep` over its raw
  output can appear to find nothing at all. `tr '<' '\n'` is not a stylistic preference; it is what
  makes the rest of the pipeline work, and it is the same reason `13 §2.2`'s manual procedure uses it.
- **Never filter on the substring `permission`.** `com.android.vending.BILLING` does not contain it,
  and it is the entry whose transitive Gradle graph must be re-reviewed on every Billing Library bump.
  The `^uses-permission` prefix match also catches `<uses-permission-sdk-23>` — deliberately, because
  a permission scoped to an API level is still a permission on the store listing.
- **Never grep `build/app/intermediates/`.** `13 §2.8`'s first named anti-pattern: that directory
  accumulates debug and profile artefacts, and Flutter's debug and profile manifests *do* declare
  `INTERNET`, so the grep fires on a stale directory and then gets deleted for being flaky. The
  second is `apkanalyzer` on an APK — the APK is not what ships. The third is `HttpOverrides.global`
  as a fourth proof. The fourth is editing the expected file to go green.
- **The script writes three files into the repository root** — `merged-manifest.xml`,
  `actual-permissions.txt`, `expected-sorted.txt`. The first is named in the job's artefact list, so
  it must stay at the root; all three must be gitignored or the next developer's `git status` is
  noise and one of them eventually gets committed. Anchor each entry with a leading solidus:
  `00-README` §7.2's `build/` rule is the standing example of an unanchored pattern matching a
  directory of that name at any depth, and N02-T01 already lost an afternoon to it.
- **One existing case in `test/policy/ci_jobs_test.dart` goes red when this job lands, and it is
  correct to change it.** N01-T06 wrote `'every job that installs Flutter asserts the pin against
  .fvmrc'`, and `13 §4.3`'s `android` job has no pin-assert step. N01-T06's own §5.3 gives the rule
  the case should have encoded: *"Inside `ci.yml`, `test` has `needs: gate`, so one assert covers the
  file."* The same is true of `android`, which needs `gate` transitively. **Re-scope the case to
  workflows, not jobs**, keeping the property that every workflow installing Flutter asserts the pin
  at least once, and state the reason in the commit message. Adding a redundant assert step to
  `android` instead would create a fifth place the version can hide, which is the thing N01-T06's pin
  discipline exists to prevent.
- **The job name becomes a required status check, and it cannot be required until it exists on
  `main`.** GitHub will not let you require a check it has never seen, so branch protection is
  updated **after** this epic merges, not in this commit. Put it on the PR body as a follow-up and
  verify on N32's first pull request that four checks are required. Renaming the job later silently
  un-requires it and every subsequent PR goes green on nothing.
- **`needs: [gate, codegen, test]` is not decoration.** It keeps a twenty-minute Gradle build from
  starting behind a formatting error, and it means `android` never runs at all on a PR where the
  cheaper jobs are red — so a red `android` in the checks list is always a real permission finding and
  never collateral.
- **The `--dart-define`s mirror the build flags and must not drift.** `13 §9.1.1`: `APP_VERSION` and
  `APP_BUILD` are compiled in because no package supplies them, and the deliberately wrong-looking
  defaults (`0.0.0+0`) are how a diagnostics log tells you somebody built without them. The per-push
  build passes `APP_VERSION=ci` on purpose — this AAB is never shipped (`13 §9.1` item 4), and a log
  line reading `ci+1284` should be unmistakable.
- **`bundletool` is fetched at `latest`, and `13 §2.3` carries that as unverified.** The gate's own
  tool floats. It has been stable for years and `dump manifest` is its oldest command, and a format
  change fails **closed** (exit 1 on a diff, or now exit 2 on an empty read). Record the version the
  job fetched in the PR body; pin only if it ever moves once.
- **This script is called from two workflows, and the second one does not exist yet.** `13 §4.4`'s
  `release.yml` runs G1 on a tag; N34 writes it. Keep the script's inputs positional and
  environment-overridable exactly as published, so N34 adds a caller and not a copy.
- **G1 being green does not retire the manual read.** `13 §12` item 1: *"Read the permission list
  yourself… Do not just trust that G1 was green."* That item exists because the gate proves the
  artefact matches the file, and a human is the only thing that proves the file is still the right
  file.

### 5.5 The full test set

Two files. Nothing here duplicates a `tool/check_policy.dart` rule — `12 §1.4` reserves source text
for the gate, and both of these read a workflow and a shell script, which the gate does not scan.

`test/policy/permission_set_test.dart` — the file N31-T01 created:

| Case | What it holds |
|---|---|
| `'expected_permissions.txt matches G0 exactly and contains no INTERNET'` | **the anchor.** Set equality against decision-record §3.3, and `INTERNET` absent as a real entry |
| `'every expected entry normalises to a bare permission name'` | correction 3's contract, from the Dart side: strip `#…`, strip trailing whitespace, and what is left matches `^[A-Za-z][A-Za-z0-9._]*$`. The case that fires if somebody puts a second `#` mid-line or a trailing tab in the file |
| `'assert_permissions.sh strips inline comments and compares by set equality'` | reads the script as text: it must contain the comment strip, must not contain a substring filter on `permission`, and must sort both sides |
| `'assert_permissions.sh exits 2 on each of its three could-not-run conditions'` | the three guards, by name. A gate that could not run *"is still a failure, never a skip"* |
| *edge* — the script is absent or not executable by `bash` | fails, never skips |

`test/policy/ci_jobs_test.dart` — N01-T06's file, extended:

| Case | What it holds |
|---|---|
| `'ci.yml declares android, blocking, needing gate codegen and test'` | the fourth job, its `needs` list, and no `continue-on-error` |
| `'the android job archives the merger report with if always'` | G4. The `if: always()` and the exact artefact path — the report is uploaded from the failed runs, which are the ones it is for |
| `'the android job passes APP_VERSION and APP_BUILD alongside build-number'` | `13 §9.1.1`'s mirror rule, asserted here so N34's `release.yml` inherits a tested shape |
| `'no workflow greps build/app/intermediates'` | `13 §2.8`'s first anti-pattern, held mechanically rather than remembered |
| `'every job that installs Flutter asserts the pin against .fvmrc'` | **re-scoped** to workflows — see §5.4. The property survives; the unit of the assertion changes, with the reason in the commit message |

**Nothing in this task is time-shaped.** The script computes no instant, the job formats no date, and
the two test files read text. No `test/domain/uk_zone/` case is added and none would mean anything —
the ambiguous **01:00–01:59** hour has no bearing on a permission set. The only clock in the vicinity
is `github.run_number`, which is a counter and not a time.

### 5.6 The drill — watched, then reverted

`00-README` §9 step 1: *"a rule nobody has seen fire is indistinguishable from a broken rule."* This
gate's entire value is the day it fires, in month six, on somebody else's plugin bump. Watch it fire
now, on this pull request, where the failure costs one CI run.

Locally first, because it costs nothing and the failure text is the thing you are checking:

```bash
# Add one line inside <manifest> in android/app/src/main/AndroidManifest.xml:
#   <uses-permission android:name="android.permission.CAMERA" />
fvm flutter build appbundle --release
bash tool/assert_permissions.sh ; echo "exit=$?"
git checkout -- android/app/src/main/AndroidManifest.xml
```

It must print `exit=1`, with `+android.permission.CAMERA` on a diff line and the four `::error::`
lines naming the merger report. Then do it once in CI, because a local pass proves the script and not
the job: commit the planted line on a throwaway commit, push, read the `android` job's log, then
`git reset --hard` back to T02's commit and re-do T03's commit properly. **The planted line never
reaches the merge** — `git log --oneline` on the branch must show exactly four commits before the PR
opens, and the PR body records that the drill was run and on which run number.

## 6. Constraints that bind this task

- **Offline** — no network path may be added to the app. The job's own network use (`checkout`, the Flutter install, `pub get`, the `bundletool` fetch) is **build-machine** network, which is a different claim from the shipped app's, and it is the only kind permitted here. Decision-record §3.4 #3 keeps that distinction explicit.
- **Never weaken a red gate to make a build green** (`CLAUDE.md`). If G1 goes red, the sequence is: read the G4 merger report, name the contributing library, decide whether that dependency stays. `android/expected_permissions.txt` changes last, never first, and never without a recorded reason.
- **No gate may assert *"no `http` in `pubspec.lock`"*** (decision-record §3.4 #1; `12 §10.2`). It is unsatisfiable — `http 1.6.0` sits on four load-bearing regular edges — and *"a gate that cannot pass gets deleted, and the real gates get deleted alongside it."*
- **G1 asserts set equality, never the absence of one string.** A grep for `INTERNET` cannot see the failure mode this gate exists for.
- **No CI step may fix rather than report** (`13 §4.6`). No auto-format commit, no bot that regenerates and pushes, no `continue-on-error: true`. *"If it is not worth failing on, delete it."*
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'expected_permissions.txt matches G0 exactly and contains no INTERNET'` passes, and was seen to fail first for the stated reason
- [ ] the `android` job is blocking
- [ ] a planted extra permission turns it red — watched once
- [ ] the merger report is archived on every run
- [ ] the script exits non-zero with the differing permission named
- [ ] the script strips inline comments, and `13 §2.3`'s published form was amended in the same commit
- [ ] all three "could not run" conditions exit `2` with an `::error::` line
- [ ] the three files the script writes are gitignored with anchored patterns
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/permission_set_test.dart
fvm flutter test test/policy/ci_jobs_test.dart
fvm flutter build appbundle --release
bash tool/assert_permissions.sh
make check
```

The fourth command must print `G1 ok — permission set matches exactly.` Then prove each failure mode
locally, in order, and watch the exit code:

```bash
bash tool/assert_permissions.sh /no/such/bundle.aab ; echo "exit=$?"   # exit=2, named
BUNDLETOOL=missing.jar bash tool/assert_permissions.sh ; echo "exit=$?" # exit=2, named
git status --short                                                     # must be clean
```

Then push and read the job log:

```bash
git push
gh run watch
gh run view --log --job android
```

The log must show the build, the `bundletool` fetch with the version it resolved, `G1 ok`, and the
artefact upload. Download the artefact once and open
`manifest-merger-release-report.txt` yourself, top to bottom — `13 §12` item 1 makes that a permanent
release-checklist item, and this is the run where you learn what it looks like.

Finally, the drill in §5.6: plant a permission, watch the job go red naming it, revert.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `ci: G1 — assert the shipped permission set, and archive G4`

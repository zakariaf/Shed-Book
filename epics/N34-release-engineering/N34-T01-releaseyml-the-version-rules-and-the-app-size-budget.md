# N34-T01 — `release.yml`, the version rules and the app-size budget

| | |
|---|---|
| **Epic** | [N34 — Release engineering](epic.md) · `00-README` §9 step 12 (3 of 3) |
| **Task** | 1 of 4 |
| **Depends on** | N33-T09 |
| **Commit** | one commit · `ci: release.yml on v* tags, with the app-size budget` |

## 1. Why this task exists

The release workflow on tag `v*`, with `--analyze-size` and the app-size budget — plus the
version-name and build-number rules recorded in `RELEASES.md` as the one place both live: the build
name is bumped by hand in the tag, the build number is always the CI run number, and both stores reject
a re-used one.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §4.4 | `release.yml` verbatim — the trigger, the keystore step, the two builds, G1, the size analysis and the artefact list |
| `docs/engineering/13-build-ci-release.md` | §6.1, §6.1.1 | the size reframing (#127), the one tracked number, and the narrowing of #126 that makes size measured and archived but gated on nothing |
| `docs/engineering/13-build-ci-release.md` | §9.1, §9.1.1, §9.4 | build name from the tag, build number from `github.run_number`, the two `--dart-define`s, `RELEASES.md`'s shape, and the artefacts a solo developer must keep |
| `docs/engineering/13-build-ci-release.md` | §1.1 | the pin assert, copied verbatim into the third workflow |
| `docs/engineering/00-README.md` | §7.4 | tags, build numbers and the never-tag window |
| `docs/research/00-tech-decisions.md` | §5, #126, #127 | the pinned versions the release build must reproduce; CI gates size, not speed |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-release` | runbook, invoked by name — the workflow, the tags and the numbering |
| `shed-dependencies-and-toolchain` | the size budget and the analyzer flags |
| `shed-platform-gateways` | the Gradle signing seam the keystore step writes into, and G1 on the artefact |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/release_config_test.dart`
- **Test** — `'release.yml triggers on v* only and RELEASES.md records the version rules'`
- **Why it is red today** — there is no release workflow, and the numbering rules live nowhere.

```bash
fvm flutter test test/policy/release_config_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the workflow, `RELEASES.md`, the budget, and the policy assertion. The assertion reads
`.github/workflows/release.yml` as text and holds four things at once: the only trigger is
`push: tags: ['v*']` and there is no `pull_request` and no `workflow_dispatch`; `BUILD_NAME` is derived
from `GITHUB_REF_NAME` and `BUILD_NUMBER` from `github.run_number`; every build command carries both
`--dart-define`s beside their matching `--build-*` flag; and `RELEASES.md` states both numbering rules
and has a header line naming the application id.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No `lib/` layer is reached — no schema, no domain, no data, no wiring, no controller, no UI, no ARB.
Say so in the commit body. Three files.

| # | Path | What changes, and why |
|---|---|---|
| 1 | `.github/workflows/release.yml` | **new.** 13 §4.4, with two deliberate holes left for the next two commits: the obfuscation flags and `build/symbols/android` in the upload list are **N34-T02**'s, and the freeze step is **N34-T04**'s. Both insertion points carry a named comment so they are not a guess — the same pattern N01-T06 used for the `check_policy` step |
| 2 | `RELEASES.md` | **new**, at the repository root (13's preamble names it; it is outside `CONVENTIONS §1`'s Dart tree). Header line records the application id / bundle id, read out of `android/app/build.gradle.kts`. One table, one row per tag |
| 3 | `test/policy/release_config_test.dart` | the anchor, written first, carrying `@Tags(['policy'])`. N34-T02 extends this same file; do not create a second one |

`pubspec.yaml`'s `version:` is **not** touched here. It is a local default with no authority over a
store artefact (§5.3), and it is bumped in the commit you tag, not in this one.

### 5.2 The workflow

13 §4.4 verbatim for everything this task owns. Every comment in it is load-bearing and is kept.

```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    tags: ['v*']

# No `concurrency:` block, and that is deliberate. ci.yml has one with
# cancel-in-progress: true (13 §4.3); cancelling a release build half way
# through is not a thing anybody wants. Copy the difference on purpose.

env:
  FLUTTER_VERSION: '3.44.8'   # must equal .fvmrc — asserted below. Never 'stable'.

jobs:
  aab:
    runs-on: ubuntu-latest
    timeout-minutes: 35        # two full release builds in one job
    steps:
      # N34-T04 inserts the seasonal freeze check HERE, as the first step,
      # before the checkout. 13 §11.

      - uses: actions/checkout@v7
      - uses: actions/setup-java@v5
        with: { distribution: temurin, java-version: '17' }
      - uses: subosito/flutter-action@v2
        with: { channel: stable, flutter-version: '${{ env.FLUTTER_VERSION }}', cache: true }

      # §1.1: every workflow that installs Flutter re-asserts the pin. Verbatim,
      # and deliberately not factored into a composite action — that would be a
      # fifth place the version could hide.
      - name: Toolchain pin agrees with .fvmrc
        run: |
          PINNED=$(grep -o '"flutter": *"[^"]*"' .fvmrc | sed 's/.*"\([0-9][^"]*\)"/\1/')
          [ "$PINNED" = "$FLUTTER_VERSION" ] || { echo "::error::.fvmrc=$PINNED workflow=$FLUTTER_VERSION"; exit 1; }
          flutter --version | grep -q "Flutter $FLUTTER_VERSION"

      - run: flutter pub get

      - name: Write the upload keystore
        env:
          KEYSTORE_B64: ${{ secrets.SHEDBOOK_KEYSTORE_BASE64 }}
        run: |
          echo "$KEYSTORE_B64" | base64 --decode > android/upload-keystore.jks
          cat > android/key.properties <<EOF
          storeFile=upload-keystore.jks
          storePassword=${{ secrets.SHEDBOOK_KEYSTORE_PASSWORD }}
          keyAlias=${{ secrets.SHEDBOOK_KEY_ALIAS }}
          keyPassword=${{ secrets.SHEDBOOK_KEY_PASSWORD }}
          EOF

      - name: Build name comes from the tag; build number from this workflow's run
        run: |
          NAME="${GITHUB_REF_NAME#v}"
          echo "BUILD_NAME=$NAME"     >> "$GITHUB_ENV"
          echo "BUILD_NUMBER=${{ github.run_number }}" >> "$GITHUB_ENV"

      # N34-T02 adds --obfuscate --split-debug-info=build/symbols/android here.
      - run: |
          flutter build appbundle --release \
            --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER" \
            --dart-define=APP_VERSION="$BUILD_NAME" --dart-define=APP_BUILD="$BUILD_NUMBER"

      - name: Fetch bundletool
        run: curl -sSL -o bundletool.jar \
             https://github.com/google/bundletool/releases/latest/download/bundletool-all.jar
      - name: G1
        run: bash tool/assert_permissions.sh

      # Size analysis is a SEPARATE, single-ABI build, so it only runs on a tag.
      # The command prints the path of the JSON it wrote — collect it from the
      # output rather than assuming a location, because that path has moved before.
      # N34-T02 adds --split-debug-info=build/symbols/android-size here.
      - name: Size analysis
        run: |
          flutter build appbundle --release --analyze-size \
            --target-platform android-arm64 \
            --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER" \
            | tee size.log
          SIZE_JSON=$(grep -o '[^ ]*code-size-analysis[^ ]*\.json' size.log | tail -1)
          [ -n "$SIZE_JSON" ] || { echo "::error::no size-analysis JSON was written"; exit 1; }
          mkdir -p build/size && cp "$SIZE_JSON" build/size/

      # N34-T02 adds build/symbols/android to this list.
      - uses: actions/upload-artifact@v7
        with:
          name: release-${{ github.ref_name }}-build-${{ github.run_number }}
          path: |
            build/app/outputs/bundle/release/app-release.aab
            build/app/outputs/logs/manifest-merger-release-report.txt
            merged-manifest.xml
            build/size/
```

### 5.3 The version rules, and the two constants they feed

`pubspec.yaml`'s `version: <build-name>+<build-number>` maps to `versionName`/`versionCode` on Android
and `CFBundleShortVersionString`/`CFBundleVersion` on iOS — and **neither half of it is what ships**.

| Rule | Spelling |
|---|---|
| The build name comes from the tag, always | `NAME="${GITHUB_REF_NAME#v}"` — strips exactly one leading `v` |
| The build number is always this workflow's run number | `--build-number=${{ github.run_number }}` |
| The running app learns both through `--dart-define`, not a package | `--dart-define=APP_VERSION="$BUILD_NAME" --dart-define=APP_BUILD="$BUILD_NUMBER"` |
| `pubspec.yaml`'s `version:` is a local default | bumped by hand in the commit you tag; if it disagrees with the tag, **the tag wins and the artefact is correct** — fix the pubspec, never re-tag |

The two defines land in constants that already exist from N11 (13 §9.1.1) — this task's job is to feed
them, not to author them:

```dart
// lib/core/log/local_log.dart — const, so it is tree-shaken into a literal.
const kAppVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.0.0');
const kAppBuild   = int.fromEnvironment('APP_BUILD', defaultValue: 0);
```

The defaults are deliberately wrong-looking. A diagnostics log reading `0.0.0+0` tells you instantly
that somebody built without the defines, which is better than a log that quietly reports a plausible
lie. **There is no package that supplies the version.** `package_info_plus` is in the graph only
transitively, via `wakelock_plus`; reading a transitive package from `lib/` is exactly the unreviewed
edge G2 exists to prevent, and adding it as a direct dependency to solve this trades a real
offline-graph review for a convenience.

`RELEASES.md`:

```markdown
# Releases — Shed Book
Application id / bundle id: <read out of android/app/build.gradle.kts and the Xcode target>

| Tag | Build number | Android uploaded | iOS uploaded | AAB arm64 download | Notes |
|---|---|---|---|---|---|
| v1.0.0 | 187 | | | | first release |
```

### 5.4 What is easy to get wrong here

- **"The budget is asserted" does not mean a byte threshold, and writing one is the specific mistake
  13 §6.1.1 forbids.** CI **measures and archives** size on every tag and **gates nothing** on it. The
  number worth gating — arm64 *download* size from the Play Console's App Bundle Explorer — does not
  exist until after upload, so no CI job can read it. The number CI *can* read, the `--analyze-size`
  total, has no baseline, so any threshold committed today is a guess that gets edited the first time
  it fires, *"which is the definition of a gate nobody trusts."* The assertion in this task is on the
  **workflow**: the step exists, it fails loudly when no JSON was written, and the JSON is uploaded.
  The byte gate arrives at release **two**, as a 5%-growth check against the previous tag's archived
  JSON.
- **"Under 20 MB, per spec §11" is decision #127's reframing, not spec §11 read literally.** Spec §11's
  sentence is about *bundled content* and cannot be read as a promise about install size. What is
  actually promised: bundled assets — fonts, `assets/content/`, icons — **under 5 MB**; AAB arm64
  **download** target **under 20 MB**; iOS **install** size *"plausibly 25–45 MB and not promised
  anywhere user-facing."* Putting an install-size figure in a store listing, a README or a forum post
  is a claim the project cannot keep.
- **`--analyze-size` cannot run on a multi-ABI bundle.** That is the whole reason the workflow builds
  twice — once for the shippable AAB and once, single-ABI, for the number. It is also why size analysis
  only ever runs on a tag: it doubles the job.
- **Do not assume where the size JSON lands.** That path has moved between Flutter versions. `tee` the
  build output, `grep -o '[^ ]*code-size-analysis[^ ]*\.json'`, take the last match, and **fail if it
  is empty** — otherwise a silent path change turns into an empty `build/size/` that nobody notices
  until the release after, when there is nothing to diff against.
- **`github.run_number` is per workflow, not per repository.** `ci.yml`'s `android` job and
  `release.yml` have separate counters, so a per-push AAB and a release AAB can carry the same or a
  descending build number. **Only `release.yml`'s artefact is ever uploaded to a store.** The per-push
  AAB exists to run G1 and is never shipped.
- **A re-used build number is rejected by both stores, and re-tagging is not the fix.** After a failed
  upload you push a *new* tag, which gets a new run number. Hand-editing a build number, re-using one,
  and re-tagging to fix a pubspec typo are all named anti-patterns in 13 §9.1.
- **This workflow never runs on the pull request that creates it.** Its only trigger is a `v*` tag —
  and `tags: ['v*']` also matches `v0.0.1` and `v1.0.0-rc1`, so **there is no rehearsal tag**. `§8`
  below runs the same two build commands on your desk; that is the rehearsal.
- **A tag also triggers `ci.yml` and `goldens.yml`.** `ci.yml`'s `push` trigger includes `tags: ['v*']`
  and `goldens.yml` (N33-T09) runs on `v*`. One tag, three workflows, three separate `run_number`
  sequences.
- **The pin assert is copied in verbatim, not factored out.** This file is the **third** `env:` block
  carrying `3.44.8`; with `.fvmrc` that is four places, and four is one more than anybody wants. A
  composite action would be a fifth. `release.yml` has one job, so it carries its own assert — unlike
  `ci.yml`, where `test` `needs: gate` and one assert covers the file.
- **Action versions are not covered by decision-record §5**, which is a pub.dev table. 13 §4.4 read
  them off the GitHub API on stated dates: `actions/checkout` v7.0.1, `actions/setup-java` v5,
  `actions/upload-artifact` v7.0.1, and `subosito/flutter-action` **v2.23.0 on the v2 major tag — there
  is no v3**. Re-verify before the first run; anyone who tells you a v3 exists is remembering, not
  checking.
- **The four keystore secrets are N32-T01's and a missing one fails obscurely.** `base64 --decode` on
  an empty secret writes a zero-byte `upload-keystore.jks` and Gradle then fails with a message that
  names neither the secret nor the step. The names are exact:
  `SHEDBOOK_KEYSTORE_BASE64`, `SHEDBOOK_KEYSTORE_PASSWORD`, `SHEDBOOK_KEY_ALIAS`,
  `SHEDBOOK_KEY_PASSWORD`. `android/key.properties` is git-ignored and is written here as a heredoc.
- **`curl`ing bundletool is build-machine network and is not a violation.** The offline claim is about
  the shipped app, not the runner (13 §2.1's three tiers). Do not "fix" it by vendoring a jar into the
  repository — that puts an unreviewable binary in git to solve a problem that does not exist.
- **No step in this workflow may rewrite source, and no job may be `continue-on-error`.** 13 §4.6:
  a step that *fixes* rather than *reports* is spec §12.4's "never silently correct" applied to the
  pipeline. No auto-format commit, no auto-`dart fix`, no bot that regenerates and pushes.
- **Nothing in this task reads a clock,** so it has no ambiguous-hour case. The release pipeline's only
  date read is the freeze check, and its DST cases live in N34-T04 where they belong. Do not add a
  time-shaped assertion here to satisfy a habit.

### 5.5 The test set

`test/policy/release_config_test.dart` — one file, `@Tags(['policy'])`, reading
`.github/workflows/release.yml`, `.github/workflows/ci.yml`, `.fvmrc` and `RELEASES.md` as text.
N34-T02 extends this same file.

| Test | What it holds |
|---|---|
| `'release.yml triggers on v* only and RELEASES.md records the version rules'` | the anchor. The trigger list is exactly `push: tags: ['v*']` — no `pull_request`, no `workflow_dispatch`, no branch push — and `RELEASES.md` states both numbering rules and carries a header line naming the application id |
| `'the build name is derived from the tag and the build number from github.run_number'` | both spellings, and that neither is a literal anywhere in the file |
| `'every build command in every workflow carries APP_VERSION and APP_BUILD beside build-name and build-number'` | 13 §9.1.1's named `test/policy/` assertion, run over **all three** workflows, not just this one. This is the case that fires when somebody adds a build command and forgets the defines, which produces a binary that logs `0.0.0+0` |
| `'the size analysis is a separate single-ABI build and its JSON is uploaded'` | `--analyze-size` appears exactly once, always with `--target-platform android-arm64`, and `build/size/` is in the artefact path list |
| `'the size step fails when no code-size-analysis JSON was written'` | the `[ -n "$SIZE_JSON" ]` guard is present. Assert on the guard, not on a byte count |
| `'no workflow asserts a size threshold or a startup latency'` | #126 and 13 §6.1.1's narrowing, held in the negative so nobody adds one "temporarily" |
| `'release.yml asserts the toolchain pin against .fvmrc, and all four places agree'` | reads `.fvmrc` and the `env:` block of each of the three workflows and compares all four to `3.44.8` |
| `'no job in release.yml is continue-on-error and no step rewrites source'` | 13 §4.6's anti-patterns, in the negative |
| `'the keystore step names all four secrets and android/key.properties is gitignored'` | the exact secret names, and `git check-ignore android/key.properties` succeeding |
| `'RELEASES.md has one row per tag and every row carries a tag and a build number'` | the table shape, so the file cannot decay into prose |

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. The workflow's own network use — `checkout`, the Flutter install, `pub get`, the bundletool fetch — is build-machine network, a different claim from the shipped app's, and it is the only kind permitted here. G1 runs inside this job on the artefact you would actually upload.
- **Nothing user-facing promises an install size.** #127's figures are internal targets; the only permitted public wording about the offline claim is 13 §2.1's paragraph, verbatim, and *"your data never leaves your phone"* is banned.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'release.yml triggers on v* only and RELEASES.md records the version rules'` passes, and was seen to fail first for the stated reason
- [ ] triggers on `v*` only
- [ ] `--analyze-size` runs and the budget is asserted
- [ ] `RELEASES.md` records both numbering rules and the current values
- [ ] the payload is under 20 MB, per spec §11
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/release_config_test.dart
make check
make test
```

Then rehearse the workflow's two build commands on your desk, because the workflow itself cannot run
on this branch and the first tag is the first time it ever executes:

```bash
# The shippable shape, multi-ABI. N34-T02 adds the obfuscation flags to this command.
fvm flutter build appbundle --release \
  --build-name=1.0.0 --build-number=0 \
  --dart-define=APP_VERSION=1.0.0 --dart-define=APP_BUILD=0

# The number, single-ABI, exactly as the workflow runs it.
fvm flutter build appbundle --release --analyze-size \
  --target-platform android-arm64 \
  --build-name=1.0.0 --build-number=0 | tee size.log
grep -o '[^ ]*code-size-analysis[^ ]*\.json' size.log | tail -1

# Read it the way you will read it at release two.
fvm dart devtools        # → Open app size tool → load the JSON

# G1 on the artefact you just built.
bash tool/assert_permissions.sh
```

Confirm by inspection that the AAB reports the tag's name and not the pubspec's: `bundletool dump
manifest --bundle=build/app/outputs/bundle/release/app-release.aab` and read `versionName` /
`versionCode`. Set `pubspec.yaml`'s `version:` to something visibly different from the `--build-name`
you passed, run the build once, confirm the flag wins, and revert. A version rule nobody has watched
override the pubspec is a version rule you are trusting on faith.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `ci: release.yml on v* tags, with the app-size budget`

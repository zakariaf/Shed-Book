# N31 — Platform artefacts, G1, G4 and G5

| | |
|---|---|
| **`00-README` §9 step** | 12 (1 of 3) |
| **Depends on** | N30 |
| **Size** | L |
| **Was** | E29 minus T01 (G0 ran at N02) and minus T06 (identifiers fixed at N00-T01) |
| **Branch** | `epic/n31-platform-artefacts-and-gates` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` · `android` |
| **Machine** | Android SDK, **JDK 17**, AGP ≥ 8.12.1, `bundletool-all.jar` on disk. A Mac for T04's iOS half. No emulator |
| **Touches `lib/`** | **No.** Two native trees, one shell script, one workflow job, four test files and two documents |

## Goal

The offline claim becomes mechanically provable in CI, against the permission set G0 actually
recorded — not against a permission set anybody hoped for.

Concretely: `android/expected_permissions.txt` is written from N02's evidence, the one removal
directive that evidence supports lands in the manifest, `tool/assert_permissions.sh` reads the
**shipped** `.aab` and asserts set equality on every push, the merger report is archived so the day a
dependency adds a permission there is a record of which one and when, and the iOS surface — three
usage strings, one appearance key, four absences — is held by the only two mechanisms iOS gives you:
construction, and one observed pass on a real device.

## Why the epic sits here

`00-README` §9 puts this at **step 12**, and its stated reason is that *"the measurements need a real
device and a real release build, which do not exist until now."* The plan critique (§2, §9 change 1)
split that reasoning in two, and this epic is the half that stayed:

- the **merged-manifest record** needed only a release build, so G0 moved forward to **N02**, twenty-nine
  epics early — because if Play Billing 8.0.0 contributed `ACCESS_NETWORK_STATE`, the store listing,
  the About screen and the Export screen wording all change, and discovering that here would mean
  re-opening copy in three merged epics;
- the **gate that executes the record** stays at step 12, because it builds a release AAB in CI on
  every push, and a job that adds twenty minutes to every pull request is not something you switch on
  in week one against a tree with no `lib/`.

The ordering inside step 12 is also deliberate. `13 §4.2` gives the `android` job `needs: [gate,
codegen, test]`, so `codegen` (N08) and `test` (N01-T06) must already exist on `main`. N32 then signs
and opens the closed track — and it signs the artefact **this** epic taught CI to inspect. Signing an
artefact whose permission set nothing asserts is the wrong order, and it is the order the old plan had.

**Nothing in this epic depends on N30's code**, only on N30 being merged. T01's `Depends on` names
N30-T08 because the epics are strictly sequential and one pull request each, not because a monetization
widget is load-bearing here. What T01 genuinely needs is `com.android.vending.BILLING` being in the
merged manifest, and that has been true since `in_app_purchase` entered `pubspec.yaml` at N00-T03.

## What is observably true when this epic merges

Things you can run, see or show someone, none of which was true before this branch:

1. **`bundletool dump manifest` on a real release `.aab` prints exactly the set `13 §2.2` recorded** —
   seven `uses-permission` lines, and `android.permission.INTERNET` is not the eighth.
2. **A planted permission turns CI red**, watched once on this very pull request: add a
   `<uses-permission>` line to `android/app/src/main/AndroidManifest.xml`, push, and the `android` job
   fails naming the permission that appeared. Revert, push, green.
3. **`build/app/outputs/logs/manifest-merger-release-report.txt` is a downloadable artefact on every
   run**, including the failed ones — which are the runs you want it from.
4. `minSdk` is a **number in `android/app/build.gradle.kts`**, not an expression that moves when a
   plugin bumps its own floor, and `fvm flutter test test/policy/android_config_test.dart` says so.
5. `adb shell dumpsys package <application id> | grep -A20 'requested permissions'` on a phone with
   the release build installed lists the same seven — the claim, read off the device rather than off a
   document.
6. **The two `flutter_local_notifications` receivers exist**, so a reminder set before a reboot still
   fires after it. The plugin has declared neither itself since v16.
7. `fvm flutter test test/policy/ios_config_test.dart` is green, and you can watch it go red by adding
   `NSAppTransportSecurity` to `ios/Runner/Info.plist` — the same failure the `gate` job's `grep`
   produces, one push earlier.
8. On a real iPhone, **Settings ▸ Privacy ▸ App Privacy Report shows no network activity** for a full
   session that saves a lambing, exports a CSV and opens Unlock. The date and the device are recorded.

## Sources

The previous version of this file cited `08 §7`, which is the wakelock section. The Android and iOS
build configuration is `08 §8.3` and `§8.4`, and what CI proves about it is `08 §9`. Corrected here.

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §2.1–§2.8 | the claim's only permitted wording, G0 as prerequisite, **G1's script verbatim**, G2/G3's split, G4's archive, G5 honestly, and the four named anti-patterns |
| `docs/engineering/13-build-ci-release.md` | §3.1, §3.2 | the eight-entry Android set with its `tools:node="remove"` manifest, the Gradle floors, and the iOS key table with its four required absences |
| `docs/engineering/13-build-ci-release.md` | §4.2, §4.3 | the job matrix and the `android` job verbatim, including the action versions and their read dates |
| `docs/engineering/13-build-ci-release.md` | §12 | the manual pre-release checklist — items 1, 2, 3 and 10 are this epic's, forever |
| `docs/research/00-tech-decisions.md` | §3.1–§3.4 | the three tiers and which two are claimable · the gates · the eight-entry set · the honest exceptions |
| `docs/research/00-tech-decisions.md` | §5.1, §5.3 | every version number, including `desugar_jdk_libs` 2.1.4 and why `permission_handler` is not here |
| `docs/engineering/08-platform-integration.md` | §8.2, §8.3, §8.4 | who asks for what and when · the final Android set with **both receiver declarations printed** · the final iOS key set with the usage-string copy verbatim |
| `docs/engineering/08-platform-integration.md` | §2.9, §2.10 | `USE_EXACT_ALARM` is a store rejection, and why the boot receiver is not optional |
| `docs/engineering/11-monetization-and-store.md` | §9.2 | `PrivacyInfo.xcprivacy`'s ruling — **already landed at N30-T07**; this epic reads it and does not re-author it |
| `docs/engineering/12-testing.md` | §10.2, §11.1, §11.2 | which gates belong in `test/` and which do not · a policy test names the property · the declared tag set |
| `epics/00-PLAN-CRITIQUE.md` | §9 change 4, §10 row N31 | `test` in N01-T06, `codegen` in N08, `android` **here** — the ruling that gives this epic the fourth job |

## Entry conditions

Everything below is already merged on `main` before this branch is cut. Each one is named because a
missing one turns this epic into a different epic, not into a slower one.

| Needs | From | Why |
|---|---|---|
| `13 §2.2`'s four-row table filled, with an ISO date in every *Recorded on* cell | N02-T01 | `13 §2.2`: *"Until this table is filled in, `android/expected_permissions.txt` does not exist and G1 cannot be written."* T01 has nothing to write from otherwise |
| The `ACCESS_NETWORK_STATE` ruling, and the honesty paragraph if it forced one | N02-T02 | It decides whether the expected file holds seven lines or eight, and whether `docs/store/offline-honesty.md` gained a sentence |
| `test/policy/g0_recorded_test.dart` green | N02-T03 | It is the guard that has banned `tools:node="remove"` since epic 2, and it must stay green through T01's commit |
| `gate` and `test` jobs in `.github/workflows/ci.yml` | N01-T06 | T03 appends a fourth job to that file and extends its test |
| `codegen` job | N08 | `android` declares `needs: [gate, codegen, test]` |
| `ios/Runner/Info.plist` with the appearance key and the three launch keys | N11-T07 | T04 edits that file and must not disturb what is already in it |
| `ios/Runner/PrivacyInfo.xcprivacy` and the `*.storekit` file | N30-T07 | G5's privacy-report check reads the first; neither is re-authored here |
| N30 merged and `main` green | N30-T08 | The epics are strictly sequential, one pull request each |
| Android SDK, JDK 17, `bundletool-all.jar`, and a Mac with Xcode for T04 | — | Check before cutting the branch, not after. `java -version` must print 17 |

## Tasks

Strictly in order. Each depends on the one before it, and the chain is not cosmetic: T01 writes the
expected set, T02 makes the build that produces the artefact reproducible, T03 executes the comparison
in CI, T04 does the same job for the platform where no such comparison is possible.

| Task | Depends on | One line |
|---|---|---|
| [N31-T01](N31-T01-androidexpected-permissionstxt-and-the-toolsnode-remove-line.md) | the merged N30, and G0's record | `android/expected_permissions.txt` and the `tools:node="remove"` line G0 proved |
| [N31-T02](N31-T02-android-build-configuration.md) | N31-T01 | Android build configuration — explicit SDK levels, Java 17, desugaring, the two receivers |
| [N31-T03](N31-T03-toolassert-permissionssh-g1-the-android-job-and-the-g4-archi.md) | N31-T02 | `tool/assert_permissions.sh` (G1), the `android` job and the G4 archive |
| [N31-T04](N31-T04-ios-the-three-usage-strings-the-appearance-key-and-g5.md) | N31-T03 | iOS — the three usage strings, the appearance key, and G5 |

Each task file's header table carries its precise `Depends on` ids; the entry-conditions table above is
where the cross-epic ones are spelled out.

## The PR workflow, concretely

Nothing here is optional and nothing here is parallel.

**1 — Cut the branch from the merged `main`.** N30 is merged and `main` is green before this starts.
Never cut from N30's branch.

```bash
git switch main && git pull --ff-only
fvm flutter --version                       # must print 3.44.8; .fvmrc is the pin
git log --oneline -1 -- pubspec.lock        # see below
git switch -c epic/n31-platform-artefacts-and-gates
```

That third command is this epic's entry condition and it takes five seconds. **If `pubspec.lock` has
changed since N02's merge, G0's record describes a different dependency set** and
`android/expected_permissions.txt` cannot be written from it. The expected answer is that it has not:
N00-T03 committed the whole runtime table at once, so the merged manifest N02 read already reflects
every plugin this app will ever have in v1. If the answer is different, stop and re-run `13 §2.2`'s
dump before T01, and say so in the PR body.

**2 — Four commits, one per task, in task order**, with the message each task file names verbatim.
Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

Two commits carry an extra obligation:

- **T01 writes the one line the whole product's claim rests on.** `android/expected_permissions.txt`
  and `tool/check_policy.dart` are the two files `CLAUDE.md` names as never editable to silence a
  gate. N02-T03's guard (`test/policy/g0_recorded_test.dart`) has banned `tools:node="remove"` since
  epic 2 and stops banning it the moment `13 §2.2`'s table is filled — which it is. Confirm the guard
  is **still green** after T01's commit; if it went red, the table was reverted, not the manifest.
- **T03 amends `13 §2.3`'s published script.** The script as printed compares expected lines that
  still carry their inline `#` comments against actual lines that are bare permission names, so it is
  red on its first run for a reason that has nothing to do with permissions. The fix belongs in
  `tool/assert_permissions.sh` **and** in the document, in the same commit — `00-README` §10's
  amendment rule, applied to a shell script.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → validate_epics.py → dart format → analyze --fatal-infos
make test         # the suite, randomised, + TZ=Europe/London --tags uk-zone
```

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the diff
in order of irreversibility. `00-README` §10's layer order does not apply — this branch reaches no
layer. The order for this branch is:

`android/expected_permissions.txt` → `android/app/src/main/AndroidManifest.xml` →
`ios/Runner/Info.plist` → `tool/assert_permissions.sh` → `.github/workflows/ci.yml` →
`android/app/build.gradle.kts` and `android/settings.gradle.kts` →
`docs/engineering/13-build-ci-release.md` → `docs/calendar.md` → `test/`.

The expected file is first because it is the only file in this repository whose edit can make a public
claim false without changing a line of Dart.

**4 — Open the PR and answer the five §12 questions** from `.github/pull_request_template.md`,
verbatim, in the body. Four of the five are genuinely not reached and should say so rather than being
ticked. **§12.3 — never present the app as a compliance or regulatory record — is reached**, and by
more than usual: the three iOS usage strings are copy a shepherd reads at the worst moment, the store
permission list is what a buyer reads before installing, and `13 §12` item 9 is explicit that store
metadata is outside `tool/check_policy.dart`'s reach forever — *"you are the gate."*

Also record in the PR body what CI cannot reproduce: T04's iOS half is built and observed on the
developer's Mac (`13 §4.1` — there is no macOS job, by budget), so name the device, the iOS version
and the date of the App Privacy Report pass.

**5 — Wait for the pipelines.** Three run on the first push; **four from T03's commit onward**, and the
fourth job's very first execution in the history of this repository is on this pull request.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` · the `NSAppTransportSecurity` grep (**G5**'s text half) | Two things, and only two. G2 proves no package entered the graph while this branch was open — this epic adds none, so a red G2 here means somebody ran `pub add` to make a build work. The ATS grep is the half of G5 a text check can do, and T04 is editing the exact file it reads. **G3 proves nothing about `android/` or `ios/`**: `check_policy.dart` walks `.dart` files under `lib/` and `test/` only, which is why `USE_EXACT_ALARM` is caught by G1 on the merged manifest and by T02's test, never by the gate |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | A **negative**, and it is the cheapest possible assurance that this branch is what it claims to be. N31 adds no table, no column and no generated file; `drift_schemas/` must not move by one byte. A red `codegen` on this branch means a commit touched `lib/`, which no task here is permitted to do |
| `test` | `flutter test` randomised · `TZ=Europe/London --tags uk-zone` over the whole suite · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · the coverage artefact (reported, **never** gated) | The four anchors, plus the extensions to `test/policy/ci_jobs_test.dart` (T03) and `test/policy/calendar_commitments_test.dart` (T04). **Nothing in this epic is time-shaped** — no instant is computed, stored or formatted — so no `test/domain/uk_zone/` case is added and the ambiguous **01:00–01:59** hour appears here only as a date sentinel in the calendar ledger, which `00-README`'s ledger test reads without ever consulting a clock |
| `android` | `actions/setup-java@v5` temurin 17 · `flutter build appbundle --release --obfuscate --split-debug-info` with `--build-number` and both `--dart-define`s · fetch `bundletool` · **G1** · upload the AAB, the merger report (**G4**), the symbols and `merged-manifest.xml` with `if: always()` | The epic. It is the only job in the repository that reads a **built artefact** rather than source, and it is the only mechanical proof behind the sentence the store listing is allowed to print. It does not exist until T03's commit, so plan for the PR to show three checks and then four |

Two consequences of that last row that bite if they are a surprise:

- **The `android` job cannot be a required status check until it exists on `main`.** GitHub will not
  let you require a check it has never seen. Add it to branch protection **after** this merge, in the
  same sitting, and confirm on N32's first pull request that four checks are required and not three.
  A gate that is not required is a gate that goes red and gets ignored.
- **It is the slowest job in the matrix by a wide margin** — a cold Gradle and pub cache puts the
  release build at fifteen to twenty-five minutes, against a `timeout-minutes: 30`. `concurrency`
  with `cancel-in-progress: true` is already set in `ci.yml`, so a second push cancels the first; do
  not push twice in a minute and then wonder which run you are reading.

Goldens do **not** run on this PR: the `goldens` job is `v*` or `workflow_dispatch` only, and it does
not exist yet — `goldens.yml` is N33-T09's.

**6 — Merge, preserving the four commits.** Rebase or a merge commit, never a squash. Each of these
four commits changes what the product may claim or which devices may install it, and each has to be
readable on its own in six months when somebody is asking *"when did that permission appear?"*

```bash
gh pr merge --merge --delete-branch
git switch main && git pull --ff-only
gh run watch                                # main must be green after the merge
# then, and only then:
git switch -c epic/n32-signing-and-closed-track
```

N32 signs an artefact and puts it on a track. Cutting it from anything other than a green merged
`main` means the first signed build is the first build nobody asserted the permission set of.

## Risks, and what is irreversible

**The loud one first.** `android/app/src/main/AndroidManifest.xml` gains
`<uses-permission android:name="android.permission.INTERNET" tools:node="remove" />` in T01. That line
is the entire mechanical content of the product's central public claim. If the evidence behind it is
wrong, the failure is not a red build — it is a purchase flow that misbehaves on a flaky connection,
in production, on someone else's phone, discovered by a shepherd. The evidence is N02's, it is dated,
and it is recorded in two documents. **Read it before you write the line, and do not re-derive it.**

**Nothing here is a schema snapshot, and nothing here is published.** No `drift_schemas/` file moves;
no artefact reaches a store — N32 does that. What does not come back cleanly:

- **A permission that has shipped.** Removing it later is a one-line diff, but the store listing showed
  it, every installed phone's permission page showed it, and the buyer who read the listing and decided
  the app was not what it claimed is not coming back. This is why `expected_permissions.txt` may never
  be edited to make a red build green: the file is the veto, and editing it deletes the veto.
- **`minSdk`, upward.** Setting it to 24 at v1 is free. Raising it after the first release silently
  strips update delivery from every device below the new floor, with no notification to the owner of
  that device. T02 sets it from G0's recorded effective value for exactly this reason: *"a `minSdk`
  that moves because a plugin bumped its own is a silent change to who can install the app."*
- **The three iOS usage strings, once a build is submitted.** They are review metadata as much as UI
  copy. Changing them later is a new submission, and the old wording stays in the review record.
- **`docs/engineering/13-build-ci-release.md` §2.3's script**, once T03 amends it. It is the published
  form the release workflow (N34) will copy; a half-applied amendment leaves two authoritative scripts
  disagreeing, which is worse than one wrong one.

| Risk | Why it bites | What to do |
|---|---|---|
| G1's published script is red on its first run for the wrong reason | The expected file's inline `#` comments survive `grep -v '^\s*#'` and are diffed against bare permission names. The first instinct is to delete the comments — which deletes the provenance that makes the file readable, and `13 §2.2` requires every line to name its contributing library | Fix the **script**, not the file (T03 §5.4), and amend `13 §2.3` in the same commit |
| The script's three exit codes are documented but not implemented | `13 §2.3` promises `2` for "the gate could not run — missing expected file, missing bundletool, missing AAB"; the published script produces `2` for the first case only, and dies under `set -e` for the other two with no `::error::` line | Implement the contract the same section states. A gate that could not run *"is still a failure, never a skip"* |
| `bundletool` is fetched at `latest` | The gate's tool floats. `13 §2.3` carries this as unverified | Record the version the job actually fetched in the PR body. It fails **closed** on a format change (exit 1 on a diff), which is the correct direction; pin only if that ever happens once |
| No Android toolchain or no JDK 17 on the machine | T01–T03 cannot be verified locally at all, and the epics are strictly sequential | Check before cutting the branch. `java -version` must print 17 |
| Watching G1 fail is skipped because it is inconvenient | `00-README` §9 step 1: *"a rule nobody has seen fire is indistinguishable from a broken rule."* This gate's whole value is the day it fires, in month six, on somebody else's plugin bump | Plant the extra permission, push, read the red log, revert. It costs one CI run |
| The `android` job is not added to branch protection after the merge | Every subsequent PR goes green on three checks and G1 proves nothing | Do it in the same sitting as the merge, and verify on N32's first PR |
| `test/policy/calendar_commitments_test.dart` closes the ledger's key set at seven | T04's Definition of Done records the G5 observation in that ledger, which needs an eighth row **and** the assertion updated in the same commit | T04 §5.5 rules on it. Extending a named set with a stated reason is the mechanism; deleting a row to go green is the thing the test exists to prevent |
| N11-T07 already asserts three of T04's properties in `test/design/first_frame_parity_test.dart` | Two homes for one property means one of them goes stale silently | T04 **moves** the plist-policy cases into `test/policy/ios_config_test.dart` rather than adding a second copy, and says so in the commit message |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test` · `android`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] `android/expected_permissions.txt` holds **seven** uncommented lines (eight if G0 recorded `ACCESS_NETWORK_STATE`), sorted, each naming its contributing library
- [ ] G1 asserts **set equality**, not the absence of one string, and was watched failing on a planted permission
- [ ] the G4 merger report is archived on every `android` run, including failed ones
- [ ] `minSdk`, `compileSdk` and `targetSdk` are explicit numbers, and `minSdk` equals G0's recorded effective value
- [ ] `USE_EXACT_ALARM` appears in no manifest, no Gradle file and no Dart file
- [ ] `NSAppTransportSecurity`, `UIBackgroundModes`, `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` appear nowhere in `ios/Runner/Info.plist`
- [ ] the G5 observation is recorded with a date and a device, and the record is read by a test
- [ ] `android` is a required status check on `main` after the merge

## Demoable on merge

`bundletool dump manifest` on a real release `.aab` shows exactly the permission set G0
recorded, and the `android` CI job fails if it ever changes.

## Notes

This epic is what makes the sentence in `CLAUDE.md` true rather than aspirational:

> "Shed Book has no account, no server and no sync. The Android build ships without the internet
> permission, so the app itself cannot connect to anything. Your records only leave the phone when you
> deliberately export and share them."

Everything before it recorded a fact. This is where the fact starts defending itself on every push.
The one thing that would undo it is a future contributor editing
`android/expected_permissions.txt` to make a red build green — which is why that file is named, by
path, in `CLAUDE.md`, in `13 §2.3`'s own script output, and in the code-review checklist.

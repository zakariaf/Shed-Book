# N32 — Signing and the closed track opens

| | |
|---|---|
| **`00-README` §9 step** | 12 (2 of 3) |
| **Ships in** | `v1.0.0` |
| **Depends on** | N31 |
| **Size** | M |
| **Was** | E30a, moved **before** the sweeps |
| **Branch** | `epic/n32-signing-and-closed-track` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` · `android` |
| **Machine** | A Mac with Xcode 26+, the Android SDK and **JDK 17**, `keytool` on the path, `bundletool-all.jar` on disk, and one physical Android phone. Both store consoles open in a browser |
| **Touches `lib/`** | **No.** One Gradle file, one `.gitignore`, three documents, two test files — plus two things that exist only in a browser and one key that exists only off the laptop |

## Goal

Generate the upload key, wire release signing, create both store records, author the listing copy, and
put the first signed build on a Play closed track and on TestFlight — **so Play's fourteen-day
closed-test clock runs in parallel with N33's sweeps instead of after them**.

## Release scope — P15

**`v1.0.0`, and the calendar is now the binding constraint rather than the ordering argument.**

Play's closed test needs **twelve testers opted in for fourteen continuous days** before production,
and `13 §11` closes the release window on **31 January 2027**. Working backwards: `v1.0.0` submits to
both stores around **mid-December 2026** — two review queues, at Christmas — so **this epic must merge
by about November 2026**, and the ledger row `twelve_testers` is still open.

**T02's listing describes `v1.0.0` and nothing else.** It is drafted while `v1.1.0` is a written plan,
which is exactly when a listing acquires a feature the build does not have. **Reminders are the named
risk**: they are in spec §7.6, they are the most screenshot-able thing in the backlog, and they are not
in the binary. Neither is the flock-book PDF, nor note search, nor the season summary.

The §3.1 offline wording is unaffected and stays verbatim — it is a statement about what the app
*cannot* do, and `v1.0.0` can do even less of it.

## Why it sits here and not at the end

`00-README` §9 puts every release concern in step 12, and its stated reason is narrow: *"G0 gates the
`tools:node="remove"` line, not the app; the measurements need a real device and a real release build,
which do not exist until now."* That reason covers the **measurements**. It does not cover the
**calendar**, and the plan critique splits step 12 on exactly that seam (§10 change 16, §11.1): N31
takes the artefacts and the gates, N32 takes signing and the tracks, N34 takes `release.yml`, the
budgets and the freeze.

What lateness costs is not effort, it is dead time. `13 §10.2`: *"A personal Google Play developer
account created after 13 November 2023 must run a closed test with at least 12 opted-in testers for 14
continuous days before it can apply for production access."* And: *"Start the closed test **during**
the build, not after it. A launch delayed by fourteen days because nobody read this paragraph is the
most avoidable schedule failure available to this project."* The critique's gate table says the same
thing in one line: **the closed track is open · N32 · otherwise fourteen days of dead calendar at the
end of the project.**

Two clocks start on this branch and run beside N33 and N34: Play's fourteen continuous days, and — if
external TestFlight testing is used — Apple's Beta App Review turnaround.

## Entry conditions

Everything below is already merged on `main` before this branch is cut. Two of them are not code and
cannot be hurried; check them **before** you cut the branch, not after.

| Needs | From | Why |
|---|---|---|
| Both developer accounts exist, identity-verified, banking and tax complete | N00-T09 | Neither store shows you an app record without them, and the tax step is the one people discover in the week they wanted to ship |
| The 13 November 2023 personal-account question answered in writing | N00-T09 | It is the difference between a fourteen-day clock and no clock at all |
| Twelve shepherds recruited and willing to opt in | N00-T07 | Play counts **opted-in** testers, not invited ones. Recruitment is weeks; opting in is minutes |
| `shed_book_unlock` created on both stores, price and territories chosen | N00-T09 | The closed test is also the first real purchase test |
| Application id / bundle id fixed and recorded in `RELEASES.md`'s header | N00-T01 | The store record freezes it forever on first upload |
| `docs/store/offline-honesty.md` | N02-T02 | The listing quotes it; it is not re-typed |
| G0 closed, `android/expected_permissions.txt`, `tool/assert_permissions.sh` | N02, N31-T01, N31-T03 | You run G1 by hand on the artefact you upload, not on a rebuild |
| `android/app/build.gradle.kts` carrying explicit SDK levels and desugaring | N31-T02 | This branch adds a `signingConfigs` block to that file |
| `ios/Runner/Info.plist`, `PrivacyInfo.xcprivacy`, the `*.storekit` file | N31-T04, N30-T07 | TestFlight rejects an archive whose privacy manifest did not make it into the target |

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §9.2, §9.3, §9.4 | the Gradle signing block, Xcode automatic signing for v1, and the four artefacts whose loss has no recovery |
| `docs/engineering/13-build-ci-release.md` | §10.1, §10.2, §10.3 | TestFlight internal versus external, the 12-tester / 14-day rule, and which purchase loops need which account |
| `docs/engineering/13-build-ci-release.md` | §9.1, §9.1.1, §12 | build name from the tag, build number from the run number, the two `--dart-define`s, and the manual checklist |
| `docs/engineering/11-monetization-and-store.md` | §9.4, §9.5, §10, §11 | the Play data-safety exemption, what is *not* needed because there is no account, the App Review notes verbatim, and license testing |
| `docs/research/00-tech-decisions.md` | §3.1, §3.4 #5, §7.1 items 4 and 14 | the only permitted public wording, the hosted privacy-policy URL, and the two open questions this epic closes in practice |
| `docs/engineering/CONVENTIONS.md` | §5.1, §5.3, §5.4 | *unlock* not *purchase*, the absolute ban list, and *"the price is never a literal"* |
| `epics/00-PLAN-CRITIQUE.md` | §10 change 16, §11.1, §11.5 | why this epic moved in front of N33, and the gate row that says what happens if it does not |
| `shed-book-spec.md` | §14 | one-time unlock, €10–15, no subscription ever — the positioning the listing must carry |

## Tasks

| Task | Depends on | One line |
|---|---|---|
| [N32-T01](N32-T01-signing-the-upload-keystore-play-app-signing-and-the-ios-hal.md) | outside this epic | Signing — the upload keystore, Play App Signing and the iOS half |
| [N32-T02](N32-T02-the-play-app-record-and-the-store-listing-draft.md) | N32-T01 | The Play app record and the store listing draft |
| [N32-T03](N32-T03-open-the-closed-track-and-testflight-the-fourteen-day-clock.md) | N32-T02 | Open the closed track and TestFlight — the fourteen-day clock starts |

The order is forced, not cosmetic. You cannot upload an artefact you cannot sign, you cannot sign into
a Play app record that does not exist, and you cannot open a track on an app record with no listing
and no content rating. Running T03 first produces an upload rejected for a reason that takes an hour
to read.

## Demoable on merge

In one sentence: **a signed AAB reaches a Play closed track and TestFlight, and the calendar ledger's
twelve-tester row records the date the clock started.** Concretely — things you can run, see or show
someone, none of which was true before this branch:

1. `fvm flutter build appbundle --release` produces an AAB, and
   `keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab` prints **your**
   upload certificate — not `CN=Android Debug`, which is what the Flutter template signs release
   builds with until somebody changes it.
2. `git check-ignore -v android/key.properties` names the ignore rule, and
   `fvm flutter test test/policy/signing_config_test.dart` is green — including the case that goes red
   the moment a `.jks` is tracked.
3. Play Console ▸ Release ▸ Setup ▸ **App integrity** shows two certificates: the app signing
   certificate Google holds, and the upload certificate you hold.
4. `docs/store/` holds the listing copy for both stores, every field inside its store's character
   limit, the offline paragraph quoted from `docs/store/offline-honesty.md` character for character,
   and the App Review notes as `11 §9.5` writes them.
5. A Play **closed** track carries a signed AAB, twelve testers are opted in, and the opt-in URL works
   on a phone that is not yours.
6. TestFlight carries the iOS build at the same build number, installable on a device.
7. `docs/calendar.md`'s `twelve_testers` row carries the date the clock started and the count — and
   `fvm flutter test --tags calendar` is **green for the first time since N00-T06 wrote it red**.
8. `RELEASES.md` has a row for a build that has no tag, and its Notes cell says why.

## The pull request workflow

Concretely, in order. Nothing here is optional and nothing here is parallel.

1. **Cut the branch from the merged `main`** — the one carrying N31's merge, never from N31's branch:
   `git switch main && git pull && git switch -c epic/n32-signing-and-closed-track`.
2. **Three commits, one per task**, in task order, with the message the task file names. Before each
   commit: **`/simplify`**, then **`/code-review`**, then **`/shed-code-review`** — that order, every
   task, no exceptions. `/shed-code-review` carries `disable-model-invocation: true`, so it is typed
   by name or it does not run.
3. **`/shed-code-review` once more over the whole branch**, read in order of irreversibility. For this
   branch that order is not `00-README` §10's layer order — this branch reaches no layer. It is:
   `.gitignore` and `android/app/build.gradle.kts` first, because a leaked key is the only defect here
   that a revert does not fix; then `docs/store/**`, because it is public copy; then
   `docs/calendar.md` and `RELEASES.md`, because they are the project's memory; then the two test
   files.
4. **Push and open the PR.** `git push -u origin epic/n32-signing-and-closed-track`, then
   `gh pr create`.
5. **Answer the five §12 questions in the PR body**, from the template N01-T07 committed. Three are
   genuinely not reached — say so rather than ticking them. Two **are**: §12.2 *never give veterinary
   advice* and §12.3 *never present the app as a regulatory record* are both reached by the store
   listing, which is public copy about what the app is and is not, and which no gate can ever read
   (`13 §12` item 9 — *"you are the gate"*).
6. **Record in the PR body what CI cannot reproduce**, because most of this epic happened in a browser
   and on a laptop. Name: the machine, the Flutter version, the JDK, the `bundletool` version, the
   keystore's alias and validity end date (never a password, never a fingerprint you would not publish
   — the SHA-256 upload certificate fingerprint is fine and is worth recording), every build number
   consumed on either store, and the date and time the closed track went live.
7. **Wait for the pipelines.** Four run, and it is worth knowing what each one does *not* prove here:
   - **`gate`** — toolchain pin against `.fvmrc`, `flutter pub get`, `tool/check_policy.dart`
     (**G2 + G3**), `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos
     --fatal-warnings`, and no `NSAppTransportSecurity` in `ios/Runner/Info.plist`. It proves this
     branch added no network path and no unreviewed package. **It cannot see Kotlin.** Nothing in
     `make check` reads `android/app/build.gradle.kts`; the anchor test in N32-T01 is the only gate
     over the signing block, which is why that test asserts the Gradle file's *shape* and not just its
     existence.
   - **`codegen`** — `build_runner build` + `drift_dev make-migrations` + `git diff --exit-code` over
     `lib/`, `drift_schemas/` and `test/drift/generated/`. This branch touches no schema, so the job's
     value here is negative evidence: it proves nothing regenerated by accident.
   - **`test`** — `-P ci-fast` with randomised ordering, `TZ=Europe/London --tags uk-zone`, and
     `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone`. It runs
     `test/policy/signing_config_test.dart` and the listing cases added to
     `test/policy/offline_wording_test.dart`. **Check whether it also runs
     `test/policy/calendar_commitments_test.dart`** — N00-T06 states the ledger test is held out of the
     blocking set by its `calendar` tag, and N01-T04's `ci-fast` preset as written excludes `golden`
     only. If the exclusion was never wired, `main` has been red since N00 and this branch is what
     turns it green; if it was, the ledger test is not run by CI at all and T03 runs it by tag. Find
     out which before you promise anything in the PR body.
   - **`android`** — release AAB, **G1**, **G4** archive. This is the job most likely to go red on this
     branch, and the cause will be the signing block: CI has no `android/key.properties` and no
     keystore, because writing them from the `SHEDBOOK_*` secrets is `release.yml`'s step and
     `release.yml` is **N34-T01's file**. N32-T01 §5 fixes the Gradle shape that keeps this job green
     with no key material on the runner. If `android` goes red with a Kotlin cast error, read that
     section before touching anything else.
8. **Merge, preserving the three commits** — rebase or a merge commit, never a squash. The three
   commits are the record: the key, the record, the track.
9. **Delete the branch**, confirm `main` is green after the merge, and only then cut N33's branch from
   the merged `main`. The fourteen days are already running while you do it — that is the entire point
   of this epic's position.

## Risks, and what is irreversible

**The loud one first, and it is a key, not a file.** The upload keystore and its three passwords are
generated on this branch and **never enter git**. If key material reaches a commit, the fix is not a
revert: it is a history rewrite on every clone, a new key, and a Play support ticket to reset the
upload key — and if the branch was pushed, assume the key is public. `13 §9.4` puts the keystore in
"two places, neither of them the laptop; one offline". Do that on the day you generate it, not later.

**Four things on this branch do not come back.**

- **Play App Signing.** Once Google generates and holds the app signing key for this application id,
  it holds it. That is the safety net — a lost *upload* key is recoverable through support — and it is
  also a one-way door.
- **The application id and the bundle id.** Fixed at N00-T01, **consumed** here. `13 §3.1`: *"chosen
  once, before the first upload, and can never change on either store."* T02 is the moment that
  sentence stops being advice.
- **Build numbers.** Both stores reject a re-used build number forever, including one burned by an
  upload that was later deleted or expired. Every number this epic consumes is spent, and `13 §9.1`
  rule 3 hands the numbering to `release.yml`'s `github.run_number` at N34 — which starts at 1. Read
  N32-T03 §5's paragraph on this before you pick a number; it is the collision that costs a release
  day at N34.
- **The listing.** It becomes a public store page. Correcting published copy is a store update, in
  public, and both stores keep the old version.

| Risk | Why it bites | What to do |
|---|---|---|
| The `android` CI job goes red on every push after T01 | The release `signingConfig` reads a `key.properties` that exists on your laptop and on no runner | Use N32-T01 §5.3's conditional shape; never make the job `continue-on-error` (`13 §4.6`) |
| A tester is on the email list but never opens the opt-in URL | Play counts **opted-in** testers. Eleven opted in is not eleven-twelfths of a clock, it is no clock | Check the opted-in count in Play Console, not your own list, and check it again on day two |
| A tester buys the unlock with a real card | The entitlement is **never revoked** (decision #88), so a refund does not re-lock — and a real charge in a test is a real charge | Add every tester to **License testing** (`11 §11`) *before* the track goes live |
| The fourteen days land inside 1 Feb – 30 Apr | `13 §10.2`'s second constraint: the window must not sit in the seasonal freeze if the plan is to ship straight after | Count the days forward on a calendar before you press "roll out" |
| The field night still has not happened | The ledger goes green on `twelve_testers` and stays red on `field_night`, whose due date was **before N13** | Do not fill a cell to make a test green. A red ledger row is the project telling the truth |
| Screenshots leak a price or a light theme | There is no light theme, and the price is the store's to render | Screenshot the dark app; never screenshot the Unlock row |
| The upload key is generated inside the repository directory | One `git add -A` from permanent | Generate it outside the tree; `android/key.properties` points at it |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test` · `android`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] no `.jks`, no `.keystore`, no password and no base64 blob is tracked or reachable in this branch's history
- [ ] `keytool -printcert -jarfile` on a locally built AAB names the upload certificate, not `CN=Android Debug`
- [ ] Play App Signing shows both certificates, and the upload certificate fingerprint is in the PR body
- [ ] every listing field is inside its store's character limit and the offline paragraph is `docs/store/offline-honesty.md` character for character
- [ ] a hosted privacy-policy URL exists and is entered on both stores
- [ ] twelve testers are **opted in**, the track is live, and the date is in `docs/calendar.md`
- [ ] TestFlight has the iOS build at the same build number, and `RELEASES.md` records both
- [ ] the symbols for every build uploaded on this branch are archived under `symbols-archive/<name>+<build>/`, off the laptop

## Notes

This epic is three tasks and perhaps two days of work, of which most is waiting for a browser. It is
the smallest epic in the back half of the plan and the one whose *position* was the point: the
critique moved it in front of N33 and gave the reason in one line — *"fourteen days of dead calendar
at the end of the project"*. Nothing on this branch makes the app better. Everything on it decides
whether the app can ship in April or in May.

---
name: shed-release
description: Cuts a Shed Book release — the offline gates G0 to G5 against a real release bundle, the exact nine-name permission set, signing and the off-machine symbols archive, size and startup budgets on two real devices, version and build number rules, the closed test track, and the release freeze between 1 February and 30 April. This builds, signs and tags, so it runs only when the developer asks for it by name.
disable-model-invocation: true
---

# Cutting a release

`docs/engineering/13-build-ci-release.md` owns this area and outranks this skill on every command,
workflow and table — §2 (gates), §3 (permissions), §4 (CI matrix), §6 (budgets), §9 (versioning and
signing), §10 (tracks), §11 (freeze), §12 (the manual checklist). `docs/research/00-tech-decisions.md`
§3.2 and §3.3 are the mechanical gates and the permission set. `docs/engineering/CONVENTIONS.md` is
binding on any name. Cite them; never restate their tables into a second authority.

**Owns:** G0–G5 against a real release AAB · the shipped permission set · signing, the keystore and
the symbols archive · size and startup budgets · version name, build number and tags · the Play
closed test · the seasonal freeze · the manual pre-release checklist.

**Do NOT use for:** what may enter `pubspec.yaml`, `analysis_options.yaml` or the `Makefile`, and the
G2/G3 rule tables inside `tool/check_policy.dart` → **shed-dependencies-and-toolchain**. Which plugin
requests which permission, when, and with what usage string → **shed-platform-gateways**.

## Stop conditions — check these before you build anything

1. **G0 ran on 2026-08-01 and §2.2's table is filled in.** What that unblocked is *writing* G1;
   `android/expected_permissions.txt`, `tool/assert_permissions.sh` and the `android` CI job are
   still N31-T02/T03's and do not exist. Do not treat a green pipeline as a permission assertion.
   **`ACCESS_NETWORK_STATE` is not removed** — the measured answer is that billing 8.0.0's own
   manifest declares no network permission and `com.google.android.datatransport:transport-backend-cct:3.1.8`,
   a compile-scope dependency of it, declares both that and `INTERNET`. The `tools:node="remove"`
   line for `INTERNET` is N31-T01's and is guarded by `test/policy/g0_recorded_test.dart`.
2. **Is it between 1 February and 30 April?** The lambing freeze (§11). Only a defect that destroys
   or corrupts records, or prevents the app opening at all, ships. If you have to argue for it, the
   answer is no.
3. **Has the Play 12-tester question been answered?** Decision-record §7.1 item 14. A personal
   developer account created after 13 November 2023 needs 12 opted-in testers for 14 continuous days
   on a closed track before it can apply for production access (§10.2). That is weeks of calendar
   time and it is on the critical path.

## The gate-integrity rule

Never edit `android/expected_permissions.txt`, `tool/policy_allowlist.txt`, `tool/check_policy.dart`
or an exit code to make a build green. For the expected-permissions file this is named in §2.8 as the
single worst thing you can do to this project — it converts the product's central claim into a
comment. A red gate is a finding: name what changed, find the contributor in G4's merger report, and
stop. User instructions outrank this skill; your own convenience does not.

## The gates (§2.8 has the table; this is what an agent gets wrong)

- **G0** — prerequisite, manual, once. **Closed 2026-08-01**; the record is 13 §2.2 and
  decision-record §3.3, the artefact is `docs/gates/manifest-merger-release-report.txt`. It recorded
  the real merged permission set, that `ACCESS_NETWORK_STATE` is present and stays, that debug **and
  profile** builds keep `INTERNET`, and `minSdk` **24** read out of the merged manifest. Re-run it on
  any Billing Library bump — the permissions were one Gradle edge further out than four documents
  assumed.
- **G1** — `tool/assert_permissions.sh` on the release `.aab`, blocking every push. It asserts **exact
  set equality**, not the absence of `INTERNET`: the failure it exists for is a plugin bump in month
  six merging a *new* permission, which a grep for one string cannot see. It reads the **built
  artefact**, never the source manifest — the merger blends in every library's manifest silently.
  Exit codes: `0` match · `1` mismatch · `2` could not run, which is a failure and never a skip.
- **G2 / G3** — `tool/check_policy.dart`, one script, one allowlist, one exit code (decision #10).
  Owned by **shed-dependencies-and-toolchain**. Never add a second scanning script here.
- **G4** — the archived `manifest-merger-release-report.txt`. Non-blocking, diagnostic, and the only
  thing that answers *which* library added that permission when G1 goes red.
- **G5** — iOS. There is no iOS permission to remove, so enforcement is construction plus observation
  (§2.7): the `NSAppTransportSecurity` text check in CI, plus the privacy report, the "Data Not
  Collected" answers and one airplane-mode/`nettop` observation pass per release, by hand.

## The permission set — nine names, and eight lines

§3.1 and decision-record §3.3 list **nine**. `android/expected_permissions.txt` holds **eight**
uncommented lines. They are the same fact counted two ways: the ninth name is `INTERNET`, asserted
by its **absence**. Confusing the two counts is how somebody adds a ninth line to green a red build.
Read the table in §3.1; do not retype it. Three rules from it that get broken:

- **`WAKE_LOCK` is not in the set.** G0 found it contributed by nothing; `wakelock_plus` uses the
  `FLAG_KEEP_SCREEN_ON` window flag. Adding it back is contradicting a measurement.
- **`androidx.core`'s `${applicationId}.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` is in the set.**
  Invisible in the Play listing, visible to G1, which asserts exact equality.

- **Never `USE_EXACT_ALARM`** — `SCHEDULE_EXACT_ALARM` is the one we declare, user-granted. Play
  rejects `USE_EXACT_ALARM` for this app category.
- **`com.android.vending.BILLING` contains no "permission" substring.** Any filter written as
  `grep permission` silently drops the entry this project cares most about. §2.3's script splits on
  `<` and selects `^uses-permission` for exactly that reason.

## Version, build number and the tag

§9.1's five rules, in the order they get broken:

1. `pubspec.yaml`'s `version:` is a **local default**, not the shipped value. Bump it to `x.y.z+1` in
   the commit you tag as hygiene only.
2. **The build name comes from the tag, always** — `git tag v1.2.0` → `--build-name=1.2.0`. If the tag
   and the pubspec disagree, the tag wins and the artefact is correct: fix the pubspec, never re-tag.
3. **The build number is always the release workflow's `github.run_number`.** Never hand-edited,
   never reused after a failed upload — both stores reject a reused number.
4. **Only `release.yml`'s artefact ever reaches a store.** Each workflow has its own `run_number`, so
   the per-push AAB can carry the same or a lower number; it exists to run G1 and is never shipped.
5. The manual iOS build uses **the same number** the release workflow produced for that tag.

Every build command carries `--dart-define=APP_VERSION` and `--dart-define=APP_BUILD` next to
`--build-name` / `--build-number` (§9.1.1). There is no package that can supply the running app its
own version — `package_info_plus` is transitive-only and reading it from `lib/` is the unreviewed
edge G2 exists to prevent. A diagnostics log reading `0.0.0+0` means somebody built without them.

## Signing and the symbols archive

Upload keystore + its three passwords live in two places, neither of them the laptop, one offline.
`android/key.properties` is git-ignored and is written in CI from the four `SHEDBOOK_*` secrets
(§4.4). Play App Signing holds the *app signing* key; you hold the *upload* key. iOS for v1 is Xcode
automatic signing on your own Mac — no `fastlane match`, no CI signing plumbing, because macOS
runners bill at 10× and that is 200 macOS minutes a month on Free/private (§9.3, §4.1).

**Release builds ship `--obfuscate --split-debug-info`, so the symbols are the only artefact whose
loss cannot be recovered by rebuilding.** Archive `build/symbols/{android,ios}` to
`symbols-archive/<name>+<build>/` — off the laptop, forever, not in git — and keep the archive path
agreeing with `flutter symbolize`'s read path (§8.4, §9.4). Without it every stack trace in every
user-sent diagnostics log for that build is permanently unreadable, and it is the only diagnostic
channel this app has.

## Budgets

- **The one tracked size number is the arm64-v8a *download* size from the Play Console's App Bundle
  Explorer**, one row per release in `docs/perf/measurements.md`. It can only be read **after**
  upload, which is why it is a checklist item and not a CI step.
- `--analyze-size`'s total is **not** the download size. It is a diffable proxy, archived per release.
  **CI measures and archives size and gates nothing on it** until a baseline exists (§6.1.1's
  narrowing of decision #126); the release *after* the first adds the 5%-growth check against the
  previous tag's archived JSON.
- Nothing user-facing ever promises an install size. Spec §11's "under 20 MB" is about bundled
  content; §6.1 is the one place that deviation is recorded.
- **Startup is measured on two physical devices in profile mode, once per release** — the oldest
  supported iPhone and the low-end Android. Profile mode is disabled on emulators and simulators, so
  a number from a hosted runner, a simulator or a debug build is not evidence, and no CI job may ever
  assert a frame time or a startup latency (§4.6, §6.2). The budget is an interactive page **at the
  first frame** and first frame ≤ 400 ms after `main()`; a spinner between the tap and the first
  digit is the failure, not the millisecond total.

## Workflow — cutting a tag

1. Confirm the three stop conditions above; `make check`, `make test`, `make gen` clean and every
   generated artefact committed.
2. **Read `references/pre-release-checklist.md` and work it in order.** Load it whenever you are
   cutting a tag — it is the ordered manual list §12 owns, including the four items that can only be
   done *after* upload.
3. Bump `pubspec.yaml`'s `version:` in the commit you tag; tag `vX.Y.Z`; push it. `release.yml`
   builds, signs, runs G1 and archives the AAB, symbols, size JSON, merged manifest and merger report.
4. Upload by hand — ninety seconds, and you want to read the rollout percentage. iOS is built and
   uploaded from your Mac with the same build number.
5. Archive symbols under `<name>+<build>`; fill in `RELEASES.md` and `docs/perf/measurements.md`.

## Gotchas

- **`goldens.yml` is the workflow people forget.** It is the only macOS job, it never runs on a PR,
  and it must still carry §1.1's three-line assert that its `FLUTTER_VERSION` equals `.fvmrc`
  — whose value is decision-record §5's pin and nobody else's. A golden diff caused by a version drift reads
  as a design regression and costs an hour on the wrong thing.
- **The size-analysis JSON's path has moved before.** Read it out of the command's own output (`tee`
  the log and grep for the path); never assume a location.
- **The freeze step in `release.yml` warns and never blocks** — the one release that must be able to
  run during the freeze is the hotfix the freeze exists to make rare. The warning annotation stays on
  the run summary forever, which is the point.
- **The freeze lifting on 1 May is not the season ending.** May is staged rollout only, 10% for 72 h.
- **Notification channel ids are frozen at the first release** — **eight**, byte-identical to
  `reminders.kind`'s CHECK (R49, `08-platform-integration.md` §2.7). Decision #65's `turnout` / `dose`
  / `withdrawal` are **superseded and banned spellings**. Changing one after release silently orphans
  every scheduled reminder on every installed device.
- **Never grep `build/app/intermediates/`.** Flutter's debug and profile manifests *do* declare
  `INTERNET`, so the grep fires on a stale directory and then gets deleted for being flaky. Read the
  AAB.
- **`bundletool` is fetched in CI at `latest` and therefore floats.** If a dump-format change ever
  breaks it, G1 fails closed on a diff, which is the correct direction — pin a version then, not now.
- **Store metadata is outside every gate.** `tool/check_policy.dart` cannot see release notes, the
  store listing or the privacy form. Only §2.1's wording is permitted, and **never** "your data never
  leaves your phone" — it does, the moment they share a CSV. No dose, no diagnosis, no "you should"
  (spec §12.2). You are the gate.
- **Flutter 3.44 made SwiftPM the default iOS dependency manager**, and it packages plugin resource
  bundles differently from CocoaPods. A dropped `PrivacyInfo.xcprivacy` surfaces as `ITMS-91061` at
  upload. Re-generate the privacy report after the migration and after every plugin bump.
- **Ship an AAB, never a fat APK; one binary, no flavors** (decisions #127, #87). `--split-per-abi` is
  for direct download, which this project does not do.
- **Nothing in CI can test a purchase.** The four offline purchase paths are checklist items, run on a
  real device in airplane mode (`11-monetization-and-store.md` §11).

## Done when

- [ ] G0's table in §2.2 is filled in from a real release AAB, and `android/expected_permissions.txt`
      exists, is sorted, holds eight uncommented lines, and names each line's contributing library.
- [ ] G1 ran on the artefact being uploaded and asserted set equality; the eight `uses-permission`
      lines were read by a human and `INTERNET` is not among them.
- [ ] No gate file, allowlist, rule table or exit code was edited to make anything pass.
- [ ] Build name came from the tag; build number is `release.yml`'s run number; both `--dart-define`s
      were passed; the uploaded artefact came from `release.yml` and no other workflow.
- [ ] Symbols archived under `<name>+<build>` off the laptop; keystore backed up in two places.
- [ ] `docs/perf/measurements.md` has a row for this release — startup on two physical devices, DB
      open and migrate, PDF duration — with the AAB download size filled in after upload.
- [ ] `RELEASES.md` has the tag, the build number and both upload dates.
- [ ] Every item in `references/pre-release-checklist.md` is done, including the airplane-mode pass,
      the dark-launch check and the release-notes read.
- [ ] If it is 1 February to 30 April, the release clears §11.1's data-loss bar and shipped staged.

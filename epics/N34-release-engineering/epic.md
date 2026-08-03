# N34 — Release engineering

| | |
|---|---|
| **`00-README` §9 step** | 12 (3 of 3) |
| **Ships in** | `v1.0.0` |
| **Depends on** | N33 |
| **Size** | M |
| **Was** | E30b |
| **Branch** | `epic/n34-release-engineering` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` · `android` |

## Goal

The four things that only exist once there is a real release build and a real device to run it on:
`.github/workflows/release.yml` on tag `v*` with the version rules and the size measurement,
`--obfuscate --split-debug-info` with the symbols filed off the laptop under
`symbols-archive/<name>+<build>/`, startup measured in **profile** mode on two physical devices into
`docs/perf/measurements.md`, and the seasonal freeze plus the manual checklist that catches everything
no pipeline structurally can.

**Why it sits at step 12, and last within it.** `00-README` §9 gives the reason and it is one
sentence: *"G0 gates the `tools:node="remove"` line, not the app; the measurements need a real device
and a real release build, which do not exist until now."* Everything in this epic is downstream of an
artefact. You cannot measure the arm64 download size of an AAB that has never been built; you cannot
symbolize a stack trace from a binary that was never obfuscated; you cannot record a cold start on a
phone that has nothing to launch. `00-PLAN-CRITIQUE` §5 then split the old E30 in two, because signing
*"unblocks the 14-day calendar clock"* and budgets and the freeze do not — so **N32** went before the
sweeps and this epic is the remainder, sequenced last on purpose.

Three of the four tasks are release *configuration*, and the fourth is prose. That is not a light epic.
Configuration is where the mistakes are permanent: a build number is spent the moment a store sees it,
a symbols directory that was never archived cannot be rebuilt, and an update is irreversible on someone
else's phone the moment they take it.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §4.4, §6.1–§6.3, §8.4, §9.1–§9.4, §11–§12 | `release.yml` verbatim, the size and startup budgets, symbolization, the version rules, the artefacts you must keep, the freeze and the eleven-item checklist |
| `docs/engineering/13-build-ci-release.md` | §1.1, §1.3, §4.2, §4.6 | the four places the toolchain version lives and the assert that makes it safe; the `Makefile`'s `perf` target; the job matrix; what is deliberately not automated |
| `docs/engineering/00-README.md` | §7.1, §7.2, §7.4, §9 | what is committed, what is git-ignored **and must not be lost**, tags and the never-tag window, the build order |
| `docs/research/00-tech-decisions.md` | §5, #126, #127 | the pinned versions the release build reproduces; CI gates size not speed; the app-size reframing |
| `docs/engineering/CONVENTIONS.md` | §1, §4.1, §5 | the tree, `lower_snake` for the names outside the Dart tree, the banned words |
| `docs/engineering/12-testing.md` | §11.2, §14 A and B | the declared tags, and why the `uk-zone` step is unscoped — this epic adds a zone-tagged case outside `test/domain/` |
| `docs/engineering/CODE-REVIEW-CHECKLIST.md` | §2, §3.1 | the five §12 questions the checklist carries and the irreversibility reading order |
| `epics/00-PLAN-CRITIQUE.md` | §5 E30, §11.1, §11.4 | why signing left this epic, why this epic is last, and the skills |

## Tasks

Strictly ordered on the branch, one commit each. **T03 is the one whose long pole is calendar, not
code** — it needs two physical devices in your hand, one of them the oldest supported. Start borrowing
the low-end Android on day one; its commit still lands third.

| Task | Depends on | One line |
|---|---|---|
| [N34-T01](N34-T01-releaseyml-the-version-rules-and-the-app-size-budget.md) | N33-T09 | `release.yml`, the version rules and the app-size budget |
| [N34-T02](N34-T02-obfuscation-and-the-off-machine-symbols-archive.md) | N34-T01 | Obfuscation and the off-machine symbols archive |
| [N34-T03](N34-T03-startup-measured-on-two-real-devices-in-profile-mode.md) | N34-T02 | Startup measured on two real devices, in profile mode |
| [N34-T04](N34-T04-the-seasonal-freeze-and-the-manual-pre-release-checklist.md) | N34-T03 | The seasonal freeze and the manual pre-release checklist |

## Demoable on merge

`git tag v1.0.0` produces a signed AAB, eight goldens and a symbols archive kept off the
laptop. Concretely, once this epic is on `main`:

| What | The command or the place to look |
|---|---|
| One tag runs three workflows | `git tag v1.0.0 && git push origin v1.0.0` → `release.yml` (tag only), `goldens.yml` (N33-T09, tag or dispatch) and `ci.yml` (its `push` trigger includes `tags: ['v*']`) |
| The artefact carries the tag's name and the run's number | the run's summary: `--build-name=1.0.0 --build-number=<run_number>`, and the same two values arrive in the binary as `kAppVersion` / `kAppBuild` through `--dart-define` |
| The AAB is signed by a keystore that never entered git | the `Write the upload keystore` step decodes `SHEDBOOK_KEYSTORE_BASE64` into `android/upload-keystore.jks` at build time (N32-T01) |
| G1 still holds on the artefact you would actually upload | `bash tool/assert_permissions.sh` inside the release job — seven `uses-permission` lines, `INTERNET` not the eighth |
| The size number exists and is diffable | `build/size/*code-size-analysis*.json` in the run artefacts; open two of them side by side in `dart devtools` → *Open app size tool* |
| A release stack trace can be read again | `flutter symbolize -i crash.txt -d symbols-archive/1.0.0+<build>/android/app.android-arm64.symbols` |
| Nothing under `symbols-archive/` is in git, and that is deliberate | `git ls-files symbols-archive/` prints nothing; `.gitignore` names it; `RELEASES.md` says where they actually live |
| The performance claim is a measurement, not an intention | `docs/perf/measurements.md` — two rows, two physical devices, one of them the oldest supported, each with device, OS version and date |
| The freeze is executable | `M=03 HEAD_COMMIT_MESSAGE='fix: a layout bug' bash tool/freeze_check.sh` exits 1 and names §11.1 |
| Everything a pipeline cannot see has an owner | `docs/release-checklist.md` — eleven items, the five §12 questions, and §11.1's bar written down before anyone is tempted to argue with it |

## The pull request, concretely

One branch, one pull request, four commits, then delete the branch. Nothing here starts before N33's
PR is merged and `main` is green (`00-PLAN-CRITIQUE` §10, *"One PR per epic"*).

1. **Cut the branch from the merged `main`.**

   ```bash
   git switch main && git pull --ff-only
   git switch -c epic/n34-release-engineering
   ```

2. **One commit per task, in task order**, each message in the project vocabulary
   (`CONVENTIONS §5`; no `draft`, no `save()`, no `sync`, no `Error` as a failure name). Each task file
   names its own subject line. **None of `00-README` §7.4's four stated exceptions applies here** — no
   toolchain bump, no golden re-baseline, no `[exempt]` line, no schema change — so four commits, no
   more.

3. **Push and open the pull request after the first commit, not after the last.**

   ```bash
   git push -u origin epic/n34-release-engineering
   gh pr create --web
   ```

   **Never `gh pr create --fill`** — it takes the body from the commit messages and skips
   `.github/pull_request_template.md` entirely, which is where the five §12 questions live.

4. **Wait for the pipelines.** Four jobs run for this epic, and **the workflow this epic authors is not
   one of them.**

   | Job | Runner | What it proves for *this* epic |
   |---|---|---|
   | `gate` | `ubuntu-latest` | `.fvmrc` and `ci.yml`'s `FLUTTER_VERSION` still agree — this epic adds a **third** `env:` block carrying `3.44.8`, so the four-places problem is now real · `check_policy` (G2 + G3) · `dart format --set-exit-if-changed` over the new Dart test files · `analyze --fatal-infos --fatal-warnings` |
   | `codegen` | `ubuntu-latest` | `build_runner` + `make-migrations` produce no diff. This epic touches no schema, so a red `codegen` here means something else on the branch regenerated — read it, do not re-run it |
   | `test` | `ubuntu-latest` **+ `libsqlite3-dev`** | the three new `test/policy/` files run · `TZ=Europe/London --tags uk-zone`, **unscoped**, which is the step that actually executes T04's two DST cases and T03's date case — a `test/domain` path scope would run them in the runner's UTC where the spring-forward case passes vacuously (12 §14 amendment A) · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` |
   | `android` | `ubuntu-latest` | a release AAB is still buildable and **G1** still passes on it, and **G4**'s merger report is archived. This is the only per-PR job that produces an artefact resembling what a tag will produce |

   **`release` and `goldens` do not run on this pull request and cannot be made to.** `release.yml`'s
   only trigger is `push: tags: ['v*']`; `goldens.yml`'s are `v*` and `workflow_dispatch` (13 §4.2,
   §4.4, §4.5). This is the epic that authors a workflow it is structurally unable to watch, which is
   why every task file below ends in commands that run the same build **locally**, and why the risk
   table treats the first tag as the first run.

5. **Answer the five §12 questions in the PR body.** The template pre-fills them (N01-T07). For this
   epic §12.3 is the live one: an AAB, a store listing and a set of release notes are all artefacts a
   shepherd could take as a regulatory claim, and `tool/check_policy.dart` cannot see any of them.

6. **Review the diff in irreversibility order** (`CODE-REVIEW-CHECKLIST` §3.1). For this epic that is:
   `.gitignore` and `.github/workflows/release.yml` first, then `RELEASES.md` and
   `docs/release-checklist.md`, then `docs/perf/measurements.md`, then the three test files. Nothing in
   this epic touches `lib/`.

7. **Merge, delete the branch, confirm `main` is green — and only then tag.**

   ```bash
   gh pr merge --squash --delete-branch
   git switch main && git pull --ff-only
   gh run list --branch main --limit 1
   ```

   The tag is a separate, deliberate act taken against a green `main`, after
   `docs/release-checklist.md` has been worked top to bottom. It is not part of merging this epic.

## Risks, and what is irreversible here

**This epic contains no schema change and no migration. It contains four other things that cannot be
undone, and three of them cannot be undone by anyone, ever.**

| Risk | Why it bites | Where it is held |
|---|---|---|
| **An update is irreversible on someone else's phone the moment they take it.** No server-side rollback, no feature flag, no remote kill switch — by design (13 §11). A regression shipped on 3 March costs a shepherd a night of records that cannot be reconstructed, in an app whose only backup is one they remembered to make | N34-T04. This is the entire argument for the freeze, and it is why the freeze is the one thing in this epic that outranks the other three |
| **The symbols archive is the only artefact whose loss cannot be recovered by rebuilding** (13 §9.4). A rebuild from the same tag produces *different* obfuscation mappings. Lose `symbols-archive/1.0.0+187/` and every stack trace in every diagnostics log a user ever sends for build 187 is permanently unreadable — and the diagnostics log is the only diagnostic channel this app has, because there is no reporter and no network | N34-T02. `symbols-archive/` is git-ignored, which means **nothing in CI can file them for you**; it is checklist item 11 and a human step |
| **A build number is spent the moment a store sees it.** Both stores reject a re-used one. There is no "undo the upload" — a failed upload does not give the number back; you push a new tag and take a new run number | N34-T01. `--build-number=${{ github.run_number }}` removes the temptation, and the anti-pattern list in 13 §9.1 names hand-editing it, re-using one, and re-tagging to fix a pubspec typo |
| **There is no rehearsal tag.** `tags: ['v*']` matches `v0.0.1`, `v1.0.0-rc1` and anything else beginning with `v`; `release.yml` declares no `workflow_dispatch`. Any tag you push "just to see" is a real release build against real signing secrets, and it spends a run number | N34-T01. Rehearse with the local build commands in each task's §8, and make the first tag `v1.0.0` on purpose |
| **The application id / bundle id can never change on either store** (13 §3.1). It was fixed in N01-T01; this epic only records it in `RELEASES.md`'s header. If the two platforms ever disagree, discovering it here is late but survivable — discovering it after the first upload is not | N34-T01's `RELEASES.md` header, read out of `android/app/build.gradle.kts`, never typed |
| **The eight notification channel ids are frozen at the first release** (R49, 13 §11.2): `colostrum`, `navel`, `turn_out`, `tag_by`, `ring_dock_castrate`, `second_dose`, `withdrawal_end`, `custom`. Changing one afterwards silently orphans every scheduled reminder on every installed device. Decision #65's `turnout`, `dose` and `withdrawal` are superseded and are banned channel ids | N34-T04, checklist item, asserted against the committed schema JSON before the first release — not before the first snapshot |
| **A single number from an emulator poisons the only performance record the project has.** Profile mode is disabled on emulators and simulators, so any number from one is noise (#126). There is no telemetry, so `docs/perf/measurements.md` is not *a* record, it is *the* record | N34-T03. The file's own header sentence says it; the anchor test enforces it against the device column |
| **`--analyze-size` gates nothing today, deliberately, and inventing a threshold now is the failure mode.** The number worth gating — arm64 download size — does not exist until after upload; the number CI can read has no baseline, so any threshold committed today is a guess that gets edited the first time it fires (13 §6.1.1's narrowing of #126). The real gate is the release **after** this one: a 5% growth check against the previous tag's archived JSON | N34-T01. The DoD line *"the budget is asserted"* means asserted on the **workflow**, not on a byte count |
| **The 12-tester / 14-day clock must not land inside the freeze** if the plan is to ship straight after it (13 §10.2). That clock started at N32; this is the epic where the two calendars collide | N34-T04 writes the freeze rows into `docs/calendar.md`, held by `test/policy/calendar_commitments_test.dart` — which by this epic is **in** the blocking set, so an empty row is a red build |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test` · `android`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] the version now lives in **four** places and no more — `.fvmrc`, `ci.yml`, `goldens.yml`, `release.yml` — and every one of the three workflows runs 13 §1.1's three-line assert
- [ ] every build command in every workflow carries `--dart-define=APP_VERSION` / `APP_BUILD` beside `--build-name` / `--build-number`, so no shipped binary can log `0.0.0+0`
- [ ] `RELEASES.md`, `docs/perf/measurements.md` and `docs/release-checklist.md` all exist, are linked to each other, and none of the three is a second copy of anything in `docs/engineering/13-build-ci-release.md`

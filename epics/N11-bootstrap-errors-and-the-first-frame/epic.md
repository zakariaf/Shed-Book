# N11 — Bootstrap, errors and the first frame

| | |
|---|---|
| **`00-README` §9 step** | 4 (3 of 3) |
| **Ships in** | `v1.0.0` |
| **Depends on** | N10 |
| **Size** | L |
| **Was** | E09a — the half that touches native files |
| **Branch** | `epic/n11-bootstrap-and-first-frame` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` — **and `android`, which for this epic is a real gate**, because T06 is the first change to `android/` since N02 |
| **Machine** | T06 needs the Android SDK and **a real Android phone**; T07 needs **a Mac with Xcode and a real iPhone**. This is the first epic in the plan that cannot be finished on a Linux box, and the first whose Definition of Done contains the words *"watched on a real device"* |
| **Touches native files** | **Yes** — `android/app/src/main/res/`, `MainActivity.kt`, `ios/Runner/Info.plist` and both storyboards |

## Goal

`main()` awaits nothing, the error net is installed before `runApp`, the first painted frame
is the page colour on both platforms, and a thrown widget renders a panel a shepherd can read in the
dark instead of red-on-yellow.

Concretely, nine commits produce: the sealed `ShedFailure` (six variants) and `WriteOutcome` (three)
that every repository in the next twenty epics returns; the **one** function that turns a
`SqliteException` into a `ShedFailure`; a twenty-line `main.dart` with no `await` in it; `ShedBookApp`
with the post-frame boot kick, the localisation delegates and the lifecycle observer; the four
launch layers on each platform set to one colour; the gate that proves they stay equal; and
`LocalLog` — the app's only diagnostics sink, redacted, bounded, and able to tell *the shepherd
closed it* from *the phone died mid-write*.

**One open conflict is ruled inside this epic and its losing documents amended in the same commit:
P14** — `NightErrorPanel`'s `#0B0D0E` against Indelible's `--page` `#0A0A0B` (T04). It is not
optional and it is not deferrable: `launch.colour_parity` compares the native launch colour to
`nSurface04`, and if both hexes are still live when T06 runs, the gate is comparing a value to itself
while the error panel quietly uses the other one.

## Why the epic sits here

`00-README` §9 puts this at **step 4**, immediately after the schema freeze (step 3, N07 + N08) and
immediately before Quick Entry (step 5, N13 + N14). Its stated reason, not re-derived here:

> *"The first frame is the product's promise, and the no-white-flash work touches native files you do
> not want to revisit. Everything after this runs inside a real app."*

Three consequences bind this epic's scope:

- It comes **after** N09 and N10 because `nSurface04` (N09-T01) is the value the native launch layers
  must equal, and `buildShedTheme` (N09-T04) is what `app.dart`'s `MaterialApp` hands its theme
  slots. A first frame written before the theme set is a first frame you rewrite.
- It comes **before** N12 because N12's harness, its seven fakes and `WriteController.guard()` all
  need `WriteOutcome` and `ShedFailure` to exist as types (`02 §7`), and `providers.dart` needs a
  running app to be wired into.
- It comes **before** every screen because after this commit series *"everything runs inside a real
  app"* — N13 pumps `QuickEntryScreen` into a `MaterialApp` this epic built, not into a bare
  `WidgetsApp` a test invented.

`00-README` §9's two parallel tracks apply here as they did in N09: the **ARB** (T05 wires the
delegates and `supportedLocales` — critique gap G3, which no task in the old plan owned) and
**accessibility** (T05 wires `accessibility_tools` behind `kDebugMode` — critique gap G4, a declared
dev dependency nothing installed). Neither is a later sweep; N33 only verifies.

## What is observably true when this epic merges

Run these on the merged `main` and watch them pass — this is the demo:

```bash
fvm flutter test test/domain/failure_test.dart \
                 test/data/failure_mapping_test.dart \
                 test/data/local_log_test.dart \
                 test/features/night_error_panel_test.dart \
                 test/features/app_test.dart \
                 test/policy/main_awaits_nothing_test.dart \
                 test/design/first_frame_parity_test.dart
make check                       # includes launch.colour_parity — the one gate rule that reads outside lib/
TZ=Europe/London fvm flutter test --tags uk-zone
```

- **`grep -c 'await' lib/main.dart` is 0**, and `main_awaits_nothing_test.dart` proves the three
  hooks are installed before `runApp` by reading the source, not by running it — because the
  property is about the *shape* of the function.
- **The app launches on a real Android phone and a real iPhone to a dark first frame with no white
  flash.** Not a screenshot test: a cold launch in a genuinely dark room, watched by eye, on both
  platforms. `06 §9.4` is explicit that a screenshot test cannot catch this — the flash is on the
  native side, before Flutter runs.
- **A deliberately thrown widget renders `NightErrorPanel`**, not the framework's red-on-yellow, and
  it renders with **no** `MaterialApp`, `Theme`, `MediaQuery` or `Directionality` ancestor — proved
  by a widget test that pumps it bare.
- **P14 is closed in writing**, and the four documents and two source files that carried the losing
  hex are amended in the same commit.
- **`ShedFailure` has six variants and `WriteOutcome` three**, neither is generic, no variant is
  named `Ok` or `Error`, and every `userMessage` is a sentence a cold shepherd could act on.
- **`shedFailureFrom` is the only site in `lib/` that names a SQLite result code.**
  `grep -rn 'SqliteException' lib/` returns one file.
- **The Android and iOS launch colours equal `nSurface04` and each other**, asserted by
  `tool/check_policy.dart`'s `launch.colour_parity` — which parses XML and a plist, and names the
  drifting file when it fails.
- **The diagnostics log holds no tag, no note text and no withdrawal period**, and a killed session
  is reported on the next launch as a fact rather than repaired.
- **`.instance` appears in `lib/` exactly once outside the SDK's own** (`LocalLog.instance`).
  `WidgetsBinding.instance` and `PlatformDispatcher.instance` are the framework's, in `main.dart`
  and `app.dart`.

Deliberately **not** demonstrable yet, and the reason for each: there is no `pumpApp` (N12-T05, and
it builds only what exists), no `databaseProvider` graph beyond the one entry T05 needs, no
`QuickEntryScreen` behind `home:` (N13-T05), no `Routes.navigatorKey` (N13-T01), and no golden of the
first frame — goldens are `v*` or manual dispatch only and the eight images are N33-T07.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/01-architecture.md` | §5.1 (the complete failure set) · §5.2 (`WriteOutcome`) · §5.3 (`ShedFailure` + `shedFailureFrom`) · §5.4 (returned vs thrown) · §5.5 (the global error net, `NightErrorPanel`'s three hard constraints, `LocalLog`'s surface) · §5.6 (`RecoveryScreen`) · §6.1–§6.3 (`main()` verbatim, line by line, and what happens after the first frame) | every type, every signature, the twenty lines of `main()` |
| `docs/engineering/02-state-di-navigation.md` | §4.6 (where providers are declared; the one deliberate static) · §5.1–§5.2 (the DI graph; production has no overrides) · §9 (why there is no state restoration) · §9.1 (`ResumePolicy`, the lifecycle switch, the five non-stylistic details) | `ShedBookApp`'s shape, the observer, the resume policy |
| `docs/engineering/06-design-system.md` | §1 (what a direction may change — **this is what rules P14**) · §2.1 (`MaterialApp`, four theme slots) · §2.4 (the error widget renders outside any theme) · §9.1–§9.4 (the four launch layers per platform and the parity gate) | the theme half of `app.dart`, every native file, the colour |
| `docs/engineering/08-platform-integration.md` | §1.1–§1.2 (the gateway rule and `_confinedPackages`) · §8.3–§8.4 (the final Android and iOS key sets) | which file may import `path_provider`; what must **not** change in the manifest or plist |
| `docs/engineering/13-build-ci-release.md` | §7.1–§7.5 (`session.lock`, `markCleanPause()`, re-arming, dirty-resume detection) · §8.1–§8.6 (why there is no crash reporter, the two handlers, the rolling log, the redaction list) · §9.1.1 (`kAppVersion` / `kAppBuild`) · §4.3 (the four CI jobs) | all of T09, and what each pipeline proves |
| `docs/engineering/10-accessibility-and-i18n.md` | §8.2 (`l10n.yaml` and the `MaterialApp` localisation block) · §8.3 (the `supportedLocales` ordering trap) · §8.7 (why `NightErrorPanel` is hard-coded English) | T05's delegates and locale list |
| `docs/engineering/CONVENTIONS.md` | §1 + §1.1 (the tree and the eight layer rules, incl. `layer.root`) · §2.4–§2.5 (the write path and the error types, verbatim) · §3.1 (`databaseProvider`) · §4.7 (rule-id grammar; the four `[exempt]` lines) · §5.2–§5.3 (the banned words) · R4, R8, R11, R29, R34, R52, R56 | **BINDING** on every path, type, provider, column and word |
| `docs/design/indelible.md` | §2.2 (`--page` `#0A0A0B`, and why it is not pure black) · §2.5 (the contrast table measured **on `#0A0A0B`**) · §5.2 (*"the first painted frame is `--page`… no white flash, ever"*) · §11 test 9 (the 240 fps first-frame test) | the value P14 rules for, and the acceptance test |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · §1 #4 · #14, #21, #90, #100, #105, #123, #124 | `main()` awaits nothing; the error net; the first frame is entitlement-agnostic; redaction |
| `epics/00-PLAN-CRITIQUE.md` | §8 G3 (the ARB is never bootstrapped) · §8 G4 (`accessibility_tools`; P14 ruled in one place and applied in three) · §9 change 14 (E09 → N11 + N12) · §10 (the workflow rules) | why T05 carries two gaps nobody owned, and why P14 lands in T04 |

## Tasks

Strictly sequential: each task depends on the one before it. The order is not arbitrary —
`shedFailureFrom` cannot compile without `ShedFailure`; `main.dart` names `LocalLog`, `ShedBookApp`
and `NightErrorPanel`; the parity gate has nothing to compare until both platforms are configured.

| Task | Depends on | One line |
|---|---|---|
| [N11-T01](N11-T01-shedfailure-and-writeoutcome.md) | N10-T08 | `ShedFailure` and `WriteOutcome` |
| [N11-T02](N11-T02-shedfailurefromobject-the-one-mapping-site.md) | N11-T01 | `shedFailureFrom(Object)` — the one mapping site |
| [N11-T03](N11-T03-maindart-twenty-lines-nothing-awaited.md) | N11-T02 | `main.dart` — twenty lines, nothing awaited |
| [N11-T04](N11-T04-nighterrorpanel-and-the-p14-ruling.md) | N11-T03 | `NightErrorPanel` and the P14 ruling |
| [N11-T05](N11-T05-appdart-shedbookapp-the-boot-kick-and-the-localisations.md) | N11-T04 | `app.dart` — `ShedBookApp`, the boot kick, and the localisations |
| [N11-T06](N11-T06-no-white-flash-the-android-layers.md) | N11-T05 | No white flash — the Android layers |
| [N11-T07](N11-T07-no-white-flash-the-ios-layers.md) | N11-T06 | No white flash — the iOS layers |
| [N11-T08](N11-T08-the-first-frame-parity-gate.md) | N11-T07 | The first-frame parity gate |
| [N11-T09](N11-T09-locallog-redaction-and-dirty-resume-detection.md) | N11-T08 | `LocalLog`, redaction and dirty-resume detection |

**Two files are written twice in this epic, and that is deliberate.** `lib/core/log/local_log.dart`
lands at T03 in the minimum shape `main()`'s two handlers require — the singleton, the bounded
in-memory ring buffer, `write` and `flutterError` — and T09 grows it into the redacted, rotating,
`session.lock`-carrying log. `lib/app.dart` lands at T03 as the ~15-line `ShedBookApp` shell
`runApp` names, and T05 grows it into the real thing. A twenty-line `main()` names three
collaborators and the commit does not compile without all three; pretending otherwise produces a
commit that is green in a task file and red in CI.

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N10 is merged and `main` is green before this starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version              # must print 3.44.8; .fvmrc is the pin
git checkout -b epic/n11-bootstrap-and-first-frame
```

**2 — One commit per task, nine commits, in task order.** Each task file names its commit line
verbatim; use it. Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test         # randomised order, + TZ=Europe/London --tags uk-zone
```

Two commits in this epic carry an obligation beyond the ordinary:

- **T03** touches `lib/main.dart`, which `00-README` §10 puts on the **never waved through** list
  alongside `lib/domain/withdrawal/**`, `drift_schemas/**`, the `[exempt]` allowlist and
  `disclaimers.dart`. However small the diff, it is read line by line.
- **T04** is the P14 ruling. `00-README` §10's amendment rule applies in full: *"a change to a
  decision requires updating the decision record and every document that applies it, in the same
  change."* The complete amendment list is in T04 §5.3. A commit that changes the hex in the code
  and leaves four documents asserting the old one is worse than no ruling, because both look
  authoritative.

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the
diff in `00-README` §10's irreversibility order. For this branch that order is:
`android/` and `ios/` (native config, and where a permission could enter) →
`tool/check_policy.dart` and `tool/policy_allowlist.txt` →
the `docs/` amendments made by the P14 ruling →
`lib/main.dart` and `lib/app.dart` →
`lib/core/failure.dart`, `lib/core/write_outcome.dart`, `lib/data/failure_mapping.dart` →
`lib/core/log/` and `lib/core/ui/night_error_panel.dart` →
`test/`.

**4 — Open the PR and answer the five §12 questions** in `.github/pull_request_template.md`
**verbatim, in the PR body**. Three of the five land here and must not be answered "not applicable":

- **§12.3 (never a compliance record)** — `NightErrorPanel`'s single action is *"Save a copy of my
  records"*; it must not imply the app is an official record of anything.
- **§12.4 (never silently correct an entry)** — the dirty-resume detection in T09 is **reported and
  never acted on**. An app that repairs itself after a crash is an app that hides the bug.
- **§12.5 (timestamps carry provenance)** — every timestamp T09 writes is machine-captured by
  `appNow()`; the Diagnostics screen states that once at the top rather than labelling each line,
  and a diagnostics line **never renders a `RecordedTime` from a real record** (`13 §7.5`).

The other two — §12.1 (never default a withdrawal period) and §12.2 (never give veterinary advice) —
this epic does not reach; say so, and say which epic would have (N05 and N06 respectively).

**If P14 could not be closed, the PR body carries the conflict with both sides cited** and T06's
anchor is downgraded in writing before it merges — not silently.

**5 — Wait for the pipelines.** Four jobs run for this epic and each proves a different thing.
`android` is not a formality here: it is the only job that reads a shipped artefact, and T06 is the
first change to `android/` since N02.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` · the `NSAppTransportSecurity` grep (**G5**, text half) | `main.no_await` fires on `lib/main.dart`; `layer.root` proves `main.dart` and `app.dart` import no drift and no `lib/core/db/`; `launch.store_call` proves neither file names `PurchaseService`; `token.raw_color` still has exactly the four `[exempt]` lines after `night_error_panel.dart` gains its hexes; and from T06 onward **`launch.colour_parity`** — the one rule in the script that reads outside `lib/` — compares the native config to `nSurface04`. The `NSAppTransportSecurity` grep matters here because T07 is the first edit to `Info.plist` |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | A **negative**, and that is the point: N11 touches no table, so nothing under `drift_schemas/` may move. If this job is red on this branch, something in `lib/` has pulled a second generator into the build, or `flutter: generate: true` silently regenerated `lib/l10n/app_localizations*.dart` under T05 and it was not committed |
| `test` | `libsqlite3-dev` on the runner · `flutter test -P ci-fast` randomised · `TZ=Europe/London --tags uk-zone` · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · the coverage artefact (reported, **never** gated) | The seven test files this epic writes. The `uk-zone` leg matters for **T05** (`ResumePolicy` across the ambiguous hour, where the wall clock moves backwards and the elapsed time does not) and **T09** (a `session.lock` written at 01:30 BST and read at 01:30 GMT is an hour apart in UTC and must stay that way). An untagged DST case passes for the wrong reason, in the runner's own zone |
| `android` | release AAB built with `--obfuscate --split-debug-info` · **G1** (`tool/assert_permissions.sh` over the merged manifest) · **G4** merger report archived | That T06 changed the launch theme and **not the permission set**. `AndroidManifest.xml` is the file T06 edits and the file G1 exists to police; N02's recorded G0 evidence is the only authority for what may be in it. This is the job that turns *"I only added one attribute"* into a fact |

Goldens do **not** run on this PR (`v*` or `workflow_dispatch` only, 10× macOS multiplier). The
first frame is verified by eye on two devices and by `launch.colour_parity`, not by a PNG.

**6 — Merge, delete the branch, and only then cut N12.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git checkout main && git pull --ff-only
# confirm main is green, then:
git checkout -b epic/n12-di-root-and-harness
```

N12 grows `lib/data/providers.dart` from the single entry T05 needed into the DI root, and builds
the harness every screen epic pumps through. Cutting it from anything other than a green merged
`main` means a provider graph rebased onto a moving `WriteOutcome`.

## Risks, and what is irreversible

**Irreversible in this epic — say it out loud in the PR body:**

- **The P14 ruling and its document amendments (T04).** A hex is trivially revertible; a decision
  applied across five documents is not, and a half-applied one is the failure the amendment rule
  exists to prevent. T04 §5.3 lists every site. Nothing else in this epic requires an owner.
- **`AndroidManifest.xml` and `ios/Runner/Info.plist` (T06, T07).** Not irreversible in git, but
  irreversible in *claim*: the moment a permission or an ATS exception lands in a shipped artefact,
  the offline-purity wording in the contract stops being true and three screens' copy changes with
  it. **Do not add a line to either file that is not in `13 §3.1` / §3.2.** If you think you need
  one, that is an N02 conversation and G0 is the evidence.
- **Deleting a key from `Info.plist`.** `UILaunchStoryboardName` and
  `UIApplicationSceneManifest`→`UISceneStoryboardFile` are **different keys naming different
  storyboards**. Deleting the wrong one produces a white launch screen *and* an App Store rejection,
  and you find out weeks later.
- **The six `ShedFailure.userMessage` strings (T01).** They are six of the only ten user-facing
  strings outside the ARB in v1 (`10 §8.7`'s closed exception list), they render when the database
  is unreadable, and they are what a shepherd reads at 3am when something has already gone wrong.
  Adding a seventh ARB exception is a review conversation, not an edit.

**Not irreversible, and must not appear in this diff at all:** `drift_schemas/`,
`lib/core/db/tables/`, `lib/domain/`. **If a file under any of those shows up on this branch, stop
and find out why.** This epic stores nothing new and computes nothing new; the schema froze at N07
and the domain finished at N06.

| Risk | Why it bites here | What holds it |
|---|---|---|
| **`main.dart` names three collaborators that do not exist yet** | T03 is the third task but `ShedBookApp` is T05, `NightErrorPanel` is T04 and `LocalLog` is T09. A commit that does not compile fails `make check`, which is in every task's DoD | Stated above and in T03 §5.1: `app.dart` and `local_log.dart` land at T03 as minimum compiling surfaces and are grown by T05 and T09. `ErrorWidget.builder` — the third hook — is installed at **T04**, with the panel it renders. T03's anchor test says *"both handlers"*, two, and it means two |
| **`databaseProvider` and `themeProvider` are N12's, but `app.dart` names both** | `02 §9.1` prints `ref.read(databaseProvider.future).ignore()` inside `initState`, and `06 §2.1` prints `ref.watch(themeProvider)` inside `build`. Neither provider exists at N11, and **`layer.root` forbids `lib/app.dart` from importing `lib/core/db/`**, so `app.dart` cannot call `openAppDatabase()` directly instead | T05 §5.3 rules it: `lib/data/providers.dart` is created here holding **exactly `databaseProvider`**, and N12-T01 grows it. `themeProvider` is *not* created — `MaterialApp` takes the const `night` pair directly, which is precisely what R29 makes `themeProvider`'s not-yet-loaded arm return, so N12-T02's swap is one line and invisible on screen |
| **`WidgetsBindingObserver` compiles and never fires** | `with WidgetsBindingObserver` alone does nothing. Without `addObserver(this)` in `initState`, `didChangeAppLifecycleState` looks like a valid override and is never called — so the resume policy, the wakelock release and the clean-pause marker all silently stop existing, and no test, lint or analyzer notices | `02 §9.1` names this as the first of its five non-stylistic details. T05's test set drives `hidden` → `resumed` through the tester and asserts the observer actually ran |
| **P14 is already decided *de facto* and nobody noticed** | Every contrast ratio `indelible.md` §2.5 publishes — 16.19, 7.80, 5.75, 5.59, 3.52, 3.88 — was measured on `--page` `#0A0A0B` (L 0.00306). `contrast_test.dart` (N09-T08) recomputes them. On `#0B0D0E` (L 0.00391) the first one is **15.93**, not 16.19, so N09 is only green if `nSurface04` is already `#0A0A0B` | T04 makes the ruling written and amends the four documents and two source files that still say `#0B0D0E`. If N09 shipped `#0B0D0E` *and* a green suite, something is wrong with `contrast_test.dart` and that is the finding, not the hex |
| **The iOS half of `launch.colour_parity` has never been run** | `06 §9.4` and `REFERENCES` §22 D10 both flag it: the storyboard stores colour as floats in XML and parsing them may prove brittle. A brittle gate gets weakened, and the rule it was weakened from is the one holding the first frame | T07 and T08: compare to within 1/255, and if it proves brittle **downgrade that one assertion to the release checklist in writing rather than weakening the rest**. Downgrading silently is the anti-pattern |
| **A new gate row with no proving case** | N03-T07's inventory assertion fails any rule id in `tool/check_policy.dart` with no entry in `test/policy/gate_rules_test.dart`'s `firesOn` map — and it fails in the reverse direction too | T06 and T08 add `launch.colour_parity` to both, in the same commit. The id must match `^(layer\|net\|time\|rp3\|stream\|db\|stat\|a11y\|gesture\|token\|theme\|type\|ui\|main\|dep\|launch\|copy\|media)\.[a-z0-9_]+$` |
| **`values-night/` looks like the right thing to add** | Every Android dark-theme guide says use `?android:attr/colorBackground` so the splash follows the system theme. In a dark-only app that is exactly backwards: a phone in light mode then launches **white** | `06 §9.1` bans the folder outright and `launch.colour_parity` asserts it does not exist. The same rule bans the deprecated `SplashScreenDrawable` meta-data, which the Flutter migration doc says can cause a crash |
| **The diagnostics log becomes the crash** | Every failure inside `LocalLog` is swallowed, deliberately. It is also the code most likely to run while the disk is full or the process is being killed | `13 §7.3` and §8.3: crash-path writes are `writeAsStringSync(flush: true)` and bypass the stream sink; every method is wrapped; the cap is 256 KB with one rotation so the log can never contribute to the disk-full failure it is recording |
| **A `SqliteException` message reaches a log or a SnackBar** | SQLite exception messages echo the failing SQL and sometimes bound values — ewe tags, note text, batch numbers. `e.toString()` in a log line is a spec §4.5 violation that looks like diligence | T02 and T09: log `resultCode` / `extendedResultCode` plus an identifier you control, never the message. `DatabaseUnreadable(resultCode, extendedResultCode)` exists precisely so the two integers travel without it |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] **`android` is green**, and its G1 step proves the permission set is byte-identical to `android/expected_permissions.txt` after T06
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] **P14 is closed by a ruling that amends every document and source file listed in T04 §5.3 in the same commit**, or carried into the PR body as open with both sides cited — never silently resolved
- [ ] `lib/main.dart` contains no `await`, no `runZonedGuarded`, no `exit(`, and no reference to `lib/core/db/` or `PurchaseService`
- [ ] all three error hooks are installed synchronously before `runApp`, and `ErrorWidget.builder` is set exactly once, never inside a `build()`
- [ ] `NightErrorPanel` builds with no `MaterialApp`, `Theme`, `MediaQuery` or `Directionality` ancestor
- [ ] `tool/policy_allowlist.txt`'s `[exempt]` section still has **exactly four lines** (R56) — `night_error_panel.dart :: token.raw_color` was created at N09-T01 and is used, not duplicated
- [ ] `launch.colour_parity` exists in `tool/check_policy.dart`, has a `firesOn` entry in `test/policy/gate_rules_test.dart`, and passes — or its iOS storyboard half is deferred to the release checklist **in writing**
- [ ] a cold launch on a real Android phone **and** a real iPhone, in a genuinely dark room, shows no frame brighter than the page colour on either
- [ ] `.instance` appears in `lib/` only as `LocalLog.instance`, `WidgetsBinding.instance` and `PlatformDispatcher.instance`
- [ ] the diagnostics log contains no value drawn from `13 §8.4`'s forbidden column, proved by a test in `test/policy/`
- [ ] the words *crash log*, *telemetry* and *analytics* appear nowhere in the diff, including comments
- [ ] the diff contains no file under `drift_schemas/`, `lib/core/db/tables/` or `lib/domain/`

## Demoable on merge

The app launches on a real Android phone and a real iPhone to a dark first frame with **no
white flash**, and a deliberately thrown widget renders `NightErrorPanel`.

## Notes

**What this epic does not build, and where it lands instead.** `RecoveryScreen` (`01 §5.6` — the one
failure a screen cannot handle) is not here: it needs `databaseProvider` to be capable of failing,
which needs N12's graph and N23's restore path. `showFailure` / `confirmSaved` / `showCapRow` are
N09's `feedback.dart`, already merged. `WriteController.guard()` — the only consumer of
`UnexpectedFailure`'s second construction site — is N12-T04. The `Settings ▸ Diagnostics` sub-screen
that surfaces T09's last-20-events list is N29; T09 writes the log, not the screen.

**`test/` has no `core/` directory** (R57 fixes the eight test directories). Pure-Dart tests for
types under `lib/core/` therefore live in `test/domain/`, which is why T01's anchor is
`test/domain/failure_test.dart` for a file at `lib/core/failure.dart`. That is the convention, not a
mistake — do not create a ninth directory to fix it.

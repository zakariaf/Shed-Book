# N33 — Ship gates: the sweeps, the matrix, the goldens and the journeys

| | |
|---|---|
| **`00-README` §9 step** | cross-cutting, before 12 |
| **Ships in** | `v1.0.0` |
| **Depends on** | N32 |
| **Size** | L |
| **Was** | E28, plus `goldens.yml` moved here from E30 |
| **Branch** | `epic/n33-ship-gates` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` · `android` |
| **Machine** | A laptop with the pinned Flutter, `libsqlite3` ≥ 3.41, one physical Android phone and one physical iPhone for the manual sweep, a dark room and a head torch. A browser for App Store Connect and for `gh workflow run goldens.yml` |
| **Touches `lib/`** | **Only where a gate goes red.** N33 authors no feature. T03 is the one task expected to force layout edits under `lib/core/ui/components/` and `lib/features/`, because it is the first run of the geometric gate against real screens |

## Goal

The assertions that can only run once every screen exists — and the eight golden images,
verified by CI **in the epic that creates them** rather than two epics later.

Concretely, N33 grows `kPumpableVariants` to its final fourteen entries and turns the 252-cell overflow
matrix on; authors `test/design/semantics_gate_test.dart` and the 84-run geometric half of
`test/design/tap_target_test.dart`; **rules P9**, the 16 pt-versus-8–12 px separation conflict, and
amends the losing document; adds the three reachability assertions and the colour-never-alone sweep;
sweeps the ARB; declares Apple's Accessibility Nutrition Label against evidence that exists; commits
eight PNGs in a commit of their own; lands the four integration journeys; and creates
`.github/workflows/goldens.yml` so those PNGs have a machine that looks at them.

**Nothing in this epic authors accessibility or copy.** Both were authored inside every widget task
from N13 onward — `00-README` §9's two parallel tracks, in as many words: *"the accessibility rules
(they are widget-authoring rules, and retrofitting semantics across twelve screens is a rewrite) and
the ARB (every string goes through `app_en.arb` from the first one)."* N33 only verifies. If a sweep
in this epic finds a missing `semanticLabel`, the fix is a one-line edit in the screen that omitted
it — not a sweep that lowers its bar.

## Release scope — P15

**`v1.0.0`, whole — and none of it was deferred despite none of it being a feature.**

**T01 is eleven variants, not fourteen.** Reminders, Season Summary and Note Search move to `v1.1.0`
with their screens, so `v1.0.0`'s matrix is **11 × 18 = 198 cells** and `v1.1.0` grows it to fourteen
and 252. The membership test is derived from the built screens rather than from a literal precisely so
this cannot be silently wrong — a half-landed deferred screen fails that test loudly.

**Why nothing here waits.** `v1.1.0` is built between February and May 2027, against a `main` that
`13 §11` forbids releasing from. That is four months of development with **no way to ship a fix**, so
every gate that normally catches a mistake before a shepherd does has to already exist: the eight
goldens (T07), `goldens.yml` (T09), the four integration journeys (T08) and the geometric tap-target
gate (T03).

**`v1.1.0`'s regression armour has to ship before `v1.1.0` starts.** That is the whole argument, and
it is the reason this epic is the one place in the split where "it is not a feature" is not a reason
to move it.

## Why the epic sits here

`00-README` §9's build order front-loads the irreversible and *"reaches pixels late"*. Every assertion
in this epic is downstream of a pixel, so none of them could have been written earlier. Its own
sentences are the argument, and they are not re-derived here:

- The matrix, the sweeps and the goldens iterate **fourteen variants**. Twelve screens plus note search
  land across steps 5–10; the fourteenth variant is Quick Entry with the export banner, which needs
  step 8's four `app_settings` columns. Before that, there is nothing to iterate — which is critique
  defect **S1** and **S7**, made once in the plan this epic replaces.
- Every cell loads `restoreFixture(db, 'flock_400_3seasons.json')`, and the fixture is written by
  `tool/seed.dart` **through the restore path** at step 8 (N23-T05), then regenerated once reminder
  rows have a writer (N24-T08). §9 step 8 says why: the seed *"is what makes 400-ewe profiling, the
  overflow matrix, the goldens and the at-cap monetization tests possible at all."* That is critique
  defect **S3**.
- N33 sits **before** step 12's release engineering but **after** N32, because the critique moved
  signing in front of the sweeps (§10 change 16): Play's fourteen continuous days run in parallel with
  this branch instead of after it. N33 is the longest of the three step-12-adjacent epics and it is the
  one whose calendar can absorb another epic's clock.

Two things N33 is deliberately *not*. It is not the accessibility authoring pass the old plan deferred
— see above. And it is not a place to relax an assertion so a screen goes green: `12 §6.3` names the
three banned "fixes" (delete the cell, clamp `textScaler`, wrap the text in a `FittedBox`) and all
three are build-breaking defects elsewhere in the same doc set.

## What is observably true when this epic merges

Run these on the merged `main` and watch them pass — this is the demo:

```bash
fvm flutter test test/features/overflow_matrix_test.dart      # 252 cells + 3 reachability + the canary
fvm flutter test test/design/semantics_gate_test.dart         # 84 runs + the unlabelled canary
fvm flutter test test/design/tap_target_test.dart             # 84 runs + the 40x40 canary
fvm flutter test test/features/redundancy_table_test.dart     # every state, three palettes
fvm flutter test test/policy/arb_completeness_test.dart
fvm flutter test test/policy/accessibility_label_test.dart
fvm flutter test test/policy/ci_jobs_test.dart
make goldens                                                  # verifies the eight PNGs; never re-baselines
make integration DEVICE=<your phone>                          # four journeys, on a real device
TZ=Europe/London fvm flutter test --tags uk-zone
make check && make test
```

- **252 cells, derived.** `kPumpableVariants.length` is 14, `Device.all.length` is 3, `kTextScales` is
  3 and `kBoldStates` is 2, and the count is the product of those four lists — the same lists the loops
  iterate. Nobody types 252. Decision #114's 216 is 12 × 18 and is superseded with the reason stated
  (`CONVENTIONS` R58).
- **Two canaries fail on purpose and are asserted to fail.** A 40 × 40 target fails the 60 pt guideline;
  a tappable widget with no `semanticLabel` fails `labeledTapTargetGuideline`. A sweep nobody has
  watched fail is indistinguishable from a sweep that asserts nothing.
- **P9 is ruled and the losing document is amended in the same commit.** One number is executable, read
  from `context.tokens.gapMin`, and the other document says the same thing.
- **The primary action is on screen without scrolling** on Quick Entry (banner shown), Lambing Entry
  and Foster, at 375 × 667 × textScaler 1.3 — asserted through `ScrollableState.position`, not through
  `Scrollable.controller`, which is null on every screen in this app.
- **Eight PNGs, in a commit of their own**, rendered with real fonts — no tofu, no Ahem — and compared
  through a comparator that tolerates 0.5 % of pixels and nothing more. Corrupt one by 5 % and four
  images land in `failures/`.
- **`gh workflow run goldens.yml` turns those eight images green on a macOS runner**, and running it on
  a deliberately corrupted PNG turns it red. It has been watched doing both.
- **`make integration DEVICE=…` runs four journeys against a real file on a real phone**, and no
  GitHub job runs them — because `schedule:` cannot drive a device and a device-attached job on a merge
  gate is how you manufacture a flaky CI.
- **`docs/store/accessibility-nutrition-label.md` declares seven features and leaves two undeclared**,
  and every declared claim names the assertion or the dated manual pass that holds it. Captions stays
  undeclared, with its reason recorded.

What is deliberately **not** true on merge: the release workflow, the size and startup measurements,
the symbols archive and the seasonal freeze are **N34**; `goldens.yml` is created here but its
tag-triggered run first happens at N34's `v1.0.0`.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/12-testing.md` | **§6.1–§6.4** (the fourteen variants, the printed matrix, what a failure looks like, the reachability trap) · **§7.1–§7.6** (the real guideline API, `ensureSemantics`, why the built-in matcher is not enough, the cost split, the canary, contrast) · **§8.1–§8.6** (the eight images, the harness, OS/font sensitivity, the re-baselining ritual, what is not used) · **§9** (the four journeys and the honest gap) · §1.4 (what is a gate and what is a test) · §5.1–§5.3 (`pumpApp`, seeding, the closed twelve-file `test/support/` list) · §11.1–§11.6 (naming, `dart_test.yaml`, randomisation, the Makefile targets, fixtures, flakiness) | every test this epic writes, where it lives, what it costs and what it may not do |
| `docs/engineering/10-accessibility-and-i18n.md` | **§7.1–§7.3** (the Nutrition Label declaration, the eleven-row per-screen sweep over fourteen variants, the automated half) · §1.1 (the seven common tasks) · §3.4 (`headingLevel` only) · §4.2 (why clamping is a bug) · §5.1–§5.3 (colour is never the only channel, the redundancy table, the grayscale gate) · §8.4–§8.7 (ARB conventions, the terminology-placeholder rule, the forty vocabulary labels, what is deliberately not in the ARB) · §10 (the gate rows and the two driver amendments) · §11 (the 35-row anti-pattern list) | the semantics gate, the headings rule, the ARB sweep and the label |
| `docs/engineering/06-design-system.md` | **§6.1–§6.3** (the tap scale, `ShedTapTarget`, the two gates printed in full) · §3.3–§3.5 (the tokens and the design gate rows) · §7 (the gesture ban) · §9.4 (the no-white-flash parity gate) | the geometric gate, the tap-target canary and one side of P9 |
| `docs/design/indelible.md` | **§4.5** (reach zones, the minimum target audit, *"8–12px minimum gaps"*) · §4.1 (the spacing scale) · §7.2, §7.8, §7.9 (the keypad, the stepper and the ease group — 8 px gaps) · §9 (the 3am compliance table) · §11 (the direction's own acceptance tests) | the other side of P9, and what T03 amends |
| `docs/engineering/13-build-ci-release.md` | **§4.2** (the job matrix and the integration row) · **§4.5** (`goldens.yml` verbatim) · §1.1 (the toolchain-pin assert, in every workflow) · §1.3 (the `Makefile`) · §4.6 (what is deliberately not automated, and the CI anti-patterns) | `goldens.yml`, the macOS budget and why the journeys are not a job |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree, including `test/design/`'s five files and `integration_test/`) · §4.5 (widget keys) · §4.7 (policy rule ids) · §5 (the words) · **R57** (the test tree) · **R58** (252 cells over 14 variants) · R56 (the four `[exempt]` lines) · R59, R66, R70 | **BINDING** on every path, file name and word |
| `docs/engineering/07-screens.md` | §16.4 (the banner is a real layout state) · §20 (the five cross-screen rules) · §21.2 (what CI proves about screens) · §21.3 (what CI cannot prove) | which screens carry the reachability assertion, and where the manual sweep takes over |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #99 · #100 · #104 · #113 · #114 · #115 · #116 · #117 · #119 · #121 | Flutter **3.44.8** / Dart **3.12.2** pinned via FVM · `flutter_riverpod` **2.6.1** exactly · `accessibility_tools` **2.8.0** · `mocktail` **1.0.5** |
| `docs/engineering/CODE-REVIEW-CHECKLIST.md` | §1.1 (do not review what a machine proves) · §2 (what no gate can catch) · §3.1 (the irreversibility read order) | why every assertion added here removes a review comment, permanently |
| `epics/00-PLAN-CRITIQUE.md` | **S1** · **S3** · **S7** · §5 E28 and E30 · §10 changes 10, 14, 16 · §11.2 N33 · §11.3 the three anchors · §11.4 the skills | why this epic exists in this shape, and which tasks moved into it |
| `CLAUDE.md` | **P2** (there is no SnackBar) · **P8** (there is no birth-type chooser) · the five safety rules · the amendment rule · the banned words | the two owner rulings the sweeps must keep dead |

## Tasks

Strictly sequential. Each task depends on the one before it because the gates accrete against one
table: the matrix must reach fourteen variants before any sweep can iterate them, the semantics sweep
must exist before the geometric one can share its guideline constant, and the goldens cannot be
rendered until the sweeps agree the screens are correct.

| Task | Depends on | One line |
|---|---|---|
| [N33-T01](N33-T01-the-overflow-matrix-at-its-final-size.md) | N32-T03 · N13-T07 · N24-T08 | The overflow matrix at its final size |
| [N33-T02](N33-T02-the-semantics-sweep-and-its-canary.md) | N33-T01 | The semantics sweep and its canary |
| [N33-T03](N33-T03-the-tap-target-sweep-the-geometric-gate-and-the-p9-ruling.md) | N33-T02 | The tap-target sweep, the geometric gate and the P9 ruling |
| [N33-T04](N33-T04-reachability-and-colour-never-alone-across-every-state.md) | N33-T03 | Reachability and colour-never-alone across every state |
| [N33-T05](N33-T05-the-arb-completeness-sweep.md) | N33-T04 | The ARB completeness sweep |
| [N33-T06](N33-T06-apples-accessibility-nutrition-label-and-the-per-screen-swee.md) | N33-T05 | Apple's Accessibility Nutrition Label and the per-screen sweep |
| [N33-T07](N33-T07-the-eight-goldens-in-their-own-commit.md) | N33-T06 | The eight goldens, in their own commit |
| [N33-T08](N33-T08-the-four-integration-journeys-and-make-integration.md) | N33-T07 | The four integration journeys and `make integration` |
| [N33-T09](N33-T09-goldensyml-the-images-verified-by-ci-in-the-epic-that-create.md) | N33-T08 | `goldens.yml` — the images verified by CI in the epic that created them |

**Ten commits, not nine.** T07 is the one task in this epic that `00-README` §7.4 forbids from landing
as a single commit: the tests are one commit, the eight PNGs are another, alone. Every other task is
one commit.

**The two tasks that will make this branch longer than it looks are T03 and T06.** T03 is the first
time the geometric gate runs against real screens, so its red list is a work queue of layout edits, not
a green run. T06's evidence rows include manual passes on two physical phones in a dark room — that is
an evening, and it cannot be moved onto the laptop.

## The PR workflow, concretely

**1 — Cut the branch from the merged `main`.** N32 is merged, `main` is green, and Play's fourteen-day
clock is already running.

```bash
git switch main && git pull --ff-only
fvm flutter --version          # must print 3.44.8; .fvmrc is the pin
git switch -c epic/n33-ship-gates
```

**2 — One commit per task, in task order — ten commits.** Each task file names its commit line
verbatim; use it. Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

Three commits in this epic carry an extra obligation:

- **T03 amends a published document.** `CLAUDE.md`'s amendment rule is explicit: the decision and
  *every* document that applies it change in the **same** change. A branch where `indelible.md` §4.5
  still says 8–12 px while `tap_target_test.dart` fails at 8 px is worse than either state alone.
- **T07's second commit contains eight binary files and nothing else.** Its body is one line saying
  what changed and why. `00-README` §7.4: a golden re-baseline *"is a deliberate act, never bundled
  with the change it re-baselines."*
- **T09 publishes a workflow whose triggers have a billing consequence.** Read the `on:` block twice
  before pushing, then dispatch it by hand once and watch it both pass and fail.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → the two validators → format --set-exit-if-changed → analyze
make test         # -P ci-fast, randomised order, + TZ=Europe/London --tags uk-zone
```

**3 — Push and open the pull request after the first commit, not after the last.**

```bash
git push -u origin epic/n33-ship-gates
gh pr create --web
```

**Never `gh pr create --fill`** — it takes the body from the commit messages and skips
`.github/pull_request_template.md`, which is where the five §12 questions live.

**4 — Before the PR is marked ready, run `/shed-code-review` once more over the whole branch**, reading
the diff in `00-README` §10's irreversibility order. For this branch that order is:
`.github/workflows/goldens.yml` and the `Makefile` → `docs/design/indelible.md` and
`docs/engineering/**` (T03's amendment, T05's and T07's) → `docs/store/accessibility-nutrition-label.md`
→ any file that appears under `lib/` because a gate went red → `test/features/goldens/*.png` →
`test/**` and `integration_test/**`. The PNGs are read as *images*, not as a diff — open all four
failure images for every one that moved.

**5 — Answer the five §12 questions in the PR body, verbatim.** N33 authors no product behaviour, so
four of the five are answered by naming the assertion this branch adds rather than by describing a
change:

- **§12.1 never default a withdrawal period** — no code path in this diff reaches
  `WithdrawalPeriod`. `test/policy/withdrawal_has_no_default_test.dart` (N05) stays green and T04's
  redundancy sweep adds the presentation half: `NOT RECORDED` is rendered as a word, never as `0` and
  never as a blank.
- **§12.2 never give veterinary advice** — T05's sweep runs `ContentPolicy` over `lib/l10n/*.arb`, and
  T05 is the task that proves the gate's ARB reader exists at all. Until that reader lands, the
  banned-phrase scan has been running against zero files.
- **§12.3 never present as a regulatory record** — T06 declares an accessibility label, which is a
  public claim about the app. Say in the body that the declaration file quotes
  `docs/store/offline-honesty.md` and adds no new claim of its own.
- **§12.4 never silently correct an entry** — the three banned matrix "fixes" are all silent
  corrections of a *test*: clamping `textScaler`, wrapping text in a `FittedBox`, deleting a cell.
  Confirm in the body that none appears in the diff, and name the two gate rows (`type.clamp`,
  `type.fitted_box`) that would have caught them.
- **§12.5 timestamps carry provenance** — T07's goldens are pumped with `atFixed` and a committed
  fixture, so every rendered time in the eight images is a fixed instant with a provenance label
  beside it. A golden that shows a bare time with no label is a §12.5 defect frozen into a PNG.

**6 — Wait for the pipelines.** Four jobs run on this PR. `goldens` does **not**: it is `v*` or
`workflow_dispatch` only, which is the whole point of T09.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart tool/check_policy.dart` (**G2 + G3**) · the two Python validators · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` · the `NSAppTransportSecurity` grep | The rows that would let a sweep be weakened instead of a screen fixed: `type.clamp` (no `withClampedTextScaling`, no `TextScaler.clamp`), `type.fitted_box`, `a11y.scale_factor` (no `textScaleFactor`, including in the theme layer), `a11y.header_bool`, `a11y.merge_semantics`, `a11y.sort_key`, the fourteen `gesture.*` rows and `token.raw_color`. It also proves `tool/policy_allowlist.txt`'s `[exempt]` section is still at R56's four lines — this epic adds none |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | A **negative**, and that is the point. N33 stores nothing and generates nothing. If `drift_schemas/` moves on this branch, a table changed six epics after the freeze — stop and find out why |
| `test` | `flutter test -P ci-fast` randomised · `TZ=Europe/London --tags uk-zone` over the whole suite, **unscoped** · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · the coverage artefact (reported, **never** gated) | The entire epic, minus the goldens and the journeys. This is where the run time of the branch shows up: 252 matrix cells plus 84 semantic runs plus 84 geometric runs, each opening `NativeDatabase.memory()` and restoring a 400-ewe fixture. The `uk-zone` leg carries T01's, T03's and T05's ambiguous-hour cases; untagged, all three pass under UTC for the wrong reason |
| `android` | release AAB · **G1** permission assertion · **G4** merger report archived | Nothing this epic authored. N33 changes no native file, adds no plugin and touches no permission — so a red `android` job on this branch means something unrelated broke, and it still blocks the merge |

The `slow`-tagged contrast group and the `golden`-tagged images are excluded from `ci-fast` by
`dart_test.yaml`. Verify that exclusion is doing what you think: `flutter test --tags golden` locally
must report **eight** tests, not "No tests ran" — a tag that is not declared in `dart_test.yaml`
matches nothing and the run is green because it ran nothing (`12 §11.2`).

**7 — Dispatch `goldens.yml` by hand before you merge.**

```bash
gh workflow run goldens.yml && gh run watch
```

Then break one PNG by 5 %, dispatch again, watch it go red and download the `golden-failures`
artefact — four images per failure. Revert. A workflow nobody has seen fail is indistinguishable from
one that asserts nothing, and this is the only workflow in the project that never runs on a PR.

**8 — Merge, delete the branch, and only then cut N34.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git switch main && git pull --ff-only
# confirm main is green, then:
git switch -c epic/n34-release-engineering
```

N34-T01 depends on N33-T09: `release.yml` and `goldens.yml` are both tag-triggered and both carry the
`FLUTTER_VERSION` block that `test/policy/ci_jobs_test.dart` compares against `.fvmrc`. Cutting N34
from anything other than a green merged `main` means writing the second tag workflow against a first
one that may still move.

## Risks, and what is irreversible

**Irreversible in this epic — say it out loud in the PR body:**

- **The eight committed PNGs.** `test/features/goldens/*.png` become the baseline every future
  toolchain bump, palette edit and font change is measured against. They are binary, they are
  reviewed by eye or not at all, and once merged, *changing* one is a deliberate act with its own
  commit forever (`00-README` §7.4, `12 §8.5`). A golden committed with tofu glyphs, a wrong palette
  or a live timestamp bakes that defect into the reference and trains the next reader to
  `--update-goldens` without looking.
- **`.github/workflows/goldens.yml`'s trigger block, because the consequence is billing.** GitHub bills
  macOS at a **10× multiplier**; the Free plan's 2,000 minutes is **200 macOS minutes a month**. An
  `on: push` or `on: pull_request` here burns the month's quota in a week, and reverting the file does
  not give the minutes back. Read the `on:` block twice.
- **T03's P9 ruling.** It amends a published document and fixes the executable separation number that
  every screen in the app is measured against from then on. Getting it wrong does not fail loudly — it
  fails as a keypad that is 8 px apart and a gate that agrees with it.
- **`docs/store/accessibility-nutrition-label.md` is a public claim to Apple.** Apple's bar is *all* of
  the seven common tasks, not most of them. Declaring a feature the app does not hold is a false
  statement in App Store Connect, and Captions is the row where declaring would be false today.
- **Widget keys are test contracts** (R59). Every sweep in this epic pins the key set it finds.
  Renaming `quick_entry.confirm` after this merges is a breaking change to `test/features/`, not a
  refactor.
- **Anything under `drift_schemas/`, `lib/core/db/tables/`, `android/` or `ios/`.** Nothing in this
  epic may appear there. If a file under any of those paths shows up in this branch, stop.

**Risks specific to N33:**

| Risk | Why it bites here | What holds it |
|---|---|---|
| **A sweep that asserts nothing** | This is the epic's central failure mode and it is silent in three separate ways: `meetsGuideline` with no live `SemanticsHandle` throws instead of asserting (#115); a `--tags` filter naming a tag that `dart_test.yaml` does not declare matches nothing and the run is green; and a `.where((s) => s.controller?.position…)` filter is empty on every screen in this app because a `Scrollable` built without an explicit controller has `controller == null` | The two canaries (T02's unlabelled widget, T03's 40 × 40 target), both asserted to **fail**; `12 §6.4`'s `ScrollableState.position` form in T04; and `test/policy/ci_jobs_test.dart`'s existing case that every selected tag is declared |
| **The matrix is fixed instead of the layout** | A red cell at `small · scale 2.0 · bold true` is one line to make green three wrong ways: delete the cell, clamp `textScaler`, or wrap the text in a `FittedBox` | `12 §6.3` names all three; two of them are gate rows (`type.clamp`, `type.fitted_box`) and the third shows up as a shrinking `kPumpableVariants.length` that the derived count assertion catches. The two legitimate fixes are a scroll view off the primary-action path, or moving something off the screen |
| **Two map keys collide and the count silently drops to 13** | Variant 3 and variant 14 are the *same screen*. Keying both `RouteNames.quickEntry` makes the second overwrite the first, `kPumpableVariants.length` becomes 13, the matrix becomes 234 cells and the anchor's `expect(…, 14)` is the only thing that notices | T01: the fourteenth key is the literal `'quick_entry.export_banner'`, and there is a case asserting the two Quick Entry variants have different map keys |
| **The banner variant renders no banner** | `armExportBanner(db)` sets four `app_settings` columns and `07 §16.2` gates the banner on all of them plus the hour. If any condition does not hold against the regenerated fixture, variant 14 silently renders variant 3 — eighteen cells that duplicate another eighteen and prove nothing | T01: the cell asserts the banner is **found** before it asserts no overflow |
| **`find.byWidget` in the geometric gate** | Two keypad keys can be equal `Widget`s, and `getRect` throws on a finder matching more than one element. The obvious fix — narrowing the finder — quietly stops measuring the keys | T03: match on `Element` identity, `find.byElementPredicate((x) => x == e)`. `06 §6.3` and `12 §7.4` both say so and it is worth repeating twice |
| **A golden rendered in Ahem** | Without `_loadAppFonts()` every glyph is a solid black box. These eight images exist to prove *legibility*, so a golden in Ahem does not merely fail to assert it — it asserts the opposite while looking stable | T07: `flutter_test_config.dart` loads the real font, and a case measures a laid-out text width against a known non-Ahem value |
| **A green golden run with no comparator** | If `TolerantFileComparator` fails to install, `matchesGoldenFile` falls back to the pixel-exact `LocalFileComparator` — or to whatever the ambient one is — and the suite passes for the wrong reason | T07: corrupt one PNG by a single pixel and confirm it still passes; corrupt 5 % and confirm it fails with four images in `failures/`. `12 §8.3` requires this before you trust a green run |
| **The goldens move because the runner's clock is in a different zone** | Every screen in this app prints a local time. `pumpApp` pins the *locale* and `atFixed` pins the *instant*, but neither pins the **process zone** — and `13 §4.5`'s `goldens.yml` sets no `TZ`. The macOS runner is UTC; a developer in London re-baselines at `01:30` and CI renders `00:30` | T07 finds it, T09 fixes it: `TZ=Europe/London` on the golden step **and** on the `Makefile`'s `goldens` / `goldens-update` targets, with a `ci_jobs_test.dart` case asserting both |
| **The integration journeys end up in the blocking set** | An integration suite on a merge gate is a suite that gets deleted the first week it is flaky, and `continue-on-error: true` is a named CI anti-pattern (`13 §4.6`: *"if it is not worth failing on, delete it"*) | T08: they are not a GitHub job at all. `13 §4.2` puts them on *"the developer's desk, phone plugged in"* via a `launchd` or `cron` entry, because `schedule:` cannot drive a device, hosted emulators are debug-only, and Firebase Test Lab needs an account and an upload — the exact posture the product rejects (#117) |
| **The fifteen-second claim measured in debug** | `flutter test integration_test` runs in **debug** by default, where a cold start is several times slower than the release build the claim is about. The assertion then either fails for the wrong reason or is loosened until it means nothing | T08: the timing case runs under `--profile` and says so in its name; in debug it is skipped with a reason, never silently relaxed |
| **`test/design/` grows a sixth file, or an empty fifth one** | R57 fixes the directory at five files. N09-T08 created four and its `gate_inventory_test.dart` asserts *"none of them references `kPumpableVariants` yet"* — an assertion that is correct today and must be flipped, not deleted, when T02 and T03 land the sweeps | T02: `semantics_gate_test.dart` is created **with its sweep**, never as a placeholder — *"an empty gate file is worse than a missing one: it looks like coverage"* — and `gate_inventory_test.dart` is updated in the same commit |
| **The ARB sweep runs against zero files** | `10 §10` amendment (a): 01 §3.2's walker skips every file that does not end `.dart`, so `copy.arb_domain_noun` and `ContentPolicy`'s ARB scan have nothing to run against. Both look green | T05: the ARB reader is the first thing the task lands, and the sweep plants a domain noun in a message and asserts the gate **fires**, then plants one in `termEwePlural` and asserts it does **not** |
| **The sweep demands the §8.7 exceptions move into the ARB** | A rule that says *"every user-facing string is an ARB key"* fails on `Disclaimers`, on the six `ShedFailure.userMessage` strings and on `RecordedTime.provenanceLabel`. The obvious fix is to move them — into the one place a translator can soften a safety string | T05: §8.7's list is encoded in the sweep as a closed set with a case per entry, and adding a seventh exception is a review conversation, not an edit |
| **A claim is declared because it is nearly true** | The Nutrition Label's bar is behavioural: *all* seven common tasks with the feature on. Six of seven is not declarable, and the temptation is strongest on Voice Control and Switch Control, which are hand passes | T06: the declaration file names, per claim, the assertion or the dated manual pass on a named device. A claim with no evidence row fails the test, and a manual row with no date fails it too |
| **The suite's wall clock becomes the reason to cut cells** | 252 + 84 + 84 runs, each opening a real in-memory SQLite database and restoring a 400-ewe backup, is minutes. The tempting optimisation — one shared database in `setUpAll` — is exactly the cross-test state that `--test-randomize-ordering-seed random` exists to catch | Pay the cost. `12 §11.3` is explicit that the data tiers share `setUp`-created databases *and* that randomisation is what catches a fixture mutated in place by a previous test. If the wall clock genuinely blocks, shard with `--total-shards` / `--shard-index`, never by deleting cells |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test` · `android`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] `kPumpableVariants.length == 14`, the two Quick Entry variants have different map keys, and the cell count is **derived** from the four axis lists — 252 appears in no assertion as a literal
- [ ] every `RouteNames` constant appears in the matrix, and `RouteNames` still declares thirteen
- [ ] both canaries fail and are asserted to fail: the 40 × 40 target against the 60 pt guideline, and the unlabelled widget against `labeledTapTargetGuideline`
- [ ] every `meetsGuideline` run opens `tester.ensureSemantics()` and disposes it in `addTearDown` — proved by a source-text assertion over `test/design/`, not by reading the diff
- [ ] `androidTapTargetGuideline` and `iOSTapTargetGuideline` appear nowhere in `test/`
- [ ] P9 is ruled, the ruled number is read from `context.tokens.gapMin` in the test, and the losing document is amended in the same commit
- [ ] the three reachability assertions read `ScrollableState.position`, never `Scrollable.controller`, and a deliberately tall screen makes them fail
- [ ] exactly eight PNGs exist under `test/features/goldens/`, they are their own commit, and `failures/` is git-ignored
- [ ] `make goldens` verifies and `make goldens-update` re-baselines — no single target does both, and both pin `TZ=Europe/London`
- [ ] `goldens.yml` triggers on `v*` tags and `workflow_dispatch` only, runs on `macos-latest`, asserts the pin against `.fvmrc`, and has been watched going both green and red
- [ ] no GitHub job runs `integration_test`, and `test/policy/ci_jobs_test.dart` asserts it
- [ ] every declared Nutrition Label feature names its evidence; Captions and Audio Descriptions are undeclared with their reason recorded
- [ ] every time-shaped assertion added by this epic has a case in the ambiguous hour **01:00–01:59**, tagged `uk-zone`
- [ ] `test/design/` holds exactly five files (R57) and `test/a11y/`, `test/golden/`, `test/screens/` and `test/integration/` do not exist
- [ ] `tool/policy_allowlist.txt`'s `[exempt]` section is still at R56's four lines
- [ ] the diff contains no file under `drift_schemas/`, `lib/core/db/tables/`, `android/` or `ios/`
- [ ] no element of `the-register.md` or `strip-bay.md` appears in the diff, in a comment, or in a review remark

## Demoable on merge

The 252-cell matrix, the semantics gate, the tap-target gate, four integration journeys and
eight CI-verified PNGs all run green.

## Notes

**This epic closes critique defects S1, S3 and S7.** S1 and S7 are the same mistake made twice — the
harness's variant table and the two guideline sweeps were scheduled in E09 and E08 against screens that
did not exist. The fix was to grow `kPumpableVariants` one row per screen epic (N13-T07 onward) and to
land the sweeps here. S3 is the fixture: the matrix seeds through `test/support/seeds.dart` until
N23-T05 writes the two committed backups through the restore path, and N24-T08 regenerates them once
reminder rows have a writer. T01 is the first task in the project that can honestly load
`flock_400_3seasons.json` in all 252 cells.

**What N33 deliberately does not do.** It does not author a `semanticLabel`, an ARB message or a
`headingLevel` — those are widget-authoring work and were done in place. It does not add
`test/design/contrast_test.dart`'s pixel-sampling group's *palette arithmetic*, which is N09-T08's; if
`12 §7.6`'s 42-run `textContrastGuideline` group has not landed by the time T02 is written, it belongs
in the same file as a second group and never in a sixth file. It does not create `release.yml`, measure
anything on a device in profile mode, or touch the seasonal freeze — all four are N34.

**The `goldens` job never runs on this PR, by design.** It is created here so the eight images have a
machine that looks at them before N34's first tag, and it is exercised on this branch by
`workflow_dispatch`. The first tag-triggered run is `v1.0.0`, in N34.

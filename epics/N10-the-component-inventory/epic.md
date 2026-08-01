# N10 — The component inventory

| | |
|---|---|
| **`00-README` §9 step** | 4 (2 of 3) |
| **Depends on** | N09 |
| **Size** | L |
| **Was** | new — the largest hole in the old plan |
| **Branch** | `epic/n10-component-inventory` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

`06-design-system.md` §12 is a twenty-one component inventory, every one of them in
`lib/core/ui/components/`, and **a sibling-feature import is a layer violation** — so no screen may
invent one. Fifteen of the twenty-one had no task in any epic. Twelve screen epics would each have
built their own, and the layer rule forbids sharing them afterwards.

This epic builds those fifteen:

| | Component | Task |
|---|---|---|
| 1 | `ShedPrimaryButton` | T01 |
| 2–3 | `ShedSecondaryButton` · `ShedDestructiveButton` | T02 |
| 4–5 | `ShedConfirmBar` · `ShedRecentsStrip` | T03 |
| 6–7 | `ShedAnimalRow` · `ShedSectionHeading` | T04 |
| 8–9 | `ShedStatusBadge` · `ShedCountdown` | T05 |
| 10–11 | `ShedChoiceRow` · `ShedFieldRow` | T06 |
| 12 | `ShedBottomSheet` | T07 |
| 13–15 | `ShedEmptyState` · `ShedBanner` · `ShedReceiptBar` | T08 |

The other six are placed elsewhere and are **not** in this diff: `ShedTapTarget` (N09-T07),
`ShedKeypad` (N13), `ShedPhoto` (N15), `ShedPenTile` (N19), `ShedSpreadChart` (N28),
`NightErrorPanel` (N11-T04).

## Why the epic sits here

`00-README` §9 puts the design system at **step 4**, between the schema freeze (step 3, N07 + N08) and
Quick Entry (step 5, N13 + N14). Its stated reason, not re-derived here:

> *"The first frame is the product's promise, and the no-white-flash work touches native files you do
> not want to revisit. Everything after this runs inside a real app."*

Three consequences fix this epic's position exactly:

- It comes **after N09** because every component reads `context.tokens`, `buildShedTextTheme`'s roles
  and `ShedTapTarget`. None of the fifteen compiles without all three.
- It comes **before N11 and N12** because nothing here needs `main()`, a provider or a database. That
  is the whole reason fifteen widgets can be written and tested two epics before the app boots — and
  it is also the constraint that shapes every one of them: **a component in `lib/core/ui/` reads no
  provider, reads no clock, and imports nothing under `lib/data/`** (`CONVENTIONS §1.1` layer rule 7).
- It comes **before every screen epic** because `00-README` §9's step 5 note — *"it also forces you to
  build every piece of machinery the other eleven screens reuse … so the second screen is cheap"* —
  only holds if the machinery is already shareable. Layer rule 6 makes that a one-way door: a button
  built inside `quick_entry/` can never be imported by `lambing/`, however small it is.

`00-README` §9 also names the two tracks that run in parallel from day one rather than in a later
sweep: **accessibility** (widget-authoring rules — the `semanticLabel`, the `headingLevel`, the
colour-never-alone rule are authored in each component, and N33 only verifies) and **the ARB**. On the
second, this epic makes a deliberate and slightly surprising call, and it is stated in every task
file: **no component composes copy, so this epic adds no message to `app_en.arb`.** The slab's verb
changes per page, the empty-state copy is per screen, several nouns are terminology the user owns
through `terminologyProvider` — and a component here reads no provider. Every string is a required
parameter, and the screen epic that mounts the component authors the message with its `description`.
An empty ARB diff on this branch is correct, and the commit messages say so.

## What is observably true when this epic merges

Run these on the merged `main` and watch them pass — this is the demo:

```bash
fvm flutter test test/design/components_test.dart
fvm flutter test test/policy/one_overlay_test.dart
TZ=Europe/London fvm flutter test test/design/ --tags uk-zone
make check
```

- **All fifteen components render at textScaler 2.0 with bold text**, on `Device.small` (375 × 667),
  in the `night` palette, with no `RenderFlex` overflow and no exception — before a single screen
  exists to get it wrong.
- **Every tap surface in every one of them is a `ShedTapTarget`**, ≥ 64 × 64, with a non-empty
  `semanticLabel` and a live `SemanticsAction.tap`. That is what makes N33's two sweeps possible at
  all: they find targets with `find.byType(ShedTapTarget)`, and a control built on a bare `InkWell`
  is invisible to every one of them.
- **`showModalBottomSheet(` appears in exactly one file** — `lib/core/ui/components/shed_bottom_sheet.dart`
  — and that call site types all three of Flutter's permissive defaults (`showDragHandle: false`,
  `enableDrag: false`, `isDismissible: false`) as literals. The gate can see a wrong value; only this
  test can see an omission.
- **`showSnackBar(` appears nowhere in `lib/`.** P2 in one grep, two epics before N14-T04 holds it
  repo-wide.
- **No primary control in the app can be constructed disabled.** `onTap` is `VoidCallback`, not
  `VoidCallback?`, on the slab, the confirm bar, both word buttons and every row — so *the slab never
  refuses a press* is a type, not a paragraph.
- **`ShedFieldRow` has no parameter that could carry a placeholder, a hint, an initial value or a
  default.** Safety rule §12.1 held at *unconstructible* in the component, which is a level above
  where a screen-side check would hold it.
- **`ShedBanner` renders at every hour from 06:00 to 21:59 and at none from 22:00 to 05:59**, proved
  by a 24-hour sweep that turns the **clock** and never the entitlement — and it reads
  `isQuietHours` from `lib/domain/free_tier.dart` rather than defining a second window.
- **`header:` appears nowhere under `lib/core/ui/components/`**, and `ShedSectionHeading`'s semantics
  node reports `headingLevel` 1 or 2 and refuses anything else.
- **A withdrawal countdown computes days with `LocalDate.daysUntil`**, so seven days across UK
  spring-forward renders seven tally marks and not six. Two `uk-zone` cases hold it.

What is deliberately **not** demonstrable yet: the two guideline sweeps and the pixel-sampling
contrast run. All three iterate `kPumpableVariants` (`12 §6.2`), which lives in
`test/support/harness.dart` — N12-T05 — and is not complete until N33. See Notes.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/06-design-system.md` | **§12** (the twenty-one component inventory: one size contract, one state list and one note per component, plus the three free-tier constraints) · §5.1 (the fifteen `TextTheme` roles and their sizes) · §5.4 (tabular figures and the silent failure) · §6.1–§6.3 (the tap scale, `ShedTapTarget`, the two gates) · §7 (**the gesture ban**, and the three sheet settings that must be typed) · §8.2 (the keypad geometry and the Quick Entry stack order) · §9.3 (frame-1 placeholders; never a spinner) · §10.1–§10.3 (haptics, and what a house receipt bar must carry itself) · §11 (four encodings per status) · §3.5 (**the gate rows**: `token.magic_size`, `token.color_scheme_read_ui`, `type.*`, `gesture.*`, `a11y.*`) | every **name, size contract and state list** |
| `docs/design/indelible.md` | §4.1–§4.5 (spacing, geometry, the row sub-grid, row heights, **the minimum-target audit — the smallest target in the app is 64 × 64**) · §5.1–§5.4 (four durations, what must never animate, reduce-motion, haptics) · §6.1–§6.3 (**there is no icon set** — six marks, 2 px strokes, butt caps, 24 or 28 px boxes) · **§7.1–§7.17** (every control's geometry, states and interaction rules) · §2.7 (how status is encoded without relying on colour) · §9 (the 3am compliance table and where each safety rule lives) · §11 (the ten acceptance tests) | every **value**, and every state list the engineering set left implicit |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree; `components/shed_<thing>.dart`; **`components/shed_receipt.dart`**) · **§1.1 layer rules 6 and 7** · §2.7 (the withdrawal types, and *the countdown widget takes a `ClearsOn`*) · §2.10–§2.11 (the free tier and the design-system catalogue) · §4.1–§4.5 (files, classes, providers, controllers, **widget keys**) · §4.7 (policy rule ids; `ui.spinner`'s scope; `ui.show_dialog`'s allowlist) · §5.1–§5.4 (vocabulary) · R24, R30, R31, R44, R56, R57, R59, R70 | **BINDING** on every path, type and word |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.1–§3.2 (what is free and the eight label rules) · **§3.4** (`headingLevel` only; `header:` is a no-op since 3.44) · §3.5 (deriving a width from the scaled numeral) · §3.8 (the live region only re-fires on `didChangeLabel()`) · §4.2 (never clamp text scale) | the semantics every component authors |
| `docs/engineering/07-screens.md` | §2.2 (the twelve-row empty-state table) · §5.1–§5.3 (the Quick Entry stack and the deck) · §10.2–§10.3 (the withdrawal control and its four renderings) · §15.1–§15.6 (undo per verb; *"Cancel" is not a verb*) · §16.2–§16.4 (the export prompt) · §20.3 (sheets over full-screen pages) | what each component is actually used for |
| `docs/engineering/12-testing.md` | §5.1 (`pumpApp`, which is N12-T05) · **§5.3** (`test/support/` is a **closed** twelve-file list) · §6 (the 252-cell overflow matrix) · §7.4–§7.6 (the gate split and the 84-run table) | where this epic's tests may live, and where they may not |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #57, #71, #90, #92, #99, #100, #101, #103, #104, #106, #115, #127 | Flutter **3.44.8** / Dart **3.12.2**; `flutter_riverpod` **2.6.1** exactly |
| `CLAUDE.md` | **P2** (there is no SnackBar) · **P8** (there is no birth-type chooser) · the 3am test floor · the five safety rules and the mechanism hierarchy · the banned words | two owner rulings that supersede a written document |
| `epics/00-PLAN-CRITIQUE.md` | G1 (why this epic exists) · §11.3 (**the two `[audit]` corrections to this epic's anchors**) · §11.4 (skills per epic) | the corrected assertions, which bind |

## Tasks

Strictly sequential. T01 lands the shared pump helper and the three conventions the other seven
inherit; after that each task extends one test file that the previous task created, so a parallel
branch would be eight conflicting edits to `test/design/components_test.dart`.

**Dependencies are a straight chain.** T01 depends on the **last commit of N09** — the whole of
`lib/core/ui/` has to exist first — and every task after it depends on the one directly above it. Each
task file's header table names its predecessor by id.

| Task | Depends on | One line |
|---|---|---|
| [N10-T01](N10-T01-shedprimarybutton-the-corner-slab.md) | the last N09 commit | `ShedPrimaryButton` — the corner slab, five states, and the rule that it never refuses a press |
| [N10-T02](N10-T02-shedsecondarybutton-and-sheddestructivebutton.md) | T01 | `ShedSecondaryButton` and `ShedDestructiveButton` — two-step destruction, `gapDestructive` reserved by the widget itself |
| [N10-T03](N10-T03-shedconfirmbar-and-shedrecentsstrip.md) | T02 | `ShedConfirmBar` and `ShedRecentsStrip` — outcome-labelled, one fixed height across four states |
| [N10-T04](N10-T04-shedanimalrow-and-shedsectionheading.md) | T03 | `ShedAnimalRow` and `ShedSectionHeading` — the ruled rows, the sub-grid, `headingLevel` 1 and 2, `header:` banned |
| [N10-T05](N10-T05-shedstatusbadge-and-shedcountdown.md) | T04 | `ShedStatusBadge` and `ShedCountdown` — word and form always; *not recorded* is its own constructor |
| [N10-T06](N10-T06-shedchoicerow-and-shedfieldrow.md) | T05 | `ShedChoiceRow` (**ease 1–5 only — P8**) and `ShedFieldRow` — an API that cannot carry a default |
| [N10-T07](N10-T07-shedbottomsheet-the-only-overlay-in-the-app.md) | T06 | `ShedBottomSheet` — one call site, three typed flags, no drag, no scrim tap |
| [N10-T08](N10-T08-shedemptystate-shedbanner-and-shedreceiptbar.md) | T07 | `ShedEmptyState`, `ShedBanner` and `ShedReceiptBar` — the same box, the quiet window, and P2's receipt |

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N09 is merged and `main` is green before this starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version          # must print 3.44.8; .fvmrc is the pin
git checkout -b epic/n10-component-inventory
```

**2 — One commit per task, eight commits, in task order.** Each task file names its commit line
verbatim; use it. Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

Two commits in this epic carry an extra obligation:

- **T07** amends `CONVENTIONS §2.11` to add `showShedBottomSheet`. A naming-authority edit travels
  with the code that introduces the name (`00-README` §10 rule 3), never in a follow-up.
- **T02** may need a new `ShedTokens` field for Indelible's madder ink. Every field on that type is
  `required`, so it moves all six palette literals in `palettes.dart` and re-runs
  `contrast_test.dart` — i.e. it reopens N09's diff. Do it inside T02's commit or not at all.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test         # -P ci-fast, randomised order, + TZ=Europe/London --tags uk-zone
```

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the
diff in `00-README` §10's irreversibility order. For this branch that order is:
`tool/policy_allowlist.txt` (it must still have **exactly four** `[exempt]` lines — R56) →
`docs/engineering/CONVENTIONS.md` and any other amended document → `lib/core/ui/feedback.dart` →
`lib/core/ui/components/` → `test/policy/` → `test/design/`.

**4 — Open the PR and answer the five §12 questions** in `.github/pull_request_template.md`
**verbatim, in the PR body**. `00-README` §7.4: the PR is *where* the safety review happens. Three of
the five land squarely on this branch and must not be answered "not applicable":

- **§12.1** — `ShedFieldRow` is the control every withdrawal figure is typed into. State that its API
  carries no `hintText`, no `placeholder`, no `initialValue` and no `defaultValue`, and name the
  source-text case that proves it.
- **§12.2** — no component originates a clinical number. `ShedCountdown` renders arithmetic on a
  figure the user supplied and holds no opinion; `ShedStatusBadge` renders a word it was handed.
- **§12.4** — `ShedChoiceRow` may not be used for birth type. P8 makes the most common contradiction
  structurally impossible; a chooser here would demote it to procedural.

Four decisions this epic takes on documented conflicts also go in the PR body, each in one line:
the **64 → 72 row-height widening** (T04) and its page-density consequence; the **64 → 72 sheet
dismiss widening** (T07); the **horizontal-versus-ruled recents arrangement** with the arithmetic that
settles it (T03); and the **`ShedConfirmBar` disabled-state reading** (T03), which follows T01's.

**5 — Wait for the pipelines.** Three jobs run for this epic and each proves a different thing.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart run tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` · the `NSAppTransportSecurity` grep | The two-tier token rules, mechanically, across fifteen new widget files: `token.raw_color` and `token.magic_size` under `lib/`, `token.color_scheme_read_ui` (`colorScheme` is a **build failure** inside `lib/core/ui/components/`), `token.literal_font_size`, `type.fitted_box`, `type.weight_cap`, and the fourteen `gesture.*` rows — `gesture.drag_handle`, `gesture.sheet_drag`, `gesture.slider`, `gesture.dismissible`, `gesture.long_press`, `gesture.raw_snackbar` — plus `a11y.header_bool` and `a11y.announce`. This is the job that catches a widget written by habit rather than from the token set |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | A **negative**, and that is the point: N10 touches no table, so fifteen components must add no generated file and move no schema snapshot. If this job is red on this branch, something under `lib/core/ui/components/` has pulled a second generator into the build, and drift is the entire generator budget (decision #16) |
| `test` | `flutter test -P ci-fast` randomised · `TZ=Europe/London --tags uk-zone` over the whole suite · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · the coverage artefact (reported, **never** gated) | `test/design/components_test.dart` and `test/policy/one_overlay_test.dart`, plus everything N09 landed. The `uk-zone` leg matters for **T05** and **T08**: the withdrawal tally across spring-forward and the quiet window through the ambiguous 01:00–01:59 hour only exercise their real cases when tagged **and** run under `TZ=Europe/London`. An untagged DST case passes for the wrong reason |

`android` also runs on every PR (`13 §4.2`), builds the release AAB and asserts **G1**. N10 changes no
native file and no permission, so it proves nothing this epic authored — but it must stay green. If it
goes red here, look at a dependency, not at a widget.

Goldens do **not** run on this PR: the `goldens` job is `v*` or `workflow_dispatch` only, because the
macOS runner bills at a 10× multiplier. The eight images are N33-T07.

**6 — Merge, delete the branch, and only then cut N11.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git checkout main && git pull --ff-only
# confirm main is green, then:
git checkout -b epic/n11-bootstrap-errors-and-the-first-frame
```

N11 builds `main()`, `app.dart`, `NightErrorPanel` and the no-white-flash layers on top of a design
system that must not move underneath it. Cutting N11 from anything other than a green merged `main`
means the first frame is composed against a token set that is still being edited.

## Risks, and what is irreversible

**Say this out loud in the PR body, because it is unusual for this backlog: nothing in this epic is
irreversible in the schema sense.** No table, no snapshot, no migration, no native file, no signing
key, no published artefact, no permission. That is worth stating because it tells a reviewer where
*not* to spend the budget — and because everything in the next list is expensive for a different
reason.

**Expensive to reverse, and each one gets named in the PR body:**

- **Fifteen public APIs that twelve screen epics consume.** From N13 onward, every screen imports
  these names. Renaming `ShedAnimalRow.summary`, widening `ShedFieldRow`'s constructor or making
  `onTap` nullable after N13 is a rebase across twelve epics, and `CONVENTIONS §4.5` makes it worse
  for keys: *"a key is a test contract, so renaming one is a breaking change to `test/features/`."*
  The narrow signatures in the task files are the cheap moment; this is it.
- **A new `ShedTokens` field (T02, if the madder ink needs one).** Every field is `required`, so it
  edits all six palette literals and re-runs `contrast_test.dart`. It reopens N09's diff and it is
  reviewed as a colour change, not as a widget change.
- **`lib/core/ui/feedback.dart` is created here (T08) with `SaveReceipt` and nothing else.** That
  file is R30's home for three functions this epic must **not** write: P2 supersedes their shapes and
  `showFailure` needs `ShedFailure` from `lib/core/failure.dart`, which layer rule 7 does not let
  `lib/core/ui/` import. Landing the functions early would pre-empt both N11-T01 and N14-T04.
- **The `CONVENTIONS §2.11` amendment (T07).** A naming-authority edit is quoted by other documents;
  once it lands, `showShedBottomSheet` is the name.

**Must not appear in this diff at all:** `drift_schemas/`, `lib/core/db/`, `lib/data/`, `android/`,
`ios/`, `pubspec.yaml`, `pubspec.lock`, and a **fifth `[exempt]` line** in `tool/policy_allowlist.txt`
(R56 fixes the day-one total at four). **If a file under any of those shows up on this branch, stop
and find out why.** Fifteen widgets need no dependency and no exemption; `13`'s gate-integrity rule is
absolute — never add an allowlist line to make a red build green.

| Risk | Why it bites here | What holds it |
|---|---|---|
| **The gates that would catch these mistakes do not run yet** | `semantics_gate_test.dart` and the geometric half of `tap_target_test.dart` iterate `kPumpableVariants`, which is N12-T05 and is not complete until N33. For two epics, each component's **own** local case is the only defence | Every task file's §5.4 carries the geometry, semantics and source-text cases explicitly rather than deferring to a sweep |
| **`test/design/components_test.dart` is one file eight commits touch in a row** | Eight sequential edits to one file is fine; two parallel ones are not, and a flat list of eighty `testWidgets` calls is unreadable by T05 | Strictly sequential tasks, and a table-driven shape with one group per component from T01 |
| **The shared pump helper drifts into `test/support/`** | It looks exactly like a harness, and `pumpApp` is coming in two epics. But `12 §5.3` **closes** `test/support/` at twelve files and names each one | T01 puts `_pumpComponent` as a private top-level function in the one file that uses it, which is the same rule `12 §5.3` applies to `selectEwe` and `enterWithdrawal` |
| **`ui.spinner` is scoped to `lib/features/` and this folder is its blind spot** | A `CircularProgressIndicator` written into a shared component passes the gate and then renders on every screen that mounts it — and decision #71 is *never a spinner, anywhere* | T03 adds a source-text case over the whole `lib/core/ui/components/` folder, and T08 extends it |
| **`token.magic_size` catches a literal after a size keyword and nothing else** | `minWidth: 2 * t.tapPrimary` fails the build; `math.max(2 * t.tapMin, x)` does not; and `t.tapPrimary * 2` is fine. The rule is real but partial, so token-first is a habit and not a gate | Named in T01's gotchas and repeated in every task's standing traps |
| **Indelible's own two artefact defects are in this epic's blast radius** | `--t-stamp` 14 px and `--t-head` 16 px are **below the 18 px floor** (`00-PLAN-CRITIQUE.md` §8, defect 2), and the stamp is `ShedStatusBadge`'s type role | T04 and T05 use `titleMedium` / `labelMedium`, both ≥ 18; N09-T05 owns the corrected exemption test and this epic does not re-litigate it |
| **Two anchors in this epic were corrected by the audit** | `00-PLAN-CRITIQUE.md` §11.3 rewrites the N10 component assertion (*"every **tap surface** in its tree"*, not *"no dimension below 64"* — which would make `ShedStatusBadge` and `ShedSectionHeading` unbuildable) and the T07 overlay assertion (a flat `showDialog(` ban would make the only two honest deletes illegal) | Both anchors are preserved verbatim as the red step; both tasks implement the **corrected** property and say so in §4 and §5.3 |
| **A reviewer suggests a red `DEAD` badge** | It is the single most obvious "improvement" on T05's diff, and `statusLoss` exists as a token to make it easy | Indelible §2.7: *"colour: none, ever. Death is a word."* N09-T02 already closed it: the field existing does not license a component to use it as the only channel |
| **P2 gets quietly re-litigated into a SnackBar** | `06 §10.3` prints a full `confirmSaved` body around `showSnackBar(`, and it is the most complete code in the whole design document | `CLAUDE.md` P2 supersedes it; T08 lands `ShedReceiptBar` with its own live region and its own dismiss, and `grep -rn "showSnackBar(" lib/` is in the verification block |
| **A component grows a `ConsumerWidget` or an `appNow()` call** | Every screen example in `07-screens.md` is a Consumer, so it is the shape a developer arrives with | Layer rule 7 gives `lib/core/ui/` only `{lib/core/ui/, lib/domain/}` plus flutter; `now` is a parameter (R24), and each task's test set includes an import-block case |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] all fifteen `06 §12` components exist under `lib/core/ui/components/`, one `shed_<thing>.dart` file each, and none of them lives under a feature's `widgets/`
- [ ] every tap surface in every component is a `ShedTapTarget` with a non-empty `semanticLabel` and a live `SemanticsAction.tap`
- [ ] no component imports a provider, a clock, `lib/data/` or `lib/core/db/`; `grep` over the import blocks proves it
- [ ] `showModalBottomSheet(` has exactly one call site and it types all three permissive flags as literals
- [ ] `showSnackBar(` appears nowhere in `lib/`
- [ ] `header:` appears nowhere in `lib/core/ui/components/`
- [ ] `ShedFieldRow`'s API cannot carry a placeholder, hint, initial value or default
- [ ] the two `uk-zone` cases (T05's spring-forward tally, T08's ambiguous-hour quiet window) pass under `TZ=Europe/London`
- [ ] `app_en.arb` is unchanged by this branch, and every commit message says why
- [ ] `tool/policy_allowlist.txt` still has exactly four `[exempt]` lines
- [ ] the diff contains no file under `drift_schemas/`, `lib/core/db/`, `lib/data/`, `android/` or `ios/`, and no change to `pubspec.yaml` or `pubspec.lock`
- [ ] no element of `the-register.md` or `strip-bay.md` appears in the diff, in a comment, or in a review remark

## Demoable on merge

Every `06 §12` component renders in a widget test at text scale 2.0 with bold text, carries a
`semanticLabel`, and has no dimension below 64 — before a single screen exists to get it wrong.

## Notes

**The 64 in that sentence is Indelible's, not `06`'s.** `06 §6.1` sets the floor at `tapMin` = **60**;
`indelible.md` §4.5's component-by-component audit concludes *"the smallest target in the app is
64 × 64. The spec floor is 60."* This epic builds to 64 and the `MinimumTapTargetGuideline` in
`test/design/` stays at 60 — the guideline is the contract, the 64 is the headroom. Where a component
is not a target at all, the sentence does not apply: `06 §12` sizes `ShedStatusBadge` at *"≥ 24 tall
inside a ≥ `tapMin` parent"* and gives `ShedSectionHeading` no target contract, which is exactly the
correction `00-PLAN-CRITIQUE.md` §11.3 made to this epic's assertion.

**Six of the twenty-one are elsewhere and this epic must not build them.** `ShedTapTarget` is
N09-T07 (already merged when this branch is cut); `ShedKeypad` is N13 and is a shared component under
R70, not a Quick Entry widget; `ShedPhoto` is N15 and owns the app's only `ColorFiltered`;
`ShedPenTile` is N19; `ShedSpreadChart` is N28; `NightErrorPanel` is N11-T04 and lives at
`lib/core/ui/night_error_panel.dart`, outside `components/`, because it renders with no `Theme` and no
`MediaQuery` ancestor.

**Two open conflicts belong to other epics and must not be closed here.** `CONVENTIONS §4.5` still
publishes `lambing_entry.birth_type.twin` as its worked widget-key example and R59 still blesses it —
an artefact P8 invalidated, assigned to **N16-T02a**. And P14 (`#0B0D0E` versus `#0A0A0B`) is
**N11-T04**'s. Nothing in this branch may contain `birth_type`, and nothing in it may pick a launch
colour.

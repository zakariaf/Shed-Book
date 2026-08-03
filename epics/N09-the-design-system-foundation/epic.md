# N09 — The design system foundation

| | |
|---|---|
| **`00-README` §9 step** | 4 (1 of 3) |
| **Ships in** | `v1.0.0` |
| **Depends on** | N08 |
| **Size** | L |
| **Was** | E08, with the two sweeps that iterate `kPumpableVariants` moved to N33 |
| **Branch** | `epic/n09-design-system-foundation` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

Author `lib/core/ui/` — `primitives.dart`, `tokens.dart`, `palettes.dart`, `theme.dart`,
`formatters.dart`, `motion.dart` and `components/shed_tap_target.dart` — with **Indelible's values**
under **`06-design-system.md`'s names and structure**, plus the four `test/design/` gate files that
can honestly run before a single screen exists. Two open conflicts are ruled inside this epic and
their losing documents amended in the same commit: **P7** (the typeface and the variable weight axis,
T05) and **P10** (four haptics or five, T09).

The other two design directions — `docs/design/the-register.md` and `docs/design/strip-bay.md` — do
not appear anywhere in the diff, in a comment, or in a review remark. `02-build-manifest.md` §4.3:
*"the point of one design system is that the alternatives are unreachable."*

## Why the epic sits here

`00-README` §9 puts the theme set at **step 4**, immediately after the schema freeze (step 3, N07 +
N08) and immediately before Quick Entry (step 5, N13 + N14). Its stated reason, not re-derived here:

> *"The first frame is the product's promise, and the no-white-flash work touches native files you do
> not want to revisit. Everything after this runs inside a real app."*

Two consequences bind this epic's scope:

- It comes **after** the freeze because §9 front-loads the irreversible and the invisible-when-wrong
  and reaches pixels late. Nothing in N09 is schema-shaped, so nothing in N09 could have justified
  being earlier.
- It comes **before** N11's `main()` / `app.dart` because `themeProvider` is a synchronous
  `Provider<ShedThemeSet>` whose not-yet-loaded arm is *the const `night` pair* (`CONVENTIONS` R29,
  `06 §2.1`). That pair has to exist as a `const` before `app.dart` can name it. N09 builds it; N11
  wires it; N10 builds the twenty-one components on top of it.

`00-README` §9 also names the two tracks that run in parallel from day one and therefore start here
rather than in a later sweep: **accessibility** (they are widget-authoring rules — `ShedTapTarget`'s
required `semanticLabel` is T07, not N33) and **the ARB** (every user-facing string goes through
`app_en.arb` from the first one). N33 only *verifies*.

## What is observably true when this epic merges

Run these on the merged `main` and watch them pass — this is the demo:

```bash
fvm flutter test test/design/                       # six files, all green
fvm flutter test test/policy/primitives_are_private_test.dart
make check                                          # policy gate + format + analyze --fatal-infos
```

- **`test/design/contrast_test.dart` recomputes every published ratio** from the six authored
  `ShedPalette` entries with `Color.computeLuminance()` — not from a table, not from a design tool's
  report. Every text pair clears **4.5:1**, every rule and mark clears **3:1**, `night` and `amber`
  clear **7:1** on numerals and primary text, and standard-contrast `deepRed` clears **4.5:1** with
  the AA exception written in the code beside the assertion (`06 §4.4`). Change one hex by one digit
  and the suite names the failing pair.
- **`shedPalettes` has exactly six entries** and every `(ShedPaletteId, highContrast)` pair appears
  exactly once — asserted, because a seventh palette added in season two would otherwise get its
  ratios published and never tested (`06 §4.1`).
- **`ShedTapTarget` cannot be constructed without a `semanticLabel`.** Delete the argument and the
  analyzer refuses to compile — at the type level, not at runtime.
- **No code path in the app can produce `Brightness.light`.** `theme_test.dart` builds the theme
  under all six palettes and asserts the brightness; the gate proves `Brightness.light`,
  `ThemeMode.system`, `ThemeMode.light`, `ColorScheme.light`, `ThemeData.light`,
  `platformBrightnessOf` and `ColorScheme.fromSeed` appear nowhere under `lib/`.
- **`Color(0x` appears in exactly two files under `lib/`** — `primitives.dart` and
  `night_error_panel.dart` — and `core/ui/primitives.dart` is imported by exactly one file,
  `palettes.dart`. Both proved by `tool/check_policy.dart`, not by inspection.
- **`package:intl` is imported by exactly one file under `lib/`** outside `lib/data/`:
  `lib/core/ui/formatters.dart`. `formatShedDate` renders `11 Mar 2026`, never `11/03/2026`.
- **Reduce-motion resolves to zero, not to shorter** — and the 40 ms press flash survives it, in both
  the Android-only and the iOS-only branch.
- **P7 and P10 are closed with a written ruling, or carried into the PR body as open with both sides
  cited.** They are not silently resolved.

What is deliberately **not** demonstrable yet: the two guideline sweeps and the pixel-sampling
contrast run. All three iterate `kPumpableVariants` (`12 §6.2`), a fourteen-entry table in
`test/support/harness.dart` that does not exist until N13 and is not complete until N33. See Notes.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/design/indelible.md` | §1.2 (the four rules) · §2.1–§2.6 (the method, five surfaces, three inks, what measurement overruled, the contrast tables, red-shift) · §3.1–§3.6 (two voices, the stacks, weights, the scale, tabular figures, 200%) · §4.1–§4.5 (spacing, geometry, the grid, row heights, reach zones) · §5.1–§5.4 (motion, what never animates, reduce-motion, haptics) · §11 (the ten acceptance tests) | every **value**: hex, size, weight, tracking, duration, target |
| `docs/engineering/06-design-system.md` | §1 (what a direction may not change) · §2 (the four theme slots) · §3 (two-tier tokens, the file layout, the gate rows) · §4 (the six palettes) · §5 (the scale, the font asset, the w700 cap, tabular figures, never clamp) · §6 (the tap scale, `ShedTapTarget`, the two gates) · §7 (the gesture ban) · §10.1 (the haptic vocabulary) | every **name and structure**: token names, file paths, class shapes, gate rule ids |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree) · §1.1 layer rule 7 · §2.11 (the design-system type catalogue) · §4.1–§4.3, §4.7 · §5.3–§5.4 · R29, R34, R35, R55, R56, R57, R70 | **BINDING** on every path, type, provider and word |
| `docs/engineering/10-accessibility-and-i18n.md` | §2.3 (`prefersReducedMotion`) · §9.1–§9.5 (the five `formatShed*` signatures, the never-numeric-date rule, 24-hour, Monday-first) | what `formatters.dart` and `motion.dart` must do |
| `docs/engineering/12-testing.md` | §7.4 (the split between `semantics_gate_test.dart` and `tap_target_test.dart`, and the 84-run table they share) · §7.5 (the canary) · §7.6 (why the pixel-sampling run is 42 runs, tagged `slow`) | which gate may run when, and where each assertion lives |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #94–#106, #98, #99, #100, #101, #105, #127 | Flutter **3.44.8** / Dart **3.12.2**; `intl` **0.20.2** (SDK-pinned, declared `any`); `accessibility_tools` **2.8.0** |
| `CLAUDE.md` | the 3am test floor · P2 (there is no SnackBar) · P8 (no birth-type chooser) · the banned words | 60 × 60 pt floor with Indelible at 64 × 64, 18 px body floor, dark only, the gesture ban |
| `epics/00-PLAN-CRITIQUE.md` | S7 · §11.4 (skills per epic) · §10 (the workflow rules) | why the two sweeps are N33's and not this epic's |

## Tasks

Strictly sequential: each task depends on the one before it, because `palettes.dart` cannot compile
without `tokens.dart`, `theme.dart` cannot compile without `palettes.dart`, and the gates cannot run
without something to measure.

| Task | Depends on | One line |
|---|---|---|
| [N09-T01](N09-T01-primitivesdart-raw-hexes-importable-nowhere-else.md) | N08-T07 | `primitives.dart` — raw hexes, importable nowhere else |
| [N09-T02](N09-T02-tokensdart-one-flat-themeextension.md) | N09-T01 | `tokens.dart` — one flat `ThemeExtension` |
| [N09-T03](N09-T03-palettesdart-night-amber-and-deep-red-each-with-a-high-contr.md) | N09-T02 | `palettes.dart` — night, amber and deep red, each with a high-contrast variant |
| [N09-T04](N09-T04-themedart-no-code-path-can-produce-a-light-theme.md) | N09-T03 | `theme.dart` — no code path can produce a light theme |
| [N09-T05](N09-T05-typography-the-variable-font-and-the-p7-ruling.md) | N09-T04 | Typography, the variable font, and the P7 ruling |
| [N09-T06](N09-T06-formattersdart-the-one-packageintl-call-site.md) | N09-T05 | `formatters.dart` — the one `package:intl` call site |
| [N09-T07](N09-T07-shedtaptarget-64-64-and-a-required-semanticlabel.md) | N09-T06 | `ShedTapTarget` — 64 × 64 and a required `semanticLabel` |
| [N09-T08](N09-T08-the-design-gates-that-can-honestly-run-today.md) | N09-T07 | The design gates that can honestly run today |
| [N09-T09](N09-T09-motiondart-the-haptic-vocabulary-and-the-p10-ruling.md) | N09-T08 | `motion.dart`, the haptic vocabulary, and the P10 ruling |

`motion.dart` is written in T09 but `prefersReducedMotion` is *called* by T08's
`reduce_motion_test.dart`. That is the one ordering wrinkle in the epic and it is deliberate: T08
lands the resolver and the four gate files; T09 lands the motion **tokens**, the haptic vocabulary and
the P10 ruling on top of it. Do not split the P10 ruling across two commits.

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N08 is merged and `main` is green before this starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version          # must print 3.44.8; .fvmrc is the pin
git checkout -b epic/n09-design-system-foundation
```

**2 — One commit per task, nine commits, in task order.** Each task file names its commit line
verbatim; use it. Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

Two commits in this epic carry an extra obligation because they are the kind that must stand alone
(`00-README` §7.4):

- **T01** adds two `[exempt]` lines to `tool/policy_allowlist.txt`. An `[exempt]` line *"deletes a
  rule for one file, forever, silently, and the reason goes in the commit message that adds it."*
  Both reasons go in T01's message.
- **T05** commits a binary font asset and a `pubspec.yaml` `fonts:` block. Read the `pubspec.lock`
  diff if there is one; a lockfile diff in a PR that does not also change `pubspec.yaml` is a review
  stop.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test         # -P ci-fast, randomised order, + TZ=Europe/London --tags uk-zone
```

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the
diff in `00-README` §10's irreversibility order. For this branch that order is:
`tool/policy_allowlist.txt` and `tool/check_policy.dart` → `pubspec.yaml` and `assets/fonts/` →
the `docs/` amendments made by the P7 and P10 rulings → `lib/core/ui/` → `test/design/`.

**4 — Open the PR and answer the five §12 questions** in `.github/pull_request_template.md`
**verbatim, in the PR body**. `00-README` §7.4: the PR is *where* the safety review happens. For N09
most honest answers are "this epic does not reach that rule" — say that, and say which task would have
if it did. Two of the five do land here: **§12.5** (`formatters.dart` renders every time as `HH:mm`
and no displayed time is ever a bare number without its provenance label) and **§12.2** (nothing in
`lib/core/ui/` originates a clinical number).

If P7 or P10 could not be closed, **the PR body carries the conflict with both sides cited**
(`02-build-manifest.md` §4.5). Do not resolve either on this epic's own authority.

**5 — Wait for the pipelines.** Three jobs run for this epic and each proves a different thing.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` · the `NSAppTransportSecurity` grep (**G5** text half) | The whole access-control story for colour, mechanically: `Color(0x` in two files, `core/ui/primitives.dart` imported by one, `colorScheme` absent from `lib/core/ui/components/`, `[exempt]` at **exactly four lines** (R56), every banned theme / type / gesture spelling absent. `--fatal-infos` is also what turns a deprecated `ColorScheme` role (`background`, `onBackground`, `surfaceVariant`) into a CI failure — `06 §2.3` rule 1 depends on that flag being set. T05 needs it green because `google_fonts` is a `type.google_fonts` row |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | A **negative**, and that is the point: N09 touches no table, so the design system must add no generated file and move no schema snapshot. If this job is red on this branch, something under `lib/core/ui/` has pulled a second generator into the build — and drift is the entire generator budget (decision #16) |
| `test` | `flutter test -P ci-fast` randomised · `TZ=Europe/London --tags uk-zone` over the whole suite · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · the coverage artefact (reported, **never** gated) | The six `test/design/` files and `test/policy/primitives_are_private_test.dart`. The `uk-zone` leg matters for **T06**: `formatters_test.dart`'s DST case only exercises the ambiguous 01:00–01:59 hour when it is tagged and the leg runs under `TZ=Europe/London`. An untagged DST case passes for the wrong reason |

`android` also runs on every PR (`13 §4.2`), builds the release AAB and asserts **G1**. N09 changes no
native file and no permission, so it proves nothing this epic authored — but it must stay green. If it
goes red here, look at a dependency, not at a token.

Goldens do **not** run on this PR: the `goldens` job is `v*` or `workflow_dispatch` only, because the
macOS runner bills at a 10× multiplier. The eight images are N33-T07.

**6 — Merge, delete the branch, and only then cut N10.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git checkout main && git pull --ff-only
# confirm main is green, then:
git checkout -b epic/n10-component-inventory
```

N10 builds fifteen components directly on `context.tokens`, `ShedTapTarget` and `buildShedTextTheme`.
Cutting it from anything other than a green merged `main` means fifteen widget files rebased onto a
moving token set.

## Risks, and what is irreversible

**Irreversible in this epic — say it out loud in the PR body:**

- **The two `[exempt]` lines in `tool/policy_allowlist.txt`** (T01). They delete a rule for one file,
  forever, silently. R56 fixes the day-one total at **four**; a fifth is a review conversation, not an
  edit. `13`'s gate-integrity rule is absolute: never add an allowlist line to make a red build green.
- **The committed font binary and the `pubspec.yaml` `fonts:` block** (T05). The file enters git
  history and counts against the < 5 MB bundled-asset budget (decision #127). It is load-bearing in
  three other places — `09 §4.2` embeds the same TTF in every PDF, `12 §8.3` loads it in
  `test/flutter_test_config.dart`, and `13 §6` budgets it — so changing the family later moves four
  artefacts together, which is exactly why P7 must be ruled here rather than deferred.
- **Any document amendment made by the P7 (T05) or P10 (T09) ruling.** `00-README` §10's amendment
  rule: the decision record and *every* document that applies the decision change in the **same
  commit**. A doc set where 06 applies a superseded decision and `indelible.md` does not is worse than
  no doc set, because both look authoritative.

**Not irreversible, and must not appear in this diff at all:** `drift_schemas/`, `lib/core/db/`,
`android/`, `ios/`. **If a file under any of those paths shows up in this branch, stop and find out
why.** The design system stores nothing and touches no native file; N11 owns the launch layers.

**Risks specific to N09:**

| Risk | Why it bites here | What holds it |
|---|---|---|
| **P7 is two conflicts, not one** | Half is the *typeface* — Indelible §3.2 needs two bundled families (serif = record, sans = control, which **is** the design) and the engineering set bundles one, `AtkinsonHyperlegibleNext[wght].ttf`. Half is the *weight axis* — 390 / 420 / 520 / 600 cannot be expressed as a `FontWeight` at all, and `06 §5.2` records the required axis as 500–700. Closing one half and declaring P7 ruled is the failure mode | T05 states both halves, runs `REFERENCES §22` **C1** (download the font, read `fvar`, `ls -l`) *before* the pubspec entry is written, and takes an owner ruling on the family count |
| **`Text.build` merges `FontWeight.bold` and does not touch `fontVariations`** | A weight set through `FontVariation('wght', 390)` silently ignores the user's Bold Text accessibility setting. The bug is invisible on a developer's device | Named in T05's gotchas; `type.weight_cap` already bans w800 / w900 for the mirror-image reason (flutter#139712) |
| **P14 (`#0B0D0E` vs `#0A0A0B`) is ruled in N11-T04, one epic later** | But `nSurface04`'s value is authored **here**, in T01, and `launch.colour_parity` parses that constant out of `primitives.dart`. Pick a value in T01 without recording the conflict and N11-T04 has nothing left to rule | T01 records P14 in the file and in the PR; T03 writes `no palette is brighter than the native launch colour` so it still means something after N11 rules |
| **P6 — Indelible ships two themes, `06 §4` ships six palettes** | `ShedPaletteId`, its stored keys `night` / `amber` / `red` and the four Settings labels are **frozen by R35**. Indelible publishes no amber table and no high-contrast variant | T03 supplies values, never a new palette id, and every value — from either document — is re-measured by the test rather than trusted |
| **P9 (16 pt vs 8–12 px separation) is ruled in N33-T03** | T07's single-widget test could accidentally freeze one of the two numbers into a passing assertion, which then reads as settled | T07 asserts the **60 / 64 floor** and the hit slop, and says nothing about separation |
| **The pretty value gets "restored" in review** | `#6B675F` as struck ink (3.52:1) and `#A63A32` as the madder (3.08:1) both look better and both lost to rule 4 already (`indelible.md §2.4`) | `contrast_test.dart` fails and names the pair. Rule 4 does not negotiate with taste |
| **`contrast_test.dart` proves arithmetic, not rendering** | It measures authored constants. The pixel-sampling `textContrastGuideline` run is 42 runs over fourteen variants and cannot exist until screens do (`12 §7.6`) | Stated in T08's comments and in the Notes below; the second group lands in the same file at N33 |
| **A gate written before the thing it gates** | S7 is exactly this defect, once. A fifth "gate" here that iterated an empty list would repeat it — and would pass, silently, forever | T08 lands four files and each says in a comment why it is not the sweep |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] `lib/core/ui/` holds exactly the files `CONVENTIONS §1` gives it, plus `components/shed_tap_target.dart` — there is no `lib/design/` folder and no shared widget under a feature's `widgets/`
- [ ] `tool/policy_allowlist.txt`'s `[exempt]` section has **exactly four lines** (R56), and the two added here carry their reason in T01's commit message
- [ ] `shedPalettes` has six entries, every `(id, highContrast)` pair appears once, and `contrast_test.dart` recomputes every published ratio
- [ ] `Brightness.light` appears nowhere under `lib/`, and no `themeMode` can follow the system
- [ ] `package:intl` is imported by exactly one file under `lib/` outside `lib/data/`
- [ ] every `ShedTapTarget` instance requires its `semanticLabel` at the type level
- [ ] **P7 and P10 are each either closed by a ruling that amends its losing document in the same commit, or carried into the PR body as open with both sides cited** — never silently resolved
- [ ] the diff contains no file under `drift_schemas/`, `lib/core/db/`, `android/` or `ios/`
- [ ] no element of `the-register.md` or `strip-bay.md` appears in the diff, in a comment, or in a review remark

## Demoable on merge

`contrast_test.dart` recomputes every pair in all six palettes and holds 4.5:1 on text and
3:1 on rules and marks, and `ShedTapTarget` cannot be constructed without a `semanticLabel`.

## Notes

`tap_target_test.dart` and `semantics_gate_test.dart` are **sweeps over `kPumpableVariants`**
(`12 §6.2`), and nothing to iterate exists yet. N09 lands `wcag.dart`, `contrast_test.dart`, a
single-widget `tap_target_test.dart` over `ShedTapTarget` and `reduce_motion_test.dart`; the sweeps are
N33-T02 and N33-T03. This closes critique defect S7.

Concretely: `kPumpableVariants` is a fourteen-entry `Map<String, Widget Function()>` declared once in
`test/support/harness.dart` — the thirteen `RouteNames` screens plus the export-banner variant (R58) —
and `test/support/harness.dart` itself is N12-T05. Four files iterate it: the 252-cell overflow matrix
(N33-T01), `semantics_gate_test.dart` (N33-T02), the geometric half of `tap_target_test.dart`
(N33-T03) and the pixel-sampling group in `contrast_test.dart` (N33). The single-widget
`tap_target_test.dart` this epic writes is the **same file**, extended later — not a different one.

`indelible.md §11`'s ten acceptance tests are this epic's own checklist. Four of them are provable at
N09 — **measurement** (`contrast_test.dart`), **64** (for `ShedTapTarget`), **two-voice** (the type
scale is split by voice, which is how rule 2 becomes checkable) and **Save** (zero hits on the string
`Save`). The other six need screens.

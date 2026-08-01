# N16 — Lambing Entry and the P8 ruling

| | |
|---|---|
| **`00-README` §9 step** | 6 (2 of 5) |
| **Depends on** | N15 |
| **Size** | L |
| **Was** | E13, plus the P8 ruling against `07 §5.4` and `12 §10.1` |
| **Branch** | `epic/n16-lambing-entry` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

The screen the shepherd is on while holding a lamb. Every field after the first tap is its own
committed write, and **birth type is counted, never chosen**.

Concretely, N16 authors `lib/features/lambing/lambing_entry_screen.dart`, its controller and write
controller, the read statement behind them in `LambingRepository`, and the six write verbs the screen
needs — `addLamb`, `setEase`, `addCare`, `removeCare`, `setBirthType`, `correctOccurredAt`. It also
**rules P8 against the three artefacts that still prescribe a chooser** (T02a) and gives
`declared_birth_type` the one writer it has never had anywhere in the plan.

## Why the epic sits here

`00-README` §9 puts Lambing Entry at **step 6**, immediately after Quick Entry end to end (step 5,
N13 + N14). Its stated reason, not re-derived here:

> *"The rest of the 3am path: Lambing Entry, Lamb Card, Foster, Pen Board — plus the one 60 s ticker.
> These are variations on machinery step 5 already built."*

Three consequences bind this epic's scope:

- Everything this screen writes goes through machinery that already exists. `WriteController.guard()`
  is N12-T04, `confirmSaved` and the receipt-is-the-committed-row rule are N14-T04, the margin strike
  is N14-T05, `ShedChoiceRow` and `ShedFieldRow` are N10-T06, `ShedKeypad` is N13-T04, `ShedPhoto`
  and the two capture gateways are N15. **N16 invents no machinery**; where it looks as if it needs
  some, the component is already in `lib/core/ui/components/` and a feature-local copy is a layer
  violation (R70).
- It comes **after** the schema freeze (step 3, N07-T08) by five epics, so nothing in this diff may
  touch a table. Every column this screen reads and writes — `lambings.declared_birth_type` nullable
  by R6, `lambings.ease` nullable, the two §12.5 provenance quads, `care_events.kind`'s closed
  `CHECK`, `lambs.birth_dam` and its `BEFORE UPDATE` trigger — was frozen at N07-T04 and N07-T08.
- It comes **before** N17 (Lamb Card) and N18 (Foster) because both are reached *from* this screen
  and both read rows only this screen creates. N17's `lambCardProvider` has nothing to read until
  `addLamb` exists.

`00-README` §9's two parallel tracks apply here in full: **accessibility** and **the ARB** are
authored inside each widget task, not swept up later. N33 only verifies.

## What is observably true when this epic merges

Run these on the merged `main` and watch them pass — this is the demo:

```bash
fvm flutter test test/features/lambing_entry_test.dart
fvm flutter test test/features/tap_budget_test.dart
fvm flutter test test/data/lambing_repository_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
fvm flutter test test/features/overflow_matrix_test.dart
make check && make test
```

- **Press the slab three times and the row reads `TRIPLET (COUNTED)`.** Nobody chose it. The label is
  derived from the un-struck `lambs` rows on every rebuild, and the tally widget holds **no counter
  field** — a stroke on screen exists if and only if a row exists in SQLite, which is what makes
  *"every write commits immediately"* geometry rather than a promise.
- **No widget anywhere in the tree carries a `birth_type` key.** A tree-walking assertion over every
  pumped `Key` proves it (T02), and it stays green for the life of the project. `grep -rn "birth_type"
  lib/features/` returns only `declared_birth_type` — the column, on the deliberate-declaration path.
- **Six taps from unlock to a lambing with one lamb**, on keyed finders, with the sixth tap on
  `lambing_entry.tally.stroke` (T02a). N14-T06 holds the first five.
- **Four superseded artefacts are amended**, in T02a's single commit, per `CLAUDE.md`'s amendment
  rule: `07 §5.4`'s six-tap composition, `12 §10.1`'s sixth tap, `CONVENTIONS §4.5`'s worked key
  example and R59 that rules on it, and `06 §12`'s `ShedChoiceRow` row.
- **`declared_birth_type` has exactly one writer** — `setBirthType`, reached only from the type cell
  or from the query mark (T06). Before this epic it had none anywhere in the plan, which is critique
  defect S4's second half.
- **A declared type that contradicts the strokes prints a query mark and adjusts nothing.** The test
  reads both values back out of the database after the mark renders and asserts neither moved.
- ***Not recorded* and *no* are different facts on screen.** Care state is `EXISTS` over `care_events`
  rows; there is no boolean column and no unticked checkbox that means "no".
- **An edited time prints both times**, with `RecordedTime.provenanceLabel`, never a hand-typed
  string, and `captured_at` never moves.
- **`kPumpableVariants` grows to two entries** and the count is still derived from the map, never
  typed (T09). N13-T07 was born with one.

What is deliberately **not** demonstrable yet: the 252-cell matrix in full (fourteen variants exist
only at N33), the goldens (N33-T07), and the reminder rows the colostrum care event will eventually
complete *from* (N24). See Notes.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/07-screens.md` | §1.2 (the one-query rule, stated exactly) · §1.3 (what a tap is) · §1.4 (the state vocabulary) · §2.2 (the empty-state row) · **§6.1–§6.5 (Lambing Entry, field by field)** · §15.1 (undo per verb) | the screen, its query, its states, its tap costs and its undo verbs |
| `docs/design/indelible.md` | §2.2 (the redundancy table) · §6.2 mark 3 and mark 4 (the query mark and the tally stroke, with the five-bar SVG) · §7.7 (boxed versus unboxed stamps) · §7.9 (**segmented choice, and why there is no birth-type control**) · §7.10 (the check control) · §7.12 (the text field, and no placeholder) · §9 screen 4 | every pixel, mark, stamp and state of this screen |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree) · §1.1 layer rules 3, 4, 5, 6 · §2.1 · §2.2 · §2.4 · §2.9 · §2.13 (**the two throwing verbs**) · §3.2 · §3.4 · §4.5 (widget keys) · §4.6 (column names) · §5 (the words) · R3, R6, R30, R32, R33, R37, R44, R46, R53, R59, R66 | **BINDING** on every path, type, provider, column and word |
| `docs/engineering/03-data-model-and-schema.md` | §5.4 (`Lambings` + the `lambing_consistency` view) · §5.5 (`Lambs`) · §5.6 (`CareEvents`) · §5.11 (`MediaAssets`' four-way `CHECK`) · §5.12 (`VocabTerms`) · §10.1 (the six lists and forty keys) | every column, `CHECK`, index and vocabulary key this screen touches |
| `docs/engineering/05-domain-correctness.md` | §4 (`RecordedTime`, the quad, how it renders) · §7.5 (**rule 4 — never silently correct**, the `Warning` catalogue, `expectedLambCount`) | the provenance type and every warning that fires here |
| `docs/engineering/02-state-di-navigation.md` | §4.2 (auto-dispose policy) · §4.4 (`.select`) · §7 (**`WriteController.guard()` and the `ref.listen` switch**) · §7.1 (the four rules) · §8.1–§8.2 (the push helper and the stack) | the write path and the navigation this screen sits in |
| `docs/engineering/12-testing.md` | §2.3–§2.4 (**the ambiguous hour, and the two tiers above the domain tests**) · §3.3 (repository tests) · §3.5 (durability) · §6.1–§6.4 (the matrix and reachability) · §7.4 (the semantics gates) · §10.1 (the tap budgets) · §10.4 (a contradiction warns and does not mutate) · §10.5 (provenance round trip) | every test this epic writes, and the two it amends |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.2 (the eight label rules) · §3.4 (**`headingLevel`, and why Lambing Entry gets no level 2**) · §5.2 (the redundancy table rows for lamb status) · §8 (the ARB rules) | semantics and every string |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #11 · #12 · #19 · #22 · #43 · #54 · #57 · #59 · #69 · #103 | Flutter **3.44.8** / Dart **3.12.2** · `flutter_riverpod` **2.6.1** exactly · `drift` **2.34.2** |
| `CLAUDE.md` | **P8** (there is no birth-type chooser) · **P2** (there is no SnackBar) · the five safety rules · the amendment rule · the banned words | the two owner rulings that supersede written documents |
| `epics/00-PLAN-CRITIQUE.md` | **S4** (the whole ruling) · §11.4 (the skills per epic) · §11.5 (the gate table) | why T02a exists and what it must amend |
| `shed-book-spec.md` | §7.2 (the lambing fields) · §12.4 (never silently correct) · §12.5 (honest timestamps) | the product promise this screen keeps |

## Tasks

Strictly sequential. Each task depends on the one before it, because the screen accretes: there is no
tally without the statement that feeds it, no lamb row without a stroke to write it, and no
contradiction to mark until both a declared type and a count exist.

| Task | Depends on | One line |
|---|---|---|
| [N16-T01](N16-T01-lambingentryprovider-one-statement-for-a-lambingid.md) | N15-T06 | `lambingEntryProvider` — one statement for a `LambingId` |
| [N16-T02](N16-T02-the-lamb-tally-strokes-with-a-true-five-bar-gate.md) | N16-T01 | The lamb tally — strokes with a true five-bar gate |
| [N16-T02a](N16-T02a-rule-p8-against-07-54-and-12-101-and-land-the-sixth-tap.md) | N16-T02 · N14-T06 | Rule P8 against `07 §5.4` and `12 §10.1`, and land the sixth tap |
| [N16-T03](N16-T03-addlamb-and-the-lambs-list.md) | N16-T02a | `addLamb` and the lambs list |
| [N16-T04](N16-T04-lambing-ease-15-and-setease.md) | N16-T03 | Lambing ease 1–5 and `setEase` |
| [N16-T05](N16-T05-care-events-as-exists.md) | N16-T04 | Care events as `EXISTS` |
| [N16-T06](N16-T06-the-warning-strip-a-query-mark-that-adjusts-nothing.md) | N16-T05 | The warning strip — a query mark that adjusts nothing |
| [N16-T07](N16-T07-correctoccurredat-and-the-provenance-header.md) | N16-T06 | `correctOccurredAt` and the provenance header |
| [N16-T08](N16-T08-assistance-detail-presentation-vocabulary-note-and-attachmen.md) | N16-T07 | Assistance detail, presentation vocabulary, note and attachments |
| [N16-T09](N16-T09-the-matrix-variant-and-the-empty-state-row.md) | N16-T08 | The matrix variant and the empty-state row |

**The one ordering wrinkle, and it is deliberate.** T02 lands the slab, its press and the minimum
`LambingRepository.addLamb` its own Definition of Done requires — *"each stroke commits immediately"*
is not satisfiable by a widget that renders seeded rows. **T03 lands the verb's contract**: the
`Future<LambId>`-and-throw semantics against `WriteOutcome`, the `birth_dam` immutability proof
against the trigger, the durability read-back at the data tier, the proof that no `sex` is ever
originated, and the three indented lamb sub-rows. T02a sits between them because its six-tap assertion needs a
pressable slab and nothing more. Do not merge T02 and T03; the second is where the contract is
proved and the first is where the pixels are.

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N15 is merged and `main` is green before this starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version          # must print 3.44.8; .fvmrc is the pin
git checkout -b epic/n16-lambing-entry
```

**2 — One commit per task, ten commits, in task order.** Each task file names its commit line
verbatim; use it. Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

Two commits in this epic carry an extra obligation:

- **T02a is a `docs:` commit that changes four artefacts at once** and is the only commit in the
  epic that touches `docs/` and `CONVENTIONS.md`. `CLAUDE.md`'s amendment rule is explicit: the
  decision record and *every* document that applies the decision change in the **same** change. A
  branch where `07 §5.4` still prescribes five big buttons and `test/features/` forbids them is
  worse than either state alone.
- **T02 raises a naming question it may not settle on its own authority.** `CONVENTIONS §2.13`
  publishes `Future<LambId> addLamb(LambingId lambing, {required Sex sex})`, and a slab press records
  a lamb *before* anyone has looked at it. `lambs.sex` is nullable and R45 is explicit that `NULL` is
  not `Sex.unknown`, so passing `Sex.unknown` to satisfy the signature is the app originating a fact
  — §12.4, at the write path. A numbered ruling in `CONVENTIONS §6` is the mechanism and the next
  free number is **R75**; T02 is the first caller and therefore takes it, and T03 is where the
  resulting behaviour is proved. If it is not ruled, it goes in the PR body as open with both sides
  cited — never implemented around.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test         # -P ci-fast, randomised order, + TZ=Europe/London --tags uk-zone
```

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the
diff in `00-README` §10's irreversibility order. For this branch that order is:
`CONVENTIONS.md` and the `docs/` amendments made by T02a → `lib/data/lambing_repository.dart` →
`lib/l10n/app_en.arb` → `lib/features/lambing/` → `lib/routing/routes.dart` → `test/`.
`lib/data/**` is never waved through, however small: it is the only layer that writes.

**4 — Open the PR and answer the five §12 questions** in `.github/pull_request_template.md`
**verbatim, in the PR body**. `00-README` §7.4: the PR is *where* the safety review happens. Unlike
most epics, **four of the five land here**, and the answers are the point of the epic:

- **§12.1** — no withdrawal period is reachable from this screen. Say so, and say that N20 owns it.
- **§12.2** — the two `CHECK`s this screen can trip (`birth_weight_g BETWEEN 200 AND 20000`,
  `volume_ml BETWEEN 1 AND 2000`) are unit-slip guards, not husbandry opinions, and no number on the
  screen is originated by the app.
- **§12.4** — birth type is derived from the strokes and labelled `(COUNTED)`, so the commonest
  contradiction is structurally impossible; where a type *is* declared and disagrees, a query mark
  prints and neither value moves. Name the test that proves it.
- **§12.5** — the event time sits in the header with its provenance label at all times, and an edited
  time prints both times.

**5 — Wait for the pipelines.** Three jobs run for this epic and each proves a different thing.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` · the `NSAppTransportSecurity` grep | The layer rules, which are where a screen like this fails first: no `package:drift` and no `lib/core/db/` import under `lib/features/`, no sibling-feature import (this screen must not reach into `quick_entry/`), no `lib/domain/validation/` import from `lib/data/` — the mechanism that makes a repository incapable of producing a `Warning` (R53). It also holds `ui.spinner` (no `CircularProgressIndicator` while the statement loads), `gesture.*` (the slab is a tap, never a drag), `token.raw_color`, `db.save_verb`, and every banned word in the diff |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | A **negative**, and that is the point: the schema froze at N07-T08 and N16 stores nothing new. If `drift_schemas/` moves on this branch, a table changed — stop and find out why. The only legitimate reason this job goes red here is a `.drift` file edit, and this epic edits none |
| `test` | `flutter test -P ci-fast` randomised · `TZ=Europe/London --tags uk-zone` over the whole suite, **unscoped** · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · the coverage artefact (reported, **never** gated) | `lambing_entry_test.dart`, `lambing_repository_test.dart`, `tap_budget_test.dart` and `overflow_matrix_test.dart`. The `uk-zone` leg is load-bearing for **T07**: `12 §2.4` already publishes `test/data/lambing_ambiguous_hour_test.dart`'s *"correcting a time INTO the repeated hour keeps the original and says so"*, and it only exercises the ambiguity when the leg runs unscoped under `TZ=Europe/London`. An untagged DST case passes for the wrong reason |

`android` also runs on every PR (`13 §4.2`), builds the release AAB and asserts **G1**. N16 changes no
native file and no permission — the photo and voice paths were wired at N15 and merge zero Android
permissions (decision #77) — so it proves nothing this epic authored, but it must stay green.

Goldens do **not** run on this PR: the `goldens` job is `v*` or `workflow_dispatch` only. The eight
images are N33-T07.

**6 — Merge, delete the branch, and only then cut N17.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git checkout main && git pull --ff-only
# confirm main is green, then:
git checkout -b epic/n17-lamb-card
```

N17's `lambCardProvider` reads rows only `addLamb` creates, and N18's foster flow reads
`lambs.birth_dam` set here and immutable afterwards. Cutting either from anything other than a green
merged `main` means rebasing a screen onto a moving write path.

## Risks, and what is irreversible

**Irreversible in this epic — say it out loud in the PR body:**

- **T02a's four document amendments.** They rule an owner decision into the doc set. `07 §5.4`,
  `12 §10.1`, `CONVENTIONS §4.5` + R59, and `06 §12`'s `ShedChoiceRow` row all change in one commit.
  A partial amendment is the worst outcome available: a doc set where one authority still blesses a
  key that a test forbids trains readers to stop trusting both.
- **Widget keys are test contracts** (R59). `lambing_entry.tally.stroke` becomes the published worked
  example in `CONVENTIONS §4.5` and is tapped by `tap_budget_test.dart`. Renaming it later is a
  breaking change to `test/features/`, not a refactor.
- **Anything under `drift_schemas/` or `lib/core/db/tables/`.** Nothing in this epic may appear
  there. **If a file under either path shows up in this branch, stop and find out why** — the schema
  froze at N07-T08 and a column added now is a migration on somebody else's phone in April.
- **A `CONVENTIONS §6` ruling, if T03 takes one** (R75, the `sex` parameter). A numbered ruling is
  cited mechanically by every later fixer; getting the number or the file list wrong is worse than
  leaving it open.

**Risks specific to N16:**

| Risk | Why it bites here | What holds it |
|---|---|---|
| **The chooser comes back** | `07 §6.4` still reads *"Declare birth type — 1 tap, five big buttons"*, `12 §10.1` still taps `lambing_entry.birth_type.twin`, `CONVENTIONS §4.5` still publishes that key as its worked example, and `06 §12` still lists birth type as a `ShedChoiceRow` use. Four authorities, all wrong, all currently readable | T02's tree-walking canary — *no widget in the tree carries a `birth_type` key* — plus T02a amending all four in one commit. The canary is the mechanism; the amendments stop the next reader re-introducing it in good faith |
| **The tally acquires a counter** | The obvious Flutter implementation is `int _lambs = 0; setState(...)`. That is a draft state with a friendly name, it double-counts under `guard()`, and it survives a failed write | T02: the tally renders `data.lambs` from the stream and holds no field. A source-text assertion that the widget declares no mutable count |
| **A minus button appears on the tally** | Symmetry is seductive, and a mis-pressed slab feels like it wants a decrement | `indelible.md` §9: *"There is no minus button on the tally, because a tally that can go down is not a tally."* A mis-press is struck (P1's `struck` / `struck_at`, ruled at N00-T05) and the count reads `TWIN (COUNTED, 1 STRUCK)` |
| **`combineLatest` over four drift streams** | The screen shows a lambing, its lambs, its care events and its warnings. Four streams is the obvious shape and it tears (`07 §1.2`, drift#3338) | T01: one `customSelect` with an explicit `readsFrom:`, fanned in **in SQL**. A source-text assertion that `combineLatest` appears nowhere in the feature |
| **`customSelect` in the controller file** | `00-README` §8 step 4 says *"the read provider goes in the feature's controller file… aggregates use `customSelect`"*, and layer rule 5 forbids `lib/features/` from importing `package:drift` at all | T01: the statement lives in `LambingRepository`, the provider in the feature file watches the `Stream` it returns. The gate catches the alternative before the analyzer does |
| **Undo is described as a SnackBar in four places** | `07 §15.1` gives the window as *"SnackBar"* for `addLamb`, `addCare` and `removeCare` | **P2 supersedes it**: there is no SnackBar anywhere in `lib/`, including `feedback.dart`. Undo is a time-boxed strike in the row's own margin with its window stated in seconds, built at N14-T05. `test/policy/no_snackbar_test.dart` is already green and must stay so |
| **A care checkbox becomes a boolean** | Four booleans on `lambings` is smaller, faster and obviously wrong: it deletes *"colostrum given at 03:22"* and leaves the colostrum reminder nothing to be completed from | T05: `EXISTS` over `care_events`, three rendered states, and there is no boolean column in the frozen schema to regress into |
| **The warning strip starts adjusting things** | Every instinct says a contradiction should be fixed, and the fix is one `UPDATE` away | T06: the validator is a pure function in `lib/domain/validation/`, the repository has no import path to it (R53), `Warning` holds no writer and there is no `warnings` column. The test reads both values back after the mark renders |
| **The ease scale is treated as open** | `03 §10.1` records *lambing ease 1–5 vs SRUC's 6* as decision-record §7.1 item 15 | It was **ruled at N00-T04**, before the freeze. `lambings.ease` has `CHECK (ease IS NULL OR ease BETWEEN 1 AND 5)` in a frozen schema. T04 implements the ruling; it does not re-open it |
| **The ease descriptions get hard-coded** | `01`'s tree comment once said `lambing_ease.dart` held *"the five authored descriptions"* | R44 and R66: the domain type is an ordinal with no descriptions; the keys are `ease_1`…`ease_5` in `vocab_terms`; the labels are ARB messages. `assets/content/` holds only prose too long to be a UI string |
| **The malpresentation list gets read from `assets/content/`** | T08's own brief once said so, and so does `01`'s tree comment | R66 again: eight `mp_*` keys seeded in `first_run.dart`, eight ARB messages, and `assets/content/` carries one provenance line per list and nothing else. A test asserts the two sets are equal |
| **`beginLambing` and `addLamb` get "fixed" to return `WriteOutcome`** | Every other verb in the app does, and consistency is a strong pull | R32 and R3: they are the only two verbs that return an id and throw, because there is no id to hand back on failure and the screen cannot open. `07 §6.1`'s `WriteCommitted(:final id)` snippet is wrong twice over and was already rewritten |
| **The `LEFT JOIN` on care events loses the pre-lamb ones** | `care_events`' `CHECK` is *exactly one* of (lambing, lamb). Joining only `c.lamb = l.id` silently drops every care event recorded before the first stroke | T01: the second arm `OR (l.id IS NULL AND c.lambing = lg.id)` is in `07 §6.2` and is easy to drop as redundant. A test records colostrum with zero lambs attached and reads it back |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] **no widget in the tree carries a `birth_type` key**, proved by a tree-walking assertion that runs on every push
- [ ] `07 §5.4`, `12 §10.1`, `CONVENTIONS §4.5` + R59 and `06 §12`'s `ShedChoiceRow` row are all amended in T02a's single commit
- [ ] `declared_birth_type` has exactly one writer, and it is the deliberate declaration in T06
- [ ] the feature reads **one** statement; `combineLatest` appears nowhere under `lib/features/lambing/`
- [ ] `package:drift` and `lib/core/db/` appear nowhere under `lib/features/`
- [ ] every care state is a row; there is no boolean care column and no unticked box that means *no*
- [ ] the six taps in `tap_budget_test.dart` land on keyed finders and the sixth is a tally stroke
- [ ] every time-shaped test has a case in the ambiguous hour **01:00–01:59**, tagged `uk-zone`
- [ ] the diff contains no file under `drift_schemas/`, `lib/core/db/tables/`, `android/` or `ios/`
- [ ] no element of `the-register.md` or `strip-bay.md` appears in the diff, in a comment, or in a review remark

## Demoable on merge

You press one slab per lamb as it arrives and the row reads `TRIPLET (COUNTED)` — nobody ever
chose it — and no widget anywhere in the tree carries a `birth_type` key.

## Notes

**This epic closes critique defect S4**, which `00-PLAN-CRITIQUE.md` calls *"the single most important
correction in this document."* As the plan stood, `tap_budget_test.dart` could not go green and
`declared_birth_type` — a nullable column, a `Warning` code and an export column — had no writer
anywhere. N14-T06 holds five taps to the committed row; N16-T02a holds the sixth and rules P8 against
the artefacts that still contradict it.

**What N16 deliberately does not do.** The lamb's own page — sex, birthweight on the keypad, death
with a cause, pet-lamb status — is **N17**; this screen renders the three indented sub-rows and
pushes. Fostering is **N18**. The colostrum and navel reminders that a care event will complete
*from* are **N24**: `03 §5.6` names the wiring, and T05 leaves the transaction boundary commented for
it rather than reaching forward.

**`kPumpableVariants` is at two entries after T09** — `quick_entry` from N13-T07 and `lambing_entry`
from here. The fourteen-entry table and the 252-cell arithmetic (R58) arrive at N33; until then the
count assertion follows the map's own length and the matrix seeds through `test/support/seeds.dart`,
not `restoreFixture` — the fixtures are written by `tool/seed.dart` through the restore path at N23
(critique defect S3).

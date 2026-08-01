# N20 — Treatments and withdrawal

| | |
|---|---|
| **`00-README` §9 step** | 7 |
| **Depends on** | N19 |
| **Size** | L |
| **Was** | E17 |
| **Branch** | `epic/n20-treatments-and-withdrawal` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

The medicine book, the countdowns, and the one control in the product where a wrong number hurts
somebody who is not the user. Spec §7.5: *"The withdrawal period is always entered by the user from
the bottle label. The app ships no default values and makes no suggestion. A wrong withdrawal number
puts meat or milk into the food chain."*

Seven tasks: the write verb and its 0..2 child rows, the entry control that has no default and no
placeholder, the stored clear date rendered as a day tally, repeat-last-treatment with the days
deliberately blank, the soft void, the three renderings and the disagreement badge, and the §12
disclosures with the matrix row and the two-tap budget.

**This epic writes no schema and no arithmetic.** `treatments`, `treatment_withdrawals`, every CHECK
and `idx_withdrawal_clear` were frozen in N07-T05 and snapshotted in N07-T08. `WithdrawalPeriod`,
`WithdrawalStatus`, `clearDateFor`, `computeWithdrawalStatus` and `checkClearDate` were finished in
N05. If a file under `drift_schemas/`, `lib/core/db/tables/` or `lib/domain/withdrawal/` appears in
this branch, stop and read `00-README` §10 rule 4.

## Why the epic sits here

`00-README` §9 puts Treatments at **step 7**, and gives the reason in one sentence, not re-derived
here:

> *"The highest-stakes screen in the app, and the domain behind it was finished in step 2 — so this
> is presentation over settled arithmetic, which is the right way round."*

Four consequences bind the scope:

- It is **after N05** because every arithmetic question this screen could ask has an answer with a
  test on it. There is no clear-date arithmetic in a widget test in this epic; there is a stored
  column and a renderer.
- It is **after N07** because §12.1 is held at *unpersistable* by a schema fact — `days` has no
  `defaultValue` and no `clientDefault`, and **no row for a target means `NotRecorded`**. Nothing in
  N20 may re-express that as a Dart check, and nothing may add the column that would make a default
  possible.
- It is **after N10** because `ShedCountdown`, `ShedFieldRow`, `ShedKeypad` and `ShedStatusBadge`
  already exist, and `ShedFieldRow` already has **no parameter capable of carrying a placeholder**
  (N10-T06). That is the system-level half of safety rule 1; this epic is the screen-level half.
- It is **after N19** because the pen board settled how a value that changes with no write is
  rendered — derived at build from `minuteTickProvider`, never stored, never bound into SQL — and
  the withdrawal countdown is the second and last consumer of that rule.

Both tracks `00-README` §9 says run from day one run here: **accessibility** — every
`semanticLabel`, `headingLevel` and widget key is authored in the commit that creates the widget —
and **the ARB**, where every string lands with a `description` and no domain noun is a literal
(10 §8.5). N33 only verifies.

## What is observably true when this epic merges

Run these on the merged `main` and watch them pass — this is the demo:

```bash
fvm flutter test test/data/treatment_repository_test.dart
fvm flutter test test/features/treatments_test.dart
fvm flutter test test/features/tap_budget_test.dart
fvm flutter test test/policy/withdrawal_has_no_default_test.dart
fvm flutter test test/policy/disclaimer_is_referenced_test.dart
fvm flutter test test/features/overflow_matrix_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check && make test
```

- **Repeat last treatment is two taps and does not copy the days.** The sheet prints the previous
  treatment in full — product, dose, route, batch, and the previous figure carrying
  `Disclaimers.withdrawalProvenance` — and where the new days would be it prints
  `DAYS NOT COPIED — READ THE BOTTLE`. The committed row has **no** `treatment_withdrawals` row.
- **An untouched withdrawal field commits no child row at all.** Not a zero, not a null — no row.
  `db.select(db.treatmentWithdrawals).get()` returns empty, and `withdrawalFor` answers
  `WithdrawalNotRecorded`.
- **A zero-day withdrawal clears tomorrow.** The one case that proves `0` is a real label value and
  not a fallback: the period elapses at the moment of administration, which is almost never local
  midnight, so today is a partial day.
- **A bottle with two numbers produces two countdowns.** Meat and milk are separate rows, unique on
  `(treatment, target)`, each with its own clear date and its own day tally.
- **The rendered clear date is the stored one.** Change the device zone, re-pump, and the date does
  not move — because nothing on a build path calls `clearDateFor` or `computeWithdrawalStatus`.
  `grep -rn "clearDateFor\|computeWithdrawalStatus" lib/features/` returns nothing.
- **A voided treatment is still there.** Struck through in the medicine book with its void date,
  still carrying the withdrawal figure it was saved with, still in `treatments.csv` with
  `is_voided = 1` — and gone from the countdowns, because the countdown asks *is she clear?* and a
  voided record cannot answer it.
- **A disagreeing clear date prints both numbers and changes neither.** Stored first, then what
  today's details would give, then *"Nothing has been changed."* There is no `fix()` anywhere.
- **Every disclosure on the screen is a reference.** `Disclaimers.withdrawalCaveat` above the
  control, `Disclaimers.withdrawalProvenance` beside every figure, `Disclaimers.exportFooter` as the
  medicine book's permanent 18 px footer — and the single-definition test still counts exactly one
  literal in the codebase.
- **`treatments` is a row of `kPumpableVariants`** and pumps clean at 3 devices × 3 text scales × 2
  bold states, with the day tally still legible at 200%.
- **Nothing about money renders.** Treatments are never capped — the free tier caps seasons and ewes
  only, and `recordTreatment` does not take an `EntryContext`.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/07-screens.md` | **§10** (all of it: the one statement and its fan-out, the safety-critical control, the six states, actions and tap costs, the four §12 disclosures), §1.3 (counting taps), §1.4 (the state vocabulary), §1.5 (the disclosure matrix row for screen 8), §15.1–§15.3 (undo per verb — a treatment's undo is a soft void), §19.2 (Treatments is one of the seven screens with no cap surface) | the screen brief this epic implements |
| `docs/engineering/05-domain-correctness.md` | **§3** (all of it: why `int?` is lossy, the sealed type, the persistence contract, the output type, the algorithm, the conservative-interpretation argument, **§3.8** stored once and the disagreement, **§3.9** the two gates, **§3.10** the three paths that route around the type), §4.1–§4.3 (`RecordedTime` and how provenance renders), §7.1, §7.4, §7.5 | the arithmetic, the mechanism, and the three ways this screen could defeat it |
| `docs/engineering/03-data-model-and-schema.md` | **§5.8** (`Treatments` and `TreatmentWithdrawals` in full — every column, index, CHECK and `ON DELETE`, and the two gates), §2 (`mixin Identified`, no `DEFAULT` on an advice column), §4 (instants as INTEGER, civil dates as TEXT), §5.12 (`vocab_terms` and the `rt_*` route keys), §5.14 (`TreatmentRepository` owns both tables and nothing else) | the storage shape this epic reads and writes, and may not change |
| `docs/design/indelible.md` | **§8 screen 8** (the medicine book, the entry cells, the blank days cell under a dotted rule, `REPEAT LAST TREATMENT`, the countdown rows), **§7.6** (the withdrawal countdown — 88 px row, the day tally, `+n` at 28 marks, and the four states), **§7.12** (the text field, and *"there is never placeholder text inside a field"*), §7.7 (boxed and unboxed stamps — `YOUR ENTRY` is unboxed), §2.7 (two non-colour channels per state), §6.2 (the six marks — dagger, query mark, tally stroke, strike), §1.2 Rule 1 (nothing is removed, only struck), §9 (the safety table, rule 1) | **the design system of record.** What the screen actually looks like |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree, the eight layer rules), §2.4 (`WriteOutcome`), §2.6 (`Warning`, `WarningCode.clearDateDisagrees`), **§2.7** (the withdrawal types and their exact signatures), §2.13 (`TreatmentRepository`, `recordTreatment`, `voidTreatment`), §2.14 (`Disclaimers`), §3.1–§3.4 (`treatmentRepositoryProvider`, `treatmentsProvider`, `minuteTickProvider`, `treatmentsControllerProvider`, `treatmentWriteControllerProvider`), §4.1, §4.5, §4.6, §5, R3, R18, R19, R23, R30, R31, R32, R33, R37, R53, R57, R58, R59, **R60**, R70 | **BINDING** on every path, type, provider, key and word |
| `shed-book-spec.md` | §7.5, §12.1, §12.3, §12.4, §12.5, §5, §15 | the five bullets this screen is, and the four safety rules it carries |
| `docs/engineering/12-testing.md` | §2.2–§2.5 (time in tests, the advancing fake clock, the ambiguous hour, the three commands), §3.1–§3.3 (`testDatabase()`, real SQLite over mocks), §5 (`pumpApp`, `Device`, and the screen-driving helpers that stay private to one file), §6.1–§6.2 (the 252-cell matrix and `kPumpableVariants`), §7.4 (the sweeps N33 runs over this row), **§10.1** (the published two-tap repeat test), **§10.3** (the published withdrawal policy file) | every test file this epic writes, and two published tests it must make compile |
| `docs/engineering/10-accessibility-and-i18n.md` | **§5.2** (the redundancy table — the four withdrawal renderings and why they split on a *type*), §3.2–§3.4 (labels, `spellOutTag`, headings), §4 (the treatments row in the screen-title table), §8.4–§8.5 (the ARB and the terminology placeholder), §11 (the checklist line naming `ShedCountdown`) | every label, and which state renders which words |
| `docs/engineering/06-design-system.md` | §12 (`ShedCountdown`, `ShedFieldRow`, `ShedKeypad`, `ShedStatusBadge`, `ShedEmptyState` — their size contracts and states), §5.4 (tabular figures), §6.1 (`tapMin` 60 / `tapPrimary` 72 / `tapHero` 88, `gapMin` 16), §8.1 (the keypad is the only numeric entry route) | the components this epic composes and may not re-invent |
| `docs/engineering/09-export-formats.md` | §3.3 (`treatments.csv` — the 29 columns, the pivot, `not_recorded`, *"blank is never `0`"*), §5 (the medicine record PDF and the struck row), §7 (the disclaimer placement per format) | what N21 will read out of the rows this epic writes |
| `docs/engineering/CODE-REVIEW-CHECKLIST.md` | **§2.2** (§12.1 as a review question, and the repeat-last example that passes every gate and is still wrong), §2.5, §2.6 | the review this branch gets, written down in advance |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #29, #31, #50, #51, #52, #62, #69, #90, #103 | `flutter_riverpod` **2.6.1**, `drift` **2.34.2**, Flutter **3.44.8** / Dart **3.12.2** |
| `docs/skills/02-build-manifest.md` | §4.1 (**P2** — there is no SnackBar; the receipt is the committed row and undo is a time-boxed strike whose window is stated in seconds), §4.3 (Indelible only), §4.4 (the two artefact defects) | the owner rulings that supersede a written document |
| `CLAUDE.md` | the four non-negotiables · the vocabulary table | *withdrawal period*, *clear date*, *record*, *warning*, *provenance* — and the banned words |
| `epics/00-PLAN-CRITIQUE.md` | §11.2 (the seven tasks), §11.3 (the two named anchors), §11.4 (this epic's two skills), §11.5 (the schema freeze as a gate) | why the epic is seven tasks and which two are named in the critique |

## Tasks

Strictly sequential. Nothing can be entered before a verb writes it, nothing can be rendered before
there is a stored date to render, nothing can be repeated before there is a full record to repeat,
nothing can be voided before there is a row, no mode can be selected before the rows exist, and the
matrix cannot pump a screen that is not finished.

| Task | Depends on | One line |
|---|---|---|
| [N20-T01](N20-T01-treatmentrepositoryrecordtreatment-and-its-withdrawal-child.md) | N19, last task · the clear-date function from N05 · the treatment cluster frozen in N07 | `TreatmentRepository.recordTreatment` and its withdrawal child rows |
| [N20-T02](N20-T02-the-withdrawal-entry-control-your-entry-no-default-no-placeh.md) | N20-T01 · the sealed type from N05 | The withdrawal entry control — `YOUR ENTRY`, no default, no placeholder |
| [N20-T03](N20-T03-the-clear-date-as-a-stored-fact-rendered-as-a-day-tally.md) | N20-T02 | The clear date as a stored fact, rendered as a day tally |
| [N20-T04](N20-T04-repeat-last-treatment-two-taps-and-the-days-are-not-copied.md) | N20-T03 | Repeat last treatment — two taps, and the days are not copied |
| [N20-T05](N20-T05-voidtreatment-a-soft-void-the-medicine-book-still-shows.md) | N20-T04 | `voidTreatment` — a soft void the medicine book still shows |
| [N20-T06](N20-T06-treatmentsprovidertreatmentmode-the-countdowns-and-the-disag.md) | N20-T05 | `treatmentsProvider(TreatmentMode)`, the countdowns and the disagreement badge |
| [N20-T07](N20-T07-the-12-disclosures-the-matrix-variant-and-the-two-tap-budget.md) | N20-T06 | The §12 disclosures, the matrix variant and the two-tap budget |

**Four names no document fixes, and where each is recorded.** `CONVENTIONS` §2.13 writes
`recordTreatment(...)` with no parameter list, and §3.2 types `treatmentsProvider` as
`StreamProvider.autoDispose.family<List<TreatmentRow>, TreatmentMode>` without shaping either type.
So this epic declares, each in the task file that creates it and each with its reasoning:
`recordTreatment`'s named parameters and its `List<WithdrawalPeriod>` (T01), `withdrawalFor`'s second
argument (T01), `TreatmentRow` / `TreatmentWithdrawalRow` (T06) and `enum TreatmentMode` (T06). If a
second document later needs any of them, the ruling belongs in `CONVENTIONS` §6 with a number, not in
a second spelling.

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N19 is merged, its branch is deleted and `main` is green
before anything here starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version                      # must print 3.44.8 / 3.12.2; .fvmrc is the pin
git checkout -b epic/n20-treatments-and-withdrawal
```

**2 — One commit per task, seven commits, in task order.** Each task file names its commit line
verbatim; use it. Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test         # -P ci-fast, randomised order, + TZ=Europe/London --tags uk-zone
```

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the
diff in `00-README` §10's irreversibility order. For this branch that order is:
`lib/data/treatment_repository.dart` → `lib/data/providers.dart` →
`lib/domain/validation/treatment_checks.dart` (read only — it is N05-T05's and must not have moved) →
`lib/l10n/app_en.arb` → `lib/routing/routes.dart` → `lib/features/treatments/` → `test/`.
`lib/data/**` and anything within reach of `lib/domain/withdrawal/**` are **never** waved through,
however small. `00-README` §10 names withdrawal as one of the six things that is never waved through.

**4 — Open the PR and answer the five §12 questions** in `.github/pull_request_template.md`
**verbatim, in the PR body**. Four of the five land squarely on this branch and must be answered with
a file and a test, not a sentence — this is the only epic in the backlog where that is true.

- **§12.1 — never default a withdrawal period.** Answer with three facts: the child table still has
  no `defaultValue` and no `clientDefault` on `days` (the schema JSON is unchanged, and `codegen`
  proves it); an untouched field commits **no row**
  (`test/policy/withdrawal_has_no_default_test.dart`); and repeat-last copies four fields and leaves
  the days blank (`test/features/tap_budget_test.dart`). Name the third explicitly — it is the one
  the checklist predicts will be got wrong.
- **§12.3 — never a compliance record.** `Disclaimers.exportFooter` is a permanent 18 px footer on
  the medicine-book mode, **referenced**; `disclaimer_is_defined_once_test.dart` still counts one
  literal in the codebase.
- **§12.4 — never silently correct.** `clearDateDisagrees` renders both numbers and writes neither.
  There is no `fix()`, no `warnings` column, and `lib/data/` still cannot import
  `lib/domain/validation/`.
- **§12.5 — timestamps carry provenance.** `administered_at` is written with the whole quad in one
  transaction; every rendered time carries `RecordedTime.provenanceLabel`; a bare `03:21` anywhere on
  this screen is a review failure.

§12.2 does not appear as a label anywhere — it binds as copy discipline. Say so, and say what held
it: the app renders the dose text verbatim and never parses it, ships no product database, offers no
conversion from milkings to days, and learns no "typical value".

**5 — Wait for the pipelines.** Three blocking jobs run for this epic and each proves a different
thing.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart run tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` | The rules this epic is most likely to break: `copy.disclaimer_retyped` (the one screen carrying three disclosures is the one where somebody types the fourth), `db.save_verb` and the banned `save`/`draft` vocabulary (there is a form on this screen and no Save button), `layer.data_no_validation` (`checkClearDate` is one import away from the repository), `layer.features` (a feature folder reaching for drift to answer *is she clear?*), the gesture ban (swipe-to-void is the obvious wrong answer) and the token rules |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | A **negative**, and it is the most important job on this branch: N20 stores into frozen tables and must move no snapshot. A red `codegen` here means somebody edited `lib/core/db/tables/treatments.dart` — which after N07-T08 is a migration on somebody else's phone, on the one table that carries a shepherd's medicine record |
| `test` | `flutter test -P ci-fast` randomised · `TZ=Europe/London --tags uk-zone` (**unscoped** — the tag selects the files) · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · coverage artefact (reported, **never** gated) | The seven anchors, the two published tests in `12 §10.1` and `12 §10.3`, and the 252-cell matrix. The `uk-zone` leg is what proves the clear-date write ran in `Europe/London`: under the runner's UTC there is no spring forward, and the 168-hour assertion passes for the wrong reason |

`android` also runs on every PR (13 §4.2) and must stay green; N20 changes no native file and no
permission, so it proves nothing this epic authored. **`goldens` does not run on this PR** — it is
`v*` or `workflow_dispatch` only, and no treatments image is in the eight-image budget (12 §8.2).
Do not add a `matchesGoldenFile` call here.

```bash
gh pr checks --watch
```

**6 — Merge, delete the branch, and only then cut N21.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git checkout main && git pull --ff-only
make check && make test                     # main green after the merge
git checkout -b epic/n21-export-csv-pdf-and-share
```

## Risks, and what is irreversible

**Irreversible in this epic — say it out loud in the PR body:**

- **Nothing here touches the schema, and that is the loudest sentence in this file.** The tables are
  frozen. If this branch contains a file under `drift_schemas/` or `lib/core/db/tables/`, the change
  is in the wrong epic and the correct next step is `00-README` §10 rule 4 — route it to the owner.
- **Every widget key introduced here is a test contract** (R59), read by four test files and by
  `12 §10.1`'s published tap-budget test: `treatment.withdrawal.enter_days` (already published in
  `CONVENTIONS` §4.5), `treatment.withdrawal.not_applicable`, `treatment.withdrawal.not_recorded`,
  `treatments.repeat_last`, `treatment.repeat.animal.<tag>`, `treatments.mode.countdown`,
  `treatments.mode.book`, `treatment.void.<id>`. They are recorded in `07-screens.md` §10 in the same
  commit that creates them.
- **`Disclaimers` is not edited by this epic.** The three strings were authored in N06-T09 and are
  referenced here. Editing one of them changes what every past export said, and the export is the
  only backup this product has.
- **Nothing else is irreversible**, and that is worth stating plainly: no snapshot, no native file, no
  published artefact, no allowlist line, no golden baseline. If this branch touches
  `tool/policy_allowlist.txt`, `android/`, `ios/` or `test/features/goldens/`, the change is in the
  wrong epic.

**Risks specific to N20:**

| Risk | Why it bites here | What holds it |
|---|---|---|
| **Repeat-last copies the days** | It is the helpful thing to do, it passes every gate, and `CODE-REVIEW-CHECKLIST` §2.2 prints the exact code that does it. NADIS: withdrawal periods *"can change for the same medicine and differ between products with the same active ingredient"* — the same trade name, bought twice, can carry two different numbers | T04: four copied fields, the days empty, `DAYS NOT COPIED — READ THE BOTTLE` where the value would be, and the NADIS sentence in a comment at the copy site so it is not "fixed" |
| **07 §10.4 reads as if the figure is carried forward** | *"the number being carried forward is the user's own previous entry, visible on screen at the moment of the commit tap"* — which is true of the **previous record shown as history** and false of the **new row**. `05` §3.10, `CODE-REVIEW-CHECKLIST` §2.2, Indelible §9 and this epic's own demo line all say the days are not copied | T04 §5.3 states the resolution in full: the sheet renders the previous treatment's figure with its provenance label; the committed row gets no `treatment_withdrawals` row. `12 §10.1`'s two assertions — `findsWidgets` on `'28'` **and** a blank days field — are both satisfied by exactly one reading |
| **The clear date is recomputed on build** | It is one function call away, it looks like removing a stored derived value, and it is wrong: `clear_date` is *"a record of what the app TOLD the user"* (#50), printed into a PDF that may already be in a vet's hands. A device that changed zone would quietly render a different date than the one on the bottle's label | T03: the display reads the stored column; `grep -rn "clearDateFor\|computeWithdrawalStatus" lib/features/` returns nothing, and it is in the epic DoD |
| **`ShedCountdown` is handed a `WithdrawalStatus`** | *"to handle all four in one place"* — 10 §5.2 names this as the one row in its table where the compiler is the gate. The widget takes a `ClearsOn`, so a countdown for a period nobody recorded is unconstructible | T03 and T06: `NOT APPLICABLE` and `NOT RECORDED` are painted by the treatment row itself, in the pixels the countdown would have occupied, with no countdown widget in the tree |
| **A nullable `int` creeps back in** | Every collapse of the three-state type into `int? days` reads as tidying. `0` is a real label value, so `?? 0` and `days ?? 0` are both indistinguishable from correct code | The type is N05's and the table is N07's; this epic only has to not defeat them. `withdrawalFor` returns a `WithdrawalPeriod`, never an `int?` |
| **The `:today` bind goes stale at midnight** | `07 §10.1`'s countdown arm filters `w.clear_date >= :today`. A bound parameter does not change at 00:00, and drift re-runs a statement only when a tracked table is **written** | T06 §5.3, and it is the same ruling N19-T02 made: the row set is what was under withdrawal when the screen opened, and every per-row figure — days left, `LAST DAY`, `CLEARED` — is derived at build from `minuteTickProvider`. A row that clears while you watch prints `CLEARED` in place. Nothing vanishes under your hand (Indelible Rule 1) |
| **A voided treatment keeps its countdown** | The row is still there by design, so every *is she clear?* surface must filter `voided_at IS NULL` explicitly — and there is more than one such surface (this screen, the pen tile's `statusAttention`, the Ewe Card, `latest_meat_clear_date` in the CSV) | T05: the countdown arm filters in SQL, and the test asserts a voided treatment is absent from countdowns **and** present in the book **and** present in the export |
| **The void becomes a delete** | It is the smaller diff and it makes the list tidier. The row may already have been printed into a medicine book handed to a vet; deleting it makes the paper and the phone disagree | 03 §5.7 has no delete verb for `treatments`; `TreatmentRepository` writes two tables and neither verb removes a row; T05's anchor asserts the row survives and is marked |
| **A second withdrawal figure appears with a different provenance** | Milk ships in the schema and the sealed type but not necessarily in the v1 UI (decision-record §7.1 item 10, ruled in N00-T04). Whatever that ruling said, the CSV writes both targets (09 §10 row 12) | T01 writes both targets from one list; the UI renders whichever targets have rows. Read N00-T04's ruling before deciding whether the control offers a milk field |
| **`Disclaimers` gets re-typed on the busiest screen** | Three of the five disclosures land here. The fourth typing of *"as entered by you"* is inevitable and it is invisible in review | `copy.disclaimer_retyped` is a gate row, `disclaimer_is_defined_once_test.dart` counts literals, and T07 adds `disclaimer_is_referenced_test.dart` — because the gate can only prove a re-type, never a **presence** |
| **A milkings-to-days conversion appears** | VICH expresses milk withdrawals in milkings; the arithmetic is one multiplication and it is banned outright — it assumes an interval the label did not state, which is the app originating a number (§12.2) and then presenting it as the user's own (§12.4) | `05` §3.2: a milkings-only label is `WithdrawalNotRecorded` with the number typed into the treatment **note** verbatim. `WithdrawalMilkings` does not exist in v1 |
| **`treatment.save` gets created** | `05` §3.9's gate-2 snippet and R59's example both name it, and it predates the no-Save rule. `save` is a banned word, `db.save_verb` is a gate row, and 07 §15.5 fails the build on an ARB key beginning `save` | T02 §5.3: the committing control is `treatment.commit`, recorded in `07-screens.md` §10 in the commit that creates it |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] the diff contains no file under `drift_schemas/`, `lib/core/db/`, `lib/domain/withdrawal/`, `android/`, `ios/`, `tool/policy_allowlist.txt` or `test/features/goldens/`
- [ ] `grep -rn "clearDateFor\|computeWithdrawalStatus" lib/features/` returns nothing — the display never recomputes a clear date
- [ ] `grep -rn "?? 0\|days ?? \|int? days" lib/features/treatments/ lib/data/treatment_repository.dart` returns nothing
- [ ] `grep -rn "domain/validation" lib/data/treatment_repository.dart` returns nothing (R53)
- [ ] every new widget key and every new ARB message is recorded in `07-screens.md` §10 in the commit that creates it
- [ ] `treatments.csv`'s three withdrawal states are reachable from data this epic can write — `days`, `not_applicable` and **`not_recorded`** — checked by reading `09 §3.3` against the rows in a seeded database

## Demoable on merge

**Repeat last treatment is two taps and does not copy the days** — it prints
`DAYS NOT COPIED — READ THE BOTTLE`.

## Notes

**What this epic deliberately does not build.** `treatments.csv`, the medicine-record PDF and the
share sheet are N21's; the withdrawal-end reminder row — written **inside this epic's transaction**,
which is why T01's transaction is one function and not three — is N24-T04's (critique S10); the
withdrawal figures on the Ewe Card timeline are N27's; `latest_meat_clear_date` on `ewes.csv` is
N21's; the semantics and tap-target sweeps over `kPumpableVariants` are N33's; the JSON backup's
`treatment_withdrawals` arm is N22's. This epic ends at four files under `lib/` plus the ARB, and six
under `test/`.

**Why there is no golden here.** The eight-image budget (12 §8.2) does not include a treatments
screen, and a golden would be the wrong instrument anyway: the safety property is *the absence of a
row*, which no PNG can show. The gates that hold it are a schema assertion and a widget test, and
decision #52 allows exactly two.

**The one thing that would change this epic's shape.** If N00-T04 ruled `WithdrawalTarget.milk` out
of the v1 **UI**, T02 renders one target and T01 still writes a list — the repository never learns
how many targets the screen offers. If it ruled milk in, T02 renders two `ShedFieldRow`s and the tap
budget for a new treatment grows by one. Read the ruling before writing T02; do not infer it from the
schema, which carries `milk` either way.

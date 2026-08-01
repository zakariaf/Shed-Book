# N27 — Ewe Card

| | |
|---|---|
| **`00-README` §9 step** | 10 (2 of 4) |
| **Depends on** | N26 |
| **Size** | L |
| **Was** | E23, closer task deleted |
| **Branch** | `epic/n27-ewe-card` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

The retention feature. In year two, *"what did 412 do last year?"* takes one second instead of an
evening with a shoebox — and `00-README` §9 says out loud that this is the one calm screen that is
**not** filler.

Seven tasks: one SQL statement that fans seven tables into one ordered history, the four-clause
summary line assembled in Dart from stored counts, the counts themselves maintained inside the writes
that invalidate them, a provenance label on every row and *as entered by you* on every withdrawal, the
disclosure the active-only tag ruling makes mandatory, the card's actions and `EweObservations`, and
the heading hierarchy that lets a screen-reader user reach the summary line in one flick.

The epic writes **no schema**. `lambings`, `treatments`, `care_events`, `foster_events`,
`ewe_observations`, `pen_occupancies`, `notes` and `ewe_summaries` were all frozen in N07-T03…T06 and
snapshotted in N07-T08 — including R37's provenance quad on the four tables that did not have it and
`notes.occurred_at`, without which four of this screen's seven arms cannot be written at all. If a
file under `drift_schemas/` or `lib/core/db/tables/` appears in this branch, stop.

## Why the epic sits here

`00-README` §9 puts the Ewe Card in **step 10**, with its stated reason, not re-derived here:

> *"The calm screens: Flock, Ewe Card, Season Summary, Note Search, Settings. Off the 3am path, so
> they may be daylight work — but the Ewe Card summary line is the **retention feature**, the reason
> the product exists in year two. Do not treat it as filler."*

Five consequences bind the scope:

- It is **after N07** because every one of the seven arms selects R37's quad, and R37 was ordered to
  land *before the first snapshot*. 07 §4.1 is explicit: until it did, *"those four arms cannot be
  written and the timeline ships with the three that can"*, and *"shipping the other four with a
  hard-coded `'auto'` is not an option: that is a §12.5 violation in the shape of a placeholder."*
  N07 landed it, so all seven arms ship here.
- It is **after N14 and N18** because `ewe_summaries` is maintained inside `LambingRepository`'s and
  `FosterRepository`'s transactions (CONVENTIONS §2.13), and both repositories have to exist before
  T03 can re-open them. Critique defect **S9** rules the placement stays and requires this epic to
  **name the files it re-opens** so the reviewer reads them in irreversibility order.
- It is **after N20** because the timeline renders treatment rows, and *as entered by you* beside a
  withdrawal figure is `Disclaimers.withdrawalProvenance` — referenced, never re-typed (decision #62).
  N20 is where the withdrawal UI and its copy were settled; this screen reads them back.
- It is **after N23** because the overflow matrix runs against `flock_400_3seasons.json`, and because
  `ewe_summaries` is **excluded from the backup** (09 §6, §7.9): a restored database has an empty
  summary table and every card reads zeros until something rebuilds it. T03 is where that rebuild verb
  comes from, and it is the reason T03 is not simply "add a counter".
- It is **after N26** because the Flock screen is the route into this card, `FlockRepository` already
  hosts the flock reads, `FlockWriteController` already exists for `createEwe`, and both screens live
  in the **same feature folder** — `lib/features/flock/` (CONVENTIONS §1). That is not a convenience;
  it is what makes this card's actions legal at all (see the risk table).

Both tracks `00-README` §9 says run from day one run here: **accessibility** — 10 §3.4 names this
screen as the reason `headingLevel` matters at all, and the hierarchy is authored in the commit that
creates the widget — and **the ARB**, where every string lands with a `description` and no domain noun
is a literal (10 §8.5). N33 only verifies.

## What is observably true when this epic merges

Run these on the merged `main` and watch them pass — this is the demo:

```bash
fvm flutter test test/features/ewe_card_test.dart
fvm flutter test test/data/ewe_summaries_test.dart
fvm flutter test test/features/overflow_matrix_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check && make test
```

- **One statement, seven kinds, one ordered history.** Open 412 and lambings, treatments, care events,
  fosters, observations, pen occupancies and notes arrive from one `customSelect` with an explicit
  `readsFrom:` over eight tables. `combineLatest` appears nowhere; the fan-in is `UNION ALL`.
- **The line reads *"3 seasons · avg 2.0 · assisted twice · prolapsed 2025"* — and it is not in the
  database.** Change the user's word for a ewe in Settings and the line re-renders; there is no
  formatted string anywhere in `ewe_summaries`, which stores counts only (03 §5.13).
- **Record a lambing and the counts move in the same transaction.** No sweep, no rebuild-on-launch, no
  refresh button. Kill the process mid-write and the summary is either fully updated or not written at
  all, because it is one `db.transaction`.
- **Restore a backup and the cards do not read zeros.** `ewe_summaries` is excluded from the backup by
  design; the rebuild verb runs after the swap and every card is correct on first open.
- **No timeline row renders a bare `03:21`.** Every row carries `recorded automatically` /
  `time entered by you` / `time edited by you` from `RecordedTime.provenanceLabel`, at the 18 px floor
  — the corrected rule, not the artefact's 14 px stamp (build-manifest §4.4 defect 2). An edited row
  prints both times.
- **Every withdrawal figure on the card carries *as entered by you*.** The string is
  `Disclaimers.withdrawalProvenance`, referenced;
  `test/policy/disclaimer_is_defined_once_test.dart` still passes, which means nobody re-typed it.
- **A struck record is still on the card, ruled through and legible.** Indelible §8 screen 2:
  *"Any struck entry in her history is still here, ruled through, at 5.75:1 — which is the whole point
  of year two."* Nothing on this screen filters `struck = 1`.
- **A reused tag says so.** Cull 412, create a new 412, open the new one, and the card discloses the
  earlier animal with a 60 pt route to her record — because tags are unique among **active** animals
  only (§7.0 ruling 7), and without the disclosure the ruling silently merges two ewes' histories in
  the reader's head.
- **An observation is a record, never a diagnosis.** *Prolapse* is written from the seeded, editable
  `ewe_observation` vocabulary; nothing on this screen infers `obs_poor_mothering` from a lamb death.
- **A screen reader reaches the summary line in one flick.** Rotor → Headings → the first stop is the
  summary. 10 §3.4: *"Without `headingLevel`, that user swipes through every field on the card and the
  retention feature is gone."*
- **`ewe_card` is the second row of `kPumpableVariants`** and pumps clean at 3 devices × 3 text scales
  × 2 bold states, including the empty card and the reused-tag state.
- **A lambing recorded at 01:30 on 25 October 2026 sorts and groups correctly**, in the hour that
  happens twice — and nothing on this card recomputes a season from the year of an instant.
- **Nothing about money renders.** The Ewe Card is not a shed screen, but 07 §19.2 is explicit that the
  upgrade affordance exists in exactly two places and this is not one: *"Free-tier history is never
  hidden, blurred, greyed out or made read-only, ever."*

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/07-screens.md` | **§4 in full** — §4.1 (the header watch and `eweTimelineQuery` printed arm by arm, its `readsFrom:` set, the `LAG` window function, the four arms R37 unblocked, `notes.occurred_at`), §4.2 (states incl. **Reused tag** and **Over-cap**), §4.3 (every action and its tap cost, R41 and R42 applied), §4.4 (the three §12 disclosures) · §1.2 (the one-query rule stated exactly) · §1.5 (the disclosure matrix and the §12.5 precondition) · §1.7 (headings) · §2.2 (the empty copy) · §15 (undo per verb) · §19.2 (nothing monetization-related here) | the screen brief this epic implements |
| `shed-book-spec.md` | §7.7 (the retention feature, the one-line summary, filter the flock by anything), §12 (the five safety rules), §15 (year two is when the app becomes irreplaceable) | why this screen exists |
| `docs/engineering/03-data-model-and-schema.md` | §5.13 (**`EweSummaries` — every column, and "counts only, never a formatted string"**), §5.7 (`EweObservations` and the §12.2 boundary in its doc comment), §5.2 (`Ewes`, `idx_ewe_tag_active`), §5.1 (`Seasons`), §5.9 (`PenOccupancies`), §5.12 (`Notes` — `season` nullable), §5.14 (who writes what), §6 (tag uniqueness, settled), §10.1 (the `ewe_observation` vocabulary — six seeded keys) | the storage shape this epic reads, and may not change |
| `docs/engineering/05-domain-correctness.md` | §4.1–§4.4 (`RecordedTime`, `provenanceLabel`, the quad, how it renders and exports), §6.5 (average litter size — `lambsBorn ÷ ewesLambed`, not configurable), §6.7 (assisted rate — both sides exclude unscored lambings, coverage always reported), §7.3 (**the origination line, and the legitimate-copy test that already contains this screen's summary line**), §8 (terminology), §2.9 (DST-1…DST-5) | the arithmetic behind the four clauses, and the two safety rules this screen touches |
| `docs/engineering/02-state-di-navigation.md` | §3.1 (the corrected 2.6.1 family shape, printed), §4.1–§4.2 (provider shapes, auto-dispose), §4.4–§4.5 (`.select`, the only permitted `AsyncValue` form), §7 (`WriteController`, `guard()`, the `ref.listen` switch), §8.1–§8.3 (`Routes.eweCard`, the three-deep stack, `PopScope` + `flushPending`) | every provider, the write path and the route |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree and the **eight layer rules** — 5 and 6 in particular), §2.1 (`EweId`, `EweObservationId`), §2.2 (`Instant`, `LocalDate`, `RecordedTime`, `TimeSource`), §2.8 (`EweSummary` / `EweObservation` are re-exported row classes), §2.13 (`FlockRepository`; `LambingRepository` owns `ewe_observations` **and** `ewe_summaries`; `SeasonRepository` owns `ewe_seasons`), §3.2 (**`eweTimelineProvider`**), §3.4 (`eweCardControllerProvider`; there is no `eweCardWriteControllerProvider`), §4.1–§4.6 (files, classes, providers, keys, database names), §5 (vocabulary), R18, R20, R28, R29, R32, R33, R37, R38, R41, R42, R53, R58, R59, R60, R61 | **BINDING** on every path, type, provider, key, column and word |
| `docs/design/indelible.md` | **§8 screen 2 (the card, printed)** — the summary first on its own 64 px row at 20 px, the current-status row, the season sub-heads, notes as ruled rows, the four in-stream word buttons, struck entries still present · §7.3 (**the ruled record row** and its six states, incl. **Struck** and **Queried**) · §7.4 (the flock row's *three*-clause summary) · §6.2 (the six marks: `†`, `‡`, `?`, tally, strike, `⌫`) · §2.7 (status without colour) · §9 (the 3am compliance table and where each §12 rule lives) | **the design system of record.** What the card actually looks like |
| `docs/engineering/10-accessibility-and-i18n.md` | **§3.4 (the heading table — and the paragraph naming this screen as the reason `headingLevel` exists)** · §3.2–§3.3 (label rules, `spellOutTag` on the tag range only) · §8.4 (dates and times are never formatted inside a message) · §8.5 (**the terminology-placeholder rule**) · §7.3 (the per-variant `headingLevel > 0` gate) · §11 (`sortKey` is banned) | every label, every heading, every ARB message |
| `docs/engineering/06-design-system.md` | §12 (`ShedSectionHeading` emits `headingLevel: 2`, `ShedEmptyState`, `ShedStatusBadge`, `ShedBottomSheet`, `ShedAnimalRow`), §6.1 (`tapMin` 60 / `tapPrimary` 72 / `tapHero` 88, `gapMin` 16), §5.5 (tabular figures), §10.3 (`SaveReceipt`) | the components this screen composes, none of which it may re-author |
| `docs/engineering/12-testing.md` | §2.1–§2.4 (one clock, `atFixed`, the ambiguous hour, the two tiers above the domain tests), §3.3 (`expectLater(stream, emitsInOrder([...]))`), §5.1–§5.3 (`pumpApp`, seeding, the twelve support files), §6.1–§6.2 (**`ewe_card` is variant 2 of the fourteen**), §7.3–§7.4 (the semantics gate), §8.2 (the eight goldens — `ewe_card_summary_line` is **deliberately not** one) | every test file this epic writes, and the one it must not |
| `docs/engineering/09-export-formats.md` | §6 (**`ewe_summaries` is excluded from the backup — a rebuildable cache, "rebuilt wholesale after a restore"**), §7.9 (excluded symmetrically) | why T03 ships a rebuild verb and not just an increment |
| `docs/engineering/01-architecture.md` | §4.2–§4.4 (event verbs, one `appNow()` per mutation, one statement per screen, `.distinct` in the repository, why `combineLatest` is build-breaking), §5.2–§5.3 (`WriteOutcome`, `ShedFailure`), §7.2 (bucket A — derived at render) | where the statement lives and what may not be stored |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #12, #44, #53, #54, #60, #62, #68, #69, #90, #104, #108, #113, #114 | `flutter_riverpod` **2.6.1**, `drift` **2.34.2**, `sqlite3` **3.5.0** (window functions since 3.25), Flutter **3.44.8** / Dart **3.12.2** |
| `docs/skills/02-build-manifest.md` | §4.1 (**P2** — no SnackBar; the receipt is the committed row), §4.3 (Indelible only), §4.4 defect 2 (**`AUTO-CAPTURED` is not an exempt stamp and must meet the 18 px floor**), §4.5 (P1 is ruled; P9 and P14 remain open) | the owner rulings that supersede a written document |
| `CLAUDE.md` | the four non-negotiables · the authority order · the vocabulary table · the skill routing table | *record*, *event*, *provenance*, *barren*, *stillborn*, *birth dam* / *rearing dam* |
| `epics/00-PLAN-CRITIQUE.md` | **S9** (this epic's cross-epic edit, and the instruction to name the re-opened files), §10 (one PR per epic, one commit per task), §11.3 (the N27-T02 anchor), §11.4 (the skills for N26–N29) | why T03 is written the way it is |

## Tasks

Strictly sequential. Nothing can be summarised before there is a history to summarise, nothing can be
maintained before the shape it maintains exists, no row can carry a provenance label before there are
rows, no disclosure can hang off a card that does not render, no action can be taken from a screen
that is not built, and the matrix cannot pump a screen that does not exist.

| Task | Depends on | One line |
|---|---|---|
| [N27-T01](N27-T01-ewetimelineprovider-the-fan-in-done-in-sql.md) | N26-T07 | `eweTimelineProvider` — the fan-in done in SQL |
| [N27-T02](N27-T02-the-one-line-summary-assembled-in-dart-from-counts.md) | N27-T01 | The one-line summary, assembled in Dart from counts |
| [N27-T03](N27-T03-ewe-summaries-rebuilt-inside-the-writes-that-invalidate-it.md) | N27-T02 · N14-T02 · N18-T01 | `ewe_summaries` rebuilt inside the writes that invalidate it |
| [N27-T04](N27-T04-timeline-rows-with-provenance-and-every-withdrawal-as-entere.md) | N27-T03 | Timeline rows with provenance, and every withdrawal *as entered by you* |
| [N27-T05](N27-T05-there-was-an-earlier-412-the-reused-tag-disclosure.md) | N27-T04 | *"There was an earlier 412"* — the reused-tag disclosure |
| [N27-T06](N27-T06-the-cards-actions-and-eweobservations.md) | N27-T05 | The card's actions and `EweObservations` |
| [N27-T07](N27-T07-the-heading-hierarchy-the-matrix-variant-and-the-empty-state.md) | N27-T06 | The heading hierarchy, the matrix variant and the empty state |

**Four names this epic fixes that no document fixes.** Each is recorded in its task file with the
reasoning; if a second document later needs one, the ruling belongs in `CONVENTIONS` §6, not in a task
file.

| Name | Task | Why it is not already fixed |
|---|---|---|
| `TimelineRow` + `enum TimelineKind` | T01 | `CONVENTIONS §3.2` types `eweTimelineProvider` as `StreamProvider.autoDispose.family<List<TimelineRow>, EweId>` and no document declares the class's fields. 07 §4.1 fixes the **columns**; the Dart shape is this epic's |
| `FlockRepository.watchEweTimeline` / `.watchEweSummary` / `.watchEarlierAnimalsWithTag` | T01, T02, T05 | 02 §3.1 already routes the card through `flockRepositoryProvider` (`repo.eweCard(arg)`), and R18's precedent is explicit — reads live on the repository that owns the area, never on a read-only query object wearing a repository's name |
| `LambingRepository.rebuildEweSummary` / `.rebuildAllEweSummaries` | T03 | 09 §6 says `ewe_summaries` is *"rebuilt wholesale after a restore"* and names no verb. Without one, every card reads zeros after a restore |
| `LambingRepository.recordObservation` | T06 | 03 §5.14 and CONVENTIONS §2.13 assign `ewe_observations` to `LambingRepository`; 07 §4.3 names the action (*"Record an observation, 2 taps"*) and no document names the method |

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N26 is merged and `main` is green before this starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version          # must print 3.44.8; .fvmrc is the pin
git checkout -b epic/n27-ewe-card
```

**2 — One commit per task, seven commits, in task order.** Each task file names its commit line
verbatim; use it. Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test         # -P ci-fast, randomised order, + TZ=Europe/London --tags uk-zone
```

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the diff
in `00-README` §10's irreversibility order. For this branch that order is:
`lib/data/lambing_repository.dart` → `lib/data/foster_repository.dart` →
`lib/data/restore_service.dart` → `lib/data/flock_repository.dart` → `lib/l10n/app_en.arb` →
`lib/routing/routes.dart` → `lib/features/flock/` → `test/`. **`lib/data/**` is never waved through,
however small.** Three of those four data files were merged in earlier epics and are re-opened here
(critique S9); `lambing_repository.dart` is the product's most-reviewed file, and a summary count it
writes wrong is wrong silently, on every card, forever, with no error and no test failure outside this
branch.

**4 — Open the PR and answer the five §12 questions** in `.github/pull_request_template.md`
**verbatim, in the PR body**. Four of the five land squarely here and must be answered with a file and
a test, not with a sentence:

- **§12.5 — timestamps carry provenance.** Every one of the seven timeline arms selects the quad;
  every rendered row prints `RecordedTime.provenanceLabel` in the same visual block as the time
  (05 §4.3), at the 18 px floor; an edited row prints what it was edited *from*. Name the test.
- **§12.1 — never default a withdrawal period.** Every withdrawal figure that reaches this card is
  labelled `Disclaimers.withdrawalProvenance` — *referenced*, never re-typed (decision #62). A
  treatment with no `treatment_withdrawals` row reads as **not recorded**, never as `0`.
- **§12.2 — never give veterinary advice.** The summary line states counts the shepherd's own records
  produced and never a judgement; `EweObservations` records what was **observed** and the app never
  infers one — 03 §5.7's doc comment is explicit that `poor_mothering` is never derived from a lamb
  death. `ContentPolicy`'s scan covers this screen's ARB messages, and 05 §7.3's legitimate-copy test
  already contains `'412 · 3 seasons · avg 2.0 · assisted twice'`.
- **§12.4 — never silently correct.** Nothing on this card rewrites a row. Struck records stay, ruled
  through. A corrected time keeps `original_effective`. The reused-tag disclosure exists precisely so
  the app does not silently merge two animals' histories. `lib/data/` still cannot import
  `lib/domain/validation/`.

§12.3 does not appear on this screen (07 §1.5's matrix) — say so, and say which epics carry it
(N21's export footer and N29's About screen).

**5 — Wait for the pipelines.** Three blocking jobs run for this epic and each proves a different
thing.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` | The rules this epic is most likely to break: `layer.features` (a feature folder reaching for `customSelect` — the first thing a seven-arm union wants to do), **`layer.sibling`** (`lib/features/flock/` importing `lib/features/lambing/`'s or `lib/features/pens/`'s controller to fire an action — the single most likely compile-time defect in T06), `a11y.header_bool` (`Semantics(header: true)` compiles, reviews clean and does nothing on 3.44), `a11y.sort_key`, `copy.disclaimer_retyped` (typing *"as entered by you"* instead of referencing it), `copy.vet_advice` over the new ARB messages, the gesture ban, and the token rules |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | A **negative**, and that is the point: N27 reads and writes frozen tables and must move no snapshot. A red `codegen` here means somebody added a column to `ewe_summaries` — which after N07-T08 is a migration on somebody else's phone, not an edit. The most likely offender is a `last_observation_kind` column, added to make the *"prolapsed 2025"* clause easy. See the risk table |
| `test` | `flutter test -P ci-fast` randomised · `TZ=Europe/London --tags uk-zone` (**unscoped** — the tag selects the files) · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · coverage artefact (reported, **never** gated) | The seven anchors, the summary-line assembly, the `ewe_summaries` transaction tests, and the 252-cell matrix with `ewe_card` as variant 2. The `uk-zone` leg is what proves the timeline's ordering and the season grouping were exercised in `Europe/London`; under the runner's UTC the ambiguous hour does not exist and the assertions pass for the wrong reason |

`android` also runs on every PR (13 §4.2) and must stay green; N27 changes no native file and no
permission, so it proves nothing this epic authored. **`goldens` does not run on this PR** — it is
`v*` or `workflow_dispatch` only, and 12 §8's note is explicit that `ewe_card_summary_line` is
**deliberately not a golden**: *"covered by the matrix plus the a11y gates."* Do not add a
`matchesGoldenFile` call here.

```bash
gh pr checks --watch
```

**6 — Merge, delete the branch, and only then cut N28.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git checkout main && git pull --ff-only
make check && make test                     # main green after the merge
git checkout -b epic/n28-season-summary
```

## Risks, and what is irreversible

**Irreversible in this epic — say it out loud in the PR body:**

- **T03 re-opens three already-merged files in `lib/data/`.** `lambing_repository.dart` (N14),
  `foster_repository.dart` (N18) and `restore_service.dart` (N23). The edits are additive and legal,
  and critique **S9** rules the placement stays — but a summary count written wrong inside a merged
  transaction is a **silent** defect on the one screen the product's second-year value rests on. Name
  all three files on the first line of the PR body so the reviewer reads them first.
- **Every widget key introduced here is a test contract** (R59), read by `ewe_card_test.dart`, the
  overflow matrix, the semantics gate and the tap-target gate: `ewe_card.summary`,
  `ewe_card.timeline`, `ewe_card.row.<kind>.<id>`, `ewe_card.earlier_animal`, `ewe_card.observe`,
  `ewe_card.record_lambing`, `ewe_card.treat`, `ewe_card.move_pen`, `ewe_card.add_note`,
  `ewe_card.status`, `ewe_card.barren`. Renaming one later breaks four test files together. Record
  them in `07-screens.md` §4 in the same commit that creates them.
- **`TimelineRow` and `TimelineKind` become a published shape** the moment T02 onward build on them —
  `CONVENTIONS §3.2` already names `TimelineRow` in a provider type, so the class is load-bearing from
  its first commit.
- **The ARB keys are frozen the moment they ship**, and the terminology placeholders inside them
  (`{singularTerm}` / `{pluralTerm}`, never `{singular}` / `{plural}` — 10 §8.5) are what keep a
  shepherd's *gimmer* from becoming *ewe* on the one screen they read most.
- **`ewe_card` joining `kPumpableVariants` raises the matrix's floor.** The self-check asserts
  `kPumpableVariants.length == 14` and that every `RouteNames` constant is present (R58); once this row
  lands, every later change to the card is pumped eighteen times.
- **Nothing else here is irreversible**, and that is worth stating plainly: no schema, no snapshot, no
  native file, no published artefact, no allowlist line, no golden baseline. If this branch touches
  `drift_schemas/`, `lib/core/db/`, `tool/policy_allowlist.txt`, `android/`, `ios/` or
  `test/features/goldens/`, the change is in the wrong epic.

**Risks specific to N27:**

| Risk | Why it bites here | What holds it |
|---|---|---|
| **Seven drift streams combined in Dart** | This is the screen where `combineLatest` looks unavoidable — seven tables, one list. 01 §4.4 and decision #12 make it a **build-breaking defect**, and drift#3338's maintainer calls the torn emission working as intended: a foster and its lambing would render a history that never existed | T01: one `customSelect`, `UNION ALL`, explicit `readsFrom:` over eight tables; the anchor asserts all seven kinds arrive in one ordered list, and a source-text case asserts `combineLatest` appears nowhere under `lib/` |
| **The summary string gets stored** | An `UPDATE ewe_summaries SET line = …` is one line of code and makes the header instant. It freezes the user's terminology, the locale, the units and the wording at write time, and it is wrong the moment a record is corrected | 03 §5.13 states the rule; T02 assembles in Dart from counts and its anchor is *"not read as a stored string"*. The `codegen` job fails on a new column |
| **The *"prolapsed 2025"* clause has no column behind it** | `ewe_summaries` stores `last_observation_season` — a **season**, not a kind. The obvious fix is a `last_observation_kind` column; the schema was frozen at N07-T08 and that is a migration on somebody else's phone | T02 §5.3: the kind comes from the newest `observed` row in the timeline the card is **already watching** — no second statement, no new column. The consequence is that the *Flock* row honestly renders three clauses (Indelible §7.4) and the *card* renders four (Indelible §8 screen 2), which is exactly what the two artefacts draw |
| **`ewe_summaries` is empty after a restore** | It is excluded from the backup by design (09 §6, §7.9) — exporting it would break the round trip because `rebuilt_at` moves. Nothing in N22 or N23 rebuilds it, and 04 §7's validation step list stops at the FTS rebuild | T03 ships `rebuildAllEweSummaries()` and calls it from `RestoreService` after the swap; the test tier includes a restore-then-open case that would otherwise render *"0 seasons"* on every card |
| **The counts are maintained by a sweep or on launch** | A nightly rebuild is easier to write than an in-transaction update, and it is wrong at 03:20 on the one night it matters | CONVENTIONS §2.13 assigns `ewe_summaries` to `LambingRepository`; T03 writes it **inside** the invalidating transaction and the anchor asserts the update and the lambing are atomic |
| **A struck record is filtered out of the history** | `WHERE struck = 0` reads like hygiene. Indelible §1.1 rule 1 is that erasure does not exist in this product, and §8 screen 2 says the struck entry staying *"is the whole point of year two"* | T01 projects P1's `struck` / `struck_at` on every arm and filters nothing; T04 renders Indelible §7.3's **Struck** state — line through, `--ink-low`, `STRUCK <time>` in the margin, and the row does not move |
| **A provenance stamp ships at 14 px** | Indelible sets `--t-stamp: 14px` and uses it 49 times. Build-manifest §4.4 defect 2 names **`AUTO-CAPTURED`** as one of exactly three stamps that lose the exemption, because it is the *sole* carrier of the §12.5 claim | T04 §5.3 states the corrected rule and the DoD asserts the floor. Every other stamp keeps the exemption |
| **The provenance label is dropped on the arms that "obviously" do not need one** | A pen occupancy or a note feels like metadata. 07 §1.5's matrix requires §12.5 on **every** timeline row, and R37 added the quad to those four tables specifically so this screen could be honest | T04's anchor iterates all seven kinds and fails if any row renders a time without a label |
| **A withdrawal figure appears without *as entered by you*, or with it re-typed** | The string is one `const` in `lib/domain/policy/disclaimers.dart`, and `test/policy/disclaimer_is_defined_once_test.dart` (N06-T09) asserts it is a literal in exactly one file. Typing it here turns a green suite red — or worse, a *paraphrase* passes | T04: reference `Disclaimers.withdrawalProvenance`; the gate row `copy.disclaimer_retyped` and N06-T09's test both run |
| **The reused-tag disclosure invents a "culled on" date** | 07 §4.2's copy reads *"An earlier 412 was culled on 12 Aug 2025."* — and **R41 rules there is no status-history table**, so no column stores when the status changed. `ewes.updated_at` is a row-lifecycle fact that any later edit moves; rendering it as a status-change date is exactly the provenance laundering §12.5 exists to prevent | T05 §5.3: the disclosure names the earlier animal and the date of her **last recorded event** — a real event time, with its own provenance — and links to her card. 07 §4.2's copy is amended in the same commit, per the amendment rule, and R41's escalation is named in the PR body rather than answered here |
| **The card's actions import a sibling feature** | *"Record a lambing"* wants `lambingWriteControllerProvider`; *"Pen her"* wants `penWriteControllerProvider`. Both live under `lib/features/lambing/` and `lib/features/pens/`, and **layer rule 6 forbids it** — the gate fails, and it should. N14-T03 hit the identical wall and its resolution is the precedent | T06 §5.3: the card's writes go through **`flockWriteControllerProvider`** — the flock feature's one write controller (CONVENTIONS §4.4 rule 2), same folder, already created in N26-T04 — reaching repositories through `lib/data/`, which layer rule 5 permits. Navigation goes through `lib/routing/routes.dart` |
| **`beginLambing` is called outside `guard()`** | It returns an id and **throws** (R32); `guard()` takes a `Future<WriteOutcome> Function()`. The two signatures do not compose and the obvious fix — a bare `try`/`catch` — deletes the double-tap defence. 07 §6.1 printed the unguarded snippet until N14-T03 amended it | T06 §5.3 reuses N14-T03's adaptation verbatim: inside `guard()`, wrap the id as `WriteCommitted(insertedId: id.value)` — R33's single permitted call site |
| **Barren is written as an observation** | The `ewe_observation` vocabulary has six keys and none is barren; the obvious place to put *"Record her as barren"* is a seventh | **R42**: barren is a season participation outcome, `ewe_seasons.status = 'barren'`, owned by `SeasonRepository`. T06 writes it there, and the DoD greps for a barren key in the observation vocabulary |
| **The observation vocabulary is hard-coded** | Six keys is a tempting `enum`. 03 convention 6: a user-editable vocabulary is an FK to `vocab_terms(key)`, and `test/data/vocab_list_scope_test.dart` asserts per column that every stored key belongs to that column's list | T06 reads `SELECT key FROM vocab_terms WHERE list = 'ewe_observation' AND hidden_at IS NULL` once, when the sheet opens — not as a second stream on the card |
| **Two documents disagree about the timeline's headings** | 10 §3.4 says the card has *"one flat timeline… so there are no further stops to invent"*; Indelible §8 screen 2 draws **per-season sub-heads**. The tell is in the query: 07 §4.1 projects `season` on all seven arms, and a flat timeline makes that seventh column dead weight | T07 §5.3: build it as Indelible draws it (`CLAUDE.md`'s authority order puts `indelible.md` above the engineering documents on what a screen looks like), **amend 10 §3.4's heading table in the same commit** — N33's semantics gate reads that table — and name the conflict in the PR body |
| **The season group is computed from the year of the instant** | Grouping by `year(at)` looks equivalent and is not: a lambing on 31 Dec 2025 inside the *2026 lambing* season groups under 2026, because the season is a **stored FK** on the row, not a derivation | T07 §5.3 groups on the projected `season` column. A `uk-zone` case seeds a lambing either side of a season boundary |
| **`notes.season` is nullable and the note gets attached to the nearest season** | Every other arm's `season` is `NOT NULL`; `notes` is not (03 §5.12). Silently folding an unseasoned note into the adjacent group is §12.4 | T07 §5.3: its own honest group, labelled, never merged |
| **`Clock.fixed` freezes the card and the test measures nothing** | The obvious way to write a *"the timeline reads 03:20"* widget test wraps it in `atFixed`, and every elapsed value then stays at its initial value forever while the test passes (decision #113, 12 §2.2) | 12 §2.2's rule: pin `now` **or** measure elapsed time, never both. This card has no elapsed value of its own, so `atFixed` is correct here — but T04's DST cases offset the **seed data**, not the clock |
| **The family provider leaks one instance per card opened** | `eweTimelineProvider` is `.autoDispose.family` (CONVENTIONS §3.2) and `eweCardControllerProvider` is `.autoDispose.family` (§3.4). keepAlive here holds a stream per ewe for the life of the process — 400 of them by the end of a night | T01 and T07: `.autoDispose` on both, and a test that pops the card and asserts no listener remains. `EweId` is an extension type with real `==` (R33), so the family key does not mint a new provider per rebuild |
| **`ewe_touches` never moves for a card opened from anywhere but the Flock list** | 07 §3.3 puts the touch on the **Flock row's tap**; 03 §5.13's doc comment says *"'Touched' includes **looking at a ewe card** without writing anything"*. If the write sits on the Flock tap, opening 412 from the pen board or a treatment row never touches her and the recents strip goes stale | T06 §5.3 names the discrepancy and puts the touch on **card entry**; the write is an upsert on the primary key `ewe`, so a Flock tap that also touches is harmless. Route the wording fix to 07 §3.3 |
| **P9 fires on the ruled rows** | 06 §6.1 asks for `gapMin` 16 between any two targets; Indelible stacks 64 px ruled rows separated by a 2 px rule and nothing else. That is open conflict **P9**, and it is not this epic's to settle | T04 and T07: build the rows as Indelible draws them, name P9 in the PR body, route the ruling to the owner rather than inventing a gap |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] the diff contains no file under `drift_schemas/`, `lib/core/db/`, `android/`, `ios/`, `tool/policy_allowlist.txt` or `test/features/goldens/`
- [ ] the three re-opened `lib/data/` files are named on the first line of the PR body (critique S9)
- [ ] `grep -rn "combineLatest" lib/` returns nothing; the timeline is one `customSelect` with an explicit `readsFrom:` over eight tables
- [ ] `grep -rn "as entered by you" lib/ --include=*.dart --include=*.arb` returns only `lib/domain/policy/disclaimers.dart`
- [ ] `grep -rn "header:" lib/features/flock/` returns nothing; every heading is a `headingLevel:`
- [ ] `grep -rn "package:drift" lib/features/flock/` returns nothing (layer rule 5); `grep -rn "features/lambing\|features/pens\|features/treatments" lib/features/flock/` returns nothing (layer rule 6)
- [ ] no column was added to `ewe_summaries`, and no formatted string is written to it
- [ ] every new widget key and every new ARB message is recorded in `07-screens.md` §4 in the commit that creates it
- [ ] 10 §3.4's heading table and 07 §4.2's reused-tag copy are amended in the commits that change them, per the amendment rule, each struck with its reason
- [ ] the card has been read once by hand with VoiceOver or TalkBack, rotor set to Headings, and the summary line is the first stop — stated in the PR body

## Demoable on merge

*"3 seasons · avg 2.0 · assisted twice · prolapsed 2025"* — assembled in Dart from counts, never read
as a string frozen in the database, printed first on the card, and reachable in one flick with the
rotor set to Headings.

## Notes

**What this epic deliberately does not build.** The Season Summary's statistics and the spread chart
are N28's; renaming *ewe* to *gimmer* is N29's; the `ewe_observations` arm of the CSV and the JSON
backup is N21's and N22's; the semantics, tap-target, contrast and reduce-motion sweeps over
`kPumpableVariants` are N33's; the four integration journeys are N33's; `ewe_card_summary_line` is
**not** a golden and never becomes one (12 §8's note). This epic ends at roughly six files under
`lib/` and three under `test/`.

**There is no edit verb for a timeline row's event time in v1, and the card is where one will be asked
for.** R37 put the quad on all seven tables precisely so one *could* exist, and 07 §4.3 already lists
*"Edit a timestamp — 2 + picker"* as an action of this screen. What T04 ships is the **render**: a row
whose `time_source` is `'edited'` prints both times and can never be laundered as auto-captured.
Adding `correctOccurredAt` for the other six tables is a repository verb plus a sheet row, and each one
must write `original_effective` and flip `time_source` in the same transaction or not at all. The
corollary that forbids the reverse still stands: **a table without the quad has no edit verb.**

**R41's escalation is live on this screen and is not answered here.** `CONVENTIONS` §7 item 1 asks
whether the retention story needs a ewe status-history table — *"she was culled in March 2025 and
un-culled in April"*. T05 is the task that discovers the answer is probably yes, and the schema is
frozen. Record the finding in the PR body and route it to the owner; do not add a table.

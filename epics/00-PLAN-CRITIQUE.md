# Shed Book — critique of the delivery backlog, and the corrected plan

**Verdict: the plan is sound in its ordering thesis and unbuildable as written.**

`00-PLAN.md`'s central argument — front-load the irreversible, reach pixels late, Quick Entry is the
product — is correct and is `00-README` §9's, faithfully. Its epic *boundaries* are mostly right. Its
arithmetic is honest (31 epics, 227 tasks, counted and confirmed). What is wrong is everything that
makes a backlog *startable*: **no task names a test, no task names a skill, eleven tasks depend on code
a later epic builds, the component library that twelve screens import is not in any epic, the `test` CI
job is never created, no task creates `android/` or `ios/` at all, and G0 — a five-line shell procedure
that gates the project's central claim — is scheduled 29 epics after it could have been run.**

The plan also states three rules in its §1 that its own §3 breaks on every line:

| §1 claims | §3 does |
|---|---|
| "Every task below names the specific first failing test it starts from" | Four of 227 tasks name a test. The other 223 name none |
| "Every task names its skills. Only the twenty-four skills that exist" | Zero tasks name a skill |
| "Every task ends with `/simplify`, then `/code-review`" | `/code-review` is Claude Code's bundled reviewer. `CLAUDE.md` mandates `/shed-code-review`, and `02-build-manifest.md` §2 change 6 made `shed-code-review` manual-only *specifically because it loses the name-space contest to the bundled one*. Instructing `/code-review` per task instructs the wrong reviewer |

A backlog whose stated rules are not met by its own rows will not be met by the person following it.
§11 below is the corrected version to build from.

---

## 1. Sequencing defects

Eleven. Each names the forward reference and the fix. **S1, S2, S4, S7 and S11 are red-main defects** —
the epic cannot compile or the test cannot be written.

### S1 · `test/support/harness.dart` is built in E09 against seven gateways and thirteen screens that do not exist

E09-T11 reads *"`test/support/` — `pumpApp`, the seven hand-written fakes, `kPumpableVariants` and the
`Device` table."* At the end of E09:

- **The seven fakes** (`12-testing.md` §4.2) wrap `NotificationScheduler` (E20), `ShareService` (E18),
  `MediaStore` / `CameraService` / `VoiceRecorder` (E12), `WakelockController` (E26 — and never given a
  task at all), `PurchaseService` (E27). **Zero of the seven seams exist in E09.**
- **`kPumpableVariants`** maps thirteen `RouteNames` to thirteen screen constructors (`12` §6.2). At E09
  there are no screens. The map cannot be typed, let alone compiled.

**Fix.** E09's harness task builds `pumpApp`, the `Device` table and `test/support/seeds.dart`
(`seedEwe` / `seedLambing` / `seedTreatment`, which `12 §10.1` already uses) — nothing else. Each fake
lands in the epic that introduces its gateway and extends `pumpApp`'s override list in the same commit.
`kPumpableVariants` is created in the Quick Entry epic with **one** entry and grows one row per screen
epic. See N12-T05, N33-T01.

### S2 · `routes.dart` declares twelve push helpers in E10 for eleven screens that do not exist

E10-T01: *"`routes.dart` — thirteen `RouteNames`, twelve typed push helpers."* `Routes.eweCard(context,
id)` must name `EweCardScreen`. It does not exist until E23.

**Fix.** E10-T01 lands `RouteNames` (thirteen `const String`s — free, no compile edge),
`Routes.navigatorKey`, the `onGenerateRoute` switch and **only the Quick Entry helper**. Every screen
epic adds its own `RouteNames` case and its own push helper. The "13 names, 12 helpers" assertion is a
`test/policy/` row in the final gate epic.

### S3 · The overflow matrix is created in E10 but its fixture arrives in E19

E10-T07 seeds the matrix. Every cell in `12 §6.2` calls `restoreFixture(db,
'flock_400_3seasons.json')`. That fixture is written by `tool/seed.dart` **through the restore path** in
E19-T09. The plan's own §5 says so — *"E19 before E28 | the seed and its two fixtures are the
precondition for the matrix"* — and then builds the matrix nine epics earlier.

**Fix.** Matrix cells use `test/support/seeds.dart` helpers until the fixtures exist; the switch to
`restoreFixture` is one task in the restore epic (N23-T06), and it is the task that proves the fixture
is loadable. State this once, in the harness file, or it will be rediscovered per screen.

### S4 · `tap_budget_test.dart` in E11 taps a Lambing Entry key, and that key is one P8 abolished

E11-T06: *"six taps from unlock to a committed lambing, on keyed finders."* `12 §10.1`'s published test
spends its sixth tap on `find.byKey(const Key('lambing_entry.birth_type.twin'))`. Two independent
failures:

1. **`LambingEntryScreen` is E13.** The test cannot be written in E11.
2. **There is no birth-type key.** P8 is a ruled owner decision carried in `CLAUDE.md` and
   `02-build-manifest.md` §4.2: *"birth type is derived from the tally strokes and labelled
   `(COUNTED)`… any skill implying a birth-type selector is wrong."* `07-screens.md` §6.4's "Declare
   birth type — 1 tap, five big buttons" and `12 §10.1`'s sixth tap are both **superseded artefacts the
   plan never reconciles**, and E13-T02 quietly assumes the new world while E11-T06 quietly assumes the
   old one.

**Fix.** Split the budget and rule the conflict in writing:

- **N14-T06** — `test/features/tap_budget_test.dart` · `'unlock to a committed beginLambing row costs 5
  taps and no typing'`. Three digits, confirm, "Lambing". The row is committed on screen entry
  (`00-README` §2.4), so five taps genuinely produce a committed lambing; that is the claim E11 can
  honestly hold.
- **N16-T02a** — rule P8's consequence for the 6-tap budget, amend `07 §5.4` and `12 §10.1` in the same
  commit per the amendment rule, and land the sixth tap as the **first tally stroke**
  (`lambing_entry.tally.stroke`). `test/features/lambing_entry_test.dart` ·
  `'no widget with a birth_type key exists anywhere in the tree'` is the canary that keeps the chooser
  dead.

This is the single most important correction in this document. As written, E11 cannot go green and
`declared_birth_type` (E06-T04) has **no writer anywhere in the plan** — a nullable column, a warning
(`birthTypeLambCountMismatch`, E13-T06) and an export column that nothing can ever populate.

### S5 · `FreeTierPolicy` is wired in E27, sixteen epics after the verb it gates

E27-T04: *"`FreeTierPolicy` wired into the only two gated verbs, `createEwe` and `startSeason`."* But
`createEwe` is built in E11-T01 and E22-T04 already describes it as *"the same gated `createEwe`
verb."* `CONVENTIONS §2.13` fixes the signature as
`createEwe({required String tag, required EntryContext context})` — the `EntryContext` parameter is
**structural** (decision #91: `EntryContext.liveEntry` is incapable of returning `BlockedByCap`), not a
later addition.

**Fix.** `createEwe` takes `EntryContext` and calls `FreeTierPolicy.decide` from its first commit
(N14-T01). `FreeTierPolicy` already exists — it is E05-T10, eleven epics earlier. E27 then only supplies
the *entitlement source*, which is the part that genuinely needs the store seam.

### S6 · The export banner writes `app_settings` in E18, but `SettingsRepository` is E26

E18-T08's once-a-day banner needs four `app_settings` columns — `last_exported_at`,
`last_export_prompted_at`, `export_prompt_dismissed_for_season` and `current_season` — **all four of
which already exist in `03` §5.13** (decision #72; `07 §16` names them and says so). **`[audit]` The
earlier citation of R40 here was wrong**: R40 adds `last_reconcile_scheduled` and `left_handed`, which
are the reminders and left-handed rows, not the banner's. The sequencing defect is unaffected —
`CONVENTIONS §2.13` gives `app_settings` writes to `SettingsRepository` and gives `ExportRepository`
*"nothing — read + artifact assembly only."* Note the write rule that comes with them: `08 §11` and
`09 §8.3` stamp `last_exported_at` on `ShareOutcome.completed` **and** `unknown`, never on `dismissed`
and never before the sheet opens.

**Fix.** Pull `SettingsRepository` forward to the DI epic (N12-T02): the repository and its
parameterised persist/re-read test, no screen. The Settings **screen** stays where it is.

### S7 · `tap_target_test` and `semantics_gate_test` are written in E08 and iterate a variant table from E10

E08-T08 lands *"`wcag.dart`, `contrast_test`, `tap_target_test`, `semantics_gate_test`,
`reduce_motion_test`."* Per `12 §6.2` the last two are **sweeps over `kPumpableVariants`** — they are
three of the four files that iterate it. Nothing to iterate exists in E08.

**Fix.** E08 lands `wcag.dart`, `contrast_test.dart` (pure, over the palettes — the honest E08 demo)
and a **single-widget** `tap_target_test` over `ShedTapTarget` plus `reduce_motion_test`. The sweeps are
the gate epic, N33-T02/T03.

### S8 · The `copy.*` gate rules are written in E02 but their source of truth is E05

E02-T06 lands *"the `time`, `db`, `rp3` and `copy` rules."* `12 §10` fixes the mechanism:
`ContentPolicy.bannedInUserFacingText` with an allowlist *"keyed by `Disclaimers.*` rather than by a
literal"*, and `copy.disclaimer_retyped` proving `Disclaimers.exportFooter` is referenced and never
re-typed. Both types are E05-T09.

**Fix.** E02-T06 lands the vocabulary and banned-word rules only — those come from `CLAUDE.md` /
`CONVENTIONS §5.3` and are available on day one. `copy.vet_advice` and `copy.disclaimer_retyped` land
**in E05-T09's commit**, which adds their rows to the gate's table. Say out loud in E02's goal that the
rule table is not closed at E02.

### S9 · `ewe_summaries` is written in E23 into a repository merged in E11

E23-T03: *"`ewe_summaries` rebuilt inside the writes that invalidate it."* Per `CONVENTIONS §2.13` those
writes are `LambingRepository`'s (E11) and `FosterRepository`'s (E15). This is legal — it is additive
— but it is a cross-epic edit to the product's most-reviewed repository and the plan does not say so.
Keep the placement; **name the files it re-opens** so the reviewer reads them in irreversibility order.

### S10 · Reminders write inside the lambing and treatment transactions, and the fixtures predate them

E20-T04 puts reminder rows *inside* E11's and E17's transactions — correct per decision #63. But
`flock_400_3seasons.json` is generated in E19-T09, one epic earlier, so **it contains no reminder rows**.
The Reminders matrix variant (E21-T06) and every later sweep therefore pump the *empty* state of a
populated screen.

**Fix.** N24 ends with a task that regenerates and re-commits both fixtures. This is the only place the
plan needs a "regenerate the fixture" task and it is currently missing.

### S11 · No task creates `android/` or `ios/`

E09's scope line says *"~20 files incl. Android and iOS"* and E09-T06 configures *"the four layers on
Android and iOS."* E29-T04/T05 configure them further. **No task ever runs `flutter create` or
otherwise brings the platform folders into existence**, and E01-T01 is a bare `mkdir` of the
`CONVENTIONS §1` tree plus `.gitignore`. Downstream, this is also what makes G0 impossible before E29:
`flutter build appbundle --release` has nothing to build.

**Fix.** N01-T01 creates the Flutter project properly (`flutter create` with the application id, then
prune to the `CONVENTIONS §1` tree). This unblocks S12.

---

## 2. The calendar-blocking items — the plan gets one right and two wrong

| Item | Source | Plan | Verdict |
|---|---|---|---|
| Field night | §7.1 item 1 · §9 step 0 | E00-T05, must land before E10 | **Correct placement, no teeth.** No task consumes its output and no gate fails while it is unbooked. "Record both where a test can see them" names no test |
| Twelve testers / 14-day closed test | §7.1 item 14 · `13 §10.2` | E00-T05 recruit, E30-T07 open the track | **Recruitment early, clock late.** The 14-day clock starts when a build reaches a track, and the track is the last task of the last epic. Two weeks of dead calendar sits at the end of the project by construction |
| **G0 — manifest merger against a real release AAB** | §1 item **5** · `13 §2.2` | **E29-T01 — epic 29 of 31** | **Wrong, and it is the worst defect in the plan.** It is one of the *five decisions that must be taken before commit #1*. `13 §2.2` calls it *"a one-afternoon empirical procedure"*. It needs exactly two things: `in_app_purchase` in `pubspec.yaml` (E00-T02) and an `android/` folder (S11). Both exist by the end of the second epic |
| Ziplock-bag capacitance | §7.1 item 2 | Prose in §5 only | **No task at all.** The plan says it *"invalidates E10 onward"* if it fails, and then gives it no owner, no epic and no date |
| Store accounts, Apple Small Business Program | §7.1 items 4 and 14 | Nowhere | **No task.** Enrolment has approval lead time, must happen *before the first sale*, and Play's closed test cannot start without a developer account and an app record |
| Lambing ease 5 vs 6 | §7.1 item 15 — *"decide before any data exists"* | Nowhere | **No task.** `LambingEase` is E05-T01 and `R44` freezes it as an ordinal. After E06 it is a migration |
| PDF printing from inside the app | §7.1 item 16 | Nowhere | **No task**, and it is a `pubspec.yaml` question (`printing` → `http`) that expires at E00-T02, not at E18 |

**What G0 costs when it is late.** If Play Billing 8.0.0 contributes `ACCESS_NETWORK_STATE`, `13 §2.2`'s
second permitted outcome applies: the permission stays, `expected_permissions.txt` gains a line, **and
the Play listing will show "view network connections"** — which changes the store-listing honesty
paragraph, the About screen (E26-T07) and the Export screen wording (E18-T07). Discovering that at E29
means re-opening copy in three epics that have already merged. Running it at N02 costs an afternoon.

**Fix — the calendar ledger, made blocking.** N00 adds `docs/calendar.md` with one row per commitment
(field night, twelve testers, ziplock, developer-account answer, Apple SBP enrolment, price and
territories) and `test/policy/calendar_commitments_test.dart` ·
`'every calendar commitment has a date and an outcome'`, which is **red from N00 until each is
recorded**. That is what "record both where a test can see them" has to mean to be worth writing. G0
gets its own epic at N02 with its own anchor: `test/policy/g0_recorded_test.dart` ·
`'no tools:node="remove" line exists while 13 §2.2's table still reads UNVERIFIED'`.

---

## 3. PR sizing

`00-PLAN` sizes by file count. The right unit is *what a reviewer can hold in one sitting in
irreversibility order* (`CODE-REVIEW-CHECKLIST` §3.1).

### Too large

| Epic | Why | Re-cut |
|---|---|---|
| **E06** — schema, 14 tasks, XL | Correctly **one PR** (a second snapshot is unrecoverable) and wrongly **fourteen commits**. Tasks T01–T13 define tables without running `make gen`, so `database.g.dart` does not exist and **the tree does not compile from T01 to T13** | Keep one PR. Re-cut to **8 tasks**, each a table cluster ending in `dart run build_runner build` **only**. `make gen` — i.e. `build_runner` **plus** `drift_dev make-migrations`, which is what writes the snapshot — runs **exactly once**, alone, in the final task. That task contains `kSchemaVersion`, `drift_schema_v1.json`, `schema_versions.dart` and `test/drift/generated/**` and nothing else, per `00-README` §7.4 |
| **E19** — backup + restore + seed, 10 tasks, XL | Two different risk profiles in one PR: a format (reviewable) and the app's most destructive code path (not) | Split. **N22 — the JSON backup**: format, `writeBackup`, forward compatibility, checksum, file import. **N23 — restore and the seed**: `RestoreService`, the two-step confirmation, `MediaSweeper`, `tool/seed.dart`, the round-trip property |
| **E09** — 11 tasks | Bundles the first frame (touches native files, needs a device) with the DI graph (pure Dart wiring) | Split. **N11** failures + `main.dart` + `NightErrorPanel` + `app.dart` + no-white-flash + `LocalLog`. **N12** `providers.dart` + `SettingsRepository` + ticker + `WriteController` + `test/support/` |
| **E28** — 8 tasks, ~900 lines of test + 8 PNGs | The goldens are a separate reviewing act — `00-README` §7.4 makes a re-baseline its own commit and `12 §8.5` makes it a deliberate ritual | Split into sweeps (N33) and keep the PNGs as their own commit inside it; move `goldens.yml` here so the images are verified by CI in the epic that creates them, not two epics later |
| **E30** — 8 tasks | Bundles signing (which unblocks the 14-day calendar clock) with budgets and the freeze (which do not) | Split. **N32** signing + Play App Signing + app record + first closed-track upload + TestFlight, **moved before the sweeps**. **N34** `release.yml`, budgets, symbols archive, perf, freeze, checklist |
| **E02** — 700 lines, T07 is "plant, watch, delete" for ~30 rules | T07 is thirty commits pretending to be one | Prove each rule as part of the task that adds it; T07 becomes "wire the gate into the `gate` job and assert the rule-id inventory is complete" |
| E13 (9), E18 (8), E26 (8), E27 (8) | Large but coherent | Keep, after the closer-task fix in §4 |

### Too small to be worth a PR and a pipeline wait

| Epic | Verdict |
|---|---|
| **E25 — Note search** (S, 4 tasks, one debounced route) | **Merge into E22 (Flock).** `CONVENTIONS §3.2` puts `noteSearchProvider` in `lib/features/flock/note_search_controller.dart` — the *same feature folder*. Both reuse the flock's queries; a separate PR buys nothing and costs a full pipeline. Becomes N26 |
| E00 (6 tasks, no `lib/`) | Keep. It is the calendar epic, and its value is that it exists at all |
| E21 (one screen, 6 tasks) | Keep. It has its own honest-line assertion |

### Net

31 epics → **35**, with two moved forward (G0, signing) and one absorbed (note search). Every epic
below fits one reviewing sitting.

---

## 4. Task granularity

### Five commits pretending to be one — the "closer task" pattern

Seven epics end with a task shaped *"Screen composition, ARB, semantics, the matrix variant and the tap
costs"* (E13-T09, E14-T05, E15-T05, E16-T07, E22-T05, E24-T06, E26-T08). Each bundles four to five
independent commits — **and it is exactly where the accessibility/ARB "parallel track" quietly becomes a
batch.** The plan's §1 says a11y and the ARB are *"authoring rules inside every UI task."* Its §3 then
gives them their own trailing task on seven screens. Both cannot be true.

**Fix.** Delete the closer task. Semantic labels, heading levels, widget keys and ARB entries land
**inside** the task that adds the widget, which is what the plan already claims. What survives as its
own one-line task per screen: **"add the matrix variant and the empty-state row"** — two files, one
commit, and it is the row that keeps `kPumpableVariants` honest.

### Other over-large tasks

| Task | Why |
|---|---|
| E02-T07 | ~30 plant/watch/delete cycles |
| E06-T14 | `seedFirstRun` (code) + `make gen` + the first snapshot (irreversible). Split: seed in T07, the freeze alone in T08 |
| E09-T06 | Four native layers × two platforms + a parity gate. Three commits |
| E19-T09 | The seed script + two fixtures. The fixtures are generated artefacts and belong in their own commit, like goldens |

### Too small to be a task

`E01-T01` (`mkdir` + `.gitignore`), `E25-T02` (three empty strings — a sub-commit of the screen),
`E29-T06` (two identifier strings), `E30-T01` (a version-numbering convention). Fold each into its
neighbour. None of these is worth a `/simplify` + review cycle on its own.

---

## 5. Skill names

**No invented skill names — because no task names a skill.** The 24 authored skills under
`.claude/skills/` were checked against `02-build-manifest.md` §3 and match exactly (19 engineering +
5 design). The three skill names that appear in `00-PLAN`'s *prose* — `shed-drift-schema`,
`shed-export-and-restore`, `shed-testing` — are all real, as are `/shed-migrations`, `/shed-release`,
`/shed-goldens-rebaseline` and `/shed-code-review`.

Two defects remain in this area:

1. **The §1 rule "every task names its skills" is unmet on all 227 rows.** With at most two auto-firing
   skills per intent (`CLAUDE.md`) and 24 to choose from, naming them is the plan's job, not the
   builder's. §11.4 supplies the mapping.

   **`[audit]` Re-verified against the filesystem, not against a list.** `.claude/skills/` holds
   exactly 24 directories; their names match the 24 authorised names one-for-one; and exactly four —
   `shed-migrations`, `shed-release`, `shed-goldens-rebaseline`, `shed-code-review` — carry
   `disable-model-invocation: true` in their `SKILL.md` frontmatter. **Every one of §11.4's four
   runbook references already says "by name" or "invoked by name", which is the only correct usage:
   a task that expects one of the four to auto-fire gets nothing.** No invented skill name exists
   anywhere in either file.
2. **`/code-review` is the wrong reviewer.** Replace with `/shed-code-review` everywhere. The bundled
   reviewer does not know the read-by-irreversibility order, the never-waved-through list, or the one
   Quick Entry question.

---

## 6. Missing test-first anchors

**223 of 227 tasks name no test.** Under the plan's own TDD rule, none of them can be started. The four
that do — E04-T04 (`withdrawal_has_no_default_test.dart`), E08-T08, E11-T06 (which is wrong, see S4)
and E19-T10 — prove the format works; it simply was not applied.

An anchor is not "write tests for X". It is a **file, a test name, and the reason it fails today**.
§11.3 supplies them for every load-bearing task.

---

## 7. Epics that leave `main` red or cannot be demonstrated

| Epic | Problem |
|---|---|
| **E06** | Does not compile between T01 and T13 (no generated code). Fixed by the `build_runner`-per-cluster / `make-migrations`-once re-cut |
| **E08** | Two of its five gate files iterate a table that does not exist (S7) |
| **E09** | The harness does not compile (S1) |
| **E10** | `routes.dart` does not compile (S2); the matrix has no fixture (S3) |
| **E11** | `tap_budget_test.dart` cannot be written (S4) |
| **E20** | Demo claim — *"project exactly the soonest 56 onto an iOS lock screen"* — is not demonstrable in an epic whose only consumer is a hand-written fake. Restate as *"a 312-reminder flock projects exactly 56 and drops none of the rest, asserted against `FakeNotificationScheduler`'s recorded calls"* |
| **E28** | Generates eight PNGs that nothing in CI verifies until E30-T06 adds `goldens.yml`. Move the workflow into this epic |

---

## 8. Coverage gaps

Walked against the 12 spec §9 screens + Note Search, every §7 feature, every §10 entity, the five §12
rules, the offline gates and the a11y/ARB track. **The screens, the entities, the safety rules and the
gates are covered.** These are not.

### G1 — `lib/core/ui/components/` has no epic

`06-design-system.md` §12 is a 21-component inventory, every one of them in `lib/core/ui/components/`,
and a sibling-feature import is a layer violation — so no screen may invent one. E08 builds tokens,
palettes, theme, type, `ShedTapTarget`, `formatters` and the gates. **Fifteen of the twenty-one
components have no task in any epic:** `ShedPrimaryButton` (the corner slab), `ShedSecondaryButton`,
`ShedDestructiveButton` (the word button's destructive form), `ShedConfirmBar`, `ShedRecentsStrip`,
`ShedAnimalRow`, `ShedStatusBadge`, `ShedCountdown`, `ShedChoiceRow`, `ShedFieldRow`,
`ShedSectionHeading`, `ShedBottomSheet` (**the only overlay in the app**), `ShedReceiptBar`,
`ShedBanner`, `ShedEmptyState`. Six are placed (`ShedTapTarget` E08, `ShedKeypad` E10, `ShedPhoto` E12,
`ShedPenTile` E16, `ShedSpreadChart` E24, `NightErrorPanel` E09).

This is the largest hole in the plan. Twelve screen epics would each build their own, and the layer
rule forbids sharing them afterwards. **New epic N10.**

### G2 — the `test` CI job is never created

`13 §4.2` requires four blocking jobs. E01-T06 creates `gate`; E07-T06 creates `codegen`; E29-T03
creates `android`. **`test` is created by nobody.** §6's coverage audit maps it to "E01-T04", which is
`dart_test.yaml` — a config file, not a job. Also unmentioned: the job needs **`libsqlite3-dev`** on the
runner (`12 §3.2`), and it runs `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` as a third
command.

### G3 — the ARB is never bootstrapped

`l10n.yaml` is E01-T03. **`lib/l10n/app_en.arb` is created by no task**, and no task wires
`localizationsDelegates` / `supportedLocales` into `app.dart` (E09-T05) or commits the generated
`app_localizations*.dart` (`00-README` §7.1 requires it committed). The first ARB string appears in
E10-T06 with nothing to put it in.

### G4 — remaining unowned items

| Missing | Source |
|---|---|
| `WakelockController` gateway + its fake | The seventh of `12 §4.2`'s seven fakes. E26-T04 describes the *setting*, never the seam |
| `.github/pull_request_template.md` with the five §12 questions verbatim | `00-README` §7.4 — it is *where* the safety review happens |
| `ios/*.storekit` | `00-README` §7.1 lists it as committed. E27-T07 covers privacy artefacts only |
| `README.md` recording which target trips the `sqlite3` build-hook fetch | Decision-record §3.4 #3 and `13 §1.3` both require it *by name*, and both call the omission a wasted evening |
| `accessibility_tools` 2.8.0 wiring | Decision #100. A declared dev dependency nothing installs |
| **The ~40 vocabulary ARB labels and the test that pairs them with the seeded keys** | **`[audit]` — the earlier row here had R66 backwards.** R66 gives the ~40 husbandry terms **three** homes: **keys** → `lib/core/db/seed/first_run.dart` (`vocab_terms`, `origin='seeded'`, `label=NULL`), **labels** → `lib/l10n/app_en.arb`, one message per key, and `assets/content/` → **only** authored prose too long to be a UI string plus one provenance line per list. So E06-T11's key source *is* created (it is `seedFirstRun`, N07-T07). What no task creates is the **ARB half** and `test/policy/vocab_labels_are_complete_test.dart`, which asserts the two sets are equal. Land both in N07-T07's commit |
| `tool/validate_skills.py` in `make check` / the `gate` job | `CLAUDE.md` lists it as one of five project commands; nothing runs it |
| **`[audit]` The two known Indelible artefact defects** | `02-build-manifest.md` §4.4 records both, says *"skills encode the corrected rule and name the artefact as wrong"*, and no task in either plan owns either. **Defect 1** — `indelible.html:1138` puts the live row inside the scrolling `.stream`, so the open row scrolls away; the corrected rule is *the live row is a fixed layer above the bottom band*. Owner: the Quick Entry shell task (E10-T05 / N13-T05). **Defect 2** — `--t-stamp` 14 px and `--t-head` 16 px are under the 18 px floor, and the §3.4 exemption test fails on the three stamps that are the sole carrier of their meaning: `DEAD`, `AUTO-CAPTURED` and `DERIVED FROM N STROKES`. Owner: the typography task (E08-T05 / N09-T05) for the corrected exemption test, and N16-T02/T07 for the two labels |
| **`[audit]` P14 is ruled in one place and applied in three** | `NightErrorPanel`'s `#0B0D0E` is also `CONVENTIONS §2.11`'s stated hex **and** `13` §5.4's dark-launch check (*"the iOS `LaunchScreen` background and the Android `windowBackground` are `#0B0D0E`"*), while Indelible's `--page` is `#0A0A0B`. N11-T04 rules P14 but N11-T06's anchor — *"the Android and iOS launch colours equal the page token"* — already assumes the page token won. Make N11-T04 the commit that rules it **and** amends `CONVENTIONS §2.11` and `13` §5.4 together, per the amendment rule; otherwise the first painted frame and the error panel can drift one hex apart and no test catches it |
| Fixture regeneration after reminders and entitlements exist | S10 |
| §12.1's schema half | §6 maps it to "E07-T02" (the migration matrix). Decision #52 puts it on `drift_schemas/drift_schema_v1.json` — it belongs in the freeze epic, as `test/policy/withdrawal_has_no_default_test.dart`'s second half |

### What is genuinely covered — do not re-cut

All twelve screens; note search; §7.1–§7.10; all 23 tables; the provenance quad; G0–G5; the five safety
rules' primary mechanisms; undo-per-verb; the export banner; the free-tier hours rule; the six
open-conflict rulings (P1, P3, P7, P9, P10, P14) with the right owners. §2's epic table is a good
document. (One nit: §1's prose says *"five … are decided inside a task; the sixth is calendar-blocking."*
All six have tasks and none is calendar-blocking.)

---

## 9. What the corrected plan changes, in one table

| # | Change | Defect closed |
|---|---|---|
| 1 | **G0 moves to N02**, immediately after the platform projects exist | Calendar · S12 |
| 2 | **N01 creates the Flutter project**, not just a `mkdir` | S11 |
| 3 | **New epic N10 — the component inventory** | G1 |
| 4 | **`test` job in N01-T06**; `codegen` N08; `android` N31 | G2 |
| 5 | The harness epic builds `pumpApp` + `Device` + seeds only; fakes and variants grow per epic | S1, S3 |
| 6 | `routes.dart` grows one helper per screen epic | S2 |
| 7 | The 6-tap budget splits 5 + 1 and **P8 is ruled against `07 §5.4` and `12 §10.1`** | S4 |
| 8 | `createEwe` takes `EntryContext` and consults `FreeTierPolicy` from its first commit | S5 |
| 9 | `SettingsRepository` moves to N12 | S6 |
| 10 | E08's sweeps move to N33; E08 keeps `contrast_test` | S7 |
| 11 | `copy.*` rules split between N03 and N06 | S8 |
| 12 | N24 regenerates the fixtures | S10 |
| 13 | E06 re-cut: `build_runner` per cluster, `make gen` once, the freeze alone | Red main · sizing |
| 14 | E19 → N22 + N23; E09 → N11 + N12; E28 → N33; E30 → N32 + N34 | Sizing |
| 15 | Note search absorbed into Flock (N26) | Sizing |
| 16 | **N32 moves before N33** so Play's 14-day clock runs in parallel with the sweeps | Calendar |
| 17 | Closer tasks deleted; a11y/ARB authored inside each widget task | Granularity |
| 18 | `docs/calendar.md` + a red-until-recorded policy test | Calendar |
| 19 | `/code-review` → `/shed-code-review` on every task | Skills |
| 20 | Every task carries a named first failing test and ≤ 3 skills | TDD · Skills |

---

## 10. Rules of the corrected plan (replaces `00-PLAN` §1)

| Rule | Detail |
|---|---|
| **One PR per epic** | Unchanged. Branch from merged `main`, wait for `gate` · `codegen` · `test` · `android`, merge, then cut the next branch |
| **One commit per task** | Unchanged, with the four stated exceptions (toolchain bump, golden re-baseline, `[exempt]` line, and a schema change which must **not** be split). **N07's fourteen-into-eight re-cut is a stated exception**: its commits are not individually green and the epic is reviewed as one diff |
| **Every task names its first failing test** | Not "write tests for X" — a file, a test name, and why it is red today. §11.3 |
| **Every task names ≤ 3 skills** | Two auto-firing plus `shed-testing` where it genuinely spans a seam. §11.4 |
| **Every task ends `/simplify` → `/shed-code-review` → commit** | **Never `/code-review`.** `/shed-code-review` is additionally run over the whole branch before the PR opens |
| **Accessibility and the ARB are authored inside the widget task** | No closer task, no sweep epic for authoring. Only the four *verification* sweeps are deferred, to N33 |
| **Green `main`, always** | Unchanged, and now actually achievable |
| **A calendar commitment is red until it is recorded** | `test/policy/calendar_commitments_test.dart` fails while any row of `docs/calendar.md` lacks a date and an outcome |

---

## 11. The corrected plan

### 11.1 The epic table — 35 epics

| # | Epic | Was | Size | Demoable on merge |
|---|---|---|---|---|
| **N00** | Decisions, rulings and the calendar | E00 +4 | S · no `lib/` | `docs/calendar.md` exists with seven commitments; the ledger test is red for the unrecorded ones and names them |
| **N01** | The project, the platform folders, the configs and the CI shell | E01 + `flutter create` | M | `make check` green on an empty tree; a PR shows green `gate` **and** `test` jobs |
| **N02** | **G0 — the merged-manifest record** | **E29-T01, moved forward 29 epics** | S · no `lib/` | `13 §2.2`'s four-row table is filled in from a real release AAB, and `g0_recorded_test.dart` goes green |
| **N03** | The gate | E02 | L | Plant any violation, exit 1 naming the rule id — every rule proved by the task that added it |
| **N04** | Domain: time and units | E03 | M | Pure-Dart suite green including DST-1…DST-5 against 01:00–01:59, no Flutter involved |
| **N05** | Domain: withdrawal | E04 | M | The 167-hour regression passes; a period is unconstructible except through `WithdrawalDays.asEnteredByUser` |
| **N06** | Domain: statistics, warnings, policy — **and the two `copy.*` gate rows** | E05 + S8 | L | Every statistic carries its verbatim definition and `notComputableReason`; `rankTagMatches('12')` ranks 12 → 128 → 412; the gate now refuses a re-typed disclaimer |
| **N07** | The schema and the freeze | E06, re-cut 14 → 8 | XL · one PR | A real SQLite file opens `STRICT`, refuses garbage, seeds a season nobody asked for, and `drift_schema_v1.json` is committed once |
| **N08** | The migration harness and the `codegen` job | E07 | M | Every from→to pair runs `migrateAndValidate` with FTS5 present; `make gen` produces no git diff in CI |
| **N09** | The design system foundation | E08, sweeps removed | L | `contrast_test.dart` recomputes every pair in all six palettes and holds 4.5:1 / 3:1 |
| **N10** | **The component inventory** | **new** | L · 15 files | Every `06 §12` component renders in a widget test at scale 2.0 and bold, with a `semanticLabel` and a ≥ 64 × 64 target |
| **N11** | Bootstrap, errors and the first frame | E09a | L incl. native | Launches on both platforms to a dark first frame with no white flash; a thrown widget renders the night panel |
| **N12** | The DI root, settings, the ticker and the harness | E09b + S6 | L | `pumpApp` pumps a widget against `NativeDatabase.memory()`; `guard()` refuses a concurrent call |
| **N13** | Quick Entry: the deck and the keypad | E10 | M | Type `12` on a real phone and 412 · 128 · 12 rank in the same frame, no SQL round trip |
| **N14** | Quick Entry: the write path | E11 + S5 | M | **Five taps from launch to a committed lambing row**, and the cap never speaks on the live-entry path |
| **N15** | Media and notes | E12 | M | A photo and a voice note land under `<appSupport>/media/YYYY/MM/` and survive an update, because only the relative path was stored |
| **N16** | Lambing Entry — **and the P8 ruling** | E13 + S4 | L | One slab per lamb and the row reads `TRIPLET (COUNTED)`; no widget in the tree carries a `birth_type` key; **six taps to a lambing with one lamb** |
| **N17** | Lamb Card | E14 | M | A birthweight typed on the app's own keypad, stored in grams, shown in the user's unit |
| **N18** | Foster | E15 | M | A reassignment in one tap, both dams on the page forever |
| **N19** | Pen Board | E16 | L | The whiteboard, live, every tile ticking in the same frame on the minute boundary |
| **N20** | Treatments and withdrawal | E17 | L | Repeat last treatment is two taps and prints `DAYS NOT COPIED — READ THE BOTTLE` |
| **N21** | Export: CSV, PDF and share | E18 | L | Three CSVs and two PDF volumes leave the phone through the share sheet, every struck row marked |
| **N22** | The JSON backup format | E19a | L | A backup round-trips `unknown_json`; a higher-schema file is refused in words a shepherd can act on |
| **N23** | Restore, the sweeps and the seed | E19b | L | `dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42` fills a phone **through the restore path**; export → import → export is equal |
| **N24** | Reminders: rows, reconcile and the fixtures | E20 + S10 | L | A 312-reminder flock projects exactly 56 and drops none of the rest; both fixtures regenerated |
| **N25** | Reminders screen | E21 | M | The discrepancy stated in one honest line with both numbers read from data |
| **N26** | Flock **and Note Search** | E22 + E25 | L | 400 ewes filter to "currently penned" at 11am; type `watery` and every note that ever said it comes back in under a second |
| **N27** | Ewe Card | E23 | L | *"3 seasons · avg 2.0 · assisted twice · prolapsed 2025"* |
| **N28** | Season Summary | E24 | L | Every number carries its definition and caveats; the chart uses no chart library and reads at 200% |
| **N29** | Settings | E26 | L | Rename *ewe* to *gimmer* and the whole app says gimmer; delete-everything says what it will destroy first |
| **N30** | Monetization | E27 − T04 | L | One unlock buys it forever; nothing about money renders on the five shed screens at any entitlement state **or hour** |
| **N31** | Platform artefacts, G1, G4, G5 | E29 − T01 | L | `bundletool dump manifest` on a real release `.aab` shows exactly the permission set G0 recorded |
| **N32** | **Signing and the closed track opens** | E30a, **moved before N33** | M | A signed AAB reaches a Play closed track and TestFlight — **the 14-day clock starts here, not at the end** |
| **N33** | Ship gates: the sweeps, the matrix, the goldens, the journeys | E28 + `goldens.yml` | L | The 252-cell matrix, the semantics gate, the tap-target gate, four journeys and eight verified PNGs |
| **N34** | Release engineering | E30b | M | `git tag v1.0.0` produces a signed AAB, eight goldens and a symbols archive kept off the laptop |

Critical path is still the whole plan. Two things now run beside it: the **calendar ledger** (N00 →
closed at N32) and the **12-tester clock** (N32 → N34).

### 11.2 Tasks that changed

Epics not listed keep `00-PLAN` §3's tasks, minus the closer task (§4) and plus the anchors in §11.3.

**N00 — Decisions, rulings and the calendar** *(6 → 9)*

| Task | One line |
|---|---|
| N00-T01 | Pin Flutter 3.44.8 / Dart 3.12.2 through `.fvmrc`, with an assertion that fails on a floating channel |
| N00-T02 | Author `pubspec.yaml` from decision-record §5 verbatim and commit the resolved `pubspec.lock` as the evidence it resolves |
| N00-T03 | Rule the four schema-shaped questions — `WithdrawalTarget.milk`, the temperature column, `Lambs.became_ewe`, **and lambing ease 5 vs 6** — before they expire at the freeze |
| N00-T04 | **Rule P1** — `struck` / `struck_at` on every table — into `CONVENTIONS §6` and the decision record |
| N00-T05 | **`docs/calendar.md`** — one row per commitment, each with an owner, a date and an outcome field |
| N00-T06 | Book the field night and start recruiting twelve shepherds; record both in the ledger |
| N00-T07 | **The ziplock-bag capacitance test** — a phone, a freezer bag, a recorded result, and the named consequence if it fails (decisions #100–#102 and the whole interaction model) |
| N00-T08 | **Store accounts** — answer the post-13-Nov-2023 personal-account question, create both developer accounts, enrol in the Apple Small Business Program, record the price and territories |
| N00-T09 | **Rule the two dependency-shaped open questions before the pubspec closes** — in-app PDF printing (`printing` → `http`) and the voice-note cap |

**N01 — The project, the platform folders, the configs and the CI shell** *(6 → 7)*

| Task | One line |
|---|---|
| N01-T01 | **`flutter create` with the fixed application id and bundle id**, then prune to the `CONVENTIONS §1` tree; `.gitignore` from §7.2 |
| N01-T02 | `analysis_options.yaml` — `flutter_lints` 6.0.0 plus the explicit strict block |
| N01-T03 | `build.yaml`, `l10n.yaml`, **`lib/l10n/app_en.arb` with its first string**, and the committed generated l10n |
| N01-T04 | `dart_test.yaml` — the two presets, the two tags, randomisation off for `migration` |
| N01-T05 | **`[audit]`** The **seven**-target `Makefile` — `gen` · `check` · `test` · `goldens` · `goldens-update` · `perf` · `integration` (`13` §1.3, verbatim) — cheapest failure first, **with `python3 tool/validate_skills.py` added as a command inside `check`, which adds a step and not a target** |
| N01-T06 | `.github/workflows/ci.yml` — the **`gate` and `test`** jobs, blocking, with `libsqlite3-dev` on the test runner |
| N01-T07 | `.github/pull_request_template.md` carrying the five §12 questions verbatim |

**N02 — G0** *(new epic, 3 tasks, no `lib/`)*

| Task | One line |
|---|---|
| N02-T01 | Run `flutter build appbundle --release` with `in_app_purchase` present; archive the merger report; record the exact `uses-permission` set, whether billing 8.0.0 contributes `ACCESS_NETWORK_STATE`, whether `src/debug`'s `INTERNET` survives, and the effective `minSdk` — into `13 §2.2`'s table |
| N02-T02 | The ruling G0 produces: `INTERNET` removed, `ACCESS_NETWORK_STATE` **left or removed on evidence**, and — if left — the store-listing honesty paragraph drafted now, before any copy is authored |
| N02-T03 | `test/policy/g0_recorded_test.dart` — no `tools:node="remove"` line may exist while the table reads UNVERIFIED |

**N07 — The schema and the freeze** *(14 → 8; `build_runner` per task, `make gen` once)*

| Task | One line |
|---|---|
| N07-T01 | `connection.dart` — `openConnection`, the seven pragmas in R13's order, the FTS5 assertion, the in-memory harness |
| N07-T02 | `database.dart`, `kSchemaVersion`, `converters.dart`, `uid.dart`, `mixin Identified` carrying P1's `struck` / `struck_at` |
| N07-T03 | The flock cluster — `seasons`, `ewes`, `ewe_seasons`, `ewe_touches`, `ewe_observations`, the active-only partial unique index on `tag` |
| N07-T04 | The lambing cluster — `lambings`, `lambs`, `foster_events`, `care_events`, the birth-dam trigger, `lamb_rearing` and `lambing_consistency` |
| N07-T05 | The pen and treatment clusters — `pens`, `pen_occupancies`, `pen_occupancy_lambs`, `treatments`, `treatment_withdrawals` (**no `DEFAULT` on `days`; no row means not recorded**) |
| N07-T06 | The ancillary cluster — `reminders`, `reminder_rules`, `notes`, `media_assets`, `vocab_terms`, `terminology_overrides`, `app_settings`, `entitlements`, `ewe_summaries`, `unknown_json` on all 21 restorable tables |
| N07-T07 | `search.drift`, `views.drift`, `queries.drift` and `seedFirstRun` in `onCreate` |
| N07-T08 | **The freeze, alone** — `make gen` in full, `drift_schema_v1.json`, `schema_versions.dart`, `test/drift/generated/**`, plus `withdrawal_has_no_default_test.dart`'s schema-JSON half |

**N10 — The component inventory** *(new epic)*

| Task | One line |
|---|---|
| N10-T01 | `ShedPrimaryButton` — the corner slab, its per-page verb, five states, and the rule that it never refuses a press |
| N10-T02 | `ShedSecondaryButton` and `ShedDestructiveButton` — the word button's forms, two-step destruction, `gapDestructive` separation |
| N10-T03 | `ShedConfirmBar` and `ShedRecentsStrip` — outcome-labelled, fixed height at frame 1 so nothing shifts |
| N10-T04 | `ShedAnimalRow` and `ShedSectionHeading` — the 64/88 px ruled rows, the sub-grid, `headingLevel` 1 and 2, `header:` banned |
| N10-T05 | `ShedStatusBadge` and `ShedCountdown` — icon **and** word always; "not recorded" a first-class state, never `0`, never blank |
| N10-T06 | `ShedChoiceRow` (**ease 1–5 only — P8**) and `ShedFieldRow` (label above value, no placeholder inside a field) |
| N10-T07 | `ShedBottomSheet` — the only overlay in the app, no drag handle, no drag, not dismissible, explicit Cancel |
| N10-T08 | `ShedEmptyState`, `ShedBanner`, `ShedReceiptBar` — the same box the content will occupy, never modal, never 22:00–06:00, never on the five shed screens |

**N12 — The DI root, settings, the ticker and the harness** *(from E09-T08…T11 + S6)*

| Task | One line |
|---|---|
| N12-T01 | `providers.dart` — `databaseProvider` and the DI graph as far as it can reach today |
| N12-T02 | **`SettingsRepository`** plus `settingsProvider`, `themeProvider`, `unitsProvider`, `terminologyProvider`, and one parameterised test that every setting persists and re-reads |
| N12-T03 | `minuteTickProvider` — one boundary-aligned 60 s ticker yielding `Instant`, `autoDispose`, never `Timer.periodic` |
| N12-T04 | `WriteController` and `guard()` — the double-tap defence, refusing to run concurrently |
| N12-T05 | `test/support/` — `pumpApp`, the `Device` table, `seeds.dart`. **No fakes, no `kPumpableVariants`** — both grow with the epics that create their subjects |

**N14 — Quick Entry: the write path**

Unchanged except: **T01** `createEwe` takes `EntryContext` and consults `FreeTierPolicy` from its first
commit; **T06** becomes the five-tap assertion (see §11.3).

**N16 — Lambing Entry**

Unchanged plus **T02a — rule P8 against the artefacts**: amend `07 §5.4`'s 6-tap composition and
`12 §10.1`'s sixth tap in the same commit, per the amendment rule, and land the six-tap assertion with
the tally stroke.

**`[audit]` T02a must amend two more artefacts, or its own canary contradicts the naming authority.**
`CONVENTIONS §4.5` publishes **`lambing_entry.birth_type.twin`** as a worked example of the widget-key
format, and **R59** rules that `Key('birthType.twin')` *becomes* `lambing_entry.birth_type.twin` — the
naming authority therefore still blesses a key for a control P8 abolished, while
`'no widget with a birth_type key exists anywhere in the tree'` forbids it. Replace the example in
§4.5 with a key that survives (`lambing_entry.tally.stroke`) and restate R59 on it, in T02a's commit.
`06 §12`'s `ShedChoiceRow` row — *"Birth type, ease 1–5, death cause"* — is the third artefact and is
already handled by N10-T06's *ease 1–5 only*; make T02a the commit that edits it.

**N24 — Reminders**

Unchanged plus **T08 — regenerate and re-commit `flock_400_3seasons.json` and `flock_15_at_cap.json`**
now that reminder rows have a writer.

**N32 — Signing and the closed track opens** *(from E30)*

| Task | One line |
|---|---|
| N32-T01 | The upload keystore, `key.properties` gitignored, Play App Signing, and the iOS half |
| N32-T02 | The Play app record and the store listing draft carrying N02-T02's honesty paragraph |
| N32-T03 | **Open the closed track with the first signed AAB and open TestFlight** — the 14-day clock starts |

**N33 — Ship gates**

E28's eight tasks plus **T09 — `goldens.yml`**, so the eight images are verified by CI in the epic that
creates them.

### 11.3 Test-first anchors for the load-bearing tasks

| Task | First failing test — file · name |
|---|---|
| N00-T01 | `test/policy/toolchain_pin_test.dart` · `'.fvmrc pins 3.44.8 and never the string stable'` |
| N00-T02 | `test/policy/lockfile_is_evidence_test.dart` · `'pubspec.lock pins flutter_riverpod to exactly 2.6.1 and declares no package:test'` |
| N00-T05…T08 | `test/policy/calendar_commitments_test.dart` · `'every commitment in docs/calendar.md has a date and an outcome'` |
| N01-T06 | `test/policy/ci_jobs_test.dart` · `'ci.yml declares gate and test, both blocking, on push and pull_request'` |
| N02-T03 | `test/policy/g0_recorded_test.dart` · `'no tools:node="remove" line exists while 13 §2.2 reads UNVERIFIED'` |
| N03-T02 | `test/policy/gate_rules_test.dart` · `'layer.features_no_db exits 1 on a planted drift import under lib/features/'` |
| N03-T04 | `test/policy/gate_rules_test.dart` · `'G2 exits 1 on a package added to pubspec.lock dependencies but not the allowlist'` |
| N04-T01 | `test/domain/time/instant_test.dart` · `'Instant exposes no now() and orders by epoch millis'` |
| N04-T05 | `test/policy/one_clock_test.dart` · `'DateTime.now( appears in exactly one non-generated file under lib/'` |
| N04-T08 | `test/domain/uk_zone/dst_test.dart` · `'DST-2: 01:30 on the clocks-back night resolves without throwing, and the file fails loudly under a wrong TZ'` **`[audit]`** — DST-1…DST-5 are one `@Tags(['uk-zone'])` file (`CONVENTIONS §1`; `05` §checklist) |
| N05-T01 | `test/policy/withdrawal_has_no_default_test.dart` · `'WithdrawalPeriod has no public generative constructor'` |
| N05-T02 | `test/domain/uk_zone/dst_test.dart` · `'DST-5: 7 days across UK spring-forward is 168 h absolute, and civil-day arithmetic would give 167'` **`[audit]`** — same file as N04-T08; the pure non-DST arithmetic stays in `test/domain/withdrawal/clear_date_test.dart` |
| N06-T07 | `test/domain/tag_match_test.dart` · `"rankTagMatches('12') returns 12, 128, 412 in that order"` |
| N06-T09 | `test/policy/disclaimer_is_defined_once_test.dart` · `'Disclaimers.exportFooter appears as a literal in exactly one file'` **`[audit]`** — the file name is `09` §7's, not a new one |
| N07-T01 | `test/data/connection_test.dart` · `'an opened connection reports synchronous=2, foreign_keys=1 and compiles an FTS5 table'` |
| N07-T05 | `test/data/schema_refuses_test.dart` · `'inserting a treatment_withdrawals row without days is rejected, and no row means NotRecorded'` |
| N07-T08 | `test/policy/withdrawal_has_no_default_test.dart` · `'drift_schema_v1.json has null defaultValue and null clientDefault for treatment_withdrawals.days'` |
| N08-T02 | `test/drift/migration_matrix_test.dart` · `'every from-to pair passes migrateAndValidate and foreign_key_check returns zero rows'` |
| N08-T05 | `test/drift/fts5_shadow_tables_test.dart` · `'SchemaVerifier accepts a schema containing FTS5 shadow tables'` |
| N09-T03 | `test/design/contrast_test.dart` · `'every text pair in all six palettes reaches 4.5 to 1 and every rule and mark 3 to 1'` |
| N09-T07 | `test/design/tap_target_test.dart` · `'ShedTapTarget lays out at least 64 by 64 and requires a semanticLabel'` |
| N10-T01…T08 | `test/design/components_test.dart` · `'<Component> renders at textScale 2.0 with boldText and every **tap surface** in its tree is at least 64 by 64 with a semanticLabel'` **`[audit]`** — *not* "no dimension below 64": `06 §12` sizes `ShedStatusBadge` at ≥ 24 tall inside a ≥ `tapMin` parent and gives `ShedSectionHeading` no target contract at all, so the earlier wording made two of the fifteen components unbuildable |
| N10-T07 | `test/policy/one_overlay_test.dart` · `'showModalBottomSheet( appears nowhere outside shed_bottom_sheet.dart, and showDialog( nowhere outside the two allowlisted destructive files'` **`[audit]`** — `ui.show_dialog` (`CONVENTIONS §4.7`) allowlists restore and delete-everything by name (`07 §12`); banning `showDialog(` outright would make the only two honest deletes in the app illegal |
| N11-T03 | `test/policy/main_awaits_nothing_test.dart` · `'main() contains no await and installs both handlers before runApp'` |
| N11-T04 | `test/features/night_error_panel_test.dart` · `'ErrorWidget.builder renders NightErrorPanel with no Theme or MediaQuery ancestor'` |
| N11-T06 | `test/design/first_frame_parity_test.dart` · `'the Android and iOS launch colours equal the page token'` |
| N12-T04 | `test/features/write_controller_test.dart` · `'guard() refuses a second invocation while the first is running'` |
| N12-T05 | `test/support/harness_test.dart` · `'pumpApp builds a widget against NativeDatabase.memory() with no production override'` |
| N13-T02 | `test/features/quick_entry_test.dart` · `'typing 12 reorders the match list in the same frame with no database read'` |
| N13-T04 | `test/features/keypad_test.dart` · `'no keypad key is ever disabled, including over the free cap'` |
| N14-T01 | `test/data/flock_repository_test.dart` · `'createEwe with EntryContext.liveEntry never returns BlockedByCap and marks the row over_free_cap'` |
| N14-T02 | `test/data/lambing_repository_test.dart` · `'beginLambing commits a row and throws on failure, returning a LambingId'` |
| N14-T04 | `test/policy/no_snackbar_test.dart` · `'showSnackBar( appears nowhere in lib/, including feedback.dart'` |
| N14-T06 | `test/features/tap_budget_test.dart` · `'unlock to a committed beginLambing row costs 5 taps and no typing'` |
| N14-T07 | `test/features/no_monetization_test.dart` · `'no monetization widget renders on Quick Entry at any entitlement state or hour'` **`[audit]`** — R57 names this file; it is a widget test, so it is `test/features/`, not `test/policy/` |
| N15-T01 | `test/data/media_store_test.dart` · `'an absolute path is rejected by the relative_path CHECK'` |
| N16-T02 | `test/features/lambing_entry_test.dart` · `'three strokes print TRIPLET (COUNTED) and no widget carries a birth_type key'` |
| N16-T02a | `test/features/tap_budget_test.dart` · `'unlock to a lambing with one lamb costs 6 taps'` |
| N16-T06 | `test/features/lambing_entry_test.dart` · `'a declared type contradicting the strokes prints a query mark and leaves both values unchanged in the database'` |
| N17-T02 | `test/domain/units_test.dart` · `'a weight typed in lb round-trips through canonical grams without rewriting the entry'` |
| N18-T01 | `test/data/foster_repository_test.dart` · `'recordFoster leaves birth_dam unchanged and appends a FosterEvent'` |
| N18-T05 | `test/features/tap_budget_test.dart` · `'foster reassignment from the Foster screen costs 1 tap'` |
| N19-T01 | `test/data/pen_repository_test.dart` · `'the partial unique index refuses a second open occupancy for pen 3'` |
| N20-T02 | `test/features/treatments_test.dart` · `'the withdrawal field renders no placeholder, no prefill and no default'` |
| N20-T04 | `test/features/tap_budget_test.dart` · `'repeat last treatment costs 2 taps, leaves days blank, and renders Disclaimers.withdrawalProvenance'` |
| N21-T01 | `test/features/csv_writer_test.dart` · `'a field containing a comma, a quote and a newline round-trips per RFC 4180'` |
| N21-T02 | `test/features/csv_shapes_test.dart` · `'every struck row is present in the lambs CSV and carries struck_at'` |
| N22-T03 | `test/features/backup_forward_compat_test.dart` · `'an unknown column survives into unknown_json and is re-emitted at the row top level'` |
| N23-T06 | `test/features/overflow_matrix_test.dart` · `'restoreFixture loads flock_400_3seasons.json into an in-memory database'` |
| N23-T10 | `test/policy/backup_round_trips_test.dart` · `'export to import to export produces equal tables bytes, equal checksums, re-issued ids and preserved uids'` **`[audit]`** — `12` §9 owns where it lives and spells it plural; `09` §7.3 owns what it asserts. One file, two owners, no second copy |
| N24-T01 | `test/domain/reminder_budget_test.dart` · `'forPlatform returns 56 on iOS and 200 on Android'` |
| N24-T05 | `test/data/reconcile_test.dart` · `'reconcile is idempotent and projects exactly the soonest 56 of 312'` |
| N25-T02 | `test/features/reminders_test.dart` · `'the windowed line reads both numbers from data and never a literal 56'` |
| N26-T01 | `test/features/flock_test.dart` · `'the filter set narrows 400 ewes to currently penned in one statement'` |
| N26-T05 | `test/features/note_search_test.dart` · `'a 200 ms debounced query for watery returns every note that contains it'` |
| N27-T02 | `test/features/ewe_card_test.dart` · `'the summary line is assembled in Dart from ewe_summaries counts, not read as a stored string'` |
| N28-T04 | `test/features/spread_chart_test.dart` · `'the spread chart exposes a semanticsBuilder node per day and imports no chart package'` |
| N29-T06 | `test/features/settings_test.dart` · `'delete everything names what it will destroy and requires two steps'` |
| N30-T04 | `test/policy/cap_never_blocks_live_entry_test.dart` · `'startSeason returns WriteRefused at the cap and createEwe on the live-entry path does not'` **`[audit]`** — the doc-named file; `FreeTierPolicy.decide`'s pure arithmetic stays in `test/domain/free_tier_test.dart` |
| N30-T08 | `test/features/no_monetization_test.dart` · `'no monetization widget renders on any of the five shed screens at any entitlement state or hour'` **`[audit]`** — the same file N14-T07 created, extended; R57 |
| N31-T03 | `test/policy/permission_set_test.dart` · `'expected_permissions.txt matches G0 exactly and contains no INTERNET'` |
| N33-T01 | `test/features/overflow_matrix_test.dart` · `'the matrix covers every route, and the count is 14'` |
| N33-T02 | `test/design/semantics_gate_test.dart` · `'the canary widget with no semanticLabel fails the sweep'` **`[audit]`** — `12` §7.4 splits the guideline sweeps into `test/design/`; `test/features/` is the matrix and the budgets |
| N33-T05 | `test/policy/arb_has_no_domain_noun_test.dart` · `'every user-facing string is an ARB key with a description and no domain noun is a literal'` **`[audit]`** — the doc-named file; it pairs with `test/policy/vocab_labels_are_complete_test.dart`, which asserts the ~40 seeded `vocab_terms` keys and their ARB labels are the same set (R66) |

### 11.4 Skills per epic

At most two auto-firing, plus `shed-testing` where the task genuinely spans a seam. All names verified
against the 24 authored skills in `.claude/skills/`.

| Epic | Skills |
|---|---|
| N00, N01 | `shed-dependencies-and-toolchain`, `shed-conventions` |
| N02 | **`[audit]`** `shed-platform-gateways` (auto — `CLAUDE.md` routes `AndroidManifest.xml` and permissions here) **+ `/shed-release`, typed by name**: it carries `disable-model-invocation: true`, so it never fires on its own, and its description is the only one that names *"the offline gates G0 to G5 against a real release bundle"* |
| N03 | `shed-conventions`, `shed-dependencies-and-toolchain` |
| N04, N06 | `shed-domain`, `shed-testing` |
| N05 | `shed-withdrawal`, `shed-safety-rules` |
| N07, N08 | `shed-drift-schema`, `shed-migrations` (by name, N07-T08 and N08 only) |
| N09, N10 | `indelible-design-system`, `indelible-controls` / `indelible-marks-and-strikes` / `indelible-states-and-feedback` by component |
| N11 | `shed-bootstrap-and-errors`, `indelible-states-and-feedback` |
| N12 | `shed-riverpod-providers`, `shed-testing` |
| N13, N14 | `shed-screens-and-routing`, `indelible-page-and-screens`; N14 adds `shed-write-path` |
| N15 | `shed-platform-gateways`, `indelible-controls` |
| N16–N19 | `shed-write-path` + `indelible-marks-and-strikes` (N16, N19), `shed-screens-and-routing` + `indelible-page-and-screens` (N17, N18) |
| N20 | `shed-withdrawal`, `indelible-marks-and-strikes` |
| N21–N23 | `shed-export-and-restore`, `shed-platform-gateways` (N21 share seam only) |
| N24, N25 | `shed-platform-gateways`, `shed-screens-and-routing` |
| N26–N29 | `shed-screens-and-routing`, `indelible-page-and-screens`; N28 adds `shed-domain`; N29 adds `shed-accessibility-and-copy` |
| N30 | `shed-monetization`, `indelible-states-and-feedback` |
| N31, N32, N34 | `shed-platform-gateways`, `shed-release` (by name) |
| N33 | `shed-testing`, `shed-accessibility-and-copy`; `shed-goldens-rebaseline` by name for the PNG commit only |

### 11.5 The gates inside the sequence

| Gate | Where | If it is not met |
|---|---|---|
| The five pre-commit decisions | N00 | Everything else can be revisited in week two. These cannot |
| **P1 is ruled** | N00-T04, before N07 | `struck` / `struck_at` after the snapshot is a rebuild of every table pointing at a shepherd's records |
| **G0 has been run** | **N02** | The permission set, the store listing and three screens' copy are all written on faith, and re-opened at N31 |
| **The schema freeze** | N07-T08 | Anything `00-README` §5.2 marks schema-shaped becomes a migration on somebody else's phone in April |
| **P8 is ruled against the artefacts** | N16-T02a | `07 §5.4` and `12 §10.1` keep prescribing a chooser the product does not have, and `declared_birth_type` has no writer |
| **The write path and the receipt** | N14 | Every screen after it is a variation on machinery built here |
| **The closed track is open** | N32 | Fourteen days of dead calendar at the end of the project |

---

## 12. What to do first

1. Fix the three §1 rules so they are true, or delete them.
2. Add the anchors (§11.3) — the plan is unstartable without them.
3. Move G0 to N02 and create the platform folders in N01. It is an afternoon and it de-risks the
   product's central claim.
4. Add N10. Without it, twelve epics each build their own buttons and the layer rule forbids sharing
   them afterwards.
5. Rule P8 against `07 §5.4` and `12 §10.1` before N14 is written, because N14's demo sentence depends
   on which ruling is real.

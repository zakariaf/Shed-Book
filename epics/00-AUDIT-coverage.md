# Audit — coverage, sequencing, and the mechanical checker

**Lens.** Does every screen, feature, entity, safety rule, gate, pipeline job and named artefact have a
task that delivers it? Does anything depend on something a later epic builds? And is any of that
checkable by a machine, or only by a careful reader on a good day?

**Audited.** 2026-07-31, against `epics/`, `CLAUDE.md`, `shed-book-spec.md`, `docs/engineering/**` and
`docs/research/00-tech-decisions.md`.

---

## 0. Headline

> **The backlog did not exist. It does now: 35 epics, 240 task files, and a checker that refuses eleven
> classes of defect and exits 0 on the tree as built.**

`epics/` contained `00-PLAN.md` (a 227-row index), `00-PLAN-CRITIQUE.md` (its corrections) and two
sibling audits. There were **no epic directories and no task files** — so the coverage question could
not be answered by reading the backlog, because the backlog was a table of contents.

This audit therefore did three things, in order:

1. **Built the backlog** from `00-PLAN-CRITIQUE.md` §11's corrected 35-epic re-cut, in the ten-section
   shape `00-AUDIT-template.md` §6 fixed as binding — 240 task files, each with a named first failing
   test, a skills table, a definition of done and a verification block.
2. **Walked the spec against it**, item by item. **Nothing is uncovered.** Seventeen items that had no
   task in `00-PLAN.md` — the component inventory, the `test` CI job, the ARB itself, the
   `WakelockController` seam, the ziplock test, the store accounts — were written into the epic each one
   belongs in.
3. **Wrote `tool/validate_epics.py`**, ran it, fixed the 24 real defects it found in the files this
   audit had just written, and watched every rule fire on a planted violation. Final run in §6.

Two defects the critique did not catch are recorded in §5. Both are sequencing defects of the same class
it names: **S12** — G0 was scheduled before the platform folders it needs existed even in the corrected
plan; **S13** — every task in the corrected N00 names a failing Dart test, and eight of them were
scheduled before a Dart test runner existed.

---

## 1. The backlog as built

35 epics · 240 tasks · one pull request per epic · one commit per task except twice, both stated · every
task TDD with a named first failing test · every task closes `/simplify` → `/code-review` →
`/shed-code-review` → commit.

| Epic | Tasks | Was | What it leaves behind |
|---|---:|---|---|
| [N00](N00-decisions-rulings-and-the-calendar/epic.md) Decisions, rulings and the calendar | 9 | E00 + 4 | The project, the pin, the lockfile, four rulings, and a commitment ledger a test can read |
| [N01](N01-the-tree-the-configs-and-the-ci-shell/epic.md) The tree, the configs and the CI shell | 7 | E01 + 3 | `make check` green on an empty tree; `gate` **and** `test` jobs; the ARB exists |
| [N02](N02-g0-the-merged-manifest-record/epic.md) G0 — the merged-manifest record | 3 | E29-T01, moved 27 epics earlier | The permission set is evidence, not hope |
| [N03](N03-the-gate/epic.md) The gate | 7 | E02 | ~30 rules, each proved by the commit that added it |
| [N04](N04-domain-time-and-units/epic.md) Domain: time and units | 8 | E03 | Pure Dart, DST-1…DST-5, one wall-clock reader |
| [N05](N05-domain-withdrawal/epic.md) Domain: withdrawal | 5 | E04 | §12.1 at *unconstructible*; the 167-hour regression |
| [N06](N06-domain-statistics-warnings-and-policy/epic.md) Domain: statistics, warnings, policy | 11 | E05 + 2 | Every statistic with its definition; `FreeTierPolicy`; the ~40 authored terms |
| [N07](N07-the-schema-and-the-freeze/epic.md) The schema and the freeze | 8 | E06, re-cut 14→8 | 23 tables, one snapshot, committed once |
| [N08](N08-the-migration-harness-and-the-codegen-job/epic.md) Migration harness and `codegen` | 7 | E07 | The matrix, the loud downgrade, the no-diff job |
| [N09](N09-the-design-system-foundation/epic.md) Design system foundation | 9 | E08 − sweeps | Six palettes measured, not chosen; P7 and P10 ruled |
| [N10](N10-the-component-inventory/epic.md) The component inventory | 8 | **new** | The 21 components twelve screens would otherwise each invent |
| [N11](N11-bootstrap-errors-and-the-first-frame/epic.md) Bootstrap, errors, first frame | 9 | E09a | Dark first frame on both platforms; P14 ruled |
| [N12](N12-the-di-root-settings-the-ticker-and-the-harness/epic.md) DI root, settings, ticker, harness | 5 | E09b + S6 | `pumpApp`, `guard()`, one ticker, `SettingsRepository` |
| [N13](N13-quick-entry-the-deck-and-the-keypad/epic.md) Quick Entry: deck and keypad | 7 | E10 | Same-frame ranking; P3 ruled; the variant table is born |
| [N14](N14-quick-entry-the-write-path/epic.md) Quick Entry: the write path | 7 | E11 + S5 | **Five taps to a committed lambing row** |
| [N15](N15-media-and-notes/epic.md) Media and notes | 6 | E12 | Relative paths only; the record survives a full disk |
| [N16](N16-lambing-entry/epic.md) Lambing Entry and the P8 ruling | 10 | E13 + S4 | `TRIPLET (COUNTED)`; no `birth_type` key anywhere |
| [N17](N17-lamb-card/epic.md) Lamb Card | 5 | E14 | Grams in storage, the user's unit on screen |
| [N18](N18-foster/epic.md) Foster | 5 | E15 | One tap; the birth dam is immutable by trigger |
| [N19](N19-pen-board/epic.md) Pen Board | 7 | E16 | The live whiteboard on one ticker |
| [N20](N20-treatments-and-withdrawal/epic.md) Treatments and withdrawal | 7 | E17 | `DAYS NOT COPIED — READ THE BOTTLE` |
| [N21](N21-export-csv-pdf-and-share/epic.md) Export: CSV, PDF and share | 8 | E18 | Three CSVs, two PDF volumes, every struck row marked |
| [N22](N22-the-json-backup-format/epic.md) The JSON backup format | 5 | E19a | `unknown_json` round-trips; a higher schema is refused |
| [N23](N23-restore-the-sweeps-and-the-seed/epic.md) Restore, the sweeps and the seed | 7 | E19b | The seed writes **through** restore; the round trip is equal |
| [N24](N24-reminders-rows-reconcile-and-the-fixtures/epic.md) Reminders: rows, reconcile, fixtures | 8 | E20 + S10 | 56 of 312 projected; both fixtures regenerated |
| [N25](N25-reminders-screen/epic.md) Reminders screen | 6 | E21 | The honest windowed line, both numbers from data |
| [N26](N26-flock-and-note-search/epic.md) Flock and Note Search | 7 | E22 + E25 | 400 ewes filtered; `watery` returns every note |
| [N27](N27-ewe-card/epic.md) Ewe Card | 7 | E23 | The summary line — the reason the product exists in year two |
| [N28](N28-season-summary/epic.md) Season Summary | 6 | E24 | Definitions with every number; no chart library |
| [N29](N29-settings/epic.md) Settings | 8 | E26 + G4 | Gimmer everywhere; the two honest deletes |
| [N30](N30-monetization/epic.md) Monetization | 8 | E27 − T04 | One unlock; nothing about money on any shed screen |
| [N31](N31-platform-artefacts-g1-g4-and-g5/epic.md) Platform artefacts, G1, G4, G5 | 4 | E29 − T01 − T06 | The offline claim, mechanically held in CI |
| [N32](N32-signing-and-the-closed-track/epic.md) Signing and the closed track | 3 | E30a, moved before N33 | The 14-day clock starts **here** |
| [N33](N33-ship-gates-sweeps-goldens-and-journeys/epic.md) Ship gates | 9 | E28 + `goldens.yml` | 252 cells, four sweeps, eight verified PNGs |
| [N34](N34-release-engineering/epic.md) Release engineering | 4 | E30b | A signed tag, symbols off the laptop, the seasonal freeze |

---

## 2. Coverage — every required item, and the task that delivers it

Walked from `shed-book-spec.md`. The owning task is named; a mechanical sweep over all 240 files
(`grep` per requirement, run as part of this audit) found **no requirement with zero matching tasks**.

### 2.1 The twelve screens plus Note Search

| Screen | Owning tasks | Matrix variant |
|---|---|---|
| 1 Flock | N26-T01 · T02 · T03 · T04 | N26-T07 |
| 2 Ewe Card | N27-T01 … T07 | N27-T07 |
| 3 Quick Entry | N13-T02 … T06 (read) · N14-T01 … T07 (write) | N13-T07, and **variant 14 with the banner** N21-T08 |
| 4 Lambing Entry | N16-T01 … T08 | N16-T09 |
| 5 Lamb Card | N17-T01 … T04 | N17-T05 |
| 6 Foster | N18-T01 … T04 | N18-T05 |
| 7 Pen Board | N19-T01 … T06 | N19-T07 |
| 8 Treatments | N20-T01 … T06 | N20-T07 |
| 9 Reminders | N25-T01 … T05 | N25-T06 |
| 10 Season Summary | N28-T01 … T05 | N28-T06 |
| 11 Export | N21-T07 (screen) · T01–T06 (artefacts) | N21-T07 |
| 12 Settings | N29-T01 … T07 (repository N12-T02) | N29-T08 |
| 13 Note Search | N26-T05 · T06 | N26-T07 |

Fourteen variants, because Quick Entry appears twice — plain and with the export banner. The count is
derived from the variant list in N33-T01, never typed.

### 2.2 Every §7 feature

| Feature | Owning tasks |
|---|---|
| §7.1 fast animal selection | N06-T07 (`rankTagMatches`) · N13-T02 (index) · N13-T03 (deck) · N13-T04 (keypad) · N13-T06 (recents, in-the-pens) · N14-T01 (create-on-the-fly) · N26-T01 (search) |
| §7.2 lambing event entry | N16-T02 (tally) · T03 (lambs) · T04 (ease) · T05 (care events) · T06 (warning) · T07 (time correction) · T08 (assistance, note, attachments) · media N15 |
| §7.3 lamb records and fostering | N17-T02 (sex, weight) · T03 (death) · T04 (pet lamb) · N18-T01…T04 (foster) · schema N07-T04 |
| §7.4 pen board | N19-T01 … T06 · timing domain N06-T07 |
| §7.5 treatments and medicines | N20-T01 … T06 · arithmetic N05-T01 … T05 |
| §7.6 reminders | N24-T01 … T07 (rows, channels, reconcile, permissions, tap) · N25-T01 … T05 (screen, intervals) |
| §7.7 history and recall | N27-T02 (the summary line) · N26-T02 (five filters) · N26-T05/T06 (full-text search) |
| §7.8 season summary | N28-T01 … T05 · statistics N06-T04 … T06 |
| §7.9 export and backup | N21 (CSV, PDF, share, banner) · N22 (JSON) · N23-T01/T02 (**restore**) · N23-T03 (sweeps) |
| §7.10 settings | N29-T02 (units) · T03 (terminology) · T04 (appearance, wakelock) · T05 (season) · T06 (deletes) · T07 (diagnostics) · N25-T05 (intervals) |

**Deliberately absent, on the owner's ruling:** §7.1's optional voice tag entry and tag OCR are cut from
v1. No task delivers them and none should; a task that did would be a defect.

### 2.3 Every §10 entity

All 23 tables land in N07, in four clusters, before one snapshot:

| Spec entity | Table(s) | Task |
|---|---|---|
| Season | `seasons`, `ewe_seasons` | N07-T03 |
| Ewe | `ewes`, `ewe_touches`, `ewe_observations` | N07-T03 |
| Lambing | `lambings` | N07-T04 |
| Lamb | `lambs`, `foster_events`, `care_events` | N07-T04 |
| Pen | `pens`, `pen_occupancies`, `pen_occupancy_lambs` | N07-T05 |
| Treatment | `treatments`, `treatment_withdrawals` | N07-T05 |
| Reminder | `reminders`, `reminder_rules` | N07-T06 |
| Note | `notes`, `media_assets` | N07-T06 |
| Settings | `app_settings` | N07-T06 |
| *(the four the spec's model hides)* | `vocab_terms`, `terminology_overrides`, `entitlements`, `ewe_summaries` | N07-T06 |

Plus `unknown_json` on all 21 restorable tables (N07-T06), the views and FTS5 (N07-T07), and the freeze
(N07-T08).

### 2.4 The five §12 safety rules

| Rule | Level it reaches | Tasks |
|---|---|---|
| §12.1 never default a withdrawal | unconstructible + unpersistable | Type N05-T01 · source scan N05-T04 · **no `DEFAULT`** N07-T05 · **schema JSON** N07-T08 · control N20-T02 · repeat N20-T04 |
| §12.2 never veterinary advice | test on source text | `ContentPolicy` N06-T09 · authored terms N06-T11 · the user's own threshold N19-T04 · statistics wording N28-T02 · observations N27-T06 |
| §12.3 never a compliance record | unconstructible | `Disclaimers` + `ExportEnvelope` N06-T09 · trailers N21-T03 · Export screen N21-T07 · About N29-T07 · backup header N22-T01 |
| §12.4 never silently correct | unrepresentable + unpersistable | `Warning` has no writer N06-T02 · validators N06-T03 · **derived birth type** N16-T02 · **P8 ruled** N16-T02a · query mark N16-T06 · `clearDateDisagrees` N05-T05 / N20-T06 |
| §12.5 timestamps are honest | unrepresentable | `RecordedTime` N04-T04 · the quad N07-T03…T06 · both times on `notes` N15-T04 · header N16-T07 · tile marker N19-T06 · every timeline row N27-T04 |

The five questions also appear verbatim in `.github/pull_request_template.md` — **N01-T07**, which had no
task in the old plan.

### 2.5 The offline gates G0–G5

| Gate | Task | Note |
|---|---|---|
| **G0** merged manifest from a real AAB | **N02-T01** · ruling N02-T02 · guard N02-T03 | Moved from epic 29 of 31 to epic 2 of 35 |
| **G1** permission assertion on the shipped `.aab` | N31-T03 | Against the set G0 recorded, not a hoped-for one |
| **G2** direct-dependency allowlist | N03-T04 | `dependencies` and `dev_dependencies` scanned separately |
| **G3** import scan | N03-T03 | Plus the recorded reason a `no http in pubspec.lock` rule must never be written |
| **G4** merger report archived | N31-T03 | Archived on every `android` run |
| **G5** iOS construction plus observation | N31-T04 | Recorded in the calendar ledger with a device and a date |

### 2.6 The CI pipeline, and everything else named in the brief

| Item | Task |
|---|---|
| `gate` job | N01-T06 · wired first in N03-T07 |
| `test` job (with `libsqlite3-dev`, three commands, two timezones) | **N01-T06** — created by nobody in the old plan |
| `codegen` job | N08-T06 |
| `android` job | N31-T03 |
| `release.yml` | N34-T01 |
| `goldens.yml` | N33-T09 — moved into the epic that creates the images |
| Export — CSV, PDF, share | N21-T01 … T06 |
| Backup — the JSON format | N22-T01 … T05 |
| **Restore** | N23-T01 (service) · N23-T02 (the two-step confirmation) · N23-T06 (`restoreInto`) |
| **`tool/seed.dart`** | N23-T04 (through the restore path) · N23-T05 (the two fixtures) · N24-T08 (regenerated) |
| Reminders | N24 (rows, channels, reconcile) · N25 (screen) |
| Monetization | N06-T10 (policy) · N14-T01 (gated verb) · N14-T07 + N30-T08 (nothing on a shed screen) · N30 (store, entitlement, unlock) |
| Release | N32 (signing, tracks) · N34 (workflow, symbols, perf, freeze) |

### 2.7 Items that had no task in `00-PLAN.md`, and now do

This is the coverage finding. Seventeen things were specified somewhere in the doc set and owned by
nobody in the backlog.

| Missing item | Source that requires it | Written into |
|---|---|---|
| **`lib/core/ui/components/` — 15 of 21 components** | `06 §12`; a sibling-feature import is a layer violation | **N10, a new epic** |
| The `test` CI job | `13 §4.2` | N01-T06 |
| `lib/l10n/app_en.arb` itself, and the delegates | `00-README` §7.1, §8 step 22 | N01-T03, N11-T05 |
| `WakelockController` gateway + fake | the seventh of `12 §4.2`'s seven fakes | N29-T04 |
| `.github/pull_request_template.md` | `00-README` §7.4 | N01-T07 |
| `ios/*.storekit` | `00-README` §7.1 | N30-T07 |
| `README.md`'s `sqlite3` build-hook note | decision-record §3.4 #3, `13 §1.3` | N02-T01 |
| `accessibility_tools` wiring | decision #100 | N11-T05 |
| `assets/content/` — the ~40 authored terms | `R66`; N07 seeds `vocab_terms` from it | N06-T11 |
| Fixture regeneration after reminders exist | critique S10 | N24-T08 |
| §12.1's schema-JSON half | decision #52 | N07-T08 |
| `validate_skills.py` / `validate_epics.py` in `make check` | `CLAUDE.md`'s five project commands | N01-T05 |
| The calendar ledger and its red-until-recorded test | critique §2 | N00-T06 |
| The ziplock-bag capacitance test | spec §17 item 4 | N00-T08 |
| Store accounts, Apple SBP, price, territories | `13 §10.2`, spec §14 | N00-T09 |
| Lambing ease 5 vs 6 | spec §17, `R44` — *decide before any data exists* | N00-T04 |
| In-app PDF printing and the voice-note cap | dependency-shaped; expire when the pubspec closes | N00-T02 |

---

## 3. Sequencing

### 3.1 The dependency graph, as built

240 tasks · **264 dependency edges** · 58 cross-epic · 22 long-range (skipping at least one epic) · **one
root**, `N00-T01`. Every edge points backwards: the checker refuses a `Depends on` id that lands later
(`depends.forward`), and the tree is clean.

The 22 long-range edges are the ones worth reading, because they are where the plan's real constraints
live rather than its narrative order:

```
N02-T01 → N00-T03    G0 needs in_app_purchase in the pubspec
N14-T01 → N06-T10    createEwe consults FreeTierPolicy from its first commit
N14-T01 → N07-T03    …and writes the ewes table
N14-T02 → N07-T04    beginLambing writes the lambing cluster
N15-T01 → N07-T06    MediaStore is held by the relative-path CHECK
N16-T02a → N14-T06   the sixth tap extends the five-tap budget
N19-T01 → N07-T05    the pen index refuses the second occupancy, not Dart
N20-T01 → N05-T02    the clear date is computed by settled arithmetic
N20-T01 → N07-T05    …and stored in a child table with no DEFAULT
N20-T02 → N05-T01    the control cannot construct a period any other way
N21-T08 → N12-T02    the banner writes app_settings through SettingsRepository
N23-T05 → N13-T07    the fixtures replace the seed helpers in the matrix
N24-T04 → N14-T02    reminder rows are written inside the lambing transaction
N24-T04 → N20-T01    …and inside the treatment transaction
N27-T03 → N14-T02    ewe_summaries is maintained inside the lambing write
N27-T03 → N18-T01    …and inside the foster write
N30-T04 → N06-T10    the entitlement source feeds the existing policy
N30-T04 → N14-T01    …into the verb that has consulted it since N14
N31-T01 → N02-T01    expected_permissions.txt comes from the G0 record
N31-T01 → N02-T02    …and from the ruling G0 produced
N33-T01 → N13-T07    the matrix reaches 14 variants from the one born in N13
N33-T01 → N24-T08    …against the regenerated fixtures
```

### 3.2 Forward references — the eleven the critique found, and where each is now closed

Every one is closed **in the built backlog**, not merely acknowledged.

| # | Forward reference | Closed by |
|---|---|---|
| **S1** | `test/support/harness.dart` built in E09 against seven gateways and thirteen screens that do not exist | **N12-T05** builds `pumpApp`, `Device` and `seeds.dart` only. Each fake lands with its gateway and joins the override list in the same commit: N15-T01/T02/T03, N21-T06, N24-T02, N29-T04, N30-T01 |
| **S2** | `routes.dart` declares twelve push helpers for eleven absent screens | **N13-T01** lands thirteen names and **one** helper; every screen epic adds its own. The 13/12 assertion is N33 |
| **S3** | The matrix is created in E10, its fixture arrives in E19 | **N13-T07** seeds the matrix from `seeds.dart`; **N23-T05** switches it to `restoreFixture` and is the task that proves the fixture loads |
| **S4** | `tap_budget_test` taps a Lambing Entry key P8 abolished | **N14-T06** asserts five taps to the committed row; **N16-T02a** rules P8 against `07 §5.4` and `12 §10.1` and lands the sixth tap as the first tally stroke |
| **S5** | `FreeTierPolicy` wired sixteen epics after the verb it gates | **N06-T10** writes the policy; **N14-T01** takes `EntryContext` from its first commit; **N30-T04** supplies only the entitlement source |
| **S6** | The export banner writes `app_settings`, but `SettingsRepository` is E26 | **N12-T02** pulls the repository forward; **N21-T08** depends on it |
| **S7** | Two E08 gates iterate a variant table from E10 | **N09-T08** lands only the gates that can honestly run; the sweeps are **N33-T02** and **N33-T03** |
| **S8** | `copy.*` gate rules in E02, their source of truth in E05 | **N03-T06** lands vocabulary rules only and says so in the source; **N06-T09** adds `copy.vet_advice` and `copy.disclaimer_retyped` in the commit that creates their types |
| **S9** | `ewe_summaries` written in E23 into a repository merged in E11 | **N27-T03** keeps the placement and **names the two repositories it re-opens**, so review reads them in irreversibility order |
| **S10** | Fixtures generated before reminders have a writer | **N24-T08** regenerates and re-commits both |
| **S11** | No task creates `android/` or `ios/` | **N00-T01** runs `flutter create` — one epic earlier than the critique proposed, for the reason in §5 |

### 3.3 Does every epic leave `main` green?

Checked epic by epic. Two need a stated answer rather than a yes:

- **N07 (the schema).** T01–T07 each end in `build_runner build` only, so the tree compiles at every
  commit; `make gen` in full — which writes the snapshot — runs once, alone, in T08. The epic is one
  pull request and is reviewed as one diff. This is the stated exception, and it is in the epic file.
- **N00-T06 (the calendar ledger).** Its test is **deliberately red** until N00-T07/T08/T09 record their
  outcomes, and it is tagged `calendar` and excluded from the blocking set until N32. That is the
  mechanism, not a leak: a commitment nothing fails over is not a commitment. It is stated in the task's
  Verification block.

Everything else: each epic ends on a task whose Definition of Done includes `make check` and `make test`
green, and no epic ends on a screen that throws or a schema that does not open.

---

## 4. What the checker refuses

`tool/validate_epics.py` — Python 3 standard library only, no dependencies, wired into `make check` by
N01-T05. Thresholds and the 24-skill list are constants at the top of the file.

| Rule id | Refuses |
|---|---|
| `epic.no_epic_md` | an epic directory with no `epic.md` |
| `epic.dirname`, `task.filename`, `task.title` | a file whose name or heading does not carry its id |
| `task.section_missing` | any of the ten required sections missing |
| `tdd.no_anchor`, `tdd.anchor_path`, `tdd.anchor_name`, `tdd.anchor_why` | a TDD section with no named first failing test — a real path, a property-shaped name, and why it is red **today** |
| `tdd.incomplete` | a TDD section with no Green or no Refactor step |
| `close.no_simplify` | a task that does not run `/simplify` before the commit |
| `close.no_code_review`, `close.no_shed_code_review` | a task that does not run each reviewer (see R1, §7) |
| `close.no_commit`, `close.order` | a close-out that does not end in a commit, or that simplifies afterwards |
| `skill.no_table`, `skill.count`, `skill.too_many_auto`, `skill.no_reason` | a missing skills table, more than three skills, more than two auto-firing, or a skill with no reason |
| `skill.unknown`, `skill.unknown_command` | **a skill name that is not one of the 24** — in the table *or anywhere in the prose*, including as a `/command` |
| `dod.too_thin` | fewer than three checkable Definition-of-Done items |
| `verify.no_block`, `verify.empty` | a Verification section with no runnable command |
| `task.thin` | a "why this task exists" under 25 words |
| `epic.dangling_task` | an `epic.md` referencing a task with no file |
| `task.unreferenced` | a task file its own `epic.md` does not reference |
| `epic.task_count` | fewer than 2 or more than 12 tasks in one pull request |
| `depends.unknown` | a `Depends on` id that exists nowhere in the backlog |
| `depends.forward` | a `Depends on` id that lands **later** — epics are sequential and one PR each |
| `depends.self` | a task depending on itself |

**Every rule has been watched to fire.** Planted on a scratch copy, one at a time:

```
== plant 1: invented skill name ==            [skill.unknown] — 2
== plant 2: forward + unknown dependency ==   [depends.forward] — 1
                                              [depends.unknown] — 1
== plant 3: drop /simplify and the DoD ==     [close.no_simplify] — 1
                                              [task.section_missing] — 1
== plant 4: orphan file, ghost reference,     [epic.dangling_task] — 1
            epic.md renamed to README.md ==   [epic.no_epic_md] — 1
                                              [task.filename] — 1
                                              [task.unreferenced] — 4
== plant 5: drop both reviewers ==            [close.no_code_review] — 1
                                              [close.no_shed_code_review] — 1
== exit code with violations ==               exit=1
```

Plant 3 found a real weakness in the checker itself: the R1 note at the foot of every task file mentions
`/simplify`, so a substring search over the whole section passed even with the step deleted. The check
now strips blockquote lines before looking. That is the check getting stronger, not the files getting
easier.

### 4.1 The 24 defects the checker found in these files, all fixed at source

| Rule | Count | Fix |
|---|---:|---|
| `tdd.anchor_why` | 15 | Reasons like *"nothing writes CSV."* replaced with the specific failure — e.g. *"nothing writes CSV, so the first export would reach for a package or for string interpolation, and neither survives a field containing a quote and a newline."* |
| `task.thin` | 7 | Seven "why this task exists" sections under the floor, expanded with the consequence of getting the task wrong |
| `tdd.no_anchor` | 1 | A test name written with double quotes (legal Dart, because the name contains an apostrophe) that the parser did not accept — parser widened to both string forms |
| `skill.unknown_command` | 1 | `<appSupport>/media/YYYY/MM/` read as an invocation of a skill called `/media` — the slash-command pattern now excludes path segments |

No threshold was lowered and no check was removed.

---

## 5. Two defects this audit found that the critique did not

Both are the same class as the critique's eleven: a task scheduled before the thing it needs exists.

### S12 · G0 was still scheduled before the platform folders existed

The critique moved G0 to N02 and put `flutter create` in N01-T01 — but its own §2 says G0 needs *"an
`android/` folder"* and `flutter build appbundle --release`. With the project created in N01-T01 that is
fine; the defect is narrower and worse: **`00-PLAN.md`'s E01-T01 is a bare `mkdir`**, so in the
uncorrected plan G0 had nothing to build even after being moved. Closed by making the project creation
the **first commit in the repository** (N00-T01), which also closes S13.

### S13 · Eight N00 tasks named a failing Dart test before a Dart test runner existed

`00-PLAN-CRITIQUE.md` §11.3 gives N00-T01 the anchor `test/policy/toolchain_pin_test.dart` and N00-T05…T08
the anchor `test/policy/calendar_commitments_test.dart`. Both are correct anchors and neither could be
run: at that point in the corrected plan there is no `pubspec.yaml`, no `flutter_test`, and no
`flutter test` command. The rule *"watch it fail for the right reason"* cannot be satisfied by a test
that cannot be executed at all.

**Closed by** making N00-T01 `flutter create` + the `.fvmrc` pin + the first policy test, and moving the
tree pruning and `.gitignore` to N01-T01. Every anchor in the backlog is now runnable in the task that
names it. This is the one place the built backlog deliberately departs from the critique's ordering, and
it is recorded in N00's epic file.

### And one numbering correction

`00-PLAN-CRITIQUE.md` §11.3's anchors for N23 (`N23-T06`, `N23-T10`) were carried over from E19's
ten-task numbering and do not fit the five-plus-seven split it proposes in §3. The **anchors are kept** —
`restoreFixture loads flock_400_3seasons.json` and the export→import→export equality — at **N23-T05** and
**N23-T07**. `N16-T02a` is kept exactly as the critique constructs it, because it is a genuine insertion
and the id is load-bearing in three documents.

---

## 6. The run

`python3 tool/validate_epics.py`, on the tree as committed:

```
Shed Book backlog validation
========================================================================
epics: 35   tasks: 240   skills known: 24

  N00   9 tasks
  N01   7 tasks
  N02   3 tasks
  N03   7 tasks
  N04   8 tasks
  N05   5 tasks
  N06  11 tasks
  N07   8 tasks
  N08   7 tasks
  N09   9 tasks
  N10   8 tasks
  N11   9 tasks
  N12   5 tasks
  N13   7 tasks
  N14   7 tasks
  N15   6 tasks
  N16  10 tasks
  N17   5 tasks
  N18   5 tasks
  N19   7 tasks
  N20   7 tasks
  N21   8 tasks
  N22   5 tasks
  N23   7 tasks
  N24   8 tasks
  N25   6 tasks
  N26   7 tasks
  N27   7 tasks
  N28   6 tasks
  N29   8 tasks
  N30   8 tasks
  N31   4 tasks
  N32   3 tasks
  N33   9 tasks
  N34   4 tasks

------------------------------------------------------------------------
SUMMARY: 35 epics, 240 tasks, 0 failures, 0 warnings — PASS
```

`echo $?` → `0`.

---

## 7. Divergences and open rulings

| # | Question | What the built backlog does | Why |
|---|---|---|---|
| **R1** | `/code-review` or `/shed-code-review`? | **Both**, in that order, in every task file, and both required by the checker | The owner's delivery workflow names `/code-review`; `CLAUDE.md` line 12 and its runbook table mandate `/shed-code-review`. Neither authority can be silently dropped by an auditor. Reversing R1 is one constant in `tool/validate_epics.py` (`REQUIRE_BUNDLED_CODE_REVIEW`) and one line deleted from 240 files |
| **R2** | E-numbering or N-numbering? | **N00–N34**, the critique's corrected re-cut | `00-PLAN.md` §12 item 1 says fix the plan first, and the critique's §11.1 is the fixed plan. Renumbering 240 files later is worse than deciding now |
| **R5** | `epic.md` or `README.md` for the epic file? | **`epic.md`** | The checker's brief names `epic.md`; `00-AUDIT-template.md` §6 links `./README.md`. One of the two documents needs a one-line edit — the files are consistent either way and renaming is `git mv` × 35 |
| **R6** | Task file naming | **`<TASK-ID>-<slug>.md`**, not `task-NN-<slug>.md` | A `Depends on` id resolves to a file mechanically, which is what makes `depends.unknown` and `depends.forward` cheap to check |

---

## 8. What remains

Honest list. None of it is a coverage gap; all of it is work this audit could not do from the documents.

1. **The task files are written, not executed.** Every anchor test is named and argued; none has been run,
   because there is no Dart toolchain in this environment and no code exists yet. The first real test of
   this backlog is N00-T01.
2. **`00-PLAN.md` still describes 31 epics E00–E30.** The built backlog is the critique's 35. The index
   now carries a status banner pointing at the critique, but the two documents disagree on numbering
   until R2 is confirmed and the plan is renumbered.
3. **Six of the seven calendar rows are undated**, by construction — that is N00-T06's test being red on
   purpose. They are commitments, and only the owner can close them.
4. **The `Sources` table is per-epic, not per-task.** `00-AUDIT-template.md` §6 wants document, section
   and what-it-binds per task. Every task carries its epic's three governing documents; a task that binds
   a fourth names it in §1 instead. Tightening this is 240 small edits and real value on the schema and
   withdrawal epics.
5. **`What you build` is a file list on 12 tasks and a directive on the other 228.** Where the file list
   was knowable from `CONVENTIONS §1` and `00-README` §8 it is written out; where writing it would have
   meant inventing paths, the task points at §8's order instead. Inventing a path in a task file is worse
   than omitting it — the developer types it and creates a file in the wrong layer.
6. **Four rulings are scheduled but not made:** P3 (N13-T01), P7 (N09-T05), P9 (N33-T03), P10 (N09-T09).
   P1 (N00-T05), P8 (N16-T02a) and P14 (N11-T04) are also scheduled. Each has a task, an anchor and a
   named losing document — but a scheduled ruling is not a ruling.
7. **The 240 files are generated from one authored data table**, so a systematic error in the template
   would be systematic across all of them. The checker holds the shape; it cannot hold the judgement.

---

## 9. Verdict

**The backlog now exists, covers everything the spec and the doc set require, and is mechanically
checkable — and it was none of those things when this audit started.**

- **Coverage: complete.** All 12 screens plus Note Search, all 10 §7 feature groups, all 23 tables behind
  the 9 spec entities, all five §12 rules at the level `CLAUDE.md` demands, G0–G5, six CI workflows,
  export, backup, **restore**, `tool/seed.dart`, reminders, monetization and release each have at least
  one task, named in §2. Seventeen items that had no owner in `00-PLAN.md` now do, including the
  component inventory — the largest hole — and the `test` CI job.
- **Sequencing: sound.** 264 dependency edges, all backward, one root, no forward reference. The
  critique's eleven defects are closed in the files rather than in prose, and two more (S12, S13) were
  found and closed here.
- **The checker: real.** Eleven classes of defect, every rule watched to fire on a planted violation, 24
  genuine defects found in these very files and fixed at source. Exit 0, with no check weakened — and one
  check made stronger when a plant exposed it.

The thing I would not claim: **this is a plan, and plans are wrong in ways only the first commit
reveals.** The riskiest single judgement in it is S13's — moving `flutter create` into N00 to make every
anchor runnable. It is right, and it means the first commit of this project is larger than a decision
record, which is exactly what `00-PLAN.md` set out to avoid.

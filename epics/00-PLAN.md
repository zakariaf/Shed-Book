# Shed Book — the delivery backlog

**31 epics · 227 tasks · one pull request per epic · one commit per task · every task TDD.**

> **Status — read this before working from §3.** This file is the **epic and task index**: one line per
> task, 227 lines. It is **not** the backlog a developer builds from. The **227 task files do not exist
> yet** — nothing under `epics/` but this file and `00-PLAN-CRITIQUE.md`. Until a task file exists,
> §1's rules below are *requirements on the task file that must be written*, not descriptions of a row
> in §3. A one-line row cannot carry a first failing test, a skills table, a definition of done or a
> verification block, and none of §3's rows do.
>
> The binding shape of a task file, the section order, the verified skill whitelist and the per-file
> conformance evidence are in **`00-AUDIT-template.md`**. The corrected epic numbering, the 64 test
> anchors and the per-epic skill mapping are in **`00-PLAN-CRITIQUE.md`** §11.1, §11.3 and §11.4 — and
> that document supersedes this one wherever the two disagree.
>
> **Technical-accuracy corrections applied in place** (`00-AUDIT-accuracy.md` §3): every line below
> carrying **`[audit]`** was factually wrong against `CONVENTIONS.md`, `00-tech-decisions.md`,
> `08-platform-integration.md` or `docs/skills/02-build-manifest.md` §4.4 and has been corrected.
> Do not restore the earlier wording; each correction cites the ruling that governs it.

This plan is `docs/engineering/00-README.md` §9 — the thirteen-step build order — expanded into
pull-request-sized units. The order is not re-argued here, because §9 already argues it: **Quick Entry is
the product**, and **the schema cannot be changed later**, so the sequence front-loads the irreversible
and the invisible-when-wrong and reaches pixels late. What this plan adds is the **split**, because two
of §9's steps group four and five screens onto a single line and neither is one reviewable diff.

---

## 1. How the work runs

| Rule | Detail |
|---|---|
| **One PR per epic** | Branch from the merged `main`, land every task in the epic on that branch, open the PR, **wait for `gate` · `codegen` · `test` · `android` to pass**, merge, then start the next epic. Epics are strictly sequential; the next branch is never cut from an open one. |
| **One commit per task** | Where a task genuinely cannot be one commit, the task file says so and says why. `00-README` §7.4 names the only legitimate cases: a toolchain bump, a golden re-baseline and an `[exempt]` allowlist line each stand alone — and a schema change must **not** be split. |
| **Every task is TDD** | Red — write the failing test first and watch it fail *for the right reason*. Green — the minimum code that passes. Refactor — with the tests green. **Every task *file* names one specific first failing test — a path, a test name and the reason it is red today.** "Write tests for this" is not an anchor and does not satisfy the rule. §3's one-line rows do not carry anchors; `00-PLAN-CRITIQUE.md` §11.3 supplies 64 of them, covering 74 tasks, and the rest are written with their task file. |
| **Every task ends with `/simplify`, then `/shed-code-review`, then the commit** | Stated explicitly, as required steps, at the foot of every task file. **`/shed-code-review`, never the bundled `/code-review`** — `CLAUDE.md` mandates it by name, and it is the only reviewer that knows the read-by-irreversibility order and the never-waved-through list. It is run per task *and* over the whole branch before the PR is opened. |
| **Every task names its skills** | A **"Skills to load" table** in every task file: only the twenty-four skills that exist under `.claude/skills/`, one line each on why. An invented skill name is a defect — the developer types it and gets nothing. At most two auto-firing skills per intent (`CLAUDE.md`); a third appears only where the task genuinely spans a seam, and `shed-testing` is the usual third. §3's rows name no skill; `00-PLAN-CRITIQUE.md` §11.4 maps skills per epic and the task file narrows that to the task. |
| **Green `main`, always** | No epic may leave `main` red, and no epic ends with a screen that throws or a schema that does not open. An epic that would have to is split until it cannot. |

### Two things that are never their own epic

**Accessibility and the ARB run in parallel from day one** (`00-README` §9's closing note). They are
*authoring rules inside every UI task*: every interactive element ≥ 64 × 64 with a `semanticLabel` and a
widget key spelled `<screen>.<element>`, every heading a `headingLevel:`, every user-facing string in
`lib/l10n/app_en.arb` with a `description`, and every domain noun a placeholder fed by
`terminologyProvider`. There is no "add a11y" epic. What is deferred — deliberately, because it cannot
run until all fourteen pumpable variants exist — is a small set of **sweeps** in E28: semantics, tap
targets, the ARB completeness pass and Apple's Accessibility Nutrition Label per-screen sweep.

### The open conflicts this plan lands, and where

`docs/skills/02-build-manifest.md` §4.5 leaves six conflicts open. Five of them are decided inside a task
in this plan rather than by a skill on its own authority; the sixth is calendar-blocking:

| # | Conflict | Where it is ruled |
|---|---|---|
| **P1** | `struck` / `struck_at` on every table — **schema-irreversible** | **E00-T04**, before the freeze. It gates `shed-drift-schema` and `shed-export-and-restore` |
| **P3** | Navigation: `02`'s Navigator stack and twelve push helpers vs Indelible §7.17's *"no stack, no back button"* | E10-T01 |
| **P7** | 390 / 420 / 520 / 600 weights need `FontVariation`; `06 §5.2` records the Atkinson axis as 500–700 | E08-T05 |
| **P9** | Tap separation — `00-README` step 19's ≥ 16 pt vs Indelible §4.5's 8–12 px. An executable gate asserts one of them | E28-T03 |
| **P10** | Four haptics (`06`'s definition of done) vs five (Indelible §5.4); `HapticFeedback.successNotification()` unverified | E08-T09 |
| **P14** | `NightErrorPanel`'s `#0B0D0E` vs Indelible's `--page` `#0A0A0B`, on the **first painted frame** | E09-T04 |

---

## 2. The epic table

| # | Epic | §9 step | Depends on | PR scope | Demoable on merge |
|---|---|---|---|---|---|
| **E00** | Decisions, rulings and the toolchain | 0 | — | **S · no `lib/`.** `.fvmrc`, `pubspec.yaml`, `pubspec.lock`, four rulings folded into the decision record. Tiny diff, long lead time | `fvm flutter --version` prints 3.44.8 / 3.12.2, `pub get` resolves, the lockfile is committed, and P1 is ruled in writing |
| **E01** | The skeleton and the configs | 1 | E00 | **M · ~10 files.** The `CONVENTIONS` §1 tree, `analysis_options.yaml`, `build.yaml`, `l10n.yaml`, `dart_test.yaml`, `Makefile`, the `gate` job | `make check` is green on an empty tree; a PR shows a green `gate` job |
| **E02** | The gate | 1 | E01 | **L · ~700 lines, one file.** `tool/check_policy.dart`, its allowlist and its self-tests | `dart run tool/check_policy.dart` exits 0; plant any violation and it exits 1 naming the rule id — **every rule has been seen to fire** |
| **E03** | Domain: time and units | 2 (1 of 3) | E01 | **M · ~20 files, thick tests.** `lib/domain/time/`, `units/`, `lib/core/time/app_clock.dart` | A pure-Dart suite runs green, including DST-1…DST-5 against the 01:00–01:59 ambiguous hour, with no Flutter involved |
| **E04** | Domain: withdrawal | 2 (2 of 3) | E03 | **M · ~10 files. The highest-stakes PR in the project** | The 167-hour spring-forward regression passes, and a withdrawal period is unconstructible except through `WithdrawalDays.asEnteredByUser` |
| **E05** | Domain: statistics, warnings and policy | 2 (3 of 3) | E04 | **L · ~25 files.** ids, enums, `validation/`, `stats/`, `terminology/`, `policy/`, `free_tier.dart` | Every statistic computes with its verbatim definition, its caveats and its `notComputableReason`; `rankTagMatches('12')` ranks 12 → 128 → 412 |
| **E06** | The schema and the freeze | 3 (1 of 2) | E02, E05 | **XL · the largest PR in the project.** 23 tables, three `.drift` files, the seed, and **the first committed snapshot** | A real SQLite file opens with `STRICT`, refuses garbage, seeds a season nobody was asked about, and `drift_schemas/drift_schema_v1.json` is committed |
| **E07** | The migration harness | 3 (2 of 2) | E06 | **M · `test/drift/`, `migrations.dart`, the `codegen` job** | Every from→to pair runs `migrateAndValidate` with FTS5 present and zero rows; `make gen` produces no git diff in CI |
| **E08** | The design system foundation | 4 (1 of 2) | E01 | **L · ~20 files.** `lib/core/ui/` primitives, tokens, palettes, theme, type, `ShedTapTarget`, `test/design/` | `contrast_test.dart` recomputes every pair in all six palettes and holds 4.5:1 on text and 3:1 on rules and marks |
| **E09** | Bootstrap, errors and the DI root | 4 (2 of 2) | E06, E08 | **L · ~20 files incl. Android and iOS.** `main.dart`, `app.dart`, the error net, `LocalLog`, `providers.dart`, `pumpApp` | **The app launches on both platforms to a dark first frame with no white flash**, and a thrown widget renders the night panel, not red-on-yellow |
| **E10** | Quick Entry: the deck and the keypad | 5 (1 of 2) | E09 | **M · `lib/routing/`, `lib/features/quick_entry/` reads, `ShedKeypad`** | Type `12` on a real phone and 412 · 128 · 12 rank **in the same frame**, with no SQL round trip |
| **E11** | Quick Entry: the write path | 5 (2 of 2) | E10 | **M · the first two repositories, `feedback.dart`, the budgets. The product** | **Six taps from launch to a committed lambing**, asserted by `tap_budget_test.dart` |
| **E12** | Media and notes | 6 (1 of 5) | E11 | **M · `MediaStore`, `CameraService`, `VoiceRecorder`, `NoteRepository`, three fakes** | A photo and a voice note attach to a record, land under `<appSupport>/media/YYYY/MM/`, and survive an update because only the relative path was stored |
| **E13** | Lambing Entry | 6 (2 of 5) | E12 | **L · ~15 files.** The tally, ease, lambs, care events, the warning strip, provenance | You press one slab per lamb as it arrives and the row reads `TRIPLET (COUNTED)` — **nobody ever chose it** |
| **E14** | Lamb Card | 6 (3 of 5) | E13 | **M · sex, weight, death, pet lamb** | A birthweight typed on the app's own keypad, stored in canonical grams, shown in the user's unit |
| **E15** | Foster | 6 (4 of 5) | E13 | **M · `foster_repository.dart` and one screen** | **A reassignment in one tap** from the Foster screen, with both dams still on the page forever |
| **E16** | Pen Board | 6 (5 of 5) | E11 | **L · pens, occupancy, the tile, the one ticker** | The whiteboard, live, every tile ticking in the same frame on the minute boundary |
| **E17** | Treatments and withdrawal | 7 | E04, E16 | **L · ~15 files. Presentation over settled arithmetic** | **Repeat last treatment is two taps and does not copy the days** — it prints `DAYS NOT COPIED — READ THE BOTTLE` |
| **E18** | Export: CSV, PDF and share | 8 (1 of 2) | E17 | **L · `csv_writer.dart`, `pdf_writer.dart`, `share_service.dart`, the Export screen** | Three CSVs and two PDF volumes leave the phone through the share sheet, every struck row marked, every footer intact |
| **E19** | Backup, restore and the seed | 8 (2 of 2) | E18 | **XL · the most destructive code in the app** | `dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42` fills a phone **through the restore path**, and export → import → export is equal |
| **E20** | Reminders: rows and reconcile | 9 (1 of 2) | E19 | **L · `NotificationScheduler`, eight channels, `reconcile()`, the fake** `[audit]` | A 312-reminder flock projects exactly the soonest 56 and drops none of the rest, asserted against `FakeNotificationScheduler`'s recorded calls |
| **E21** | Reminders screen | 9 (2 of 2) | E20 | **M · one screen** | The screen states the discrepancy in one honest line with both numbers read from data |
| **E22** | Flock | 10 (1 of 5) | E19 | **M · the list, five filters, add a ewe** | 400 ewes filter to "currently penned" in daylight, at 11am, in the yard |
| **E23** | Ewe Card | 10 (2 of 5) | E22 | **L · the timeline, the summary line, observations** | *"3 seasons · avg 2.0 · assisted twice · prolapsed 2025"* — the reason the product exists in year two |
| **E24** | Season Summary | 10 (3 of 5) | E23 | **L · the statistics as rendered and the hand-rolled chart** | Every number carries its definition and its caveats; the spread chart uses no chart library and reads at 200% |
| **E25** | Note search | 10 (4 of 5) | E23 | **S · one debounced FTS5 route** | Type `watery` and every note that ever said it comes back, offline, in under a second |
| **E26** | Settings | 10 (5 of 5) | E24 | **L · units, terminology, season, appearance, the two honest deletes, diagnostics** | Rename *ewe* to *gimmer* and the whole app says gimmer; delete-everything says exactly what it will destroy first |
| **E27** | Monetization | 11 | E26 | **L · `PurchaseService`, entitlement, `FreeTierPolicy`, the two rows, the store artefacts** | One unlock buys it forever — and the widget test proves nothing about money renders on any of the five shed screens at any entitlement state |
| **E28** | Ship gates: goldens, the sweeps and the journeys | cross-cutting, before 12 | E27 | **L · ~900 lines of test**, eight PNGs (their own commit) | The **252-cell** matrix, the semantics gate, the tap-target gate and four integration journeys all run green |
| **E29** | Offline gates and platform artefacts | 12 (1 of 2) | E28 | **L · `android/`, `ios/`, `tool/assert_permissions.sh`, the `android` CI job** | **`[audit]`** `bundletool dump manifest` on a real release `.aab` shows **exactly the permission set G0 recorded** — `INTERNET` absent, and `ACCESS_NETWORK_STATE` present or absent **on G0's evidence, never on faith** (decision-record §3.3) |
| **E30** | Release engineering | 12 (2 of 2) | E29 | **M · signing, budgets, `release.yml`, `goldens.yml`, the checklist** | `git tag v1.0.0` produces a signed AAB, eight goldens and a symbols archive kept off the laptop |

S ≈ ≤ 6 files · M ≈ 7–14 files · L ≈ 15–25 files · XL ≈ 25+ files or an irreversible artefact.

---

## 3. The epics, task by task

### E00 — Decisions, rulings and the toolchain · §9 step 0

**Goal.** The five pre-commit decisions are closed, the two schema-irreversible rulings are made, the
dependency table is proved to resolve, and the two calendar-blocking items are booked. None of this is
code and all of it is unrecoverable later.

| Task | One line |
|---|---|
| E00-T01 | Pin Flutter 3.44.8 / Dart 3.12.2 through `.fvmrc`, with an assertion that fails on a floating channel |
| E00-T02 | Author `pubspec.yaml` from decision-record §5 verbatim and commit the resolved `pubspec.lock` as the evidence it resolves |
| E00-T03 | Rule the three schema-shaped open questions — `WithdrawalTarget.milk`, the temperature column, `Lambs.became_ewe` — before they expire at the freeze |
| E00-T04 | **Rule P1** — `struck` / `struck_at` on every table — and fold it into `CONVENTIONS.md` §6 and the decision record |
| E00-T05 | Book the field night and start recruiting twelve shepherds; record both where a test can see them |
| E00-T06 | Guard decision #5: no `tools:node="remove"` line may exist until G0 has been run against a real AAB |

### E01 — The skeleton and the configs · §9 step 1

**Goal.** The tree a developer `mkdir`s from, the four generator/lint/test configs, the `Makefile`, and a
blocking `gate` job. A gate is cheap on an empty tree and impossible to retrofit across twelve screens.

| Task | One line |
|---|---|
| E01-T01 | `mkdir` the `CONVENTIONS.md` §1 tree and write `.gitignore` from §7.2 |
| E01-T02 | `analysis_options.yaml` — `flutter_lints` 6.0.0 plus the explicit `strict-casts` / `strict-inference` / `strict-raw-types` block |
| E01-T03 | `build.yaml` and `l10n.yaml` — drift as the only generator, no banned build option, `en` only, generated l10n committed |
| E01-T04 | `dart_test.yaml` — the `ci-fast` and `ci-golden` presets, the `uk-zone` and `golden` tags, and randomisation off for `migration` |
| E01-T05 | The seven-target `Makefile`, cheapest failure first, where `goldens` verifies and only `goldens-update` re-baselines |
| E01-T06 | `.github/workflows/ci.yml` — the `gate` job, blocking, on every push and every pull request |

### E02 — The gate · §9 step 1

**Goal.** One script, one rule table, one allowlist, one exit code — layer rules, the network scan (G3),
the token and gesture rules, the vocabulary rules and the lockfile allowlist (G2) — with every rule
watched to fire once.

| Task | One line |
|---|---|
| E02-T01 | The script skeleton: the rule table shape, the file walk, the generated-file skip, the allowlist parser and the four `[exempt]` lines |
| E02-T02 | The eight layer rules plus `layer.sibling` and `layer.data_no_validation` |
| E02-T03 | The `net.*` rules — G3 — and the recorded reason a *"no `http` in `pubspec.lock`"* rule is unsatisfiable and must never be written |
| E02-T04 | G2 — the direct-dependency allowlist over `pubspec.lock`, with `dependencies` and `dev_dependencies` scanned separately |
| E02-T05 | The design rules: raw hexes, magic sizes, the whole gesture ban, `showSnackBar(`, `CircularProgressIndicator`, `showDialog(` |
| E02-T06 | The `time`, `db`, `rp3` and `copy` rules, including the banned-word list and the one-word-per-concept vocabulary |
| E02-T07 | Plant, watch, delete — prove each rule fires once — and wire the gate in as the `gate` job's first step |

### E03 — Domain: time and units · §9 step 2

**Goal.** Pure Dart, zero dependencies, the thickest test tier, and the code most likely to be wrong
invisibly. It compiles before Flutter is involved.

| Task | One line |
|---|---|
| E03-T01 | `Instant` — the extension type over UTC epoch millis, with ordering, arithmetic and no `Instant.now()` |
| E03-T02 | `LocalDate` — strict parse that throws, `plusDays`, `daysUntil`, `startOfDayLocal`, never derived from a partial |
| E03-T03 | `PartialDate` — a year, maybe a month, never silently widened to a full date |
| E03-T04 | `RecordedTime` and `TimeSource` — provenance as part of the value, with a `provenanceLabel` that can never be empty |
| E03-T05 | `appNow()` — the one wall-clock reader in the app, its single allowlist entry, and `checkLocalWallTimeExists` |
| E03-T06 | `Grams`, `WeightUnit` and `parseUserNumber`, which returns null on ambiguity rather than guessing |
| E03-T07 | `MilliCelsius` — canonical integer temperature, converted only at the display edge |
| E03-T08 | The `uk-zone` tier — `@Tags(['uk-zone'])`, `TZ=Europe/London`, the 01:00–01:59 ambiguous hour, failing loudly on a wrong zone |

### E04 — Domain: withdrawal · §9 step 2

**Goal.** The highest-stakes code in the app, written while it is still arithmetic with no screen
attached. A wrong withdrawal number puts meat into the food chain.

| Task | One line |
|---|---|
| E04-T01 | `sealed WithdrawalPeriod` with a private generative constructor and one entry point, `WithdrawalDays.asEnteredByUser` |
| E04-T02 | `clearDateFor` — ceil to the next local midnight of administration + N × 24 h, with the 167-hour spring-forward regression |
| E04-T03 | `WithdrawalStatus` and `computeWithdrawalStatus` — `ClearsOn` / `NoWithdrawal` / `WithdrawalUnknown` |
| E04-T04 | `test/policy/withdrawal_has_no_default_test.dart` — the type-and-source half of "never default a withdrawal" |
| E04-T05 | `clearDateDisagrees` — a warning computed from the stored inputs, shown and never applied |

### E05 — Domain: statistics, warnings and policy · §9 step 2

**Goal.** Ids, the enums that mirror stored keys, the validators that cannot fix anything, the eight
statistics with their verbatim definitions, terminology, the disclaimers, and the free-tier decision.

| Task | One line |
|---|---|
| E05-T01 | `ids.dart`, `BirthType` with `expectedLambCount` (null for `quintPlus`), `LambingEase`, `Sex`, `FosterOutcome` |
| E05-T02 | `Warning`, the eleven `WarningCode` members and `Reviewed<T>` — no writer, no `fix()`, nothing to persist into |
| E05-T03 | The three validator files — lambing, foster, treatment — plus `kPlausibleBirthWeight` |
| E05-T04 | `StatResult`, `LambCount`, `FlockDenominator`, `LambingPercentageChoice` and `SeasonCounts` |
| E05-T05 | Lambing percentage, average litter size and barren rate, each with its `notComputableReason` arms |
| E05-T06 | Assisted rate, losses by cause and by age, and the dense zero-filled lambing spread |
| E05-T07 | `rankTagMatches` / `TagIndexEntry`, and `timeSincePenned` / `isReadyToTurnOut`, both taking `now` as a parameter |
| E05-T08 | Terminology — `AnimalClass`, `TermLabel`, `Terminology`: a closed enum under a user-editable overlay |
| E05-T09 | `Disclaimers`, `ContentPolicy` and `ExportEnvelope`, with the content scan self-tested in both directions |
| E05-T10 | `free_tier.dart` — `EntryContext`, `CapDecision`, `RefusalReason`, `FreeTierPolicy.decide`, `isQuietHours` |

### E06 — The schema and the freeze · §9 step 3

**Goal.** Every table, every constraint, every index, the three `.drift` files, the first-run seed and
**the first committed schema snapshot**.

**Why this is one PR.** `00-README` §9 step 3 says it in one breath — *"every table, the first snapshot,
the from→to matrix"* — and `04` §1 makes the *first committed snapshot* the irreversible event. Splitting
the tables across PRs would either commit a snapshot twice or invent migration steps for a schema no
phone will ever hold, and those steps live in `schema_versions.dart` forever. This is the one place the
plan accepts a very large diff, and it is reviewed in the order `CODE-REVIEW-CHECKLIST.md` §3.1
prescribes. Only the last task runs `make gen` to completion.

| Task | One line |
|---|---|
| E06-T01 | `connection.dart` — `openConnection`, the seven pragmas in R13's order, the FTS5 assertion, and the in-memory test harness |
| E06-T02 | `database.dart`, `kSchemaVersion`, `AppDatabase`, `converters.dart`, `uid.dart`, and `mixin Identified` carrying P1's `struck` / `struck_at` |
| E06-T03 | `seasons`, `ewes`, `ewe_seasons` — and the **active-only** partial unique index on `tag` |
| E06-T04 | `lambings` and `lambs` — nullable `declared_birth_type`, the birth-dam immutability trigger, the `lambing_consistency` view |
| E06-T05 | `foster_events` and the `lamb_rearing` view — append-only, with the provenance quad |
| E06-T06 | `care_events` and `ewe_observations` — the exclusive-parent CHECK idiom, and checkbox state as `EXISTS` |
| E06-T07 | `pens`, `pen_occupancies`, `pen_occupancy_lambs` — the partial unique index `WHERE exited_at IS NULL` |
| E06-T08 | `treatments` and `treatment_withdrawals` — a child table where **no row means not recorded**, and no `DEFAULT` on `days` |
| E06-T09 | `reminders` and `reminder_rules` |
| E06-T10 | `notes` and `media_assets` — `occurred_at` distinct from `created_at`, the relative-path CHECK, `missing_since` |
| E06-T11 | `vocab_terms` and `terminology_overrides`, seeded with the ~40 authored keys |
| E06-T12 | `app_settings`, `entitlements`, `ewe_touches`, `ewe_summaries`, and `unknown_json` on all 21 restorable tables |
| E06-T13 | `search.drift`, `views.drift` and `queries.drift` — FTS5 present in v1 with zero real rows |
| E06-T14 | `seedFirstRun` in `onCreate`, then `make gen` and the first committed snapshot — **the freeze** |

### E07 — The migration harness · §9 step 3

**Goal.** The from→to matrix, the scoped data-integrity test, the loud downgrade, the FTS5 shadow-table
question answered in week one, and the CI job that makes a stale generated file impossible.

| Task | One line |
|---|---|
| E07-T01 | `migrations.dart` — the `stepByStep` scaffold with the five migration rules on it as a doc comment |
| E07-T02 | The from→to matrix: `SchemaVerifier.migrateAndValidate` on every pair, and `PRAGMA foreign_key_check` returning zero rows |
| E07-T03 | `testWithDataIntegrity`, scoped to the N-1→N pair and any step that rewrites a table |
| E07-T04 | The downgrade test — a newer file on an older build fails loudly and never runs |
| E07-T05 | FTS5 shadow tables under `SchemaVerifier` — the day-one unverified claim, checked and the answer written down |
| E07-T06 | The `codegen` CI job — regenerate, then `git diff --exit-code` over `lib/`, `drift_schemas/`, `test/drift/generated/` |
| E07-T07 | `_snapshotBeforeMigration` and `diagnostics_snapshot.dart` — `VACUUM INTO`, bounded, never rethrowing |

### E08 — The design system foundation · §9 step 4

**Goal.** Tokens, palettes, theme, type and targets from `indelible.md` only, plus the four executable
design gates. The other two directions do not appear.

| Task | One line |
|---|---|
| E08-T01 | `primitives.dart` — raw hexes and raw scales, importable only inside `lib/core/ui/`, with its two allowlist lines |
| E08-T02 | `tokens.dart` — one flat `ThemeExtension`, `ShedPalette`, `ShedPaletteId`, `context.tokens`, and a `lerp` that snaps |
| E08-T03 | `palettes.dart` — night, amber and deep red, each with a high-contrast variant, measured rather than chosen |
| E08-T04 | `theme.dart` — `buildShedTheme`, `ShedThemeSet`, and no code path that can produce a light theme |
| E08-T05 | **`[audit]`** Typography — the two voices, the variable font asset, the scale, the weight cap, tabular figures; **rules P7**; and lands **`02-build-manifest.md` §4.4 defect 2**: `--t-stamp` 14 px and `--t-head` 16 px sit under the 18 px floor, and the three stamps that are the *sole* carrier of their meaning — **`DEAD`**, **`AUTO-CAPTURED`** (the sole §12.5 provenance label) and **`DERIVED FROM N STROKES`** (the sole statement of the §12.4 claim) — are **not** exempt and must meet the floor. Every other stamp keeps the exemption |
| E08-T06 | `formatters.dart` — the one `package:intl` call site: `d MMM y`, 24-hour `HH:mm`, and never an all-numeric human date |
| E08-T07 | `ShedTapTarget` — a required `semanticLabel`, the 64 × 64 build, hit slop, and `Semantics(onTap:)` |
| E08-T08 | The executable gates: `wcag.dart`, `contrast_test`, `tap_target_test`, `semantics_gate_test`, `reduce_motion_test` |
| E08-T09 | `motion.dart`, the reduce-motion resolver and the haptic vocabulary; **rules P10** |

### E09 — Bootstrap, errors and the DI root · §9 step 4

**Goal.** `main()` awaits nothing, the first painted frame is the page colour, the error net is installed
before `runApp`, the database opens after the first frame, and `test/support/` can pump the app.

| Task | One line |
|---|---|
| E09-T01 | `ShedFailure` and its six variants, and `WriteOutcome` and its three — non-generic, no `Ok`, no `Error` |
| E09-T02 | `shedFailureFrom(Object)` — the only place a `SqliteException` becomes a `ShedFailure` |
| E09-T03 | `main.dart` — twenty lines, nothing awaited, both handlers installed before `runApp`, and no `runZonedGuarded` |
| E09-T04 | `NightErrorPanel` — the `ErrorWidget.builder` that bypasses `Theme` and carries its own `Directionality`; **rules P14** |
| E09-T05 | `app.dart` — `ShedBookApp` as a `ConsumerStatefulWidget`, the post-frame boot kick, and `ResumePolicy` |
| E09-T06 | No white flash — the four layers on Android and iOS, and the parity gate that proves it |
| E09-T07 | `LocalLog`, redaction, `attachTo`, `markCleanPause()` and `session.lock` dirty-resume detection |
| E09-T08 | `providers.dart` — `databaseProvider` and the DI graph, plus `settingsProvider`, `themeProvider`, `unitsProvider`, `terminologyProvider` |
| E09-T09 | `minuteTickProvider` — one boundary-aligned 60 s ticker yielding `Instant`, `autoDispose`, never `Timer.periodic` |
| E09-T10 | `WriteController` and `guard()` — the double-tap defence, refusing to run concurrently |
| E09-T11 | `test/support/` — `pumpApp`, the seven hand-written fakes, `kPumpableVariants` and the `Device` table |

### E10 — Quick Entry: the deck and the keypad · §9 step 5

**Goal.** The read half of the product's one screen, and every piece of machinery the other twelve screens
reuse.

| Task | One line |
|---|---|
| E10-T01 | `routes.dart` — thirteen `RouteNames`, twelve typed push helpers, the navigator key, Android back; **rules P3** |
| E10-T02 | `tagIndexProvider` — active animals only, feeding an in-memory ranked filter that updates in the same frame |
| E10-T03 | `quickEntryDeckProvider` — one statement, two buckets, read by the two strips through `.select` |
| E10-T04 | `ShedKeypad` — the only number-entry route in the app, no key ever disabled, with its semantics tree |
| E10-T05 | **`[audit]`** The Quick Entry shell — the ruled page, the madder spine, the margin cell, the bottom band, frame 1 with no data; and lands **`02-build-manifest.md` §4.4 defect 1**: `indelible.html:1138` puts the live row inside the scrolling `.stream`, so the open row can scroll away. **The live row is a fixed layer above the bottom band and cannot scroll** — the artefact is wrong and the corrected rule is what ships |
| E10-T06 | The two strips — penned ascending by `entered_at`, recents — with their empty copy authored into the ARB |
| E10-T07 | The overflow matrix seeded with `quick_entry`, its count derived from the variant list and never typed |

### E11 — Quick Entry: the write path · §9 step 5

**Goal.** Six taps to a committed lambing, no Save button, no draft, and a receipt that is the committed
row itself.

| Task | One line |
|---|---|
| E11-T01 | `FlockRepository.createEwe` and the `ewe_touches` write — create-on-the-fly never blocks an entry |
| E11-T02 | `LambingRepository.beginLambing` — returns an id and throws; the row exists **before** the route is pushed |
| E11-T03 | `quick_entry_write_controller` through `guard()`, with its double-tap test |
| E11-T04 | `feedback.dart` — `confirmSaved` / `showFailure` / `showCapRow`, where the receipt is the printed row and no file calls `showSnackBar(` |
| E11-T05 | Undo as a time-boxed strike in the row's own margin, the window stated in seconds, never surviving process death |
| E11-T06 | **`[audit]`** `test/features/tap_budget_test.dart` — **five** taps from unlock to a committed `beginLambing` row, on keyed finders. **Not six**: `12 §10.1`'s published sixth tap is `find.byKey(const Key('lambing_entry.birth_type.twin'))`, and **P8 abolished the birth-type chooser**. The sixth tap is the first tally stroke and it belongs to E13 (see `00-PLAN-CRITIQUE.md` S4, N14-T06 and N16-T02a) |
| E11-T07 | The no-monetization-on-a-shed-screen widget test, at every entitlement state |

### E12 — Media and notes · §9 step 6

**Goal.** The capture seams and the one storage rule that is irreversible: only relative paths are ever
written, and the database refuses anything else.

| Task | One line |
|---|---|
| E12-T01 | **`[audit]`** `MediaStore` — the media root, `newRelativePath`, `resolve`, `writeAtomically`, **the `flutter_image_compress` downscale (2048 px longest edge, JPEG q80, `keepExif: false`)**, and the relative-path rule. **R47** gives the downscale to `MediaStore`, not to `CameraService` |
| E12-T02 | **`[audit]`** `CameraService` over `image_picker` — `pickImage` and `retrieveLostData` on resume, and **nothing else**: it wraps exactly one plugin so the fake tests the real path (R9, R47). The capture flow is `CameraService.pick()` → `MediaStore` compresses and writes → `NoteRepository` inserts the `media_assets` row |
| E12-T03 | `VoiceRecorder` over `record` — AAC-LC `.m4a`, never opus, with `kVoiceNoteMaxSeconds` |
| E12-T04 | `NoteRepository` — `notes` and `media_assets` writes with the provenance quad and a real `occurred_at` |
| E12-T05 | Disk full at 3am — the write-ordering rule, and the failure mapping that keeps the record and loses only the file |
| E12-T06 | `ShedPhoto` — a captured photo is a ruled cell under a `ColorFiltered`, never a card and never a thumbnail grid |

### E13 — Lambing Entry · §9 step 6

**Goal.** The screen the shepherd is on while holding a lamb. Every field after the first tap is its own
committed write, and **birth type is counted, never chosen**.

| Task | One line |
|---|---|
| E13-T01 | `lambingEntryProvider` — one statement producing `LambingEntryData` for a `LambingId` |
| E13-T02 | The lamb tally — strokes with a true five-bar gate, birth type derived and labelled `(COUNTED)` |
| E13-T03 | `addLamb` — the second and last verb that returns an id and throws — and the lambs list |
| E13-T04 | Lambing ease 1–5 as the one surviving segmented choice, and `setEase` |
| E13-T05 | Care events as `EXISTS` — colostrum with volume and method, navel dip, stomach tube, warmed |
| E13-T06 | The warning strip — a declared type that contradicts the strokes prints a query mark and adjusts nothing |
| E13-T07 | `correctOccurredAt` and the provenance header, where an edited time prints both times |
| E13-T08 | Assistance detail, the presentation vocabulary, the free-text note, and the photo and voice-note attachments |
| E13-T09 | Screen composition, ARB strings, heading levels, the matrix variant and the empty-state row |

### E14 — Lamb Card · §9 step 6

**Goal.** One lamb's whole life on one page: sex, weight, dam, foster, death.

| Task | One line |
|---|---|
| E14-T01 | `lambCardProvider` — one statement producing `LambCardData`, with the current rearing dam read from the view |
| E14-T02 | Sex, and a birthweight typed on the app's own keypad, stored in canonical grams and shown in the user's unit |
| E14-T03 | Death — the date, a cause from the editable vocabulary, `stillborn` as its own bucket, and `deathBeforeBirth` |
| E14-T04 | Pet lamb / bottle status with a feeding count |
| E14-T05 | Screen composition, ARB, semantics, the matrix variant and the tap costs |

### E15 — Foster · §9 step 6

**Goal.** The flow most likely to be abandoned if it takes five taps.

| Task | One line |
|---|---|
| E15-T01 | `FosterRepository.recordFoster` and `FosterOutcome` — to a ewe, to a bottle, or removed unknown |
| E15-T02 | The one-tap reassignment, reusing the Quick Entry deck query rather than inventing a second one |
| E15-T03 | Undo as a compensating `FosterEvent` labelled *corrected* — `birth_dam` is immutable by trigger |
| E15-T04 | The `fosterToSelf` warning and the four rules this screen must not break |
| E15-T05 | Screen composition, ARB, the matrix variant and the one-tap budget test |

### E16 — Pen Board · §9 step 6

**Goal.** The digital whiteboard, glanceable from arm's length under a head torch, on the one ticker built
in E09.

| Task | One line |
|---|---|
| E16-T01 | `PenRepository.enterPen` / `exitPen(PenExitReason)` — the database refuses two ewes in pen 3 |
| E16-T02 | `penBoardProvider` and `PenTile` — the same projection Quick Entry's "in the pens" strip reads |
| E16-T03 | Lazy pen creation — the zero-pen board and its single 72 pt "Add a pen" tile |
| E16-T04 | Hours since penned off the one ticker, and a ready-to-turn-out threshold labelled as the user's own |
| E16-T05 | `ShedPenTile` — twelve ruled rows, five statuses, every state carrying two non-colour channels |
| E16-T06 | Turn out, move and mark-as-group in one tap, and the edited-entry marker on the tile |
| E16-T07 | Screen composition, the pen-board grid semantics tree, and the matrix variant |

### E17 — Treatments and withdrawal · §9 step 7

**Goal.** The highest-stakes screen in the app, over arithmetic settled in E04.

| Task | One line |
|---|---|
| E17-T01 | `TreatmentRepository.recordTreatment` and its `treatment_withdrawals` child rows, meat and milk |
| E17-T02 | The withdrawal entry control — `YOUR ENTRY`, no default, no placeholder, no prefill, with the caveat above it |
| E17-T03 | The clear date computed once at write time and stored, and `ClearsOn` rendered as a day tally |
| E17-T04 | Repeat last treatment — product, dose, route and batch copied; days blank and stamped `DAYS NOT COPIED — READ THE BOTTLE` |
| E17-T05 | `voidTreatment` — a soft void the medicine book shows, because a treatment may already have been printed |
| E17-T06 | `treatmentsProvider(TreatmentMode)`, the countdowns segment and the `clearDateDisagrees` badge |
| E17-T07 | Screen composition, the §12.1 / §12.3 / §12.5 disclosures, the matrix variant and the two-tap repeat budget |

### E18 — Export: CSV, PDF and share · §9 step 8

**Goal.** The only backup this product has, and the only route records leave the phone by.

| Task | One line |
|---|---|
| E18-T01 | `CsvWriter` — hand-rolled RFC 4180, the quoting rules, UTF-8, the line ending, the formula-injection guard |
| E18-T02 | The three shapes and their verbatim header rows, with every struck row included and marked |
| E18-T03 | The disclaimer trailers — referenced from `Disclaimers`, never re-typed, proved by a test that greps the source |
| E18-T04 | `pdf_writer.dart` — the one builder, the mandatory embedded TTF, the page furniture |
| E18-T05 | The flock book in two volumes and the medicine record, built off the UI isolate and split at the row cap |
| E18-T06 | `ShareService` — delivery through the share sheet and nowhere else, always a file path |
| E18-T07 | `ExportRepository`, `exportCountsProvider` and the Export screen with its honest wording |
| E18-T08 | The end-of-day export banner — once per local civil day, never mid-entry, dismissible for the season (matrix variant 14) |

### E19 — Backup, restore and the seed · §9 step 8

**Goal.** Restore must exist before the seed can route through it, and the seed is what makes 400-ewe
profiling, the matrix, the goldens and the at-cap tests possible at all.

| Task | One line |
|---|---|
| E19-T01 | `backup_format.dart` — `BackupHeader` and the canonical encoder, with `_disclaimer` as the first key |
| E19-T02 | `writeBackup` — every restorable table including `vocab_terms`, the four exclusions named, and no base64 |
| E19-T03 | Forward compatibility — `unknown_json` round-trips, and a backup from a higher schema is refused clearly |
| E19-T04 | The checksum and how the file is written, described without the words *verified* or *secure* |
| E19-T05 | File import through `file_selector`, with the magic bytes validated by us |
| E19-T06 | `RestoreService` — a new file beside the live one, validated, swapped, reopened, plus `completeInterruptedRestore` |
| E19-T07 | The restore confirmation that states plainly what will be destroyed and requires two steps |
| E19-T08 | `MediaSweeper` — both directions, and when the sweeps run |
| E19-T09 | `tool/seed.dart` writing its demo database **through the restore path**, plus the two committed fixtures |
| E19-T10 | The export → import → export equality property, as a test |

### E20 — Reminders: rows and reconcile · §9 step 9

**Goal.** The reminder row is a durable fact written in the same transaction as the event; the OS list is a
rebuildable projection of the soonest 56 or 200.

| Task | One line |
|---|---|
| E20-T01 | `ReminderBudget.forPlatform()` — 56 on iOS, 200 on Android, and the flock that breaks the naive design |
| E20-T02 | `NotificationScheduler` — the seam, the app's only `package:timezone` call site, and its hand-written fake |
| E20-T03 | **`[audit]`** The **eight** Android channels — the channel id is byte-identical to `reminders.kind`, which is 03 §5.10's eight strings (**R49**; decision #65's six names are superseded and `turnout` / `dose` / `withdrawal` are banned channel ids) — frozen at release, plus notification ids and payloads |
| E20-T04 | `ReminderRepository`, and reminder rows written **inside** the lambing and treatment transactions |
| E20-T05 | `ReminderReconciler.reconcile()` — idempotent, debounced, called from exactly four places, never on a write path |
| E20-T06 | `POST_NOTIFICATIONS` at the first reminder and never at launch; `SCHEDULE_EXACT_ALARM` only; reboot and DST |
| E20-T07 | Handling a tap — route to the record, then re-reconcile |

### E21 — Reminders screen · §9 step 9

**Goal.** Due today, overdue, upcoming — and the screen that tells the truth about the gap between the
app's list and the phone's.

| Task | One line |
|---|---|
| E21-T01 | `remindersProvider` and `RemindersView` — one statement, three groups, day boundaries off the ticker |
| E21-T02 | The honest windowed line, with both numbers read from data and never a hard-coded 56 |
| E21-T03 | Completing a reminder writes the domain fact — the tap that ticks colostrum writes the `CareEvent` |
| E21-T04 | Mute as a strike, and nothing that nags twice |
| E21-T05 | Reminder intervals as `reminder_rules`, user-configurable, with the free-tier reminder question recorded |
| E21-T06 | Screen composition, ARB, the matrix variant and an empty state that explains where reminders come from |

### E22 — Flock · §9 step 10

**Goal.** The daylight screen: find any animal, filter the flock by anything, add a ewe.

| Task | One line |
|---|---|
| E22-T01 | `flockListProvider` and `FlockRow` — one statement, with the search box reusing `rankTagMatches` |
| E22-T02 | The five filters, and a filtered-empty state whose copy is not the empty state's |
| E22-T03 | The 88 px ewe row, with the §12.4 warning badge and the culled-tag marker |
| E22-T04 | Add a ewe from the bottom bar, through the same gated `createEwe` verb Quick Entry uses |
| E22-T05 | Screen composition, ARB, headings, the matrix variant and the tap costs |

### E23 — Ewe Card · §9 step 10

**Goal.** The retention feature. In year two, *"what did 412 do last year?"* takes one second. Not filler.

| Task | One line |
|---|---|
| E23-T01 | `eweTimelineProvider` — one statement with the fan-in done in SQL, producing `TimelineRow` |
| E23-T02 | The one-line summary assembled in Dart from `ewe_summaries` counts, never from a string frozen in the database |
| E23-T03 | `ewe_summaries` rebuilt inside the writes that invalidate it |
| E23-T04 | Timeline rows — every event with its provenance label, every withdrawal with "as entered by you" |
| E23-T05 | *"There was an earlier 412"* — the disclosure a reused tag requires |
| E23-T06 | The card's actions, including `EweObservations` writes from the seeded vocabulary |
| E23-T07 | Screen composition and a real heading hierarchy, so a screen reader jumps straight to the summary line |

### E24 — Season Summary · §9 step 10

**Goal.** Statistics that carry their own definitions, and one hand-rolled chart.

| Task | One line |
|---|---|
| E24-T01 | `SeasonRepository.watchSeasonCounts` — `customSelect` with an explicit `readsFrom:`, never `groupBy` in a Dart view |
| E24-T02 | The statistics as rendered — each with its verbatim definition, its numerator and denominator, and its caveats |
| E24-T03 | `watchSpread` — dense, zero-filled, grouped by the denormalised local civil date |
| E24-T04 | The hand-rolled `CustomPainter` spread chart and its `semanticsBuilder` — no axis, legend, tooltip, colour or animation |
| E24-T05 | Comparison against previous seasons, once they exist |
| E24-T06 | Screen composition, the three data shapes as states, the matrix variant and the empty season |

### E25 — Note search · §9 step 10

**Goal.** The thirteenth route: full-text offline search across every note.

| Task | One line |
|---|---|
| E25-T01 | `noteSearchProvider` — an autoDispose family over FTS5 with a 200 ms debounce |
| E25-T02 | The three distinct empty strings, because "no notes yet" and "no match" are different facts |
| E25-T03 | `SearchHit` rendering and navigation to the record the note belongs to |
| E25-T04 | The route, screen composition, ARB and matrix variant 13 |

### E26 — Settings · §9 step 10

**Goal.** The settings that actually matter, and the only two honest deletes in the app.

| Task | One line |
|---|---|
| E26-T01 | `SettingsRepository`, and one parameterised test that every setting persists and re-reads |
| E26-T02 | Units — kg / lb and °C / °F — converted only at the display edge, never in storage |
| E26-T03 | Terminology editing through `terminology_overrides`, with no domain noun baked into any message |
| E26-T04 | Palette, high contrast, the left-handed mirror, and the default-off wakelock with its 30-minute expiry |
| E26-T05 | Season start date, season switching and `SeasonRepository.startSeason` |
| E26-T06 | Delete a season and delete everything — the only `canPop: false` flow, and the only two honest deletes |
| E26-T07 | Diagnostics — the redacted log, the `VACUUM INTO` snapshot, and About with its §12.3 wording |
| E26-T08 | Screen composition, the deliberate friction, ARB and the matrix variant |

### E27 — Monetization · §9 step 11

**Goal.** One non-consumable unlock. It can be last precisely because nothing on the shed path branches on
`unlocked`.

| Task | One line |
|---|---|
| E27-T01 | `PurchaseService` — the store seam, `kUnlockProductId`, `PurchaseSignal`, `StoreUnreachable`, and its fake |
| E27-T02 | `EntitlementRepository`, the entitlement row and its three rules |
| E27-T03 | `UnlockController` and `UnlockState`'s four variants — purchase, restore, double taps, and why `pending` is not one |
| E27-T04 | `FreeTierPolicy` wired into the only two gated verbs, `createEwe` and `startSeason`, mapping to `WriteRefused` |
| E27-T05 | The two static upgrade rows and the four hard constraints, plus `showCapRow` |
| E27-T06 | The price read from `ProductDetails.price` — never a literal, anywhere, including in assets |
| E27-T07 | Store artefacts — `PrivacyInfo.xcprivacy`, Apple's genuine "Data Not Collected", Play's data-safety form |
| E27-T08 | The at-cap tests against `flock_15_at_cap.json`, and the shed-screen test extended to every entitlement state |

### E28 — Ship gates: goldens, the sweeps and the journeys · cross-cutting, before step 12

**Goal.** The assertions that can only run once every screen exists.

| Task | One line |
|---|---|
| E28-T01 | The overflow matrix at its final size — 14 variants × 3 devices × 3 text scales × 2 bold states, count derived not typed |
| E28-T02 | The semantics sweep across all thirteen routes — the house rule, `ensureSemantics`, and the canary that proves the gate can fail |
| E28-T03 | The tap-target sweep and the geometric gate; **rules P9**, the 16 pt / 8–12 px separation conflict |
| E28-T04 | The reachability assertions and colour-never-alone across every state the app shows |
| E28-T05 | The ARB completeness sweep — every user-facing string, every `description`, no domain noun as a literal |
| E28-T06 | Apple's Accessibility Nutrition Label declaration and the per-screen sweep behind it |
| E28-T07 | The eight goldens — real fonts loaded, the tolerant comparator, the PNGs in their own commit |
| E28-T08 | The four integration journeys and `make integration` — reported, never blocking |

### E29 — Offline gates and platform artefacts · §9 step 12

**Goal.** The offline claim becomes mechanically provable. **G0 first: until it has been run, G1 is
unwritten, not merely unimplemented.**

| Task | One line |
|---|---|
| E29-T01 | Run G0 against a real release AAB — record the merged manifest, the effective `minSdk`, and which library contributed what |
| E29-T02 | **`[audit]`** `android/expected_permissions.txt` — **the entries G0 recorded**, not a remembered eight — and the one `tools:node="remove"` line G0 proved. `INTERNET`'s removal is proven; `ACCESS_NETWORK_STATE`'s is not until G0 says so (§3.3) |
| E29-T03 | `tool/assert_permissions.sh` (G1), the blocking `android` CI job, and the G4 merger report archived |
| E29-T04 | **`[audit]`** Android build configuration — `targetSdk`/`compileSdk` **36**, Java **17**, AGP ≥ **8.12.1**, `desugar_jdk_libs` **2.1.4**, the two receivers, and an **explicit `minSdk` set to the effective value G0 read out of the merged manifest** (13 §3.1 expects 24; 08 §8.3's checklist forbids the literal being typed from memory or from a plugin changelog) |
| E29-T05 | iOS — the three usage strings, the appearance key, no ATS exception, and G5 as construction plus observation |
| E29-T06 | The application id and bundle id fixed once, in one commit, recorded where a human will find them |

### E30 — Release engineering · §9 step 12

**Goal.** Everything that needs a real device, a real release build and a signing key — plus the calendar
rule that outranks all of it between 1 February and 30 April.

| Task | One line |
|---|---|
| E30-T01 | Version name and build number rules, and `RELEASES.md` as the one place both are recorded |
| E30-T02 | Signing — the upload keystore, `key.properties` gitignored, Play App Signing, and the iOS half |
| E30-T03 | Obfuscation and the off-machine symbols archive, kept forever and never in git |
| E30-T04 | `release.yml` on tag `v*`, with `--analyze-size` and the app-size budget |
| E30-T05 | Startup measured on two real devices in profile mode, written into `docs/perf/measurements.md` |
| E30-T06 | `goldens.yml` — macOS, on a tag or manual dispatch only, never a per-PR gate |
| E30-T07 | Test tracks — TestFlight, and Play's twelve-tester fourteen-day closed test |
| E30-T08 | The seasonal release freeze and the manual pre-release checklist |

---

## 4. The critical path

Because every epic is one PR and PRs are sequential, **the critical path is the whole plan**:

```
E00 → E01 → E02 → E03 → E04 → E05 → E06 → E07 → E08 → E09 → E10 → E11 → E12 → E13 → E14 → E15
    → E16 → E17 → E18 → E19 → E20 → E21 → E22 → E23 → E24 → E25 → E26 → E27 → E28 → E29 → E30
```

That is the point, not a limitation: it prevents a schema epic and a screen epic being in flight at once,
which is the only way this codebase can produce a conflict nobody can resolve.

**Five hard gates inside the sequence:**

| Gate | Where | If it is not met |
|---|---|---|
| The five pre-commit decisions | E00 | Everything else can be revisited in week two. These cannot |
| **P1 is ruled** | E00-T04, before E06 | `struck` / `struck_at` on every table after the snapshot is a rebuild of every table that points at a shepherd's records |
| **The schema freeze** | E06-T14 | Anything `00-README` §5.2 marks schema-shaped that has not landed becomes a migration on somebody else's phone in April |
| **The write path and the receipt** | E11 | Every screen after it is a variation on machinery built here; getting it wrong once costs twelve screens |
| **G0 has been run** | E29-T01 | The offline gate in CI is *unwritten*. Removing `INTERNET` is proven; removing `ACCESS_NETWORK_STATE` is **not**, and must never be committed on faith |

## 5. What genuinely runs in parallel

Epics do not overlap — that is the delivery rule. Four things do, and three of them must start on day one.

1. **The field night.** `00-README` §5.2's item 1 is the highest-value unresolved item in the project and
   it closes three others. Every tap count in `07-screens.md` is a desk estimate until it happens. Book it
   in E00; it must land **before E10**, or Quick Entry is designed from forum posts.
2. **The ziplock-bag capacitance test.** A hardware question, answerable with a phone and a freezer bag at
   any point after E00. If it fails, decisions #100–#102 change and the interaction model is re-cut around
   volume-button shortcuts — which invalidates E10 onward. Do it during E01–E05, when being wrong costs a
   design change rather than a rewrite.
3. **Twelve shepherds and the closed track.** Play's twelve-tester / fourteen-day requirement starts
   *after* you have found twelve people, and recruiting them doubles as the answer to item 1. Start in
   E00; the track opens in E30-T07.
4. **Accessibility and the ARB.** An authoring rule in every UI task from E08 onward, with the four sweeps
   in E28 that cannot run until all fourteen variants exist.

### Reordering that is safe, and reordering that is not

| Safe | Why |
|---|---|
| E14 / E15 / E16 among themselves | Lamb Card, Foster and Pen Board share only machinery merged in E11 and E13 |
| E22 / E25 | Flock and note search touch different queries and share nothing but `rankTagMatches` |
| E24 before E23 | Season Summary needs `SeasonRepository` reads, not the Ewe Card |
| E30-T05 / E30-T06 | Both need a real device or a Mac; neither blocks the other |

| Never | Why |
|---|---|
| Anything that stores a fact before E06 | The schema is the freeze point; a table that arrives after the snapshot is a migration on a phone |
| E19 before E18 | `ExportRepository` and the envelope's `_disclaimer` land with the CSV writer |
| E19 before E28 | The seed and its two fixtures are the precondition for the matrix, the goldens and the at-cap tests |
| E20 before E11–E17 | `reconcile()` needs writes to reconcile *from* |
| E29-T03 before E29-T01 | G1 would assert a permission set G0 has not proved |

---

## 6. Coverage audit

| Required | Where it lands |
|---|---|
| **All 12 spec §9 screens** | Flock E22 · Ewe Card E23 · Quick Entry E10+E11 · Lambing Entry E13 · Lamb Card E14 · Foster E15 · Pen Board E16 · Treatments E17 · Reminders E21 · Season Summary E24 · Export E18 · Settings E26 |
| **The 13th route — note search** | E25; matrix variant 13 in E28-T01 |
| **§7.1 fast animal selection** | E05-T07 (`rankTagMatches`), E10-T02/T03/T04, E11-T01 (create-on-the-fly), E22-T01 |
| **§7.2 lambing entry** | E13 in full; media in E12 |
| **§7.3 lamb records and fostering** | E14 and E15; the schema in E06-T04/T05 |
| **§7.4 pen board** | E16 in full; the domain in E05-T07 |
| **§7.5 treatments and medicines** | E17 in full; the arithmetic in E04 |
| **§7.6 reminders** | E20 (rows, seam, reconcile) and E21 (screen) |
| **§7.7 history and recall** | E23 (the summary line), E22-T02 (filters), E25 (note search) |
| **§7.8 season summary** | E24; the statistics in E05-T04…T06 |
| **§7.9 export and backup** | E18 (CSV, PDF, share, banner) and E19 (JSON, **restore**, sweeps, seed) |
| **§7.10 settings** | E26 in full |
| **Every §10 entity** | E06-T03…T12 — all 23 tables, including the four the spec's model hides |
| **§12.1 never default a withdrawal** | Type E04-T01 · storage E06-T08 · schema-JSON gate E07-T02 · control E17-T02 · repeat E17-T04 |
| **§12.2 never give veterinary advice** | `ContentPolicy` E05-T09 · enforced in E16-T04 (the user's own threshold), E24-T02, E26-T07 |
| **§12.3 never a compliance record** | `Disclaimers` E05-T09 · footers E18-T03 · Export screen E18-T07 · About E26-T07 |
| **§12.4 never silently correct** | `Warning` E05-T02 · no `warnings` column E06 · derived birth type E13-T02 · the query mark E13-T06 · `clearDateDisagrees` E17-T06 |
| **§12.5 timestamps are honest** | `RecordedTime` E03-T04 · the quad on seven tables E06 · the header E13-T07 · the tile marker E16-T06 · every timeline row E23-T04 |
| **The offline gates G0–G5** | G2 E02-T04 · G3 E02-T03 · G0 E29-T01 · G1 + G4 E29-T03 · G5 E29-T05 |
| **The CI pipeline** | `gate` E01-T06 + E02-T07 · `codegen` E07-T06 · `test` E01-T04 · `android` E29-T03 · `release` E30-T04 · `goldens` E30-T06 |
| **Lints and the analyzer block** | E01-T02 |
| **The five decisions before commit #1** | E00-T01…T06 — epic 0, calendar-blocking |
| **Accessibility and the ARB** | Authoring rules in every UI task; sweeps E28-T02, T03, T04, T05, T06 |
| **Export, backup, restore, `tool/seed.dart`** | E18 · E19-T06 (restore) · E19-T09 (the seed, through the restore path) |
| **Monetization** | E27 in full; decision #90's widget test exists from E11-T07 |
| **Release engineering** | E29 and E30 |

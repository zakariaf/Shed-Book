# The Shed Book backlog

**35 epics · 240 tasks · one pull request per epic · one commit per task · every task TDD.**

This is the front door. Everything a developer needs to start work is either on this page or one
link away: what to build, in what order, on which branch, what proves it, and where the reasoning
lives. The build order is [`docs/engineering/00-README.md` §9](../docs/engineering/00-README.md);
this backlog is that order cut into pull requests.

Two facts set the order and explain almost every decision below. **Quick Entry is the product** —
every other screen exists to serve or read back the fifteen-second loop it drives — and **the schema
cannot be changed later**, because the only backup is one the shepherd remembered to make. So the
sequence front-loads the irreversible and the invisible-when-wrong, and reaches pixels late.

| | |
|---|---|
| **Start here** | [N00](N00-decisions-rulings-and-the-calendar/epic.md) → [N00-T01](N00-decisions-rulings-and-the-calendar/N00-T01-the-flutter-project-and-the-toolchain-pin.md), the first commit in the repository |
| **Validate the backlog** | `python3 tool/validate_epics.py` → §7 |
| **Not code, start today** | The field night · twelve testers · Apple SBP · G0 → §6 |
| **Never re-decide** | [`docs/research/00-tech-decisions.md`](../docs/research/00-tech-decisions.md) → §8 |

---

## 1. How to use this backlog

**Epics are sequential and each is one pull request.** N00 merges before N01 is cut. There is no
parallel track and no long-lived branch: the dependency graph has 264 edges, every one of them
pointing backwards, and it is arranged that way so that at any moment there is exactly one branch,
one open PR and one green `main`. An epic that is merged is a thing that works; an epic that is open
is the only thing in flight.

**Tasks are one commit each.** Not one commit per file and not one commit per idea — one commit per
task, in project vocabulary, so that `git log` reads as the task index and a bisect lands on a task
file that explains itself. Two tasks in the whole backlog state an exception and both say so in
their own header; nothing else may.

**Every task is TDD, and the test is named before the code.** Each task file's §4 gives the file,
the exact test name, and — this is the part that matters — **why it is red today**. Write it, run
it, watch it fail *for that reason*: not on a missing import, not on a compile error somewhere else.
Then the minimum code that turns it green and nothing beyond it. Then refactor with the suite green.
A task whose anchor test passed the first time you ran it has not been done; it has been described.

**Every task ends with `/simplify`, then `/code-review`.** In that order, over the diff, before the
commit — quality first, then defects, then commit. This project adds a third step, `/shed-code-review`,
which is the runbook that knows this codebase's rules and reads a diff in order of irreversibility;
`CLAUDE.md` mandates it and it is listed in all 240 task files. Until [ruling R1](#open-rulings) is
closed, **run all three**. At the end of the epic, run `/shed-code-review` once more over the whole
branch before opening the pull request — a diff that was reviewed in eight pieces has not been
reviewed as a change.

**A task is not a licence to design.** The task file names its sources, its skills, its constraints
and its Definition of Done. If the task seems wrong, that is a signal to read §8 and then raise it —
not to build it differently. See the amendment rule in §8.

---

## 2. The epics, in execution order

Read the row, open the `epic.md`, work the tasks in order. **Depends on** is the epic that must be
merged into `main` first; **PR** is the rough size of the diff a reviewer will face and the number of
commits in it.

| # | Epic | What it delivers | Demoable when it merges | Depends on | PR |
|---|---|---|---|---|---|
| **N00** | [Decisions, rulings and the calendar](N00-decisions-rulings-and-the-calendar/epic.md) | The repository itself, the toolchain pin, a resolving lockfile, four irreversible rulings, and a calendar ledger a test reads | `fvm flutter --version` prints 3.44.8 / 3.12.2, `flutter pub get` resolves and the lockfile is committed, P1 is … | — | S · 9 tasks |
| **N01** | [The tree, the configs and the CI shell](N01-the-tree-the-configs-and-the-ci-shell/epic.md) | The `CONVENTIONS §1` tree, four configs, the `Makefile`, the ARB with its first string, and two blocking CI jobs | `make check` is green on an empty tree and a pull request shows a green `gate` **and** a green `test` job, with … | N00 | M · 7 tasks |
| **N02** | [G0 — the merged-manifest record](N02-g0-the-merged-manifest-record/epic.md) | The permission set read off a real release AAB, the ruling it forces, and the guard on `tools:node="remove"` | `13 §2.2`'s four-row table is filled in from a real release `.aab` — every `uses-permission` named … | N01 | S · 3 tasks |
| **N03** | [The gate](N03-the-gate/epic.md) | `tool/check_policy.dart` — ~30 rules, one allowlist, one exit code, each rule watched to fire | `dart run tool/check_policy.dart` exits 0 on the tree; plant any violation and it exits 1 naming the rule id. … | N02 | L · 7 tasks |
| **N04** | [Domain: time and units](N04-domain-time-and-units/epic.md) | `Instant`, `LocalDate`, `PartialDate`, `RecordedTime`, `appNow()`, `Grams`, `MilliCelsius`, and the `uk-zone` tier | A pure-Dart suite runs green — including DST-1…DST-5 against the 01:00–01:59 ambiguous hour — with no Flutter, no … | N03 | M · 8 tasks |
| **N05** | [Domain: withdrawal](N05-domain-withdrawal/epic.md) | The withdrawal arithmetic at the *unconstructible* level, and a warning that changes nothing | The 167-hour spring-forward regression passes, and a withdrawal period is unconstructible except through … | N04 | M · 5 tasks |
| **N06** | [Domain: statistics, warnings and policy](N06-domain-statistics-warnings-and-policy/epic.md) | Ids, warnings, validators, the eight statistics with their verbatim definitions, terminology, disclaimers, `FreeTierPolicy`, the authored terms | Every statistic computes with its verbatim definition, its caveats and its `notComputableReason` … | N05 | L · 11 tasks |
| **N07** | [The schema and the freeze](N07-the-schema-and-the-freeze/epic.md) | 23 tables in four clusters, FTS5 in v1, the first-run seed — and the one committed schema snapshot | A real SQLite file opens with `STRICT`, refuses garbage, seeds a season nobody was asked about, and … | N06 | XL · 8 tasks |
| **N08** | [The migration harness and the `codegen` job](N08-the-migration-harness-and-the-codegen-job/epic.md) | The from→to matrix, the loud downgrade, the FTS5 answer, the pre-migration snapshot, and the `codegen` job | Every from→to pair runs `migrateAndValidate` with FTS5 present and zero rows, and `make gen` produces no git diff … | N07 | M · 7 tasks |
| **N09** | [The design system foundation](N09-the-design-system-foundation/epic.md) | Primitives, tokens, six measured palettes, the dark-only theme, type, `ShedTapTarget`, motion — and the gates that can honestly run | `contrast_test.dart` recomputes every pair in all six palettes and holds 4.5:1 on text and 3:1 on rules and marks … | N08 | L · 9 tasks |
| **N10** | [The component inventory](N10-the-component-inventory/epic.md) | All 21 `06 §12` components in `lib/core/ui/components/`, before a screen exists to reinvent one | Every `06 §12` component renders in a widget test at text scale 2.0 with bold text, carries a `semanticLabel`, and … | N09 | L · 8 tasks |
| **N11** | [Bootstrap, errors and the first frame](N11-bootstrap-errors-and-the-first-frame/epic.md) | `main()`, `app.dart`, `ShedFailure`, `NightErrorPanel`, the four-layer no-white-flash configuration, `LocalLog` | The app launches on a real Android phone and a real iPhone to a dark first frame with **no white flash**, and a … | N10 | L · 9 tasks |
| **N12** | [The DI root, settings, the ticker and the harness](N12-the-di-root-settings-the-ticker-and-the-harness/epic.md) | `providers.dart`, `SettingsRepository`, the one ticker, `WriteController.guard()`, and `test/support/` | `pumpApp` builds a widget against `NativeDatabase.memory()` with no production override, and `guard()` refuses a … | N11 | L · 5 tasks |
| **N13** | [Quick Entry: the deck and the keypad](N13-quick-entry-the-deck-and-the-keypad/epic.md) | `routes.dart`, `tagIndexProvider`, `quickEntryDeckProvider`, `ShedKeypad`, the shell, the two strips, `kPumpableVariants` | Type `12` on a real phone and 412 · 128 · 12 rank **in the same frame**, with no SQL round trip. | N12 | M · 7 tasks |
| **N14** | [Quick Entry: the write path](N14-quick-entry-the-write-path/epic.md) | `createEwe`, `beginLambing`, the write controller, the receipt, undo, and the five-tap budget test | **Five taps from launch to a committed `beginLambing` row**, asserted by `tap_budget_test.dart` on keyed finders … | N13 | M · 7 tasks |
| **N15** | [Media and notes](N15-media-and-notes/epic.md) | `MediaStore`, `CameraService`, `VoiceRecorder`, `NoteRepository`, `ShedPhoto` — relative paths only | A photo and a voice note attach to a record, land under `<appSupport>/media/YYYY/MM/`, and survive an app update … | N14 | M · 6 tasks |
| **N16** | [Lambing Entry and the P8 ruling](N16-lambing-entry/epic.md) | `lambingEntryProvider`, the tally, ease 1–5, care events, the warning strip, provenance, attachments — and the P8 ruling | You press one slab per lamb as it arrives and the row reads `TRIPLET (COUNTED)` — nobody ever chose it — and no … | N15 | L · 10 tasks |
| **N17** | [Lamb Card](N17-lamb-card/epic.md) | `lambCardProvider`, sex, birthweight on the app keypad, death with `stillborn` as its own bucket, pet-lamb status | A birthweight typed on the app's own keypad, stored in canonical grams, shown in the user's unit — and a death … | N16 | M · 5 tasks |
| **N18** | [Foster](N18-foster/epic.md) | `recordFoster`, the one-tap reassignment, the compensating *corrected* event, `fosterToSelf` | **A reassignment in one tap** from the Foster screen, with both dams still on the page forever. | N17 | M · 5 tasks |
| **N19** | [Pen Board](N19-pen-board/epic.md) | `enterPen`/`exitPen`, `penBoardProvider`, lazy pens, the ticker-driven tiles, `ShedPenTile`, the grid semantics tree | The whiteboard, live, every tile ticking in the same frame on the minute boundary — and the database itself … | N18 | L · 7 tasks |
| **N20** | [Treatments and withdrawal](N20-treatments-and-withdrawal/epic.md) | `recordTreatment` and its withdrawal children, the `YOUR ENTRY` control, the stored clear date, repeat, the soft void | **Repeat last treatment is two taps and does not copy the days** — it prints `DAYS NOT COPIED — READ THE BOTTLE`. | N19 | L · 7 tasks |
| **N21** | [Export: CSV, PDF and share](N21-export-csv-pdf-and-share/epic.md) | `CsvWriter`, the three CSV shapes, `pdf_writer.dart`, two flock-book volumes, the medicine record, `ShareService`, the Export screen, the banner | Three CSVs and two PDF volumes leave the phone through the share sheet, every struck row included and marked … | N20 | L · 8 tasks |
| **N22** | [The JSON backup format](N22-the-json-backup-format/epic.md) | `BackupHeader`, the canonical encoder, all 21 restorable tables, `unknown_json` round-trip, the checksum, file import | A backup round-trips `unknown_json` untouched, and a backup written by a higher schema is refused in words a … | N21 | L · 5 tasks |
| **N23** | [Restore, the sweeps and the seed](N23-restore-the-sweeps-and-the-seed/epic.md) | `RestoreService`, the two-step confirmation, `MediaSweeper`, `tool/seed.dart` through restore, two fixtures, the equality property | `dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42` fills a phone **through the restore path**, and export … | N22 | L · 7 tasks |
| **N24** | [Reminders: rows, reconcile and the fixtures](N24-reminders-rows-reconcile-and-the-fixtures/epic.md) | `ReminderBudget`, `NotificationScheduler` and its fake, the channels, rows inside the event transactions, `reconcile()`, both fixtures regenerated | A 312-reminder flock projects exactly 56 and drops none of the rest, asserted against … | N23 | L · 8 tasks |
| **N25** | [Reminders screen](N25-reminders-screen/epic.md) | `remindersProvider`, the three groups, the honest windowed line, completion as a domain write, mute as a strike, `reminder_rules` | The screen states the discrepancy in one honest line with **both numbers read from data**, never a hard-coded 56. | N24 | M · 6 tasks |
| **N26** | [Flock and Note Search](N26-flock-and-note-search/epic.md) | `flockListProvider`, the five filters, the 88 px row, add-a-ewe, `noteSearchProvider` over FTS5, hit rendering | 400 ewes filter to *currently penned* in daylight, at 11am, in the yard — and typing `watery` returns every note … | N25 | L · 7 tasks |
| **N27** | [Ewe Card](N27-ewe-card/epic.md) | `eweTimelineProvider`, the one-line summary, `ewe_summaries` maintained by its writers, provenance, the reused-tag disclosure, `EweObservations` | *"3 seasons · avg 2.0 · assisted twice · prolapsed 2025"* — assembled in Dart from counts, never read as a string … | N26 | L · 7 tasks |
| **N28** | [Season Summary](N28-season-summary/epic.md) | `watchSeasonCounts`, the statistics as rendered, `watchSpread`, the hand-rolled chart, season comparison | Every number carries its definition and its caveats, and the spread chart uses no chart library and reads at 200% … | N27 | L · 6 tasks |
| **N29** | [Settings](N29-settings/epic.md) | The Settings screen, units, terminology editing, appearance and `WakelockController`, season switching, the two honest deletes, Diagnostics and About | Rename *ewe* to *gimmer* and the whole app says gimmer; delete-everything says exactly what it will destroy … | N28 | L · 8 tasks |
| **N30** | [Monetization](N30-monetization/epic.md) | `PurchaseService`, `EntitlementRepository`, `UnlockController`, the entitlement source, the two static rows, the store artefacts | One unlock buys it forever, and the widget test proves nothing about money renders on any of the five shed screens … | N29 | L · 8 tasks |
| **N31** | [Platform artefacts, G1, G4 and G5](N31-platform-artefacts-g1-g4-and-g5/epic.md) | `expected_permissions.txt`, the Android build configuration, `assert_permissions.sh` (G1), the `android` job, the G4 archive, iOS G5 | `bundletool dump manifest` on a real release `.aab` shows exactly the permission set G0 recorded, and the … | N30 | L · 4 tasks |
| **N32** | [Signing and the closed track opens](N32-signing-and-the-closed-track/epic.md) | The upload keystore, Play App Signing, the app record, the listing draft, the first signed build on a closed track and TestFlight | A signed AAB reaches a Play closed track and TestFlight, and the calendar ledger's twelve-tester row records the … | N31 | M · 3 tasks |
| **N33** | [Ship gates: the sweeps, the matrix, the goldens and the journeys](N33-ship-gates-sweeps-goldens-and-journeys/epic.md) | The 252-cell matrix, the semantics sweep, the tap-target gate, reachability, the ARB sweep, the nutrition label, eight goldens, four journeys, `goldens.yml` | The 252-cell matrix, the semantics gate, the tap-target gate, four integration journeys and eight CI-verified PNGs … | N32 | L · 9 tasks |
| **N34** | [Release engineering](N34-release-engineering/epic.md) | `release.yml`, the version rules, the app-size budget, obfuscation, the off-machine symbols archive, startup on two real devices, the seasonal freeze | `git tag v1.0.0` produces a signed AAB, eight goldens and a symbols archive kept off the laptop. | N33 | M · 4 tasks |

**Sizes.** `S` — an afternoon to a day, mostly decisions and files nobody generates. `M` — a day or
two. `L` — several days; the review is the expensive part. `XL` — [N07](N07-the-schema-and-the-freeze/epic.md)
only, and it is XL because it is the one epic whose output cannot be changed afterwards.

**The four epics that are not where a reader expects them, and why:**

- **N02 (G0) runs at position 2 but is `00-README` §9 step 12.** It reads the merged manifest off a
  real release AAB. Until it has been run, the offline gate G1 is *unwritten*, not merely
  unimplemented, and the store listing, the About screen and the Export screen are all written on
  faith. It costs an afternoon here; at position 29 it re-opens copy in three merged epics.
- **N10 (the component inventory) is new.** Fifteen of `06-design-system.md` §12's twenty-one
  components had no owner. A sibling-feature import is a layer violation, so twelve screen epics
  would each have built their own and the layer rule then forbids sharing them.
- **N12 pulls `SettingsRepository` forward** from Settings (N29) because the export banner writes
  `app_settings` in N21 — fifteen epics before the Settings screen exists.
- **N32 (signing) runs before N33 (the sweeps).** Play's closed test needs fourteen days with twelve
  testers. Signing last parks two weeks of dead calendar at the end of the project by construction;
  signing here runs that clock in parallel with the sweeps.

---

## 3. The task index

240 tasks, grouped by epic, in commit order. The one-liner is what the task does; the task file is
why, plus the anchor test, the skills, the constraints, the Definition of Done and the verification
commands. `N16-T02a` is not a typo — it is a genuine insertion whose id is load-bearing in three
documents.

#### [N00 — Decisions, rulings and the calendar](N00-decisions-rulings-and-the-calendar/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N00-T01](N00-decisions-rulings-and-the-calendar/N00-T01-the-flutter-project-and-the-toolchain-pin.md) | The Flutter project and the toolchain pin | `flutter create` at the pinned SDK, producing `android/`, `ios/` and a `pubspec.yaml` that T03 will rewrite. |
| [N00-T02](N00-decisions-rulings-and-the-calendar/N00-T02-rule-the-two-dependency-shaped-open-questions.md) | Rule the two dependency-shaped open questions | Two open questions expire the moment `pubspec.yaml` closes in T03: **in-app PDF printing** (the `printing` package pulls `http`, which the offline … |
| [N00-T03](N00-decisions-rulings-and-the-calendar/N00-T03-pubspecyaml-from-decision-record-5-and-the-committed-lockfil.md) | `pubspec.yaml` from decision-record §5, and the committed lockfile | Every dependency authored from decision-record §5.1 and §5.2 **verbatim** — `flutter_riverpod: 2.6.1` with no caret, `drift 2.34.2` / `drift_dev` … |
| [N00-T04](N00-decisions-rulings-and-the-calendar/N00-T04-rule-the-four-schema-shaped-questions.md) | Rule the four schema-shaped questions | Four open questions become migrations on somebody else's phone if they survive the freeze in N07-T08: `WithdrawalTarget.milk`, the temperature … |
| [N00-T05](N00-decisions-rulings-and-the-calendar/N00-T05-rule-p1-struck-struck-at-on-every-table.md) | Rule P1 — `struck` / `struck_at` on every table | P1 is the schema-irreversible open conflict: whether every table carries `struck` and `struck_at`, or only some do. |
| [N00-T06](N00-decisions-rulings-and-the-calendar/N00-T06-docscalendarmd-and-the-ledger-test-that-stays-red-until-it-i.md) | `docs/calendar.md` and the ledger test that stays red until it is filled | One row per calendar commitment — the field night, the twelve testers, the ziplock-bag capacitance test, the two developer accounts, Apple Small … |
| [N00-T07](N00-decisions-rulings-and-the-calendar/N00-T07-book-the-field-night-and-start-recruiting-twelve-shepherds.md) | Book the field night and start recruiting twelve shepherds | `00-README` §5.2's item 1 is the highest-value unresolved item in the project and it closes three others: every tap count in `07-screens.md` is a … |
| [N00-T08](N00-decisions-rulings-and-the-calendar/N00-T08-the-ziplock-bag-capacitance-test.md) | The ziplock-bag capacitance test | A phone, a freezer bag and a recorded result per target device. |
| [N00-T09](N00-decisions-rulings-and-the-calendar/N00-T09-store-accounts-the-small-business-program-price-and-territor.md) | Store accounts, the Small Business Program, price and territories | Both developer accounts created, the post-13-November-2023 personal-account question answered in writing, Apple Small Business Program enrolment … |

#### [N01 — The tree, the configs and the CI shell](N01-the-tree-the-configs-and-the-ci-shell/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N01-T01](N01-the-tree-the-configs-and-the-ci-shell/N01-T01-prune-to-the-conventions-1-tree-and-write-gitignore.md) | Prune to the `CONVENTIONS §1` tree and write `.gitignore` | `flutter create` produced `lib/main.dart` and `test/widget_test.dart` and none of `CONVENTIONS §1`'s folders. |
| [N01-T02](N01-the-tree-the-configs-and-the-ci-shell/N01-T02-analysis-optionsyaml.md) | `analysis_options.yaml` | `flutter_lints 6.0.0` as the include, plus the explicit `analyzer.language` block — `strict-casts`, `strict-inference`, `strict-raw-types`, all three … |
| [N01-T03](N01-the-tree-the-configs-and-the-ci-shell/N01-T03-buildyaml-l10nyaml-and-libl10napp-enarb.md) | `build.yaml`, `l10n.yaml` and `lib/l10n/app_en.arb` | Drift as the **only** generator in `build.yaml`, with no banned build option; `l10n.yaml` with `en` only and the generated output committed; and … |
| [N01-T04](N01-the-tree-the-configs-and-the-ci-shell/N01-T04-dart-testyaml.md) | `dart_test.yaml` | The `ci-fast` and `ci-golden` presets, the `uk-zone`, `golden`, `slow` and `calendar` tags, and randomisation switched **off** for the `migration` … |
| [N01-T05](N01-the-tree-the-configs-and-the-ci-shell/N01-T05-the-makefile-cheapest-failure-first.md) | The `Makefile`, cheapest failure first | Eight targets — `gen`, `check`, `test`, `goldens`, `goldens-update`, `integration`, `validate`, `all` — ordered so the sub-second failure happens … |
| [N01-T06](N01-the-tree-the-configs-and-the-ci-shell/N01-T06-githubworkflowsciyml-the-gate-and-test-jobs.md) | `.github/workflows/ci.yml` — the `gate` and `test` jobs | Two blocking jobs on every push and every pull request. |
| [N01-T07](N01-the-tree-the-configs-and-the-ci-shell/N01-T07-githubpull-request-templatemd-the-five-12-questions-verbatim.md) | `.github/pull_request_template.md` — the five §12 questions, verbatim | The pull request is **where the safety review happens** (`00-README` §7.4). |

#### [N02 — G0 — the merged-manifest record](N02-g0-the-merged-manifest-record/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N02-T01](N02-g0-the-merged-manifest-record/N02-T01-run-g0-against-a-real-release-aab-and-record-what-it-says.md) | Run G0 against a real release AAB and record what it says | `flutter build appbundle --release` with `in_app_purchase` present, then read the merged manifest and the merger report. |
| [N02-T02](N02-g0-the-merged-manifest-record/N02-T02-the-ruling-g0-produces-and-the-honesty-paragraph-it-may-forc.md) | The ruling G0 produces, and the honesty paragraph it may force | `INTERNET` is removed. `ACCESS_NETWORK_STATE` is **left or removed on the evidence**, not on faith. |
| [N02-T03](N02-g0-the-merged-manifest-record/N02-T03-g0-recorded-testdart-the-guard-on-toolsnode-remove.md) | `g0_recorded_test.dart` — the guard on `tools:node="remove"` | Decision #5 in one executable line: **no `tools:node="remove"` may exist in any manifest while `13 §2.2`'s table still reads UNVERIFIED**. |

#### [N03 — The gate](N03-the-gate/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N03-T01](N03-the-gate/N03-T01-the-gate-skeleton-the-rule-table-the-walk-the-allowlist.md) | The gate skeleton — the rule table, the walk, the allowlist | `tool/check_policy.dart`: the rule-table shape (id, description, matcher, scope), the file walk, the generated-file skip (`*.g.dart`, `*.drift.dart` … |
| [N03-T02](N03-the-gate/N03-T02-the-layer-rules.md) | The layer rules | The eight layer rules plus `layer.sibling` and `layer.data_no_validation`. |
| [N03-T03](N03-the-gate/N03-T03-the-net-rules-g3.md) | The `net.*` rules — G3 | The import scan: no `dart:io` `HttpClient`, no `package:http`, no socket, no `WebSocket`, no `Uri.parse` reaching a scheme we do not ship, anywhere … |
| [N03-T04](N03-the-gate/N03-T04-g2-the-direct-dependency-allowlist-over-pubspeclock.md) | G2 — the direct-dependency allowlist over `pubspec.lock` | Every direct dependency must appear in the allowlist with a reason. |
| [N03-T05](N03-the-gate/N03-T05-the-design-rules.md) | The design rules | `design.raw_hex` (a `Color(0x…)` outside `lib/core/ui/primitives.dart`), `design.magic_size` (a numeric literal in a padding, gap, width or height) … |
| [N03-T06](N03-the-gate/N03-T06-the-time-db-rp3-and-vocabulary-rules.md) | The `time`, `db`, `rp3` and vocabulary rules | `time.wall_clock` — `DateTime.now(` may appear in exactly one non-generated file under `lib/`. |
| [N03-T07](N03-the-gate/N03-T07-wire-the-gate-into-ci-and-assert-the-rule-inventory-is-compl.md) | Wire the gate into CI and assert the rule inventory is complete | The gate becomes the `gate` job's **first** step, before `pub get`, because it is sub-second and everything after it is not. |

#### [N04 — Domain: time and units](N04-domain-time-and-units/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N04-T01](N04-domain-time-and-units/N04-T01-instant-the-extension-type-over-utc-epoch-millis.md) | `Instant` — the extension type over UTC epoch millis | `Instant` as an extension type over `int` epoch millis, with ordering, arithmetic, `compareTo` and **no `Instant.now()`**. |
| [N04-T02](N04-domain-time-and-units/N04-T02-localdate-strict-parse-never-widened.md) | `LocalDate` — strict parse, never widened | `LocalDate` over `TEXT 'YYYY-MM-DD'` with a **strict** parse that throws rather than guesses, plus `plusDays`, `daysUntil` and `startOfDayLocal`. |
| [N04-T03](N04-domain-time-and-units/N04-T03-partialdate-a-year-maybe-a-month-never-silently-widened.md) | `PartialDate` — a year, maybe a month, never silently widened | A ewe's date of birth is often *"2022"* and sometimes *"spring 2022"*. |
| [N04-T04](N04-domain-time-and-units/N04-T04-recordedtime-and-timesource-provenance-as-part-of-the-value.md) | `RecordedTime` and `TimeSource` — provenance as part of the value | §12.5 made unrepresentable: the time and where it came from are **one value**, so a timestamp cannot be stored without its provenance. |
| [N04-T05](N04-domain-time-and-units/N04-T05-appnow-the-one-wall-clock-reader.md) | `appNow()` — the one wall-clock reader | `lib/core/time/app_clock.dart` — the **only** file under `lib/` permitted to call `DateTime.now(`, its single `[exempt]` allowlist line, and … |
| [N04-T06](N04-domain-time-and-units/N04-T06-grams-weightunit-and-parseusernumber.md) | `Grams`, `WeightUnit` and `parseUserNumber` | Mass is canonical **grams** in storage and is converted only at the display edge. |
| [N04-T07](N04-domain-time-and-units/N04-T07-millicelsius-canonical-integer-temperature.md) | `MilliCelsius` — canonical integer temperature | Temperature as an integer in milli-degrees Celsius, converted to °F only at the display edge. |
| [N04-T08](N04-domain-time-and-units/N04-T08-the-uk-zone-test-tier-and-the-ambiguous-hour.md) | The `uk-zone` test tier and the ambiguous hour | `@Tags(['uk-zone'])`, `TZ=Europe/London`, and the DST-1…DST-5 cases against the **01:00–01:59** ambiguous hour the owner ruled. |

#### [N05 — Domain: withdrawal](N05-domain-withdrawal/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N05-T01](N05-domain-withdrawal/N05-T01-sealed-withdrawalperiod-and-its-one-entry-point.md) | `sealed WithdrawalPeriod` and its one entry point | A sealed type with a **private generative constructor** and exactly one public entry point, `WithdrawalDays.asEnteredByUser`. §12.1 pushed to … |
| [N05-T02](N05-domain-withdrawal/N05-T02-cleardatefor-ceil-to-the-next-local-midnight.md) | `clearDateFor` — ceil to the next local midnight | Decision #3, executable: the clear date is the **ceiling to the next local midnight** of (administration instant + N × 24 h), computed in … |
| [N05-T03](N05-domain-withdrawal/N05-T03-withdrawalstatus-and-computewithdrawalstatus.md) | `WithdrawalStatus` and `computeWithdrawalStatus` | Three arms and no fourth: `ClearsOn`, `NoWithdrawal`, `WithdrawalUnknown`. |
| [N05-T04](N05-domain-withdrawal/N05-T04-the-type-and-source-half-of-never-default-a-withdrawal.md) | The type-and-source half of *never default a withdrawal* | `test/policy/withdrawal_has_no_default_test.dart` grows its second assertion: **no literal withdrawal day count appears anywhere under `lib/`** — not … |
| [N05-T05](N05-domain-withdrawal/N05-T05-cleardatedisagrees-a-warning-that-changes-nothing.md) | `clearDateDisagrees` — a warning that changes nothing | When the stored clear date does not equal what today's arithmetic would produce from the stored inputs — because the device zone changed, or the row … |

#### [N06 — Domain: statistics, warnings and policy](N06-domain-statistics-warnings-and-policy/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N06-T01](N06-domain-statistics-warnings-and-policy/N06-T01-idsdart-and-the-enums-that-mirror-stored-keys.md) | `ids.dart` and the enums that mirror stored keys | Extension-type ids for every entity, plus `BirthType` with `expectedLambCount` (**null** for `quintPlus`, never a guess), `LambingEase` as the … |
| [N06-T02](N06-domain-statistics-warnings-and-policy/N06-T02-warning-the-eleven-warningcode-members-and-reviewed-t.md) | `Warning`, the eleven `WarningCode` members and `Reviewed<T>` | The §12.4 mechanism, at the *unrepresentable* level: `Warning` has **no writer**, no `fix()`, and nothing to persist into — there is no `warnings` … |
| [N06-T03](N06-domain-statistics-warnings-and-policy/N06-T03-the-three-validators-and-kplausiblebirthweight.md) | The three validators and `kPlausibleBirthWeight` | Lambing, foster and treatment validation as pure functions returning `List<Warning>`. |
| [N06-T04](N06-domain-statistics-warnings-and-policy/N06-T04-statresult-lambcount-flockdenominator-and-seasoncounts.md) | `StatResult`, `LambCount`, `FlockDenominator` and `SeasonCounts` | The shapes every statistic returns. A statistic with no denominator returns `notComputableReason` — **not** zero, not a dash, not an empty string. |
| [N06-T05](N06-domain-statistics-warnings-and-policy/N06-T05-lambing-percentage-average-litter-size-and-barren-rate.md) | Lambing percentage, average litter size and barren rate | Three statistics, each carrying its **verbatim definition**, its numerator, its denominator and its caveats — because *lambing percentage* means at … |
| [N06-T06](N06-domain-statistics-warnings-and-policy/N06-T06-assisted-rate-losses-by-cause-and-by-age-and-the-lambing-spr.md) | Assisted rate, losses by cause and by age, and the lambing spread | The remaining statistics, plus the **dense, zero-filled** lambing spread: every day of the season present, including the days nothing was born … |
| [N06-T07](N06-domain-statistics-warnings-and-policy/N06-T07-ranktagmatches-and-the-pen-timing-functions.md) | `rankTagMatches` and the pen-timing functions | The ranking behind spec §7.1's partial tag matching — typing `12` surfaces 12, then 128, then 412 — and `timeSincePenned` / `isReadyToTurnOut`, both … |
| [N06-T08](N06-domain-statistics-warnings-and-policy/N06-T08-terminology-a-closed-enum-under-a-user-editable-overlay.md) | Terminology — a closed enum under a user-editable overlay | `AnimalClass`, `TermLabel` and `Terminology`: the concepts are a **closed enum** the code switches on; the words are an overlay the user edits. |
| [N06-T09](N06-domain-statistics-warnings-and-policy/N06-T09-disclaimers-contentpolicy-exportenvelope-and-the-two-copy-ga.md) | `Disclaimers`, `ContentPolicy`, `ExportEnvelope` — and the two `copy.*` gate rows | `Disclaimers` as an `abstract final class` of `const` strings in **one** file, referenced and never re-typed; `ExportEnvelope` with **no** disclaimer … |
| [N06-T10](N06-domain-statistics-warnings-and-policy/N06-T10-free-tierdart-the-cap-decision-eleven-epics-before-it-is-wir.md) | `free_tier.dart` — the cap decision, eleven epics before it is wired | `EntryContext`, `CapDecision`, `RefusalReason`, `FreeTierPolicy.decide` and `isQuietHours`. |
| [N06-T11](N06-domain-statistics-warnings-and-policy/N06-T11-assetscontent-the-40-authored-terms.md) | `assets/content/` — the ~40 authored terms | Spec §11's only shipped data: the lambing-ease scale descriptions, the common death causes, the common malpresentations and the common treatment … |

#### [N07 — The schema and the freeze](N07-the-schema-and-the-freeze/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N07-T01](N07-the-schema-and-the-freeze/N07-T01-connectiondart-pragmas-fts5-and-the-in-memory-harness.md) | `connection.dart` — pragmas, FTS5 and the in-memory harness | `openConnection` with the seven pragmas in `R13`'s order — `synchronous = FULL` among them, because *assume the phone dies* is a durability setting … |
| [N07-T02](N07-the-schema-and-the-freeze/N07-T02-databasedart-convertersdart-uiddart-and-mixin-identified.md) | `database.dart`, `converters.dart`, `uid.dart` and `mixin Identified` | The `AppDatabase` class, `kSchemaVersion`, the type converters (`Instant`, `LocalDate`, `Grams`, `MilliCelsius` — every one of them mapping to … |
| [N07-T03](N07-the-schema-and-the-freeze/N07-T03-the-flock-cluster.md) | The flock cluster | `seasons`, `ewes`, `ewe_seasons`, `ewe_touches`, `ewe_observations` — with the **active-only partial unique index** on `tag`, which is the owner's … |
| [N07-T04](N07-the-schema-and-the-freeze/N07-T04-the-lambing-cluster.md) | The lambing cluster | `lambings`, `lambs`, `foster_events`, `care_events`, the **birth-dam immutability trigger**, and the `lamb_rearing` and `lambing_consistency` views. |
| [N07-T05](N07-the-schema-and-the-freeze/N07-T05-the-pen-and-treatment-clusters.md) | The pen and treatment clusters | `pens`, `pen_occupancies`, `pen_occupancy_lambs` with the partial unique index `WHERE exited_at IS NULL` — the database itself refuses two ewes in … |
| [N07-T06](N07-the-schema-and-the-freeze/N07-T06-the-ancillary-cluster-and-unknown-json.md) | The ancillary cluster and `unknown_json` | `reminders`, `reminder_rules`, `notes`, `media_assets`, `vocab_terms`, `terminology_overrides`, `app_settings`, `entitlements`, `ewe_summaries` … |
| [N07-T07](N07-the-schema-and-the-freeze/N07-T07-searchdrift-viewsdrift-queriesdrift-and-seedfirstrun.md) | `search.drift`, `views.drift`, `queries.drift` and `seedFirstRun` | FTS5 present in **v1** with zero real rows — so the shadow-table question is answered in week one rather than at v4 with a shepherd's data in the … |
| [N07-T08](N07-the-schema-and-the-freeze/N07-T08-the-freeze-alone.md) | The freeze, alone | `make gen` **in full** — `build_runner` plus `drift_dev make-migrations` — run once, writing `kSchemaVersion`, `drift_schemas/drift_schema_v1.json` … |

#### [N08 — The migration harness and the `codegen` job](N08-the-migration-harness-and-the-codegen-job/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N08-T01](N08-the-migration-harness-and-the-codegen-job/N08-T01-migrationsdart-the-stepbystep-scaffold.md) | `migrations.dart` — the `stepByStep` scaffold | The migration strategy with the five migration rules carried on it as a doc comment where the next person will actually read them: forward-only … |
| [N08-T02](N08-the-migration-harness-and-the-codegen-job/N08-T02-the-from-to-matrix.md) | The from→to matrix | `SchemaVerifier.migrateAndValidate` on **every** from→to pair, with `PRAGMA foreign_key_check` returning zero rows afterwards. |
| [N08-T03](N08-the-migration-harness-and-the-codegen-job/N08-T03-testwithdataintegrity-scoped.md) | `testWithDataIntegrity`, scoped | Data integrity checked on the N-1→N pair and on any step that rewrites a table — not on every pair, because a full-data check across every historical … |
| [N08-T04](N08-the-migration-harness-and-the-codegen-job/N08-T04-the-loud-downgrade.md) | The loud downgrade | A database file written by a **newer** schema on an older build must fail loudly and never open. |
| [N08-T05](N08-the-migration-harness-and-the-codegen-job/N08-T05-fts5-shadow-tables-under-schemaverifier.md) | FTS5 shadow tables under `SchemaVerifier` | The day-one unverified claim, checked: does `SchemaVerifier` choke on FTS5 shadow tables? |
| [N08-T06](N08-the-migration-harness-and-the-codegen-job/N08-T06-the-codegen-ci-job.md) | The `codegen` CI job | Regenerate, then `git diff --exit-code` over `lib/`, `drift_schemas/` and `test/drift/generated/`. |
| [N08-T07](N08-the-migration-harness-and-the-codegen-job/N08-T07-snapshotbeforemigration-and-diagnostics-snapshotdart.md) | `_snapshotBeforeMigration` and `diagnostics_snapshot.dart` | `VACUUM INTO` a snapshot before a migration runs, bounded in size and count, and **never rethrowing** — a failed snapshot must not stop the app … |

#### [N09 — The design system foundation](N09-the-design-system-foundation/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N09-T01](N09-the-design-system-foundation/N09-T01-primitivesdart-raw-hexes-importable-nowhere-else.md) | `primitives.dart` — raw hexes, importable nowhere else | The only file in the app permitted to contain a raw hex or a raw scale value, with its two `[exempt]` allowlist lines. |
| [N09-T02](N09-the-design-system-foundation/N09-T02-tokensdart-one-flat-themeextension.md) | `tokens.dart` — one flat `ThemeExtension` | `ShedTokens` as a single flat `ThemeExtension`, `ShedPalette`, `ShedPaletteId`, `context.tokens`, and a `lerp` that **snaps** rather than … |
| [N09-T03](N09-the-design-system-foundation/N09-T03-palettesdart-night-amber-and-deep-red-each-with-a-high-contr.md) | `palettes.dart` — night, amber and deep red, each with a high-contrast variant | Six palettes, **measured rather than chosen**: every text pair recomputed to 4.5:1 and every rule and mark to 3:1, in code, by the test — not by eye … |
| [N09-T04](N09-the-design-system-foundation/N09-T04-themedart-no-code-path-can-produce-a-light-theme.md) | `theme.dart` — no code path can produce a light theme | `buildShedTheme` and `ShedThemeSet`, with **no** code path that can produce `Brightness.light`. |
| [N09-T05](N09-the-design-system-foundation/N09-T05-typography-the-variable-font-and-the-p7-ruling.md) | Typography, the variable font, and the P7 ruling | The two voices, the variable font asset, the scale with an 18 px absolute floor, the weight cap and tabular figures. |
| [N09-T06](N09-the-design-system-foundation/N09-T06-formattersdart-the-one-packageintl-call-site.md) | `formatters.dart` — the one `package:intl` call site | `d MMM y`, 24-hour `HH:mm`, `dd/MM/yyyy` where a numeric date is unavoidable — and **never** an all-numeric human date, because `03/04` is two … |
| [N09-T07](N09-the-design-system-foundation/N09-T07-shedtaptarget-64-64-and-a-required-semanticlabel.md) | `ShedTapTarget` — 64 × 64 and a required `semanticLabel` | The tap primitive every control is built on: a **required** `semanticLabel`, a 64 × 64 minimum build box against the 60 pt floor's four points of … |
| [N09-T08](N09-the-design-system-foundation/N09-T08-the-design-gates-that-can-honestly-run-today.md) | The design gates that can honestly run today | `wcag.dart`'s arithmetic, `contrast_test.dart` over the palettes, the single-widget `tap_target_test.dart` and `reduce_motion_test.dart`. |
| [N09-T09](N09-the-design-system-foundation/N09-T09-motiondart-the-haptic-vocabulary-and-the-p10-ruling.md) | `motion.dart`, the haptic vocabulary, and the P10 ruling | The motion tokens, the reduce-motion resolver and the haptic vocabulary. |

#### [N10 — The component inventory](N10-the-component-inventory/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N10-T01](N10-the-component-inventory/N10-T01-shedprimarybutton-the-corner-slab.md) | `ShedPrimaryButton` — the corner slab | The one-per-page primary verb: a corner slab, five states, and the rule that it **never refuses a press**. |
| [N10-T02](N10-the-component-inventory/N10-T02-shedsecondarybutton-and-sheddestructivebutton.md) | `ShedSecondaryButton` and `ShedDestructiveButton` | The word button's two forms. The destructive form carries **two-step destruction** and `gapDestructive` separation, so the tap that deletes a season … |
| [N10-T03](N10-the-component-inventory/N10-T03-shedconfirmbar-and-shedrecentsstrip.md) | `ShedConfirmBar` and `ShedRecentsStrip` | Both outcome-labelled and both at **fixed height from frame 1**, so nothing shifts under a thumb that is already moving. |
| [N10-T04](N10-the-component-inventory/N10-T04-shedanimalrow-and-shedsectionheading.md) | `ShedAnimalRow` and `ShedSectionHeading` | The 64 and 88 px ruled rows, the sub-grid they align to, and `headingLevel` 1 and 2 — with `header:` **banned**, because a screen reader that hears … |
| [N10-T05](N10-the-component-inventory/N10-T05-shedstatusbadge-and-shedcountdown.md) | `ShedStatusBadge` and `ShedCountdown` | Icon **and** word, always — colour is never the only channel, because a head torch and a red-shift palette between them destroy hue discrimination. |
| [N10-T06](N10-the-component-inventory/N10-T06-shedchoicerow-and-shedfieldrow.md) | `ShedChoiceRow` and `ShedFieldRow` | `ShedChoiceRow` survives **for lambing ease 1–5 only** — P8 abolished the birth-type chooser and this component is the last legitimate segmented … |
| [N10-T07](N10-the-component-inventory/N10-T07-shedbottomsheet-the-only-overlay-in-the-app.md) | `ShedBottomSheet` — the only overlay in the app | One overlay type, and only one: no drag handle, no drag, not dismissible by tapping outside, with an explicit Cancel. |
| [N10-T08](N10-the-component-inventory/N10-T08-shedemptystate-shedbanner-and-shedreceiptbar.md) | `ShedEmptyState`, `ShedBanner` and `ShedReceiptBar` | The empty state occupies **the same box the content will**, so nothing jumps when the first record arrives. |

#### [N11 — Bootstrap, errors and the first frame](N11-bootstrap-errors-and-the-first-frame/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N11-T01](N11-bootstrap-errors-and-the-first-frame/N11-T01-shedfailure-and-writeoutcome.md) | `ShedFailure` and `WriteOutcome` | Six failure variants and three write outcomes, all non-generic — **no `Ok`, no `Error`**, because `Error` is a banned name and a generic result type … |
| [N11-T02](N11-bootstrap-errors-and-the-first-frame/N11-T02-shedfailurefromobject-the-one-mapping-site.md) | `shedFailureFrom(Object)` — the one mapping site | The **only** place a `SqliteException` becomes a `ShedFailure`. |
| [N11-T03](N11-bootstrap-errors-and-the-first-frame/N11-T03-maindart-twenty-lines-nothing-awaited.md) | `main.dart` — twenty lines, nothing awaited | Decision #4, executable: `ensureInitialized()` → install both handlers → `runApp()`. |
| [N11-T04](N11-bootstrap-errors-and-the-first-frame/N11-T04-nighterrorpanel-and-the-p14-ruling.md) | `NightErrorPanel` and the P14 ruling | The `ErrorWidget.builder` that renders when everything else has failed — so it **bypasses `Theme`** and carries its own `Directionality`, because a … |
| [N11-T05](N11-bootstrap-errors-and-the-first-frame/N11-T05-appdart-shedbookapp-the-boot-kick-and-the-localisations.md) | `app.dart` — `ShedBookApp`, the boot kick, and the localisations | `ShedBookApp` as a `ConsumerStatefulWidget`, the **post-frame** boot kick that opens the database after the first frame, `ResumePolicy`, and the … |
| [N11-T06](N11-bootstrap-errors-and-the-first-frame/N11-T06-no-white-flash-the-android-layers.md) | No white flash — the Android layers | The Android half of the four-layer configuration: the launch theme, the window background, the `styles.xml` night variant and the activity's theme … |
| [N11-T07](N11-bootstrap-errors-and-the-first-frame/N11-T07-no-white-flash-the-ios-layers.md) | No white flash — the iOS layers | The iOS half: the launch storyboard's background, `Info.plist`'s appearance key, the window's background colour and the root view controller's. |
| [N11-T08](N11-bootstrap-errors-and-the-first-frame/N11-T08-the-first-frame-parity-gate.md) | The first-frame parity gate | One test that reads **both** platforms' native files and asserts they equal each other and the token. |
| [N11-T09](N11-bootstrap-errors-and-the-first-frame/N11-T09-locallog-redaction-and-dirty-resume-detection.md) | `LocalLog`, redaction and dirty-resume detection | The diagnostics log — never *crash log*, never *telemetry*, because there is none and the words matter. |

#### [N12 — The DI root, settings, the ticker and the harness](N12-the-di-root-settings-the-ticker-and-the-harness/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N12-T01](N12-the-di-root-settings-the-ticker-and-the-harness/N12-T01-providersdart-the-di-graph-as-far-as-it-can-honestly-reach.md) | `providers.dart` — the DI graph as far as it can honestly reach | `databaseProvider` as a `FutureProvider`, keepAlive, and the repository providers derived from it — for the repositories that exist today. |
| [N12-T02](N12-the-di-root-settings-the-ticker-and-the-harness/N12-T02-settingsrepository-and-the-four-settings-providers.md) | `SettingsRepository` and the four settings providers | Pulled forward from the Settings epic because the export banner writes `app_settings` in N21 — `lastExportedAt`, `lastExportPromptedAt` … |
| [N12-T03](N12-the-di-root-settings-the-ticker-and-the-harness/N12-T03-minutetickprovider-one-boundary-aligned-ticker.md) | `minuteTickProvider` — one boundary-aligned ticker | **One** 60-second ticker in the whole app, aligned to the minute boundary, yielding `Instant`, `autoDispose`, and never `Timer.periodic` — because … |
| [N12-T04](N12-the-di-root-settings-the-ticker-and-the-harness/N12-T04-writecontroller-and-guard.md) | `WriteController` and `guard()` | Every mutation goes through `guard()`, which **refuses to run concurrently**. |
| [N12-T05](N12-the-di-root-settings-the-ticker-and-the-harness/N12-T05-testsupport-pumpapp-device-and-seedsdart-and-nothing-else.md) | `test/support/` — `pumpApp`, `Device` and `seeds.dart`, and nothing else | `pumpApp` over `NativeDatabase.memory()`, the `Device` table, `freshSupportDir()`, and `seeds.dart`'s `seedEwe` / `seedLambing` / `seedTreatment`. |

#### [N13 — Quick Entry: the deck and the keypad](N13-quick-entry-the-deck-and-the-keypad/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N13-T01](N13-quick-entry-the-deck-and-the-keypad/N13-T01-routesdart-thirteen-names-one-helper-and-the-p3-ruling.md) | `routes.dart` — thirteen names, one helper, and the P3 ruling | Thirteen `RouteNames` constants (free — a `const String` creates no compile edge), `Routes.navigatorKey`, the `onGenerateRoute` switch and **only the … |
| [N13-T02](N13-quick-entry-the-deck-and-the-keypad/N13-T02-tagindexprovider-active-animals-only-ranked-in-memory.md) | `tagIndexProvider` — active animals only, ranked in memory | The in-memory tag index over **active animals only** — the owner's uniqueness ruling made into a query — feeding `rankTagMatches` so that typing a … |
| [N13-T03](N13-quick-entry-the-deck-and-the-keypad/N13-T03-quickentrydeckprovider-one-statement-two-buckets.md) | `quickEntryDeckProvider` — one statement, two buckets | The deck: *in the pens* and *recents*, in **one** drift statement with an explicit `readsFrom:`, read by the two strips through `.select` so a change … |
| [N13-T04](N13-quick-entry-the-deck-and-the-keypad/N13-T04-shedkeypad-the-only-number-entry-route-in-the-app.md) | `ShedKeypad` — the only number-entry route in the app | Digits at 40 pt minimum on 64 × 64 targets, and **no key is ever disabled** — including over the free cap, because a dead key at 3am is … |
| [N13-T05](N13-quick-entry-the-deck-and-the-keypad/N13-T05-the-quick-entry-shell.md) | The Quick Entry shell | The ruled page, the madder spine, the margin cell, the bottom band — and **frame 1 with no data**, which is the state the shepherd actually opens to … |
| [N13-T06](N13-quick-entry-the-deck-and-the-keypad/N13-T06-the-two-strips.md) | The two strips | *In the pens*, ascending by `entered_at` — oldest first, because that is the ewe most likely to need something — and *recents*, the last six animals … |
| [N13-T07](N13-quick-entry-the-deck-and-the-keypad/N13-T07-kpumpablevariants-is-born-with-one-entry.md) | `kPumpableVariants` is born, with one entry | The overflow matrix's table is created here with **one** row — `quick_entry` — and its count is **derived from the variant list, never typed**. |

#### [N14 — Quick Entry: the write path](N14-quick-entry-the-write-path/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N14-T01](N14-quick-entry-the-write-path/N14-T01-flockrepositorycreateewe-gated-from-its-first-commit.md) | `FlockRepository.createEwe` — gated from its first commit | `createEwe({required String tag, required EntryContext context})` — the `EntryContext` parameter is **structural**, not a later addition: decision … |
| [N14-T02](N14-quick-entry-the-write-path/N14-T02-lambingrepositorybeginlambing-the-row-exists-before-the-rout.md) | `LambingRepository.beginLambing` — the row exists before the route is pushed | One of only **two** verbs in the app that return an id and throw. |
| [N14-T03](N14-quick-entry-the-write-path/N14-T03-quick-entry-write-controller-through-guard.md) | `quick_entry_write_controller` through `guard()` | The screen's write controller, every mutation through `WriteController.guard()`, with its double-tap test. |
| [N14-T04](N14-quick-entry-the-write-path/N14-T04-feedbackdart-the-receipt-is-the-committed-row.md) | `feedback.dart` — the receipt is the committed row | `confirmSaved` / `showFailure` / `showCapRow`, where the confirmation **is the committed row**, in ink, one line above the one being written. |
| [N14-T05](N14-quick-entry-the-write-path/N14-T05-undo-as-a-time-boxed-strike-in-the-rows-own-margin.md) | Undo as a time-boxed strike in the row's own margin | Undo is a **strike in the margin of the row itself**, its window stated in seconds, and it never survives process death — because an undo that … |
| [N14-T06](N14-quick-entry-the-write-path/N14-T06-tap-budget-testdart-five-taps-to-a-committed-lambing-row.md) | `tap_budget_test.dart` — five taps to a committed lambing row | Unlock → three digits → confirm → *Lambing*. The row is committed on screen entry, so **five taps genuinely produce a committed lambing** — that is … |
| [N14-T07](N14-quick-entry-the-write-path/N14-T07-nothing-about-money-renders-on-a-shed-screen.md) | Nothing about money renders on a shed screen | Decision #90's widget test, sixteen epics before monetization exists: **no monetization widget renders on Quick Entry at any entitlement state or … |

#### [N15 — Media and notes](N15-media-and-notes/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N15-T01](N15-media-and-notes/N15-T01-mediastore-relative-paths-and-nothing-else.md) | `MediaStore` — relative paths, and nothing else | The media root under application support, `newRelativePath` (`media/YYYY/MM/`), `resolve`, `writeAtomically`, and the **one irreversible rule**: only … |
| [N15-T02](N15-media-and-notes/N15-T02-cameraservice-over-image-picker.md) | `CameraService` over `image_picker` | 2048 px longest edge, JPEG q80, **EXIF dropped** — a photo of a ewe carries GPS otherwise, and location data in a shared flock book is a commercially … |
| [N15-T03](N15-media-and-notes/N15-T03-voicerecorder-over-record.md) | `VoiceRecorder` over `record` | AAC-LC `.m4a`, **never opus** — because the file has to open on the vet's laptop and in a mail client, not only on the phone that made it — with … |
| [N15-T04](N15-media-and-notes/N15-T04-noterepository-notes-and-media-assets.md) | `NoteRepository` — `notes` and `media_assets` | The note write with the provenance quad and a **real `occurred_at`** distinct from `created_at` — because a note written at 7am about a 3am event has … |
| [N15-T05](N15-media-and-notes/N15-T05-disk-full-at-3am.md) | Disk full at 3am | The write-ordering rule and the failure mapping that **keeps the record and loses only the file**. |
| [N15-T06](N15-media-and-notes/N15-T06-shedphoto-a-ruled-cell-never-a-thumbnail-grid.md) | `ShedPhoto` — a ruled cell, never a thumbnail grid | A captured photo renders as a **ruled cell under a `ColorFiltered`** — never a card, never a thumbnail grid, never a gallery. |

#### [N16 — Lambing Entry and the P8 ruling](N16-lambing-entry/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N16-T01](N16-lambing-entry/N16-T01-lambingentryprovider-one-statement-for-a-lambingid.md) | `lambingEntryProvider` — one statement for a `LambingId` | One drift statement producing `LambingEntryData` for a `LambingId`: the lambing, its lambs, its care events and its warnings, fanned in **in SQL**. |
| [N16-T02](N16-lambing-entry/N16-T02-the-lamb-tally-strokes-with-a-true-five-bar-gate.md) | The lamb tally — strokes with a true five-bar gate | One slab per lamb as it arrives, drawn as real five-bar-gate strokes, and **birth type derived from the count** and labelled `(COUNTED)`. |
| [N16-T02a](N16-lambing-entry/N16-T02a-rule-p8-against-07-54-and-12-101-and-land-the-sixth-tap.md) | Rule P8 against `07 §5.4` and `12 §10.1`, and land the sixth tap | Two superseded artefacts still prescribe a chooser the product does not have: `07-screens.md` §5.4's *"Declare birth type — 1 tap, five big buttons"* … |
| [N16-T03](N16-lambing-entry/N16-T03-addlamb-and-the-lambs-list.md) | `addLamb` and the lambs list | The second and last verb in the app that returns an id and throws. |
| [N16-T04](N16-lambing-entry/N16-T04-lambing-ease-15-and-setease.md) | Lambing ease 1–5 and `setEase` | The **one surviving segmented choice** in the product, over `ShedChoiceRow`. |
| [N16-T05](N16-lambing-entry/N16-T05-care-events-as-exists.md) | Care events as `EXISTS` | Colostrum (with volume and method), navel dip, stomach tube, warmed — stored as **rows**, so *not recorded* and *no* stay different facts. |
| [N16-T06](N16-lambing-entry/N16-T06-the-warning-strip-a-query-mark-that-adjusts-nothing.md) | The warning strip — a query mark that adjusts nothing | A **declared** birth type that contradicts the strokes prints a query mark in the margin and **adjusts nothing** — neither value moves in the … |
| [N16-T07](N16-lambing-entry/N16-T07-correctoccurredat-and-the-provenance-header.md) | `correctOccurredAt` and the provenance header | A deferred entry's time is editable, and an edited time **prints both times** — the captured one and the corrected one — with its provenance label. … |
| [N16-T08](N16-lambing-entry/N16-T08-assistance-detail-presentation-vocabulary-note-and-attachmen.md) | Assistance detail, presentation vocabulary, note and attachments | Who assisted, the malpresentation vocabulary from `assets/content/`, the free-text note, and the photo and voice-note attachments over N15's gateways. |
| [N16-T09](N16-lambing-entry/N16-T09-the-matrix-variant-and-the-empty-state-row.md) | The matrix variant and the empty-state row | `lambing_entry` joins `kPumpableVariants` and the screen's empty state gets its own row — the two files that keep the variant table honest. |

#### [N17 — Lamb Card](N17-lamb-card/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N17-T01](N17-lamb-card/N17-T01-lambcardprovider-one-statement-rearing-dam-from-the-view.md) | `lambCardProvider` — one statement, rearing dam from the view | One statement producing `LambCardData`, with the **current rearing dam read from the `lamb_rearing` view** rather than from a column — because the … |
| [N17-T02](N17-lamb-card/N17-T02-sex-and-a-birthweight-on-the-apps-own-keypad.md) | Sex, and a birthweight on the app's own keypad | Sex as a committed write on tap, and a birthweight typed on `ShedKeypad` — never the system keyboard — stored in **canonical grams** and shown in the … |
| [N17-T03](N17-lamb-card/N17-T03-death-date-cause-stillborn-and-deathbeforebirth.md) | Death — date, cause, `stillborn`, and `deathBeforeBirth` | A death date, a cause from the **editable** vocabulary, `stillborn` as its own bucket (never *died at age 0*, which is a different fact and a … |
| [N17-T04](N17-lamb-card/N17-T04-pet-lamb-status-and-the-feeding-count.md) | Pet lamb status and the feeding count | Spec §7.3's pet lamb / bottle status with a feeding count — the field that tells a shepherd in April which lambs cost them six weeks of bottles. |
| [N17-T05](N17-lamb-card/N17-T05-the-matrix-variant-and-the-empty-state-row.md) | The matrix variant and the empty-state row | `lamb_card` joins `kPumpableVariants`, with its empty state — a lamb with nothing recorded but its existence, which is the common case in the first … |

#### [N18 — Foster](N18-foster/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N18-T01](N18-foster/N18-T01-fosterrepositoryrecordfoster-append-only-birth-dam-untouched.md) | `FosterRepository.recordFoster` — append-only, birth dam untouched | `FosterOutcome`: to a ewe, to a bottle, or removed unknown. |
| [N18-T02](N18-foster/N18-T02-the-one-tap-reassignment.md) | The one-tap reassignment | Reassignment in **one tap**, reusing Quick Entry's deck query rather than inventing a second one — because two queries for *which ewes are available* … |
| [N18-T03](N18-foster/N18-T03-undo-as-a-compensating-fosterevent-labelled-corrected.md) | Undo as a compensating `FosterEvent` labelled *corrected* | There is no delete here: the undo is a **new event** labelled *corrected*, because the history is the record. |
| [N18-T04](N18-foster/N18-T04-the-fostertoself-warning-and-the-four-rules-this-screen-may.md) | The `fosterToSelf` warning and the four rules this screen may not break | Fostering a lamb to its own birth dam is a warning, not a refusal — a shepherd may be correcting an earlier mistaken foster and the app does not know … |
| [N18-T05](N18-foster/N18-T05-the-matrix-variant-and-the-empty-state-row.md) | The matrix variant and the empty-state row | `foster` joins `kPumpableVariants`, with the extra reachability assertion `12 §6.2` requires for this screen at the smallest device and textScaler … |

#### [N19 — Pen Board](N19-pen-board/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N19-T01](N19-pen-board/N19-T01-penrepositoryenterpen-exitpenpenexitreason.md) | `PenRepository.enterPen` / `exitPen(PenExitReason)` | The database itself refuses two ewes in pen 3 — the partial unique index `WHERE exited_at IS NULL` from N07-T05, not a check in Dart, because the … |
| [N19-T02](N19-pen-board/N19-T02-penboardprovider-and-the-same-projection-quick-entry-reads.md) | `penBoardProvider` and the same projection Quick Entry reads | The pen board reads the **same projection** as Quick Entry's *in the pens* strip. |
| [N19-T03](N19-pen-board/N19-T03-lazy-pen-creation-and-the-zero-pen-board.md) | Lazy pen creation and the zero-pen board | A shepherd who has never made a pen sees **one** 72 pt *Add a pen* tile, not an empty grid and not a setup wizard. |
| [N19-T04](N19-pen-board/N19-T04-hours-since-penned-off-the-one-ticker.md) | Hours since penned, off the one ticker | Elapsed time from N12-T03's single ticker — every tile updating **in the same frame** on the minute boundary — and a ready-to-turn-out threshold … |
| [N19-T05](N19-pen-board/N19-T05-shedpentile-five-statuses-two-non-colour-channels-each.md) | `ShedPenTile` — five statuses, two non-colour channels each | Twelve ruled rows, five statuses, and **every state carrying two non-colour channels** — a word and a mark — because a head torch and a red-shift … |
| [N19-T06](N19-pen-board/N19-T06-turn-out-move-and-mark-as-group-in-one-tap-and-the-edited-ma.md) | Turn out, move and mark-as-group in one tap, and the edited marker | Spec §7.4's three actions, each one tap — and the **edited-entry marker** on the tile, because a pen entry time that was corrected must say so … |
| [N19-T07](N19-pen-board/N19-T07-the-matrix-variant-the-grid-semantics-tree-and-the-empty-sta.md) | The matrix variant, the grid semantics tree and the empty state | `pen_board` joins `kPumpableVariants`, and the grid gets a **real semantics tree** — a board that reads as twelve unlabelled buttons is unusable with … |

#### [N20 — Treatments and withdrawal](N20-treatments-and-withdrawal/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N20-T01](N20-treatments-and-withdrawal/N20-T01-treatmentrepositoryrecordtreatment-and-its-withdrawal-child.md) | `TreatmentRepository.recordTreatment` and its withdrawal child rows | The treatment write and its `treatment_withdrawals` child rows — **meat and milk separately**, per N00-T04's ruling. |
| [N20-T02](N20-treatments-and-withdrawal/N20-T02-the-withdrawal-entry-control-your-entry-no-default-no-placeh.md) | The withdrawal entry control — `YOUR ENTRY`, no default, no placeholder | The control that spec §12.1 exists for: no default, no placeholder, no prefill, no suggestion, no *typical value*, with the caveat **above** it — the … |
| [N20-T03](N20-treatments-and-withdrawal/N20-T03-the-clear-date-as-a-stored-fact-rendered-as-a-day-tally.md) | The clear date as a stored fact, rendered as a day tally | The clear date is computed **once at write time** by N05-T02's function and **stored** — never recomputed for display, because a device that changed … |
| [N20-T04](N20-treatments-and-withdrawal/N20-T04-repeat-last-treatment-two-taps-and-the-days-are-not-copied.md) | Repeat last treatment — two taps, and the days are not copied | Product, dose, route and batch are copied; **the withdrawal days are not**, and the row says so: `DAYS NOT COPIED — READ THE BOTTLE`. |
| [N20-T05](N20-treatments-and-withdrawal/N20-T05-voidtreatment-a-soft-void-the-medicine-book-still-shows.md) | `voidTreatment` — a soft void the medicine book still shows | A treatment may already have been printed and handed to a vet, so a void is **soft**: the row is struck (P1's columns), the medicine book still shows … |
| [N20-T06](N20-treatments-and-withdrawal/N20-T06-treatmentsprovidertreatmentmode-the-countdowns-and-the-disag.md) | `treatmentsProvider(TreatmentMode)`, the countdowns and the disagreement badge | One statement per mode — log, countdowns, medicine book — plus the `clearDateDisagrees` badge from N05-T05, which shows both numbers and changes … |
| [N20-T07](N20-treatments-and-withdrawal/N20-T07-the-12-disclosures-the-matrix-variant-and-the-two-tap-budget.md) | The §12 disclosures, the matrix variant and the two-tap budget | §12.1's *as entered by you*, §12.3's *this is not a statutory medicine book*, and §12.5's provenance on every row — all referenced from `Disclaimers`. |

#### [N21 — Export: CSV, PDF and share](N21-export-csv-pdf-and-share/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N21-T01](N21-export-csv-pdf-and-share/N21-T01-csvwriter-hand-rolled-rfc-4180.md) | `CsvWriter` — hand-rolled RFC 4180 | Hand-rolled because the quoting rules are the whole job and a dependency for them is a dependency to audit: the quoting rules, UTF-8 with a BOM … |
| [N21-T02](N21-export-csv-pdf-and-share/N21-T02-the-three-shapes-and-their-verbatim-header-rows.md) | The three shapes and their verbatim header rows | One row per lamb, one row per ewe, one row per treatment — spec §7.9's three shapes, each with its **verbatim** header row. |
| [N21-T03](N21-export-csv-pdf-and-share/N21-T03-the-disclaimer-trailers-referenced-and-never-re-typed.md) | The disclaimer trailers, referenced and never re-typed | §12.3 in the footer of every artefact — referenced from `Disclaimers`, never re-typed, and proved by a test that greps the source. |
| [N21-T04](N21-export-csv-pdf-and-share/N21-T04-pdf-writerdart-one-builder-one-embedded-font.md) | `pdf_writer.dart` — one builder, one embedded font | One builder, the **mandatory embedded TTF** — a PDF with a non-embedded font renders as tofu on the vet's machine — and the page furniture: title … |
| [N21-T05](N21-export-csv-pdf-and-share/N21-T05-the-flock-book-in-two-volumes-and-the-medicine-record.md) | The flock book in two volumes and the medicine record | Built **off the UI isolate** — a 400-ewe flock book on the main isolate is a frozen phone — and split at the row cap into two volumes, because a … |
| [N21-T06](N21-export-csv-pdf-and-share/N21-T06-shareservice-the-share-sheet-and-nowhere-else.md) | `ShareService` — the share sheet and nowhere else | Delivery through the system share sheet and **nowhere else**, always as a file path. |
| [N21-T07](N21-export-csv-pdf-and-share/N21-T07-exportrepository-exportcountsprovider-and-the-export-screen.md) | `ExportRepository`, `exportCountsProvider` and the Export screen | `ExportRepository` does **read and artefact assembly only** — it writes nothing, per `CONVENTIONS §2.13`, which is why `SettingsRepository` came … |
| [N21-T08](N21-export-csv-pdf-and-share/N21-T08-the-end-of-day-export-banner.md) | The end-of-day export banner | Once per **local civil day**, never mid-entry, never between 22:00 and 06:00, dismissible for the season — and it is matrix variant 14, *Quick Entry … |

#### [N22 — The JSON backup format](N22-the-json-backup-format/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N22-T01](N22-the-json-backup-format/N22-T01-backup-formatdart-backupheader-and-the-canonical-encoder.md) | `backup_format.dart` — `BackupHeader` and the canonical encoder | The header, the canonical encoder — stable key order, stable number formatting, so two exports of the same data are byte-identical and the round-trip … |
| [N22-T02](N22-the-json-backup-format/N22-T02-writebackup-every-restorable-table-four-exclusions-named.md) | `writeBackup` — every restorable table, four exclusions named | All 21 restorable tables including `vocab_terms` — a shepherd who renamed *ewe* to *gimmer* and edited the death-cause list must get those back … |
| [N22-T03](N22-the-json-backup-format/N22-T03-forward-compatibility-unknown-json-round-trips.md) | Forward compatibility — `unknown_json` round-trips | A column a **newer** build wrote survives a round trip through an older one: it lands in `unknown_json` and is re-emitted at the row's top level. |
| [N22-T04](N22-the-json-backup-format/N22-T04-the-checksum-described-without-the-words-verified-or-secure.md) | The checksum, described without the words *verified* or *secure* | A checksum that detects **accidental corruption** — a truncated AirDrop, a bad SD card — and nothing else. |
| [N22-T05](N22-the-json-backup-format/N22-T05-file-import-through-file-selector-with-the-magic-bytes-valid.md) | File import through `file_selector`, with the magic bytes validated by us | Import through the platform picker, and **we** validate the magic bytes — not the picker's extension filter, which on Android is a suggestion and on … |

#### [N23 — Restore, the sweeps and the seed](N23-restore-the-sweeps-and-the-seed/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N23-T01](N23-restore-the-sweeps-and-the-seed/N23-T01-restoreservice-a-new-file-beside-the-live-one.md) | `RestoreService` — a new file beside the live one | Restore never writes into the live database. It builds a **new file beside it**, validates it, swaps, reopens — and `completeInterruptedRestore` … |
| [N23-T02](N23-restore-the-sweeps-and-the-seed/N23-T02-the-restore-confirmation-that-names-what-it-will-destroy.md) | The restore confirmation that names what it will destroy | Two steps, and the first one **states plainly what will be destroyed** — this many ewes, this many lambings, this many treatments, counted from the … |
| [N23-T03](N23-restore-the-sweeps-and-the-seed/N23-T03-mediasweeper-both-directions.md) | `MediaSweeper` — both directions | Files with no row and rows with no file. The first wastes a shepherd's storage in March; the second is a broken image on the Ewe Card and is recorded … |
| [N23-T04](N23-restore-the-sweeps-and-the-seed/N23-T04-toolseeddart-writing-its-demo-database-through-the-restore-p.md) | `tool/seed.dart` — writing its demo database through the restore path | `dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42`, deterministic, writing **through `RestoreService`** rather than through the repositories. |
| [N23-T05](N23-restore-the-sweeps-and-the-seed/N23-T05-the-two-committed-fixtures-and-the-matrix-switch.md) | The two committed fixtures, and the matrix switch | `flock_400_3seasons.json` and `flock_15_at_cap.json`, generated by the seed and committed as **their own commit** — they are generated artefacts … |
| [N23-T06](N23-restore-the-sweeps-and-the-seed/N23-T06-restoreinto-and-freshsupportdir-in-the-harness.md) | `restoreInto` and `freshSupportDir()` in the harness | The harness gains the two members `09 §7.3` calls and `12` declares: `restoreInto` and `freshSupportDir()`, a temp directory torn down with the test. |
| [N23-T07](N23-restore-the-sweeps-and-the-seed/N23-T07-the-export-import-export-equality-property.md) | The export → import → export equality property | The property that holds the whole format together: export, import into a fresh database, export again — and the two files are equal. |

#### [N24 — Reminders: rows, reconcile and the fixtures](N24-reminders-rows-reconcile-and-the-fixtures/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N24-T01](N24-reminders-rows-reconcile-and-the-fixtures/N24-T01-reminderbudgetforplatform-56-on-ios-200-on-android.md) | `ReminderBudget.forPlatform()` — 56 on iOS, 200 on Android | The OS caps, in one place, with the flock that breaks the naive design written into the test name: several hundred stored reminders and only the … |
| [N24-T02](N24-reminders-rows-reconcile-and-the-fixtures/N24-T02-notificationscheduler-the-seam-and-its-fake.md) | `NotificationScheduler` — the seam and its fake | The gateway, the app's **only** `package:timezone` call site, and `FakeNotificationScheduler` with its loud tripwires: a duplicate id, more than the … |
| [N24-T03](N24-reminders-rows-reconcile-and-the-fixtures/N24-T03-the-six-android-channels-ids-frozen-at-release.md) | The six Android channels, ids frozen at release | Six channels — colostrum, navel dip, turn out, tag-by, ring/dock/castrate, withdrawal end — with **ids frozen at release**, because an Android … |
| [N24-T04](N24-reminders-rows-reconcile-and-the-fixtures/N24-T04-reminderrepository-and-rows-written-inside-the-event-transac.md) | `ReminderRepository`, and rows written inside the event transactions | Decision #63: the reminder row is written **inside** the lambing and treatment transactions, not after them. |
| [N24-T05](N24-reminders-rows-reconcile-and-the-fixtures/N24-T05-reminderreconcilerreconcile-idempotent-debounced-four-call-s.md) | `ReminderReconciler.reconcile()` — idempotent, debounced, four call sites | Rebuild the OS projection from the rows: `cancelAll()`, then project the soonest N. |
| [N24-T06](N24-reminders-rows-reconcile-and-the-fixtures/N24-T06-permissions-reboot-and-dst.md) | Permissions, reboot and DST | `POST_NOTIFICATIONS` requested at the **first reminder** and never at launch — spec §5's *zero interruptions* includes a permission dialog at 3am … |
| [N24-T07](N24-reminders-rows-reconcile-and-the-fixtures/N24-T07-handling-a-tap-route-to-the-record-then-re-reconcile.md) | Handling a tap — route to the record, then re-reconcile | A tapped notification routes to the **record**, not to a list, and then re-reconciles — because the tap consumed one of the projected slots and the … |
| [N24-T08](N24-reminders-rows-reconcile-and-the-fixtures/N24-T08-regenerate-and-re-commit-both-fixtures.md) | Regenerate and re-commit both fixtures | The fixtures were generated in N23 — one epic before reminder rows had a writer — so `flock_400_3seasons.json` contains **no reminders**, and every … |

#### [N25 — Reminders screen](N25-reminders-screen/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N25-T01](N25-reminders-screen/N25-T01-remindersprovider-and-remindersview-three-groups-off-the-tic.md) | `remindersProvider` and `RemindersView` — three groups off the ticker | One statement, three groups — due today, overdue, upcoming — with the day boundaries computed from N12-T03's ticker so the groups re-sort themselves … |
| [N25-T02](N25-reminders-screen/N25-T02-the-honest-windowed-line.md) | The honest windowed line | *"56 of 312 reminders are on your phone's list."* **Both numbers read from data** — the budget from `ReminderBudget.forPlatform()` and the count from … |
| [N25-T03](N25-reminders-screen/N25-T03-completing-a-reminder-writes-the-domain-fact.md) | Completing a reminder writes the domain fact | The tap that ticks *colostrum given* writes the `CareEvent` — the reminder is not a to-do list, it is a prompt to record a fact, and completing it … |
| [N25-T04](N25-reminders-screen/N25-T04-mute-as-a-strike-and-nothing-that-nags-twice.md) | Mute as a strike, and nothing that nags twice | Spec §7.6: *nothing nags twice*. Mute is a **strike** on the row — visible, reversible, never a deletion — and a muted reminder is never re-projected. |
| [N25-T05](N25-reminders-screen/N25-T05-reminder-intervals-as-reminder-rules-user-configurable.md) | Reminder intervals as `reminder_rules`, user-configurable | Spec §7.6: *all intervals user-configurable*. |
| [N25-T06](N25-reminders-screen/N25-T06-the-matrix-variant-and-the-empty-state-that-explains-itself.md) | The matrix variant and the empty state that explains itself | `reminders` joins `kPumpableVariants`, and the empty state **explains where reminders come from** — a screen that says *no reminders* to a shepherd … |

#### [N26 — Flock and Note Search](N26-flock-and-note-search/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N26-T01](N26-flock-and-note-search/N26-T01-flocklistprovider-and-flockrow-one-statement.md) | `flockListProvider` and `FlockRow` — one statement | One statement producing the list, with the search box reusing `rankTagMatches` — the same ranking Quick Entry uses, so a shepherd who learned it at … |
| [N26-T02](N26-flock-and-note-search/N26-T02-the-five-filters-and-a-filtered-empty-state-of-its-own.md) | The five filters and a filtered-empty state of its own | Spec §7.7's filters — barren, not yet lambed, triplet-bearing, currently penned, under treatment — and a **filtered-empty** state whose copy is not … |
| [N26-T03](N26-flock-and-note-search/N26-T03-the-88-px-ewe-row-the-124-warning-badge-and-the-culled-tag-m.md) | The 88 px ewe row, the §12.4 warning badge and the culled-tag marker | The row over `ShedAnimalRow`, with the §12.4 warning badge — a ewe whose records contradict themselves says so in the list — and the culled-tag … |
| [N26-T04](N26-flock-and-note-search/N26-T04-add-a-ewe-from-the-bottom-bar-through-the-same-gated-verb.md) | Add a ewe from the bottom bar, through the same gated verb | The same `createEwe` verb Quick Entry uses, with `EntryContext.deliberate` rather than `liveEntry` — which is the one place the cap may honestly … |
| [N26-T05](N26-flock-and-note-search/N26-T05-notesearchprovider-fts5-with-a-200-ms-debounce.md) | `noteSearchProvider` — FTS5 with a 200 ms debounce | The thirteenth route: an `autoDispose` family over FTS5 with a 200 ms debounce. |
| [N26-T06](N26-flock-and-note-search/N26-T06-searchhit-rendering-navigation-and-the-three-distinct-empty.md) | `SearchHit` rendering, navigation, and the three distinct empty strings | A hit renders with enough context to be recognisable and navigates to **the record the note belongs to**. |
| [N26-T07](N26-flock-and-note-search/N26-T07-two-matrix-variants-flock-and-note-search.md) | Two matrix variants — `flock` and `note_search` | Both routes join `kPumpableVariants`, taking the table to a count the arithmetic derives. |

#### [N27 — Ewe Card](N27-ewe-card/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N27-T01](N27-ewe-card/N27-T01-ewetimelineprovider-the-fan-in-done-in-sql.md) | `eweTimelineProvider` — the fan-in done in SQL | One statement producing `TimelineRow` — lambings, treatments, fosters, observations, notes, pen occupancies — with the fan-in **in SQL**, because six … |
| [N27-T02](N27-ewe-card/N27-T02-the-one-line-summary-assembled-in-dart-from-counts.md) | The one-line summary, assembled in Dart from counts | *"3 seasons · avg 2.0 · assisted twice · prolapsed 2025."* Assembled **in Dart from `ewe_summaries` counts**, never read as a string frozen in the … |
| [N27-T03](N27-ewe-card/N27-T03-ewe-summaries-rebuilt-inside-the-writes-that-invalidate-it.md) | `ewe_summaries` rebuilt inside the writes that invalidate it | The counts are maintained by the writes that change them — `LambingRepository`'s (N14) and `FosterRepository`'s (N18). |
| [N27-T04](N27-ewe-card/N27-T04-timeline-rows-with-provenance-and-every-withdrawal-as-entere.md) | Timeline rows with provenance, and every withdrawal *as entered by you* | Every event carries its provenance label; every withdrawal carries *as entered by you*. §12.5 and §12.1 rendered on the one screen where a shepherd … |
| [N27-T05](N27-ewe-card/N27-T05-there-was-an-earlier-412-the-reused-tag-disclosure.md) | *"There was an earlier 412"* — the reused-tag disclosure | The active-only uniqueness ruling has a consequence a shepherd must be told about: a reused tag means two animals share a number, and the card says … |
| [N27-T06](N27-ewe-card/N27-T06-the-cards-actions-and-eweobservations.md) | The card's actions and `EweObservations` | The actions a shepherd takes from the card, and `EweObservations` written from the **seeded vocabulary** — prolapse, mastitis, poor mothering … |
| [N27-T07](N27-ewe-card/N27-T07-the-heading-hierarchy-the-matrix-variant-and-the-empty-state.md) | The heading hierarchy, the matrix variant and the empty state | A real heading hierarchy, so a screen reader jumps **straight to the summary line** — which is the whole point of the screen and is otherwise buried … |

#### [N28 — Season Summary](N28-season-summary/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N28-T01](N28-season-summary/N28-T01-seasonrepositorywatchseasoncounts-customselect-with-explicit.md) | `SeasonRepository.watchSeasonCounts` — `customSelect` with explicit `readsFrom:` | The season's counts in one `customSelect` with an explicit `readsFrom:` — **never** a `groupBy` in a Dart view, which produces a stream that does not … |
| [N28-T02](N28-season-summary/N28-T02-the-statistics-as-rendered-definition-numerator-denominator.md) | The statistics as rendered — definition, numerator, denominator, caveats | Each statistic renders **with its verbatim definition**, its numerator and denominator, and its caveats. |
| [N28-T03](N28-season-summary/N28-T03-watchspread-dense-zero-filled-grouped-by-the-denormalised-ci.md) | `watchSpread` — dense, zero-filled, grouped by the denormalised civil date | Grouped by the **denormalised local civil date** column — not computed from an instant at query time, which would put a 23:40 lambing on the wrong … |
| [N28-T04](N28-season-summary/N28-T04-the-hand-rolled-spread-chart.md) | The hand-rolled spread chart | A `CustomPainter` and a `semanticsBuilder` — **no chart library**, no axis furniture, no legend, no tooltip, no colour encoding and no animation. |
| [N28-T05](N28-season-summary/N28-T05-comparison-against-previous-seasons-once-they-exist.md) | Comparison against previous seasons, once they exist | Spec §7.8's comparison — and the honest empty case: in season one there is nothing to compare to, and the screen says that rather than rendering a … |
| [N28-T06](N28-season-summary/N28-T06-the-three-data-shapes-as-states-the-matrix-variant-and-the-e.md) | The three data shapes as states, the matrix variant and the empty season | No data, some data, a full season — three states, each with its own box, and `season_summary` joining `kPumpableVariants`. |

#### [N29 — Settings](N29-settings/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N29-T01](N29-settings/N29-T01-settings-screen-composition-over-the-repository-built-in-n12.md) | Settings screen composition over the repository built in N12 | `SettingsRepository` already exists (N12-T02) with its parameterised persist-and-re-read test; this is the **screen**. |
| [N29-T02](N29-settings/N29-T02-units-kg-lb-and-c-f-converted-only-at-the-display-edge.md) | Units — kg / lb and °C / °F, converted only at the display edge | The setting changes the **display**, never the storage. |
| [N29-T03](N29-settings/N29-T03-terminology-editing-through-terminology-overrides.md) | Terminology editing through `terminology_overrides` | Rename *ewe* to *gimmer* and the whole app says gimmer — including the ARB messages, which carry the term as a **placeholder** fed by … |
| [N29-T04](N29-settings/N29-T04-palette-high-contrast-the-left-handed-mirror-and-wakelockcon.md) | Palette, high contrast, the left-handed mirror, and `WakelockController` | The appearance settings — plus the **`WakelockController` gateway and its fake**, which the old plan described as a setting and never gave a seam. |
| [N29-T05](N29-settings/N29-T05-season-start-date-season-switching-and-startseason.md) | Season start date, season switching and `startSeason` | The second of the two cap-gated verbs. Switching seasons changes what every screen reads; the season start date is the boundary the spread and the … |
| [N29-T06](N29-settings/N29-T06-the-only-two-honest-deletes-in-the-app.md) | The only two honest deletes in the app | Delete a season and delete everything — the only `canPop: false` flow in the product, and the only two places anything is genuinely destroyed. |
| [N29-T07](N29-settings/N29-T07-diagnostics-and-about.md) | Diagnostics and About | The redacted diagnostics log, the `VACUUM INTO` snapshot for support, and About carrying §12.3's wording and the offline paragraph from N02-T02 … |
| [N29-T08](N29-settings/N29-T08-the-matrix-variant-and-the-deliberate-friction.md) | The matrix variant and the deliberate friction | `settings` joins `kPumpableVariants`, and the friction is asserted: nothing on this screen is a one-tap destructive action, and nothing on it is … |

#### [N30 — Monetization](N30-monetization/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N30-T01](N30-monetization/N30-T01-purchaseservice-the-store-seam-and-its-fake.md) | `PurchaseService` — the store seam and its fake | The seventh gateway: `kUnlockProductId`, `PurchaseSignal`, `StoreUnreachable`, and `FakePurchaseService`. |
| [N30-T02](N30-monetization/N30-T02-entitlementrepository-and-the-entitlement-row.md) | `EntitlementRepository` and the entitlement row | The entitlement as a **row**, with its three rules: it is set by a store signal only, it is never cleared by a failure to reach the store, and it … |
| [N30-T03](N30-monetization/N30-T03-unlockcontroller-and-unlockstates-four-variants.md) | `UnlockController` and `UnlockState`'s four variants | Purchase, restore, double taps — and **why `pending` is not one of the variants**: `pending` is a banned model state (`CLAUDE.md`), and a purchase … |
| [N30-T04](N30-monetization/N30-T04-wire-the-entitlement-source-into-the-two-gated-verbs.md) | Wire the entitlement source into the two gated verbs | `FreeTierPolicy` has been consulted by `createEwe` since N14-T01 and by `startSeason` since N29-T05; what has been missing is the **entitlement … |
| [N30-T05](N30-monetization/N30-T05-the-two-static-upgrade-rows-and-showcaprow.md) | The two static upgrade rows and `showCapRow` | Two rows, four hard constraints: never on a shed screen, never mid-entry, never between 22:00 and 06:00, never modal. |
| [N30-T06](N30-monetization/N30-T06-the-price-read-from-productdetailsprice-never-a-literal.md) | The price read from `ProductDetails.price`, never a literal | The price comes from the store, always — never a literal, **including in assets** and including in the store listing copy the app renders. |
| [N30-T07](N30-monetization/N30-T07-store-artefacts-privacyinfoxcprivacy-the-data-safety-form-st.md) | Store artefacts — `PrivacyInfo.xcprivacy`, the data-safety form, `*.storekit` | Apple's **genuine** *Data Not Collected* declaration, Play's data-safety form filled in to match, and `ios/Configuration.storekit` — the offline … |
| [N30-T08](N30-monetization/N30-T08-the-at-cap-tests-and-no-money-on-any-shed-screen.md) | The at-cap tests, and no money on **any** shed screen | The at-cap behaviour against `flock_15_at_cap.json`, and N14-T07's assertion extended from Quick Entry to **all five shed screens**, at every … |

#### [N31 — Platform artefacts, G1, G4 and G5](N31-platform-artefacts-g1-g4-and-g5/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N31-T01](N31-platform-artefacts-g1-g4-and-g5/N31-T01-androidexpected-permissionstxt-and-the-toolsnode-remove-line.md) | `android/expected_permissions.txt` and the `tools:node="remove"` line G0 proved | The permission list, exactly as G0 recorded it at N02, and the one removal directive the evidence supports. |
| [N31-T02](N31-platform-artefacts-g1-g4-and-g5/N31-T02-android-build-configuration.md) | Android build configuration | `targetSdk` / `compileSdk` 36, an **explicit** `minSdk` 24, Java 17, core-library desugaring, and the two receivers reminders need. |
| [N31-T03](N31-platform-artefacts-g1-g4-and-g5/N31-T03-toolassert-permissionssh-g1-the-android-job-and-the-g4-archi.md) | `tool/assert_permissions.sh` (G1), the `android` job and the G4 archive | G1 executable: build the release AAB in CI, dump its merged manifest, and diff against `expected_permissions.txt`. |
| [N31-T04](N31-platform-artefacts-g1-g4-and-g5/N31-T04-ios-the-three-usage-strings-the-appearance-key-and-g5.md) | iOS — the three usage strings, the appearance key, and G5 | Camera, microphone and photo-library usage strings written as a shepherd would read them, the dark appearance key, **no ATS exception** — and G5 as … |

#### [N32 — Signing and the closed track opens](N32-signing-and-the-closed-track/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N32-T01](N32-signing-and-the-closed-track/N32-T01-signing-the-upload-keystore-play-app-signing-and-the-ios-hal.md) | Signing — the upload keystore, Play App Signing and the iOS half | The upload keystore, `key.properties` **gitignored** and regenerable from the keystore and its passwords, Play App Signing enrolled, and the iOS … |
| [N32-T02](N32-signing-and-the-closed-track/N32-T02-the-play-app-record-and-the-store-listing-draft.md) | The Play app record and the store listing draft | The app record, and the listing draft carrying **N02-T02's honesty paragraph** — written at epic 2 precisely so it could be used here without … |
| [N32-T03](N32-signing-and-the-closed-track/N32-T03-open-the-closed-track-and-testflight-the-fourteen-day-clock.md) | Open the closed track and TestFlight — the fourteen-day clock starts | The first signed AAB reaches a Play closed track with the twelve testers recruited in N00-T07, and the iOS build reaches TestFlight. |

#### [N33 — Ship gates: the sweeps, the matrix, the goldens and the journeys](N33-ship-gates-sweeps-goldens-and-journeys/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N33-T01](N33-ship-gates-sweeps-goldens-and-journeys/N33-T01-the-overflow-matrix-at-its-final-size.md) | The overflow matrix at its final size | Fourteen variants × 3 devices × 3 text scales × 2 bold states = **252 cells**, with the count **derived from the variant list, never typed**. |
| [N33-T02](N33-ship-gates-sweeps-goldens-and-journeys/N33-T02-the-semantics-sweep-and-its-canary.md) | The semantics sweep and its canary | The tree-walking guidelines plus the headings assertion across all fourteen variants — and the **canary that proves the gate can fail**, because a … |
| [N33-T03](N33-ship-gates-sweeps-goldens-and-journeys/N33-T03-the-tap-target-sweep-the-geometric-gate-and-the-p9-ruling.md) | The tap-target sweep, the geometric gate and the P9 ruling | The geometric gate over fourteen variants × three devices × two text scales, with the 40 × 40 canary failing the 60 pt guideline. |
| [N33-T04](N33-ship-gates-sweeps-goldens-and-journeys/N33-T04-reachability-and-colour-never-alone-across-every-state.md) | Reachability and colour-never-alone across every state | The primary action stays reachable without scrolling on the smallest device at textScaler 1.3 — for Quick Entry **with the banner shown**, Lambing … |
| [N33-T05](N33-ship-gates-sweeps-goldens-and-journeys/N33-T05-the-arb-completeness-sweep.md) | The ARB completeness sweep | Every user-facing string is an ARB key with a `description`, and **no domain noun appears as a literal** anywhere. |
| [N33-T06](N33-ship-gates-sweeps-goldens-and-journeys/N33-T06-apples-accessibility-nutrition-label-and-the-per-screen-swee.md) | Apple's Accessibility Nutrition Label and the per-screen sweep | The declaration, and the per-screen sweep behind it — because the label is a claim, and a claim about accessibility that no test holds is the same … |
| [N33-T07](N33-ship-gates-sweeps-goldens-and-journeys/N33-T07-the-eight-goldens-in-their-own-commit.md) | The eight goldens, in their own commit | Eight images — the budget — with real fonts loaded and a tolerant comparator, and **the PNGs in their own commit**, per `00-README` §7.4's rule that … |
| [N33-T08](N33-ship-gates-sweeps-goldens-and-journeys/N33-T08-the-four-integration-journeys-and-make-integration.md) | The four integration journeys and `make integration` | Four journeys through the real app on a real device — reported, **never blocking**, because an integration suite in the blocking set is a suite that … |
| [N33-T09](N33-ship-gates-sweeps-goldens-and-journeys/N33-T09-goldensyml-the-images-verified-by-ci-in-the-epic-that-create.md) | `goldens.yml` — the images verified by CI in the epic that created them | macOS, on a tag or manual dispatch only — never a per-PR gate, because the macOS runner bills at a 10× multiplier and a per-push job burns the free … |

#### [N34 — Release engineering](N34-release-engineering/epic.md)

| Task | Title | What it does |
|---|---|---|
| [N34-T01](N34-release-engineering/N34-T01-releaseyml-the-version-rules-and-the-app-size-budget.md) | `release.yml`, the version rules and the app-size budget | The release workflow on tag `v*`, with `--analyze-size` and the app-size budget — plus the version-name and build-number rules recorded in … |
| [N34-T02](N34-release-engineering/N34-T02-obfuscation-and-the-off-machine-symbols-archive.md) | Obfuscation and the off-machine symbols archive | `--obfuscate --split-debug-info`, and the symbols archived under `symbols-archive/<name>+<build>/` — **kept forever, off the laptop, never in git**. |
| [N34-T03](N34-release-engineering/N34-T03-startup-measured-on-two-real-devices-in-profile-mode.md) | Startup measured on two real devices, in profile mode | The numbers that decide whether the first-frame work in N11 actually paid off — measured in **profile** mode on two real devices, one of them the … |
| [N34-T04](N34-release-engineering/N34-T04-the-seasonal-freeze-and-the-manual-pre-release-checklist.md) | The seasonal freeze and the manual pre-release checklist | **Never tag between 1 February and 30 April** except for a data-loss-class hotfix — the calendar rule that outranks everything else in this epic … |

---

## 4. The delivery loop

One epic, one branch, one pull request, one merge. Then delete the branch and do it again.

### 4.1 The branch

```
epic/<nnn>-<short-slug>
```

Lower case, hyphens, `epic/` prefix, and **the exact string is the one in the epic file's `Branch`
row** — it is not derived from the directory name and several of them are deliberately shorter
(`N01-the-tree-the-configs-and-the-ci-shell` → `epic/n01-tree-configs-ci`). Copy it; do not
reconstruct it.

```bash
git switch main && git pull                       # the merged main, not yesterday's
git switch -c epic/n04-domain-time-and-units      # the string from the epic file
```

Cut it from the **merged** `main` after the previous epic went in. Never from another epic branch,
never from a stale local `main` — this backlog's whole shape assumes each epic starts on top of the
last one's merge commit.

### 4.2 The commit

[Conventional Commits](https://www.conventionalcommits.org): `type(scope): subject`, lower case,
imperative, no trailing full stop. **The exact message is in the task file's `Commit` row** —
it was written with the task and it is what makes `git log` readable as the task index.

```
feat(domain): clearDateFor ceils to the next local midnight
test(policy): five taps from launch to a committed lambing row
ci: goldens.yml, on tags and dispatch only
docs: add the calendar ledger and the test that keeps it honest
```

The types in use are `feat`, `test`, `docs`, `ci`, `chore` and `fix`; the scope is the layer or the
feature (`domain`, `data`, `db`, `ui`, `core`, `features`, `export`, `reminders`, `gateway`,
`monetization`, `android`, `ios`, …). **The vocabulary rules apply to the message.** No `draft`, no
`save()`, no `sync`, no `Error` as a failure name, one word per concept — a commit message is prose
this project will read for years.

### 4.3 The loop, step by step

1. **Read the epic file.** Goal, sources, task list, Definition of Done, what is demoable on merge.
   Then read `docs/calendar.md` — §6 — because a commitment nobody looks at is not a commitment.
2. **Cut the branch** from the merged `main`, using §4.1's exact string.
3. **Work the tasks in order.** For each one: read the task file · load the two or three skills it
   names · write the anchor test · watch it fail for the stated reason · write the minimum code ·
   refactor green · walk the Definition of Done · run the Verification block · then `/simplify`,
   `/code-review`, `/shed-code-review` · then **one commit** with the task's own message.
   Do not batch tasks and do not reorder them; the `Depends on` row is why they are in this order.
4. **Close the epic.** Run `/shed-code-review` over the **whole branch**, in irreversibility order —
   schema first, then anything that writes, then presentation. This is the last cheap moment to
   catch a schema mistake.
5. **Open the pull request.** Answer the five §12 safety questions in the body; they are the
   template's, verbatim, and they are where the safety review actually happens. Title the PR with
   the epic. Push.
6. **Wait for the pipelines** — §5. Do not merge on a partial green and do not start the next epic
   while this one is red; the next epic is cut from this merge.
7. **Fix what CI raises, on this branch.** A gate failure names its rule id — look it up in
   `tool/check_policy.dart`'s rule table rather than working around it. A `codegen` failure means a
   generated file is stale: regenerate, read the diff, commit it. A fix commit is a normal commit
   with a normal message; it does not need a task.
8. **Merge into `main`** once every blocking job is green.
9. **Confirm `main` is green after the merge**, then **delete the branch** locally and on the remote.
10. **Start the next epic** from step 1, on the freshly merged `main`.

```bash
git switch main && git pull
git branch -d epic/n04-domain-time-and-units
git push origin --delete epic/n04-domain-time-and-units
```

---

## 5. What the pipelines check, and how long to wait

Six workflows exist by the end of the backlog; they arrive as the tasks that write them land, which
is why each epic file names the ones its pull request will actually run.

| Job | Runs on | Checks | Cap | Blocking | First written by |
|---|---|---|---|---|---|
| `gate` | every push, every PR · `ubuntu-latest` | toolchain pin equals `.fvmrc` · `pub get` · `check_policy` (**G2** dependency allowlist + **G3** import scan) · `dart format --set-exit-if-changed` · `analyze --fatal-infos --fatal-warnings` · the iOS ATS text check (**G5** half) | 15 min | Yes | [N01-T06](N01-the-tree-the-configs-and-the-ci-shell/N01-T06-githubworkflowsciyml-the-gate-and-test-jobs.md), wired first in [N03-T07](N03-the-gate/N03-T07-wire-the-gate-into-ci-and-assert-the-rule-inventory-is-compl.md) |
| `codegen` | every push, every PR · `ubuntu-latest` | `build_runner build` + `drift_dev make-migrations`, then `git diff --exit-code` over `lib/`, `drift_schemas/` and `test/drift/generated/` — a stale generated file cannot merge | 20 min | Yes | [N08-T06](N08-the-migration-harness-and-the-codegen-job/N08-T06-the-codegen-ci-job.md) |
| `test` | every push, every PR · `ubuntu-latest` + `libsqlite3-dev` | `-P ci-fast` in randomised order · the whole suite again under `TZ=Europe/London --tags uk-zone` · `test/domain` under `TZ=Pacific/Chatham` · coverage archived, never gated | 25 min | Yes | [N01-T06](N01-the-tree-the-configs-and-the-ci-shell/N01-T06-githubworkflowsciyml-the-gate-and-test-jobs.md) |
| `android` | every push, every PR · `ubuntu-latest` | builds the release AAB, dumps its **merged** manifest and diffs it against `android/expected_permissions.txt` (**G1**); archives the merger report (**G4**) | 30 min | Yes | [N31-T03](N31-platform-artefacts-g1-g4-and-g5/N31-T03-toolassert-permissionssh-g1-the-android-job-and-the-g4-archi.md) |
| `release` | tag `v*` · `ubuntu-latest` | signed AAB with the run number as the build number · **G1** again · `--analyze-size` JSON · symbols · all artefacts | 35 min | Yes | [N34-T01](N34-release-engineering/N34-T01-releaseyml-the-version-rules-and-the-app-size-budget.md) |
| `goldens` | tag `v*` **or** manual dispatch · `macos-latest` | `flutter test -P ci-golden` — the eight images | 20 min | Yes when it runs | [N33-T09](N33-ship-gates-sweeps-goldens-and-journeys/N33-T09-goldensyml-the-images-verified-by-ci-in-the-epic-that-create.md) |

**On the numbers.** The column is the `timeout-minutes` **cap**, not a measurement — the doc set
records no measured job durations, because no job has run yet. Treat them as the ceiling: a job that
approaches its cap is a job to investigate, and the first real durations should be written down the
first week `main` is green. In practice `gate` fails in seconds when it fails at all — that is why
it is the first job and why `make check` runs `check_policy` before the formatter and the analyzer.

**Why `goldens` is not a per-PR gate.** GitHub bills macOS minutes at a **10× multiplier**, and a
free private repository's 2,000 minutes is **200 macOS minutes a month**. A per-push macOS job burns
the quota in a week. The eight images change only on a deliberate re-baseline, so they are verified
on a tag or by dispatching the workflow by hand — which is what N33 does to prove them in the epic
that creates them.

**Not in CI at all, on purpose.** The four integration journeys run on your own desk with a phone
plugged in (`make integration DEVICE=…`), **reported and never blocking** — an integration suite in
the blocking set is a suite that gets deleted the first week it is flaky. Startup and frame timings
need profile mode on real hardware, which hosted runners cannot give; they are measured once per
release into `docs/perf/measurements.md`. The iOS archive is a five-minute manual step on the
developer's Mac.

**Locally, before you push:** `make check` (sub-second, then seconds, then tens of seconds — cheapest
failure first), then `make test`, then `make validate`.

---

## 6. The calendar-blocking items — start these today

Four things on the critical path are not code, cannot be compressed by working harder, and are the
only items in this backlog whose lead time is measured in weeks.

**[`docs/calendar.md`](../docs/calendar.md) is the ledger, and it is the list.** It exists as of
[N00-T06](N00-decisions-rulings-and-the-calendar/N00-T06-docscalendarmd-and-the-ledger-test-that-stays-red-until-it-i.md):
seven rows, each with a key, an owner, a due point, a recorded date, an outcome and — the column that
makes it a commitment rather than a wish — what happens if it does not happen. It is held by
`test/policy/calendar_commitments_test.dart`, which **stays red until every row is filled and names
the incomplete rows by key**. That test is tagged `calendar` and excluded from the blocking set until
N32 — deliberately, because a commitment nothing fails over is not a commitment.

**Read the ledger, not the table below.** The table is here to explain *why* four of the seven are on
the critical path; the ledger is where their state actually lives, and a row is never deleted to make
the test pass. Read it at the start of every epic.

| Item | Task | Why it is on the critical path |
|---|---|---|
| **Book the field night** | [N00-T07](N00-decisions-rulings-and-the-calendar/N00-T07-book-the-field-night-and-start-recruiting-twelve-shepherds.md) | Every tap count in `07-screens.md` is a desk estimate until somebody watches one full night in a real shed. It is the highest-value unresolved item in the project and it closes three others. **It must happen before N13**, or Quick Entry — the product — is designed from forum posts. Sheds do not lamb on demand: the window is the window. |
| **Recruit twelve shepherds** | [N00-T07](N00-decisions-rulings-and-the-calendar/N00-T07-book-the-field-night-and-start-recruiting-twelve-shepherds.md) → [N32-T03](N32-signing-and-the-closed-track/N32-T03-open-the-closed-track-and-testflight-the-fourteen-day-clock.md) | Play's closed test requires **twelve testers for fourteen continuous days**, and the clock cannot start until twelve people exist. Recruitment takes weeks and is not under your control. The whole reason N32 was moved ahead of N33 is to run that fortnight in parallel with the sweeps instead of after them — but that only works if the twelve are already found. |
| **Apple Small Business Program enrolment** | [N00-T09](N00-decisions-rulings-and-the-calendar/N00-T09-store-accounts-the-small-business-program-price-and-territor.md) | Enrolment is an application with a review period and it sets the commission rate on every sale. It is also bundled with the two developer accounts, the post-13-November-2023 personal-account question, and the price band and territory list — none of which can be created the afternoon you want to ship. Submit it in week one and let it sit. |
| **The manifest-merger check (G0) against a real release AAB** | [N02](N02-g0-the-merged-manifest-record/epic.md) — [T01](N02-g0-the-merged-manifest-record/N02-T01-run-g0-against-a-real-release-aab-and-record-what-it-says.md) · [T02](N02-g0-the-merged-manifest-record/N02-T02-the-ruling-g0-produces-and-the-honesty-paragraph-it-may-forc.md) | One afternoon, an Android toolchain, and `in_app_purchase` in the pubspec — but until it has run, **G1 is unwritten** and the offline claim is faith. Three research notes hard-coded the removal of `ACCESS_NETWORK_STATE` from a Play Billing manifest six majors out of date. If billing 8.0.0 declares it and the merger strips it, the failure appears as a purchase flow misbehaving on a flaky connection, in production, on somebody else's phone. The ruling it produces is also the honesty paragraph the store listing (N32-T02) and the About screen (N29-T07) both reference. |

A fifth ledger row, the **ziplock-bag capacitance test** ([N00-T08](N00-decisions-rulings-and-the-calendar/N00-T08-the-ziplock-bag-capacitance-test.md)),
needs only a phone, a freezer bag and ten minutes — but it needs a phone per target device, and if a
target device cannot be operated through a bag then the 3am test floor is not met by any amount of
code.

---

## 7. Validating the backlog

```bash
python3 tool/validate_epics.py
```

Python 3 standard library only, no dependencies. Exit **0** clean, **1** at least one failure, **2**
the `epics/` root does not exist. It is wired into `make check` by
[N01-T05](N01-the-tree-the-configs-and-the-ci-shell/N01-T05-the-makefile-cheapest-failure-first.md),
alongside `tool/check_policy.dart` and `tool/validate_skills.py`.

It refuses thirty-nine named defects — a missing `epic.md`; any of the ten required sections
absent; a TDD block with no named first failing test, no real path, or no reason it is red **today**;
a close-out missing `/simplify`, either reviewer, or the commit; **a skill name that is not one of
the twenty-four that exist on disk**, in the table or anywhere in the prose; a Definition of Done
under three checkable items; a Verification block with no runnable command; a task file its own
`epic.md` does not reference, or a reference with no file; an epic with fewer than 2 or more than 12
tasks; and a `Depends on` id that is unknown, self-referential, or **lands later** than the task
depending on it.

Every rule has been watched to fire on a planted violation — a rule nobody has seen fail is
indistinguishable from a rule that asserts nothing. It says nothing about whether a task is well
*conceived*: it holds the shape, and the three audits in this folder hold the judgement.

Current state:

```
epics: 35   tasks: 240   skills known: 24
SUMMARY: 35 epics, 240 tasks, 0 failures, 0 warnings — PASS
```

---

## 8. Where the reasoning lives

**A task never re-litigates a decision.** Every rule in this backlog has a failure behind it, and
most of those failures happen at 03:20 on somebody else's phone in March. If a task looks wrong,
read the owning document; if it is still wrong, amend the decision record and every document that
applies it **in the same change** — that is the amendment rule in
[`docs/engineering/00-README.md` §10](../docs/engineering/00-README.md). The one thing you may never
do is implement around a decision you disagree with.

**Authority order** (`CLAUDE.md`): [`docs/research/00-tech-decisions.md`](../docs/research/00-tech-decisions.md)
(decisions; §5 is the only source of a version number) → [`docs/engineering/CONVENTIONS.md`](../docs/engineering/CONVENTIONS.md)
(every name, path, type, word) → [`docs/design/indelible.md`](../docs/design/indelible.md) (the one
design system) → the thirteen engineering documents → `.claude/skills/`. **A skill never outranks a
document**; it distils one and cites it.

| Where | What you go there for |
|---|---|
| [`CLAUDE.md`](../CLAUDE.md) | The four non-negotiables — offline purity, the 3am test floor, the five safety rules, every write commits immediately — plus the banned vocabulary. Present, not consulted. |
| [`shed-book-spec.md`](../shed-book-spec.md) | The product: the twelve screens, the ten feature groups, the entities, §12's safety rules, §17's open questions. |
| [`docs/engineering/00-README.md`](../docs/engineering/00-README.md) | §9 the build order this backlog implements · §8 the layer order a task touches files in · §7.4 the pull-request rules · §10 the amendment rule and the known open contradictions. |
| [`docs/engineering/`](../docs/engineering) | The thirteen documents. `CONVENTIONS.md` outranks all of them on any name; `01`–`13` own architecture, state, schema, migrations, domain, design, screens, platform, export, accessibility, monetization, testing and CI; `CODE-REVIEW-CHECKLIST.md` and `REFERENCES.md` sit beside them. |
| [`docs/design/indelible.md`](../docs/design/indelible.md) | The one design direction. The other two in `docs/design/` are the rejected comparisons and must not appear in a diff. |
| [`docs/research/00-tech-decisions.md`](../docs/research/00-tech-decisions.md) | The decision record, FINAL. Every version number, every numbered decision, and §6 where superseded decisions are struck **with their reason** so they are not quietly re-litigated. |
| [`docs/skills/`](../docs/skills) · [`.claude/skills/`](../.claude/skills) | The 24 skills — 20 auto-triggering, 4 manual-only runbooks (`/shed-migrations`, `/shed-release`, `/shed-goldens-rebaseline`, `/shed-code-review`). Each task file names the two or three it needs; `docs/skills/02-build-manifest.md` is the build spec and amending a skill amends it. |

**Inside this folder:**

| File | What it is |
|---|---|
| [`00-PLAN.md`](00-PLAN.md) | The original 31-epic index. Superseded — kept for the reasoning, not the numbering. |
| [`00-PLAN-CRITIQUE.md`](00-PLAN-CRITIQUE.md) | Its corrections, and the 35-epic re-cut this backlog was built from. §11 is the input every task file was written against. |
| [`00-AUDIT-template.md`](00-AUDIT-template.md) | The binding shape of a task file: the ten sections, in one order, and §7's open rulings. |
| [`00-AUDIT-accuracy.md`](00-AUDIT-accuracy.md) | Technical accuracy and skill validity — every backticked token run down against the doc corpus. |
| [`00-AUDIT-coverage.md`](00-AUDIT-coverage.md) | Coverage and sequencing: which task delivers which spec item, the dependency graph, the thirteen closed forward references, and the checker. |

<a id="open-rulings"></a>

**Open rulings.** Four are decided by the owner, not by a task, and each is noted where it binds:

| # | Question | What the backlog does today |
|---|---|---|
| **R1** | `/code-review` or `/shed-code-review`? | **Both**, in that order, in all 240 files and required by the checker. Reversing it is one constant in `tool/validate_epics.py` and one line deleted from 240 files. |
| **R2** | E-numbering or N-numbering? | **N00–N34**, the critique's re-cut. `00-PLAN.md` still reads E00–E30 and is superseded. |
| **R5** | `epic.md` or `README.md` for the per-epic file? | **`epic.md`**, in all 35 directories. `00-AUDIT-template.md` §6 still links `./README.md`; that is a one-line edit to the audit, not a rename. |
| **R6** | Task file naming | **`<TASK-ID>-<slug>.md`** — so a `Depends on` id resolves to a file mechanically, which is what makes the forward-reference check cheap. |

Seven design rulings are **scheduled but not yet made** — P1 ([N00-T05](N00-decisions-rulings-and-the-calendar/N00-T05-rule-p1-struck-struck-at-on-every-table.md)),
P3 (N13-T01), P7 (N09-T05), P8 (N16-T02a), P9 (N33-T03), P10 (N09-T09), P14 (N11-T04). Each has a
task, an anchor test and a named losing document. **A scheduled ruling is not a ruling**: make it in
the task, write it down, and then never re-open it.

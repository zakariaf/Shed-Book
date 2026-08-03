# N17 — Lamb Card

| | |
|---|---|
| **`00-README` §9 step** | 6 (3 of 5) |
| **Ships in** | `v1.0.0` |
| **Depends on** | N16 |
| **Size** | M |
| **Was** | E14, closer task deleted |
| **Branch** | `epic/n17-lamb-card` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

One lamb's whole life on one page: sex, weight, dam, foster, death.

Concretely, N17 authors `lib/features/lambing/lamb_card_screen.dart`, its controller, the one
statement behind it in `LambingRepository`, `Routes.lambCard`, and the five write verbs the screen
needs — `setLambSex`, `setBirthWeight`, `recordDeath`, `setPetLamb`, `recordBottleFeed`. It is the
first screen in the app that renders **two dams at once**, and the first that writes a **civil date**.

## Why the epic sits here

`00-README` §9 puts the Lamb Card at **step 6**, third of the five screens on the 3am path. §9's own
reason, quoted rather than re-derived:

> *"The rest of the 3am path: Lambing Entry, Lamb Card, Foster, Pen Board — plus the one 60 s ticker.
> These are variations on machinery step 5 already built. Foster and the pen board carry their own tap
> budgets."*

Three consequences bind this epic's scope:

- **It invents no machinery.** `WriteController.guard()` is N12-T04; the receipt-is-the-committed-row
  rule and the margin strike are N14-T04 and N14-T05; `ShedKeypad` is N13-T04; `ShedChoiceRow`,
  `ShedFieldRow`, `ShedStatusBadge` and `ShedEmptyState` are N10-T05/T06/T08. Where this screen looks
  as if it needs a new shared control, the control is already in `lib/core/ui/components/` and a
  feature-local copy is a layer violation (R70).
- **It comes after N16 because it has nothing to read until `addLamb` exists.** Every row this screen
  renders is created by `LambingRepository.addLamb` (N16-T03), and the tap that opens it is on the
  Lambing Entry's lamb sub-row. Both screens live in `lib/features/lambing/`, so this is not a sibling
  import — the Lamb Card is the same feature folder, one route deeper.
- **It comes before N18 (Foster).** The rearing-dam cell this epic renders is the cell N18 turns into
  a chooser. N17 renders the current rearing dam and the `FOSTER` action; it does **not** write a
  `FosterEvent`. If `foster_events` gains a row on this branch, the scope has slipped.

`00-README` §9's two parallel tracks apply in full: **accessibility** and **the ARB** are authored
inside each widget task. N33 only verifies; there is no later sweep.

## What is observably true when this epic merges

Run these on the merged `main` — this is the demo:

```bash
fvm flutter test test/features/lamb_card_test.dart
fvm flutter test test/domain/units_test.dart test/domain/units
fvm flutter test test/data/lambing_repository_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
fvm flutter test test/features/overflow_matrix_test.dart
make check && make test
```

- **A birthweight typed as `9.5` on the app's own keypad with the unit set to lb reads back `9.5 lb`,
  and the column holds `4309`.** Switch the setting to kg, reopen, switch back: still `9.5`. The
  round trip through the display unit never rewrites what the shepherd entered.
- **Both dams are on the page at once, and only one of them is a target.** `BIRTH DAM 412 —
  PERMANENT` has no `onTap` anywhere in its subtree; the rearing dam comes from the `lamb_rearing`
  view and changes the moment a `FosterEvent` is appended, with no `UPDATE` to `lambs` and no
  `rearing_dam` column anywhere in the schema.
- **"No ewe — bottle" and "No ewe — not recorded" are two different strings.** Both mean
  `rearing_dam IS NULL`; one is null by intent and one is null by omission, and rendering them with
  one string would be the app deciding they are the same fact.
- **`stillborn` is a status, not a cause, and never a day-0 death.** A stillborn lamb lands in
  `AgeBucket.stillborn`; `lossesBreakdown` never counts it in `sameDay`.
- **A death date before the lambing prints `The death date is before the lambing.` and stores both
  dates unchanged.** Read both columns back after the badge renders and neither has moved.
- **A blank cause is `unattributed`, and `dc_unknown` is a cause the shepherd picked.** Two columns,
  never merged, in storage and in the losses breakdown.
- **`+1 feed` commits before your thumb leaves the glass**, on a target ≥ 64 × 64, with no
  repeat-on-hold and no slider anywhere in the tree.
- **`kPumpableVariants` grows to three entries** — `quick_entry` (N13-T07), `lambing_entry`
  (N16-T09), `lamb_card` (N17-T05) — and the count is still derived from the map's own length, never
  typed.
- **`grep -rn 'showDatePicker\|showTimePicker' lib/` returns nothing.** The death date is relative
  buttons plus the keypad, which is what a shepherd needs at 07:00 the morning after.

Deliberately **not** demonstrable yet: fostering from this screen (N18), the full 252-cell matrix
(N33), the goldens (N33-T07), and the lamb rows in the CSV (N21).

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/07-screens.md` | §1.2 (the one-query rule, stated exactly) · §1.3 (what a tap is) · §1.4 (the state vocabulary) · §1.5 (the §12 disclosure matrix) · **§7.1–§7.4 (Lamb Card)** · §15.1–§15.3 (undo per verb) | the screen, its query, its five states, its tap costs, and which verbs have no undo |
| `docs/engineering/03-data-model-and-schema.md` | §5.5 (**`Lambs`, every column and all eight `CHECK`s**) · §5.6 (`CareEvents`' closed `kind`) · §5.8 (`Treatments.lamb`) · §5.11 (`Notes.lamb`) · §5.12 (`VocabTerms`) · **§7 (the birth-dam trigger and the `lamb_rearing` view, printed in full)** · §10.1 (the eight `dc_*` keys) | every column, constraint, view and vocabulary key this screen touches |
| `docs/engineering/05-domain-correctness.md` | **§5.1–§5.4 (canonical grams, the display-unit round trip, the keypad, `kPlausibleBirthWeight`)** · §6.8 (losses by cause and by age, `LambStatus`, `AgeBucket`) · §7.5 (rule 4, the `Warning` catalogue, `deathBeforeBirth`) · §8.1 (`AnimalClass`, `Terminology.labelFor`) | the units, the statistics this screen feeds, and both warnings that fire here |
| `docs/design/indelible.md` | §7.3 (the ruled record row and its **unset cell**) · §7.7 (boxed versus unboxed stamps) · §7.8 (the number stepper, and no repeat-on-hold) · §7.9 (segmented choice) · §7.12 (the text field, and **no placeholder**) · §7.13 (word button) · **§8 screen 5** · §9 (the 3am compliance table) | every pixel, mark, stamp and state of this screen |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree) · §1.1 layer rules 3, 4, 5, 7 · §2.1 · §2.3 (`Grams`, `WeightUnit`) · §2.4 · §2.9 (`Sex`, `LambStatus`, and death causes are **not** a domain enum) · §3.2 (`lambCardProvider`) · §3.4 (**the closed controller list**) · §4.5 (widget keys) · §4.6 (column names) · §5 (the words) · R17, R33, R37, R45, R53, R59, R66 | **BINDING** on every path, type, provider, column and word |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.4 (**`headingLevel`, and why the Lamb Card gets no level 2**) · §5.2 (the redundancy table's four lamb-status rows) · §6.2 (**`showDatePicker` does not ship**) · §8.4–§8.5 (the ARB rules and the terminology placeholder) · §9.1–§9.4 (`formatShedWeight`, `formatShedDate`, and no all-numeric date) | semantics, every string, and every format |
| `docs/engineering/02-state-di-navigation.md` | §4.2 (auto-dispose) · §4.4 (`.select`, and a controller never formats) · §5.1 (the `async*` read-provider shape) · §7 (`guard()` and the `ref.listen` switch) · §8 (the push helper) | the wiring this screen sits in |
| `docs/engineering/12-testing.md` | §2.1–§2.4 (time in tests, and why `Clock.fixed` freezes a widget test) · §3.3 (repository tests against `NativeDatabase.memory()`) · §5.1 (`pumpApp`) · §6.1–§6.2 (the variant table and the derived count) · §7.4 (the semantics gates) | every test this epic writes |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #12 · #33 · #53 · #54 · #56 · #57 · #60 · #71 · #90 · #103 · §7.0 ruling 3 | Flutter **3.44.8** / Dart **3.12.2** · `flutter_riverpod` **2.6.1** exactly · `drift` **2.34.2** · UK/Ireland, kg, 24 h, ambiguous hour 01:00–01:59 |
| `CLAUDE.md` | **P2** (there is no SnackBar) · the five safety rules · the amendment rule · the banned words | the owner ruling that supersedes `07 §15`'s undo column |
| `epics/00-PLAN-CRITIQUE.md` | §4 (the closer task is deleted) · §11.3 (the anchors) · §11.4 (skills per epic) | why T05 is one line and not five |
| `shed-book-spec.md` | §7.3 (lamb records, fostering, pet lamb, death with a cause) · §12.2 · §12.4 | the product promise this screen keeps |

## Tasks

Strictly sequential. The screen accretes: there is nothing to render until the statement exists, no
death to warn about until a status control exists, and no variant row until the screen is finished.

| Task | Depends on | One line |
|---|---|---|
| [N17-T01](N17-T01-lambcardprovider-one-statement-rearing-dam-from-the-view.md) | N16-T09 | `lambCardProvider` — one statement, rearing dam from the view |
| [N17-T02](N17-T02-sex-and-a-birthweight-on-the-apps-own-keypad.md) | N17-T01 | Sex, and a birthweight on the app's own keypad |
| [N17-T03](N17-T03-death-date-cause-stillborn-and-deathbeforebirth.md) | N17-T02 | Death — date, cause, `stillborn`, and `deathBeforeBirth` |
| [N17-T04](N17-T04-pet-lamb-status-and-the-feeding-count.md) | N17-T03 | Pet lamb status and the feeding count |
| [N17-T05](N17-T05-the-matrix-variant-and-the-empty-state-row.md) | N17-T04 | The matrix variant and the empty-state row |

T05 is deliberately one line. `00-PLAN-CRITIQUE.md` §4 deleted the *"screen composition, ARB,
semantics, the matrix variant and the tap costs"* closer task that E14 ended with, because it bundled
five commits and quietly turned the accessibility track into a batch. Everything that closer used to
carry is authored inside T01–T04; what survives is the two files that keep `kPumpableVariants`
honest.

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N16 is merged and `main` is green before this starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version          # must print 3.44.8 / 3.12.2; .fvmrc is the pin
git checkout -b epic/n17-lamb-card
```

The branch string is the one in the header row above. Do not reconstruct it from the directory name.

**2 — One commit per task, five commits, in task order.** Each task file names its commit line
verbatim; use it. Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test         # -P ci-fast, randomised order, + TZ=Europe/London --tags uk-zone
```

Two tasks carry an extra obligation, and both are naming obligations rather than code:

- **T01 adds a push helper to `lib/routing/routes.dart`.** N13-T01 shipped thirteen `RouteNames` and
  **only the Quick Entry helper**; `Routes.lambCard` is the second one this backlog writes. It is a
  compile edge from routing to a feature, so it lands with the screen, not before it.
- **T02, T03 and T04 add write verbs to `LambingRepository` that `CONVENTIONS §2.13` does not
  publish.** §2.13 is explicitly *"canonical verb signatures where more than one document names
  them"* — it is not the closed set. Name them under §4.2's event-verb rule, list them in the PR
  body, and if a reviewer wants them in §2.13, that is a numbered ruling in §6, not a rename three
  epics later when N18, N19 and N27 already call them.

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the
diff in `00-README` §10's irreversibility order. For this branch that order is:
`lib/data/lambing_repository.dart` → `lib/l10n/app_en.arb` → `lib/routing/routes.dart` →
`lib/features/lambing/` → `test/`. `lib/data/**` is never waved through, however small: it is the
only layer that writes.

**4 — Open the PR and answer the five §12 questions** from `.github/pull_request_template.md`
**verbatim, in the PR body**. Three of the five land squarely on this epic:

- **§12.2** — this screen holds a birthweight, and `CODE-REVIEW-CHECKLIST.md` §2.3's worked example
  of a rule the content scanner **cannot catch** is in this exact file: multiplying
  `lamb.birthWeight.inKilograms` by 50 to suggest a colostrum volume. State that no number on this
  screen is originated by the app, and that the two `CHECK`s it can trip
  (`birth_weight_g BETWEEN 200 AND 20000`, `bottle_feeds >= 0`) are unit-slip guards, not husbandry
  opinions.
- **§12.4** — `implausibleBirthWeight` and `deathBeforeBirth` are observations. Name the test that
  reads both stored values back **after** the badge renders and asserts neither moved.
- **§12.5** — the birth time carries its provenance label from the *lambing*. Say plainly that
  `lambs` carries **no provenance quad**, so the death date carries no provenance claim; see
  *Irreversible* below.

**5 — Wait for the pipelines.** Three blocking jobs run on this PR. `android` does not exist yet
(N31-T03 writes it), `release` runs on `v*`, and `goldens` runs on `v*` or manual dispatch only.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` · the `NSAppTransportSecurity` grep | The layer rules, which is where a screen fails first: no `package:drift` and no `lib/core/db/` import under `lib/features/`, no sibling-feature import, and no `lib/domain/validation/` import from `lib/data/` (R53 — the mechanism that makes a repository structurally incapable of producing a `Warning`). It also holds `a11y.material_picker` (**no `showDatePicker`** — the one rule this epic is most likely to trip), `gesture.*` (no slider under the feed counter, no drag on the weight), `ui.spinner`, `token.raw_color`, `db.save_verb`, and every banned word in the diff |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | A **negative**, and that is the point. The schema froze at N07-T08, six epics ago; N17 stores nothing new. If `drift_schemas/` moves on this branch, a table changed — stop and find out why before you regenerate anything |
| `test` | `flutter test -P ci-fast` randomised · `TZ=Europe/London --tags uk-zone` over the whole suite, **unscoped** · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · the coverage artefact (reported, **never** gated) | `lamb_card_test.dart`, `lambing_repository_test.dart`, `units_test.dart` and `overflow_matrix_test.dart`. The `uk-zone` leg is load-bearing for **T03**: `LocalDate.of(instant)` in the repeated hour 01:00–01:59 is what decides whether a lamb born at 01:30 on 25 October and found dead the same morning trips `deathBeforeBirth`. That case only exercises the ambiguity when the leg runs unscoped under `TZ=Europe/London` |

`gh pr checks --watch`. Do not merge on a yellow, and do not start N18 while this one is red — N18's
branch is cut from this merge.

**6 — Merge, delete the branch, and only then cut N18.**

```bash
gh pr merge --delete-branch                 # or the repo's configured strategy
git checkout main && git pull --ff-only
# confirm main is green, then:
git checkout -b epic/n18-foster
```

N18 turns the rearing-dam cell this epic renders into a two-tap chooser, and its one-tap budget is
measured from a Lamb Card that already paints both dams. Cutting it from anything other than a green
merged `main` means rebasing a chooser onto a moving cell.

## Risks, and what is irreversible

**Irreversible in this epic — say it out loud in the PR body:**

- **Nothing here may touch `drift_schemas/` or `lib/core/db/tables/`.** The lambing cluster froze at
  N07-T04 and the snapshot was committed at N07-T08. `lambs` has no provenance quad, no
  `rearing_dam` column, no `feed_events` table and a **closed** `CHECK` on `care_events.kind`. Every
  one of those is a thing this screen will make you want, and every one of them is a migration on
  somebody else's phone in April. **If a file under either path appears in this branch, stop.**
- **The death date carries no provenance, and the screen must not claim otherwise.** `07 §7.3` says
  *"accepting it records `autoCaptured`, changing it records `userEntered`"* — and `lambs` has no
  `captured_at`, no `original_effective` and no `time_source` (R37 added the quad to
  `PenOccupancies`, `FosterEvents`, `Notes` and `EweObservations`; it did **not** add it to `Lambs`).
  `CLAUDE.md`'s corollary is absolute: *a table without the provenance quad has no edit verb*, and an
  `AUTO` stamp beside a value the schema cannot prove was auto-captured is a §12.5 violation wearing
  a placeholder's clothes. **T03 ships the death date with no provenance stamp and records the
  contradiction in the PR body.** Adding the quad to `Lambs` is a schema change: irreversible,
  owner-only, out of scope here.
- **Widget keys are test contracts** (R59). `lamb_card.weight`, `lamb_card.status.stillborn`,
  `lamb_card.feed.increment` and their siblings are tapped by `lamb_card_test.dart` and, from N33, by
  the semantics and tap-target sweeps. Renaming one later is a breaking change to `test/features/`,
  not a refactor.
- **The eight `dc_*` keys are frozen forever.** They go into SQLite, every CSV `death_cause_key`
  column and every JSON backup, and a backup written by v1.0 is restored by v1.9. This epic renders
  them and lets the shepherd add a ninth with `origin = 'user'`; it never renames one and never
  hides a seeded key behind a nicer word.

**Risks specific to N17:**

| Risk | Why it bites here | What holds it |
|---|---|---|
| **A `rearing_dam` column appears** | It is one `UPDATE` away, it makes the query trivial, and decision #33 rejects it by name: a denormalised current-rearing-dam column is a dual write producing a lamb whose history says *"fostered to 128"* while the list screen says *"412"* | The schema is frozen and has no such column (`03 §7`). T01 reads `lamb_rearing`, and the anchor test appends a `FosterEvent` and asserts the screen moves with no write to `lambs` |
| **The view name goes in `readsFrom:`** | `lamb_rearing` is a **view**; keying a stream on it either fails or silently never re-emits | `07 §7.1` fixes the set at `{lambs, lambings, ewes, fosterEvents, careEvents, treatments}` — the view's *base* tables. T01's test appends a foster event and asserts a new emission |
| **The header vanishes when the history is empty** | The natural shape joins the header CTE to the history arms, and a lamb with nothing recorded has no history rows, so the whole statement returns zero and the screen renders Empty for a lamb that plainly exists | T01: the `'born'` arm is derived from `lambs.lambing`, which is `NOT NULL` — so the union always has at least one row. `07 §7.2`'s empty copy is *"Nothing **else** recorded."* for exactly this reason |
| **The display unit gets stored** | A form seeded from `4.3 kg` at 1 dp and written back is a silent correction with no line of code to blame — `05 §5.1` walks the exact sequence | Canonical grams, conversion at the widget boundary only, no `unit` column in the frozen schema, and `05 §5.3`'s round-trip loops already green from N04-T06 |
| **A colostrum volume gets suggested from the weight** | AHDB publishes 50 ml/kg, the app holds the birthweight, and multiplying is one line and would be *helpful*. `CODE-REVIEW-CHECKLIST.md` §2.3 uses `lamb_card_screen.dart` as its worked example of a §12.2 violation that **passes** the content scanner | Nothing on this screen computes from the weight. It is a review question, not a gate — which is why it is in the PR body |
| **`stillborn` becomes a cause, or a day-0 death** | `dc_stillborn` exists as a `death_cause` key *and* `stillborn` is a `lambs.status` value, so deriving either from the other looks like tidying | `05 §6.8`: stillborn is its own `AgeBucket`, never `sameDay`. T03 records the status and the cause independently and asserts neither is inferred from the other |
| **`unattributed` and `unknown` get merged** | Both render as "we do not know", and one `COALESCE` collapses them | `05 §6.8` and `CONVENTIONS §5.1`: `dc_unknown` is a cause the shepherd picked; `NULL` is our word *unattributed*. Two columns, two words, one test |
| **A `showDatePicker` appears for the death date** | `07 §7.3` says *"1 + picker"*, and Material's picker is one line | `10 §6.2` bans both pickers with the gate row `a11y.material_picker`: the dial is a drag, the keyboard mode opens the system IME, and the calendar cells are ~32 pt — half the floor. The control is **Today / Yesterday / 2 days ago / Pick a date** plus `ShedKeypad` |
| **The status flip to `alive` trips a `CHECK`** | `lambs` carries `CHECK (death_date IS NULL OR status IN ('dead','stillborn'))` **and** the same for `death_cause`. Writing the date before the status, or clearing the status without the date, fails with `SQLITE_CONSTRAINT_CHECK` on a real phone | T03: status, date and cause move together inside one `_db.transaction()`, and the reversal case is an explicit open item in the PR body — it is the one place on this screen where recorded data would be destroyed |
| **A feed becomes a `CareEvent`** | Indelible screen 5 says *"pressing + also prints a timestamped row into the stream: `FEED 4 — 06:40`. Every feed is an event"* — and `care_events.kind` is a **closed** `CHECK` of four values wired to frozen notification channel ids | T04: `lambs.bottle_feeds` is the stored fact. A fifth `kind` is a migration **and** a channel decision (`03 §5.6`), and printing a per-feed timestamp the schema cannot carry is inventing precision |
| **A `lambCardWriteControllerProvider` gets created** | Every other screen has a write controller, so the symmetry is strong | `CONVENTIONS §3.4` publishes the controller list and it is not in it. §4.4 rule 2 is one write controller per **feature**: the Lamb Card's writes go through `lambingWriteControllerProvider`, which N16 built |
| **`LambCardData` lands in the feature file** | `10 §9.1`'s DoD puts `PenTile` in `pen_board_controller.dart`, and copying that placement here makes `lambing_repository.dart` unable to name its own return type | T01: the type is declared in `lib/data/lambing_repository.dart` beside the statement that produces it. Layer rule 3 forbids `lib/data/` from importing `lib/features/`, and the analyzer only tells you after both files exist |
| **A SnackBar reappears** | `07 §15.1` gives *"SnackBar"* as the undo window for eight verbs | **P2 supersedes it.** `test/policy/no_snackbar_test.dart` has been green since N14-T04 and must stay so. None of this epic's verbs has an undo row in `07 §15.1` at all — they correct forward, and `updated_at` moves |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] the diff contains no file under `drift_schemas/`, `lib/core/db/tables/`, `android/` or `ios/`
- [ ] the rearing dam is read from `lamb_rearing`; `grep -rn 'rearing_dam' lib/data/ lib/features/` finds no assignment
- [ ] the birth-dam cell has no `onTap` anywhere in its subtree, proved by a widget test
- [ ] the feature reads **one** statement; `combineLatest` appears nowhere under `lib/features/lambing/`
- [ ] `package:drift` and `lib/core/db/` appear nowhere under `lib/features/`
- [ ] no `showDatePicker`, no `showTimePicker`, no free-text date field, no system keyboard
- [ ] every displayed weight goes through `formatShedWeight`; no display unit is ever assigned to a variable that flows toward the database
- [ ] `lamb_card` carries exactly one `headingLevel: 1` node and no level 2 (`10 §3.4`)
- [ ] every time-shaped test has a case in the ambiguous hour **01:00–01:59**, tagged `uk-zone`
- [ ] no element of `the-register.md` or `strip-bay.md` appears in the diff, in a comment, or in a review remark

## Demoable on merge

A birthweight typed on the app's own keypad, stored in canonical grams, shown in the user's
unit — and a death recorded with `stillborn` as its own bucket, never *died at age 0*.

## Notes

**What N17 deliberately does not do.** Fostering is **N18** — this screen renders the current rearing
dam and a `FOSTER` action that pushes; it writes no `FosterEvent`. The lamb's notes and photos are
N15's machinery reached from here, and the history arms this statement carries are the six tables
`07 §7.1` names: adding a `notes` arm means adding `notes` to `readsFrom:` **in the same edit**, or
the stream silently stops re-emitting. The CSV columns `pet_lamb`, `bottle_feeds`, `death_cause_key`
and `rearing_dam_tag` are **N21**; this epic writes the values they read.

**`kPumpableVariants` is at three entries after T05** — `quick_entry` (N13-T07), `lambing_entry`
(N16-T09) and `lamb_card`. The fourteen-entry table and the 252-cell arithmetic (R58) arrive at N33;
until then the count assertion follows the map's own length and the matrix seeds through
`test/support/seeds.dart`, not `restoreFixture` — the fixtures are written by `tool/seed.dart`
through the restore path at N23.

# N14 — Quick Entry: the write path

| | |
|---|---|
| **`00-README` §9 step** | 5 (2 of 2) |
| **Depends on** | N13 |
| **Size** | M |
| **Was** | E11, with `createEwe` taking `EntryContext` |
| **Branch** | `epic/n14-quick-entry-write-path` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

Make the tap commit. N13 built the deck, the keypad and the shell — a screen that can *select* an
animal and cannot yet *record* anything. N14 lands the two verbs behind it (`FlockRepository.createEwe`
and `LambingRepository.beginLambing`), the guarded controller that calls them, the receipt that proves
they returned, the strike that takes one back, and the two assertions this epic exists to earn:
**five taps from launch to a committed lambing row**, and **nothing about money on the 3am screen**.

Five taps to a committed lambing row, no Save button, no draft, and a receipt that is the
committed row itself.

## Why the epic sits here

`00-README` §9 puts Quick Entry at **step 5**, immediately after the first frame (step 4 — N09, N10,
N11, N12) and before every other screen. Its stated reason, not re-derived here:

> *"It is the product. It also forces you to build every piece of machinery the other eleven screens
> reuse — the deck query, the keypad, the write controller, the receipt — so the second screen is
> cheap."*

Three consequences bind this epic's scope:

- It comes **after** the schema freeze (step 3) because every column these two verbs write —
  `ewes.over_free_cap`, `lambings.declared_birth_type` nullable per R6, the §12.5 provenance quad,
  `ewe_touches` — had to be right before the first snapshot. Nothing in N14 may add a column. If one
  turns out to be missing, that is a migration and an owner conversation, not an edit.
- It comes **after** N12 because `WriteController.guard()` (N12-T04), `pumpApp` (N12-T05) and
  `databaseProvider` (N12-T01) are the machinery every task here calls. The double-tap defence is not
  written in this epic; it is *used* here, for the first time, on the product's central write.
- It comes **sixteen epics before monetization on purpose.** `00-README` §9 step 11: monetization
  *"can be last precisely because nothing on the shed path branches on `unlocked` — that is decision
  #90, and the widget test that holds it should exist from step 5."* Step 5 is here. That is T07, and
  it is the same reason T01 takes an `EntryContext` in its first commit rather than acquiring one in
  N30 (critique defect S5).

`00-README` §9's two parallel tracks start here as everywhere else: **accessibility** and **the ARB**
are authored inside the widget task (T04, T05), never in a later sweep. N33 only verifies.

**What this epic needs from earlier epics, by task.** Each task file's header carries the full list;
these are the four that cross an epic boundary, and every one of them is already merged on `main`
before the branch is cut: T01 depends on N13-T07 (`kPumpableVariants`, born with one entry), on
N06-T10 (`free_tier.dart` — `EntryContext`, `CapDecision`, `FreeTierPolicy.decide`, `isQuietHours`)
and on N07-T03 (the flock cluster: `ewes`, `ewe_touches`, the active-only partial unique index);
T02 additionally depends on N07-T04 (the lambing cluster). Everything from T02 onward depends only on
the task before it.

## What is observably true when this epic merges

Run these on the merged `main` and watch them pass — this is the demo:

```bash
fvm flutter test test/features/tap_budget_test.dart
fvm flutter test test/data/flock_repository_test.dart test/data/lambing_repository_test.dart
fvm flutter test test/policy/no_snackbar_test.dart test/policy/no_money_on_a_shed_screen_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check && make test
```

- **Five taps produce a committed lambing row.** `4` (three digits + confirm) `+ 1` (`Lambing`), on
  keyed finders, and the assertion reads the row **back out of the database**, not off the screen. The
  sixth tap — the first tally stroke — is N16-T02a's, where the tally exists.
- **A double-fired confirm commits exactly one lambing.** Two `tester.tap()` calls with no pump between
  them, which is the only shape that tests anything (`02 §7.1` rule 4).
- **The row survives the process.** `test/data/durability_test.dart` writes a lambing, closes the
  database, reopens the file cold and finds the row — `synchronous = FULL`, WAL, decision #28. That is
  the closest a test suite gets to *assume the phone dies*.
- **The cap never speaks on the live-entry path.** `createEwe(context: EntryContext.liveEntry)` at
  99 ewes, locked, at 03:20 returns `WriteCommitted` with the row marked `over_free_cap`. It is not a
  convention: `FreeTierPolicy.decide` cannot reach a `BlockedByCap` on that arm at all.
- **`showSnackBar(` appears nowhere under `lib/`** — including in `feedback.dart`, which was the last
  file with a legitimate call site until P2. There is no `[exempt]` line for it.
- **No monetization widget renders on Quick Entry** at any entitlement state and on both sides of the
  22:00–06:00 boundary, including inside the ambiguous 01:00–01:59 hour.
- **A struck lambing is still there.** Undo strikes the row in its own margin — it does not move,
  collapse or disappear — and the window is stated in seconds in the copy, from the same constant the
  timer uses.

What is deliberately **not** demonstrable yet: pushing Lambing Entry. `LambingEntryScreen`,
`RouteNames.lambingEntry`'s push helper and the sixth tap are N16's (critique defect S2's ruling —
`routes.dart` grows one helper per screen epic). At N14 the "Lambing" tap commits the row and prints
the receipt, and that is the whole interaction.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/00-README.md` | §2.4 (every write commits immediately; the row is created on screen entry) · §8 steps 3–7 · §9 step 5 · §7.4 (commits that must stand alone) · §10 (the amendment rule, and the two known open contradictions this epic meets) | the write-path law, the file-touch order, and why this epic is here |
| `docs/engineering/01-architecture.md` | §4.1 (repositories: concrete, no interfaces, no `Clock`) · §4.2 (event verbs; the `beginLambing` body, printed) · §4.3 (one `appNow()`, one transaction, gateways *after* it returns) · §4.4 (persist before republish, `.distinct()`, no `combineLatest`) · §4.5 (there is no Save button) · §5.2, §5.4, §5.5 (what is returned versus thrown, and the global net) | the shape of every verb in T01 and T02 |
| `docs/engineering/02-state-di-navigation.md` | §6 (the nine controller rules) · §7 (`WriteController`, `guard()`, the `ref.listen` switch) · §7.1 (the four rules, including no pump between the two taps) · §4.2 (auto-dispose) · §2 (the Riverpod-3 ban list) | T03, exactly |
| `docs/engineering/07-screens.md` | §5.3 (states, including the `412 →` frame-1 window) · §5.4 (actions and tap costs) · §5.5 (commit, confirmation, double taps) · §5.6 (what is banned on this screen) · §5.7 (§12 on this screen) · §6.1 (the write happens before the route) · §15 (undo per verb) | the tap budget, the three confirmation channels, the undo table |
| `docs/engineering/11-monetization-and-store.md` | §2 (names) · §4.1 (the entitlement row) · §4.4 (nothing on the 3am path reads it) · §7.1–§7.4 (what is capped, the complete type, the two gated verbs, the two stated consequences) · §8 (the four hard constraints) · §8.1 (`over_free_cap` is not a warning) | `EntryContext`, decision #91's live-entry rule, and T07 |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree) · §1.1 layer rules 3, 4, 5, 6, 8 · §2.4 (`WriteOutcome`, `WriteState`, `WriteController`) · §2.10 (free tier) · §2.11 (`SaveReceipt` and the three feedback functions) · §2.13 (the canonical verb signatures) · §3.1, §3.4 · §4.4, §4.5, §4.6 · §5.1–§5.3 · R3, R6, R10, R30, R31, R32, R33, R53, R57, R59, R69 | **BINDING** on every path, type, provider, key and word |
| `docs/engineering/03-data-model-and-schema.md` | §5.2 (`Ewes`, `tag_digits`, the active-only partial unique index) · §5.4 (`Lambings`, the quad, nullable `declared_birth_type`) · §5.13 (`Entitlements`) · §5.14 (who owns which writes) · §9.2 (the FTS5 source triggers and the `COALESCE` rule) | every column these verbs touch |
| `docs/engineering/12-testing.md` | §3.3 (repository tests) · §3.5 (durability) · §5.1 (`pumpApp`) · §5.2–§5.3 (seeding; what may live in `test/support/`) · §10.1 (the three tap budgets) · §10.7 (nothing monetization-related on a shed screen) | every test file this epic writes |
| `docs/engineering/06-design-system.md` | §10.1 (the four haptics) · §10.3 (the receipt as proof, `SaveReceipt`, the three functions) · §12 (`ShedReceiptBar`, `ShedBanner`, and the three free-tier constraints) | T04's channel |
| `docs/design/indelible.md` | §6.2 marks 4 and 5 (the tally stroke, the strike line) · §7.3 (the ruled record row and its Live, Struck and Queried states) · §8 Screen 3 (the live row, the receipt one line above, `STRIKE`) · §9 (the 3am compliance table) | what the shepherd actually sees when a write returns |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #11, #22, #28, #32, #42, #46, #55, #68, #69, #90, #91, #103 · §7.0 rulings 3, 7, 8 | `flutter_riverpod` **2.6.1**, `drift` **2.34.2**, `uuid` **4.6.0**, `clock` **1.1.2** |
| `CLAUDE.md` | the four non-negotiables · **P2** (there is no SnackBar) · **P8** (no birth-type chooser) · the vocabulary and the banned words | the two owner rulings that supersede a written document, both of which land in this epic |
| `epics/00-PLAN-CRITIQUE.md` | **S4** (the budget splits 5 + 1) · **S5** (`createEwe` is gated from its first commit) · S2 · S3 · §10 (the workflow rules) · §11.3 (the anchors) · §11.4 (skills per epic) · §11.5 (*"the write path and the receipt — every screen after it is a variation on machinery built here"*) | why this epic's tasks are cut the way they are |

## Tasks

Strictly sequential. T02 cannot compile without T01's repository conventions in place, T03 has nothing
to guard until both verbs exist, T04 has nothing to receipt until the controller emits `WriteDone`,
T05 has nothing to strike until there is a receipt, and T06 and T07 are assertions over the finished
screen.

Cross-epic dependencies are listed above and in each task file's header; the column below is the
in-epic order.

| Task | Depends on | One line |
|---|---|---|
| [N14-T01](N14-T01-flockrepositorycreateewe-gated-from-its-first-commit.md) | — (see above) | `FlockRepository.createEwe` — gated from its first commit |
| [N14-T02](N14-T02-lambingrepositorybeginlambing-the-row-exists-before-the-rout.md) | N14-T01 | `LambingRepository.beginLambing` — the row exists before the route is pushed |
| [N14-T03](N14-T03-quick-entry-write-controller-through-guard.md) | N14-T02 | `quick_entry_write_controller` through `guard()` |
| [N14-T04](N14-T04-feedbackdart-the-receipt-is-the-committed-row.md) | N14-T03 | `feedback.dart` — the receipt is the committed row |
| [N14-T05](N14-T05-undo-as-a-time-boxed-strike-in-the-rows-own-margin.md) | N14-T04 | Undo as a time-boxed strike in the row's own margin |
| [N14-T06](N14-T06-tap-budget-testdart-five-taps-to-a-committed-lambing-row.md) | N14-T05 | `tap_budget_test.dart` — five taps to a committed lambing row |
| [N14-T07](N14-T07-nothing-about-money-renders-on-a-shed-screen.md) | N14-T06 | Nothing about money renders on a shed screen |

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N13 is merged and `main` is green before this starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version          # must print 3.44.8; .fvmrc is the pin
git checkout -b epic/n14-quick-entry-write-path
```

**2 — One commit per task, seven commits, in task order.** Each task file names its commit line
verbatim; use it. Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

Two commits in this epic carry an extra obligation, because both amend a document that other documents
apply (`00-README` §10, the amendment rule — *"every document that applies it, in the same change"*):

- **T04** strikes `CONVENTIONS §2.11`'s sentence *"`feedback.dart` is the one file permitted to call
  `showSnackBar(`"* and moves the `gesture.raw_snackbar` gate row to **no allowlist entry at all**. P2
  is the ruling; T04 is the commit that makes the naming authority agree with it.
- **T05** strikes `07 §15.1`'s first two rows (`beginLambing` and `addLamb` → *"hard delete"*) and
  `§15.2`'s window (*"until the SnackBar is dismissed"*). P1 gives every table `struck` / `struck_at`
  and P2 states the window in seconds; a document that still prescribes a hard delete and a SnackBar
  lifetime is worse than no document.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test         # -P ci-fast, randomised order, + TZ=Europe/London --tags uk-zone
```

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the diff
in `00-README` §10's irreversibility order. For this branch that order is:
`tool/policy_allowlist.txt` and `tool/check_policy.dart` → the `docs/` amendments made by T04 and T05 →
`lib/data/**` (`flock_repository.dart`, `lambing_repository.dart`, `providers.dart`) →
`lib/l10n/app_en.arb` → `lib/core/ui/` → `lib/features/quick_entry/` → `test/`.

`lib/data/**` is read third *and never waved through* on this branch: `00-README` §10 names any table
gaining an edit verb as never-waved-through, and T05 gives `lambings` its first one.

**4 — Open the PR and answer the five §12 questions** in `.github/pull_request_template.md`
**verbatim, in the PR body**. `00-README` §7.4: the PR is *where* the safety review happens. Three of
the five land squarely in this epic and must not be answered "not applicable":

- **§12.4 — never silently correct.** `beginLambing` writes `declaredBirthType: const Value.absent()`
  and nothing in this branch ever defaults it. `WriteCommitted.warnings` is populated by the
  controller, never by a repository (R53), and `lib/data/` still cannot import
  `lib/domain/validation/`. `over_free_cap` is **not** a warning (`11 §8.1`) and gets no badge, no
  colour and no `WarningCode`.
- **§12.5 — timestamps carry provenance.** One `appNow()` per mutation; `RecordedTime.capture(now)` on
  the lambing; `time_source = 'auto'` with `original_effective IS NULL`, held by the paired SQL CHECK.
  Every time the receipt prints carries its provenance label — a bare `03:24` is a review failure.
- **§12.2 — never give veterinary advice.** No copy added by T04 or T05 contains a "should", a
  recommendation or a clinical claim; no event button, strip header or confirm key does either
  (`07 §5.7`).

**5 — Wait for the pipelines.** Three jobs run for this epic and each proves a different thing.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` · the `NSAppTransportSecurity` grep | The layer rules that make this epic's shape structural rather than reviewed: `layer.single_writer` (nothing outside `lib/data/` opens a transaction), `layer.features` (no drift import under `lib/features/`), `layer.sibling` (Quick Entry never reaches into `lib/features/lambing/`), `layer.data_no_validation` (R53), `layer.data_no_material`, `db.save_verb` (`save\w*\(` under `lib/data/`), the banned-word rows (`draft`, `isDirty`, `commit()`, `submit()`, `pending`) and — after T04 — `gesture.raw_snackbar` with **no** allowlist entry. The `rp3.*` rows catch a Riverpod-3 spelling in the new controller |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | A **negative**, and it is the most important negative in the epic: N14 writes *to* the schema and must not change it. If `drift_schemas/drift_schema_v1.json` moves on this branch, a table or a column has been edited to make a verb convenient — stop, because after the freeze that is a migration on somebody else's phone in April |
| `test` | `flutter test -P ci-fast` randomised · `TZ=Europe/London --tags uk-zone` over the whole suite · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · the coverage artefact (reported, **never** gated) | Every anchor in this epic. The `uk-zone` leg is load-bearing for T02 and T06: `lambings.local_date` is computed in Dart from the effective instant, and the one place it can be wrong is the ambiguous 01:00–01:59 hour. An untagged DST case runs under the runner's own zone and passes for the wrong reason |

`android` also runs on every PR (`13 §4.2`), builds the release AAB and asserts **G1**. N14 changes no
native file and no permission, so it proves nothing this epic authored — but it must stay green. If it
goes red here, look at a dependency, not at a repository.

Goldens do **not** run on this PR: the `goldens` job is `v*` or `workflow_dispatch` only, because the
macOS runner bills at a 10× multiplier. Quick Entry is one of the eight images and it is N33-T07's.

**6 — Merge, delete the branch, and only then cut N15.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git checkout main && git pull --ff-only
# confirm main is green, then:
git checkout -b epic/n15-media-and-notes
```

N15 adds `MediaStore`, `CameraService` and `VoiceRecorder` — and `LambingRepository`'s constructor
grows its `MediaStore` parameter there, not here. Cutting N15 from anything other than a green merged
`main` means rebasing a gateway onto a moving repository.

## Risks, and what is irreversible

**Irreversible in this epic — say it out loud in the PR body:**

- **Two widget keys become test contracts forever.** `quick_entry.confirm` and
  `quick_entry.event.lambing` are read by `test/features/tap_budget_test.dart` from this epic onward,
  and by N16-T02a, N33-T01 and the four integration journeys after that. R59: *"a key is a test
  contract, so renaming one is a breaking change to `test/features/`."* Spell them right the first
  time.
- **The `docs/` amendments in T04 and T05.** A superseded rule is **struck with its reason**, never
  quietly rewritten (`00-README` §10). Once `CONVENTIONS §2.11` and `07 §15` are edited, the previous
  wording exists only in git history.
- **`lambings` gains its first edit verb** (T05's strike). R37's standing rule — *a table without the
  provenance quad has no edit verb* — is satisfied because `Lambings` carries the quad; but from that
  commit on, every reviewer reads that file under the never-waved-through rule.

**Not irreversible, and must not appear in this diff at all:** `drift_schemas/`, `lib/core/db/tables/`,
`android/`, `ios/`, `pubspec.yaml`. **If a file under any of those paths shows up in this branch, stop
and find out why.** Every column this epic writes was frozen at N07-T08; every package it needs was
resolved at N00-T03.

**Risks specific to N14:**

| Risk | Why it bites here | What holds it |
|---|---|---|
| **`beginLambing` returns an id and throws, and `guard()` takes a `Future<WriteOutcome> Function()`** | The two signatures do not compose. The obvious fix — call `beginLambing` outside the guard, as `07 §6.1`'s own snippet does — deletes the double-tap defence on the product's central write, and the second tap of a cold-thumb double-fire is a second lambing record | T03 routes it through `guard()` and carries the id back as `WriteCommitted.insertedId`, which is exactly the single wrapping call site R33 describes. `07 §6.1` is amended in T03's commit |
| **`lambingWriteControllerProvider` is the wrong controller for this tap** | `07 §6.1` names it, and it lives in `lib/features/lambing/`. Quick Entry importing it is a `layer.sibling` violation — not a style point, a build failure | T03 uses `quickEntryWriteControllerProvider` (`CONVENTIONS §3.4` declares both) and reaches the repository through `lib/data/`, which layer rule 5 permits |
| **`createEwe` needs `unlocked`, and `EntitlementRepository` is N30-T02** | The temptation is to defer the whole policy call to N30, which is critique defect S5 restated | The `entitlements` row exists from `seedFirstRun` (N07-T07) and is readable inside the transaction. T01 reads it with a private select; N30-T04 replaces that read with the repository collaborator and changes no signature |
| **The FTS5 source triggers fire on the create-on-the-fly path** | `search_docs.title` and `body` are `NOT NULL` while every source column is nullable. A trigger missing one `COALESCE` aborts the insert with a `NOT NULL` failure — *at 03:20, from a trigger nobody was looking at* (`03 §9.2`) | T01 and T02 each assert a create with every optional column null. The triggers are N07-T07's; this epic is the first code that exercises them |
| **P2 leaves `confirmSaved` with no channel** | `06 §10.3`'s implementation is a `SnackBar`; its stated fallback is an `OverlayEntry`; P2 forbids both — *"no floating overlay"* | T04 makes the committed row itself the receipt and names the one new type it needs, registering it in `CONVENTIONS §2.11` in the same commit rather than inventing it inside a widget file |
| **The undo window has no number anywhere in the doc set** | `07 §15.2` states it as a widget lifetime, which P2 abolished. A developer will pick a number in a widget and the ARB copy will drift from the timer | T05 declares one `const Duration`, interpolates its `inSeconds` into the ARB message, and records the chosen number as a ruling in the PR body |
| **`HapticFeedback.successNotification()` may not exist on 3.44.8** | `06 §10.1` asserts it is real; `07 §5.5`, `10 §11` and `12` carry it as unverified; `00-README` §10 lists it as a known open contradiction | T04 runs `REFERENCES §22.E` E1's five-minute check **before** writing the call, and degrades to `heavyImpact()` with the design intent unchanged if it is absent |
| **The active-only unique index versus `duplicateActiveTag`** | `07 §3.3` says the warning *"never blocks the create"*; `03 §6`'s partial unique index makes a second **active** 412 unstorable. `00-README` §10 names this as an open contradiction and calls it a domain question | T01 does **not** resolve it. On the live path it is unreachable — `rankTagMatches` reads active animals only, so "Create 412" is offered only when no active 412 exists — and the repository maps the constraint failure through `shedFailureFrom` rather than crashing. The ruling belongs to N26-T04's calm path |
| **The tap budget is counted in the frame-1 window** | `07 §5.3`: until the tag index resolves, creating a new ewe costs **one extra tap**. A budget test written against an unresolved index measures 6 and is wrong for the wrong reason | T06 seeds the ewe and relies on `pumpApp`'s trailing `pumpAndSettle()`; the test asserts the confirm key reads *"Use 412"*, not *"412 →"*, before it counts |
| **A test that pumps between the two taps** | It passes, proves nothing, and gets "fixed" by adding the cooldown `02 §7.1` rule 1 forbids | T03's double-tap case has no `pump` between the taps, and the reason is a comment in the file |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] `drift_schemas/`, `lib/core/db/tables/`, `android/`, `ios/` and `pubspec.yaml` are untouched by this diff
- [ ] `createEwe` takes `EntryContext` in its **first** commit, and `EntryContext.liveEntry` never returns `BlockedByCap` at any flock size, season count or hour
- [ ] `beginLambing` returns a `LambingId` and throws; every other write on this branch returns `WriteOutcome`
- [ ] every mutation the screen performs goes through `WriteController.guard()`, and each has a double-tap test with **no pump between the taps**
- [ ] `showSnackBar(`, `save`, `commit(`, `submit(`, `isDirty`, `draft` and `Dismissible` appear nowhere in the diff, and no `[exempt]` line was added
- [ ] **P2's two amendments landed with their tasks** — `CONVENTIONS §2.11` in T04, `07 §15.1` and `§15.2` in T05 — each struck with its reason
- [ ] the undo window is one `const Duration`, its `inSeconds` is what the copy says, and it does not survive a restart
- [ ] every time this epic renders carries its provenance label; no bare `03:24` anywhere
- [ ] the `uk-zone` DST cases exist for `local_date` (T02), the tap budget (T06) and the quiet window (T07), and each fails loudly under a wrong `TZ`

## Demoable on merge

**Five taps from launch to a committed `beginLambing` row**, asserted by
`tap_budget_test.dart` on keyed finders — and the cap never speaks on the live-entry path, at any
entitlement state or hour.

## Notes

The old plan's six-tap assertion spent its sixth tap on
`find.byKey(Key('lambing_entry.birth_type.twin'))` — a screen that does not exist until N16 and a key
**P8 abolished**. The budget splits: five taps to the committed row here, the sixth tap — the first
tally stroke — in N16-T02a. This closes critique defect S4.

Two more things this epic starts and does not finish, stated here so neither is rediscovered per
screen:

- **`kPumpableVariants` stays at one entry.** N13-T07 created it with `quick_entry`; N14 adds no
  screen, so it adds no variant. The next row is N16-T09's.
- **`test/support/seeds.dart` gains `setEntitlement` and `setEwesInCurrentSeason`** in T07 (`12 §5.3`
  declares both). It does **not** gain a fixture: `flock_15_at_cap.json` is written by `tool/seed.dart`
  through the restore path in N23, and the switch from seed helpers to fixtures is N23-T06 (critique
  defect S3).

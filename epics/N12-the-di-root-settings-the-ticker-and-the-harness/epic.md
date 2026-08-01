# N12 — The DI root, settings, the ticker and the harness

| | |
|---|---|
| **`00-README` §9 step** | 4 (3 of 3) |
| **Depends on** | N11 |
| **Size** | L |
| **Was** | E09b, plus `SettingsRepository` pulled forward from E26 |
| **Branch** | `epic/n12-di-root-and-harness` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

`providers.dart` and the DI graph as far as it can honestly reach today, `SettingsRepository`
(pulled forward because the export banner writes `app_settings` in N21, nine epics before the
Settings screen), the one ticker, `WriteController.guard()`, and a test harness that builds **only what
exists**.

The word *honestly* is the whole epic. `CONVENTIONS` §3.1 catalogues **thirty** providers for
`lib/data/providers.dart`. At the end of N12 that file declares **seven**, because twelve repositories
and seven gateways have not been written yet and a `FutureProvider<FlockRepository>` whose body throws
`UnimplementedError` compiles, type-checks, reads as progress and is a lie. The same rule produces the
harness's shape: `pumpApp` over `NativeDatabase.memory()`, `Device`, `seeds.dart` — **no gateway fakes
and no `kPumpableVariants`** (critique defect S1).

## Why the epic sits here

`00-README` §9 puts this at **step 4**, the last of the four epics that share it (N09 theme, N10
components, N11 first frame, N12 wiring). §9's stated reason for step 4, not re-derived here:

> *"The first frame is the product's promise, and the no-white-flash work touches native files you do
> not want to revisit. **Everything after this runs inside a real app.**"*

N12 is the clause in bold. N11 built an app that paints; N12 is what makes it an app that can *reach a
row*. Three consequences bind the scope:

- It comes **after** N11 because `databaseProvider` is opened from the first post-frame callback in
  `lib/app.dart` (`02 §9.1`, decision #21) — the boot kick exists already and has had nothing to kick.
- It comes **before** N13 because step 5 is *"Quick Entry, end to end"*, and §9's reason for putting
  Quick Entry there is that *"it forces you to build every piece of machinery the other eleven screens
  reuse."* Three of those pieces are N12's, not N13's: the container the screen is pumped in, the
  `WriteController` its write extends, and the ticker its pen-board sibling reads.
- Nothing here is schema-shaped, so nothing here could have justified being earlier than the freeze
  (step 3, N07 + N08).

`SettingsRepository` is the one thing in this epic that is not from §9's step 4. It is pulled forward
by critique defect **S6**: N21's end-of-day export banner writes `last_exported_at`,
`last_export_prompted_at` and `export_prompt_dismissed_for_season`, and `CONVENTIONS` §2.13 gives
`ExportRepository` *"nothing — read + artifact assembly only."* Without T02 the banner epic invents a
second `app_settings` writer, which is how a settings row ends up with two owners and one of them
wins at 3am. The Settings **screen** stays in N29.

## What is observably true when this epic merges

Run these on the merged `main` and watch them pass — this is the demo:

```bash
fvm flutter test test/data/providers_test.dart test/data/settings_repository_test.dart
fvm flutter test test/features/minute_tick_test.dart test/features/write_controller_test.dart
fvm flutter test test/support/harness_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone      # T02, T03 and T05 each add a file
make check && make test
```

- **A widget can be pumped against a real database.** `tester.pumpApp(const SizedBox(), db: db)`
  builds a themed, `en_GB`, dark, notch-padded tree over `NativeDatabase.memory()` with
  `databaseProvider` overridden and **no production override anywhere**. Every widget test in the
  remaining twenty-two epics enters through this one function.
- **`guard()` refuses a second invocation while the first is running.** Drive a `WriteController`
  whose action never completes, call the verb twice, and the action closure has run **once**. Complete
  the first write and call again — and it runs, because `guard()` prevents concurrency, not
  repetition (`02 §7.1` rule 1).
- **One ticker, aligned to the wall-clock minute, that stops when the last listener goes.**
  `minuteTickProvider` yields `Instant`; `grep -rn 'Timer.periodic' lib/` returns nothing, and it
  returns nothing because `net.sync_timer` fails the build, not because nobody wrote one.
- **Every `app_settings` column round-trips**, proved by one table-driven test over the setting list
  rather than fourteen hand-written ones — so the fifteenth setting joins the suite for free. Writing
  `palette = 'dark'` comes back as `WriteFailed`, not as a silent correction.
- **The first frame still paints before the database opens.** `themeProvider` is a synchronous
  `Provider<ShedThemeSet>` whose not-yet-loaded arm is the `const night` pair; a widget test that
  never resolves `databaseProvider` still renders a themed tree.
- **`lib/` contains zero occurrences of `overrideWith` and `overrideWithValue`**, and
  `test/support/harness.dart` is built almost entirely out of them. That asymmetry is the
  `rp3.overrides` rule landed in N03-T06, and this is the epic that first proves it was scoped right.

What is deliberately **not** demonstrable yet: any repository other than settings, any gateway, any
screen, and `kPumpableVariants`. See Notes.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/02-state-di-navigation.md` | §1 (why 2.6.1 exactly) · §2.1–§2.4 (the Riverpod-3 ban list and the thirteen `rp3.*` gate rows) · §3 (the 2.6.1 spelling card) · §4.1–§4.6 (provider shapes, auto-dispose policy, `watch`/`read`/`listen`, reading an `AsyncValue`, where providers are declared) · §5.1–§5.4 (the DI graph, no production overrides, the clock is not a provider, overriding in tests) · §6 (controller conventions) · §7 + §7.1 (`WriteController`, `guard()`, the four rules) · §9.1 (the resume path and the one legitimate `ref.invalidate`) | the provider graph, the override rules, the write gate and the harness |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree) · §1.1 layer rules 2, 3, 4, 5, 7 and `layer.root` · §2.2 (`Instant`, `appNow()`) · §2.8 (`AppDatabase`, `openAppDatabase`) · §2.11 (`ShedThemeSet`, `buildShedTheme`) · §2.12 (the seven gateways — **none of which exist yet**) · §2.13 (`SettingsRepository` owns `app_settings`; `ExportRepository` owns nothing) · §2.14 (`Terminology`, `ResumePolicy`) · §3.1 (the thirty-provider catalogue) · §3.3 (the ticker) · §3.5 (what is not in the graph) · §4.2–§4.3 (class and provider naming, the five documented exceptions) · §5.2–§5.3 (vocabulary and the banned words) · R23, R25, R29, R33, R40, R56, R57, R68, R72, R74 | **BINDING** on every path, type, provider and word |
| `docs/engineering/12-testing.md` | §2.1–§2.3 (`atFixed`, the `fakeAsync` trap, the ambiguous hour) · §3.1 (`testDatabase()` and `closeStreamsSynchronously`) · §3.5 (durability as a testable property) · §4.2 (the seven fakes — **and which epic each belongs to**) · §5.1 (`shedContainer` and `pumpApp` in full) · §5.2–§5.3 (the two seeding routes; the closed twelve-file list) · §6.2 (`kPumpableVariants`, and why it cannot exist yet) · §11.2 (`dart_test.yaml` and the preset dispute) · §11.6 (`Future.delayed` in a test body is banned) | the harness, the tiers, and what may exist yet |
| `docs/engineering/03-data-model-and-schema.md` | §5.13 (`AppSettings` — every column, every `CHECK`, the one-row rule) · §5.12 (`VocabTerms`, `TerminologyOverrides`) | the setting list the parameterised test iterates |
| `docs/engineering/01-architecture.md` | §3.2–§3.3 (the rule table: `net.sync_timer`, `stream.invalidate`, `rp3.*`) · §4.1 (repository providers fold the await) · §5.2–§5.4 (`WriteOutcome`, `ShedFailure`, `UnexpectedFailure`) · §7.2 (the ticker body) | the failure types, the gate rows and the ticker's shape |
| `docs/engineering/05-domain-correctness.md` | §8.1 (`Terminology`, `TermLabel`, and where the defaults come from) | the one open seam in T02 |
| `docs/engineering/06-design-system.md` | §2.1 (`themeProvider` is synchronous and the first frame paints before the database opens) | why `themeProvider` may not await |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #11, #12, #13, #15, #17–#22, #46, #63, #66, #90, #103, #111, #112, #113 | `flutter_riverpod` **2.6.1** exact · Flutter **3.44.8** / Dart **3.12.2** · `drift` **2.34.2** · `mocktail` **1.0.5** |
| `epics/00-PLAN-CRITIQUE.md` | S1 (the harness) · S3 (the fixture) · S6 (`SettingsRepository`) · §9 changes 5 and 9 · §11.4 (skills per epic) | why the harness is three things and not eleven |
| `CLAUDE.md` | the 3am test · P2 (there is no SnackBar) · the banned words | 60 × 60 pt, 18 px floor, dark only, no `draft`/`save()`/`sync` |

## Tasks

Strictly sequential. T02 edits the file T01 creates; T03's ticker and T04's controller are both read
by T05's harness through the container T01 declares.

| Task | Depends on | One line |
|---|---|---|
| [N12-T01](N12-T01-providersdart-the-di-graph-as-far-as-it-can-honestly-reach.md) | N11, its last task | `providers.dart` — the DI graph as far as it can honestly reach |
| [N12-T02](N12-T02-settingsrepository-and-the-four-settings-providers.md) | N12-T01 | `SettingsRepository` and the four settings providers |
| [N12-T03](N12-T03-minutetickprovider-one-boundary-aligned-ticker.md) | N12-T02 | `minuteTickProvider` — one boundary-aligned ticker |
| [N12-T04](N12-T04-writecontroller-and-guard.md) | N12-T03 | `WriteController` and `guard()` |
| [N12-T05](N12-T05-testsupport-pumpapp-device-and-seedsdart-and-nothing-else.md) | N12-T04 | `test/support/` — `pumpApp`, `Device` and `seeds.dart`, and nothing else |

T04 does not technically depend on T03 — `write_action.dart` and `ticker.dart` never meet. The order is
kept because T05's harness needs both and because one commit per task in a fixed order is what makes
the branch readable. Do not reorder to "parallelise": there is one developer.

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N11 is merged and `main` is green before this starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version          # must print 3.44.8; .fvmrc is the pin
git checkout -b epic/n12-di-root-and-harness
```

**2 — One commit per task, five commits, in task order.** Each task file names its commit line
verbatim; use it. Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

One commit in this epic carries an extra obligation, and it is the one to read twice
(`00-README` §7.4):

- **T03 may need a fifth `[exempt]` line in `tool/policy_allowlist.txt`.** `stream.invalidate` bans
  `ref.invalidate(` under `lib/` with no exemption, and `02 §9.1` requires exactly one call —
  `ref.invalidate(minuteTickProvider)` in `lib/app.dart`'s `resumed` arm. R56 fixes the day-one total
  at four. An `[exempt]` line *"deletes a rule for one file, forever, silently, and the reason goes in
  the commit message that adds it."* If T03 adds one, that reason is the whole commit message, and the
  PR body says so at the top.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test         # the suite, randomised, + TZ=Europe/London --tags uk-zone
```

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the diff
in `00-README` §10's irreversibility order. For this branch that order is:
`tool/policy_allowlist.txt` (if T03 touched it) → `lib/data/settings_repository.dart` and
`lib/data/providers.dart` → `lib/core/write_action.dart` and `lib/core/time/ticker.dart` →
`lib/app.dart` → `test/support/`.

`lib/data/**` is high in that order for a reason that applies here specifically: `SettingsRepository`
is the first repository in the project, and whatever shape it takes is the shape the other eleven copy.

**4 — Open the PR and answer the five §12 questions** in `.github/pull_request_template.md`
**verbatim, in the PR body**. Three of the five land in this epic and must not be answered "n/a":

- **§12.1 — never default a withdrawal period.** `app_settings` has no withdrawal column and must
  never gain one; `seedTreatment` in T05 takes `withdrawalDays` as a **required** parameter with no
  default. Say both.
- **§12.4 — never silently correct an entry.** T02's `CHECK` constraints must surface as `WriteFailed`,
  never as a clamp. `turn_out_threshold_hours` outside 1–336 is a refusal, not a nearest legal value.
- **§12.5 — timestamps carry provenance.** T02 writes three `Instant` columns through
  `InstantConverter`; T05's `atFixed` is the mechanism every later provenance test uses. The uk-zone
  cases in T02 and T05 are the evidence.

§12.2 (no veterinary advice) and §12.3 (not a regulatory record) do not reach this epic — say that, and
say that `turn_out_threshold_hours` is the column that would have, and why `03 §5.13` rules it a
display threshold rather than a recommendation.

**5 — Wait for the pipelines.** Three jobs run for this epic and each proves a different thing.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart run tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` · the `NSAppTransportSecurity` grep (**G5** text half) | The Riverpod-2.6.1 story, mechanically. All thirteen `rp3.*` rows fire against `lib/` and `test/`; `rp3.overrides` fires against `lib/` **only**, which is what lets T05's harness exist at all. `--fatal-infos` is independently the proof that no Riverpod-3-only class or parameter is in the tree (`02 §2.1`: eight of the banned APIs fail the analyzer). `net.sync_timer` proves T03 used `Future.delayed`; `db.save_verb` proves T02 has no `save*(` in `lib/data/`; `time.dart_clock` proves T03 called `appNow()` and not `clock.now()`. **`[exempt]` is not counted here** — if T03 added a fifth line, this job still passes and only the reviewer catches it |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | A **negative**, and that is the point: N12 adds no table and no column, so `drift_schemas/` must not move and `database.g.dart` must not change. If this job is red on this branch, `SettingsRepository` has reached for a column that does not exist, or something under `lib/data/` has pulled a second generator into the build — and drift is the entire generator budget (decision #16) |
| `test` | `flutter test` randomised · `TZ=Europe/London --tags uk-zone` over the **whole** suite · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · the coverage artefact (reported, **never** gated) | The five anchors plus the three zone-pinned files T02, T03 and T05 add. The `uk-zone` leg is load-bearing three times over in this epic: `InstantConverter` round-tripping 01:30 on 25 October 2026 (T02), the ticker's boundary arithmetic inside a repeated hour (T03), and `atFixed` pinning `appNow()` in that hour (T05). Untagged, all three pass under UTC for the wrong reason. **`libsqlite3-dev` is installed by this job** — every test in T02 and T05 touches real SQLite |

`android` also runs on every PR (`13 §4.2`), builds the release AAB and asserts **G1**. N12 changes no
native file, no permission and no dependency, so it proves nothing this epic authored — but it must
stay green. If it goes red here, look at `pubspec.lock`, not at a provider.

Goldens do **not** run on this PR: the `goldens` job is `v*` or `workflow_dispatch` only. The eight
images are N33-T07 and they will be pumped through T05's harness.

**6 — Merge, delete the branch, and only then cut N13.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git checkout main && git pull --ff-only
# confirm main is green, then:
git checkout -b epic/n13-quick-entry-deck-and-keypad
```

N13 is the first epic that pumps a real screen through `pumpApp` and the first that adds a row to
`kPumpableVariants`. Cutting it from anything other than a green merged `main` means every widget test
in the project rebased onto a moving harness signature.

## Risks, and what is irreversible

**Nothing in this epic is irreversible in the schema sense** — and that is worth saying out loud
rather than leaving as an absence, because three of the four irreversible categories are simply not
present:

- **No schema snapshot.** `drift_schemas/` must not appear in this diff. T02 writes to `app_settings`;
  it does not add a column to it. If you find yourself wanting one, stop: `03 §5.13` already has
  fourteen and the freeze was N07.
- **No native file.** `android/` and `ios/` must not appear in this diff. N11 owns the launch layers.
- **No published artefact.** No tag, no store listing, no signing key.

**What *is* expensive to change, stated as loudly as an irreversible thing, because the cost is paid
by other epics rather than by this one:**

- **A fifth `[exempt]` line, if T03 adds one** (see the PR workflow, step 2). This one *is* forever
  and silent. R56: four on day one; a fifth is a review conversation, not an edit.
- **`pumpApp`'s signature** (T05). Twenty-two epics and roughly 250 widget tests enter through it,
  including all 252 overflow-matrix cells and all eight goldens. Adding a required parameter later is
  a project-wide edit; the `...overrides` spread-last ordering is depended on by `12 §4.4`.
- **`WriteController`'s shape** (T04). Twelve write controllers extend it and every one inherits
  `guard()`'s concurrency semantics. Getting `state = const WriteRunning()` on the wrong side of the
  first `await` produces a bug that is invisible in every test that pumps between two taps.
- **`SettingsRepository`'s verb shape** (T02). It is the first repository written in the project. The
  other eleven copy it, including the ones that write records rather than preferences.

**Risks specific to N12:**

| Risk | Why it bites here | What holds it |
|---|---|---|
| **Declaring providers for things that do not exist** | `CONVENTIONS` §3.1 lists thirty and reads like a checklist. Twenty-three of them name a class no file declares. A stub that throws `UnimplementedError` compiles and passes review as "wiring" | T01 lands **two**, T02 adds **five**, and the file carries a header ledger naming the epic that adds each of the remaining twenty-three. The anchor test asserts the declared set equals the ledger |
| **The Riverpod-3 recipe** | Every tutorial, blog post and model completion published after 2025 shows the 3.x API. `class X extends Notifier<S>` with `NotifierProvider.autoDispose` is the single most likely line to be written in T04, and the analyzer's message points at the bound, not at the fix | `02 §2.1`'s table is the fix list, `--fatal-infos` catches eight of the nine, and the thirteen `rp3.*` gate rows catch the ones that compile clean. Load `shed-riverpod-providers` before writing a line |
| **`stream.invalidate` versus the one legitimate invalidate** | The rule is a blanket ban under `lib/`; the resume path needs exactly one call, and `lib/app.dart` already exists without it because `minuteTickProvider` did not | T03 owns the collision, states both sides, and either adds the `[exempt]` line with its reason or carries the conflict into the PR body. It does not quietly drop the invalidate — that would leave every elapsed-time display twenty minutes stale after a resume |
| **`atFixed` used on an elapsed-time test** | `Clock.fixed` freezes `appNow()`, so a ticker or pen-tile test wrapped in it measures 0 h **and passes** (decision #113). T05 is where the helper is authored and where the convention is set for every later epic | T05's doc comment carries the warning verbatim, and T03's elapsed-time case pins nothing and offsets the seed instead. Every `atFixed` call in the widget tier gets a comment saying why it is safe |
| **`terminologyProvider`'s defaults have two homes** | `CONVENTIONS` §3.1 puts the provider in `lib/data/providers.dart` *"derived from `settingsProvider` + the seeded defaults"*; `05 §8.1` puts the defaults in `lib/features/settings/terminology_bootstrap.dart`, *"which already has a `BuildContext`"*, because `lib/data/` may not import `AppLocalizations`. Both cannot be true of one expression | T02 states the seam, lands the provider with the defaults as an injected map, and either rules it or carries it into the PR body with both citations. It does not invent a third source of default labels |
| **`ShedPaletteId.values.byName('red')` throws** | `deepRed`'s stored key is `'red'` (R35) — the one member whose key does not match its name. `byName` is the obvious spelling and it is wrong, and it is wrong at the moment a shepherd who chose deep red opens the app | T02 looks up by `.key`, and an unrecognised key resolves to `night` rather than throwing. A palette that cannot be read must not be a crash on the first frame |
| **A second `app_settings` writer in N21** | S6 is exactly this defect, deferred. Pulling the repository forward only closes it if N21 can see that it must call this one | T02's class doc comment names N21, names the three banner columns, and carries `08 §11` / `09 §8.3`'s rule that `last_exported_at` is stamped on `ShareOutcome.completed` **and** `unknown`, never on `dismissed` and never before the sheet opens |
| **The harness grows the fakes anyway** | `12 §5.1` prints `shedContainer` with seven gateway overrides and seven optional named parameters. It is the most copyable snippet in the doc set and none of the seven types exist | T05 lands the container with **one** override and **zero** gateway parameters, and the header comment names N15, N21, N24, N29 and N30 as the homes of the seven. An optional `share:` parameter that overrides nothing is worse than no parameter: it silently accepts a fake |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] `lib/data/providers.dart` declares exactly seven providers, and its header ledger names the epic that adds each of the other twenty-three
- [ ] `databaseProvider` is a `FutureProvider<AppDatabase>`, keepAlive; `Provider<AppDatabase>` appears nowhere
- [ ] `lib/` contains zero occurrences of `overrideWith` and `overrideWithValue`; `test/support/harness.dart` contains them and the gate is silent about it
- [ ] no `AsyncValue` accessor (`.value`, `.valueOrNull`, `.requireValue`, `.hasValue`, `.asData`) appears in the diff; every read is an exhaustive `switch`
- [ ] the type name `Ref` appears nowhere, and `ref.mounted` appears nowhere
- [ ] `Timer.periodic` appears nowhere under `lib/`, and `net.sync_timer` carries no exemption
- [ ] every mutation path in the app goes through `WriteController.guard()`, and `guard()` sets `WriteRunning` **before** its first `await`
- [ ] `WriteState` subclasses do not implement `==`
- [ ] `test/support/` holds exactly `harness.dart`, `seeds.dart` and `harness_test.dart` — no fake, no `kPumpableVariants`
- [ ] three `@Tags(['uk-zone'])` files are added (T02, T03, T05), each with the `setUpAll` offset guard, and `TZ=Europe/London fvm flutter test --tags uk-zone` reports the expected count rather than 0
- [ ] the diff contains no file under `drift_schemas/`, `lib/core/db/`, `android/` or `ios/`
- [ ] **if a fifth `[exempt]` line was added, its reason is the commit message and it is the first line of the PR body**

## Demoable on merge

`pumpApp` builds a widget against `NativeDatabase.memory()` with no production override, and
`guard()` refuses a second invocation while the first is running.

## Notes

**The harness builds `pumpApp`, the `Device` table and `seeds.dart` — nothing else.** The
seven fakes wrap gateways that do not exist yet (N15, N21, N24, N29, N30) and `kPumpableVariants` maps
route names to screen constructors that do not exist yet. Each fake lands in the epic that introduces
its gateway and extends `pumpApp`'s override list in the same commit; `kPumpableVariants` is created in
N13 with one entry and grows one row per screen epic. This closes critique defect S1.

Concretely, the ledger every later epic reads out of `test/support/harness.dart`'s header comment:

| Fake (`12 §4.2`) | Gateway it wraps | Lands in |
|---|---|---|
| `FakeMediaStore`, `FakeCameraService`, `FakeVoiceRecorder` | `MediaStore`, `CameraService`, `VoiceRecorder` | N15 — media and notes |
| `FakeShareService` | `ShareService` | N21 — export, CSV, PDF and share |
| `FakeNotificationScheduler` | `NotificationScheduler` | N24 — reminders, rows and reconcile |
| `FakeWakelockController` | `WakelockController` | N29 — settings |
| `FakePurchaseService` | `PurchaseService` (the store seam, R74) | N30 — monetization |

**And the fixture is not here either.** `12 §5.2` gives two seeding routes; N12 lands only the first.
`restoreFixture(db, 'flock_400_3seasons.json')` goes through `RestoreService`, which is N23, and the
fixture itself is written by `tool/seed.dart` through the restore path in the same epic (critique
defect S3). Until then every test seeds with the targeted helpers, and the switch is one task in the
restore epic — N23-T06, which is the task that proves the fixture is loadable at all. `harness.dart`
says this once, in a comment, so it is not rediscovered per screen.

**`test/support/` is a closed list of twelve files** (`12 §5.3`). N12 opens it with three of them; the
other nine have named homes. A thirteenth file is a review conversation.

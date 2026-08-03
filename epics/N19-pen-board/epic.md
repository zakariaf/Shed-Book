# N19 — Pen Board

| | |
|---|---|
| **`00-README` §9 step** | 6 (5 of 5) |
| **Ships in** | `v1.0.0` |
| **Depends on** | N18 |
| **Size** | L |
| **Was** | E16, closer task deleted |
| **Branch** | `epic/n19-pen-board` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

The whiteboard, but timed and never wiped: who is in which pen, for how long, and who is past the
threshold **the shepherd set**. Spec §7.4 calls it *"the digital replacement for the whiteboard, and a
feature paper genuinely cannot match"*, and requires it to work *"as a glanceable board — legible from
arm's length in a head torch"*.

Seven tasks: the two write verbs the database refuses to let go wrong (`enterPen`, `exitPen`), one
occupancy projection read by two screens, lazy pen creation so day one is not a setup wizard, elapsed
time driven by N12's single ticker, the row component with its five statuses, the three one-tap verbs
with the edited-time marker, and the matrix variant with the board's semantics tree.

The epic writes **no schema**. `pens`, `pen_occupancies`, `pen_occupancy_lambs`, the partial unique
index `idx_penocc_one_open` and the §12.5 provenance quad on `pen_occupancies` were all frozen in
N07-T05 and snapshotted in N07-T08. If a file under `drift_schemas/` appears in this branch, stop.

## Why the epic sits here

`00-README` §9 puts the pen board in **step 6**, *"the rest of the 3am path: Lambing Entry, Lamb Card,
Foster, Pen Board — plus the one 60 s ticker"*, with its stated reason, not re-derived here:

> *"These are variations on machinery step 5 already built. Foster and the pen board carry their own
> tap budgets."*

Four consequences bind the scope:

- It is **after N07** because the mechanism this whole epic rests on is an index, not a code path.
  `idx_penocc_one_open ON pen_occupancies (pen) WHERE exited_at IS NULL` is *"the whiteboard gets
  wiped"* solved at the storage layer (decision #34, 03 §5.9). Nothing in N19 may re-express it as a
  Dart check.
- It is **after N12** because `minuteTickProvider` (N12-T03) is the only ticker in the app and the pen
  board is its principal consumer. The board is also the screen 02 §4.2 names when it explains why
  that provider is `.autoDispose` at all.
- It is **after N13** because the deck statement (`quickEntryDeckProvider`, R28) already reads the
  *penned* half of this epic's projection. Decision #67: *"in the pens"* is the same projection the
  pen board watches, ordered differently. Two answers to *who is penned* is the failure the product
  exists to fix.
- It is **after N18** because Foster settled the commit-then-print shape (P2 — the receipt is the
  committed row) that every verb on this board reuses, and because both screens carry tap costs that
  are asserted rather than claimed.

Both tracks `00-README` §9 says run from day one run here: **accessibility** — the board's semantics
tree is the hardest one in the app (10 §3.5, *"hard case A"*) and it is authored in the commit that
creates the widget, never swept in later — and **the ARB**, where every string lands with a
`description` and no domain noun is a literal (10 §8.5). N33 only verifies.

## What is observably true when this epic merges

Run these on the merged `main` and watch them pass — this is the demo:

```bash
fvm flutter test test/data/pen_repository_test.dart
fvm flutter test test/features/pen_board_test.dart
fvm flutter test test/design/components_test.dart
fvm flutter test test/features/overflow_matrix_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check && make test
```

- **The database itself refuses two ewes in pen 3.** A second `enterPen` on an open pen returns
  `WriteFailed`, and the test proves the refusal came from `idx_penocc_one_open` by naming the index
  in the raised constraint — not from a Dart guard that the next code path can forget.
- **One projection, two screens.** The board and Quick Entry's *in the pens* strip agree on the set of
  penned ewes, asserted by pumping both against one seeded database — with an orphan pen (lambs, no
  ewe) seeded so a naive length comparison fails.
- **A flock with no pens shows one large action, not an empty grid and not a wizard.** `seedFirstRun`
  writes zero pens on purpose (decision #42); the first pen is created by the tap that fills it.
- **Every row ticks in the same frame.** One `minuteTickProvider` boundary moves every hours figure at
  once; there is no `Timer.periodic` anywhere under `lib/`, and popping the board leaves the ticker
  with no listeners.
- **A ewe penned at 22:00 GMT on 28 March 2026 reads `9h` at 08:00 BST, not `10h`.** Elapsed physical
  time from epoch millis, across the UK spring-forward, in the three weeks of the year this app
  matters.
- **No status is distinguishable by colour alone.** Each of the five statuses carries a word and a
  non-colour mark; read the board under the OS grayscale filter and it reads identically (06 §11's
  ship gate).
- **Turn out costs one tap once the row is open, and nothing disappears under your hand.** The row
  re-prints in place as `TURNED OUT 04:12` and stays on the board for the rest of the night.
- **A corrected entry time says so on the board**, not only in the sheet — `†` plus the word, never
  the mark alone (§12.5, 07 §9.6).
- **`pen_board` is the seventh row of `kPumpableVariants`** and pumps clean at 3 devices × 3 text
  scales × 2 bold states, with one labelled semantics node per pen and a summary node first.
- **Nothing about money renders**, at any entitlement state or hour: the pen board is one of the five
  shed screens (07 §1.1, decision #90).

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/07-screens.md` | §9 (all of it: the query, the timer, tile content, states, actions and tap costs, the §12 disclosures), §1.1–§1.2 (shed screen, the one-query rule), §15.1–§15.3 (undo per verb) | the screen brief this epic implements |
| `shed-book-spec.md` | §7.4, §5, §12 | the whiteboard replacement, hours since penned, one-tap actions, the 3am floor and the five safety rules |
| `docs/engineering/03-data-model-and-schema.md` | §5.9 (`Pens`, `PenOccupancies`, `PenOccupancyLambs`, every CHECK and index), §8 (the live-board statement and the hours-since-penned rule), §5.13 (`turn_out_threshold_hours`), §5.14 (who writes what), §10 (no pens are seeded) | the storage shape this epic reads and writes, and may not change |
| `docs/engineering/02-state-di-navigation.md` | §4.1–§4.2 (provider shapes, the auto-dispose policy), §4.5 (reading an `AsyncValue`), §5.1 (`penBoardProvider`, `watchBoard`), §7 (`PenWriteController.turnOut`, `guard()`), §7.1 (the four rules and the double-tap test), §8.1–§8.2 (`Routes.penBoard`, the stack) | every provider, the write controller and the route |
| `docs/engineering/06-design-system.md` | §6.1 (`tapMin` 60, `tapPrimary` 72, `tapHero` 88, `gapMin` 16), §11 (pen-board glanceability, the five statuses, reflow, honest timestamps), §12 (`ShedPenTile` in the component inventory), §5.5 (tabular figures) | the component, the type scale and the five-status table |
| `docs/design/indelible.md` | §1.2 (the four rules), §2.7 (status without colour), §6.2 (the six marks), §7.5 (**the pen row — the tile that is not a tile**), §8 screen 7 (the board, the header, the sort, the one-tap chooser), §4.4 (88 px row height), §5.4 (haptics) | **the design system of record.** What the board actually looks like |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.5 (**hard case A** — the board's semantics tree, `PenTile`, `PenTileStatus`, `penTileSentence`, the §12.2 tension), §3.2 (label rules), §3.3 (`spellOutTag`), §3.4 (headings), §8.4–§8.5 (ARB and the terminology placeholder) | every label, and the ten facts the projection must carry |
| `docs/engineering/12-testing.md` | §2.2–§2.5 (the advancing fake clock, `Clock.fixed`, the ambiguous hour, the three commands), §2.4 (**the two published pen-board DST tests**), §3.3 (**the two published `PenRepository` tests**), §5 (`pumpApp`, `Device`), §6.1–§6.4 (the matrix and reachability), §7.4 (the semantics and geometric gates), §8.2 (`pen_board_12_pens` is one of the eight goldens — and it is N33's) | every test file this epic writes |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree and the eight layer rules), §2.13 (`PenRepository`, `enterPen`, `exitPen`), §3.2–§3.4 (`penBoardProvider`, `minuteTickProvider`, `penBoardControllerProvider`, `penWriteControllerProvider`), §4.1 (file names), §4.5 (widget keys), §4.6 (database names), §5 (vocabulary), R18, R19, R24, R25, R28, R30, R32, R36, R37, R53, R58, R59, R63 | **BINDING** on every path, type, provider, key and word |
| `docs/engineering/05-domain-correctness.md` | §2.9 (DST-1, the 9-hour case), §4.2 (`RecordedTime` and `provenanceLabel`), §7.2 (the origination line), §7.5 (what a threshold badge may say) | the arithmetic and the two safety rules this screen touches |
| `docs/engineering/01-architecture.md` | §4.4 (one statement per screen, `.distinct` in the repository, `readsFrom:`), §5.2–§5.3 (`WriteOutcome`, `ShedFailure`, `shedFailureFrom`), §7.2 (**bucket A — derived-at-render values**) | why nothing elapsed is ever stored |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #12, #22, #34, #42, #66, #67, #90, #103, #106, #113 | `flutter_riverpod` **2.6.1**, `drift` **2.34.2**, Flutter **3.44.8** / Dart **3.12.2** |
| `docs/skills/02-build-manifest.md` | §4.1 (**P2** — no SnackBar; undo is a time-boxed strike, its window stated in seconds), §4.3 (Indelible only), §4.4 defect 2 (`DEAD` is not an exempt stamp), §4.5 (P9, P10 and P14 are open) | the owner rulings that supersede a written document |
| `CLAUDE.md` | the four non-negotiables · the vocabulary table | *turn out*, *penned*, *pen occupancy*, *record*, *event*, *warning* |
| `epics/00-PLAN-CRITIQUE.md` | G1 (`ShedPenTile` is placed in this epic), S2, S3 (fixtures do not exist until N23), §11.3 | why T05 builds a component and why T07 seeds instead of restoring |

## Tasks

Strictly sequential. Each task depends on the one before it: nothing can be projected before the verbs
write rows, nothing can be rendered before the projection exists, nothing can tick before there is a
row on screen, no component can carry five statuses before something computes them, no verb can be one
tap before there is a row to tap, and the matrix cannot pump a screen that does not exist.

| Task | Depends on | One line |
|---|---|---|
| [N19-T01](N19-T01-penrepositoryenterpen-exitpenpenexitreason.md) | N18, last task · the pen cluster frozen in N07 | `PenRepository.enterPen` / `exitPen(PenExitReason)` |
| [N19-T02](N19-T02-penboardprovider-and-the-same-projection-quick-entry-reads.md) | N19-T01 | `penBoardProvider` and the same projection Quick Entry reads |
| [N19-T03](N19-T03-lazy-pen-creation-and-the-zero-pen-board.md) | N19-T02 | Lazy pen creation and the zero-pen board |
| [N19-T04](N19-T04-hours-since-penned-off-the-one-ticker.md) | N19-T03 | Hours since penned, off the one ticker |
| [N19-T05](N19-T05-shedpentile-five-statuses-two-non-colour-channels-each.md) | N19-T04 | `ShedPenTile` — five statuses, two non-colour channels each |
| [N19-T06](N19-T06-turn-out-move-and-mark-as-group-in-one-tap-and-the-edited-ma.md) | N19-T05 | Turn out, move and mark-as-group in one tap, and the edited marker |
| [N19-T07](N19-T07-the-matrix-variant-the-grid-semantics-tree-and-the-empty-sta.md) | N19-T06 | The matrix variant, the grid semantics tree and the empty state |

**T02 and T03 each fix a name no document fixes.** T02 declares `PenTile` and
`enum PenTileStatus { settling, ready, attention, loss, empty }` — 10 §3.5 names both and says out
loud that no sibling defines their fields. T03 declares `PenRepository.addPen`, which 07 §9.5 names
only as prose (*"creates the next-numbered pen immediately"*). Both are recorded in the task file with
their reasoning; if a second document later needs either, the ruling belongs in `CONVENTIONS` §6.

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N18 is merged and `main` is green before this starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version          # must print 3.44.8; .fvmrc is the pin
git checkout -b epic/n19-pen-board
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
`lib/data/pen_repository.dart` → `lib/data/providers.dart` → `lib/l10n/app_en.arb` →
`lib/routing/routes.dart` → `lib/core/ui/components/shed_pen_tile.dart` → `lib/features/pens/` →
`test/`. `lib/data/**` is never waved through, however small — this branch gives `pen_occupancies`
its first writer, and a row it writes wrong is a ewe in the wrong pen on a board people trust.

**4 — Open the PR and answer the five §12 questions** in `.github/pull_request_template.md`
**verbatim, in the PR body**. Three land squarely here and must be answered with a file and a test,
not with a sentence:

- **§12.2 — never give veterinary advice.** The turn-out threshold is the **user's**, always. The
  board's legend prints their own number (*"Ready = your 24 h threshold"*), `isReadyToTurnOut` takes
  the threshold as a parameter and holds no opinion, and no copy on this screen says a ewe is fit to
  turn out. 05 §7.5 is explicit that the badge is only acceptable *because* the threshold is user-set.
- **§12.5 — timestamps carry provenance.** `enterPen` writes the whole quad in one transaction,
  `time_source = 'auto'`, `original_effective IS NULL`, held by the paired SQL CHECK; and an edited
  entry time is marked **on the board**, with the word beside the mark. 07 §9.6: *"the board is what
  people trust; the board must not launder an edited time as a captured one."*
- **§12.4 — never silently correct.** Nothing on this board rewrites a row. A move closes one
  occupancy and opens another; both stay forever. `lib/data/` still cannot import
  `lib/domain/validation/`.

§12.1 and §12.3 do not appear on this screen — say so, and say which epic carries them (N20 and N21).

**5 — Wait for the pipelines.** Three blocking jobs run for this epic and each proves a different
thing.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` | The rules this epic is most likely to break: `layer.features` (a feature folder importing `package:drift` or `lib/core/db/` — the first thing the board's statement wants to do), `layer.sibling` (`lib/features/pens/` importing Quick Entry's controller for the deck), `time.dart_clock` (a widget reading a clock instead of taking the tick), `net.sync_timer` (`Timer.periodic` per row), the gesture ban (a board is where somebody reaches for swipe-to-turn-out and drag-to-move) and the token rules (a raw hex or a magic size in a new component) |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | A **negative**, and that is the point: N19 stores into frozen tables and must move no snapshot. A red `codegen` here means somebody edited `lib/core/db/tables/pens.dart` — which after N07-T08 is a migration on somebody else's phone, not an edit |
| `test` | `flutter test -P ci-fast` randomised · `TZ=Europe/London --tags uk-zone` (**unscoped** — the tag selects the files) · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · coverage artefact (reported, **never** gated) | The seven anchors and the 252-cell matrix. The `uk-zone` leg is what proves `test/data/pen_repository_dst_test.dart` and `test/features/pen_board_dst_test.dart` ran in `Europe/London`; under the runner's UTC there is no spring forward and the 9-hour assertion passes for the wrong reason |

`android` also runs on every PR (13 §4.2) and must stay green; N19 changes no native file and no
permission, so it proves nothing this epic authored. **`goldens` does not run on this PR** — it is
`v*` or `workflow_dispatch` only. `pen_board_12_pens` is one of the eight images (12 §8.2) and it is
**N33's** to create and baseline, not this epic's. Do not add a `matchesGoldenFile` call here.

```bash
gh pr checks --watch
```

**6 — Merge, delete the branch, and only then cut N20.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git checkout main && git pull --ff-only
make check && make test                     # main green after the merge
git checkout -b epic/n20-treatments-withdrawal
```

## Risks, and what is irreversible

**Irreversible in this epic — say it out loud in the PR body:**

- **Every widget key introduced here is a test contract** (R59) and is read by four test files:
  `pen_board.turn_out.<penId>`, `pen_board.move.<penId>`, `pen_board.pen.<penId>`,
  `pen_board.add_pen`. Renaming one later breaks the board's tests, the matrix and the semantics gate
  together. They are recorded in `07-screens.md` §9.5 in the same commit that creates them.
- **`PenTile` and `PenTileStatus` become a published shape** the moment T05 and T07 build on them —
  10 §7.3's checklist already asserts they exist in `lib/features/pens/pen_board_controller.dart`.
- **Nothing else here is irreversible**, and that is worth stating plainly: no schema, no snapshot, no
  native file, no published artefact, no allowlist line, no golden baseline. If this branch touches
  `drift_schemas/`, `lib/core/db/tables/`, `tool/policy_allowlist.txt`, `android/`, `ios/` or
  `test/features/goldens/`, the change is in the wrong epic.

**Risks specific to N19:**

| Risk | Why it bites here | What holds it |
|---|---|---|
| **The keepAlive projection watches the autoDispose ticker** | `penBoardProvider` is keepAlive (CONVENTIONS §3.2) and `minuteTickProvider` is autoDispose (R25). A keepAlive listener never goes away, so the ticker would keep waking the process every 60 s all night with the board nowhere on screen — destroying the exact battery argument decision #66 makes and 02 §4.2 calls *"load-bearing, not tidiness"* | T04 §5.3: the **widget** watches the tick, never the projection provider; and T04's test pops the board and asserts the ticker has no listener left |
| **Two statements answer *who is penned*** | 03 §8 publishes `penBoard` in `queries.drift`; 07 §9.1 publishes an extended `customSelect`; the deck already reads the same rows for Quick Entry's strip. Two of them drift apart and the board is wrong — which is the single failure this product was built to fix | T02: one statement in `PenRepository.watchBoard()`, and a test that pumps the board and the strip against one database and compares the sets |
| **The elapsed value gets stored, cached or computed in SQL** | It changes with no write, so any stored copy is wrong within a minute (01 §7.2, bucket A). SQL-side time is banned outright (decision #47) | 03 §8 states it as a rule; T04 computes it at build from the tick, and no column in this epic holds an hour |
| **A `Clock.fixed` wrapper silently measures 0 h** | The obvious way to write an elapsed-time widget test freezes the clock, and every hours readout then stays at its initial value forever while the test passes (decision #113) | 12 §2.2 and §2.4; T04 offsets the seed data instead and carries the comment above the one legitimate `atFixed` call |
| **The board is built as a grid** | 06 §11 and 10 §3.5 both describe a reflowing grid with a `_penColumns` helper; Indelible §8 screen 7 refuses tiles outright — *"a grid forces the eye to zig-zag… a ruled column does not"* — and the design system outranks the engineering docs on what the screen looks like | T05 §5.3 and T07 §5.3: one ruled column at every text scale, which also deletes the hardest half of WCAG 1.4.10 and makes the semantics tree trivially linear |
| **The status is carried by colour** | Five statuses is exactly where a status palette gets invented, and a red head torch has already destroyed the hue channel before the shepherd looks at it | T05's anchor asserts a word **and** a non-colour mark per status; the grayscale-filter read is 06 §11's ship gate and is in the DoD |
| **`DEAD` ships at 14 px** | It is a stamp, and stamps are the one thing Indelible permits below the 18 px floor — but only where the stamp is not the sole carrier of its meaning. `DEAD` is (build-manifest §4.4 defect 2) | T05 §5.3 names the corrected rule: `DEAD` is not an exempt stamp. `OVER` keeps the exemption because it sits beside a dagger and a doubled rule |
| **Turn out becomes one tap from the board** | It reads like a kindness. A brushed row would turn out a ewe with a chilled lamb still under the lamp | 07 §9.5 rejects it explicitly; T06 asserts two taps from the board, one from the open sheet, and no confirmation step |
| **`exitPen`'s undo re-opens a pen that is now occupied** | Clearing `exited_at` re-creates an open occupancy, and the partial unique index refuses it if anything else has been penned there since | 07 §15.1 states the precondition; T06 tests the refusal path as well as the happy one |
| **A second write path to `pen_occupancies` appears** | `RestoreService` writes every table once (04 §7) and is the only other writer. Anything else — a "quick tidy-up", a sweep, a fix-up on launch — is a second writer of the board's truth | 03 §5.14 closes the writer list at twelve; `layer.single_writer` proves no mutating drift API escaped `lib/data/` |
| **The `:today` bind goes stale at midnight** | 07 §9.1 projects `under_withdrawal` against a bound `:today`. A bound parameter does not change at 00:00 and drift re-runs a statement only when a tracked table is **written**, so a cleared withdrawal keeps its badge until the next write | T02 §5.3: project `clear_date` and compare it in Dart against the instant the ticker just yielded — the same bucket-A rule that governs the hours |
| **The fixtures do not exist yet** | 12 §6.2's matrix body calls `restoreFixture(db, 'flock_400_3seasons.json')`; the fixtures arrive in N23 (critique S3). Copying the snippet verbatim gives a red test that looks like a product bug | T07 seeds through `test/support/seeds.dart`; N23-T06 is the one task that switches the matrix to the fixture |
| **P9 fires on the ruled rows** | 06 §6.1 asks for `gapMin` 16 between any two targets; Indelible stacks 88 px rows separated by a 2 px rule and nothing else. That is open conflict **P9**, and it is not this epic's to settle | T05 §5.3: build the rows as Indelible draws them, name P9 in the PR body, and route the ruling to the owner rather than inventing a gap |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] the diff contains no file under `drift_schemas/`, `lib/core/db/tables/`, `android/`, `ios/`, `tool/policy_allowlist.txt` or `test/features/goldens/`
- [ ] `grep -rn "Timer.periodic\|Duration(seconds: 60)" lib/features/pens/` returns nothing — there is one ticker and it is N12's
- [ ] `grep -rn "sincePenned" lib/ test/` returns only `timeSincePenned` (R24)
- [ ] `minuteTickProvider` is watched by a widget and never by `penBoardProvider`, and the board's last pop leaves it with no listeners
- [ ] every new widget key and every new ARB message is recorded in `07-screens.md` §9 in the commit that creates it
- [ ] the board renders identically under the OS grayscale filter, checked by hand once and stated in the PR body

## Demoable on merge

The whiteboard, live, every row ticking in the same frame on the minute boundary — and the
database itself refusing two ewes in pen 3.

## Notes

**What this epic deliberately does not build.** The `pen_board_12_pens` golden is N33-T09's; renaming
and deactivating a pen from Settings ▸ Pens is N29's; the pen rows on the Ewe Card timeline are N27's;
the `pen_occupancies` arm of the CSV and the JSON backup is N21's and N22's; the semantics and
tap-target sweeps over `kPumpableVariants` are N33's; the fixture switch is N23-T06's. This epic ends
at six files under `lib/` and seven under `test/`.

**There is no edit verb for a pen entry time in v1.** The quad is on `pen_occupancies` precisely so
one *could* exist (R37), and T06 renders the edited marker so a row that carries `time_source =
'edited'` — from a restore, or from a later epic — can never be laundered as auto-captured. What the
corollary forbids is the reverse: a table without the quad has no edit verb. Adding
`correctEnteredAt` later is a repository verb plus a sheet row, and it must write `original_effective`
and flip `time_source` in the same transaction or not at all.

# N28 — Season Summary

| | |
|---|---|
| **`00-README` §9 step** | 10 (3 of 4) |
| **Depends on** | N27 |
| **Size** | L |
| **Was** | E24, closer task deleted |
| **Branch** | `epic/n28-season-summary` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

Statistics that carry their own definitions, and one hand-rolled chart.

Season Summary is the screen where the app is most likely to lie without anyone noticing. The same
toy season — 5 ewes to the ram, 3 lambed, 6 lambs of which 1 stillborn and 1 died at 2 days, 1 ewe
recorded barren, 1 with no recorded outcome — reads **120% / 100% / 80% / 200%** under four
legitimate published definitions (`05-domain-correctness.md` §6). A bare number leaving this screen
is a number a shepherd quotes over a gate. So every figure here ships welded to the sentence that
defines it, and every figure that cannot be computed says so in words.

## Why the epic sits here

`00-README` §9 step 10 is *"the calm screens: Flock, Ewe Card, Season Summary, Note Search,
Settings"*, and its reason is the one to cite rather than re-derive: these are **off the 3am path, so
they may be daylight work** — the machinery they read was built in steps 3–8 and the arithmetic they
render was finished in step 2. §9 attaches a warning to this step that binds N28 as much as it binds
N27: *"the Ewe Card summary line is the retention feature… Do not treat it as filler."* Season
Summary is the flock-level half of the same promise.

Three preconditions are already met when this branch is cut, and none of them is negotiable:

- **Step 2** shipped `lib/domain/stats/**` in N06 — `StatResult`, `LambingPercentageChoice`,
  `lambingPercentage`, `averageLitterSize`, `barrenRate`, `assistedRate`, `lossesBreakdown`,
  `lambingSpread`. **N28 writes no new statistic arithmetic.** It reads, wires and renders.
- **Step 3** froze the schema in N07. Every column this epic reads — `seasons.ewes_to_ram`,
  `ewe_seasons.status`, `lambings.local_date`, `lambings.ease`, `lambs.status`, `lambs.death_date`,
  `lambs.death_cause`, `app_settings.percentage_definition`, `app_settings.cycle_days` — already
  exists. **N28 adds no table and no column.**
- **Step 8** shipped `tool/seed.dart` and `test/fixtures/flock_400_3seasons.json` in N23, which is
  the only way a three-season comparison and a 60-day straggle chart can be pumped at all.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/07-screens.md` | §12 | Season Summary and the spread chart |
| `docs/engineering/05-domain-correctness.md` | §5–§6 | the statistics, their definitions and their caveats |
| `shed-book-spec.md` | §7.8 | lambing percentage, litter size, barren and assisted rates, losses, spread |
| `docs/design/indelible.md` | §7.11, §8 screen 10 | the totals footer, and the chart as fourteen ruled rows |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.4, §3.7 | the heading hierarchy and the chart's three accessibility layers |
| `docs/engineering/CONVENTIONS.md` | §2.6, §3.2, R18, R61 | `SeasonCounts`, `seasonFactsProvider`, no `SeasonStatsRepository`, definitions verbatim |
| `docs/engineering/12-testing.md` | §6, §7.4, §8.2 | the matrix variant, the 84-run gates, the three chart goldens |

## Tasks

| Task | One line |
|---|---|
| [N28-T01](N28-T01-seasonrepositorywatchseasoncounts-customselect-with-explicit.md) | `SeasonRepository.watchSeasonCounts` — `customSelect` with explicit `readsFrom:` |
| [N28-T02](N28-T02-the-statistics-as-rendered-definition-numerator-denominator.md) | The statistics as rendered — definition, numerator, denominator, caveats |
| [N28-T03](N28-T03-watchspread-dense-zero-filled-grouped-by-the-denormalised-ci.md) | `watchSpread` — dense, zero-filled, grouped by the denormalised civil date |
| [N28-T04](N28-T04-the-hand-rolled-spread-chart.md) | The hand-rolled spread chart |
| [N28-T05](N28-T05-comparison-against-previous-seasons-once-they-exist.md) | Comparison against previous seasons, once they exist |
| [N28-T06](N28-T06-the-three-data-shapes-as-states-the-matrix-variant-and-the-e.md) | The three data shapes as states, the matrix variant and the empty season |

## Dependencies

The chain is **strictly linear**, and each task file's header carries its own `Depends on` row.
The first task depends on the last task of the previous epic; every other task depends on the one
above it in the table.

| Task | Depends on | Why it cannot start earlier |
|---|---|---|
| T01 | the last task of N27 | the branch is cut from a merged, green `main` |
| T02 | T01 | there is nothing to render until the counts have a reader |
| T03 | T02 | the spread hangs under the stat cards and shares their controller and state class |
| T04 | T03 | the painter takes a `List<DayBirths>` and nothing produces one until T03 lands |
| T05 | T04 | the comparison is a second set of the rows T04 draws |
| T06 | T05 | the matrix cell pumps the finished screen, comparison state included |

Counts → rendering → spread query → chart → comparison → states.

## Observably true when this epic merges

Run `dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42`, open the app, reach Season Summary,
and:

1. **Every figure carries its definition, its numerator and its denominator.** `187%` prints with
   `lambs born alive per ewe put to the ram` under it and `6 / 5` beside it. Change the definition in
   Settings ▸ Season and the sentence changes with the number, verbatim from
   `LambingPercentageChoice.definition` — never paraphrased.
2. **A statistic that cannot be computed says so in words.** Clear `seasons.ewes_to_ram` and the
   lambing-percentage card reads *"The number of ewes put to the ram has not been entered for this
   season."* — not `0`, not an em dash, not `NaN`. `grep -rn '?? 0' lib/features/season/` returns
   nothing and the gate proves it.
3. **The spread chart draws with no chart package in the graph.** `grep -c fl_chart pubspec.lock`
   is `0`; the chart is a `CustomPainter`, and it renders one node per day including the days with
   no lambs.
4. **VoiceOver reads the chart without seeing it.** Every day is a labelled node — *"21 Mar, 19
   lambs"*, *"18 Mar, no lambs"* — plus two always-visible lines of real text under the chart, plus
   a working "View as table".
5. **Season one is honest.** A one-season database renders the named no-comparison state, not a
   flat zero baseline that reads like a collapse.
6. **The screen holds at 200%.** `season_summary` is a row in `kPumpableVariants`, so it is pumped
   at 3 devices × 3 text scales × 2 bold states with no `RenderFlex` overflow, and it carries one
   `headingLevel: 1` and six `headingLevel: 2` nodes.

## The PR workflow, concretely

```bash
git switch main && git pull                     # the merged main, not a stale local one
git switch -c epic/n28-season-summary
```

**One commit per task, six commits, in task order.** Each commit is the whole of its task — screen,
ARB, semantics, widget keys and tests together — because the accessibility and ARB track is an
authoring rule inside every UI task, not a trailing sweep (`00-PLAN-CRITIQUE.md` §4). Before each
commit, in this order: **`/simplify`**, then **`/code-review`**, then **`/shed-code-review`**.

Before opening the pull request, run the gates locally — they are far cheaper than a CI round trip:

```bash
make gen                          # expect NO diff: this epic generates nothing
make check                        # check_policy.dart -> dart format -> analyze --fatal-infos
make test                         # -P ci-fast randomised, then TZ=Europe/London --tags uk-zone
python3 tool/validate_epics.py
```

Then open the pull request and **wait for the pipelines**. Four jobs are blocking on every pull
request (`13-build-ci-release.md` §4.2). What each one proves for *this* epic:

| Job | Runner | What it proves here |
|---|---|---|
| `gate` | ubuntu | The toolchain pin still agrees with `.fvmrc`; `check_policy` passes **G2 + G3** and the rows this epic can break — `stat.zero_default` (`?? 0` under `lib/features/season/`), `stream.combine` (`combineLatest` anywhere in `lib/`), `layer.core_ui` (the chart component reaching into a feature), `token.raw_color`, `ui.spinner`, `time.sql_now_1` and `time.sql_now_2`; then `dart format`; then `analyze --fatal-infos --fatal-warnings`, which is where every banned Riverpod-3 spelling fails |
| `codegen` | ubuntu | `build_runner build` + `drift_dev make-migrations` + `git diff --exit-code` over `lib/`, `drift_schemas/`, `test/drift/generated/`. **For this epic the proof is a negative:** nothing moved, because N28 touches no table. A diff here means someone added a column and did not say so |
| `test` | ubuntu + `libsqlite3-dev` | `-P ci-fast` randomised; then `TZ=Europe/London --tags uk-zone` over the whole suite, which is where the 25 October 2026 repeated-hour cases run; then `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone`; coverage archived, never gated |
| `android` | ubuntu | The release AAB builds, **G1** asserts the permission set on the shipped bundle, **G4** archives the merger report. It runs on every pull request and proves nothing new about this epic beyond that no dependency crept in — which is exactly what a chart package would have done |

**Goldens do not run on this pull request.** The macOS runner bills at a 10× multiplier and
`goldens.yml` fires only on a `v*` tag or manual dispatch (`13-build-ci-release.md` §4.2, decision
#116). The three chart images — `lambing_spread_one_day`, `lambing_spread_tight_18_days`,
`lambing_spread_60_day_straggle` — are **N33's** to take. N28's obligation is to leave the chart
*golden-able*: deterministic, driven by a committed fixture and `atFixed()`, with no animation and
no wall-clock read.

Answer the five §12 questions in `.github/pull_request_template.md` in the pull request body. On
this screen §12.2 and §12.4 carry the whole weight (`07-screens.md` §12.6), and the honest answer to
§12.4 names the caveats.

When every job is green: **merge, delete the branch**, confirm `main` is green after the merge, and
only then cut `epic/n29-settings` from the merged `main`.

## Risks specific to this epic

| Risk | Why it bites here | The guard |
|---|---|---|
| **A stored `lambing_percentage`** | The epic reads like a schema epic. It is not. A cached percentage freezes a definition the user can still change, and `01-architecture.md` names it as an anti-pattern beside a `warnings` column | `codegen` must show no diff. If you bumped `kSchemaVersion`, stop |
| **`?? 0` on a nullable aggregate** | Every aggregate column arrives nullable; `?? 0` reads as tidy null-safety and turns *"we have not recorded that"* into *"you scored zero"* | Gate rows `stat.zero_default` and `stat.zero_default2`, plus `CODE-REVIEW-CHECKLIST.md` §1.9 |
| **`combineLatest` over two drift streams** | This screen genuinely has two statements — counts and spread. The obvious move is to combine them, and two streams updated inside one transaction emit at different times, so the summary tears | Gate row `stream.combine` over all of `lib/`. Fan in inside one `map`, or watch two families independently |
| **A missing table in `readsFrom:`** | The stream compiles, the screen renders, and the summary silently stops updating in the middle of lambing. Nothing fails | The T01 test that writes to each named table and expects a re-emit |
| **A chart package** | One static chart, and every tutorial reaches for `fl_chart` | G2's dependency allowlist. **Do not add a line to `tool/policy_allowlist.txt`** |
| **The 44 px chart row versus the 60 pt floor** | Indelible's day row is the only sub-64 px row in the system, and the instinct is to make each bar tappable to "fix" its accessibility | Bars carry **no** tap action, so `MinimumTapTargetGuideline` skips them (`12-testing.md` §7.3 rule 2). The tappable affordance is the 64 × 64 "View as table" button |
| **Three spellings that do not rhyme** | `SeasonSummaryScreen` in `season_summary_screen.dart`, the controller file `season_controller.dart`, the provider `seasonControllerProvider` | All three are CONVENTIONS' (§4.1, §3.2, §3.4). None is a typo to tidy |

**Nothing in this epic is irreversible in the schema sense** — no table, no column, no
`kSchemaVersion` bump, no new `drift_schemas/drift_schema_v<N>.json`, no native file, no published
artefact. Say it out loud in the commit messages, because `00-README` §8 asks you to.

**Three things here are irreversible in every other sense, and they are loud:**

1. **The four `definition` strings are printed into CSVs and PDFs that outlive the app** (R61,
   `05-domain-correctness.md` §6.2). Once a shepherd has emailed last season's flock book, the
   wording is fixed forever. They are pinned literally by a test; a "tidier" rewording is a defect,
   not an improvement.
2. **Widget keys are test contracts** (R59). The `season_summary.*` keys land in this epic and every
   later test finds by them; renaming one is a breaking change to `test/features/`.
3. **A `[exempt]` line in `tool/policy_allowlist.txt` deletes a rule for one file, forever,
   silently.** This epic must add none. If a gate is genuinely wrong, say so and stop.

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `android` is green too — it is blocking on every pull request, and a chart package would fail it
- [ ] `codegen` shows **no diff**: this epic adds no table, no column and no schema snapshot
- [ ] `tool/policy_allowlist.txt` and `android/expected_permissions.txt` are unchanged
- [ ] `season_summary` is a row in `kPumpableVariants`, and the matrix, the 84-run semantics gate and the 84-run geometric gate are all green on it
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`

## Demoable on merge

Every number carries its definition and its caveats, and the spread chart uses no chart
library and reads at 200% text scale.

Concretely, on the seeded three-season database: six figures each with its definition sentence and
its `numerator / denominator`, a fourteen-row spread with dotted zero days, the fact line *"32 of 48
ewes lambed in the first 17 days"*, the eight-placeholder summary sentence, a working "View as
table", and — switching to season one — the named no-comparison state instead of a zero baseline.

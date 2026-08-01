# N34-T04 — The seasonal freeze and the manual pre-release checklist

| | |
|---|---|
| **Epic** | [N34 — Release engineering](epic.md) · `00-README` §9 step 12 (3 of 3) |
| **Task** | 4 of 4 |
| **Depends on** | N34-T03 |
| **Commit** | one commit · `ci: the seasonal release freeze and the pre-release checklist` |

## 1. Why this task exists

**Never tag between 1 February and 30 April** except for a data-loss-class hotfix — the
calendar rule that outranks everything else in this epic, because that window is lambing and a bad
release then costs a shepherd their season. Plus the manual checklist for everything no gate can
hold.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §11, §11.1, §11.2 | the window, the three-row calendar table, what clears the freeze, and the release-checklist items the calendar owns |
| `docs/engineering/13-build-ci-release.md` | §12 | the eleven manual items, verbatim — the ones a pipeline structurally cannot see |
| `docs/engineering/13-build-ci-release.md` | §4.4 | where the freeze step sits in the job, and its published warn-only form — see §5.3, which deviates from it |
| `docs/engineering/13-build-ci-release.md` | §2.3, §10.2, §10.3 | G1's read-it-yourself rule; the 12-tester clock that must not land inside the freeze; the four offline purchase paths that are checklist items and not CI |
| `docs/engineering/00-README.md` | §7.4 | *"Never tag between 1 February and 30 April except for a data-loss-class hotfix"* |
| `docs/engineering/CODE-REVIEW-CHECKLIST.md` | §2 | the five §12 questions the checklist carries, in their diff-shaped form |
| `docs/engineering/08-platform-integration.md` | §2.7 | the eight notification channel ids, frozen at the first release (R49) |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-release` | runbook, invoked by name — the freeze and the checklist are its last chapter |
| `shed-safety-rules` | the checklist's five §12 questions are its subject |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/release_freeze_test.dart`
- **Test** — `'tagging between 1 February and 30 April fails unless the commit is marked a data-loss hotfix'`
- **Why it is red today** — nothing prevents a February release, and the rule exists only as prose in `13 §11`.

```bash
fvm flutter test test/policy/release_freeze_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the freeze check in the release workflow, the checklist, and the assertion. The assertion
runs `tool/freeze_check.sh` as a subprocess with a stubbed month and a stubbed commit message and
holds both arms: month `02`, `03` or `04` with no marker exits **1** and prints an `::error::` naming
§11.1; the same month with the marker exits **0** and prints a `::warning::` that survives on the run's
summary page.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No `lib/` layer is reached. Say so in the commit body. Six files, two of them new.

| # | Path | What changes, and why |
|---|---|---|
| 1 | `tool/freeze_check.sh` | **new.** The freeze, extracted from the workflow so it can be executed by a test. `tool/assert_permissions.sh` (G1) is the precedent — 13 §2.3 puts a shell check in `tool/` when it cannot live in `check_policy.dart`. This is **not** a second source-scanning gate and does not touch decision #10: it scans no source |
| 2 | `.github/workflows/release.yml` | edit. `- name: Seasonal freeze check` becomes the **first** step of the `aab` job, before `actions/checkout@v7`, calling the script. This is the hole N34-T01 left with a named comment |
| 3 | `docs/release-checklist.md` | **new.** 13 §12's eleven items, §11's window table, §11.1's bar and §11.2's calendar items. See §5.4 on why this path and not another |
| 4 | `docs/calendar.md` | edit. Freeze rows added to N00-T05's ledger — the window's start and end for the coming year, each with an owner, a date and an outcome |
| 5 | `RELEASES.md` | edit. One line linking `docs/release-checklist.md`, above the table, so the checklist is found by somebody who opened the release file |
| 6 | `test/policy/release_freeze_test.dart` | the anchor, written first, carrying `@Tags(['policy'])`. Two of its cases carry `tags: ['uk-zone']` |

### 5.2 The freeze check

```bash
#!/usr/bin/env bash
# tool/freeze_check.sh — the seasonal lambing freeze, 13 §11.
#
# Blocks a release build between 1 February and 30 April unless the head commit
# carries the literal marker. Not advisory: a warning nobody blocks on is the
# same artefact as no freeze at all.
#
# MONTH and HEAD_COMMIT_MESSAGE are injected so a test can drive both arms.
# In the workflow they come from `date -u +%m` and the event payload, and the
# message arrives through env:, NEVER through ${{ }} inside the script body.
set -euo pipefail

MARKER='[data-loss-hotfix]'
M="${MONTH:-$(date -u +%m)}"
MSG="${HEAD_COMMIT_MESSAGE:-}"

case "$M" in
  02|03|04) ;;
  *) exit 0 ;;
esac

case "$MSG" in
  *"$MARKER"*)
    echo "::warning::LAMBING FREEZE (1 Feb – 30 Apr) cleared by $MARKER. This must be a defect that destroys or corrupts records, or prevents the app opening at all — 13 §11.1. Staged rollout 10% for 24 h on Play, phased release on iOS."
    exit 0 ;;
  *)
    echo "::error::LAMBING FREEZE (1 Feb – 30 Apr). Only a data-loss-class hotfix ships now — 13 §11.1. If it qualifies, put $MARKER in the commit message you tag and say why in RELEASES.md. If you have to argue for it, the answer is no."
    exit 1 ;;
esac
```

The workflow step, first in the job:

```yaml
      # 13 §11. First step, before the checkout, so a frozen release costs
      # fifteen seconds and not a whole build. The commit message arrives
      # through env: — never interpolated into the shell. See §5.3.
      - name: Seasonal freeze check
        env:
          HEAD_COMMIT_MESSAGE: ${{ github.event.head_commit.message }}
        run: bash tool/freeze_check.sh
```

The window, from 13 §11 — three rows, and the middle one is the one people forget:

| Dates | Status | What may ship |
|---|---|---|
| 1 Feb – 30 Apr | **FROZEN** | Only a data-loss-class hotfix (§11.1) |
| 1 – 31 May | Elevated scrutiny | Hill flocks are still lambing. Staged rollout only, 10% for 72 h |
| 1 Jun – 31 Jan | Open | Normal releases; this is where feature work lands |

### 5.3 The deviation from 13 §4.4 as published — read this before you write the step

**13 §4.4's freeze step warns and never blocks, and §11 argues for that in writing:** *"the one
release that must be able to run during the freeze is the hotfix the freeze exists to make rare."*
This task's anchor test and its Definition of Done say the opposite — *"tagging … **fails** unless the
commit is marked a data-loss hotfix"*, *"the freeze is executable, not advisory"*, *"the hotfix escape
hatch requires an explicit marker and leaves a record."*

**Both are satisfied by one design, and it is the one above.** The escape hatch is what reconciles
them: the hotfix can still ship, in fifteen seconds, at the cost of one deliberate string in a commit
message — which is exactly the *"leaves a record"* half that a bare warning does not give you. 13
§11's own reason for the warning is preserved verbatim in the cleared arm, because it is right and
orthogonal: *"a warning annotation stays on the run's summary page for the rest of the release's life,
which is the point: the person who cannot remember why they shipped on 3 March can go and read it."*

Record the deviation in **exactly one place** — a comment at the top of `tool/freeze_check.sh`,
reproduced above — and nowhere else. Reversing it means deleting one `exit 1` and one test case.
Do not restate the argument in `docs/release-checklist.md`; a rule stated twice is a rule that drifts.

### 5.4 The checklist, and why it is a file

13's Definition of done requires that *"the §12 manual checklist is in the repository, not in this
document only"* — and **no document in the set names a path for it.** This task fixes it at
`docs/release-checklist.md`, hyphenated to sit beside `docs/calendar.md` and
`docs/engineering/13-build-ci-release.md` rather than inventing a third naming style. The anchor test
pins the path, so a second copy cannot appear and quietly disagree.

The eleven items, from 13 §12, each with the reason it is manual:

| # | Item | Why no pipeline can hold it |
|---|---|---|
| 1 | **Read the permission list yourself.** `bundletool dump manifest` on the artefact you are about to upload. Seven `uses-permission` lines; confirm `INTERNET` is not the eighth | G1 being green is a fact about a script, not about your eyes. Split on `<` first — grepping the substring `permission` **misses `com.android.vending.BILLING`**, which is the one this project cares most about (13 §2.3) |
| 2 | **Xcode → Archive → Generate Privacy Report.** Read the aggregate, not just your own manifest. Re-do after any plugin bump and after the SwiftPM migration | The aggregate exists only inside an Xcode archive |
| 3 | **Airplane-mode pass on a real device.** Cold launch → record a lambing event → export a CSV → open Unlock → tap Restore. Plus 11 §11's four offline purchase paths | Nothing in the pipeline can test a purchase (13 §10.3) |
| 4 | **Dark-launch check.** No white flash: the iOS `LaunchScreen` background and the Android `windowBackground` are the base surface `#0B0D0E`, and the Android 12+ splash exit fade is disabled | It is a *release configuration* bug, not a Dart bug, so **no test in the suite will ever catch it** |
| 5 | **The four integration journeys**, on a plugged-in phone (`make integration DEVICE=…`). Reported, not blocking — but read the report | #117: an integration suite in the blocking set is a suite that gets deleted the first week it is flaky |
| 6 | **Goldens re-baselined (`make goldens-update`) and every changed pixel looked at**, if any changed | A golden that changed and nobody can say why is a red build, not a re-baseline |
| 7 | **`docs/perf/measurements.md` has a row for this release** — startup on two devices, DB open, PDF duration. Fill the AAB download column in *after* upload | N34-T03. #126 forbids a CI perf assertion, so this is where "a regression is a release blocker" actually lives |
| 8 | **Season freeze:** is it between 1 February and 30 April? Does this release clear §11.1's bar? | The pipeline holds the date; only a human holds the judgement |
| 9 | **Release notes and store listing read for §12.2 compliance.** No dose, no diagnosis, no "you should". **No "your data never leaves your phone"** | `tool/check_policy.dart` cannot see store metadata — **you are the gate** |
| 10 | **"Did anything gain a network path this release?"** If a dependency was added or bumped, re-read its transitive graph and its merged manifest | If yes, the Apple privacy label and the Play Data safety form are versioned artefacts that must be updated **before** this build ships |
| 11 | **`RELEASES.md` updated** with tag, build number and upload dates; **symbols archived** under that build number | N34-T02: `symbols-archive/` is git-ignored, so nothing in CI can file them for you |

The checklist also carries the five §12 questions in their diff-shaped form
(`CODE-REVIEW-CHECKLIST` §2) — §12.1 never default a withdrawal period, §12.2 never give veterinary
advice, §12.3 never present as a regulatory record, §12.4 never silently correct an entry, §12.5
timestamps carry provenance — and §11.2's four calendar items.

### 5.5 What is easy to get wrong here

- **Never interpolate `${{ github.event.head_commit.message }}` into a `run:` block.** A commit message
  is attacker-controlled text; `${{ }}` substitutes it into the shell *before* the shell parses it, and
  a message containing a backtick or `$(…)` executes on a runner that holds the four signing secrets.
  Pass it through `env:` and read `"$HEAD_COMMIT_MESSAGE"` inside quotes. This is the single most
  dangerous line in the epic and it looks like nothing.
- **`date -u +%m` is UTC, deliberately, and it over-freezes by an hour.** At 00:30 BST on 1 May, UTC is
  still 30 April 23:30, so the check reads month `04` and blocks for thirty more minutes. That is the
  safe side of the boundary and it is the right trade. The alternative — `TZ=Europe/London date +%m` —
  makes the freeze depend on the runner's configured zone, and a freeze that a runner image can change
  is not a freeze. Leave it UTC and say so in the script.
- **The marker goes on the head commit of the tag, not on the tag and not on some commit in the
  branch.** `github.event.head_commit.message` is the tag push's head commit. An annotated tag message
  is not in that payload at all, so a marker in `git tag -m` is invisible to the check — and the
  developer who put it there will believe the freeze is broken.
- **The step runs before `actions/checkout@v7`, and that constrains what it can read.** It cannot
  `git log`, cannot read a file from the repository, and cannot use `git tag -l --format`. Everything
  it needs comes from the event payload and the environment. Moving it after the checkout to "make it
  easier" costs the whole point of the position: a frozen release should fail in fifteen seconds, not
  after a keystore is written and a Gradle build starts.
- **§11.1's bar is narrow, and it is written down before anyone is tempted to argue with it.** Exactly
  one class of change clears it: **a defect that destroys or corrupts records, or prevents the app
  opening at all.** Not a crash on a secondary screen, not a wrong statistic, not a layout bug, not a
  missing translation. *"If you have to argue for it, the answer is no."*
- **1 May is not the season ending.** Hill flocks are still lambing in May: staged rollout only, 10%
  for 72 hours. A freeze-*clearing* hotfix gets a tighter rule again — 10% for 24 hours before going
  wider on Play, plus phased release on iOS. Neither is a CI step; both are checklist lines.
- **The eight notification channel ids freeze at the *first release*, not at the first snapshot**
  (R49, 13 §11.2, 08 §2.7). They are `colostrum`, `navel`, `turn_out`, `tag_by`,
  `ring_dock_castrate`, `second_dose`, `withdrawal_end`, `custom` — byte-identical to `reminders.kind`'s
  CHECK. **Decision #65's `turnout`, `dose` and `withdrawal` are superseded and are banned channel
  ids**; they match no kind. Changing one after release silently orphans every scheduled reminder on
  every installed device, on phones you will never see.
- **`docs/calendar.md` is held by a test that blocks by the time you get here.**
  `test/policy/calendar_commitments_test.dart` (N00-T05) *stays red until every row is filled*, and it
  is excluded from the blocking set only **until N32**. At N34 it is in. An empty freeze row is a red
  build, which is the intended behaviour of a ledger nobody can quietly ignore.
- **Add the freeze to a real calendar in September, when it is easy** (13 §11). The repository row is
  the record; the September reminder is what makes somebody read it.
- **The 12-tester / 14-day clock must not land inside the freeze** if the plan is to ship straight
  after it (13 §10.2). That clock started at N32. This is where the two calendars collide, and the
  collision is resolved on paper, in `docs/calendar.md`, not in February.
- **Three dated obligations belong in the calendar rows, not in code**: Play Billing 9 mandatory
  **31 August 2027** (put a reminder in Q1 2027; `in_app_purchase_android` ships Billing 8.0.0 today,
  which satisfies the 31 August 2026 deadline), target API 36 by **31 August 2026** (extensions to
  1 November 2026), and Xcode 26+ / iOS 26 SDK required for uploads since **28 April 2026**. Also
  yearly: refresh the bundled IANA timezone data by bumping `timezone` and re-running the DST suites —
  **outside the freeze**.
- **The checklist is prose and prose rots.** That is why the anchor test reads it: eleven items, the
  five questions, one file. A checklist nothing asserts against is a checklist that loses an item the
  first time somebody tidies it.

### 5.6 The test set

`test/policy/release_freeze_test.dart` — one file, `@Tags(['policy'])`, running `tool/freeze_check.sh`
as a subprocess with `MONTH` and `HEAD_COMMIT_MESSAGE` stubbed, and reading
`.github/workflows/release.yml`, `docs/release-checklist.md`, `docs/calendar.md` and `RELEASES.md`
as text.

| Test | What it holds |
|---|---|
| `'tagging between 1 February and 30 April fails unless the commit is marked a data-loss hotfix'` | the anchor, both arms. `MONTH=03` with an ordinary message exits 1 and the output names §11.1; `MONTH=03` with `[data-loss-hotfix]` exits 0 and the output is a `::warning::` |
| `'31 January and 1 May are open, 1 February and 30 April are frozen'` | the four boundary months — `01`, `02`, `04`, `05` — as a table. The off-by-one at either edge is the whole rule |
| `'01:30 on the spring-forward Sunday is inside the freeze and the check builds no local wall time'` | `tags: ['uk-zone']`. 29 March 2026, when local **01:00–01:59 does not exist**. The freeze answer is FROZEN whichever instant in that hour is used, and the check reads UTC — a local wall time here either throws or silently shifts, and both are wrong |
| `'01:30 on the clocks-back Sunday is open, both times it occurs'` | `tags: ['uk-zone']`. 25 October 2026, the ambiguous hour **01:00–01:59**, which happens twice — 00:30 UTC and 01:30 UTC both read as local 01:30. The answer is *open* twice and never *frozen once*. Together with the case above this proves the freeze reads UTC and never a wall clock, which is the entire reason `date -u` is correct |
| `'the freeze check is the first step of the aab job, before the checkout'` | its position, which is what makes a frozen release cost fifteen seconds |
| `'the commit message reaches the script through env and is never interpolated into the shell'` | no `${{ github.event` appears inside any `run:` body in any workflow. The injection case, held in the negative across all three files |
| `'no workflow makes the freeze step continue-on-error'` | 13 §4.6: *"if it is not worth failing on, delete it."* The one line that would turn this back into a warning |
| `'docs/release-checklist.md carries all eleven items and the five §12 questions'` | counted, not eyeballed. The §12 questions are matched against `shed-book-spec.md` at run time, the way N01-T07's template test does it, so a spec edit turns this red rather than letting the two copies drift |
| `'the checklist is the only release checklist in the repository and RELEASES.md links it'` | one file, one path, and it is reachable from the file somebody actually opens |
| `'the eight notification channel ids in the checklist equal reminders.kind byte for byte'` | read from the committed `drift_schemas/drift_schema_v1.json` CHECK, never from a list typed here. `turnout`, `dose` and `withdrawal` appear nowhere |
| `'docs/calendar.md carries the freeze window with an owner, a date and an outcome'` | the ledger row, in N00-T05's shape, so `calendar_commitments_test.dart` covers it too |

## 6. Constraints that bind this task

- **The five safety rules** — this task's subject is the whole set, because the checklist is the last place all five are asked before an artefact reaches a shepherd. The rule the *freeze* holds is the one behind them all: an update is irreversible on someone else's phone the moment they take it. A rule that drops to merely *documented* has been deleted, whatever the prose says — which is why the freeze is a script with an `exit 1` and not a paragraph.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. Checklist items 1, 9 and 10 are the human half of that same claim, and item 9 is the only place the store listing is ever checked at all.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'tagging between 1 February and 30 April fails unless the commit is marked a data-loss hotfix'` passes, and was seen to fail first for the stated reason
- [ ] the freeze is executable, not advisory
- [ ] the hotfix escape hatch requires an explicit marker and leaves a record
- [ ] the checklist carries the five §12 questions and the manual device checks
- [ ] the checklist is linked from `RELEASES.md`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/release_freeze_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

Drive both arms of the freeze by hand, and watch each one, because a gate nobody has seen fire is
indistinguishable from a broken gate:

```bash
# Frozen, no marker — expect exit 1 and an ::error:: naming §11.1.
MONTH=03 HEAD_COMMIT_MESSAGE='fix: a layout bug on the ewe card' bash tool/freeze_check.sh; echo "exit=$?"

# Frozen, marked — expect exit 0 and a ::warning:: that will sit on the run summary forever.
MONTH=03 HEAD_COMMIT_MESSAGE='fix: [data-loss-hotfix] restore drops media rows' bash tool/freeze_check.sh; echo "exit=$?"

# Open — expect exit 0 and silence.
MONTH=09 HEAD_COMMIT_MESSAGE='feat: season summary' bash tool/freeze_check.sh; echo "exit=$?"

# The edges.
for M in 01 02 04 05; do MONTH=$M HEAD_COMMIT_MESSAGE='x' bash tool/freeze_check.sh; echo "$M -> $?"; done
```

Then read `docs/release-checklist.md` top to bottom **against a real artefact**, not as a document
review: run item 1's `bundletool dump manifest` on the AAB from N34-T01's §8, run item 4's dark-launch
check on a phone in a dark room, and read item 9's store listing text for the banned sentence. A
checklist that has only ever been proofread is a checklist whose items you do not know how to do.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `ci: the seasonal release freeze and the pre-release checklist`

# N01-T05 — The `Makefile`, cheapest failure first

| | |
|---|---|
| **Epic** | [N01 — The tree, the configs and the CI shell](epic.md) · `00-README` §9 step 1 |
| **Task** | 5 of 7 |
| **Depends on** | N01-T02 · N01-T04 |
| **Commit** | one commit · `chore: the eight-target Makefile, cheapest failure first` |

## 1. Why this task exists

Eight targets — `gen`, `check`, `test`, `goldens`, `goldens-update`, `integration`,
`validate`, `all` — ordered so the sub-second failure happens before the thirty-second one. `check`
runs `dart run tool/check_policy.dart`, then `python3 tool/validate_skills.py`, then
`python3 tool/validate_epics.py`, then `dart format --set-exit-if-changed`, then
`flutter analyze --fatal-infos --fatal-warnings`. `goldens` **verifies**; only `goldens-update`
re-baselines, and never as a side effect.

`CLAUDE.md` names five project commands — `make gen`, `make check`, `make test`,
`dart run tool/check_policy.dart`, `python3 tool/validate_skills.py` — and until this task none of
them exists. The two Python validators are declared project commands that nothing runs, which is
critique gap G4.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §1.3 | the `Makefile` verbatim, the seven targets it ships, and the cold-cache network paragraph |
| `docs/engineering/12-testing.md` | §11.4, §11.2 | the two commands on `test`, the `goldens` split, and the filter spelling still in dispute |
| `docs/engineering/00-README.md` | §7.3, §7.4, §8 step 8 | `make gen` is the only way generated code changes; a golden re-baseline is its own commit |
| `epics/00-PLAN-CRITIQUE.md` | §11.2 N01-T05 | the `[audit]` ruling: `validate_skills.py` is a **command inside `check`**, not a target of its own |
| `CLAUDE.md` | the pinned-stack table | the five project commands this file has to make real |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-dependencies-and-toolchain` | `13 §1` owns the `Makefile` and this skill carries it |
| `shed-testing` | the target list is the local mirror of the CI job matrix |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/makefile_test.dart`
- **Test** — `'make check runs check_policy, validate_skills and validate_epics before analyze, and goldens never re-baselines'`
- **Why it is red today** — there is no `Makefile`; `CLAUDE.md` names five project commands and none of them exists. `tool/validate_skills.py` and `tool/validate_epics.py` are declared project commands that nothing runs — critique gap G4.

```bash
fvm flutter test test/policy/makefile_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — write the targets and let the test parse the recipe lines for order and for the
absence of `--update-goldens` in `goldens`. Assert the order as a **subsequence** of the canonical
list, not as equality, for the reason in §5.3.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No `lib/` layer is reached. One root file and one test.

| # | Path | What changes, and why |
|---|---|---|
| 1 | `Makefile` | new. 13 §1.3's recipes verbatim, plus `validate` and `all`, plus the two Python validators inside `check` |
| 2 | `README.md` | one paragraph: which of `pub get`, `gen`, `test` and `build` first needs the network on a cold cache. 13 §1.3 says find this out once, in plane mode, and write it down — see §5.3 |
| 3 | `test/policy/makefile_test.dart` | the anchor, written first, carrying `@Tags(['policy'])` |

### 5.2 The file

13 §1.3's recipes are reproduced, not redefined. `validate` and `all` are this task's additions;
`check` gains the two validators as **steps**, which is `00-PLAN-CRITIQUE` §11.2's `[audit]` ruling
in as many words: *"a step and not a target"*.

```make
# Makefile
FLUTTER ?= fvm flutter
DART    ?= fvm dart

gen:                      ## codegen + migration artefacts. The ONLY way generated code changes
	$(DART) run build_runner build --delete-conflicting-outputs
	$(DART) run drift_dev make-migrations

check:                    ## cheapest failure first: <1s, then seconds, then tens of seconds
	$(DART) run tool/check_policy.dart
	$(MAKE) validate
	$(DART) format --output=none --set-exit-if-changed .
	$(FLUTTER) analyze --fatal-infos --fatal-warnings

validate:                 ## the two doc validators, on their own, for a docs-only change
	python3 tool/validate_skills.py
	python3 tool/validate_epics.py

test:                     ## 12-testing.md §11.4. Two commands, because TZ is per-process.
	$(FLUTTER) test -P ci-fast --test-randomize-ordering-seed random --coverage
	TZ=Europe/London $(FLUTTER) test --tags uk-zone

goldens:                  ## VERIFY against the committed PNGs. Never a per-PR gate (#116)
	$(FLUTTER) test -P ci-golden

goldens-update:           ## RE-BASELINE. A deliberate act, its own commit (12 §8.5)
	$(FLUTTER) test -P ci-golden --update-goldens

perf:                     ## decision #126 — needs a real device, profile mode
	$(FLUTTER) run --profile --trace-startup -d $(DEVICE)

integration:              ## decision #117 — four journeys, real device, reported not blocking
	$(FLUTTER) test integration_test -d $(DEVICE)

all: gen check test       ## the full local pass, in the order a developer actually wants it
```

**The count.** The Definition of Done counts the eight this task's title names: `gen`, `check`,
`test`, `goldens`, `goldens-update`, `integration`, `validate`, `all`. `perf` is 13 §1.3's seventh
and ships with them, because 13 §1.3 is verbatim-binding and a `Makefile` missing one of its targets
contradicts the document that owns the file. Nine recipes, eight counted; if that reads wrong, raise
it rather than deleting `perf`.

**The filter spelling** — `-P ci-fast` and `-P ci-golden` above — is whatever N01-T04's day-one
check decided. If it decided `flutter test` has no preset flag, these three lines read
`--exclude-tags golden` and `--tags golden` instead, and 13 §1.3 takes 12 §14 edit 1 in the same
commit. Both files say the same thing or neither is written.

### 5.3 What is easy to get wrong here

- **`tool/check_policy.dart` does not exist until N03, and `make check`'s first line calls it.**
  This is the one real sequencing collision in the epic, and it must be decided here rather than
  discovered. `00-PLAN-CRITIQUE` §10 requires a green `main` at every merge, and N03-T01's own first
  failing test is red *because* `make check` calls a script that is not there.

  | Option | What it costs |
  |---|---|
  | **C — recommended.** N01-T05 writes every line above **except** `$(DART) run tool/check_policy.dart`; **N03 adds that one line in the commit that creates the script.** N03's last task is already called *"wire the gate into CI"*, so the same commit that adds the `gate` job's policy step adds the `Makefile`'s — the two files stay in step and neither is ever red. The anchor test asserts the ordering *contract* rather than an exact list, so it passes in both states and fails the moment somebody puts `analyze` before `format`. Precedent: `00-PLAN-CRITIQUE` §9 change 6, where `routes.dart` grows one helper per screen epic. Cost: N03-T01's *"and `make check` calls a script that is not there"* clause is amended in N03's own commit |
  | **A — the alternative.** Write the line now and land a `tool/check_policy.dart` with an empty rule table beside it. Cost: a gate that exits 0 for a whole epic, which is exactly the *"rule nobody has seen fire"* `00-README` §9 warns about, plus N03-T01's *"does not exist"* clause amended |

  Whichever you take, say which in the commit message. What is not permitted is writing the line and
  merging a red `make check`.

- **Recipe lines are indented with a TAB.** A space-indented recipe fails with
  `Makefile:7: *** missing separator.  Stop.` and the message names the line, not the cause. Most
  editors convert tabs to spaces by default; set the exception for this file before you type.
- **`?=`, not `=`, on `FLUTTER` and `DART`.** The default is `fvm flutter`, which is right on the
  developer's machine and wrong on CI, where `subosito/flutter-action` installs Flutter directly and
  there is no FVM. `?=` is what lets a caller pass `FLUTTER=flutter`.
- **CI does not run `make`.** 13 §4.3's `ci.yml` spells its steps out. So this file and that file are
  two copies of one list, kept in step by hand — which is why this task's anchor asserts the recipes
  and N01-T06's asserts the workflow steps, and why a change to either is a change to both.
- **`goldens` must contain no `--update-goldens`, ever.** 13 §1.3: *"a target called `goldens` that
  silently passes `--update-goldens` is the easiest way there is to green a broken golden, because
  you type it to check and it always agrees with you."* And a re-baseline is its own commit
  (`00-README` §7.4).
- **`--delete-conflicting-outputs` on `gen` is not optional.** Without it, a renamed source leaves a
  stale generated output and `build_runner` refuses to run rather than overwriting it.
- **`test` is two commands because `TZ` is per-process.** A `--tags` filter selects files; it cannot
  change the zone the runner started in. Same reason `TZ=Europe/London` sits on the second line and
  not in an environment block.
- **`perf` and `integration` need `DEVICE=` and a plugged-in phone.** Neither belongs in CI:
  hosted emulators run debug mode only, and profile-mode numbers from a hosted runner are load noise
  (decision #126).
- **The network paragraph is owed.** `package:sqlite3`'s build hooks download a sha256-verified
  prebuilt binary from GitHub on a **cold** cache — a fresh clone, a new pub cache, or after
  `flutter clean` — and cache it afterwards, so a warm laptop builds in plane mode. **Which target
  trips the fetch first is unverified.** Find out once, in plane mode, and write the answer in
  `README.md`. Without that paragraph the first offline build failure gets mistaken for a regression
  and somebody spends an evening on it.
- **`make check` and `make test` are in every task's Definition of Done, including the four before
  this one.** For N01-T01 through N01-T04 those lines mean the equivalent commands run by hand; from
  this commit they mean the target. That is not a licence to weaken a recipe so an earlier task's
  checklist reads true retroactively.

### 5.4 The test set

`test/policy/makefile_test.dart` — one file, six cases, reading the `Makefile` as text. Nothing here
is time-shaped; the `uk-zone` selection this file *invokes* is proved by N01-T04's canary.

| Test | What it holds |
|---|---|
| `'make check runs check_policy, validate_skills and validate_epics before analyze, and goldens never re-baselines'` | the anchor. `check`'s steps are a **subsequence** of the canonical order, so it is true before and after N03 adds the gate line; and when `check_policy` is present it is first |
| `'every command CLAUDE.md names is a real target or a real script'` | closes critique gap G4 — the two Python validators had no runner |
| `'goldens carries no --update-goldens and goldens-update carries exactly one'` | the self-agreeing golden, refused |
| `'every recipe line is indented with a tab'` | the `missing separator` failure, caught by the test instead of by the developer |
| `'test runs two commands and the second sets TZ=Europe/London with no path'` | 12 §2.5 note 1 — a scoped zone step runs the wrong files in UTC |
| `'no recipe fetches anything over the network'` | no `curl`, no `wget`, no `git clone` in any recipe; the one genuine cold-cache fetch is `package:sqlite3`'s build hook and it is documented, not scripted |

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. No recipe may fetch anything; the one cold-cache fetch is `package:sqlite3`'s and it is a documented build-hook exception, not a step this file adds.
- **Never edit the gate to make a build pass.** `CLAUDE.md`: never edit `tool/check_policy.dart`, its
  rule table or its exit code, and never add a line to `tool/policy_allowlist.txt` to silence it.
  That applies to the `Makefile` too — a recipe that swallows an exit code is the same act.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'make check runs check_policy, validate_skills and validate_epics before analyze, and goldens never re-baselines'` passes, and was seen to fail first for the stated reason
- [ ] all eight targets exist and run
- [ ] `check` runs the three validators before `format` and `analyze`
- [ ] `goldens` contains no `--update-goldens`
- [ ] `make check` is green on the tree as it stands
- [ ] the §5.3 option taken for the `check_policy` line is named in the commit message
- [ ] `README.md` records which target first needs the network on a cold cache
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/makefile_test.dart
make -n all
make check
make test
```

`make -n` prints the recipe lines without running them, which is how you read the order back and
confirm `check` is cheapest-failure-first. Then run `make goldens` once and confirm it **fails**
against a tree with no committed PNGs rather than writing any — a `goldens` target that creates a
baseline on first run is the failure this split exists to prevent.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `chore: the eight-target Makefile, cheapest failure first`

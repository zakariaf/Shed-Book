# N03-T07 — Wire the gate into CI and assert the rule inventory is complete

| | |
|---|---|
| **Epic** | [N03 — The gate](epic.md) · `00-README` §9 step 1 |
| **Task** | 7 of 7 |
| **Depends on** | N03-T06 |
| **Commit** | one commit · `ci: run the gate first and assert every rule is proved` |

## 1. Why this task exists

The gate becomes the `gate` job's **first** step, before `pub get`, because it is
sub-second and everything after it is not. And one inventory assertion: every rule id in the table
appears in `gate_rules_test.dart`, so a rule added without a proving test is itself a failure. This
replaces the old plan's single thirty-cycle *"plant, watch, delete"* task, which was thirty commits
pretending to be one.

The inventory assertion is the part that outlives this epic. Six later epics add rows —
`copy.vet_advice` and `copy.disclaimer_retyped` in N06, the `db.destructive_ddl` family in N08,
`layer.in_app_purchase` and `launch.store_call` in N30 — and each of them will be written by
somebody who has forgotten this file exists. The assertion is what turns *"add a proving case"* from
a convention into a red build.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §4.2, §4.3 | the `gate` job's contents, its trigger, and the step order as `ci.yml` prints it |
| `docs/engineering/13-build-ci-release.md` | §1.1, §1.3 | the toolchain-pin assert that must run in the first job that installs Flutter; `make check`'s order |
| `docs/engineering/01-architecture.md` | §3.3 | *"It runs **after** `flutter pub get` (it reads `pubspec.lock`)"* — the sentence this task has to reconcile |
| `docs/engineering/12-testing.md` | §1.4 | what is a gate and what is a test, and why a `RegExp` inside a `test()` is a policy rule that escaped its home |
| `docs/engineering/CONVENTIONS.md` | §4.7 | the id grammar the inventory assertion validates against |
| `epics/00-PLAN-CRITIQUE.md` | §3 | why E02-T07 was re-cut into this task |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | the inventory assertion is a test about tests |
| `shed-dependencies-and-toolchain` | the `gate` job's step order is its subject |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/gate_rules_test.dart`
- **Test** — `'every rule id in the table is proved by a test in this file'`
- **Why it is red today** — a rule can be added to the table today with nothing proving it fires.

```bash
fvm flutter test test/policy/gate_rules_test.dart   # expect: failing, for the reason above
```

The assertion, spelled out, in three parts. **One**: the set difference
`policyRuleIds.toSet().difference(firesOn.keys.toSet())` is empty, and the failure message lists the
unproved ids by name. **Two**: the reverse difference is also empty — a proving case for an id that
is no longer in the table is a case that passes vacuously forever. **Three**: every id matches
`RegExp(r'^(layer|net|time|rp3|stream|db|stat|a11y|gesture|token|theme|type|ui|main|dep|launch|copy|media)\.[a-z0-9_]+$')`,
so `CONVENTIONS` §4.7's grammar is held by the same test rather than by a reader's memory. It will
fail red before green *four* ways if `firesOn` is empty, which is why it is written last.

**Green.** The minimum code that passes, and nothing beyond it — expose the rule ids from the script, iterate them in the test, and fail naming any id with
no proving case.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in the order you touch them

No schema, no domain, no data, no UI, no ARB — say so in the commit message (`00-README` §8).

| # | File | What changes, and why |
|---|---|---|
| 1 | `tool/check_policy.dart` | `policyRuleIds` stops being a stub and yields from all three tables — `_bannedText`, `_bannedPattern` and `_bannedPathPairs` — plus the layer ids `_directionRuleId` can emit and the three `dep.*` ids `_checkLockfile` can emit. **An id that a rule can emit but the getter does not yield is invisible to the assertion**, which is the one way this task can be written and still be worthless |
| 2 | `test/policy/gate_rules_test.dart` | The `firesOn` map becomes the file's spine: every case from T02–T06 is re-expressed as an entry, and the three-part inventory assertion iterates it |
| 3 | `.github/workflows/ci.yml` | The `Policy gate (G2 + G3)` step N01-T06 authored is confirmed in position, and any `continue-on-error` or placeholder it carried while the script did not exist is removed |
| 4 | `Makefile` | **No change.** N01-T05 already ordered `check` cheapest-failure-first with `check_policy` on line one |

### 5.2 The signatures

```dart
/// Every rule id this script can emit, in declaration order, from ALL of:
///   _bannedText · _bannedPattern · _bannedPathPairs · _directionRuleId's values
///   · the three dep.* ids _checkLockfile emits.
/// N03-T07's inventory assertion iterates this. A rule that can fire but is not
/// yielded here is a rule with no proving case and no way to notice.
Iterable<String> get policyRuleIds sync* { … }
```

```dart
// test/policy/gate_rules_test.dart
/// id -> the smallest source that must trip it. This map IS the proof: a row
/// with no entry fails the inventory assertion, and an entry with no row fails
/// it from the other side.
const firesOn = <String, PlantedViolation>{ … };

test('every rule id in the table is proved by a test in this file', () { … });
```

### 5.3 The details that are easy to get wrong

- **Three documents disagree about where the gate runs in the `gate` job, and this task is where
  that has to be resolved rather than inherited.** This task's own title says *"first step, before
  `pub get`"*. `01-architecture.md` §3.3 says the opposite, with a reason: *"It runs **after**
  `flutter pub get` (it reads `pubspec.lock`), and before `dart format` and `flutter analyze`, so
  the cheapest failure reports first."* `13 §4.3` prints `ci.yml` with `- run: flutter pub get`
  above the policy step. **Two documents agree and they are right**: a missing lockfile is exit 2,
  and G2 must read the lockfile CI will actually build with, not the one that was committed before
  an upstream package moved. The resolution that satisfies both the title's intent and the
  documents: the policy gate is the **first step that can fail on the contents of the diff**, and
  the two steps above it — installing the pinned Flutter and `pub get` — are preconditions, one of
  which `13 §1.1` requires to be first in the first job that installs Flutter. State the resolution
  in the commit message; do not silently pick one and leave the next reader to find the
  contradiction.
- **The step order that ships:** checkout → `flutter-action` → toolchain pin assert → `flutter pub
  get` → **`dart tool/check_policy.dart`** → `dart format --output=none --set-exit-if-changed .`
  → `flutter analyze --fatal-infos --fatal-warnings` → the `NSAppTransportSecurity` check. Sub-second
  before tens of seconds, exactly as `make check` orders it locally. Every other job in `ci.yml`
  `needs: gate`, so one toolchain assert covers the workflow.
- **A gate that cannot fail is not a gate.** If N01-T06 landed the step with `continue-on-error:
  true`, or as an `echo`, or commented out — which is the only way N01 and N02 could have shown a
  green `gate` while `tool/check_policy.dart` did not exist — removing that is the most important
  line of this diff. Check it before anything else.
- **`policyRuleIds` must include ids that no table row carries.** `layer.direction`'s replacements
  come from `_directionRuleId`'s *values*, not from a row; `dep.direct_main`, `dep.direct_dev` and
  `dep.transitive` are built by string interpolation inside `_checkLockfile` and appear in no table
  at all. Yield the ids from one place each and let the assertion see them, or the epic ships with
  thirteen ids nobody proved and a test that says everything is fine.
- **Assert in both directions.** A proving case for a deleted id passes for ever and proves nothing;
  it is how a rule gets removed in a "tidy-up" and the test suite stays green. The reverse difference
  is one extra line and it is the line that catches a deletion.
- **The id-grammar assertion is not decoration.** `CONVENTIONS` §4.7 fixes seventeen namespaces and
  a `lower_snake` tail. Three task titles in this very epic use ids that violate it (`design.raw_hex`,
  `time.wall_clock`, `db.custom_statement`). If this assertion is not written, the fourth one lands
  and the `[exempt]` key that references it never matches — silently, for ever.
- **This is a test about the gate, not a policy expressed as a test.** `12 §1.4` is emphatic that
  *"if the assertion can be made by reading source text, it belongs in `tool/check_policy.dart`, not
  in `test/policy/`"* and that a `RegExp` inside a `test()` is a policy rule that escaped its home.
  This file is the exception that proves the rule: it asserts a property of the gate's own tables,
  which no gate row can express, and it contains no `RegExp` matching product source. Say so in the
  commit message — otherwise the next reader cites §1.4 against it and deletes it.
- **The assertion runs in the `test` job, not the `gate` job.** It is a Dart test, so it needs
  `flutter test` and it lands with the rest of the suite. The `gate` job proves the rules *run*; the
  `test` job proves they are *proved*. Two jobs, two claims — do not try to fold the inventory
  assertion into the script, because a script that fails when a rule has no test is a script that
  fails on a fresh clone with no test runner.
- **The `test` job's third command runs over a directory that does not exist yet.**
  `TZ=Pacific/Chatham flutter test test/domain --exclude-tags uk-zone` is in `13 §4.2` and
  `test/domain/` arrives in N04. `flutter test` on a missing path is an error, not a no-op, so
  either N01-T06 already guarded it or this is where you find out. It is the last chance before the
  epic merges and the `test` job's green becomes load-bearing for every epic after.

### 5.4 The full test set

| Case | What it asserts |
|---|---|
| `'every rule id in the table is proved by a test in this file'` | The anchor. `policyRuleIds` minus `firesOn.keys` is empty, and the message lists the unproved ids |
| the reverse difference | `firesOn.keys` minus `policyRuleIds` is empty — no vacuous case survives a deleted row |
| the id grammar | every id matches `CONVENTIONS` §4.7's namespace-and-`lower_snake` shape |
| no duplicate ids | `policyRuleIds` has no repeats — R54: a duplicate rule is a rule that gets weakened twice |
| the `dep.*` ids are yielded | the three ids `_checkLockfile` interpolates appear in `policyRuleIds` |
| the layer ids are yielded | every value of `_directionRuleId` appears in `policyRuleIds`, and `layer.direction` / `layer.import` appear **nowhere** |
| the deliberate absences | `copy.vet_advice` and `copy.disclaimer_retyped` are absent, and the comment naming N06-T09 is present in the source |
| `'ci.yml runs the policy gate before format and analyze'` | Parse `.github/workflows/ci.yml`: the `gate` job contains the `dart tool/check_policy.dart` step; its index is above `dart format` and `flutter analyze`; the job carries no `continue-on-error` |
| `'every job in ci.yml needs gate'` | `13 §1.1`'s claim that one toolchain assert covers the workflow is only true while this holds |
| `'make check runs the gate first'` | The `Makefile` target's first line is the script — reasserted here because this is the commit that claims the ordering property |

Nothing here is time-shaped.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. Both live in the one step this task fixes in place; a `gate` job that skips it is a push with no offline proof at all.
- **One script, one allowlist, one exit code** — decision #10. The inventory assertion is a *test*, not a second gate: it needs `flutter test`, and a gate must run on a clean checkout in under a second with no Flutter (`01 §3.3`).
- **The gate is the `gate` job and the `gate` job is blocking.** `13 §4.2` — every push to `main`, every pull request, `ubuntu-latest`, 15-minute timeout. Goldens are deliberately not a per-PR gate; nothing else in `13 §4.2` is optional.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every rule id in the table is proved by a test in this file'` passes, and was seen to fail first for the stated reason
- [ ] `check_policy` is the `gate` job's first step
- [ ] every rule id has a proving test and the inventory assertion holds it
- [ ] `make check` and the `gate` job are both green
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/gate_rules_test.dart
make check
```

Then prove the assertion has teeth — add a row with no proving case, watch it go red, take it out:

```bash
make test
grep -n 'check_policy\|dart format\|flutter analyze' .github/workflows/ci.yml   # the step order
grep -c 'continue-on-error' .github/workflows/ci.yml                           # 0
# add one throwaway row to _bannedText, then:
fvm flutter test test/policy/gate_rules_test.dart   # red, naming the unproved id
# remove it, then:
fvm flutter test test/policy/gate_rules_test.dart   # green
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `ci: run the gate first and assert every rule is proved`

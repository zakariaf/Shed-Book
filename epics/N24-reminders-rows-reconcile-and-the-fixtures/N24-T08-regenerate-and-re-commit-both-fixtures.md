# N24-T08 — Regenerate and re-commit both fixtures

| | |
|---|---|
| **Epic** | [N24 — Reminders: rows, reconcile and the fixtures](epic.md) · `00-README` §9 step 9 (1 of 2) |
| **Task** | 8 of 8 |
| **Depends on** | N24-T07 |
| **Commit** | one commit · `test(fixtures): regenerate both fixtures now that reminders have a writer` |
| **Two commits, and why** | The generator must emit reminder rows before the fixtures can contain any, and `00-README` §7.4 keeps a generated artefact in a commit of its own. So: `feat(seed): the flock generator emits reminder rows` first, then the commit named above — which carries **the two JSON files and nothing else** |

## 1. Why this task exists

The fixtures were generated in **N23-T05**, one epic before reminder rows had a writer, so
`test/fixtures/flock_400_3seasons.json` contains **no reminders**. N23-T05 said so in writing and
deferred it here: *"`flock_400_3seasons.json` contains no reminder rows, and that is not a bug. The
critique records it… N24 handles it."*

Without this task, every later sweep pumps the **empty** state of a populated screen: N25-T06's
Reminders matrix variant, the accessibility gates, the eight goldens and the spec §7.7 recall
assertions all load this file. A 252-cell matrix that renders an empty list cannot overflow, so 18
cells go green while proving nothing. That is critique defect **S10**, and this is the only place the
plan repairs it.

It is also the **one sanctioned exception** to N23-T05's standing rule that the fixtures are not
regenerated. §5.3 states the exception and its boundary.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `epics/00-PLAN-CRITIQUE.md` | **S10** (*"E20-T04 puts reminder rows inside E11's and E17's transactions — correct per decision #63. But `flock_400_3seasons.json` is generated in E19-T09, one epic earlier, so it contains no reminder rows"*) · the fix: *"N24 ends with a task that regenerates and re-commits both fixtures"* · §11.3 (the anchor) | why this task exists at all |
| `epics/N23-restore-the-sweeps-and-the-seed/N23-T05-the-two-committed-fixtures-and-the-matrix-switch.md` | §5.1 (the two commits, and the generating commands with their seeds) · §5.4 (*"do not regenerate the fixtures when the schema bumps"* — the rule this task is the exception to) · §5.5 (the seven shape assertions the fixtures already carry) | the commands, the rule, and everything that must still be true afterwards |
| `docs/engineering/12-testing.md` | **§11.5** (the seed command; the two fixtures by shape and consumer; *"do not add a third fixture without deleting one"*) · §5.2 (fixtures go through `RestoreService`) · §6.2 (the matrix cell, which calls `restoreFixture`) · §11.3 (randomised ordering) | which fixture holds what, and who loads it |
| `docs/engineering/00-README.md` | **§7.1** (`test/fixtures/*.json` are committed, by name) · **§7.4** (a generated artefact is committed by itself — the golden re-baseline rule) · §7.3 (never hand-edit a generated file) | why this is two commits |
| `docs/engineering/04-migrations-media-backup-restore.md` | §6.5 (a backup whose `schema` is **lower** than `kSchemaVersion` is accepted; a higher one is refused) · §7.1 (why the fixtures are real backup files) | what the `schema` key in the file means, and why it must not move |
| `docs/engineering/09-export-formats.md` | §5.2–§5.7 (the envelope, the checksum, the `counts` block, the `_disclaimer` first key) | what regenerating changes inside the file besides the rows |
| `docs/engineering/03-data-model-and-schema.md` | §5.10 (`reminders` — the columns the generator must emit and the three `CHECK`s it must satisfy) | the shape of the rows being added |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · **#74** (the seed script, its fixed seed and fixed clock, and the two fixtures) · #73 (one restore path) | the generator's contract |
| `epics/N25-reminders-screen/N25-T06-the-matrix-variant-and-the-empty-state-that-explains-itself.md` | §5 (the Reminders matrix variant, and the row-count assertion **before** any layout assertion) | which half of the anchor's promise lands here, and which lands there |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | the fixtures, what they must contain and which tests depend on them |
| `shed-export-and-restore` | regeneration goes through the seed and the restore path |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/overflow_matrix_test.dart`
- **Test** — `'the 400-ewe fixture contains reminder rows and the Reminders variant renders a populated screen'`
- **Why it is red today** — the fixture has no reminders, so the Reminders screen's matrix variant would pump empty forever.

```bash
fvm flutter test test/features/overflow_matrix_test.dart   # expect: failing, for the reason above
```

**Split the assertion, because only one half is buildable in this epic.** `RemindersScreen` does not
exist until N25-T01, and `kPumpableVariants` gains its row at N25-T06 — so nothing can *render* here.

- **This task's half, and it is the load-bearing one:** after `restoreFixture(db,
  'flock_400_3seasons.json')`, the `reminders` table is non-empty; **all eight kinds** are present; and
  the rows straddle the three buckets N25-T01 will need — at least one `due_at` in the past, one inside
  today, one in the future. Assert counts, not a widget.
- **N25-T06's half:** the variant renders. N25-T06's file already states it *"asserts the fixture
  yields a non-zero reminder count before it asserts anything about layout"* — this task is what makes
  that count non-zero.

Keep the test name: it is the anchor and the epic and the critique both cite it. Put the split in the
`reason:` strings, so a red run says which half failed.

**Green.** The minimum code that passes, and nothing beyond it — re-run the seed, commit both fixtures alone, and assert the row count.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The two commits, in order

**Commit 1 — `feat(seed): the flock generator emits reminder rows`.** Code only, no fixtures.

| File | What changes in it, and why |
|---|---|
| `test/support/flock_generator.dart` | **Edit.** `FlockGenerator(seed)` emits `reminders` rows alongside the lambings and treatments it already generates: the offset kinds from each lambing, `tag_by` and `ring_dock_castrate` per lamb, `second_dose` and `withdrawal_end` per treatment **that has a withdrawal row** — the same rules T04 wrote, because the fixture must look like something the app could have produced |
| `tool/seed.dart` | **Edit, if the generator is not the only source.** The seed writes a backup and hands it to `RestoreService`; the reminder rows must therefore be in the **backup JSON**, not written afterwards through a repository. Restore imports rows verbatim; it does not replay verbs |

**Commit 2 — `test(fixtures): regenerate both fixtures now that reminders have a writer`.** Two files
and nothing else:

```
test/fixtures/flock_400_3seasons.json
test/fixtures/flock_15_at_cap.json
```

with the exact commands in the message, seeds included, so a reviewer reproduces the bytes rather than
reads them (N23-T05's precedent):

```
dart run --define=SHED_SEED=true tool/seed.dart --ewes 400 --seasons 3 --seed 42 --out test/fixtures
dart run --define=SHED_SEED=true tool/seed.dart --ewes 15  --seasons 1 --seed 15 --out test/fixtures
```

The test edits ride in commit 1, so commit 2 stays 100 % generated JSON:

| File | Commit | What changes |
|---|---|---|
| `test/features/overflow_matrix_test.dart` | 1 | The anchor's data half, plus the existing cells unchanged |
| `test/policy/one_restore_path_test.dart` | 1 | N23-T05's fixture-shape group gains the reminder assertions in §5.5 |

### 5.2 What the generator must produce, and why it must look real

`12 §11.5` fixes what `flock_400_3seasons.json` holds: 400 ewes, three seasons, a culled ewe whose tag
a live ewe reuses, an edited timestamp, a contradictory lambing, unicode notes. Add reminders that a
real flock would have:

| Property | Why it matters downstream |
|---|---|
| **More than `ReminderBudget.forPlatform()` open, unmuted, future rows** | It is the epic's demo claim. A fixture with 40 reminders cannot exercise the windowing at all |
| **All eight kinds present** | N25-T01's three buckets and N25-T06's variant read every kind's label; a missing kind is a label nobody renders until a shepherd has one |
| **Rows in all three buckets** — overdue, due today, upcoming | N25-T01 buckets by bound Dart boundaries. All-future rows leave two headings permanently empty and the empty-bucket copy untested |
| **At least one muted and one completed row** | `schedulable_total` excludes both, and `07 §11.1`'s *"muted reminders are listed but never counted"* has no fixture case otherwise |
| **At least one treatment with no withdrawal row and therefore no `withdrawal_end` reminder** | §12.1, carried in the fixture where the round trip can see it |
| **Every row satisfies the `<= 1` parent CHECK** | Otherwise `restoreFixture` fails at import and every matrix cell fails at once |

`flock_15_at_cap.json` gets reminders too — it is a real flock at the free-tier cap — and **still has
exactly 15 ewes in one season**. Fifteen ewes fit comfortably inside 56, which is the case
`00-README` §5.2 item 17 is about; do not inflate it to make windowing interesting.

### 5.3 The exception, and its boundary

N23-T05 laid down a rule with teeth:

> *"Do not regenerate the fixtures when the schema bumps. The committed files carry `"schema":
> <kSchemaVersion at generation>`, and `04 §6.5` accepts a backup whose schema is lower than the app's.
> That makes these two files the only standing evidence in the repo that an older backup still
> restores."*

This task is the **one sanctioned regeneration**, and it is sanctioned because the fixture is missing
*rows the app now writes*, not because the schema moved. The boundary follows directly:

- **`kSchemaVersion` must not have changed since N23-T05.** Check before you regenerate. If it has,
  stop: the regeneration would silently delete the older-backup evidence, and that is a conversation,
  not a command.
- **The `schema` key in both regenerated files must hold the same number as before.** Diff it
  explicitly; it is one line and it is the whole of the above.
- **N23-T05's rule stands after this commit.** Update the sentence in that task file that defers the
  work here — *"N24 handles it"* becomes *"N24-T08 handled it; the rule stands"* — in commit 2, under
  `00-README` §10's amendment rule. A deferral left standing after it has been honoured is a deferral
  someone acts on twice.

### 5.4 The details that are easy to get wrong

- **Restore imports rows; it does not replay verbs.** `tool/seed.dart` writes its database *through*
  `RestoreService` (decision #74), and `RestoreService` inserts what the backup JSON contains. So the
  reminders must be **in the JSON**. Calling `LambingRepository.beginLambing` from the seed to "get the
  reminders for free" builds a second write path and destroys the property decision #74 exists for.
- **The regeneration must change only what it should.** The seed is deterministic — fixed seed, fixed
  clock, uids from its own PRNG (N23-T04). So `git diff` on each fixture should show the new
  `reminders` array, the `counts` block, and the `checksum`, **and nothing else**. Ewes, lambings,
  treatments and every `uid` must be byte-identical to the previous commit. If other rows moved, the
  generator lost determinism, and the fixture will churn on every future regeneration.
- **Read the diff by the numbers, not by the bytes.** `00-README` §7.3: a generated file is read *"only
  to confirm nobody hand-edited one"*. The reviewable artefact is the command in the commit message
  plus the `counts` block — not 400 ewes of JSON.
- **Nothing under `lib/` changes in either commit.** A production change needed to make a fixture load
  is a fixture testing the wrong thing. `test/support/flock_generator.dart` and `tool/seed.dart` are
  test and tool code, and both are outside `lib/`.
- **Two fixtures, and the list is closed** (`12 §11.5`). The temptation here is a third —
  `flock_with_reminders.json`. Four topics depend on populated state and none of them needs a bespoke
  shape; a fixture per test is how a suite becomes unmaintainable.
- **`restoreFixture` still goes through `RestoreService`.** N23-T05 asserted it and
  `test/policy/one_restore_path_test.dart` holds it. Adding reminders must not tempt anyone into a
  loader shortcut; `grep -rn "jsonDecode" test/support/` stays as small as it was.
- **The matrix's cell count stays derived** (R58). Adding reminder rows to a fixture changes no
  variant. If `kPumpableVariants.length` moves in this diff, something else happened.
- **The checksum recomputes, and the header key order does not change.** `09 §5.2`: `_disclaimer` is
  the first key of every backup, including these. A regeneration that reorders the header breaks the
  round-trip equality assertion in N23-T07, which is the most expensive test in the suite to debug.
- **Every fixture case that passed before must still pass**, unchanged: the culled-ewe tag reuse, the
  edited timestamp, the contradictory lambing that the load does not repair, the treatment with no
  withdrawal row. Run N23-T05's whole group, not just the new cases.
- **The 15-ewe fixture is still exactly 15 ewes.** It is the monetization tests' input, and
  `setEwesInCurrentSeason` still writes decision #90's 99-ewe case — the helper does not disappear
  because a fixture grew.
- **The reminder rows are time-shaped, so the fixture is too.** Its `due_at` values are absolute epoch
  millis; a generator that derives them from a local `DateTime` puts a row in the wrong bucket for a
  reader in another zone, and the `uk-zone` case below is the only place that shows up.

### 5.5 The full test set

| Case | File | What it asserts |
|---|---|---|
| `'the 400-ewe fixture contains reminder rows and the Reminders variant renders a populated screen'` | `test/features/overflow_matrix_test.dart` | **The anchor**, data half: after `restoreFixture`, `reminders` is non-empty, all eight kinds are present, and rows fall in all three buckets. The render half is N25-T06's and the `reason:` says so |
| `'the 400-ewe fixture holds more open unmuted future reminders than ReminderBudget.forPlatform()'` | same | The epic's demo claim, made possible. Never a literal 56 |
| `'the 400-ewe fixture holds at least one muted and one completed reminder'` | same | `schedulable_total`'s two exclusions have a case |
| `'every reminder row in both fixtures has exactly one non-null parent'` | `test/policy/one_restore_path_test.dart` | The `<= 1` CHECK, proved on the file rather than at import time |
| `'every reminder kind in both fixtures is one of the eight'` | same | The frozen list (R49), applied to generated data |
| `'the 400-ewe fixture contains a treatment with no withdrawal row and no withdrawal_end reminder'` | same | **§12.1**, carried in the fixture |
| `'both fixtures are still valid backups'` | same | Header key order, `_disclaimer` first, checksum recomputes, `counts` matches the parsed rows |
| `'the schema key in both fixtures is unchanged from the previous commit'` | same | §5.3's boundary, as a test rather than as a hope |
| `'flock_15_at_cap.json still holds exactly 15 ewes in one season'` | same | N23-T05's assertion, unchanged |
| N23-T05's four shape cases | same | Culled-ewe tag reuse, edited timestamp, contradictory lambing unrepaired, unicode notes — all still true |
| `'restoreFixture still reaches RestoreService and no second loader exists'` | same | Decision #73, re-asserted after a change to what the fixture contains |
| `'regenerating with the same seed reproduces the committed bytes'` | manual, in §8 | Determinism. The command is in the commit message precisely so this is checkable |
| every existing matrix cell | `test/features/overflow_matrix_test.dart` | Now against a fixture with reminders. `takeException()` is null in every one |
| `'a fixture load at 01:30 on 25 October 2026 puts every reminder in the same bucket as under UTC'` · **`@Tags(['uk-zone'])`** | `test/features/overflow_matrix_test.dart` | `TZ=Europe/London`, `atFixed` in the repeated hour. `due_at` is absolute; a generator that derived it from a local `DateTime` moves a row between *overdue* and *today*, and only this cell sees it |

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Nothing under `lib/` changes.** If a file under `lib/` appears in either commit, stop and find out
  why.
- **Generated artefacts are never hand-edited** (`00-README` §7.3). If a fixture is wrong, fix the
  generator and regenerate — in its own commit, with the command in the message.
- **No third fixture, and no `drift_schemas/` change.** Both are named anti-patterns and both are
  reachable from here.

## 7. Definition of Done

- [ ] `'the 400-ewe fixture contains reminder rows and the Reminders variant renders a populated screen'` passes, and was seen to fail first for the stated reason
- [ ] both fixtures regenerated and committed by themselves
- [ ] the 400-ewe fixture contains reminders
- [ ] the at-cap fixture still has exactly 15 ewes
- [ ] the matrix passes against the regenerated fixtures
- [ ] the commit contains the two regenerated fixtures and nothing else — generated artefacts are committed alone, per `00-README` §7.4
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the stated commit exception in the header applies: the generator change is commit 1, the two JSON files are commit 2, and commit 2's message carries both generating commands with their seeds
- [ ] the anchor's render half is explicitly deferred to N25-T06 in its `reason:`
- [ ] the `schema` key in both files is unchanged, and `kSchemaVersion` has not moved since N23-T05
- [ ] the diff of each fixture shows the reminders, the `counts` block and the checksum — and nothing else
- [ ] N23-T05's deferral sentence is updated to say the regeneration happened and the rule stands
- [ ] no file under `lib/` and no file under `drift_schemas/` appears in either commit
- [ ] there are still exactly two files in `test/fixtures/`

## 8. Verification

```bash
fvm flutter test test/features/overflow_matrix_test.dart
dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42
make test
```

```bash
# Reproducibility — regenerate into a scratch directory and compare bytes.
dart run --define=SHED_SEED=true tool/seed.dart --ewes 400 --seasons 3 --seed 42 --out /tmp/fx
dart run --define=SHED_SEED=true tool/seed.dart --ewes 15  --seasons 1 --seed 15 --out /tmp/fx
diff /tmp/fx/flock_400_3seasons.json test/fixtures/flock_400_3seasons.json && echo reproducible
diff /tmp/fx/flock_15_at_cap.json    test/fixtures/flock_15_at_cap.json    && echo reproducible

# What moved, and what must not have.
git diff HEAD~1 --stat -- test/fixtures/
git show HEAD --stat                       # commit 2: exactly two JSON files
grep -o '"schema": *[0-9]*' test/fixtures/*.json          # unchanged from the previous commit
git diff HEAD~2 -- lib/ drift_schemas/                    # expect nothing
ls test/fixtures/ | wc -l                                 # expect 2

fvm flutter test test/policy/one_restore_path_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
fvm flutter test test/features/overflow_matrix_test.dart --test-randomize-ordering-seed random
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(fixtures): regenerate both fixtures now that reminders have a writer`

# Shed Book — audit: template conformance of the task backlog

**Lens.** Every task file under `epics/`, checked against the owner's three hard requirements — TDD
stated and real, `/simplify` → review before the commit, a "Skills to load" table naming only real
skills — plus header/dependencies/commit line, a checkable Definition of Done, a Verification block
with runnable commands, and one section order across every file.

**Audited.** 2026-07-31, against `epics/` at the time of writing.

---

## 0. Headline

> **The backlog was never written out as task files. 227 task files are expected; 0 exist.**
>
> `epics/` contains exactly two files — `00-PLAN.md` (the epic and task *index*, one line per task) and
> `00-PLAN-CRITIQUE.md` (the corrections). Neither is a task file, and a one-line table row cannot
> carry a first failing test, a skills table, a definition of done or a verification block.

Conformance against the three hard requirements is therefore **0 / 227 on each**, and the cause is
absence, not deviation. Nothing was found to be *badly* written; the writing has not happened. The one
thing that *was* wrong in an existing file — `00-PLAN.md` §1 asserting three rules its own §3 does not
meet — is fixed, and the fix is recorded in §5.

This finding is not new. `00-PLAN-CRITIQUE.md` §5, §6 and §12 already say it: *"223 of 227 tasks name no
test… Under the plan's own TDD rule, none of them can be started"* and *"no task names a skill."* This
audit confirms it mechanically, corrects the counts, and supplies the template §6 that was missing.

---

## 1. Per-file conformance — files that exist

| File | Kind | Header: epic · deps · commit | TDD Red/Green/Refactor | Named first failing test | `/simplify` → review | Skills table | Definition of Done | Verification block | Section order | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|
| `00-PLAN.md` | Epic + task **index** | n/a — not a task file | Stated as a rule (§1), never structured | **No** — 2 of 227 rows mention a test file; 0 name a test *name* + why-red | Stated once in §1; **was** `/code-review` → **fixed** to `/shed-code-review` | **No** — 0 of 227 rows name a skill | No | No | n/a | **Not a task file.** Sound as an index; fixed to stop claiming otherwise |
| `00-PLAN-CRITIQUE.md` | Corrections + corrected plan | n/a — not a task file | §10 restates the rule correctly | **Partial** — §11.3 supplies 64 anchor rows covering 74 tasks, correctly shaped (path · name) | §10 correctly requires `/simplify` → `/shed-code-review` | **Partial** — §11.4 maps skills *per epic*, not per task | No | No | n/a | **Not a task file.** The most useful document in the folder; its §11 is the input the task files must be written from |

## 2. Per-file conformance — task files

| Epic | Tasks in index | Task files present | TDD anchor | `/simplify` → review | Skills table | Header | DoD | Verification |
|---|---|---|---|---|---|---|---|---|
| E00 | 6 | 0 | — | — | — | — | — | — |
| E01 | 6 | 0 | — | — | — | — | — | — |
| E02 | 7 | 0 | — | — | — | — | — | — |
| E03 | 8 | 0 | — | — | — | — | — | — |
| E04 | 5 | 0 | — | — | — | — | — | — |
| E05 | 10 | 0 | — | — | — | — | — | — |
| E06 | 14 | 0 | — | — | — | — | — | — |
| E07 | 7 | 0 | — | — | — | — | — | — |
| E08 | 9 | 0 | — | — | — | — | — | — |
| E09 | 11 | 0 | — | — | — | — | — | — |
| E10 | 7 | 0 | — | — | — | — | — | — |
| E11 | 7 | 0 | — | — | — | — | — | — |
| E12 | 6 | 0 | — | — | — | — | — | — |
| E13 | 9 | 0 | — | — | — | — | — | — |
| E14 | 5 | 0 | — | — | — | — | — | — |
| E15 | 5 | 0 | — | — | — | — | — | — |
| E16 | 7 | 0 | — | — | — | — | — | — |
| E17 | 7 | 0 | — | — | — | — | — | — |
| E18 | 8 | 0 | — | — | — | — | — | — |
| E19 | 10 | 0 | — | — | — | — | — | — |
| E20 | 7 | 0 | — | — | — | — | — | — |
| E21 | 6 | 0 | — | — | — | — | — | — |
| E22 | 5 | 0 | — | — | — | — | — | — |
| E23 | 7 | 0 | — | — | — | — | — | — |
| E24 | 6 | 0 | — | — | — | — | — | — |
| E25 | 4 | 0 | — | — | — | — | — | — |
| E26 | 8 | 0 | — | — | — | — | — | — |
| E27 | 8 | 0 | — | — | — | — | — | — |
| E28 | 8 | 0 | — | — | — | — | — | — |
| E29 | 6 | 0 | — | — | — | — | — | — |
| E30 | 8 | 0 | — | — | — | — | — | — |
| **Total** | **227** | **0** | **0 / 227** | **0 / 227** | **0 / 227** | **0 / 227** | **0 / 227** | **0 / 227** |

Per `00-PLAN-CRITIQUE.md` §11.1 the epic set is re-cut to **35 epics (N00–N34)** with note search absorbed
and four epics split. **The numbering to write task files under is an open owner decision** — see §7.

---

## 3. The evidence, mechanically

Run from the repository root. Every number in this audit is reproducible.

```bash
# 1. Task files under epics/ — expected 227, actual 0
find epics -type f -name '*.md' ! -name '00-*' | wc -l            # → 0

# 2. Task rows in the index — 227 unique ids
grep -oE '^\| E[0-9]{2}-T[0-9]{2} \|' epics/00-PLAN.md | sort -u | wc -l   # → 227

# 3. Rows naming a test file — 2 (E04-T04, E11-T06); rows naming a test NAME + why-red — 0
grep -E '^\| E[0-9]{2}-T[0-9]{2} \|' epics/00-PLAN.md | grep -c '_test\.dart'   # → 2

# 4. Rows naming a skill — 0
#    (the two 'shed-screen' hits are the vocabulary term "shed screen", not a skill)
grep -E '^\| E[0-9]{2}-T[0-9]{2} \|' epics/00-PLAN.md \
  | grep -oE '(shed|indelible)-[a-z-]+' | sort -u                 # → shed-screen only

# 5. Rows carrying /simplify or a review step — 0 (both appear once, in §1's rule table)
grep -cE '^\| E[0-9]{2}-T[0-9]{2} \|.*(/simplify|code-review)' epics/00-PLAN.md   # → 0

# 6. Skills that actually exist — 24
ls .claude/skills | wc -l                                          # → 24
```

**No invented skill name was found anywhere in `epics/`.** Every `shed-*` / `indelible-*` string in both
documents resolves to a real directory under `.claude/skills/`. That defect class is clean — because
almost no skill is named at all.

**Correction to the critique.** `00-PLAN-CRITIQUE.md` §6 says four tasks name a test. Mechanically it is
**two** (E04-T04, E11-T06). E08-T08 names four test *files* as deliverables, not as an anchor; E19-T10
says *"as a test"* and names nothing. Under the rule as the owner stated it — a path, a test name, and
the reason it is red today — the honest count is **zero**.

---

## 4. The three hard requirements, verdict by requirement

| # | Requirement | Verdict | Why |
|---|---|---|---|
| **1** | TDD stated and real: Red/Green/Refactor, a named first failing test with its file path, and confirm it fails for the right reason | **Not met, 0 / 227** | Stated once as a rule in `00-PLAN.md` §1. No task carries the structure. The rule's own sentence — *"Every task below names the specific first failing test"* — was false; it is now corrected. `00-PLAN-CRITIQUE.md` §11.3 supplies **64 anchor rows covering 74 tasks**, correctly shaped; **the remaining ~153 of the 227 indexed tasks have none** |
| **2** | Ends with `/simplify` then the review, in that order, before the commit, as required steps | **Not met, 0 / 227** | Stated once in `00-PLAN.md` §1, nowhere per task. It also named the **wrong reviewer** — the bundled `/code-review` rather than the project's `/shed-code-review`, which `CLAUDE.md` mandates by name. Fixed in the index; unresolved as an owner ruling (§7) |
| **3** | A "Skills to load" table naming only real skills, each with a reason | **Not met, 0 / 227** | No task row names a skill. `00-PLAN-CRITIQUE.md` §11.4 maps skills **per epic**, which is the input, not the deliverable — a task file must narrow it and give the one-line reason |

Secondary checks, all **not met** across 227 tasks for the same reason: no header block (epic link,
dependencies, commit line), no Definition of Done, no Verification block, no section order to build a
habit from.

---

## 5. Fixes applied

Only `00-PLAN.md` was fixed; it is the only file that contained a defect rather than an absence.

| # | File | Was | Now |
|---|---|---|---|
| 1 | `00-PLAN.md` after the title | No statement that the task files are unwritten. §1 read as a description of a finished backlog | A status block: §3 is an **index**, the 227 task files **do not exist**, §1's rules are requirements on the task file to be written, and `00-PLAN-CRITIQUE.md` supersedes this file where they disagree |
| 2 | `00-PLAN.md` §1, TDD row | *"Every task below names the specific first failing test it starts from"* — false; 0 of 227 do | States the anchor's required shape (**path · test name · why it is red today**), says *"write tests for this" is not an anchor*, and points at `00-PLAN-CRITIQUE.md` §11.3 for the 64 that exist |
| 3 | `00-PLAN.md` §1, review row | *"Every task ends with `/simplify`, then `/code-review`"* — the **bundled** reviewer, which does not know this project | `/simplify` → **`/shed-code-review`** → commit, with *"never the bundled `/code-review`"* stated and the reason given. Per `CLAUDE.md` line 12 and `00-PLAN-CRITIQUE.md` §9 change 19 / §10 |
| 4 | `00-PLAN.md` §1, skills row | *"Every task names its skills"* — false; 0 of 227 do | Requires a **"Skills to load" table** in the task file, states that an invented name is a defect, and points at `00-PLAN-CRITIQUE.md` §11.4 |
| 5 | `epics/00-AUDIT-template.md` | Did not exist | This file: the conformance evidence and **the binding task-file template**, §6 |

**Not fixed, deliberately: the 227 task files were not generated.** Writing them is authoring the
backlog, not repairing a deviation, and three preconditions are unmet — the epic numbering is unruled
(§7), roughly 153 of the 227 indexed tasks have no test anchor that can be derived without reading the 22,694-line engineering set
task by task, and eleven sequencing defects (`00-PLAN-CRITIQUE.md` §1) mean several tasks as indexed
**cannot be written truthfully at all** until they are re-cut. Generating 227 files on top of that would
manufacture conformance without correctness — files that pass this audit and mislead the developer.
That is the worse failure.

---

## 6. The binding task-file template

Every task file is `epics/<epic-slug>/task-NN-<slug>.md`. **Same ten sections, same order, every file** —
that is the point of the template; the developer stops reading structure after the third task and reads
only content. The section order follows `00-README` §8, which names the files you touch in the order you
touch them.

````markdown
# <N>-T<NN> — <imperative title>

| | |
|---|---|
| **Epic** | [<N> — <epic name>](./README.md) · `00-README` §9 step <n> |
| **Depends on** | <N>-T<NN> (<what it provides>) · merged epic <N-1> |
| **Commit** | one commit · `<type>: <subject in project vocabulary>` |
| **Not one commit because** | *(omit unless true)* <reason, from `00-README` §7.4's three cases> |

## 1. Why this task exists

Two to four sentences. What is true after this task that was not true before, and what breaks if it is
wrong. No restating of the title.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/research/00-tech-decisions.md` | §<n> #<id> | <the decision this applies> |
| `docs/engineering/CONVENTIONS.md` | §<n> | <the exact names, paths, columns> |
| `docs/engineering/<nn>-<name>.md` | §<n> | <the reasoning> |
| `docs/design/indelible.md` | §<n> | *(UI tasks only)* |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `<auto-firing skill>` | <the intent it owns for this task> |
| `<auto-firing skill>` | <the second intent, if the task genuinely has one> |
| `<shed-testing, or a /runbook>` | <only where the task spans a seam> |

At most two auto-firing skills plus one. Only names from §8 of this audit.

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the right reason** — the reason
stated below, not a missing import and not a compile error in an unrelated file.

- **File** — `test/<tier>/<name>_test.dart`
- **Test** — `'<the exact test name, a property, not a file name>'`
- **Why it is red today** — <the type does not exist / the column has a DEFAULT / the widget renders a
  chooser P8 abolished>. One sentence, specific.

```bash
fvm flutter test test/<tier>/<name>_test.dart   # expect: 1 failing, for the reason above
```

**Green.** The minimum code that passes — the files in §5, nothing beyond them. Do not write the second
test's implementation while making the first pass.

**Refactor.** With the tests green. <Name what is likely to need it, or "nothing expected".>

## 5. What you build

Files in `00-README` §8 order. Skip a layer only when the task genuinely does not reach it, and say so.

| # | File | Change |
|---|---|---|
| 1 | `lib/core/db/tables/<cluster>.dart` | *(schema)* |
| 2 | `lib/domain/<area>/<file>.dart` | *(domain — pure Dart, `now` is a parameter)* |
| 3 | `lib/data/<area>_repository.dart` | *(write path — an event verb, one transaction)* |
| 4 | `lib/data/providers.dart` | *(wiring)* |
| 5 | `lib/features/<f>/<screen>_controller.dart` | *(controller — no draft, no `BuildContext`)* |
| 6 | `lib/features/<f>/<screen>_screen.dart` | *(UI — `context.tokens`, keys `<screen>.<element>`)* |
| 7 | `lib/l10n/app_en.arb` | *(every user-facing string, each with a `description`)* |
| 8 | `test/<tier>/<name>_test.dart` | *(the anchor, then the rest)* |

## 6. Constraints that bind this task

Only the ones that actually bite here — not the whole of `CLAUDE.md`.

- **§12.<n>** <which safety rule, and at which level it is held: unrepresentable / unconstructible /
  unpersistable / caught by a test on the source text>
- **3am** <the target size, the text floor, the banned gesture, the tap budget this task must not blow>
- **Offline** <only if the task touches a dependency, a permission or a platform file>
- **Write path** <only if the task writes: the row is created on screen entry, no draft, no Save button>

## 7. Definition of Done

Checkable, not aspirational. Every line is something a reader can confirm from the diff or a command.

- [ ] `<the anchor test>` passes, and was seen to fail first for the stated reason
- [ ] <the specific behaviour, phrased as an observation: "no row means `NotRecorded`", not "handles the
      empty case">
- [ ] Every new user-facing string is in `app_en.arb` with a `description`; no domain noun is a literal
- [ ] Every new interactive element is ≥ 64 × 64, has a `semanticLabel` and a `<screen>.<element>` key
- [ ] `make check` and `make test` are green
- [ ] One commit, in project vocabulary *(or: the stated exception in the header applies)*

## 8. Verification

```bash
fvm flutter test test/<tier>/<name>_test.dart    # the anchor
make gen                                          # only if the schema or a generator input moved
make check                                        # check_policy → format → analyze --fatal-infos
make test                                         # -P ci-fast + TZ=Europe/London --tags uk-zone
```

<Any task-specific command, with the exact output that proves the claim — e.g.
`dart tool/check_policy.dart` exits 1 naming `withdrawal.no_default` on the planted violation.>

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/shed-code-review`** — the project's review runbook, read in order of irreversibility. **Never the
   bundled `/code-review`**: it does not know the never-waved-through list or the one Quick Entry
   question. `CLAUDE.md`: *"Before claiming work is complete, run `/shed-code-review`."*
3. **Commit** — one commit, project vocabulary, no banned word in the message.
````

### 6.1 A worked example, so the template is not theoretical

Derived from `CONVENTIONS.md` §2.7, `CLAUDE.md` §12.1 and `00-PLAN-CRITIQUE.md` §11.3. This is what
"real TDD" looks like in this project — the anchor is a **property** (`test/policy/`, named for what it
holds), and it is red because the type does not exist.

| Section | Content |
|---|---|
| **Header** | Epic: withdrawal domain · `00-README` §9 step 2 · Depends on: the time/units task (`Instant`) · Commit: one |
| **Skills** | `shed-withdrawal` — owns doses, withdrawal days and clear dates · `shed-safety-rules` — owns "any default, pre-fill, suggestion or placeholder", which is the whole point of the task |
| **Red** | `test/policy/withdrawal_has_no_default_test.dart` · `'WithdrawalPeriod has no public generative constructor'` · **red because `lib/domain/withdrawal/withdrawal_period.dart` does not exist**, and once it does, red again until the constructor is private |
| **Green** | `sealed class WithdrawalPeriod`, `WithdrawalDays._` private, one entry point `WithdrawalDays.asEnteredByUser({required int days, required WithdrawalTarget target})`, plus `WithdrawalNotApplicable` and `WithdrawalNotRecorded` |
| **DoD** | A withdrawal period is **unconstructible** except through `asEnteredByUser`; no `DEFAULT`, no fallback, no `?? 0` anywhere in the file; §12.1 is held at *unconstructible*, not at *documented* |
| **Verification** | `fvm flutter test test/policy/withdrawal_has_no_default_test.dart` · `make check` |
| **Close** | `/simplify` → `/shed-code-review` → commit |

---

## 7. Open rulings that block writing the task files

| # | Question | Positions | Blocks |
|---|---|---|---|
| **R1** | **`/code-review` or `/shed-code-review`?** | The owner's delivery workflow says *"`/simplify` and then `/code-review`"*. `CLAUDE.md` line 12 and its runbook table say **`/shed-code-review`**, and `00-PLAN-CRITIQUE.md` §5 argues the bundled reviewer loses the name-space contest and knows none of this project's rules. **Written as `/shed-code-review`** in the index and the template — the project authority is binding and the owner's phrasing reads as generic. **Confirm or reverse.** | Section 9 of all 227 files |
| **R2** | **E-numbering or N-numbering?** | `00-PLAN.md` has 31 epics E00–E30. `00-PLAN-CRITIQUE.md` §11.1 re-cuts to 35, N00–N34, and `00-PLAN.md` §12 item 1 says fix the plan first. Task files must be written under one of them, and renumbering 227 files later is worse than deciding now | Every filename and every cross-reference |
| **R3** | **Are the eleven sequencing defects accepted?** | `00-PLAN-CRITIQUE.md` §1: S1, S2, S4, S7 and S11 are red-`main` defects. Tasks E09-T11, E10-T01, E11-T06 and E08-T08 **cannot be given a truthful anchor as indexed** — the test they would name cannot compile | The task files for E08–E11 |
| **R4** | **P8 versus `07 §5.4` and `12 §10.1`** | Two superseded artefacts still prescribe a birth-type chooser the product does not have. Until amended, the 6-tap budget anchor is unwritable | The Quick Entry and Lambing Entry task files |

---

## 8. The 24 skills — the only names a task file may use

Verified against `.claude/skills/` on 2026-07-31. Anything not on this list is a defect.

**Auto-firing (20).** `shed-conventions` · `shed-dependencies-and-toolchain` · `shed-bootstrap-and-errors`
· `shed-riverpod-providers` · `shed-write-path` · `shed-drift-schema` · `shed-domain` · `shed-withdrawal`
· `shed-safety-rules` · `shed-screens-and-routing` · `shed-accessibility-and-copy` ·
`shed-platform-gateways` · `shed-export-and-restore` · `shed-monetization` · `shed-testing` ·
`indelible-design-system` · `indelible-page-and-screens` · `indelible-controls` ·
`indelible-marks-and-strikes` · `indelible-states-and-feedback`

**Manual runbooks (4), invoked by name.** `/shed-migrations` · `/shed-release` ·
`/shed-goldens-rebaseline` · `/shed-code-review`

---

## 9. What to do next

1. **Rule R1 and R2.** Two decisions, ten minutes, and they are prerequisites to the first task file.
2. **Apply `00-PLAN-CRITIQUE.md` §12's five items to `00-PLAN.md`** — the plan is the source the task
   files are written from, and writing 227 files from a plan with eleven known sequencing defects
   propagates every one of them into a file the developer will follow at 3am.
3. **Then write the task files, epic by epic, and only one epic ahead of the build.** A task file written
   twenty epics early is written against a codebase that does not exist and will be rewritten. Write
   N00's task files, build N00, then write N01's.
4. **Re-run this audit per epic**, with the §6 template as the checklist. The three hard requirements are
   mechanically checkable — a ten-line script over the epic folder will hold them.

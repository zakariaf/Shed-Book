# N01-T07 — `.github/pull_request_template.md` — the five §12 questions, verbatim

| | |
|---|---|
| **Epic** | [N01 — The tree, the configs and the CI shell](epic.md) · `00-README` §9 step 1 |
| **Task** | 7 of 7 |
| **Depends on** | N01-T06 |
| **Commit** | one commit · `ci: pull request template carrying the five §12 questions verbatim` |

## 1. Why this task exists

The pull request is **where the safety review happens** (`00-README` §7.4). The template
carries the five §12 questions verbatim — never defaulted a withdrawal, never gave veterinary advice,
never presented the app as a regulatory record, never silently corrected an entry, timestamps carry
provenance — plus the irreversibility reading order from `CODE-REVIEW-CHECKLIST` §3.1.

Spec §12 says these rules *"should be visible in the code review checklist"*. A checklist is the
**weakest** mechanism in the hierarchy `00-README` §2.3 applies — *unrepresentable → unconstructible
→ unpersistable → caught by a test on the source text → documented* — and each of the five is
already pushed as far up it as it will go. This template is the residue: the part no type and no
`CHECK` constraint can hold, in front of the one person who can.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `shed-book-spec.md` | §12 | the five rules, and the text the template quotes character for character |
| `docs/engineering/CODE-REVIEW-CHECKLIST.md` | §2.2–§2.6 | the five questions in their diff-shaped form — *of the diff, not of the codebase* |
| `docs/engineering/CODE-REVIEW-CHECKLIST.md` | §3.1, §3.3, §3.4 | the irreversibility reading order, the never-waved-through list, the one Quick Entry question |
| `docs/engineering/00-README.md` | §2.3, §7.4 | the mechanism hierarchy, and why the PR is where this happens at all |
| `docs/engineering/CONVENTIONS.md` | §5.3 | the banned words, which apply to this file's own prose |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-safety-rules` | the five questions are its subject and it owns their wording |
| `shed-conventions` | verbatim means verbatim; the vocabulary rules apply to the template too |
| `shed-code-review` | the runbook this template is the front page of; its reading order is what §3.1 puts here |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/pr_template_test.dart`
- **Test** — `'the template carries all five §12 questions verbatim'`
- **Why it is red today** — no template exists; the questions live only in a document nobody opens while reviewing.

```bash
fvm flutter test test/policy/pr_template_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — author the template and let the test compare each question against the spec §12 text it
quotes, character for character. Read the source text out of `shed-book-spec.md` at run time rather
than hard-coding it, so a spec edit forces a template edit instead of silently diverging.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No `lib/` layer is reached. One template, one test.

| # | Path | What changes, and why |
|---|---|---|
| 1 | `.github/pull_request_template.md` | new. Exactly one template file in the repository — see §5.3 for why "exactly one" is an assertion and not a remark |
| 2 | `test/policy/pr_template_test.dart` | the anchor, written first, carrying `@Tags(['policy'])` |

### 5.2 The template

Each block pairs the spec's own sentence — quoted, and the thing the test compares — with the
checklist's diff-shaped question, which is the thing you actually answer.

```markdown
## What changed

One line, in project vocabulary (`CONVENTIONS §5`). Not the branch name.

## The five safety rules (spec §12)

Ask each of the diff, not of the codebase. If the diff does not touch the area, write
"not reached" — do not tick it.

- [ ] **§12.1 — Never default a medicine withdrawal period.** The user reads it off the bottle. The app stores what they typed and shows its source as "as entered by you."
      *Does anything in this diff put a number in a withdrawal field that the user did not read off the bottle?*
- [ ] **§12.2 — Never give veterinary advice.** No suggested doses, no diagnosis from symptoms, no "you should" text anywhere.
      *Does this diff originate a number or a judgement, rather than transform one the user supplied?*
- [ ] **§12.3 — Never present the app as a compliance or regulatory record.** It is a notebook. Holding numbers, movement reporting and statutory medicine books are out of scope, and the export should say so in its footer.
      *Does this diff produce an artefact a shepherd could hand to an inspector, without the footer that says it is not one?*
- [ ] **§12.4 — Never silently correct a user's entry.** If a birth type of "twin" has three lambs attached, flag it; do not fix it.
      *Does this diff change a value the user entered, on the way in or on the way out?*
- [ ] **§12.5 — Timestamps are honest.** Auto-captured time is labelled as such; edited time is labelled as edited.
      *Does every event time this diff writes or renders carry its provenance?*

## If this diff touches Quick Entry

> **Does the shepherd have to do anything new before the record exists?**

A tap, a wait, a decision, or a thing on screen that was not there before. If yes, it lands
somewhere calmer, in daylight.

## Read the diff in this order — irreversibility, not the order it prints

1. `pubspec.yaml`, `pubspec.lock`, `tool/policy_allowlist.txt`, `android/expected_permissions.txt`, `.fvmrc`
2. `lib/core/db/tables/**`, `drift_schemas/`, `lib/core/db/migrations.dart`
3. `lib/data/**`
4. `lib/domain/withdrawal/`, `lib/domain/stats/`, `lib/domain/time/`
5. `lib/l10n/app_en.arb`
6. `lib/features/**`

**Never waved through, however small:** `lib/domain/withdrawal/**` · `drift_schemas/**` · the
`[exempt]` section of `tool/policy_allowlist.txt` · `lib/domain/policy/disclaimers.dart` ·
`lib/main.dart` · any new export format · any table gaining an edit verb ·
`android/expected_permissions.txt` · a `pubspec.lock` diff in a PR that does not also change
`pubspec.yaml`.

## Gates

- [ ] `gate` green
- [ ] `test` green
- [ ] `/simplify`, then `/code-review`, were run before every commit on this branch
- [ ] `/shed-code-review` run once over the whole branch, in irreversibility order, before this PR was opened
```

### 5.3 What is easy to get wrong here

- **Verbatim means the test reads the spec, not a copy of it.** Hard-coding the five sentences in
  the test makes the test and the template two copies that agree with each other and can both drift
  from `shed-book-spec.md`. Parse §12's five numbered items out of the spec at run time, strip the
  `**` emphasis, and assert each appears in the template. Then a spec edit turns the build red until
  the template follows, which is the point.
- **Exactly one template may exist, and GitHub's rules here are a trap.** A single file at
  `.github/pull_request_template.md` is applied automatically. A **directory** named
  `.github/PULL_REQUEST_TEMPLATE/` means *multiple* templates and **none of them is applied by
  default** — the author has to pass a query parameter. The repository root and `docs/` are also
  searched. Assert that exactly one template path exists anywhere in the repository; two is
  undefined behaviour and a directory is silence.
- **`gh pr create --fill` skips the template.** `--fill` takes the body from the commit messages.
  Use plain `gh pr create`, which opens an editor pre-filled with the template, or `--body-file`
  pointing at a filled-in copy. This is worth a line in the repository README, because the whole
  mechanism is defeated by a habit.
- **Nothing enforces a tick.** GitHub does not block a merge on an unchecked box, and no CI job can
  read intent. That is not a defect to be engineered away — it is why `00-README` §2.3 pushes each
  of the five as far up the mechanism hierarchy as it will go, and why a rule that has dropped to
  *merely documented* has been deleted, whatever the prose says. The template's job is to make the
  question unavoidable, not to make the answer mandatory.
- **Do not paraphrase §12.3 to avoid a banned word.** *"Compliance record"* and *"official record"*
  are on `CONVENTIONS §5.3`'s banned list — the ban is on **our own prose claiming to be one**, not
  on quoting the spec rule that forbids it. Quote the spec sentence; the surrounding template prose
  stays clean.
- **Do not add a sixth question to the §12 block.** `CODE-REVIEW-CHECKLIST` §2.7–§2.9 carry three
  more real questions — tokens, the wall clock, the unearned zero — and every one of them is already
  a gate rule or a test in N03 and N06. The §12 block is exactly five because five is the number a
  reviewer reads. The gates section at the bottom is where anything mechanical goes.
- **"Write not reached, do not tick it."** §2.1: ask each question *of the diff*. A ticked box on a
  diff that never touched withdrawal is a habit that makes the ticked box on the diff that *did*
  worthless.
- **This template is prose that ships in the repository**, so `CONVENTIONS §5`'s vocabulary binds
  it: *record* not entry, *warning* not flag, *withdrawal period*, *clear date*, *turn out*,
  *reconcile*, *restore* never merge — and no `draft`, `save()`, `sync` or `Error` as a failure
  name.
- **N02 through N34 all inherit this file.** Every later epic's Definition of Done includes *"the
  five §12 questions are answered in the PR body"*. Getting the wording wrong here is getting it
  wrong thirty-three more times.

### 5.4 The test set

`test/policy/pr_template_test.dart` — one file, six cases, reading `.github/pull_request_template.md`
and `shed-book-spec.md` as text. Nothing here is time-shaped.

| Test | What it holds |
|---|---|
| `'the template carries all five §12 questions verbatim'` | the anchor. Each spec §12 sentence, read out of the spec at run time, appears in the template character for character |
| `'the template asks each rule as a question of the diff'` | the five `CODE-REVIEW-CHECKLIST` §2.2–§2.6 question sentences are present too — the statement alone is a rule, the question is a review |
| `'the template carries the six-row irreversibility reading order, in order'` | §3.1, as an ordered list. The case that fires when somebody re-sorts it alphabetically |
| `'the template carries the one Quick Entry question'` | §3.4 — the question that decides whether a change lands on the 3am path at all |
| `'exactly one pull request template exists in the repository'` | the plural-directory trap and the duplicate-file trap, in one case |
| `'the template contains no banned word'` | `CONVENTIONS §5.3` over the template's own prose, excluding the quoted spec §12.3 sentence |

## 6. Constraints that bind this task

- **The five safety rules** — this task touches all five at once, and at the **weakest** level in the
  hierarchy: *documented*. That is correct here and only here, because each rule is simultaneously
  held at a stronger level elsewhere — §12.1 unconstructible plus unpersistable, §12.2 a test on
  source text, §12.3 unconstructible, §12.4 unrepresentable plus unpersistable, §12.5
  unrepresentable. Nothing in this task may be treated as a substitute for one of those.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Offline** — the template is public-facing prose inside the repository. `CLAUDE.md`'s permitted
  wording rules apply: never *"your data never leaves your phone"*, never *"offline-first"*.

## 7. Definition of Done

- [ ] `'the template carries all five §12 questions verbatim'` passes, and was seen to fail first for the stated reason
- [ ] all five questions present and verbatim
- [ ] the reading order from `CODE-REVIEW-CHECKLIST` §3.1 is in the template
- [ ] the test fails if a question is paraphrased
- [ ] the test reads `shed-book-spec.md` §12 at run time rather than holding its own copy
- [ ] exactly one pull request template exists in the repository
- [ ] this epic's own PR body is filled in from the template, before it merges
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/pr_template_test.dart
gh pr create --web
make check
```

`--web` opens the browser with the body already filled from the template — which is the only way to
see that GitHub actually picked the file up. Then prove the anchor bites: reword one §12 sentence in
the template, watch the test fail naming which rule, and revert it.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `ci: pull request template carrying the five §12 questions verbatim`

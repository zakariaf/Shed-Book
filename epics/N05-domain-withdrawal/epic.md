# N05 — Domain: withdrawal

| | |
|---|---|
| **`00-README` §9 step** | 2 (2 of 3) |
| **Depends on** | N04 |
| **Size** | M |
| **Was** | E04 |
| **Branch** | `epic/n05-domain-withdrawal` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `test` |

## Goal

The highest-stakes code in the app, written while it is still arithmetic with no screen
attached. A wrong withdrawal number puts meat or milk into the food chain.

**Why it sits here, and not later.** `00-README` §9 step 2 is *"`lib/domain/**` — time, units,
withdrawal, warnings, statistics — with `test/domain/` including DST-1…DST-5"*, and its reason is
the one to keep in your head: **"Pure Dart, zero dependencies, the thickest test tier, and the code
most likely to be wrong invisibly. It compiles before Flutter is involved, so it is the cheapest
place in the project to be correct."** The same section is what makes step 7 possible at all —
*"Treatments and the withdrawal UI: the highest-stakes screen in the app, and the domain behind it
was finished in step 2 — so this is presentation over settled arithmetic, which is the right way
round."* N20 is allowed to be a screen epic because this epic already answered every arithmetic
question it would otherwise have had to answer in a widget test.

Three things are deliberately **not** in this epic and must not drift into it: the
`treatment_withdrawals` table (N07-T05), the schema-JSON half of the §12.1 gate (N07-T08), and every
pixel — the entry control, the countdown, the medicine book (N20). This epic ships types and pure
functions, and the only proof it can offer is a test.

## What is observably true when this epic merges

- `fvm flutter test test/domain/withdrawal` is green: a table of clear dates covering `0` days,
  the ordinary case, the exactly-at-local-midnight case and the 1000-day band edge.
- `TZ=Europe/London fvm flutter test --tags uk-zone` is green, and the file **fails loudly** under
  any other zone rather than skipping. Inside it, the 167-versus-168-hour regression: a seven-day
  withdrawal administered 20:00 on Thursday 26 March 2026 elapses at **21:00 on 2 April**, not
  20:00, and clears on **3 April 2026** — the day civil-day arithmetic would have got wrong, in the
  week UK/Ireland lambing peaks.
- `TZ=Pacific/Chatham fvm flutter test test/domain --exclude-tags uk-zone` is green, which proves no
  clear-date assertion secretly depends on a whole-hour offset.
- There is **no expression anywhere in the language** that produces a withdrawal period the user did
  not type: `WithdrawalDays` has a private generative constructor and one factory,
  `WithdrawalDays.asEnteredByUser`.
- A treatment with no withdrawal row computes `WithdrawalUnknown` — not *clears today*, not zero,
  not blank.
- A stored clear date that disagrees with today's arithmetic produces a `Warning` carrying both
  dates, and nothing anywhere can apply it.
- `dart tool/check_policy.dart` is green with **no new line in `tool/policy_allowlist.txt`**.

Not demoable: anything with a screen. If you want to see it, read the test names — that is what
this epic is for.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §3 (all of it) | the sealed type, the persistence contract, the output type, the clear-date algorithm, the conservative-interpretation argument, the disagreement, the two gates, and the three paths that route around the type |
| `docs/engineering/05-domain-correctness.md` | §2.9 | DST-1…DST-5, the measured Dart behaviour, and the `setUpAll` that fails loudly on a wrong zone |
| `docs/engineering/05-domain-correctness.md` | §1.2, §7.5 | the four import bans, and `Warning` / `WarningCode` — no writer, no `fix()` |
| `docs/engineering/CONVENTIONS.md` | §1, §2.6, §2.7 | every file path, type name and signature in this epic, already settled |
| `docs/research/00-tech-decisions.md` | §1 #3, #49, #50, #51, #52 | ceil-to-next-local-midnight in absolute time; stored exactly once; the sealed type; **two gates and no more** |
| `docs/engineering/12-testing.md` | §1.4, §2.3, §2.5, §10.3 | what is a gate and what is a test; the ambiguous hour; the three commands; the withdrawal policy file |
| `shed-book-spec.md` | §7.5, §12.1 | the withdrawal period is always entered by the user from the bottle label; never default one |

## Tasks

Work them in order. Each is one commit; the dependency column is why the order is the order.

| Task | Depends on | One line |
|---|---|---|
| [N05-T01](N05-T01-sealed-withdrawalperiod-and-its-one-entry-point.md) | N04 | `sealed WithdrawalPeriod` and its one entry point |
| [N05-T02](N05-T02-cleardatefor-ceil-to-the-next-local-midnight.md) | T01 | `clearDateFor` — ceil to the next local midnight |
| [N05-T03](N05-T03-withdrawalstatus-and-computewithdrawalstatus.md) | T02 | `WithdrawalStatus` and `computeWithdrawalStatus` |
| [N05-T04](N05-T04-the-type-and-source-half-of-never-default-a-withdrawal.md) | T03 | The type-and-source half of *never default a withdrawal* |
| [N05-T05](N05-T05-cleardatedisagrees-a-warning-that-changes-nothing.md) | T04 | `clearDateDisagrees` — a warning that changes nothing |

The first task's dependency is the last task of N04 — the `uk-zone` tier and the ambiguous hour —
because `clearDateFor` is written into a test tier that must already fail loudly in the wrong zone.

## The pull request, concretely

One epic, one branch, one pull request, one merge — then delete the branch and cut the next.

1. **Cut the branch from the merged `main`**, after N04 has gone in. The string is the one in the
   header row; copy it, do not reconstruct it.
   ```bash
   git switch main && git pull
   git switch -c epic/n05-domain-withdrawal
   ```
2. **Work the five tasks in order.** For each: read the file, load the two skills it names, write
   the anchor test, watch it fail *for the stated reason*, write the minimum code, refactor green,
   walk the Definition of Done, run the Verification block, then `/simplify`, `/code-review`,
   `/shed-code-review`, then **one commit** with the task's own message. Do not batch and do not
   reorder.
3. **Close the epic.** Run `/shed-code-review` once more over the **whole branch**, in
   irreversibility order (`CODE-REVIEW-CHECKLIST` §3.1). For this branch that order is short and it
   matters: `lib/domain/withdrawal/` and `lib/domain/validation/` are row 4 — *"arithmetic that is
   invisible when wrong. A wrong clear date hurts somebody who is not the user"* — and §3.3 lists
   `lib/domain/withdrawal/**` among the files that are **never waved through, however small**.
4. **Open the pull request** and answer the five §12 questions in
   `.github/pull_request_template.md` verbatim in the body. Question 1 is this epic's whole subject;
   answer it with the file and line of the private constructor, not with a sentence.
5. **Wait for the pipelines.** Two jobs exist and can run at this point in the backlog, and both are
   blocking:

   | Job | What it runs on this branch | What a green tick actually proves |
   |---|---|---|
   | `gate` | toolchain pin equals `.fvmrc` · `pub get` · `dart tool/check_policy.dart` (**G2** dependency allowlist + **G3** import scan) · `dart format --set-exit-if-changed` · `analyze --fatal-infos --fatal-warnings` | That `lib/domain/withdrawal/` and `lib/domain/validation/` import no Flutter, no drift, no Riverpod, no `intl` and **no `package:clock`** (`layer.domain`, R24) — the property that makes "did you test the boundary?" a compile-time question — and that no new `[exempt]` line was added to buy a green build |
   | `test` | `-P ci-fast` in randomised order · the whole suite again under `TZ=Europe/London --tags uk-zone` · `test/domain` under `TZ=Pacific/Chatham --exclude-tags uk-zone` · coverage archived, never gated | That the clear date is 168 absolute hours and not 167 in the target zone, and that nothing in the zone-agnostic tier smuggled in a whole-hour assumption. The randomised seed is printed: a failure reproduces with `--test-randomize-ordering-seed=<seed>` |

   `codegen` does not exist yet (N08-T06 writes it) and `android` does not exist yet (N31-T03 writes
   it). This epic generates nothing and touches no platform folder, so there is nothing for either
   to prove. **Do not merge on a partial green, and do not cut N06 while this is red** — N06 is cut
   from this merge commit.
6. **Fix what CI raises on this branch.** A gate failure names its rule id; look it up in
   `tool/check_policy.dart`'s rule table. Never edit the rule table, the exit code or the allowlist
   to make it pass — if a gate is genuinely wrong, say so and stop.
7. **Merge, confirm `main` is green, then delete the branch**, locally and on the remote.
   ```bash
   git switch main && git pull
   git branch -d epic/n05-domain-withdrawal
   git push origin --delete epic/n05-domain-withdrawal
   ```
8. **Only then start N06**, from the freshly merged `main`.

## Risks, and what is irreversible

**Nothing in this epic writes a schema snapshot, a native file or a published artefact.** No
migration is possible from here and no user can be hurt by a bad merge. That is the good news, and
it is exactly why the next four paragraphs matter — everything here is cheap to change *today* and
expensive to change *after* the epic it feeds.

- **The stored keys are frozen by the epic that follows.** `WithdrawalTarget.meat.key == 'meat'` and
  `WithdrawalTarget.milk.key == 'milk'` become `treatment_withdrawals.target` at N07-T05 and are
  written into `CHECK (target IN ('meat','milk'))`, into every CSV and into every JSON backup. After
  the freeze at N07-T08 they are a migration on somebody else's phone. Spell them now, exactly as
  `CONVENTIONS.md` §2.7 spells them, and never localise one.
- **`WithdrawalTarget.milk` ships even though open question 10 is open.** Whether the target market
  is ever a dairy flock is still unanswered; `milk` is in the v1 type and the v1 schema regardless,
  because shipping it now is free and retrofitting it is a migration. N00-T04 is the ruling. Do not
  gate it behind a flag and do not delete it because the v1 UI has one target.
- **`WarningCode` is an export vocabulary, not an implementation detail.** The CSV carries a
  `warnings` column of joined **codes**, never localised messages. Renaming `clearDateDisagrees`
  after N21 breaks every export ever written.
- **The rounding direction is the one defect class that hurts a person who is not the user.** Ceil
  to the next local midnight is a *second* rounding in the same direction the regulator already
  rounded (EMA/CVMP/SWP/735418/2012 §4.1.2 — to whole milkings, then to whole 12- or 24-hour
  multiples), and it is bounded by 24 h. The next developer's instinct is to "fix" the apparent
  over-hold. The comment that stops them is part of N05-T02's diff, not an afterthought.
- **The temptation this epic exists to refuse.** A medicines lookup table, a learned default, a
  "you usually enter 28 for this product" prompt, a milkings-to-days conversion, a `?? 0`. Each is
  one line and each reads as helpful. NADIS: withdrawal periods *"can change for the same medicine
  and differ between products with the same active ingredient."* The same trade name, bought twice,
  can carry two different numbers.
- **The one genuine sequencing hazard.** N05-T05 needs `Warning` and `WarningCode`, whose epic is
  N06. The task file rules it and names the two files N06 re-opens; read that section before you
  start T05, not after.

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`

## Demoable on merge

The 167-hour spring-forward regression passes, and a withdrawal period is unconstructible
except through `WithdrawalDays.asEnteredByUser`.

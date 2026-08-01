# N16-T02a — Rule P8 against `07 §5.4` and `12 §10.1`, and land the sixth tap

| | |
|---|---|
| **Epic** | [N16 — Lambing Entry and the P8 ruling](epic.md) · `00-README` §9 step 6 (2 of 5) |
| **Task** | 3 of 10 |
| **Depends on** | N16-T02 · N14-T06 |
| **Commit** | one commit · `docs: rule P8 against 07 §5.4 and 12 §10.1, and land the sixth tap` |

## 1. Why this task exists

Two superseded artefacts still prescribe a chooser the product does not have:
`07-screens.md` §5.4's *"Declare birth type — 1 tap, five big buttons"* and `12-testing.md` §10.1's sixth
tap on `lambing_entry.birth_type.twin`. Amend **both**, in this commit, per the amendment rule — and
land the sixth tap as the **first tally stroke**. This is the single most important correction the
critique found: without it, `declared_birth_type` has no writer anywhere in the plan.

The audit found two more, and they are worse than the first two because they are *authorities*:
`CONVENTIONS §4.5` publishes `lambing_entry.birth_type.twin` as its **worked example** of the widget-key
format and **R59** rules that `Key('birthType.twin')` *becomes* that key — so the naming authority
currently blesses a key that T02's canary forbids. `06 §12` lists birth type as a `ShedChoiceRow` use.
Four artefacts, one commit.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `epics/00-PLAN-CRITIQUE.md` | **S4 in full** · §11.3 (the split budget) · §11.5 (the gate table row) · the N16 section's `[audit]` note naming §4.5, R59 and `06 §12` | exactly which artefacts change and what they become |
| `CLAUDE.md` | **P8**, verbatim · the **amendment rule**, all six steps · the banned words | the ruling being applied, and the procedure for applying it |
| `docs/engineering/07-screens.md` | §1.3 (the three tap budgets) · **§5.4** (Quick Entry's actions and tap costs) · §6.3 (*"the five buttons are unselected"*) · **§6.4** (*"Declare birth type — 1 tap, five big buttons"*, and *"a valid record is one tap on this screen (birth type)"*) | the four passages that must change |
| `docs/engineering/12-testing.md` | **§10.1** (the published six-tap test, whose sixth tap is `find.byKey(const Key('lambing_entry.birth_type.twin'))`) · §10.1's new-widget-keys blockquote | the test body being amended and the key-ownership note |
| `docs/engineering/CONVENTIONS.md` | **§4.5** (the worked key examples) · **§6 R59** (`birthType.twin` becomes `lambing_entry.birth_type.twin`) · §6 (where a new numbered ruling goes) · §7 (what this file deliberately does not settle) | the naming authority's own defect |
| `docs/engineering/06-design-system.md` | **§12** (`ShedChoiceRow`: *"Birth type, ease 1–5, death cause"*) | the third artefact |
| `docs/research/00-tech-decisions.md` | §7.0 (the SETTLED owner-ruling table) · §2 (any row assuming a chooser) · §5 (versions only) | where the ruling is recorded, and what it strikes |
| `docs/skills/02-build-manifest.md` | §3 (the skill row table) · §4.2 (P8 as already ruled) | the manifest the skills must keep agreeing with |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-safety-rules` | P8 is what makes §12.4 structural and this is the ruling that lands it |
| `shed-testing` | the tap budget is the artefact being amended |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/tap_budget_test.dart`
- **Test** — `'unlock to a lambing with one lamb costs 6 taps'`
- **Why it is red today** — the five-tap budget from N14-T06 stops at the committed row, and the sixth tap in the published test targets a key that does not and must not exist.

```bash
fvm flutter test test/features/tap_budget_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion. The budget claim is not *"six taps happened"* but *"six taps produced a
lambing with a lamb on it"*, so assert both counts — `countLambings(db)` is 1 **and** `countLambs(db)`
is 1 — and assert `c.textEntries` is 0. Then add the second case that makes the ruling structural
rather than procedural: **no key tapped anywhere in the journey contains `birth_type`.**

**Green.** The minimum code that passes, and nothing beyond it — amend both documents, add the sixth tap on `lambing_entry.tally.stroke`, and record the
ruling in the decision record.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema, no domain, no data, no controller, no UI.** This is a documents-and-tests commit, and the
commit type is `docs:` for exactly that reason. If a file under `lib/` other than nothing at all
appears in this diff, the ruling is being implemented rather than recorded — T02 already implemented
it.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `docs/research/00-tech-decisions.md` §7.0 | **The ruling is recorded first.** A row in the SETTLED owner-ruling table: the question, the ruling, and *what it binds*. Amendment rule step 1 — everything else in this commit is downstream of this row existing |
| 2 | `docs/research/00-tech-decisions.md` §2 | Any decision row that assumes a birth-type chooser is **struck with its reason**, never quietly rewritten. Then grep the doc set for its number: every document opens with a `> **Decisions applied:**` line and each one that carries the number changes here |
| 3 | `docs/engineering/07-screens.md` §5.4 | The six-tap composition. Five taps produce the committed lambing row (three digits, confirm, "Lambing"); the sixth is the first tally stroke and it happens on Lambing Entry, not here |
| 4 | `docs/engineering/07-screens.md` §6.4 | *"Declare birth type — 1 tap, five big buttons"* is **deleted** and replaced by *"Add a lamb — 1 tap on the corner slab; the birth type is counted from the strokes."* The closing line *"A valid record is one tap on this screen (birth type)"* becomes *"(a tally stroke)"* — the promise is unchanged and its mechanism is not |
| 5 | `docs/engineering/07-screens.md` §6.3 | The *"Birth type undeclared — the five buttons are unselected"* row becomes *"no strokes yet; the type cell prints its gap and `NOT RECORDED`."* The rest of the row survives verbatim: **birth type is never defaulted to single** and an undeclared type is `NULL` |
| 6 | `docs/engineering/07-screens.md` §1.3 | The budget stays at **6**. Only its composition changes. Do not renumber it: the claim it holds is spec §15's fifteen seconds and the arithmetic behind six is printed in `12 §10.1` |
| 7 | `docs/engineering/12-testing.md` §10.1 | The published test body: `find.byKey(const Key('lambing_entry.birth_type.twin'))` becomes `find.byKey(const Key('lambing_entry.tally.stroke'))`, and the assertions gain `expect(await countLambs(db), 1)`. The new-widget-keys blockquote gains `lambing_entry.tally.stroke`; the budget-rationale comment is left alone |
| 8 | `docs/engineering/CONVENTIONS.md` §4.5 | The worked example `lambing_entry.birth_type.twin` becomes `lambing_entry.tally.stroke`. **A naming authority that publishes a key for a control the product does not have is worse than a missing example**, because a fixer applies it mechanically |
| 9 | `docs/engineering/CONVENTIONS.md` §6 R59 | R59 is **restated on the surviving key**, with the superseding reason recorded in place: `Key('birthType.twin')` was the defect, `lambing_entry.tally.stroke` is the format's example, and P8 is why the old example could not stand. Add the new numbered ruling for P8's consequence at the next free number and cross-reference R59 from it |
| 10 | `docs/engineering/06-design-system.md` §12 | The `ShedChoiceRow` row's Notes cell — *"Birth type, ease 1–5, death cause"* — loses birth type. N10-T06 already shipped the component as ease-only with a doc comment naming P8; this is the document catching up with the code |
| 11 | `.claude/skills/` | Grep for P8 and for the struck decision number. Any skill body that describes a birth-type chooser changes here. Amendment rule step 6: a skill-scope change also updates `docs/skills/02-build-manifest.md` §3 and re-runs `python3 tool/validate_skills.py` |
| 12 | `test/features/tap_budget_test.dart` | **The anchor.** The sixth tap, the two counts, the zero text entries, and the no-`birth_type`-key assertion over the tapped keys |
| 13 | `test/policy/p8_ruled_test.dart` | **New.** The property, not the file (`CONVENTIONS §4.1`): no document and no skill in the set prescribes a birth-type chooser, and every worked key example in `CONVENTIONS §4.5` names a key that exists in `lib/` |

### 5.2 The signatures

There are none — no Dart type is created. What this task produces is a diff whose shape is fixed by
the amendment rule, and one test body. The amended sixth tap, in `12 §10.1`'s own idiom:

```dart
// test/features/tap_budget_test.dart — spec §5, §15; 07-screens.md §1.3
// Budget rationale, unchanged: 6 taps at a generous 1.5 s each — gloved, wet,
// cold, dark — is 9 s, leaving ~6 s for unlock and cold start against the 15 s
// claim. What changed is the SIXTH tap, not the number.
await tester.countedTap(find.byKey(const Key('quick_entry.keypad.digit_4')), c);
await tester.countedTap(find.byKey(const Key('quick_entry.keypad.digit_1')), c);
await tester.countedTap(find.byKey(const Key('quick_entry.keypad.digit_2')), c);
await tester.countedTap(find.byKey(const Key('quick_entry.confirm')), c);
await tester.countedTap(find.byKey(const Key('quick_entry.event.lambing')), c);
// P8: birth type is COUNTED, so the sixth tap is a stroke, not a declaration.
await tester.countedTap(find.byKey(const Key('lambing_entry.tally.stroke')), c);

expect(c.taps, lessThanOrEqualTo(6));
expect(c.textEntries, 0);
expect(await countLambings(db), 1);
expect(await countLambs(db), 1);      // the sixth tap has to have DONE something
```

### 5.3 The details that are easy to get wrong

- **All four artefacts change in one commit, or none of them do.** `CLAUDE.md`'s amendment rule is not
  advisory: *"A change to a decision requires updating the decision record and every document **and
  skill** that applies it, in the same change."* A branch state where `07 §5.4` still prescribes five
  big buttons and `test/features/` forbids them is worse than either alone, because both look
  authoritative and the reader has no way to tell which is stale.
- **The decision record is edited first, and a superseded row is struck with its reason.** Never
  quietly rewritten. Then grep the set for the decision number — every document opens with a
  `> **Decisions applied:**` line, and a document that still lists a struck number is the next
  reader's evidence that the amendment was partial.
- **The budget is still six.** Splitting it 5 + 1 is not a reduction: N14-T06 already asserts *"unlock
  to a committed `beginLambing` row costs 5 taps and no typing"*, because the row is committed on
  screen entry (`00-README` §2.4). This task adds the sixth on a screen that now exists. Renumbering
  the claim would be the one change this task must not make.
- **`declared_birth_type` survives, and so does the `lambing_consistency` view.** P8 abolishes the
  *chooser*, not the *column*. The column is written by exactly one verb — `setBirthType`, on the
  deliberate-declaration path in T06, reached only from the type cell or from the query mark. Nothing
  in `03 §5.4` or `views.drift` changes here, and if either shows up in the diff the ruling has been
  over-applied into the frozen schema.
- **R59 is restated, not deleted.** The ruling itself is correct — `Key('birthType.twin')` really was
  a defect and the dotted `lower_snake` format really is canonical. Only its **example** is wrong.
  Rewrite it on `lambing_entry.tally.stroke` and record why the old example could not stand;
  deleting R59 would take the format ruling down with the example.
- **Widget keys are test contracts** (R59). `lambing_entry.tally.stroke` is now published in the
  naming authority and tapped by the tap budget, so renaming it later is a breaking change to
  `test/features/`, not a refactor. T02 already shipped it — this task must not change its spelling
  while writing it down.
- **`12 §10.1`'s test needs the push to actually happen.** The sixth tap is on a *different screen*,
  reached by `Routes.lambingEntry` (landed in T01) after `beginLambing` returns. If the finder comes
  up empty, the failure is navigation, not the key — check the push helper before the key spelling.
- **`06 §12`'s row is the third artefact and it is easy to miss**, because the component was already
  shipped correctly at N10-T06. The code is right and the inventory is wrong; a reader who trusts the
  inventory builds the chooser and is following the document set when they do.
- **Do not touch `tool/check_policy.dart` or its allowlist.** `CLAUDE.md` is absolute: never edit the
  gate's rule table or exit code to make a build pass, and never add an allowlist line to silence one.
  Nothing in this ruling needs either.
- **`python3 tool/validate_skills.py` is in the Verification block for a reason.** This commit may
  edit a `SKILL.md` body, and a skill whose description no longer matches its row in
  `docs/skills/02-build-manifest.md` §3 is worse than a missing skill.
- **Nothing in this task is time-shaped**, so there is no `uk-zone` case. Say so rather than adding
  one for symmetry: a DST case that cannot fail occupies the slot where a real one would go.

### 5.4 The full test set

| File · case | What it asserts |
|---|---|
| `test/features/tap_budget_test.dart` · `'unlock to a lambing with one lamb costs 6 taps'` | **The anchor.** Six keyed taps, `c.textEntries` is 0, `countLambings(db)` is 1 and `countLambs(db)` is 1 |
| `test/features/tap_budget_test.dart` · `'no key tapped in the six-tap journey contains birth_type'` | The ruling as a property of the journey, not only of the tree |
| `test/features/tap_budget_test.dart` · `'the five-tap budget from N14-T06 is unchanged'` | The split is additive. `'unlock to a committed beginLambing row costs 5 taps and no typing'` still passes untouched |
| `test/policy/p8_ruled_test.dart` · `'no document or skill in the set prescribes a birth-type chooser'` | Scans `docs/` and `.claude/skills/` for `birth_type.twin`, `five big buttons` and `Declare birth type`; expects zero outside a struck row's recorded reason |
| `test/policy/p8_ruled_test.dart` · `'every worked key example in CONVENTIONS §4.5 names a key that exists in lib/'` | The naming authority cannot publish a key for a control that does not exist. This is the assertion that would have caught the original defect |
| `test/policy/p8_ruled_test.dart` · `'06 §12 lists ShedChoiceRow for ease and death cause only'` | The third artefact, held mechanically |
| `test/policy/p8_ruled_test.dart` · `'decision-record §7.0 carries P8 with its ruling and what it binds'` | The record exists and is findable by the next fixer |
| `test/features/lambing_entry_test.dart` · `'three strokes print TRIPLET (COUNTED) and no widget carries a birth_type key'` | T02's canary, re-run. It must still be green after four documents moved |

## 6. Constraints that bind this task

- **The amendment rule** — the decision record, every document that applies the decision, and every skill that distils it change in the **same** commit. A partial amendment is the failure mode this task exists to close.
- **The five safety rules** — P8 is what pushes §12.4 from *documented* to *unrepresentable*: with no chooser, the commonest contradiction between a declared type and a lamb count cannot be created. A rule that drops back to merely documented has been deleted, whatever the prose says.
- **Never edit the gate to make a build pass** — no rule-table change, no `[exempt]` line, no allowlist entry. Nothing in this ruling needs one.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'unlock to a lambing with one lamb costs 6 taps'` passes, and was seen to fail first for the stated reason
- [ ] `07 §5.4` and `12 §10.1` are both amended in this commit
- [ ] the six-tap assertion taps a tally stroke, never a birth-type key
- [ ] `declared_birth_type` now has exactly one writer — the deliberate declaration in T06
- [ ] the decision record carries the ruling with its reason
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `CONVENTIONS §4.5`'s worked example and **R59** are both restated on `lambing_entry.tally.stroke`
- [ ] `06 §12`'s `ShedChoiceRow` row no longer lists birth type
- [ ] `07 §6.3` and `07 §6.4` are amended too, and both keep *birth type is never defaulted to single*
- [ ] the budget is still **6**; only its composition changed, and N14-T06's five-tap case is untouched
- [ ] no file under `lib/`, `drift_schemas/` or `lib/core/db/` appears in this diff
- [ ] `python3 tool/validate_skills.py` passes, and `docs/skills/02-build-manifest.md` §3 agrees with every edited skill
- [ ] no `[exempt]` line, allowlist entry or gate rule was added or changed

## 8. Verification

```bash
fvm flutter test test/features/tap_budget_test.dart
fvm flutter test test/policy/p8_ruled_test.dart
fvm flutter test test/features/lambing_entry_test.dart
python3 tool/validate_skills.py
make check
make test
```

Prove the four artefacts actually moved, and that nothing under `lib/` did:

```bash
grep -rn "birth_type.twin\|five big buttons\|Declare birth type" docs/ .claude/skills/   # expect zero
grep -rn "lambing_entry.tally.stroke" docs/engineering/CONVENTIONS.md docs/engineering/12-testing.md
git diff --name-only main -- lib/ drift_schemas/                                         # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `docs: rule P8 against 07 §5.4 and 12 §10.1, and land the sixth tap`

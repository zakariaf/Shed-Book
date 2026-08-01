# N20-T07 — The §12 disclosures, the matrix variant and the two-tap budget

| | |
|---|---|
| **Epic** | [N20 — Treatments and withdrawal](epic.md) · `00-README` §9 step 7 |
| **Task** | 7 of 7 |
| **Depends on** | N20-T06 |
| **Commit** | one commit · `feat(treatments): the §12 disclosures and the matrix variant` |

## 1. Why this task exists

§12.1's *as entered by you*, §12.3's *this is not a statutory medicine book*, and §12.5's
provenance on every row — all referenced from `Disclaimers`. Plus `treatments` joining
`kPumpableVariants`.

Treatments is the only screen in the product carrying **four** of the five §12 disclosures at once
(07 §1.5), and the medicine-book mode is *the view somebody shows an inspector*. That is why §12.3's
footer belongs on the screen and not only in the PDF, and why this closing task is a policy test
rather than a tidy-up.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§10.5** (the four disclosures on this screen, one line each: `withdrawalProvenance` next to every figure, `withdrawalCaveat` above the control, `exportFooter` as a **permanent 18 pt footer on the medicine-book segment**, provenance per row, and `clearDateDisagrees` shown and never applied), **§1.5** (the disclosure matrix — Treatments' row is the fullest in the table), §1.7 (headings and semantics) | which disclosure belongs on which surface |
| `docs/engineering/05-domain-correctness.md` | **§7.4** (`Disclaimers` as an `abstract final class` of `const` strings — *"the ONLY place these strings exist. Not in the ARB"* — and the single-definition test that caught a real duplication in the allowlist), §7.3 (`ContentPolicy`, whose allowlist is **keyed by `Disclaimers.*`** rather than by a re-typed literal) | the mechanism, and the one place it has already failed |
| `docs/engineering/CONVENTIONS.md` | §2.14 (`Disclaimers`: `exportFooter`, `withdrawalProvenance`, `withdrawalCaveat` — *referenced, never re-typed*), §4.7 (`copy.disclaimer_retyped` as a gate row), §4.1 (a policy test states the **property**, not the file), **R58** (252 cells over 14 pumpable variants, the arithmetic following the variant list), R57 (the test tree) | the names, the gate and the count |
| `docs/engineering/12-testing.md` | **§6.1–§6.2** (the matrix, `kPumpableVariants` in `test/support/harness.dart`, and the self-check that **derives** the count), §7.4 (the four files that iterate the table, and the sweeps N33 runs), **§1.4** (*if it can be asserted by reading source text, it is the gate's job* — and what that leaves for a test), §10.1 (the two-tap budget) | where the row goes, and what this policy file is allowed to assert |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.4 (headings — one `headingLevel: 1` per screen), §4 (*"Treatments" — the two segments, in 07 §10's words*), §7.3 (the gate asserts a heading node on **all fourteen** variants), §5.2 (the redundancy table this row enrols in) | what the matrix row quietly signs the screen up for |
| `docs/engineering/09-export-formats.md` | §7 (the disclaimer's placement per format, and *"Export screen: verbatim, above the buttons"*) | how the same string behaves in the epic that follows this one |
| `docs/engineering/06-design-system.md` | §12 (`ShedEmptyState`, `ShedBanner`), §5.1 (the 18 px floor) | the footer's size floor |
| `docs/engineering/11-monetization-and-store.md` | §8 rule 1 (Treatments *"renders nothing monetization-related"* at any entitlement state, alongside the five shed screens) | the negative this screen also has to hold |
| `epics/00-PLAN-CRITIQUE.md` | §11.3 (N06-T09 already created `disclaimer_is_defined_once_test.dart`), S3 (the fixtures do not exist until N23) | why this is a second file, and why it seeds rather than restores |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-safety-rules` | which disclosure belongs on which surface |
| `shed-testing` | the variant row and the budget assertion |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/disclaimer_is_referenced_test.dart`
- **Test** — `'every disclosure on the Treatments screen is referenced from Disclaimers and none is re-typed'`
- **Assertion, spelled out** — pump the screen in **book** mode and assert
  `find.textContaining(Disclaimers.exportFooter)` finds a widget; pump the entry control and assert
  the same for `Disclaimers.withdrawalCaveat`; pump a treatment with a withdrawal and assert the same
  for `Disclaimers.withdrawalProvenance`. Compare against the **constants**, never against a copy of
  their text: a test that hard-codes the literal still passes after somebody edits the constant, which
  is the one failure this assertion exists to catch (`12 §10.1` makes the same point in its own
  comment). Then assert the footer is reachable **without a tap** — `find` it on the first pumped
  frame of book mode, not after opening anything.
- **Why it is red today** — the screen renders no disclosure, and the first one typed inline would defeat the one-file rule.

```bash
fvm flutter test test/policy/disclaimer_is_referenced_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the three disclosures by reference, the variant row, and the tap budget.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 steps 6 and 7. **Steps 1–5 are skipped and the commit message says so** — no schema,
no domain, no verb, no provider, no controller. Three surfaces gain a reference, one line goes into
the harness, and the rest is tests.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `lib/features/treatments/treatments_screen.dart` | edit | `Disclaimers.exportFooter` as a **permanent 18 px footer** on the book mode — not a tooltip, not behind a tap, not in an expander |
| 2 | `lib/features/treatments/widgets/treatment_row.dart` | edit | `Disclaimers.withdrawalProvenance` beside **every** withdrawal figure, including the previous figure in the repeat sheet and the struck figure on a voided row |
| 3 | `lib/features/treatments/widgets/withdrawal_control.dart` | edit | confirm `Disclaimers.withdrawalCaveat` is above the control and permanently visible (T02 placed it; this is the commit that asserts it) |
| 4 | `test/support/harness.dart` | edit | one line: `RouteNames.treatments: () => const TreatmentsScreen(),` into `kPumpableVariants` |
| 5 | `test/support/seeds.dart` | edit | `seedTreatmentBook(db)` — one animal, one treatment with a meat withdrawal, one with `not_applicable`, one with none and one voided, so the matrix pumps all four renderings rather than an empty page |
| 6 | `test/policy/disclaimer_is_referenced_test.dart` | **new** | the anchor plus the cases in §5.4 |
| 7 | `test/features/overflow_matrix_test.dart` | edit | the `treatments` row, and the derived-count self-check |
| 8 | `test/features/tap_budget_test.dart` | edit | re-assert the two-tap repeat **with the disclosures rendered** — see §5.3 item 4 |
| 9 | `docs/engineering/07-screens.md` §10.5 | edit | record which widget carries which disclosure, so the next reader can find them without grepping |

### 5.2 The signatures

```dart
// test/support/harness.dart — the table lives here and four files iterate it
// (12 §6.2). A local copy in a test file passes today and silently stops
// covering the screen at N33.
final kPumpableVariants = <String, Widget Function()>{
  // …the rows built so far…
  RouteNames.treatments: () => const TreatmentsScreen(),   // here
};
```

```dart
// test/features/overflow_matrix_test.dart — the count follows the map, never a
// literal. R58: 14 variants x 3 devices x 3 text scales x 2 bold states = 252,
// and "the arithmetic follows the variant list, not a remembered number".
test('the matrix covers every route built so far, and the count is derived', () {
  expect(kPumpableVariants.length, _routesBuiltSoFar.length,
      reason: 'a screen was added without a matrix row — R58');
});
```

```dart
// test/policy/disclaimer_is_referenced_test.dart — the property, not the file
// (CONVENTIONS §4.1). Compare against the CONSTANT, never a copy of its text.
expect(find.textContaining(Disclaimers.exportFooter), findsOneWidget);
```

### 5.3 The details that are easy to get wrong

1. **This file and `disclaimer_is_defined_once_test.dart` assert opposite properties, which is why
   there are two.** N06-T09's file proves the string exists as a literal in **exactly one file** —
   absence of duplication, a source scan. This one proves the string is **actually on the screen** —
   presence, which no source scan and no gate can establish. `12 §1.4` is the rule that keeps them
   apart: *if it can be asserted by reading source text, it is the gate's job.* The re-type half is
   already the gate's (`copy.disclaimer_retyped`); do not re-implement it here as a `RegExp` over
   `lib/`.
2. **Comparing against the constant is what makes the test load-bearing.** A test that writes
   `find.text('as entered by you')` passes forever, including after somebody edits
   `Disclaimers.withdrawalProvenance` and the screen stops matching. Reference the constant and the
   test tracks the string. This is the same instruction `12 §10.1` gives in its own comment, for the
   same reason.
3. **§12.5's provenance is *not* a `Disclaimers` string.** It comes from
   `RecordedTime.provenanceLabel`, an exhaustive switch in the domain that can never be empty
   (05 §4.1). Four §12 disclosures land on this screen and only three of them come from
   `Disclaimers` — asserting all four against the same class is the mistake, and it produces a test
   that cannot fail.
4. **The budget is re-asserted here because this task can break it.** T04 proved two taps on a screen
   with no footer and no caveat. Adding a permanent 18 px footer and a permanently visible caveat
   changes the layout, and at `textScaler` 2.0 on the smallest device the animal lines in the repeat
   sheet can fall below the fold — a tap becomes a scroll, and a scroll is not a tap but it is time
   at 03:20. Re-run the budget with the disclosures present, and add the reachability assertion
   `12 §6.2` requires: at the smallest `Device` and `textScaler` 1.3, every target the screen offers
   is reachable without scrolling past the fold.
5. **The footer is permanent, 18 px, and not behind a tap** (07 §10.5). *"This is the view someone
   shows an inspector, so the string belongs on screen and not only in the PDF."* An expander, a
   tooltip (`Tooltip` is a banned widget anyway) or a first-run-only banner all fail the same clause.
6. **`Disclaimers` never enters the ARB**, and the ARB test must not start expecting it. A translator
   can soften or drop an ARB string and the app has no mechanism to notice (05 §7.4). If
   `arb_has_no_domain_noun_test.dart` (N33-T05) or the vocabulary-label test trips over these strings,
   the fix is in the test's scope, never in moving the constants.
7. **`ContentPolicy`'s allowlist is keyed by `Disclaimers.*`, and that is not decoration.** 05 §7.4
   records that the banned-phrase allowlist had **already** re-typed the disclaimer once, during the
   research — the exact failure this task guards. If the screen's copy trips `ContentPolicy`, add a
   key, never a literal.
8. **The matrix row quietly enrols the screen in three more sweeps.** `12 §7.4`'s
   `semantics_gate_test.dart` and `tap_target_test.dart` and `10 §7.3`'s heading assertion all iterate
   `kPumpableVariants`. So this one line means Treatments must carry exactly one `headingLevel: 1`
   node, a `semanticLabel` on every interactive element, and ≥ 64 × 64 on every target — from N33
   onward, whether or not anyone remembers. Author them now; N33 verifies, it does not fix.
9. **The count is derived, never typed.** R58. Until N33 completes the table, the self-check follows
   the map's own length; writing `expect(kPumpableVariants.length, 8)` re-introduces exactly the
   remembered number R58 exists to delete. Decision #114's 216 is superseded and predates variants 13
   and 14.
10. **Seed; do not `restoreFixture`.** `12 §6.2`'s published matrix body calls
    `restoreFixture(db, 'flock_400_3seasons.json')`, and the fixtures are produced by `tool/seed.dart`
    through the restore path at **N23**, three epics away (critique S3). Copying the snippet verbatim
    gives a red test that looks like a product bug. `seedTreatmentBook` is the four-row seed this
    screen needs, and N23-T06 is the one task that switches the matrix to the fixture.
11. **Pump both modes.** The matrix takes one widget per variant, and a screen with two modes has two
    layouts; the book mode is the one with the footer and the long product names, so it is the one that
    overflows first. Pump the variant in book mode and add a mode-switch case in
    `treatments_test.dart` rather than adding a fifteenth variant — R58's count follows the **route**
    list, and a second treatments row would make 252 wrong.
12. **Nothing about money renders here either.** Treatments is not one of the five shed screens, but
    11 §8 puts it in the same sentence: the affordance exists in exactly two places, and this is
    neither. N30-T08 extends `no_monetization_test.dart` to cover it; this task's job is to not create
    the thing that test would find.
13. **This commit touches `lib/` in three places and they are all one-line references.** Anything
    else under `lib/` means the task has grown, and the disclosures were supposed to have been placed
    by T02, T03 and T06 as those screens were built.

### 5.4 The full test set

**`test/policy/disclaimer_is_referenced_test.dart`** — new.

| Case | What it pins |
|---|---|
| `'every disclosure on the Treatments screen is referenced from Disclaimers and none is re-typed'` | **the anchor**, all three constants, compared against the constants |
| `'the medicine book footer is on the first frame and is not behind a tap'` | 07 §10.5 — the inspector's view |
| `'the footer renders at or above the 18 px floor at every text scale'` | the size clause of the same line |
| `'every withdrawal figure on the screen carries withdrawalProvenance, including the struck one and the repeat sheet one'` | *"next to **every** withdrawal figure"* — the two easy ones to miss |
| `'the time provenance comes from RecordedTime.provenanceLabel and not from Disclaimers'` | §5.3 item 3 |
| `'no Disclaimers text appears as a literal under lib/features/treatments/'` | the cheap cross-check; the gate owns the general case |

**`test/features/overflow_matrix_test.dart`** — extended.

| Case | What it pins |
|---|---|
| `'treatments pumps at every device, text scale and bold state without overflow'` | 3 × 3 × 2 = 18 cells, no `RenderFlex` overflow and no exception, seeded with all four withdrawal renderings |
| `'the matrix covers every route built so far, and the count is derived'` | R58 |
| `'every target on treatments is reachable at the smallest device and textScaler 1.3'` | `12 §6.2`'s reachability clause |

**`test/features/tap_budget_test.dart`** — extended.

| Case | What it pins |
|---|---|
| `'repeat last treatment still costs 2 taps with the disclosures rendered'` | the budget after the layout grew — §5.3 item 4 |

**`test/features/treatments_test.dart`** — extended.

| Case | What it pins |
|---|---|
| `'treatments carries exactly one headingLevel 1 node and no headingLevel 2'` | 10 §3.4, enrolling the screen in N33's sweep |
| `'both modes pump clean at textScaler 2.0 with boldText'` | the second layout the matrix does not reach |

## 6. Constraints that bind this task

- **Four of the five rules land on this one screen (07 §1.5), and every disclosure is *referenced*, never re-typed.** §12.1's *as entered by you*, §12.3's *this is not a statutory medicine book*, §12.5's provenance on every row — all read from `Disclaimers` (N06-T09) so `copy.disclaimer_retyped` stays green. §12.3's footer belongs on the **screen** and not only in the exported PDF, because medicine-book mode is the view somebody holds up to an inspector.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **The disclosures are `const` strings in one file** — referenced, never re-typed, never localised, never moved to the ARB.
- **`00-README` §8 steps 1–5 skipped** — the commit message says so, and the only `lib/` changes are three one-line references.

## 7. Definition of Done

- [ ] `'every disclosure on the Treatments screen is referenced from Disclaimers and none is re-typed'` passes, and was seen to fail first for the stated reason
- [ ] no disclosure string appears as a literal in the feature
- [ ] the variant count stays derived
- [ ] the two-tap repeat budget still holds
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the medicine-book footer is on the first frame, at or above 18 px, and not behind a tap
- [ ] `kPumpableVariants` gains exactly one row and the table stays declared once, in `test/support/harness.dart`
- [ ] the screen carries exactly one `headingLevel: 1` node and a `semanticLabel` on every interactive element

## 8. Verification

```bash
fvm flutter test test/policy/disclaimer_is_referenced_test.dart
fvm flutter test test/policy/disclaimer_is_defined_once_test.dart
fvm flutter test test/features/overflow_matrix_test.dart
fvm flutter test test/features/tap_budget_test.dart
fvm flutter test test/features/treatments_test.dart
fvm flutter test test/design
grep -rn "statutory medicine\|as entered by you\|suggests no value" lib/ --include=*.dart
grep -rn "kPumpableVariants" test/ | grep -v "support/harness.dart"
grep -rn "expect(kPumpableVariants.length, [0-9]" test/
grep -rn "restoreFixture" test/features/overflow_matrix_test.dart
make check
make test
```

The first grep must return exactly the three lines in `lib/domain/policy/disclaimers.dart`. The
second must show iterations only — never a second table. The third must return nothing (R58). The
fourth must return nothing until N23-T06: the fixtures do not exist yet, and a test that needs one is
a test that gets skipped and forgotten.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(treatments): the §12 disclosures and the matrix variant`

# N33-T06 — Apple's Accessibility Nutrition Label and the per-screen sweep

| | |
|---|---|
| **Epic** | [N33 — Ship gates: the sweeps, the matrix, the goldens and the journeys](epic.md) · `00-README` §9 step cross-cutting, before 12 |
| **Task** | 6 of 9 |
| **Depends on** | N33-T05 |
| **Commit** | one commit · `test(policy): the Accessibility Nutrition Label and its sweep` |

## 1. Why this task exists

The declaration, and the per-screen sweep behind it — because the label is a claim, and a
claim about accessibility that no test holds is the same class of defect as a claim about privacy that
no gate holds.

Apple's bar is behavioural, not technical: *"To indicate support for an accessibility feature in the
Accessibility Nutrition Labels, users must be able to complete **all of the common tasks** of your app
using that feature."* Shed Book has no login, so the list is fixed at **seven**: first run ·
unlock/restore purchase · Quick Entry · Lambing Entry · Pen Board · Treatments · Settings. Six of seven
is not declarable, and the temptation is strongest exactly where the evidence is a hand pass.

This is also the only task in N33 whose long pole is not code. Rows 1–10 of `10 §7.2` run on **one
small iPhone and one small Android, in a dark room, holding a torch**, across fourteen variants. That
is an evening and it cannot be moved onto the laptop.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/10-accessibility-and-i18n.md` | **§7.1** (the nine-row declaration table, with a Declare? and an Evidence column, and the Captions paragraph in full) · **§7.2** (the eleven-row per-screen sweep, its subjects — the fourteen variants — and the ship gate: rows 1–10 green on all fourteen) · **§7.3** (the automated half) · **§1.1** (the seven common tasks, and Apple's own sentence) · §1.2 (WCAG 2.2 AA through WCAG2ICT, and the four criteria regulators exclude) · **§1.3** (the EAA does not apply — no VPAT, no EN 301 549) · §2.1–§2.3 (the platform flag truth table and the reduce-motion resolver) · §4.2 (clamping makes the Larger Text declaration a lie) · §5.3 (grayscale is manual) · §6.3 (Switch Control and Voice Control) | every claim, its evidence and its wording |
| `docs/engineering/12-testing.md` | §11.1 (a policy test is named for the property) · §13 (what CI proves, and what it cannot) · §7.4–§7.6 (the assertions the declaration cites) · §8.2 (the goldens the Larger Text and Sufficient Contrast rows cite) | which assertions may be named as evidence |
| `docs/engineering/06-design-system.md` | §9.1–§9.4 (no white flash at four layers, and the parity gate the Dark Interface row cites) · §2.5 (the accessibility flags the theme layer reads) · §10.1 (haptics are real, never load-bearing) | two of the seven declared rows |
| `docs/engineering/07-screens.md` | **§21.3** (what CI cannot prove — legibility under a head torch, whether six taps *feel* like fifteen seconds, whether a gloved thumb finds the confirm key) | the honest boundary between an assertion and a hand pass |
| `docs/engineering/11-monetization-and-store.md` | §9.4–§9.5, §10 (the store declarations, the App Review notes, and where an accessibility note belongs in the listing) | where the label sits beside the other store claims |
| `docs/engineering/08-platform-integration.md` | §10 (the record of why OCR and voice tag entry are v2, and the on-device-recognition ruling) | why Captions cannot be declared |
| `docs/research/00-tech-decisions.md` | §5 only for versions · **#107** (Apple's Accessibility Nutrition Labels are the ship gate; WCAG 2.2 AA via WCAG2ICT) · §7.0 owner ruling #6 (on-device speech recognition cut from v1) · #99 · #104 · #105 · #106 | the decision that makes this a gate, and the one that makes Captions false |
| `epics/N02-.../N02-T02` | §5.2, §5.3 (`docs/store/offline-honesty.md` — the precedent for a recorded public claim under `docs/store/`) | where the declaration file lives, and on whose precedent |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-accessibility-and-copy` | the label's claims and what each one requires per screen |
| `shed-testing` | the per-screen sweep that holds them |
| `/shed-release` | typed by name — the declaration is entered in App Store Connect, and this skill is the one that carries the store-artefact ritual |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/accessibility_label_test.dart`
- **Test** — `'every claim in the Accessibility Nutrition Label is held by an assertion in this suite'`
- **Why it is red today** — the declaration would otherwise be written from optimism.

```bash
fvm flutter test test/policy/accessibility_label_test.dart   # expect: failing, for the reason above
```

Sharpen it in the direction that decides whether it can ever fail. Iterate **from the declaration to
the evidence**, never the other way round: for each declared feature, read its evidence rows and assert
that each named test **file exists** and that each named test **name appears verbatim inside it**.
Iterating the tests and checking each has a claim passes vacuously the moment a claim is added, which
is exactly when you need it to fail. Then assert every `manual` evidence row carries a device and a
date, and that the date is not older than the current build's version row.

**Green.** The minimum code that passes, and nothing beyond it — the declaration, and one assertion per claim, per screen.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No `lib/` layer is reached.** One new document, one new test, two amendments — say so in the commit
message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `docs/store/accessibility-nutrition-label.md` | **New.** The single authored source of every accessibility claim this product makes: the nine features with Declare? yes/no, the seven common tasks, one **evidence row per claim** naming either `file · test name` or `manual · device · date`, and the Captions paragraph. **No authority names this path**; the task creates it on `docs/store/offline-honesty.md`'s precedent (N02-T02), in the folder `10 §7.1` calls *"the store listing's accessibility notes"* and that N32-T02 already fills |
| 2 | `test/policy/accessibility_label_test.dart` | **New. The anchor, written first.** `@Tags(['policy'])`. Parses the declaration file, walks claim → evidence, and holds the two undeclared rows |
| 3 | `docs/engineering/10-accessibility-and-i18n.md` §7.1 | **Amended, in this commit.** Its Evidence column becomes a pointer to the declaration file rather than a second, drifting copy of it. One source for a public claim |
| 4 | `docs/store/accessibility-nutrition-label.md` §sweep | **Same file, its second half.** The dated record of `10 §7.2`'s eleven rows × fourteen variants, on two named physical devices. N34-T04 owns the pre-release checklist and folds this into it; this task creates the record and names N34-T04 as the task that schedules its repeat |

### 5.2 The signatures

The declaration's machine-readable half. It is a document a human reads, so the structure is a table,
and the test parses the table rather than a second JSON copy of it:

```markdown
<!-- docs/store/accessibility-nutrition-label.md -->
| Feature | Declare | Evidence |
|---|---|---|
| VoiceOver | yes | `test/design/semantics_gate_test.dart` · `'<variant> · <device> · scale 1.0 — 60 pt floor'` ; manual · iPhone SE (3rd gen), iOS 26.2 · 2026-08-14 |
| Larger Text | yes | `test/features/overflow_matrix_test.dart` · `'the matrix covers every route, and the count is 14'` ; `tool/check_policy.dart` · `type.clamp` |
| Captions | no | undeclared — see §Captions |
```

The walk, from claim to evidence:

```dart
// test/policy/accessibility_label_test.dart
@Tags(['policy'])
library;

/// Iterates the DECLARATION, not the tests. A loop over the test files that
/// checks each has a claim passes vacuously the moment a claim is added — which
/// is the exact moment this file exists to fail.
test('every claim in the Accessibility Nutrition Label is held by an assertion in this suite', () {
  for (final claim in declaredFeatures(kLabelFile)) {
    expect(claim.evidence, isNotEmpty, reason: '"${claim.feature}" is declared with no evidence');
    for (final e in claim.evidence) {
      switch (e) {
        case AutomatedEvidence(:final path, :final testName):
          expect(File(path).existsSync(), isTrue, reason: '$path does not exist');
          expect(File(path).readAsStringSync(), contains(testName),
              reason: '"$testName" is not in $path — it was renamed and the claim is now unheld');
        case ManualEvidence(:final device, :final date):
          expect(device, isNotEmpty);
          expect(date, isNotNull,
              reason: 'a manual claim with no date is the same defect as an automated '
                      'claim with no test');
      }
    }
  }
});
```

### 5.3 The details that are easy to get wrong

- **Iterate from the declaration, always.** This is the single structural decision in the task. Every
  other direction produces a test that is green when the label is a lie.
- **A renamed test silently unholds a claim, and only a verbatim name catch finds it.** Asserting the
  *file* exists is not enough: `semantics_gate_test.dart` will exist for the life of the project. The
  assertion is that the named test string appears **inside** it.
- **A manual claim with no date is exactly as broken as an automated claim with no test.** Four of the
  seven declared features — VoiceOver, Voice Control, Differentiate Without Color Alone, and half of
  Sufficient Contrast — are held partly by a hand pass. Each carries `manual · <device> · <date>`, and
  the test fails on a missing date and on a date older than the version row. `10 §7.1`: *"Re-evaluate
  every release; put it in the release checklist, not in someone's memory."*
- **Captions must stay undeclared, and the reason is a consequence of an earlier decision, not an
  oversight.** The app records voice notes (`record` 7.1.1, AAC-LC `.m4a`) and cannot transcribe them:
  on-device speech recognition was cut from v1 because the recognizer runs in another process whose
  network access the manifest cannot constrain (owner ruling §7.0 #6). Declaring Captions would be
  false; ignoring the gap would be worse. The design constraint that replaces it — *a voice note never
  carries a fact that exists nowhere else* — belongs in the file, verbatim.
- **Audio Descriptions is undeclared because there is no video.** One line, stated, so nobody
  re-opens it.
- **Larger Text is declarable only because nothing clamps.** `10 §4.2`: clamp at 1.3× and *"you cannot
  declare Larger Text, which costs you a Nutrition Label row."* The evidence rows are the 252-cell
  matrix and the `type.clamp` gate row — and if either is ever weakened, this claim goes with it.
- **Sufficient Contrast is re-checked with Bold Text, Increase Contrast and Reduce Transparency on —
  and there is no reduce-transparency flag to read.** Flutter exposes none; the claim is held by
  construction instead: `BackdropFilter`, frosted bars and scrims over text are banned outright
  (`06 §2.5`, `10 §11` row 34). Say that in the evidence cell rather than citing a flag that does not
  exist.
- **Dark Interface is held by the four-layer no-white-flash configuration and its parity gate**
  (`06 §9.4`), not by `themeMode: ThemeMode.dark`. A cold launch that flashes white for two frames
  fails the claim on a device and passes every widget test.
- **Reduced Motion needs *both* flags.** iOS never sets `disableAnimations`; Android never sets
  `reduceMotion`; `MediaQueryData` has no `reduceMotion` property at all. The two-branch test in
  `test/design/reduce_motion_test.dart` (N09-T08) is the evidence, and reading one flag is the bug
  `10 §11` row 10 names.
- **The seven common tasks and the fourteen variants are different lists, and both are needed.** The
  label's bar is per **task**; the sweep's subjects are per **variant**. Unlock/restore purchase is a
  common task and is not a variant; note search is a variant and is not a common task. A file that
  conflates them will under-test the purchase flow, which is the one task nobody thinks of as
  accessibility work.
- **Row 11 of `10 §7.2` — the glove and freezer-bag pass — informs the design and does not gate the
  release.** It is decision-record §7.1 item 2 and it is open. Record its result; do not let it block.
- **Row 6b (Smart Invert) is per release, not per screen.** Photos invert and that is accepted; no
  photo is the sole carrier of meaning.
- **Row 10 runs the sweep with `app_settings.left_handed` both ways.** A mirrored layout that clips at
  AX5 is a defect the default layout hides, and `left_handed` mirrors the keypad's bottom row **and the
  bottom action bar order**, and nothing else (R40).
- **Do not produce a VPAT and do not claim EN 301 549 conformance** (`10 §1.3`). The EAA covers a closed
  list and a one-time-purchase farm notebook is not on it. A test case asserts neither phrase appears
  anywhere under `docs/store/`.
- **The sweep's date is a civil date, never an instant.** `docs/store/…` records `2026-10-25`, not an
  epoch millisecond — which is decision #2's split applied to a document. A sweep run at 01:30 on the
  clocks-back night is one row, not two, and a date parsed from an instant in the repeated hour can
  resolve to either of two candidates.

### 5.4 The full test set

| File · case | What it asserts |
|---|---|
| `test/policy/accessibility_label_test.dart` · `'every claim in the Accessibility Nutrition Label is held by an assertion in this suite'` | **The anchor.** Claim → evidence for every declared feature; file exists; test name appears verbatim; manual rows carry a device and a date |
| `…` · `'a declared feature with no evidence row fails'` | *canary.* Plant a tenth declared feature with an empty evidence cell and assert the failure names it |
| `…` · `'a renamed test unholds its claim'` | *canary.* Rename one referenced test, assert the failure names both the claim and the file |
| `…` · `'a manual evidence row with no date fails'` | *edge.* The row shape that looks complete and is not |
| `…` · `'a manual evidence row older than the current version row fails'` | *edge.* `10 §7.1`'s *"re-evaluate every release"*, as an assertion instead of a habit |
| `…` · `'Captions and Audio Descriptions are undeclared and each carries its reason'` | *edge.* The two rows where the honest answer is no |
| `…` · `'the Captions paragraph contains the voice-note design constraint verbatim'` | *edge.* *"A voice note never carries a fact that exists nowhere else."* If that sentence goes, the gap is unmitigated |
| `…` · `'the seven common tasks are exactly 10 §1.1's seven'` | *edge.* No login, so seven — and unlock/restore purchase is one of them |
| `…` · `'every declared feature names every one of the seven common tasks in its sweep record'` | *edge.* Apple's bar is *all* of them; six of seven is not declarable |
| `…` · `'no VPAT and no EN 301 549 claim appears under docs/store/'` | *edge.* `10 §1.3`, held by a machine |
| `…` · `'the declaration quotes docs/store/offline-honesty.md and adds no new public claim'` | *edge.* §12.3: the app is not a compliance record, and an accessibility document is a place a new claim would slip in |
| `…` · `'every sweep date is a civil date, never an instant'` | *edge, `uk-zone`.* Parsed under `TZ=Europe/London`: `2026-10-25` is one day whichever of the two 01:30s it was written in. A date stored as epoch millis in the repeated hour resolves to either of two candidates, and the sweep record would then be ambiguous about which night the pass happened on |

### 5.5 The manual half, and how it is recorded

`10 §7.2` rows 1–10 are the ship gate and they run by hand. The record in
`docs/store/accessibility-nutrition-label.md` §sweep is a table with one row per pass and one column
per variant, plus:

- **The two devices, named with their OS versions.** One small iPhone, one small Android — the smallest
  and oldest you support, because that is where the layout breaks.
- **The conditions**: a dark room, a head torch, and for row 11 a freezer bag.
- **The date**, as a civil date.
- **The result per row**, and for any failure, the issue or the commit that fixed it.

Row 7 — VoiceOver/TalkBack, eyes closed — is the one to do first and the one that will find things:
*"the full core loop — pick animal, record a lambing, hear the receipt — without looking. Then: open a
ewe card, foster a lamb, log a treatment with a withdrawal, read the season chart, export a CSV."*
Nothing in `test/` substitutes for it (`07 §21.3`).

## 6. Constraints that bind this task

- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every claim in the Accessibility Nutrition Label is held by an assertion in this suite'` passes, and was seen to fail first for the stated reason
- [ ] every claim maps to at least one assertion
- [ ] a claim with no assertion fails the test
- [ ] the declaration matches what the sweeps actually prove
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the test iterates **from the declaration to the evidence**, and a renamed test unholds its claim
- [ ] every `manual` evidence row carries a named device and a civil date, and a stale date fails
- [ ] Captions and Audio Descriptions are undeclared, each with its reason, and the voice-note design constraint appears verbatim
- [ ] the seven common tasks are `10 §1.1`'s seven, and every declared feature is recorded against all seven
- [ ] `10 §7.2` rows 1–10 are recorded green on all fourteen variants, on two named physical devices, dated
- [ ] row 11 (glove / freezer bag) is recorded as an input to the design and does **not** gate this merge
- [ ] no VPAT and no EN 301 549 claim appears anywhere under `docs/store/`
- [ ] `10 §7.1`'s Evidence column points at the declaration file rather than duplicating it
- [ ] the civil-date case exists and is tagged `uk-zone`

## 8. Verification

```bash
fvm flutter test test/policy/accessibility_label_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

Prove the claim → evidence walk can fail, reverting each:

```bash
# 1. Declare a tenth feature with an empty evidence cell.
fvm flutter test test/policy/accessibility_label_test.dart   # expect: 'declared with no evidence'
# 2. Rename one referenced test by one character.
fvm flutter test test/policy/accessibility_label_test.dart   # expect: 'it was renamed and the claim is now unheld'
# 3. Blank one manual row's date.
fvm flutter test test/policy/accessibility_label_test.dart   # expect: the manual-date assertion
git checkout -- docs/store/ test/design/
```

```bash
grep -rn "VPAT\|EN 301 549" docs/store/     # expect zero
grep -rn "Captions" docs/store/accessibility-nutrition-label.md   # expect the undeclared row and its reason
```

The manual half, on the two phones, in a dark room:

```bash
fvm flutter run --release -d <iphone>      # rows 1-10, fourteen variants, both handednesses
fvm flutter run --release -d <android>     # then the same, TalkBack instead of VoiceOver
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(policy): the Accessibility Nutrition Label and its sweep`

# N20-T02 — The withdrawal entry control — `YOUR ENTRY`, no default, no placeholder

| | |
|---|---|
| **Epic** | [N20 — Treatments and withdrawal](epic.md) · `00-README` §9 step 7 |
| **Task** | 2 of 7 |
| **Depends on** | N20-T01 · N05-T01 |
| **Commit** | one commit · `feat(treatments): the withdrawal control with no default and no placeholder` |

## 1. Why this task exists

The control that spec §12.1 exists for: no default, no placeholder, no prefill, no
suggestion, no *typical value*, with the caveat **above** it — the user reads the number off the bottle
and the app stores what they typed, labelled *as entered by you*.

It is also the screen this epic hangs on. The Treatments screen, its route, its write controller and
its three-choice control all land here, because there is nothing to render in T03 and nothing to
repeat in T04 until a shepherd can put a treatment into the database through a screen. The control
itself is eleven lines of composition over `ShedFieldRow` and `ShedKeypad`; the difficulty is
everything the control must refuse to do.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§10.2** (the safety-critical control: three explicit 72 pt choices, *"no pre-filled number and no pre-selected option"*, the one-to-one map onto the sealed type, the confirm key's wording, and `Disclaimers.withdrawalCaveat` permanently above), §10.4 (what a new treatment costs), §1.4 (the state vocabulary), §15.5 (there is no draft state, so *Cancel* is not a verb, and no ARB key begins `save`) | what the control is and what it may not be |
| `docs/design/indelible.md` | **§7.12** (the text field: a 64 px line, label above, rule below, the four states, and *"there is never placeholder text inside a field"* — with the withdrawal cell named as the reason), **§7.7** (boxed = a state of the animal, unboxed = a note about the record, with `YOUR ENTRY` in the unboxed list), §8 screen 8 (the entry cells and the blank days cell under a dotted rule), §7.13 (the word button), §7.14 (the bottom sheet is the only overlay), §9 safety rule 1 | every word and every mark on this control |
| `docs/engineering/05-domain-correctness.md` | **§3.2** (the sealed type, its private generative constructor and its one factory; and the milkings rule — a label stating only milkings is `WithdrawalNotRecorded` with the number typed into the **note**), **§3.9** gate 2 (the widget test that is half of the §12.1 proof), §3.10 path 2 (**no learned default, ever**) | the three choices, and the two things the control must never grow |
| `docs/engineering/CONVENTIONS.md` | **§2.7** (`WithdrawalDays.asEnteredByUser`, `WithdrawalNotApplicable`, `WithdrawalNotRecorded`), §2.11 (`ShedKeypad`, `ShedTapTarget`, `SaveReceipt`), §2.14 (`Disclaimers`), §3.4 (`treatmentsControllerProvider`, `treatmentWriteControllerProvider`), §4.4 (controller rules — **rule 4: what the user typed lives in a private field on the notifier**), §4.5 + R59 (widget keys), §5.3 (the banned words), R70 (`ShedKeypad` is shared) | every name, key and word |
| `docs/engineering/06-design-system.md` | §12 (`ShedFieldRow` ≥ `tapMin`, label **above** value; `ShedKeypad` 3 × 4 with cells ≥ `tapPrimary`; `ShedConfirmBar` labelled **with the outcome**), **§8.1** (decision #57: the in-app keypad is the only numeric entry route, and why the system keyboard is a white-flash vector), §6.1 (the target sizes) | the components this composes and may not re-invent |
| `docs/engineering/02-state-di-navigation.md` | §7 (`WriteController.guard()` and the double-tap defence), §7.1 (the four rules), §8.1–§8.2 (`RouteNames.treatments` is already declared; this task adds the push helper) | the write path and the route |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.2 (label rules), §3.4 (headings), §4 (the Treatments screen title and its two modes), §8.4–§8.5 (ARB, `description` on every message, and the terminology placeholder), §5.2 (`NOT RECORDED` — never `0`, never blank) | every string this task authors |
| `docs/engineering/12-testing.md` | **§10.3** (the published policy file, its three tests and its two private helpers `openNewTreatment` / `enterWithdrawal`), §5 (`pumpApp`, and why screen-driving helpers stay private to the file that uses them) | the tests, and where their helpers live |
| `docs/engineering/CODE-REVIEW-CHECKLIST.md` | **§2.2** (`hintText: '28'` — *"a hint at 3am is a value"*; the learned-default shape; and the migration shape) | the three things that pass CI and are still wrong |
| `docs/skills/02-build-manifest.md` | §4.1 (**P2** — no SnackBar; the receipt is the committed row), §4.4 defect 2 (the 18 px floor and the stamp exemption test) | why there is no floating confirmation, and what keeps `YOUR ENTRY` legal at 14 px |
| `shed-book-spec.md` | §7.5, §12.1 | the sentence this control exists to satisfy |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-withdrawal` | the control, its label and its caveat are its subject |
| `shed-safety-rules` | this is §12.1's most visible surface |

The pixels of the field itself are `indelible-controls`', and they are already spent: N10-T06 shipped
`ShedFieldRow` with **no parameter capable of carrying a placeholder or a default**. This task
composes that component; it does not re-open it.

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/treatments_test.dart`
- **Test** — `'the withdrawal field renders no placeholder, no prefill and no default'`
- **Assertion, spelled out** — pump the screen, call the private helper `openNewTreatment(tester)`, then
  assert on **rendered text**, not on a widget's private state (`12 §10.3`): collect every `Text`
  descendant of `find.byKey(const Key('treatment.withdrawal.enter_days'))` and assert none of them
  matches `RegExp(r'\d')`. Then assert the other half, which the published test does not:
  **none of the three choices is selected** — `find.byWidgetPredicate` over `ShedTapTarget` in the
  control's subtree returns three widgets and zero with `selected: true`. A control that pre-selects
  *Not recorded* is as wrong as one that pre-fills `28`, because it makes a decision the shepherd did
  not make.
- **Why it is red today** — nothing enters a withdrawal period, and every form library's default behaviour is a placeholder.

```bash
fvm flutter test test/features/treatments_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the control over `ShedFieldRow` and `ShedKeypad`, with the caveat rendered above it from
`Disclaimers`.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 steps 5, 6 and 7. **Steps 1–4 are skipped and the commit message says so**: the schema
is N07's, the sealed type is N05-T01's, the repository and its provider are T01's. The only new
provider here is the screen's own write controller, which lives in the feature folder, not in
`lib/data/providers.dart`.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `lib/features/treatments/treatment_write_controller.dart` | **new** | `TreatmentWriteController extends WriteController`, reached through `treatmentWriteControllerProvider` (`NotifierProvider.autoDispose`, always). Holds the typed fields in **private fields** (§4.4 rule 4) and commits through `guard()` |
| 2 | `lib/features/treatments/treatments_controller.dart` | **new** | `TreatmentsController` + `treatmentsControllerProvider` — screen state only: which mode is showing, which entry sheet is open. **No data.** `treatmentsProvider` joins this file in T06 |
| 3 | `lib/features/treatments/widgets/withdrawal_control.dart` | **new** | The three choices, the keypad route and the caveat. A widget that appears on exactly one screen stays in that feature's `widgets/` (06 §3.1) |
| 4 | `lib/features/treatments/treatments_screen.dart` | **new** | `TreatmentsScreen` — the page, its `headingLevel: 1` title, the entry cells, and the corner slab reading `+ DOSE` (Indelible §7.1) |
| 5 | `lib/routing/routes.dart` | edit | `Routes.treatments(BuildContext)` — the push helper. `RouteNames.treatments` already exists (02 §8.1); this adds the twelfth of the twelve helpers |
| 6 | `lib/l10n/app_en.arb` | edit | every string in §5.3 item 6, each with a `description`. **Not** the three `Disclaimers` strings — those never go near the ARB (05 §7.4) |
| 7 | `docs/engineering/07-screens.md` §10 | edit | record the widget keys and the ARB keys this commit creates. 07 owns screen keys (R59); a key created in code and not recorded there is a test contract nobody can find |
| 8 | `test/features/treatments_test.dart` | **new** | the anchor plus the cases in §5.4 |
| 9 | `test/policy/withdrawal_has_no_default_test.dart` | edit | gate 2's widget half — the third test in `12 §10.3`, plus its two private helpers |

### 5.2 The signatures

```dart
// lib/features/treatments/widgets/withdrawal_control.dart
// 07 §10.2: three explicit choices, one per constructor of the sealed type,
// and NOTHING selected until the shepherd chooses.
class WithdrawalControl extends ConsumerWidget {
  const WithdrawalControl({
    super.key,
    required this.target,
    required this.period,          // null == nothing chosen yet. NOT WithdrawalNotRecorded.
    required this.onChanged,
  });

  final WithdrawalTarget target;
  final WithdrawalPeriod? period;
  final ValueChanged<WithdrawalPeriod> onChanged;
}
```

```dart
// lib/features/treatments/treatment_write_controller.dart — CONVENTIONS §4.4, §2.4.
final class TreatmentWriteController extends WriteController {
  @override
  WriteState build() => const WriteIdle();

  // §4.4 rule 4: what the shepherd typed lives in a private field, not only in
  // `state`. None of these is a draft, none is persisted, and none is named one.
  String _productName = '';
  String? _doseText;
  String? _route;
  String? _batchNo;
  String? _note;
  final Map<WithdrawalTarget, WithdrawalPeriod> _withdrawals = {};

  void chooseWithdrawal(WithdrawalTarget target, WithdrawalPeriod period) =>
      _withdrawals[target] = period;

  /// The one committing call. `guard()` refuses a concurrent second invocation,
  /// which is the double-tap defence for cold, wet fingers (decision #22).
  Future<void> record({EweId? ewe, LambId? lamb}) => guard(() =>
      _repo.recordTreatment(
        ewe: ewe,
        lamb: lamb,
        productName: _productName,
        doseText: _doseText,
        route: _route,
        batchNo: _batchNo,
        note: _note,
        withdrawals: _withdrawals.values.toList(growable: false),
      ));
}
```

The three choices map one-to-one onto the sealed type, and the mapping is the whole control:

```dart
// Enter days  -> opens ShedKeypad, empty; on confirm:
WithdrawalDays.asEnteredByUser(days: typed, target: target)
// Not applicable ->
WithdrawalNotApplicable(target)
// Not recorded  ->
const WithdrawalNotRecorded()
```

Widget keys, recorded in `07-screens.md` §10 in this commit
(`<screen>.<element>[.<qualifier>]`, every segment `lower_snake`, R59):

| Key | What it is |
|---|---|
| `treatment.withdrawal.enter_days` | the *Enter days* choice — **already published** in `CONVENTIONS` §4.5 and read by `12 §10.3` |
| `treatment.withdrawal.not_applicable` | the second choice |
| `treatment.withdrawal.not_recorded` | the third choice |
| `treatment.withdrawal.keypad` | the keypad sheet opened by the first choice |
| `treatment.commit` | the committing control. **Not `treatment.save`** — see §5.3 item 5 |
| `treatments.new_dose` | the corner slab, `+ DOSE` |

### 5.3 The details that are easy to get wrong

1. **Nothing is pre-selected, and *nothing chosen* is not `WithdrawalNotRecorded`.** The control's
   `period` is nullable at first paint precisely so the two states are distinguishable on screen: an
   untouched control and a control on which the shepherd deliberately chose *Not recorded* commit the
   same rows (none), but they are not the same act, and a pre-selected third choice claims a decision
   nobody made. 07 §10.2: *"no pre-filled number **and no pre-selected option**."*
2. **The treatment row is not created on screen entry, and this is the one screen where that is
   correct.** Everywhere else the row is created on entry (`00-README` §2.4, decision #11). Here it
   cannot be: a treatment row with no `treatment_withdrawals` child is, by construction, a completed
   medicine record whose withdrawal was *not recorded* — it would appear in the medicine book and in
   `treatments.csv` the instant the screen opened. So the fields live in private fields on the write
   controller (§4.4 rule 4) and one `guard()`ed call commits the lot. **The banned words still bind**:
   no identifier called `draft`, no `isDirty`, no `Save` button and no ARB key beginning `save`
   (07 §15.5); the committing control is labelled with the **outcome**, the way `ShedConfirmBar`
   requires — *"Record Alamycin LA for 412"*, never *"Save"*. If a reviewer reads §2.4 as requiring a
   `beginTreatment` verb, that is a third throwing verb and a change to R32: route it to the owner
   rather than inventing it here.
3. **`hintText` is the whole failure mode, and it is not reachable through `ShedFieldRow`.** N10-T06
   shipped the component with no such parameter, which is §12.1 held at *unrepresentable* at the
   component layer. The way it comes back is a bare `TextField` or `TextFormField` dropped onto this
   screen because the keypad felt like extra work. Grep the diff for both, and remember 06 §8.1: the
   system keyboard is also a white-flash vector on a dark-only app, so the in-app keypad is not a
   preference.
4. **No learned default, ever** (05 §3.10 path 2). No *"you usually enter 28 for this product"*, no
   allowlist, no confidence threshold, no *"we noticed…"* row. That is a medicines lookup table the
   user built by accident, and it fails silently on the one bottle that changed. The widget test for
   it is in §5.4 and it is not optional — it is named in the source document.
5. **`treatment.save` must not be created.** `05` §3.9's gate-2 snippet taps
   `Key('treatment.save')` and R59 lists `treatment.save` among the published spellings; both predate
   the no-Save rule. `save` is a banned word (`CONVENTIONS` §5.3), `db.save_verb` is a gate row, and
   07 §15.5 fails the build on an ARB key beginning `save`. The key is `treatment.commit`, recorded in
   `07-screens.md` §10 in this commit.
6. **The caveat is what keeps `YOUR ENTRY` legal below the 18 px floor.** Indelible sets `--t-stamp`
   at 14 px, and build-manifest §4.4 defect 2 permits the exemption only where *"no stamp is ever the
   sole carrier of its meaning"*. `YOUR ENTRY` is not the sole carrier **because
   `Disclaimers.withdrawalCaveat` sits permanently above the control** and the field label spells the
   instruction in full. Delete the caveat to save vertical space and the stamp loses its exemption and
   must be re-set at 18 px. They are one decision, not two.
7. **`YOUR ENTRY` is an unboxed stamp, and Indelible says both things.** §7.7 states the rule with its
   reason — boxed means a state of the animal, unboxed means a note about the record — and lists
   `YOUR ENTRY` among the unboxed. §7.12's state table and §8 screen 8 both call it boxed. Ship it
   **unboxed**, because §7.7 is the component contract and the two others are usage sites; name the
   contradiction in the PR body so the owner can rule it either way. It is a 2 px border in one file.
8. **The caveat, the provenance label and the footer are *referenced*, never re-typed.**
   `Disclaimers.withdrawalCaveat` above the control, `Disclaimers.withdrawalProvenance` on the confirm
   key. They are `const` strings in `lib/domain/policy/disclaimers.dart` and they never enter the ARB
   — a translator can soften or drop an ARB string and the app has no mechanism to notice (05 §7.4).
   `copy.disclaimer_retyped` is a gate row and `disclaimer_is_defined_once_test.dart` counts literals.
9. **A milkings-only label is `WithdrawalNotRecorded`, and the number goes in the note.** 05 §3.2:
   `WithdrawalDays` cannot hold *"6 milkings"* and must never be used to. The control offers no
   conversion, no calculator and no hint; the note field is where the shepherd writes what the bottle
   said, verbatim. `WithdrawalMilkings` does not exist in v1.
10. **Which targets the control offers is N00-T04's ruling, not this task's.** `WithdrawalTarget.milk`
    is in the v1 schema and in the sealed type either way. Read the ruling in the decision record
    before deciding whether the screen renders one `WithdrawalControl` or two; do not infer it from
    the schema, and do not let *"the CHECK allows milk"* become a second field nobody ruled on.
11. **There is no floating confirmation.** P2: `showSnackBar(` is banned everywhere, including in
    `feedback.dart`. The receipt **is the committed row**, printed in ink one line above the one being
    written. `confirmSaved` is the printed-receipt channel, not an overlay, and `ShedBottomSheet` is
    the only overlay in the app (N10-T07; `showModalBottomSheet(` appears nowhere else).
12. **Every string is an ARB message with a `description`, and no domain noun is a literal.** The
    animal noun comes from `terminologyProvider` as a placeholder (10 §8.5) — a shepherd who renamed
    *ewe* to *gimmer* sees *gimmer* here too. There is no later sweep: N33 verifies, it does not
    author.
13. **Nothing in this task is time-shaped.** The control writes no instant; the write it drives is
    T01's and its `uk-zone` cases already cover the ambiguous hour. Do not add a `Clock.fixed` wrapper
    to this widget test — `12 §2.2` is explicit that it freezes `now()` and silently measures zero.

### 5.4 The full test set

**`test/features/treatments_test.dart`** — new.

| Case | What it pins |
|---|---|
| `'the withdrawal field renders no placeholder, no prefill and no default'` | **the anchor.** No digit in the field's rendered text; none of the three choices selected |
| `'the three choices map one to one onto WithdrawalPeriod and commit the row each one means'` | *Enter days* → one `days` row; *Not applicable* → one `not_applicable` row; *Not recorded* → **no row** |
| `'choosing Enter days opens the in-app keypad with an empty value and no system keyboard'` | `ShedKeypad` present, `EditableText` absent, no `TextField` anywhere in the subtree |
| `'the confirm key states the number and its provenance, referenced from Disclaimers'` | `find.textContaining(Disclaimers.withdrawalProvenance)` — never the literal string |
| `'typing 0 commits days = 0 and the control shows it as a value, not as blank'` | `0` is a real label value |
| `'Disclaimers.withdrawalCaveat renders above the control and appears exactly once in the tree'` | referenced, not re-typed, and permanently visible rather than behind a tap |
| `'a second treatment of an identical product still commits with no withdrawal row'` | 05 §3.10 path 2 — the no-learned-default test the source document names |
| `'the control carries no Save affordance and no ARB key beginning save'` | 07 §15.5, asserted over the rendered semantics labels and the ARB map |
| `'every choice is at least 72 by 72 at textScaler 2.0 with boldText'` | 07 §10.2's 72 pt, above the 60 pt floor, at the scale where a `Row` clips |
| `'the screen carries exactly one headingLevel 1 node'` | 10 §3.4, enrolling the screen in N33's sweep |
| `'a double-fired commit records exactly one treatment'` | decision #22 — `tester.tap(); tester.tap();` through `guard()` |

**`test/policy/withdrawal_has_no_default_test.dart`** — extended with gate 2's widget half.

| Case | What it pins |
|---|---|
| `'an untouched withdrawal control commits no withdrawal row'` | `05` §3.9 gate 2. The published name spells it *"saves as not recorded"*; `saves` is a banned word (`CONVENTIONS` §5.3) and the property is identical — `12` owns the file, so the corrected name ships and the reason goes in the commit message |
| `'the entry control is empty, and the committing control carries no number until one is typed'` | `12 §10.3`'s third test, with its two private helpers `openNewTreatment` and `enterWithdrawal` kept **in this file** (`12 §5`: a shared tap sequence quietly stops being the thing the budget is counting) |

## 6. Constraints that bind this task

- **§12.1, held at *unconstructible* — at the widget level, which is where a shepherd meets it.** `ShedFieldRow` shipped in N10-T06 with **no parameter capable of carrying a placeholder, a default or a suggestion**, so this control cannot express one even by accident. Do not add one, and do not reach past it to a raw `TextField`. The caveat renders **above** the field, where a thumb does not cover it, and *no entry* stays distinct from *not applicable* all the way to the column.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider. The three choices are 72 pt (07 §10.2), not 60.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **P2 — there is no SnackBar.** The receipt is the committed row; `showSnackBar(` appears nowhere, and `test/policy/no_snackbar_test.dart` (N14-T04) already holds it.

## 7. Definition of Done

- [ ] `'the withdrawal field renders no placeholder, no prefill and no default'` passes, and was seen to fail first for the stated reason
- [ ] no placeholder, no prefill, no default, no suggestion
- [ ] the caveat is referenced from `Disclaimers`, never re-typed
- [ ] the stored value is labelled *as entered by you* wherever it is rendered
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] no `TextField`, `TextFormField` or `hintText` appears anywhere under `lib/features/treatments/`
- [ ] none of the three choices is selected at first paint, and *nothing chosen* is distinguishable on screen from *not recorded*
- [ ] every new widget key and every new ARB message is recorded in `07-screens.md` §10 in this commit

## 8. Verification

```bash
fvm flutter test test/features/treatments_test.dart
fvm flutter test test/policy/withdrawal_has_no_default_test.dart
fvm flutter test test/policy/no_snackbar_test.dart
fvm flutter test test/policy/disclaimer_is_defined_once_test.dart
grep -rn "hintText\|TextField\|TextFormField\|EditableText" lib/features/treatments/
grep -rn "draft\|isDirty\|save" lib/features/treatments/ lib/l10n/app_en.arb
grep -rn "as entered by you\|statutory medicine" lib/features/ lib/l10n/
dart run tool/check_policy.dart
make check
make test
```

The first grep is §12.1 at the component layer and must print nothing. The second is the vocabulary
gate — a hit in the ARB is a `save`-prefixed key, which 07 §15.5 fails the build on. The third must
print nothing: a `Disclaimers` string appearing as a literal outside
`lib/domain/policy/disclaimers.dart` is `copy.disclaimer_retyped`, and it is the failure this screen
is most likely to produce because it carries three of the five disclosures.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(treatments): the withdrawal control with no default and no placeholder`

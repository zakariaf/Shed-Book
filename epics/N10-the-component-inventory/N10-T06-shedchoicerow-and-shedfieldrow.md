# N10-T06 — `ShedChoiceRow` and `ShedFieldRow`

| | |
|---|---|
| **Epic** | [N10 — The component inventory](epic.md) · `00-README` §9 step 4 (2 of 3) |
| **Task** | 6 of 8 |
| **Depends on** | N10-T05 |
| **Commit** | one commit · `feat(ui): ShedChoiceRow (ease only) and ShedFieldRow with no placeholder` |

## 1. Why this task exists

`ShedChoiceRow` survives **for lambing ease 1–5 only** — P8 abolished the birth-type
chooser and this component is the last legitimate segmented control in the product. `ShedFieldRow` puts
the label **above** the value and never a placeholder inside a field, because a placeholder that looks
like a value is how a withdrawal period acquires a default by accident.

Indelible states the second half as a system rule rather than a screen rule, which is why it belongs
here and not in N20: *"the text-field component forbids placeholder text system-wide (§7.12) so this
cannot regress by accident"* (§9, safety rule 1). The strongest available form of that is an API with
**no parameter capable of carrying a placeholder or a default** — unrepresentable rather than
documented.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/design/indelible.md` | §7.9 (**segmented choice** — five 64 × 64 buttons, 8 px gaps, `64 × 5 + 8 × 4 = 352`, the selected underline, and the group's *unset* state; **and the paragraph that abolishes the birth-type chooser: "Safety rule 4, as geometry"**) · §7.12 (**the text field** — a 64 px line, label above, rule below, the four states, and *"there is never placeholder text inside a field"*) · §7.8 (tapping a value opens the keypad sheet) · §9 safety rule 1 (the component-level forbid) | every value and both refusals |
| `docs/engineering/06-design-system.md` | §12 (`ShedChoiceRow`: n × `tapPrimary`, **`Wrap`, not `Row`**, states default/pressed/selected; `ShedFieldRow`: ≥ `tapMin` tall, states default/pressed/**empty**, *label above value so it survives 200%*) · §8.1 (decision #57: the in-app keypad is the only numeric entry route, and why the system keyboard is a white-flash vector) · §3.5 (`gesture.slider`) | the size contracts and the entry route |
| `docs/engineering/07-screens.md` | §10.2 (**the safety-critical control** — three explicit 72 pt choices, *"no pre-filled number and no pre-selected option"*, and `Disclaimers.withdrawalCaveat` above it permanently) · §6.4 (ease on Lambing Entry) | what the field row is used for at its highest stakes |
| `docs/engineering/CONVENTIONS.md` | **R44** (`LambingEase` carries an **ordinal, not descriptions**; the five labels are `vocab_terms` rows + ARB, resolved at the presentation edge) · §2.7 (`WithdrawalDays.asEnteredByUser` — a private generative constructor) · §4.5 + **R59** (the widget-key format, and the published example P8 invalidated) · §1.1 layer rule 7 | the types, the names and one stale example |
| `docs/engineering/00-README.md` | §2.3 (**the five safety rules and the mechanism hierarchy**) · §10 rule 5 (a rule that drops to *documented* has been deleted) | the level this task must hold §12.1 at |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-controls` | the choice row and the field row are its subject |
| `shed-safety-rules` | no placeholder inside a field is §12.1 expressed as a component rule |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/components_test.dart`
- **Test** — `'ShedFieldRow renders no placeholder inside the field and ShedChoiceRow is documented as ease-only'`
- **Why it is red today** — no field row exists, so the first form would use a `TextField` with a hint.

```bash
fvm flutter test test/design/components_test.dart   # expect: failing, for the reason above
```

Sharpen the first half from *renders none* to *cannot express one*, which is a whole level up
`00-README` §2.3's hierarchy:

```dart
// (a) behavioural — the unset field paints a dotted rule and no glyph
await _pumpComponent(tester, const ShedFieldRow(label: 'DAYS', value: null, /* … */));
expect(find.descendant(of: find.byType(ShedFieldRow), matching: find.byType(Text)),
       findsOneWidget);                                    // the label, and nothing else

// (b) structural — the API has nowhere to put one
final String src = File('lib/core/ui/components/shed_field_row.dart').readAsStringSync();
for (final banned in ['hintText', 'placeholder', 'initialValue', 'defaultValue', 'InputDecoration']) {
  expect(src.contains(banned), isFalse, reason: '$banned is a way to default a withdrawal period');
}
```

The second half asserts the doc comment names P8 **and** that no member of the component's API can
carry a birth type — the enum it takes is `LambingEase`-shaped, not `BirthType`-shaped.

**Green.** The minimum code that passes, and nothing beyond it — both widgets; the choice row's doc comment names P8 and says what it may not be used
for.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**UI and tests only.** No schema, no domain, no data, no wiring, no controller, no ARB entry — the
ease descriptions are `vocab_terms` rows resolved to ARB messages at the presentation edge (R44), and
`Disclaimers.withdrawalCaveat` is *referenced by the screen*, never re-typed here
(`copy.disclaimer_retyped`). Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/components/shed_choice_row.dart` | **New.** The last segmented control in the product. Its doc comment is load-bearing: it names P8, states that the component may not be used for birth type or death cause, and points at Indelible §7.9's paragraph |
| 2 | `lib/core/ui/components/shed_field_row.dart` | **New.** Label above, value on a rule, dotted rule when unset. The API is the safety mechanism |
| 3 | `test/design/components_test.dart` | **Extend.** The two structural cases, the unset-group case, the 200% case, and the `Wrap`-not-`Row` case |

### 5.2 The signatures

```dart
// lib/core/ui/components/shed_choice_row.dart

/// EASE 1–5 ONLY.
///
/// P8 (`CLAUDE.md`) abolished the birth-type chooser: birth type is derived
/// from the tally strokes and printed `(COUNTED)`, which is what makes safety
/// rule §12.4 structural instead of procedural. indelible.md §7.9: "there is
/// no segmented control, because there is no choice. This is the signature of
/// the direction and it must not be softened."
///
/// This component MAY NOT be used for birth type. It may not be used for death
/// cause either — that is a vocabulary list of arbitrary length and belongs in
/// a sheet, not in a five-cell Wrap.
final class ShedChoiceRow extends StatelessWidget {
  const ShedChoiceRow({
    super.key,
    required this.choices,       // exactly the five ease ordinals
    required this.selected,      // null == the group's unset state
    required this.onSelected,
    required this.unsetLabel,    // 'EASE — NOT RECORDED · SKIPPABLE'
    required this.groupSemanticLabel,
  });

  /// `(ordinal, label, semanticLabel)`. The label is the ARB message behind a
  /// `vocab_terms` row `ease_1`…`ease_5` (R44): `LambingEase` carries an
  /// ordinal and nothing else, and a domain file cannot hold ARB text.
  final List<({int ordinal, String label, String semanticLabel})> choices;

  final int? selected;
  final ValueChanged<int> onSelected;
  final String unsetLabel, groupSemanticLabel;
}
```

```dart
// lib/core/ui/components/shed_field_row.dart

/// A 64 px line: label above, value on a 2 px rule, dotted rule when unset.
///
/// There is deliberately NO hintText, NO placeholder, NO initialValue and NO
/// InputDecoration on this API. indelible.md §9 safety rule 1: "the text-field
/// component forbids placeholder text system-wide so this cannot regress by
/// accident." A placeholder in the withdrawal-days field is a food-chain risk
/// (spec §12.1), and in the dark a grey placeholder is indistinguishable from
/// an entered value.
///
/// It is also not a TextField. Decision #57 makes ShedKeypad the only numeric
/// entry route; `onTap` opens whatever surface the screen chooses.
final class ShedFieldRow extends StatelessWidget {
  const ShedFieldRow({
    super.key,
    required this.label,          // ALWAYS above the value, never inside it
    required this.value,          // null == unset == the dotted rule
    required this.onTap,
    required this.semanticLabel,
    this.stamp,                   // e.g. ShedStamp.yourEntry on the days field
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final String semanticLabel;
  final ShedStamp? stamp;
}
```

### 5.3 The details that are easy to get wrong

- **The unset field is a visible gap, not an empty string.** Indelible §7.12: a 2 px **dotted** rule
  (`--rule-dot`, `2px 6px`) and **no glyph**. Rendering `''`, `-`, `—` or a zero-width space all read
  as "there is a value here and it is blank", which is the opposite fact. §7.3's unset cell says it
  again: *"a visible gap, never a hidden field. The record is honest about its own thinness."*
- **`value: ''` and `value: null` must not behave the same.** Guard it: an empty non-null string is a
  caller bug, and an `assert(value == null || value!.isNotEmpty)` is what turns it into a test failure
  instead of a field that silently looks unset.
- **The label is above, and that is a 200 % requirement, not a taste.** `06 §12`: *"label **above**
  value, so it survives 200%."* A leading-label row at textScaler 2.0 leaves the value about 90 px of
  a 375 px device, and `FittedBox` is gated (`type.fitted_box`) so there is no way to shrink out of it.
  The overflow matrix (252 cells, N33-T01) is where this would otherwise be discovered, twelve screens
  late.
- **`Wrap`, not `Row`.** `06 §12` says so in four words and the reason is the same 200 %: five 64 px
  cells with 8 px gaps come to 352 px inside Indelible's 361 px record column at scale 1.0, and at 2.0
  they do not. A `Row` overflows; a `Wrap` reflows to two lines and the group keeps working. Use
  `Wrap(spacing: t.gapMin, runSpacing: t.gapMin)`.
- **The unset state belongs to the *group*, not to a sixth cell.** Indelible §7.9: *"all five
  unselected and a 2 px dotted `--rule` under the whole group labelled `EASE — NOT RECORDED ·
  SKIPPABLE`."* A "not recorded" sixth button would be a sixth target, would change the ease list's
  arithmetic, and would make *not recorded* selectable — which is a different fact from *not selected*.
- **`LambingEase` has no descriptions and never will (R44).** Indelible §7.9's selected state prints
  `EASE 3 · SOME ASSISTANCE`, and that string is **not** on the domain type: `extension type const
  LambingEase(int code)` validates 1..5 and holds nothing else, because a domain file cannot hold ARB
  text (layer rule 1 bans `intl` and `AppLocalizations`). The five labels come from `vocab_terms`
  rows `ease_1`…`ease_5` through the ARB, resolved at the presentation edge — so they arrive here as
  strings in `choices`.
- **`CONVENTIONS §4.5` still publishes `lambing_entry.birth_type.twin` as its worked key example, and
  R59 still blesses it.** That is an artefact P8 invalidated, and `00-PLAN-CRITIQUE.md` assigns the
  fix to **N16-T02a**, not to this task. Do not fix it here and do not copy it: no key, no parameter,
  no doc comment and no test in this commit may contain `birth_type`.
- **No `Slider`, no `CupertinoPicker`, no `showDatePicker(`, no `showTimePicker(`.**
  `gesture.slider` and `a11y.material_picker` fail the build on all four — *"the dial is a drag, the
  keyboard mode is the system IME, and the cells are under 60 pt"*. The replacement for a value is the
  keypad; the replacement for a range of five is this component.
- **`ShedFieldRow` is not the withdrawal control, and must not become it.** `07 §10.2`'s control is
  three explicit 72 pt choices — `[ Enter days ] [ Not applicable ] [ Not recorded ]` — mapping
  one-to-one onto the sealed `WithdrawalPeriod`, with no pre-selected option. That composition is
  N20-T02's. This task supplies the field row it uses for the days value and, critically, supplies it
  with **no way to prefill**.
- **The focused state has no glow, no fill and no colour change.** §7.12: the rule goes 2 px solid at
  full ink and a 2 px caret appears. Material's default focus decoration does all three of the banned
  things, which is one more reason this component is not an `InputDecorator`.
- **The standing epic traps apply.** No `colorScheme`; no constructed `TextStyle`; token before
  literal; `ShedTapTarget` under every cell and under the value, or the N33 sweeps cannot see them;
  `onTap` non-nullable — Indelible §7.12's disabled row reads simply **"Never."**

### 5.4 The full test set

`test/design/components_test.dart`, extended.

| Case | What it asserts |
|---|---|
| `'ShedFieldRow renders no placeholder inside the field and ShedChoiceRow is documented as ease-only'` | **The anchor**, in both halves: the unset row renders the label and nothing else; the source of `shed_field_row.dart` contains none of `hintText`, `placeholder`, `initialValue`, `defaultValue`, `InputDecoration` |
| `'ShedFieldRow has no API surface that could carry a default'` | The constructor's parameter list, read from source. §12.1 held at *unconstructible*, not at *documented* |
| `'an unset ShedFieldRow paints a dotted rule and no value glyph'` | The dash pattern is present; no second `Text` |
| `'value: empty string is refused'` | The assert fires. `''` and `null` are different facts |
| `'the label sits above the value at textScale 1.0, 1.3 and 2.0'` | The label's rect is strictly above the value's in all three, and there is no overflow |
| `'ShedFieldRow is at least tapMin tall and is one ShedTapTarget'` | 60 floor, 64 in practice; one target; `semanticLabel` non-empty |
| `'ShedChoiceRow lays out five cells of tapPrimary in a Wrap'` | Five rects, each ≥ 72; `find.byType(Wrap)` present; `find.byType(Row)` absent as the group's direct layout |
| `'ShedChoiceRow reflows to two lines at textScale 2.0 without overflow'` | The `Wrap` earning its keep. No `RenderFlex` exception |
| `'the unset group renders one dotted rule and one label, not a sixth cell'` | Five targets, not six; the unset label present |
| `'a selected cell differs from an unselected one with colour removed'` | The 2 px underline and the border weight. Decision #106 |
| `'selecting a cell reports its ordinal once'` | `onSelected` fires with 3, exactly once, for one tap |
| `'no file in this commit contains birth_type'` | Source text over both files and the test additions. P8, and R59's stale example left alone for N16-T02a |
| `'neither file names Slider, CupertinoPicker, showDatePicker or showTimePicker'` | Source text. `gesture.slider` and `a11y.material_picker` would catch it under `lib/`; the local case names the component |
| `'both components render at textScale 2.0 with boldText with no overflow'` | The epic-wide case, these two components' rows |

**Nothing here is time-shaped.** The field row renders whatever string it is given; a date value
arrives already formatted by `formatters.dart` as `d MMM y` (`11 Mar 2026`) and never all-numeric
(R60). If this component ever formats a date, two rules broke at once.

## 6. Constraints that bind this task

- **§12.1 — never default a medicine withdrawal period.** Held at **unconstructible**: the field row
  has no parameter that can carry a placeholder, a hint, an initial value or a default, and no branch
  that fills one in. `00-README` §2.3's hierarchy is *unrepresentable → unconstructible →
  unpersistable → source test → documented*, and a rule that drops to merely documented has been
  deleted. Both the behavioural case and the source-text case ship in this commit.
- **§12.4 — never silently correct.** P8 is why `ShedChoiceRow` may not be used for birth type: the
  type is derived from the tally strokes and labelled `(COUNTED)`, so *"the most common contradiction
  is structurally impossible rather than caught by validation"* (Indelible §9). Re-admitting a
  birth-type chooser here would demote a structural mechanism to a procedural one.
- **3am** — each choice cell ≥ `tapPrimary` (72) with `gapMin` (16) separation, the field row ≥
  `tapMin` (60) and 64 in practice, 18 px floor, dark only. No slider, no picker, no drag: every value
  is reachable by discrete taps.
- **No ARB entry** — the ease labels come from `vocab_terms` + ARB at the presentation edge (R44), the
  unset label and every semantic label are parameters, and `Disclaimers.withdrawalCaveat` is
  referenced by the screen and never re-typed (`copy.disclaimer_retyped`).
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'ShedFieldRow renders no placeholder inside the field and ShedChoiceRow is documented as ease-only'` passes, and was seen to fail first for the stated reason
- [ ] no `hintText` anywhere in either component
- [ ] the label is above the value in every state
- [ ] the choice row's doc comment names P8
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `ShedFieldRow`'s API contains no `placeholder`, `initialValue`, `defaultValue` or `InputDecoration`, proved by a source-text case
- [ ] `value: ''` is refused; `null` is the only unset
- [ ] the choice row is a `Wrap` and reflows at textScaler 2.0 without overflow
- [ ] the unset state belongs to the group and adds no sixth target
- [ ] the string `birth_type` appears nowhere in this commit

## 8. Verification

```bash
fvm flutter test test/design/components_test.dart
fvm flutter test test/design/
make check
make test
```

```bash
grep -nE "hintText|placeholder|initialValue|defaultValue|InputDecoration" lib/core/ui/components/shed_field_row.dart   # expect zero
grep -rn "birth_type\|BirthType" lib/core/ui/components/                                                               # expect zero
grep -n "P8" lib/core/ui/components/shed_choice_row.dart                                                               # expect one
grep -nE "Slider|CupertinoPicker|showDatePicker|showTimePicker" lib/core/ui/components/                                # expect zero
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): ShedChoiceRow (ease only) and ShedFieldRow with no placeholder`

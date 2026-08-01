# N29-T02 — Units — kg / lb and °C / °F, converted only at the display edge

| | |
|---|---|
| **Epic** | [N29 — Settings](epic.md) · `00-README` §9 step 10 (4 of 4) |
| **Task** | 2 of 8 |
| **Depends on** | N29-T01 |
| **Commit** | one commit · `feat(settings): units at the display edge only` |

## 1. Why this task exists

The setting changes the **display**, never the storage. A shepherd who switches to lb must
see the same weights they entered, not a rounded round trip — which is exactly what happens if a unit
change rewrites stored values.

`05 §5.1` names the bug in full, and it is worth reading before writing a line: *"the user enters
9.5 lb; you store 9.5 with a unit flag; they switch to kg and see 4.309; the edit screen pre-fills 4.3
at 1 dp; they save without touching it; the record is now 4.3 kg = 9.48 lb. **The value drifted because
nobody edited it** — a silent correction with no line of code to blame."* That is safety rule 4
committed by a settings screen, and there is no test anywhere else in the suite that would catch it.

The defence is already built. Canonical mass is integer **grams**; canonical temperature is integer
**milli-°C** (decision #56, measured: 0.1 kg storage would silently rewrite **132 of 241** pound
entries). There is **no `unit` column on any measurement** and a schema test asserts it. `unitsProvider`
has derived `WeightUnit` from `settingsProvider` since N12-T02. What this task adds is the **control**
and the discipline that every rendering site goes through one formatter.

One section, one control. **The °C / °F control does not ship in v1** — see §5.3.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | **§5.1** (the canonical-storage rule and the display-unit round-trip bug) · **§5.2** (`Grams` and `MilliCelsius` in full; `round()`, never `toInt()`; *"never build an extension type for a display unit"*) · §5.3 (the three tests that **are** the specification, including the 132-corruption test) · §5.4 (the keypad is the input; `parseUserNumber` rejects ambiguity) · **§5.2 last paragraph** (*"do not add a temperature column until open question 11 is answered"*) | the canonical units and the display edge |
| `docs/engineering/07-screens.md` | **§14.3 row 1** (Units: kg / lb from `app_settings.weight_unit`; *"**°C / °F ships only if a temperature field ships**" — an unused setting is a 3am tax*) · §14.4 (≤ 2 taps) | which control ships |
| `docs/engineering/03-data-model-and-schema.md` | §5.13 (`weight_unit` `CHECK IN ('kg','lb')`, default `'kg'`; `temperature_unit` `CHECK IN ('c','f')`, default `'c'`) · §4 (time and unit storage) | the columns and their `CHECK`s |
| `docs/engineering/CONVENTIONS.md` | §2.3 (`Grams`, `MilliCelsius`, **`WeightUnit { kg('kg'), lb('lb') }`**, `parseUserNumber`; *"`Pounds` and `Fahrenheit` are banned type names"*) · §3.1 (`unitsProvider : Provider<WeightUnit>`, R68) · §2.11 (`lib/core/ui/formatters.dart` is the only `package:intl` call site outside `lib/data/`) · §4.5 + R59 | **BINDING** on the type, the provider and the key |
| `docs/engineering/10-accessibility-and-i18n.md` | §8.4 rule 4 (**dates and numbers are never formatted inside an ARB message**; pass a pre-formatted `String`) · §8.5 (*"prefer label/value over sentences"* — `Ewes · 132`) · §9.1 (one formatting authority) · §3.2 (the label matches the visible text) | how a unit is rendered and announced |
| `docs/engineering/06-design-system.md` | §12 (`ShedChoiceRow` — `Wrap`, not `Row`; `ShedFieldRow` puts the label **above** the value) · §8 (`ShedKeypad` is the only number-entry route, decision #57) | the control's shape |
| `docs/design/indelible.md` | §8 screen 12 (*"Units `KG / LB` and temperature `°C / °F` as two-word segmented lines"*) · §7.9 (segmented choice: 64 × 64, 8 px gaps, selected carries a `--madder-rule` underline **as well as** a fill change) | the segmented line |
| `docs/research/00-tech-decisions.md` | **#56** (canonical grams and milli-°C, chosen by measurement) · #57 (the in-app keypad) · #106 (colour is never the only channel) · §7.1 **open question 11** (*"where does temperature appear at all?"* — unresolved) | why grams, and why the second control waits |
| `docs/engineering/12-testing.md` | §5.1 (`pumpApp`) · §10 (the product's own promises as tests) | how the anchor is written |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-domain` | the canonical units and the display edge |
| `shed-accessibility-and-copy` | how a unit is rendered and announced |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/settings_test.dart`
- **Test** — `'switching units changes every rendered weight and rewrites no stored row'`
- **Why it is red today** — nothing switches units, and the obvious implementation converts on write.

```bash
fvm flutter test test/features/settings_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it cannot pass by rendering one weight. Write it as a **before/after column
read around a UI action**:

1. Seed a lamb whose `birth_weight_g` is a value that does **not** round-trip cleanly at 1 dp in
   either direction — `Grams(4309)` is the value from `05 §5.1`'s own worked example.
2. Read `SELECT birth_weight_g FROM lambs` and keep the raw `int`.
3. Pump Settings, tap `settings.units.weight.lb`, `pumpAndSettle`.
4. Re-read the same column and assert the `int` is **identical**. Not "close to". Identical.
5. Then pump the Lamb Card and assert the rendered text changed from `4.3 kg` to `9.5 lb` — so the
   test proves both halves: the display moved and the storage did not.

The negative half is the point. A test that only asserts step 5 passes against the implementation that
converts on write, which is the implementation this task exists to prevent.

**Green.** The minimum code that passes, and nothing beyond it — the setting, the display-edge conversion, and a read-back proving storage is
untouched.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Steps 6 (UI), 7 (ARB) and 8 (tests), plus one `lib/core/ui/` edit.** No schema — `weight_unit` and
`temperature_unit` were frozen at N07-T08. No domain — `Grams`, `MilliCelsius`, `WeightUnit` and
`parseUserNumber` all shipped in N04. No data — `SettingsRepository.setWeightUnit` shipped in N12-T02.
**Say all three out loud in the commit message.**

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/formatters.dart` | **Edit.** `formatMass(Grams, WeightUnit)` — the **one** place a canonical gram becomes a displayed number, and already the only `package:intl` call site outside `lib/data/`. Every rendering site calls this; a second `toStringAsFixed(1)` anywhere under `lib/features/` is the defect |
| 2 | `lib/features/settings/widgets/units_section.dart` | **New.** Section 1: the kg / lb segmented line. Two `ShedTapTarget`s in a `Wrap`, `settings.units.weight.kg` / `.lb`, each ≥ 64 × 64 with an 8 px gap |
| 3 | `lib/features/settings/settings_write_controller.dart` | **Edit.** `Future<void> setWeightUnit(WeightUnit unit)` — one `guard()`ed call into the repository verb that already exists |
| 4 | `lib/features/settings/settings_screen.dart` | **Edit.** Slot the section into `SettingsSection.units`, and add the comment naming open question 11 beside it |
| 5 | `lib/l10n/app_en.arb` | **Edit.** `settingsUnitsTitle`, `settingsUnitsWeightKg`, `settingsUnitsWeightLb`, and the semantics label for each. Each with a `description` |
| 6 | `test/features/settings_test.dart` | **Edit.** The anchor and the cases in §5.4, appended to T01's file |

**Every widget that renders a mass is audited in this commit**, but only edited where it is not already
going through `formatMass`. Expect to touch `lamb_card_screen.dart` and the lamb rows under
`lib/features/lambing/widgets/`. **If a mass renders anywhere else, the audit is the deliverable** —
list them in the commit message.

### 5.2 The signatures

```dart
// lib/core/ui/formatters.dart — the ONE display edge for mass.
//
// 05 §5.1: "One canonical unit is stored. Display units are computed at the
// widget boundary and are NEVER assigned to a variable that flows back toward
// the database." The return type is String for exactly that reason: a double
// could be stored; a String cannot be, without somebody noticing.
String formatMass(Grams g, WeightUnit unit) => switch (unit) {
      WeightUnit.kg => '${g.inKilograms.toStringAsFixed(1)} kg',
      WeightUnit.lb => '${g.inPounds.toStringAsFixed(1)} lb',
    };
```

```dart
// lib/features/settings/widgets/units_section.dart
final class UnitsSection extends ConsumerWidget {
  const UnitsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // R68: unitsProvider, not settingsProvider.weightUnit parsed here.
    // One parse site, and it is in providers.dart.
    final WeightUnit unit = ref.watch(unitsProvider);
    …
  }
}
```

```dart
// lib/features/settings/settings_write_controller.dart
/// The verb exists on SettingsRepository since N12-T02. This is the guard.
Future<void> setWeightUnit(WeightUnit unit) => guard(() async {
      final repo = await ref.read(settingsRepositoryProvider.future);
      return repo.setWeightUnit(unit);
    });
```

Widget keys, R59 spelling:

```
settings.units.weight.kg      settings.units.weight.lb
```

There is deliberately no `settings.units.temperature.*` key in this commit. Adding one later is a new
key, not a rename, so nothing breaks.

### 5.3 The details that are easy to get wrong

- **The °C / °F control does not ship, and this is the ruling to record.** `07 §14.3` row 1: *"°C / °F
  **ships only if a temperature field ships** (§7.1 open question 11) — an unused setting is a 3am
  tax."* `05 §5.2`: *"open question 11 is **unresolved** … `MilliCelsius` ships either way and costs
  nothing; **do not add a temperature column until that question is answered**, because an unused
  setting is a 3am tax and an unused column is a migration you did not need."* The column
  `temperature_unit` already exists with a default of `'c'`, so *"shipping the control later is a UI
  change, not a migration"* — which is precisely why it costs nothing to wait. Put that sentence in a
  comment beside the section, and carry open question 11 into the PR body as still open. **The task
  title names both units; the shipped screen shows one.** That is not a scope cut — it is the ruling
  the two documents already made, applied.
- **The DoD line *"temperature and mass are independent settings"* is satisfied at the repository and
  the schema, not at the screen.** Two columns, two `CHECK`s, two verbs — `setWeightUnit` and
  `setTemperatureUnit` — and no single "units" enum that couples them. What must never exist is one
  control, one column or one setting governing both. Assert it as a test; do not render a second
  control to prove it.
- **No `unit` column, ever, on any measurement** (`05 §5.1`). A schema test already asserts it (N07).
  If a section in a later epic wants to record "this weight was entered in lb", the answer is no: the
  canonical value is the record and the display unit is a preference.
- **`round()`, never `toInt()`, never `ceil()`/`floor()`** (`05 §5.2`). `toInt()` truncates toward zero
  and is therefore systematically **light** on every weight in the flock. There is a boundary test at
  `x.5` in `test/domain/` already; do not add a second rounding site here that skips it.
- **`Pounds` and `Fahrenheit` are banned type names** (`CONVENTIONS` §2.3). Both would erase to the
  same runtime type as `Grams` and `MilliCelsius`, *"giving false confidence in any `is`/`switch`/
  serialisation path and inviting somebody to store one."* Pounds exist only as a `double` return from
  a getter, consumed immediately by a formatter.
- **The form controller is seeded from the canonical value each time it opens and never re-derives
  from the old canonical** (`05 §5.1`). This is the half of the round-trip bug that lives outside this
  task's diff, and it is why the audit of every mass-rendering site is part of the commit rather than a
  follow-up.
- **`unitsProvider`, not a parse at the widget** (R68). `WeightUnit.fromKey(value.weightUnit)` happens
  once, in `lib/data/providers.dart`. A second `fromKey` under `lib/features/` is a second answer to
  what `'lb'` means, and it will be the one that is wrong when a restore brings back a value this build
  does not know.
- **Do not format inside an ARB message** (`10 §8.4` rule 4). ARB supports `DateTime` and number
  placeholders with a `format`; this app does not use them, because `Grams` is an extension type over
  `int` and the one formatting site is `formatters.dart`. Pass a pre-formatted `String`. One formatting
  authority, not two.
- **Prefer label/value over a sentence** (`10 §8.5`): `Weight · kg`, not "Weights are shown in
  kilograms." It is the most legible layout at 200% text scale and it dodges grammatical agreement.
- **Colour is never the only channel** (decision #106). The selected segment carries a fill change
  **and** an underline **and** its label sits at full ink while its sibling sits at `--ink-mid`
  (`indelible.md` §7.9). A selected state expressed only as a colour fails `test/design/` and fails a
  shepherd wearing a head torch.
- **The semantics label matches the visible text** (`10 §3.2` rule 3). The control reads `kg`, so the
  label is `kg`, not `kilograms` — Voice Control's "tap kg" must work. State goes in `selected:`, never
  in the label (rule 2).
- **A `CHECK` violation is a `WriteFailed`, never a clamp** — inherited from N12-T02. It cannot fire
  from this control (two buttons, two legal values) and the rule still binds: do not add a fallback arm
  that writes `'kg'` when something unexpected arrives.
- **There is no SnackBar** (P2). The receipt is the segmented line re-printing with the other segment
  selected, and every weight on the next screen reading in the new unit.
- **This section is ≤ 2 taps by construction** — one tap on the screen, no sheet. If it grows a sheet,
  it has grown past `07 §14.4`'s budget for a two-value choice.

### 5.4 The full test set

Appended to `test/features/settings_test.dart`, plus one domain-tier case that belongs beside its
siblings.

| Case | What it asserts |
|---|---|
| `'switching units changes every rendered weight and rewrites no stored row'` | **The anchor.** `birth_weight_g` is byte-identical before and after; the rendered string moves `4.3 kg` → `9.5 lb` |
| `'switching units twice returns the identical stored integer'` | kg → lb → kg. The round trip that a convert-on-write implementation fails on the second hop |
| `'the stored value is unchanged for every weight in a seeded 400-ewe flock'` | Read every `birth_weight_g` into a list, switch, re-read, `expect(after, equals(before))`. One assertion over hundreds of rows — the cheapest possible proof that no bulk `UPDATE` ran |
| `'every widget that renders a mass goes through formatMass'` | Source text under `lib/features/`: no `inKilograms`, no `inPounds`, no `toStringAsFixed` outside `lib/core/ui/formatters.dart` |
| `'temperature and mass are independent settings'` | Write `weight_unit = 'lb'`; `temperature_unit` is still `'c'`. Two columns, two verbs, no coupling — and `setTemperatureUnit` exists on the repository while no control renders it |
| `'the temperature control does not render in v1'` | `settings.units.temperature.c` is `findsNothing`, with the `reason:` citing `07 §14.3` row 1 and open question 11. The case is the record of the ruling |
| `'both segments are at least 60 x 60, separated by at least gapMin, and read from context.tokens'` | `tester.getRect`; no literal `64` and no literal `8` in the widget file |
| `'the selected segment is distinguished by more than colour'` | The selected node carries `selected: true` in semantics **and** a non-colour visual difference (`06 §5`, decision #106) |
| `'the semantics label is the visible text and the state is not in the label'` | `kg` / `lb`; no `'kg, selected'` (`10 §3.2` rules 2 and 3) |
| `'no SnackBar is shown when the unit changes'` | `find.byType(SnackBar)` is `findsNothing` (P2) |
| `'the units section renders without overflow at the smallest device and textScaler 2.0'` | Two 64 pt segments plus a heading — the easy cell, asserted so that a later redesign into three segments is caught |
| `'UNITS: a 0.1 lb entry survives a round trip at 1 dp'` · in `test/domain/units_test.dart` | Already written in N04 (`05 §5.3`). **Do not duplicate it here.** Cite it in the widget test's `reason:` so the widget tier points at the tier that actually proves the arithmetic |

## 6. Constraints that bind this task

- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Never silently correct an entry** (safety rule 4). The whole task is one instance of it: a unit
  preference that rewrites a stored measurement is a correction nobody asked for and nobody can see.
- **en_GB, kg, °C, 24 h** (owner ruling §7.0 #3). `weight_unit` defaults to `'kg'`, `temperature_unit`
  to `'c'`, and `03 §5.13` deliberately carries **no** locale, date-format or first-day-of-week column
  — *"a stored copy would go stale the moment the user changes their phone's region."* Do not add one.
- **The keypad is the only number-entry route** (decision #57). This section has no numeric field, so
  the rule binds it negatively: if a unit control grows a text field, it has grown a locale problem
  (`double.parse('4,3')` throws) that the keypad exists to remove.

## 7. Definition of Done

- [ ] `'switching units changes every rendered weight and rewrites no stored row'` passes, and was seen to fail first for the stated reason
- [ ] no stored value changes
- [ ] every rendering site respects the setting
- [ ] temperature and mass are independent settings
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the commit message records that the schema, domain and data steps are all skipped, and lists every file audited for a mass rendering
- [ ] `formatMass` is the only place a `Grams` becomes a displayed number; `inKilograms`, `inPounds` and `toStringAsFixed` appear nowhere under `lib/features/`
- [ ] the °C / °F control is **not** rendered, the reason is a comment beside the section citing `07 §14.3` and open question 11, and the PR body carries the question as still open
- [ ] no `unit` column is added to any table, and `drift_schemas/` does not appear in the diff
- [ ] the selected segment is distinguished by more than colour, and its semantics carry `selected:` rather than a label suffix
- [ ] `find.byType(SnackBar)` is `findsNothing` in every new case

## 8. Verification

```bash
fvm flutter test test/features/settings_test.dart
fvm flutter test test/domain/units_test.dart      # the arithmetic tier, unchanged, still green
make check
make test
```

```bash
grep -rn "inKilograms\|inPounds\|toStringAsFixed" lib/features/     # expect zero
grep -rn "formatMass" lib/ | wc -l                                  # one definition + N call sites
grep -rn "class Pounds\|class Fahrenheit" lib/                      # expect zero (CONVENTIONS §2.3)
grep -rn "temperature" lib/features/settings/                       # expect only the comment
grep -rn "toInt()" lib/domain/units/                                # expect zero — round(), always
git diff --stat -- drift_schemas/ lib/core/db/                      # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(settings): units at the display edge only`

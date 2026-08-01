# N17-T02 — Sex, and a birthweight on the app's own keypad

| | |
|---|---|
| **Epic** | [N17 — Lamb Card](epic.md) · `00-README` §9 step 6 (3 of 5) |
| **Task** | 2 of 5 |
| **Depends on** | N17-T01 |
| **Commit** | one commit · `feat(lamb_card): sex and a birthweight in canonical grams` |

## 1. Why this task exists

Sex as a committed write on tap, and a birthweight typed on `ShedKeypad` — never the
system keyboard — stored in **canonical grams** and shown in the user's unit. Typed in lb, stored in
grams, displayed in lb: the round trip must not rewrite what the shepherd entered.

`05 §5.1` walks the failure this prevents, and it is worth memorising because it has no line of code
to blame: the user enters 9.5 lb → you store 9.5 with a unit flag → they switch to kg and see 4.309 →
the edit screen pre-fills 4.3 at 1 dp → they close it without touching anything → the record is now
4.3 kg = 9.48 lb. *The value drifted because nobody edited it.* That is a §12.4 silent correction
produced entirely by a storage decision.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | **§5.1** | the canonical-storage rule, and the display-unit round-trip bug it exists to prevent |
| `docs/engineering/05-domain-correctness.md` | **§5.2–§5.4** | `Grams` printed in full, `round()` over `toInt()`, the keypad ruling (decision #57), and `kPlausibleBirthWeight` as shipped |
| `docs/engineering/05-domain-correctness.md` | §7.5 | `implausibleBirthWeight` — an observation, never a block and never a judgement |
| `docs/engineering/03-data-model-and-schema.md` | §5.5 | `birth_weight_g INTEGER`, `sex TEXT` nullable, and `CHECK (birth_weight_g IS NULL OR birth_weight_g BETWEEN 200 AND 20000)` |
| `docs/engineering/07-screens.md` | §7.3 | the tap costs: sex 1 tap, birthweight 1 + digits + 1 |
| `docs/engineering/06-design-system.md` | **§8** | `ShedKeypad` — the decimal key, `displaySmall` glyphs, no key repeat, and *"every numeric entry in the app uses this pad… and weights"* |
| `docs/engineering/10-accessibility-and-i18n.md` | §9.1, §9.4 | `formatShedWeight(Grams, WeightUnit, String)`, `unitsProvider`, and why the decimal separator is fixed |
| `docs/engineering/10-accessibility-and-i18n.md` | §8.5, §5.2 | the terminology placeholder rule, and the lamb-row redundancy rows |
| `docs/engineering/CONVENTIONS.md` | §2.3, §2.9, §3.1, §4.5, R45, R68, R70 | `Grams`, `WeightUnit`, `Sex` (`NULL` ≠ `unknown`), `unitsProvider`, widget keys, and `ShedKeypad`'s home |
| `docs/design/indelible.md` | §7.8, §7.12, §7.14, §8 screen 5 | the number stepper, the field with no placeholder, the one overlay, and the summary row's `4.1kg` |
| `docs/engineering/CODE-REVIEW-CHECKLIST.md` | **§2.3** | the §12.2 example that is set in `lamb_card_screen.dart` and passes the content scanner |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | each field is its own immediate write |
| `shed-domain` | `Grams`, the unit conversion and the display edge |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/units_test.dart`
- **Test** — `'a weight typed in lb round-trips through canonical grams without rewriting the entry'`
- **Why it is red today** — nothing records a weight, and the obvious implementation stores whatever unit was typed.

```bash
fvm flutter test test/domain/units_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the keypad entry, the conversion at the boundary, and the round-trip property.

Sharpen the assertion: the test must exercise the **full entry path**, not just `Grams.fromPounds`.
Type the digits, read the committed `birth_weight_g`, re-open the cell, and assert the digits that
come back are the ones that went in — with `WeightUnit.lb` and again with `WeightUnit.kg`.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 steps 3 (the write verbs), 5 (the write controller call sites), 6 (UI + ARB) and 7
(tests). **Steps 1 and 2 are skipped and the commit message says so**: `birth_weight_g` and `sex` are
N07-T04's columns, and `Grams`, `WeightUnit` and `formatShedWeight` all exist from N04-T06 and N09-T06.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `test/domain/units_test.dart` | edit | The anchor, written first. It joins the file N04-T06 created |
| 2 | `lib/data/lambing_repository.dart` | edit | `setLambSex` and `setBirthWeight` — two event verbs, each one `_db.transaction()`, each returning `WriteOutcome`, each calling `appNow()` once |
| 3 | `lib/features/lambing/lambing_write_controller.dart` | edit | Two methods routing through `guard()`. **No new write controller** — `CONVENTIONS §3.4` has no `lambCardWriteControllerProvider` |
| 4 | `lib/features/lambing/widgets/lamb_sex_row.dart` | new | Three targets — female / male / unknown — over `ShedChoiceRow`. Feature-local: it appears on one screen |
| 5 | `lib/features/lambing/widgets/lamb_weight_cell.dart` | new | The 64 px cell, its unset state, and the `ShedBottomSheet` + `ShedKeypad` it opens |
| 6 | `lib/features/lambing/lamb_card_screen.dart` | edit | Both cells land in the card; the summary row gains the weight |
| 7 | `lib/l10n/app_en.arb` | edit | `lambCardSexLabel`, `lambCardSexUnknown`, `lambCardWeightLabel`, `lambCardWeightUnset`, `lambCardWeightUnitKg`, `lambCardWeightUnitLb`, `warningImplausibleBirthWeight`, each with a `description` |
| 8 | `test/features/lamb_card_test.dart` | edit | The widget half of the round trip, the keypad assertions, and the three sex states |

### 5.2 The signatures

```dart
// lib/data/lambing_repository.dart
// New names, declared here under CONVENTIONS §4.2's event-verb rule. §2.13 publishes
// "canonical verb signatures where more than one document names them" — it is not the
// closed set. Both are listed in the PR body.

/// `null` is "not recorded". `Sex.unknown` is "the shepherd looked and could not
/// tell". R45: they are different facts and neither is the other's default.
Future<WriteOutcome> setLambSex(LambId lamb, Sex? sex);

/// Canonical grams. `null` clears the cell back to unset — a weight is skippable
/// and stays skippable.
Future<WriteOutcome> setBirthWeight(LambId lamb, Grams? weight);
```

```dart
// lib/features/lambing/lambing_write_controller.dart
Future<void> setLambSex(LambId lamb, Sex? sex) =>
    guard(() => _repo.setLambSex(lamb, sex));

Future<void> setBirthWeight(LambId lamb, Grams? weight) =>
    guard(() => _repo.setBirthWeight(lamb, weight));
```

```dart
// lib/features/lambing/widgets/lamb_weight_cell.dart — the display edge, and the ONLY
// place a display unit exists. The double never travels back toward the database.
final unit = ref.watch(unitsProvider);                       // Provider<WeightUnit>
final text = weight == null
    ? l10n.lambCardWeightUnset
    : formatShedWeight(weight, unit, context.localeName);    // lib/core/ui/formatters.dart

// On confirm: the TYPED string becomes canonical, once.
final typed = double.parse(keypadBuffer);                    // the pad emits '.' always
final grams = switch (unit) {
  WeightUnit.kg => Grams.fromKilograms(typed),
  WeightUnit.lb => Grams.fromPounds(typed),
};
```

Widget keys, per `CONVENTIONS §4.5` — every segment `lower_snake`, joined by `.`:

```
lamb_card.sex.female      lamb_card.sex.male      lamb_card.sex.unknown
lamb_card.weight          lamb_card.weight.confirm
```

### 5.3 The details that are easy to get wrong

1. **The cell is seeded from the canonical value and parses the typed text back into canonical. It
   never re-derives from the old canonical.** `05 §5.1`'s third bullet. Seeding the keypad buffer
   from `formatShedWeight`'s output at 1 dp and then reading that buffer back on confirm is precisely
   the round trip the whole design exists to prevent — it looks like reuse and it is data loss. Seed
   the buffer from the canonical value once, on open; if the shepherd does not touch a key, **write
   nothing at all**.
2. **`Sex?` is nullable and `Sex.unknown` is not the null.** `03 §5.5`'s comment and R45:
   `lambs.sex IS NULL` means not recorded; `'unknown'` means the shepherd looked and could not tell.
   Modelling it as `Sex` with `unknown` as the default deletes the first fact, and the CSV then
   claims every unsexed lamb was inspected. The control therefore has **three** targets and a fourth
   state (nothing selected) that is not a target.
3. **The sex label on screen is a terminology term, not the word "female".** `05 §8.1`:
   `AnimalClass.eweLamb` and `AnimalClass.ramLamb` are stable keys with user-editable labels;
   Indelible screen 4 prints `LAMB 1 · EWE LAMB · ALIVE · 4.1kg`. The ARB message carries the frame
   and the noun arrives as a placeholder fed by `terminologyProvider` (`10 §8.5`). A literal `ewe
   lamb` in an ARB message is a defect, and `arb_has_no_domain_noun_test.dart` (N33-T05) will find it.
4. **The keypad's decimal key is live here and inert for tags.** `06 §8`: bottom-right is *always*
   the decimal key and *"the grid never re-legends"* — it renders inert (`surfaceRaised`,
   `textChrome`, `onTap` null) when the field is integer-only. A weight field must switch it on;
   forgetting to is a cell that cannot record `4.1`.
5. **The pad's decimal key always emits `.`, whatever the phone's locale.** Decision #57 removes the
   locale problem at the source: `double.parse('4,3')` throws, and `NumberFormat.parse` for a comma
   locale throws on `'4.3'` — which is worse, because a UK shepherd's phone may be set to French.
   `parseUserNumber` is for *"any free-text numeric field that survives review"*, and this is not one:
   there is no system keyboard on this screen.
6. **`round()`, never `toInt()`.** `toInt()` truncates toward zero, so every conversion is
   systematically light — on a birthweight, in the direction that reads as a smaller lamb. The
   factories in `grams.dart` already do this; do not add a second conversion at the call site.
7. **The `CHECK` is a unit-slip guard, not a husbandry opinion.** `birth_weight_g BETWEEN 200 AND
   20000` refuses 4 g and 30 kg at the storage layer — a fat-finger `4` where `4000` was meant.
   `03 §5.5`'s comment is explicit: *"Never narrow this to a range a vet would recognise — spec
   §12.2."* A rejected write surfaces as a `ShedFailure` through `shedFailureFrom`, not as a silent
   clamp.
8. **`implausibleBirthWeight` is a `Warning` and warnings never gate the write.** Below `Grams(1000)`
   or above `Grams(10000)`, both bounds inclusive-pass (`05 §5.4`). The message is the catalogue's
   verbatim `"0.4 kg is outside the usual range for a lamb."` — never *"that is light for a twin"*,
   which is husbandry advice. The **controller** runs the validator against the freshly-watched row
   and hands the `List<Warning>` on; a repository is structurally incapable of producing one (R53),
   and `lib/data/` has no import path to `lib/domain/validation/`.
9. **A weight of 4 g cannot raise the warning at all.** `07 §7.4` spells this out: the `CHECK`
   refuses it before any validator sees it. Do not write a test that expects a warning for 4 g — you
   will get a `SqliteException`, and the test that "proves" the warning will be proving the `CHECK`.
10. **Do not multiply the weight by anything.** `CODE-REVIEW-CHECKLIST.md` §2.3's worked example of a
    §12.2 violation that **passes** the content scanner is set in this exact file:
    `(lamb.birthWeight.inKilograms * 50).round()` feeding an ARB message `"Give {ml} ml"`. AHDB
    publishes 50 ml/kg, the app holds the weight, and it would be *helpful*. No pattern matches, no
    gate fires, and it is a dose suggestion. Nothing on this screen computes from the weight.
11. **`unitsProvider` is a `Provider<WeightUnit>` derived from `settingsProvider`, and it is an
    app-level singleton.** `07 §1.2` permits watching it beside the one content statement. Do not
    read the unit through a second drift stream, and do not pass it into the controller — `02 §4.4`
    rule 3: a controller never formats for display, and a controller that knows `en_GB` cannot be
    unit-tested without a locale.
12. **There is no placeholder in the cell.** Indelible §7.12: *"In the dark, a grey placeholder is
    indistinguishable from an entered value."* Unset prints a visible gap — a 2 px dotted rule with
    `NOT RECORDED · SKIPPABLE` in the control face above it (§7.8's Unset state) — never a ghosted
    `0.0` and never `—` alone.
13. **No system keyboard, anywhere.** `TextField`, `TextFormField`, `keyboardType:` and
    `showModalBottomSheet(` outside `shed_bottom_sheet.dart` are all wrong on this path; the last is
    a gate row from N10-T07. The pad opens in `ShedBottomSheet`, the only overlay in the app, with
    `enableDrag: false` and an explicit Cancel.
14. **Both writes are their own commit and neither has an undo verb.** `07 §15.1` lists no row for a
    lamb field: they correct forward, `updated_at` moves, and the previous value is not preserved
    because `lambs` has no history table and no provenance quad. The screen must not imply otherwise
    — no "Undo" label on a sex tap.

### 5.4 The full test set

**`test/domain/units_test.dart`** — the anchor joins N04-T06's file. Zone-agnostic.

| Case | What it pins |
|---|---|
| `'a weight typed in lb round-trips through canonical grams without rewriting the entry'` | **the anchor.** For every tenth 1.0…25.0 lb: type → `Grams.fromPounds` → `formatShedWeight(g, lb, 'en_GB')` → parse the rendered digits → equals what was typed |
| `'a weight typed in kg round-trips through canonical grams'` | the same loop through `fromKilograms` / `inKilograms` |
| `'switching the display unit does not change the stored grams'` | one `Grams`, rendered under both `WeightUnit` values, asserted `.value` unchanged |
| `'the plausible band bounds do not warn'` | `Grams(1000)` and `Grams(10000)` produce an empty `List<Warning>` — both bounds inclusive-pass |
| `'999 g and 10001 g each produce exactly one implausibleBirthWeight'` | the message is the catalogue's verbatim string; `warnings.single.code` is the enum member |

**`test/features/lamb_card_test.dart`** — extended.

| Case | What it pins |
|---|---|
| `'typing 9 . 5 on the keypad with lb selected commits 4309 grams'` | the full entry path, on keyed finders `lamb_card.weight` → digits → `lamb_card.weight.confirm` |
| `'opening and closing the weight cell without pressing a key writes nothing'` | `updated_at` is unchanged. This is note 1 as a test |
| `'the decimal key is live on the weight cell and inert on the tag cell'` | `06 §8` — same grid, two states, never re-legended |
| `'no system keyboard is reachable from this screen'` | a tree walk: no `EditableText` under `LambCardScreen` |
| `'sex has three targets and a fourth unset state that is not a target'` | female / male / unknown are `ShedTapTarget`s; nothing-selected exposes no tap |
| `'leaving sex unrecorded stores NULL, not unknown'` | read `lambs.sex` back: `isNull`. Then tap unknown and read `'unknown'` |
| `'the sex label is the terminology term, not a literal'` | override `AnimalClass.eweLamb` to `'chilver'` and assert the row renders `chilver` |
| `'an implausible weight commits and prints an observation'` | the row is written, the badge renders, and reading `birth_weight_g` back shows the value unchanged |
| `'nothing on this screen multiplies the birthweight'` | source read of `lib/features/lambing/`: no arithmetic operator applied to `inKilograms` or `inPounds`. Note 10, as a test that survives review turnover |
| `'both writes go through guard() and a double tap commits once'` | `tester.tap(); tester.tap();` on `lamb_card.sex.female` — one row change |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **The five safety rules** — rule 4 (never silently correct), held at **unpersistable** for the storage half (there is no `unit` column and `Pounds` is a banned type name) and at **caught by a test** for the entry half. Rule 2 (never give veterinary advice) is held here only by review — note 10 is why it is in the PR body.
- **3am** — the pad is the only numeric route: 72 pt keys, `.` always, no key repeat, no system keyboard, no slider. Every target ≥ 64 × 64.

## 7. Definition of Done

- [ ] `'a weight typed in lb round-trips through canonical grams without rewriting the entry'` passes, and was seen to fail first for the stated reason
- [ ] storage is grams, always
- [ ] the entry is never rewritten by a round trip through the display unit
- [ ] no system keyboard, anywhere
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/units_test.dart
fvm flutter test test/domain/units
fvm flutter test test/features/lamb_card_test.dart
TZ=Pacific/Chatham fvm flutter test test/domain/units_test.dart
grep -rn "TextField\|TextFormField\|keyboardType" lib/features/lambing/   # expect: nothing
grep -rn "inKilograms\|inPounds" lib/features/                            # display only, no arithmetic
dart run tool/check_policy.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(lamb_card): sex and a birthweight in canonical grams`

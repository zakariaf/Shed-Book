# N04-T06 — `Grams`, `WeightUnit` and `parseUserNumber`

| | |
|---|---|
| **Epic** | [N04 — Domain: time and units](epic.md) · `00-README` §9 step 2 (1 of 3) |
| **Task** | 6 of 8 |
| **Depends on** | N04-T05 |
| **Commit** | one commit · `feat(domain): Grams, WeightUnit and a parser that refuses to guess` |

## 1. Why this task exists

Mass is canonical **grams** in storage and is converted only at the display edge.
`parseUserNumber` returns **null on ambiguity** rather than guessing: `1,5` is 1.5 in Ireland and a
malformed 15 in a spreadsheet paste, so the function refuses and the caller asks. Guessing here is a
§12.4 silent correction.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §5.1 | the canonical-storage rule and the display-unit round-trip bug it prevents |
| `docs/engineering/05-domain-correctness.md` | §5.2 | `Grams` printed in full, the two exact conversion constants, and `round()` over `toInt()` |
| `docs/engineering/05-domain-correctness.md` | §5.3, §5.4 | the three tests that *are* the specification, the keypad ruling, and `parseUserNumber`'s printed body |
| `docs/engineering/CONVENTIONS.md` | §2.3, §6 R17, R68 | `Grams`, `WeightUnit`, `parseUserNumber` — names, files, member lists; `Pounds` and `Fahrenheit` banned |
| `docs/research/00-tech-decisions.md` | §2.E #55, #56, #57, #118; §5.2 | canonical grams; the `normalize*` ban scope; keypad input; property tests scoped to value round-trips; `glados` struck from §5.2 on 2026-08-01 |
| `docs/research/00-tech-decisions.md` | §7.0 ruling 3 | UK/Ireland first — `weight_unit` defaults to `'kg'`, `en_GB`, 24-hour |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-domain` | units, canonical storage and the display edge |
| `shed-safety-rules` | a parser that guesses is a silent correction with a friendly name |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/units_test.dart`
- **Test** — `'parseUserNumber returns null for 1,5 rather than guessing 15 or 1.5'`
- **Why it is red today** — nothing parses a typed weight, so the first screen to need one would call `double.parse`.

```bash
fvm flutter test test/domain/units_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the `Grams` extension type, the `WeightUnit` enum, and a parser whose ambiguous cases are
enumerated in the test. **Read §5.3.1 first**: the anchor requires a parser one line stricter than the
body `05` §5.4 prints, and that discrepancy is a finding, not a licence to weaken the test.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 step 2 (domain) and step 7 (tests). Step 1 skipped — `lambs.birth_weight_g` and
`app_settings.weight_unit` are N07's columns. What this task fixes is the shape and the key strings
those columns must match. Say so in the commit message.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `test/domain/units_test.dart` | new | The anchor, written first |
| 2 | `lib/domain/units/parse_number.dart` | new | `double? parseUserNumber(String raw)`. One top-level function, no class, no `Parser` suffix |
| 3 | `lib/domain/units/grams.dart` | new | `extension type const Grams(int value)`, two `static const` conversion factors, three factories, four getters |
| 4 | `lib/domain/units/weight_unit.dart` | new | `enum WeightUnit { kg('kg'), lb('lb') }` + `fromKey` |
| 5 | `test/domain/units/grams_test.dart` | new | The three §5.3 loops. Mirrors `lib/domain/units/grams.dart` per CONVENTIONS §4.1 |

`kPlausibleBirthWeight` is **not** here: CONVENTIONS §2.3 puts it in
`lib/domain/validation/lambing_checks.dart`, which is N06-T03. Declaring it early would put a
validation constant in the units folder and give `lib/data/`'s import ban nothing to bite on.

> **Naming deviation, recorded rather than silently fixed.** CONVENTIONS §4.1 says a test mirrors the
> file under test, which would spell the anchor `test/domain/units/parse_number_test.dart`. The
> backlog fixed the anchor at `test/domain/units_test.dart` and the anchor is preserved verbatim. Keep
> both: `units_test.dart` holds `parseUserNumber` and `WeightUnit`; `units/grams_test.dart` mirrors
> `grams.dart`. Do not rename the anchor to tidy this up — it is referenced from
> `00-PLAN-CRITIQUE.md`'s first-failing-test table.

### 5.2 The signatures

```dart
// lib/domain/units/grams.dart
/// Canonical mass: whole grams. Non-transparent extension type, so a raw `int`
/// cannot be passed where a mass is expected, and it costs no allocation on a
/// 400-row flock list.
extension type const Grams(int value) {
  static const double _gPerLb = 453.59237;     // exact, by definition
  static const double _gPerOz = 28.349523125;  // exact, by definition

  factory Grams.fromKilograms(double kg) => Grams((kg * 1000).round());
  factory Grams.fromPounds(double lb)    => Grams((lb * _gPerLb).round());
  factory Grams.fromPoundsOunces(int lb, double oz) =>
      Grams((lb * _gPerLb + oz * _gPerOz).round());

  double get inKilograms     => value / 1000.0;
  double get inPounds        => value / _gPerLb;
  int    get wholePounds     => inPounds.floor();
  double get remainderOunces => (value - wholePounds * _gPerLb) / _gPerOz;
}
```

```dart
// lib/domain/units/weight_unit.dart
/// Rendering and parsing only. There is NO unit column on any measurement.
/// The keys are byte-identical to app_settings.weight_unit's CHECK (R68).
enum WeightUnit {
  kg('kg'),
  lb('lb');

  const WeightUnit(this.key);
  final String key;

  static WeightUnit fromKey(String k) =>
      WeightUnit.values.firstWhere((u) => u.key == k,
          orElse: () => throw FormatException('Unknown weight unit', k));
}
```

```dart
// lib/domain/units/parse_number.dart
/// Rejects ambiguity rather than guessing. `4,3` may be 4.3 or a mistyped 43,
/// and choosing either is a silent correction (safety rule 4). The caller asks.
double? parseUserNumber(String raw);
```

### 5.3 The details that are easy to get wrong

1. **The anchor test contradicts `05` §5.4's printed body, and the anchor wins.** The body as printed
   is:

   ```dart
   final commas = ','.allMatches(s).length;
   final dots = '.'.allMatches(s).length;
   if (commas > 0 && dots > 0) return null;   // ambiguous
   if (commas > 1 || dots > 1) return null;
   return double.tryParse(s.replaceAll(',', '.'));
   ```

   Feed it `'1,5'`: one comma, zero dots, neither guard fires, and it returns **1.5**. That *is* a
   guess — the document's own comment says *"guessing that `'4,3'` means 43 is a silent correction"*
   and then resolves the ambiguity the other way, which is the same act in the other direction. The
   anchor test — `'parseUserNumber returns null for 1,5 rather than guessing 15 or 1.5'` — is the
   stricter and safer reading, and it is the one the backlog fixed.

   **Resolution to implement:** replace the first guard with `if (commas > 0) return null;`. A comma
   is ambiguous in `en_GB` full stop: as a decimal separator it means 1.5, as a thousands separator a
   mistyped 15. `null` becomes a `Warning`, never a value.

   **Resolution to record:** this is an edit to `05` §5.4's printed body and its comment, under
   `00-README` §10's amendment rule. Raise it in the PR body with the §12 questions — do not weaken
   the test to match the document, and do not change the document without saying so.

   The cost is near zero, because §5.4 already removed the locale problem at the source: weights use
   **the in-app 60×60 pt keypad** with one decimal key that always emits `.` (decision #57).
   `parseUserNumber` exists only for *"any free-text numeric field that survives review"* — a
   shrinking set.
2. **`round()`, never `toInt()`, never `ceil()`/`floor()`.** `toInt()` truncates toward zero, so every
   conversion is systematically light — on a birthweight, in the direction that reads as a smaller
   lamb. `05` §5.2 says so and asks for a boundary test at `x.5`. Note Dart's `double.round()` rounds
   **half away from zero**, so `(0.5).round() == 1` and `(-0.5).round() == -1`; pin both.
3. **The two constants are exact by definition and must not be shortened.** `453.59237` g/lb and
   `28.349523125` g/oz are the international definitions. Writing `453.592` looks harmless and breaks
   the 0.1 lb round-trip loop at the top of the range, which is the loop that justifies the whole
   design.
4. **Never build an extension type for a display unit.** `Pounds` and `Fahrenheit` are banned type
   names (CONVENTIONS §2.3). They would erase to the same runtime type as `Grams`, giving false
   confidence in any `is`/`switch`/serialisation path and inviting somebody to store one. Pounds exist
   only as a `double` returned by a getter and consumed immediately by a formatter.
5. **There is no `unit` column on any measurement, and a schema test in N07 asserts it.** The unit
   preference lives in `app_settings` and affects **rendering and parsing only**. The bug this
   prevents is the display-unit round trip, and it is worth memorising because it has no line of code
   to blame: user enters 9.5 lb → you store 9.5 with a unit flag → they switch to kg and see 4.309 →
   the edit screen pre-fills 4.3 at 1 dp → they save without touching it → the record is now 4.3 kg =
   9.48 lb. *The value drifted because nobody edited it.*
6. **A form is seeded from the canonical value and parses the typed text back into canonical. It
   never re-derives from the old canonical.** That is `05` §5.1's third bullet and it is the call-site
   half of the same bug.
7. **`WeightUnit`'s keys are a contract with a column that does not exist yet.** `'kg'` and `'lb'`
   must be byte-identical to `app_settings.weight_unit`'s `CHECK` (R68), written in N07. A mismatch
   surfaces as a `CHECK` failure on a real phone, not as a compile error here. The default is `'kg'`
   — settled, not open (decision-record §7.0 ruling 3: UK/Ireland first).
8. **`remainderOunces` uses `wholePounds`, which uses `floor()` — deliberately.** It is a
   decomposition for display (`8 lb 3 oz`), not a rounding of the canonical value. Nothing here is
   stored. Do not "make it consistent" with `round()`; `floor()` is what makes the pair sum back to
   the original.
9. **Storage never rounds. Only the display edge does.** `Grams` holds an `int`; every getter returns
   a `double` for immediate rendering. The moment a rounded display value is assigned to a variable
   that flows back toward the database, §5.1's rule has been broken.
10. **The third test in §5.3 looks deletable and is not.** It computes the corruption count for the
    *rejected* 0.1 kg design — `expect(corrupted, 132)` — and it exists so that "simplifying" the
    canonical unit in season three fails CI with the measurement that decided it. `05` §5.3 says
    outright: *"it stays."* Keep the `reason:` string that names decision #56.
11. ****`glados` was struck from decision-record §5.2 on 2026-08-01** — it does not resolve against `drift_dev` 2.34.5 at any version, because it depends on `package:test`. Decision #118 is amended: the pure-value layer is an explicit table of cases in the same file. Do not add the package; the rule `12 §10.6` stated in advance has already been applied — the property layer was deleted, not the pin.** The original text of this item read *"`glados` is already a dev dependency — use it here and nowhere
    beyond value round-trips.** Decision #118 scopes property tests to *pure value round-trips only*.
    If `flutter pub get` reddens when you first import it, delete the property layer, not the pin
    (`12` §10.6): it is the dev dependency closest to the `analyzer <13` constraint that `drift_dev`
    needs.
12. **`parseUserNumber` returns `double?`, and `null` is not zero.** `?? 0` anywhere near it is the
    §12.4 failure mode in its purest form. `05` §6.1 bans `?? 0` outright in two feature folders and
    makes it a `tool/check_policy.dart` rule; the habit starts here.
13. **The plausibility band is not this file's.** Warning below `Grams(1000)` or above `Grams(10000)`
    is `kPlausibleBirthWeight` in N06-T03, it is **provisional pending open question 12**, and it
    produces a `Warning` — an observation — never a block and never a judgement. Do not add a range
    check to `Grams`.

### 5.4 The full test set

**`test/domain/units_test.dart`** — the anchor's home: `parseUserNumber` and `WeightUnit`.
Zone-agnostic, no `@Tags`.

| Case | What it pins |
|---|---|
| `'parseUserNumber returns null for 1,5 rather than guessing 15 or 1.5'` | **the anchor.** `expect(parseUserNumber('1,5'), isNull)` |
| `'every ambiguous input returns null'` | a table: `'1,5'`, `'4,3'`, `'1,5.5'`, `'1.5,5'`, `'1.234.5'`, `'1,234,5'`, `'1 234,5'`, `'--4'`, `'4.'`, `'.'`, `','`, `'4,'`, `'abc'`, `''`, `'4 kg'`, `'4.5.6'` |
| `'every unambiguous input parses'` | `'4'` → 4.0; `'4.5'` → 4.5; `'0'` → 0.0; `'0.5'` → 0.5; `'-4.5'` → −4.5; `'  4.5  '` → 4.5; `'4 . 5'` → 4.5 (spaces are stripped before counting) |
| `'null is never coerced to a number by the parser itself'` | source read of `parse_number.dart`: no `?? 0`, no `?? 0.0`, no `orElse` returning a number |
| `'WeightUnit keys are kg and lb, in that order'` | `WeightUnit.values.map((u) => u.key).toList() == ['kg', 'lb']`, with a `reason:` naming `app_settings.weight_unit`'s `CHECK` (R68) |
| `'fromKey round-trips and throws on anything else'` | both keys round-trip; `'kgs'`, `'KG'`, `'pounds'`, `''` all throw `FormatException` |

**`test/domain/units/grams_test.dart`** — the loops that are the specification.

| Case | What it pins |
|---|---|
| `'UNITS: a 0.1 lb entry survives a round trip at 1 dp'` | `05` §5.3 verbatim: `tenths` 10…250, `Grams.fromPounds(lb).inPounds` at 1 dp equals `lb` |
| `'UNITS: 0.1 kg canonical WOULD corrupt lb entries — this is why grams'` | `05` §5.3 verbatim: `expect(corrupted, 132, reason: 'the measurement behind decision #56')` |
| `'a 0.1 kg entry survives a round trip at 1 dp'` | `tenths` 10…250 through `fromKilograms`/`inKilograms` |
| `'rounding is half away from zero at the x.5 boundary'` | `Grams.fromKilograms(0.0005).value == 1`; `Grams.fromKilograms(-0.0005).value == -1`; and the assertion that `toInt()` would give 0 for both |
| `'the conversion constants are the exact definitions'` | `453.59237` and `28.349523125` pinned literally — the guard against a "tidied" `453.592` |
| `'pounds and ounces decompose and recompose'` | for `g` across 500…12000: `Grams.fromPoundsOunces(g.wholePounds, g.remainderOunces).value` is within 1 g of `g.value` |
| `'the plausible birthweight band is representable but not enforced here'` | `Grams(1000)` and `Grams(10000)` construct freely; source read of `grams.dart` finds no range check and no `throw` |
| `'Grams is const and erases to int'` | `const Grams(4000)` compiles; a documented note that `Grams(0)` and `Instant(0)` are identical at runtime, so no code may discriminate them by type |
| **table** `'fromPounds/inPounds round-trips at 1 dp for any plausible lamb'` | an explicit table of cases across 1.0…25.0 kg, including both endpoints and the 0.05 kg neighbours of every 0.1 kg step — decision #118 as amended 2026-08-01. `glados` does not resolve and is struck from §5.2 |

## 6. Constraints that bind this task

- **The five safety rules** — rule 4 (never silently correct an entry), held at **unconstructible** for the storage half (there is no `unit` column and no display extension type to store) and at **caught by a test** for the parser half. A `parseUserNumber` that resolves `'1,5'` in either direction drops rule 4 to *documented*, which `05` §7.1 counts as deleted.
- **`layer.domain`** — `dart:*`, `package:meta`, `package:collection`, `lib/domain/` only. No `intl`: `NumberFormat.parse` for a comma locale throws on `'4.3'`, which is *worse* than `double.parse` throwing on `'4,3'`, because a UK shepherd's phone may be set to French (`05` §5.4).
- **The 3am test** — the reason this parser is nearly unreachable is that number entry is the in-app 60×60 pt keypad with one decimal key that always emits `.` (decision #57). No system keyboard, no locale, no dismissal jank.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'parseUserNumber returns null for 1,5 rather than guessing 15 or 1.5'` passes, and was seen to fail first for the stated reason
- [ ] storage is grams, always
- [ ] every ambiguous input in the test table returns null
- [ ] no rounding happens in storage — only at the display edge
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/units_test.dart
fvm flutter test test/domain/units
TZ=Pacific/Chatham fvm flutter test test/domain/units_test.dart test/domain/units
dart analyze lib/domain/units
dart run tool/check_policy.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): Grams, WeightUnit and a parser that refuses to guess`

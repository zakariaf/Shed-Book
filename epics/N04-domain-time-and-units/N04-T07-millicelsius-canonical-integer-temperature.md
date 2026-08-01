# N04-T07 — `MilliCelsius` — canonical integer temperature

| | |
|---|---|
| **Epic** | [N04 — Domain: time and units](epic.md) · `00-README` §9 step 2 (1 of 3) |
| **Task** | 7 of 8 |
| **Depends on** | N04-T06 |
| **Commit** | one commit · `feat(domain): MilliCelsius as canonical integer temperature` |

## 1. Why this task exists

Temperature as an integer in milli-degrees Celsius, converted to °F only at the display
edge. Integer storage because a float temperature round-trips badly through JSON and because the
schema-shaped ruling in N00-T04 fixed the column's shape.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §5.2 | `MilliCelsius` printed in full; the 89-of-201 measurement behind decision #56; *"0.01 °C is the minimum that survives all 201"* |
| `docs/engineering/05-domain-correctness.md` | §5.1, §5.3 | canonical storage, the display edge, and the round-trip loop that is the specification |
| `docs/engineering/05-domain-correctness.md` | §7.3 | safety rule 2 — the app may transform a number the user supplied and may never originate a clinical one |
| `docs/engineering/CONVENTIONS.md` | §2.3, §6 R68 | `MilliCelsius`'s file and members; `Fahrenheit` is a banned type name; `temperatureUnitProvider` ships only if a column ships |
| `docs/research/00-tech-decisions.md` | §2.E #56, §7.1 open question 11 | integer milli-°C; *where does temperature appear at all* is **still open** |
| `epics/N00-decisions-rulings-and-the-calendar/N00-T04-rule-the-four-schema-shaped-questions.md` | the temperature-column ruling | read the ruling this task's shape must match, before you write a line |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-domain` | canonical units and the conversion edge |
| `shed-drift-schema` | N00-T04 ruled the column's shape and open question 11 says do not create the column yet — check both before writing |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/temperature_test.dart`
- **Test** — `'a temperature entered in °F round-trips through MilliCelsius without drifting'`
- **Why it is red today** — no temperature type exists and the ruled column has nothing to store.

```dart
// `05` §5.3's loop, at the resolution a hook thermometer actually reads.
for (var tenths = 950; tenths <= 1150; tenths++) {       // 95.0 .. 115.0 F
  final f = tenths / 10.0;
  final t = MilliCelsius.fromFahrenheit(f);
  expect(double.parse(t.inFahrenheit.toStringAsFixed(1)), closeTo(f, 1e-9));
}
```

```bash
fvm flutter test test/domain/temperature_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the extension type, both conversions, and a round-trip property over the plausible range.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 step 2 (domain) and step 7 (tests). Step 1 is skipped **and must stay skipped** — see
§5.3.1. Say so in the commit message, and say *why*, because this is the one task in the epic where
"skipping the schema step" is a ruling rather than a sequencing detail.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `test/domain/temperature_test.dart` | new | The anchor, written first |
| 2 | `lib/domain/units/milli_celsius.dart` | new | The whole task. One extension type, two factories, two getters. Twelve lines of code and about forty of test |

Not touched: `lib/domain/units/weight_unit.dart` — there is **no** `TemperatureUnit` enum in v1.
R68: `temperatureUnitProvider` ships only if a temperature column ships, and no column ships until
open question 11 is answered.

> **Naming deviation, recorded rather than silently fixed.** CONVENTIONS §4.1's mirror rule would
> spell this test `test/domain/units/milli_celsius_test.dart`. The backlog fixed the anchor at
> `test/domain/temperature_test.dart` and `00-PLAN-CRITIQUE.md` references it. Keep the anchor; do not
> rename it to tidy the tree.

### 5.2 The signature

`05` §5.2 prints it in full. Copy it — including the operator order in both expressions, which is
load-bearing (§5.3.4):

```dart
// lib/domain/units/milli_celsius.dart
/// Canonical temperature: thousandths of a degree Celsius.
extension type const MilliCelsius(int value) {
  factory MilliCelsius.fromCelsius(double c) => MilliCelsius((c * 1000).round());
  factory MilliCelsius.fromFahrenheit(double f) =>
      MilliCelsius(((f - 32) * 5 / 9 * 1000).round());

  double get inCelsius    => value / 1000.0;
  double get inFahrenheit => value / 1000.0 * 9 / 5 + 32;
}
```

That is the entire public surface. No `isFever`, no `isNormal`, no plausibility band, no `compareTo`
until something needs one.

### 5.3 The details that are easy to get wrong

1. **Do not add a temperature column, a setting, or a provider.** Open question 11 in
   decision-record §7.1 is **unresolved**: spec §7.10 has a °C/°F setting but §10's data model has no
   temperature field. `05` §5.2 rules on it directly — *"`MilliCelsius` ships either way and costs
   nothing; do not add a temperature column until that question is answered, because an unused
   setting is a 3am tax and an unused column is a migration you did not need."* Shipping the type is
   free insurance; shipping the column is a commitment. Read N00-T04's ruling first and match its
   shape; if it ruled a column in, that column is still N07's to write, not yours.
2. **The word this type invites is banned.** A temperature in the domain is one autocomplete away
   from *"38.5 °C — normal"* or *"that's a fever"*. `ContentPolicy.bannedInUserFacingText` (N06-T09)
   matches `\b(normal|healthy|abnormal|too (low|high|light|heavy))\b` and `\b(diagnos|prognos)` and
   `\b(indicates?|suggests?) (a |an )?(problem|deficiency|infection|disease)\b`. `05` §7.3's line is
   the one to keep in your head: *"the app may arithmetic-transform a number the user supplied; the
   app may never originate a number that is a clinical decision."* A conversion is arithmetic. A
   judgement about the result is origination. This type does conversion only.
3. **`round()`, never `toInt()`.** Same rule as `Grams` and the same reason: `toInt()` truncates
   toward zero, which is systematically low above freezing and systematically *high* below it — the
   asymmetry is worse than the bias. Dart's `double.round()` is half away from zero, so
   `(-0.5).round() == -1`; pin that case, because a lambing shed in late March goes below zero and a
   truncating conversion there fails in the opposite direction from the one you tested.
4. **The operator order in both expressions is the specification.** `((f - 32) * 5 / 9 * 1000)` and
   `value / 1000.0 * 9 / 5 + 32` are not algebraically interchangeable in IEEE-754 with
   `((f - 32) * 5000 / 9)` or `(value * 9 / 5000 + 32)`. They differ in the last bit, which is enough
   to move a `.round()` across a boundary and break the 201-value loop at one input. Copy the printed
   expressions; if a review finds them ugly, the answer is a comment, not a rearrangement.
5. **Milli, not centi, and the reason is a measurement.** Storing at 0.1 °C rewrites **89 of 201**
   Fahrenheit entries at 1 dp. 0.01 °C is the *minimum* that survives all 201 — milli buys headroom
   for a 2 dp display later **without a migration**. That is the whole argument for the extra factor
   of ten, and it belongs in a comment above the type.
6. **`Fahrenheit` is a banned type name** (CONVENTIONS §2.3). An extension type for a display unit
   would erase to the same runtime type as `MilliCelsius` and `Grams`, giving false confidence in any
   `is`/`switch`/serialisation path and inviting somebody to store one. Fahrenheit exists only as a
   `double` returned by `inFahrenheit` and consumed immediately by a formatter.
7. **Integer storage is also a JSON and a SQL property, not only a rounding one.** A `double`
   measurement makes SQLite's `SUM` and `==` approximate and a JSON round trip can shift the last
   digit — `05` §5.4's anti-pattern list names both. The backup is the only copy of the data; a value
   that changes on restore is a silent correction with no author.
8. **No `package:decimal`, no `package:fixed`.** Both are in decision-record §5.3's rejected table:
   `BigInt` allocations for a problem `int` solves exactly.
9. **Negative and zero are real values.** `MilliCelsius(0)` is 0 °C, not "unset". There is no
   sentinel, no `-999`, and no nullable-means-zero. If a column ever ships, absence is `NULL` and it
   means *not recorded*.

### 5.4 The full test set — `test/domain/temperature_test.dart`

Zone-agnostic — nothing here touches a clock or a zone. No `@Tags`. This is the one file in the epic
with no time-shaped case to place in the ambiguous hour, and that absence is itself the property:
a temperature carries no instant, so nothing about it can move when the clocks do.

| Case | What it pins |
|---|---|
| `'a temperature entered in °F round-trips through MilliCelsius without drifting'` | **the anchor.** `05` §5.3's loop, 95.0…115.0 °F at 1 dp |
| `'a °C entry round-trips at 1 dp across the shed range'` | −20.0…45.0 °C in tenths, through `fromCelsius`/`inCelsius` |
| `'0.1 °C canonical WOULD corrupt 89 of 201 Fahrenheit entries'` | the executable form of decision #56's second measurement, with a `reason:` naming it — the sibling of the 132-of-241 test in N04-T06, and equally not deletable |
| `'0.01 °C is the minimum that survives all 201'` | the same loop at centi-degrees corrupts **zero** — which is why milli is headroom and not superstition |
| `'the freezing point and body temperature are exact'` | `fromCelsius(0).value == 0`; `fromFahrenheit(32).value == 0`; `fromCelsius(39.0).value == 39000`; `fromFahrenheit(102.2).inCelsius` at 1 dp is 39.0 |
| `'rounding is half away from zero, above and below zero'` | `fromCelsius(0.0005).value == 1`; `fromCelsius(-0.0005).value == -1`; and the assertion that `toInt()` gives 0 for both |
| `'negative temperatures survive the round trip'` | −25.0…0.0 °C in tenths — the case a shed in late March actually produces |
| `'the conversion expressions are the printed ones'` | source read of `milli_celsius.dart`: `(f - 32) * 5 / 9 * 1000` and `value / 1000.0 * 9 / 5 + 32` appear literally, guarding against an algebraic "tidy-up" |
| `'MilliCelsius exposes no judgement'` | source read: no `normal`, no `fever`, no `isHigh`, no `min`/`max` constant, no `throw` on a range. Safety rule 2 at the source-text level, before N06-T09's `ContentPolicy` scan exists to catch it |
| `'MilliCelsius is const and erases to int'` | `const MilliCelsius(39000)` compiles; a documented note that it is indistinguishable at runtime from `Grams(39000)` |
| **property** `'fromFahrenheit/inFahrenheit round-trips at 1 dp'` | `glados`, over `double` restricted to 95.0…115.0 — decision #118's scope. If `flutter pub get` reddens, delete the property layer, not the pin (`12` §10.6) |

## 6. Constraints that bind this task

- **The five safety rules** — rule 2 (never give veterinary advice), held at **caught by a test on the source text**. The type converts and does nothing else; the moment it acquires a band, a label or a `bool`, the app is originating a clinical number. Rule 4 rides along at **unconstructible**: integer canonical storage is what stops 44% of Fahrenheit entries being rewritten by the storage decision alone.
- **`layer.domain`** — `dart:*`, `package:meta`, `package:collection`, `lib/domain/` only.
- **Do not touch the schema** — open question 11 is open; `05` §5.2 forbids the column until it is answered, and N07 owns the column if it ever ships.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'a temperature entered in °F round-trips through MilliCelsius without drifting'` passes, and was seen to fail first for the stated reason
- [ ] storage is integer milli-Celsius
- [ ] conversion happens only at the display edge
- [ ] the round trip is exact across the plausible range
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/temperature_test.dart
fvm flutter test test/domain/units test/domain/units_test.dart      # T06 still green
TZ=Pacific/Chatham fvm flutter test test/domain/temperature_test.dart
dart analyze lib/domain/units/milli_celsius.dart
grep -rn 'temperature' lib/core/db/ || echo 'no temperature column — correct, open question 11'
dart run tool/check_policy.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): MilliCelsius as canonical integer temperature`

# N04-T03 — `PartialDate` — a year, maybe a month, never silently widened

| | |
|---|---|
| **Epic** | [N04 — Domain: time and units](epic.md) · `00-README` §9 step 2 (1 of 3) |
| **Task** | 3 of 8 |
| **Depends on** | N04-T02 |
| **Commit** | one commit · `feat(domain): PartialDate, which never widens` |

## 1. Why this task exists

A ewe's date of birth is often *"2022"* and sometimes *"spring 2022"*. `PartialDate`
represents exactly that and refuses to become a `LocalDate`. The type is the mechanism: there is no
lossy conversion to call.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §2.2 (`Ewe.date_of_birth` row + the paragraph after the table) | the three stored shapes, the three-way `GLOB`, the exposed members, and *"a length check alone is not enough: `'20x6'` has length 4"* |
| `docs/engineering/05-domain-correctness.md` | §7.1, §7.5 | safety rule 4 at the **unrepresentable** level, and why a helpful widening is still a silent correction |
| `docs/engineering/CONVENTIONS.md` | §2.2 | `extension type const PartialDate._(String iso)`; `PartialDate.parse`; `int get year`, `int? get month`, `LocalDate? get exactDate` |
| `docs/engineering/05-domain-correctness.md` | §2.5 | `PartialDateConverter` is built over this strict parse — the file is N07's, the shape is fixed here |
| `docs/research/00-tech-decisions.md` | §2.E #29, #55 | civil dates are `TEXT`; the `normalize*` ban is on functions that return a corrected domain value |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-domain` | the value type and its total ordering against an incomplete peer |
| `shed-safety-rules` | silently widening a partial date is a §12.4 silent correction wearing a helpful face |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/time/partial_date_test.dart`
- **Test** — `'a PartialDate with no month cannot be read as a LocalDate'`
- **Why it is red today** — nothing represents an incomplete date, so it would be stored as `2022-01-01`.

```dart
// the assertion, spelled out — it is the whole point of the type
final p = PartialDate.parse('2022');
expect(p.year, 2022);
expect(p.month, isNull);
expect(p.exactDate, isNull);   // NOT LocalDate(2022, 1, 1)
```

```bash
fvm flutter test test/domain/time/partial_date_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the **extension type over the ISO
prefix string** (CONVENTIONS §2.2 fixes the shape; it is not a sealed class), its three-way strict
parse, its total ordering, its display form, and **no widening path**. `exactDate` returns
`LocalDate?`, and the only non-null case is the full `'YYYY-MM-DD'` form.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 step 2 (domain) and step 7 (tests). Step 1 skipped — `ewes.date_of_birth` and its
three-way `GLOB` `CHECK` are N07's, and `PartialDateConverter` is N07's too. What this task fixes is
the *shape* they must both match. Say so in the commit message.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `test/domain/time/partial_date_test.dart` | new | The anchor, written first |
| 2 | `lib/domain/time/partial_date.dart` | new | The whole task. Imports `local_date.dart` for the `LocalDate?` return; `local_date.dart` learns nothing about it |
| 3 | `lib/domain/time/local_date.dart` | **read, not touched** | Confirm it contains no occurrence of the string `PartialDate` — N04-T02's anchor already asserts this, and this task must not be the one that adds one |

### 5.2 The signature

CONVENTIONS §2.2 is binding: `extension type const PartialDate._(String iso)`, private
representation constructor, `PartialDate.parse`, and the three accessors. The three stored shapes are
`05` §2.2's, and they are exactly the three the schema's `GLOB` `CHECK` accepts:

```
'YYYY'         e.g. '2022'          GLOB '[0-9][0-9][0-9][0-9]'
'YYYY-MM'      e.g. '2022-03'       GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]'
'YYYY-MM-DD'   e.g. '2022-03-14'    GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
```

```dart
// lib/domain/time/partial_date.dart
/// A date known to the year, sometimes to the month, occasionally to the day.
/// A ewe's date of birth is almost never known exactly. This is a real state,
/// not a missing value, and it is NEVER padded to 1 January (safety rule 4).
extension type const PartialDate._(String iso) {
  /// Strict, three-way. Throws rather than coercing.
  factory PartialDate.parse(String s) { … }

  /// Always known.
  int get year;

  /// Null when the month was never recorded. Never 1 as a stand-in.
  int? get month;

  /// Non-null ONLY for the full 'YYYY-MM-DD' form. There is no other way to
  /// get a LocalDate out of a PartialDate, and there must never be one.
  LocalDate? get exactDate;

  /// Total. Ties on the known prefix are broken by precision, least-precise
  /// first: '2022' < '2022-03' < '2022-03-14' < '2022-04'.
  int compareTo(PartialDate o);

  /// '2022' / 'March 2022' / '14 March 2022' — never invents a month or a day.
  String get display;
}
```

`display` is the one member CONVENTIONS §2.2 does not enumerate and `05` §2.2 does not print. It is
required by this task's Definition of Done (*"the display form never invents a month"*) and by
`07-screens.md`'s ewe card. Keep it in the domain only because it is a **structural** rendering —
which fields exist — and not a locale-dependent one; the `d MMM y` formatting of the exact case
belongs to `lib/core/ui/formatters.dart` (D4). If that reads as a stretch during review, the
correct resolution is to move `display` out, not to widen `exactDate`.

### 5.3 The details that are easy to get wrong

1. **`exactDate` returning `LocalDate(year, month ?? 1, day ?? 1)` is the bug this whole type exists
   to prevent.** It is one line, it reads as tidy null-safety hygiene, and it turns *"born sometime in
   2022"* into *"born 1 January 2022"* on every ewe card, every export and every age calculation,
   forever. It is `05` §7.1's rule 4 wearing a helpful face. The type is the mechanism: with
   `exactDate` returning `LocalDate?`, there is **no lossy conversion to call**.
2. **A length check is not a validation.** `'20x6'` has length 4 and is not a year. `05` §2.2 says so
   in as many words. Parse by shape *and* by content: match the three `RegExp`s, then validate the
   month is 1..12, then — for the full form — delegate to `LocalDate.parse` so an impossible day is
   rejected by the code that already knows how.
3. **`'2022-3'` must throw.** Zero-padding is not cosmetic here: the `GLOB` in the schema is a
   character-class match and `'2022-3'` fails it, so an unpadded value is unstorable. Worse, the
   ordering is lexical over the prefix, and one unpadded value sorts `'2022-3'` after `'2022-12'`.
4. **Ordering is total and its tie-break is a decision, not an accident.** `'2022'` and `'2022-03'`
   share a known prefix. Rank the **less precise first**: `'2022' < '2022-03' < '2022-03-14' <
   '2022-04'`. Write the rule in the doc comment, and pin it in the test — because the alternative
   (equal, then unstable) makes a flock list reorder itself between builds under randomised test
   ordering.
5. **`display` never invents.** `'2022'` renders as `2022`, not `Jan 2022`, not `2022-01-01`, not
   `2022-??-??`. An em-dash or a `?` placeholder is worse than the bare year: it reads as missing data
   rather than as a fact recorded at the precision it was known.
6. **There is no `PartialDate.of(Instant)` and no `PartialDate.fromLocalDate`.** Narrowing is as
   banned as widening in v1 — nothing in the app has a reason to throw away precision it already has,
   and a narrowing constructor is a lossy conversion sitting one autocomplete away from the widening
   one.
7. **Follow N04-T02's verdict on the private representation constructor.** If
   `extension type const LocalDate._(String iso)` had to fall back to a public representation
   constructor, this file falls back the same way, in the same commit style, and `PartialDate.parse`
   is not weakened either. Two files disagreeing on that spelling is a review finding.
8. **`compareTo` is a plain method, not `Comparable`.** Same reason as `Instant` (N04-T01 §5.3.1): an
   extension type may only `implements` a supertype of its representation, and `String` implements
   `Comparable<String>`, not `Comparable<PartialDate>`.
9. **Nothing here reads a clock.** "Is this ewe over four?" takes `Instant now` as a parameter at the
   call site (D3). There is no `age` getter on this type.

### 5.4 The full test set — `test/domain/time/partial_date_test.dart`

Zone-agnostic. No `@Tags`. Every case below is a fact about strings and integers, so it passes
identically under `TZ=Pacific/Chatham`.

| Case | What it pins |
|---|---|
| `'a PartialDate with no month cannot be read as a LocalDate'` | **the anchor.** `parse('2022')` → `year == 2022`, `month == null`, `exactDate == null` |
| `'the year-month form knows its month and still has no exact date'` | `parse('2022-03')` → `month == 3`, `exactDate == null` |
| `'only the full form yields an exactDate'` | `parse('2022-03-14').exactDate == LocalDate(2022, 3, 14)` |
| `'no member on the type returns a non-null LocalDate from a partial'` | source read of `partial_date.dart`: the only `LocalDate` in the return position is `LocalDate?`, and there is no `??` next to a `LocalDate(` construction |
| `'parse rejects malformed input'` | table: `'20x6'`, `'2022-3'`, `'2022-'`, `'2022-03-'`, `'2022-13'`, `'2022-00'`, `'2022-02-30'`, `'22'`, `'2022/03'`, `''`, `'2022-03-14T00:00'` — all throw |
| `'parse accepts every real boundary'` | `'2022'`, `'2022-01'`, `'2022-12'`, `'2024-02-29'`, `'0001-01-01'` |
| `'ordering is total and least-precise-first'` | sort `['2022-04', '2022-03-14', '2022', '2022-03', '2021-12-31']` and assert the exact order; assert `compareTo` is antisymmetric over every pair in that list |
| `'ordering never throws on a mixed-precision list'` | shuffle the same list ten times with a fixed seed and assert the sorted result is identical each time |
| `'display never invents a month or a day'` | `'2022'` → `2022`; `'2022-03'` → `March 2022`; `'2022-03-14'` → `14 March 2022`. Assert the first contains no `Jan` and no `01` |
| `'equality comes from the representation'` | `parse('2022') == parse('2022')`; `parse('2022') != parse('2022-01')` — *"the year 2022"* and *"January 2022"* are different facts |
| `'the three shapes are exactly the three the schema GLOB accepts'` | the three accepted forms, listed literally, as the executable form of the contract N07's `CHECK` must match |
| `'a partial date is unaffected by the ambiguous hour'` | `parse('2026-10-25')` has the same `iso`, `year`, `month` and `exactDate` regardless of process zone — the case that proves this type carries no instant, and the reason it needs no `uk-zone` tag while every other time type in this epic does |

## 6. Constraints that bind this task

- **The five safety rules** — rule 4 (never silently correct an entry), held at **unrepresentable**. There is no method that returns a non-null `LocalDate` from a year-only value, so the 1-January bug has no call site. If a later change adds one, rule 4 drops to *documented* on this type, which `05` §7.1 counts as deleted.
- **`layer.domain`** — `dart:*`, `package:meta`, `package:collection`, `lib/domain/` only.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'a PartialDate with no month cannot be read as a LocalDate'` passes, and was seen to fail first for the stated reason
- [ ] no method returns a `LocalDate` from a partial
- [ ] ordering is total and documented for the ambiguous cases
- [ ] the display form never invents a month
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/time/partial_date_test.dart
fvm flutter test test/domain/time            # T01 + T02 + T03 together
TZ=Pacific/Chatham fvm flutter test test/domain/time
dart analyze lib/domain/time/partial_date.dart
dart run tool/check_policy.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): PartialDate, which never widens`

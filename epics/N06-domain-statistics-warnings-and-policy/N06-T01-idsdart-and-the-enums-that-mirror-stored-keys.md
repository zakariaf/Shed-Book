# N06-T01 — `ids.dart` and the enums that mirror stored keys

| | |
|---|---|
| **Epic** | [N06 — Domain: statistics, warnings and policy](epic.md) · `00-README` §9 step 2 (3 of 3) |
| **Task** | 1 of 11 |
| **Depends on** | N05-T05 |
| **Commit** | one commit · `feat(domain): ids and the enums that mirror stored keys` |

## 1. Why this task exists

Extension-type ids for every entity, plus `BirthType` with `expectedLambCount`
(**null** for `quintPlus`, never a guess), `LambingEase` as the ordinal ruled in N00-T04, `Sex` and
`FosterOutcome`. Every enum mirrors a stored key exactly, because a renamed enum member is a silent
data migration.

Sixteen ids exist here even though sixteen tables do not exist until N07. That is deliberate: R33
says a bare `int` never crosses a repository, controller, route-helper or provider-family boundary,
and the way that rule gets broken is a repository written in N14 against an id type that was never
created. Create all sixteen now and the violation is a compile error rather than a habit.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/CONVENTIONS.md` | §2.1, §2.9, R5, R15, R33, R44, R45, R46, R64 | the sixteen id names, the four enums, their stored keys, and what may not live in this folder |
| `docs/engineering/05-domain-correctness.md` | §1.1, §1.2, §2.3, §7.5 | the file map, the four import bans, extension-type erasure, and `expectedLambCount`'s null arm |
| `docs/engineering/03-data-model-and-schema.md` | §5.4, §5.5, §7 | the stored codes `lambings.declared_birth_type` 1..5, `lambs.sex` `('f','m','unknown')`, `foster_events.outcome` |
| `epics/N00-decisions-rulings-and-the-calendar/N00-T04-rule-the-four-schema-shaped-questions.md` | — | the ruling that `LambingEase` stays a 1..5 ordinal |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-domain` | ids and enums are pure-Dart value types and this is their tier |
| `shed-conventions` | §2 already names each of these; this task writes what it named |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/ids_test.dart`
- **Test** — `'expectedLambCount is null for quintPlus and never zero'`
- **Why it is red today** — no id types exist, so every repository signature would take a bare `String`.

```bash
fvm flutter test test/domain/ids_test.dart   # expect: failing, for the reason above
```

Make the assertion say both halves out loud, because `expect(x, isNull)` alone also passes for a
function that returns null for everything:

```dart
expect(expectedLambCount(BirthType.quintPlus), isNull,
    reason: 'quad-or-more is open-ended: a contradiction is UNDEFINED, not false');
expect(expectedLambCount(BirthType.twin), 2);
expect(BirthType.quintPlus.code, 5,
    reason: 'the stored code is 5; the expected count is not');
```

**Green.** The minimum code that passes, and nothing beyond it — the extension types, the four enums, and the `expectedLambCount` table with its null
arm.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8's order starts at the schema. **This task skips step 1 entirely and says so in the
commit message: it stores nothing.** The schema arrives in N07, and the whole point of `00-README`
§9's ordering is that these types compile before a database exists. Steps 3–7 (data, wiring,
controller, UI, ARB) are not reached either. What is left is step 2 — `lib/domain/` — and the tests.

### 5.1 The files, in order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/domain/ids.dart` | **New.** The sixteen `extension type const …Id(int value)` declarations from `CONVENTIONS` §2.1, and nothing else. No `package:uuid`: `String newUid()` is `lib/core/db/uid.dart`'s, and `lib/domain/` may not import that package (R15, layer rule 1) |
| 2 | `lib/domain/birth_type.dart` | **New.** `enum BirthType` carrying `final int code` (03's stored codes 1..5) **and** the top-level `int? expectedLambCount(BirthType)` — one file, both, per R46. 05 owns the semantics, 03 owns the codes |
| 3 | `lib/domain/lambing_ease.dart` | **New.** `extension type const LambingEase(int code)` validated to 1..5 and **nothing else** (R44). No description strings: they are `vocab_terms` keys `ease_1`…`ease_5` with ARB messages, and holding them here would need `AppLocalizations`, which layer rule 1 forbids |
| 4 | `lib/domain/sex.dart` | **New.** `enum Sex { female('f'), male('m'), unknown('unknown') }` + `fromKey` (R45) |
| 5 | `lib/domain/foster_outcome.dart` | **New.** `sealed class FosterOutcome` with three variants, each carrying its stored key (R64) |
| 6 | `test/domain/ids_test.dart` | **New.** The anchor, plus the erasure assertion in §5.4 |
| 7 | `test/domain/birth_type_test.dart` · `lambing_ease_test.dart` · `sex_test.dart` · `foster_outcome_test.dart` | **New.** One per file under test (`CONVENTIONS` §4.1), each freezing its stored keys |

The anchor test is `test/domain/ids_test.dart`; it is written before any of them. It carries a
`BirthType` assertion rather than an id assertion because it is this epic's *first* red and
`ids.dart` is the first file everything else imports; the rest of the birth-type cases live in
`test/domain/birth_type_test.dart`, where §4.1 puts them.

### 5.2 The signatures

```dart
// lib/domain/ids.dart — R5. The representation getter is always `.value`.
extension type const EweId(int value) {}
extension type const EweSeasonId(int value) {}
extension type const LambingId(int value) {}
extension type const LambId(int value) {}
extension type const FosterEventId(int value) {}
extension type const CareEventId(int value) {}
extension type const EweObservationId(int value) {}
extension type const PenId(int value) {}
extension type const PenOccupancyId(int value) {}
extension type const TreatmentId(int value) {}
extension type const TreatmentWithdrawalId(int value) {}
extension type const ReminderId(int value) {}
extension type const NoteId(int value) {}
extension type const MediaAssetId(int value) {}
extension type const SeasonId(int value) {}
extension type const VocabTermId(int value) {}
```

```dart
// lib/domain/birth_type.dart — R46. This file holds the enum AND the function.
enum BirthType {
  single(1), twin(2), triplet(3), quad(4), quintPlus(5);

  const BirthType(this.code);
  /// The stored code in `lambings.declared_birth_type`. Frozen forever.
  final int code;

  static BirthType fromCode(int c) => BirthType.values.firstWhere((t) => t.code == c,
      orElse: () => throw FormatException('Unknown birth type code', '$c'));
}

/// null for quintPlus is load-bearing: "quad or more" is open-ended, so a
/// contradiction is UNDEFINED, not false. Encoding it as 5 would produce a
/// false warning for every set of sextuplets.
int? expectedLambCount(BirthType t) => switch (t) {
      BirthType.single    => 1,
      BirthType.twin      => 2,
      BirthType.triplet   => 3,
      BirthType.quad      => 4,
      BirthType.quintPlus => null,
    };
```

```dart
// lib/domain/sex.dart — R45. NULL in the column is NOT Sex.unknown.
enum Sex {
  female('f'), male('m'), unknown('unknown');
  const Sex(this.key);
  final String key;
  static Sex fromKey(String k) => Sex.values.firstWhere((s) => s.key == k,
      orElse: () => throw FormatException('Unknown sex', k));
}
```

```dart
// lib/domain/foster_outcome.dart — R64. sealed, three variants, three stored keys.
sealed class FosterOutcome {
  const FosterOutcome();
  String get key;
}
final class ToEwe extends FosterOutcome {
  const ToEwe(this.ewe);
  final EweId ewe;
  @override String get key => 'to_ewe';
}
final class ToBottle extends FosterOutcome {
  const ToBottle();
  @override String get key => 'to_bottle';
}
final class RemovedUnknown extends FosterOutcome {
  const RemovedUnknown();
  @override String get key => 'removed_unknown';
}
```

`LambingEase` is `extension type const LambingEase(int code)` whose validating entry point rejects
anything outside 1..5. An extension type cannot have a private *generative* constructor, so the
validation is a factory over the public representation constructor — the same shape `LocalDate` uses
in N04-T02, and with the same caveat: run `dart analyze` on the file in **this** commit rather than
assuming the spelling resolves on Dart 3.12.2.

### 5.3 The details that are easy to get wrong

- **Extension types erase at run time.** `EweId(3) == LambId(3)` is `true`, `EweId(3) is int` is
  `true`, and `switch (x) { case EweId(): … }` does not discriminate. Never key one `Map` with two id
  types, never `is`-check an id, and never serialise one expecting the type to survive.
  `05-domain-correctness.md` §2.3 states the rule this follows from: build extension types only for
  *canonical* values.
- **`code` is not `expectedLambCount`.** `BirthType.quintPlus.code == 5` while
  `expectedLambCount(BirthType.quintPlus) == null`. Reaching for `.code` at T03's validation site is
  the single mistake this design exists to prevent: it produces a false `birthTypeLambCountMismatch`
  on every set of sextuplets, which is the app inventing a fact — safety rule 4 with extra steps.
- **`Sex.unknown`'s key is the word `unknown`, not `'u'`**, and a SQL `NULL` is not it. `NULL` means
  "not recorded"; `unknown` means "looked, could not tell". Collapsing the two is exactly what the
  column's nullability exists to prevent (R45).
- **`lambing_ease.dart` holds no prose.** If you find yourself typing "unassisted" into this file,
  stop: `03` §10.1 puts `ease_1`…`ease_5` in `vocab_terms` and `10` §8.6 puts their labels in the
  ARB. The `intl` import you would then need is banned by layer rule 1 and the gate will say so.
- **`setRearingDam(lambId, eweId?)` is a banned signature** (R64). It is the shape you will reach for
  the first time you use `FosterOutcome`, and a nullable ewe id merges "bottle" (null by intent) with
  "not recorded" (null by omission). T06's rearing-credit numbers differ between the two.
- **`ids.dart` holds ids only** (R5). Anything you are tempted to put beside them — a uid generator,
  a `parseId`, a `toJson` — belongs elsewhere, and `package:uuid` is banned in this layer outright.
- **`extension type const EweId(int value) {}` needs the empty braces.** A trailing `;` in place of
  the body does not compile.
- **Do not try `implements Comparable`.** `extension type EweId(int) implements Comparable<EweId>`
  fails with `extension_type_implements_not_supertype`, because `int` implements `Comparable<num>`.
  `05` §2.3 documents this wall for `Instant`; it is the same wall. If ids need sorting, sort on
  `.value`.

### 5.4 The full test set

| File | Cases |
|---|---|
| `test/domain/ids_test.dart` | **anchor:** `'expectedLambCount is null for quintPlus and never zero'` · `'every id exposes .value and nothing else'`, over all sixteen · `'two id types with the same value are equal at run time — extension types erase'`, asserted so nobody builds on the opposite |
| `test/domain/birth_type_test.dart` | `'the five stored codes are 1..5 and are frozen'` · `'expectedLambCount is 1, 2, 3, 4, null across the five members'` · `'fromCode throws FormatException on 0 and on 6'` |
| `test/domain/lambing_ease_test.dart` | `'1..5 construct'` · `'0 and 6 throw'` · `'LambingEase carries no label'` — asserted by the *absence* of any string member; put the reason in the test so the next reader knows the absence is deliberate (R44) |
| `test/domain/sex_test.dart` | `'the three stored keys are f, m and unknown, in that order'` · `'fromKey throws on an unrecognised key'` · `'unknown is a value, not the absence of one'` |
| `test/domain/foster_outcome_test.dart` | `'the three stored keys are to_ewe, to_bottle and removed_unknown'` · `'an exhaustive switch over FosterOutcome compiles with no default arm'` — the compile *is* the assertion, and adding a fourth variant later must break here |

**No `uk-zone` case.** Nothing in this task carries a time, so there is nothing to assert in the
ambiguous 01:00–01:59 hour; the first time-shaped work in this epic is T06's lambing spread. Say so
in the commit message rather than leaving a reviewer to wonder.

## 6. Constraints that bind this task

- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Stored keys are a contract.** Every string and integer in this diff is written into SQLite, the CSV and the JSON backup, and N07 freezes them one epic later.

## 7. Definition of Done

- [ ] `'expectedLambCount is null for quintPlus and never zero'` passes, and was seen to fail first for the stated reason
- [ ] ids are extension types, never `String` in a signature
- [ ] every enum member's stored key is asserted against `CONVENTIONS §2`
- [ ] `quintPlus` has no expected count
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/ids_test.dart
fvm flutter test test/domain/birth_type_test.dart test/domain/lambing_ease_test.dart \
                 test/domain/sex_test.dart test/domain/foster_outcome_test.dart
grep -rn "package:uuid\|package:flutter\|package:drift\|package:clock" lib/domain/   # expect: nothing
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): ids and the enums that mirror stored keys`

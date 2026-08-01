# N05-T01 — `sealed WithdrawalPeriod` and its one entry point

| | |
|---|---|
| **Epic** | [N05 — Domain: withdrawal](epic.md) · `00-README` §9 step 2 (2 of 3) |
| **Task** | 1 of 5 |
| **Depends on** | N04-T08 |
| **Commit** | one commit · `feat(domain): sealed WithdrawalPeriod with one entry point` |

## 1. Why this task exists

A sealed type with a **private generative constructor** and exactly one public entry
point, `WithdrawalDays.asEnteredByUser`. §12.1 pushed to *unconstructible*: there is no expression
anywhere in the language that produces a withdrawal period the user did not type.

The alternative that looks reasonable and is not is `int? withdrawalDays`. It is not merely weak, it
is **lossy** (05 §3.1): `withdrawalDays ?? 0` is one keystroke away in a null-safety cleanup and
*reads as tidy code*; `0` is a real label value, so a nullable int cannot tell "the label says zero"
from "I did not look", which makes wrong code indistinguishable from correct code; and *"not
applicable"* — the label states no withdrawal for this species or route — is a third distinct fact
that collapses too. No amount of care at call sites recovers information the type discarded, so the
information is never discarded.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §3.1–§3.2 | why `int?` is lossy, the exact type, the four stacked mechanisms, and the milkings rule |
| `docs/engineering/CONVENTIONS.md` | §1, §2.7 | the file path, and every member name and signature spelled exactly |
| `docs/research/00-tech-decisions.md` | §2 #51, #52 | the sealed type over an `extension type`, and **two gates and no more** |
| `shed-book-spec.md` | §7.5, §12.1 | never default a medicine withdrawal period |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-withdrawal` | medicines, withdrawal days and clear dates are its subject |
| `shed-safety-rules` | §12.1 is the rule and unconstructible is the level it must reach |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/withdrawal_has_no_default_test.dart`
- **Test** — `'WithdrawalPeriod has no public generative constructor'`
- **Why it is red today** — the type does not exist; any int could become a withdrawal period.

```bash
fvm flutter test test/policy/withdrawal_has_no_default_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the sealed type, the private constructor, the single factory whose name says where the
number came from. The assertion is over the source text of **one named file**,
`lib/domain/withdrawal/withdrawal_period.dart`: `WithdrawalDays` declares exactly one generative
constructor and it is `WithdrawalDays._`; there is no `factory WithdrawalDays(`, no
`const WithdrawalDays(`, and the file declares no `part` and is named by no `part of`.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8's order

`00-README` §8 step 1 is **skipped and the commit message says so**: the `treatment_withdrawals`
table is N07-T05's and the schema half of this gate is N07-T08's. This task stores nothing. Steps 3
to 7 — data, wiring, controller, UI, ARB — are not reached either; the first screen that renders a
withdrawal is N20-T02, fifteen epics away. What this task touches is step 2 (domain) and step 7
(tests), and that is the whole diff.

| # | File | New or re-opened | What changes in it, and why |
|---|---|---|---|
| 1 | `test/policy/withdrawal_has_no_default_test.dart` | **new** | The anchor. It is written first and it is the file the whole §12.1 story accumulates in: N05-T04 adds the source half, N07-T08 adds the schema half against `drift_schemas/drift_schema_v1.json`. Give it a file docstring naming all three halves and their tasks, so the second person to open it does not assume it is finished. |
| 2 | `lib/domain/withdrawal/withdrawal_period.dart` | **new** | `enum WithdrawalTarget` with its frozen storage keys, `sealed class WithdrawalPeriod`, and the three final subclasses. Pure Dart: no `package:flutter`, no `package:drift`, no Riverpod, no `package:intl`, **no `package:clock`** (05 §1.2 bans D1–D4, `CONVENTIONS` §1.1 layer rule 1). |
| 3 | `test/domain/withdrawal/withdrawal_period_test.dart` | **new** | The mirror test (`CONVENTIONS` §4.1: a test mirrors the file under test with a `_test.dart` suffix). Everything about *behaviour* lives here; only the "no public generative constructor" property lives in `test/policy/`, because that one is a claim about the artefact rather than about a value. |

### 5.2 The signatures

Exactly as `05-domain-correctness.md` §3.2 and `CONVENTIONS.md` §2.7 spell them. This is one of the
few tasks where the signature *is* the deliverable, so it is reproduced in full and it is not open
to improvement:

```dart
// lib/domain/withdrawal/withdrawal_period.dart

/// What the withdrawal applies to. One bottle routinely prints two different
/// numbers; one field per treatment is a modelling bug that becomes a food
/// safety bug on a dairy flock.
enum WithdrawalTarget {
  meat('meat'),
  milk('milk');

  const WithdrawalTarget(this.key);

  /// Stable storage/export key. Never the localised label.
  final String key;

  static WithdrawalTarget fromKey(String k) =>
      WithdrawalTarget.values.firstWhere((t) => t.key == k,
          orElse: () => throw FormatException('Unknown withdrawal target', k));
}

/// A withdrawal period is a THREE-STATE value.
sealed class WithdrawalPeriod {
  const WithdrawalPeriod();
}

/// The user read a number off the bottle. [days] MAY be 0 — that is a real
/// label value, not a fallback.
final class WithdrawalDays extends WithdrawalPeriod {
  final int days;
  final WithdrawalTarget target;

  /// Private. No default. No optional parameter. No `int days = 0`.
  const WithdrawalDays._(this.days, this.target);

  /// The ONLY way to build one. Throws rather than coercing.
  factory WithdrawalDays.asEnteredByUser({
    required int days,
    required WithdrawalTarget target,
  }) {
    if (days < 0) throw ArgumentError.value(days, 'days', 'must be >= 0');
    if (days > 1000) throw ArgumentError.value(days, 'days', 'implausible');
    return WithdrawalDays._(days, target);
  }
}

/// The label explicitly states no withdrawal applies. Distinct from zero days
/// and distinct from "I did not look".
final class WithdrawalNotApplicable extends WithdrawalPeriod {
  final WithdrawalTarget target;
  const WithdrawalNotApplicable(this.target);
}

/// The user deliberately skipped it. The app must never invent one, and must
/// never show a countdown or a clear date for this state.
final class WithdrawalNotRecorded extends WithdrawalPeriod {
  const WithdrawalNotRecorded();
}
```

Four mechanisms are stacked, strongest first, and the diff must keep all four:

| Mechanism | Level | What it stops |
|---|---|---|
| `sealed` + exhaustive `switch` | unrepresentable | forgetting the not-recorded case at any call site |
| private `WithdrawalDays._` | unconstructible | any construction path that is not the named factory |
| **required named** `days:`, no default | unconstructible | `WithdrawalDays()` compiling at all |
| throwing on `days < 0` | unconstructible | a coerced value entering the system quietly |

### 5.3 The details that are easy to get wrong

- **The anchor test's name is broader than its assertion, deliberately.** Two of the three
  subclasses *do* have public generative constructors — `const WithdrawalNotApplicable(this.target)`
  and `const WithdrawalNotRecorded()` — and so does the base, `const WithdrawalPeriod()`. That is
  correct: `sealed` already stops the base being instantiated or extended outside its library, and
  neither marker state carries a number anybody could be wrong about. **Only `WithdrawalDays` is
  locked**, because it is the only one holding a figure read off a bottle. A test that asserts "no
  subclass has a public constructor" is a test that gets weakened the first time somebody needs
  `const WithdrawalNotRecorded()` — which is on the very next task.
- **`_` is library-private, not class-private.** Anything else declared in
  `withdrawal_period.dart`, or in a `part` of it, can call `WithdrawalDays._`. So the file holds
  those declarations and nothing else, declares no `part`, and is named by no `part of`. Assert
  that in the anchor test; it costs one line and it is the only hole left in the mechanism.
- **`0` must construct.** The guard band is `days < 0` throws and `days > 1000` throws; zero is
  inside it and is a real, storable value. A test that only proves the throws has proved half the
  rule, and the wrong half.
- **`1000` is an implausibility guard, not a cap and not a default.** It **throws**; it never
  clamps. Clamping would be the app silently correcting an entry (§12.4) on top of originating a
  number (§12.2).
- **`fromKey` throws `FormatException`; it never returns a fallback.** A `firstWhere` whose
  `orElse` returns `WithdrawalTarget.meat` is the same defect as `?? 0`, one level up.
- **The keys are frozen the moment N07 writes the table.** `'meat'` and `'milk'` become
  `treatment_withdrawals.target` and `CHECK (target IN ('meat','milk'))`, then a CSV column, then a
  JSON backup field. They are never localised, never title-cased, never plural.
- **`milk` ships in v1 even though open question 10 is open.** *Is the target market ever a dairy
  flock?* is unanswered; `WithdrawalTarget.milk` is in the type and in the schema regardless,
  because shipping it now is free and retrofitting it is a migration. N00-T04 is the ruling.
- **`WithdrawalDays` cannot express milkings and must never be used to.** VICH states milk periods
  in milkings as well as days, usually on a 12-hour interval. Converting *6 milkings* to *3 days*
  assumes an interval the label did not state — the app originating a number (rule 2) and then
  presenting it as the user's own (rule 4). The v1 rule, in three lines: a label stating only
  milkings is `WithdrawalNotRecorded` for that target, with the number typed verbatim into the
  treatment **note**; the UI shows `WithdrawalUnknown` and offers no conversion, calculator or hint;
  v2 may add a fourth subtype whose interval is **required and user-supplied**, which `sealed` turns
  into a compile-error-guided change at every switch. Put the reason in a comment on the class, not
  in a commit message nobody re-reads.
- **An `extension type` cannot give you a private generative constructor** — which is why this is
  hand-written and not the `extension type` some of the research proposed (decision #51). `freezed`
  is rejected before you even reach its resolution problem: it generates a public constructor and a
  total `copyWith`, and drift is the only generator this project budgets for (decision #16).
- **Extension types erase at runtime.** `Instant` and `LocalDate` from N04 are extension types over
  `int` and `String`; a runtime `is` check cannot tell one from another. It is not a problem in this
  file — which holds neither — and it is why the arithmetic in N05-T02 takes them as parameters
  rather than switching on them.
- **Vocabulary.** *withdrawal period* on first use, *withdrawal* thereafter; never *withholding*,
  never *WHP*, never *"the days"*. The commit message obeys the same rule.

### 5.4 The full test set

`test/policy/withdrawal_has_no_default_test.dart` — the claims about the artefact:

| Test | What it holds |
|---|---|
| `'WithdrawalPeriod has no public generative constructor'` | **the anchor.** `WithdrawalDays`'s only generative constructor is `WithdrawalDays._`; there is no `factory WithdrawalDays(` and no `const WithdrawalDays(` |
| `'withdrawal_period.dart declares no part and is named by no part of'` | the library-private hole, closed |
| `'WithdrawalDays.asEnteredByUser is the only factory on WithdrawalDays'` | a second factory is a second entry point, whatever it is called |

`test/domain/withdrawal/withdrawal_period_test.dart` — the behaviour, table-driven:

| Test | Case |
|---|---|
| `'asEnteredByUser accepts 0 days, because 0 is a real label value'` | `days: 0` constructs and reports `days == 0` |
| `'asEnteredByUser throws on a negative day count rather than coercing it'` | `days: -1` throws `ArgumentError` |
| `'asEnteredByUser throws above the implausible band and never clamps'` | `days: 1001` throws; `days: 1000` constructs |
| `'a switch over WithdrawalPeriod needs three arms and no default clause'` | a switch **expression** covering all three subtypes compiles and is total |
| `'WithdrawalTarget keys are frozen at meat and milk'` | `values.map((t) => t.key)` is exactly `['meat', 'milk']` |
| `'fromKey round-trips every member and throws FormatException on anything else'` | `'meat'`, `'milk'`, then `'MEAT'` and `''` throw |
| `'WithdrawalNotApplicable carries its target and WithdrawalNotRecorded carries nothing'` | two marker states, and the fact that they are two different facts |
| `'one bottle with a meat figure and no milk figure is two different states'` | `WithdrawalDays` for meat beside `WithdrawalNotRecorded` — the modelling case the child table exists for |

**No `uk-zone` case, and that is not an omission.** This task computes no date, holds no `Instant`
and reads no clock, so there is nothing for the ambiguous 01:00–01:59 hour to bite. The DST cases
arrive with `clearDateFor` in the next task, and the first one is the 167-hour regression.

## 6. Constraints that bind this task

- **Safety rule §12.1 — never default a medicine withdrawal period.** Held at **unconstructible**
  here (the private constructor and the single named factory) and at **unpersistable** at N07-T05
  (no row means not recorded). A rule that drops to merely *documented* has been deleted, whatever
  the prose says.
- **The four import bans (05 §1.2).** `lib/domain/**` may not import `package:flutter`,
  `package:drift` or `lib/data/`, may not import **`package:clock`**, and may not import
  `package:intl` or `AppLocalizations`. The `gate` job proves it as rule `layer.domain`.
- **Two gates and no more (decision #52).** Do not add a `check_policy` row for this type and do not
  invent a third proof. The sealed type is the mechanism; the tests are its evidence.
- **No medicines lookup table, ever** — no product database, no suggestion, no allowlist, no
  learned default (decision-record §5.3 and spec §11).
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'WithdrawalPeriod has no public generative constructor'` passes, and was seen to fail first for the stated reason
- [ ] no public generative constructor
- [ ] the only entry point is named `asEnteredByUser`
- [ ] `0` is a real, storable value distinct from *not recorded*
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/withdrawal_has_no_default_test.dart
fvm flutter test test/domain/withdrawal/withdrawal_period_test.dart
fvm dart tool/check_policy.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): sealed WithdrawalPeriod with one entry point`

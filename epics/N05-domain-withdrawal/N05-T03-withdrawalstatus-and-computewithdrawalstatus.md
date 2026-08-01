# N05-T03 — `WithdrawalStatus` and `computeWithdrawalStatus`

| | |
|---|---|
| **Epic** | [N05 — Domain: withdrawal](epic.md) · `00-README` §9 step 2 (2 of 3) |
| **Task** | 3 of 5 |
| **Depends on** | N05-T02 |
| **Commit** | one commit · `feat(domain): WithdrawalStatus and computeWithdrawalStatus` |

## 1. Why this task exists

Three arms and no fourth: `ClearsOn`, `NoWithdrawal`, `WithdrawalUnknown`. A treatment
with no `treatment_withdrawals` row is `WithdrawalUnknown` — **not** *clears today*, not zero, not
blank. The absent row is the fact.

The input type is sealed, so `LocalDate? clearDate` as an output would reintroduce exactly the null
the input type just eliminated. Sealing the output is what makes the countdown widget's signature
possible: it takes a `ClearsOn`, never a `WithdrawalStatus`, so rendering a countdown for a period
nobody entered is *type-impossible* rather than merely forbidden.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §3.3–§3.5 | the row-to-state mapping, the sealed output, and the switch that joins them |
| `docs/engineering/05-domain-correctness.md` | §3.10 | the three paths that route around the type — repeat, learned defaults, and the soft void |
| `docs/engineering/CONVENTIONS.md` | §2.7 | `ClearsOn(date, elapsesAt, target)` and the two markers, spelled exactly |
| `docs/engineering/06-design-system.md` | §12 | `ShedCountdown`'s three states, and *not recorded* as a first-class one |
| `docs/engineering/07-screens.md` | §10.1, §10.4 | what the Treatments screen does with each arm, and the fan-out per target |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-withdrawal` | the status vocabulary and its display contract |
| `shed-safety-rules` | the missing-row arm is §12.1's unpersistable half |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/withdrawal/status_test.dart`
- **Test** — `'a treatment with no withdrawal row computes WithdrawalUnknown, never ClearsOn today'`
- **Why it is red today** — no status type exists, so a screen would render a blank or a zero.

```bash
fvm flutter test test/domain/withdrawal/status_test.dart   # expect: failing, for the reason above
```

The assertion, sharpened: `computeWithdrawalStatus(administeredAt: anyInstant, period: const
WithdrawalNotRecorded())` is `isA<WithdrawalUnknown>()`, and it is **not** `isA<ClearsOn>()` and not
`isA<NoWithdrawal>()` — the two wrong answers a nullable model would have produced.

**Green.** The minimum code that passes, and nothing beyond it — the sealed status, the pure function over stored inputs, and a test table covering the
absent row, the zero-day row and the ordinary case.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8's order

Step 1 (schema) is **skipped and the commit message says so**. What this task does depend on is the
*shape* N07-T05 will write, because the mapping below is the contract between the two:

| Domain state | Rows for that target |
|---|---|
| `WithdrawalDays(n, target)` | one row, `kind='days'`, `days=n`, `clear_date` set |
| `WithdrawalNotApplicable(target)` | one row, `kind='not_applicable'`, `days IS NULL` |
| `WithdrawalNotRecorded` | **no row** |

| # | File | New or re-opened | What changes in it, and why |
|---|---|---|---|
| 1 | `test/domain/withdrawal/status_test.dart` | **new** | The anchor, and then the whole three-arm table. |
| 2 | `lib/domain/withdrawal/withdrawal_status.dart` | **new** | `sealed class WithdrawalStatus` and its three final subclasses. Imports `time/instant.dart` and `time/local_date.dart` from N04 and `withdrawal_period.dart` from N05-T01 for `WithdrawalTarget`; nothing else. |
| 3 | `lib/domain/withdrawal/clear_date.dart` | **re-opened** (N05-T02 created it) | Add `computeWithdrawalStatus` beside `clearDateFor`. `CONVENTIONS` §1 puts both in this one file — do not start a third file for the switch. |
| 4 | `test/domain/uk_zone/clear_date_dst_test.dart` | **re-opened** (N05-T02 created it) | Add DST-5, which 05 §2.9 writes against `computeWithdrawalStatus` rather than against `clearDateFor`: the status arm is what a screen will actually call, so the zone regression is pinned at that level too. |

### 5.2 The signatures

```dart
// lib/domain/withdrawal/withdrawal_status.dart
sealed class WithdrawalStatus { const WithdrawalStatus(); }

/// The animal is clear for the WHOLE of [date].
final class ClearsOn extends WithdrawalStatus {
  final LocalDate date;

  /// The exact instant the label's period elapses, shown next to the date so
  /// the shepherd can check our arithmetic against their own.
  final Instant elapsesAt;
  final WithdrawalTarget target;
  const ClearsOn(this.date, this.elapsesAt, this.target);
}

final class NoWithdrawal      extends WithdrawalStatus { const NoWithdrawal(); }
final class WithdrawalUnknown extends WithdrawalStatus { const WithdrawalUnknown(); }
```

```dart
// lib/domain/withdrawal/clear_date.dart — added beside clearDateFor
WithdrawalStatus computeWithdrawalStatus({
  required Instant administeredAt,
  required WithdrawalPeriod period,
}) =>
    switch (period) {
      WithdrawalNotRecorded() => const WithdrawalUnknown(),
      WithdrawalNotApplicable() => const NoWithdrawal(),
      WithdrawalDays(:final days, :final target) => () {
          final r = clearDateFor(administeredAt: administeredAt, days: days);
          return ClearsOn(r.date, r.elapsesAt, target);
        }(),
    };
```

### 5.3 The details that are easy to get wrong

- **`ClearsOn`'s constructor is positional, and stays positional.** `const ClearsOn(this.date,
  this.elapsesAt, this.target)` is how `CONVENTIONS` §2.7 and 05 §3.4 both spell it. The reviewer's
  instinct — *"three fields, make them named"* — is a rename of a published signature and needs a
  ruling in `CONVENTIONS` §6, not a commit.
- **The switch is an *expression* with three arms and no `default`, and no `_` wildcard anywhere.**
  A wildcard silently swallows the fourth arm when `WithdrawalMilkings` is proposed in v2, which
  destroys the one property `sealed` was chosen for: adding a subtype must be a compile-error-guided
  change at every call site. This applies at every future call site too, not just here.
- **Three wrong answers for the absent row, all of which look reasonable in isolation.**
  `ClearsOn(today)` says the animal is clear when nobody knows; `NoWithdrawal` says the label stated
  none when nobody looked; a blank cell or an em-dash lets a shepherd read *zero*. The right answer
  is a state with a name: `WithdrawalUnknown` renders as *"Withdrawal not recorded"* with a 60 pt
  *"Add it"* action (05 §3.4), never as an absence.
- **`0` days maps to `ClearsOn`, not to `NoWithdrawal`.** They are different facts: *the label says
  zero* versus *the label says no withdrawal applies to this route or species*. The zero-day
  `ClearsOn` carries tomorrow's date, because the period elapses at the moment of administration and
  today is a partial day.
- **`computeWithdrawalStatus` takes no `now`, and must not learn to.** It answers *what did the
  label say and when does it elapse*, not *is she clear today*. The second question is asked at the
  read edge, in SQL — `w.kind = 'days' AND w.clear_date >= :today` (07 §10.1) — with `today` supplied
  by `appNow()` at the edge. Adding a `now` parameter here would make the status time-varying and
  every cached value wrong at midnight.
- **This function does not read a database and must never be handed a row.** `lib/domain/` may not
  import `package:drift` or `lib/data/` (05 §1.2 D2). The repository maps rows to
  `WithdrawalPeriod` and passes plain values in; a treatment with a meat row and a milk row produces
  **two** statuses, which is why the countdown segment lists two countdowns for one treatment.
- **A soft-voided treatment is excluded upstream and never recomputed.** Decision #69: undo of a
  treatment sets `treatments.voided_at` and the row stays, because it may already have been printed
  into a medicine book handed to a vet. Every *"is she clear?"* query filters `voided_at IS NULL`;
  the withdrawal row, its inputs and its stored `clear_date` are never deleted, blanked or
  recalculated. That is N20-T05's work, but the reason belongs in this file's comment, because this
  is the function somebody will be tempted to call on a voided row.
- **`ClearsOn.elapsesAt` is not decoration.** It is rendered beside the date so the shepherd can
  check the app's arithmetic against their own — *"Clear on Wed 11 Mar · 7 days as entered by you,
  from Tue 3 Mar 20:00, ends Tue 10 Mar 20:00."* Dropping it because "the date is enough" removes
  the only way a user can catch us being wrong.
- **Extension types erase at runtime.** `ClearsOn` holds a `LocalDate` (over `String`) and an
  `Instant` (over `int`); a runtime `is int` or `is String` check will not discriminate them from
  any other extension type over the same representation. Switch on the *sealed* type, never on a
  runtime representation type.
- **The countdown's contract, so you build the right thing for it.** `ShedCountdown` (06 §12,
  N10-T05) has three states — active, clear, **not recorded** — and *"not recorded" is a first-class
  state, never `0`, never blank*. It accepts a `ClearsOn`. If a widget signature ever takes
  `WithdrawalStatus`, that is the defect this task exists to make impossible.
- **`ClearsOn.date` is never rendered all-numeric.** `CONVENTIONS` R60: a human-facing date is
  `d MMM y`, and the withdrawal countdown is the worst possible place to break that rule, because
  the number it renders is the safety-critical one. The formatting is N20's; the constraint is
  recorded here because this is where the value is born.

### 5.4 The full test set

`test/domain/withdrawal/status_test.dart` — one table over the three arms plus the edges:

| Test | Case |
|---|---|
| `'a treatment with no withdrawal row computes WithdrawalUnknown, never ClearsOn today'` | **the anchor.** `WithdrawalNotRecorded` in, `WithdrawalUnknown` out, and neither of the two wrong arms |
| `'WithdrawalNotApplicable computes NoWithdrawal, which is not the same fact as zero days'` | the marker row arm |
| `'a zero-day withdrawal computes ClearsOn tomorrow, not NoWithdrawal'` | administered at 20:00 with `days: 0` |
| `'an ordinary 7-day withdrawal computes ClearsOn the day after the period elapses'` | the worked example, relationally |
| `'ClearsOn carries the target it was entered for'` | meat and milk produce two distinct statuses from one treatment |
| `'ClearsOn.elapsesAt equals clearDateFor elapsesAt for the same inputs'` | the two entry points agree, so a screen may use either |
| `'the switch over WithdrawalStatus is total with three arms and no default clause'` | a switch expression over the result compiles without a fallback |
| `'computeWithdrawalStatus is pure: equal inputs give equal outputs and no clock is read'` | called twice, same result |

`test/domain/uk_zone/clear_date_dst_test.dart` — one case added:

| Test | Case |
|---|---|
| `'DST-5: the clear date is computed in absolute time'` | treated 20:00 on 26 March 2026, `WithdrawalDays.asEnteredByUser(days: 7, target: WithdrawalTarget.meat)`; the result as `ClearsOn` has `elapsesAt.local == DateTime(2026, 4, 2, 21, 0)` — 21:00, not 20:00 — and `date == LocalDate(2026, 4, 3)` |

## 6. Constraints that bind this task

- **Safety rule §12.1, unpersistable half.** *No row means not recorded.* There is no column whose
  default could quietly mean "zero days", because there is no row at all — and the domain's mirror
  of that is `WithdrawalNotRecorded` mapping to `WithdrawalUnknown` with no third possibility.
- **Safety rule §12.4 — never silently correct.** A status is computed from stored inputs and
  written nowhere. If the stored clear date and a fresh computation disagree, that is a warning, not
  a repair — and it is the next task but one.
- **The three paths that route around the type (05 §3.10)** are the reason this arm matters:
  *repeat last treatment* copies everything **except** the withdrawal; there is **no learned
  default**, ever; and a voided treatment is excluded from every withdrawal surface and never
  recomputed. All three land in N20 and all three assume `WithdrawalUnknown` renders honestly.
- **The four import bans (05 §1.2)**, including `package:drift` and `lib/data/`: a domain function
  that knows about a repository is a domain function that can be made to write.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'a treatment with no withdrawal row computes WithdrawalUnknown, never ClearsOn today'` passes, and was seen to fail first for the stated reason
- [ ] three arms, exhaustively switched at every call site
- [ ] the absent row maps to `WithdrawalUnknown`
- [ ] `0` days maps to `ClearsOn`, not to `NoWithdrawal`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/withdrawal/status_test.dart
fvm flutter test test/domain/withdrawal
TZ=Europe/London fvm flutter test --tags uk-zone
TZ=Pacific/Chatham fvm flutter test test/domain --exclude-tags uk-zone
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): WithdrawalStatus and computeWithdrawalStatus`

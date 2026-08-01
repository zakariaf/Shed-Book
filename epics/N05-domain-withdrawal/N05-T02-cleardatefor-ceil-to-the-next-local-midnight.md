# N05-T02 — `clearDateFor` — ceil to the next local midnight

| | |
|---|---|
| **Epic** | [N05 — Domain: withdrawal](epic.md) · `00-README` §9 step 2 (2 of 3) |
| **Task** | 2 of 5 |
| **Depends on** | N05-T01 |
| **Commit** | one commit · `feat(domain): clearDateFor, ceiling to the next local midnight` |

## 1. Why this task exists

Decision #3, executable: the clear date is the **ceiling to the next local midnight** of
(administration instant + N × 24 h), computed in **absolute** time. Civil-day arithmetic is banned
here, and the regression that proves why is the seven-day withdrawal across UK spring-forward: 168
absolute hours, where civil-day arithmetic gives 167 and puts meat in the food chain a day early.

This is the one function in the app that produces a number a stranger relies on. Everything else in
`lib/domain/` is wrong for the user; this is wrong for whoever eats the lamb.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §3.5–§3.7 | the algorithm line by line, the worked example, the two deliberate edge behaviours, and the conservative-interpretation argument that must go in the code comment |
| `docs/engineering/05-domain-correctness.md` | §2.9 | the measured Dart behaviour under `TZ=Europe/London`, DST-4 and DST-5, and the `setUpAll` that fails loudly |
| `docs/research/00-tech-decisions.md` | §1 #3, §2 #49, #50 | ceil-to-next-local-midnight, computed in absolute time, stored once |
| `docs/engineering/CONVENTIONS.md` | §1, §2.7, §4.1 | the file path, the record return type, and where the two test files go |
| `docs/engineering/12-testing.md` | §2.3, §2.5 | the ambiguous hour, and the three commands the suite is run with |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-withdrawal` | this is the arithmetic it exists to protect |
| `shed-domain` | absolute versus civil time is its distinction |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/uk_zone/clear_date_dst_test.dart`
- **Test** — `'7 days across UK spring-forward is 168 h absolute, and civil-day arithmetic would give 167'`
- **Why it is red today** — nothing computes a clear date.

```bash
fvm flutter test test/domain/uk_zone/clear_date_dst_test.dart   # expect: failing, for the reason above
```

The two halves of the assertion, so it fails for the right reason rather than merely failing:
`DateTime(2026, 3, 26, 20, 0).add(const Duration(days: 7)).difference(treated).inHours` is **168**
and `DateTime(2026, 3, 26 + 7, 20, 0).difference(treated).inHours` is **167**; and
`clearDateFor(administeredAt: Instant.fromDateTime(treated), days: 7)` returns
`elapsesAt.local == DateTime(2026, 4, 2, 21, 0)` and `date == LocalDate(2026, 4, 3)`.

**Green.** The minimum code that passes, and nothing beyond it — absolute addition, then ceiling to the next local midnight in the device zone, with the
DST cases in the `uk-zone` tier.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8's order

Step 1 (schema) is **skipped and the commit message says so** — this function computes a value that
N20-T01 will store, inside the same `db.transaction` that writes the withdrawal row, but the column
is N07-T05's and the write is N20's. Steps 3 to 7 are not reached. Step 2 (domain) and step 7
(tests) are the whole diff.

| # | File | New or re-opened | What changes in it, and why |
|---|---|---|---|
| 1 | `test/domain/uk_zone/clear_date_dst_test.dart` | **new** | The anchor, `@Tags(['uk-zone'])`, with the `setUpAll` offset guard from 05 §2.9 — *a skipped safety test is a broken safety test*. This is the tier N04-T08 built; this task is its first real inhabitant. |
| 2 | `lib/domain/withdrawal/clear_date.dart` | **new** | `clearDateFor` and nothing else. `computeWithdrawalStatus` lands in the same file on the next task, so leave the import list minimal and do not pre-add `withdrawal_status.dart`. |
| 3 | `test/domain/withdrawal/clear_date_test.dart` | **new** | The zone-agnostic arithmetic. `CONVENTIONS` §4.1 names this exact path as its worked example of a mirror test, and 00-PLAN-CRITIQUE §11.3 rules that the pure non-DST arithmetic stays here while the DST cases live in the `uk-zone` tier. |

### 5.2 The signature

`05-domain-correctness.md` §3.5, verbatim — including the comment, which is part of the deliverable
and is the only thing standing between the next developer and a "simplification" that eats the
regulator's margin:

```dart
// lib/domain/withdrawal/clear_date.dart

/// The ONE function that computes a clear date. Called exactly once per
/// withdrawal row, at write time (decision #50).
///
/// clearDate = ceil-to-next-local-midnight(administeredAt + N x 24 h),
/// computed in ABSOLUTE time. Civil-day arithmetic is banned here.
///
/// The ceil looks like an over-hold and it is not: the regulator already
/// rounded the label number UP (EMA CVMP §4.1.2 — to whole milkings, then to
/// whole 12- or 24-hour multiples). A second rounding in the same direction is
/// safe and bounded by 24 h. Rounding the other way eats the regulator's own
/// margin. Do not "simplify" this. See 05-domain-correctness.md §3.7.
({LocalDate date, Instant elapsesAt}) clearDateFor({
  required Instant administeredAt,
  required int days,
}) {
  final elapsesAt = administeredAt.plus(Duration(hours: days * 24));
  final dayOfElapse = LocalDate.of(elapsesAt);
  final startOfThatDay = dayOfElapse.startOfDayLocal();
  final date = elapsesAt.epochMillis == startOfThatDay.epochMillis
      ? dayOfElapse            // elapses exactly at midnight: that whole day is clear
      : dayOfElapse.plusDays(1);
  return (date: date, elapsesAt: elapsesAt);
}
```

The worked example to keep in your head: treated **Tue 3 Mar 20:00**, 7 days. The period elapses
**Tue 10 Mar 20:00**. Ten March is therefore only *partly* clear, so the first fully clear day is
**Wed 11 Mar** — one day later than a shepherd counting on their fingers, and the app must show its
working rather than look broken.

### 5.3 The details that are easy to get wrong

- **Never `DateTime(y, m, d + n)`.** Measured under `TZ=Europe/London`: a civil `+7` from 20:00 on
  26 March 2026 yields **167 hours, not 168** — one hour short of a seven-day withdrawal, on a
  treatment given in late March, which is peak lambing. The autumn direction is the same defect
  pointing the other way: a civil `+7` from 22 October 20:00 yields **169 hours**. Calendar
  arithmetic is narrowed to season boundaries and display-only date offsets (decision #49).
- **`Duration` arithmetic on `DateTime` is *absolute*-time arithmetic.** That is why it is the right
  tool here and the wrong tool for a calendar. `Instant.plus` and `Instant.difference` give the
  identical answer to `DateTime.add` and `DateTime.difference`, because both are epoch-millisecond
  arithmetic.
- **`LocalDate.of(elapsesAt)` reads the device's *current* zone, not the zone at administration.**
  That is deliberate and it is the entire reason N05-T05 exists: a phone that crossed a border, or
  a row written before a fix, can make the stored date and a fresh computation disagree — which is
  *shown, never applied*. Do not try to store an offset here to make it stable.
- **`LocalDate.startOfDayLocal()` uses `DateTime(y, m, d)` — the local constructor, not
  `DateTime.utc`.** `LocalDate.plusDays` and `daysUntil` route through `DateTime.utc` for the
  opposite reason (UTC has no DST, so `Duration(days: n)` there is exactly *n* calendar days). The
  two spellings look inconsistent and are not; both are load-bearing.
- **A zone with no local midnight** — some historical DST rules skip it — is handled by that same
  line: `DateTime(y, m, d)` returns the first instant that *does* exist that day, the millisecond
  comparison fails, and the algorithm takes the next day. **It never rounds down.** Write that in a
  comment or somebody will "fix" the equality into a `<=`.
- **A zero-day withdrawal elapses at the moment of administration**, which is almost never local
  midnight, so the clear date is *tomorrow*. That is correct — today is a partial day — and it is
  the case that proves `0` is a real value flowing through real code. It must never render as
  "clear now".
- **The exactly-at-midnight equality is not dead code.** Administer at local midnight on 1 February
  with 7 days and the period elapses at local midnight on 8 February, so 8 February is clear in
  full. Administer at local midnight on **25 March 2026** with 7 days and it elapses at **01:00 BST
  on 1 April** — the spring-forward moved it — so the equality fails and the clear date is
  2 April. Both cases belong in the test set; the second is the one that catches a rewrite.
- **`clearDateFor` needs no `now` and reads no clock.** Its two inputs are both parameters and
  neither is the current time, so the Definition of Done's *"`now` is a parameter; the function
  reads no clock"* is satisfied at its strongest: there is nothing to fake, and `package:clock` is
  banned in `lib/domain/` anyway (05 §1.2 D3, `CONVENTIONS` R24). If you find yourself wanting
  `appNow()` here, you are writing *"is she clear today?"*, which is a read-edge question and is
  answered in SQL by `w.clear_date >= :today` (07 §10.1).
- **It takes a raw `int days`, not a `WithdrawalPeriod`.** Only one of the three arms carries a
  number; the switch that knows which is `computeWithdrawalStatus`, next task. Widening this
  signature would put a sealed-type switch inside the arithmetic and duplicate it.
- **Zone-agnostic tests must assert *relationally*.** CI runs `test/domain` a second time under
  `TZ=Pacific/Chatham` — UTC+12:45, with its own DST — which catches any code that assumes a
  whole-hour offset or a same-day UTC/local mapping. So `test/domain/withdrawal/clear_date_test.dart`
  asserts things like *"`elapsesAt` is exactly `days × 24 h` after administration"* and *"the clear
  date is the day after the day of elapse unless the elapse is exactly at local midnight"*. Absolute
  wall-clock values belong only in the `uk-zone` file.
- **The `uk-zone` file fails loudly under a wrong zone; it never skips.** The `setUpAll` asserts
  `DateTime(2026, 7, 1).timeZoneOffset == const Duration(hours: 1)` with the reason *"Run this file
  with `TZ=Europe/London`"*. A skipped safety test is a broken safety test.
- **Do not warn about the ambiguous hour here.** 01:00–01:59 on 25 October happens twice; Dart picks
  one instant and the displayed time still matches what the shepherd typed, so nothing has been
  silently corrected from their point of view. The *nonexistent* hour is the one that gets a warning,
  and it is `checkLocalWallTimeExists` at the entry edge (N04), not this function's business. Noise
  at 3am is a defect.
- ****`glados` was struck from decision-record §5.2 on 2026-08-01** — it does not resolve against `drift_dev` 2.34.5 at any version, because it depends on `package:test`. Decision #118 is amended: the pure-value layer is an explicit table of cases in the same file. Do not add the package; the rule `12 §10.6` stated in advance has already been applied — the property layer was deleted, not the pin.** Decision #118
  scopes it to pure value round-trips; 12 §10.6 warns that it is the dev dependency closest to the
  `analyzer` constraint that governs the whole toolchain. Write the properties as a hand-rolled loop
  over a day table first. The day table is now the whole of it: `glados` was struck on 2026-08-01 and
  the resolution reddens, the property layer is deleted, not the pin.

### 5.4 The full test set

`test/domain/uk_zone/clear_date_dst_test.dart` — `@Tags(['uk-zone'])`, `TZ=Europe/London`, 2026
transitions on **29 March** and **25 October**:

| Test | Case |
|---|---|
| `'7 days across UK spring-forward is 168 h absolute, and civil-day arithmetic would give 167'` | **the anchor.** Both numbers pinned, so a future "simplification" fails CI |
| `'a 7-day withdrawal administered at 20:00 on 26 March 2026 clears on 3 April 2026'` | `elapsesAt.local` is `2026-04-02 21:00`, not 20:00; `date` is `2026-04-03` |
| `'a period administered at local midnight across the spring-forward clears the following day'` | 25 March 00:00 + 7 d elapses 01:00 on 1 April, so 1 April is partial and the clear date is 2 April |
| `'a 7-day withdrawal across the clocks-back night is still 168 absolute hours'` | the autumn direction, where civil arithmetic over-counts to 169 |
| `'a treatment administered in the ambiguous hour on 25 October 2026 clears from the stored instant'` | 01:30 happens twice; whichever instant Dart chose is the one the clear date is computed from, and no warning is raised |
| `setUpAll` | asserts the process offset and fails with *"Run this file with TZ=Europe/London"* |

`test/domain/withdrawal/clear_date_test.dart` — zone-agnostic, relational, table-driven:

| Test | Case |
|---|---|
| `'the worked example: treated at 20:00 for 7 days, the period elapses on day 7 and the clear date is day 8'` | 05 §3.5's example, expressed as day offsets rather than as March dates |
| `'a zero-day withdrawal clears tomorrow, because today is a partial day'` | `days: 0` at 20:00 |
| `'a period that elapses exactly at local midnight clears that same day'` | administered at local midnight, no transition in the window |
| `'elapsesAt is exactly days times 24 hours after administration, for every day count'` | property over `0, 1, 7, 14, 28, 999, 1000` |
| `'the clear date is never earlier than the civil day the period elapses on'` | property; the algorithm never rounds down |
| `'the clear date is at most one day after the day of elapse'` | property; the second rounding is bounded by 24 h |
| `'clearDateFor reads no clock: two calls with the same inputs are equal'` | purity, and the reason there is nothing to fake |

## 6. Constraints that bind this task

- **Decision #49 and #50.** Absolute time, ceil to the next local midnight, computed **exactly
  once** at write time and stored — never recomputed for display. The comment above the function is
  where #50's reason lives: the stored value is *a record of what the app told the user* and what
  got printed into a medicine book handed to a vet or an abattoir.
- **A setting to "count whole days from the day of treatment" is rejected outright.** It is a
  food-safety setting whose wrong value puts meat in the food chain, buried in a screen nobody opens
  at 3am, and it would let the app produce a number *less* conservative than the label.
- **Safety rule §12.2 — never give veterinary advice.** The app may arithmetic-transform a number
  the user supplied; it may never originate one. Counting down from the N the user typed is the
  allowed side of that line, and this function is the whole of it.
- **The four import bans (05 §1.2)**, including **`package:clock`**: pure functions take their
  inputs as parameters, which is what makes *"did you test the boundary?"* a compile-time question.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'7 days across UK spring-forward is 168 h absolute, and civil-day arithmetic would give 167'` passes, and was seen to fail first for the stated reason
- [ ] the 167-hour regression fails on a civil-day implementation and passes on this one
- [ ] `now` is a parameter; the function reads no clock
- [ ] the result is computed once and stored, never recomputed for display
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/uk_zone/clear_date_dst_test.dart
fvm flutter test test/domain/withdrawal/clear_date_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
TZ=Pacific/Chatham fvm flutter test test/domain --exclude-tags uk-zone
make check
make test
```

The third command is unscoped on purpose: the tag selects the files, and a path would quietly drop
the zone-pinned files that live outside `test/domain/` from later epics (12 §2.5). The fourth
carries `--exclude-tags uk-zone` because the `uk-zone` files assert their own offset and are
correctly red in a hostile zone.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): clearDateFor, ceiling to the next local midnight`

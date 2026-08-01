# N20-T03 — The clear date as a stored fact, rendered as a day tally

| | |
|---|---|
| **Epic** | [N20 — Treatments and withdrawal](epic.md) · `00-README` §9 step 7 |
| **Task** | 3 of 7 |
| **Depends on** | N20-T02 |
| **Commit** | one commit · `feat(treatments): the stored clear date, rendered as a day tally` |

## 1. Why this task exists

The clear date is computed **once at write time** by N05-T02's function and **stored** —
never recomputed for display, because a device that changed timezone would then quietly show a
different date than the one the shepherd wrote on the bottle's label. `ClearsOn` renders as a day
tally.

Two things are being built at once and they pull in opposite directions. The **date** is a civil fact
that was decided on the day and must never move. The **countdown** beside it — *9d*, *LAST DAY*,
*CLEARED* — changes with no write at all and must never be stored. Getting either one on the wrong
side of that line is the defect this task exists to prevent.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | **§3.8** (*"`clear_date` is the one stored derived value in the app… it is a record of what the app told the user on the day, and it is printed into a medicine-book PDF"*), **§3.4** (`ClearsOn(date, elapsesAt, target)`, and `WithdrawalUnknown` as *"a state with a name and its own widget — never a blank cell and never an em-dash that might mean zero"*), §3.5 (the algorithm, and the worked example), §3.7 (the working the screen must show), §4.3 (every displayed event time carries its provenance) | what is stored, what is derived, and what each state says |
| `docs/engineering/07-screens.md` | **§10.3** (the six states, row by row: the countdown line, *Withdrawal not recorded*, *Not applicable*, and the all-numeric-date defect R60 corrects), §10.1 (`clear_date` comes off the child row, never off `treatments`) | the six renderings |
| `docs/design/indelible.md` | **§7.6** (the countdown: an 88 px row, product name at 20 px, `CLEARS <date>` at 19 px caps, **one 2 px × 12 px mark per remaining day with 4 px gaps, capped at 28 with `+n`**, the days figure at 32 px tabular, and the four states — Default, **Last day**, **Cleared**, Pressed), §6.2 mark 4 (the tally stroke and the five-bar gate), §6.2 mark 1 (the dagger — *always accompanied by a word*), §2.7 (the two rows for *under withdrawal* and *last day of withdrawal*), §7.3 (the unset cell — a dotted rule and a visible gap) | every dimension and every state name |
| `docs/engineering/10-accessibility-and-i18n.md` | **§5.2** (the four withdrawal renderings, and *"they split on a **type**, not on a layout choice"*), §11 (the checklist line: `ShedCountdown` is constructed only from a `ClearsOn`), §3.2 (labels), §8.5 (the ARB) | which state renders what, and the one place the compiler is the gate |
| `docs/engineering/06-design-system.md` | §12 (`ShedCountdown`: `headlineLarge` tabular, states active / clear / **not recorded**), **§5.4** (tabular figures, and the silent failure a proportional font produces in a column of numbers) | the component and its type |
| `docs/engineering/CONVENTIONS.md` | **§2.7** (`ClearsOn`, `NoWithdrawal`, `WithdrawalUnknown`; *"the countdown widget takes a `ClearsOn`, never a `WithdrawalStatus`"*), §2.2 (`LocalDate.of(Instant)`, `.daysUntil`, `.plusDays`, `Instant.plus`), §3.3 (`minuteTickProvider`), §2.11 (`lib/core/ui/formatters.dart` is the only `package:intl` call site outside `lib/data/`), **R60** (no human-facing date is all-numeric), R24, R25 | the types, the arithmetic and the format |
| `docs/engineering/01-architecture.md` | §7.2 (**bucket A — derived-at-render values**; nothing elapsed is ever stored) | why the days figure has no column |
| `docs/engineering/12-testing.md` | §2.2 (`Clock.fixed` silently measures zero), §2.4 (the ambiguous hour and where a zone-pinned widget test lives), §5 (`pumpApp`) | how to test a thing that changes with no write |
| `docs/research/00-tech-decisions.md` | §1 decision 3, #50 | ceil to the next local midnight, in absolute time, **stored exactly once at write time** |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-withdrawal` | the arithmetic and the storage rule |
| `indelible-marks-and-strikes` | the tally rendering and the countdown mark |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/treatments_test.dart`
- **Test** — `'the rendered clear date is the stored one, unchanged after a device timezone change'`
- **Assertion, spelled out** — you cannot change `TZ` inside a running Dart process, so **seed the
  consequence instead**: write a treatment whose `administered_at` and `days` would today produce
  `2026-03-12`, then set its stored `clear_date` to `2026-03-11` — exactly the row a device that moved
  zone leaves behind. Pump the screen and assert `find.text('11 Mar 2026')` is present and
  `find.textContaining('12 Mar')` is absent. The assertion is not *"the date is right"*; it is *"the
  date is the stored one"*, and those two differ in precisely the case that matters.
- **Why it is red today** — nothing renders a clear date, and the obvious implementation recomputes it on build.

```bash
fvm flutter test test/features/treatments_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — render the stored value, and a test that changes the zone and re-pumps.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

The Refactor step has real work in it here. T01 shipped
`withdrawalFor(TreatmentId, WithdrawalTarget)` returning a bare `WithdrawalPeriod`; this task adds
`withdrawalsFor(TreatmentId)` returning the rows **with their stored clear dates**. Reduce the first to
a lookup over the second rather than leaving two statements that read the same table.

## 5. What you build

`00-README` §8 steps 4, 6 and 7 — one repository read, the rendering, and the tests. **Steps 1, 2, 3
and 5 are skipped and the commit message says so**: no schema, no domain (the arithmetic is N05's and
is not called here at all), no write verb, no new screen controller.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `lib/data/treatment_repository.dart` | edit | `withdrawalsFor(TreatmentId)` — the child rows **with `clear_date`**, which `withdrawalFor` alone cannot carry. `TreatmentWithdrawalRow` is declared here, beside the read that produces it |
| 2 | `lib/features/treatments/widgets/withdrawal_cell.dart` | **new** | The total mapping from a child row to one of the three renderings, and the only place `ShedCountdown` is constructed |
| 3 | `lib/features/treatments/widgets/treatment_row.dart` | **new** | The 88 px row: product, `CLEARS <date>`, the tally, the days figure, and the administered time with its provenance label |
| 4 | `lib/features/treatments/treatments_screen.dart` | edit | The committed row printed as the receipt (P2) now carries its withdrawal cell |
| 5 | `lib/l10n/app_en.arb` | edit | `treatmentClearsOn`, `treatmentDaysLeft`, `treatmentLastDay`, `treatmentCleared`, `treatmentWithdrawalNotRecorded`, `treatmentWithdrawalNotApplicable`, `treatmentAddWithdrawal` — each with a `description` |
| 6 | `docs/engineering/07-screens.md` §10.3 | edit | R60's correction applied in the document as well as in the code: the published row still reads `clear on 11/03/2026` |
| 7 | `test/features/treatments_test.dart` | edit | the anchor plus the cases in §5.4 |
| 8 | `test/features/treatments_dst_test.dart` | **new**, `@Tags(['uk-zone'])` | the two clocks-change cases the days figure gets wrong |

### 5.2 The signatures

```dart
// lib/data/treatment_repository.dart — the child row AS STORED. `clearDate` is
// the value the app told the user on the day (#50), not a computed one.
final class TreatmentWithdrawalRow {
  const TreatmentWithdrawalRow({
    required this.target,
    required this.period,          // WithdrawalDays | WithdrawalNotApplicable
    required this.storedClearDate, // null iff kind == 'not_applicable'
  });

  final WithdrawalTarget target;
  final WithdrawalPeriod period;
  final LocalDate? storedClearDate;
}

// A target with NO row is absent from the list. That absence is
// WithdrawalNotRecorded, and it is why this is a List and not a fixed pair.
Future<List<TreatmentWithdrawalRow>> withdrawalsFor(TreatmentId id);
```

The mapping is total, it is the whole of this task, and **it calls neither `clearDateFor` nor
`computeWithdrawalStatus`**:

```dart
// lib/features/treatments/widgets/withdrawal_cell.dart
WithdrawalStatus _statusOf(TreatmentWithdrawalRow? row, Instant administeredAt) =>
    switch (row) {
      // No row for this target. The absence IS the state (03 §5.8).
      null => const WithdrawalUnknown(),
      // The label states no withdrawal applies. A fact, not a gap.
      TreatmentWithdrawalRow(period: WithdrawalNotApplicable()) => const NoWithdrawal(),
      // The stored date, and an instant that is safe to recompute (§5.3 item 2).
      TreatmentWithdrawalRow(
        period: WithdrawalDays(:final days, :final target),
        :final storedClearDate,
      ) =>
        ClearsOn(
          storedClearDate!,                                        // STORED. Never derived.
          administeredAt.plus(Duration(hours: days * 24)),         // absolute, zone-free
          target,
        ),
    };
```

and the one construction of the countdown, which the type system already polices:

```dart
// ShedCountdown takes a ClearsOn, never a WithdrawalStatus (CONVENTIONS §2.7).
// `now` is the instant the ticker last yielded — a parameter, never a clock read (R24).
switch (status) {
  case ClearsOn c:            return ShedCountdown(clearsOn: c, now: tick);
  case NoWithdrawal():        return _NotApplicableCell();   // painted by the row itself
  case WithdrawalUnknown():   return _NotRecordedCell();     // words + a 60 pt "Add it"
}
```

### 5.3 The details that are easy to get wrong

1. **Nothing on a build path calls `clearDateFor` or `computeWithdrawalStatus`.** Both are correct
   functions and both are the wrong tool here: they answer *"what would the clear date be?"*, and the
   screen's question is *"what did we tell the shepherd?"*. `computeWithdrawalStatus` is especially
   tempting because 07 §10.3 mentions it by name while describing the *semantics* of
   `WithdrawalUnknown` — that sentence is not a call site. The DoD holds it with a grep, and the grep
   is the only mechanism available, because both calls compile and both look right.
2. **The date is stored; the instant is not, and may be recomputed.** `ClearsOn` carries both.
   `elapsesAt` is `administeredAt + days × 24 h` — absolute time, identical in every zone, and it is
   what makes the working line honest: *"7 days as entered by you, from Tue 3 Mar 20:00, ends Tue
   10 Mar 20:00"* (05 §3.7). The **date** is the ceil of that instant to the next local midnight, and
   the ceil is the only zone-dependent step in the whole algorithm. That is exactly why one is stored
   and the other is not.
3. **The days figure is a *civil* day count, not `elapsesAt.difference(now).inDays`.** Use
   `LocalDate.of(now).daysUntil(storedClearDate)`. Across the clocks-back night a civil day is 25
   hours and across spring forward it is 23, so a duration-based figure is off by one in the two weeks
   of the year this app is used hardest. The tally has one mark per **remaining day**, and a shepherd
   counting marks is counting sleeps.
4. **The days figure is derived at build and stored nowhere** (`01` §7.2, bucket A). It changes with
   no write, so any cached copy is wrong within a day. It comes off `minuteTickProvider` — the one
   ticker in the app (R25) — watched by the **widget**, never by a keepAlive provider, which is the
   ruling N19-T04 made and the reason the ticker is `autoDispose` at all.
5. **A row that clears while you are looking at it prints `CLEARED` in place.** It does not vanish:
   Indelible §7.6's *Cleared* state is `CLEARED 4 AUG` in `--ink-low` with the tally replaced by a
   2 px solid rule the width the tally used to be, and *"the row stays in the medicine book forever"*.
   Nothing disappears under your hand (Rule 1).
6. **`WithdrawalUnknown` is words plus an action, never a blank and never an em-dash.** 05 §3.4:
   *"Withdrawal not recorded"* plus a 60 pt *"Add it"*. An em-dash might mean zero, and zero is a real
   label value. `NOT APPLICABLE` and `NOT RECORDED` are painted by the treatment row itself, in the
   pixels the countdown would have occupied, **with no countdown widget in the tree** (10 §5.2). This
   is the one row of the redundancy table where the compiler is the gate — writing
   `ShedCountdown(status)` to handle all four in one place is the defect the type exists to prevent.
7. **`d MMM y`, never `11/03/2026`** (R60). 07 §10.3's published row carries the defect and this task
   fixes the document as well as the code — *"the withdrawal countdown is the single worst place to
   break this rule, because the number it renders is the safety-critical one."* Formatting goes
   through `lib/core/ui/formatters.dart`, the only `package:intl` call site outside `lib/data/`; a
   `DateFormat` constructed in a feature file is a layer violation and a second locale policy.
8. **Figures are tabular.** 06 §5.4: a proportional font makes a column of day counts jitter, and the
   failure is silent — it looks like a font choice and reads as noise under a head torch at arm's
   length. The days figure is `--t-tag` 32 px tabular, right-aligned, so the numbers form their own
   scannable column.
9. **The tally caps at 28 marks and prints `+n`.** Indelible §7.6. A 90-day withdrawal is real, and 90
   marks is a wall. At 200 % text scale the marks do not scale into a smear: the **figure** is the
   carrier and the tally is the second channel, which is also what keeps it legible when the row
   reflows.
10. **The administered time carries its provenance label.** 05 §4.3: a bare `03:21` is a review
    failure. It comes from `RecordedTime.provenanceLabel`, an exhaustive switch that can never be
    empty, and it renders in the same visual block as the time.
11. **The date is a `LocalDate`, and `LocalDate.parse` is strict and throws.** The column is
    `TEXT 'YYYY-MM-DD'` behind `LocalDateConverter`; it never becomes a `DateTime` on the way to the
    screen, because a `DateTime` reintroduces a time and a zone to a value that has neither.
12. **Do not wrap this widget test in `withClock(Clock.fixed(...))`.** `12 §2.2`: it freezes `now()`
    while `pump(Duration)` still fires timers, so the days figure stays at its initial value forever
    and the test passes having measured nothing. Offset the **seed data** instead.

### 5.4 The full test set

**`test/features/treatments_test.dart`** — extended.

| Case | What it pins |
|---|---|
| `'the rendered clear date is the stored one, unchanged after a device timezone change'` | **the anchor**, seeded as the disagreement it actually is |
| `'the display calls neither clearDateFor nor computeWithdrawalStatus'` | a source assertion over `lib/features/treatments/`, because both compile and both look right |
| `'the clear date renders as d MMM y and never all-numeric'` | R60, with a negative on `RegExp(r'\d{2}/\d{2}/\d{4}')` |
| `'a treatment with no withdrawal row renders NOT RECORDED with an action, never 0 and never blank'` | 05 §3.4 · 10 §5.2 |
| `'a not-applicable withdrawal renders NOT APPLICABLE and no ShedCountdown appears in the tree'` | `find.byType(ShedCountdown)` is `findsNothing` |
| `'the day tally draws one mark per remaining day and caps at 28 with a plus figure'` | Indelible §7.6 |
| `'the last day prints LAST DAY, a dagger and a doubled rule, and the dagger never travels alone'` | §6.2 mark 1 — *always accompanied by a word* |
| `'a withdrawal that clears while the screen is open prints CLEARED in place and the row stays'` | pump past the boundary on the tick; assert the row is still found |
| `'the days figure moves on a minute tick across local midnight without a database write'` | bucket A |
| `'the tally and the days figure both read at textScaler 2.0 with boldText'` | the 3am floor at the scale where a `Row` clips |
| `'the administered time renders with its provenance label and never bare'` | §12.5 |

**`test/features/treatments_dst_test.dart`** `@Tags(['uk-zone'])` — new.

| Case | What it pins |
|---|---|
| `'a withdrawal spanning the clocks-back night counts civil days, not 24-hour blocks'` | seed a clear date the far side of 25 October 2026; a duration-based figure is one short |
| `'a withdrawal spanning spring forward counts civil days, not 24-hour blocks'` | the same, the other way, on 29 March 2026 — the week UK lambing peaks |
| `'a treatment administered at 01:30 in the repeated hour renders its stored clear date and its provenance label'` | the ambiguous hour, on the display side; `05` §2.9's `setUpAll` makes the file fail loudly under a wrong zone rather than skip |

## 6. Constraints that bind this task

- **§12.5, held at *caught by a test* on both sides of one line.** The clear date is computed once at write time and stored with its provenance; the countdown beside it is computed on every tick and stored nowhere. A phone carried across a timezone must still show the date the shepherd wrote on the bottle's label. Recomputing the date for display, and persisting the countdown, are the two halves of the same defect and each gets its own assertion.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. It is **clear date**, never *safe date* and never *withdrawal end date*.
- **Bucket A** — nothing elapsed is stored, cached or computed in SQL. SQL-side time is banned outright (decision #47).

## 7. Definition of Done

- [ ] `'the rendered clear date is the stored one, unchanged after a device timezone change'` passes, and was seen to fail first for the stated reason
- [ ] the display never recomputes the date
- [ ] the tally reads at 200% text scale
- [ ] `WithdrawalUnknown` renders as its own words, never as a blank
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `grep -rn "clearDateFor\|computeWithdrawalStatus" lib/features/` returns nothing
- [ ] `ShedCountdown` is constructed from a `ClearsOn` at exactly one site, and from nothing else
- [ ] `07-screens.md` §10.3's `clear on 11/03/2026` is corrected to `d MMM y` in this commit (R60)

## 8. Verification

```bash
fvm flutter test test/features/treatments_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
grep -rn "clearDateFor\|computeWithdrawalStatus" lib/features/
grep -rn "ShedCountdown(" lib/features/
grep -rn "DateFormat\|package:intl" lib/features/treatments/
grep -rn "Timer.periodic\|Duration(seconds:" lib/features/treatments/
make check
make test
```

The first grep must print nothing — it is the whole task, and it is the only mechanism available
because both calls compile. The second must print exactly one line. The third must print nothing:
formatting goes through `lib/core/ui/formatters.dart` (R55, layer rule 7). The fourth must print
nothing: there is one ticker in the app and it is N12's.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(treatments): the stored clear date, rendered as a day tally`

---
name: shed-withdrawal
description: >-
  Withdrawal periods and clear dates — never defaulted, suggested, pre-filled or copied by
  repeat-last-treatment. Use for medicines, doses, treatments, batch numbers, withdrawal days, clear
  dates and countdowns. Do NOT use for general date arithmetic (shed-domain).
---

# Withdrawal periods and clear dates

The highest-stakes code in Shed Book. A wrong number here puts meat or milk in the food chain.
Owning documents, which outrank this skill and carry the reasoning: `docs/engineering/05-domain-correctness.md`
§3 and §7.1, `docs/research/00-tech-decisions.md` §1 decision 3 and decisions #49–#52,
`docs/engineering/CONVENTIONS.md` §2.7 (every name and signature), `docs/engineering/03-data-model-and-schema.md`
§5.8 (the tables), `docs/engineering/07-screens.md` §10 (Screen 8 Treatments).

## Four prohibitions, and why each escape hatch is also closed

1. **Never default.** No `?? 0` within reach of a withdrawal, no `withDefault`/`clientDefault` on
   `days`, no optional or defaulted `days` parameter, no seeded `0` in the field. `0` is a real label
   value — products genuinely print zero-day withdrawals — so a nullable int cannot tell "the label
   says zero" from "I did not look", and code that coerces null to zero is indistinguishable from
   correct code (05 §3.1).
2. **Never suggest.** No medicines lookup table, no product database, no unit hint, no placeholder.
   The app ships none and the entry field carries no hint text (decision #51, spec §11).
3. **Never learn.** No "you usually enter 28 for this product", no allowlist, no confidence
   threshold, no "we noticed…" prompt. NADIS on sheep medicine usage — withdrawal periods *can change
   for the same medicine and differ between products with the same active ingredient* — so a learned
   default fails silently on the one bottle that changed (05 §3.10).
4. **Never copy.** `REPEAT LAST TREATMENT` copies product, dose, route and batch, and **explicitly
   leaves the days blank**, printing `DAYS NOT COPIED — READ THE BOTTLE` in the cell where the value
   would go (`docs/design/indelible.md` §8 Screen 8 and §9; 05 §3.10). Put the NADIS sentence in a
   comment at the copy site or the next developer will "fix" the apparent oversight.

## The type is the mechanism

`WithdrawalPeriod` is a three-state `sealed` class with a **private generative constructor** and a
single entry point, `WithdrawalDays.asEnteredByUser`, which throws rather than coerces. Names,
subtypes and exact signatures are in `CONVENTIONS.md` §2.7; the implementation lives in
`lib/domain/withdrawal/withdrawal_period.dart`. Do not re-derive it, do not widen it.

- `freezed` and `extension type` are both rejected here for the same reason — neither can give you a
  private generative constructor (decision #51). Do not reach for either.
- The output is sealed too (`lib/domain/withdrawal/withdrawal_status.dart`). The countdown widget
  takes `ClearsOn`, never `WithdrawalStatus`, which makes a countdown for an unrecorded period
  type-impossible. A widget that accepts `WithdrawalStatus` and switches internally is a defect.
- `WithdrawalUnknown` is a named state with its own widget and its own add action — never a blank
  cell, never an em-dash that might read as zero. How it is drawn is `indelible-controls`.
- **Milkings do not convert.** There is no `WithdrawalMilkings` in v1. A label stating only milkings
  is recorded as not-recorded for that target, with the number typed verbatim into the treatment
  note. Converting milkings to days assumes an interval the label did not state, which originates a
  number (§12.2) and then presents it as the user's own (§12.4).

## Absence is the state

Withdrawals are a child table, 0..n rows per treatment, unique on `(treatment, target)` — see
03 §5.8. **No row for a target means not recorded.** There is no column whose default could quietly
mean zero, because there is no row. Never write a placeholder, zero or null-days row to "represent"
the absence; that is the exact confusion the shape exists to prevent. `UNIQUE (treatment, target)` is
also the hand-written index on the `treatment` foreign key that decision #31 requires — do not add a
second one.

## The clear-date algorithm

`clearDate = ceil-to-next-local-midnight(administeredAt + N × 24 h)`, computed in **absolute** time,
by the one function `clearDateFor()` in `lib/domain/withdrawal/clear_date.dart`, called **exactly
once per withdrawal row at write time**, inside the same `db.transaction` that writes the row
(decisions #49, #50).

**Read `examples/clear_date.dart` before writing or changing any clear-date arithmetic.** It is the
canonical implementation with this project's imports and the comment that must survive; once
`lib/domain/withdrawal/clear_date.dart` exists, that file is authoritative.

Keep this worked example in your head: treated **Tue 3 Mar 20:00**, 7 days → the period elapses
**Tue 10 Mar 20:00** → 10 March is only partly clear → the clear date is **Wed 11 Mar**.

## Gotchas

- **Civil-day arithmetic is banned here and the number is measured.** `DateTime(y, m, d + 7)` across
  the UK spring-forward yields **167 hours, not 168** — one hour short of a seven-day withdrawal, on
  a treatment given in late March, which is peak UK/Ireland lambing (05 §2.9, decision #49).
- **A zero-day withdrawal clears tomorrow, not today.** It elapses at the moment of administration,
  which is almost never local midnight, so today is a partial day. This is correct, and it is the
  case that proves `0` flows through real code.
- **The ceil looks like an over-hold and is not.** The regulator already rounded the label number up;
  a second rounding in the same direction is safe and bounded by 24 h, and rounding the other way
  eats the regulator's own margin (05 §3.7). Do not "simplify" it. **A setting to count whole days
  from the day of treatment is rejected outright** — configurable food safety does not ship.
- **Warn about the nonexistent local hour, never the ambiguous one.** UK 01:00–01:59 is skipped in
  spring and repeated in autumn. Dart silently moves a nonexistent local time, so
  `checkLocalWallTimeExists` flags it; the ambiguous hour has zero visible effect and a warning there
  is 3am noise (05 §2.9).
- **A stored clear date that disagrees with a fresh computation is shown, never applied.** There is
  no `fix()`. `checkClearDate` in `lib/domain/validation/treatment_checks.dart` returns a
  `Warning`; only an edit through `TreatmentRepository` writes a new clear date (decision #54).
- **Voiding a treatment is a soft void.** Filter `voided_at IS NULL` on every countdown, clear-date
  and "is she clear?" query; **never** delete, blank or recompute the withdrawal row — the medicine
  book shows it struck through, still carrying the figure it was saved with (decision #69, 05 §3.10).
- **Two gates prove §12.1 and there are only two** (decision #52) — the schema-JSON assertion that
  `days` has null `defaultValue` and null `clientDefault`, and the widget test that an untouched
  field saves no row. Do not add a source heuristic hunting numeric literals near "withdrawal"; it
  fires on the table's own `CHECK` constraints and on fixtures, and a weakened gate is worse than none.
- **07 §10.4 describes the repeat sheet as showing the previous withdrawal figure. It is superseded**
  by 05 §3.10 and the selected design system. Days are not copied and not carried into the field.
- **Provenance is one const, referenced and never re-typed** — `Disclaimers` in
  `lib/domain/policy/disclaimers.dart` (decision #62), next to every withdrawal figure, every clear
  date, and in every export. Retyping the string breaks the single-definition test.
- **A human-facing date is never all-numeric**, and the withdrawal countdown is the worst place to
  break that rule because the number it renders is the safety-critical one (`CONVENTIONS.md` R60).

## Not this skill

- General date arithmetic, `Instant`, `LocalDate`, the clock and unit canonicalisation → **shed-domain**.
- The other four safety rules and their mechanisms → **shed-safety-rules**.
- How the withdrawal field, keypad and choices are drawn → **indelible-controls**; the day tally and
  the strike on a voided row → **indelible-marks-and-strikes**.

## Supporting files

- `examples/clear_date.dart` — the clear-date algorithm as a compiling artefact with this project's
  exact imports. **Load before touching clear-date arithmetic.**
- `examples/clear_date_dst_test.dart` — DST-1 to DST-5 including the 01:00–01:59 ambiguous hour,
  tagged `uk-zone`, destined for `test/domain/uk_zone/dst_test.dart`. **Load before writing or
  changing a time-shaped test.**

## Done when

- [ ] No `?? 0`, no default, no `clientDefault` and no seeded `0` anywhere a withdrawal can reach.
- [ ] Every `WithdrawalDays` in the codebase is built by `asEnteredByUser`; no other construction path compiles.
- [ ] Not-recorded is expressed by the **absence** of a row, never by a written placeholder.
- [ ] `clearDateFor()` is the only clear-date computation, called once per row at write time, in the write transaction.
- [ ] Repeat-last copies product, dose, route and batch only, and prints `DAYS NOT COPIED — READ THE BOTTLE`.
- [ ] Every countdown / clear-date query filters `voided_at IS NULL`; no withdrawal row is ever recomputed.
- [ ] `TZ=Europe/London flutter test test/domain` passes, including DST-4's `167` and DST-5.
- [ ] `TZ=Pacific/Chatham flutter test test/domain --exclude-tags uk-zone` passes.
- [ ] `flutter analyze` and `dart tool/check_policy.dart` are clean.

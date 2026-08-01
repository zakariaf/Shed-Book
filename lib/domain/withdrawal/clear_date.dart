import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';

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
///
/// **Why absolute, measured rather than argued.** Under `TZ=Europe/London` a
/// civil `+7` from 20:00 on 26 March 2026 yields **167 hours, not 168** — one
/// hour short of a seven-day withdrawal, on a treatment given in the week UK and
/// Irish lambing peaks, on the side that clears the animal early. The autumn
/// direction over-counts to 169. Both are pinned in
/// `test/domain/uk_zone/clear_date_dst_test.dart`.
///
/// **It computes once and the caller stores the answer.** Decision #50: the
/// stored value is a record of what the app told the user, and what got printed
/// into a medicine book handed to a vet or an abattoir. Recomputing it for
/// display is how the app quietly changes its own advice. When a stored date and
/// a fresh computation disagree, that is `clearDateDisagrees` (N05-T05) — shown,
/// never applied.
///
/// **It reads no clock and takes no `now`.** Both inputs are parameters and
/// neither is the current time, so there is nothing to fake; `package:clock` is
/// banned in `lib/domain/` anyway (05 §1.2 D3, CONVENTIONS R24). If you want
/// `appNow()` here you are writing *"is she clear today?"*, which is a read-edge
/// question answered in SQL by `w.clear_date >= :today` (07 §10.1).
///
/// **It takes a raw `int days`, not a `WithdrawalPeriod`.** Only one of the
/// three arms carries a number, and the switch that knows which is
/// `computeWithdrawalStatus` (N05-T03). Widening this signature would put a sealed-type
/// switch inside the arithmetic and then duplicate it.
({LocalDate date, Instant elapsesAt}) clearDateFor({
  required Instant administeredAt,
  required int days,
}) {
  // Duration arithmetic on an epoch instant is ABSOLUTE-time arithmetic — the
  // right tool for elapsed time and the wrong tool for a calendar. LocalDate's
  // own plusDays routes through DateTime.utc for the opposite reason. The two
  // spellings look inconsistent and are not; both are load-bearing.
  final Instant elapsesAt = administeredAt.plus(Duration(hours: days * 24));
  final LocalDate dayOfElapse = LocalDate.of(elapsesAt);
  final Instant startOfThatDay = dayOfElapse.startOfDayLocal();

  // The comparison is against the first instant that EXISTS on that local day.
  // In a zone with no local midnight — some historical DST rules skip it —
  // `DateTime(y, m, d)` returns the first instant that does, the equality fails,
  // and the next day is taken. The algorithm never rounds down.
  //
  // The rewrite to guard against is not a loosened comparison — `elapsesAt` is
  // always at or after the start of its own local day, so `<=` here would be the
  // same function. It is dropping the ternary and returning `dayOfElapse`
  // unconditionally, which reads as removing a special case and clears every
  // animal a day early. `test/domain/withdrawal/clear_date_test.dart`'s worked
  // example and zero-day case are what catch it; the two bound properties beside
  // them do not, because a round-down satisfies both.
  final LocalDate date = elapsesAt.epochMillis == startOfThatDay.epochMillis
      ? dayOfElapse // elapses exactly at midnight: that whole day is clear
      : dayOfElapse.plusDays(1);

  return (date: date, elapsesAt: elapsesAt);
}

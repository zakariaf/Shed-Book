import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_status.dart';

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

/// The three-arm switch a screen actually calls, joining the sealed input to the
/// sealed output.
///
/// **The absent row is the fact.** `WithdrawalNotRecorded` — which the repository
/// produces when `treatment_withdrawals` holds no row for that target — maps to
/// [WithdrawalUnknown] and to nothing else. There is no fourth possibility and
/// no fallback, because every plausible fallback is a lie: *clear today* says
/// the animal is clear when nobody knows, and *no withdrawal* says the label
/// stated none when nobody looked.
///
/// **Three arms, no `default:` and no `_` wildcard — here and at every future
/// call site.** A wildcard silently swallows the fourth arm if `WithdrawalMilkings`
/// is ever proposed in v2, which destroys the one property `sealed` was chosen
/// for: adding a subtype must be a compile-error-guided change everywhere.
///
/// **It takes no `now`, and must not learn to.** It answers *what did the label
/// say and when does it elapse*, not *is she clear today*. The second question
/// is asked at the read edge, in SQL — `w.kind = 'days' AND w.clear_date >=
/// :today` (07 §10.1) — with `today` supplied by `appNow()` at that edge. A `now`
/// here would make the status time-varying and every cached value wrong at
/// midnight.
///
/// **It reads no database and must never be handed a row.** `lib/domain/` may
/// not import `package:drift` or `lib/data/` (05 §1.2 D2). The repository maps
/// rows to a [WithdrawalPeriod] and passes plain values in; a treatment with a
/// meat row and a milk row produces **two** statuses, which is why one treatment
/// shows two countdowns.
///
/// **Do not call this on a voided treatment.** Decision #69: undo of a treatment
/// sets `treatments.voided_at` and the row stays, because it may already have
/// been printed into a medicine book handed to a vet. Every *"is she clear?"*
/// query filters `voided_at IS NULL` upstream; the withdrawal row, its inputs and
/// its stored `clear_date` are never deleted, blanked or recalculated. The
/// exclusion is N20-T05's work — the reason is here, because this is the
/// function somebody will be tempted to call on a voided row instead.
WithdrawalStatus computeWithdrawalStatus({
  required Instant administeredAt,
  required WithdrawalPeriod period,
}) => switch (period) {
  WithdrawalNotRecorded() => const WithdrawalUnknown(),
  WithdrawalNotApplicable() => const NoWithdrawal(),
  // `days: 0` lands HERE, not on NoWithdrawal. "The label says zero" and "the
  // label says none applies" are different facts, and the zero-day case carries
  // tomorrow's date because the period elapses at the moment of administration.
  WithdrawalDays(:final int days, :final WithdrawalTarget target) => () {
    final ({LocalDate date, Instant elapsesAt}) r = clearDateFor(
      administeredAt: administeredAt,
      days: days,
    );
    return ClearsOn(r.date, r.elapsesAt, target);
  }(),
};

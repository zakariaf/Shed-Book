// The canonical clear-date algorithm. Destination: lib/domain/withdrawal/clear_date.dart
//
// Owned by docs/engineering/05-domain-correctness.md §3.5; decisions #49 and #50 in
// docs/research/00-tech-decisions.md. Names and signatures are fixed by CONVENTIONS.md §2.7.
//
// lib/domain/ is PURE DART: no flutter, no drift, no riverpod, no intl, no package:clock.
// `administeredAt` is passed in; nothing here reads a wall clock (CONVENTIONS.md R23, R24).

import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_status.dart';

/// The ONE function that computes a clear date. Called exactly once per
/// withdrawal row, at write time, inside the same `db.transaction` that writes
/// the row (decision #50).
///
/// clearDate = ceil-to-next-local-midnight(administeredAt + N x 24 h),
/// computed in ABSOLUTE time. Civil-day arithmetic is banned here: a civil `+7`
/// across the UK spring-forward yields 167 hours, not 168 — one hour short of a
/// seven-day withdrawal, in late March, which is peak UK/Ireland lambing.
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
  // Elapses exactly at local midnight: that whole day is already clear.
  // In a zone with no local midnight, `DateTime(y, m, d)` returns the first
  // instant that does exist, the comparison fails, and we take the next day.
  // The algorithm never rounds DOWN.
  final date = elapsesAt.epochMillis == startOfThatDay.epochMillis
      ? dayOfElapse
      : dayOfElapse.plusDays(1);
  return (date: date, elapsesAt: elapsesAt);
}

/// The exhaustive switch is the safety mechanism. Adding a fourth
/// `WithdrawalPeriod` subtype must break this function at compile time.
///
/// A zero-day withdrawal elapses at the moment of administration, which is
/// almost never local midnight, so it clears TOMORROW. That is correct — today
/// is a partial day — and it is the case that proves `0` is a real label value
/// flowing through real code, not a fallback.
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

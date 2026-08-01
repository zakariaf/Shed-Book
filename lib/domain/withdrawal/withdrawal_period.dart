/// What the withdrawal applies to.
///
/// One bottle routinely prints two different numbers; one field per treatment
/// is a modelling bug that becomes a food safety bug on a dairy flock.
///
/// [milk] ships in v1 even though the target market may never be a dairy flock
/// (open question 10, ruled 2026-08-01). Retrofitting it would be a migration on
/// somebody else's phone; shipping it now is free. Do not gate it behind a flag
/// and do not delete it because the v1 UI offers one target.
enum WithdrawalTarget {
  meat('meat'),
  milk('milk');

  const WithdrawalTarget(this.key);

  /// Stable storage/export key. Never the localised label.
  ///
  /// **Frozen** the moment N07-T05 writes `treatment_withdrawals.target` and its
  /// `CHECK (target IN ('meat','milk'))`, and then again by every CSV column and
  /// every JSON backup. Never localised, never title-cased, never plural.
  final String key;

  /// Throws rather than falling back.
  ///
  /// An `orElse` returning [WithdrawalTarget.meat] is `?? 0` one level up: it
  /// turns a value nobody wrote into a value that looks like one somebody did.
  static WithdrawalTarget fromKey(String k) => WithdrawalTarget.values.firstWhere(
    (WithdrawalTarget t) => t.key == k,
    orElse: () => throw FormatException('Unknown withdrawal target', k),
  );
}

/// A withdrawal period is a THREE-STATE value.
///
/// `int? withdrawalDays` is not merely weak, it is **lossy** (05 §3.1).
/// `withdrawalDays ?? 0` is one keystroke away in a null-safety cleanup and
/// reads as tidy code; `0` is a real label value, so a nullable int cannot tell
/// *"the label says zero"* from *"I did not look"*, which makes wrong code
/// indistinguishable from correct code; and *"not applicable"* is a third
/// distinct fact that collapses too. No amount of care at call sites recovers
/// information the type discarded, so it is never discarded.
///
/// `sealed` is the first of four stacked mechanisms: an exhaustive `switch` over
/// this type makes forgetting the not-recorded case a compile error at every
/// call site.
sealed class WithdrawalPeriod {
  const WithdrawalPeriod();
}

/// The user read a number off the bottle. [days] MAY be 0 — that is a real
/// label value, not a fallback.
///
/// **This type deliberately cannot express milkings, and must never be used
/// to.** VICH states milk periods in milkings as well as days, normally on a
/// 12-hour interval. Converting *6 milkings* to *3 days* assumes an interval the
/// label did not state: that is the app originating a number (safety rule
/// §12.2) and then presenting it as the user's own (§12.4), one on top of the
/// other. The primary source is EMA/CVMP/SWP/735418/2012 §4.1.2 — *"because a
/// different milking frequency can be used in practice, the final unit of the
/// milk withdrawal period should be real time."*
///
/// The v1 rule, in three lines:
///
///   - a label stating only milkings is [WithdrawalNotRecorded] for that target,
///     with the number typed verbatim into the treatment note;
///   - the UI shows `WithdrawalUnknown` for it, and offers no conversion, no
///     calculator and no hint;
///   - v2 may add a fourth subtype whose interval is **required and
///     user-supplied**, for the same reason [days] is. `sealed` turns that into
///     a compile-error-guided change at every switch, which is the whole point.
final class WithdrawalDays extends WithdrawalPeriod {
  /// Private. No default. No optional parameter. No `int days = 0`.
  const WithdrawalDays._(this.days, this.target);

  /// The ONLY way to build one. Throws rather than coercing.
  ///
  /// The name carries the provenance: §12.1 requires the app to show the
  /// source as *"as entered by you"*, and a factory called anything else would
  /// let a call site forget where the figure came from.
  ///
  /// `1000` is an implausibility guard, not a cap and not a default. It
  /// **throws**; it never clamps. Clamping would be the app silently correcting
  /// an entry (§12.4) on top of originating a number (§12.2).
  factory WithdrawalDays.asEnteredByUser({required int days, required WithdrawalTarget target}) {
    if (days < 0) {
      throw ArgumentError.value(days, 'days', 'must be >= 0');
    }
    if (days > 1000) {
      throw ArgumentError.value(days, 'days', 'implausible');
    }
    return WithdrawalDays._(days, target);
  }

  final int days;
  final WithdrawalTarget target;
}

/// The label explicitly states no withdrawal applies. Distinct from zero days
/// and distinct from "I did not look".
///
/// It carries [target] because the persisted marker row is per target — decision
/// #51's *"0..n entries per treatment"* requires it.
final class WithdrawalNotApplicable extends WithdrawalPeriod {
  const WithdrawalNotApplicable(this.target);

  final WithdrawalTarget target;
}

/// The user deliberately skipped it. The app must never invent one, and must
/// never show a countdown or a clear date for this state.
final class WithdrawalNotRecorded extends WithdrawalPeriod {
  const WithdrawalNotRecorded();
}

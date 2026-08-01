import 'package:shed_book/domain/time/instant.dart';

/// How long this animal has physically been in the pen.
///
/// **`now` is a parameter** (R24, D3). `package:clock` is banned in
/// `lib/domain/` and the gate proves it, so the pen board's ticker drives this
/// rather than a hidden clock read — and the boundary is testable because there
/// is nothing to fake.
///
/// **`sincePenned` is a banned name.** 03 §8 once declared it as
/// `Duration sincePenned(Instant enteredAt)`, with the current instant read from
/// the ambient clock inside the body — one parameter and a clock read, in the
/// layer that may not have one.
///
/// The offending line is described rather than quoted, deliberately.
/// `test/policy/one_clock_test.dart` scans whole file text for the ambient
/// reader, at the same width `tool/check_policy.dart` scans for the wall-clock
/// literal, and a comment quoting it verbatim trips that scan. Narrowing the
/// cross-check to declarations so this comment could keep the quote would make
/// it disagree with the gate about scope, which the test's own header says is
/// worse than having no cross-check at all.
///
/// **The answer looks wrong by an hour once a year, and it is right.** Penned
/// Saturday 22:00, checked Sunday 08:00 across the UK spring-forward: this is
/// **9 h** while the wall clock says 10. Nine is correct — it is a welfare
/// question about physical hours in a 4 × 4 pen, and it errs toward turning out
/// later. Do not "fix" it.
Duration timeSincePenned(Instant enteredAt, Instant now) => now.difference(enteredAt);

/// Whether this animal has passed **the user's own** turn-out threshold.
///
/// **It originates neither the threshold nor `now`; both are parameters.** A
/// default of 24 in this signature would be the app suggesting a husbandry
/// decision, which is exactly §12.2's origination line. The value comes from
/// `app_settings.turn_out_threshold_hours`, whose column default is 24 and whose
/// `CHECK (turn_out_threshold_hours BETWEEN 1 AND 336)` is a **range guard, not
/// a recommendation**.
///
/// **The label is never bare "ready".** 07 §9.6's legend reads *"Ready = your
/// 24 h threshold"* with the user's own number substituted — never the default.
/// This is the function somebody will be tempted to rename `isFitToTurnOut`,
/// which would be a clinical claim the app is not entitled to make.
bool isReadyToTurnOut({
  required Instant enteredAt,
  required Instant now,
  required int thresholdHours,
}) => timeSincePenned(enteredAt, now) >= Duration(hours: thresholdHours);

/// Stored keys for `pen_occupancies.exit_reason` (R63), frozen by N07-T05's
/// `CHECK` one epic later.
///
/// It lands here rather than in N19-T01 where it is first used, because landing
/// it there means matching an enum to a `CHECK` that already shipped.
enum PenExitReason {
  turnedOut('turned_out'),
  moved('moved'),
  died('died'),
  other('other');

  const PenExitReason(this.key);

  final String key;

  static PenExitReason fromKey(String k) => PenExitReason.values.firstWhere(
    (PenExitReason r) => r.key == k,
    orElse: () => throw FormatException('Unknown pen exit reason', k),
  );
}

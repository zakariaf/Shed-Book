import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';

/// What a screen is allowed to know about a treatment's withdrawal.
///
/// The input type is sealed, so `LocalDate? clearDate` as an output would
/// reintroduce exactly the null [WithdrawalPeriod] just eliminated. Sealing the
/// output is what makes the countdown's signature possible: `ShedCountdown`
/// takes a [ClearsOn], never a `WithdrawalStatus`, so rendering a countdown for
/// a period nobody entered is **type-impossible** rather than merely forbidden.
///
/// Switch on this sealed type, never on a runtime representation type. [ClearsOn]
/// holds a [LocalDate] over `String` and an [Instant] over `int`, and extension
/// types erase at runtime — an `is int` check cannot tell an [Instant] from any
/// other extension type over `int`.
sealed class WithdrawalStatus {
  const WithdrawalStatus();
}

/// The animal is clear for the WHOLE of [date].
final class ClearsOn extends WithdrawalStatus {
  /// Positional, and it stays positional — this is how CONVENTIONS §2.7 and
  /// 05 §3.4 both spell it. The reviewer's instinct, *"three fields, make them
  /// named"*, is a rename of a published signature and needs a numbered ruling
  /// in CONVENTIONS §6, not a commit.
  const ClearsOn(this.date, this.elapsesAt, this.target);

  /// Never rendered all-numeric. A human-facing date is `d MMM y` (R60), and the
  /// withdrawal countdown is the worst possible place to break that rule,
  /// because the number it renders is the safety-critical one. The formatting is
  /// N20's; the constraint is recorded here because this is where the value is
  /// born.
  final LocalDate date;

  /// The exact instant the label's period elapses, shown next to the date so
  /// the shepherd can check our arithmetic against their own — *"Clear on Wed 11
  /// Mar · 7 days as entered by you, from Tue 3 Mar 20:00, ends Tue 10 Mar
  /// 20:00."*
  ///
  /// Not decoration. Dropping it because *"the date is enough"* removes the only
  /// way a user can catch us being wrong.
  final Instant elapsesAt;

  final WithdrawalTarget target;
}

/// The label states no withdrawal applies to this route or species.
final class NoWithdrawal extends WithdrawalStatus {
  const NoWithdrawal();
}

/// Nobody looked at the bottle. **A state with a name, never an absence.**
///
/// It renders as *"Withdrawal not recorded"* with a 60 pt *"Add it"* action
/// (05 §3.4). A blank cell or an em-dash lets a shepherd read *zero*, which is
/// the confusion the whole sealed input type exists to prevent — reintroducing
/// it one layer later would undo all of it.
final class WithdrawalUnknown extends WithdrawalStatus {
  const WithdrawalUnknown();
}

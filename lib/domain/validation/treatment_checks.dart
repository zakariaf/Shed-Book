import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/validation/warning.dart';
import 'package:shed_book/domain/withdrawal/clear_date.dart';

/// The stored clear date does not match what today's arithmetic produces from
/// the stored inputs. **The app says so and changes nothing.**
///
/// `clear_date` is the one stored derived value in the app (decision #50), and
/// it is stored precisely because it is *not really derived*: it is a record of
/// what the app told the user on the day, printed into a medicine-book PDF that
/// may be handed to a vet or an abattoir. A value like that cannot be silently
/// refreshed, so this is the honest answer to the staleness objection.
///
/// **It returns warnings and no date, and that IS "returns the stored value,
/// always".** There is no return path yielding the recomputed date as a value a
/// caller could persist. The stored date the caller passed in is the only one
/// that survives the call, and it stays the one printed in the medicine book.
/// There is no `fix()`: editing the treatment is a user action that writes a new
/// `clear_date` through the normal repository path, and nothing else may rewrite
/// it.
///
/// **Three causes, one response.** The device zone changed; an input was edited;
/// the row predates a fix. All three produce this warning and none produces a
/// correction. Do not branch on the cause — the app cannot know which it was.
///
/// **Never call it for a soft-voided treatment.** Decision #69: the withdrawal
/// row, its inputs and its stored `clear_date` are never deleted, blanked or
/// recalculated, and the medicine book shows the treatment struck through with
/// its void date, still carrying the figure it was recorded with. A disagreement
/// beside a voided row is the app arguing with a record it already published.
///
/// **A repository cannot call this**, and that is a mechanism rather than a
/// convention: `lib/data/` may not import `lib/domain/validation/` at all
/// (`layer.data_no_validation`, R53). Repositories return `WriteCommitted` with
/// the default empty warnings; the **controller** runs the validators against
/// the freshly-watched row. Warnings are never persisted — there is no
/// `warnings` column — so they are recomputed on read and can never diverge from
/// their source or be mistaken for user data on export. And a warning never
/// gates a write: a blocked write produces a lost record, which is worse than a
/// warned one.
///
/// **It takes `int days`, not a [WithdrawalPeriod].** Only the `WithdrawalDays`
/// arm has a stored clear date; `WithdrawalNotApplicable` has no date to
/// disagree with and `WithdrawalNotRecorded` has no row at all. Widening the
/// signature would import a switch `computeWithdrawalStatus` already owns.
///
/// **The ISO dates in [Warning.message] are not what a shepherd reads.** R60
/// bans all-numeric human-facing dates, and both rules are right: the domain
/// cannot import `package:intl` (05 §1.2 D4), so it *cannot* produce
/// `11 Mar 2026`, and [Warning] has no structured date fields, so a screen
/// cannot reformat this string's contents. The consequence for N20-T06, recorded
/// here because this is where the constraint is created: the disagreement row
/// renders **both dates from the values the row already holds**, through
/// `lib/core/ui/formatters.dart` as `d MMM y`, stored first, with *"Nothing has
/// been changed."* under them (07 §10.4). This message is the domain's own
/// record of the observation.
List<Warning> checkClearDate({
  required Instant administeredAt,
  required int days,
  required LocalDate storedClearDate,
}) {
  final LocalDate recomputed = clearDateFor(administeredAt: administeredAt, days: days).date;

  // compareTo, not `==`. LocalDate is an extension type over its ISO string so
  // `==` happens to work today; compareTo survives the day the representation
  // changes.
  if (recomputed.compareTo(storedClearDate) == 0) {
    // `const []`, never `[]` and never null: this runs on every render of every
    // treatment row, and the agreeing path is the overwhelmingly common one.
    return const <Warning>[];
  }

  return <Warning>[
    Warning(
      WarningCode.clearDateDisagrees,
      // What we OBSERVED, and nothing about what to do. The stored date comes
      // first, which is the order 07 §10.4 renders them in.
      'This treatment was recorded with a clear date of ${storedClearDate.iso}. '
      'From the details now recorded it would be ${recomputed.iso}.',
      fieldPath: 'withdrawal',
    ),
  ];
}

// test/policy/flock_filter_never_implies_a_withdrawal_test.dart
//
// **RULING N1, AS A PROPERTY.** Named for what it forbids rather than for the
// file it guards (`CONVENTIONS §4.1`), because the defect it exists to catch can
// move between the statement, the controller and the screen without changing
// shape.
//
// The rule: **an unrecorded withdrawal is UNKNOWN, never clear.** A ewe injected
// yesterday whose withdrawal nobody typed must not be filtered out of *under
// treatment*, because removing her from that list is the app answering a
// withdrawal question on the shepherd's behalf — spec §12.1's exact shape, and
// the one the child-table design already refuses at the storage layer
// (`03 §5.8`: *"NO ROW for a target means NotRecorded"*).
//
// This is not a hypothetical. `07 §3.1`'s printed predicate was
// `w.kind = 'days' AND w.clear_date >= :today`, an INNER JOIN to
// `treatment_withdrawals`, and N26-T01 implemented it verbatim. A treatment with
// no withdrawal row has nothing to join to, so she vanished — silently, and in
// the direction that reads as *she is clear*.
@Tags(<String>['policy'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/data/treatment_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

/// A treatment on [ewe] with the withdrawals given — **an empty list writes no
/// row**, which is how NotRecorded is expressed (`03 §5.8`). There is no
/// placeholder to write and writing one would be the confusion the shape exists
/// to prevent.
Future<void> _treat(
  AppDatabase db,
  EweId ewe, {
  required List<WithdrawalPeriod> withdrawals,
}) async {
  final WriteOutcome outcome = await TreatmentRepository(db).recordTreatment(
    TreatEwe(ewe),
    productName: 'Alamycin LA 300 mg/ml',
    doseText: '3 ml',
    batchNo: 'B7734-2026',
    withdrawals: withdrawals,
  );
  expect(outcome, isA<WriteCommitted>());
}

void main() {
  test('a ewe whose withdrawal nobody recorded is under treatment, not clear', () async {
    // THE ANCHOR. Three ewes, three withdrawal states, and the assertion is on
    // which of them the filter is allowed to hide.
    final AppDatabase db = testDatabase();
    await seedSeason(db);

    final EweId unrecorded = await seedEwe(db, tag: 'W1');
    final EweId running = await seedEwe(db, tag: 'W2');
    final EweId notApplicable = await seedEwe(db, tag: 'W3');

    // 1 — NOBODY TYPED ANYTHING. No row, so no target has an answer.
    await _treat(db, unrecorded, withdrawals: const <WithdrawalPeriod>[]);
    // 2 — A REAL PERIOD, still running.
    await _treat(
      db,
      running,
      withdrawals: <WithdrawalPeriod>[
        WithdrawalDays.asEnteredByUser(days: 28, target: WithdrawalTarget.meat),
      ],
    );
    // 3 — RECORDED AS NOT APPLICABLE. This is an ANSWER, so she is clear, and
    // she is the control that stops this test passing for a filter that simply
    // returns everybody.
    await _treat(
      db,
      notApplicable,
      withdrawals: const <WithdrawalPeriod>[WithdrawalNotApplicable(WithdrawalTarget.meat)],
    );

    final List<FlockRow> rows = await flockList(db, const FlockFilters());
    FlockRow rowFor(EweId id) => rows.firstWhere((FlockRow r) => r.id.value == id.value);

    // **THE FLAG IS CLOCK-FREE AND SAYS *UNKNOWN*, NOT *CLEAR*.**
    expect(
      rowFor(unrecorded).unrecordedWithdrawal,
      isTrue,
      reason: 'a treatment with no withdrawal row is unknown — §12.1',
    );
    expect(rowFor(running).unrecordedWithdrawal, isFalse);
    expect(
      rowFor(notApplicable).unrecordedWithdrawal,
      isFalse,
      reason: 'not-applicable is a recorded answer, so it is not unknown',
    );

    await db.close();
  });

  test(
    'the under-treatment filter includes the unrecorded ewe and excludes the clear one',
    () async {
      // The filter itself, which is the thing a shepherd actually uses. Written
      // separately from the flag because a correct flag rendered by a filter that
      // ignores it is still a ewe missing from the list.
      final AppDatabase db = testDatabase();
      await seedSeason(db);

      final EweId unrecorded = await seedEwe(db, tag: 'W1');
      final EweId notApplicable = await seedEwe(db, tag: 'W3');
      final EweId untreated = await seedEwe(db, tag: 'W4');

      await _treat(db, unrecorded, withdrawals: const <WithdrawalPeriod>[]);
      await _treat(
        db,
        notApplicable,
        withdrawals: const <WithdrawalPeriod>[WithdrawalNotApplicable(WithdrawalTarget.meat)],
      );

      final Set<int> under = (await flockList(db, const FlockFilters()))
          .where((FlockRow r) => r.isUnderTreatment(appNow()))
          .map((FlockRow r) => r.id.value)
          .toSet();

      expect(under, contains(unrecorded.value), reason: 'the unknown ewe is hidden — §12.1');
      expect(under, isNot(contains(notApplicable.value)));
      expect(
        under,
        isNot(contains(untreated.value)),
        reason: 'never treated is not under treatment',
      );

      await db.close();
    },
  );

  test('the statement binds no date, so a screen open across midnight still filters on today', () {
    // **THE OTHER HALF OF N1, AND IT IS A SOURCE ASSERTION BECAUSE THERE IS NO
    // WAY TO OBSERVE IT AT RUNTIME WITHOUT WAITING FOR MIDNIGHT.**
    //
    // `07 §3.1`'s predicate bound `:today` into the statement. A `watch()` binds
    // its variables ONCE, when the stream is built, and drift re-runs the same
    // prepared statement with the same arguments on every table change — so a
    // phone left on the flock page overnight goes on filtering against
    // yesterday's date, and the ewe who cleared at midnight stays listed as
    // running. Decision #47 bans SQL-side time; a Dart date frozen into a
    // long-lived statement is the same bug wearing a Dart hat.
    //
    // The statement now returns `latest_clear_date` and `unrecorded_withdrawal`,
    // both clock-free, and the comparison happens in Dart where `now` advances.
    final String sql = flockListSqlForTest;

    for (final String clockShaped in <String>[
      'clear_date >=',
      'clear_date >',
      "date('now')",
      'CURRENT_DATE',
      'julianday',
    ]) {
      expect(
        sql.toLowerCase(),
        isNot(contains(clockShaped.toLowerCase())),
        reason: '$clockShaped puts today into a statement that is bound once',
      );
    }
  });
}

// test/domain/validation/treatment_checks_test.dart — mirrors
// lib/domain/validation/treatment_checks.dart, which N05-T05 created for
// checkClearDate and N06-T03 extended with checkTreatment.
//
// The disagreement's own cases are test/domain/withdrawal/disagreement_test.dart's,
// where the property lives. What is here is checkTreatment, plus ONE regression
// case re-running N05-T05's anchor against the extended file — so a careless
// edit to the shared file is caught here rather than fifteen epics later in N20.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/validation/treatment_checks.dart';
import 'package:shed_book/domain/validation/warning.dart';
import 'package:shed_book/domain/withdrawal/clear_date.dart';

/// June: transition-free in Europe/London, Pacific/Chatham and UTC.
final Instant _treatedAt20 = Instant.fromDateTime(DateTime(2026, 6, 3, 20));

LocalDate _recomputed(int days) => clearDateFor(administeredAt: _treatedAt20, days: days).date;

void main() {
  test('a treatment whose withdrawal rows all agree is silent', () {
    expect(
      checkTreatment(
        administeredAt: _treatedAt20,
        withdrawals: <({int days, LocalDate storedClearDate})>[
          (days: 7, storedClearDate: _recomputed(7)),
          (days: 3, storedClearDate: _recomputed(3)),
        ],
      ),
      isEmpty,
    );
  });

  test('a treatment with no withdrawal rows is silent, not unknown', () {
    // No row means not recorded, and "not recorded" is not a contradiction —
    // it is WithdrawalUnknown, which is computeWithdrawalStatus's answer and not
    // a warning.
    expect(
      checkTreatment(
        administeredAt: _treatedAt20,
        withdrawals: const <({int days, LocalDate storedClearDate})>[],
      ),
      isEmpty,
    );
  });

  test('a treatment with a meat row and a milk row can raise two warnings', () {
    // One bottle, two numbers, two stored dates, two ways to disagree — the same
    // reason one treatment shows two countdowns. A check that stopped at the
    // first row would silently pass the second.
    final List<Warning> warnings = checkTreatment(
      administeredAt: _treatedAt20,
      withdrawals: <({int days, LocalDate storedClearDate})>[
        (days: 7, storedClearDate: _recomputed(7).plusDays(-1)),
        (days: 3, storedClearDate: _recomputed(3).plusDays(1)),
      ],
    );

    expect(warnings, hasLength(2));
    expect(
      warnings.map((Warning w) => w.code).toSet(),
      <WarningCode>{WarningCode.clearDateDisagrees},
      reason: 'checkTreatment raises no NEW code — that is the evidence it invents nothing',
    );
  });

  test('checkTreatment reports rows in the order it was given them', () {
    final List<Warning> warnings = checkTreatment(
      administeredAt: _treatedAt20,
      withdrawals: <({int days, LocalDate storedClearDate})>[
        (days: 7, storedClearDate: _recomputed(7).plusDays(-1)),
        (days: 3, storedClearDate: _recomputed(3).plusDays(1)),
      ],
    );

    expect(warnings.first.message, contains(_recomputed(7).plusDays(-1).iso));
    expect(warnings.last.message, contains(_recomputed(3).plusDays(1).iso));
  });

  test('clearDateDisagrees warns and returns the stored clear date unchanged', () {
    // N05-T05's anchor, re-run against the extended file. If somebody moves or
    // reshapes checkClearDate while adding to this file, it fails here.
    final LocalDate stored = _recomputed(7).plusDays(-1);

    final List<Warning> warnings = checkClearDate(
      administeredAt: _treatedAt20,
      days: 7,
      storedClearDate: stored,
    );

    expect(warnings.single.code, WarningCode.clearDateDisagrees);
    expect(warnings.single.message, contains(stored.iso));
    expect(warnings.single.message, contains(_recomputed(7).iso));
    expect(warnings.single.fieldPath, 'withdrawal');
  });
}

// test/domain/withdrawal/withdrawal_period_test.dart — mirrors
// lib/domain/withdrawal/withdrawal_period.dart (CONVENTIONS §4.1).
//
// Everything about BEHAVIOUR is here. The one property that is a claim about the
// artefact rather than about a value — that WithdrawalDays has no public
// generative constructor — lives in test/policy/withdrawal_has_no_default_test.dart.
//
// No uk-zone case, and that is not an omission: nothing in this file computes a
// date, holds an Instant or reads a clock, so there is nothing for the ambiguous
// 01:00–01:59 hour to bite. The DST cases arrive with clearDateFor in N05-T02.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';

void main() {
  test('asEnteredByUser accepts 0 days, because 0 is a real label value', () {
    // The half of the rule that is easiest to leave untested and is the wrong
    // half to leave untested. Products genuinely print zero-day withdrawals; a
    // guard band that rejected zero would push every one of them into
    // WithdrawalNotRecorded, which is the confusion the type exists to prevent.
    final WithdrawalDays w = WithdrawalDays.asEnteredByUser(days: 0, target: WithdrawalTarget.meat);
    expect(w.days, 0);
    expect(w.target, WithdrawalTarget.meat);
  });

  test('asEnteredByUser throws on a negative day count rather than coercing it', () {
    expect(
      () => WithdrawalDays.asEnteredByUser(days: -1, target: WithdrawalTarget.meat),
      throwsArgumentError,
    );
  });

  test('asEnteredByUser throws above the implausible band and never clamps', () {
    // If this ever returns a WithdrawalDays holding 1000 for an input of 1001,
    // the app has silently corrected an entry (§12.4) and shown the result as
    // the user's own number (§12.1). Throwing is the whole behaviour.
    expect(
      () => WithdrawalDays.asEnteredByUser(days: 1001, target: WithdrawalTarget.milk),
      throwsArgumentError,
    );
    expect(
      WithdrawalDays.asEnteredByUser(days: 1000, target: WithdrawalTarget.milk).days,
      1000,
      reason: '1000 is inside the band; the guard is > 1000',
    );
  });

  test('a switch over WithdrawalPeriod needs three arms and no default clause', () {
    // The compiler is the assertion. A fourth subtype, or a deleted arm, makes
    // this file stop compiling — which is the mechanism `sealed` buys and the
    // reason no `default:` may ever be added at a real call site.
    String describe(WithdrawalPeriod p) => switch (p) {
      WithdrawalDays(:final int days) => 'days:$days',
      WithdrawalNotApplicable(:final WithdrawalTarget target) => 'n/a:${target.key}',
      WithdrawalNotRecorded() => 'not recorded',
    };

    expect(
      describe(WithdrawalDays.asEnteredByUser(days: 7, target: WithdrawalTarget.meat)),
      'days:7',
    );
    expect(describe(const WithdrawalNotApplicable(WithdrawalTarget.milk)), 'n/a:milk');
    expect(describe(const WithdrawalNotRecorded()), 'not recorded');
  });

  test('WithdrawalTarget keys are frozen at meat and milk', () {
    // Frozen by N07-T05's CHECK, then by every CSV column and every JSON backup.
    // A change here after the freeze is a migration on somebody else's phone.
    expect(WithdrawalTarget.values.map((WithdrawalTarget t) => t.key).toList(), <String>[
      'meat',
      'milk',
    ]);
  });

  test('fromKey round-trips every member and throws FormatException on anything else', () {
    for (final WithdrawalTarget t in WithdrawalTarget.values) {
      expect(WithdrawalTarget.fromKey(t.key), t, reason: t.key);
    }
    for (final String bad in <String>['MEAT', '', 'Meat', 'milks', 'meat ']) {
      expect(() => WithdrawalTarget.fromKey(bad), throwsFormatException, reason: bad);
    }
  });

  test('WithdrawalNotApplicable carries its target and WithdrawalNotRecorded carries nothing', () {
    // Two marker states, and the fact that they are two different facts. "The
    // label says no withdrawal applies to meat" is knowledge; "I did not look"
    // is its absence, and it is not per-target because there is nothing to
    // attach it to.
    const WithdrawalNotApplicable notApplicable = WithdrawalNotApplicable(WithdrawalTarget.meat);
    expect(notApplicable.target, WithdrawalTarget.meat);
    expect(
      const WithdrawalNotRecorded(),
      isNot(isA<WithdrawalNotApplicable>()),
      reason: 'never merge the two into one "no number" state',
    );
  });

  test('one bottle with a meat figure and no milk figure is two different states', () {
    // The modelling case the child table exists for (05 §3.3). One field per
    // treatment cannot hold this pair, and on a dairy flock that is a food
    // safety bug rather than a tidiness one.
    final List<WithdrawalPeriod> oneBottle = <WithdrawalPeriod>[
      WithdrawalDays.asEnteredByUser(days: 28, target: WithdrawalTarget.meat),
      const WithdrawalNotRecorded(),
    ];

    expect((oneBottle.first as WithdrawalDays).days, 28);
    expect((oneBottle.first as WithdrawalDays).target, WithdrawalTarget.meat);
    expect(oneBottle.last, isA<WithdrawalNotRecorded>());
  });
}

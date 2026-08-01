// test/domain/withdrawal/status_test.dart — the three arms of WithdrawalStatus
// and the switch that produces them.
//
// Zone-agnostic and relational, for the same reason clear_date_test.dart is:
// CI runs test/domain again under TZ=Pacific/Chatham. DST-5 — the same function
// pinned to absolute UK wall-clock values — is in
// test/domain/uk_zone/clear_date_dst_test.dart.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/withdrawal/clear_date.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_status.dart';

/// June, for the same reason clear_date_test.dart uses it: transition-free in
/// Europe/London, Pacific/Chatham and UTC.
final Instant _treatedAt20 = Instant.fromDateTime(DateTime(2026, 6, 3, 20));

void main() {
  test('a treatment with no withdrawal row computes WithdrawalUnknown, never ClearsOn today', () {
    // The absent row IS the fact. Three wrong answers all look reasonable in
    // isolation, and a nullable model would have produced two of them:
    // ClearsOn(today) says the animal is clear when nobody knows, and
    // NoWithdrawal says the label stated none when nobody looked. The third — a
    // blank cell or an em-dash — lets a shepherd read zero.
    final WithdrawalStatus status = computeWithdrawalStatus(
      administeredAt: _treatedAt20,
      period: const WithdrawalNotRecorded(),
    );

    expect(status, isA<WithdrawalUnknown>());
    expect(status, isNot(isA<ClearsOn>()), reason: 'never "clear" when nobody looked');
    expect(
      status,
      isNot(isA<NoWithdrawal>()),
      reason: '"I did not look" is not "the label says none applies"',
    );
  });

  test(
    'WithdrawalNotApplicable computes NoWithdrawal, which is not the same fact as zero days',
    () {
      final WithdrawalStatus status = computeWithdrawalStatus(
        administeredAt: _treatedAt20,
        period: const WithdrawalNotApplicable(WithdrawalTarget.meat),
      );

      expect(status, isA<NoWithdrawal>());
      expect(status, isNot(isA<ClearsOn>()), reason: 'no period to count down');
    },
  );

  test('a zero-day withdrawal computes ClearsOn tomorrow, not NoWithdrawal', () {
    // "The label says zero" and "the label says none applies to this route or
    // species" are different facts and take different arms. The zero-day
    // ClearsOn carries TOMORROW, because the period elapses at the moment of
    // administration and today is a partial day.
    final WithdrawalStatus status = computeWithdrawalStatus(
      administeredAt: _treatedAt20,
      period: WithdrawalDays.asEnteredByUser(days: 0, target: WithdrawalTarget.meat),
    );

    expect(status, isA<ClearsOn>());
    expect((status as ClearsOn).date, LocalDate.of(_treatedAt20).plusDays(1));
    expect(status.elapsesAt, _treatedAt20);
  });

  test('an ordinary 7-day withdrawal computes ClearsOn the day after the period elapses', () {
    final ClearsOn status =
        computeWithdrawalStatus(
              administeredAt: _treatedAt20,
              period: WithdrawalDays.asEnteredByUser(days: 7, target: WithdrawalTarget.meat),
            )
            as ClearsOn;

    expect(LocalDate.of(status.elapsesAt), LocalDate.of(_treatedAt20).plusDays(7));
    expect(status.date, LocalDate.of(_treatedAt20).plusDays(8));
  });

  test('ClearsOn carries the target it was entered for', () {
    // One bottle, two numbers, two statuses — which is why the countdown segment
    // lists two countdowns for one treatment, and why a single withdrawal field
    // per treatment is a food safety bug on a dairy flock.
    final ClearsOn meat =
        computeWithdrawalStatus(
              administeredAt: _treatedAt20,
              period: WithdrawalDays.asEnteredByUser(days: 7, target: WithdrawalTarget.meat),
            )
            as ClearsOn;
    final ClearsOn milk =
        computeWithdrawalStatus(
              administeredAt: _treatedAt20,
              period: WithdrawalDays.asEnteredByUser(days: 3, target: WithdrawalTarget.milk),
            )
            as ClearsOn;

    expect(meat.target, WithdrawalTarget.meat);
    expect(milk.target, WithdrawalTarget.milk);
    expect(meat.date, isNot(milk.date), reason: 'two numbers on one bottle clear on two dates');
  });

  test('ClearsOn.elapsesAt equals clearDateFor elapsesAt for the same inputs', () {
    // The two entry points agree, so a screen may use either — and elapsesAt is
    // not decoration. It is rendered beside the date so the shepherd can check
    // our arithmetic against their own; dropping it because "the date is enough"
    // removes the only way a user can catch us being wrong.
    final ({LocalDate date, Instant elapsesAt}) direct = clearDateFor(
      administeredAt: _treatedAt20,
      days: 28,
    );
    final ClearsOn viaStatus =
        computeWithdrawalStatus(
              administeredAt: _treatedAt20,
              period: WithdrawalDays.asEnteredByUser(days: 28, target: WithdrawalTarget.meat),
            )
            as ClearsOn;

    expect(viaStatus.elapsesAt, direct.elapsesAt);
    expect(viaStatus.date, direct.date);
  });

  test('the switch over WithdrawalStatus is total with three arms and no default clause', () {
    // The compiler is the assertion, and the ban is on the WILDCARD as much as
    // on `default:`. A `_` arm silently swallows the fourth case when
    // WithdrawalMilkings is proposed in v2, which destroys the one property
    // `sealed` was chosen for: adding a subtype must be a compile-error-guided
    // change at EVERY call site, not just this one.
    String describe(WithdrawalStatus s) => switch (s) {
      ClearsOn(:final LocalDate date, :final WithdrawalTarget target) =>
        'clear ${target.key} on ${date.iso}',
      NoWithdrawal() => 'none applies',
      WithdrawalUnknown() => 'not recorded',
    };

    expect(describe(const WithdrawalUnknown()), 'not recorded');
    expect(describe(const NoWithdrawal()), 'none applies');
    expect(
      describe(
        computeWithdrawalStatus(
          administeredAt: _treatedAt20,
          period: WithdrawalDays.asEnteredByUser(days: 7, target: WithdrawalTarget.milk),
        ),
      ),
      'clear milk on ${LocalDate.of(_treatedAt20).plusDays(8).iso}',
    );
  });

  test('computeWithdrawalStatus is pure: equal inputs give equal outputs and no clock is read', () {
    // It takes no `now` and must not learn to. It answers "what did the label
    // say and when does it elapse", not "is she clear today" — the second
    // question is asked at the read edge in SQL, with today supplied by appNow().
    // A `now` parameter here would make the status time-varying and every cached
    // value wrong at midnight.
    final WithdrawalPeriod period = WithdrawalDays.asEnteredByUser(
      days: 14,
      target: WithdrawalTarget.meat,
    );
    final ClearsOn first =
        computeWithdrawalStatus(administeredAt: _treatedAt20, period: period) as ClearsOn;
    final ClearsOn second =
        computeWithdrawalStatus(administeredAt: _treatedAt20, period: period) as ClearsOn;

    expect(first.date, second.date);
    expect(first.elapsesAt, second.elapsesAt);
    expect(first.target, second.target);
  });
}

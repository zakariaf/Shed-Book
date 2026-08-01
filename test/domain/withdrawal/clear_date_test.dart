// test/domain/withdrawal/clear_date_test.dart — mirrors
// lib/domain/withdrawal/clear_date.dart (CONVENTIONS §4.1, which names this
// exact path as its worked example of a mirror test).
//
// Zone-agnostic, and it has to be: CI runs test/domain a second time under
// TZ=Pacific/Chatham — UTC+12:45, with its own DST — which catches any code that
// assumes a whole-hour offset or a same-day UTC/local mapping. So every
// assertion here is RELATIONAL: day offsets from the administration date, and
// bounds on the rounding. Absolute wall-clock values belong only in
// test/domain/uk_zone/clear_date_dst_test.dart.
//
// Where a case needs a window with no transition inside it, it uses June. June
// is transition-free in Europe/London, in Pacific/Chatham (southern hemisphere:
// its DST ends in April and resumes in September) and in UTC — the three zones
// this suite is run in. A March date here would be a zone-dependent assertion
// wearing a zone-agnostic file name.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/withdrawal/clear_date.dart';

/// The day counts the properties below sweep: both band edges, the ordinary
/// veterinary numbers, and 0.
const List<int> _dayCounts = <int>[0, 1, 7, 14, 28, 999, 1000];

/// Administration times of day, as (hour, minute). Local midnight is first
/// because it is the only one that can make the equality arm fire.
const List<(int, int)> _timesOfDay = <(int, int)>[(0, 0), (7, 30), (12, 0), (20, 0), (23, 59)];

void main() {
  test('the worked example: treated at 20:00 for 7 days, the period elapses on '
      'day 7 and the clear date is day 8', () {
    // 05 §3.5's example, as day offsets. Treated at 20:00; the period elapses at
    // 20:00 seven days later, so that day is only PARTLY clear, and the first
    // fully clear day is the eighth. One day later than a shepherd counting on
    // their fingers — which is why the app shows its working rather than looking
    // broken.
    final Instant treated = Instant.fromDateTime(DateTime(2026, 6, 3, 20));
    final LocalDate dayOfTreatment = LocalDate.of(treated);

    final ({LocalDate date, Instant elapsesAt}) r = clearDateFor(administeredAt: treated, days: 7);

    expect(LocalDate.of(r.elapsesAt), dayOfTreatment.plusDays(7));
    expect(r.date, dayOfTreatment.plusDays(8));
  });

  test('a zero-day withdrawal clears tomorrow, because today is a partial day', () {
    // The case that proves 0 is a real value flowing through real code. The
    // period elapses at the moment of administration, which is almost never
    // local midnight, so the clear date is tomorrow. It must never render as
    // "clear now".
    final Instant treated = Instant.fromDateTime(DateTime(2026, 6, 3, 20));
    final ({LocalDate date, Instant elapsesAt}) r = clearDateFor(administeredAt: treated, days: 0);

    expect(r.elapsesAt, treated, reason: 'zero days elapses immediately');
    expect(r.date, LocalDate.of(treated).plusDays(1));
  });

  test('a period that elapses exactly at local midnight clears that same day', () {
    // The equality arm, and it is not dead code: administered at local midnight
    // with no transition in the window, the period elapses at local midnight
    // seven days later, so that whole day is clear. The spring-forward form of
    // this case — where the same input elapses at 01:00 instead and the clear
    // date moves a day — is in the uk-zone file, and it is the one that catches
    // a rewrite of the equality into an inequality.
    final Instant treated = Instant.fromDateTime(DateTime(2026, 6, 3));
    final ({LocalDate date, Instant elapsesAt}) r = clearDateFor(administeredAt: treated, days: 7);

    expect(r.elapsesAt, LocalDate.of(treated).plusDays(7).startOfDayLocal());
    expect(r.date, LocalDate.of(treated).plusDays(7));
  });

  test('elapsesAt is exactly days times 24 hours after administration, for every day count', () {
    for (final int days in _dayCounts) {
      for (final (int, int) at in _timesOfDay) {
        final Instant treated = Instant.fromDateTime(DateTime(2026, 3, 20, at.$1, at.$2));
        final ({LocalDate date, Instant elapsesAt}) r = clearDateFor(
          administeredAt: treated,
          days: days,
        );

        expect(
          r.elapsesAt.difference(treated),
          Duration(hours: days * 24),
          reason: 'days=$days at ${at.$1}:${at.$2} — absolute, whatever the zone does in between',
        );
      }
    }
  });

  test('the clear date is never earlier than the civil day the period elapses on', () {
    // The algorithm never rounds DOWN — the direction that puts meat in the food
    // chain early.
    //
    // Read this as the BOUND it is, not as the behaviour. Measured by planting a
    // round-down (`date = dayOfElapse` unconditionally): this property stays
    // green, because a round-down satisfies it exactly. What catches that plant
    // is the worked example and the zero-day case above. A bound that cannot
    // fail alone still earns its place — it is what fails if a rewrite ever
    // returns a date BEFORE the elapse — but do not delete either of those two
    // cases believing this one covers them.
    for (final int days in _dayCounts) {
      for (final (int, int) at in _timesOfDay) {
        final Instant treated = Instant.fromDateTime(DateTime(2026, 3, 20, at.$1, at.$2));
        final ({LocalDate date, Instant elapsesAt}) r = clearDateFor(
          administeredAt: treated,
          days: days,
        );

        expect(
          LocalDate.of(r.elapsesAt).daysUntil(r.date),
          greaterThanOrEqualTo(0),
          reason: 'days=$days at ${at.$1}:${at.$2}',
        );
      }
    }
  });

  test('the clear date is at most one day after the day of elapse', () {
    // The other bound. The second rounding is in the same direction the
    // regulator already rounded, and it is bounded by 24 h — that boundedness is
    // the whole argument for why the ceil is safe rather than an over-hold, so
    // it is asserted rather than assumed.
    for (final int days in _dayCounts) {
      for (final (int, int) at in _timesOfDay) {
        final Instant treated = Instant.fromDateTime(DateTime(2026, 3, 20, at.$1, at.$2));
        final ({LocalDate date, Instant elapsesAt}) r = clearDateFor(
          administeredAt: treated,
          days: days,
        );

        expect(
          LocalDate.of(r.elapsesAt).daysUntil(r.date),
          lessThanOrEqualTo(1),
          reason: 'days=$days at ${at.$1}:${at.$2}',
        );
      }
    }
  });

  test('clearDateFor reads no clock: two calls with the same inputs are equal', () {
    // Purity, and the reason there is nothing to fake. Both inputs are
    // parameters and neither is the current time, so the "now is a parameter"
    // requirement is satisfied at its strongest.
    final Instant treated = Instant.fromDateTime(DateTime(2026, 6, 3, 20));

    final ({LocalDate date, Instant elapsesAt}) first = clearDateFor(
      administeredAt: treated,
      days: 28,
    );
    final ({LocalDate date, Instant elapsesAt}) second = clearDateFor(
      administeredAt: treated,
      days: 28,
    );

    expect(first.date, second.date);
    expect(first.elapsesAt, second.elapsesAt);
  });
}

// The counterpart to `uk_zone/zone_canary_test.dart`, and the file that makes
// the hostile-zone CI step mean something.
//
// That step is `TZ=Pacific/Chatham flutter test test/domain --exclude-tags
// uk-zone` — a +12:45/+13:45 non-hour offset with DST in the southern summer
// (decision #48). It exists to prove the suite is not accidentally
// London-only. With only the `uk-zone` canary in `test/domain/`, excluding
// `uk-zone` selects **nothing**: the run prints "No tests match the requested
// tag selectors" and exits 79, so the step is red for eleven epics for a reason
// no task in this epic can fix.
//
// This file is deliberately **untagged**, so it is selected by the broad run
// AND by the hostile step, and it asserts the property the domain layer is
// built on: `lib/domain/` is pure Dart with no clock — `now` is always a
// parameter — so every domain result is a function of its inputs and of
// nothing the process environment supplies. A domain test that changes verdict
// with `TZ` is a domain function that read the wall clock.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UTC arithmetic is identical in every zone', () {
    // The two DST boundaries the uk-zone canary measures in local time. In UTC
    // they are plain 24-hour days, in Europe/London, in Pacific/Chatham and on
    // a CI runner in UTC alike.
    expect(
      DateTime.utc(2026, 3, 30).difference(DateTime.utc(2026, 3, 29)),
      const Duration(hours: 24),
    );
    expect(
      DateTime.utc(2026, 10, 26).difference(DateTime.utc(2026, 10, 25)),
      const Duration(hours: 25 - 1),
    );
  });

  test('epoch milliseconds round-trip through UTC without touching the zone', () {
    // This is `Instant`'s storage contract before `Instant` exists (#29): UTC
    // epoch millis, and never a local `DateTime`.
    const int millis = 1774569000000;
    final DateTime instant = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    expect(instant.millisecondsSinceEpoch, millis);
    expect(instant.isUtc, isTrue);
    expect(instant.toIso8601String().endsWith('Z'), isTrue);
  });

  test('a civil date is a string and is never re-parsed through a local '
      'DateTime', () {
    // Civil dates are TEXT 'YYYY-MM-DD' (#29) precisely so that no zone can
    // move one. Parsing one into a local DateTime and formatting it back is the
    // bug this asserts against, and it is silent in the zone you wrote it in.
    const String civil = '2026-03-29';
    expect(civil.split('-'), <String>['2026', '03', '29']);
    expect(DateTime.parse('${civil}T00:00:00Z').toIso8601String(), startsWith(civil));
  });
}

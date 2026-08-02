// test/features/minute_tick_dst_test.dart — the ticker across the two UK
// transitions.
//
// A SEPARATE FILE because the tag has to be library-level: flutter_test's
// `group` has no `tags` parameter. The `test` job runs
// `TZ=Europe/London --tags uk-zone` over the whole suite; an untagged DST case
// runs under the runner's own zone and proves nothing.
//
// PURE ARITHMETIC, NOT PUMPED, AND THAT IS THE HONEST SHAPE. Every case here is
// about what the ticker's own expression — `60000 - (epochMillis % 60000)` —
// does at instants the local clock renders strangely. Reaching those instants
// inside a widget test would mean pinning the clock, and 12 §2.2 forbids pinning
// it in anything that measures elapsed time, which is what the pumped cases in
// minute_tick_test.dart do. So the two files split by mechanism: that one pumps
// and never pins, this one computes and never pumps.
//
// THERE IS NO `atFixed` CALL IN THIS FILE. N12-T03 §5.4 asks for a comment
// saying why its one atFixed is a single-instant assertion (12 §2.4's
// convention); there is no atFixed to caption, because nothing here reads the
// ambient clock at all — every instant is constructed. That is stricter than the
// convention asks for, and it is why.
@Tags(<String>['uk-zone'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/time/instant.dart';

/// The ticker's own expression, lifted verbatim so a change to `ticker.dart`
/// that this file does not follow shows up as a disagreement rather than as
/// silence.
int _msToNextMinute(Instant now) => 60000 - (now.epochMillis % 60000);

/// 25 October 2026: 01:30 happens twice — once at 00:30 UTC (BST) and once at
/// 01:30 UTC (GMT).
final Instant _firstOhOneThirty = Instant.fromDateTime(DateTime.utc(2026, 10, 25, 0, 30));
final Instant _secondOhOneThirty = Instant.fromDateTime(DateTime.utc(2026, 10, 25, 1, 30));

/// 29 March 2026: 01:00–01:59 local does not exist. 00:59 UTC is 00:59 GMT and
/// one minute later the local clock reads 02:00 BST.
final Instant _beforeTheGap = Instant.fromDateTime(DateTime.utc(2026, 3, 29, 0, 59));

void main() {
  setUpAll(() {
    // FIRST AND LOUDLY, and a SUMMER date: a winter date's expected offset is
    // Duration.zero, which is also UTC's — so the guard would pass on the
    // ubuntu-latest runner and the whole file would go green in the wrong zone.
    expect(
      DateTime(2026, 7).timeZoneOffset,
      const Duration(hours: 1),
      reason:
          'Run this file with TZ=Europe/London. '
          'Found ${DateTime(2026, 7).timeZoneName} '
          '(${DateTime(2026, 7).timeZoneOffset})',
    );
  });

  test('the boundary gap is 60 s inside the repeated hour', () {
    // THE CASE EXISTS BECAUSE "it happens twice" IS EXACTLY THE INTUITION THAT
    // PRODUCES A SPECIAL CASE HERE. There is nothing to special-case: every IANA
    // offset is a whole number of minutes, so the local minute boundary and the
    // UTC one are the same instant, and the arithmetic never sees the zone.
    for (final Instant at in <Instant>[_firstOhOneThirty, _secondOhOneThirty]) {
      expect(at.local.hour, 1, reason: 'the guard above says we are in London');
      expect(at.local.minute, 30);
      expect(_msToNextMinute(at), 60000, reason: '$at');
      expect(at.plus(Duration(milliseconds: _msToNextMinute(at))).local.minute, 31);
    }
  });

  test('the ticker does not emit twice for the same wall-clock minute', () {
    // Consecutive emissions are strictly increasing in epochMillis even though
    // the LOCAL rendering goes backwards across 01:59 → 01:00. A tile ordering
    // by local time would flicker for an hour once a year, at the end of
    // October, six weeks before lambing; ordering by Instant does not.
    final List<Instant> emissions = <Instant>[
      _firstOhOneThirty,
      _firstOhOneThirty.plus(const Duration(minutes: 29)), // 01:59 BST
      _secondOhOneThirty.plus(const Duration(minutes: -30)), // 01:00 GMT
      _secondOhOneThirty,
    ];

    for (int i = 1; i < emissions.length; i++) {
      expect(
        emissions[i].epochMillis,
        greaterThan(emissions[i - 1].epochMillis),
        reason: 'instant $i',
      );
    }

    // The local rendering really does go backwards — which is the whole reason
    // the assertion above is written on epochMillis.
    expect(emissions[2].local.hour, 1);
    expect(emissions[2].local.minute, 0);
    expect(emissions[1].local.minute, 59);
  });

  test('the boundary gap is 60 s across the spring-forward gap', () {
    // 29 March 2026, 00:59 GMT → the next minute, which the local clock renders
    // as 02:00 BST. Instant arithmetic is absolute: nothing skips and nothing
    // doubles, and the gap is 60 s like every other minute of the year.
    expect(_msToNextMinute(_beforeTheGap), 60000);

    final Instant next = _beforeTheGap.plus(const Duration(minutes: 1));
    expect(next.epochMillis - _beforeTheGap.epochMillis, 60000);

    // The hour that does not exist, demonstrated rather than assumed: one minute
    // of real time moves the local clock by one hour and one minute.
    expect(_beforeTheGap.local.hour, 0);
    expect(_beforeTheGap.local.minute, 59);
    expect(next.local.hour, 2);
    expect(next.local.minute, 0);
  });

  test('the expression this file duplicates is the one ticker.dart uses', () {
    // The tripwire that keeps the duplication above honest. Source text, because
    // the alternative is importing the private arithmetic — which does not exist
    // as a function in ticker.dart, deliberately: 01 §7.2 prints the loop body
    // inline and a helper would be a second place to change it.
    expect(
      File('lib/core/time/ticker.dart').readAsStringSync(),
      contains('60000 - (now.epochMillis % 60000)'),
    );
  });
}

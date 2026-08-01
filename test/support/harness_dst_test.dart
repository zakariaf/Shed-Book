// test/support/harness_dst_test.dart — the harness's own time-shaped cases.
//
// A SEPARATE FILE because the tag has to be library-level: flutter_test's
// `group` has no `tags` parameter (that is package:test's API), so a tagged
// group is not expressible and every uk-zone file in this project is its own
// file for the same reason.
//
// The `test` job runs `TZ=Europe/London --tags uk-zone` over the whole suite. An
// untagged DST case runs under the runner's own zone and proves nothing.
@Tags(<String>['uk-zone'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';

import 'harness.dart';
import 'seeds.dart';

/// 25 October 2026, the clocks-back night. 01:30 happens twice: once at 00:30
/// UTC (BST, UTC+1) and once at 01:30 UTC (GMT).
final DateTime _firstOhOneThirty = DateTime.utc(2026, 10, 25, 0, 30);
final DateTime _secondOhOneThirty = DateTime.utc(2026, 10, 25, 1, 30);

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

  test('atFixed pins appNow() to 01:30 inside the repeated hour', () {
    // A SINGLE-INSTANT ASSERTION, which is the only kind atFixed permits.
    for (final DateTime candidate in <DateTime>[_firstOhOneThirty, _secondOhOneThirty]) {
      final Instant seen = atFixed(candidate, appNow);

      expect(seen.local.hour, 1, reason: '$candidate');
      expect(seen.local.minute, 30, reason: '$candidate');
      expect(
        seen.epochMillis,
        anyOf(_firstOhOneThirty.millisecondsSinceEpoch, _secondOhOneThirty.millisecondsSinceEpoch),
      );
    }
  });

  test('atFixed freezes appNow(), and this file is where that is proved rather '
      'than discovered', () async {
    // THE ONLY PLACE IN THE SUITE WHERE FREEZING IS THE PROPERTY UNDER TEST.
    // Everywhere else it is the trap: an elapsed-time assertion inside atFixed
    // measures 0 h forever AND PASSES, which is decision #113's whole subject.
    // Asserting it deliberately here is what turns a silent failure mode into a
    // documented one.
    late Instant before;
    late Instant after;

    await atFixed(_firstOhOneThirty, () async {
      before = appNow();
      await pumpEventQueue();
      after = appNow();
    });

    expect(after.epochMillis, before.epochMillis);
  });

  testWidgets('without atFixed, a pumped duration moves appNow()', (WidgetTester tester) async {
    // The binding's advancing clock, proved once so no later epic re-derives it:
    // AutomatedTestWidgetsFlutterBinding runs the body inside a FakeAsync zone
    // and installs that zone's clock as package:clock's ambient clock. This is
    // the recipe for anything that measures elapsed time — pin nothing.
    final AppDatabase db = testDatabase();
    await tester.pumpApp(const SizedBox.shrink(), db: db);

    final Instant before = appNow();
    await tester.pump(const Duration(hours: 25));
    final Instant after = appNow();

    expect(after.epochMillis - before.epochMillis, const Duration(hours: 25).inMilliseconds);
  });

  test('a row seeded inside atFixed at 01:30 reads back as 01:30', () async {
    // Ties the harness's time helper to the converter N12-T02 exercised. A
    // single-instant assertion: the row's stored millis are compared, not an
    // elapsed duration.
    final AppDatabase db = testDatabase();

    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await atFixed(
      _secondOhOneThirty,
      () => seedLambing(db, ewe, occurredAt: appNow()),
    );

    final Lambing row = await (db.select(
      db.lambings,
    )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();

    expect(row.occurredAt.epochMillis, _secondOhOneThirty.millisecondsSinceEpoch);
    expect(row.occurredAt.local.hour, 1);
    expect(row.occurredAt.local.minute, 30);

    // The local DATE is what a 01:30 lambing on the clocks-back night is really
    // about: both candidates land on the 25th, and the row must say so.
    expect(row.localDate.iso, '2026-10-25');
  });
}

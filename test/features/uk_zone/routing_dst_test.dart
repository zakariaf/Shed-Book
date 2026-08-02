// test/features/uk_zone/routing_dst_test.dart
//
// The one time-shaped case in N13-T01, and it is the reason the routing tests
// needed a tagged file at all: without TZ=Europe/London on the process it passes
// vacuously in UTC.
@Tags(<String>['uk-zone'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/app.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/routing/routes.dart';

/// 25 October 2026. 01:30 happens twice: once at 00:30 UTC (BST) and once at
/// 01:30 UTC (GMT).
final Instant _backgroundedAt = Instant.fromDateTime(DateTime.utc(2026, 10, 25, 0, 30));
final Instant _resumedAt = Instant.fromDateTime(DateTime.utc(2026, 10, 25, 1, 30));

void main() {
  setUpAll(() {
    // FIRST AND LOUDLY, and a SUMMER date: a winter date's expected offset is
    // Duration.zero, which is also UTC's — so the guard would pass on the
    // ubuntu-latest runner and the file would go green in the wrong zone.
    expect(
      DateTime(2026, 7).timeZoneOffset,
      const Duration(hours: 1),
      reason:
          'Run this file with TZ=Europe/London. '
          'Found ${DateTime(2026, 7).timeZoneName} '
          '(${DateTime(2026, 7).timeZoneOffset})',
    );
  });

  test('the repeated hour is where a wall-clock subtraction silently returns zero', () {
    // THE ARITHMETIC HALF, and it is the whole reason the navigation half below
    // matters. Both instants render 01:30 locally, so subtracting the two LOCAL
    // wall times gives zero — and a resume policy written that way keeps a stale
    // selection for the whole repeated hour. Sixty real minutes have passed.
    expect(_backgroundedAt.local.hour, 1);
    expect(_backgroundedAt.local.minute, 30);
    expect(_resumedAt.local.hour, 1);
    expect(_resumedAt.local.minute, 30);

    // THE NAIVE READING, ASSERTED RATHER THAN DESCRIBED — and the first draft of
    // this case got it wrong, which is worth keeping. Subtracting the two
    // `.local` DateTimes gives the right answer (Dart's DateTime subtraction is
    // absolute), so `Instant.local` is NOT the trap. The trap is reading the
    // RENDERED FIELDS back and rebuilding a DateTime from them, which is what a
    // policy written against "what the clock said" does:
    DateTime asRendered(Instant i) =>
        DateTime(i.local.year, i.local.month, i.local.day, i.local.hour, i.local.minute);
    expect(
      asRendered(_resumedAt).difference(asRendered(_backgroundedAt)),
      Duration.zero,
      reason: 'this is the bug 02 §9 exists to prevent',
    );

    // Instant arithmetic is absolute, so the policy fires.
    expect(_resumedAt.difference(_backgroundedAt), const Duration(hours: 1));
    expect(ResumePolicy.shouldClearSelection(_backgroundedAt, _resumedAt), isTrue);
  });

  testWidgets('a resume across the ambiguous hour still returns to Quick Entry', (
    WidgetTester tester,
  ) async {
    // THE NAVIGATION HALF. ResumePolicy's arithmetic is N11's and has its own
    // case; what this asserts is that the context-free pop lands on isFirst —
    // the path a resume and, later, a notification tap both take, neither of
    // which has a BuildContext to hand.
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: Routes.navigatorKey,
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (BuildContext _) => const Text('lambing entry')),
            ),
            child: const Text('quick entry'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('quick entry'));
    await tester.pumpAndSettle();
    expect(find.text('lambing entry'), findsOneWidget);

    // The phone was pocketed at 01:30 BST and taken out at 01:30 GMT.
    expect(ResumePolicy.shouldClearSelection(_backgroundedAt, _resumedAt), isTrue);
    Routes.popToQuickEntryGlobal();
    await tester.pumpAndSettle();

    expect(find.text('quick entry'), findsOneWidget);
    expect(find.text('lambing entry'), findsNothing);
  });
}

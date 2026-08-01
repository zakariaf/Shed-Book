// test/domain/uk_zone/penning_dst_test.dart — elapsed time is absolute across
// both UK transitions.
@Tags(<String>['uk-zone'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/penning.dart';
import 'package:shed_book/domain/time/instant.dart';

void main() {
  setUpAll(() {
    // A SUMMER date. Under Europe/London 1 July is BST so the offset is +1; a
    // winter date's expected value is Duration.zero, which is also UTC's, so the
    // guard would pass in the wrong zone.
    expect(
      DateTime(2026, 7).timeZoneOffset,
      const Duration(hours: 1),
      reason:
          'Run this file with TZ=Europe/London. '
          'Found ${DateTime(2026, 7).timeZoneName} '
          '(${DateTime(2026, 7).timeZoneOffset})',
    );
  });

  test('penned Sat 22:00, checked Sun 08:00 across the spring-forward is 9 h, not 10', () {
    // 05 §2.9's DST-1, at this function's own call site rather than assumed to
    // carry over from Instant.difference's test. Nine is correct: it is a
    // welfare question about physical hours in a 4 x 4 pen, and it errs toward
    // turning out later.
    final Instant penned = Instant.fromDateTime(DateTime(2026, 3, 28, 22));
    final Instant now = Instant.fromDateTime(DateTime(2026, 3, 29, 8));

    expect(timeSincePenned(penned, now), const Duration(hours: 9));
    // What a civil implementation computes: take the two wall-clock readings at
    // face value and subtract. It reads 10 h, and it is the bug.
    expect(
      DateTime.utc(2026, 3, 29, 8).difference(DateTime.utc(2026, 3, 28, 22)),
      const Duration(hours: 10),
      reason: 'the wall clock advanced 10 h; only 9 physical hours passed',
    );
  });

  test('the same pair across the fall-back is 11 h, not 10', () {
    final Instant penned = Instant.fromDateTime(DateTime(2026, 10, 24, 22));
    final Instant now = Instant.fromDateTime(DateTime(2026, 10, 25, 8));

    expect(timeSincePenned(penned, now), const Duration(hours: 11));
    expect(
      DateTime.utc(2026, 10, 25, 8).difference(DateTime.utc(2026, 10, 24, 22)),
      const Duration(hours: 10),
      reason: 'the same 10 h wall-clock reading, and 11 physical hours passed',
    );
  });

  test('isReadyToTurnOut against a 10 h threshold flips on absolute hours, '
      'not wall-clock hours', () {
    // Spring: the wall clock reads 10 h and the animal has been penned 9, so it
    // is NOT ready. Autumn: the wall clock reads 10 h and the animal has been
    // penned 11, so it is. Same two wall-clock readings, opposite answers —
    // which is the whole reason the arithmetic is absolute.
    expect(
      isReadyToTurnOut(
        enteredAt: Instant.fromDateTime(DateTime(2026, 3, 28, 22)),
        now: Instant.fromDateTime(DateTime(2026, 3, 29, 8)),
        thresholdHours: 10,
      ),
      isFalse,
    );
    expect(
      isReadyToTurnOut(
        enteredAt: Instant.fromDateTime(DateTime(2026, 10, 24, 22)),
        now: Instant.fromDateTime(DateTime(2026, 10, 25, 8)),
        thresholdHours: 10,
      ),
      isTrue,
    );
  });
}

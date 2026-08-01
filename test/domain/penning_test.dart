// test/domain/penning_test.dart — mirrors lib/domain/penning.dart.
//
// Relational: every assertion is a duration between two constructed instants,
// never a wall-clock literal. The absolute-time cases are
// test/domain/uk_zone/penning_dst_test.dart's.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/penning.dart';
import 'package:shed_book/domain/time/instant.dart';

final Instant _penned = Instant.fromDateTime(DateTime.utc(2026, 6, 3, 20));

void main() {
  test('timeSincePenned is now minus enteredAt, exactly', () {
    expect(
      timeSincePenned(_penned, _penned.plus(const Duration(hours: 9, minutes: 30))),
      const Duration(hours: 9, minutes: 30),
    );
    expect(timeSincePenned(_penned, _penned), Duration.zero);
    expect(
      timeSincePenned(_penned, _penned.plus(const Duration(hours: -1))),
      const Duration(hours: -1),
      reason: 'a clock that went backwards is reported, not clamped to zero',
    );
  });

  test('a 24 h threshold: 23:59 is not ready, 24:00 is', () {
    // Both sides of the boundary, because a pen tile flips on it and an
    // off-by-one shows up as an animal held an extra night.
    expect(
      isReadyToTurnOut(
        enteredAt: _penned,
        now: _penned.plus(const Duration(hours: 23, minutes: 59)),
        thresholdHours: 24,
      ),
      isFalse,
    );
    expect(
      isReadyToTurnOut(
        enteredAt: _penned,
        now: _penned.plus(const Duration(hours: 24)),
        thresholdHours: 24,
      ),
      isTrue,
    );
  });

  test('the threshold is a parameter: 6 and 48 give different answers on the same instants', () {
    final Instant now = _penned.plus(const Duration(hours: 24));

    expect(isReadyToTurnOut(enteredAt: _penned, now: now, thresholdHours: 6), isTrue);
    expect(isReadyToTurnOut(enteredAt: _penned, now: now, thresholdHours: 48), isFalse);
  });

  test('no default threshold exists in the signature', () {
    // Asserted by the ANALYZER, not by a runtime expect: `thresholdHours` is
    // `required`, so a call omitting it does not compile and cannot be written
    // here to be tested. A default of 24 would be the app suggesting a husbandry
    // decision — §12.2's origination line — and the column's CHECK of 1..336 is
    // a range guard, not a recommendation.
    //
    // The same goes for `now`. Both are the caller's.
    expect(
      isReadyToTurnOut(enteredAt: _penned, now: _penned, thresholdHours: 1),
      isFalse,
      reason: 'every input named at every call site',
    );
  });

  test("PenExitReason's four stored keys are turned_out, moved, died, other", () {
    expect(PenExitReason.values.map((PenExitReason r) => r.key).toList(), <String>[
      'turned_out',
      'moved',
      'died',
      'other',
    ]);
    for (final PenExitReason r in PenExitReason.values) {
      expect(PenExitReason.fromKey(r.key), r);
    }
    expect(() => PenExitReason.fromKey('turnout'), throwsFormatException);
  });
}

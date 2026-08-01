// DST-1 to DST-5. Destination: test/domain/uk_zone/dst_test.dart
//
// Owned by docs/engineering/05-domain-correctness.md §2.9; mandatory and ship-blocking
// (docs/engineering/12-testing.md §2.3). UK clocks go forward at 01:00 GMT (01:00–01:59 never
// happens) and back at 02:00 BST (01:00–01:59 happens twice). In 2026 those dates are 29 March
// and 25 October. Late March is peak lambing, which is why this is not a footnote.
//
// Run: TZ=Europe/London flutter test test/domain
// The hostile-zone job MUST carry --exclude-tags uk-zone:
//   TZ=Pacific/Chatham flutter test test/domain --exclude-tags uk-zone

@Tags(['uk-zone'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/penning.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/wall_time.dart';
import 'package:shed_book/domain/validation/warning.dart';
import 'package:shed_book/domain/withdrawal/clear_date.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_status.dart';

void main() {
  setUpAll(() {
    // A skipped safety test is a broken safety test. Fail loudly instead.
    expect(DateTime(2026, 7, 1).timeZoneOffset, const Duration(hours: 1),
        reason: 'Run this file with TZ=Europe/London');
  });

  test('DST-1: hours since penned is ABSOLUTE across the spring-forward', () {
    final penned = Instant.fromDateTime(DateTime(2026, 3, 28, 22, 0)); // Sat 22:00 GMT
    final now = Instant.fromDateTime(DateTime(2026, 3, 29, 8, 0)); // Sun 08:00 BST
    expect(timeSincePenned(penned, now), const Duration(hours: 9));
    // The wall clock advanced 10 h. Nine is correct: it is a welfare question
    // about physical hours in a 4x4 pen, and it errs toward turning out later.
  });

  test('DST-2: a lambing recorded in the ambiguous hour round-trips its wall time', () {
    // 01:30 on 25 Oct 2026 happens twice. Dart picks one instant.
    final typed = DateTime(2026, 10, 25, 1, 30);
    final i = Instant.fromDateTime(typed);

    expect(i.local.hour, 1);
    expect(i.local.minute, 30);
    expect(LocalDate.of(i), LocalDate(2026, 10, 25));

    // Exactly one of the two candidate instants, and the export says which.
    final bstCandidate = DateTime.utc(2026, 10, 25, 0, 30).millisecondsSinceEpoch;
    final gmtCandidate = DateTime.utc(2026, 10, 25, 1, 30).millisecondsSinceEpoch;
    expect(i.epochMillis, anyOf(bstCandidate, gmtCandidate));

    // No warning: the displayed time still matches what the user typed, so
    // nothing was silently corrected from the shepherd's point of view.
    // Warning about the ambiguous hour is noise at 3am and is a defect.
    expect(checkLocalWallTimeExists(2026, 10, 25, 1, 30), isEmpty);
  });

  test('DST-3: the nonexistent hour IS warned about', () {
    // `DateTime(2026, 3, 29, 1, 30)` returns 02:30 with no exception — Dart
    // silently correcting a user's entry on our behalf (safety rule §12.4).
    final w = checkLocalWallTimeExists(2026, 3, 29, 1, 30);
    expect(w.single.code, WarningCode.timeDoesNotExistLocally);
    expect(w.single.message, contains('01:30'));
    expect(w.single.message, contains('02:30'));
  });

  test('DST-4: civil-day arithmetic under-counts a 7-day withdrawal by one hour', () {
    final treated = DateTime(2026, 3, 26, 20, 0);
    final civil = DateTime(treated.year, treated.month, treated.day + 7, 20, 0);
    expect(civil.difference(treated).inHours, 167); // the bug
    expect(treated.add(const Duration(days: 7)).difference(treated).inHours, 168); // the rule
  });

  test('DST-5: the clear date is computed in absolute time', () {
    final treated = Instant.fromDateTime(DateTime(2026, 3, 26, 20, 0));
    final status = computeWithdrawalStatus(
      administeredAt: treated,
      period: WithdrawalDays.asEnteredByUser(days: 7, target: WithdrawalTarget.meat),
    ) as ClearsOn;
    expect(status.elapsesAt.local, DateTime(2026, 4, 2, 21, 0)); // 21:00, not 20:00
    expect(status.date, LocalDate(2026, 4, 3));
  });
}

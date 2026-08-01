// test/domain/uk_zone/lambing_checks_dst_test.dart — the three time-shaped
// codes across both UK transitions.
//
// Zone-pinned, so it carries the setUpAll offset guard and FAILS LOUDLY rather
// than skipping when the zone is wrong. A skipped safety test is a broken safety
// test. The zone-agnostic half is test/domain/validation/lambing_validation_test.dart.
@Tags(<String>['uk-zone'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/birth_type.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/recorded_time.dart';
import 'package:shed_book/domain/units/grams.dart';
import 'package:shed_book/domain/validation/lambing_checks.dart';
import 'package:shed_book/domain/validation/warning.dart';

List<Warning> _check({
  required RecordedTime time,
  required LocalDate storedLocalDate,
  Instant? now,
}) => checkLambing(
  declaredBirthType: BirthType.single,
  lambCount: 1,
  time: time,
  storedLocalDate: storedLocalDate,
  seasonStart: LocalDate(2026, 1, 1),
  now: now ?? Instant.fromDateTime(DateTime(2026, 12, 31)),
  birthWeights: const <Grams?>[Grams(4500)],
  lambOutcomes: const <({LocalDate? deathDate, bool isDead})>[],
);

void main() {
  setUpAll(() {
    // The date is a SUMMER one, and that is the whole trick: under
    // Europe/London 1 July is BST so the offset is +1. A winter date's expected
    // value is Duration.zero, which is also UTC's, so the guard would pass on the
    // ubuntu-latest runner and the tier would go green in the wrong zone.
    expect(
      DateTime(2026, 7).timeZoneOffset,
      const Duration(hours: 1),
      reason:
          'Run this file with TZ=Europe/London. '
          'Found ${DateTime(2026, 7).timeZoneName} '
          '(${DateTime(2026, 7).timeZoneOffset})',
    );
  });

  test('a lambing at 01:30 on 25 Oct 2026 — the ambiguous hour — does NOT raise '
      'localDateDisagrees when local_date is 2026-10-25', () {
    // 01:30 happens twice that night. Dart picks one of the two instants and
    // LocalDate.of agrees with the stored day either way, so there is nothing to
    // disagree about. Warning here would be the named anti-pattern: the
    // displayed time still matches what the shepherd typed, so nothing was
    // silently corrected from their point of view, and noise at 3am is a defect.
    final Instant ambiguous = Instant.fromDateTime(DateTime(2026, 10, 25, 1, 30));

    expect(LocalDate.of(ambiguous), LocalDate(2026, 10, 25));
    expect(
      _check(time: RecordedTime.capture(ambiguous), storedLocalDate: LocalDate(2026, 10, 25)),
      isEmpty,
    );
  });

  test('a lambing at 01:30 on 29 Mar 2026 — the hour that does not exist — is '
      'Dart-shifted to 02:30 and still does not raise localDateDisagrees', () {
    // Dart moves a nonexistent local time FORWARD with no exception, which is
    // Dart violating §12.4 on our behalf. checkLocalWallTimeExists (N04-T08) is
    // what detects that, and it is a different code and a different function.
    // What must NOT happen is a second, spurious warning here: the shifted
    // instant is still on 29 March, so the stored day still agrees.
    final Instant shifted = Instant.fromDateTime(DateTime(2026, 3, 29, 1, 30));

    expect(shifted.local.hour, 2, reason: 'silently moved to 02:30');
    expect(shifted.local.minute, 30);
    expect(LocalDate.of(shifted), LocalDate(2026, 3, 29));
    expect(
      _check(time: RecordedTime.capture(shifted), storedLocalDate: LocalDate(2026, 3, 29)),
      isEmpty,
    );
  });

  test('lambingLongBeforeCapture across the spring-forward measures 168 h, not 167', () {
    // DST-4's civil-arithmetic bug, re-asserted at THIS call site rather than
    // assumed to carry over. The threshold is 3 days = 72 absolute hours; a
    // civil implementation would compute 71 across the transition and fire an
    // hour early, on the weekend that is also peak lambing.
    final Instant effective = Instant.fromDateTime(DateTime(2026, 3, 26, 20));
    final Instant capturedSevenDaysLater = Instant.fromDateTime(DateTime(2026, 4, 2, 21));

    expect(
      capturedSevenDaysLater.difference(effective),
      const Duration(hours: 168),
      reason: 'the wall clock says 26 Mar 20:00 to 2 Apr 21:00; absolute time says 168 h',
    );

    final List<Warning> warnings = _check(
      time: RecordedTime.entered(effective: effective, now: capturedSevenDaysLater),
      storedLocalDate: LocalDate(2026, 3, 26),
    );
    expect(warnings.single.code, WarningCode.lambingLongBeforeCapture);

    // And the boundary itself, in the zone where civil and absolute disagree.
    // Exactly 72 h does not warn; the trigger is strictly greater.
    final Instant exactlyThreeDays = effective.plus(const Duration(hours: 72));
    expect(
      _check(
        time: RecordedTime.entered(effective: effective, now: exactlyThreeDays),
        storedLocalDate: LocalDate(2026, 3, 26),
      ),
      isEmpty,
      reason: 'civil-day arithmetic would call this 73 h and warn',
    );
  });
}

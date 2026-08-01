// test/domain/uk_zone/ambiguous_hour_test.dart — DST-1 … DST-4.
//
// The owner settled the region: UK / Ireland, so the ambiguous and the
// nonexistent hour are both 01:00–01:59. Clocks go forward at 01:00 GMT
// (01:00–01:59 never happens) and back at 02:00 BST (01:00–01:59 happens
// twice). In 2026 those dates are 29 March and 25 October. Late March is
// precisely when UK and Irish lambing happens, which is why this is not a
// footnote. The years are hard-coded on purpose — a computed "last Sunday in
// March" helper would be a reimplementation of the thing under test.
//
// FILE-NAME DISAGREEMENT, recorded rather than resolved silently.
// 00-PLAN-CRITIQUE.md's [audit] row spells this test/domain/uk_zone/dst_test.dart
// and rules DST-1…DST-5 into ONE tagged file. The task files split them: this
// file holds DST-1…DST-4 and N05-T02's clear_date_dst_test.dart holds DST-5.
// Both anchors are fixed by the backlog and both are preserved. It is raised in
// the pull request body; if the owner rules for one file, the rename happens
// here and N05-T02's anchor follows.
//
// DST-5 is deliberately absent. It asserts computeWithdrawalStatus, which is
// N05-T03's function, and hand-inlining a ceil-to-next-local-midnight to make a
// fifth case appear would be a test that reimplements the function under test —
// it proves nothing and passes after the real function regresses. The DoD line
// "the five DST cases exist and pass" is a TIER-level property, satisfied when
// N05-T02 merges.
//
// None of the four cases installs a clock. They take their instants as
// literals, which is what keeps them safe under
// `--test-randomize-ordering-seed random`.
@Tags(<String>['uk-zone'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/wall_time.dart';
import 'package:shed_book/domain/validation/warning.dart';

void main() {
  setUpAll(() {
    // A skipped safety test is a broken safety test. Fail loudly instead — no
    // `skip:`, no TZ-conditional wrapper.
    //
    // The date is a SUMMER one and that is the whole trick. Under Europe/London
    // 1 July is BST, so the offset is +1. Assert a winter date instead and the
    // expected value is Duration.zero — which is also UTC's offset, so the guard
    // would pass on the ubuntu-latest runner and the whole tier would go green
    // in the wrong zone. One date literal is the difference between a real gate
    // and a decorative one.
    expect(
      DateTime(2026, 7).timeZoneOffset,
      const Duration(hours: 1),
      reason:
          'Run this file with TZ=Europe/London. '
          'Found ${DateTime(2026, 7).timeZoneName} '
          '(${DateTime(2026, 7).timeZoneOffset})',
    );
  });

  test('DST-1: hours since penned is ABSOLUTE across the spring-forward', () {
    final Instant penned = Instant.fromDateTime(DateTime(2026, 3, 28, 22)); // Sat 22:00 GMT
    final Instant now = Instant.fromDateTime(DateTime(2026, 3, 29, 8)); // Sun 08:00 BST
    expect(now.difference(penned), const Duration(hours: 9));
    // The wall clock advanced 10 h. Nine is correct: it is a welfare question
    // about physical hours in a 4x4 pen, and it errs toward turning out later.
    //
    // Instant.difference, not timeSincePenned: that function is N06-T07's and
    // gives the identical answer. When it lands, add its assertion BESIDE this
    // one rather than replacing it — two callers, one number.
  });

  test('01:30 on the clocks-back night resolves without throwing and the suite '
      'fails loudly under a wrong TZ', () {
    // DST-2, stated as the property the backlog anchors on: the round trip and
    // the setUpAll guard above are one claim.
    //
    // 01:30 on 25 Oct 2026 happens twice. Dart picks one instant and the app
    // does not care which, because both render as 01:30 and the exported UTC
    // column disambiguates.
    final DateTime typed = DateTime(2026, 10, 25, 1, 30);
    final Instant i = Instant.fromDateTime(typed);

    expect(i.local.hour, 1);
    expect(i.local.minute, 30);
    // The one that would put a bar in the wrong column of the lambing-spread
    // histogram.
    expect(LocalDate.of(i), LocalDate(2026, 10, 25));

    // anyOf, deliberately: asserting a single epoch value pins an
    // implementation detail of the VM's zone handling and will fail on some
    // future tzdata.
    final int bstCandidate = DateTime.utc(2026, 10, 25, 0, 30).millisecondsSinceEpoch;
    final int gmtCandidate = DateTime.utc(2026, 10, 25, 1, 30).millisecondsSinceEpoch;
    expect(i.epochMillis, anyOf(bstCandidate, gmtCandidate));

    // No warning: the displayed time still matches what the shepherd typed, so
    // nothing was silently corrected from their point of view. Adding one here
    // is a named anti-pattern, not an improvement.
    expect(checkLocalWallTimeExists(2026, 10, 25, 1, 30), isEmpty);
  });

  test('DST-3: the nonexistent hour IS warned about', () {
    // The mirror of DST-2. Dart moves a nonexistent local time forward with NO
    // exception — DateTime(2026, 3, 29, 1, 30) is silently 02:30 — which is Dart
    // violating safety rule §12.4 on our behalf, so we detect it.
    final List<Warning> w = checkLocalWallTimeExists(2026, 3, 29, 1, 30);
    expect(w.single.code, WarningCode.timeDoesNotExistLocally);
    expect(w.single.message, contains('01:30'));
    expect(w.single.message, contains('02:30'));
    expect(w.single.fieldPath, 'time');
  });

  test('DST-4: civil-day arithmetic under-counts a 7-day withdrawal by one hour', () {
    final DateTime treated = DateTime(2026, 3, 26, 20);
    final DateTime civil = DateTime(treated.year, treated.month, treated.day + 7, 20);
    final DateTime absolute = treated.add(const Duration(days: 7));

    expect(civil.difference(treated), const Duration(hours: 167));
    expect(absolute.difference(treated), const Duration(hours: 168));
    // One hour short of a seven-day withdrawal, in late March, on the side that
    // clears the animal early. This is why clearDateFor adds
    // Duration(hours: days * 24) to an Instant and never adds civil days.
    expect(absolute.difference(civil), const Duration(hours: 1));
    expect(absolute.hour, 21);
    expect(civil.hour, 20);
  });
}

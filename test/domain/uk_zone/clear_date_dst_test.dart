// test/domain/uk_zone/clear_date_dst_test.dart — DST-5, and the four clear-date
// cases the UK transitions bite.
//
// This is the tier N04-T08 built and this is its first real inhabitant. Every
// assertion here is an ABSOLUTE wall-clock value, which is exactly why the file
// is tagged: CI runs test/domain a second time under TZ=Pacific/Chatham with
// --exclude-tags uk-zone, and these cases are correctly red in a hostile zone.
// The relational, zone-agnostic half is test/domain/withdrawal/clear_date_test.dart.
//
// DST-5 landed here in two halves, because the function it names spans two
// tasks. 05 §2.9 writes it through computeWithdrawalStatus (N05-T03); the
// arithmetic underneath it is clearDateFor (N05-T02). BOTH forms are present and
// both are assertions on the same number — two callers, one answer. A rewrite
// that fixes one caller and not the other is what the pair catches, so do not
// collapse them.
//
// FILE-NAME DISAGREEMENT, recorded rather than resolved silently, and the same
// one ambiguous_hour_test.dart records: 00-PLAN-CRITIQUE.md's [audit] row rules
// DST-1…DST-5 into one file called test/domain/uk_zone/dst_test.dart. The task
// files split them across two names, and both names are fixed by the backlog. It
// is raised in the pull request body; if the owner rules for one file, both
// anchors move together.
@Tags(<String>['uk-zone'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/wall_time.dart';
import 'package:shed_book/domain/validation/treatment_checks.dart';
import 'package:shed_book/domain/validation/warning.dart';
import 'package:shed_book/domain/withdrawal/clear_date.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_status.dart';

void main() {
  setUpAll(() {
    // A skipped safety test is a broken safety test. Fail loudly instead — no
    // `skip:`, no TZ-conditional wrapper.
    //
    // The date is a SUMMER one and that is the whole trick. Under Europe/London
    // 1 July is BST, so the offset is +1. Assert a winter date instead and the
    // expected value is Duration.zero — which is also UTC's offset, so the guard
    // would pass on the ubuntu-latest runner and the whole tier would go green
    // in the wrong zone.
    expect(
      DateTime(2026, 7).timeZoneOffset,
      const Duration(hours: 1),
      reason:
          'Run this file with TZ=Europe/London. '
          'Found ${DateTime(2026, 7).timeZoneName} '
          '(${DateTime(2026, 7).timeZoneOffset})',
    );
  });

  test('7 days across UK spring-forward is 168 h absolute, and civil-day '
      'arithmetic would give 167', () {
    final DateTime treated = DateTime(2026, 3, 26, 20);

    // Both numbers are pinned, so a future "simplification" to civil-day
    // arithmetic fails CI with the two figures side by side rather than with a
    // date that merely looks wrong.
    expect(
      treated.add(const Duration(days: 7)).difference(treated).inHours,
      168,
      reason: 'the rule',
    );
    expect(
      DateTime(treated.year, treated.month, treated.day + 7, 20).difference(treated).inHours,
      167,
      reason: 'the bug: one hour short of a seven-day withdrawal, in late March',
    );

    // And the function under test is on the correct side of that difference.
    final ({LocalDate date, Instant elapsesAt}) r = clearDateFor(
      administeredAt: Instant.fromDateTime(treated),
      days: 7,
    );
    expect(r.elapsesAt.local, DateTime(2026, 4, 2, 21));
    expect(r.date, LocalDate(2026, 4, 3));
  });

  test('a 7-day withdrawal administered at 20:00 on 26 March 2026 clears on 3 April 2026', () {
    // The 21:00 is the whole point: the period elapses an hour later on the wall
    // clock than it was administered, because the clocks went forward inside the
    // window. 2 April is therefore only PARTLY clear, and the first fully clear
    // day is 3 April.
    final ({LocalDate date, Instant elapsesAt}) r = clearDateFor(
      administeredAt: Instant.fromDateTime(DateTime(2026, 3, 26, 20)),
      days: 7,
    );

    expect(r.elapsesAt.local.hour, 21, reason: 'not 20:00 — the clocks moved inside the window');
    expect(r.elapsesAt.local, DateTime(2026, 4, 2, 21));
    expect(r.date, LocalDate(2026, 4, 3));
  });

  test('DST-5: the clear date is computed in absolute time', () {
    // 05 §2.9 writes DST-5 through computeWithdrawalStatus rather than through
    // clearDateFor, because the status arm is what a screen actually calls — so
    // the zone regression is pinned at that level too. This sits BESIDE the
    // clearDateFor case above rather than replacing it: two callers, one number,
    // and a rewrite that fixes one without the other is exactly what a pair of
    // assertions catches.
    final ClearsOn status =
        computeWithdrawalStatus(
              administeredAt: Instant.fromDateTime(DateTime(2026, 3, 26, 20)),
              period: WithdrawalDays.asEnteredByUser(days: 7, target: WithdrawalTarget.meat),
            )
            as ClearsOn;

    expect(status.elapsesAt.local, DateTime(2026, 4, 2, 21));
    expect(status.date, LocalDate(2026, 4, 3));
    expect(status.target, WithdrawalTarget.meat);
  });

  test('a period administered at local midnight across the spring-forward '
      'clears the following day', () {
    // The case that proves the exactly-at-midnight equality is not dead code and
    // is not a `<=`. Administered at local midnight on 25 March; 168 absolute
    // hours later it is 01:00 BST on 1 April, NOT local midnight, because the
    // spring-forward moved it. So 1 April is partial and the clear date is 2
    // April. Loosen the equality and this case silently clears a day early.
    final ({LocalDate date, Instant elapsesAt}) r = clearDateFor(
      administeredAt: Instant.fromDateTime(DateTime(2026, 3, 25)),
      days: 7,
    );

    expect(r.elapsesAt.local, DateTime(2026, 4, 1, 1));
    expect(LocalDate.of(r.elapsesAt), LocalDate(2026, 4, 1));
    expect(r.date, LocalDate(2026, 4, 2));
  });

  test('a 7-day withdrawal across the clocks-back night is still 168 absolute hours', () {
    // The autumn direction — the same defect pointing the other way. Civil
    // arithmetic OVER-counts here, to 169 h, which is the harmless direction and
    // is exactly why the spring case is the one that ships bad meat. Both are
    // pinned, because a rewrite that gets one right by accident gets the other
    // wrong.
    final DateTime treated = DateTime(2026, 10, 22, 20);

    expect(
      DateTime(treated.year, treated.month, treated.day + 7, 20).difference(treated).inHours,
      169,
    );
    expect(treated.add(const Duration(days: 7)).difference(treated).inHours, 168);

    final ({LocalDate date, Instant elapsesAt}) r = clearDateFor(
      administeredAt: Instant.fromDateTime(treated),
      days: 7,
    );
    expect(r.elapsesAt.local, DateTime(2026, 10, 29, 19));
    expect(r.date, LocalDate(2026, 10, 30));
  });

  test('a clear date recorded by civil-day arithmetic across the spring-forward '
      'disagrees by exactly one day and is not corrected', () {
    // The disagreement's real-world origin story, in the zone where it happens.
    // 2 April is what the civil-day bug would have written for this treatment;
    // the arithmetic now produces 3 April. One warning, both dates in it, and 2
    // April is still what the caller holds afterwards — because a clear date is
    // a record of what the app told the user on the day, and it may already have
    // been printed into a medicine book handed to a vet.
    final LocalDate whatTheBugWrote = LocalDate(2026, 4, 2);

    final List<Warning> warnings = checkClearDate(
      administeredAt: Instant.fromDateTime(DateTime(2026, 3, 26, 20)),
      days: 7,
      storedClearDate: whatTheBugWrote,
    );

    expect(warnings.single.code, WarningCode.clearDateDisagrees);
    expect(warnings.single.message, contains('2026-04-02'));
    expect(warnings.single.message, contains('2026-04-03'));
    expect(whatTheBugWrote.daysUntil(LocalDate(2026, 4, 3)), 1);
  });

  test('a treatment administered in the ambiguous hour on 25 October 2026 '
      'clears from the stored instant', () {
    // 01:30 happens twice. Whichever of the two instants Dart chose is the one
    // the clear date is computed from, and both land on the same answer — which
    // is why this is assertable at all without pinning a VM implementation
    // detail. Adding a warning here is a named anti-pattern: the displayed time
    // still matches what the shepherd typed, so nothing was silently corrected
    // from their point of view, and noise at 3am is a defect.
    final Instant administered = Instant.fromDateTime(DateTime(2026, 10, 25, 1, 30));
    final ({LocalDate date, Instant elapsesAt}) r = clearDateFor(
      administeredAt: administered,
      days: 7,
    );

    expect(LocalDate.of(r.elapsesAt), LocalDate(2026, 11, 1), reason: 'either candidate instant');
    expect(r.date, LocalDate(2026, 11, 2));
    expect(r.elapsesAt.difference(administered), const Duration(hours: 168));
    expect(checkLocalWallTimeExists(2026, 10, 25, 1, 30), isEmpty);
  });
}

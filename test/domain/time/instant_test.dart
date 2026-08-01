// test/domain/time/instant_test.dart — mirrors lib/domain/time/instant.dart
// (CONVENTIONS §4.1).
//
// **Zone-agnostic by construction.** This file must be identically green under
// TZ=Pacific/Chatham and TZ=Europe/London, so every assertion is relational or
// UTC-anchored and there is no `@Tags` on it. The wall-clock forms of the
// repeated hour — `DateTime(2026, 10, 25, 1, 30)` with no `isUtc` — belong in
// test/domain/uk_zone/ambiguous_hour_test.dart (N04-T08); written here they
// would make this file pass or fail on the runner's TZ.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/time/instant.dart';

/// [path]'s source with every comment line removed, so a member scan reads
/// declarations and not the prose that documents them.
String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

void main() {
  test('Instant exposes no now() and orders by epoch millis', () {
    // There is no runtime reflection to assert an absent member with:
    // dart:mirrors is unavailable under Flutter and every test here imports
    // flutter_test (#4). So read the ONE named file's source. A scan over lib/
    // would belong in tool/check_policy.dart, not in a test (12 §1.4) — and the
    // gate cannot catch this one anyway: `factory Instant.now()` built on
    // clock.now() trips layer.domain and one built on the wall-clock reader
    // trips
    // time.dart_clock, but neither fires on the member's existence.
    //
    // Comment lines are dropped before matching. The doc comments legitimately
    // use the word — "now.difference(penned) is positive when now is later" is
    // how the operand order is documented — and a scan that cannot tell a
    // declaration from prose about one is the same failure as a scan that
    // cannot tell a prohibition from a claim.
    final String declarations = _declarations('lib/domain/time/instant.dart');
    expect(
      RegExp(r'\bnow\b').hasMatch(declarations),
      isFalse,
      reason: 'Instant.now() is a banned spelling — CONVENTIONS §2.2. appNow() is the one reader',
    );
    expect(
      declarations,
      isNot(contains('fromUtc')),
      reason: 'Instant.fromUtc() is a banned spelling',
    );

    const Instant t1 = Instant(1000);
    const Instant t2 = Instant(2000);
    const Instant t3 = Instant(3000);
    expect(<Instant>[t3, t1, t2]..sort(Instant.ascending), <Instant>[t1, t2, t3]);
  });

  test('fromDateTime is zone-independent', () {
    final DateTime utc = DateTime.utc(2026, 3, 4, 3, 20);
    expect(Instant.fromDateTime(utc), Instant.fromDateTime(utc.toLocal()));
  });

  test('plus and difference are absolute, not civil', () {
    // 168 hours, not seven calendar days. Across the UK spring-forward those
    // differ by an hour and the difference lands in a withdrawal period, which
    // is why there is no plusDays on this type — calendar arithmetic is
    // LocalDate's and belongs nowhere near a withdrawal.
    for (final DateTime anchor in <DateTime>[
      DateTime.utc(2026, 3, 26, 22), // before the spring-forward
      DateTime.utc(2026, 10, 24, 22), // before the autumn repeat
    ]) {
      final Instant t = Instant.fromDateTime(anchor);
      expect(t.plus(const Duration(days: 7)).difference(t).inHours, 168);
    }
  });

  test('difference is this minus other', () {
    const Instant earlier = Instant(1000);
    const Instant later = Instant(4000);
    expect(later.difference(earlier), const Duration(milliseconds: 3000));
    expect(earlier.difference(later), const Duration(milliseconds: -3000));
  });

  test('isBefore, isAfter and compareTo agree', () {
    const Instant a = Instant(10);
    const Instant b = Instant(20);
    expect(a.isBefore(b), isTrue);
    expect(b.isAfter(a), isTrue);
    expect(a.compareTo(b), lessThan(0));
    expect(b.compareTo(a), greaterThan(0));
    // The equal case, which is the one an off-by-one gets wrong.
    expect(a.isBefore(a), isFalse);
    expect(a.isAfter(a), isFalse);
    expect(a.compareTo(a), 0);
  });

  test('descending is the exact reverse of ascending', () {
    const List<Instant> unsorted = <Instant>[Instant(3), Instant(1), Instant(2)];
    final List<Instant> up = <Instant>[...unsorted]..sort(Instant.ascending);
    final List<Instant> down = <Instant>[...unsorted]..sort(Instant.descending);
    expect(down, up.reversed.toList());
  });

  test('equality and hashCode come from the representation', () {
    // Written by nobody: they come from int, which is what makes an Instant a
    // safe Map key. Adding an == of your own is dead code the analyzer will not
    // flag.
    expect(const Instant(1), const Instant(1));
    expect(<Instant, String>{const Instant(1): 'a'}[const Instant(1)], 'a');
  });

  test('the two candidate instants of the repeated hour are exactly one hour apart', () {
    // The ambiguous-hour property, stated without a TZ. Instant is unperturbed
    // by the repeat: absolute time has no repeated hour, only wall-clock time
    // does. That is the whole reason instants are stored and civil dates are not.
    final Instant first = Instant.fromDateTime(DateTime.utc(2026, 10, 25, 0, 30));
    final Instant second = Instant.fromDateTime(DateTime.utc(2026, 10, 25, 1, 30));
    expect(second.difference(first), const Duration(hours: 1));
    expect(first.utc, DateTime.utc(2026, 10, 25, 0, 30));
    expect(second.utc, DateTime.utc(2026, 10, 25, 1, 30));
  });

  test('a negative epoch is a real instant', () {
    expect(const Instant(-1).isBefore(const Instant(0)), isTrue);
    expect(const Instant(-1).utc.year, 1969);
  });

  test('const Instant is a compile-time constant', () {
    // The representation constructor is const, so a 400-row flock list of these
    // allocates nothing.
    const Instant a = Instant(0);
    expect(identical(a, const Instant(0)), isTrue);
  });
}

// test/domain/ids_test.dart — the sixteen ids, and this epic's first red.
//
// It carries a BirthType assertion rather than an id assertion because ids.dart
// is the first file everything else imports and this is the epic's opening
// anchor. The rest of the birth-type cases live in test/domain/birth_type_test.dart,
// where CONVENTIONS §4.1 puts them.
//
// No uk-zone case: nothing in this task carries a time, so there is nothing for
// the ambiguous 01:00–01:59 hour to bite. The first time-shaped work in this
// epic is N06-T06's lambing spread.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/birth_type.dart';
import 'package:shed_book/domain/ids.dart';

void main() {
  test('expectedLambCount is null for quintPlus and never zero', () {
    // Both halves said out loud, because `expect(x, isNull)` alone also passes
    // for a function that returns null for everything.
    expect(
      expectedLambCount(BirthType.quintPlus),
      isNull,
      reason: 'quad-or-more is open-ended: a contradiction is UNDEFINED, not false',
    );
    expect(expectedLambCount(BirthType.twin), 2);
    expect(BirthType.quintPlus.code, 5, reason: 'the stored code is 5; the expected count is not');
  });

  test('every id exposes .value and nothing else', () {
    // All sixteen, because R33's rule — a bare int never crosses a repository,
    // controller, route-helper or provider-family boundary — gets broken by a
    // repository written in N14 against an id type nobody created. Sixteen ids
    // exist here though sixteen tables do not, so that violation is a compile
    // error rather than a habit.
    expect(const EweId(1).value, 1);
    expect(const EweSeasonId(2).value, 2);
    expect(const LambingId(3).value, 3);
    expect(const LambId(4).value, 4);
    expect(const FosterEventId(5).value, 5);
    expect(const CareEventId(6).value, 6);
    expect(const EweObservationId(7).value, 7);
    expect(const PenId(8).value, 8);
    expect(const PenOccupancyId(9).value, 9);
    expect(const TreatmentId(10).value, 10);
    expect(const TreatmentWithdrawalId(11).value, 11);
    expect(const ReminderId(12).value, 12);
    expect(const NoteId(13).value, 13);
    expect(const MediaAssetId(14).value, 14);
    expect(const SeasonId(15).value, 15);
    expect(const VocabTermId(16).value, 16);
  });

  test('two id types with the same value are equal at run time — extension types erase', () {
    // Asserted so nobody builds on the opposite, and MEASURED rather than
    // assumed — writing this case found that the boundary is not where
    // 05 §2.3's summary suggests.
    //
    // What the compiler DOES stop, and it is more than expected:
    //
    //   * an extension type declaring no `implements` is not assignable to
    //     Object, so a Map keyed by Object cannot hold one at all;
    //   * `EweId(3) == LambId(3)` written directly is an ANALYZER ERROR under
    //     --fatal-infos (unrelated_type_equality_checks), not merely a lint.
    //
    // So the equality below has to be reached through `dynamic` — which is
    // exactly the point. Everything that goes through `dynamic` (a JSON map, a
    // Map<dynamic, …>, an Object? slot reached by inference) sees a bare int,
    // and nothing warns there.
    final dynamic asDynamic = const EweId(3);
    final dynamic otherType = const LambId(3);
    expect(asDynamic == otherType, isTrue);
    expect(asDynamic.runtimeType, int, reason: 'the run-time type is the representation');
    expect(asDynamic is int, isTrue);
    expect(
      asDynamic is EweId,
      isTrue,
      reason: 'and so is a bare int: an `is`-check on an id discriminates nothing',
    );

    final Map<dynamic, String> keyedByOne = <dynamic, String>{const EweId(3): 'ewe'};
    expect(keyedByOne[const LambId(3)], 'ewe', reason: 'a different id type hits the same entry');
    expect(keyedByOne[3], 'ewe', reason: 'and so does a bare 3');
  });
}

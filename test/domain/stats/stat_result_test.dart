// test/domain/stats/stat_result_test.dart — the shape every statistic returns.
//
// No uk-zone case: these are shapes, not arithmetic over time. DayBirths carries
// a LocalDate but computes nothing with it, and the first time-shaped assertions
// in this epic are N06-T06's spread cases.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/stats/definitions.dart';

void main() {
  test('a statistic with no denominator returns notComputableReason, never 0', () {
    const StatResult r = StatResult.notComputable(
      definition: 'lambs born alive per ewe put to the ram',
      reason: kEwesToRamNotEntered,
    );

    // Both halves. `isNull` alone also passes for a type whose value is always
    // null; the second line is the one that says a zero is not standing in for
    // the absence.
    expect(r.value, isNull);
    expect(r.value, isNot(0));
    expect(r.notComputableReason, isNotEmpty);
    expect(r.definition, isNotEmpty);
  });

  test('a computable result carries value, numerator, denominator and definition together', () {
    // numerator/denominator render beside the number ("6 / 5") because it is the
    // cheapest way for a shepherd to sanity-check a figure that looks wrong, and
    // at 18 pt it costs one line. There is no constructor that omits any of them.
    const StatResult r = StatResult(
      value: 1.2,
      definition: 'lambs born alive per ewe put to the ram',
      numerator: 6,
      denominator: 5,
    );

    expect(r.value, 1.2);
    expect(r.numerator, 6);
    expect(r.denominator, 5);
    expect(r.definition, 'lambs born alive per ewe put to the ram');
    expect(r.notComputableReason, isNull);
  });

  test('caveats defaults to const [] and is never null', () {
    const StatResult computable = StatResult(
      value: 1.2,
      definition: 'd',
      numerator: 6,
      denominator: 5,
    );
    const StatResult refused = StatResult.notComputable(definition: 'd', reason: 'r');

    expect(computable.caveats, isEmpty);
    expect(refused.caveats, isEmpty);
    expect(identical(computable.caveats, const <String>[]), isTrue);
  });

  test('notComputable leaves numerator and denominator at 0 and value null', () {
    // They are STRUCTURAL PLACEHOLDERS, not counts. Nothing may render them when
    // value is null: notComputableReason is the value's replacement, and "0 / 0"
    // printed beside it reads as a real measurement.
    const StatResult r = StatResult.notComputable(definition: 'd', reason: 'r');

    expect(r.value, isNull);
    expect(r.numerator, 0);
    expect(r.denominator, 0);
    expect(r.notComputableReason, 'r');
  });

  test('there is no StatResult constructor without a definition', () {
    // 05 §9 row 21, and it is the mechanism rather than a convention: a bare
    // percentage cannot be CONSTRUCTED, so it cannot be rendered. The compile is
    // the assertion — both constructors take `definition` as required.
    const StatResult a = StatResult(value: 0, definition: 'd', numerator: 0, denominator: 4);
    expect(a.definition, isNotEmpty);
    expect(
      a.value,
      0,
      reason: 'a genuine zero IS representable — it is a measured 0/4, not an absence',
    );
  });

  test('the notComputable reasons are named constants, not sentences typed at call sites', () {
    // "A closed set with display text" without an enum. Two call sites that word
    // the same refusal differently produce two statistics §6.11 then refuses to
    // compare — so the wording exists once and is referenced.
    for (final String reason in <String>[
      kEwesToRamNotEntered,
      kNoEwesLambed,
      kNoLambingsScored,
      kDenominatorIsZero,
    ]) {
      expect(reason, isNotEmpty);
      expect(reason, endsWith('.'), reason: 'it renders as a sentence in place of the number');
    }
  });
}

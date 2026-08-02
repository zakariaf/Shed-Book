// test/domain/units_test.dart — parseUserNumber and WeightUnit.
//
// NAMING DEVIATION, recorded rather than silently fixed. CONVENTIONS §4.1 says a
// test mirrors the file under test, which would spell this
// test/domain/units/parse_number_test.dart. The backlog fixed the anchor at this
// path and 00-PLAN-CRITIQUE.md's first-failing-test table references it, so the
// anchor is preserved verbatim: this file holds parseUserNumber and WeightUnit,
// and units/grams_test.dart mirrors grams.dart.
//
// Zone-agnostic, no @Tags.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/units/grams.dart';
import 'package:shed_book/domain/units/parse_number.dart';
import 'package:shed_book/domain/units/weight_unit.dart';

void main() {
  test('parseUserNumber returns null for 1,5 rather than guessing 15 or 1.5', () {
    expect(parseUserNumber('1,5'), isNull);
  });

  test('every ambiguous input returns null', () {
    for (final String bad in <String>[
      '1,5',
      '4,3',
      '1,5.5',
      '1.5,5',
      '1.234.5',
      '1,234,5',
      '1 234,5',
      '--4',
      '4.',
      '.',
      ',',
      '4,',
      'abc',
      '',
      '4 kg',
      '4.5.6',
      // double.tryParse accepts all four of these and a shepherd types none of
      // them on a keypad with one decimal key.
      '1e3',
      '0x10',
      'Infinity',
      'NaN',
    ]) {
      expect(parseUserNumber(bad), isNull, reason: '"$bad"');
    }
  });

  test('every unambiguous input parses', () {
    expect(parseUserNumber('4'), 4.0);
    expect(parseUserNumber('4.5'), 4.5);
    expect(parseUserNumber('0'), 0.0);
    expect(parseUserNumber('0.5'), 0.5);
    expect(parseUserNumber('-4.5'), -4.5);
    expect(parseUserNumber('  4.5  '), 4.5);
    // Spaces are stripped before counting, so a fat-fingered space between the
    // digits and the point is not an ambiguity.
    expect(parseUserNumber('4 . 5'), 4.5);
  });

  test('null is never coerced to a number by the parser itself', () {
    final String source = File(
      'lib/domain/units/parse_number.dart',
    ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');
    expect(source, isNot(contains('?? 0')));
    expect(source, isNot(contains('orElse')));
  });

  test('WeightUnit keys are kg and lb, in that order', () {
    expect(
      WeightUnit.values.map((WeightUnit u) => u.key).toList(),
      <String>['kg', 'lb'],
      reason:
          "byte-identical to app_settings.weight_unit's CHECK (R68), written at N07. "
          'A mismatch surfaces as a CHECK failure on a real phone, not as a compile error',
    );
  });

  test('fromKey round-trips and throws on anything else', () {
    for (final WeightUnit u in WeightUnit.values) {
      expect(WeightUnit.fromKey(u.key), u);
    }
    for (final String bad in <String>['kgs', 'KG', 'pounds', '']) {
      expect(() => WeightUnit.fromKey(bad), throwsFormatException, reason: bad);
    }
  });

  test('a weight typed in lb round-trips through canonical grams without rewriting the entry', () {
    // N17-T02's ANCHOR, DOMAIN HALF. The widget half — type the digits, read the
    // committed column, re-open the cell — lives in lamb_card_test.dart; this is
    // the arithmetic underneath it, and it is here because a round trip that
    // fails does so in the conversion rather than in the sheet.
    //
    // THE PROPERTY: what the shepherd typed is what they see again. Canonical
    // storage is integer grams (#42), so a lb entry converts on the way in and
    // back on the way out, and the app must never rewrite the entry to make the
    // arithmetic tidy — 9 lb 1 oz that comes back as 9 lb 0 oz is §12.4 with a
    // rounding error's face on.
    for (final ({int lb, double oz}) typed in <({int lb, double oz})>[
      (lb: 9, oz: 1),
      (lb: 4, oz: 0),
      (lb: 12, oz: 15),
      (lb: 1, oz: 8),
    ]) {
      final Grams stored = Grams.fromPoundsOunces(typed.lb, typed.oz);

      // `poundsOunces`, THE DISPLAY PAIR — not `wholePounds` beside
      // `remainderOunces.round()`, which is the two-roundings-at-two-scales bug
      // this case found. Measured before the fix: 4 lb came back as "3 lb 16 oz"
      // and three of the four cases named a quantity that does not exist.
      final ({int pounds, int ounces}) back = stored.poundsOunces;

      expect(back.pounds, typed.lb, reason: '${typed.lb} lb ${typed.oz} oz');
      expect(back.ounces, typed.oz.round(), reason: '${typed.lb} lb ${typed.oz} oz');
      expect(back.ounces, lessThan(16), reason: 'sixteen ounces is a pound');
    }
  });

  test('a weight typed in kg round-trips at the one decimal the keypad offers', () {
    // THE OTHER UNIT, and the resolution the entry path actually has. The keypad
    // gives one decimal place, so the property is stated at one decimal rather
    // than at full double precision — claiming more would be claiming a
    // precision no shepherd can type.
    for (final double kg in <double>[4.1, 0.9, 12.0, 7.5]) {
      final Grams stored = Grams.fromKilograms(kg);
      expect(stored.inKilograms, closeTo(kg, 0.05), reason: '$kg kg');
    }
  });

  test('the two units are the same weight, and neither is stored', () {
    // R68 AND #42 TOGETHER. `WeightUnit` is a DISPLAY choice from
    // `unitsProvider`; the column is grams and nothing else. This case is what
    // makes that concrete: the same mass entered either way is the same integer,
    // so switching the display unit cannot change a record.
    final Grams viaKg = Grams.fromKilograms(4.1);
    final Grams viaLb = Grams.fromPounds(4.1 * 2.20462);

    expect((viaKg.value - viaLb.value).abs(), lessThanOrEqualTo(1), reason: 'one gram of rounding');
  });
}

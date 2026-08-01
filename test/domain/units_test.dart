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
}

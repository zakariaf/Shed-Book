// test/domain/temperature_test.dart — MilliCelsius.
//
// NAMING DEVIATION, recorded rather than silently fixed. CONVENTIONS §4.1's
// mirror rule would spell this test/domain/units/milli_celsius_test.dart. The
// backlog fixed the anchor at this path and 00-PLAN-CRITIQUE.md references it.
//
// Zone-agnostic — nothing here touches a clock or a zone. This is the one file
// in the epic with no time-shaped case to place in the ambiguous hour, and that
// absence is itself the property: a temperature carries no instant, so nothing
// about it can move when the clocks do.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/units/milli_celsius.dart';

void main() {
  test('a temperature entered in °F round-trips through MilliCelsius without drifting', () {
    for (int tenths = 950; tenths <= 1150; tenths++) {
      final double f = tenths / 10.0;
      final MilliCelsius t = MilliCelsius.fromFahrenheit(f);
      expect(double.parse(t.inFahrenheit.toStringAsFixed(1)), closeTo(f, 1e-9), reason: '$f F');
    }
  });

  test('a °C entry round-trips at 1 dp across the shed range', () {
    for (int tenths = -200; tenths <= 450; tenths++) {
      final double c = tenths / 10.0;
      final MilliCelsius t = MilliCelsius.fromCelsius(c);
      expect(double.parse(t.inCelsius.toStringAsFixed(1)), closeTo(c, 1e-9), reason: '$c C');
    }
  });

  test('0.1 °C canonical WOULD corrupt 89 of 201 Fahrenheit entries', () {
    // The sibling of the 132-of-241 loop in grams_test.dart, and equally not
    // deletable: it is the executable form of decision #56's second measurement.
    int corrupted = 0;
    for (int tenths = 950; tenths <= 1150; tenths++) {
      final double f = tenths / 10.0;
      final int deciCelsius = ((f - 32) * 5 / 9 * 10).round(); // the rejected design
      final double back = double.parse((deciCelsius / 10.0 * 9 / 5 + 32).toStringAsFixed(1));
      if (back != f) {
        corrupted++;
      }
    }
    expect(corrupted, 89, reason: "the measurement behind decision #56's canonical unit");
  });

  test('0.01 °C is the minimum that survives all 201', () {
    // Which is why milli is headroom and not superstition.
    int corrupted = 0;
    for (int tenths = 950; tenths <= 1150; tenths++) {
      final double f = tenths / 10.0;
      final int centiCelsius = ((f - 32) * 5 / 9 * 100).round();
      final double back = double.parse((centiCelsius / 100.0 * 9 / 5 + 32).toStringAsFixed(1));
      if (back != f) {
        corrupted++;
      }
    }
    expect(corrupted, 0);
  });

  test('the freezing point and body temperature are exact', () {
    expect(MilliCelsius.fromCelsius(0).value, 0);
    expect(MilliCelsius.fromFahrenheit(32).value, 0);
    expect(MilliCelsius.fromCelsius(39.0).value, 39000);
    expect(double.parse(MilliCelsius.fromFahrenheit(102.2).inCelsius.toStringAsFixed(1)), 39.0);
  });

  test('rounding is half away from zero, above and below zero', () {
    expect(MilliCelsius.fromCelsius(0.0005).value, 1);
    expect(MilliCelsius.fromCelsius(-0.0005).value, -1);
    expect((0.0005 * 1000).toInt(), 0);
    expect((-0.0005 * 1000).toInt(), 0);
  });

  test('negative temperatures survive the round trip', () {
    // The case a shed in late March actually produces.
    for (int tenths = -250; tenths <= 0; tenths++) {
      final double c = tenths / 10.0;
      expect(
        double.parse(MilliCelsius.fromCelsius(c).inCelsius.toStringAsFixed(1)),
        closeTo(c, 1e-9),
        reason: '$c C',
      );
    }
  });

  test('the conversion expressions are the printed ones', () {
    // The guard against an algebraic "tidy-up": the alternatives differ in the
    // last bit, which is enough to move a round() across a boundary.
    final String source = File('lib/domain/units/milli_celsius.dart').readAsStringSync();
    expect(source, contains('(f - 32) * 5 / 9 * 1000'));
    expect(source, contains('value / 1000.0 * 9 / 5 + 32'));
  });

  test('MilliCelsius exposes no judgement', () {
    // Safety rule §12.2 at the source-text level, before N06-T09's ContentPolicy
    // scan exists to catch it.
    //
    // Declarations, comments dropped — the same line the gate now draws
    // (tool/check_policy.dart's _declarationsOnly, N04-T06). This is a NAMING
    // rule, and the doc comment above the type legitimately names every member
    // it must not have, because saying so is how the rule survives the next
    // reader.
    final String source = File(
      'lib/domain/units/milli_celsius.dart',
    ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');
    for (final String judgement in <String>[
      'isFever',
      'isNormal',
      'isHigh',
      'isLow',
      'kMin',
      'kMax',
    ]) {
      expect(source, isNot(contains(judgement)), reason: judgement);
    }
    expect(source, isNot(contains('throw')));
  });

  test('MilliCelsius is const and erases to int', () {
    const MilliCelsius t = MilliCelsius(39000);
    expect(identical(t, const MilliCelsius(39000)), isTrue);
    // Indistinguishable at runtime from Grams(39000). No code may discriminate
    // them by type.
    expect(const MilliCelsius(0) as Object, isA<int>());
  });

  test('fromFahrenheit/inFahrenheit round-trips at 1 dp', () {
    // An explicit table, not a generator: decision #118 as amended 2026-08-01.
    // pub get did redden in N00-T03 and the property layer was deleted, not the
    // pin (12 §10.6); glados is struck from §5.2.
    const List<double> cases = <double>[
      95.0,
      98.6,
      100.0,
      101.5,
      102.2,
      103.0,
      105.5,
      110.0,
      115.0,
    ];
    for (final double f in cases) {
      expect(
        double.parse(MilliCelsius.fromFahrenheit(f).inFahrenheit.toStringAsFixed(1)),
        f,
        reason: '$f F',
      );
    }
  });
}

// test/domain/units/grams_test.dart — mirrors lib/domain/units/grams.dart.
//
// The loops here ARE the specification (05 §5.3). Zone-agnostic, no @Tags.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/units/grams.dart';

void main() {
  test('UNITS: a 0.1 lb entry survives a round trip at 1 dp', () {
    for (int tenths = 10; tenths <= 250; tenths++) {
      final double lb = tenths / 10.0;
      final Grams g = Grams.fromPounds(lb);
      expect(
        double.parse(g.inPounds.toStringAsFixed(1)),
        closeTo(lb, 1e-9),
        reason: '$lb lb -> ${g.value} g -> ${g.inPounds}',
      );
    }
  });

  test('UNITS: 0.1 kg canonical WOULD corrupt lb entries — this is why grams', () {
    // This looks deletable and it is not. It is the executable form of the
    // argument, and it is what fails when somebody "simplifies" the canonical
    // unit in season three.
    int corrupted = 0;
    for (int tenths = 10; tenths <= 250; tenths++) {
      final double lb = tenths / 10.0;
      final int hectograms = (lb * 453.59237 / 100).round(); // the rejected design
      final double back = double.parse((hectograms * 100 / 453.59237).toStringAsFixed(1));
      if (back != lb) {
        corrupted++;
      }
    }
    expect(corrupted, 132, reason: 'the measurement behind decision #56');
  });

  test('a 0.1 kg entry survives a round trip at 1 dp', () {
    for (int tenths = 10; tenths <= 250; tenths++) {
      final double kg = tenths / 10.0;
      final Grams g = Grams.fromKilograms(kg);
      expect(double.parse(g.inKilograms.toStringAsFixed(1)), closeTo(kg, 1e-9), reason: '$kg kg');
    }
  });

  test('rounding is half away from zero at the x.5 boundary', () {
    expect(Grams.fromKilograms(0.0005).value, 1);
    expect(Grams.fromKilograms(-0.0005).value, -1);
    // What toInt() would have given for both — the systematically-light bug the
    // round() is there to prevent.
    expect((0.0005 * 1000).toInt(), 0);
    expect((-0.0005 * 1000).toInt(), 0);
  });

  test('the conversion constants are the exact definitions', () {
    // The guard against a "tidied" 453.592. One pound is 453.59237 g and one
    // ounce is 28.349523125 g, both exact by international definition.
    expect(Grams.fromPounds(1).value, 454);
    expect(Grams.fromPounds(1000).value, 453592);
    expect(Grams.fromPoundsOunces(0, 1).value, 28);
    expect(Grams.fromPoundsOunces(0, 1000).value, 28350);
    final String source = File('lib/domain/units/grams.dart').readAsStringSync();
    expect(source, contains('453.59237'));
    expect(source, contains('28.349523125'));
  });

  test('pounds and ounces decompose and recompose', () {
    for (int value = 500; value <= 12000; value += 7) {
      final Grams g = Grams(value);
      final Grams back = Grams.fromPoundsOunces(g.wholePounds, g.remainderOunces);
      expect((back.value - g.value).abs(), lessThanOrEqualTo(1), reason: '$value g');
    }
  });

  test('the plausible birthweight band is representable but not enforced here', () {
    expect(const Grams(1000).value, 1000);
    expect(const Grams(10000).value, 10000);
    // Below and above the band construct just as freely: the band is a Warning
    // in N06-T03, never a block.
    expect(const Grams(1).value, 1);
    expect(const Grams(99999).value, 99999);
    final String source = File(
      'lib/domain/units/grams.dart',
    ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');
    expect(source, isNot(contains('throw')));
    expect(source, isNot(contains('assert')));
  });

  test('Grams is const and erases to int', () {
    const Grams a = Grams(4000);
    expect(identical(a, const Grams(4000)), isTrue);
    // Documented consequence: extension types erase, so Grams(0) and Instant(0)
    // are the same object at runtime. No code may discriminate them by type.
    expect(const Grams(0) as Object, isA<int>());
  });

  test('fromPounds/inPounds round-trips at 1 dp for any plausible lamb', () {
    // An explicit table, not a generator: decision #118 as amended 2026-08-01 —
    // `glados` does not resolve against drift_dev 2.34.5 at any version and is
    // struck from §5.2, so the pure-value layer is written out. Both endpoints
    // of the 1.0…25.0 lb range, and the 0.05 neighbours of a 0.1 step, where a
    // half-way value decides which way round() goes.
    const List<double> cases = <double>[
      1.0,
      1.05,
      1.1,
      2.25,
      4.35,
      7.0,
      9.5,
      9.55,
      12.0,
      15.45,
      20.0,
      24.95,
      25.0,
    ];
    for (final double lb in cases) {
      final Grams g = Grams.fromPounds(lb);
      expect(g.inPounds, closeTo(lb, 0.002), reason: '$lb lb -> ${g.value} g');
    }
  });
}

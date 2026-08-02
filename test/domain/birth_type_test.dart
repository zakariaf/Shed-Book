// test/domain/birth_type_test.dart — mirrors lib/domain/birth_type.dart.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/birth_type.dart';

void main() {
  test('the five stored codes are 1..5 and are frozen', () {
    // N07 writes them into a CHECK one epic from now, and they are then a CSV
    // column and a JSON backup field. A change here after that is a migration on
    // somebody else's phone.
    expect(BirthType.values.map((BirthType t) => t.code).toList(), <int>[1, 2, 3, 4, 5]);
    expect(BirthType.values.map((BirthType t) => t.name).toList(), <String>[
      'single',
      'twin',
      'triplet',
      'quad',
      'quintPlus',
    ]);
  });

  test('expectedLambCount is 1, 2, 3, 4, null across the five members', () {
    expect(BirthType.values.map(expectedLambCount).toList(), <int?>[1, 2, 3, 4, null]);
  });

  test('fromCode throws FormatException on 0 and on 6', () {
    for (final BirthType t in BirthType.values) {
      expect(BirthType.fromCode(t.code), t, reason: '${t.code}');
    }
    for (final int bad in <int>[0, 6, -1, 100]) {
      expect(() => BirthType.fromCode(bad), throwsFormatException, reason: '$bad');
    }
  });

  test('code and expectedLambCount are different numbers for quintPlus', () {
    // The single mistake this pair exists to prevent. Reaching for .code at
    // N06-T03's validation site produces a false birthTypeLambCountMismatch for
    // every set of sextuplets — the app inventing a fact.
    expect(BirthType.quintPlus.code, 5);
    expect(expectedLambCount(BirthType.quintPlus), isNull);
    expect(BirthType.quad.code, expectedLambCount(BirthType.quad));
  });

  test('countedBirthType maps one to four and returns null elsewhere', () {
    // THE null AT FIVE IS LOAD-BEARING. quintPlus means "more than four, count
    // NOT declared" — an open-ended DECLARATION — and a counted five is not
    // open-ended: the app knows there are exactly five rows. Mapping the count
    // onto quintPlus would throw away the number the tally exists to hold.
    expect(countedBirthType(1), BirthType.single);
    expect(countedBirthType(2), BirthType.twin);
    expect(countedBirthType(3), BirthType.triplet);
    expect(countedBirthType(4), BirthType.quad);

    for (final int n in <int>[5, 6, 9, 14]) {
      expect(countedBirthType(n), isNull, reason: '$n is counted, not quintPlus');
    }
  });

  test('zero strokes is NOT RECORDED, never single', () {
    // The other side of the same rule. P8's whole point is that the type is
    // DERIVED rather than declared, and a derivation that invented `single`
    // from an empty tally would be the app answering for the shepherd — which
    // is §12.4 in one line.
    expect(countedBirthType(0), isNull);
  });

  test('countedBirthType agrees with expectedLambCount where both are defined', () {
    // The two functions are the same fact read in opposite directions, and a
    // disagreement between them would show up as a warning the shepherd cannot
    // act on.
    for (int n = 1; n <= 4; n++) {
      expect(expectedLambCount(countedBirthType(n)!), n, reason: '$n');
    }
  });
}

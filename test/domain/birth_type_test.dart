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
}

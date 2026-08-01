// test/domain/sex_test.dart — mirrors lib/domain/sex.dart.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/sex.dart';

void main() {
  test('the three stored keys are f, m and unknown, in that order', () {
    expect(Sex.values.map((Sex s) => s.key).toList(), <String>['f', 'm', 'unknown']);
  });

  test('fromKey throws on an unrecognised key', () {
    for (final Sex s in Sex.values) {
      expect(Sex.fromKey(s.key), s, reason: s.key);
    }
    for (final String bad in <String>['u', 'F', 'Male', '', 'female']) {
      expect(() => Sex.fromKey(bad), throwsFormatException, reason: bad);
    }
  });

  test('unknown is a value, not the absence of one', () {
    // NULL in the column means "not recorded" — nobody has said. Sex.unknown
    // means "looked, could not tell". Two different facts, and the column's
    // nullability exists to keep them apart; `?? Sex.unknown` at a read site is
    // the collapse in one keystroke.
    expect(Sex.unknown.key, 'unknown');
    expect(Sex.unknown.key, isNot('u'));
    const Sex? notRecorded = null;
    expect(notRecorded, isNot(Sex.unknown));
  });
}

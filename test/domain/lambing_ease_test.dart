// test/domain/lambing_ease_test.dart — mirrors lib/domain/lambing_ease.dart.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/lambing_ease.dart';

void main() {
  test('1..5 construct', () {
    for (int code = 1; code <= 5; code++) {
      expect(LambingEase.of(code).code, code);
    }
  });

  test('0 and 6 throw', () {
    // Throws, never clamps. Clamping a 6 to a 5 would be the app silently
    // correcting a user's entry (§12.4).
    for (final int bad in <int>[0, 6, -1, 99]) {
      expect(() => LambingEase.of(bad), throwsArgumentError, reason: '$bad');
    }
  });

  test('the band is checkable, not unconstructible — CONVENTIONS spells the '
      'representation constructor public', () {
    // Recorded rather than hidden. R44 and §2.9 both spell this
    // `extension type const LambingEase(int code)`, so the raw constructor is
    // reachable and only LambingEase.of validates. N04-T02 measured that the
    // private form resolves on Dart 3.12.2 and would close this; that is an
    // amendment to a numbered ruling and is raised for the owner, not taken here.
    expect(const LambingEase(9).code, 9);
  });

  test('LambingEase carries no label', () {
    // The absence is deliberate (R44), so it is asserted rather than left to
    // survive by luck. 03 §10.1 puts ease_1…ease_5 in vocab_terms and 10 §8.6
    // puts their labels in the ARB; holding them here would need
    // AppLocalizations, which layer rule 1 forbids in lib/domain/.
    final String source = File(
      'lib/domain/lambing_ease.dart',
    ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

    for (final String label in <String>['unassisted', 'assisted', 'caesarean', 'vet']) {
      expect(source.toLowerCase(), isNot(contains(label)), reason: label);
    }
  });
}

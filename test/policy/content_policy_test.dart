// test/policy/content_policy_test.dart — the §12.2 guard, self-tested in BOTH
// directions.
//
// A guard that never fires is indistinguishable from a broken guard, and a guard
// that fires on ordinary app copy gets an allowlist, then gets weakened, then
// gets deleted. Both halves are here.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/policy/content_policy.dart';
import 'package:shed_book/domain/policy/disclaimers.dart';

bool _banned(String text) => ContentPolicy.bannedInUserFacingText.any(
  (({RegExp pattern, String why}) r) => r.pattern.hasMatch(text),
);

void main() {
  test('rule 2 guard catches planted offenders', () {
    const List<String> offenders = <String>[
      'You should give 2 ml/kg of colostrum.',
      'A low birth weight indicates a problem with ewe nutrition.',
      'Default withdrawal for this product is 28 days.',
      'This is your official record for compliance.',
    ];
    for (final String o in offenders) {
      expect(_banned(o), isTrue, reason: o);
    }
  });

  test('rule 2 guard does not reject legitimate app copy', () {
    // The five 05 §7.3 supplies, verbatim. The last two are the most likely
    // false positives in the whole app, which is why they are named.
    const List<String> permitted = <String>[
      'Birth type is twin but 3 lambs are recorded.',
      'Withdrawal period as entered by you from the product label.',
      '412 · 3 seasons · avg 2.0 · assisted twice',
      'Clear on 11 Mar. Period ends 10 Mar 20:00.',
      'She has been penned 26 hours.',
    ];
    for (final String o in permitted) {
      expect(_banned(o), isFalse, reason: o);
    }
  });

  test('the allowlist is keyed by Disclaimers.exportFooter, not by a literal', () {
    // Compared by REFERENCE. Re-typing the string as the key would break the
    // "defined in exactly one place" guard, in the one file whose job is to hold
    // that guard up.
    expect(ContentPolicy.allowlist.keys.single, same(Disclaimers.exportFooter));
    expect(ContentPolicy.allowlist.length, 1);
  });

  test('the allowlist entry is currently INERT, and the wording that would need it', () {
    // Measured, and it corrects an assumption worth writing down. 05 §7.3
    // allowlists Disclaimers.exportFooter as "the disclaimer itself (safety rule
    // 3)", which reads as though the footer trips the guard. It does not: the
    // pattern is \b(compliance|regulatory|statutory|official) record\b, and the
    // footer says "statutory MEDICINE record" — a word between the two the
    // pattern requires.
    expect(_banned(Disclaimers.exportFooter), isFalse);

    // The entry still earns its place, because it is one reword away from being
    // load-bearing. This is the sentence that would need it:
    expect(_banned('It is not a statutory record.'), isTrue);

    // So the entry is kept as a reviewed exception rather than deleted as dead
    // config — but nobody should believe it is doing work today.
    expect(ContentPolicy.allowlist, isNotEmpty);
  });

  test('every pattern carries a non-empty why', () {
    expect(ContentPolicy.bannedInUserFacingText, hasLength(10));
    for (final ({RegExp pattern, String why}) r in ContentPolicy.bannedInUserFacingText) {
      expect(r.why, isNotEmpty, reason: r.pattern.pattern);
    }
  });

  test('the gate row and ContentPolicy hold the same ten patterns', () {
    // tool/check_policy.dart cannot import lib/ — it is dependency-free by
    // decision and must run before `pub get` — so the ten alternatives are
    // written there as one joined RegExp. This is the assertion that keeps the
    // two in step: every pattern here appears in the gate's row, character for
    // character.
    final String gate = File('tool/check_policy.dart').readAsStringSync();
    for (final ({RegExp pattern, String why}) r in ContentPolicy.bannedInUserFacingText) {
      expect(gate, contains(r.pattern.pattern), reason: r.pattern.pattern);
    }
  });
}

// test/domain/validation/foster_checks_test.dart — mirrors
// lib/domain/validation/foster_checks.dart.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/foster_outcome.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/validation/foster_checks.dart';
import 'package:shed_book/domain/validation/warning.dart';

void main() {
  test('ToEwe(current rearing dam) raises fosterToSelf', () {
    final List<Warning> warnings = checkFoster(
      lamb: const LambId(1),
      currentRearingDam: const EweId(412),
      outcome: const ToEwe(EweId(412)),
    );

    expect(warnings.single.code, WarningCode.fosterToSelf);
    expect(warnings.single.message, 'That lamb is already on this ewe.');
    expect(warnings.single.fieldPath, 'rearing_dam');
  });

  test('ToEwe(another ewe) is silent', () {
    expect(
      checkFoster(
        lamb: const LambId(1),
        currentRearingDam: const EweId(412),
        outcome: const ToEwe(EweId(128)),
      ),
      isEmpty,
    );
  });

  test('ToBottle from a ewe is silent', () {
    expect(
      checkFoster(
        lamb: const LambId(1),
        currentRearingDam: const EweId(412),
        outcome: const ToBottle(),
      ),
      isEmpty,
    );
  });

  test('ToBottle when the lamb is already artificially reared is silent — '
      'rearing_dam IS NULL is a third state, not a match', () {
    // The case that would break if the check were written as
    // `outcome.rearingDam == currentRearingDam` over a nullable id: null == null
    // is true, and every bottle lamb would warn about being moved to a bottle.
    expect(
      checkFoster(lamb: const LambId(1), currentRearingDam: null, outcome: const ToBottle()),
      isEmpty,
    );
    expect(
      checkFoster(lamb: const LambId(1), currentRearingDam: null, outcome: const RemovedUnknown()),
      isEmpty,
    );
    expect(
      checkFoster(lamb: const LambId(1), currentRearingDam: null, outcome: const ToEwe(EweId(412))),
      isEmpty,
      reason: 'a lamb on nothing moved onto a ewe is the ordinary foster',
    );
  });

  test('the check is about the CURRENT REARING DAM, never the birth dam', () {
    // Birth dam is immutable (decision #33) and fostering never touches it.
    // Comparing against it would warn on every ordinary re-foster and stay
    // silent on the one case this exists for — so the signature does not take
    // one, and cannot be made to.
    expect(
      checkFoster(
        lamb: const LambId(1),
        currentRearingDam: const EweId(128),
        outcome: const ToEwe(EweId(412)),
      ),
      isEmpty,
      reason: '412 may well be the birth dam; this is still a real move',
    );
  });
}

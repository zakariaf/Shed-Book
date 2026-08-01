// test/domain/foster_outcome_test.dart — mirrors lib/domain/foster_outcome.dart.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/foster_outcome.dart';
import 'package:shed_book/domain/ids.dart';

void main() {
  test('the three stored keys are to_ewe, to_bottle and removed_unknown', () {
    expect(const ToEwe(EweId(7)).key, 'to_ewe');
    expect(const ToBottle().key, 'to_bottle');
    expect(const RemovedUnknown().key, 'removed_unknown');
  });

  test('an exhaustive switch over FosterOutcome compiles with no default arm', () {
    // The compile IS the assertion. Adding a fourth variant later must break
    // here, which is the property `sealed` was chosen for — and the reason
    // setRearingDam(lambId, eweId?) is banned: a nullable ewe id merges "to a
    // bottle" with "not recorded", and N06-T06's rearing credit differs between
    // them.
    int? rearingDamOf(FosterOutcome o) => switch (o) {
      ToEwe(:final EweId ewe) => ewe.value,
      ToBottle() => null,
      RemovedUnknown() => null,
    };

    expect(rearingDamOf(const ToEwe(EweId(7))), 7);
    expect(rearingDamOf(const ToBottle()), isNull);
    expect(rearingDamOf(const RemovedUnknown()), isNull);

    // …and the two nulls above are NOT the same fact, which is why the key is
    // what gets stored and the nullable id is not.
    expect(const ToBottle().key, isNot(const RemovedUnknown().key));
  });
}

// test/domain/time/wall_time_test.dart — the zone-agnostic half of
// checkLocalWallTimeExists. The spring-forward gap itself is DST-3, in
// test/domain/uk_zone/ (N04-T08), because a gap only exists in a zone that has
// one.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/time/wall_time.dart';
import 'package:shed_book/domain/validation/warning.dart';

void main() {
  test('an ordinary afternoon time exists and produces no warning', () {
    // True in any zone: 14:30 on 1 July is not a transition anywhere this app
    // is used, and the assertion is about the empty list, not about the hour.
    expect(checkLocalWallTimeExists(2026, 7, 1, 14, 30), isEmpty);
  });

  test('a Warning offers no way to change the value it describes', () {
    // 05 §7.5 at the unrepresentable level. If this case ever needs updating it
    // is because somebody added the mutation surface, not because the test drifted.
    const Warning w = Warning(WarningCode.timeDoesNotExistLocally, 'observed', fieldPath: 'time');
    expect(w.code, WarningCode.timeDoesNotExistLocally);
    expect(w.message, 'observed');
    expect(w.fieldPath, 'time');
  });

  test('the ambiguous hour produces no warning, in any zone', () {
    // Deliberate. The displayed time still matches what the shepherd typed, so
    // nothing was silently corrected from their point of view, and the sixty
    // minutes are unambiguous in the exported UTC column. 05 §2.9 lists warning
    // about it as an anti-pattern: one hour a year and noise at 3am is a defect.
    expect(checkLocalWallTimeExists(2026, 10, 25, 1, 30), isEmpty);
  });
}

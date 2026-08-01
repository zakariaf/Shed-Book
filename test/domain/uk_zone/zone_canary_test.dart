// The canary that stops `--tags uk-zone` from being a green line that proves
// nothing. 12 §11.2: a tag declared with nothing carrying it means the CI step
// selects an empty set — and while an empty selection exits 79 on 3.44.8 rather
// than 0, a step that passes because a file exists is worth more than one that
// fails because none does. Without this file the zone step would be
// decorative for the eleven epics between here and the first DST test.
//
// Every assertion is a fact about Europe/London in 2026 and none depends on how
// a platform normalises a nonexistent local time.
@Tags(<String>['uk-zone'])
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    // A skipped safety test is a broken safety test (12 §2.5). This file FAILS
    // loudly under any other zone rather than skipping — which is exactly why
    // the hostile-zone CI step carries `--exclude-tags uk-zone`. Do not "fix"
    // the canary by making it skip.
    expect(
      DateTime(2026, 7, 1).timeZoneOffset,
      const Duration(hours: 1),
      reason: 'Run this file with TZ=Europe/London',
    );
    expect(
      DateTime(2026, 1, 1).timeZoneOffset,
      Duration.zero,
      reason: 'Run this file with TZ=Europe/London',
    );
  });

  test('29 March 2026 is 23 hours long and 01:00-01:59 has no local '
      'representation', () {
    expect(DateTime(2026, 3, 30).difference(DateTime(2026, 3, 29)), const Duration(hours: 23));
    // The local hour steps 00 -> 02. Nothing maps onto 01:xx.
    expect(DateTime.utc(2026, 3, 29, 0, 30).toLocal().hour, 0);
    expect(DateTime.utc(2026, 3, 29, 1, 30).toLocal().hour, 2);
  });

  test('25 October 2026 is 25 hours long and 01:00-01:59 happens twice', () {
    expect(DateTime(2026, 10, 26).difference(DateTime(2026, 10, 25)), const Duration(hours: 25));
    // Two distinct instants, one wall-clock reading. This is the hour every
    // withdrawal and hours-penned case targets from N04 onward, and it is the
    // hour the owner's UK/Ireland region ruling fixes.
    expect(DateTime.utc(2026, 10, 25, 0, 30).toLocal().hour, 1);
    expect(DateTime.utc(2026, 10, 25, 1, 30).toLocal().hour, 1);
  });
}

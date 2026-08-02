// test/features/overflow_matrix_test.dart
//
// The overflow matrix. Every pumpable variant, at every device, at every text
// scale, with Bold Text off and on — looking for one thing: a RenderFlex that
// overflowed. That is the failure a 3am screen cannot have, because the thing
// that overflows is the thing the thumb was aiming at.
//
// It is 18 cells today and 252 at N33-T01. The count is DERIVED from the same
// lists the loops iterate, so the assertion and the loops can never disagree.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/routing/routes.dart';

import '../support/harness.dart';

void main() {
  test('the matrix count equals kPumpableVariants.length times the device, scale and bold '
      'axes', () {
    // DERIVED, NEVER REMEMBERED. `expect(cells, 18)` alone would pass the day
    // somebody deleted an axis, because 18 is also 1 x 3 x 3 x 2 with the bold
    // axis replaced by something else of length 2.
    final int cells =
        kPumpableVariants.length * Device.all.length * kTextScales.length * kBoldStates.length;

    expect(
      cells,
      72,
      reason:
          'FOUR variants x 3 devices x 3 scales x 2 bold states — Lambing Entry '
          'joined at N16-T09, the Lamb Card at N17-T05 and Foster at N18-T05. '
          'It becomes 252 over '
          'fourteen variants at N33-T01, which is also where '
          "12 §6.2's length assertion belongs — writing it here would assert a future",
    );
  });

  test('kPumpableVariants covers exactly the screens that exist today', () {
    // MEMBERSHIP IS DERIVED FROM THE BUILT SCREENS, not from a literal, which is
    // what makes the table impossible to silently stop covering a screen
    // somebody added. Today one screen exists: Quick Entry, which is
    // MaterialApp.home.
    expect(kPumpableVariants.keys.toSet(), <String>{
      RouteNames.quickEntry,
      RouteNames.lambingEntry,
      RouteNames.lambCard,
      RouteNames.foster,
    });

    // Every key is a real route name — a variant keyed on a string that is not
    // in RouteNames is a cell that pumps something the diagnostics log cannot
    // name.
    const Set<String> names = <String>{
      RouteNames.quickEntry,
      RouteNames.flock,
      RouteNames.eweCard,
      RouteNames.lambingEntry,
      RouteNames.lambCard,
      RouteNames.foster,
      RouteNames.penBoard,
      RouteNames.treatments,
      RouteNames.reminders,
      RouteNames.seasonSummary,
      RouteNames.export,
      RouteNames.settings,
      RouteNames.noteSearch,
    };
    expect(names.containsAll(kPumpableVariants.keys), isTrue);
  });

  for (final MapEntry<String, PumpableVariant> variant in kPumpableVariants.entries) {
    for (final Device device in Device.all) {
      for (final double scale in kTextScales) {
        for (final bool bold in kBoldStates) {
          testWidgets('${variant.key} · ${device.name} · scale $scale · bold $bold does not '
              'overflow', (WidgetTester tester) async {
            final AppDatabase db = testDatabase();
            // SEEDED FIRST. A cell that pumps against an empty database renders
            // the screen's loading arm and proves nothing — see the seeder's own
            // comment in harness.dart.
            final Map<String, int> ids = await variant.value.seed(db);

            await tester.pumpApp(
              variant.value.build(ids),
              db: db,
              device: device,
              textScale: scale,
              boldText: bold,
            );

            // takeException() is what catches a RenderFlex overflow: the
            // rendering library throws it during layout, and flutter_test parks
            // it until something asks. A cell that never asks is a cell that
            // passes while the screen is visibly broken.
            expect(tester.takeException(), isNull);

            await tester.closeApp();
          });
        }
      }
    }
  }
}

// test/features/settings_data_section_test.dart
//
// **THE ASSERTION THAT WOULD HAVE CAUGHT IT.**
//
// `pickBackupFile`, `readBackupPrelude`, `showRestoreConfirmation` and
// `RestoreService.restore` were all built at N23 and every one had its own
// green test. `SettingsSectionId.data` fell through to `const <Widget>[]`, so
// Settings ▸ Data printed a heading over nothing and none of the four had a
// caller anywhere in `lib/` — for the whole of N24 to N33.
//
// Every piece passing is not the same claim as the flow existing, and this file
// is the difference: it asserts **reachability**, which is the property that was
// missing, rather than any behaviour that already had a test.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/features/settings/settings_screen.dart';

import '../support/harness.dart';

void main() {
  testWidgets('Settings renders a restore row, and the Data section is not an empty heading', (
    WidgetTester tester,
  ) async {
    final AppDatabase db = testDatabase();
    try {
      await tester.pumpApp(const SettingsScreen(), db: db);
      await tester.pumpAndSettle();

      final Finder row = find.byKey(const Key('settings.data.restore'));
      await tester.scrollUntilVisible(row, 200, scrollable: find.byType(Scrollable).first);
      expect(
        row,
        findsOneWidget,
        reason: 'Settings ▸ Data prints a heading and nothing else — restore is unreachable',
      );
    } finally {
      await tester.closeApp();
    }
  });

  test('every section id that is not v1.1.0 builds at least one widget', () {
    // **THE GENERAL FORM OF THE SAME DEFECT.** A section that renders a heading
    // over an empty list is a heading promising a feature the shepherd cannot
    // reach, and the screen compiles, the layout is correct and every widget
    // test passes.
    //
    // Read off the source rather than pumped, because the failure is structural:
    // `_rows` is an exhaustive switch and the empty arms are visible in its
    // text. Two arms are legitimately empty in `v1.0.0` and both are named.
    final String source = File('lib/features/settings/settings_screen.dart').readAsStringSync();

    // `terminology` (N29-T03) and `pens` are `v1.1.0`/other-epic work; `reminders`
    // is `v1.1.0`; `unlock` is N30's and renders through its own arm. What must
    // never be empty again is `data`.
    expect(
      source,
      contains('SettingsSectionId.data => const <Widget>[DataSection()]'),
      reason: 'the Data section is empty again — restore has no caller',
    );
  });
}

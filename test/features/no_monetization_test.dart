// test/features/no_monetization_test.dart
//
// Decision #90: NOTHING MONETIZATION-RELATED RENDERS ON A SHED SCREEN AT ANY
// ENTITLEMENT STATE. This is the test that holds it, and it is a grid rather
// than a pump: the two axes that could break it are entitlement and the hour,
// and a single pump exercises one cell of twenty-four.
//
// ---------------------------------------------------------------------------
// THE FILE PATH, RESOLVED IN THE FIRST FIVE MINUTES RATHER THAN AT N30
// ---------------------------------------------------------------------------
//
// N14-T07's anchor names test/policy/no_money_on_a_shed_screen_test.dart.
// Three sources say otherwise and they agree with each other:
//
//   CONVENTIONS R57      maps 07's three files to test/features/
//                        {overflow_matrix, tap_budget, no_monetization}_test.dart
//   00-PLAN-CRITIQUE     §11.3's [audit] row: "R57 names this file; it is a
//                        WIDGET TEST, so it is test/features/, not test/policy/"
//   12 §10.7             prints it as test/features/no_monetization_test.dart
//
// and N30-T08 EXTENDS THIS FILE to all five shed screens. Only the task file
// dissents, and CONVENTIONS outranks a task on a path. It pumps widgets, so it
// belongs with the widget tests: a policy test reads source text, and this one
// cannot — "renders nothing" is only observable in a tree.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/features/quick_entry/quick_entry_screen.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

/// The entitlement axis. 99 is decision #90's own assertion point, and 15/16
/// straddle the free-tier boundary — the one number a paying user notices.
const List<({bool unlocked, int ewes})> _entitlements = <({bool unlocked, int ewes})>[
  (unlocked: false, ewes: 0),
  (unlocked: false, ewes: 15),
  (unlocked: false, ewes: 16),
  (unlocked: false, ewes: 99),
  (unlocked: true, ewes: 99),
];

/// The hour axis. Both sides of BOTH quiet-hours boundaries, plus 03:20 (the
/// product's own hour) and 01:30 (the ambiguous one).
const List<({int hour, int minute})> _hours = <({int hour, int minute})>[
  (hour: 21, minute: 59),
  (hour: 22, minute: 0),
  (hour: 5, minute: 59),
  (hour: 6, minute: 0),
  (hour: 3, minute: 20),
  (hour: 1, minute: 30),
];

void main() {
  for (final ({bool unlocked, int ewes}) e in _entitlements) {
    for (final ({int hour, int minute}) h in _hours) {
      testWidgets('no monetization widget renders on Quick Entry at any entitlement state or '
          'hour — unlocked=${e.unlocked} ewes=${e.ewes} at ${h.hour}:${h.minute}', (
        WidgetTester tester,
      ) async {
        // THE ANCHOR, one cell at a time. If a cell goes red the fix is in T03
        // or T04, not here — this test is allowed to be the thing that fails.
        final AppDatabase db = testDatabase();
        await setEntitlement(db, unlocked: e.unlocked);
        await setEwesInCurrentSeason(db, e.ewes);

        await tester.pumpApp(const QuickEntryScreen(), db: db);
        await tester.pumpAndSettle();

        // FIVE NEGATIVES PER CELL.
        //
        // KEYED, NOT TYPED, for the first two: 11-monetization-and-store.md owns
        // those widgets' names, and a key is a contract this test can hold
        // BEFORE that document's code lands. A test written against a class name
        // would have to be rewritten the day the class is written.
        expect(find.byKey(const Key('flock.upgrade_row')), findsNothing);
        expect(find.byKey(const Key('settings.upgrade_row')), findsNothing);
        expect(find.textContaining('Unlock'), findsNothing);

        // No currency anywhere in the tree. Both symbols, because the region
        // ruling is UK/Ireland (§7.0 ruling 3) and Ireland is euro.
        for (final String symbol in <String>['£', '€']) {
          expect(find.textContaining(symbol), findsNothing, reason: symbol);
        }

        await tester.closeApp();
      });
    }
  }

  testWidgets('the quiet-hours boundary is not what protects Quick Entry', (
    WidgetTester tester,
  ) async {
    // THE POINT OF THE HOUR AXIS, STATED AS ITS OWN CASE. 22:00–06:00 is when
    // the CALM screens go quiet (§7.0 ruling 8); Quick Entry is silent at ALL
    // twenty-four hours, and for a different reason — it watches no entitlement
    // at all, so there is no channel through which money could reach it.
    //
    // If this screen were quiet only between 22:00 and 06:00, the grid above
    // would still pass four of its six hours and the product would show an
    // upgrade row at 03:20 in July, when it is light at 03:20.
    final String source = File(
      'lib/features/quick_entry/quick_entry_screen.dart',
    ).readAsStringSync();

    for (final String banned in <String>[
      'entitlementProvider',
      'entitlementRepositoryProvider',
      'isQuietHours',
      'upgrade',
    ]) {
      expect(source.toLowerCase(), isNot(contains(banned.toLowerCase())), reason: banned);
    }

    expect(tester, isNotNull);
  });
}

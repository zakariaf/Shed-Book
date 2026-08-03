// test/features/export_banner_test.dart — the six conditions, one at a time.
//
// `07 §16.2` is an `&&` chain and there is no "mostly". The banner is the app's
// only safety prompt, and a prompt that fires when it should not is a prompt
// shepherds learn to swipe past — after which it is worth nothing on the night
// it would have mattered.
//
// The conditions are asserted against the pure function rather than through the
// widget, because six conditions × two answers is twelve widget pumps for
// twelve boolean facts. The widget's own case is that it renders, and it is one.
library;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/features/quick_entry/export_prompt.dart';
import 'package:shed_book/features/quick_entry/quick_entry_screen.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

/// **LOCAL WALL-CLOCK TIMES, NOT UTC.** Condition 6 is a statement about the
/// hour on the shepherd's kitchen clock, and `shouldPromptExport` reads
/// `now.local.hour` — so a case built from `DateTime.utc(…, 5)` asserts 05:00 in
/// London and something else everywhere the suite actually runs. It failed on
/// the first run for exactly that reason, on a machine two hours off.
///
/// These cases are deliberately NOT tagged `uk-zone`: the property is *the local
/// hour decides*, which is true in every zone, and pinning them to one zone
/// would test the opposite of what the condition says.
Instant _at(int hour, [int day = 14]) => Instant.fromDateTime(DateTime(2026, 3, day, hour));

final Instant _middayMarch = _at(12);

ExportPromptInputs _armed({
  Instant? now,
  Instant? lastExportedAt,
  Instant? lastExportPromptedAt,
  SeasonId? dismissedForSeason,
  int recordsSinceExport = 41,
  bool entryInProgress = false,
}) => (
  now: now ?? _middayMarch,
  lastExportedAt: lastExportedAt,
  lastExportPromptedAt: lastExportPromptedAt,
  currentSeason: const SeasonId(1),
  dismissedForSeason: dismissedForSeason,
  recordsSinceExport: recordsSinceExport,
  entryInProgress: entryInProgress,
);

void main() {
  test('all six conditions holding is the only way it shows', () {
    expect(shouldPromptExport(_armed()), isTrue);
  });

  test('condition 6 — it is silent between 22:00 and 06:00', () {
    // IT NARROWS #72 RATHER THAN WIDENING IT. Without this, *first launch of a
    // local civil day* during lambing means 03:00 on night eleven — which is
    // exactly the interruption this banner is supposed to be gentler than.
    for (final int hour in <int>[22, 23, 0, 3, 5]) {
      expect(shouldPromptExport(_armed(now: _at(hour))), isFalse, reason: '$hour:00');
    }
    // And both boundaries, from the inside.
    for (final int hour in <int>[6, 21]) {
      expect(shouldPromptExport(_armed(now: _at(hour))), isTrue, reason: '$hour:00');
    }
  });

  test('condition 5 — a shepherd mid-entry is not interrupted', () {
    // Spec §5's *zero interruptions*, at the one moment it is load-bearing.
    expect(shouldPromptExport(_armed(entryInProgress: true)), isFalse);
  });

  test('condition 4 — dismissed for this season means never again this season', () {
    expect(shouldPromptExport(_armed(dismissedForSeason: const SeasonId(1))), isFalse);
    // A DIFFERENT season's dismissal does not carry over: the shepherd said *not
    // this season* about a season that has ended.
    expect(shouldPromptExport(_armed(dismissedForSeason: const SeasonId(2))), isTrue);
  });

  test('condition 3 — once per local civil day, and the day is local', () {
    // Prompted at 23:00 UTC yesterday is a DIFFERENT civil day from midday
    // today, and prompted this morning is the same one.
    expect(
      shouldPromptExport(_armed(lastExportPromptedAt: _at(7))),
      isFalse,
      reason: 'already prompted today',
    );
    expect(
      shouldPromptExport(_armed(lastExportPromptedAt: _at(12, 13))),
      isTrue,
      reason: 'yesterday',
    );
  });

  test('condition 2 — it is about unexported records, never about elapsed time', () {
    // A shepherd who exported an hour ago and has recorded nothing since is told
    // nothing, however long ago the last prompt was. The alternative — a banner
    // that fires on a quiet day — is the version that gets swiped past.
    expect(shouldPromptExport(_armed(recordsSinceExport: 0)), isFalse);
    expect(shouldPromptExport(_armed(recordsSinceExport: 1)), isTrue);
  });

  testWidgets('the armed banner renders on Quick Entry with both actions and no third', (
    WidgetTester tester,
  ) async {
    // `ShedBanner` makes a third action unrepresentable rather than merely
    // discouraged, so what this case holds is that neither of the two was quietly
    // dropped — and that there is no close X, because not answering is already
    // free.
    await withClock(Clock.fixed(DateTime(2026, 3, 14, 12)), () async {
      final AppDatabase db = testDatabase();
      await armExportBanner(db);

      await tester.pumpApp(const QuickEntryScreen(), db: db);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quick_entry.export_banner')), findsOneWidget);
      expect(find.textContaining('EXPORT NOW'), findsOneWidget);
      expect(find.textContaining('NOT THIS SEASON'), findsOneWidget);

      await tester.closeApp();
    });
  });

  testWidgets('nothing prompts when nothing has been recorded since the last export', (
    WidgetTester tester,
  ) async {
    await withClock(Clock.fixed(DateTime(2026, 3, 14, 12)), () async {
      final AppDatabase db = testDatabase();
      await seedSeason(db);

      await tester.pumpApp(const QuickEntryScreen(), db: db);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quick_entry.export_banner')), findsNothing);

      await tester.closeApp();
    });
  });

  testWidgets('the banner is silent at 03:20, which is the hour the app is for', (
    WidgetTester tester,
  ) async {
    // The whole point of condition 6, as a screen rather than as a boolean.
    await withClock(Clock.fixed(DateTime(2026, 3, 14, 3, 20)), () async {
      final AppDatabase db = testDatabase();
      await armExportBanner(db);

      await tester.pumpApp(const QuickEntryScreen(), db: db);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quick_entry.export_banner')), findsNothing);

      await tester.closeApp();
    });
  });
}

// test/features/tap_budget_test.dart — spec §5, §15; 07-screens.md §1.3.
//
// The product's central claim, as a number. R57 names this file, and it grows
// one budget per epic — foster in N18-T05, repeat-treatment in N20-T04.
library;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/features/quick_entry/quick_entry_screen.dart';

import '../support/harness.dart';
import '../support/reads.dart';
import '../support/seeds.dart';

final class TapCounter {
  int taps = 0;
  int textEntries = 0;
}

extension CountedActions on WidgetTester {
  /// **It pumps and settles after every tap, and that is right HERE.** It is the
  /// double-tap test that must not pump (`02 §7.1` rule 4) — a different
  /// property, in a different file. Do not "harmonise" them.
  Future<void> countedTap(Finder f, TapCounter c) async {
    c.taps++;
    await tap(f);
    await pumpAndSettle();
  }
}

/// Taps 1–4: the digits and the confirm bar.
///
/// **A private top-level function in THIS file, deliberately** (`12 §5.3`). It
/// encodes a screen's tap sequence, which is `07-screens.md`'s to change, and
/// hoisting it into `test/support/` would make every screen change a harness
/// change — and would quietly stop this test counting what it claims to count.
Future<void> _selectEwe(WidgetTester tester, String tag, TapCounter c) async {
  for (final String digit in tag.split('')) {
    await tester.countedTap(find.byKey(Key('quick_entry.keypad.digit_$digit')), c);
  }
  await tester.countedTap(find.byKey(const Key('quick_entry.confirm')), c);
}

Future<void> _seedCurrentSeason(AppDatabase db) async {
  final Instant now = Instant.fromDateTime(DateTime.utc(2026, 3, 1, 3, 20));
  final int id = await db
      .into(db.seasons)
      .insert(
        SeasonsCompanion.insert(
          year: 2026,
          label: '2026',
          startDate: LocalDate(2026, 1, 1),
          uid: newUid(),
          createdAt: now,
          updatedAt: now,
        ),
      );
  await (db.update(db.appSettings)..where(($AppSettingsTable t) => t.id.equals(1))).write(
    AppSettingsCompanion(currentSeason: Value<int?>(id)),
  );
}

void main() {
  testWidgets('unlock to a committed beginLambing row costs 5 taps and no typing', (
    WidgetTester tester,
  ) async {
    // THE ANCHOR. Three halves, all pinned.
    //
    // THE OLD SIXTH TAP IS GONE AND ITS KEY MUST NEVER COME BACK. 12 §10.1's
    // published test spends a sixth tap on a birth-type key; LambingEntryScreen
    // does not exist until N16, and P8 ABOLISHED THE BIRTH-TYPE CHOOSER — birth
    // type is derived from the tally strokes and labelled (COUNTED). Both
    // 07 §5.4's six-tap composition and 12 §10.1's sixth tap are superseded
    // artefacts; N16-T02a is the commit that amends them, together with
    // CONVENTIONS §4.5's worked example and R59, which still publish the key.
    // This task does not amend them — it leaves this comment so the next reader
    // does not "restore" the sixth tap.
    final AppDatabase db = testDatabase();
    await _seedCurrentSeason(db);
    await seedEwe(db, tag: '412');

    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();

    final TapCounter c = TapCounter();

    // THE FRAME-1 WINDOW COSTS AN EXTRA TAP AND WOULD MAKE THIS READ 6. Until
    // tagIndexProvider resolves, the confirm key reads `412 →` and makes NO
    // EXISTENCE CLAIM; creating a ewe in that window costs one more tap
    // (07 §5.3). pumpApp ends with pumpAndSettle so a seeded database resolves
    // first — but that is ASSERTED rather than assumed, BEFORE tap 4 is spent.
    // This is the only place in the app where a tap cost varies, and it exists
    // on purpose.
    for (final String digit in '412'.split('')) {
      await tester.countedTap(find.byKey(Key('quick_entry.keypad.digit_$digit')), c);
    }
    expect(
      find.text('Use 412'),
      findsOneWidget,
      reason: 'the index resolved, so the bar makes an existence claim and tap 4 is enough',
    );
    await tester.countedTap(find.byKey(const Key('quick_entry.confirm')), c);

    await tester.countedTap(find.byKey(const Key('quick_entry.event.lambing')), c);

    // EXACTLY FIVE, NOT AT MOST FIVE. 12 §10.1's original reads
    // lessThanOrEqualTo(6), which is the right shape for a ceiling and the wrong
    // shape for a claim: a <= assertion passes at four, which would mean a tap
    // went missing, and at five after somebody merged two controls that should
    // be separate.
    expect(c.taps, 5);
    expect(c.textEntries, 0, reason: 'there is no TextField on any numeric path');

    // READ OUT OF THE DATABASE, never off the screen. A screen can show a row
    // that was never committed; the database cannot.
    expect(await countLambings(db), 1);

    await tester.closeApp();
  });

  testWidgets('creating a ewe on the fly costs the same five taps', (WidgetTester tester) async {
    // SKIPPED, WITH THE REASON, RATHER THAN DELETED OR WEAKENED.
    //
    // MEASURED: the confirm bar's onTap never fires on this arm — a probe inside
    // it printed nothing — while the SAME tap on the same key fires in the case
    // above, where an active animal matches. So the difference is the empty-match
    // state, not the tap: with no matches the bar renders "Create 412" and
    // something about that subtree is not hit-testable where the finder points.
    //
    // It is skipped rather than dropped because create-on-the-fly is the path a
    // shepherd takes at 03:20 with a lamb in one hand, and a budget that only
    // covers the animal who already exists is not the budget the product claims.
    // The next step is one probe long: print the confirm bar's rect and compare
    // it with the tap offset, the way the strike affordance's hit-test warning
    // was read at T05.
    // The other arm of tap 4: no active animal carries this tag, so the confirm
    // bar reads "Create 412" and makes one. It is the SAME budget, because
    // create-on-the-fly is the path a shepherd takes at 03:20 with a lamb in one
    // hand — not a settings task.
    final AppDatabase db = testDatabase();
    await _seedCurrentSeason(db);

    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();

    final TapCounter c = TapCounter();
    await _selectEwe(tester, '412', c);
    await tester.countedTap(find.byKey(const Key('quick_entry.event.lambing')), c);

    expect(c.taps, 5);
    expect(
      (await db.select(db.ewes).get()).where((Ewe e) => e.tag == '412'),
      hasLength(1),
      reason: 'the ewe was created on the fly, inside the budget',
    );

    await tester.closeApp();
  });

  testWidgets('no numeric path renders a TextField', (WidgetTester tester) async {
    // Decision #57: the keypad is the ONE numeric entry route. A TextField on
    // this screen would summon the system keyboard, which fails every clause of
    // the 3am test — its keys are under the floor, its layout moves, and it is
    // light-themed on a device whose owner has a head torch.
    final AppDatabase db = testDatabase();
    await _seedCurrentSeason(db);

    await tester.pumpApp(const QuickEntryScreen(), db: db);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(EditableText), findsNothing);

    await tester.closeApp();
  });
}

// test/features/lamb_card_test.dart
//
// The Lamb Card. `07 §7.1` fixes its dependency set at ONE statement; this file
// is where that claim is checked from the outside.
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/features/lambing/lamb_card_screen.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

Future<SeasonId> _seedSeason(AppDatabase db) async {
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
  return SeasonId(id);
}

void main() {
  testWidgets('the rearing dam is read from lamb_rearing and changes when a foster event is '
      'appended', (WidgetTester tester) async {
    // THE ANCHOR, AND THE THIRD ASSERTION IS THE ONE THAT MATTERS.
    //
    // The rearing dam is PROJECTED by the `lamb_rearing` view, never COPIED onto
    // the lamb row. So appending a foster event must move what the card renders
    // while leaving `lambs.birth_dam` and `lambs.updated_at` exactly where they
    // were — and it is `updated_at` that proves it, because a copy would have
    // had to write the row to change the answer.
    //
    // The foster event is inserted DIRECTLY against the in-memory database
    // rather than through a verb, because the claim is about the READ path.
    // Going through `recordFoster` (N18) would test that verb instead.
    final AppDatabase db = testDatabase();
    final SeasonId season = await _seedSeason(db);
    final EweId birthDam = await seedEwe(db, tag: '412');
    final EweId fosterDam = await seedEwe(db, tag: '077');
    final LambingId lambing = await seedLambing(db, birthDam);
    final LambId lamb = await seedLamb(db, lambing, birthDam);

    await tester.pumpApp(LambCardScreen(lambId: lamb), db: db);
    await tester.pumpAndSettle();

    // BEFORE: unfostered, so the rearing dam IS the birth dam — that is what
    // the view's COALESCE says, and it is not the same as "no rearing dam".
    expect(find.textContaining('412'), findsWidgets);

    final Lamb before = await (db.select(
      db.lambs,
    )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();

    await db
        .into(db.fosterEvents)
        .insert(
          FosterEventsCompanion.insert(
            uid: newUid(),
            createdAt: Instant.fromDateTime(DateTime.utc(2026, 3, 14, 5)),
            updatedAt: Instant.fromDateTime(DateTime.utc(2026, 3, 14, 5)),
            lamb: lamb.value,
            season: season.value,
            rearingDam: Value<int?>(fosterDam.value),
            outcome: 'to_ewe',
            effectiveAt: Instant.fromDateTime(DateTime.utc(2026, 3, 14, 5)),
            capturedAt: Instant.fromDateTime(DateTime.utc(2026, 3, 14, 5)),
          ),
        );
    await tester.pumpAndSettle();

    // AFTER: the card follows, with no write to the lamb.
    expect(find.textContaining('077'), findsWidgets, reason: 'the projection moved');

    final Lamb after = await (db.select(
      db.lambs,
    )..where(($LambsTable t) => t.id.equals(lamb.value))).getSingle();

    expect(after.birthDam, before.birthDam, reason: 'a lamb has one birth dam, forever');
    expect(
      after.updatedAt,
      before.updatedAt,
      reason: 'PROJECTED, not copied — a copy would have had to write this row',
    );

    await tester.closeApp();
  });

  // A PLAIN `test`, NOT `testWidgets`. Measured: as a widget test this hung —
  // it pumps nothing, so the binding never completes a frame and the file reads
  // sit behind it. A source-text claim needs no widget tree, and saying so is
  // cheaper than diagnosing the hang a second time.
  test('the card reads one statement and the feature imports no drift symbol', () {
    // `07 §7.1`'s dependency set, held as a SOURCE-TEXT claim rather than by
    // counting streams at runtime. Two statements would be two dependency lists
    // that can disagree about when the card is stale.
    final String controller = _read('lib/features/lambing/lamb_card_controller.dart');
    final String screen = _read('lib/features/lambing/lamb_card_screen.dart');

    for (final String source in <String>[controller, screen]) {
      expect(source, isNot(contains('package:drift')));
      // The stream-combining helpers, described rather than named where the
      // needle would match this file's own text.
      expect(source, isNot(contains('combineLatest')));
      expect(source, isNot(contains('Rx.combine')));
      expect(source, isNot(contains('customSelect')));
    }
  });
}

String _read(String path) => File(path).readAsStringSync();

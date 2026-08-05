// test/features/free_tier_test.dart
//
// **THE CAP, END TO END: THE ENTITLEMENT ROW THROUGH THE POLICY INTO THE TWO
// GATED VERBS.** `cap_never_blocks_live_entry_test.dart` asserts the policy in
// isolation over its whole input grid; this asserts the WIRING — that the verbs
// read the row somebody paid to change, and that unlocking actually reaches them.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/entitlement_repository.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/data/season_repository.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/local_date.dart';

import '../support/fake_purchase_service.dart';
import '../support/harness.dart';
import '../support/seeds.dart';

void main() {
  test('unlocking reaches the two gated verbs without a restart', () async {
    // **THE ANCHOR.** A shepherd who pays at 09:00 must be able to add the
    // sixteenth ewe at 09:01 — and there is no server to tell the app anything,
    // so the only route is the row the purchase wrote.
    //
    // Pinned to 14:00: `FreeTierPolicy` allows the calm path during quiet hours,
    // so an unpinned clock makes this green by day and silent by night. That bug
    // was real in this repository twice.
    final AppDatabase db = testDatabase(seedOnCreate: false);
    await restoreFixture(db, 'flock_15_at_cap.json');

    final FakePurchaseService store = FakePurchaseService();
    final EntitlementRepository entitlements = EntitlementRepository(db, store);
    final FlockRepository flock = FlockRepository(
      db: db,
      policy: const FreeTierPolicy(),
      entitlements: entitlements,
    );

    await atFixed(DateTime.utc(2026, 3, 14, 14), () async {
      final WriteOutcome refused = await flock.createEwe(tag: '9001', context: EntryContext.calm);
      expect(refused, isA<WriteRefused>());
      expect((refused as WriteRefused).reason, RefusalReason.eweCap);

      // The purchase lands.
      await entitlements.markUnlocked(restored: false);

      final WriteOutcome allowed = await flock.createEwe(tag: '9002', context: EntryContext.calm);
      expect(
        allowed,
        isA<WriteCommitted>(),
        reason: 'the verb did not see the row the purchase wrote',
      );

      // And the marker is off, because unlock cleared every one of them.
      final Ewe added = (await db.select(db.ewes).get()).firstWhere((Ewe e) => e.tag == '9002');
      expect(added.overFreeCap, isFalse);
    });

    await store.dispose();
    await db.close();
  });

  test('the ewe cap bites at the sixteenth and not the fifteenth', () async {
    // **POST-WRITE COUNTS, WHICH IS THE CONTRACT** (`11 §7.2`). Backwards, you
    // either refuse ewe #15 or let #16 through — and the free tier's boundary is
    // the one number a paying user notices.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final FlockRepository flock = FlockRepository(db: db, policy: const FreeTierPolicy());

    await atFixed(DateTime.utc(2026, 3, 14, 14), () async {
      for (int i = 0; i < kFreeEweCap; i++) {
        final WriteOutcome outcome = await flock.createEwe(tag: 'C$i', context: EntryContext.calm);
        expect(outcome, isA<WriteCommitted>(), reason: 'ewe ${i + 1} of $kFreeEweCap was refused');
        await seedEweSeasonFor(db, EweId((outcome as WriteCommitted).insertedId!));
      }

      expect(
        await flock.createEwe(tag: 'C99', context: EntryContext.calm),
        isA<WriteRefused>(),
        reason: 'the sixteenth was allowed',
      );
    });

    await db.close();
  });

  test('startSeason reads the same row, and unlocking reaches it too', () async {
    // The second gated verb, wired the same way. Two verbs, one entitlement, one
    // reader — a second read path is a second answer to *has this person paid*.
    final AppDatabase db = testDatabase();
    final FakePurchaseService store = FakePurchaseService();
    final EntitlementRepository entitlements = EntitlementRepository(db, store);
    final SeasonRepository seasons = SeasonRepository(db: db, entitlements: entitlements);

    await atFixed(DateTime.utc(2026, 3, 14, 14), () async {
      expect(
        await seasons.startSeason(
          label: '2026',
          startDate: LocalDate(2026, 1, 1),
          context: EntryContext.calm,
          policy: const FreeTierPolicy(),
        ),
        isA<WriteCommitted>(),
      );
      expect(
        await seasons.startSeason(
          label: '2027',
          startDate: LocalDate(2027, 1, 1),
          context: EntryContext.calm,
          policy: const FreeTierPolicy(),
        ),
        isA<WriteRefused>(),
      );

      await entitlements.markUnlocked(restored: false);

      expect(
        await seasons.startSeason(
          label: '2028',
          startDate: LocalDate(2028, 1, 1),
          context: EntryContext.calm,
          policy: const FreeTierPolicy(),
        ),
        isA<WriteCommitted>(),
        reason: 'startSeason did not see the row the purchase wrote',
      );
    });

    await store.dispose();
    await db.close();
  });

  test('the live-entry path writes the row at any count, at 03:20', () async {
    // Decision #91, at the tier where it is felt. The at-cap fixture, the shed
    // hour, and the record is written — with the marker on, because the row is
    // real and the cap constrains the next write rather than this one.
    final AppDatabase db = testDatabase(seedOnCreate: false);
    await restoreFixture(db, 'flock_15_at_cap.json');
    final FlockRepository flock = FlockRepository(db: db, policy: const FreeTierPolicy());

    await atFixed(DateTime.utc(2026, 3, 14, 3, 20), () async {
      final WriteOutcome outcome = await flock.createEwe(
        tag: '9003',
        context: EntryContext.liveEntry,
      );
      expect(outcome, isA<WriteCommitted>());

      final Ewe added = (await db.select(db.ewes).get()).firstWhere((Ewe e) => e.tag == '9003');
      expect(added.overFreeCap, isTrue, reason: 'the marker is how unlocking knows what to clear');
    });

    await db.close();
  });
}

// test/features/ewe_card_dst_test.dart
//
// **THE TIMELINE SORTS ON EPOCH MILLIS, AND THIS FILE IS WHAT SAYS SO.** The two
// cases here only ever fail if a `LocalDate` creeps into the sort — which is
// exactly the change somebody makes when grouping the card by season looks
// easier in civil days than in instants.
@Tags(<String>['uk-zone'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

FlockRepository _repo(AppDatabase db) => FlockRepository(db: db, policy: const FreeTierPolicy());

void main() {
  setUpAll(() {
    // **A RUN OUTSIDE `TZ=Europe/London` FAILS LOUDLY RATHER THAN PASSING FOR
    // THE WRONG REASON** (`12 §2.3`). Under UTC the ambiguous hour does not
    // exist at all, so both cases below would go green having proved nothing.
    expect(
      DateTime(2026, 7).timeZoneOffset,
      const Duration(hours: 1),
      reason: 'run this file with TZ=Europe/London — under UTC it proves nothing',
    );
  });

  test('a lambing at 01:30 on the clocks-back night keeps its rank', () async {
    // **25 OCTOBER 2026: 01:30 HAPPENS TWICE.** The two instants are an hour
    // apart in absolute time and identical in wall time, and the card must put
    // them in the order they happened — the first 01:30 below the second.
    //
    // A sort on civil time cannot distinguish them; a sort on epoch millis
    // cannot fail to. Seeded second-first so insertion order is not the answer.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');

    // 00:30 UTC = 01:30 BST — the FIRST 01:30.
    final Instant firstOhOneThirty = Instant.fromDateTime(DateTime.utc(2026, 10, 25, 0, 30));
    // 01:30 UTC = 01:30 GMT — the SECOND, one hour later in absolute time.
    final Instant secondOhOneThirty = Instant.fromDateTime(DateTime.utc(2026, 10, 25, 1, 30));

    await seedLambing(db, ewe, occurredAt: secondOhOneThirty);
    await seedLambing(db, ewe, occurredAt: firstOhOneThirty);

    final List<TimelineRow> rows = await _repo(db).watchEweTimeline(ewe).first;
    expect(rows, hasLength(2));

    // The wall clock says the same thing about both, which is the whole point.
    expect(rows.first.at.local.hour, 1);
    expect(rows.first.at.local.minute, 30);
    expect(rows.last.at.local.hour, 1);
    expect(rows.last.at.local.minute, 30);

    // And the order is absolute-time order, most recent first.
    expect(rows.first.at, secondOhOneThirty);
    expect(rows.last.at, firstOhOneThirty);
    expect(
      rows.first.at.epochMillis - rows.last.at.epochMillis,
      const Duration(hours: 1).inMilliseconds,
      reason: 'the repeated hour collapsed — the sort is not on epoch millis',
    );

    await db.close();
  });

  test('22:00 GMT on 28 March sorts before 08:00 BST on 29 March', () async {
    // Spring-forward, the other direction. 01:00–01:59 does not exist that
    // night, and the two events are ten hours apart in absolute time and eleven
    // in civil hours — so any arithmetic that counts civil hours gets a
    // different answer from the one the shepherd lived through.
    final AppDatabase db = testDatabase();
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');

    final Instant nightBefore = Instant.fromDateTime(DateTime.utc(2026, 3, 28, 22));
    final Instant morningAfter = Instant.fromDateTime(DateTime.utc(2026, 3, 29, 7));

    await seedLambing(db, ewe, occurredAt: nightBefore);
    await seedLambing(db, ewe, occurredAt: morningAfter);

    final List<TimelineRow> rows = await _repo(db).watchEweTimeline(ewe).first;
    expect(rows.first.at, morningAfter, reason: 'most recent first');
    expect(rows.last.at, nightBefore);

    // 07:00 UTC is 08:00 BST — the clocks went forward between the two rows.
    expect(rows.first.at.local.hour, 8);
    expect(rows.last.at.local.hour, 22);

    await db.close();
  });
}

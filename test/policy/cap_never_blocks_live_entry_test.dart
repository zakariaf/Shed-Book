// test/policy/cap_never_blocks_live_entry_test.dart
//
// **NAMED FOR THE PROPERTY, NOT THE FILE IT TESTS** (`CONVENTIONS §4.1`).
//
// Decision #91, in one sentence: *a shepherd mid-lambing is never told to pay.*
// It is not a preference and it is not a UX nicety — it is the line between a
// product that records a lambing at 03:20 and a product that interrupts one to
// ask for money. The whole free-tier design exists downstream of it.
//
// **THE WHOLE INPUT GRID, NOT A SAMPLE.** `FreeTierPolicy.decide` takes five
// inputs and its five statements are in a fixed order that IS the policy. A test
// that picked interesting combinations would be a test that agreed with whoever
// picked them; this enumerates every combination of the four that matter and
// asserts one property over all of them.
@Tags(<String>['policy'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/time/instant.dart';

void main() {
  test('no input at all makes the live-entry path refuse', () {
    // **THE ANCHOR, AS A PROPERTY OVER THE FULL GRID.** 2 entitlement states x 2
    // hours x 4 ewe counts x 3 season counts = 48 combinations, and
    // `EntryContext.liveEntry` returns `Allow` for every one of them.
    //
    // Decision #91 makes this *structural* rather than promised: `decide`'s
    // `liveEntry` arm returns before either cap statement is reached, so there
    // is no path through the function that can refuse. The grid is what proves
    // the arm has not moved.
    const FreeTierPolicy policy = FreeTierPolicy();

    // 03:20 in the shed, and 14:00 in daylight. The hours matter because the
    // quiet-hours degrade sits between the live-entry arm and the caps, and a
    // reordering would show up here rather than in a screen test six epics on.
    final List<Instant> hours = <Instant>[
      Instant.fromDateTime(DateTime.utc(2026, 3, 14, 3, 20)),
      Instant.fromDateTime(DateTime.utc(2026, 3, 14, 14)),
    ];

    int checked = 0;
    for (final bool unlocked in <bool>[false, true]) {
      for (final Instant now in hours) {
        for (final int ewes in <int>[0, kFreeEweCap - 1, kFreeEweCap, kFreeEweCap + 1]) {
          for (final int seasons in <int>[
            kFreeSeasonCount,
            kFreeSeasonCount + 1,
            kFreeSeasonCount + 5,
          ]) {
            final CapDecision decision = policy.decide(
              context: EntryContext.liveEntry,
              now: now,
              unlocked: unlocked,
              ewesInCurrentSeason: ewes,
              seasonCount: seasons,
            );
            expect(
              decision,
              isA<Allow>(),
              reason:
                  'liveEntry refused at unlocked=$unlocked ewes=$ewes seasons=$seasons — '
                  'a shepherd mid-lambing was told to pay',
            );
            checked++;
          }
        }
      }
    }

    // The count is derived from the loops, so a lost dimension is visible rather
    // than silently halving the grid.
    expect(checked, 2 * 2 * 4 * 3);
  });

  test('over the cap, the live-entry row is still written and carries the marker', () {
    // **THE ROW IS REAL** (`07 §19.4` rule 1: *"rows over the cap are real
    // rows"*). `Allow(overFreeCap: true)` is not a soft refusal — the record is
    // written in full, and the marker exists only so that unlocking can clear it.
    const FreeTierPolicy policy = FreeTierPolicy();

    final CapDecision decision = policy.decide(
      context: EntryContext.liveEntry,
      now: Instant.fromDateTime(DateTime.utc(2026, 3, 14, 3, 20)),
      unlocked: false,
      ewesInCurrentSeason: kFreeEweCap + 1,
      seasonCount: kFreeSeasonCount + 1,
    );

    expect(decision, isA<Allow>());
    expect((decision as Allow).overFreeCap, isTrue);
  });

  test('the calm path is the only one that can refuse, and only outside quiet hours', () {
    // The mirror of the anchor: if the calm path never refused either, the whole
    // free tier would be decoration and this file would be asserting nothing.
    const FreeTierPolicy policy = FreeTierPolicy();
    final Instant daylight = Instant.fromDateTime(DateTime.utc(2026, 3, 14, 14));
    final Instant night = Instant.fromDateTime(DateTime.utc(2026, 3, 14, 23, 30));

    expect(
      policy.decide(
        context: EntryContext.calm,
        now: daylight,
        unlocked: false,
        ewesInCurrentSeason: kFreeEweCap + 1,
        seasonCount: kFreeSeasonCount,
      ),
      isA<BlockedByCap>(),
    );

    // **22:00–06:00 ALLOWS, PERMANENTLY, AND IT IS NOT A BUG TO FIX.**
    // `07 §19.3` rule 2 and `11 §7.4` say so out loud: the app does not solicit
    // at night, and deferring the refusal to the morning is the "fix" they name.
    expect(
      policy.decide(
        context: EntryContext.calm,
        now: night,
        unlocked: false,
        ewesInCurrentSeason: kFreeEweCap + 1,
        seasonCount: kFreeSeasonCount,
      ),
      isA<Allow>(),
    );
  });

  test('season-primary: when both are over, the reason is the season', () {
    // The order of the two `if`s in `decide` IS the ruling (§7.0 ruling 8). A
    // restored three-season backup therefore refuses a calm create with
    // `secondSeason` — which is the honest shape of *the cap constrains the next
    // write, never the existing records*.
    const FreeTierPolicy policy = FreeTierPolicy();

    final CapDecision decision = policy.decide(
      context: EntryContext.calm,
      now: Instant.fromDateTime(DateTime.utc(2026, 3, 14, 14)),
      unlocked: false,
      ewesInCurrentSeason: kFreeEweCap + 1,
      seasonCount: kFreeSeasonCount + 1,
    );

    expect((decision as BlockedByCap).reason, RefusalReason.secondSeason);
  });

  test('unlocked allows everything, and never carries a marker', () {
    // The `unlocked` arm returns before every other statement, so a paid
    // notebook cannot be marked over-cap by any input — which is what makes
    // `markUnlocked`'s marker clear a one-time act rather than a race.
    const FreeTierPolicy policy = FreeTierPolicy();

    for (final EntryContext context in EntryContext.values) {
      final CapDecision decision = policy.decide(
        context: context,
        now: Instant.fromDateTime(DateTime.utc(2026, 3, 14, 14)),
        unlocked: true,
        ewesInCurrentSeason: 4000,
        seasonCount: 40,
      );
      expect(decision, isA<Allow>(), reason: context.name);
      expect((decision as Allow).overFreeCap, isFalse, reason: context.name);
    }
  });
}

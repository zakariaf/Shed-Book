// test/domain/free_tier_test.dart — the cap, eleven epics before it is wired.
//
// NO uk-zone case, and the reason is worth stating rather than omitting. The
// only local-hour read in this file is isQuietHours, and every case below
// constructs its instant FROM a local wall time and asserts about that same wall
// time — so the assertion is true in every zone by construction. There is no
// elapsed-time arithmetic here for a transition to bite, and the whole-grid
// property in test/policy/cap_never_blocks_live_entry_test.dart sweeps all 24
// local hours anyway.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/time/instant.dart';

/// A local wall time on an ordinary day, as an Instant.
Instant at(int hour, int minute) => Instant.fromDateTime(DateTime(2026, 6, 3, hour, minute));

const FreeTierPolicy _policy = FreeTierPolicy();

CapDecision _calm({required int ewes, int seasons = 1, bool unlocked = false, int hour = 14}) =>
    _policy.decide(
      context: EntryContext.calm,
      now: at(hour, 0),
      unlocked: unlocked,
      ewesInCurrentSeason: ewes,
      seasonCount: seasons,
    );

void main() {
  test('isQuietHours is true at 23:00 and 05:59 local and decide never refuses '
      'EntryContext.liveEntry', () {
    expect(isQuietHours(at(23, 0)), isTrue);
    expect(isQuietHours(at(5, 59)), isTrue);
    expect(isQuietHours(at(6, 0)), isFalse);
    expect(isQuietHours(at(21, 59)), isFalse);

    expect(
      _policy.decide(
        context: EntryContext.liveEntry,
        now: at(14, 0),
        unlocked: false,
        ewesInCurrentSeason: 99,
        seasonCount: 5,
      ),
      isA<Allow>(),
    );
  });

  test('both isQuietHours boundaries, in both directions', () {
    // 22:00 opens the window and 06:00 closes it. Both are inclusive on the
    // quiet side, and an off-by-one here is the app asking for money at 05:59.
    expect(isQuietHours(at(21, 59)), isFalse);
    expect(isQuietHours(at(22, 0)), isTrue);
    expect(isQuietHours(at(5, 59)), isTrue);
    expect(isQuietHours(at(6, 0)), isFalse);
  });

  test('ewe #15 is allowed and ewe #16 is refused in calm', () {
    // The counts are POST-WRITE. Writing the fifteenth ewe means
    // ewesInCurrentSeason is 15, and 15 is inside the cap.
    expect(_calm(ewes: 15), isA<Allow>());
    expect((_calm(ewes: 15) as Allow).overFreeCap, isFalse);

    final CapDecision sixteenth = _calm(ewes: 16);
    expect(sixteenth, isA<BlockedByCap>());
    expect((sixteenth as BlockedByCap).reason, RefusalReason.eweCap);
  });

  test('season #1 is allowed and season #2 is refused in calm', () {
    expect(_calm(ewes: 1), isA<Allow>());
    final CapDecision second = _calm(ewes: 1, seasons: 2);
    expect((second as BlockedByCap).reason, RefusalReason.secondSeason);
  });

  test('both over → the reason is secondSeason, not eweCap', () {
    // Season-primary. The order of the last two ifs is the ruling, so a restored
    // three-season backup refuses with secondSeason — the honest shape of "the
    // cap is never applied retroactively".
    final CapDecision both = _calm(ewes: 40, seasons: 3);
    expect((both as BlockedByCap).reason, RefusalReason.secondSeason);
  });

  test('unlocked short-circuits everything and returns Allow(overFreeCap: false)', () {
    final CapDecision d = _calm(ewes: 400, seasons: 9, unlocked: true);
    expect(d, isA<Allow>());
    expect((d as Allow).overFreeCap, isFalse, reason: 'the flag clears on unlock');
  });

  test('a calm gate at 22:30 returns Allow(overFreeCap: true), and the flag is '
      'what N30 reads', () {
    // The app does not solicit at night even in a calm context. The write goes
    // through, the row is real, and the flag rides on it.
    final CapDecision d = _calm(ewes: 40, hour: 22);
    expect(d, isA<Allow>());
    expect((d as Allow).overFreeCap, isTrue);
  });

  test('an over-cap live entry is allowed and carries the flag', () {
    final CapDecision d = _policy.decide(
      context: EntryContext.liveEntry,
      now: at(14, 0),
      unlocked: false,
      ewesInCurrentSeason: 40,
      seasonCount: 1,
    );

    expect(d, isA<Allow>());
    expect((d as Allow).overFreeCap, isTrue, reason: 'nothing is withheld; the flag is the record');
  });
}

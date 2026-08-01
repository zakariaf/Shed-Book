// test/policy/cap_never_blocks_live_entry_test.dart — 11 §12.2's whole-grid
// property.
//
// "Nothing monetization-related renders on the five shed screens at any
// entitlement state" is one of the four non-negotiables, and this is the half of
// it that is a PROPERTY rather than a promise: across every input the policy
// takes, EntryContext.liveEntry cannot reach BlockedByCap.
//
// 2 x 31 x 5 x 24 = 7 440 cases, and they run in milliseconds because the
// function is pure. That is the whole argument for the cap living in the domain
// rather than in a widget: a UI check is one refactor from being bypassed and
// cannot be swept like this.
@Tags(<String>['policy'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/time/instant.dart';

void main() {
  test('decide(context: liveEntry, …) never returns BlockedByCap across the whole grid', () {
    const FreeTierPolicy policy = FreeTierPolicy();
    int cases = 0;

    for (final bool unlocked in <bool>[false, true]) {
      for (int ewes = 0; ewes <= 30; ewes++) {
        for (int seasons = 1; seasons <= 5; seasons++) {
          for (int hour = 0; hour < 24; hour++) {
            final CapDecision d = policy.decide(
              context: EntryContext.liveEntry,
              now: Instant.fromDateTime(DateTime(2026, 6, 3, hour)),
              unlocked: unlocked,
              ewesInCurrentSeason: ewes,
              seasonCount: seasons,
            );
            expect(
              d,
              isA<Allow>(),
              reason: 'unlocked=$unlocked ewes=$ewes seasons=$seasons hour=$hour',
            );
            cases++;
          }
        }
      }
    }

    // The count is asserted so a future refactor that narrows the loops is
    // visible: a grid that quietly shrank to one case still passes the assertion
    // above.
    expect(cases, 7440);
  });

  test('the same grid in calm DOES refuse, which is what makes the property mean something', () {
    // A property that holds because nothing ever refuses proves nothing. This is
    // the control: the identical inputs, one enum member different, and the
    // refusals appear.
    const FreeTierPolicy policy = FreeTierPolicy();
    int refusals = 0;

    for (int ewes = 0; ewes <= 30; ewes++) {
      for (int seasons = 1; seasons <= 5; seasons++) {
        final CapDecision d = policy.decide(
          context: EntryContext.calm,
          now: Instant.fromDateTime(DateTime(2026, 6, 3, 14)),
          unlocked: false,
          ewesInCurrentSeason: ewes,
          seasonCount: seasons,
        );
        if (d is BlockedByCap) {
          refusals++;
        }
      }
    }

    expect(refusals, greaterThan(0));
  });
}

// test/policy/flock_generator_test.dart — the generator's own invariants.
//
// **THE GENERATOR IS TEST INFRASTRUCTURE, WHICH IS EXACTLY WHY IT NEEDS TESTS.**
// A wrong assertion fails loudly; a wrong *fixture* passes quietly, and every
// test standing on it passes with it. Three of this file's four cases exist
// because the generator was wrong in that silent way and something four layers
// downstream reported it.
@Tags(<String>['policy'])
library;

import 'package:flutter_test/flutter_test.dart';

import '../../tool/flock_generator.dart';

void main() {
  test('every tag is unique and at least one collides with another as a prefix', () {
    // **BOTH PROPERTIES, AND THE FIRST TWO DRAFTS HAD ONE EACH.**
    //
    // `% 900` gave 400 distinct tags with a prefix collision arithmetically
    // impossible. `% 300` gave the collision and duplicate tags, which
    // `ewes.tag`'s partial unique index refused — and nothing caught it until 400
    // rows tried to land. This case is the drill for both directions at once.
    final FlockGenerator g = FlockGenerator(137);
    final List<String> tags = <String>[for (int n = 0; n < 400; n++) g.tag(n)];

    expect(tags.toSet(), hasLength(tags.length), reason: 'ewes.tag is uniquely indexed');

    // A tag that is a strict prefix of another — `2096` and `20960` — is the one
    // pair the tag index ranks wrong and the one a sequential generator can never
    // produce.
    final Set<String> set = tags.toSet();
    expect(
      tags.where((String t) => set.any((String o) => o != t && o.startsWith(t))),
      isNotEmpty,
      reason: 'no prefix collision means the tag index bug is untested',
    );
  });

  test('every tag sits in the reserved band, above the hand-written seeders', () {
    // **THE SEPARATION THE MATRIX DEPENDS ON.** The fixture is a backdrop and the
    // `seeds.dart` helpers write on top of it, so their tag spaces must be
    // disjoint. They were not: the flock spanned `100`–`499`, `_seedHardLambing`
    // inserts ewe `412`, and all 144 matrix cells failed at once with
    // `WriteFailed`.
    //
    // **THE BOUND IS A LITERAL, AND THE FIRST DRAFT'S WAS NOT.** It read
    // `greaterThanOrEqualTo(kFixtureTagBase)` — the generator compared against
    // the constant the generator uses, so moving the band back to 100 kept it
    // green. Caught by planting exactly that. A test whose expected value is
    // computed from the thing under test asserts only that arithmetic is
    // deterministic.
    const int line = 2000;
    expect(
      kFixtureTagBase,
      line,
      reason: 'the band moved — every seeder tag below it is now at risk',
    );

    for (int n = 0; n < 400; n++) {
      final String tag = FlockGenerator(137).tag(n);
      final int digits = int.parse(tag.replaceAll(RegExp('[^0-9]'), ''));
      expect(
        digits,
        greaterThanOrEqualTo(line),
        reason: '$tag is below the band and can collide with a seeder',
      );
    }

    // AND THE TAGS THE SEEDERS ACTUALLY WRITE, spelled out. The band is an
    // abstraction; these are the six literals that collided for real when it was
    // wrong, and they fail by name rather than by arithmetic.
    final Set<String> generated = <String>{
      for (int n = 0; n < 400; n++) FlockGenerator(137).tag(n),
    };
    for (final String seeded in <String>['412', '400', '401', '402', '900', '1077', '40001']) {
      expect(generated, isNot(contains(seeded)), reason: 'a seeds.dart tag is inside the flock');
    }
  });

  test('the flock carries app_settings with a current season', () {
    // **THE ROW THE GENERATOR FORGOT.** Every write verb reads the current season
    // out of `app_settings` — `getSingle()` on `id = 1` — so a flock without it
    // restores to a database the app cannot write to.
    //
    // Nothing said so. The restore committed, `foreign_key_check` passed, and
    // every declared count matched, because the counts count what the FILE holds.
    // It surfaced as `Bad state: No element` from `TreatmentRepository`, four
    // layers from the omission.
    final Map<String, Object?> tables = flockTables(ewes: 20, seasons: 2, seed: 7);

    final List<Object?> settings = tables['app_settings']! as List<Object?>;
    expect(settings, hasLength(1), reason: 'app_settings is a singleton, id = 1');

    final Map<String, Object?> row = settings.single! as Map<String, Object?>;
    expect(row['current_season_uid'], isNotNull, reason: 'no current season is an unusable flock');
    // AND IT POINTS AT A SEASON THAT EXISTS. A dangling uid resolves to null on
    // import, which lands the same unusable database by a different route.
    expect(<Object?>[
      for (final Object? s in tables['seasons']! as List<Object?>)
        (s! as Map<String, Object?>)['uid'],
    ], contains(row['current_season_uid']));
  });

  test('the same seed produces the same flock', () {
    // Determinism is the constraint the whole generator is built around: a
    // committed fixture that changed every regeneration would be unreviewable in
    // a diff, which is most of what a committed fixture is for.
    expect(
      flockTables(ewes: 30, seasons: 2, seed: 99).toString(),
      flockTables(ewes: 30, seasons: 2, seed: 99).toString(),
    );
  });
}

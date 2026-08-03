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

  test('the flock carries the four shapes 12 §11.5 names', () {
    // **THE FIXTURE SPEC IS A CONTRACT AND THE GENERATOR WAS IGNORING IT.** The
    // table in `12 §11.5` names what `flock_400_3seasons.json` must contain: a
    // culled ewe whose tag a live ewe reuses, an edited timestamp, a
    // contradictory lambing, unicode notes. The first version emitted four
    // tables of uniformly active ewes and no notes at all — so every test that
    // believed it was exercising those shapes was exercising their absence, and
    // nothing said so because a fixture cannot fail.
    //
    // Found while starting N26, whose culled-tag rendering and warning badge both
    // need shapes that were not there.
    final Map<String, Object?> t = flockTables(ewes: 120, seasons: 3, seed: 137);
    List<Map<String, Object?>> rows(String name) => <Map<String, Object?>>[
      for (final Object? r in t[name]! as List<Object?>) r! as Map<String, Object?>,
    ];

    // 1 — A CULLED EWE WHOSE TAG A LIVE EWE REUSES. The one shape that makes
    // `idx_ewe_tagdigits`' partial uniqueness meaningful: the index covers
    // ACTIVE animals only, so this pair is legal and a flock without it never
    // proves the predicate is there.
    final List<Map<String, Object?>> ewes = rows('ewes');
    final Iterable<Map<String, Object?>> culled = ewes.where(
      (Map<String, Object?> e) => e['status'] == 'culled',
    );
    expect(culled, isNotEmpty, reason: 'no culled ewe');
    expect(
      ewes.where(
        (Map<String, Object?> e) => e['status'] == 'active' && e['tag'] == culled.first['tag'],
      ),
      isNotEmpty,
      reason: 'the culled tag is not reused by a live ewe',
    );

    // 2 — AN EDITED TIMESTAMP, with its `original_effective`. The schema's paired
    // CHECK makes them inseparable, so asserting both is asserting the row is
    // storable at all.
    final Iterable<Map<String, Object?>> edited = rows(
      'lambings',
    ).where((Map<String, Object?> l) => l['time_source'] == 'edited');
    expect(edited, isNotEmpty, reason: 'no edited timestamp');
    expect(
      edited.every((Map<String, Object?> l) => l['original_effective'] != null),
      isTrue,
      reason: "time_source 'edited' without original_effective is unstorable",
    );

    // 3 — A CONTRADICTORY LAMBING. `lambing_consistency` computes
    // `is_mismatched` from `declared_birth_type` against the attached lamb
    // count, and it is the only source of the Flock row's warning badge
    // (decision #54: a warning cannot be persisted). A flock where declared
    // always equals counted can never light it.
    final Map<String, int> lambsPerLambing = <String, int>{};
    for (final Map<String, Object?> l in rows('lambs')) {
      final String k = l['lambing_uid']! as String;
      lambsPerLambing[k] = (lambsPerLambing[k] ?? 0) + 1;
    }
    expect(
      rows('lambings').where((Map<String, Object?> l) {
        final int declared = l['declared_birth_type']! as int;
        final int counted = lambsPerLambing[l['uid']] ?? 0;
        // declared = 5 means "more than four, count not declared", so five or
        // more attached lambs is NOT a mismatch — the view says so and this
        // must agree with it or the assertion counts phantom warnings.
        return declared != counted && !(declared == 5 && counted >= 5);
      }),
      isNotEmpty,
      reason: 'no contradictory lambing — the warning badge can never light',
    );

    // 4 — UNICODE NOTES. A flock of ASCII never exercises the CSV writer's
    // quoting, the FTS5 tokeniser, or an ellipsis at a grapheme boundary.
    final List<Map<String, Object?>> notes = rows('notes');
    expect(notes, isNotEmpty, reason: 'no notes at all');
    expect(
      notes.any((Map<String, Object?> n) => (n['body']! as String).runes.any((int r) => r > 127)),
      isTrue,
      reason: 'every note is ASCII',
    );
  });

  test('the at-cap fixture takes no culled ewe', () {
    // Its ewe count IS the free tier's boundary (§7.0 ruling 8), so it has to
    // mean one thing. With the culled row switched on it read sixteen — still
    // fifteen active, still at cap by the product's own rule, and exactly the
    // ambiguity a boundary fixture must not carry.
    final Map<String, Object?> t = flockTables(
      ewes: 15,
      seasons: 1,
      seed: 41,
      withCulledReusedTag: false,
    );
    expect(t['ewes']! as List<Object?>, hasLength(15));
  });
}

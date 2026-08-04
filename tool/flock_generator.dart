// test/support/flock_generator.dart — one plausible flock, from one integer.
//
// **HAND-ROLLED, AND DELIBERATELY NOT A `glados` `Any` EXTENSION** (#118). A
// property library generates values that satisfy a type; this generates values
// that satisfy a *shepherd* — 400 ewes where a few are barren, litters that are
// mostly twins, a handful of losses, and tags that look like tags.
//
// **`tool/seed.dart` AND THE ROUND-TRIP PROPERTY CALL THE SAME GENERATOR.** Two
// generators is two definitions of *plausible*, and the day they disagree is the
// day a fixture stops representing what the property tested.
//
// **EVERY UID IS DERIVED FROM THE SEED.** `newUid()` is UUID v7 — a timestamp and
// randomness — so a generator that used it would produce a different file every
// run, and the committed fixtures would be unreviewable in a diff. That is the
// single constraint this file is built around.
library;

import 'dart:math';

import 'package:shed_book/domain/policy/export_envelope.dart';
import 'package:shed_book/domain/time/instant.dart';

/// **THE RESERVED BAND.** Every tag a generated flock carries starts here, so
/// the fixtures occupy `2000`–`2399` and the hand-written seeders in
/// `test/support/` keep the space below it.
///
/// The two have to be disjoint because `ewes.tag` is uniquely indexed on active
/// animals (§7.0 ruling 7) and the matrix now loads a fixture **and then** runs a
/// seeder on top of it. They were not disjoint, and all 144 cells said so at
/// once. One number holds the separation; `flock_generator_test.dart` asserts it
/// rather than trusting this comment.
const int kFixtureTagBase = 2000;

/// One flock, reproducibly.
///
/// The same seed produces byte-identical output, which is what makes
/// `FlockGenerator(137)` a useful thing to put in a failure message.
final class FlockGenerator {
  FlockGenerator(this.seed) : _random = Random(seed);

  final int seed;
  final Random _random;

  /// A UUID-shaped string derived from the seed and a counter.
  ///
  /// **Shaped like a v7 uid but deterministic**: 36 characters, the hyphens
  /// where `media_assets`' `CHECK` expects them, and the same value on every run.
  /// It is not a real v7 and does not claim to be — nothing in the app parses a
  /// uid, it only compares them.
  String uid(String prefix, int n) {
    final String tail = (seed * 1000003 + n).toRadixString(16).padLeft(12, '0');
    final String head = prefix.padRight(8, '0').substring(0, 8);
    return '$head-${tail.substring(0, 4)}-7${tail.substring(4, 7)}-'
        'a${tail.substring(7, 10)}-${tail.padRight(12, '0').substring(0, 12)}';
  }

  /// Tags a shepherd would recognise: mostly three digits, a few with a letter,
  /// none of them sequential all the way through.
  ///
  /// Sequential tags are what a naive generator produces and they hide the one
  /// bug the tag index has — `2096` and `20960` ranking wrong — because a run of
  /// consecutive numbers never produces a prefix collision.
  String tag(int n) {
    // **UNIQUE, AND STILL COLLIDING ON A PREFIX.** Both properties at once, and
    // the first two drafts had one each.
    //
    // Draft one used `% 900`, giving 400 distinct three-digit tags — unique, and
    // no prefix collision was arithmetically possible. Draft two narrowed to
    // `% 300` so bases repeated, which produced the collision **and duplicate
    // tags**, and `ewes.tag` carries a partial unique index on active animals
    // (§7.0 ruling 7). The 400-ewe fixture refused to load. Measured, twice.
    //
    // So: the plain form is `kFixtureTagBase + n`, distinct for every ewe. Every
    // ninety-
    // seventh ewe instead takes the PREVIOUS ewe's number with a `0` appended —
    // five digits, so it can collide with no four-digit tag, and distinct from
    // every other five-digit tag because `n` is.
    //
    // That gives `2096` and `20960` in the same flock — the pair the tag index
    // ranks wrong, and the one a sequential generator can never make. (An earlier
    // comment here claimed the pair was `412`/`4120`. It was not: `4120` is
    // `${100 + n - 1}0` for no `n`, and reading the generated file said so.)
    //
    // **THE BASE IS 2000, AND THAT IS A RESERVED BAND (`kFixtureTagBase`).**
    // It was `100`, which put the flock across `100`–`499` — straight through
    // the tags the hand-written seeders use. Every one of the 144 matrix cells
    // failed with `WriteFailed` the first time the fixture became their backdrop,
    // because `_seedHardLambing` inserts ewe `412` and the fixture already owned
    // it (`ewes.tag` is uniquely indexed, §7.0 ruling 7).
    //
    // Moving the fixture up is the one-line fix; prefixing every seeder tag is
    // the N-line one, and it would have to be redone by whoever writes seeder
    // N+1. Four-to-five digit tags are what UK ear tags actually look like, so
    // nothing is lost. `flock_generator_test.dart` holds the band.
    if (n > 0 && n % 97 == 0) {
      return '${kFixtureTagBase + n - 1}0';
    }
    // A few carry a letter, because real ear tags do and a digits-only flock
    // never exercises `tag_digits` being a projection rather than the tag.
    return _random.nextInt(23) == 0 ? 'B${kFixtureTagBase + n}' : '${kFixtureTagBase + n}';
  }

  /// Most ewes rear twins; a few are barren; a few have a single or triplets.
  ///
  /// The distribution matters because a flock of uniform twins never exercises
  /// the birth-type tally past two strokes, and the five-bar gate is the thing
  /// most likely to be wrong.
  int litterSize() {
    final int r = _random.nextInt(100);
    if (r < 8) {
      return 0; // barren
    }
    if (r < 25) {
      return 1;
    }
    if (r < 85) {
      return 2;
    }
    return r < 97 ? 3 : 4;
  }

  /// Roughly one lamb in twelve does not survive, and one in five of those is
  /// stillborn rather than a later death — its own bucket, never folded in.
  String lambStatus() {
    final int r = _random.nextInt(100);
    if (r < 92) {
      return 'alive';
    }
    return _random.nextInt(5) == 0 ? 'stillborn' : 'dead';
  }

  /// Grams. A newborn lamb is 3–6 kg and the outliers are what the unit
  /// formatter gets wrong.
  int birthWeightGrams() => 3000 + _random.nextInt(3000);

  /// An offset in minutes from the season start, so lambings cluster the way a
  /// tupping does rather than spreading evenly across three months.
  ///
  /// A uniform spread makes the spread chart look right when it is not: the
  /// chart's whole job is to show a shepherd whether their tupping was tight.
  int lambingOffsetMinutes(int n) {
    final double bell = (_random.nextDouble() + _random.nextDouble()) / 2;
    return (bell * 45 * 24 * 60).round() + n % 60;
  }
}

/// The seed's envelope.
///
/// **A FIXED INSTANT, NOT `appNow()`.** Same seed, same bytes: a clock read here
/// would make every regeneration of the two committed fixtures a different file,
/// and an unreviewable diff is most of what they would then be.
ExportEnvelope seedEnvelope() => ExportEnvelope.standard(
  now: Instant.fromDateTime(DateTime.utc(2026, 7, 27, 21, 4)),
  appVersion: '1.0.0',
);

/// The whole flock, as the backup format carries it — uids, `<parent>_uid`
/// pointers, no integer ids.
///
/// **Built as a file rather than as rows**, because the seed's whole design is
/// that it writes through `RestoreService`: producing rows directly would be the
/// second writer this task exists to avoid.
Map<String, Object?> flockTables({
  required int ewes,
  required int seasons,
  required int seed,
  bool withCulledReusedTag = true,
}) {
  final FlockGenerator g = FlockGenerator(seed);
  const int dayMs = 24 * 60 * 60 * 1000;
  final int firstSeasonStart = DateTime.utc(2026 - seasons + 1, 1, 1).millisecondsSinceEpoch;

  final List<Map<String, Object?>> seasonRows = <Map<String, Object?>>[];
  final List<Map<String, Object?>> eweRows = <Map<String, Object?>>[];
  final List<Map<String, Object?>> lambingRows = <Map<String, Object?>>[];
  final List<Map<String, Object?>> lambRows = <Map<String, Object?>>[];
  final List<Map<String, Object?>> eweSeasonRows = <Map<String, Object?>>[];

  for (int s = 0; s < seasons; s++) {
    final int year = 2026 - seasons + 1 + s;
    seasonRows.add(<String, Object?>{
      'uid': g.uid('season', s),
      'created_at': firstSeasonStart + s * 365 * dayMs,
      'updated_at': firstSeasonStart + s * 365 * dayMs,
      'year': year,
      'label': '$year',
      'start_date': '$year-01-01',
    });
  }

  // **THE FOUR SHAPES `12 §11.5` NAMES, AND THE FIXTURE CARRIED NONE OF THEM.**
  // The table in that section is not decoration — it is what four topics load
  // this file *for*: a culled ewe whose tag a live ewe reuses, an edited
  // timestamp, a contradictory lambing, unicode notes. The first version of this
  // generator emitted four tables of uniformly `active` ewes and no notes at all,
  // so every test that believed it was exercising those shapes was exercising
  // their absence. Found while starting N26, whose *culled tag* rendering and
  // *currently penned* filter both need them.
  //
  // Pens and treatments are here for the same reason one step further on: N26's
  // own T01 test asserts the *currently penned* filter narrows the list to the
  // count of open `pen_occupancies` rows. With no pens that assertion reads
  // `0 == 0` and passes against an implementation that ignores the filter.
  final List<Map<String, Object?>> penRows = <Map<String, Object?>>[];
  final List<Map<String, Object?>> occupancyRows = <Map<String, Object?>>[];
  final List<Map<String, Object?>> noteRows = <Map<String, Object?>>[];
  int openOccupancies = 0;

  // Roughly one pen per twenty ewes, floored at four — a 400-ewe shed does not
  // run on six pens, and the *currently penned* filter is only worth testing
  // against a plausible number of them.
  final int penCount = ewes ~/ 20 < 4 ? 4 : ewes ~/ 20;

  for (int p = 0; p < penCount; p++) {
    penRows.add(<String, Object?>{
      'uid': g.uid('pen', p),
      'created_at': firstSeasonStart,
      'updated_at': firstSeasonStart,
      'label': 'Pen ${p + 1}',
      'sort_order': p,
      'is_active': true,
    });
  }

  // **THE CULLED EWE WHOSE TAG A LIVE EWE REUSES.** The one shape that makes
  // `idx_ewe_tagdigits`' partial uniqueness meaningful: the index covers ACTIVE
  // animals only, so this row is legal and a flock without it never proves the
  // predicate is there. A shepherd really does put last year's number back on a
  // new ewe.
  //
  // **AND IT IS OFF FOR THE AT-CAP FIXTURE.** `flock_15_at_cap.json` exists to
  // BE the free tier's boundary (§7.0 ruling 8), so its ewe count has to mean one
  // thing. Switching this on took it to sixteen rows — still fifteen *active*,
  // so still at cap by the product's own rule, and that is exactly the ambiguity
  // a boundary fixture must not carry. `12 §11.5` assigns this shape to the
  // 400-ewe fixture and to that one only.
  final String reusedTag = g.tag(3);
  if (withCulledReusedTag) {
    eweRows.add(<String, Object?>{
      'uid': g.uid('culled', 0),
      'created_at': firstSeasonStart,
      'updated_at': firstSeasonStart,
      'tag': reusedTag,
      'tag_digits': reusedTag.replaceAll(RegExp('[^0-9]'), ''),
      'status': 'culled',
    });
  }

  int lambN = 0;
  for (int e = 0; e < ewes; e++) {
    final String eweUid = g.uid('ewe', e);
    final String tag = g.tag(e);
    eweRows.add(<String, Object?>{
      'uid': eweUid,
      'created_at': firstSeasonStart,
      'updated_at': firstSeasonStart,
      'tag': tag,
      // The keypad's ranking projection — digits only, and it is stored rather
      // than computed on read, so the file carries it.
      'tag_digits': tag.replaceAll(RegExp('[^0-9]'), ''),
      'status': 'active',
    });

    // **ONE EWE IN SEVEN IS IN A PEN RIGHT NOW** — an open occupancy, `exited_at`
    // NULL, which is exactly what the *currently penned* filter's `EXISTS`
    // subquery looks for. Every seventh rather than a block, so the filter cannot
    // pass by taking a prefix of the list.
    if (e % 7 == 3) {
      // **AT MOST ONE OPEN OCCUPANCY PER PEN, AND THE DATABASE ENFORCES IT.**
      // `idx_penocc_one_open` is `UNIQUE (pen) WHERE exited_at IS NULL` —
      // *"the database physically refuses two ewes in pen 3 at once… the
      // whiteboard gets wiped, solved at the storage layer."* The first draft
      // put fifty-seven ewes in six pens and the fixture would not load:
      // `UNIQUE constraint failed: pen_occupancies.pen`.
      //
      // Which is the right shape anyway. A season leaves far more pen history
      // than it leaves current occupants, so the early ones stay OPEN — one per
      // pen, which is what *currently penned* filters to — and the rest are
      // CLOSED, which is what a pen board's history reads.
      final bool open = openOccupancies < penCount;
      final int enteredAt = DateTime.utc(2026, 2, 10).millisecondsSinceEpoch;
      occupancyRows.add(<String, Object?>{
        'uid': g.uid('occ', e),
        'created_at': firstSeasonStart,
        'updated_at': firstSeasonStart,
        'pen_uid': g.uid('pen', open ? openOccupancies : e % penCount),
        'season_uid': g.uid('season', seasons - 1),
        'ewe_uid': eweUid,
        'entered_at': enteredAt,
        'captured_at': enteredAt,
        'time_source': 'auto',
        // The schema pairs these: `CHECK ((exited_at IS NULL) = (exit_reason IS
        // NULL))`, so a closed occupancy without a reason is unstorable and a
        // reason without an exit is too.
        if (!open) 'exited_at': enteredAt + 2 * 24 * 3600 * 1000,
        if (!open) 'exit_reason': 'turned_out',
      });
      if (open) {
        openOccupancies++;
      }
    }

    // **UNICODE NOTES, AND THE POINT IS THE BYTES.** A flock of ASCII notes never
    // exercises the CSV writer's quoting, the FTS5 tokeniser or the row's
    // ellipsis at a grapheme boundary. Welsh, an accent, an emoji and a
    // right-to-left fragment, because those are the four that break different
    // things.
    if (e % 23 == 5) {
      const List<String> bodies = <String>[
        'Cadwyd yn y sied — llaeth yn brin',
        'Prolapsed — vet called, réussi',
        'Watch this one 🐑 next season',
        'ملاحظة: توأم',
      ];
      noteRows.add(<String, Object?>{
        'uid': g.uid('note', e),
        'created_at': firstSeasonStart,
        'updated_at': firstSeasonStart,
        'ewe_uid': eweUid,
        'body': bodies[(e ~/ 23) % bodies.length],
        'occurred_at': DateTime.utc(2026, 2, 12).millisecondsSinceEpoch,
        'captured_at': DateTime.utc(2026, 2, 12).millisecondsSinceEpoch,
        'time_source': 'auto',
      });
    }

    // **THE MOST RECENT SEASON ONLY.** `--ewes` is *ewes in the most recent
    // season*; a flock that lambed identically three years running is a flock
    // whose ewe card shows the same row three times and proves nothing.
    final int litter = g.litterSize();

    // **HER PARTICIPATION IN THE SEASON, AND THE FIXTURE CARRIED NONE OF IT.**
    // `ewe_seasons` is the table the whole free tier is counted from —
    // `_countEwesInCurrentSeason` counts ROWS HERE, not ewes — so a fixture of
    // fifteen ewes and no participation rows counted as **zero**, and
    // `flock_15_at_cap.json` was not at the cap at all. It is the file's entire
    // reason to exist (`12 §11.5`), and every N30 test that would have pumped it
    // was going to assert against the wrong side of the boundary.
    //
    // It is also where *barren* lives (R42, `03 §5.3`): a barren ewe is a stored
    // ANSWER — `status = 'barren'` — never the absence of a lambing. A flock with
    // no rows here can never light the *barren* filter, so N26-T02's own filter
    // was passing against an empty set.
    //
    // Found by N26-T04's at-cap anchor. Third table this epic has found missing
    // from a fixture that every check called complete.
    eweSeasonRows.add(<String, Object?>{
      'uid': g.uid('eweseason', e),
      'created_at': firstSeasonStart,
      'updated_at': firstSeasonStart,
      'season_uid': g.uid('season', seasons - 1),
      'ewe_uid': eweUid,
      'status': litter == 0 ? 'barren' : 'lambed',
    });

    if (litter == 0) {
      continue; // barren, and barren is a real outcome rather than an absence
    }

    final int at =
        DateTime.utc(2026, 2, 1).millisecondsSinceEpoch + g.lambingOffsetMinutes(e) * 60 * 1000;
    final String lambingUid = g.uid('lambing', e);
    lambingRows.add(<String, Object?>{
      'uid': lambingUid,
      'created_at': at,
      'updated_at': at,
      'season_uid': g.uid('season', seasons - 1),
      'ewe_uid': eweUid,
      'occurred_at': at,
      'captured_at': at,
      'local_date': DateTime.fromMillisecondsSinceEpoch(
        at,
        isUtc: true,
      ).toIso8601String().substring(0, 10),
      // **THE EDITED TIMESTAMP (`12 §11.5`).** Every fortieth lambing carries the
      // provenance quad's third state — `time_source = 'edited'` with
      // `original_effective` holding what it said before. The schema's paired
      // CHECK makes the two inseparable: `(time_source = 'edited') =
      // (original_effective IS NOT NULL)`, so a fixture cannot fake one without
      // the other, and §12.5's provenance label has something real to render.
      'time_source': e % 40 == 11 ? 'edited' : 'auto',
      if (e % 40 == 11) 'original_effective': at - 3 * 3600 * 1000,
      // **THE CONTRADICTORY LAMBING (`12 §11.5`).** `lambing_consistency`
      // computes `is_mismatched` from `declared_birth_type` against the attached
      // lamb count, and it is the source of the Flock row's warning badge
      // (`07 §3.1`: there is no `warning_count` column and there never will be,
      // decision #54). A flock where declared always equals counted can never
      // light that badge, so every thirty-first lambing declares one more than it
      // has — which is what a shepherd tapping the tally and then losing a lamb
      // actually produces.
      //
      // Not 5-vs-5-or-more: `declared = 5` means *more than four, count not
      // declared*, so five attached lambs is NOT a mismatch. Declaring `litter +
      // 1` stays under that rule for every litter this generator makes.
      'declared_birth_type': e % 31 == 17 ? litter + 1 : litter,
    });

    for (int l = 0; l < litter; l++) {
      lambRows.add(<String, Object?>{
        'uid': g.uid('lamb', lambN++),
        'created_at': at,
        'updated_at': at,
        'lambing_uid': lambingUid,
        'birth_dam_uid': eweUid,
        'status': g.lambStatus(),
        'birth_weight_g': g.birthWeightGrams(),
      });
    }
  }

  return <String, Object?>{
    // **`app_settings` FIRST, AND IT IS NOT DECORATION.** Every write verb in the
    // app reads the current season out of this row — `_currentSeason()` does
    // `getSingle()` on `id = 1` — so a flock without it is a database the app
    // cannot write to at all.
    //
    // The generator omitted it, and the fixture therefore restored to 400 ewes
    // and no settings. Nothing said so: the restore committed, `foreign_key_check`
    // passed, and every declared count matched, because the counts count what the
    // FILE holds. It surfaced as `Bad state: No element` from
    // `TreatmentRepository` when the matrix first ran against the fixture — four
    // layers away from the omission.
    //
    // **THAT IS THE SECOND TIME THIS TABLE HAS GONE MISSING IN THIS EPIC.** The
    // first was `updateRestoredSingleton` issuing an `UPDATE` that matched no
    // row; this is the file simply not carrying it. Same silence, same table,
    // two different causes — which is the argument for the round-trip property
    // over any amount of per-table checking.
    'app_settings': <Map<String, Object?>>[
      <String, Object?>{
        'id': 1,
        // POINTED AT THE MOST RECENT SEASON, resolved through `<parent>_uid`
        // like every other foreign key in the format (`kBackupForeignKeys`
        // already maps it — the mapping was there, the row was not).
        'current_season_uid': g.uid('season', seasons - 1),
        'weight_unit': 'kg',
        'palette': 'night',
        'high_contrast': false,
        'wakelock_enabled': false,
        'left_handed': false,
        'percentage_definition': 'born_alive_per_ewe_to_ram',
        'turn_out_threshold_hours': 24,
        'cycle_days': 17,
      },
    ],
    // **PARENTS BEFORE CHILDREN.** `importInto` inserts in this order and
    // resolves `<parent>_uid` as it goes, so `pens` must precede
    // `pen_occupancies` and `ewes` must precede both. The order is the contract,
    // not a preference.
    'seasons': seasonRows,
    'pens': penRows,
    'ewes': eweRows,
    'ewe_seasons': eweSeasonRows,
    'lambings': lambingRows,
    'lambs': lambRows,
    'pen_occupancies': occupancyRows,
    'notes': noteRows,
  };
}

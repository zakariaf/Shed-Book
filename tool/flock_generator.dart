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
  /// bug the tag index has — `412` and `4120` ranking wrong — because a run of
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
    // So: the plain form is `100 + n`, distinct for every ewe. Every ninety-
    // seventh ewe instead takes the PREVIOUS ewe's number with a `0` appended —
    // four digits, so it can collide with no three-digit tag, and distinct from
    // every other four-digit tag because `n` is.
    //
    // That gives `412` and `4120` in the same flock, which is the one pair the
    // tag index ranks wrong and the one a sequential generator can never make.
    if (n > 0 && n % 97 == 0) {
      return '${100 + n - 1}0';
    }
    // A few carry a letter, because real ear tags do and a digits-only flock
    // never exercises `tag_digits` being a projection rather than the tag.
    return _random.nextInt(23) == 0 ? 'B${100 + n}' : '${100 + n}';
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
Map<String, Object?> flockTables({required int ewes, required int seasons, required int seed}) {
  final FlockGenerator g = FlockGenerator(seed);
  const int dayMs = 24 * 60 * 60 * 1000;
  final int firstSeasonStart = DateTime.utc(2026 - seasons + 1, 1, 1).millisecondsSinceEpoch;

  final List<Map<String, Object?>> seasonRows = <Map<String, Object?>>[];
  final List<Map<String, Object?>> eweRows = <Map<String, Object?>>[];
  final List<Map<String, Object?>> lambingRows = <Map<String, Object?>>[];
  final List<Map<String, Object?>> lambRows = <Map<String, Object?>>[];

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

    // **THE MOST RECENT SEASON ONLY.** `--ewes` is *ewes in the most recent
    // season*; a flock that lambed identically three years running is a flock
    // whose ewe card shows the same row three times and proves nothing.
    final int litter = g.litterSize();
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
      'time_source': 'auto',
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
    'seasons': seasonRows,
    'ewes': eweRows,
    'lambings': lambingRows,
    'lambs': lambRows,
  };
}

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
    // **THE RANGE IS NARROWER THAN THE FLOCK ON PURPOSE.** With `% 900` over 400
    // draws every base is distinct — 7 and 900 are coprime — so no base can
    // appear at both widths and a prefix collision is arithmetically impossible.
    // The second draft had the widths right and still produced none.
    //
    // Real flocks reuse numbers across years anyway: a culled 412 releases the
    // tag, which is the whole reason the unique index is partial (§7.0 ruling 7).
    final int base = 100 + (n * 7) % 300;
    final int r = _random.nextInt(10);
    // **THREE DIGITS AND FOUR, MIXED**, which is what makes a prefix collision
    // possible at all — and the first draft produced only three, so `412` and
    // `4120` could never both exist.
    //
    // That pair ranking wrong is the one bug the tag index has, and a flock of
    // uniform-width tags hides it completely. Real flocks carry both widths.
    if (r == 0) {
      return 'B$base';
    }
    return r < 3 ? '${base}0' : '$base';
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

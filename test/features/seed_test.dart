// test/features/seed_test.dart — the generator that makes a 400-ewe database
// possible, and the determinism that makes its output reviewable.
//
// **`newUid()` IS WHAT BREAKS THIS.** UUID v7 carries a timestamp and
// randomness, so a generator that used it would produce a different file every
// run — and the two committed fixtures (N23-T05) would be unreviewable in a
// diff, which is most of what they are for.
library;

import 'package:flutter_test/flutter_test.dart';

import '../support/flock_generator.dart';

void main() {
  test('the seed is deterministic for a given --seed', () {
    // BYTE-STABLE, NOT MERELY EQUAL IN SHAPE. Two runs of the same seed produce
    // the same uids, the same tags and the same litters — which is what lets a
    // failure say `reproduce with FlockGenerator(42)` and mean it.
    final FlockGenerator a = FlockGenerator(42);
    final FlockGenerator b = FlockGenerator(42);

    for (int i = 0; i < 200; i++) {
      expect(a.uid('ewe', i), b.uid('ewe', i), reason: 'uid $i');
      expect(a.tag(i), b.tag(i), reason: 'tag $i');
      expect(a.litterSize(), b.litterSize(), reason: 'litter $i');
      expect(a.lambStatus(), b.lambStatus(), reason: 'status $i');
      expect(a.birthWeightGrams(), b.birthWeightGrams(), reason: 'weight $i');
    }
  });

  test('a different seed produces a different flock', () {
    // The other half: a generator that ignored its seed would pass every
    // determinism assertion above and be worthless.
    final FlockGenerator a = FlockGenerator(42);
    final FlockGenerator b = FlockGenerator(137);

    expect(a.uid('ewe', 1), isNot(b.uid('ewe', 1)));
    expect(
      List<int>.generate(50, (_) => a.litterSize()),
      isNot(List<int>.generate(50, (_) => b.litterSize())),
    );
  });

  test('a uid is 36 characters and hyphenated where the schema expects', () {
    // `media_assets.uid` carries a length CHECK and every table's `uid` is
    // compared as a string. A generator that produced a 34-character uid would
    // fail at insert with a message about length rather than about seeding.
    for (final String prefix in <String>['ewe', 'lambing', 'lamb', 'treatment']) {
      final String uid = FlockGenerator(42).uid(prefix, 7);
      expect(uid, hasLength(36), reason: uid);
      expect(
        RegExp(r'^[0-9a-z]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-a[0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(uid),
        isTrue,
        reason: uid,
      );
    }
  });

  test('the flock is plausible rather than uniform', () {
    // A uniform flock never exercises the thing most likely to be wrong. Twins
    // dominate, a few are barren, and the tail reaches four — so the five-bar
    // tally gate and the birth-type derivation both get used.
    final FlockGenerator g = FlockGenerator(42);
    final List<int> litters = List<int>.generate(400, (_) => g.litterSize());

    expect(litters.where((int l) => l == 0), isNotEmpty, reason: 'some are barren');
    expect(litters.where((int l) => l == 2).length, greaterThan(litters.length ~/ 3));
    expect(litters.toSet().length, greaterThan(3), reason: 'not one litter size for everybody');

    // AND THE TAGS COLLIDE ON A PREFIX, which sequential tags never do — `412`
    // and `4120` ranking wrong is the one bug the tag index has, and a run of
    // consecutive numbers hides it.
    final Set<String> tags = <String>{for (int i = 0; i < 400; i++) g.tag(i)};
    expect(
      tags.any((String t) => tags.any((String o) => o != t && o.startsWith(t))),
      isTrue,
      reason: 'at least one tag is a prefix of another',
    );
  });

  test('lambings cluster the way a tupping does', () {
    // A uniform spread makes the spread chart look right when it is not — and
    // the chart's whole job is to tell a shepherd whether their tupping was
    // tight.
    final FlockGenerator g = FlockGenerator(42);
    final List<int> days = <int>[
      for (int i = 0; i < 400; i++) g.lambingOffsetMinutes(i) ~/ (24 * 60),
    ];

    final Map<int, int> perDay = <int, int>{};
    for (final int d in days) {
      perDay[d] = (perDay[d] ?? 0) + 1;
    }
    final int peak = perDay.values.reduce((int a, int b) => a > b ? a : b);
    final double mean = days.length / perDay.length;

    expect(peak, greaterThan(mean * 1.5), reason: 'there is a peak, not a plateau');
  });
}

// test/features/seed_test.dart — the generator that makes a 400-ewe database
// possible, and the determinism that makes its output reviewable.
//
// **`newUid()` IS WHAT BREAKS THIS.** UUID v7 carries a timestamp and
// randomness, so a generator that used it would produce a different file every
// run — and the two committed fixtures (N23-T05) would be unreviewable in a
// diff, which is most of what they are for.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/backup_format.dart';
import '../support/harness.dart';
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

  test('the generated flock restores, and twice with one seed is byte-identical', () async {
    // **THE HALF THAT MATTERS: it goes through `RestoreService`.** A seed that
    // wrote through repositories would be a second writer, tested by nothing —
    // and the restore would go a year without being run outside its own unit
    // tests. This is what makes 400-ewe profiling, the overflow matrix and the
    // goldens possible at all.
    final Map<String, Object?> first = flockTables(ewes: 30, seasons: 2, seed: 42);
    final Map<String, Object?> second = flockTables(ewes: 30, seasons: 2, seed: 42);

    // BYTE-IDENTICAL, which is what makes N23-T05's committed fixtures
    // reviewable in a diff.
    expect(canonicalJsonBytes(first), orderedEquals(canonicalJsonBytes(second)));

    final Directory support = freshSupportDir();
    final Uint8List body = canonicalJsonBytes(first);
    final File backup = File('${support.path}/seed.json')
      ..writeAsBytesSync(<int>[
        ...utf8.encode(
          headerPrefixJson(
            BackupHeader(
              schema: kSchemaVersion,
              appVersion: '1.0.0',
              exportedAtUtc: '2026-07-27T21:04:00.000Z',
              exportedAtOffsetMinutes: 0,
              exportedAtZoneAbbreviation: 'GMT',
              counts: <String, int>{
                for (final MapEntry<String, Object?> e in first.entries)
                  e.key: (e.value! as List<Object?>).length,
              },
              media: const BackupMedia(included: false, count: 0, bytes: 0),
            ),
            fnv1a64Hex(body),
            seedEnvelope(),
          ),
        ),
        ...body,
        ...utf8.encode('}\n'),
      ]);

    final AppDatabase restored = await restoreInto(support, backup);

    // THE MARKS ONLY A RESTORE LEAVES: ids re-issued from 1 in insertion order,
    // and no `seedFirstRun` season beyond the ones the file declares.
    final List<Ewe> ewes = await restored.select(restored.ewes).get();
    // **THIRTY ACTIVE, THIRTY-ONE ROWS.** The extra is `12 §11.5`'s culled ewe
    // whose tag a live ewe reuses — the shape that makes `idx_ewe_tagdigits`'
    // partial uniqueness mean something, since that index covers active animals
    // only. Counting rows made this read `30` and fail the day the generator
    // started carrying the shapes its own spec asks for; counting what the flock
    // IS survives the next shape too.
    expect(ewes.where((Ewe e) => e.status == 'active'), hasLength(30));
    expect(ewes.where((Ewe e) => e.status == 'culled'), hasLength(1));
    expect(ewes.map((Ewe e) => e.id), containsAll(<int>[1, 2, 3]));
    expect(
      await restored.select(restored.seasons).get(),
      hasLength(2),
      reason: 'two declared seasons and no phantom third',
    );

    // AND A BARREN EWE IS A EWE WITH NO LAMBING, not an absent row.
    final List<Lambing> lambings = await restored.select(restored.lambings).get();
    expect(lambings.length, lessThan(ewes.length), reason: 'some are barren');
    expect(lambings, isNotEmpty);
  });
}

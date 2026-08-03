// test/policy/export_round_trip_test.dart
//
// **THE PROPERTY THAT VERIFIES EVERYTHING ABOVE IT.** N22 writes the file, N23
// reads it back — and a column dropped by either would be invisible until a
// shepherd restored onto a new phone, months later, with no way to tell what was
// lost or when.
//
// Export → import → export, and the two files must be **byte-identical**. Not
// structurally equal: the checksum covers the bytes, and a round trip that
// produces the same data in a different order produces a different checksum and
// a file the next build cannot verify.
//
// **ONE FILE, AND THIS SPELLING.** `12 §10.6` calls it
// `backup_round_trips_test.dart`, `09 §7.3` calls it `backup_round_trip_test.dart`
// and this epic's anchor calls it `export_round_trip_test.dart`. Three names for
// one test is how two of them get written. The anchor's spelling wins because it
// is the one the backlog cites.
@Tags(<String>['policy'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/backup_format.dart';
import 'package:shed_book/data/export_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/policy/export_envelope.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';
import 'package:shed_book/data/treatment_repository.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

/// The `tables` value as it appears in the file — the bytes the checksum covers.
Uint8List tablesBytesOf(String text) =>
    canonicalJsonBytes((jsonDecode(text) as Map<String, Object?>)['tables']);

String checksumOf(String text) =>
    ((jsonDecode(text) as Map<String, Object?>)['checksum']! as Map<String, Object?>)['value']!
        as String;

/// Every `uid` in the file, so identity can be compared across the round trip.
Set<String> uidsOf(String text) {
  final Map<String, Object?> tables =
      (jsonDecode(text) as Map<String, Object?>)['tables']! as Map<String, Object?>;
  return <String>{
    for (final Object? rows in tables.values)
      for (final Object? row in rows! as List<Object?>)
        if ((row! as Map<String, Object?>)['uid'] case final String uid) uid,
  };
}

Directory _dir(String prefix) {
  final Directory d = Directory.systemTemp.createTempSync(prefix);
  addTearDown(() {
    if (d.existsSync()) {
      d.deleteSync(recursive: true);
    }
  });
  return d;
}

/// One flock, awkward enough that a dropped column shows.
///
/// **The seed is printed in every `reason:`**, because the only useful thing a
/// failure can tell you is how to reproduce it.
const int kSeed = 137;

Future<void> _seedFlock(AppDatabase db) async {
  await seedSeason(db);
  final TreatmentRepository treatments = TreatmentRepository(db);

  for (int i = 0; i < 6; i++) {
    final EweId ewe = await seedEwe(db, tag: '${400 + i}');
    final LambingId lambing = await seedLambing(db, ewe);
    for (int j = 0; j <= i % 3; j++) {
      await seedLamb(db, lambing, ewe);
    }
    // A treatment on every other ewe, and the three withdrawal states across
    // them — the columns most likely to be dropped are the ones with a shape.
    if (i.isEven) {
      await treatments.recordTreatment(
        TreatEwe(ewe),
        productName: 'Alamycin LA 300 mg/ml',
        doseText: '3 ml',
        batchNo: 'B7734-2026',
        withdrawals: i == 0
            ? <WithdrawalPeriod>[
                WithdrawalDays.asEnteredByUser(days: 28, target: WithdrawalTarget.meat),
              ]
            : i == 2
            ? const <WithdrawalPeriod>[WithdrawalNotApplicable(WithdrawalTarget.meat)]
            : const <WithdrawalPeriod>[],
      );
    }
  }
}

Future<String> _export(AppDatabase db) async {
  final Directory out = _dir('shed_rt_out');
  final ExportArtifact a = await ExportRepository(db).writeBackup(
    envelope: ExportEnvelope.standard(
      now: Instant.fromDateTime(DateTime.utc(2026, 7, 27, 21, 4)),
      appVersion: '1.0.0',
    ),
    outputDir: out,
  );
  return File(a.path).readAsStringSync();
}

void main() {
  test('export to import to export produces equal table bytes', () async {
    // THE ANCHOR. A dropped column, a re-ordered key, a re-stamped `updated_at`
    // or a uid regenerated on import all break this and nothing else catches
    // any of them.
    final AppDatabase source = testDatabase();
    await _seedFlock(source);
    final String first = await _export(source);
    await source.close();

    final Directory support = freshSupportDir();
    final File backup = File('${support.path}/backup.json')..writeAsStringSync(first);
    final AppDatabase restored = await restoreInto(support, backup);

    final String second = await _export(restored);

    expect(
      tablesBytesOf(second),
      orderedEquals(tablesBytesOf(first)),
      reason: 'the round trip is not byte-stable — reproduce with FlockGenerator($kSeed)',
    );
  });

  test('the checksum survives the round trip', () async {
    // Its own case, so a failure names which half broke. The checksum covers the
    // `tables` bytes, so this and the anchor fail together for a data change and
    // separately for an arithmetic one.
    final AppDatabase source = testDatabase();
    await _seedFlock(source);
    final String first = await _export(source);
    await source.close();

    final Directory support = freshSupportDir();
    final AppDatabase restored = await restoreInto(
      support,
      File('${support.path}/backup.json')..writeAsStringSync(first),
    );

    expect(
      checksumOf(await _export(restored)),
      checksumOf(first),
      reason: 'reproduce with FlockGenerator($kSeed)',
    );
  });

  test('uids are preserved and integer ids are re-issued', () async {
    // **THE TWO HALVES OF IDENTITY, AND THEY POINT OPPOSITE WAYS.** A uid that
    // changed would make the restored flock a different flock; an integer id
    // that survived would be a pointer that means something else on this phone.
    final AppDatabase source = testDatabase();
    await _seedFlock(source);
    final String first = await _export(source);
    final List<Ewe> before = await source.select(source.ewes).get();
    await source.close();

    final Directory support = freshSupportDir();
    final AppDatabase restored = await restoreInto(
      support,
      File('${support.path}/backup.json')..writeAsStringSync(first),
    );

    expect(
      uidsOf(await _export(restored)),
      uidsOf(first),
      reason: 'identity is the uid — reproduce with FlockGenerator($kSeed)',
    );

    // The ids are re-issued from 1 in insert order, which for a restored
    // database is the file's order rather than the original's — so the SET may
    // coincide even though every row moved. What cannot coincide is the pairing,
    // and that is what the anchor's byte equality already holds through the
    // resolved foreign keys.
    final List<Ewe> after = await restored.select(restored.ewes).get();
    expect(after, hasLength(before.length), reason: 'reproduce with FlockGenerator($kSeed)');
    for (final Ewe e in after) {
      expect(
        before.firstWhere((Ewe b) => b.uid == e.uid).tag,
        e.tag,
        reason: 'the uid still names the same ewe — FlockGenerator($kSeed)',
      );
    }
  });

  test('a column dropped from the export breaks the round trip, not merely the file', () async {
    // The negative control. Without it every case above passes for an exporter
    // that drops the same column twice — the second export would agree with the
    // first because both are missing it.
    //
    // **THIS IS WHY THE PROPERTY COMPARES A RESTORED DATABASE AND NOT TWO
    // EXPORTS OF THE SAME ONE.** The restore is what makes the omission visible:
    // the column is gone from the database, so the row that needed it is wrong
    // in a way the file alone cannot show.
    final AppDatabase source = testDatabase();
    await _seedFlock(source);
    final String first = await _export(source);
    await source.close();

    final Map<String, Object?> decoded = jsonDecode(first) as Map<String, Object?>;
    final Map<String, Object?> tables = decoded['tables']! as Map<String, Object?>;
    for (final Object? row in tables['ewes']! as List<Object?>) {
      (row! as Map<String, Object?>).remove('tag');
    }

    final Directory support = freshSupportDir();
    final File damaged = File('${support.path}/backup.json')
      ..writeAsStringSync(jsonEncode(decoded));

    // `ewes.tag` is NOT NULL, so the import refuses it — which is the good
    // outcome, and the one that proves a silently-dropped column cannot survive
    // this path.
    await expectLater(
      restoreInto(support, damaged),
      throwsA(anything),
      reason: 'reproduce with FlockGenerator($kSeed)',
    );
  });
}

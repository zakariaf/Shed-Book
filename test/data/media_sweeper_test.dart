// test/data/media_sweeper_test.dart — reconciling the media folder with the
// database, in **both** directions.
//
// **NOTHING IS DELETED.** The word in the anchor's name is *removed*, and it
// means moved to `.trash/<yyyy-MM-dd>/<its original relative path>`. `04 §4.8` is
// spec §12.4 applied to bytes: *"the app does not silently destroy the user's
// things."*
//
// So the assertion is on where the file **arrived**, not on where it is absent
// from. A test that only checks the original path is empty passes for a `delete()`
// — which is the one implementation this whole file exists to refuse.
library;

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/data/media_sweeper.dart';
import 'package:shed_book/data/media_store.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';

import 'package:shed_book/domain/ids.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

/// A `MediaStore` rooted in one temp directory for the life of the test.
({MediaStore store, Directory root}) _store() {
  final Directory dir = Directory.systemTemp.createTempSync('shed_media');
  addTearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });
  Future<Directory> resolve() async => dir;
  return (store: MediaStore(supportDirectory: resolve, temporaryDirectory: resolve), root: dir);
}

Future<File> _file(MediaStore store, String relative) async {
  final File f = File('${(await store.root()).path}/$relative');
  f.parent.createSync(recursive: true);
  f.writeAsStringSync('bytes');
  return f;
}

/// **ATTACHED TO A EWE, because a media asset with no owner is unstorable.**
/// `media_assets` carries
/// `CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) + (lambing IS NOT NULL) + (note IS NOT NULL) = 1)`
/// — a photo belongs to exactly one thing, and the first draft of this seed
/// belonged to nothing and failed at insert.
Future<void> _row(AppDatabase db, String relative) async {
  final EweId ewe = await seedEwe(db, tag: 'm${relative.hashCode.abs() % 1000}');
  await db
      .into(db.mediaAssets)
      .insert(
        MediaAssetsCompanion.insert(
          ewe: Value<int?>(ewe.value),
          // A REAL UUID SHAPE. `media_assets.uid` is 36 characters under the
          // schema's own CHECK, and a seed that shortcuts it fails at insert with
          // a message about length rather than about media.
          uid: newUid(),
          createdAt: Instant.fromDateTime(DateTime.utc(2026, 3, 14)),
          updatedAt: Instant.fromDateTime(DateTime.utc(2026, 3, 14)),
          relativePath: relative,
          kind: 'photo',
          byteSize: 5,
        ),
      );
}

/// The date the sweep will stamp the trash folder with.
///
/// **`appNow()`, not a direct clock read** — R23 and #46 make it the app's single
/// wall-clock reader, and `time.dart_clock` refuses the alternative under `test/`
/// as well as under `lib/`. It caught the first draft of this line, which is the
/// rule working: a test that read its own clock would disagree with the sweeper
/// by a day at midnight, once a year, unreproducibly.
String get _today => LocalDate.of(appNow()).iso;

void main() {
  test('a row with no file is marked missing_since and a file with no row is removed', () async {
    // THE ANCHOR, both directions at once.
    final AppDatabase db = testDatabase();
    final ({MediaStore store, Directory root}) m = _store();

    // Direction 1 — a file nothing points at.
    await _file(m.store, '2026/03/orphan.jpg');
    // Direction 2 — a row whose file is gone.
    await _row(db, '2026/03/missing.jpg');

    final SweepReport orphans = await MediaSweeper(db, m.store).sweepOrphanFiles();
    final SweepReport missing = await MediaSweeper(db, m.store).sweepMissingFiles();

    // **MOVED, NOT DELETED**, and asserted on where it ARRIVED. A check that the
    // original path is empty passes for a `delete()`.
    final Directory root = await m.store.root();
    expect(
      File('${root.path}/.trash/$_today/2026/03/orphan.jpg').existsSync(),
      isTrue,
      reason: 'the orphan is recoverable, at its original relative path under .trash',
    );
    expect(File('${root.path}/2026/03/orphan.jpg').existsSync(), isFalse);

    // **THE ROW SURVIVES.** `04 §4.9`: deleting it *"makes the app lie by
    // omission"* — *"photo taken 14 March 03:22, file no longer on this phone"*
    // is a true and useful sentence, and an absent row is not.
    final MediaAsset row = await db.select(db.mediaAssets).getSingle();
    expect(row.relativePath, '2026/03/missing.jpg');
    expect(row.missingSince, isNotNull);

    // AND THE REPORT CARRIES BOTH COUNTS, so the Diagnostics line is real rather
    // than decorative.
    expect(orphans.orphanFilesTrashed, 1);
    expect(missing.rowsFlaggedMissing, 1);

    await db.close();
  });

  test('a file that comes back clears the flag', () async {
    // `04 §5.2`, and this is the half of direction 2 that is easiest to skip. A
    // shepherd who restored their container, or an iOS device restore that
    // brought the media back, must not be left with a permanent scar.
    final AppDatabase db = testDatabase();
    final ({MediaStore store, Directory root}) m = _store();

    await _row(db, '2026/03/back.jpg');
    expect((await MediaSweeper(db, m.store).sweepMissingFiles()).rowsFlaggedMissing, 1);

    await _file(m.store, '2026/03/back.jpg');
    final SweepReport second = await MediaSweeper(db, m.store).sweepMissingFiles();

    expect(second.rowsUnflagged, 1);
    expect((await db.select(db.mediaAssets).getSingle()).missingSince, isNull);

    await db.close();
  });

  test('a .part file is the one thing a sweep may delete', () async {
    // A killed atomic write: `MediaStore` writes `<target>.part` and renames, so
    // nothing ever referenced it and no row can point at it. Delete it, count
    // it, move on — trashing it would fill `.trash` with bytes nobody can use.
    final AppDatabase db = testDatabase();
    final ({MediaStore store, Directory root}) m = _store();

    await _file(m.store, '2026/03/half-written.jpg.part');

    final SweepReport report = await MediaSweeper(db, m.store).sweepOrphanFiles();

    expect(report.partFilesDeleted, 1);
    expect(report.orphanFilesTrashed, 0, reason: 'a .part is not an orphan');

    final Directory root = await m.store.root();
    expect(File('${root.path}/2026/03/half-written.jpg.part').existsSync(), isFalse);
    expect(
      Directory('${root.path}/.trash').existsSync() &&
          Directory('${root.path}/.trash').listSync(recursive: true).isNotEmpty,
      isFalse,
      reason: 'nothing was trashed',
    );

    await db.close();
  });

  test('the sweep never walks into its own trash', () async {
    // Without the skip, the second sweep trashes what the first one trashed —
    // one directory deeper each run, for ever.
    final AppDatabase db = testDatabase();
    final ({MediaStore store, Directory root}) m = _store();

    await _file(m.store, '2026/03/orphan.jpg');
    await MediaSweeper(db, m.store).sweepOrphanFiles();
    final SweepReport second = await MediaSweeper(db, m.store).sweepOrphanFiles();

    expect(second.orphanFilesTrashed, 0);

    final Directory root = await m.store.root();
    expect(
      File('${root.path}/.trash/$_today/2026/03/orphan.jpg').existsSync(),
      isTrue,
      reason: 'still where the first sweep put it',
    );
    expect(
      Directory('${root.path}/.trash/$_today/.trash').existsSync(),
      isFalse,
      reason: 'and not one directory deeper',
    );

    await db.close();
  });

  test('a referenced file is left alone', () async {
    // The positive, and it is the one a sweep that trashes everything would
    // fail. Written last on purpose.
    final AppDatabase db = testDatabase();
    final ({MediaStore store, Directory root}) m = _store();

    await _file(m.store, '2026/03/kept.jpg');
    await _row(db, '2026/03/kept.jpg');

    final SweepReport orphans = await MediaSweeper(db, m.store).sweepOrphanFiles();
    final SweepReport missing = await MediaSweeper(db, m.store).sweepMissingFiles();

    expect(orphans.orphanFilesTrashed, 0);
    expect(missing.rowsFlaggedMissing, 0);
    expect((await m.store.root()).path, isNotEmpty);
    expect(File('${(await m.store.root()).path}/2026/03/kept.jpg').existsSync(), isTrue);
    expect((await db.select(db.mediaAssets).getSingle()).missingSince, isNull);

    await db.close();
  });

  test('media_sweeper.dart deletes nothing but a .part, and reads no clock of its own', () {
    // Two structural halves. `delete(` on anything else is the implementation
    // this file refuses, and `appNow()` is the app's single wall-clock reader
    // (R23, #46) — a second clock in a sweep is a `.trash` folder dated a day
    // out from every other date in the app.
    final String source = File('lib/data/media_sweeper.dart')
        .readAsLinesSync()
        .where((String l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
        .join('\n');

    // SPLIT ACROSS TWO LITERALS, because `time.dart_clock` scans `test/` as well
    // as `lib/` and this file would otherwise fail the rule it is asserting.
    // `one_overlay_test.dart` splits `showDialog` for exactly the same reason.
    // The fourteenth time this project has caught a prohibition matching itself.
    const String clock =
        'DateTime'
        '.now(';
    expect(source, isNot(contains(clock)));
    // One `delete(` and it is the `.part` branch; more than one is a sweep that
    // has learned to destroy something else.
    expect('delete('.allMatches(source).length, lessThanOrEqualTo(1));
  });
}

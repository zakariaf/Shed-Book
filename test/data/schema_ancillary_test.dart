// test/data/schema_ancillary_test.dart — the ancillary cluster, the three
// media_assets path CHECKs, and unknown_json.
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:sqlite3/common.dart';

import 'package:shed_book/domain/time/local_date.dart';

import '../support/harness.dart';

/// The tables a backup restores into. Caches and the two singletons are
/// deliberately absent from the RESTORABLE set for different reasons, and both
/// reasons are named.
const Map<String, String> kNotRestorable = <String, String>{
  'ewe_touches': 'a cache — rebuilt, never restored',
  'ewe_summaries': 'a cache — rebuilt wholesale after a restore',
  'search_docs': 'a cache — FTS5, rebuilt from the notes',
  'search_fts': 'a cache — the FTS5 index itself',
  'entitlements': "restoring your neighbour's backup must not unlock your app (#88)",
  'reminder_rules': 'settings-shaped, keyed by kind, no identity of its own',
  'terminology_overrides': 'keyed by the AnimalClass name, no identity of its own',
  'pen_occupancy_lambs': 'a pure join table — its identity is its two parents',
};

Future<int> _mediaWith(AppDatabase db, String path, int ewe) => db
    .into(db.mediaAssets)
    .insert(
      MediaAssetsCompanion.insert(
        uid: newUid(),
        createdAt: appNow(),
        updatedAt: appNow(),
        relativePath: path,
        kind: 'photo',
        byteSize: 1,
        ewe: Value<int?>(ewe),
      ),
    );

Future<int> _ewe(AppDatabase db) => db
    .into(db.ewes)
    .insert(
      EwesCompanion.insert(
        uid: newUid(),
        createdAt: appNow(),
        updatedAt: appNow(),
        tag: '412',
        tagDigits: '412',
      ),
    );

void main() {
  test('media_assets refuses an absolute path and unknown_json exists on '
      'every restorable table', () async {
    final AppDatabase db = testDatabase();
    final int ewe = await _ewe(db);

    // R62's three CHECKs, all of which MUST be here before the v1 snapshot: a
    // CHECK cannot be added by ALTER TABLE afterwards without a full rebuild of
    // the one table that points at the user's photographs.
    await expectLater(_mediaWith(db, '/var/mobile/x.jpg', ewe), throwsA(isA<SqliteException>()));
    await expectLater(_mediaWith(db, 'x.jpg', ewe), throwsA(isA<SqliteException>()));
    await expectLater(
      _mediaWith(db, '2026/03/a/b.jpg', ewe),
      throwsA(isA<SqliteException>()),
      reason: 'never deeper than YYYY/MM/<file>',
    );
    await expectLater(_mediaWith(db, '2026/03/019524f7.jpg', ewe), completes);

    // The unknown_json half, derived from the enumeration rather than hard-coded.
    final Iterable<TableInfo<Table, dynamic>> restorable = db.allTables.where(
      (TableInfo<Table, dynamic> t) => !kNotRestorable.containsKey(t.actualTableName),
    );

    for (final TableInfo<Table, dynamic> t in restorable) {
      expect(
        t.$columns.map((GeneratedColumn<Object> c) => c.name),
        contains('unknown_json'),
        reason: '${t.actualTableName} — an import → export round trip must be lossless',
      );
    }
    expect(restorable, isNotEmpty);
  });

  test('unknown_json refuses text that is not JSON', () async {
    final AppDatabase db = testDatabase();
    final int ewe = await _ewe(db);

    await expectLater(
      (db.update(db.ewes)..where(($EwesTable t) => t.id.equals(ewe))).write(
        const EwesCompanion(unknownJson: Value<String?>('not json')),
      ),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      (db.update(db.ewes)..where(($EwesTable t) => t.id.equals(ewe))).write(
        const EwesCompanion(unknownJson: Value<String?>('{"futureField":1}')),
      ),
      completes,
    );
  });

  test('a vocab term in use cannot be deleted; it is hidden instead', () async {
    // RESTRICT, and it is the whole reason hiddenAt exists. A user-editable
    // vocabulary is a foreign key, never a CHECK (convention 6).
    final AppDatabase db = testDatabase();

    // The seed has already inserted obs_prolapse — which is the realistic case,
    // and is why this reads the seeded row rather than inserting its own.
    final VocabTerm seeded = await (db.select(
      db.vocabTerms,
    )..where(($VocabTermsTable t) => t.key.equals('obs_prolapse'))).getSingle();

    final int season = await db
        .into(db.seasons)
        .insert(
          SeasonsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            year: 2026,
            label: '2026',
            startDate: LocalDate(2026, 3, 1),
          ),
        );
    await db
        .into(db.eweObservations)
        .insert(
          EweObservationsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            ewe: await _ewe(db),
            season: season,
            kind: 'obs_prolapse',
            occurredAt: appNow(),
            capturedAt: appNow(),
          ),
        );

    await expectLater(
      (db.delete(db.vocabTerms)..where(($VocabTermsTable t) => t.id.equals(seeded.id))).go(),
      throwsA(isA<SqliteException>()),
    );
  });

  test('a user-added term must carry a label; a seeded one need not', () async {
    final AppDatabase db = testDatabase();

    Future<int> insert(String origin, {String? label}) => db
        .into(db.vocabTerms)
        .insert(
          VocabTermsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            list: 'death_cause',
            key: 'dc_$origin${label ?? ''}',
            sortOrder: 1,
            origin: origin,
            label: Value<String?>(label),
          ),
        );

    await expectLater(insert('seeded'), completes, reason: 'NULL means "use the shipped default"');
    await expectLater(insert('user'), throwsA(isA<SqliteException>()));
    await expectLater(insert('user', label: 'Fell in the beck'), completes);
  });

  test('app_settings holds exactly one row and no locale column', () async {
    // The seed already wrote row 1, so this asserts the CHECK refuses a SECOND
    // row rather than inserting the first.
    final AppDatabase db = testDatabase();

    await expectLater(
      db.into(db.appSettings).insert(const AppSettingsCompanion(id: Value<int>(2))),
      throwsA(isA<SqliteException>()),
    );

    final Set<String> columns = db.appSettings.$columns
        .map((GeneratedColumn<Object> c) => c.name)
        .toSet();
    for (final String absent in <String>[
      'locale',
      'date_format',
      'first_day_of_week',
      'temperature_unit',
    ]) {
      expect(columns, isNot(contains(absent)), reason: absent);
    }
    expect((await db.select(db.appSettings).getSingle()).palette, 'night');
  });

  test('reminders carry no os_notification_id', () async {
    // Decision #63: the OS projection is a rebuildable cache produced by
    // cancelAll() + rebuild. A stored OS id would be a second source of truth
    // that goes stale on every reconcile.
    final AppDatabase db = testDatabase();

    expect(
      db.reminders.$columns.map((GeneratedColumn<Object> c) => c.name),
      isNot(contains('os_notification_id')),
    );
  });

  test('a foster to a ewe needs a rearing dam, and to a bottle must not have one', () async {
    // Bottle (null by intent) and unknown (null by omission) are different facts
    // and the rearing-credit numbers differ.
    final AppDatabase db = testDatabase();
    final int ewe = await _ewe(db);
    final int season = await db
        .into(db.seasons)
        .insert(
          SeasonsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            year: 2026,
            label: '2026',
            startDate: LocalDate(2026, 3, 1),
          ),
        );
    final int lambing = await db
        .into(db.lambings)
        .insert(
          LambingsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            season: season,
            ewe: ewe,
            occurredAt: appNow(),
            capturedAt: appNow(),
            localDate: LocalDate(2026, 3, 4),
          ),
        );
    final int lamb = await db
        .into(db.lambs)
        .insert(
          LambsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            lambing: lambing,
            birthDam: ewe,
          ),
        );

    Future<int> foster(String outcome, {int? dam}) => db
        .into(db.fosterEvents)
        .insert(
          FosterEventsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            lamb: lamb,
            season: season,
            outcome: outcome,
            rearingDam: Value<int?>(dam),
            effectiveAt: appNow(),
            capturedAt: appNow(),
          ),
        );

    await expectLater(foster('to_ewe'), throwsA(isA<SqliteException>()));
    await expectLater(foster('to_bottle', dam: ewe), throwsA(isA<SqliteException>()));
    await expectLater(foster('to_bottle'), completes);
    await expectLater(foster('to_ewe', dam: ewe), completes);
  });
}

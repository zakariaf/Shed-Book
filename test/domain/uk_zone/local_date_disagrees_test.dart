// test/domain/uk_zone/local_date_disagrees_test.dart — the warning column that
// exists so §12.4 does not have to be trusted.
//
// `lambings.local_date` is the civil date **stored at write time** — the day as
// it was lived. Re-deriving it from the same instant in the export-time zone can
// give a different day, and that is not a bug in either value: the shepherd was
// in one zone and the phone is now in another, or the clocks changed underneath
// them.
//
// **BOTH VALUES ARE PRINTED AND NEITHER IS CORRECTED.** `local_date_disagrees`
// is `WarningCode.localDateDisagrees` as a column, and it is the whole mechanism:
// the alternative — silently re-deriving the date at export — is §12.4 in its
// plainest form, on a file the shepherd may already have printed.
//
// Tagged `uk-zone` because the assertions are absolute wall-clock values.
@Tags(<String>['uk-zone'])
library;

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/csv_writer.dart';
import 'package:shed_book/data/export_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/policy/export_envelope.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';

import '../../support/harness.dart';
import '../../support/seeds.dart';
import '../../features/csv_writer_test.dart' show parseRfc4180;

void main() {
  late AppDatabase db;
  late ExportRepository repo;
  late SeasonId season;

  CsvWriter writer() => CsvWriter(
    ExportEnvelope.standard(
      now: Instant.fromDateTime(DateTime.utc(2026, 4, 1, 9)),
      appVersion: '1.0.0',
    ),
    localZoneLabel: 'BST (UTC+01:00)',
  );

  setUp(() async {
    db = testDatabase();
    repo = ExportRepository(db);
    season = await seedSeason(db);
  });

  Future<List<String>> exportOneLamb({
    required Instant bornAt,
    required LocalDate storedDate,
  }) async {
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe, occurredAt: bornAt);
    await (db.update(db.lambings)..where(($LambingsTable t) => t.id.equals(lambing.value))).write(
      LambingsCompanion(localDate: Value<LocalDate>(storedDate)),
    );
    await seedLamb(db, lambing, ewe);

    final List<List<String>> records = parseRfc4180(
      utf8.decode(
        (await repo.writeLambsCsv(
          season: season,
          writer: writer(),
          vocabLabels: const <String, String>{},
        )).sublist(3),
      ),
    );
    return records[1];
  }

  test('a stored civil date that matches the export-time zone does not warn', () async {
    // 14 March 2026, 03:20 UTC — 03:20 GMT locally, and the stored day is the
    // day it was lived.
    final Instant born = Instant.fromDateTime(DateTime.utc(2026, 3, 14, 3, 20));
    final List<String> row = await exportOneLamb(bornAt: born, storedDate: LocalDate(2026, 3, 14));

    final int disagrees = ExportRepository.lambsHeader.indexOf('local_date_disagrees');
    expect(row[disagrees], '0');
  });

  test(
    'a lambing recorded just before local midnight in another zone warns, and keeps both',
    () async {
      // The shepherd was somewhere UTC+13 when they recorded it: 23:30 on the 14th
      // where they stood, which is 10:30 UTC and still the 14th in London — but
      // the same clock crossing in the other direction is what this column exists
      // for, so the case pins an instant whose UK civil day is the 15th while the
      // stored day is the 14th.
      final Instant born = Instant.fromDateTime(DateTime.utc(2026, 3, 15, 2, 0));
      final List<String> row = await exportOneLamb(
        bornAt: born,
        storedDate: LocalDate(2026, 3, 14),
      );

      final int disagrees = ExportRepository.lambsHeader.indexOf('local_date_disagrees');
      final int stored = ExportRepository.lambsHeader.indexOf('born_local_date');
      final int utc = ExportRepository.lambsHeader.indexOf('born_at_utc');

      expect(row[disagrees], '1');

      // AND THE STORED DATE IS STILL THE STORED ONE. This is the assertion that
      // catches a "helpful" export that re-derives the day — the warning column
      // would then read `0` for ever and nobody would know the two disagreed.
      expect(row[stored], '2026-03-14');
      expect(row[utc], '2026-03-15T02:00:00.000Z');
      expect(LocalDate.of(born).iso, '2026-03-15', reason: 'the export-time zone says the 15th');
    },
  );
}

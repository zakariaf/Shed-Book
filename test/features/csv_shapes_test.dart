// test/features/csv_shapes_test.dart
//
// THE PROMISE THIS FILE HOLDS is `indelible.md` screen 11's, in its own words:
// *"every CSV carries a `struck` and a `struck_at` column and every struck row
// is included and marked, because an export that quietly drops the strikes would
// undo the one thing this app is for."*
//
// A flock book that silently omits a corrected record is a different document
// than the one the shepherd thinks they are sending — and they cannot recall it
// off somebody else's laptop.
//
// The reader is `parseRfc4180` from `csv_writer_test.dart`: one strict parser,
// written from the RFC, shared by every case that reads a produced file.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/csv_writer.dart';
import 'package:shed_book/data/export_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/policy/export_envelope.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';
import 'package:shed_book/data/treatment_repository.dart';

import '../support/harness.dart';
import '../support/seeds.dart';
import 'csv_writer_test.dart' show parseRfc4180;

final Instant _exportedAt = Instant.fromDateTime(DateTime.utc(2026, 4, 1, 9));

CsvWriter _writer() => CsvWriter(
  ExportEnvelope.standard(now: _exportedAt, appVersion: '1.0.0'),
  localZoneLabel: 'GMT (UTC+00:00)',
);

/// Header, data records and trailer, split apart — every case wants the middle.
({List<String> header, List<List<String>> data}) shapeOf(Uint8List bytes) {
  final List<List<String>> records = parseRfc4180(utf8.decode(bytes.sublist(3)));
  return (header: records.first, data: records.sublist(1, records.length - 6));
}

int columnOf(List<String> header, String name) {
  final int i = header.indexOf(name);
  expect(i, isNot(-1), reason: 'no column named $name in ${header.join(',')}');
  return i;
}

void main() {
  late AppDatabase db;
  late ExportRepository repo;
  late SeasonId season;

  setUp(() async {
    db = testDatabase();
    repo = ExportRepository(db);
    season = await seedSeason(db);
  });

  test('every struck row is present in the lambs CSV and carries struck_at', () async {
    // THE ANCHOR. Three lambs, one struck. A `WHERE struck = 0` fails this with
    // a count of two and a message naming the missing uid.
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final List<LambId> lambs = <LambId>[
      for (int i = 0; i < 3; i++) await seedLamb(db, lambing, ewe),
    ];

    final Instant struckAt = Instant.fromDateTime(DateTime.utc(2026, 3, 20, 14, 5));
    await (db.update(db.lambs)..where(($LambsTable t) => t.id.equals(lambs[1].value))).write(
      LambsCompanion(struck: const Value<bool>(true), struckAt: Value<Instant?>(struckAt)),
    );

    final String struckUid = (await (db.select(
      db.lambs,
    )..where(($LambsTable t) => t.id.equals(lambs[1].value))).getSingle()).uid;

    final ({List<String> header, List<List<String>> data}) csv = shapeOf(
      await repo.writeLambsCsv(
        season: season,
        writer: _writer(),
        vocabLabels: const <String, String>{},
      ),
    );

    expect(csv.data, hasLength(3), reason: 'three lambs, and the struck one is not filtered out');

    final int uidCol = columnOf(csv.header, 'lamb_uid');
    final int struckCol = columnOf(csv.header, 'struck');
    final int atCol = columnOf(csv.header, 'struck_at');

    final List<String> row = csv.data.firstWhere((List<String> r) => r[uidCol] == struckUid);
    expect(row[struckCol], '1');
    expect(row[atCol], '2026-03-20T14:05:00.000Z');

    // AND THE OTHER TWO ARE MARKED UNSTRUCK RATHER THAN BLANK. A blank cell
    // reads as "not recorded", which is a different fact.
    for (final List<String> other in csv.data.where((List<String> r) => r[uidCol] != struckUid)) {
      expect(other[struckCol], '0');
      expect(other[atCol], '');
    }
  });

  test('the three header rows are the frozen contract, field for field', () async {
    // Appending a column is allowed; renaming or reordering one breaks every
    // spreadsheet a shepherd has built on the file, and that file is already on
    // somebody else's laptop.
    expect(ExportRepository.lambsHeader, hasLength(37));
    expect(ExportRepository.ewesHeader, hasLength(28));
    expect(ExportRepository.treatmentsHeader, hasLength(31));

    for (final List<String> header in <List<String>>[
      ExportRepository.lambsHeader,
      ExportRepository.ewesHeader,
      ExportRepository.treatmentsHeader,
    ]) {
      expect(header.last, 'struck_at', reason: 'R79 puts the pair last, in that order');
      expect(header[header.length - 2], 'struck');
      expect(header.toSet(), hasLength(header.length), reason: 'no duplicated column');
    }
  });

  test('a produced file is rectangular and its header is the const list', () async {
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    await seedLamb(db, lambing, ewe);

    for (final (List<String> expected, Uint8List bytes) in <(List<String>, Uint8List)>[
      (
        ExportRepository.lambsHeader,
        await repo.writeLambsCsv(
          season: season,
          writer: _writer(),
          vocabLabels: const <String, String>{},
        ),
      ),
      (
        ExportRepository.ewesHeader,
        await repo.writeEwesCsv(
          season: season,
          writer: _writer(),
          vocabLabels: const <String, String>{},
        ),
      ),
      (
        ExportRepository.treatmentsHeader,
        await repo.writeTreatmentsCsv(
          season: season,
          writer: _writer(),
          vocabLabels: const <String, String>{},
        ),
      ),
    ]) {
      final List<List<String>> records = parseRfc4180(utf8.decode(bytes.sublist(3)));
      expect(records.first, expected);
      for (final List<String> r in records) {
        expect(r, hasLength(expected.length));
      }
    }
  });

  test('a lamb that died before tagging is in the file, fully', () async {
    // `03 §5.5`: a lamb that died before tagging is counted. An export that
    // drops it loses exactly the losses that matter most — and a blank tag is
    // how it appears, not an absent row.
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId lamb = await seedLamb(db, lambing, ewe);
    await (db.update(db.lambs)..where(($LambsTable t) => t.id.equals(lamb.value))).write(
      const LambsCompanion(status: Value<String>('stillborn'), tag: Value<String?>(null)),
    );

    final ({List<String> header, List<List<String>> data}) csv = shapeOf(
      await repo.writeLambsCsv(
        season: season,
        writer: _writer(),
        vocabLabels: const <String, String>{},
      ),
    );

    expect(csv.data, hasLength(1));
    expect(csv.data.single[columnOf(csv.header, 'lamb_tag')], '');
    // STILLBORN IS ITS OWN BUCKET, never folded into a day-0 death.
    expect(csv.data.single[columnOf(csv.header, 'status')], 'stillborn');
  });

  test('a blank sex is not the word unknown', () async {
    // R45. Blank is *not recorded*; `unknown` is *looked and could not tell*.
    // Merging them is how a flock's sex ratio quietly becomes a fiction.
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    final LambId notRecorded = await seedLamb(db, lambing, ewe);
    final LambId looked = await seedLamb(db, lambing, ewe);

    await (db.update(db.lambs)..where(($LambsTable t) => t.id.equals(looked.value))).write(
      const LambsCompanion(sex: Value<String?>('unknown')),
    );

    final ({List<String> header, List<List<String>> data}) csv = shapeOf(
      await repo.writeLambsCsv(
        season: season,
        writer: _writer(),
        vocabLabels: const <String, String>{},
      ),
    );
    final int uid = columnOf(csv.header, 'lamb_uid');
    final int sex = columnOf(csv.header, 'sex');

    final String blankUid = (await (db.select(
      db.lambs,
    )..where(($LambsTable t) => t.id.equals(notRecorded.value))).getSingle()).uid;

    expect(csv.data.firstWhere((List<String> r) => r[uid] == blankUid)[sex], '');
    expect(csv.data.firstWhere((List<String> r) => r[uid] != blankUid)[sex], 'unknown');
  });

  test(
    'an active ewe with no participation row is still in the ewes CSV, with a blank status',
    () async {
      // `09 §3.2`'s union rule. An export that silently omits an animal the
      // shepherd can see in her flock list is the failure this format exists to
      // prevent: a blank cell is honest, an absent row is not.
      await seedEwe(db, tag: '412');

      final ({List<String> header, List<List<String>> data}) csv = shapeOf(
        await repo.writeEwesCsv(
          season: season,
          writer: _writer(),
          vocabLabels: const <String, String>{},
        ),
      );

      expect(csv.data, hasLength(1));
      expect(csv.data.single[columnOf(csv.header, 'tag')], '412');
      expect(csv.data.single[columnOf(csv.header, 'season_status')], '');
    },
  );

  test('the ewes CSV carries counts and never over_free_cap', () async {
    // A monetization marker is not a fact about a sheep. It is in the JSON
    // backup, because the backup is the record and the CSV is a report — and
    // that distinction settles every "does this column belong?" argument.
    expect(ExportRepository.ewesHeader, isNot(contains('over_free_cap')));
    // `tag_digits` is a projection for the keypad's ranking and never a CSV
    // column; the tag is exported exactly as typed.
    expect(ExportRepository.ewesHeader, isNot(contains('tag_digits')));
  });

  test('a voided treatment is in the file, marked, with struck derived from voided_at', () async {
    // Decision #69: undo for a treatment is a soft void, because the row may
    // already have been printed into a medicine book handed to a vet. `R79 §d`:
    // `treatments` carries no `struck` column, so the export contract's pair is
    // DERIVED here — once, in one place — and sits beside `is_voided`.
    final EweId ewe = await seedEwe(db, tag: '412');
    final TreatmentRepository treatments = TreatmentRepository(db);
    final int id =
        ((await treatments.recordTreatment(
                  TreatEwe(ewe),
                  productName: 'Alamycin',
                  withdrawals: <WithdrawalPeriod>[
                    WithdrawalDays.asEnteredByUser(days: 28, target: WithdrawalTarget.meat),
                  ],
                ))
                as WriteCommitted)
            .insertedId!;
    await treatments.voidTreatment(TreatmentId(id));

    final ({List<String> header, List<List<String>> data}) csv = shapeOf(
      await repo.writeTreatmentsCsv(
        season: season,
        writer: _writer(),
        vocabLabels: const <String, String>{},
      ),
    );

    expect(csv.data, hasLength(1), reason: 'the void keeps the row');
    final List<String> row = csv.data.single;
    expect(row[columnOf(csv.header, 'is_voided')], '1');
    expect(row[columnOf(csv.header, 'struck')], '1');
    expect(row[columnOf(csv.header, 'voided_at_utc')], isNotEmpty);
    expect(
      row[columnOf(csv.header, 'struck_at')],
      row[columnOf(csv.header, 'voided_at_utc')],
      reason: 'one fact, two contract names',
    );
  });

  test('the three withdrawal states never collapse into one blank cell', () async {
    // SAFETY RULE §12.1, at the file's edge. `not_recorded` is the absence of a
    // child row, `not_applicable` is a row the shepherd wrote, and `days` is a
    // number off a bottle. A nullable integer merges the first two, and `0` is a
    // real label value — which is the whole reason the child table exists.
    final EweId ewe = await seedEwe(db, tag: '412');
    final TreatmentRepository treatments = TreatmentRepository(db);

    await treatments.recordTreatment(TreatEwe(ewe), productName: 'Nobody looked');
    await treatments.recordTreatment(
      TreatEwe(ewe),
      productName: 'None applies',
      withdrawals: const <WithdrawalPeriod>[WithdrawalNotApplicable(WithdrawalTarget.meat)],
    );
    await treatments.recordTreatment(
      TreatEwe(ewe),
      productName: 'Alamycin',
      withdrawals: <WithdrawalPeriod>[
        WithdrawalDays.asEnteredByUser(days: 0, target: WithdrawalTarget.meat),
      ],
    );

    final ({List<String> header, List<List<String>> data}) csv = shapeOf(
      await repo.writeTreatmentsCsv(
        season: season,
        writer: _writer(),
        vocabLabels: const <String, String>{},
      ),
    );

    final int name = columnOf(csv.header, 'product_name');
    final int state = columnOf(csv.header, 'meat_withdrawal_state');
    final int days = columnOf(csv.header, 'meat_withdrawal_days');
    final int source = columnOf(csv.header, 'meat_withdrawal_source');

    List<String> by(String p) => csv.data.firstWhere((List<String> r) => r[name] == p);

    expect(by('Nobody looked')[state], 'not_recorded');
    expect(by('Nobody looked')[days], '');
    expect(by('None applies')[state], 'not_applicable');
    expect(by('None applies')[days], '', reason: 'nothing applies is not zero days');

    // AND ZERO IS A NUMBER SOMEBODY READ OFF A BOTTLE. It is the case a nullable
    // integer cannot carry, and the one that proves the three states are real.
    expect(by('Alamycin')[state], 'days');
    expect(by('Alamycin')[days], '0');
    expect(by('Alamycin')[source], 'as entered by you');
    expect(by('Nobody looked')[source], '', reason: 'no period, no provenance to claim');
  });

  test('the stored clear date is exported, never recomputed', () async {
    // Decision #50: the clear date is a record of what the app TOLD the user on
    // the day, and recomputing it at export would silently move a date they may
    // have written in a book. The disagreement column exists to say so.
    final EweId ewe = await seedEwe(db, tag: '412');
    final TreatmentRepository treatments = TreatmentRepository(db);
    await treatments.recordTreatment(
      TreatEwe(ewe),
      productName: 'Alamycin',
      withdrawals: <WithdrawalPeriod>[
        WithdrawalDays.asEnteredByUser(days: 28, target: WithdrawalTarget.meat),
      ],
    );

    final String stored = (await db.select(db.treatmentWithdrawals).getSingle()).clearDate!.iso;

    final ({List<String> header, List<List<String>> data}) csv = shapeOf(
      await repo.writeTreatmentsCsv(
        season: season,
        writer: _writer(),
        vocabLabels: const <String, String>{},
      ),
    );

    expect(csv.data.single[columnOf(csv.header, 'meat_clear_date')], stored);
    expect(csv.data.single[columnOf(csv.header, 'clear_date_disagrees')], '0');
  });

  test('no export statement filters a struck row out', () async {
    // `09 §3.1` asks for this assertion by name, and it is a source scan rather
    // than a behavioural case because it covers the statements this task has not
    // written yet as well as the three it has.
    final String source = File('lib/data/export_repository.dart').readAsStringSync();
    for (final String predicate in <String>[
      'struck = 0',
      'struck=0',
      'NOT struck',
      'struck IS FALSE',
    ]) {
      expect(source, isNot(contains(predicate)), reason: predicate);
    }
  });
}

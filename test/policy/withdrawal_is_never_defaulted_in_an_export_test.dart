// test/policy/withdrawal_is_never_defaulted_in_an_export_test.dart
//
// `09 §6.4`'s third test, and it belongs beside the trailer rather than beside
// the shapes because it is a §12.1 property of **the provenance columns and the
// caveat**, not of the column list.
//
// The claim: an export can carry a withdrawal number, and when it does it says
// where the number came from. It may never carry one that the app originated,
// and it may never turn *nobody looked* into a zero on the way out.
@Tags(<String>['policy'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/csv_writer.dart';
import 'package:shed_book/data/export_repository.dart';
import 'package:shed_book/data/treatment_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/domain/policy/export_envelope.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';

import '../support/harness.dart';
import '../support/seeds.dart';
import '../features/csv_writer_test.dart' show parseRfc4180;

CsvWriter _writer() => CsvWriter(
  ExportEnvelope.standard(
    now: Instant.fromDateTime(DateTime.utc(2026, 4, 1, 9)),
    appVersion: '1.0.0',
  ),
  localZoneLabel: 'GMT (UTC+00:00)',
);

void main() {
  test('no export writes a withdrawal number the shepherd did not enter', () async {
    final AppDatabase db = testDatabase();
    final SeasonId season = await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final TreatmentRepository treatments = TreatmentRepository(db);

    // A treatment with NO withdrawal at all — the case a default would fill in.
    final int id =
        ((await treatments.recordTreatment(TreatEwe(ewe), productName: 'Alamycin'))
                as WriteCommitted)
            .insertedId!;
    expect(id, isPositive);

    final List<List<String>> records = parseRfc4180(
      utf8.decode(
        (await ExportRepository(db).writeTreatmentsCsv(
          season: season,
          writer: _writer(),
          vocabLabels: const <String, String>{},
        )).sublist(3),
      ),
    );
    final List<String> row = records[1];
    final List<String> header = ExportRepository.treatmentsHeader;

    for (final String target in <String>['meat', 'milk']) {
      // THE STATE IS SAID OUT LOUD. Absence is a value with a name, not an empty
      // cell somebody has to interpret.
      expect(row[header.indexOf('${target}_withdrawal_state')], 'not_recorded');
      // AND THE NUMBER IS BLANK, NEVER `0`. `0` is a real label value, so a zero
      // here would be the app answering a clinical question nobody asked it.
      expect(row[header.indexOf('${target}_withdrawal_days')], '');
      expect(row[header.indexOf('${target}_clear_date')], '');
      // AND NOTHING CLAIMS A PROVENANCE FOR A NUMBER THAT DOES NOT EXIST.
      expect(row[header.indexOf('${target}_withdrawal_source')], '');
    }

    await db.close();
  });

  test('an entered withdrawal carries its provenance, referenced never re-typed', () async {
    final AppDatabase db = testDatabase();
    final SeasonId season = await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');

    await TreatmentRepository(db).recordTreatment(
      TreatEwe(ewe),
      productName: 'Alamycin',
      withdrawals: <WithdrawalPeriod>[
        WithdrawalDays.asEnteredByUser(days: 28, target: WithdrawalTarget.meat),
      ],
    );

    final List<List<String>> records = parseRfc4180(
      utf8.decode(
        (await ExportRepository(db).writeTreatmentsCsv(
          season: season,
          writer: _writer(),
          vocabLabels: const <String, String>{},
        )).sublist(3),
      ),
    );
    final List<String> header = ExportRepository.treatmentsHeader;

    expect(records[1][header.indexOf('meat_withdrawal_days')], '28');
    // THE FOUR WORDS TRAVEL WITH THE NUMBER, and they are the constant rather
    // than a copy of its text.
    expect(records[1][header.indexOf('meat_withdrawal_source')], Disclaimers.withdrawalProvenance);

    await db.close();
  });

  test('no export writer contains a literal day count beside a withdrawal word', () async {
    // The structural half, and the reason it is a scan: the two cases above
    // exercise the two states that exist today, and a default added tomorrow —
    // `days ?? 28`, `withdrawalDays: 7` — would pass both while shipping a
    // number the app originated.
    for (final String path in <String>[
      'lib/data/csv_writer.dart',
      'lib/data/export_repository.dart',
    ]) {
      final String source = File(path).readAsStringSync();
      expect(
        RegExp(r'withdrawal[A-Za-z_]*\s*[:=]\s*\d').hasMatch(source),
        isFalse,
        reason: '$path assigns a literal number to something withdrawal-shaped',
      );
      expect(
        RegExp(r'\bdays\s*\?\?\s*\d').hasMatch(source),
        isFalse,
        reason: '$path defaults a day count',
      );
    }
  });
}

// test/policy/every_export_carries_the_footer_test.dart
//
// `09 §6.4`'s second test: **every artefact × {seeded database, empty
// database}.**
//
// The empty half is the one that matters and it is the one a hand-written check
// forgets. `07 §13.2`: *"a 0-row CSV still carries its disclaimer trailer."* An
// export of nothing is still an export — and it is the one a shepherd is most
// likely to send to somebody while asking why it is empty, which is exactly when
// the file needs to say what it is and what it is not.
//
// A separate file from `disclaimer_is_defined_once_test.dart` (N06-T09) and from
// `disclaimer_is_referenced_test.dart`, and NOT a fork of either: `12 §11.1`
// names a policy test for its property, and these are three properties that fail
// for three different reasons — *the string exists once*, *nobody re-typed it*,
// and *every artefact carries it*.
@Tags(<String>['policy'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/csv_writer.dart';
import 'package:shed_book/data/export_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/domain/policy/export_envelope.dart';
import 'package:shed_book/domain/time/instant.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

typedef Artefact = ({
  String name,
  Future<List<int>> Function(ExportRepository repo, SeasonId season, CsvWriter w) build,
});

/// Five artefacts in `09 §6.3`'s matrix; three exist. **The list is written to
/// grow**: the two PDFs are `v1.1.0`'s (P15) and N22 adds the backup, and each
/// joins by adding a row here rather than by writing a fourth test.
const List<Artefact> artefacts = <Artefact>[
  (name: 'lambs.csv', build: _lambs),
  (name: 'ewes.csv', build: _ewes),
  (name: 'treatments.csv', build: _treatments),
];

Future<List<int>> _lambs(ExportRepository r, SeasonId s, CsvWriter w) =>
    r.writeLambsCsv(season: s, writer: w, vocabLabels: const <String, String>{});
Future<List<int>> _ewes(ExportRepository r, SeasonId s, CsvWriter w) =>
    r.writeEwesCsv(season: s, writer: w, vocabLabels: const <String, String>{});
Future<List<int>> _treatments(ExportRepository r, SeasonId s, CsvWriter w) =>
    r.writeTreatmentsCsv(season: s, writer: w, vocabLabels: const <String, String>{});

void main() {
  for (final Artefact a in artefacts) {
    for (final bool seeded in <bool>[true, false]) {
      test(
        '${a.name} carries the §12.3, §12.1 and R79 disclosures — ${seeded ? 'seeded' : 'empty'}',
        () async {
          final AppDatabase db = testDatabase();
          final SeasonId season = await seedSeason(db);

          if (seeded) {
            final EweId ewe = await seedEwe(db, tag: '412');
            final LambingId lambing = await seedLambing(db, ewe);
            await seedLamb(db, lambing, ewe);
          }

          final String body = utf8.decode(
            (await a.build(
              ExportRepository(db),
              season,
              CsvWriter(
                ExportEnvelope.standard(
                  now: Instant.fromDateTime(DateTime.utc(2026, 4, 1, 9)),
                  appVersion: '1.0.0',
                ),
                localZoneLabel: 'GMT (UTC+00:00)',
              ),
            )).sublist(3),
          );

          // ASSERTED AGAINST THE CONSTANTS, never against a copy of their text. A
          // test that hard-codes the literal still passes after somebody edits the
          // constant, which is the one failure this whole family exists to catch.
          expect(body, contains(Disclaimers.exportFooter), reason: '§12.3');
          expect(body, contains(Disclaimers.withdrawalCaveat), reason: '§12.1');
          expect(body, contains(Disclaimers.strikeNotice), reason: 'R79, screen 11');

          await db.close();
        },
      );
    }
  }
}

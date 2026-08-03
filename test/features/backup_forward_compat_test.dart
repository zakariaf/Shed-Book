// test/features/backup_forward_compat_test.dart
//
// THE CONTRACT THAT MAKES A BACKUP SURVIVE THE APP THAT WROTE IT.
//
// A shepherd who installs `v1.1.0` on a new phone and restores a `v1.0.0` file
// must lose nothing — and, harder, a shepherd who goes the other way must lose
// nothing either. A column this build has never heard of rides through in
// `unknown_json` and comes back out at the row's top level, unchanged.
//
// **AND A FILE THIS BUILD CANNOT READ IS REFUSED, NOT GUESSED AT.** Guessing at a
// newer schema is §12.4 applied to restore, and a partial import destroys
// records rather than declining to touch them.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/backup_format.dart';

void main() {
  test('an unknown column survives into unknown_json and is re-emitted at the row top level', () {
    // THE ANCHOR. A row from a build that knows about tupping rams, read by a
    // build that does not.
    const Set<String> known = <String>{'uid', 'tag', 'created_at', 'updated_at'};
    final Map<String, Object?> incoming = <String, Object?>{
      'uid': 'a',
      'tag': '412',
      'created_at': 1,
      'tupping_ram_tag': 'R7',
      'updated_at': 2,
    };

    final ({Map<String, Object?> row, String? unknownJson}) captured = captureUnknownColumns(
      incoming,
      known,
    );

    // ONE — the container holds exactly the unknown key, as a JSON **object**.
    // Not a bare string and not an array: the column's
    // `CHECK (unknown_json IS NULL OR json_valid(unknown_json))` would throw
    // from the importer, at the one moment nothing may throw.
    expect(captured.unknownJson, '{"tupping_ram_tag":"R7"}');
    expect(captured.row.containsKey('tupping_ram_tag'), isFalse);

    // TWO — the next export puts it back at the TOP LEVEL, sorted into place
    // rather than appended.
    final Map<String, Object?> stored = <String, Object?>{
      'uid': 'a',
      'tag': '412',
      'created_at': 1,
      'updated_at': 2,
      'unknown_json': captured.unknownJson,
    };
    final String out = utf8.decode(canonicalJsonBytes(splatUnknownJson(stored)));

    expect(
      out.indexOf('"tupping_ram_tag"'),
      allOf(greaterThan(out.indexOf('"tag"')), lessThan(out.indexOf('"updated_at"'))),
      reason: 'sorted into place, not appended',
    );

    // THREE — the container is never emitted under its own name. Emitting it as
    // well writes every preserved field twice, and the next export nests it
    // again, one level deeper each time.
    expect(out.contains('unknown_json'), isFalse);
  });

  test('the splat happens before the sort, and only byte equality shows it', () {
    // THE SINGLE EASIEST THING TO GET WRONG HERE. Merging after the sort
    // produces a file that decodes correctly, reads correctly and looks right in
    // `jq` — and whose key order is wrong, so the second export is not
    // byte-identical to the first.
    final Map<String, Object?> stored = <String, Object?>{
      'uid': 'a',
      'zzz': 1,
      'unknown_json': '{"aaa":2}',
    };

    final String out = utf8.decode(canonicalJsonBytes(splatUnknownJson(stored)));
    expect(out.indexOf('"aaa"'), lessThan(out.indexOf('"uid"')));

    expect(
      canonicalJsonBytes(splatUnknownJson(stored)),
      orderedEquals(canonicalJsonBytes(splatUnknownJson(stored))),
    );
  });

  test('a row with nothing unknown carries NULL, never an empty object', () {
    // `'{}'` and `NULL` are different bytes on the next export, so a writer that
    // helpfully stores an empty object breaks byte equality for every row that
    // has nothing to preserve — which is almost all of them.
    final ({Map<String, Object?> row, String? unknownJson}) captured = captureUnknownColumns(
      <String, Object?>{'uid': 'a'},
      <String>{'uid'},
    );
    expect(captured.unknownJson, isNull);
  });

  test('a preserved key that collides with a live column loses to the column', () {
    // In theory impossible — if the column exists today the key is not unknown.
    // In practice it happens the moment somebody hand-edits a backup, or a
    // column is added and an older file is replayed through a build that has
    // since gained it. **Decided in code rather than by map-merge order**, which
    // would settle it silently and differently depending on which way the merge
    // was written.
    final Map<String, Object?> stored = <String, Object?>{
      'uid': 'a',
      'tag': '412',
      'unknown_json': '{"tag":"WRONG"}',
    };

    expect(splatUnknownJson(stored)['tag'], '412');
  });

  test('a preserved value is passed through and never re-parsed', () {
    // A preserved key whose value looks like an instant is a **string** to this
    // build. The build that wrote it knows what it means; this one does not, and
    // carrying it without interpreting it is the entire point of the container.
    final Map<String, Object?> splatted = splatUnknownJson(<String, Object?>{
      'uid': 'a',
      'unknown_json': '{"scanned_at":"2026-03-14T03:20:00.000Z","litter":3,"flag":true}',
    });

    expect(splatted['scanned_at'], '2026-03-14T03:20:00.000Z');
    expect(splatted['scanned_at'], isA<String>());
    expect(splatted['litter'], 3);
    expect(splatted['flag'], isTrue);
  });

  test('a file from a newer app is refused, not guessed at', () {
    // `09 §5.5`. **Do not soften this to "may not be compatible":** guessing at a
    // newer schema is §12.4 applied to restore, and a partial import destroys
    // records rather than declining to touch them.
    final BackupHeaderOutcome newerFormat = readBackupHeader(<String, Object?>{
      'format': kBackupFormat,
      'formatVersion': kBackupFormatVersion + 1,
      'schema': 1,
    });
    expect(newerFormat, isA<BackupRefused>());
    expect((newerFormat as BackupRefused).reason, BackupRefusalReason.newerFormatVersion);
    expect(newerFormat.foundFormatVersion, kBackupFormatVersion + 1);
    expect(newerFormat.readsFormatVersion, kBackupFormatVersion);

    final BackupHeaderOutcome newerSchema = readBackupHeader(<String, Object?>{
      'format': kBackupFormat,
      'formatVersion': kBackupFormatVersion,
      'schema': kSchemaVersion + 1,
    });
    expect((newerSchema as BackupRefused).reason, BackupRefusalReason.newerSchema);
    expect(newerSchema.foundSchema, kSchemaVersion + 1);
  });

  test('a file that is not ours, and a file with a missing key, are told apart', () {
    // Two different sentences for two different problems: *this is not a Shed
    // Book backup* and *this is one and it is damaged* send a shepherd to two
    // different next steps.
    expect(
      (readBackupHeader(<String, Object?>{'format': 'something-else'}) as BackupRefused).reason,
      BackupRefusalReason.notShedBookFormat,
    );
    expect(
      (readBackupHeader(<String, Object?>{}) as BackupRefused).reason,
      BackupRefusalReason.notShedBookFormat,
    );
    expect(
      (readBackupHeader(<String, Object?>{
                'format': kBackupFormat,
                'formatVersion': kBackupFormatVersion,
              })
              as BackupRefused)
          .reason,
      BackupRefusalReason.malformedHeader,
      reason: 'ours, and damaged',
    );
  });

  test('an older or equal file is accepted', () {
    // The whole point of the version fields: the app reads down, never up.
    final BackupHeaderOutcome outcome = readBackupHeader(<String, Object?>{
      'format': kBackupFormat,
      'formatVersion': kBackupFormatVersion,
      'schema': kSchemaVersion,
    });
    expect(outcome, isA<BackupHeaderAccepted>());
  });

  test('a refusal is a value, not an exception', () {
    // `01 §5`: a refusal is something the restore screen renders. An exception
    // escaping into the UI is the failure mode the sealed outcome exists to
    // prevent — and `ShedFailure` is not the type for it either: that is for a
    // database the app could not read, and this is a file it read perfectly well.
    expect(() => readBackupHeader(<String, Object?>{'format': 42}), returnsNormally);
  });
}

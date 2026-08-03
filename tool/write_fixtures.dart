// tool/write_fixtures.dart — regenerating the two committed fixtures.
//
// **A FIXTURE NOBODY CAN REGENERATE IS A BINARY BLOB WITH A `.json` EXTENSION.**
// The first two versions of `test/fixtures/*.json` were written by an ad-hoc
// script that was never committed, so the only way to change the flock was to
// reconstruct that script from the generator — and the generator changed three
// times in one day. This file is that script, kept.
//
//   dart run tool/write_fixtures.dart
//
// **IT WRITES THROUGH `headerPrefixJson`, NOT ALONGSIDE IT.** The bytes come out
// of the same function `writeBackup` uses, in the same order, with the checksum
// over the same canonical `tables` encoding. A fixture assembled by a second
// hand-written encoder would prove the *reader* consistent with that encoder
// rather than with the app, which is the one thing a fixture must never do.
//
// Deterministic by construction: every uid is derived from the seed and
// `seedEnvelope()` pins the instant, so running it twice produces two identical
// files and a diff under `test/fixtures/` is always a real change to the flock.
//
// Unlike `tool/seed.dart` this opens no database and imports no Flutter, so it
// runs under plain `dart run` — the `LocalLog` → `foundation` → `dart:ui` chain
// that blocks the seed script does not reach here.
library;

import 'dart:convert';
import 'dart:io';

import 'package:shed_book/core/db/database.dart' show kSchemaVersion;
import 'package:shed_book/data/backup_format.dart';
import 'package:shed_book/domain/policy/export_envelope.dart';

import 'flock_generator.dart';

/// The two fixtures and the shapes they exist to carry.
///
/// `12 §11.5` names what the big one must contain and `flock_generator.dart`
/// produces it. The small one is pinned to the free tier's cap (§7.0 ruling 8)
/// so N30's at-cap tests cannot end up asserting against the wrong side of the
/// line.
const Map<String, ({int ewes, int seasons, int seed, bool culled})> _fixtures =
    <String, ({int ewes, int seasons, int seed, bool culled})>{
      'flock_400_3seasons.json': (ewes: 400, seasons: 3, seed: 137, culled: true),
      // **NO CULLED ROW HERE.** This fixture's ewe count is the free tier's
      // boundary and has to mean one thing — see `flockTables`' own comment.
      'flock_15_at_cap.json': (ewes: 15, seasons: 1, seed: 41, culled: false),
    };

void main(List<String> args) {
  final Directory out = Directory('test/fixtures');
  if (!out.existsSync()) {
    out.createSync(recursive: true);
  }

  final ExportEnvelope envelope = seedEnvelope();

  for (final MapEntry<String, ({int ewes, int seasons, int seed, bool culled})> f
      in _fixtures.entries) {
    final Map<String, Object?> tables = flockTables(
      ewes: f.value.ewes,
      seasons: f.value.seasons,
      seed: f.value.seed,
      withCulledReusedTag: f.value.culled,
    );

    // THE CHECKSUM COVERS THE CANONICAL `tables` BYTES — the same call
    // `writeBackup` makes, so a fixture that fails verification is telling the
    // truth about the writer rather than about this script.
    final String checksum = fnv1a64Hex(canonicalJsonBytes(tables));

    final BackupHeader header = BackupHeader(
      schema: kSchemaVersion,
      appVersion: envelope.appVersion,
      exportedAtUtc: envelope.generatedAt.utc.toIso8601String(),
      // FIXED, NOT READ FROM THE MACHINE. A zone read here would make the file
      // depend on where it was generated, which is the same determinism argument
      // that keeps `newUid()` out of the generator.
      exportedAtOffsetMinutes: 0,
      exportedAtZoneAbbreviation: 'GMT',
      counts: <String, int>{
        for (final MapEntry<String, Object?> t in tables.entries)
          t.key: (t.value! as List<Object?>).length,
      },
      media: const BackupMedia(included: false, count: 0, bytes: 0),
    );

    // `headerPrefixJson` ends in `,"tables":` — it is a prefix, so the file is
    // the prefix, the canonical tables, and the closing brace.
    final String text =
        '${headerPrefixJson(header, checksum, envelope)}'
        '${utf8.decode(canonicalJsonBytes(tables))}}';

    File('${out.path}/${f.key}').writeAsStringSync(text);
    stdout.writeln(
      '${f.key}: ${f.value.ewes} ewes, ${f.value.seasons} seasons, '
      'seed ${f.value.seed}, checksum $checksum',
    );
  }
}

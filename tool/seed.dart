// tool/seed.dart — the demo database, written **through the restore path**.
//
// That is the whole design and it is not convenience: `00-README` §9 step 8 puts
// the seed here so that filling a phone with 400 ewes exercises the one code
// path where a bug loses five seasons. A seed that wrote through repositories
// would be a second writer, tested by nothing, and the restore would go a year
// without being run outside its own unit tests.
//
// It is also what makes 400-ewe profiling, the overflow matrix, the eight
// goldens and the at-cap monetization tests possible at all.
//
//   dart run --define=SHED_SEED=true tool/seed.dart --ewes 400 --seasons 3 --seed 42
//
// **AND IT DOES NOT RUN UNDER PLAIN `dart run` TODAY. MEASURED, NOT ASSUMED.**
// `RestoreService` records its outcome through `LocalLog` (#124), `LocalLog`
// imports `package:flutter/foundation.dart`, and that needs `dart:ui` — which
// only the Flutter engine provides. The failure is
// `'Picture' isn't a type` out of the framework, which names nothing useful.
//
// The task calls this *a plain Dart script with no Flutter bindings*, and it
// cannot be one while that edge exists. Two ways out, neither of them this
// task's: `LocalLog` drops its `foundation` import (it is N11's file), or
// `RestoreService` takes an injected recorder. **Routed rather than worked
// around** — reaching for a second logger here would put a second definition of
// *what a restore records* in the tree.
//
// The generator and this script's shape are verified through
// `test/features/seed_test.dart`, which runs where `dart:ui` exists and
// exercises the same `flockTables` → backup → `RestoreService` path end to end.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/backup_format.dart';
import 'package:shed_book/data/restore_service.dart';

import 'flock_generator.dart';

bool _assertsAreOn = false;

Future<void> main(List<String> args) async {
  // **#74: IT CANNOT RUN IN A RELEASE BUILD, AND BOTH GUARDS ARE NEEDED.**
  // `assert()` is stripped in release, so on its own it would silently permit
  // exactly the build it exists to refuse; the define is what makes the refusal
  // loud. Together: release cannot pass the assert, and a debug run without the
  // define gets a message telling it how.
  assert(() {
    _assertsAreOn = true;
    return true;
  }());
  if (!_assertsAreOn || !const bool.fromEnvironment('SHED_SEED')) {
    // Decision #74 calls it *a `--dart-define`*; the flag `dart run` accepts is
    // spelled `--define` (`flutter run` spells the same thing `--dart-define`).
    // The message prints the one this script is actually launched with.
    stderr.writeln(
      'tool/seed.dart is a development script. '
      'Run it with: dart run --define=SHED_SEED=true tool/seed.dart',
    );
    exit(2);
  }

  final _Options o = _parse(args);
  final Directory support = Directory(o.out)..createSync(recursive: true);

  // ONE BACKUP FILE, WRITTEN BY THE APP'S OWN ENCODER — not a second one. A
  // fixture built by a private writer is a fixture that agrees with nothing.
  final Map<String, Object?> tables = flockTables(ewes: o.ewes, seasons: o.seasons, seed: o.seed);
  final Uint8List body = canonicalJsonBytes(tables);
  final BackupHeader header = BackupHeader(
    schema: kSchemaVersion,
    appVersion: '1.0.0',
    // FIXED, NOT `appNow()`. Same seed, same bytes — a timestamp here would make
    // the committed fixtures differ on every regeneration and unreviewable in a
    // diff, which is most of what they are for.
    exportedAtUtc: '2026-07-27T21:04:00.000Z',
    exportedAtOffsetMinutes: 0,
    exportedAtZoneAbbreviation: 'GMT',
    counts: <String, int>{
      for (final MapEntry<String, Object?> e in tables.entries)
        e.key: (e.value! as List<Object?>).length,
    },
    media: const BackupMedia(included: false, count: 0, bytes: 0),
  );

  final File backup = File('${support.path}/seed-${o.seed}.json');
  backup.writeAsBytesSync(<int>[
    ...utf8.encode(headerPrefixJson(header, fnv1a64Hex(body), seedEnvelope())),
    ...body,
    ...utf8.encode('}\n'),
  ]);

  // AND THEN THROUGH THE RESTORE, which is the point.
  final Map<String, Object?> decoded =
      jsonDecode(backup.readAsStringSync()) as Map<String, Object?>;
  final BackupHeaderOutcome outcome = readBackupHeader(decoded);
  if (outcome is! BackupHeaderAccepted) {
    stderr.writeln('seed: the file this script just wrote is not readable by this build');
    exit(1);
  }

  final WriteOutcome result = await RestoreService(support).restore(
    header: outcome.header,
    tables: <String, List<Map<String, Object?>>>{
      for (final MapEntry<String, Object?> e
          in (decoded['tables']! as Map<String, Object?>).entries)
        e.key: <Map<String, Object?>>[
          for (final Object? row in e.value! as List<Object?>) row! as Map<String, Object?>,
        ],
    },
    openStaging: (File file) async {
      file.parent.createSync(recursive: true);
      return AppDatabase(NativeDatabase(file), seedOnCreate: false);
    },
  );

  if (result is! WriteCommitted) {
    stderr.writeln('seed: the restore refused the file — $result');
    exit(1);
  }

  stdout.writeln(
    'seeded ${o.ewes} ewes over ${o.seasons} seasons at seed ${o.seed}\n'
    '  backup:   ${backup.path}\n'
    '  database: ${support.path}/$kLiveDatabaseName',
  );
}

/// **HAND-ROLLED, because `args` is not in the verified dependency table** and
/// nothing enters `pubspec.yaml` for a development script (decision-record §5.1).
/// Four flags do not justify a package the offline gates would then have to
/// reason about.
_Options _parse(List<String> args) {
  int of(String flag, int fallback) {
    final int i = args.indexOf('--$flag');
    return i == -1 || i + 1 >= args.length ? fallback : int.parse(args[i + 1]);
  }

  final int outAt = args.indexOf('--out');
  return _Options(
    ewes: of('ewes', 400),
    seasons: of('seasons', 3),
    seed: of('seed', 42),
    out: outAt == -1 || outAt + 1 >= args.length
        ? Directory.systemTemp.createTempSync('shed_seed').path
        : args[outAt + 1],
  );
}

final class _Options {
  const _Options({
    required this.ewes,
    required this.seasons,
    required this.seed,
    required this.out,
  });

  final int ewes;
  final int seasons;
  final int seed;
  final String out;
}

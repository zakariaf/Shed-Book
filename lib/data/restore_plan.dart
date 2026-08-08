// lib/data/restore_plan.dart
//
// **THE HALF OF THE RESTORE FLOW THAT HAS NO `BuildContext`.**
//
// The flow crosses a layer boundary in the middle: reading the file, counting
// what is on the phone and swapping the database are `lib/data/`'s, and the two
// -step confirmation is a modal that only a screen can show. Splitting it here
// is not tidiness — `layer.features` fails the build on a `lib/features/` file
// that imports `lib/core/db/`, and the first draft of this flow did, three
// times: the staging `AppDatabase`, `drift/native.dart` and the live counts.
//
// So this file prepares and commits, and `restore_controller.dart` asks.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/backup_format.dart';
import 'package:shed_book/data/restore_service.dart';

/// The four numbers both sides of the confirmation print.
///
/// **A record and not the drift row class**: it is built from a header on one
/// side and from four counts on the other, and neither is a table.
typedef RestoreCounts = ({int seasons, int ewes, int lambs, int treatments});

/// A file that has been read and accepted, with everything the confirmation
/// needs and nothing written yet.
///
/// **REACHING THIS IS STILL ABANDONABLE WITH NOTHING LOST** — `04 §7.2` puts the
/// last non-destructive step at 10, and this is step 3.
final class RestorePlan {
  const RestorePlan({
    required this.header,
    required this.tables,
    required this.backup,
    required this.live,
  });

  final BackupHeader header;
  final Map<String, List<Map<String, Object?>>> tables;
  final RestoreCounts backup;
  final RestoreCounts live;
}

/// Either a plan or the refusal to render.
sealed class RestorePlanOutcome {
  const RestorePlanOutcome();
}

final class RestorePlanned extends RestorePlanOutcome {
  const RestorePlanned(this.plan);
  final RestorePlan plan;
}

final class RestorePlanRefused extends RestorePlanOutcome {
  const RestorePlanRefused(this.refusal);
  final BackupRefused refusal;
}

/// Reads a picked file against the live database.
///
/// **A FUNCTION BEHIND A PROVIDER, BECAUSE `lib/features/` MAY NOT NAME
/// `AppDatabase`** (`layer.features`, `04 §4.9`). The controller has to supply a
/// path and get a plan back without ever holding a database handle, and this
/// typedef is the shape of that seam.
typedef RestorePlanner = Future<RestorePlanOutcome> Function(String pickedPath);

/// `04 §7.2` steps 1–3: sniff, read, count. Writes nothing.
Future<RestorePlanOutcome> planRestore(String pickedPath, AppDatabase live) async {
  final BackupHeaderOutcome outcome = await readBackupPrelude(pickedPath);
  if (outcome case final BackupRefused refused) {
    return RestorePlanRefused(refused);
  }
  final BackupHeader header = (outcome as BackupHeaderAccepted).header;

  // **A SECOND READ OF THE SAME FILE, DELIBERATELY.** `readBackupPrelude`
  // returns a header and not a payload so that a file which is going to be
  // refused is never fully decoded — a truncated 40 MB download should cost a
  // sniff, not a parse.
  final Map<String, List<Map<String, Object?>>> tables;
  try {
    final Object? decoded = jsonDecode(await File(pickedPath).readAsString());
    final Map<String, Object?> raw =
        (decoded! as Map<String, Object?>)['tables']! as Map<String, Object?>;
    tables = <String, List<Map<String, Object?>>>{
      for (final MapEntry<String, Object?> e in raw.entries)
        e.key: <Map<String, Object?>>[
          for (final Object? row in e.value! as List<Object?>) row! as Map<String, Object?>,
        ],
    };
  } on Object {
    // The header parsed and the body did not, which is *incomplete* rather than
    // *not ours*: the shepherd's file IS a Shed Book backup and it is short.
    return const RestorePlanRefused(
      BackupRefused(BackupRefusalReason.malformedHeader, foundKind: BackupFileKind.shedBookBackup),
    );
  }

  return RestorePlanned(
    RestorePlan(
      header: header,
      tables: tables,
      backup: (
        seasons: header.counts['seasons'] ?? 0,
        ewes: header.counts['ewes'] ?? 0,
        lambs: header.counts['lambs'] ?? 0,
        treatments: header.counts['treatments'] ?? 0,
      ),
      live: (
        seasons: (await live.select(live.seasons).get()).length,
        ewes: (await live.select(live.ewes).get()).length,
        lambs: (await live.select(live.lambs).get()).length,
        treatments: (await live.select(live.treatments).get()).length,
      ),
    ),
  );
}

/// `04 §7.2` steps 5–14. The only call in the product that renames the live
/// database, and the only one past the point of no return.
Future<WriteOutcome> commitRestore(RestoreService service, RestorePlan plan) => service.restore(
  header: plan.header,
  tables: plan.tables,
  openStaging: (File file) async {
    file.parent.createSync(recursive: true);
    // `seedOnCreate: false`: `importInto` decides whether a first-run season is
    // needed, at the end of its own transaction, and only when the backup
    // carries none.
    return AppDatabase(NativeDatabase(file), seedOnCreate: false);
  },
);

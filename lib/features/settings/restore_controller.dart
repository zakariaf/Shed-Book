// lib/features/settings/restore_controller.dart
//
// **THE CALLER THAT WAS NEVER WRITTEN.**
//
// `pickBackupFile`, `readBackupPrelude`, `showRestoreConfirmation` and
// `RestoreService.restore` all landed at N23 and every one was tested at the
// piece level. Nothing in `lib/` called any of them: `SettingsSectionId.data`
// fell through to an empty widget list, so Settings ▸ Data printed a heading
// over nothing, and the only recovery path this product has was unreachable
// from inside the product.
//
// Found on 2026-08-04 by N33-T05's ARB orphan sweep — ten `restoreRefused*` and
// `restoreDone*` messages that nothing rendered. Sorted by `CLAUDE.md`'s own
// test: *on the night of 3 March 2027, what happens?* A shepherd on a new
// phone, holding the backup file this product tells them to make, cannot get
// their records back.
//
// **THIS FILE IS THE ASKING HALF.** Everything with no `BuildContext` — the
// read, the counts, the swap — is `lib/data/restore_plan.dart`'s, because
// `layer.features` fails the build on a `lib/features/` file that imports
// `lib/core/db/`, and the first draft of this flow did so three times.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/failure.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/backup_format.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/data/restore_plan.dart';
import 'package:shed_book/data/restore_service.dart';
import 'package:shed_book/features/settings/restore_flow.dart';
import 'package:shed_book/features/settings/widgets/restore_confirmation.dart';

/// What a restore attempt ended as.
///
/// **AN OUTCOME, NOT AN EXCEPTION** (`01 §5`). A refusal is a value the screen
/// renders: the app read the file perfectly well and declined to act on it, and
/// that is a different thing from a database it could not read.
sealed class RestoreAttempt {
  const RestoreAttempt();
}

/// The shepherd backed out — of the picker or of the confirmation.
///
/// **NOT AN ERROR.** Backing out is a decision, and rendering it as a failure is
/// how a screen tells somebody they did something wrong when they did not.
final class RestoreAbandoned extends RestoreAttempt {
  const RestoreAbandoned();
}

/// The file was read and declined. [refusal] is what to say.
final class RestoreDeclined extends RestoreAttempt {
  const RestoreDeclined(this.refusal);
  final BackupRefused refusal;
}

/// The swap happened. [media] is how many photos and voice notes the other phone
/// had — this version does not carry them, and the completion copy says so.
final class RestoreDone extends RestoreAttempt {
  const RestoreDone(this.media);
  final int media;
}

/// The swap was attempted and did not complete. **The live database is
/// untouched**: `RestoreService` rolls back before it returns.
final class RestoreFailed extends RestoreAttempt {
  const RestoreFailed(this.failure);
  final ShedFailure failure;
}

/// `04 §7.2` steps 0–14, from the Settings row to the outcome the section
/// prints.
Future<RestoreAttempt> runRestore(BuildContext context, WidgetRef ref) async {
  // 0 — the picker, through the one `file_selector` call site in the app. It
  // returns a path rather than an `XFile` so this file never names the plugin's
  // type, which would need the import `layer.plugin_file_selector` forbids.
  final String? picked = await pickBackupFile();
  if (picked == null) {
    return const RestoreAbandoned();
  }

  // 1–3 — sniff, read, count. Nothing is written and every refusal returns here.
  final RestorePlanOutcome planned = await ref.read(restorePlannerProvider)(picked);
  if (planned case RestorePlanRefused(refusal: final BackupRefused r)) {
    return RestoreDeclined(r);
  }
  final RestorePlan plan = (planned as RestorePlanned).plan;

  if (!context.mounted) {
    return const RestoreAbandoned();
  }

  // 4 — the two-step confirmation. **THE LAST POINT AT WHICH NOTHING HAS
  // HAPPENED.** Everything above can be abandoned with nothing lost.
  final bool go = await showRestoreConfirmation(
    context,
    backup: plan.backup,
    live: plan.live,
    backupDate: plan.header.exportedAtUtc,
    backupVersion: plan.header.appVersion,
    mediaCount: plan.header.media.count,
  );
  if (!go) {
    return const RestoreAbandoned();
  }

  // 5–14 — the staging build, the validation and the two renames.
  final RestoreService service = await ref.read(restoreServiceProvider.future);
  final WriteOutcome result = await commitRestore(service, plan);

  // **EXHAUSTIVE, WITH NO `_` ARM.** `WriteOutcome` is sealed; a fourth variant
  // must fail to compile here rather than fall into a default that reports a
  // restore as failed when it committed, or the reverse.
  return switch (result) {
    WriteCommitted() => RestoreDone(plan.header.media.count),
    WriteRefused() => const RestoreAbandoned(),
    WriteFailed(failure: final ShedFailure f) => RestoreFailed(f),
  };
}

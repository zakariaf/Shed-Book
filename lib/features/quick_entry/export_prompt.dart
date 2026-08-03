// lib/features/quick_entry/export_prompt.dart
//
// THE SIX CONDITIONS, AS ONE PURE FUNCTION.
//
// `07 §16.2` — **every** condition must hold. This is an `&&` chain and there is
// no "mostly": the banner is the app's only safety prompt and a prompt that
// fires when it should not is a prompt shepherds learn to ignore.
//
// **A BANNER, NOT A NOTIFICATION**, and the reason is structural rather than
// stylistic (#72, `07 §16.1`): a notification needs `POST_NOTIFICATIONS`, which
// is deliberately deferred to the moment the user asks for lock-screen alerts —
// so a shepherd who never creates a reminder would never receive the one prompt
// spec §7.9 calls a **safety** feature. A banner needs no permission, cannot
// fire while their hands are full, and honours spec §5's *zero interruptions*.
//
// Pure, and it takes `now` rather than reading it: R23 makes `appNow()` the only
// wall-clock reader in the app, so a test pins the hour with `withClock` and this
// function has nothing to stub.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/data/export_repository.dart';
import 'package:shed_book/data/models.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/features/quick_entry/quick_entry_controller.dart';

/// Everything the decision needs, and nothing else.
typedef ExportPromptInputs = ({
  Instant now,
  Instant? lastExportedAt,
  Instant? lastExportPromptedAt,
  SeasonId? currentSeason,
  SeasonId? dismissedForSeason,
  int recordsSinceExport,

  /// Condition 5. **Session state, not stored state** — a shepherd mid-entry is
  /// not interrupted, and "mid-entry" is a fact about this launch.
  bool entryInProgress,
});

/// The quiet window the owner set for the free-tier surfaces (§7.0 ruling 8),
/// reused here on purpose: one window, one answer to *when may the app speak*.
const int kExportPromptOpensHour = 6;
const int kExportPromptClosesHour = 22;

/// Whether the end-of-day banner may render **right now**.
///
/// Condition 6 **narrows** decision #72 rather than widening it. Without it,
/// *"first launch of a local civil day"* during lambing means 03:00 on night
/// eleven — which is exactly the interruption this banner is supposed to be
/// gentler than.
bool shouldPromptExport(ExportPromptInputs i) {
  // THE CIVIL DAY, IN LOCAL TIME, using the same derivation as
  // `lambings.local_date`. Comparing UTC days fires the banner an hour early or
  // late depending on the season — the kind of small wrongness that makes a
  // shepherd stop trusting a screen.
  final LocalDate today = LocalDate.of(i.now);
  final int hour = i.now.local.hour;

  // 6 — inside the window.
  if (hour < kExportPromptOpensHour || hour >= kExportPromptClosesHour) {
    return false;
  }

  // 5 — nothing is open.
  if (i.entryInProgress) {
    return false;
  }

  // 4 — not dismissed for this season.
  if (i.currentSeason != null && i.dismissedForSeason == i.currentSeason) {
    return false;
  }

  // 3 — not already prompted today.
  if (i.lastExportPromptedAt != null && LocalDate.of(i.lastExportPromptedAt!).iso == today.iso) {
    return false;
  }

  // 2 — there is something to export that has not been exported.
  //
  // **NOT "has it been a while".** A shepherd who exported an hour ago and has
  // recorded nothing since is told nothing, however long ago the last prompt
  // was: the banner is about unexported records, not about elapsed time.
  if (i.recordsSinceExport <= 0) {
    return false;
  }

  // 1 — the first launch of a local civil day is expressed as *not prompted
  // today*, which condition 3 already holds. Stating it separately would be a
  // second source of truth about the same fact, and the two would drift.
  return true;
}

/// What the screen needs to render the banner, and whether it renders at all.
///
/// **ONE RECORD, NOT A BOOLEAN PLUS FOUR READS.** The banner's headline needs the
/// last export date and its count line needs the count, so a bare `bool` would
/// send the screen back for both — one frame later, and possibly to a different
/// answer.
typedef ExportPromptState = ({
  bool show,
  Instant now,
  Instant? lastExportedAt,
  int recordsSinceExport,
  SeasonId? currentSeason,
});

/// The banner's decision, evaluated once per build against `appNow()`.
///
/// **`.autoDispose`**, and it is watched by Quick Entry alone. It reads settings
/// and one count; the six conditions are `shouldPromptExport`'s, which is pure
/// and takes `now` rather than reading it (R23).
final AutoDisposeFutureProvider<ExportPromptState> exportPromptProvider =
    FutureProvider.autoDispose<ExportPromptState>((ref) async {
      // THE DATABASE FIRST. `settingsProvider` reads `requireValue` on it, so
      // watching settings before it opens throws — and the throw arrives as a
      // `null` value on the screen rather than as an error, which is how the
      // Export screen's counts silently never landed. Measured, in T07.
      await ref.watch(databaseProvider.future);
      final AppSetting settings = await ref.watch(settingsProvider.future);
      final Instant now = appNow();

      final SeasonId? season = settings.currentSeason == null
          ? null
          : SeasonId(settings.currentSeason!);

      final int since = season == null
          ? 0
          : await ref
                .watch(exportRepositoryProvider.future)
                .then(
                  (ExportRepository r) =>
                      r.countRecordsSinceExport(season, settings.lastExportedAt),
                );

      return (
        show: shouldPromptExport((
          now: now,
          lastExportedAt: settings.lastExportedAt,
          lastExportPromptedAt: settings.lastExportPromptedAt,
          currentSeason: season,
          dismissedForSeason: settings.exportPromptDismissedForSeason == null
              ? null
              : SeasonId(settings.exportPromptDismissedForSeason!),
          recordsSinceExport: since,
          // CONDITION 5, and it is a fact about this launch rather than a stored
          // one: a shepherd with a ewe loaded is mid-entry, and mid-entry is the
          // one moment spec §5 promises zero interruptions.
          entryInProgress: ref.watch(quickEntryControllerProvider).selected != null,
        )),
        now: now,
        lastExportedAt: settings.lastExportedAt,
        recordsSinceExport: since,
        currentSeason: season,
      );
    });

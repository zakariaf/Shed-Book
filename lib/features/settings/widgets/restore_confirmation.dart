// lib/features/settings/widgets/restore_confirmation.dart
//
// THE CONFIRMATION THAT NAMES WHAT IT WILL DESTROY, in `04 §7.3`'s order — and
// **the order is the argument**: what you are about to gain, what you are about
// to lose, what that means, what it does not include, and only then the controls.
//
// **THE ONE `showDialog(` CALL SITE THIS FEATURE IS ALLOWED (R85).**
// `indelible.md §7.14` said the bottom sheet is the only overlay in the app;
// `07 §14.4` said these two flows may be modal. R85 rules for the second and
// amends the first, and the reason is dismissal rather than taste: a sheet closes
// when a thumb lands outside it — correct for a chooser, exactly wrong for a
// confirmation that deletes every record on the phone. Indelible's own argument
// for the sheet is that nothing vanishes under your hand; a dismissible
// destruction dialog is that principle inverted.
//
// `ui.show_dialog` confines it here **in the rule**, not in the allowlist.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_primary_button.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/l10n/app_localizations.dart';

/// What the two summaries render.
///
/// **Two of these are built from two different sources**, and keeping them the
/// same shape is what makes swapping them possible — so the call site names them
/// and the test asserts the live one against a `COUNT(*)` it takes itself.
typedef RestoreCounts = ({int seasons, int ewes, int lambs, int treatments});

/// `canPop: false` — the **second** such flow in the app, and `07 §14.3` is
/// corrected in the same commit that says so. Once step 12's rename has begun
/// there is nothing to pop back to.
Future<bool> showRestoreConfirmation(
  BuildContext context, {
  required RestoreCounts backup,
  required RestoreCounts live,
  required String backupDate,
  required String backupVersion,
  required int mediaCount,
}) async =>
    await showDialog<bool>(
      context: context,
      // NOT DISMISSIBLE. This is the whole reason the flow is modal at all.
      barrierDismissible: false,
      builder: (BuildContext context) => PopScope(
        canPop: false,
        child: _RestoreConfirmation(
          backup: backup,
          live: live,
          backupDate: backupDate,
          backupVersion: backupVersion,
          mediaCount: mediaCount,
        ),
      ),
    ) ??
    false;

class _RestoreConfirmation extends StatefulWidget {
  const _RestoreConfirmation({
    required this.backup,
    required this.live,
    required this.backupDate,
    required this.backupVersion,
    required this.mediaCount,
  });

  final RestoreCounts backup;
  final RestoreCounts live;
  final String backupDate;
  final String backupVersion;
  final int mediaCount;

  @override
  State<_RestoreConfirmation> createState() => _RestoreConfirmationState();
}

class _RestoreConfirmationState extends State<_RestoreConfirmation> {
  /// **TWO STEPS, NOT ONE.** A single 72 pt button under a wall of text is one
  /// cold thumb away from destroying a season. Step one commits to nothing; it
  /// unlocks step two.
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: t.surfaceRaised,
      insetPadding: EdgeInsets.all(t.gapMin),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(t.gapMin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // 1 — WHAT IS IN THE BACKUP. First, because a shepherd deciding
              // whether to restore is deciding whether this is the right file,
              // and they cannot judge that from a name.
              Text(
                l10n.restoreBackupSummary(
                  seasons: widget.backup.seasons,
                  ewes: widget.backup.ewes,
                  lambs: widget.backup.lambs,
                  treatments: widget.backup.treatments,
                  date: widget.backupDate,
                  version: widget.backupVersion,
                ),
                key: const Key('settings.restore.backup_summary'),
                style: text.bodyMedium,
              ),
              SizedBox(height: t.gapMin),
              // 2 — WHAT IS ON THIS PHONE NOW. Read with `COUNT(*)` from the
              // live database, never from the header: rendering the backup's
              // numbers here is the one bug that makes the whole confirmation a
              // lie, and it looks right in every screenshot.
              Text(
                l10n.restoreLiveSummary(
                  seasons: widget.live.seasons,
                  ewes: widget.live.ewes,
                  lambs: widget.live.lambs,
                  treatments: widget.live.treatments,
                ),
                key: const Key('settings.restore.live_summary'),
                style: text.bodyMedium,
              ),
              SizedBox(height: t.gapMin),
              // 3 — WHAT THAT MEANS.
              Text(
                l10n.restoreDestruction,
                key: const Key('settings.restore.destruction'),
                style: text.bodyMedium?.copyWith(color: t.statusAttention),
              ),
              SizedBox(height: t.gapMin),
              // 4 — WHAT IT DOES NOT INCLUDE, said BEFORE the controls. A
              // shepherd who learns afterwards that photos were not in the file
              // has been told too late to choose differently.
              Text(
                l10n.restoreMediaNotice(count: widget.mediaCount),
                key: const Key('settings.restore.media_notice'),
                style: text.bodySmall?.copyWith(color: t.textSecondary),
              ),
              SizedBox(height: t.gapMin),
              // 5 — THE CONTROLS, and only now.
              ShedTapTarget(
                key: const Key('settings.restore.step_one'),
                semanticLabel: l10n.restoreStepOne,
                minSize: t.tapIndelible,
                onTap: () => setState(() => _understood = true),
                child: ExcludeSemantics(
                  child: Center(
                    child: Text(
                      l10n.restoreStepOne,
                      style: _understood ? text.titleMedium : text.bodyMedium,
                    ),
                  ),
                ),
              ),
              SizedBox(height: t.gapMin),
              Row(
                children: <Widget>[
                  // CANCEL IS ALWAYS LIVE AND IS NEVER THE DESTRUCTIVE SIDE.
                  // Backing out of a destruction confirmation is the expected
                  // answer, not the exceptional one.
                  Expanded(
                    child: ShedTapTarget(
                      key: const Key('settings.restore.cancel'),
                      semanticLabel: l10n.restoreCancel,
                      minSize: t.tapPrimary,
                      onTap: () => Navigator.of(context).pop(false),
                      child: ExcludeSemantics(
                        child: Center(child: Text(l10n.restoreCancel, style: text.titleMedium)),
                      ),
                    ),
                  ),
                  SizedBox(width: t.gapMin),
                  // AND STEP TWO IS ON THE OPPOSITE SIDE.
                  //
                  // **`refusing`, NOT DISABLED — AND THERE IS NO DISABLED.**
                  // `ShedPrimaryButton` has four states and none of them is a
                  // dead control: `onTap` is non-nullable *"and that is the whole
                  // task"*, because a null callback announces as a disabled
                  // button, makes `06 §6.3`'s geometric gate skip it, and leaves
                  // a shepherd tapping a live-looking rectangle that does
                  // nothing.
                  //
                  // The task asked for *disabled until step one is taken*.
                  // Indelible's answer to that shape is `refusing` — *"what is
                  // missing, said in words… `onTap` still fires: it opens the
                  // thing that is missing."* So a thumb that lands here first
                  // takes step one rather than being ignored, and the two-step
                  // guarantee is unchanged: **the restore still needs two
                  // presses**, and the first one cannot be the destructive one.
                  Expanded(
                    child: ShedPrimaryButton(
                      key: const Key('settings.restore.replace_everything'),
                      label: l10n.restoreReplaceEverything,
                      semanticLabel: l10n.restoreReplaceEverything,
                      state: _understood
                          ? ShedPrimaryButtonState.ready
                          : ShedPrimaryButtonState.refusing,
                      onTap: () {
                        if (!_understood) {
                          setState(() => _understood = true);
                          return;
                        }
                        Navigator.of(context).pop(true);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/features/settings/widgets/data_section.dart
//
// **SECTION 11 OF `07 §14.3`, AND IT WAS EMPTY.** `SettingsSectionId.data` fell
// through to `const <Widget>[]`, so this section printed a heading and nothing
// under it — and `pickBackupFile`, `readBackupPrelude`,
// `showRestoreConfirmation` and `RestoreService.restore` had no caller anywhere
// in `lib/`. N23-T02's step 4 was never done, and the only recovery path this
// product has was unreachable from inside the product.
//
// **THE TWO DELETES ARE `v1.1.0`** (`docs/RELEASE-SCOPE.md`, N29-T03/T06), so
// this section holds one row in `v1.0.0`. That is not a hidden gap: a shepherd
// who wants a season gone can restore an earlier backup, and a shepherd who
// wants everything gone deletes the app. Neither is true of restore, which has
// no substitute at all.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/backup_format.dart';
import 'package:shed_book/features/settings/restore_controller.dart';
import 'package:shed_book/l10n/app_localizations.dart';

final class DataSection extends ConsumerStatefulWidget {
  const DataSection({super.key});

  @override
  ConsumerState<DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends ConsumerState<DataSection> {
  /// What the last attempt said, printed in the section rather than over it.
  ///
  /// **NOT A SNACKBAR AND NOT A TOAST** (ruling P2). A refusal is a sentence the
  /// shepherd needs to still be there while they go and find the right file, and
  /// a message that dismisses itself is a message read by whoever was looking.
  String? _said;

  /// True while the picker or the swap is in flight. **The row refuses rather
  /// than disables** — `indelible.md §7.13`'s answer to a dead control is a
  /// control that says what it is waiting for.
  bool _busy = false;

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _said = null;
    });

    final AppLocalizations l10n = AppLocalizations.of(context);
    final RestoreAttempt attempt = await runRestore(context, ref);

    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _said = switch (attempt) {
        // **BACKING OUT SAYS NOTHING**, because it is a decision rather than a
        // failure and a line of copy about it is a line telling somebody they
        // did something wrong when they did not.
        RestoreAbandoned() => null,
        RestoreDeclined(refusal: final BackupRefused r) => _refusalCopy(l10n, r),
        RestoreDone(media: final int media) =>
          media == 0
              ? l10n.restoreDoneTitle
              : '${l10n.restoreDoneTitle} ${l10n.restoreDoneMedia(count: media)}',
        RestoreFailed() => l10n.restoreRefusedDamaged,
      };
    });
  }

  /// One sentence per refusal, and **eight reasons rather than one**.
  ///
  /// `04 §7.4` splits them because the actions differ: *this is a photo archive*
  /// sends a shepherd back to the picker for a different file, *this was made by
  /// a newer version* sends them to the store, and *this is damaged* sends them
  /// to their other backup. One sentence covering all three would send them
  /// nowhere.
  ///
  /// An exhaustive switch with no `default:` — a ninth reason must fail to
  /// compile here rather than print the wrong sentence.
  String _refusalCopy(AppLocalizations l10n, BackupRefused r) => switch (r.reason) {
    BackupRefusalReason.notShedBookFormat => l10n.restoreRefusedNotOurs,
    BackupRefusalReason.newerFormatVersion || BackupRefusalReason.newerSchema =>
      '${l10n.restoreRefusedNewerApp} '
          '${l10n.restoreRefusedNewerAppDetail(foundFormat: r.foundFormatVersion ?? 0, foundSchema: r.foundSchema ?? 0, readsFormat: r.readsFormatVersion, readsSchema: r.readsSchema)}',
    // **DAMAGED AND INCOMPLETE ARE THE SAME REASON AND TWO SENTENCES.** The
    // header parsed and the body did not, so the file IS a Shed Book backup and
    // it is short — and the second half of that sentence is the one that
    // matters: nothing on this phone has changed.
    BackupRefusalReason.malformedHeader =>
      '${l10n.restoreRefusedDamaged} ${l10n.backupRefusedIncomplete}',
    BackupRefusalReason.pickedZipArchive => l10n.restoreRefusedZip,
    BackupRefusalReason.pickedDatabaseCopy => l10n.restoreRefusedDatabaseCopy,
    BackupRefusalReason.notABackupFile => l10n.restoreRefusedNotABackup,
  };

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: ShedWordButton(
              key: const Key('settings.data.restore'),
              label: l10n.settingsDataRestore,
              semanticLabel: l10n.settingsDataRestore,
              // **NOT `selected`, EVER.** A word button's selected state is a
              // filter's, and this one is an act — a restore row that looked
              // chosen would read as a restore that had already happened.
              selected: false,
              // **NEVER `null`, EVEN WHILE BUSY.** A dead control is
              // indistinguishable from a missed tap at 03:20, and this row is
              // read in daylight by somebody who has just lost a phone. The
              // guard is in `_restore`, which returns immediately.
              onTap: () {
                if (!_busy) {
                  _restore();
                }
              },
            ),
          ),
          if (_said case final String said) ...<Widget>[
            SizedBox(height: t.gapMin),
            Text(
              said,
              key: const Key('settings.data.said'),
              style: text.bodyMedium?.copyWith(color: t.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

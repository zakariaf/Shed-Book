// lib/features/settings/widgets/diagnostics_section.dart
//
// Section 10 of `07 §14.3`, and `13 §8.5`'s rows in its order.
//
// **THERE IS NO TELEMETRY AND NO ANALYTICS IN THIS APP**, so this section is the
// only way a problem travels — and it travels because the shepherd sent it,
// deliberately, through the system share sheet.
//
// **THE INTEGRITY CHECK REPORTS AND REPAIRS NOTHING.** An app that silently
// "fixed" a records file would be the one thing worse than one that could not
// read it: the shepherd would never know which night stopped being true.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'package:shed_book/core/log/local_log.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/data/settings_repository.dart';
import 'package:shed_book/data/share_service.dart';
import 'package:shed_book/features/settings/widgets/setting_row.dart';
import 'package:shed_book/l10n/app_localizations.dart';

final class DiagnosticsSection extends ConsumerStatefulWidget {
  const DiagnosticsSection({super.key});

  @override
  ConsumerState<DiagnosticsSection> createState() => _DiagnosticsSectionState();
}

class _DiagnosticsSectionState extends ConsumerState<DiagnosticsSection> {
  /// `null` until the shepherd asks. **Not a value computed on build**: an
  /// integrity check is a full scan of the records file, and running it every
  /// time Settings opens would make the slowest possible answer the default one.
  bool? _intact;

  /// The two numbers, `null` until the check runs. Same reason as [_intact]:
  /// counting every record is a scan, and running it whenever Settings opens
  /// makes the slowest possible answer the default one.
  ({int records, int animals})? _counts;

  /// What the last share said, printed in the section rather than over it —
  /// there is no SnackBar in this app (ruling P2).
  String? _said;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toLanguageTag();

    // **ALREADY REDACTED, BECAUSE REDACTION HAPPENS ON THE WAY IN** (`13 §8.4`).
    // Nothing here re-implements `Redact`: a second pass is a second answer to
    // *what is a tag number*, and the two would disagree the first time one of
    // them was improved.
    final List<String> recent = LocalLog.instance.recentRecords();

    // **THE THREE ACTS ARE THREE ROWS, AND WHAT EACH ONE SAYS SITS UNDER IT.**
    // They were three word buttons separated by 16 pt of nothing, with the
    // verdict, the counts and the log preview floating between them — so the
    // reader had to work out which line belonged to which press. Ruled, the
    // answer is the position: a result line shares an edge with the row that
    // produced it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SettingRow(
          control: ShedWordButton(
            key: const Key('settings.diagnostics.check'),
            label: l10n.settingsDiagnosticsCheck,
            selected: false,
            onTap: _runCheck,
          ),
        ),
        if (_intact case final bool intact)
          SettingLine(
            text: intact ? l10n.settingsDiagnosticsIntact : l10n.settingsDiagnosticsDamaged,
            textKey: const Key('settings.diagnostics.result'),
          ),
        // **THE SIZE, BESIDE THE VERDICT** (`13 §8.5`). Whoever reads a
        // diagnostics note needs to know whether this is a test flock or four
        // seasons of work, and *intact* alone does not say.
        if (_counts case final ({int animals, int records}) c)
          SettingLine(
            // **THROUGH `formatShedCount`, WHICH IS WHY THE PLACEHOLDERS
            // ARE `String`.** A four-figure record count printed raw reads
            // as `1240`; grouped it reads as a size. The ARB declares them
            // as strings precisely so no call site can pass a bare `int`
            // and skip the formatter.
            text: l10n.settingsDiagnosticsCounts(
              records: formatShedCount(c.records, locale),
              ewes: formatShedCount(c.animals, locale),
            ),
            textKey: const Key('settings.diagnostics.counts'),
            muted: true,
          ),
        SettingLine(
          text: recent.isEmpty
              ? l10n.settingsDiagnosticsNoLog
              : l10n.settingsDiagnosticsRecent(count: recent.length),
          textKey: const Key('settings.diagnostics.recent_heading'),
          muted: true,
        ),
        for (final String record in recent) SettingLine(text: record),

        // **THE TWO SHARE ROWS, WHICH THIS FILE'S OWN HEADER ALREADY CLAIMED
        // AND DID NOT HAVE.** *"The only way a problem travels — and it
        // travels because the shepherd sent it, deliberately, through the
        // system share sheet."* That was true of the design and not of the
        // code: `13 §8.5`'s two rows had no widget, so the log and the file
        // could be read on the phone and never got off it. Found by N33-T05's
        // ARB orphan sweep.
        SettingRow(
          control: ShedWordButton(
            key: const Key('settings.diagnostics.share_log'),
            label: l10n.settingsDiagnosticsShareLog,
            selected: false,
            onTap: _shareLog,
          ),
        ),
        SettingRow(
          control: ShedWordButton(
            key: const Key('settings.diagnostics.share_snapshot'),
            label: l10n.settingsDiagnosticsShareSnapshot,
            selected: false,
            onTap: _shareSnapshot,
          ),
        ),
        if (_said case final String said)
          SettingLine(text: said, textKey: const Key('settings.diagnostics.said'), muted: true),
      ],
    );
  }

  Future<void> _runCheck() async {
    // **THROUGH THE REPOSITORY, BECAUSE TWO LAYER RULES SAY SO.**
    // `lib/features/` may not import `lib/core/db/` (rule 5), and the raw
    // statement is confined to `lib/core/db/` besides (rule 8) — so the widget
    // asks `SettingsRepository`, which asks the database.
    final SettingsRepository repo = ref.read(settingsRepositoryProvider);
    final bool ok = await repo.checkDatabase();
    final ({int animals, int records}) counts = await repo.diagnosticCounts();
    if (!mounted) {
      return;
    }
    setState(() {
      _intact = ok;
      _counts = counts;
    });
  }

  /// **THE LOG LEAVES THE PHONE ONLY BECAUSE THE SHEPHERD SENT IT.** There is no
  /// telemetry in this app and this is the whole of the alternative.
  Future<void> _shareLog() async {
    final String? path = LocalLog.instance.logFilePath;
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (path == null || !File(path).existsSync()) {
      setState(() => _said = l10n.settingsDiagnosticsNoLog);
      return;
    }
    await _share(<String>[path], <String>['shed-book-log.txt']);
  }

  /// A `VACUUM INTO` copy of the records file.
  ///
  /// **A SNAPSHOT, NEVER A BACKUP** (`CLAUDE.md`): a backup is the JSON a
  /// shepherd restores from, and this is a `.sqlite` for somebody debugging.
  /// The restore screen refuses one of these by name — `restoreRefusedDatabaseCopy`
  /// — which only reads as helpful if the two are never called the same thing.
  Future<void> _shareSnapshot() async {
    final Directory scratch = await ref.read(mediaStoreProvider).exportScratch();
    final File snapshot = await ref.read(settingsRepositoryProvider).writeSnapshot(scratch);
    await _share(<String>[snapshot.path], <String>['shed-book-diagnostics.sqlite']);
  }

  Future<void> _share(List<String> paths, List<String> names) async {
    // **`origin` IS REQUIRED AND IS THE WIDGET'S OWN RECT.** `share_plus` says
    // omitting it *"may cause crashes or unresponsive UI"* on iPad, which is the
    // platform nobody tests on first — so it is a required parameter rather than
    // a lint.
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final ShareOutcome outcome = await ref
        .read(shareServiceProvider)
        .shareFiles(
          paths: paths,
          fileNames: names,
          origin: box.localToGlobal(Offset.zero) & box.size,
        );

    if (!mounted) {
      return;
    }

    // **NOTHING IS STAMPED HERE, AND THAT IS THE POINT OF READING THE OUTCOME
    // AT ALL.** Sharing a diagnostics file is not an export: stamping
    // `last_exported_at` from this row would silence the end-of-day prompt for
    // a shepherd who has backed up nothing — the one failure mode that turns a
    // safety feature into a liability. The export screen stamps; this does not,
    // on any outcome.
    //
    // And nothing is said afterwards either. The sheet is another process: it
    // either handed the file on or the shepherd backed out, and both were
    // visible to them as they happened. A line of copy about it would be the
    // app narrating something it did not do.
    setState(() => _said = outcome == ShareOutcome.dismissed ? null : null);
  }
}

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
import 'package:shed_book/core/log/local_log.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/providers.dart';
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

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;

    // **ALREADY REDACTED, BECAUSE REDACTION HAPPENS ON THE WAY IN** (`13 §8.4`).
    // Nothing here re-implements `Redact`: a second pass is a second answer to
    // *what is a tag number*, and the two would disagree the first time one of
    // them was improved.
    final List<String> recent = LocalLog.instance.recentRecords();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ShedWordButton(
            key: const Key('settings.diagnostics.check'),
            label: l10n.settingsDiagnosticsCheck,
            selected: false,
            onTap: _runCheck,
          ),
          if (_intact case final bool intact)
            Padding(
              padding: EdgeInsets.only(top: t.gapMin / 2),
              child: Text(
                intact ? l10n.settingsDiagnosticsIntact : l10n.settingsDiagnosticsDamaged,
                key: const Key('settings.diagnostics.result'),
                style: text.bodyMedium,
              ),
            ),
          SizedBox(height: t.gapMin),
          Text(
            recent.isEmpty
                ? l10n.settingsDiagnosticsNoLog
                : l10n.settingsDiagnosticsRecent(count: recent.length),
            key: const Key('settings.diagnostics.recent_heading'),
            style: text.labelMedium,
          ),
          for (final String record in recent)
            Padding(
              padding: EdgeInsets.only(top: t.gapMin / 4),
              child: Text(record, style: text.bodySmall),
            ),
        ],
      ),
    );
  }

  Future<void> _runCheck() async {
    // **THROUGH THE REPOSITORY, BECAUSE TWO LAYER RULES SAY SO.**
    // `lib/features/` may not import `lib/core/db/` (rule 5), and the raw
    // statement is confined to `lib/core/db/` besides (rule 8) — so the widget
    // asks `SettingsRepository`, which asks the database.
    final bool ok = await ref.read(settingsRepositoryProvider).checkDatabase();
    if (!mounted) {
      return;
    }
    setState(() => _intact = ok);
  }
}

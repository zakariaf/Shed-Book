// lib/features/settings/widgets/about_section.dart
//
// Section 12 of `07 §14.3`: the version, and the offline statement.
//
// **THE OFFLINE PARAGRAPH IS `Disclaimers.offlineStatement`, REFERENCED AND
// NEVER RE-TYPED.** It is the only permitted public wording for the claim
// (decision-record §3.1), and `copy.disclaimer_retyped` fails the build on a
// second copy. The test compares the rendered text to
// `docs/store/offline-honesty.md` character for character — a copy in the test
// would drift from the copy in the document and then defend the wrong sentence.
//
// **AND IT IS DELIBERATELY NOT AN ARB STRING** (`10 §8.7`). A translator can
// drop or soften an ARB message and the app has no mechanism to notice; this
// sentence is the one whose softening would turn a true claim into a false one.
// Only tiers 1 and 2 are claimable — *no data leaves the device by any route* is
// **false**, because the share sheet is another process.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/log/local_log.dart' show kAppVersion;
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/l10n/app_localizations.dart';

final class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

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
          Text(
            // `kAppVersion` is a `--dart-define`, so a build that forgot to set
            // it reads `0.1.0` and says so rather than claiming a release number
            // it does not have.
            l10n.settingsAboutVersion(version: kAppVersion),
            key: const Key('settings.about.version'),
            style: text.bodyMedium,
          ),
          SizedBox(height: t.gapMin),
          Text(
            Disclaimers.offlineStatement,
            key: const Key('settings.about.offline'),
            style: text.bodyMedium,
          ),
          SizedBox(height: t.gapMin),
          Text(
            Disclaimers.exportFooter,
            key: const Key('settings.about.disclaimer'),
            style: text.bodyMedium,
          ),
        ],
      ),
    );
  }
}

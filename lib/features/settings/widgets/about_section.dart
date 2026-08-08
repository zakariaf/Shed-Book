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
import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/features/settings/widgets/setting_row.dart';
import 'package:shed_book/l10n/app_localizations.dart';

final class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    // **THREE PRINTED LINES, EACH IN THE RULING.** They were three `Text`s with
    // 16 pt of nothing between them at the foot of a page with no rules on it,
    // which is where the two paragraphs a shepherd may one day hand to a vet were
    // hardest to tell apart from chrome. Ruled, they read as the closing lines of
    // the same document — which is what they are.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SettingLine(
          // `kAppVersion` is a `--dart-define`, so a build that forgot to set
          // it reads `0.1.0` and says so rather than claiming a release number
          // it does not have.
          text: l10n.settingsAboutVersion(version: kAppVersion),
          textKey: const Key('settings.about.version'),
        ),
        SettingLine(
          text: Disclaimers.offlineStatement,
          textKey: const Key('settings.about.offline'),
        ),
        SettingLine(
          text: Disclaimers.exportFooter,
          textKey: const Key('settings.about.disclaimer'),
        ),
      ],
    );
  }
}

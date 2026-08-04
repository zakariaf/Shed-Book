// lib/features/settings/settings_screen.dart — `indelible.md §8` screen 12.
//
// **THE FILE DID NOT EXIST, AND TWO EARLIER TASKS SAID THEY EDITED IT.** N23-T02
// and N23-T03 both describe adding a row to this screen; neither created it, and
// no task before this one did. Recorded here rather than left for the next
// reader to rediscover: the Data row and the diagnostics line arrive with their
// own sections below, in the places §14.3 assigns them.
//
// ---------------------------------------------------------------------------
// SECTION LEDGER — `07 §14.3` LISTS TWELVE. THIS SCREEN RENDERS ELEVEN.
// ---------------------------------------------------------------------------
//
//   1  Units            N29-T02      7  Keep screen on   N29-T04
//   2  Terminology      N29-T03      8  Left-handed      N29-T04
//   3  Reminders        HERE         9  Unlock           *** N30-T05 ***
//   4  Season           N29-T05     10  Diagnostics      N29-T07
//   5  Pens             HERE        11  Data             N23-T02 + N29-T06
//   6  Appearance       N29-T04     12  About            N29-T07
//
// **Section 9 is ABSENT, NOT STUBBED.** `purchaseServiceProvider` is N30-T01's
// and nothing here may reach it — #90: nothing branches on `unlocked` outside
// the two gated verbs, and an empty Unlock row would be the paywall's outline
// showing through on a screen that has no business knowing about one.
//
// **Sections 2 and 11's deletes ship in `v1.1.0`** (`docs/RELEASE-SCOPE.md`):
// terminology editing is N29-T03 and the two deletes are N29-T06. The sections
// exist and say what they currently hold; what waits is the editing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_empty_state.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/models.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/features/settings/widgets/settings_section.dart';
import 'package:shed_book/l10n/app_localizations.dart';

/// The sections this screen renders, in `07 §14.3`'s order.
///
/// **DERIVED, NOT REMEMBERED.** The count is asserted against this list rather
/// than against a literal, so a section added without a ledger line above fails
/// the test that reads it.
enum SettingsSectionId {
  units,
  terminology,
  reminders,
  season,
  pens,
  appearance,
  keepScreenOn,
  leftHanded,
  diagnostics,
  data,
  about,
}

/// `07 §14.3`'s twelve minus Unlock. Public so the test reads the same list the
/// screen builds from.
const List<SettingsSectionId> kSettingsSections = SettingsSectionId.values;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: t.surfaceBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // `07 §16`'s sticky header: read-only, never collapses, never
            // parallaxes, never changes height. It carries no back button —
            // a 44 px row is below the 60 pt floor, so a target in it would be
            // an illegal one (`indelible.md §4.4`).
            Padding(
              padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin),
              child: Semantics(
                headingLevel: 1,
                child: Text(l10n.settingsTitle, style: Theme.of(context).textTheme.headlineSmall),
              ),
            ),
            Expanded(
              child: switch (ref.watch(settingsProvider)) {
                AsyncData<AppSetting>(value: final AppSetting settings) => _body(
                  context,
                  l10n,
                  settings,
                ),
                AsyncError<AppSetting>() => ShedEmptyState(
                  key: const Key('settings.error'),
                  copy: l10n.settingsUnavailable,
                ),
                // **NEVER A SPINNER** (#71). There is no loading state anywhere
                // in this app; the page colour is the honest first frame.
                _ => const SizedBox.expand(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n, AppSetting settings) => ListView(
    key: const Key('settings.list'),
    padding: EdgeInsets.zero,
    children: <Widget>[
      for (final SettingsSectionId id in kSettingsSections)
        SettingsSection(
          key: Key('settings.section.${id.name}'),
          title: _title(l10n, id),
          // **THE BODIES ARRIVE WITH THEIR OWN TASKS.** T01 lands the frame: the
          // ledger, the eleven headings and the four states §14.2 permits. A
          // section rendered with a placeholder control would be a control that
          // writes nothing while looking like it does.
          rows: const <Widget>[],
        ),
    ],
  );

  /// Exhaustive, no `default:` — a twelfth section must fail to compile here
  /// rather than render with no title.
  String _title(AppLocalizations l10n, SettingsSectionId id) => switch (id) {
    SettingsSectionId.units => l10n.settingsSectionUnits,
    SettingsSectionId.terminology => l10n.settingsSectionTerminology,
    SettingsSectionId.reminders => l10n.settingsSectionReminders,
    SettingsSectionId.season => l10n.settingsSectionSeason,
    SettingsSectionId.pens => l10n.settingsSectionPens,
    SettingsSectionId.appearance => l10n.settingsSectionAppearance,
    SettingsSectionId.keepScreenOn => l10n.settingsSectionKeepScreenOn,
    SettingsSectionId.leftHanded => l10n.settingsSectionLeftHanded,
    SettingsSectionId.diagnostics => l10n.settingsSectionDiagnostics,
    SettingsSectionId.data => l10n.settingsSectionData,
    SettingsSectionId.about => l10n.settingsSectionAbout,
  };
}

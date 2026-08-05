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
// **ALL TWELVE SINCE N30-T05.** Section 9 was absent rather than stubbed for
// five epics, because an empty Unlock row would have been the paywall's outline
// showing through on a screen that had no business knowing about one. It is here
// now, with the section that gives it meaning.
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
import 'package:shed_book/features/settings/settings_write_controller.dart';
import 'package:shed_book/features/settings/widgets/appearance_section.dart';
import 'package:shed_book/features/settings/widgets/about_section.dart';
import 'package:shed_book/features/settings/widgets/data_section.dart';
import 'package:shed_book/features/settings/widgets/diagnostics_section.dart';
import 'package:shed_book/features/settings/widgets/season_section.dart';
import 'package:shed_book/features/settings/widgets/settings_section.dart';
import 'package:shed_book/features/settings/widgets/unlock_section.dart';
import 'package:shed_book/features/settings/widgets/units_section.dart';
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
  // **SECTION 9 OF TWELVE, FILLED AT N30-T05.** T01 rendered eleven and left a
  // ledger comment naming this task as the twelfth's home; this is that.
  unlock,
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
          // **THE BODIES ARRIVE WITH THEIR OWN TASKS.** T01 landed the frame:
          // the ledger, the eleven headings and the four states §14.2 permits. A
          // section rendered with a placeholder control would be a control that
          // writes nothing while looking like it does.
          rows: _rows(id),
        ),
    ],
  );

  /// What each section holds today.
  ///
  /// **AN EMPTY LIST IS A SECTION WHOSE TASK HAS NOT LANDED**, not a section
  /// with nothing to say — and it renders as a heading with a rule under it,
  /// which is honest: the setting exists and is not yet reachable here.
  List<Widget> _rows(SettingsSectionId id) => switch (id) {
    // **NO TEMPERATURE CONTROL BESIDE IT, AND THAT IS RULED.** §7.0 row 11: no
    // `v1.0.0` table stores a temperature, so `AppSettings` carries no
    // `temperature_unit` column and a segmented line for one would be a setting
    // for a value that does not exist.
    SettingsSectionId.units => const <Widget>[UnitsSection()],
    SettingsSectionId.season => const <Widget>[SeasonSection()],
    // **DIAGNOSTICS AND ABOUT SIT OUTSIDE THE ERROR PANEL** (`07 §14.2`). They
    // are the two sections a shepherd needs *when something is wrong* — a
    // Diagnostics row that disappears because the settings row could not be read
    // is a diagnostics row that works only when nothing needs diagnosing.
    SettingsSectionId.diagnostics => const <Widget>[DiagnosticsSection()],
    // **THIS FELL THROUGH TO AN EMPTY LIST AND THE SECTION PRINTED A HEADING
    // OVER NOTHING.** N23-T02's step 4 — the Settings ▸ Data row that opens the
    // restore — was never done, so the only recovery path this product has had
    // no caller anywhere in `lib/`. Found by N33-T05's ARB orphan sweep.
    SettingsSectionId.data => const <Widget>[DataSection()],
    SettingsSectionId.about => const <Widget>[AboutSection()],
    SettingsSectionId.appearance => const <Widget>[
      PaletteSection(),
      // **HIGH CONTRAST IS ITS OWN ROW.** It raises every ink to the top of its
      // ramp — an addition to whichever palette is chosen, not a fourth palette
      // — so a shepherd who wants amber AND high contrast can have both.
      _HighContrastRow(),
    ],
    SettingsSectionId.keepScreenOn => const <Widget>[_KeepScreenOnRow()],
    SettingsSectionId.unlock => const <Widget>[UnlockSection()],
    SettingsSectionId.leftHanded => const <Widget>[_LeftHandedRow()],
    _ => const <Widget>[],
  };

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
    SettingsSectionId.unlock => l10n.settingsSectionUnlock,
    SettingsSectionId.diagnostics => l10n.settingsSectionDiagnostics,
    SettingsSectionId.data => l10n.settingsSectionData,
    SettingsSectionId.about => l10n.settingsSectionAbout,
  };
}

/// The three boolean rows, each one `AppSetting` column and one guarded verb.
///
/// They are private classes rather than inline builders because each needs to
/// watch `settingsProvider` for its own value — an inline row would push that
/// watch up to the whole screen and rebuild eleven sections when one boolean
/// moves.
final class _HighContrastRow extends ConsumerWidget {
  const _HighContrastRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return BooleanSettingRow(
      settingKey: 'appearance.high_contrast',
      label: l10n.settingsHighContrast,
      value: _read(ref, (AppSetting s) => s.highContrast),
      spokenOn: l10n.settingsHighContrastOn,
      spokenOff: l10n.settingsHighContrastOff,
      onChanged: (bool on) =>
          ref.read(settingsWriteControllerProvider.notifier).setHighContrast(on: on).ignore(),
    );
  }
}

final class _KeepScreenOnRow extends ConsumerWidget {
  const _KeepScreenOnRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return BooleanSettingRow(
      settingKey: 'keep_screen_on',
      label: l10n.settingsKeepScreenOn,
      value: _read(ref, (AppSetting s) => s.wakelockEnabled),
      spokenOn: l10n.settingsKeepScreenOnStateOn,
      spokenOff: l10n.settingsKeepScreenOnStateOff,
      onChanged: (bool on) =>
          ref.read(settingsWriteControllerProvider.notifier).setWakelockEnabled(on: on).ignore(),
    );
  }
}

final class _LeftHandedRow extends ConsumerWidget {
  const _LeftHandedRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return BooleanSettingRow(
      settingKey: 'left_handed',
      label: l10n.settingsLeftHanded,
      value: _read(ref, (AppSetting s) => s.leftHanded),
      spokenOn: l10n.settingsLeftHandedStateOn,
      spokenOff: l10n.settingsLeftHandedStateOff,
      onChanged: (bool on) =>
          ref.read(settingsWriteControllerProvider.notifier).setLeftHanded(on: on).ignore(),
    );
  }
}

/// **`false` UNTIL THE ROW IS READ, AND IT IS THE HONEST DEFAULT** — every one of
/// these three columns is `withDefault(const Constant(false))`, so an unread
/// setting and an off setting are the same fact. That is not true of the palette,
/// which is why `PaletteSection` renders nothing instead.
bool _read(WidgetRef ref, bool Function(AppSetting) field) => switch (ref.watch(settingsProvider)) {
  AsyncData<AppSetting>(value: final AppSetting s) => field(s),
  _ => false,
};

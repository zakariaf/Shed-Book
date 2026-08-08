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
//
// ---------------------------------------------------------------------------
// THE PAGE (rebuilt 2026-08-08)
// ---------------------------------------------------------------------------
//
// This screen was a `Column` of headings over loose word buttons on black: no
// spine, no margin gutter, no ruled rows, no sticky header. `indelible.md §8`'s
// first claim is that there is ONE scrolling ruled document and twelve screens
// are that document under a different filter — so the screen is now `ShedPage`,
// and every setting is a `ShedRuledRow` like every record on every other page.
//
// **THREE HEADINGS PRINTED OVER NOTHING, AND ALL THREE ARE ANSWERED HERE.**
//
//   * **Terminology** — the words exist and ship as authored defaults; only the
//     EDITING is `v1.1.0` (N29-T03). So the section prints the seven current
//     terms, read-only, and says so. A heading with nothing under it told the
//     shepherd less than the words themselves do.
//   * **Reminders** and **Pens** — nothing behind either one. No reminder row is
//     written in `v1.0.0` (`docs/RELEASE-SCOPE.md`, N24/N25) and no pen bulk-add,
//     rename or reorder exists to reach. A section with no rows is **not
//     printed**: a heading over nothing is a promise the build cannot keep, and
//     the ledger above is where the fact that they are coming belongs.
//   * **Season** — it was never empty. `START A SEASON`, the cycle words and the
//     four percentage definitions all rendered; what made the section read as
//     blank was the two empty headings immediately above it and word buttons that
//     drew their rule the full width of the page, so the one control under
//     `SEASON` looked like a divider. Both are fixed above this line rather than
//     in `season_section.dart`.
//
// **THERE ARE NO THUMB ANCHORS ON THIS SCREEN, AND THAT IS A GAP RATHER THAN A
// DECISION.** `ShedPage.band` is null because Settings has no primary act — but
// `INDEX` is the only navigation affordance in the app (`P3`), and this screen
// has none, so the only way out is the platform back gesture. Giving it one needs
// a band that is `INDEX` alone; `ShedBottomBand` requires a slab.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_page.dart';
import 'package:shed_book/data/models.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/features/settings/settings_write_controller.dart';
import 'package:shed_book/features/settings/widgets/appearance_section.dart';
import 'package:shed_book/features/settings/widgets/about_section.dart';
import 'package:shed_book/features/settings/widgets/data_section.dart';
import 'package:shed_book/features/settings/widgets/diagnostics_section.dart';
import 'package:shed_book/features/settings/widgets/season_section.dart';
import 'package:shed_book/features/settings/widgets/setting_row.dart';
import 'package:shed_book/features/settings/widgets/settings_section.dart';
import 'package:shed_book/features/settings/widgets/terminology_section.dart';
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
    final AppLocalizations l10n = AppLocalizations.of(context);

    return ShedPage(
      // `§7.16`: the sticky 44 pt header, read-only, never a target — it carries
      // no back button, because a 44 pt row is below the 60 pt floor and a target
      // in it would be an illegal one. `ShedPageHeader` uppercases and applies
      // heading level 1, which is why the ARB string stays sentence case.
      header: l10n.settingsTitle,
      // The key stays where it was, on the scrollable: `ensureVisible` and
      // `scrollUntilVisible` in four test files find their scrollable through it.
      scrollKey: const Key('settings.list'),
      children: switch (ref.watch(settingsProvider)) {
        AsyncData<AppSetting>() => _sections(l10n),
        AsyncError<AppSetting>() => _unreadable(l10n),
        // **NEVER A SPINNER** (#71). There is no loading state anywhere in this
        // app; the page colour is the honest first frame. An empty list rather
        // than a `SizedBox.expand()`, which has no height inside a scroll view.
        _ => const <Widget>[],
      },
    );
  }

  /// What the page prints when `app_settings` cannot be read.
  ///
  /// **NOT `ShedEmptyState`, AND THE REASON IS MECHANICAL BEFORE IT IS A
  /// DESIGN ARGUMENT.** That component is `SizedBox(height: double.infinity)` by
  /// construction — *"it fills its parent"* is the whole of how an empty state
  /// occupies the same box the populated content will. Inside `ShedPage`'s
  /// scrolling stream the parent's height is **unbounded**, so it throws
  /// *"BoxConstraints forces an infinite height"* on the first layout pass.
  /// Measured on 2026-08-08: eighteen exceptions per pump, because this arm
  /// renders on frame 1 of every launch (see below).
  ///
  /// So the failure is printed the way P2 prints every other statement in this
  /// app — **in ink, in the ruling**, one line in the document rather than a
  /// panel over it.
  ///
  /// **AND DIAGNOSTICS AND ABOUT STAY UNDER IT**, which `07 §14.2` asks for in as
  /// many words — *"the standard panel replaces the section list only.
  /// Diagnostics stays reachable, because a database read failure is exactly
  /// when someone needs it"* — and which the full-page panel made impossible.
  /// Neither section reads `app_settings`: `DiagnosticsSection` reads the log
  /// and touches the repository only on a press, and `AboutSection` is const
  /// copy. They are the two things a shepherd needs when this arm is reached.
  ///
  /// **FRAME 1 REACHES THIS ARM AND THE SENTENCE IS NOT TRUE YET.**
  /// `settingsProvider` derives from `databaseProvider`, and a derived provider
  /// whose source is still loading surfaces as `AsyncError` — so *"Settings could
  /// not be read."* prints for one frame on every launch, before anything has
  /// tried to read it. That is a defect in the provider's shape rather than in
  /// this screen, it predates this layout, and it is not fixed here: telling the
  /// two states apart needs `settingsProvider` to distinguish *the database is
  /// not open yet* from *the row could not be read*.
  List<Widget> _unreadable(AppLocalizations l10n) => <Widget>[
    SettingLine(text: l10n.settingsUnavailable, textKey: const Key('settings.error')),
    for (final SettingsSectionId id in <SettingsSectionId>[
      SettingsSectionId.diagnostics,
      SettingsSectionId.about,
    ])
      SettingsSection(
        key: Key('settings.section.${id.name}'),
        title: _title(l10n, id),
        rows: _rows(id),
      ),
  ];

  /// The sections that have something under them, in `§14.3`'s order.
  ///
  /// **A SECTION WITH NO ROWS IS DROPPED, NOT PRINTED EMPTY.** It used to render
  /// as a heading with a rule under it, on the reading that *"the setting exists
  /// and is not yet reachable here"* is honest. Looking at the running app that
  /// reading does not survive: three consecutive headings with nothing between
  /// them read as a screen that failed to load, and the shepherd cannot tell
  /// *not built yet* from *broken*. The ledger at the top of this file is where a
  /// section's absence is recorded, and it is read by the person who can act on
  /// it.
  List<Widget> _sections(AppLocalizations l10n) {
    final List<Widget> out = <Widget>[];
    for (final SettingsSectionId id in kSettingsSections) {
      final List<Widget> rows = _rows(id);
      if (rows.isEmpty) {
        continue;
      }
      out.add(
        SettingsSection(
          key: Key('settings.section.${id.name}'),
          title: _title(l10n, id),
          rows: rows,
        ),
      );
    }
    return out;
  }

  /// What each section holds today.
  List<Widget> _rows(SettingsSectionId id) => switch (id) {
    // **NO TEMPERATURE CONTROL BESIDE IT, AND THAT IS RULED.** §7.0 row 11: no
    // `v1.0.0` table stores a temperature, so `AppSettings` carries no
    // `temperature_unit` column and a segmented line for one would be a setting
    // for a value that does not exist. `§8`'s mockup prints a `TEMPERATURE`
    // section head; this build has nothing to put under it.
    SettingsSectionId.units => const <Widget>[UnitsSection()],
    // **THE WORDS SHIP; ONLY THE EDITING WAITS** (`docs/RELEASE-SCOPE.md`,
    // N29-T03). Read-only is more than the heading over nothing that was here.
    SettingsSectionId.terminology => const <Widget>[TerminologySection()],
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
      // **THE TWO-VOICES NOTE, WHICH `§8` PUTS DIRECTLY UNDER THE THEME BUTTONS
      // AND NOTHING IN THIS APP HAD EVER PRINTED.** It is here rather than in
      // About because it explains what the shepherd is looking at on the line
      // above: the palette they just chose renders both voices.
      _VoicesNote(),
    ],
    SettingsSectionId.keepScreenOn => const <Widget>[_KeepScreenOnRow()],
    SettingsSectionId.unlock => const <Widget>[UnlockSection()],
    SettingsSectionId.leftHanded => const <Widget>[_LeftHandedRow()],
    // Reminders (N24/N25) and Pens (`§14.3` row 5) have nothing behind them in
    // this release, so `_sections` drops them rather than printing a heading.
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

/// `§8`'s two-voices line, plus the one documented exception (`§3.5` rule 5).
///
/// **IT IS NOT `§8`'S SENTENCE, AND COPYING THAT SENTENCE WOULD SHIP A CLAIM THAT
/// IS NO LONGER TRUE.** `§8` reads *"IF IT IS SERIF, IT HAPPENED. IF IT IS SANS,
/// IT IS A THING YOU CAN PRESS."* — written when two faces were planned. P7
/// (2026-08-02) closed that: one family ships, Atkinson Hyperlegible Next, which
/// is a sans, and `§1.2` rule 2 was amended to the axis that actually shipped —
/// **sentence case means it happened, capitals mean it is a thing you can
/// press.** Nothing on this screen is serif, so the original line would be the
/// app describing a typeface it does not have.
///
/// The exception survives verbatim in substance: the keypad digits are set in the
/// record voice so the digit you press is the shape that prints. `§3.5` requires
/// it to be documented **here**, beside the two-voices line, *"because an
/// unexplained exception is a bug."*
final class _VoicesNote extends StatelessWidget {
  const _VoicesNote();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SettingLine(
          key: const Key('settings.appearance.voices'),
          text: l10n.settingsAppearanceVoices,
        ),
        SettingLine(
          key: const Key('settings.appearance.keypad_voice'),
          text: l10n.settingsAppearanceKeypadVoice,
          muted: true,
        ),
      ],
    );
  }
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
      // **LABELLED, BECAUSE IT IS THE SECOND ROW IN ITS SECTION.** The Appearance
      // heading says `APPEARANCE`; it cannot also say which of the two rows under
      // it this is.
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
      // **NO LABEL: THE SECTION HEADING IS THE LABEL.** `KEEP SCREEN ON` printed
      // over a row reading `KEEP SCREEN ON` is the same word twice on two lines
      // that share an edge.
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

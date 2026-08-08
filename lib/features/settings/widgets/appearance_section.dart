// lib/features/settings/widgets/appearance_section.dart
//
// Sections 6, 7 and 8 of `07 §14.3` — the palette, high contrast, the wakelock
// and the left-handed mirror. Four settings that share one shape: a word, a
// state, and one tap to change it.
//
// **THE THREE PALETTE IDS ARE FROZEN** (R35). `night`, `amber` and `red` are
// stored keys, and `deepRed`'s key is `red` — a two-word label over a one-word
// key, which is exactly the kind of thing that gets "tidied" into a mismatch.
// Supply values, never a new palette id.
//
// **HIGH CONTRAST IS AN ADDITION, NOT A FOURTH PALETTE.** It raises every ink to
// the top of its ramp, which is why it is its own row rather than a fourth word
// on the line above — a shepherd who wants amber AND high contrast must be able
// to have both.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/models.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/features/settings/settings_write_controller.dart';
import 'package:shed_book/features/settings/widgets/setting_row.dart';
import 'package:shed_book/l10n/app_localizations.dart';

/// The palette line.
final class PaletteSection extends ConsumerWidget {
  const PaletteSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppSetting? settings = switch (ref.watch(settingsProvider)) {
      AsyncData<AppSetting>(value: final AppSetting s) => s,
      _ => null,
    };
    if (settings == null) {
      // **NOTHING, NOT A DEFAULT.** Rendering `NIGHT` as selected before the row
      // has been read would show the shepherd a choice they did not make, and
      // for one frame it would be wrong for anyone who chose otherwise.
      //
      // **THE BOX STILL OCCUPIES A ROW.** `§14.2`'s frame-1 rule is that the
      // sections are static and only the values wait; a zero-height box here
      // would move every row below it the instant the settings row landed.
      return SizedBox(height: t.tapIndelible);
    }

    return SettingRow(
      label: l10n.settingsPaletteLabel,
      control: Wrap(
        // **`gapMin`, NOT HALF OF IT — R86.** These were 8, which is the exact
        // middle of the band the separation rule forbids: touching is legal,
        // 16 is legal, and 8 is a thumb landing between two settings and
        // getting whichever one the hit test reached first. Six Settings cells
        // of N33-T03's geometric sweep said so.
        spacing: t.gapMin,
        runSpacing: t.gapMin,
        children: <Widget>[
          for (final ({ShedPaletteId id, String label}) choice
              in <({ShedPaletteId id, String label})>[
                (id: ShedPaletteId.night, label: l10n.settingsPaletteNight),
                (id: ShedPaletteId.amber, label: l10n.settingsPaletteAmber),
                (id: ShedPaletteId.deepRed, label: l10n.settingsPaletteDeepRed),
              ])
            ShedWordButton(
              key: Key('settings.appearance.palette.${choice.id.key}'),
              label: choice.label,
              selected: settings.palette == choice.id.key,
              semanticLabel: l10n.settingsPaletteSemantics(palette: choice.label),
              onTap: () => ref
                  .read(settingsWriteControllerProvider.notifier)
                  .setPalette(choice.id.key)
                  .ignore(),
            ),
        ],
      ),
    );
  }
}

/// One boolean setting, as a word that carries its own state.
///
/// **NOT A `Switch`.** Material's is a drag target with a tap fallback, and drag
/// is banned outright (`06 §7`) — a control whose primary gesture the app does
/// not support is a control that teaches the wrong thing. A word button carries
/// `selected`, which a screen reader announces itself.
///
/// **THE WORD ON THE BUTTON IS THE VALUE NOW, NOT THE SETTING'S NAME.** It used
/// to read `HIGH CONTRAST` with the state carried only by `selected` — a filled
/// word versus an unfilled one — which is `§7.13`'s *Selected* rendering doing a
/// job it was never given. A shepherd looking at one word could not tell whether
/// it named the setting or its state, and there was nothing on the line that
/// said `ON` or `OFF`.
///
/// `§7.12`'s shape settles it: the **label is above the rule**, the **value sits
/// on it**. So the name goes to [SettingRow.label] (or to the section heading,
/// where the heading already is the name) and the button prints `ON` / `OFF`.
/// The spoken form is unchanged, and so is the write.
///
/// **`settingsKeepScreenOn` AND `settingsLeftHanded` WERE DELETED FROM THE ARB IN
/// THE SAME CHANGE**, because sections 7 and 8 take their name from the section
/// heading and nothing rendered those two messages any more. The orphan sweep
/// could not have told anybody: it looks for the literal `.<key>` in `lib/`, and
/// `.settingsKeepScreenOn` is a substring of `.settingsKeepScreenOnStateOn`,
/// which is still called. Every `foo` / `fooStateOn` pair in the catalogue has
/// the same blind spot.
final class BooleanSettingRow extends ConsumerWidget {
  const BooleanSettingRow({
    required this.settingKey,
    required this.value,
    required this.spokenOn,
    required this.spokenOff,
    required this.onChanged,
    super.key,
    this.label,
  });

  final String settingKey;

  /// `null` where the section heading is already the setting's name — sections
  /// 7 and 8, which hold one row each.
  final String? label;
  final bool value;
  final String spokenOn;
  final String spokenOff;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return SettingRow(
      label: label,
      control: ShedWordButton(
        key: Key('settings.$settingKey'),
        label: value ? l10n.settingsStateOn : l10n.settingsStateOff,
        selected: value,
        // **THE SPOKEN FORM IS A SENTENCE, NOT A LABEL PLUS A STATE WORD.**
        // The node already carries `selected`; appending *"on"* to the label
        // would have a screen reader say it twice, which `10 §3.2` rule 2
        // names as the noise users report. It is also the only place the
        // setting's NAME is spoken now that the button prints its value.
        semanticLabel: value ? spokenOn : spokenOff,
        onTap: () => onChanged(!value),
      ),
    );
  }
}

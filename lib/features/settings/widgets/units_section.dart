// lib/features/settings/widgets/units_section.dart
//
// **UNITS ARE A DISPLAY CHOICE AND NOTHING ELSE.** Decision #56: one canonical
// unit is stored — grams — and display units are computed at the edge. Switching
// this rewrites **no row**: the same `int` is in the column before and after, and
// the test asserts it is identical rather than close to.
//
// The implementation this exists to prevent converts on write. It looks correct,
// it passes every rendering test, and it loses precision on every switch — after
// four changes of mind a 4,300 g lamb is not 4,300 g any more, and nothing on
// screen ever said so.
//
// **THERE IS NO TEMPERATURE CONTROL, AND THAT IS RULED RATHER THAN MISSING.**
// `03 §5`'s `AppSettings` carries no `temperature_unit` column — ruled 2026-08-01
// (§7.0 row 11): no `v1.0.0` table stores a temperature, so a unit for it would
// be a setting for a value that does not exist. `indelible.md §8` screen 12 draws
// two segmented lines; it gets one, and the second lands with whatever first
// stores a temperature.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/units/weight_unit.dart';
import 'package:shed_book/features/settings/settings_write_controller.dart';
import 'package:shed_book/l10n/app_localizations.dart';

final class UnitsSection extends ConsumerWidget {
  const UnitsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);

    // **`unitsProvider`, NOT `settingsProvider`** (R68). It is a `Provider`
    // derived from the settings stream, so the screen does not carry a second
    // `AsyncValue` for a value that is always present.
    final WeightUnit current = ref.watch(unitsProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 2),
      child: Wrap(
        // **`gapMin`, NOT HALF OF IT — R86.** These were 8, which is the exact
        // middle of the band the separation rule forbids: touching is legal,
        // 16 is legal, and 8 is a thumb landing between two settings and
        // getting whichever one the hit test reached first. Six Settings cells
        // of N33-T03's geometric sweep said so.
        spacing: t.gapMin,
        runSpacing: t.gapMin,
        children: <Widget>[
          for (final ({WeightUnit unit, String label, String spoken}) choice
              in <({WeightUnit unit, String label, String spoken})>[
                (
                  unit: WeightUnit.kg,
                  label: l10n.settingsUnitsWeightKg,
                  spoken: l10n.settingsUnitsWeightKgSpoken,
                ),
                (
                  unit: WeightUnit.lb,
                  label: l10n.settingsUnitsWeightLb,
                  spoken: l10n.settingsUnitsWeightLbSpoken,
                ),
              ])
            ShedWordButton(
              key: Key('settings.units.weight.${choice.unit.key}'),
              label: choice.label,
              // **TWO CHANNELS, NEITHER OF THEM HUE ALONE** (#106,
              // `indelible.md §7.9`): `ShedWordButton` draws the selected state
              // as a fill change AND a madder underline, so it survives the OS
              // grayscale filter.
              selected: current == choice.unit,
              // The spoken noun, because a screen reader reads `KG` as two
              // letters — and no state word in it, since the node carries
              // `selected` and announcing it twice is the noise `10 §3.2` rule 2
              // names.
              semanticLabel: l10n.settingsUnitsWeightSemantics(unit: choice.spoken),
              onTap: () => ref
                  .read(settingsWriteControllerProvider.notifier)
                  .setWeightUnit(choice.unit)
                  .ignore(),
            ),
        ],
      ),
    );
  }
}

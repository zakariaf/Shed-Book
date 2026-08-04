// lib/features/settings/widgets/season_section.dart
//
// Section 4 of `07 §14.3`: which season the app is writing into, and starting
// the next one.
//
// **SWITCHING SEASONS INVALIDATES NOTHING.** Every screen reads its season
// through `settingsProvider`, a stream over `app_settings` — so writing that
// column re-runs every dependent statement on its own. `ref.invalidate` here
// would be the easy way, and it is the one that leaves a screen showing last
// season's numbers the first time the invalidation list falls behind the
// screens.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/models.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/settings/settings_write_controller.dart';
import 'package:shed_book/l10n/app_localizations.dart';

final class SeasonSection extends ConsumerWidget {
  const SeasonSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toLanguageTag();

    final AppSetting? settings = switch (ref.watch(settingsProvider)) {
      AsyncData<AppSetting>(value: final AppSetting s) => s,
      _ => null,
    };
    final List<Season> seasons = switch (ref.watch(seasonsProvider)) {
      AsyncData<List<Season>>(value: final List<Season> l) => l,
      _ => const <Season>[],
    };

    if (settings == null || seasons.isEmpty) {
      // **A FRESH NOTEBOOK HAS NO SEASON, AND THAT IS NORMAL.** `seedFirstRun`
      // deliberately writes none (#42) — a season is the shepherd's first act,
      // not the installer's.
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 2),
        child: Text(
          l10n.settingsSeasonNone,
          key: const Key('settings.season.none'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final Season season in seasons)
            Padding(
              padding: EdgeInsets.only(bottom: t.gapMin / 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ShedWordButton(
                  key: Key('settings.season.${season.id}'),
                  // The current one prints its start date; the others print
                  // their label alone, because a list of dates is a list nobody
                  // reads at 9am.
                  label: settings.currentSeason == season.id
                      ? l10n.settingsSeasonCurrent(
                          label: season.label,
                          // **NEVER ALL-NUMERIC** (R60): `1 Jan 2026`, not
                          // `01/01/2026`, which reads as a different day on two
                          // sides of an ocean.
                          date: formatShedDate(season.startDate, locale),
                        )
                      : l10n.settingsSeasonSwitch(label: season.label),
                  selected: settings.currentSeason == season.id,
                  // It names the CONSEQUENCE — which season tonight's records
                  // land in — rather than the act.
                  semanticLabel: l10n.settingsSeasonSwitchSemantics(label: season.label),
                  onTap: () => ref
                      .read(settingsWriteControllerProvider.notifier)
                      .switchSeason(SeasonId(season.id))
                      .ignore(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

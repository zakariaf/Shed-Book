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
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/write_action.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/terminology/animal_class.dart';
import 'package:shed_book/domain/terminology/term_label.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/features/settings/settings_write_controller.dart';
import 'package:shed_book/l10n/app_localizations.dart';

final class SeasonSection extends ConsumerStatefulWidget {
  const SeasonSection({super.key});

  @override
  ConsumerState<SeasonSection> createState() => _SeasonSectionState();
}

class _SeasonSectionState extends ConsumerState<SeasonSection> {
  /// The cap refusal, printed **in the section**.
  ///
  /// **NOT `showCapRow`, AND THAT IS A MEASUREMENT RATHER THAN A PREFERENCE.**
  /// `showCapRow` writes into `ShedReceiptScope`, and Settings has none — so the
  /// call would compile, run, guard correctly and render nothing at all, which
  /// is the worst of the three possible outcomes. The refusal goes where P2 puts
  /// every other confirmation: in ink, in the section, one line under the act.
  String? _refused;

  @override
  Widget build(BuildContext context) {
    final WidgetRef ref = this.ref;
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
      //
      // **AND UNTIL 2026-08-05 IT WAS ALSO A DEAD END.** This arm printed the
      // sentence and nothing else, and `startSeason` — which exists in
      // `SeasonRepository` and in `SettingsWriteController` — had no caller
      // anywhere in `lib/`. So a fresh install could not start a season, and
      // `LambingRepository._currentSeason()` refuses to invent one on the 3am
      // path, correctly. **Measured**: on a fresh notebook, tapping 4-1-2,
      // confirm, Lambing recorded nothing and said nothing.
      //
      // A shepherd's first night with this app did nothing at all. `07 §14.3`
      // row 4 specified this row and it was never built.
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.settingsSeasonNone,
              key: const Key('settings.season.none'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: t.gapMin),
            _startRow(l10n, locale),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // **THE ROW `07 §14.3` ROW 4 ASKED FOR AND NOBODY BUILT.** It is
          // calm-gated — `EntryContext.calm` in the controller — because
          // starting a season is daylight work and the one other place the free
          // tier may honestly refuse.
          Align(alignment: Alignment.centerLeft, child: _startRow(l10n, locale)),
          if (_refused case final String said)
            Padding(
              padding: EdgeInsets.only(top: t.gapMin / 2, bottom: t.gapMin),
              child: Text(
                said,
                key: const Key('settings.season.refused'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.textSecondary),
              ),
            ),
          SizedBox(height: t.gapMin),

          for (final Season season in seasons)
            Padding(
              // **`gapMin`, NOT HALF — R86.** These season buttons switch which
              // season a night's records are written into, and they were 8 pt
              // apart: the exact middle of the forbidden band, on the one
              // control in Settings where the wrong tap misfiles a season.
              padding: EdgeInsets.only(bottom: t.gapMin),
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

  /// `START A SEASON`, and the two values it supplies without asking.
  ///
  /// **THE LABEL IS THIS YEAR AND THE START DATE IS TODAY, AND NEITHER IS A
  /// DECISION THE APP IS MAKING FOR THE SHEPHERD.** A season's label is a year,
  /// which is a fact about the calendar rather than a judgement; its start date
  /// is the day they started it, which is the day they pressed this. Both are
  /// changeable afterwards through the season's own controls.
  ///
  /// The alternative — a text field and a date picker before a shepherd can
  /// record anything — is spec §7.1 exactly backwards: *never block an entry to
  /// make the user go and set something up first.* This row is already one step
  /// further from the record than that sentence wants; asking two questions
  /// inside it would be two more.
  ///
  /// **`formatShedYear`, NOT `formatShedCount`.** A grouped year prints `2,026`,
  /// and the label is the string a shepherd reads for the rest of the season.
  Widget _startRow(AppLocalizations l10n, String locale) => ShedWordButton(
    key: const Key('settings.season.start'),
    label: l10n.settingsSeasonStart,
    semanticLabel: l10n.settingsSeasonStart,
    selected: false,
    onTap: () async {
      final LocalDate today = LocalDate.of(appNow());
      await ref
          .read(settingsWriteControllerProvider.notifier)
          .startSeason(label: formatShedYear(today.year, locale), startDate: today);

      if (!mounted) {
        return;
      }
      // The refusal is read off the controller's state rather than returned,
      // because `guard()` owns the outcome — one shape for every write (#13).
      final WriteState state = ref.read(settingsWriteControllerProvider);
      setState(() {
        _refused = switch (state) {
          WriteDone(outcome: WriteRefused(reason: final RefusalReason r)) => _refusalCopy(r),
          _ => null,
        };
      });
    },
  );

  /// The cap refusal, in this section's own words.
  ///
  /// **A SECOND SWITCH, AND THE LAYER RULES ARE RIGHT TO FORCE IT.** Flock has
  /// `capRefusalCopy` and this cannot call it: `layer.sibling` bans one feature
  /// importing another, `lib/data/` may not import `lib/l10n/`, and
  /// `lib/core/ui/` is deliberately denied that edge too — *a shared component
  /// renders what it is handed and never resolves copy*, which is the rule that
  /// forced `ShedKeypad`'s four label parameters.
  ///
  /// So there is no legal home for a shared copy resolver, and the mitigation is
  /// not to invent one: `test/features/settings_test.dart` asserts the two
  /// switches produce the same sentence for the same reason. Two
  /// implementations with a test between them is honest; two implementations
  /// nobody compares is the thing to avoid.
  ///
  /// **THE CAP IS A PLACEHOLDER, NEVER A TYPED NUMBER.** `kFreeEweCap` is the
  /// source; a literal goes stale the day it moves, in the one sentence a paying
  /// user reads most carefully.
  String _refusalCopy(RefusalReason reason) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TermLabel term =
        ref.read(terminologyProvider).overrideFor(AnimalClass.ewe) ??
        TermLabel(l10n.termEweSingular, l10n.termEwePlural);
    return switch (reason) {
      RefusalReason.eweCap => l10n.capRefusedEweCap(cap: kFreeEweCap, term: term.plural),
      RefusalReason.secondSeason => l10n.capRefusedSecondSeason,
    };
  }
}

// lib/features/settings/widgets/season_section.dart
//
// Section 4 of `07 §14.3`: which season the app is writing into, and starting
// the next one.
//
// **IT WAS REPORTED AS A HEADING WITH NOTHING UNDER IT, AND IT NEVER WAS ONE.**
// Pumped on 2026-08-08 against a fresh notebook, the section rendered *"No season
// started."* and `START A SEASON`; against a seeded one it rendered the start
// row, `CYCLE 17 DAYS` with its two words, all four percentage definitions and a
// row per season. Every one of those was on the page.
//
// What made it read as empty was two things, and neither of them is in this file:
// **Terminology and Reminders printed empty headings immediately above it**, so
// three section heads ran together and the eye attached the content to the wrong
// one; and until R87 every `ShedWordButton` drew its rule the full width of the
// page, so a lone `START A SEASON` under a heading looked like a divider rather
// than a control. Both are fixed in `settings_screen.dart` and in the component.
// The change here is the ledger shape: every line is a `ShedRuledRow`.
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
import 'package:shed_book/core/ui/components/shed_ruled_row.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/models.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/write_action.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/stats/definitions.dart';
import 'package:shed_book/domain/terminology/animal_class.dart';
import 'package:shed_book/domain/terminology/term_label.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/features/settings/settings_write_controller.dart';
import 'package:shed_book/features/settings/widgets/setting_row.dart';
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SettingLine(text: l10n.settingsSeasonNone, textKey: const Key('settings.season.none')),
          SettingRow(control: _startRow(l10n, locale)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // **THE ROW `07 §14.3` ROW 4 ASKED FOR AND NOBODY BUILT.** It is
        // calm-gated — `EntryContext.calm` in the controller — because
        // starting a season is daylight work and the one other place the free
        // tier may honestly refuse.
        SettingRow(control: _startRow(l10n, locale)),
        if (_refused case final String said)
          SettingLine(text: said, textKey: const Key('settings.season.refused'), muted: true),

        // **THE CYCLE, AND THE DEFAULT IS THE SHEPHERD'S RATHER THAN THE
        // APP'S.** `lambingSpread` reads `cycle_days` to say how many ewes
        // lambed in the first cycle, and its own doc is blunt that the
        // parameter *"has a default and the app must never use it"* — 17 is
        // what `onCreate` seeds, and this row is how a shepherd whose tup
        // ratio says otherwise changes it.
        //
        // **STORED NOW, READ IN JUNE.** Season Summary is `v1.1.0` (N28), and
        // the season this number describes is happening now — a setting a
        // shepherd cannot reach until after the season it applies to is a
        // setting that arrives too late to be true.
        //
        // Two words rather than a stepper: `indelible.md §6` has no icon set,
        // and hold-to-repeat is a banned gesture. One press, one day.
        //
        // **THE FIGURE IS THE ROW'S LABEL NOW, NOT A LINE ABOVE A GAP.**
        // `§7.12`: the label states what is set and the control sits on the
        // rule under it, so the count and the two words that change it are one
        // 88 pt line instead of three loose ones.
        SettingRow(
          key: const Key('settings.season.cycle'),
          label: l10n.settingsSeasonCycleDays(days: formatShedCount(settings.cycleDays, locale)),
          control: Wrap(
            spacing: t.gapMin,
            runSpacing: t.gapMin,
            children: <Widget>[
              for (final ({String key, String label, int delta}) step
                  in <({String key, String label, int delta})>[
                    (key: 'shorter', label: l10n.settingsSeasonCycleShorter, delta: -1),
                    (key: 'longer', label: l10n.settingsSeasonCycleLonger, delta: 1),
                  ])
                ShedWordButton(
                  key: Key('settings.season.cycle.${step.key}'),
                  label: step.label,
                  semanticLabel: step.label,
                  selected: false,
                  // **CLAMPED, AND THE FLOOR IS NOT A JUDGEMENT.** A cycle of
                  // zero or of a year is not a shorter cycle, it is a number
                  // that breaks the spread's arithmetic — so the control cannot
                  // produce one. It is a range on a count, not a suggestion
                  // about sheep.
                  onTap: () => ref
                      .read(settingsRepositoryProvider)
                      .setCycleDays((settings.cycleDays + step.delta).clamp(1, 60))
                      .ignore(),
                ),
            ],
          ),
        ),

        // **WHICH PERCENTAGE, STATED RATHER THAN PICKED.** There are four
        // honest definitions and they give different numbers off the same
        // flock — *born alive per ewe to the ram* and *reared per ewe to the
        // ram* can be twenty points apart in a hard year. The app does not
        // choose; it says which one it is using, in the shepherd's own words,
        // and the four sentences are the domain's rather than this file's.
        //
        // **FOUR WHOLE-ROW CHOICES, NOT FOUR STACKED WORD BUTTONS.** The
        // definitions are sentences — *"lambs born incl. stillborn per ewe put
        // to the ram"* — and a sentence inside a word button ellipsised at one
        // line on every device, so three of the four choices read as the same
        // truncated phrase. As ruled rows they have the record column's full
        // width, they share edges (R86's other legal separation) and the row IS
        // the target, which is 64 x the record width rather than 64 x the word.
        _ChoiceHeading(label: l10n.settingsSeasonPercentage),
        for (final LambingPercentageChoice choice in LambingPercentageChoice.values)
          _PercentageChoiceRow(
            key: Key('settings.season.percentage.${choice.key}'),
            definition: choice.definition,
            inUse: settings.percentageDefinition == choice.key,
            inUseStamp: l10n.settingsSeasonPercentageInUse,
            onTap: () =>
                ref.read(settingsRepositoryProvider).setPercentageDefinition(choice).ignore(),
          ),

        for (final Season season in seasons)
          _SeasonChoiceRow(
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
            current: settings.currentSeason == season.id,
            inUseStamp: l10n.settingsSeasonPercentageInUse,
            // It names the CONSEQUENCE — which season tonight's records
            // land in — rather than the act.
            semanticLabel: l10n.settingsSeasonSwitchSemantics(label: season.label),
            onTap: () => ref
                .read(settingsWriteControllerProvider.notifier)
                .switchSeason(SeasonId(season.id))
                .ignore(),
          ),
      ],
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

/// The line that says what the rows under it are choosing between.
///
/// **A READ-ONLY RULED ROW, NOT A `ShedSectionHeading`.** `10 §3.4`'s heading
/// table has exactly two levels and both are spoken for — the screen title is 1
/// and every Settings section head is 2 — so a third heading inside a section
/// would either invent a level 3 the component asserts against, or add a second
/// level-2 stop that a screen-reader user would land on expecting a new section.
final class _ChoiceHeading extends StatelessWidget {
  const _ChoiceHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    return ShedRuledRow(
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: t.textSecondary),
        ),
      ),
    );
  }
}

/// One lambing-percentage definition, as one ruled line.
///
/// **THE MARGIN CELL CARRIES THE STATE, AND IT IS A WORD** (`§1.2` rule 3 —
/// meaning is carried by form first, hue never alone). The chosen definition
/// takes an `IN USE` stamp in the 68 pt margin and its sentence goes to the
/// heavier role; the others carry neither. Three channels — a word, a position
/// and a weight — none of which is a colour, so the row survives the OS
/// grayscale filter and a head torch equally.
final class _PercentageChoiceRow extends StatelessWidget {
  const _PercentageChoiceRow({
    required this.definition,
    required this.inUse,
    required this.inUseStamp,
    required this.onTap,
    super.key,
  });

  final String definition;
  final bool inUse;
  final String inUseStamp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ShedRuledRow(
      height: kRuledRowTall,
      onTap: onTap,
      // No state word in the label — the node carries `selected` and a screen
      // reader announces it once (`10 §3.2` rule 2).
      semanticLabel: definition,
      selected: inUse,
      margin: inUse ? _InUseStamp(label: inUseStamp) : null,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          definition,
          // **NOT ELLIPSISED, AND THAT IS WHY IT IS A ROW.** Three of the four
          // definitions differ only in their last four words; a single clipped
          // line would print the same phrase three times.
          style: inUse ? text.titleMedium : text.bodyMedium,
        ),
      ),
    );
  }
}

/// One season, as one ruled line. Pressing it moves where tonight's records land.
final class _SeasonChoiceRow extends StatelessWidget {
  const _SeasonChoiceRow({
    required this.label,
    required this.current,
    required this.inUseStamp,
    required this.semanticLabel,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool current;
  final String inUseStamp;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ShedRuledRow(
      height: kRuledRowTall,
      onTap: onTap,
      semanticLabel: semanticLabel,
      selected: current,
      margin: current ? _InUseStamp(label: inUseStamp) : null,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(label, style: current ? text.titleMedium : text.bodyMedium),
      ),
    );
  }
}

/// The margin stamp. `§3.4` permits sub-18 px type only for a stamp, and only
/// when it is never the sole carrier of its meaning — here the sentence beside it
/// is also in the heavier role, so removing the stamp loses nothing.
final class _InUseStamp extends StatelessWidget {
  const _InUseStamp({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.gapMin / 2),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

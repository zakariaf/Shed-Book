// lib/features/settings/widgets/terminology_section.dart
//
// **SECTION 2 OF `07 §14.3`, AND IT PRINTED A HEADING OVER NOTHING.**
//
// The reading that put it there was reasonable: editing the overlay is N29-T03
// and ships in `v1.1.0` (`docs/RELEASE-SCOPE.md`), so there was no control to
// draw. What that reading missed is that **the words themselves are not
// deferred** — the release-scope entry says so in as many words: *"the authored
// defaults ship in `v1.0.0` and every screen already reads `terminologyProvider`
// … they simply cannot be changed yet."*
//
// So the section prints the seven words it is currently using. That is strictly
// more than the heading said, it is the fact a shepherd opening `TERMINOLOGY`
// came to find, and it is true in both releases — in June the same rows gain an
// edit affordance and nothing else about them moves.
//
// **READ-ONLY IS RENDERED AS READ-ONLY, NOT AS DISABLED.** `indelible.md §7.13`
// has no disabled state worth the name — *"avoided; where genuinely impossible,
// `--ink-low` with a dotted underline and a printed reason beside it"* — and a
// greyed-out text field is the worst of both: it looks like a control, refuses
// the tap, and explains nothing. These are `SettingLine`s. There is no target on
// them at all, so there is nothing to press and nothing to be disappointed by,
// and the line above them says why.
//
// ---------------------------------------------------------------------------
// WHY THE ARB IS READ DIRECTLY RATHER THAN THROUGH `Terminology.labelFor`
// ---------------------------------------------------------------------------
//
// `terminologyProvider` is `const Terminology({}, {})` until N29 wires the
// defaults, so `labelFor` ends in `_defaults[c]!` and **throws**. That trap is
// recorded on the domain type itself and worked around the same way in
// `lambing_entry_screen.dart` and in `season_section.dart`: ask
// `overrideFor` — which returns `null` rather than throwing — and fall back to
// the ARB message, which is the source those defaults will be seeded from.
//
// The moment N29 fills the map, `overrideFor` starts answering and this file
// keeps working unchanged.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/terminology/animal_class.dart';
import 'package:shed_book/domain/terminology/term_label.dart';
import 'package:shed_book/domain/terminology/terminology.dart';
import 'package:shed_book/features/settings/widgets/setting_row.dart';
import 'package:shed_book/l10n/app_localizations.dart';

final class TerminologySection extends ConsumerWidget {
  const TerminologySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Terminology terms = ref.watch(terminologyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SettingLine(
          key: const Key('settings.terminology.note'),
          text: l10n.settingsTerminologyNote,
          muted: true,
        ),
        // **SEVEN, NOT `§8`'S FIVE.** The mockup lists `EWE`, `GIMMER`,
        // `SHEARLING`, `THEAVE`, `HOGGET` — but four of those five are the SAME
        // class under four county names, which is the whole reason `AnimalClass`
        // is a closed set of concepts with the words as an overlay. The rows are
        // driven off `AnimalClass.values`, so a class added to the domain cannot
        // silently go unprinted here.
        for (final AnimalClass c in AnimalClass.values)
          SettingLine(
            key: Key('settings.terminology.${c.name}'),
            // **BOTH FORMS ON THE LINE, AND THE PLURAL IS NEVER DERIVED.** `10
            // §8.5`: a plural guessed by appending an `s` gives *"3 sheeps"*,
            // and `tup/tups` against `ox/oxen` is why no rule works. The pair is
            // what the shepherd will eventually type, so the pair is what the
            // page shows.
            text: l10n.settingsTerminologyPair(
              singularTerm: _label(l10n, terms, c).singular,
              pluralTerm: _label(l10n, terms, c).plural,
            ),
          ),
      ],
    );
  }

  /// The shepherd's word if they have one, otherwise the shipped default.
  ///
  /// Exhaustive over `AnimalClass` with no `default:` — an eighth class must fail
  /// to compile here rather than print an empty line. The fourteen ARB messages
  /// are the parity `terminology_survives_a_rename_test.dart` holds.
  TermLabel _label(AppLocalizations l10n, Terminology terms, AnimalClass c) =>
      terms.overrideFor(c) ??
      switch (c) {
        AnimalClass.ewe => TermLabel(l10n.termEweSingular, l10n.termEwePlural),
        AnimalClass.maidenFemale => TermLabel(
          l10n.termMaidenFemaleSingular,
          l10n.termMaidenFemalePlural,
        ),
        AnimalClass.eweLamb => TermLabel(l10n.termEweLambSingular, l10n.termEweLambPlural),
        AnimalClass.ram => TermLabel(l10n.termRamSingular, l10n.termRamPlural),
        AnimalClass.ramLamb => TermLabel(l10n.termRamLambSingular, l10n.termRamLambPlural),
        AnimalClass.wether => TermLabel(l10n.termWetherSingular, l10n.termWetherPlural),
        AnimalClass.lamb => TermLabel(l10n.termLambSingular, l10n.termLambPlural),
      };
}

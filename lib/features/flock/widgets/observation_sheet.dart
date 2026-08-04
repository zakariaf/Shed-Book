// lib/features/flock/widgets/observation_sheet.dart
//
// **WHAT THE SHEPHERD SAW, FROM THEIR OWN VOCABULARY.** The options are exactly
// the non-hidden `ewe_observation` rows — six seeded, user-extensible, each
// renameable — and the app never adds a seventh on their behalf.
//
// **AN OBSERVATION IS A RECORD, NEVER A DIAGNOSIS** (§12.2's origination line).
// *"Prolapse"* is what somebody saw; *"prolapse risk"* is a clinical decision.
// The sheet's heading asks *"What did you see?"* deliberately — *"what is wrong
// with her"* would invite the second kind of answer.
//
// **AND IT NEVER INFERS ONE.** No `obs_poor_mothering` from a lamb death, no
// `obs_no_milk` from a bottle-fed lamb. Only a tap in this sheet writes a row.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/core/ui/vocab_label.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/data/settings_repository.dart' show VocabEntry;
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/flock/flock_controller.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class ObservationSheet extends ConsumerWidget {
  const ObservationSheet({required this.eweId, super.key});

  final EweId eweId;

  /// The list `vocab_terms` seeds for `ewe_observation`, in the order
  /// `first_run.dart` writes them.
  ///
  /// **THE OPTIONS COME FROM THE DATABASE, NOT FROM THIS LIST.** This map only
  /// supplies the *shipped English* for a key whose `label` is still `NULL`
  /// (R66) — a term the shepherd renamed renders their word, a term they hid is
  /// absent, and a term they added renders even though nothing here names it.
  static const String _prefix = 'obs_';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);

    // `.value ?? const []` and not the accessor that throws: the vocabulary
    // arrives one frame after the sheet opens, and a chooser that threw for that
    // frame would take the screen with it.
    final List<VocabEntry> vocab = switch (ref.watch(vocabProvider)) {
      AsyncData<List<VocabEntry>>(value: final List<VocabEntry> v) => v,
      _ => const <VocabEntry>[],
    };
    final List<VocabEntry> options = vocab
        .where((VocabEntry e) => e.key.startsWith(_prefix))
        .toList();

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(t.gapMin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(l10n.eweCardObserveHeading, style: Theme.of(context).textTheme.labelMedium),
            SizedBox(height: t.gapMin),
            // **ONE TAP IS ONE COMMITTED OBSERVATION.** No Save button, no
            // draft, no second confirmation — the row exists the moment the word
            // is pressed, and the confirmation is that row appearing on the
            // timeline behind the sheet (P2: there is no SnackBar).
            Wrap(
              spacing: t.gapMin,
              runSpacing: t.gapMin,
              children: <Widget>[
                for (final VocabEntry term in options)
                  ShedWordButton(
                    key: Key('ewe_card.observe.${term.key}'),
                    label: vocabLabel(term.label, _shipped(l10n, term.key) ?? term.key),
                    selected: false,
                    onTap: () {
                      ref
                          .read(flockWriteControllerProvider.notifier)
                          .recordObservation(eweId, kind: term.key)
                          .ignore();
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The shipped English for a seeded key, or `null` for a term the shepherd
  /// added — whose own label is then the only thing that could render it.
  /// Printing a word this app chose against somebody else's term would be the
  /// app renaming their vocabulary.
  String? _shipped(AppLocalizations l10n, String key) => switch (key) {
    'obs_prolapse' => l10n.vocabObsProlapse,
    'obs_mastitis' => l10n.vocabObsMastitis,
    'obs_poor_mothering' => l10n.vocabObsPoorMothering,
    'obs_good_mothering' => l10n.vocabObsGoodMothering,
    'obs_no_milk' => l10n.vocabObsNoMilk,
    'obs_other' => l10n.vocabObsOther,
    _ => null,
  };
}

// lib/features/lambing/widgets/ease_row.dart
//
// The one surviving chooser in the product. P8 abolished the birth-type chooser
// — birth type is DERIVED from the tally strokes and printed `(COUNTED)` — and
// `ShedChoiceRow`'s own doc comment says in as many words that it is ease 1–5 or
// nothing. This file is its only caller.
//
// THE SCALE IS FIVE AND IT WAS RULED BEFORE THE FREEZE. Decision-record §7.1
// item 15 (*lambing ease 1–5 vs SRUC's 6*) was ruled by N00-T04; `lambings.ease`
// carries `CHECK (ease IS NULL OR ease BETWEEN 1 AND 5)` in a frozen schema, and
// `03 §10.1` notes that 5 covers elective caesarean. A sixth button is a
// migration on somebody else's phone, not a widget change.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_choice_row.dart';
import 'package:shed_book/core/ui/components/shed_ruled_row.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/core/ui/vocab_label.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/data/settings_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/lambing_ease.dart';
import 'package:shed_book/features/lambing/lambing_entry_controller.dart';
import 'package:shed_book/l10n/app_localizations.dart';

/// The five ease keys, in ordinal order. **Frozen** — these strings are foreign
/// keys into `vocab_terms.key`, they are never translated and never edited
/// (`03 §3`), and the list length is what `ShedChoiceRow`'s constructor asserts.
const List<String> kEaseKeys = <String>['ease_1', 'ease_2', 'ease_3', 'ease_4', 'ease_5'];

class EaseRow extends ConsumerWidget {
  const EaseRow({required this.lambingId, required this.ease, super.key});

  final LambingId lambingId;

  /// `null` is UNSCORED, and it is a real answer rather than a missing one
  /// (decision #59). It is never rendered as `1` and never as `0`.
  ///
  /// **The domain type, not an `int`.** `LambingEase` validates 1–5 into
  /// existence, so an out-of-range ordinal cannot reach this widget and be
  /// silently drawn as no selection at all. The unwrap to `int?` happens once,
  /// at the `ShedChoiceRow` boundary, because the component compares ordinals.
  final LambingEase? ease;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ShedTokens t = context.tokens;

    // THE SECOND WATCH, AND IT IS A SINGLETON RATHER THAN A SECOND CONTENT
    // STATEMENT (`07 §1.2`). The ordinal comes from the screen's one statement;
    // the words are a lookup. Joining forty vocabulary rows onto every lamb row
    // would be the alternative, and it buys nothing.
    //
    // `.value ?? const []` and not `.requireValue`: the vocabulary arrives one
    // frame after the first paint, and a chooser that threw for that frame would
    // take the whole screen with it. An empty list renders the shipped defaults,
    // which is exactly right — a rename the shepherd has not loaded yet is not a
    // reason to show nothing.
    final List<VocabEntry> vocab = ref.watch(vocabProvider).value ?? <VocabEntry>[];

    String describe(String key) {
      // firstWhere with an orElse that returns null rather than throwing: a
      // missing row means the seed did not run, which is a broken install, not
      // a state this widget should crash on at 03:20.
      String? userLabel;
      for (final VocabEntry term in vocab) {
        if (term.key == key) {
          userLabel = term.label;
          break;
        }
      }
      return vocabLabel(userLabel, _shipped(key, l10n));
    }

    final int? code = ease?.code;

    // **THE RULED BLOCK, NOT A ROW OF SENTENCES.** Until R87 this widget handed
    // `ShedChoiceRow` the five authored sentences as its button labels, and the
    // component's `Center` then stretched each one to the full width — five
    // full-bleed rows reading *No assistance*, *Slight assistance by hand*, and
    // so on. `indelible.md §7.9` draws five 72 × 72 buttons carrying the DIGITS,
    // *"with the description printed to the right"* for the selected one only.
    //
    // The sentences are not lost and they are not decoration: they are each
    // button's spoken label, so a screen reader still hears *"Ease 3,
    // Considerable assistance needed"* on a control the eye reads as a `3`.
    return DecoratedBox(
      // The block closes with the same rule every ruled row closes with, so the
      // ruling stays continuous through a control that is not one row
      // (`§7.3`).
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: t.outline, width: t.outlineWidth),
        ),
      ),
      child: Padding(
        // **`gapMin` VERTICALLY, AND R86 FIXES THE NUMBER.** The strip's top
        // edge is a target edge, and the row above it is a target too: the two
        // legal separations are 0 and >= 16, and there is nothing between them.
        // Half a gap here would be the 8 pt the ruling struck out.
        // **THE RECORD COLUMN STARTS AT 76, AND THE STRIP MAY NOT CROSS THE
        // SPINE.** `§4.3`: the spine at x=68 *"does not break for headers,
        // sheets, sections or the live row — if a component would interrupt it,
        // that component is wrong."* So the group is laid inside the record
        // column, which is 301 pt at the 393 reference viewport and 283 at
        // `Device.small`. Five 72 pt cells need 360, so the strip re-lays as
        // 4 + 1 and 3 + 2 — the same reflow `§3.6` already documents for 150%
        // text, arriving one device earlier. §7.9's *"361px available"* is the
        // PAGE width, and the spine is what this page spends the difference on.
        padding: EdgeInsets.only(
          left: kRuledMarginWidth + t.gapMin / 2,
          right: t.gapMin,
          bottom: t.gapMin,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(vertical: t.gapMin / 2),
              child: Text(
                l10n.lambingEaseHeading,
                key: const Key('lambing_entry.ease.heading'),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: t.textSecondary),
              ),
            ),
            ShedChoiceRow(
              key: const Key('lambing_entry.ease'),
              selected: code,
              onSelected: (int ordinal) {
                // ONE TAP IS ONE COMMITTED SCORE. No Save button, no draft, and
                // the confirmation is the underline moving.
                ref
                    .read(lambingWriteControllerProvider.notifier)
                    .setEase(lambingId, LambingEase(ordinal));
              },
              unsetLabel: l10n.lambingEaseUnset,
              groupSemanticLabel: l10n.lambingEaseGroupSemantics,
              choices: <({int ordinal, String label, String semanticLabel})>[
                for (int i = 0; i < kEaseKeys.length; i++)
                  (
                    ordinal: i + 1,
                    // THE DIGIT IS THE BUTTON. `LambingEase` carries an ordinal
                    // and nothing else, and the ordinal is what the column
                    // stores — so the thing on screen and the thing on disk are
                    // the same character.
                    label: '${i + 1}',
                    // NO STATE WORD. `10 §3.2` rule 2: the node carries
                    // `selected:` and a screen reader announces the state
                    // itself. "Ease 3, selected" is the doubled announcement
                    // users report as noise.
                    semanticLabel: l10n.lambingEaseValueSemantics(
                      ordinal: i + 1,
                      description: describe(kEaseKeys[i]),
                    ),
                  ),
              ],
            ),
            // **THE DESCRIPTION PRINTS ONLY FOR THE SELECTED VALUE** (§7.9's
            // *Selected* row: `EASE 3 · SOME ASSISTANCE`). Five sentences
            // printed at once is the shape this widget had before, and it is
            // what pushed every other cell on the screen below the fold.
            //
            // The words are the shepherd's — `describe` resolves the
            // `vocab_terms` override first — so they are printed VERBATIM and
            // never upper-cased: changing the case of a term they typed is
            // editing their word.
            if (code case final int ordinal)
              Padding(
                padding: EdgeInsets.only(top: t.gapMin / 2),
                child: Text(
                  l10n.lambingEaseSelected(
                    ordinal: ordinal,
                    description: describe(kEaseKeys[ordinal - 1]),
                  ),
                  key: const Key('lambing_entry.ease.description'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The shipped word for one ease key.
///
/// **A switch and not a map lookup by name**, so adding `ease_6` fails to
/// compile here rather than rendering an empty button — the scale is frozen at
/// five and this is one more place that is true.
///
/// The five sentences are the app's own. `03 §10.1` overturns an earlier
/// "adopt them verbatim" instruction: the SRUC technical note is image-based and
/// its licence terms could not be verified. The CONCEPT of a five-point
/// assistance scale is not ownable; the sentences are. The no-verbatim check
/// scans both `assets/content/` and `lib/l10n/` (R66), so pasting into either
/// fails the build.
String _shipped(String key, AppLocalizations l10n) => switch (key) {
  'ease_1' => l10n.vocabEase1,
  'ease_2' => l10n.vocabEase2,
  'ease_3' => l10n.vocabEase3,
  'ease_4' => l10n.vocabEase4,
  'ease_5' => l10n.vocabEase5,
  _ => throw ArgumentError.value(key, 'key', 'not one of the five frozen ease keys'),
};

// lib/core/ui/components/shed_choice_row.dart
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// **EASE 1–5 ONLY.**
///
/// P8 (`CLAUDE.md`) abolished the birth-type chooser: birth type is DERIVED from
/// the tally strokes and printed `(COUNTED)`, which is what makes safety rule
/// §12.4 structural instead of procedural. indelible.md §7.9: *"there is no
/// segmented control, because there is no choice. This is the signature of the
/// direction and it must not be softened."*
///
/// **This component may not be used for birth type**, and it may not be used for
/// death cause either — that is a vocabulary list of arbitrary length and belongs
/// in a sheet, not in a five-cell `Wrap`.
///
/// The five-cell shape is enforced in the constructor rather than trusted.
final class ShedChoiceRow extends StatelessWidget {
  const ShedChoiceRow({
    required this.choices,
    required this.selected,
    required this.onSelected,
    required this.unsetLabel,
    required this.groupSemanticLabel,
    super.key,
  }) : assert(
         choices.length == 5,
         'ease is 1–5 and this component is for ease alone — a chooser of any '
         'other length is P8 being softened',
       );

  /// `(ordinal, label, semanticLabel)`. The label is the ARB message behind a
  /// `vocab_terms` row `ease_1`…`ease_5` (R44): `LambingEase` carries an ordinal
  /// and nothing else, because a domain file cannot hold ARB text.
  final List<({int ordinal, String label, String semanticLabel})> choices;

  /// `null` is the group's **unset** state — a real answer, and skippable.
  final int? selected;

  final ValueChanged<int> onSelected;

  /// `EASE — NOT RECORDED · SKIPPABLE`. Arrives localised.
  final String unsetLabel;

  final String groupSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return Semantics(
      label: groupSemanticLabel,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // A Wrap, NOT a Row. At 200% five cells of tapPrimary do not share one
          // line, and a Row overflows where a Wrap reflows to two. Decision #99
          // forbids clamping the text, so the layout is what gives way.
          Wrap(
            spacing: t.gapMin,
            runSpacing: t.gapMin,
            children: <Widget>[
              for (final ({int ordinal, String label, String semanticLabel}) c in choices)
                ShedTapTarget(
                  onTap: () => onSelected(c.ordinal),
                  semanticLabel: c.semanticLabel,
                  minSize: t.tapPrimary,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        // The non-colour channel: a selected cell carries a
                        // heavier underline. A border colour alone would be
                        // invisible to a reader who cannot separate the inks.
                        bottom: BorderSide(
                          color: selected == c.ordinal ? t.textPrimary : t.outline,
                          width: selected == c.ordinal ? t.outlineWidth * 2 : t.outlineWidth,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        c.label,
                        // BOTH WEIGHTS ARE EXPLICIT. `selected ? w700 : null`
                        // was the first attempt and distinguishes nothing:
                        // labelLarge is ALREADY w700, so the null branch
                        // inherits the same weight and the channel is a no-op.
                        // Naming both ends is what makes it a real second
                        // channel beside the heavier underline.
                        style: text.labelLarge?.copyWith(
                          fontWeight: selected == c.ordinal ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // The unset state is a LABEL, never a sixth cell. A sixth cell would
          // make "not recorded" something you pick, and then a shepherd who
          // skipped the question and one who answered "unknown" become
          // indistinguishable in the record.
          if (selected == null) Text(unsetLabel, style: text.titleSmall),
        ],
      ),
    );
  }
}

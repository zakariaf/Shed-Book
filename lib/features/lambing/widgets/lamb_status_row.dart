// lib/features/lambing/widgets/lamb_status_row.dart
//
// THREE TARGETS, NOT FOUR. Alive, dead and stillborn are what a shepherd records
// at the shed; SOLD is set from the flock list, and offering it here would put a
// sale in a lambing pen.
//
// STILLBORN IS ITS OWN STATUS AND NEVER "DIED AT AGE 0". It is a different line
// in every count `05 §6` produces, and collapsing it into `dead` with a
// same-day date would make a season's losses unreadable a year later.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/stats/season_counts.dart';

class LambStatusRow extends StatelessWidget {
  const LambStatusRow({
    required this.status,
    required this.words,
    required this.onSelected,
    super.key,
  });

  final LambStatus status;

  final ({String alive, String dead, String stillborn}) words;

  /// **Selecting `alive` is how a death is undone**, and the verb behind it
  /// clears the date and the cause with it. There is no separate clear, because
  /// a lamb that is alive is not a lamb that is alive and died on Tuesday.
  final ValueChanged<LambStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    return Wrap(
      spacing: t.gapMin,
      runSpacing: t.gapMin,
      children: <Widget>[
        for (final ({LambStatus value, String word}) c in <({LambStatus value, String word})>[
          (value: LambStatus.alive, word: words.alive),
          (value: LambStatus.dead, word: words.dead),
          (value: LambStatus.stillborn, word: words.stillborn),
        ])
          _StatusButton(
            id: 'lamb_card.status.${c.value.key}',
            word: c.word,
            selected: status == c.value,
            // NO CLEAR-BY-RETAP HERE, unlike sex and presentation. A lamb always
            // has a status — `alive` is the schema's default and a real answer —
            // so there is no *not recorded* to return to, and a tap that
            // un-selected the current status would leave the row showing
            // nothing while the column still said something.
            onTap: () => onSelected(c.value),
          ),
      ],
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.id,
    required this.word,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final String word;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return Semantics(
      selected: selected,
      child: ShedTapTarget(
        key: Key(id),
        semanticLabel: word,
        minSize: t.tapIndelible,
        onTap: onTap,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? t.textPrimary : t.outline,
                  width: selected ? t.outlineWidth * 2 : t.outlineWidth,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: t.gapMin),
              child: Center(
                child: Text(word, style: selected ? text.titleMedium : text.bodyMedium),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

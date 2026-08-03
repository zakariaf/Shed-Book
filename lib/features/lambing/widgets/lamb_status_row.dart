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
import 'package:shed_book/core/ui/components/shed_word_button.dart';
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
        for (final ({LambStatus value, String label}) c in <({LambStatus value, String label})>[
          (value: LambStatus.alive, label: words.alive),
          (value: LambStatus.dead, label: words.dead),
          (value: LambStatus.stillborn, label: words.stillborn),
        ])
          ShedWordButton(
            key: Key('lamb_card.status.${c.value.key}'),
            label: c.label,
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

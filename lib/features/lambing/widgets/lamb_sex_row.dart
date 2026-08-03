// lib/features/lambing/widgets/lamb_sex_row.dart
//
// THREE TARGETS, NOT TWO, AND R45 IS WHY. `null` is *not recorded*;
// `Sex.unknown` is *the shepherd looked and could not tell*. They are different
// facts and neither is the other's default, so the third target exists and the
// way back to `null` is to tap the selected one again.
//
// FEATURE-LOCAL: it appears on one screen. `lib/core/ui/components/` is for the
// things two features need (R70), and a shared component nobody shares is a
// component that grows a parameter for every caller.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/sex.dart';

class LambSexRow extends StatelessWidget {
  const LambSexRow({required this.sex, required this.words, required this.onSelected, super.key});

  /// `null` is *not recorded*, and it is the state every lamb starts in.
  final Sex? sex;

  /// `(female, male, unknown)`, resolved by the screen.
  final ({String female, String male, String unknown}) words;

  /// `null` clears it. **Tapping the selected value clears it**, because
  /// recorded-as-unknown and not-recorded are both reachable and a shepherd who
  /// mis-taps must be able to get back to *nothing said*.
  final ValueChanged<Sex?> onSelected;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    return Wrap(
      spacing: t.gapMin,
      runSpacing: t.gapMin,
      children: <Widget>[
        for (final ({Sex value, String label}) c in <({Sex value, String label})>[
          (value: Sex.female, label: words.female),
          (value: Sex.male, label: words.male),
          (value: Sex.unknown, label: words.unknown),
        ])
          ShedWordButton(
            key: Key('lamb_card.sex.${c.value.key}'),
            label: c.label,
            selected: sex == c.value,
            onTap: () => onSelected(sex == c.value ? null : c.value),
          ),
      ],
    );
  }
}

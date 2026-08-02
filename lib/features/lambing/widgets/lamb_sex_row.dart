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
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
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
        for (final ({Sex value, String word}) c in <({Sex value, String word})>[
          (value: Sex.female, word: words.female),
          (value: Sex.male, word: words.male),
          (value: Sex.unknown, word: words.unknown),
        ])
          _SexButton(
            id: 'lamb_card.sex.${c.value.key}',
            word: c.word,
            selected: sex == c.value,
            onTap: () => onSelected(sex == c.value ? null : c.value),
          ),
      ],
    );
  }
}

class _SexButton extends StatelessWidget {
  const _SexButton({
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

    // `selected:` on the node, no state word in the label (`10 §3.2` rule 2).
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

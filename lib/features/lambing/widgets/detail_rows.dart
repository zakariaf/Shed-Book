// lib/features/lambing/widgets/detail_rows.dart
//
// EVERY FIELD HERE IS SKIPPABLE, AND THE ROW SAYS SO. Unset is a dotted rule and
// `NOT RECORDED · SKIPPABLE` — never a placeholder inside the field
// (`indelible.md §7.12`): *"in the dark, a grey placeholder is
// indistinguishable from an entered value."* There is no `hintText` anywhere in
// this feature.
//
// THERE ARE NO CHIPS ON THIS SCREEN, AND `07 §6.4` USES THE WORD ANYWAY.
// `indelible.md` is explicit: *"the filters are not chips — chips are containers
// with a radius, and this system has neither."* The malpresentation picker is a
// ruled list of WORD BUTTONS (§7.13), each clearing 64 × 64.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// One word button in the presentation list.
typedef PresentationChoice = ({String key, String label, bool selected});

/// The malpresentation picker.
///
/// **HIDDEN TERMS ARE NOT OFFERED, BUT A HIDDEN TERM ALREADY ON THE RECORD
/// STILL RENDERS.** `presentation` is an FK onto `vocab_terms.key` with
/// `ON DELETE RESTRICT`, so a term in use cannot be deleted — removal sets
/// `hidden_at`. Filtering hidden terms out of the LABEL LOOKUP as well as out of
/// the LIST is how an existing record starts printing a raw key at 03:20, so the
/// caller passes the offered list and the resolved label separately.
class PresentationPicker extends StatelessWidget {
  const PresentationPicker({
    required this.choices,
    required this.onSelected,
    required this.unsetLabel,
    required this.groupSemanticLabel,
    super.key,
  });

  final List<PresentationChoice> choices;

  /// `null` clears it. **Tapping the selected word clears it**, because the
  /// field is skippable and without that there is no way back to *not recorded*
  /// after a mis-tap — which would leave the app holding a claim the shepherd
  /// disowned.
  final ValueChanged<String?> onSelected;

  final String unsetLabel;
  final String groupSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final bool anySelected = choices.any((PresentationChoice c) => c.selected);

    return Semantics(
      label: groupSemanticLabel,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // A Wrap rather than a Row: eight words do not share one line at any
          // text scale, and decision #99 forbids clamping the text to make them.
          Wrap(
            spacing: t.gapMin,
            runSpacing: t.gapMin,
            children: <Widget>[
              for (final PresentationChoice c in choices)
                _WordButton(
                  id: 'lambing_entry.presentation.${c.key}',
                  label: c.label,
                  selected: c.selected,
                  onTap: () => onSelected(c.selected ? null : c.key),
                ),
            ],
          ),
          if (!anySelected)
            Padding(
              padding: EdgeInsets.only(top: t.gapMin / 4),
              child: Text(
                unsetLabel,
                key: const Key('lambing_entry.presentation.unset'),
                style: text.bodySmall?.copyWith(color: t.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

/// A word button — **not a `Chip`**. No radius, no container, no fill: a word
/// with a rule under it, which is what this system draws.
class _WordButton extends StatelessWidget {
  const _WordButton({
    required this.id,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    // `selected:` on the node and NO STATE WORD in the label (`10 §3.2` rule 2).
    return Semantics(
      selected: selected,
      child: ShedTapTarget(
        key: Key(id),
        semanticLabel: label,
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
                child: Text(label, style: selected ? text.titleMedium : text.bodyMedium),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

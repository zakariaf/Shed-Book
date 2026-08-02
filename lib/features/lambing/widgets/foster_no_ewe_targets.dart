// lib/features/lambing/widgets/foster_no_ewe_targets.dart
//
// TWO TARGETS, AND THEY ARE TWO DIFFERENT FACTS. `to_bottle` is null BY INTENT —
// the shepherd put this lamb on a bottle. `removed_unknown` is null BY OMISSION
// — the lamb came off a ewe and where it went was not written down. The
// rearing-credit numbers differ between them, which is why
// `setRearingDam(LambId, EweId?)` is a banned signature (`07 §8.4` rule 1).
//
// A WIDGET, NOT A CHOOSER: these commit, they do not open anything. Every step
// between the tap and the row spends the one-tap budget `07 §8.2` fixes.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

class FosterNoEweTargets extends StatelessWidget {
  const FosterNoEweTargets({
    required this.onToBottle,
    required this.onRemoved,
    required this.bottleLabel,
    required this.removedLabel,
    super.key,
  });

  final VoidCallback onToBottle;
  final VoidCallback onRemoved;
  final String bottleLabel;
  final String removedLabel;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Target(id: 'foster.to_bottle', label: bottleLabel, onTap: onToBottle),
        // gapDestructive between them. They are adjacent in the layout and
        // opposite in meaning, and a mis-tap here writes the wrong fact into a
        // season's figures — which is exactly what that token is for.
        SizedBox(height: t.gapDestructive),
        _Target(id: 'foster.removed_unknown', label: removedLabel, onTap: onRemoved),
      ],
    );
  }
}

class _Target extends StatelessWidget {
  const _Target({required this.id, required this.label, required this.onTap});

  final String id;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.gapMin),
      child: ShedTapTarget(
        key: Key(id),
        semanticLabel: label,
        minSize: t.tapPrimary,
        onTap: onTap,
        child: ExcludeSemantics(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

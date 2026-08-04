// lib/core/ui/components/shed_corner_slab.dart
//
// **THE LARGEST TARGET IN THE SYSTEM**, and the one the shepherd aims at without
// looking. `indelible.md §7.1` fixes it at 160 × 140 in the bottom corner; §4.5
// puts it in the thumb band, 0–320 px from the bottom edge.
//
// It is a component rather than a number in each screen because the number is
// now needed in two places — Quick Entry's `+ LAMB` and Flock's `+ EWE` — and a
// geometry contract copied into a second file is a geometry contract that will
// disagree with itself. `_Grid` in `quick_entry_screen.dart` reads [width] and
// [height] off this class for exactly that reason.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

final class ShedCornerSlab extends StatelessWidget {
  const ShedCornerSlab({
    required this.label,
    required this.onTap,
    required this.semanticLabel,
    super.key,
  });

  /// `indelible.md §7.1`, the reference viewport's figures. **Named here once**
  /// — `token.magic_size` is right to fire on a bare number, and these are the
  /// component's own dimensions rather than palette values, so they are not on
  /// `ShedTokens`.
  static const double width = 160;
  static const double height = 140;

  /// A word, in the control face. There is no icon set (`indelible.md §1.3`).
  final String label;

  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    return SizedBox(
      width: width,
      height: height,
      child: ShedTapTarget(
        onTap: onTap,
        semanticLabel: semanticLabel,
        minSize: t.tapHero,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.surfaceFill,
            // Radius 2 — the slab is the one shape in the system with a corner
            // (`indelible.md §4.2`); the record has none and the sheet has none.
            border: Border.all(color: t.outline, width: t.outlineWidth),
            borderRadius: BorderRadius.all(Radius.circular(t.radiusControl)),
          ),
          child: ExcludeSemantics(
            child: Center(
              // VERBATIM, and nothing shrinks it to fit: the label is the one
              // string on this screen that must survive 200% text intact.
              child: Text(label, style: Theme.of(context).textTheme.headlineSmall),
            ),
          ),
        ),
      ),
    );
  }
}

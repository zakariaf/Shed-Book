// lib/features/flock/widgets/flock_band.dart
//
// **THE TWO THUMB ANCHORS, AND THE FLOCK HAD ONLY ONE.**
//
// `indelible.md §4.4` and `mockups/indelible.html` screen 1 put `INDEX` bottom
// left and the `+ EWE` slab bottom right, on a 152 pt band that nothing scrolls
// under. Measured against the running app on 2026-08-07: there was no `INDEX` at
// all, and the slab was a `Positioned` child of a bare `Stack` — so it floated
// OVER the last record row instead of sitting under it, and a shepherd reaching
// for the bottom of the list pressed `+ EWE`.
//
// **WHY NOT `ShedBottomBand`.** R87's own component does this layout, and it is
// the right home for it — but it hard-codes `Key('quick_entry.slab')` and
// `Key('quick_entry.index')`, and it re-draws the slab from a `Container`
// instead of using `ShedCornerSlab`. `flock_test.dart` measures
// `Key('flock.add_slab')` against `ShedCornerSlab.width`/`.height`, so adopting
// it would mean either losing a pinned key or parameterising a shared component
// every screen's band is about to want. That is a change with six callers and
// belongs to whoever lands them together; the geometry below is eight lines and
// is stated once here rather than half-migrated.
//
// **THE BAND IS 152 *ABOVE* THE SAFE-AREA INSET.** `§4.4` measures from
// `env(safe-area-inset-bottom)`; in Flutter that is
// `MediaQuery.paddingOf(context).bottom`, which is zero inside `ShedPage`'s
// `SafeArea` and non-zero if this is ever used without one. Reading it costs
// nothing and a hard-coded 152 puts the slab under the home indicator.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_corner_slab.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

final class FlockBand extends StatelessWidget {
  const FlockBand({
    required this.indexLabel,
    required this.slabLabel,
    required this.onIndex,
    required this.onSlab,
    required this.bandHeight,
    required this.indexWidth,
    required this.indexHeight,
    super.key,
    this.leftHanded = false,
  });

  final String indexLabel;

  /// `+ EWE`. **Never disabled, and never absent**: pressing it opens the add
  /// sheet at every entitlement state, because the free-tier cap is decided by
  /// the verb inside the transaction and never by a greyed-out control
  /// (`11 §7.3`, decision #90).
  final String slabLabel;

  final VoidCallback onIndex;
  final VoidCallback onSlab;

  final double bandHeight;
  final double indexWidth;
  final double indexHeight;

  /// **MOVES THE SLAB, NOT THE SPINE** (`§4.3`, R40). A book's margin is on the
  /// left; three things mirror in this app and the margin is not one of them.
  final bool leftHanded;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final double safeBottom = MediaQuery.paddingOf(context).bottom;

    final Widget index = ShedTapTarget(
      key: const Key('flock.index'),
      semanticLabel: indexLabel,
      minSize: indexHeight,
      onTap: onIndex,
      child: ExcludeSemantics(
        child: SizedBox(
          width: indexWidth,
          height: indexHeight,
          child: Center(child: Text(indexLabel, style: Theme.of(context).textTheme.labelMedium)),
        ),
      ),
    );

    final Widget slab = ShedCornerSlab(
      key: const Key('flock.add_slab'),
      label: slabLabel,
      semanticLabel: slabLabel,
      onTap: onSlab,
    );

    return SizedBox(
      height: bandHeight + safeBottom,
      child: Padding(
        // `bottom: safeBottom` and NOT `safeBottom + gapMin`: the height above
        // already includes the inset, so adding it again inside the padding
        // spends it twice and the row overflows by exactly the gap.
        padding: EdgeInsets.only(left: t.gapMin, right: t.gapMin, bottom: safeBottom),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          // **THE TWO ANCHORS ARE AT OPPOSITE ENDS**, which is R86's other legal
          // separation: far more than 16 pt apart, so a cold thumb aiming at one
          // cannot land on the other.
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: leftHanded ? <Widget>[slab, index] : <Widget>[index, slab],
        ),
      ),
    );
  }
}

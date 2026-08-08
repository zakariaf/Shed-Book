// lib/features/lambing/widgets/lambing_entry_band.dart
//
// **THE THUMB BAND, AND THIS SCREEN HAD NONE.**
//
// `indelible.md §4.5` reserves the bottom 320 px for one thumb and says nothing
// required to record an event may sit above it. The act this screen exists for —
// one more stroke, one more lamb — was an 88 pt cell at the right-hand end of a
// scrolling row, four regions down the page. On a 375 × 667 phone at 130 % text
// it was the fourth thing the shepherd had to scroll to.
//
// ---------------------------------------------------------------------------
// WHY THIS IS NOT `ShedBottomBand`
// ---------------------------------------------------------------------------
//
// Two reasons, and the first is mechanical. `ShedBottomBand` keys its two
// targets `quick_entry.index` and `quick_entry.slab` — R87 moved the widget out
// of the feature folder and left the feature's keys inside it. This screen's
// primary act is keyed `lambing_entry.tally.stroke`, which is named in the
// decision record under P8 and pinned by four test files, so it cannot be
// renamed to satisfy a component.
//
// The second is that `ShedBottomBand` draws its own slab — a `Container` with a
// border and a `labelLarge` word — rather than using `ShedCornerSlab`, which is
// `§7.1`'s component and carries the 160 × 140 contract as `static const`s. A
// second screen adopting the copy would make the copy the standard.
//
// Neither is a reason to change a shared component in a task about one screen,
// and both are worth reporting.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_corner_slab.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// `indelible.md §4.4`'s band, and `§7.17`'s bottom-left control.
///
/// Named here rather than typed inline for the reason `token.magic_size` exists:
/// these are this screen's layout constants, not palette values, so they are not
/// on `ShedTokens` — the same arrangement `quick_entry_screen.dart` uses.
const double kLambingBandHeight = 152;
const double kLambingBackWidth = 96;
const double kLambingBackHeight = 64;

/// `TONIGHT` bottom-left, `+ LAMB` bottom-right.
final class LambingEntryBand extends StatelessWidget {
  const LambingEntryBand({
    required this.backLabel,
    required this.slabLabel,
    required this.slabSemanticLabel,
    required this.onBack,
    required this.onSlab,
    super.key,
  });

  /// `TONIGHT` — the page this screen is an expansion of.
  ///
  /// **THERE IS NO BACK CHEVRON IN THIS APP** (ruling P3), and there is no index
  /// sheet reachable from here either: `IndexSheet` lives in
  /// `lib/features/quick_entry/widgets/`, which `layer.sibling` forbids this
  /// feature from importing. So the one navigation affordance names its
  /// destination instead of pointing at it, which is what the rest of the
  /// product does anyway — `07 §6.4`'s *"Done — 1 tap — pops; there is nothing
  /// to save"*, with the word saying where you land rather than what you did.
  final String backLabel;

  /// `+ LAMB`. **Never disabled** (`§7.2`): a dead key under a cold thumb is
  /// indistinguishable from a missed tap.
  final String slabLabel;
  final String slabSemanticLabel;

  final VoidCallback onBack;
  final VoidCallback onSlab;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    // MEASURED FROM THE INSET, NEVER HARD-CODED. `12 §5.1`: `pumpApp` injects a
    // 34 pt bottom padding precisely because a zero-padding harness hides the
    // entire class of bug where a bottom-anchored 60 pt target is under the home
    // bar — which is every primary action in this app.
    final double safeBottom = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      key: const Key('lambing_entry.band'),
      height: kLambingBandHeight + safeBottom,
      child: Padding(
        // `bottom: safeBottom` and NOT `safeBottom + gapMin`: the height above
        // already includes the inset, so adding it again inside the padding
        // spends it twice and the row overflows by exactly the gap.
        padding: EdgeInsets.only(left: t.gapMin, right: t.gapMin, bottom: safeBottom),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            ShedTapTarget(
              key: const Key('lambing_entry.back'),
              semanticLabel: backLabel,
              minSize: kLambingBackHeight,
              onTap: onBack,
              child: ExcludeSemantics(
                child: SizedBox(
                  width: kLambingBackWidth,
                  height: kLambingBackHeight,
                  child: Center(
                    child: Text(backLabel, style: Theme.of(context).textTheme.labelMedium),
                  ),
                ),
              ),
            ),
            ShedCornerSlab(
              // **THE KEY IS THE ACT, NOT THE WIDGET.** It was on an 88 pt cell
              // in the tally row; it is on the 160 × 140 slab now, and the four
              // tests that press it press the same act in a better place.
              key: const Key('lambing_entry.tally.stroke'),
              label: slabLabel,
              semanticLabel: slabSemanticLabel,
              onTap: onSlab,
            ),
          ],
        ),
      ),
    );
  }
}

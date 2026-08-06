// lib/features/quick_entry/widgets/quick_entry_bottom_band.dart
//
// The bottom band: INDEX bottom-left (96 x 64), the corner slab bottom-right
// (160 x 140).
//
// THE BAND IS 152 *ABOVE* THE SAFE-AREA INSET, AND HARD-CODING 152 IS THE BUG.
// indelible.md §4.4 measures from env(safe-area-inset-bottom); in Flutter that is
// MediaQuery.paddingOf(context).bottom. pumpApp injects a 34 pt bottom padding
// precisely because "a zero-padding harness hides the entire class of bug where a
// bottom-anchored 60 pt target is under the home bar — which is every primary
// action in this app" (12 §5.1). A band of exactly 152 puts the slab under the
// home indicator on every shipping iPhone.
//
// INDEX is the ONLY navigation affordance in the app. P3's affordance half went
// to indelible.md, so there is no back chevron anywhere (decision record §7.0a).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/features/quick_entry/quick_entry_controller.dart';

/// **A `ConsumerWidget`, AND IT WATCHES ONE BOOLEAN.**
///
/// `§8`: *"the slab arms — its border goes to `--ink-full`, a madder tick prints
/// at its corner, and its label changes to `+ LAMB`."* Something has to notice
/// that an animal was chosen, and it may not be the screen: the shell watching
/// nothing is what makes every box on it immovable (`02 §10.1`).
///
/// So the band notices, and a rebuild here can move nothing — the band is 152 pt,
/// `INDEX` is 96 × 64 and the slab is 160 × 140, all fixed, none of them derived
/// from the thing being watched. Only the word inside the slab changes.
class QuickEntryBottomBand extends ConsumerWidget {
  const QuickEntryBottomBand({
    required this.indexLabel,
    required this.slabLabelUnarmed,
    required this.slabLabelArmed,
    required this.onIndex,
    required this.onSlab,
    required this.bandHeight,
    required this.indexWidth,
    required this.indexHeight,
    required this.slabWidth,
    required this.slabHeight,
    super.key,
    this.leftHanded = false,
  });

  final String indexLabel;

  /// `TAG FIRST` — and it is **never disabled**. Pressing it opens the tag
  /// sheet, because a dead key under a cold thumb is indistinguishable from a
  /// missed tap (`§7.2`).
  final String slabLabelUnarmed;

  /// `+ LAMB`, once an animal is chosen.
  final String slabLabelArmed;
  final VoidCallback onIndex;

  /// **Never null.** The slab before an animal is chosen reads "Tag first" and
  /// is still a 160 x 140 target: pressing it opens the tag sheet rather than
  /// doing nothing, because a dead key under a cold thumb is indistinguishable
  /// from a missed tap.
  final VoidCallback onSlab;

  final double bandHeight;
  final double indexWidth;
  final double indexHeight;
  final double slabWidth;
  final double slabHeight;

  /// Moves the SLAB, not the spine (indelible.md §4.3).
  final bool leftHanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final double safeBottom = MediaQuery.paddingOf(context).bottom;

    // `.select`, so a keystroke in the tag sheet does not rebuild the band —
    // only the transition from nothing-chosen to chosen does.
    final bool armed = ref.watch(
      quickEntryControllerProvider.select((QuickEntryState s) => s.selected != null),
    );
    final String slabLabel = armed ? slabLabelArmed : slabLabelUnarmed;

    final Widget index = ShedTapTarget(
      key: const Key('quick_entry.index'),
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

    final Widget slab = ShedTapTarget(
      key: const Key('quick_entry.slab'),
      semanticLabel: slabLabel,
      minSize: slabHeight,
      onTap: onSlab,
      child: ExcludeSemantics(
        child: Container(
          width: slabWidth,
          height: slabHeight,
          decoration: BoxDecoration(
            color: t.surfaceRaised,
            borderRadius: BorderRadius.circular(t.radiusControl),
            border: Border.all(color: t.outline, width: t.outlineWidth),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(t.gapMin / 2),
              child: Text(
                slabLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ),
      ),
    );

    return SizedBox(
      key: const Key('quick_entry.bottom_band'),
      height: bandHeight + safeBottom,
      child: Padding(
        // `bottom: safeBottom` and NOT `safeBottom + gapMin`: the height above
        // already includes the inset, so adding it again inside the padding
        // spends it twice and the row overflows by exactly the gap. Measured at
        // 2 px on the reference viewport, which is small enough to look like a
        // rounding artefact and is not one.
        padding: EdgeInsets.only(left: t.gapMin, right: t.gapMin, bottom: safeBottom),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: leftHanded ? <Widget>[slab, index] : <Widget>[index, slab],
        ),
      ),
    );
  }
}

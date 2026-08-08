// lib/core/ui/components/shed_bottom_band.dart
//
// **MOVED FROM `lib/features/quick_entry/widgets/` AT R87, AND THE MOVE IS A FIX
// RATHER THAN A TIDY-UP.** `layer.sibling` forbids one feature importing another,
// so a page component in a feature folder is a component only that feature can
// ever have. Measured: Quick Entry was the ONLY screen in the app with a spine, a
// margin cell or a ruled header — six screens rendered as a bare column because
// the parts were in a room they could not reach.
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
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/control_voice.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// **IT WATCHES NOTHING, AND THAT IS R87'S CONDITION FOR THE MOVE.**
///
/// Quick Entry's band swaps `TAG FIRST` for `+ LAMB` when an animal is chosen, so
/// this widget was a `ConsumerWidget` reading `quickEntryControllerProvider`.
/// `layer.core_ui` forbids `lib/core/ui/` importing `lib/data/`, and the rule is
/// right beyond the gate: a shared component that watched one screen's provider
/// would be a component with that screen's state baked into it, and the other six
/// bands would inherit a subscription they have no use for.
///
/// So the band renders the word it is handed. Quick Entry keeps a thin
/// feature-local `ConsumerWidget` that chooses between two strings — which is
/// where the watching belonged, because *the slab arms* is a fact about that
/// screen and not about a band.
class ShedBottomBand extends StatelessWidget {
  const ShedBottomBand({
    required this.indexLabel,
    required this.slabLabel,
    required this.onIndex,
    required this.onSlab,
    required this.bandHeight,
    required this.indexWidth,
    required this.indexHeight,
    required this.slabWidth,
    required this.slabHeight,
    super.key,
    this.leftHanded = false,
    this.indexKey = const Key('quick_entry.index'),
    this.slabKey = const Key('quick_entry.slab'),
    this.slabSemanticLabel,
  });

  final String indexLabel;

  /// The word on the slab. **Never disabled, whatever it reads**: pressing an
  /// unarmed slab does something, because a dead key under a cold thumb is
  /// indistinguishable from a missed tap (`§7.2`).
  final String slabLabel;
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

  /// **THE KEYS COME FROM THE CALLER, WHICH IS WHAT R87'S OWN COMMIT MESSAGE
  /// SAID AND THE FIRST CUT DID NOT DO.** Quick Entry's `quick_entry.index` and
  /// `quick_entry.slab` are pinned by the rect anchor and by the geometric gate,
  /// so they are the DEFAULTS and that screen is untouched — but a second screen
  /// rendering a slab keyed `quick_entry.slab` is a key that lies about which
  /// page it is on, and its own test cannot find it. The pen board passes
  /// `pen_board.add_pen`.
  final Key indexKey;
  final Key slabKey;

  /// What the slab SAYS when the visible word cannot be read aloud. `+ PEN`
  /// announces as *"plus pen"*; the pen board hands it *"Add a pen"*, which is
  /// the reason `penBoardAddPenSemantics` exists. Defaults to [slabLabel],
  /// because for `TAG FIRST` and `+ LAMB` the two are the same string and a
  /// second one would be a second thing to keep in step.
  final String? slabSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final double safeBottom = MediaQuery.paddingOf(context).bottom;

    final Widget index = ShedTapTarget(
      key: indexKey,
      semanticLabel: indexLabel,
      minSize: indexHeight,
      onTap: onIndex,
      child: ExcludeSemantics(
        // **A MINIMUM, NOT A FIXED BOX — AND THE GOLDEN IS WHAT CAUGHT IT.**
        //
        // A fixed box clipped its own word at 200% text scale:
        // `quick_entry_scale_2_0` rendered the app's ONE navigation affordance as
        // `INDE`. `§7.17`'s index dimensions are the FLOOR that makes it a legal
        // target, exactly as `§4.3`'s are the margin cell's, and `§3.6` is the
        // rule both follow — *rows grow, the grid does not move*.
        //
        // (The forbidden form is not spelled out here on purpose: `token.magic_size`
        // scans this file including its comments, and quoting the thing a comment
        // forbids is how a prohibition fires on the paragraph explaining it. The
        // seventh time this project has caught that.)
        //
        // Growing costs nothing here: the band is a `spaceBetween` row, so the
        // index takes the width it needs from the empty middle and the slab stays
        // welded to its own corner. Nothing the thumb aims at moves.
        //
        // Before P16 this was invisible, because the entry sheet covered the band
        // on every frame the app ever drew.
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: indexWidth, minHeight: indexHeight),
          child: Center(
            // **THE CONTROL VOICE** (§3.1, ruling P7). `INDEX` is the app's one
            // navigation affordance and one of its two thumb anchors.
            child: Text(
              controlCase(indexLabel),
              textAlign: TextAlign.center,
              style: controlStyle(context, Theme.of(context).textTheme.labelMedium),
            ),
          ),
        ),
      ),
    );

    final Widget slab = ShedTapTarget(
      key: slabKey,
      semanticLabel: slabSemanticLabel ?? slabLabel,
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
                // **THE SLAB'S OWN WORD, AT `--t-slab`'s 0.06em** (§7.1).
                //
                // **AND THIS BAND DRAWS ITS OWN SLAB RATHER THAN USING
                // `ShedCornerSlab`, WHICH IS A REPORTED DUPLICATE.** Two
                // renderings of the app's largest target now exist and they will
                // disagree the first time one of them moves. Collapsing them is
                // a geometry change, so it is named here rather than made in a
                // typographic pass.
                controlCase(slabLabel),
                textAlign: TextAlign.center,
                style: controlStyle(
                  context,
                  Theme.of(context).textTheme.labelLarge,
                  track: kTrackSlab,
                ),
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

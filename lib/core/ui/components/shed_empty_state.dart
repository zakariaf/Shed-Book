// lib/core/ui/components/shed_empty_state.dart
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// Decision #71: **the empty states ARE the onboarding.** One line of copy and
/// one action, at the same `tapHero` control the populated screen uses. No
/// illustration, no spinner, no tour, no multi-step anything (`07 §2.2`).
///
/// **It fills its parent**, and that is the whole mechanism behind *"occupies
/// the same box the populated content will"*: a screen puts the list and this
/// widget in the same slot, and nothing can jump when the first record lands.
final class ShedEmptyState extends StatelessWidget {
  const ShedEmptyState({required this.copy, super.key, this.action});

  /// `07 §2.2`, verbatim — *"No animals yet."* Arrives localised.
  final String copy;

  /// A `ShedPrimaryButton`, or nothing: the Lamb Card's empty state has no
  /// action, because there is nothing to do there that is not done elsewhere.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    return SizedBox(
      // TAKES THE MAXIMUM OF LOOSE CONSTRAINTS, NOT THE MINIMUM. The real bug
      // this prevents is an intrinsic wrapper that sizes to the copy: the empty
      // state then occupies a short box, the populated list occupies a tall one,
      // and the screen jumps the moment a shepherd records their first ewe.
      width: double.infinity,
      height: double.infinity,
      // **IT SCROLLS WHEN THE BOX IS SMALLER THAN THE WORDS, AND AT 200% IT IS.**
      // The centred column above is right when this widget owns the page. On the
      // Ewe Card it does not — the summary line sits above it and takes the
      // height it needs — so at textScaler 2.0 on a 375 x 667 device the column
      // overflowed by 52 px. Measured at N27-T02, not guessed.
      //
      // The scroll view keeps both properties: the box is still the full height
      // of the slot, so nothing jumps when the first record lands, AND the copy
      // is still reachable when it is taller than the box. `Center` inside is
      // what keeps the resting position identical to before — a screen with room
      // to spare renders exactly the same pixels it did.
      //
      // Vertical scrolling is the one permitted tracked gesture, and an empty
      // state's action is never reachable ONLY behind it: at every size where
      // the action fits, it is on screen.
      // `LayoutBuilder` is what makes the two properties compatible: a scroll
      // view hands its child UNBOUNDED height, so a bare `Center` inside one
      // fails to lay out at all. The minimum height is the slot's own, read from
      // the constraints — so the content centres in a full-height box when there
      // is room and grows past it when there is not.
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  copy,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                if (action != null) ...<Widget>[SizedBox(height: t.gapMin), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(copy, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          if (action != null) ...<Widget>[SizedBox(height: t.gapMin), action!],
        ],
      ),
    );
  }
}

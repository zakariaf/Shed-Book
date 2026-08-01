// lib/core/ui/components/shed_banner.dart
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/time/instant.dart';

/// **Never modal. Never on the five shed screens. Never 22:00–06:00.**
///
/// `now` is a parameter because a component in `lib/core/ui/` reads no clock and
/// no provider (layer rule 7, R24). The caller passes `appNow()` or the value it
/// already holds from `minuteTickProvider`.
final class ShedBanner extends StatelessWidget {
  const ShedBanner({
    required this.now,
    required this.message,
    required this.primary,
    super.key,
    this.secondary,
  });

  final Instant now;

  /// Arrives localised, and states a fact rather than a judgement.
  final String message;

  /// `('Export now', …)` / `('Unlock', …)`.
  final ({String label, String semanticLabel, VoidCallback onTap}) primary;

  /// `('Not this season', …)`. The upgrade row has none — **and there is no way
  /// to pass a third.** Two actions is the ceiling, in the type.
  final ({String label, String semanticLabel, VoidCallback onTap})? secondary;

  @override
  Widget build(BuildContext context) {
    // THE ONE DEFINITION OF THE WINDOW (11 §9.2), imported rather than retyped.
    // Writing `h >= 22 || h < 6` here is how the policy and the row end up
    // disagreeing about when the app goes quiet — and the row is the half a
    // shepherd actually sees at 03:20.
    if (isQuietHours(now)) {
      return const SizedBox.shrink();
    }

    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    Widget action(({String label, String semanticLabel, VoidCallback onTap}) a) => ShedTapTarget(
      onTap: a.onTap,
      semanticLabel: a.semanticLabel,
      minSize: t.tapIndelibleFloor,
      child: Center(child: Text(a.label, style: text.labelLarge)),
    );

    return ConstrainedBox(
      // THE SAME PIXELS AT 0 EWES AS AT 15 (06 §12): the height comes from
      // tapHero and not from the message, so a banner that gains a number does
      // not move the content under it.
      //
      // A MINIMUM rather than a fixed height, and a Wrap rather than a Row.
      // MEASURED: at 200% with Bold Text the message and two actions overflow
      // one line by 251 px. Decision #99 forbids clamping the text and there is
      // no ellipsis in this product, so the LAYOUT gives way — the actions drop
      // to a second run and the banner grows. At every ordinary scale it is one
      // run and exactly tapHero.
      constraints: BoxConstraints(minHeight: t.tapHero, minWidth: double.infinity),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.surfaceRaised,
          border: Border.all(color: t.outline, width: t.outlineWidth),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: t.gapMin),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: t.gapMin,
            runSpacing: t.gapMin,
            children: <Widget>[
              Text(message, style: text.bodyMedium),
              action(primary),
              if (secondary != null) action(secondary!),
            ],
          ),
        ),
      ),
    );
  }
}

extension on ShedTokens {
  /// indelible.md §4.5 builds to 64 where `tapMin` is the 60 pt contract.
  double get tapIndelibleFloor => tapMin + gapMin / 4;
}

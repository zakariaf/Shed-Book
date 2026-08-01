// lib/core/ui/components/shed_secondary_button.dart
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// indelible.md §7.13's two forms.
///
/// The colour channel is **not** what distinguishes them: `outlined` draws a
/// border and no underline, `inStream` draws an underline and no border, so the
/// two remain distinguishable to somebody who cannot tell the inks apart
/// (decision #106, WCAG 1.4.1 Level A).
enum ShedSecondaryButtonForm {
  /// 06 §12's contract — 2 px at `outlineWidth`, fill `surfaceFill`.
  outlined,

  /// The filter row: no fill, no border, a 2 px underline the width of the word.
  inStream,
}

final class ShedSecondaryButton extends StatelessWidget {
  const ShedSecondaryButton({
    required this.label,
    required this.onTap,
    required this.semanticLabel,
    super.key,
    this.form = ShedSecondaryButtonForm.outlined,
    this.selected = false,
  });

  final String label;

  /// Non-nullable, for the reason `ShedPrimaryButton` documents: a null callback
  /// announces a disabled node, makes the geometric gate skip it, and leaves a
  /// live-looking control that does nothing.
  final VoidCallback onTap;

  final String semanticLabel;
  final ShedSecondaryButtonForm form;

  /// Only meaningful for [ShedSecondaryButtonForm.inStream]: the underline lifts
  /// to `textPrimary` while its siblings sit at `textSecondary`.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final Color ink = selected ? t.textPrimary : t.textSecondary;

    return ShedTapTarget(
      onTap: onTap,
      semanticLabel: semanticLabel,
      minSize: t.tapPrimary,
      child: switch (form) {
        ShedSecondaryButtonForm.outlined => DecoratedBox(
          decoration: BoxDecoration(
            color: t.surfaceFill,
            border: Border.all(color: t.outline, width: t.outlineWidth),
            borderRadius: BorderRadius.all(Radius.circular(t.radiusControl)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: Center(child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
          ),
        ),
        ShedSecondaryButtonForm.inStream => DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: ink, width: t.outlineWidth),
            ),
          ),
          child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: ink)),
        ),
      },
    );
  }
}

// lib/core/ui/components/shed_receipt.dart
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// **P2: there is no SnackBar. THIS is the receipt.**
///
/// Because it is not a `SnackBar` it inherits none of the framework's wrapping,
/// and 06 §10.3 lists what it must therefore carry itself:
///
///   * its own `Semantics(liveRegion: true)`, so the announcement happens at
///     all;
///   * the same text-uniqueness rule — two receipts for the same ewe in the same
///     minute must differ, or the second is not announced (`didChangeLabel`);
///   * its own dismiss target at the tap floor, because there is no framework
///     action button to inherit one from.
///
/// The confirmation **is the committed row**, one line above the one being
/// written; this bar is the margin note beside it, and its undo window is
/// **stated in seconds** rather than implied.
final class ShedReceiptBar extends StatelessWidget {
  const ShedReceiptBar({
    required this.message,
    required this.undoLabel,
    required this.undoSemanticLabel,
    required this.onUndo,
    super.key,
  });

  /// Arrives localised, and is **unique per receipt** — it carries the tag and
  /// the second, not just the verb, because an assistive technology skips a
  /// live-region update whose text has not changed.
  final String message;

  /// `UNDO`, `Correct this`, `Void this`. **No default here**: the verb belongs
  /// to the screen that knows what is being undone.
  final String undoLabel;

  final String undoSemanticLabel;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      child: SizedBox(
        width: double.infinity,
        height: t.tapHero,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.surfaceRaised,
            border: Border(
              top: BorderSide(color: t.outline, width: t.outlineWidth),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(message, style: text.bodyMedium, maxLines: 1)),
                ShedTapTarget(
                  onTap: onUndo,
                  semanticLabel: undoSemanticLabel,
                  minSize: t.tapIndelible,
                  child: Center(child: Text(undoLabel, style: text.labelLarge)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

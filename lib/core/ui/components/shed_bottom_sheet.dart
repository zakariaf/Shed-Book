// lib/core/ui/components/shed_bottom_sheet.dart
//
// THE ONLY OVERLAY IN THE APP, and the only call site of Flutter's modal-sheet
// function.
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// Opens the one overlay this app has.
///
/// **All three permissive flags are typed, and that is the whole point of there
/// being one call site.** Flutter's defaults are all wrong here (06 §7):
///
///   * `enableDrag` defaults to **true**, and it is drag-to-dismiss — a banned
///     gesture that would silently discard a chooser;
///   * a drag handle advertises a gesture this app does not support;
///   * a scrim tap is not a labelled target, so it is invisible to Switch
///     Control and unreachable by anyone who cannot see the dimmed area.
///
/// The gate can only see a literal `true` — **it cannot see an omission** — so
/// the rule is held by there being exactly one place where the flags could be
/// omitted, and a policy test that reads all three off this file.
Future<T?> showShedBottomSheet<T>(
  BuildContext context, {
  required Widget child,
  required String dismissLabel,
  required String dismissSemanticLabel,
  required String barrierLabel,
  bool fillsViewport = false,
}) {
  final ShedTokens t = context.tokens;
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: false,
    enableDrag: false,
    isDismissible: false,
    // 60% of the viewport is above Flutter's 9/16 default cap, so the keypad
    // sheet does not fit without this. A chooser is content-height and does not
    // need it (indelible.md §7.14).
    isScrollControlled: fillsViewport,
    barrierLabel: barrierLabel,
    backgroundColor: t.surfaceRaised,
    // Radius 0 — "a document has no corners".
    shape: const RoundedRectangleBorder(),
    builder: (BuildContext _) => ShedBottomSheet(
      dismissLabel: dismissLabel,
      dismissSemanticLabel: dismissSemanticLabel,
      fillsViewport: fillsViewport,
      child: child,
    ),
  );
}

final class ShedBottomSheet extends StatelessWidget {
  const ShedBottomSheet({
    required this.child,
    required this.dismissLabel,
    required this.dismissSemanticLabel,
    super.key,
    this.fillsViewport = false,
  }) : assert(dismissLabel != 'Cancel', "07 §15.5: 'Cancel' is not a verb here"),
       assert(dismissLabel != 'Save', 'indelible.md §11 test 7');

  final Widget child;

  /// indelible.md §7.14: `CLOSE`. Arrives localised.
  final String dismissLabel;

  final String dismissSemanticLabel;
  final bool fillsViewport;

  /// indelible.md §7.14: 60% of the viewport for the keypad.
  static const double viewportFraction = 0.6;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final double? height = fillsViewport
        ? MediaQuery.sizeOf(context).height * viewportFraction
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        // A 2 px TOP RULE AND NO SHADOW. indelible.md §4.2: nothing casts a
        // shadow. A shadow is the first thing a Material default puts back, and
        // under a head torch it reads as a smudge rather than as depth.
        border: Border(
          top: BorderSide(color: t.textPrimary, width: t.outlineWidth),
        ),
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Column(
          mainAxisSize: fillsViewport ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // The dismiss control sits TOP-RIGHT, where a thumb reaches it
            // without crossing the content — and it is a labelled target,
            // because the scrim is not one.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.all(t.gapMin / 2),
                child: ShedTapTarget(
                  onTap: () => Navigator.of(context).pop(),
                  semanticLabel: dismissSemanticLabel,
                  minSize: t.tapPrimary,
                  child: Center(
                    child: Text(dismissLabel, style: Theme.of(context).textTheme.labelLarge),
                  ),
                ),
              ),
            ),
            if (fillsViewport) Expanded(child: child) else Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

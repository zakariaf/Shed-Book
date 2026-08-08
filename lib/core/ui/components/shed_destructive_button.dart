// lib/core/ui/components/shed_destructive_button.dart
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/control_voice.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// Two steps, and **the first one is not a dialog**.
///
/// 06 §12 lists `confirming` as a real state of this component precisely so a
/// screen never has to open a modal to get a confirmation. The modal-opening
/// call is banned outside the two allowlisted Settings files (`CONVENTIONS §4.7`,
/// gate row `ui.show_dialog`) — described rather than spelled here, because that
/// row scans this file and a quoted prohibition is indistinguishable from the
/// thing prohibited. A modal at 03:20 is a second thing to find in the dark.
enum ShedDestructiveButtonState { armed, confirming }

/// The only two-step control in the app.
///
/// **It reserves its own separation.** The widget cannot see its neighbours, so
/// it pads by `gapDestructive` inside its own laid-out box. That is what makes
/// the rule structural rather than something twelve screens have to remember —
/// and a screen that forgets cannot produce a flush neighbour, because the gap
/// is already inside this widget's rect.
final class ShedDestructiveButton extends StatefulWidget {
  const ShedDestructiveButton({
    required this.label,
    required this.confirmLabel,
    required this.onConfirmed,
    required this.semanticLabel,
    required this.confirmSemanticLabel,
    super.key,
  });

  /// `STRIKE`.
  final String label;

  /// `STRIKE — TAP AGAIN`. **The word changes, not only the colour** — decision
  /// #106 means the second step has to be readable to somebody who cannot see
  /// the madder ink at all.
  final String confirmLabel;

  /// Fires on the **second** tap only.
  final VoidCallback onConfirmed;

  final String semanticLabel;
  final String confirmSemanticLabel;

  @override
  State<ShedDestructiveButton> createState() => _ShedDestructiveButtonState();
}

class _ShedDestructiveButtonState extends State<ShedDestructiveButton> {
  ShedDestructiveButtonState _state = ShedDestructiveButtonState.armed;

  /// **There is no timer, and that is deliberate.**
  ///
  /// A state that unwinds itself after n seconds is a state that changes under a
  /// thumb already moving: the shepherd sees `TAP AGAIN`, commits to the second
  /// press, and the control reverts between the decision and the contact. So
  /// `confirming` decays only when the widget goes away — a route pop or a
  /// dispose — and `--motion-press` (40 ms) is the only duration this component
  /// holds.
  void _onTap() {
    switch (_state) {
      case ShedDestructiveButtonState.armed:
        setState(() => _state = ShedDestructiveButtonState.confirming);
      case ShedDestructiveButtonState.confirming:
        widget.onConfirmed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final bool confirming = _state == ShedDestructiveButtonState.confirming;

    return Padding(
      // The reserved separation, inside this widget's own box.
      padding: EdgeInsets.all(t.gapDestructive),
      child: ShedTapTarget(
        onTap: _onTap,
        semanticLabel: confirming ? widget.confirmSemanticLabel : widget.semanticLabel,
        minSize: t.tapPrimary,
        // NO FILLED SURFACE behind the madder ink (indelible.md §7.13). A
        // destructive control that fills is a destructive control that draws the
        // eye, and this one is meant to be found only when looked for.
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: confirming ? t.statusLoss : t.outline, width: t.outlineWidth),
            borderRadius: BorderRadius.all(Radius.circular(t.radiusControl)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: Center(
              child: Text(
                // **THE CONTROL VOICE** (§3.1, ruling P7). The two honest
                // deletes wear this button, and neither their copy nor their
                // typed-confirmation requirement changes here — only how the
                // word is set.
                controlCase(confirming ? widget.confirmLabel : widget.label),
                style: controlStyle(
                  context,
                  Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: confirming ? t.statusLoss : t.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

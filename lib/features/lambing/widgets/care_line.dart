// lib/features/lambing/widgets/care_line.dart
//
// THERE IS NO CHECKBOX GLYPH, AND indelible.md §7.10 SAYS WHY IN ONE SENTENCE:
// "a tick is a state and this system does not record states — it records
// events. Ticking `colostrum given` at 03:24 records that you ticked it at
// 03:24, which is a materially better record and costs nothing."
//
// TWO STATES, NOT THREE, AND THE MISSING ONE IS DELIBERATE. *Not recorded* and
// *done* exist; there is NO WAY TO RECORD "NO". A shepherd who did not dip a
// navel has recorded nothing, and the app must not turn that into a claim
// (decision #43, 07 §6.2). A boolean column would delete both facts at once.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// What one care line knows about itself.
///
/// [doneAt] and [undoneAt] are already-formatted strings, because the widget
/// that draws a time must not also decide how to format it — that is
/// `formatShedTime`'s job and it lives at the screen edge with the locale.
typedef CareLineState = ({
  String label,

  /// `null` is UNSET — never *no*, never `0`, never *not given*.
  String? doneAt,

  /// Non-null only after the event was struck. Both stamps print: the DONE one
  /// struck through, the UNDONE one beside it.
  String? undoneAt,
  String semanticLabel,
});

/// One 64 px ruled line: label left, a 64 × 64 target right.
class CareLine extends StatelessWidget {
  const CareLine({required this.state, required this.onPressed, super.key});

  final CareLineState state;

  /// **NEVER NULL, AND NEVER DISABLED** (`indelible.md §7.10`: *"Disabled —
  /// never"*). A dead control under a cold thumb is indistinguishable from a
  /// missed tap, which is the whole argument, and it is why this parameter is
  /// required rather than nullable.
  final VoidCallback onPressed;

  bool get _isDone => state.doneAt != null;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return ShedTapTarget(
      semanticLabel: state.semanticLabel,
      minSize: t.tapIndelible,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: t.gapMin),
          child: Row(
            children: <Widget>[
              // THE LABEL IS THE STATE'S FIRST CHANNEL. Unset it sits in the
              // secondary ink under a dotted rule; done it lifts to the primary
              // ink over a solid one. `10 §5.2`: colour is never one of the
              // three channels on its own.
              // FLEXIBLE, NOT EXPANDED, AND MEASURED. Expanded takes ALL the
              // remaining width before the stamps are laid out, so the two
              // stamps of the Undone state — `D̶O̶N̶E̶ ̶0̶3̶:̶2̶4̶ · UNDONE 03:31` —
              // overflowed the row by 74 px. Flexible lets the label give way
              // instead, which is the right one to lose: the stamps carry the
              // times, and the label is the one thing the shepherd already
              // knows because it never changes.
              Flexible(
                child: _UnderlinedLabel(
                  label: state.label,
                  done: _isDone,
                  style: (_isDone ? text.titleMedium : text.bodyMedium)?.copyWith(
                    color: _isDone ? t.textPrimary : t.textSecondary,
                  ),
                  t: t,
                ),
              ),
              if (state.doneAt case final String at)
                Flexible(
                  child: _Stamp(at: at, struck: state.undoneAt != null),
                ),
              if (state.undoneAt case final String at) ...<Widget>[
                Text(' · ', style: text.bodySmall),
                Flexible(child: _Stamp(at: at, struck: false, undone: true)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The label with its rule underneath — **dotted when unset, solid when done**.
///
/// The dots are drawn rather than dashed with a border, because Flutter has no
/// dotted `BorderSide` and the alternative — a dashed image asset — would not
/// take the palette.
class _UnderlinedLabel extends StatelessWidget {
  const _UnderlinedLabel({
    required this.label,
    required this.done,
    required this.style,
    required this.t,
  });

  final String label;
  final bool done;
  final TextStyle? style;
  final ShedTokens t;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
      SizedBox(height: t.gapMin / 4),
      SizedBox(
        width: t.tapIndelible,
        height: t.outlineWidth,
        child: CustomPaint(
          painter: _RulePainter(
            colour: done ? t.textPrimary : t.outline,
            dotted: !done,
            width: t.outlineWidth,
          ),
        ),
      ),
    ],
  );
}

class _RulePainter extends CustomPainter {
  const _RulePainter({required this.colour, required this.dotted, required this.width});

  final Color colour;
  final bool dotted;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = colour
      ..strokeWidth = width
      ..strokeCap = StrokeCap.square;

    if (!dotted) {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
      return;
    }

    // Dots of one rule-width, spaced two apart. Derived from the rule width so
    // the pattern scales with the token rather than with a literal.
    final double step = width * 3;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(x + width, size.height / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_RulePainter old) =>
      old.colour != colour || old.dotted != dotted || old.width != width;
}

/// `DONE 03:24` — an **unboxed** stamp, the word in the chrome voice and the
/// time tabular beside it. Struck when the event was undone.
class _Stamp extends StatelessWidget {
  const _Stamp({required this.at, required this.struck, this.undone = false});

  final String at;
  final bool struck;
  final bool undone;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return Text(
      at,
      maxLines: 1,
      // ELLIPSISED RATHER THAN SHRUNK. A shrink-to-fit widget is banned (10
      // §4.4): shrinking a stamp to fit is how an 18 pt floor becomes a 9 pt
      // time on the one device whose owner turned the text up.
      overflow: TextOverflow.ellipsis,
      style: (undone ? text.labelSmall : text.bodySmall)?.copyWith(
        color: struck ? t.textSecondary : t.textPrimary,
        // THE STRIKE IS A LINE THROUGH THE STAMP, NOT ITS REMOVAL. Rule 1
        // applies to a checkbox exactly as it applies to a lambing: the DONE
        // stamp stays on the page with a line through it, and UNDONE prints
        // beside it with its own time.
        decoration: struck ? TextDecoration.lineThrough : null,
        decorationColor: struck ? t.textSecondary : null,
        decorationThickness: struck ? 2 : null,
      ),
    );
  }
}

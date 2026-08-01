// lib/core/ui/components/shed_field_row.dart
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_status_badge.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// A field line: **label above, value on a rule, dotted rule when unset.**
///
/// THERE IS DELIBERATELY NO `hintText`, NO placeholder, NO `initialValue`, NO
/// `defaultValue` AND NO `InputDecoration` ON THIS API — and the absence is the
/// mechanism, not a convention. indelible.md §9 safety rule 1: *"the text-field
/// component forbids placeholder text system-wide so this cannot regress by
/// accident."*
///
/// Two reasons, and the first is a food-chain risk. A placeholder in the
/// withdrawal-days field is safety rule §12.1 broken (spec §12.1) — the shepherd
/// reads a number the app suggested and the meat clears early. And in the dark a
/// grey placeholder is indistinguishable from an entered value, so the second
/// failure is that nobody can tell which field they have filled in.
///
/// **It is not a `TextField`.** Decision #57 makes `ShedKeypad` the only numeric
/// entry route; `onTap` opens whatever surface the screen chooses.
///
/// It also formats nothing. A date arrives already rendered as `11 Mar 2026` by
/// `formatters.dart` (R60) — if this component ever formats a date, two rules
/// broke at once.
final class ShedFieldRow extends StatelessWidget {
  ShedFieldRow({
    required this.label,
    required this.value,
    required this.onTap,
    required this.semanticLabel,
    super.key,
    this.stamp,
  }) : assert(
         value == null || value.trim().isNotEmpty,
         "'' and null are different facts: null is unset, '' is a value nobody "
         'can see. Pass null.',
       );

  /// **Always above the value, never inside it.** A label that becomes a
  /// placeholder is a label that disappears the moment the field is filled, and
  /// then nobody can check what they answered.
  final String label;

  /// `null` is unset — the dotted rule. It is not `''`.
  final String? value;

  final VoidCallback onTap;
  final String semanticLabel;

  /// e.g. `ShedStamp.yourEntry` on the withdrawal-days field.
  final ShedStamp? stamp;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final String? shown = value;

    return ShedTapTarget(
      onTap: onTap,
      semanticLabel: semanticLabel,
      minSize: t.tapIndelibleFloor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: text.titleSmall),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: t.outline,
                  width: t.outlineWidth,
                  // The unset rule is DOTTED and the set rule is solid: the
                  // second non-colour channel, so an empty field is legible as
                  // empty under a head torch.
                  style: shown == null ? BorderStyle.none : BorderStyle.solid,
                ),
              ),
            ),
            child: shown == null
                ? _DottedRule(colour: t.outline, width: t.outlineWidth)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(shown, style: text.bodyLarge),
                      if (stamp != null) ...<Widget>[
                        SizedBox(width: t.gapMin / 2),
                        ShedStatusBadge(stamp: stamp!, label: label),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// The unset rule. A dashed line drawn directly, because `BorderStyle` has no
/// dotted member.
class _DottedRule extends StatelessWidget {
  const _DottedRule({required this.colour, required this.width});

  final Color colour;
  final double width;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DottedRulePainter(colour: colour, width: width),
    size: Size(double.infinity, width),
  );
}

class _DottedRulePainter extends CustomPainter {
  const _DottedRulePainter({required this.colour, required this.width});

  final Color colour;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = colour
      ..strokeWidth = width;
    const double on = 4;
    const double off = 4;
    for (double x = 0; x < size.width; x += on + off) {
      canvas.drawLine(Offset(x, 0), Offset(x + on, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DottedRulePainter old) => old.colour != colour || old.width != width;
}

extension on ShedTokens {
  /// indelible.md §4.5 builds to 64 while `tapMin` is the 60 pt contract. A
  /// field row is the smallest thing on an entry screen, so it takes the design
  /// figure rather than the floor.
  double get tapIndelibleFloor => tapMin + gapMin / 4;
}

// lib/core/ui/components/shed_tally.dart
//
// A TRUE FIVE-BAR GATE. One filled rect per mark, and the FIFTH mark of any
// group is a diagonal drawn across the previous four — because a shepherd
// counting to fourteen lambs in a night should not have to count to fourteen.
// Four uprights and a slash read as five at a glance; fourteen uprights do not.
//
// It lives in lib/core/ui/components/ and not under lib/features/lambing/
// widgets/ because the pen tile (N19) and the withdrawal day tally (N20-T03)
// print the SAME mark, and layer rule 6 forbids a sibling-feature import. R70.
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// The mark's geometry, from `indelible.md` §6.2. Named rather than typed
/// inline: `token.magic_size` is right to fire on a bare number, and these are
/// the component's own constants rather than palette values.
class _Mark {
  static const double width = 8;
  static const double height = 30;
  static const double gap = 3;
  static const int perGroup = 5;
}

class ShedTally extends StatelessWidget {
  const ShedTally({
    required this.count,
    required this.semanticLabel,
    super.key,
    this.struck = const <int>{},
  });

  /// Total marks, including struck ones.
  final int count;

  /// **Zero-based indices of struck marks.** A struck mark KEEPS ITS RECT and
  /// takes a line through it — Indelible Rule 1: nothing disappears from the
  /// page, so the count a shepherd sees never silently shrinks.
  final Set<int> struck;

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: CustomPaint(
          size: Size(_widthFor(count), _Mark.height),
          painter: _TallyPainter(
            count: count,
            struck: struck,
            ink: t.textPrimary,
            strikeInk: t.statusLoss,
            strikeWidth: t.outlineWidth,
          ),
        ),
      ),
    );
  }

  /// Each group of five occupies four upright slots — the fifth is the diagonal
  /// across them — plus one group gap.
  static double _widthFor(int count) {
    if (count <= 0) {
      return 0;
    }
    final int groups = count ~/ _Mark.perGroup;
    final int remainder = count % _Mark.perGroup;
    final int slots = groups * 4 + remainder;
    return slots * (_Mark.width + _Mark.gap) + groups * _Mark.gap;
  }
}

class _TallyPainter extends CustomPainter {
  const _TallyPainter({
    required this.count,
    required this.struck,
    required this.ink,
    required this.strikeInk,
    required this.strikeWidth,
  });

  final int count;
  final Set<int> struck;
  final Color ink;
  final Color strikeInk;
  final double strikeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill = Paint()..color = ink;
    final Paint strike = Paint()
      ..color = strikeInk
      ..strokeWidth = strikeWidth
      ..strokeCap = StrokeCap.square;

    double x = 0;
    for (int group = 0; group * _Mark.perGroup < count; group++) {
      final int inThis = (count - group * _Mark.perGroup).clamp(0, _Mark.perGroup);
      final double groupStart = x;
      final int uprights = inThis >= _Mark.perGroup ? 4 : inThis;

      for (int i = 0; i < uprights; i++) {
        final int index = group * _Mark.perGroup + i;
        canvas.drawRect(Rect.fromLTWH(x, 0, _Mark.width, _Mark.height), fill);
        if (struck.contains(index)) {
          canvas.drawLine(
            Offset(x - _Mark.gap, _Mark.height / 2),
            Offset(x + _Mark.width + _Mark.gap, _Mark.height / 2),
            strike,
          );
        }
        x += _Mark.width + _Mark.gap;
      }

      // THE FIFTH MARK IS THE DIAGONAL, drawn across the four already there.
      if (inThis >= _Mark.perGroup) {
        canvas.drawLine(
          Offset(groupStart - _Mark.gap, _Mark.height),
          Offset(x - _Mark.gap, 0),
          Paint()
            ..color = ink
            ..strokeWidth = _Mark.width
            ..strokeCap = StrokeCap.square,
        );
        x += _Mark.gap;
      }
    }
  }

  @override
  bool shouldRepaint(_TallyPainter old) =>
      old.count != count ||
      old.struck.length != struck.length ||
      old.ink != ink ||
      old.strikeInk != strikeInk;
}

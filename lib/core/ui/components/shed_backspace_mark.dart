// lib/core/ui/components/shed_backspace_mark.dart
//
// **THE DELETE KEY WAS RENDERING AS A TOFU BOX ON EVERY DEVICE, AND ONLY A
// GOLDEN COULD SHOW IT.**
//
// `shed_keypad.dart` drew it as `Text('⌫')`. The bundled family — Atkinson
// Hyperlegible Next, decision #98, the only font this app ships — has no glyph
// at that codepoint, so the key painted an empty rectangle: no fallback stack to
// rescue it: there is no second family, and the one package that fetches a face
// at runtime is banned outright as a network path. Every
// widget test passed. `find.byKey('quick_entry.keypad.backspace')` found it, the
// semantics label read *Backspace*, the tap target measured 60 pt, and the
// shepherd saw a box.
//
// `indelible-marks-and-strikes` §2 already said not to type it: `⌫` is one of
// the six marks, and every mark in this system is **drawn** — 2 px stroke, butt
// caps, miter joins, a 24 × 24 or 28 × 28 box, `currentColor` so it dims with a
// struck row, and no fills except tally strokes. A glyph is not a mark; it is a
// bet on somebody else's font.
//
// **`⌫` DELETES A DIGIT YOU ARE TYPING. IT NEVER DELETES A RECORD.** The two
// names collide and the concepts do not — erasure does not exist in this
// product, and the one place the word *delete* is legitimate is a keypad.
library;

import 'package:flutter/material.dart';

/// The mark's box. 28 × 28 is one of the two legal sizes (§2); it is not the tap
/// target, which is the key around it.
class _Box {
  static const double side = 28;

  /// Where the pointed left end sits, vertically centred.
  static const double point = 2;

  /// The body's left edge — the width of the arrowhead.
  static const double shoulder = 10;

  /// The cross inside, inset from the body.
  static const double crossInset = 4;
}

/// A drawn backspace mark: an arrow-ended box with a cross in it.
class ShedBackspaceMark extends StatelessWidget {
  const ShedBackspaceMark({required this.colour, required this.strokeWidth, super.key});

  /// **THE ENCLOSING KEY'S INK, WHICH IS WHAT `currentColor` MEANS HERE** — so a
  /// key that dims dims its mark with it, exactly as a struck row dims the marks
  /// in its margin.
  ///
  /// Passed in rather than read: `lib/core/ui/` takes its metrics and its ink
  /// from the widget above, and a raw-hex fallback in this file would be a
  /// `token.raw_color` hit — correctly, since a mark with a hard-coded white
  /// would survive every palette change including the two night-shift ones.
  final Color colour;

  /// `context.tokens.outlineWidth`, likewise from above. A literal here would be
  /// a `token.magic_size` hit.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(_Box.side, _Box.side),
    painter: _BackspacePainter(colour: colour, strokeWidth: strokeWidth),
  );
}

class _BackspacePainter extends CustomPainter {
  const _BackspacePainter({required this.colour, required this.strokeWidth});

  final Color colour;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pen = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      // NOTHING IN A PRINTED BOOK HAS A ROUNDED END (§2).
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter;

    final double mid = size.height / 2;
    final double right = size.width - _Box.point;
    final double top = _Box.point * 2;
    final double bottom = size.height - _Box.point * 2;

    canvas.drawPath(
      Path()
        ..moveTo(_Box.point, mid)
        ..lineTo(_Box.shoulder, top)
        ..lineTo(right, top)
        ..lineTo(right, bottom)
        ..lineTo(_Box.shoulder, bottom)
        ..close(),
      pen,
    );

    // The cross. Inside the body, never touching the outline — a cross that
    // meets the box reads as a filled shape at 30% brightness.
    final double x0 = _Box.shoulder + _Box.crossInset;
    final double x1 = right - _Box.crossInset;
    final double y0 = top + _Box.crossInset;
    final double y1 = bottom - _Box.crossInset;

    canvas
      ..drawLine(Offset(x0, y0), Offset(x1, y1), pen)
      ..drawLine(Offset(x1, y0), Offset(x0, y1), pen);
  }

  @override
  bool shouldRepaint(_BackspacePainter old) =>
      old.colour != colour || old.strokeWidth != strokeWidth;
}

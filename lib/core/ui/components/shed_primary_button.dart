// lib/core/ui/components/shed_primary_button.dart — the corner slab.
//
// It lives here rather than under a feature's widgets/ because layer rule 6
// forbids a sibling import: a button built inside quick_entry/ could never be
// reused by Lambing Entry.
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// The states of indelible.md §7.1.
///
/// **There is no `disabled` member, and that absence is the point.** 06 §12
/// lists one; indelible.md rules that the slab still fires and opens the tag
/// sheet, and indelible.md wins because **a dead rectangle in the dark is
/// indistinguishable from a missed tap**. At 03:20 a shepherd who presses a
/// disabled button concludes the phone did not register the press, and presses
/// harder.
enum ShedPrimaryButtonState {
  /// Fill `surfaceFill`, outline at `outlineWidth`, label at full ink.
  ready,

  /// A subject has landed; the next press writes. The outline lifts to
  /// `textPrimary` and the corner tick prints.
  armed,

  /// What is missing, said in words. Same box, same target, different verb and
  /// a dotted outline. **`onTap` still fires** — it opens the thing that is
  /// missing.
  refusing,

  /// Pressing would contradict something already recorded. Fires normally; the
  /// query mark is the record's job, not the button's.
  querying,
}

/// The primary action on a shed screen.
///
/// **`onTap` is non-nullable, and that is the whole task.** `ShedTapTarget`
/// takes a nullable callback and sets `Semantics(enabled: onTap != null)`. Pass
/// null and three things happen at once: the node announces as a disabled
/// button, 06 §6.3's geometric gate *skips* it, and a shepherd taps a
/// live-looking rectangle that does nothing. Narrowing the type here makes that
/// failure mode unexpressible rather than merely discouraged.
///
/// The widget key comes from the SCREEN, not from here (`CONVENTIONS §4.5`):
/// `quick_entry.slab`, `flock.slab`. A `Key('primaryButton')` is a defect (R59).
final class ShedPrimaryButton extends StatelessWidget {
  const ShedPrimaryButton({
    required this.label,
    required this.onTap,
    required this.semanticLabel,
    super.key,
    this.state = ShedPrimaryButtonState.ready,
  });

  /// Already localised and already upper-cased by the caller — `+ LAMB`,
  /// `+ EWE`, `+ DOSE`, `TAG FIRST`. **This file composes no copy**: a component
  /// that builds a string is a component that needs an ARB entry, and then the
  /// same sentence exists in two places the moment a screen wants it phrased
  /// differently.
  final String label;

  final VoidCallback onTap;
  final String semanticLabel;
  final ShedPrimaryButtonState state;

  /// Dotted only while refusing. The outline says *what kind of press this is*
  /// without changing the box, the target or the verb's availability.
  bool get _isDotted => state == ShedPrimaryButtonState.refusing;

  /// The outline lifts to full ink once a subject has landed.
  Color _outlineColour(ShedTokens t) =>
      state == ShedPrimaryButtonState.armed ? t.textPrimary : t.outline;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    return ShedTapTarget(
      onTap: onTap,
      semanticLabel: semanticLabel,
      // 88 — one scalar, both axes.
      minSize: t.tapHero,
      child: ConstrainedBox(
        // tapHero is square; 06 §12 also wants at least 2 x tapPrimary of
        // WIDTH. TOKEN FIRST, LITERAL SECOND: token.magic_size matches
        // `minWidth:` followed by a digit, so `2 * t.tapPrimary` is a gate
        // failure and `t.tapPrimary * 2` is not. The rule is coarse on purpose
        // and the remedy is free.
        constraints: BoxConstraints(minWidth: t.tapPrimary * 2),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: t.surfaceFill,
            shape: _SlabBorder(
              colour: _outlineColour(t),
              width: t.outlineWidth,
              radius: t.radiusControl,
              dotted: _isDotted,
            ),
          ),
          child: Center(
            // labelLarge, never a constructed TextStyle. 06 §5.4: building a
            // fresh TextStyle instead of using the role drops fontFeatures, and
            // the numerals start jittering.
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
      ),
    );
  }
}

/// A square-cornered border that can draw dotted.
///
/// Written rather than reached for because Flutter has no dotted `BorderSide`:
/// `BorderStyle` is `none` or `solid`. The alternative — a package — would have
/// to clear the G2 dependency allowlist for one dashed rectangle.
class _SlabBorder extends OutlinedBorder {
  const _SlabBorder({
    required this.colour,
    required this.width,
    required this.radius,
    required this.dotted,
  });

  final Color colour;
  final double width;
  final double radius;
  final bool dotted;

  BorderRadius get _radius => BorderRadius.all(Radius.circular(radius));

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  ShapeBorder scale(double t) =>
      _SlabBorder(colour: colour, width: width * t, radius: radius * t, dotted: dotted);

  @override
  _SlabBorder copyWith({BorderSide? side}) => this;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_radius.toRRect(rect).deflate(width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_radius.toRRect(rect));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final Paint paint = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    final Path outline = Path()..addRRect(_radius.toRRect(rect).deflate(width / 2));
    canvas.drawPath(dotted ? _dash(outline) : outline, paint);
  }

  /// Dashes any path by walking its metrics. `dashOn` and `dashOff` are equal so
  /// the rhythm reads as a dotted rule rather than as a dashed one.
  static Path _dash(Path source) {
    const double dashOn = 4;
    const double dashOff = 4;
    final Path out = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dashOn;
        out.addPath(metric.extractPath(distance, next.clamp(0, metric.length)), Offset.zero);
        distance = next + dashOff;
      }
    }
    return out;
  }

  @override
  bool operator ==(Object other) =>
      other is _SlabBorder &&
      other.colour == colour &&
      other.width == width &&
      other.radius == radius &&
      other.dotted == dotted;

  @override
  int get hashCode => Object.hash(colour, width, radius, dotted);
}

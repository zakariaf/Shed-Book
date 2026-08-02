// lib/core/ui/components/shed_pen_tile.dart
//
// FIVE STATUSES, AND EVERY ONE CARRIES A WORD AND A MARK AS WELL AS ITS INK.
// `10 §5.2`: colour is never one of the three channels on its own, and this
// system has no status palette to lean on anyway — `loss` gets NO colour channel
// at all, because a colour-coded death reads wrong at 4am through a wet freezer
// bag.
//
// The obvious implementation is a coloured rectangle. Every rule in this file
// exists to make that unbuildable.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tally.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// The five states, mirrored from `PenTileStatus` in `lib/features/pens/`.
///
/// **MIRRORED RATHER THAN IMPORTED**, because `lib/core/ui/` may not import
/// `lib/features/` — a shared component that knew about one feature would be a
/// component only that feature could use. The two enums are kept in step by a
/// test on the source text, not by an import.
enum ShedPenTileStatus { settling, ready, attention, loss, empty }

/// What one tile renders. Words arrive resolved; this component never looks one
/// up (`layer.core_ui` forbids it reaching the ARB).
typedef ShedPenTileLabels = ({
  String penLabel,
  String? tag,

  /// The hours readout, or null on an empty pen.
  String? hours,

  /// The status word — `READY`, `CLEAR 14 JUL`, `DEAD`, `— empty —` — or null
  /// for `settling`, whose word IS its hours.
  String? statusWord,
  String semanticLabel,
});

class ShedPenTile extends StatelessWidget {
  const ShedPenTile({
    required this.status,
    required this.labels,
    required this.lambCount,
    required this.onTap,
    super.key,
  });

  final ShedPenTileStatus status;
  final ShedPenTileLabels labels;

  /// Drawn as TALLY STROKES, never a digit (`indelible.md §8` screen 7). Four
  /// lambs is four marks a shepherd counts at a glance from a metre away; `4` is
  /// a glyph they have to read.
  final int lambCount;

  /// **Never null, even on an empty pen.** An empty pen is the pen they are
  /// about to use, and a dead tile is indistinguishable from a missed tap.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return ShedTapTarget(
      semanticLabel: labels.semanticLabel,
      // `06 §12`: at least two tap-primaries square. A tile is aimed at from a
      // metre away with a gloved thumb, which is a different act from hitting a
      // key on a pad held at arm's length.
      minSize: t.tapPrimary * 2,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.all(t.gapMin / 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      labels.penLabel,
                      key: const Key('pen_tile.label'),
                      style: text.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // THE DAGGER IS `ready`'s NON-COLOUR MARK, and it is the only
                  // reinforcement that status gets.
                  if (status == ShedPenTileStatus.ready) ...<Widget>[
                    SizedBox(width: t.gapMin / 4),
                    Text('†', key: const Key('pen_tile.dagger'), style: text.bodyMedium),
                  ],
                  // THE CIRCLE-SLASH IS `attention`'s. `statusAttention` is
                  // reinforcement beside it, never the only channel.
                  if (status == ShedPenTileStatus.attention) ...<Widget>[
                    SizedBox(width: t.gapMin / 4),
                    Text(
                      '⊘',
                      key: const Key('pen_tile.badge'),
                      style: text.bodyMedium?.copyWith(color: t.statusAttention),
                    ),
                  ],
                ],
              ),
              if (labels.tag case final String tag)
                Text(
                  tag,
                  key: const Key('pen_tile.tag'),
                  style: text.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              // TALLY STROKES, NOT A DIGIT.
              if (lambCount > 0)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: t.gapMin / 4),
                  child: ShedTally(
                    key: const Key('pen_tile.tally'),
                    count: lambCount,
                    // THE TILE'S OWN LABEL ALREADY SAYS THE COUNT, and the whole
                    // tile is one utterance — so the tally is excluded from the
                    // node rather than announced again. Two announcements for
                    // one fact is the noise `10 §3.2` names.
                    semanticLabel: '',
                  ),
                ),
              Flexible(
                child: Text(
                  <String>[
                    if (labels.hours case final String h) h,
                    if (labels.statusWord case final String w) w,
                  ].join(' · '),
                  key: const Key('pen_tile.state'),
                  style: text.bodySmall?.copyWith(
                    // `ready` LIFTS THE HOURS from the secondary ink to the
                    // primary — the third channel on that status, after the word
                    // and the dagger.
                    color: status == ShedPenTileStatus.ready ? t.textPrimary : t.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // THE RULE BENEATH THE ROW IS THE SHAPE CHANNEL, and it differs
              // per status: single, doubled, dashed, dotted.
              _StatusRule(status: status, t: t),
            ],
          ),
        ),
      ),
    );
  }
}

/// The rule under the row. **Four different shapes, no colour required to tell
/// them apart** — which is what makes the tile legible to a reader who cannot
/// separate the inks, and to anybody at all through a wet freezer bag.
class _StatusRule extends StatelessWidget {
  const _StatusRule({required this.status, required this.t});

  final ShedPenTileStatus status;
  final ShedTokens t;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('pen_tile.rule'),
    width: double.infinity,
    // The doubled rule needs room for two lines and the 3 pt between them.
    height: t.outlineWidth * 2 + 3,
    child: CustomPaint(
      painter: _RulePainter(
        colour: status == ShedPenTileStatus.ready ? t.textPrimary : t.outline,
        style: status,
        width: t.outlineWidth,
      ),
    ),
  );
}

class _RulePainter extends CustomPainter {
  const _RulePainter({required this.colour, required this.style, required this.width});

  final Color colour;
  final ShedPenTileStatus style;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = colour
      ..strokeWidth = width
      ..strokeCap = StrokeCap.square;

    void line(double y, {bool dotted = false, bool dashed = false}) {
      if (!dotted && !dashed) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        return;
      }
      // Derived from the rule width so the pattern scales with the token rather
      // than with a literal.
      final double on = dashed ? width * 4 : width;
      final double step = on + width * 2;
      for (double x = 0; x < size.width; x += step) {
        canvas.drawLine(Offset(x, y), Offset(x + on, y), paint);
      }
    }

    switch (style) {
      // DOUBLED: two lines, three points apart. The heaviest mark on the board,
      // for the one status that says a decision is available.
      case ShedPenTileStatus.ready:
        line(width / 2);
        line(width / 2 + width + 3);
      case ShedPenTileStatus.attention:
        line(width / 2, dashed: true);
      case ShedPenTileStatus.empty:
        line(width / 2, dotted: true);
      case ShedPenTileStatus.settling:
      case ShedPenTileStatus.loss:
        line(width / 2);
    }
  }

  @override
  bool shouldRepaint(_RulePainter old) =>
      old.colour != colour || old.style != style || old.width != width;
}

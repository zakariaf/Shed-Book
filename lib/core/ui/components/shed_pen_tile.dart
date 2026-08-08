// lib/core/ui/components/shed_pen_tile.dart
//
// **IT WAS A TILE. IT IS A RULED ROW NOW, AND THE DOCUMENTS DISAGREED.**
//
// `06 §11` and `10 §5.2` describe pen TILES — a grid, corner triangles,
// hatching. `indelible.md §8` screen 7 refuses them in as many words, and the
// authority order puts `indelible.md` above the thirteen engineering documents:
//
// > *"The obvious answer is a 3 × 4 grid of tiles. This system does not have
// > tiles… A grid forces the eye to zig-zag — across, down, back, across — and
// > every hop is a chance to read pen 7's hours against pen 8's occupant. **A
// > ruled column does not zig-zag.**"*
//
// So the board is twelve ruled rows, 88 pt each, in the same document as every
// other screen — and this component is `ShedRuledRow` with three columns in it.
//
// **THE CLASS KEEPS ITS NAME AND THAT IS DELIBERATE, NOT AN OVERSIGHT.**
// `ShedPenTile` is a `CONVENTIONS §1` name; renaming it needs a numbered ruling
// in `§6`, and it is pinned by `test/policy/mirrored_enums_agree_test.dart`,
// `test/design/components_test.dart` and the board's own test. Re-shaping the
// widget is this task's; re-naming it is the owner's. The name is reported as
// wrong rather than quietly changed.
//
// ---------------------------------------------------------------------------
// THE OVER-THRESHOLD ROW CARRIES FOUR CHANNELS AND ANY THREE ARE SUFFICIENT
// ---------------------------------------------------------------------------
//
// `indelible.md §8`, verbatim in structure:
//
//   1. **A word.** `OVER` as a boxed stamp — `ShedStamp.over`, which has existed
//      in `ShedStatusBadge` since `10 §5.2` and had no caller until now.
//   2. **A mark.** `†` in the MARGIN CELL, at the heading role, the same dagger
//      used for every *"look at this"* in the app.
//   3. **Geometry.** The rule beneath the row DOUBLES. *"This is the strongest
//      signal of the four, because it is visible in peripheral vision from
//      across the shed at a distance where you cannot yet read `OVER`."*
//   4. **Ink density.** The hours figure lifts from `--ink-mid` to `--ink-full`.
//
// Delete the colour and three remain. There is no colour on this row at all
// except the attention mark, which is why the board reads identically under a
// red torch, in monochrome, and to a reader with deuteranopia.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_ruled_row.dart';
import 'package:shed_book/core/ui/components/shed_status_badge.dart';
import 'package:shed_book/core/ui/components/shed_tally.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// The five states, mirrored from `PenTileStatus` in `lib/features/pens/`.
///
/// **MIRRORED RATHER THAN IMPORTED**, because `lib/core/ui/` may not import
/// `lib/features/` — a shared component that knew about one feature would be a
/// component only that feature could use. The two enums are kept in step by
/// `test/policy/mirrored_enums_agree_test.dart`, which compares the declared
/// members and their order.
///
/// **THAT TEST DID NOT EXIST WHEN THIS COMMENT FIRST CLAIMED IT DID.** It was
/// written after a review found the claim false, and a comment describing a
/// mechanism that is not there is worse than no comment — it tells the next
/// reader the risk is already handled.
///
/// `ready` IS THE ROW `indelible.md §8` CALLS **OVER**: settled past the
/// shepherd's own turn-out threshold. The member name mirrors `PenTileStatus`
/// and the mirror test pins it, so the WORD changed in the ARB and the member
/// did not.
///
/// The better fix is still open: layer rule 7 permits `lib/core/ui/` to import
/// `lib/domain/`, and `shed_countdown.dart` already does — so this enum could
/// live in `lib/domain/penning.dart` beside `PenExitReason` and the mirror could
/// go entirely. That needs a `CONVENTIONS §6` ruling and a `10 §3.5` amendment.
enum ShedPenTileStatus { settling, ready, attention, loss, empty }

/// What one row renders. Words arrive resolved; this component never looks one
/// up (`layer.core_ui` forbids it reaching the ARB).
typedef ShedPenTileLabels = ({
  String penLabel,
  String? tag,

  /// The hours readout, or null on an empty pen.
  String? hours,

  /// The status word — `OVER`, `CLEAR 14 JUL`, `DEAD`, `— empty —` — or null
  /// for `settling`, whose word IS its hours.
  String? statusWord,
  String semanticLabel,
});

/// One pen, one ruled line.
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
  /// about to use, and a dead row is indistinguishable from a missed tap.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final bool over = status == ShedPenTileStatus.ready;

    // **THE ROW IS THE OUTERMOST WIDGET, AND WRAPPING IT IN A `Stack` WAS A BUG
    // A SEMANTICS TEST CAUGHT.** The first cut drew the doubled rule as a
    // `Positioned` layer here, which put a `Stack` above `ShedTapTarget` — so
    // `getSemantics(find.byKey('pen_board.tile.1'))` walked past the row's own
    // node and returned the BOARD's container label, `PENS`. One utterance per
    // row is `10 §3.2`'s rule and it stopped being true. The doubling moved into
    // `ShedRuledRow` where it belongs — `§7.4` gives the same doubled rule to the
    // flock row's warning state, so it was never the pen board's to own.
    return ShedRuledRow(
      // 88, `§4.4`'s tall row: 44 pt tabular over an 18 pt floor needs it.
      height: kRuledRowTall,
      semanticLabel: labels.semanticLabel,
      onTap: onTap,
      // CHANNEL 3 — GEOMETRY.
      doubled: over,
      margin: _MarginMark(status: status, text: text, t: t),
      // **THE TWO COLUMNS ARE BOTH IN `child`, AND `ShedRuledRow.trailing` IS
      // DELIBERATELY UNUSED.** `trailing` is laid out at its intrinsic width,
      // which is right for a stamp and wrong for this row: measured at
      // textScaler 2.0 on a 375 pt device, `31h` plus a boxed `OVER` wants
      // ~200 pt of a ~291 pt line, the record column is squeezed to 91, and a
      // five-digit tag (the overflow matrix seeds `40001`) overflows by more
      // than the row is wide. Two `Expanded`s cannot overflow, because neither
      // can take more than its share.
      child: Row(
        children: <Widget>[
          Expanded(
            child: _Occupant(labels: labels, status: status, lambCount: lambCount),
          ),
          Expanded(
            child: _Hours(labels: labels, status: status),
          ),
        ],
      ),
    );
  }
}

/// The 68 pt margin cell: the *"look at this"* mark, and nothing else.
///
/// `indelible.md §8` puts the dagger HERE rather than beside the hours — the
/// margin is the one column that is empty on every ordinary row, so a mark in it
/// is visible down the whole page without reading a single word.
class _MarginMark extends StatelessWidget {
  const _MarginMark({required this.status, required this.text, required this.t});

  final ShedPenTileStatus status;
  final TextTheme text;
  final ShedTokens t;

  @override
  Widget build(BuildContext context) => Center(
    child: switch (status) {
      // CHANNEL 2 — the dagger, at the 24 pt heading role `§8` asks for.
      ShedPenTileStatus.ready => Text(
        '†',
        key: const Key('pen_tile.dagger'),
        style: text.headlineSmall,
      ),
      // THE CIRCLE-SLASH IS `attention`'s. `statusAttention` is reinforcement
      // beside the shape, never the only channel.
      ShedPenTileStatus.attention => Text(
        '⊘',
        key: const Key('pen_tile.badge'),
        style: text.headlineSmall?.copyWith(color: t.statusAttention),
      ),
      // `loss` GETS NO MARK AND NO COLOUR, EVER. A colour-coded death reads
      // wrong at 4am through a wet freezer bag; the word `DEAD` carries it.
      ShedPenTileStatus.settling ||
      ShedPenTileStatus.loss ||
      ShedPenTileStatus.empty => const SizedBox.shrink(),
    },
  );
}

/// Column 1 and 2 of `§8`'s three: the pen number, then what is in it.
///
/// **A `Wrap`, NOT A `Row`, AND THAT IS THE TEXT-SCALE ANSWER.** At 100% these
/// sit on one line and the row reads exactly as the design draws it. At 200% the
/// pen number alone is ~89 pt and a five-digit tag ~180, so something has to
/// give: a `Wrap` lets the occupant fall to a second line and the row grow —
/// `§3.6`, *rows grow, the grid does not move* — instead of clipping a tag or
/// overflowing the page. Every child is ellipsised as well, because a `Wrap`
/// child wider than the whole column would still overflow.
class _Occupant extends StatelessWidget {
  const _Occupant({required this.labels, required this.status, required this.lambCount});

  final ShedPenTileLabels labels;
  final ShedPenTileStatus status;
  final int lambCount;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return Wrap(
      spacing: t.gapMin,
      runSpacing: t.gapMin / 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        // **THE BIGGEST THING IN THE ROW, HARD AGAINST THE SPINE.** `§8`: *"the
        // number you shout across the shed"*. `displaySmall` is the numeral role
        // — tabular, so `4` and `12` do not shift the tag beside them.
        Text(
          labels.penLabel,
          key: const Key('pen_tile.label'),
          style: text.displaySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (labels.tag case final String tag)
          Text(
            tag,
            key: const Key('pen_tile.tag'),
            style: text.headlineLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        // TALLY STROKES, NOT A DIGIT. Two strokes means two lambs, counted at a
        // glance without reading — and it is the same mark the slab prints, so
        // there is one visual language for "how many lambs" in the entry flow
        // and on the board.
        if (lambCount > 0)
          ShedTally(
            key: const Key('pen_tile.tally'),
            count: lambCount,
            // THE ROW'S OWN LABEL ALREADY SAYS THE COUNT, and the whole row is
            // one utterance — so the tally is excluded from the node rather than
            // announced again. Two announcements for one fact is the noise
            // `10 §3.2` names.
            semanticLabel: '',
          ),
        // The word that is about the OCCUPANT lives here; `OVER`, which is about
        // the hours figure, prints beside the hours. `— empty —` is not a stamp
        // — it is the absence of an occupant, printed in `--ink-low` where the
        // occupant would be, because *"a grid that hides its holes is useless"*
        // when you are carrying a ewe and looking for the space.
        if (labels.statusWord case final String word)
          switch (status) {
            ShedPenTileStatus.attention => ShedStatusBadge(
              key: const Key('pen_tile.state'),
              stamp: ShedStamp.withdrawal,
              label: word,
            ),
            ShedPenTileStatus.loss => ShedStatusBadge(
              key: const Key('pen_tile.state'),
              stamp: ShedStamp.dead,
              label: word,
            ),
            ShedPenTileStatus.empty => Text(
              word,
              key: const Key('pen_tile.state'),
              style: text.bodyLarge?.copyWith(color: t.textChrome),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // `settling` HAS NO WORD — its word is its hours, because "settling"
            // is not news: every penned ewe is settling, and a word that says
            // nothing crowds out the number that does. `ready`'s word prints
            // beside the figure it is about.
            ShedPenTileStatus.settling || ShedPenTileStatus.ready => const SizedBox.shrink(),
          },
      ],
    );
  }
}

/// Column 3: the hours, right-aligned, forming a clean numeric column down the
/// right edge of the page — which is the whole reason `§8` refuses a grid.
class _Hours extends StatelessWidget {
  const _Hours({required this.labels, required this.status});

  final ShedPenTileLabels labels;
  final ShedPenTileStatus status;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final bool over = status == ShedPenTileStatus.ready;

    return Wrap(
      spacing: t.gapMin,
      runSpacing: t.gapMin / 2,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        if (labels.hours case final String hours)
          Text(
            hours,
            key: const Key('pen_tile.hours'),
            style: text.headlineLarge?.copyWith(
              // CHANNEL 4 — INK DENSITY. Under threshold the figure sits at
              // `--ink-mid` (7.80:1); over, it lifts to `--ink-full` (16.19:1).
              // It is the weakest of the four on purpose: it is the one a red
              // torch and a monochrome screen both take away.
              color: over ? t.textPrimary : t.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        // CHANNEL 1 — THE WORD, BOXED. `§7.7`: boxed is a state of the animal,
        // and being past the shepherd's own turn-out threshold is one.
        if (over && labels.statusWord != null)
          ShedStatusBadge(
            key: const Key('pen_tile.over'),
            stamp: ShedStamp.over,
            label: labels.statusWord!,
          ),
      ],
    );
  }
}

// **THE FOUR-SHAPE RULE VOCABULARY IS GONE, AND THAT IS `indelible.md` WINNING
// AN ARGUMENT.** A private `_StatusRule` used to paint single / doubled / dashed
// / dotted, one shape per status, from `10 §5.2`, under the key `pen_tile.rule`.
// `§8` gives the board ONE shape channel — *"the rule beneath the row doubles"* —
// and only for over-threshold, for the reason the section itself states: what is
// legible from across the shed is the presence of a second line, not the
// difference between a dash and a dot at 2 px. The remaining channel is
// `ShedRuledRow.doubled`, keyed `shed_ruled_row.doubled`, because `§7.4` gives
// the flock row's warning state the identical mark and *the same fact wears the
// same clothes wherever it appears*.

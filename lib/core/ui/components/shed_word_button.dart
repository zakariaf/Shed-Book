// lib/core/ui/components/shed_word_button.dart
//
// `indelible.md §7.13`'s word button — *"the universal control"* — as ONE
// widget instead of seven private copies.
//
// ---------------------------------------------------------------------------
// WHY THIS IS A NEW COMPONENT AND NOT A CALL TO `ShedSecondaryButton`
// ---------------------------------------------------------------------------
//
// `ShedSecondaryButton`'s `inStream` form is §7.13's *Default* and *Selected*
// rows and had ZERO call sites. It was the obvious thing to adopt, and adopting
// it would have REGRESSED two things every one of the seven copies had:
//
//   1. **`Semantics(selected:)` on the node.** `10 §3.2` rule 2 says the state
//      belongs on the node rather than in the label, so a screen reader
//      announces it once. `ShedSecondaryButton` sets no flag, so a migration
//      would have made six selectable controls announce as plain buttons.
//
//   2. **A NON-COLOUR CHANNEL between selected and unselected.** §7.13's
//      *Selected* row distinguishes by ink alone — *"underline goes 2px
//      `--ink-full`; label `--ink-full` while siblings sit at `--ink-mid`"* —
//      and `10 §5.2` says colour is never one of the three channels on its own.
//      All seven copies independently doubled the underline and lifted the text
//      role. Seven authors converging on the same addition is a specification.
//
// **THAT TENSION IS THE OWNER'S TO RULE ON, NOT MINE**, so nothing here changes
// a rendering: this is a pure extraction of what the copies already did. Either
// §7.13 gains the non-colour channel and `ShedSecondaryButton.inStream` follows,
// or this component is wrong and all seven call sites were wrong together. What
// is not defensible is six near-copies drifting quietly, which is what happened:
// one used `tapPrimary` where five used `tapIndelible`, and only one ellipsised.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/control_voice.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// A word with a rule under it. **Not a chip, not a segmented control** —
/// `indelible.md` is explicit that this system has neither, because both are
/// containers with a radius.
final class ShedWordButton extends StatelessWidget {
  const ShedWordButton({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.semanticLabel,
    this.minSize,
  });

  final String label;

  final bool selected;

  /// **Never null, and never disabled** (`indelible.md §7.2`). A dead control
  /// under a cold thumb is indistinguishable from a missed tap, which is why
  /// this is required rather than nullable — the disabled state is unbuildable.
  final VoidCallback onTap;

  /// Defaults to [label]. Supplied only where the spoken form differs from the
  /// visible one — the colostrum method buttons are the one such caller.
  ///
  /// **NO STATE WORD IN IT** (`10 §3.2` rule 2): the node carries `selected` and
  /// a screen reader announces the state itself, so *"Tube, selected"* is the
  /// doubled announcement users report as noise.
  final String? semanticLabel;

  /// Defaults to the 64 pt Indelible floor. `tapPrimary` where a caller sits in
  /// a denser row.
  final double? minSize;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return Semantics(
      selected: selected,
      // **THE BUTTON HUGS ITS WORD, AND WITHOUT THIS IT NEVER DID.**
      //
      // `ShedTapTarget` wraps its child in `Center`, and `Center` expands to the
      // maximum width it is offered. In a `Column`, a `Wrap` or any bounded
      // parent that is the full page — so every word button in this app rendered
      // as a full-width row with the label centred in it and a rule running the
      // whole way across underneath.
      //
      // That is the shape the owner described on 2026-08-06, looking at the
      // running app: *"the buttons with a small word and just one line behind
      // them."* It read as unfinished because it was: `indelible.md §7.13` draws
      // a word with a rule **under the word**, and `§8` puts five of them on one
      // line. Five full-width rows is a different control.
      //
      // `IntrinsicWidth` is the narrow fix — it tightens to the child's own
      // intrinsic width, so the 64 pt floor inside `ShedTapTarget` still wins on
      // a short label and the rule stops where the word does. It costs one extra
      // layout pass on a handful of words per screen, which is the cheapest of
      // the available fixes and the only one that leaves the target geometry
      // exactly where the gates measure it.
      child: IntrinsicWidth(
        child: ShedTapTarget(
          semanticLabel: semanticLabel ?? label,
          minSize: minSize ?? t.tapIndelible,
          onTap: onTap,
          child: ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    // THE COLOUR CHANNEL — §7.13's own.
                    color: selected ? t.textPrimary : t.outline,
                    // AND THE SHAPE CHANNEL, which is the addition. A reader who
                    // cannot separate the inks still sees a heavier rule.
                    width: selected ? t.outlineWidth * 2 : t.outlineWidth,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: t.gapMin),
                child: Center(
                  child: Text(
                    // **THE CONTROL VOICE** (§3.1, ruling P7): capitals say
                    // *this is a thing you can press*, sentence case says *this
                    // happened*. Two typefaces used to carry that; one family
                    // ships, so case and weight carry it instead.
                    //
                    // Capitals cost 16–32% of label width against this face —
                    // measured with the real TTF, because `flutter_test` renders
                    // every glyph as a square and shows only the tracking.
                    // Nothing overflows: every call site is a `Wrap` or a
                    // stretched `Column`, so the ellipsis below absorbs it.
                    controlCase(label),
                    // THE THIRD CHANNEL: weight, not just ink. It goes on
                    // carrying SELECTED-vs-unselected while the capitals carry
                    // control-vs-record — two axes, and neither is hue.
                    style: controlStyle(context, selected ? text.titleMedium : text.bodyMedium),
                    maxLines: 1,
                    // ELLIPSISED, NEVER SHRUNK. A shrink-to-fit widget is banned
                    // (`10 §4.4`): shrinking a legend is how an 18 pt floor
                    // becomes 9 pt on the one device whose owner turned the text
                    // up. Five of the six copies omitted this and would clip at
                    // 200%.
                    overflow: TextOverflow.ellipsis,
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

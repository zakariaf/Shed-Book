// lib/core/ui/components/shed_keypad.dart
//
// THE ONE NUMERIC ENTRY ROUTE IN THE APP (decision #57). Tags, litter counts,
// ease scores, days and weights all come through here. There is no TextField on
// any numeric path and no system keyboard anywhere (06 §8.1) — the system
// keyboard fails every clause of the 3am test: its keys are under the floor, its
// layout moves, and it is light-themed on a device whose owner has a head torch.
//
// lib/core/ui/components/, NOT features/quick_entry/widgets/ (R70). Lambing
// Entry, Treatments and Settings all need the same pad, and layer rule 6 forbids
// a sibling-feature import — so the feature-folder placement is not merely
// inconsistent, it is unbuildable.
//
// It watches nothing and is const-constructible, so a keystroke cannot rebuild
// it (02 §10.1). The moment someone makes it a ConsumerWidget to "just watch one
// thing here", every child below loses its const-ness.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// The third key on the bottom row.
///
/// **A CONSTRUCTOR PARAMETER, NOT A RUNTIME STATE, AND THAT IS A RULING.**
/// `06 §8.2` wanted the bottom-right key to always be the decimal, rendering
/// *inert* — `onTap: null` — on an integer-only field. `indelible.md §7.2`'s
/// key-state table says of Disabled: *"Never. No key is ever disabled — a dead
/// key under a cold thumb is indistinguishable from a missed tap."*
///
/// An inert key **is** a disabled key: `onTap: null` makes [ShedTapTarget] emit
/// `enabled: false` and drop `SemanticsAction.tap`. The two cannot both hold,
/// and `CLAUDE.md`'s authority order puts `indelible.md` above the thirteen
/// engineering documents. `06 §8.2` is amended in the same commit.
///
/// `06`'s real requirement survives intact — *"the grid never re-legends"* —
/// because the legend is fixed for as long as the pad is on screen. A tag pad is
/// built with [newTag]; a weight pad (N20) is built with [decimal].
enum ShedKeypadThirdKey { newTag, decimal }

class ShedKeypad extends StatelessWidget {
  const ShedKeypad({
    required this.onDigit,
    required this.onBackspace,
    required this.thirdKey,
    required this.onThirdKey,
    required this.padLabel,
    required this.backspaceLabel,
    required this.backspaceHint,
    required this.thirdKeyLabel,
    super.key,
    this.leftHanded = false,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final ShedKeypadThirdKey thirdKey;
  final VoidCallback onThirdKey;

  /// **THE FOUR LABELS ARE PARAMETERS, NOT AN `AppLocalizations` LOOKUP**, and
  /// the gate is what says so: `layer.core_ui` forbids `lib/core/ui/` importing
  /// `lib/l10n/`. It is the same shape [ShedTapTarget] already uses for
  /// `semanticLabel` — a component in the shared tier renders what it is handed
  /// and never resolves copy, so the screen that knows the locale is the screen
  /// that supplies the words.
  final String padLabel;
  final String backspaceLabel;
  final String backspaceHint;

  /// The legend on the third key: the create-on-the-fly word, or the decimal
  /// separator, which is a locale decision the screen makes rather than a
  /// hard-coded full stop.
  final String thirdKeyLabel;

  /// Mirrors the **bottom row only** (R40). The digits stay where a phone
  /// keypad puts them: a shepherd who has used a phone knows where 5 is, and
  /// mirroring the grid would cost that for no reach benefit.
  final bool leftHanded;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextScaler scaler = MediaQuery.textScalerOf(context);

    // The digit glyph is the `displaySmall` role — 40 pt in `night`, 44 pt in
    // either night-shift palette. THE ROLE IS THE BINDING STATEMENT, NOT THE
    // NUMBER (06 §8.2), which is why it is read off the tokens.
    //
    // Three keypad geometries are in the doc set and only one binds: 07 §5.1
    // sketches "72 pt keys, 44 pt glyphs, 16 pt gaps" and indelible §7.2 draws
    // 117 × 84 at a 393 px viewport. Indelible's is the CSS artefact's rendering
    // at one viewport and is LARGER than the floor, so both hold. No literal
    // appears here.
    final double glyph = t.numeralSize;

    final TextStyle digitStyle =
        Theme.of(context).textTheme.displaySmall ?? TextStyle(fontSize: glyph);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // MEASURED, AND A DEVIATION FROM 06 §8.2'S PRINTED FORMULA, RECORDED
        // RATHER THAN APPLIED SILENTLY. The formula is
        // `max(tapPrimary, scaler.scale(glyph) * 1.6)` and it has NO WIDTH TERM,
        // but three keys across is a hard constraint: at text scale 2.0 on a
        // 390 pt viewport it asks for 3 × 128 + 2 × 16 = 416 pt and the row
        // overflows by 26. §8.2's own sentence — "after which the pad grows and
        // the match list above it gives up rows" — describes growth in HEIGHT,
        // which is the axis that has somewhere to give.
        //
        // So the width available is a ceiling, and `tapMin` is the floor that
        // outranks it. On a viewport too narrow for three 60 pt keys the floor
        // wins and the row overflows visibly — which is correct: N33's geometric
        // gate is what must fail there, not the target size.
        final double wanted = math.max(t.tapPrimary, scaler.scale(glyph) * 1.6);
        final double ceiling = (constraints.maxWidth - 2 * t.gapMin) / 3;
        final double side = math.max(t.tapMin, math.min(wanted, ceiling));

        return _pad(context, t, side, digitStyle);
      },
    );
  }

  Widget _pad(BuildContext context, ShedTokens t, double side, TextStyle digitStyle) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: padLabel,
      child: Column(
        key: const Key('quick_entry.keypad'),
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final List<String> row in const <List<String>>[
            <String>['1', '2', '3'],
            <String>['4', '5', '6'],
            <String>['7', '8', '9'],
          ])
            _Row(
              gap: t.gapMin,
              children: <Widget>[for (final String d in row) _digitKey(d, side, digitStyle)],
            ),
          _Row(
            gap: t.gapMin,
            // Left-handed mirrors THIS ROW ONLY.
            children: leftHanded
                ? <Widget>[
                    _thirdKey(context, side),
                    _digitKey('0', side, digitStyle),
                    _backspaceKey(side, digitStyle),
                  ]
                : <Widget>[
                    _backspaceKey(side, digitStyle),
                    _digitKey('0', side, digitStyle),
                    _thirdKey(context, side),
                  ],
          ),
        ],
      ),
    );
  }

  /// The label **is** the digit (`10 §3.6`), because Voice Control matches the
  /// visible glyph — never "Four key", never "Digit four". The glyph sits inside
  /// `ExcludeSemantics` so the node is not announced twice.
  Widget _digitKey(String d, double side, TextStyle style) => ShedTapTarget(
    key: Key('quick_entry.keypad.digit_$d'),
    semanticLabel: d,
    minSize: side,
    onTap: () => onDigit(d),
    child: ExcludeSemantics(child: Text(d, style: style)),
  );

  /// **No key repeat.** Hold-to-repeat is a banned gesture, and a cold thumb
  /// resting here must delete one digit rather than empty the buffer.
  Widget _backspaceKey(double side, TextStyle style) => ShedTapTarget(
    key: const Key('quick_entry.keypad.backspace'),
    semanticLabel: backspaceLabel,
    onTapHint: backspaceHint,
    minSize: side,
    onTap: onBackspace,
    child: ExcludeSemantics(child: Text('⌫', style: style)),
  );

  Widget _thirdKey(BuildContext context, double side) {
    final bool isNewTag = thirdKey == ShedKeypadThirdKey.newTag;
    return ShedTapTarget(
      key: Key(isNewTag ? 'quick_entry.keypad.new_tag' : 'quick_entry.keypad.decimal'),
      semanticLabel: thirdKeyLabel,
      minSize: side,
      // NEVER null, in either configuration. See ShedKeypadThirdKey.
      onTap: onThirdKey,
      child: ExcludeSemantics(
        // CONSTRAINED TO THE KEY, AND WRAPPING RATHER THAN SHRINKING. The word
        // legend is the only key whose label is wider than its glyph, so at high
        // text scale it is the one that overflows the row — measured at 2.0,
        // where "NEW TAG" wanted ~150 pt in a 119 pt key.
        //
        // The shrink-to-fit widget is banned (06 §8.2, 10 §4.4, gate row
        // type.fitted_box — which scans this file, so it is described rather
        // than named): shrinking a legend to fit is how an 18 pt floor becomes a
        // 9 pt legend on the one device whose owner turned the text up. Wrapping
        // keeps every glyph at its authored size.
        child: SizedBox(
          width: side,
          child: Text(
            thirdKeyLabel,
            textAlign: TextAlign.center,
            style: isNewTag
                ? Theme.of(context).textTheme.labelMedium
                : Theme.of(context).textTheme.displaySmall,
          ),
        ),
      ),
    );
  }
}

/// **Explicit sizing, never `Expanded`.** `Expanded` inside the row overrides
/// `minWidth` and silently shrinks a key below the floor on a 320 pt device once
/// page padding is added (`06 §8.2`) — a failure that only shows on the smallest
/// phone, which is the one most likely to be in a coat pocket.
class _Row extends StatelessWidget {
  const _Row({required this.children, required this.gap});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: gap),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) SizedBox(width: gap),
          children[i],
        ],
      ],
    ),
  );
}

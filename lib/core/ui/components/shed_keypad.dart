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
import 'package:shed_book/core/ui/components/shed_backspace_mark.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/motion.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// §7.2's authored key height. **84, and the width is not a constant** — it is
/// the sheet's width divided by three, because the keys share edges.
const double kKeyHeight = 84;

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
        // **THE KEYS SHARE EDGES, SO THE GRID IS THE WIDTH DIVIDED BY THREE.**
        // §7.2, amended at R86: `123 × 3 = 369` plus 12 px of sheet padding each
        // side = 393, *"gap 0 is the only arithmetic that works, it is this
        // design's own idiom, and it makes each key larger: 123 against 117."*
        //
        // Built with `gapMin` between the keys instead, this pad wanted
        // `3 × 117 + 2 × 16 = 383` and then centred what was left — which is
        // where the *"huge with many empty spaces"* came from. The gaps were the
        // spaces.
        //
        // `tapMin` still outranks the division. On a viewport too narrow for
        // three 60 pt keys the floor wins and the row overflows visibly, which is
        // correct: the geometric gate is what must fail there, not the target.
        final double width = math.max(t.tapMin, constraints.maxWidth / 3);

        // **HEIGHT ONLY** (§3.6's table: the key goes 84 → 108 at 200%, the grid
        // does not move). A key that grew in width would break the 3-column grid
        // that the digit positions are muscle memory for.
        final double height = math.max(kKeyHeight, scaler.scale(glyph) * 1.6);

        return _pad(context, t, width, height, digitStyle);
      },
    );
  }

  Widget _pad(
    BuildContext context,
    ShedTokens t,
    double width,
    double height,
    TextStyle digitStyle,
  ) {
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
              children: <Widget>[
                for (final String d in row) _digitKey(d, width, height, digitStyle),
              ],
            ),
          _Row(
            // Left-handed mirrors THIS ROW ONLY.
            children: leftHanded
                ? <Widget>[
                    _thirdKey(context, width, height),
                    _digitKey('0', width, height, digitStyle),
                    _backspaceKey(width, height, digitStyle, t.outlineWidth),
                  ]
                : <Widget>[
                    _backspaceKey(width, height, digitStyle, t.outlineWidth),
                    _digitKey('0', width, height, digitStyle),
                    _thirdKey(context, width, height),
                  ],
          ),
        ],
      ),
    );
  }

  /// The label **is** the digit (`10 §3.6`), because Voice Control matches the
  /// visible glyph — never "Four key", never "Digit four". The glyph sits inside
  /// `ExcludeSemantics` so the node is not announced twice.
  Widget _digitKey(String d, double width, double height, TextStyle style) => _Key(
    keyId: 'quick_entry.keypad.digit_$d',
    semanticLabel: d,
    width: width,
    height: height,
    onTap: () => onDigit(d),
    child: Text(d, style: style),
  );

  /// **No key repeat.** Hold-to-repeat is a banned gesture, and a cold thumb
  /// resting here must delete one digit rather than empty the buffer.
  Widget _backspaceKey(double width, double height, TextStyle style, double strokeWidth) => _Key(
    keyId: 'quick_entry.keypad.backspace',
    semanticLabel: backspaceLabel,
    onTapHint: backspaceHint,
    width: width,
    height: height,
    onTap: onBackspace,
    // **DRAWN, NOT TYPED.** The glyph rendered as a tofu box on every device —
    // the bundled family has nothing at U+232B and there is no second family to
    // fall back to. See `shed_backspace_mark.dart`.
    child: ShedBackspaceMark(colour: style.color!, strokeWidth: strokeWidth),
  );

  Widget _thirdKey(BuildContext context, double width, double height) {
    final bool isNewTag = thirdKey == ShedKeypadThirdKey.newTag;
    return _Key(
      keyId: isNewTag ? 'quick_entry.keypad.new_tag' : 'quick_entry.keypad.decimal',
      semanticLabel: thirdKeyLabel,
      width: width,
      height: height,
      // NEVER null, in either configuration. See ShedKeypadThirdKey.
      onTap: onThirdKey,
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
        width: width,
        child: Text(
          thirdKeyLabel,
          textAlign: TextAlign.center,
          style: isNewTag
              ? Theme.of(context).textTheme.labelMedium
              : Theme.of(context).textTheme.displaySmall,
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
  const _Row({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: children,
  );
}

/// **A KEY IS A FILLED SLAB, AND IT WAS DRAWN AS BARE TEXT ON THE PAGE.**
///
/// `indelible.md §7.2`: *"Fill `--slab`, 2px `--rule` border, 2px radius."* The
/// pad shipped with none of the three, so twelve digits floated on the page with
/// nothing to say where one key ended and the next began — and with the row gaps
/// that this file has now closed, the whole pad read as *"huge with many empty
/// spaces"*. A target you cannot see the edge of is a target you aim at by
/// memory, which is the one thing this design refuses to ask for at 03:20.
///
/// **THE PRESS STATE IS 40 ms OF FILL AND NOTHING ELSE** (§5.1). No scale, no
/// lift, no ripple: *"a target that shrinks under a cold thumb is a target you
/// miss."* It survives reduce-motion — `motion.dart` zeroes ink, sheet and
/// strike, and press stays, because for somebody who cannot feel the haptic it
/// is the only feedback left.
///
/// Pressed also takes the border to `--ink-mid`, which is `§2.5`'s binding
/// placement rule rather than decoration: `--rule` on `--slab-pressed` measures
/// **2.54:1** and fails the 3:1 non-text floor. The border cannot stay put.
class _Key extends StatefulWidget {
  const _Key({
    required this.keyId,
    required this.semanticLabel,
    required this.width,
    required this.height,
    required this.onTap,
    required this.child,
    this.onTapHint,
  });

  final String keyId;
  final String semanticLabel;
  final String? onTapHint;
  final double width;
  final double height;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    return ShedTapTarget(
      key: Key(widget.keyId),
      semanticLabel: widget.semanticLabel,
      onTapHint: widget.onTapHint,
      // The floor, not the size. The child below is the authored 123 × 84 and is
      // larger on every supported device, so this constraint only ever bites on
      // a viewport narrower than three 60 pt keys.
      minSize: t.tapMin,
      onTap: widget.onTap,
      child: Listener(
        onPointerDown: (_) => setState(() => _down = true),
        onPointerUp: (_) => setState(() => _down = false),
        onPointerCancel: (_) => setState(() => _down = false),
        child: AnimatedContainer(
          duration: kPressFlash,
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _down ? t.surfacePressed : t.surfaceFill,
            border: Border.all(color: _down ? t.textSecondary : t.outline, width: t.outlineWidth),
            borderRadius: BorderRadius.circular(t.radiusControl),
          ),
          alignment: Alignment.center,
          child: ExcludeSemantics(child: widget.child),
        ),
      ),
    );
  }
}

// lib/features/lambing/widgets/colostrum_detail.dart
//
// BOTH FIELDS ARE SKIPPABLE, BOTH ARE EMPTY UNTIL THE SHEPHERD TYPES, AND
// NEITHER HAS A PLACEHOLDER. `05 §7.3` gives the line that settles every case
// like this one: *the app may arithmetic-transform a number the user supplied;
// it may never originate a number that is a clinical decision.* No default
// volume, no suggested volume, no "typical" figure in a hint, no last-value
// autofill — the field behaves exactly like the withdrawal-days field, and for
// exactly the same reason.
//
// NO PLACEHOLDER TEXT INSIDE THE VOLUME FIELD (`indelible.md §7.12`): *"In the
// dark, a grey placeholder is indistinguishable from an entered value."* The
// label goes ABOVE the line in the control voice; the value sits on the rule.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_keypad.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/care_kind.dart';

/// What the sheet hands back when the shepherd closes it.
///
/// Both halves nullable, and **`null` is a real answer** rather than a missing
/// one: a shepherd who fed colostrum without measuring it has recorded the
/// feed, which is the fact that matters at 03:20.
typedef ColostrumDetail = ({int? volumeMl, ColostrumMethod? method});

/// The words the sheet renders, resolved by the screen.
typedef ColostrumLabels = ({
  String volumeLabel,
  String methodLabel,
  String unitSuffix,
  String recordLabel,
  String recordSemanticLabel,
  String padLabel,
  String backspaceLabel,
  String backspaceHint,
  List<String> methodWords,
  String Function(String) methodSemanticLabel,
});

class ColostrumDetailSheet extends StatefulWidget {
  const ColostrumDetailSheet({required this.labels, required this.onRecord, super.key});

  final ColostrumLabels labels;

  /// Called once, with whatever the shepherd supplied. **There is no validation
  /// here and no correction**: a volume outside `1..2000` reaches the repository
  /// and comes back as a `WriteFailed` with the shed's own message. Clamping it
  /// in the widget would be §12.4 with a helpful face on, and it would also make
  /// the schema's guard untestable from the screen.
  final ValueChanged<ColostrumDetail> onRecord;

  @override
  State<ColostrumDetailSheet> createState() => _ColostrumDetailSheetState();
}

class _ColostrumDetailSheetState extends State<ColostrumDetailSheet> {
  /// **THE ONLY STATE IN THE SHEET, AND IT IS NOT A DRAFT.** Nothing is written
  /// until the record button; the row this sheet contributes to already exists
  /// on the page above, because the care line committed it. If the phone dies
  /// here, the colostrum event is already recorded and only the volume is lost —
  /// which is the trade the whole write path is built on.
  String _digits = '';
  ColostrumMethod? _method;

  int? get _volume => _digits.isEmpty ? null : int.tryParse(_digits);

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final ColostrumLabels l = widget.labels;

    // SCROLLABLE, AND MEASURED. `indelible.md §7.14` gives the keypad sheet 60%
    // of the viewport — 511 pt on a 852 pt phone — and this sheet's content is
    // taller than that: the pad alone is four rows of 72 plus gaps, and the
    // volume field, two labels, the method row and the record button follow it.
    // The measured overflow was 496 px.
    //
    // The alternative was to shrink the pad, and that is the one thing that must
    // not give: the keys are the 3am contract. Vertical scrolling is the one
    // tracked gesture (06 §7), so the sheet scrolls and every key stays at its
    // authored size.
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // THE LABEL IS ABOVE THE LINE, NOT INSIDE IT.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: Text(l.volumeLabel, style: text.labelMedium),
          ),
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: Row(
              children: <Widget>[
                // THE VALUE SITS ON THE RULE, AND AN EMPTY FIELD IS EMPTY. No
                // grey "e.g. 200", no ghosted last value: in the dark a
                // placeholder is indistinguishable from an entered value.
                Expanded(
                  child: Container(
                    key: const Key('lambing_entry.colostrum.volume'),
                    height: t.tapIndelible,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: t.outline, width: t.outlineWidth),
                      ),
                    ),
                    child: Text(_digits, style: text.displaySmall),
                  ),
                ),
                SizedBox(width: t.gapMin),
                Text(l.unitSuffix, style: text.bodyMedium),
              ],
            ),
          ),
          // DECISION #57 — THE KEYPAD IS THE ONLY NUMBER-ENTRY ROUTE IN THE APP.
          // A TextField with a numeric keyboard is the thing it exists to replace:
          // the system keyboard's keys are under the floor, its layout moves, and
          // it is light-themed on a device whose owner has a head torch.
          //
          // The third key is `decimal` and NOT `newTag`, because millilitres are
          // whole numbers here — the key is a constructor parameter rather than a
          // runtime state precisely so it cannot go inert (see ShedKeypadThirdKey),
          // and a live decimal key that produces a rejected volume is better than
          // a dead key under a cold thumb.
          ShedKeypad(
            onDigit: (String d) => setState(() => _digits += d),
            onBackspace: () => setState(() {
              if (_digits.isNotEmpty) {
                _digits = _digits.substring(0, _digits.length - 1);
              }
            }),
            thirdKey: ShedKeypadThirdKey.decimal,
            onThirdKey: () => setState(() => _digits += '.'),
            padLabel: l.padLabel,
            backspaceLabel: l.backspaceLabel,
            backspaceHint: l.backspaceHint,
            thirdKeyLabel: '.',
          ),
          SizedBox(height: t.gapMin),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: Text(l.methodLabel, style: text.labelMedium),
          ),
          // METHOD IS A WRAP OF THREE, NOT A ShedChoiceRow. That component asserts
          // FIVE choices in its constructor and its doc comment says in as many
          // words that it is ease 1–5 or nothing — using it here would be P8 being
          // softened by a third party.
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: Wrap(
              spacing: t.gapMin,
              runSpacing: t.gapMin,
              children: <Widget>[
                for (int i = 0; i < ColostrumMethod.values.length; i++)
                  _MethodButton(
                    word: l.methodWords[i],
                    semanticLabel: l.methodSemanticLabel(l.methodWords[i]),
                    selected: _method == ColostrumMethod.values[i],
                    onTap: () => setState(() {
                      // TAPPING THE SELECTED ONE CLEARS IT. Method is skippable,
                      // and without this there is no way back to "not recorded"
                      // after a mis-tap — which would be the app holding a claim
                      // the shepherd disowned.
                      _method = _method == ColostrumMethod.values[i]
                          ? null
                          : ColostrumMethod.values[i];
                    }),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: ShedTapTarget(
              key: const Key('lambing_entry.colostrum.record'),
              semanticLabel: l.recordSemanticLabel,
              minSize: t.tapHero,
              onTap: () => widget.onRecord((volumeMl: _volume, method: _method)),
              child: ExcludeSemantics(
                child: Center(child: Text(l.recordLabel, style: text.titleMedium)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One method word. Selected state is the border and the weight — **never
/// colour alone** (`10 §5.2`), and never disabled.
class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.word,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
  });

  final String word;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    // `selected:` ON THE NODE, AND NO STATE WORD IN THE LABEL (`10 §3.2` rule
    // 2). A screen reader announces the state itself; "Tube, selected" in the
    // label is the doubled announcement users report as noise.
    //
    // `ShedTapTarget` has no `selected` parameter, so the flag is set by a
    // Semantics wrapper rather than by adding one — a shared component gains a
    // parameter when two callers need it, not when one does.
    return Semantics(
      selected: selected,
      child: ShedTapTarget(
        key: Key('lambing_entry.colostrum.method.$word'),
        semanticLabel: semanticLabel,
        minSize: t.tapPrimary,
        onTap: onTap,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? t.textPrimary : t.outline,
                  width: selected ? t.outlineWidth * 2 : t.outlineWidth,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: t.gapMin),
              child: Center(
                child: Text(word, style: selected ? text.titleMedium : text.bodyMedium),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

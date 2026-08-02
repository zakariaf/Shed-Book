// lib/features/lambing/widgets/lamb_weight_cell.dart
//
// THE CELL AND THE SHEET IT OPENS. Entry goes through `ShedKeypad` (decision
// #57): it is the only numeric route in the app, and a text field with a numeric
// keyboard is the thing it exists to replace.
//
// THE UNIT IS A DISPLAY CHOICE AND THE COLUMN IS GRAMS. `WeightUnit` comes from
// `unitsProvider` (R68) and the conversion happens here, at the widget boundary
// — never in the repository, which would let a switch of display unit change a
// record.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_keypad.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/units/grams.dart';
import 'package:shed_book/domain/units/parse_number.dart';
import 'package:shed_book/domain/units/weight_unit.dart';

typedef WeightSheetLabels = ({
  String heading,
  String unitSuffix,
  String confirmLabel,
  String confirmSemanticLabel,
  String padLabel,
  String backspaceLabel,
  String backspaceHint,
});

/// The keypad sheet. **No placeholder and no pre-fill** (`indelible.md §7.12`):
/// in the dark a grey figure is indistinguishable from an entered one, and
/// pre-filling the existing weight would make *keeping it* and *retyping it*
/// look identical.
class LambWeightSheet extends StatefulWidget {
  const LambWeightSheet({
    required this.labels,
    required this.units,
    required this.onRecord,
    super.key,
  });

  final WeightSheetLabels labels;
  final WeightUnit units;

  /// Called with canonical grams, converted here. `null` is never passed —
  /// clearing a weight is the cell's job, not the sheet's.
  final ValueChanged<Grams> onRecord;

  @override
  State<LambWeightSheet> createState() => _LambWeightSheetState();
}

class _LambWeightSheetState extends State<LambWeightSheet> {
  String _digits = '';

  /// **`parseUserNumber` RATHER THAN `double.parse`.** It returns null instead
  /// of guessing at an ambiguous string, which is the same refusal the rest of
  /// this app makes: the app may transform a number the shepherd supplied, never
  /// originate one (`05 §7.3`).
  Grams? get _weight {
    final double? typed = parseUserNumber(_digits);
    if (typed == null || typed <= 0) {
      return null;
    }
    return switch (widget.units) {
      // CONVERTED AT THE BOUNDARY, ONCE. `lb` entry is decimal pounds; the
      // decomposition into pounds and ounces is a DISPLAY concern and lives in
      // `Grams.poundsOunces`, which rounds once and carries at sixteen.
      WeightUnit.kg => Grams.fromKilograms(typed),
      WeightUnit.lb => Grams.fromPounds(typed),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final WeightSheetLabels l = widget.labels;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: Text(l.heading, style: text.labelMedium),
          ),
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    key: const Key('lamb_card.weight.value'),
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
          ShedKeypad(
            onDigit: (String d) => setState(() => _digits += d),
            onBackspace: () => setState(() {
              if (_digits.isNotEmpty) {
                _digits = _digits.substring(0, _digits.length - 1);
              }
            }),
            // A WEIGHT HAS A DECIMAL, so the third key is the decimal — and it
            // is a constructor parameter rather than a runtime state precisely
            // so it can never go inert (see `ShedKeypadThirdKey`).
            thirdKey: ShedKeypadThirdKey.decimal,
            onThirdKey: () => setState(() {
              // ONE DECIMAL POINT. A second one would make `parseUserNumber`
              // return null and the button silently do nothing, which reads as a
              // broken app rather than as a refused key.
              if (!_digits.contains('.')) {
                _digits += '.';
              }
            }),
            padLabel: l.padLabel,
            backspaceLabel: l.backspaceLabel,
            backspaceHint: l.backspaceHint,
            thirdKeyLabel: '.',
          ),
          SizedBox(height: t.gapMin),
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: ShedTapTarget(
              key: const Key('lamb_card.weight.confirm'),
              semanticLabel: l.confirmSemanticLabel,
              minSize: t.tapHero,
              // NEVER NULL. An unparseable entry means pressing it does nothing;
              // a greyed button at 03:20 reads as a broken app.
              onTap: () {
                if (_weight case final Grams g) {
                  widget.onRecord(g);
                }
              },
              child: ExcludeSemantics(
                child: Center(child: Text(l.confirmLabel, style: text.titleMedium)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

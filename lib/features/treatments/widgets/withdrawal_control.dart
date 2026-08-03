// lib/features/treatments/widgets/withdrawal_control.dart
//
// SAFETY RULE §12.1, AS A WIDGET: **never default a medicine withdrawal
// period.** The repository makes the wrong row unwritable; this makes the wrong
// answer un-preselectable.
//
// THREE CHOICES AND NONE OF THEM IS SELECTED WHEN THE CONTROL OPENS. A control
// that pre-selects *not recorded* is as wrong as one that pre-fills `28`,
// because both make a decision the shepherd did not make — and the one that
// pre-fills a number is the app originating a clinical figure, which `05 §7.3`
// forbids in one line.
//
// NO PLACEHOLDER INSIDE THE FIELD (`indelible.md §7.12`): in the dark a grey
// figure is indistinguishable from an entered one.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_keypad.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';

typedef WithdrawalLabels = ({
  String heading,
  String enterDays,
  String notApplicable,
  String notRecorded,
  String unit,
  String padLabel,
  String backspaceLabel,
  String backspaceHint,
});

/// One target's withdrawal, asked on its own.
///
/// **MEAT AND MILK ARE ASKED SEPARATELY**, because one entered period implies
/// nothing about the other — and a control that asked once and wrote both would
/// be inventing the half the shepherd did not read.
class WithdrawalControl extends StatefulWidget {
  const WithdrawalControl({
    required this.target,
    required this.labels,
    required this.onChanged,
    super.key,
  });

  final WithdrawalTarget target;
  final WithdrawalLabels labels;

  /// Called with what the shepherd chose. **`WithdrawalNotRecorded` is only ever
  /// sent because they chose it**, never because they have not answered yet —
  /// the un-answered state emits nothing at all.
  final ValueChanged<WithdrawalPeriod> onChanged;

  @override
  State<WithdrawalControl> createState() => _WithdrawalControlState();
}

class _WithdrawalControlState extends State<WithdrawalControl> {
  /// **`null` UNTIL THEY CHOOSE**, and that is the whole point. There is no
  /// initial value, so there is no answer to accidentally commit.
  _Choice? _choice;

  String _digits = '';

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final WithdrawalLabels l = widget.labels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
          child: Text(l.heading, style: text.labelMedium),
        ),
        Wrap(
          spacing: t.gapMin,
          runSpacing: t.gapMin,
          children: <Widget>[
            ShedWordButton(
              key: const Key('treatment.withdrawal.enter_days'),
              label: l.enterDays,
              selected: _choice == _Choice.days,
              onTap: () => setState(() => _choice = _Choice.days),
            ),
            ShedWordButton(
              key: const Key('treatment.withdrawal.not_applicable'),
              label: l.notApplicable,
              selected: _choice == _Choice.notApplicable,
              onTap: () {
                setState(() => _choice = _Choice.notApplicable);
                widget.onChanged(WithdrawalNotApplicable(widget.target));
              },
            ),
            ShedWordButton(
              key: const Key('treatment.withdrawal.not_recorded'),
              label: l.notRecorded,
              selected: _choice == _Choice.notRecorded,
              onTap: () {
                setState(() => _choice = _Choice.notRecorded);
                widget.onChanged(const WithdrawalNotRecorded());
              },
            ),
          ],
        ),
        // THE KEYPAD APPEARS ONLY AFTER THEY CHOOSE `days`. Showing it up front
        // would be an invitation to type a number before deciding whether there
        // is one, and an empty field beside two other options reads as the
        // default answer.
        if (_choice == _Choice.days) ...<Widget>[
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    key: const Key('treatment.withdrawal.days_value'),
                    height: t.tapIndelible,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: t.outline, width: t.outlineWidth),
                      ),
                    ),
                    // EMPTY IS EMPTY. No placeholder, no prefill, no last value.
                    child: Text(_digits, style: text.displaySmall),
                  ),
                ),
                SizedBox(width: t.gapMin),
                Text(l.unit, style: text.bodyMedium),
              ],
            ),
          ),
          ShedKeypad(
            onDigit: (String d) => setState(() {
              _digits += d;
              _emitDays();
            }),
            onBackspace: () => setState(() {
              if (_digits.isNotEmpty) {
                _digits = _digits.substring(0, _digits.length - 1);
              }
              _emitDays();
            }),
            // A WITHDRAWAL IS WHOLE DAYS, so the decimal appends nothing. It
            // stays LIVE because a dead key under a cold thumb is
            // indistinguishable from a missed tap.
            thirdKey: ShedKeypadThirdKey.decimal,
            onThirdKey: () {},
            padLabel: l.padLabel,
            backspaceLabel: l.backspaceLabel,
            backspaceHint: l.backspaceHint,
            thirdKeyLabel: '.',
          ),
        ],
      ],
    );
  }

  /// **NOTHING IS EMITTED FOR AN EMPTY FIELD.** A shepherd who chose *days* and
  /// has not typed yet has not answered, and sending `0` would be the app
  /// answering for them — which is exactly what a zero-day period means and
  /// exactly what it must not be allowed to mean by accident.
  void _emitDays() {
    final int? days = int.tryParse(_digits);
    if (days == null) {
      return;
    }
    widget.onChanged(
      // `asEnteredByUser` IS THE ONLY WAY TO BUILD ONE, and its name is the
      // §12.1 claim in the type system: every stored period came off a bottle
      // the shepherd was holding.
      WithdrawalDays.asEnteredByUser(days: days, target: widget.target),
    );
  }
}

enum _Choice { days, notApplicable, notRecorded }

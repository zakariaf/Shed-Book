// lib/features/lambing/widgets/time_editor_sheet.dart
//
// NOT `showTimePicker` AND NOT `showDatePicker`, AND THIS IS THE SINGLE MOST
// LIKELY SHORTCUT ON THE WHOLE SCREEN. Three separate rules forbid them:
//
//   1. Both are `showDialog` call sites, and `ui.show_dialog` is a gate row
//      outside two allowlisted destructive files. This screen is not one.
//   2. Material's time picker DEFAULTS TO THE DIAL, which is a drag gesture —
//      banned outright (decision #101).
//   3. Its input mode is a text field with a numeric keyboard, which decision
//      #57 replaced with the app's own keypad.
//
// So the editor is `ShedKeypad` inside `ShedBottomSheet`, which already carries
// `enableDrag: false` and `isDismissible: false`.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_keypad.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';

typedef TimeEditorLabels = ({
  String heading,
  String hint,
  String confirmLabel,
  String confirmSemanticLabel,
  String padLabel,
  String backspaceLabel,
  String backspaceHint,
});

/// Four digits, `HHmm`, on the app's own pad.
///
/// **NO PLACEHOLDER AND NO PRE-FILL** — the field starts empty exactly like the
/// colostrum volume, for the same reason (`indelible.md §7.12`): in the dark a
/// grey value is indistinguishable from an entered one, and pre-filling the
/// current time would make *keeping it* and *retyping it* look identical.
class TimeEditorSheet extends StatefulWidget {
  const TimeEditorSheet({required this.labels, required this.onCorrect, super.key});

  final TimeEditorLabels labels;

  /// `(hour, minute)`. Called only when four digits form a real wall time —
  /// **the sheet does not correct an impossible one**, it simply does not
  /// commit it, because silently turning 25:99 into 23:59 is §12.4.
  final void Function(int hour, int minute) onCorrect;

  @override
  State<TimeEditorSheet> createState() => _TimeEditorSheetState();
}

class _TimeEditorSheetState extends State<TimeEditorSheet> {
  String _digits = '';

  /// `null` until four digits form a real time. **Nothing is clamped and nothing
  /// is rounded**: an impossible time leaves the button inert rather than
  /// becoming a different time the shepherd did not type.
  ({int hour, int minute})? get _parsed {
    if (_digits.length != 4) {
      return null;
    }
    final int h = int.parse(_digits.substring(0, 2));
    final int m = int.parse(_digits.substring(2, 4));
    if (h > 23 || m > 59) {
      return null;
    }
    return (hour: h, minute: m);
  }

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final TimeEditorLabels l = widget.labels;

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
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: Text(l.hint, style: text.bodySmall),
          ),
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: Container(
              key: const Key('lambing_entry.time_editor.value'),
              height: t.tapIndelible,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: t.outline, width: t.outlineWidth),
                ),
              ),
              // `03:2` while they are typing — the colon is punctuation on the
              // digits they have entered, never a placeholder for ones they
              // have not.
              child: Text(_display(), style: text.displaySmall),
            ),
          ),
          ShedKeypad(
            onDigit: (String d) => setState(() {
              if (_digits.length < 4) {
                _digits += d;
              }
            }),
            onBackspace: () => setState(() {
              if (_digits.isNotEmpty) {
                _digits = _digits.substring(0, _digits.length - 1);
              }
            }),
            // The third key is the decimal rather than NEW TAG, and it appends
            // nothing here: a time has no decimal point. It stays LIVE because a
            // dead key under a cold thumb is indistinguishable from a missed tap
            // (`indelible.md §7.2`) — pressing it is simply a no-op the shepherd
            // sees, since the field does not change.
            thirdKey: ShedKeypadThirdKey.decimal,
            onThirdKey: () {},
            padLabel: l.padLabel,
            backspaceLabel: l.backspaceLabel,
            backspaceHint: l.backspaceHint,
            thirdKeyLabel: '.',
          ),
          SizedBox(height: t.gapMin),
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: ShedTapTarget(
              key: const Key('lambing_entry.time_editor.confirm'),
              semanticLabel: l.confirmSemanticLabel,
              minSize: t.tapHero,
              // NEVER NULL. An impossible time does not disable the button; it
              // means pressing it does nothing, which the empty field explains.
              // A greyed button at 03:20 reads as a broken app.
              onTap: () {
                if (_parsed case final ({int hour, int minute}) time) {
                  widget.onCorrect(time.hour, time.minute);
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

  String _display() => switch (_digits.length) {
    0 => '',
    1 || 2 => _digits,
    _ => '${_digits.substring(0, 2)}:${_digits.substring(2)}',
  };
}

// lib/core/ui/components/shed_text_field.dart
//
// **THE APP HAD NO WAY TO ENTER FREE TEXT. AT ALL.**
//
// Measured 2026-08-05: `TextField`, `TextFormField`, `EditableText` and
// `TextEditingController` appeared **three times in `lib/`, all three inside
// comments**. `ShedFieldRow` is §7.12's shell — label above, value on a rule,
// dotted rule when unset — and it takes an `onTap` and opens *"whatever surface
// the screen chooses"*. No screen ever chose one.
//
// That single absence is what left a cluster of repository verbs with no caller:
// a treatment cannot be recorded without a product name, a note cannot be added
// without a note, and both honest deletes require the season year or the word
// `EVERYTHING` typed into a field. `indelible.md §7.12` specifies the control
// completely — geometry, four states, and the rule below — and it was never
// built.
//
// **NEVER A PLACEHOLDER, AND THE ABSENCE IS THE MECHANISM.** §7.12: *there is
// never placeholder text inside a field.* In the dark a grey placeholder is
// indistinguishable from an entered value, and in the withdrawal-days field a
// placeholder number is a food-chain risk — safety rule §12.1 broken by a
// decoration. So this API has no `hintText`, no `initialValue`, no
// `defaultValue` and no `InputDecoration`, exactly as `ShedFieldRow` has none.
// Hints live in the label, above the line, in the control voice, where they
// cannot be mistaken for content.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shed_book/core/ui/components/shed_status_badge.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// A 64 px text line: label above, value **on** the rule, rule below.
///
/// **THE VALUE IS THE RECORD FACE AND THE LABEL IS THE CONTROL FACE** (Rule 2).
/// What the shepherd typed happened; the label is a thing they can press.
final class ShedTextField extends StatefulWidget {
  const ShedTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    super.key,
    this.stamp,
    this.maxLength,
  });

  /// **Always above the value, never inside it.** A label that becomes a
  /// placeholder is a label that disappears the moment the field is filled, and
  /// then nobody can check what they answered.
  final String label;

  /// `null` is unset — the dotted rule. **It is not `''`.** Empty string is a
  /// value nobody can see; null is the visible gap.
  final String? value;

  /// Fires on every keystroke, with `null` when the field is emptied.
  ///
  /// **EVERY WRITE COMMITS IMMEDIATELY** and this is where that lands for text:
  /// there is no Save button in this product and no draft to lose, so the
  /// screen writes what it is handed. A controller that batched keystrokes into
  /// a commit would be a draft wearing a different name.
  final ValueChanged<String?> onChanged;

  final String semanticLabel;

  /// §7.12's fourth state — `YOUR ENTRY` on the withdrawal-days field.
  ///
  /// **THE STAMP AND ITS WORD ARE PASSED TOGETHER**, because `ShedStatusBadge`
  /// requires both and `lib/core/ui/` may not resolve copy. The caller picks
  /// `ShedStamp.yourEntry`; this component only places it.
  ///
  /// **DISCREPANCY, RECORDED RATHER THAN QUIETLY RESOLVED:** `indelible.md`
  /// §7.12 and `indelible-marks-and-strikes` §6 both list `YOUR ENTRY` as a
  /// **boxed** stamp, and `ShedStamp.yourEntry` is declared `unboxed`. Changing
  /// a shipped stamp's form moves pixels in two goldens and a contrast case, so
  /// it is a ruling rather than an edit made in passing. This component renders
  /// whichever form the enum declares.
  final ({ShedStamp stamp, String label})? stamp;

  /// A hard cap, enforced by the input formatter rather than by a validator.
  ///
  /// **NOT A COUNTER AND NOT A WARNING.** A season label is 1–60 characters by
  /// schema `CHECK`; a field that let somebody type 61 and then refused the
  /// write would be safety rule §12.4's *never silently correct* in the one
  /// direction that is worse — correcting after the fact.
  final int? maxLength;

  @override
  State<ShedTextField> createState() => _ShedTextFieldState();
}

class _ShedTextFieldState extends State<ShedTextField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value ?? '');
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Focus drives the rule's weight (§7.12): dotted when unset, 2 px solid
    // `--ink-full` while focused, 2 px solid `--rule` when filled.
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final bool filled = _controller.text.trim().isNotEmpty;

    return Semantics(
      textField: true,
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                // **`Flexible`, BECAUSE A LABEL IS A SENTENCE AT 200%.**
                // `DAYS — READ FROM THE BOTTLE. YOUR ENTRY.` is the longest
                // label in the app and the one that must not be clipped.
                // Measured: the bare `Text` overflowed Lambing Entry's row by
                // 26 to 56 px at textScaler 2.0, and the overflow matrix caught
                // all six cells on the first run.
                Flexible(
                  child: Text(
                    widget.label,
                    style: text.labelMedium?.copyWith(color: t.textSecondary),
                  ),
                ),
                if (widget.stamp case final ({ShedStamp stamp, String label}) badge) ...<Widget>[
                  SizedBox(width: t.gapMin / 2),
                  ShedStatusBadge(stamp: badge.stamp, label: badge.label),
                ],
              ],
            ),
            // **A MINIMUM, NOT A FIXED HEIGHT** (`indelible.md §3.6`: rows grow,
            // the grid does not move). The value inside is 20 px record face,
            // which is 40 at 200%, and a fixed 64 px box cannot hold it.
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: t.tapIndelible),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  // **THE RECORD FACE.** What they typed happened.
                  style: text.bodyLarge,
                  cursorColor: t.textPrimary,
                  cursorWidth: t.outlineWidth,
                  maxLines: 1,
                  inputFormatters: <TextInputFormatter>[
                    if (widget.maxLength case final int max) LengthLimitingTextInputFormatter(max),
                  ],
                  // **EVERY ONE OF THESE IS A DEFAULT BEING REFUSED.** Material's
                  // field arrives with an underline, a fill, a counter, a
                  // floating label and a hint slot — five decorations this
                  // design does not have, and the hint slot is the one that is a
                  // safety rule.
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                  onChanged: (String v) => widget.onChanged(v.trim().isEmpty ? null : v),
                ),
              ),
            ),
            _Rule(filled: filled, focused: _focus.hasFocus, t: t),
          ],
        ),
      ),
    );
  }
}

/// §7.12's rule: **dotted is the visible gap.**
///
/// *"A blank reads as missing data, a dotted rule reads as nothing happened, and
/// they are different facts."* Never solid when unset, so an empty field can
/// never be confused with an entered one.
class _Rule extends StatelessWidget {
  const _Rule({required this.filled, required this.focused, required this.t});

  final bool filled;
  final bool focused;
  final ShedTokens t;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('shed_text_field.rule'),
    height: t.outlineWidth,
    width: double.infinity,
    child: CustomPaint(
      painter: _RulePainter(
        colour: focused ? t.textPrimary : t.outline,
        dotted: !filled && !focused,
        width: t.outlineWidth,
      ),
    ),
  );
}

class _RulePainter extends CustomPainter {
  const _RulePainter({required this.colour, required this.dotted, required this.width});

  final Color colour;
  final bool dotted;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pen = Paint()
      ..color = colour
      ..strokeWidth = width
      // NOTHING IN A PRINTED BOOK HAS A ROUNDED END.
      ..strokeCap = StrokeCap.butt;

    if (!dotted) {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), pen);
      return;
    }

    // `--rule-dot` is `2px 6px` — two on, six off.
    const double on = 2;
    const double off = 6;
    for (double x = 0; x < size.width; x += on + off) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset((x + on).clamp(0, size.width), size.height / 2),
        pen,
      );
    }
  }

  @override
  bool shouldRepaint(_RulePainter old) =>
      old.colour != colour || old.dotted != dotted || old.width != width;
}

// lib/features/flock/widgets/withdrawal_note.dart
//
// **THE FIGURE, AND WHERE IT CAME FROM.** §12.1's whole mechanism arrives here
// as a `sealed WithdrawalPeriod` with three variants, so *not recorded* is a
// **type**, not a null int — and the coalesce-to-zero this file would otherwise
// be the natural home of is not merely banned here, it is unwritable, because
// there is no nullable int to coalesce. (The operator is described rather than
// spelled: `stat.zero_default2` scans source text, comments included, and this
// is the twenty-eighth time this project has failed its own gate inside the
// comment explaining that gate.)
//
// `Disclaimers.withdrawalProvenance` is **referenced, never re-typed** (#62,
// §12.3's mechanism). `test/policy/disclaimer_is_defined_once_test.dart` asserts
// the literal appears in exactly one file and the gate row scans for it — and
// the card's own test asserts **identity with the constant**, because a text
// match passes on a copy.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';
import 'package:shed_book/l10n/app_localizations.dart';

final class WithdrawalNote extends StatelessWidget {
  const WithdrawalNote({required this.period, super.key});

  final WithdrawalPeriod period;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;

    // **EXHAUSTIVE, NO `default:`.** `WithdrawalPeriod` is sealed with three
    // variants; the day a fourth lands — v2's milkings, whose interval would be
    // required and user-supplied — this must fail to compile rather than render
    // one of the three.
    final String figure = switch (period) {
      WithdrawalDays(:final int days) => l10n.eweCardWithdrawalDays(days: days),
      WithdrawalNotApplicable() => l10n.eweCardWithdrawalNotApplicable,
      WithdrawalNotRecorded() => l10n.eweCardWithdrawalNotRecorded,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // **NOT RECORDED PRINTS A DOTTED RULE AND THE WORDS.** `indelible.md §5`:
        // never a blank line, never `0`, never an em dash alone — a blank reads
        // as missing data and a dotted rule reads as *nothing happened*, and they
        // are different facts.
        if (period is WithdrawalNotRecorded) _dottedRule(t),
        Text(figure, style: text.bodyMedium),
        // **THE DISCLAIMER RIDES ON THE FIGURE, AND ONLY ON A FIGURE.** A
        // not-recorded state has no number that could have come from the
        // shepherd, so *"as entered by you"* beside it would be a claim about an
        // entry nobody made.
        if (period is WithdrawalDays)
          Text(Disclaimers.withdrawalProvenance, style: text.labelMedium),
      ],
    );
  }

  /// `--rule-dot`: 2 px on, 6 px off. Never solid, so an empty field can never be
  /// confused with an entered one. Rules do not scale with text — a rule is a
  /// physical mark, not type.
  Widget _dottedRule(ShedTokens t) => SizedBox(
    height: t.outlineWidth,
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => Row(
        children: <Widget>[
          for (int i = 0; i < constraints.maxWidth ~/ (t.gapMin / 2); i++)
            Padding(
              padding: EdgeInsets.only(right: t.gapMin / 4),
              child: SizedBox(
                width: t.outlineWidth,
                height: t.outlineWidth,
                child: ColoredBox(color: t.outline),
              ),
            ),
        ],
      ),
    ),
  );
}

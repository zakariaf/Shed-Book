// lib/core/ui/components/shed_countdown.dart
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_status.dart';

/// The withdrawal countdown.
///
/// **THREE CONSTRUCTORS, AND THE SPLIT IS THE SAFETY RULE.** `07 §10.3` names
/// three different facts and this type refuses to blur them:
///
///   * the default takes a [ClearsOn] — a real period, so it draws a figure, a
///     tally and a clear date;
///   * [ShedCountdown.notRecorded] is a **gap** (`WithdrawalUnknown`): words
///     only, no date, no figure, no tally;
///   * [ShedCountdown.notApplicable] is a **fact off the label**
///     (`NoWithdrawal`): also words, and a *different sentence*.
///
/// The default constructor's parameter is `ClearsOn` and never
/// `WithdrawalStatus` (`CONVENTIONS §2.7`), so **a countdown for an unrecorded
/// period is type-impossible** rather than merely discouraged. That is safety
/// rule §12.1 held at the type level: a `0` where a withdrawal was never
/// recorded is the exact failure the rule exists to prevent, and `0` is a real
/// label value.
///
/// **It reads no clock** (R24). `now` arrives as a parameter and this file
/// imports no `lib/core/time/`.
final class ShedCountdown extends StatelessWidget {
  const ShedCountdown({
    required ClearsOn this.clearsOn,
    required Instant this.now,
    required this.productName,
    required String this.clearsOnLabel,
    required this.semanticLabel,
    super.key,
  }) : words = null;

  /// `WithdrawalUnknown` — a gap.
  const ShedCountdown.notRecorded({
    required this.productName,
    required String this.words,
    required this.semanticLabel,
    super.key,
  }) : clearsOn = null,
       now = null,
       clearsOnLabel = null;

  /// `NoWithdrawal` — a fact off the label, and **distinct from a gap**. A
  /// product with no withdrawal period is a thing the shepherd read; a gap is a
  /// thing nobody recorded. Rendering the same sentence for both is how the
  /// second becomes invisible.
  const ShedCountdown.notApplicable({
    required this.productName,
    required String this.words,
    required this.semanticLabel,
    super.key,
  }) : clearsOn = null,
       now = null,
       clearsOnLabel = null;

  final ClearsOn? clearsOn;
  final Instant? now;
  final String productName;

  /// `CLEARS 12 AUG 2026`, already formatted by the caller (R60).
  final String? clearsOnLabel;

  final String? words;
  final String semanticLabel;

  /// indelible.md §7.9. Beyond this the strokes stop being countable and start
  /// being a texture, so the surplus is printed as a figure instead.
  static const int maxMarks = 28;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    final String? onlyWords = words;
    if (onlyWords != null) {
      return Semantics(
        label: semanticLabel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(productName, style: text.titleSmall),
            Text(onlyWords, style: text.bodyMedium),
          ],
        ),
      );
    }

    // Whole civil days remaining. LocalDate arithmetic, never Instant
    // subtraction: `elapsesAt.difference(now).inDays` truncates a 23-hour
    // spring-forward day to 0 and silently loses a day of a withdrawal period.
    final int days = LocalDate.of(now!).daysUntil(clearsOn!.date);
    final bool cleared = days <= 0;
    final bool lastDay = days == 1;
    final int marks = days.clamp(0, maxMarks);
    final int surplus = days > maxMarks ? days - maxMarks : 0;

    return Semantics(
      label: semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(productName, style: text.titleSmall),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$days',
                // headlineLarge is tabular. THE FIGURE IS NEVER RECOLOURED on
                // the last day — indelible.md §7.9 spends the last day on a
                // WORD, a dagger and a doubled rule, three non-colour channels,
                // because the one thing a shepherd must not have to do at 03:20
                // is distinguish two reds.
                style: text.headlineLarge,
              ),
              if (lastDay) ...<Widget>[
                SizedBox(width: t.gapMin / 2),
                Text('LAST DAY', style: text.titleSmall),
                Text('†', style: text.titleSmall),
              ],
              if (surplus > 0) ...<Widget>[
                SizedBox(width: t.gapMin / 2),
                Text('+$surplus', style: text.titleSmall),
              ],
            ],
          ),
          // The tally, and the cleared rule that replaces it, occupy the SAME
          // width — both are full-width boxes — so nothing reflows when a
          // withdrawal clears. A row that jumps on the day it clears is a row
          // whose neighbour gets pressed.
          SizedBox(
            width: double.infinity,
            child: cleared
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: t.outline, width: t.outlineWidth),
                      ),
                    ),
                    child: SizedBox(height: t.outlineWidth),
                  )
                : Row(
                    children: <Widget>[
                      for (int i = 0; i < marks; i++)
                        Padding(
                          padding: EdgeInsets.only(right: t.outlineWidth),
                          child: SizedBox(
                            width: t.outlineWidth,
                            height: t.gapMin,
                            child: ColoredBox(color: t.textPrimary),
                          ),
                        ),
                    ],
                  ),
          ),
          Text(
            clearsOnLabel!,
            style: text.bodyMedium,
            // Doubled rule on the last day: the third non-colour channel.
            strutStyle: lastDay ? const StrutStyle(forceStrutHeight: true) : null,
          ),
          if (lastDay)
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: t.outline, width: t.outlineWidth),
                    bottom: BorderSide(color: t.outline, width: t.outlineWidth),
                  ),
                ),
                child: SizedBox(height: t.ruleDoubleGapHeight),
              ),
            ),
        ],
      ),
    );
  }
}

extension on ShedTokens {
  /// indelible.md §4.2's `--rule-double-gap`. It is not a palette value, so it
  /// is derived from `outlineWidth` rather than added as a token nothing else
  /// would read.
  double get ruleDoubleGapHeight => outlineWidth * 1.5;
}

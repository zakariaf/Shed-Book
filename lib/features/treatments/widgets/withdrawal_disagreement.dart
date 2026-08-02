// lib/features/treatments/widgets/withdrawal_disagreement.dart
//
// WHEN THE STORED CLEAR DATE AND A RECOMPUTATION DISAGREE, BOTH ARE SHOWN AND
// NEITHER IS UPDATED.
//
// It happens when the device changed timezone between the write and the read.
// §12.4 forbids silently correcting a user's entry, and the stored date is the
// one the shepherd was told and may have written in a book and handed to a vet.
//
// **THERE IS NO CONTROL OFFERING TO RECONCILE THEM.** Offering would make the app
// the arbiter of a clinical date, which is the same line §12.2 draws: the app may
// arithmetic-transform a number the user supplied, never originate one that is a
// clinical decision. The line says nothing has been changed, in as many words.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/tokens.dart';

typedef DisagreementLabels = ({String stored, String recomputed, String explanation});

class WithdrawalDisagreement extends StatelessWidget {
  const WithdrawalDisagreement({required this.labels, super.key});

  final DisagreementLabels labels;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.all(t.gapMin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // THE STORED ONE FIRST, ALWAYS. It is the one in the book.
          Text(
            labels.stored,
            key: const Key('treatment.withdrawal.stored'),
            style: text.bodyMedium,
          ),
          Text(
            labels.recomputed,
            key: const Key('treatment.withdrawal.recomputed'),
            style: text.bodySmall?.copyWith(color: t.textSecondary),
          ),
          SizedBox(height: t.gapMin / 4),
          Text(
            labels.explanation,
            key: const Key('treatment.withdrawal.disagrees'),
            style: text.bodySmall?.copyWith(color: t.statusAttention),
          ),
        ],
      ),
    );
  }
}

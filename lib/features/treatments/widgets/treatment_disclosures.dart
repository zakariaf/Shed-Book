// lib/features/treatments/widgets/treatment_disclosures.dart
//
// SAFETY RULE §12.3: never present the app as a compliance record.
//
// **EVERY STRING HERE IS REFERENCED FROM `Disclaimers` AND NONE IS RE-TYPED.**
// That is `12 §10.1`'s whole mechanism: `Disclaimers` is an `abstract final
// class` of `const` strings in one file, and the moment a screen types its own
// version there are two wordings — one of which somebody will improve and the
// other of which will not follow.
//
// It is also why the tests compare against the CONSTANTS rather than against a
// copy of their text: a test that hard-codes the literal still passes after
// somebody edits the constant, which is the one failure the assertion exists to
// catch.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/policy/disclaimers.dart';

/// The footer on the medicine-book view.
///
/// **REACHABLE WITHOUT A TAP.** It is on the first painted frame of book mode,
/// not behind an "about" affordance — a disclosure the shepherd has to go
/// looking for is a disclosure that has not been made.
class TreatmentBookFooter extends StatelessWidget {
  const TreatmentBookFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    return Padding(
      padding: EdgeInsets.all(t.gapMin),
      child: Text(
        // REFERENCED, NEVER RE-TYPED.
        Disclaimers.exportFooter,
        key: const Key('treatments.book.footer'),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.textSecondary),
      ),
    );
  }
}

/// The caveat beside the withdrawal entry control.
class WithdrawalCaveat extends StatelessWidget {
  const WithdrawalCaveat({super.key});

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
      child: Text(
        Disclaimers.withdrawalCaveat,
        key: const Key('treatment.withdrawal.caveat'),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.textSecondary),
      ),
    );
  }
}

/// The provenance stamp beside a stored withdrawal period.
///
/// The four words that keep a stored number from reading as the app's own
/// advice. They travel with the number everywhere it goes, which is why this is
/// a widget rather than a string a caller assembles.
///
/// **THE WORDS ARE NOT QUOTED IN THIS COMMENT**, and that is not fussiness:
/// `disclaimer_is_referenced_test.dart` scans this feature for the constants'
/// VALUES, so a doc comment that spells one out is a second copy — the exact
/// thing the one-file rule exists to prevent. It caught the first draft of this
/// comment.
class WithdrawalProvenanceStamp extends StatelessWidget {
  const WithdrawalProvenanceStamp({super.key});

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    return Text(
      Disclaimers.withdrawalProvenance,
      key: const Key('treatment.withdrawal.provenance'),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.textSecondary),
    );
  }
}

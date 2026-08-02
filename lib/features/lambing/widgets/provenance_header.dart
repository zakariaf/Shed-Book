// lib/features/lambing/widgets/provenance_header.dart
//
// THE PROVENANCE TRAVELS WITH THE TIME, ALWAYS. §12.5 is unrepresentable in the
// domain — `RecordedTime` has no constructor that produces a time without a
// source — and this is the one place that claim reaches the shepherd. A header
// that printed `03:20` alone would make the mechanism true and the product
// silent about it.
//
// THE LABEL IS THE DOMAIN'S, NOT THE ARB'S. `provenanceLabel` is English in
// `lib/domain/`, which is correct today because v1 ships `en` only (decision
// #108, `05 §4.1`). If a second locale ever ships, the label moves to ARB AND
// the exhaustive-switch test moves with it. Meanwhile no ARB message duplicates
// one of the three, because two spellings of the same claim is how they drift.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/time/recorded_time.dart';

/// The words around the time. The formatted strings arrive already made —
/// `formatShedTime` lives at the screen edge with the locale.
typedef ProvenanceLabels = ({
  String effective,

  /// Non-null only when the time was edited. **The FIRST value, not the
  /// previous one**: an unbounded chain of edits keeps what we first thought.
  String? wasEffective,
  String wasPrefix,
  String semanticLabel,
  String editSemanticLabel,
});

class ProvenanceHeader extends StatelessWidget {
  const ProvenanceHeader({
    required this.time,
    required this.labels,
    required this.onCorrect,
    super.key,
  });

  final RecordedTime time;
  final ProvenanceLabels labels;

  /// **`07 §6.4` gives this screen exactly ONE time-editing action and this is
  /// it.** `CareEvents` carries the full quad too, which PERMITS an edit verb
  /// but does not require one — the standing rule runs one way only (`05 §4.2`):
  /// *a table without the quad has no edit verb*. Do not add a per-care-event
  /// time picker.
  final VoidCallback onCorrect;

  bool get _edited => time.originalEffective != null;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    return ShedTapTarget(
      key: const Key('lambing_entry.provenance_header'),
      semanticLabel: labels.semanticLabel,
      onTapHint: labels.editSemanticLabel,
      minSize: t.tapIndelible,
      onTap: onCorrect,
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: t.gapMin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    labels.effective,
                    key: const Key('lambing_entry.provenance_time'),
                    style: text.titleMedium,
                  ),
                  if (_edited) ...<Widget>[
                    SizedBox(width: t.gapMin / 4),
                    // THE DAGGER, BESIDE THE TIME. A third channel alongside the
                    // phrase below and the *was* line, because colour is never
                    // one of the three on its own (`10 §5.2`) and this system
                    // has no status palette to use as one anyway.
                    Text(
                      '†',
                      key: const Key('lambing_entry.provenance_dagger'),
                      style: text.bodySmall,
                    ),
                  ],
                ],
              ),
              // THE PROVENANCE ON ITS OWN LINE, AND THAT IS A RULING BETWEEN TWO
              // DOCUMENTS.
              //
              // `indelible.md §6.2` draws the margin stamp as a short `AUTO` /
              // `EDITED`. `provenanceLabel` is a PHRASE — *"recorded
              // automatically"*, *"time edited by you"* — and N16-T07 is
              // explicit that no second spelling of it may exist: *"no ARB
              // message duplicates one of the three."* A short stamp beside the
              // time would be exactly that second spelling.
              //
              // So the phrase wins and it gets its own line. Measured: in the
              // Row beside the time it overflowed a 393 pt header by 164 px, so
              // this is not only the honest reading of the rule but the only one
              // that fits. If the short stamp is wanted, it is `provenanceLabel`
              // that changes — one spelling, in the domain, with the exhaustive
              // switch and its test moving with it.
              Text(
                time.provenanceLabel,
                key: const Key('lambing_entry.provenance'),
                style: text.bodySmall,
              ),
              // WHAT IT WAS EDITED FROM, on its own line. Without it the label
              // is true and uninformative: the shepherd learns that a time was
              // changed and not what it was changed from, which is the half
              // that matters when they are checking their own memory.
              if (labels.wasEffective case final String was)
                Text(
                  '${labels.wasPrefix} $was',
                  key: const Key('lambing_entry.provenance_was'),
                  style: text.bodySmall?.copyWith(color: t.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

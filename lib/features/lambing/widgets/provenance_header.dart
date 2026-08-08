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
import 'package:shed_book/core/ui/components/shed_ruled_row.dart';
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

  /// `AUTO` / `ENTERED` / `EDITED` — the SHORT stamp, for the 68 pt margin.
  ///
  /// **IT IS NOT A SECOND SPELLING OF `provenanceLabel`, BECAUSE BOTH ARE ON
  /// THIS ROW AT ONCE.** N16-T07 forbade a short stamp that REPLACED the phrase;
  /// what it forbade was the claim being made twice in two wordings in two
  /// places. Here the margin carries the four-letter stamp and the record column
  /// carries the phrase, on the same line, so a reader gets one claim in the
  /// glance and the whole of it in the read. `tonight_rows.dart` records the
  /// other half of the arithmetic: an 18 px caps-tracked phrase does not fit
  /// 68 px — six characters is already ~84 — so a margin that tried to carry the
  /// phrase printed `recor…`, which states nothing at all.
  String stamp,
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

    // **THE FIRST RULED ROW OF THE PAGE, AND THE MARGIN IS WHERE THE TIME
    // LIVES.** `§4.3`: margin cell 0–68 carries the time with its stamp beneath;
    // the record column from 76 carries the sentence. Before R87 this widget was
    // a bare `Column` of three `Text`s with no margin, no rule and no gutter —
    // the time sat at x=16 in the same column as the words, so the one number a
    // shepherd looks for at 03:20 had no fixed place on the page.
    return ShedRuledRow(
      key: const Key('lambing_entry.provenance_header'),
      semanticLabel: labels.semanticLabel,
      // THE VERB, RENAMED. *"Double tap to correct the time"* — without it the
      // node says a time and a source and gives no clue that pressing it does
      // anything at all.
      onTapHint: labels.editSemanticLabel,
      onTap: onCorrect,
      height: kRuledRowTall,
      margin: Padding(
        padding: EdgeInsets.symmetric(horizontal: t.gapMin / 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    labels.effective,
                    key: const Key('lambing_entry.provenance_time'),
                    style: text.titleMedium,
                    maxLines: 1,
                  ),
                ),
                if (_edited) ...<Widget>[
                  SizedBox(width: t.gapMin / 4),
                  // THE DAGGER, IN THE MARGIN CELL (`§6.2`). A third channel
                  // alongside the phrase and the *was* line, because colour is
                  // never one of the three on its own (`10 §5.2`) and this
                  // system has no status palette to use as one anyway.
                  Text(
                    '†',
                    key: const Key('lambing_entry.provenance_dagger'),
                    style: text.bodySmall,
                  ),
                ],
              ],
            ),
            Text(labels.stamp, style: text.labelSmall, maxLines: 1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // THE PROVENANCE PHRASE, IN THE RECORD COLUMN, AND THAT IS A RULING
          // BETWEEN TWO DOCUMENTS.
          //
          // `indelible.md §6.2` draws the margin stamp as a short `AUTO` /
          // `EDITED`. `provenanceLabel` is a PHRASE — *"recorded
          // automatically"*, *"time edited by you"* — and N16-T07 is explicit
          // that no second spelling of it may exist: *"no ARB message
          // duplicates one of the three."*
          //
          // Both survive here because they are not two spellings competing for
          // one slot: the stamp is the margin's four letters and the phrase is
          // the record column's sentence, and `tonight_rows.dart` already
          // ruled that the long label *"prints in the RECORD COLUMN on Lambing
          // Entry, where it has the width."* Measured before that: in a Row
          // beside the time the phrase overflowed a 393 pt header by 164 px.
          Text(
            time.provenanceLabel,
            key: const Key('lambing_entry.provenance'),
            style: text.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // WHAT IT WAS EDITED FROM, on its own line. Without it the label is
          // true and uninformative: the shepherd learns that a time was changed
          // and not what it was changed from, which is the half that matters
          // when they are checking their own memory.
          if (labels.wasEffective case final String was)
            Text(
              '${labels.wasPrefix} $was',
              key: const Key('lambing_entry.provenance_was'),
              style: text.bodySmall?.copyWith(color: t.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

// lib/features/flock/ewe_card_screen.dart — `indelible.md §8` screen 2.
//
// **T01 IS DELIBERATELY MINIMAL: ONE LINE PER TIMELINE ROW.** The statement is
// the task, and this screen exists to prove it reaches a widget. T02 builds the
// summary line, T04 turns each line into a real ruled record row with its
// provenance label, and T07 lands the heading hierarchy and the empty state.
//
// A screen that arrived whole here would be a screen nobody reviewed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_empty_state.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/flock/ewe_card_controller.dart';
import 'package:shed_book/features/flock/widgets/earlier_animal_note.dart';
import 'package:shed_book/features/flock/widgets/ewe_summary_line.dart';
import 'package:shed_book/routing/routes.dart';
import 'package:shed_book/features/flock/widgets/timeline_record_row.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class EweCardScreen extends ConsumerWidget {
  const EweCardScreen({required this.eweId, required this.tag, super.key});

  final EweId eweId;

  /// **PASSED IN, NOT LOOKED UP.** The tag is what the shepherd tapped to get
  /// here, so it is already known — a second statement to re-read it would put a
  /// frame between opening the card and knowing whose it is.
  final String tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: t.surfaceBase,
      body: SafeArea(
        // **THE SUMMARY LINE IS FIRST, ABOVE THE TIMELINE.** Spec §7.7: it is
        // *"visible before anything else"*, and that is a widget-order fact
        // rather than a comment — `07 §4.2`'s frame 1 reserves its height so the
        // page does not shift when the counts land.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // **UNDER THE HEADER AND ABOVE THE SUMMARY LINE** (`07 §4.2`). It
            // qualifies *who this card is about*, so it cannot come after the
            // history it qualifies — a reader who meets the timeline first has
            // already begun attributing it to one animal.
            EarlierAnimalNote(
              eweId: eweId,
              tag: tag,
              // **THE EARLIER CARD DOES NOT DISCLOSE BACK.** The relationship is
              // directional: she is finished, and telling a reader of a closed
              // record that a different animal has her number later is noise at
              // the moment they are trying to read one history. That falls out of
              // the statement rather than out of this call — it returns only
              // animals whose status is not active.
              onOpen: (EweId earlier, String earlierTag) =>
                  Routes.eweCard(context, earlier, tag: earlierTag),
            ),
            EweSummaryLine(eweId: eweId, tag: tag),
            Expanded(child: _timeline(context, ref, t, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _timeline(BuildContext context, WidgetRef ref, ShedTokens t, AppLocalizations l10n) =>
      SizedBox.expand(
        // **EVERY ARM WRITTEN OUT** (`02 §4.5`), and read as an exhaustive
        // switch rather than through the accessors that flatten the three states
        // into two. The trailing `_` is loading and Dart's exhaustiveness
        // requirement in one — `AsyncValue`'s hierarchy is not closed over the
        // refreshing combinations.
        child: switch (ref.watch(eweTimelineProvider(eweId))) {
          AsyncData<List<TimelineRow>>(value: final List<TimelineRow> rows) when rows.isEmpty =>
            ShedEmptyState(key: const Key('ewe_card.empty'), copy: l10n.eweCardEmpty),
          AsyncData<List<TimelineRow>>(value: final List<TimelineRow> rows) => ListView.builder(
            key: const Key('ewe_card.timeline'),
            padding: EdgeInsets.zero,
            itemCount: rows.length,
            // **KEYED ON THE PAIR, NEVER ON `ref` ALONE.** Lambing 7 and note 7
            // are both `ref: 7`, so a key built from the id alone collides and
            // Flutter reuses the wrong element.
            itemBuilder: (BuildContext context, int i) => TimelineRecordRow(
              key: Key('ewe_card.row.${rows[i].kind.key}.${rows[i].ref}'),
              row: rows[i],
            ),
          ),
          AsyncError<List<TimelineRow>>() => ShedEmptyState(
            key: const Key('ewe_card.error'),
            copy: l10n.eweCardUnavailable,
          ),
          // **NEVER A SPINNER** (#71). `07 §4.2`'s frame 1 is a fixed-height
          // placeholder at the summary line's exact height — T02 builds it, and
          // until the summary line exists there is no height to reserve, so the
          // page colour is the honest first frame rather than a lie about
          // progress.
          _ => const SizedBox.expand(),
        },
      );
}

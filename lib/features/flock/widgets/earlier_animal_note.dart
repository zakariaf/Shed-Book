// lib/features/flock/widgets/earlier_animal_note.dart
//
// **"THERE WAS AN EARLIER 412."** The active-only uniqueness ruling has a
// consequence a shepherd must be told about: a reused tag means two animals
// share a number, and without this the ruling silently merges two ewes'
// histories in the reader's head.
//
// **IT IS A STATE, NOT AN AFFORDANCE.** `07 §4.2` lists it among the loaded
// card's states: it renders whenever the tag was reused — not behind a "show
// history" toggle, not on a long press (banned), not only when the user asks. A
// disclosure the user has to find is not a disclosure.
//
// **AND IT IS NOT AN ERROR.** Tags are unique among active animals only (§7.0
// ruling 7), so this is a normal, expected state. No red, no warning mark, no
// exclamation — a sentence and a way to read the other record.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/ewe_status.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/features/flock/ewe_card_controller.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class EarlierAnimalNote extends ConsumerWidget {
  const EarlierAnimalNote({
    required this.eweId,
    required this.tag,
    required this.onOpen,
    super.key,
  });

  final EweId eweId;
  final String tag;

  /// Pushing the earlier animal's card is the **screen's** job, not this
  /// widget's: a widget that pushes its own route is a widget two screens can
  /// never share (`02 §8.4`).
  final void Function(EweId earlier, String tag) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toLanguageTag();

    final List<EarlierAnimal> earlier = switch (ref.watch(
      earlierAnimalsProvider((ewe: eweId, tag: tag)),
    )) {
      AsyncData<List<EarlierAnimal>>(value: final List<EarlierAnimal> l) => l,
      // **NOTHING, NOT A PLACEHOLDER.** The common case by far is no reuse at
      // all, and reserving height for a disclosure that will not arrive would
      // put a gap under the header on every card in the flock.
      _ => const <EarlierAnimal>[],
    };
    if (earlier.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      key: const Key('ewe_card.earlier_animal'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      // **ONE ROW EACH, NEVER A JOINED SENTENCE.** Nothing stops a tag being
      // reused twice over ten seasons, and *"An earlier 412 and another earlier
      // 412"* is not a sentence anybody wants to read at 9am.
      children: <Widget>[
        for (final EarlierAnimal a in earlier)
          ShedTapTarget(
            key: Key('ewe_card.earlier_animal.${a.eweId.value}'),
            semanticLabel: l10n.eweCardEarlierAnimalOpen(tag: a.tag),
            minSize: t.tapIndelible,
            onTap: () => onOpen(a.eweId, a.tag),
            child: ExcludeSemantics(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _sentence(l10n, a, locale),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// **THE STATUS WORD WITHOUT A DATE, AND AN EVENT DATE THAT IS REAL.**
  ///
  /// `07 §4.2` prints *"An earlier 412 was culled on 12 Aug 2025"*, which needs
  /// the date her status changed — and **R41 rules there is no status-history
  /// table**. `ewes.status` is a mutable column with `updated_at` moving, and
  /// `updated_at` is a *row-lifecycle* fact: it moves when anyone edits her
  /// breed, her EID or her date of birth. Rendering it as *"culled on"* would
  /// present a maintenance timestamp as an event time, which is the laundering
  /// §12.5 exists to prevent — an event time carries its provenance and
  /// `updated_at` has none.
  ///
  /// So the sentence states her status (true now, no date claimed) and the last
  /// **recorded event** on her record, which has its own provenance quad.
  /// `07 §4.2` is amended in the same commit.
  String _sentence(AppLocalizations l10n, EarlierAnimal a, String locale) {
    final String status = switch (a.status) {
      EweStatus.sold => l10n.eweStatusSold,
      EweStatus.dead => l10n.eweStatusDead,
      EweStatus.culled => l10n.eweStatusCulled,
      // Unreachable by construction — the statement filters `status <> 'active'`
      // — and written out rather than defaulted, so the day a fifth status lands
      // this fails to compile instead of printing the wrong word.
      EweStatus.active => l10n.eweStatusCulled,
    };
    if (a.lastRecordedAt == null) {
      return l10n.eweCardEarlierAnimalUndated(tag: a.tag, status: status);
    }
    return l10n.eweCardEarlierAnimal(
      tag: a.tag,
      status: status,
      // **A HUMAN-FACING DATE IS NEVER ALL-NUMERIC** (R60): `12 Aug 2025`, never
      // `12/08/2025`, which reads as a different day on two sides of an ocean.
      date: formatShedDate(LocalDate.of(a.lastRecordedAt!), locale),
    );
  }
}

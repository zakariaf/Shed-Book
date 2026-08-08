// lib/features/lambing/widgets/lamb_tally_row.dart
//
// The subject row: the derived birth type in the record column, the strokes in
// the trailing column, and the query mark in the margin when the declaration
// disagrees with them.
//
// ONE PRESS IS ONE STROKE AND ONE COMMITTED LAMB ROW. There is no confirmation
// step, because the row IS the confirmation — indelible.md §9's three presses.
//
// **THE PRESS MOVED TO THE CORNER SLAB AT R87, AND THE KEY MOVED WITH IT.**
// `indelible.md §7.1` puts the primary action at 160 × 140 in the bottom corner,
// inside `§4.5`'s thumb band; this row had it as an 88 pt cell at the right-hand
// end of a scrolling row, which is the one place `§4.5` says nothing required to
// record an event may sit. `lambing_entry.tally.stroke` is named in the decision
// record (P8) and pinned by four tests, so it travelled with the target rather
// than being renamed — the key is the ACT, not the widget it was drawn in.
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_ruled_row.dart';
import 'package:shed_book/core/ui/components/shed_tally.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/domain/birth_type.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class LambTallyRow extends StatelessWidget {
  const LambTallyRow({required this.lambs, super.key, this.margin});

  final List<LambEntryRow> lambs;

  /// The query mark, when the declaration contradicts the strokes.
  ///
  /// **IT SITS IN THE MARGIN OF THE OFFENDING ROW** (`indelible.md §6.2`), which
  /// is this one: the contradiction is between the declared type and the counted
  /// strokes, and the strokes are what is on screen here. It arrives as a widget
  /// rather than as a flag because deciding whether a warning exists is the
  /// screen's job — this row renders what it is handed.
  final Widget? margin;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);

    // STRUCK STROKES STILL COUNT AS MARKS and do not count as lambs. Indelible
    // Rule 1 keeps the mark on the page; the derived type is about the animals
    // that exist.
    final int live = lambs.where((LambEntryRow l) => !l.struck).length;
    final Set<int> struck = <int>{
      for (int i = 0; i < lambs.length; i++)
        if (lambs[i].struck) i,
    };

    final BirthType? counted = countedBirthType(live);
    final String typeLabel = live == 0
        ? l10n.lambingTypeNotRecorded
        : counted == null
        // Five or more: print the COUNT, because countedBirthType returns null
        // there rather than collapsing it onto quintPlus and throwing the
        // number away.
        ? l10n.lambingTypeCountedMany(count: live, animals: 'lambs')
        : l10n.lambingTypeCounted(type: counted.name);

    return ShedRuledRow(
      // TALL, BECAUSE THIS IS THE SUBJECT ROW. `§4.4` gives 88 to the row that
      // carries a large figure over a summary; the derived type is the largest
      // thing this screen can honestly print, because the ewe's tag is not on
      // the statement that feeds it.
      height: kRuledRowTall,
      margin: margin,
      trailing: Padding(
        padding: EdgeInsets.symmetric(vertical: t.gapMin),
        child: ShedTally(
          key: const Key('lambing_entry.tally'),
          count: lambs.length,
          struck: struck,
          semanticLabel: l10n.lambingTallySemantics(count: live, animal: 'lamb', animals: 'lambs'),
        ),
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          typeLabel,
          key: const Key('lambing_entry.counted_type'),
          // **THE RECORD FACE, LARGE.** §8 screen 4: birth type *"prints as
          // `TRIPLET (COUNTED)` beside three tally marks"* and is not a control
          // — so it is set as a value that happened, not as a thing to press.
          style: Theme.of(context).textTheme.titleLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

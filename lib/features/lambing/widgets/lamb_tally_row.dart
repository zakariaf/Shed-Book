// lib/features/lambing/widgets/lamb_tally_row.dart
//
// The screen-side row: the tally in its fixed column, the derived type cell,
// and the slab on the right.
//
// ONE PRESS IS ONE STROKE AND ONE COMMITTED LAMB ROW. There is no confirmation
// step, because the row IS the confirmation — indelible.md §9's three presses.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_tally.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/domain/birth_type.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/lambing/lambing_entry_controller.dart';
import 'package:shed_book/l10n/app_localizations.dart';

/// The tally's own column is fixed so the type cell never moves as strokes
/// land — a cell that shifted under the thumb at stroke five is a cell the
/// shepherd mis-taps at stroke six.
const double _tallyColumn = 132;

class LambTallyRow extends ConsumerWidget {
  const LambTallyRow({required this.lambingId, required this.lambs, super.key});

  final LambingId lambingId;
  final List<LambEntryRow> lambs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Row(
      children: <Widget>[
        SizedBox(
          width: _tallyColumn,
          child: ShedTally(
            key: const Key('lambing_entry.tally'),
            count: lambs.length,
            struck: struck,
            semanticLabel: l10n.lambingTallySemantics(
              count: live,
              animal: 'lamb',
              animals: 'lambs',
            ),
          ),
        ),
        Expanded(
          child: Text(
            typeLabel,
            key: const Key('lambing_entry.counted_type'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        ShedTapTarget(
          key: const Key('lambing_entry.tally.stroke'),
          semanticLabel: l10n.lambingAddLamb(animal: 'lamb'),
          minSize: t.tapHero,
          onTap: () =>
              ref.read(lambingWriteControllerProvider.notifier).addLamb(lambingId).ignore(),
          child: ExcludeSemantics(
            child: SizedBox(
              width: t.tapHero,
              height: t.tapHero,
              child: Center(
                child: Text(
                  l10n.lambingAddLamb(animal: 'lamb'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

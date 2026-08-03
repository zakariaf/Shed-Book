// lib/features/quick_entry/widgets/recents_strip.dart
//
// Six full-width ruled lines, newest first. See in_pens_strip.dart for the
// horizontal-scroll ruling that applies to both.
//
// IT WATCHES NO TICKER, and that is not an omission: the recents strip shows no
// time at all (07 §5.2). Watching the minute tick here would rebuild six rows
// every sixty seconds to change nothing.
//
// THE ASYMMETRY WITH THE PENNED STRIP IS THE DESIGN. Penned is ascending —
// longest-penned first, "the one you are standing next to" — and recents is
// descending. Rendering both newest-first feels tidier and is wrong.
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/core/ui/components/shed_animal_row.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class RecentsStrip extends ConsumerWidget {
  const RecentsStrip({required this.height, super.key});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    final AsyncValue<List<DeckEntry>> recents = ref.watch(
      quickEntryDeckProvider.select(
        (AsyncValue<QuickEntryDeck> d) => d.whenData((QuickEntryDeck v) => v.recents),
      ),
    );

    return SizedBox(
      key: const Key('quick_entry.recents_strip'),
      height: height,
      width: double.infinity,
      child: switch (recents) {
        AsyncData<List<DeckEntry>>(value: final List<DeckEntry> rows) when rows.isEmpty => _Empty(
          text: l10n.quickEntryRecentsEmpty,
        ),
        AsyncData<List<DeckEntry>>(value: final List<DeckEntry> rows) => ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            for (final DeckEntry e in rows)
              ShedAnimalRow(
                key: Key('quick_entry.recent.${e.eweId.value}'),
                tag: e.tag,
                summary: '',
                semanticLabel: l10n.quickEntryRecentRowLabel(tag: e.tag),
                onTap: () {},
              ),
          ],
        ),
        AsyncError<List<DeckEntry>>() => _Empty(text: l10n.quickEntryDeckUnavailable),
        _ => const SizedBox.expand(),
      },
    );
  }
}

/// **NOT `ShedEmptyState`, AND THAT WAS TRIED.** The shared component is
/// `double.infinity` in both axes so it takes the maximum of LOOSE constraints —
/// which is its whole no-jump point, and which requires a BOUNDED parent. A
/// strip sizes to its content, so swapping it in overflowed six overflow-matrix
/// cells at textScaler 2.0, on every device.
///
/// The constraint is real and was undocumented. It is now recorded here and on
/// the component; reconciling the two shapes — an empty state that fills, and
/// one that sits in a content-sized row — is a design question rather than a
/// call-site choice.
class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: context.tokens.gapMin),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    ),
  );
}

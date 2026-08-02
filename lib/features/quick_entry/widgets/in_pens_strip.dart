// lib/features/quick_entry/widgets/in_pens_strip.dart
//
// SIX FULL-WIDTH RULED LINES, NOT A HORIZONTALLY SCROLLING STRIP, AND THAT IS A
// RULING. 07 §5.1 draws "[ IN THE PENS · 6 tiles ]" as "fixed height,
// horizontally scrolling". indelible.md §7.15 draws six full-width 64 px ruled
// lines, and CLAUDE.md's gesture ban is absolute: "swipe-to-delete and every
// swipe action, DRAG AND DRAG HANDLES, long-press bindings, hold-to-repeat,
// pinch, force touch, sliders."
//
// A horizontally scrolling strip is operated by a lateral drag on a 64 pt-tall
// element — the gesture the ban names — and there is NO GATE ROW THAT CATCHES
// IT: a horizontal scroll direction is not a banned identifier. So it would have
// shipped silently.
//
// Both buckets are already LIMIT 6 in SQL (T03), so there is nothing to scroll
// TO: the horizontal scroll in 07 §5.1 was affordance for a list that cannot
// exceed six rows. 07 §5.1 is amended in the same commit.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/core/time/ticker.dart';
import 'package:shed_book/core/ui/components/shed_animal_row.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/domain/penning.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class InPensStrip extends ConsumerWidget {
  const InPensStrip({required this.height, super.key});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ShedTokens t = context.tokens;

    // THE ONLY WATCH IS `.penned`. `.select` is what stops a recents change
    // rebuilding this strip — and it only works because FlockRepository._toDeck
    // hands back the SAME list instance when the bucket did not change
    // (02 §4.4: a stored List still has identity ==).
    final AsyncValue<List<DeckEntry>> penned = ref.watch(
      quickEntryDeckProvider.select(
        (AsyncValue<QuickEntryDeck> d) => d.whenData((QuickEntryDeck v) => v.penned),
      ),
    );

    // ONE TICKER, and it is minuteTickProvider (R25, decision #66). The hours
    // figure is the only thing on this screen that changes without a tap.
    final Instant now = switch (ref.watch(minuteTickProvider)) {
      AsyncData<Instant>(value: final Instant i) => i,
      _ => Instant(0),
    };

    return SizedBox(
      key: const Key('quick_entry.penned_strip'),
      height: height,
      width: double.infinity,
      child: switch (penned) {
        AsyncData<List<DeckEntry>>(value: final List<DeckEntry> rows) when rows.isEmpty => _Empty(
          text: l10n.quickEntryPennedEmpty,
        ),
        AsyncData<List<DeckEntry>>(value: final List<DeckEntry> rows) => ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[for (final DeckEntry e in rows) _row(context, l10n, t, e, now)],
        ),
        AsyncError<List<DeckEntry>>() => _Empty(text: l10n.quickEntryDeckUnavailable),
        _ => const SizedBox.expand(),
      },
    );
  }

  Widget _row(BuildContext context, AppLocalizations l10n, ShedTokens t, DeckEntry e, Instant now) {
    // ELAPSED PHYSICAL TIME, from epoch millis, never two subtracted wall
    // clocks. 03 §8 rule 1's worked example: a ewe penned at 22:00 before UK
    // spring-forward and seen at 08:00 has been penned 9 hours, not the 10 the
    // clock suggests. `now` is a parameter, always (R24).
    final int hours = timeSincePenned(e.sortAt, now).inHours;

    return ShedAnimalRow(
      // The key qualifier is the ewe ID, not the tag and not the index. A tag is
      // "exactly as typed" and may contain letters or leading zeros, which
      // breaks the all-lower_snake key format (R59); an index reorders every
      // minute, and a key is a test contract.
      key: Key('quick_entry.penned.${e.eweId.value}'),
      tag: e.tag,
      summary: e.penLabel ?? '',
      trailing: Text(
        l10n.quickEntryHoursPenned(hours: hours),
        style: Theme.of(context).textTheme.labelMedium,
      ),
      semanticLabel: l10n.quickEntryPennedRowLabel(tag: e.tag, pen: e.penLabel ?? '', hours: hours),
      onTap: () {},
    );
  }
}

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

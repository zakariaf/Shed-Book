// lib/features/quick_entry/widgets/tag_sheet_body.dart
//
// **ITS OWN FILE, AND THAT IS A STRUCTURAL REQUIREMENT RATHER THAN TIDINESS.**
//
// `quick_entry_test.dart` asserts that `quick_entry_screen.dart` contains no
// `ref.watch` at all — *"a StatelessWidget that watches nothing cannot be
// rebuilt by a keystroke or by an emission"* (`02 §10.1`), which is what makes
// every box on that screen immovable under a thumb. The assertion is over the
// whole file, so a sheet body living in it reddens the anchor even though a
// widget in a modal route cannot move the page's boxes at all.
//
// Rather than narrow the assertion to make a build pass, the widget moved. The
// test still says exactly what it said, and the file it guards contains exactly
// what it is about.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/write_action.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/penning.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/tag_match.dart';
import 'package:shed_book/features/quick_entry/quick_entry_controller.dart';
import 'package:shed_book/features/quick_entry/quick_entry_write_controller.dart';
import 'package:shed_book/features/quick_entry/widgets/tag_sheet.dart';
import 'package:shed_book/features/quick_entry/widgets/tonight_rows.dart';
import 'package:shed_book/l10n/app_localizations.dart';

/// The tag sheet's live contents.
///
/// **A `ConsumerWidget` INSIDE THE SHEET, NOT A SNAPSHOT PASSED INTO IT.** The
/// sheet is pushed onto the navigator with its own element tree, so a list
/// captured at push time would freeze at the digits typed before it opened — the
/// keypad would fill the display line and the matches below would never re-rank.
///
/// It replaces `_ConfirmBar`, which was the whole selection surface: a single bar
/// reading `Use 412` / `Create 412` with no list above it to give it context. The
/// owner's question on first use — *"what was that, set 412, use 412, what is
/// that?"* — is what a confirm with nothing to confirm against reads like.
class TagSheetBody extends ConsumerWidget {
  const TagSheetBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final QuickEntryState state = ref.watch(quickEntryControllerProvider);

    // **THE SIX RECENTS WHEN NOTHING IS TYPED, THE MATCHES WHEN SOMETHING IS.**
    // `§8`: the recents print first and *"one press of a recent line is the whole
    // selection. That is the common case and it costs one tap."* The list built
    // before P16 had neither — it had no list.
    //
    // **IT READS THE DECK, NOT THE TAG INDEX**, and that is what puts a summary
    // on the row. The index carries a tag and its ranking digits; the deck
    // carries the pen. §8's rows are `412 · penned 2h · pen 4` precisely because
    // a bare column of numbers is a list you read rather than recognise — and
    // reading three digits under a head torch is the thing this whole design is
    // arranged to avoid.
    //
    // It is also where the deck's two buckets went. They were built as permanent
    // 96 pt strips on the page; §8 puts them here, and P16's arithmetic only
    // works because they moved.
    final AsyncValue<QuickEntryDeck> deckAsync = ref.watch(quickEntryDeckProvider);
    final QuickEntryDeck? deck = deckAsync.value;

    final Instant now = appNow();

    void choose(EweId ewe) {
      ref.read(quickEntryControllerProvider.notifier).select(ewe);
      // **THE SHEET DROPS WHEN THE TAG LANDS** (`§8`). Leaving it up is what the
      // app did for its whole life so far, and it is why the page was a sliver.
      Navigator.of(context).pop();
    }

    // Penned first, then recents, deduplicated — a ewe who is both is one row.
    final List<DeckEntry> listed = state.query.isEmpty
        ? <DeckEntry>[
            ...?deck?.penned,
            ...?deck?.recents.where(
              (DeckEntry r) => deck.penned.every((DeckEntry p) => p.eweId != r.eweId),
            ),
          ].take(_kRecentsShown).toList()
        : const <DeckEntry>[];

    final List<ShedTagMatch> rows = state.query.isEmpty
        ? <ShedTagMatch>[
            for (final DeckEntry e in listed)
              (
                id: '${e.eweId.value}',
                tag: e.tag,
                // **`412 · penned 2h · pen 4`, WHICH IS §8'S OWN ROW.** The pen
                // AND the hours, because two similar tags in two pens are told
                // apart by where they are and how long they have been there.
                //
                // The hours come from `timeSincePenned` — ELAPSED PHYSICAL time,
                // never two subtracted wall clocks (`03 §8` rule 1). A ewe penned
                // at 22:00 before UK spring-forward and seen at 08:00 has been
                // penned nine hours, not ten, and this is the one screen where
                // that figure decides whether somebody walks out to her.
                summary: e.penLabel == null
                    ? l10n.quickEntryTagSheetSeenRecently
                    : '${l10n.quickEntryTagSheetInPen(pen: e.penLabel!)} · '
                          '${l10n.quickEntryHoursPenned(hours: timeSincePenned(e.sortAt, now).inHours)}',
                semanticLabel: e.penLabel == null
                    ? l10n.quickEntryRecentRowLabel(tag: e.tag)
                    : l10n.quickEntryPennedRowLabel(
                        tag: e.tag,
                        pen: e.penLabel!,
                        hours: timeSincePenned(e.sortAt, now).inHours,
                      ),
                onTap: () => choose(e.eweId),
              ),
          ]
        : <ShedTagMatch>[
            for (final TagIndexEntry e in state.matches)
              (
                id: '${e.eweId.value}',
                tag: e.tag,
                // **NEVER A HISTORY IT HAS NOT READ.** A typed match comes off
                // the in-memory tag index, which carries the tag and its ranking
                // digits and nothing else. Printing "lambed yesterday · twins"
                // here would be the app originating a fact — and §12.2's
                // origination line does not bend for a summary.
                summary: '',
                semanticLabel: l10n.quickEntryRecentRowLabel(tag: e.tag),
                onTap: () => choose(e.eweId),
              ),
          ];

    // **NULL IS NOT EMPTY, AND COLLAPSING THEM IS THE DAY-ONE BUG.** Frame 1
    // has not read the database; an empty list means it was read and there is
    // nothing in it. `ShedRecentsStrip` held this distinction and the strip is
    // gone, so the property moves here rather than lapsing with it.
    // **THREE STATES, NOT TWO.** Frame 1 has not read the database; an empty list
    // means it WAS read and there is nothing in it; and a stream carrying a
    // failure is neither. Collapsing the first two tells a shepherd on their
    // first night that the app lost their flock; collapsing the third tells them
    // their flock is empty when it is not.
    final String? emptyNote = rows.isNotEmpty || state.query.isNotEmpty
        ? null
        : deckAsync.hasError
        ? l10n.quickEntryDeckUnavailable
        : deck == null
        ? l10n.quickEntryTagSheetReading
        : l10n.quickEntryTagSheetNoAnimals;

    return TagSheet(
      emptyNote: emptyNote,
      heading: state.query.isEmpty
          ? '${l10n.quickEntryTagSheetHeading(count: rows.length)} · ${l10n.quickEntryTagSheetPennedFirst}'
          : l10n.quickEntryTagSheetHeading(count: rows.length),
      query: state.query,
      rowHeight: kRecordRowHeight,
      marginWidth: kMarginWidth,
      matches: rows,
      createLabel: state.query.isEmpty
          ? l10n.quickEntryTagSheetCreateEmpty
          : l10n.quickEntryTagSheetCreate(tag: state.query),
      onCreate: () async {
        if (state.query.isEmpty) {
          return;
        }
        // An exact match is a selection, not a create. Pressing the create line
        // for a tag that already exists must not write a second ewe with the same
        // number — the shepherd holding 412 means *this* 412.
        final TagIndexEntry? exact = state.matches
            .where((TagIndexEntry e) => e.tag == state.query)
            .firstOrNull;
        if (exact != null) {
          choose(exact.eweId);
          return;
        }
        await ref.read(quickEntryWriteControllerProvider.notifier).createEwe(state.query);
        if (!context.mounted) {
          return;
        }
        // **CREATING SELECTS HER, AND WITHOUT THAT LINE THE NEXT TAP DOES
        // NOTHING.** Measured 2026-08-05: type 412, create, then the event
        // button read `selected` and found null. No exception, no message,
        // nothing on screen.
        if (ref.read(quickEntryWriteControllerProvider) case WriteDone(
          outcome: WriteCommitted(insertedId: final int id?),
        )) {
          choose(EweId(id));
        }
      },
      onDigit: (String d) => ref.read(quickEntryControllerProvider.notifier).appendDigit(d),
      onBackspace: () => ref.read(quickEntryControllerProvider.notifier).backspace(),
      onNewTag: () => ref.read(quickEntryControllerProvider.notifier).clearSelection(),
      padLabel: l10n.keypadTagEntry,
      backspaceLabel: l10n.keypadBackspace,
      backspaceHint: l10n.hintDeleteLastDigit,
      newTagLabel: l10n.keypadNewTag,
    );
  }
}

/// `§8` prints six recents in the sheet. Six, because that is what fits above the
/// keypad on the reference viewport and because a longer list is a list you read
/// instead of recognise.
const int _kRecentsShown = 6;

// lib/features/quick_entry/quick_entry_screen.dart
//
// A StatelessWidget, NOT a ConsumerWidget. It watches nothing, so it cannot be
// rebuilt by anything — which is the strongest available proof that a digit
// cannot reach the keypad (02 §10.1). The moment someone makes it a
// ConsumerWidget to "just watch one thing here", every child below loses its
// const-ness.
//
// EVERY BOX IS RESERVED AT ITS FINAL SIZE ON FRAME 1. That is decision #21's
// whole promise and it is what the anchor test pins: frame 1 with no data
// occupies the same rects as frame 2 with six penned and six recent entries.
// Nothing moves under a thumb — a 3 pt shift is enough to mis-target a 64 pt
// key, and the thumb is already committed by the time the data arrives.
//
// ---------------------------------------------------------------------------
// THE KEYPAD AND THE CONFIRM BAR ARE IN THE SHEET, AND THAT IS A RULING
// ---------------------------------------------------------------------------
//
// MEASURED, and it is arithmetic rather than taste. N13-T05 §5.2's band table
// makes all of these always-on: header 44 + live row 128 + two 96 strips +
// keypad ~336 + confirm 88 + band 152 + 34 safe-area inset = 974 pt. The
// reference viewport is 852 and Device.small is 667. The record column is
// Expanded and can flex to zero, and the page STILL overflows by 122 before a
// single record is drawn. The table over-commits the viewport.
//
// Three sources disagree and the ruling reconciles them rather than picking one:
//
//   * decision #21 — frame 1 is interactive, with a usable keypad;
//   * indelible.md §7.2 and §8 — the keypad lives in the bottom sheet that opens
//     when you enter a tag, which is what makes the arithmetic work;
//   * N13-T05 §5.4 — `quick_entry.keypad` is one of the boxes the anchor pins.
//
// RULED: the keypad and the confirm bar move into the entry sheet, AND THE SHEET
// IS OPEN ON FRAME 1. Decision #21's promise is honoured exactly — the shepherd
// sees a usable keypad on the first painted frame — and §5.4's box is still
// findable and still pinned, because an open sheet is on screen. The page's own
// chrome comes to 550 pt, which fits 667 with room for records.
//
// The sheet is a Stack layer anchored to the bottom rather than a child of the
// column: it OVERLAYS the bottom band the way indelible §8 draws it, and a sheet
// that pushed the band would move the slab, which is the one target the shepherd
// aims at without looking.
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_keypad.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/features/quick_entry/widgets/quick_entry_bottom_band.dart';
import 'package:shed_book/features/quick_entry/widgets/quick_entry_margin_cell.dart';
import 'package:shed_book/features/quick_entry/widgets/quick_entry_page_header.dart';
import 'package:shed_book/features/quick_entry/widgets/quick_entry_spine.dart';
import 'package:shed_book/l10n/app_localizations.dart';

/// The reference geometry, from `indelible.md` §4.3–§4.4 at the 393 × 852
/// viewport. Named rather than typed inline: `token.magic_size` is right to fire
/// on a bare number, and these are layout constants this screen owns — they are
/// not palette values, so they are not on `ShedTokens`.
class _Grid {
  static const double headerHeight = 44;
  static const double marginWidth = 68;
  static const double rowHeight = 64;
  static const double liveRowHeight = 128;
  static const double bandHeight = 152;
  static const double indexWidth = 96;
  static const double indexHeight = 64;
  static const double slabWidth = 160;
  static const double slabHeight = 140;
  static const double stripHeight = 96;
}

class QuickEntryScreen extends StatelessWidget {
  const QuickEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: t.surfaceBase,
      body: Stack(
        children: <Widget>[
          // THE SPINE IS THE BOTTOM LAYER, painted behind everything. A spine
          // assembled per row is a spine with seams, and the seams show under a
          // head torch at the moment the shepherd is scrolling.
          const QuickEntrySpine(left: _Grid.marginWidth),

          Column(
            children: <Widget>[
              QuickEntryPageHeader(
                // The night and page are the record column's, and the column is
                // T06's. Until then the header renders its own shape at its own
                // height, which is what the anchor pins.
                text: l10n.quickEntryPageHeader(night: '', page: 1),
                height: _Grid.headerHeight,
              ),

              // The record column takes the remainder, and the remainder is what
              // gives. That is the design's own answer rather than an invention:
              // 06 §8.2 says of the keypad growing that "the match list above it
              // gives up rows". Same trade, one level up — the chrome the thumb
              // aims at is fixed, the reading surface flexes.
              //
              // Its rows share edges — 64 pt, no gaps — because a ruled page has
              // no gutters.
              Expanded(
                child: ClipRect(
                  child: SingleChildScrollView(
                    key: const Key('quick_entry.record_column'),
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < 12; i++)
                          const SizedBox(height: _Grid.rowHeight, child: SizedBox.expand()),
                      ],
                    ),
                  ),
                ),
              ),

              // The deck's two strips. T06 fills them; the sizes are final now,
              // which is what makes frame 1 and frame 2 identical.
              const SizedBox(
                key: Key('quick_entry.penned_strip'),
                height: _Grid.stripHeight,
                width: double.infinity,
              ),
              const SizedBox(
                key: Key('quick_entry.recents_strip'),
                height: _Grid.stripHeight,
                width: double.infinity,
              ),

              // THE LIVE ROW IS A FIXED LAYER, NOT A SCROLLING CHILD, and this
              // task owns that correction. indelible.html:1138 puts it inside the
              // scrolling stream, so the open row scrolls away — the audit
              // block's Indelible artefact defect 1. The corrected rule is that
              // it is welded above the bottom band, and the reason is the
              // mechanism §8 describes: "you can see it, in ink, one line above."
              // A row you have to scroll to find is not a receipt.
              SizedBox(
                key: const Key('quick_entry.live_row'),
                height: _Grid.liveRowHeight,
                child: Row(
                  children: <Widget>[
                    QuickEntryMarginCell(
                      time: '',
                      stampAuto: l10n.quickEntryStampAuto,
                      width: _Grid.marginWidth,
                      height: _Grid.rowHeight,
                    ),
                    const Expanded(child: SizedBox.expand()),
                  ],
                ),
              ),

              QuickEntryBottomBand(
                indexLabel: l10n.quickEntryIndex,
                slabLabel: l10n.quickEntrySlabTagFirst,
                onIndex: () {},
                onSlab: () {},
                bandHeight: _Grid.bandHeight,
                indexWidth: _Grid.indexWidth,
                indexHeight: _Grid.indexHeight,
                slabWidth: _Grid.slabWidth,
                slabHeight: _Grid.slabHeight,
              ),
            ],
          ),

          // THE ENTRY SHEET, OPEN ON FRAME 1. See the ruling in this file's
          // header. It overlays the band rather than pushing it, because a sheet
          // that moved the slab would move the one target the shepherd aims at
          // without looking.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ColoredBox(
              color: t.surfaceRaised,
              child: Column(
                key: const Key('quick_entry.entry_sheet'),
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // FRAME 1 IS INTERACTIVE, and that is decision #21's promise:
                  // the keypad is fully usable before the database has opened,
                  // because it watches nothing and needs nothing.
                  ShedKeypad(
                    onDigit: (String _) {},
                    onBackspace: () {},
                    thirdKey: ShedKeypadThirdKey.newTag,
                    onThirdKey: () {},
                    padLabel: l10n.keypadTagEntry,
                    backspaceLabel: l10n.keypadBackspace,
                    backspaceHint: l10n.hintDeleteLastDigit,
                    thirdKeyLabel: l10n.keypadNewTag,
                  ),
                  SizedBox(
                    key: const Key('quick_entry.confirm'),
                    height: t.tapHero,
                    width: double.infinity,
                  ),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

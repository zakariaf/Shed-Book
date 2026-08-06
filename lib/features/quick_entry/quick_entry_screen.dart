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
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_corner_slab.dart';
import 'package:shed_book/core/ui/components/shed_keypad.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/failure.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/ui/feedback.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/core/write_action.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/tag_match.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/validation/warning.dart';
import 'package:shed_book/features/quick_entry/quick_entry_controller.dart';
import 'package:shed_book/features/quick_entry/quick_entry_write_controller.dart';
import 'package:shed_book/features/quick_entry/widgets/in_pens_strip.dart';
import 'package:shed_book/features/quick_entry/widgets/quick_entry_bottom_band.dart';
import 'package:shed_book/features/quick_entry/widgets/quick_entry_margin_cell.dart';
import 'package:shed_book/features/quick_entry/widgets/quick_entry_page_header.dart';
import 'package:shed_book/features/quick_entry/widgets/quick_entry_spine.dart';
import 'package:shed_book/core/ui/components/shed_bottom_sheet.dart';
import 'package:shed_book/features/quick_entry/widgets/export_banner.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/features/quick_entry/widgets/index_sheet.dart';
import 'package:shed_book/features/quick_entry/widgets/tonight_rows.dart';
import 'package:shed_book/routing/routes.dart';
import 'package:shed_book/features/quick_entry/widgets/recents_strip.dart';
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
  // **READ OFF THE COMPONENT, NOT COPIED.** N26-T04 needed the same slab on the
  // Flock screen, and `indelible.md §7.1`'s 160 × 140 written in two files is a
  // contract that will disagree with itself the first time one of them moves.
  static const double slabWidth = ShedCornerSlab.width;
  static const double slabHeight = ShedCornerSlab.height;
  static const double stripHeight = 96;
}

class QuickEntryScreen extends StatelessWidget {
  const QuickEntryScreen({super.key});

  @override
  Widget build(BuildContext context) => ShedReceiptScope(
    // INSTALLED HERE, ABOVE the page, and the reason is mechanical: `ref.listen`
    // is registered in _QuickEntryPage.build, so its BuildContext is that
    // widget's — which is ABOVE anything _QuickEntryPage returns. A scope
    // installed inside the page is a scope the publisher cannot see, and
    // confirmSaved would silently publish to nothing.
    notifier: _receipts,
    child: const _QuickEntryPage(),
  );

  /// One notifier for the screen. A receipt is a fact about the last committed
  /// row rather than about a widget's lifecycle, so it outlives a rebuild.
  static final ValueNotifier<SaveReceipt?> _receipts = ValueNotifier<SaveReceipt?>(null);
}

/// The page proper.
///
/// **A ConsumerWidget, and [QuickEntryScreen] deliberately is not.** The shell's
/// immovable-boxes property rests on the screen watching nothing (`02 §10.1`),
/// and that assertion is source text over `QuickEntryScreen`. The write path
/// needs one `ref.listen`, so it lives one widget down — where a rebuild moves
/// nothing, because this widget's children are the same fixed boxes.
class _QuickEntryPage extends ConsumerWidget {
  const _QuickEntryPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);

    // THE ONE LISTEN, AND THE ONLY PLACE FEEDBACK HAPPENS (02 §7). The switch is
    // EXHAUSTIVE with no `default:` — WriteOutcome is sealed with three
    // variants, and the day a fourth appears this must fail to compile rather
    // than swallow it.
    ref.listen<WriteState>(quickEntryWriteControllerProvider, (
      WriteState? previous,
      WriteState next,
    ) {
      if (next case WriteDone(:final WriteOutcome outcome)) {
        switch (outcome) {
          case WriteCommitted(:final List<Warning> warnings, :final int? insertedId):
            // The confirmation IS the committed row, in ink, one line above the
            // one being written. Three channels: the haptic, the receipt
            // published to the scope, and the row itself — which the drift
            // stream has already re-emitted and is the only one of the three
            // still true five seconds later.
            // `undoLabel` IS SET EXPLICITLY rather than letting the 'UNDO'
            // default through. 07 §15.3 reserves "Undo" for where the record
            // DISAPPEARS, and after P1 it never does — the row stays in
            // position, legible, permanently marked. The word is STRIKE.
            final int? id = insertedId;
            confirmSaved(
              context,
              SaveReceipt(
                term: l10n.quickEntryLambing,
                tag: '',
                summary: l10n.quickEntryStrikeWindow(seconds: kStrikeWindow.inSeconds),
                at: formatShedTime(appNow(), 'en_GB'),
                expiresAt: appNow().plus(kStrikeWindow),
                undoLabel: l10n.quickEntryStrike,
                undo: id == null
                    ? null
                    : () => ref
                          .read(quickEntryWriteControllerProvider.notifier)
                          .strike(LambingId(id))
                          .ignore(),
              ),
              warnings,
            );
          case WriteFailed(:final ShedFailure failure):
            // `.userMessage` is read HERE rather than inside showFailure,
            // because lib/core/ui/ may not import lib/core/ — see that
            // function's doc comment for why the printed signature is wrong.
            showFailure(context, failure.userMessage);
          case WriteRefused(:final RefusalReason reason):
            // Both guards live inside showCapRow rather than here: a guard at a
            // call site is a guard somebody forgets at the thirteenth call site.
            showCapRow(
              context,
              reason,
              onShedScreen: true,
              now: appNow(),
              // Unreachable by construction on this screen — the guard returns
              // before the copy is asked for — and supplied rather than
              // faked, because a `throw` here would be a landmine in the one
              // file that must never surprise anybody at 03:20.
              copyFor: (RefusalReason r) => '',
            );
          // UNREACHABLE ON THIS SCREEN, and the arm exists to prove it stays
          // that way. createEwe passes EntryContext.liveEntry, and
          // FreeTierPolicy.decide cannot reach a BlockedByCap on that arm
          // (decision #91).
        }
      }
    });

    return Scaffold(
      backgroundColor: t.surfaceBase,
      // **THE ONE SCREEN WITHOUT A `SafeArea`, AND IT IS THE SCREEN THE WHOLE
      // PRODUCT IS.** Seen on a simulator on 2026-08-05: the page header drew
      // UNDER the status bar and behind the Dynamic Island — `NIGHT OF · P`
      // and then nothing, with the clock printed through it. Every other screen
      // in `lib/features/` already had one.
      //
      // **NO TEST COULD SEE IT.** `pumpApp` passes
      // `EdgeInsets.only(top: 47, bottom: 34)` as a MediaQuery inset, which is
      // exactly right — and a widget that ignores the inset lays out and
      // measures perfectly inside it. The overflow matrix asks *did anything
      // overflow*, the geometric sweep asks *is anything too small or too
      // close*; neither asks *is anything underneath the notch*, because that
      // is not a property of the layout, it is a property of the layout's
      // relationship to a cut-out the test view does not draw.
      //
      // `indelible.md §4.3`'s 393 × 852 grid is the SAFE viewport, and `§4.4`'s
      // 44 px sticky header is measured from the top of it.
      body: SafeArea(
        child: Stack(
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

                // THE BANNER'S SLOT, above the record column and below the page
                // header (`07 §16.2`). It renders here and nowhere else.
                //
                // **IT IS OUTSIDE THE `Expanded` BELOW**, which is the shrink
                // order made structural: the record column is what gives when the
                // banner takes height, and the keypad, the confirm bar and the two
                // strips never shrink. `06 §8.2` sets that trade one level down —
                // *"the match list above it gives up rows"* — and this is the same
                // trade one level up.
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
                          // THE BANNER'S SLOT: the top of the record column, which
                          // is the reading surface above the tag readout
                          // (`07 §16.2`) — and, structurally, the one part of this
                          // screen that already scrolls.
                          //
                          // **INSIDE THE SCROLL VIEW AND NOT ABOVE IT**, and that
                          // is measured rather than preferred. Placed above the
                          // record column it takes height from a `Column` whose
                          // other children are fixed, and at textScaler 2.0 on a
                          // 375 × 667 device it overflowed by **665 pixels** —
                          // there is no shrink order that survives that, because
                          // the keypad, the confirm bar and the recents strip may
                          // never give. Inside, it cannot take height from the
                          // chrome at all: the banner scrolls, and the thumb
                          // targets stay exactly where they were.
                          const ExportBanner(),

                          // **TONIGHT'S PAGE, WHICH WAS TWELVE EMPTY BOXES.**
                          // `for (int i = 0; i < 12; i++) SizedBox(...)` stood
                          // here — so the design's central promise, *the
                          // confirmation IS the committed row, in ink, one line
                          // above the one being written*, had no row to be, and
                          // the screen read as a keypad on a black page.
                          //
                          // Reported from a simulator on 2026-08-06: a lambing
                          // was recorded, the shepherd went back, typed the tag
                          // again, and the page was empty.
                          TonightRows(
                            locale: context.localeName,
                            l10n: l10n,
                            // Tapping a row opens what it is a record OF. The
                            // row is the receipt and the way back into it.
                            onOpen: (TonightRow row) =>
                                unawaited(Routes.lambingEntry(context, row.lambing)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // The deck's two strips. T06 fills them; the sizes are final now,
                // which is what makes frame 1 and frame 2 identical.
                //
                // **THE IN-PENS STRIP IS THE SECOND THING THAT GIVES**, and only
                // when the export banner is up. `07 §16.2` fixes the shrink order
                // — the filtered-match list loses a row, then this strip — and the
                // keypad, the confirm bar and the recents strip never shrink.
                //
                // The `Flexible` stays from N21-T08's first attempt even though the
                // banner no longer needs it: the record column reaches zero on a
                // 375 × 667 device before anything is added, so a strip that
                // cannot give is a strip that overflows the day anything else
                // does. It costs nothing while nothing needs it.
                const Flexible(child: InPensStrip(height: _Grid.stripHeight)),
                const RecentsStrip(height: _Grid.stripHeight),

                QuickEntryBottomBand(
                  indexLabel: l10n.quickEntryIndex,
                  slabLabel: l10n.quickEntrySlabTagFirst,
                  // **THIS WAS `() {}` AND IT MADE THE APP A SINGLE SCREEN.**
                  // Flock, the pens, the medicine book, Export and Settings
                  // were all built, all tested, all in the matrix — and
                  // unreachable. `indelible.md §7.17`: `INDEX` opens the index.
                  onIndex: () => _openIndex(context, l10n),
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
                    // THE LIVE ROW LIVES AT THE TOP OF THE SHEET, AND THAT IS A CORRECTION
                    // MEASURED AT N14-T05. As a sibling of the bottom band it was
                    // COVERED by the sheet — the hit test landed on the sheet's own
                    // background, which means the shepherd could neither see the
                    // receipt nor press the strike word. indelible §8's whole claim
                    // is "you can see it, in ink, one line above the one being
                    // written", and a row under an opaque sheet is not one line
                    // above anything.
                    //
                    // It is still a FIXED LAYER, NOT A SCROLLING CHILD, and this
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
                          // THE RECEIPT LIVES IN THE ROW, NOT IN AN OVERLAY. It reads
                          // the scope rather than watching a provider, because a
                          // feedback function has a BuildContext and no WidgetRef.
                          Expanded(
                            child: ValueListenableBuilder<SaveReceipt?>(
                              valueListenable: ShedReceiptScope.of(context),
                              builder: (BuildContext context, SaveReceipt? receipt, Widget? _) =>
                                  receipt == null
                                  ? const SizedBox.expand()
                                  : _StrikeAffordance(receipt: receipt),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // FRAME 1 IS INTERACTIVE, and that is decision #21's promise:
                    // the keypad is fully usable before the database has opened,
                    // because it watches nothing and needs nothing.
                    ShedKeypad(
                      // WIRED HERE, and it was a stub until N14-T06 found it. The
                      // budget test is what noticed: with a no-op onDigit the query
                      // never fills, so the confirm bar renders nothing and tap 4
                      // lands on empty space. A screen test that only asserted
                      // "the keypad is present" would never have caught it.
                      onDigit: (String d) =>
                          ref.read(quickEntryControllerProvider.notifier).appendDigit(d),
                      onBackspace: () =>
                          ref.read(quickEntryControllerProvider.notifier).backspace(),
                      thirdKey: ShedKeypadThirdKey.newTag,
                      // The third key clears the selection and starts a fresh tag:
                      // "new tag" at 03:20 means the animal in front of you is not
                      // the one on screen.
                      onThirdKey: () =>
                          ref.read(quickEntryControllerProvider.notifier).clearSelection(),
                      padLabel: l10n.keypadTagEntry,
                      backspaceLabel: l10n.keypadBackspace,
                      backspaceHint: l10n.hintDeleteLastDigit,
                      thirdKeyLabel: l10n.keypadNewTag,
                    ),
                    // THE LAMBING EVENT BUTTON, in the confirm slot the shell
                    // reserved. It is the product's central write: the tap commits
                    // the row BEFORE any screen is pushed, which is why the label
                    // names the event rather than an intention.
                    //
                    // N16 pushes LambingEntryScreen from the outcome's id. There
                    // is no route helper for a screen that does not exist yet.
                    // THE CONFIRM BAR AND THE EVENT BUTTON ARE TWO CONTROLS, and
                    // T06's budget is what says so: tap 4 confirms WHICH animal,
                    // tap 5 commits WHAT happened. Merging them would read as four
                    // taps and would mean the shepherd cannot see which ewe they
                    // are about to file a lambing against before they file it.
                    //
                    // Labelled with the OUTCOME — "Use 412" / "Create 412" — never
                    // a bare tick (06 §8.2): at 03:20 a tick asks the shepherd to
                    // remember what they were confirming.
                    SizedBox(
                      key: const Key('quick_entry.confirm'),
                      height: t.tapHero,
                      width: double.infinity,
                      child: _ConfirmBar(),
                    ),

                    // **`INDEX` AND THE EVENT VERB SHARE ONE ROW, AND THE
                    // SHARING IS THE FIX RATHER THAN THE ARRANGEMENT.**
                    //
                    // `indelible.md §7.17` pins `INDEX` bottom-left of the BAND
                    // — and the band is 152 px sitting under an opaque sheet
                    // that is open on frame 1, so both thumb anchors were
                    // painted over on every frame this app has ever drawn.
                    // Measured on a simulator: from Quick Entry a shepherd
                    // could reach Flock, the pens, the medicine book, Export
                    // and Settings — not one of them.
                    //
                    // **TWO FIXES WERE TRIED AND BOTH COST THE HEADER.** Moving
                    // the sheet up by the band's height put its top over the
                    // page header; giving `INDEX` its own 64 px row did the
                    // same thing 64 px later. The sheet is already within a row
                    // of the viewport on a 375 × 667 device — 64 live row + 336
                    // keypad + 88 confirm + 88 event — so it has no spare
                    // height to give, and the band's geometry is `07 §16`'s
                    // rather than this session's to re-cut.
                    //
                    // Sharing the event verb's row costs nothing: `INDEX` is
                    // 96 × 64 in §7.17 and the row is `tapHero` 88, so both
                    // clear their floors, `INDEX` is bottom-LEFT as the design
                    // says, and the event verb keeps the width its label needs.
                    SizedBox(
                      key: const Key('quick_entry.event'),
                      height: t.tapHero,
                      width: double.infinity,
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            key: const Key('quick_entry.index'),
                            width: _Grid.indexWidth,
                            child: ShedTapTarget(
                              key: const Key('quick_entry.index.open'),
                              semanticLabel: l10n.quickEntryIndex,
                              minSize: t.tapIndelible,
                              onTap: () => _openIndex(context, l10n),
                              child: ExcludeSemantics(
                                child: Center(
                                  child: Text(
                                    l10n.quickEntryIndex,
                                    style: Theme.of(context).textTheme.labelLarge,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ShedTapTarget(
                              key: const Key('quick_entry.event.lambing'),
                              semanticLabel: l10n.quickEntryLambing,
                              minSize: t.tapHero,
                              // **THE ROW COMMITS, THEN THE SCREEN OPENS — AND
                              // THE OPENING WAS MISSING ENTIRELY.**
                              //
                              // `CLAUDE.md`: *Quick Entry's "Lambing" tap calls
                              // `beginLambing(ewe)` **before** Lambing Entry is
                              // pushed.* The commit was there and the push was
                              // not, so on a simulator the tap wrote a lambing,
                              // published its receipt — *20 seconds to strike* —
                              // and left the shepherd on Quick Entry with no
                              // sign anything had opened. The ewe card has done
                              // this correctly since N27; this screen never did.
                              //
                              // **THE PUSH IS HERE AND NOT IN THE `ref.listen`
                              // ABOVE**, and that is the whole reason it needs
                              // its own await: the listener fires for EVERY
                              // committed write on this screen, `createEwe`
                              // included, so pushing from it would open Lambing
                              // Entry the moment a shepherd created a ewe. Same
                              // shape as the confirm bar's create-then-select.
                              onTap: () async {
                                final EweId? selected = ref
                                    .read(quickEntryControllerProvider)
                                    .selected;
                                if (selected == null) {
                                  return;
                                }
                                await ref
                                    .read(quickEntryWriteControllerProvider.notifier)
                                    .beginLambing(selected);

                                if (!context.mounted) {
                                  return;
                                }
                                // The id comes off the committed outcome. There
                                // is nothing else to read it from: the lambing
                                // is one row among tonight's and no stream
                                // carries *the one I just started*.
                                if (ref.read(quickEntryWriteControllerProvider) case WriteDone(
                                  outcome: WriteCommitted(insertedId: final int id?),
                                )) {
                                  await Routes.lambingEntry(context, LambingId(id));
                                }
                              },
                              child: ExcludeSemantics(
                                child: Center(
                                  child: Text(
                                    l10n.quickEntryLambing,
                                    style: Theme.of(context).textTheme.labelLarge,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.paddingOf(context).bottom),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `§7.17`'s index, from either affordance.
  ///
  /// **ONE METHOD, TWO CALL SITES**, because the band's `INDEX` and the sheet's
  /// are the same act — and two copies of a six-destination list is one that
  /// stops agreeing the first time a screen is added.
  void _openIndex(BuildContext context, AppLocalizations l10n) {
    unawaited(
      showShedBottomSheet<void>(
        context,
        dismissLabel: l10n.indexClose,
        dismissSemanticLabel: l10n.indexCloseHint,
        barrierLabel: l10n.quickEntryIndex,
        child: IndexSheet(
          lines: <IndexLine>[
            // **TONIGHT HAS NO DESTINATION**, and that is not an
            // omission: the shepherd is already on it, so the
            // line closes the sheet. `IndexSheet` supplies that.
            (id: 'tonight', label: l10n.indexTonight, onTap: null),
            (
              id: 'flock',
              label: l10n.indexFlock,
              onTap: () {
                Navigator.of(context).pop();
                unawaited(Routes.flock(context));
              },
            ),
            (
              id: 'pens',
              label: l10n.indexPens,
              onTap: () {
                Navigator.of(context).pop();
                unawaited(Routes.penBoard(context));
              },
            ),
            (
              id: 'medicine_book',
              label: l10n.indexMedicineBook,
              onTap: () {
                Navigator.of(context).pop();
                unawaited(Routes.treatments(context));
              },
            ),
            (
              id: 'export',
              label: l10n.indexExport,
              onTap: () {
                Navigator.of(context).pop();
                unawaited(Routes.export(context));
              },
            ),
            (
              id: 'settings',
              label: l10n.indexSettings,
              onTap: () {
                Navigator.of(context).pop();
                unawaited(Routes.settings(context));
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// The strike word, in the just-committed row's margin, for [kStrikeWindow].
///
/// **The window is not a Timer that outlives the screen** (`07 §15.2`). It is
/// tied to this widget and cancelled on dispose, and it is NEVER reconstructed
/// after a restart: `01 §4.5` and `07 §15.4` — there is no state restoration, no
/// undo affordance is ever rebuilt from storage, and no copy anywhere may say
/// "you can undo this later."
class _StrikeAffordance extends StatefulWidget {
  const _StrikeAffordance({required this.receipt});

  final SaveReceipt receipt;

  @override
  State<_StrikeAffordance> createState() => _StrikeAffordanceState();
}

class _StrikeAffordanceState extends State<_StrikeAffordance> {
  Timer? _window;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(_StrikeAffordance old) {
    super.didUpdateWidget(old);
    if (!identical(old.receipt, widget.receipt)) {
      _schedule();
    }
  }

  /// Schedules ONE rebuild at the deadline. **It decides nothing** — the
  /// receipt's `expiresAt` decides, so a `State` recreated after the deadline
  /// recomputes *closed* rather than re-opening the window.
  ///
  /// MEASURED: holding the window as widget state meant the affordance re-armed
  /// whenever its State was recreated. The timer fired, the word disappeared,
  /// and a rebuild brought it straight back — so a window "stated in seconds"
  /// silently lasted as long as the shepherd kept the screen open.
  void _schedule() {
    _window?.cancel();
    final Instant? expires = widget.receipt.expiresAt;
    if (expires == null) {
      return;
    }
    final int ms = expires.epochMillis - appNow().epochMillis;
    if (ms <= 0) {
      return;
    }
    _window = Timer(Duration(milliseconds: ms), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _window?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SaveReceipt r = widget.receipt;
    return Semantics(
      liveRegion: true,
      // THE LABEL DIFFERS EVERY SAVE or the live region does not re-announce —
      // it speaks only when its label CHANGES, so two identical saves in a row
      // would announce once and the second lamb would get silence.
      label: r.liveLabel,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(r.summary, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1),
          ),
          if (r.isOpenAt(appNow()))
            ShedTapTarget(
              key: const Key('quick_entry.strike'),
              semanticLabel: r.undoLabel,
              minSize: context.tokens.tapMin,
              onTap: r.undo!,
              child: ExcludeSemantics(
                child: Text(r.undoLabel, style: Theme.of(context).textTheme.labelMedium),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tap 4 of the five-tap path: **which animal**.
///
/// It reads the controller's top match and commits the selection. When the tag
/// matches no active animal it reads "Create 412" and creates one through
/// `EntryContext.liveEntry`, which is the parameter that makes a refusal
/// unreachable here (decision #91).
class _ConfirmBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final QuickEntryState state = ref.watch(quickEntryControllerProvider);

    if (state.query.isEmpty) {
      return const SizedBox.expand();
    }

    final TagIndexEntry? top = state.matches.isEmpty ? null : state.matches.first;
    final bool exact = top != null && top.tag == state.query;
    final String label = exact
        ? l10n.quickEntryConfirmUse(tag: top.tag)
        : l10n.quickEntryConfirmCreate(tag: state.query);

    return ShedTapTarget(
      semanticLabel: label,
      minSize: context.tokens.tapHero,
      // **CREATING SELECTS HER, AND WITHOUT THAT LINE THE NEXT TAP DID
      // NOTHING.** Measured 2026-08-05: type 412, `Create 412`, `Lambing` — the
      // ewe was written and no lambing was, because the event button reads
      // `quickEntryControllerProvider.selected` and a create left it null. No
      // exception, no message, nothing on screen. It is the create-on-the-fly
      // journey — *type an unknown tag, one confirm creates the ewe, straight
      // into Lambing Entry* — failing at the word *straight*.
      //
      // The id comes off the committed outcome rather than from a re-query of
      // the tag index: the index is a stream and may not have re-emitted yet,
      // and `07 §5.3` names that race by name.
      onTap: () async {
        if (exact) {
          ref.read(quickEntryControllerProvider.notifier).select(top.eweId);
          return;
        }
        await ref.read(quickEntryWriteControllerProvider.notifier).createEwe(state.query);
        if (ref.read(quickEntryWriteControllerProvider) case WriteDone(
          outcome: WriteCommitted(insertedId: final int id?),
        )) {
          ref.read(quickEntryControllerProvider.notifier).select(EweId(id));
        }
      },
      child: ExcludeSemantics(
        child: Center(child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
      ),
    );
  }
}

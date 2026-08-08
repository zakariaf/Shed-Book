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
// THE KEYPAD IS NOT ON FRAME 1 (ruling P16, owner, 2026-08-06, §7.0e)
// ---------------------------------------------------------------------------
//
// N13-T05 ruled the entry sheet OPEN on frame 1, reconciling decision #21's
// *"fully interactive keypad"* with indelible §8's sheet-on-demand by keeping
// both on screen at once. What it shipped was a keypad covering the page: on a
// 667 pt device the record column was left 125 px, one and a half rows, so the
// app's own records were a sliver behind the sheet.
//
// **#21's keypad clause is struck. Frame 1 is the page.** #21's actual subject —
// nothing awaited, no splash, no white flash, a dark frame before the database
// opens — is untouched, and the page satisfies it better than the keypad did:
// tonight's records, the five event words, the TAG cell, INDEX and the slab are
// all on frame 1 and all live, none of them waiting on data.
//
// **The arithmetic that beat N13-T05 was never the keypad — it was the strips.**
// §8 puts the six recents INSIDE the sheet as full-width ruled lines; they were
// built as two permanent 96 pt bands on the page. With them where the design puts
// them: header 44 + event line 64 + live row 128 + band 152 = 388 fixed, leaving
// 279 for records on a 667 pt device. Sheet open: 128 + 336 + 64 = 528 fixed,
// leaving 139 for matches — and the match list giving up rows first is 06 §8.2's
// documented shrink order rather than an improvisation.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_corner_slab.dart';
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
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/validation/warning.dart';
import 'package:shed_book/features/quick_entry/quick_entry_controller.dart';
import 'package:shed_book/features/quick_entry/quick_entry_write_controller.dart';
import 'package:shed_book/features/quick_entry/widgets/quick_entry_band.dart';
import 'package:shed_book/core/ui/components/shed_page_header.dart';
import 'package:shed_book/core/ui/components/shed_spine.dart';
import 'package:shed_book/core/ui/components/shed_bottom_sheet.dart';
import 'package:shed_book/features/quick_entry/widgets/export_banner.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/features/quick_entry/widgets/index_sheet.dart';
import 'package:shed_book/features/quick_entry/widgets/tonight_rows.dart';
import 'package:shed_book/features/quick_entry/widgets/event_word_line.dart';
import 'package:shed_book/features/quick_entry/widgets/live_row.dart';
import 'package:shed_book/features/quick_entry/widgets/tag_sheet_body.dart';
import 'package:shed_book/routing/routes.dart';
import 'package:shed_book/l10n/app_localizations.dart';

/// The reference geometry, from `indelible.md` §4.3–§4.4 at the 393 × 852
/// viewport. Named rather than typed inline: `token.magic_size` is right to fire
/// on a bare number, and these are layout constants this screen owns — they are
/// not palette values, so they are not on `ShedTokens`.
class _Grid {
  static const double headerHeight = 44;
  static const double marginWidth = 68;
  static const double bandHeight = 152;
  static const double indexWidth = 96;
  static const double indexHeight = 64;
  // **READ OFF THE COMPONENT, NOT COPIED.** N26-T04 needed the same slab on the
  // Flock screen, and `indelible.md §7.1`'s 160 × 140 written in two files is a
  // contract that will disagree with itself the first time one of them moves.
  static const double slabWidth = ShedCornerSlab.width;
  static const double slabHeight = ShedCornerSlab.height;
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

    // **NOT ONE `ref.watch` IN THIS METHOD, AND THAT IS THE SCREEN'S ONE
    // STRUCTURAL PROMISE.** `02 §10.1`: a widget that watches nothing cannot be
    // rebuilt by a keystroke or by an emission, and that — not any layout
    // constant — is what makes every box here immovable under a thumb.
    //
    // Everything that needs to notice something notices it for itself:
    // `TonightRows`, `LiveRow`, `ExportBanner` and the band each read their own
    // provider, and each sits in a box whose size does not depend on what it
    // read. `ref.read` inside a tap handler is not a subscription, and it is how
    // the write path gets the current selection.
    return Scaffold(
      backgroundColor: t.surfaceBase,
      // **THE ONE SCREEN WITHOUT A `SafeArea`, AND IT IS THE SCREEN THE WHOLE
      // PRODUCT IS.** Seen on a simulator on 2026-08-05: the page header drew
      // UNDER the status bar and behind the Dynamic Island. Every other screen in
      // `lib/features/` already had one, and no test could see it — `pumpApp`
      // passes the inset as a MediaQuery padding, which is exactly right, and a
      // widget that ignores an inset lays out perfectly inside it.
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // THE SPINE IS THE BOTTOM LAYER, painted behind everything. A spine
            // assembled per row is a spine with seams, and the seams show under a
            // head torch at the moment the shepherd is scrolling.
            const ShedSpine(left: _Grid.marginWidth),

            Column(
              children: <Widget>[
                ShedPageHeader(
                  // **THE NIGHT, WHICH PRINTED AS A GAP.** `NIGHT OF · PAGE 1`
                  // was on screen for weeks: the argument was `night: ''`, so the
                  // one line stating which night you are on stated nothing.
                  text: l10n.quickEntryPageHeader(
                    night: formatShedDate(LocalDate.of(appNow()), context.localeName),
                    page: 1,
                  ),
                  height: _Grid.headerHeight,
                ),

                // The record column takes the remainder, and the remainder is
                // what gives (`06 §8.2`, one level up): the chrome the thumb aims
                // at is fixed, the reading surface flexes.
                Expanded(
                  child: ClipRect(
                    child: SingleChildScrollView(
                      key: const Key('quick_entry.record_column'),
                      child: Column(
                        children: <Widget>[
                          // Inside the scroll view and not above it — measured at
                          // N21-T08, where placing it above overflowed a
                          // 375 x 667 device by 665 px at textScaler 2.0.
                          const ExportBanner(),
                          TonightRows(
                            locale: context.localeName,
                            l10n: l10n,
                            onOpen: (TonightRow row) =>
                                unawaited(Routes.lambingEntry(context, row.lambing)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // **THE FIVE EVENT WORDS.** `§8`: one 64 px ruled line directly
                // above the live row, at the top of the thumb band, with Lambing
                // pre-selected *"because that is what tonight is"*.
                EventWordLine(
                  semanticLabel: l10n.quickEntryEventLine,
                  words: <ShedEventWord>[
                    (
                      id: 'lambing',
                      label: l10n.quickEntryLambing,
                      selected: true,
                      // The row is already a lambing; pressing the selected word
                      // opens it rather than starting a second one.
                      onTap: () => _openRow(context, ref),
                    ),
                    (
                      id: 'treatment',
                      label: l10n.quickEntryEventTreatment,
                      selected: false,
                      onTap: () => unawaited(Routes.treatments(context)),
                    ),
                    (
                      id: 'note',
                      label: l10n.quickEntryEventNote,
                      selected: false,
                      onTap: () => _openRow(context, ref),
                    ),
                    (
                      id: 'death',
                      label: l10n.quickEntryEventDeath,
                      selected: false,
                      // A death is recorded against a lamb, and the lamb is on
                      // the lambing. There is no route that takes a death
                      // directly, and inventing one here would be a second way to
                      // write the same fact.
                      onTap: () => _openRow(context, ref),
                    ),
                    (
                      id: 'move_pen',
                      label: l10n.quickEntryEventMovePen,
                      selected: false,
                      onTap: () => unawaited(Routes.penBoard(context)),
                    ),
                  ],
                ),

                // **THE LIVE ROW: THE PERSISTENT LOADED SUBJECT.** Welded above
                // the band, never a scrolling child — `indelible.html:1138` puts
                // it inside the stream, which is the design's one genuine safety
                // gap (`00-comparison.md §4.1`): the open row scrolls away and you
                // lose track of whose it is.
                LiveRow(
                  time: formatShedTime(appNow(), context.localeName),
                  provenance: l10n.quickEntryStampAuto,
                  tagPrompt: l10n.quickEntryTagPrompt,
                  tagCellSemanticLabel: l10n.quickEntryTagCell,
                  onTagCell: () => _openTagSheet(context, ref, l10n),
                  derivedType: (int strokes) => _derivedType(l10n, strokes),
                  derivedStamp: l10n.quickEntryDerivedStamp,
                  marginWidth: _Grid.marginWidth,
                  // THE RECEIPT LIVES IN THE ROW, NOT IN AN OVERLAY (P2 — there
                  // is no SnackBar). It reads the scope rather than watching a
                  // provider, because a feedback function has a BuildContext and
                  // no WidgetRef.
                  trailing: ValueListenableBuilder<SaveReceipt?>(
                    valueListenable: ShedReceiptScope.of(context),
                    builder: (BuildContext context, SaveReceipt? receipt, Widget? _) =>
                        receipt == null
                        ? const SizedBox.shrink()
                        : _StrikeAffordance(receipt: receipt),
                  ),
                ),

                QuickEntryBand(
                  indexLabel: l10n.quickEntryIndex,
                  // **THE SLAB ARMS WHEN THE TAG LANDS** (`§8`): its label
                  // changes from `TAG FIRST` to `+ LAMB`. It is never disabled —
                  // pressing `TAG FIRST` opens the sheet, because a dead key
                  // under a cold thumb is indistinguishable from a missed tap.
                  slabLabelUnarmed: l10n.quickEntrySlabTagFirst,
                  slabLabelArmed: l10n.quickEntrySlabAddLamb(term: l10n.termLambSingular),
                  onIndex: () => _openIndex(context, l10n),
                  // **THIS WAS `() {}`, AND IT IS THE PRODUCT'S CENTRAL ACT.**
                  // `§8`: *"Press the slab. One stroke prints in the lamb column
                  // ... Three taps. About six seconds."* The three taps were
                  // there; the third did nothing at all.
                  onSlab: () async {
                    final QuickEntryState state = ref.read(quickEntryControllerProvider);
                    final EweId? ewe = state.selected;
                    if (ewe == null) {
                      _openTagSheet(context, ref, l10n);
                      return;
                    }
                    await ref
                        .read(quickEntryWriteControllerProvider.notifier)
                        .addLamb(ewe: ewe, into: state.openLambing);
                    // The id comes off the committed outcome. The row must be
                    // remembered or the next press opens a SECOND lambing, and a
                    // set of triplets is filed as three singles.
                    if (ref.read(quickEntryWriteControllerProvider) case WriteDone(
                      outcome: WriteCommitted(insertedId: final int id?),
                    )) {
                      ref.read(quickEntryControllerProvider.notifier).openedLambing(LambingId(id));
                    }
                  },
                  bandHeight: _Grid.bandHeight,
                  indexWidth: _Grid.indexWidth,
                  indexHeight: _Grid.indexHeight,
                  slabWidth: _Grid.slabWidth,
                  slabHeight: _Grid.slabHeight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the row the slab is writing into, if there is one.
  ///
  /// **THREE OF THE FIVE EVENT WORDS LAND HERE**, and that is honest rather than
  /// lazy: a note and a death are both recorded against the open lambing, on the
  /// screen that owns it. Inventing a second route to write the same fact would
  /// be a second place for it to disagree with itself.
  void _openRow(BuildContext context, WidgetRef ref) {
    if (ref.read(quickEntryControllerProvider).openLambing case final LambingId id) {
      unawaited(Routes.lambingEntry(context, id));
    }
  }

  /// `SINGLE` / `TWIN` / `TRIPLET`, **counted, never chosen** (ruling P8).
  ///
  /// Nobody ever picks "triplet" from a list. The type is a count of things that
  /// happened, which is what turns safety rule §12.4 from a validation routine
  /// into the structure of the interaction — and it is why there is no chooser
  /// anywhere in this file for it to contradict.
  String? _derivedType(AppLocalizations l10n, int strokes) => switch (strokes) {
    0 => null,
    1 => l10n.quickEntryDerivedSingle,
    2 => l10n.quickEntryDerivedTwin,
    3 => l10n.quickEntryDerivedTriplet,
    _ => l10n.quickEntryDerivedMultiple(count: strokes, term: l10n.termLambPlural),
  };

  /// `§8`'s tag sheet, from the TAG cell or from an unarmed slab.
  ///
  /// **IT RISES IN FRONT OF THE PAGE AND GOES AWAY WHEN A TAG LANDS.** Before
  /// P16 it was open on every frame the app ever drew, which is what left the
  /// record column 125 px on a 667 pt device.
  void _openTagSheet(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    unawaited(
      showShedBottomSheet<void>(
        context,
        dismissLabel: l10n.quickEntryTagSheetClose,
        dismissSemanticLabel: l10n.quickEntryTagSheetCloseHint,
        barrierLabel: l10n.quickEntryTagCell,
        // The keypad needs more than Flutter's 9/16 default cap, and §8's sheet
        // needs more than §7.14's 60%: the heading, the digits, the match list
        // and the create line all sit above those twelve keys. Measured: 60%
        // overflowed by 87 px with the list already at zero rows.
        //
        // The list is what gives, which is `06 §8.2`'s documented shrink order —
        // on the smallest supported device it goes to zero rows and the create
        // line is still there, so an unknown tag can always be written into the
        // book.
        fillsViewport: true,
        viewportFraction: _kTagSheetFraction,
        child: const TagSheetBody(),
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
            // **KEYED, BECAUSE THE TEST THAT READS IT WAS CLOCK-DEPENDENT.** The
            // window is asserted from the constant rather than from a literal, so
            // the finder searched for the digits of `kStrikeWindow.inSeconds` —
            // and the margin cell one column left prints the time. At 14:20 that
            // is two matches and a red suite; at 14:21 it is one and a green one.
            // A test that passes or fails on the wall clock is worse than none.
            child: Text(
              r.summary,
              key: const Key('quick_entry.strike.window'),
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
            ),
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

/// How much of the viewport `§8`'s tag sheet takes.
///
/// `§7.14`'s 60% is the bare keypad's figure and the tag sheet is the case that
/// proves it is not every sheet's: `§8` puts a heading, the typed digits, a
/// match list AND the create line above those same twelve keys. Measured at P16
/// on the reference viewport, 60% overflowed by **87 px** with the list already
/// at zero rows — a sheet that obeyed §7.14 could not render §8's own contents.
const double _kTagSheetFraction = 0.88;

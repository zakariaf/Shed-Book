// lib/features/pens/pen_board_screen.dart
//
// THE BOARD IS A PICTURE OF THE SHED. Every active pen is a row whether or not
// anything is in it, because the empty pen is the one the shepherd is about to
// use — and a board that showed only occupied pens would hide exactly the rows
// they are looking for at 03:20.
//
// **IT WAS A `Wrap` OF TILES, AND `indelible.md §8` REFUSES TILES.** The obvious
// answer is a 3 × 4 grid; §8 spends a paragraph rejecting it, because *"a grid
// forces the eye to zig-zag — across, down, back, across — and every hop is a
// chance to read pen 7's hours against pen 8's occupant. A ruled column does not
// zig-zag."* `06 §11` and `10 §5.2` describe the tiles; `indelible.md` outranks
// them in the authority order, so the board is twelve ruled rows in the one
// document — same spine, same header, same thumb band as every other screen.
//
// It watches TWO things and that is deliberate: the board's one statement, and
// the minute ticker. `10 §3.5`'s `hours` and `status` depend on `now`, so
// nothing stores them — and the TICK IS WATCHED BY THE WIDGET, never by
// `penBoardProvider`, which is keepAlive. A keepAlive listener on an
// `.autoDispose` ticker is a listener that never goes away, and the ticker would
// wake the process every sixty seconds all night with no board on screen. That
// is the *"measurable overnight battery"* decision #66 argues about, and the
// reason `02 §4.2` calls the ticker's `.autoDispose` load-bearing rather than
// tidiness.
library;

import 'package:shed_book/features/pens/widgets/pen_sheet.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/data/pen_repository.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/core/ui/components/shed_time_editor.dart';
import 'package:shed_book/core/ui/components/shed_bottom_sheet.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_bottom_band.dart';
import 'package:shed_book/core/ui/components/shed_corner_slab.dart';
import 'package:shed_book/core/ui/components/shed_page.dart';
import 'package:shed_book/core/ui/components/shed_pen_tile.dart';
import 'package:shed_book/core/ui/components/shed_ruled_row.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/time/ticker.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/features/pens/pen_board_controller.dart';
import 'package:shed_book/l10n/app_localizations.dart';
import 'package:shed_book/routing/routes.dart';

/// The page's own geometry, from `indelible.md` §4.4. Named rather than typed
/// inline: `token.magic_size` is right to fire on a bare number, and these are
/// layout constants the screen owns — they are not palette values, so they are
/// not on `ShedTokens`. Read off the components where a component owns them.
class _Grid {
  static const double bandHeight = 152;
  static const double indexWidth = 96;
  static const double indexHeight = 64;
  static const double slabWidth = ShedCornerSlab.width;
  static const double slabHeight = ShedCornerSlab.height;
}

/// Which way the board is printed.
///
/// **NOT PERSISTED, AND THAT IS THE POINT.** It is a way of looking at the page
/// for the next thirty seconds, not a setting; a stored sort order is a decision
/// the shepherd has to remember making, and the board they open at 04:12 is the
/// one that answers *which pen needs me*.
enum _PenOrder { hours, penNumber }

class PenBoardScreen extends ConsumerStatefulWidget {
  const PenBoardScreen({super.key});

  @override
  ConsumerState<PenBoardScreen> createState() => _PenBoardScreenState();
}

class _PenBoardScreenState extends ConsumerState<PenBoardScreen> {
  _PenOrder _order = _PenOrder.hours;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = context.localeName;
    final List<PenTile> tiles = ref.watch(penBoardProvider).value ?? const <PenTile>[];

    // THE TICK, WATCHED HERE. When the route pops, the last listener goes and
    // the ticker stops — which is the whole point of it being autoDispose.
    final Instant now = ref.watch(minuteTickProvider).value ?? appNow();
    final LocalDate today = LocalDate.of(now);

    // RESOLVED FOR THIS TICK, ALL OF THEM, IN ONE PASS. Twelve rows do not grow
    // twelve timers: one stream, one frame, twelve `forTick` calls.
    //
    // THE THRESHOLD COMES FROM THE TILE, NOT FROM A SECOND WATCH HERE, and that
    // is a fix rather than a preference. `settleThresholdHoursProvider` reads
    // `settingsProvider`, which reads the settings repository, which calls
    // `requireValue` on the database — so watching it in a widget that paints
    // BEFORE the database opens throws on the first frame. Measured: all
    // eighteen pen-board matrix cells failed with `AsyncLoading<AppDatabase>`.
    //
    // `penBoardProvider` already resolved it after awaiting the database, and it
    // is on every row. One source, and it is the one that waited.
    // **THE DECK, FOR THE SHEET'S CANDIDATE LIST.** Read here rather than inside
    // `_openPen` because a provider may not be read from a callback that outlives
    // the build; `.value` is null until the database opens, and the sheet handles
    // that — it offers no candidates rather than throwing.
    final QuickEntryDeck? deck = ref.watch(quickEntryDeckProvider).value;

    final List<PenTile> resolved = <PenTile>[
      for (final PenTile tile in tiles)
        tile.forTick(now, thresholdHours: tile.thresholdHours, today: today),
    ]..sort(_order == _PenOrder.hours ? _byHoursDescending : _byPenNumber);

    return ShedPage(
      // `THE PENS · 27 JUL 2026 04:12 · 5 OCCUPIED · 2 OVER †` (`§8`). The
      // header is the one line that answers the question from six feet away
      // without reading a single row, which is why it carries the two counts
      // rather than just naming the screen.
      header: l10n.penBoardPageHeader(
        date: formatShedDate(today, locale),
        time: formatShedTime(now, locale),
        occupied: resolved.where((PenTile p) => p.status != PenTileStatus.empty).length,
        over: resolved.where((PenTile p) => p.status == PenTileStatus.ready).length,
      ),
      scrollKey: const Key('pen_board.stream'),
      band: ShedBottomBand(
        indexKey: const Key('pen_board.index'),
        indexLabel: l10n.penBoardIndex,
        // INDEX is the only navigation affordance in the app — there is no back
        // chevron anywhere (decision record §7.0a). It pops rather than pushes:
        // the board is a destination, and `popToQuickEntry` is a no-op on the
        // route stack the tests pump, where the board IS route 0.
        onIndex: () => Routes.popToQuickEntry(context),
        // **THE SLAB READS `+ PEN`, NOT `MOVE`, AND THAT IS A REPORTED GAP.**
        // `§8` puts `MOVE` here — *"pressing it opens the same chooser
        // pre-loaded with the most recently touched ewe"* — and that chooser
        // does not exist: the turn-out and move verbs are on `PenRepository`
        // with no caller, and building the sheet is a write path, not a
        // re-layout. `+ PEN` is the one act this screen already performs, and a
        // slab that reads `MOVE` and does nothing is worse than one that reads
        // what it does.
        slabKey: const Key('pen_board.add_pen'),
        slabLabel: l10n.penBoardAddPen,
        slabSemanticLabel: l10n.penBoardAddPenSemantics,
        // ONE TAP, NO WIZARD, NO NAMING STEP — `addPen` chooses the number and
        // the shepherd renames it in daylight.
        onSlab: () => ref.read(penRepositoryProvider).addPen(),
        bandHeight: _Grid.bandHeight,
        indexWidth: _Grid.indexWidth,
        indexHeight: _Grid.indexHeight,
        slabWidth: _Grid.slabWidth,
        slabHeight: _Grid.slabHeight,
      ),
      children: resolved.isEmpty
          // THE ZERO-PEN BOARD IS NOT AN EMPTY RULED PAGE. A flock that has not
          // made its pens yet gets one printed line and the slab — an empty
          // page is a screen that looks broken, and a wizard is a decision at
          // 03:20 nobody wants.
          ? <Widget>[
              ShedRuledRow(
                key: const Key('pen_board.empty'),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.penBoardNoPens,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: t.textChrome),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ]
          : <Widget>[
              _SortLine(
                order: _order,
                l10n: l10n,
                onTap: () => setState(() {
                  _order = _order == _PenOrder.hours ? _PenOrder.penNumber : _PenOrder.hours;
                }),
              ),
              Semantics(
                // ONE CONTAINER FOR THE BOARD, with the rows as explicit
                // children. Without it a screen reader reads twelve rows as
                // twelve unrelated buttons.
                key: const Key('pen_board.grid'),
                container: true,
                explicitChildNodes: true,
                label: l10n.penBoardTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final PenTile tile in resolved)
                      ShedPenTile(
                        key: Key('pen_board.tile.${tile.penLabel}'),
                        status: _statusOf(tile),
                        lambCount: tile.lambCount,
                        labels: _labelsFor(context, tile, l10n),
                        // **RESTORED. THIS WAS `onTap: () {}` A SECOND TIME.**
                        //
                        // N19 landed `enterPen`, `exitPen` and `movePen` with
                        // tests and no caller; N26 wired them to this row and
                        // left a comment saying so. The R87 rebuild re-typed the
                        // comment as *"T07 opens the row"* — the pre-N26 text —
                        // and put the empty handler back, so a shepherd could
                        // once again add a pen and not put an animal in it.
                        //
                        // `fresh_notebook_test.dart`'s penning journey is what
                        // caught it. A re-layout that silently drops a screen's
                        // primary act is the worst thing a re-layout can do, and
                        // it is invisible in a screenshot.
                        onTap: () => _openPen(context, ref, l10n, tile, resolved, deck),
                      ),
                  ],
                ),
              ),
            ],
    );
  }

  /// **LOSS FIRST, THEN HOURS DESCENDING, THEN THE PEN NUMBER**, and all three
  /// keys are named in a document.
  ///
  /// `indelible.md §8`: *"the board is sorted by hours descending by default, so
  /// the pens that need you are the pens you can already see."* `10 §3.5` sorts
  /// loss rows above settling ones. Both hold if loss is the first key — and it
  /// has to be, because a dead lamb in a pen entered two hours ago would
  /// otherwise sink to row eleven, which is the one row nobody scrolls to.
  ///
  /// The pen number is the tie-break rather than the insertion order, so a board
  /// where nothing has been penned yet still prints 1, 2, 3 rather than whatever
  /// order the statement happened to emit.
  static int _byHoursDescending(PenTile a, PenTile b) {
    if (a.hasLoss != b.hasLoss) {
      return a.hasLoss ? -1 : 1;
    }
    final int byHours = b.hours.compareTo(a.hours);
    return byHours != 0 ? byHours : _byPenNumber(a, b);
  }

  /// Physical order — the order the shepherd walks. **NUMERIC WHERE BOTH LABELS
  /// ARE NUMBERS**, because `'10' < '9'` as text and a board that printed pen 10
  /// between 1 and 2 would be worse than no sort at all. A renamed pen (`Shed A`)
  /// has no number, so it sorts after the numbered ones by its own string —
  /// `nextPenLabel` ignores it for the same reason.
  static int _byPenNumber(PenTile a, PenTile b) {
    final int? x = int.tryParse(a.penLabel);
    final int? y = int.tryParse(b.penLabel);
    if (x != null && y != null) {
      return x.compareTo(y);
    }
    if (x != null) {
      return -1;
    }
    if (y != null) {
      return 1;
    }
    return a.penLabel.compareTo(b.penLabel);
  }

  /// The component's enum from the feature's.
  ///
  /// **MIRRORED, NOT IMPORTED**, because `lib/core/ui/` may not import
  /// `lib/features/` — see `ShedPenTileStatus`. This switch is exhaustive, so a
  /// sixth status fails to compile here rather than rendering as `settling`.
  ShedPenTileStatus _statusOf(PenTile tile) => switch (tile.status) {
    PenTileStatus.settling => ShedPenTileStatus.settling,
    PenTileStatus.ready => ShedPenTileStatus.ready,
    PenTileStatus.attention => ShedPenTileStatus.attention,
    PenTileStatus.loss => ShedPenTileStatus.loss,
    PenTileStatus.empty => ShedPenTileStatus.empty,
  };

  ShedPenTileLabels _labelsFor(BuildContext context, PenTile tile, AppLocalizations l10n) {
    final String locale = Localizations.localeOf(context).toLanguageTag();

    final String? word = switch (tile.status) {
      // `settling`'s WORD IS ITS HOURS — see ShedPenTile.
      PenTileStatus.settling => null,
      PenTileStatus.ready => l10n.penTileReady,
      PenTileStatus.attention => l10n.penTileAttention(
        // **`formatShedDayMonth`, NOT `formatShedDate`, AND THE FORMATTER SAYS
        // SO IN ITS OWN DOC** — *"`14 Jul`. The tight-chip form — the pen tile
        // and the withdrawal countdown."* The full form carried a year into a
        // stamp that shares its line with a 44 pt pen number and a 32 pt hours
        // figure; the year is the one part of a clear date nobody needs on a
        // board they read at arm's length, and it costs five characters.
        date: tile.clearDate == null ? '' : formatShedDayMonth(tile.clearDate!, locale),
      ),
      PenTileStatus.loss => l10n.penTileLoss,
      PenTileStatus.empty => l10n.penTileEmpty,
    };

    final String hours = l10n.penTileHours(hours: tile.hours);

    return (
      penLabel: tile.penLabel,
      tag: tile.tag,
      hours: tile.status == PenTileStatus.empty ? null : hours,
      statusWord: word,
      semanticLabel: l10n.penTileSemantics(
        label: tile.penLabel,
        state: <String>[
          if (tile.tag case final String tag) tag,
          if (tile.status != PenTileStatus.empty) hours,
          if (word case final String w) w,
        ].join(', '),
      ),
    );
  }

  /// One pen's verbs. **Each is one tap once the sheet is open** (`07 §9.5`).
  void _openPen(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PenTile tile,
    List<PenTile> all,
    QuickEntryDeck? deck,
  ) {
    final List<DeckEntry> candidates = <DeckEntry>[...?deck?.penned, ...?deck?.recents];

    unawaited(
      showShedBottomSheet<void>(
        context,
        dismissLabel: l10n.colostrumSheetClose,
        dismissSemanticLabel: l10n.colostrumSheetCloseSemantics,
        barrierLabel: l10n.penBoardTitle,
        child: PenSheet(
          // **`tag == null && lambCount == 0` IS EMPTY**, and the two halves
          // matter: a pen with lambs and no ewe is an ORPHAN pen, which is
          // occupied and whose verbs are turn-out and move.
          occupied: tile.tag != null || tile.lambCount > 0,
          candidates: candidates,
          otherPens: <({PenId id, String label})>[
            for (final PenTile p in all)
              if (p.penId != tile.penId) (id: p.penId, label: p.penLabel),
          ],
          l10n: l10n,
          onCorrectTime: () => _openTimeEditor(context, ref, l10n, tile),
          onAction: (PenAction action) {
            final PenRepository pens = ref.read(penRepositoryProvider);
            // EXHAUSTIVE, no `_` arm: a fourth verb must fail to compile here
            // rather than silently do nothing, which is the defect this whole
            // sheet exists to undo.
            unawaited(switch (action) {
              PenAnimal(ewe: final EweId ewe) => pens.enterPen(tile.penId, ewe: ewe),
              TurnOut() => pens.turnOutFrom(tile.penId),
              MoveTo(pen: final PenId to) => pens.movePenFrom(tile.penId, to),
              // Reached through `onCorrectTime`, which asks first — the arm
              // exists so the switch stays exhaustive rather than growing a
              // wildcard that would swallow a fifth verb.
              CorrectEnteredAt(hour: final int h, minute: final int m) => pens.correctEnteredAtFrom(
                tile.penId,
                hour: h,
                minute: m,
              ),
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  /// The §12.5 edit path on a penning time.
  ///
  /// **THE DAY IS THE ONE ALREADY ON THE RECORD**, exactly as on Lambing Entry:
  /// a shepherd correcting at 03:47 means *it was 03:20 that night*, and taking
  /// the day from the clock would move a 3am penning across a date boundary the
  /// moment they corrected it after midnight.
  void _openTimeEditor(BuildContext context, WidgetRef ref, AppLocalizations l10n, PenTile tile) {
    unawaited(
      showShedBottomSheet<void>(
        context,
        dismissLabel: l10n.colostrumSheetClose,
        dismissSemanticLabel: l10n.colostrumSheetCloseSemantics,
        barrierLabel: l10n.timeEditorHeading,
        fillsViewport: true,
        child: ShedTimeEditor(
          labels: (
            heading: l10n.timeEditorHeading,
            hint: l10n.timeEditorHint,
            confirmLabel: l10n.timeEditorConfirm,
            confirmSemanticLabel: l10n.timeEditorConfirmSemantics,
            padLabel: l10n.timeEditorHeading,
            backspaceLabel: l10n.keypadBackspace,
            backspaceHint: l10n.hintDeleteLastDigit,
          ),
          onCorrect: (int hour, int minute) {
            ref
                .read(penRepositoryProvider)
                .correctEnteredAtFrom(tile.penId, hour: hour, minute: minute)
                .ignore();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

/// The one in-stream control on this page.
///
/// **AT THE TOP OF THE STREAM, WHICH COSTS A ROW AND BUYS THE ONLY REACHABLE
/// POSITION.** `§8` fits eight rows above the band and puts four more one scroll
/// away; a sort control under the twelfth is a control nobody finds while
/// carrying a ewe. Seven pens above the band instead of eight is the price.
class _SortLine extends StatelessWidget {
  const _SortLine({required this.order, required this.l10n, required this.onTap});

  final _PenOrder order;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ShedRuledRow(
    key: const Key('pen_board.sort'),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      // **`IntrinsicWidth`, AND WITHOUT IT THE BUTTON IS THE WHOLE LINE.**
      // `ShedTapTarget` centres its child inside a `ConstrainedBox`, and an
      // `Align` with finite constraints FILLS rather than shrink-wraps — so the
      // word button measured 298 pt wide and drew its 2 px underline across the
      // page, one pixel above the row's own rule. Two full-width rules stacked
      // is the doubled rule, which on this board means *over threshold*. A word
      // button has to hug its word or the mark stops meaning one thing.
      child: IntrinsicWidth(
        child: ShedWordButton(
          key: const Key('pen_board.sort.button'),
          // **THE WORD NAMES WHAT THE PRESS WILL DO, NEVER WHAT IS TRUE NOW.**
          // A control labelled with its current state is a control the shepherd
          // has to reason about before pressing it, and at 03:20 they will not.
          label: order == _PenOrder.hours ? l10n.penBoardSortByPen : l10n.penBoardSortByHours,
          // There is no selected state: it is one button that swaps, not two
          // that would need a selection channel between them.
          selected: false,
          onTap: onTap,
        ),
      ),
    ),
  );
}

// lib/features/pens/pen_board_screen.dart
//
// THE BOARD IS A PICTURE OF THE SHED. Every active pen is a tile whether or not
// anything is in it, because the empty pen is the one the shepherd is about to
// use — and a board that showed only occupied pens would hide exactly the tiles
// they are looking for at 03:20.
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_pen_tile.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/time/ticker.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/features/pens/pen_board_controller.dart';
import 'dart:async';

import 'package:shed_book/core/ui/components/shed_bottom_sheet.dart';
import 'package:shed_book/data/flock_repository.dart';
import 'package:shed_book/data/pen_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/pens/widgets/pen_sheet.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class PenBoardScreen extends ConsumerWidget {
  const PenBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<PenTile> tiles = ref.watch(penBoardProvider).value ?? const <PenTile>[];

    // **WATCHED HERE, NOT READ IN THE SHEET, AND THE DIFFERENCE IS A LOADING
    // VALUE.** `ref.read` on a `StreamProvider` nobody is listening to starts it
    // and returns `AsyncLoading` — so the first draft opened the sheet on an
    // empty deck every time, with the heading rendered over nothing. Watching it
    // in `build` means it is already resolved when a tile is pressed.
    final QuickEntryDeck? deck = ref.watch(quickEntryDeckProvider).value;

    // THE TICK, WATCHED HERE. When the route pops, the last listener goes and
    // the ticker stops — which is the whole point of it being autoDispose.
    final Instant now = ref.watch(minuteTickProvider).value ?? appNow();
    final LocalDate today = LocalDate.of(now);

    // RESOLVED FOR THIS TICK, ALL OF THEM, IN ONE PASS. Twelve tiles do not grow
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
    // is on every tile. One source, and it is the one that waited.
    final List<PenTile> resolved = <PenTile>[
      for (final PenTile tile in tiles)
        tile.forTick(now, thresholdHours: tile.thresholdHours, today: today),
    ];

    return Scaffold(
      backgroundColor: t.surfaceBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: resolved.isEmpty
                  // THE ZERO-PEN BOARD IS NOT AN EMPTY GRID. A flock that has
                  // not made its pens yet gets ONE target and nothing else —
                  // an empty grid is a screen that looks broken, and a wizard is
                  // a decision at 03:20 nobody wants.
                  ? Center(child: _AddPen(l10n: l10n))
                  : SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(t.gapMin),
                        child: Semantics(
                          // ONE CONTAINER FOR THE GRID, with the tiles as
                          // explicit children. Without it a screen reader reads
                          // twelve tiles as twelve unrelated buttons.
                          container: true,
                          explicitChildNodes: true,
                          label: l10n.penBoardTitle,
                          child: Wrap(
                            key: const Key('pen_board.grid'),
                            spacing: t.gapMin,
                            runSpacing: t.gapMin,
                            children: <Widget>[
                              for (final PenTile tile in resolved)
                                ShedPenTile(
                                  key: Key('pen_board.tile.${tile.penLabel}'),
                                  status: _statusOf(tile),
                                  lambCount: tile.lambCount,
                                  labels: _labelsFor(context, tile, l10n),
                                  // **THIS WAS `onTap: () {}` AND THE COMMENT
                                  // SAID T07 WOULD OPEN THE ROW.** T07 landed
                                  // the board and not the sheet, so every verb
                                  // N19 built — `enterPen`, `exitPen`,
                                  // `movePen` — had no caller: a shepherd could
                                  // add a pen and could not put an animal in
                                  // it, take one out, or move one.
                                  onTap: () => _openPen(context, ref, l10n, tile, resolved, deck),
                                ),
                              _AddPen(l10n: l10n),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
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
          onAction: (PenAction action) {
            final PenRepository pens = ref.read(penRepositoryProvider);
            // EXHAUSTIVE, no `_` arm: a fourth verb must fail to compile here
            // rather than silently do nothing, which is the defect this whole
            // sheet exists to undo.
            unawaited(switch (action) {
              PenAnimal(ewe: final EweId ewe) => pens.enterPen(tile.penId, ewe: ewe),
              TurnOut() => pens.turnOutFrom(tile.penId),
              MoveTo(pen: final PenId to) => pens.movePenFrom(tile.penId, to),
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
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
        date: tile.clearDate == null ? '' : formatShedDate(tile.clearDate!, locale),
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
}

class _AddPen extends ConsumerWidget {
  const _AddPen({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;

    return ShedTapTarget(
      key: const Key('pen_board.add_pen'),
      semanticLabel: l10n.penBoardAddPenSemantics,
      minSize: t.tapPrimary,
      // ONE TAP, NO WIZARD, NO NAMING STEP — `addPen` chooses the number and the
      // shepherd renames it in daylight.
      onTap: () => ref.read(penRepositoryProvider).addPen(),
      child: ExcludeSemantics(
        child: Center(
          child: Text(l10n.penBoardAddPen, style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
    );
  }
}

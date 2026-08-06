// lib/features/quick_entry/widgets/tonight_rows.dart
//
// **THE RECORD COLUMN. IT WAS TWELVE EMPTY `SizedBox`es.**
//
// `quick_entry_screen.dart` drew `for (int i = 0; i < 12; i++) SizedBox(...)`
// where the page should be, so the design's central promise — *the confirmation
// IS the committed row, in ink, one line above the one being written* — had no
// row to be. Reported from a simulator on 2026-08-06: a shepherd recorded a
// lambing, went back to Quick Entry, typed the tag again, and found nothing.
//
// It is also most of why the screen read as unfinished. `indelible.md`'s whole
// organising idea is a ruled ledger — margin time, spine, one line per record —
// and with no lines and no records what is left is a keypad on a black page.
//
// **NOTHING IS REMOVED FROM THIS PAGE.** A struck lambing keeps its position,
// its legibility and its place in the order, and takes an unboxed `STRUCK`
// stamp. `WHERE struck IS NULL` is the reflex and it is the defect.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_status_badge.dart';
import 'package:shed_book/core/ui/components/shed_tally.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/time/recorded_time.dart';
import 'package:shed_book/core/ui/components/shed_margin_cell.dart';
import 'package:shed_book/l10n/app_localizations.dart';

/// One ruled line per lambing, most recent first.
///
/// **IT READS ITS OWN PROVIDER**, exactly as `InPensStrip`, `RecentsStrip` and
/// `ExportBanner` do — and that is a structural rule rather than a style
/// choice. `quick_entry_test.dart` asserts the shell watches nothing, *"because
/// a StatelessWidget that watches nothing cannot be rebuilt by a keystroke or
/// by an emission"* (`02 §10.1`), and that is what makes every box on the
/// screen immovable under a thumb.
///
/// The first draft took its rows as a parameter and had the page watch
/// `tonightProvider` for it. That test caught it immediately, which is the
/// assertion doing its job: a `ref.watch` in the page is a channel through
/// which a lambing arriving at 03:20 could move the keypad under a finger
/// already travelling towards it.
class TonightRows extends ConsumerWidget {
  const TonightRows({required this.locale, required this.l10n, required this.onOpen, super.key});

  final String locale;
  final AppLocalizations l10n;
  final ValueChanged<TonightRow> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final List<TonightRow> rows = ref.watch(tonightProvider).value ?? const <TonightRow>[];

    if (rows.isEmpty) {
      // **NOT `ShedEmptyState`.** Quick Entry is never empty (`07 §2.2`) — the
      // deck and the keypad are always there — so this is a line about the
      // PAGE, in the pixels a row would occupy, rather than a screen-sized
      // empty state that would push the chrome around.
      return SizedBox(
        height: kRecordRowHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: t.gapMin),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.tonightEmpty,
              key: const Key('quick_entry.tonight.empty'),
              style: text.labelMedium?.copyWith(color: t.textSecondary),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final TonightRow row in rows)
          DecoratedBox(
            // **ROWS SHARE EDGES — 2 px, NO GAP** (`§7.3`): the ruling is
            // continuous, like a ledger. It is also R86-legal, because targets
            // that touch are one of the two permitted separations.
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: t.outline, width: t.outlineWidth),
              ),
            ),
            child: ShedTapTarget(
              key: Key('quick_entry.tonight.${row.lambing.value}'),
              semanticLabel: l10n.tonightRow(
                tag: row.tag ?? l10n.tonightUntagged,
                count: formatShedCount(row.lambCount, locale),
              ),
              minSize: kRecordRowHeight,
              onTap: () => onOpen(row),
              child: ExcludeSemantics(
                child: Row(
                  children: <Widget>[
                    // **THE MARGIN CELL: THE TIME, AND THE PROVENANCE UNDER
                    // IT** (`§4.3`, `§12.5`). The stamp is not an exempt stamp —
                    // it is the sole statement of the §12.5 claim on its line —
                    // so it renders at the 18 px floor in `labelMedium`.
                    // **THE COMPONENT, NOT A COPY.** `ShedMarginCell`
                    // is §4.3's cell, and it holds the measured reason its
                    // height is a minimum rather than 64.
                    //
                    // **THE SHORT STAMP, NOT THE PROVENANCE SENTENCE.**
                    // `indelible-page-and-screens §1.2` owns this and it is
                    // arithmetic: an 18 px caps-tracked word does not fit the
                    // 68 px margin — six characters is already ~84 px. Shipped
                    // with `provenanceLabel`, the margin read `recor…` on a
                    // simulator, which states nothing at all and is a worse
                    // §12.5 outcome than the four-letter stamp. The long label
                    // is not lost: it prints in the RECORD COLUMN on Lambing
                    // Entry, where it has the width.
                    ShedMarginCell(
                      time: formatShedTime(row.at.effective, locale),
                      stampAuto: switch (row.at.source) {
                        TimeSource.autoCaptured => l10n.quickEntryStampAuto,
                        TimeSource.userEntered => l10n.quickEntryStampEntered,
                        TimeSource.userEdited => l10n.quickEntryStampEdited,
                      },
                      width: kMarginWidth,
                      height: kRecordRowHeight,
                    ),
                    Expanded(
                      child: Text(
                        row.tag ?? l10n.tonightUntagged,
                        style: text.bodyLarge?.copyWith(
                          color: row.struck ? t.textSecondary : t.textPrimary,
                          // **A STRIKE IS A RULE THROUGH THE ROW, AND THIS IS
                          // THE TEXT HALF OF IT.** The struck row stays where it
                          // is, dimmed and still legible — never removed, never
                          // sorted away.
                          decoration: row.struck ? TextDecoration.lineThrough : null,
                          decorationThickness: row.struck ? 2 : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // **STROKES, NEVER A DIGIT** (`§8` screen 7): four lambs is
                    // four marks a shepherd counts at a glance.
                    if (row.lambCount > 0) ShedTally(count: row.lambCount, semanticLabel: ''),
                    if (row.struck) ...<Widget>[
                      SizedBox(width: t.gapMin / 2),
                      ShedStatusBadge(stamp: ShedStamp.struck, label: l10n.tonightStruck),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// `indelible.md §4.4`'s record row and `§4.3`'s margin cell.
const double kRecordRowHeight = 64;
const double kMarginWidth = 68;

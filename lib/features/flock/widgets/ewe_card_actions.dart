// lib/features/flock/widgets/ewe_card_actions.dart
//
// **THE CARD'S FOUR VERBS, IN THE THUMB BAND.** `indelible.md §4.5`: nothing
// required to record an event sits above 560 px from the bottom, and these are
// the acts a shepherd takes while standing next to the animal.
//
// **EVERY ACTION IS A WORD.** There is no icon set in this system
// (`indelible.md §1.3`), so `LAMBING`, `OBSERVE`, `BARREN` and `CULL` are the
// controls — not glyphs with tooltips, which would need a banned gesture to read.
//
// **THE VERBS COME FROM THIS FEATURE'S OWN WRITE CONTROLLER**, because layer
// rule 6 forbids `lib/features/flock/` from importing `lib/features/lambing/`.
// `CONVENTIONS §4.4` rule 2 — one write controller per feature — is what makes
// that fine, and N14-T03 hit the identical wall on Quick Entry.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_bottom_sheet.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/ewe_status.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/flock/flock_controller.dart';
import 'package:shed_book/features/flock/widgets/note_sheet.dart';
import 'package:shed_book/features/flock/widgets/observation_sheet.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class EweCardActions extends ConsumerWidget {
  const EweCardActions({required this.eweId, super.key});

  final EweId eweId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final FlockWriteController writes = ref.read(flockWriteControllerProvider.notifier);

    return Padding(
      key: const Key('ewe_card.actions'),
      padding: EdgeInsets.all(t.gapMin),
      // **THE EVENT VERB IS LAST, WHICH PUTS IT NEAREST THE THUMB.** `Wrap`
      // fills top-down, so four buttons on one line become two lines with the
      // FIRST one furthest from the bottom — exactly backwards for reach. The
      // primary act gets its own full-width row at the bottom of the band and
      // the three secondary words share the line above it.
      //
      // Measured: at `Device.small` the four-on-one-line arrangement put the top
      // row 354 px from the bottom, outside `indelible.md §4.5`'s 0–320 thumb
      // band. Secondary actions may live in the 320–560 reach band; the event
      // verb may not.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: t.gapMin,
            runSpacing: t.gapMin,
            children: <Widget>[
              ShedWordButton(
                key: const Key('ewe_card.action.observe'),
                label: l10n.eweCardActionObserve,
                selected: false,
                onTap: () => showShedBottomSheet<void>(
                  context,
                  dismissLabel: l10n.eweCardObserveClose,
                  dismissSemanticLabel: l10n.eweCardObserveCloseHint,
                  barrierLabel: l10n.eweCardObserveHeading,
                  child: ObservationSheet(eweId: eweId),
                ),
              ),
              // **THE GENERAL NOTE** — the one verb for a fact the schema has
              // no column for. `addNote` had no caller anywhere in `lib/`.
              ShedWordButton(
                key: const Key('ewe_card.action.note'),
                label: l10n.eweCardActionNote,
                selected: false,
                onTap: () => showShedBottomSheet<void>(
                  context,
                  dismissLabel: l10n.eweCardNoteClose,
                  dismissSemanticLabel: l10n.eweCardNoteCloseHint,
                  barrierLabel: l10n.eweCardNoteHeading,
                  child: NoteSheet(eweId: eweId),
                ),
              ),
              // R42 — a season participation outcome, not a status and not an
              // observation.
              ShedWordButton(
                key: const Key('ewe_card.action.barren'),
                label: l10n.eweCardActionBarren,
                selected: false,
                onTap: () => writes.recordBarren(eweId).ignore(),
              ),
              // **NO CONFIRMATION DIALOG, AND NO UNDO VERB EITHER** (R41, #92).
              // The previous value is recoverable from the record's own context
              // — an animal with lambings this season who is suddenly culled was
              // active a moment ago, and the card says so. `guard()` is what
              // stops a double tap writing twice.
              ShedWordButton(
                key: const Key('ewe_card.action.cull'),
                label: l10n.eweCardActionCull,
                selected: false,
                onTap: () => writes.setStatus(eweId, EweStatus.culled).ignore(),
              ),
            ],
          ),
          SizedBox(height: t.gapMin),
          // **THE ROW IS COMMITTED BY THIS TAP, BEFORE ANY SCREEN IS PUSHED**
          // (`07 §7.1`). The screen's `ref.listen` pushes Lambing Entry from the
          // id the outcome carries — navigation is the screen's job, never the
          // controller's (`§4.4` rule 3).
          ShedWordButton(
            key: const Key('ewe_card.action.lambing'),
            label: l10n.eweCardActionLambing,
            selected: false,
            onTap: () => writes.beginLambing(eweId).ignore(),
          ),
        ],
      ),
    );
  }
}

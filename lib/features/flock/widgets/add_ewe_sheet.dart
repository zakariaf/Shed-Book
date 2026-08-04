// lib/features/flock/widgets/add_ewe_sheet.dart
//
// **RULING N4 — `07 §3.3` VERSUS `03 §6`, AND BOTH SENTENCES ARE TRUE.**
//
//   `07 §3.3`  the `duplicateActiveTag` warning *"never blocks the create"*
//   `03 §6`    `UNIQUE ON ewes (tag) WHERE status = 'active' AND struck = 0`
//
// The index is on `tag`, the **exact string**. So `412` and `B412` are both
// storable — same digits, ranked together by the pad, genuinely ambiguous — and
// that ambiguity is what the warning is for. A second live `412` is not
// ambiguous, it is identical, and it makes *"what did 412 do last year?"*
// unanswerable, which is the question the product exists to answer.
//
// The resolution is GEOMETRY, not prose (§12.4's ladder: a rule that has dropped
// to merely documented has been deleted). The confirm bar's **label is derived
// from the match state**, so `CREATE 412` is unreachable while an active `412`
// exists: there is no create to block, and the warning "never blocks" is true
// and vacuous. A tag held only by a culled, sold or dead animal raises nothing
// at all — that tag is free (`03 §6` item 4).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_confirm_bar.dart';
import 'package:shed_book/core/ui/components/shed_keypad.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/tag_match.dart';
import 'package:shed_book/features/flock/flock_controller.dart';
import 'package:shed_book/l10n/app_localizations.dart';

/// The sheet's own body. Opened by [FlockScreen]'s `+ EWE` slab through
/// `showShedBottomSheet`, which is the one place the three permissive flags are
/// typed.
class AddEweSheet extends ConsumerStatefulWidget {
  const AddEweSheet({required this.onOpenExisting, super.key});

  /// What `OPEN 412` does. The sheet does not navigate itself — a widget that
  /// pops its own route and pushes another is a widget two screens can never
  /// share (`02 §8.4`).
  final void Function(EweId ewe) onOpenExisting;

  @override
  ConsumerState<AddEweSheet> createState() => _AddEweSheetState();
}

class _AddEweSheetState extends ConsumerState<AddEweSheet> {
  /// **A PRIVATE FIELD ON THE STATE, NOT A HALF-WRITTEN ROW** (`CONVENTIONS
  /// §4.4` rule 4, `07 §15.5`). Closing the sheet without confirming writes
  /// nothing — and that is the *absence* of a draft rather than the discarding
  /// of one. There is no draft state in this app to lose.
  String _typed = '';

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context);

    // **THE ACTIVE FLOCK ONLY** (R26, §7.0 ruling 7). `tagIndexProvider`'s
    // statement carries `WHERE status = 'active'`, which is the same set the
    // partial unique index covers — so a culled `412` is absent here, and
    // typing `412` offers `CREATE 412` because that tag really is free.
    final List<TagIndexEntry> index = switch (ref.watch(tagIndexProvider)) {
      AsyncData<List<TagIndexEntry>>(value: final List<TagIndexEntry> all) => all,
      _ => const <TagIndexEntry>[],
    };
    final List<TagIndexEntry> matches = rankTagMatches(index, _typed);

    // **EXACT ON THE STRING, NOT ON THE DIGITS.** `rankTagMatches` ranks by the
    // projection, so `B412` is in this list when `412` is typed — and it is a
    // different tag on a different animal. Comparing `e.tag` is what keeps the
    // two cases apart, and it is the same comparison the index makes.
    final TagIndexEntry? exact = matches.where((TagIndexEntry e) => e.tag == _typed).firstOrNull;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: Text(l10n.flockAddHeading(term: l10n.termEweSingular), style: text.labelMedium),
          ),
          // **THE HINT IS ABOVE THE LINE, NEVER INSIDE THE FIELD**
          // (`indelible.md §7.12`): *"in the dark, a grey placeholder is
          // indistinguishable from an entered value."*
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: Text(l10n.flockAddFieldLabel, style: text.bodySmall),
          ),
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: Container(
              key: const Key('flock.add.value'),
              height: t.tapIndelible,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: t.outline, width: t.outlineWidth),
                ),
              ),
              child: Text(_typed, style: text.displaySmall),
            ),
          ),
          // **THE COLLISION IS STATED IN WORDS, IN THE PIXELS BELOW THE FIELD.**
          // `WarningCode.duplicateActiveTag`'s value, constructed here by the UI
          // and never persisted — decision #54: there is no `warnings` column
          // and there is nowhere to persist one.
          if (exact != null)
            Padding(
              key: const Key('flock.add.duplicate'),
              padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin),
              child: Text(
                l10n.flockAddDuplicateTag(tag: exact.tag, term: l10n.termEweSingular),
                style: text.bodyMedium,
              ),
            ),
          ShedKeypad(
            onDigit: (String d) => setState(() => _typed += d),
            onBackspace: () => setState(() {
              if (_typed.isNotEmpty) {
                _typed = _typed.substring(0, _typed.length - 1);
              }
            }),
            thirdKey: ShedKeypadThirdKey.newTag,
            // NEW TAG starts a fresh one. Same meaning as on Quick Entry: the
            // animal in front of you is not the one on screen.
            onThirdKey: () => setState(() => _typed = ''),
            padLabel: l10n.keypadTagEntry,
            backspaceLabel: l10n.keypadBackspace,
            backspaceHint: l10n.hintDeleteLastDigit,
            thirdKeyLabel: l10n.keypadNewTag,
          ),
          SizedBox(height: t.gapMin),
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            // **NOTHING IS DISABLED AND NOTHING IS HIDDEN.** With no digits
            // typed the bar is absent rather than inert — a dead control under a
            // cold thumb is indistinguishable from a missed tap
            // (`indelible.md §7.2`).
            child: _typed.isEmpty
                ? SizedBox(height: t.tapHero)
                : ShedConfirmBar(
                    key: const Key('flock.add.confirm'),
                    // **THE LABEL IS THE OUTCOME, AND IT IS WHAT HOLDS RULING
                    // N4 AT *unconstructible*.** `OPEN 412` while an active 412
                    // exists; `CREATE 412` only when the tag is free.
                    outcomeLabel: exact == null
                        ? l10n.flockAddConfirmCreate(tag: _typed)
                        : l10n.flockAddConfirmOpen(tag: exact.tag),
                    semanticLabel: exact == null
                        ? l10n.flockAddConfirmCreate(tag: _typed)
                        : l10n.flockAddConfirmOpen(tag: exact.tag),
                    onTap: () {
                      if (exact case final TagIndexEntry e) {
                        widget.onOpenExisting(e.eweId);
                        return;
                      }
                      // **THE SHEET DOES NOT AWAIT THE OUTCOME.** The verb is an
                      // event verb returning `Future<void>`; the outcome lands
                      // as state and the screen's `ref.listen` renders it. A
                      // sheet that awaited it would be a second place the
                      // outcome is handled, and one of the two would drift.
                      ref.read(flockWriteControllerProvider.notifier).createEwe(_typed).ignore();
                      Navigator.of(context).pop();
                    },
                  ),
          ),
          // The live-ranked match list, under the confirm bar: it is what the
          // shepherd reads to decide, and reading happens above the thumb.
          for (final TagIndexEntry m in matches.take(_maxMatches))
            ShedTapTarget(
              key: Key('flock.add.match.${m.eweId.value}'),
              semanticLabel: l10n.flockAddConfirmOpen(tag: m.tag),
              minSize: t.tapMin,
              onTap: () => widget.onOpenExisting(m.eweId),
              child: ExcludeSemantics(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: t.gapMin),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(m.tag, style: text.titleMedium),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Six, the same depth as Quick Entry's deck strips. A list long enough to
  /// scroll is a list nobody reads at 03:20 — and this one sits inside a sheet
  /// that must not grow past the viewport.
  static const int _maxMatches = 6;
}

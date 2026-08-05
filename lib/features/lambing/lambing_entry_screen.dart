// lib/features/lambing/lambing_entry_screen.dart
//
// The shell. The header, the lambs region and the care region are empty regions
// today; T02 onward fills them. It exists now because the anchor test has to
// pump something, and because the route helper needs a destination.
//
// It watches ONE provider. lib/features/ may not import package:drift or
// lib/core/db/ at all (layer rule 5), which is why LambingEntryData is declared
// in lib/data/ and assembled there.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_section_heading.dart';
import 'package:shed_book/core/ui/components/shed_text_field.dart';
import 'package:shed_book/core/ui/components/shed_word_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/sex.dart';
import 'package:shed_book/domain/stats/season_counts.dart';
import 'package:shed_book/domain/units/weight_unit.dart';
import 'package:shed_book/core/write_action.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/features/lambing/lambing_entry_controller.dart';
import 'package:shed_book/features/lambing/photo_controller.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/core/ui/vocab_label.dart';
import 'package:shed_book/domain/birth_type.dart';
import 'package:shed_book/domain/care_kind.dart';
import 'package:shed_book/core/ui/components/shed_bottom_sheet.dart';
import 'package:shed_book/features/lambing/widgets/care_line.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/recorded_time.dart';
import 'package:shed_book/domain/validation/warning.dart';
import 'package:shed_book/features/lambing/widgets/colostrum_detail.dart';
import 'package:shed_book/features/lambing/widgets/declare_type_sheet.dart';
import 'package:shed_book/features/lambing/widgets/provenance_header.dart';
import 'package:shed_book/features/lambing/widgets/query_mark.dart';
import 'package:shed_book/core/ui/components/shed_time_editor.dart';
import 'package:shed_book/data/settings_repository.dart';
import 'package:shed_book/features/lambing/widgets/detail_rows.dart';
import 'package:shed_book/features/lambing/widgets/ease_row.dart';
import 'package:shed_book/features/lambing/widgets/lamb_row.dart';
import 'package:shed_book/features/lambing/widgets/lamb_tally_row.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class LambingEntryScreen extends ConsumerWidget {
  const LambingEntryScreen({required this.lambingId, super.key});

  final LambingId lambingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<LambingEntryData> data = ref.watch(lambingEntryProvider(lambingId));

    // THE ONE LISTEN. The switch is exhaustive with no `default:` — WriteOutcome
    // is sealed with three variants, and the day a fourth lands this must fail
    // to compile rather than swallow it.
    ref.listen<WriteState>(lambingWriteControllerProvider, (WriteState? previous, WriteState next) {
      if (next case WriteDone(:final WriteOutcome outcome)) {
        switch (outcome) {
          case WriteCommitted():
            // The confirmation IS the stroke: the stream re-emits and the mark
            // appears. There is nothing else to say and no SnackBar to say it
            // in (P2).
            break;
          case WriteFailed():
            // T06's warning strip. A failure is never silence.
            break;
          case WriteRefused():
            // Unreachable: no write on this screen is gated by the cap.
            break;
        }
      }
    });

    return Scaffold(
      backgroundColor: t.surfaceBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(t.gapMin),
              child: ShedSectionHeading(label: l10n.lambingEntryTitle.toUpperCase(), level: 1),
            ),
            Expanded(
              child: switch (data) {
                AsyncData<LambingEntryData>(value: final LambingEntryData d) => _Regions(
                  data: d,
                  // **THE SHEPHERD'S OWN PLURAL, IN TITLE CASE.**
                  // `copy.arb_domain_noun` found this heading hard-coded as
                  // *Lambs* at N33-T05 — a shepherd who renamed the term read
                  // somebody else's noun on the screen they use most.
                  //
                  // The capital is presentation, not derivation: `10 §8.5` bans
                  // deriving a PLURAL from a singular, because that is a fact
                  // about the word. Which case a heading renders in is a fact
                  // about the heading, and every other one in this system is
                  // capitalised.
                  lambsLabel: l10n.lambingEntryLambs(term: _titleCase(l10n.termLambPlural)),
                  careLabel: l10n.lambingEntryCare,
                  units: ref.watch(unitsProvider),
                  // RECOMPUTED ON EVERY EMISSION, NEVER STORED. Decision #54
                  // closes the `warnings` column permanently.
                  warnings: ref.watch(lambingWarningsProvider(lambingId)),
                  // THE SAME APP-LEVEL SINGLETON THE EASE ROW READS (R81). One
                  // watch, four consumers, no second content statement.
                  vocab: ref.watch(vocabProvider).value ?? <VocabEntry>[],
                ),
                // NO SPINNER (07 §1.4): loading is a fixed-height placeholder or
                // it is nothing. A spinner on a screen the shepherd reached by
                // committing a row says the row might not be there.
                _ => const SizedBox.expand(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Regions extends ConsumerWidget {
  const _Regions({
    required this.data,
    required this.lambsLabel,
    required this.careLabel,
    required this.units,
    required this.warnings,
    required this.vocab,
  });

  final LambingEntryData data;
  final String lambsLabel;
  final String careLabel;

  /// **Never inferred from the locale** (R68). A UK smallholder may genuinely
  /// want lb, and a wrong inference silently mislabels every weight ever
  /// recorded.
  final WeightUnit units;

  /// **DERIVED, NOT STORED**, and never gating anything (`05 §7.5` guarantee 3).
  /// A blocked write produces a lost record, which is worse than a queried one —
  /// and on this screen there is nothing to block anyway, because every field
  /// committed the moment it was tapped.
  final List<Warning> warnings;

  /// The forty vocabulary rows, for the presentation picker's labels.
  final List<VocabEntry> vocab;

  /// The warnings against one cell, grouped.
  ///
  /// **NEVER TWICE FOR ONE FIELD** (`07 §6.3`). Two codes can fire on the same
  /// cell — a header time can be both `lambingInFuture` and
  /// `lambingLongBeforeCapture` — so the mark is one per `fieldPath` and the
  /// sheet lists everything it found.
  List<Warning> _warningsOn(String fieldPath) =>
      warnings.where((Warning w) => w.fieldPath == fieldPath).toList(growable: false);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final ShedTokens t = context.tokens;

    // SCROLLABLE FROM T04, AND VERTICAL SCROLLING IS THE ONE TRACKED GESTURE
    // (06 §7 — the gate's own words, and every swipe ACTION stays banned).
    //
    // It was a plain Column until the ease group landed, and the ease group is
    // what made it overflow: five 72 pt buttons with their descriptions do not
    // fit under the tally on a small phone, and at 150% text scale they re-lay
    // as 3 + 2 and take another row. The measured overflow was 148 px.
    //
    // A ListView would be the reflex and it is wrong here: the regions are a
    // fixed handful, not a list, and a ListView would add lazy building and a
    // scroll controller for nothing. The trailing Expanded filler goes with the
    // change — nothing may be Expanded inside an unbounded scrollable.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // THE MARGIN CELL OVER THE RECORD (T07). It replaces the bare
          // provenance line: the time, the stamp, the dagger when edited, and a
          // second line saying what it was edited FROM.
          ProvenanceHeader(
            time: data.lambing.time,
            labels: _provenanceLabels(context, data.lambing.time),
            onCorrect: () => _openTimeEditor(context, ref, data.lambing.id),
          ),
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: Text(
              '$lambsLabel ${data.lambs.length}',
              key: const Key('lambing_entry.lambs'),
              style: text.bodyMedium,
            ),
          ),
          Padding(
            // **`bottom: gapMin`, AND IT IS R86 THAT PUT IT THERE.** N33-T03's
            // geometric sweep measured **6 pt** between the `+ lamb` slab and
            // the first lamb row — the tally row is 94 tall because the tally
            // column is, the slab inside it is `tapHero` 88, and the six left
            // over landed under the slab. Six is the middle of the band the
            // separation rule forbids, and this is the one pair on this screen
            // where a mis-tap adds a lamb that was never born.
            //
            // A gap rather than stretching the slab to 94: `06 §6.1`'s sizes are
            // the tap scale, and a target sized by whatever its neighbour
            // happened to measure is a target that changes size when the tally
            // does. The 16 pt also says something true — the tally is about the
            // lambing, the rows below it are the lambs.
            padding: EdgeInsets.only(left: t.gapMin, right: t.gapMin, bottom: t.gapMin),
            child: LambTallyRow(lambingId: data.lambing.id, lambs: data.lambs),
          ),
          // ONE ROW PER LAMB, IN `l.id ASC` — STROKE ORDER, which is the order the
          // repository already returns and the order the tally beside it counts
          // in. 10 §5.2 groups by status on the lists that are ABOUT lambs; here
          // the ordinal must agree with the marks, and re-sorting the dead to the
          // bottom would print LAMB 3 second. If that is disputed it is a screens
          // question for N17/N27, not a local choice.
          //
          // A Column and not a ListView: a lambing is single, twins or triplets
          // in almost every case, and quintPlus is the tail. A scrollable here
          // would add a scroll gesture to a screen whose whole point is that a
          // cold thumb hits big fixed things.
          for (int i = 0; i < data.lambs.length; i++)
            LambRow(
              key: Key('lambing_entry.lamb.${data.lambs[i].id.value}'),
              labels: _labelsFor(context, data.lambs[i], i + 1),
            ),
          // UNDER THE LAMBS, ABOVE CARE. Ease is about the lambing rather than
          // about any one lamb, so it sits below the list it describes.
          // THE MARK SITS BESIDE THE TALLY, WHICH IS THE OFFENDING CELL: the
          // contradiction is between the declared type and the counted strokes,
          // and the strokes are what is on screen.
          //
          // THE KEY SAYS `declared_type`, NOT THE ABOLISHED SEGMENT, AND R80a
          // MADE IT DO SO. That rule bans the segment from every widget key
          // under `lib/`, because such a key is the chooser coming back
          // somewhere nobody is looking — and it fired on the first run of this
          // task. The rename is the honest one anyway: this cell is about the
          // DECLARATION, which is a different fact from the counted type the
          // tally prints, and the two should not share a name.
          if (_warningsOn('birth_type') case final List<Warning> found when found.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: t.gapMin),
              child: Row(
                children: <Widget>[
                  QueryMark(
                    key: const Key('lambing_entry.query.declared_type'),
                    semanticLabel: AppLocalizations.of(
                      context,
                    ).queryMarkSemantics(finding: found.first.message),
                    onTap: () => _openDeclareType(context, ref, data.lambing.id, found),
                  ),
                ],
              ),
            ),
          EaseRow(lambingId: data.lambing.id, ease: data.lambing.ease),
          // THE FOUR CARE LINES. On this screen every care event is written
          // against the LAMBING — the lamb arm is for care given to one lamb,
          // which is N17's per-lamb detail. `CareSubject` is sealed so neither
          // arm can be forgotten at a call site.
          for (final CareKind kind in CareKind.values)
            CareLine(
              key: Key('lambing_entry.care.${kind.key}'),
              state: _careState(context, kind),
              onPressed: () {
                final CareEntryRow? existing = _liveCare(kind);
                final LambingWriteController write = ref.read(
                  lambingWriteControllerProvider.notifier,
                );
                // A SECOND PRESS UNDOES, AND UNDOING IS A STRIKE. It does not
                // revert the line to unset: both stamps stay on the page.
                if (existing != null) {
                  write.removeCare(existing.id);
                } else if (kind == CareKind.colostrum) {
                  // COLOSTRUM OPENS ITS DETAIL SHEET; THE OTHER THREE DO NOT.
                  // Volume and method exist only for colostrum, and putting a
                  // sheet in front of a navel dip would add a decision to a
                  // one-tap act at 03:20 for a field that does not exist.
                  _openColostrumDetail(context, write, data.lambing.id);
                } else {
                  write.addCare(CareForLambing(data.lambing.id), kind: kind);
                }
              },
            ),
          // THE ASSISTANCE DETAIL (T08). Every field below is SKIPPABLE and
          // each commits on its own — four narrow verbs, never one wide write,
          // because a wide write is how a second edit clobbers the first.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
            child: Text(AppLocalizations.of(context).detailPresentation, style: text.labelMedium),
          ),
          // **THE THREE DETAIL FIELDS, WHICH THE DESIGN SPECIFIES AND NOBODY
          // BUILT.** `indelible.md §8` screen 4: *"Assistance detail and the
          // note are text fields with the label above and a dotted rule
          // below."* `setAssistedBy`, `setPresentationNote` and `setNote` all
          // existed on the controller and the repository, with tests, and had
          // no caller — because until `ShedTextField` landed there was no way
          // to enter free text anywhere in the app.
          //
          // **EVERY KEYSTROKE COMMITS.** There is no Save button and no draft:
          // each `onChanged` is its own write, which is the same contract the
          // ease buttons and the care checks hold to.
          // **THE PHOTO, WHOSE WHOLE CHAIN HAD NO CALLER.** `pick`,
          // `newRelativePath`, `writePhoto` and `attachPhoto` each landed with
          // tests and fakes; nothing joined them up.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ShedWordButton(
                key: const Key('lambing_entry.photo'),
                label: AppLocalizations.of(context).lambingEntryPhoto,
                semanticLabel: AppLocalizations.of(context).lambingEntryPhoto,
                selected: false,
                onTap: () => attachPhotoTo(ref, data.lambing.id).ignore(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: ShedTextField(
              key: const Key('lambing_entry.assisted_by'),
              label: AppLocalizations.of(context).detailAssistedBy,
              value: data.lambing.assistedBy,
              semanticLabel: AppLocalizations.of(context).detailAssistedBy,
              onChanged: (String? v) => ref
                  .read(lambingWriteControllerProvider.notifier)
                  .setAssistedBy(data.lambing.id, v)
                  .ignore(),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: ShedTextField(
              key: const Key('lambing_entry.presentation_note'),
              label: AppLocalizations.of(context).detailPresentationNote,
              value: data.lambing.presentationNote,
              semanticLabel: AppLocalizations.of(context).detailPresentationNote,
              onChanged: (String? v) => ref
                  .read(lambingWriteControllerProvider.notifier)
                  .setPresentationNote(data.lambing.id, v)
                  .ignore(),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: ShedTextField(
              key: const Key('lambing_entry.note'),
              label: AppLocalizations.of(context).detailNote,
              value: data.lambing.note,
              semanticLabel: AppLocalizations.of(context).detailNote,
              onChanged: (String? v) => ref
                  .read(lambingWriteControllerProvider.notifier)
                  .setNote(data.lambing.id, v)
                  .ignore(),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: PresentationPicker(
              key: const Key('lambing_entry.presentation'),
              choices: _presentationChoices(context),
              unsetLabel: AppLocalizations.of(context).detailUnset,
              groupSemanticLabel: AppLocalizations.of(context).detailPresentationSemantics,
              onSelected: (String? key) => ref
                  .read(lambingWriteControllerProvider.notifier)
                  .setPresentation(data.lambing.id, key),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin),
            child: Text(
              '$careLabel ${data.lambs.fold<int>(0, (int n, LambEntryRow l) => n + l.care.length) + data.lambingCare.length}',
              key: const Key('lambing_entry.care'),
              style: text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// The eight malpresentation words, in `sort_order`.
  ///
  /// **A HIDDEN TERM IS NOT OFFERED**, which is what `vocabProvider`'s ordering
  /// and the seed's `hidden_at` between them decide — and a lambing that already
  /// references a hidden term still renders its label, because the label comes
  /// from the same list rather than from the offered subset. Filtering the
  /// lookup as well as the list is how an existing record starts printing a raw
  /// key at 03:20.
  List<PresentationChoice> _presentationChoices(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    const List<String> keys = <String>[
      'mp_head_back',
      'mp_one_leg_back',
      'mp_both_legs_back',
      'mp_breech',
      'mp_backwards',
      'mp_twins_together',
      'mp_ringwomb',
      'mp_other',
    ];

    String shipped(String key) => switch (key) {
      'mp_head_back' => l10n.vocabMpHeadBack,
      'mp_one_leg_back' => l10n.vocabMpOneLegBack,
      'mp_both_legs_back' => l10n.vocabMpBothLegsBack,
      'mp_breech' => l10n.vocabMpBreech,
      'mp_backwards' => l10n.vocabMpBackwards,
      'mp_twins_together' => l10n.vocabMpTwinsTogether,
      'mp_ringwomb' => l10n.vocabMpRingwomb,
      'mp_other' => l10n.vocabMpOther,
      _ => throw ArgumentError.value(key, 'key', 'not a frozen malpresentation key'),
    };

    return <PresentationChoice>[
      for (final String key in keys)
        (
          key: key,
          label: vocabLabel(
            vocab.where((VocabEntry v) => v.key == key).firstOrNull?.label,
            shipped(key),
          ),
          selected: data.lambing.presentation == key,
        ),
    ];
  }

  /// The header's words.
  ProvenanceLabels _provenanceLabels(BuildContext context, RecordedTime time) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final String effective = formatShedTime(time.effective, locale);

    return (
      effective: effective,
      wasEffective: time.originalEffective == null
          ? null
          : formatShedTime(time.originalEffective!, locale),
      wasPrefix: l10n.provenanceWasPrefix,
      // THE PROVENANCE IS IN THE SPOKEN LABEL TOO. A time read aloud without its
      // source would be the one place §12.5's claim goes silent, and it is
      // `provenanceLabel` itself rather than a second spelling of it.
      semanticLabel: l10n.provenanceHeaderSemantics(
        time: effective,
        provenance: time.provenanceLabel,
      ),
      editSemanticLabel: l10n.provenanceEditHint,
    );
  }

  /// The app's own keypad in a sheet. **Never a Material time picker** — see
  /// `time_editor_sheet.dart` for the three separate rules that forbid it.
  void _openTimeEditor(BuildContext context, WidgetRef ref, LambingId lambing) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final LambingWriteController write = ref.read(lambingWriteControllerProvider.notifier);
    final LambingEntryData current = data;

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
            // THE DAY IS THE ONE ALREADY ON THE RECORD. A shepherd correcting a
            // time at 03:47 means "it was 03:20 THAT NIGHT", not "03:20 today" —
            // and taking the day from the clock would move a 3am lambing across
            // a date boundary the moment they corrected it after midnight.
            final DateTime day = current.lambing.time.effective.local;
            write.correctOccurredAt(
              lambing,
              Instant.fromDateTime(DateTime(day.year, day.month, day.day, hour, minute).toUtc()),
            );
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  /// Opens the sheet a query mark leads to.
  ///
  /// **IT ADJUSTS NOTHING, IN EITHER BRANCH.** `CHANGE THE BIRTH TYPE` writes
  /// the declaration and leaves the lambs alone; `LEAVE IT` writes nothing to
  /// either. The mark is not an offer to fix.
  void _openDeclareType(
    BuildContext context,
    WidgetRef ref,
    LambingId lambing,
    List<Warning> found,
  ) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final LambingWriteController write = ref.read(lambingWriteControllerProvider.notifier);

    unawaited(
      showShedBottomSheet<void>(
        context,
        dismissLabel: l10n.colostrumSheetClose,
        dismissSemanticLabel: l10n.colostrumSheetCloseSemantics,
        barrierLabel: l10n.declareTypeHeading,
        child: DeclareTypeSheet(
          labels: (
            heading: l10n.declareTypeHeading,
            // EVERY LINE IS A `Warning.message`, which says what we observed and
            // never what to do. There is no second source of these strings and
            // no place to write one.
            findings: <String>[for (final Warning w in found) w.message],
            changeLabel: l10n.declareTypeChange,
            leaveLabel: l10n.declareTypeLeave,
            typeWord: (BirthType type) => switch (type) {
              BirthType.single => l10n.birthTypeSingle,
              BirthType.twin => l10n.birthTypeTwin,
              BirthType.triplet => l10n.birthTypeTriplet,
              BirthType.quad => l10n.birthTypeQuad,
              BirthType.quintPlus => l10n.birthTypeQuintPlus,
            },
          ),
          onDeclare: (BirthType type) {
            write.setBirthType(lambing, type);
            Navigator.of(context).pop();
          },
          onLeave: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /// Opens the colostrum detail and records whatever comes back.
  ///
  /// **THE CARE EVENT IS WRITTEN WHEN THE SHEET CLOSES, NOT WHEN IT OPENS**, and
  /// that is the one place on this screen where a tap does not commit
  /// immediately. It is deliberate and it is bounded: `addCare` takes the volume
  /// and the method as arguments, so writing on open would mean writing twice —
  /// an insert and then an update — and the second write is the one that could
  /// be lost. One row, one transaction, one provenance quad.
  ///
  /// Closing the sheet without pressing RECORD writes the event with both fields
  /// null, because the shepherd DID give colostrum: the sheet asks for detail,
  /// never for permission. The dismiss word says so.
  void _openColostrumDetail(BuildContext context, LambingWriteController write, LambingId lambing) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    unawaited(
      showShedBottomSheet<void>(
        context,
        dismissLabel: l10n.colostrumSheetClose,
        dismissSemanticLabel: l10n.colostrumSheetCloseSemantics,
        barrierLabel: l10n.colostrumSheetBarrier,
        // 60% of the viewport — the keypad does not fit without it
        // (indelible.md §7.14).
        fillsViewport: true,
        child: ColostrumDetailSheet(
          labels: (
            volumeLabel: l10n.colostrumVolumeLabel,
            methodLabel: l10n.colostrumMethodLabel,
            unitSuffix: l10n.colostrumVolumeUnit,
            recordLabel: l10n.colostrumRecord,
            recordSemanticLabel: l10n.colostrumRecordSemantics,
            padLabel: l10n.colostrumVolumeLabel,
            backspaceLabel: l10n.keypadBackspace,
            backspaceHint: l10n.hintDeleteLastDigit,
            methodWords: <String>[
              l10n.colostrumMethodTeat,
              l10n.colostrumMethodTube,
              l10n.colostrumMethodBottle,
            ],
            methodSemanticLabel: (String w) => l10n.colostrumMethodSemantics(word: w),
          ),
          onRecord: (ColostrumDetail detail) {
            write.addCare(
              CareForLambing(lambing),
              kind: CareKind.colostrum,
              volumeMl: detail.volumeMl,
              method: detail.method,
            );
            Navigator.of(context).pop();
          },
        ),
      ).then((void _) {
        // DISMISSED WITHOUT RECORDING STILL WRITES THE EVENT — see above. The
        // guard is what stops the RECORD path writing twice: it has already run
        // by the time this fires, so the row exists and `_liveCare` is not null.
        if (_liveCare(CareKind.colostrum) == null) {
          write.addCare(CareForLambing(lambing), kind: CareKind.colostrum);
        }
      }),
    );
  }

  /// The LIVE care event of one kind against this lambing, or null.
  ///
  /// **DERIVED FROM THE ONE STATEMENT, NOT FROM A SECOND QUERY.** T01's
  /// statement already returns the care rows; this is `any` over data in hand.
  /// An `EXISTS` subquery would be a second content stream and `07 §1.2` forbids
  /// it — the word *exists* in that document names the SHAPE OF THE STATE, not a
  /// SQL construct to go and write.
  ///
  /// **Struck rows are excluded from LIVE but not from the page.** A struck care
  /// event still renders — its DONE stamp struck, its UNDONE stamp beside it —
  /// which is why the two lookups below are different functions rather than one
  /// with a flag.
  CareEntryRow? _liveCare(CareKind kind) {
    for (final CareEntryRow c in data.lambingCare) {
      if (c.kind == kind.key && !c.struck) {
        return c;
      }
    }
    return null;
  }

  CareEntryRow? _struckCare(CareKind kind) {
    for (final CareEntryRow c in data.lambingCare) {
      if (c.kind == kind.key && c.struck) {
        return c;
      }
    }
    return null;
  }

  /// One care line's words.
  ///
  /// **THERE IS NO "NO" ARM**, and the `switch` has nowhere to put one: the
  /// state is a done stamp or the not-recorded label, and `null` is what an
  /// unpressed line carries. Decision #43.
  CareLineState _careState(BuildContext context, CareKind kind) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final String label = switch (kind) {
      // EXHAUSTIVE, NO `default:`. A fifth kind is a schema migration AND a
      // notification-channel decision (R49); it must not be able to reach the
      // screen as a blank label.
      CareKind.colostrum => l10n.careColostrum,
      CareKind.navelDip => l10n.careNavelDip,
      CareKind.stomachTube => l10n.careStomachTube,
      CareKind.warmed => l10n.careWarmed,
    };

    final CareEntryRow? live = _liveCare(kind);
    final CareEntryRow? struck = _struckCare(kind);

    final String? doneAt = switch ((live, struck)) {
      (final CareEntryRow c, _) => l10n.careDoneAt(time: formatShedTime(c.time.effective, locale)),
      (null, final CareEntryRow c) => l10n.careDoneAt(
        time: formatShedTime(c.time.effective, locale),
      ),
      (null, null) => null,
    };
    final String? undoneAt = live == null && struck != null
        ? l10n.careUndoneAt(time: formatShedTime(struck.time.effective, locale))
        : null;

    return (
      label: label,
      doneAt: doneAt,
      undoneAt: undoneAt,
      semanticLabel: l10n.careLineSemantics(label: label, state: doneAt ?? l10n.careNotRecorded),
    );
  }

  /// The screen resolves the copy; [LambRow] renders it. See `LambRowLabels`.
  ///
  /// **THE NOUNS COME FROM THE ARB'S `term*Singular` MESSAGES, NOT FROM A
  /// LITERAL AND NOT YET FROM `terminologyProvider`.** Three things forced this,
  /// and the middle one is a gate:
  ///
  /// 1. `10 §8.5` — a domain noun varies by county, so it is never typed into a
  ///    sentence. `l10n_bootstrap_test.dart` scans every ARB value for one and
  ///    caught `"EWE {animal}"` on the first run of this task.
  /// 2. The `term<Class>Singular` / `term<Class>Plural` pair IS the sanctioned
  ///    source — the fourteen messages the placeholder is fed FROM — and reading
  ///    them here is what `05 §8`'s bootstrap will do when it lands.
  /// 3. `terminologyProvider` is `const Terminology({}, {})` until N29, and
  ///    `labelFor` ends in `_defaults[c]!`. **Routing through it today would
  ///    throw**, which is why `LambTallyRow` types `'lamb'` instead. This is the
  ///    better half of that trade: no literal, no crash, and one grep — the
  ///    `term…Singular` reads below — when N29 wires the overrides through.
  ///
  /// The SEX CELL IS THE ANIMAL CLASS. `AnimalClass.eweLamb`, `ramLamb` and
  /// `lamb` are exactly the three states a lamb's sex can be in, and the last
  /// one's own doc comment reads *"sex unknown, or not yet sexed"* — so a
  /// recorded `Sex.unknown` renders as the plain animal noun while an ABSENT sex
  /// renders as *not recorded* (R45). The two stay different words.
  LambRowLabels _labelsFor(BuildContext context, LambEntryRow lamb, int ordinal) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return lambRowLabels(
      ordinal: ordinal,
      sex: lamb.sex,
      status: lamb.status,
      weight: lamb.birthWeight,
      tag: lamb.tag,
      units: units,
      localeName: Localizations.localeOf(context).toLanguageTag(),
      ordinalLabel: (int n) =>
          l10n.lambingLambOrdinal(animal: l10n.termLambSingular, n: n).toUpperCase(),
      sexLabel: (Sex s) => switch (s) {
        // EXHAUSTIVE, NO `default:`. The day a fourth member lands on Sex this
        // must fail to compile rather than render one of the three.
        Sex.female => l10n.termEweLambSingular.toUpperCase(),
        Sex.male => l10n.termRamLambSingular.toUpperCase(),
        Sex.unknown => l10n.termLambSingular.toUpperCase(),
      },
      statusLabel: (LambStatus s) => switch (s) {
        LambStatus.alive => l10n.lambStatusAlive,
        LambStatus.dead => l10n.lambStatusDead,
        LambStatus.stillborn => l10n.lambStatusStillborn,
        LambStatus.sold => l10n.lambStatusSold,
      },
      notRecorded: l10n.lambingTypeNotRecorded,
      // A COMMA AND A SPACE, not the middot the eye gets: at least one screen
      // reader says "middle dot" and another says nothing at all, and neither
      // is what the row means.
      sentence: (List<String> parts) => l10n.lambRowSemantics(parts: parts.join(', ')),
    );
  }
}

/// First letter up, the rest as the shepherd typed it.
///
/// **NOT `toUpperCase()` AND NOT A LOOKUP.** A term they entered as `Ewe Lambs`
/// keeps its second capital; one they entered as `hoggs` gains one and nothing
/// else. Deriving anything more than the first character would be editing their
/// word.
String _titleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

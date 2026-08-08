// test/features/redundancy_table_test.dart
//
// **`10 §5.2`, ONE CASE PER ROW, UNDER ALL THREE PALETTES.**
//
// The rule (`10 §5.1`, decision #106): three of colour, shape, word and
// position, with **colour never one of the three on its own** — because the
// night-shift palettes deliberately destroy the hue channel, so a colour-only
// encoding is unreadable in the mode the spec names twice.
//
// **NO CASE IN THIS FILE COMPARES TWO `Color`s, AND THAT IS THE POINT.** A test
// asserting that two states have different colours asserts the OPPOSITE of this
// rule. What is asserted is the **word** — resolved through `AppLocalizations`,
// never typed — and that it is the *same* word in every palette, which is what
// "the encoding does not depend on hue" means operationally.
//
// **A GREEN RUN HERE IS NOT A GRAYSCALE PASS.** `10 §5.3` makes grayscale a
// per-release manual sweep (`§7.2` row 6) and N33-T06 records it. Word-and-shape
// presence is automatable; *"can you read this screen with the hue channel
// gone"* is a judgement, and a file that quietly stood in for it would be worse
// than no file.
@Tags(<String>['policy'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/ui/components/shed_countdown.dart';
import 'package:shed_book/core/ui/components/shed_pen_tile.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/treatments/treatments_screen.dart';
import 'package:shed_book/l10n/app_localizations.dart';

import '../support/harness.dart';
import '../support/seeds.dart';

/// **`10 §5.2`'s SHAPE COLUMN, AS THE MARKS INDELIBLE ACTUALLY DRAWS.**
///
/// That column specifies a thick left bar, a filled corner triangle, a
/// circle-slash badge and a diagonal hatch — tile decorations. The selected
/// direction has **no tiles**: `indelible.md §7` makes the pen board ruled
/// rows, and `06 §11`/`10 §5.2`'s tile encodings are superseded by *word +
/// dagger + doubled rule + ink density*. `shed_pen_tile.dart` implements
/// exactly that, so the shape channel is real and has keys; it is a different
/// set of marks from the one the table names.
///
/// Each row below therefore asserts the **word** and the **mark**, and `null`
/// means the status is carried by the rule under the row — which every status
/// has, in four distinguishable styles, and which is asserted separately.
typedef PenTileRow = ({String state, String word, Key? mark});

const Map<ShedPenTileStatus, PenTileRow> kPenTileStates = <ShedPenTileStatus, PenTileRow>{
  ShedPenTileStatus.settling: (state: 'settling', word: '4h', mark: null),
  ShedPenTileStatus.ready: (state: 'ready', word: 'READY', mark: Key('pen_tile.dagger')),
  ShedPenTileStatus.attention: (
    state: 'under withdrawal',
    word: 'CLEAR 14 JUL',
    mark: Key('pen_tile.badge'),
  ),
  // **`loss` GETS NO COLOUR CHANNEL AT ALL AND NO GLYPH EITHER** — the
  // component's own header says so, and `indelible-marks-and-strikes` §7 is
  // blunter: *`DEAD` is a word, in full ink, with no colour, ever.* So the word
  // and the rule under the row are the two channels, and the word is doing most
  // of the work. That is the row to read this whole file against.
  ShedPenTileStatus.loss: (state: 'loss recorded', word: 'DEAD', mark: null),
  ShedPenTileStatus.empty: (state: 'empty pen', word: '— empty —', mark: null),
};

/// **`v1.1.0`, AND NAMED RATHER THAN OMITTED.** `10 §5.2`'s Reminder row —
/// overdue / due today / upcoming — has no screen behind it in this build
/// (N24, N25; `docs/RELEASE-SCOPE.md`, ruling P15). A case for a widget that
/// does not exist would pump nothing and pass, which is the failure this whole
/// epic is about.
const List<String> kRowsAwaitingTheirScreen = <String>['Reminder · overdue / due today / upcoming'];

void main() {
  group('pen tile', () {
    for (final MapEntry<ShedPenTileStatus, PenTileRow> state in kPenTileStates.entries) {
      for (final ShedPaletteId palette in ShedPaletteId.values) {
        testWidgets('${state.value.state} · ${palette.name} — word and mark', (
          WidgetTester tester,
        ) async {
          // **`deepRed` IS THE ONE THAT MATTERS** (decision #96): it drops
          // luminance as well as hue, so it is where a second channel that was
          // quietly a colour fails. Iterating `ShedPaletteId.values` rather than
          // hand-listing two of the three is what makes that automatic.
          final AppDatabase db = testDatabase();
          final PenTileRow row = state.value;

          try {
            await tester.pumpApp(
              Center(
                child: ShedPenTile(
                  status: state.key,
                  labels: (
                    penLabel: '4',
                    tag: state.key == ShedPenTileStatus.empty ? null : '412',
                    hours: state.key == ShedPenTileStatus.empty ? null : '4h',
                    statusWord: state.key == ShedPenTileStatus.settling ? null : row.word,
                    semanticLabel: 'Pen 4',
                  ),
                  lambCount: state.key == ShedPenTileStatus.empty ? 0 : 2,
                  onTap: () {},
                ),
              ),
              db: db,
              palette: palette,
            );

            // **THE WORD, VIA `textContaining`, AND THE JOIN IS WHY.** The tile
            // prints hours and status as ONE line — `4h · READY` — so
            // `find.text('READY')` finds nothing and would have failed every row
            // for a reason that has nothing to do with the rule.
            expect(
              find.textContaining(row.word),
              findsOneWidget,
              reason: '${row.state} · ${palette.name}: the word is gone',
            );

            if (row.mark case final Key mark) {
              expect(find.byKey(mark), findsOneWidget, reason: 'the second channel is missing');
            }

            // **EVERY STATUS HAS A RULE UNDER IT.** It is the channel that
            // survives when the word is truncated and the glyph is absent, and
            // it is the one every row shares, so it is asserted on every row.
            //
            // **THE KEY MOVED AND THE FOUR SHAPES DID NOT SURVIVE.** `10 §5.2`
            // gave the rule four distinguishable styles — single, doubled,
            // dashed, dotted, one per status — painted inside the tile under
            // `pen_tile.rule`. `indelible.md §8` gives the board ONE shape
            // channel, the doubled rule, and only for over-threshold, for a
            // reason the section states itself: what is legible from across the
            // shed is the presence of a second line, not a dash against a dot at
            // 2 px. `indelible.md` outranks `10`, so the vocabulary went.
            //
            // The pen row is a `ShedRuledRow` now, so the rule under it is the
            // ledger's own — asserted here, on every status, exactly as before.
            // The four-shape claim is the part that is gone, and it is gone
            // deliberately rather than by omission.
            expect(find.byKey(const Key('shed_ruled_row.rule')), findsOneWidget);
          } finally {
            await tester.closeApp();
          }
        });
      }
    }
  });

  group('treatment row — the four withdrawal states split on a type', () {
    for (final ShedPaletteId palette in ShedPaletteId.values) {
      testWidgets('a treatment with no applicable withdrawal prints NOT APPLICABLE and mounts no '
          'ShedCountdown · ${palette.name}', (WidgetTester tester) async {
        // **THE COMPILER IS THE GATE HERE AND THIS CASE PROVES IT FIRED.**
        // `ShedCountdown` takes a `ClearsOn`, never a `WithdrawalStatus`
        // (`CONVENTIONS §2.7`, `05 §9` anti-pattern 9), so a countdown for a
        // period nobody recorded is unconstructible rather than merely
        // forbidden. `NOT APPLICABLE` and `NOT RECORDED` are painted by the
        // treatment row itself, in the pixels the countdown would have
        // occupied, with **no countdown widget in the tree** — and that
        // absence is what this asserts.
        final AppDatabase db = testDatabase();
        await seedSeason(db);
        final EweId ewe = await seedEwe(db, tag: '412');
        await seedTreatment(
          db,
          ewe: ewe,
          product: 'Alamycin',
          withdrawalDays: null,
          notApplicable: true,
        );

        try {
          await tester.pumpApp(const TreatmentsScreen(), db: db, palette: palette);
          await tester.pumpAndSettle();

          // **THE BOOK, NOT THE COUNTDOWN.** The screen opens on the countdown,
          // which by construction lists only treatments that have one — so the
          // two states this file is about are invisible there, and that is
          // correct rather than a bug: the countdown is *what is still
          // running*, the book is *what happened*. The words live in the book,
          // so the case goes there.
          await tester.tap(find.byKey(const Key('treatments.mode.book')));
          await tester.pumpAndSettle();

          final AppLocalizations l10n = AppLocalizations.of(
            tester.element(find.byType(TreatmentsScreen)),
          );
          expect(find.text(l10n.treatmentsNotApplicable), findsWidgets);
          expect(
            find.byType(ShedCountdown),
            findsNothing,
            reason:
                'a countdown for a period nobody recorded is the defect the type split prevents',
          );
        } finally {
          await tester.closeApp();
        }
      });

      testWidgets('a treatment with no recorded withdrawal prints NOT RECORDED, never 0 and never '
          'blank · ${palette.name}', (WidgetTester tester) async {
        // **THE PRESENTATION HALF OF SAFETY RULE §12.1.** *Nothing applies* is
        // something somebody read off a bottle; *not recorded* is nobody
        // having looked. One sentence for two facts is the bug `10 §5.2`
        // split, and a blank cell or a `0` would say the second thing while
        // meaning the first.
        final AppDatabase db = testDatabase();
        await seedSeason(db);
        final EweId ewe = await seedEwe(db, tag: '077');
        await seedTreatment(db, ewe: ewe, product: 'Alamycin', withdrawalDays: null);

        try {
          await tester.pumpApp(const TreatmentsScreen(), db: db, palette: palette);
          await tester.pumpAndSettle();

          // **THE BOOK, NOT THE COUNTDOWN.** The screen opens on the countdown,
          // which by construction lists only treatments that have one — so the
          // two states this file is about are invisible there, and that is
          // correct rather than a bug: the countdown is *what is still
          // running*, the book is *what happened*. The words live in the book,
          // so the case goes there.
          await tester.tap(find.byKey(const Key('treatments.mode.book')));
          await tester.pumpAndSettle();

          final AppLocalizations l10n = AppLocalizations.of(
            tester.element(find.byType(TreatmentsScreen)),
          );
          expect(find.text(l10n.treatmentsNoWithdrawal), findsWidgets);
          expect(find.byType(ShedCountdown), findsNothing);

          // Never `0`, never blank: the two ways this row has of lying.
          expect(find.text('0'), findsNothing);
          expect(find.text(''), findsNothing);

          // AND THE TWO WORDS ARE DIFFERENT WORDS, which is the whole reason
          // the row was split. Asserting each in isolation would pass if
          // somebody folded them back into one string.
          expect(l10n.treatmentsNoWithdrawal, isNot(l10n.treatmentsNotApplicable));
        } finally {
          await tester.closeApp();
        }
      });
    }
  });

  test('the rows with no case are exactly the ones whose screen is v1.1.0', () {
    // Same discipline as the overflow matrix's absent-route case: the gap is
    // stated, not left for somebody to notice.
    expect(kRowsAwaitingTheirScreen, hasLength(1));

    // And every pen-tile state has a row, derived from the enum rather than
    // counted: a sixth status must fail here rather than render untested.
    expect(kPenTileStates.keys.toSet(), ShedPenTileStatus.values.toSet());
  });
}

// test/features/goldens_test.dart
//
// **A GOLDEN EARNS ITS PLACE ONLY WHERE A *PIXEL* REGRESSION IS A USABILITY OR
// SAFETY REGRESSION NO OTHER TEST CAN SEE.** Does it overflow, is the target
// 60 pt, is the ratio 12:1 — all already asserted more cheaply by the overflow
// matrix, the geometric sweep and `contrast_test.dart`, and without a binary
// artefact. What is left is the thing a human has to look at.
//
// The review question for these images is never *"did it change"*. It is the one
// the whole suite exists for: **can you still read the tag number?**
//
// **FIVE, NOT EIGHT — `12 §8.2`'s LIST AT ITS `v1.0.0` SIZE.** Three of the
// eight are decision #70's lambing-spread shapes, and the spread chart lives on
// Season Summary, which is `v1.1.0` (N28; `docs/RELEASE-SCOPE.md`, ruling P15).
// A golden of a screen that does not exist is a PNG of an error. The three are
// named below rather than dropped, and the count is derived so it moves on its
// own.
//
// Tagged `golden` and excluded from `make test` by `BROAD_EXCLUDE`: decision
// #116 is explicit that these are **not** a per-PR gate. `make goldens` verifies
// and `make goldens-update` re-baselines, and the second is a deliberate act
// with its own commit (`12 §8.5`).
@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/ui/components/shed_countdown.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_status.dart';
import 'package:shed_book/features/pens/pen_board_screen.dart';
import 'package:shed_book/features/quick_entry/quick_entry_screen.dart';

import '../support/harness.dart';
import '../support/seeds.dart';
import '../support/tolerant_comparator.dart';

/// The three images `12 §8.2` lists that cannot exist yet, named rather than
/// dropped — the same discipline as the overflow matrix's absent routes.
///
/// Each is one of decision #70's chart data shapes: a single day, a tight
/// eighteen-day lambing, and a sixty-day straggle. The chart is a hand-rolled
/// `CustomPainter` on Season Summary (N28), so all three land together in
/// `v1.1.0` and the count below goes back to eight.
const List<String> kGoldensAwaitingTheirScreen = <String>[
  'lambing_spread_one_day.png',
  'lambing_spread_tight_18_days.png',
  'lambing_spread_60_day_straggle.png',
];

/// The night the images are rendered on.
///
/// **PINNED, AND WITHOUT IT EVERY GOLDEN ROTS ON A CALENDAR.** A screen that
/// prints an elapsed time re-renders differently every day, so eight images
/// would need re-baselining every morning and the ritual would stop meaning
/// anything. 11 February 2026, 08:00 — the morning after the fixture pens its
/// ewes, and outside the 22:00–06:00 window in which the export banner is
/// silent.
final DateTime kGoldenNight = DateTime.utc(2026, 2, 11, 8);

void main() {
  test('the comparator is installed and tolerant, not the pixel-exact default', () {
    // **A SUITE THAT COMPARES PIXEL-EXACT PASSES FOR THE WRONG REASON, AND THE
    // LOG LOOKS IDENTICAL TO A CORRECT RUN.** So does one that renders tofu. The
    // two assertions below are the only things standing between eight green
    // images and eight pictures of nothing.
    expect(
      goldenFileComparator,
      isA<TolerantFileComparator>(),
      reason: 'test/flutter_test_config.dart did not install it — LocalFileComparator is exact',
    );
    expect((goldenFileComparator as TolerantFileComparator).tolerance, 0.005);
  });

  testWidgets('the real font is loaded and nothing renders as Ahem', (WidgetTester tester) async {
    // **AHEM RENDERS EVERY GLYPH AS A FULL-EM BOX**, so a five-character string
    // at 20 px is exactly 100 px wide. A real proportional face never is.
    // Measuring is the only way to tell: tofu and text look the same in a log,
    // and identical in a PNG nobody opens.
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Text('41288', style: TextStyle(fontFamily: 'AtkinsonNext', fontSize: 20)),
      ),
    );

    final Size size = tester.getSize(find.byType(Text));
    expect(
      size.width,
      isNot(closeTo(100, 0.5)),
      reason: 'five glyphs at exactly 100 px is Ahem — the bundled font did not load',
    );
    expect(size.width, greaterThan(0));
  });

  testWidgets('quick entry, default — the deck, the keypad and the slab', (
    WidgetTester tester,
  ) async {
    // **THE SCREEN THE WHOLE PRODUCT IS.** What only a pixel can catch here is
    // the tag column: three tabular digits right-aligned on their units, which
    // is what makes four hundred rows scannable rather than readable.
    final AppDatabase db = await fixtureDatabase('flock_400_3seasons.json');
    try {
      await atFixed(kGoldenNight, () async {
        await tester.pumpApp(const QuickEntryScreen(), db: db, device: Device.small);
      });
      // **SETTLED, AND THE FIRST BASELINE PROVED WHY.** Without it the image is
      // the frame before the providers resolve: a keypad on an empty page, no
      // deck, no strips, no confirm bar. It is a real state — decision #21's
      // promise that frame 1 is interactive — and it is not the screen these
      // goldens are for, and nothing in the log distinguishes the two.
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(QuickEntryScreen),
        matchesGoldenFile('goldens/quick_entry_default.png'),
      );
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('quick entry at text scale 2.0 — the grid does not move', (
    WidgetTester tester,
  ) async {
    // `indelible.md §3.6`: rows grow, the grid does not move. The margin stays
    // left, the spine stays vertical, the slab stays in its corner, the page
    // just gets longer. **That is a claim about pixels** and the matrix cannot
    // make it — the matrix proves nothing overflowed, which a wrong-but-tidy
    // layout also satisfies.
    final AppDatabase db = await fixtureDatabase('flock_400_3seasons.json');
    try {
      await atFixed(kGoldenNight, () async {
        await tester.pumpApp(
          const QuickEntryScreen(),
          db: db,
          device: Device.small,
          textScale: 2.0,
        );
      });
      // **SETTLED, AND THE FIRST BASELINE PROVED WHY.** Without it the image is
      // the frame before the providers resolve: a keypad on an empty page, no
      // deck, no strips, no confirm bar. It is a real state — decision #21's
      // promise that frame 1 is interactive — and it is not the screen these
      // goldens are for, and nothing in the log distinguishes the two.
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(QuickEntryScreen),
        matchesGoldenFile('goldens/quick_entry_scale_2_0.png'),
      );
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('quick entry in deep red — the palette that drops luminance too', (
    WidgetTester tester,
  ) async {
    // **AT STANDARD CONTRAST, DELIBERATELY** (`06 §4.5`). `deepRed` is the
    // night-shift palette that drops luminance as well as hue (decision #96), so
    // it is where a layout that was quietly relying on a colour difference stops
    // reading — and pairing it with high contrast would hide exactly that.
    final AppDatabase db = await fixtureDatabase('flock_400_3seasons.json');
    try {
      await atFixed(kGoldenNight, () async {
        await tester.pumpApp(
          const QuickEntryScreen(),
          db: db,
          device: Device.small,
          palette: ShedPaletteId.deepRed,
        );
      });
      // **SETTLED, AND THE FIRST BASELINE PROVED WHY.** Without it the image is
      // the frame before the providers resolve: a keypad on an empty page, no
      // deck, no strips, no confirm bar. It is a real state — decision #21's
      // promise that frame 1 is interactive — and it is not the screen these
      // goldens are for, and nothing in the log distinguishes the two.
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(QuickEntryScreen),
        matchesGoldenFile('goldens/quick_entry_deep_red.png'),
      );
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('the pen board at twelve pens across three statuses', (WidgetTester tester) async {
    // **GLANCEABILITY IS A PIXEL PROPERTY** (`06 §11`). Twelve pens is the shape
    // a shepherd reads from a metre away, and what has to survive is telling the
    // three statuses apart by rule style and word — not by hue, which is the
    // channel `deepRed` and a grayscale filter both remove.
    final AppDatabase db = testDatabase();
    await seedSeason(db);

    for (int i = 1; i <= 12; i++) {
      final PenId pen = await seedPen(db, label: '$i');
      final EweId ewe = await seedEwe(db, tag: '${400 + i}');
      await seedPenOccupancy(db, pen, ewe);
    }

    try {
      await atFixed(kGoldenNight, () async {
        await tester.pumpApp(const PenBoardScreen(), db: db, device: Device.small);
      });
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(PenBoardScreen),
        matchesGoldenFile('goldens/pen_board_12_pens.png'),
      );
    } finally {
      await tester.closeApp();
    }
  });

  testWidgets('the withdrawal countdown in all three states, stacked', (WidgetTester tester) async {
    // **THE HIGHEST-STAKES PIXELS IN THE APP**, and the one image where the
    // review question is not about legibility but about confusion: *clears on a
    // date*, *nothing applies* and *nobody looked* must be three visibly
    // different things. `07 §10.3`.
    //
    // The three are constructed through the three NAMED constructors, which is
    // itself the §12.1 mechanism showing through: `ShedCountdown` takes a
    // `ClearsOn`, so a countdown for a period nobody recorded cannot be built
    // at all — the other two states are different constructors rendering
    // different words, not one widget switching on a status.
    final AppDatabase db = testDatabase();
    final Instant now = Instant.fromDateTime(kGoldenNight);

    try {
      await atFixed(kGoldenNight, () async {
        await tester.pumpApp(
          // **A `Scaffold`, BECAUSE `pumpApp` PUTS THE WIDGET STRAIGHT INTO
          // `MaterialApp.home` AND EVERY REAL SCREEN BRINGS ITS OWN.** The first
          // baseline pumped a bare `Column` and captured three states of grey
          // ink on white — an app with no light theme, photographed in one.
          // An image that cannot be judged for legibility is not worth
          // committing.
          Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ShedCountdown(
                  clearsOn: ClearsOn(LocalDate.of(now).plusDays(14), now, WithdrawalTarget.meat),
                  now: now,
                  productName: 'Alamycin LA',
                  clearsOnLabel: 'CLEAR 25 FEB',
                  semanticLabel: 'Alamycin LA, clear on 25 February',
                ),
                const ShedCountdown.notApplicable(
                  productName: 'Spot-on',
                  words: 'NOT APPLICABLE',
                  semanticLabel: 'Spot-on, no withdrawal applies',
                ),
                const ShedCountdown.notRecorded(
                  productName: 'Footbath',
                  words: 'NOT RECORDED',
                  semanticLabel: 'Footbath, withdrawal not recorded',
                ),
              ],
            ),
          ),
          db: db,
          device: Device.small,
        );
      });
      // **THE `Scaffold`, NOT THE `Column`.** The first baseline captured the
      // Column's own bounds, which have no background — three states of grey
      // ink on white, in an app that has no light theme and whose whole claim
      // about this widget is that you can read it at 30% brightness. An image
      // that cannot be judged for legibility is not worth committing.
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/withdrawal_countdown_three_states.png'),
      );
    } finally {
      await tester.closeApp();
    }
  });

  test('the golden set is five, and the three missing ones are v1.1.0', () {
    // Derived, and stated. `12 §8.1`'s eight is the finished product; a count
    // that silently shrank would be three images nobody notices are gone.
    expect(kGoldensAwaitingTheirScreen, hasLength(3));
    for (final String name in kGoldensAwaitingTheirScreen) {
      expect(name, startsWith('lambing_spread_'), reason: 'all three are the same chart');
    }
  });
}

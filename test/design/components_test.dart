// test/design/components_test.dart — the component inventory.
//
// ONE FILE FOR THE WHOLE EPIC. Each of N10's eight tasks extends this file
// rather than adding a ninth; `_pumpComponent` below is the shared helper all of
// them use, and it is a private top-level function here rather than a thirteenth
// file in test/support/, because 12 §5.3 closes that list.
//
// No sweep. These are component cases, not screen cases — N33-T02 and N33-T03
// own the sweeps over kPumpableVariants, which does not exist until N12-T05.
library;

import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/ui/components/shed_confirm_bar.dart';
import 'package:shed_book/core/ui/components/shed_destructive_button.dart';
import 'package:shed_book/core/ui/components/shed_primary_button.dart';
import 'package:shed_book/core/ui/components/shed_recents_strip.dart';
import 'package:shed_book/core/ui/components/shed_secondary_button.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/palettes.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/core/ui/theme.dart';

/// Pumps one component inside a real theme.
///
/// A real theme is not optional: every component reads `context.tokens`, and the
/// accessor ends in `!` — a bare `MaterialApp` throws a null check on a widget
/// deep in the tree with a message that never mentions tokens.
///
/// [scale] and [boldText] exist because the anchor runs at 200% with Bold Text
/// on. Decision #99 says never clamp, so a 200% user is a real user, and the
/// framework's bold-text merge is exactly what a hand-built `TextStyle` would
/// silently drop.
Future<void> _pumpComponent(
  WidgetTester tester,
  Widget component, {
  double scale = 1.0,
  bool boldText = false,
  ShedPalette palette = nightPalette,
}) => tester.pumpWidget(
  MaterialApp(
    theme: buildShedTheme(palette),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale), boldText: boldText),
      child: Scaffold(body: Center(child: component)),
    ),
  ),
);

String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

ShedPrimaryButton _slab({
  ShedPrimaryButtonState state = ShedPrimaryButtonState.ready,
  String label = '+ LAMB',
}) => ShedPrimaryButton(label: label, onTap: () {}, semanticLabel: 'Add a lamb', state: state);

void main() {
  const String file = 'lib/core/ui/components/shed_primary_button.dart';

  testWidgets('ShedPrimaryButton renders at textScale 2.0 with boldText, has a '
      'semanticLabel, and no dimension below 64', (WidgetTester tester) async {
    // THE ANCHOR, and it runs at the hard end of the range on purpose: 200% text
    // with Bold Text on is where a slab either holds its box or overflows.
    final SemanticsHandle handle = tester.ensureSemantics();

    await _pumpComponent(tester, _slab(), scale: 2.0, boldText: true);

    expect(tester.takeException(), isNull, reason: 'the slab overflowed or threw');

    final Rect rect = tester.getRect(find.byType(ShedPrimaryButton));
    expect(rect.height, greaterThanOrEqualTo(88.0), reason: 'tapHero');
    expect(rect.width, greaterThanOrEqualTo(144.0), reason: '2 x tapPrimary');
    expect(rect.shortestSide, greaterThanOrEqualTo(64.0), reason: "indelible.md §4.5's build box");

    final SemanticsNode node = tester.getSemantics(find.byType(ShedTapTarget));
    expect(node.label, isNotEmpty);

    handle.dispose();
  });

  testWidgets('the slab is one ShedTapTarget and the gates can find it', (
    WidgetTester tester,
  ) async {
    // N33's two sweeps find targets BY TYPE. A control built on a bare InkWell
    // is invisible to every one of them — it would pass this epic and vanish
    // from the geometric gate, silently, forever.
    await _pumpComponent(tester, _slab());
    expect(find.byType(ShedTapTarget), findsOneWidget);
  });

  testWidgets('every ShedPrimaryButtonState exposes SemanticsAction.tap', (
    WidgetTester tester,
  ) async {
    // THE EXECUTABLE FORM OF "NEVER REFUSES A PRESS", including `refusing`
    // itself. indelible.md §7.1: still a target — pressing it opens the tag
    // sheet rather than doing nothing.
    final SemanticsHandle handle = tester.ensureSemantics();

    for (final ShedPrimaryButtonState state in ShedPrimaryButtonState.values) {
      await _pumpComponent(tester, _slab(state: state));
      final SemanticsData data = tester.getSemantics(find.byType(ShedTapTarget)).getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue, reason: '$state');
      expect(data.flagsCollection.isEnabled, Tristate.isTrue, reason: '$state');
    }

    handle.dispose();
  });

  testWidgets('the refusing state changes the label and the outline, never the '
      'enabled flag', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await _pumpComponent(tester, _slab(label: '+ LAMB'));
    final Rect ready = tester.getRect(find.byType(ShedPrimaryButton));

    await _pumpComponent(tester, _slab(state: ShedPrimaryButtonState.refusing, label: 'TAG FIRST'));

    final SemanticsData data = tester.getSemantics(find.byType(ShedTapTarget)).getSemanticsData();
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    expect(find.text('TAG FIRST'), findsOneWidget);
    expect(find.text('+ LAMB'), findsNothing);

    // Same box. The state changes the verb and the outline, not the geometry —
    // a slab that resized as it refused would move under a thumb already in
    // flight.
    expect(tester.getRect(find.byType(ShedPrimaryButton)).size, ready.size);

    handle.dispose();
  });

  testWidgets('a press changes fill and nothing else', (WidgetTester tester) async {
    // Catches an AnimatedScale or a Transform added later. indelible.md §5.1: a
    // press is a fill change only — "a target that shrinks under a cold thumb is
    // a target you miss".
    await _pumpComponent(tester, _slab());
    final Rect before = tester.getRect(find.byType(ShedPrimaryButton));

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(ShedPrimaryButton)),
    );
    await tester.pump(const Duration(milliseconds: 40));

    expect(tester.getRect(find.byType(ShedPrimaryButton)), before);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('the label goes through labelLarge and never a constructed TextStyle', (
    WidgetTester tester,
  ) async {
    // 06 §5.4's silent failure: a fresh TextStyle drops fontFeatures, and the
    // pen board starts jittering as 412 and 108 take different widths.
    late TextStyle expected;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildShedTheme(nightPalette),
        home: Builder(
          builder: (BuildContext context) {
            expected = Theme.of(context).textTheme.labelLarge!;
            return Scaffold(body: Center(child: _slab()));
          },
        ),
      ),
    );

    final Text text = tester.widget<Text>(find.text('+ LAMB'));
    expect(text.style!.fontSize, expected.fontSize);
    expect(text.style!.fontWeight, expected.fontWeight);
    expect(text.style!.fontFamily, expected.fontFamily);
  });

  testWidgets('no dimension shrinks between textScale 1.0, 1.3 and 2.0', (
    WidgetTester tester,
  ) async {
    // A box that shrinks as text grows is the FittedBox bug wearing a different
    // hat.
    Size? previous;
    for (final double scale in <double>[1.0, 1.3, 2.0]) {
      await _pumpComponent(tester, _slab(), scale: scale);
      final Size size = tester.getSize(find.byType(ShedPrimaryButton));
      if (previous != null) {
        expect(size.width, greaterThanOrEqualTo(previous.width), reason: 'scale $scale');
        expect(size.height, greaterThanOrEqualTo(previous.height), reason: 'scale $scale');
      }
      previous = size;
    }
  });

  test('ShedPrimaryButton constructs with no nullable onTap', () {
    // THE NARROWING IS THE FEATURE. ShedTapTarget takes VoidCallback? and sets
    // Semantics(enabled: onTap != null); passing null here would announce a
    // disabled button, make 06 §6.3's geometric gate SKIP it, and leave a
    // shepherd tapping a live-looking rectangle that does nothing.
    final String source = _declarations(file);
    expect(source, contains('required this.onTap'));
    expect(source, contains('final VoidCallback onTap;'));
    expect(source, isNot(contains('VoidCallback?')));
    expect(source, isNot(contains('onTap: null')));
  });

  test('the component file contains no colorScheme, no raw colour and no literal fontSize', () {
    // The gate proves this repo-wide; this case is what tells you WHICH
    // component broke it. The raw-colour needle is split across two adjacent
    // literals so this file does not fire on itself.
    const String rawColour =
        'Color'
        '(0x';
    final String source = _declarations(file);

    expect(source, isNot(contains('colorScheme')));
    expect(source, isNot(contains(rawColour)));
    expect(source, isNot(matches(RegExp(r'fontSize:\s*[0-9]'))));
  });

  test('the file imports no provider, no localisation and nothing under lib/data', () {
    // Layer rule 7 lists what lib/core/ui/ may import, and a component file is
    // where the first violation gets introduced — a widget that reaches for a
    // provider is a widget that cannot be pumped without a ProviderScope.
    final String imports = _declarations(
      file,
    ).split('\n').where((String l) => l.trimLeft().startsWith('import ')).join('\n');

    for (final String forbidden in <String>['riverpod', 'l10n', 'data/', 'drift']) {
      expect(imports, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  // -------------------------------------------------------------------------
  // N10-T02 — ShedSecondaryButton and ShedDestructiveButton
  // -------------------------------------------------------------------------

  const String secondaryFile = 'lib/core/ui/components/shed_secondary_button.dart';
  const String destructiveFile = 'lib/core/ui/components/shed_destructive_button.dart';

  ShedDestructiveButton striker(VoidCallback onConfirmed) => ShedDestructiveButton(
    label: 'STRIKE',
    confirmLabel: 'STRIKE — TAP AGAIN',
    onConfirmed: onConfirmed,
    semanticLabel: 'Strike this record',
    confirmSemanticLabel: 'Strike this record, tap again to confirm',
  );

  testWidgets('ShedDestructiveButton requires two taps and is separated by '
      'gapDestructive from any other target', (WidgetTester tester) async {
    // THE ANCHOR, and the separation half is the one a screen cannot get wrong:
    // the widget reserves the gap inside its OWN box, so a flush neighbour is
    // geometrically impossible rather than merely discouraged.
    int struck = 0;
    await _pumpComponent(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          striker(() => struck++),
          ShedPrimaryButton(label: 'NEIGHBOUR', onTap: () {}, semanticLabel: 'Neighbour'),
        ],
      ),
    );

    await tester.tap(find.text('STRIKE'));
    await tester.pump();
    expect(struck, 0, reason: 'the first tap arms and writes nothing');

    await tester.tap(find.text('STRIKE — TAP AGAIN'));
    await tester.pump();
    expect(struck, 1);

    final Rect target = tester.getRect(find.byType(ShedTapTarget).first);
    final Rect neighbour = tester.getRect(find.byType(ShedPrimaryButton));
    expect(
      neighbour.top - target.bottom,
      greaterThanOrEqualTo(32.0),
      reason: 'gapDestructive is not reserved inside the widget box',
    );
  });

  testWidgets('tapping ShedDestructiveButton twice in the same frame strikes once', (
    WidgetTester tester,
  ) async {
    // 00-README §8 step 28's literal case: two taps with NO pump between them —
    // the fast thumb, not the deliberate second press.
    //
    // MEASURED: it strikes EXACTLY ONCE, and that is pinned rather than left as
    // `lessThanOrEqualTo(1)`, because a range hides which of the two answers the
    // widget actually gives.
    //
    // One, not zero, and that is the right answer. setState mutates _state
    // immediately, so the second tap sees `confirming` even though no frame was
    // painted in between — the shepherd pressed twice, which IS the
    // confirmation. Requiring them to have SEEN the changed label would need a
    // minimum dwell, i.e. a timer, and this component bans timers for a stronger
    // reason: a state that unwinds itself changes under a thumb already moving.
    // A mistaken strike is recoverable — undo is a time-boxed strike in the
    // row's own margin.
    //
    // What this case actually guards is TWO: a naive implementation that read
    // the state from a rebuilt widget rather than from the State object would
    // fire onConfirmed on both taps.
    int struck = 0;
    await _pumpComponent(tester, striker(() => struck++));

    await tester.tap(find.byType(ShedTapTarget));
    await tester.tap(find.byType(ShedTapTarget));
    await tester.pump();

    expect(struck, 1, reason: 'a double tap must strike once — never twice, never zero');
  });

  testWidgets('the confirming state changes the label, not only the colour', (
    WidgetTester tester,
  ) async {
    // Decision #106 in one assertion. Somebody who cannot tell the madder ink
    // from the outline still reads a different word.
    await _pumpComponent(tester, striker(() {}));
    expect(find.text('STRIKE'), findsOneWidget);

    await tester.tap(find.byType(ShedTapTarget));
    await tester.pump();

    expect(find.text('STRIKE — TAP AGAIN'), findsOneWidget);
    expect(find.text('STRIKE'), findsNothing);
  });

  testWidgets('confirming reverts on dispose and never on a timer', (WidgetTester tester) async {
    // A state that unwinds after n seconds changes under a thumb already moving:
    // the shepherd reads TAP AGAIN, commits to the press, and the control
    // reverts between the decision and the contact.
    await _pumpComponent(tester, striker(() {}));
    await tester.tap(find.byType(ShedTapTarget));
    await tester.pump();
    expect(find.text('STRIKE — TAP AGAIN'), findsOneWidget);

    // Thirty seconds, still mounted: unchanged.
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('STRIKE — TAP AGAIN'), findsOneWidget);

    // Pumped away and back: armed again.
    await _pumpComponent(tester, const SizedBox.shrink());
    await _pumpComponent(tester, striker(() {}));
    expect(find.text('STRIKE'), findsOneWidget);

    final String source = _declarations(destructiveFile);
    expect(source, isNot(contains('Timer')));
    expect(source, isNot(contains('Future.delayed')));
  });

  testWidgets('ShedDestructiveButton renders no filled surface behind the madder ink', (
    WidgetTester tester,
  ) async {
    // indelible.md §7.13. A destructive control that fills is one that draws the
    // eye, and this one is meant to be found only when looked for.
    await _pumpComponent(tester, striker(() {}));

    final Iterable<DecoratedBox> boxes = tester.widgetList<DecoratedBox>(
      find.descendant(of: find.byType(ShedDestructiveButton), matching: find.byType(DecoratedBox)),
    );
    for (final DecoratedBox box in boxes) {
      expect((box.decoration as BoxDecoration).color, isNull, reason: 'a fill appeared');
    }
  });

  testWidgets('ShedSecondaryButton is at least tapPrimary tall in both forms', (
    WidgetTester tester,
  ) async {
    for (final ShedSecondaryButtonForm form in ShedSecondaryButtonForm.values) {
      for (final double scale in <double>[1.0, 1.3, 2.0]) {
        await _pumpComponent(
          tester,
          ShedSecondaryButton(label: 'EWES', onTap: () {}, semanticLabel: 'Ewes', form: form),
          scale: scale,
        );
        expect(
          tester.getSize(find.byType(ShedSecondaryButton)).height,
          greaterThanOrEqualTo(72.0),
          reason: '$form at $scale',
        );
      }
    }
  });

  testWidgets('ShedSecondaryButton renders at textScale 2.0 with boldText and every tap '
      'surface carries a semanticLabel', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await _pumpComponent(
      tester,
      ShedSecondaryButton(label: 'EWES', onTap: () {}, semanticLabel: 'Ewes'),
      scale: 2.0,
      boldText: true,
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSemantics(find.byType(ShedTapTarget)).label, 'Ewes');

    handle.dispose();
  });

  testWidgets('the inStream form draws an underline and no border, and outlined draws a '
      'border and no underline', (WidgetTester tester) async {
    // The two forms are distinguishable with the colour channel removed.
    BoxDecoration decorationOf(ShedSecondaryButtonForm form) {
      final DecoratedBox box = tester.widget<DecoratedBox>(
        find
            .descendant(of: find.byType(ShedSecondaryButton), matching: find.byType(DecoratedBox))
            .first,
      );
      return box.decoration as BoxDecoration;
    }

    await _pumpComponent(
      tester,
      ShedSecondaryButton(label: 'EWES', onTap: () {}, semanticLabel: 'Ewes'),
    );
    final BoxDecoration outlined = decorationOf(ShedSecondaryButtonForm.outlined);
    expect(outlined.border, isA<Border>());
    expect((outlined.border! as Border).top.width, greaterThan(0));
    expect(outlined.color, isNotNull, reason: 'outlined carries a fill');

    await _pumpComponent(
      tester,
      ShedSecondaryButton(
        label: 'EWES',
        onTap: () {},
        semanticLabel: 'Ewes',
        form: ShedSecondaryButtonForm.inStream,
      ),
    );
    final BoxDecoration inStream = decorationOf(ShedSecondaryButtonForm.inStream);
    expect(inStream.color, isNull, reason: 'inStream carries no fill');
    expect((inStream.border! as Border).top, BorderSide.none);
    expect((inStream.border! as Border).bottom.width, greaterThan(0));
  });

  testWidgets('selected lifts the underline ink and leaves the siblings alone', (
    WidgetTester tester,
  ) async {
    await _pumpComponent(
      tester,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final String label in <String>['ALL', 'EWES', 'LAMBS'])
            ShedSecondaryButton(
              label: label,
              onTap: () {},
              semanticLabel: label,
              form: ShedSecondaryButtonForm.inStream,
              selected: label == 'EWES',
            ),
        ],
      ),
    );

    final ShedTokens t = buildShedTheme(nightPalette).extension<ShedTokens>()!;
    final Iterable<Text> texts = tester.widgetList<Text>(
      find.descendant(of: find.byType(ShedSecondaryButton), matching: find.byType(Text)),
    );

    expect(
      texts.where((Text x) => x.style!.color == t.textPrimary).length,
      1,
      reason: 'exactly one sibling is selected',
    );
  });

  test('neither file names delete, remove, splice or hidden', () {
    // indelible.md §11 test 1, made mechanical: nothing in this product is
    // deleted, and a component that says so teaches the wrong verb to every
    // screen that reads it.
    for (final String file in <String>[secondaryFile, destructiveFile]) {
      final String source = _declarations(file).toLowerCase();
      for (final String word in <String>['delete', 'remove', 'splice', 'hidden']) {
        expect(source, isNot(contains(word)), reason: '$file says $word');
      }
    }
  });

  test('neither file calls showDialog( or constructs an AlertDialog', () {
    // ui.show_dialog allowlists two Settings files and neither is here. The
    // whole reason `confirming` is a STATE of this component is so a screen
    // never needs a modal to get a confirmation.
    for (final String file in <String>[secondaryFile, destructiveFile]) {
      final String source = _declarations(file);
      expect(source, isNot(contains('showDialog')), reason: file);
      expect(source, isNot(contains('AlertDialog')), reason: file);
    }
  });

  // -------------------------------------------------------------------------
  // N10-T03 — ShedConfirmBar and ShedRecentsStrip
  // -------------------------------------------------------------------------

  ShedRecentsEntry entry(String tag) => ShedRecentsEntry(
    tag: tag,
    summary: 'penned 2h',
    semanticLabel: 'Ewe $tag, penned 2 hours ago',
    onTap: () {},
  );

  List<ShedRecentsEntry> entries(int n) => <ShedRecentsEntry>[
    for (int i = 0; i < n; i++) entry('${400 + i}'),
  ];

  testWidgets('ShedRecentsStrip occupies the same height empty and full', (
    WidgetTester tester,
  ) async {
    // THE ANCHOR. A strip that grows as it fills moves the slab under a thumb
    // already in flight — so all four states, at three text scales, are one
    // height.
    for (final double scale in <double>[1.0, 1.3, 2.0]) {
      final List<double> heights = <double>[];
      for (final List<ShedRecentsEntry>? state in <List<ShedRecentsEntry>?>[
        null,
        const <ShedRecentsEntry>[],
        entries(2),
        entries(6),
      ]) {
        await _pumpComponent(
          tester,
          ShedRecentsStrip(entries: state, emptyLabel: 'No recent animals.'),
          scale: scale,
        );
        heights.add(tester.getSize(find.byType(ShedRecentsStrip)).height);
      }
      expect(heights.toSet(), hasLength(1), reason: 'scale $scale gave heights $heights');
      expect(heights.first, greaterThanOrEqualTo(72.0), reason: 'tapPrimary at scale $scale');
    }
  });

  testWidgets('a null entry list renders the frame-1 placeholder and an empty list '
      'renders the empty copy', (WidgetTester tester) async {
    // THE DAY-ONE BUG, CAUGHT. Frame 1 has not read the database; an empty list
    // means it was read and there is nothing in it. Collapsing the two tells a
    // shepherd on day one that the app lost their flock.
    await _pumpComponent(
      tester,
      const ShedRecentsStrip(entries: null, emptyLabel: 'No recent animals.', placeholderLabel: ''),
    );
    expect(find.text('No recent animals.'), findsNothing);

    await _pumpComponent(
      tester,
      const ShedRecentsStrip(entries: <ShedRecentsEntry>[], emptyLabel: 'No recent animals.'),
    );
    expect(find.text('No recent animals.'), findsOneWidget);
  });

  testWidgets('nine entries render six', (WidgetTester tester) async {
    // maxEntries held IN THE LAYOUT, not only in an assert — an assert is
    // stripped in release, which is the build where nobody is watching.
    await _pumpComponent(
      tester,
      ShedRecentsStrip(entries: entries(9), emptyLabel: 'No recent animals.'),
    );
    expect(find.byType(ShedTapTarget), findsNWidgets(ShedRecentsStrip.maxEntries));
    expect(ShedRecentsStrip.maxEntries, 6);
  });

  testWidgets('every recents entry is a ShedTapTarget at least tapPrimary tall with a '
      'semanticLabel', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await _pumpComponent(
      tester,
      ShedRecentsStrip(entries: entries(6), emptyLabel: 'No recent animals.'),
    );

    final Finder targets = find.byType(ShedTapTarget);
    expect(targets, findsNWidgets(6));
    for (int i = 0; i < 6; i++) {
      expect(tester.getSize(targets.at(i)).height, greaterThanOrEqualTo(72.0), reason: 'entry $i');
      expect(tester.getSemantics(targets.at(i)).label, isNotEmpty, reason: 'entry $i');
    }

    handle.dispose();
  });

  testWidgets('adjacent recents entries are gapMin apart or touching', (WidgetTester tester) async {
    // 0 or >= 16, never 4. Two targets 4 pt apart read as one wide target to a
    // cold thumb, and the shepherd hits the wrong ewe.
    await _pumpComponent(
      tester,
      ShedRecentsStrip(entries: entries(4), emptyLabel: 'No recent animals.'),
    );

    final Finder targets = find.byType(ShedTapTarget);
    for (int i = 1; i < 4; i++) {
      final double gap =
          tester.getRect(targets.at(i)).left - tester.getRect(targets.at(i - 1)).right;
      expect(gap == 0 || gap >= 16.0, isTrue, reason: 'entries $i and ${i - 1} are $gap apart');
    }
  });

  testWidgets('ShedConfirmBar is full width and tapHero tall', (WidgetTester tester) async {
    for (final double scale in <double>[1.0, 1.3, 2.0]) {
      await _pumpComponent(
        tester,
        ShedConfirmBar(outcomeLabel: 'Create 412', onTap: () {}, semanticLabel: 'Create ewe 412'),
        scale: scale,
      );
      final Size size = tester.getSize(find.byType(ShedConfirmBar));
      expect(size.height, greaterThanOrEqualTo(88.0), reason: 'scale $scale');
      expect(size.width, 800.0, reason: 'full width at scale $scale');
    }
  });

  test('ShedConfirmBar refuses OK, Done, Confirm, Submit and Save as its label', () {
    // indelible.md §11 test 7 and 06 §8.2. At 03:20 a shepherd reading "OK" has
    // to reconstruct what they are agreeing to from memory, and the whole point
    // of the bar is that they do not have to.
    //
    // Case- and whitespace-insensitive, so `ok` and ` OK ` are caught too.
    for (final String banned in <String>['OK', 'ok', ' Done ', 'Confirm', 'SUBMIT', 'Save']) {
      expect(
        () => ShedConfirmBar(outcomeLabel: banned, onTap: () {}, semanticLabel: 'x'),
        throwsAssertionError,
        reason: banned,
      );
    }

    // And an outcome label is accepted.
    expect(
      () => ShedConfirmBar(outcomeLabel: 'Create 412', onTap: () {}, semanticLabel: 'x'),
      returnsNormally,
    );
  });

  testWidgets('ShedConfirmBar renders the outcome text verbatim', (WidgetTester tester) async {
    // No truncation, no FittedBox (type.fitted_box bans it anyway), no ellipsis
    // at 200%. A truncated outcome is a shepherd agreeing to something they
    // cannot read.
    await _pumpComponent(
      tester,
      ShedConfirmBar(
        outcomeLabel: '7 days — as entered by you',
        onTap: () {},
        semanticLabel: 'Withdrawal 7 days as entered by you',
      ),
      scale: 2.0,
    );

    expect(find.text('7 days — as entered by you'), findsOneWidget);
    final Text text = tester.widget<Text>(find.text('7 days — as entered by you'));
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    expect(text.maxLines, isNull);
  });

  test('neither component constructs a CircularProgressIndicator', () {
    // Covers the hole ui.spinner's lib/features/ scope leaves. There is no
    // spinner in this product: frame 1 shows the page colour and then the
    // records, and a spinner is a promise that something is happening off
    // screen.
    for (final String file in <String>[
      'lib/core/ui/components/shed_confirm_bar.dart',
      'lib/core/ui/components/shed_recents_strip.dart',
    ]) {
      final String source = _declarations(file);
      expect(source, isNot(contains('CircularProgressIndicator')), reason: file);
      expect(source, isNot(contains('LinearProgressIndicator')), reason: file);
    }
  });

  test('neither component uses AnimatedSwitcher, AnimatedContainer or AnimatedOpacity', () {
    // indelible.md §5.2. Nothing on these two animates: the strip changing
    // content under a thumb is worse than the strip changing instantly.
    for (final String file in <String>[
      'lib/core/ui/components/shed_confirm_bar.dart',
      'lib/core/ui/components/shed_recents_strip.dart',
    ]) {
      final String source = _declarations(file);
      for (final String banned in <String>[
        'AnimatedSwitcher',
        'AnimatedContainer',
        'AnimatedOpacity',
        'AnimatedAlign',
      ]) {
        expect(source, isNot(contains(banned)), reason: '$file uses $banned');
      }
    }
  });

  testWidgets('both components render at textScale 2.0 with boldText with no overflow', (
    WidgetTester tester,
  ) async {
    await _pumpComponent(
      tester,
      ShedConfirmBar(outcomeLabel: 'Create 412', onTap: () {}, semanticLabel: 'Create ewe 412'),
      scale: 2.0,
      boldText: true,
    );
    expect(tester.takeException(), isNull, reason: 'ShedConfirmBar overflowed');

    await _pumpComponent(
      tester,
      ShedRecentsStrip(entries: entries(3), emptyLabel: 'No recent animals.'),
      scale: 2.0,
      boldText: true,
    );
    expect(tester.takeException(), isNull, reason: 'ShedRecentsStrip overflowed');
  });
}

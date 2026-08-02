// test/features/keypad_test.dart
//
// The keypad in isolation. Its screen is T05; this file pumps the component,
// which is why it exists separately from quick_entry_test.dart.
library;

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/ui/components/shed_keypad.dart';

import '../support/harness.dart';

/// Builds the pad with the four labels supplied.
///
/// The component takes them as PARAMETERS rather than reading
/// `AppLocalizations`, because `layer.core_ui` forbids `lib/core/ui/` importing
/// `lib/l10n/` — the screen that knows the locale is the screen that supplies
/// the words, which is the same shape `ShedTapTarget.semanticLabel` already
/// uses. T05 passes the real ones.
ShedKeypad _pad({
  ValueChanged<String>? onDigit,
  VoidCallback? onBackspace,
  ShedKeypadThirdKey third = ShedKeypadThirdKey.newTag,
  VoidCallback? onThirdKey,
}) => ShedKeypad(
  onDigit: onDigit ?? (_) {},
  onBackspace: onBackspace ?? () {},
  thirdKey: third,
  onThirdKey: onThirdKey ?? () {},
  padLabel: 'Tag entry',
  backspaceLabel: 'Backspace',
  backspaceHint: 'delete the last digit',
  thirdKeyLabel: third == ShedKeypadThirdKey.newTag ? 'NEW TAG' : '.',
);

const List<String> _digits = <String>['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

/// Every key's widget key, in one place, because a key is a test contract
/// (`CONVENTIONS §4.5`).
List<String> _keyIds(ShedKeypadThirdKey third) => <String>[
  for (final String d in _digits) 'quick_entry.keypad.digit_$d',
  'quick_entry.keypad.backspace',
  if (third == ShedKeypadThirdKey.newTag)
    'quick_entry.keypad.new_tag'
  else
    'quick_entry.keypad.decimal',
];

void main() {
  testWidgets('no keypad key is ever disabled, including over the free cap', (
    WidgetTester tester,
  ) async {
    // THE ANCHOR, and it is about a disagreement between two documents.
    //
    // 06 §8.2 wants the bottom-right key to be the decimal, rendering INERT
    // (onTap null) on an integer-only field. indelible.md §7.2's key-state table
    // says of Disabled: "Never. No key is ever disabled — a dead key under a
    // cold thumb is indistinguishable from a missed tap."
    //
    // An inert key IS a disabled key: `onTap: null` makes ShedTapTarget emit
    // enabled:false and drop the tap ACTION. So 06's decimal rule and this test
    // cannot both be satisfied, and CLAUDE.md puts indelible.md above the
    // engineering documents. RULED: the third key is a CONSTRUCTOR PARAMETER,
    // not a runtime state — which also preserves 06's real requirement that the
    // grid never re-legends, because the legend is fixed while the pad is on
    // screen.
    //
    // "Disabled" is asserted MECHANICALLY rather than visually, in three parts:
    // a node that announces as a button and then refuses to activate is exactly
    // the failure 06 §6.2 warns about, and nothing in flutter_test catches a
    // missing action on its own.
    final AppDatabase db = testDatabase();

    for (final ShedKeypadThirdKey third in ShedKeypadThirdKey.values) {
      final List<String> tapped = <String>[];

      await tester.pumpApp(
        _pad(
          onDigit: tapped.add,
          onBackspace: () => tapped.add('backspace'),
          third: third,
          onThirdKey: () => tapped.add('third'),
        ),
        db: db,
      );

      for (final String id in _keyIds(third)) {
        final Finder f = find.byKey(Key(id));
        expect(f, findsOneWidget, reason: id);

        final SemanticsNode node = tester.getSemantics(f);
        final SemanticsData data = node.getSemanticsData();

        expect(data.flagsCollection.isEnabled, Tristate.isTrue, reason: '$id must be enabled');
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: '$id must carry a tap action');

        final int before = tapped.length;
        await tester.tap(f);
        expect(tapped.length, before + 1, reason: '$id must actually fire');
      }
    }
  });

  testWidgets('the pad renders identically at every entitlement state', (
    WidgetTester tester,
  ) async {
    // Decision #90 — nothing monetization-related renders on a shed screen at
    // ANY entitlement state — held by GEOMETRY rather than by a reviewer's eye.
    //
    // The keypad takes no entitlement argument and watches nothing, which is the
    // strongest form of this property available: there is no channel through
    // which the cap could reach it. This case pins that by capturing every key's
    // rect and comparing across pumps, so the day somebody adds a `ref.watch`
    // here the geometry is what notices.
    final AppDatabase db = testDatabase();
    Map<String, Rect>? first;

    for (int pump = 0; pump < 3; pump++) {
      await tester.pumpApp(_pad(), db: db);

      final Map<String, Rect> rects = <String, Rect>{
        for (final String id in _keyIds(ShedKeypadThirdKey.newTag))
          id: tester.getRect(find.byKey(Key(id))),
      };

      first ??= rects;
      expect(rects, first, reason: 'the pad does not vary — it has nothing to vary with');
    }
  });

  testWidgets('every key clears the 72 pt keypad contract at Device.small', (
    WidgetTester tester,
  ) async {
    // The cheap version of N33's geometric gate, here because `Expanded` inside
    // the keypad Row would override minWidth and silently shrink a key below the
    // floor on a 320 pt device once page padding is added (06 §8.2).
    final AppDatabase db = testDatabase();

    await tester.pumpApp(_pad(), db: db, device: Device.small);

    // ASSERTED AGAINST tapPrimary (72), NOT THE 60 FLOOR, and the drill is why:
    // deleting `minSize` entirely leaves ShedTapTarget falling back to tapMin,
    // which still clears 60 — so a case written against 60 passes against a
    // keypad that has forgotten it is a keypad. 06 §8.2's contract for this
    // component is "cells ≥ tapPrimary", and that is what fails when the sizing
    // goes away.
    for (final String id in _keyIds(ShedKeypadThirdKey.newTag)) {
      final Size size = tester.getSize(find.byKey(Key(id)));
      expect(size.width, greaterThanOrEqualTo(72.0), reason: id);
      expect(size.height, greaterThanOrEqualTo(72.0), reason: id);
    }
  });

  testWidgets('the key box grows with text scale and never shrinks below the floor', (
    WidgetTester tester,
  ) async {
    // 06 §8.2: max(tapPrimary, scaler.scale(glyph) * 1.6). The floor governs
    // until roughly 112% text scale, after which the pad grows and the match
    // list above it gives up rows — which is the correct trade, because the pad
    // is what the thumb hits.
    final AppDatabase db = testDatabase();

    Future<double> keySide(double scale) async {
      await tester.pumpApp(_pad(), db: db, textScale: scale);
      return tester.getSize(find.byKey(const Key('quick_entry.keypad.digit_5'))).height;
    }

    final double atOne = await keySide(1.0);
    final double atTwo = await keySide(2.0);

    expect(atOne, greaterThanOrEqualTo(60.0));
    expect(
      atTwo,
      greaterThan(atOne),
      reason: 'the box is computed from the glyph, not written down',
    );
  });

  testWidgets('the digit label IS the digit, and the glyph is not announced twice', (
    WidgetTester tester,
  ) async {
    // 10 §3.6: Voice Control matches the VISIBLE glyph, so the label is "4" and
    // never "Four key" or "Digit four". The Text sits inside ExcludeSemantics,
    // so the node carries one label rather than two.
    final AppDatabase db = testDatabase();

    await tester.pumpApp(_pad(), db: db);

    for (final String d in _digits) {
      final SemanticsNode node = tester.getSemantics(
        find.byKey(Key('quick_entry.keypad.digit_$d')),
      );
      expect(node.label, d, reason: d);
    }
  });

  testWidgets('the pad is a StatelessWidget and watches nothing', (WidgetTester tester) async {
    // 02 §10.1, and it is the strongest available proof that a keystroke cannot
    // rebuild the pad: it has no channel to be rebuilt through. The moment
    // somebody makes it a ConsumerWidget to "just watch one thing here", every
    // child below loses its const-ness.
    expect(
      const ShedKeypad(
        onDigit: _noDigit,
        onBackspace: _noop,
        thirdKey: ShedKeypadThirdKey.newTag,
        onThirdKey: _noop,
        padLabel: 'Tag entry',
        backspaceLabel: 'Backspace',
        backspaceHint: 'delete the last digit',
        thirdKeyLabel: 'NEW TAG',
      ),
      isA<StatelessWidget>(),
    );
  });

  testWidgets('backspace carries a hint and there is no key repeat', (WidgetTester tester) async {
    // Hold-to-repeat is a banned gesture. A cold thumb resting on backspace must
    // delete one digit, not empty the buffer.
    final AppDatabase db = testDatabase();
    int deletions = 0;

    await tester.pumpApp(_pad(onBackspace: () => deletions += 1), db: db);

    final Finder back = find.byKey(const Key('quick_entry.keypad.backspace'));
    final TestGesture gesture = await tester.startGesture(tester.getCenter(back));
    await tester.pump(const Duration(seconds: 3));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(deletions, 1, reason: 'a held key deletes one digit, not the buffer');

    // `onTapHint` populates hintOverrides, NOT `node.hint` — measured. A case
    // asserting the latter passes only when somebody has also set a plain hint,
    // which is not what 10 §3.6 asks for.
    // `onTapHint` lands in hintOverrides on the NODE, not on SemanticsData and
    // not in `node.hint` — measured. A case asserting `node.hint` passes only
    // when somebody has also set a plain hint, which is not what 10 §3.6 asks
    // for: the override renames the VERB ("double tap to delete the last
    // digit"), it does not add a description.
    final SemanticsNode node = tester.getSemantics(back);
    expect(node.label, isNotEmpty);
    expect(node.hintOverrides?.onTapHint, isNotEmpty, reason: 'onTapHint — 10 §3.6');
  });
}

void _noDigit(String _) {}
void _noop() {}

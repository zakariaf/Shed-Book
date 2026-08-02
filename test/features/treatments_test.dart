// test/features/treatments_test.dart
//
// Safety rule §12.1 from the screen's side. The repository makes the wrong row
// unwritable; these cases make the wrong answer un-preselectable.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/domain/withdrawal/withdrawal_period.dart';
import 'package:shed_book/features/treatments/widgets/withdrawal_control.dart';
import 'package:shed_book/features/treatments/widgets/withdrawal_disagreement.dart';

import '../support/harness.dart';

const WithdrawalLabels _labels = (
  heading: 'WITHDRAWAL — MEAT',
  enterDays: 'DAYS OFF THE BOTTLE',
  notApplicable: 'NONE APPLIES',
  notRecorded: 'NOT RECORDED',
  unit: 'days',
  padLabel: 'Withdrawal days',
  backspaceLabel: 'Backspace',
  backspaceHint: 'delete the last digit',
);

Future<void> _pumpControl(
  WidgetTester tester,
  AppDatabase db, {
  required void Function(WithdrawalPeriod) onChanged,
}) => tester.pumpApp(
  WithdrawalControl(target: WithdrawalTarget.meat, labels: _labels, onChanged: onChanged),
  db: db,
);

void main() {
  testWidgets('the withdrawal field renders no placeholder, no prefill and no default', (
    WidgetTester tester,
  ) async {
    // THE ANCHOR, AND IT HAS TWO HALVES.
    //
    // NO DIGIT ANYWHERE, asserted on RENDERED TEXT rather than on a widget's
    // private state (`12 §10.3`) — a field whose controller is empty but which
    // paints a grey `28` is exactly the failure, and only the rendered text
    // catches it.
    //
    // AND NONE OF THE THREE IS SELECTED. A control that pre-selects *not
    // recorded* is as wrong as one that pre-fills `28`: both make a decision the
    // shepherd did not make, and the second is the app originating a clinical
    // number, which `05 §7.3` forbids in one line.
    final AppDatabase db = testDatabase();
    final List<WithdrawalPeriod> emitted = <WithdrawalPeriod>[];

    await _pumpControl(tester, db, onChanged: emitted.add);
    await tester.pumpAndSettle();

    for (final Text t in tester.widgetList<Text>(find.byType(Text))) {
      expect(
        t.data ?? '',
        isNot(matches(RegExp(r'\d'))),
        reason: 'no digit is rendered before the shepherd types one',
      );
    }

    final Iterable<Semantics> choices = tester.widgetList<Semantics>(
      find.byWidgetPredicate((Widget w) => w is Semantics && w.properties.selected != null),
    );
    expect(choices, hasLength(3), reason: 'three choices');
    expect(
      choices.where((Semantics s) => s.properties.selected ?? false),
      isEmpty,
      reason: 'and not one of them is chosen for the shepherd',
    );

    // AND NOTHING HAS BEEN EMITTED. An un-answered control has not answered.
    expect(emitted, isEmpty);

    await tester.closeApp();
  });

  testWidgets('choosing days shows the keypad and emits nothing until a digit is typed', (
    WidgetTester tester,
  ) async {
    // A SHEPHERD WHO CHOSE *DAYS* AND HAS NOT TYPED YET HAS NOT ANSWERED.
    // Emitting `0` there would be the app answering for them — and zero days is
    // a real, meaningful period, which is exactly why it must never arrive by
    // accident.
    //
    // The keypad appears only AFTER the choice: showing it up front invites a
    // number before the decision, and an empty field beside two other options
    // reads as the default answer.
    final AppDatabase db = testDatabase();
    final List<WithdrawalPeriod> emitted = <WithdrawalPeriod>[];

    await _pumpControl(tester, db, onChanged: emitted.add);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quick_entry.keypad')), findsNothing);

    await tester.tap(find.byKey(const Key('treatment.withdrawal.enter_days')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quick_entry.keypad')), findsOneWidget);
    expect(emitted, isEmpty, reason: 'chosen, but not yet answered');

    await tester.tap(find.byKey(const Key('quick_entry.keypad.digit_2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('quick_entry.keypad.digit_8')));
    await tester.pumpAndSettle();

    expect(emitted.last, isA<WithdrawalDays>());
    expect((emitted.last as WithdrawalDays).days, 28);

    // AND BACKSPACING TO EMPTY EMITS NOTHING NEW. Drilled: `int.tryParse(...) ??
    // 0` passed every other case in this file, because choosing *days* does not
    // emit on its own — only a keystroke does. Clearing the field is the one
    // path where a fallback zero can escape, and zero days is a real, meaningful
    // period, which is exactly why it must never arrive by accident.
    final int afterTyping = emitted.length;
    await tester.tap(find.byKey(const Key('quick_entry.keypad.backspace')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('quick_entry.keypad.backspace')));
    await tester.pumpAndSettle();

    expect(emitted.length, afterTyping + 1, reason: 'one emission for 2, none for an empty field');
    expect((emitted.last as WithdrawalDays).days, 2, reason: 'never 0');
  });

  testWidgets('not recorded and none applies are two different answers', (
    WidgetTester tester,
  ) async {
    // BOTH ARE CHOICES THE SHEPHERD MAKES, and they mean different things: the
    // label said none applies, versus nobody wrote a number down. The repository
    // stores a row for the first and nothing at all for the second, and this is
    // the screen half of that distinction.
    final AppDatabase db = testDatabase();
    final List<WithdrawalPeriod> emitted = <WithdrawalPeriod>[];

    await _pumpControl(tester, db, onChanged: emitted.add);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('treatment.withdrawal.not_applicable')));
    await tester.pumpAndSettle();
    expect(emitted.last, isA<WithdrawalNotApplicable>());

    await tester.tap(find.byKey(const Key('treatment.withdrawal.not_recorded')));
    await tester.pumpAndSettle();
    expect(emitted.last, isA<WithdrawalNotRecorded>());

    // AND THE KEYPAD IS GONE AGAIN — neither of these takes a number.
    expect(find.byKey(const Key('quick_entry.keypad')), findsNothing);

    await tester.closeApp();
  });

  testWidgets('every withdrawal choice clears 64 by 64 at the smallest device', (
    WidgetTester tester,
  ) async {
    // The 3am floor, measured rather than read back from the constant passed in.
    final AppDatabase db = testDatabase();

    await tester.pumpApp(
      WithdrawalControl(target: WithdrawalTarget.meat, labels: _labels, onChanged: (_) {}),
      db: db,
      device: Device.small,
    );
    await tester.pumpAndSettle();

    for (final String id in <String>[
      'treatment.withdrawal.enter_days',
      'treatment.withdrawal.not_applicable',
      'treatment.withdrawal.not_recorded',
    ]) {
      final Size size = tester.getSize(find.byKey(Key(id)));
      expect(size.height, greaterThanOrEqualTo(64.0), reason: id);
      expect(size.width, greaterThanOrEqualTo(64.0), reason: id);
    }

    // AND THERE IS NO TEXT FIELD ANYWHERE. Decision #57: the keypad is the only
    // numeric route in the app, and a numeric keyboard is the thing it replaced.
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ShedTapTarget), findsWidgets);

    await tester.closeApp();
  });

  testWidgets('a disagreeing clear date renders both numbers and offers no correction', (
    WidgetTester tester,
  ) async {
    // BOTH NUMBERS, NEITHER UPDATED. The disagreement happens when the device
    // changed timezone between the write and the read, and §12.4 forbids
    // silently correcting a user's entry — the stored date is the one the
    // shepherd was told and may have written in a book.
    //
    // THE STORED ONE RENDERS FIRST, asserted geometrically rather than by index:
    // a column that built them in one order and laid them out in another would
    // satisfy any find-based check.
    //
    // AND THERE IS NO CONTROL OFFERING TO RECONCILE THEM. Offering would make
    // the app the arbiter of a clinical date — the same line §12.2 draws.
    final AppDatabase db = testDatabase();

    await tester.pumpApp(
      const WithdrawalDisagreement(
        labels: (
          stored: 'STORED 11 Mar 2026',
          recomputed: "TODAY'S ARITHMETIC 12 Mar 2026",
          explanation: 'Nothing has been changed.',
        ),
      ),
      db: db,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('11 Mar 2026'), findsOneWidget);
    expect(find.textContaining('12 Mar 2026'), findsOneWidget);
    expect(find.textContaining('Nothing has been changed'), findsOneWidget);

    final double storedY = tester
        .getTopLeft(find.byKey(const Key('treatment.withdrawal.stored')))
        .dy;
    final double recomputedY = tester
        .getTopLeft(find.byKey(const Key('treatment.withdrawal.recomputed')))
        .dy;
    expect(storedY, lessThan(recomputedY), reason: 'the one in the book comes first');

    // NO TARGET ANYWHERE IN THE SUBTREE. Not a disabled one, not a hidden one —
    // none. The absence is the mechanism.
    expect(find.byType(ShedTapTarget), findsNothing);

    await tester.closeApp();
  });
}

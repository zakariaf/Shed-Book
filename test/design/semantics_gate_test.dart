// test/design/semantics_gate_test.dart
//
// **THE LABELLED-TARGET SWEEP, OVER EVERY VARIANT THAT EXISTS.** N09 deferred it
// deliberately: a sweep over an empty variant table is a green test that
// iterates nothing, and it would have been green through eight screen epics.
//
// It runs at textScaler **1.0 and 2.0**, because a label is not a geometry
// problem until the geometry moves — a row that fits at 1.0 and reflows at 2.0
// can lose a `Semantics` boundary in the reflow, and the sweep is the only thing
// that would notice.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';

import '../support/harness.dart';

void main() {
  // **EVERY VARIANT, DERIVED FROM THE TABLE RATHER THAN LISTED.** `12 §6.1`
  // names fourteen; eleven exist today, because reminders, the season summary
  // and note search ship in `v1.1.0`. A hard-coded fourteen here would assert a
  // future, and a hard-coded eleven would stop sweeping the day one lands.
  for (final MapEntry<String, PumpableVariant> variant in kPumpableVariants.entries) {
    for (final double scale in <double>[1.0, 2.0]) {
      testWidgets('${variant.key} · scale $scale · every tap target carries a label', (
        WidgetTester tester,
      ) async {
        // **`ensureSemantics()` FIRST, AND WITHOUT IT THE SWEEP PROVES NOTHING.**
        // The semantics tree is not built in a test unless something asks for
        // it, and `meetsGuideline` on an absent tree passes.
        final SemanticsHandle handle = tester.ensureSemantics();
        final AppDatabase db = await fixtureDatabase('flock_400_3seasons.json');

        // Pinned for the same reason the overflow matrix pins: a screen that
        // renders an elapsed time has a layout demand that is unbounded in time,
        // and a sweep whose subject changes every day is a sweep that goes red
        // for nobody's change.
        await atFixed(DateTime.utc(2026, 2, 11, 8), () async {
          final Map<String, int> ids = await variant.value.seed(db);
          await tester.pumpApp(variant.value.build(ids), db: db, textScale: scale);
        });

        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        handle.dispose();
        await tester.closeApp();
      });
    }
  }

  testWidgets('the canary widget with no semanticLabel fails the sweep', (
    WidgetTester tester,
  ) async {
    // **THE ANCHOR, AND IT IS THE ONLY CASE IN THIS FILE THAT CAN FAIL FOR A
    // GOOD REASON.** Without it, a guideline that silently stopped evaluating
    // anything would keep every sweep above green for ever — and the sweep is
    // the whole of what N33 adds here.
    //
    // `evaluate()` DIRECTLY, never `isNot(meetsGuideline(...))`: `meetsGuideline`
    // is an `AsyncMatcher`, asserting that something fails one is awkward and
    // easy to get subtly wrong, and a canary you cannot read is not a canary
    // (`12 §7.5`).
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            // A tappable thing with no label at all. `GestureDetector`
            // contributes no semantics node, which is exactly why the project
            // bans it in favour of `ShedTapTarget` — and why this is the right
            // shape for the canary.
            child: _UnlabelledTarget(),
          ),
        ),
      ),
    );

    final Evaluation evaluation = await labeledTapTargetGuideline.evaluate(tester);

    expect(
      evaluation.passed,
      isFalse,
      reason: 'if this canary ever passes, the labelled-target gate above is dead',
    );
    // **A CANARY THAT FAILS FOR AN UNRELATED REASON IS A CANARY THAT PASSES FOR
    // THE WRONG ONE.** The reason is a newline-joined string; it must name the
    // thing that is wrong.
    expect(
      evaluation.reason,
      contains('SemanticsNode'),
      reason: 'the canary failed for a reason that is not the missing label',
    );

    handle.dispose();
  });
}

/// A tappable node with a semantics boundary and **no label** — the one shape
/// `labeledTapTargetGuideline` exists to catch.
class _UnlabelledTarget extends StatelessWidget {
  const _UnlabelledTarget();

  @override
  Widget build(BuildContext context) =>
      Semantics(container: true, onTap: () {}, child: const SizedBox.square(dimension: 64));
}

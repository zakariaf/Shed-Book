// test/policy/disclaimer_is_referenced_test.dart — `12 §10.1`.
//
// `disclaimer_is_defined_once_test.dart` holds that the strings live in ONE
// file. This holds the other half: that the screens actually RENDER them, and
// render them by reference.
//
// The two are different failures. A constant nobody uses is a promise nobody
// keeps; a screen that types its own wording is two promises, one of which
// somebody will improve and the other of which will not follow.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/features/treatments/widgets/treatment_disclosures.dart';

import '../support/harness.dart';

void main() {
  testWidgets('every disclosure on the Treatments screen is referenced from Disclaimers', (
    WidgetTester tester,
  ) async {
    // COMPARED AGAINST THE CONSTANTS, NEVER AGAINST A COPY OF THEIR TEXT. A test
    // that hard-codes the literal still passes after somebody edits the
    // constant — which is the one failure this assertion exists to catch, and
    // `12 §10.1` makes the same point in its own comment.
    final AppDatabase db = testDatabase();

    await tester.pumpApp(const TreatmentBookFooter(), db: db);
    // ON THE FIRST PAINTED FRAME, without a tap and without settling. A
    // disclosure the shepherd has to go looking for is a disclosure that has not
    // been made.
    expect(
      find.textContaining(Disclaimers.exportFooter),
      findsOneWidget,
      reason: 'the book footer is reachable without a tap',
    );
    await tester.closeApp();

    await tester.pumpApp(const WithdrawalCaveat(), db: db);
    expect(find.textContaining(Disclaimers.withdrawalCaveat), findsOneWidget);
    await tester.closeApp();

    await tester.pumpApp(const WithdrawalProvenanceStamp(), db: db);
    expect(find.textContaining(Disclaimers.withdrawalProvenance), findsOneWidget);
    await tester.closeApp();
  });

  test('no disclosure is re-typed in the treatments feature', () {
    // THE OTHER DIRECTION. The case above proves the words REACH the screen; this
    // proves they are not ALSO written out somewhere in the feature, which is how
    // two wordings appear.
    //
    // Scanned over the feature's own files, and the needle is the constant's
    // VALUE — so a paraphrase is not caught, but a copy-paste is, and a
    // copy-paste is what actually happens.
    final Directory feature = Directory('lib/features/treatments');
    if (!feature.existsSync()) {
      return;
    }

    for (final FileSystemEntity entity in feature.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      // `treatment_disclosures.dart` is the one file that REFERENCES them, and
      // referencing is `Disclaimers.name` rather than the text — so it is
      // scanned like every other file rather than exempted.
      final String source = entity.readAsStringSync();
      for (final String literal in <String>[
        Disclaimers.exportFooter,
        Disclaimers.withdrawalCaveat,
        Disclaimers.withdrawalProvenance,
      ]) {
        expect(
          source.contains(literal),
          isFalse,
          reason: '${entity.path} types a disclosure out instead of referencing it',
        );
      }
    }
  });
}

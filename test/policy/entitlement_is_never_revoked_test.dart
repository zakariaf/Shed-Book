// test/policy/entitlement_is_never_revoked_test.dart
//
// **NAMED FOR WHAT IT FORBIDS, NOT FOR THE FILE IT GUARDS** (`CONVENTIONS §4.1`),
// because the defect it exists to catch can move between the repository, a
// controller and a listener without changing shape.
//
// The rule (`11 §12.2`): **an entitlement is never revoked.** There is no verb
// that sets `unlocked` back to false, and there must never be one.
//
// This is not a hypothetical rule with a hypothetical failure. It is the
// reasonable-looking fix: the store says it cannot confirm the purchase, so the
// app "corrects" itself. A shed has no signal most of the time the store is
// asked — `StoreUnreachable` is the NORMAL case, which is why it is not even a
// `ShedFailure` — so that correction takes the unlock away from a shepherd
// standing in a barn at 03:20, for a network they never had. It reads as
// defensive and it is theft.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A file's source with its comment lines removed. The rule is about what the
/// code DOES, not the prose about what it must not do — a distinction this
/// project has failed on more than thirty times.
String _code(String path) => File(path)
    .readAsStringSync()
    .split('\n')
    .where((String l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  test('no verb anywhere in lib/ writes unlocked back to false', () {
    // The gate row `db.entitlement_revoke` scans `lib/data/`, which is the only
    // tier that can write the column. This scans **all of `lib/`**, deliberately
    // wider: a controller cannot write it today, and the day the layer rules
    // move is the day this rule would silently stop covering the place it moved
    // to.
    final RegExp revoke = RegExp(r'unlocked:\s*(const\s+)?Value(<bool>)?\(false\)');

    for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) {
        continue;
      }
      expect(
        revoke.hasMatch(_code(f.path)),
        isFalse,
        reason: '${f.path} revokes an entitlement — 11 §12.2',
      );
    }
  });

  test('the repository exposes no verb whose name suggests one', () {
    // A method called `lock`, `revoke`, `clearEntitlement` or `downgrade` is the
    // shape somebody reaches for before they write the assignment — and a name
    // is easier to review than a companion three lines into a transaction.
    final String source = _code('lib/data/entitlement_repository.dart');
    for (final String verb in <String>['revoke', 'downgrade', 'clearEntitlement', 'relock']) {
      expect(source, isNot(contains(verb)), reason: 'a $verb verb exists');
    }
  });

  test('StoreUnreachable is not a signal, so it can never reach the listener', () {
    // **THE STORE CANNOT REPORT WHAT IT COULD NOT REACH.** `PurchaseSignal` has
    // five members and none of them means *unreachable*: the timeout throws out
    // of `queryUnlockPrice` and never enters the stream, so the listener that
    // writes the row cannot see one even by accident.
    //
    // Asserted on the seam's source rather than at runtime, because the property
    // is that a value does not exist — and a runtime test can only ever show
    // that one particular path did not produce it.
    final String seam = _code('lib/data/purchase_service.dart');
    expect(seam, contains('enum PurchaseSignal'));
    expect(
      seam,
      isNot(contains('PurchaseSignal.unreachable')),
      reason: 'unreachable became a signal — the listener can now act on no signal',
    );

    final String listener = _code('lib/data/entitlement_repository.dart');
    expect(
      listener,
      isNot(contains('StoreUnreachable')),
      reason: 'the entitlement listener knows about a store failure it must not act on',
    );
  });

  test('the signal switch is exhaustive, with no catch-all', () {
    // Five signals, five arms. A `default:` or a `_ =>` turns a sixth signal in
    // a future change from a compile error into a purchase nobody notices —
    // and on this switch specifically, into an unlock that silently never lands.
    final String body = _code(
      'lib/data/entitlement_repository.dart',
    ).split('switch (signal) {').last.split('\n  }').first;
    expect(body, isNot(contains('default:')));
    expect(body, isNot(contains('_ =>')));
    expect('PurchaseSignal.'.allMatches(body).length, 5);
  });
}

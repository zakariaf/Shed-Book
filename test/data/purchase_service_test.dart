// test/data/purchase_service_test.dart
//
// **THE SEAM, AND THE PROPERTY THAT MAKES IT A SEAM.** Nothing outside
// `purchase_service.dart` may name a plugin type — and an import ban alone does
// not achieve that, because a public signature returning a plugin type makes the
// caller import it legitimately. These cases assert the *outward* shape.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/failure.dart';
import 'package:shed_book/data/purchase_service.dart';

/// A file's source with its comment lines removed.
///
/// Every scan in this file uses it. The distinction it draws — what the code
/// *does* versus what the comments *say about what it must not do* — is the one
/// this project has failed on more than thirty times, in gate rows and in tests.
String _code(String path) => File(path)
    .readAsStringSync()
    .split('\n')
    .where((String l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  test('StoreUnreachable is a first-class signal, not a failure', () {
    // **THE WHOLE DESIGN RESTS ON THIS.** A shed with no signal is the normal
    // case, not a fault: the app is fully usable, every record is written, and
    // the only thing that cannot happen is a purchase.
    //
    // Making it a `ShedFailure` would put it in the same bucket as a corrupt
    // records file, and the panel that renders those would tell a shepherd
    // something is wrong when nothing is.
    expect(const StoreUnreachable(), isNot(isA<ShedFailure>()));
    expect(const StoreUnreachable(), isA<Exception>());
  });

  test('the product id is frozen and byte-identical in both stores', () {
    // Changing it strands every purchase ever made — and there is no server to
    // migrate them with. Pinned as a literal here on purpose: this is the one
    // string that must be typed twice, in App Store Connect and Play Console,
    // and a test that read it from the source could not tell they had diverged.
    expect(kUnlockProductId, 'shed_book_unlock');
  });

  test('PurchaseSignal carries five members and no plugin type', () {
    // **EVERYTHING THE REST OF THE APP MAY LEARN FROM A STORE UPDATE.** Five
    // arms, matching the plugin's five statuses one for one — so a sixth member
    // in a future plugin major is a compile error in the switch rather than a
    // silently-ignored purchase.
    expect(PurchaseSignal.values, hasLength(5));
    expect(
      PurchaseSignal.values.map((PurchaseSignal s) => s.name),
      containsAll(<String>['awaitingPayment', 'purchased', 'restored', 'cancelled', 'failed']),
    );
  });

  test('the plugin is imported in exactly one file, and its types leak nowhere', () {
    // **THE SECOND CLAUSE IS THE LOAD-BEARING ONE.** An import ban is trivially
    // satisfied by a signature that returns a plugin type — the caller then
    // imports the plugin legitimately, and the rule holds on paper while the
    // architecture is gone.
    const List<String> pluginTypes = <String>[
      'PurchaseDetails',
      'ProductDetails',
      'PurchaseStatus',
      'PurchaseParam',
      'InAppPurchase',
    ];

    final List<String> importers = <String>[];
    for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) {
        continue;
      }
      final String src = f.readAsStringSync();
      if (src.contains('package:in_app_purchase')) {
        importers.add(f.path);
      }
      if (f.path.endsWith('data/purchase_service.dart')) {
        continue;
      }
      // Comments stripped: the prose explaining the ban legitimately names the
      // types, and this project has failed its own scans on that distinction
      // more than thirty times.
      final String code = src
          .split('\n')
          .where((String l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
          .join('\n');
      for (final String type in pluginTypes) {
        expect(code, isNot(contains(type)), reason: '${f.path} names $type');
      }
    }

    expect(importers, <String>['lib/data/purchase_service.dart']);
  });

  test('main.dart and app.dart do not name the store at all', () {
    // `launch.store_call`. The first painted frame must not be able to start a
    // billing client — decision #21's promise is that frame one is tonight's
    // page, and a store handshake on the launch path is the one thing that could
    // put a system dialog in front of it.
    for (final String path in <String>['lib/main.dart', 'lib/app.dart']) {
      final String src = File(path).readAsStringSync();
      expect(src, isNot(contains('PurchaseService')), reason: path);
      expect(src, isNot(contains('purchase_service.dart')), reason: path);
    }
  });

  test('the plugin surface used is exactly seven members', () {
    // Reaching for an eighth is a document conversation, not an implementation
    // detail — `getPlatformAddition`, `enableStoreKit1()` and `buyConsumable`
    // are each a decision with a paper trail, and none of them has one.
    // Comments stripped, for the thirty-third time in this project: the
    // paragraph explaining why the seam does not reach for `getPlatformAddition`
    // names it, and a scan that cannot tell prose from a call flags the
    // explanation instead of a violation.
    final String src = _code('lib/data/purchase_service.dart');
    for (final String banned in <String>[
      'getPlatformAddition',
      'enableStoreKit1',
      'buyConsumable',
      'applicationUserName',
    ]) {
      expect(src, isNot(contains(banned)), reason: 'the seam reached for $banned');
    }
    // And the seven that ARE used, so a rewrite that quietly drops one is caught.
    for (final String used in <String>[
      'purchaseStream',
      'isAvailable',
      'queryProductDetails',
      'buyNonConsumable',
      'restorePurchases',
      'completePurchase',
    ]) {
      expect(src, contains(used), reason: 'the seam no longer calls $used');
    }
  });

  test('completion is gated on pending, and the product check gates the signal', () {
    // **THE TWO LINES SIT ONE APART, WHICH IS EXACTLY HOW THEY GET SWAPPED.**
    //
    //   * an unrecognised id left uncompleted is redelivered forever, so
    //     completion runs regardless of product id;
    //   * a `pending` purchase must NEVER be completed — on Android
    //     `completePurchase` IS `acknowledgePurchase()`, and Google's own wording
    //     is *"don't acknowledge it while a purchase is in PENDING state."*
    //
    // Asserted on the source because the ordering is what matters and a runtime
    // test would need a plugin double for a property that is structural.
    final String src = _code('lib/data/purchase_service.dart');
    final int completion = src.indexOf('completePurchase(purchase)');
    final int idCheck = src.indexOf('purchase.productID != kUnlockProductId');
    expect(completion, greaterThan(0));
    expect(idCheck, greaterThan(0));
    expect(
      completion,
      lessThan(idCheck),
      reason: 'the product-id check gates the SIGNAL, not the completion',
    );
    expect(
      src.contains('purchase.status != PurchaseStatus.pending'),
      isTrue,
      reason: 'a pending purchase must never be acknowledged',
    );
  });

  test('the switch over the plugin status has no catch-all arm', () {
    // Five members, five arms. A `default:` or a `_ =>` turns a sixth member in
    // a future plugin major from a compile error into a silently-ignored
    // purchase — which is a shepherd who paid and did not get the unlock.
    final String body = _code(
      'lib/data/purchase_service.dart',
    ).split('_signals.add(switch (purchase.status) {').last.split('});').first;
    expect(body, isNot(contains('default:')));
    expect(body, isNot(contains('_ =>')));
    expect('PurchaseStatus.'.allMatches(body).length, 5);
  });
}

// test/policy/store_artefacts_test.dart
//
// **THREE ARTEFACTS NOTHING IN DART READS, AND ONE OF THEM IS A LEGAL
// DECLARATION.** No widget test renders them, no gate compiles them, and each
// fails on somebody else's submission — days later, in a review queue, with a
// message that names none of this.
@Tags(<String>['policy'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/data/purchase_service.dart';

const String _privacy = 'ios/Runner/PrivacyInfo.xcprivacy';
const String _storekit = 'ios/Configuration.storekit';

void main() {
  test('the privacy manifest declares two reasons, and CA92.1 is not one of them', () {
    // **AN API DECLARED THAT THE APP CANNOT CALL IS A FALSE STATEMENT IN A LEGAL
    // DOCUMENT**, and it is the kind that looks harmless. `CA92.1` is the
    // user-defaults reason; this app has no user defaults — `shared_preferences`
    // is forbidden by entitlement rule 3, is not in decision-record §5.1, and
    // N30-T05 refused it again rather than fake a rate limit with it.
    final String plist = File(_privacy).readAsStringSync();

    expect(
      plist,
      contains('C617.1'),
      reason: 'file timestamps are read by LocalLog and connection',
    );
    expect(plist, contains('E174.1'), reason: 'SQLite calls statfs and has no manifest of its own');
    expect(
      plist,
      isNot(contains('CA92.1')),
      reason: 'the app has no user defaults — declaring one is a false statement',
    );
    // Third-party-SDK codes, which an app manifest must never carry.
    for (final String sdkCode in <String>['0A2A.1', 'C56D.1', '3B52.1', '35F9.1']) {
      expect(plist, isNot(contains(sdkCode)), reason: '$sdkCode is a third-party SDK reason');
    }
  });

  test('tracking is false, the domains are empty, and the collected types key is PRESENT', () {
    // **AN ABSENT KEY IS AN UNANSWERED QUESTION; AN EMPTY ARRAY IS THE ANSWER
    // "NONE".** The difference is invisible in a diff and decisive in review.
    final String plist = File(_privacy).readAsStringSync();

    expect(plist, contains('<key>NSPrivacyTracking</key>'));
    expect(
      RegExp(r'<key>NSPrivacyTracking</key>\s*<false/>').hasMatch(plist),
      isTrue,
      reason: 'tracking is not declared false',
    );
    expect(plist, contains('<key>NSPrivacyTrackingDomains</key>'));
    expect(
      plist,
      contains('<key>NSPrivacyCollectedDataTypes</key>'),
      reason: 'the key must be present and empty, not absent',
    );
    expect(
      RegExp(r'<key>NSPrivacyCollectedDataTypes</key>\s*<array/>').hasMatch(plist),
      isTrue,
      reason: 'the collected-types array is not empty',
    );
  });

  test('the manifest is in the Runner target, not merely in the project', () {
    // **THE WORST POSSIBLE FAILURE SHAPE** (`11 §9.2`): a `PrivacyInfo.xcprivacy`
    // that sits in the project but not in the target **ships nothing, and the
    // build succeeds**. Nothing goes red — the app is simply submitted without
    // the declaration, and the first anybody hears is a rejection.
    final String pbxproj = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

    expect(
      pbxproj,
      contains('PrivacyInfo.xcprivacy'),
      reason: 'the manifest is not referenced by the Xcode project at all',
    );

    // **THE ASSERTION IS ON THE RESOURCES PHASE'S OWN BLOCK, NOT ON THE FILE
    // APPEARING SOMEWHERE.** A `PBXFileReference` and a group entry make it
    // visible in Xcode and ship nothing; only a `PBXBuildFile` listed inside a
    // `PBXResourcesBuildPhase` puts it in the bundle. The first draft of this
    // case asserted the phase merely existed, which is true of every generated
    // project and proves nothing.
    final int start = pbxproj.indexOf('/* Begin PBXResourcesBuildPhase section */');
    final int end = pbxproj.indexOf('/* End PBXResourcesBuildPhase section */');
    expect(start, greaterThan(0));
    expect(end, greaterThan(start));

    expect(
      pbxproj.substring(start, end),
      contains('PrivacyInfo.xcprivacy in Resources'),
      reason:
          'the manifest is in the project but not in the target — it would ship nothing '
          'and the build would succeed',
    );
  });

  test('the StoreKit config names the one product id, byte for byte', () {
    // **FROZEN AT THE FIRST SALE.** The id is typed in three places that cannot
    // check each other — App Store Connect, Play Console and this file — and a
    // mismatch strands every purchase ever made, with no server to migrate them.
    final Map<String, Object?> config =
        jsonDecode(File(_storekit).readAsStringSync()) as Map<String, Object?>;
    final List<Object?> products = config['products']! as List<Object?>;

    expect(products, hasLength(1), reason: 'one non-consumable, bought once (spec §14)');
    final Map<String, Object?> product = products.single as Map<String, Object?>;
    expect(product['productID'], kUnlockProductId);
    expect(
      product['type'],
      'NonConsumable',
      reason: 'a consumable could be bought twice and would not restore',
    );
    expect(product['familyShareable'], false);
  });

  test('both store documents exist and say the same thing the app does', () {
    // They are re-answered on every submission and shown to a shepherd in the
    // listing. An answer that drifts from the app is worse than a missing one:
    // it is a claim, in public, that somebody can check.
    final String dataSafety = File('docs/store/data-safety.md').readAsStringSync();
    final String reviewNotes = File('docs/store/app-review-notes.md').readAsStringSync();

    expect(
      dataSafety,
      contains('targetSdk'),
      reason: 'the form asks and the answer must be recorded',
    );
    expect(dataSafety.toLowerCase(), contains('payment'), reason: 'the exemption must be quoted');
    expect(
      dataSafety,
      contains('g5_observation'),
      reason: 'the answers rest on a claim no test can make — the ledger row must be named',
    );

    // The review notes name the product id and the restore path, because those
    // are the two things a reviewer looks for and cannot find on their own.
    expect(reviewNotes, contains(kUnlockProductId));
    expect(reviewNotes.toLowerCase(), contains('restore purchases'));

    // **NEITHER MAY CARRY THE BANNED CLAIM.** Only tiers 1 and 2 are claimable,
    // and these two files are read by people who will quote them back.
    for (final String doc in <String>[dataSafety, reviewNotes]) {
      expect(doc.toLowerCase(), isNot(contains('never leaves your phone')));
      expect(doc.toLowerCase(), isNot(contains('offline-first')));
    }
  });
}

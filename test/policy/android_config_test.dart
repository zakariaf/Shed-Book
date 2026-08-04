// test/policy/android_config_test.dart
//
// **THE TWO FILES THAT DECIDE WHO CAN INSTALL THE APP AND WHETHER REMINDERS
// SURVIVE A REBOOT.** Neither is reachable from Dart, neither is covered by any
// widget test, and both fail in a way that only appears on somebody else's
// phone — so they are asserted as text.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _appGradle = 'android/app/build.gradle.kts';
const String _settingsGradle = 'android/settings.gradle.kts';
const String _manifest = 'android/app/src/main/AndroidManifest.xml';

void main() {
  test('minSdk is declared explicitly as 24 and never inherited from the toolchain', () {
    // **`flutter.minSdkVersion` MOVES WITH THE SDK.** A toolchain bump could
    // change who can install the app without a line in any diff — and raising
    // the floor is the one Gradle change that REMOVES users rather than adding
    // behaviour. 24 is the floor `flutter_local_notifications` 22.2.0 declares,
    // read off the installed package.
    final String gradle = File(_appGradle).readAsStringSync();

    expect(gradle, contains('minSdk = 24'));
    expect(gradle, contains('targetSdk = 36'));
    expect(gradle, contains('compileSdk = 36'));

    for (final String inherited in <String>[
      'flutter.minSdkVersion',
      'flutter.targetSdkVersion',
      'flutter.compileSdkVersion',
    ]) {
      expect(
        gradle.split('\n').where((String l) => !l.trimLeft().startsWith('//')).join('\n'),
        isNot(contains(inherited)),
        reason: '$inherited moves with the toolchain — pin it',
      );
    }
  });

  test('Java 17, Kotlin JVM 17 and core-library desugaring are all present', () {
    // **THE RELEASE BUILD FAILS AT `:app:checkReleaseAarMetadata` WITHOUT THEM**,
    // which is why they landed at N02-T01 rather than here: G0 could not have run
    // the merger against a real `.aab` otherwise. Asserted, not re-added.
    final String gradle = File(_appGradle).readAsStringSync();

    expect(gradle, contains('isCoreLibraryDesugaringEnabled = true'));
    expect(gradle, contains('desugar_jdk_libs:2.1.4'));
    expect(gradle, contains('JVM_17'));
  });

  test('AGP is at or above the floor both plugins pin', () {
    // **READ OFF THE INSTALLED PACKAGES, NOT THEIR READMEs** — a README changes a
    // floor without a changelog entry, which is why `08 §8.3` carried these two
    // numbers as *Unverified* until N31-T02.
    //
    //   share_plus 13.3.0                 -> com.android.tools.build:gradle:8.12.1
    //   flutter_local_notifications 22.2.0 -> com.android.tools.build:gradle:8.11.1
    //
    // The project is on 9.0.1, above both. Asserted as a major-version floor
    // rather than an exact string, because the number moves and the property
    // does not.
    final RegExp agp = RegExp(r'id\("com\.android\.application"\) version "(\d+)\.(\d+)\.(\d+)"');
    final RegExpMatch? m = agp.firstMatch(File(_settingsGradle).readAsStringSync());
    expect(m, isNotNull, reason: 'the AGP version is not declared where the test can read it');

    final int major = int.parse(m!.group(1)!);
    final int minor = int.parse(m.group(2)!);
    expect(
      major > 8 || (major == 8 && minor >= 12),
      isTrue,
      reason: 'AGP $major.$minor is below share_plus 13.3.0s floor of 8.12.1',
    );
  });

  test('the permission block T01 wrote is untouched by this configuration', () {
    // Two commits, two blocks, and this one must not have moved the other. The
    // removal directives are what make decision-record §3.1's claim true, and a
    // Gradle-shaped edit that reformatted the manifest is exactly how one of
    // them would go missing without anybody deciding to remove it.
    final String manifest = File(_manifest).readAsStringSync();

    expect(manifest, contains('android:name="android.permission.INTERNET" tools:node="remove"'));
    expect(
      manifest,
      contains('android:name="android.permission.POST_NOTIFICATIONS" tools:node="remove"'),
    );
    expect(
      manifest,
      contains('xmlns:tools='),
      reason: 'tools:node without the namespace is a no-op',
    );
  });

  test('no notification receiver is registered, because v1.0.0 has no reminders', () {
    // **THE ABSENCE IS THE ASSERTION.** `08` gives this task two
    // `flutter_local_notifications` receivers — the boot receiver and the
    // scheduled-notification receiver — and both belong to reminders, which are
    // N24/N25 and ship in `v1.1.0`.
    //
    // Registering them now would declare a component for a feature that cannot
    // fire: `v1.0.0` creates no notification channel, and T01 removes
    // POST_NOTIFICATIONS from the merged manifest. A receiver with no permission
    // and no channel is dead configuration that the next reader has to prove is
    // dead. N24 adds both, in the commit that adds the reminder that needs them.
    final String manifest = File(_manifest).readAsStringSync();

    for (final String receiver in <String>[
      'ScheduledNotificationBootReceiver',
      'ScheduledNotificationReceiver',
    ]) {
      expect(
        manifest,
        isNot(contains(receiver)),
        reason: '$receiver is v1.1.0s — it cannot fire without a channel or the permission',
      );
    }
  });
}

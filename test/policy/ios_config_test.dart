// test/policy/ios_config_test.dart
//
// **`Info.plist` IS APP STORE REVIEW METADATA, NOT CONFIGURATION.** A missing
// usage string is a rejection; a vague one is a review question that costs a
// week. Nothing in Dart reaches this file, no widget test renders it, and it
// fails on somebody else's submission — so it is asserted as text.
//
// The four plist cases N11-T07 left in `test/design/first_frame_parity_test.dart`
// move here. That file is for the FIRST FRAME — the page colour and the two
// storyboards — and a plist policy living inside a design test is a policy the
// next person deletes while tidying a colour assertion.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _plist = 'ios/Runner/Info.plist';

/// The `<string>` immediately following [key], or `null`.
///
/// Parsed by position rather than with an XML library: a plist is a flat
/// key/value sequence, the file is thirty lines, and a dependency for this would
/// be a `pubspec.yaml` change decision-record §5 owns.
String? _valueFor(String key) {
  final RegExpMatch? m = RegExp(
    '<key>$key</key>\\s*<string>([^<]*)</string>',
  ).firstMatch(File(_plist).readAsStringSync());
  return m?.group(1);
}

void main() {
  test('the three usage strings are present, non-empty, and no ATS exception exists', () {
    // **THE ANCHOR.** Three keys, `08 §8.4`'s copy verbatim, and the absence
    // that matters more than any of them.
    const Map<String, String> expected = <String, String>{
      'NSCameraUsageDescription':
          'Shed Book uses the camera so you can attach a photo to a lambing record.',
      'NSPhotoLibraryUsageDescription':
          'Shed Book lets you attach a photo you have already taken to a lambing record.',
      'NSMicrophoneUsageDescription':
          'Shed Book records voice notes you attach to a lambing record.',
    };

    expected.forEach((String key, String copy) {
      final String? value = _valueFor(key);
      expect(value, isNotNull, reason: '$key is missing — a rejection, not a warning');
      expect(value, isNotEmpty, reason: '$key is empty — worse than missing, it looks deliberate');
      expect(value, copy, reason: '$key does not match 08 §8.4 verbatim');
    });

    // **G5's TEXT HALF.** An app with no network code does not need an ATS
    // exception, and its presence would be a claim that something wants to talk
    // — on the one platform artefact a reviewer reads before the app runs.
    expect(
      File(_plist).readAsStringSync(),
      isNot(contains('NSAppTransportSecurity')),
      reason: 'an ATS exception is a request to make an insecure connection',
    );
  });

  test('every usage string names the feature and promises nothing else', () {
    // A shepherd reads these while a system dialog is covering the screen they
    // were using, one-handed. The only useful content is *what this is for* —
    // and `ContentPolicy`'s banned words apply here exactly as they apply to
    // anything else the app says.
    for (final String key in <String>[
      'NSCameraUsageDescription',
      'NSPhotoLibraryUsageDescription',
      'NSMicrophoneUsageDescription',
    ]) {
      final String value = _valueFor(key)!;
      expect(value, startsWith('Shed Book'), reason: '$key does not name the app');
      expect(value, endsWith('.'), reason: '$key is not a sentence');
      expect('.'.allMatches(value).length, 1, reason: '$key is two sentences — say one thing');
      for (final String banned in <String>['we may', 'should', 'may be used', 'in order to']) {
        expect(value.toLowerCase(), isNot(contains(banned)), reason: '$key says "$banned"');
      }
    }

    // **THE MICROPHONE STRING SAYS *NOTE*, NOT DICTATION.** Voice tag entry is
    // cut from v1 (`08 §10.2`), and a string promising it would describe a
    // feature the app does not have to a reviewer who will look for it.
    final String mic = _valueFor('NSMicrophoneUsageDescription')!;
    expect(mic.toLowerCase(), contains('voice note'));
    for (final String absent in <String>['dictat', 'speech', 'transcri']) {
      expect(mic.toLowerCase(), isNot(contains(absent)), reason: 'the mic string promises $absent');
    }
  });

  test('four keys are absent and stay absent', () {
    // Each of these would be a claim this app cannot make. `UIFileSharingEnabled`
    // and `LSSupportsOpeningDocumentsInPlace` would expose the records file over
    // USB and in Files — a route out of the phone nobody chose, in a product
    // whose backup story is a deliberate share. `NSLocationWhenInUseUsageDescription`
    // is a permission nothing asks for. `ITSAppUsesNonExemptEncryption` absent is
    // not the same as false and must be decided at submission, not guessed here.
    final String plist = File(_plist).readAsStringSync();
    for (final String key in <String>[
      'UIFileSharingEnabled',
      'LSSupportsOpeningDocumentsInPlace',
      'NSLocationWhenInUseUsageDescription',
      'NSBluetoothAlwaysUsageDescription',
    ]) {
      expect(plist, isNot(contains(key)), reason: '$key is a claim this app does not make');
    }
  });

  test('the dark appearance and both storyboards survive', () {
    // **MOVED FROM `first_frame_parity_test.dart`, NOT DUPLICATED.**
    // `UILaunchStoryboardName` and `UIMainStoryboardFile` are different keys
    // naming different storyboards, and losing either is a flash rather than a
    // crash — the kind of defect that never appears on a warm simulator launch.
    final String plist = File(_plist).readAsStringSync();

    expect(
      RegExp(r'<key>UIUserInterfaceStyle</key>\s*<string>Dark</string>').hasMatch(plist),
      isTrue,
      reason: 'without it the app follows the system appearance and can go light',
    );
    expect(plist, contains('<key>UILaunchStoryboardName</key>'));
    expect(plist, contains('<key>UIMainStoryboardFile</key>'));
  });
}

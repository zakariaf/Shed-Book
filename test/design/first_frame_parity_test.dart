// test/design/first_frame_parity_test.dart — the first painted frame is one
// colour, in every layer that can paint it.
//
// ONE FILE, EXTENDED TWICE. T07 adds the iOS group and T08 adds the
// cross-platform assertion and the gate row. Three files would let a platform
// drift out of the set without anything noticing.
//
// The failure this guards is invisible everywhere except a cold launch on a real
// phone: the Dart theme is right, every widget test passes, and the shepherd
// still gets a pale flash before the page appears.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _primitives = 'lib/core/ui/primitives.dart';
const String _colours = 'android/app/src/main/res/values/colors.xml';
const String _styles = 'android/app/src/main/res/values/styles.xml';
const String _stylesNight = 'android/app/src/main/res/values-night/styles.xml';
const String _stylesV31 = 'android/app/src/main/res/values-v31/styles.xml';
const String _manifest = 'android/app/src/main/AndroidManifest.xml';
const String _launchStoryboard = 'ios/Runner/Base.lproj/LaunchScreen.storyboard';
const String _mainStoryboard = 'ios/Runner/Base.lproj/Main.storyboard';

/// The root view's `backgroundColor` as (red, green, blue) floats.
///
/// **The storyboard stores components, not a hex**, so the comparison has to be
/// numeric and tolerant: 0x0A / 255 is 0.039215686…, and Xcode writes six
/// decimal places. Anything tighter than 1/255 fails on rounding rather than on
/// the colour.
(double, double, double) _storyboardColour(String path) {
  final RegExpMatch? m = RegExp(
    r'<color key="backgroundColor" red="([\d.]+)" green="([\d.]+)" blue="([\d.]+)"',
  ).firstMatch(File(path).readAsStringSync());
  expect(m, isNotNull, reason: 'no sRGB backgroundColor in $path');
  return (double.parse(m!.group(1)!), double.parse(m.group(2)!), double.parse(m.group(3)!));
}

/// `nSurface04`'s six hex digits, read out of the Dart source.
///
/// Parsed rather than imported: importing it would make this test agree with
/// itself, and what is under test is that two files written in different
/// languages say the same thing.
String _dartPageColour() {
  final RegExpMatch? m = RegExp(
    r'const Color nSurface04 = Color\(0xFF([0-9A-Fa-f]{6})\)',
  ).firstMatch(File(_primitives).readAsStringSync());
  expect(m, isNotNull, reason: 'nSurface04 not found in $_primitives');
  return m!.group(1)!.toUpperCase();
}

String _androidPageColour() {
  final RegExpMatch? m = RegExp(
    r'<color name="shed_surface_base">#FF([0-9A-Fa-f]{6})</color>',
  ).firstMatch(File(_colours).readAsStringSync());
  expect(m, isNotNull, reason: 'shed_surface_base not found in $_colours');
  return m!.group(1)!.toUpperCase();
}

void main() {
  group('android', () {
    test('the launch colour equals nSurface04', () {
      // THE ANCHOR. Editing one file without the other is the failure this
      // exists for, and it shows up only on a cold launch on a real device.
      expect(
        _androidPageColour(),
        _dartPageColour(),
        reason: 'colors.xml and primitives.dart disagree about the first painted frame',
      );
    });

    test('the hex is typed in exactly one Android file', () {
      // Every other Android file references @color/shed_surface_base. A second
      // literal is a second thing to remember.
      final List<String> offenders = Directory('android')
          .listSync(recursive: true)
          .whereType<File>()
          .map((File f) => f.path.replaceAll(r'\', '/'))
          .where((String p) => p.endsWith('.xml') || p.endsWith('.kt'))
          .where((String p) => p != _colours)
          .where((String p) => File(p).readAsStringSync().contains('#FF${_dartPageColour()}'))
          .toList();

      expect(offenders, isEmpty, reason: 'the page colour is typed outside colors.xml');
    });

    test('the non-night folder is dark too', () {
      // values-night/ is only consulted in dark mode. A shepherd whose phone is
      // in LIGHT mode still gets values/, and this app has no light theme — so a
      // light launch background here is a white flash on exactly the devices
      // whose owners never turn dark mode on.
      final String light = File(_styles).readAsStringSync();

      expect(light, contains('@color/shed_surface_base'));
      expect(light, contains('Theme.Black.NoTitleBar'));
      expect(light, contains('android:forceDarkAllowed">false'));
    });

    test('values/ and values-night/ agree', () {
      // The app is dark-only, so there is nothing for dark mode to change.
      // Keeping the two identical is what makes a divergence obvious in a diff
      // rather than a surprise on one device.
      // Comments are stripped as BLOCKS, not line by line: an XML comment spans
      // many lines and only the first starts with the opener, so a line filter
      // leaves the body behind and the two files "differ" by their prose.
      String styleBlocks(String path) {
        final String withoutComments = File(
          path,
        ).readAsStringSync().replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
        final String? block = RegExp(
          r'<style[\s\S]*</style>',
        ).firstMatch(withoutComments)?.group(0);
        return (block ?? '').replaceAll(RegExp(r'\s+'), ' ');
      }

      expect(styleBlocks(_stylesNight), styleBlocks(_styles));
      expect(styleBlocks(_styles), isNotEmpty);
    });

    test('android 12+ opts out of the platform splash it cannot opt out of', () {
      // Android 12 replaced windowBackground with the SplashScreen API and it
      // CANNOT be disabled. Without these three, the platform draws the launcher
      // icon on a system-chosen background before our first frame.
      final String v31 = File(_stylesV31).readAsStringSync();

      expect(v31, contains('windowSplashScreenBackground">@color/shed_surface_base'));
      expect(v31, contains('windowSplashScreenAnimatedIcon'));
      expect(
        v31,
        contains('windowSplashScreenAnimationDuration">0'),
        reason: 'any duration is a crossfade between two identical images',
      );
    });

    test('the splash icon drawable exists', () {
      // windowSplashScreenAnimatedIcon needs one. Without it the launcher
      // supplies its own default, and it will not be yours.
      expect(File('android/app/src/main/res/drawable/ic_splash_mono.xml').existsSync(), isTrue);
    });

    test('the splash exit fade is removed in MainActivity', () {
      final File activity = Directory('android')
          .listSync(recursive: true)
          .whereType<File>()
          .firstWhere((File f) => f.path.endsWith('MainActivity.kt'));
      final String source = activity.readAsStringSync();

      expect(source, contains('setOnExitAnimationListener'));
      expect(source, contains('view.remove()'));
    });

    test('the system bars do not enforce their own contrast', () {
      // Both default TRUE, and both paint a translucent scrim behind the system
      // bars — a lighter band across the top and bottom of a page whose whole
      // claim is that it is one field.
      final String light = File(_styles).readAsStringSync();
      expect(light, contains('enforceStatusBarContrast">false'));
      expect(light, contains('enforceNavigationBarContrast">false'));
    });

    test('predictive back is enabled on the application', () {
      expect(
        File(_manifest).readAsStringSync(),
        contains('android:enableOnBackInvokedCallback="true"'),
      );
    });

    test('the manifest still carries everything G0 and the plugins need', () {
      // Read the whole file before editing it: the removal line, the permissions
      // and the notification receivers must all survive a launch-theme edit.
      final String manifest = File(_manifest).readAsStringSync();

      expect(manifest, contains('<application'));
      expect(manifest, contains('.MainActivity'));
      expect(manifest, contains('@style/LaunchTheme'));
      // **THE NAME MUST APPEAR, AND IT MUST APPEAR ONLY AS A REMOVAL.**
      //
      // This case asserted the string was absent entirely, which was right while
      // nothing had written a removal directive — and wrong the moment N31-T01
      // did. `tools:node="remove"` names the permission in order to delete it
      // from the merged manifest: absence of the string means the merger puts
      // INTERNET back, which is the opposite of what the assertion wanted.
      //
      // What survives is the property it was reaching for: the app never
      // **declares** it. Merged in by Play Billing's telemetry transport on a
      // transitive edge no README mentions, and removed here — which is what
      // makes decision-record §3.1's sentence true.
      expect(
        manifest,
        contains('android:name="android.permission.INTERNET" tools:node="remove"'),
        reason: 'G1: the shipped app has no internet permission — the removal is how',
      );
      expect(
        RegExp(r'android\.permission\.INTERNET').allMatches(manifest).length,
        1,
        reason: 'INTERNET appears once, as the removal, and never as a declaration',
      );
    });
  });

  group('ios', () {
    test('both storyboards paint the ruled page colour', () {
      // TWO STORYBOARDS, AND THE SECOND IS THE ONE PEOPLE FORGET.
      // LaunchScreen is what iOS shows before the engine starts; Main is what
      // the scene shows for the instant between the engine starting and
      // Flutter's first frame. A white Main.storyboard is a one-frame flash that
      // never appears on a simulator warm-launch.
      final String hex = _dartPageColour();
      final double r = int.parse(hex.substring(0, 2), radix: 16) / 255.0;
      final double g = int.parse(hex.substring(2, 4), radix: 16) / 255.0;
      final double b = int.parse(hex.substring(4, 6), radix: 16) / 255.0;

      for (final String path in <String>[_launchStoryboard, _mainStoryboard]) {
        final (double sr, double sg, double sb) = _storyboardColour(path);
        expect(sr, closeTo(r, 1 / 255), reason: '$path red');
        expect(sg, closeTo(g, 1 / 255), reason: '$path green');
        expect(sb, closeTo(b, 1 / 255), reason: '$path blue');
      }
    });

    // **THE TWO `Info.plist` POLICY CASES MOVED TO
    // `test/policy/ios_config_test.dart` AT N31-T04.** This file is for the
    // FIRST FRAME — the page colour and the two storyboards — and a plist policy
    // living inside a design test is a policy the next person deletes while
    // tidying a colour assertion. Moved, not duplicated: two copies of an
    // assertion is one copy that stops being true.

    test('the template launch image is gone', () {
      // The generated storyboard centres a LaunchImage on white. Leaving it
      // means a logo appears and then vanishes — which is the splash this
      // product does not have.
      final String storyboard = File(_launchStoryboard).readAsStringSync();
      expect(storyboard, isNot(contains('LaunchImage')));
    });
  });
}

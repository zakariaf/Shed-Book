// Decision #5: the dependency table is not a proposal until somebody has
// resolved it and committed the result. This file reads `pubspec.lock` and not
// `pubspec.yaml` — the pubspec is what you asked for, the lockfile is what you
// got, and only the second is evidence.
//
// There is no YAML parser here on purpose. `yaml` is not in decision-record §5,
// and §5 is the only source of a version number in this project. `pubspec.lock`
// is generated with a flat, stable shape, so a line scanner is enough — the
// same posture as decision #82's hand-rolled CSV writer.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// One package as the lockfile resolved it.
class LockedPackage {
  const LockedPackage({required this.dependency, required this.version});

  /// `direct main`, `direct dev`, `direct overridden` or `transitive`.
  final String dependency;
  final String version;

  bool get isDirect => dependency.startsWith('direct');
}

final RegExp _packageLine = RegExp(r'^  ([a-z0-9_]+):$');
final RegExp _dependencyLine = RegExp(r'^    dependency: "?([^"]+)"?$');
final RegExp _versionLine = RegExp(r'^    version: "([^"]+)"$');

Map<String, LockedPackage> parseLockfile(String text) {
  final Map<String, LockedPackage> packages = <String, LockedPackage>{};
  String? name;
  String? dependency;
  String? version;

  void flush() {
    if (name != null && dependency != null && version != null) {
      packages[name!] = LockedPackage(dependency: dependency!, version: version!);
    }
  }

  for (final String line in text.split('\n')) {
    final RegExpMatch? package = _packageLine.firstMatch(line);
    if (package != null) {
      flush();
      name = package.group(1);
      dependency = null;
      version = null;
      continue;
    }
    dependency ??= _dependencyLine.firstMatch(line)?.group(1);
    version ??= _versionLine.firstMatch(line)?.group(1);
  }
  flush();
  return packages;
}

/// Decision-record §5.1, verbatim. `flutter`, `flutter_localizations` and
/// `flutter_test` come from the SDK and carry no pub version, so they are
/// asserted separately.
const Map<String, String> runtimeDependencies = <String, String>{
  'flutter_riverpod': '2.6.1',
  'drift': '2.34.2',
  'drift_flutter': '0.3.1',
  'sqlite3': '3.5.0',
  'path_provider': '2.1.6',
  'uuid': '4.6.0',
  'clock': '1.1.2',
  // Declared `intl: any` because flutter_localizations pins 0.20.2 exactly, so
  // `^0.20.3` will not resolve (decision #108). The resolved version is still
  // asserted — `any` is a constraint, not a licence to drift.
  'intl': '0.20.2',
  'flutter_local_notifications': '22.2.0',
  'timezone': '0.11.1',
  'wakelock_plus': '1.7.0',
  'image_picker': '1.2.3',
  'flutter_image_compress': '2.5.1',
  'file_selector': '1.1.0',
  'record': '7.1.1',
  'pdf': '3.13.0',
  'archive': '4.0.9',
  'share_plus': '13.3.0',
  'in_app_purchase': '3.3.0',
  'device_info_plus': '13.2.0',
  'logging': '1.3.0',
};

/// Decision-record §5.2. `build_runner` carries a range and is asserted by its
/// own case. `glados` is **not** here: it was struck from §5.2 on 2026-08-01
/// because it does not resolve against `drift_dev` 2.34.5 at any version, and
/// it is asserted absent by [rejectedAsDirect] instead.
const Map<String, String> devDependencies = <String, String>{
  'drift_dev': '2.34.5',
  'flutter_lints': '6.0.0',
  'mocktail': '1.0.5',
  'accessibility_tools': '2.8.0',
  'golden_screenshot': '11.0.1',
};

/// Decision-record §5.3. Each was rejected with a reason and an alternative;
/// none may reappear as a direct dependency. Several of them are legitimately
/// present as **transitive** packages, which is why this list is checked
/// against `isDirect` and never against presence.
const List<String> rejectedAsDirect = <String>[
  'printing',
  'google_fonts',
  'csv',
  'permission_handler',
  'file_picker',
  'go_router',
  'freezed',
  'mockito',
  'sqlite3_flutter_libs',
  'sqlcipher_flutter_libs',
  'riverpod_generator',
  'riverpod_lint',
  'riverpod_annotation',
  'hooks_riverpod',
  'import_lint',
  'custom_lint',
  'dart_code_metrics',
  'get_it',
  'melos',
  'speech_to_text',
  'golden_toolkit',
  'alchemist',
  'patrol',
  'checks',
  'flutter_native_splash',
  'screen_brightness',
  'disk_space_plus',
  'open_filex',
  // Struck from §5.2 on 2026-08-01, not §5.3, but the assertion is the same
  // one: it depends on package:test and cannot coexist with drift_dev 2.34.5.
  'glados',
  'flutter_glados',
  // `yaml` arrives transitively via build_runner. No test in this project may
  // import it — decision-record §5 is the only source of a version number, and
  // reading a transitive package from test/ is what G2's [transitive] section
  // exists to police.
  'yaml',
];

void main() {
  final File lockfile = File('pubspec.lock');
  final Map<String, LockedPackage> locked = lockfile.existsSync()
      ? parseLockfile(lockfile.readAsStringSync())
      : <String, LockedPackage>{};

  test('pubspec.lock pins flutter_riverpod to exactly 2.6.1 and declares no '
      'package:test', () {
    expect(lockfile.existsSync(), isTrue,
        reason: 'pubspec.lock is decision #5\'s evidence and must be committed');
    expect(locked, isNotEmpty, reason: 'pubspec.lock parsed to nothing');

    final LockedPackage? riverpod = locked['flutter_riverpod'];
    expect(riverpod, isNotNull, reason: 'flutter_riverpod is not in the lockfile');
    expect(riverpod!.dependency, 'direct main');
    // Exact, not a caret. Every Riverpod 3 API is a compile error here, and 3.x
    // cannot resolve alongside drift_dev ≥ 2.34.1 at all (decision #17).
    expect(riverpod.version, '2.6.1');

    // Decision #4. `flutter_test` does not depend on package:test; declaring it
    // caps analyzer < 13.0.0 and breaks drift_dev. The assertion is about the
    // dependency KIND, never about presence.
    final LockedPackage? test = locked['test'];
    if (test != null) {
      expect(test.isDirect, isFalse,
          reason: 'package:test is a direct ${test.dependency} dependency');
    }
  });

  test('build_runner resolves inside the range decision #3 fixes', () {
    final LockedPackage? runner = locked['build_runner'];
    expect(runner, isNotNull);
    expect(runner!.dependency, 'direct dev');

    final List<int> version = runner.version
        .split('.')
        .map((String p) => int.parse(p.split('-').first))
        .toList();
    // ">=2.15.0 <2.15.2". 2.15.2 requires analyzer >=13.3.0 → meta ^1.18.3,
    // which the SDK's exact meta: 1.18.0 makes unresolvable.
    expect(version[0], 2);
    expect(version[1], 15);
    expect(version[2], inInclusiveRange(0, 1),
        reason: 'build_runner ${runner.version} is outside the decision #3 range');
  });

  test('every package in decision-record §5.1 is a direct main dependency at '
      'its §5 version', () {
    runtimeDependencies.forEach((String name, String version) {
      final LockedPackage? package = locked[name];
      expect(package, isNotNull, reason: '$name is missing from the lockfile');
      expect(package!.dependency, 'direct main', reason: name);
      expect(package.version, version,
          reason: '$name resolved to ${package.version}, §5.1 says $version');
    });
  });

  test('every package in decision-record §5.2 is a direct dev dependency at '
      'its §5 version', () {
    devDependencies.forEach((String name, String version) {
      final LockedPackage? package = locked[name];
      expect(package, isNotNull, reason: '$name is missing from the lockfile');
      expect(package!.dependency, 'direct dev', reason: name);
      expect(package.version, version,
          reason: '$name resolved to ${package.version}, §5.2 says $version');
    });
  });

  test('no package from §5.3 is a direct dependency', () {
    for (final String name in rejectedAsDirect) {
      final LockedPackage? package = locked[name];
      if (package == null) {
        continue;
      }
      expect(package.isDirect, isFalse,
          reason: '$name was rejected in §5.3 and is a ${package.dependency} '
              'dependency');
    }
  });

  test('the test makes no claim about http', () {
    // Deliberate documentation case. `http 1.6.0` sits on two regular edges —
    // flutter_local_notifications → timezone → http, and wakelock_plus →
    // package_info_plus → http. A "no http in pubspec.lock" gate is
    // unsatisfiable and 13's Definition of done bans it by name. The offline
    // proof is G1 + G2 + G3, never the lockfile's package list.
    final LockedPackage? http = locked['http'];
    expect(http, isNotNull,
        reason: 'http is expected in the lockfile; if it has gone, an edge '
            'changed and the offline prose needs re-reading, not celebrating');
    expect(http!.dependency, 'transitive',
        reason: 'http must arrive transitively and never be declared');
  });
}

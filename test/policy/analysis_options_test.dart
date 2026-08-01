// `flutter analyze` is silent about configuration that is absent, and equally
// silent about a promotion whose rule was never enabled. So this file reads the
// YAML as text rather than trusting the analyzer to notice a missing key.
//
// It does not use `package:yaml`. That package is not in decision-record §5,
// §5 is the only source of a version number, and importing a transitive package
// from `test/` is exactly what G2's `[transitive]` section exists to police —
// it would also trip `depend_on_referenced_packages`, which `flutter_lints`
// enables and `--fatal-infos` turns into a build break.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _options = 'analysis_options.yaml';
const String _pubspec = 'pubspec.yaml';

/// Decision #109, and it comes from decision-record §5 and nowhere else.
const String flutterLintsVersion = '6.0.0';

/// The three analyzer language modes. `flutter_lints` sets **none** of them,
/// which is why this block is not optional and is restated in the repository
/// rather than inherited — it must survive a base-package bump and be visible.
const List<String> strictModes = <String>['strict-casts', 'strict-inference', 'strict-raw-types'];

/// Rules promoted under `errors:` that `flutter_lints`' own closure does **not**
/// enable. Each must therefore appear twice — once under `linter: rules:` to
/// turn it on and once under `errors:` to raise it — or the promotion is
/// silently dead configuration.
const List<String> promotedButNotInFlutterLints = <String>['avoid_dynamic_calls', 'close_sinks'];

/// Every generated shape. `lib/l10n/app_localizations*.dart` is generated too
/// but is deliberately **not** excluded from analysis — it is committed source
/// that must compile.
const List<String> excludedShapes = <String>[
  "'**/*.g.dart'",
  "'**/*.drift.dart'",
  "'lib/core/db/schema_versions.dart'",
  "'test/drift/generated/**'",
  "'build/**'",
];

void main() {
  final List<String> lines = File(_options).readAsLinesSync();

  /// A key is present only if it is not commented out.
  bool declares(String needle) => lines.any((String l) {
    final String trimmed = l.trimLeft();
    return !trimmed.startsWith('#') && trimmed.contains(needle);
  });

  test('strict-casts, strict-inference and strict-raw-types are all true and '
      'the include is flutter_lints $flutterLintsVersion', () {
    for (final String mode in strictModes) {
      expect(
        declares('$mode: true'),
        isTrue,
        reason:
            '$mode is not set true. The load-bearing one is strict-casts: '
            'every row out of SQLite and every field out of a JSON backup is '
            'a dynamic-adjacent boundary',
      );
    }
    expect(declares('include: package:flutter_lints/flutter.yaml'), isTrue);

    // The other half: the version is pinned exactly, not a caret range.
    expect(
      File(
        _pubspec,
      ).readAsLinesSync().any((String l) => l.trim() == 'flutter_lints: $flutterLintsVersion'),
      isTrue,
      reason:
          'pubspec.yaml does not pin flutter_lints to exactly '
          '$flutterLintsVersion; a caret admits a version §5 has not verified',
    );
  });

  test('every rule promoted under errors is also enabled by flutter_lints or '
      'by the linter block', () {
    // The dead-configuration case, and the most valuable one in this file.
    // `errors:` can raise a lint's severity only if the rule is enabled
    // somewhere. Delete either half and the promotion does nothing at all,
    // and the analyzer will not tell you.
    for (final String rule in promotedButNotInFlutterLints) {
      expect(declares('$rule: error'), isTrue, reason: '$rule is not promoted');
      expect(
        declares('- $rule'),
        isTrue,
        reason:
            '$rule is promoted but never enabled, so the promotion is '
            'dead configuration',
      );
    }
  });

  test('the exclude list names every generated shape and no freezed output', () {
    for (final String shape in excludedShapes) {
      expect(declares(shape), isTrue, reason: '$shape is not excluded');
    }
    // freezed is rejected on this stack — its analyzer constraint conflicts
    // with both drift_dev and build_runner. A line for a package that cannot
    // be installed is configuration that implies it might be.
    //
    // `declares` and not a raw substring search: the config file's own comment
    // explaining why the entry is absent contains the word, and a check that
    // cannot tell a comment from a rule is a check that fires on its own
    // documentation.
    expect(declares('freezed'), isFalse, reason: 'freezed cannot be installed on this stack');
  });

  test('there is no plugins section', () {
    // Every analyzer plugin that could express this project's rules is
    // discontinued, archived or unresolvable: custom_lint is archived upstream
    // and riverpod_lint is internally unresolvable against drift_dev's
    // analyzer ^13.0.0. That is exactly why tool/check_policy.dart exists.
    expect(declares('plugins:'), isFalse);
  });

  test('formatter page_width is 100 and no line-length lint is disabled', () {
    expect(declares('page_width: 100'), isTrue);
    // Disabling the lint leaves the formatter still wrapping at 80, and the
    // two then argue in every diff.
    expect(declares('lines_longer_than_80_chars: false'), isFalse);
    expect(declares('- lines_longer_than_80_chars'), isFalse);
  });

  test('todo is downgraded to ignore', () {
    // A TODO is an analyzer *info*, and --fatal-infos turns every one into a
    // build break. Without this line the first `// TODO` in the codebase is
    // red CI.
    expect(declares('todo: ignore'), isTrue);
  });
}

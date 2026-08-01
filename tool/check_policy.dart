// tool/check_policy.dart
//
// The single source-and-dependency gate for Shed Book.
//   dart tool/check_policy.dart
//
// NEVER `dart run`. Measured 2026-08-01 (N03-T01): the `run` subcommand does an
// implicit `pub get` and executes the package's build hooks, so on a cold hook
// cache with no network it fails at a pub.dev advisories fetch — which is
// exactly "it can fail for reasons that are not violations". Without `run` it
// exits 0 on the same tree, in ~2.5 s, of which the walk is milliseconds.
// Exit codes: 0 clean · 1 violations · 2 the gate could not run (still a failure).
//
// Dependency-free by decision (00-tech-decisions #9, #10): every analyzer plugin
// that could express these rules is discontinued, archived, or unresolvable
// against drift_dev's analyzer ^13.0.0. Do not add a second scanning script;
// the answer to a new rule is a new row in the tables below. The moment this
// script needs `pub get` it can fail for reasons that are not violations.
//
// THE RULE TABLE IS NOT CLOSED. copy.vet_advice and copy.disclaimer_retyped
// need ContentPolicy and Disclaimers and arrive with them (N06-T09). The
// db.destructive_ddl family arrives with the migration harness (N08), and
// layer.in_app_purchase / launch.store_call with monetization (N30). A row and
// the case that proves it fires land in the same commit — always.
//
// NEVER edit this file, its rule table, its exit code, or
// tool/policy_allowlist.txt to make a build pass. An [exempt] line deletes one
// rule for one file, forever, and silently. If a gate is genuinely wrong, say
// so and stop.

import 'dart:io';

const String _package = 'shed_book';

/// Walked roots. `tool/` is deliberately absent: this file's own tables contain
/// every banned literal, so scanning it would fail the build on itself.
const List<String> _roots = <String>['lib', 'test'];

/// The four allowlist sections. A header outside this set is a typo that would
/// empty a whole section, so it is refused rather than accepted.
const Set<String> _allowlistSections = <String>{
  'dependencies',
  'dev_dependencies',
  'transitive',
  'exempt',
};

/// Most specific prefix first — [_layerOf] returns the first match.
///
/// **The order is the rule.** `lib/core/ui/` and `lib/core/db/` must both
/// precede `lib/core/`, and `lib/` must be last. Sort this list alphabetically —
/// a plausible tidy-up — and `lib/core/db/database.dart` resolves to layer
/// `lib/core/`, which *is* allowed to import `lib/core/ui/`, so R16's carefully
/// drawn line disappears with no test failing.
const List<String> _layers = <String>[
  'lib/core/db/',
  'lib/core/ui/',
  'lib/core/',
  'lib/domain/',
  'lib/data/',
  'lib/features/',
  'lib/routing/',
  'lib/',
];

/// CONVENTIONS §1.1's eight layer rules, as amended. Copied, never re-derived.
const Map<String, Set<String>> _mayImport = <String, Set<String>>{
  'lib/domain/': <String>{'lib/domain/'},
  'lib/core/db/': <String>{'lib/core/db/', 'lib/core/', 'lib/domain/'}, // R16
  'lib/core/ui/': <String>{'lib/core/ui/', 'lib/domain/'},
  'lib/core/': <String>{'lib/core/', 'lib/core/ui/', 'lib/core/db/', 'lib/domain/'},
  'lib/data/': <String>{'lib/data/', 'lib/core/', 'lib/core/db/', 'lib/core/ui/', 'lib/domain/'},
  'lib/features/': <String>{
    'lib/features/',
    'lib/data/',
    'lib/domain/',
    'lib/core/',
    'lib/core/ui/',
    'lib/routing/',
  },
  'lib/routing/': <String>{
    'lib/routing/',
    'lib/features/',
    'lib/data/',
    'lib/core/',
    'lib/domain/',
  },
  'lib/': <String>{
    'lib/',
    'lib/core/',
    'lib/core/ui/',
    'lib/data/',
    'lib/domain/',
    'lib/features/',
    'lib/routing/',
  },
};

const Map<String, Set<String>> _bannedPackages = <String, Set<String>>{
  // R24: package:clock is banned in the domain. A pure function that needs the
  // current instant takes it as a parameter: timeSincePenned(enteredAt, now).
  'lib/domain/': <String>{
    'package:flutter/',
    'package:drift/',
    'package:sqlite3',
    'package:flutter_riverpod/',
    'package:riverpod/',
    'package:intl/',
    'package:clock/',
  },
  'lib/data/': <String>{'package:flutter/material.dart', 'package:flutter/cupertino.dart'},
  'lib/core/ui/': <String>{'package:drift/', 'package:sqlite3'},
  'lib/features/': <String>{'package:drift/', 'package:sqlite3'},
  'lib/routing/': <String>{'package:drift/', 'package:sqlite3'},
  'lib/': <String>{'package:drift/', 'package:sqlite3'},
};

/// Path-pair bans. Not expressible in [_mayImport], because `lib/data/` may
/// import the rest of `lib/domain/` freely. R53 — spec §12.4's structural half,
/// and the one rule in this table a reviewer may never wave through.
const List<(String, String, String)> _bannedPathPairs = <(String, String, String)>[
  ('layer.data_no_validation', 'lib/data/', 'lib/domain/validation/'),
];

/// The importing layer → the id its direction violation is reported under.
///
/// `01 §3.2`'s printed driver emits `layer.direction` and `layer.import`, and
/// neither is one of CONVENTIONS §1.1's ten ids — so the inventory assertion
/// would face ten ids with no proving case and two proving cases with no id.
/// `lib/routing/` shares `layer.features` because §1.1 gives routing no id of
/// its own, and the two-way routing↔features edge is deliberate.
const Map<String, String> _directionRuleId = <String, String>{
  'lib/domain/': 'layer.domain',
  'lib/core/db/': 'layer.core_db',
  'lib/core/ui/': 'layer.core_ui',
  'lib/core/': 'layer.core_ui',
  'lib/data/': 'layer.data',
  'lib/features/': 'layer.features',
  'lib/routing/': 'layer.features',
  'lib/': 'layer.root',
};

/// Every layer rule id, in CONVENTIONS §1.1's order. Listed rather than derived
/// from the maps above, because `layer.sibling`, `layer.single_writer` and
/// `layer.data_no_validation` are emitted by code and not by a map entry, and
/// an inventory that cannot see them is an inventory with holes.
const List<String> _layerRuleIds = <String>[
  'layer.domain',
  'layer.core_db',
  'layer.data',
  'layer.data_no_material',
  'layer.features',
  'layer.sibling',
  'layer.core_ui',
  'layer.single_writer',
  'layer.root',
  'layer.data_no_validation',
];

/// G3 of the offline contract. Applies to **every scanned file**, in both roots,
/// regardless of layer — a network dependency in the test tier is still in the
/// graph. Reported under `layer.import`, which is the one import id that is not
/// a direction rule.
///
/// `package:firebase_` and `package:google_mlkit_` carry **no trailing slash**:
/// they are prefixes over a family of packages, not a single package root, and
/// adding the slash silently unbans `firebase_core`.
///
/// `package:printing/` and `package:google_fonts/` are banned here *and* on G2's
/// allowlist. That is not duplication: G2 stops the package entering the graph,
/// G3 stops a source file importing it if it ever does — transitively, for
/// instance, via a package that vendors it.
const Set<String> _bannedEverywhere = <String>{
  'package:http/',
  'package:dio/',
  'package:connectivity_plus/',
  'package:workmanager/',
  'package:battery_plus/',
  'package:web_socket_channel/',
  'package:firebase_',
  'package:google_fonts/',
  'package:printing/',
  'package:speech_to_text/',
  'package:google_mlkit_',
  'package:permission_handler/',
};

/// (id, literal text, path prefix it applies under, why). An empty `under`
/// means every scanned root — the driver never walks anything else.
///
/// **The `net.*` rows are not redundant with [_bannedEverywhere].** That set
/// matches `package:` URIs, and the highest-risk socket APIs in this app do not
/// arrive on one: `HttpClient`, `Socket` and `WebSocket` come from `dart:io`,
/// which every file may legitimately import, and `Image.network` is in the
/// Flutter SDK. G3 claims our own source cannot reach a network API; without
/// these rows it is not proved.
///
/// **There is no rule that reads `pubspec.lock` for `http`, and there must never
/// be one.** `http 1.6.0` sits on two REGULAR edges —
/// `flutter_local_notifications → timezone → http`, and
/// `wakelock_plus → package_info_plus → http`. Such a rule is permanently red,
/// so it gets deleted by whoever meets it first, and then there is no gate at
/// all. The claim G2 makes is narrower and true: no package enters the graph
/// unreviewed. (00-tech-decisions §3.4 #1, 13 §2.4.) `test/policy/gate_rules_test.dart`
/// holds that as an assertion, because a comment cannot stop a future row.
///
/// **There is no `Uri.parse(` row, and that is a decision.** A bare one would
/// fire on the media store's relative paths, on the restore path and on
/// `share_plus`'s file URIs — all legitimate, none a network path. `01 §3.3`
/// names the anti-pattern: a rule that gets weakened is worse than one never
/// written. If a scheme check is ever wanted it belongs where a URI is actually
/// constructed, and that is one file.
const List<(String, String, String, String)> _bannedText = <(String, String, String, String)>[
  // 'Socket.connect(' also matches RawSocket.connect( and SecureSocket.connect(,
  // because both contain it. Deliberate, and why the row carries the dot and the
  // open paren rather than a bare `Socket`.
  //
  // 'HttpClient(' misses `HttpClient.new` and a torn-off constructor. Both are
  // legal Dart and neither contains the literal. That is the honest limit of a
  // text gate: G3 proves our source has no obvious network call site, not that
  // it cannot possibly open a socket. What G3 does not prove is G1's job, and
  // the split is the point (13 §2.5). Upgrade the claim's honesty, never the row.
  ('net.http_client', 'HttpClient(', 'lib/', 'dart:io socket — G3'),
  ('net.socket', 'Socket.connect(', 'lib/', 'dart:io socket — G3'),
  ('net.web_socket', 'WebSocket.', 'lib/', 'dart:io socket — G3'),
  ('net.image_network', 'Image.network(', 'lib/', 'no remote assets — G3'),
  // Bans an identifier, not an import: PdfGoogleFonts is a class inside
  // package:printing, and #83 keeps pdf and rejects printing exactly because
  // the class is a one-line footgun. The row fires on a copied snippet before
  // the import is even added.
  ('net.pdf_fonts', 'PdfGoogleFonts', 'lib/', 'fetches fonts over HTTP — G3, #83'),
  // No exemption, deliberately: R25's one ticker is built on Future.delayed
  // precisely so this row needs no waiver (#66). A developer reaching for
  // Timer.periodic at N12 is this row working, not this row being wrong.
  (
    'net.sync_timer',
    'Timer.periodic(',
    'lib/',
    'per-row timers and refresh loops are both banned; the one ticker uses '
        'Future.delayed so this rule needs no exemption — #66, #7',
  ),
];

/// Same tuple, a pattern instead of a literal. `final`, not `const`: RegExp has
/// no const constructor.
final List<(String, RegExp, String, String)> _bannedPattern = <(String, RegExp, String, String)>[];

/// Every rule id this script can emit, in declaration order. N03-T07's
/// inventory assertion iterates this; a rule that is not here cannot be proved.
Iterable<String> get policyRuleIds sync* {
  yield* _layerRuleIds;
  yield 'layer.import';
  for (final (String id, _, _, _) in _bannedText) {
    yield id;
  }
  for (final (String id, _, _, _) in _bannedPattern) {
    yield id;
  }
}

/// Every text and pattern rule as (id, the path prefix it applies under).
///
/// Exposed for one assertion and one only: **no rule's scope may be
/// `pubspec.lock`.** A rule that reads the lockfile for `http` is unsatisfiable
/// — see [_bannedText] — and a comment cannot stop a future contributor writing
/// one. A test can.
Iterable<(String, String)> get policyRuleScopes sync* {
  for (final (String id, _, String under, _) in _bannedText) {
    yield (id, under);
  }
  for (final (String id, _, String under, _) in _bannedPattern) {
    yield (id, under);
  }
}

/// `import` and `export` alike. A re-export moves a symbol across a layer
/// boundary exactly as an import does, which is what makes `lib/data/models.dart`
/// (R20, the one file that re-exports every drift row type) a legal
/// concentration point rather than a hole.
///
/// Configurable imports — `import '…' if (dart.library.io) '…'` — are not
/// matched. There are none in this project and none is permitted.
final RegExp _directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

/// Null for anything outside `lib/` — layer direction does not apply there. The
/// test tier is allowed to reach the database.
String? _layerOf(String path) {
  for (final String layer in _layers) {
    if (path.startsWith(layer)) {
      return layer;
    }
  }
  return null;
}

/// `'lib/features/flock/flock_screen.dart'` + `'../../data/models.dart'`
///   → `'lib/data/models.dart'`.
///
/// `..` pops a segment and does not clamp at the root: a path with more `..`
/// than depth escapes `lib/`, resolves to no layer and is skipped. The analyzer
/// rejects such an import anyway, so this is recorded rather than guarded.
String _resolveRelative(String from, String uri) {
  final List<String> parts = from.split('/')..removeLast();
  for (final String segment in uri.split('/')) {
    if (segment.isEmpty || segment == '.') {
      continue;
    }
    if (segment == '..') {
      if (parts.isNotEmpty) {
        parts.removeLast();
      }
    } else {
      parts.add(segment);
    }
  }
  return parts.join('/');
}

/// Which of CONVENTIONS §1.1's ids a banned **package** import is reported under.
///
/// Rule 8 is the writer ban and it is keyed on the package, not the layer:
/// `package:sqlite3` anywhere outside `lib/data/` and `lib/core/db/` is
/// `layer.single_writer`. Rule 4 is likewise keyed on the package. Everything
/// else is the importing layer's own id.
String _packageRuleId(String layer, String package) {
  if (package.startsWith('package:sqlite3')) {
    return 'layer.single_writer';
  }
  if (layer == 'lib/data/' && package.startsWith('package:flutter/')) {
    return 'layer.data_no_material';
  }
  return _directionRuleId[layer]!;
}

/// 00-README §7.3: everything generated is named so you can see it, and the
/// gate always skips it. Never hand-edit one; `make gen` is the only writer.
///
/// Three of the four shapes are not `*.g.dart`. `app_localizations*.dart` comes
/// from gen-l10n and holds user-facing strings the vocabulary rules would fire
/// on; `test/drift/generated/**` comes from `drift_dev schema steps` and holds
/// generated SQL. All four are committed (00-README §7.1) and all four are
/// walked by a driver that only checks two suffixes.
bool _isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.drift.dart') ||
    path.contains('/app_localizations') ||
    path.contains('test/drift/generated/');

/// The file kinds the gate reads. N03-T06 widens this to `.arb`, because the
/// vocabulary rules have to read `lib/l10n/app_en.arb` — one predicate, so that
/// is a one-line change and not a rewrite of the walk.
bool _isScannable(String path) => path.endsWith('.dart');

/// Every file the gate will read under [root], as repository-relative paths,
/// **sorted**.
///
/// `Directory.listSync(recursive: true)` returns filesystem order, which
/// differs between macOS and the `ubuntu-latest` runner. Sorting here rather
/// than only sorting the violations means the walk itself is reproducible, so a
/// future short-circuit cannot make the first reported message machine-dependent.
List<String> scannedFiles(String root) {
  final List<String> out = <String>[];
  for (final String name in _roots) {
    final Directory dir = Directory(_join(root, name));
    if (!dir.existsSync()) {
      continue;
    }
    for (final FileSystemEntity entity in dir.listSync(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      final String path = _relative(entity.path, root);
      if (!_isScannable(path) || _isGenerated(path)) {
        continue;
      }
      out.add(path);
    }
  }
  return out..sort();
}

/// Pure. Walks [root], applies every rule, returns one message per violation.
/// Never prints and never exits — `main()` owns the process.
///
/// Throws [PolicyConfigProblem] if the gate cannot read its own configuration.
List<String> runPolicy({String root = '.'}) {
  final Map<String, Set<String>> allow = readAllowlist(root);
  final Set<String> exempt = allow['exempt'] ?? const <String>{};
  final List<String> violations = <String>[];

  for (final String path in scannedFiles(root)) {
    final String source = File(_join(root, path)).readAsStringSync();

    for (final (String id, String text, String under, String why) in _bannedText) {
      if (!path.startsWith(under) || !source.contains(text)) {
        continue;
      }
      if (exempt.contains('$path :: $id')) {
        continue;
      }
      violations.add('[$id] $path contains "$text" — $why');
    }

    for (final (String id, RegExp pattern, String under, String why) in _bannedPattern) {
      if (!path.startsWith(under) || !pattern.hasMatch(source)) {
        continue;
      }
      if (exempt.contains('$path :: $id')) {
        continue;
      }
      violations.add('[$id] $path matches ${pattern.pattern} — $why');
    }

    violations.addAll(_checkImports(path, source, exempt));
  }

  return violations..sort();
}

/// The layer rules, for one file. CONVENTIONS §1.1.
List<String> _checkImports(String path, String source, Set<String> exempt) {
  final List<String> violations = <String>[];
  final String? layer = _layerOf(path);

  for (final RegExpMatch match in _directive.allMatches(source)) {
    String uri = match.group(1)!;

    for (final String banned in <String>{..._bannedEverywhere, ...?_bannedPackages[layer]}) {
      if (!uri.startsWith(banned) || exempt.contains('$path :: import:$uri')) {
        continue;
      }
      final String id = _bannedEverywhere.contains(banned)
          ? 'layer.import'
          : _packageRuleId(layer!, banned);
      violations.add('[$id] $path (${layer ?? 'test'}) may not import $uri');
    }

    // No layer direction outside lib/.
    if (layer == null) {
      continue;
    }

    if (uri.startsWith('package:$_package/')) {
      uri = 'lib/${uri.substring('package:$_package/'.length)}';
    } else if (uri.startsWith('dart:') || uri.startsWith('package:')) {
      // A package: URI that is not banned is legal — `package:collection` in
      // the domain, for one — and never reaches the direction check.
      continue;
    } else {
      uri = _resolveRelative(path, uri);
    }

    for (final (String id, String fromPrefix, String toPrefix) in _bannedPathPairs) {
      if (path.startsWith(fromPrefix) && uri.startsWith(toPrefix)) {
        violations.add('[$id] $path may not import $uri');
      }
    }

    final String? to = _layerOf(uri);
    if (to == null) {
      continue;
    }
    if (!_mayImport[layer]!.contains(to)) {
      violations.add('[${_directionRuleId[layer]}] $path ($layer) may not import $to  [$uri]');
      continue;
    }
    // Rule 6 fires only when the IMPORTING file is under lib/features/, so
    // routing may name all nine features and a feature still may not name a
    // sibling. The asymmetry is deliberate (01 §3.1).
    if (layer == 'lib/features/' && to == 'lib/features/') {
      final String a = path.split('/')[2];
      final String b = uri.split('/')[2];
      if (a != b) {
        violations.add(
          '[layer.sibling] $path: feature "$a" may not import feature "$b" — '
          'move the shared piece into lib/data/ or lib/domain/',
        );
      }
    }
  }
  return violations;
}

/// Parses `<root>/tool/policy_allowlist.txt`.
///
/// `[section]` headers, one entry per line, `#` starts a comment. Throws
/// [PolicyConfigProblem] on a malformed line, naming the file and the 1-based
/// line number; `main()` turns that into exit 2.
///
/// `[exempt]` keys are **normalised** to `'<path> :: <id>'`. The file is
/// column-aligned for readability and the driver looks the key up unpadded, so
/// storing the raw line makes every exemption ever written silently inert — the
/// gate goes red on a file that carries a waiver, somebody deletes the rule, and
/// nobody sees it happen.
Map<String, Set<String>> readAllowlist(String root) {
  const String name = 'tool/policy_allowlist.txt';
  final File file = File(_join(root, name));
  if (!file.existsSync()) {
    throw const PolicyConfigProblem('$name is missing — the gate cannot run');
  }
  final Map<String, Set<String>> out = <String, Set<String>>{
    for (final String section in _allowlistSections) section: <String>{},
  };
  String? section;
  final List<String> lines = file.readAsLinesSync();
  for (int i = 0; i < lines.length; i++) {
    final String line = lines[i].split('#').first.trim();
    final int number = i + 1;
    if (line.isEmpty) {
      continue;
    }
    if (line.startsWith('[') && line.endsWith(']')) {
      section = line.substring(1, line.length - 1);
      if (!_allowlistSections.contains(section)) {
        throw PolicyConfigProblem(
          '$name line $number: unknown section "$section". '
          'The four are ${_allowlistSections.join(", ")}',
        );
      }
      continue;
    }
    if (section == null) {
      throw PolicyConfigProblem(
        '$name line $number: "$line" is outside any section. '
        'Every entry belongs under one of ${_allowlistSections.join(", ")}',
      );
    }
    out[section]!.add(section == 'exempt' ? _exemptKey(name, number, line) : line);
  }
  return out;
}

String _exemptKey(String name, int number, String line) {
  final List<String> halves = line.split('::');
  if (halves.length != 2) {
    throw PolicyConfigProblem(
      '$name line $number: "$line" is not `<path> :: <rule id>`. '
      'A waiver with no :: separator is refused, never ignored',
    );
  }
  return '${halves.first.trim()} :: ${halves.last.trim()}';
}

/// The gate could not run. Deliberately not named `…Error`: `CLAUDE.md` bans
/// `Error` as a failure-type name, and this is a configuration problem the gate
/// reports, not a failure type the app models.
final class PolicyConfigProblem implements Exception {
  const PolicyConfigProblem(this.message);
  final String message;

  @override
  String toString() => 'PolicyConfigProblem: $message';
}

String _join(String root, String path) => root == '.' ? path : '$root/$path';

String _relative(String path, String root) {
  final String normalised = path.replaceAll(r'\', '/');
  final String prefix = root == '.' ? '' : '$root/';
  return normalised.startsWith(prefix) ? normalised.substring(prefix.length) : normalised;
}

void main(List<String> args) {
  final List<String> violations;
  try {
    violations = runPolicy();
  } on PolicyConfigProblem catch (problem) {
    stderr.writeln('POLICY  ${problem.message}');
    exit(2);
  }
  if (violations.isEmpty) {
    stdout.writeln('policy ok');
    return;
  }
  for (final String line in violations) {
    stderr.writeln('POLICY  $line');
  }
  exit(1);
}

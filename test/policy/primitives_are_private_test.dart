// test/policy/primitives_are_private_test.dart — the access-control story for
// colour, as a test on source text.
//
// Dart has no directory-private visibility, so the LANGUAGE cannot hold 06
// §3.1's rule and the gate does. This file is the second holder, and it exists
// because the gate's row and this file fail differently: the row names an id,
// this names the offending file and the offending constant. At 03:20 nobody is
// reading a rule table.
//
// Every scan here reads DECLARATIONS — comment lines dropped — for the same
// reason warning_has_no_writer_test.dart does. primitives.dart's own header
// names the values measurement overruled so that nobody restores them, and a
// scan over raw text would fire on that sentence and make deleting the warning
// the cheapest fix.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _primitives = 'lib/core/ui/primitives.dart';
const String _errorPanel = 'lib/core/ui/night_error_panel.dart';
const String _allowlist = 'tool/policy_allowlist.txt';
const String _gate = 'tool/check_policy.dart';

/// The two keys N09-T01 is answerable for. Both were landed inert by N03-T05,
/// which is why this asserts their PRESENCE rather than adding them — see the
/// commit message.
const List<String> _thisTaskSKeys = <String>[
  'lib/core/ui/primitives.dart :: token.raw_color',
  'lib/core/ui/palettes.dart :: token.primitives_import',
];

/// The gate's own row, character for character (`token.primitives_import`). If
/// these two ever diverge, the gate and this file are policing different rules
/// and one of them is asleep.
final RegExp _primitivesImport = RegExp(r'''import\s+['"][^'"]*core/ui/primitives\.dart''');

/// Generated output is not authored, so it is not held to authored rules. The
/// gate's own driver skips exactly these two suffixes.
bool _isAuthored(String path) => !path.endsWith('.g.dart') && !path.endsWith('.drift.dart');

List<String> _dartFilesUnder(String root) {
  final Directory dir = Directory(root);
  if (!dir.existsSync()) {
    return const <String>[];
  }
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .map((File f) => f.path.replaceAll(r'\', '/'))
      .where((String p) => p.endsWith('.dart') && _isAuthored(p))
      .toList()
    ..sort();
}

/// [path]'s source with whole-line comments removed. `///` and `//` both start
/// with `//` once the indent is trimmed, so one filter catches both.
String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

/// The `[exempt]` section's keys, comments and blank lines dropped.
List<String> _exemptLines() {
  final List<String> lines = File(_allowlist).readAsLinesSync();
  final int start = lines.indexWhere((String l) => l.trim() == '[exempt]');
  expect(start, isNot(-1), reason: 'the allowlist has no [exempt] section');

  final List<String> keys = <String>[];
  for (final String raw in lines.skip(start + 1)) {
    if (raw.trimLeft().startsWith('[')) {
      break; // the next section
    }
    final String line = raw.split('#').first.trim();
    if (line.isEmpty) {
      continue;
    }
    // Collapse runs of spaces so the key compares independently of the
    // column alignment the file uses for readability.
    keys.add(line.replaceAll(RegExp(r'\s+'), ' '));
  }
  return keys;
}

/// Every `const <name> = Color(0x…)` in primitives.dart, as (name, hex).
List<(String, String)> _colourConstants() {
  // The optional `Color ` is not cosmetic: analysis_options.yaml's strict block
  // means every declaration in primitives.dart carries its type, so a regex
  // written against the untyped form matches nothing and every case below goes
  // green over an empty list.
  final RegExp declaration = RegExp(
    r'const\s+(?:Color\s+)?(\w+)\s*=\s*Color\(0x([0-9A-Fa-f]{8})\)',
  );
  return declaration
      .allMatches(_declarations(_primitives))
      .map((RegExpMatch m) => (m.group(1)!, m.group(2)!.toUpperCase()))
      .toList();
}

void main() {
  test('primitives.dart is imported by no file outside lib/core/ui/ and has exactly '
      'two allowlist lines', () {
    // The existence assertion is FIRST and it is not ceremony. Every other
    // clause in this case is satisfied by a repository with no primitives.dart
    // at all — no file exists, so no file imports it, so the set is empty and
    // the case goes green having proved nothing. That is the exact shape of a
    // test that passes for the wrong reason, and the task's own "why it is red
    // today" line says the file's absence is what red means.
    expect(
      File(_primitives).existsSync(),
      isTrue,
      reason: '$_primitives does not exist, so every other clause here is vacuous',
    );

    final List<String> importers = _dartFilesUnder(
      'lib',
    ).where((String p) => _primitivesImport.hasMatch(_declarations(p))).toList();

    final List<String> outsiders = importers
        .where((String p) => !p.startsWith('lib/core/ui/'))
        .toList();

    expect(
      outsiders,
      isEmpty,
      reason:
          '06 §3.1: primitives are private to lib/core/ui/. These files reach '
          'past tokens.dart to the raw values',
    );

    final List<String> exempt = _exemptLines();
    for (final String key in _thisTaskSKeys) {
      expect(exempt, contains(key), reason: 'the allowlist lost a line this file depends on');
    }
  });

  test('the [exempt] section has exactly five lines and every id it names exists '
      'in the rule table', () {
    final List<String> exempt = _exemptLines();

    // R56 fixes the day-one total. A fifth line is a review conversation, not a
    // keystroke, and this is the assertion that makes that true rather than
    // aspirational.
    // **FIVE SINCE 2026-08-04** (decision-record §7.0d). The fifth is
    // `lib/data/purchase_service.dart :: copy.banned_word` —
    // `PurchaseStatus.pending` is the `in_app_purchase` plugin's own enum member,
    // in the acknowledgement guard and the exhaustive switch arm, and neither is
    // removable or ours.
    //
    // **R56 WAS NEVER ABOUT THE NUMBER FOUR.** It was about a new line requiring
    // somebody to say why, in front of a reader — which is why FOUR SEPARATE
    // TESTS assert this count and all four had to be edited, deliberately, in
    // the commit that added it. The sixth costs the same.
    expect(
      exempt,
      hasLength(5),
      reason: 'R56, amended: five, and the sixth is another review conversation',
    );

    // The silent-typo case, and the more valuable half. A key naming an id no
    // row declares exempts NOTHING — silently — and reads as correct in a diff
    // forever. 01 §3.2 fixes the format as '<path> :: <id>'.
    final String gate = File(_gate).readAsStringSync();
    for (final String key in exempt) {
      final List<String> halves = key.split(' :: ');
      expect(halves, hasLength(2), reason: 'malformed key: $key');

      expect(
        gate,
        contains("'${halves[1]}'"),
        reason:
            '${halves[1]} is named by an [exempt] line but no rule in '
            '$_gate declares it, so that line waives nothing',
      );
    }
  });

  test('primitives.dart imports only dart:ui', () {
    // Catches the package:flutter/material.dart slip before token.material_color
    // has to. That import pulls `Colors.` into scope in the one file that must
    // not have it, and the exemption this file carries is for token.raw_color
    // only — it would not cover it.
    final List<String> imports = _declarations(_primitives)
        .split('\n')
        .where((String l) => l.trimLeft().startsWith('import '))
        .map((String l) => l.trim())
        .toList();

    expect(imports, <String>["import 'dart:ui' show Color;"]);
  });

  test('no const in primitives.dart is named after its job', () {
    // The tier boundary, made executable. A primitive that already knows it is
    // the strike colour has skipped a tier and pre-empted tokens.dart's only
    // decision.
    //
    // Scoped to the COLOUR declarations. The scale constants are `s04`,
    // `tapMin`, `ruleW` — a single regex covering both families would have to
    // be loose enough to admit `tapMin`, and then it admits `nPage` too.
    final List<(String, String)> colours = _colourConstants();
    expect(colours, isNotEmpty, reason: 'no Color constants found — has the file moved?');

    final RegExp valueNamed = RegExp(r'^[narh][A-Z][A-Za-z]+[0-9]*$');
    for (final (String name, _) in colours) {
      expect(
        valueNamed.hasMatch(name),
        isTrue,
        reason:
            '$name is not <palette letter><hue or role><step> — 06 §3.2. '
            'A meaning-free name is what stops this tier deciding anything',
      );
    }

    // The job words, spelled apart from the names above so this loop cannot
    // match on its own source if the file is ever scanned as raw text.
    for (final (String name, _) in colours) {
      final String lower = name.toLowerCase();
      for (final String job in <String>[
        'page',
        'strike',
        'struck',
        'spine',
        'border',
        'disabled',
        'error',
        'pressed',
      ]) {
        expect(
          lower.contains(job),
          isFalse,
          reason: '$name names what the value is FOR. That belongs in tokens.dart',
        );
      }
    }
  });

  test('every colour literal under lib/ is in primitives.dart or night_error_panel.dart', () {
    // The positive form of the gate's token.raw_color row, so a failure names
    // the offending FILE rather than a rule id. night_error_panel.dart is
    // exempt for a different reason from this file's: 06 §2.4 — it renders with
    // no Theme, no MediaQuery and no Directionality in scope, so it cannot read
    // a token even in principle.
    final List<String> offenders = _dartFilesUnder('lib')
        .where((String p) => p != _primitives && p != _errorPanel)
        .where((String p) => _declarations(p).contains('Color(0x'))
        .toList();

    expect(offenders, isEmpty, reason: 'read context.tokens — #97');
  });

  test('no two constants carry the same hex', () {
    // A duplicated value means the next tier picks one arbitrarily and the
    // palette gains an invisible alias that survives every rename.
    final List<(String, String)> colours = _colourConstants();
    final Map<String, List<String>> byHex = <String, List<String>>{};
    for (final (String name, String hex) in colours) {
      byHex.putIfAbsent(hex, () => <String>[]).add(name);
    }

    final Map<String, List<String>> duplicated = Map<String, List<String>>.fromEntries(
      byHex.entries.where((MapEntry<String, List<String>> e) => e.value.length > 1),
    );
    expect(duplicated, isEmpty, reason: 'one value, one name');
  });

  test('every value 06 §4.2 to §4.5 publishes appears in the file', () {
    // A ramp one value short COMPILES, and fails only when a component in N10
    // reaches for the missing one.
    //
    // These are 06's ramps rather than indelible.md's, and the reason is
    // decision #95 — see the header of primitives.dart, and the P6 section of
    // the PR body. It is asserted here as well as commented there because the
    // pull toward "restoring" the warmer indelible ramp will be strong, and it
    // has to fail loudly rather than merely disagree with a comment.
    const List<String> night = <String>[
      '0A0A0B', '12161A', '1A2025', '242B31', //
      '8A9199', 'B7BDC4', 'E8EAED', 'FFFFFF',
      '7DD3A0', 'FFD54F', 'FFB4AB',
    ];
    const List<String> amber = <String>[
      '000000', '140D00', '1F1400', //
      'FFE0A3', 'FFC46B', 'FFB000', 'D68F00', 'C98400', 'A66E00',
    ];
    const List<String> deepRed = <String>[
      '1A0503', '2A0806', 'FF9E80', 'FF6B4A', 'FF4400', 'E62200', 'CC2200', //
    ];
    const List<String> highContrast = <String>['7A7A7A', 'A8F0C6', 'FFE08A', 'FFC7BD'];

    final Set<String> present = _colourConstants()
        .map(((String, String) c) => c.$2.substring(2)) // drop the FF alpha
        .toSet();

    for (final String hex in <String>[...night, ...amber, ...deepRed, ...highContrast]) {
      expect(present, contains(hex), reason: '06 §4 publishes #$hex and this file lost it');
    }
  });

  test('neither value indelible.md §2.4 records as overruled is present', () {
    // #6B675F measures 3.52:1 as struck ink and #A63A32 measures 3.08:1 as the
    // madder. Both look better than what replaced them, and rule 4 does not
    // negotiate with taste.
    //
    // Under the P6 resolution neither is in the shipped ramp at all, so this
    // case is weaker than it was when indelible.md supplied the values — it now
    // guards against someone reintroducing them rather than against a demotion
    // being undone. It is kept because that reintroduction is exactly what
    // "restore the prettier value" would look like in a diff.
    final Set<String> hexes = _colourConstants()
        .map(((String, String) c) => c.$2.substring(2))
        .toSet();
    expect(hexes, isNot(contains('A63A32')), reason: 'overruled by indelible.md §2.4 rule 4');
    expect(hexes, isNot(contains('6B675F')), reason: 'overruled by indelible.md §2.4 rule 4');
  });
}

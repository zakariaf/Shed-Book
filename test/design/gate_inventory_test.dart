// test/design/gate_inventory_test.dart — the honesty check.
//
// Small on purpose. It asserts nothing about the app; it asserts things about
// the GATES — that the four that can honestly run today exist, that none of them
// pretends to a coverage it does not have, and that a fifth cannot appear
// silently.
//
// Critique defect S7 is "a gate written before the thing it gates", and it
// happened once already in this project. The cases here are what stop it
// happening again by accident: a sweep over an empty table passes, forever, and
// reads as coverage in every report.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _dir = 'test/design';

/// The four gate files N09 lands, and the helper they share.
const List<String> _expected = <String>[
  'contrast_test.dart',
  'formatters_test.dart',
  'gate_inventory_test.dart',
  'haptics_test.dart',
  'reduce_motion_test.dart',
  'tap_target_test.dart',
  'theme_test.dart',
  'tokens_test.dart',
  'typography_test.dart',
  'wcag.dart',
];

/// Files directly in `test/design/`, dotfiles excluded.
///
/// `.gitkeep` is excluded rather than listed: `tree_shape_test.dart` requires
/// one in every leaf directory so a fresh clone reproduces the tree, and it is a
/// git artefact rather than a gate.
///
/// **Not recursive.** `test/design/uk_zone/formatters_dst_test.dart` lives one
/// level down because a `uk-zone` tag has to be library-level — `flutter_test`'s
/// `group` takes no `tags` parameter — and it is a DST case rather than a gate,
/// so it is deliberately outside this inventory.
List<String> _filesInDesign() =>
    Directory(_dir)
        .listSync()
        .whereType<File>()
        .map((File f) => f.uri.pathSegments.last)
        .where((String name) => !name.startsWith('.'))
        .toList()
      ..sort();

void main() {
  test('test/design/ holds wcag.dart, contrast_test.dart, tap_target_test.dart '
      'and reduce_motion_test.dart', () {
    // The four the task names, plus the four this epic's other tasks landed
    // beside them. Asserted as an EXACT set rather than a subset: a fifth gate
    // file appearing without a task behind it is exactly what this case exists
    // to catch, and `containsAll` would not catch it.
    expect(_filesInDesign(), _expected);

    for (final String name in <String>[
      'wcag.dart',
      'contrast_test.dart',
      'tap_target_test.dart',
      'reduce_motion_test.dart',
    ]) {
      expect(File('$_dir/$name').existsSync(), isTrue, reason: name);
    }
  });

  test('no file in test/design/ references the variant table yet', () {
    // S7, made mechanical. The needle is split across two adjacent literals so
    // this file does not fire on itself — Dart concatenates them at compile
    // time, so the runtime value is whole while the source text is not.
    //
    // When N33-T02 and N33-T03 land the sweeps, THIS CASE IS UPDATED IN THE SAME
    // COMMIT THAT EARNS THE CHANGE. That is the point: the change is visible in
    // a diff rather than arriving as a quiet new import.
    const String needle =
        'kPumpable'
        'Variants';

    for (final String name in _filesInDesign()) {
      final String body = File(
        '$_dir/$name',
      ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');
      expect(body, isNot(contains(needle)), reason: '$name iterates a table that is not populated');
    }
  });

  test('each gate file states its scope and names where its sweep lands', () {
    // A gate with no stated scope is a gate that grows silently. Each of these
    // three carries, in its head comment, the sentence saying what it does NOT
    // cover and which task picks that up.
    const Map<String, List<String>> mustMention = <String, List<String>>{
      'contrast_test.dart': <String>['12 §7.6', 'N33'],
      'tap_target_test.dart': <String>['N33-T02', 'N33-T03'],
      'reduce_motion_test.dart': <String>['N33-T02', 'N33-T03'],
      'wcag.dart': <String>['06 §3.5'],
    };

    for (final MapEntry<String, List<String>> e in mustMention.entries) {
      final String source = File('$_dir/${e.key}').readAsStringSync();
      for (final String marker in e.value) {
        expect(source, contains(marker), reason: '${e.key} does not name $marker');
      }
    }
  });

  test('semantics_gate_test.dart does not exist yet', () {
    // AN EMPTY GATE FILE READS AS COVERAGE, which is worse than a missing one:
    // it appears in every listing, it passes, and nobody opens it.
    //
    // This case deletes itself at N33-T02, in the commit that gives the file
    // something to sweep.
    expect(
      File('$_dir/semantics_gate_test.dart').existsSync(),
      isFalse,
      reason: 'if this file now exists, it must actually sweep something',
    );
  });
}

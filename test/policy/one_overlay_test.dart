// test/policy/one_overlay_test.dart — there is one overlay in this app.
//
// The gate holds the SPELLINGS; this file holds the CALL-SITE SETS. The
// difference matters: `ui.show_dialog` can see a literal and cannot see an
// omission, so a sheet opened without `enableDrag: false` passes the gate and
// ships drag-to-dismiss — a banned gesture that silently discards a chooser.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _sheetFile = 'lib/core/ui/components/shed_bottom_sheet.dart';

List<String> _authoredDart(String root) =>
    Directory(root)
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => f.path.replaceAll(r'\', '/'))
        .where(
          (String p) => p.endsWith('.dart') && !p.endsWith('.g.dart') && !p.endsWith('.drift.dart'),
        )
        .toList()
      ..sort();

String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

/// Files under `lib/` whose declarations call [needle].
///
/// The needle is passed in split so this file's own source never contains the
/// full token — otherwise it fires on itself, which every source-text test in
/// this project has done at least once.
List<String> _callSites(String needle) =>
    _authoredDart('lib').where((String p) => _declarations(p).contains(needle)).toList();

void main() {
  test('the modal-sheet function is called from exactly one file', () {
    // THE ANCHOR. One overlay means one call site, and the whole reason to have
    // one is that it is the only place the three permissive flags can be
    // forgotten.
    // No trailing paren in the needle: the real call is
    // `showModalBottomSheet<T>(`, and a type argument sits between the name and
    // the bracket. The first version included the paren and matched nothing —
    // which is the shape of a source-text test that passes over an empty set.
    const String needle =
        'showModal'
        'BottomSheet';
    expect(_callSites(needle), <String>[_sheetFile]);
  });

  test('the one sheet call site types all three permissive flags', () {
    // THE OMISSION THE GATE CANNOT SEE. Flutter's `enableDrag` defaults to TRUE
    // and is drag-to-dismiss; a drag handle advertises a gesture this app does
    // not support; and a scrim tap is not a labelled target, so it is invisible
    // to Switch Control.
    final String source = _declarations(_sheetFile);
    for (final String flag in <String>[
      'showDragHandle: false',
      'enableDrag: false',
      'isDismissible: false',
    ]) {
      expect(source, contains(flag), reason: flag);
    }
  });

  test('the modal-dialog function is called only from the files the rule permits', () {
    // **THE AUTHORITY MOVED, AND SO DID THIS TEST — R85.** It read
    // `tool/policy_allowlist.txt`, because that is where the exception was
    // expected to live. It lives in the RULE now: `ui.show_dialog` is a
    // `_confinedPattern` whose `only` list names the permitted files, for the
    // reason that family was built at N21-T01 — an `[exempt]` line reads *"that
    // file was excused"* where the truth is *"that file is the exception the
    // design ruled"*, and R56 fixes the allowlist at four lines.
    //
    // Still read off disk rather than retyped: a test that hard-codes the same
    // paths agrees with itself after somebody edits one.
    const String needle =
        'show'
        'Dialog';

    final String gate = File('tool/check_policy.dart').readAsStringSync();
    final int at = gate.indexOf("'ui.show_dialog'");
    expect(at, isNot(-1), reason: 'the rule is gone, not merely widened');
    // A FIXED WINDOW, NOT A SEARCH FOR THE CLOSING PAREN. The first `),` after
    // the id is inside the row's own `RegExp(r'showDialog\(')`, so a
    // paren-terminated slice reads an empty permitted set and the assertion then
    // fails with *larger than expected* — which reads as *the code is wrong*
    // rather than *the test is*. Measured.
    final Set<String> allowed = RegExp(
      "'(lib/[^']+[.]dart)'",
    ).allMatches(gate.substring(at, at + 600)).map((RegExpMatch m) => m.group(1)!).toSet();
    expect(allowed, isNotEmpty, reason: 'the rule names no permitted file');

    expect(_callSites(needle).toSet(), allowed);
  });

  test('canPop false appears only in the two destructive confirmations', () {
    // **THE NUMBER CHANGED IN THE COMMIT THAT EARNED IT, WHICH IS THE POINT.**
    // It was zero, and `07 §14.4` gave it exactly one call site at N29's season
    // delete. R85 (N23-T02) makes restore the second and corrects §14.3's *"the
    // only"* in the same commit: once step 12's rename has begun there is
    // nothing to pop back to.
    //
    // Named rather than counted, so a third arrives visibly.
    final List<String> offenders = _authoredDart(
      'lib',
    ).where((String p) => _declarations(p).contains('canPop: false')).toList();
    expect(offenders, <String>['lib/features/settings/widgets/restore_confirmation.dart']);
  });

  test('no file under lib/ names BoxShadow or sets an elevation', () {
    // indelible.md §4.2: nothing casts a shadow. A shadow is the first thing a
    // Material default puts back, and under a head torch it reads as a smudge
    // rather than as depth.
    for (final String path in _authoredDart('lib')) {
      final String source = _declarations(path);
      expect(source, isNot(contains('BoxShadow')), reason: path);
      expect(source, isNot(matches(RegExp(r'elevation:\s*[1-9]'))), reason: path);
    }
  });
}

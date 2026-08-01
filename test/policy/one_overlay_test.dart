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
const String _allowlist = 'tool/policy_allowlist.txt';

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

  test('the modal-dialog function is called only from the allowlisted files', () {
    // Read off disk rather than retyped: the allowlist is the authority, and a
    // test that hard-codes the same two paths would agree with itself after
    // somebody edited one.
    const String needle =
        'show'
        'Dialog';

    final Set<String> allowed = File(_allowlist)
        .readAsLinesSync()
        .map((String l) => l.split('#').first.trim())
        .where((String l) => l.contains('ui.show_dialog'))
        .map((String l) => l.split('::').first.trim())
        .toSet();

    expect(_callSites(needle).toSet(), allowed);
  });

  test('no file under lib/ constructs a PopScope with canPop false', () {
    // Today the expected count is ZERO. 07 §14.4 gives it exactly one call site
    // at N29, and this test is where that stays deliberate — the number changes
    // in the commit that earns it, visibly, rather than by drift.
    final List<String> offenders = _authoredDart(
      'lib',
    ).where((String p) => _declarations(p).contains('canPop: false')).toList();
    expect(offenders, isEmpty);
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

// test/policy/g0_recorded_test.dart — decision-record §1 item 5; 13 §2.2.
//
// G0 is not a CI job. It is a procedure somebody ran once against a real
// release `.aab`, and this file is the only thing that stops its record
// rotting back into prose. It re-implements no part of `bundletool`: it holds
// two documents to an artefact a human read, and it fails — never skips — if
// either document has moved out from under it.
//
// `flutter test` runs with the package root as the working directory, so these
// paths are relative and no asset bundle is involved.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _thirteen = 'docs/engineering/13-build-ci-release.md';
const String _decisions = 'docs/research/00-tech-decisions.md';

/// The four rows of `13` §2.2's table, as (question, answer, recordedOn).
///
/// Sliced from the `### 2.2` heading to the next `### ` — never whole-file. The
/// word UNVERIFIED appears twice more in `13` (§2.3's `bundletool` note and a
/// comment inside §4.3's YAML) and both are legitimate, so a whole-file scan is
/// red forever and then gets weakened by whoever hits it.
List<(String, String, String)> _g0Table() {
  final List<String> section = _section(_thirteen, '### 2.2');
  final List<(String, String, String)> rows = <(String, String, String)>[];
  bool fenced = false;
  for (final String line in section) {
    final String trimmed = line.trim();
    // §2.2 carries shell and YAML blocks whose pipes would otherwise read as
    // table cells. Skipping fences is not tidiness: `| grep … | sed … | sort -u`
    // splits into as many parts as a data row.
    if (trimmed.startsWith('```')) {
      fenced = !fenced;
      continue;
    }
    if (fenced || !trimmed.startsWith('|')) {
      continue;
    }
    final List<String> cells = trimmed.split('|').map((String cell) => cell.trim()).toList();
    // A leading and a trailing `|` give an empty first and last element.
    if (cells.length != 5) {
      continue;
    }
    final String question = cells[1];
    // The header row and the `|---|` separator are not data.
    if (question == 'Question' || question.replaceAll('-', '').isEmpty) {
      continue;
    }
    rows.add((question, cells[2], cells[3]));
  }
  return rows;
}

/// The permission names in decision-record §3.3's **first** fenced block, which
/// is the as-built set — the one G0 read off the artefact. The second block in
/// that section is what N31-T02 will add and is deliberately not read here.
Set<String> _canonicalPermissions() {
  final List<String> section = _section(_decisions, '### 3.3');
  final List<String> block = <String>[];
  bool inside = false;
  for (final String line in section) {
    if (line.trimLeft().startsWith('```')) {
      if (inside) {
        break;
      }
      inside = true;
      continue;
    }
    if (inside) {
      block.add(line);
    }
  }
  expect(
    block,
    isNotEmpty,
    reason: 'decision-record §3.3 has no fenced block — G0 has nothing to compare against',
  );
  return _permissionsIn(block.join('\n'));
}

/// The permission names inside one table cell, or one fenced block.
///
/// Compared as a **set**, so whitespace and ordering churn in a markdown table
/// cannot turn a real regression into noise, or noise into a green.
Set<String> _permissionsIn(String text) => RegExp(
  r'\b(?:android\.permission\.[A-Z_]+|com\.android\.vending\.BILLING'
  r'|[a-z][a-z0-9.]*\.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION)',
).allMatches(text).map((RegExpMatch m) => m.group(0)!).toSet();

/// The three source-set manifests a `flutter create` project has.
///
/// Named, never walked. `build/` is gitignored, so it is absent in CI and
/// present on the machine that just ran T01's B19 experiment — where it holds a
/// **merged** manifest carrying exactly the directive this guard bans. A
/// recursive walk is therefore green in CI and red locally, which is the shape
/// 13 §2.8 warns about when it bans grepping `build/app/intermediates/`.
/// `src/profile` is the one people forget, and it is the interesting one:
/// `src/debug` and `src/profile` exist to hold `INTERNET` for hot reload.
const List<String> _manifests = <String>[
  'android/app/src/main/AndroidManifest.xml',
  'android/app/src/debug/AndroidManifest.xml',
  'android/app/src/profile/AndroidManifest.xml',
];

/// Any directive that deletes something at merge time — not just the one
/// spelling. `tools:node="removeAll"` is not caught by a match on
/// `tools:node="remove"` (the closing quote is in the way), and
/// `tools:remove="android:name"` deletes an attribute rather than an element.
final RegExp _removalDirective = RegExp(r'''tools:(node\s*=\s*['"]remove(All)?['"]|remove\s*=)''');

/// The questions of `13` §2.2 whose Answer or *Recorded on* cell is unfilled.
///
/// The sentinel is the **column**, not only the word: reverting a date to `—`
/// must re-arm the guard just as reverting an answer does.
Iterable<String> _unverifiedRows() => _g0Table()
    .where(
      ((String, String, String) row) =>
          row.$2.contains('UNVERIFIED') ||
          row.$2.toLowerCase().contains('not yet run') ||
          row.$3.trim() == '—',
    )
    .map(((String, String, String) row) => row.$1);

/// The lines of one `###` section of [path], heading excluded.
///
/// An absent file or an absent heading **fails**; `13` §2.3 on G1 is explicit
/// that a gate which could not run "is still a failure, never a skip".
List<String> _section(String path, String heading) {
  final File file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path is missing');
  final List<String> lines = file.readAsLinesSync();
  // `$heading ` and not `$heading`: a prefix match reads `### 2.2x` as `### 2.2`,
  // which is how a renamed section stays silently "found" and the guard keeps
  // passing against a table that is no longer there. Drilled 2026-08-01.
  final int start = lines.indexWhere(
    (String l) => l.trimRight() == heading || l.startsWith('$heading '),
  );
  expect(start, isNot(-1), reason: '$path has no `$heading` heading');
  final List<String> out = <String>[];
  for (int i = start + 1; i < lines.length; i++) {
    if (lines[i].startsWith('### ') || lines[i].startsWith('## ')) {
      break;
    }
    out.add(lines[i]);
  }
  return out;
}

void main() {
  test(
    'the merged-manifest table in 13 §2.2 names every uses-permission the real AAB declares',
    () {
      final List<(String, String, String)> rows = _g0Table();
      expect(rows, hasLength(4), reason: '13 §2.2 fixes four questions');
      for (final (String question, String answer, String recordedOn) in rows) {
        expect(answer, isNot(contains('UNVERIFIED')), reason: question);
        expect(answer.toLowerCase(), isNot(contains('not yet run')), reason: question);
        expect(recordedOn, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')), reason: question);
      }
      // Row 1's set is decision-record §3.3's as-built set, spelling for spelling.
      final Set<String> recorded = _permissionsIn(rows.first.$2);
      expect(recorded, isNotEmpty, reason: 'row 1 of 13 §2.2 names no permission at all');
      expect(recorded, equals(_canonicalPermissions()));
    },
  );

  test('no tools:node="remove" line exists while 13 §2.2 reads UNVERIFIED', () {
    final List<String> unverified = _unverifiedRows().toList();
    // G0 is recorded, so N31-T01 may write the line. The guard stays conditional
    // on purpose: hardened into an absolute ban it would be deleted at N31, and
    // a deleted guard protects nothing.
    if (unverified.isEmpty) {
      return;
    }
    expect(
      File(_manifests.first).existsSync(),
      isTrue,
      reason: 'src/main must exist; an absent manifest is a failure, never a skip',
    );
    for (final String path in _manifests) {
      final File file = File(path);
      // Only src/debug and src/profile may legitimately be absent.
      if (!file.existsSync()) {
        continue;
      }
      final List<String> lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        expect(
          _removalDirective.hasMatch(lines[i]),
          isFalse,
          reason:
              '$path line ${i + 1} removes something at merge time while '
              '13 §2.2 still reads UNVERIFIED for: ${unverified.join(", ")}',
        );
      }
    }
  });
}

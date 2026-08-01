// test/policy/offline_wording_test.dart — decision-record §3.1; 13 §2.1.
//
// Scope: the **authored public copy** this repository holds — `docs/store/` and
// `README.md`. Not the doc set. `grep -rn "never leaves your phone" --include="*.md" .`
// finds the phrase in `CLAUDE.md`, the decision record, ten lines across
// `docs/engineering/`, five skills and three research notes, and **every one of
// them is a document banning it**. A test that cannot tell a prohibition from a
// claim gets one allowlist, then two, then deleted.
//
// This file never claims `lib/` or `assets/`. Those belong to the `copy.*` rules
// of `tool/check_policy.dart` (N03, N06), because 12 §1.4 says an assertion that
// can be made by reading source text belongs in the gate and not here — and two
// scanners over one question means two allowlists.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _decisions = 'docs/research/00-tech-decisions.md';
const String _honesty = 'docs/store/offline-honesty.md';

/// The directories and files that are authored public copy.
const List<String> _publicCopy = <String>['docs/store/', 'README.md'];

/// Phrasings that may never appear in authored public copy, in any casing.
///
/// The list stays a `const` in this one file. N22-T04 adds the backup-checksum
/// wording and N32-T02 adds the listing case, both to **this** file: a list that
/// moves to `test/support/` acquires a second allowlist.
const List<String> _bannedEverywhereInPublicCopy = <String>[
  'your data never leaves your phone',
  'offline-first',
];

/// Banned **unqualified** only. The qualified form — the one that names the
/// export as the backup — is the honest sentence this product needs, so a
/// blanket ban would delete a true statement.
const String _lostPhone = 'a lost phone is lost data';

/// Decision-record §3.1's blockquote, read from the document at run time and
/// never inlined here. A copy in the test drifts from the copy in the document,
/// and the test then defends the wrong sentence.
String _permittedWording() {
  final List<String> lines = _read(_decisions).split('\n');
  final int start = lines.indexWhere((String l) => l.trimRight().startsWith('### 3.1'));
  expect(start, isNot(-1), reason: '$_decisions has no `### 3.1` heading');
  for (int i = start + 1; i < lines.length; i++) {
    if (lines[i].startsWith('### ') || lines[i].startsWith('## ')) {
      break;
    }
    final String line = lines[i].trimRight();
    if (line.startsWith('> "') && line.endsWith('"')) {
      return line.substring(3, line.length - 1);
    }
  }
  fail('$_decisions §3.1 carries no quoted permitted wording');
}

/// Every authored public copy file, as paths.
List<String> _publicCopyFiles() {
  final List<String> out = <String>[];
  for (final String entry in _publicCopy) {
    if (entry.endsWith('/')) {
      final Directory dir = Directory(entry);
      expect(dir.existsSync(), isTrue, reason: '$entry is missing');
      out.addAll(
        dir
            .listSync(recursive: true)
            .whereType<File>()
            .map((File f) => f.path)
            .where((String p) => p.endsWith('.md')),
      );
    } else {
      expect(File(entry).existsSync(), isTrue, reason: '$entry is missing');
      out.add(entry);
    }
  }
  expect(out, isNotEmpty, reason: 'the scan selected no file, so it proves nothing');
  return out;
}

/// The two markers that delimit a prohibition region — text that **names** a
/// banned phrasing rather than claiming it.
const String _prohibitionsOpen =
    '<!-- prohibitions: these name banned phrasings, never claim them -->';
const String _prohibitionsClose = '<!-- end prohibitions -->';

/// [path]'s claims — everything outside the prohibition region, lowercased, with
/// typographic apostrophes folded to straight ones.
///
/// A copywriter has to be able to read the banned phrasings to recognise them,
/// so one explicitly marked region per file is exempt. It is a comment pair and
/// not a code fence because a fence is a formatting choice somebody makes for
/// other reasons, and this exemption must be impossible to acquire by accident.
/// That the region still names every banned phrasing is asserted separately.
String _claims(String path) {
  final StringBuffer out = StringBuffer();
  bool exempt = false;
  int regions = 0;
  for (final String line in _read(path).split('\n')) {
    if (line.trim() == _prohibitionsOpen) {
      expect(exempt, isFalse, reason: '$path: a prohibition region opens inside another');
      exempt = true;
      regions++;
      continue;
    }
    if (line.trim() == _prohibitionsClose) {
      expect(exempt, isTrue, reason: '$path: a prohibition region closes without opening');
      exempt = false;
      continue;
    }
    if (!exempt) {
      out.writeln(line);
    }
  }
  expect(exempt, isFalse, reason: '$path: a prohibition region is never closed');
  expect(regions, lessThanOrEqualTo(1), reason: '$path: one exempt region per file, or none');
  return _fold(out.toString());
}

String _read(String path) {
  final File file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path is missing — an absent file fails, never skips');
  return file.readAsStringSync();
}

String _fold(String text) => text.toLowerCase().replaceAll('’', "'");

void main() {
  test('the only public offline wording in the repository is decision-record §3.1 verbatim, and '
      'the phrase your data never leaves your phone appears nowhere', () {
    final String permitted = _permittedWording();
    expect(
      _read(_honesty),
      contains(permitted),
      reason: 'block 1 of $_honesty is a quotation; a paraphrase is a different claim',
    );

    for (final String path in _publicCopyFiles()) {
      final String prose = _claims(path);
      for (final String phrase in _bannedEverywhereInPublicCopy) {
        expect(prose, isNot(contains(_fold(phrase))), reason: '$path: "$phrase"');
      }
      for (final String line in prose.split('\n')) {
        if (line.contains(_lostPhone)) {
          expect(
            line,
            contains('export'),
            reason:
                '$path: "$_lostPhone" is banned UNQUALIFIED. Name the export as the backup '
                'in the same sentence, or do not write it',
          );
        }
      }
    }

    // The prohibition list itself must survive. Without this, deleting block 3
    // makes the scan above trivially greener and nothing notices.
    final String honesty = _fold(_read(_honesty));
    for (final String phrase in <String>[..._bannedEverywhereInPublicCopy, _lostPhone]) {
      expect(
        honesty,
        contains(_fold(phrase)),
        reason: '$_honesty block 3 no longer names "$phrase" as banned',
      );
    }
  });
}

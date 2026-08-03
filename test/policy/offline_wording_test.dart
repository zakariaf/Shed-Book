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

import 'dart:convert';
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

/// The six words the backup checksum's copy may never use, anywhere near it.
///
/// **FNV-1a IS A CORRUPTION CHECK, NOT A SECURITY FUNCTION.** It detects a
/// truncated download, a half-written file and a bad card. It detects nothing an
/// author intended, and a shepherd who reads *verified* has been told their
/// backup is proof against something it is not proof against at all.
///
/// Added to **this** file rather than to a second one, per the note above: a
/// list that moves to `test/support/` acquires a second allowlist.
const List<String> _bannedNearTheChecksum = <String>[
  'verified',
  'verify',
  'secure',
  'security',
  'authentic',
  'tamper',
];

/// Where that copy lives.
const List<String> _checksumCopy = <String>[
  'lib/data/backup_format.dart',
  'lib/features/export/',
  'lib/features/settings/',
  'lib/l10n/app_en.arb',
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

  test('the words verified and secure appear nowhere near the backup checksum', () {
    // `09 §5.7`'s wording rule, made mechanical. The check is honest about what
    // it does — *this file is complete* — and silent about what it does not do,
    // because there is no phrasing of *secure* that is true of a 64-bit
    // non-cryptographic hash and also useful to a shepherd.
    //
    // Scanned over JOINED string literals and ARB message values, never over the
    // raw file: Dart wraps long strings across adjacent literals, and a naive
    // `contains` misses exactly the sentence you are trying to police
    // (`09 §6.4`). The doc comments in `backup_format.dart` that NAME these
    // words to forbid them are outside the scan for the same reason — they are
    // comments, not copy.
    for (final String path in _checksumCopy) {
      for (final String text in _copyIn(path)) {
        for (final String word in _bannedNearTheChecksum) {
          expect(
            text.toLowerCase(),
            isNot(contains(word)),
            reason: '$path over-claims with "$word" — FNV-1a finds corruption, not tampering',
          );
        }
      }
    }
  });

  test('the checksum copy that does exist says what the check does not do', () {
    // The negative above is only half a rule: a screen that says nothing at all
    // also passes it. `09 §5.7` wants the file to be honest, so the message has
    // to exist and has to be the qualified sentence.
    final String arb = _read('lib/l10n/app_en.arb');
    expect(arb, contains('backupIntegrityLine'));
    expect(arb, contains('backupRefusedIncomplete'));
  });
}

/// Every authored string in one path — Dart string literals joined across
/// adjacent parts, or ARB message values.
///
/// **Comments are excluded.** A file that names a banned word in order to forbid
/// it is doing the opposite of over-claiming, and scanning raw text would make
/// this rule unwritable in the one file that most needs it.
List<String> _copyIn(String path) {
  final List<String> files = path.endsWith('/')
      ? Directory(path)
            .listSync(recursive: true)
            .whereType<File>()
            .map((File f) => f.path)
            .where((String p) => p.endsWith('.dart') && !p.endsWith('.g.dart'))
            .toList()
      : <String>[path];

  final List<String> out = <String>[];
  for (final String file in files) {
    if (!File(file).existsSync()) {
      continue;
    }
    if (file.endsWith('.arb')) {
      final Map<String, Object?> arb =
          jsonDecode(File(file).readAsStringSync()) as Map<String, Object?>;
      for (final MapEntry<String, Object?> e in arb.entries) {
        // MESSAGE VALUES ONLY. An `@key` block is a description written for a
        // developer, and several of them name these words precisely to forbid
        // them.
        if (!e.key.startsWith('@') && e.value is String) {
          out.add(e.value! as String);
        }
      }
      continue;
    }
    final String source = File(file)
        .readAsLinesSync()
        .where((String l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
        .join('\n');
    for (final RegExpMatch m in RegExp("'([^'\\n]*)'").allMatches(source)) {
      out.add(m.group(1)!);
    }
  }
  return out;
}

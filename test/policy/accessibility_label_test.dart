// test/policy/accessibility_label_test.dart
//
// **THE LABEL IS A CLAIM, AND A CLAIM ABOUT ACCESSIBILITY THAT NO TEST HOLDS IS
// THE SAME CLASS OF DEFECT AS A CLAIM ABOUT PRIVACY THAT NO GATE HOLDS.**
//
// `docs/store/accessibility-nutrition-label.md` is the single authored source;
// this file reads it and refuses to let it say more than the suite proves.
//
// **IT ITERATES THE DECLARATION, NEVER THE TESTS, AND THAT IS THE ONE
// STRUCTURAL DECISION IN THE FILE.** A loop over the test files checking each
// has a claim passes vacuously the moment a claim is *added* — which is the
// exact moment this file exists to fail. Every other direction produces a test
// that is green when the label is a lie.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String kLabelFile = 'docs/store/accessibility-nutrition-label.md';

/// One row of the declaration table.
typedef Claim = ({String feature, String declare, String evidence});

/// The rows of §2's table, parsed from the document a human reads.
///
/// **The table IS the machine-readable form.** A second JSON copy beside it
/// would be one more thing to keep in step, and the failure mode of a drifting
/// copy is a green test over a stale claim.
List<Claim> _claims() {
  final List<String> lines = File(kLabelFile).readAsLinesSync();
  final List<Claim> out = <Claim>[];

  for (final String line in lines) {
    if (!line.startsWith('| ') || line.startsWith('| Feature') || line.startsWith('|---')) {
      continue;
    }
    final List<String> cells = line.split('|').map((String c) => c.trim()).toList();
    // '', feature, declare, evidence, ''
    if (cells.length != 5) {
      continue;
    }
    if (!<String>['yes', 'no', 'pending'].contains(cells[2])) {
      continue;
    }
    out.add((feature: cells[1], declare: cells[2], evidence: cells[3]));
  }
  return out;
}

/// `` `path` · `'test name'` `` pairs inside one evidence cell.
Iterable<({String path, String name})> _automated(String evidence) sync* {
  final RegExp pair = RegExp(
    r'`([^`]+\.(?:dart))`\s*·\s*`'
    r"'([^']*)'"
    r'`',
  );
  for (final RegExpMatch m in pair.allMatches(evidence)) {
    yield (path: m.group(1)!, name: m.group(2)!);
  }
}

void main() {
  test(
    'every claim in the Accessibility Nutrition Label is held by an assertion in this suite',
    () {
      final List<Claim> claims = _claims();
      expect(claims, hasLength(9), reason: 'nine features — the table lost a row or grew one');

      for (final Claim claim in claims) {
        if (claim.declare == 'no') {
          // An undeclared feature needs a REASON in the file and no evidence.
          expect(
            claim.evidence.toLowerCase(),
            contains('undeclared'),
            reason: '"${claim.feature}" is not declared and does not say why',
          );
          continue;
        }

        expect(
          claim.evidence,
          isNotEmpty,
          reason: '"${claim.feature}" is declared with no evidence',
        );

        final List<({String name, String path})> cited = _automated(claim.evidence).toList();
        expect(cited, isNotEmpty, reason: '"${claim.feature}" cites no automated evidence at all');

        for (final ({String name, String path}) e in cited) {
          expect(
            File(e.path).existsSync(),
            isTrue,
            reason: '${e.path} does not exist — "${claim.feature}" cites a file that is gone',
          );
          // **A RENAMED TEST SILENTLY UNHOLDS A CLAIM, AND ONLY A VERBATIM NAME
          // CATCH FINDS IT.** Asserting the file exists is not enough:
          // `semantics_gate_test.dart` will exist for the life of the project.
          expect(
            File(e.path).readAsStringSync(),
            contains(e.name),
            reason:
                '"${e.name}" is not in ${e.path} — it was renamed and '
                '"${claim.feature}" is now unheld',
          );
        }
      }
    },
  );

  test('a manual evidence row carries a device and a date, or the feature is pending', () {
    // **A MANUAL CLAIM WITH NO DATE IS EXACTLY AS BROKEN AS AN AUTOMATED CLAIM
    // WITH NO TEST.** `10 §7.1`: *re-evaluate every release; put it in the
    // release checklist, not in someone's memory.*
    //
    // Three features are held partly by a hand pass that has not been run —
    // VoiceOver, Voice Control and Differentiate Without Color Alone. They are
    // `pending`, which is the honest state and not a soft `yes`: the pass is an
    // evening on two physical phones in a dark room, and writing `yes` now
    // would be the defect this whole folder exists to prevent.
    for (final Claim claim in _claims()) {
      if (!claim.evidence.contains('manual')) {
        continue;
      }
      if (claim.evidence.contains('PENDING')) {
        expect(
          claim.declare,
          'pending',
          reason: '"${claim.feature}" cites a hand pass that has not happened and still says yes',
        );
        continue;
      }
      // Once run, the row carries a device and an ISO date.
      expect(
        RegExp(r'manual\s*·\s*[^·]+·\s*\d{4}-\d{2}-\d{2}').hasMatch(claim.evidence),
        isTrue,
        reason: '"${claim.feature}" has a manual row with no device or no date',
      );
    }
  });

  test('nothing pending has been entered as declared, and the file says which', () {
    final List<Claim> pending = _claims().where((Claim c) => c.declare == 'pending').toList();
    expect(
      pending.map((Claim c) => c.feature).toList(),
      <String>['VoiceOver / TalkBack', 'Differentiate Without Color Alone', 'Voice Control'],
      reason: 'the pending set changed — the device pass either ran or regressed',
    );

    final String body = File(kLabelFile).readAsStringSync();
    expect(body, contains('NOT YET RUN'), reason: 'the sweep record must state its own status');
    expect(
      body,
      contains('`pending` is not a soft yes'),
      reason: 'a reader must not be able to mistake pending for a declaration',
    );
  });

  test('Captions stays undeclared, and the rule that replaces it is in the file', () {
    // Not an oversight and not a gap to be closed later: on-device speech
    // recognition was cut because the recognizer runs in another process whose
    // network access the manifest cannot constrain (owner ruling §7.0 #6).
    final String body = File(kLabelFile).readAsStringSync();

    expect(
      body,
      contains('**A voice note never carries a fact that exists nowhere else.**'),
      reason: 'the constraint that replaces captions is the thing that makes the gap honest',
    );
  });

  test('the seven common tasks are seven, and unlock is one of them', () {
    // **THE TASKS AND THE VARIANTS ARE DIFFERENT LISTS AND BOTH ARE NEEDED.**
    // Apple's bar is per task; the sweep's subjects are per variant. Unlock is a
    // common task and not a variant; note search is a variant and not a common
    // task. A file that conflates them under-tests the purchase flow — the one
    // task nobody thinks of as accessibility work.
    final List<String> tasks = File(
      kLabelFile,
    ).readAsLinesSync().where((String l) => RegExp(r'^\d\. ').hasMatch(l)).toList();

    expect(tasks, hasLength(7));
    expect(
      tasks.any((String t) => t.toLowerCase().contains('unlock')),
      isTrue,
      reason: 'the purchase flow is a common task and Apple counts it',
    );
  });

  test('no VPAT and no EN 301 549 claim', () {
    // `10 §1.3`. A conformance claim nobody asked for is a claim somebody has to
    // defend, and the EAA covers a closed list this product is not on.
    final String body = File(kLabelFile).readAsStringSync();
    expect(body, contains('No VPAT'));

    for (final FileSystemEntity f in Directory('docs/store').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.md')) {
        continue;
      }
      final String text = f.readAsStringSync();
      // The label file names the two in order to refuse them; every other store
      // document must not name them at all.
      if (f.path.endsWith('accessibility-nutrition-label.md')) {
        continue;
      }
      expect(text, isNot(contains('VPAT')), reason: f.path);
      expect(text, isNot(contains('EN 301 549')), reason: f.path);
    }
  });
}

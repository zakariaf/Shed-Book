// test/policy/reachability_test.dart
//
// **THE DOMINANT DEFECT IN THIS REPOSITORY WAS NEVER A MISSING FUNCTION. IT WAS
// A FUNCTION WITH NO CALLER.**
//
// Every piece had its own green test and nothing asserted the flow existed. A
// sweep on 2026-08-05 for public `lib/data/` verbs referenced nowhere else
// returned **thirty-seven**, and behind them were: restore unreachable, no way
// to make a backup, no way to record a treatment, no way to start a season, a
// pen board that could only add a pen, and no free-text input anywhere in the
// app.
//
// This file is that sweep, kept. It is the gate the project did not have — and
// the reason it did not have one is that every other gate here scans for
// something *present* and forbidden, while this one scans for something
// *absent* and required.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verbs with no caller, each with the reason it has none.
///
/// **A CLOSED LIST, AND IT ONLY SHRINKS.** The test fails in both directions: a
/// new unreachable verb fails because it is not here, and a verb that gains a
/// caller fails because it still is. A list that could quietly grow is a list
/// that would have contained all thirty-seven and told nobody.
/// **EMPTY, AND THAT IS THE POINT.**
///
/// The sweep found **thirty-seven**. Thirty-five gained a caller a shepherd can
/// reach; two were deleted as second writers for columns another class owns
/// (`setCurrentSeason`, `markMediaMissing`), their properties moving to the
/// mechanisms that hold them; and the last, `recordReconcileScheduled`, was
/// deleted because its caller genuinely could not exist — nothing in `v1.0.0`
/// reconciles, and the column's own doc says *never reconciled* is a real
/// state.
///
/// **THIS MAP IS KEPT EMPTY RATHER THAN DELETED.** The next verb with no caller
/// has to be a decision somebody writes down, in a line naming what is in the
/// way — because silence is how thirty-seven of them accumulated, each behind
/// its own green test, hiding restore, the backup, the treatment entry, the pen
/// board's every verb and the whole media chain.
const Map<String, String> kNoCallerYet = <String, String>{};

/// Public methods on `lib/data/` classes, and how many times each is named
/// anywhere else under `lib/`.
///
/// **`lib/` ONLY, AND WIDENING IT TO `test/` WAS TRIED AND REVERTED.** Every one
/// of the thirty-seven this sweep found had its own green test — that is the
/// whole shape of the defect — so a test-inclusive scan finds nothing and the
/// gate becomes decorative. What is being asked is *can a shepherd reach this*,
/// and a test is not a shepherd.
Map<String, int> _callsPerVerb() {
  final Map<String, String> sources = <String, String>{};
  for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) {
      continue;
    }
    if (f.path.endsWith('.g.dart') || f.path.contains('/l10n/')) {
      continue;
    }
    // Comments stripped: this file's own prose names several of these verbs,
    // and so do the doc comments on the verbs themselves.
    sources[f.path] = f
        .readAsLinesSync()
        .where((String l) => !l.trimLeft().startsWith('//'))
        .join('\n');
  }

  final RegExp declaration = RegExp(
    r'^  (?:Future<[^>]*>|Stream<[^>]*>|[A-Z]\w*|void)\s+(\w+)\(',
    multiLine: true,
  );

  final Map<String, int> calls = <String, int>{};
  for (final MapEntry<String, String> file in sources.entries) {
    if (!file.key.startsWith('lib/data/')) {
      continue;
    }
    for (final RegExpMatch m in declaration.allMatches(file.value)) {
      final String verb = m.group(1)!;
      if (verb.startsWith('_')) {
        continue;
      }
      calls[verb] = 0;
      for (final MapEntry<String, String> other in sources.entries) {
        calls[verb] = calls[verb]! + RegExp('\\.$verb\\b').allMatches(other.value).length;
        if (other.key == file.key) {
          // An internal call — `repeatTreatment` calling `recordTreatment` — is
          // still not a caller from the product's point of view unless the
          // outer one is reachable. Counted, because the outer one is checked
          // on its own line.
          calls[verb] =
              calls[verb]! +
              RegExp('(?<![\\w.])$verb\\(').allMatches(other.value).length -
              RegExp(
                '^  (?:Future<[^>]*>|Stream<[^>]*>|[A-Z]\\w*|void)\\s+$verb\\(',
                multiLine: true,
              ).allMatches(other.value).length;
        }
      }
    }
  }
  return calls;
}

void main() {
  test('every lib/data/ verb has a caller, or is on the list with its reason', () {
    final Map<String, int> calls = _callsPerVerb();
    expect(calls, isNotEmpty, reason: 'the sweep found no verbs at all — the regex broke');

    final Set<String> unreachable = <String>{
      for (final MapEntry<String, int> e in calls.entries)
        if (e.value <= 0) e.key,
    };

    expect(
      unreachable.difference(kNoCallerYet.keys.toSet()),
      isEmpty,
      reason:
          'a repository verb nothing calls. Either wire it or add it to kNoCallerYet '
          'with the reason — silence is how thirty-seven of them accumulated',
    );

    // **AND THE LIST ONLY SHRINKS.** A verb that gains a caller must leave it,
    // or the list stops describing anything.
    expect(
      kNoCallerYet.keys.toSet().difference(unreachable),
      isEmpty,
      reason: 'these are called now — delete them from kNoCallerYet',
    );
  });

  test('every reason names a task, a release or a mechanism', () {
    // A reason of *not yet* is not a reason. Each line says which screen, which
    // epic or which ruling is between the verb and its caller.
    for (final MapEntry<String, String> e in kNoCallerYet.entries) {
      expect(
        RegExp(r'N\d\d|v1\.1\.0|§|Provider|Repository').hasMatch(e.value),
        isTrue,
        reason: '${e.key}: "${e.value}" does not name what is in the way',
      );
    }
  });
}

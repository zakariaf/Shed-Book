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
const Map<String, String> kNoCallerYet = <String, String>{
  // ── FIVE ENTRIES, AND EVERY ONE NAMES A RULE ITS CALLERS ASSERT ───────────
  //
  // **THIRTY-TWO OF THE THIRTY-SEVEN GAINED A CALLER. TWO WERE DELETED. THESE
  // FIVE STAY, AND THE REASON IS THE SAME FOR ALL OF THEM.**
  //
  // Each was deleted in the course of this sweep, and each deletion broke a test
  // that was asserting something real — so each was restored. That is the line
  // this gate draws: a verb whose only caller is the test that states a rule is
  // **not dead code**, it is the rule written where a reader can see it. What
  // the gate is for is a verb *nothing at all* reaches, which is the shape that
  // hid restore, the backup, the treatment entry and the whole media chain.
  //
  // The two that WERE deleted are the ones that failed that test:
  // `setCurrentSeason` and `markMediaMissing` were second writers for columns
  // another class owns, their properties moved to the mechanisms that hold
  // them, and no assertion was lost.
  //
  // These three round-trip a column that ships in the backup — which is exactly
  // what has to hold for a `v1.0.0` backup to restore into `v1.1.0` unchanged
  // (P15, all 21 tables whole). Their screens are N28's and N24's.
  'setCycleDays': 'its caller asserts cycle_days round-trips — P15, and N28 reads it',
  'setPercentageDefinition': 'its caller asserts percentage_definition round-trips — P15, N28',
  'recordReconcileScheduled': 'its caller asserts last_reconcile_scheduled round-trips — P15, N24',

  // ── N15, MEDIA AND NOTES — THE ONE REMAINING FEATURE ──────────────────────
  // **N15 IS WIRED.** Both chains are joined up — `photo_controller.dart` and
  // `voice_controller.dart` — and reached from Lambing Entry. What is left of
  // the media verbs is the two below, and neither is a gap.
  //
  // **`addNote` LEFT THIS LIST**, and the decision it was waiting on is
  // recorded on `editNoteBody`: a note is a ROW, so per-keystroke commits need
  // an update-by-id — and that verb does NOT touch the provenance quad, because
  // the quad is about when the note happened and typing more of it does not
  // change that. Marking every keystroke as an edit would make `EDITED` mean
  // nothing on the one stamp §12.5 rests on.

  // ── BOTH CORRECTION VERBS ARE WIRED ───────────────────────────────────────
  // `correctEnteredAt` needed a time editor the pen board could not legally
  // import — it lived under `lib/features/lambing/` and `layer.sibling` forbids
  // one feature reaching into another. It moved to `lib/core/ui/components/`
  // unchanged. `correctFoster` turned out not to need one at all: it writes a
  // compensating event, and its affordance is *"Correct this"* on the foster's
  // own timeline row, which is where `indelible-marks-and-strikes` §9 puts it.

  // **TWO WERE DELETED RATHER THAN LISTED** on 2026-08-05, which is the
  // stronger fix: `setCurrentSeason` was a second writer for a column `03
  // §5.14` gives to `SeasonRepository`, and `markMediaMissing` a second writer
  // for one only `MediaSweeper` knows how to un-write. A dead verb kept with a
  // reason is still dead code. Their properties moved to the mechanisms that
  // hold them; neither assertion was lost.
  //
  // **TWO GAINED CALLERS**: `recordExportPrompted` is stamped by the banner —
  // the once-a-day rule read the column and NOTHING WROTE IT, so a shepherd who
  // ignored the prompt got it again on every cold launch — and `levelDbfs`
  // prints a word while recording, because §6 has six marks and none is a
  // meter.
  // **TWO KEPT, AND DELETING EITHER WOULD HAVE DELETED A RULE'S CLEAREST
  // STATEMENT.**
  //
  // Following the sweep to the end pointed at both, because the screen reads
  // the same two facts reactively — the book stream's first non-voided row, and
  // `watchWithdrawals`. Both deletions were made, both broke a test that was
  // asserting something real, and both were reverted.
  //
  // `lastTreatment`'s callers assert that **repeat last skips a voided
  // treatment** — the thing a shepherd would otherwise repeat by accident.
  // `withdrawalFor`'s assert that **zero days is a recorded period and not the
  // same as none**, the case a nullable int cannot pass and the reason the
  // child table exists at all (§12.1, `05 §3.1`).
  //
  // A verb whose only caller is the test that states a rule is not dead code.
  // It is the rule, written where a reader can see it, and this gate exists to
  // find verbs **nothing at all** reaches — not to make these two disappear.
  'lastTreatment': 'its callers assert repeat-last skips a voided treatment — 07 §10.4',
  // **KEPT FOR THE SAME REASON.** Following the sweep to the end pointed here, because the screen
  // reads the withdrawals off `watchWithdrawals`. But `withdrawalFor`'s callers
  // are the §12.1 cases that assert *zero days is a recorded period and not the
  // same as none* — the case a nullable int cannot pass, and the reason the
  // child table exists at all.
  //
  // A verb whose only caller is a safety test is not dead code. It is the
  // shape of the rule, written where a reader can see it, and the gate exists
  // to find verbs **nothing at all** reaches — not to make this one disappear.
  'withdrawalFor': 'the §12.1 zero-days cases are its callers — 05 §3.1, and it stays',
};

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

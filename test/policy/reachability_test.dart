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
  // ── `v1.1.0`, AND THE SCREEN IS THE REASON ────────────────────────────────
  // `docs/RELEASE-SCOPE.md`, ruling P15. A verb whose only reader is a screen
  // that ships in June is not a gap; wiring it now would mean building the
  // screen now.
  'setCycleDays': 'Season Summary (N28) — the only reader of cycle_days',
  'setPercentageDefinition': 'Season Summary (N28) — the lambing-percentage definition',
  'recordReconcileScheduled': 'reminders (N24) — nothing schedules yet',

  // ── N15, MEDIA AND NOTES — THE ONE REMAINING FEATURE ──────────────────────
  // The camera, the recorder and the photo store are a chain, and `addNote`
  // needs a decision this sweep should not make at speed: a note is a ROW, not
  // a column, so per-keystroke commits need an update-by-id that does not
  // exist — and `notes` carries the provenance quad, so an edited note owes an
  // `EDITED` stamp. `setNote` on the lambing screen is a column and is wired.
  'addNote': 'N15 — needs an edit-by-id verb and its §12.5 provenance ruling',
  'attachPhoto': 'N15 — the photo chain',
  'beginVoiceNote': 'N15 — the voice chain',
  'completeVoiceNote': 'N15 — the voice chain',
  'markMediaMissing': 'N15 — called by the sweep only when a photo exists to lose',
  'writePhoto': 'N15 — the photo chain',
  'newRelativePath': 'N15 — the photo chain',
  'pick': 'N15 — CameraService, and a native surface integration_test cannot drive',
  'levelDbfs': 'N15 — the recorder level meter',

  // ── BOTH CORRECTION VERBS ARE WIRED ───────────────────────────────────────
  // `correctEnteredAt` needed a time editor the pen board could not legally
  // import — it lived under `lib/features/lambing/` and `layer.sibling` forbids
  // one feature reaching into another. It moved to `lib/core/ui/components/`
  // unchanged. `correctFoster` turned out not to need one at all: it writes a
  // compensating event, and its affordance is *"Correct this"* on the foster's
  // own timeline row, which is where `indelible-marks-and-strikes` §9 puts it.

  // ── READ HELPERS THE SCREEN GETS ANOTHER WAY ──────────────────────────────
  // Not gaps: the data reaches the screen through a stream that already carries
  // it, and a second path would be a second answer.
  'lastTreatment':
      'treatmentsProvider(TreatmentMode.book) carries it — the screen takes its first row',
  'withdrawalFor': 'storedWithdrawalsProvider carries them',
  'setCurrentSeason': 'SeasonRepository.switchSeason owns app_settings.current_season (03 §5.14)',
  'recordExportPrompted': 'SettingsRepository.recordExported is the one the prompt writes through',
};

/// Public methods on `lib/data/` classes, and how many times each is named
/// anywhere else under `lib/`.
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

// test/design/haptics_test.dart — the haptic vocabulary and the four motion
// tokens.
//
// Nothing here is time-shaped: a Duration is a span, not a clock reading.
// T06's formatters_dst_test.dart has the epic's only uk-zone group.
//
// No sweep. This file tests a vocabulary, not fourteen screens — the sweeps are
// N33-T02 and N33-T03.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/ui/motion.dart';

const String _motionFile = 'lib/core/ui/motion.dart';

List<String> _authoredDart(String root) => Directory(root)
    .listSync(recursive: true)
    .whereType<File>()
    .map((File f) => f.path.replaceAll(r'\', '/'))
    .where(
      (String p) => p.endsWith('.dart') && !p.endsWith('.g.dart') && !p.endsWith('.drift.dart'),
    )
    .toList();

String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

void main() {
  test('the haptic vocabulary has exactly the ruled number of entries and names no '
      'unverified platform call', () {
    // THE ANCHOR. Four entries: three write outcomes plus the selection tick.
    //
    // "Names no unverified platform call" is satisfiable precisely because every
    // member is referenced AS A SYMBOL. A symbol is a compile-time existence
    // proof; 'successNotification' in a map key is a runtime hope, and it would
    // fail on a phone rather than here.
    expect(ShedWriteSignal.values, hasLength(3));

    final String source = _declarations(_motionFile);
    for (final String member in <String>[
      'HapticFeedback.successNotification()',
      'HapticFeedback.warningNotification()',
      'HapticFeedback.errorNotification()',
      'HapticFeedback.selectionClick()',
    ]) {
      expect(source, contains(member), reason: member);
    }

    // Four members, and no fifth.
    expect('HapticFeedback.'.allMatches(source).length, 4);
  });

  test('every member the vocabulary names resolves on HapticFeedback at 3.44.8', () {
    // Compilation is the proof; this case exists so the proof has a NAME in the
    // report. REFERENCES §22 E1 was run against the installed SDK on 2026-08-01
    // and all three notification members exist, so the documented heavyImpact()
    // fallback is not needed.
    //
    // Referencing them as tear-offs rather than calling them: a call would go to
    // the platform channel and this is not a widget test.
    expect(HapticFeedback.successNotification, isA<Function>());
    expect(HapticFeedback.warningNotification, isA<Function>());
    expect(HapticFeedback.errorNotification, isA<Function>());
    expect(HapticFeedback.selectionClick, isA<Function>());
  });

  test('HapticFeedback.vibrate appears nowhere under lib/', () {
    // On Android it is a long buzz, not a tick.
    for (final String path in _authoredDart('lib')) {
      expect(_declarations(path), isNot(contains('vibrate')), reason: path);
    }
  });

  test('the vocabulary is keyed on a write outcome, not on a tap', () {
    // hapticForWrite CANNOT BE CALLED WITHOUT STATING AN OUTCOME, which is what
    // makes 06 §10.1's "fires when the transaction returned" structural rather
    // than a comment. There is no argument-free success helper a gesture
    // callback could reach for — "a false receipt is worse than no receipt".
    final String source = _declarations(_motionFile);

    expect(source, contains('Future<void> hapticForWrite(ShedWriteSignal signal)'));
    expect(source, isNot(contains('hapticSuccess(')));
    expect(source, isNot(contains('hapticCommitted(')));

    // And the selection tick is the OPPOSITE timing — pointer down, before the
    // state change — so it is a separate entry point rather than another arm of
    // the same switch. Swapping the two is the mistake.
    expect(source, contains('Future<void> hapticSelection()'));
  });

  test('the free-tier cap has no vocabulary entry', () {
    // Decision #90 and 06 §10.1's first deliberate omission. Both gated actions
    // are calm-UI, and "a buzz would turn a calm gate into a rebuke".
    final String source = _declarations(_motionFile);
    for (final String word in <String>['cap', 'freeTier', 'entitlement', 'unlock']) {
      expect(source, isNot(contains(word)), reason: word);
    }
  });

  test('a warning and a refusal are different entries', () {
    // A committed-with-warnings write is NOT a failure. Conflating them would
    // tell a shepherd to try again after a record that already exists.
    expect(ShedWriteSignal.committedWithWarnings, isNot(ShedWriteSignal.refused));
    final String source = _declarations(_motionFile);
    expect(source, contains('ShedWriteSignal.committedWithWarnings => HapticFeedback.warning'));
    expect(source, contains('ShedWriteSignal.refused => HapticFeedback.error'));
  });

  test('no audio API is referenced under lib/', () {
    // Haptics are one of three redundant channels; sound is not one of them. An
    // app cannot detect that haptics are switched off system-wide, which is why
    // colour + shape + text carry the meaning and the tick only confirms it.
    for (final String path in _authoredDart('lib')) {
      expect(_declarations(path), isNot(contains('SystemSound')), reason: path);
    }
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    for (final String pkg in <String>['audioplayers', 'just_audio', 'soundpool']) {
      expect(pubspec, isNot(contains(pkg)), reason: pkg);
    }
  });

  test('the four durations are 40, 120, 160 and 180 milliseconds and there is no fifth', () {
    // indelible.md §5.1's budget, asserted as an exact set so a fifth cannot
    // appear without deleting one.
    expect(kPressFlash, const Duration(milliseconds: 40));
    expect(kMotionInk, const Duration(milliseconds: 120));
    expect(kMotionSheet, const Duration(milliseconds: 160));
    expect(kMotionStrike, const Duration(milliseconds: 180));

    final String source = _declarations(_motionFile);
    expect(
      'const Duration k'.allMatches(source).length,
      4,
      reason: 'a fifth motion token appeared without one being removed',
    );
  });

  test('the strike is the only linear curve', () {
    // Every other token uses the shared ease-out. The strike is linear because a
    // pen crosses a page at constant speed — it is the only animation in the app
    // with a direction, and the one place the animation IS the meaning.
    expect(kEaseStrike, Curves.linear);
    expect(kEaseOut, const Cubic(0.2, 0, 0, 1));
    expect(kEaseOut, isNot(Curves.linear));

    final String source = _declarations(_motionFile);
    expect(
      'Curves.linear'.allMatches(source).length,
      1,
      reason: 'a second linear curve makes the strike stop meaning anything',
    );
  });

  test('under reduce-motion, ink, sheet and strike are zero and press is 40 ms', () {
    // The per-token table from indelible.md §5.3, now that the constants exist.
    // Extends what T08's file could only assert over local literals.
    for (final Duration animated in <Duration>[kMotionInk, kMotionSheet, kMotionStrike]) {
      expect(resolveMotion(animated, reduced: true), Duration.zero);
    }
    expect(
      kPressFlash,
      const Duration(milliseconds: 40),
      reason: 'the press flash is not resolved — call sites use the constant directly',
    );
  });

  test('haptics are not gated on reduce-motion', () {
    // They are not motion (indelible.md §5.4). The resolver and the vocabulary
    // are independent, and this asserts the file never joins them.
    final String source = _declarations(_motionFile);
    expect(source, isNot(matches(RegExp(r'prefersReducedMotion[^\n]*Haptic'))));
    expect(source, isNot(matches(RegExp(r'Haptic[^\n]*prefersReducedMotion'))));
  });

  test('the P10 ruling is recorded and the amended document agrees with the vocabulary', () {
    // If the ruling had been deferred, this case names it as deferred rather
    // than passing quietly.
    final String source = File(_motionFile).readAsStringSync();
    expect(source, contains('P10'));
    expect(source, contains('RULED'));
    expect(
      source,
      contains('four API members'),
      reason: 'the ruling must say WHICH list won — "four or five" of what settles nothing',
    );
  });

  test('no stale unverified flag for successNotification remains in 07, 10 or 12', () {
    // E1's other half: the check closes FOUR documents, not one. A verified fact
    // with three documents still calling it unverified is worse than an
    // unverified one, because the next reader trusts whichever they open first.
    for (final String doc in <String>[
      'docs/engineering/07-screens.md',
      'docs/engineering/10-accessibility-and-i18n.md',
      'docs/engineering/12-testing.md',
      'docs/engineering/CONVENTIONS.md',
    ]) {
      final String text = File(doc).readAsStringSync();
      if (!text.contains('successNotification')) {
        continue;
      }
      expect(
        text,
        contains('N09-T09'),
        reason: '$doc still discusses successNotification without the 2026-08-01 verification',
      );
    }
  });
}

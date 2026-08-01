// test/domain/time/recorded_time_test.dart — mirrors
// lib/domain/time/recorded_time.dart.
//
// Zone-agnostic: every Instant here is built from a DateTime.utc or from an
// integer, so the file passes identically under TZ=Pacific/Chatham. The
// wall-clock form of the repeated hour is DST-2, in test/domain/uk_zone/.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/recorded_time.dart';

/// The file's declarations, comments dropped — the doc comments name every
/// anti-pattern the source scans look for, which is prose about a prohibition
/// and not the thing itself.
String _declarations() => File(
  'lib/domain/time/recorded_time.dart',
).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

void main() {
  final Instant t0315 = Instant.fromDateTime(DateTime.utc(2026, 3, 4, 3, 15));
  final Instant t0320 = Instant.fromDateTime(DateTime.utc(2026, 3, 4, 3, 20));
  final Instant t0330 = Instant.fromDateTime(DateTime.utc(2026, 3, 4, 3, 30));
  final Instant t0700 = Instant.fromDateTime(DateTime.utc(2026, 3, 4, 7));

  test('provenanceLabel is exhaustive and never returns an empty string', () {
    for (final TimeSource s in TimeSource.values) {
      final RecordedTime r = switch (s) {
        TimeSource.autoCaptured => RecordedTime.capture(t0320),
        TimeSource.userEntered => RecordedTime.entered(effective: t0320, now: t0700),
        TimeSource.userEdited => RecordedTime.capture(t0320).editedTo(t0330),
      };
      expect(r.source, s);
      expect(r.provenanceLabel, isNotEmpty, reason: s.key);
    }
  });

  test('capture sets effective == capturedAt and no original', () {
    final RecordedTime r = RecordedTime.capture(t0320);
    expect(r.effective, t0320);
    expect(r.capturedAt, t0320);
    expect(r.originalEffective, isNull);
    expect(r.source, TimeSource.autoCaptured);
    expect(r.isEdited, isFalse);
  });

  test('entered keeps the typed time and stamps the write separately', () {
    // A deferred entry typed at 07:00 for an 03:20 lambing was never wrong.
    final RecordedTime r = RecordedTime.entered(effective: t0320, now: t0700);
    expect(r.effective, t0320);
    expect(r.capturedAt, t0700);
    expect(r.originalEffective, isNull);
    expect(r.isEdited, isFalse);
    expect(r.source, TimeSource.userEntered);
  });

  test('editing preserves the ORIGINAL across many edits', () {
    final RecordedTime r = RecordedTime.entered(
      effective: t0700,
      now: t0700,
    ).editedTo(t0330).editedTo(t0320).editedTo(t0315);
    expect(r.effective, t0315);
    // The FIRST value, not the previous one. `originalEffective = effective`
    // instead of `originalEffective ?? effective` would give t0320 here, and
    // the type would record that a time was edited while losing what it was
    // edited from.
    expect(r.originalEffective, t0700);
    expect(r.capturedAt, t0700);
    expect(r.source, TimeSource.userEdited);
  });

  test('editing an auto-captured time keeps the captured instant', () {
    final RecordedTime r = RecordedTime.capture(t0320).editedTo(t0330);
    expect(r.capturedAt, t0320);
    expect(r.originalEffective, t0320);
    expect(r.effective, t0330);
  });

  test('editing back to the original value still reads as edited', () {
    // Undoing an edit is not the same as never having edited.
    final RecordedTime r = RecordedTime.capture(t0320).editedTo(t0330).editedTo(t0320);
    expect(r.isEdited, isTrue);
    expect(r.originalEffective, t0320);
    expect(r.effective, t0320);
  });

  test('time_source keys are FROZEN', () {
    expect(
      TimeSource.values.map((TimeSource s) => s.key).toList(),
      <String>['auto', 'entered', 'edited'],
      reason:
          'these go into SQLite, every CSV time_source column and every JSON backup, '
          'and a v1.0 backup is restored by v1.9',
    );
  });

  test('fromKey round-trips every member and throws on anything else', () {
    for (final TimeSource s in TimeSource.values) {
      expect(TimeSource.fromKey(s.key), s);
    }
    // The three most likely wrong spellings.
    for (final String bad in <String>['captured', 'corrected', '']) {
      expect(() => TimeSource.fromKey(bad), throwsFormatException, reason: bad);
    }
  });

  test('entryLag is capturedAt minus effective', () {
    expect(
      RecordedTime.entered(effective: t0320, now: t0700).entryLag,
      const Duration(hours: 3, minutes: 40),
    );
    expect(RecordedTime.capture(t0320).entryLag, Duration.zero);
  });

  test('there is no way to clear originalEffective', () {
    final String source = _declarations();
    expect(source, isNot(contains('copyWith')));
    expect(RegExp(r'\bset\s+\w').hasMatch(source), isFalse, reason: 'no setter');
    // One private generative constructor, and exactly three call sites: the two
    // factories and editedTo.
    expect(RegExp('RecordedTime._').allMatches(source).length, 4);
  });

  test('provenanceLabel has no default arm', () {
    final String source = _declarations();
    expect(source, isNot(contains('default:')));
    expect(source, isNot(contains('_ =>')));
  });

  test("the labels are 07-screens.md's, verbatim", () {
    expect(RecordedTime.capture(t0320).provenanceLabel, 'recorded automatically');
    expect(
      RecordedTime.entered(effective: t0320, now: t0700).provenanceLabel,
      'time entered by you',
    );
    expect(RecordedTime.capture(t0320).editedTo(t0330).provenanceLabel, 'time edited by you');
  });

  test('a time recorded in the ambiguous hour carries its provenance unchanged', () {
    // The two candidate instants of the repeated 01:00–01:59 hour. Provenance is
    // orthogonal to the ambiguity.
    final RecordedTime first = RecordedTime.capture(
      Instant.fromDateTime(DateTime.utc(2026, 10, 25, 0, 30)),
    );
    final RecordedTime second = RecordedTime.capture(
      Instant.fromDateTime(DateTime.utc(2026, 10, 25, 1, 30)),
    );
    expect(first.source, TimeSource.autoCaptured);
    expect(second.source, TimeSource.autoCaptured);
    expect(first.entryLag, Duration.zero);
    expect(second.entryLag, Duration.zero);
    expect(first.effective == second.effective, isFalse);
  });
}

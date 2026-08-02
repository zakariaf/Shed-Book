// test/data/recorded_time_columns_test.dart
//
// The read path's half of §12.5. Every write path could produce a RecordedTime;
// until this reconstruction existed, no read path could — so a screen showing a
// stored time had no way to say where it came from.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/data/recorded_time_columns.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/recorded_time.dart';

final Instant _happened = Instant.fromDateTime(DateTime.utc(2026, 3, 14, 3, 20));
final Instant _wroteItDown = Instant.fromDateTime(DateTime.utc(2026, 3, 14, 7));
final Instant _correctedTo = Instant.fromDateTime(DateTime.utc(2026, 3, 14, 3, 5));

void main() {
  test('a round trip through the columns preserves every field, on all three arms', () {
    // THE ANCHOR. Each arm is built by the WRITE path's own factory, flattened
    // to columns the way a repository writes them, and rebuilt — and every
    // field has to survive, not just the label.
    final List<RecordedTime> written = <RecordedTime>[
      RecordedTime.capture(_happened),
      RecordedTime.entered(effective: _happened, now: _wroteItDown),
      RecordedTime.entered(effective: _happened, now: _wroteItDown).editedTo(_correctedTo),
    ];

    for (final RecordedTime original in written) {
      final RecordedTime rebuilt = recordedTimeFromColumns(
        effective: original.effective,
        capturedAt: original.capturedAt,
        originalEffective: original.originalEffective,
        sourceKey: original.source.key,
      );

      expect(rebuilt.effective, original.effective, reason: original.source.key);
      expect(rebuilt.capturedAt, original.capturedAt, reason: original.source.key);
      expect(rebuilt.originalEffective, original.originalEffective, reason: original.source.key);
      expect(rebuilt.source, original.source, reason: original.source.key);
      expect(rebuilt.provenanceLabel, original.provenanceLabel, reason: original.source.key);
    }
  });

  test('an edited time still says what it was edited FROM', () {
    // The `??` in editedTo is the whole feature, and a reconstruction that
    // assigned originalEffective directly would keep only the PREVIOUS value —
    // recording THAT a time was edited and losing WHAT IT WAS EDITED FROM, which
    // makes the §12.5 label true and uninformative.
    final RecordedTime rebuilt = recordedTimeFromColumns(
      effective: _correctedTo,
      capturedAt: _wroteItDown,
      originalEffective: _happened,
      sourceKey: 'edited',
    );

    expect(rebuilt.isEdited, isTrue);
    expect(rebuilt.effective, _correctedTo);
    expect(rebuilt.originalEffective, _happened);
  });

  test('a chain of edits keeps the FIRST value, not the previous one', () {
    // Two edits. The original must survive both.
    final RecordedTime twice = RecordedTime.entered(
      effective: _happened,
      now: _wroteItDown,
    ).editedTo(_correctedTo).editedTo(Instant.fromDateTime(DateTime.utc(2026, 3, 14, 2)));

    final RecordedTime rebuilt = recordedTimeFromColumns(
      effective: twice.effective,
      capturedAt: twice.capturedAt,
      originalEffective: twice.originalEffective,
      sourceKey: twice.source.key,
    );

    expect(rebuilt.originalEffective, _happened, reason: 'the FIRST value, across the chain');
  });

  test("a row marked edited with no original throws rather than being repaired", () {
    // The schema's paired CHECK makes this unstorable —
    // CHECK ((time_source = 'edited') = (original_effective IS NOT NULL)) — so
    // reaching it means the row came from somewhere else: a restore from a
    // corrupted backup, or a future bug. Substituting a value would be the app
    // INVENTING provenance, which is the one thing §12.5 exists to stop.
    expect(
      () => recordedTimeFromColumns(
        effective: _correctedTo,
        capturedAt: _wroteItDown,
        originalEffective: null,
        sourceKey: 'edited',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('an unknown source key throws rather than defaulting to auto', () {
    // Defaulting would label a time "recorded automatically" on the strength of
    // a key nobody recognises — the app claiming it watched something when it
    // does not know.
    expect(
      () => recordedTimeFromColumns(
        effective: _happened,
        capturedAt: _happened,
        originalEffective: null,
        sourceKey: 'guessed',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('the label is never empty, on any arm', () {
    for (final String key in <String>['auto', 'entered']) {
      final RecordedTime t = recordedTimeFromColumns(
        effective: _happened,
        capturedAt: key == 'auto' ? _happened : _wroteItDown,
        originalEffective: null,
        sourceKey: key,
      );
      expect(t.provenanceLabel, isNotEmpty, reason: key);
    }
  });
}

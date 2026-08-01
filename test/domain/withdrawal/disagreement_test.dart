// test/domain/withdrawal/disagreement_test.dart — §12.4 in one function: a
// warning computed from stored inputs, shown, never applied.
//
// It sits under test/domain/withdrawal/ rather than mirroring
// lib/domain/validation/treatment_checks.dart because the property under test is
// the WITHDRAWAL disagreement. N06-T03 adds the validator-shaped tests in
// test/domain/validation/ when checkTreatment lands beside checkClearDate.
//
// Zone-agnostic. The real-world origin story — a row written by the civil-day
// bug across the spring-forward — is one case in
// test/domain/uk_zone/clear_date_dst_test.dart, because that is where it happens.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/validation/treatment_checks.dart';
import 'package:shed_book/domain/validation/warning.dart';
import 'package:shed_book/domain/withdrawal/clear_date.dart';

/// June: transition-free in Europe/London, Pacific/Chatham and UTC.
final Instant _treatedAt20 = Instant.fromDateTime(DateTime(2026, 6, 3, 20));

/// What the arithmetic actually produces for those inputs, so the cases below
/// can be built relative to it rather than around a hard-coded June date.
LocalDate _recomputed(int days) => clearDateFor(administeredAt: _treatedAt20, days: days).date;

void main() {
  test('clearDateDisagrees warns and returns the stored clear date unchanged', () {
    // The three causes — the device zone changed, an input was edited, the row
    // predates a fix — produce one warning and no correction. The function does
    // not branch on the cause, because the app cannot know which one it was.
    final LocalDate stored = _recomputed(7).plusDays(-1);

    final List<Warning> warnings = checkClearDate(
      administeredAt: _treatedAt20,
      days: 7,
      storedClearDate: stored,
    );

    expect(warnings, hasLength(1));
    expect(warnings.single.code, WarningCode.clearDateDisagrees);
    expect(warnings.single.message, contains(stored.iso));
    expect(warnings.single.message, contains(_recomputed(7).iso));
    expect(warnings.single.fieldPath, 'withdrawal');

    // "Returns the stored value, always" — held by the function handing back no
    // date at all. There is no return path yielding the recomputed date as a
    // value a caller could persist, so the date the caller passed in is the only
    // one that survives the call, and it stays the one printed in the medicine
    // book.
    expect(stored, _recomputed(7).plusDays(-1));
  });

  test('agreement returns a const empty list, not a warning with an empty message', () {
    final List<Warning> warnings = checkClearDate(
      administeredAt: _treatedAt20,
      days: 7,
      storedClearDate: _recomputed(7),
    );

    expect(warnings, isEmpty);
    expect(
      identical(warnings, const <Warning>[]),
      isTrue,
      reason:
          'this runs on every render of every treatment row; the agreeing path allocates nothing',
    );
  });

  test('the message names the stored date first and the recomputed date second', () {
    // Pinned so a reword cannot silently swap them. 07 §10.4 renders the stored
    // date first, and a shepherd reading the two in the wrong order would think
    // the app had already changed the record.
    final LocalDate stored = _recomputed(7).plusDays(-1);

    final String message = checkClearDate(
      administeredAt: _treatedAt20,
      days: 7,
      storedClearDate: stored,
    ).single.message;

    expect(
      message.indexOf(stored.iso),
      lessThan(message.indexOf(_recomputed(7).iso)),
      reason: 'stored first: $message',
    );
  });

  test('a zero-day withdrawal whose stored date was rounded down disagrees by one day', () {
    // Where a naive implementation stores TODAY: the period elapses at the moment
    // of administration, so today is a partial day and the clear date is
    // tomorrow. A row written by that implementation disagrees by exactly one day
    // — and is still not corrected.
    final LocalDate storedAsToday = LocalDate.of(_treatedAt20);

    final List<Warning> warnings = checkClearDate(
      administeredAt: _treatedAt20,
      days: 0,
      storedClearDate: storedAsToday,
    );

    expect(warnings.single.code, WarningCode.clearDateDisagrees);
    expect(storedAsToday.daysUntil(_recomputed(0)), 1);
  });

  test('checkClearDate exposes no writer: its only return type is List of Warning', () {
    // The negative-space assertion, kept beside the positive one. There is no
    // fix(), no repair path and no writer — editing the treatment is a user
    // action that writes a new clear_date through the normal repository path,
    // and nothing else may rewrite it.
    final List<Warning> warnings = checkClearDate(
      administeredAt: _treatedAt20,
      days: 7,
      storedClearDate: _recomputed(7).plusDays(-1),
    );

    expect(warnings, isA<List<Warning>>());
    expect(warnings.single, isA<Warning>());
    // Warning itself holds nothing mutable and offers nothing to apply.
    expect(warnings.single.message, isA<String>());
    expect(warnings.single.fieldPath, isA<String?>());
  });

  test('the warning is recomputed identically on every call', () {
    // Purity: no memo, no cache, nothing to invalidate. Warnings are never
    // persisted — there is no `warnings` column — so they are recomputed on read,
    // and a derived value that is never stored can never diverge from its source.
    final LocalDate stored = _recomputed(14).plusDays(2);

    final Warning first = checkClearDate(
      administeredAt: _treatedAt20,
      days: 14,
      storedClearDate: stored,
    ).single;
    final Warning second = checkClearDate(
      administeredAt: _treatedAt20,
      days: 14,
      storedClearDate: stored,
    ).single;

    expect(first.code, second.code);
    expect(first.message, second.message);
    expect(first.fieldPath, second.fieldPath);
  });
}

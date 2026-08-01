// test/data/failure_mapping_test.dart — every result code, mapped.
//
// Against a real in-memory SQLite, never a mock (00-README §8 step 12). The host
// needs libsqlite3-dev; CI installs it in the `test` job.
//
// Nothing here is time-shaped: a result code carries no clock.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/failure.dart';
import 'package:shed_book/data/failure_mapping.dart';
import 'package:sqlite3/common.dart' show SqliteException;

/// A `SqliteException` carrying [extendedResultCode].
///
/// **`resultCode` IS DERIVED, not stored**: sqlite3 3.5.0 computes it as
/// `extendedResultCode & 0xFF`, and the constructor takes only the extended
/// code. 01 §5.3's printed function destructures both, which works — but a test
/// cannot set them independently, and one that tried would be asserting against
/// a shape the package does not have. So 2067 gives resultCode 19, and 13 gives
/// 13.
///
/// Constructed rather than provoked, because you cannot fill a disk from a unit
/// test — and that is honest here since **the code is the whole input** to the
/// function under test.
SqliteException _sqlite(int extendedResultCode) => SqliteException(
  extendedResultCode: extendedResultCode,
  message: 'a message that embeds the failing SQL and must never be shown',
  causingStatement: 'INSERT INTO ewes (tag) VALUES (?)',
);

void main() {
  test('a unique-constraint violation maps to a named ShedFailure, not to a generic one', () {
    // THE ANCHOR. resultCode 19 / extendedResultCode 2067 is what
    // idx_ewe_tag_active throws for two active ewes on tag 412.
    //
    // It maps to UnexpectedFailure ON PURPOSE: a duplicate active tag is a
    // PROGRAMMER error, not a storage one. The write path is meant to have
    // checked, and telling a shepherd to free space would be a lie.
    final SqliteException e = _sqlite(2067);
    expect(e.resultCode, 19, reason: '2067 & 0xFF');
    final ShedFailure f = shedFailureFrom(e);

    expect(f, isA<UnexpectedFailure>());
    expect((f as UnexpectedFailure).error, same(e));
    expect(f, isNot(isA<DiskFull>()));
  });

  test('the DriftRemoteException unwrap is present but CANNOT be exercised from a test', () {
    // THE HALF THAT ONLY RUNS IN PRODUCTION, and it turns out it cannot be run
    // here either.
    //
    // MEASURED against drift 2.34.2: DriftRemoteException's only constructor is
    // PRIVATE — `DriftRemoteException._(this.remoteCause, this.remoteStackTrace)`
    // — so a test cannot build one. drift_flutter runs SQLite on a background
    // isolate and produces the wrapper on every real device; an in-process
    // NativeDatabase.memory() never does.
    //
    // So this branch is verified by READING, not by running, and that is stated
    // rather than papered over with a fake that would prove nothing about the
    // real type. What IS assertable is that the unwrap is there and happens
    // before classification — because a `catch` clause written against the bare
    // SqliteException passes every test in this file and classifies NOTHING on a
    // phone.
    final String source = File(
      'lib/data/failure_mapping.dart',
    ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

    expect(source, contains('error is DriftRemoteException ? error.remoteCause : error'));
    expect(
      source.indexOf('remoteCause'),
      lessThan(source.indexOf('SqliteException(')),
      reason: 'the unwrap must happen BEFORE the classification',
    );
  });

  test('SQLITE_FULL maps to DiskFull', () {
    expect(shedFailureFrom(_sqlite(13)), isA<DiskFull>());
  });

  test('SQLITE_IOERR maps to StorageWriteFailed and the message does not mention space', () {
    // THE ONE CASE IN THIS FILE ABOUT SAFETY RATHER THAN SHAPE. IOERR means the
    // app knows the write did not land and does NOT know why.
    final ShedFailure f = shedFailureFrom(_sqlite(10));
    expect(f, isA<StorageWriteFailed>());
    expect(f.userMessage, isNot(contains('out of space')));
  });

  test('SQLITE_CORRUPT and SQLITE_NOTADB both map to DatabaseUnreadable and carry both codes', () {
    for (final int code in <int>[11, 26]) {
      final ShedFailure f = shedFailureFrom(_sqlite(code));
      expect(f, isA<DatabaseUnreadable>(), reason: '$code');
      expect((f as DatabaseUnreadable).resultCode, code);
      expect(f.extendedResultCode, code);
    }
  });

  test('SQLITE_READONLY, SQLITE_PERM and SQLITE_CANTOPEN all map to StorageReadOnly', () {
    // Three codes, one thing the user can do about it.
    for (final int code in <int>[8, 3, 14]) {
      expect(shedFailureFrom(_sqlite(code)), isA<StorageReadOnly>(), reason: '$code');
    }
  });

  test('an unknown SQLite result code maps to UnexpectedFailure and says so', () {
    final ShedFailure f = shedFailureFrom(_sqlite(99));
    expect(f, isA<UnexpectedFailure>());
    expect(f.userMessage, contains('Something went wrong'));
  });

  test('a non-SQLite object maps to UnexpectedFailure without inspecting it', () {
    // THE FUNCTION IS TOTAL: there is no input for which it throws. A mapping
    // function that can itself fail is one that fails inside a catch.
    for (final Object input in <Object>[
      StateError('x'),
      'a bare string',
      42,
      <int>[1],
    ]) {
      final ShedFailure f = shedFailureFrom(input);
      expect(f, isA<UnexpectedFailure>(), reason: '$input');
      expect((f as UnexpectedFailure).error, same(input), reason: '$input');
    }
  });

  test('no ShedFailure produced here ever renders the exception message', () {
    // 13 §8.4, made mechanical at the one place it can leak. A SqliteException's
    // toString() embeds the failing SQL, and the failing SQL embeds the
    // shepherd's tags, note text and batch numbers.
    for (final int code in <int>[13, 10, 11, 26, 8, 3, 14, 19, 99]) {
      final SqliteException e = _sqlite(code);
      final String message = shedFailureFrom(e).userMessage;

      for (final String word in e.toString().split(RegExp(r'\W+'))) {
        if (word.length <= 4) {
          continue;
        }
        expect(
          message.toLowerCase(),
          isNot(contains(word.toLowerCase())),
          reason: 'code $code leaked "$word"',
        );
      }
    }
  });

  test('MediaWriteFailed is not reachable from this function', () {
    // It is a FileSystemException from MediaStore, mapped at that gateway
    // (01 §5.1). Adding an arm for it here would put media IO behind a
    // SQLite-shaped door.
    for (final int code in <int>[3, 8, 10, 11, 13, 14, 19, 26, 99]) {
      expect(shedFailureFrom(_sqlite(code)), isNot(isA<MediaWriteFailed>()), reason: '$code');
    }
    expect(shedFailureFrom(const FileSystemExceptionStub()), isA<UnexpectedFailure>());
  });
}

/// A stand-in for a media-layer failure, so the case above can show that this
/// function does not classify one.
class FileSystemExceptionStub implements Exception {
  const FileSystemExceptionStub();
}

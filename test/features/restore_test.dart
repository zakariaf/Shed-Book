// test/features/restore_test.dart — the most destructive code in the app, and
// the four states an interrupted swap can leave behind.
//
// **AN APP THAT KNOWS ONLY TWO STATES REPORTS THE FIRST ROW AS SUCCESS.** That
// is the specific lie `RestoreOutcome` exists to prevent: a crash between the
// sentinel and the first rename has changed nothing at all, and telling a
// shepherd their restore worked when their old records are still there — and the
// new ones are not — is worse than telling them it failed.
//
// The fault is injected **between step 10 and step 11**, through a seam the
// service exposes for exactly this. Not a `try`/`catch` round the whole flow:
// that proves the flow can fail, which nobody doubted, and proves nothing about
// where.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/data/restore_service.dart';

/// The three files a SQLite database is, and the reason `_moveInto` moves all
/// three: a main file reunited with a stale `-wal` is the corruption `04 §8.1`
/// describes, and it looks like a working database until it does not.
const List<String> _sidecars = <String>['', '-wal', '-shm'];

Directory _support() {
  final Directory dir = Directory.systemTemp.createTempSync('shed_support');
  addTearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });
  return dir;
}

void _writeDb(Directory support, String name, String contents) {
  for (final String suffix in _sidecars) {
    File('${support.path}/$name$suffix').writeAsStringSync('$contents$suffix');
  }
}

String? _read(Directory support, String name) {
  final File f = File('${support.path}/$name');
  return f.existsSync() ? f.readAsStringSync() : null;
}

void main() {
  test('a restore interrupted before the swap leaves the live database untouched', () async {
    // THE ANCHOR. Crashed after the sentinel, before the first rename.
    final Directory support = _support();
    _writeDb(support, kLiveDatabaseName, 'ORIGINAL');
    File('${support.path}/$kRestoreSentinelName').writeAsStringSync('');

    // `(live: true, rollback: false)` — nothing has moved.
    final RestoreOutcome outcome = await completeInterruptedRestore(support);

    // **NOT `completed`, NOT `rolledBack`.** The restore did not start.
    expect(outcome, RestoreOutcome.notStarted);

    // The live file still holds the ORIGINAL rows, all three parts of it.
    for (final String suffix in _sidecars) {
      expect(_read(support, '$kLiveDatabaseName$suffix'), 'ORIGINAL$suffix');
    }

    // AND THE EVIDENCE IS CLEARED. A sentinel left behind makes the next launch
    // resolve the same state again, for ever.
    expect(File('${support.path}/$kRestoreSentinelName').existsSync(), isFalse);
    expect(Directory('${support.path}/$kRestoreStagingDir').existsSync(), isFalse);
  });

  test('a restore interrupted between the two renames is rolled back', () async {
    // `(live: false, rollback: true)` — the live file was moved aside and the
    // incoming one had not landed. The original comes back.
    final Directory support = _support();
    _writeDb(support, kRestoreRollbackName, 'ORIGINAL');
    File('${support.path}/$kRestoreSentinelName').writeAsStringSync('');

    expect(await completeInterruptedRestore(support), RestoreOutcome.rolledBack);

    for (final String suffix in _sidecars) {
      expect(_read(support, '$kLiveDatabaseName$suffix'), 'ORIGINAL$suffix');
    }
    expect(File('${support.path}/$kRestoreRollbackName').existsSync(), isFalse);
    expect(File('${support.path}/$kRestoreSentinelName').existsSync(), isFalse);
  });

  test('a restore interrupted after the second rename is a success we failed to record', () async {
    // `(live: true, rollback: true)` — the new file landed and the old one had
    // not been cleared yet. **This is `completed`**, and it is the arm that
    // most invites a wrong answer: the new file was fully validated at step 7,
    // so it is a success we merely failed to write down.
    final Directory support = _support();
    _writeDb(support, kLiveDatabaseName, 'INCOMING');
    _writeDb(support, kRestoreRollbackName, 'ORIGINAL');
    File('${support.path}/$kRestoreSentinelName').writeAsStringSync('');

    expect(await completeInterruptedRestore(support), RestoreOutcome.completed);

    expect(_read(support, kLiveDatabaseName), 'INCOMING');
    expect(
      File('${support.path}/$kRestoreRollbackName').existsSync(),
      isFalse,
      reason: 'the old file is cleared, which is what step 13 was going to do',
    );
  });

  test('both files gone is recovered from staging, and only otherwise is it fatal', () async {
    // `(live: false, rollback: false)` — mid-rename, or somebody was tidying up.
    // Staging is tried FIRST, because the validated file may still be sitting
    // there, and `lostBothFiles` is the only branch that reaches `04 §8.4`'s
    // corruption screen. Reaching it when a good file exists two directories
    // away would be the worst possible false alarm.
    final Directory recoverable = _support();
    Directory('${recoverable.path}/$kRestoreStagingDir').createSync();
    _writeDb(recoverable, '$kRestoreStagingDir/$kLiveDatabaseName', 'STAGED');
    File('${recoverable.path}/$kRestoreSentinelName').writeAsStringSync('');

    expect(await completeInterruptedRestore(recoverable), RestoreOutcome.completed);
    expect(_read(recoverable, kLiveDatabaseName), 'STAGED');

    final Directory lost = _support();
    File('${lost.path}/$kRestoreSentinelName').writeAsStringSync('');
    expect(await completeInterruptedRestore(lost), RestoreOutcome.lostBothFiles);
  });

  test('no sentinel is nothing to do, and it is the answer on every ordinary launch', () async {
    // The common case, and it must be cheap: one `existsSync` on a path that is
    // not there. This runs before the database opens, on every cold start,
    // including the 03:20 one.
    expect(await completeInterruptedRestore(_support()), RestoreOutcome.nothingToDo);
  });

  test('every move carries the -wal and the -shm with it', () async {
    // `04 §8.1`: a main file reunited with a stale write-ahead log is
    // corruption that looks like a working database until it does not. Both
    // sidecars travel in both directions, or neither does.
    final Directory support = _support();
    _writeDb(support, kRestoreRollbackName, 'ORIGINAL');
    File('${support.path}/$kRestoreSentinelName').writeAsStringSync('');

    await completeInterruptedRestore(support);

    for (final String suffix in _sidecars) {
      expect(_read(support, '$kLiveDatabaseName$suffix'), 'ORIGINAL$suffix', reason: suffix);
      expect(File('${support.path}/$kRestoreRollbackName$suffix').existsSync(), isFalse);
    }
  });

  test('notStarted is never a legal answer to "did the restore work"', () {
    // `09 §7.3`. The enum has five members and only two of them mean the
    // shepherd's records changed. Stated as an assertion so a sixth member
    // cannot be added without somebody deciding which side it is on.
    const Set<RestoreOutcome> changedTheRecords = <RestoreOutcome>{
      RestoreOutcome.completed,
      RestoreOutcome.rolledBack,
    };
    expect(RestoreOutcome.values, hasLength(5));
    expect(changedTheRecords, isNot(contains(RestoreOutcome.notStarted)));
    expect(changedTheRecords, isNot(contains(RestoreOutcome.nothingToDo)));
    expect(changedTheRecords, isNot(contains(RestoreOutcome.lostBothFiles)));
  });
}

// test/data/local_log_test.dart
//
// A REAL temp directory per test, torn down with it. No fake filesystem: the
// properties under test are sync write, flush, rotation and "the file survives a
// process boundary", and a fake proves none of them.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/log/local_log.dart';

late Directory _dir;

String _log() {
  final File f = File('${_dir.path}/${LocalLog.logName}');
  return f.existsSync() ? f.readAsStringSync() : '';
}

Map<String, Object?> _lock() =>
    jsonDecode(File('${_dir.path}/${LocalLog.lockName}').readAsStringSync())
        as Map<String, Object?>;

/// A stand-in for a database failure, carrying the two integers the real one
/// does. Duck-typed on purpose: `lib/core/` may not import the driver.
class _FakeSqliteException implements Exception {
  const _FakeSqliteException();
  int get resultCode => 11;
  int get extendedResultCode => 2067;
  @override
  String toString() =>
      'SqliteException(2067): while inserting, UNIQUE constraint failed, '
      'INSERT INTO ewes (tag) VALUES (412) -- prolapse noted by vet';
}

void main() {
  setUp(() {
    _dir = Directory.systemTemp.createTempSync('shed_log_');
    LocalLog.instance.resetForTest();
  });

  tearDown(() {
    LocalLog.instance.resetForTest();
    if (_dir.existsSync()) {
      _dir.deleteSync(recursive: true);
    }
  });

  test('a tag number and a free-text note are redacted before they reach the log file', () {
    // THE ANCHOR, BOTH DIRECTIONS. What must survive is what makes the file
    // useful; what must not is everything the shepherd typed.
    LocalLog.instance.attachTo(_dir);
    LocalLog.instance.record('nav.lambing_entry');
    LocalLog.instance.write('uncaught', StateError('x'), StackTrace.current);

    final String contents = _log();

    expect(contents, contains('StateError'));
    expect(contents, contains('nav.lambing_entry'));
    expect(contents, matches(RegExp(r'\d{4}-\d{2}-\d{2}T[\d:.]+Z')), reason: 'a UTC timestamp');

    expect(contents, isNot(contains('412')));
    expect(contents, isNot(contains('prolapse')));
  });

  test('a database failure reaches the log as two integers and never as a message', () {
    // 13 §8.4's rule, at the one place it bites. The exception's text embeds the
    // failing SQL, and the failing SQL embeds the tag and the note.
    LocalLog.instance.attachTo(_dir);
    const _FakeSqliteException e = _FakeSqliteException();
    LocalLog.instance.write('db', e, StackTrace.current);

    final String contents = _log();

    expect(contents, contains('code=11'));
    expect(contents, contains('extended=2067'));

    // The TYPE NAME is excluded, because writing it is the point: `write()`
    // records `error.runtimeType` deliberately, and the type happens to be a
    // substring of the message too. Asserting on it would be asserting that the
    // log records nothing useful.
    final String typeName = e.runtimeType.toString();
    for (final String word in e.toString().split(RegExp(r'\W+'))) {
      if (word.length <= 4 || typeName.contains(word)) {
        continue;
      }
      expect(contents, isNot(contains(word)), reason: 'leaked "$word"');
    }
    expect(contents, isNot(contains('prolapse')), reason: 'the note is in the SQL');
    expect(contents, isNot(contains('INSERT')), reason: 'the failing SQL itself');
  });

  test('a withdrawal period never reaches the log', () {
    // Called out separately because it is the one forbidden field that is a BARE
    // NUMBER and looks harmless in a log line.
    //
    // ASSERTED OVER THE LINES THIS TEST WROTE, NOT OVER THE WHOLE FILE, and that
    // is a fix for a REAL ORDER DEPENDENCY rather than a weakening.
    //
    // `LocalLog.instance` is a process-wide singleton with a pre-attach ring
    // buffer, and `attachTo` FLUSHES that buffer into whichever directory
    // attaches next — the behaviour the "records written before attachTo are
    // flushed on attach" case exists to guarantee. So a record written by
    // ANOTHER test file while unattached lands in this file's log, and any `28`
    // anywhere in it — a byte count, an id, a timestamp — failed this case.
    // Measured: the file passes alone under every seed and failed two runs in
    // three under `make test`, which randomises across the suite.
    //
    // The claim is unchanged and still exact: a withdrawal period must not
    // appear in the record that carries it. Scoping to the withdrawal lines is
    // what makes the case about this file's own behaviour.
    LocalLog.instance.attachTo(_dir);
    LocalLog.instance.record('treatment withdrawal 28 days');

    final List<String> ours = _log()
        .split('\n')
        .where((String line) => line.contains('withdrawal'))
        .toList();

    expect(ours, isNotEmpty, reason: 'the record must actually have been written');
    for (final String line in ours) {
      expect(line, isNot(contains('28')), reason: line);
    }

    // AND THE REDACTOR ITSELF, independent of any file. This is the half that
    // cannot be affected by ordering at all.
    expect(LocalLog.redact('treatment withdrawal 28 days'), isNot(contains('28')));
  });

  test('a media path with a sandbox UUID is rewritten, and the stack frames survive', () {
    // Dropping the frame is the wrong fix: it removes the only part of the
    // record that says where the failure was.
    const String path =
        '/var/mobile/Containers/Data/Application/'
        'A1B2C3D4-E5F6-4A7B-8C9D-0E1F2A3B4C5D/Documents/photo.jpg';
    final String redacted = LocalLog.redact('media $path at MyClass.build (file.dart:42:7)');

    expect(redacted, isNot(contains('A1B2C3D4')));
    expect(redacted, contains('<uuid>'));
    expect(redacted, contains('MyClass.build'));
    expect(redacted, contains('file.dart:42:7'), reason: 'the frame survives');
  });

  test('records written before attachTo are flushed on attach, in order', () {
    // main() installs the handlers and the directory is unknown until
    // post-frame, so anything logged in between must survive AND must not
    // reorder — a log whose first three lines are shuffled is a log that cannot
    // answer "what happened just before".
    LocalLog.instance.record('nav.first');
    LocalLog.instance.record('nav.second');
    LocalLog.instance.record('nav.third');

    expect(_log(), isEmpty, reason: 'nothing on disk before attach');
    expect(LocalLog.instance.buffered, hasLength(3));

    LocalLog.instance.attachTo(_dir);

    final String contents = _log();
    expect(contents.indexOf('nav.first'), lessThan(contents.indexOf('nav.second')));
    expect(contents.indexOf('nav.second'), lessThan(contents.indexOf('nav.third')));
  });

  test('the ring buffer is bounded and drops oldest first', () {
    for (int i = 0; i < LocalLog.capacity + 20; i++) {
      LocalLog.instance.record('nav.route_$i');
    }
    expect(LocalLog.instance.buffered, hasLength(LocalLog.capacity));

    LocalLog.instance.attachTo(_dir);
    final String contents = _log();

    expect(
      contents,
      isNot(contains('nav.route_0 ')),
      reason: 'the oldest should have been dropped',
    );
    expect(contents, contains('nav.route_${LocalLog.capacity + 19}'));
  });

  test('the log rotates at 256 KB and keeps exactly one rotation', () {
    // THE LOG MUST NEVER CONTRIBUTE TO THE DISK-FULL FAILURE IT IS RECORDING.
    LocalLog.instance.attachTo(_dir);
    final String filler = 'nav.${'x' * 500}';
    for (int i = 0; i < 1200; i++) {
      LocalLog.instance.record(filler);
    }

    final File live = File('${_dir.path}/${LocalLog.logName}');
    final File rotated = File('${_dir.path}/${LocalLog.rotatedName}');

    expect(live.existsSync(), isTrue);
    expect(rotated.existsSync(), isTrue, reason: 'it never rotated');
    expect(File('${_dir.path}/shedbook.2.log').existsSync(), isFalse);
    expect(
      live.lengthSync() + rotated.lengthSync(),
      lessThan(LocalLog.maxBytes * 2 + 4096),
      reason: 'the total on disk exceeded two files',
    );
  });

  test('a crash-path write reaches disk without a flush of the stream', () {
    // No await anywhere in this case. The process may be gone before a microtask
    // runs, so the content has to be there the instant the call returns.
    LocalLog.instance.attachTo(_dir);
    LocalLog.instance.write('uncaught', StateError('boom'), StackTrace.current);

    expect(_log(), contains('StateError'));
  });

  test('a failure inside the log is swallowed and never propagates', () {
    // Diagnostics must never be the cause of a crash. A log that throws while
    // recording a failure turns one into two, and the second has no handler
    // left.
    final Directory gone = Directory('${_dir.path}/missing');
    LocalLog.instance.attachTo(gone);
    gone.deleteSync(recursive: true);

    expect(
      () => LocalLog.instance.write('uncaught', StateError('x'), StackTrace.current),
      returnsNormally,
    );
    expect(() => LocalLog.instance.record('nav.x'), returnsNormally);
    expect(LocalLog.instance.markCleanPause, returnsNormally);
  });

  test('attachTo creates the diagnostics directory on first run', () {
    final Directory fresh = Directory('${_dir.path}/diagnostics');
    expect(fresh.existsSync(), isFalse);

    LocalLog.instance.attachTo(fresh);

    expect(fresh.existsSync(), isTrue);
    expect(File('${fresh.path}/${LocalLog.lockName}').existsSync(), isTrue);
  });

  test('a session.lock left with clean false is reported on the next attachTo', () {
    File('${_dir.path}/${LocalLog.lockName}').writeAsStringSync(
      jsonEncode(<String, Object?>{
        'startedAt': '2026-03-11T02:41:07.412Z',
        'appVersion': '1.2.0',
        'build': 187,
        'lastEvent': 'nav.lambing_entry',
        'freeBytes': 4831838208,
        'clean': false,
      }),
    );

    LocalLog.instance.attachTo(_dir);

    final String contents = _log();
    expect('session.abnormal_termination'.allMatches(contents).length, 1);
    expect(contents, contains('nav.lambing_entry'));
  });

  test('a clean pause is not reported as abnormal', () {
    // THE NEGATIVE. Without it, the previous case passes on an implementation
    // that always reports.
    File('${_dir.path}/${LocalLog.lockName}').writeAsStringSync(
      jsonEncode(<String, Object?>{
        'startedAt': '2026-03-11T02:41:07.412Z',
        'appVersion': '1.2.0',
        'build': 187,
        'lastEvent': 'nav.flock',
        'freeBytes': 1,
        'clean': true,
      }),
    );

    LocalLog.instance.attachTo(_dir);

    expect(_log(), isNot(contains('session.abnormal_termination')));
  });

  test('markCleanPause rewrites the lock rather than deleting it', () {
    // 13 §7.3: the CONTENTS are what make the next report useful. An absent file
    // says only "something happened".
    LocalLog.instance.attachTo(_dir);
    LocalLog.instance.record('nav.flock');
    LocalLog.instance.markCleanPause();

    expect(File('${_dir.path}/${LocalLog.lockName}').existsSync(), isTrue);
    expect(_lock()['clean'], isTrue);
    expect(_lock()['lastEvent'], 'nav.flock');
  });

  test('the lock re-arms on the first record after a pause, and only once', () {
    LocalLog.instance.attachTo(_dir);
    LocalLog.instance.markCleanPause();
    expect(_lock()['clean'], isTrue);

    LocalLog.instance.record('nav.a');
    expect(_lock()['clean'], isFalse, reason: 'the session did not re-arm');

    final String afterFirst = File('${_dir.path}/${LocalLog.lockName}').readAsStringSync();
    LocalLog.instance.record('nav.b');
    final String afterSecond = File('${_dir.path}/${LocalLog.lockName}').readAsStringSync();

    expect(
      afterSecond,
      afterFirst,
      reason: 'the second record rewrote the lock — one arm per session, not one per record',
    );
  });

  test('a session.lock carries only the six allowed fields', () {
    // A SEVENTH KEY IS HOW A TAG GETS INTO A FILE the shepherd may hand to
    // somebody.
    LocalLog.instance.attachTo(_dir);

    expect(_lock().keys.toSet(), <String>{
      'startedAt',
      'appVersion',
      'build',
      'lastEvent',
      'freeBytes',
      'clean',
    });
  });

  test('nothing this file writes is ever transmitted', () {
    // G3 covers lib/ broadly; this is the file where it matters most, because it
    // is the one holding everything that went wrong.
    final String source = File(
      'lib/core/log/local_log.dart',
    ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

    for (final String banned in <String>['HttpClient', 'Socket', 'Uri.http', 'dart:html']) {
      expect(source, isNot(contains(banned)), reason: banned);
    }
  });

  test('the banned words appear nowhere in lib/core/log/, in code or in comments', () {
    // CONVENTIONS §5.2. Over the WHOLE source, comments included: the word is
    // what teaches the next reader what this file is, and it is not a crash
    // reporter.
    for (final FileSystemEntity f in Directory('lib/core/log').listSync(recursive: true)) {
      if (f is! File) {
        continue;
      }
      final String source = f.readAsStringSync().toLowerCase();
      for (final String banned in <String>['crash log', 'telemetry', 'analytics']) {
        expect(source, isNot(contains(banned)), reason: '${f.path} says $banned');
      }
    }
  });
}

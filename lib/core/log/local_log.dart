// lib/core/log/local_log.dart — the diagnostics log.
//
// This is NOT a reporter of any kind (#123) — the two words CONVENTIONS §5.2
// bans for that idea are absent from this whole directory, and a test asserts it
// over comments as well as code, which is why this sentence describes rather
// than names them. Nothing here leaves the phone unless the shepherd
// deliberately saves a copy from Settings ▸ Diagnostics.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shed_book/core/time/app_clock.dart';

/// Compiled in at build time (13 §9.1.1). Constants rather than a lookup because
/// there is no package in the graph that can supply them.
const String kAppVersion = String.fromEnvironment('SHED_APP_VERSION', defaultValue: '0.1.0');
const int kAppBuild = int.fromEnvironment('SHED_APP_BUILD', defaultValue: 1);

/// The diagnostics log.
final class LocalLog {
  LocalLog._();

  /// **The one static-field singleton in `lib/`** (02 §4.6, R52).
  ///
  /// The three error handlers are installed in `main()`, before any
  /// `ProviderScope` exists, and must still work when the container has been
  /// torn down by the very failure being logged. A provider cannot satisfy that:
  /// reading one requires a `Ref`, and the thing that just died is where the
  /// `Ref` came from.
  static final LocalLog instance = LocalLog._();

  /// Bounded, because the directory is unknown until `path_provider` resolves —
  /// which happens *after* the first frame (`01 §5.5`). An unbounded buffer
  /// waiting for a directory is a leak; a bounded one is a ring.
  static const int capacity = 200;

  /// 13 §7.4. **This file must never contribute to the disk-full failure it is
  /// recording**, so the total on disk is capped at twice this: one live file
  /// and exactly one rotation.
  static const int maxBytes = 256 * 1024;

  static const String logName = 'shedbook.log';
  static const String rotatedName = 'shedbook.1.log';
  static const String lockName = 'session.lock';

  final List<String> _buffered = <String>[];
  Directory? _dir;
  String _lastEvent = '';
  bool _armed = false;

  /// Records held before [attachTo], newest last. A copy, so a caller cannot
  /// mutate the buffer it is reading.
  @visibleForTesting
  List<String> get buffered => List<String>.unmodifiable(_buffered);

  /// The live log file's path, for the share sheet.
  ///
  /// **A PATH, NEVER BYTES.** `share_plus` takes files, and handing it the
  /// contents instead would mean holding a 256 KB string on the main isolate to
  /// build a file the platform is about to read off disk anyway.
  ///
  /// `null` before [attachTo] — on a launch where the support directory could
  /// not be created there is no log to send, and the Diagnostics row says so
  /// rather than offering a share that fails in the system sheet.
  String? get logFilePath => _dir == null ? null : _logFile.path;

  /// The last [limit] records, newest **last**, exactly as they sit on disk.
  ///
  /// **ALREADY REDACTED, BECAUSE REDACTION HAPPENS ON THE WAY IN** (`13 §8.4`).
  /// This is a read; it does not re-implement `Redact` and it must not — a
  /// second redaction pass is a second answer to *what is a tag number*, and the
  /// two would disagree the first time one of them was improved.
  ///
  /// Returns `const []` rather than throwing when there is nothing to read: a
  /// diagnostics screen that crashes is the one screen that cannot.
  List<String> recentRecords({int limit = 20}) {
    try {
      if (_dir == null) {
        return List<String>.unmodifiable(
          _buffered.length <= limit ? _buffered : _buffered.sublist(_buffered.length - limit),
        );
      }
      final File live = _logFile;
      if (!live.existsSync()) {
        return const <String>[];
      }
      final List<String> lines = live
          .readAsLinesSync()
          .where((String l) => l.trim().isNotEmpty)
          .toList();
      return List<String>.unmodifiable(
        lines.length <= limit ? lines : lines.sublist(lines.length - limit),
      );
    } on Object {
      // The log swallows its own failures everywhere else in this file, and a
      // read is no different: a diagnostics screen that cannot show the log must
      // still show everything else.
      return const <String>[];
    }
  }

  File get _logFile => File('${_dir!.path}/$logName');
  File get _lockFile => File('${_dir!.path}/$lockName');

  /// **Everything a shepherd typed, removed before it reaches disk** (13 §8.4).
  ///
  /// Deliberately aggressive. A tag, a note, a batch number, a withdrawal period
  /// and a sandbox UUID are all things a diagnostics file might be handed to
  /// somebody else with. The withdrawal period is the one that looks harmless:
  /// it is a **bare number** in a log line and nothing marks it out.
  ///
  /// **Stack frames survive.** Dropping a frame to remove a path is the wrong
  /// fix — it removes the only part of the record that says where the failure
  /// was.
  @visibleForTesting
  static String redact(String line) {
    String out = line;

    // A sandbox UUID inside a media path. The path shape survives; the identity
    // does not.
    out = out.replaceAll(
      RegExp(r'[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}'),
      '<uuid>',
    );

    // Any bare run of digits that is not part of a stack frame's line:column and
    // not part of a timestamp. A tag is a number, a withdrawal period is a
    // number, a batch number is a number — and none of them is worth the risk of
    // telling them apart.
    out = out.replaceAll(RegExp(r'(?<![:.\-\dTZ\w])\d+(?![:.\-\dTZ])'), '<n>');

    return out;
  }

  /// A structured event — `nav.<route_name>`, `restore.begin`,
  /// `migration.v1_to_v2`. **A route or an operation name, never a row, a tag, a
  /// note or a path.**
  void record(String event) {
    _lastEvent = event;
    _append('${appNow().utc.toIso8601String()} $event');
    _armIfNeeded();
  }

  /// **`error.toString()` is never written.** A database exception's text embeds
  /// the failing SQL, and the failing SQL embeds the shepherd's tags, note text
  /// and batch numbers. What is written is the TYPE, plus the two integers a
  /// database failure is actually diagnosed from.
  void write(String event, Object error, StackTrace stack) {
    final String safe = redact(
      '${appNow().utc.toIso8601String()} $event ${error.runtimeType}\n$stack',
    );
    _appendSafe(safe.replaceFirst('\n', '${_sqliteCodes(error)}\n'));
  }

  void flutterError(FlutterErrorDetails details) =>
      write('flutter', details.exception, details.stack ?? StackTrace.empty);

  /// The two result codes, read by **duck typing rather than by importing the
  /// driver**: `lib/core/` may not depend on sqlite3, and
  /// `lib/data/failure_mapping.dart` is the one file that names it.
  ///
  /// They are appended AFTER redaction rather than before, and that ordering is
  /// the whole trick. The first attempt relied on a `code=` prefix to protect
  /// them and the digit rule ate them anyway — the log recorded `code=<n>`,
  /// which is worse than useless. A diagnostic integer the app produced is not a
  /// value the shepherd typed, so it must never pass through the redactor at
  /// all.
  String _sqliteCodes(Object error) {
    try {
      // Two dynamic reads, ignored deliberately and scoped to these lines. The
      // alternative is importing sqlite3 into lib/core/, which breaks layer rule
      // 8 — and lib/data/failure_mapping.dart is meant to be the ONE file that
      // names the driver. A NoSuchMethodError here is the expected outcome for
      // every non-database failure and is caught below.
      final dynamic e = error;
      // ignore: avoid_dynamic_calls
      final Object? code = e.resultCode;
      // ignore: avoid_dynamic_calls
      final Object? extended = e.extendedResultCode;
      if (code is int && extended is int) {
        return ' code=$code extended=$extended';
      }
    } on NoSuchMethodError catch (_) {
      // Not a database failure. Nothing to add.
    }
    return '';
  }

  void _append(String line) => _appendSafe(redact(line));

  /// Takes a line that has ALREADY been redacted. Nothing may reach this that
  /// has not passed through [redact] or been produced by the app itself.
  void _appendSafe(String safe) {
    if (_dir == null) {
      _buffered.add(safe);
      if (_buffered.length > capacity) {
        _buffered.removeAt(0);
      }
      return;
    }
    _writeThrough(safe);
  }

  /// **Synchronous, with `flush: true`.** A crash-path write has no `await` to
  /// come back from: the process may be gone before a microtask runs.
  ///
  /// **Every failure here is swallowed.** Diagnostics must never be the cause of
  /// a crash — a log that throws while recording a failure turns one into two,
  /// and the second has no handler left.
  void _writeThrough(String line) {
    try {
      _rotateIfNeeded();
      _logFile.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    } on Object catch (_) {
      // Deliberately silent. See above.
    }
  }

  void _rotateIfNeeded() {
    final File live = _logFile;
    if (!live.existsSync() || live.lengthSync() < maxBytes) {
      return;
    }
    final File rotated = File('${_dir!.path}/$rotatedName');
    if (rotated.existsSync()) {
      rotated.deleteSync();
    }
    live.renameSync(rotated.path);
  }

  /// Attaches to a directory, flushes the ring buffer **in order**, and reports a
  /// previous session that never reached a clean pause.
  ///
  /// The report happens here because this is the first moment the previous lock
  /// can be read at all.
  void attachTo(Directory dir) {
    try {
      dir.createSync(recursive: true);
      final Map<String, Object?>? previous = _readLockIn(dir);

      _dir = dir;

      if (previous != null && previous['clean'] == false) {
        _writeThrough(
          '${appNow().utc.toIso8601String()} session.abnormal_termination ${jsonEncode(previous)}',
        );
      }

      for (final String line in _buffered) {
        _writeThrough(line);
      }
      _buffered.clear();

      _armed = false;
      _armSession();
    } on Object catch (_) {
      // Swallowed, like every other failure in this file.
    }
  }

  /// 13 §7.3: the lock is **rewritten, not deleted**. Its contents — the free
  /// bytes and the last event at the moment of the pause — are what make the
  /// next report useful; an absent file says only *"something happened"*.
  void markCleanPause() {
    _writeLock(clean: true);
    _armed = false;
  }

  void _armIfNeeded() {
    if (_armed || _dir == null) {
      return;
    }
    _armSession();
  }

  void _armSession() {
    _writeLock(clean: false);
    _armed = true;
  }

  void _writeLock({required bool clean}) {
    if (_dir == null) {
      return;
    }
    try {
      // EXACTLY THE SIX FIELDS decision #124 allows, and no seventh. A seventh
      // key is how a tag gets into a file the shepherd may hand to somebody.
      _lockFile.writeAsStringSync(
        jsonEncode(<String, Object?>{
          // appNow(), never the platform clock directly — that ban applies to
          // the log too, and three research notes wrote it wrongly in this exact
          // snippet. `.utc` is what makes the timestamp unambiguous on the one
          // night of the year when a local hour happens twice.
          'startedAt': appNow().utc.toIso8601String(),
          'appVersion': kAppVersion,
          'build': kAppBuild,
          'lastEvent': _lastEvent,
          'freeBytes': _freeBytes(),
          'clean': clean,
        }),
        flush: true,
      );
    } on Object catch (_) {
      // Swallowed.
    }
  }

  Map<String, Object?>? _readLockIn(Directory dir) {
    try {
      final File lock = File('${dir.path}/$lockName');
      if (!lock.existsSync()) {
        return null;
      }
      final Object? decoded = jsonDecode(lock.readAsStringSync());
      return decoded is Map<String, Object?> ? decoded : null;
    } on Object catch (_) {
      return null;
    }
  }

  /// Best effort. `0` when it cannot be read: a lock that failed to write
  /// because it could not stat the volume would defeat its own purpose.
  int _freeBytes() {
    try {
      return _dir!.statSync().size;
    } on Object catch (_) {
      return 0;
    }
  }

  /// Test seam. The singleton outlives every test otherwise, and a log still
  /// attached to a deleted temporary directory fails the next case for the wrong
  /// reason.
  @visibleForTesting
  void resetForTest() {
    _buffered.clear();
    _dir = null;
    _lastEvent = '';
    _armed = false;
  }
}

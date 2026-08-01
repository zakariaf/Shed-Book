// lib/core/log/local_log.dart — the minimum surface main() requires.
//
// T09 adds record(), attachTo(Directory), markCleanPause(), redaction, the
// 256 KB rotation and session.lock. See 13 §7 and §8.
import 'package:flutter/foundation.dart';

/// The diagnostics log. **There is no telemetry and no analytics** (#123): this
/// buffer never leaves the phone unless the shepherd deliberately saves a copy
/// from Settings ▸ Diagnostics.
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

  /// Bounded, and that bound is why writing to disk is not attempted yet:
  /// `01 §5.5` — the log directory is unknown until `path_provider` resolves,
  /// which happens *after* the first frame. An unbounded buffer waiting for a
  /// directory is a leak; a bounded one is a ring.
  static const int capacity = 200;

  final List<String> _entries = <String>[];

  /// A copy, so a caller cannot mutate the buffer it is reading.
  List<String> get entries => List<String>.unmodifiable(_entries);

  /// **`error.toString()` is never written here.** 13 §8.4: an exception's text
  /// embeds the failing SQL, and the failing SQL embeds the shepherd's tags,
  /// note text and batch numbers. T09 adds the redaction that makes writing more
  /// than the type safe; until then the type is all that is written.
  void write(String event, Object error, StackTrace stack) =>
      _append('$event: ${error.runtimeType}');

  void flutterError(FlutterErrorDetails details) =>
      _append('flutter: ${details.exception.runtimeType}');

  void _append(String line) {
    _entries.add(line);
    if (_entries.length > capacity) {
      _entries.removeAt(0);
    }
  }
}

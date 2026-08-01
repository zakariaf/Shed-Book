// lib/main.dart — twenty lines, and nothing awaited.
//
// NOTHING IS AWAITED HERE (#21). An `await` before `runApp` is a frame the
// shepherd spends looking at the platform's launch colour, and every candidate
// for it — opening the database, resolving a directory, reading settings —
// belongs after the first frame. `01 §5.5`.
//
// There is no runZonedGuarded (#14): `PlatformDispatcher.instance.onError`
// supersedes it, and a zone/binding mismatch is a documented footgun
// (flutter#94123).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/app.dart';
import 'package:shed_book/core/log/local_log.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Framework errors: build, layout, paint.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details); // keeps the console output in debug
    LocalLog.instance.flutterError(details);
  };

  // 2. Everything outside the Flutter call stack: async gaps, platform channels.
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    LocalLog.instance.write('uncaught', error, stack);
    // HANDLED — do not kill the app. Returning false lets the process die with a
    // lamb half-recorded; the record is already committed and the shepherd needs
    // the screen back, not a crash.
    return true;
  };

  // 3. ErrorWidget.builder — N11-T04, with the panel it renders.

  runApp(const ProviderScope(child: ShedBookApp()));
}

// Reference copy of `lib/main.dart`. The canonical text is
// docs/engineering/01-architecture.md §6.1. Copy the ORDER and the prohibitions;
// do NOT copy these comments — see the last note at the bottom of this file.
//
// Twenty lines of body. No `async`, no `overrides`, no early return, and nothing
// suspended on a future. Every annotation below says what suspending there costs.

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/log/local_log.dart';
import 'core/ui/night_error_panel.dart';

// Deliberately absent, and rule `layer.root` enforces it: `lib/core/db/`,
// `package:drift/*`, `package:sqlite3*`. `main.dart` never names the database
// type, so it structurally cannot open one. `purchaseServiceProvider` is absent
// too (`launch.store_call`): the first frame is entitlement-agnostic.

void main() {
  // Explicit only so the two handlers below bind against a live binding —
  // `runApp()` calls it internally anyway. Nothing may suspend above this line;
  // this is where somebody eventually writes "because the binding needed it".
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Framework errors: build, layout, paint. Installed FIRST, before anything
  //    in this function can throw. `presentError` keeps the debug console honest.
  //    The body must not throw: exceptions from the handler itself are not
  //    caught (13 §8.2), so anything fragile inside goes in a bare `catch (_)`.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    LocalLog.instance.flutterError(details);
  };

  // 2. Everything outside the Flutter call stack: async gaps, platform channels.
  //    `true` means handled. `false` forwards to a platform fallback that on some
  //    platforms terminates the process — at 3am the committed data outranks the
  //    process. No `runZonedGuarded`: this supersedes it, and a zone/binding
  //    mismatch is a documented footgun (flutter#94123).
  PlatformDispatcher.instance.onError = (error, stack) {
    LocalLog.instance.write('uncaught', error, stack);
    return true;
  };

  // 3. What a broken subtree renders as. The Flutter default is a red-on-yellow
  //    block, which under a head torch is blinding. Set once, here; reassigning a
  //    global during layout races whatever is currently rendering.
  ErrorWidget.builder = (details) => const NightErrorPanel();

  // No `overrides:`. The database is not constructed here and is never injected
  // with `overrideWithValue` — tests override `databaseProvider` in their own
  // scope. No `retry:`: that parameter is Riverpod 3 and will not compile on
  // 2.6.1. The DB open is kicked post-frame from `lib/app.dart`, not from here.
  runApp(const ProviderScope(child: ShedBookApp()));
}

// Nothing above may be suspended on a future, and the diagnostics log is why it
// still works: `LocalLog` buffers in memory until `attachTo(directory)` runs on
// the post-frame path, because `path_provider` has not resolved yet.
//
// LAST NOTE, and it bites: rule `main.no_await` is a plain substring match for
// the five letters a-w-a-i-t followed by a space, anywhere in `lib/main.dart` —
// including inside a comment. Paste these annotations into the real file and the
// gate fails on prose. Keep the code, drop the commentary.

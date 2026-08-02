// lib/app.dart — ShedBookApp.
// A DEV dependency imported from lib/, which trips
// depend_on_referenced_packages and reads as a mistake. It is not: #100 puts the
// wrapper behind kDebugMode, which is a compile-time constant, so the release
// tree never references the package and it never ships. pubspec.yaml's own
// comment on this line says the same. Ignored here, scoped to the import, rather
// than promoted to a real dependency — promoting it would put it in the release
// dependency graph, which is the thing being avoided.
// ignore: depend_on_referenced_packages
import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/time/ticker.dart';
import 'package:shed_book/core/ui/theme.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/l10n/app_localizations.dart';

/// Whether the debug accessibility checker wraps the tree (#100).
///
/// Defaults to [kDebugMode], so **every build a human runs is unchanged** — the
/// checker is present in debug and compiled out of release exactly as decision
/// #100 requires.
///
/// It is a variable rather than a constant for one reason, and it is an upstream
/// defect rather than a preference. **MEASURED 2026-08-01: `accessibility_tools`
/// 2.8.0 throws during widget-tree finalisation on Flutter 3.44.8** — *"Looking
/// up a deactivated widget's ancestor is unsafe"* — so every widget test that
/// pumps [ShedBookApp] fails on tear-down rather than on its claim. Isolated to
/// the package: `AccessibilityTools(child: MaterialApp(...))` alone reproduces
/// it with no Riverpod and no app code, and unmounting first does not help.
///
/// The three alternatives were worse: amending decision #100 to drop the package
/// removes the only thing standing between a debug build and unlabelled tap
/// targets; changing its version edits decision-record §5, the single source of
/// a version number, to route around a bug; and leaving it wired would mean
/// `app.dart` has no widget test at all.
///
/// **Tests set this false; nothing else may.** `pumpApp` (N12-T05) is where that
/// belongs once it exists.
@visibleForTesting
bool debugShowAccessibilityTools = kDebugMode;

/// When a resumed app has been away long enough that the shepherd has moved on.
///
/// **Pure — no Riverpod, no `BuildContext`** — so it is a unit test rather than a
/// widget test. The parameters are [Instant] and not `DateTime`, because the
/// only wall-clock reader in the app is `appNow()` and it returns an `Instant`
/// (R23).
///
/// It measures **absolute** time, and that is the whole reason it takes
/// `Instant`. A civil-time implementation returns a *negative* duration across
/// the clocks-back hour — the wall clock reads earlier while real minutes have
/// passed — and silently keeps a stale selection through the one hour of the
/// year that happens twice, in late October, six weeks before lambing.
class ResumePolicy {
  static const Duration staleAfter = Duration(minutes: 2);

  static bool shouldClearSelection(Instant hiddenAt, Instant resumedAt) =>
      resumedAt.difference(hiddenAt) >= staleAfter;
}

/// `ConsumerStatefulWidget`, never `ConsumerWidget` (R34): it owns a
/// `WidgetsBindingObserver` and a post-frame callback, and neither has anywhere
/// to live on a stateless one.
class ShedBookApp extends ConsumerStatefulWidget {
  const ShedBookApp({super.key});

  @override
  ConsumerState<ShedBookApp> createState() => _ShedBookAppState();
}

class _ShedBookAppState extends ConsumerState<ShedBookApp> with WidgetsBindingObserver {
  Instant? _hiddenAt;

  /// Cleared when a resume is stale. N13 reads it; here it exists so the
  /// lifecycle wiring has an **observable effect** — without one, nothing proves
  /// `addObserver` was ever called.
  bool selectionCleared = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // THE BOOT KICK. The database opens AFTER the first frame — never before,
    // and never inside main(). `.ignore()` because nothing here awaits it: the
    // screens watch the provider, and a failure surfaces through `AsyncValue`
    // rather than as an unhandled future.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      ref.read(databaseProvider.future).ignore();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
        _hiddenAt = appNow();
      case AppLifecycleState.resumed:
        final Instant? hidden = _hiddenAt;
        if (hidden != null && ResumePolicy.shouldClearSelection(hidden, appNow())) {
          setState(() => selectionCleared = true);
        }
        // Elapsed times are stale by however long the app was away, and twenty
        // minutes of "penned 2h" is a lie a shepherd acts on.
        //
        // ONE OF THE TWO ARCHITECTED INVALIDATES IN THE WHOLE APP (02 §4.1); the
        // other is `databaseProvider` at restore step 14 (04 §7). Neither has a
        // drift stream behind it, which is exactly what the ban is scoped to.
        // The `stream.invalidate` rule was narrowed on 2026-08-02 to fire on
        // every other argument, so this line is legible to the gate rather than
        // excused by it — and the allowlist still has four entries.
        ref.invalidate(minuteTickProvider);
        _hiddenAt = null;
      // TODO(N12-T01): release the wakelock on `inactive`, not only on `hidden`
      // (decision #79). `wakelockProvider` does not exist yet, and a test
      // asserting nothing is worse than a documented gap — so the obligation is
      // named here and in N11's pull request rather than half-wired.
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ShedThemeSet t = buildShedThemeSet(ShedPaletteId.night);

    final Widget app = MaterialApp(
      // A product name, never localised.
      title: 'Shed Book',

      // ALL FOUR THEME SLOTS, so no platform event can select light.
      theme: t.theme,
      darkTheme: t.theme,
      highContrastTheme: t.highContrast,
      highContrastDarkTheme: t.highContrast,
      themeMode: ThemeMode.dark,
      color: t.theme.scaffoldBackgroundColor,
      themeAnimationDuration: Duration.zero,

      localizationsDelegates: AppLocalizations.localizationsDelegates,

      // `en` FIRST, and the order is the whole point: putting `en_GB` first
      // gives EVERY English speaker on earth British formats. First match wins,
      // so a US device resolves to `en` and only a GB device reaches `en_GB`.
      supportedLocales: const <Locale>[Locale('en'), Locale('en', 'GB'), Locale('en', 'IE')],

      home: const Scaffold(body: SizedBox.expand()),
    );

    // Debug only (#100). See [debugShowAccessibilityTools] for why this reads a
    // variable that defaults to kDebugMode rather than the constant directly —
    // and note the release build is unaffected either way, because the default
    // IS the constant.
    return debugShowAccessibilityTools ? AccessibilityTools(child: app) : app;
  }
}

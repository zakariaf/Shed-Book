# 08 — Startup, Performance, Crash Safety and Diagnostics

**Topic owner:** Shed Book (offline-only lambing recorder, iOS + Android)
**Toolchain researched against:** Flutter 3.44.x stable, Dart 3.12.x, DevTools 2.57.0, Xcode 26.6, macOS arm64
**Researched:** 2026-07-27. Every version number below was read off a live pub.dev page on that date — re-verify before you `pub add` anything, and never trust a version you remember.

Headline promises this document has to make true:

- *"Median time from unlock to a saved lambing event is under 15 seconds."* (spec §15)
- *"Assume the phone dies. Every write is committed immediately. There is no draft state to lose."* (spec §5)
- *"No white flash on launch."* (spec §5)
- *"The data is nobody else's business."* (spec §4.5) — which disqualifies every mainstream crash reporter.

---

## Bottom line

| # | Decision | Confidence |
|---|---|---|
| 1 | **Nothing async runs before `runApp()`.** `main()` = `ensureInitialized` → install error handlers → `runApp()`. DB open, migration, timezone DB, notification plugin, locale, `path_provider` all happen *after* the first frame, inside the widget tree. | high |
| 2 | **Do not hold the native splash open** (`deferFirstFrame` / `flutter_native_splash.preserve`). Paint the real dark Quick Entry shell immediately; the giant keypad needs zero data. Recents strip and pen list fill in ~100–300 ms later. | high |
| 3 | **Cold-start budget: first Flutter frame ≤ 400 ms after `main()` on the oldest target device; interactive keypad at the first frame.** Measure with `flutter run --profile --trace-startup`; the numbers land in `build/start_up_info.json`. | high |
| 4 | **Always resume to Quick Entry with nothing selected if backgrounded > ~2 minutes.** Restoring a stale selected ewe at 3am is a data-integrity bug, not a convenience. No `RestorationMixin`, no `restorationScopeId`. The database *is* the restored state. | high |
| 5 | **`PRAGMA journal_mode = WAL` + `PRAGMA synchronous = FULL`.** The popular Flutter/drift advice is WAL + `NORMAL`; that is wrong here. `NORMAL` in WAL explicitly loses durability on power loss, and "the phone dies" is the stated threat model. One extra fsync per commit is free at ~10 writes/minute. | high |
| 6 | **Commit the event row *before* the media.** Tiny row first (always fits, always fast), photo/voice written after and attached by a second commit. Survives disk-full and battery-death with the record intact and only the photo missing. | high |
| 7 | **The flock lives in memory; the keypad filter is synchronous.** 400 ewes is ~100 KB. A SQL round-trip per keystroke through drift's background isolate lands one or two frames late. In-memory filtering updates the digits and the list in the *same* frame. This contradicts the common "debounce + query" advice, and the contradiction is the point. | high |
| 8 | **Debounced FTS5 SQL for note search only** (spec §7.7, unbounded growth), 200 ms debounce, off the keypad path, on its own screen. | medium |
| 9 | **Impeller is not a decision — it is the only renderer on iOS and the default on Android API 29+.** This app has no custom shaders, no blurs, no `saveLayer`-heavy chrome. Shader-compilation jank is a non-issue. Do not opt out. | high |
| 10 | **No Sentry, no Crashlytics, no analytics of any kind.** `FlutterError.onError` + `PlatformDispatcher.instance.onError` → rolling local log file → Settings ▸ Diagnostics ▸ Export via share sheet. `runZonedGuarded` is **not** needed and is actively harmful (zone-mismatch footgun). | high |
| 11 | **Detect crashes the Dart handlers can't see with a "clean shutdown" marker.** Set a flag at launch, clear it on `AppLifecycleState.hidden`. Flag still set next launch ⇒ previous session died (native crash, OOM kill, battery). | high |
| 12 | **Off-isolate: only PDF generation and image downscaling.** CSV/JSON at this data volume are milliseconds. A drift connection *cannot* cross an isolate boundary — use `computeWithDatabase` / `serializableConnection()`. | high |
| 13 | **`wakelock_plus` behind an explicit, session-scoped, default-OFF "Keep screen on" toggle** that auto-expires when the app backgrounds. Screen-on is the dominant battery cost and the shed is cold. | high |
| 14 | **CI gates app *size*, not app *speed*.** Profile mode is disabled on emulators, so any CI perf number from a hosted runner is noise. Startup and frame timings are measured by hand on two real devices per release and committed to `docs/perf/measurements.md`. | medium |
| 15 | **`sqlite3_flutter_libs` is discontinued (0.6.0+eol) and does nothing.** Depend on `sqlite3: ^3.x`, which bundles SQLite via Dart build hooks. Do not copy a 2024-era drift setup. | high |

---

## 0. Toolchain and package facts verified 2026-07-27

Read off live pages. Anything marked ⚠️ is a trap that a from-memory setup will fall into.

| Package | Version | Published | Publisher | Verdict |
|---|---|---|---|---|
| `drift` | 2.34.2 | ~12 days ago | simonbinder.eu (verified) | adopt |
| `drift_dev` | 2.34.5 | recent | simonbinder.eu | adopt (dev dep) |
| `drift_flutter` | 0.3.1 | ~16 days ago | simonbinder.eu | adopt |
| `sqlite3` | 3.5.0 | ~8 days ago | simonbinder.eu | adopt |
| ⚠️ `sqlite3_flutter_libs` | **0.6.0+eol — DISCONTINUED** | ~5 months ago | simonbinder.eu | **do not add** |
| `path_provider` | 2.1.6 | ~41 days ago | flutter.dev (verified) | adopt |
| `wakelock_plus` | 1.7.0 | ~5 days ago | fluttercommunity.dev | adopt |
| `share_plus` | 13.3.0 | ~3 days ago | fluttercommunity.dev | adopt |
| `pdf` | 3.13.0 | ~40 days ago | nfet.net (verified) | adopt |
| `printing` | 5.15.0 | ~40 days ago | nfet.net (verified) | adopt-with-care (see §5.2) |
| `flutter_image_compress` | 2.5.1 | ~44 hours ago | fluttercandies.com | adopt |
| `logging` | 1.3.0 | ~21 months ago | dart.dev (verified) | adopt (stable, not stale) |
| `device_info_plus` | 13.2.0 | ~30 days ago | fluttercommunity.dev | adopt |
| `flutter_native_splash` | 2.4.8 | ~58 days ago | jonhanson.net (verified) | adopt-with-care (§1.4) |
| ⚠️ `disk_space_plus` | 0.2.6 | ~13 months ago | **unverified uploader** | avoid — see §9.3 |

### 0.1 The `sqlite3_flutter_libs` trap

`sqlite3_flutter_libs` now publishes as `0.6.0+eol`, is marked **discontinued** on pub.dev, and its own page says: *"Not used anymore, update to version 3.x of package:sqlite3 instead"* and *"Starting from version 0.6.0, this package no longer does anything."*
([pub.dev/packages/sqlite3_flutter_libs](https://pub.dev/packages/sqlite3_flutter_libs))

The migration guide is explicit:

> 1. If you depend on `sqlite3_flutter_libs`, stop doing that
> 2. If you depend on `sqlcipher_flutter_libs`, stop doing that and read encryption
> 3. Upgrade to `sqlite3: ^3.0.0`
> 4. Update the `sqlite3.wasm` file from latest releases
> 5. Remove any `open.overrideFor` customization code and calls to `applyWorkaroundToOpenSqlite3OnOldAndroidVersions`

([UPGRADING_TO_V3.md](https://github.com/simolus3/sqlite3.dart/blob/main/UPGRADING_TO_V3.md))

`sqlite3` 3.x *"relies on hooks to automatically bundle a pre-compiled version of SQLite with your application"* — Dart build hooks, which are stable as of Dart 3.10 and need no `--enable-experiment` flag on 3.12 ([dart.dev/tools/hooks](https://dart.dev/tools/hooks)). Drift migrated at **2.32.0**: *"Migrate to version 3.x of the `sqlite3` package"* ([drift changelog](https://pub.dev/packages/drift/changelog)).

Bundled SQLite versions from the `sqlite3` changelog: 3.1.7 → SQLite 3.52.0, 3.3.2 → 3.53.1, 3.4.0 → 3.53.3. So on `sqlite3: ^3.5.0` you are on SQLite 3.53.x or later — WAL, FTS5, `PRAGMA optimize` and `VACUUM INTO` are all long-since available.

⚠️ **Caveat I could not resolve:** the pub.dev dependency list for `drift_flutter 0.3.1` still shows `sqlite3_flutter_libs ^0.6.0+eol` as a transitive dependency, even though its changelog says 0.3.0 moved to sqlite3 3.x. It resolves to the no-op EOL shim, which is harmless, but **do not add it to your own `pubspec.yaml`**. Run `flutter pub deps` after setup and confirm you see `sqlite3 3.x` in the tree.

⚠️ **Offline note on build hooks:** the hooks download pre-built SQLite binaries from GitHub releases *at build time*. That is a **build-machine** network path, not a runtime one — the shipped app opens no socket. But it does mean your build is not hermetic. Vendor the pub cache or pin an offline mirror if you care about reproducing a 2029 build.

### 0.2 Dart version discrepancy — flagged, not resolved

The Flutter 3.44.0 release-notes page contains a PR entry reading *"Bumped to Dart 3.10"*, while secondary coverage of the 3.44 launch consistently pairs it with Dart 3.12. The brief for this project states Dart 3.12.2. **Resolve this locally with `flutter --version`** rather than trusting either source; nothing in this document depends on the difference.
([release notes 3.44.0](https://docs.flutter.dev/release/release-notes/release-notes-3.44.0))

---

## 1. Cold start

### 1.1 What actually costs time

The phases, in order, on a cold launch:

| Phase | Who owns it | Typical cost | Can you shrink it? |
|---|---|---|---|
| Process fork + `zygote` (Android) / `dyld` + runtime init (iOS) | OS | ~50–150 ms | Barely. Fewer native libs helps a little. |
| Flutter engine init (`FlutterEngineMainEnter`) | engine | ~30–80 ms | No. |
| Dart VM start + AOT snapshot load | engine | ~30–100 ms, scales with code size | Yes — smaller app, fewer packages. |
| Plugin registration (`GeneratedPluginRegistrant`) | your `pubspec` | ~1–10 ms **per plugin**, on the platform thread | **Yes. This is the one you control.** |
| `main()` → `runApp()` | you | should be **< 5 ms** | Yes, ruthlessly. |
| First frame build/layout/paint (`Widgets built first useful frame`) | you | ~20–80 ms | Yes — keep the first route shallow. |
| First frame raster (`Rasterized first useful frame`) | engine | ~10–40 ms | Yes — no blurs, no `saveLayer` on route 1. |
| **DB open + migration check** | you | **0 ms if deferred**, 20–150 ms if not | **Yes — defer it.** |

The authoritative measurement is `flutter run --profile --trace-startup`, which writes `build/start_up_info.json` and `build/start_up_timeline.json`. The JSON keys are, verbatim from `flutter_tools/lib/src/tracing.dart`:

- `engineEnterTimestampMicros`
- `timeToFrameworkInitMicros`
- `timeToFirstFrameMicros`
- `timeToFirstFrameRasterizedMicros`
- `timeAfterFrameworkInitMicros`

backed by the timeline events `FlutterEngineMainEnter`, `Framework initialization`, `Widgets built first useful frame`, `Rasterized first useful frame`.
([flutter_tools/tracing.dart](https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_tools/lib/src/tracing.dart))

### 1.2 Realistic numbers, and how honest to be about them

**I did not measure on device in this session.** Do not put my numbers in a spec sheet. What I *can* give you are the authoritative outer bounds and a budget derived from them.

**Platform ceilings (primary sources):**

- **Android vitals** treats startup as *excessive* at: cold **≥ 5 s**, warm **≥ 2 s**, hot **≥ 1.5 s**. That is the "your app is bad" line, not a target. Time to Initial Display (TTID) is reported by logcat as `ActivityManager: Displayed com.example/.MainActivity: +3s534ms` and can be pulled with `adb shell am start -S -W ...`.
  ([developer.android.com — App startup time](https://developer.android.com/topic/performance/vitals/launch-time))
- **Apple's target** is far tighter: render the first frame within **400 ms**, so pixels appear during the launch animation and the app is interactive when the animation ends. iOS spends ~100 ms on system-side work, leaving ~300 ms for you. *(This is quoted from a search-result summary of [Reducing your app's launch time](https://developer.apple.com/documentation/xcode/reducing-your-app-s-launch-time); the direct WebFetch of that page returned no body twice, so treat the exact wording as second-hand while treating the 400 ms figure as Apple's published goal.)*

**Budget for Shed Book** (targets, to be replaced with measured numbers in `docs/perf/measurements.md`):

| Device class | Tap → first Flutter frame | Tap → keypad accepts a digit |
|---|---|---|
| iPhone SE (2020) / iPhone 11, iOS 26 | ≤ 700 ms | same frame |
| Mid-range Android, API 33–36, 4 GB RAM (Pixel 6a / Galaxy A5x class) | ≤ 900 ms | same frame |
| Low-end Android, API 29–30, 3 GB RAM, no Vulkan | ≤ 1600 ms | same frame |

The second column is the one that matters. **The 15-second budget is dominated by the human, not by the machine.** Even a 1.6 s launch spends 11 % of the budget. What kills you is not launch latency — it is a spinner that makes the shepherd wait before they can start typing. Hence decision #2.

### 1.3 What must NOT happen before the first frame

Forbidden in `main()` before `runApp()`:

- `await getApplicationDocumentsDirectory()` / any `path_provider` call — platform channel round trip.
- Opening the drift database, running `MigrationStrategy`, or `beforeOpen`.
- `flutter_local_notifications` initialisation, `tz.initializeTimeZones()` (the IANA database parse is measurably expensive), permission checks.
- Loading `intl` message catalogs or `rootBundle` assets.
- Reading `SharedPreferences` / settings.
- `device_info_plus`, `package_info_plus`.
- Anything that can throw. An exception before `runApp()` is a black screen with no error UI.

`main()` should read as a hard rule:

```dart
// lib/main.dart — nothing here may await.
void main() {
  // 1. Binding first: everything below needs it, and it is synchronous.
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // 2. Error handlers BEFORE any other code can throw. See §7.
  Diagnostics.installSync(binding);

  // 3. Paint. Immediately.
  runApp(const ProviderScope(child: ShedBookApp()));
}
```

`WidgetsFlutterBinding.ensureInitialized()` *"returns an instance of the binding that implements WidgetsBinding. If no binding exists yet, it creates and initializes"* one ([api.flutter.dev](https://api.flutter.dev/flutter/widgets/WidgetsFlutterBinding-class.html)). It is synchronous and cheap.

### 1.4 Deferring DB / notifications / locale without a blank screen

The trick is that **the 3am screen is renderable with no data at all.** Spec §7.1: giant numeric keypad, recents strip, "in the pens" list, event buttons. Only two of those need the database, and both degrade gracefully to an empty row of the same height.

```dart
// The first route paints with zero I/O. Digits are static widgets.
class QuickEntryScreen extends ConsumerWidget {
  const QuickEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AsyncValue: `loading` renders a fixed-height placeholder in the SAME
    // dark colour, so there is no layout shift and no spinner.
    final recents = ref.watch(recentAnimalsProvider);

    return Scaffold(
      backgroundColor: ShedColors.background, // identical to the native splash
      body: Column(
        children: [
          SizedBox(
            height: 96, // reserved whether or not data has arrived
            child: recents.maybeWhen(
              data: (list) => RecentsStrip(list),
              orElse: () => const SizedBox.shrink(), // not a spinner
            ),
          ),
          const Expanded(child: TagKeypad()),   // usable at frame 1
          const EventButtonRow(),               // usable at frame 1
        ],
      ),
    );
  }
}
```

Deferred initialisation runs off the first post-frame callback, so it cannot delay frame 1:

```dart
class _BootstrapState extends ConsumerState<Bootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fire-and-forget; each stage reports failure to Diagnostics, never throws.
      unawaited(ref.read(deferredBootProvider.future));
    });
  }
}

// Ordered by how soon the 3am user needs it.
final deferredBootProvider = FutureProvider<void>((ref) async {
  await ref.read(databaseProvider.future);      // ~20–150 ms, fills recents/pens
  await ref.read(settingsProvider.future);      // theme, units, terminology
  // Everything below is not needed to record an event. Yield first.
  await Future<void>.delayed(Duration.zero);
  await ref.read(notificationServiceProvider.future); // tz db + plugin init
});
```

`SchedulerBinding.instance.scheduleTask` is available for genuinely low-priority work — but note the doc's constraint: *"Tasks should be short (as in, up to a millisecond), so as to not cause the regular frame callbacks to get delayed"* ([api.flutter.dev](https://api.flutter.dev/flutter/scheduler/SchedulerBinding/scheduleTask.html)). Notification-plugin init is far longer than a millisecond, so it belongs in a post-frame future, not a scheduled task.

**Reject `deferFirstFrame`.** The API exists — *"tells the framework to not send the first frames to the engine until there is a corresponding call to `allowFirstFrame`"*, and *"calling this has no effect after the first frame has been sent to the engine"* ([api.flutter.dev](https://api.flutter.dev/flutter/widgets/WidgetsBinding/deferFirstFrame.html)) — and `flutter_native_splash`'s `preserve()`/`remove()` pair wraps it. Both hold a **static image** on screen while you do I/O. For a networked app with a login check that is right. Here it converts a 0 ms wait into a 150 ms wait for no benefit, because the keypad does not need the database. Use `flutter_native_splash` **only** to generate the native splash assets, never its preserve/remove API.

### 1.5 No white flash — the concrete recipe

Three surfaces must be the *same* hex colour, or you get a flash on a dark-adapted eye at 3am:

1. **Android** `windowBackground` / `android:windowSplashScreenBackground`
2. **iOS** `LaunchScreen.storyboard` view background
3. **Flutter** `Scaffold.backgroundColor` of route 1

Android additionally needs the Android-12+ splash exit animation killed, or you get a cross-fade through the system window:

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { view -> view.remove() }
        }
        super.onCreate(savedInstanceState)
    }
}
```

and the theme pair in `styles.xml` plus the `io.flutter.embedding.android.NormalTheme` meta-data, exactly as documented ([Android splash screen](https://docs.flutter.dev/platform-integration/android/splash-screen)). Note both `values/styles.xml` **and** `values-night/styles.xml` must be dark — spec §5 says dark is the default, not a mode.

On iOS the launch storyboard is mandatory for App Store submission ([iOS launch screen](https://docs.flutter.dev/platform-integration/ios/launch-screen)); set its background to the same colour and set `UIUserInterfaceStyle = Dark` in `Info.plist` so a light-mode phone does not flash the light variant.

---

## 2. Warm start and resume — the 20-minute gap

### 2.1 What the OS does to the process

**iOS.** The app moves *active → inactive → background → suspended*. Suspended means *"the app remains in memory"* with all code execution stopped. Nothing is torn down: the Dart heap, the drift isolate, the open SQLite file descriptor, and the page cache all survive. Resume is effectively free. The system terminates a suspended app under **memory pressure** (also background-task timeout, resource violations, reboot) ([About the app launch sequence](https://developer.apple.com/documentation/uikit/about-the-app-launch-sequence)).

**Android.** The process drops to **cached** — *"not currently needed. The system freely kills these when resources are needed elsewhere… Can be killed at any time."* On Android 13+, *"cached process apps may receive limited or no execution time until entering an active lifecycle state."* Critically: *"`onDestroy()` is not guaranteed to be called in the case that a process is killed by the system"* ([Processes and app lifecycle](https://developer.android.com/guide/components/activities/process-lifecycle)).

**What that means in a shed at 3am on a 3 GB phone:** 20 minutes backgrounded with the camera app, a torch app and a browser used in between is a *plausible* kill. Plan for both outcomes.

Flutter surfaces this as `AppLifecycleState`: `detached`, `resumed`, `inactive`, `hidden`, `paused`. The framework *synthesises* `hidden` between `inactive`↔`paused` on iOS and Android so both platforms present the same state machine, and the docs warn that in `inactive` an app *"may be hidden and paused at any time"* ([AppLifecycleState](https://api.flutter.dev/flutter/dart-ui/AppLifecycleState.html)).

**`hidden` is your flush point.** It is the last state you are guaranteed to observe before the OS can stop you.

### 2.2 Does the DB connection survive?

- **Suspended / cached (not killed):** yes. Same process, same fds, same drift isolate. No reopen, no migration check, no cost.
- **Killed:** no. Full cold start, including the migration check. Which is another reason the migration check must not be on the critical path to the first frame.

⚠️ **iOS `0xdead10cc`.** iOS terminates apps that hold a **file lock or SQLite lock while suspended** — the code is literally pronounced "deadlock". Apple's guidance is to release the lock before becoming eligible for suspension, or wrap the work in a background task ([Apple Developer Forums thread 126438](https://developer.apple.com/forums/thread/126438)). Concretely for Shed Book:

- **Never hold a transaction open across an `await` that waits on the user.** No "BEGIN, show a dialog, COMMIT". Every write is a self-contained transaction — which is what spec §5 demands anyway.
- **Do not put the database in an App Group / shared container.** Most reported `0xdead10cc` crashes involve shared containers. The app sandbox is correct and there is no widget or extension in v1.
- On `AppLifecycleState.hidden`, run a `PRAGMA wal_checkpoint(TRUNCATE)` and flush the diagnostics log. Cheap, and leaves no long-lived WAL reader.

### 2.3 What the app owes the user on resume

This is a **safety** question, not a UX question. Spec §12.4: *never silently correct a user's entry*; the corollary is *never silently attribute an entry to the wrong animal*.

The failure mode: at 03:20 the shepherd selects ewe 412 and is interrupted. At 03:41 they reopen the app, the screen shows "412" selected, they tap "Twin" — and ewe 128's lambing is recorded against 412. That is exactly the class of error the product exists to eliminate (spec §2).

**Rule:**

```dart
class ResumePolicy {
  /// Beyond this, the previously selected animal is untrustworthy.
  static const staleAfter = Duration(minutes: 2);

  static bool shouldClearSelection(DateTime hiddenAt, DateTime resumedAt) =>
      resumedAt.difference(hiddenAt) >= staleAfter;
}

class _AppLifecycle extends ConsumerState<AppRoot> with WidgetsBindingObserver {
  DateTime? _hiddenAt;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
        _hiddenAt = DateTime.now();
        ref.read(diagnosticsProvider).flushAndMarkCleanPause();
        unawaited(ref.read(databaseProvider).checkpointTruncate());
      case AppLifecycleState.resumed:
        final at = _hiddenAt;
        if (at != null && ResumePolicy.shouldClearSelection(at, DateTime.now())) {
          ref.read(selectedAnimalProvider.notifier).clear();
          ref.read(routerProvider).goToQuickEntry();
        }
        _hiddenAt = null;
      case _:
        break;
    }
  }
}
```

- **< 2 min:** stay where you are, keep the selected ewe. You put the phone down to grab a towel.
- **≥ 2 min or process death:** land on Quick Entry, nothing selected.

**Nothing is lost by clearing,** because of decision #6 and spec §5: the lambing row is committed on the *first* tap (birth type), and every subsequent field commits on entry. So the in-flight event already exists in the database. Surface it as the first chip in the recents strip labelled *"412 · lambing, 03:20 — continue"*. Resuming is then one tap and is read from durable storage rather than from volatile UI state.

### 2.4 Why `RestorationMixin` is the wrong tool here

Flutter's state restoration serialises registered `RestorableProperty` values into a `RestorationBucket` handed to the platform, so state survives process death ([RestorationMixin](https://api.flutter.dev/flutter/widgets/RestorationMixin-mixin.html)). It is the right answer for an app with genuinely ephemeral UI state worth preserving — a half-filled multi-page form, a scroll offset in a feed.

Shed Book has, by design, **no ephemeral state worth preserving**. Adopting restoration would mean:

- Every entry field becomes a `Restorable*` with a `restorationId`, adding boilerplate to all 12 screens.
- You reintroduce a **draft state** — the exact thing spec §5 says must not exist.
- You risk restoring a stale animal selection, i.e. §2.3's bug, but now across a *reboot*.

**Decision: leave `MaterialApp.restorationScopeId` null.** Cost of state restoration: zero, because we don't use it. The database is the restoration mechanism.

---

## 3. Impeller

### 3.1 Status, verbatim from docs.flutter.dev

> **Android:** "Impeller is **available and enabled by default on Android API 29+**. On devices running lower versions of Android or don't support Vulkan, Impeller falls back to the legacy OpenGL renderer. No action on your part is necessary for this fallback behavior."
>
> **iOS:** "Impeller is the **only supported** rendering engine on iOS with no ability to switch to Skia."
>
> **macOS:** behind a flag; "In a future release, the ability to opt-out of using Impeller will be removed."

([docs.flutter.dev/perf/impeller](https://docs.flutter.dev/perf/impeller))

Opt-out on Android, if you ever need it for a bug bisect:

```bash
flutter run --no-enable-impeller
```

```xml
<!-- android/app/src/main/AndroidManifest.xml, inside <application> -->
<meta-data android:name="io.flutter.embedding.android.EnableImpeller" android:value="false" />
```

### 3.2 Is there still a Skia fallback on Android?

**Ambiguous, and it does not matter for this app.** The docs say "legacy OpenGL renderer" without saying whether that is Skia's GL backend or Impeller's own OpenGL ES backend. The tracking issue *"[Impeller] Switch Android non-Vulkan fallback from Skia OpenGL to Impeller OpenGL"* ([flutter/flutter#158361](https://github.com/flutter/flutter/issues/158361)) is **closed**, which suggests the switch landed, but the docs page had not been reworded as of this research date and no primary source states the Flutter version. Secondary coverage claiming "Skia is stripped out for Android 10+" is a Medium post and is **not** evidence.

Treat it as: *on API < 29 or a Vulkan-less device you get an OpenGL ES path of some description, and it is slower.* Test on one such device (an API-30 budget phone) once, and move on.

### 3.3 Shader compilation jank

Flutter's own page on the subject now reduces to one sentence:

> "Do you see noticeable jank on your mobile app, but only on the first run of an animation? To avoid this, make sure you're using Flutter's default graphic renderer, Impeller."

([docs.flutter.dev/perf/shader](https://docs.flutter.dev/perf/shader))

Impeller precompiles its shader set at engine build time, so there is no runtime shader compilation to jank on. The whole `--bundle-sksl-path` / SkSL warm-up workflow from the Skia era is dead. **Do not implement it.** DevTools still marks shader-compiling frames dark red in the Performance view ([DevTools Performance](https://docs.flutter.dev/tools/devtools/performance)); if you ever see one, you are on the wrong renderer.

### 3.4 Does this app need to care?

**Almost not at all.** Shed Book's rendering is: flat dark rectangles, large text, a handful of icons, one bar chart (§7.8), and photos on the ewe card. There is no blur, no `ShaderMask`, no `ColorFilter`, no hero-heavy navigation, no parallax. `saveLayer` — the expensive primitive that triggers *"an offscreen buffer and GPU render target switches"* ([Performance best practices](https://docs.flutter.dev/perf/best-practices)) — is triggered by `ShaderMask`, `ColorFilter`, `Chip` with partial alpha, and `Text` with an overflow shader. Avoid partially-transparent `Chip`s in the recents strip and you have eliminated the category.

The **one** place to be careful: an optional **red-shift mode** (spec §7.10). The naive implementation is a full-screen `ColorFiltered` or `ShaderMask` overlay — which is a `saveLayer` on *every frame of the whole app*, exactly the thing to avoid. Implement red-shift as a **second `ColorScheme`** (red-on-black tokens) selected by a theme switch. Zero rendering cost, and it looks better.

---

## 4. List and search performance

### 4.1 The honest sizing

| Dataset | Rows at the ceiling of the spec | In-memory footprint |
|---|---|---|
| Ewes, one season | 400 | ~100 KB |
| Ewes, ten seasons | ~4,000 (many retired) | ~1 MB |
| Lambs, one season | ~800 | ~200 KB |
| Treatments, five seasons | ~5,000 | ~1.5 MB |
| Notes (free text + voice transcripts) | **unbounded** | unbounded |

400 ewes is not a data-scale problem. It is smaller than one photo. Any argument about "SQL vs memory" framed as a *scale* question is answering the wrong question.

### 4.2 The real question is latency shape, not throughput

Drift's Flutter default runs the database on a **background isolate**. `driftDatabase(name:)` opens `$name.sqlite` in the application documents directory; `DriftNativeOptions` exposes `shareAcrossIsolates` (default `false`), `isolateSetup`, `setup`, `databaseDirectory`, `databasePath`, `tempDirectoryPath`, `isolateDebugLog` ([DriftNativeOptions](https://pub.dev/documentation/drift_flutter/latest/drift_flutter/DriftNativeOptions-class.html)). Under the hood the recommended native executor is `NativeDatabase.createInBackground` ([drift native platform docs](https://drift.simonbinder.eu/platforms/vm/)).

That is good for not blocking the UI thread, and it has a cost drift states plainly:

> "while using a background isolate can reduce lag on the UI thread, the overall database is going to be slightly slower! There's a overhead involved in sending data between isolates."
> "If you're not running into dropped frames because of drift, using a background isolate is probably not necessary for your app."

([drift Isolates](https://drift.simonbinder.eu/isolates/))

So per keystroke you get: keystroke → UI thread → port send → background isolate → SQLite (µs) → port send back → UI thread → `setState` → next frame. Total maybe 1–3 ms of work, but it is **asynchronous**, so the filtered list lands **one or two frames after the digit**. At 60 Hz that is 16–33 ms of the list visibly trailing the digits.

On a warm phone nobody notices. On a cold, thermally-throttled phone, with a gloved thumb hitting `4-1-2` fast, the list is chasing the keypad. That reads as *lag*, and lag at 3am reads as *broken*.

### 4.3 The call: the flock lives in memory

```dart
/// Loaded once after first frame, invalidated on any write to Ewes.
final flockProvider = FutureProvider<List<EweSummary>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.eweSummaries().get(); // ~400 rows, ~15 ms once
});

/// Pure, synchronous, no I/O. Runs inside build().
final filteredFlockProvider = Provider<List<EweSummary>>((ref) {
  final query = ref.watch(keypadQueryProvider);          // e.g. "12"
  final flock = ref.watch(flockProvider).valueOrNull ?? const [];
  if (query.isEmpty) return flock;
  // Spec §7.1: typing `12` must surface 412, 128, 12 — substring, not prefix.
  final out = <EweSummary>[];
  for (final e in flock) {
    if (e.tag.contains(query)) out.add(e);
  }
  // Exact match first, then shortest tag, then numeric.
  out.sort((a, b) => _rank(a, query).compareTo(_rank(b, query)));
  return out;
});
```

Cost of that loop: a substring scan over short ASCII strings is on the order of 100 ns each, so **400 rows ≈ 40 µs** — 0.25 % of a 16 ms frame. The digit and the list update in the same frame. **No debounce.** Debouncing an operation that costs 40 µs is cargo cult.

**Where in-memory breaks.** At roughly 10,000 rows the scan is ~1 ms; at 50,000 it is ~5 ms and starts eating the frame budget alongside build/layout; past ~100,000 it is over budget on its own. Shed Book's ceiling is 400 ewes per season and ~4,000 lifetime rows. **In-memory does not break for this app, in any plausible ten-season future.** If it ever did, the fix is a precomputed `Map<String, List<int>>` of 2-gram → row indices, still in memory.

**Where SQL wins and must be used:**

- **Note full-text search** (spec §7.7, "Full-text offline search across every note, tag, and treatment"). Unbounded growth, and you want ranking. Use **FTS5** with a `bm25()` ordering, on its own screen, with a **200 ms debounce** and a cancel-previous-query guard.
- **Season summary aggregates** (spec §7.8) — `GROUP BY` in SQL, computed once per screen open, not per frame.
- **Filters over the whole flock** (spec §7.7: barren, not yet lambed, triplet-bearing, currently penned, under treatment). These are cheap in memory too, but they are naturally expressible as SQL and are not on a per-keystroke path.

If you ever *do* need indexed prefix matching in SQL, know the constraint: SQLite can use an index for `LIKE` **only** when the pattern does not begin with a wildcard, and the column collation matches the case sensitivity (`NOCASE` in default mode) ([SQLite query optimizer overview](https://www.sqlite.org/optoverview.html)). `tag LIKE '12%'` is indexable; `tag LIKE '%12%'` — which is what spec §7.1 actually requires — **is a full scan**. Another point for in-memory: the required semantics defeat the index anyway.

### 4.4 Keeping the frame under 16 ms while filtering

Flutter's budget: on 60 Hz, *build in ≤ 8 ms, render in ≤ 8 ms* ([best practices](https://docs.flutter.dev/perf/best-practices)).

- **`ListView.builder`, never the default constructor.** The default *"requires doing work for every child that could possibly be displayed… instead of just those children that are actually visible"* ([ListView](https://api.flutter.dev/flutter/widgets/ListView-class.html)).
- **Set `itemExtent`.** Spec §5 mandates ≥ 60×60 pt targets, so rows are a fixed height anyway (use 88.0 for a two-line ewe row with comfortable hit slop). The docs: specifying `itemExtent` or `prototypeItem` *"is more efficient than letting the children determine their own extent because the scrolling machinery can make use of the foreknowledge of the children's extent to save work."* This also eliminates intrinsic-size passes, which DevTools' **Track layouts** surfaces as `$runtimeType intrinsics`.
- **`const` the row chrome.** Divider, chevron, badge shells.
- **Keep the filtered list short.** After two digits the candidate set is typically < 20 ewes. Do not render 400 rows and scroll; render the matches.
- **Do not animate the list.** No `AnimatedList`, no implicit reorder animation between keystrokes. Cold fingers plus moving targets is a mis-tap generator, and it costs frames.
- **`RepaintBoundary` around the keypad.** The keypad never changes while the list does; isolating it stops the list rebuild from repainting 12 large buttons.

### 4.5 Pen board (spec §7.4)

"Hours since penned" is the only continuously-changing value in the app. Do **not** drive it from an `AnimationController` or a 1 s `Timer` — that is 60 or 1 rebuilds/second of a grid for a value that changes once an hour.

```dart
// Ticks once a minute, only while the Pen Board is mounted and the app is resumed.
final penClockProvider = StreamProvider.autoDispose<DateTime>((ref) {
  return Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});
```

Cancel it on `AppLifecycleState.hidden`. A per-minute rebuild of a 12-cell grid is invisible; a per-second one is measurable battery drain over a six-hour night.

---

## 5. Off-isolate work

### 5.1 What can and cannot cross an isolate boundary

Isolates do not share memory; messages are copied (except `Isolate.run`'s result, which is sent via `exit` *"without copying"*). Unsendable types include *"objects with native resources (e.g. `Socket`), `ReceivePort`, `DynamicLibrary`, pointers, classes marked with `@pragma('vm:isolate-unsendable')`"* ([dart.dev/language/concurrency](https://dart.dev/language/concurrency)).

`compute(fun, message)` on native platforms is documented as identical to `await Isolate.run(() => fun(message))` ([compute](https://api.flutter.dev/flutter/foundation/compute.html)). Both warn about closures: *"If computation is a closure, it may implicitly send unexpected state to the isolate… This can cause performance degradation, increased memory usage, or runtime failures if the captured state includes non-sendable objects"* ([Isolate.run](https://api.dart.dev/stable/dart-isolate/Isolate/run.html)). **Always pass a top-level or static function plus an explicit data payload.**

### 5.2 Can a drift connection cross? No — and here is what to use instead

Drift is unambiguous: a database instance holds streams, futures and other mutable state, and sending it raises *"sending an invalid object"*. Three sanctioned patterns ([drift Isolates](https://drift.simonbinder.eu/isolates/)):

**(a) `computeWithDatabase` — for a short-lived job.** Drift *"sets up a pair of SendPort/ReceivePorts over which database calls are relayed, spawns a new isolate with `Isolate.run`, creates a raw database connection based on those ports, invokes the `connect` callback to create a second instance of your database class"*, runs the computation, and tears down.

```dart
await database.computeWithDatabase(
  computation: (db) async {
    final rows = await db.allLambingsForSeason(seasonId).get();
    // build the PDF here, on the background isolate
  },
  connect: (connection) => ShedDatabase(connection),
);
```

**(b) `serializableConnection()` — when you want to own the isolate.**

```dart
final connection = await database.serializableConnection();
final bytes = await Isolate.run(() async {
  final db = ShedDatabase(await connection.connect());
  try {
    return buildFlockBookPdf(await db.allLambingsForSeason(seasonId).get());
  } finally {
    await db.close();
  }
});
```

**(c) `DriftIsolate.spawn()` + `connect(singleClientMode: true)`** — for a long-lived second isolate. Not needed here.

⚠️ **Platform channels on a background isolate.** Plugins do not work on a non-root isolate until you initialise its messenger. Drift's own sample does this inside the spawned isolate:

```dart
final token = RootIsolateToken.instance!;
await DriftIsolate.spawn(() {
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  return LazyDatabase(() async { /* ... */ });
});
```

Same requirement applies to `flutter_image_compress`, whose docs say *"Platform channels don't work in a background isolate unless you initialize its binary messenger first"* — omit it and you get `UnimplementedError` ([flutter_image_compress](https://pub.dev/packages/flutter_image_compress)).

### 5.3 Job-by-job

| Job | Volume at ten seasons | Cost | Isolate? |
|---|---|---|---|
| **CSV, one row per lamb** | ~8,000 rows | `StringBuffer`, a few ms | **No.** Isolate overhead exceeds the work. |
| **CSV, one row per treatment** | ~5,000 rows | few ms | No. |
| **Full JSON backup** | ~20,000 rows total | 20–80 ms for query + encode | **Borderline.** Do it on the main isolate but **stream to a file** via `IOSink`, not `jsonEncode` of one giant object — a 5 MB string is a GC event. If measurement shows > 100 ms, move to `computeWithDatabase`. |
| **PDF flock book** | 400 ewes ≈ 30–60 pages | **hundreds of ms to seconds**, plus large `Uint8List` allocation | **Yes. Always.** |
| **Medicine record PDF** | tens of pages | 100s of ms | Yes, same path. |
| **Image downscale** | one photo | 50–400 ms in pure Dart | **Native, not Dart.** See below. |

**PDF specifics.** `pdf` 3.13.0 is pure Dart; `Document.save()` returns a `Uint8List`, which is sendable. Fonts are the trap: `rootBundle.load()` is a platform-channel call, so **load font bytes on the root isolate and pass the `ByteData`/`Uint8List` into the isolate**, or call `BackgroundIsolateBinaryMessenger.ensureInitialized` first. Prefer passing bytes — fewer moving parts.

```dart
// Root isolate: gather everything the PDF needs as plain sendable data.
final fontRegular = (await rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    .buffer.asUint8List();
final payload = FlockBookPayload(
  rows: await db.flockBookRows(seasonId).get(), // plain data classes
  fontRegular: fontRegular,
  footer: 'Shed Book is a notebook, not a regulatory record.', // spec §12.3
);

// Background isolate: no plugins, no channels, no DB.
final Uint8List pdfBytes = await compute(buildFlockBookPdf, payload);

// Root isolate: hand to the share sheet.
await SharePlus.instance.share(ShareParams(
  files: [XFile.fromData(pdfBytes, mimeType: 'application/pdf',
      name: 'shed-book-${season.label}.pdf')],
));
```

⚠️ **`printing` and the offline constraint.** `printing` 5.15.0 is fine on mobile — its Android manifest declares **no permissions at all**, only a `FileProvider` (verified by reading `printing/android/src/main/AndroidManifest.xml`). But its pub page notes that the **web** implementation loads Pdf.js from a CDN. We do not ship web, so this is moot — but it is a good example of a package that is offline-clean on the platforms we ship and not on one we don't. If you only need "save + share", `share_plus` alone is enough and `printing` can be dropped; add `printing` only when the user asks for a real print dialog.

**Image downscaling.** Do **not** use `package:image` in an isolate. `flutter_image_compress` states plainly that it *"compresses images using native code (Kotlin on Android, Objective-C/Swift on Apple platforms)"* because *"Dart-only image libraries exist, but in practice they are too slow for typical compression workloads."* Native compression runs on a platform thread, not the Dart UI isolate, so there is nothing to isolate. Its temp files land in `context.cacheDir` / `NSTemporaryDirectory()` and are OS-managed — but **clean them up yourself**, because Android may or may not.

For *thumbnails* on the ewe card, prefer `dart:ui`'s decoder with a target size, which decodes on the engine's I/O thread:

```dart
Future<ui.Image> thumbnail(Uint8List bytes, {int width = 240}) async {
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: width);
  return (await codec.getNextFrame()).image;
}
```

### 5.4 Keeping the UI alive during an export

The share sheet is the user's mental "done" signal, so what matters is that the app stays *responsive* while the bytes are produced.

- Show a **determinate** progress indicator driven by page count, not a spinner. "Page 12 of 47" tells a shepherd it is working; a spinner tells them nothing.
- Make it **cancellable**: check a flag between pages inside the isolate payload loop and return early. `Isolate.kill` is a blunt instrument that can leave the drift client dangling.
- Do the export from the **Export screen** (§9 screen 11), never as a side effect of the end-of-day prompt. The prompt (spec §7.9) opens the screen; it does not start work.
- Do not `await` the export on the UI thread inside a modal that blocks back navigation. If it takes 8 seconds, the shepherd must be able to leave and go pull a lamb.

---

## 6. Crash safety and data integrity

### 6.1 What SQLite actually guarantees

**Rollback journal (default `journal_mode=DELETE`).** SQLite writes the original page content to a `-journal` file, fsyncs it, then writes the database, fsyncs that, then **deletes the journal — which is the commit point**. Crash before journal fsync ⇒ nothing happened. Crash between ⇒ next open finds a "hot journal" and rolls back. Crash after deletion ⇒ committed. ([SQLite: Atomic Commit](https://www.sqlite.org/atomiccommit.html))

**WAL.** The main database is never touched during a transaction; changes are appended to `-wal` and a commit record is written. Readers do not block writers and vice versa; there is exactly one writer at a time. Checkpointing moves WAL content back into the main file, automatically at ~1000 pages by default. ([SQLite: WAL](https://www.sqlite.org/wal.html))

**The durability line, which most Flutter tutorials get wrong.** From `PRAGMA synchronous`:

| Mode | Rollback journal | **WAL** |
|---|---|---|
| `EXTRA` (3) | ACID | ACID |
| `FULL` (2) | maybe not durable | **ACID** |
| `NORMAL` (1) | maybe not consistent | **"maybe not durable"** |
| `OFF` (0) | not consistent | not consistent |

> "WAL mode is always consistent with synchronous=NORMAL, but WAL mode does lose durability."

([SQLite PRAGMA reference](https://www.sqlite.org/pragma.html))

Read that precisely. `WAL + NORMAL`:

- **survives a process kill** (Android LMK, iOS jetsam, force-quit) — the bytes are in the OS page cache and the kernel writes them out; the dying process is irrelevant;
- **can lose the last committed transactions on power loss / kernel panic / battery death.**

Spec §5 says *"Assume the phone dies."* A flat lithium battery in a 0 °C shed is a power loss, not a process kill. So:

> **`PRAGMA journal_mode = WAL; PRAGMA synchronous = FULL;`**

Cost: one extra fsync per commit, single-digit milliseconds on flash. At the app's write rate (a handful of commits per lambing) it is unmeasurable. This is the single most important line in this document.

### 6.2 The connection setup

```dart
QueryExecutor openShedBookDatabase() {
  return driftDatabase(
    name: 'shed_book',
    native: DriftNativeOptions(
      databaseDirectory: getApplicationSupportDirectory,
      setup: (db) {
        // journal_mode is PERSISTENT — stored in the file header, survives reopen.
        db.execute('PRAGMA journal_mode = WAL;');
        // The rest are PER-CONNECTION and must be re-applied every open.
        db.execute('PRAGMA synchronous = FULL;');      // §6.1 — the phone dies
        db.execute('PRAGMA foreign_keys = ON;');       // OFF by default since 3.6.19
        db.execute('PRAGMA busy_timeout = 5000;');     // no SQLITE_BUSY at 3am
        db.execute('PRAGMA journal_size_limit = 4194304;'); // cap -wal at 4 MB
        db.execute('PRAGMA temp_store = MEMORY;');     // no temp files to fill the disk
      },
    ),
  );
}
```

Scope, from the PRAGMA reference: `journal_mode` is **persistent** (survives close/reopen, stored per-database); `synchronous`, `busy_timeout`, `foreign_keys`, `temp_store`, `wal_autocheckpoint`, `journal_size_limit`, `cache_size` and `mmap_size` are **session-only** and must be set on every connection. Getting this wrong is a silent durability regression: WAL sticks, `synchronous=FULL` does not.

⚠️ Because drift runs the DB on a background isolate, the `setup` callback runs **there**. Do not reference root-isolate globals inside it. Drift warns: *"Dart isolates don't share memory… Initializations like `open.overrideFor` or service locators must run on the background isolate where the database actually opens."*

`PRAGMA optimize` once per session before close is recommended by SQLite for short-lived connections; for a long-lived app connection, run `PRAGMA optimize = 0x10002` at startup (deferred, post-first-frame) and periodically. At 4,000 rows this is a no-op, but it is free and correct.

### 6.3 App-level rules that make "every write commits immediately" true

1. **One user action = one transaction, committed before the UI acknowledges.** The green tick is drawn from the write's completion, not optimistically.
   ```dart
   Future<LambingId> recordBirthType(EweId ewe, BirthType type) async {
     final id = await db.transaction(() async {
       return db.into(db.lambings).insert(LambingsCompanion.insert(
         ewe: ewe,
         datetime: DateTime.now(),
         timestampSource: TimestampSource.autoCaptured, // spec §12.5
         birthType: type,
       ));
     });
     return LambingId(id); // UI updates only after this returns
   }
   ```
2. **Never hold a transaction across an `await` on the user.** No open transaction while a dialog is up. (Also §2.2 — `0xdead10cc`.)
3. **No "Save" button on the entry path.** The row exists from the first tap. Every subsequent field is its own committed `UPDATE`. This is what makes §2.3's aggressive resume-clear safe.
4. **Commit the row before the media.** Photo/voice are attached by a *second* commit after the file lands. Ordering matters (§9.4).
5. **Never mutate a stored timestamp silently.** Store `capturedAt` and `editedAt` separately with a `TimestampSource` enum. Spec §12.5.
6. **Never repair a user's data on read.** Spec §12.4: three lambs against a "twin" is *flagged in the UI*, never corrected in the database. This also means integrity checks belong in the presentation layer, not in a migration.
7. **Migrations are forward-only, additive, and never destructive.** `m.addColumn`, `m.createTable`. Never drop a column with user data. Drift's `beforeOpen` *"will be called whenever the database is opened, regardless of whether a migration actually ran"* ([drift migrations](https://drift.simonbinder.eu/migrations/)) — so keep it near-empty; it is on the cold-start path.

### 6.4 Corruption and I/O failure

Codes you must handle explicitly ([SQLite result codes](https://www.sqlite.org/rescode.html)):

| Code | Cause | Shed Book response |
|---|---|---|
| `SQLITE_FULL` (13) | disk full, incl. temp files on another partition | §9.4 — degrade to text, never lose the entry |
| `SQLITE_BUSY` (5) | another connection holds the write lock | `busy_timeout=5000` absorbs it; if it still fires, retry once then surface |
| `SQLITE_IOERR` (10) | OS-level I/O error, unmounted fs, hardware | log with extended code, tell the user honestly, offer export of what's readable |
| `SQLITE_CORRUPT` (11) / `SQLITE_NOTADB` (26) | damaged file | **do not delete anything** — see below |
| `SQLITE_READONLY` (8) | permissions, `-shm` unwritable | should be impossible in-sandbox; log and surface |

**Corruption policy.** On `SQLITE_CORRUPT` or `SQLITE_NOTADB` at open:

1. **Never delete.** Rename `shed_book.sqlite` (and its `-wal`, `-shm`) to `shed_book.corrupt-<timestamp>.sqlite`.
2. Open a fresh empty database so the app is usable *tonight*.
3. Show a blunt, non-technical screen: *"Some of your records could not be read. The damaged file has been kept. Tap to export it."* The damaged file goes out through the share sheet like any other export.
4. Log the extended result code to Diagnostics.

**The `-wal` / `-shm` rule.** SQLite: *"The WAL file is part of persistent database state. Separating the database from its WAL file can cause data loss or corruption."* Consequence for this app: if you ever add a "copy the raw .sqlite file" feature, it is wrong. The backup format is JSON (spec §7.9). If you need a file-level copy, use `VACUUM INTO 'path'` or checkpoint with `PRAGMA wal_checkpoint(TRUNCATE)` first — never `File.copy` of the main file alone.

**Do not run `PRAGMA integrity_check` at startup.** It is a full-database scan. Put `PRAGMA quick_check` behind a button in Settings ▸ Diagnostics, with a progress indicator.

---

## 7. Crash reporting with no network

### 7.1 Why the standard answer is disqualified

Sentry and Crashlytics both (a) require `android.permission.INTERNET`, (b) transmit device and error data to a third party, (c) add SDK weight and startup work, and (d) for Crashlytics, drag in Firebase and a Google services plugin. Spec §4.3 ("no server means no outage"), §4.5 ("the data is nobody else's business") and §13 ("no sync, no cloud backup of any kind") each independently rule them out. There is no "just crash reports, no PII" configuration that satisfies §4.5, because the fact that a specific device crashed at 03:41 is itself telemetry the user did not consent to.

**Also: verify the permission is actually absent.** Flutter's own templates add `INTERNET` to the **debug and profile** manifests only (the Dart VM service needs it); the release manifest does not have it. Plugins can still merge it in. Add a belt-and-braces removal and a CI check:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          xmlns:tools="http://schemas.android.com/tools">
    <uses-permission android:name="android.permission.INTERNET" tools:node="remove" />
```

```bash
# CI gate — fail the build if any network permission survives the merge.
flutter build apk --release
! grep -qE 'android.permission.(INTERNET|ACCESS_NETWORK_STATE)' \
    build/app/intermediates/merged_manifests/release/AndroidManifest.xml
```

### 7.2 The bootstrap, in order

```dart
// lib/diagnostics/diagnostics.dart
class Diagnostics {
  static late final DiagnosticsLog _log;

  /// Synchronous. Runs before ANY other app code. Must never throw.
  static void installSync(WidgetsBinding binding) {
    _log = DiagnosticsLog(); // lazily resolves its directory; buffers until then

    // 1. Errors the framework catches: build, layout, paint.
    final previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      _log.writeErrorSync('flutter', details.exception, details.stack,
          library: details.library, context: details.context?.toString());
      FlutterError.presentError(details); // keep console output in debug
      previous?.call(details);
    };

    // 2. Errors Flutter does NOT catch: async gaps, platform channels.
    //    Root isolate only — see §7.4.
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _log.writeErrorSync('platform', error, stack);
      return true; // handled: suppress the platform's stderr fallback
    };

    // 3. A build error must not show a red screen at 3am.
    ErrorWidget.builder = (FlutterErrorDetails details) => const ShedErrorTile();

    // 4. Abnormal-termination detection (§7.5).
    _log.openSession();
  }
}
```

This mirrors Flutter's own "handle all types of errors" sample, which sets `FlutterError.onError`, `PlatformDispatcher.instance.onError` and `ErrorWidget.builder` and uses **no `runZonedGuarded`** ([Handling errors in Flutter](https://docs.flutter.dev/testing/errors)).

Semantics worth pinning down:

- `FlutterError.onError` — *"Called whenever the Flutter framework catches an error."* Default is `presentError`. *"Exceptions thrown by the handler itself won't be caught"* and *"setting it to null silently ignores all errors."* Hence: the handler body must be exception-proof. ([FlutterError.onError](https://api.flutter.dev/flutter/foundation/FlutterError/onError.html))
- `PlatformDispatcher.onError` — invoked *"when an unhandled error occurs in the **root isolate**"*; returning `true` means handled, `false` triggers *"a fallback mechanism such as printing to stderr."* ([PlatformDispatcher.onError](https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/onError.html))

### 7.3 Why `runZonedGuarded` is not needed — and is a footgun

`runZonedGuarded` was the pre-`PlatformDispatcher.onError` way to catch uncaught async errors. `PlatformDispatcher.instance.onError` now covers the same ground for the root isolate, and Flutter's own error-handling page demonstrates the complete setup without it.

Reasons to actively avoid it here:

1. **Zone mismatch.** If you call `runZonedGuarded(() { runApp(...); }, ...)` but `WidgetsFlutterBinding.ensureInitialized()` ran in the root zone, the framework throws the "Zone mismatch" assertion. Getting the ordering right is easy to break and hard to notice.
2. **It swallows nothing extra.** With `onError` returning `true`, every root-isolate async error already lands in the log.
3. **It changes `Zone.current` for the whole app**, which means every `Timer` and microtask you schedule runs in a custom zone. Harmless until it isn't.
4. One fewer moving part in a bootstrap that must never fail.

**Where the gap genuinely is:** child isolates. `PlatformDispatcher.onError` does not see them. Mitigations:

- `Isolate.run` / `compute` **rethrow into the caller** — so as long as you `await` them inside a `try`/`catch`, the error surfaces normally. (Note the doc caveat: *"Uncaught asynchronous errors terminate computation but are reported as `RemoteError` objects rather than original error instances."*)
- If you ever use raw `Isolate.spawn`, attach `addErrorListener` and forward over a `SendPort`. Shed Book should not need raw `spawn`.

### 7.4 What the log actually is

A **rolling, redacted, plain-text file** in application support, never in cache (Android deletes cache under storage pressure).

```
<appSupport>/diagnostics/
  session.lock            ← presence at launch = last session died (§7.5)
  shedbook.log            ← current, capped at 256 KB
  shedbook.1.log          ← previous rotation
```

```dart
class DiagnosticsLog {
  static const _maxBytes = 256 * 1024;
  File? _file;

  /// Crash-path writes are SYNCHRONOUS. An async write may never flush
  /// if the process is about to be killed. This is the whole point.
  void writeErrorSync(String source, Object error, StackTrace? stack,
      {String? library, String? context}) {
    try {
      final f = _file;
      if (f == null) { _buffer.add(...); return; }
      final b = StringBuffer()
        ..writeln('--- ${DateTime.now().toIso8601String()} [$source]')
        ..writeln('build: ${BuildInfo.version}+${BuildInfo.build}')
        ..writeln('screen: ${NavObserver.currentRouteName}')
        ..writeln('error: ${Redact.message(error)}')   // §7.6
        ..writeln(Redact.stack(stack));
      f.writeAsStringSync(b.toString(), mode: FileMode.append, flush: true);
      _rotateIfNeededSync(f);
    } catch (_) {
      // Diagnostics must never be the cause of a crash. Swallow.
    }
  }
}
```

Three non-obvious details:

- **`writeAsStringSync(..., flush: true)` on the error path.** An `IOSink.write` is buffered and may never reach disk before the process dies. Synchronous + flush costs a few ms on a path that is already failing.
- **Buffer before `path_provider` resolves.** `installSync` runs before the first frame; the directory is not known yet. Buffer to a bounded in-memory list and drain once the path arrives.
- **Rotate by size, synchronously.** Never let the log itself contribute to a disk-full condition.

### 7.5 Catching what the Dart handlers cannot see

`FlutterError.onError` and `PlatformDispatcher.onError` see **Dart** errors. They do **not** see: an engine/native crash, an Android LMK kill, an iOS jetsam kill, `0xdead10cc`, or the battery dying. Those are precisely the failures that matter for a 3am shed app.

Detect them by inference:

```dart
// At launch, inside installSync():
final lock = File('${dir.path}/diagnostics/session.lock');
if (lock.existsSync()) {
  final prior = jsonDecode(lock.readAsStringSync());
  _log.writeEventSync('abnormal_termination', prior); // screen, uptime, free bytes
}
lock.writeAsStringSync(jsonEncode({
  'startedAt': DateTime.now().toIso8601String(),
  'build': BuildInfo.build,
}), flush: true);

// On AppLifecycleState.hidden — the last state you are guaranteed to see:
lock.deleteSync();
```

A `session.lock` present at launch means the previous session ended without reaching `hidden`. Combined with the last few log lines (which record screen transitions) you get a usable picture of *where* it died without any telemetry leaving the phone.

Also record, once per session at `hidden`: free disk bytes, DB file size, media folder size, WAL size. When a user emails you a log, those four numbers explain most reports.

### 7.6 Redaction is mandatory, not optional

Spec §4.5. The log must contain **no flock data**. Rules:

- **Allowed:** timestamp, app version + build, OS version, device model (`device_info_plus`), free bytes, screen/route name, exception *type*, stack trace, drift/SQLite result codes.
- **Forbidden:** ewe tags, note text, treatment product names, batch numbers, withdrawal periods, photo paths containing user filenames, database row contents.
- **Implementation:** a `Redact` helper that (a) truncates exception messages to a whitelist of known-safe prefixes and otherwise emits only `error.runtimeType`, and (b) rewrites file paths in stack traces to strip the sandbox UUID.
- SQLite exceptions are the risky case — `SqliteException` messages can echo SQL and sometimes bound values. Log `e.resultCode` and `e.extendedResultCode`, plus a *statement identifier* you control, not the raw message.

### 7.7 The Diagnostics screen

Settings ▸ Diagnostics (a sub-screen of screen 12, not a 13th screen):

- **Records:** ewes / lambings / lambs / treatments counts. Reassures the user their data is there.
- **Storage:** database size, media size, free space on device.
- **Last 20 events:** timestamped, redacted, scrollable.
- **Check database** → `PRAGMA quick_check` with a progress indicator.
- **Export diagnostics** → share sheet, sends `shedbook.log` + `shedbook.1.log`. Copy above the button, verbatim in tone: *"This file contains no animal records — only app version, device model and error messages. You can open it and read it before you send it."* That sentence is what makes voluntary reporting actually happen.
- **No automatic prompt to send.** Spec §5: "Zero interruptions."

---

## 8. Battery, thermals and the head torch

### 8.1 Where the energy goes

For a six-hour night with intermittent use, the ranking is: **screen-on time ≫ CPU ≫ everything else**. There is no radio use (no network by construction), no GPS, no sensors, no background service. Shed Book is close to the best-case profile for a mobile app.

### 8.2 Keep the screen awake — yes, but not by default

The 3am argument *for*: the shepherd props the phone on a straw bale, hands occupied, and does not want to unlock it again with a wet glove.
The argument *against*: an always-on screen for six hours in a cold shed will flatten a phone, and a dead phone is worse than a slow one.

**Decision:** `wakelock_plus` 1.7.0 (fluttercommunity.dev, *"does not require any special permissions on any platform"*, no INTERNET), behind:

- an explicit **"Keep screen on"** toggle in Settings, **default OFF**;
- **session-scoped**: automatically released on `AppLifecycleState.hidden` and re-acquired on `resumed` only if the toggle is on;
- **auto-expiring**: a 30-minute timer releases it regardless, with a one-line toast ("Screen lock re-enabled") so the behaviour is honest rather than mysterious;
- **never** acquired implicitly by any screen.

```dart
class ScreenAwake {
  Timer? _expiry;
  Future<void> enable() async {
    await WakelockPlus.enable();
    _expiry?.cancel();
    _expiry = Timer(const Duration(minutes: 30), disable);
  }
  Future<void> disable() async {
    _expiry?.cancel();
    await WakelockPlus.disable();
  }
}
```

Pair it with a **brightness floor, not a boost**: in a dark shed, auto-brightness will already drive the panel low, which is both correct for dark-adapted vision and good for battery. Do not force brightness up. The red-shift mode (spec §7.10) is the right tool for legibility at low brightness.

### 8.3 What cold does

Apple: iPhone and iPad *"are designed for use where the ambient temperature is between 0º and 35º C (32º to 95º F)"*, and *"using an iOS or iPadOS device in very cold conditions outside of its operating range might temporarily shorten battery life and could cause your device to turn off."* The effect is **reversible** — *"battery life will return to normal when you bring your device back to higher ambient temperatures"* — unlike heat damage, which is permanent. ([Apple Support HT118431](https://support.apple.com/en-us/118431))

A UK lambing shed in February is routinely 0–5 °C, and the phone is often outside the shed in a pocket at −2 °C. So the realistic failure is: **the phone shows 40 % and shuts off**, then reports 35 % once it warms up. Nothing the app can do prevents that.

What the app can honestly offer:

1. **Be fast, so the screen is on for less time.** The 15-second interaction *is* the battery mitigation. This is the strongest argument for §1 and §4 that has nothing to do with UX.
2. **Zero background work.** No periodic sync (there is none), no background fetch, no location, no listeners while backgrounded. Cancel the pen-board minute timer on `hidden` (§4.5).
3. **Nothing that keeps the CPU busy while idle.** No infinite animations on the Quick Entry screen. A pulsing "recording" dot during a voice note is fine; a permanently animated background is not.
4. **A one-line, non-nagging note in Settings ▸ Diagnostics** — *"Cold weather can make a phone report a lower battery level and shut down early. It usually recovers when warm."* Factual, no advice, consistent with spec §12.2's prohibition on "you should" text (which is about veterinary advice, but the tone rule generalises).
5. **Export prompt integrates with this.** Spec §7.9's end-of-day export prompt is the real answer to "the phone died in a puddle."

### 8.4 Thermals

Not a concern in this app's direction. There is no sustained GPU load, no video, no ML. The one place to watch is **PDF export of a 60-page flock book with photos**, which is a burst of CPU — but it is user-initiated, bounded, and typically happens indoors afterwards. Do not run it automatically.

---

## 9. Storage growth

### 9.1 Estimating

| Item | Assumption | Size |
|---|---|---|
| Photo | JPEG, 1600 px long edge, quality 80 | **300–500 KB** |
| Photo (if you store the camera original) | 12 MP HEIC/JPEG | **2–5 MB** ⚠️ |
| Voice note | AAC 32 kbps mono, 30 s | **~120 KB** |
| Voice note, 2 min | | ~480 KB |
| Database row (lambing + 2 lambs + note) | | **< 1 KB** |
| Full DB, one 400-ewe season | ~5,000 rows | **2–5 MB** |
| Full DB, ten seasons | ~50,000 rows | **20–50 MB** |

**Season model, 400 ewes:**

| Scenario | Media | Total |
|---|---|---|
| Conservative — 25 % of lambings get one downscaled photo | 100 × 400 KB | **~40 MB** |
| Typical — every lambing gets a photo, 10 % get a voice note | 400 × 400 KB + 40 × 150 KB | **~166 MB** |
| Heavy — 3 photos per lambing, 25 % voice notes | 1200 × 400 KB + 100 × 250 KB | **~505 MB** |
| ⚠️ **If you store originals** — 3 photos, 3 MB each | 1200 × 3 MB | **~3.6 GB** |

The last row is the failure case, and it is entirely self-inflicted. **Downscale at capture, never store the original.**

```dart
// flutter_image_compress, native, off the Dart UI isolate.
final bytes = await FlutterImageCompress.compressWithFile(
  cameraFile.path,
  minWidth: 1600, minHeight: 1600, // long-edge cap
  quality: 80,
  format: CompressFormat.jpeg,
);
```

1600 px is plenty to see a malpresentation, a prolapse, or an ear tag. Anything larger is storing pixels no shepherd will ever look at.

### 9.2 Where files live

| | Database | Media | Diagnostics log | Export scratch |
|---|---|---|---|---|
| Directory | app **support** | app **support**/media | app **support**/diagnostics | **temporary** |

Rationale: Android's `cacheDir` (which `getTemporaryDirectory()` maps to) is explicitly volatile — *"When the device is low on internal storage space, Android may delete these cache files to recover space. So check for the existence of your cache files before reading them"* ([Android app-specific storage](https://developer.android.com/training/data-storage/app-specific)). Losing a photo of a difficult lambing to a silent OS cleanup would be an unforgivable bug. Only the throwaway PDF/CSV byte buffers, which the user has just shared, belong in temp.

⚠️ **Verify the exact platform mapping of `path_provider`'s directories yourself** (`getApplicationSupportDirectory` vs `getApplicationDocumentsDirectory` on Android/iOS). The pub.dev page lists the four directories but the excerpt I read did not spell out the native mapping or iCloud/backup exclusion behaviour. This matters because on iOS, `Documents` is user-visible in Files when `UIFileSharingEnabled` is set — which you almost certainly do **not** want for the database. ([path_provider](https://pub.dev/packages/path_provider)) — **medium confidence, confirm from the plugin source before shipping.**

### 9.3 When to warn

Do **not** ship a "free disk space" plugin for this. `disk_space_plus` 0.2.6 is 13 months old with an **unverified uploader** and 14 likes; `storage_space` and friends are similarly thin. Adding an unmaintained native plugin to an app whose selling point is that it cannot break is a bad trade.

Instead, use what is already there:

```dart
// Zero dependencies. Works on both platforms.
Future<int> freeBytes(Directory dir) async {
  final st = await dir.statSync(); // FileStat — no free-space field, see below
  ...
}
```

Dart's `FileStat` does **not** expose free space, so if you want a *number* you either add a plugin or write ~20 lines of platform channel (`StatFs.getAvailableBytes()` on Android, `NSFileManager.attributesOfFileSystem(forPath:)` on iOS). **Write the 20 lines.** It is less risk than the dependency, has no permissions, and you control it.

**Warning policy** (all non-blocking, all in Settings ▸ Diagnostics plus one contextual banner):

| Condition | Action |
|---|---|
| App media > 1 GB | A line in Diagnostics: "Photos: 1.2 GB. You can export and delete a past season." Never a modal. |
| Device free < 500 MB | One banner on the Export screen when it is next opened. |
| Device free < 100 MB | Disable *new photo attachment* (grey the camera button with the reason on it). Text entry continues to work. |
| `SQLITE_FULL` thrown | §9.4 |

Never a modal on the Quick Entry screen. Spec §5: "Zero interruptions."

### 9.4 Disk full mid-write — the real 3am failure

This is where the ordering rule from decision #6 pays for itself.

**Order of operations for a lambing with a photo:**

1. **Commit the event row.** ~500 bytes. Succeeds on a device with 200 KB free.
2. UI shows the event as saved. The shepherd can walk away here and nothing is lost.
3. Downscale and write the photo to `media/<uuid>.jpg` (temp file, then `rename` — rename within a filesystem is atomic).
4. Commit a second, tiny `UPDATE` attaching the path.

If step 3 fails with `ENOSPC` or step 4 with `SQLITE_FULL`:

- The lambing record **already exists and is correct**. Nothing is lost that the 3am user cares about.
- Show a persistent, dismissible chip on the record: *"Photo not saved — storage full."* Honest, not silent (spec §12.4 in spirit).
- Offer **Retry photo** on the ewe card, so it can be recovered after freeing space, without re-entering the event.

If even step 1 fails with `SQLITE_FULL`:

```dart
try {
  await recordBirthType(ewe, type);
} on SqliteException catch (e) {
  if (e.resultCode == 13 /* SQLITE_FULL */) {
    // Do NOT clear the in-memory entry. Do NOT navigate away.
    ref.read(pendingEntryProvider.notifier).hold(ewe, type);
    showStorageFullSheet(
      onRetry: () => recordBirthType(ewe, type),
      onFreeSpace: () => openExportScreen(),   // export then delete a season
    );
  }
  rethrow;
}
```

Key points: SQLite's transaction **rolls back atomically**, so there is no half-written record. The in-memory entry is held so a retry after the user deletes a video from their camera roll costs one tap, not a re-entry. And `PRAGMA temp_store = MEMORY` (§6.2) removes one whole class of `SQLITE_FULL` — SQLite's docs note it can fire *"even with abundant primary disk space if temporary files are stored on a separate partition"* ([result codes](https://www.sqlite.org/rescode.html)).

---

## 10. Measuring

### 10.1 The rule that governs everything else

> "Debug mode's performance is **not representative** of real-world usage… Emulator/simulator execute only in debug mode… Profile mode is **disabled on emulator/simulator**."

([Flutter build modes](https://docs.flutter.dev/testing/build-modes))

Therefore: **every performance number must come from a physical device in profile or release mode.** Any number from a simulator, an emulator, or a debug build is not evidence. This single fact is what drives decision #14.

### 10.2 Measure by hand, once per release

Two devices: the oldest supported iPhone (SE 2020 / 11) and a low-end Android (API 30, 3 GB, no Vulkan). Script it, record the output in `docs/perf/measurements.md`, and diff it release to release.

**(a) Cold start**

```bash
flutter run --profile --trace-startup -d <device>
# → build/start_up_info.json
#   engineEnterTimestampMicros, timeToFrameworkInitMicros,
#   timeToFirstFrameMicros, timeToFirstFrameRasterizedMicros,
#   timeAfterFrameworkInitMicros
```

Android cross-check, because it includes the OS-side cost `--trace-startup` cannot see:

```bash
adb shell am force-stop com.shedbook.app
adb shell am start -S -W -c android.intent.category.LAUNCHER \
  -a android.intent.action.MAIN com.shedbook.app/.MainActivity
# TotalTime / WaitTime; also check: adb logcat -d | grep "Displayed"
```

Reference thresholds (never targets): Android vitals flags cold ≥ 5 s, warm ≥ 2 s, hot ≥ 1.5 s as *excessive*; Apple's stated goal is a first frame within **400 ms**.

**(b) DB open and migration**, so you know what §1.3's deferral is actually buying:

```dart
import 'dart:developer' as dev;

final task = dev.TimelineTask()..start('db.open');
final db = await openDatabase();
task.finish();
```

These appear in DevTools ▸ Performance ▸ **Timeline Events** ([DevTools Performance](https://docs.flutter.dev/tools/devtools/performance)).

**(c) Keypad frame times.** Profile mode, DevTools Performance view, type `4-1-2` fast with the flock loaded at 400 ewes. Every frame must be green. If any is red: click it, read the **Frame analysis** tab, then enable **Track widget builds** (UI-thread red) or **Track paints** (raster-thread red). The performance overlay is also reachable by pressing **P** in the `flutter run` console.

**(d) Export duration.** Wall-clock a 400-ewe flock book PDF and a full JSON backup, on the slow Android, with the battery below 20 % (thermal/DVFS state matters).

**(e) App size**, before every release:

```bash
flutter build appbundle --analyze-size
flutter build ipa --export-method development   # then Xcode App Thinning Size Report
```

Spec §11 sets a hard target: *"Total app payload well under 20 MB, dominated by fonts and icons."* Note `--split-debug-info` gives a *"dramatic reduction"* ([app size docs](https://docs.flutter.dev/perf/app-size)).

### 10.3 What goes in CI — and what does not

**In CI (deterministic, no device needed):**

| Check | Why it works in CI |
|---|---|
| **App size budget** — fail if the AAB grows > 5 % or crosses 20 MB | Pure build output, no runtime |
| **Permission audit** — grep the merged manifest for `INTERNET` / `ACCESS_NETWORK_STATE` (§7.1) | Build output |
| **Dependency audit** — fail if `flutter pub deps` contains any package with a known network path, or a discontinued package | Deterministic |
| **`flutter analyze` + a custom lint** banning `dart:io` `HttpClient`, `package:http`, `Socket` | Static |
| **Drift schema tests** — drift's generated schema snapshots verify every migration path from v1 to vN | Pure Dart, headless |
| **A "no `await` before `runApp`" test** — assert `main.dart` contains no `await` before the `runApp` call (a 15-line source test) | Static, and it protects decision #1 forever |

**Not in CI:** frame times, startup latency, export duration. Flutter *does* support it — `IntegrationTestWidgetsFlutterBinding.traceAction(..., reportKey: 'x')` plus `TimelineSummary.summarize(...).writeTimelineToFile(...)` produces `build/x.timeline_summary.json`, run via `flutter drive --driver=test_driver/perf_driver.dart --target=integration_test/x_test.dart --profile --no-dds` ([Performance profiling in integration tests](https://docs.flutter.dev/cookbook/testing/integration/profiling)). But for a **single developer with no device farm**, a hosted-runner emulator can only run debug mode, so the numbers are meaningless and the gate becomes a flaky tax you will end up disabling. Build the harness, run it on a desk device before a release, commit the JSON. Do not gate merges on it.

**One exception worth automating locally:** a `make perf` target that runs (a) `--trace-startup` and (b) the quick-entry `traceAction` against a plugged-in phone and prints a diff against the committed baseline. Ten minutes of work, and it is what actually catches a regression.

### 10.4 The metric the spec actually asks for

Spec §15: *"Median time from unlock to a saved lambing event is under 15 seconds."* You cannot measure "unlock" from inside the app, and you must not phone home. What you **can** do, entirely locally:

```dart
// Root isolate. Timestamps only, no content. Written to the diagnostics log,
// visible in Settings ▸ Diagnostics, never transmitted.
class InteractionTiming {
  DateTime? _resumedAt;
  void onResumed() => _resumedAt = DateTime.now();
  void onLambingCommitted() {
    final t = _resumedAt;
    if (t != null) {
      Diagnostics.event('entry_latency_ms',
          DateTime.now().difference(t).inMilliseconds);
      _resumedAt = null;
    }
  }
}
```

Show the rolling median in Diagnostics as *"Typical time to record an event: 11 s."* It is honest, it is local, it is the product's own success metric made visible, and a user can voluntarily paste it into a forum post. That is the offline-only substitute for analytics.

---

## Rejected alternatives

| Considered | Why it lost |
|---|---|
| **Sentry / Firebase Crashlytics** | Requires `INTERNET`, transmits data to a third party. Violates spec §4.5 and §13. No configuration makes it compliant, because the transmission itself is the violation. |
| **`runZonedGuarded` around `runApp`** | `PlatformDispatcher.instance.onError` covers the same root-isolate errors; Flutter's own docs demonstrate the full setup without it. It adds a zone-mismatch failure mode to a bootstrap that must never fail. |
| **`sqlite3_flutter_libs`** | **Discontinued** (`0.6.0+eol`) and a no-op. Its own page tells you to move to `sqlite3: ^3.x`. Copying a 2024 drift tutorial gets you a dead dependency. |
| **`PRAGMA synchronous = NORMAL` with WAL** (the popular choice) | SQLite states plainly that WAL + `NORMAL` "does lose durability" on power loss. Spec §5 says assume the phone dies. `FULL` costs one fsync per commit at ~10 commits/minute. |
| **`journal_mode = DELETE` (default)** | Safe, but every write blocks readers and the rollback journal costs two fsyncs plus a file delete per commit. WAL + `FULL` is both faster and equally durable. |
| **`journal_mode = MEMORY` or `OFF`** | "Risky for durability" / "disables atomic commit". Instantly disqualified by spec §5. |
| **SQL query per keystroke on the tag keypad** | Correct at scale, wrong here. Async round-trip through drift's background isolate lands the list 1–2 frames behind the digits, and the required substring semantics (`%12%`) cannot use an index anyway. In-memory is ~40 µs and same-frame. |
| **Debouncing the tag keypad** | Debouncing a 40 µs operation adds latency for nothing. Debounce belongs only on the unbounded FTS note search. |
| **`RestorationMixin` / `restorationScopeId`** | Reintroduces draft state, which spec §5 forbids, and risks restoring a stale animal selection — the exact error class the product exists to eliminate. The database is the restoration mechanism. |
| **`deferFirstFrame` / `flutter_native_splash.preserve()`** | Holds a static image while you do I/O the first screen doesn't need. Converts a 0 ms wait into 150 ms. Use the package for asset generation only. |
| **A splash screen with a logo animation** | Every millisecond of it is stolen from the 15-second budget, and spec §5 forbids interruptions. The launch image is a flat dark rectangle that matches route 1. |
| **`package:image` for downscaling, inside an isolate** | `flutter_image_compress`'s own docs: Dart-only image libraries "are too slow for typical compression workloads." Native compression already runs off the Dart isolate. |
| **`disk_space_plus` / `storage_space` / `flutter_storage_info`** | All thin, some with unverified uploaders, one 13 months stale. ~20 lines of `StatFs` / `NSFileManager` platform channel is less risk in an app whose promise is that it cannot break. |
| **`printing` as a hard dependency** | Its web implementation pulls Pdf.js from a CDN. Irrelevant on mobile (its Android manifest declares no permissions), but `share_plus` alone covers "save + share". Add `printing` only when a real print dialog is requested. |
| **`FlutterEngineGroup` / pre-warmed engine** | A meaningful cold-start trick for add-to-app hosts. Shed Book is a pure Flutter app with one engine; there is nothing to pre-warm. |
| **SkSL shader warm-up (`--bundle-sksl-path`)** | Dead with Impeller. Flutter's own shader page now just says "use Impeller." |
| **Opting out of Impeller on Android** | Only as a temporary bisect. Impeller is the default and iOS has no alternative; running two renderers doubles your test surface for zero benefit to a flat dark UI. |
| **CI performance gates on frame time / startup** | Profile mode is disabled on emulators, so hosted-runner numbers are noise. Gate size and permissions (deterministic); measure speed by hand on real devices. |
| **A 1-second timer for pen-board "hours since penned"** | 3,600× more rebuilds than the value changes. One minute is already generous. |
| **Full-screen `ColorFiltered` for red-shift mode** | A per-frame `saveLayer` over the whole app. A second `ColorScheme` costs nothing and looks better. |
| **`PRAGMA integrity_check` at startup** | Full-database scan on the cold-start path. Belongs behind a button as `quick_check`. |
| **Copying the raw `.sqlite` file as a backup** | SQLite: "Separating the database from its WAL file can cause data loss or corruption." The backup format is JSON (spec §7.9); a file copy would need `VACUUM INTO` or a `TRUNCATE` checkpoint first. |

---

## Pitfalls

| # | Pitfall | Mitigation |
|---|---|---|
| 1 | `await` creeps back into `main()` — someone adds `await Firebase.init()`-shaped code and the launch gains 200 ms | The source test in §10.3 that fails CI if `main.dart` contains `await` before `runApp` |
| 2 | `PRAGMA synchronous = FULL` is set in `setup` but the connection is later reopened by a path that skips it | `synchronous` is **session-only**. Have exactly one `openShedBookDatabase()` and assert `PRAGMA synchronous` returns `2` in a startup self-check |
| 3 | `journal_mode = WAL` silently fails and returns the previous mode | `PRAGMA journal_mode = WAL` returns `"wal"` on success. Read the returned value and log a Diagnostics event if it isn't |
| 4 | Foreign keys silently unenforced — `foreign_keys` is **OFF by default** and per-connection | Set it in `setup`; add a drift test that a dangling `Lamb.lambing` insert throws |
| 5 | `setup` callback references a root-isolate global and throws on the background isolate | Drift: "global variables… may not be visible in a background isolate." Keep `setup` to `db.execute` calls only |
| 6 | Platform channel called from a background isolate → `UnimplementedError` | `BackgroundIsolateBinaryMessenger.ensureInitialized(RootIsolateToken.instance!)` inside the isolate, or pass bytes instead of calling channels |
| 7 | `compute`/`Isolate.run` given a closure that captures the whole widget tree | Dart docs: closures "may implicitly send unexpected state." Always a top-level/static function + explicit data class |
| 8 | The diagnostics log write is `async` and never flushes before the process dies | `writeAsStringSync(..., mode: FileMode.append, flush: true)` on the error path |
| 9 | The diagnostics log itself throws (disk full) and takes down the error handler | Wrap the whole handler body in a bare `catch (_) {}`; `FlutterError.onError` explicitly does not catch its own exceptions |
| 10 | The log leaks flock data via a `SqliteException` message echoing SQL and bound values | Log `resultCode` / `extendedResultCode` and a statement id, never `e.toString()` |
| 11 | The log grows unbounded and contributes to a disk-full failure | Rotate at 256 KB, keep two files, check on every write |
| 12 | A stale selected ewe survives a 20-minute background gap and an event is filed against the wrong animal | The `ResumePolicy` 2-minute rule (§2.3) |
| 13 | iOS kills the app with `0xdead10cc` because a transaction was open across suspension | Never hold a transaction across a UI `await`; checkpoint on `hidden`; never use an App Group container |
| 14 | White/light flash at launch on a light-mode phone | Dark `values-night/styles.xml` **and** `values/styles.xml`; `UIUserInterfaceStyle = Dark` in `Info.plist`; splash exit-animation listener in `MainActivity` |
| 15 | Media stored in `getTemporaryDirectory()` and silently deleted by Android under storage pressure | Media in application **support**; only post-share export scratch in temp |
| 16 | Camera originals stored, and a season eats 3.6 GB | Downscale to 1600 px / q80 at capture; never persist the original |
| 17 | `SQLITE_FULL` loses the user's entry because the UI navigated away optimistically | Commit before acknowledging; hold the in-memory entry on failure; offer retry |
| 18 | A plugin merges `android.permission.INTERNET` back into the release manifest | `tools:node="remove"` + the CI grep on the merged manifest |
| 19 | Performance "measured" in debug mode or on a simulator, producing numbers that are 5–10× off | Profile mode on physical devices only; it is disabled on emulators by design |
| 20 | The pen board's per-second timer keeps the UI isolate busy all night | Minute-granularity `Stream.periodic`, `autoDispose`, cancelled on `hidden` |
| 21 | `beforeOpen` grows expensive work — it runs on *every* open, not just migrations | Keep it to seeding on `details.wasCreated`; anything else goes in deferred boot |
| 22 | Someone "optimises" the flock list by adding an intrinsic-sized row and every keystroke triggers an intrinsics pass | Fixed `itemExtent`; DevTools **Track layouts** shows `$runtimeType intrinsics` |
| 23 | Build hooks fail on a machine without network, or the pinned SQLite binary disappears in 2029 | Vendor the pub cache / mirror the hook artefacts for long-term reproducibility; note this in the release runbook |
| 24 | A drift `singleClientMode: true` connection is closed while a second client is still attached | Use `computeWithDatabase` (which manages teardown) rather than hand-rolled `DriftIsolate` lifecycles |

---

## How this serves the 3am test and the offline-only constraint

**The 3am test.**

- *"Under fifteen seconds from unlock to a saved lambing event."* — The keypad is interactive at frame 1 (§1.4), the filter is same-frame (§4.3), and the first tap commits (§6.3). The machine contributes under a second; the remaining fourteen belong to the human.
- *"No white flash on launch."* — Three surfaces, one hex value, splash exit animation suppressed (§1.5).
- *"Cold fingers… minimum 60×60 pt."* — Fixed row extents fall out of the tap-target rule and simultaneously give the scroll machinery the extent foreknowledge it wants (§4.4). Nothing animates or moves under a thumb mid-tap.
- *"Zero interruptions."* — No crash-report prompt, no rating prompt, no modal storage warning on the entry path (§7.7, §9.3). The only storage interruption is at the point where photos become impossible, and even then text entry keeps working.
- *"Assume the phone dies."* — `WAL + synchronous = FULL` (§6.1), commit-before-acknowledge (§6.3), record-before-media (§9.4). A battery death mid-entry loses at most the photo.
- *"There is no draft state to lose."* — Which is exactly why the aggressive resume-clear (§2.3) is safe, and why `RestorationMixin` is unnecessary.
- **A cold shed drains batteries.** The fastest interaction is also the least screen-on time, so §1 and §4 are battery features as much as UX features (§8.3).

**Offline-only.**

- Zero runtime network paths in anything recommended here. `wakelock_plus` requires no permissions. `printing`'s Android manifest declares none. `share_plus` hands off to the OS. `sqlite3` bundles a static library.
- The only network in the whole stack is Dart build hooks downloading a SQLite binary **at build time** (§0.1) — flagged as a reproducibility risk, not a privacy one.
- Crash reporting is a **file the user can read and choose to send** (§7.4, §7.6), which is a stronger privacy position than any "anonymised telemetry" claim, and it is verifiable by the user.
- The success metric of spec §15 is computed and displayed **on device** (§10.4) instead of being collected.
- The CI permission audit (§10.3) makes "no INTERNET permission" a property the build enforces rather than a claim on a website.

---

## Sources

Fetched 2026-07-27. Every URL below was actually retrieved unless annotated.

**Flutter — performance and rendering**
- https://docs.flutter.dev/perf/best-practices
- https://docs.flutter.dev/perf/ui-performance
- https://docs.flutter.dev/perf/impeller
- https://docs.flutter.dev/perf/shader
- https://docs.flutter.dev/perf/app-size
- https://docs.flutter.dev/tools/devtools/performance
- https://docs.flutter.dev/testing/build-modes
- https://docs.flutter.dev/cookbook/testing/integration/profiling
- https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_tools/lib/src/tracing.dart
- https://github.com/flutter/flutter/issues/158361

**Flutter — errors, lifecycle, startup**
- https://docs.flutter.dev/testing/errors
- https://api.flutter.dev/flutter/foundation/FlutterError/onError.html
- https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/onError.html
- https://api.flutter.dev/flutter/dart-ui/AppLifecycleState.html
- https://api.flutter.dev/flutter/widgets/RestorationMixin-mixin.html
- https://api.flutter.dev/flutter/widgets/WidgetsBinding/deferFirstFrame.html
- https://api.flutter.dev/flutter/widgets/WidgetsFlutterBinding-class.html
- https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver/didHaveMemoryPressure.html
- https://api.flutter.dev/flutter/scheduler/SchedulerBinding/scheduleTask.html
- https://api.flutter.dev/flutter/widgets/ListView-class.html
- https://api.flutter.dev/flutter/foundation/compute.html
- https://api.flutter.dev/flutter/services/BackgroundIsolateBinaryMessenger-class.html
- https://docs.flutter.dev/platform-integration/android/splash-screen
- https://docs.flutter.dev/platform-integration/ios/launch-screen
- https://docs.flutter.dev/release/release-notes
- https://docs.flutter.dev/release/release-notes/release-notes-3.44.0

**Dart**
- https://dart.dev/language/concurrency
- https://api.dart.dev/stable/dart-isolate/Isolate/run.html
- https://dart.dev/tools/hooks *(via search result summary; confirms build hooks are stable from Dart 3.10)*

**SQLite**
- https://www.sqlite.org/atomiccommit.html
- https://www.sqlite.org/wal.html
- https://www.sqlite.org/pragma.html
- https://www.sqlite.org/rescode.html
- https://www.sqlite.org/optoverview.html

**Drift / sqlite3.dart**
- https://drift.simonbinder.eu/docs/getting-started/
- https://drift.simonbinder.eu/isolates/
- https://drift.simonbinder.eu/platforms/vm/
- https://drift.simonbinder.eu/migrations/
- https://pub.dev/packages/drift
- https://pub.dev/packages/drift/changelog
- https://pub.dev/packages/drift_flutter
- https://pub.dev/packages/drift_flutter/changelog
- https://pub.dev/documentation/drift_flutter/latest/drift_flutter/driftDatabase.html
- https://pub.dev/documentation/drift_flutter/latest/drift_flutter/DriftNativeOptions-class.html
- https://pub.dev/documentation/drift/latest/native/NativeDatabase-class.html
- https://pub.dev/packages/sqlite3
- https://pub.dev/packages/sqlite3/changelog
- https://pub.dev/packages/sqlite3_flutter_libs
- https://github.com/simolus3/sqlite3.dart/blob/main/UPGRADING_TO_V3.md

**Android**
- https://developer.android.com/topic/performance/vitals/launch-time
- https://developer.android.com/guide/components/activities/process-lifecycle
- https://developer.android.com/training/data-storage/app-specific

**Apple**
- https://developer.apple.com/documentation/uikit/about-the-app-launch-sequence
- https://developer.apple.com/documentation/xcode/reducing-your-app-s-launch-time *(direct fetch returned no body twice; the 400 ms first-frame goal and the ~100 ms system / ~300 ms app split are quoted from a search-result summary of this page — treat exact wording as second-hand)*
- https://support.apple.com/en-us/118431 *(iPhone/iPad 0–35 °C operating range; cold effects temporary)*
- https://developer.apple.com/forums/thread/126438 *(0xdead10cc — file/SQLite lock held during suspension; Apple Developer Forums, staff-answered, not formal documentation)*

**Other packages (all read from their live pub.dev pages)**
- https://pub.dev/packages/path_provider
- https://pub.dev/packages/wakelock_plus
- https://pub.dev/packages/share_plus
- https://pub.dev/packages/pdf
- https://pub.dev/packages/printing
- https://raw.githubusercontent.com/DavBfr/dart_pdf/master/printing/android/src/main/AndroidManifest.xml
- https://pub.dev/packages/flutter_image_compress
- https://pub.dev/packages/logging
- https://pub.dev/packages/device_info_plus
- https://pub.dev/packages/flutter_native_splash
- https://pub.dev/packages/disk_space_plus

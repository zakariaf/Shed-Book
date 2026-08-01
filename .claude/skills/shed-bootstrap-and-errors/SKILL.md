---
name: shed-bootstrap-and-errors
description: How Shed Book starts, resumes and fails. Use when editing main.dart or app.dart, mapping an exception to ShedFailure, wiring the local log, handling lifecycle or resume, or chasing a white flash or slow start. Do NOT use for write semantics (shed-write-path).
---

# Bootstrap, lifecycle and failure

Two files own all of it: `lib/main.dart` (~20 lines, suspends on nothing) and `lib/app.dart` (`ShedBookApp`, the only stateful widget above the router). Sources, all BINDING and all outranking this skill — cite them, do not restate their tables: `docs/engineering/01-architecture.md` §5–§6, `docs/engineering/02-state-di-navigation.md` §9, `docs/engineering/13-build-ci-release.md` §7–§8, `docs/engineering/06-design-system.md` §9, `docs/engineering/CONVENTIONS.md` §2.5 + §2.14 (R4, R11, R23, R34, R52).

**Do NOT use for:** repository verbs and `WriteCommitted` semantics — `shed-write-path`; provider shapes, `WriteController.guard` and Riverpod 2.6.1 spellings — `shed-riverpod-providers`; the wording or pixels of the failure panel, receipts and empty states — `indelible-states-and-feedback`.

## Non-negotiables

- **`main()` suspends on nothing.** No `async`, no futures awaited, no `overrides:`, no `retry:`. Rule `main.no_await` fails the build on the literal word in `lib/main.dart`.
- **The first frame is a static dark Quick Entry shell with a fully interactive keypad and no data** (decision #21). Everything else lands after it. Never a spinner (`ui.spinner`).
- **No network path, ever — including the error path.** No Crashlytics, Sentry, Bugsnag, analytics. A crash report is a transmission and the transmission *is* the violation; gate G1 fails the moment one is wired up.
- **Reads throw and propagate to the global net; writes return a sealed `WriteOutcome`.**
- **One diagnostics sink, `LocalLog.instance`** (R52). `_diagnostics` is a banned identifier; this is the only non-framework `.instance` in `lib/`.
- **Never log an exception message.** `SqliteException` messages echo the failing SQL and sometimes bound values — tags, note text, batch numbers, withdrawal periods.
- **Nothing here re-stamps a record's time.** Resume shows the fact from disk; the honest time is when it happened, not when the app came back (spec §12.5).

## `lib/main.dart` and the global error net

Install order is the entire content of the file: binding → `FlutterError.onError` → `PlatformDispatcher.instance.onError` (return `true`; `false` can terminate the process) → `ErrorWidget.builder` → `runApp(const ProviderScope(child: ShedBookApp()))`.

**Read `examples/main.dart` before editing startup** — it is the install order with an annotation on every line explaining what suspending there would cost, which the real file cannot carry because `main.no_await` is a substring match. Prose cannot settle that ordering; the file can. **Precedence: `01 §6.1` is the canonical text and `lib/main.dart` is authoritative the moment it exists** — the example is a teaching copy and loses to both.

Three divergences from standard advice, each deliberate (01 §5.5): **no crash reporter**, **no `runZonedGuarded`** (`PlatformDispatcher.instance.onError` supersedes it and a zone/binding mismatch is a known footgun), **no `exit(1)` in release** — killing the app mid-lambing over one mis-laid-out widget is worse than a broken screen when the data is already committed.

`lib/main.dart` and `lib/app.dart` may not import `lib/core/db/`, `package:drift/*` or `package:sqlite3*` (`layer.root`), nor reference `purchaseServiceProvider` (`launch.store_call`). Neither can open a database or read the entitlement, by construction.

`NightErrorPanel` (`lib/core/ui/night_error_panel.dart`) renders where nothing is guaranteed: own `Directionality`, no `Theme`, no `MediaQuery`, no provider, hard-coded base surface — one of the four `[exempt]` lines in `tool/policy_allowlist.txt`, its rule being `token.raw_color` (R56). Prove it by pumping it bare.

## After the first frame

`ShedBookApp` is a `ConsumerStatefulWidget` (R34) so `initState` can post-frame-kick `ref.read(databaseProvider.future).ignore()` — started, never awaited: the providers that need it rebuild when it lands, and a failure still surfaces as `databaseProvider`'s `AsyncError`. The callback exists so the open still starts on a screen that watches nothing. What else runs post-frame, and who owns each item, is the table in `01 §6.3` — read it before adding anything to boot.

`databaseProvider` failing is the one failure a screen cannot handle: it routes to `RecoveryScreen` in the same tree — save a copy / restore from JSON / start a new records file. **Never auto-repair, never auto-delete** (01 §5.6; `04-migrations-media-backup-restore.md` owns the screen).

## Failures

`ShedFailure` is sealed with six variants in `lib/core/failure.dart` (CONVENTIONS §2.5 — do not invent a seventh); every `switch` over it is exhaustive with no `default`. Mapping is `shedFailureFrom(Object)` in `lib/data/failure_mapping.dart` (R4) — there is no `ShedFailure.from`, because putting the mapping on the type drags `package:sqlite3` into `lib/core/`, which layer rule 8 forbids.

- **Unwrap `DriftRemoteException.remoteCause` first.** drift runs SQLite on a background isolate, so the real error arrives wrapped and a `switch` on the outer object matches nothing.
- **`UnexpectedFailure` is constructed at exactly two sites**: inside `shedFailureFrom`, and inside `WriteController.guard`'s catch-all. A third site is a defect.
- **No `userMessage` may name a cause the result code does not prove.** `SQLITE_IOERR` must not say "out of space" — asserting what the app cannot see is safety rule §12.4's error aimed at the user instead of the record.
- Failures reach the user through `showFailure(context, failure)` in `lib/core/ui/feedback.dart` (R10, R30). **There is no SnackBar in this app**: owner ruling P2 supersedes 01 §5.4's "persistent SnackBar" wording, and `showSnackBar(` is banned everywhere including `feedback.dart`.

## `LocalLog`

Five methods, fixed (CONVENTIONS §2.14, R52) — do not add a sixth. A static singleton installed before any `ProviderScope` exists, so it is not a provider and never will be.

- **Handlers install in `main()`; the directory is unknown until `path_provider` resolves post-frame.** `LocalLog` therefore starts memory-only with a bounded ring buffer and flushes on `attachTo(directory)`. A log that touches the filesystem at construction breaks startup ordering.
- **Crash-path writes are `writeAsStringSync(..., flush: true)` and bypass the stream sink** — a buffered `IOSink` write may never reach disk when the process is about to die.
- **Redaction is a list, not a judgement call** — the allowed/forbidden columns are `13 §8.4`, mirrored in `lib/core/log/redaction.dart`. Log `resultCode`/`extendedResultCode` plus a statement identifier you control; never `e.toString()`.
- **Any failure inside the log is swallowed.** Diagnostics must never be the cause of a crash.
- 256 KB, one rotation, in application support — **never the cache directory**, which Android deletes under storage pressure.

## The clean pause and the dirty resume

Engine crashes, jetsam kills and a flat battery are invisible to both Dart handlers — and they are exactly the 3am failures that matter. They are detected by inference (13 §7):

- `session.lock` is written `clean: false` at `attachTo`, rewritten `clean: true` by `markCleanPause()`, and **re-armed on the first `write`/`record`/`flutterError` after a pause**, behind an in-memory latch so it costs one sync write per resume.
- Present-and-not-clean at the next launch ⇒ the previous session died. `attachTo` records `session.abnormal_termination`; **it is reported, never acted on.** Never prompt, never count, never behave differently — a self-repairing app hides the bug (§12.4 is flag, do not fix).
- `startedAt` is `appNow().utc.toIso8601String()`. `DateTime.now(` is banned outside `lib/core/time/app_clock.dart` and the ban applies to the log too — three research notes wrote `DateTime.now()` in this exact snippet and all three are wrong.
- Documented blind spot: a process killed after resume but before any event is recorded reports as a clean pause.

## Lifecycle and resume, in `lib/app.dart`

`_ShedBookAppState extends ConsumerState<ShedBookApp> with WidgetsBindingObserver`. The switch in `02 §9.1` is the reference implementation; four parts of it are load-bearing:

- **`addObserver(this)` in `initState`, `removeObserver(this)` in `dispose`.** The mixin alone does nothing: `didChangeAppLifecycleState` looks like a valid override and is never called. No lint, analyzer or test notices, and the resume policy, the wakelock release and the clean-pause marker all silently stop existing.
- **`hidden` is the only safe place to record a clean pause** — synthesised on both platforms, the last state you are guaranteed to observe. `markCleanPause()` has exactly this one call site.
- **The wakelock releases on any non-resumed state, not just `hidden`** (decision #79): a phone that goes `inactive` behind a banner must not hold the screen on all night.
- **`resumed` calls `reconcile()`, never `schedule(`** (decision #63, R51), reached through `reminderReconcilerProvider.future` and deliberately not awaited — the callback is `void` and must not sit on the frame.

`ResumePolicy` lives in `lib/app.dart`; `staleAfter` is 2 minutes. Under it, keep the selection — the phone went down to grab a towel. At or over it, clear the selection and land on Quick Entry, because a stale selected ewe files ewe 128's lambing against 412, the exact error the product exists to eliminate. **There is no state restoration anywhere** (decision #24): no `RestorationMixin`, no `restorationScopeId`, no `Restorable*`; CI greps for all of them.

Clearing the selection destroys nothing **only** because every write commits immediately. The in-flight lambing row already exists and returns as the first recents chip; resume must not touch its `RecordedTime`. Weaken commit-on-first-tap and the aggressive clear becomes data loss. What is honestly lost is the table in `02 §9.3`, with one correction: undo is a time-boxed strike affordance whose window is stated in **seconds** (ruling P2), not "until the SnackBar is dismissed", and it does not survive process death.

## No white flash

Four layers, one colour, and **the first two have no Dart-side fix** — by the time Dart runs the flash has happened. The colour, the XML, the storyboard floats and the `launch.colour_parity` gate are `06 §9`; read it before touching `android/` or `ios/`. What gets forgotten: `Main.storyboard`'s `FlutterViewController` view defaults to **white** and is what shows between the launch screen tearing down and Flutter's first frame. **No `values-night/` folder** — the usual Android advice launches white on a phone in light mode. No `flutter_native_splash`, no `deferFirstFrame()`, no minimum splash duration: each converts a fixed dark frame into a variable wait on the DB open, which is the thing this design exists to prevent.

## Gotchas

- `ResumePolicy.shouldClearSelection` takes two `Instant`s, not `DateTime`s: `appNow()` is the only wall-clock reader (R23) and returns `Instant`. CONVENTIONS §2.14's table cell still spells `DateTime` — R23 is the later ruling in the same file and wins. Flag the cell; do not follow it.
- `ref.invalidate(minuteTickProvider)` in the `resumed` arm is the **one** legitimate `ref.invalidate` in the codebase (elapsed times are 20 minutes stale) — but rule `stream.invalidate` scans all of `lib/` and `[exempt]` has four lines, none for `lib/app.dart` (R56). Keep the call and raise the missing allowlist line; deleting it to green the gate ships stale times.
- `main.no_await` is a substring match, so the word in a **comment** fails the build. Do not paste `examples/main.dart`'s annotations into the real file.
- `WidgetsBinding.instance` and `PlatformDispatcher.instance` are the SDK's and belong in `main.dart`/`app.dart`; the "one `.instance` in `lib/`" grep means one *non-framework* singleton.
- `reminderReconcilerProvider` is a `FutureProvider`, so resume reaches it via `.future`; `ref.read(p)` hands you the `AsyncValue`, not the reconciler.
- `kAppVersion`/`kAppBuild` come from `--dart-define`, not from a package (`13 §9.1.1`). A log line reading `0.0.0+0` means somebody built without the defines — that wrong-looking default is deliberate.

## Done when

- [ ] `lib/main.dart` matches `01 §6.1` — no `async`, no suspension, no `overrides`, no `retry:`, three handlers before `runApp()` — and `dart tool/check_policy.dart` exits 0.
- [ ] `NightErrorPanel` renders with no `MaterialApp`, `Theme`, `Directionality` or `MediaQuery` ancestor, proved by a widget test that pumps it bare.
- [ ] `LocalLog` accepts records before its directory is known and flushes them on `attachTo()`, proved by a unit test; it never writes an exception message.
- [ ] `shedFailureFrom` is tested for `SQLITE_FULL`, `SQLITE_IOERR`, `SQLITE_CORRUPT` and a `DriftRemoteException` wrapper, and no `userMessage` names a cause the result code does not prove.
- [ ] `UnexpectedFailure` is constructed at exactly two sites; grep proves it.
- [ ] `addObserver(this)`/`removeObserver(this)` are present; a widget test drives `hidden` → `resumed` and asserts the selection cleared, and another drives `inactive` and asserts the wakelock released.
- [ ] `ResumePolicy.staleAfter` is 2 minutes, with unit tests at 1 min 59 s and 2 min 0 s taking their instants from `appNow()`.
- [ ] A killed session leaves `clean: false`, produces exactly one `session.abnormal_termination` line in Settings ▸ Diagnostics, and changes no other app behaviour.
- [ ] Backgrounding 3 minutes and returning lands on Quick Entry with nothing selected, the in-flight lambing first in recents, its displayed time still the original captured one. By hand, once per release.
- [ ] A cold launch on both platforms in a genuinely dark room shows no white frame — no screenshot test can catch this, the flash is native.

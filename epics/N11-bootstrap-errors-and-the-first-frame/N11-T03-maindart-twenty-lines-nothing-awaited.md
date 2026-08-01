# N11-T03 — `main.dart` — twenty lines, nothing awaited

| | |
|---|---|
| **Epic** | [N11 — Bootstrap, errors and the first frame](epic.md) · `00-README` §9 step 4 (3 of 3) |
| **Task** | 3 of 9 |
| **Depends on** | N11-T02 |
| **Commit** | one commit · `feat(app): main.dart — nothing awaited, both handlers before runApp` |

## 1. Why this task exists

Decision #4, executable: `ensureInitialized()` → install both handlers → `runApp()`.
**Nothing is awaited**, there is no `runZonedGuarded`, and the database is opened after the first
frame. Every millisecond before `runApp` is a millisecond of white or black nothing on a phone in a
cold shed.

It is one of the five decisions `00-README` §4 says must be taken before commit #1, and it is the
only one of the five whose *implementation* is a single file. `01 §6.2`'s line-by-line table exists
because every line of this function has been written wrongly by somebody: an `await` above
`ensureInitialized()`, a `runZonedGuarded` wrapper, `overrides: [databaseProvider.overrideWithValue(db)]`,
`deferFirstFrame()`, `flutter_native_splash.preserve`, `if (kReleaseMode) exit(1)`. Each of those is
in the anti-pattern list and each has a named failure.

`main.dart` is also on `00-README` §10's **never waved through** list. However small a future diff to
this file is, it is read line by line — which is the other reason the file is twenty lines.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/01-architecture.md` | §6.1 (`lib/main.dart` printed in full — this is the file) · §6.2 (line by line, and why each line is there) · §6.3 (what happens after the first frame, and the anti-pattern list) · §5.5 (the three hooks and the three divergences from standard advice) · §3.2 (`main.no_await` as a rule row) | every line, in order, verbatim |
| `docs/engineering/13-build-ci-release.md` | §8.1 (why there is no crash reporter at all) · §8.2 (the two handlers, and why `onError` returns `true`) · §8.3 (the ring buffer before `attachTo`) | the handler bodies, and the log they write to |
| `docs/engineering/02-state-di-navigation.md` | §4.6 (the one deliberate static: `LocalLog.instance`, and why a provider cannot satisfy it) · §5.2 (production has no overrides) | why `LocalLog` is a singleton and `ProviderScope` is `const` with no `overrides` |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree: `main.dart` ~20 lines, awaits nothing, no overrides) · §1.1 `layer.root` · §3.5 (`LocalLog` is not in the provider graph) · R34, R52 | **BINDING**. `layer.root` is what stops `main.dart` opening the database itself |
| `docs/research/00-tech-decisions.md` | §1 #4 · #14 (the global error net) · #21 (bootstrap) · #123 (`LocalLog`, no analytics) · §5 for versions | the decision this file is |
| `docs/engineering/11-monetization-and-store.md` | §12.1 (`launch.store_call`) | `main.dart` and `app.dart` may not name `PurchaseService` |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-bootstrap-and-errors` | `main.dart` is its file and decision #4 is its rule |
| `shed-riverpod-providers` | the container's construction, and what may not happen before `runApp` |

The cap is two auto-firing skills. The anchor is a source-reading policy test, and `12 §1.4` — cited
in Sources — is the authority on what may be one; §5.4 writes the scan out, including the joined
string-literal trap that breaks a naive `contains`. `shed-testing` is therefore not reloaded.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/main_awaits_nothing_test.dart`
- **Test** — `'main() contains no await and installs both handlers before runApp'`
- **Why it is red today** — `main.dart` is `flutter create`'s and does nothing this project needs.

```bash
fvm flutter test test/policy/main_awaits_nothing_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. The test reads `lib/main.dart` as **text** —
not by running it — and asserts, in order: the file contains exactly one `void main()` and it is not
`Future<void> main()` and not `async`; the token `await ` does not appear anywhere in the file; the
index of `FlutterError.onError` and the index of `PlatformDispatcher.instance.onError` are both
**less than** the index of `runApp(`; `runZonedGuarded`, `exit(`, `deferFirstFrame`,
`flutter_native_splash` and `overrides:` appear nowhere; and `runApp(` is followed by
`const ProviderScope(`. Ordering by string index is what makes *"before `runApp`"* mechanical — a
test that only checked presence would pass on a file that installed the handlers afterwards, which is
the exact bug the rule exists to prevent.

**Green.** The minimum code that passes, and nothing beyond it — the twenty lines, both handlers, and a source-reading policy test — because the property
is about the *shape* of the function, not its behaviour.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Read this before you start, because it is the surprising part of this task.** A twenty-line
`main()` names three collaborators, and Dart does not compile a file whose imports do not resolve.
`make check` runs `flutter analyze --fatal-infos --fatal-warnings` and it is in this task's
Definition of Done, so *"the minimum code that passes"* here is `main.dart` **plus the smallest
compiling surface of each of the two collaborators that do not exist yet.** Say that in the commit
message; do not pretend the commit is one file.

| # | Path | What changes in it, and why |
|---|---|---|
| 1 | `test/policy/main_awaits_nothing_test.dart` | **New. The anchor, written first.** A source-text policy test — `12 §11.1` names a policy test for the property, not the file |
| 2 | `lib/core/log/local_log.dart` | **New, minimum surface.** `LocalLog.instance` (the one deliberate static in `lib/`, R52), a bounded in-memory ring buffer, and the two methods `main()` names: `void write(String event, Object error, StackTrace stack)` and `void flutterError(FlutterErrorDetails details)`. **T09 grows this file** into the redacted, rotating, `session.lock`-carrying log. Nothing here writes to disk yet, and the ring buffer is exactly why that is safe (`01 §5.5`: the directory is unknown until `path_provider` resolves after the first frame) |
| 3 | `lib/app.dart` | **New, minimum surface.** `class ShedBookApp extends ConsumerStatefulWidget` (R34) whose `build` returns a `MaterialApp` with the const `night` theme and an empty dark `Scaffold`. ~15 lines. **T05 grows this file** into the real thing — the boot kick, the delegates, the lifecycle observer and the a11y wrapper |
| 4 | `lib/main.dart` | **Replaced.** `flutter create`'s counter app goes; `01 §6.1`'s file arrives. Two of the three hooks land here; `ErrorWidget.builder` lands at **T04**, with the panel it renders |
| 5 | `tool/check_policy.dart` | **Only if N03 did not already land it.** `main.no_await` is `01 §3.2`'s row: `('main.no_await', 'await ', 'lib/main.dart', 'main() awaits nothing — #21')`. Check before you add — a duplicate rule is a rule that gets weakened twice (R54) — and if you do add it, add its `firesOn` entry to `test/policy/gate_rules_test.dart` in the same commit or N03-T07's inventory assertion fails |

No schema, no domain, no repository, no controller, no ARB entry. Say so in the commit message.

### 5.2 The signature

`01 §6.1`, verbatim, minus the third hook:

```dart
// lib/main.dart
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/log/local_log.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Framework errors: build, layout, paint.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);     // keeps the console output in debug
    LocalLog.instance.flutterError(details);
  };

  // 2. Everything outside the Flutter call stack: async gaps, platform channels.
  PlatformDispatcher.instance.onError = (error, stack) {
    LocalLog.instance.write('uncaught', error, stack);
    return true;                            // handled — do not kill the app
  };

  // 3. ErrorWidget.builder — N11-T04, with the panel it renders.

  runApp(const ProviderScope(child: ShedBookApp()));
}
```

The minimum `LocalLog` this task lands, so that T09 has something to grow rather than something to
replace:

```dart
// lib/core/log/local_log.dart — the minimum surface main() requires.
// T09 adds record(), attachTo(Directory), markCleanPause(), redaction,
// the 256 KB rotation and session.lock. See 13 §7 and §8.
final class LocalLog {
  LocalLog._();

  /// The ONE static-field singleton in lib/ (02 §4.6, R52). The three error
  /// handlers are installed in main(), before any ProviderScope exists, and
  /// must still work when the container has been torn down by the very failure
  /// being logged. A provider cannot satisfy that.
  static final LocalLog instance = LocalLog._();

  void write(String event, Object error, StackTrace stack) { /* ring buffer */ }
  void flutterError(FlutterErrorDetails details) { /* ring buffer */ }
}
```

### 5.3 The details that are easy to get wrong

- **`WidgetsFlutterBinding.ensureInitialized()` is not there because `runApp` needs it.** `runApp`
  calls it internally, so this line moves binding initialisation by microseconds. It is explicit for
  two reasons `01 §6.2` states: so the two handlers below are guaranteed to be installed against a
  live binding, and so that nobody later adds an `await` above it *"because the binding needed it"*.
  Deleting it looks like a simplification and removes the guard.
- **`PlatformDispatcher.instance.onError` returns `true`, and the return value is the whole point.**
  `false` forwards to the platform's default handler, which on some platforms terminates the process.
  At 3am the committed data matters more than the process. A handler that returns `false` compiles,
  analyses clean, and kills the app in a cold shed.
- **There is no `runZonedGuarded` and adding one is a regression, not a belt-and-braces improvement.**
  `PlatformDispatcher.instance.onError` covers the same root-isolate ground; Flutter's own
  error-handling page demonstrates the complete setup without it; and a zone/binding mismatch is a
  documented footgun (flutter#94123 — the framework does not warn when `ensureInitialized` runs in a
  different zone than `runApp`). The genuine gap is child isolates, and this app never uses raw
  `Isolate.spawn`: `Isolate.run` and `compute` rethrow into the caller.
- **`ErrorWidget.builder` is set once, here, and never inside a `build()`.** Reassigning a global
  during layout is a race with whatever is currently rendering. It lands at T04 rather than here
  because it names `NightErrorPanel`, and a `main.dart` referencing a widget that does not exist does
  not compile. T03's anchor test says *"both handlers"* — two — and it means two; T04 extends the
  same test to require three.
- **`const ProviderScope(child: ShedBookApp())` has no `overrides` and no `retry:`.** Production has
  zero overrides (`02 §5.2`) — there is nothing to override because nothing is constructed before
  `runApp`. And `retry:` is a **Riverpod 3 parameter that does not exist on 2.6.1**: it is a compile
  error, it is a `check_policy` row (`rp3` namespace), and there is no auto-retry to disable. Any
  snippet you copy from a tutorial published after 2025 will have it.
- **`layer.root` is what stops the obvious shortcut.** `lib/main.dart` and `lib/app.dart` may not
  import `lib/core/db/`, `package:drift/*` or `package:sqlite3*`. So `main()` *cannot* call
  `openAppDatabase()` even if you wanted it to — which is the mechanism behind "the database is not
  opened in `main()`", and it is stronger than the convention. The open is kicked from a post-frame
  callback through a provider, at T05.
- **`launch.store_call` bans `PurchaseService` and `purchase_service.dart` from these two files.**
  Nothing about the first frame may depend on entitlement (decision #90). The failure mode is a
  paywall flash at 3am.
- **`FlutterError.presentError(details)` stays.** Without it the debug console goes quiet and every
  framework error becomes invisible during development while looking correctly handled. `13 §8.2`
  also notes that exceptions thrown by the handler *itself* are not caught, which is why every
  `LocalLog` method swallows.
- **A `LocalLog` that writes to disk in `main()` is the mistake this ordering exists to prevent.**
  The handlers are installed synchronously in `main()`, but the diagnostics directory is not known
  until `path_provider` resolves after the first frame. So `LocalLog` starts in **memory-only mode
  with a bounded ring buffer** and flushes when `attachTo(directory)` is called during post-frame
  boot (T09). Resolving a directory here would mean an `await`, which is the one thing this file may
  not contain.
- **`.instance` is a grep, and this file creates the only legitimate hit.** `02`'s Definition of Done
  says: grep `\.instance\b`; every hit other than `LocalLog.instance` is a defect.
  `WidgetsBinding.instance` and `PlatformDispatcher.instance` are the SDK's, and they live in exactly
  these two files.
- **`test/policy/` is the right home and the assertion is a source scan, which normally belongs in
  the gate.** `12 §1.4` is explicit: *"if the assertion can be made by reading source text, it
  belongs in `tool/check_policy.dart`."* The `await ` half **is** a gate row (`main.no_await`). What
  the test adds and the gate cannot is the **ordering** assertion — a rule table matches patterns,
  not relative positions — so the two coexist and the test names the property the gate cannot.

### 5.4 The full test set

`test/policy/main_awaits_nothing_test.dart` — a source-text test. No `pumpWidget`, no binding, no
database. It reads `File('lib/main.dart').readAsStringSync()` once and asserts against it.

| Case | What it asserts |
|---|---|
| `'main() contains no await and installs both handlers before runApp'` | **The anchor.** `void main()` exactly once, not `async`, not `Future<void>`; the token `await ` absent; `indexOf('FlutterError.onError')` and `indexOf('PlatformDispatcher.instance.onError')` both `< indexOf('runApp(')` |
| `'main.dart contains no banned bootstrap call'` | None of `runZonedGuarded`, `deferFirstFrame`, `flutter_native_splash`, `exit(`, `WidgetsBinding.instance.deferFirstFrame`, `overrides:`, `retry:` appears. One assertion per token so the failure names which one |
| `'PlatformDispatcher.instance.onError returns true'` | The handler body contains `return true;` and no `return false;`. The difference is whether the process survives |
| `'runApp receives a const ProviderScope and nothing else'` | `runApp(const ProviderScope(child: ShedBookApp()))`, matched as a whole. Catches a lost `const`, an added `overrides:`, and a second child |
| `'main.dart imports nothing from lib/core/db/, drift or sqlite3'` | `layer.root` as a test as well as a gate row, because this file is the one somebody will "just open the database in" |
| `'main.dart names no store or purchase symbol'` | `PurchaseService`, `purchase_service.dart`, `InAppPurchase` all absent — `launch.store_call`, decision #90 |
| `'LocalLog.instance is the only non-SDK static instance in lib/'` | Walks `lib/**/*.dart` (skipping generated), greps `\.instance\b`, and asserts every hit is `LocalLog.instance`, `WidgetsBinding.instance` or `PlatformDispatcher.instance`. The property `02`'s Definition of Done asks for, written where it is first true |
| `'the file is under 30 lines of body'` | Not a style rule: `01 §6.1` says twenty lines of body and `00-README` §10 puts this file on the never-waved-through list. A number here is what makes growth visible in a diff rather than gradual |

**Nothing in this task is time-shaped**, so no `test/domain/uk_zone/` case and no `@Tags(['uk-zone'])`.

## 6. Constraints that bind this task

- **3am** — the whole task is the fifteen-second clause of the 3am test. `main()` awaiting anything
  converts the fixed cost of a dark first frame into a variable wait on the disk, which is precisely
  what `01 §6.3` exists to prevent.
- **Offline** — no network path may be added. G2 and G3 stay green. This file adds no dependency, and
  `13 §8.1` is why there is no crash reporter in it: **there is no "just crash reports, no PII"
  configuration that satisfies spec §4.5, because the transmission itself is the violation.**
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'main() contains no await and installs both handlers before runApp'` passes, and was seen to fail first for the stated reason
- [ ] no `await` in `main()`
- [ ] `FlutterError.onError` and `PlatformDispatcher.instance.onError` both installed before `runApp`
- [ ] no `runZonedGuarded`
- [ ] the database is not opened in `main()`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `PlatformDispatcher.instance.onError` returns `true`, and `FlutterError.presentError` is still called
- [ ] `runApp` receives `const ProviderScope(child: ShedBookApp())` — no `overrides`, no `retry:`
- [ ] `main.dart` names no `PurchaseService`, no `InAppPurchase`, and nothing under `lib/core/db/`
- [ ] `LocalLog.instance` is the only non-SDK `.instance` in `lib/`
- [ ] the commit message states that `app.dart` and `local_log.dart` land here as minimum compiling surfaces, and names T05 and T09 as the tasks that grow them
- [ ] if `main.no_await` was added to `tool/check_policy.dart` here, its `firesOn` entry landed in the same commit

## 8. Verification

```bash
fvm flutter test test/policy/main_awaits_nothing_test.dart
make check
make test
```

Then confirm by hand, because this file is on the never-waved-through list:

```bash
grep -c "await" lib/main.dart          # expect 0
wc -l lib/main.dart                    # expect ~25 including imports
grep -rn "\.instance\b" lib/ --include='*.dart' | grep -v '\.g\.dart'
# expect only LocalLog.instance, WidgetsBinding.instance, PlatformDispatcher.instance

fvm flutter run --debug                # the app starts and paints a dark, empty frame
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(app): main.dart — nothing awaited, both handlers before runApp`

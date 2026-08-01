# N11-T05 — `app.dart` — `ShedBookApp`, the boot kick, and the localisations

| | |
|---|---|
| **Epic** | [N11 — Bootstrap, errors and the first frame](epic.md) · `00-README` §9 step 4 (3 of 3) |
| **Task** | 5 of 9 |
| **Depends on** | N11-T04 |
| **Commit** | one commit · `feat(app): ShedBookApp, the post-frame boot kick and the localisations` |

## 1. Why this task exists

`ShedBookApp` as a `ConsumerStatefulWidget`, the **post-frame** boot kick that opens the
database after the first frame, `ResumePolicy`, and the `localizationsDelegates` / `supportedLocales`
wiring the old plan never gave to any task. Also the `accessibility_tools` debug wiring — decision
#100's declared dev dependency that nothing installed. Critique gaps G3 and G4.

This is the largest task in the epic and the one with the most cross-document surface, because
`app.dart` is where four documents meet: `01 §6.3` owns the boot kick, `02 §9.1` owns the lifecycle
observer and the resume policy, `06 §2.1` owns the theme half of `build()`, and `10 §8.2` owns the
localisation block. None of them owns the *file*; this task assembles it.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/01-architecture.md` | §6.3 (the post-frame boot kick, printed; the table of what happens after the first frame; the anti-pattern list) · §5.6 (what a failed `databaseProvider` becomes — and why `RecoveryScreen` is not this task) | `initState`'s callback, and the one line inside it |
| `docs/engineering/02-state-di-navigation.md` | §9 (why there is no state restoration — decision #24, and the 03:20 → 03:41 worked example) · §9.1 (`ResumePolicy`, `_ShedBookAppState` printed in full, **the five details that are not stylistic**) · §9.2 (what the app owes the user on resume) · §4.6 (`LocalLog.instance` is not a provider) · §5.1 (the DI graph) | the `State`, the observer, the switch, `staleAfter` |
| `docs/engineering/06-design-system.md` | §2.1 (`MaterialApp` printed in full — four theme slots, `themeMode`, `color`, `themeAnimationDuration`) · §9.3 (`SystemChrome.setSystemUIOverlayStyle` from the first frame) | the theme half of `build()`, verbatim |
| `docs/engineering/10-accessibility-and-i18n.md` | §8.2 (the `MaterialApp` localisation block, printed) · §8.3 (**the `supportedLocales` ordering trap** — first-wins resolution) · §7.3 (`locale_resolution_test.dart`) · §6 (`accessibility_tools`: it wraps the tree, so `lib/` imports it; wire it behind `kDebugMode`) | the delegates, the locale list, the a11y wrapper |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree: `app.dart` = theme + post-frame boot kick + `WidgetsBindingObserver`) · §1.1 `layer.root` · §3.1 (`databaseProvider`) · R29 (`themeProvider` is synchronous, `night` is its not-yet-loaded arm) · R34 (`ShedBookApp` is a `ConsumerStatefulWidget`) | **BINDING** on the widget kind, the provider names and what this file may import |
| `docs/research/00-tech-decisions.md` | §1 #4 · #21 (the first frame is a static dark Quick Entry shell) · #24 (no state restoration) · #79 (wakelock released on any non-resumed state) · #90 (the first frame is entitlement-agnostic) · #100 (`accessibility_tools` 2.8.0) · #108 (gen-l10n from day one, `en` only) · §5 for versions | every decision this file executes |
| `epics/00-PLAN-CRITIQUE.md` | §8 G3 (the ARB is never bootstrapped — *"no task wires `localizationsDelegates` / `supportedLocales`"*) · §8 G4 (`accessibility_tools` — *"a declared dev dependency nothing installs"*) | the two gaps this task closes |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-bootstrap-and-errors` | `app.dart`, the lifecycle and the resume policy are its subject |
| `shed-riverpod-providers` | the 2.6.1 spellings, and why `databaseProvider` is a `FutureProvider` read through `.future` |

The cap is two. The localisation delegates, their ordering trap and the debug accessibility tooling
are `shed-accessibility-and-copy`'s; they are not reloaded because §5.2 prints the delegate list in
the one order that works, names `accessibility_tools` 2.8.0 as debug-only and behind `kDebugMode`, and
§5.3 states what breaks when the order is wrong.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/app_test.dart`
- **Test** — `'the database is opened after the first frame and AppLocalizations resolves the ARB's first string'`
- **Why it is red today** — there is no `app.dart`; nothing pumps a themed tree and nothing resolves an ARB string.

```bash
fvm flutter test test/features/app_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. *After the first frame* is an ordering claim,
so prove it with ordering: override `databaseProvider` with an override that records the frame count
at the moment it is first read, `pumpWidget(UncontrolledProviderScope(container: c, child: const
ShedBookApp()))`, assert the open has **not** been requested after the synchronous `pumpWidget`
returns, then `await tester.pump()` and assert it has. The localisation half is the same test's
second act: find the `MaterialApp`, take a descendant `BuildContext`, and assert
`AppLocalizations.of(context).withdrawalSource(days: 7)` returns the ARB string N01-T03 authored —
with no `!`, because `l10n.yaml` sets `nullable-getter: false`.

**Green.** The minimum code that passes, and nothing beyond it — the widget, the post-frame callback, the delegates, and the debug-only accessibility
wrapper.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

§8's wiring step (13) and UI step (18) both land here; the ARB step (22) does **not** — N01-T03
already created `lib/l10n/app_en.arb` with its first string, and this task is what finally makes that
string reachable from a widget. No schema, no domain, no repository, no controller. Say so in the
commit message.

| # | Path | What changes in it, and why |
|---|---|---|
| 1 | `test/features/app_test.dart` | **New. The anchor, written first.** |
| 2 | `lib/data/providers.dart` | **New, one entry only** — `databaseProvider`. See §5.3: `app.dart` cannot open the database itself, and N12-T01 grows this file into the DI root |
| 3 | `lib/app.dart` | **Grown** from T03's shell. `ShedBookApp` + `_ShedBookAppState` with `WidgetsBindingObserver`, `initState`'s post-frame kick, `dispose`, `didChangeAppLifecycleState`, the full `MaterialApp`, and the top-level `ResumePolicy` class |
| 4 | `pubspec.yaml` | **Confirmed, not edited** — `accessibility_tools: 2.8.0` is already a `dev_dependency` (decision #100). Read the line; do not bump it |
| 5 | `tool/policy_allowlist.txt` | **`[dev_dependencies]` section**: confirm `accessibility_tools` is listed. `10 §6` flags the unusual part — **it is a widget that wraps the app tree, so `lib/` imports a dev dependency**, and G2 scans direct dependencies. If the allowlist does not carry it, the gate goes red the moment `app.dart` imports it |
| 6 | `test/features/locale_resolution_test.dart` | **New.** `10 §7.3`'s three cases. It is a separate file because the property is about `supportedLocales` ordering, not about `ShedBookApp` |

### 5.2 The signatures

The widget, assembled from `06 §2.1`, `01 §6.3` and `02 §9.1` — each of which prints its own half:

```dart
// lib/app.dart
class ShedBookApp extends ConsumerStatefulWidget {          // R34 — not ConsumerWidget
  const ShedBookApp({super.key});
  @override
  ConsumerState<ShedBookApp> createState() => _ShedBookAppState();
}

class _ShedBookAppState extends ConsumerState<ShedBookApp>
    with WidgetsBindingObserver {
  Instant? _hiddenAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);              // 02 §9.1 detail 1
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(databaseProvider.future).ignore();           // 01 §6.3
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { /* §5.3 */ }

  @override
  Widget build(BuildContext context) => MaterialApp(/* §5.2 continued */);
}

/// Pure, no Riverpod, no BuildContext — so it is a unit test, not a widget test.
/// The parameters are `Instant`, not `DateTime`: the only wall-clock reader in
/// the app is `appNow()` and it returns an `Instant` (R23).
class ResumePolicy {
  static const staleAfter = Duration(minutes: 2);

  static bool shouldClearSelection(Instant hiddenAt, Instant resumedAt) =>
      resumedAt.difference(hiddenAt) >= staleAfter;
}
```

The `MaterialApp`, with `06 §2.1`'s theme half and `10 §8.2`'s localisation half in one call:

```dart
MaterialApp(
  title: 'Shed Book',                       // a product name, never localised
  // ---- theme (06 §2.1). All four slots, so no platform event can select light.
  theme: t.theme,
  darkTheme: t.theme,
  highContrastTheme: t.highContrast,
  highContrastDarkTheme: t.highContrast,
  themeMode: ThemeMode.dark,
  color: t.theme.scaffoldBackgroundColor,   // painted behind the app before route 1
  themeAnimationDuration: Duration.zero,    // a 200 ms lerp drags every colour
                                            // through a desaturated midpoint
  // ---- localisation (10 §8.2). Critique gap G3 — no task owned this line.
  localizationsDelegates: const <LocalizationsDelegate<Object>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const <Locale>[
    Locale('en'),                           // MUST be first — 10 §8.3
    Locale('en', 'GB'),
    Locale('en', 'IE'),
  ],
  // ---- N13 fills these two in: navigatorKey: Routes.navigatorKey,
  //      home: const QuickEntryScreen().
  home: const _BootShell(),
  builder: (context, child) => kDebugMode
      ? AccessibilityTools(child: child)    // 10 §6 — debug only, never release
      : child!,
)
```

The lifecycle switch, `02 §9.1` verbatim in shape — with the two arms that cannot run yet marked, not
deleted:

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  // Decision #79: released on ANY non-resumed state, not just `hidden`.
  // wakelockProvider is N12-T01's; until then this line is absent and its
  // absence is named in the commit message, not silently omitted.
  if (state != AppLifecycleState.resumed) { /* ref.read(wakelockProvider).release(); */ }

  switch (state) {
    case AppLifecycleState.hidden:
      // `hidden` is synthesised on both platforms and is the last state you are
      // guaranteed to observe — the only safe place to record a clean pause.
      _hiddenAt = appNow();
      LocalLog.instance.markCleanPause();          // T09 lands the method
    case AppLifecycleState.resumed:
      final hiddenAt = _hiddenAt;
      if (hiddenAt != null &&
          ResumePolicy.shouldClearSelection(hiddenAt, appNow())) {
        // quickEntryControllerProvider is N13's; Routes is N13-T01's.
      }
      _hiddenAt = null;
      // ref.invalidate(minuteTickProvider)  — N12-T03
      // reminderReconcilerProvider…reconcile() — N24
    case _:
      break;
  }
}
```

And the one-provider file:

```dart
// lib/data/providers.dart — N12-T01 grows this into the DI root.
final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await openAppDatabase();      // lib/core/db/connection.dart (R2, R12)
  ref.onDispose(db.close);
  return db;
});
```

### 5.3 The details that are easy to get wrong

- **`app.dart` cannot open the database, and that is a gate, not a preference.** `layer.root`:
  *"`lib/main.dart` and `lib/app.dart` may not import `lib/core/db/`, `package:drift/*` or
  `package:sqlite3*`."* So `ref.read(databaseProvider.future)` is not one option among several — it
  is the only legal shape, and it means **`databaseProvider` must exist at this task**.
  `CONVENTIONS §3.1` and N12-T01 both own `lib/data/providers.dart`; the resolution is that this task
  creates the file with **exactly one entry** and N12-T01 grows it. Say that in the commit message
  and carry it into the PR body, because it is a scope change to a later epic.
- **`themeProvider` is *not* created here, and taking the const `night` pair directly is the correct
  minimum.** R29 makes `themeProvider` a synchronous `Provider<ShedThemeSet>` whose not-yet-loaded
  arm is *the const `night` pair*, derived from `settingsProvider` — which needs `SettingsRepository`,
  which is N12-T02. So `build()` resolves `buildShedTheme(resolvePalette(ShedPaletteId.night))`
  directly. N12-T02's change is then one line, and because every palette is dark, the later swap is
  invisible rather than a flash. Do **not** invent a placeholder `themeProvider` here: two
  declarations of the same provider name is exactly the drift `CONVENTIONS §3` exists to prevent.
- **`addObserver(this)` in `initState` and `removeObserver(this)` in `dispose`. This is the single
  highest-value line in the file.** `with WidgetsBindingObserver` alone compiles,
  `didChangeAppLifecycleState` looks like a valid override, and it is **never called**. That is the
  failure mode where the resume policy, the wakelock release and the clean-pause marker all silently
  stop existing and no test, lint or analyzer notices. `02 §9.1` lists it first of five for that
  reason, and the test that catches it is the one that drives `hidden` → `resumed` and asserts an
  effect.
- **`.ignore()` is `dart:async` and it is deliberate, not a slip.** It marks the future as
  intentionally unawaited; a failure still surfaces through `databaseProvider`'s `AsyncError`
  downstream (`01 §5.6`). `await`ing it here would defeat the whole decision, and dropping the
  `.ignore()` earns an analyzer info — which `--fatal-infos` turns into a CI failure.
- **`Locale('en')` must be first, and getting it wrong is invisible until an export is misread.**
  `WidgetsApp.basicLocaleListResolution` builds its lookup maps **first-wins**
  (`languageLocales[locale.languageCode] ??= locale`). `[Locale('en','GB'), Locale('en'), …]` gives
  *every English speaker on earth* British date formats; `[Locale('en')]` alone gives a UK phone US
  formats and a Sunday week start. And `MaterialApp.supportedLocales` **defaults to
  `[Locale('en','US')]`**, so leaving it unset is the same bug wearing a different hat. That is why
  `locale_resolution_test.dart` exists and why it has three cases, not one.
- **Set `supportedLocales` explicitly, never from `AppLocalizations.supportedLocales`.** The
  generated list is ordered by the ARB files present, which is one file, which is `en` — and the
  ordering property above is then an accident that a second ARB would silently break.
- **`accessibility_tools` is a dev dependency that `lib/` imports, which is unusual and is the reason
  it needs an allowlist entry.** `10 §6`: it is a *widget that wraps the app tree*. Wire it in
  `MaterialApp.builder` behind `kDebugMode`, add it to `tool/policy_allowlist.txt`'s
  `[dev_dependencies]` section, and remember **its 48 × 48 default is below this app's 60/64 floor** —
  it complements the house assertion and never replaces it. Wiring it in `runApp` or above
  `MaterialApp` puts it outside `Directionality` and it will throw in debug.
- **`MaterialApp.builder`'s `child` is nullable and the release arm must not crash on it.**
  `child!` in the release branch is correct here — `MaterialApp` always supplies one when `home` is
  set — but write the ternary so the debug arm is the one that wraps, not the one that unwraps.
- **`home:` is a placeholder and must look like one.** `06 §2.1` prints `home: const
  QuickEntryScreen()` and that screen is **N13-T05**. Land a private `_BootShell` — a dark
  `Scaffold` with nothing in it, in this file — and let N13-T05 replace the one line. Do **not** put
  a spinner in it: `02 §4.5` rule 1, *a spinning white ring under a head torch is a flashbang*.
  Likewise `navigatorKey: Routes.navigatorKey` waits for N13-T01, because `lib/routing/routes.dart`
  does not exist yet.
- **`ResumePolicy` is a top-level class in `app.dart`, not a file of its own.** `02 §9.1` places it
  there deliberately: *"there is no separate lifecycle file."* It is pure — no Riverpod, no
  `BuildContext` — so it is unit-testable, which is the only reason the 2-minute boundary can be
  tested at 1 min 59 s and 2 min 0 s without pumping a widget.
- **`staleAfter` is 2 minutes and the reason is a data-integrity bug, not a UX preference.** `02 §9`'s
  worked example: at 03:20 the shepherd selects 412 and is interrupted; at 03:41 they reopen, see
  "412" still selected, tap "Twin", and ewe 128's lambing is filed against 412. Clearing the
  selection destroys nothing **only because** every write commits immediately — the two decisions
  must be read together.
- **`appNow()`, never `DateTime.now()`.** `time.dart_clock` allowlists exactly one file,
  `lib/core/time/app_clock.dart`. Both instants in the lifecycle switch come from `appNow()`, which
  is what lets a test move time with `withClock`.
- **There is no `restorationScopeId`, no `RestorationMixin`, no `Restorable*`.** Decision #24, and
  CI greps for all of them. The reason is correctness: the database *is* the restored state, so
  adopting restoration would mean reintroducing a draft to serialise — the thing spec §5 forbids.
- **Nothing here reads `entitlementProvider`.** Decision #90: the first frame is
  entitlement-agnostic, and `launch.store_call` bans `PurchaseService` from this file outright. The
  failure mode is a paywall flash at 3am.
- **`SystemChrome.setSystemUIOverlayStyle` is set once, from the first frame** (`06 §9.3`), with
  `statusBarIconBrightness: Brightness.light` (Android), `statusBarBrightness: Brightness.dark` (iOS
  — it describes the *background*, which is the one people invert) and
  `systemNavigationBarIconBrightness: Brightness.light`.
- **`flutter: generate: true` means gen-l10n re-runs on every `flutter run` and `flutter build`.**
  Finish with `git diff --exit-code -- lib/l10n/` before committing, or the `codegen` job fails on a
  file you never opened.

### 5.4 The full test set

`test/features/app_test.dart` — widget tests, built with an inline `ProviderContainer` +
`UncontrolledProviderScope`. **`pumpApp` does not exist yet** (N12-T05, and it builds only what
exists), so this file constructs its own container and registers `addTearDown(container.dispose)`
itself — 2.6.1 does not do it for you, and there is no `ProviderContainer.test()`.

| Case | What it asserts |
|---|---|
| `'the database is opened after the first frame and AppLocalizations resolves the ARB's first string'` | **The anchor.** The override recording the open is untouched immediately after `pumpWidget` returns and touched after one `pump()`; and `AppLocalizations.of(context).withdrawalSource(days: 7)` returns N01-T03's string, with no `!` |
| `'the observer is registered — a hidden → resumed cycle clears the selection'` | Drive `tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden)` then `.resumed` with more than `staleAfter` between them, and assert the effect. **This is the test that proves `addObserver` was called at all** |
| `'a hidden → resumed cycle under two minutes keeps the selection'` | The other side of the boundary, so the policy is not vacuously "always clear" |
| `'ResumePolicy.shouldClearSelection is false at 1 min 59 s and true at 2 min 0 s'` | A pure unit case on the boundary. No widget, no pump |
| `'ResumePolicy measures absolute time across the ambiguous hour'` | `@Tags(['uk-zone'])`, `TZ=Europe/London`. Hidden at **01:59 BST on 25 Oct 2026**, resumed at **01:01 GMT** — the wall clock reads *earlier* while two real minutes have passed, so the policy must return **true**. A civil-time implementation returns a negative duration and silently keeps a stale selection through the one hour of the year that happens twice, in late October, six weeks before lambing |
| `'the wakelock is released on inactive, not only on hidden'` | Decision #79. **Deferred to N12-T01 with a named `// TODO(N12-T01)` beside the commented line** and stated in the commit message — `wakelockProvider` does not exist yet, and a test asserting nothing is worse than a documented gap |
| `'no database work happens before the first frame'` | The negative form of the anchor, asserted against the whole first frame rather than one provider: no `AsyncData` anywhere in the container after `pumpWidget` returns synchronously |
| `'every theme slot is dark and themeMode is ThemeMode.dark'` | All four slots, plus `MaterialApp.color` equal to `scaffoldBackgroundColor`, plus `themeAnimationDuration == Duration.zero` |
| `'accessibility_tools wraps the tree in debug and not in release'` | `kDebugMode` is a compile-time const, so assert the debug shape here and prove the release shape by source text: the import and the widget appear in exactly one file and inside exactly one `kDebugMode` ternary |
| `'app.dart imports nothing from lib/core/db/, drift or sqlite3'` | `layer.root`, as a test as well as a gate row |
| `'app.dart names no store or entitlement symbol'` | `launch.store_call` and decision #90 |
| `'there is no restorationScopeId, RestorationMixin or Restorable* in lib/'` | Decision #24, asserted where it is first tempting |

`test/features/locale_resolution_test.dart` — `10 §7.3`'s three cases:

| Case | What it asserts |
|---|---|
| `'a device set to en-GB resolves to en_GB'` | `d MMM y`, Monday-first, 24-hour |
| `'a device set to en-US resolves to en, not en_GB'` | The first-wins consequence: `Locale('en')` leading is what stops British formats reaching everyone |
| `'a device set to fr resolves to en'` | The fallback, and it must not throw |

## 6. Constraints that bind this task

- **3am** — the first frame is a static dark shell with no data and, once N13 lands, a fully
  interactive keypad. Nothing is awaited before it paints, nothing spins, and nothing
  monetization-related renders at any entitlement state (decision #90).
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies. This task is where the ARB becomes *reachable* — critique gap G3 — and where `accessibility_tools` starts flagging the rest live in debug — gap G4.
- **The five safety rules** — §12.5 is why the resume path must **never re-stamp** an in-flight
  lambing's `RecordedTime`: the honest time is 03:20, not 03:41. Provenance is a property of the row,
  not of the session (`02 §9.2`).
- **Offline** — no network path may be added. G2 and G3 stay green. `flutter_localizations` bundles
  its CLDR data as generated Dart and `intl` ships its own: no asset download, no HTTP, no
  permission (`10 §8.2`).
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the database is opened after the first frame and AppLocalizations resolves the ARB's first string'` passes, and was seen to fail first for the stated reason
- [ ] no database work happens before the first frame
- [ ] `AppLocalizations` resolves and the ARB is reachable from a widget
- [ ] `accessibility_tools` is wired in debug only and never in release
- [ ] `ResumePolicy` is exercised by a lifecycle test
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `WidgetsBinding.instance.addObserver(this)` is in `initState` and `removeObserver(this)` in `dispose`, and a widget test drives `hidden` → `resumed` and asserts the effect
- [ ] `supportedLocales` lists bare `Locale('en')` **first**, is set explicitly, and `locale_resolution_test.dart` passes all three cases
- [ ] `ResumePolicy` has cases at 1 min 59 s, 2 min 0 s **and** across the ambiguous hour, the last tagged `uk-zone`
- [ ] `lib/data/providers.dart` holds **exactly one** provider, and the commit message names N12-T01 as the task that grows it
- [ ] no `themeProvider` is declared here; the theme comes from the const `night` pair, per R29
- [ ] `app.dart` imports nothing under `lib/core/db/`, no drift, no sqlite3, no `PurchaseService`
- [ ] `git diff --exit-code -- lib/l10n/` is clean before the commit
- [ ] every arm deferred to a later epic carries a `// TODO(<task-id>)` naming that task, and the commit message lists them

## 8. Verification

```bash
fvm flutter test test/features/app_test.dart
fvm flutter test test/features/locale_resolution_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
git diff --exit-code -- lib/l10n/        # gen-l10n re-runs on every build
```

Then by hand, on a device, because two of these are not observable in a test:

```bash
fvm flutter run --debug
# 1. The app paints a dark frame immediately; nothing spins.
# 2. accessibility_tools' checker button is visible in debug.
# 3. Background the app for three minutes and return: it comes back to a dark
#    frame, and nothing in the diagnostics ring buffer says the DB reopened.
fvm flutter run --release
# 4. The accessibility_tools overlay is gone. If it is not, the kDebugMode
#    ternary is on the wrong branch.
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(app): ShedBookApp, the post-frame boot kick and the localisations`

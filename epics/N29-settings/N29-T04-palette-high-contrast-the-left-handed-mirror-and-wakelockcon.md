# N29-T04 — Palette, high contrast, the left-handed mirror, and `WakelockController`

| | |
|---|---|
| **Epic** | [N29 — Settings](epic.md) · `00-README` §9 step 10 (4 of 4) |
| **Task** | 4 of 8 |
| **Depends on** | N29-T03 |
| **Commit** | one commit · `feat(settings): appearance settings and the WakelockController gateway` |

## 1. Why this task exists

The appearance settings — plus the **`WakelockController` gateway and its fake**, which the
old plan described as a setting and never gave a seam. Default **off**, with a 30-minute expiry, because
a wakelock left on flattens a phone in a shed at 4am, which is the failure this setting is meant to
prevent.

Four sections in one commit because they are four rows over four columns that already exist —
`palette`, `high_contrast`, `wakelock_enabled`, `left_handed` — and because splitting the wakelock's
*row* from the wakelock's *seam* is exactly the mistake the old plan made. `00-PLAN-CRITIQUE` §8 G4:
*"`WakelockController` gateway + its fake — the seventh of `12 §4.2`'s seven fakes. **E26-T04 describes
the setting, never the seam.**"*

Everything the appearance rows write is already resolvable. Six palettes were authored in N09
(`3 palettes × 2 contrast levels`, every one a literal constructor call); `resolvePalette(id,
highContrast:)` is an exhaustive `switch` over `(enum, bool)`; `themeProvider` has been synchronous
since N12-T02, with the `const night` pair as its not-yet-loaded arm. `left_handed` already mirrors
`ShedKeypad`'s bottom row (N13-T04) and the bottom action bar. What is missing is the four controls —
and the object that turns `wakelock_enabled = 1` into a screen that stays on.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/08-platform-integration.md` | **§7** (the wakelock: the reason, decision #79's split, **the class printed in full**, `sessionExpiry`, the idempotent `acquire()`, the unconditional `release()`) · **§7.1** (the three necessary conditions; the six routes it may never be held on, **Settings among them**) · **§7.2** (where `acquire()` is called from: one `NavigatorObserver` in `lib/app.dart`, never a screen's `initState`) · **§7.3** (the four gates) · §1.1–§1.2 (the gateway pattern and `layer.plugin_*`) · §8.3 (`WAKE_LOCK` is already merged by `wakelock_plus`) | the seam, its fake and its expiry |
| `docs/engineering/06-design-system.md` | **§4.1** (six palettes, `resolvePalette`, `shedPalettes`, and the **four Settings labels, verbatim**) · §4.2–§4.4 (the three palettes and their measured ratios) · §2.1 (`themeProvider` is synchronous) · §8.2 (**`leftHanded` mirrors the bottom row only**) · §9 (dark only; no light theme reachable) · §12 (the component inventory) | the palettes, the high-contrast variants and the mirror |
| `docs/engineering/07-screens.md` | **§14.3 row 6** (Appearance: *"**two independent controls, not one three-way choice**"*; the stored key is byte-identical to `ShedPaletteId`'s; High contrast *"selects a real higher-contrast palette and is not an alias of the night one"*) · **row 7** (Keep screen on: default off, session-scoped, 30-minute auto-expiry) · **row 8** (Left-handed layout: mirrors the keypad's bottom row and the bottom action bar) · §20 rule 4 | which controls, and what they may not be |
| `docs/engineering/CONVENTIONS.md` | **§2.12** (`WakelockController` · `lib/data/wakelock_controller.dart` · wraps `wakelock_plus` · `acquire()` / `release()` — **R9**) · §3.1 (`wakelockProvider : Provider<WakelockController>` — the name is `wakelockProvider`, **not** `wakelockControllerProvider`, a documented §4.3 exception) · §2.11 (`ShedPaletteId`, `ShedThemeSet`, `context.tokens`) · §2.9 + **R35** (`night`→`'night'`, `amber`→`'amber'`, `deepRed`→**`'red'`**) · §4.5 + R59 | **BINDING** on the class, the file, the provider and the keys |
| `docs/engineering/03-data-model-and-schema.md` | §5.13 (`palette` `CHECK IN ('night','amber','red')` — **no `dark`**; `high_contrast`, `wakelock_enabled`, `left_handed`, all boolean, all defaulting false) | the four columns |
| `docs/engineering/12-testing.md` | **§4.2** (the seven fakes; `FakeWakelockController` records `int acquired` / `int released` and **trips on a `release()` without a matching `acquire()`**) · **§4.4** (where `mocktail` earns its keep — the printed `wakelock_scope_test.dart` using `verifyNever`) · §5.1 (`pumpApp` and its override list) | the fake and its tripwire |
| `docs/engineering/02-state-di-navigation.md` | **§9.1** (the lifecycle release: `if (state != AppLifecycleState.resumed) ref.read(wakelockProvider).release();`) · §8.1 (`RouteSettings(name:)`) · §5.1 (the DI graph) | where the release is wired |
| `docs/research/00-tech-decisions.md` | **#79** (`wakelock_plus` **1.7.0** — default-off, session-scoped, 30-minute expiry) · #95 (the `#0B0D0E` base) · #96 (the four Settings labels) · #106 (colour is never the only channel) · #113 (the widget-test binding's clock advances) · §5 for the version | the decision and the version |
| `docs/design/indelible.md` | §8 screen 12 (theme controls, and `WRITING HAND · RIGHT / LEFT` *"mirrors the slab and the index button and states that the margin does not move"*) · §2.6 (the red-shift variant is nearly a no-op **by construction** — nothing was ever encoded by hue) | the controls' shape |
| `epics/00-PLAN-CRITIQUE.md` | **§8 G4** (the gateway and its fake are unowned) | why the seam is here |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | the wakelock seam, its fake and its expiry |
| `indelible-design-system` | the palettes, the high-contrast variants and the mirror |

`CLAUDE.md` allows **two** auto-firing skills per intent and this task uses both. The fake's shape and
its tripwire are `12 §4.2`'s and the `verifyNever` case is `12 §4.4`'s printed test, both cited in
Sources and spelled out in §5.2 and §5.4 — read those sections rather than loading a third skill. The
two above are the ones that decide whether the **seam** is right rather than whether its test is tidy.

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/wakelock_test.dart`
- **Test** — `'the wakelock is off by default, expires after 30 minutes, and every acquire has a matching release'`
- **Why it is red today** — there is no `WakelockController` and it is the seventh of the seven fakes `12 §4.2` requires — critique gap G4.

```bash
fvm flutter test test/data/wakelock_test.dart   # expect: failing, for the reason above
```

Sharpen it into three assertions, because "off by default" and "expires" fail for different reasons
and the third is the one that catches a leak:

1. **Off by default.** A fresh `WakelockController` has `isHeld == false`, and
   `app_settings.wakelock_enabled` is `false` out of `seedFirstRun`. Both, because either alone permits
   a controller that acquires eagerly against a false column.
2. **The expiry is enforced by the gateway, not by a caller.** `acquire()`, advance the binding's clock
   by 31 minutes, and assert `isHeld == false` and that the plugin's `disable` ran **once**. Then
   `acquire()` again at minute 20 and assert the timer **re-armed** rather than stacking — one
   outstanding `Timer`, not two (`08 §7`: *"idempotent; re-arms the expiry"*).
3. **Every acquire has a matching release.** Drive `acquire(); acquire(); release();` and assert the
   plugin saw exactly one `enable` and one `disable`. Then drive a bare `release()` on a fresh
   controller and assert it is a **no-op that does not throw** — while `FakeWakelockController`, used
   by the widget tier, **does** throw on the same sequence. That asymmetry is deliberate: the real
   gateway must survive a spurious release from the lifecycle observer; the fake must make a spurious
   release in a *test* impossible to miss.

**Green.** The minimum code that passes, and nothing beyond it — the gateway, the expiry, `FakeWakelockController` with its release tripwire, and the
override list entry.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Steps 3 (the gateway), 4 (wiring), 5 (controller), 6 (UI), 7 (ARB) and 8 (tests).** No schema —
`palette`, `high_contrast`, `wakelock_enabled` and `left_handed` were frozen at N07-T08. No domain —
nothing is computed. **Say both out loud in the commit message.**

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/wakelock_controller.dart` | **New.** The seventh gateway, **as `08 §7` prints it**. The one `package:wakelock_plus/` import site in the app (`layer.plugin_wakelock_plus`) |
| 2 | `lib/data/providers.dart` | **Edit.** `wakelockProvider : Provider<WakelockController>`, keepAlive. The name is `wakelockProvider` — one of `CONVENTIONS` §4.3's five documented exceptions |
| 3 | `lib/app.dart` | **Edit.** A small `NavigatorObserver` reading `RouteSettings.name` on push, pop and replace, plus the lifecycle release in the existing `didChangeAppLifecycleState`. `lib/app.dart` already hosts the `WidgetsBindingObserver` and already passes `navigatorObservers:` (`08 §7.2`) |
| 4 | `lib/features/settings/widgets/appearance_section.dart` | **New.** Sections 6, 7 and 8: three palette choices, the High contrast switch, Keep screen on, Left-handed layout |
| 5 | `lib/features/settings/settings_write_controller.dart` | **Edit.** `setPalette`, `setHighContrast`, `setWakelockEnabled`, `setLeftHanded` — four `guard()`ed calls into verbs that already exist |
| 6 | `lib/features/settings/settings_screen.dart` | **Edit.** Slot the three sections in at 6, 7 and 8 |
| 7 | `lib/l10n/app_en.arb` | **Edit.** The four palette labels **verbatim**, the wakelock row and its cost sentence, the left-handed row and its *"the margin does not move"* sentence |
| 8 | `test/support/fake_wakelock_controller.dart` | **New.** `12 §4.2`'s seventh fake — `implements`, never `extends` |
| 9 | `test/support/harness.dart` | **Edit.** Add `wakelockProvider.overrideWithValue(...)` to `pumpApp`'s override list and **cross `FakeWakelockController` off the fake ledger** N12-T05 wrote |
| 10 | `test/data/wakelock_test.dart` | **New.** The anchor |
| 11 | `test/features/wakelock_scope_test.dart` | **New.** `12 §4.4`'s printed test, plus the route cases |
| 12 | `test/features/settings_test.dart` | **Edit.** The four appearance rows |
| 13 | `tool/check_policy.dart` | **Edit, only if the row is absent.** `layer.plugin_wakelock_plus` — `08 §7.3` requires it by name. Check first; N01 may already have shipped it |

### 5.2 The signatures

`08 §7` prints the class in full. Write it as printed — R9 fixes the name and both verbs, and the
comments are load-bearing:

```dart
// lib/data/wakelock_controller.dart — R9 fixes the class name and both verbs.
import 'dart:async' show Timer, unawaited;

final class WakelockController {
  static const sessionExpiry = Duration(minutes: 30);

  bool _held = false;
  Timer? _expiry;
  bool get isHeld => _held;

  /// Called ONLY by the route observer (08 §7.2), and only when
  /// app_settings.wakelock_enabled is true. Idempotent; re-arms the expiry.
  Future<void> acquire() async {
    _expiry?.cancel();
    _expiry = Timer(sessionExpiry, () { unawaited(release()); });
    if (_held) return;
    _held = true;
    await WakelockPlus.enable();
  }

  /// Unconditional and idempotent: it ends the whole session. Called from the
  /// route observer, from EVERY non-resumed lifecycle state (02 §9.1), from
  /// the expiry timer, and on app dispose.
  Future<void> release() async {
    _expiry?.cancel();
    _expiry = null;
    if (!_held) return;
    _held = false;
    await WakelockPlus.disable();
  }
}
```

```dart
// lib/app.dart — ONE decider. 08 §7.2: not from a screen's initState/dispose,
// because two permitted routes stack (Quick Entry -> Lambing Entry) and
// per-screen calls make popping the top one release a lock the screen
// underneath still wants — or make the reverse leak it.
const _wakelockRoutes = <String>{
  RouteNames.quickEntry, RouteNames.lambingEntry, RouteNames.penBoard,
};

final class _WakelockRouteObserver extends NavigatorObserver {
  _WakelockRouteObserver(this._ref);
  final WidgetRef _ref;

  void _apply(Route<dynamic>? top) {
    final on = _ref.read(settingsProvider).…wakelockEnabled;   // exhaustive switch, no accessor
    final permitted = _wakelockRoutes.contains(top?.settings.name);
    final w = _ref.read(wakelockProvider);
    if (on && permitted) { unawaited(w.acquire()); } else { unawaited(w.release()); }
  }

  @override void didPush(Route r, Route? previous)   => _apply(r);
  @override void didPop(Route r, Route? previous)    => _apply(previous);
  @override void didReplace({Route? newRoute, Route? oldRoute}) => _apply(newRoute);
}
```

```dart
// test/support/fake_wakelock_controller.dart — 12 §4.2's seventh fake.
// `implements`, never `extends`: when 08 changes a signature, this file is a
// COMPILE ERROR rather than a silent divergence.
final class FakeWakelockController implements WakelockController {
  int acquired = 0;
  int released = 0;
  bool _held = false;

  @override
  bool get isHeld => _held;

  @override
  Future<void> acquire() async { acquired++; _held = true; }

  @override
  Future<void> release() async {
    if (!_held) {
      throw StateError(
          'decision #79: release() with no matching acquire(). In production '
          'this is a harmless no-op, which is exactly why a test must not let '
          'it pass — a wakelock leak is invisible until a phone is flat at '
          '05:00 on night eleven.');
    }
    released++;
    _held = false;
  }
}
```

Widget keys, R59 spelling:

```
settings.appearance.palette.night     settings.appearance.palette.amber
settings.appearance.palette.red       settings.appearance.high_contrast
settings.keep_screen_on               settings.left_handed
```

`settings.appearance.palette.red`, not `.deep_red` — the key follows the **stored key**, which is
`'red'` (R35). One string, three places: the enum's `key`, the `CHECK`, the widget key.

The four labels, from `06 §4.1` and decision #96, **verbatim**:

```
Night
Amber (recommended)
Deep red (best for night vision, hardest to read)
High contrast
```

### 5.3 The details that are easy to get wrong

- **`ShedPaletteId.values.byName('red')` throws.** `deepRed`'s stored key is `'red'` (R35) — the one
  member whose key does not match its name. `paletteFromKey(String)` was written in **N12-T02** as a
  `.key` lookup, with an unrecognised key resolving to `night` rather than throwing. **Call it. Do not
  re-implement it.** A second palette-from-string function under `lib/features/` is a second answer,
  and it will be the wrong one when a restore brings back a value this build does not know.
- **There is no `dark` key.** `03 §5.13`'s `CHECK IN ('night','amber','red')` rejects it, and R35
  renamed `dark`→`night` precisely so the stored key and the enum key are the same string. `dark` is
  the historical spelling somebody will try; N12-T02 already has a named test for it.
- **Two independent controls, not one three-way choice** (`07 §14.3` row 6). Palette is a three-way
  pick; High contrast is a **separate boolean** that selects a genuinely different palette, and
  `06 §12`'s DoD says *"`highContrastDarkTheme` is not a copy of `darkTheme` — that would be dead
  plumbing while claiming to honour the flag."* A four-button group labelled Night / Amber / Deep red /
  High contrast is the natural implementation and it is wrong: it makes high contrast unreachable in
  amber, which is the combination a shepherd with astigmatism in a red-shifted shed actually needs.
- **The in-app switch and iOS's Increase Contrast are ORed** (`06 §4.1`). Because Android never sets
  the platform flag, the same six palettes are reachable from the Settings switch on both platforms.
  The switch does not *replace* the platform flag; it joins it.
- **The four labels are typed exactly** (decision #96, `06 §4.1`, `CONVENTIONS` §5.4). *"Deep red (best
  for night vision, hardest to read)"* is honest on purpose: `#FF0000` on the night base measures
  **5.25:1** and `#FFB000` measures **11.46:1**. Softening the label to "Deep red" is the app declining
  to say the thing the measurement says.
- **There is no light theme and no system-follow** (`06 §9`, spec §5). The Appearance section has three
  palettes and one switch. A "Follow system" row is not a missing feature.
- **Default off, and the row says what it costs** (`08 §7.1` condition 1). The copy must state the
  30-minute expiry: *"when the expiry fires the screen simply behaves normally again; walking to another
  permitted route and back re-arms it. **Say that in the Settings copy rather than letting the shepherd
  discover it.**"*
- **The wakelock may never be held on this screen** (`08 §7.1` condition 2). Quick Entry, Lambing Entry
  and the Pen Board, and nothing else: *"never Season Summary, Export, Settings, Treatments, Flock or
  note search — those are daylight screens read with two hands."* The row that turns it on lives on a
  screen where it can never be active. That is not an inconsistency; it is the point.
- **One decider, in `lib/app.dart`** (`08 §7.2`). Not `initState`, not `dispose`, not a
  `RouteAware`. `RouteSettings(name:)` already exists for the diagnostics log and `ModalRoute.withName`
  — *"this is its third and last use."*
- **`release()` is unconditional, never reference-counted** (`08 §7.3`, last bullet): *"a crash-restart
  with the lock leaked drains the phone silently overnight — which is why `release()` is unconditional
  rather than reference-counted."* Reference counting is the obvious "improvement" and it is the bug.
- **The lifecycle release fires on every non-resumed state, not just `paused`** (`02 §9.1`, `08 §7.2`).
  *"A phone that goes `inactive` behind a banner and never reaches `hidden` must not hold the screen on
  for the rest of the night."*
- **Do not wrap the expiry test in `atFixed`.** `Clock.fixed` freezes `appNow()`, so an elapsed-time
  test wrapped in it measures 0 and **passes** (decision #113; N12-T05's doc comment carries the
  warning verbatim). The expiry is a `Timer` on the binding's clock: `08 §7.3` says *"a widget test
  pumps `Duration(minutes: 31)`"*, and that is the mechanism. Put a comment beside the test saying why
  it pins nothing.
- **`wakelockProvider`, not `wakelockControllerProvider`** (`CONVENTIONS` §3.1 and §4.3). It is one of
  five documented exceptions to the `<typeNameLowerCamel>Provider` rule, because two documents already
  agree on it and renaming buys nothing.
- **The fake `implements`, never `extends`** (`12 §4.2`). A signature change must be a compile error.
- **`mocktail` earns its keep here and only here.** `12 §4.4` prints
  `test/features/wakelock_scope_test.dart` with `verifyNever(() => wakelock.acquire())` for the Flock
  screen: *"proving a call did not happen with a fake means asserting on the absence of an entry in a
  list, which is true for the wrong reasons whenever the fake was not wired in at all."* Use
  `mocktail` for the never-cases and the hand-written fake for everything else.
- **`leftHanded` mirrors the bottom row only** (`06 §8.2`). The keypad's bottom row (backspace, 0,
  decimal) and the bottom action bar. It does **not** mirror the reading order, does not set
  `Directionality`, and does not move the margin — `indelible.md` §8 screen 12 makes the app say so on
  the row itself. A `TextDirection.rtl` implementation would mirror the whole layout and break every
  golden and every reachability assertion in the project.
- **No permission and no manifest line.** `WAKE_LOCK` is merged by `wakelock_plus` and is already in
  `android/expected_permissions.txt` (`08 §8.3`). If `android` goes red on this branch, a **dependency**
  changed — stop, and do not edit the expected-permissions file (`CLAUDE.md`). The discontinued
  `wakelock` package (not `wakelock_plus`) is on Apple's third-party-SDK list (`08 §8.4`) and is
  banned; G2's allowlist already names the right one, so do not `pub add` anything.
- **There is no SnackBar** (P2). The receipt for a palette change is **the whole app repainting** —
  the most legible confirmation in the product, and it arrives through `themeProvider`'s next build.

### 5.4 The full test set

Three files.

`test/data/wakelock_test.dart`:

| Case | What it asserts |
|---|---|
| `'the wakelock is off by default, expires after 30 minutes, and every acquire has a matching release'` | **The anchor**, in its three parts |
| `'a second acquire re-arms the expiry rather than stacking a second timer'` | `acquire()` at 0 and at 20 min; still held at 45, released at 51 |
| `'release is a no-op on a controller that never acquired'` | No throw, no plugin call. The real gateway must survive a spurious release from the observer |
| `'sessionExpiry is 30 minutes and is read from the class, not a literal'` | `WakelockController.sessionExpiry == const Duration(minutes: 30)`; no `30` literal at any call site |
| `'package:wakelock_plus is imported by exactly one file'` | Source text over `lib/`. Duplicates `layer.plugin_wakelock_plus` deliberately, in the tier that runs first |

`test/features/wakelock_scope_test.dart`:

| Case | What it asserts |
|---|---|
| `'the Flock screen never acquires the wakelock'` | `12 §4.4`'s printed test, `verifyNever`, `_MockWakelock` |
| `'the Settings screen never acquires the wakelock'` | The screen this task builds is on `08 §7.1`'s excluded list |
| `'Quick Entry acquires and Quick Entry to Lambing Entry keeps it held'` | Both routes are permitted; the observer does not release on the push |
| `'Quick Entry to Season Summary releases'` | `08 §7.3`, third bullet |
| `'a resumed to inactive transition releases and isHeld is false'` | `08 §7.3`, second bullet; `02 §9.1`'s exact condition |
| `'the lock expires after 31 pumped minutes on a permitted route'` | Binding clock, no `atFixed`, with the comment saying why |
| `'nothing is acquired while app_settings.wakelock_enabled is false'` | Condition 1. The default state, which is the state most of the flock is in |
| `'FakeWakelockController throws on a release with no acquire'` | The tripwire itself, asserted — a tripwire nobody tests is a tripwire that was deleted |

`test/features/settings_test.dart` (appended):

| Case | What it asserts |
|---|---|
| `'the four palette labels are 06 §4.1's, verbatim'` | String equality against the four labels, read from the ARB |
| `'choosing deep red stores red, repaints the app, and dark is refused'` | `app_settings.palette == 'red'`; `themeProvider` yields the `deepRed` pair; writing `'dark'` is `WriteFailed` with no clamp (R35) |
| `'an unrecognised stored palette resolves to night rather than throwing'` | Write `'chartreuse'` past the repository; the screen renders |
| `'High contrast is an independent switch and reaches a genuinely different palette'` | `amber` + `highContrast: true` resolves to `amberHcPalette`, not to `nightPalette`; at least one token differs |
| `'there is no light theme and no follow-system control'` | No fourth palette key; `ThemeMode.light` and `ThemeMode.system` appear nowhere under `lib/` |
| `'Keep screen on is off by default and its copy states the 30-minute expiry'` | The switch is off; the ARB message contains the expiry sentence |
| `'the left-handed mirror flips the keypad bottom row and the action bar, not the reading order'` | Pump the keypad at both settings; the backspace/decimal `Rect`s swap, the tag readout's `Rect` does not, and `Directionality` is unchanged |
| `'each appearance control is at least 60 x 60 and reads from context.tokens'` | `tester.getRect`; no size literal in the widget file |
| `'no SnackBar is shown for any appearance change'` | P2 |

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **§12.2 on the palette labels.** *"The palette labels describe legibility and not eyesight"*
  (`07 §14.5`). "Best for night vision" is a statement about wavelength and dark adaptation, taken from
  the decision record's own measurements. Do not extend it into anything about the reader's eyes.
- **`wakelock_plus` **1.7.0**, from decision-record §5 and nowhere else.** Not a README, not `pub add`,
  not memory. It is already in the resolved `pubspec.lock` committed at N01.

## 7. Definition of Done

- [ ] `'the wakelock is off by default, expires after 30 minutes, and every acquire has a matching release'` passes, and was seen to fail first for the stated reason
- [ ] default off
- [ ] a 30-minute expiry that is enforced by the gateway
- [ ] the fake trips on a release with no matching acquire
- [ ] the left-handed mirror flips the primary target's side, not the reading order
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the commit message records that the schema and domain steps are skipped, and names critique gap **G4** as closed
- [ ] `lib/data/wakelock_controller.dart` is the only file importing `package:wakelock_plus/`, and `layer.plugin_wakelock_plus` is a live rule
- [ ] `acquire()` and `release()` are called from **one** decider in `lib/app.dart` and from no screen's `initState` or `dispose`
- [ ] `release()` is unconditional and idempotent; nothing reference-counts it
- [ ] the expiry test pumps the binding's clock and is **not** wrapped in `atFixed`, with a comment saying why
- [ ] `wakelockProvider` is the provider name, and `wakelockControllerProvider` appears nowhere
- [ ] `test/support/harness.dart` overrides `wakelockProvider` in `pumpApp`, and the fake ledger's `FakeWakelockController` row is crossed off
- [ ] palette and high contrast are two independent controls; the four labels are `06 §4.1`'s verbatim
- [ ] `paletteFromKey` has exactly one definition, in `lib/data/providers.dart`; `byName(` appears nowhere near a palette
- [ ] `android/` and `ios/` do not appear in the diff, and `android/expected_permissions.txt` is unchanged

## 8. Verification

```bash
fvm flutter test test/data/wakelock_test.dart
fvm flutter test test/features/wakelock_scope_test.dart
fvm flutter test test/features/settings_test.dart
make check
make test
```

```bash
grep -rln "package:wakelock_plus" lib/                       # exactly lib/data/wakelock_controller.dart
grep -n "layer.plugin_wakelock_plus" tool/check_policy.dart  # the rule must exist
grep -rn "wakelockControllerProvider" lib/ test/             # expect zero (CONVENTIONS §3.1)
grep -rn "byName(" lib/ | grep -i palette                    # expect zero (R35)
grep -rn "'dark'" lib/ | grep -i palette                     # expect zero (R35, 03 §5.13)
grep -rn "ThemeMode.light\|ThemeMode.system" lib/            # expect zero (06 §9)
grep -rn "atFixed" test/data/wakelock_test.dart              # expect zero (decision #113)
grep -rn "FakeWakelockController" test/support/harness.dart  # the ledger row, crossed off
git diff --stat -- android/ ios/ drift_schemas/              # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(settings): appearance settings and the WakelockController gateway`

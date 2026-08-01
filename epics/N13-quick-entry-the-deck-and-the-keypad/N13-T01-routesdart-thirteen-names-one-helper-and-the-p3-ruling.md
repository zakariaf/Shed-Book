# N13-T01 — `routes.dart` — thirteen names, one helper, and the P3 ruling

| | |
|---|---|
| **Epic** | [N13 — Quick Entry: the deck and the keypad](epic.md) · `00-README` §9 step 5 (1 of 2) |
| **Task** | 1 of 7 |
| **Depends on** | N12-T05 |
| **Commit** | one commit · `feat(routing): RouteNames, the navigator key, one helper, and the P3 ruling` |

## 1. Why this task exists

Thirteen `RouteNames` constants (free — a `const String` creates no compile edge),
`Routes.navigatorKey`, the route factory and **only the Quick Entry helper**. **This
task rules P3**: `02`'s Navigator stack and twelve push helpers against Indelible §7.17's *no stack, no
back button*. Rule it, amend the losing document, and implement Android back accordingly.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/02-state-di-navigation.md` | **§8.1** (the route helper, printed in full) · §8.2 (the stack) · **§8.3** (Android back, `PopScope`, `onPopInvokedWithResult`) · §8.4 (the anti-patterns table) · §9 + §9.1 (why there is no restoration; the resume policy) | the file, verbatim, and the back behaviour |
| `docs/engineering/CONVENTIONS.md` | §1 (`lib/routing/routes.dart` is in the tree) · §1.1 layer rules 5 and 6 + the `lib/routing/` `_mayImport` row · §2.14 (`RouteNames`, `Routes` — 13 names, 12 push helpers, `Routes.navigatorKey`) · §4.5 (widget keys) · §5.3 (banned words) · R33 (ids cross boundaries) | **BINDING** on the names, the file and the argument types |
| `docs/design/indelible.md` | **§7.17** (the index button and index sheet — *"there is no tab bar, no rail, no stack, and no back button"*) · §8 Screen 3 (*"There is no Quick Entry screen, and that is the design"*) · §4.5 (`INDEX` is a bottom-left 96 × 64 anchor) | the losing or winning side of P3 |
| `docs/engineering/07-screens.md` | §1.1 (the index — twelve screens, their route helpers, and the note-search route) · §1.6 (resume and restoration) · §5 opening (Quick Entry is the root route, never pushed) | which name maps to which screen, and which one is `home:` |
| `docs/research/00-tech-decisions.md` | §5.1 (`go_router` 17.3.0, rejected, with the reason) · #23 (Navigator + typed push helpers) · #24 (no state restoration) · #124 (route name is a loggable field) | why there is no router package and why every route sets a name |
| `epics/00-PLAN-CRITIQUE.md` | **S2** (twelve helpers for eleven absent screens) · §5 rule 6 (`routes.dart` grows one helper per screen epic) | the shape of this task |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-screens-and-routing` | routes, push helpers and the back behaviour are its subject |
| `indelible-page-and-screens` | §7.17 is one side of the P3 conflict |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/routing_test.dart`
- **Test** — `'RouteNames has thirteen constants and exactly one push helper exists today'`
- **Why it is red today** — the old plan declared twelve helpers for eleven screens that do not exist — the file could not compile. Today there is no routing at all.

```bash
fvm flutter test test/features/routing_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it says something a `const` list cannot fake. Read `lib/routing/routes.dart`
as **source text** and assert four things at once:

1. exactly thirteen `static const` declarations inside `abstract final class RouteNames`, and their
   values are the thirteen strings `02 §8.1` prints, each `lower_snake`;
2. the thirteen values are pairwise distinct (two names with the same string make
   `ModalRoute.withName` ambiguous and the diagnostics log unreadable);
3. `routes.dart` contains **zero** occurrences of `.push(` — the "one helper" that exists today is
   `Routes.popToQuickEntry`, a *pop*, because Quick Entry is `MaterialApp.home` and is never pushed;
4. `routes.dart` contains **zero** occurrences of `onGenerateRoute`, `routes:`, `pushNamed` and
   `GoRoute`.

Assertion 3 is the one that carries the test's name, and §5.3 explains why the count is a pop and not
a push. Write both facts as the `reason:` on the expectation, so a future reader of a failure message
does not have to find this file.

**Green.** The minimum code that passes, and nothing beyond it — the names, the key, the switch, one helper, and the P3 ruling written into the decision
record with the losing document amended in this commit.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema, no domain, no data, no controller.** This task reaches wiring (step 4 — it declares no
provider but is the file every screen's navigation goes through), UI (step 6, item 21 —
*"`lib/routing/routes.dart` — a `RouteNames` entry and a typed push helper, if the feature adds a
screen"*) and tests (step 7). Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/routing/routes.dart` | **New.** `abstract final class RouteNames` with thirteen `static const String`s; `abstract final class Routes` with `navigatorKey`, the private `_route` factory, `popTo`, `popToQuickEntry` and `popToQuickEntryGlobal`. **No push helper and no screen import yet** — twelve of the thirteen destinations do not exist, and a `const String` creates no compile edge, which is the whole point of S2's fix |
| 2 | `lib/app.dart` | **Edit.** `MaterialApp` gains `navigatorKey: Routes.navigatorKey`. `home:` stays N11's placeholder until **T05** replaces it with `const QuickEntryScreen()`. Confirm `restorationScopeId` is absent and stays absent (`02 §9`) |
| 3 | `android/app/src/main/AndroidManifest.xml` | **Edit, if N11-T06 did not already do it.** `android:enableOnBackInvokedCallback="true"` on `<application>`. Required by `02 §8.3`, because predictive back starts its animation *before* the gesture commits, so `canPop` must be decided ahead of time. **A native file — read the diff, and read the `android` job's G4 merger report on this PR** |
| 4 | `docs/research/00-tech-decisions.md` §7 | **Edit.** The P3 ruling: what it now says, and why the other answer was wrong. `00-README` §10 rule 1 — a superseded decision is struck with its reason, never quietly rewritten |
| 5 | `docs/engineering/02-state-di-navigation.md` §8 **or** `docs/design/indelible.md` §7.17 | **Edit — whichever loses.** The amendment rule is absolute: the decision record and every document that applies the decision change in the **same commit** |
| 6 | `test/features/routing_test.dart` | **New.** The anchor plus the cases in §5.4 |

`lib/l10n/app_en.arb` is **not** touched: `routes.dart` renders nothing and holds no user-facing
string. A route *name* is an internal identifier and a diagnostics-log field (decision #124), never a
label.

### 5.2 The signatures

`02 §8.1` prints this file and `CONVENTIONS` §2.14 catalogues it. Type the names as printed; a rename
here is a rename in fourteen files and in `test/policy/`.

```dart
// lib/routing/routes.dart
import 'package:flutter/material.dart';

/// Every route name that can appear in the diagnostics log. Route name is one of
/// the few fields decision #124 permits to be logged, so every route sets one.
///
/// Thirteen names, and today ZERO push helpers: Quick Entry is MaterialApp.home
/// (route 0, `isFirst`) and is never pushed, and the other twelve screens do not
/// exist yet. Each screen epic adds its own `Routes.<screen>` push helper in the
/// commit that adds the screen. The arithmetic assertion — thirteen names minus
/// twelve push helpers equals one — is a `test/policy/` row in N33, NOT here:
/// asserting it today would assert 13 - 0 = 13 and would have to be edited
/// twelve times. Critique S2.
abstract final class RouteNames {
  static const quickEntry = 'quick_entry';
  static const flock = 'flock';
  static const eweCard = 'ewe_card';
  static const lambingEntry = 'lambing_entry';
  static const lambCard = 'lamb_card';
  static const foster = 'foster';
  static const penBoard = 'pen_board';
  static const treatments = 'treatments';
  static const reminders = 'reminders';
  static const seasonSummary = 'season_summary';
  static const export = 'export';
  static const settings = 'settings';
  static const noteSearch = 'note_search';
}

abstract final class Routes {
  /// The one navigator, so notification taps and the resume policy can navigate
  /// without a BuildContext.
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// Back to the screen that started the flow. Used only by the pen-board flow's
  /// explicit "back to the board" action (02 §8.2).
  static void popTo(BuildContext context, String routeName) =>
      Navigator.of(context).popUntil(ModalRoute.withName(routeName));

  /// Back to Quick Entry — the "next ewe" action, and the resume policy.
  /// THIS is the one helper that exists today.
  static void popToQuickEntry(BuildContext context) =>
      Navigator.of(context).popUntil((r) => r.isFirst);

  /// The context-free twin: `ResumePolicy` (lib/app.dart) and, later, a
  /// notification tap have no BuildContext to hand.
  static void popToQuickEntryGlobal() =>
      navigatorKey.currentState?.popUntil((r) => r.isFirst);

  /// The ONLY place a MaterialPageRoute is constructed in this app.
  /// `RouteSettings(name:)` exists for exactly two reasons — the diagnostics log
  /// and `ModalRoute.withName` — and NEVER for `pushNamed`.
  static MaterialPageRoute<void> _route(
    String name,
    WidgetBuilder builder,
  ) =>
      MaterialPageRoute<void>(
        builder: builder,
        settings: RouteSettings(name: name),
      );
}
```

`_route` is private and, today, unused. Keep it: it is the shape every screen epic copies, and having
it land once with the `RouteSettings(name:)` comment attached is the difference between twelve
consistent helpers and twelve nearly-consistent ones. If `--fatal-infos` objects to an unused private
member, land the first push helper in the epic that lands the first pushed screen — do not delete
`_route` and do not add an `// ignore:`.

The push-helper shape every later epic writes, printed here once so nobody re-derives it (`02 §8.1`,
R33 — the argument is an extension-type id, never a bare `int`):

```dart
  static Future<void> eweCard(BuildContext context, EweId id) =>
      Navigator.of(context).push(_route(
        RouteNames.eweCard,
        (_) => EweCardScreen(eweId: id),
      ));
```

### 5.3 The details that are easy to get wrong

- **There is no `onGenerateRoute`, and the critique's own wording invites you to build one.**
  Critique S2's fix text reads *"lands `RouteNames` …, `Routes.navigatorKey`, the `onGenerateRoute`
  switch and only the Quick Entry helper"*. But `02 §8.1` ends *"There is no `routes:` table and no
  `onGenerateRoute`"*, and §8.4's anti-pattern table bans `Navigator.pushNamed` / `onGenerateRoute` /
  a `routes:` map with the reason: *"stringly-typed arguments are the exact thing the helper file
  removes."* `CONVENTIONS` §2.14 carries `RouteNames`, `Routes` and `Routes.navigatorKey` and nothing
  else, and `CONVENTIONS` outranks a plan document on a name. **Build no `onGenerateRoute`.** The
  "switch" S2 means is `_route(name, builder)`. Note the correction in the commit message so the next
  reader of the critique does not re-open it.
- **There is no Quick Entry *push* helper, and the anchor test's name is about a helper, not a push.**
  Quick Entry is `MaterialApp.home`, route 0, `isFirst` (`02 §8.1`, `07 §1.1`, `07 §5` opening). The
  one helper the file ships today is `popToQuickEntry`. The file therefore contains **zero** `push(`
  call sites, and that is the correct state, not a gap. Write it in the doc comment; the failure mode
  is a well-meaning contributor adding `Routes.quickEntry(context)` that pushes a second copy of the
  root route on top of itself.
- **Twelve of the thirteen names have no destination, and that is free.** A `static const String`
  creates no compile edge — no import, no symbol, no type. That is the exact property S2's fix relies
  on, and it is why the names land now rather than one at a time: the diagnostics log, the resume
  policy and `ModalRoute.withName` all need the full vocabulary before the screens exist.
- **`noteSearch` is the thirteenth and it is not a spec §9 screen.** Decision #35 puts full-text note
  search on its own screen because it is a different problem from tag matching. It is a real route, it
  is pumped by the matrix like any other (`12 §6.1` variant 13), and leaving it out is how the count
  becomes twelve and the matrix becomes 234 cells.
- **`GlobalKey` is a global and this is the only one.** `Routes.navigatorKey` is a `static final`
  `GlobalKey<NavigatorState>`. A widget test that pumps **two** `MaterialApp`s carrying the same key in
  one tree throws `Duplicate GlobalKey detected in widget tree`, and the message names the key, not
  your test. `pumpApp` (N12-T05) pumps one screen inside one `MaterialApp`; if a later test needs two,
  it passes its own key. Do not "fix" this by making the key non-`final` or by rebuilding it per test.
- **`canPop` is `true` on every screen in this app, forever.** Because every write commits immediately
  there is no "discard unsaved changes?" dialog anywhere (`02 §8.3`). The **single** exception is the
  season-deletion / delete-everything flow in Settings (decision #69), and CI counts it: more than one
  `canPop: false` under `lib/` fails the policy check. This epic adds **zero**.
- **`onPopInvokedWithResult`, never `onPopInvoked`.** The latter is deprecated and
  `flutter analyze --fatal-infos` — which the `gate` job runs — fails on it. `WillPopScope` was removed
  from the framework entirely; if you find it in a snippet, the snippet predates 3.44.
- **`Navigator.restorablePush` is banned and so is `restorationScopeId`.** Decision #24: no
  `RestorationMixin`, no `Restorable*` properties, no iOS `Main.storyboard` restoration-ID step. CI
  greps for all of them. The reason is correctness, not effort — `02 §9` spells out the 03:20 → 03:41
  scenario in which a restored selection files ewe 128's lambing against 412.
- **`go_router` is not merely unused, it is grepped for.** `lib/`, `test/` **and** `pubspec.yaml`
  (decision #23). Its entire value proposition is URLs; there is no web target, no deep link and no URL
  bar, and it costs three breaking majors in ~24 months plus flutter#117683 (open since 2022-12-27).
- **`lib/routing/` importing every feature is not a layer violation.** Layer rule 6 (no sibling-feature
  imports) applies to `lib/features/<a>/` → `lib/features/<b>/`; `lib/routing/` is not a feature, and
  rule 5 explicitly allows `lib/features/` → `lib/routing/`. `CONVENTIONS` §1.1's `_mayImport` row is
  `'lib/routing/': {'lib/routing/', 'lib/features/', 'lib/data/', 'lib/core/', 'lib/domain/'}`. That
  asymmetry is the trade the file buys: one file knows all twelve destinations so no screen has to know
  a second one.
- **The ziplock-bag capacitance question lands in this file** (`00-tech-decisions` §7.1 item 2,
  `02 §8.4`'s closing note). If the target hardware does not register taps through a freezer bag, the
  interaction model moves to volume-button shortcuts and every entry point gains a second, context-free
  caller through `navigatorKey`. **Do not design for that now** — do keep `_route` the only place a
  `MaterialPageRoute` is constructed, so the change stays one file.

**P3, and how to rule it.** Both sides, cited, because a ruling has to name what it overrules:

| Side | What it says | Where |
|---|---|---|
| `02` | `Navigator` 1.0, a stack three pushes deep at most, twelve typed push helpers, `PopScope` with `canPop: true` everywhere, Android predictive back, and a 2-minute resume reset to Quick Entry | `02 §8.1`–§8.3, §9.1 |
| Indelible | *"There is no tab bar, no rail, no stack, and no back button — pressing `INDEX` and choosing another filter is always one press deeper, never one press back."* And Screen 3: *"There is no Quick Entry screen, and that is the design"* — one scrolling ruled page under different filters, `INDEX` bottom-left, the slab bottom-right | `indelible.md` §7.17, §4.5, §8 |

The two are not reconcilable by wording. Rule them together, and note that the disagreement has two
halves that may be ruled the same way or differently:

1. **The mechanism** — whether navigation is a `Navigator` stack at all. Indelible's *"one press
   deeper, never one press back"* is a claim about what the user is told; a `Navigator` push whose only
   exit is `popToQuickEntry` satisfies it from the user's side while keeping route semantics, the
   diagnostics log's route name and Android's hardware back working. Deleting the stack means owning
   the Android back button by hand on every screen, which is the higher-risk half.
2. **The affordance** — whether an on-screen back control exists. Indelible ships `INDEX` (96 × 64,
   bottom-left) and no back chevron; `02` never requires a visible back control, only that the platform
   gesture works.

Whatever is ruled, three things must be true in this commit: the ruling is written into
`00-tech-decisions` §7 with its reason, the losing document is edited in the same commit, and Android
back behaves as the ruling says. If the owner is needed, **carry P3 into the PR body with both sides
cited** (`02-build-manifest.md` §4.5) rather than deciding it here.

### 5.4 The full test set

`test/features/routing_test.dart`. Most of these are source-text assertions over `routes.dart`, which
is the right tier: the properties are about what the file *contains*, and there are no screens to
navigate between yet.

| Case | What it asserts |
|---|---|
| `'RouteNames has thirteen constants and exactly one push helper exists today'` | **The anchor.** Thirteen `static const`s, values pairwise distinct and `lower_snake`; zero `.push(`; the one helper is `popToQuickEntry` |
| `'the thirteen RouteNames values are exactly 02 §8.1's list'` | Set equality against the literal list, so a typo (`pen_board` → `penboard`) fails here rather than in a matrix cell nine epics later |
| `'routes.dart contains no onGenerateRoute, no routes: map, no pushNamed and no GoRoute'` | The four anti-patterns from `02 §8.4`, as one source-text assertion |
| `'go_router appears in neither lib/, test/ nor pubspec.yaml'` | Decision #23's own grep, run as a test so it fails before CI does |
| `'MaterialApp sets navigatorKey and does not set restorationScopeId'` | Pump `app.dart` through `pumpApp`, find the `MaterialApp`, assert both |
| `'Restorable, RestorationMixin and restorablePush appear nowhere under lib/'` | Decision #24, as source text over the whole `lib/` tree |
| `'lib/ contains zero PopScope with canPop: false'` | Today's true count. The one permitted occurrence is N29's season deletion; a second is a defect |
| `'onPopInvoked does not appear; onPopInvokedWithResult is the only spelling'` | The deprecation `--fatal-infos` would catch — asserted here so the failure names the reason |
| `'popToQuickEntry pops until isFirst'` | Push two synthetic routes onto a test navigator, call it, assert one route remains and it is `isFirst` |
| `'popToQuickEntryGlobal works with no BuildContext'` | Same, through `Routes.navigatorKey.currentState`. This is the resume policy's and the future notification tap's only path |
| `'_route stamps RouteSettings(name:) and is the only MaterialPageRoute construction under lib/'` | Source text over `lib/`: one `MaterialPageRoute(` and it is in `routes.dart` |
| `'the thirteen-names-twelve-helpers assertion is deferred, and the file says so'` | The doc comment names N33 and the reason. A comment is the artefact here, and a test that reads it is what stops it being deleted as noise |
| `'a resume across the ambiguous DST hour still returns to Quick Entry with nothing selected'` · **`@Tags(['uk-zone'])`** | `TZ=Europe/London`. Background at **01:30 BST** and resume at **01:30 GMT** — the repeated hour, so the wall clock has not moved and elapsed physical time is 60 minutes. `ResumePolicy.staleAfter` is 2 minutes, so the reset must fire and `popToQuickEntryGlobal` must land on `isFirst`. A naive `DateTime` subtraction of two local wall times gives **zero** here and silently keeps a stale selection — exactly the 03:20 / 03:41 data-integrity bug `02 §9` exists to prevent. This case asserts the **navigation** half; `ResumePolicy`'s arithmetic is N11's and has its own case |

The DST case is the only time-shaped assertion in this task, and it is the reason `routing_test.dart`
carries a `uk-zone` tag at all. Without `TZ=Europe/London` on the process it passes vacuously in UTC.

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **`routes.dart` renders nothing**, so the two rows above bind it only negatively: this task adds no
  target, no string and no gesture. If it did, it would be the wrong file.
- **The amendment rule** (`00-README` §10) binds the P3 ruling, not just the code: decision record plus
  every applying document, in the same commit.

## 7. Definition of Done

- [ ] `'RouteNames has thirteen constants and exactly one push helper exists today'` passes, and was seen to fail first for the stated reason
- [ ] thirteen `RouteNames` constants
- [ ] exactly one push helper, and a comment saying each screen epic adds its own
- [ ] P3 is ruled and Android back does what the ruling says
- [ ] the *thirteen names, twelve helpers* assertion is deferred to N33 and the comment says so
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the thirteen values are pairwise distinct and `lower_snake`, and `noteSearch` is among them
- [ ] `onGenerateRoute`, a `routes:` map, `pushNamed`, `GoRoute` and `restorationScopeId` appear nowhere in `lib/`
- [ ] `MaterialApp` carries `navigatorKey: Routes.navigatorKey`; `home:` is still N11's placeholder (T05 replaces it)
- [ ] `android:enableOnBackInvokedCallback="true"` is present in `AndroidManifest.xml`, and `android/expected_permissions.txt` is untouched
- [ ] **the P3 ruling is written into `00-tech-decisions` §7 and its losing document amended in this same commit**, or P3 is carried into the PR body as open with both sides cited
- [ ] the `uk-zone` resume case exists and fails when the `TZ=Europe/London` leg is removed

## 8. Verification

```bash
fvm flutter test test/features/routing_test.dart
make check
make test
```

```bash
# The uk-zone leg, run the way CI runs it — the DST case is vacuous without it.
TZ=Europe/London fvm flutter test --tags uk-zone
```

```bash
# The four anti-patterns and the two globals, as the reviewer will grep for them.
grep -rn "onGenerateRoute\|pushNamed\|routes:\|GoRoute" lib/            # expect zero
grep -rn "restorationScopeId\|RestorationMixin\|restorablePush" lib/    # expect zero
grep -rn "go_router" lib/ test/ pubspec.yaml                            # expect zero
grep -c "\.push(" lib/routing/routes.dart                               # expect 0
grep -rn "MaterialPageRoute(" lib/                                      # expect one, in routes.dart
grep -rn "canPop: false" lib/                                           # expect zero
grep -rn "onPopInvoked\b" lib/                                          # expect zero
```

```bash
# The native edit and the document amendment, read rather than assumed.
git diff --stat android/ docs/
grep -n "enableOnBackInvokedCallback" android/app/src/main/AndroidManifest.xml
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(routing): RouteNames, the navigator key, one helper, and the P3 ruling`

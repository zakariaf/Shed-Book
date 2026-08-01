# N11-T04 — `NightErrorPanel` and the P14 ruling

| | |
|---|---|
| **Epic** | [N11 — Bootstrap, errors and the first frame](epic.md) · `00-README` §9 step 4 (3 of 3) |
| **Task** | 4 of 9 |
| **Depends on** | N11-T03 |
| **Commit** | one commit · `feat(app): NightErrorPanel, theme-free, and the P14 ruling` |

## 1. Why this task exists

The `ErrorWidget.builder` that renders when everything else has failed — so it **bypasses
`Theme`** and carries its own `Directionality`, because a theme lookup is exactly what may be broken.
**This task rules P14**: the panel's `#0B0D0E` against Indelible's `--page` `#0A0A0B`, on the first
painted frame, where the difference is visible as a seam.

Flutter's default `ErrorWidget` is a red-on-yellow block. Under a head torch in a dark shed that is
both blinding and terrifying, and it tells a shepherd holding a lamb nothing they can act on. Ours is
the page colour, one line of near-white text, and exactly one action: *"Save a copy of my records"*.

P14 lands here rather than in N09 because N09-T01 authored `nSurface04` and was told to **record the
conflict in a comment and carry it into the PR body, not to pick silently**. Two documents disagree
about one hex, that hex is the first painted frame, and `launch.colour_parity` (T06 onward) compares
the native launch colour to that constant. If both values are still live when T06 runs, the gate
compares a value to itself while the error panel uses the other one and no test sees the seam.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/01-architecture.md` | §5.5 (the panel's **three hard constraints**, and the one action it offers) · §6.1 (`ErrorWidget.builder` is set in `main()`, once) · §3.2 (the `[exempt]` allowlist and why this file is on it) | the widget's contract |
| `docs/engineering/06-design-system.md` | §1 (**the table that rules P14**: *"the base surface hex, provided it is no brighter than `#0B0D0E`"* is in the *free — a direction owns it* column) · §2.4 (the error widget renders outside any theme) · §3.5 (`test/design/wcag.dart`'s `launchSurface`) · §4.2 (the `night` palette's base surface) · §9 (the single constant) · §12 (the inventory row) | the colour, and the authority to change it |
| `docs/design/indelible.md` | §2.2 (`--page` `#0A0A0B`, L 0.00306, *"one step off black… the first painted frame"*) · §2.5 (the contrast table, **measured on `#0A0A0B`**) · §5.2 (*"no white flash, ever, on either platform"*) | the winning value and the evidence for it |
| `docs/engineering/10-accessibility-and-i18n.md` | §8.7 rule 6 (**`NightErrorPanel` contains hard-coded English** — a `Localizations` lookup there is a crash inside the crash handler) | why this widget has no ARB entry |
| `docs/engineering/CONVENTIONS.md` | §2.11 (the `NightErrorPanel` row — **amended by this task**) · §4.5 (widget keys) · §4.7 + R56 (the four `[exempt]` lines) · §5.3–§5.4 (banned words, copy conventions) | **BINDING**, and one of the rows this ruling edits |
| `docs/engineering/13-build-ci-release.md` | §12 item 4 (the dark-launch check — **amended by this task**) | the fourth document carrying the losing hex |
| `epics/00-PLAN-CRITIQUE.md` | §8 G4, the P14 row | *"Make N11-T04 the commit that rules it **and** amends `CONVENTIONS §2.11` and `13` §5.4 together, per the amendment rule"* |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-bootstrap-and-errors` | the error net and its widget are its subject |
| `indelible-states-and-feedback` | the panel is a state, and P14 is its colour conflict |

Two auto-firing skills is the cap. `shed-conventions` is not reloaded, and its three bearings on this
diff are named instead: the amendment rule (this commit edits `CONVENTIONS` §2.11's row and says so in
the message), the `[exempt]` allowlist R56 fixes at four lines on day one, and the rule-id grammar the
new row must satisfy. All three are quoted in §5.1 and held in §6.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/night_error_panel_test.dart`
- **Test** — `'ErrorWidget.builder renders NightErrorPanel with no Theme or MediaQuery ancestor'`
- **Why it is red today** — a thrown widget renders Flutter's red-on-yellow, which is unreadable under a head torch and tells a shepherd nothing.

```bash
fvm flutter test test/features/night_error_panel_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. Pump the panel **bare** — `tester.pumpWidget(const
NightErrorPanel())` with no `MaterialApp`, no `Theme`, no `MediaQuery` and no `Directionality` above
it — and assert it builds without throwing, that `tester.takeException()` is null, and that the
outermost painted fill is the page colour. Then, in the same file, install
`ErrorWidget.builder` exactly as `main.dart` does, pump a widget whose `build` throws, and assert
`find.byType(NightErrorPanel)` finds one. A bare pump alone proves the widget; the builder half
proves the wiring, and they fail for different reasons.

**Green.** The minimum code that passes, and nothing beyond it — the panel with no inherited lookups, the ruling written into the decision record, and the
losing value amended in this commit.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

§8 reaches the UI at step 18 and the ARB at step 22. This task lands at step 18 and **deliberately
skips step 22** — `10 §8.7` rule 6 makes this widget's copy hard-coded English, because a
`Localizations` lookup inside the crash handler is a crash inside the crash handler. Say so in the
commit message. No schema, no domain, no data, no provider, no controller.

| # | Path | What changes in it, and why |
|---|---|---|
| 1 | `test/features/night_error_panel_test.dart` | **New. The anchor, written first.** |
| 2 | `lib/core/ui/night_error_panel.dart` | **New.** The widget. The one file besides `primitives.dart` permitted to hold a `Color(0x…)` under `lib/` — its `[exempt]` line was created at N09-T01 and is **used**, not added again (R56 fixes the day-one total at four) |
| 3 | `lib/main.dart` | **Edited.** The third hook lands: `ErrorWidget.builder = (details) => const NightErrorPanel();`. `main.dart` is on `00-README` §10's never-waved-through list — a three-line diff is still read line by line |
| 4 | `test/policy/main_awaits_nothing_test.dart` | **Extended.** T03's anchor now requires **three** hooks before `runApp`, not two, and asserts `ErrorWidget.builder` is assigned exactly once in `lib/` and never inside a `build(` |
| 5 | `lib/core/ui/primitives.dart` | **Edited by the P14 ruling** — `nSurface04`'s value, and the comment N09-T01 left naming the conflict is replaced by the ruling's citation |
| 6 | `test/design/wcag.dart` | **Edited by the P14 ruling** — `const Color launchSurface`, which `06 §3.5` deliberately duplicates *"so that if someone edits `nSurface04` without editing the native config, this test must fail"* |
| 7 | `docs/` — five files | **Edited by the P14 ruling.** The full list is §5.3 below. `00-README` §10's amendment rule: same change, same commit |

### 5.2 The signatures

`01 §5.5` fixes the three hard constraints; `06 §2.4` fixes the content:

```dart
// lib/core/ui/night_error_panel.dart
// Renders when everything else has failed. It may be invoked with NO Theme, NO
// MediaQuery, NO Directionality and NO Localizations in scope, so it reads none
// of them. The one file besides primitives.dart allowed a raw hex under lib/ —
// allowlist line `lib/core/ui/night_error_panel.dart :: token.raw_color`.
// Copy is hard-coded English by construction (10 §8.7 rule 6).
import 'package:flutter/widgets.dart';

class NightErrorPanel extends StatelessWidget {
  const NightErrorPanel({super.key, this.onSaveACopy});

  /// Wired by the Diagnostics route when one exists (N29). Null here, and the
  /// action still renders — a disabled-looking button at 3am reads as a broken
  /// app, so it renders enabled and does nothing until N29 lands it.
  final VoidCallback? onSaveACopy;

  @override
  Widget build(BuildContext context) {
    return Directionality(              // constraint 1: supply our own
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: _page,                   // constraint 2: no Theme, no token lookup
        child: /* text + one 64×64 action */,
      ),
    );
  }
}
```

`package:flutter/widgets.dart`, **not** `material.dart`. Material's widgets look up `Theme`,
`MaterialLocalizations` and `MediaQuery`, which is the entire failure mode this file exists to avoid:
a `Scaffold`, a `Text` with a `style:` from `Theme.of`, an `ElevatedButton` or a `SnackBar` in here
throws inside the error handler and you get a grey screen with no diagnosis at all.

The copy, from `06 §2.4` — the base surface, one line of near-white text, the route name, and exactly
one action:

| Element | Content | Key |
|---|---|---|
| Message | *"Something went wrong on this screen. Your records are safe."* — present tense, no blame, no code | `night_error_panel.message` |
| Context line | The last recorded event, if one is available (see §5.3) | `night_error_panel.context` |
| Action | *"Save a copy of my records"* — 64 × 64 minimum, `semanticLabel` set | `night_error_panel.save_a_copy` |

### 5.3 The details that are easy to get wrong

**The P14 ruling comes first, because it is what this commit is for.**

- **`06 §1` already gives Indelible the authority, and that is the ruling.** Its table splits *fixed
  here — a direction may not change it* from *free — a direction owns it*, and **"the base surface
  hex, provided it is no brighter than `#0B0D0E`"** is in the free column. `#0A0A0B` has relative
  luminance **0.00306**; `#0B0D0E` has **0.00391**. Indelible's value is darker, so it is inside the
  ceiling `06` itself set. **Rule for `#0A0A0B` and amend the four documents and two source files
  that still say `#0B0D0E`.** You are not overruling `06`; you are applying its own rule.
- **P14 is already decided *de facto* by a test that is either green or wrong.** Every ratio
  `indelible.md` §2.5 publishes — 16.19, 7.80, 5.75, 5.59, 3.52, 3.88 — was measured against
  `--page` `#0A0A0B`, and `contrast_test.dart` (N09-T08) recomputes them with
  `Color.computeLuminance()`. On `#0B0D0E` the first is **15.93**, not 16.19. So if N09 merged green,
  `nSurface04` is already `#0A0A0B` and this commit is making the ruling *written*. If N09 merged
  with `#0B0D0E` **and** a green suite, that is a finding about `contrast_test.dart`, not a licence
  to keep the hex — say so in the PR body.
- **The complete amendment list. All of it, in this commit** (`00-README` §10):

  | File | What carries `#0B0D0E` |
  |---|---|
  | `lib/core/ui/primitives.dart` | `const nSurface04` and its `L = 0.0039` comment |
  | `test/design/wcag.dart` | `const Color launchSurface` (`06 §3.5`) |
  | `docs/engineering/06-design-system.md` | §1's ceiling row · §2.4 (the panel's hex) · §3.2 (`nSurface04`) · §3.5 (`launchSurface`) · §4.2 (base surface prose, the `surfaceBase` row, and the `onStatus` row) · §9 (*"the single constant"*, `colors.xml`'s `#FF0B0D0E`, **and the iOS float triplet**) · §12's Definition of Done line |
  | `docs/engineering/CONVENTIONS.md` | §2.11's `NightErrorPanel` row |
  | `docs/engineering/01-architecture.md` | §5.5's *"hard-codes the base surface `#0B0D0E`"* |
  | `docs/engineering/13-build-ci-release.md` | §12 item 4, the dark-launch check (the critique cites this as "13 §5.4") |
  | `docs/design/indelible.md` | **nothing** — it wins; add a one-line note that P14 is closed |

- **Recompute the iOS storyboard floats; do not copy the ones in `06 §9.2`.** They are `#0B0D0E`'s.
  `#0A0A0B` is R=10, G=10, B=11 → `red="0.039216" green="0.039216" blue="0.043137" alpha="1"`,
  `colorSpace="custom" customColorSpace="sRGB"`. The Android ARGB string becomes `#FF0A0A0B`. T07
  consumes both; getting them wrong here means T08's parity gate fails for a reason that looks like a
  parser bug.
- **`onStatus` is a different role and must be re-measured, not renamed.** `06 §4.2` uses `#0B0D0E`
  as *text inside a status chip*, where the ratios quoted are 10.85 / 13.80 / 11.47 against the three
  fills. Changing the base surface does not automatically change that role. Decide it explicitly and
  let `contrast_test.dart` confirm whichever way you go — it recomputes, so a wrong choice is red,
  not silent.

**Then the widget.**

- **The three hard constraints are not style, and each has a failure behind it.** Supply your own
  `Directionality` (there may be no `MaterialApp` above); read no `Theme`, no `MediaQuery` and no
  provider (a theme lookup is exactly what may be broken); offer exactly one action. `01 §5.5`.
- **`MediaQuery` includes `textScaler`, and this widget cannot read it.** So the text size here is a
  literal, not a token and not a scaled value — the one place in the app where 18 px is typed rather
  than resolved. That is a consequence of the constraint, and it is the reason the panel carries one
  short line rather than a paragraph: it cannot reflow to a user's text-scale setting.
- **`token.magic_size` will fire on that literal unless the `[exempt]` line covers it — check which
  rule ids the existing line names.** R56 fixes the day-one `[exempt]` total at **four** and this
  file already has its line for `token.raw_color`. If `token.magic_size` also fires, the answer is
  **not** a fifth line: express the size as a `const` local in this file (the rule targets
  `width:`/`height:`/`SizedBox(`-style literals) and say so in the commit message. Adding an
  allowlist line to make a red build green is a named anti-pattern.
- **The route-name line is a real conflict between two documents, and you have to decide it here.**
  `06 §2.4` says the panel renders *"the route name"*; `01 §6.1` builds it as `const
  NightErrorPanel()` and layer rule 7 forbids `lib/core/ui/` from importing `lib/core/log/` or
  `lib/routing/` — so the widget can reach neither `LocalLog.instance.lastEvent` nor
  `Routes.navigatorKey`. The two resolutions, and neither may be taken silently: (a) drop the const
  and let `main.dart` — which *may* import both — pass the value:
  `ErrorWidget.builder = (details) => NightErrorPanel(lastEvent: LocalLog.instance.lastEvent);`,
  evaluated at error time, not install time; or (b) drop the line from the panel and leave the route
  in the diagnostics log where `13 §7.2`'s `lastEvent` already records it. **(b) is the smaller
  change and the recommendation**; if you take (a), `LocalLog` gains a `lastEvent` getter at T09 and
  T03's *"`runApp` receives a const `ProviderScope`"* assertion is untouched because the `const` in
  question is the panel's, not the scope's. Record the choice in the PR body either way.
- **The action must be honest about what it does today.** *"Save a copy of my records"* routes to the
  same share path Export uses (`01 §5.5`) — and neither exists until N21/N29. Render the action, wire
  the callback as nullable, and **do not render a disabled button**: a greyed control at 3am reads as
  a broken app. `07 §15` and `06 §6.2` both take that line.
- **The copy may not imply the app is an official record.** §12.3. *"Your records are safe"* is a
  statement about the database; *"nothing was lost"* is a promise the panel cannot keep, and
  *"contact support"* names a channel that does not exist. `copy.vet_advice` scans `lib/`, so a
  *should* in this file fails the build.
- **No SnackBar, no dialog, no `showDialog`.** `ui.show_dialog` is a gate row outside the two
  allowlisted destructive files, and `feedback.dart` is the only file permitted to call
  `showSnackBar(` — neither is reachable from here anyway, because both need a `ScaffoldMessenger`.
- **The panel is a `StatelessWidget` in `lib/core/ui/`, not a feature screen** — but its test lives in
  `test/features/`, because that is where widget tests go (R57's eight directories; `test/design/` is
  for the gates). The anchor's path is fixed and correct.

### 5.4 The full test set

`test/features/night_error_panel_test.dart` — widget tests. No database, no `ProviderScope`, and
deliberately **no `pumpApp`**: the harness does not exist until N12-T05, and even when it does it
wraps the tree in exactly the `MaterialApp` this widget must survive without.

| Case | What it asserts |
|---|---|
| `'ErrorWidget.builder renders NightErrorPanel with no Theme or MediaQuery ancestor'` | **The anchor.** Install the builder as `main.dart` does; pump a widget whose `build` throws; `find.byType(NightErrorPanel)` finds one, and the thrown error is consumed |
| `'the panel builds bare — no MaterialApp, no Theme, no MediaQuery, no Directionality'` | `tester.pumpWidget(const NightErrorPanel())` and `tester.takeException()` is null. Four ancestors absent, one widget, no throw. This is the case that fails the day someone adds a `Scaffold` |
| `'the panel reads no inherited theme'` | Source-text: the file names none of `Theme.of`, `MediaQuery.of`, `MediaQuery.` , `Localizations.of`, `DefaultTextStyle.of`, `context.tokens`, `Scaffold`, `SnackBar`, `showDialog`. Cheaper than pumping every negative, and it names the offending token |
| `'the panel imports package:flutter/widgets.dart and not material.dart'` | One import assertion. `material.dart` is how every one of the lookups above gets reintroduced by accident |
| `'the fill is the page colour and no other colour is painted'` | Pump bare, find the outermost `ColoredBox`, assert its colour equals the ruled value. Written as a literal here **and** compared to `wcag.dart`'s `launchSurface`, so the ruling holds in two places |
| `'the panel offers exactly one action, at least 64 × 64, with a semanticLabel'` | One tappable node; its rect is ≥ 64 in both axes; `semanticLabel` is non-empty. `tester.ensureSemantics()` before the assertion (decision #115) |
| `'the copy names no code, no cause and no channel that does not exist'` | The rendered text contains no digit run, no `Exception`, no *support*, no *contact*, no *should*, and no *compliance* / *official* |
| `'the panel renders identically at text scale 2.0'` | It cannot read `textScaler`, so this is a **regression guard, not a feature**: assert the layout does not overflow when the harness supplies a large scale that the widget ignores. Documents the limitation instead of hiding it |
| `'ErrorWidget.builder is assigned exactly once in lib/ and never inside a build('` | Extends `test/policy/main_awaits_nothing_test.dart`. Reassigning a global during layout races whatever is currently rendering |
| `'main() installs all three hooks before runApp'` | The T03 anchor, widened from two to three, with the same index-ordering technique |

**Nothing in this task is time-shaped**, so no `test/domain/uk_zone/` case and no `@Tags(['uk-zone'])`.

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies. **The one documented exception in the app applies to this file**: `10 §8.7` rule 6 makes `NightErrorPanel`'s copy hard-coded English. The `semanticLabel` and the widget keys are still required.
- **The amendment rule** — `00-README` §10: a change to a decision updates the decision record and every document that applies it, **in the same change**. P14 touches five documents and two source files and they move together or not at all.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'ErrorWidget.builder renders NightErrorPanel with no Theme or MediaQuery ancestor'` passes, and was seen to fail first for the stated reason
- [ ] the panel builds with no `Theme`, no `MediaQuery` and no `Directionality` ancestor
- [ ] P14 is ruled and the losing document amended here
- [ ] the panel says what happened and what the shepherd can still do
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] **every file in §5.3's amendment table is edited in this commit** — five documents, two source files — and `grep -rn '0B0D0E' docs/ lib/ test/` returns only struck-with-reason mentions
- [ ] the iOS storyboard floats and the Android ARGB string are recomputed for the ruled hex and written into the ruling, ready for T06 and T07
- [ ] the file imports `package:flutter/widgets.dart` and names no `Theme.of`, `MediaQuery`, `Localizations`, `Scaffold`, `SnackBar` or `showDialog`
- [ ] `tool/policy_allowlist.txt`'s `[exempt]` section still has **exactly four lines** (R56)
- [ ] the route-name question is decided in writing, with the chosen option recorded in the PR body
- [ ] `ErrorWidget.builder` is assigned once, in `main.dart`, never inside a `build()`

## 8. Verification

```bash
fvm flutter test test/features/night_error_panel_test.dart
fvm flutter test test/policy/main_awaits_nothing_test.dart
fvm flutter test test/design/contrast_test.dart      # the ruling must not move a single ratio out of range
make check
make test
```

Then confirm the ruling landed everywhere it had to:

```bash
grep -rn "0B0D0E" docs/ lib/ test/ android/ ios/
# expect: only lines that record P14 as struck, with its reason

grep -rn "0A0A0B\|0xFF0A0A0B" lib/core/ui/primitives.dart test/design/wcag.dart
# expect one hit each — nSurface04 and launchSurface, agreeing

sed -n '/^\[exempt\]/,$p' tool/policy_allowlist.txt | grep -c '::'
# expect 4
```

And by eye, because this is a widget nobody looks at until it matters:

```bash
fvm flutter run --debug     # then force a build error in a child widget and read the panel
                            # in a dark room. If it is legible at arm's length, it is right.
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(app): NightErrorPanel, theme-free, and the P14 ruling`

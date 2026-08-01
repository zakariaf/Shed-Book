# N24-T01 — `ReminderBudget.forPlatform()` — 56 on iOS, 200 on Android

| | |
|---|---|
| **Epic** | [N24 — Reminders: rows, reconcile and the fixtures](epic.md) · `00-README` §9 step 9 (1 of 2) |
| **Task** | 1 of 8 |
| **Depends on** | N23-T07 |
| **Commit** | one commit · `feat(domain): ReminderBudget.forPlatform()` |

## 1. Why this task exists

Apple's limit is **64 pending notification requests per app**, and the behaviour above it is
**permanently undefined**: the `flutter_local_notifications` README says the last 64 set are kept, the
Developer Forums thread implies the soonest, and issue #2312 reports that at 65+ *nothing fired at all*
— an issue closed `not planned`. A 400-ewe flock in one peak week produces roughly **500** pending
reminders (`08 §2.2`'s arithmetic: 180 + 120 + 120 + 80). Five hundred rows against a sixty-four-slot
ceiling is not "mostly fine, occasionally lossy"; it is structurally broken, and it breaks **silently**,
by dropping reminders nobody can see were dropped. In a shed that means a lamb does not get tubed.

This task puts the two numbers in one place, before anything can hard-code them. Every later
assertion — the fake's budget tripwire (T02), the reconciler's slice (T05), the honest windowed line
(N25-T02) — reads this call and never a literal.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/08-platform-integration.md` | **§2.2** (the ceiling, the flock arithmetic, and the class printed in full) · §2.13 fact 2 (*"the number 56 never appears in a string"*) · §11 item 10 (the over-limit behaviour is permanently undefined) · §11 item 11 (open question 17 changes the budget, not the architecture) | the two numbers, the headroom, and the reason |
| `docs/engineering/CONVENTIONS.md` | §1 (`lib/domain/reminder_budget.dart` in the tree) · §1.1 **layer rule 1** (`lib/domain/` may import `dart:*` and nothing else) · §2.14 (the shape, as one row) · **R50** | **BINDING** on the path, the class shape and the method name |
| `docs/engineering/07-screens.md` | §11.2 (*"Never hard-code 56 in copy"*) · §17.1 (the windowed projection, in one paragraph) · §17.3 rule 1 | who reads it, and why a literal is a defect |
| `docs/engineering/12-testing.md` | §4.2 (`FakeNotificationScheduler`'s budget tripwire calls this) · §4.3 (the tripwire, printed) · §11.1 (test naming) | the first consumer, one task later |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · **#63** (the windowed projection and its four call sites) | the decision this task serves |
| `epics/00-PLAN-CRITIQUE.md` | §11.3 (this task's anchor) · the E20 restatement — *"a 312-reminder flock projects exactly 56 and drops none of the rest, asserted against `FakeNotificationScheduler`'s recorded calls"* | why the demo claim is a fake's records and not an iPhone |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | the platform caps and the scheduler seam are its subject |
| `shed-domain` | the budget is a pure value and belongs with the arithmetic |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/reminder_budget_test.dart`
- **Test** — `'forPlatform returns 56 on iOS and 200 on Android'`
- **Why it is red today** — nothing knows the caps, and the first implementation would schedule everything and lose the excess silently.

```bash
fvm flutter test test/domain/reminder_budget_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion before you write the implementation, because the obvious form of this test
**cannot fail on the iOS arm**. `forPlatform()` branches on `dart:io`'s `Platform.isIOS`, which is
`false` on `ubuntu-latest` and `false` on the developer's Mac — macOS is not iOS. There is no host in
this project's test matrix where the iOS arm is reachable. The anchor therefore asserts three separate
things:

1. `ReminderBudget.ios == 56` and `ReminderBudget.android == 200` — the constants, directly.
2. `forPlatform() == ReminderBudget.android` on any non-iOS host, with `reason:` naming why.
3. A **source-text** assertion over `lib/domain/reminder_budget.dart` that the body is the
   `Platform.isIOS ? ios : android` ternary.

Assertion 3 is the one that actually holds the iOS arm. `debugDefaultTargetPlatformOverride` does
**not** move `dart:io`'s `Platform` and must not be reached for here.

**Green.** The minimum code that passes, and nothing beyond it — the budget and its platform switch.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8's order

| §8 step | File | What changes in it, and why |
|---|---|---|
| 1 — schema | **skipped** | The budget stores nothing. It is two `const int`s and a switch; a column for it would put a device fact in a shepherd's database. Say "no schema step" in the commit message |
| 2 — domain | `lib/domain/reminder_budget.dart` | **New.** The whole task. `abstract final class ReminderBudget` with `static const int ios = 56`, `static const int android = 200`, `static int forPlatform()` |
| 3–6 | **skipped** | No repository writes it, no provider exposes it, no widget is added. `lib/features/` and `lib/data/` call the static directly — that is what R50 means by *"both `ReminderReconciler` and the Reminders screen read this"* |
| 7 — tests | `test/domain/reminder_budget_test.dart` | **New.** The anchor plus §5.4's cases |

### 5.2 The signature — this file *is* the task

```dart
// lib/domain/reminder_budget.dart — pure Dart. dart:io is permitted by layer rule 1.
import 'dart:io' show Platform;

/// R50. Both `ReminderReconciler` and the Reminders screen read this; the
/// number 56 never appears in copy, only through this call.
abstract final class ReminderBudget {
  /// 64 is the hard iOS limit and the behaviour above it is undefined.
  /// Eight slots of headroom.
  static const int ios = 56;

  /// Android documents no cap. 200 is a self-imposed sanity bound: it keeps
  /// the reconcile loop to ~200 platform-channel calls, and a projection
  /// bigger than that is a list nobody could act on anyway.
  static const int android = 200;

  static int forPlatform() => Platform.isIOS ? ios : android;
}
```

`08 §2.2` prints this verbatim. Type it as printed. The comments **are** the specification: the
eight-slot headroom and the reason Android's number is self-imposed are the two facts a future reader
will otherwise "optimise" away.

### 5.3 The details that are easy to get wrong

- **`Platform.isIOS` is false in every test process this project runs.** `flutter test` runs on the
  host; on CI that host is `ubuntu-latest`. `forPlatform()` returns **200** there and on a Mac. Any
  test, at any tier, that writes `expect(find.text('56'), findsOneWidget)` is red on CI forever; any
  test that writes `200` passes on CI and asserts nothing about the platform this budget exists for.
  N25-T02 carries the same warning, because the same trap is waiting one epic later.
- **`abstract final class`, not an enum and not a top-level `const`.** `abstract final` is
  simultaneously un-extendable, un-implementable and un-instantiable, which is the point: there is one
  budget and nobody can make a second one. A top-level `kReminderBudgetIos` would be greppable but not
  groupable, and `CONVENTIONS §2.14` fixes the shape.
- **There is no `reminderBudgetProvider`.** It is a static on a pure class, read directly by
  `lib/data/reminder_reconciler.dart` (T05) and `lib/features/reminders/` (N25). Putting it in the
  container would make a device fact overridable, and an overridable budget is a budget a test can set
  to 5 to make itself pass.
- **It lives in `lib/domain/`, and `dart:io` is what makes that legal.** Layer rule 1 permits
  `dart:*`. It does **not** permit `package:flutter/foundation.dart`, so `defaultTargetPlatform` is out
  of reach here — which is correct, because `defaultTargetPlatform` is a *Flutter* notion a widget test
  can override, and an OS request ceiling is not.
- **56, not 64.** The eight slots are headroom against an undefined failure mode, not caution. Do not
  reclaim them: one of the three published descriptions of the over-limit behaviour is *nothing fires
  at all*, and it was recorded against a real app.
- **200 is not a documented Android limit.** Android publishes none. It is our bound on the reconcile
  loop — 204 platform-channel calls per run at the ceiling (`08 §2.4`). Anyone raising it is raising a
  frame-time cost, not lifting a platform restriction, and the comment must keep saying so.
- **Open question 17 is not settled and does not block this task.** Whether the free tier caps
  reminders (`00-README` §5.2 item 17, `08 §11` item 11) changes *the budget*, not the architecture:
  15 ewes fits inside 56 comfortably and 400 does not. If it is ever ruled, the change is one arm of
  one method in this file. Do not anticipate it with a parameter.
- **No literal `56` anywhere else in `lib/`, `test/` or `assets/`** — that is a DoD line, and it is
  what keeps the Reminders screen's line honest. The source-scanning policy test that enforces it
  across the whole tree is N25-T02's (`test/policy/reminder_budget_is_never_a_literal_test.dart`);
  this task holds the property inside its own file and does **not** create that policy file early.
- **Nothing here is time-shaped, so there is no `uk-zone` case** — and the commit message should say
  so out loud. A budget is a count. The ambiguous hour arrives in T02 (`scheduleTimeFor`, DST-8), T04
  (the offset arithmetic, DST-6) and T06 (the two `tag_by` cases, DST-7 and DST-9), and every one of
  those is tagged.

### 5.4 The full test set

`test/domain/reminder_budget_test.dart` — a pure unit test: no binding, no database, no harness.

| Case | What it asserts |
|---|---|
| `'forPlatform returns 56 on iOS and 200 on Android'` | **The anchor.** `ReminderBudget.ios` is 56, `ReminderBudget.android` is 200, and `forPlatform()` equals one of the two — with the host-platform caveat in `reason:` |
| `'forPlatform returns the Android budget on a non-iOS host'` | `Platform.isIOS` is false here, so the returned value is `ReminderBudget.android`. The `reason:` states this is a fact about the *test host*, not about Android phones |
| `'the platform switch reads Platform.isIOS and nothing else'` | Source text over the file: it contains `Platform.isIOS`; it contains neither `defaultTargetPlatform` nor `TargetPlatform` |
| `'each of the two numbers appears exactly once in the file'` | Source text: `56` and `200` occur once each. A second occurrence is a copy waiting to drift |
| `'reminder_budget.dart imports dart:io and nothing else'` | Source text: no `package:flutter`, no `package:drift`, no `package:riverpod`, no other `lib/` path. Layer rule 1, held at the one domain file most tempted to break it |
| `'ReminderBudget is abstract final'` | Source text (`abstract final class ReminderBudget`) — there is no runtime form of "you cannot construct this", so the source is the assertion |
| `'no literal 56 appears anywhere else under lib/'` | Source scan over `lib/`, excluding this file and `*.g.dart`. Trivially true today; load-bearing from T05 onward |

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **This task authors no string, no widget and no gesture**, so the 3am floor and the ARB rule bind it
  negatively: a string in this diff means the number reached copy, which is the one thing R50 exists
  to prevent.
- **No dependency moves.** `pubspec.yaml` and `pubspec.lock` are not in this diff — the two plugins
  arrive in T02. A lockfile diff here is a review stop (`00-README` §7.1).

## 7. Definition of Done

- [ ] `'forPlatform returns 56 on iOS and 200 on Android'` passes, and was seen to fail first for the stated reason
- [ ] both numbers in one place
- [ ] no literal 56 anywhere else in the app
- [ ] the value is read by the screen in N25-T02
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the class is `abstract final`, lives in `lib/domain/reminder_budget.dart`, and spells `ios`, `android` and `forPlatform()` exactly as R50 does
- [ ] the file imports `dart:io` and nothing else
- [ ] the anchor states in `reason:` why the iOS arm is unreachable on the test host
- [ ] there is no `reminderBudgetProvider` and no override of this value anywhere
- [ ] the commit message says the schema step was skipped, and why

## 8. Verification

```bash
fvm flutter test test/domain/reminder_budget_test.dart
make check
make test
```

```bash
# The properties the file exists to hold, read straight off the source.
grep -c '56' lib/domain/reminder_budget.dart                              # expect 1
grep -rn '\b56\b' lib/ --include='*.dart' | grep -v reminder_budget.dart  # expect nothing
grep -rn 'defaultTargetPlatform\|TargetPlatform' lib/domain/              # expect nothing
grep -n 'import' lib/domain/reminder_budget.dart                          # expect one: dart:io
git diff --stat -- pubspec.yaml pubspec.lock                              # expect nothing
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): ReminderBudget.forPlatform()`

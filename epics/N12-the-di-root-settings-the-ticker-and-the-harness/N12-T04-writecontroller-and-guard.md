# N12-T04 — `WriteController` and `guard()`

| | |
|---|---|
| **Epic** | [N12 — The DI root, settings, the ticker and the harness](epic.md) · `00-README` §9 step 4 (3 of 3) |
| **Task** | 4 of 5 |
| **Depends on** | N12-T03 |
| **Commit** | one commit · `feat(core): WriteController.guard(), the double-tap defence` |

## 1. Why this task exists

Every mutation goes through `guard()`, which **refuses to run concurrently**. It is the
double-tap defence, and it is a UX safety feature wearing architecture's clothes: a cold thumb on a
glass screen through a bag double-taps constantly.

Without it the second fire is a second lambing record — a data-integrity bug produced by hardware, in
the one part of the product that exists to eliminate exactly that class of error.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/02-state-di-navigation.md` | §4–§5 | the provider graph, the override rules and the harness |
| `docs/engineering/CONVENTIONS.md` | §2.13, §3 | `SettingsRepository`'s ownership of `app_settings`, and every provider name |
| `docs/engineering/12-testing.md` | §4, §6.2 | the seven fakes and the variant table — and what may exist yet |
| `docs/engineering/02-state-di-navigation.md` | **§7** (the class, printed in full) · **§7.1** (the four rules) · §2.1 rows 2 and 6 (`AutoDisposeNotifier`; no `Ref.mounted`) · §2.2–§2.3 (`Mutation` and `ref.mutate` are not in this project) · §3 (the spelling card and the notifier-lifecycle note) · §4.2 (write controllers are always `.autoDispose`) · §6 (the nine controller conventions) | the whole file, verbatim in shape |
| `docs/engineering/CONVENTIONS.md` | §1 (`lib/core/write_action.dart`) · §2.4 (the write path) · §2.5 (`ShedFailure` and `UnexpectedFailure`) · §2.10 (`RefusalReason`) · §3.4 (`<feature>WriteControllerProvider`, always `.autoDispose`) · §4.2 · §4.4 · §5.2 (**"mutation" is a banned synonym**) · R8, R30, R53, R72 | the file path, the class name, the failure constructor, the vocabulary |
| `docs/engineering/01-architecture.md` | §5.2 (`WriteOutcome`'s three variants) · §5.3–§5.4 (`ShedFailure`, `shedFailureFrom`, where a programmer error lands) | what `guard()` returns into `WriteDone`, and what it may not import |
| `docs/engineering/12-testing.md` | §3.5 (durability as a property) · §10.1 (the double-tap widget test, and why there is no pump between the taps) · §11.6 (`Future.delayed` in a test body is banned) | how the concurrency assertion is written today and how it is written per screen later |
| `docs/research/00-tech-decisions.md` | #22 (double-tap protection) · #13 (`WriteOutcome`) · #103 (commit-then-confirm) · #91/#92 (`WriteRefused` is not a failure) | why the gate exists and what it must not become |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-riverpod-providers` | the controller's shape, its state, its disposal, and why `AutoDisposeNotifier` is the only bound that compiles on 2.6.1 |
| `shed-write-path` | every write in the app routes through this and it owns the rule |

`WriteOutcome`, `ShedFailure` and `UnexpectedFailure` are N11-T01/T02's and this is their first
consumer; their shapes are in `01 §5.2`–`§5.4`, cited in Sources. The skill budget is two auto-firing.

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/write_controller_test.dart`
- **Test** — `'guard() refuses a second invocation while the first is running'`
- **Why it is red today** — nothing serialises writes; the first double tap would create two ewes.

```bash
fvm flutter test test/features/write_controller_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it holds the *mechanism* and not just the outcome. Declare a test-local
`final class _SlowWriteController extends WriteController` whose verb is
`Future<void> go() => guard(() => _completer.future)`, where `_completer` is a `Completer<WriteOutcome>`
the test controls. Then, with **no `await` between the two calls**:

```dart
final notifier = container.read(_slowProvider.notifier);
notifier.go();            // deliberately not awaited
notifier.go();            // the second tap, in the same microtask turn
expect(actionInvocations, 1);
expect(container.read(_slowProvider), isA<WriteRunning>());
completer.complete(const WriteCommitted());
await pumpEventQueue();
expect(container.read(_slowProvider), isA<WriteDone>());
```

`actionInvocations, 1` is the assertion that matters: it proves the closure was never *entered*, which
is a stronger statement than "the state did not change twice". Use a `Completer`, never
`Future.delayed` — real wall time inside a `FakeAsync` zone hangs or flakes, and `12 §11.6` bans it
outright.

**Green.** The minimum code that passes, and nothing beyond it — the controller, the guard, and a test that starts a slow write and taps again.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 5 (controllers) and step 7 (tests) only** — and specifically the *base class* half of step 5;
the per-feature write controllers arrive one per screen epic. No schema (this task stores nothing; say
so in the commit message), no domain, no data, no wiring, no UI, no ARB string.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/write_action.dart` | **New.** `sealed class WriteState`, `WriteIdle`, `WriteRunning`, `WriteDone`, and `abstract base class WriteController`. The file name stays `write_action.dart` even though the class is `WriteController` (R72) |
| 2 | `test/features/write_controller_test.dart` | **New.** The anchor plus the sequencing, disposal, failure and policy cases in §5.4 |

No provider is declared in this task. `<feature>WriteControllerProvider` is per-screen
(`CONVENTIONS` §3.4) and the first one is N14's `quickEntryWriteControllerProvider`. The test declares
its own throwaway provider over a test-local subclass, which is also the proof that the base class is
subclassable outside `lib/core/`.

### 5.2 The signatures

`02 §7` prints this class in full. Type it as printed — a rename here is a rename in twelve write
controllers, and the two comments about *before the first await* and *no `==`* are load-bearing
documentation, not decoration.

```dart
// lib/core/write_action.dart — CONVENTIONS §1, §2.4 (R72). See 02 §4.6.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'failure.dart';         // sealed ShedFailure  — N11-T01
import 'write_outcome.dart';   // sealed WriteOutcome — N11-T01

sealed class WriteState {
  const WriteState();
}

final class WriteIdle extends WriteState {
  const WriteIdle();
}

final class WriteRunning extends WriteState {
  const WriteRunning();
}

/// Deliberately has NO `==`. Two identical outcomes in a row must still fire
/// `ref.listen`, because each completed write owes the user its own haptic, its
/// own confirmation and its own uniquely-labelled live region (decision #103).
final class WriteDone extends WriteState {
  const WriteDone(this.outcome);
  final WriteOutcome outcome;
}

/// `base` because Dart requires every subtype of a `base` class to be `base`,
/// `final` or `sealed` — every subclass in this project is a `final class`.
abstract base class WriteController extends AutoDisposeNotifier<WriteState> {
  bool _disposed = false;

  /// Must not `ref.watch` anything. A write controller has no data
  /// dependencies, so `build()` runs exactly once per mount.
  @override
  WriteState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return const WriteIdle();
  }

  @protected
  Future<void> guard(Future<WriteOutcome> Function() action) async {
    // The double-tap gate. This assignment MUST happen synchronously, before
    // the first await, or the second tap of a double-fire slips through.
    if (state is WriteRunning) return;
    state = const WriteRunning();

    WriteOutcome outcome;
    try {
      outcome = await action();
    } on Object catch (e, s) {
      // Repositories map their own expected failures and return WriteFailed
      // (01 §5.4), so anything reaching here is a bug — a bad cast, a null id,
      // a closure that throws before the transaction. It must still surface as
      // a failure. It must never surface as silence.
      outcome = WriteFailed(UnexpectedFailure(e, s));
    }

    // The screen may have been popped while the transaction ran. The write
    // itself completed — drift does not care that the provider is gone — but
    // assigning `state` after disposal throws. 2.6.1 has no `ref.mounted`
    // (02 §2.1), which is why `_disposed` exists at all.
    if (_disposed) return;
    state = WriteDone(outcome);
  }
}
```

The per-screen shape, for the epics that add one — put it in a doc comment so N14 copies it:

```dart
// lib/features/pens/pen_board_controller.dart  — the shape, from 02 §7.
//
// final class PenWriteController extends WriteController {
//   // `turnOut` is the UI verb and lives HERE; the repository verb is
//   // `exitPen`, because the occupancy row — not the pen — is what closes (R63).
//   Future<void> turnOut(PenOccupancyId occupancy) => guard(() async {
//         final repo = await ref.read(penRepositoryProvider.future);
//         return repo.exitPen(occupancy, reason: PenExitReason.turnedOut);
//       });
// }
//
// final penWriteControllerProvider =
//     NotifierProvider.autoDispose<PenWriteController, WriteState>(
//   PenWriteController.new,
// );
```

### 5.3 The details that are easy to get wrong

- **`state = const WriteRunning()` must be on the near side of the first `await`.** This is the whole
  task. Write `final repo = await ref.read(...)` first and the second tap arrives while `state` is
  still `WriteIdle`, both calls pass the check, and the double-tap defence is decoration. The awaited
  work belongs **inside the action closure**, never before `guard()`'s own assignment.
- **`AutoDisposeNotifier<WriteState>`, not `Notifier<WriteState>`.** On 2.6.1,
  `NotifierProvider.autoDispose<X, S>` requires `class X extends AutoDisposeNotifier<S>`; the
  `Notifier` form fails with *"'X' doesn't conform to the bound 'AutoDisposeNotifier<S>'"* — an error
  message that points at the bound and not at the fix (`02 §2.1` row 2). This is the single likeliest
  Riverpod-3 reflex in the epic.
- **`abstract base class`, and every subclass is `final class`.** Dart requires every subtype of a
  `base` class to be `base`, `final` or `sealed`. Writing `abstract class` compiles today and lets a
  screen epic write `class X implements WriteController`, which would give it a `guard()` that guards
  nothing.
- **`_disposed` exists because 2.6.1 has no `Ref.mounted`.** It is not a stylistic choice
  (`02 §2.1`, last row of §2.3). `ref.mounted` is a gate row; writing it is a red build, and reaching
  for it is the signal that you have started porting a Riverpod-3 snippet.
- **`build()` must not `ref.watch` anything.** If it does, `build()` re-runs whenever the watched thing
  changes — and because 2.6.1 *preserves the notifier instance* across a `build()` re-run (`02 §3`),
  `_disposed = false` executes mid-flight while `state` is reset to `WriteIdle`. The in-flight write
  then completes into a controller that thinks it is idle, and the next tap starts a second one.
- **`WriteDone` has no `==`, and neither does any other `WriteState` subclass.** Adding one — or
  reaching for `package:equatable`, or making it a record — means two identical outcomes in a row
  collapse into one `ref.listen` callback, so the second saved lamb gets no haptic and no confirmation
  and the shepherd taps again. `02`'s Definition of Done asserts it.
- **`guard()` may not import `lib/data/failure_mapping.dart`.** `lib/core/` does not reach into
  `lib/data/` (layer rule; `_mayImport['lib/core/']` has no `lib/data/` entry). Translating a
  `SqliteException` into a `ShedFailure` is the repository's job through the single top-level
  `shedFailureFrom(Object)` (R4). There is **no** `ShedFailure.from(e, s)`, and putting the mapping on
  `ShedFailure` would drag `package:sqlite3` into `lib/core/`.
- **`UnexpectedFailure(Object error, StackTrace stack)` is constructed at exactly two sites** (R8):
  inside `shedFailureFrom` and inside this catch-all. If you find a third, one of them is wrong.
- **`on Object catch`, not `catch (e)` and not `on Exception`.** An `Error` — a bad cast, a null check
  — is precisely the case that must not vanish silently, and `on Exception` does not catch it.
- **`guard()` prevents concurrency, not repetition** (`02 §7.1` rule 1). Once the first write returns,
  a second tap is a second write, and for "add lamb" that is correct. Where an action must not repeat
  *after* completion, the **repository** makes it idempotent — `exitPen` is a no-op when the occupancy
  row already has `exited_at`, enforced by a partial unique index. A UI cooldown is not the mechanism
  and would drop a legitimate second lamb. Do not add a `Duration`, a `Timer` or a `lastTapAt` field
  to this file.
- **No optimistic UI, and `WriteRunning` disables nothing visually** (decision #103, `02 §7.1` rule 2).
  A greyed-out button at 3am reads as a broken app. This file exposes the state; it does not decide
  what a screen does with it.
- **The refusal is a return, not a throw and not a queue.** `if (state is WriteRunning) return;` — the
  second call completes its `Future<void>` immediately having done nothing. Do **not** return a
  `WriteRefused`: that variant means *the free-tier policy declined a calm-UI action* (decision #91)
  and it comes from a repository, never from the gate. Rendering a double tap as a refusal would tell
  a shepherd their record did not save when it did.
- **"Mutation" is a banned synonym** (`CONVENTIONS` §5.2) and `Mutation` / `ref.mutate(` are gate rows
  (`02 §2.4`). The noun is **write controller**; the verb is **write**. The commit message obeys this
  too.
- **There is no `commit()`, no `submit()`, no `save()`, no `isDirty` and no draft** in this file or
  anywhere downstream of it (`CONVENTIONS` §5.3). The row is created on screen entry and every field is
  its own committed write.

### 5.4 The full test set

`test/features/write_controller_test.dart` — pure `ProviderContainer` tests plus source-text sweeps.
No widget test: there is no screen until N13, and the per-screen double-tap tests
(`tester.tap(); tester.tap();`, **no pump between them**) arrive one per screen epic from N14 onward.
Say that in a header comment, because the absence otherwise reads as an omission.

| Case | What it asserts |
|---|---|
| `'guard() refuses a second invocation while the first is running'` | **The anchor.** Two unawaited calls in one microtask turn; the action closure ran once; state is `WriteRunning` |
| `'the refused call completes normally and throws nothing'` | `await` the second future; no exception. The refusal is a return |
| `'state moves Idle → Running → Done and never skips'` | Record every state through `container.listen`; assert the exact sequence |
| `'WriteRunning is set before the first await'` | Read `state` synchronously, immediately after calling the verb and before any `await`. This is the one assertion that catches the misordering §5.3 opens with |
| `'a second call after the first completes runs the action again'` | Rule 1, stated as a test so nobody adds a cooldown to make the anchor "safer" |
| `'a throwing action becomes WriteFailed(UnexpectedFailure) and not a thrown exception'` | The closure throws a `StateError`; the outcome is `WriteFailed`, its failure is `UnexpectedFailure`, and the future completes normally |
| `'an action returning WriteFailed passes it through unchanged'` | The repository's own mapped failure is not re-wrapped |
| `'an action returning WriteRefused passes it through unchanged'` | `WriteRefused` reaches `WriteDone` intact. The gate never manufactures one and never swallows one |
| `'disposal mid-flight does not throw and does not assign state'` | Start the write, dispose the container, complete the completer; no exception. The `_disposed` field, isolated |
| `'two identical outcomes produce two distinct WriteDone notifications'` | `container.listen` fires twice for two `WriteCommitted()` results. The no-`==` property, as behaviour rather than as source text |
| `'no WriteState subclass declares operator =='` | Source text over `lib/core/write_action.dart` |
| `'build() watches nothing'` | Source text: no `ref.watch` in `write_action.dart` |
| `'write_action.dart does not import lib/data/'` | Source text. Layer rule, and specifically the `failure_mapping.dart` temptation |
| `'no Timer, Duration or cooldown field exists in write_action.dart'` | Source text. Rule 1 as a mechanical assertion |

**Nothing here is time-shaped.** `guard()` reads no clock, stores no instant and takes no `Duration` —
the only asynchrony in the tests is a `Completer` the test resolves by hand. There is therefore no
`uk-zone` case, and that absence is itself worth a comment in the file: the moment somebody adds a
timeout or a cooldown to `guard()`, this task acquires one.

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **The 3am test, as the actual reason** — the gate exists because a cold, gloved thumb on capacitive
  glass through a freezer bag double-fires. It is hardware, not user error, and the fix is structural.
- **Never silently correct an entry** — a swallowed exception is a silent correction of the worst kind:
  the record did not land and the app said nothing. `on Object catch` and `WriteFailed` are how that is
  prevented.
- **`WriteRefused` is not a failure** (decision #91) and never comes from here.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. Add `mutation` to that list for this file (`CONVENTIONS` §5.2).

## 7. Definition of Done

- [ ] `'guard() refuses a second invocation while the first is running'` passes, and was seen to fail first for the stated reason
- [ ] a concurrent call is refused, not queued
- [ ] the refusal is visible to the caller and is not an exception
- [ ] no write path in any later epic bypasses it
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `state = const WriteRunning()` is the last statement before the first `await`, and a test reads `state` synchronously to prove it
- [ ] `WriteController` is an `abstract base class` extending `AutoDisposeNotifier<WriteState>`
- [ ] `build()` `ref.watch`es nothing, and `_disposed` is reset in `build()` and set in `ref.onDispose`
- [ ] no `WriteState` subclass declares `operator ==`
- [ ] `lib/core/write_action.dart` imports nothing under `lib/data/`, and `UnexpectedFailure` is constructed at exactly two sites in the codebase
- [ ] no `Timer`, cooldown or debounce exists in this file — `guard()` prevents concurrency, not repetition
- [ ] the file carries a doc comment with the per-screen `WriteController` shape, so N14 copies rather than invents
- [ ] the test file carries a header comment saying that the `tester.tap(); tester.tap();` widget tests land one per screen epic, with no pump between the taps

## 8. Verification

```bash
fvm flutter test test/features/write_controller_test.dart
make check
make test
```

```bash
grep -n "await" lib/core/write_action.dart          # read every one; the first must be inside guard's try
grep -n "operator ==" lib/core/write_action.dart    # expect zero
grep -n "ref.watch" lib/core/write_action.dart      # expect zero
grep -n "Timer\|Duration" lib/core/write_action.dart # expect zero
grep -rn "data/failure_mapping" lib/core/           # expect zero
grep -rn "Mutation\|ref.mutate(" lib/ test/         # expect zero
grep -rn "UnexpectedFailure(" lib/                  # expect exactly two construction sites
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(core): WriteController.guard(), the double-tap defence`

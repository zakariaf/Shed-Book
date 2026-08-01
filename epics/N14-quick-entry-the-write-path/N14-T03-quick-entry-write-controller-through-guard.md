# N14-T03 — `quick_entry_write_controller` through `guard()`

| | |
|---|---|
| **Epic** | [N14 — Quick Entry: the write path](epic.md) · `00-README` §9 step 5 (2 of 2) |
| **Task** | 3 of 7 |
| **Depends on** | N14-T02 |
| **Commit** | one commit · `feat(quick_entry): the write controller, guarded` |

## 1. Why this task exists

The screen's write controller, every mutation through `WriteController.guard()`, with its
double-tap test. No `BuildContext`, no navigation, no formatting and no drift import in the controller
— it is screen state, never data.

A cold, gloved thumb on capacitive glass through a freezer bag double-fires. Without the gate the
second fire is a second lambing record — a data-integrity bug produced by hardware, on the product's
central write, at 03:20. `02 §7` calls this *"a UX safety feature disguised as architecture"*, and this
is the task where the disguise is first worn.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §5.4 | the write path and the tap budget |
| `docs/engineering/00-README.md` | §2.4, §8 step 3 | every write commits immediately; the row is created on screen entry |
| `docs/engineering/11-monetization-and-store.md` | §2 | `EntryContext` and decision #91's live-entry rule |
| `docs/engineering/02-state-di-navigation.md` | §6 (the nine controller rules) · **§7 (`WriteController`, `guard()` and the `ref.listen` switch, printed)** · §7.1 (the four rules) · §4.2 (auto-dispose) · §4.3 (`watch` / `read` / `listen`) · §2.1–§2.4 (the Riverpod-3 ban list and the CI rules) | the controller's shape, and every spelling that does not compile on 2.6.1 |
| `docs/engineering/CONVENTIONS.md` | §2.4 (`WriteState`, `WriteController`, `WriteOutcome`) · §3.4 (`quickEntryWriteControllerProvider`) · §4.1, §4.2, §4.4 · §1.1 layer rules 5 and 6 · R3, R30, R32, R33, R53 | **BINDING**: the provider name, the file name, and the ids that cross the boundary |
| `docs/engineering/01-architecture.md` | §4.4 (persist before republish; no optimistic UI, no manual invalidation) · §5.2, §5.4 | why the UI changes only after the transaction returns |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | the controller's shape and what may not be in it |
| `shed-riverpod-providers` | the controller's scope and its disposal |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/quick_entry_test.dart`
- **Test** — `'a double tap on the lambing verb creates exactly one lambing'`
- **Why it is red today** — nothing serialises the screen's writes; a cold-thumb double tap creates two rows.

```bash
fvm flutter test test/features/quick_entry_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion, and get the shape of the taps right or the test proves nothing:
`await tester.tap(lambing); await tester.tap(lambing);` with **no `pump` between them**, then one
`pumpAndSettle()`, then `expect(await countLambings(db), 1)`. `02 §7.1` rule 4 spells out why: with a
pump in the middle the first write completes, `state` becomes `WriteDone`, and the second tap
legitimately produces a second row — the test fails and rule 1 says it is right to.

**Green.** The minimum code that passes, and nothing beyond it — the controller through `guard()`, and the double-tap test `00-README` §8 step 28
requires.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema, no domain, no data step.** `WriteController` and `guard()` are N12-T04's; both
repositories are T01's and T02's. This task is `00-README` §8 steps 5 and 6 only — the controller and
the screen wiring — plus the ARB strings the two new controls need.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/features/quick_entry/quick_entry_write_controller.dart` | **New.** `final class QuickEntryWriteController extends WriteController` with two methods and its provider. The file name is `CONVENTIONS §4.1`'s `<feature>_write_controller.dart` |
| 2 | `lib/features/quick_entry/quick_entry_screen.dart` | **Edit.** Wire the confirm key and the `Lambing` event button to the controller, and add the single `ref.listen` that turns `WriteDone` into feedback. T04 fills in what feedback *is*; this task lands the exhaustive switch with all three arms |
| 3 | `lib/features/quick_entry/quick_entry_controller.dart` | **Edit, only if needed.** The typed digits live in a **private field on the notifier**, not only in `state` (`02 §6` rule 8). If N13 already did that, touch nothing |
| 4 | `lib/l10n/app_en.arb` | **Edit.** Any string the two controls need, each with a `description`. No domain noun is a literal — the term comes from `terminologyProvider` as a placeholder |
| 5 | `docs/engineering/07-screens.md` §6.1 | **Amend.** Its snippet calls `beginLambing` outside any guard and through the wrong controller. See §5.3 — the amendment lands in this commit, per the amendment rule |
| 6 | `test/features/quick_entry_test.dart` | **Edit.** The anchor plus the cases below. The file exists from N13-T02 and N13-T05 |

### 5.2 The signatures

```dart
// lib/features/quick_entry/quick_entry_write_controller.dart
// `final` because WriteController is `base`: Dart requires every subtype of a
// base class to be base, final or sealed (02 §7).
final class QuickEntryWriteController extends WriteController {
  /// The confirm key's "Create 412" arm. EntryContext.liveEntry is not a
  /// default and not a convention — it is the parameter that makes a refusal
  /// unreachable on this screen (decision #91).
  Future<void> createEwe(String tag) => guard(() async {
        final repo = await ref.read(flockRepositoryProvider.future);
        return repo.createEwe(tag: tag, context: EntryContext.liveEntry);
      });

  /// The "Lambing" event button. beginLambing returns an id and throws
  /// (R32), so it is adapted to guard()'s Future<WriteOutcome> here: the id
  /// travels back as WriteCommitted.insertedId, which is the single call site
  /// R33 permits to wrap a bare int. A throw is caught by guard()'s catch-all
  /// and surfaces as WriteFailed(UnexpectedFailure), never as silence.
  Future<void> beginLambing(EweId ewe) => guard(() async {
        final repo = await ref.read(lambingRepositoryProvider.future);
        final LambingId id = await repo.beginLambing(ewe);
        return WriteCommitted(insertedId: id.value);
      });
}

final quickEntryWriteControllerProvider =
    NotifierProvider.autoDispose<QuickEntryWriteController, WriteState>(
  QuickEntryWriteController.new,
);
```

And on the screen — the only place feedback happens (`02 §7`):

```dart
// lib/features/quick_entry/quick_entry_screen.dart
ref.listen(quickEntryWriteControllerProvider, (previous, next) {
  if (next case WriteDone(:final outcome)) {
    // WriteOutcome is sealed and has THREE variants. No `default:` — the day a
    // fourth appears, every switch must fail to compile rather than swallow it.
    switch (outcome) {
      case WriteCommitted(:final warnings):
        confirmSaved(context, receipt, warnings);   // T04 builds `receipt`
      case WriteFailed(:final failure):
        showFailure(context, failure);
      case WriteRefused(:final reason):
        showCapRow(context, reason);                // unreachable on this screen
    }
  }
});
```

### 5.3 The details that are easy to get wrong

- **`beginLambing` returns an id and throws; `guard()` takes a `Future<WriteOutcome> Function()`.** The
  two signatures do not compose, and the obvious resolution is the wrong one. `07 §6.1`'s printed
  snippet calls `await controller.beginLambing(ewe)` in a bare `try` / `catch` **outside** any guard —
  which deletes the double-tap defence on the product's central write and makes this task's anchor
  unpassable. The adaptation above is the fix, and it is not an invention: R33 says a bare `int`
  appears *"as `WriteCommitted.insertedId`, which the single reading call site wraps."* This is that
  call site. **Amend `07 §6.1` in this commit**, per `00-README` §10 — a document that still prints
  the unguarded snippet will be copied by the next screen.
- **`lambingWriteControllerProvider` is the wrong controller for this tap, and using it does not
  build.** `07 §6.1` names it; `CONVENTIONS §3.4` declares it; it lives in `lib/features/lambing/`.
  Quick Entry importing it is a `layer.sibling` violation (rule 6) — the gate fails, and it should.
  The Quick Entry lambing tap belongs to `quickEntryWriteControllerProvider`, which reaches the
  repository through `lib/data/`, which layer rule 5 permits. `lambingWriteControllerProvider` is
  N16's, for writes made *from* Lambing Entry.
- **There is nothing to push yet, and that is correct.** `LambingEntryScreen`, `RouteNames.lambingEntry`
  and `Routes.lambingEntry` are N16's — critique defect S2's ruling is that `routes.dart` grows one
  helper per screen epic. At N14 the tap commits the row and prints the receipt. Do **not** add a route
  helper for a screen that does not exist; do leave a comment naming N16 as where the push lands, so
  the id that `WriteCommitted.insertedId` already carries is not re-plumbed later.
- **`guard()` prevents concurrency, not repetition** (`02 §7.1` rule 1). Once the first write returns,
  a second tap is a second write — and for "add lamb" that is correct. Do not add a cooldown, a
  debounce or a disabled state to make the second tap impossible: a UI cooldown would drop a legitimate
  second lamb, and taps are never debounced (rule 3; the 400 ms ceiling applies to free-text fields
  only).
- **The state assignment before the first `await` is the entire gate.** `if (state is WriteRunning)
  return; state = const WriteRunning();` runs synchronously. Insert an `await` above it — a
  `ref.read(...future)` moved out of the closure, for instance — and the second tap of a double-fire
  slips through. `guard()` is N12-T04's and already correct; the way to break it from here is to do
  work before calling it.
- **`WriteState` subclasses deliberately have no `==`.** Two identical outcomes in a row must still
  fire `ref.listen`, because each completed write owes the user its own haptic, its own receipt and its
  own uniquely-labelled live region. Adding `==` "for tidiness" silently drops the second triplet's
  confirmation.
- **The controller must not `ref.watch` anything.** A write controller has no data dependencies, so
  `build()` runs exactly once per mount. Watching a provider re-runs `build()`, resets `state` to
  `WriteIdle`, and reopens the double-tap window mid-write.
- **`.autoDispose`, always** (`CONVENTIONS §3.4`). And `guard()` already handles the screen being
  popped mid-transaction through its `_disposed` flag: 2.6.1 has no `ref.mounted`, which is why the
  flag exists. Do not add a second liveness check.
- **Riverpod 2.6.1 spellings only.** `NotifierProvider.autoDispose<C, S>(C.new)` — never a bare
  `Notifier` with `.autoDispose`, never `ProviderScope.retry`, never `ProviderContainer.test()`, never
  `WidgetTester.container`, never `AsyncValue.valueOrNull`, never `StateProvider` or
  `StateNotifierProvider`, never a constructor-delivered family argument. The `rp3.*` gate rows grep
  for each; `ProviderScope.retry` is a compile error here, and the "disable it" advice in the raw notes
  must not be ported.
- **No `BuildContext` in the controller, ever** (`02 §6` rule 5). It never navigates, never shows a
  receipt, never calls `HapticFeedback`. The screen does all of that from `ref.listen`. A controller
  that holds a context is a controller you cannot unit-test and a screen you cannot reason about after
  a pop.
- **No drift import under `lib/features/`** (layer rule 5, `layer.features`). The controller talks to a
  repository; it never sees an `AppDatabase`, a `Companion` or a `Value`.
- **`WriteCommitted.warnings` is populated *here*, not by the repository** (R53). For this task the
  list is empty — the two validators that could speak (`birthTypeLambCountMismatch`,
  `implausibleBirthWeight`) have no data yet on a fresh lambing — but the plumbing is authored now so
  N16 has somewhere to put them. Do not shortcut it by having the repository return warnings; it
  structurally cannot.
- **No optimistic UI.** Nothing on screen changes before the transaction returns (decision #103). And
  no `ref.invalidate` after a write: drift already tracks which tables each stream reads, and manual
  invalidation is the classic stale-read bug. It is on the banned-text list.
- **The `WriteRefused` arm is written even though it is unreachable here.** `EntryContext.liveEntry`
  cannot produce one, so the arm never runs on Quick Entry — but the switch is exhaustive over a sealed
  type, and deleting the arm to "avoid dead code" is how a fourth variant later becomes a silent
  swallow. `showCapRow` is a no-op on a shed screen (T04, T07).

### 5.4 The full test set

`test/features/quick_entry_test.dart`, through `pumpApp` (N12-T05) against
`NativeDatabase.memory()` with `closeStreamsSynchronously: true`.

| Case | What it asserts |
|---|---|
| `'a double tap on the lambing verb creates exactly one lambing'` | **The anchor.** Two taps, **no pump between them**, one row. The reason for the missing pump is a comment in the file, or someone adds it back |
| `'a double tap on the confirm key creates exactly one ewe'` | The same gate on the other verb. Create-on-the-fly is the tap most likely to be double-fired, because it is the one the shepherd hesitates over |
| `'a second tap after the first write returns creates a second lambing'` | Rule 1 stated as a test: `guard()` prevents concurrency, not repetition. This is the case a cooldown would break |
| `'the controller emits WriteIdle, WriteRunning, WriteDone in that order'` | Read through a `ProviderContainer` listener. Proves the gate is a state machine and not a boolean in a `State` |
| `'two identical outcomes in a row both fire ref.listen'` | The no-`==` rule. Two lambings for the same ewe produce two notifications |
| `'the lambing tap commits before anything renders'` | Read the row from the database immediately after the tap settles. No Save, no Done, no pop |
| `'a failed write surfaces as WriteFailed and never as silence'` | Force a throw (a non-existent ewe) and assert `WriteDone(WriteFailed(...))` reached `ref.listen` |
| `'the committed lambing id reaches the screen as WriteCommitted.insertedId'` | The adaptation in §5.2, asserted rather than assumed — it is what N16 will push with |
| `'the controller holds no BuildContext and imports no drift'` | Source text over `lib/features/quick_entry/`, so the layer rule is visible in the failing test and not only in the gate |
| `'no Riverpod 3 spelling appears in the feature folder'` | Source text for the nine banned spellings (`02 §2`) |
| `'the write controller is autoDispose and is disposed when the screen pops'` | `CONVENTIONS §3.4`. A keepAlive write controller keeps `WriteRunning` alive across a pop and locks the next screen out |
| `'popping the screen mid-write does not throw'` | The `_disposed` path in `guard()`, exercised from a real widget tree |

No `uk-zone` group here: nothing in this task reads or derives a local civil time. The time-shaped
assertions live in T02 (`local_date`) and T07 (the quiet window).

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **3am** — the double-tap defence *is* the 3am requirement here. No control is ever disabled while a
  write runs: a greyed-out button at 3am reads as a broken app (`02 §7.1` rule 2).
- **Accessibility and the ARB, authored here** — every string this task adds goes into `app_en.arb`
  with a `description`; no domain noun is a literal; the term is a placeholder fed by
  `terminologyProvider`.

## 7. Definition of Done

- [ ] `'a double tap on the lambing verb creates exactly one lambing'` passes, and was seen to fail first for the stated reason
- [ ] one row per double tap
- [ ] no `BuildContext` in the controller
- [ ] no drift import in `lib/features/`, per N03-T02's rule
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the provider is `quickEntryWriteControllerProvider`, `NotifierProvider.autoDispose`, in `lib/features/quick_entry/quick_entry_write_controller.dart`
- [ ] `lib/features/quick_entry/` imports nothing from `lib/features/lambing/` — `lambingWriteControllerProvider` is not used here
- [ ] `beginLambing` runs **inside** `guard()`, and its id reaches the screen as `WriteCommitted.insertedId`
- [ ] `07 §6.1`'s unguarded snippet is amended in this commit, struck with its reason
- [ ] the `ref.listen` switch is exhaustive over `WriteOutcome`'s three variants with no `default:`
- [ ] the double-tap cases have **no `pump` between the two taps**, and a comment says why
- [ ] no cooldown, no debounce and no disabled state was added to any committing control
- [ ] no Riverpod-3 spelling appears anywhere in the diff
- [ ] no route helper was added for a screen that does not exist yet; a comment names N16 as where the push lands

## 8. Verification

```bash
fvm flutter test test/features/quick_entry_test.dart
make check
make test
```

```bash
grep -rn "features/lambing" lib/features/quick_entry/ --include='*.dart'   # expect zero
grep -rn "package:drift\|AppDatabase" lib/features/ --include='*.dart'     # expect zero
grep -rn "BuildContext" lib/features/quick_entry/quick_entry_write_controller.dart  # expect zero
grep -rn "ref.invalidate\|valueOrNull\|StateProvider\|ProviderScope.retry" lib/ --include='*.dart'
# expect zero for all four
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(quick_entry): the write controller, guarded`

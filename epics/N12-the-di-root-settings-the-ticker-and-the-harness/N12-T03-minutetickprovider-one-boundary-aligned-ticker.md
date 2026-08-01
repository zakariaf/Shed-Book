# N12-T03 — `minuteTickProvider` — one boundary-aligned ticker

| | |
|---|---|
| **Epic** | [N12 — The DI root, settings, the ticker and the harness](epic.md) · `00-README` §9 step 4 (3 of 3) |
| **Task** | 3 of 5 |
| **Depends on** | N12-T02 |
| **Commit** | one commit · `feat(core): minuteTickProvider, one boundary-aligned ticker` |

## 1. Why this task exists

**One** 60-second ticker in the whole app, aligned to the minute boundary, yielding
`Instant`, `autoDispose`, and never `Timer.periodic` — because twelve tiles each with their own timer
means twelve wake-ups a minute and twelve different ideas of what time it is.

It is also the task that completes `lib/app.dart`'s resume path. `02 §9.1` requires
`ref.invalidate(minuteTickProvider)` in the `resumed` arm — the **one** legitimate `ref.invalidate` in
the codebase — and N11-T05 could not write it because the provider did not exist. That line collides
with the `stream.invalidate` gate row; §5.3 owns the collision.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/02-state-di-navigation.md` | §4–§5 | the provider graph, the override rules and the harness |
| `docs/engineering/CONVENTIONS.md` | §2.13, §3 | `SettingsRepository`'s ownership of `app_settings`, and every provider name |
| `docs/engineering/12-testing.md` | §4, §6.2 | the seven fakes and the variant table — and what may exist yet |
| `docs/engineering/CONVENTIONS.md` | §3.3 (the ticker's one row) · §4.3 (the naming exception) · **R25** (one name, one element type, one dispose policy) · R23 (`appNow()`) · R24 (`timeSincePenned` takes `now`) · R56 (`[exempt]` has four lines) | `minuteTickProvider`, `StreamProvider.autoDispose<Instant>`, `lib/core/time/ticker.dart`; `minuteTickerProvider` and `penTickProvider` are banned |
| `docs/engineering/01-architecture.md` | §3.2 (`net.sync_timer`, `stream.invalidate`) · §7.2 (the ticker body, and the bucket-A argument) | the two gate rows this task meets, and one of the two published bodies |
| `docs/engineering/07-screens.md` | §1.2 (the four app-level singletons a screen may watch) · §9.2 (the ticker, the battery argument, the `async*` cancellation limitation) · §11.1 (the Reminders day boundaries re-bind from it) | the second published body, and every consumer |
| `docs/engineering/02-state-di-navigation.md` | §4.1 (the one legitimate `ref.invalidate`) · §4.2 (why `.autoDispose` is load-bearing) · §9.1 (the resume arm) | why the invalidate exists and where it goes |
| `docs/engineering/12-testing.md` | §2.1–§2.2 (the advancing fake clock; `Clock.fixed` freezes) · §2.3–§2.5 (the ambiguous hour and the three commands) · §11.6 (`Future.delayed` in a test body is banned) | how a timer-driven provider is tested without `package:fake_async` |
| `docs/engineering/06-design-system.md` | §14 (one 60 s app-level ticker; no per-tile timers) | the display-granularity argument for 60 s rather than 30 s |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-riverpod-providers` | the ticker's scope, its disposal and its rebuild blast radius — and the `ref.invalidate` allowance in §4.1 |
| `shed-domain` | it yields `Instant`, `appNow()` is the one wall-clock reader, and every consumer takes `now` as a parameter |

The testing half — the binding's advancing fake clock, and `Clock.fixed` as the trap beside it — is
`12 §2.1`–`§2.2`, cited in Sources and written out in §5.3. The skill budget is two auto-firing.

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/minute_tick_test.dart`
- **Test** — `'the ticker fires on the minute boundary, once, and disposes with its last listener'`
- **Why it is red today** — nothing ticks; the pen board would grow its own timer.

```bash
fvm flutter test test/features/minute_tick_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion into the three properties the name promises, each provable separately inside a
`testWidgets` body (which is where the binding's *advancing* fake clock lives):

1. **On the boundary, not on subscribe.** Subscribe at a moment that is 17 s past a minute, collect
   emissions, `tester.pump(const Duration(seconds: 43))`, and assert the second emission's
   `epochMillis % 60000 == 0`. Subscribing at :17 and ticking at :17 would pass a naive "it emits every
   60 s" test and is the bug this assertion exists to catch — thirty tiles updating at thirty different
   seconds past the minute is the noise decision #66 rejects.
2. **Once.** Over five simulated minutes the emission count is 6 (the immediate one plus five), not 10
   and not 300. Two listeners see the **same** stream, not two loops.
3. **Disposes with its last listener.** Cancel the subscription, pump two minutes, and assert **no
   further emission** reaches a listener re-subscribed afterwards from the original generator — i.e.
   that a *new* subscription starts a *new* loop with its own immediate emission. Do **not** assert
   that no timer is pending: see the `async*` tail in §5.3.

**Green.** The minimum code that passes, and nothing beyond it — the provider, boundary alignment computed from the current instant, and a disposal
assertion.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 4 (wiring) and step 7 (tests), plus one line of step 5.** No schema — this task stores nothing;
say so in the commit message. No domain (the ticker *reads* `appNow()`, which is N04-T05's), no data,
no UI, no ARB string.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/time/ticker.dart` | **New.** `minuteTickProvider` and nothing else. Imports `package:flutter_riverpod/flutter_riverpod.dart`, `app_clock.dart` and `../../domain/time/instant.dart` |
| 2 | `lib/app.dart` | **Edit, one line.** `ref.invalidate(minuteTickProvider)` in the `AppLifecycleState.resumed` arm of `didChangeAppLifecycleState` (`02 §9.1`). Elapsed times are twenty minutes stale after a pocketed phone comes back |
| 3 | `tool/policy_allowlist.txt` | **Possibly edit — read §5.3 first.** `app.dart :: stream.invalidate` would be the fifth `[exempt]` line and R56 fixes the day-one total at four |
| 4 | `test/features/minute_tick_test.dart` | **New.** The anchor plus the emission, alignment, disposal and policy cases |
| 5 | `test/features/minute_tick_dst_test.dart` | **New.** `@Tags(['uk-zone'])` with the `setUpAll` offset guard. Boundary arithmetic across the repeated hour and the missing hour |

Note that `lib/app.dart` is edited but `lib/core/time/app_clock.dart` is not: `appNow()` already
exists and is already the one allowlisted `DateTime.now(` site.

### 5.2 The signatures

One provider, one line of declaration, and the body is `01 §7.2`'s. Both `01 §7.2` and `07 §9.2` print
a body; they are behaviourally identical because every IANA offset is a whole number of minutes, so
`epochMillis % 60000` and *(seconds + millis into the local minute)* are the same quantity. Take
`01 §7.2`'s: it allocates no `DateTime` per tick and it cannot be misread as zone-dependent.

```dart
// lib/core/time/ticker.dart
//
// A single heartbeat for every time-relative display in the app (decision #66,
// CONVENTIONS §3.3, R25). Aligned to the wall-clock minute so every pen tile
// updates in the SAME frame — a grid whose cells change at different moments
// reads as noise under a head torch.
//
// `.autoDispose` is load-bearing, not tidiness (02 §4.2, 07 §9.2): a plain
// StreamProvider stays subscribed for the life of the ProviderScope, so this
// loop would wake the process every 60 s all night with no pen board on screen.
//
// It yields `Instant`, never a raw `DateTime` (R25). `minuteTickerProvider` and
// `penTickProvider` are banned spellings.
//
// Consumers: the pen board (07 §9), the withdrawal countdown (07 §10) and the
// Reminders day boundaries (07 §11.1). All three take `now` as a parameter and
// none of them reads a clock (R24).
final minuteTickProvider = StreamProvider.autoDispose<Instant>((ref) async* {
  while (true) {
    final now = appNow();                     // the ONE wall-clock reader (R23)
    yield now;
    final msToNextMinute = 60000 - (now.epochMillis % 60000);
    await Future<void>.delayed(Duration(milliseconds: msToNextMinute));
  }
});
```

And the one line in `lib/app.dart`, inside the `resumed` arm that N11-T05 already wrote:

```dart
      case AppLifecycleState.resumed:
        // …ResumePolicy, _hiddenAt = null…
        ref.invalidate(minuteTickProvider);   // elapsed times are 20 min stale
```

### 5.3 The details that are easy to get wrong

- **`stream.invalidate` bans `ref.invalidate(` under `lib/`, and this task writes one.** The rule
  landed in N03-T06 with the reason *"drift tracks tables; manual invalidation is a stale read"*, and
  it carries no exemption. `02 §4.1` is explicit that the ban is *scoped to drift-backed providers*
  and that `ref.invalidate(minuteTickProvider)` on resume is *"the whole allowance; a second one is a
  defect"* — but the gate is a text scan and cannot see the distinction. **You have exactly two honest
  moves.** Either (a) add `app.dart :: stream.invalidate` as a fifth `[exempt]` line, with the reason
  in the commit message, and flag it as the first line of the PR body — R56 says a fifth is *"a review
  conversation, not an edit"*; or (b) narrow the rule's pattern so it fires on every
  `ref.invalidate(` **except** the one whose argument is `minuteTickProvider`, which is a rule-table
  change and belongs in the same commit with the same reasoning. What you may **not** do is drop the
  invalidate: without it, a phone pocketed at 03:20 and reopened at 03:41 shows every pen tile twenty
  minutes stale, and that is a number a shepherd acts on.
- **The `async*` generator does not stop when the last listener goes — it stops at its next `yield`.**
  `07 §9.2` states the limitation and accepts it: *"after the last listener goes the pending
  `Future.delayed` still completes — up to 60 s of tail. That is one wake-up, once, and it is cheaper
  than the `StreamController` plumbing that would avoid it."* So a disposal test that asserts "no
  pending timer" is asserting something false, and the fix somebody will reach for — a
  `StreamController` with `onCancel` — is the plumbing this shape deliberately declines. Prove
  disposal by proving the *subscription* is gone and a new one starts a new loop.
- **`Timer.periodic(` is banned under `lib/` by `net.sync_timer` and the rule carries no exemption**
  precisely because this file uses `Future.delayed`. If you find yourself needing an exemption, you
  have written the wrong shape.
- **Boundary alignment is computed from the instant you just yielded, not from a stored start time.**
  `60000 - (now.epochMillis % 60000)` re-derives the gap every iteration, so a delayed wake-up
  self-corrects on the next tick instead of accumulating drift for the rest of the night.
- **When `epochMillis % 60000 == 0` the expression yields 60000, not 0.** That is correct — you have
  just emitted on the boundary, so the next one is a full minute away. Do not "fix" it to `% 60000`
  again; that would produce a zero-delay loop and a hot spin.
- **`appNow()`, never `clock.now()` and never `DateTime.now()`.** `time.dart_clock` scans `lib/` and
  `test/` and allowlists exactly one file — `lib/core/time/app_clock.dart` — so a direct clock read
  here is a red build. This is also why the ticker cannot be unit-tested by injecting a clock: there is
  no clock seam, by design (decision #46).
- **In a widget test you install no clock at all.** `AutomatedTestWidgetsFlutterBinding` runs every
  `testWidgets` body inside a `FakeAsync` zone and installs that zone's clock as `package:clock`'s
  ambient clock, so `tester.pump(const Duration(minutes: 1))` really does move what `appNow()` returns
  **and** fires the pending `Future.delayed`. That is the only mechanism available: `package:fake_async`
  is not a declared dependency, and importing it trips `depend_on_referenced_packages`.
- **Never wrap a ticker test in `atFixed`.** `Clock.fixed` freezes `now()`, so every emission carries
  the same instant, the boundary arithmetic returns the same gap forever, and the test passes while
  measuring nothing (decision #113). Put a comment saying so above the one `atFixed` call the DST file
  legitimately makes.
- **It yields `Instant`, and `Instant` is an extension type over `int`.** A `StreamProvider<DateTime>`
  compiles and puts an unwrapped instant in the UI layer, which is exactly what `Instant` exists to
  prevent (R25). `StreamProvider` itself is **not** on decision #18's banned list; `StateProvider` and
  `StateNotifierProvider` are.
- **Sixty seconds, not thirty.** Display granularity is hours (`07 §9.2`, `06 §14`), so a 30 s tick
  doubles the wake-ups and changes nothing on screen.
- **`lib/core/` may not import `lib/data/`.** The ticker reaches nothing and nothing reaches it except
  through the provider. If you find yourself importing `providers.dart` here, you have put a data
  dependency on a clock.
- **This is a `lib/core/time/` file, and its test is in `test/features/`.** That is the anchor path
  this task was given and it is kept. `R57` mirrors `lib/features/` in the widget tier, and the ticker
  is only observable through a pumped tree — so the placement follows the tier, not the source folder.

### 5.4 The full test set

Two files. Both are `testWidgets`, because the advancing fake clock only exists inside the widget
binding.

`test/features/minute_tick_test.dart`:

| Case | What it asserts |
|---|---|
| `'the ticker fires on the minute boundary, once, and disposes with its last listener'` | **The anchor.** The three properties in §4 |
| `'the first emission is immediate'` | A tile must not be blank for up to 60 s after the board opens. `expect(emissions, hasLength(1))` before any pump |
| `'the second emission lands on the boundary when the first did not'` | Subscribe at :17, pump 43 s, assert `epochMillis % 60000 == 0`. The alignment property, isolated |
| `'five simulated minutes produce six emissions'` | Not ten, not three hundred. The rate, isolated |
| `'two listeners share one loop'` | Two subscriptions, five minutes, and each sees six emissions rather than twelve between them |
| `'a re-subscription after the last listener leaves starts a new loop with an immediate emission'` | The `.autoDispose` property, expressed the way the `async*` shape allows |
| `'the provider yields Instant, not DateTime'` | `isA<Instant>()` on the first emission. Cheap, and it is the R25 property |
| `'Timer.periodic appears nowhere under lib/'` | Source-text sweep. Duplicates `net.sync_timer` deliberately, in the tier a developer runs first |
| `'exactly one ticker provider is declared in lib/'` | Source text: one `StreamProvider.autoDispose<Instant>` and zero occurrences of `minuteTickerProvider` or `penTickProvider` |
| `'ref.invalidate appears exactly once under lib/, in app.dart, with minuteTickProvider'` | The policy assertion that keeps the allowance from becoming a habit (`02 §4.1`). This is the test that makes the `[exempt]` decision safe |

`test/features/minute_tick_dst_test.dart` — `@Tags(['uk-zone'])`, `setUpAll` asserting
`DateTime(2026, 7, 1).timeZoneOffset == Duration(hours: 1)` and failing with the zone it found
(N04-T08's pattern):

| Case | What it asserts |
|---|---|
| `'the boundary gap is 60 s inside the repeated hour'` | 25 October 2026, 01:30 BST → 01:31: the ticker's arithmetic is over epoch millis, so the repeated hour changes nothing. The case exists because *"it happens twice"* is exactly the intuition that produces a special case here |
| `'the ticker does not emit twice for the same wall-clock minute'` | Across 01:59 → 01:00 (clocks back), consecutive emissions are strictly increasing in `epochMillis` even though the local rendering goes backwards. A tile ordering by local time would flicker; ordering by `Instant` does not |
| `'the boundary gap is 60 s across the spring-forward gap'` | 29 March 2026, 00:59 GMT → 01:00, which does not exist locally. `Instant` arithmetic is absolute; nothing skips and nothing doubles |
| `'the one atFixed call in this file is a single-instant assertion'` | A comment, not an assertion — but the file must carry it above the `atFixed`, per `12 §2.4`'s convention, and the reviewer checks it |

## 6. Constraints that bind this task

- **The 3am test** — thirty tiles updating in thirty different frames is the failure this ticker
  exists to prevent, and it is a legibility failure, not a performance one.
- **Timestamps carry provenance** — the ticker yields *now*, and nothing it feeds is ever stored.
  Elapsed time is bucket A (`01 §7.2`): computed at render, never cached, never a column.
- **Every consumer takes `now` as a parameter** (R24). `timeSincePenned(enteredAt, now)` is pure and
  reads no clock; if a consumer reaches for `appNow()` itself, the tick is not what drives it.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. `sync` is worth naming twice here: a periodic wake-up is exactly the thing the vocabulary bans the word for.

## 7. Definition of Done

- [ ] `'the ticker fires on the minute boundary, once, and disposes with its last listener'` passes, and was seen to fail first for the stated reason
- [ ] exactly one ticker in the app, held by a policy assertion
- [ ] aligned to the boundary, not to the subscribe moment
- [ ] `autoDispose`, and proved to dispose
- [ ] no `Timer.periodic` anywhere under `lib/`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the provider is `StreamProvider.autoDispose<Instant>` in `lib/core/time/ticker.dart`; `minuteTickerProvider` and `penTickProvider` appear nowhere
- [ ] the ticker calls `appNow()` and never `clock.now()` or `DateTime.now()`
- [ ] `lib/app.dart`'s `resumed` arm calls `ref.invalidate(minuteTickProvider)`, and `ref.invalidate(` appears **exactly once** under `lib/`
- [ ] **the `stream.invalidate` collision is closed one of the two ways in §5.3, the reason is in the commit message, and it is the first line of the PR body** — never left as a silent gate suppression
- [ ] no disposal assertion claims "no pending timer"; the `async*` tail is documented in the file
- [ ] `test/features/minute_tick_dst_test.dart` is tagged `uk-zone`, guards its offset in `setUpAll`, and is reported by `TZ=Europe/London fvm flutter test --tags uk-zone`

## 8. Verification

```bash
fvm flutter test test/features/minute_tick_test.dart
TZ=Europe/London fvm flutter test test/features/minute_tick_dst_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone --reporter expanded   # confirm the new file is counted
make check
make test
```

```bash
grep -rn "Timer.periodic" lib/                              # expect zero
grep -rn "minuteTickerProvider\|penTickProvider" lib/ test/  # expect zero
grep -rn "ref.invalidate(" lib/                              # expect exactly one, in app.dart
grep -n "clock.now()\|DateTime.now(" lib/core/time/ticker.dart   # expect zero
grep -c "" tool/policy_allowlist.txt                         # read the [exempt] section by hand
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(core): minuteTickProvider, one boundary-aligned ticker`

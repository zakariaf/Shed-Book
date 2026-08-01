---
name: shed-riverpod-providers
description: flutter_riverpod 2.6.1 pinned exactly, every Riverpod 3 API banned. Use for any provider, notifier, controller, ref.watch, ref.read, AsyncValue, autoDispose, family, select, rebuild scope or jank, and whenever copying Riverpod published after 2025. Do NOT use for repository methods (shed-write-path).
---

# Riverpod 2.6.1 — providers, controllers, rebuild scope

Authorities: `docs/engineering/02-state-di-navigation.md` (owns this area),
`docs/engineering/CONVENTIONS.md` §3 (the closed provider catalogue),
`docs/research/00-tech-decisions.md` §5 (the only source of versions). Cite them; do not restate them.

## 1. The pin — `flutter_riverpod: 2.6.1`, no caret

`^2.6.1` is a defect: CI asserts the exact string in `pubspec.yaml` and the resolved version in
`pubspec.lock`. Why (02 §1): `riverpod` 3.x declares `test: ^1.0.0` in **runtime** dependencies →
`analyzer <13` → cannot coexist with `drift_dev` ≥2.34.1, so `flutter pub get` fails outright.
WONTFIX upstream. 3.x is uninstallable here, not merely undesirable.

- If `pub get` fails with solver output naming `test ^1.0.0`, someone raised the pin — revert it. Never
  loosen the constraint; never take the `any`-constraint workaround, which resolves only by pinning
  `drift_dev` back to 2.34.0.
- Always `import 'package:flutter_riverpod/flutter_riverpod.dart';`, never `package:riverpod/riverpod.dart`
  — it is transitive, not declared, and gate G2 scans direct dependencies.
- The whole surface used here: `Provider`, `FutureProvider`, `StreamProvider`, `NotifierProvider`,
  `.family`, `.autoDispose`, `.select`, `ProviderScope`, `ProviderContainer`. Nothing else. `lib/domain/`
  imports no Riverpod; providers live only in `lib/data/`, `lib/core/`, `lib/features/`.

## 2. Riverpod 3 is banned — all of it

Assume any Riverpod you did not write is 3.x; every tutorial published after 2025 shows the 3.x form.
This is the likeliest way the codebase silently breaks. Full list and CI rows: 02 §2.1–§2.4. The ones
actually copied:

- **Family args through the constructor.** 3.x uses the constructor; 2.6.1 uses `build(Arg arg)` with a
  **zero-argument** tear-off (`C.new`) and an inherited `arg` getter.
- **`Notifier` + `.autoDispose`.** 2.6.1 has distinct bases: `AutoDisposeNotifier`,
  `AutoDisposeAsyncNotifier`, `AutoDisposeFamilyNotifier`, `AutoDisposeFamilyAsyncNotifier`.
- **`ref.mounted` does not exist.** Track disposal with a `bool _disposed` set from `ref.onDispose` —
  that is why `WriteController` carries one (§7).
- **Never write the type name `Ref`.** 2.6.1's `Ref<State>` type parameter is deprecated; let the
  create-callback parameter infer, and use the inherited `ref` inside a notifier.
- **No codegen.** `@riverpod`, `riverpod_annotation`, `riverpod_generator`, `riverpod_lint` are
  internally unresolvable. Providers are hand-written, one line each; drift is the only generator.
- **Compiles but banned:** `StateProvider`, `StateNotifier`, `StateNotifierProvider`, `ChangeNotifierProvider`, and
  **every `AsyncValue` accessor** — `.value`, `.valueOrNull`, `.requireValue`, `.hasValue`, `.asData`.
- **Absent here:** `ProviderContainer.test`, `WidgetTester.container`, `Mutation`/`ref.mutate`,
  `hooks_riverpod`/`flutter_hooks`, Riverpod 3 offline persistence, `ProviderScope(retry:)`.

**Read `references/riverpod3-symptoms.md` when a Riverpod snippet fails to compile, when the analyzer
flags a provider/notifier/`Ref`, or before adapting Riverpod copied from outside this repo.** It maps
the exact error text — or the silent wrong behaviour — to the 2.6.1 spelling.

## 3. Shapes, names, disposal

The spelling card is 02 §3. The **closed catalogue of every provider** — name, type, file and dispose
policy, one row each, together with the plausible-looking spellings that are **banned** — is
`CONVENTIONS.md` §3.1–§3.4. Look yours up there before you declare it: a provider not in that list is
a convention change, not an implementation detail, and a name that reads right is as likely to be a
banned row as a correct one. Never copy a row of §3 into a skill, a comment or a PR description —
cite it, so there is only ever one list.

Auto-dispose policy is a rule about *kinds*, not a second list of names (02 §4.2):

- **keepAlive** — `databaseProvider`, repositories, gateways, settings, and the hub reads §3.2 marks
  as such. Reopening SQLite or re-querying the hub on every pop at 03:41 is the wrong trade.
- **`.autoDispose.family`** — per-animal reads and controllers; a season of browsing must not leave 400
  live drift subscriptions. **`.autoDispose`, always** — write controllers.
- `minuteTickProvider` — `.autoDispose` is load-bearing: nothing ticks when no elapsed time is shown. It
  yields `Instant`, never `DateTime` (R25).
- `ref.keepAlive()` is used nowhere. Reaching for it means `.autoDispose` landed on a hub provider; remove
  the `.autoDispose` instead.

Family arguments are the cache key, compared with `==`. Use the extension-type ids from `lib/domain/ids.dart`
(`EweId`, `LambId`, `LambingId`). Never a `List`, never a hand-written class without verified `==`/`hashCode`
— you create and leak a provider instance per rebuild.

## 4. One drift statement per screen; fan-in in SQL

- **`combineLatest` over drift streams is a build-breaking defect** (07 §1.2). drift#3338: two streams
  written in one transaction can emit at different times, so the combination renders a state that never
  existed in the database. If two values must agree for the screen to be correct they are **one SQL
  statement** — `WITH … UNION ALL`, not Dart.
- One **content** statement per screen. It may also watch single-row lookups and the app-level
  singletons `settingsProvider`, `entitlementProvider`, `tagIndexProvider`, `minuteTickProvider`.
- Quick Entry's two strips are **one** provider, `quickEntryDeckProvider`, read with `.select` (R28).
- **Never `ref.invalidate` a drift-backed read provider.** `watch()` already re-emits; a manual
  invalidate means the write bypassed drift or the query is missing a table in `readsFrom:`. The ban
  is scoped to drift-backed **reads** (02 §3), and **exactly two call sites in `lib/` are legitimate,
  neither of them a read**: `ref.invalidate(minuteTickProvider)` on `AppLifecycleState.resumed`
  (02 §9.1, R25 — a wall-clock ticker with no database behind it), and
  `ref.invalidate(databaseProvider)` at step 14 of restore (04 §7, `shed-export-and-restore`) — the
  live database file has been *replaced*, so re-opening it is the point, not a stale-read patch.
  A third is a defect. `stream.invalidate` scans all of `lib/` with no `[exempt]` line (R56's four),
  so both call sites are expected red until the row narrows to drift-backed reads or the two lines
  are allowlisted (`CODE-REVIEW-CHECKLIST §1.5`, an open gate question) — **raise it; never delete
  the call to green the gate.**

## 5. `watch` / `read` / `listen` / `.select`

- `ref.watch` — **only** in `Widget.build()` and `Notifier.build()`. In a callback it creates a subscription
  per tap that is never released: the app degrades over a night.
- `ref.read` — **only** in callbacks, event handlers, controller methods. In `build()` the widget stops
  updating and shows a stale ewe at 3am.
- `ref.listen` — **only** in `build()`, unconditional, at the top, never inside an `if`. Side effects live
  here: haptics, the receipt, navigation, screen-reader announcements.
- Neither `ref.watch`-in-callback nor `ref.read`-in-`build` is CI-catchable. Check them by eye.
- **Anything reachable through `.select` is a stored field computed once in the state class's factory —
  never a getter that allocates a collection.** A getter returning a fresh `List` rebuilds on every emission
  *and* re-runs the filter once per comparison: strictly worse than no `.select`.
- A stored `List` still has identity `==`, so it deduplicates **nothing**; what it removes is the
  recomputation during the frame. Select a scalar (`s.query`, `s.matches.length`) for real deduplication,
  and never add `listEquals` to close the gap — it costs more than the rebuild it prevents.

## 6. Reading an `AsyncValue`

Exhaustive `switch` over `AsyncData` / `AsyncError` / `AsyncLoading`, **no `default:`**, no accessor
anywhere (02 §4.5). Three consequences that are not stylistic:

1. **`AsyncLoading` is never a spinner** — a fixed-height placeholder in the same dark colour, so
   nothing shifts when data lands. A spinning white ring under a head torch is a flashbang.
2. **`AsyncError` is never silent.** When `databaseProvider` fails every downstream provider is
   `AsyncError`; the keypad stays interactive but event buttons become an honest failure row. A tap
   must never look like it recorded something when it did not.
3. **Never `?? 0`** on a nullable aggregate — an unknown statistic is `notComputableReason`, not zero.

## 7. The DI graph and `WriteController`

- Root is `databaseProvider : FutureProvider<AppDatabase>`, opened on the first post-frame callback with
  `ref.onDispose(db.close)`. There is **no** `Provider<AppDatabase>` and no `overrideWithValue(db)`.
- Asynchrony is contagious upwards: repository providers are `FutureProvider`s that
  `await ref.watch(databaseProvider.future)`; read providers fold the open away with
  `StreamProvider((ref) async* { … yield* repo.watchX(); })`.
- **Production has zero overrides** — `runApp(const ProviderScope(child: ShedBookApp()))`.
  `overrideWith`/`overrideWithValue` are CI-banned in `lib/`; they live in `test/` and `tool/seed.dart` only.
- **The clock is not a provider.** One ambient `package:clock`, read only through `appNow()` in
  `lib/core/time/app_clock.dart` (R23). No `clockProvider`, no `Clock` interface, no `SystemClock`; tests
  use `withClock(...)`, never an override.
- **Tests override leaves, never controllers**: `databaseProvider` and the seven gateways — a fake repository
  or controller tests the fake. Use `ProviderContainer(overrides: […])` with `addTearDown(container.dispose)`
  (2.6.1 does not register it for you), an in-memory drift database with `closeStreamsSynchronously: true`,
  handed to the tree via `UncontrolledProviderScope`.
- **Every mutation goes through `WriteController.guard()`** (02 §7), which assigns `state = const WriteRunning()`
  **synchronously, before the first `await`** — that assignment *is* the double-tap gate. A cold gloved thumb
  through a freezer bag double-fires; without the gate the second fire is a second lambing record.
- `guard()` prevents concurrency, not repetition: after completion a second tap is a legitimate second write,
  and idempotence beyond that is the repository's job. **A UI cooldown is not the mechanism** — it would drop
  a real second lamb. Taps are never debounced.
- `WriteDone` deliberately has **no `==`**: two identical outcomes in a row must each fire `ref.listen`, because
  each completed write owes the user its own feedback.
- Switch over `WriteOutcome` covers all three variants, no `default:`. **`WriteRefused` is not a failure** — it
  renders as the calm static upgrade row, never a modal, never as an error.
- **`WriteCommitted.warnings` is populated by the controller, never by a repository (R53).** `lib/data/` may not
  import `lib/domain/validation/`, so a repository is structurally incapable of producing a `Warning`; it returns
  `WriteCommitted(insertedId: …)` with the default empty list. The controller runs the domain validators against
  the freshly-watched row and passes the `List<Warning>` to `confirmSaved`. Warnings are flagged, never fixed,
  and never block a save (spec §12.4).

## 8. Rebuild scope and performance

- **Never store a time-relative value** (01 §7.1–§7.2). The storage half of that rule — which values,
  and why a column may not hold one — is **shed-drift-schema**'s. This skill owns the render half:
  compute from the instant `minuteTickProvider` yields, with domain functions taking `now` as a
  parameter and never reading a clock (R24). One app-level ticker, boundary-aligned to the wall-clock
  minute — never a `Timer.periodic` per row.
- `QuickEntryScreen` is a `StatelessWidget` that watches nothing, so the `const` `_Keypad` is structurally
  incapable of rebuilding. Making it a `ConsumerWidget` to "just watch one thing here" destroys every child's
  `const`-ness. Filter in the controller, once per keystroke — never `where`+`toList` inside `build()`.
- `ListView.builder` with `itemExtent`; `ValueKey(id)` on rows; no `Opacity`/`ShaderMask`/`ColorFilter` in a row
  (they force `saveLayer`); **never override `operator ==` on a widget** (O(N²)).
- Exactly two debounces exist in `lib/`: 200 ms on note search, 400 ms on free-text fields. **No debounce on the
  keypad** — the match is sub-millisecond and a debounce puts visible lag between thumb and digit. A third is a
  defect. Measure in profile mode on a real low-end device with the 400-ewe fixture, never the simulator.

## 9. Gotchas that defy the obvious assumption

- **A `Notifier` instance survives its own `build()` re-run**, but `state` does not. **Anything the user typed
  lives in a private field on the notifier**, and `state` is seeded from it at the end of `build()`. Without
  this, an unrelated flock change silently wipes digits a shepherd just typed — a real 3am data loss.
- **A controller holds screen state, never data.** Mirroring drift rows into state gives two sources of truth
  and the wrong one wins at 3am.
- **Controllers hold no draft** — no `save()`, no `isDirty`, no `commit()`; every field is its own committed
  write and there is no Save button in this app. They hold no `BuildContext`, never navigate, never format for
  display (no `DateFormat`, no unit conversion, no terminology lookup), and never import drift.
- **There is no SnackBar in this app** (ruling P2). 02 §4.3/§7 still say "SnackBar" — superseded, and
  `showSnackBar(` is banned everywhere including `lib/core/ui/feedback.dart`. Call `confirmSaved` /
  `showFailure` / `showCapRow` (R30) from `ref.listen`; **indelible-states-and-feedback** owns what
  they render, so do not describe the receipt from here.
- **Nothing on the 3am path watches `entitlementProvider`** (decision #90) — the failure mode is a paywall flash
  at 3am.
- **`WidgetsBindingObserver` does nothing without `addObserver(this)`** in `initState` and `removeObserver(this)`
  in `dispose`. The mixin compiles and the overrides look valid while no lifecycle callback ever fires —
  silently killing the resume policy and the wakelock release.
- **`Clock.fixed` freezes `now()`.** Widget tests already have an advancing fake clock; pinning `now` makes every
  "hours since penned" readout silently measure 0 h. Offset the seed data instead.

## Scope — do NOT use this skill for

- Repository methods, event verbs, transactions, `WriteOutcome`/`ShedFailure` mapping →
  **shed-write-path** (it points at R53 here rather than repeating it).
- drift tables, queries, views, `readsFrom:`, migrations → **shed-drift-schema**.
- Screen layout, widget composition, `Navigator`, route helpers, `PopScope` → **shed-screens-and-routing**.

## Definition of done

- [ ] `pubspec.yaml` has `flutter_riverpod: 2.6.1`, no caret; `pubspec.lock` committed.
- [ ] `flutter analyze --fatal-infos` clean — this alone proves no Riverpod-3-only class or named parameter
      survives. `dart run tool/check_policy.dart` passes (it carries the `rp3.*` rows from 02 §2.4).
- [ ] No `AsyncValue` accessor anywhere; every read site is an exhaustive `switch` with no `default:`.
- [ ] `ref.mounted`, the type name `Ref`, `@riverpod` and `showSnackBar(` appear nowhere in `lib/`.
- [ ] `lib/` has zero `overrideWith`/`overrideWithValue`, zero `ref.keepAlive()`, and exactly one
      `ref.invalidate` per call path — `minuteTickProvider` on resume, and `databaseProvider` at
      restore step 14. Neither is a drift-backed read.
- [ ] Every provider was checked against `CONVENTIONS.md` §3 — name, type, file, dispose policy — and
      against §3.2–§3.4's banned spellings, by opening that file rather than from memory.
- [ ] No `combineLatest` over drift streams; every screen has one content statement.
- [ ] Every mutation goes through `WriteController.guard()`, which assigns `WriteRunning` before its first
      `await`. Every destructive action has a two-tap test **with no pump between the taps**, asserting one row.
- [ ] `ref.watch` only in `build()`; `ref.read` only in callbacks and controller methods; every `ref.listen`
      unconditional at the top of `build()`.
- [ ] No derived collection is a getter; every `.select` target is a stored field.
- [ ] No time-relative value is stored, in a table or in controller state.

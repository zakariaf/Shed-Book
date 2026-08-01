# Riverpod 3 symptoms → the 2.6.1 spelling

A diagnostic index. You are here because a Riverpod snippet did not compile, the analyzer flagged a
provider, or you are about to adapt code copied from outside this repo.

**The canonical spelling card is `docs/engineering/02-state-di-navigation.md` §3** — eight rows
covering every provider shape this app uses, with the corrected family example. Read it once; this
file only routes a symptom to the right row of it. The full ban list and its CI rules are 02
§2.1–§2.4.

Default diagnosis: **the snippet is Riverpod 3.** Everything published after 2025 is.

---

## A. It does not compile — the analyzer caught it

| What you see | Diagnosis | Fix |
|---|---|---|
| `The named parameter 'retry' isn't defined` on `ProviderScope` / `ProviderContainer` | 3.x auto-retry | Delete the line. 2.6.1 has no auto-retry, so there is nothing to disable, and no pitfall to port. |
| `'X' doesn't conform to the bound 'AutoDisposeNotifier<S>'` | `Notifier` used with `.autoDispose` | `class X extends AutoDisposeNotifier<S>`. Same shape for `AutoDisposeAsyncNotifier<S>` (02 §3). |
| `'C' doesn't conform to the bound 'AutoDisposeFamilyAsyncNotifier<T, Arg>'` **and/or** `The argument type 'C Function(int)' can't be assigned to the parameter type 'C Function()'` | 3.x delivers family args through the constructor | Extend `AutoDisposeFamilyAsyncNotifier<T, Arg>` (or `AutoDisposeFamilyNotifier<S, Arg>`), take the arg in `build(Arg arg)`, pass a **zero-argument** tear-off `C.new`, and read `this.arg` inside. Copy the worked example in 02 §3 rather than re-deriving it. |
| `The named parameter 'isAutoDispose' isn't defined` | 3.x flag | Use the builder: `AsyncNotifierProvider.autoDispose.family<C, T, Arg>(C.new)`. |
| `The getter 'mounted' isn't defined for the type 'Ref'` | `ref.mounted` is 3.x only | Track disposal by hand: a `bool _disposed` field set from `ref.onDispose`. `WriteController` (02 §7) already does this — subclass it rather than inventing a second mechanism. |
| `strict-raw-types` or `deprecated_member_use` on a written `Ref` type | 2.6.1's `Ref<State>` type parameter is deprecated; 3.x unified `Ref` | **Never name `Ref` in this codebase.** Let the create-callback parameter infer (`Provider<T>((ref) => …)`); inside a notifier use the inherited `ref`. |
| `ProviderObserverContext` is undefined, or an override "doesn't match the supertype" | 3.x `ProviderObserver` | 2.6.1's signature is `didUpdateProvider(ProviderBase<Object?>, Object? previousValue, Object? newValue, ProviderContainer)`; the class is `abstract class`, not `abstract base class`. Permitted only as a `kDebugMode` logger wired to nothing that persists or transmits. |
| `The method 'test' isn't defined for the type 'ProviderContainer'` | `ProviderContainer.test()` is 3.x | `ProviderContainer(overrides: […])` + `addTearDown(container.dispose)` — 2.6.1 does not register the teardown for you (02 §5.4). |
| `The getter 'container' isn't defined for … WidgetTester` | `tester.container` is 3.x | Build your own container and pass it via `UncontrolledProviderScope(container: …, child: …)`. |
| `Mutation` / `ref.mutate` undefined | 3.x, and experimental even there | `WriteController.guard()` (02 §7) is the only write gate in the app. |
| `Undefined name '_$…Hash'`, a missing `.g.dart`, or `build_runner` cannot resolve `riverpod_generator` | `@riverpod` codegen | There is no Riverpod codegen here — `riverpod_generator` and `riverpod_lint` are internally unresolvable at every published version. Hand-write the provider; it is one line. drift is the only generator (decision #16). |
| `pub get` fails with solver output naming `test ^1.0.0` and `drift_dev` | the pin was raised | Restore `flutter_riverpod: 2.6.1` exactly, no caret. Do not use the `any`-constraint workaround: it resolves by pinning `drift_dev` back to 2.34.0 (02 §1). |

---

## B. It compiles and is still wrong

These are the dangerous half: the analyzer is happy, and the defect shows up at 3am.

| What you see or wrote | Why it is wrong | Fix |
|---|---|---|
| `AsyncValue.value`, `.valueOrNull`, `.requireValue`, `.hasValue`, `.asData` | Removed or reshaped in 3.x, and every one is a place to render a stale or null value | Exhaustive `switch` over `AsyncData` / `AsyncError` / `AsyncLoading`, no `default:` (02 §4.5). Four spellings are grepped by CI; bare `.value` is reviewer-only, so check it deliberately. |
| `StateProvider`, `StateNotifier`, `StateNotifierProvider`, `ChangeNotifierProvider` | Legacy; moved to `legacy.dart` in 3.0 | `NotifierProvider` over a `Notifier` and an `@immutable` state class. |
| `import 'package:riverpod/riverpod.dart';` | Compiles — `riverpod` is transitive — but gate G2 scans direct dependencies | `import 'package:flutter_riverpod/flutter_riverpod.dart';` |
| `hooks_riverpod`, `flutter_hooks`, `useProvider` | A second mental model for twelve simple screens, plus the 3.x runtime dependency | Not in this project. |
| `CircularProgressIndicator` in an `AsyncLoading` arm | A spinning white ring under a head torch is a flashbang, and the layout shifts when data lands | Fixed-height placeholder in the same dark colour (02 §4.5). |
| `ref.watch(...)` inside a callback | Creates a subscription per tap that is never released; the app degrades over a night | `ref.read` in callbacks, `ref.watch` only in `build()`. Not CI-catchable. |
| `ref.read(...)` inside `build()` | The widget stops updating and shows a stale ewe | `ref.watch`. Not CI-catchable. |
| `ref.invalidate(someDriftBackedProvider)` after a write | drift's `watch()` already re-emits; the invalidate is masking a write that bypassed drift or a query missing a table in `readsFrom:` | Delete it and fix the query. Two call sites in `lib/` are legitimate and neither is a drift-backed read: `minuteTickProvider` on resume (02 §9.1) and `databaseProvider` at restore step 14, where the database *file* was replaced (04 §7). |
| `combineLatest` / `Rx.combineLatest` / `StreamZip` over two drift streams | drift#3338: two streams written in one transaction can emit at different times, so the combination renders a state that never existed in the database | One SQL statement — fan-in with `WITH … UNION ALL` (07 §1.2). |
| `.select((s) => s.someGetterReturningAList)` | The getter allocates a fresh `List` each call and `List`'s `==` is identity, so it rebuilds on every emission *and* re-runs the filter once per comparison | Store the collection as a field computed in the state class's factory (02 §4.4). |
| A family keyed by a `List`, a record of raw values, or a hand-written class without verified `==`/`hashCode` | The key is compared with `==`, so a new provider instance is created and leaked per rebuild | Use the extension-type ids from `lib/domain/ids.dart`. |
| `ref.keepAlive()` | It only appears because `.autoDispose` was put on a hub provider | Remove the `.autoDispose` instead (02 §4.2). |
| A one-time setup in a `Notifier` constructor, or user input held only in `state` | The notifier instance is preserved across `build()` re-runs while `state` is not, so an unrelated dependency change wipes typed input | Private field on the notifier; seed `state` from it at the end of `build()` (02 §3, §10.2). |

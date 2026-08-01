# N30-T01 — `PurchaseService` — the store seam and its fake

| | |
|---|---|
| **Epic** | [N30 — Monetization](epic.md) · `00-README` §9 step 11 |
| **Task** | 1 of 8 |
| **Depends on** | N29-T08 |
| **Commit** | one commit · `feat(gateway): PurchaseService and its fake` |

## 1. Why this task exists

The seventh gateway: `kUnlockProductId`, `PurchaseSignal`, `StoreUnreachable`, and
`FakePurchaseService`. `StoreUnreachable` is a first-class outcome, not an error — the shepherd is in a
shed with no signal, and the app must behave correctly when the store cannot be reached, which is most
of the time it will be asked.

Two structural facts make one file worth its own commit. **It is the only file in the app permitted to
import `package:in_app_purchase`**, and the rule that says so is only enforceable because no plugin
type crosses the seam in either direction: the moment a public signature names `List<PurchaseDetails>`,
`entitlement_repository.dart` has to import the plugin to name its own callback, and
`layer.in_app_purchase` becomes a comment CI cannot check. And **`_onBatch` acknowledges before it
signals** — a three-day auto-refund window depends on that ordering, and nothing repairs the wrong one.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/11-monetization-and-store.md` | **§5** (the class printed in full, the seven plugin members used, the plugin-free seam) · **§5.1** (the two moments the store is consulted, the drain exception, the 14-day bound) · **§5.2** (the acknowledgement window and the acknowledge-then-write order) · §6.3 (the five-row `PurchaseStatus` → `PurchaseSignal` mapping) · §1.1 (`kUnlockProductId`, the plugin versions) · §2 (`PurchaseService`, `purchaseServiceProvider`, `PurchaseSignal`, `StoreUnreachable` — the names, and why each spelling is the only one permitted) · §3.3 (the four allowlist lines and the 0.4.8 floor) · **§12.1** (`layer.in_app_purchase` and `launch.store_call`, both halves) · §12.2 (what `purchase_service_test.dart` asserts) | the whole file, and both gate rows |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree — `lib/data/purchase_service.dart`, `test/support/`) · §1.1 layer rules **3, 4, 8** · §2.12 (**the seventh seam, and it is the store seam**) · §3.1 (`purchaseServiceProvider` — `Provider<PurchaseService>`, keepAlive, *"same shape as `shareServiceProvider`"*) · §4.1–§4.2 (file and class naming; `Gateway` is not a suffix and `Store` is reserved to `MediaStore`) · §4.7 + **R54** (dotted rule ids; a duplicate rule is a rule weakened twice) · §5.2 (**gateway**, never adapter/wrapper/client) · §5.3 (`pending` is banned as a model state) · **R74** | **BINDING**: the path, the class name, the provider, and the two banned-name lists |
| `docs/engineering/12-testing.md` | **§4.2** (the seven fakes; `FakePurchaseService` records *"a scripted `updates` stream you drive from the test"* and `List<String> calls`, and its tripwire is *"any store call during a `pumpApp` of a shed screen"*) · §4.1 (`implements`, **never** `extends`) · §4.5 (the anti-patterns) · **§5.1** (`shedContainer` already names `purchaseServiceProvider` in its printed override list) | the fake's shape, and where it plugs in |
| `docs/engineering/01-architecture.md` | §3.2 (the dependency allowlist) · §4.1 (gateways are concrete `final class`es in `lib/data/`) · §6.3 (the banned `main()` lines) · §5.1 (the six `ShedFailure` variants — none of them is a store failure) | the layer, and what a store failure is not |
| `docs/research/00-tech-decisions.md` | **§5.1** (`in_app_purchase` **3.3.0**) · §2 #87 (one non-consumable, one binary, one bundle id) · #89 (`purchase_in_flight_at` and the drain) · #90 (nothing on the shed path branches on `unlocked`) · §1 #5 and §3.4 (the four `in_app_purchase*` packages and the honest exceptions) | the version and the model |
| `epics/00-PLAN-CRITIQUE.md` | §11.4 (N30's skills) · §11.5 (the gates inside the sequence) · G4 | the skills, and N03-T07's inventory assertion |
| `shed-book-spec.md` | §14 | one-time unlock, no subscription, a cap that must not degrade 3am |
| `CLAUDE.md` | offline purity · the banned words · *"never edit `tool/check_policy.dart`… to make a build pass"* | what may and may not be added to the gate |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-monetization` | the store seam, the product id and the signals are its subject |
| `shed-platform-gateways` | the gateway's shape and its fake follow the same rules as the other six |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/purchase_service_test.dart`
- **Test** — `'StoreUnreachable is a first-class signal and the app remains fully usable when it is returned'`
- **Why it is red today** — nothing talks to the store, and the app has no unlock path.

```bash
fvm flutter test test/data/purchase_service_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it cannot pass for the wrong reason. Drive a plugin double whose
`queryProductDetails` never completes, assert `queryUnlockPrice()` throws `const StoreUnreachable()`
**inside the ten-second bound rather than after it**, and assert in the same test that it is not a
`ShedFailure` — `expect(const StoreUnreachable(), isNot(isA<ShedFailure>()))` — because the whole
design rests on a shed with no signal being the normal case rather than a fault.

**Green.** The minimum code that passes, and nothing beyond it — the gateway, the signals, and the fake joining `pumpApp`'s override list in this
commit.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step, no domain step.** This gateway stores nothing and computes nothing — say so in the
commit message. It is §8 step 3 (the data layer), step 4 (wiring) and step 7 (tests), plus two gate
rows.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/purchase_service.dart` | **New.** The only `package:in_app_purchase` call site in the app (R74). Holds `kUnlockProductId`, `StoreUnreachable`, `enum PurchaseSignal` and `final class PurchaseService`. The rule id goes in the file's header comment, so the next reader learns it here rather than from a red build |
| 2 | `lib/data/providers.dart` | **Edit.** One line: `purchaseServiceProvider`. `Provider<PurchaseService>`, keepAlive, not `async` — the same shape as `shareServiceProvider` (`CONVENTIONS §3.1`). It is deliberately **not** a `FutureProvider`: nothing is initialised at construction, which is the whole point |
| 3 | `tool/check_policy.dart` | **Edit.** Two rows — `layer.in_app_purchase` and `launch.store_call`. N03-T01's own comment names them: *"`layer.in_app_purchase` / `launch.store_call` with monetization (N30). A row and the case that proves it fires land in the same commit — always."* |
| 4 | `test/policy/gate_rules_test.dart` | **Edit.** Three planted-violation cases (both halves of `layer.in_app_purchase`, plus `launch.store_call`). **N03-T07's inventory assertion fails the build on a rule id with no case here**, so this file is not optional |
| 5 | `test/support/fake_purchase_service.dart` | **New.** The seventh fake. `implements PurchaseService`, never `extends` — so a signature change is a compile error rather than a silent divergence (`12 §4.1`) |
| 6 | `test/support/harness.dart` | **Edit.** `12 §5.1`'s printed `shedContainer` already carries the `FakePurchaseService? purchases` parameter and `purchaseServiceProvider.overrideWithValue(purchases ?? FakePurchaseService())`. This commit makes that line **compile**. Cross the last row off the header's fake ledger — it has been outstanding since N12-T05 |
| 7 | `test/data/purchase_service_test.dart` | **New.** The anchor and the nine cases in §5.4 |

**Not touched, and each absence is a check:** `pubspec.yaml` and `pubspec.lock` (the dependency landed
in N00-T03; a lockfile diff with no `pubspec.yaml` diff is a review stop), `tool/policy_allowlist.txt`
(N03-T04 wrote the four `in_app_purchase*` lines), `android/expected_permissions.txt` (N02's G0
recorded `com.android.vending.BILLING`), `lib/main.dart` and `lib/app.dart` (`launch.store_call` is
about to make that mechanical).

**Before you write line one, read `pubspec.lock`.** If `in_app_purchase_storekit` resolves below
**0.4.8**, stop: promote it to a direct dependency at `^0.4.8`, move its allowlist line from
`[transitive]` to `[dependencies]` with the reason in the message, and land that as **its own commit**
(`00-README §7.4`). A 0.4.3-era resolution reports a StoreKit 2 purchase as `restored` and leaves it
unfinished (flutter#172434). It costs an unlock, and it does it silently.

### 5.2 The signatures

`11 §5` prints this class in full and it is not a sketch. Type it as written; the deviations that look
harmless are the ones §5.3 names.

```dart
// lib/data/purchase_service.dart
// The ONLY file in the app permitted to import package:in_app_purchase.
// Rule id: layer.in_app_purchase.
import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Frozen at the first sale. Byte-identical in App Store Connect and in
/// Play Console. Changing it strands every purchase ever made.
const kUnlockProductId = 'shed_book_unlock';

/// The store did not answer inside the bound. Deliberately NOT a ShedFailure:
/// a shed with no signal is the normal case, not a fault (11 §6.2).
final class StoreUnreachable implements Exception {
  const StoreUnreachable();
}

/// Everything the rest of the app is allowed to learn from a store update
/// about OUR product. No plugin type crosses this line.
enum PurchaseSignal { awaitingPayment, purchased, restored, cancelled, failed }

final class PurchaseService {
  PurchaseService([InAppPurchase? iap]) : _iap = iap ?? InAppPurchase.instance;

  static const _bound = Duration(seconds: 10);

  /// Two readers: EntitlementRepository writes the row, UnlockController
  /// renders the section. Neither imports the plugin, and neither has to know
  /// whether `purchaseStream` is broadcast.
  Stream<PurchaseSignal> get updates;

  void attach();                       // idempotent; subscribing is what initialises billing on Android
  Future<void> detach();               // cancels the plugin subscription; does NOT close the fan-out
  Future<bool> isAvailable();          // bounded; false on timeout
  Future<String?> queryUnlockPrice();  // throws StoreUnreachable on timeout; null if the id is unconfigured
  Future<bool> buyUnlock();            // false when no ProductDetails was resolved in this process
  Future<void> restore();              // no applicationUserName; replays through `updates`
}
```

```dart
// lib/data/providers.dart
final purchaseServiceProvider = Provider<PurchaseService>((ref) => PurchaseService());
// keepAlive (R74). Nothing on a shed screen may watch it, and lib/main.dart /
// lib/app.dart may not name it (launch.store_call).
```

The plugin surface used is **exactly seven members**: `instance`, `purchaseStream`, `isAvailable`,
`queryProductDetails`, `buyNonConsumable`, `restorePurchases`, `completePurchase`. There is no
`getPlatformAddition`, no `enableStoreKit1()` and no `buyConsumable`. Reaching for an eighth is a `11`
conversation, not an implementation detail.

The two gate rows, in `CONVENTIONS §4.7`'s dotted grammar:

| Rule id | Fails on | Scope |
|---|---|---|
| `layer.in_app_purchase` | `package:in_app_purchase` imported anywhere but `lib/data/purchase_service.dart`, **or** any of `PurchaseDetails`, `ProductDetails`, `PurchaseStatus`, `PurchaseParam`, `InAppPurchase` appearing outside that file | `lib/` |
| `launch.store_call` | `PurchaseService` or `purchase_service.dart` referenced in `lib/main.dart` or `lib/app.dart` | those two files |

### 5.3 The details that are easy to get wrong

- **The seam is plugin-free on the way *out*, and that is the load-bearing half.** An import ban is
  trivially satisfied by a public signature that returns a plugin type — and then the *caller* imports
  the plugin to name it, legitimately, and the rule holds on paper while the architecture is gone. That
  is why `layer.in_app_purchase` carries a second clause banning the five token names, and why `updates`
  is a `Stream<PurchaseSignal>` and the price crosses as a bare `String`.
- **`_onBatch` completes *before* it emits, and the comment saying so is not decoration.** Google
  auto-refunds and revokes if a purchase is not acknowledged within **three days**. Acknowledge-then-write
  leaves a window one process-death wide in which the purchase is acknowledged and the row unwritten —
  repaired by the Restore button Apple already requires. Write-then-acknowledge produces an auto-refund
  three days later, and **nothing repairs that**.
- **Completion runs for every non-`pending` update whose `pendingCompletePurchase` is true, regardless
  of product id.** An unrecognised id left uncompleted is redelivered forever. The `productID` check
  gates the **signal**, not the completion — and the two lines sit one apart, which is exactly how they
  get swapped.
- **Never complete a `pending` purchase.** Google's own wording: *"don't acknowledge it while a purchase
  is in PENDING state."* On Android `completePurchase` **is** `acknowledgePurchase()`.
- **The `switch` over `PurchaseStatus` is exhaustive with no default arm, deliberately.** Five members,
  five arms. A `default:` or a `_ =>` turns a sixth member in a future plugin major from a compile error
  into a silently-ignored purchase.
- **`attach()` initialises the Android billing client; the constructor does not.** Subscribing to
  `purchaseStream` *is* the initialisation. That is why `purchaseServiceProvider` is a plain `Provider`,
  and it is why decision #90 survives T04 putting this provider transitively on the Quick Entry path.
  Nothing on a shed screen calls `attach()`, and `FakePurchaseService`'s tripwire is what proves it.
- **`detach()` cancels the plugin subscription and does *not* close the fan-out.** The provider is
  keepAlive and a later `attach()` must work. A `_signals.close()` here is a *"Bad state: Cannot add new
  events after calling close"* on the next Settings visit.
- **`isAvailable()` and `queryUnlockPrice()` bound differently on purpose.** `isAvailable()` times out
  to `false`; `queryUnlockPrice()` times out by **throwing** `StoreUnreachable`. They produce two
  different lines on screen — `productNotFound` versus `storeUnreachable` — and collapsing them loses
  the distinction between *"your store is unreachable"* and *"this product is not configured"*, which is
  the difference between a shed and a broken Play Console entry.
- **`queryUnlockPrice()` returns `null` when the store answers but the id is absent.** Null is not an
  error and must not be mapped to one.
- **`_product` is process-lifetime only.** Never persisted, never written to a table, never held in a
  provider that survives a restart. A stored price goes stale, and a stale price in front of a user is
  the same class of dishonesty as a stale clear date shown as current.
- **`onError` on the plugin subscription swallows, deliberately.** *"An offline app is never blocked by
  a store stream error."* It does **not** log: a store failure is not a `ShedFailure` and must not reach
  the diagnostics log as one, or the log fills with a hundred non-events (`11 §6.2`, and decision #124's
  spirit).
- **No retry, no `Timer`, no back-off, no background attempt.** The retry is the user tapping the button
  again. A `Timer.periodic` here is Flutter's `offline-first` cache-over-network pattern arriving by the
  back door — and `offline-first` is a banned word in our own prose.
- **`pending` is a banned model state.** `PurchaseStatus.pending` is the *plugin's* word and appears
  inside this one file only. That asymmetry is the seam doing its job; our signal is `awaitingPayment`.
- **Layer rule 4 still applies.** `lib/data/` may not import `package:flutter/material.dart`. The plugin
  pulls Flutter transitively and that is fine; a `material.dart` import in this file is not.
- **`launch.store_call` deliberately does not name `InAppPurchase`.** `layer.in_app_purchase` already
  bans that token everywhere under `lib/`; a duplicate is a rule that gets weakened twice (R54).
- **`tool/policy_allowlist.txt` is not edited.** R56 fixes the `[exempt]` section at four lines on day
  one, and adding a fifth to keep a new rule quiet is the named anti-pattern.

### 5.4 The full test set

| File | Case | What it holds |
|---|---|---|
| `test/data/purchase_service_test.dart` | **anchor** — `'StoreUnreachable is a first-class signal and the app remains fully usable when it is returned'` | The bound fires, the type is thrown, and it is not a `ShedFailure` |
| | `'_onBatch completes every non-pending update whose pendingCompletePurchase is true, including an unrecognised product id'` | A batch of `kUnlockProductId` + `'some_other_id'`, both `purchased`, both `pendingCompletePurchase`: two `completePurchase` calls |
| | `'a pending update is never completed'` | One `pending` update with `pendingCompletePurchase: true`; zero `completePurchase` calls |
| | `'a signal is emitted only for kUnlockProductId'` | The unrecognised id is completed and produces **no** entry on `updates` |
| | `'completion happens before the signal is emitted'` | Record both into one ordered `List<String>` on the plugin double and compare the list. Assert the **order**, not that both happened — §5.2's three-day window is this case |
| | `'the five PurchaseStatus members map to the five PurchaseSignal members'` | Table-driven, one row per member, against `11 §6.3`'s table |
| | `'queryUnlockPrice returns null when the store answers with no matching product'` | `productNotFound`, distinguishable from `storeUnreachable` |
| | `'isAvailable returns false on timeout rather than throwing'` | The other bound, the other behaviour |
| | `'buyUnlock returns false when no product was resolved in this process'` | The only way to reach the store without a `ProductDetails` in hand |
| | `'attach twice creates one subscription, and detach then attach works'` | Idempotence, and the fan-out surviving `detach()` |
| `test/policy/gate_rules_test.dart` | `'layer.in_app_purchase exits 1 on a planted import outside purchase_service.dart'` | Half one |
| | `'layer.in_app_purchase exits 1 on a planted ProductDetails token outside purchase_service.dart'` | **Half two — the half that makes half one hold** |
| | `'launch.store_call exits 1 on a planted PurchaseService reference in lib/app.dart'` | The launch path |

**No `uk-zone` case, and say why in the file's header comment.** Nothing in this task is time-shaped:
`_bound` is a `Duration` over a plugin call, and this file never calls `appNow()`, never touches
`Instant` and never reads a local hour. The epic's two ambiguous-hour cases belong to **T02** (the
14-day drain bound must be absolute, never civil-day arithmetic) and **T05** (the quiet window). A
`uk-zone` tag on a file with no wall-clock read is noise that dilutes the tag.

**Fakes, not mocks — with the *plugin* as the one exception.** `FakePurchaseService` is the
hand-written fake of *our* class, for everybody else's tests. Inside this file you also need a double
for `InAppPurchase` itself, injected through the optional constructor parameter. That is the one place
in this task `mocktail` could earn its keep (`12 §4.4`: *"ordering across two seams"*), but a small
hand-written `_FakeInAppPurchase` with an ordered `calls` list reads closer to the spec and is
preferred.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'StoreUnreachable is a first-class signal and the app remains fully usable when it is returned'` passes, and was seen to fail first for the stated reason
- [ ] `StoreUnreachable` is a signal, never an exception
- [ ] the app is fully usable while the store is unreachable
- [ ] the fake is the seventh in `test/support/`, completing `12 §4.2`'s list
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

> **Reading line two.** `StoreUnreachable` is declared `implements Exception` because Dart's `throw`
> wants it, and it is thrown by exactly one method inside exactly one file (`11 §5`). What the line
> forbids is treating it as one *outside* the seam: it is never a `ShedFailure` variant, never reaches
> `showFailure`, never carries an error haptic, never renders red, and never appears in the diagnostics
> log. T03's `UnlockController` converts it to `UnlockUnavailable(storeUnreachable)` at the boundary,
> and nothing above the seam catches a store type again.

## 8. Verification

```bash
fvm flutter test test/data/purchase_service_test.dart
fvm flutter test test/policy/gate_rules_test.dart
dart run tool/check_policy.dart
grep -rn "package:in_app_purchase" lib/                  # exactly lib/data/purchase_service.dart
grep -rnE "PurchaseDetails|ProductDetails|PurchaseStatus|PurchaseParam|InAppPurchase" lib/   # the same one file
grep -rn "PurchaseService\|purchase_service" lib/main.dart lib/app.dart    # nothing
grep -n "in_app_purchase_storekit" -A2 pubspec.lock      # must resolve >= 0.4.8
git diff --stat -- pubspec.yaml pubspec.lock tool/policy_allowlist.txt     # nothing
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(gateway): PurchaseService and its fake`

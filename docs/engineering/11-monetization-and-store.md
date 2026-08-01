# 11 — Monetization and store compliance

This document governs every line of code that touches money, and every artefact the two stores demand
from an app that collects nothing. It settles the business model, what `in_app_purchase` does to the
Android manifest and which of the offline claims survive it, the entitlement row and the three rules
that make it safe on a phone that never sees a network again, the one-file plugin seam and the
plugin-free signal that crosses it, the purchase and restore flows and their four states, the
`FreeTierPolicy` object and the hard constraints on the upgrade affordance, and both stores' privacy
declarations. Read `07-screens.md` for where the two upgrade rows sit and
what they say, `06-design-system.md` for the component they are made of, and
`03-data-model-and-schema.md` for the table shapes this document writes to. Nothing here may put a
store call on the launch path, and nothing here may render on a shed screen.

> **Decisions applied:** #87 free app + one non-consumable unlock, one binary, one bundle ID · #88 the
> entitlement is a locally-persisted row, written once, never revoked, excluded from the backup ·
> #89 `purchase_in_flight_at` and the three-day acknowledgement window · #90 the first frame is
> entitlement-agnostic · #91 one policy object consulted by the repository, with `EntryContext` as an
> explicit parameter · #92 no modal ever; two static rows · #93 "Data Not Collected" / "No data
> collected or shared", `PrivacyInfo.xcprivacy`, a hosted privacy-policy URL · #86 export is never
> gated by the free tier · #5 the manifest-merger check runs against a real release AAB before any
> `tools:node="remove"` line, and the four `in_app_purchase*` packages join the offline allowlist ·
> #17/#18/#19 `flutter_riverpod` 2.6.1 spellings only · #13 writes return `WriteOutcome` · #123/#124
> no telemetry, redacted local diagnostics only · #128 build number = CI run number, seasonal release
> freeze. **Owner's rulings (§7.0):** the free tier is **season-primary with the ewe cap secondary**,
> it never surfaces mid-entry and never between **22:00 and 06:00**; UK/Ireland first (`en_GB`, 24 h,
> `d MMM y` in front of a human); tag OCR and voice tag entry are cut from v1, so no monetization
> surface may ever be attached to them.

---

## 1. The model

### 1.1 What ships

**A free app with one non-consumable in-app purchase that unlocks it forever.** One binary, one
bundle identifier, one store listing per platform, no flavors, no second SKU, no subscription — ever
(decision #87).

| | Decision |
|---|---|
| Plugin | `in_app_purchase` **3.3.0** (flutter.dev, 2026-06-03), the version in `00-tech-decisions.md` §5.1 |
| StoreKit floor | `in_app_purchase_storekit` **≥ 0.4.8** — 0.4.3 reported StoreKit 2 purchases as `restored` and left them unfinished (flutter#172434) |
| Play Billing | **8.0.0**, arriving via `in_app_purchase_android`. Billing 8 is mandatory from **31 Aug 2026** and 8.0.0 already satisfies it; Billing 9 is mandatory **31 Aug 2027** — a Q1-2027 calendar item, not a v1 item |
| Product kind | **Non-consumable.** Not a consumable, not an auto-renewing subscription, not a "XX-day Trial" tier-0 item |
| Product id | `shed_book_unlock` — declared once, frozen at the first sale, byte-identical in App Store Connect and Play Console |
| Flavors | **None.** With IAP there is nothing to vary at build time; a second bundle id is exactly what App Review 4.3(a) forbids |

The rejected models, so nobody re-opens them: **paid up front** kills the spec §14 trial and Apple's
only sanctioned trial mechanism for a non-subscription app is itself an IAP, so "paid with a trial"
still ships StoreKit; **two SKUs** is a direct hit on App Review 4.3(a) and, decisively, a second app
sandbox means the shepherd's first season does not follow them into the paid app, which destroys the
§7.7 retention thesis; **`purchases_flutter` (RevenueCat)** is a mandatory third-party network path
with an API key and forces a Play "Purchase history collected" declaration, which destroys the
collects-nothing claim; **a time-limited trial** expires on night eleven, which spec §15 names as the
retention test; **server-side receipt validation** requires a server.

### 1.2 The one sentence that governs everything else

> The store is the source of a **one-time fact**, not a runtime dependency. Ask it exactly twice —
> when the user taps Unlock, and when the user taps Restore. Write the answer to SQLite. Never ask
> again.

Every rule in §4, §5 and §6 is a consequence of that sentence.

---

## 2. Names this document adds

`CONVENTIONS.md` is the naming authority and this document adopts every name it defines — `EntryContext`,
`CapDecision`, `Allow`, `BlockedByCap`, `RefusalReason`, `FreeTierPolicy`, `EntitlementRepository`,
`entitlementProvider`, `freeTierPolicyProvider`, `showCapRow` (R69, R30). Monetization was designed in
ignorance of the offline audit and vice versa (critique c3 B1), so a handful of names genuinely do not
exist yet. Each one below follows `CONVENTIONS.md` §4 and is **flagged**, with the clause it follows and
the document that owns the file it lands in.

| Name | File | Follows | Owner to fold it in |
|---|---|---|---|
| `PurchaseService` | `lib/data/purchase_service.dart` | §4.2 "Service / gateway → `<Name>Service` … touches one plugin" | **Folded in — `CONVENTIONS.md` R74.** §2.12 is now "six platform seams and one store seam", §1's tree carries the file, and §5.2's collective noun follows. `Gateway` is not a class suffix and `Store` is reserved to `MediaStore` (§5.2), so `PurchaseService` is the only spelling §4.2 permits |
| `purchaseServiceProvider` | `lib/data/providers.dart` | §4.3 `<typeNameLowerCamel>Provider`; `Provider<PurchaseService>`, keepAlive, like `shareServiceProvider` | **Folded in** — `CONVENTIONS.md` §3.1 (R74) and `02-state-di-navigation.md` §5.1 |
| `kUnlockProductId` | `lib/data/purchase_service.dart` | `const` top-level; the store id, frozen forever | this document |
| `PurchaseSignal` | `lib/data/purchase_service.dart` | §4.2 has no row for an enum declared beside its gateway, so it takes the value-type rule — **no suffix**. `PurchaseStatus` is rejected (it is the plugin's own type name, and the whole point is that the two are different), `PurchaseResult` and `PurchaseEvent` too (§5.2 reserves *event* for a row in a history table). It exists so `layer.in_app_purchase` is a gate rather than a comment: it is the **only** thing that crosses the seam (§5) | this document |
| `StoreUnreachable` | `lib/data/purchase_service.dart` | §4.2 "Sealed result — no suffix; variants are nouns". §5.3 permits the name: `Error` is the banned failure-type word, and this is deliberately **not** a `ShedFailure` variant (§6.2) | this document |
| `UnlockController`, `UnlockState` and its four variants | `lib/features/settings/unlock_controller.dart` | §4.2 "Screen controller `<Screen>Controller`" + "Immutable screen state `<Screen>State`" | §3.4's declared controller list gains `unlockControllerProvider` |
| `kFreeEweCap`, `kFreeSeasonCount`, `isQuietHours(Instant)` | `lib/domain/free_tier.dart` | §2.10 gives 11 the members of this file | this document |
| `SeasonRepository.startSeason(...)` | `lib/data/season_repository.dart` | §2.13 — `SeasonRepository` already owns `seasons`; the verb is the second gated write and no document names it | `CONVENTIONS.md` §2.13's canonical verb list, and `03-data-model-and-schema.md` §5.14 |
| `app_settings.last_unlock_prompted_at` | `lib/core/db/tables/` | R40's precedent (`last_reconcile_scheduled`, `left_handed`): a nullable `INTEGER` instant a screen needs and 03 did not declare | **`03-data-model-and-schema.md`, and it must land before the first schema snapshot** |
| `Routes.settings(context, {bool focusUnlock = false})` | `lib/routing/routes.dart` | an argument on an existing push helper — **not** a fourteenth `RouteNames` entry | `02-state-di-navigation.md` §8.1 |

Nothing else is added. There is no `StoreGateway`, no `PurchaseRepository`, no `paywallProvider`, no
`UpgradeRow` widget (the component is `ShedBanner`, and 06 owns it), no `unlock` route, and no
`shared_preferences`.

---

## 3. What `in_app_purchase` does to the manifest, and which offline claims survive

### 3.1 The permission set — nine names, eight lines

~~The eight-entry permission set~~ — **struck 2026-08-01. G0 measured nine.**
`00-tech-decisions.md` §3.3 is canonical and is not re-typed here any more, because it now carries
two blocks — what the artefact declared and what N31 changes — and a reproduction of one of them
reads as the whole. What this document owes the reader is the monetization half:

- **`in_app_purchase_android`'s own manifest is empty.** Verified: `<manifest package="io.flutter.plugins.inapppurchase"></manifest>` and nothing else.
- **The Play Billing 8.0.0 AAR merges `com.android.vending.BILLING`** and, in the merged manifest, nothing else — read off a real release `.aab` on **2026-08-01**, not off the 2.0.3 mirror, which is struck. ~~Treat "billing 8.0.0 adds nothing else" as highly likely and **unverified**.~~
- **What was missed was not the AAR but its Gradle graph.** `com.android.billingclient:billing:8.0.0` has `com.google.android.datatransport:transport-backend-cct:3.1.8` as a **compile-scope** dependency, and *that* library declares both `android.permission.INTERNET` and `android.permission.ACCESS_NETWORK_STATE`. Billing 8.0.0 also brings `play-services-base` 18.5.0, `play-services-basement` 18.4.0, `play-services-location` 19.0.0 and `play-services-tasks` 18.2.0; none of those contributed a permission to the 2026-08-01 build, and the location one was checked by name because a location permission in a lambing notebook's Play listing would be indefensible.
- **This is the reason "the billing AAR is a Play-Services-adjacent artefact whose transitive Gradle graph is reviewed on every bump" is a rule and not a caution.** The permissions were one edge further out than four documents assumed.
- **iOS merges nothing**, because iOS has no manifest permission model. StoreKit 2 is an XPC client of the system App Store daemon; `in_app_purchase_storekit` has used StoreKit 2 by default since 0.4.0.

### 3.2 G0 is a prerequisite, not a chore

**Before any `tools:node="remove"` line is committed** (decision #5, critique c3 B2):

```bash
flutter build appbundle --release
grep -n -i "INTERNET\|ACCESS_NETWORK_STATE" \
  build/app/outputs/logs/manifest-merger-release-report.txt
java -jar bundletool.jar dump manifest \
  --bundle build/app/outputs/bundle/release/app-release.aab \
  | grep -i "uses-permission"
```

Then **record the actual permission set contributed by Play Billing 8.0.0 in `00-tech-decisions.md`
§3.3**. **Done 2026-08-01** (N02-T01); §3.3 carries it and this section is kept because the procedure
is what a Billing Library bump re-runs, not because it is still owed.

Removing `INTERNET` is safe and proven — twice over, as of that build: the `.aab` built with the line
drops it and keeps the other six, and the debug and profile variants keep theirs.
~~**Removing `ACCESS_NETWORK_STATE` is not proven**~~ — **struck: it is not removed.** Three research
notes hard-coded that removal on the strength of a six-majors-old AAR; the measured answer is that
billing's own manifest declares neither network permission and a transitive Google telemetry library
declares both, so `13-build-ci-release.md` §2.2's *leave it* branch is the one that fires. Had the
removal been committed on faith, the failure would have surfaced as a purchase flow that misbehaves on
a flaky connection, in production, on somebody else's phone. ~~Until G0 has run, the offline gate is
**unwritten, not merely unimplemented**.~~ It has run; the gate is writable, and N31-T03 writes it.

The billing AAR is a **Play-Services-adjacent artefact**. Its transitive Gradle graph is reviewed on
every Billing Library bump, and the bump is never done in the same commit as anything else.

### 3.3 The allowlist entries

`tool/policy_allowlist.txt` gains four lines (critique c3 B1's ruling). Without them the gate fails on
day one, because it fails on any unlisted package:

```
[dependencies]
in_app_purchase                     # decision #87. The only unlock mechanism. flutter.dev 3.3.0.

[transitive]
in_app_purchase_android             # Play Billing 8.0.0 AAR. Merges com.android.vending.BILLING.
in_app_purchase_storekit            # StoreKit 2. MUST resolve >= 0.4.8 — see 00-tech-decisions §5.1.
in_app_purchase_platform_interface  # federated interface. No platform code.
```

If `pubspec.lock` resolves `in_app_purchase_storekit` below 0.4.8, promote it to a direct dependency
at `^0.4.8` and move its allowlist line to `[dependencies]` with that reason in the commit message.
A silent 0.4.3-era resolution costs an unlock and reports it as a restore.

### 3.4 Which offline claims survive — all of them, because none of them was ever tier 3

| Tier | Claim | Survives IAP? |
|---|---|---|
| 1 | The app has no network code and no `INTERNET` permission. Nothing in our process can open a socket. | **Yes.** `com.android.vending.BILLING` authorises binding to the Play Store's exported AIDL service. It is not a network permission. Without `INTERNET` our process still cannot open a socket, and G1 proves it against the shipped `.aab` on every push. |
| 2 | No dependency attempts a network call **from our process**. | **Yes.** Play Billing is binder IPC; StoreKit 2 is XPC. The socket belongs to the Play Store app or to the App Store daemon. |
| 3 | No data ever leaves the device by any route. | **Never claimed**, before or after IAP. The share sheet already broke it, deliberately. |

**The only public wording permitted stays exactly as it is**, verbatim, and monetization does not
amend a word of it:

> "Shed Book has no account, no server and no sync. The Android build ships without the internet
> permission, so the app itself cannot connect to anything. Your records only leave the phone when you
> deliberately export and share them."

State the boundary honestly wherever anyone asks: during a purchase, bytes move on the device's
behalf, in **someone else's process**. That is a different sentence from "the app connects", and the
app's own permission line is the verifiable proof of the difference. Do not write *"your data never
leaves your phone"* — it is a banned string and `tool/check_policy.dart` fails the build on it.

---

## 4. The entitlement row

### 4.1 It is a row, not a query

`03-data-model-and-schema.md` §5.13 owns the table and it is four columns:

| Column | Type | Meaning |
|---|---|---|
| `id` | `INTEGER`, `CHECK (id = 1)` | the singleton |
| `unlocked` | `INTEGER NOT NULL DEFAULT 0` | the whole answer |
| `unlocked_at` | `INTEGER` nullable, `InstantConverter` | when we wrote it |
| `purchase_in_flight_at` | `INTEGER` nullable, `InstantConverter` | decision #89's flag |

Seeded by `seedFirstRun` in `onCreate` as `const EntitlementsCompanion()`, so the row exists from the
first millisecond and no code path ever handles "no entitlement row". The drift row class is
`Entitlement`, re-exported by `lib/data/models.dart`.

**What is deliberately not on the row**, against note 07's sketch: `product_id`, `store`,
`acquired_via`, `purchase_id`, `recorded_at_was_edited`. A `purchaseID` is store-account-adjacent data
that spec §4.5 gives us no reason to hold, the app has no support-email path to spend it on (no
`url_launcher`, no network), and decision #124's redaction list would forbid logging it anyway. If a
support workflow ever needs it, that is a schema conversation with 03, before a snapshot.

`unlocked_at` and `purchase_in_flight_at` are **machine facts about our own process**, not event
times. They carry no §12.5 provenance quad and are **not rendered anywhere in v1** — the unlocked
Settings section reads one word, "Unlocked.", with no date, no price and no receipt. If a date is
ever rendered, the quad lands on the table first (R37's standing rule: a table without the quad has
no edit verb, and nothing displays an unprovenanced time).

### 4.2 The three rules

**Rule 1 — write-once, never revoked.** The app never sets `unlocked` back to `0`. Both stores can
revoke after a refund, but detecting that means polling the store on the launch path, which is the one
thing this app refuses to do. Re-locking a shepherd on night nine because a refund propagated is
unacceptable against €12 of revenue. Deliberate, documented, and enforced by a policy rule
(`db.entitlement_revoke`, §12.1) and a policy test.

**Rule 2 — excluded from the backup, ignored on import.** The entitlement belongs to a store account,
not to a flock. Including it in the §7.9 JSON backup would turn the backup file into a licence key,
and restoring your neighbour's file must not unlock your app.
`04-migrations-media-backup-restore.md` already owns both halves: the export writer skips the table,
the importer skips and logs it, and there is a refusal fixture for a backup that carries one.

**Rule 3 — never in `shared_preferences`.** Prefs are a second source of truth that disagrees with the
database after a restore, and they are trivially editable. One file, one truth. As a bonus this
removes an `NSPrivacyAccessedAPICategoryUserDefaults` obligation from the app's own privacy manifest
(§9.2). `shared_preferences` is not in `00-tech-decisions.md` §5.1 and adding it is a dependency
review, not an edit.

### 4.3 How the app knows it is unlocked when it never sees a network again

It reads one row of its own SQLite file. That is the entire mechanism.

```dart
// lib/data/providers.dart
final entitlementProvider = StreamProvider<Entitlement>((ref) async* {
  final repo = await ref.watch(entitlementRepositoryProvider.future);
  yield* repo.watch();
});   // keepAlive. Nothing on a shed screen may watch this (decision #90).
```

`EntitlementRepository` (`lib/data/entitlement_repository.dart`, owns writes to `entitlements`, takes
`AppDatabase` and `PurchaseService`):

```dart
Stream<Entitlement> watch();                    // one row, .distinct() in the repository
Future<Entitlement> read();                     // the boot check and the policy call sites
Future<void> beginPurchase();                   // sets purchase_in_flight_at = appNow()
Future<void> markUnlocked({required bool restored});
Future<void> abandonPurchase();                 // clears purchase_in_flight_at
void attach();                                  // PurchaseService.attach() + listen(updates)
Future<void> detach();                          // cancels both; wired to ref.onDispose
```

`attach()` subscribes to `PurchaseService.updates`, which is a `Stream<PurchaseSignal>` and **not** a
stream of plugin types (§5). That is not tidiness: `entitlement_repository.dart` naming
`List<PurchaseDetails>` in a callback would import `package:in_app_purchase`, and
`layer.in_app_purchase` (§12.1) would then be a comment instead of a gate. This repository reacts to
exactly two signals — `purchased` → `markUnlocked(restored: false)` and `restored` →
`markUnlocked(restored: true)` — and ignores the other three, because a store failure never touches
the row (§4.2 rule 1).

`markUnlocked` is the one place `unlocked` is ever written and it does three updates in **one**
`db.transaction`:

```dart
Future<void> markUnlocked({required bool restored}) async {
  await _db.transaction(() async {
    final now = appNow();
    await (_db.update(_db.entitlements)..where((t) => t.id.equals(1))).write(
      EntitlementsCompanion(
        unlocked: const Value(true),
        unlockedAt: Value(now),
        purchaseInFlightAt: const Value(null),
      ),
    );
    // decision #91: on unlock the over-cap markers clear in one transaction.
    // No `where`: every marker in the file clears, which is the whole point.
    await _db.update(_db.ewes).write(
          const EwesCompanion(overFreeCap: Value(false)),
        );
    await _db.update(_db.seasons).write(
          const SeasonsCompanion(overFreeCap: Value(false)),
        );
  });
  // OUTSIDE the transaction, deliberately. LocalLog writes a file, a file
  // write can fail, and a failed diagnostics line must never roll back an
  // unlock the user has already paid for.
  LocalLog.instance.record(restored ? 'unlock.restored' : 'unlock.purchased');
}
```

> **The one documented exception to `CONVENTIONS.md` §2.13's table-ownership rule.**
> `EntitlementRepository` writes `ewes.over_free_cap` and `seasons.over_free_cap`, which belong to
> `FlockRepository` and `SeasonRepository`. Decision #91 requires the clear to be atomic with the
> unlock, and three repositories mean three transactions. The exception is narrow and stated in the
> method's doc comment: those two columns are **monetization bookkeeping that happens to live on two
> record tables** — written by their owners on insert, cleared here on unlock, and read by nothing
> else. No other cross-repository write exists in the app.

`LocalLog.instance.record` takes an event string and nothing else: never the `purchaseID`, never the
price, never a store error message. Decision #124's allowed list does not include any of them.

### 4.4 Nothing on the 3am path reads it

Decision #90, and it is the reason the entitlement can be read late without anyone noticing:

- `main()` reads nothing (`01-architecture.md` §6.3 lists "Reading the entitlement" among the banned lines).
- The first frame is the **unlocked-neutral** Quick Entry shell: an interactive keypad, no data, no branch on `unlocked`.
- Quick Entry, Lambing Entry, Lamb Card, Foster and Pen Board never watch `entitlementProvider` and never render a monetization widget at any entitlement state.
- The failure mode this prevents is a **paywall flash at 3am**. It is enforced by `test/features/no_monetization_test.dart`, not by discipline.

### 4.5 New device, no signal — the honest case

A shepherd restores a JSON backup from a USB stick in the shed, on a new phone, with no bars. Both
stores' entitlement caches (`Transaction.currentEntitlements`, `queryPurchasesAsync`) need the network
at least once to populate, and Apple's own DTS answer names this exact case; the underlying
`NSURLErrorDomain Code=-1009` is not cleanly catchable.

| State | What the app does |
|---|---|
| Backup restored, `unlocked = 0`, no signal | **Fully usable.** Every restored ewe is readable, editable, searchable and exportable. The cap is never applied retroactively — a restored 400-ewe flock is 400 real rows |
| User taps **Restore purchases**, no signal | Fails, calmly. `UnlockUnavailable(storeUnreachable)`. One line: *"Restoring your unlock needs a connection to the store, once. Everything else in Shed Book works with no signal."* The button stays exactly where it is; the retry is the user tapping it again |
| User taps **Unlock** instead, has signal, already owns it | Both stores handle it. Play returns `ITEM_ALREADY_OWNED`; StoreKit resolves it as a restore. Nobody is charged twice — and Restore sits **above** Unlock so the fear never arises |
| Signal returns three weeks later, user taps Restore | `purchaseStream` replays with `PurchaseStatus.restored`, the row is written, and it is written once |

**Say this plainly, do not bury it.** The one thing this app cannot do offline is prove a purchase it
has never seen. Everything else it can do.

---

## 5. The store seam — `PurchaseService`

The seventh gateway (§2). One hand-written class in `lib/data/`, wrapping exactly one plugin, replaced
by `FakePurchaseService` in `test/support/` — the same shape as the other six, so `test/support/` now
holds **seven** hand-written fakes.

**The seam is plugin-free on the way out, and that is load-bearing.** `purchase_service.dart` is the
only file permitted to import `package:in_app_purchase` (`layer.in_app_purchase`, §12.1). Therefore no
`PurchaseDetails`, `ProductDetails`, `PurchaseStatus` or `PurchaseParam` may appear in the *type* of
anything this class exposes — the moment it does, `entitlement_repository.dart` and
`unlock_controller.dart` have to import the plugin to name their own callbacks, and the rule becomes a
comment that CI cannot enforce. Exactly two things cross the seam: a `PurchaseSignal` and a `String`
price.

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
/// a shed with no signal is the normal case, not a fault (§6.2).
final class StoreUnreachable implements Exception {
  const StoreUnreachable();
}

/// Everything the rest of the app is allowed to learn from a store update
/// about OUR product. No plugin type crosses this line.
enum PurchaseSignal { awaitingPayment, purchased, restored, cancelled, failed }

/// Wraps in_app_purchase. Holds no database and no entitlement — only the
/// plugin subscription and the fan-out that lets two readers share it. Every
/// store call is bounded: a shed has no signal and a screen may not sit in a
/// contacting state forever.
final class PurchaseService {
  PurchaseService([InAppPurchase? iap]) : _iap = iap ?? InAppPurchase.instance;
  final InAppPurchase _iap;

  static const _bound = Duration(seconds: 10);

  final _signals = StreamController<PurchaseSignal>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// Process-lifetime only. Never persisted, never written to a table (§6.7).
  ProductDetails? _product;

  /// Two readers listen here: EntitlementRepository, which writes the row, and
  /// UnlockController, which renders the section. Neither imports the plugin,
  /// and neither has to know whether `purchaseStream` is broadcast.
  Stream<PurchaseSignal> get updates => _signals.stream;

  /// Idempotent. On Android, subscribing is what initialises the billing
  /// client — which is why this runs on Settings ▸ Unlock and on the bounded
  /// drain (§5.1), and never on the launch path.
  void attach() {
    _sub ??= _iap.purchaseStream.listen(
      _onBatch,
      // An offline app is never blocked by a store stream error.
      onError: (Object _, StackTrace __) {},
    );
  }

  /// Drops the plugin subscription. Does not close the fan-out: the provider
  /// is keepAlive and a later attach() must work.
  Future<void> detach() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<bool> isAvailable() =>
      _iap.isAvailable().timeout(_bound, onTimeout: () => false);

  /// Throws StoreUnreachable when the store does not answer inside the bound;
  /// returns null when it answers but the id is not configured. Those are two
  /// different lines on screen (storeUnreachable vs productNotFound) and must
  /// stay distinguishable. On success, returns ProductDetails.price — already
  /// localised by the store — and holds the ProductDetails for buyUnlock().
  Future<String?> queryUnlockPrice() async {
    final r = await _iap
        .queryProductDetails({kUnlockProductId})
        .timeout(_bound, onTimeout: () => throw const StoreUnreachable());
    _product = r.productDetails.isEmpty ? null : r.productDetails.first;
    return _product?.price;
  }

  /// False when the product was never resolved in this process, which is the
  /// only way to reach the store without a ProductDetails in hand.
  Future<bool> buyUnlock() async {
    final p = _product;
    if (p == null) return false;
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: p),
    );
  }

  /// No account, so no applicationUserName. Replays through `updates`.
  Future<void> restore() => _iap.restorePurchases();

  Future<void> _onBatch(List<PurchaseDetails> batch) async {
    for (final p in batch) {
      // Completion runs for EVERY non-pending update whose flag is set,
      // regardless of product id: an unrecognised id left uncompleted is
      // redelivered forever. On Android this call IS acknowledgePurchase().
      //
      // It runs BEFORE the signal, deliberately. If the process dies between
      // the two, the purchase is acknowledged and the row unwritten — which
      // Restore repairs. The other order risks an unacknowledged purchase,
      // which auto-refunds in three days and nothing repairs (§5.2).
      if (p.status != PurchaseStatus.pending && p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
      if (p.productID != kUnlockProductId) continue;
      _signals.add(switch (p.status) {
        PurchaseStatus.pending => PurchaseSignal.awaitingPayment,
        PurchaseStatus.purchased => PurchaseSignal.purchased,
        PurchaseStatus.restored => PurchaseSignal.restored,
        PurchaseStatus.canceled => PurchaseSignal.cancelled,
        PurchaseStatus.error => PurchaseSignal.failed,
      });
    }
  }
}
```

The plugin surface used is exactly that: `instance`, `purchaseStream`, `isAvailable`,
`queryProductDetails`, `buyNonConsumable`, `restorePurchases`, `completePurchase`. No
`getPlatformAddition`, no `enableStoreKit1()`, no `buyConsumable`.

### 5.1 The two moments the store is consulted, and the one exception

1. The user opens **Settings ▸ Unlock** — `attach()`, then `isAvailable()` + `queryUnlockPrice()`.
2. The user taps **Unlock** or **Restore purchases**.

The exception is decision #89's drain: **only if** `purchase_in_flight_at` is set **and**
`unlocked = 0`, the boot sequence calls `attach()` after the database opens (which is itself after the
first frame). Note 07's sketch attaches the listener unconditionally on every launch; that is
superseded, because subscribing to `purchaseStream` on Android initialises the billing client, and
initialising a billing client on a cold launch in a shed is exactly the thing this design exists to
avoid.

Bound the drain, or it is not self-clearing: if `purchase_in_flight_at` is **older than 14 days** and
`unlocked` is still `0`, call `abandonPurchase()` and do not attach. Google's acknowledgement window is
three days, a shepherd can be off-network for a week, and after fourteen days the transaction has
either been acknowledged or auto-refunded — continuing to initialise a billing client on every launch
forever buys nothing.

### 5.2 The acknowledgement window

Google auto-refunds and revokes entitlement if a purchase is not acknowledged **within three days** of
the state moving from `PENDING` to `PURCHASED`. The dangerous case is the one Google itself names: the
user pays, Play confirms, and the phone drops off the network before our app hears about it.

- `buyUnlock()` is preceded by `beginPurchase()`, which writes `purchase_in_flight_at`.
- `completePurchase` runs for **every** update where `pendingCompletePurchase` is true and the status is not `pending`, on every platform, regardless of product id. On Android that call *is* `acknowledgePurchase()`. Completing an unrecognised product id is harmless and stops an infinite redelivery loop; **writing the entitlement** happens only for `kUnlockProductId`. It lives inside `PurchaseService._onBatch` and nowhere else, because it takes a `PurchaseDetails` and only that file may name one.
- Never complete a `pending` purchase. Google: *"don't acknowledge it while a purchase is in PENDING state."*
- Acknowledge **first**, write the row **second** (§5's `_onBatch` comment). The window between them is one process death wide, and the failure it produces — paid, acknowledged, still locked — is repaired by the Restore button that Apple already requires. The reverse order produces an auto-refund three days later, which nothing repairs.

---

## 6. Purchase and restore flows

### 6.1 Where the surface lives

There is **no Unlock route.** `RouteNames` has thirteen entries and none of them is `unlock`; adding a
fourteenth would contradict `CONVENTIONS.md` §2.14. The surface is:

| Surface | Where | What it is |
|---|---|---|
| Upgrade row 1 | pinned top of the **Flock** screen | a `ShedBanner`, one action: **Unlock** → `Routes.settings(context, focusUnlock: true)` |
| Upgrade row 2 | **Settings ▸ Unlock** (section 9 of 12) | the same `ShedBanner` |
| The flow itself | **Settings ▸ Unlock** | **Restore purchases** above **Unlock**, both ≥ 60 pt |

`ShedBanner` is the only monetization component that exists (`06-design-system.md` §12). There is no
modal, no interstitial, no self-appearing bottom sheet, no badge, no colour change, no accent. The
upgrade row uses one of `ShedBanner`'s two action slots and has no dismiss action, because a permanent
row cannot meaningfully be dismissed.

**This surface is an accessibility ship gate, not just a screen.** Apple's Accessibility Nutrition
Labels require every declared feature to complete *all common tasks*, and
`10-accessibility-and-i18n.md` lists **unlock / restore purchase** as one of the seven. So the Unlock
section must be completable end to end under VoiceOver, Voice Control, Larger Text at 200% and
Differentiate Without Color Alone — including the `UnlockUnavailable` state, whose text is the only
thing that tells a screen-reader user why nothing happened.

### 6.2 `UnlockState` — four variants, and why `pending` is not one of them

`CONVENTIONS.md` §5.3 bans `pending` as a model state. The plugin's `PurchaseStatus.pending` is the
plugin's word, and our state is named for what the user is actually waiting on.

```dart
// lib/features/settings/unlock_controller.dart
sealed class UnlockState { const UnlockState(); }

/// The resting state. `price` is non-null only if the store answered in THIS
/// process. It is never persisted: a stored price goes stale, and a stale
/// price in front of a user is the same class of dishonesty as a stale clear
/// date shown as current.
final class UnlockOffered extends UnlockState {
  const UnlockOffered({this.price});
  // The store's own localised, currency-formatted string, arriving through
  // PurchaseService.queryUnlockPrice(). Not even the plugin's TYPE NAME may
  // be written in this file — layer.in_app_purchase scans for the token.
  final String? price;
}

/// A bounded store call is in flight. NO SPINNER: `ui.spinner` bans
/// CircularProgressIndicator under lib/features/. The Unlock button's label
/// swaps to "Contacting the store…" and the button is disabled.
final class UnlockContactingStore extends UnlockState { const UnlockContactingStore(); }

/// Android slow payment instruments (cash, bank transfer) and Apple's
/// Ask to Buy family-approval hold. Do not unlock, do not complete,
/// keep purchase_in_flight_at set.
final class UnlockAwaitingPayment extends UnlockState { const UnlockAwaitingPayment(); }

/// The store could not be reached, or refused, or the user backed out.
/// This is NOT a ShedFailure and never renders through showFailure().
final class UnlockUnavailable extends UnlockState {
  const UnlockUnavailable(this.reason);
  final UnlockUnavailableReason reason;
}

enum UnlockUnavailableReason { storeUnreachable, productNotFound, userCancelled, storeError }

final class UnlockController extends AutoDisposeNotifier<UnlockState> {
  StreamSubscription<PurchaseSignal>? _sub;

  @override
  UnlockState build() {
    ref.onDispose(() => _sub?.cancel());
    return const UnlockOffered();
  }

  /// PurchaseService.attach(), then isAvailable() + queryUnlockPrice(), then
  /// _sub = service.updates.listen(_onSignal). The subscription is what
  /// carries awaitingPayment / cancelled / failed back to this screen; it
  /// carries no plugin type, so this file never imports the plugin (§5).
  Future<void> openSection();
  Future<void> unlock();
  Future<void> restore();
}
```

`unlockControllerProvider = NotifierProvider.autoDispose<UnlockController, UnlockState>(UnlockController.new)`
— the Riverpod **2.6.1** spelling. `AutoDisposeNotifier`, never bare `Notifier` with `.autoDispose`;
zero-argument constructor tear-off; no `Mutation`, no `ProviderScope.retry`, no `AsyncValue.valueOrNull`.

**A store failure is not a `ShedFailure`.** There is no `StoreUnavailable` variant on `ShedFailure` and
there must never be one: the six variants are storage failures with six `userMessage` strings, they
render through `showFailure` with an error haptic, and they are the vocabulary of the Diagnostics
screen. A shed with no signal is the normal case, not a fault, and logging it as one would poison the
diagnostics log with a hundred non-events.

**Whether the section renders the entitlement or the flow.** `UnlockState` holds screen state and
never data (`CONVENTIONS.md` §4.4 rule 1). The truth about entitlement comes from
`entitlementProvider`. The section renders the product of the two: `unlocked = 1` → one word,
"Unlocked."; otherwise the two buttons plus whatever `UnlockState` says.

### 6.3 The state machine, end to end

| Trigger | Store call | `UnlockState` becomes | Row write |
|---|---|---|---|
| Section opens | `attach()`, `isAvailable()`, `queryUnlockPrice()` | `UnlockContactingStore` → `UnlockOffered(price: …)` | — |
| …store unreachable or timed out (`StoreUnreachable`) | — | `UnlockUnavailable(storeUnreachable)` | — |
| …`isAvailable()` false, or `queryUnlockPrice()` returned null | — | `UnlockUnavailable(productNotFound)` | — |
| Tap **Unlock** | `beginPurchase()` then `buyUnlock()` | `UnlockContactingStore` | `purchase_in_flight_at = appNow()` |
| Tap **Unlock**, `buyUnlock()` returns false | — | `UnlockUnavailable(productNotFound)`; `abandonPurchase()` | flag cleared |
| Tap **Restore purchases** | `restore()` | `UnlockContactingStore` | — |
| Boot with the flag set and `unlocked = 0`, ≤ 14 days | `attach()` only | not mounted | — |
| Boot with the flag set and `unlocked = 0`, > 14 days | none | not mounted | `abandonPurchase()` |

And the mapping from a store update. It happens in **three places, once each**, and the split is what
keeps the plugin behind one file:

- `PurchaseService._onBatch` completes the purchase and turns `PurchaseStatus` into `PurchaseSignal`. It is the only code that sees a `PurchaseDetails`.
- `EntitlementRepository`, listening to `PurchaseService.updates`, writes the row on two signals and ignores the other three.
- `UnlockController`, listening to the same fan-out, sets screen state on three signals and ignores the two that the entitlement stream will report anyway.

| `PurchaseStatus` (plugin) | `PurchaseSignal` (seam) | `completePurchase` | Entitlement row | `UnlockState` |
|---|---|---|---|---|
| `pending` | `awaitingPayment` | **never** | untouched | `UnlockAwaitingPayment` |
| `purchased` | `purchased` | yes, if `pendingCompletePurchase` | `markUnlocked(restored: false)` | untouched — the section re-renders from `entitlementProvider` |
| `restored` | `restored` | yes, if `pendingCompletePurchase` | `markUnlocked(restored: true)` | ditto |
| `error` | `failed` | yes, if `pendingCompletePurchase` | **untouched — never downgraded** | `UnlockUnavailable(storeError)`; `abandonPurchase()` |
| `canceled` | `cancelled` | yes, if `pendingCompletePurchase` | untouched | `UnlockOffered(price: …)`; `abandonPurchase()` |

`PurchaseStatus` has exactly those five members, so `_onBatch`'s `switch` expression is exhaustive
without a default arm — which is the point: a sixth member in a future plugin major becomes a compile
error rather than a silently-ignored purchase.

`purchased` and `restored` are handled **identically**. That is not tidiness: it is what makes the
`in_app_purchase_storekit` 0.4.3-era regression — StoreKit 2 purchases reported as `restored` —
incapable of costing an unlock, even if a future resolution slips below the 0.4.8 floor.

Apple's **Ask to Buy** hold surfaces through the same `pending` arm on StoreKit 1. Whether
StoreKit 2 under `in_app_purchase_storekit` ≥ 0.4.8 distinguishes it is **unverified** — no primary
source in the research covers it. Both are handled identically and safely: no unlock, no
`completePurchase`, flag left set, so a later approval drains through the same path.

### 6.4 Restore is mandatory, and it is labelled the way Apple looks for it

App Review guideline **3.1.1**: *"you should make sure you have a restore mechanism for any restorable
in-app purchases."* In practice reviewers look for a visibly labelled control on the same screen as
the buy button, and a missing one is a routine rejection.

Two consequences:

1. **Restore sits above Unlock**, always, in both rows and in the section. It removes the double-charge fear before it forms.
2. **The button label is "Restore purchases"**, and this is the **one permitted use of the word "purchase" in user-facing copy**. `CONVENTIONS.md` §5.1 says use *unlock*, never *purchase* — the exception exists because this string is a store-review artefact that a reviewer scans for visually, and losing a submission to house vocabulary is a bad trade. Every other sentence says "unlock": *"Restoring your unlock needs a connection to the store, once."*

### 6.5 When the store is unreachable — which, in a shed, is always

The single most common runtime state of the whole monetization surface. It is not an error.

- **No dialog.** `ui.show_dialog` allowlists exactly two files (delete-season and restore-from-backup) and this is not one of them.
- **No spinner.** `ui.spinner` bans `CircularProgressIndicator` under `lib/features/`; `UnlockContactingStore` is expressed as a disabled button with a changed label.
- **No snackbar, no haptic, no red.** `showFailure` is for `ShedFailure` and this is not one.
- **No retry loop, no timer, no back-off, no background attempt.** The retry is the user tapping the button again. A `Timer.periodic` here would be Flutter's `offline-first` design pattern (decision #7) arriving by the back door.
- **No blocked screen.** Every other pixel in Settings works. The app stays in the free tier and stays completely usable.
- **Bounded.** Ten seconds, then `UnlockUnavailable(storeUnreachable)`.
- A de-Googled device, a signed-out Play account and an App Store outage all land in the same state, and all are correct.

### 6.6 Double taps

Cold, wet fingers on capacitive glass double-fire, and a double-fired Unlock that opens two checkout
sheets is the worst possible instance of it. `UnlockController.unlock()` and `.restore()` both begin
`if (state is UnlockContactingStore) return;` — the same refusal `WriteController.guard()` makes, in
the same shape. They do not go through `WriteController` itself, because a purchase does not return a
`WriteOutcome` and its result arrives on a stream minutes later; that is a stated, narrow departure
from `CONVENTIONS.md` §4.4 rule 2, and the entitlement row write it eventually causes is still made by
a repository. `test/features/tap_budget_test.dart` gains one `tester.tap(); tester.tap();` case per
button.

### 6.7 The price is never a literal

`CONVENTIONS.md` §5.4: the price is `ProductDetails.price`, always. The policy gate already carries
`copy.currency_literal` — a currency symbol followed by a digit anywhere under `lib/` or `assets/`
fails the build.

That collides with decision #88, because knowing a price means calling the store, and the two upgrade
rows are always on screen. The resolution:

- The rows render **without a price** until the store has answered in this process. `07-screens.md` §19.2's `<store price>` is a placeholder, and when it is unresolved the sentence simply ends after "Unlock once".
- Once `queryUnlockPrice()` has returned a non-null `String`, both rows may render it for the remainder of the process. The string is `ProductDetails.price`, already localised and currency-formatted by the store; nothing in `lib/` reformats it.
- It is **never persisted**. Not in `app_settings`, not in the entitlement row, not in a file. `PurchaseService._product` is the only thing that holds it, and it dies with the process.

In a shed the price is unknown, and that is the expected rendering. `07-screens.md` §19.2 must note
the two forms; the rule that produces them is this document's.

---

## 7. The free-tier policy object

### 7.1 What is capped

The owner's ruling (§7.0 #8): **season-primary, ewe cap secondary.** The free tier covers one full
season; the ewe cap is a calm secondary gate. The season wall lands exactly where spec §7.7 says the
value is — opening last year's history in season two — so the app asks for money at the moment it has
proved itself.

| Capability | Free | Unlocked |
|---|---|---|
| Read, search, filter, edit any existing record | ✅ | ✅ |
| Lambing events, lambs, fostering, care events, treatments, pen board, reminders | ✅ unlimited | ✅ |
| **CSV / PDF / JSON export** | ✅ **always, in every state** (decision #86) | ✅ |
| Withdrawal periods, clear dates, the medicine book | ✅ **never capped, ever** | ✅ |
| Create a ewe during Quick Entry, Lambing Entry or Foster | ✅ **always** — the row is created and flagged | ✅ |
| Create a ewe from the Flock screen past the cap | ❌ calm refusal | ✅ |
| Start a second season | ❌ calm refusal | ✅ |

Two of those are not negotiable. **Export is never gated** — spec §7.9 calls it a safety feature, and
paywalling the only backup mechanism in an app with no cloud is a data-hostage pattern that
contradicts the product's own selling point. **Nothing safety-related is ever gated** — a withdrawal
period, a clear date and the medicine book are the spec §12.1 machinery, and gating them would make a
commercial decision into a food-safety one.

### 7.2 The type, complete

`lib/domain/free_tier.dart` — the file is 01's, the members are this document's (R69). Pure Dart: no
flutter, no drift, no riverpod, no `package:clock`.

```dart
/// The free tier's two limits. Constants, not constructor parameters: an
/// injectable cap lets a test lower it to 3 and hide an off-by-one that
/// production would then ship. The at-cap fixture
/// (test/fixtures/flock_15_at_cap.json) is how tests reach the boundary.
const int kFreeEweCap = 15;
const int kFreeSeasonCount = 1;

enum EntryContext {
  /// Quick Entry's keypad, Lambing Entry's create-on-the-fly, Foster's
  /// reassignment. Spec §7.1: never block an entry.
  liveEntry,

  /// Flock "+", Settings ▸ Season. The user is standing still, in daylight,
  /// with two hands free. A refusal here is legitimate.
  calm,
}

sealed class CapDecision { const CapDecision(); }

final class Allow extends CapDecision {
  const Allow({required this.overFreeCap});
  /// True when a write proceeds that the free tier would otherwise refuse.
  /// The row is real; the flag rides on it and clears on unlock.
  final bool overFreeCap;
}

final class BlockedByCap extends CapDecision {
  const BlockedByCap(this.reason);
  final RefusalReason reason;
}

enum RefusalReason { secondSeason, eweCap }

/// 22:00–06:00 local wall time. One predicate, so the policy and the upgrade
/// row cannot disagree about when the app goes quiet.
///
/// UK/Ireland's ambiguous DST hour is 01:00–01:59 (§7.0 ruling 3), which sits
/// inside this window under BOTH readings — so the one place in the app where
/// a local hour is genuinely ambiguous is a place where the ambiguity cannot
/// change the answer.
bool isQuietHours(Instant now) {
  final h = now.local.hour;
  return h >= 22 || h < 6;
}

final class FreeTierPolicy {
  const FreeTierPolicy();

  /// `ewesInCurrentSeason` and `seasonCount` are the counts **as they would be
  /// after the write**. That is the contract, and getting it wrong is an
  /// off-by-one that either refuses ewe #15 or lets #16 through.
  CapDecision decide({
    required EntryContext context,
    required Instant now,
    required bool unlocked,
    required int ewesInCurrentSeason,
    required int seasonCount,
  }) {
    final overSeason = seasonCount > kFreeSeasonCount;
    final overEwes = ewesInCurrentSeason > kFreeEweCap;
    final over = !unlocked && (overSeason || overEwes);

    if (unlocked) return const Allow(overFreeCap: false);

    // Spec §7.1. This arm is why the whole object exists.
    if (context == EntryContext.liveEntry) return Allow(overFreeCap: over);

    // Owner's ruling: nothing surfaces between 22:00 and 06:00.
    if (isQuietHours(now)) return Allow(overFreeCap: over);

    // Season-primary. If both are over, the season is the reason.
    if (overSeason) return const BlockedByCap(RefusalReason.secondSeason);
    if (overEwes) return const BlockedByCap(RefusalReason.eweCap);
    return const Allow(overFreeCap: false);
  }
}
```

Read the two `return`s before the gates: **`EntryContext.liveEntry` is structurally incapable of
returning `BlockedByCap`.** Not by convention, not by a code review rule — the function cannot reach a
`BlockedByCap` on that path. That is what makes "the cap never fires at 03:20" a property rather than
a promise, and `test/policy/cap_never_blocks_live_entry_test.dart` asserts it across the whole input
grid.

`freeTierPolicyProvider = Provider<FreeTierPolicy>((ref) => const FreeTierPolicy());` — keepAlive.

### 7.3 Where the check lives: two repository verbs, and only two

Not in widgets. In the repository, with the calling context as an explicit parameter, so the rule
cannot be got wrong by accident and is unit-testable without a widget test (decision #91, critique
c3 D7).

```dart
// lib/data/flock_repository.dart
Future<WriteOutcome> createEwe({required String tag, required EntryContext context}) =>
    _db.transaction(() async {
      final unlocked = (await _entitlements.read()).unlocked;
      final decision = _policy.decide(
        context: context,
        now: appNow(),
        unlocked: unlocked,
        ewesInCurrentSeason: await _countEwesInCurrentSeason() + 1,   // post-write
        seasonCount: await _countSeasons(),                          // unchanged
      );
      return switch (decision) {
        BlockedByCap(:final reason) => WriteRefused(reason),
        Allow(:final overFreeCap) => WriteCommitted(
            insertedId: await _insertEwe(tag: tag, overFreeCap: overFreeCap),
          ),
      };
    });

// lib/data/season_repository.dart  — the second gated write (§2).
Future<WriteOutcome> startSeason({
  required String label,
  required LocalDate startDate,
  required EntryContext context,
});
```

Rules that fall out and are worth stating once:

- The decision and the insert are in **one transaction**, so the count cannot move between them.
- The policy reads `appNow()` in `lib/data/`, never in `lib/domain/` — `package:clock` is banned in the domain (R24) and `FreeTierPolicy` takes `now` as a parameter for exactly that reason.
- The cap is **not** a schema `CHECK`. A `CHECK` would fire on a paying user mid-lambing and there would be no way to tell it apart from corruption.
- The cap is **not** a UI check. A UI check is one refactor away from being bypassed and cannot be tested without pumping a widget.
- `createEwe` is the only create verb the cap can refuse, and `startSeason` the only other gated write. `beginLambing` and `addLamb` throw and return ids; they are never gated, at any entitlement state.
- `WriteRefused(reason)` reaches the screen through `WriteDone`, and the screen calls `showCapRow(context, reason)` — calm, static, no haptic, never a modal (R30).

`RefusalReason` maps to exactly two ARB messages, with the cap as a placeholder so the number is never
typed twice:

| Reason | Message |
|---|---|
| `secondSeason` | "The free version covers one season. Unlock to start another." |
| `eweCap` | "The free version covers {count} ewes in a season. Unlock to add more." |

### 7.4 Two consequences of the rules above, stated rather than discovered

Both fall straight out of §7.2's `return`s. Neither is a bug, both are permanent, and a reader who
meets them for the first time in production will read them as one.

**A calm gate that lands inside the quiet window is not deferred — it is forgiven, permanently.**
`isQuietHours` returns `Allow`, `startSeason` commits with `over_free_cap = 1`, and rule 1 (§4.2) means
the app never revokes and never re-refuses. So a user who taps "start a new season" at 22:30 gets their
second season for nothing, and keeps it. That is the accepted cost of the owner's ruling that nothing
surfaces between 22:00 and 06:00, and it is the correct trade: the alternative is an app that asks a
shepherd for money at 03:20, which spec §5 makes a shipping gate. **Do not "fix" it** by deferring the
refusal to the morning — a refusal that arrives detached from the tap that caused it is worse than no
refusal, and it would fire while the user is somewhere else in the app.

**A restored multi-season backup closes both calm gates at once.** `_countSeasons()` on a restored
three-season file is `3 > kFreeSeasonCount`, so in the free tier `createEwe(context: calm)` returns
`BlockedByCap(secondSeason)` — the season is the reason, per season-primary — and so does
`startSeason`. Everything else still works: every restored ewe is readable, editable, searchable and
exportable (§4.5), every live-entry write commits, and no row is touched. That is the honest shape of
"the cap is never applied retroactively": it constrains the *next* write, never the existing records.

---

## 8. The upgrade affordance: four hard constraints

A permanent static row converts worse than a well-timed modal. That is the deliberate trade. Spec §5's
*"zero interruptions"* is written as a shipping gate — *"If a feature cannot be operated under these
conditions, it does not ship"* — and this audience is described as vocally hostile to farm-software
subscriptions and will punish an app that nags. The conversion mechanism is the season wall, not the
prompt.

**1. Never mid-entry.** `EntryContext.liveEntry` cannot return `BlockedByCap`. Creating ewe #16 at
03:20 succeeds, silently, and the row carries `over_free_cap = 1`. Nothing is said, nothing is shown,
no receipt mentions it. The five shed screens — Quick Entry, Lambing Entry, Lamb Card, Foster, Pen
Board — render nothing monetization-related at any entitlement state, and neither do Ewe Card,
Treatments, Reminders, Season Summary, Export or note search: the affordance exists in exactly two
places.

**2. Never between 22:00 and 06:00.** `isQuietHours(now)` is one predicate and both halves read it:
calm-UI cap decisions degrade to `Allow(overFreeCap: …)`, and **neither** `ShedBanner` renders — the
Settings row goes quiet as well as the Flock one, which is `06-design-system.md` §12 constraint 3
("on any screen, at any ewe count") and is wider than `07-screens.md` §19.3, whose rule 2 names only
the Flock row. 06 owns the component and its rule is the one that ships; 07 §19.3 adopts the wider
wording. The widget test that proves it **sets the clock, not the entitlement**.

The one distinction that must be written down, because it is easy to over-apply: what the quiet window
suppresses is **soliciting**, not **selling**. Settings ▸ Unlock is a settings section like any other;
it exists at 23:00, its Restore and Unlock buttons work at 23:00, and a shepherd who deliberately
walks to it at midnight to pay is not interrupted by being allowed to. What does not happen at 23:00
is a row appearing, a refusal firing, or the app navigating anywhere on its own.

**3. Never a modal.** No modal, no interstitial, no full-screen takeover, no bottom sheet that appears
by itself, on launch or on the Nth save or on the 16th ewe or at end of season. `ui.show_dialog`
already fails the build on `showDialog(` outside the two allowlisted destructive files, so a modal
paywall is caught by an existing rule rather than a new one. `showCapRow` is a `ShedBanner` row through
`ScaffoldMessenger.showMaterialBanner` — the one non-modal persistent surface the framework offers.

**4. Never more than once a day.** When a calm-UI action returns `WriteRefused`, the *user initiated
that tap*, so navigating to Settings ▸ Unlock is a response rather than an interruption — and it is the
only navigation to Unlock the app ever performs on its own. But a user who taps "+" ten times must not
be sent there ten times. So:

- The self-navigation fires **at most once per local civil day**, recorded in `app_settings.last_unlock_prompted_at` (§2 — a nullable `INTEGER` instant, written by `SettingsRepository`, **must land before the first schema snapshot**).
- The comparison is `LocalDate.of(appNow()) != LocalDate.of(lastPrompted)`. Same day → no navigation; `showCapRow` renders the refusal in place and nothing moves.
- It cannot fire in the quiet window, because nothing is refused in the quiet window.
- A **user-initiated** tap on an upgrade row is not a prompt and is never rate-limited. The row is always tappable.

### 8.1 What happens to the data when a user exceeds the cap and later pays

Nothing destructive. Ever. This is the section to read before writing any code that touches
`over_free_cap`.

- Rows created over the cap are **real rows**, in the same tables, indistinguishable from any other except for `ewes.over_free_cap` / `seasons.over_free_cap`. No shadow storage, no staging table, no separate sandbox, no soft delete.
- **On unlock**: `unlocked = 1`, `unlocked_at` written, both flag columns cleared, in one transaction (§4.3). Nothing migrates, nothing reconciles, nothing can be lost in between.
- **On not paying**: nothing is deleted, hidden, greyed out, blurred, teased or made read-only. Ever. A shepherd who tried it for one season and walked away opens the app in year two and exports their CSV. Anything else is data ransom, in a product whose selling point is that no company can take their five seasons away in 2029.
- The flag **is not a warning**. It has no `WarningCode`, it never renders as a badge, it never gets a colour, and it never enters the §12.4 contradiction machinery. It is monetization bookkeeping.
- **Nothing reads `over_free_cap` when `unlocked = 1`.** The two rows only render in the free tier, and the honest count on the Flock row is theirs alone. That is what makes a restored backup carrying stale `over_free_cap` markers harmless: the app does **not** rewrite the user's rows to tidy up its own bookkeeping, and never needs to.
- `over_free_cap` is not a husbandry fact. `09-export-formats.md` §5 has ruled: it is **absent from every CSV shape and every PDF**, and **present in the JSON backup**, because the backup is the record and the CSV is a report. That is the right answer, and the rule above is what makes it safe — a backup restored onto an unlocked phone carries stale `over_free_cap = 1` markers that nothing will ever read.

### 8.2 What the cap never does

It never blocks a save. It never blocks a treatment, a withdrawal period, a clear date or the medicine
book. It never blocks an export. It never reaches backwards and locks last year's ewe card. It never
applies retroactively to a restored flock. It never caps reminders — whether it ever does is §7.1 open
question 17, still open, and it changes the reconcile budget rather than any screen.

---

## 9. Store compliance for an app that collects nothing

This is a real, mechanical rejection cause. Precision here is cheaper than a rejected submission at the
start of lambing.

### 9.1 Apple — a genuine "Data Not Collected"

Apple defines the operative verb narrowly: *"**Collect** refers to transmitting data off the device in
a way that allows you and/or your third-party partners to access it for a period longer than what is
necessary to service the transmitted request in real time."* Shed Book transmits nothing. Records,
photos, voice notes and the SQLite file leave the phone only through the system share sheet, where the
user chooses the destination — that is the user transmitting, not the app. Every one of Apple's
fourteen categories is answered **No**, and the label renders as **Data Not Collected**.

Two judgement calls, recorded so they are re-checked rather than remembered:

- **In-app purchase data.** Apple processes and retains it; we receive a `purchaseID` and nothing that identifies a person, and we do not even store that (§4.1). Not "collected" under the definition above. **If a backend is ever added, this answer changes and the label must be updated before that build ships.**
- **Crash reports and analytics.** There are none, by design (decision #123). If Sentry, Crashlytics or any error reporting to a server ever lands, the label is no longer "Data Not Collected" and `NSPrivacyTrackingDomains` becomes relevant.

A **hosted privacy-policy URL is mandatory** (guideline 5.1.1(i): the link in App Store Connect
metadata *and* "within the app in an easily accessible manner"). The in-app half is satisfied by
shipping the full policy text as static Dart strings on Settings ▸ About — readable in the shed with no
signal, and it avoids `url_launcher`, which is itself on Apple's privacy-manifest SDK list. The hosted
URL is the one piece of internet infrastructure this project cannot avoid, and it lives outside the
app.

### 9.2 `PrivacyInfo.xcprivacy` — the required-reason codes this app actually needs

`ITMS-91053: Missing API declaration` is the rejection. The codes below were cross-checked against two
independent renderings of Apple's table during the research, because the first fetch returned a
garbled mapping. **Do not trust a single summary of this table, including this one — re-read Apple's
page before the first submission.**

| Category | Code | In **our** manifest? | Why |
|---|---|---|---|
| `NSPrivacyAccessedAPICategoryFileTimestamp` | **`C617.1`** | **Yes** | Timestamps/size/metadata of files **inside the app container**. drift writes `shed_book.sqlite` plus its WAL, `MediaStore` writes and resolves media, `MediaSweeper` stats files to find orphans, and the export path writes temp files |
| `NSPrivacyAccessedAPICategoryDiskSpace` | **`E174.1`** | **Yes** | "Check whether there is sufficient disk space to write files, or detect low disk space." `DiskFull` is one of the six `ShedFailure` variants — the app genuinely queries this before writing a photo or a PDF |
| `NSPrivacyAccessedAPICategoryUserDefaults` | `CA92.1` | **No, in v1** | `shared_preferences` is not a dependency and entitlement rule 3 forbids it. No app-level Dart code touches `NSUserDefaults`; plugins that do declare it in their own manifests. Re-check in the generated privacy report after any plugin bump |
| `NSPrivacyAccessedAPICategorySystemBootTime` | `35F9.1` | **No** | The Flutter engine's own manifest already declares FileTimestamp `[0A2A.1, C617.1]` and SystemBootTime `[35F9.1]`. `Stopwatch` and the engine's file access are covered. Declare `35F9.1` yourself only if you write native code reading `systemUptime`/`mach_absolute_time` — this app writes none |

**Never put `0A2A.1` or `C56D.1` in an app's manifest.** Both are reserved for third-party SDK
wrappers, and using them in an app manifest is the shape of
`ITMS-91055: Invalid API reason declaration`.

> **This supersedes the decision record's own wording, and one line in a sibling.** Decision #93 says
> `C617.1` + `CA92.1`, with `E174.1` "only if free disk space is actually queried", and
> `08-platform-integration.md` §11 restates it while marking the row "owned by 11". It is owned by 11,
> and the ruling is: **`E174.1` ships** (free space is queried, `DiskFull` is a `ShedFailure`) and
> **`CA92.1` does not** (no `shared_preferences`, no app-level `NSUserDefaults`). #93's wording predates
> entitlement rule 3, which is what removed the `shared_preferences` dependency that would have made
> `CA92.1` true. **Both `00-tech-decisions.md` §2 row 93 and 08 §11 are edited to match, in the same
> commit as this ruling** — a decision record that disagrees with the doc that owns the answer is worse
> than either being wrong. Over-declaring inside your own valid codes is not a rejection cause;
> under-declaring is — so if a plugin bump ever introduces app-level `NSUserDefaults` use, add
> `CA92.1` and do not agonise.

> **Unresolved, and it must be closed before the first submission.** `85F4.1` is "display disk-space
> info to the user", and Settings ▸ Diagnostics does display storage figures to the user (decision
> #123). Note 07's reason-code table treats `85F4.1` as a valid app-level code; its own pitfall table
> lists it as a rejection cause. The two halves of the research disagree, and no critic resolved it.
> **Re-read Apple's `NSPrivacyAccessedAPITypeReasons` page and decide there, not here.** `E174.1` is
> unambiguously correct and ships either way.

```xml
<!-- ios/Runner/PrivacyInfo.xcprivacy -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>
  <false/>

  <key>NSPrivacyTrackingDomains</key>
  <array/>

  <!-- Genuinely empty. Shed Book transmits nothing off the device. -->
  <key>NSPrivacyCollectedDataTypes</key>
  <array/>

  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <!-- shed_book.sqlite + WAL, the media folder, export temp files:
         all inside the app container. -->
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>C617.1</string></array>
    </dict>

    <!-- Free-space check before writing a photo or a PDF export.
         DiskFull is a ShedFailure variant. -->
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>E174.1</string></array>
    </dict>
  </array>
</dict>
</plist>
```

**The file must be in the Runner target's Copy Bundle Resources, at the root of the app bundle.** A
`PrivacyInfo.xcprivacy` that sits in the project but not in the target ships nothing, and the build
succeeds.

### 9.3 Plugin manifests aggregate; they do not substitute

Apple maintains a list of "commonly used SDKs" that must include a privacy manifest and a signature.
It stood at **89 entries** when the research was fetched (it grows; re-read it, do not quote this
number at a reviewer) and it is full of this app's stack: **Flutter** itself,
**path_provider**, **share_plus**, **device_info_plus**, **image_picker_ios**,
**flutter_local_notifications** — plus `url_launcher`, `file_picker`, `connectivity_plus` and
`shared_preferences_ios`, none of which this project uses, which is itself worth noticing.

1. **The engine ships its own manifest** and it covers the engine's file access and clock use.
2. **You still need your own.** SDK manifests cover SDK code; yours covers yours. They **aggregate**.
3. **Verify the aggregate, do not assume it.** Product → Archive, right-click the archive in the Organizer, **Generate Privacy Report**. Read the PDF. Do it once before the first submission and again after **every** plugin bump.
4. **Flutter 3.44 made Swift Package Manager the default for iOS/macOS.** Plugin resource bundles — which is how a plugin's `PrivacyInfo.xcprivacy` gets into the app — are packaged differently by SwiftPM than by CocoaPods. **Re-generate the privacy report after the SwiftPM migration**; do not carry a CocoaPods-era assumption forward. The failure mode is `ITMS-91061: Missing privacy manifest`.
5. **Any plugin not on Apple's list that ships no manifest is ours to declare.** Check `file_selector`, `record`, `flutter_image_compress`, `wakelock_plus`, `in_app_purchase_storekit` and `sqlite3` in the generated report — **unverified** whether each ships one. If one does not, and it touches a required-reason API we have not declared, the declaration is ours. We already declare `C617.1`, which covers the common case.

### 9.4 Google Play

**Data safety form: "No data collected or shared."** Google's own exemptions cover everything that
might look like collection — data processed **ephemerally**, data processed **on-device only**, and,
directly on point:

> "If your app uses a payment service such as PayPal, Google Pay, **Google Play's billing system**, or
> similar services to complete payment transactions, **you don't need to declare collection of the data
> that the payment service collects** in connection with its processing of financial transactions, if
> the payment service collects this information directly from the user, and collection is governed by
> that service's terms."

That exemption is why a plain `in_app_purchase` integration keeps a clean form — and why RevenueCat
would flip it: with a third party in the path you must declare "Purchase history" collected, because
your app transmits purchase data to them. That is a second, independent reason `purchases_flutter` is
rejected (decision #87).

**The privacy policy is required even with zero collection.** Every app must complete the form and
provide a policy link.

**Target API level.** By 31 August 2026 new apps and updates must target **Android 16 (API 36)** or
higher. Set `targetSdk = 36` from the first commit; a greenfield project has no reason to be behind.

**AAB + Play App Signing** are mandatory for new apps. You keep an upload key; Google holds the app
signing key. Back the upload keystore up somewhere that is not the laptop.

### 9.5 What is NOT needed, because there is no account

| Requirement | Applies? | Why not |
|---|---|---|
| **Sign in with Apple** (guideline 4.8) | **No** | Triggered only by third-party or social login. Shed Book has no login of any kind |
| **Account deletion — Apple 5.1.1(v)** | **No** | *"If your app supports account creation, you must also offer account deletion within the app."* There is no account creation |
| **Account deletion — Play** | **No** | Same condition: *"If your app enables account creation…"*. The Play Console answer is "users can't create accounts" and **no deletion URL is needed** |
| Guideline 2.2 (demos, betas, trials) | **No** | 2.2 targets incomplete builds. A capped-but-complete free tier is the model 3.1.1 and 4.3(a) actively recommend |
| "No analytics" causes friction | **No** | There is no store rule requiring telemetry. The cost is ours: we will not know why a shepherd stopped |

Do not add a Sign in with Apple button, an account-deletion screen or a deletion URL "for parity".
Each one would create the account model the app does not have, and each is a new privacy declaration.

**But do describe destruction in the privacy policy**, because the user asks the same question the
rules do: data is destroyed by **Settings ▸ Delete everything** (spec §7.10) and by uninstalling.
Nothing is held anywhere else, because there is nowhere else.

**Guideline 4.2 Minimum Functionality is the one to watch.** The *free* experience is what the reviewer
sees, and it must be a working notebook rather than a teaser. The design clears this comfortably —
everything works, one full season, 15 ewes, export included. A hard three-ewe demo would not.

**App Review notes, verbatim, on every submission:**

> This app has no server, no account and no sync. Android release builds declare no INTERNET
> permission. To test the unlock, use the sandbox account below; a "Restore purchases" button sits
> directly above the Unlock button on the same screen (Settings ▸ Unlock). The free tier covers one
> season and 15 ewes; every other feature, including export, is available without purchase.

Reviewers test on a networked device and may not read the notes, so nothing in the app may *depend* on
them being read.

---

## 10. Pricing, territories and fees

**This section is bounded by §7.1 open question 4, which is still open — and it is now a *booking*, not a decision.** It is ledger row `price_and_territories` in [`docs/calendar.md`](../calendar.md), which carries the €10–15 band, the SBP arithmetic, the 30 June 2026 fee restructure and the instruction that the one-time-product rate is **read inside Play Console and recorded with the date it was read**, because Google's own post does not state one and the quoted 20% + 5% is secondary reporting. The answer lands in that row and this section follows it. Do not treat any number here
as settled.

- **The range is €10–15.** €11.99 or €12.99 are the shapes under discussion. The exact figure and the territory list are the owner's.
- **Enrol in the Apple Small Business Program before the first sale.** 15% instead of 30% for developers under $1M USD annual proceeds; new developers qualify; enrolment takes effect 15 days after the end of the fiscal month of approval. At €12 gross that is roughly €10.20 net instead of €8.40. Enrolling after the first sale means paying 30% on everything sold in the gap, for nothing.
- **Google restructured its fees on 30 June 2026** (US, UK and EEA first, staggered elsewhere through 2027). The fee splits into a **service fee** and a **billing fee**; the billing fee is 5% when you use Google Play's billing system in those markets, and the service fee starts at 10% on the first $1M of annual earnings with tiered rates for other transaction types. The figure most often quoted for a one-time purchase from a new install — **20% service + 5% billing** — comes from secondary reporting only and is **unverified**; Google's own post does not state a one-time-product rate. ⚠️ **Confirm the exact one-time-product rate for IE/UK/EEA inside Play Console before committing to a price.** This changed two months before the research was done and the secondary sources disagree in detail; a number copied from a blog into a spreadsheet is how a price gets set 5% wrong for three years.
- Both stores support per-territory prices. Price in EUR for IE and UK-adjacent markets (§7.0 ruling 3 puts UK/Ireland first) and let the stores convert the rest.
- The price never appears as a literal anywhere in the repository (§6.7).

---

## 11. Testing purchases

`12-testing.md` owns the test suite and `13-build-ci-release.md` owns the pipeline. What belongs here
is the part that is specific to money.

| Platform | Loop |
|---|---|
| iOS, fastest | A local **`.storekit` configuration file**. Works **fully offline**, needs no Apple account, and is the only loop that can be run in a shed |
| iOS, real | **Sandbox** with a sandbox Apple Account (network required), then **TestFlight** (network required) |
| Android | **Play Console → Settings → License testing.** License testers get test payment instruments (always approves, always declines, slow test card) and can sideload debug-signed builds. The package name must match a Play Console app, and the tester must also be opted into a test track or they are charged for real |

**The three paths nobody tests, and this app takes all three:**

1. Airplane mode, open Settings ▸ Unlock, tap **Unlock**. Expect `UnlockUnavailable(storeUnreachable)` within ten seconds, no dialog, no spinner, and the rest of Settings still working.
2. Airplane mode, tap **Restore purchases**. Same, with the honest one-liner from §4.5.
3. Buy on device A. Install on device B with no signal. Confirm the app is fully usable in the free tier and the restored flock is complete. Restore the purchase once signal returns.

Add one more that costs nothing and catches the worst bug: **buy, then kill the app before the purchase
stream delivers.** Relaunch offline (the flag is set, `attach()` runs, nothing arrives, the app stays
free and usable), then relaunch with signal (the stream delivers, `completePurchase` runs inside the
three-day window, and the row is written after it — that order, per §5.2).

Fixtures: `test/fixtures/flock_15_at_cap.json` is the at-cap flock; `flock_400_3seasons.json` is the
over-cap, multi-season case. Both are produced by `tool/seed.dart` through the restore path.

---

## 12. The gates

### 12.1 Policy rule rows this document adds

Four rows in `tool/check_policy.dart`'s rule table (`CONVENTIONS.md` §4.7's dotted `namespace.name`).
No second script. Two of them carry a second clause, and the second clause is the one that does the
work — an import ban is bypassed by a leaked type, and a component ban is bypassed by the component
having a second, legitimate use.

| Rule id | Fails on | Scope |
|---|---|---|
| `layer.in_app_purchase` | `package:in_app_purchase` imported anywhere but `lib/data/purchase_service.dart`, **or** any of `PurchaseDetails`, `ProductDetails`, `PurchaseStatus`, `PurchaseParam`, `InAppPurchase` appearing outside that file. The second half is what makes the first half hold: the import ban is trivially satisfied by a leaked type in a public signature that someone else then has to import to name (§5) | `lib/` |
| `launch.store_call` | `PurchaseService` or `purchase_service.dart` referenced in `lib/main.dart` or `lib/app.dart` | those two files |
| `ui.monetization_surface` | `showCapRow(` called outside `lib/features/flock/` and `lib/features/settings/`; **and** `ShedBanner` constructed outside those two plus `lib/features/quick_entry/` | `lib/features/` |
| `db.entitlement_revoke` | `markLocked`, `revokeEntitlement`, or `unlocked:` assigned `false`/`Constant(false)` outside `lib/core/db/tables/` | `lib/` |

`ui.monetization_surface` allows `ShedBanner` in `quick_entry/` on purpose: the same component carries
the end-of-day **export prompt** (`07-screens.md` §16.2), which is not a monetization surface and
predates this document. Scoping the component ban to two folders would have failed the build on a
banner the spec calls a safety feature. `showCapRow(` is the half that actually guards monetization,
and it is exact — the cap can only be refused from those two folders, because `liveEntry` is
structurally incapable of returning `BlockedByCap` (§7.2).

Rules that already exist and do this document's work, so no duplicate is added: `ui.show_dialog` (no
modal paywall), `ui.spinner` (no spinner in the contacting state), `copy.currency_literal` (no price
literal), `net.*` (the offline source scan), and `_checkLockfile`'s `dep.direct_main` /
`dep.transitive` (`01-architecture.md` §3.2 — one of the four allowlist entries is direct main and
three are transitive, and they are checked by different rule ids because they sit in different
sections). A duplicate rule is a rule that gets weakened twice (R54), which is why
`launch.store_call` no longer names `InAppPurchase`: `layer.in_app_purchase` already covers that
token everywhere under `lib/`, and `launch.store_call` exists for the two names it does not cover.

### 12.2 Tests

| File | Asserts |
|---|---|
| `test/policy/cap_never_blocks_live_entry_test.dart` | `decide(context: liveEntry, …)` never returns `BlockedByCap`, across the whole grid of `unlocked` × ewe counts 0…30 × season counts 1…5 × all 24 local hours |
| `test/policy/quiet_window_never_solicits_test.dart` | At every local hour in 22:00–05:59, `decide` returns `Allow` for both calm gates, and no `ShedBanner` renders on Flock or Settings. **The test sets the clock, not the entitlement** |
| `test/policy/entitlement_is_never_revoked_test.dart` | No code path in `lib/` writes `unlocked = false` after `onCreate`; `markUnlocked` is idempotent; an `error` or `canceled` update leaves an existing `unlocked = 1` untouched |
| `test/domain/free_tier_test.dart` | The boundaries: ewe #15 allowed, ewe #16 refused in `calm`, season #1 allowed, season #2 refused; both over → `secondSeason`; `unlocked` short-circuits everything |
| `test/data/entitlement_repository_test.dart` | `markUnlocked` clears both `over_free_cap` columns in the same transaction; a mid-transaction failure leaves `unlocked = 0` and both markers intact; feeding `FakePurchaseService` a `PurchaseSignal.awaitingPayment`, `.cancelled` or `.failed` writes nothing |
| `test/data/purchase_service_test.dart` | `_onBatch` completes every non-`pending` update whose `pendingCompletePurchase` is true, including an unrecognised product id; it never completes a `pending` one; it emits a signal only for `kUnlockProductId`; and it completes **before** it emits (§5.2) |
| `test/features/no_monetization_test.dart` | The five shed screens at `unlocked: false, ewesInCurrentSeason: 99` contain no `ShedBanner`; the Flock row is absent at 23:30 |
| `test/features/tap_budget_test.dart` | `tester.tap(); tester.tap();` on Unlock and on Restore starts exactly one store call |

The over-cap and at-cap widget states are part of the **252-cell overflow matrix** (R58), because
`Free version · covers this season · 22 of 15 ewes · Unlock once for €12.99` at textScaler 2.0 with
bold text is exactly the kind of row that overflows.

Backup and restore assertions live in `04-migrations-media-backup-restore.md` and already exist there:
an entitlement row in a backup file does not unlock the app; the export writer skips the table; the
importer skips and logs it.

---

## Definition of done

Tick every line before calling monetization finished.

**The model and the manifest**
- [ ] `pubspec.yaml` declares `in_app_purchase: 3.3.0` and nothing else store-related; `purchases_flutter`, `flutter_inapp_purchase` and `shared_preferences` are absent.
- [ ] `pubspec.lock` resolves `in_app_purchase_storekit` at **≥ 0.4.8**. If not, it is a direct dependency at `^0.4.8` with the reason in the commit message.
- [ ] The four `in_app_purchase*` lines are in `tool/policy_allowlist.txt`, one in `[dependencies]` and three in `[transitive]`, each with a reason.
- [ ] **G0 has been run**: `manifest-merger-release-report.txt` has been read on a real release AAB, and the permission set Play Billing 8.0.0 contributes is recorded in `00-tech-decisions.md` §3.3. No `tools:node="remove"` line was committed before that.
- [ ] `bundletool dump manifest` on the shipped `.aab` lists exactly the eight-entry set, including `com.android.vending.BILLING` and **excluding** `android.permission.INTERNET`.
- [ ] One binary, one bundle id per platform, no flavors, no second SKU.

**The entitlement**
- [ ] `entitlements` is the four columns in `03-data-model-and-schema.md` §5.13, seeded in `onCreate`, and no code path handles a missing row.
- [ ] `unlocked` is written in exactly one method, `EntitlementRepository.markUnlocked`, and is never written `false` after `onCreate`. `db.entitlement_revoke` is green.
- [ ] `markUnlocked` clears `ewes.over_free_cap` and `seasons.over_free_cap` in the same transaction, and its doc comment states the §2.13 ownership exception and why.
- [ ] The entitlement is absent from the JSON backup and ignored on import; the refusal fixture passes.
- [ ] `unlocked_at` and `purchase_in_flight_at` are rendered nowhere.
- [ ] `main()` and `app.dart` reference nothing store-related; `launch.store_call` is green.
- [ ] No shed screen watches `entitlementProvider`; `no_monetization_test.dart` is green.

**The flows**
- [ ] `package:in_app_purchase` is imported in exactly one file; `layer.in_app_purchase` is green.
- [ ] **No plugin type crosses the seam.** `PurchaseDetails`, `ProductDetails`, `PurchaseStatus`, `PurchaseParam` and `InAppPurchase` appear in exactly one file. `PurchaseService.updates` is a `Stream<PurchaseSignal>`; the price crosses as a `String`.
- [ ] `EntitlementRepository` and `UnlockController` both listen to that one fan-out, and neither imports the plugin.
- [ ] The billing client is initialised only on Settings ▸ Unlock, or on boot when `purchase_in_flight_at` is set **and** `unlocked = 0` **and** the flag is under 14 days old.
- [ ] `completePurchase` runs for every non-`pending` update with `pendingCompletePurchase == true`, on both platforms, regardless of product id; a `pending` purchase is never completed; completion happens **before** the signal is emitted.
- [ ] `purchased` and `restored` are handled by the same code.
- [ ] The Restore control is labelled **"Restore purchases"** and sits above Unlock in both rows and in the section. Every other sentence says "unlock".
- [ ] Every store call is bounded at ten seconds. There is no retry loop, no timer and no background attempt.
- [ ] A store failure is not a `ShedFailure`, produces no dialog, no spinner, no haptic and no snackbar, and does not appear in the diagnostics log as an error.
- [ ] A double tap on Unlock or Restore starts exactly one store call.
- [ ] No currency literal exists anywhere under `lib/` or `assets/`; the rows render without a price until the store answers, and the price is never persisted.
- [ ] The unlock / restore task completes end to end under VoiceOver, Voice Control and Larger Text at 200%, including the `UnlockUnavailable` state — it is one of the seven common tasks in `10-accessibility-and-i18n.md`.

**The free tier**
- [ ] `lib/domain/free_tier.dart` holds `kFreeEweCap`, `kFreeSeasonCount`, `EntryContext`, `CapDecision`, `Allow`, `BlockedByCap`, `RefusalReason`, `isQuietHours` and `FreeTierPolicy` — and imports no flutter, no drift, no riverpod and no `package:clock`.
- [ ] `EntryContext.liveEntry` cannot return `BlockedByCap`; the grid test proves it.
- [ ] `decide` is called only from `FlockRepository.createEwe` and `SeasonRepository.startSeason`, inside the same transaction as the insert, with **post-write** counts.
- [ ] `isQuietHours` is the only definition of 22:00–06:00 in the codebase, and both the policy and the two rows read it.
- [ ] The cap is not a schema `CHECK`, not a UI check and not a repository guard that ignores its caller.
- [ ] Export, treatments, withdrawal periods, clear dates and the medicine book are ungated in every state.
- [ ] Self-navigation to Unlock fires at most once per local civil day, via `app_settings.last_unlock_prompted_at`, and never in the quiet window. A user-initiated tap is never rate-limited.
- [ ] On unlock, nothing migrates and nothing is lost. On not paying, nothing is deleted, hidden, greyed, blurred or made read-only.
- [ ] Nothing reads `over_free_cap` when `unlocked = 1`.
- [ ] `app_settings.last_unlock_prompted_at` has landed in `03-data-model-and-schema.md` §5.13 **before the first schema snapshot**. Nothing else in this document depends on a column that does not exist yet.
- [ ] §7.4's two consequences are in the reviewer's head, not just the file: a calm gate forgiven inside the quiet window is never clawed back, and a restored multi-season backup closes both calm gates with `secondSeason`.

**The stores**
- [ ] App Store Connect App Privacy answers "No" to all fourteen categories and renders **Data Not Collected**.
- [ ] `ios/Runner/PrivacyInfo.xcprivacy` ships `C617.1` and `E174.1`, declares `NSPrivacyTracking = false`, empty `NSPrivacyTrackingDomains` and empty `NSPrivacyCollectedDataTypes` — and is in the Runner target's **Copy Bundle Resources**.
- [ ] `0A2A.1` and `C56D.1` appear nowhere in the app's manifest.
- [ ] The `85F4.1` question (§9.2) has been closed against Apple's own page, and the answer is recorded.
- [ ] Product → Archive → **Generate Privacy Report** has been run and read, after the SwiftPM migration and after the most recent plugin bump.
- [ ] Play Data safety declares no collection and no sharing; the privacy-policy URL is set on both stores; the account-deletion answer is "users can't create accounts".
- [ ] `targetSdk = 36`; the build ships as an AAB with Play App Signing; the upload keystore is backed up off the laptop.
- [ ] There is no Sign in with Apple button, no account-deletion screen and no deletion URL.
- [ ] The privacy policy text ships as static Dart strings on Settings ▸ About, with no `url_launcher`.
- [ ] The App Review notes in §9.5 are attached to the submission.
- [ ] `00-tech-decisions.md` §2 row 93 and `08-platform-integration.md` §11 both read `C617.1` + `E174.1`, with no `CA92.1`, in the same commit as §9.2's ruling.

**Pricing**
- [ ] Apple Small Business Program enrolment is **complete before the first sale**.
- [ ] The Play one-time-product rate for the target territories has been read **in Play Console**, not from a secondary source, and recorded.
- [ ] The price and territory list are the owner's answer to §7.1 open question 4, and that question is closed in writing before the first submission.

---

## References

**Project documents**

- `docs/research/00-tech-decisions.md` — §1 decision 5 (the manifest-merger prerequisite), §2 rows 86–93, §3.2 gates G0–G5, §3.3 the eight-entry permission set, §3.4 honest exceptions 2 and 5, §5.1 the verified versions, §6 corrections, §7.0 ruling 8 and §7.1 open question 4.
- `shed-book-spec.md` — §4.3 and §4.5 (positioning and privacy), §5 (the 3am test and zero interruptions), §7.1 (never block an entry), §7.9 (export is a safety feature), §7.10 (delete everything), §12 (the five safety rules), §14 (the free tier), §15 (success criteria), §17 (open questions).
- `docs/research/raw/07-monetization-and-release.md` — §1.1–§1.5 (why the model is free + one non-consumable), §2.1–§2.5 (the entitlement row, the acknowledgement window, the no-signal case), §3.1–§3.4 (the cap, `EntryContext`, the affordance constraints, the over-cap data rules), §4.1–§4.6 (privacy labels, the reason-code table, plugin aggregation, Play, the fees), §6.4 (purchase testing), §10 (pitfalls 3–13, 17).
- `docs/research/critique/c1-packages.md` — the `in_app_purchase` 3.3.0 row and the `in_app_purchase_storekit ≥ 0.4.8` floor.
- `docs/research/critique/c3-consistency.md` — B1 (`in_app_purchase` was invisible to the offline audit), B2 (the unverified `ACCESS_NETWORK_STATE` removal), B3 item 6 and item 9, C6 (the first frame is entitlement-agnostic), D7 (the cap's three placements and which one breaks §7.1).

**Sibling engineering documents**

`01-architecture.md` (the write path, `WriteRefused`, the policy gate, the boot sequence, the allowlist) · `02-state-di-navigation.md` (the DI graph, `Routes`, Riverpod 2.6.1 spellings) · `03-data-model-and-schema.md` (`entitlements`, `ewes.over_free_cap`, `seasons.over_free_cap`, `app_settings`) · `04-migrations-media-backup-restore.md` (the entitlement is never exported and never imported) · `05-domain-correctness.md` (`Instant`, `LocalDate`, `appNow()`) · `06-design-system.md` (`ShedBanner`, `showCapRow`, §12's three free-tier constraints) · `07-screens.md` (§14.3 Settings ▸ Unlock, §19 the cap surfaces and their copy) · `09-export-formats.md` · `12-testing.md` · `13-build-ci-release.md` (the CI shape, G0–G5, signing, the seasonal freeze) · `CODE-REVIEW-CHECKLIST.md` · `CONVENTIONS.md` (R30, R40, R54, R58, R69).

**Primary sources**

- Apple, *App Review Guidelines* — 3.1.1 (restore mechanism, trial-as-IAP), 4.2 (minimum functionality), 4.3(a) (multiple bundle ids), 4.8 (Sign in with Apple), 5.1.1(i) and 5.1.1(v). <https://developer.apple.com/app-store/review/guidelines/>
- Apple, *App privacy details on the App Store* — the definition of "collect". <https://developer.apple.com/app-store/app-privacy-details/>
- Apple, *Describing use of required reason API* (`NSPrivacyAccessedAPITypeReasons`) — the code table. <https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons>
- Apple, *Adding a privacy manifest to your app or third-party SDK*. <https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk>
- Apple, *Upcoming third-party SDK requirements* — the SDK list. <https://developer.apple.com/support/third-party-SDK-requirements/>
- Apple, *Transaction.currentEntitlements* — a local cache that the network populates. <https://developer.apple.com/documentation/storekit/transaction/currententitlements>
- Apple Developer Forums thread 706450 — DTS: *"To get the latest transactions the device will need internet access…"*, and the new-device-with-no-signal case. <https://developer.apple.com/forums/thread/706450>
- Apple, *Testing at all stages of development with Xcode and the sandbox* — the `.storekit` file, sandbox, TestFlight. <https://developer.apple.com/documentation/storekit/testing-at-all-stages-of-development-with-xcode-and-the-sandbox>
- Apple, *App Store Small Business Program* — 15%, under $1M, effective 15 days after the fiscal month of approval. <https://developer.apple.com/app-store/small-business-program/>
- Google, *Integrate Google Play's billing system* — the three-day acknowledgement window and the network-loss case it names. <https://developer.android.com/google/play/billing/integrate>
- Google, *Handle BillingResult response codes* — `SERVICE_UNAVAILABLE`, `BILLING_UNAVAILABLE`. <https://developer.android.com/google/play/billing/errors>
- Google, *Play Billing Library deprecation FAQ* — the PBL 8 and PBL 9 deadlines. <https://developer.android.com/google/play/billing/deprecation-faq>
- Google, *Test your Google Play Billing Library integration* — license testers. <https://developer.android.com/google/play/billing/test>
- Google, *Merge multiple manifest files* — merge priority and `tools:node="remove"` / `tools:selector`. <https://developer.android.com/build/manage-manifests>
- Google Play, *Provide information for Google Play's Data safety section* — the ephemeral, on-device and payment-service exemptions. <https://support.google.com/googleplay/android-developer/answer/10787469>
- Google Play, *Understanding Google Play's app account deletion requirements* — conditioned on account creation. <https://support.google.com/googleplay/android-developer/answer/13327111>
- Google Play, *Target API level requirements*. <https://support.google.com/googleplay/android-developer/answer/11926878>
- Google Play, *Use Play App Signing*. <https://support.google.com/googleplay/android-developer/answer/9842756>
- Android Developers Blog, *Expanded billing choice and lower fees on Google Play* (30 June 2026) — the service-fee / billing-fee split. <https://android-developers.googleblog.com/2026/06/play-expanded-billing.html>
- `in_app_purchase` API reference — the seven members this app uses. <https://pub.dev/documentation/in_app_purchase/latest/in_app_purchase/InAppPurchase-class.html>
- `in_app_purchase_android` Android manifest — empty. <https://raw.githubusercontent.com/flutter/packages/main/packages/in_app_purchase/in_app_purchase_android/android/src/main/AndroidManifest.xml>
- `in_app_purchase_android` build.gradle.kts — `com.android.billingclient:billing:8.0.0`. <https://raw.githubusercontent.com/flutter/packages/main/packages/in_app_purchase/in_app_purchase_android/android/build.gradle.kts>
- flutter#172434 — StoreKit 2 purchases reported as `restored` and left unfinished; fixed in `in_app_purchase_storekit` 0.4.8. <https://github.com/flutter/flutter/issues/172434>
- Flutter, *Build and release an Android app* — `INTERNET` lives in `src/debug` and `src/profile`, not `main`. <https://docs.flutter.dev/deployment/android>
- *What's new in Flutter 3.44* — Swift Package Manager is the default for iOS/macOS. <https://blog.flutter.dev/whats-new-in-flutter-3-44-b0cc1ad3c527>
- Archived Google IAB v3 integration guide — in-app billing is IPC through the Play Store app, which is why `com.android.vending.BILLING` exists. <https://stuff.mit.edu/afs/sipb/project/android/docs/google/play/billing/billing_integrate.html>
- Mirrored Play Billing AAR manifest, **billing 2.0.3** — architectural evidence only. **The 8.0.0 manifest could not be fetched from a primary source; G0 replaces it.** <https://github.com/dandar3/android-google-play-billing/blob/master/AndroidManifest.xml>

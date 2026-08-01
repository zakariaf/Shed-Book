# 07 — Monetization, store compliance, CI and release

**App:** Shed Book — offline-only Flutter lambing notebook (iOS + Android)
**Toolchain assumed:** Flutter 3.44.6 stable / Dart 3.12.2 / Xcode 26.6 / macOS arm64
**Research date:** 2026-07-27
**Status:** research notes, to be distilled into engineering docs. Everything version-sensitive was fetched, not recalled.

---

## Bottom line

| # | Decision | Confidence | Why |
|---|---|---|---|
| 1 | **Free app + one non-consumable IAP unlock** (`in_app_purchase` 3.3.0). Not paid-up-front, not two SKUs. | High | It is the only model that keeps the spec's free tier (§14) *and* keeps the Android release manifest free of `android.permission.INTERNET`. Two SKUs is a direct hit on App Review Guideline 4.3(a). |
| 2 | **The release Android manifest declares NO `android.permission.INTERNET`.** Play Billing does not need it. | High (verify once with the merger report) | Play Billing is binder IPC to the Play Store app; the Play Store process owns the socket. The billing AAR embeds only `com.android.vending.BILLING`. Flutter's own template puts INTERNET in `src/debug` + `src/profile` only. |
| 3 | **Entitlement is a locally-persisted fact in SQLite, written once, never revoked by the app.** The store is consulted only on explicit user action (Unlock / Restore). | High | `Transaction.currentEntitlements` needs the network at least once on a fresh install; `queryPurchasesAsync` hits the network when Play's cache expires. Neither is acceptable on the launch path of a 3am app. |
| 4 | **No modal upgrade prompt, ever.** The upgrade affordance is one static row at the top of the Flock screen and one row in Settings. | High | Spec §5: "Zero interruptions. No ads, no rating prompts… no notification permission nags mid-season." A timed modal is an ad. |
| 5 | **The cap gates two calm-UI actions only: starting a second season, and adding ewe #16 from the Flock screen.** Create-on-the-fly during Quick Entry / Lambing Entry is *never* blocked. Read, edit, search and **export are never gated**. | High | Spec §7.1 "Never block an entry"; §7.9 export is a safety feature, not a paywall lever. |
| 6 | **Declare "Data Not Collected" on Apple and "No data collected or shared" on Play.** Ship a `PrivacyInfo.xcprivacy` anyway. | High | Apple defines "collect" as transmitting off-device; Play explicitly exempts payment-service data and on-device-only processing. The privacy *manifest* is a separate, mandatory artefact. |
| 7 | **App PrivacyInfo.xcprivacy declares `C617.1` (file timestamp) + `CA92.1` (user defaults), and `E174.1` only if you actually query free disk space.** | High | Verified against Apple's reason-code table from two independent renderings. Do **not** use `0A2A.1` / `C56D.1` — those are third-party-SDK codes. |
| 8 | **`very_good_analysis` 10.3.0**, not `flutter_lints`. Keep its `strict-casts` / `strict-inference` / `strict-raw-types`. Turn off `public_member_api_docs` and `lines_longer_than_80_chars` for an app (not a package). | Medium-high | `flutter_lints` 6.0.0 sets no analyzer strict modes at all. For a single-developer app where the compiler is the only reviewer, strict modes are worth more than the lint list. |
| 9 | **CI: one Linux job on every push (format + analyze + codegen freshness + tests + Android AAB + a permission assertion). One macOS job on tags only.** | High | macOS runners bill at a **10× minute multiplier**; the GitHub Free plan's 2,000 minutes = **200 macOS minutes/month**. A per-push macOS build burns the whole quota in a week. |
| 10 | **No flavors for free/paid.** One binary, one bundle ID, one store listing per platform. | High | With IAP there is nothing to vary at build time. Flavors would only buy you a second Bundle ID, which is exactly what 4.3(a) forbids. |
| 11 | **"Under 20 MB" is achievable for the Android *download* and probably not for the iOS *install size*.** Reframe the spec's target as "bundled assets under 5 MB". | Medium-high | Flutter's own docs give no 2026 baseline. Community measurements put a plugin-light Flutter arm64 download at ~8–14 MB and iOS installs at 25–45 MB. |
| 12 | **A hosted privacy policy URL is mandatory on both stores** — the one piece of internet infrastructure this project cannot avoid. Also ship the full policy text *inside* the app as static Dart strings. | High | Apple 5.1.1(i) requires the link in App Store Connect metadata **and** "within the app in an easily accessible manner". Shipping the text offline satisfies the in-app half without `url_launcher`. |

---

## 1. The central tension: can an offline app sell an unlock?

The spec's strongest formulation of "offline" is:

> an Android build that declares NO INTERNET permission at all, and an iOS build that opens no socket

In-app purchase obviously involves money moving over a network. The question is *whose process opens the socket*. On both platforms the answer is: not ours.

### 1.1 Android — Play Billing does not need `android.permission.INTERNET`

Four pieces of evidence, from weakest to strongest:

**(a) The architecture is IPC, not HTTP.** Google's own (archived) integration guide states it plainly:

> "In-app billing relies on the Google Play application, which handles all communication between your application and the Google Play server. To use the Google Play application, your application must request the proper permission by adding the `com.android.vending.BILLING` permission to your AndroidManifest.xml file."
> — [Implementing In-app Billing (IAB v3), Android Developers (archived mirror)](https://stuff.mit.edu/afs/sipb/project/android/docs/google/play/billing/billing_integrate.html)

The client binds a `ServiceConnection` to an AIDL service exported by the Play Store app. Modern `BillingClient` keeps this shape — hence `ProxyBillingActivity`, a translucent activity in the library manifest whose only job is to host the Play Store's checkout sheet.

**(b) The error codes describe someone else's network.** [Handle BillingResult response codes](https://developer.android.com/google/play/billing/errors):

> `SERVICE_UNAVAILABLE` (2): "This transient error indicates the Google Play Billing service is currently unavailable. In most cases, this means there is a network connection issue anywhere **between the client device and Google Play Billing services**."
> `BILLING_UNAVAILABLE` (3): "The Play Store app on the user's device is out of date… The Play Store app is blocked by the system."

The failure surface is the *device's* Play Store, not our process.

**(c) The billing AAR's own manifest declares only BILLING.** A mirrored copy of the published AAR manifest shows exactly one permission, one activity, one meta-data key, no `<queries>`, no services:
[dandar3/android-google-play-billing AndroidManifest.xml](https://github.com/dandar3/android-google-play-billing/blob/master/AndroidManifest.xml) — `com.android.vending.BILLING`, `com.android.billingclient.api.ProxyBillingActivity` (`Theme.Translucent.NoTitleBar`), `com.google.android.play.billingclient.version`.

⚠️ **Caveat, stated honestly:** that mirror is billing 2.0.3. I could not fetch the AAR manifest for billing **8.0.0** (the version `in_app_purchase_android` actually pulls in) from a primary source — AARs are binary and Google Maven doesn't publish the manifest as text. Google's [deprecation FAQ](https://developer.android.com/google/play/billing/deprecation-faq) still discusses only `com.android.vending.BILLING` and the `com.google.android.play.billingclient.version` meta-data, and says "These dependencies only appear in APKs that require the `com.android.vending.BILLING` permission." Treat "no INTERNET in billing 8.0.0" as **highly likely but requiring one empirical check** (§1.5).

**(d) The Flutter plugin adds nothing.** `in_app_purchase_android`'s own Android manifest is literally empty:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
  package="io.flutter.plugins.inapppurchase">
</manifest>
```
— [flutter/packages `in_app_purchase_android/android/src/main/AndroidManifest.xml`](https://raw.githubusercontent.com/flutter/packages/main/packages/in_app_purchase/in_app_purchase_android/android/src/main/AndroidManifest.xml)

And its gradle pulls `com.android.billingclient:billing:8.0.0`:

```kotlin
dependencies {
    implementation("androidx.annotation:annotation:1.10.0")
    implementation("com.android.billingclient:billing:8.0.0")
    …
}
```
— [in_app_purchase_android/android/build.gradle.kts](https://raw.githubusercontent.com/flutter/packages/main/packages/in_app_purchase/in_app_purchase_android/android/build.gradle.kts)

(8.0.0 satisfies Google's deadline: "By **Aug 31, 2026**, all new apps and updates to existing apps must use Billing Library version 8 or later", extension to Nov 1, 2026 — [deprecation FAQ](https://developer.android.com/google/play/billing/deprecation-faq). Latest is 9.1.0, 2026-06-18 — [release notes](https://developer.android.com/google/play/billing/release-notes).)

### 1.2 Flutter itself already keeps INTERNET out of release builds

This is the part most Flutter developers get wrong, because their `main/AndroidManifest.xml` has had INTERNET pasted into it by a tutorial. Flutter's own documentation:

> "The standard template doesn't include this tag but allows Internet access during development to enable communication between Flutter tools and a running app."
> — [Build and release an Android app](https://docs.flutter.dev/deployment/android)

The permission lives in `android/app/src/debug/AndroidManifest.xml` and `android/app/src/profile/AndroidManifest.xml`, which the manifest merger only applies to those build types ([flutter/flutter#20789](https://github.com/flutter/flutter/issues/20789); merge priority: build variant > build type > flavor > main > libraries — [Merge multiple manifest files](https://developer.android.com/build/manage-manifests)).

**So the release AAB genuinely has no INTERNET permission, and hot reload still works in debug.** That is the whole trick, and it costs nothing.

### 1.3 iOS — StoreKit runs out of process and has no permission model

iOS has no manifest permission for network access, so "no INTERNET permission" has no iOS analogue. The meaningful claim is "the app process opens no socket." StoreKit 2 is an XPC client of the system App Store daemon; purchases, entitlement sync and receipt signing all happen in Apple's process. `in_app_purchase_storekit` (0.4.11, flutter.dev, published 3 days before this research) uses **StoreKit 2 by default since 0.4.0** — its changelog entry reads:

> "**BREAKING CHANGE:** StoreKit 2 is now the default for all devices that support it."
> — [in_app_purchase_storekit changelog](https://pub.dev/packages/in_app_purchase_storekit/changelog)

with `InAppPurchaseStoreKit1Platform.enableStoreKit1()` as an escape hatch ([in_app_purchase pub page](https://pub.dev/packages/in_app_purchase)).

### 1.4 What StoreKit 2 gives you *on-device*, and what still needs the network

This is the crux of the offline-entitlement question, and the popular answer ("StoreKit 2 verifies locally, so you're fine offline") is **half true**.

**On-device, no network:**
- Every transaction arrives as a **JWS payload signed by Apple**, and StoreKit verifies the signature locally before handing you `VerificationResult.verified(_)`. You never parse a receipt, never call a validation server.
- `Transaction.currentEntitlements` reads a **local cache**. Apple's docs describe it as "A sequence of the latest transactions that entitle a customer to In-App Purchases and subscriptions… a transaction for each non-consumable In-App Purchase" ([Transaction.currentEntitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements)).
- `AppTransaction.shared` reads the cached, App-Store-signed app transaction; `AppTransaction.refresh()` is the explicit network call ([AppTransaction](https://developer.apple.com/documentation/storekit/apptransaction)).

**Still needs the network:**
- Populating that cache in the first place. Apple's DTS answer on the developer forums:

  > "To get the latest transactions the device will need internet access but it does cache data locally and new transactions are pushed to the device when online, so could be up to date when it goes offline."
  > — [StoreKit 2 currentEntitlements without internet](https://developer.apple.com/forums/thread/706450)

  And the follow-up in that same thread names the exact failure this app will hit: a user who bought on another device, opens the app for the first time on a new phone **with no signal**, gets nothing, and the underlying `NSURLErrorDomain Code=-1009` is not cleanly catchable.
- `queryProductDetails` (fetching the localized price string).
- The purchase flow itself, obviously.

**Android is the same shape.** `queryPurchasesAsync` is served from a Play Store cache that expires and then re-fetches ([Google Play Developer Community thread](https://support.google.com/googleplay/android-developer/thread/275369787/google-s-in-app-billing-api-querypurchasesasync-returned-incorrect-results?hl=en); Google's own guidance is to call it "when your app successfully establishes a connection with the Google Play Billing Library" specifically to recover from "**Network Issues during the purchase**: A user can make a successful purchase and receive confirmation from Google, but their device loses network connectivity before their device and your app receives notification" — [Integrate Google Play's billing system](https://developer.android.com/google/play/billing/integrate)).

**Design consequence, and it is the single most important one in this document:**

> The store is a *source of a one-time fact*, not a runtime dependency. Ask it exactly twice — when the user taps Unlock, and when the user taps Restore. Write the answer to SQLite. Never ask again.

### 1.5 The three business models, weighed

| | **A. Free app + non-consumable IAP unlock** | **B. Paid up front** | **C. Two SKUs (free + paid app)** |
|---|---|---|---|
| Free tier possible? | ✅ Yes — the spec's "try it for a night" | ❌ No | ✅ Yes |
| Android INTERNET permission | Not required (§1.1) | Not required — zero store code in the binary | Not required |
| Store SDK in the binary | `in_app_purchase` + billing 8.0.0 AAR (~a few hundred KB) | **None** | Only in the paid one, or neither |
| Failure modes at runtime | Store unavailable, pending purchases, 3-day ack window, restore-with-no-signal | Effectively none | Same as A, plus… |
| Data migration free → paid | Trivial (same app, flip a flag) | N/A | ❌ **Broken.** Separate app sandbox; the shepherd's first season does not follow them. |
| Store policy risk | Standard freemium, no issue | None | ❌ **App Review 4.3(a)** |
| Discovery / conversion | Best | Worst — paid-up-front installs are a fraction of free installs | Confusing listing, split reviews |

**On option C specifically**, Apple is unambiguous:

> **4.3 Spam (a)** "Don't create multiple Bundle IDs of the same app… This practice results in unnecessary apps, which makes it hard for users to find the apps they want. If your app has different versions for specific locations, sports teams, universities, etc., **consider submitting a single app and providing the variations using in-app purchase**."
> — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

Independently of policy, option C fails the product: Shed Book's entire retention thesis (§7.7, "the moment the app becomes irreplaceable" is opening last season's ewe card) depends on the data surviving the purchase. A second app with a second sandbox destroys that.

**On option B (paid up front)** — it deserves more respect than it usually gets, and for a *different* app I would take it. It removes the billing AAR, the purchase stream, the 3-day acknowledgement window, the restore button, the pending-purchase state machine, and every screen that talks about money. That is maybe 400 lines of code and three failure modes deleted. But:
- Spec §14 explicitly wants the trial: "so the shepherd can try it for a night before committing." A shepherd will not pay €12 sight-unseen for an app from an unknown developer at the start of lambing.
- Spec §16 kill criteria hinge on whether shepherds will move off paper at all. A paid-up-front app makes that impossible to learn cheaply.
- Apple's only sanctioned trial mechanism for a non-subscription app is itself an IAP:

  > "Non-subscription apps may offer a free time-based trial period before presenting a full unlock option by setting up a **Non-Consumable IAP item at Price Tier 0** that follows the naming convention: **'XX-day Trial.'**"
  > — [App Review Guidelines 3.1.1](https://developer.apple.com/app-store/review/guidelines/)

  So even "paid app with a trial" ends up shipping StoreKit. Option B is really "no trial at all."

**Verdict: option A.** Ship the free app with one non-consumable. Keep the option-B purity claim by *earning it in the manifest* rather than by removing the feature.

### 1.6 The one empirical check that must happen before you trust any of this

Do this on day one of the Android work, not the week before launch:

```bash
flutter build appbundle --release

# 1. Read the merger's decision tree — it names the source of every permission.
grep -n -i "INTERNET" build/app/outputs/logs/manifest-merger-release-report.txt

# 2. Read the merged manifest that actually shipped.
#    (Path varies by AGP; find it rather than guessing.)
find build -name AndroidManifest.xml -path "*merged*" -print

# 3. Assert against the built artifact, not the source.
bundletool dump manifest --bundle build/app/outputs/bundle/release/app-release.aab \
  | grep -i "uses-permission"
```

Expected output: `com.android.vending.BILLING`, `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`, camera/mic if OCR and voice notes ship. **Not** `android.permission.INTERNET`.

If something does drag INTERNET in, the manifest merger gives you a surgical removal — but only use it after you know what would break:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          xmlns:tools="http://schemas.android.com/tools">
    <uses-permission android:name="android.permission.INTERNET" tools:node="remove" />
</manifest>
```
(`tools:node="remove"`, and `tools:selector="<library-package>"` to scope it to one dependency — [Merge multiple manifest files](https://developer.android.com/build/manage-manifests).)

**Be honest about what the claim means.** "No INTERNET permission" means *our process cannot open a socket*. It does not mean no bytes ever move on the device on our behalf — the Play Store app does the purchase round-trip. The privacy claim that actually matters to a shepherd (spec §4.5: "Losses, barren rates and treatment records… stay on the device") is fully and literally true either way, and the permission line in the Play listing is a *verifiable* proof of it that no competitor with a sync queue can match. That is a marketing asset. Say it accurately.

---

## 2. Offline entitlement: how the app knows it's unlocked

### 2.1 The entitlement is a row, not a query

```sql
-- One row, id pinned to 1. Lives in the same SQLite file as everything else,
-- so it is atomic with every other write and cannot drift.
CREATE TABLE entitlement (
  id                       INTEGER PRIMARY KEY CHECK (id = 1),
  unlocked                 INTEGER NOT NULL DEFAULT 0,   -- 0/1
  product_id               TEXT,
  store                    TEXT,        -- 'app_store' | 'play'
  acquired_via             TEXT,        -- 'purchase' | 'restore'
  purchase_id              TEXT,        -- PurchaseDetails.purchaseID, for support emails
  recorded_at              TEXT NOT NULL,
  recorded_at_was_edited   INTEGER NOT NULL DEFAULT 0    -- always 0; mirrors the
                                                          -- app-wide honest-timestamp rule
) STRICT;
```

Three rules that follow from the spec, not from convention:

1. **Write-once, never revoked.** The app never sets `unlocked` back to 0. Apple and Google can revoke a purchase after a refund, but detecting that requires polling the store — i.e. requires the network on the launch path, which is exactly what we refuse to do. Re-locking a shepherd on night nine of lambing because a refund propagated is unacceptable; the revenue at risk is €12. **Deliberate, documented decision.**
2. **Excluded from JSON backup/export.** The entitlement belongs to a store account, not to the flock data. Including it in the §7.9 full JSON backup would (a) turn the backup file into a licence key and (b) be *wrong* — restoring your neighbour's backup should not unlock your app. The export writer must skip this table; the import reader must ignore it if present.
3. **Never in `shared_preferences`.** Prefs are trivially editable on a rooted device and, more importantly, they are a second source of truth that can disagree with the DB after a restore. One file, one truth. (Bonus: skipping `shared_preferences` also removes one `NSPrivacyAccessedAPICategoryUserDefaults` obligation — see §4.2.)

### 2.2 Reading it is synchronous and free

```dart
/// Read at startup, cached in memory for the process lifetime.
/// This is a single-row SELECT on an already-open database — it is not
/// allowed to be async at the call site, and it never touches the store.
final class Entitlement {
  const Entitlement({required this.isUnlocked, this.recordedAt});
  final bool isUnlocked;
  final DateTime? recordedAt;

  static const locked = Entitlement(isUnlocked: false);
}
```

Nothing on the 3am path may `await` a store call. The Quick Entry screen must be able to render before the billing client has even connected.

### 2.3 The purchase flow (current API, `in_app_purchase` 3.3.0)

Public surface verified from [InAppPurchase class docs](https://pub.dev/documentation/in_app_purchase/latest/in_app_purchase/InAppPurchase-class.html):

| member | signature |
|---|---|
| `InAppPurchase.instance` | `InAppPurchase` |
| `purchaseStream` | `Stream<List<PurchaseDetails>>` |
| `isAvailable()` | `Future<bool>` |
| `queryProductDetails(Set<String>)` | `Future<ProductDetailsResponse>` |
| `buyNonConsumable({required PurchaseParam purchaseParam})` | `Future<bool>` |
| `buyConsumable({required PurchaseParam purchaseParam, bool autoConsume = true})` | `Future<bool>` |
| `completePurchase(PurchaseDetails)` | `Future<void>` |
| `restorePurchases({String? applicationUserName})` | `Future<void>` |
| `getPlatformAddition<T extends InAppPurchasePlatformAddition?>()` | `T` |

```dart
import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

const kUnlockProductId = 'shedbook_full_unlock';

/// Owns the *only* two moments this app talks to a store.
///
/// Lifecycle rule: the purchase stream listener is attached after the first
/// frame (it is a cheap event subscription, not a network call, and StoreKit
/// re-delivers unfinished transactions through it). Nothing else — no
/// isAvailable(), no queryProductDetails() — runs until the user opens
/// the Unlock screen.
final class StoreGateway {
  StoreGateway(this._iap, this._entitlements);

  final InAppPurchase _iap;
  final EntitlementRepository _entitlements;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  void attach() {
    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (_, __) {/* swallow: an offline app is never blocked by this */},
    );
  }

  Future<void> dispose() async => _sub?.cancel();

  Future<void> _onPurchases(List<PurchaseDetails> updates) async {
    for (final p in updates) {
      switch (p.status) {
        case PurchaseStatus.pending:
          // Android only (e.g. cash / slow payment instruments). Do NOT unlock,
          // do NOT complete. The user is told "waiting for your payment method".
          break;

        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          // Never downgrade an existing entitlement on an error.
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (p.productID == kUnlockProductId) {
            await _entitlements.markUnlocked(
              purchaseId: p.purchaseID,
              acquiredVia: p.status == PurchaseStatus.restored
                  ? 'restore'
                  : 'purchase',
            );
          }
      }

      // MUST run for purchased/restored/error, on every platform.
      // Android: this is acknowledgePurchase(). Miss it for 3 days and Google
      // auto-refunds and revokes the entitlement.
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }
}
```

On the acknowledgement window, Google is explicit:

> "your app needs to notify Google that the purchase was successfully processed… and must be done **within three days so that the purchase isn't automatically refunded and entitlement revoked**… The three-day acknowledgement window begins only when the purchase state transitions from 'PENDING' to 'PURCHASED'."
> — [Integrate Google Play's billing system](https://developer.android.com/google/play/billing/integrate)

**The dangerous case is the one Google names:** the user pays, Play confirms, and our app never receives the update because the phone dropped off the network. If we never acknowledge, the purchase auto-refunds. The fix without a launch-time network call:

- When we call `buyNonConsumable`, set a local `purchase_in_flight_at` timestamp.
- On next launch, **only if** `purchase_in_flight_at` is set and `unlocked = 0`, initialise the billing client and let the purchase stream drain. This is bounded, rare and self-clearing.
- Also drain whenever the user opens the Unlock/Restore screen.

### 2.4 Restore — Apple mandates it

> **3.1.1 In-App Purchase:** "Any credits or in-game currencies purchased via in-app purchase may not expire, and **you should make sure you have a restore mechanism for any restorable in-app purchases**."
> — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

That is the current guideline number: **3.1.1**, not a sub-clause. In practice reviewers look for a visibly labelled "Restore Purchases" control on the same screen as the buy button; a missing one is a routine rejection.

For a no-account app, pass nothing:

```dart
await InAppPurchase.instance.restorePurchases(); // applicationUserName: null
```

`restorePurchases` replays through `purchaseStream` with `PurchaseStatus.restored`, which the handler above already treats as an unlock.

### 2.5 New device, no signal — the honest UX

The scenario is real for this audience: new phone, JSON backup restored from a USB stick in the shed, no bars.

| State | Behaviour |
|---|---|
| Restored data, `unlocked = 0`, no signal | App is **fully usable**. All existing ewes readable, editable, exportable. |
| User taps Restore, no signal | Fails. Show: *"Restoring your purchase needs a connection to the App Store, just once. Everything else in Shed Book works offline."* Then a "Try again" that stays put. |
| User taps Unlock instead, has signal, already owns it | Both stores handle this. Play returns `ITEM_ALREADY_OWNED`; StoreKit resolves it as a restore. Nobody is charged twice. Still, put Restore *above* Unlock on the screen so the double-charge fear never arises. |

**The rule that makes all of this safe: the cap is never applied retroactively.** A restored 200-ewe flock in free mode is fully readable and fully exportable. See §3.

---

## 3. The free-tier cap without degrading 3am

### 3.1 What is capped

Spec §14: "Free tier: full app, capped at a small flock (e.g. 15 ewes) or one season… The cap must not degrade the 3am experience."

| Capability | Free | Paid |
|---|---|---|
| Read / search / filter any existing record | ✅ | ✅ |
| Edit any existing record | ✅ | ✅ |
| Lambing events, lambs, fostering, treatments, pen board, reminders | ✅ unlimited | ✅ |
| **CSV / PDF / JSON export** | ✅ **always** | ✅ |
| Create a new ewe from the Flock screen when at 15 | ❌ blocked (calm UI) | ✅ |
| Create a new ewe *during Quick Entry / Lambing Entry* | ✅ **always allowed** | ✅ |
| Start a second season | ❌ blocked (calm UI) | ✅ |

Two lines deserve defending.

**Export is never gated.** Spec §7.9 calls export "a safety feature, not a convenience", and §7.9 also asks the app to be "honest that a lost phone is lost data unless the user exports." Paywalling the only backup mechanism in an app with no cloud would be a data-hostage pattern. It also converts badly — the shepherd who cannot get their data out writes the review that kills the app.

**Create-on-the-fly is never blocked.** Spec §7.1: "if the tag does not exist, one tap creates the ewe and continues. **Never block an entry to make the user go and set something up first.**" A paywall at 03:20 with a lamb in one hand is the worst possible modal in the worst possible moment. So the entry path always succeeds and the row is flagged.

### 3.2 Where the check lives

Not in widgets. In one policy object consulted by the repository, with the *calling context* as an explicit parameter — so the rule is impossible to get wrong by accident and is unit-testable without a widget test.

```dart
enum EntryContext {
  /// Flock screen "+", Settings, restore/import UI, season switcher.
  /// A block here is legitimate: the user is standing still, in daylight,
  /// with two hands free.
  calm,

  /// Quick Entry keypad and Lambing Entry create-on-the-fly.
  /// A block here is forbidden by spec §7.1 and §5.
  liveEntry,
}

sealed class CapDecision {
  const CapDecision();
}
final class Allow extends CapDecision {
  const Allow({this.overFreeCap = false});
  /// True when we let a write through at 3am that the free tier would
  /// otherwise have refused. Recorded on the row, surfaced later, calmly.
  final bool overFreeCap;
}
final class BlockedByCap extends CapDecision {
  const BlockedByCap(this.limit);
  final int limit;
}

final class FreeTierPolicy {
  const FreeTierPolicy({this.maxEwesPerSeason = 15, this.maxSeasons = 1});
  final int maxEwesPerSeason;
  final int maxSeasons;

  CapDecision canCreateEwe({
    required bool unlocked,
    required int ewesInCurrentSeason,
    required EntryContext context,
  }) {
    if (unlocked) return const Allow();
    if (ewesInCurrentSeason < maxEwesPerSeason) return const Allow();
    return switch (context) {
      EntryContext.liveEntry => const Allow(overFreeCap: true), // never block
      EntryContext.calm => BlockedByCap(maxEwesPerSeason),
    };
  }

  /// Starting a season is *always* a calm-UI action (Settings → season
  /// switching, spec §7.10), so this one can block unconditionally.
  CapDecision canStartSeason({
    required bool unlocked,
    required int existingSeasonCount,
  }) =>
      unlocked || existingSeasonCount < maxSeasons
          ? const Allow()
          : BlockedByCap(maxSeasons);
}
```

The season gate is the better of the two, and it should be the primary one. It costs nothing at 3am (you switch seasons in August, not in March at 03:20), and it lands exactly where spec §7.7 says the value is: *"At least one user opens a ewe's previous-season history during their second season. That is the moment the app becomes irreplaceable."* You are asking for money at the precise moment the product has proved itself.

### 3.3 What the upgrade prompt must never do

Spec §5 is a hard constraint list, and a timed upsell modal violates it directly:

> "**Zero interruptions.** No ads, no rating prompts, no onboarding after first run, no 'what's new', no notification permission nags mid-season."

Therefore:

- **No modal, ever.** Not on launch, not on the Nth save, not on the 16th ewe, not at end of season.
- **No interstitial, no full-screen takeover, no bottom sheet that appears by itself.**
- The affordance is **two static places**: a single row pinned at the top of the Flock screen (`Free version · 15 of 15 ewes · Unlock — €12 once`) and a row in Settings. Both are always there, in the same pixels, whether you are at 3 ewes or 15. Nothing appears or moves.
- **Nothing monetization-related renders on Quick Entry, Lambing Entry, Lamb Card, Foster, or Pen Board.** These are the shed screens. Enforce it with a widget test that pumps each of those routes with `unlocked: false, ewesInCurrentSeason: 99` and asserts no upgrade widget is found.
- When `BlockedByCap` comes back from a calm-UI action, the *user initiated that tap*, so navigating to the Unlock screen is a response, not an interruption. That is the only navigation to Unlock the app ever performs on its own.

There is a real objection here: "a permanent static row converts worse than a well-timed modal." That is true and I am recommending against the higher-converting option on purpose, because spec §5 is written as a shipping gate ("If a feature cannot be operated under these conditions, it does not ship") and because this audience is described as "vocally hostile to farm-software subscriptions" (§14) — the same people who will punish an app that nags. The conversion mechanism here is the season wall, not the prompt.

### 3.4 Data consequences of exceeding the cap and later paying

- Rows created over the cap are **real rows**, indistinguishable from any other except for an `over_free_cap` boolean and, ideally, nothing else. No shadow storage, no "pending" table, no separate sandbox.
- On unlock: set `unlocked = 1` and clear the `over_free_cap` flags in the same transaction. Nothing to migrate, nothing to reconcile, no risk of losing an entry.
- On *not* paying: nothing is deleted, hidden, greyed out or made read-only. Ever. The shepherd who tried it for one season and walked away must still be able to open the app in year two and export their CSV. Anything else is data ransom and, for an app whose selling point is "no company can take your five seasons away in 2029" (§4.3), it is self-contradictory.
- The `over_free_cap` count is what powers the honest line on the Flock row: *"22 ewes recorded · free version covers 15."* No exclamation mark, no colour change to red, no badge.

---

## 4. Store compliance for an app that collects nothing

### 4.1 Apple — a genuine "Data Not Collected"

Apple defines the operative verb narrowly:

> "**Collect** refers to transmitting data off the device in a way that allows you and/or your third-party partners to access it for a period longer than what is necessary to service the transmitted request in real time."
> — [App privacy details on the App Store](https://developer.apple.com/app-store/app-privacy-details/)

Shed Book transmits nothing. Photos, notes, treatment records and the SQLite file never leave the device except through the **system share sheet**, where the user chooses the destination — that is the user transmitting, not the app. So every one of Apple's fourteen categories is answered "No", and the label renders as **Data Not Collected**.

Two judgement calls to record explicitly:

- **In-app purchase data.** Apple, not the developer, processes and retains it. We receive a `purchaseID` and nothing that identifies a person. The developer is not "collecting" it under the definition above. This is the near-universal reading for freemium apps with no backend. *If you ever add a backend, this answer changes and the label must be updated before that build ships.*
- **Crash reports / analytics.** There are none, by design (see §4.5). If you later add Sentry, Crashlytics or even Flutter's own error reporting to a server, the label is no longer "Data Not Collected" and `NSPrivacyTrackingDomains` may become relevant.

**Privacy policy is still mandatory.** Guideline 5.1.1(i):

> "All apps must include a link to their privacy policy in the App Store Connect metadata field **and within the app in an easily accessible manner**."

Ship the policy text as static Dart strings on a Settings → Privacy screen (readable in the shed with no signal — a small, genuine win), plus the hosted URL for store metadata. This also avoids adding `url_launcher`, which is itself on Apple's privacy-manifest list (§4.3).

### 4.2 PrivacyInfo.xcprivacy and the required-reason APIs

This is a real, mechanical rejection cause (`ITMS-91053: Missing API declaration`), so the codes matter. The full table below was cross-checked against two independent renderings of Apple's page ([NSPrivacyAccessedAPITypeReasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons), [mirror gist](https://gist.github.com/mironal/9169633fb09c06c2f8f781ebe01644b7)) because the first fetch returned a garbled mapping. **Do not trust a single summary of this table.**

**`NSPrivacyAccessedAPICategoryFileTimestamp`**
| Code | Meaning |
|---|---|
| `DDA9.1` | Display file timestamps to the person using the device. May not be sent off-device. |
| `C617.1` | Access timestamps/size/metadata of files **inside the app container, app group container, or the app's CloudKit container**. |
| `3B52.1` | Access metadata of files the user specifically granted access to (e.g. document picker). |
| `0A2A.1` | **Third-party SDK only** — wrapper around file-timestamp APIs. |

**`NSPrivacyAccessedAPICategorySystemBootTime`**
| Code | Meaning |
|---|---|
| `35F9.1` | Measure elapsed time between in-app events. Not sent off-device. |
| `8FFB.1` | Calculate absolute timestamps for in-app events (UIKit/AVFAudio). |
| `3D61.1` | Include boot time in a user-submitted bug report. |

**`NSPrivacyAccessedAPICategoryDiskSpace`**
| Code | Meaning |
|---|---|
| `85F4.1` | Display disk-space info to the user. |
| `E174.1` | **Check whether there is sufficient disk space to write files**, or detect low disk space. |
| `7D9E.1` | Include disk space in a user-submitted bug report. |
| `B728.1` | Health research app detecting low disk space affecting research data. |

**`NSPrivacyAccessedAPICategoryActiveKeyboards`** — `3EC4.1` (custom keyboard app), `54BD.1` (present correct customised UI). *Not applicable here.*

**`NSPrivacyAccessedAPICategoryUserDefaults`**
| Code | Meaning |
|---|---|
| `CA92.1` | Read/write information **accessible only to the app itself**. |
| `1C8F.1` | Read/write within the same App Group. |
| `C56D.1` | **Third-party SDK only** — wrapper around user-defaults APIs. |
| `AC6B.1` | Read `com.apple.configuration.managed` (MDM) / write `com.apple.feedback.managed`. |

**What Shed Book's own manifest needs.** The app writes a SQLite file and a media folder in its container (`path_provider` → app documents), writes export temp files, and — if you use `shared_preferences` for anything at all — touches `NSUserDefaults`. Flutter itself already declares the engine's usage separately (§4.3), but the app must declare what *app-level* code triggers.

`ios/Runner/PrivacyInfo.xcprivacy`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>
  <false/>

  <key>NSPrivacyTrackingDomains</key>
  <array/>

  <!-- Genuinely empty. Shed Book transmits nothing off device. -->
  <key>NSPrivacyCollectedDataTypes</key>
  <array/>

  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <!-- SQLite database + media folder + export temp files, all inside the
         app container. Also covers path_provider / drift / share_plus paths. -->
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>C617.1</string></array>
    </dict>

    <!-- Only if the app actually uses NSUserDefaults (shared_preferences,
         or Flutter plugin state). Delete this dict if it does not. -->
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>CA92.1</string></array>
    </dict>

    <!-- Only if you check free space before writing a photo or a PDF export.
         Given spec §7.9 and the media folder, you probably will. Delete
         otherwise — do not declare APIs you do not call. -->
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

Rules of thumb:
- **Never put `0A2A.1` or `C56D.1` in an app's manifest.** They are reserved for SDK wrappers. Using them in an app manifest is the shape of `ITMS-91055: Invalid API reason declaration`.
- Over-declaring within your own valid codes is not a rejection cause; under-declaring is. When unsure between `C617.1` and nothing, declare `C617.1`.
- The file must be added to the **Runner target's Copy Bundle Resources**, at the root of the app bundle. A `PrivacyInfo.xcprivacy` sitting in the project but not in the target ships nothing.

### 4.3 Plugins ship their own manifests, and Xcode aggregates them

Apple maintains a list of "commonly used SDKs" that **must** include a privacy manifest and a signature when you submit a new app or an update that adds them. The list is 89 entries and it is full of this app's stack:

> …**connectivity_plus**, **device_info_plus**, **file_picker**, **Flutter**, flutter_inappwebview, **flutter_local_notifications**, fluttertoast, **image_picker_ios**, package_info_plus, **path_provider**, path_provider_ios, **share_plus**, shared_preferences_ios, **sqflite**, **url_launcher**, url_launcher_ios, video_player_avfoundation, webview_flutter_wkwebview…
> — [Upcoming third-party SDK requirements](https://developer.apple.com/support/third-party-SDK-requirements/)

Practical implications:

1. **`Flutter` itself is on the list**, and the engine ships its own manifest. Verified contents of `engine/src/flutter/shell/platform/darwin/ios/framework/PrivacyInfo.xcprivacy`: `NSPrivacyTracking = false`, `NSPrivacyCollectedDataTypes = []`, and `NSPrivacyAccessedAPITypes` = FileTimestamp `[0A2A.1, C617.1]` + SystemBootTime `[35F9.1]`. So Dart's `Stopwatch`/clock usage and the engine's file access are already covered — **you do not declare `35F9.1` yourself** unless you write native code that reads `systemUptime`/`mach_absolute_time`.
2. **You still need your own manifest.** SDK manifests cover SDK code; yours covers yours. They aggregate, they do not substitute.
3. **Verify the aggregate, don't assume it.** Archive the app (Product → Archive), right-click the archive in the Organizer, **Generate Privacy Report**. That PDF is what Apple's static analysis will roughly agree with. Do this once before the first submission and again after any plugin bump.
4. ⚠️ **Flutter 3.44 made Swift Package Manager the default dependency manager for iOS/macOS** ([What's new in Flutter 3.44](https://blog.flutter.dev/whats-new-in-flutter-3-44-b0cc1ad3c527)). Plugin resource bundles — which is how `PrivacyInfo.xcprivacy` files get into the app — are packaged differently by SwiftPM than by CocoaPods. **Re-generate the privacy report after the SwiftPM migration**, do not carry over a CocoaPods-era assumption. Known failure mode in the ecosystem: a package's manifest being shadowed or dropped, producing `ITMS-91061: Missing privacy manifest`.
5. Any plugin you pick that is *not* on Apple's list and does not ship a manifest is your problem to declare. `sqlite3_flutter_libs` is not on the list (and is now **0.6.0+eol / discontinued** — [pub.dev](https://pub.dev/packages/sqlite3_flutter_libs) — the publisher directs you to `package:sqlite3` 3.x, which no longer needs it). Whatever the database topic settles on, check whether it ships `PrivacyInfo.xcprivacy`, and if not, declare `C617.1` yourself (you already are).

### 4.4 Google Play

**Data safety form.** Answer "No" to collection and sharing. Google's own exemptions cover the two things that might look like collection:

> Data need not be declared as collected or shared if it is **processed ephemerally** (accessed in memory for a real-time request only), **processed on-device only** (never sent off-device), or end-to-end encrypted.
> — [Provide information for Google Play's Data safety section](https://support.google.com/googleplay/android-developer/answer/10787469)

and, directly on point for IAP:

> "If your app uses a payment service such as PayPal, Google Pay, **Google Play's billing system**, or similar services to complete payment transactions, **you don't need to declare collection of the data that the payment service collects** in connection with its processing of financial transactions, if the payment service collects this information directly from the user, and collection is governed by that service's terms."

Note: this exemption is why a plain `in_app_purchase` integration keeps a clean form, and why adding **RevenueCat would flip it** — with RevenueCat you must declare "Purchase history" as collected, because your app is transmitting purchase data to a third party.

**Privacy policy is required even with zero collection.** "Even apps with zero data collection must complete this form and provide a link to their privacy policy."

**Target API level.** By **31 August 2026**, new apps and updates must target **Android 16 (API 36)** or higher; existing apps must be at API 35 or higher to stay visible to new users on newer devices; extensions available to **1 November 2026** ([Target API level requirements](https://support.google.com/googleplay/android-developer/answer/11926878), [Meet Google Play's target API level requirement](https://developer.android.com/google/play/requirements/target-sdk)). Set `targetSdk = 36` from day one — a greenfield project has no reason to be behind.

**Data deletion policy: not applicable, and verified.** Play's account-deletion requirement is conditioned on account creation:

> "If your app enables account creation, you must provide users with an in-app path to delete their app accounts and associated data, and provide a web link resource where users can request app account deletion."
> — [Understanding Google Play's app account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111)

Shed Book has no accounts, so the answer is "users can't create accounts" and no deletion URL is needed. Still, describe in the privacy policy how data is destroyed: **Settings → Delete everything** (spec §7.10) and uninstall.

**Android App Bundle + Play App Signing** are both mandatory for new apps (since August 2021) and remain so ([Use Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)). You keep an upload key; Google holds the app signing key.

### 4.5 Store rules that people expect to bite, and whether they do

| Rule | Applies? | Evidence |
|---|---|---|
| Sign in with Apple (4.8) | **No.** Triggered only by third-party/social login. | No login at all. |
| Account deletion — Apple 5.1.1(v) | **No.** "**If your app supports account creation**, you must also offer account deletion within the app." | [Guidelines](https://developer.apple.com/app-store/review/guidelines/) |
| Account deletion — Play | **No**, same condition. | [Play Console Help 13327111](https://support.google.com/googleplay/android-developer/answer/13327111) |
| Privacy policy | **Yes, both stores, unconditionally.** | Apple 5.1.1(i); Play Data safety. |
| "No analytics at all" causes friction | **No.** There is no store rule requiring telemetry. The only cost is yours: you will be blind to crashes and to whether the 15-second target is met. Mitigate with an *opt-in, on-device-only* diagnostics screen (spec-compatible: nothing leaves the device) and with beta feedback from real shepherds. | — |
| Guideline 2.2 "Demos, betas, and trial versions of your app don't belong on the App Store" | **No**, for a freemium app. 2.2 targets incomplete builds. A capped-but-complete free tier is the model 3.1.1 and 4.3(a) actively recommend. | [Guidelines](https://developer.apple.com/app-store/review/guidelines/) |
| Guideline 4.2 Minimum Functionality | **Watch it.** The *free* experience is what the reviewer sees. It must be a working notebook, not a teaser. Our design (everything works, 15 ewes, export included) clears this comfortably; a hard 3-ewe demo would not. | [Guidelines](https://developer.apple.com/app-store/review/guidelines/) |
| App Review testing an offline app | **Prepare for it.** Reviewers test on a networked device but may not read your notes. Put in the App Review notes: *"This app has no server and no account. Android release builds declare no INTERNET permission. To test the unlock, use the sandbox account below; a Restore Purchases button is on the same screen."* | — |
| Apple SDK deadline | **Yes.** From **28 April 2026**, uploads must be built with **Xcode 26+ / iOS 26 SDK**. Xcode 26.6 satisfies this. | [SDK minimum requirements](https://developer.apple.com/news/upcoming-requirements/?id=02032026a) |
| UIScene lifecycle | **Handled.** Default for iOS since **Flutter 3.41**, auto-migrated by the CLI on `flutter run` / `flutter build ios`. Apple's warning: "In the release following iOS 26, any UIKit app built with the latest SDK will be required to use the UIScene life cycle, otherwise it will not launch." A greenfield 3.44 project gets it free. | [UIScene adoption](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate) |

### 4.6 Fees, for pricing the €10–15 decision

- **Apple Small Business Program: 15%** instead of 30%, for developers under **$1M USD** in annual proceeds; new developers qualify; enrolment takes effect 15 days after the end of the fiscal month of approval ([App Store Small Business Program](https://developer.apple.com/app-store/small-business-program/)). **Enrol before the first sale.** At €12 gross this is roughly €10.20 net vs €8.40.
- **Google Play restructured on 30 June 2026** (US, UK, EEA first, staggered elsewhere through 2027): the fee splits into a **service fee** and a **billing fee**. Service fee starts at 10% on the first $1M annual earnings and 10% on auto-renewing subscriptions, with tiered rates for other transaction types; the **billing fee is 5%** when you use Google Play's billing system in the US/UK/EEA ([Expanded billing choice and lower fees on Google Play](https://android-developers.googleblog.com/2026/06/play-expanded-billing.html)). Secondary reporting puts one-time purchases from new installs at a 20% service fee + 5% billing fee. ⚠️ **Confirm the exact rate for a one-time product in your target markets inside Play Console before setting the price** — this changed two months before this research and the secondary sources disagree in detail.
- Both stores let you set per-territory prices. Price in EUR for IE/UK-adjacent markets (spec §17 question 3 leans UK/Ireland) and let the stores convert.

---

## 5. App size and payload

### 5.1 What the numbers actually are

Flutter's own documentation gives **no current baseline** — the only figure on [Measuring your app's size](https://docs.flutter.dev/perf/app-size) is a Flutter 1.17 iOS demo at "5.4 MB compressed, 13.7 MB uncompressed", which is archaeology. Community measurements in 2026 put a minimal release build at roughly **4–10 MB for an arm64 Android download** and **12–15 MB+ for an iOS IPA**, with real plugin-carrying apps at **12–25 MB (Android)** and **30–50 MB (iOS)**. Treat all of these as order-of-magnitude, and **measure your own** (§5.3).

**Honest reading of spec §11.** It says: "Total app payload well under 20 MB, dominated by fonts and icons." That sentence is about *bundled content* — the ~40 authored husbandry terms, no breed database, no medicine database. That target is easy and should be restated as: **bundled assets under 5 MB, and no licensed data of any kind.** The *binary* is whatever Flutter's engine costs. On Android the user's download will plausibly land under 20 MB. **On iOS, getting the install size under 20 MB with this plugin set is unlikely, and the spec should not be read as promising it.**

### 5.2 What actually moves the needle, ranked

1. **Ship an AAB, never a fat APK.** "Removing the `--split-per-abi` flag results in a fat APK that contains your code compiled for *all* the target ABIs" — armeabi-v7a + arm64-v8a + x86-64 ([Build and release an Android app](https://docs.flutter.dev/deployment/android)). Play strips the rest per device. This is the single biggest lever and it is free. `flutter build apk --split-per-abi` only matters for direct-download distribution, which we do not do.
2. **ML Kit text recognition for tag OCR (spec §7.1) is the biggest discretionary payload — and it has an offline trap.** The *unbundled* model adds ~260 KB per script but **downloads the model through Google Play services on first use**; the *bundled* model adds **~4 MB per script** and works from install with no download ([ML Kit model installation paths](https://developers.google.com/ml-kit/tips/installation-paths)). For a permanently-offline app, **unbundled is disqualified** — a shepherd installing in the farmhouse and first using OCR in the shed would get nothing. So: bundled Latin script only (+~4 MB), or drop Android OCR and keep it iOS-only via Vision (which is free, in-OS, and adds zero bytes). *Final call belongs to the OCR/camera topic; flagging the size and offline consequences here.*
3. **`--split-debug-info` and `--obfuscate`.** Flutter documents `--split-debug-info` as able to "dramatically reduce code size" ([app-size](https://docs.flutter.dev/perf/app-size)); `flutter build ipa --obfuscate --split-debug-info=...` ([Build and release an iOS app](https://docs.flutter.dev/deployment/ios)). Keep the symbol directory as a CI artifact per release or your crash reports are noise. Note Flutter 3.44 changed a default here: *"Don't strip symbols from `libapp.so` on Android by default"* ([3.44.0 release notes](https://docs.flutter.dev/release/release-notes/release-notes-3.44.0)) — measure both ways.
4. **Fonts.** MaterialIcons is tree-shaken by default in release builds; custom icon fonts often are not. Spec §5 demands "High-contrast type, minimum 18 pt body" — that argues for one variable font or two static weights, not a nine-weight family. Two weights of a good sans is a couple of hundred KB; a full family is several MB.
5. **PDF generation** (spec §7.9 flock book + medicine record) pulls in a rendering library and, if you embed a font for the PDF, a second copy of that font. Reuse the app's font bytes for the PDF rather than shipping a separate one.
6. **R8** is always on: *"Code shrinking is always enabled in release builds"* — the `--[no-]shrink` flag has no effect ([deployment/android](https://docs.flutter.dev/deployment/android)).

### 5.3 Measure, in CI, every release

```bash
flutter build appbundle --release --analyze-size \
  --target-platform android-arm64 \
  --obfuscate --split-debug-info=build/symbols/android

flutter build ios --release --analyze-size \
  --obfuscate --split-debug-info=build/symbols/ios
```

Each writes a `*-code-size-analysis_*.json`; open it with `dart devtools` → "Open app size tool", and diff two of them to see what a dependency bump cost ([app-size](https://docs.flutter.dev/perf/app-size)). Archive the JSON as a CI artifact so the diff is possible at all.

---

## 6. Versioning, flavors, signing, release

### 6.1 Version and build number

`pubspec.yaml` `version: <build-name>+<build-number>` maps to:

| | Android | iOS |
|---|---|---|
| build-name (`1.0.0`) | `versionName` | `CFBundleShortVersionString` |
| build-number (`+1`) | `versionCode` | `CFBundleVersion` |

— [Build and release an iOS app](https://docs.flutter.dev/deployment/ios)

**Strategy for a solo dev:**
- `version: 1.0.0+1` in `pubspec.yaml` is the source of truth for the *name* only.
- **Build number = the CI run number, always.** `flutter build appbundle --build-number=${{ github.run_number }}`. Both stores reject a re-used build number, and a monotonically increasing integer you never have to think about removes an entire category of release-day friction. Overriding at build time is supported: `flutter build ipa --build-name=1.0.0 --build-number=2`.
- Bump the build-name by hand, in the tag. `git tag v1.1.0` triggers the release workflow; the workflow derives `--build-name` from the tag.
- Lambing is seasonal. **Freeze releases during the customer's lambing season** (roughly February–April in the UK/Ireland). A regression shipped on 3 March costs someone a night of records. Note this in the release checklist, not just in someone's head.

### 6.2 Flavors: not needed

Flutter flavors exist to vary "which icon, app name, API key, feature flag, and logging level is associated with a specific version of your app" ([Flavors](https://docs.flutter.dev/deployment/flavors)). With IAP there is nothing to vary — free and paid are the same binary with a different row in one table.

The one legitimate use would be a `dev` flavor with a different `applicationIdSuffix` so a debug build can coexist with the store build on your own phone. That is a nice-to-have, and it costs you: a second bundle ID means a second App Store Connect record and a second set of IAP products for sandbox testing. **For v1, skip flavors.** Use `--dart-define` for the handful of build-time toggles (e.g. `SHEDBOOK_DEBUG_UNLOCK=true` to bypass the paywall on your own device) and gate them behind `kDebugMode` so they cannot reach a release build.

### 6.3 Signing

**Android.** Generate an upload keystore, keep `android/key.properties` out of git, load it in `build.gradle.kts`:

```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes { release { signingConfig = signingConfigs.getByName("release") } }
}
```
— [Build and release an Android app](https://docs.flutter.dev/deployment/android)

In CI, base64 the keystore into a repository secret and write it out at build time. **Back the keystore up somewhere that is not your laptop** — Play App Signing means Google holds the *app signing* key so a lost upload key is recoverable via support, but that is a support ticket you do not want during lambing.

**iOS.** For a solo developer, let Xcode manage signing with automatic provisioning, and either (a) build releases locally on the Mac you already own, or (b) use `fastlane match` / App Store Connect API keys in CI. Given §7's cost analysis, **(a) is the right answer for v1**.

### 6.4 Test tracks

**Apple / TestFlight.** Internal testing (up to 100 members of your team, no App Review) is instant and is the right loop for a solo dev. External testing (up to 10,000, requires a TestFlight review) is how you get real shepherds on it. Upload with:

```bash
flutter build ipa --export-options-plist=ios/ExportOptions.plist
xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
```
— [Build and release an iOS app](https://docs.flutter.dev/deployment/ios)

**Google Play — this one has a trap for new solo developers.** Personal developer accounts created **after 13 November 2023** must run a **closed test with at least 12 opted-in testers for 14 continuous days** before they can apply for production access (reduced from 20 testers on 11 December 2024). Organisation accounts and older personal accounts are exempt.
— [App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465)

**Plan for this at the start of the project, not at the end.** Twelve real testers for fourteen days is 2–3 weeks of calendar time and requires recruiting a dozen people — which, for this app, means finding a dozen shepherds on The Farming Forum or Accidental Smallholder (spec §3). That recruitment doubles as the §17 user research. Do it during the build, not after.

**Testing purchases.**
- *Android:* add yourself to **Settings → License testing** in Play Console. License testers get test payment instruments ("always approves", "always declines", "slow test card") and — crucially — *"License testers can bypass this check, meaning you can sideload apps for testing, even for apps using debug builds with debug signatures without the need to upload to the new version of your app."* The package name must match a Play Console app, and the tester must also be opted into a test track or they will be charged for real. ([Test your Google Play Billing Library integration](https://developer.android.com/google/play/billing/test))
- *iOS:* three stages — a local **`.storekit` configuration file** (works fully offline, no Apple account, fastest loop), **Sandbox** with a sandbox Apple Account (network required), and **TestFlight** (network required). ([Testing at all stages of development with Xcode and the sandbox](https://developer.apple.com/documentation/storekit/testing-at-all-stages-of-development-with-xcode-and-the-sandbox))
- **Test the offline paths deliberately:** airplane mode + tap Unlock; airplane mode + tap Restore; buy on device A, install on device B with no signal, then restore once signal returns. These are the paths this app will actually take and they are the ones nobody tests.

---

## 7. CI for exactly one developer

### 7.1 The cost reality that determines the whole design

GitHub Actions bills minutes with an **OS multiplier: Linux 1×, Windows 2×, macOS 10×**, drawn from a pool measured in Linux-equivalent minutes. GitHub Free includes **2,000 minutes/month**, Pro **3,000**. Standard macOS runners are **$0.062/min**; Linux 2-core x64 **$0.006/min**. Public repositories run standard runners for free; private repositories draw on the quota. ([About billing for GitHub Actions](https://docs.github.com/en/billing/managing-billing-for-your-products/about-billing-for-github-actions))

**So on a private repo, GitHub Free gives you 200 macOS minutes per month.** A Flutter iOS build with a cold pub/CocoaPods/SwiftPM cache is 10–20 minutes. That is **ten to twenty iOS builds a month, total.** Running one on every push is not a budgeting mistake, it is a same-week outage.

Therefore:

| Trigger | Runner | Jobs |
|---|---|---|
| every push / PR | `ubuntu-latest` | format, analyze, codegen freshness, tests, **Android AAB + permission assertion** |
| tag `v*` | `ubuntu-latest` | signed AAB → artifact (upload to Play manually or via a later step) |
| tag `v*` | `macos-latest` **or your own laptop** | iOS archive |

**And the honest recommendation: for v1, build iOS on your Mac.** You have an Xcode 26.6 machine. `flutter build ipa` + Transporter is a five-minute manual step you perform maybe once a month. Automating it costs you signing-secret plumbing, `fastlane match`, and your entire macOS minute budget, to save five minutes. Automate it when release cadence justifies it, not before. *This is the opposite of the usual Flutter-CI blog post advice, and for a solo dev with a Mac it is correct.*

### 7.2 The workflow

Verified current action versions: `actions/checkout` **v7.0.1**, `actions/cache` **v6.1.0**, `actions/upload-artifact` **v7.0.1** (all fetched from the GitHub API, 2026-07-20 / 2026-06-26 / 2026-04-10). `subosito/flutter-action` is still on the **v2** major tag, latest **v2.23.0** (2026-03-25) — there is no v3. Note the maintenance concern: the project has had slow periods, though it now has a new maintainer; `flutter-actions/setup-flutter` exists as a drop-in alternative if that becomes a problem.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
    tags: ['v*']
  pull_request:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

env:
  FLUTTER_VERSION: '3.44.6'   # pinned. never 'stable'.

jobs:
  verify:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v7

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true

      - run: flutter --version
      - run: flutter pub get

      # 1. Formatting. --set-exit-if-changed makes it a gate, not a suggestion.
      - name: Format
        run: dart format --output=none --set-exit-if-changed .

      # 2. Codegen freshness. Generated files ARE committed (so a clean
      #    checkout builds), so CI must prove they match their sources.
      - name: Regenerate code
        run: dart run build_runner build --delete-conflicting-outputs
      - name: Codegen is fresh
        run: |
          if ! git diff --exit-code --stat; then
            echo "::error::Generated code is stale. Run:"
            echo "  dart run build_runner build --delete-conflicting-outputs"
            exit 1
          fi

      # 3. Static analysis. --fatal-infos defaults to true in flutter analyze,
      #    but pass it explicitly so the intent survives a tool change.
      - name: Analyze
        run: flutter analyze --fatal-infos --fatal-warnings

      # 4. Tests, with randomized ordering to catch order-dependent state.
      - name: Test
        run: |
          flutter test \
            --reporter github \
            --test-randomize-ordering-seed random \
            --coverage

      - uses: actions/upload-artifact@v7
        if: always()
        with:
          name: coverage
          path: coverage/lcov.info

  android:
    runs-on: ubuntu-latest
    needs: verify
    timeout-minutes: 25
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-java@v5
        with: { distribution: temurin, java-version: '17' }
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true

      - run: flutter pub get
      - name: Build app bundle
        run: |
          flutter build appbundle --release \
            --build-number=${{ github.run_number }} \
            --obfuscate --split-debug-info=build/symbols/android

      # ---- The gate that makes the whole offline claim enforceable ----
      - name: Assert the release bundle requests no network permission
        run: |
          curl -sSL -o bundletool.jar \
            https://github.com/google/bundletool/releases/latest/download/bundletool-all.jar
          java -jar bundletool.jar dump manifest \
            --bundle build/app/outputs/bundle/release/app-release.aab \
            > merged-manifest.xml
          echo "--- permissions in the shipped bundle ---"
          grep -o 'android:name="[^"]*permission[^"]*"' merged-manifest.xml | sort -u
          if grep -q 'android.permission.INTERNET' merged-manifest.xml; then
            echo "::error::android.permission.INTERNET is in the release manifest."
            echo "Shed Book ships with no network permission. Find the library that"
            echo "added it in build/app/outputs/logs/manifest-merger-release-report.txt"
            exit 1
          fi

      - uses: actions/upload-artifact@v7
        with:
          name: android-release
          path: |
            build/app/outputs/bundle/release/app-release.aab
            build/symbols/android
            merged-manifest.xml
```

Flags verified against the tool's own source: `flutter analyze` defines `--fatal-infos` ("Treat info level issues as fatal", **default `true`**) and `--fatal-warnings` (default `true`); `flutter test` defines `--test-randomize-ordering-seed` ("Must be a 32bit unsigned integer or the string \"random\""), `--reporter` (allows `compact`, `expanded`, `failures-only`, `github`, `json`, `silent`), `--coverage`, `--coverage-path` (default `coverage/lcov.info`), `--concurrency`, `--total-shards`/`--shard-index`.
— [flutter_tools analyze.dart](https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_tools/lib/src/commands/analyze.dart), [flutter_tools test.dart](https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_tools/lib/src/commands/test.dart), [package:test](https://pub.dev/packages/test)

### 7.3 What is worth automating with one developer, and what is not

**Worth it — because these fail silently and you will not notice:**
- `dart format --set-exit-if-changed`. Zero thought, zero diff noise forever.
- **Codegen freshness.** The failure is invisible locally (your `.g.dart` is fine because you generated it) and lethal on a fresh clone. Commit generated files *and* gate them.
- `flutter analyze --fatal-infos`. With strict-casts on (§8), this is your only reviewer.
- **The INTERNET-permission assertion.** This is the highest-value job in the whole pipeline. It is the only mechanical guard on the app's central promise, and the way it breaks — a transitive dependency of a plugin you bump in month six quietly merging a `<uses-permission>` — is exactly the kind of thing a solo developer never notices by hand. Make it fail the build.
- Randomized test ordering. Cheap; catches shared-state bugs that will otherwise appear as a flake at 11pm on release day.

**Not worth it — the automation costs more than the manual step:**
- iOS builds on every push (§7.1).
- Automated store uploads for v1. Manual upload of an AAB is 90 seconds and you *want* to look at the release notes and the staged rollout percentage anyway.
- Screenshot generation, `integration_test` on a device farm, coverage thresholds. All good for a team; all pure overhead for one person who is also the QA.
- Dependabot on every package. Do use it for GitHub Actions versions (low noise, real security value); for pub packages, a monthly manual `flutter pub outdated` is better because a plugin bump here can change the merged manifest or the privacy manifest and needs a human to look.

**A manual pre-release checklist beats a pipeline for the store-specific things:**
1. `bundletool dump manifest` permission list — read it, don't just let CI grep it.
2. Xcode → Archive → Generate Privacy Report — read the aggregate.
3. Airplane-mode pass: cold launch, save a lambing event, export a CSV, open Unlock, tap Restore.
4. Dark-launch check: no white flash (spec §5) — verify the iOS `LaunchScreen.storyboard` background and the Android `windowBackground`/splash are the app's dark surface colour, not white. This is a *release configuration* bug, not a Dart bug, so it will not appear in any test.
5. Season freeze: is it February–April? If so, is this release worth the risk?

---

## 8. Lints

### 8.1 The three candidates, as fetched

| Package | Version | Publisher | Built on | Analyzer strict modes | Rules |
|---|---|---|---|---|---|
| [`lints`](https://pub.dev/packages/lints) | **6.1.0** (5 months ago) | dart.dev | — | none | `core` + `recommended` |
| [`flutter_lints`](https://pub.dev/packages/flutter_lints) | **6.0.0** (14 months ago) | flutter.dev | `package:lints/recommended.yaml` | **none** | recommended + **10** Flutter rules |
| [`very_good_analysis`](https://pub.dev/packages/very_good_analysis) | **10.3.0** (38 days ago) | Very Good Ventures | its own set | **`strict-casts`, `strict-inference`, `strict-raw-types` all true** | ~215 |

`flutter_lints` 6.0.0's entire Flutter-specific contribution, verbatim from [flutter.yaml](https://raw.githubusercontent.com/flutter/packages/main/packages/flutter_lints/lib/flutter.yaml):

```yaml
include: package:lints/recommended.yaml
linter:
  rules:
    - avoid_print
    - avoid_unnecessary_containers
    - avoid_web_libraries_in_flutter
    - no_logic_in_create_state
    - prefer_const_constructors_in_immutables
    - sized_box_for_whitespace
    - sort_child_properties_last
    - use_build_context_synchronously
    - use_full_hex_values_for_flutter_colors
    - use_key_in_widget_constructors
```

Ten rules, and **no analyzer language modes at all**. That last part is the decision.

### 8.2 Why strict modes matter more than the rule count here

The three modes ([Customizing static analysis](https://dart.dev/tools/analysis)):

- **`strict-casts`** — "ensures that the type inference engine never implicitly casts from `dynamic` to a more specific type". This is the one that matters. Every row that comes back from SQLite, every field parsed out of a JSON backup (spec §7.9), and every `PurchaseDetails` field is a `dynamic`-adjacent boundary. Without `strict-casts`, `final w = row['birth_weight'];` silently becomes whatever you assign it to and blows up at runtime — in a barn, at 3am, on a record that is now lost.
- **`strict-raw-types`** — no bare `List`/`Map`/`Future`.
- **`strict-inference`** — no silent `dynamic` when inference cannot decide.

For an app whose safety rules include *"Never silently correct a user's entry"* (§12.4) and *"Timestamps are honest"* (§12.5), the type system doing its job at every data boundary is not stylistic. It is the same discipline in the compiler.

**Recommendation: `very_good_analysis` 10.3.0**, then switch off the rules that are for *packages*, not apps.

### 8.3 `analysis_options.yaml`

```yaml
# Shed Book — analysis configuration.
#
# Base: very_good_analysis 10.3.0. Chosen over flutter_lints because
# flutter_lints sets no analyzer language modes, and strict-casts is the
# single most valuable setting in a data-heavy offline app where every
# SQLite row and every JSON-backup field is an untyped boundary.
include: package:very_good_analysis/analysis_options.10.3.0.yaml

analyzer:
  # Inherited from very_good_analysis, restated so the intent is visible
  # in this repo and survives a base-package bump.
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

  errors:
    # Missing a required-reason or a null check must never be a "hint".
    invalid_annotation_target: ignore     # freezed/json_serializable noise
    todo: ignore

    # Project-specific promotions. These map directly to spec §12.
    unrelated_type_equality_checks: error
    collection_methods_unrelated_type: error
    avoid_dynamic_calls: error
    use_build_context_synchronously: error
    close_sinks: error                    # purchase stream subscriptions

  exclude:
    - '**/*.g.dart'
    - '**/*.freezed.dart'
    - '**/*.drift.dart'
    - 'build/**'

  plugins:
    - custom_lint            # only if the codegen topic adopts riverpod_lint / drift's lints

linter:
  rules:
    # --- Turned OFF: these are package-publishing rules, not app rules ---
    public_member_api_docs: false
    lines_longer_than_80_chars: false     # see `formatter.page_width` below
    always_use_package_imports: true      # keep: relative imports bite on refactors

    # --- Turned ON explicitly: they encode spec rules ---
    avoid_print: true                     # nothing should log in a release shed app
    prefer_const_constructors: true        # cheap frames on the 3am path
    prefer_const_constructors_in_immutables: true
    sort_constructors_first: true
    unawaited_futures: true               # a dropped await == a lost write (§5 "every
                                          # write is committed immediately")
    only_throw_errors: true
    require_trailing_commas: true

formatter:
  page_width: 100
```

Note `formatter.page_width` is the current, documented way to set line length (default 80), alongside `trailing_commas: automate | preserve` ([Customizing static analysis](https://dart.dev/tools/analysis)). Setting it there and disabling `lines_longer_than_80_chars` keeps the formatter and the linter from arguing.

**Honest counter-argument:** `very_good_analysis` at ~215 rules will produce a wall of diagnostics on day one and some of its opinions (`sort_constructors_first`, `require_trailing_commas`) are pure taste. If you find yourself disabling more than about a dozen rules, you have effectively built a custom set and would be better off with `include: package:flutter_lints/flutter.yaml` plus the `analyzer.language` block above — which gets you the 90% of the value (strict modes) with 10% of the noise. **That is a legitimate fallback and I would not argue with a developer who took it.** What is *not* acceptable is `flutter_lints` alone, with no strict modes.

---

## 9. Rejected alternatives

| Rejected | Why it lost |
|---|---|
| **RevenueCat (`purchases_flutter` 10.4.3)** | It is "a client for the RevenueCat subscription and purchase tracking system" with "server-side receipt validation" ([pub.dev](https://pub.dev/packages/purchases_flutter)). That is a mandatory third-party network path, an API key, and — per Google's own guidance — a **Data safety declaration of "Purchase history" collected**, which destroys the "collects nothing" claim. Excellent product; categorically wrong for this app. This is the clearest case in the whole document where the popular Flutter answer is flatly incorrect here. |
| **`flutter_inapp_purchase` 9.6.1 (OpenIAP)** | Genuinely current — StoreKit 2 and **Play Billing 9.1.0**, ahead of the first-party plugin's 8.0.0, published hours before this research, hyo.dev. But: single-maintainer, MIT, and a much thinner track record than `flutter.dev`'s. For an app that must still build in 2031 with no server to keep it alive, the first-party plugin's institutional backing is worth more than a Billing Library minor version. Revisit if `in_app_purchase` misses the Aug 2027 PBL 9 deadline. |
| **Paid up front, no IAP** | Kills the spec §14 free tier, which is the wedge against subscription incumbents. See §1.5 — I hold this open as a fallback if App Review pushes back on the freemium model, since it is a *smaller* app, not a bigger one. |
| **Two SKUs (Shed Book Free + Shed Book Pro)** | App Review 4.3(a) forbids multiple Bundle IDs of the same app and names IAP as the sanctioned alternative. Independently, it breaks free→paid data migration, which destroys the year-two recall thesis (§7.7). |
| **A time-limited trial ("XX-day Trial" non-consumable at Price Tier 0, per 3.1.1)** | Allowed by Apple, but wrong for the product: lambing is a two-to-six-week burst, and a 14-day clock that expires on night eleven — the exact night spec §15 names as the retention test — is maximally hostile. Google Play has no equivalent construct, so you would be running two different trial models. A capacity cap is platform-neutral and season-shaped. |
| **Server-side receipt validation** | Requires a server. Non-starter (spec §4.3). StoreKit 2 verifies the JWS locally and Play Billing purchases are signed; for a €12 one-time unlock, local verification plus "write once, never revoke" is the correct risk posture. |
| **Checking the store on every launch to detect refunds** | Puts a network call on the launch path of an app whose whole promise is that it works with no signal, and creates a state where a shepherd is locked out mid-season by a transient store error. Rejected explicitly. |
| **Modal / timed upgrade prompt** | Spec §5 "Zero interruptions". A conversion-optimised modal is an ad. |
| **Paywalling export** | Spec §7.9 makes export the only backup. Gating it is a data-hostage pattern that contradicts §4.3's own selling point. |
| **`shared_preferences` for the entitlement** | Second source of truth; disagrees with the DB after a restore; also adds an `NSPrivacyAccessedAPICategoryUserDefaults` obligation. One SQLite file, one truth. |
| **`flutter_lints` alone** | Sets no analyzer language modes. `strict-casts` is the highest-value analyzer setting for this codebase and `flutter_lints` does not give it to you. |
| **`--split-per-abi` APKs for Play** | Play wants an AAB and does per-device splitting itself; per-ABI APKs are for direct distribution, which we do not do. |
| **ML Kit *unbundled* text recognition** | Downloads the model through Play services on first use. A shepherd who installs in the farmhouse and first uses OCR in the shed gets nothing. Bundled (+~4 MB) or nothing. |
| **iOS build on every push in CI** | 10× minute multiplier; 200 macOS minutes/month on GitHub Free. Build iOS on the Mac you already have. |
| **`subosito/flutter-action@v3`** | Does not exist. Latest is **v2.23.0** on the **v2** major tag. Anyone who tells you otherwise is remembering, not checking. |

---

## 10. Pitfalls

| # | Pitfall | Mitigation |
|---|---|---|
| 1 | **A tutorial-pasted `<uses-permission android:name="android.permission.INTERNET"/>` in `android/app/src/main/AndroidManifest.xml`.** It is the single most common line in Flutter Android manifests and it silently voids the app's central claim. | It does not belong there. Flutter puts it in `src/debug` and `src/profile` only. CI job asserts against the built AAB (§7.2). |
| 2 | **A transitive dependency merges INTERNET in month six.** Manifest merger blends library permissions in without a warning. | The same CI assertion, and read `build/app/outputs/logs/manifest-merger-release-report.txt` when it fires. `tools:node="remove"` with `tools:selector` as a last resort. |
| 3 | **Missing the 3-day acknowledgement window** because the user's phone dropped off the network right after paying. Google auto-refunds and revokes. | `completePurchase()` on every `purchased`/`restored`/`error` where `pendingCompletePurchase` is true. Plus the `purchase_in_flight_at` flag that re-drains the stream on the next launch (§2.3). |
| 4 | **Acknowledging a `PENDING` purchase.** Google: "don't acknowledge it while a purchase is in PENDING state." | The `switch` in §2.3 has an explicit `pending` arm that does nothing. |
| 5 | **`PurchaseStatus.restored` reported for a fresh purchase on iOS**, leaving it unfinished. Real regression: `in_app_purchase_storekit` 0.4.3 / `in_app_purchase` 3.2.3 ([flutter#172434](https://github.com/flutter/flutter/issues/172434)), fixed in **0.4.8**: *"Fixes an issue causing StoreKit2 purchases to be reported as `restored` and left in an unfinished state, due to `pendingCompletePurchase` being false."* | Pin `in_app_purchase_storekit` ≥ 0.4.8 (current 0.4.11). Treat `purchased` and `restored` identically in the handler — which the §2.3 code does — so the class of bug cannot cost an unlock. |
| 6 | **Restore fails on a new device with no signal and the user thinks they lost their purchase.** Apple's DTS confirms the entitlement cache needs the network at least once; the underlying `-1009` is not cleanly catchable. | Honest copy (§2.5). Restore button above Buy. Never re-lock existing data. Never apply the cap retroactively. |
| 7 | **The cap fires at 03:20 during create-on-the-fly.** Catastrophic; kills the app's one promise. | `EntryContext.liveEntry` can only ever return `Allow`. Enforce with a unit test asserting `canCreateEwe(context: liveEntry)` never returns `BlockedByCap`, for any input. |
| 8 | **Monetization UI leaks onto a shed screen.** | Widget test: pump Quick Entry, Lambing Entry, Lamb Card, Foster and Pen Board with `unlocked: false, ewesInCurrentSeason: 99`; assert `find.byType(UpgradeRow)` is `findsNothing`. |
| 9 | **The entitlement rides along in the JSON backup**, turning the backup file into a licence key and unlocking anyone who imports a friend's file. | Export writer skips the `entitlement` table; import reader ignores it. Test both directions. |
| 10 | **`ITMS-91053: Missing API declaration`** on first submission. | Ship `PrivacyInfo.xcprivacy` (§4.2) *added to the Runner target's Copy Bundle Resources*. Generate the privacy report from the archive before uploading. |
| 11 | **Wrong reason code.** e.g. `0A2A.1` (third-party SDK) or `85F4.1` (display disk space) in an app manifest → `ITMS-91055: Invalid API reason declaration`. | Use the table in §4.2. Cross-check against Apple's page, not against a blog and not against memory — the first automated summary I fetched had four of the codes mapped to the wrong categories. |
| 12 | **SwiftPM migration drops a plugin's privacy manifest.** Flutter 3.44 made SwiftPM the default; resource-bundle packaging differs from CocoaPods. | Re-generate the Xcode privacy report after the migration and after every plugin bump. |
| 13 | **New personal Play account blocked at launch** by the 12-testers-for-14-days rule. | Start closed testing 3–4 weeks before you want production access; recruit the twelve from the forums in spec §3 and get user research out of it. |
| 14 | **Build number collision** on re-upload. Both stores reject a reused `versionCode`/`CFBundleVersion`. | `--build-number=${{ github.run_number }}`. Never hand-edit. |
| 15 | **White flash on launch** (spec §5 violation). Not a Dart bug and no test catches it. | Set the iOS `LaunchScreen.storyboard` background and the Android `windowBackground`/splash to the app's dark surface colour. Manual pre-release check. |
| 16 | **Play Billing 8 → 9 deadline.** Billing 8 is required by 31 Aug 2026; Billing **9** will be required by 31 Aug 2027. `in_app_purchase_android` 0.5.2 ships 8.0.0. | Calendar reminder for Q1 2027. If the first-party plugin lags, that is when `flutter_inapp_purchase` gets reconsidered. |
| 17 | **Store unavailable / de-Googled device.** `isAvailable()` returns false; `queryProductDetails` returns nothing. | Every monetization path must no-op gracefully. The app stays in free tier and stays fully usable. Never show a spinner, never block a screen, never show an error dialog for this. |
| 18 | **Declaring "Data Not Collected" and then adding a crash reporter.** | The privacy label and the Data safety form are versioned artefacts. Add a line to the pre-release checklist: *"Did anything gain a network path this release?"* |

---

## 11. How this serves the 3am test and the offline-only constraint

- **Zero store calls on the launch path.** Cold start reads one SQLite row. The billing client is not even connected until the user opens the Unlock screen (or a purchase is known to be in flight). The 15-second target is untouched by monetization.
- **The cap can never block a save.** `EntryContext.liveEntry` is structurally incapable of returning `BlockedByCap`. The 16th ewe at 03:20 is created, used, and mentioned to the user in daylight.
- **No modal, ever.** Spec §5's "zero interruptions" is enforced by a widget test, not by discipline.
- **Export is never paywalled.** The one safety mechanism in an app with no cloud stays free in every state, including the state where the user never pays and comes back two years later.
- **The offline claim is mechanically enforced, not asserted.** A CI job reads the shipped `.aab` and fails the build if `android.permission.INTERNET` is present. The Play listing's permission line becomes verifiable proof of the §4.5 privacy promise, which no syncing competitor can offer.
- **Write-once entitlement.** No store round-trip can ever re-lock a shepherd mid-season, because the app never asks again.
- **Privacy policy readable in the shed.** Shipped as static text, not a `url_launcher` tap into a browser that has no signal.
- **Release freeze during lambing.** A regression shipped in March costs someone a night of records. The calendar is part of the release process.

---

## 12. Open questions (owner decisions, or need a device)

1. **Confirm empirically that a release AAB built with `in_app_purchase` 3.3.0 / billing 8.0.0 contains no `android.permission.INTERNET`, and that a real purchase completes without it** (license-tester account, airplane-mode-off, sideloaded debug build). This is the load-bearing assumption of the entire monetization design and it needs one afternoon on a real device. Everything else in §1 is documentary evidence.
2. **Cap shape: 15 ewes, one season, or both?** The spec offers both. I recommend season-primary (the calmest possible gate, landing exactly where §7.7 says the value is) with the ewe cap as a secondary calm-UI gate. Owner call.
3. **Exact price and territory.** €10–15 is a range. €11.99 or €12.99 with Apple Small Business Program enrolment; confirm Google's post-June-2026 one-time-product fee for IE/UK/EEA in Play Console before committing.
4. **Does Android tag OCR ship in v1?** Bundled ML Kit costs ~4 MB and is the largest discretionary payload; unbundled is disqualified as a network dependency. iOS Vision is free. An iOS-only OCR shortcut may be the right v1 answer.
5. **Is iOS install size a stated promise anywhere user-facing?** If so, it should be walked back to "bundled content under 5 MB" — the binary is what Flutter costs.
6. **Does the developer account already exist, and is it a personal account created after 13 Nov 2023?** If yes, the 12-tester/14-day closed test is on the critical path and must be scheduled now.
7. **Who are the twelve testers?** This is a recruitment problem, not an engineering one, and it doubles as spec §17 question 1 ("Can we observe one full night in a real lambing shed?").

---

## Sources

Every URL below was fetched during this research.

**Flutter / Dart**
- https://docs.flutter.dev/deployment/android
- https://docs.flutter.dev/deployment/ios
- https://docs.flutter.dev/deployment/flavors
- https://docs.flutter.dev/perf/app-size
- https://docs.flutter.dev/testing/overview
- https://docs.flutter.dev/release/release-notes/release-notes-3.44.0
- https://docs.flutter.dev/release/breaking-changes/uiscenedelegate
- https://dart.dev/tools/analysis
- https://dart.dev/tools/dart-analyze
- https://dart.dev/tools/dart-test
- https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_tools/lib/src/commands/analyze.dart
- https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_tools/lib/src/commands/test.dart
- https://raw.githubusercontent.com/flutter/flutter/master/engine/src/flutter/shell/platform/darwin/ios/framework/PrivacyInfo.xcprivacy
- https://raw.githubusercontent.com/flutter/packages/main/packages/flutter_lints/lib/flutter.yaml
- https://raw.githubusercontent.com/flutter/packages/main/packages/in_app_purchase/in_app_purchase_android/android/src/main/AndroidManifest.xml
- https://raw.githubusercontent.com/flutter/packages/main/packages/in_app_purchase/in_app_purchase_android/android/build.gradle.kts
- https://raw.githubusercontent.com/flutter/packages/main/packages/in_app_purchase/in_app_purchase/example/lib/main.dart
- https://github.com/flutter/flutter/issues/172434
- https://github.com/flutter/flutter/issues/20789

**pub.dev**
- https://pub.dev/packages/in_app_purchase
- https://pub.dev/packages/in_app_purchase/changelog
- https://pub.dev/packages/in_app_purchase_android
- https://pub.dev/packages/in_app_purchase_android/changelog
- https://pub.dev/packages/in_app_purchase_storekit
- https://pub.dev/packages/in_app_purchase_storekit/changelog
- https://pub.dev/documentation/in_app_purchase/latest/in_app_purchase/InAppPurchase-class.html
- https://pub.dev/packages/purchases_flutter
- https://pub.dev/packages/flutter_inapp_purchase
- https://pub.dev/packages/flutter_local_notifications
- https://pub.dev/packages/share_plus
- https://pub.dev/packages/path_provider
- https://pub.dev/packages/sqlite3_flutter_libs
- https://pub.dev/packages/flutter_lints
- https://pub.dev/packages/very_good_analysis
- https://pub.dev/packages/lints
- https://pub.dev/packages/test
- https://pub.dev/packages/build_runner
- https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_analysis/main/lib/analysis_options.10.3.0.yaml

**Apple**
- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/app-store/app-privacy-details/
- https://developer.apple.com/support/third-party-SDK-requirements/
- https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
- https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons
- https://developer.apple.com/documentation/storekit/transaction/currententitlements
- https://developer.apple.com/documentation/storekit/apptransaction
- https://developer.apple.com/documentation/storekit/testing-at-all-stages-of-development-with-xcode-and-the-sandbox
- https://developer.apple.com/forums/thread/706450
- https://developer.apple.com/app-store/small-business-program/
- https://developer.apple.com/news/upcoming-requirements/?id=02032026a
- https://gist.github.com/mironal/9169633fb09c06c2f8f781ebe01644b7 *(secondary mirror, used only to cross-check the reason-code table)*

**Google / Android**
- https://developer.android.com/google/play/billing/integrate
- https://developer.android.com/google/play/billing/errors
- https://developer.android.com/google/play/billing/release-notes
- https://developer.android.com/google/play/billing/deprecation-faq
- https://developer.android.com/google/play/billing/test
- https://developer.android.com/build/manage-manifests
- https://developer.android.com/google/play/requirements/target-sdk
- https://developers.google.com/ml-kit/tips/installation-paths
- https://android-developers.googleblog.com/2026/06/play-expanded-billing.html
- https://support.google.com/googleplay/android-developer/answer/10787469 (Data safety)
- https://support.google.com/googleplay/android-developer/answer/11926878 (target API level)
- https://support.google.com/googleplay/android-developer/answer/13327111 (account deletion)
- https://support.google.com/googleplay/android-developer/answer/14151465 (12 testers / 14 days)
- https://support.google.com/googleplay/android-developer/answer/9842756 (Play App Signing)
- https://support.google.com/googleplay/android-developer/answer/6062777 (license testing)
- https://github.com/dandar3/android-google-play-billing/blob/master/AndroidManifest.xml *(mirrored AAR manifest, billing 2.0.3 — used as architectural evidence only)*
- https://stuff.mit.edu/afs/sipb/project/android/docs/google/play/billing/billing_integrate.html *(archived Google IAB v3 guide — IPC architecture)*

**CI / GitHub**
- https://docs.github.com/en/billing/managing-billing-for-your-products/about-billing-for-github-actions
- https://github.com/subosito/flutter-action
- https://api.github.com/repos/subosito/flutter-action/releases
- https://api.github.com/repos/actions/checkout/releases
- https://api.github.com/repos/actions/cache/releases
- https://api.github.com/repos/actions/upload-artifact/releases

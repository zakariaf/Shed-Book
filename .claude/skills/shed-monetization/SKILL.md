---
name: shed-monetization
description: >-
  The one non-consumable unlock. Use for price, purchase, restoring purchases, entitlement, unlock
  or the cap. Do NOT use for how it is drawn (indelible-states-and-feedback).
---

# The one unlock

> The store is the source of a **one-time fact**, not a runtime dependency. Ask it exactly twice — when
> the user taps Unlock, and when the user taps Restore. Write the answer to SQLite. Never ask again.
> (`11-monetization-and-store.md` §1.2)

Every rule below follows from that sentence. Authorities, in order: `docs/engineering/CONVENTIONS.md`
§2.10, §5.1, §5.4, R69, R74; then `docs/engineering/11-monetization-and-store.md`; versions only from
`docs/research/00-tech-decisions.md` §5.1. They are BINDING and outrank this skill. Read **11 §9** before
touching a privacy declaration, **11 §12.2** before writing a monetization test.

**Do NOT use this skill for:** how the upgrade row, the cap row or the unlocked section is *drawn* —
**indelible-states-and-feedback** owns `ShedBanner`, `showCapRow` rendering and every visual state. Routes,
`RouteNames`, `Routes.settings(context, focusUnlock: true)` — **shed-screens-and-routing**. Nothing
monetization-related renders on the five shed screens (Quick Entry, Lambing Entry, Lamb Card, Foster, Pen
Board) at **any** entitlement state, held by `test/features/no_monetization_test.dart`.

**Vocabulary (CONVENTIONS §5.1):** **unlock**, **the free tier**, **the cap** — never purchase, buy,
subscribe, trial, freemium, paywall. One exception: the button label **"Restore purchases"**, because App
Review 3.1.1 reviewers scan for that string.

## The model

Free app, **one non-consumable IAP**, one binary, one bundle id, product id `shed_book_unlock` frozen at the
first sale and byte-identical in both consoles. No subscription, no second SKU, no flavors, no tier-0 trial
item, no `purchases_flutter`/RevenueCat (a network path that forces a Play "Purchase history collected"
declaration), no server-side receipt validation. Plugin versions, including the
`in_app_purchase_storekit` floor that exists to avoid a StoreKit 2 regression, are in 11 §1.1 and
decision-record §5.1 — read them there and never pin from memory.

## The entitlement row and its three rules

One singleton row, four columns (`03-data-model-and-schema.md` §5.13), seeded by `seedFirstRun` in
`onCreate`, so no code path handles "no entitlement row". `unlocked_at` and `purchase_in_flight_at` are
machine facts, carry no §12.5 provenance quad and render **nowhere** — the unlocked section reads one word,
"Unlocked."

1. **Write-once, never revoked** — not even after a refund, because detecting one means polling the store on
   the launch path. Enforced by `db.entitlement_revoke`.
2. **Excluded from the backup, ignored on import** — otherwise the backup file is a licence key and your
   neighbour's file unlocks your app.
3. **Never in `shared_preferences`** — a second truth that disagrees after a restore, and trivially editable.

`EntitlementRepository.markUnlocked({required bool restored})` is the **only** writer of `unlocked`, and it
clears `ewes.over_free_cap` and `seasons.over_free_cap` in the *same* transaction — the one documented
exception to CONVENTIONS §2.13 table ownership, stated in the method's doc comment. `LocalLog.instance.record`
runs **outside** it (a failed diagnostics line must never roll back a paid unlock) and takes an event string
only: never the `purchaseID`, never the price, never a store error. `entitlementProvider` is a keepAlive
`StreamProvider<Entitlement>`; `main()` reads nothing, the first frame is entitlement-agnostic (#90), no shed
screen watches it. The failure prevented is a paywall flash at 3am.

## The seam — `PurchaseService`

`lib/data/purchase_service.dart` (R74) is the **only** file permitted to import `package:in_app_purchase`, and
exactly two things cross it: a `PurchaseSignal` and a `String` price. No `PurchaseDetails`, `ProductDetails`,
`PurchaseStatus`, `PurchaseParam` or `InAppPurchase` in the *type* of anything it exposes — one leaked type
forces `entitlement_repository.dart` or `unlock_controller.dart` to import the plugin to name its own
callback, and `layer.in_app_purchase` becomes a comment CI cannot enforce. That rule's second clause bans
those five tokens everywhere else under `lib/`, which is what makes the first clause hold. `kUnlockProductId`,
`PurchaseSignal` and `StoreUnreachable` live in that file and nowhere else.

- **`StoreUnreachable` is not a `ShedFailure`** and never renders through `showFailure()`. A shed with no
  signal is the normal case, not a fault; logging it as one poisons the diagnostics log. Never add a
  `StoreUnavailable` variant.
- Every store call is **bounded at ten seconds** → `UnlockUnavailable(storeUnreachable)`. No retry loop, no
  timer, no back-off, no background attempt: the retry is the user tapping again.
- The billing client initialises **only** on Settings ▸ Unlock, or on boot when `purchase_in_flight_at` is set
  **and** `unlocked = 0` **and** the flag is under 14 days old. Never on the launch path (`launch.store_call`).
- `UnlockState` has four variants and `pending` is not one (CONVENTIONS §5.3 bans it as a model state):
  `UnlockOffered`, `UnlockContactingStore`, `UnlockAwaitingPayment`, `UnlockUnavailable`. `unlockControllerProvider
  = NotifierProvider.autoDispose<UnlockController, UnlockState>(UnlockController.new)` over an
  `AutoDisposeNotifier` — the Riverpod **2.6.1** spelling; no bare `Notifier` with `.autoDispose`, no `Mutation`.
- **Restore sits above Unlock**, always, so the double-charge fear never forms; both ≥ 60 pt. Both begin
  `if (state is UnlockContactingStore) return;` — cold fingers double-fire and a double-fired Unlock opens two
  checkout sheets. Not via `WriteController`: a purchase returns no `WriteOutcome`.

## The free-tier policy

`lib/domain/free_tier.dart` — pure Dart: no flutter, no drift, no riverpod, no `package:clock`. Members and
`FreeTierPolicy.decide`'s signature are fixed by **CONVENTIONS §2.10 / R69**; the body is 11 §7.2.
`kFreeEweCap = 15` and `kFreeSeasonCount = 1` are `const`s, not constructor parameters — an injectable cap lets
a test lower it to 3 and hide an off-by-one production then ships.

**`EntryContext.liveEntry` is structurally incapable of returning `BlockedByCap`.** Not a convention, not a
review rule — the function cannot reach that return on that path, which makes "the cap never fires at 03:20" a
property rather than a promise. `isQuietHours` (22:00–06:00 local) is the same kind of early `Allow` and is the
**only** definition of that window in the codebase, so the policy and both rows cannot disagree. Season-primary:
if both are over, the reason is `secondSeason`.

`decide` is called from exactly two verbs — `FlockRepository.createEwe` and `SeasonRepository.startSeason` —
with `EntryContext` explicit, **post-write** counts, inside the insert's transaction so the count cannot move;
`BlockedByCap(reason)` → `WriteRefused(reason)`. The cap is **not** a schema `CHECK` (it would fire on a paying
user mid-lambing, indistinguishable from corruption) and **not** a UI check (one refactor from bypassed).
`beginLambing` and `addLamb` are never gated, at any entitlement state.

## The four hard constraints on the upgrade affordance

1. **Never mid-entry.** Ewe #16 at 03:20 succeeds silently with `over_free_cap = 1`.
2. **Never 22:00–06:00** — the Settings row goes quiet as well as the Flock one (`06-design-system.md` §12
   constraint 3 is wider than `07-screens.md` §19.3 and is the one that ships). The window suppresses
   **soliciting**, not **selling**: Settings ▸ Unlock still works at 23:00 for someone who walks to it. The
   proving test **sets the clock, not the entitlement**.
3. **Never a modal** — no interstitial, no takeover, no self-appearing sheet, on launch or the Nth save or the
   16th ewe. `ui.show_dialog` already fails the build outside two destructive files.
4. **Never more than once a day.** Self-navigation after a `WriteRefused` fires at most once per local civil day
   via `app_settings.last_unlock_prompted_at`, compared as `LocalDate.of(appNow()) != LocalDate.of(lastPrompted)`.
   A user-initiated tap on a row is not a prompt and is never rate-limited.

Never gated, in any state: export (spec §7.9 calls it a safety feature; paywalling the only backup is data
ransom), withdrawal periods, clear dates, the medicine book, and creating a ewe during Quick Entry, Lambing
Entry or Foster. On not paying, nothing is deleted, hidden, greyed, blurred or made read-only — ever.

## Store compliance for an app that collects nothing

Apple answers **No** to all fourteen categories → **Data Not Collected**; Play is **"No data collected or
shared"**, because Google's payment-service exemption covers Play billing (a second reason RevenueCat is
rejected). `ios/Runner/PrivacyInfo.xcprivacy` ships `C617.1` + `E174.1` **only**: not `CA92.1` (no
`shared_preferences`, per rule 3 — this supersedes decision #93 and `08-platform-integration.md` §11), and never
`0A2A.1`/`C56D.1`, which are SDK-only and the shape of `ITMS-91055`. It must sit in the Runner target's Copy
Bundle Resources or it ships nothing and the build still succeeds. A hosted privacy-policy URL is mandatory on
both stores; the in-app half is static Dart strings on Settings ▸ About, avoiding `url_launcher`. No account, so
no Sign in with Apple, no deletion screen, no deletion URL — adding one "for parity" creates the account model
the app does not have. `85F4.1` is unresolved in 11 §9.2; close it there before the first submission.

## Gotchas

- **The price is never a literal** — `ProductDetails.price`, always (CONVENTIONS §5.4);
  `copy.currency_literal` fails the build on a currency symbol followed by a digit under `lib/` or `assets/`.
  The rows render **without** a price until the store answers in this process (the sentence ends after "Unlock
  once") and it is **never persisted**: a stale price is the same dishonesty as a stale clear date.
- **A calm gate inside the quiet window is forgiven permanently, not deferred.** A second season started at
  22:30 is kept, free, forever (rule 1 never revokes). Do not "fix" it by deferring the refusal to morning — a
  refusal detached from the tap that caused it is worse than none.
- **A restored multi-season backup closes both calm gates with `secondSeason`.** The cap constrains the *next*
  write, never existing rows; every restored ewe stays readable, editable and exportable.
- `completePurchase` runs for **every** non-`pending` update whose `pendingCompletePurchase` is set,
  **regardless of product id** — an unrecognised id left uncompleted is redelivered forever. Never complete a
  `pending` one. **Acknowledge first, write the row second:** that gap is one process death wide and yields
  "paid, acknowledged, still locked", which Restore repairs, whereas the reverse yields an auto-refund in three
  days that nothing repairs.
- `purchased` and `restored` run **identical** code — that is what makes the historical
  `in_app_purchase_storekit` regression (StoreKit 2 purchases reported as `restored`, 11 §1.1)
  incapable of costing an unlock.
- `over_free_cap` is bookkeeping, not a `Warning`: no `WarningCode`, no badge, no colour, never in the §12.4
  contradiction machinery. Absent from every CSV and PDF, present in the JSON backup. **Nothing reads it when
  `unlocked = 1`**, which is why stale markers on a restored file are harmless — never rewrite a user's rows to
  tidy up bookkeeping.
- `ui.monetization_surface` allows `ShedBanner` in `lib/features/quick_entry/` on purpose: the same component
  carries the end-of-day export prompt. `showCapRow(` is the half that guards monetization and is exact.
- The one thing this app cannot do offline is **prove a purchase it has never seen**; say so plainly. Offline
  wording is fixed by decision record §3 and monetization amends not a word of it: during a purchase, bytes move
  on the device's behalf **in someone else's process**, which is a different sentence from "the app connects".
  Never write "your data never leaves your phone".

## Banned outright

A subscription · a second SKU or bundle id · flavors · `purchases_flutter` · `shared_preferences` ·
`StoreGateway`, `BillingService`, `IapGateway`, `PurchaseRepository`, `paywallProvider`, `UpgradeRow` (R74; the
component is `ShedBanner`) · an `unlock` route (`RouteNames` is thirteen) · a `product_id`/`purchase_id`/`store`
column on the entitlement row · a spinner (`ui.spinner`) · a snackbar, haptic or red for a store failure · a
`Timer.periodic` retry · reading the entitlement in `main()` · a currency literal · any monetization surface on
tag OCR or voice tag entry (both cut from v1).

## Definition of done

- [ ] `package:in_app_purchase` and all five plugin type names appear in exactly one file; `layer.in_app_purchase` and `launch.store_call` are green.
- [ ] `PurchaseService.updates` is a `Stream<PurchaseSignal>`, the price crosses as a `String`, and neither `EntitlementRepository` nor `UnlockController` imports the plugin.
- [ ] `unlocked` is written in `markUnlocked` alone, never `false` after `onCreate`, and both `over_free_cap` columns clear in that transaction; `db.entitlement_revoke` is green.
- [ ] The entitlement is absent from the JSON backup and ignored on import; `unlocked_at` and `purchase_in_flight_at` render nowhere.
- [ ] The grid test proves `liveEntry` never returns `BlockedByCap`; the quiet-window test sets the clock, not the entitlement.
- [ ] `decide` is called only from `createEwe` and `startSeason`, post-write counts, inside the insert's transaction; `isQuietHours` is the codebase's only 22:00–06:00 definition.
- [ ] The five shed screens hold no `ShedBanner` at `unlocked: false, ewesInCurrentSeason: 99`, and the Flock row is absent at 23:30.
- [ ] Every store call is bounded at ten seconds, a double tap starts exactly one, and a store failure produces no dialog, spinner, haptic or snackbar.
- [ ] `grep` finds no currency literal, no persisted price, no `shared_preferences` and no banned seam spelling.
- [ ] `PrivacyInfo.xcprivacy` ships `C617.1` + `E174.1` only, sits in Copy Bundle Resources, and 11 §9's checklist has been walked before submission.

# Play Console — the Data safety form, answered

> **Companion to [`offline-honesty.md`](offline-honesty.md)**, which is the single authored source of
> every public sentence about the offline claim. This file is the same discipline applied to a form:
> the answers are **recorded so they can be re-checked**, rather than remembered by whoever fills it in
> next. Decisions applied: **#93** (store privacy declarations, as amended by N30-T07) · §3.1 (the
> permitted wording) · **#88** (the entitlement is never exported).

Play's form is re-answered on **every** submission and its answers are shown to a shepherd in the
listing. An answer that drifts from the app is worse than a missing one: it is a claim, in public,
that somebody can check.

---

## The four answers

| Question | Answer | Why, and what would change it |
|---|---|---|
| Does your app collect or share any of the required user data types? | **No** | There is no network code and no analytics. The Android build ships without `INTERNET` — removed by `tools:node="remove"`, because Play Billing's telemetry transport merges it in on a transitive edge. Adding any dependency that can reach a network changes this answer before it changes anything else. |
| Is all of the user data collected by your app encrypted in transit? | **Not applicable** — no data is collected | The form only asks once the first answer is *yes*. |
| Do you provide a way for users to request that their data is deleted? | **Not applicable** — no data leaves the device | Settings holds the only two deletes in the product, and they act on the phone. |
| Does your app allow users to create an account? | **No** | There is no account, no sign-in and no identifier. This is the same sentence §3.1 permits, in Play's own words. |

## The payment exemption, quoted rather than paraphrased

Play's Data safety guidance exempts data handled entirely by the payment processor:

> "Data that is collected and processed *ephemerally*… and data that your app sends to a payment
> processor to complete a transaction, where your app does not access it, does not need to be declared."

The unlock is a single non-consumable bought through Google Play Billing. **The app never sees a card
number, a billing address or an account identifier** — `PurchaseService`'s whole outward surface is
five `PurchaseSignal` members and one price `String`, and `entitlements` stores four columns of which
none records who paid or how (`11 §4.1`).

## The rest of the form

- **Privacy policy URL** — mandatory on both stores, and the same URL goes in App Store Connect. The
  full text also ships as static Dart strings so Apple 5.1.1(i)'s in-app requirement is met **without
  `url_launcher`**, which is not in decision-record §5.1 and would be a network-shaped dependency in
  an app whose central claim is that it makes no network calls.
- **`targetSdk`** — **36**, pinned explicitly in `android/app/build.gradle.kts` at N31-T02 rather than
  inherited from the toolchain.
- **Account deletion URL** — not required, because there is no account to delete.

## What must be re-checked before each submission

1. **`android/expected_permissions.txt` still matches the built `.aab`** — gate G1 asserts it on every
   Android CI run, and the answer above depends on `INTERNET` being absent.
2. **No dependency has been added that can reach a network.** G2 (the allowlist) and G3 (the import
   scan) hold this in CI; a new dependency is a decision-record §5 change and this file is one of the
   things it must update.
3. **The `g5_observation` row in `docs/calendar.md` has been filled for this release.** No test can
   make the claim these answers rest on: G1 reads a permission set off an artefact and G3 reads
   imports, and **neither watches the app run**.

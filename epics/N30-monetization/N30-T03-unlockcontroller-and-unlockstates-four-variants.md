# N30-T03 — `UnlockController` and `UnlockState`'s four variants

| | |
|---|---|
| **Epic** | [N30 — Monetization](epic.md) · `00-README` §9 step 11 |
| **Task** | 3 of 8 |
| **Depends on** | N30-T02 |
| **Commit** | one commit · `feat(monetization): UnlockController and its four states` |

## 1. Why this task exists

Purchase, restore, double taps — and **why `pending` is not one of the variants**: `pending`
is a banned model state (`CLAUDE.md`), and a purchase that is in flight is represented by the controller
being busy, not by a state the UI can render as a spinner nobody can cancel.

The four variants are named for **what the user is waiting on**, not for what the plugin calls it. The
plugin's `PurchaseStatus.pending` covers two genuinely different situations — an Android slow payment
instrument and Apple's Ask to Buy family hold — and both are the user waiting on **somebody else's
approval**, which is what `UnlockAwaitingPayment` says. A screen that said *"pending"* would be telling
the shepherd nothing and offering them nothing to do.

This screen is also a **ship gate rather than just a screen**: `10 §1.1` lists *unlock / restore
purchase* among the seven common tasks Apple's Accessibility Nutrition Labels require to complete under
every declared feature — including the `UnlockUnavailable` state, whose text is the only thing that
tells a screen-reader user why nothing happened.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/11-monetization-and-store.md` | **§6.2** (`UnlockState`'s four variants printed in full, `UnlockUnavailableReason`, `UnlockController`'s three methods, the Riverpod 2.6.1 provider line, and why a store failure is not a `ShedFailure`) · **§6.3** (the eight-row trigger table and the three-way split of the store update) · **§6.4** (Restore is mandatory, sits above Unlock, and *"Restore purchases"* is the one permitted use of the word) · **§6.5** (the unreachable case: no dialog, no spinner, no snackbar, no haptic, no red, no retry loop, no blocked screen, bounded at ten seconds) · **§6.6** (double taps, and the stated narrow departure from `CONVENTIONS §4.4` rule 2) · §6.1 (there is no Unlock route; the surface is Settings ▸ Unlock) · §5 (the seam this controller listens to) | the whole file |
| `docs/engineering/CONVENTIONS.md` | §1 (`lib/features/settings/unlock_controller.dart`) · §1.1 layer rules **5, 6** (a sibling feature import is a layer violation) · §2.4 (`WriteOutcome` — and why a purchase does not return one) · §3.4 (`unlockControllerProvider` joins the declared controller list) · §4.2 (`<Screen>Controller` / `<Screen>State`) · §4.4 (controllers hold screen state, never data; no `BuildContext`, no navigation, no formatting, no drift import) · §4.5 + R59 (widget keys) · **§5.1** (*unlock*, never *purchase* — and the single exception) · **§5.3** (`pending` is banned, absolutely) · R30 (`showFailure` is for `ShedFailure` and this is not one) | the names, the layer and the vocabulary |
| `docs/research/00-tech-decisions.md` | §2 **#17/#18/#19** (`flutter_riverpod` **2.6.1** spellings and the Riverpod-3 ban list) · **#71** (never a spinner) · #22 (the double-tap defence) · #88 (Restore above Unlock) · #89 (the in-flight flag) · #90 · #103 (commit-then-confirm, never optimistic UI) · #123/#124 (no telemetry; the redaction list) · §5.1 for versions | the API spellings and the no-spinner rule |
| `docs/engineering/02-state-di-navigation.md` | §5 (provider scope and override rules) · §6 (controller conventions) · §8.1 (`RouteNames` has **thirteen** entries and none is `unlock`) | the provider and the absence of a route |
| `docs/engineering/07-screens.md` | §14.2 (Settings' over-cap state) · **§14.3 row 9** (*"Unlock — Restore purchases sits above Unlock"*) · §14.4 (tap costs) · §20 (bottom-third primaries) | where this controller's state is rendered |
| `docs/engineering/10-accessibility-and-i18n.md` | **§1.1** (the seven common tasks) · §3.2 (label rules) · §3.4 (`headingLevel:` only; `header:` is a no-op on 3.44) · §4 (200% text, never clamp) · §8.4 (ARB house rules: every message has a `description`) | why the four states each need announced text |
| `docs/engineering/06-design-system.md` | §12 (the inventory: **no loading state anywhere**, decision #71) · §10.1 (the four haptic patterns, and which channel has none) · §10.3 (what P2 removed from `feedback.dart`) | the disabled-button-with-a-changed-label rendering |
| `docs/engineering/12-testing.md` | §5.1 (`pumpApp`, `shedContainer`) · §4.2 (`FakePurchaseService` drives `updates`) · §10.1 (tap budgets) · §4.5 (*"overriding a screen controller"* is an anti-pattern — a fake controller tests the fake) | the tier, and what may be overridden |
| `epics/00-PLAN-CRITIQUE.md` | §11.4 (N30's skills) | the skills table |
| `shed-book-spec.md` | §14 | one-time unlock, no subscription, a cap that must not degrade 3am |
| `CLAUDE.md` | the banned words · **P2** · the 3am floor | `pending`, the SnackBar, 64 × 64 |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-monetization` | the unlock flow, its states and its restore path |
| `shed-riverpod-providers` | the 2.6.1 spellings, the controller's shape and the double-tap defence |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/unlock_test.dart`
- **Test** — `'a double tap on unlock produces one purchase attempt and no pending state exists'`
- **Why it is red today** — nothing drives the purchase, and the obvious implementation has a `pending` state.

```bash
fvm flutter test test/features/unlock_test.dart   # expect: failing, for the reason above
```

Sharpen both halves so neither can pass for the other's reason. For the double tap, assert on
`FakePurchaseService.calls` — `expect(fake.calls.where((c) => c == 'buyUnlock').length, 1)` after
`tester.tap(); tester.tap();` with no `pump` between them, because a `pump` between two taps is not a
double tap and passes trivially. For the absent state, assert on the **type set**:
`UnlockState`'s subtypes are exactly the four in §5.2, and no identifier under
`lib/features/settings/` matches `/\bpending\b/` case-insensitively.

**Green.** The minimum code that passes, and nothing beyond it — the controller through `guard()`, four variants, no `pending`.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema, no domain, no data step.** Nothing here stores anything or computes anything — say so in
the commit message. This is §8 step 5 (controllers) and step 22 (the ARB), plus its tests.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/features/settings/unlock_controller.dart` | **New.** `sealed class UnlockState` with its four variants, `enum UnlockUnavailableReason`, `final class UnlockController extends AutoDisposeNotifier<UnlockState>`, and `unlockControllerProvider`. One file, because `CONVENTIONS §4.1` puts a small write controller in the screen controller's file rather than inventing a second |
| 2 | `lib/l10n/app_en.arb` | **Edit.** Every string this controller's states put on screen, each with a `description`: the four `UnlockUnavailableReason` lines, the contacting-store button label, the awaiting-payment line, and the unlocked section's one word. **No domain noun as a literal** — if a message names the animal, the term comes from `terminologyProvider` as a placeholder (`10 §8.5`) |
| 3 | `test/features/unlock_test.dart` | **New.** The anchor and the cases in §5.4 |
| 4 | `test/features/tap_budget_test.dart` | **Edit.** `11 §6.6`: *"gains one `tester.tap(); tester.tap();` case per button"* — one for Unlock, one for Restore purchases |

**Not touched:** `lib/routing/routes.dart` (there is **no Unlock route**; `RouteNames` has thirteen
entries and `Routes.settings(context, focusUnlock: true)` landed in N29-T01),
`lib/features/settings/settings_screen.dart` (the section's pixels are **T05**'s), `lib/core/ui/` (the
components exist; if this task wants a new one, that is a 06 conversation).

### 5.2 The signatures

`11 §6.2` prints these and the comments on them are load-bearing. Type them as written.

```dart
// lib/features/settings/unlock_controller.dart
sealed class UnlockState { const UnlockState(); }

/// The resting state. `price` is non-null only if the store answered in THIS
/// process. It is never persisted: a stored price goes stale, and a stale price
/// in front of a user is the same class of dishonesty as a stale clear date
/// shown as current.
final class UnlockOffered extends UnlockState {
  const UnlockOffered({this.price});
  final String? price;   // the store's own localised, currency-formatted string
}

/// A bounded store call is in flight. NO SPINNER: `ui.spinner` bans
/// CircularProgressIndicator under lib/features/. The Unlock button's label
/// swaps to "Contacting the store…" and the button is disabled.
final class UnlockContactingStore extends UnlockState { const UnlockContactingStore(); }

/// Android slow payment instruments (cash, bank transfer) and Apple's Ask to Buy
/// family-approval hold. Do not unlock, do not complete, keep
/// purchase_in_flight_at set.
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

  Future<void> openSection();   // attach() → isAvailable() + queryUnlockPrice() → listen(updates)
  Future<void> unlock();
  Future<void> restore();
}

final unlockControllerProvider =
    NotifierProvider.autoDispose<UnlockController, UnlockState>(UnlockController.new);
```

The eight-row trigger table is `11 §6.3` and it is the specification, not an illustration:

| Trigger | Store call | `UnlockState` becomes | Row write |
|---|---|---|---|
| Section opens | `attach()`, `isAvailable()`, `queryUnlockPrice()` | `UnlockContactingStore` → `UnlockOffered(price: …)` | — |
| …store unreachable or timed out (`StoreUnreachable`) | — | `UnlockUnavailable(storeUnreachable)` | — |
| …`isAvailable()` false, or `queryUnlockPrice()` returned null | — | `UnlockUnavailable(productNotFound)` | — |
| Tap **Unlock** | `beginPurchase()` then `buyUnlock()` | `UnlockContactingStore` | `purchase_in_flight_at = appNow()` |
| Tap **Unlock**, `buyUnlock()` returns false | — | `UnlockUnavailable(productNotFound)`; `abandonPurchase()` | flag cleared |
| Tap **Restore purchases** | `restore()` | `UnlockContactingStore` | — |
| Boot, flag set, `unlocked = 0`, ≤ 14 days | `attach()` only | not mounted | — |
| Boot, flag set, `unlocked = 0`, > 14 days | none | not mounted | `abandonPurchase()` |

And the three signals this controller reacts to, out of five:

| `PurchaseSignal` | `UnlockState` becomes | Why |
|---|---|---|
| `awaitingPayment` | `UnlockAwaitingPayment` | Nobody else can tell the user this |
| `cancelled` | `UnlockOffered(price: …)`; `abandonPurchase()` | Back to rest, price kept |
| `failed` | `UnlockUnavailable(storeError)`; `abandonPurchase()` | The row is **untouched** — never downgraded |
| `purchased` | **ignored** | The section re-renders from `entitlementProvider` |
| `restored` | **ignored** | Ditto |

### 5.3 The details that are easy to get wrong

- **`pending` is banned and the ban is a gate row, not a preference.** `copy.banned_word` scans `lib/`
  for it. `PurchaseStatus.pending` lives inside `purchase_service.dart` and crosses the seam as
  `PurchaseSignal.awaitingPayment`; here it becomes `UnlockAwaitingPayment`. A `bool _pending` field, a
  `case pending:`, or a comment that says *"the pending state"* all redden the build.
- **This controller does not go through `WriteController`, and the departure is stated.** A purchase
  does not return a `WriteOutcome` and its result arrives on a stream minutes later, so `guard()`'s
  contract does not fit (`11 §6.6`, a narrow documented departure from `CONVENTIONS §4.4` rule 2). What
  it **does** do is make the same refusal in the same shape: `unlock()` and `restore()` both begin
  `if (state is UnlockContactingStore) return;`. The entitlement row write it eventually causes is
  still made by a repository, so the single-writer rule is intact. Say all of that in a doc comment;
  an undocumented departure reads as an oversight.
- **`AutoDisposeNotifier`, never bare `Notifier` with `.autoDispose`.** The 2.6.1 spelling is
  `NotifierProvider.autoDispose<UnlockController, UnlockState>(UnlockController.new)` — zero-argument
  constructor tear-off, no `Mutation`, no `ProviderScope.retry`, no `AsyncValue.valueOrNull`, no
  `ProviderContainer.test()`, no `WidgetTester.container`. Every one of those is Riverpod 3 and a
  compile error here (decisions #17/#18/#19), which is the good outcome.
- **`UnlockState` holds screen state and never data** (`CONVENTIONS §4.4` rule 1). The truth about
  entitlement comes from `entitlementProvider`, and the section renders the **product of the two**:
  `unlocked = 1` → one word, *"Unlocked."*; otherwise the two buttons plus whatever `UnlockState` says.
  Putting a `bool unlocked` on `UnlockState` gives you two sources of truth that disagree for one frame
  after a purchase, and that frame is the one the user is staring at.
- **A store failure is not a `ShedFailure`, and there must never be a `StoreUnavailable` variant on
  it.** The six variants are storage failures with six `userMessage` strings; they render through
  `showFailure` with an error haptic and they are the vocabulary of the Diagnostics screen. A shed with
  no signal is the normal case, and logging it as a fault poisons the diagnostics log with a hundred
  non-events. So: **no `showFailure`, no error haptic, no red, no `LocalLog` error line.**
- **No spinner.** `ui.spinner` bans `CircularProgressIndicator` under `lib/features/` and decision #71
  says *"never a spinner"* outright. `UnlockContactingStore` renders as a **disabled button with a
  changed label**. A ten-second indeterminate spinner nobody can cancel is the exact thing this design
  refuses.
- **No dialog.** `ui.show_dialog` allowlists exactly two files — delete-season and
  restore-from-backup — and this is not one of them. There is no modal path to a purchase.
- **No snackbar, and no material banner either.** P2 removed both, including from `feedback.dart`. The
  state renders in the section, in ink.
- **Not even the plugin's type *name* may be written in this file.** `layer.in_app_purchase` scans for
  the token, so a doc comment reading *"from `ProductDetails.price`"* reddens the build. Say *"the
  store's own localised string, arriving through `PurchaseService.queryUnlockPrice()`"* instead — which
  is `11 §6.2`'s own wording, written that way for this reason.
- **Restore sits above Unlock, always.** App Review **3.1.1** and a routine rejection cause: reviewers
  look for a visibly labelled restore control on the same screen as the buy button. It also removes the
  double-charge fear before it forms — and both stores handle the already-owned case anyway (Play
  returns `ITEM_ALREADY_OWNED`, StoreKit resolves it as a restore), so nobody is charged twice.
- **"Restore purchases" is the one permitted use of the word *purchase* in user-facing copy.**
  `CONVENTIONS §5.1` says *unlock*, never *purchase*; the exception exists because the string is a
  store-review artefact a reviewer scans for visually. Every other sentence says unlock — including the
  unreachable line: *"Restoring your unlock needs a connection to the store, once. Everything else in
  Shed Book works with no signal."*
- **Every one of the four states needs announced text, not just a visual.** `10 §1.1` makes unlock /
  restore one of the seven common tasks, so the section must complete end to end under VoiceOver, Voice
  Control, Larger Text at 200% and Differentiate Without Colour Alone — **including
  `UnlockUnavailable`**, where the text is the only thing that tells a screen-reader user why nothing
  happened. A state whose only rendering is a greyed button is that user hearing silence.
- **`openSection()` is where the billing client gets initialised, and that is deliberate.** It calls
  `PurchaseService.attach()`, and on Android subscribing to `purchaseStream` *is* the initialisation.
  It must never be called from `build()` of anything reachable from a shed screen, and there is no
  route to this section from one.
- **`ref.onDispose(() => _sub?.cancel())` goes in `build()`, not in a `dispose()` override.** The
  notifier has no `dispose()`; a subscription that outlives the autoDispose is a listener writing to a
  disposed notifier the next time the store answers.
- **No retry loop, no timer, no back-off, no background attempt.** The retry is the user tapping the
  button again (`11 §6.5`). A `Timer.periodic` here is decision #7's rejected `offline-first` pattern
  arriving by the back door.
- **A de-Googled device, a signed-out Play account and an App Store outage all land in
  `UnlockUnavailable` and all of them are correct.** None of them is a bug report.

### 5.4 The full test set

| File | Case | What it holds |
|---|---|---|
| `test/features/unlock_test.dart` | **anchor** — `'a double tap on unlock produces one purchase attempt and no pending state exists'` | Both halves of §4 |
| | `'opening the section moves through UnlockContactingStore to UnlockOffered'` | Row 1 of the trigger table |
| | `'a store that times out lands in UnlockUnavailable(storeUnreachable) within the bound'` | Row 2 |
| | `'isAvailable false and a null price both land in UnlockUnavailable(productNotFound)'` | Row 3, and the two paths that reach it |
| | `'tapping Unlock writes purchase_in_flight_at before it calls the store'` | Row 4 — `beginPurchase()` **then** `buyUnlock()`, asserted by order |
| | `'buyUnlock returning false clears the in-flight flag and reports productNotFound'` | Row 5 |
| | `'awaitingPayment renders its own line and neither unlocks nor completes'` | The Ask to Buy / slow-instrument arm |
| | `'a failed signal leaves an existing unlocked = 1 untouched'` | The row is never downgraded |
| | `'a cancelled signal returns to UnlockOffered with the price kept'` | Rest, without a second store call |
| | `'purchased and restored are ignored by the controller and re-render from entitlementProvider'` | The three-way split |
| | `'UnlockUnavailable never calls showFailure and writes no error to LocalLog'` | The not-a-`ShedFailure` rule, asserted rather than assumed |
| | `'no CircularProgressIndicator is constructed in any of the four states'` | `ui.spinner`'s subject, at the widget tier |
| | `'the Restore purchases control is above the Unlock control in the render tree'` | App Review 3.1.1, as geometry rather than as a comment |
| | `'every state announces text under a semantics handle'` | `10 §1.1`'s common task, all four states |
| | `'the four UnlockState subtypes are exactly the documented four'` | A fifth variant fails here before it fails review |
| `test/features/tap_budget_test.dart` | `'a double tap on Restore purchases starts exactly one store call'` | `11 §6.6`'s second case |
| | `'a double tap on Unlock starts exactly one store call'` | Its first |

**No `uk-zone` case, and say why in the file's header comment.** Nothing in this controller reads a
wall clock: the bound is a `Duration`, the in-flight flag is written by the repository, and the quiet
window is **T05**'s. The epic's two ambiguous-hour cases are T02's 14-day bound and T05's window.

**Do not override `unlockControllerProvider` in any of these tests.** `12 §4.5` and `02 §5.4`: override
leaves, never controllers — a fake controller tests the fake. Everything above is driven by
`FakePurchaseService` through `pumpApp`, which is exactly what `12 §5.1`'s `shedContainer` already
wires.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

> **Two more bind here and are worth naming.** **Accessibility and the ARB are authored in this
> commit** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a
> `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them;
> N33 only verifies. And **the 3am floor applies even though this is a daylight screen**: 64 × 64
> targets, 18 px floor, dark only, and none of the banned gestures.

## 7. Definition of Done

- [ ] `'a double tap on unlock produces one purchase attempt and no pending state exists'` passes, and was seen to fail first for the stated reason
- [ ] the word `pending` appears nowhere as a model state
- [ ] a double tap produces one attempt
- [ ] restore-purchases is reachable and works offline-first-tolerant
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

> **Reading line four, which uses a word we ban in our own prose.** *"Offline-first-tolerant"* is not a
> licence to build a cache-over-network pattern — `offline-first` is banned by `CONVENTIONS §5.3`
> precisely because that pattern is decision #7's rejected design. What the line requires is `11 §4.5`'s
> honest behaviour: **Restore purchases is always reachable**, it is bounded at ten seconds, it fails
> calmly into `UnlockUnavailable(storeUnreachable)` with one sentence, the button stays exactly where it
> is, the retry is the user tapping it again, and every other pixel keeps working. Do not put that
> phrase in the commit message.

## 8. Verification

```bash
fvm flutter test test/features/unlock_test.dart
fvm flutter test test/features/tap_budget_test.dart
dart tool/check_policy.dart
grep -rni "\bpending\b" lib/features/settings/           # nothing
grep -rnE "PurchaseDetails|ProductDetails|PurchaseStatus|PurchaseParam|InAppPurchase" lib/features/   # nothing
grep -rn "CircularProgressIndicator\|showDialog(\|showSnackBar(\|showMaterialBanner(" lib/features/settings/   # nothing
git diff --stat -- lib/routing/routes.dart               # nothing — there is no Unlock route
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(monetization): UnlockController and its four states`

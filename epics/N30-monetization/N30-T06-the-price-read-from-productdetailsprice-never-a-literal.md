# N30-T06 — The price read from `ProductDetails.price`, never a literal

| | |
|---|---|
| **Epic** | [N30 — Monetization](epic.md) · `00-README` §9 step 11 |
| **Task** | 6 of 8 |
| **Depends on** | N30-T05 |
| **Commit** | one commit · `feat(monetization): the price from ProductDetails, never a literal` |

## 1. Why this task exists

The price comes from the store, always — never a literal, **including in assets** and
including in the store listing copy the app renders. A hard-coded price is wrong in every territory but
one and is a store-review rejection in several.

There is a genuine collision to resolve, and `11 §6.7` names it: **knowing a price means calling the
store, and the two upgrade rows are always on screen.** In a shed the store never answers. So the rows
must have a correct rendering for *"price unknown"*, and that rendering is not a placeholder, not a
guess, not a cached value and not a spinner — the sentence simply ends after *"Unlock once"*. **In a
shed the price is unknown, and that is the expected rendering**, not a failure state.

The task also lands a gate row that `11 §12.1` believes already exists. See §5.1.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/11-monetization-and-store.md` | **§6.7** (the price is never a literal; the collision with decision #88 and its three-part resolution; *"nothing in `lib/` reformats it"*; never persisted) · §6.2 (`UnlockOffered.price` — non-null only if the store answered in **this** process, and *"not even the plugin's TYPE NAME may be written in this file"*) · §5 (`queryUnlockPrice()` returns `ProductDetails.price` and holds the `ProductDetails` for `buyUnlock()`) · §6.3 (which triggers produce a price) · §6.5 (the unreachable case) · **§10** (pricing, territories and fees — **§7.1 open question 4 is still open; nothing there is settled**) · §12.1 (`copy.currency_literal` under *"rules that already exist"*) | the rule, and the two renderings |
| `docs/engineering/CONVENTIONS.md` | **§5.4** (*"The price is never a literal. `ProductDetails.price` from the store, always."*) · **§4.7** (`copy.currency_literal` is listed among *"rows this file adds that no document had as a row"* — a currency symbol followed by a digit under `lib/` or `assets/`) · §1 (`lib/core/ui/formatters.dart` is the only `package:intl` call site in `lib/` outside `lib/data/`) · §1.1 layer rules 5, 7 · §5.1 (*unlock*, and the one *purchase* exception) · §4.1 (a policy test states the **property**, not the file) · R56 (the `[exempt]` allowlist has four lines) | the rule id and the formatter boundary |
| `docs/engineering/07-screens.md` | **§19.2** (`Free version · covers this season · 22 of 15 ewes · Unlock once for <store price>` — *"`<store price>` is `ProductDetails.price` from the store, never a literal"*, and `11 §6.7` requires §19.2 to note **both** forms) | the sentence, and its second form |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.2 (label rules) · §4 (200% text; never clamp; `FittedBox` banned) · §8.4 (ARB house rules — every message a `description`) · §8.7 (what is deliberately not in the ARB) | how a price is announced, and why two messages beat one |
| `docs/research/00-tech-decisions.md` | §2 **#87** (one non-consumable; no second SKU) · #88 (the store is consulted on exactly two user actions) · #92 (two static rows) · #108 (`en_GB`; never an all-numeric date) · **§7.1 open question 4** (the exact price and territory list are the owner's, and still open) · §5.1 for versions | why no number may be written down |
| `epics/N00-decisions-rulings-and-the-calendar/N00-T09-store-accounts-the-small-business-program-price-and-territor.md` | the whole task — the ledger that records the price, and *"`docs/` is out of `copy.currency_literal`'s scope, which is why the price may be written in the ledger and nowhere else"* | the one place a number is allowed |
| `docs/engineering/12-testing.md` | §1.4 (**what is a gate and what is a test** — re-read it before expressing this as a `RegExp` inside a `test()`) · §6 (the overflow matrix) · §5.1 (`pumpApp`) | where the assertion belongs |
| `docs/engineering/06-design-system.md` | §12 (`ShedBanner`) · §4 (tokens) | the row that renders it |
| `epics/00-PLAN-CRITIQUE.md` | §11.4 (N30's skills) · §11.5 | the skills, and N03-T07's inventory assertion |
| `shed-book-spec.md` | **§14** (€10–15, one-time, **no subscription ever**) | the model the copy must not contradict |
| `CLAUDE.md` | the banned words · *"never add a line to `tool/policy_allowlist.txt` … to silence a gate"* | the escape hatch that must not exist |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-monetization` | the price, the territories and the store's authority over both |
| `shed-accessibility-and-copy` | how a price is rendered and announced, and the two ARB forms |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/no_price_literal_test.dart`
- **Test** — `'no currency literal appears anywhere under lib/ or assets/'`
- **Why it is red today** — nothing renders a price, and the first one written would be a literal.

```bash
fvm flutter test test/policy/no_price_literal_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it survives a rename and cannot be quietly defeated. Scan every non-generated
file under **both** `lib/` and `assets/` for a currency symbol immediately followed by a digit — at
minimum `€`, `£`, `$` and `¥`, and the `EUR`/`GBP` ISO codes followed by whitespace and a digit — and
assert **in the same test** that `tool/policy_allowlist.txt` contains no `[exempt]` line naming
`copy.currency_literal`. A rule with an escape hatch is a rule that will be escaped at 23:00 on a
Tuesday, and R56 fixes the `[exempt]` section at four lines on day one.

**Green.** The minimum code that passes, and nothing beyond it — read from `ProductDetails.price`, and a source-and-asset scan for currency literals.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema, no domain, no data step.** The price is never stored and never computed — say so in the
commit message. This is §8 step 5 (the controller), step 6 (UI), step 22 (the ARB), one gate row and
its tests.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `tool/check_policy.dart` | **Edit.** `copy.currency_literal`. **Check the table first** — `11 §12.1` lists it under *"rules that already exist and do this document's work"*, but no task in N01–N29 lands it and `CONVENTIONS §4.7` lists it among *"rows this file adds that no document had as a row"*. If it is absent, it lands here and it is **not** a duplicate. If N03-T05 did ship it, this task adds only the proving case |
| 2 | `test/policy/gate_rules_test.dart` | **Edit.** The planted-violation case. N03-T07's inventory assertion fails the build on a rule id with no case here |
| 3 | `lib/features/settings/unlock_controller.dart` | **Edit.** `openSection()` populates `UnlockOffered(price: …)` from `PurchaseService.queryUnlockPrice()`. T03 declared the field; this task fills it and handles the two failure returns distinctly |
| 4 | `lib/features/flock/widgets/upgrade_row.dart` | **Edit.** Render the price clause only when the string is non-null. The row must not watch `unlockControllerProvider` — it is a sibling feature — so the price reaches it through the shared read named in §5.2 |
| 5 | `lib/features/settings/settings_screen.dart` | **Edit.** The same clause in section 9's row |
| 6 | `lib/l10n/app_en.arb` | **Edit.** **Two messages, not one with an empty placeholder** — see §5.3. Each with a `description` naming which form it is and when it renders |
| 7 | `test/policy/no_price_literal_test.dart` | **New.** The anchor |
| 8 | `test/features/free_tier_test.dart` | **Edit.** The two renderings, and the no-reformatting case |
| 9 | `test/features/overflow_matrix_test.dart` | **Edit.** The priced form is the longer of the two and is the one R58 names |

**Not touched:** `lib/core/ui/formatters.dart` (it must **not** gain a currency formatter — see §5.3),
`lib/data/purchase_service.dart` (T01 wrote `queryUnlockPrice()`), any table, any file under
`drift_schemas/`, and `docs/store/` — the price is the owner's and lives in N00-T09's ledger.

### 5.2 The signatures

Nothing new is declared. What matters is the path the string takes, and that it is a `String` the whole
way:

```
PurchaseService.queryUnlockPrice()   Future<String?>   // lib/data/ — the only file that may name the plugin type
        ↓  (a String, never a plugin type)
UnlockController.openSection()       → UnlockOffered(price: String?)
        ↓
Settings ▸ Unlock row   and   Flock upgrade row        // rendered verbatim, never reformatted
```

`UnlockOffered` is T03's and does not change:

```dart
final class UnlockOffered extends UnlockState {
  const UnlockOffered({this.price});
  /// The store's own localised, currency-formatted string, arriving through
  /// PurchaseService.queryUnlockPrice(). Non-null only if the store answered in
  /// THIS process. Never persisted.
  final String? price;
}
```

The gate row:

| Rule id | Fails on | Scope |
|---|---|---|
| `copy.currency_literal` | a currency symbol immediately followed by a digit | `lib/` **and** `assets/` |

`docs/` is deliberately out of scope (N00-T09) — which is exactly why the price may be written in the
decision ledger and nowhere else.

**The Flock row may not import `lib/features/settings/`.** Layer rule 6: siblings never import
siblings, and `unlockControllerProvider` lives in `settings/`. Route the price through a shared read —
either a small `Provider<String?>` in `lib/data/providers.dart` fed by the same `queryUnlockPrice()`
result, or a parameter passed down from a common ancestor. Whichever you choose, record it in a
comment; a `layer.sibling` violation discovered at the end of this task is a rewrite of the row.

### 5.3 The details that are easy to get wrong

- **Two ARB messages, not one message with an empty placeholder.** *"Unlock once for {price}"* with
  `price: ''` renders *"Unlock once for "* — a trailing preposition and a space, at 18 px, under a head
  torch. `11 §6.7` is explicit: *"when it is unresolved the sentence simply ends after 'Unlock once'."*
  Two messages, two `description`s, one `if`.
- **Nothing in `lib/` reformats the string.** `ProductDetails.price` is **already localised and
  currency-formatted by the store**, for the user's storefront, in their currency, with their
  separators. Re-running it through `NumberFormat.currency` is how a UK user sees `€12.99` rendered as
  `£12.99`. `lib/core/ui/formatters.dart` is the only `package:intl` call site in `lib/` outside
  `lib/data/` (`CONVENTIONS §1`) and it must **not** gain a currency formatter — if you find yourself
  adding one, the price has taken a wrong turn.
- **`null` is not an error and must not be mapped to one.** `queryUnlockPrice()` returns `null` when the
  store **answered** and the id was not configured (`productNotFound`), and **throws**
  `StoreUnreachable` when it did not answer (`storeUnreachable`). Two different lines on screen. The
  row's price clause is absent in both cases, but the Settings section's message is not the same, and
  collapsing them loses the difference between a shed and a broken Play Console entry.
- **The price is never persisted.** Not in `app_settings`, not on the entitlement row, not in a file,
  not in `LocalLog`. `PurchaseService._product` holds it and dies with the process (`11 §6.7`). A stored
  price goes stale — territory pricing changes, VAT changes, the owner changes the number — and a stale
  price in front of a user is the same class of dishonesty as a stale clear date shown as current.
- **Once the store has answered, both rows may render the price for the rest of the process.** It is
  process-scoped, not screen-scoped: a shepherd who opens Settings ▸ Unlock and then walks to the Flock
  screen sees the price on both. That is the whole reason the string is shared rather than local to
  `UnlockState`.
- **The scan covers `assets/` because the privacy policy and the About copy live there.** `assets/content/`
  holds authored prose too long to be a UI string (`CONVENTIONS §1`), and the store-listing paragraph
  the app renders is exactly the kind of text somebody pastes a price into. So is the App Review notes
  block. Both are in scope.
- **Write the symbol set down and plant one of each.** A scan that only knows `£` passes a file
  containing `€12.99`, and UK/Ireland first (§7.0 ruling 3) means **both** are live. Plant `€12.99`,
  `£11.99`, `$12` and `EUR 12.99` in temp files under each root and assert one violation each.
- **`12 §1.4` is the section to re-read before writing this.** A source-scanning rule belongs in
  `tool/check_policy.dart` — the gate — and the `test/policy/` file exists to prove the **property** and
  to hold the no-`[exempt]` assertion. Expressing the whole thing as a `RegExp` inside a `test()` is the
  named anti-pattern, and it produces a second scanning suite and a false-positive habit.
- **Never add an `[exempt]` line to keep this quiet.** R56 fixes the section at four lines on day one; a
  fifth is a review conversation, it deletes a rule for one file forever and silently, and `CLAUDE.md`
  names editing the allowlist to silence a gate as an anti-pattern outright.
- **No number goes in the commit message, the ARB, a test expectation or a comment.** Decision-record
  §7.1 open question **4** is still open: the exact price and the territory list are the owner's, `11 §10`
  says nothing in it is settled, and the Play one-time-product rate has to be read **in Play Console**
  rather than copied from secondary reporting. A number in a test is a number that will be wrong for
  three years.
- **The announced label must not re-say the currency in words.** Screen readers pronounce `€12.99`
  correctly for the user's locale; a `semanticLabel` of *"twelve euros ninety-nine"* is wrong the moment
  the storefront is not Ireland, and it is a second source of truth for a string whose whole point is
  that the store owns it.
- **The priced form is the one that overflows.** `Free version · covers this season · 22 of 15 ewes ·
  Unlock once for €12.99` at textScaler 2.0 with bold text is R58's named example. Reflow, never clip;
  no `FittedBox`; never clamp the scale (decision #99).

### 5.4 The full test set

| File | Case | What it holds |
|---|---|---|
| `test/policy/no_price_literal_test.dart` | **anchor** — `'no currency literal appears anywhere under lib/ or assets/'` | The scan over both roots, plus the no-`[exempt]` assertion |
| | `'the scan catches €, £, $ and an ISO code followed by a digit'` | One planted file per symbol; four violations, not one |
| | `'the scan skips generated files and finds a literal in assets/content/'` | The two ends of its scope |
| `test/policy/gate_rules_test.dart` | `'copy.currency_literal exits 1 on a planted €12.99 under lib/'` | The proving case N03-T07's inventory assertion requires |
| `test/features/free_tier_test.dart` | `'the row renders without a price until queryUnlockPrice returns'` | The shed rendering: the sentence ends after *"Unlock once"* and there is **no** trailing preposition |
| | `'once the store answers, both rows render the price for the rest of the process'` | Process-scoped, and shared across two features |
| | `'an unreachable store renders the offer without a price rather than a guessed one'` | `StoreUnreachable`, not `null` |
| | `'a null price from a configured-but-missing product renders productNotFound, not storeUnreachable'` | The two failure returns stay distinguishable |
| | `'the rendered price is byte-identical to the string the fake returned'` | No reformatting — assert equality against the fake's own string, not against a formatted expectation |
| | `'no price is written to app_settings, entitlements or LocalLog after a successful query'` | Never persisted, asserted by reading the tables and the log back |
| | `'the semanticLabel contains the store string and does not spell the currency in words'` | The announcement rule |
| `test/features/overflow_matrix_test.dart` | the priced at-cap variant | R58: 3 sizes × 3 text scales × 2 bold states, no `RenderFlex` overflow. Use the **longest plausible** store string, not the shortest |

**No `uk-zone` case, and say why in the file's header comment.** Nothing in this task is time-shaped:
the price is a `String` from a plugin, held for a process lifetime, never compared against a clock and
never persisted. The epic's two ambiguous-hour cases are T02's 14-day bound and T05's quiet window.

## 6. Constraints that bind this task

- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

> **One vocabulary point bites specifically here.** The row says **unlock**, never *buy*, *purchase*,
> *subscribe* or *upgrade* as a verb (`CONVENTIONS §5.1`), and *"Restore purchases"* is the single
> permitted exception. It also must never imply a recurring charge: spec §14 makes the **absence of a
> recurring price** part of the positioning, not a pricing experiment, and this audience is described as
> vocally hostile to farm-software subscriptions. *"Unlock once"* is doing work; do not shorten it.

## 7. Definition of Done

- [ ] `'no currency literal appears anywhere under lib/ or assets/'` passes, and was seen to fail first for the stated reason
- [ ] no currency symbol followed by digits anywhere under `lib/` or `assets/`
- [ ] the price renders as the store returned it, including its currency
- [ ] an unreachable store renders the offer without a price rather than a guessed one
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/no_price_literal_test.dart
fvm flutter test test/policy/gate_rules_test.dart
fvm flutter test test/features/free_tier_test.dart
fvm flutter test test/features/overflow_matrix_test.dart
dart run tool/check_policy.dart
grep -rnE '[€£$¥][0-9]' lib/ assets/                     # nothing
grep -rnE '\b(EUR|GBP|USD)\s*[0-9]' lib/ assets/         # nothing
grep -rn "NumberFormat" lib/                             # no currency formatter anywhere
grep -c "" <(grep -A99 "^\[exempt\]" tool/policy_allowlist.txt | grep "::")   # still four
grep -rn "currency_literal" tool/policy_allowlist.txt    # nothing — no exempt line
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(monetization): the price from ProductDetails, never a literal`

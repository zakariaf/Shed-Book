# N00-T09 — Store accounts, the Small Business Program, price and territories

| | |
|---|---|
| **Epic** | [N00 — Decisions, rulings and the calendar](epic.md) · `00-README` §9 step 0 |
| **Task** | 9 of 9 |
| **Depends on** | N00-T06 |
| **Commit** | one commit · `docs: record store accounts, SBP enrolment, price band and territories` |

## 1. Why this task exists

Both developer accounts created, the post-13-November-2023 personal-account question
answered in writing, Apple Small Business Program enrolment submitted, and the price band and
territory list chosen. Every one of these has approval lead time, all of them must be settled before
the first sale, and Play's closed test cannot start without an account and an app record. The old plan
had no task for any of it.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/11-monetization-and-store.md` | §10, §2, Definition of done | the €10–15 range, the Apple SBP arithmetic, Google's 30 June 2026 fee restructure marked **unverified**, and `kUnlockProductId` |
| `docs/engineering/13-build-ci-release.md` | §10.2, §10.3, §3.1 | the 12-tester / 14-day rule and its exemptions, the offline `.storekit` loop, and the identifier fixed in N00-T01 |
| `docs/research/00-tech-decisions.md` | §7.1 items 4 and 14; §2 I #87, #88, #93 | the two open questions, one binary with one bundle id, the never-revoked entitlement, and the privacy declarations |
| `shed-book-spec.md` | §14 | *"One-time unlock, €10–15. No subscription, ever"* and why the absence of a recurring price is positioning, not an experiment |
| `docs/engineering/CONVENTIONS.md` | §4.7, §5.1, §5.4 | the `copy.currency_literal` gate row, *unlock* not *purchase*, and *"the price is never a literal"* |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-monetization` | price, territories and the one-time unlock are its subject |
| `shed-release` | runbook, invoked by name — the store accounts are its first precondition |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/calendar_commitments_test.dart`
- **Test** — `'the developer-account, SBP, price and territories rows each carry a date and an outcome'`
- **Why it is red today** — all four rows are empty, and N32 cannot open a track without them.

```bash
fvm flutter test test/policy/calendar_commitments_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — create the accounts, submit the enrolment, choose the price band from spec §14's €10–15
and the territory list, and record the dates.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

After this task the ledger test **passes for six of seven rows** and stays red only on `field_night`'s
second half and `twelve_testers`' opt-in count, which close at N32-T03. The epic merges with the test
red, on purpose.

## 5. What you build

Four ledger rows, three test cases, and four things that happen in a browser with a card and a wait.
Nothing here is code, and every one of them has a lead time measured in days.

| # | File | What changes, and why |
|---|---|---|
| 1 | `docs/calendar.md` — `developer_accounts` | Owner, the date both accounts existed, and an outcome cell that answers the question in writing: **is the Google Play account a personal account created after 13 November 2023?** Yes or no, because it is the difference between a fourteen-day clock and no clock at all |
| 2 | `docs/calendar.md` — `apple_sbp_enrolment` | Owner, the submission date, and the date enrolment takes effect. It is fifteen days after the end of the fiscal month of approval, so the effective date is not the submission date and the row should carry both |
| 3 | `docs/calendar.md` — `price_and_territories` | Owner, the date decided, and an outcome cell carrying the chosen price, the territory list, and **the one-time-product rate read in Play Console** with the date it was read |
| 4 | `docs/calendar.md` — `store_identifiers` | The half N00-T01 could not fill: the unlock product created on both stores under one id, `shed_book_unlock`, as a **non-consumable** on Apple and a **one-time (managed) product** on Play |
| 5 | `test/policy/calendar_commitments_test.dart` | Three named-row cases beside T06's anchor, T07's two and T08's three |
| 6 | `docs/research/00-tech-decisions.md` §7.1 items 4 and 14, §7.0 | Item 4 struck with the price ruling; item 14 struck for the account half, with the recruitment half left to T07's row |
| 7 | `docs/engineering/11-monetization-and-store.md` §10 | The section opens *"This section is bounded by §7.1 open question 4, which is still open. Do not treat any number here as settled."* That sentence is what this task deletes, replacing it with the answer and its date |
| 8 | `docs/engineering/13-build-ci-release.md` §10.2 | The blockquote *"Nobody has answered this"* replaced by the answer, because everything downstream of it is a schedule |

### The four things, with the numbers that decide them

**Developer accounts.** Apple Developer Program is **$99 a year**; Google Play is a **$25 one-off**. Both
run identity verification before anything can be published, and an organisation account on either needs
a D-U-N-S number, which is itself a wait. Do both now: nothing in N32 can start without them, and
neither approval is something you can hurry in the week you want to ship.

**The 13 November 2023 question.** `13 §10.2`: *"A personal Google Play developer account created after
13 November 2023 must run a closed test with at least 12 opted-in testers for 14 continuous days before
it can apply for production access."* Reduced from twenty testers on 11 December 2024. Organisation
accounts and older personal accounts are exempt. If the answer is *yes*, N32-T03 is on the critical
path and T07's recruitment is a schedule item, not a research one.

**Apple Small Business Program.** 15% instead of 30% for developers under $1M USD in annual proceeds;
new developers qualify. **Enrolment takes effect fifteen days after the end of the fiscal month of
approval** — so it is a deadline, not a task. At €12 gross that is roughly €10.20 net instead of €8.40.
Enrolling after the first sale means paying 30% on everything sold in the gap, for nothing.

**Price and territories.** Spec §14 fixes the range at **€10–15** and `11 §10` names €11.99 and €12.99 as
the shapes under discussion. Price in EUR for IE and UK-adjacent markets — §7.0 ruling 3 puts UK/Ireland
first — and let both stores convert the rest. **Google restructured its fees on 30 June 2026**: the fee
splits into a service fee and a billing fee, the billing fee is 5% in US, UK and EEA when you use Play's
billing, and the widely-quoted **20% service + 5% billing** figure for a one-time product comes from
secondary reporting only and is **unverified** — Google's own post does not state a one-time-product
rate. `11 §10` says it in a warning: confirm the exact rate inside Play Console before committing to a
price. A number copied from a blog is how a price gets set 5% wrong for three years.

### The product id, frozen forever

```dart
// lib/data/purchase_service.dart — written in N30, from this row
const kUnlockProductId = 'shed_book_unlock';
```

One id, identical on both stores, created here and never changed: a non-consumable in App Store Connect
and a one-time (managed) in-app product in Play Console. Decision #87 is one binary, one bundle id, one
store listing per platform — two SKUs is a direct hit on App Review 4.3(a), and a second app sandbox
destroys the retention thesis because the shepherd's first season does not follow them.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **The price is never a literal** (`CONVENTIONS §5.4`) — the app renders `ProductDetails.price` from the store, always. `copy.currency_literal` is a `check_policy` row scanning `lib/` and `assets/` for a currency symbol followed by a digit; `docs/` is out of its scope, which is why the price may be written in the ledger and nowhere else.
- **Vocabulary** — one word per concept (`CLAUDE.md`). *unlock*, never *purchase*, *buy* or *subscribe*; *the free tier* or *the cap*, never *trial*, *freemium* or *paywall*. The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

### The details that are easy to get wrong

- **Do not create the Play app record here.** That is N32-T02, together with the store listing draft
  carrying N02-T02's honesty paragraph. This task creates the **accounts** and the **product**; the
  listing needs G0's answer about `ACCESS_NETWORK_STATE`, which does not exist until N02.
- **Both stores need banking and tax before a paid product can go live**, and both have their own
  approval wait. It is not part of account creation and it is the step people discover in the week they
  wanted to ship. Record it in the `developer_accounts` outcome cell if it is not done.
- **A hosted privacy-policy URL is mandatory on both stores** and is *"the one piece of internet
  infrastructure this project cannot avoid"* (decision-record §3.4 #5). It has no owner in this backlog.
  It is needed before the listing at N32-T02, not before the account, so note it in the row rather than
  doing it here — but note it, because nobody else will.
- **`ios/*.storekit` is committed** (`00-README` §7.1) and the local StoreKit configuration loop works
  fully offline with no Apple account. `13 §10.3` calls it *"the only purchase test that can be run
  before the developer account question is answered"*. It lands at N30 with `PurchaseService` — do not
  pull it forward into this commit just because it is adjacent.
- **The entitlement is never revoked, so a refund is not a code path.** Decision #88 and decision-record
  §4's last rows: re-locking a shepherd on night nine because a refund propagated is unacceptable
  against €12 of revenue. That is a pricing consequence as much as a technical one, and it belongs in
  the reasoning behind the price, not discovered at N30.
- **The store privacy answers are "Data Not Collected" on Apple and "No data collected or shared" on
  Play** (decision #93), and they are versioned artefacts that must be updated **before** a build ships
  if anything ever gains a network path. Nothing in this task changes them; everything in this task is
  the account under which they are eventually filed.
- **`store_identifiers` is the row two tasks share.** N00-T01 fixed the application id and bundle id and
  wrote them into `RELEASES.md`'s header; this task adds the product id and the fact that both stores now
  hold it. A row half-filled by an earlier task is unusual in this ledger — say so in the outcome cell so
  the next reader does not think one of the two is missing.
- **Nothing here is time-shaped in code.** The dates are civil dates in a document. The one date with
  arithmetic behind it — SBP's *fifteen days after the end of the fiscal month of approval* — is Apple's
  arithmetic on Apple's calendar, and the ledger records both the submission date and the effective date
  rather than computing one from the other.

## 7. Definition of Done

- [ ] `'the developer-account, SBP, price and territories rows each carry a date and an outcome'` passes, and was seen to fail first for the stated reason
- [ ] both developer accounts exist and are named in the ledger
- [ ] the personal-account question is answered in writing
- [ ] the price band and territories are recorded, and no price literal is written anywhere in the app
- [ ] SBP enrolment is submitted with its date
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/calendar_commitments_test.dart
```

By path — the `calendar` tag is declared in N01-T04 and until then a `--tags` filter matches nothing and
the run is green having run no tests (`12 §11.2`). The failure message must now name only what N32
closes:

```
1 commitment is not recorded:
  twelve_testers — outcome recorded, opt-in count below twelve
```

Then confirm the two documents that were waiting on this answer no longer say they are waiting:

```bash
grep -n "still open" docs/engineering/11-monetization-and-store.md
grep -n "Nobody has answered this" docs/engineering/13-build-ci-release.md
grep -rn "€" lib/ assets/ 2>/dev/null                       # must be empty; the price is never a literal
```

The cases this task adds:

| Case | Asserts |
|---|---|
| `'the developer-account, SBP, price and territories rows each carry a date and an outcome'` | the anchor: all four complete under T06's `complete` rule |
| `'the developer-account row answers the 13 November 2023 question'` | the outcome cell contains an explicit yes or no, because the schedule downstream of it is different in each case |
| `'the price row records where the store rate was read and when'` | the outcome names Play Console and a date — a rate from a secondary source is what `11 §10` warns against by name |

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `docs: record store accounts, SBP enrolment, price band and territories`

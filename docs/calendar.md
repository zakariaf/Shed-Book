# The calendar ledger

Seven commitments that need somebody else's diary. Each has a key, an owner, a due point expressed
in epics rather than dates, the date it was **recorded**, its **outcome**, and — the column that
makes it a commitment rather than a wish — **what happens if it does not happen**.

`test/policy/calendar_commitments_test.dart` reads this file and **fails while any row is
incomplete, naming the incomplete rows by key.** That test is red on purpose from N00-T06 until N32
closes the last row. It is kept out of the blocking set by the `calendar` tag, declared in
`dart_test.yaml` (N01-T04) and excluded by `make test` (N01-T05) and the `test` CI job (N01-T06).
Until those land it is run by path and by nobody else — an undeclared tag matches nothing and the run
is green having run no tests (`12 §11.2`).

**A row is never deleted to make the test pass.** That is the only way this file can lie, and it is
the failure the plan critique wrote it to prevent: the old plan recorded the field night with
*"correct placement, no teeth — no task consumes its output and no gate fails while it is
unbooked."*

Dates here are ISO `YYYY-MM-DD`. That is not a contradiction of `CONVENTIONS §5.4`'s *never
all-numeric* rule, which governs dates shown to a **shepherd**; this file is read by a developer and
by a parser, exactly as a CSV carries an ISO-8601 column beside its human one.

| Key | Commitment | Owner | Due | Recorded | Outcome | If it does not happen |
|---|---|---|---|---|---|---|
| `field_night` | One full night observed in a real lambing shed | | before N13 | | | Quick Entry is designed from forum posts, and every tap count in `07-screens.md` stays a desk estimate |
| `twelve_testers` | Twelve shepherds recruited and opted in to the Play closed test | | before N32 | | | Play's 14-day clock cannot start; fourteen days of dead calendar at the end of the project |
| `ziplock_capacitance` | Taps registered through a freezer bag, per target device, under all five conditions below | | before N13 | | | Decision **#100** (the 60×60 pt floor), decision **#101** (the gesture ban) and decision **#102** (volume-button shortcuts) are struck and re-decided, and the interaction model is re-cut around volume-button shortcuts — which invalidates N13 onward |
| `developer_accounts` | Both store accounts exist; the post-13-Nov-2023 personal-account question answered | | before N32 | | | No app record, no closed track, no TestFlight |
| `apple_sbp_enrolment` | Apple Small Business Program enrolment submitted | | before the first sale | | | 30% instead of 15% on everything sold in the gap, for nothing |
| `price_and_territories` | The exact price and the territory list, read in Play Console | | before the first submission | | | A price set from a secondary source, wrong for three years |
| `g5_observation` | The shipped build observed making **no network connection** on a real device — Charles or a proxy on a physical phone, one full session, every screen | | before N34 | | | The offline claim in decision-record §3.1 rests on two gates that read *artefacts* — G1 the permission set, G3 the imports — and neither watches the app run. A dependency that opened a socket from a background isolate would pass both |
| `store_identifiers` | Application id / bundle id and the unlock product id, created on both stores | | before N32 | | The application id and bundle id half is **done**: `com.shedbook.shedbook`, fixed in N00-T01 and recorded in `RELEASES.md`'s header and decision #129. The unlock product id is fixed as **`shed_book_unlock`** — one id, identical on both stores — but has **not been created** on either: a non-consumable in App Store Connect and a one-time (managed) product in Play Console. That half is N00-T09's and needs the accounts first | Two stores keyed on a string nobody wrote down |

## P15 turned three of these due points into dates

**Ruled 2026-08-03** (decision record §7.0c, scope in [`RELEASE-SCOPE.md`](RELEASE-SCOPE.md)). The
product ships twice, and `v1.0.0` has to be in the store before **1 February 2027** because `13 §11`
freezes releases 1 Feb – 30 Apr and that is the only time of year this app is used. A release that
misses it slips by a year.

The `Due` column stays expressed in epics, which is right — it is the column a developer reads. But
three rows now also have a calendar date behind them, and they are the three that need somebody else:

| Key | Reads | Now also means |
|---|---|---|
| `twelve_testers` | before N32 | **~November 2026.** Play counts testers who joined the closed track via the opt-in link, for **fourteen continuous days**, before production. Working back from a mid-December submission, the link has to be live in November — and this row is still empty |
| `developer_accounts` | before N32 | **~October 2026.** Both accounts must exist before the app record, the closed track and TestFlight do; Apple's enrolment is not same-day |
| `g5_observation` | The shipped build observed making **no network connection** on a real device — Charles or a proxy on a physical phone, one full session, every screen | | before N34 | | | The offline claim in decision-record §3.1 rests on two gates that read *artefacts* — G1 the permission set, G3 the imports — and neither watches the app run. A dependency that opened a socket from a background isolate would pass both |
| `store_identifiers` | before N32 | **~October 2026**, its unresolved half. `shed_book_unlock` has to exist as a non-consumable in App Store Connect and a one-time managed product in Play Console, and it needs the accounts first |

`apple_sbp_enrolment` and `price_and_territories` read *before the first sale* and *before the first
submission*, and those now resolve to **mid-December 2026** by the same arithmetic.

**`field_night` and `ziplock_capacitance` are unaffected and remain the two that are late.** Their due
point was *before N13*, N13 merged in 2026, and the honest reading is that both were missed rather
than moved. The 2027 lambing season — February to April — is the next window a shed night can be
booked in at all, and it falls **during the freeze**, which is a good time to observe and a forbidden
time to ship. Recording that here rather than quietly re-dating the rows is what §0 of this file
requires.

## How the columns are read

```
recorded  := an ISO civil date, YYYY-MM-DD, and nothing else
outcome   := a non-empty cell that is not one of: — TBD ? pending TODO n/a
complete  := owner is non-empty AND recorded is a date AND outcome is a real outcome
```

`store_identifiers` is the one row two tasks share, which is unusual here and is said out loud so
the next reader does not think half of it is missing: N00-T01 fixed the identifier and wrote it into
`RELEASES.md`; N00-T09 creates the product on both stores and records the date.

## `field_night` and `twelve_testers` — what a filled row looks like

Both are N00-T07's. Neither is closed, and the ledger test names both.

**`field_night`.** The outcome cell names **the shed, the flock size, and roughly how many lambings
are expected that night** — a night with two lambings is a visit, not an observation. What the night
is for is the things nobody writes down: which hand holds the phone, what is in the other one, where
the torch is, how long the phone is out of a pocket, and what actually happens between the ewe
starting and the record being wanted. It also turns four desk estimates into observations — five taps
from launch to a committed `beginLambing` row, six to a lambing with one lamb, one for a foster
reassignment, two for a repeat treatment.

The window is seasonal and does not reopen on demand: UK/Ireland lambing runs roughly February to
April, the same three months `13 §11` freezes releases for. **If N13 lands outside that window the
night cannot be booked before it, and the honest move is to record that in the outcome cell and say
plainly that Quick Entry was designed from forum posts.** Do not quietly re-scope the row to a phone
call with a shepherd and call it observed.

**`twelve_testers`.** The outcome cell names the channels posted to and carries **two** numbers:
how many said yes, and how many have **opted in**. They diverge, and the second is the one N32-T03
needs — Play counts testers who joined the closed track via the opt-in link, for fourteen continuous
days, so twelve people who said yes on a forum are twelve people who have not clicked anything.

Spec §3's channels, which is what the test checks the outcome against: The Farming Forum (sheep
board) · Accidental Smallholder · r/sheep · r/homestead · National Sheep Association · breed
societies · local NFU and young farmer groups. The audience is smallholders and small commercial
flocks, **20–400 ewes**, lambing indoors or in a field within walking distance, one or two people
doing all the work, often alongside a day job. Spec §3 also records what they type into an app
store — *lambing app · sheep records offline · flock book app · lambing records no subscription ·
lambing notebook* — which is the vocabulary a recruitment post should use, because it is theirs.

Twelve is the current floor, not a remembered one: it was reduced from twenty on 11 December 2024,
and organisation accounts and personal accounts created before 13 November 2023 are exempt entirely.
Whether this project is exempt is `developer_accounts`' question — recruit anyway, because the field
night needs the same people for a different reason.

## `ziplock_capacitance` — the measurement, so two people get the same answer

N00-T08's. **The consequence is written here before the result is known**, deliberately, so that the
result cannot be argued with afterwards. The critique's complaint about the old plan was not that the
test was missing; it was that it had *"no owner, no epic and no date"* and its consequence lived in
prose.

A standard 1 L LDPE freezer bag — the kind a shepherd already has — sealed over the phone. Test
**every target device** at the OS version it will ship to, and record each condition separately:

| # | Condition | Why it is on the list |
|---|---|---|
| 1 | A single tap on a 60×60 pt target, dry bag, bare hand | The baseline decision #100 assumes |
| 2 | The same, with the bag **wet on the outside** | This is the shed condition, and it is the one that fails: water on a capacitive surface produces **phantom touches**, not missed ones |
| 3 | The same, with a wet or gloved hand inside | Spec §5's actual user. Parhi et al.'s 9.2/9.6 mm optimum is for a *bare* thumb in ideal conditions |
| 4 | Two taps in quick succession on the same target | The double-tap defence (#22) exists because cold, wet fingers on capacitive glass double-fire. Confirm the hardware double-fires rather than misses |
| 5 | The same tap with the vendor's glove mode / raised touch sensitivity **off** | It is off by default on the Androids that have it. A result that only holds with it on is a fail for a stock device |

**Pass means: every condition registers a tap on the intended 60×60 pt target, and no condition
produces a phantom touch elsewhere.** Anything else is a fail, recorded per device **with the
condition that failed**. *"Works dry, phantom touches wet"* is the most likely result and it is a
genuine answer — it points at hit slop and target size rather than at volume buttons. Write the
condition, not a verdict.

Three things that change the answer and must be recorded with it:

- **The bag is not the failure mode; the water on it is.** Capacitive digitisers couple happily
  through a thin dielectric — 50 µm of LDPE is nothing. What breaks them is a conductive film across
  the surface, which is exactly what a shed produces. A test run on a dry bag at a kitchen table
  passes and proves nothing.
- **Record the OS version, not just the model.** Touch rejection and moisture heuristics are
  firmware, and the same handset behaves differently across a major OS release.
- **Do not test with a screen protector unless the target ships with one** — and if you do, say so in
  the outcome cell. It is another dielectric layer.

**The bag is a user workaround, never a product feature.** The app cannot detect it, must not detect
it, and no code path may branch on it. What the measurement changes is a *decision*, not a runtime.
The measurement uses a **single tap only**, because that is the only gesture the product has — do not
test a swipe through the bag; there are no swipes to save.

**And volume-button shortcuts are not a free fallback.** On Android, capturing volume keys outside
your own foreground activity needs a media session or an accessibility service; on iOS it is bounded
by App Store Guideline 2.5.9. Either route is a new permission or a new entitlement — and a new
permission is a change to the set **G0 records at N02**. If this fails, N02's answer changes shape
too.

## The four store rows — the numbers that decide them

N00-T09's. Nothing here is code, and every one has a lead time measured in days.

**`developer_accounts`.** Apple Developer Program is **$99 a year**; Google Play is a **$25 one-off**.
Both run identity verification before anything can be published, and an organisation account on
either needs a D-U-N-S number, which is itself a wait.

The outcome cell must answer one question **in writing, yes or no**: *is the Google Play account a
personal account created after 13 November 2023?* If yes, that account must run a closed test with at
least **twelve opted-in testers for fourteen continuous days** before it can apply for production
access — so N32-T03 is on the critical path and `twelve_testers` is a schedule item rather than a
research one. Organisation accounts and older personal accounts are exempt entirely. It is the
difference between a fourteen-day clock and no clock at all.

Two more things belong in that cell if they are not done, because they are what people discover in
the week they wanted to ship: **banking and tax details** on both stores, each with its own approval
wait, are required before a paid product can go live; and a **hosted privacy-policy URL**, mandatory
on both stores, *"the one piece of internet infrastructure this project cannot avoid"* — it has **no
owner anywhere in this backlog**. It is needed before the listing at N32-T02, not before the account,
so note it here rather than doing it here — but note it, because nobody else will.

**`apple_sbp_enrolment`.** The Small Business Program is 15% instead of 30% for developers under $1M
USD in annual proceeds, and new developers qualify. **It takes effect fifteen days after the end of
the fiscal month of approval** — so it is a deadline, not a task, and the row carries **both** the
submission date and the effective date rather than computing one from the other; that arithmetic is
Apple's, on Apple's calendar. At €12 gross it is roughly €10.20 net instead of €8.40. Enrolling after
the first sale means paying 30% on everything sold in the gap, for nothing.

**`price_and_territories`.** Spec §14 fixes the range at **€10–15** — *"one-time unlock. No
subscription, ever"* — and `11 §10` names €11.99 and €12.99 as the shapes under discussion. Price in
EUR for IE and UK-adjacent markets, per the UK/Ireland-first ruling, and let both stores convert the
rest.

**Google restructured its fees on 30 June 2026** and this is where the row earns its keep: the fee
splits into a service fee and a billing fee, the billing fee is 5% in the US, UK and EEA when you use
Play's billing, and the widely-quoted **20% service + 5% billing** figure for a one-time product
comes from **secondary reporting only** — Google's own post does not state a one-time-product rate.
The outcome cell must record **the rate as read inside Play Console, and the date it was read**. A
number copied from a blog is how a price gets set 5% wrong for three years.

One pricing consequence that is not a technical one: **the entitlement is never revoked, so a refund
is not a code path.** Re-locking a shepherd on night nine because a refund propagated is
unacceptable against €12 of revenue. That belongs in the reasoning behind the price, not discovered
at N30.

**The price is never a literal in the app.** `CONVENTIONS §5.4`: the app renders
`ProductDetails.price` from the store, always. `copy.currency_literal` is a `check_policy` row
scanning `lib/` and `assets/` for a currency symbol followed by a digit. `docs/` is out of its scope,
which is exactly why the price may be written in this ledger and nowhere else.

**What N00-T09 does not do.** It does not create the Play app record or the store listing — that is
N32-T02, and the listing needs G0's answer about `ACCESS_NETWORK_STATE`, which does not exist until
N02. It creates the **accounts** and the **product**. It also does not pull `ios/*.storekit` forward:
the local StoreKit configuration loop works fully offline with no Apple account and is *"the only
purchase test that can be run before the developer account question is answered"*, but it lands at
N30 with `PurchaseService`.

## What this file does not do

**It never reads a clock.** No row is asserted to be in the future and no recorded date is compared
against today. A test that did would change verdict at midnight and be ambiguous for a whole hour
once a year, because the owner's region ruling puts the UK/Ireland ambiguous hour at **01:00–01:59**.
If a recency assertion is ever genuinely wanted it takes `withClock` and a case at 01:30 on the
clocks-back night in the `uk-zone` tier — it does not take `DateTime.now()`, which under decision #46
may appear in exactly one file under `lib/` and has no business in a policy test at all. The sixth
case of the ledger test is a policy test on a policy test, and it exists to keep it that way.

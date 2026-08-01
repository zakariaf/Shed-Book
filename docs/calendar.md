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
| `ziplock_capacitance` | Taps registered through a freezer bag, per target device | | before N13 | | | Decisions #100–#102 change and the interaction model is re-cut around volume-button shortcuts |
| `developer_accounts` | Both store accounts exist; the post-13-Nov-2023 personal-account question answered | | before N32 | | | No app record, no closed track, no TestFlight |
| `apple_sbp_enrolment` | Apple Small Business Program enrolment submitted | | before the first sale | | | 30% instead of 15% on everything sold in the gap, for nothing |
| `price_and_territories` | The exact price and the territory list, read in Play Console | | before the first submission | | | A price set from a secondary source, wrong for three years |
| `store_identifiers` | Application id / bundle id and the unlock product id, created on both stores | | before N32 | | The application id and bundle id half is **done**: `com.shedbook.shedbook`, fixed in N00-T01 and recorded in `RELEASES.md`'s header and decision #129. The unlock product `shed_book_unlock` has **not** been created on either store — that half is N00-T09's | Two stores keyed on a string nobody wrote down |

## How the columns are read

```
recorded  := an ISO civil date, YYYY-MM-DD, and nothing else
outcome   := a non-empty cell that is not one of: — TBD ? pending TODO n/a
complete  := owner is non-empty AND recorded is a date AND outcome is a real outcome
```

`store_identifiers` is the one row two tasks share, which is unusual here and is said out loud so
the next reader does not think half of it is missing: N00-T01 fixed the identifier and wrote it into
`RELEASES.md`; N00-T09 creates the product on both stores and records the date.

## What this file does not do

**It never reads a clock.** No row is asserted to be in the future and no recorded date is compared
against today. A test that did would change verdict at midnight and be ambiguous for a whole hour
once a year, because the owner's region ruling puts the UK/Ireland ambiguous hour at **01:00–01:59**.
If a recency assertion is ever genuinely wanted it takes `withClock` and a case at 01:30 on the
clocks-back night in the `uk-zone` tier — it does not take `DateTime.now()`, which under decision #46
may appear in exactly one file under `lib/` and has no business in a policy test at all. The sixth
case of the ledger test is a policy test on a policy test, and it exists to keep it that way.

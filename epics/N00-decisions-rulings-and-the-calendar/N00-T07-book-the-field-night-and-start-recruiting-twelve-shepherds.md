# N00-T07 — Book the field night and start recruiting twelve shepherds

| | |
|---|---|
| **Epic** | [N00 — Decisions, rulings and the calendar](epic.md) · `00-README` §9 step 0 |
| **Task** | 7 of 9 |
| **Depends on** | N00-T06 |
| **Commit** | one commit · `docs: book the field night and open twelve-tester recruitment` |

## 1. Why this task exists

`00-README` §5.2's item 1 is the highest-value unresolved item in the project and it closes
three others: every tap count in `07-screens.md` is a desk estimate until somebody watches one full
night in a real shed. Recruiting twelve shepherds doubles as Play's twelve-tester requirement, whose
fourteen-day clock cannot start until they exist. Book the night, name the shed, open the recruitment
channels from spec §3, and record both in the ledger.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/research/00-tech-decisions.md` | §7.1 items 1 and 14 | *"The entry flow is the product and cannot be designed correctly from forum posts"*, and the recruitment that doubles as the answer |
| `shed-book-spec.md` | §3, §5, §17 item 1 | who this is for, where they gather, the 3am test the night is observed against, and the question in the owner's own words |
| `docs/engineering/13-build-ci-release.md` | §10.2, §11 | Play's 12-tester / 14-day closed test, and the February–April freeze that is also the lambing window |
| `docs/engineering/07-screens.md` | §1.3 and the per-screen tap costs | the desk estimates the night exists to confirm or destroy |
| `epics/00-PLAN-CRITIQUE.md` | §2 | *"Correct placement, no teeth"* — why this became a ledger row with a test behind it |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-conventions` | the ledger row shape and the vocabulary of what gets recorded |
| `shed-testing` | the ledger test is what makes the commitment real |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/calendar_commitments_test.dart`
- **Test** — `'the field night row and the twelve-tester row both carry a date'`
- **Why it is red today** — both rows exist and both are empty.

```bash
fvm flutter test test/policy/calendar_commitments_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — a booked date and a named shed in the field-night row; a channel list and a running count
in the twelve-tester row.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

The suite is not green after this task — the other four ledger rows are still empty and the anchor from
T06 still fails. "Green" here means these two cases pass and the file's failure message has shrunk from
six rows to four.

## 5. What you build

Two ledger rows, two test cases, and one thing that is not a file at all: a booking in somebody else's
diary. This is the task in the epic where the deliverable is a phone call.

| # | File | What changes, and why |
|---|---|---|
| 1 | `docs/calendar.md` — `field_night` | Owner, the **Recorded** date the night is booked for, and an outcome cell naming the shed, the flock size and roughly how many lambings are expected that night. A night with two lambings is a visit, not an observation |
| 2 | `docs/calendar.md` — `twelve_testers` | Owner, the **Recorded** date recruitment opened, and an outcome cell listing the channels posted to and the running count of shepherds who have said yes |
| 3 | `test/policy/calendar_commitments_test.dart` | Two named-row cases added beside T06's anchor |
| 4 | `docs/research/00-tech-decisions.md` §7.1 items 1 and 14 | Struck for the half this task closes — *the observation is booked*, *recruitment is open* — with the half that remains (the observation has not happened; twelve people have not opted in) restated as its own line, because striking a half-answered question is how a project loses the other half |
| 5 | `docs/engineering/00-README.md` §5.2 items 1 and 14 | The same status, in the document a developer actually opens |

### The recruitment channels, from spec §3

The Farming Forum (sheep board) · Accidental Smallholder · r/sheep · r/homestead · National Sheep
Association · breed societies · local NFU and young farmer groups. The audience is smallholders and
small commercial flocks, **20–400 ewes**, lambing indoors or in a field within walking distance, one
or two people doing all the work, often alongside a day job. Spec §3 also says what they type into an
app store — *lambing app · sheep records offline · flock book app · lambing records no subscription ·
lambing notebook* — which is the vocabulary a recruitment post should use, because it is theirs.

### What the field night is for, concretely

`07-screens.md` prices every screen in taps and `12-testing.md` §10.1 turns three of those prices into
executable budgets: **five taps** from launch to a committed `beginLambing` row (N14-T06), **six** to a
lambing with one lamb (N16-T02a), **one** for a foster reassignment (N18-T05), **two** for a repeat
treatment (N20-T04). Every one of those numbers is a desk estimate today. The night is what turns them
into observations — and it is also the only way to see the things nobody writes down: which hand holds
the phone, what is on the other one, where the torch is, how long the phone is out of a pocket, and
what actually happens between the ewe starting and the record being wanted.

## 6. Constraints that bind this task

- **The 3am test** (spec §5) — the night is observed against it: one thumb, one hand, gloves, wet hands, head torch or darkness, and under fifteen seconds from unlock to a saved lambing. What you are measuring is whether those conditions are as described, not whether the app is good; there is no app.
- **Offline** — nothing observed leaves the shed by a network path, and no animal record is copied. There is no product to demonstrate and nothing to install.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

### The details that are easy to get wrong

- **The window is seasonal and does not reopen on demand.** UK/Ireland lambing runs roughly February to
  April — the same three months `13 §11` freezes releases for, and for the same reason. If N13 lands
  outside that window, the night **cannot** be booked before it, and the honest move is to record that in
  the outcome cell and say plainly that Quick Entry was designed from forum posts. Do not quietly
  re-scope the row to a phone call with a shepherd and call it observed.
- **"Recruited" is not "opted in".** Play's clock counts testers who have joined the closed track via the
  opt-in link, for **fourteen continuous days**. Twelve people who said yes on a forum are twelve people
  who have not yet clicked anything. The row's outcome should carry both numbers — said yes, and opted
  in — because they diverge and the second is the one that matters at N32-T03.
- **Do not assert a target count in the test.** A case that requires `count >= 12` goes red every time
  somebody drops out, in an epic that merged months earlier, on a `main` everyone expects to be green.
  Assert what T06's shape asserts: an owner, an ISO date and a real outcome.
- **Twelve testers is the current floor, not a remembered one.** It was reduced from twenty on
  11 December 2024, and organisation accounts and personal accounts created before 13 November 2023 are
  exempt entirely (`13 §10.2`). Whether this project is exempt is T09's question — start recruiting
  anyway, because item 1 needs the same people for a different reason.
- **This task may contradict T02's voice-note ruling, and that is allowed.** Decision-record §7.1 item 1
  says the observation *"also closes questions 2, 12 and 18"* — the ziplock test, the lamb-scale
  resolution and the voice-note cap. If the night says ninety seconds, the amendment rule applies and
  the cost is one constant and one row. That is precisely why T02 ruled 60 s: it is the recoverable
  direction.
- **Nothing here is time-shaped in code.** The dates are civil dates written by a human into a
  document, and the ledger test reads no clock — see T06's sixth case, which exists to keep it that way.
  If a *"the field night has not already passed"* assertion is ever added, it needs `withClock` and a
  case at 01:30 on the clocks-back night in the `uk-zone` tier.

## 7. Definition of Done

- [ ] `'the field night row and the twelve-tester row both carry a date'` passes, and was seen to fail first for the stated reason
- [ ] the field night has a date and a location
- [ ] the twelve-tester row names the channels and carries a count
- [ ] the field night is booked **before N13**, or Quick Entry is designed from forum posts
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/calendar_commitments_test.dart
```

Run it **by path**. Do not add `--tags calendar`: the tag is declared in N01-T04's `dart_test.yaml`, and
until it exists a `--tags` filter matches nothing and the run is green having run no tests
(`12 §11.2`). Read the failure message and confirm it has shrunk to four rows:

```
4 commitments are not recorded:
  ziplock_capacitance   — no date, no outcome
  developer_accounts    — no date, no outcome
  apple_sbp_enrolment   — no date, no outcome
  price_and_territories — no date, no outcome
```

The cases this task adds:

| Case | Asserts |
|---|---|
| `'the field night row and the twelve-tester row both carry a date'` | the anchor: both rows complete under T06's `complete` rule |
| `'the field night row names a location'` | the outcome cell is more than a date — a night with no shed named has not been booked |
| `'the twelve-tester row names at least one channel from spec §3'` | the outcome cell contains a channel name, so *"posted somewhere"* cannot pass |

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `docs: book the field night and open twelve-tester recruitment`

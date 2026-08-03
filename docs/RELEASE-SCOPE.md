# Release scope — what ships in `v1.0.0` and what waits for `v1.1.0`

> **Decisions applied:** #128 release hygiene and the seasonal freeze · #127 the app-size budget ·
> #90 nothing on the shed path branches on `unlocked` · #83 `pdf` is the only PDF producer ·
> #63/#65 notification channel ids frozen at release · #37 migrations are forward-only ·
> **P15** — the two releases (`00-tech-decisions.md` §7.0c), which this document is the application of.

Ruled by the owner on **2026-08-03**. `tool/validate_epics.py` reads the table in §3 and fails while
any epic's `**Ships in**` row disagrees with it, so this file and thirty-five epic headers cannot
drift apart.

---

## 0. The word to use, and the two words never to use

**Write the tag.** An epic ships in **`v1.0.0`** or in **`v1.1.0`**, and those are the strings — the
same ones `release.yml` fires on, `RELEASES.md` records and both stores display. There is no new
vocabulary here because there does not need to be any.

**Never write "v1" or "v2" for these two releases.** Both words are already taken, and taken for
something that is nearly the opposite:

| Word | What it already means | Where |
|---|---|---|
| **v1** | *the product* — everything that is not cut — spanning both releases | spec §7 *"Must-have features (v1)"*, §13, decision-record §7.0 |
| **v2** | *cut, and maybe never* — EID readers, cattle, weather, any sync | spec §13 *"Each of these is a reasonable v2 candidate"* |

So *"reminders are not in v1"* would say reminders are **cut from the product**, which is false and is
the single most damaging thing this document could be misread as saying. *"Reminders ship in
`v1.1.0`"* says what is true. `CONVENTIONS.md`'s R-numbers and `epics/README.md`'s *ruling R1* make
`R1`/`R2` unusable as labels for the same reason — they are rule ids, and this project has spent
thirty-four epics on one word per concept.

---

## 1. Why there are two releases at all

Not effort. **A date somebody else owns.**

`13 §11` freezes releases for the customer's lambing season, and the freeze is not a preference:

| Dates | Status | What may ship |
|---|---|---|
| 1 Feb – 30 Apr | **FROZEN** | only a defect that destroys records or prevents the app opening |
| 1 – 31 May | elevated scrutiny | hill flocks are still lambing; staged rollout only, 10% for 72 h |
| 1 Jun – 31 Jan | open | this is where feature work lands |

Today is **2026-08-03**. That leaves one open window — **now until 31 January 2027** — and on the far
side of it is the 2027 UK/Ireland lambing season, which is the *only* time of year this app is used at
all. A release that misses it does not slip by a month. **It slips by a year**, into a season whose
shepherds have already chosen a notebook or a competitor.

The whole remaining backlog does not fit in that window with any confidence. So the question is not
*"what can we drop"* — it is **"what has to be on a phone before the first ewe lambs, and what can
arrive while the freeze is on and ship the day it lifts."**

That second half is the part that makes this cheap. **The freeze blocks releases, not work.**
February to May 2027 is four months in which `v1.1.0` can be built, reviewed and sat on a closed track
— and then shipped on **1 June 2027**, the first legal day, with the 2027 season's data still fresh
in the shepherd's mind and eight months before the 2028 season needs it.

```
2026-08 ────────────────────────── 2027-01   2027-02 ───── 2027-04   2027-05   2027-06 ─────
        build v1.0.0                          FROZEN                  staged     ship v1.1.0
                          ▲ submit                ▲ build v1.1.0                       ▲
                          mid-December            (releases blocked, work is not)      1 June
```

### The dates that follow from that

| Date | What must be true |
|---|---|
| **~2026-11** | **N32 merged.** Play's closed test needs twelve testers opted in for **fourteen continuous days** before production, and the ledger row `twelve_testers` is not closed |
| **~2026-12-15** | `v1.0.0` submitted to both stores. Two review queues, at Christmas |
| **2027-01** | in the store, and being installed by shepherds *before* they need it |
| **2027-02-01** | freeze begins. `v1.1.0` development starts |
| **2027-06-01** | freeze plus May's elevated window over. `v1.1.0` ships |

---

## 2. How the line was drawn

One question per epic, and it is not *"is this valuable"* — everything left is valuable, or it would
already be in spec §13.

> **If this is missing on the night of 3 March 2027, what happens?**

Three answers, and they sort the backlog:

1. **A record is lost, or cannot be got off the phone.** → `v1.0.0`. There is no server, no sync and
   no remote fix, and the app is *frozen* that night. Export, backup and restore are in this class and
   are not negotiable.
2. **The app cannot be sold, shipped or installed.** → `v1.0.0`. Signing, permissions, the store
   artefacts, the unlock.
3. **The shepherd does the thing slightly less conveniently, using something that is already on
   screen.** → `v1.1.0`.

Every deferral below is in class 3, and each one names what covers it in the meantime. **A deferral
with no answer to *"what do they do instead"* is a cut, and would belong in spec §13 instead.**

---

## 3. The table

`tool/validate_epics.py` parses this table. One row per epic, `Ships in` is exactly one of the two
tags or the word `split`, and every epic directory must appear.

| Epic | Ships in | Tasks in `v1.0.0` | Tasks in `v1.1.0` |
|---|---|---|---|
| N00 … N20 | `v1.0.0` | all — merged | — |
| N21 — Export: CSV, PDF and share | `split` | T01 T02 T03 T06 T07 T08 | T04 T05 |
| N22 — The JSON backup format | `v1.0.0` | all | — |
| N23 — Restore, the sweeps and the seed | `v1.0.0` | all | — |
| N24 — Reminders: rows, reconcile, fixtures | `v1.1.0` | — | all |
| N25 — Reminders screen | `v1.1.0` | — | all |
| N26 — Flock and Note Search | `split` | T01 T02 T03 T04 T07 | T05 T06 |
| N27 — Ewe Card | `v1.0.0` | all | — |
| N28 — Season Summary | `v1.1.0` | — | all |
| N29 — Settings | `split` | T01 T02 T04 T05 T07 T08 | T03 T06 |
| N30 — Monetization | `v1.0.0` | all | — |
| N31 — Platform artefacts, G1, G4, G5 | `v1.0.0` | all | — |
| N32 — Signing and the closed track | `v1.0.0` | all | — |
| N33 — Ship gates | `v1.0.0` | all | — |
| N34 — Release engineering | `v1.0.0` | all | — |

**64 tasks in `v1.0.0`. 26 in `v1.1.0`.** Twenty-nine per cent of the remaining backlog moves out of
the window, and none of it is a feature the shepherd loses — only one they get later.

---

## 4. Every deferral, and what covers it until June

### N24 + N25 — reminders (14 tasks, the largest single move)

**What waits.** Colostrum window, navel dip, turn out, tag-by, ring/dock/castrate, second dose,
withdrawal end. Local notifications, the eight Android channels, the reconciler, the screen.

**Why it is the right thing to defer, and not merely the biggest.** It is the only feature in the
backlog whose correctness depends on undocumented OS behaviour. `08 §2.1`: Apple's ceiling is 64
pending requests per app and the behaviour above it is *permanently undefined* — three published
descriptions that disagree and an issue closed `not planned`. A 400-ewe flock in one peak week
produces roughly 500 pending reminders. That is a feature whose failure mode is **silent**: a
reminder that was dropped looks exactly like a reminder that was never due, and there is no screen
anywhere that could tell the shepherd why the lamb was not tubed.

Shipping that for the first time, into the first season, three weeks before a freeze during which it
cannot be fixed, is the worst-timed thing in the entire plan.

**What covers it.** Nothing, honestly — and that is stated rather than dressed up. The pen board's
hours-since-penned tile and the treatments countdown are on screen and are the two facts a reminder
would have carried, but a screen you have to look at is not a phone that buzzes. **This is the one
deferral the store listing must not imply is present.**

**What it costs to defer — measured, not assumed:**

- **Nothing is orphaned.** `13 §11.2`: notification channel ids are frozen *at release* and changing
  one afterwards silently orphans every scheduled reminder on every installed device. `v1.0.0`
  creates **no channel**, so it freezes nothing and `v1.1.0` is the first release that fixes the
  eight ids. Deferring is strictly safer here than shipping.
- **A smaller permission set.** `v1.0.0` ships without `POST_NOTIFICATIONS`,
  `RECEIVE_BOOT_COMPLETED` and `SCHEDULE_EXACT_ALARM`. See §5.2 — this is the constraint that needs
  the most care, and it is also the release that first makes the offline claim in public.
- **An open question leaves the critical path.** Decision-record §7.1 item 17 — *"does the free tier
  cap reminders too?"* — is a `v1.1.0` question now, and it was one of two product-shaped items still
  unanswered.
- **A lambing recorded in `v1.0.0` gets no reminders when `v1.1.0` arrives.** No rows are written, so
  there is nothing to project. This is deliberate rather than overlooked: by June 2027 every reminder
  a February lambing would have raised is months past, and writing rows nothing reads is a §12 shape
  the project does not use anywhere else.

### N28 — Season Summary (6 tasks)

**What waits.** Lambing percentage with its definition, litter size, barren and assisted rates,
losses by cause and age, the spread chart, season comparison.

**What covers it.** `v1.0.0`'s three CSV shapes — one row per lamb, per ewe, per treatment — carry
every number this screen derives. A shepherd who wants their lambing percentage in April 2027 opens a
spreadsheet, and `05 §6` is explicit that the same season reads **120% / 100% / 80% / 200%** under
four legitimate published definitions, so a shepherd computing it themselves is choosing the one they
already quote over a gate.

**And the last task cannot run in `v1.0.0` anyway.** N28-T05 is *comparison against previous seasons
once they exist* — there are none in a first season, by construction.

### N21-T04, T05 — the two PDFs (2 tasks)

**What waits.** The flock book in two volumes and the medicine record PDF, on a `compute` isolate
with a mandatory embedded TTF.

**What covers it.** The medicine record ships as **CSV** in `v1.0.0`, with the same §12.1, §12.3 and
§12.5 trailers, emitted by the writer's own frame. It opens and prints from any spreadsheet. §12.3
forbids presenting the app as a compliance record in either format, so the PDF is a nicer artefact,
not a different claim.

**And it takes a dependency out of the release that first makes the offline claim.** `pdf` 3.13.0
leaves `v1.0.0`'s graph entirely — one fewer line in `tool/policy_allowlist.txt`'s `[dependencies]`
section, one fewer package for G2 and G3 to reason about, and a smaller binary against #127's size
budget, in the release where the offline-purity argument is made to a store reviewer for the first
time.

### N26-T05, T06 — note search (2 tasks)

**What waits.** `noteSearchProvider`, the app's only FTS5 query, its only 200 ms debounce, hit
rendering and the thirteenth route.

**What covers it.** Notes are on the Ewe Card and the Lamb Card, which both ship in `v1.0.0`.

**And this one costs nothing at all, which is checkable rather than asserted.** `lib/core/db/search.drift`
keeps `search_docs` and `search_fts` in step through **SQL triggers, not Dart** — five source-table
trios, and the file says why: *"a Dart projection is one repository method away from being skipped,
and a note that is not in the index is a note the shepherd cannot find."* The index is therefore
maintained by `v1.0.0` with no code and no task, so **`v1.1.0`'s search finds every note written in
the 2027 season.** Nothing is backfilled because nothing was missed.

### N29-T03, T06 — terminology editing and the two deletes (2 tasks)

**What waits.** Editing *ewe → gimmer / shearling / theave / hogget* through `terminology_overrides`;
delete a season, and delete everything.

**What covers it.** The authored defaults ship in `v1.0.0` and every screen already reads
`terminologyProvider` (in the DI graph since N12-T02), so the labels are correct for the region the
owner ruled first — they simply cannot be changed yet. And `v1.0.0`'s honest answer to *delete
everything* is **uninstall**: with no account and no server, that genuinely is all of it, which is a
sentence the About screen can print without qualification.

**Deleting a season is the one that has to wait for a reason rather than a preference:** it is
destructive, irreversible, guarded at four taps by `07 §14.4`, and there is no season worth deleting
in a first season.

---

## 5. The five constraints that make the split reversible

A deferral is only cheap if `v1.1.0` can add the feature without asking a shepherd to do anything.
These are the places where `v1.0.0` has to be built for a release it does not contain, and each one is
load-bearing.

### 5.1 The backup format ships **complete** in `v1.0.0` — all 21 tables

This is the most important line in this document.

N22 serialises **every restorable table, including `reminders`, `reminder_rules` and the ones no
`v1.0.0` screen reads.** They are empty; they are still in the envelope, still in the header's table
list, still in the canonical encoder's ordering.

The reason is `04 §7`'s own asymmetry. N22-T03's forward-compatibility contract carries an unknown
**column** through `unknown_json` and back out; **it does not carry an unknown table.** So a `v1.0.0`
backup written without `reminders` and restored into `v1.1.0` would be a restore that has to invent a
missing table, on the one code path where a bug loses five seasons — and it would be discovered by a
shepherd, in June, on a new phone.

Ship the format whole and there is no format change between the two releases at all: **a backup
written by `v1.0.0` restores into `v1.1.0` byte-for-byte unchanged**, and N23-T07's
export→import→export equality property holds across the boundary rather than up to it.

### 5.2 `android/expected_permissions.txt` is `v1.0.0`'s set, and the delta is written down now

G1 asserts **set equality** against the shipped `.aab` on every push. `v1.0.0`'s set is strictly
smaller than the one the doc set currently anticipates, because reminders are what add
`POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` and `SCHEDULE_EXACT_ALARM`.

N31-T01 writes the **`v1.0.0`** set. It must also write, in the same file, the three lines `v1.1.0`
will add and the epic that adds them — because the day G1 goes red is the day somebody has to decide
in five minutes whether a permission appeared because we added a feature or because a dependency did,
and decision-record §3.2 is built on that being answerable from a file rather than from memory.

**This is a gain for `v1.0.0`, not a cost.** The release that first argues offline purity to a store
reviewer, a shepherd and a forum ships with three fewer permissions than planned.

### 5.3 The store listing describes `v1.0.0` and nothing else

N32-T02 drafts the listing while `v1.1.0` is a written plan, which is exactly when a listing acquires
a feature the build does not have. Reminders are the specific risk: they are in spec §7.6, they are
the most screenshot-able thing in the backlog, and they are not in the binary.

The §3.1 offline wording is unaffected and stays verbatim — it is a statement about what the app
*cannot* do, and `v1.0.0` can do even less of it.

### 5.4 The overflow matrix is **eleven** variants in `v1.0.0`, not fourteen

N33-T01 says *"its final fourteen entries"* and a 252-cell matrix. Three variants are deferred with
their screens — Reminders, Season Summary, Note Search — so `v1.0.0`'s matrix is **eleven variants ×
18 cells = 198**, and `v1.1.0` grows it to fourteen.

The membership test is derived from the built screens rather than from a literal precisely so this
cannot be silently wrong (`test/features/overflow_matrix_test.dart`), and it is the mechanism that
will fail loudly if a deferred screen is half-landed.

### 5.5 `v1.1.0` is built during the freeze and is therefore built without a safety net

From 1 February 2027 nothing ships except a defect that destroys records or prevents the app opening.
That is four months of development against a `main` that **cannot be released**, so every gate that
normally catches a mistake before a shepherd does has to already exist: the eight goldens (N33-T07),
`goldens.yml` (N33-T09), the four integration journeys (N33-T08) and the geometric tap-target gate
(N33-T03).

All four are in `v1.0.0`, and this is why none of them was deferred despite none of them being a
feature. **`v1.1.0`'s regression armour has to ship before `v1.1.0` starts.**

---

## 6. The order the work runs in now

The chain was strictly linear, so removing three epics from the middle re-cuts it. Two `Depends on`
rows change and nothing else does.

### `v1.0.0` — eleven pull requests

```
N21 (six tasks) → N22 → N23 → N26 (five tasks) → N27 → N29 (six tasks)
    → N30 → N31 → N32 → N33 → N34 → tag v1.0.0
```

| Epic | Was | Now | Why the edge is real, or why it was only sequence |
|---|---|---|---|
| **N26** | depends on N25 | **depends on N23** | The old edge was linear order alone. Flock reads `ewes` and the filters, neither of which N24 or N25 touches |
| **N29** | depends on N28 | **depends on N27** | Same. Settings composes over `SettingsRepository`, built at N12-T02 |
| **N30** | depends on N29 | unchanged, and it is a **real** edge | N30-T04 wires the entitlement source into the two gated verbs, and one of them is `startSeason` — which is N29-T05 |

### `v1.1.0` — six pull requests, in this order

```
N24 → N25 → N28 → N21-B → N26-B → N29-B → tag v1.1.0
```

The three tails keep their task files where they are and take a branch of their own, so the
one-pull-request-per-epic rule survives: `epic/n21b-pdf-export`, `epic/n26b-note-search`,
`epic/n29b-terminology-and-deletes`.

N24 first, and not because it is the largest: it is the only one that touches write transactions that
already exist, and it is the one whose fixtures (N24-T08) every later branch reads.

---

## 7. The one further cut available, and what it costs

If the December date starts slipping, there is exactly one more coherent line to draw, and it is
worth naming in advance so it is a decision rather than a panic.

**Defer N26 Flock and N27 Ewe Card as well — twelve tasks — and `v1.0.0` becomes the shed and
nothing else.**

**What makes it survivable.** Every animal is still reachable: `tagIndexProvider` ranks
412 · 128 · 12 in the same frame as you type `12` on Quick Entry's keypad, so the Flock list is a
*browse* screen rather than the only door. *"Is 412 clear?"* is answered by the Treatments RUNNING
segment and by the pen board's withdrawal tile. Spec §15's own success criterion puts the recall
moment in the **second** season — February 2028 — and `v1.1.0` lands in June 2027, well before it.

**What it costs, and why it is not the recommendation.** The Ewe Card is the first paragraph of this
product's description — *"in year two, what did 412 do last year? takes one second instead of an
evening with a shoebox"* — and it is the wedge against the incumbents. Shipping `v1.0.0` without it
means the store listing cannot make the claim the product is sold on, into the one season anyone is
looking. A livestock app whose first release cannot list your livestock also collects a particular
kind of one-star review that outlives the release.

**Take this cut only if the alternative is missing 1 February 2027 entirely** — because missing that
date costs a year, and this costs a listing paragraph for five months.

---

## 8. What this document does not do

- It does not move anything into or out of **spec §13**. Nothing here is cut; everything here ships.
- It does not touch the **schema**. All 23 tables were frozen at N07-T08 and every deferred screen
  reads tables that already exist — which is why deferring them is possible at all, and is decision
  #37's forward-only rule paying for itself.
- It does not change the **five safety rules**, the **3am floor** or the **offline claim**. §12.1's
  three withdrawal states, the 60 × 60 pt target, the 18 pt floor and the §3.1 wording are identical
  in both releases.
- It does not answer decision-record §7.1 item **9** — *"does the app replace the paper record
  entirely, or sit alongside it for the first season?"* — but it does bind it: `v1.0.0` ships CSV and
  no flock-book PDF, so for the 2027 season the honest answer is **alongside**, and the listing and
  the Export screen should say so in those words.

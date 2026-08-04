# 07 — Screens

This document is the brief for all twelve screens in spec §9: what each one is for, the single query that feeds it, every state it can be in including empty and over-cap, every action with its tap cost, and which spec §12 disclosure appears where. It also settles three things that cut across screens and were previously scattered or missing: undo semantics per verb, the end-of-day export banner, and how the Reminders screen reconciles SQLite (the truth) with the OS notification centre (a windowed cache). Read `06-design-system.md` for how a control looks and `01-architecture.md` for how a write happens; this document decides *what is on the screen and what it costs the shepherd*.

> **Decisions applied:** #8 (feature-first UI folders), #11 (event-verb writes, no draft state, no Save button), #12 (one watched statement per screen, no `combineLatest`), #13 (`WriteOutcome`), #21 (first frame is an interactive Quick Entry shell), #22 (`WriteController.guard()`), #23 (`Navigator` + typed route helpers), #24 (no state restoration), #35 (in-memory tag match, FTS5 on its own screen), #42 (first-run season, lazy pens), #43 (`CareEvents` as `EXISTS`), #44 (`EweObservations`), #50 (`WarningCode.clearDateDisagrees` shown, never applied), #51 (`WithdrawalPeriod` three states), #53 (`RecordedTime` provenance), #54 (warnings are a return type, not a column), #58/#59 (`StatResult`, statistic definitions), #60 (`customSelect` + `readsFrom:` for aggregates), #62 (`Disclaimers` referenced, never re-typed), #63/#64 (reminder reconcile + the honest line), #66 (one 60 s app ticker), #67 ("in the pens" shares the pen projection), #68 (`ewe_touches`), #69 (undo per verb), #70 (hand-rolled spread chart), #71 (empty states are the onboarding), #72 (in-app export banner), #73 (replace-everything restore), #86 (export never gated), #90/#92 (no monetization on the shed screens; two static rows), #91 (`EntryContext.liveEntry` cannot be blocked), #100/#101 (60 pt floor, gesture ban), #103 (commit-then-confirm), #104 (`headingLevel`), #106 (colour is never the only channel), #114 (overflow + reachability matrix), #120 (tap-budget tests). Owner rulings §7.0: tag OCR and voice tag entry cut; tags unique among **active** animals only; UK/Ireland defaults (en_GB, kg, °C, 24 h, `d MMM y` on screen and `dd/MM/yyyy` only where a numeric date is required, Monday, ambiguous DST hour 01:00–01:59, AHDB percentage); free tier **season-primary, ewe cap secondary, never mid-entry, never 22:00–06:00**.

---

## 1. How to read a screen brief

### 1.1 The index

| # | Screen | Route helper | Feature folder | Content query | Shed screen? |
|---|---|---|---|---|---|
| 1 | Flock | `Routes.flock(context)` | `lib/features/flock/` | `flockListQuery` | no |
| 2 | Ewe Card | `Routes.eweCard(context, id)` | `lib/features/flock/` | `eweTimelineQuery` | no |
| 3 | **Quick Entry** | root route, never pushed | `lib/features/quick_entry/` | `quickEntryDeckQuery` | **yes** |
| 4 | Lambing Entry | `Routes.lambingEntry(context, id)` | `lib/features/lambing/` | `lambingEntryQuery` | **yes** |
| 5 | Lamb Card | `Routes.lambCard(context, id)` | `lib/features/lambing/` | `lambCardQuery` | **yes** |
| 6 | Foster | `Routes.foster(context, lambId)` | `lib/features/lambing/` | `quickEntryDeckQuery` (reused) | **yes** |
| 7 | **Pen Board** | `Routes.penBoard(context)` | `lib/features/pens/` | `penBoardQuery` | **yes** |
| 8 | Treatments | `Routes.treatments(context)` | `lib/features/treatments/` | `treatmentsQuery` | no |
| 9 | Reminders | `Routes.reminders(context)` | `lib/features/reminders/` | `remindersQuery` | no |
| 10 | Season Summary | `Routes.seasonSummary(context, id)` | `lib/features/season/` | `seasonFactsQuery` | no |
| 11 | Export | `Routes.export(context)` | `lib/features/export/` | `exportCountsQuery` | no |
| 12 | Settings | `Routes.settings(context)` | `lib/features/settings/` | `settingsProvider` (single row) | no |

Nine feature folders, twelve screens (decision #8). **"Shed screen" means nothing monetization-related may render on it, at any entitlement state, ever** (decision #92) — enforced by the widget test in §21.2.

**One route exists that is not a spec §9 screen:** note search, `Routes.noteSearch(context)` → `RouteNames.noteSearch` (already declared in `02-state-di-navigation.md` §8.1), in `lib/features/flock/`. It is described in §18. It is pumped by the overflow matrix like any other screen, which is why the matrix is 14 variants and not 12 (§21.2).

### 1.2 The one-query rule, stated exactly

Decision #12 says one SQL statement per screen. The precise form, because three screens legitimately watch more than one thing:

> **Every screen has exactly one *content* statement** — the one that produces its list, grid or timeline. Anything else it watches must be (a) a single-row lookup, or (b) an app-level singleton (`settingsProvider`, `entitlementProvider`, `tagIndexProvider`, `minuteTickProvider`). **No displayed value may be computed from two drift streams.** If two streams have to agree for the screen to be correct, they are one statement.

That is the enforceable version of the drift#3338 rule: torn emission only hurts when you combine. Two independent widgets watching two independent streams is fine; `combineLatest` over drift streams is a build-breaking defect (§21.1). Fan-in happens **in SQL** — `WITH … UNION ALL` — not in Dart.

Every aggregate or `GROUP BY` goes through `customSelect` with an explicit `readsFrom:` (decision #60). Never `groupBy` inside a Dart-defined drift view.

### 1.3 Counting taps

A **tap** is one pointer-down/up on a target of at least 60×60 pt. Counting starts with the screen already pushed and its first frame painted; **the tap that navigated here is not counted**. Digits typed on the keypad count individually (a 3-digit tag is 3 taps). Scrolling is not a tap. There are no gestures to count: no swipe, drag, long-press, pinch or force touch exists anywhere (decision #101).

Three tap budgets are asserted in CI (decision #120, `test/features/tap_budget_test.dart`, keyed finders):

| Journey | Budget | Spec claim being held |
|---|---|---|
| Unlock → committed lambing for a ewe already in the flock | **6 taps** | §15 "Median time from unlock to a saved lambing event is under 15 seconds." |
| Foster: reassignment measured from the Foster screen | **1 tap** (2 including opening it) | §7.3 "move a lamb to a different ewe in two taps… This is the flow most likely to be abandoned if it takes five taps." |
| Repeat last treatment onto another animal | **2 taps** | §7.5 "Repeat-last-treatment shortcut for treating a batch." |

Every number in the tap tables below is a **desk estimate until the field night happens** (§7.1 open question 1, §22). The three budgets above are the only ones CI holds; the rest are design intent and are labelled as such.

### 1.4 The state vocabulary

Every brief lists the same states. If a brief omits one, the state is impossible and the brief says why.

| State | What it means | House rule |
|---|---|---|
| **Frame 1** | Painted before the database is open (decision #21) | A fixed-height placeholder in the same surface colour. **Never a spinner.** No layout shift when data lands. |
| **Loaded** | The normal case | — |
| **Empty** | Query returned zero rows | Occupies the same box the content will occupy; one line of 18 pt copy; exactly one 60 pt action, which is the same control the populated screen uses (decision #71) |
| **Filtered-empty** | Rows exist, the filter excludes them | Different copy from Empty, and the action is "Clear filters" |
| **Error** | A read threw (decision #13) | Dark panel, one 18 pt line naming what could not be read, 60 pt "Try again", 60 pt "Diagnostics". Never the exception message (decision #124). Never red-on-yellow (decision #14). |
| **Over-cap** | Free tier, past the ewe cap or at the season wall | On 7 of 12 screens the answer is **nothing renders**. See §19. |

### 1.5 The §12 disclosure matrix

| Screen | §12.1 "as entered by you" | §12.5 time provenance | §12.3 not-a-regulatory-record | §12.4 warning badge |
|---|---|---|---|---|
| 1 Flock | — | — | — | ✓ row badge |
| 2 Ewe Card | ✓ on any withdrawal in the timeline | ✓ every timeline row | — | ✓ row badge |
| 3 Quick Entry | — | ✓ in the commit SnackBar | — | — |
| 4 Lambing Entry | — | ✓ header, always visible | — | ✓ ~~60 pt amber strip~~ query mark + underline (N16-T06) |
| 5 Lamb Card | — | ✓ birth time and death date | — | ✓ |
| 6 Foster | — | ✓ on the foster event | — | ✓ `fosterToSelf` |
| 7 Pen Board | — | ✓ edited-entry marker **on the tile** | — | ✓ tile badge |
| 8 Treatments | ✓ every withdrawal figure + the caveat above the entry control | ✓ administered-at | ✓ footer of the medicine-book segment | ✓ `clearDateDisagrees` |
| 9 Reminders | — | ✓ on the source event's time | — | — |
| 10 Season Summary | — | — | — | ✓ caveats per stat |
| 11 Export | ✓ on the treatment/medicine rows | ✓ one line explaining the exported columns | ✓ verbatim, above the buttons | — |
| 12 Settings | — | — | ✓ in About, and in the unlock copy | — |

§12.2 ("never give veterinary advice") is a *negative* and therefore appears nowhere as a label. It binds as copy discipline on every screen: the app may arithmetic-transform a number the user supplied and may never originate a number that is a clinical decision. "Ready to turn out" is a *user-set threshold* and is labelled as the user's own (§9.7). "32 of 48 ewes lambed in the first 17 days" is a fact; "your tupping was tight" is a judgement and is banned.

Strings: `Disclaimers.exportFooter`, `Disclaimers.withdrawalProvenance` (`'as entered by you'`), `Disclaimers.withdrawalCaveat` are `const`s in `lib/domain/policy/disclaimers.dart`, **referenced and never re-typed** (decision #62). Time labels come from `RecordedTime.provenanceLabel`, which is an exhaustive switch and can never be empty (decision #53): `recorded automatically` / `time entered by you` / `time edited by you`.

**The §12.5 precondition, settled by `CONVENTIONS.md` R37.** A row can only carry a provenance label if its table carries the four columns `occurred_at` (or the entity's event-time column) + `captured_at` + `original_effective` + `time_source`. `05-domain-correctness.md` §4.2 names the entities that must carry the quad: `Lambings`, `Treatments`, `CareEvents`, `FosterEvents`, `Notes`, deaths. `03-data-model-and-schema.md` §5 shipped it on **only three** — `Lambings`, `CareEvents`, `Treatments`. R37 rules that doc 03 adds it to **`PenOccupancies`, `FosterEvents`, `Notes` and `EweObservations` as well**, plus a `notes.occurred_at` distinct from the mixin's `created_at`, **before the first schema snapshot** — because every one of them appears on a timeline row (§4.4) and the pen entry time appears on a tile the shepherd trusts (§9.6). Until it lands, the rule is absolute and stated in one line: **a table without the quad has no edit verb.** An auto label is only honest if the value is physically unable to have been edited.

Column spelling: the column is `original_effective` (Dart `originalEffective`) everywhere, per `CONVENTIONS.md` §4.6. There is no `original_effective_at`.

### 1.6 Resume and restoration

There is no state restoration (decision #24). Two rules, both screen-visible:

1. **Backgrounded longer than 2 minutes → the Navigator resets to Quick Entry with nothing selected.** Under 2 minutes the route stack is untouched. Restoring a stale selected ewe at 3am is a data-integrity bug.
2. **After process death you land on Quick Entry, empty.** No in-flight anything is rebuilt — in particular no undo affordance is ever reconstructed from storage (§15.4).

### 1.7 Headings and semantics

Every section heading uses `headingLevel: 1..6`; `Semantics(header: true)` is a no-op since 3.44 and is banned in review (decision #104). Ewe Card and Season Summary get a real hierarchy so a screen-reader user can jump straight to the §7.7 summary line, which is the retention feature.

---

## 2. First run — the only onboarding there is

Spec §5 bans onboarding after first run. The reading that ships: **there is no onboarding at all, and the empty states are the teaching surface** (decision #71).

### 2.1 What actually happens on the very first launch

1. `main()` awaits nothing; the first frame is the dark Quick Entry shell with a **fully interactive keypad and no data** (decision #21).
2. The database opens on the first post-frame callback. Its `onCreate` inserts one `Season` from the device clock — `year = now.year`, `label = "<year> lambing"`, `startDate = today` — and sets `app_settings.current_season` to it **in the same transaction** (decision #42). The user is asked nothing.
3. Pens do not exist yet. They are created lazily on first use (§9.5).
4. **No permission is requested.** Not notifications (§11.5), not camera or microphone (first photo/voice tap), not billing (Unlock/Restore only).
5. The two static upgrade rows (Flock, Settings) render from launch #1, at 0 ewes exactly as at 15 (decision #92) — subject to the 22:00–06:00 rule in §19.
6. Nothing else. No tour, no sample flock, no "what's new", no rating prompt.

**Acceptance test:** on a fresh install, a lambing can be recorded for a brand-new ewe without ever opening Settings. `integration_test/first_run_journey_test.dart`.

### 2.2 The empty-state table

One row per screen. Never a spinner, never an illustration, never a multi-step tour.

| Screen | Empty copy | The single action |
|---|---|---|
| 1 Flock | "No animals yet." | "Add a ewe" (the same bottom-bar button the populated screen has) |
| 2 Ewe Card | "Nothing recorded for 412 yet." | "Record a lambing" |
| 3 Quick Entry | **Never empty** — the keypad works at frame 1 | pens strip: "Nothing penned yet." · recents strip: "No recent animals." |
| 4 Lambing Entry | **Never empty** — the row exists before the screen does. Lambs list: "No lambs recorded yet." | "Add a lamb" |
| 5 Lamb Card | **Never empty.** History section: "Nothing else recorded." | — |
| 6 Foster | "No other animals yet." | keypad; confirm key reads "Create 412". The two no-ewe targets are present even here — a bottle lamb needs no other animal to exist |
| 7 Pen Board | Zero pens: "No pens yet." · Pens but none occupied: "No animals penned." | a single 72 pt "Add a pen" tile · tap any tile to pen a ewe |
| 8 Treatments | "No treatments recorded." · countdowns segment: "Nothing under withdrawal." | "New treatment" |
| 9 Reminders | "No reminders. Reminders are created when you record a lambing or a treatment." | "Reminder intervals" |
| 10 Season Summary | "Nothing recorded in 2026 lambing yet." | "Quick Entry" |
| 11 Export | "Nothing recorded yet." — buttons stay live; a 0-row CSV still carries its disclaimer trailer | — |
| 12 Settings | **Never empty** — the `app_settings` row exists from `onCreate`. Diagnostics: "No events recorded." | — |
| — Note search | No query yet: "Type to search notes." · No notes exist at all: "No notes recorded yet." · Query with no match: "No notes match 'watery'." | "Clear", on the third only |

Three distinct strings on note search, not one. "No notes recorded yet" and "no notes match this" are different facts, and a shepherd who sees the wrong one concludes the app lost their notes.

**Anti-pattern:** a `CircularProgressIndicator` anywhere in `lib/features/**`. `tool/check_policy.dart` bans the identifier outright; loading is a fixed-height placeholder or it is nothing.

---

## 3. Screen 1 — Flock

**Purpose.** Find any animal, filter the flock by anything, and add a ewe. This is the daylight screen — it is where you stand in the yard at 11am, not where you stand at 03:20.

### 3.1 The query

`flockListQuery` — one `customSelect`, ewes joined to their precomputed `ewe_summaries` row and to the status booleans the §7.7 filters need.

```sql
-- Column names are doc 03's. ewe_summaries stores COUNTS ONLY: the §7.7
-- sentence "3 seasons · avg 2.0 · assisted twice" is assembled in Dart from
-- these numbers with the terminology overlay and the locale applied. A
-- formatted string in the database would freeze both (03 §5.13).
SELECT e.id, e.tag, e.tag_digits, e.status,
       s.seasons_recorded, s.lambings_recorded, s.lambs_born, s.lambs_born_alive,
       s.assisted_lambings, s.scored_lambings, s.last_observation_season,
       EXISTS (SELECT 1 FROM pen_occupancies o
                WHERE o.ewe = e.id AND o.exited_at IS NULL)          AS is_penned,
       (SELECT MAX(w.clear_date) FROM treatments t
          JOIN treatment_withdrawals w ON w.treatment = t.id
         WHERE t.ewe = e.id AND t.voided_at IS NULL
           AND w.kind = 'days')                                      AS latest_clear_date,
       EXISTS (SELECT 1 FROM treatments t
                WHERE t.ewe = e.id AND t.voided_at IS NULL
                  AND NOT EXISTS (SELECT 1 FROM treatment_withdrawals w
                                   WHERE w.treatment = t.id))        AS unrecorded_withdrawal,
       EXISTS (SELECT 1 FROM lambing_consistency lc
                 JOIN lambings lg ON lg.id = lc.lambing_id
                WHERE lg.ewe = e.id AND lc.is_mismatched = 1)        AS has_warning
  FROM ewes e
  LEFT JOIN ewe_summaries s ON s.ewe = e.id
 ORDER BY (e.status <> 'active'), e.tag_digits, e.tag;
```

**RULING N3 (N26-T03) — the §12.4 badge is a word, not an icon.**

This section said *"icon + count, never colour alone"*. There is no icon set in this product: `indelible.md §1.3` lists *"no icon set — every action is a word"* among the things the system does not have, and `06 §12` specifies `ShedStatusBadge` as *"a stamp set in words, not an icon-plus-word"*. `CLAUDE.md`'s authority order puts `indelible.md` above the thirteen engineering documents, so the word wins and this row is corrected.

The two non-colour channels §1.2 rule 3 requires are the **word** and the **form**: `QUERIED` is unboxed because it is a note about the writing, `CULLED` is boxed because it is a state of the sheep, and `indelible.md §7.7` says you must be able to tell which from ten feet. Both stamps were already in the design's own lists; neither is a new mark, so §6.3's six-mark budget is untouched.

`test/features/flock_test.dart` asserts on the rendered TEXT, so an icon-based badge fails it.

**RULING N2 (N26-T03) — `WHERE e.status = 'active'` is struck from this statement.**

It contradicted `indelible.md §7.4`, whose **Struck** state reads *"She stays in the list, at the bottom, under a printed line reading `STRUCK — 1`."* Both could not ship. `CLAUDE.md`'s authority order puts `indelible.md` above the thirteen engineering documents, so the design wins — and two further arguments point the same way. The design system's **first rule** is *nothing is ever removed, only struck*, so filtering her out is that rule inverted at the data layer; and N26-T03's Definition of Done — *a culled tag is visibly distinct from an active one with the same number* — is unsatisfiable if the struck row never renders.

She is also what makes §7.0 ruling 7 legible: tags are unique among **active** animals only, so one tag appears twice and the struck row is the reason that is legal rather than a bug (`03 §6`: they are two animals, *"a link, never a merge offer"*).

The ordering clause carries it: active first, struck last, tag order within each. `test/features/flock_test.dart` holds both halves — that she is present, and that no active row is printed below her.

**RULING N1 (N26-T02) — the two columns above replaced a single `under_withdrawal` `EXISTS` whose predicate was `w.kind = 'days' AND w.clear_date >= :today`, and it was wrong twice.**

*An unrecorded withdrawal is **unknown**, never clear.* The old predicate INNER JOINed `treatment_withdrawals`, so a ewe injected yesterday whose withdrawal nobody typed had nothing to join to and vanished from the *under treatment* filter — the app answering a withdrawal question on the shepherd's behalf, which is spec §12.1's exact shape and the thing `03 §5.8`'s child table already refuses at the storage layer. `unrecorded_withdrawal` names that state so the screen can say `— NOT RECORDED` rather than nothing.

*And no date may be bound into this statement.* `watch()` binds its variables **once**, when the stream is built, and drift re-runs the same prepared statement with the same arguments on every table change — so a phone left on the flock page overnight goes on filtering against yesterday, and the ewe who cleared at midnight stays listed as running. Decision #47 bans SQL-side time; a Dart date frozen into a long-lived statement is the same defect wearing a Dart hat. Both columns are clock-free and the comparison happens in Dart, where `now` is a parameter (R24) and advances. `test/policy/flock_filter_never_implies_a_withdrawal_test.dart` holds all three halves.

Consequently **four of the five §7.7 filters narrow the `WHERE`; `under treatment` is applied in Dart** against these two columns.

`readsFrom: {ewes, eweSummaries, penOccupancies, treatments, treatmentWithdrawals, lambings, lambs}`. `clear_date` is a `TEXT 'YYYY-MM-DD'` civil date computed in Dart at write time (decision #2, #50) — the one wall-clock reader in the app (`lib/core/time/app_clock.dart`), and SQL-side time is banned (decision #47), and `clear_date` is a `TEXT` civil date (decision #2), so the comparison is a lexicographic string comparison and is correct only because the format sorts.

**There is no `warning_count` column and there never will be** (decision #54): a warning cannot be persisted because there is nowhere to persist it. `has_warning` is read from the `lambing_consistency` **view** (doc 03 §5.4), which recomputes on read. The remaining warning codes that can badge a Flock row — `duplicateActiveTag` in particular — are computed in Dart from the same active-tag cache the keypad uses; they are not in this statement because they are not in the database.

**Filters are SQL; the search box is Dart.** The five §7.7 filters (barren, not yet lambed, triplet-bearing, currently penned, under treatment) narrow the `WHERE`. The text box narrows the *streamed* rows in Dart using `rankTagMatches` from **`lib/domain/tag_match.dart`** — the same pure function the keypad uses (decision #35), one implementation, two call sites. It must live in `lib/domain/`, not in `lib/features/quick_entry/`: the layer rule in §21.1 forbids one feature folder importing another, so a copy in `quick_entry/` would make the Flock call site illegal. `03-data-model-and-schema.md` §9.1 shows the body under a `lib/features/quick_entry/tag_matcher.dart` path; `CONVENTIONS.md` R27 rules that path out in favour of `lib/domain/tag_match.dart` (§22 item 6). Note search is not here; it is FTS5 on its own screen, reached from the Flock app bar.

### 3.2 States

| State | Rendering |
|---|---|
| Frame 1 | Six fixed-height dark row placeholders |
| Loaded | Rows: tag (32 pt tabular) · summary line (18 pt, assembled in Dart from the counts) · status chips (icon + text, never colour alone) |
| Empty | "No animals yet." + "Add a ewe" |
| Filtered-empty | "No animals match these filters." + "Clear filters" |
| Error | Standard dark error panel |
| **Over-cap** | The static row, pinned top, always in the same pixels: `Free version · covers this season · 22 of 15 ewes · Unlock once for <store price>`. Season first, ewe cap second — that is the owner's ruling (§7.0 #8), and a row that leads with the ewe cap states the secondary gate as though it were the primary one. No colour change, no badge, no exclamation mark. Hidden entirely 22:00–06:00 (§19). |

**The price is never a literal in this codebase.** `<store price>` is `ProductDetails.price` from `in_app_purchase` — the store's own localized, tax-inclusive string. The exact price is still open (§7.1 #4: "€10–15 is a range"), a hard-coded figure would be wrong in every non-euro territory, and both stores require the displayed price to be the one they quote. `tool/check_policy.dart` bans a currency symbol followed by digits in `lib/` and `assets/`.

### 3.3 Actions

| Action | Taps | Notes |
|---|---|---|
| Open a ewe card | 1 | writes an `ewe_touches` row (decision #68) |
| Toggle a filter | 1 each | filter chips are 60 pt, in a horizontally scrolling row |
| Search by tag | 1 per digit | in-frame, synchronous, no debounce, no spinner |
| Add a ewe | 1 to open + digits + 1 confirm | `EntryContext.calm`. Over the cap this returns `BlockedByCap` and navigates to Unlock — the only self-navigation to Unlock in the app, and it is a response to the user's own tap. Between 22:00 and 06:00 it degrades to `Allow(overFreeCap: true)` and creates the row (§19.3) |
| Search notes (FTS5) | 1 to open the search screen | 200 ms debounce lives there, never here |

**Typing a tag that an active animal already holds** raises `WarningCode.duplicateActiveTag` — "412 is already in use by an active ewe." — as ~~a 60 pt amber strip under the field~~ **the query mark and underline ruled at N16-T06** (see §6.3's amendment: Indelible has no status palette, so there is no amber to build a strip from). It **never blocks the create**, because tags are unique among active animals only (§7.0 ruling 7) and the partial unique index is what enforces uniqueness; the warning is there so the shepherd sees the collision, not so the app refuses the entry. A tag held only by a culled or sold animal raises nothing at all: that tag is free.

> **Amended — ruling N4 (N26-T04), and what "never blocks" turns out to mean.** This paragraph and `03 §6`'s partial unique index `ON ewes (tag) WHERE status = 'active' AND struck = 0` were carried by `00-README` §10 as an open contradiction. **Both sentences are true, about different cases**, because the index is on `tag`, the *exact string*:
>
> - `412` and `B412` are **different tags with the same digits**, both storable, both ranked together by the pad. That is the genuinely ambiguous case, it is what `duplicateActiveTag` is for, and it never blocks anything.
> - A **second live `412`** is not ambiguous, it is identical, and it makes *"what did 412 do last year?"* — the question the product exists to answer — unanswerable. It is refused, as `TagAlreadyInUse`, checked inside the create's own transaction so the shepherd gets a sentence naming the tag rather than a crash from the index.
>
> The resolution is **geometry, not prose**: the add sheet's confirm bar takes its label from the match state, so it reads `Open 412` while an active 412 exists and `Create 412` only when the tag is free. There is no create to block, which is what keeps §12.4 at *unconstructible* rather than dropping it to *documented*.
>
> ~~"navigates to Unlock"~~ **does not land in N26.** Unlock is a **Settings section**, not one of the thirteen `RouteNames`, and Settings is N29; the over-cap refusal renders as a row through `showCapRow` (decision #92 — no modal, no interstitial, no navigation). The pixels are N30-T05's.

### 3.4 §12 on this screen

Only §12.4: a small persistent badge on any row whose records carry warnings, so a contradiction found at 3am is still findable at 9am. The badge is a WORD, never colour alone — see ruling N3 below.

No §12.1 and no §12.5 label appears here: the Flock row shows no withdrawal figure and no event time. The summary line is a count, not a time.

---

## 4. Screen 2 — Ewe Card

**Purpose.** Answer "what did 412 do last year?" in one second. This is the retention feature; spec §15 makes opening it in season two the moment the app becomes irreplaceable.

### 4.1 The query

Header: a single-row watch of `ewe_summaries` (counts, precomputed on write — the summary line must never wait for an aggregate). The **sentence** is assembled in Dart; the table holds no formatted string (doc 03 §5.13).

Content: `eweTimelineQuery`, one `customSelect` that unions every table that can say something about her into one shape. Four columns are load-bearing and identical on every arm: `kind`, `ref`, `at` (the event instant, epoch millis) and the §12.5 triple `captured_at` / `original_effective` / `time_source`.

```sql
-- Column names are doc 03's. Every arm projects the same seven columns; the
-- result names come from the left-most SELECT.
SELECT 'lambing' AS kind, lg.id AS ref, lg.occurred_at AS at,
       lg.captured_at, lg.original_effective, lg.time_source, lg.season AS season
  FROM lambings lg WHERE lg.ewe = :ewe

UNION ALL
SELECT 'treatment', t.id, t.administered_at,
       t.captured_at, t.original_effective, t.time_source, t.season
  FROM treatments t WHERE t.ewe = :ewe

-- care_events has NO `ewe` column: the CHECK is exactly one of (lambing, lamb).
-- Her care events are reached through her lambings and through the lambs she bore.
UNION ALL
SELECT 'care', c.id, c.occurred_at,
       c.captured_at, c.original_effective, c.time_source, c.season
  FROM care_events c
  LEFT JOIN lambings lg2 ON lg2.id = c.lambing
  LEFT JOIN lambs   lb2  ON lb2.id = c.lamb
 WHERE lg2.ewe = :ewe OR lb2.birth_dam = :ewe

-- foster_events has NO to_ewe/from_ewe columns: it has ONE rearing_dam plus an
-- outcome. "She lost a lamb to a foster" is the PREVIOUS rearing dam, which is
-- the LAG of rearing_dam over the lamb's own event order. SQLite has had window
-- functions since 3.25; we bundle 3.5.0 (decision-record §5.1), so this is safe.
UNION ALL
SELECT 'foster', f.id, f.effective_at,
       f.captured_at, f.original_effective, f.time_source, f.season
  FROM (SELECT fe.*,
               LAG(fe.rearing_dam) OVER (PARTITION BY fe.lamb
                                         ORDER BY fe.effective_at, fe.id) AS prev_dam,
               lb.birth_dam AS lamb_birth_dam
          FROM foster_events fe JOIN lambs lb ON lb.id = fe.lamb) f
 WHERE f.rearing_dam = :ewe
    OR f.prev_dam = :ewe
    OR (f.prev_dam IS NULL AND f.lamb_birth_dam = :ewe)

UNION ALL
SELECT 'observed', o.id, o.occurred_at,
       o.captured_at, o.original_effective, o.time_source, o.season
  FROM ewe_observations o WHERE o.ewe = :ewe

UNION ALL
SELECT 'penned', p.id, p.entered_at,
       p.captured_at, p.original_effective, p.time_source, p.season
  FROM pen_occupancies p WHERE p.ewe = :ewe

UNION ALL
SELECT 'note', n.id, n.occurred_at,
       n.captured_at, n.original_effective, n.time_source, n.season
  FROM notes n WHERE n.ewe = :ewe

 ORDER BY at DESC;
```

`readsFrom: {lambings, treatments, careEvents, lambs, fosterEvents, eweObservations, penOccupancies, notes}`. No `LIMIT`: a ewe's whole life over five seasons is ~80 rows across indexed tables — sub-millisecond. The one-second budget is spent on the frame, not the query plan.

**Four of those seven arms select columns doc 03 had not declared, and `CONVENTIONS.md` R37 orders them added before the first schema snapshot.** `foster_events`, `ewe_observations`, `pen_occupancies` and `notes` carry an event time but not the §12.5 quad. This screen's whole promise is a provenance label on *every* row (§1.5), so the quad is a hard requirement on all four, not a nicety — it is the single largest schema dependency this document has, and it is item 3 in §22. Until doc 03 lands it, those four arms cannot be written and the timeline ships with the three that can (`lambings`, `treatments`, `care_events`). Shipping the other four with a hard-coded `'auto'` is not an option: that is a §12.5 violation in the shape of a placeholder.

`notes` also needs an `occurred_at`, which R37 adds alongside the quad. Doc 03's `Notes` carries only the `Identified` mixin's `created_at`/`updated_at`, which are row-lifecycle facts, not event facts — a note typed at 07:00 about something at 03:20 has an `occurred_at` of 03:20 and a `captured_at` of 07:00, and that distinction is exactly what spec §15's "within five minutes of the event" is measured from.

`EweObservations` (decision #44) is what makes "prolapsed 2025" appear at all; its vocabulary is the `vocab_terms` keys `obs_prolapse`, `obs_mastitis`, `obs_poor_mothering`, `obs_good_mothering`, `obs_no_milk`, `obs_other`, user-extensible. **The app records what the shepherd observed and never infers it** — "poor mothering" is never derived from a lamb death (§12.2).

### 4.2 States

| State | Rendering |
|---|---|
| Frame 1 | Header placeholder at the summary line's exact height |
| Loaded | `headingLevel: 1` tag, then the summary line, then the timeline |
| Empty | "Nothing recorded for 412 yet." + "Record a lambing" |
| Reused tag | Under the header: "An earlier 412 was culled on 12 Aug 2025. Separate record." + a 60 pt tap to open it. Tags are unique among **active** animals only (§7.0 ruling 7), so this line is a normal, expected state — not an error |
| Error | Standard panel |
| Over-cap | **Nothing.** Free-tier history is never hidden, blurred, greyed or made read-only. The season wall is upstream (§19.2); it never reaches back and locks last year's card |

### 4.3 Actions

| Action | Taps | Result |
|---|---|---|
| Record a lambing | 1 | `beginLambing` commits, **then** Lambing Entry is pushed (§7.1) |
| Treat her | 1 | Treatment sheet, animal pre-loaded |
| Pen her | 2 | pen picker → tap a pen; a pen that does not exist yet is created on that tap |
| Record an observation | 2 | "Observe" → pick kind |
| Add note / voice note / photo | 1 each | recording and capture flows live in `08-platform-integration.md` |
| Edit a timestamp | 2 + picker | writes `RecordedTime.editedTo`; the row then reads "time edited by you" and shows what it was edited *from*. **Available only on rows whose table carries the §12.5 quad** — see §1.5. A table without the quad has no edit verb |
| Change status (sold / died / culled) | 2 | `setStatus`; the previous value stays recoverable from the record's own context, so there is no undo verb (§15.1) |
| Record her as barren | 2 | writes `ewe_seasons.status = 'barren'` for the current season, not a `status` change and not an observation |

`ewes.status` is a mutable column with `CHECK (status IN ('active','sold','dead','culled'))` (doc 03 §5.2) and there is **no status-history table**: `CONVENTIONS.md` R41 rules that decision #31's history-table rule is instantiated by decisions #33 (fostering) and #34 (pen occupancy) only, so `ewes.status` stays mutable with `updated_at` moving. "Barren" is not one of the four values, and per R42 it is not an `EweObservations` row either — it is a **season participation outcome**, `ewe_seasons.status = 'barren'`, and the §7.7 "barren" filter joins `ewe_seasons` for the current season. `EweObservations` never carries it; its vocabulary is `obs_prolapse`, `obs_mastitis`, `obs_poor_mothering`, `obs_good_mothering`, `obs_no_milk`, `obs_other`.

### 4.4 §12 on this screen

- **§12.5** on every timeline row: `recorded automatically` / `time entered by you` / `time edited by you`, rendered from `RecordedTime.provenanceLabel`. An edited row also shows the original value.
- **§12.1** next to any withdrawal figure that appears in a treatment row: `as entered by you`.
- **§12.4** badges on rows with warnings.

---

## 5. Screen 3 — Quick Entry

**Purpose.** Pick the animal and record what happened, in under fifteen seconds from unlock, one-handed, in a head torch, with the other hand on a lamb. This is the product. Everything else exists to serve it or to read back what it recorded.

Spec §7.1 opens with the sentence that governs this whole section: *"This is the hardest UX problem in the app and deserves the most attention."* That is why this brief and the Pen Board's are the two long ones.

It is the **root route** — `MaterialApp.home`, route 0, `isFirst`. It is never pushed; every other screen pops back to it.

### 5.1 Layout, top to bottom

```
[ export banner slot ]      ← §16; absent most days, and its presence is a matrix variant
[ entered tag              ]  displayLarge 64 pt tabular — the thing you check without reading
[ filtered matches         ]  max 3 rows; drops to 2 before the keypad ever shrinks
[ IN THE PENS  · 6 tiles   ]  fixed height, horizontally scrolling
[ RECENTS      · 6 tiles   ]  fixed height, horizontally scrolling
[ ShedKeypad               ]  4 rows × 3 columns; 72 pt (`tapPrimary`) keys, 44 pt glyphs, 16 pt gaps
[ confirm bar              ]  full-width 88 pt (`tapHero`), labelled with the OUTCOME
[ event button row         ]  Lambing · Treatment · Pen · Note — 88 pt
```

The keypad geometry, the confirm bar and the "labelled with the outcome, never a bare tick" rule belong to `06-design-system.md` §8.2; this document only fixes where they sit relative to the two selection strips, which doc 06's layout order does not mention.

The keypad never shrinks and is never covered. If the layout does not fit, the filtered-match list gives up rows first, then the "in the pens" strip; the keypad, the confirm bar and the recents strip never give up anything. Reachability at 375×667 × textScaler 1.3, **with the banner shown**, is asserted by the overflow matrix (decision #114, §21.2).

### 5.2 The query

One statement feeds both selection strips (decision #67: "in the pens" is the same projection the Pen Board watches, ordered differently). One statement, one provider: **`quickEntryDeckProvider`** — `StreamProvider<QuickEntryDeck>`, keepAlive, where `QuickEntryDeck` is `({List<DeckEntry> penned, List<DeckEntry> recents})`. The two strips read it with `.select((d) => d.penned)` and `.select((d) => d.recents)`; `recentEwesProvider` and `inPensProvider` are banned spellings (`CONVENTIONS.md` R28).

```sql
-- quickEntryDeckQuery. One statement, two buckets, one stream.
-- SQLite only accepts ORDER BY/LIMIT on the final arm of a compound SELECT,
-- so each bucket is a CTE.
WITH penned AS (
  SELECT 'penned' AS bucket, e.id AS ewe_id, e.tag AS tag, e.tag_digits AS tag_digits,
         o.entered_at AS sort_at, p.label AS pen_label
    FROM pen_occupancies o
    JOIN ewes e ON e.id = o.ewe
    JOIN pens p ON p.id = o.pen
   WHERE o.exited_at IS NULL AND o.ewe IS NOT NULL
   ORDER BY o.entered_at ASC           -- longest-penned first: the one you are standing next to
   LIMIT 6
), recents AS (
  SELECT 'recent', e.id, e.tag, e.tag_digits, t.touched_at, NULL
    FROM ewe_touches t
    JOIN ewes e ON e.id = t.ewe
   WHERE e.status = 'active'
   ORDER BY t.touched_at DESC
   LIMIT 6
)
SELECT * FROM penned UNION ALL SELECT * FROM recents;
```

`readsFrom: {penOccupancies, eweTouches, ewes, pens}`, `.distinct()` in the repository. `o.ewe` is nullable in doc 03's `PenOccupancies` (a pen can hold lambs with no ewe), hence the `IS NOT NULL` — decision #67 says the strip is ewes only, and without that predicate the `JOIN ewes` would silently drop the row anyway, which is the same result reached by accident rather than on purpose.

`ewe_touches` has `ewe` as its **primary key**, so there is exactly one row per ewe and `LIMIT 6` after `ORDER BY touched_at DESC` really is the last six distinct animals — no `GROUP BY`, no `DISTINCT`.

No `time_source` is projected here. Neither strip shows a time: the pens strip shows hours-since-penned, computed in Dart from `entered_at` (§9.2), and the recents strip shows nothing but a tag. §12.5 applies to *displayed event times*, and there are none on this screen outside the commit SnackBar (§5.7).

The keypad itself is fed by **`tagIndexProvider`** (`StreamProvider<List<TagIndexEntry>>`, `lib/data/providers.dart`, keepAlive — `CONVENTIONS.md` §3.2, R26), an app-level singleton, not a screen query: one statement over the active ewes, watched once and held in memory as `List<TagIndexEntry>` (`{EweId eweId, String tag, String digits, Instant? lastTouched}`). `flockTagCacheProvider` is a banned spelling. Doc 03 §9.1 sizes the index at ~400 entries × ~40 bytes ≈ **16 KB**; use that figure. Matching is `rankTagMatches` (`lib/domain/tag_match.dart`) in Dart — exact, then prefix, then suffix, then infix, then most-recently-touched. **Synchronous, so the list updates in the same frame as the keystroke.** FTS5 cannot do this: trigram matching ignores queries under three characters, and the spec's own example is `12` → `412` (decision #35). There is no debounce on this path and there is no `await` between a digit and a redraw.

The index is filtered to **active** animals, which is what makes create-on-the-fly correct under §7.0 ruling 7: a culled 412 is not in the index, so typing `412` offers "Create 412", and the partial unique index accepts it.

### 5.3 States

| State | Rendering |
|---|---|
| **Frame 1** | The keypad is fully interactive with zero data. Both strips are fixed-height dark placeholders. Digits accumulate in widget state. The confirm key reads `412 →` — it makes **no existence claim** while the tag index is unresolved |
| Loaded, no digits typed | Both strips populated; confirm key hidden |
| Loaded, digits typed, match exists | Confirm key reads **"Use 412"** |
| Loaded, digits typed, no match | Confirm key reads **"Create 412"** |
| Empty (day one) | Pens strip: "Nothing penned yet." Recents strip: "No recent animals." Both keep their box. The keypad is unaffected |
| **Filtered-empty** | **Does not exist on this screen, and that is the design.** Digits that match nothing are not an empty result — the confirm key becomes "Create 412". Spec §7.1: *"if the tag does not exist, one tap creates the ewe and continues. Never block an entry to make the user go and set something up first."* A "no matches" message here would be the app stopping to tell the shepherd something it should instead be offering to fix |
| Error | The strips show "Could not read recents." on one line and a 60 pt "Diagnostics". **The keypad keeps working** — a database read failure must not cost you the ability to type a tag |
| Over-cap | **Nothing.** No upgrade row, no counter, no colour change. Enforced by widget test at `unlocked: false, ewesInCurrentSeason: 99` (decision #90) |

The `412 →` window lasts from frame 1 until the tag index resolves. **The duration is unmeasured** — it is one `SELECT` over an indexed 400-row table behind a first-post-frame database open, so it should be tens of milliseconds, but no number here is measured and none should be quoted until the device trace in `12-testing.md` runs. What matters is the behaviour, which is unconditional: in that window, creating a new ewe costs **one extra tap** — the first tap resolves the index and re-labels the key to "Create 412", the second commits. This is the only place in the app where a tap cost varies, and it exists because a confirm key that guesses "Use" and creates a duplicate ewe at 03:20 is worse than an extra tap.

### 5.4 Actions and tap costs

| Action | Taps from Quick Entry open | Notes |
|---|---|---|
| Select a penned ewe | 1 | tile |
| Select a recent ewe | 1 | tile |
| Select by tag | 3 (digits) + 1 confirm | "Use 412" |
| **Create on the fly** | 3 (digits) + 1 confirm | "Create 412". `EntryContext.liveEntry` — structurally incapable of returning `BlockedByCap` (decision #91). Over the free cap the row is created and marked `over_free_cap`; nothing is said, nothing is shown |
| Backspace | 1 | bottom-left (bottom-right when `leftHanded`). No key repeat — that needs a held contact |
| Clear the tag | 1 | |
| **Record a lambing** | ewe + 1 ("Lambing") | commits `beginLambing`, then pushes Lambing Entry |
| Record a treatment | ewe + 1 | pushes the treatment sheet |
| Pen the ewe | ewe + 1 + 1 (pen) | |
| Add a note | ewe + 1 | |

**The 6-tap budget:** `4` (digits + confirm) `+ 1` (Lambing) `+ 1` (~~birth type~~ **the first tally stroke**) = a committed, valid lambing record. Asserted in `test/features/tap_budget_test.dart` with keyed finders (`quick_entry.keypad.digit_4`, `quick_entry.confirm`, `quick_entry.event.lambing`, `lambing_entry.tally.stroke`).

> **AMENDED 2026-08-02 (N16-T02a), ruling P8.** The budget stays at **6** and the fifteen-second promise is unchanged; only the sixth tap's composition changes. Birth type is DERIVED from the strokes and labelled `(COUNTED)` — see decision-record §7.0b for why that is a safety rule rather than a simplification: a declared type and a counted one can disagree, and every way of resolving that disagreement is worse than not having it.

### 5.5 Commit, confirmation and double taps

Order is **tap → write → await the transaction → change the UI** (decision #103). No optimistic UI: on local SQLite this costs single-digit milliseconds, so there is no reason to be optimistic and a hard correctness reason not to be.

Three redundant confirmation channels:

1. The commit haptic — perceivable with the phone in a bag. `06-design-system.md` §10 owns the vocabulary and spells it `HapticFeedback.successNotification()`. **VERIFIED 2026-08-01 (N09-T09), `REFERENCES §22` E1.** `successNotification`, `warningNotification` and `errorNotification` all exist on the installed Flutter **3.44.8**, in `packages/flutter/lib/src/services/haptic_feedback.dart`. This paragraph previously read *"that member is unverified"* and carried the `heavyImpact()` fallback; **the fallback is not needed and the spelling stands.** Item 7 in §22 is closed.
2. A **persistent** SnackBar carrying the committed fact and its time with provenance: `412 · triplets · 03:24 · recorded automatically`, with a ≥60 pt UNDO action and `insetPadding` clearing the bottom bar (`EdgeInsets.fromLTRB(16, 16, 16, 96)`, doc 06 §2). It is raised by `confirmSaved(context, receipt, warnings)` with a `SaveReceipt` — `lib/core/ui/feedback.dart`, owned by `06-design-system.md` §10.3 (`CONVENTIONS.md` R10, R30, R31); the screen never calls `showSnackBar(` itself.
3. The list mutates: the ewe jumps to the head of the recents strip. This is the only signal still true five seconds later, and the only one that proves the *database* changed.

The announcement is a `liveRegion` whose label is unique each time — never `SemanticsService.announce`, which is a silent no-op on Android (decision #103).

Every destructive or committing control routes through `WriteController.guard()`, which refuses to run concurrently (decision #22). Cold wet fingers double-fire; one `tester.tap(); tester.tap();` test per committing action.

### 5.6 What is banned on this screen

No monetization widget. No dialog. No modal that appears by itself. No `Tooltip`, `Dismissible`, `Draggable`. No system keyboard — the OS numeric keypad puts `1` at the top of the screen on iOS, cannot be sized to 60 pt, cannot carry a "Create 412" key, and a third-party Android IME can render bright in a dark shed. No tag OCR, no voice tag entry (§7.0 rulings 5 and 6: both **cut from v1**, and not open; the voice **note** ships, via `record` 7.1.1 as pure local recording). The two spec §7.1 bullets that name them are superseded — `08-platform-integration.md` documents both as v2 candidates with the reason, so a future contributor does not reopen them.

### 5.7 §12 on this screen

One disclosure, and it is the one that is easiest to drop:

- **§12.5** in the commit SnackBar. Every committed fact is echoed with its time **and** its provenance label from `RecordedTime.provenanceLabel` — `412 · triplets · 03:24 · recorded automatically`. A bare `03:24` in a SnackBar is a review failure; doc 05 §4.3's rule is "never a bare `03:21`", and a SnackBar is a screen showing an event time like any other.
- **§12.1** does not appear: no withdrawal figure is enterable from this screen. Tapping "Treatment" pushes the treatment sheet, and the caveat lives there (§10.2).
- **§12.3** does not appear: the not-a-regulatory-record footer belongs on Export, on the medicine-book segment, and in Settings ▸ About. Putting it on the 3am screen would cost a line of the keypad's budget to say something nobody reads at 03:20.
- **§12.4** does not appear: warnings are raised by the screen that owns the contradicted field. Quick Entry owns no field a warning can attach to except the tag, and `duplicateActiveTag` fires on the Flock create path (§3.3), not here — over the free cap or not, `EntryContext.liveEntry` creates the row and says nothing (§19.3).
- **§12.2** binds as copy discipline: no event button, no strip header and no confirm key may contain a "should", a recommendation or a clinical claim.

---

## 6. Screen 4 — Lambing Entry

**Purpose.** Record the birth while it is happening. The row already exists before this screen is built.

### 6.1 The write happens before the route

There is no draft state and no Save button (decision #11). The sequence is:

> **AMENDED 2026-08-02 (N14-T03). The snippet below is SUPERSEDED for the Quick Entry tap, on two
> counts, and it is kept because the reasoning in its comments is still correct.**
>
> **1. It calls the verb OUTSIDE any guard.** `beginLambing` returns an id and throws;
> `WriteController.guard()` takes a `Future<WriteOutcome> Function()`. The two do not compose, and a
> bare `try`/`catch` deletes the double-tap defence on the product's central write — the anchor
> *'a double tap on the lambing verb creates exactly one lambing'* is unpassable against this shape,
> and drilling it confirms that. The adaptation is to wrap inside the guard and return the id as an
> outcome, which is not an invention: R33 says a bare `int` appears *"as `WriteCommitted.insertedId`,
> which the single reading call site wraps"*, and this is that call site.
>
> ```dart
> Future<void> beginLambing(EweId ewe) => guard(() async {
>   final repo = ref.read(lambingRepositoryProvider);
>   final LambingId id = await repo.beginLambing(ewe);
>   return WriteCommitted(insertedId: id.value);
> });
> ```
>
> **2. `lambingWriteControllerProvider` is the wrong controller for this tap, and using it does not
> build.** It lives in `lib/features/lambing/`, so Quick Entry importing it is a `layer.sibling`
> violation (rule 6) — the gate fails, and it should. The Quick Entry tap belongs to
> `quickEntryWriteControllerProvider`, which reaches the repository through `lib/data/`. The
> controller this snippet names is N16's, for writes made *from* Lambing Entry.
>
> **3. The `catch` arm is also superseded, by P2.** `showFailure` is correct; *"persistent SnackBar"*
> is not — `showSnackBar(` is banned everywhere. The confirmation is the committed row, in ink.
> Failure copy is N14-T04's.

```dart
Future<void> onLambingTapped(BuildContext context, WidgetRef ref, EweId ewe) async {
  final controller = ref.read(lambingWriteControllerProvider.notifier);
  try {
    // beginLambing and addLamb are the ONLY two verbs that return an id and
    // throw (CONVENTIONS §2.13, R32) — there is no id to hand back on failure
    // and the screen cannot open. Every other write returns a WriteOutcome and
    // goes through WriteController.guard(), which refuses to run concurrently:
    // cold wet fingers double-fire (decision #22).
    final LambingId lambing = await controller.beginLambing(ewe);  // one db.transaction
    if (!context.mounted) return;
    Routes.lambingEntry(context, lambing);      // the screen never exists without a row
  } catch (error) {
    if (!context.mounted) return;
    // shedFailureFrom(Object) — lib/data/failure_mapping.dart (R4).
    // showFailure — lib/core/ui/feedback.dart (R10, R30). Persistent SnackBar,
    // never a dialog. showShedFailure is a banned spelling.
    showFailure(context, shedFailureFrom(error));
  }
}
```

Three things in that snippet are fixed by `CONVENTIONS.md` and are not local choices: the argument and the return are **extension-type ids**, never a bare `int` (R33); the failure path is `showFailure`, not `showShedFailure` (R30); and there is no `WriteCommitted(:final id)` arm, because `WriteCommitted` is non-generic and its id field is `insertedId` (R3) — a verb that returns an id does not return a `WriteOutcome` at all.

An abandoned entry is therefore a **true statement** — "a lambing began for 412 at 03:24 and nothing else was recorded" — not garbage. It is removed by Undo within the SnackBar window, or explicitly from the Ewe Card, and never by a background sweep.

### 6.2 The query

`lambingEntryQuery` — the lambing row joined to its lambs and their care events, assembled in Dart.

```sql
SELECT lg.id AS lambing_id, lg.ewe, lg.season, lg.declared_birth_type, lg.ease,
       lg.occurred_at, lg.captured_at, lg.original_effective, lg.time_source,
       lg.assisted_by, lg.presentation, lg.presentation_note,
       l.id AS lamb_id, l.sex, l.status, l.birth_weight_g, l.tag,
       c.id AS care_id, c.kind AS care_kind, c.volume_ml, c.method,
       c.occurred_at AS care_occurred_at, c.time_source AS care_time_source
  FROM lambings lg
  LEFT JOIN lambs l       ON l.lambing = lg.id
  -- CareEvents' CHECK is exactly one of (lambing, lamb). This screen writes
  -- every care event against a LAMB; the nullable `lambing` FK exists for a
  -- care action taken before any lamb is attached, and the second arm picks
  -- those up on the null-lamb row the outer LEFT JOIN produces.
  LEFT JOIN care_events c ON c.lamb = l.id
                          OR (l.id IS NULL AND c.lambing = lg.id)
 WHERE lg.id = :lambing
 ORDER BY l.id ASC, c.id ASC;
```

`readsFrom: {lambings, lambs, careEvents}`. `lg.*` is not used: a `SELECT *` over a table with a `uid`/`created_at`/`updated_at` mixin silently widens every time doc 03 adds a column, and `customSelect` result parsing is positional-by-name, so the column list is written out. Care checkbox state is `EXISTS` over these rows, never a boolean column (decision #43), which is what keeps "colostrum given at 03:22" recoverable.

Controller, in Riverpod 2.6.1 spelling (decision #19 — families take the arg through `build`, and the constructor tear-off is zero-argument):

```dart
final lambingEntryControllerProvider = AsyncNotifierProvider.autoDispose
    .family<LambingEntryController, LambingEntryState, LambingId>(
        LambingEntryController.new);

final class LambingEntryController
    extends AutoDisposeFamilyAsyncNotifier<LambingEntryState, LambingId> {
  @override
  Future<LambingEntryState> build(LambingId lambing) async { … }
}
```

The family argument is `LambingId` from `lib/domain/ids.dart`, never a bare `int` (`CONVENTIONS.md` R33): a bare `int` appears only inside `lib/core/db/` and as `WriteCommitted.insertedId`, which the single reading call site wraps.

Riverpod-3 spellings are banned and CI greps for each. Decision #18 lists **nine**, and all nine belong in the rule table: `ProviderScope.retry`, `ProviderContainer.test()`, `WidgetTester.container`, bare `Notifier` + `.autoDispose`, Mutations, `AsyncValue.valueOrNull`, `StateProvider`, `StateNotifierProvider`, constructor-delivered family args.

Two of those are worth naming for why: `ProviderScope.retry` is a **compile error** on 2.6.1 and there is no auto-retry to disable, so the pitfall paragraph and the "disable it" advice that appear in raw notes 01 and 04 must not be ported (decision-record §6). And `AsyncValue.valueOrNull` is banned even though a 2.6.1 codebase compiles without it, because avoiding it now makes a future 4.0 migration near-free (decision-record §5.1).

### 6.3 States

| State | Rendering |
|---|---|
| Frame 1 | Impossible — the row is committed before the push |
| Loaded, no lambs | The normal opening state. Birth type may be declared before any lamb is attached |
| Loaded, lambs attached | One 88 pt row per lamb |
| Birth type undeclared | The five buttons are unselected. **Birth type is never defaulted to "single"** — an undeclared type is `NULL` in `lambings.declared_birth_type` and reads as "not declared" |
| Filtered-empty | Impossible — this screen has no filter |
| Contradiction | ~~60 pt amber strip~~ **a query mark in the margin + a 2 px madder underline under the offending cell**. Never a dialog, never blocking, never twice for one field |

> **AMENDED 2026-08-02 (N16-T06), by the authority order.** ~~60 pt amber strip~~ → **a query mark
> `?` in the margin plus a 2 px madder underline under the offending cell.** `indelible.md §2.2` and
> `§6.2` call for that mark, and Indelible has **no status palette at all** — *"a colour-coded death
> reads wrong at 4am through a wet freezer bag."* `CLAUDE.md`'s authority order puts
> `docs/design/indelible.md` above the thirteen engineering documents, so an amber strip is
> unbuildable: there is no amber token to build it from, and inventing one would be adding a status
> colour to a system that deliberately has none.
>
> **Everything else in the row survives verbatim** — never a dialog, never blocking, never twice for
> one field — and `05 §7.5` guarantee 3 stays absolute: warnings never gate the write.

| Error | Standard panel |
| Over-cap | **Nothing** |

**The nullability contradiction, settled by `CONVENTIONS.md` R6 (an owner ruling).** `01-architecture.md` §6 writes `birthType: const Value.absent()` in `beginLambing`, with the comment "absent ≠ Value(null)". `03-data-model-and-schema.md` §5.4 declared `late final declaredBirthType = integer()();` — non-nullable, no default, no `clientDefault`. Those two cannot both ship: an `INSERT` that omits a NOT NULL column with no default fails with `SQLITE_CONSTRAINT_NOTNULL`, so `beginLambing` would throw on its first call, on a fresh install, on the 3am path. **`Lambings.declaredBirthType` is nullable**, because decision #11 puts the row on screen entry and the shepherd has not tapped a birth type yet; doc 03 makes the change, and it must land **before the first schema snapshot** — it is irreversible afterwards. The column is `declared_birth_type` / `declaredBirthType`, never `birth_type` (`CONVENTIONS.md` §4.6). Item 1 in §22.

### 6.4 Actions and tap costs

| Action | Taps | Notes |
|---|---|---|
| Declare birth type | 1 | five big buttons: single / twin / triplet / quad / more, stored as `declared_birth_type` 1..5. **"more" is open-ended and opens nothing** — 5 means "more than four, count not declared", and the count comes from the lambs actually attached. This is load-bearing: `birthTypeLambCountMismatch` is *undefined*, not false, when the declared type is open-ended, so a large litter must never show a false badge (doc 03 §5.4, doc 05 §7) |
| Lambing ease 1–5 | 1 | a blank score means *not scored* and is excluded from the assisted rate on both sides (decision #59). It is never inferred as "1 — unassisted" |
| Add a lamb | 1 | the 88 pt primary action |
| Lamb sex | 1 | |
| Lamb alive / dead / stillborn | 1 | stillborn is its own state, never "died at age 0" |
| Birthweight | 1 + digits + 1 | the in-app keypad with one decimal key that always emits `.` (decision #57). Canonical storage is integer grams |
| Lamb tag | 1 + digits + 1 | optional and stays optional; a lamb that dies before tagging is still fully counted |
| Care checkbox (colostrum / navel dip / stomach tube / warmed) | 1 each | writes a `CareEvent` with the §12.5 triple |
| Colostrum volume + method | 2 more | skippable |
| Assistance detail | 1 to open + 1 per chip | who assisted, malpresentation, lubricant/ropes/vet |
| Note / voice note / photo | 1 each | |
| Edit the event time | 2 + picker | |
| Done | 1 | pops. There is nothing to save |

**A valid record is one tap** on this screen (birth type), exactly as spec §7.2 promises.

### 6.5 §12 on this screen

- **§12.5**: the event time sits in the header with its provenance label at all times.
- **§12.4**: the warning strip is fed by pure functions returning `List<Warning>` (decision #54). There is no `warnings` column and no `fix()` method — a warning cannot be persisted because there is nowhere to persist it, and cannot mutate because it holds no writer. The catalogue that fires here: `birthTypeLambCountMismatch` ("Birth type is twin but 3 lambs are recorded."), `lambingInFuture` (>2 min ahead), `lambingBeforeSeasonStart`, `lambingLongBeforeCapture` (>3 days), `timeDoesNotExistLocally` ("The clock skipped 01:30 that night (clocks went forward). Saved as 02:30."), `implausibleBirthWeight`.
- The **ambiguous** DST hour (01:00–01:59 in UK/Ireland, §7.0 ruling 3) is deliberately **not** warned about: the displayed time matches what the user typed, so nothing has been silently corrected from their point of view, and the 60 minutes of ambiguity are recorded in the exported UTC column regardless.

---

## 7. Screen 5 — Lamb Card

**Purpose.** One lamb's identity, weight, dams, rearing status and death. Reached from the Lambing Entry, the Ewe Card or a pen tile.

### 7.1 The query

`lambCardQuery` — the lamb, its birth dam, its **current rearing dam from the `lamb_rearing` view** (doc 03 §7; never a denormalised column, decision #33), and its history unioned as on the Ewe Card. `readsFrom: {lambs, lambings, ewes, fosterEvents, careEvents, treatments}` — `lamb_rearing` is a view, so its base tables are what the stream is keyed on, not the view name.

### 7.2 States

| State | Rendering |
|---|---|
| **Frame 1** | Impossible — reached only from a loaded Lambing Entry, Ewe Card or pen tile, and the row is committed before any of those can offer the tap |
| Loaded | Header: tag or "untagged", sex, status, birth dam, rearing dam |
| Untagged | Normal, not empty. Lamb identity is the row id; `tag` is nullable at every layer |
| **Reared by no ewe — two different states, never merged** | `lamb_rearing.rearing_dam IS NULL` covers two facts that doc 03 keeps apart on purpose, because the rearing-credit numbers differ. `foster_events.outcome = 'to_bottle'` → **"No ewe — bottle"**, null *by intent*. `outcome = 'removed_unknown'` → **"No ewe — not recorded"**, null *by omission*. Both belong to no ewe's reared count; only the first is a husbandry fact. Rendering them with one string would be the app deciding they are the same, which is a §12.4 violation |
| Dead | The card stays fully editable. A dead lamb keeps both dams so the ewe's litter size stays right and the loss stays attributed |
| Empty history | "Nothing else recorded." |
| Filtered-empty | Impossible — this screen has no filter |
| Error | Standard panel |
| Over-cap | **Nothing** — shed screen |

### 7.3 Actions and tap costs

| Action | Taps | Notes |
|---|---|---|
| Add or change the tag | 1 + digits + 1 | |
| Birthweight | 1 + digits + 1 | |
| Sex | 1 | |
| Alive / dead / stillborn | 1 | dead → cause list is 1 more tap, from the authored short list, user-extensible |
| Death date | 1 + picker | seeded from the device date and **shown**; accepting it records `autoCaptured`, changing it records `userEntered` |
| **Foster** | 1 | pushes Foster |
| Pet lamb / bottle | 1 | |
| +1 feed | 1 | a 72 pt counter button |
| Note / photo | 1 each | |

### 7.4 §12 on this screen

§12.5 on the birth time (inherited from the lambing) and on the death date. §12.4 badges for `deathBeforeBirth` ("The death date is before the lambing.") and `implausibleBirthWeight` — both are observations, never judgements. The catalogue message in doc 05 §7 is **"0.4 kg is outside the usual range for a lamb."**, fired outside roughly 1.0–10.0 kg. Never "that is light for a twin", which is husbandry advice (§12.2). A weight of 4 g could not raise this warning at all: doc 03's `CHECK (birth_weight_g IS NULL OR birth_weight_g BETWEEN 200 AND 20000)` refuses it at the storage layer before any validator sees it.

---

## 8. Screen 6 — Foster

**Purpose.** Move a lamb to a different rearing dam. Spec §7.3: *"move a lamb to a different ewe in two taps… This is the flow most likely to be abandoned if it takes five taps."*

### 8.1 Holding the two-tap claim

The reassignment is **one tap from the Foster screen**, and two counting the tap that opens it. There is **no confirmation step** — commit-then-confirm with a persistent SnackBar is the house pattern, and a confirm dialog here would put the flow at three taps and a modal on a shed screen. On this screen the SnackBar action reads **"Correct this"**, not "Undo": the reversal is a compensating event that stays in history, and calling it Undo would claim an erasure that never happens (§15.3).

Whole journeys, all asserted:

| From | Taps |
|---|---|
| Lamb Card | 2 (Foster → target) |
| Pen Board | 3 (tile → Foster on the lamb row → target) |
| Quick Entry | 4 (ewe → lamb → Foster → target) |

### 8.2 The query

`quickEntryDeckQuery`, reused with the fostering lamb's current rearing dam excluded from neither bucket (fostering onto the current dam is a *warning*, not an exclusion — see §8.4). Penned ewes first, ordered by longest penned; then recents; then the keypad for anyone else. One statement, already written, no new table.

### 8.3 States

| State | Rendering |
|---|---|
| Frame 1 | Impossible — reached only from a loaded card |
| Loaded | Two strips + keypad + **two** 72 pt no-ewe targets: "No ewe — bottle" and "No ewe — not recorded" (§8.4 rule 1) |
| Empty | "No other animals yet." — the keypad still creates one |
| Filtered-empty | Impossible — this screen has no filter; the keypad narrows, it does not filter to nothing (an unmatched tag becomes "Create") |
| Error | Standard panel |
| Over-cap | **Nothing** — shed screen |

### 8.4 Rules this screen must not break

1. **The verb carries the outcome; it is not a nullable ewe id.** Raw note 09 §11 writes `setRearingDam(lambId, eweId?)`, and that signature is wrong for this schema. Doc 03's `FosterEvents.outcome` is `'to_ewe' | 'to_bottle' | 'removed_unknown'`, with the comment *"bottle (null by intent) and unknown (null by omission) are different facts and the rearing-credit numbers differ. Do not merge them."* A nullable `eweId?` merges exactly those two. The verb is:

   ```dart
   // FosterRepository — CONVENTIONS.md §2.13.
   Future<WriteOutcome> recordFoster(LambId lamb, FosterOutcome outcome);
   ```

   `FosterOutcome` is declared once, in `lib/domain/foster_outcome.dart`: a sealed type with three
   variants, each carrying its stored key — `ToEwe(EweId)`→`'to_ewe'`, `ToBottle()`→`'to_bottle'`,
   `RemovedUnknown()`→`'removed_unknown'` (`CONVENTIONS.md` §2.9, R64). It is referenced here, never
   re-declared. `setRearingDam(lambId, eweId?)` is a banned signature.

   That is why the screen shows two no-ewe targets and not one.
2. **Birth dam is immutable.** No parameter of `recordFoster` can name a birth dam, so the screen physically cannot change it, and a `BEFORE UPDATE` trigger refuses it even if a future code path tries (decision #33). A permanent 18 pt line says so: "Fostering does not change the birth dam." The industry model is the reason, not squeamishness: a grafted lamb keeps its birth type and gains a rear type, and `lambings.declared_birth_type` must never be recomputed by a foster.
3. **Warn, never block.** `fosterToSelf` ("That lamb is already on this ewe.") is the only warning. Fostering onto a ewe who has not lambed is legitimate and is never blocked — §7.1's "never block an entry to make the user go and set something up first" applies to her missing lambing record too.
4. **No teat-count warning.** Rejected: it edges into husbandry advice (§12.2) and the app has no business counting a ewe's teats.
5. Undo writes a **compensating `FosterEvent`** whose `corrects` FK points at the event it reverses, visible in history forever — `FosterEvents` is append-only, so a foster undo cannot be a delete (§15).

### 8.5 Actions and tap costs

| Action | Taps from Foster open | Notes |
|---|---|---|
| **Reassign to a penned ewe** | **1** | tile. Commits immediately; no confirmation step |
| **Reassign to a recent ewe** | **1** | tile |
| Reassign to a ewe by tag | digits + 1 confirm | "Use 412" |
| Reassign to a ewe that does not exist yet | digits + 1 confirm | "Create 412", then the foster commits in the same transaction. `EntryContext.liveEntry` — never blocked by the cap |
| **No ewe — bottle** | **1** | writes `outcome = 'to_bottle'` |
| **No ewe — not recorded** | **1** | writes `outcome = 'removed_unknown'` |
| **Correct this** | 1 | the SnackBar action; writes the compensating event. Never labelled "Undo" (§15.3) |
| Back | 1 | bottom-bar button, not only the AppBar chevron (§20.2) |

The 1-tap reassignment is the budget CI holds (§1.3). Everything else on this screen is measured from it.

### 8.6 §12 on this screen

- **§12.5** on the foster event, in the commit SnackBar and on both animals' timelines: `412 → 128 · 03:31 · recorded automatically`. This is one of the four tables that does not yet carry the provenance quad — see §1.5 and §22 item 3.
- **§12.4**: `fosterToSelf` as ~~a 60 pt amber strip~~ **the query mark and underline** (N16-T06). Shown, never blocking.
- **§12.2** binds hardest here: no screen in the app is more tempting to make helpful. No "this ewe has capacity", no "she has milk", no ordering of targets by anything except the two neutral facts the deck already has — longest penned, most recently touched.
- §12.1 and §12.3 do not appear: no withdrawal figure, no exportable record view.

---

## 9. Screen 7 — Pen Board

**Purpose.** The whiteboard, but timed and never wiped: who is in which pen, for how long, and who is over your turn-out threshold. Spec §7.4 calls it *"The digital replacement for the whiteboard, and a feature paper genuinely cannot match"*, and requires it to work *"as a glanceable board — legible from arm's length in a head torch"*. Arm's length is taken as roughly 60 cm; that number is a design assumption, not a measurement, and the field night is what confirms it (§22).

### 9.1 The query

`penBoardQuery` — one `customSelect`, one row per pen, with the occupant and the facts the tile and its sheet need. It extends doc 03 §8's `penBoard` statement with the three status booleans; the shape and the column names are doc 03's.

```sql
SELECT p.id AS pen_id, p.label AS pen_label, p.sort_order,
       o.id AS occupancy_id,
       o.entered_at, o.captured_at, o.original_effective, o.time_source,
       e.id AS ewe_id, e.tag AS ewe_tag,
       -- The lambs IN THIS PEN, from the join table. NOT "every lamb this ewe
       -- ever bore": that subquery is unscoped by season and would count last
       -- year's lambs on this year's board.
       (SELECT COUNT(*) FROM pen_occupancy_lambs pol
         WHERE pol.occupancy = o.id)                                 AS lamb_count,
       (SELECT COUNT(*) FROM pen_occupancy_lambs pol2
          JOIN lambs l ON l.id = pol2.lamb
         WHERE pol2.occupancy = o.id AND l.status = 'alive')         AS live_lambs,
       -- status is one of ('alive','dead','stillborn','sold'), so `<> 'dead'`
       -- would count a stillborn lamb as live. Test for 'alive' explicitly.
       EXISTS (SELECT 1 FROM pen_occupancy_lambs pol3
                 JOIN lambs l2 ON l2.id = pol3.lamb
                WHERE pol3.occupancy = o.id
                  AND l2.status IN ('dead','stillborn'))             AS has_loss,
       EXISTS (SELECT 1 FROM treatments t
                 JOIN treatment_withdrawals w ON w.treatment = t.id
                WHERE t.ewe = e.id AND t.voided_at IS NULL
                  AND w.kind = 'days' AND w.clear_date >= :today)    AS under_withdrawal
  FROM pens p
  LEFT JOIN pen_occupancies o ON o.pen = p.id AND o.exited_at IS NULL
  LEFT JOIN ewes e            ON e.id = o.ewe
 WHERE p.is_active = 1
 ORDER BY p.sort_order, p.label;
```

`readsFrom: {pens, penOccupancies, penOccupancyLambs, ewes, lambs, treatments, treatmentWithdrawals}`. The partial unique index `idx_penocc_one_open ON pen_occupancies (pen) WHERE exited_at IS NULL` means the database physically refuses two ewes in one pen (decision #34), so this `LEFT JOIN` cannot produce a duplicate row — the whiteboard's failure mode is solved at the storage layer, not in this query.

`o.captured_at`, `o.original_effective` and `o.time_source` are the columns §9.6 needs; `CONVENTIONS.md` R37 adds them to `PenOccupancies` before the first schema snapshot. §22 item 3.

### 9.2 The timer

**One app-level, boundary-aligned 60-second ticker**, `minuteTickProvider` (decision #66; `CONVENTIONS.md` R25 — `penTickProvider` and `minuteTickerProvider` are banned spellings). It is declared once, in `lib/core/time/ticker.dart`, and catalogued in `CONVENTIONS.md` §3.3; it is reproduced here only because the battery argument below is this document's. Tiles read it and compute `timeSincePenned(enteredAt, now)` — `lib/domain/penning.dart`, pure, takes `now` and never reads a clock (R24) — at build; the elapsed value is never cached and never stored.

```dart
/// lib/core/time/ticker.dart
///
/// Fires on the minute boundary so every tile changes in the same frame.
/// A grid where cells update at different moments reads as noise under a head torch.
///
/// `.autoDispose` is load-bearing, not tidiness: a plain StreamProvider stays
/// subscribed for the life of the ProviderScope, so the loop would keep waking
/// the process every 60 s all night with no pen board on screen. autoDispose
/// cancels the subscription when the last listener goes, which is what makes
/// the "measurable overnight battery" argument in decision #66 actually hold.
final minuteTickProvider = StreamProvider.autoDispose<Instant>((ref) async* {
  while (true) {
    final now = appNow();               // the ONE wall-clock reader (R23)
    yield now;
    final wall = now.local;
    await Future<void>.delayed(const Duration(minutes: 1) -
        Duration(seconds: wall.second, milliseconds: wall.millisecond));
  }
});
```

It yields `Instant`, never a raw `DateTime`: a provider yielding an unwrapped instant puts one in the UI layer, which is exactly what `Instant` exists to prevent (R25). `StreamProvider` is not on decision #18's banned list; `StateProvider` and `StateNotifierProvider` are. The `async*` body returns a `Stream<Instant>`, which is the create signature 2.6.1 expects.

One honest limitation of the `async*` shape: a Dart generator observes cancellation at its next `yield`, so after the last listener goes the pending `Future.delayed` still completes — up to 60 s of tail. That is one wake-up, once, and it is cheaper than the `StreamController` plumbing that would avoid it.

No `Timer.periodic` per row (30 timers, measurable overnight battery). No 30-second tick — display granularity is hours. The same ticker re-binds the Reminders screen's day boundaries (§11.1); there is exactly one ticker in the app.

In widget tests, `AutomatedTestWidgetsFlutterBinding` already provides an **advancing** fake clock, so `tester.pump(const Duration(hours: 25))` really moves `appNow()`. **Never wrap a pen-board test in `withClock(Clock.fixed(…))`** — that freezes `appNow()` and the test silently measures 0 h forever (decision #113). Offset the seed data instead.

### 9.3 Tile content and status encoding

A tile carries **at most three facts**: tag, hours, status. Lamb count and everything else live on the detail sheet.

| Element | Size |
|---|---|
| Tag | 40 pt, w700, tabular figures |
| Hours since penned | 32 pt, w700, tabular — *the number the board exists to show* |
| Everything else | 18 pt |

Every status carries **four** encodings, because red-shift mode destroys the colour channel entirely and red-green colour-vision deficiency affects roughly 8% of men of Northern European descent — the population this app ships to first (decision #106, WCAG 1.4.1). The table is `06-design-system.md` §11's, verbatim including its label text, because 06 owns the design system (`CONVENTIONS.md` R36); this document owns only the behaviour attached to it — the sorting, and the READY legend naming the user's own threshold (§9.6):

| Status | Colour token | Shape | Text | Position |
|---|---|---|---|---|
| Settling (< threshold) | `textSecondary` | plain tile, no border | `4h` | default order |
| **Ready to turn out** (≥ `app_settings.turn_out_threshold_hours`, default 24) | `statusReady` | thick left bar + filled corner triangle | `26h · READY` | sorted to top |
| Under withdrawal / treating | `statusAttention` | dashed outline + circle-slash badge | `12h · CLEAR 14 JUL` | badge on cell |
| Loss recorded | `statusLoss` | diagonal hatch fill | `DEAD` | sorted to top |
| Empty pen | `outline` only | dashed border, no fill | `—` | sorted to bottom |

The shape encodings are *structurally* different — bar, triangle, dashed outline, hatch, dash. Five similar icons are one icon at 60 cm under a torch. Verified against the Grayscale accessibility filter as a ship gate.

**Reflow, never clip.** The grid is `LayoutBuilder`-driven on a minimum tile width that scales with `MediaQuery.textScalerOf(context).scale(40)`. At 200% text the board goes to one or two columns and scrolls. A shepherd who needs 200% text needs a bigger `26h`, not four columns of clipped numbers. `FittedBox` around user-facing text is banned in review.

### 9.4 States

| State | Rendering |
|---|---|
| **Frame 1** | The same grid geometry in placeholder tiles — no shift when data lands |
| **Zero pens (day one)** | A single 72 pt **"Add a pen"** tile. Not an empty grid, not a wizard (decision #42) |
| Pens exist, none occupied | Every tile renders its label and the empty-pen encoding from §9.3 — `—`, dashed border, sorted to the bottom; tapping one opens the ewe picker |
| Loaded | As above |
| Filtered-empty | Impossible — the board has no filter. A deactivated pen (`is_active = 0`) leaves the grid entirely and is not a filtered state; it is a different set of pens |
| Error | Standard dark panel across the grid area |
| Over-cap | **Nothing** — shed screen, at any entitlement state |

### 9.5 Actions and tap costs

Spec §7.4: *"Move / turn out / mark as group in one tap."* Held as: **one tap per verb once the tile is open, and no verb has a confirmation step** — two taps from the board. A true one-tap-from-the-board turn-out is rejected because a brushed tile would turn out a ewe with a chilled lamb still under the lamp; the Undo pattern covers the mistake instead.

| Action | Taps from the board | Notes |
|---|---|---|
| Open a tile | 1 | a bottom sheet, `isDismissible: false`, `showDragHandle: false`, explicit 72 pt Cancel |
| **Turn out** | 2 | the write-controller verb is `turnOut`, which calls `exitPen(occupancy, reason: PenExitReason.turnedOut)` and writes `exited_at` + `exit_reason` together (`CONVENTIONS.md` R63); persistent Undo |
| **Move to another pen** | 2 | the sheet lists the other pens as its primary content |
| Mark as a group / turn out to a group | 2 | |
| Open the ewe card | 2 | |
| Foster a lamb from this pen | 2 | the lamb rows in the sheet each carry a 60 pt "Foster" |
| Add a pen | 1 | creates the next-numbered pen immediately; rename lives in the sheet and in Settings ▸ Pens |
| Change the turn-out threshold | → Settings | not on this screen; it is a season-level preference, not a 3am decision |

### 9.6 §12 on this screen

- **§12.5, and this is the one people miss:** a pen entry time that was edited is marked **on the tile**, not only on the detail sheet — a `~` prefix plus the word `edited` (never the marker alone). The board is what people trust; the board must not launder an edited time as a captured one. This requires the provenance quad on `pen_occupancies`, which `CONVENTIONS.md` R37 adds to doc 03 before the first schema snapshot (§1.5, §22 item 3). **Until it lands, the pen entry time has no edit verb** — the marker cannot be faked and the auto label cannot be a lie.
- **§12.2:** the READY state is a *user-set threshold*, and the board says so in the legend, with the user's own number substituted, not the default: "Ready = your 24 h threshold." The app never claims a lamb is fit to turn out, and never suggests a threshold — the schema's `CHECK (turn_out_threshold_hours BETWEEN 1 AND 336)` is a range guard, not a recommendation.
- **§12.4:** a tile whose ewe carries warnings shows the badge.

---

## 10. Screen 8 — Treatments

**Purpose.** Log what was given, count down the withdrawal the user read off the bottle, and be the medicine book someone hands to a vet.

One screen, two segments on a 60 pt segmented control: **Countdowns** | **Medicine book**.

### 10.1 The query

`treatmentsQuery(mode)` — one `customSelect` with a bound mode.

```sql
SELECT t.id, t.product_name, t.dose_text, t.route, t.batch_no,
       t.administered_at, t.captured_at, t.original_effective, t.time_source,
       t.voided_at,
       -- Withdrawals are a CHILD TABLE, 0..n rows per treatment, unique on
       -- (treatment, target). There is NO withdrawal_days and NO clear_date
       -- column on `treatments`. NO ROW for a target means NotRecorded;
       -- kind='not_applicable' means NotApplicable; kind='days' carries days
       -- and the clear date computed once at write time (decision #50).
       w.target, w.kind AS withdrawal_kind, w.days, w.clear_date,
       e.tag AS ewe_tag, l.tag AS lamb_tag
  FROM treatments t
  LEFT JOIN treatment_withdrawals w ON w.treatment = t.id
  LEFT JOIN ewes  e ON e.id = t.ewe
  LEFT JOIN lambs l ON l.id = t.lamb
 WHERE (:mode = 'book')
    OR (t.voided_at IS NULL AND w.kind = 'days' AND w.clear_date >= :today)
 ORDER BY CASE WHEN :mode = 'book'      THEN t.administered_at END DESC,
          CASE WHEN :mode = 'countdown' THEN w.clear_date      END ASC,
          t.id, w.target;
```

`readsFrom: {treatments, treatmentWithdrawals, ewes, lambs}`.

**This statement fans out, and the repository collapses it.** One product routinely prints a meat figure and a milk figure, so a treatment with both targets returns two rows. `treatmentsQuery` is still one statement; the repository groups by `t.id` in Dart and emits one `TreatmentRow` carrying a `List<WithdrawalPeriod>`. That is not stream combination — it is one stream, folded — so §1.2 holds. The countdown segment is the one place the fan-out is *wanted*: a meat clear date and a milk clear date are two different countdowns and are listed as two rows, each labelled with its target.

The `w.kind = 'days'` predicate in the countdown arm is what keeps a `NotRecorded` treatment out of the countdown list entirely, which is correct: there is no number to count down. It appears in the medicine book with "Withdrawal not recorded" (§10.3), which is where an inspector would look for it.

### 10.2 Entering a withdrawal period — the safety-critical control

Spec §7.5, and it is the sentence this control exists to satisfy: *"The withdrawal period is always entered by the user from the bottle label. The app ships no default values and makes no suggestion. A wrong withdrawal number puts meat or milk into the food chain."* Safety rule §12.1 says the same thing as a rule: *"Never default a medicine withdrawal period."* The control is three explicit 72 pt choices with **no pre-filled number and no pre-selected option**:

```
[ Enter days ]     [ Not applicable ]     [ Not recorded ]
```

They map one-to-one onto the sealed type (decision #51): `WithdrawalDays.asEnteredByUser(days:, target:)` / `WithdrawalNotApplicable` / `WithdrawalNotRecorded`. Choosing "Enter days" opens the keypad with an empty field; the confirm key reads **"7 days — as entered by you"**. `Disclaimers.withdrawalCaveat` sits above the control, permanently:

> Withdrawal period as entered by you from the product label. Shed Book does not know any product and suggests no value. Check the label.

Two targets are supported (`meat`, `milk`) because one product routinely prints different figures; 0..n entries per treatment, unique on `(treatment, target)`. `0` days is a **real value**, not "missing" — and it is the value that proves the type works, because a zero-day withdrawal still produces a clear date of *tomorrow*: the period elapses at the moment of administration, which is almost never local midnight, so today is a partial day (doc 05 §3.5). The screen shows that date; it does not round it down to "clear now".

`milk` ships in the v1 **schema and sealed type** — ruled 2026-08-01 (decision-record §7.0 row 10, `CONVENTIONS` R75), because that was free then and a migration afterwards. Whether it ever appears in the **UI** is a separate, product-shaped question and stays one; the v1 UI may never write a milk withdrawal, and the ruling does not add a Treatments field.

### 10.3 States

| State | Rendering |
|---|---|
| Frame 1 | Six fixed-height dark row placeholders, same geometry as Flock |
| Loaded, countdowns | Rows sorted by clear date, one row per target: `412 · Alamycin · meat · clear on 11 Mar 2026 · 4 days left`. **A human-facing date is never all-numeric** — `d MMM y`, and the withdrawal countdown is the worst possible place to break that rule, because the number it renders is the safety-critical one (`CONVENTIONS.md` R60) |
| Loaded, book | Reverse chronological, every treatment ever, including voided ones shown struck through with `voided 5 Mar 2026` |
| Withdrawal not recorded | `computeWithdrawalStatus` returns **`WithdrawalUnknown`**, which renders as "Withdrawal not recorded" with no countdown. The countdown widget takes a `ClearsOn`, so a countdown for an unrecorded period is type-impossible. (`WithdrawalUnknown` is a `WithdrawalStatus`; the three *periods* are `WithdrawalDays` / `WithdrawalNotApplicable` / `WithdrawalNotRecorded` — decision #51) |
| Withdrawal not applicable | `NoWithdrawal` renders as "Not applicable", also with no countdown. Distinct from "not recorded": one is a fact off the label, the other is a gap |
| **Clear date disagrees** | Both dates shown, stored first, with the message from `checkClearDate` in `05-domain-correctness.md` §3.8 — *"This treatment was saved with a clear date of 2026-03-11. From the details now recorded it would be 2026-03-12."* — plus one line: "Nothing has been changed." Referenced from the warning, not re-typed here (decision #50, decision #54) |
| Empty (book) | "No treatments recorded." + "New treatment" |
| Empty (countdowns) | "Nothing under withdrawal." |
| Filtered-empty | Impossible — the segmented control is a mode, not a filter, and each mode has its own empty copy above |
| Error | Standard panel |
| Over-cap | **Nothing.** Treatments are never capped — the free tier caps seasons and ewes only |

### 10.4 Actions and tap costs

| Action | Taps | Notes |
|---|---|---|
| New treatment | 1 to open + animal + product + dose + route + batch + withdrawal | every field except the animal is skippable; the withdrawal control is never skipped *silently* — skipping it records `NotRecorded` explicitly |
| **Repeat last treatment** | **2** | tap 1 opens a sheet showing the entire copied treatment — product, dose, route, batch, and the withdrawal as `7 days · as entered by you on 3 Mar 2026`; tap 2 picks the animal and commits |
| Void a treatment | 2 | soft-void; the medicine book shows the void, never loses the row |
| Open the animal | 1 | |
| Export the medicine book | 1 | pushes Export |

**Why "repeat last" does not violate §12.1:** the number being carried forward is *the user's own previous entry*, visible on screen at the moment of the commit tap. The app ships no default and originates no number. The gate is that the figure must be **rendered before the committing tap**, which is why the sheet shows the whole treatment rather than a bare animal picker. Asserted by widget test.

### 10.5 §12 on this screen

- **§12.1**: `Disclaimers.withdrawalProvenance` next to every withdrawal figure; `Disclaimers.withdrawalCaveat` above the entry control.
- **§12.3**: the medicine-book segment carries `Disclaimers.exportFooter` as a permanent 18 pt footer. This is the view someone shows an inspector, so the string belongs on screen and not only in the PDF. It is **referenced**, never re-typed (decision #62); the single-definition test counts one literal in the codebase.
- **§12.5**: administered-at provenance per row.
- **§12.4**: `WarningCode.clearDateDisagrees` is shown and never applied. There is no `fix()`; editing the treatment through the normal repository path is the only thing that writes a new `clear_date`.

---

## 11. Screen 9 — Reminders

**Purpose.** What is overdue, what is due today, what is coming — and an honest statement of what the lock screen will and will not tell you.

### 11.1 The query

`remindersQuery` — one `customSelect`, bucketed by bound Dart-computed boundaries.

```sql
SELECT r.id, r.kind, r.title, r.due_at, r.muted, r.completed_at,
       e.tag AS ewe_tag, l.tag AS lamb_tag,
       CASE WHEN r.due_at <  :startOfToday    THEN 'overdue'
            WHEN r.due_at <  :startOfTomorrow THEN 'today'
            ELSE 'upcoming' END                            AS bucket,
       -- The number the honest line quotes. It counts EXACTLY what reconcile()
       -- is eligible to project: open and unmuted. See the note below.
       (SELECT COUNT(*) FROM reminders r2
         WHERE r2.completed_at IS NULL AND r2.muted = 0)    AS schedulable_total
  FROM reminders r
  LEFT JOIN ewes  e ON e.id = r.ewe
  LEFT JOIN lambs l ON l.id = r.lamb
 WHERE r.completed_at IS NULL
 ORDER BY r.due_at ASC;
```

`readsFrom: {reminders, ewes, lambs}`. `:startOfToday` and `:startOfTomorrow` are epoch millis computed in Dart from `appNow()` — `CURRENT_TIMESTAMP`, `date('now')` and friends are banned (decision #47). The bounds are re-bound by `minuteTickProvider` (§9.2), so the screen re-buckets itself at midnight without a second ticker.

**Muted reminders are listed but never counted, and the copy must not confuse the two.** The list shows every open reminder including muted ones — "nothing nags twice" (§7.6) means it does not *fire* twice, not that it disappears — while `schedulable_total` excludes muted rows, because a muted row is never projected to the OS. If the honest line quoted a total that included them, a shepherd could count fourteen rows on screen against a line reading "all 12 are stored in the app" and conclude the app had lost two. Muted rows carry a "muted" chip (icon + text) and sit at the foot of their bucket.

### 11.2 The reconciliation line — see §17 for the full rule

The screen states the discrepancy in one line, in a box of fixed height so nothing shifts:

| Condition | Copy |
|---|---|
| `stored > scheduled` | "Showing the next 56 reminders on your lock screen. All 312 are stored in the app." |
| `stored == scheduled` | "All 12 reminders are on your lock screen." |
| Alerts not granted | "Lock-screen alerts are off. All 12 reminders are stored in the app." + a 72 pt **"Turn on alerts"** |

Both numbers are read from data — `app_settings.last_reconcile_scheduled` and the query's `schedulable_total`. **Never hard-code 56 in copy**; it is `ReminderBudget.forPlatform()` (`abstract final class ReminderBudget` in `lib/domain/reminder_budget.dart` — 56 iOS / 200 Android, `CONVENTIONS.md` §2.14, R50), and the same constant is what `ReminderReconciler.reconcile()` slices with, so the copy cannot drift from the behaviour. Rows beyond the OS window carry an "app only" chip (icon + text, never colour alone).

`app_settings.last_reconcile_scheduled` was missing from `03-data-model-and-schema.md` §5.13; `CONVENTIONS.md` R40 adds it as a nullable `integer()` column, written by `reconcile()` in the same transaction that records the projection. Without it the line has no honest source for `scheduled` and would have to count what it hoped it scheduled rather than what it did. §22 item 5.

### 11.3 States

| State | Rendering |
|---|---|
| Frame 1 | Three group headers with three fixed-height row placeholders each — the geometry is known before the data is |
| Loaded | Three `headingLevel: 2` groups: Overdue, Due today, Upcoming |
| Empty | "No reminders. Reminders are created when you record a lambing or a treatment." + "Reminder intervals" |
| Empty in one bucket only | The bucket keeps its heading and shows one 18 pt line — "Nothing overdue." / "Nothing due today." / "Nothing coming up." A missing heading reads as a rendering failure, and "nothing overdue" is the single most reassuring line on this screen at 03:00 |
| Alerts off | As above; the list is fully populated regardless. The database is the truth; the OS is a cache |
| Filtered-empty | Impossible — the buckets are a partition of the open reminders, not a filter |
| Error | Standard panel |
| Over-cap | **Nothing.** Whether the free tier caps reminders is §7.1 open question 17; it changes the reconcile budget, not this screen |

### 11.4 Actions and tap costs

| Action | Taps | Notes |
|---|---|---|
| **Complete** | 1 | For `colostrum` and `navel`, completing writes the `CareEvent` — it is the same tap (decision #43). Then `reconcile()` runs, so the 57th reminder can enter the window |
| Mute | 1 | "Nothing nags twice" (§7.6): a delivered reminder never re-fires |
| Open the animal | 1 | |
| Turn on alerts | 1 | triggers the OS permission request |
| Change intervals | 1 | pushes Settings ▸ Reminders |

**Snooze is not in v1.** It introduces a second time model (due-at versus deferred-until) for a case the mute-plus-recreate path already covers. Recorded as a deliberate omission.

### 11.5 Permission — a refinement of decision #65, stated so it is not re-litigated

Decision #65 says the notification permission is requested "the first time the user creates a reminder, never at first launch". Reminder **rows** are created automatically inside the lambing and treatment transactions (decision #63), so read literally that would put a system permission dialog on screen at 03:24 during the first lambing — precisely the mid-season nag spec §5 forbids.

> **The rule that ships: the permission is never requested from a write path.** It is requested only from an explicit user tap on "Turn on alerts" (this screen) or Settings ▸ Reminders. Until then, reminder rows are written and displayed normally and the OS projection is simply empty, which the screen states honestly.

This narrows #65; it never widens it. `08-platform-integration.md` must carry the same rule. Flagged in §22.

### 11.6 §12 on this screen

- **§12.5** on the source event's time, on every row: a colostrum reminder reads `412 · colostrum · due 03:24 · from a lambing recorded automatically at 01:24`. The reminder's own `due_at` is arithmetic on a user-configurable interval and is not itself an observation, so it carries no provenance label; the **event it came from** does, and that is the one a shepherd needs to judge whether the reminder is still right.
- **§12.2** binds hard: a reminder may state an interval the user set and may never state a clinical window. "Colostrum — your 2 h interval" is a fact about a setting. "Colostrum is needed within 2 hours" is veterinary advice and is banned, including in the notification body, which is the copy most likely to be written carelessly because nobody reviews a string that only appears on a lock screen.
- §12.1, §12.3 and §12.4 do not appear: no withdrawal figure is enterable here, this is not a record view someone shows an inspector, and a reminder cannot contradict anything — it is generated, not entered.

---

## 12. Screen 10 — Season Summary

**Purpose.** The numbers, once a season, in daylight, with their definitions attached.

### 12.1 The query

`seasonFactsQuery` — one `customSelect` with explicit `readsFrom:` producing **raw counts only**. A pure Dart function then assembles each `StatResult` (decision #58), carrying `value` (`double?`), `definition`, `numerator`, `denominator`, `caveats` and `notComputableReason`. A SQL view cannot carry a caveat, which is why the view stops at the counts.

**`?? 0` is a build-breaking defect in `lib/features/season/**` and `lib/features/flock/**`.** `value` is never `0` standing in for unknown; the same season yields 120% / 100% / 80% / 200% under four legitimate definitions, so an unlabelled number is worse than no number.

### 12.2 The statistics, as rendered

| Stat | Definition shown under the number | Not-computable case |
|---|---|---|
| Lambing % | **"lambs born alive per ewe put to the ram"** — verbatim from `LambingPercentageChoice.definition`, never paraphrased, because the same string is printed into CSVs and PDFs that outlive the app (`CONVENTIONS.md` R61). The card may render the formula `lambs born alive ÷ ewes put to the ram` *alongside* it, never instead of it. `app_settings.percentage_definition` defaults to `born_alive_per_ewe_to_ram` under §7.0 ruling 3 (UK/Ireland first, the AHDB convention), and remains user-configurable per §7.8 across the four values doc 03's CHECK allows | "Number of ewes put to the ram has not been entered for this season." **Never falls back to ewes lambed** — that substitution silently changes the definition, which is the §12.4 failure in numeric form |
| Average litter size | "lambs born ÷ ewes lambed" — not configurable | zero ewes lambed → `null` |
| Barren rate | "ewes you marked barren ÷ ewes put to the ram" | caveat: "1 ewe has no recorded outcome. She is not counted as barren." |
| Assisted rate | "lambings scored 2 or higher, per lambing **with an ease score**" | caveat: "1 of 3 lambings has no ease score and is excluded from both sides." Zero scores → `null`, never `0%` |
| Losses | by cause and by age bucket | `stillborn` is its own bucket; a blank cause is `unattributed`, which is our word, not the user-pickable "unknown" |
| Lambing spread | bar chart, births per day | dense and zero-filled — the gaps *are* the information |

Over 100% is normal and is computed, with a caveat: "3 ewes have lambed but only 2 were recorded as put to the ram." Warn, never fix.

### 12.3 The chart

Hand-rolled `SpreadChartPainter`, ~120 lines, with a `semanticsBuilder` (decision #70). No chart package: one static chart does not justify a dependency that must clear the offline allowlist. Rules: 18 pt minimum labels, no hover tooltips (there is no hover), no thin gridlines, ≥60 pt tap target per bar, and **if bars get thinner than that, the chart scrolls horizontally inside its card rather than shrinking**. Golden-tested at three data shapes: one day, a tight 18-day spread, a 60-day straggle.

Under the chart, as a fact and never a judgement: "32 of 48 ewes lambed in the first 17 days." The cycle length is `app_settings.cycle_days`, default 17, `CHECK (cycle_days BETWEEN 1 AND 60)`.

The bucketing key is `lambings.local_date`, the denormalised civil date written in the same statement as `occurred_at` — not a SQL date function on the instant. SQLite cannot bucket by the shepherd's civil day without a timezone database; Dart can, and did, at write time (decision #47, doc 03 §5.4).

### 12.4 States

| State | Rendering |
|---|---|
| Frame 1 | One fixed-height card per stat, in the final geometry, with the definition line already painted — the definitions are static text and do not wait for the counts |
| Loaded | `headingLevel: 1` season label, then one card per stat |
| Partially computable | Each stat renders its own `notComputableReason` in its own card. The screen is never blank because one input is missing |
| Empty | "Nothing recorded in 2026 lambing yet." + "Quick Entry". No empty chart is drawn |
| Filtered-empty | Impossible — the season chip switches the season, it does not filter within one |
| Comparison unavailable | The previous-season strip is **absent**, not shown locked or teased. A free-tier user has exactly one season, and a greyed "unlock to compare" row would be a monetization surface outside the two permitted places |
| Error | Standard panel |
| **Over-cap** | **Nothing on this screen.** The season wall is upstream: under §7.0 ruling 8 the free tier covers one full season, so a free-tier user reaches this screen for their own season and sees it whole. Starting a *second* season is the gated action, and it is gated in Settings ▸ Season (`EntryContext.calm`), not here. Last year's summary is never hidden, blurred or made read-only (§19.4) |

### 12.5 Actions

| Action | Taps |
|---|---|
| Switch season | 1 (a 60 pt season chip) |
| Change the lambing-% definition | 2 (pushes Settings ▸ Season) |
| Export this season | 1 (pushes Export) |
| Read a bar's value | 1 (each bar is its own 60 pt target with a semantic label) |

### 12.6 §12 on this screen

This screen has no entry control, so §12.1 and §12.5 do not appear. The two that do carry the whole weight of the screen:

- **§12.4** as a caveat under each number, never as a badge: "1 of 3 lambings has no ease score and is excluded from both sides." A caveat is a `StatResult.caveats` entry, rendered in the same card as the number it qualifies, at 18 pt, always visible — never behind a tap. Over 100% is computed and caveated, never clamped: "3 ewes have lambed but only 2 were recorded as put to the ram." Warn, never fix.
- **§12.2** is the reason `definition` is a required field on `StatResult` and is rendered under every number. The app may state *"32 of 48 ewes lambed in the first 17 days"* — arithmetic on values the shepherd supplied. It may not state *"your tupping was tight"*, *"your barren rate is high"*, or *"consider scanning earlier"*. The test for the line is mechanical: if removing the user's own numbers leaves an opinion, it does not ship.
- **§12.3** does not appear on screen but binds the export: tapping "Export this season" produces artifacts that carry `Disclaimers.exportFooter` (§13.4).

---

## 13. Screen 11 — Export

**Purpose.** Get the records off the phone. Because there is no cloud, this is a safety feature, not a convenience.

### 13.1 The query

`exportCountsQuery` — one `customSelect` returning row counts per shape plus `app_settings.last_exported_at`. `readsFrom: {lambs, ewes, treatments, appSettings}`.

### 13.2 States

| State | Rendering |
|---|---|
| Frame 1 | Seven fixed-height rows with their labels painted and the counts blank — the labels are static and never wait |
| Loaded | Seven 72 pt rows, each with its row count |
| Empty | "Nothing recorded yet." Buttons **stay live**; a 0-row CSV still carries its disclaimer trailer |
| Building | The row shows determinate progress; the screen never blocks and never covers itself with a modal. PDF generation and image downscaling are the only off-isolate work in the app (decision #125); CSV and JSON at this volume are milliseconds and stay on the main isolate |
| Failed | A persistent SnackBar naming the artifact, plus "Diagnostics". Never the exception message (decision #124) |
| Filtered-empty | Impossible — this screen has no filter |
| Error (read) | Standard panel. Distinct from Failed, which is a *write* outcome on one artifact while the screen itself is fine |
| **Over-cap** | **Nothing. Export is never gated by the free tier, ever** (decision #86). Putting the only backup mechanism behind the cap, in an app with no cloud, is a data-hostage pattern |

### 13.3 Actions

| Action | Taps | Output |
|---|---|---|
| Lambs CSV | 1 | `lambs.csv` → share sheet |
| Ewes CSV | 1 | `ewes.csv` |
| Treatments CSV | 1 | `treatments.csv` |
| Flock book PDF | 1 | split into ewes/lambs volumes rather than crashing on a 120-page season |
| Medicine record PDF | 1 | the one someone hands to a vet |
| Full JSON backup | 1 | **records only** in v1 |
| Media | 1 | offered as a separate share, stated plainly |

Every artifact is delivered through the system share sheet — email, AirDrop, a USB drive, whatever the shepherd already uses. There is no in-app print dialog; printing is the OS Print action from the share sheet.

### 13.4 §12 and the honest wording

All three disclosures appear here, and this screen owns the app's most easily-broken promise.

- **§12.3**: `Disclaimers.exportFooter` verbatim, above the buttons.
- **§12.1**: on the treatments and medicine-book rows.
- **§12.5**: one line — "Times are exported with their source: recorded automatically, entered by you, or edited by you."
- **Backup honesty**: "A lost phone is lost records unless you export." and "This backup contains your records. Photos and voice notes are shared separately."
- **Banned copy, permanently:** *"your data never leaves your phone."* It does, the moment they AirDrop a CSV — which is the backup story the product depends on. The only permitted public wording is the tier-1 + tier-2 sentence in `13-build-ci-release.md`; `tool/check_policy.dart` bans the phrase as literal text anywhere in `lib/` and `assets/`.

---

## 14. Screen 12 — Settings

**Purpose.** The things spec §7.10 names, plus the destructive ones, all done in daylight with two hands.

### 14.1 The query

`settingsProvider` — a single-row watch of `app_settings` plus three counts. This is the only screen with no list statement, and that is legitimate under §1.2.

### 14.2 States

| State | Rendering |
|---|---|
| Frame 1 | The full section list with every label and every control painted at its stored-default position — the sections are static, only the *values* wait. No shift when the row lands |
| Loaded | As below |
| Empty | **Impossible.** `app_settings` has `CHECK (id = 1)` and every column has a default, so the row exists from `onCreate`. A settings screen with no settings is a bug, not a state |
| Filtered-empty | Impossible — no filter |
| Error | The standard panel replaces the *section list only*. Diagnostics stays reachable, because a database read failure is exactly when someone needs it |
| Over-cap | The Unlock section renders its static row (§19.2). Every other section is unaffected: nothing in Settings is gated, hidden or greyed by entitlement |

### 14.3 Sections, in order

| # | Section | Contents |
|---|---|---|
| 1 | Units | kg / lb (`app_settings.weight_unit`), and that is the whole row. **There is no °C / °F control** — ruled 2026-08-01 (decision-record §7.0 row 11, `CONVENTIONS` R76): no v1 table stores a temperature, so `app_settings.temperature_unit` and `temperatureUnitProvider` do not exist either. An unused setting is a 3am tax. If a temperature column ever ships, the column and the control return together as an additive migration |
| 2 | Terminology | the editable `TermLabel` overlay: ewe / gimmer / shearling / theave / hogget. Seeded here, in a `BuildContext`-bearing feature, never in `domain/` or `data/`. A locale change or app update never overwrites a user's term |
| 3 | Reminders | intervals per type, and "Turn on lock-screen alerts" |
| 4 | Season | start date, switch season, start a new season (calm-gated) |
| 5 | Pens | bulk add, rename, reorder, and the turn-out threshold the Pen Board labels as yours |
| 6 | Appearance | **Two independent controls, not one three-way choice.** Palette (`app_settings.palette`, `CHECK IN ('night','amber','red')` — the stored key is byte-identical to `ShedPaletteId`'s key, `CONVENTIONS.md` R35). The three labels are `06-design-system.md`'s, **verbatim**: **Night** / **Amber (recommended)** / **Deep red (best for night vision, hardest to read)** — labelled honestly, because the spec names red-shift twice and it genuinely is harder to read. Separately, a **High contrast** toggle (`app_settings.high_contrast`, boolean), which selects a real higher-contrast palette and is not an alias of the night one (decision #95). There is no light theme: spec §5 makes dark the default, not an option |
| 7 | Keep screen on | `app_settings.wakelock_enabled`, default **off**, session-scoped, 30-minute auto-expiry |
| 8 | Left-handed layout | mirrors the keypad's bottom row and the bottom action bar. `app_settings.left_handed`, `INTEGER NOT NULL DEFAULT 0`, added to doc 03 by `CONVENTIONS.md` R40 — §22 item 5 |
| 9 | Unlock | **Restore purchases sits above Unlock** |
| 10 | Diagnostics | last 20 events, record counts, storage figures, `PRAGMA quick_check`, and a **user-initiated** share. No automatic prompt to send |
| 11 | Data | Restore from backup · Delete a season · Delete everything |
| 12 | About | version, the permitted offline wording, the privacy policy as static text (no `url_launcher`), `Disclaimers.exportFooter` |

### 14.4 Tap costs and the deliberate friction

Every non-destructive setting is reachable in **≤2 taps** from the Settings screen. The destructive ones are deliberately more expensive:

| Action | Taps | Guard |
|---|---|---|
| Delete a season | 4 | typed confirmation; one of the **two** `canPop: false` flows (R85 adds restore); **no undo** |
| Delete everything | 4 | typed confirmation, with "Export first" offered as a 72 pt action above it — offered, never required |
| **Restore from backup** | 4 | states plainly what will be destroyed; imports into a new file beside the live one, validates row counts and `PRAGMA foreign_key_check`, then swaps and reopens. **Never merges.** Refuses a backup whose schema is higher than the app's, with a clear message |

Restore and delete are the only two flows in the app permitted to use `showDialog` — **ruled R85** at N23-T02, against `indelible.md` §7.14's *"the only overlay in the app"*, which is amended in the same commit. The reason is dismissal: a bottom sheet closes when a thumb lands outside it, and a confirmation that destroys every record on the phone must not.

`tool/check_policy.dart` confines `showDialog(` to exactly those two files **in the rule itself**, not in `tool/policy_allowlist.txt` — an `[exempt]` line reads *"that file was excused"* where the truth is *"that file is the exception the design ruled"*, and R56 fixes the allowlist at four lines.

**Restore is also the second `canPop: false` flow**, and §14.3's table is corrected above: once step 12's rename has begun there is nothing to pop back to.

### 14.5 §12 on this screen

- **§12.3** in About, as `Disclaimers.exportFooter` **referenced**, never re-typed (decision #62) — the single-definition test counts one literal in the codebase and Settings is one of the four call sites. Also in the unlock copy: what is being bought is a notebook, not a compliance product.
- **§12.5** does not appear: Settings displays no event time.
- **§12.1** does not appear: no withdrawal figure is enterable. **Reminder intervals are not withdrawal periods** and may carry defaults — that distinction is worth stating once, because "the app ships no default values" is scoped by spec §7.5 to the withdrawal period and a blanket reading of it would leave the reminder intervals unusable.
- **§12.2**: no section may recommend a value. "Ready to turn out" is the user's threshold, the palette labels describe legibility and not eyesight, and Diagnostics offers no interpretation.

Diagnostics carries its own honesty line above the share button: *"This file contains no animal records… You can open it and read it before you send it."* That claim is enforced by decision #124's redaction list — no tags, no note text, no product names, no batch numbers, no withdrawal periods, no media paths — not by a reviewer remembering.

---

## 15. Undo and delete semantics, per verb

There is **no generic `repo.undo(id)`** (decision #69). Undo is defined per verb in the repository, and the label "Undo" is only used where the record genuinely disappears; everywhere else the correction is forward and visible.

### 15.1 The table

> **AMENDED 2026-08-02 (N14-T05), by P1 and P2 together. The four ~~Hard delete~~ rows are STRUCK, and
> so is every "SnackBar" in the Window column.**
>
> P1 gave every record-bearing table `struck` / `struck_at` and requires that every CSV carries the
> columns and every struck row is exported and marked. Indelible Rule 1 is absolute — *"There is no
> delete. Not banned — absent. The concept of erasure does not exist in the product."* So undo on these
> rows is a **strike**: the row keeps its position, its legibility and its place in every query that is
> not explicitly filtering, and the margin prints `STRUCK HH:mm`. `strikeLambing` is the verb
> (`CONVENTIONS §2.13`, added in the same commit); a row that collapses or fades is the bug
> `indelible.md` §7.3's *"the row stays in position"* exists to prevent.
>
> P2 abolished the window definition in §15.2 without supplying a replacement, so the window is now
> `kStrikeWindow` in `lib/core/ui/feedback.dart` — **20 s, proposed rather than ruled**, and carried
> into N14's pull request as a ruling because it is a number a shepherd reads on screen.
>
> **This amendment is load-bearing for two later epics.** A document that still prescribes a hard
> delete will be followed by N16 for `addLamb` and by N18 for foster.
>
> **AMENDED AGAIN 2026-08-02 (N16-T05), for `removeCare`.** The row above said the undo of
> `removeCare` is *"re-insert with the original `RecordedTime`"*, which implies the row was deleted.
> That is **unrenderable**: `indelible.md §7.10`'s **Undone** state prints `D̶O̶N̶E̶ ̶0̶3̶:̶2̶4̶ · UNDONE 03:31`
> — a struck stamp beside a new one — and a deleted row has no stamp to strike. `care_events` carries
> `Struckable` (P1, N00-T05), so `removeCare` sets `struck` / `struck_at`, both times stay on the
> page, and the line does **not** revert to unset. The SnackBar column dies with P2 as everywhere
> else: the confirmation is the line itself.

| Verb | Repository method | Undo does | Window | Visible afterwards |
|---|---|---|---|---|
| Begin a lambing | `beginLambing` | ~~**Hard delete**, allowed only while it has zero child rows~~ → **strike** (`strikeLambing`): `struck = 1`, `struck_at` set | `kStrikeWindow` | the row, struck, in position and legible |
| Add a lamb | `addLamb` | ~~**Hard delete**~~ → **strike** — N16 | `kStrikeWindow` | the row, struck |
| Add a care event | `addCare` | ~~**Hard delete**~~ → **strike** — N16 | `kStrikeWindow` | the row, struck |
| Remove a care event | `removeCare` | ~~re-insert with the original `RecordedTime`~~ **STRIKES** — see the N16-T05 note below | ~~SnackBar~~ the line's own Undone state | nothing |
| **Foster** | `recordFoster` | a **compensating `FosterEvent`** whose `corrects` FK names the event it reverses | SnackBar | *both* events, forever, on both cards |
| **Treatment** | `recordTreatment` | **soft-void** — sets `voided_at` | SnackBar | the row, struck through, in the medicine book |
| Pen a ewe | `enterPen` | **Hard delete** of the occupancy row | SnackBar | nothing |
| Turn out | `exitPen` | clears `exited_at` **and** `exit_reason` on the same row — doc 03's `CHECK ((exited_at IS NULL) = (exit_reason IS NULL))` makes clearing only one of them unstorable — and **only if** no later occupancy exists for that pen or that ewe, because the partial unique index would otherwise refuse the re-open | SnackBar | nothing |
| Edit a timestamp | `correctOccurredAt` | **no undo verb** — `RecordedTime.editedTo` preserves `original_effective` | — | "time edited by you", and what it was edited from |
| Change a status | `setStatus` | **no undo verb** — correct forward | — | the current value, with `updated_at` moved. `ewes.status` is a mutable column and there is no status-history table (`CONVENTIONS.md` R41); the previous value is recoverable from the record's own context |
| Delete a season | `deleteSeason` | **none** | — | nothing. `ON DELETE CASCADE` has already run |
| Delete everything / restore | — | **none** | — | nothing |

### 15.2 The window, stated once

**~~Until the SnackBar is dismissed or the route pops, whichever is first.~~ Struck 2026-08-02 (P2).**
There is no transient message to dismiss, so this definition has no referent.

**The window is `kStrikeWindow` — 20 s — declared in `lib/core/ui/feedback.dart` beside the three
feedback functions, and STATED IN SECONDS beside the affordance.** The ARB message takes
`kStrikeWindow.inSeconds` as a placeholder so the copy and the timer can never disagree; the number is
never typed into copy.

It is measured in **absolute time, never civil time** — a `Duration` compared against instants, so a
window opened at 01:59 on the clocks-back night lasts 20 s and not 3600. Same reasoning decision #3
applies to the withdrawal clear date.

**Still true, and now the only part of the old sentence that is:** no timer that outlives the screen.
The window is tied to the widget that renders the affordance and cancelled on dispose, and it is never
reconstructed after a restart (`01 §4.5`, §15.4). No copy anywhere may say *"you can undo this later."*

### 15.3 Why this is §12.4-compliant

Spec §12.4 forbids *silently correcting the user's entry*. Undo does the opposite of correcting: it removes a record the user made seconds ago, on their own tap, and it never rewrites a value. Anything outside the window becomes a correction-forward in which **both values remain visible** — an edited time shows its original, a corrected foster shows both events, a voided treatment stays in the medicine book. The app never chooses which of two values is right.

`FosterEvents` is append-only and `birth_dam` is immutable by a `BEFORE UPDATE` trigger, so a foster undo *must* be a compensating event; this is a schema fact, not a UI preference. The `corrects` FK has `ON DELETE RESTRICT`, which means the compensating event also cannot be deleted out from under the one it corrects.

**The word "Undo" is only used where the record disappears.** On foster and on treatment the label is different, because a compensating event and a soft-void both leave visible history and calling that "Undo" would be the app claiming to have erased something it did not: the foster SnackBar reads **"Correct this"**, the treatment SnackBar reads **"Void this"**. That is what `SaveReceipt.undoLabel` exists for (`lib/core/ui/feedback.dart`, `CONVENTIONS.md` R31) — the label is a field, not a constant. The distinction is the whole reason decision #69 refuses a generic `undo(id)`.

### 15.4 Undo does not survive process death, and the UI must never imply it does

There is no state restoration (decision #24). On resume after a kill, the SnackBar is gone and **no undo affordance is ever reconstructed from storage**. The wording is factual — "Undo" beside a fact that was just committed — and there is no "you can undo this later" copy anywhere.

### 15.5 There is no draft state, so "Cancel" is not a verb

The row is created on screen entry, not on exit (decision #11). Backing out of Lambing Entry pops the route and leaves a true statement behind. There is no `Save`, no `Cancel`, no `isDirty`, no `commit()`. **Anti-pattern:** any repository method matching `save\w*\(` in `lib/data/`, or a button whose ARB key starts with `save`. `tool/check_policy.dart` fails the build on both.

### 15.6 Swipe-to-delete stays banned

`Dismissible` and `Draggable` are banned outright (decision #101). The persistent Undo on a ≥60 pt `SnackBarAction` is what gives back recoverability without a tracked gesture that fails on a marginal capacitive contact. The default Material `SnackBarAction` is **not** 60 pt — override it in `snackBarTheme` or use the house overlay.

---

## 16. The end-of-day export prompt

Spec §7.9: *"A gentle end-of-day prompt to export, at most once per day, dismissible for the season."*

### 16.1 It is an in-app banner, not a notification — and why

A notification needs `POST_NOTIFICATIONS`, which is deliberately deferred to the moment the user asks for lock-screen alerts (§11.5). A shepherd who never creates a reminder would therefore never receive the one prompt the spec calls a **safety** feature. A banner needs no permission, cannot fire while they are in the shed with their hands full, and honours §5's "zero interruptions" (decision #72).

### 16.2 Where and when

Top of **Quick Entry only**, in a slot above the tag readout. Never on any other screen. Never mid-entry. Never blocking. Every condition must hold:

1. It is the first launch of a **local civil day** (the denormalised local-date rule, not UTC).
2. Writes have occurred since `app_settings.last_exported_at`.
3. `app_settings.last_export_prompted_at` is not today.
4. `app_settings.export_prompt_dismissed_for_season != app_settings.current_season`.
5. No ewe is loaded and no lambing has been opened in this session.
6. **Local time is between 06:00 and 22:00.**

Condition 6 narrows decision #72 and does not widen it. Reason: without it, "first launch of a local civil day" during lambing means 03:00 on night eleven, which is exactly the interruption the banner is supposed to be gentler than. It uses the same quiet window the owner set for the free-tier surfaces (§7.0 ruling 8). Flagged for owner confirmation in §22.

All four `app_settings` columns this needs already exist in doc 03 §5.13: `last_exported_at`, `last_export_prompted_at`, `export_prompt_dismissed_for_season` and `current_season`. Condition 1's "local civil day" is evaluated in Dart against `appNow()`, using the same civil-date derivation as `lambings.local_date`; comparing UTC days would fire the banner an hour early or late depending on the season, which is the kind of small wrongness that makes a shepherd stop trusting the thing.

`last_export_prompted_at` is written when the banner **renders**, not when it is answered, so an unanswered banner does not return the same day.

### 16.3 The wording, and what it may not say

> **You have not exported since 2 Mar 2026.** 41 records since then. A lost phone is lost records.
> `[ Export now ]` `[ Not this season ]`

Both actions are 60 pt. "Export now" pushes the Export screen and **starts no work**. "Not this season" writes `export_prompt_dismissed_for_season` and the banner never appears again this season. There is no third "later" action and no close X: not answering is already free.

Banned: the word "backup" used to mean anything automatic, "sync" in any form, "your data is safe", and any implication that the app protects the records by itself.

### 16.4 Layout consequences

The banner is a real layout state, so it is its own variant in the overflow matrix (§21.2), and the reachability assertion — Quick Entry's primary action on screen without scrolling at 375×667 × textScaler 1.3 — must pass **with the banner shown**. If it does not fit, the filtered-match list loses a row, then the "in the pens" strip; the keypad, the confirm bar and the recents strip never shrink.

---

## 17. The reminder reconciliation rule

### 17.1 The architecture, in one paragraph

The `Reminder` row in SQLite **is** the record; the OS notification centre holds a *windowed projection* of it. The reminder row is written in the same transaction as the lambing or the treatment. One idempotent `reconcile()` projects the soonest **56** (iOS) / **200** (Android) into the OS by `cancelAll()` + rebuild. Apple's hard limit is 64 pending requests per app and the behaviour above it is undefined — three conflicting descriptions and an issue closed `not planned` — so the budget is 56 with eight slots of headroom. A 400-ewe flock generates **several hundred** pending reminders — the exact figure depends on which of the seven §7.6 types are enabled and is not worth quoting to two significant figures; what matters is that it is comfortably above 64. Naive `zonedSchedule()`-on-write is therefore not "mostly fine", it is structurally broken, and it breaks by silently dropping reminders.

**`zonedSchedule()` is never called on a write path.** A platform-channel round-trip inside a drift transaction is banned.

### 17.2 Called from exactly four places

| Trigger | Why |
|---|---|
| App start, after the DB opens | recover from a kill, a reboot, an OS purge |
| `AppLifecycleState.resumed` | timezone change, permission change, notifications delivered while away |
| After any write touching `Reminder`, `Lambing`, `Treatment` or the interval settings | every write commits immediately; so must the projection |
| After a notification tap | the 57th reminder can now enter the window |

Debounced to at most once per 500 ms, run off the paint frame.

### 17.3 What the Reminders screen must state

The OS list and the app list **deliberately disagree**, and the screen says so rather than leaving the shepherd to conclude the app dropped something. The three lines are in §11.2. Rules:

1. **Both numbers come from data.** `scheduled` from `app_settings.last_reconcile_scheduled` — written by `reconcile()` itself, so it records what was projected and not what was intended — and `stored` from the screen's own `schedulable_total`. Never a literal, and never a count of anything the projection would skip (§11.1).
2. **The box is the same height in all three states**, so the list below never shifts.
3. **Rows beyond the window carry an "app only" chip** — icon plus the words, never colour alone.
4. **Never write "some reminders may not fire."** They will fire; they are simply not on the lock screen yet, and they enter the window as nearer ones are completed — provided the app is opened, which a shepherd does several times a night.
5. When alerts are off, the list is unchanged. The database is the truth.

### 17.4 The failure this design removes

Without it, the first symptom of the 64-request ceiling is a lamb that does not get tubed, and there is no screen anywhere that could have told the shepherd why. That is the whole reason the line exists.

---

## 18. Search

Two different problems, deliberately on two different surfaces (decision #35):

| Problem | Where | Mechanism |
|---|---|---|
| Partial tag matching (`12` → 412, 128, 12) | Quick Entry keypad, Flock search box, Foster | **In-memory ranked filter in Dart** over the cached active tags, `rankTagMatches` in `lib/domain/tag_match.dart`. Synchronous, same-frame, no debounce |
| Full-text note search | `Routes.noteSearch(context)` → its own screen in `lib/features/flock/`, reached from the Flock app bar | **FTS5** over the `search_docs` fan-in table, kept in sync by SQL triggers, **200 ms debounce**, `bm25()` ordering, `snippet()` for the excerpt |

FTS5 cannot do the first: trigram matching ignores queries under three characters, and the spec's headline example is two characters. FTS5 availability is a **startup assertion**, not a runtime capability probe — `package:sqlite3`'s bundled build documents `SQLITE_ENABLE_FTS5`; assert once at open and fail loudly. There is no `LIKE` fallback branch to maintain.

The note-search screen's states: **Frame 1** → the search field, already focused and typeable, over an empty result box (the same rule as the keypad: the input works before the data does); **empty query** → "Type to search notes."; **loaded** → results showing the note, its animal and its date with provenance; **filtered-empty** → "No notes match 'watery'." with a "Clear" action; **empty** (no notes exist at all, distinct copy) → "No notes recorded yet."; **error** → standard panel; **over-cap** → nothing, ever. Its actions: type (1 per character), open a result (1), clear (1). It is a shed-adjacent screen but not a shed screen — it renders nothing monetization-related regardless, because the affordance exists in exactly two places (§19.2).

---

## 19. Free-tier cap surfaces

### 19.1 Season-primary, ewe cap secondary

The owner's ruling (§7.0 #8): the free tier covers **one full season**; the ewe cap is a calm secondary gate. The season wall lands exactly where §7.7 says the value is — opening last year's history in season two — so the app asks for money at the moment it has proved itself.

### 19.2 The two surfaces, and the seven screens that have none

| Surface | Where | Copy |
|---|---|---|
| Static row 1 | pinned top of **Flock** | `Free version · covers this season · 22 of 15 ewes · Unlock once for <store price>` |
| Static row 2 | **Settings ▸ Unlock** | Same sentence, Restore above Unlock |

The season leads and the ewe count follows, because that is the shape of the ruling. `<store price>` is `ProductDetails.price` from the store, never a literal (§3.2).

Nothing else, anywhere, ever. **No modal, no interstitial, no self-appearing bottom sheet, no timed prompt, no badge, no colour change to red.** The rows are always present, in the same pixels, at 3 ewes and at 22. A permanent static row converts worse than a well-timed modal; that is the deliberate trade, because this audience is vocally hostile to farm-software nagging.

Quick Entry, Lambing Entry, Lamb Card, Foster and Pen Board render nothing monetization-related at any entitlement state. Ewe Card, Treatments, Reminders, Season Summary and Export also render nothing, because the affordance exists in exactly two places.

### 19.3 The two hard rules on top

1. **Never mid-entry.** `EntryContext.liveEntry` is structurally incapable of returning `BlockedByCap`; it returns `Allow(overFreeCap: true)` and the row is marked `over_free_cap`. Creating ewe #16 at 03:20 succeeds silently.
2. **Never between 22:00 and 06:00.** In that window the Flock row does not render and calm-UI cap decisions degrade to `Allow(overFreeCap: true)`. This requires `FreeTierPolicy.decide` to take the current instant — `decide({context, now, unlocked, ewesInCurrentSeason, seasonCount})`, fixed by `CONVENTIONS.md` R69 in `lib/domain/free_tier.dart` and adopted by `11-monetization-and-store.md`.

### 19.4 What the cap never does

Rows over the cap are real rows. On unlock, `unlocked = 1` and every `over_free_cap` marker clears in one transaction. On *not* paying, **nothing is deleted, hidden, greyed out or made read-only, ever** — a shepherd who tried it for one season and walked away must still open the app in year two and export their CSV. Anything else is data ransom in an app whose selling point is that no company can take their five seasons away.

---

## 20. Cross-screen interaction rules

`06-design-system.md` owns the controls; these five are the *screen-layout* consequences, and every brief above assumes them.

1. **Primary actions live in the bottom third.** A persistent bottom action bar, ≥88 pt plus safe-area inset, on Quick Entry, Lambing Entry, Foster and Pen Board. A top-right "Done" is banned here: on a 6.1–6.7" phone it is the furthest point from a right thumb's pivot and needs a hand-shuffle over a concrete floor.
2. **The top of the screen is information only** — tag, timestamp, summary line. Reading does not require reaching. **Back is a bottom-bar button**, not only the AppBar chevron or the system gesture.
3. **Modal bottom sheets over full-screen pages** for every short pick-one flow — foster target, ease score, birth type, death cause. All three of the permissive Flutter defaults `06-design-system.md` §7 requires typing are typed on every sheet: `showDragHandle: false` (a handle implies a banned gesture), **`enableDrag: false`** (the default is `true`, and it is drag-to-dismiss), `isDismissible: false` (a scrim tap is not a labelled target). The sheet closes through an explicit 72 pt (`tapPrimary`) Cancel.
4. **Left-handed mirrors** the keypad's bottom row and the action bar order. A third of one-handed users lead with the left thumb.
5. **No screen shows success before its transaction returns**, and every list row is ≥60 pt with a 16 pt gap so a 9 mm contact patch centred on a gap resolves to exactly one row.

---

## 21. What CI proves about screens, and what it cannot

### 21.1 `tool/check_policy.dart` (one gate, one rule table, one exit code)

| Rule | Fires on |
|---|---|
| Banned widgets | `Dismissible`, `Draggable`, `Tooltip`, `InteractiveViewer`, `onLongPress:`, `CircularProgressIndicator` in `lib/features/**` |
| Banned dialogs | `showDialog(` outside the two allowlisted destructive files |
| Banned stream combination | `combineLatest` / `Rx.combineLatest` in `lib/` |
| No Save | `save\w*\(` in `lib/data/`; ARB button keys starting with `save` |
| Banned Riverpod-3 APIs | the **nine** spellings in decision #18, each its own row |
| Design tokens | raw `Color(0x…)`, `Colors.*`, magic sizes in widgets |
| Banned copy | *"your data never leaves your phone"*, and any re-typing of `Disclaimers.exportFooter` |
| Hard-coded price | a currency symbol followed by digits in `lib/**` or `assets/**` — the price comes from `ProductDetails.price` (§3.2) |
| Clock | `DateTime.now(` or `clock.now(` outside `lib/core/time/app_clock.dart` — `appNow()` is the app's only wall-clock reader |
| Layers | `lib/features/**` importing `core/db/`, `package:drift/`, `package:sqlite3/`, or a sibling feature |

### 21.2 Widget and golden tests

| Test | Asserts |
|---|---|
| `test/features/overflow_matrix_test.dart` | **252 cells: 14 pumpable variants × {375×667, 390×844, 430×932} × textScaler {1.0, 1.3, 2.0} × boldText {false, true}** — no `RenderFlex` overflow, no exception. Decision #114's "216" is 12 screens × 18 and predates two variants this document adds: the note-search screen (§18) and Quick Entry with the export banner shown (§16.4). The arithmetic must match the screen list or the number becomes decorative |
| reachability assertion | the primary action of Quick Entry, Lambing Entry and Foster is on screen without scrolling at the smallest device × textScaler 1.3 |
| `test/features/tap_budget_test.dart` | the three budgets in §1.3, by keyed finders |
| `test/features/no_monetization_test.dart` | pumps Quick Entry, Lambing Entry, Lamb Card, Foster and Pen Board with `unlocked: false, ewesInCurrentSeason: 99` and finds no upgrade widget |
| tap targets | `MinimumTapTargetGuideline(size: Size(60, 60), …)` **plus** a geometric gate that catches edge-flush and semantics-free nodes. Every run begins `final handle = tester.ensureSemantics(); addTearDown(handle.dispose);` — without a live handle the guideline throws instead of checking |
| double-tap | one `tester.tap(); tester.tap();` per committing action |
| goldens (~8) | Quick Entry, Pen Board at three data shapes, the spread chart at three data shapes, the withdrawal control. Dark theme, tagged `golden`, one runner, one pinned Flutter version, not a per-PR gate |
| `test/policy/` | spec §12 as executable assertions, including "no numeric default reaches a withdrawal field" and "every export artifact carries the footer" |

Widget tests use `DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true)` — real SQLite, never a mock. Forget `closeStreamsSynchronously` and every stream-touching widget test fails with a pending-timer error.

### 21.3 What CI cannot prove

Legibility under a head torch, whether six taps *feels* like fifteen seconds with a lamb under one arm, whether the pen board reads from three metres, and whether a gloved thumb finds the confirm key. Those close on the field night (§7.1 open question 1) and the ziplock-bag capacitance test (question 2), and no test in this repository is a substitute for either.

---

## 22. Open items this document depends on

Items 1–6, 8 and 13 were cross-document contradictions this review surfaced; **`CONVENTIONS.md` §6 has since ruled on every one of them**, and the rows below record the ruling and who still has to make the edit. Items 1, 3 and 5 are schema changes that must land **before the first schema snapshot**. The rest are genuinely open and belong to the owner or to a test that has not been run.

| # | Item | Status | Who closes it |
|---|---|---|---|
| 1 | **`lambings.declared_birth_type` nullability** | **Settled — `CONVENTIONS.md` R6 (owner ruling): the column is nullable.** `01-architecture.md` §6 inserts `Value.absent()`; doc 03 §5.4 declared it NOT NULL with no default, and `beginLambing` would throw `SQLITE_CONSTRAINT_NOTNULL` on a fresh install (§6.3). The name is `declared_birth_type`, never `birth_type`. **Must land before the first schema snapshot** | doc 03, then doc 01 |
| 2 | **`treatments` has no `clear_date` and no `withdrawal_days`** | Correct per doc 03 — they live on `treatment_withdrawals`, 0..n per treatment. §3.1, §9.1 and §10.1 have been rewritten to join the child table. Any sibling doc still reading `treatments.clear_date` is wrong | doc 09, doc 11 |
| 3 | **The §12.5 provenance quad on four more tables** | **Settled — `CONVENTIONS.md` R37:** doc 03 adds `captured_at` / `original_effective` / `time_source` to `PenOccupancies`, `FosterEvents`, `Notes` and `EweObservations`, plus `notes.occurred_at` distinct from `created_at`. §4.1, §8.6 and §9.6 all depend on it. **Until it lands, none of those four has an edit verb** — an auto label must be unfalsifiable, not merely unchallenged. **Must land before the first schema snapshot** | doc 03 |
| 4 | **Status-change history rows, and where "barren" lives** | **Settled — `CONVENTIONS.md` R41 and R42:** there is no `ewe_status_events` table; `ewes.status` stays a mutable column with `updated_at` moving, and §4.3/§15.1 no longer claim a history row. "Barren" is `ewe_seasons.status = 'barren'`, a season participation outcome — not a `status` value and not an `EweObservations` row; the §7.7 filter joins `ewe_seasons`. R41 leaves one escalation open: if the retention story needs "culled in March, un-culled in April", that is a schema addition and needs the owner | closed; escalation with the owner |
| 5 | **Two `app_settings` columns this document uses** | **Settled — `CONVENTIONS.md` R40:** doc 03 adds `last_reconcile_scheduled INTEGER` (nullable, written by `reconcile()` in the same transaction that records the projection — §11.2, §17.3) and `left_handed INTEGER NOT NULL DEFAULT 0` (§14.3 §8, §5.4). **Must land before the first schema snapshot** | doc 03 |
| 6 | **`rankTagMatches` is placed in a feature folder** | **Settled — `CONVENTIONS.md` R27: `lib/domain/tag_match.dart`**, holding both `rankTagMatches` and `TagIndexEntry`. Doc 03 §9.1 shows it at `lib/features/quick_entry/tag_matcher.dart`; the Flock search box and Foster both call it and §21.1 forbids one feature importing another, so that placement is unbuildable, not merely inconsistent | doc 03 |
| 7 | ~~**`HapticFeedback.successNotification()` is unverified**~~ | **CLOSED 2026-08-01 (N09-T09).** Grepped against the installed 3.44.8 SDK: all three notification members exist in `packages/flutter/lib/src/services/haptic_feedback.dart`. The `heavyImpact()` fallback is not needed. `CONVENTIONS §7` item 4 declined to rule because it is an SDK fact rather than a name — and the way to settle an SDK fact is to read the SDK | doc 06 |
| 8 | **Overflow matrix arithmetic** | **Settled — `CONVENTIONS.md` R58: 252 cells over 14 pumpable variants.** Decision #114's 216 (12 screens × 18) predates note search and the banner variant (§21.2) and is superseded with the reason stated. Doc 12 must carry the same number | doc 12 |
| 9 | The field night in a real lambing shed (§7.1 #1) | **Open, highest value in the project.** Every tap count here is a desk estimate until it happens; only the three budgets in §1.3 are held by CI | owner |
| 10 | Ziplock-bag capacitance (§7.1 #2) | Open. If taps do not register, the interaction model changes and every brief here is re-cut | hardware test |
| 11 | Notification permission requested only from an explicit tap (§11.5) | Refines decision #65. `08-platform-integration.md` must carry the same rule | doc 08 |
| 12 | Export banner quiet hours 06:00–22:00 (§16.2) | Narrows decision #72 using the owner's 22:00–06:00 precedent. **Needs owner confirmation** | owner |
| 13 | `FreeTierPolicy` taking the current instant (§19.3) | **Settled — `CONVENTIONS.md` R69:** `FreeTierPolicy.decide({context, now, unlocked, ewesInCurrentSeason, seasonCount})` takes `now`, because the 22:00–06:00 quiet window needs it. Doc 11 adopts the type as printed in `CONVENTIONS.md` §2.10 | doc 11 |
| 14 | Exact price (§7.1 #4) | €10–15 is a range. Nothing here depends on the number, because the copy reads `ProductDetails.price` (§3.2) | owner |
| 15 | ~~°C/°F setting (§14.3 §1)~~ | **Closed 2026-08-01 — it does not ship.** No v1 table stores a temperature, and the column is dropped with the control (decision-record §7.0 row 11, `CONVENTIONS` R76) | ruled |
| 16 | Does the free tier cap reminders? (§7.1 #17) | Open. Changes the reconcile budget, not screen 9 | owner |
| 17 | Voice-note cap 60 s or 120 s (§7.1 #18) | Open. Changes only the recording control's copy | owner |
| 18 | `milk` withdrawal target in the v1 **UI** (§7.1 #10) | Open. It is in the v1 schema and sealed type either way (§10.2) | owner |

---

## Definition of done

Tick every line before calling the screen layer finished.

- [ ] All twelve screens exist, each with **one** content statement, and no displayed value is computed from two drift streams.
- [ ] Every aggregate goes through `customSelect` with an explicit `readsFrom:`; no `groupBy` in a Dart-defined view.
- [ ] The first frame is an interactive Quick Entry keypad with zero data, and no screen shows a spinner in any state.
- [ ] Every screen's empty, filtered-empty and error states are implemented from the table in §2.2 — same box, one action, no illustration. Where a brief declares a state impossible, the brief says why.
- [ ] Every SQL statement in this document names only columns that exist in `03-data-model-and-schema.md`. Run it: open an `AppDatabase(NativeDatabase.memory())` at `kSchemaVersion`, then `EXPLAIN` each statement against it. A statement that references a missing column fails at parse, which is the cheapest possible discovery of §22 items 1, 3 and 5.
- [ ] On a fresh install, a lambing is recordable for a new ewe without opening Settings. Integration test green.
- [ ] The three tap budgets pass: 6 taps unlock→lambing, 1 tap foster reassignment, 2 taps repeat treatment.
- [ ] The **252-cell** overflow matrix passes — 14 variants including note search and Quick Entry with the export banner shown — and the reachability assertion holds at 375×667 × textScaler 1.3.
- [ ] `no_monetization_test.dart` passes on all five shed screens at `unlocked: false, ewesInCurrentSeason: 99`.
- [ ] The Flock upgrade row does not render between 22:00 and 06:00, and no calm-UI cap decision blocks in that window. Its copy names the **season** first and the ewe count second, and contains no currency literal — the price comes from `ProductDetails.price`.
- [ ] Every `RecordedTime` rendered anywhere carries its provenance label, including on Pen Board tiles. Every table whose time is rendered carries the full quad, and **no table without the quad exposes an edit verb** (§22 item 3).
- [ ] Every screen brief has a "§12 on this screen" section, including the four that state which disclosures do *not* appear and why.
- [ ] The withdrawal control has no pre-filled number and no pre-selected option; the schema JSON shows null `defaultValue` and null `clientDefault` for `days`.
- [ ] `Disclaimers.exportFooter` appears as a literal exactly once in the codebase and is referenced by the Export screen, the medicine-book segment, Settings ▸ About and every export writer.
- [ ] Every warning surfaces as ~~a 60 pt amber strip~~ **a query mark plus a madder underline** (N16-T06) or a row badge; no `warnings` column exists and no code path fixes a contradiction.
- [ ] Undo is implemented per verb per §15.1; no `undo(id)` method exists; no undo affordance is ever rebuilt after process death. The label reads "Undo" only where the row disappears — "Correct this" on foster, "Void this" on treatment.
- [ ] `reconcile()` is called from exactly four places, debounced 500 ms, never from inside a drift transaction, and writes `last_reconcile_scheduled` in the same transaction that records what it projected.
- [ ] The Reminders screen renders all three reconciliation lines with numbers read from data, and the box height is identical in each. Muted reminders appear in the list and are excluded from `schedulable_total`, and no copy conflates the two counts.
- [ ] Every pen status carries colour **and** shape **and** text, verified with the Grayscale filter on a device.
- [ ] Every heading uses `headingLevel:`; `Semantics(header: true)` appears nowhere.
- [ ] `tool/check_policy.dart` passes with every rule in §21.1 active.
- [ ] Tap-target runs begin with `tester.ensureSemantics()` and a tear-down.

---

## References

Sources this document actually relies on. Fetch dates as recorded in the decision record and its notes (2026-07-27 unless stated).

**Project documents**

- `docs/research/00-tech-decisions.md` — the canonical decision record; §2 rows, §3 offline-purity wording, §4 dropped/degraded list, §5 versions, §6 corrections, §7.0 owner rulings.
- `shed-book-spec.md` — §5 (the 3am test), §7.1–7.10 (features), §9 (screens), §12 (safety rules), §14 (money), §15 (success criteria), §17 (open questions).
- `docs/research/raw/05-design-system-3am.md` — §9 keypad, §10 feedback and the saved affordance, §11 reachability, §12 pen-board glanceability.
- `docs/research/raw/06-platform-integration.md` — §1.4 the 64-request ceiling and the reconcile function, §1.5 timezone handling at the notification seam.
- `docs/research/raw/07-monetization-and-release.md` — §3.2 `EntryContext` and `FreeTierPolicy`, §3.3 upgrade-affordance constraints, §3.4 over-cap data rules.
- `docs/research/raw/08-performance-and-reliability.md` — §1.4 the no-data first frame, §1.5 the no-white-flash recipe.
- `docs/research/raw/09-domain-correctness.md` — §1.1 withdrawal types, §1.3 `Disclaimers`, §1.5 `RecordedTime`, §3.6 editable timestamps, Part 4 statistics, Part 5 fostering, Part 7 the warning catalogue, Part 8 search.
- `docs/research/critique/c4-completeness.md` — findings 2, 3, 4, 5, 11, 12, 13, 15, 17.

**Sibling engineering documents**

`01-architecture.md` · `02-state-di-navigation.md` · `03-data-model-and-schema.md` · `05-domain-correctness.md` · `06-design-system.md` · `08-platform-integration.md` · `09-export-formats.md` · `10-accessibility-and-i18n.md` · `11-monetization-and-store.md` · `12-testing.md` · `CODE-REVIEW-CHECKLIST.md`

The specific sections every SQL statement and every class name above was checked against, because a screen brief that invents a column is worse than one that omits it:

- `03-data-model-and-schema.md` §2 (the `Identified` mixin), §5.2–§5.13 (every table's columns), §6 (the partial unique tag indexes), §7 (`lamb_rearing`), §8 (`penBoard`, `inThePens`, hours-since-penned), §9 (`rankTagMatches`, `search_docs`).
- `05-domain-correctness.md` §3.5–§3.8 (`clearDateFor`, `computeWithdrawalStatus`, `checkClearDate`), §4.1–§4.3 (`RecordedTime`, the quad, how it renders), §6.1 (`StatResult`), §7 (`WarningCode` and the catalogue), §7.4 (`Disclaimers`).
- `02-state-di-navigation.md` §7 (`rankTagMatches` placement), §8.1 (`RouteNames`, `Routes`), §8.3 (`PopScope`, the single `canPop: false`).
- `06-design-system.md` §2 (`snackBarTheme`, `insetPadding`), §3 (the token names), §5.1 (the type scale), §6 (`tapPrimary` 72 / `tapHero` 88 / 60 pt floor), §8.2 (the keypad geometry contract), §10 (the haptic vocabulary — see §22 item 7).

**Primary sources**

- Apple Developer Forums thread 811171 — the 64 pending-notification-request limit per app. <https://developer.apple.com/forums/thread/811171>
- `flutter_local_notifications` issue #2312 — a third, conflicting description of the over-limit behaviour; closed `not planned`. <https://github.com/MaikuB/flutter_local_notifications/issues/2312>
- SQLite FTS5 — *"Substrings consisting of fewer than 3 unicode characters do not match any rows when used with a full-text query."* <https://www.sqlite.org/fts5.html>
- SQLite foreign keys — child-key indexes are not created automatically; enforcement is off by default. <https://www.sqlite.org/foreignkeys.html>
- SQLite SELECT — `ORDER BY` and `LIMIT` apply to the compound SELECT as a whole, which is why each deck bucket is a CTE. <https://www.sqlite.org/lang_select.html>
- W3C WCAG 2.2, SC 1.4.1 Use of Color. <https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html>
- drift issue #3338 — two streams updated in one transaction can emit at different times; maintainer: *"generally is working as intended"*. <https://github.com/simolus3/drift/issues/3338>
- flutter#139712 — with Bold Text on, w800/w900 render lighter, at w700. <https://github.com/flutter/flutter/issues/139712>
- AHDB, *Reducing Lamb Losses for Better Returns* — the lambing-percentage convention adopted as the UK/Ireland default.
- Sheep Genetics, *Understanding Lambing Ease ASBVs* — *"a blank score indicates the lambing ease was not scored."* <https://www.sheepgenetics.org.au/globalassets/sheep-genetics/resources/lambing-ease-scoring-guideline.pdf>
- Hoober, *How Do Users Really Hold Mobile Devices?*, UXmatters 2013 — 49% one-handed; of those, 67% right thumb. <https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php>

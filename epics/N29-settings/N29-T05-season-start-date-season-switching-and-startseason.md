# N29-T05 — Season start date, season switching and `startSeason`

| | |
|---|---|
| **Epic** | [N29 — Settings](epic.md) · `00-README` §9 step 10 (4 of 4) |
| **Task** | 5 of 8 |
| **Depends on** | N29-T04 |
| **Commit** | one commit · `feat(settings): season start, switching, and the gated startSeason verb` |

## 1. Why this task exists

The second of the two cap-gated verbs. Switching seasons changes what every screen reads;
the season start date is the boundary the spread and the statistics are computed against.

`11 §7.2` gives `startSeason` its signature and names it as *"the second gated write"*. `11 §2`'s own
inventory records why nobody has written it: *"`SeasonRepository` already owns `seasons`; **the verb is
the second gated write and no document names it**."* `FlockRepository.createEwe` has consulted
`FreeTierPolicy` since N14-T01; this is its pair.

The other half is the switch. `app_settings.current_season` is a nullable FK with `ON DELETE SET NULL`
and `SeasonRepository` owns it. Every season-scoped screen in the app — the Pen Board, Treatments,
Reminders, the Season Summary, the lambing-spread chart, the export counts — reads it directly or
reads a provider derived from it. Changing it must move all of them, **without a single
`ref.invalidate`**, because `stream.invalidate` bans that under `lib/` with exactly one exemption and
it is not this one.

And the start date is a `LocalDate`. Not an instant, not a `DateTime`, not "midnight on the day": it is
the civil boundary the spread histogram buckets against and the `lambingBeforeSeasonStart` warning
compares to.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/11-monetization-and-store.md` | **§7.2** (`startSeason`'s signature, printed; the decision and the insert in **one transaction**; the policy reads `appNow()` in `lib/data/`) · **§7.3** (the two `RefusalReason` messages, with the cap as a placeholder) · **§7.4** (*"a calm gate that lands inside the quiet window is not deferred — it is **forgiven, permanently**"*; and the restored multi-season case) · §2 (the inventory row that says no document names this verb) | the gate |
| `docs/engineering/03-data-model-and-schema.md` | **§5.1** (`Seasons`: `year`, `label` 1–60 chars, `start_date` as `LocalDateConverter` with a `GLOB` `CHECK`, `end_date >= start_date`, `ewes_to_ram` **with no default**, `over_free_cap`) · §5.13 (`app_settings.current_season`, `ON DELETE SET NULL`; the FK-index exemption) · §5.14 (`SeasonRepository` owns `seasons`, `ewe_seasons`, `app_settings.current_season`) | the columns and their `CHECK`s |
| `docs/engineering/CONVENTIONS.md` | §2.1 (`SeasonId`) · §2.2 (**`LocalDate`**: `LocalDate(y,m,d)`, `LocalDate.of(Instant)`, `LocalDate.parse` strict) · §2.10 (`EntryContext`, `CapDecision`, `Allow`, `BlockedByCap`, `RefusalReason`, `FreeTierPolicy.decide`) · §2.13 (`SeasonRepository`'s verbs) · §3.1 (`settingsProvider`, `freeTierPolicyProvider`) · §3.2 (`seasonFactsProvider` is a `.family` over `SeasonId`) · §4.5 + R59 · **R33** (an id crosses a boundary; a bare `int` does not) · R60 | **BINDING** on the type, the verb and the key |
| `docs/engineering/07-screens.md` | **§14.3 row 4** (Season: start date, switch season, start a new season — **calm-gated**) · §14.4 (≤ 2 taps) · §19.1 (season-primary) · §19.3 (the two hard rules) · §19.4 (*"rows over the cap are real rows … **nothing is deleted, hidden, greyed out or made read-only, ever**"*) | the section |
| `docs/engineering/05-domain-correctness.md` | §2 (the time model; `LocalDate` is `TEXT 'YYYY-MM-DD'`, an instant is `INTEGER` epoch millis; **decision #2 is irreversible after the first snapshot**) · §6 (the statistics computed against the season boundary) · §7 (the five safety rules) | why the start date is a civil date |
| `docs/engineering/02-state-di-navigation.md` | §4.1–§4.2 (a drift `watch()` re-emits; no invalidate needed) · **§9.1** (the one legitimate `ref.invalidate` in the codebase — `minuteTickProvider` on resume — and therefore the only one) · §5.1 (the graph) | how the switch propagates |
| `docs/engineering/12-testing.md` | §2.2–§2.4 (`atFixed`, the ambiguous hour, the two candidate instants) · §3.1 (`testDatabase()`) · §5.1 (`pumpApp`) | how the DST case is written |
| `docs/research/00-tech-decisions.md` | **#2** (instants `INTEGER`, civil dates `TEXT`) · #91 (season-primary) · §7.0 ruling 8 (nothing surfaces 22:00–06:00) · §7.0 ruling 3 (UK/Ireland; the ambiguous hour is **01:00–01:59**) · #108 (never an all-numeric date in front of a human) | the decisions applied |
| `docs/design/indelible.md` | §8 screen 12 (*"Season start date and a `SWITCH SEASON` line"*) · §7.13 (word button) | the control |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | `startSeason` is an event verb and the second gated one |
| `shed-monetization` | the free tier is season-primary, so this verb is where the cap speaks |

`LocalDate`'s shape and the ambiguous-hour derivation are `05 §2`'s and `12 §2.4`'s, cited in Sources
and spelled out in §5.3; the skill budget is two auto-firing and the two above are the ones that decide
whether the **verb** is right rather than whether its date arithmetic is tidy.

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/settings_test.dart`
- **Test** — `'startSeason is gated by FreeTierPolicy and switching seasons re-reads every screen'`
- **Why it is red today** — there is one season and no way to start another.

```bash
fvm flutter test test/features/settings_test.dart   # expect: failing, for the reason above
```

Sharpen it into the two halves, because they fail for different reasons and only one of them is about
money:

1. **The gate.** With `entitlements.unlocked = 0`, one season already present, and the clock pinned to
   **14:00** so the quiet window is not in play, call `startSeason(label: '2027', startDate:
   LocalDate(2027, 1, 15), context: EntryContext.calm)` and assert `WriteRefused(RefusalReason.secondSeason)`
   **and** that `SELECT COUNT(*) FROM seasons` is still 1. Then set `unlocked = 1` and assert
   `WriteCommitted` and a count of 2.
2. **The switch.** Seed two seasons with different lambings. Switch `current_season`, pump, and assert
   the Pen Board, the Season Summary and the export counts all render the **other** season's numbers —
   with **no `ref.invalidate` anywhere in the diff**. Assert that last part as source text, in the same
   test, because it is the assertion that fails when somebody makes the switch work the easy way.

**Green.** The minimum code that passes, and nothing beyond it — the verb, the gate, the switch, and the re-read.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Steps 3 (write path), 5 (controller), 6 (UI), 7 (ARB) and 8 (tests).** No schema — `seasons` and
`app_settings.current_season` were frozen at N07-T08. No domain — `LocalDate`, `EntryContext`,
`CapDecision` and `FreeTierPolicy` all shipped in N04 and N06. **Say both out loud in the commit
message.**

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/season_repository.dart` | **Edit.** `startSeason`, exactly as `11 §7.2` prints its signature — the second and last gated write. Also `setSeasonStartDate` if `SeasonRepository` does not already carry one, and `setCurrentSeason` already exists on `SettingsRepository` (N12-T02) — **do not add a second writer for `current_season`**; `03 §5.14` assigns it to `SeasonRepository`, so decide once, in this commit, which of the two owns it, and cite the ruling |
| 2 | `lib/features/settings/widgets/season_section.dart` | **New.** Section 4: the current season's start date (a date control, not a text field), a switch-season row, and a start-a-new-season row |
| 3 | `lib/features/settings/settings_write_controller.dart` | **Edit.** `startSeason(...)`, `switchSeason(SeasonId)`, `setSeasonStartDate(SeasonId, LocalDate)`, all `guard()`ed. The `WriteRefused` arm calls `showCapRow` — the **only** feedback function this screen may reach for, and it is calm, static and never a modal |
| 4 | `lib/features/settings/settings_screen.dart` | **Edit.** Slot the section into `SettingsSection.season` |
| 5 | `lib/l10n/app_en.arb` | **Edit.** The section strings, the switch row, and the two `RefusalReason` messages from `11 §7.3` with `{count}` as a placeholder so the cap number is never typed twice |
| 6 | `test/features/settings_test.dart` | **Edit.** The anchor and the cases in §5.4 |
| 7 | `test/data/season_repository_test.dart` | **Edit.** The verb's own tier: the gate, the transaction, the counts |
| 8 | `test/data/season_ambiguous_hour_test.dart` | **New.** `@Tags(['uk-zone'])` with the `setUpAll` offset guard |

### 5.2 The signatures

```dart
// lib/data/season_repository.dart — 11 §7.2's signature, verbatim.
//
// The SECOND and last gated write. createEwe (N14-T01) is the other. 11 §7.2:
// "the decision and the insert are in ONE transaction, so the count cannot move
// between them", and "the policy reads appNow() in lib/data/, never in
// lib/domain/" — package:clock is banned in the domain (R24) and FreeTierPolicy
// takes `now` as a parameter for exactly that reason.
Future<WriteOutcome> startSeason({
  required String label,
  required LocalDate startDate,
  required EntryContext context,
}) =>
    _db.transaction(() async {
      final decision = ref_free_tier.decide(
        context: context,
        now: appNow(),
        unlocked: await _readUnlocked(),          // inside the transaction
        ewesInCurrentSeason: await _countEwesInCurrentSeason(),
        seasonCount: await _countSeasons() + 1,   // POST-write, as createEwe does
      );
      return switch (decision) {
        BlockedByCap(:final reason) => WriteRefused(reason),
        Allow(:final overFreeCap) => WriteCommitted(
            insertedId: await _insertSeason(
              label: label, startDate: startDate, overFreeCap: overFreeCap),
          ),
      };
    });

/// The switch. One UPDATE of app_settings.current_season inside one
/// transaction. It writes nothing else: a season switch changes what the app
/// READS, never what it has recorded.
Future<WriteOutcome> switchSeason(SeasonId season);

/// The boundary the spread and the statistics are computed against.
/// A LocalDate, not an Instant (decision #2, 05 §2).
Future<WriteOutcome> setSeasonStartDate(SeasonId season, LocalDate startDate);
```

```dart
// lib/features/settings/settings_write_controller.dart
Future<void> startSeason({required String label, required LocalDate startDate}) =>
    guard(() async {
      final repo = await ref.read(seasonRepositoryProvider.future);
      // EntryContext.calm: this is Settings. `liveEntry` is structurally
      // incapable of returning BlockedByCap (11 §7.3) and is the wrong context
      // here — passing it would make the cap unreachable and the free tier a
      // lie by argument.
      return repo.startSeason(
        label: label, startDate: startDate, context: EntryContext.calm);
    });
```

Widget keys, R59 spelling:

```
settings.season.start_date        settings.season.switch
settings.season.switch.2          … one per SeasonId
settings.season.start_new         settings.season.cap_row
```

### 5.3 The details that are easy to get wrong

- **`EntryContext.calm`, and never `liveEntry`.** `11 §7.3` and `07 §19.3`: `EntryContext.liveEntry` is
  *structurally incapable* of returning `BlockedByCap`. Passing it from Settings compiles, passes every
  happy-path test, and silently removes the free tier — the free tier would then exist only in the
  documentation.
- **The count is `+ 1` and post-write, and `unlocked` is read inside the transaction.** `11 §7.2` and
  N14-T01's rule: *"the decision and the insert are in one transaction, so the count cannot move
  between them."* A decision taken outside the transaction is a decision against a count that a
  concurrent write could have moved — and although this app has one writer, the shape is the shape the
  other repositories copy.
- **A calm gate inside the quiet window is forgiven, permanently — and this is not a bug.**
  `11 §7.4`: at 22:30 in the free tier, `isQuietHours` returns `Allow`, `startSeason` commits with
  `over_free_cap = 1`, and rule 1 means *"the app never revokes and never re-refuses."* **Do not "fix"
  it** by deferring the refusal to the morning: *"a refusal that arrives detached from the tap that
  caused it is worse than no refusal, and it would fire while the user is somewhere else in the app."*
  Write it as a named test case with the citation in the test name, so the next reader meets it as a
  decision.
- **A restored multi-season backup closes the gate for a free user, and every record stays readable.**
  `11 §7.4`: `_countSeasons()` on a restored three-season file is over the cap, so both calm gates
  refuse — *"and everything else still works: every restored ewe is readable, editable, searchable and
  exportable, every live-entry write commits, and no row is touched."* `07 §19.4`: nothing is deleted,
  hidden, greyed out or made read-only, **ever**.
- **The refusal is `showCapRow`, never a modal, never a dialog, never a SnackBar.** `CONVENTIONS`
  §2.11 R30: *"calm, static, never a modal."* P2 removes the SnackBar underneath it, so the row is a
  row on the screen — in the section, in the same pixels, at 1 season and at 3.
- **The start date is a `LocalDate`, and the whole point is that it is not an instant.** Decision #2:
  civil dates are `TEXT 'YYYY-MM-DD'`; `store_date_time_values_as_text` is never set and drift
  `dateTime()` columns are never used. `03 §5.1`'s `CHECK (start_date GLOB '[0-9][0-9][0-9][0-9]-…')`
  makes a malformed value unstorable. Writing an epoch-millis midnight here would pass every test on
  the desk and shift by an hour across the March boundary, which is the exact class of bug decision #3
  exists to prevent for withdrawal.
- **Deriving the start date from `appNow()` in the ambiguous hour needs `LocalDate.of(Instant)`, and
  both candidate instants must give the same civil date.** 25 October 2026, 01:30 happens twice; both
  instants are on the 25th, so `LocalDate.of` must return `2026-10-25` for either. It is a one-line
  test and it is the one that catches a UTC-based derivation, which returns the 25th for one candidate
  and — depending on the offset arithmetic — the 24th for the other.
- **`end_date >= start_date` is a plain string comparison and is correct *because* the format is
  fixed** (`03 §5.1`). That is the payoff of the `TEXT` convention; do not "improve" it into a parse.
- **`ewes_to_ram` has no default and must not gain one** (`03 §5.1`): *"a season with a blank
  `ewes_to_ram` is 'I did not record it', not zero and not 'same as lambed'."* The start-a-season row
  must not pre-fill it, and the lambing percentage's denominator is `StatResult.notComputable` until
  the shepherd records it. That is safety rule 4 and safety rule 2 at once.
- **No `ref.invalidate`, anywhere.** `stream.invalidate` bans `ref.invalidate(` under `lib/`, and
  `02 §9.1`'s `ref.invalidate(minuteTickProvider)` on resume is *"the one legitimate `ref.invalidate`
  in the codebase."* The switch propagates because `settingsProvider` is a drift `watch()` and every
  season-scoped read either reads `current_season` **inside its own SQL** or takes the id from
  `settingsProvider.select((s) => s.currentSeason)` as a family argument. Both re-emit for free.
  Reaching for an invalidate here is the shape that leaves one screen twenty minutes stale.
- **`seasonFactsProvider` is `.family<SeasonCounts, SeasonId>`** (`CONVENTIONS` §3.2). Switching the
  season changes the **argument**, which is a different family instance and a fresh subscription. A
  screen that captured a `SeasonId` in its own state at build time will not follow the switch — that is
  the defect the anchor's second half exists to catch, and it renders as a Season Summary that
  confidently shows last year.
- **`current_season` has one owner, and this commit decides which.** `03 §5.14` and `CONVENTIONS`
  §2.13 both assign `app_settings.current_season` to **`SeasonRepository`**; N12-T02's printed
  signature list put `setCurrentSeason(SeasonId?)` on `SettingsRepository`. Both cannot be the only
  writer. **Rule it in writing in this commit and amend the losing document in the same commit**
  (`00-README` §10). The recommendation, with its reason: keep the column's writes on
  `SeasonRepository`, because the switch has to run in the same transaction as the season-scoped
  bookkeeping and because `03 §5.14` is the schema's own ownership table. If it goes the other way,
  `SeasonRepository.switchSeason` delegates and `CONVENTIONS` §2.13 is the line that changes.
- **`ON DELETE SET NULL` means "no current season" is a real state.** `current_season` is nullable and
  T06's season delete can produce a null. Every screen already handles it (the first-run seed sets it),
  but the switch UI must not assume a non-null id and must not write one back defensively.
- **A season label is 1–60 characters and `CHECK (length(trim(label)) > 0)`.** A whitespace-only label
  is `WriteFailed`, never trimmed into a year. Reject with a reason (safety rule 4).
- **Never an all-numeric date in front of a human** (decision #108, R60). `15 Jan 2027`, never
  `15/01/2027`. The numeric form appears only inside CSV, beside an ISO-8601 column. The widget test
  greps the rendered text for `/` and expects none.
- **A bare `int` never crosses this boundary** (R33). `SeasonId`, in the repository parameter, in the
  controller method, in the family key and in the widget key's qualifier.
- **There is no SnackBar and no undo** (P2; `07 §15.1`). Starting a season and switching one are both
  forward-visible: the screen re-prints with the new current season. Deleting one is T06's, and it has
  no undo at all.

### 5.4 The full test set

Three files.

`test/features/settings_test.dart` (appended):

| Case | What it asserts |
|---|---|
| `'startSeason is gated by FreeTierPolicy and switching seasons re-reads every screen'` | **The anchor**, both halves, including the source-text `ref.invalidate` assertion |
| `'the switch invalidates nothing and every season-scoped provider still follows'` | `grep`-equivalent over `lib/` for `ref.invalidate(`: one occurrence, in `lib/app.dart`, for `minuteTickProvider` |
| `'a refusal renders showCapRow and never a modal'` | `find.byType(Dialog)` and `find.byType(SnackBar)` are both `findsNothing`; `settings.season.cap_row` is found |
| `'the cap row renders the same at one season and at three'` | Same `Rect`, same string shape; the number comes from a `{count}` placeholder |
| `'no rendered date on this section contains a slash'` | Walk every `Text`; `d MMM y` only (R60, decision #108) |
| `'a whitespace-only season label is refused and nothing is stored'` | `WriteFailed`; `COUNT(*)` unchanged; nothing trimmed into a year |
| `'switching to a season with no lambings renders the empty summary, not last season's'` | The defect the family-argument gotcha describes, asserted |

`test/data/season_repository_test.dart` (appended):

| Case | What it asserts |
|---|---|
| `'startSeason refuses a second season in the free tier outside the quiet window'` | Clock at 14:00, `unlocked = 0`, one season → `WriteRefused(secondSeason)`, `COUNT(*)` still 1 |
| `'startSeason commits for an unlocked user and marks nothing over the cap'` | `unlocked = 1` → `WriteCommitted`, `over_free_cap = 0` |
| `'a calm startSeason at 22:30 is allowed, marked over the cap, and never re-refused'` · `reason: '11 §7.4 — forgiven, permanently. Do not fix.'` | Clock at 22:30; `Allow(overFreeCap: true)`; the row exists with `over_free_cap = 1`; a subsequent read never revokes |
| `'the decision and the insert are one transaction'` | A forced failure in the insert leaves `COUNT(*)` unchanged and no `over_free_cap` marker behind |
| `'seasonCount is post-write and ewesInCurrentSeason is not'` | The two arguments, asserted against a seeded fixture; mirrors N14-T01's rule |
| `'a season with no ewes_to_ram stores NULL and the percentage is notComputable'` | No default, no zero, no "same as lambed" |
| `'switchSeason writes only app_settings.current_season'` | Row counts on every other table unchanged |
| `'a season label of 61 characters is refused'` | `withLength(min: 1, max: 60)` |
| `'end_date before start_date is refused by the database'` | `CHECK (end_date IS NULL OR end_date >= start_date)` |

`test/data/season_ambiguous_hour_test.dart` — `@Tags(['uk-zone'])`, `setUpAll` asserting
`DateTime(2026, 7, 1).timeZoneOffset == Duration(hours: 1)` and failing with the zone it found
(N04-T08's pattern):

| Case | What it asserts |
|---|---|
| `'a season started at 01:30 in the repeated hour has start_date 2026-10-25 for either candidate instant'` | `atFixed` at both candidates; `LocalDate.of(appNow())` is `2026-10-25` both times |
| `'a season started at 00:59 on the spring-forward night has start_date 2026-03-29'` | The gap, not the overlap. The civil date does not slide when the wall clock jumps |
| `'the quiet-hours arm uses local wall time, not UTC'` | 22:30 local on the clocks-back night is inside the window even though the UTC hour is 21:30 |
| `'the start date round-trips through LocalDateConverter across a close and reopen'` | A real file; write, close, reopen with `seedOnCreate: false`, read `'2026-10-25'` |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. **Season**, never *year* or *campaign*; **the cap** and **the free tier**, never *trial*, *freemium* or *paywall*; **unlock**, never *purchase* or *subscribe*.
- **Never between 22:00 and 06:00** (owner ruling §7.0 #8, `07 §19.3`). The cap row does not render and
  calm cap decisions degrade to `Allow(overFreeCap: true)`. The widget test that proves it **sets the
  clock, not the entitlement** (`06 §12`).
- **Never silently correct an entry** (safety rule 4): a bad label, a bad date and a bad `end_date` are
  all `WriteFailed`. Nothing is trimmed into legality.
- **Never give veterinary advice** (safety rule 2): the season start date is a bookkeeping boundary the
  shepherd sets. No suggested date, no "typical lambing starts", no pre-fill from last year's.

## 7. Definition of Done

- [ ] `'startSeason is gated by FreeTierPolicy and switching seasons re-reads every screen'` passes, and was seen to fail first for the stated reason
- [ ] `startSeason` consults `FreeTierPolicy`
- [ ] the switch invalidates every season-scoped provider
- [ ] the start date is a `LocalDate`, not an instant
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the commit message records that the schema and domain steps are skipped
- [ ] **the DoD line above reads "invalidates" and the implementation must not**: `ref.invalidate(` appears exactly once under `lib/`, in `lib/app.dart` for `minuteTickProvider` (`02 §9.1`). The switch propagates through `settingsProvider`'s stream and through family arguments
- [ ] `startSeason` passes `EntryContext.calm`; `EntryContext.liveEntry` appears nowhere under `lib/features/settings/`
- [ ] the decision and the insert are one transaction, `unlocked` is read inside it, and `seasonCount` is post-write
- [ ] the quiet-window forgiveness is a named test case carrying its `11 §7.4` citation
- [ ] `app_settings.current_season` has exactly one writer, the ruling is recorded, and the losing document is amended in this commit
- [ ] no rendered date is all-numeric (R60), and no bare `int` crosses a boundary (R33)
- [ ] `test/data/season_ambiguous_hour_test.dart` is tagged `uk-zone`, guards its offset in `setUpAll`, and is reported by `TZ=Europe/London fvm flutter test --tags uk-zone`

## 8. Verification

```bash
fvm flutter test test/features/settings_test.dart
fvm flutter test test/data/season_repository_test.dart
TZ=Europe/London fvm flutter test test/data/season_ambiguous_hour_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone --reporter expanded   # confirm the new file is counted
make check
make test
```

```bash
grep -rn "ref.invalidate(" lib/                          # exactly one, in app.dart, minuteTickProvider
grep -rn "EntryContext.liveEntry" lib/features/settings/ # expect zero
grep -rn "currentSeason" lib/data/*.dart                 # one writer; the ruling names which
grep -rn "DateTime\b" lib/data/season_repository.dart    # expect zero — Instant and LocalDate only
grep -rn "dateTime()" lib/core/db/tables/                # expect zero (decision #2)
grep -rn "showDialog(\|SnackBar(" lib/features/settings/widgets/season_section.dart  # expect zero
git diff --stat -- drift_schemas/ lib/domain/            # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(settings): season start, switching, and the gated startSeason verb`

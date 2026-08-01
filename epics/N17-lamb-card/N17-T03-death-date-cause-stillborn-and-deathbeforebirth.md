# N17-T03 — Death — date, cause, `stillborn`, and `deathBeforeBirth`

| | |
|---|---|
| **Epic** | [N17 — Lamb Card](epic.md) · `00-README` §9 step 6 (3 of 5) |
| **Task** | 3 of 5 |
| **Depends on** | N17-T02 |
| **Commit** | one commit · `feat(lamb_card): death recording with stillborn as its own bucket` |

## 1. Why this task exists

A death date, a cause from the **editable** vocabulary, `stillborn` as its own bucket
(never *died at age 0*, which is a different fact and a different statistic), and the
`deathBeforeBirth` warning — which warns and stores exactly what was entered.

Three facts are being kept apart that every simplifying instinct wants to merge. `stillborn` is a
**status**, not a cause; `dc_stillborn` is a **cause** the shepherd may pick, and neither is derived
from the other. `dc_unknown` is a cause the shepherd picked; a `NULL` cause is our word
**unattributed** and it gets its own row in the losses breakdown. And a death date has **day**
resolution, so the first age bucket is *"born and died the same day"* and never *"under 24 hours"* —
claiming the hour would be the silent precision inflation safety rule 4 forbids.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | **§5.5** | `status`, `death_date`, `death_cause`, and the four `CHECK`s that govern which order you write them in |
| `docs/engineering/03-data-model-and-schema.md` | §5.12, **§10.1** | `VocabTerms`' shape, `origin`, `hidden_at`, and the eight seeded `dc_*` keys |
| `docs/engineering/05-domain-correctness.md` | **§6.8** | `LambStatus`, `AgeBucket`, `LambOutcome`, `lossesBreakdown`, and the six edge cases this screen creates |
| `docs/engineering/05-domain-correctness.md` | **§7.5** | rule 4, the `Warning` catalogue, `deathBeforeBirth`'s trigger and verbatim message, and why a warning holds no writer |
| `docs/engineering/07-screens.md` | §7.3, **§7.4** | the tap costs, and §12.5 / §12.4 on this screen |
| `docs/engineering/07-screens.md` | §1.5 | the §12 disclosure matrix — and the provenance claim this table makes that the schema cannot keep |
| `docs/engineering/10-accessibility-and-i18n.md` | **§6.2, §9.2, §9.3** | `showDatePicker` does not ship, no all-numeric date, and the relative-button control that replaces both |
| `docs/engineering/10-accessibility-and-i18n.md` | §5.2 | the four lamb-status rows of the redundancy table — word, shape, colour, position |
| `docs/engineering/CONVENTIONS.md` | §2.6, §2.9, §4.6, §5.1, R17, R37, R53, R66 | `WarningCode`, `LambStatus`, why `death_cause.dart` does not exist, the provenance columns, *unattributed* versus *unknown* |
| `docs/design/indelible.md` | §7.3, §7.7, §7.9, §8 screen 5 | the struck and queried row states, boxed versus unboxed stamps, the chooser as ruled sheet lines, and `RECORD DEATH` |
| `CLAUDE.md` | the five safety rules, the corollary | *a table without the provenance quad has no edit verb* |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | the write, its provenance and its immediacy |
| `shed-safety-rules` | the warning shows and never corrects, and `stillborn` is vocabulary |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/lamb_card_test.dart`
- **Test** — `'a death date before the birth prints deathBeforeBirth and stores both dates unchanged'`
- **Why it is red today** — nothing records a death, and spec §7.3 names the cause list explicitly.

```bash
fvm flutter test test/features/lamb_card_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the fields, the vocabulary lookup, the warning, and the read-back assertion.

Sharpen the assertion: read **both** `lambs.death_date` and `lambings.local_date` back out of the
database **after** the badge has rendered, and assert neither moved. A test that only asserts the
badge appears cannot tell a warning from a correction.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 steps 3 (the write verb), 5 (the controller, which is where the validator runs), 6 (UI
+ ARB) and 7 (tests). **Steps 1 and 2 are skipped and the commit message says so**: the three columns
and their `CHECK`s are N07-T04's, and `WarningCode.deathBeforeBirth`, `LambStatus`, `AgeBucket` and
`lossesBreakdown` are all N06's.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `test/features/lamb_card_test.dart` | edit | The anchor, written first |
| 2 | `lib/data/lambing_repository.dart` | edit | `recordDeath` and `clearDeath` — **one** `_db.transaction()` each, because the `CHECK`s make status, date and cause a single atomic move |
| 3 | `lib/data/settings_repository.dart` | edit | `watchVocabulary(String list)` — the death-cause terms, `origin` either way, `hidden_at IS NULL`, ordered by `sort_order`. `SettingsRepository` owns `vocab_terms` (`CONVENTIONS §2.13`) |
| 4 | `lib/domain/validation/lambing_checks.dart` | edit | `checkLambDeath(...)` beside `checkLambing` — a pure top-level function returning `List<Warning>`, no class, no `Validator` suffix (`05 §7.5` guarantee 1) |
| 5 | `lib/features/lambing/lambing_write_controller.dart` | edit | `recordDeath` / `clearDeath` through `guard()`, and the validator call that populates `WriteCommitted.warnings` — **here**, never in the repository (R53) |
| 6 | `lib/features/lambing/widgets/lamb_status_row.dart` | new | Alive / dead / stillborn over `ShedChoiceRow`, three targets, four rendered states |
| 7 | `lib/features/lambing/widgets/death_date_cell.dart` | new | **Today · Yesterday · 2 days ago · Pick a date**, the last stepping a `d MMM y` value with two ≥ 64 pt arrows. No picker, no free text |
| 8 | `lib/features/lambing/widgets/death_cause_sheet.dart` | new | The vocabulary as ruled 64 px sheet lines inside `ShedBottomSheet`, plus `ADD A CAUSE` |
| 9 | `lib/features/lambing/lamb_card_screen.dart` | edit | The three cells land, and the warning strip renders beneath the field that owns it |
| 10 | `lib/l10n/app_en.arb` | edit | `lambCardStatusAlive/Dead/Stillborn`, `lambCardDeathDateLabel`, `lambCardDeathDateToday/Yesterday/TwoDaysAgo/PickADate`, `lambCardDeathCauseLabel`, `lambCardDeathCauseUnattributed`, `lambCardAddACause`, `warningDeathBeforeBirth`, and the eight `dc_*` labels if N06-T10 has not already seeded them |
| 11 | `test/domain/validation/lambing_checks_test.dart` | edit | The pure half of `deathBeforeBirth` |
| 12 | `test/domain/uk_zone/lamb_card_ambiguous_hour_test.dart` | edit | The 01:00–01:59 case, tagged `uk-zone` |

### 5.2 The signatures

```dart
// lib/data/lambing_repository.dart
// New names, declared here under CONVENTIONS §4.2's event-verb rule and listed in the
// PR body. `recordDeath` matches `recordFoster` / `recordTreatment`; it is one verb
// because the three columns cannot legally move apart (see §5.3 note 1).

/// `status` is `LambStatus.dead` or `LambStatus.stillborn`. `date` may be null —
/// "died, date not recorded" is a real state and lands in `AgeBucket.unknownAge`.
/// `causeKey` may be null — that is *unattributed*, and it is not `dc_unknown`.
Future<WriteOutcome> recordDeath(
  LambId lamb, {
  required LambStatus status,
  LocalDate? date,
  String? causeKey,
});

/// Back to `alive`. Clears `death_date` and `death_cause` in the same statement
/// because the CHECKs make any other order unstorable. See §5.3 note 2 — this is
/// the one verb on this screen that destroys a recorded value.
Future<WriteOutcome> clearDeath(LambId lamb);
```

```dart
// lib/domain/validation/lambing_checks.dart — pure, top-level, holds no writer.
List<Warning> checkLambDeath({
  required LocalDate lambingLocalDate,
  LocalDate? deathDate,
  required LambStatus status,
});
// Fires WarningCode.deathBeforeBirth when deathDate < lambingLocalDate.
// Message, verbatim from 05 §7.5's catalogue: "The death date is before the lambing."
```

Widget keys, per `CONVENTIONS §4.5`:

```
lamb_card.status.alive        lamb_card.status.dead        lamb_card.status.stillborn
lamb_card.death_date          lamb_card.death_date.today   lamb_card.death_date.yesterday
lamb_card.death_date.two_days_ago                          lamb_card.death_date.pick
lamb_card.death_cause         lamb_card.death_cause.dc_starvation   …one per key
```

### 5.3 The details that are easy to get wrong

1. **The four `CHECK`s make status, date and cause one atomic move, and the naive order fails on a
   real phone.** `03 §5.5` ships:

   ```
   CHECK (status IN ('alive','dead','stillborn','sold'))
   CHECK (death_date  IS NULL OR status IN ('dead','stillborn'))
   CHECK (death_cause IS NULL OR status IN ('dead','stillborn'))
   CHECK (death_date  IS NULL OR death_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')
   ```

   "Every field is its own immediate write" is the house rule, and applying it literally here writes
   the date first — against a row still at `status = 'alive'` — and gets `SQLITE_CONSTRAINT_CHECK`.
   The resolution is not to relax the rule: `recordDeath` is **one event verb** that moves all three
   inside one `_db.transaction()`, exactly as `enterPen` moves an occupancy. Tapping `dead` with no
   date and no cause is a legal, complete call.
2. **Going back to `alive` destroys recorded data, and it is the only place on this screen that
   does.** `CHECK 2` and `CHECK 3` make "status alive, date still set" unstorable, so `clearDeath`
   must null both columns in the same statement. There is no history table and no strike mechanism
   at field level, so the date and the cause are gone. **This is an open item, not a decision to make
   quietly**: `07 §7.3` gives the control three states and does not say what a reversal costs. Ship
   `clearDeath`, state the loss in the PR body under the §12.4 question, and let the reviewer rule.
   Do not paper over it with a modal — there is no modal dialog anywhere in this app.
3. **`lambs` has no provenance quad, so the death date carries no provenance stamp.** `07 §7.3` says
   *"seeded from the device date and shown; accepting it records `autoCaptured`, changing it records
   `userEntered`"*, and `07 §1.5` claims a §12.5 tick for the death date. The schema cannot keep
   either promise: R37 added `captured_at` / `original_effective` / `time_source` to
   `PenOccupancies`, `FosterEvents`, `Notes` and `EweObservations` — **not** to `Lambs`.
   `CLAUDE.md`'s corollary is absolute: *a table without the provenance quad has no edit verb*, and
   an `AUTO` stamp beside a value the schema cannot prove was auto-captured is a §12.5 violation in
   the shape of a placeholder. **Ship the death date with no provenance stamp**, keep the *birth*
   time's stamp (it comes from `lambings`, which has the quad), and record the contradiction in the
   PR body. Adding the quad to `Lambs` is a schema change: irreversible, owner-only, out of scope.
4. **The date control is relative buttons plus the keypad, and `showDatePicker` is a gate row.**
   `10 §6.2`, rule `a11y.material_picker`: the picker's dial is a drag, its keyboard mode opens the
   system IME, and its calendar cells are ~32 pt — half the floor. **Today · Yesterday · 2 days
   ago · Pick a date**, where the last steps a `d MMM y` value with two ≥ 64 pt arrows. And there is
   no free-text date field anywhere (`10 §9.3`): a shepherd typing `07/03` means 7 March, and a
   parser reading it as 3 July has corrupted a record while looking helpful.
5. **No date a human reads is all-numeric.** `10 §9.2`: `d MMM y` → `11 Mar 2026`, through
   `formatShedDate(LocalDate, String localeName)`. `dd/MM/yyyy` is the region's convention and the
   app's answer to it is never to render it. `DateFormat.yMd` is the gate row `copy.numeric_date`.
6. **Seeding today's date is not a placeholder, and the difference is the whole point.** Indelible
   §7.12 forbids placeholder text inside a field because in the dark a grey placeholder is
   indistinguishable from an entered value. A death date pre-set to today is rendered in **full ink**
   as a real, visible value the shepherd can see and change — that is `07 §7.3`'s *"and shown"*. Do
   not render it dimmed, and do not render it as a ghost that vanishes on focus. Safety rule 1 is
   about withdrawal periods and does not reach here; if in doubt, the honest fallback is to leave the
   cell unset with its dotted rule, which is never wrong.
7. **`stillborn` is a status; `dc_stillborn` is a cause; neither is derived from the other.**
   `03 §10.1` seeds eight `death_cause` keys and one of them is `dc_stillborn`, while
   `lambs.status` has `'stillborn'` as its own value. Setting the cause because the status is
   stillborn, or the status because the cause is, is the app inferring — §12.2. Record what the
   shepherd tapped, both times, independently.
8. **`stillborn` is never a day-0 death.** `05 §6.8`: it is its own `AgeBucket`, because a stillborn
   lamb has no age at death and folding it in double-counts against any "first 24 h losses" figure.
   `CONVENTIONS §5.1` bans the words *died at birth*, *dead-born* and *"died at age 0"* outright, in
   prose and in code.
9. **A blank cause is *unattributed*, and it is not `dc_unknown`.** `05 §6.8` and `CONVENTIONS §5.1`:
   *"unknown" is a cause the user can pick; "unattributed" is our word for a blank field. Never merge
   the columns.* One `COALESCE(death_cause, 'dc_unknown')` deletes the distinction for every export
   ever written. Give unattributed a prominent row rather than hiding it — in a *studied* population
   Teagasc still records 19% of deaths as diagnosis not reached, so a large unattributed share is
   something real, not a personal failing.
10. **The cause list is a `vocab_terms` FK, not an enum.** R17 deleted `lib/domain/death_cause.dart`
    and it must not come back. `death_cause` references `VocabTerms.key` with `ON DELETE RESTRICT`,
    so a term in use cannot be removed — removal sets `hidden_at`, never a `DELETE`. A user-added
    term writes `origin = 'user'`, a generated key, and a **mandatory** `label`
    (`CHECK (origin = 'seeded' OR label IS NOT NULL)`).
11. **The eight seeded keys have `label IS NULL`, and that is correct.** `03 §10.1`: the keys are
    seeded with `label = NULL` meaning *"render the shipped default for this key"*, and the English
    labels are ARB messages (R66). Reading `vocab_terms.label` and rendering the empty string is the
    failure this split creates; the render is `term.label ?? l10n.<key>`. A test asserts the seeded
    key set and the ARB label set are equal (N33-T05's `vocab_labels_are_complete_test.dart`).
12. **The vocabulary is a second stream, and `07 §1.2` allows it — but not on the content path.**
    The rule is one *content* statement per screen; the cause list is neither a single-row lookup nor
    an app-level singleton, so it must not be watched by the screen. Read it when the chooser sheet
    opens and dispose it when the sheet closes. Never `combineLatest` it with `lambCardProvider`.
13. **The warning is populated by the controller, never by the repository.** `05 §7.5` guarantee 4 and
    R53: `lib/data/**` has **no import path** to `lib/domain/validation/**` — it is its own gate row,
    `layer.data_no_validation`. So `recordDeath` returns `WriteCommitted` with the default empty
    `warnings`, and `LambingWriteController` runs `checkLambDeath` against the freshly-watched row
    and carries the list forward. A repository that could produce a `Warning` is a repository that
    could persist one.
14. **`deathBeforeBirth` compares two `LocalDate`s, not two instants.** `05 §6.8`:
    `lambingDate.daysUntil(deathDate)` — negative → `unknownAge` plus the warning. The lambing side
    is `lambings.local_date`, the stored civil day, **not** `LocalDate.of(occurred_at)` recomputed at
    read time. If the device zone changed between insert and read, the stored value is the record of
    the shepherd's day as it was lived, and `WarningCode.localDateDisagrees` exists to surface a
    mismatch rather than repair it.
15. **The status is never encoded by colour alone.** `10 §5.2`: `dead` → hatch fill + the word
    `DEAD`, grouped after alive; `stillborn` → hatch fill **and** outline + the word `STILLBORN`,
    *"its own word, never folded into 'died'"*. Four differently-coloured shapes is one shape. Turn on
    the OS grayscale filter and read the row — that is the gate.
16. **A dead lamb's card stays fully editable and keeps both dams.** `07 §7.2`: *"A dead lamb keeps
    both dams so the ewe's litter size stays right and the loss stays attributed."* Do not grey the
    card, do not disable the cells, do not remove the lamb from the litter count, and do not turn
    anything red. It prints the word `DEAD` and a date.
17. **A lamb that died before tagging is counted, fully.** Identity is the row id; `tag` is nullable
    at every layer. Keep a tagless dead lamb in the fixtures — `05 §6.8` asks for it by name.

### 5.4 The full test set

**`test/features/lamb_card_test.dart`** — extended.

| Case | What it pins |
|---|---|
| `'a death date before the birth prints deathBeforeBirth and stores both dates unchanged'` | **the anchor.** Read `lambs.death_date` and `lambings.local_date` back **after** the badge renders; assert neither moved |
| `'recording a death writes status, date and cause in one transaction'` | one `updated_at` change, not three; and the naive date-first order is asserted to throw at the data tier |
| `'tapping dead with no date and no cause is a complete, legal write'` | `death_date` and `death_cause` are both `NULL`, `status = 'dead'` |
| `'stillborn is stored as a status and does not set a cause'` | `status = 'stillborn'`, `death_cause IS NULL`; and picking `dc_stillborn` does not change the status |
| `'a blank cause and dc_unknown are two different stored values'` | `NULL` versus `'dc_unknown'`, and two different rendered strings |
| `'the cause list includes a user-added term and excludes a hidden one'` | `origin = 'user'` with a label appears; `hidden_at IS NOT NULL` does not |
| `'a seeded cause renders its ARB label, never an empty string'` | `label IS NULL` → `l10n.dcStarvation`. Note 11 |
| `'no date picker and no free-text date field exist on this screen'` | tree walk: no `showDatePicker`, no `EditableText`; plus the source grep in §8 |
| `'the death date renders as d MMM y and never all-numeric'` | `11 Mar 2026`; a regexp assertion that no rendered string matches `\d{2}/\d{2}/\d{4}` |
| `'the dead and stillborn rows differ in shape and word, not only in colour'` | `10 §5.2`'s two rows |
| `'a dead lamb keeps both dams and stays editable'` | both cells still render; the sex and weight cells still expose tap actions |
| `'a tagless dead lamb renders and is counted'` | `tag IS NULL`, the header reads the untagged string, the row is present |
| `'returning to alive clears both columns and the screen says so'` | `clearDeath`; both `NULL`; the test is named for the loss so a reviewer meets note 2 |
| `'the warning does not gate the write'` | the row is committed **before** the badge is asserted |

**`test/domain/validation/lambing_checks_test.dart`** — extended. Pure, zone-agnostic.

| Case | What it pins |
|---|---|
| `'checkLambDeath fires deathBeforeBirth when the death date precedes the lambing date'` | `warnings.single.code`; the message is the catalogue's verbatim string |
| `'a death on the lambing day fires nothing'` | `daysUntil == 0` → `sameDay`, no warning |
| `'a null death date fires nothing and lands in unknownAge'` | *"died, date not recorded"* is a real state |
| `'Warning exposes no writer'` | source read of `warning.dart`: no `fix()`, no `corrected`, no callback, no `Reviewed<T>.cleaned` |
| `'lossesBreakdown puts stillborn in its own bucket and never in sameDay'` | `05 §6.8`, re-asserted from this screen's side |
| `'a blank cause tallies under unattributed, not under dc_unknown'` | two separate map entries |

**`test/domain/uk_zone/lamb_card_ambiguous_hour_test.dart`** — extended, `@Tags(['uk-zone'])`, run
under `TZ=Europe/London`, with `05 §2.9`'s `setUpAll` offset assertion.

| Case | What it pins |
|---|---|
| `'a lamb born at 01:30 on 25 October and found dead the same morning does not trip deathBeforeBirth'` | the ambiguous hour. `lambings.local_date` is `2026-10-25` for **either** candidate instant, so `daysUntil` is 0 — this is the case that catches a `LocalDate.of()` recomputed from the wrong instant |
| `'a lamb born at 01:30 on 29 March records the corrected wall time and its civil date'` | the **nonexistent** hour, which *is* warned about (`WarningCode.timeDoesNotExistLocally`) — inherited from the lambing, not raised here |

## 6. Constraints that bind this task

- **The five safety rules** — rule 4 (never silently correct an entry), held at **unrepresentable** (`Warning` holds no writer, there is no `warnings` column) and **unpersistable** (`lib/data/` cannot import `lib/domain/validation/`). Rule 5 (honest timestamps) is held here by *omission*: `lambs` carries no quad, so the death date makes no provenance claim — see §5.3 note 3. A rule that drops to merely *documented* has been deleted, whatever the prose says.
- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. Also banned here specifically: *died at birth*, *dead-born*, *died at age 0*, and *unknown* where *unattributed* is meant.
- **3am** — every interactive element ≥ 64 × 64, 18 px text floor, dark only, and none of the banned gestures. The date arrows are taps, never a drag; the chooser is a sheet with no drag handle.

## 7. Definition of Done

- [ ] `'a death date before the birth prints deathBeforeBirth and stores both dates unchanged'` passes, and was seen to fail first for the stated reason
- [ ] `stillborn` is its own bucket in storage and in the statistics
- [ ] the cause list is editable by the user
- [ ] the warning changes nothing
- [ ] *unattributed* and *unknown* are never merged
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/features/lamb_card_test.dart
fvm flutter test test/domain/validation/lambing_checks_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
grep -rn "showDatePicker\|showTimePicker" lib/                 # expect: nothing
grep -rn "dc_unknown" lib/ | grep -i "coalesce\|??"            # expect: nothing
grep -rn "domain/validation" lib/data/                         # expect: nothing (R53)
dart run tool/check_policy.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(lamb_card): death recording with stillborn as its own bucket`

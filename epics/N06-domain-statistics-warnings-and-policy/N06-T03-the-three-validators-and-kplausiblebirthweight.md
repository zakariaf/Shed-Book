# N06-T03 — The three validators and `kPlausibleBirthWeight`

| | |
|---|---|
| **Epic** | [N06 — Domain: statistics, warnings and policy](epic.md) · `00-README` §9 step 2 (3 of 3) |
| **Task** | 3 of 11 |
| **Depends on** | N06-T02 |
| **Commit** | one commit · `feat(domain): the three validators, which cannot fix anything` |

## 1. Why this task exists

Lambing, foster and treatment validation as pure functions returning `List<Warning>`.
They **cannot** fix anything — there is nothing in scope that writes. `kPlausibleBirthWeight` is a
plausibility band, not a limit: a 9 kg lamb is warned about and stored exactly as typed.

Eight of the eleven `WarningCode` members get their producer here. The other three already have one
(`clearDateDisagrees`, N05-T05; `timeDoesNotExistLocally`, N04-T08) or never will in this epic
(`duplicateActiveTag`, N26 — see T02 §5.4).

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §5.4, §7.5 | `kPlausibleBirthWeight`'s bounds and provenance, the four structural guarantees, the eleven-row trigger/message catalogue |
| `docs/engineering/CONVENTIONS.md` | §1 rule 1, §2.3, §2.6, R53 | the file paths, `kPlausibleBirthWeight`'s exact spelling, and the import ban this task must not violate |
| `docs/engineering/12-testing.md` | §10.4 | the assertion that matters is *the record is unchanged*, read back from the database |
| `docs/engineering/03-data-model-and-schema.md` | §5.4, §5.5 | `lambings.declared_birth_type` is **nullable** (R6), `lambs.death_date` is day-resolution |
| `shed-book-spec.md` | §12.4 | the worked example the anchor test reproduces |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-safety-rules` | a validator that corrects is the defect this whole tier exists to prevent |
| `shed-domain` | pure functions over value types, `now` as a parameter |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/validation/lambing_validation_test.dart`
- **Test** — `'a declared twin with three lambs returns birthTypeLambCountMismatch and changes nothing'`
- **Why it is red today** — nothing detects the contradiction the spec §12.4 names by example.

```dart
final w = checkLambing(declaredBirthType: BirthType.twin, lambCount: 3, /* … */);
expect(w.single.code, WarningCode.birthTypeLambCountMismatch);
expect(w.single.message, 'Birth type is twin but 3 lambs are recorded.');
expect(w.single.fieldPath, 'birth_type');
```

```bash
fvm flutter test test/domain/validation/lambing_validation_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — three files of top-level functions, each returning warnings and nothing else.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 step 2 only. Step 1 is skipped and the commit message says so: guarantee 2 of `05`
§7.5 is that warnings are **recomputed on read** and have no column, so reaching the schema here
would be the defect. Step 3 is unreachable by construction — `layer.data_no_validation` (R53) means
`lib/data/` cannot even import what this task writes.

### 5.1 The files, in order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/domain/validation/lambing_checks.dart` | **New.** `const kPlausibleBirthWeight` and `checkLambing`, raising seven of the eight codes below |
| 2 | `lib/domain/validation/foster_checks.dart` | **New.** `checkFoster`, raising `fosterToSelf` |
| 3 | `lib/domain/validation/treatment_checks.dart` | **Extended** (N05-T05 created it for `checkClearDate`). Add `checkTreatment`. Do not move or re-shape `checkClearDate` |
| 4 | `test/domain/validation/lambing_validation_test.dart` | **New.** The anchor plus the seven-code table |
| 5 | `test/domain/validation/foster_checks_test.dart` · `treatment_checks_test.dart` | **New.** One per file under test |
| 6 | `test/domain/uk_zone/lambing_checks_dst_test.dart` | **New**, `@Tags(['uk-zone'])`. The three time-shaped codes across both UK transitions |

### 5.2 The signatures

```dart
// lib/domain/validation/lambing_checks.dart
/// The plausibility band, NOT a limit. Both bounds are inclusive-pass:
/// 1.0 kg and 10.0 kg do not warn. Derived from AHDB's optimum birthweights
/// for 70–85 kg ewes to a terminal sire, widened downward for hill breeds.
/// PROVISIONAL against decision-record §7.1 open question 12.
const ({Grams min, Grams max}) kPlausibleBirthWeight =
    (min: Grams(1000), max: Grams(10000));

List<Warning> checkLambing({
  required BirthType? declaredBirthType,   // nullable: R6
  required int lambCount,
  required RecordedTime time,
  required LocalDate storedLocalDate,
  required LocalDate seasonStart,
  required Instant now,                    // a PARAMETER — D3 bans package:clock here
  required List<Grams?> birthWeights,
  required List<({LocalDate? deathDate, bool isDead})> lambOutcomes,
});

List<Warning> checkFoster({
  required LambId lamb,
  required EweId? currentRearingDam,
  required FosterOutcome outcome,
});

List<Warning> checkTreatment({ /* … */ });   // beside the existing checkClearDate
```

The eight codes this task raises, with the trigger and the message from `05` §7.5's catalogue —
copy the wording, do not paraphrase it, because `07-screens.md` renders it and `09` exports the code
beside it:

| Code | Trigger | Message |
|---|---|---|
| `birthTypeLambCountMismatch` | `expectedLambCount(declared) != lambCount`, and the expected count is not null | "Birth type is twin but 3 lambs are recorded." |
| `lambingInFuture` | `time.effective > now + 2 min` | "This time is in the future." |
| `lambingBeforeSeasonStart` | `LocalDate.of(time.effective) < seasonStart` | "This is before the season start (2026-03-01)." |
| `lambingLongBeforeCapture` | `time.capturedAt − time.effective > 3 d` | "Recorded more than 3 days after the time entered." |
| `implausibleBirthWeight` | `< kPlausibleBirthWeight.min` or `> kPlausibleBirthWeight.max` | "0.4 kg is outside the usual range for a lamb." |
| `deathBeforeBirth` | a lamb's `death_date` < the lambing's local date | "The death date is before the lambing." |
| `localDateDisagrees` | `storedLocalDate != LocalDate.of(time.effective)` | §6.9 — the stored value is a record of the shepherd's day as it was lived |
| `fosterToSelf` | `outcome` is `ToEwe(e)` and `e == currentRearingDam` | "That lamb is already on this ewe." |

### 5.3 The signature decision you have to make in this commit

`05` §7.5 guarantee 1 spells the entry point `List<Warning> checkLambing(Lambing lambing, List<Lamb>
lambs)`, and `12-testing.md` §10.4 calls it that way with two drift rows read back from the database.
**That signature cannot compile.** `Lambing` and `Lamb` are drift row classes generated into
`lib/core/db/database.g.dart`; layer rule 1 gives `lib/domain/` `{lib/domain/, dart:*, meta,
collection}` and nothing else, and D2 bans `package:drift` outright. The gate's `layer.domain` rule
fails the build before `analyze` gets to it.

**Take the named-parameter shape above.** It keeps everything the documents actually bind — the
`check<Thing>` → `List<Warning>` shape, one function per file, no class, no `Validator` suffix — and
it invents no type name, so `CONVENTIONS` §2 needs no new row. `05` §6.8 already sets the precedent:
the domain takes plain records (`LambOutcome`), never rows.

Two consequences to write down rather than discover:

1. `12-testing.md` §10.4's snippet becomes `checkLambing(declaredBirthType: …, lambCount:
   lambsBefore.length, …)` built from the rows at the call site. The **property** it asserts — a
   query with no writer, the row unchanged afterwards — is untouched, and 12 §10 says in as many
   words that the property never depended on the name.
2. Per `00-README` §10's amendment rule, note the deviation in the commit message and raise it
   against `05` §7.5 and `12` §10.4 rather than leaving two documents describing an uncompilable
   call. If instead you prefer a record typedef, it is a **name**, so it needs a numbered ruling in
   `CONVENTIONS` §6 in this same commit — not a local decision.

### 5.4 The details that are easy to get wrong

- **`expectedLambCount`, never `.code`.** `BirthType.quintPlus.code` is 5; a quintuplet-or-more
  lambing with seven lambs must produce **no warning at all**, because the type is open-ended and a
  contradiction is *undefined*, not false. `12-testing.md` §10.4 carries this as its own test and it
  is the case a `.code` implementation silently fails.
- **`declaredBirthType` is nullable** (R6, and it must land before the first snapshot). A lambing
  with no declared type yet is the normal state — the row is created on screen *entry* (decision #11)
  — so `null` produces no warning. Warning about "you have not chosen a birth type" would be the app
  nagging at 03:20.
- **The band warns; it never clamps, never blocks and never rejects.** A 9 kg lamb is stored as 9 kg.
  There is no `min`/`max` applied to the value anywhere, and `Grams(400)` round-trips out of the
  validator unchanged inside `Reviewed<T>`.
- **Both bounds are inclusive-pass.** `Grams(1000)` and `Grams(10000)` do **not** warn. Write the
  comparison as `< min || > max`, and put 1000 and 10000 in the test as their own cases — an
  off-by-one here fires an amber strip at every 1.0 kg hill twin in the county.
- **`kPlausibleBirthWeight` is one named constant at one site.** Not two literals at the check, not
  a pair of parameters. `05` §5.4 makes it a single `const` record precisely so that open question 12
  can be answered by editing one line.
- **`now` is a parameter.** `package:clock` is banned in `lib/domain/` (D3 / R24) and the gate proves
  it. A validator that reads a clock cannot be tested at a boundary, and `lambingInFuture`'s trigger
  *is* a boundary.
- **The 2-minute grace on `lambingInFuture` is not a rounding allowance** — it absorbs a device clock
  a minute or two ahead of the phone that wrote the row. Do not tighten it to zero; every
  auto-captured lambing would warn about itself on a fast clock.
- **`lambingLongBeforeCapture` measures absolute time, not civil days.** `capturedAt.difference(
  effective) > const Duration(days: 3)`. A civil `+3` across the spring-forward is 71 hours, and the
  warning would fire an hour early on the one weekend of the year that is also peak lambing.
- **`localDateDisagrees` is shown, never applied.** `05` §6.9: if the device zone changed between
  insert and read, **do not recompute historical rows** — `local_date` records the shepherd's day as
  it was lived. This validator's whole job is to say the two disagree and stop.
- **The ambiguous hour is deliberately not warned about** (`05` §2.9's anti-pattern list). 01:30 on
  25 Oct 2026 happens twice; the displayed time still matches what the user typed, so nothing was
  silently corrected from their point of view. Noise at 3am is a defect.
- **`checkFoster` compares against the *current rearing dam*, never the birth dam.** Birth dam is
  immutable (decision #33) and fostering never touches it; `fosterToSelf` is about the ewe the lamb
  is already on.
- **Do not touch `checkClearDate` while you are in `treatment_checks.dart`.** It is merged, it is on
  the withdrawal path, and `05` §3.8 fixes its shape. Adding a function beside it is additive; moving
  it is a review stop.

### 5.5 The full test set

| File | Cases |
|---|---|
| `test/domain/validation/lambing_validation_test.dart` | **anchor:** `'a declared twin with three lambs returns birthTypeLambCountMismatch and changes nothing'` · `'quintPlus with seven lambs is undefined, not a contradiction — no warning'` · `'a null declared birth type warns about nothing'` · `'single with one lamb is silent'` · `'effective 3 minutes ahead of now raises lambingInFuture; 1 minute ahead does not'` · `'a lambing the civil day before seasonStart raises lambingBeforeSeasonStart; on the start date it does not'` · `'capturedAt 73 h after effective raises lambingLongBeforeCapture; 71 h does not'` · `'Grams(999) and Grams(10001) raise implausibleBirthWeight; Grams(1000) and Grams(10000) do not'` · `'a death date one day before the lambing raises deathBeforeBirth'` · `'a stored local_date one day off raises localDateDisagrees and returns nothing corrected'` · `'no validator returns a value' — the return type is List<Warning> and nothing else, asserted by the compile` |
| `test/domain/validation/foster_checks_test.dart` | `'ToEwe(current rearing dam) raises fosterToSelf'` · `'ToEwe(another ewe) is silent'` · `'ToBottle from a ewe is silent'` · `'ToBottle when the lamb is already artificially reared is silent — rearing_dam IS NULL is a third state, not a match'` |
| `test/domain/validation/treatment_checks_test.dart` | `checkTreatment`'s own cases · one regression case re-running N05-T05's `'clearDateDisagrees warns and returns the stored clear date unchanged'` against the extended file, so a careless edit to the shared file is caught here rather than in N20 |
| `test/domain/uk_zone/lambing_checks_dst_test.dart` `@Tags(['uk-zone'])` | `'a lambing at 01:30 on 25 Oct 2026 — the ambiguous hour — does NOT raise localDateDisagrees when local_date is 2026-10-25'` · `'a lambing at 01:30 on 29 Mar 2026 — the hour that does not exist — is Dart-shifted to 02:30 and still does not raise localDateDisagrees'`, because `LocalDate.of` agrees with the stored day · `'lambingLongBeforeCapture across the spring-forward measures 168 h, not 167'` — the civil-arithmetic bug from DST-4, re-asserted at this call site |

The `uk_zone` file must carry the `setUpAll` offset assertion from `05` §2.9 and **fail loudly**
rather than skip when the zone is wrong. A skipped safety test is a broken safety test.

## 6. Constraints that bind this task

- **§12.4, held at *unrepresentable*.** The three validators return `List<Warning>` and there is nothing in scope that writes: no `fix()`, no repository import, no column to persist into. `kPlausibleBirthWeight` is a band and not a limit — a 9 kg lamb warns and is stored exactly as typed. A validator that clamps, rounds or substitutes has broken the rule at the one level the type system was supposed to make impossible to reach.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'a declared twin with three lambs returns birthTypeLambCountMismatch and changes nothing'` passes, and was seen to fail first for the stated reason
- [ ] no validator returns a corrected value
- [ ] the plausibility band warns and never clamps
- [ ] `lib/data/` still cannot import this folder — N03-T02's rule holds
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/validation/lambing_validation_test.dart
fvm flutter test test/domain/validation/
TZ=Europe/London fvm flutter test --tags uk-zone
TZ=Pacific/Chatham fvm flutter test test/domain --exclude-tags uk-zone
grep -rn "domain/validation" lib/data/     # expect: nothing — R53
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): the three validators, which cannot fix anything`

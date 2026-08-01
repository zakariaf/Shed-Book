# N04-T08 — The `uk-zone` test tier and the ambiguous hour

| | |
|---|---|
| **Epic** | [N04 — Domain: time and units](epic.md) · `00-README` §9 step 2 (1 of 3) |
| **Task** | 8 of 8 |
| **Depends on** | N04-T07 |
| **Commit** | one commit · `test(domain): the uk-zone tier and the 01:00-01:59 ambiguous hour` |

## 1. Why this task exists

`@Tags(['uk-zone'])`, `TZ=Europe/London`, and the DST-1…DST-5 cases against the
**01:00–01:59** ambiguous hour the owner ruled. The tier fails **loudly** under a wrong zone rather
than passing silently — a green suite in the wrong timezone is worse than a red one.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §2.9 | the measured DST probe table, DST-1…DST-5 printed in full, the `setUpAll` guard, and the three anti-patterns |
| `docs/engineering/12-testing.md` | §2.3, §2.4, §2.5, §11.2, §11.3 | the ambiguous hour, the two tiers above the domain tests, the **three** zone commands, the tag declaration, randomised ordering |
| `docs/engineering/CONVENTIONS.md` | §1, §4.1 | `test/domain/uk_zone/` in the tree; a policy test states the property, not the file |
| `docs/research/00-tech-decisions.md` | §2.K #121, §7.0 ruling 2 | the two-timezone CI run; UK/Ireland first, so the ambiguous hour is **01:00–01:59** |
| `epics/N01-.../N01-T04-dart-testyaml.md`, `N01-T06-...ciyml...md` | the tag declaration and the two-zone `test` job | both already exist — this task **verifies** them, it does not author them |
| `epics/00-PLAN-CRITIQUE.md` | the first-failing-test table (`[audit]` row) | the ruling that DST-1…DST-5 are one `@Tags(['uk-zone'])` file — see §5.3.9 |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-domain` | DST and clocks-change arithmetic is its subject |
| `shed-testing` | the tag, the preset and the loud-failure requirement are its subject |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/uk_zone/ambiguous_hour_test.dart`
- **Test** — `'01:30 on the clocks-back night resolves without throwing and the suite fails loudly under a wrong TZ'`
- **Why it is red today** — no `uk-zone` tier exists, so every time-shaped test runs in whatever zone the machine is in.

```bash
fvm flutter test test/domain/uk_zone/ambiguous_hour_test.dart   # expect: failing, for the reason above
```

Run it **twice** on the way to green — once bare, once with `TZ=Pacific/Chatham` — and confirm the
second run fails on the `setUpAll` offset assertion with the zone it found in the message. A guard
nobody has watched fire is indistinguishable from a broken guard.

**Green.** The minimum code that passes, and nothing beyond it — the tagged tier, a zone assertion in `setUpAll` that fails with the zone it found, and
DST-1…DST-4. **DST-5 is not writable in this epic** — it asserts on `computeWithdrawalStatus`, which
is N05-T03. See §5.3.8.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 step 7 (tests) only. This task adds **no** code under `lib/` — it is the tier that
re-runs T01 through T07 under a pinned zone. Say so in the commit message; the `test(domain):` prefix
on the commit already does half of it.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `test/domain/uk_zone/ambiguous_hour_test.dart` | new | The whole task: `@Tags(['uk-zone'])`, the `setUpAll` offset guard, DST-1 … DST-4 |
| 2 | `dart_test.yaml` | **verify, do not edit** | N01-T04 declared the `uk-zone` tag. Confirm it is there — see §5.3.1, this is the single highest-consequence check in the task |
| 3 | `.github/workflows/ci.yml` | **verify, do not edit** | N01-T06 wrote the two-zone `test` job. Confirm the target-zone step is **unscoped** and the hostile-zone step carries **`--exclude-tags uk-zone`** (`12` §2.5) |
| 4 | `Makefile` | **verify, do not edit** | N01-T05's `test` target runs `TZ=Europe/London $(FLUTTER) test --tags uk-zone` as its second command |

`test/data/lambing_ambiguous_hour_test.dart` and `test/features/pen_board_dst_test.dart` — the two
tiers **above** this one, also `@Tags(['uk-zone'])` (`12` §2.4) — are not this task's. They need a
database and a screen, which arrive in N14 and N19. They are the reason the CI target-zone step must
be unscoped.

### 5.2 The file's shape

```dart
// test/domain/uk_zone/ambiguous_hour_test.dart
@Tags(['uk-zone'])
library;

import 'package:flutter_test/flutter_test.dart';
// ... domain imports: instant.dart, local_date.dart, wall_time.dart, warning.dart

void main() {
  setUpAll(() {
    // A skipped safety test is a broken safety test. Fail loudly instead.
    expect(DateTime(2026, 7, 1).timeZoneOffset, const Duration(hours: 1),
        reason: 'Run this file with TZ=Europe/London');
  });

  test('DST-1: hours since penned is ABSOLUTE across the spring-forward', () { … });
  test('DST-2: a lambing recorded in the ambiguous hour round-trips its wall time', () { … });
  test('DST-3: the nonexistent hour IS warned about', () { … });
  test('DST-4: civil-day arithmetic under-counts a 7-day withdrawal by one hour', () { … });
}
```

The four bodies are printed verbatim in `05` §2.9. Copy them, including the comments — the comment
under DST-1 (*"the wall clock advanced 10 h. Nine is correct: it is a welfare question about physical
hours in a 4x4 pen, and it errs toward turning out later"*) is the reason nobody deletes the test.

The **anchor test's name** is `'01:30 on the clocks-back night resolves without throwing and the
suite fails loudly under a wrong TZ'`. It is DST-2 plus the `setUpAll` guard, stated as one property.
Keep both spellings in the file: the anchor name as its own `test(...)`, and DST-1…DST-4 as the four
named cases, or name DST-2 with the anchor string. Whichever you choose, the anchor string must appear
verbatim as a test name — it is what `00-PLAN-CRITIQUE.md` records for this task.

### 5.3 The details that are easy to get wrong

1. **An undeclared tag silently matches nothing, and the run is green because it ran zero tests.**
   `12` §11.2: *"the tags must be declared here or a `--tags` filter silently matches nothing."*
   `uk-zone` is declared in `dart_test.yaml` by N01-T04. Before you trust a green
   `TZ=Europe/London flutter test --tags uk-zone`, read the reporter line and confirm it says **4**
   tests, not 0. This is the failure mode that makes every other guard in this task worthless.
2. **The `setUpAll` guard asserts a *summer* offset, and that is the whole trick.**
   `DateTime(2026, 7, 1).timeZoneOffset` is `Duration(hours: 1)` under `Europe/London` (BST). Assert
   it on a *winter* date instead and the expected value is `Duration.zero` — which is also UTC's
   offset, so the guard passes on `ubuntu-latest`'s default UTC runner and the whole tier goes green
   in the wrong zone. One date literal is the difference between a real gate and a decorative one.
3. **Fail, never `skip`.** `05` §2.9 lists *"skipping a DST test when the zone is wrong"* as an
   anti-pattern, and `12` §2.5 says the same: a skipped safety test is a broken safety test. Do not
   wrap the file in a `TZ`-conditional. Do not use `skip:`. The `reason:` string must name the zone
   you need — and it is worth adding `DateTime.now().timeZoneName` to the message so the failure says
   what it *found*, not only what it wanted.
4. **DST-1 uses `Instant.difference`, not `timeSincePenned`.** `12` §2.3 prints it with
   `timeSincePenned(penned, now)`; that function lives in `lib/domain/penning.dart` and arrives in
   **N06-T07**. `05` §2.9 — the owner of these five tests — prints it as `now.difference(penned)`,
   which is available today and gives the identical answer. Use the `05` form. When N06-T07 lands, add
   the `timeSincePenned` assertion beside it rather than replacing it: two callers, one number.
5. **DST-2 asserts `anyOf` on the two candidate instants, deliberately.** 01:30 on 25 October 2026
   happens twice; Dart picks one and the app does not care which, because both render as `01:30` and
   the exported UTC column disambiguates. Asserting a single epoch value here pins an implementation
   detail of the VM's zone handling and will fail on some future tzdata. The three assertions that
   *do* matter: `i.local.hour == 1`, `i.local.minute == 30`, and `LocalDate.of(i) == LocalDate(2026, 10, 25)`.
   The last one is the one that would put a bar in the wrong column of the lambing-spread histogram.
6. **DST-2 also asserts `checkLocalWallTimeExists(2026, 10, 25, 1, 30)` is EMPTY.** The ambiguous
   hour is deliberately not warned about (`05` §2.9, §7.5): the displayed time still matches what the
   user typed, so nothing was silently corrected from the shepherd's point of view, and noise at 3am
   is a defect. Adding a warning here is a named anti-pattern, not an improvement.
7. **DST-3 is the mirror and it *does* warn.** `checkLocalWallTimeExists(2026, 3, 29, 1, 30)` returns
   exactly one `Warning` with `code == WarningCode.timeDoesNotExistLocally`, and the message contains
   both `'01:30'` and `'02:30'`. Dart moves a nonexistent local time forward with **no exception** —
   `DateTime(2026, 3, 29, 1, 30)` is silently `02:30` — which is Dart violating safety rule 4 on our
   behalf. `WarningCode` exists because N04-T05 created it partially; N06-T02 completes the enum.
8. **DST-5 cannot be written here, and faking it is worse than omitting it.** It asserts
   `computeWithdrawalStatus(...) as ClearsOn` with `status.elapsesAt.local == DateTime(2026, 4, 2, 21, 0)`
   and `status.date == LocalDate(2026, 4, 3)`. `computeWithdrawalStatus` is **N05-T03**. It lands in
   N05-T02's `test/domain/uk_zone/clear_date_dst_test.dart`, which is that task's own anchor. Do not
   hand-inline a ceil-to-next-local-midnight to make a fifth test appear: a test that reimplements the
   function under test proves nothing and will pass after the real function regresses. The DoD line
   *"the five DST cases exist and pass"* is a **tier-level** property, satisfied when N05-T02 merges.
   Note that in the commit message.
9. **The file name disagrees with `00-PLAN-CRITIQUE.md`, and the disagreement is recorded, not
   resolved silently.** The critique's `[audit]` row spells the file `test/domain/uk_zone/dst_test.dart`
   and rules that DST-1…DST-5 are **one** tagged file. The task files as written split them:
   `ambiguous_hour_test.dart` here (DST-1…DST-4) and `clear_date_dst_test.dart` in N05-T02 (DST-5).
   Both anchors are fixed by the backlog and are preserved. **Raise it in the PR body**; the split is
   defensible (the clear-date cases belong with the clear-date task and its own red-first anchor), but
   two documents naming one file two ways is the thing that must not be left to collide. If the owner
   rules for one file, the rename happens **here**, in this task, and N05-T02's anchor follows.
10. **`Pacific/Chatham` is UTC+12:45 with its own DST, chosen on purpose.** It catches any code that
    assumes a whole-hour offset or a same-day UTC/local mapping. The hostile-zone step must carry
    `--exclude-tags uk-zone`, because this file's `setUpAll` is *false* there and correctly red —
    which is exactly how a correct gate gets deleted by somebody trying to green a build (`12` §2.5).
11. **The zone-agnostic files must contain only relational assertions.** After this task, run
    `TZ=Pacific/Chatham fvm flutter test test/domain --exclude-tags uk-zone` and read the output: if
    any file outside `uk_zone/` fails, it is asserting an absolute wall-clock value and belongs either
    here or rewritten. *"If a test's result depends on `TZ`, something is reading ambient local time
    that should not be"* (`12` §2.5).
12. **Randomised ordering is on, and `withClock` leaks.** The suite runs
    `--test-randomize-ordering-seed random` (`12` §11.3). If any case here installs a clock, install
    it with the harness's `atFixed` and never leave a `withClock` open across a `test()` boundary —
    randomisation is precisely what turns that leak into a failure that reproduces only under one
    seed. None of DST-1…DST-4 needs a clock at all; they take their instants as literals.
13. **2026's transitions are 29 March and 25 October.** Late March is peak UK/Ireland lambing, which
    is why this is not a footnote. If you change a year in these tests, change the dates with it —
    hard-coding 2026 is correct and intentional; a computed "last Sunday in March" helper is a
    reimplementation of the thing under test.

### 5.4 The full test set — `test/domain/uk_zone/ambiguous_hour_test.dart`

`@Tags(['uk-zone'])`. Runs under `TZ=Europe/London` only, and fails loudly anywhere else.

| Case | What it pins |
|---|---|
| `'01:30 on the clocks-back night resolves without throwing and the suite fails loudly under a wrong TZ'` | **the anchor.** DST-2's assertions plus the `setUpAll` guard, stated as one property |
| **DST-1** `'hours since penned is ABSOLUTE across the spring-forward'` | penned `DateTime(2026, 3, 28, 22, 0)` GMT, checked `DateTime(2026, 3, 29, 8, 0)` BST → `now.difference(penned) == const Duration(hours: 9)`. The wall clock advanced 10 |
| **DST-2** `'a lambing recorded in the ambiguous hour round-trips its wall time'` | `Instant.fromDateTime(DateTime(2026, 10, 25, 1, 30))` → `.local.hour == 1`, `.local.minute == 30`, `LocalDate.of(i) == LocalDate(2026, 10, 25)`, `epochMillis` is `anyOf` the BST and GMT candidates, and `checkLocalWallTimeExists(2026, 10, 25, 1, 30)` is **empty** |
| **DST-3** `'the nonexistent hour IS warned about'` | `checkLocalWallTimeExists(2026, 3, 29, 1, 30).single.code == WarningCode.timeDoesNotExistLocally`; the message contains `'01:30'` **and** `'02:30'` |
| **DST-4** `'civil-day arithmetic under-counts a 7-day withdrawal by one hour'` | `DateTime(2026, 3, 26, 20, 0)`: civil `+7` keeping 20:00 is **167 h** (the bug); `.add(const Duration(days: 7))` is **168 h** (the rule). Pure `DateTime` — no domain function needed, which is why it can land here |
| `'the guard names the zone it found'` | assert the `setUpAll` failure message would contain the actual `timeZoneName` — checked by calling the guard's helper directly with a wrong offset, not by running the suite in another zone |
| `'the nonexistent hour also moves the civil date at a day boundary'` | `checkLocalWallTimeExists` on a gap time that rolls the day — the edge §5.3.7's predicate compares `built.day` for |
| `'a LocalDate is unmoved by either transition'` | `LocalDate(2026, 3, 29).plusDays(1) == LocalDate(2026, 3, 30)` and `LocalDate(2026, 10, 25).plusDays(1) == LocalDate(2026, 10, 26)` — the UTC routing in N04-T02, proved under the zone where local routing would break it |
| `'startOfDayLocal on the spring-forward day is the first instant that exists'` | `LocalDate(2026, 3, 29).startOfDayLocal()` renders at `00:00` local (the gap is 01:00–01:59, so midnight is untouched here) and the algorithm never rounds *down* — the property N05-T02's clear date depends on |

**DST-5** — *the clear date is computed in absolute time* — is **not in this file**. It lands in
`test/domain/uk_zone/clear_date_dst_test.dart` with N05-T02. See §5.3.8.

## 6. Constraints that bind this task

- **The five safety rules** — rule 4 (never silently correct an entry), held at **caught by a test**. DST-3 is the only place in the app where Dart's own silent correction of a nonexistent local time is surfaced. If this file is skipped, weakened or run in the wrong zone, rule 4 has no proof left.
- **The 3am test** — DST-1's nine hours versus ten decides when a ewe and her lambs leave a 4×4 pen, on the last Sunday in March, in the middle of the only three weeks of the year the app matters. It errs toward turning out **later**, deliberately.
- **`layer.domain`** — the file imports `package:flutter_test` and `lib/domain/` only. `package:test` is never a direct dependency (decision #4): it caps `analyzer <13.0.0` and breaks `drift_dev ≥ 2.34.1`. An `import 'package:test/test.dart';` anywhere under `test/` is a defect.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'01:30 on the clocks-back night resolves without throwing and the suite fails loudly under a wrong TZ'` passes, and was seen to fail first for the stated reason
- [ ] the five DST cases exist and pass under `TZ=Europe/London`
- [ ] the tier fails with a readable message under `TZ=Pacific/Chatham`
- [ ] the `test` CI job runs both zones, per N01-T06
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/uk_zone/ambiguous_hour_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
TZ=Pacific/Chatham fvm flutter test test/domain --exclude-tags uk-zone

# the three checks that catch a green-for-the-wrong-reason run
TZ=Europe/London fvm flutter test --tags uk-zone --reporter expanded   # confirm it reports 4, not 0
TZ=Pacific/Chatham fvm flutter test test/domain/uk_zone               # MUST be red, on setUpAll
grep -n 'uk-zone' dart_test.yaml .github/workflows/ci.yml Makefile

make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(domain): the uk-zone tier and the 01:00-01:59 ambiguous hour`

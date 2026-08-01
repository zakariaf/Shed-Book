# N00-T06 — `docs/calendar.md` and the ledger test that stays red until it is filled

| | |
|---|---|
| **Epic** | [N00 — Decisions, rulings and the calendar](epic.md) · `00-README` §9 step 0 |
| **Task** | 6 of 9 |
| **Depends on** | N00-T01 |
| **Commit** | one commit · `docs: add the calendar ledger and the test that keeps it honest` |

## 1. Why this task exists

One row per calendar commitment — the field night, the twelve testers, the ziplock-bag
capacitance test, the two developer accounts, Apple Small Business Program enrolment, the price and
territories, and the store identifiers — each with an owner, a date and an outcome. Plus the test that
fails while any cell is empty. *"Record it where a test can see it"* has to mean this or it means
nothing.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `epics/00-PLAN-CRITIQUE.md` | §2, §10 last row | the seven commitments by name, why the old plan's placement had *"no teeth"*, and the rule *"a calendar commitment is red until it is recorded"* |
| `docs/research/00-tech-decisions.md` | §7.1 items 1, 2, 4, 14 | the four questions that are bookings rather than decisions, ranked by what they block |
| `docs/engineering/13-build-ci-release.md` | §10.2, §11, §12 | Play's 12-tester / 14-day clock, the seasonal freeze, and the manual checklist the ledger feeds |
| `docs/engineering/12-testing.md` | §11.1, §11.2 | a policy test states the **property**, not the file; and a tag must be declared or a `--tags` filter matches nothing |
| `docs/engineering/CONVENTIONS.md` | §1, §4.6, §5.4 | where the file sits, `snake_case` keys, and *"dates a human reads are never all-numeric"* |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | the ledger is only a commitment if a red test holds it |
| `shed-conventions` | the file's location and the row vocabulary are naming decisions |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/calendar_commitments_test.dart`
- **Test** — `'every commitment in docs/calendar.md has an owner, a date and an outcome'`
- **Why it is red today** — `docs/calendar.md` does not exist; once it does, six of its seven rows have no date.

```bash
fvm flutter test test/policy/calendar_commitments_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the ledger, the parser, and a failure message that **names the undated rows** rather than
counting them.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

This is the one task in the backlog whose anchor is **still red when the commit lands**, and that is
deliberate. "Green" here means the test compiles, parses the file, and fails with a message that names
`field_night`, `ziplock_capacitance`, `developer_accounts`, `apple_sbp_enrolment`,
`price_and_territories` and `store_identifiers` — not *"6 rows incomplete"*.

## 5. What you build

| # | File | What changes, and why |
|---|---|---|
| 1 | `docs/calendar.md` | The ledger. Seven rows, one fixed table shape, a stable `snake_case` key per row so the test and every later commit can name a row without matching on prose |
| 2 | `test/policy/calendar_commitments_test.dart` | The anchor, plus the ~25-line Markdown table reader that feeds it. `@Tags(['calendar'])` at the top of the file, before the imports |
| 3 | `docs/research/00-tech-decisions.md` §7.1 | Items 1, 2, 4 and 14 gain T02's `calendar-shaped` tag and a pointer at the ledger row that will close them |
| 4 | `epics/README.md` §6 | The *"Not code, start today"* list points at `docs/calendar.md` rather than repeating the seven items |

### The ledger's shape

```markdown
| Key | Commitment | Owner | Due | Recorded | Outcome | If it does not happen |
|---|---|---|---|---|---|---|
| `field_night` | One full night observed in a real lambing shed | | before N13 | | | Quick Entry is designed from forum posts, and every tap count in `07-screens.md` stays a desk estimate |
| `twelve_testers` | Twelve shepherds recruited and opted in to the Play closed test | | before N32 | | | Play's 14-day clock cannot start; fourteen days of dead calendar at the end of the project |
| `ziplock_capacitance` | Taps registered through a freezer bag, per target device | | before N13 | | | Decisions #100–#102 change and the interaction model is re-cut around volume-button shortcuts |
| `developer_accounts` | Both store accounts exist; the post-13-Nov-2023 personal-account question answered | | before N32 | | | No app record, no closed track, no TestFlight |
| `apple_sbp_enrolment` | Apple Small Business Program enrolment submitted | | before the first sale | | | 30% instead of 15% on everything sold in the gap, for nothing |
| `price_and_territories` | The exact price and the territory list, read in Play Console | | before the first submission | | | A price set from a secondary source, wrong for three years |
| `store_identifiers` | Application id / bundle id and the unlock product id, created on both stores | | before N32 | | | Two stores keyed on a string nobody wrote down |
```

Six of the seven cells under **Recorded** and **Outcome** are empty when this commit lands. The
seventh — `store_identifiers` — has its identifier half already, because N00-T01 fixed the application
id and the bundle id and wrote them into `RELEASES.md`; T09 completes it by creating the product on both
stores.

### What the test asserts, and what it deliberately does not

```
recorded  := an ISO civil date, YYYY-MM-DD, and nothing else
outcome   := a non-empty cell that is not one of: — TBD ? pending TODO n/a
complete  := owner is non-empty AND recorded is a date AND outcome is a real outcome
```

The failure message is the deliverable:

```
6 commitments are not recorded:
  field_night           — no date, no outcome
  ziplock_capacitance   — no date, no outcome
  developer_accounts    — no date, no outcome
  apple_sbp_enrolment   — no date, no outcome
  price_and_territories — no date, no outcome
  store_identifiers     — outcome recorded, no date
```

## 6. Constraints that bind this task

- **Green `main`, always — with one stated exception, and this is it.** The ledger test is red by design until N32. It is kept out of the blocking set by the `calendar` tag, which is declared in N01-T04's `dart_test.yaml` and excluded by N01-T05's `make test` and N01-T06's `test` job. Until those land, this file is run by path and by nobody else.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

### The details that are easy to get wrong

- **`@Tags` is a library annotation and must be the first thing in the file**, above every import, followed
  by a bare `library;`. Put it after an import and it is silently ignored — the test still runs, the tag
  does not exist, and the exclusion N01-T05 relies on quietly does nothing.

  ```dart
  @Tags(['calendar'])
  library;

  import 'dart:io';
  import 'package:flutter_test/flutter_test.dart';
  ```
- **Never run `--tags calendar` in this epic.** `dart_test.yaml` does not exist until N01-T04, and
  `12 §11.2` states the consequence exactly: *"The tags must be declared here or a `--tags` filter
  silently matches nothing and the run is green because it ran nothing."* In N00 the only honest
  invocation is by path. The verification block below is written that way for all four ledger tasks.
- **`make test` does not exist yet either.** N01-T05 writes the `Makefile`. Two Definition-of-Done lines
  in this task name it because the habit is the point; in this epic §8's commands are the equivalent.
- **The test must never read the clock.** It is tempting to assert *"the field night is in the future"* or
  *"recorded is not after today"*. Do not: a test that compares a ledger date to `now` changes verdict at
  midnight and is ambiguous for a whole hour once a year, because the owner's region ruling puts the
  UK/Ireland ambiguous hour at **01:00–01:59**. If a recency assertion is ever genuinely wanted, it takes
  `withClock` and a case at 01:30 on the clocks-back night in the `uk-zone` tier — it does not take
  `DateTime.now()`, which under decision #46 may appear in exactly one file under `lib/` and has no
  business in a policy test.
- **Parse the table, do not regex the prose.** Split on `|`, trim, drop the header and the separator row,
  key on column 1. A row's key is `snake_case` inside backticks so that a later commit can say *"turn
  `ziplock_capacitance` green"* and mean exactly one row.
- **A row is never deleted to make the test pass.** That is the only way this file can lie, and it is
  the failure mode the critique wrote it to prevent: the old plan recorded the field night *"correct
  placement, no teeth — no task consumes its output and no gate fails while it is unbooked."*
- **`docs/calendar.md` is a document, not an asset.** It never enters `pubspec.yaml`'s `assets:` block and
  the app never reads it. The test reads it from the repository root with `File('docs/calendar.md')`,
  which is what `flutter test`'s working directory is.
- **Dates in the ledger are ISO `YYYY-MM-DD`, and that is not a contradiction of `CONVENTIONS §5.4`.**
  §5.4's *"never all-numeric"* rule governs dates **shown to a shepherd**. This file is read by a
  developer and by a parser; the ISO form is the machine-checkable one, exactly as CSV carries an
  ISO-8601 column beside its human one.

## 7. Definition of Done

- [ ] `'every commitment in docs/calendar.md has an owner, a date and an outcome'` passes, and was seen to fail first for the stated reason
- [ ] the file carries all seven commitments
- [ ] the test names each undated row in its failure message
- [ ] the test is red at the end of this task, deliberately, and each of T07–T09 turns one row green
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/calendar_commitments_test.dart
```

This test is **expected to fail** at the end of this task, and the failure message is what you are
verifying — read it and confirm it names six rows by key. Two more checks prove the test can also
succeed, which a permanently-red test never demonstrates:

```bash
cp docs/calendar.md docs/calendar.md.bak
# fill every Recorded and Outcome cell with a plausible value, then:
fvm flutter test test/policy/calendar_commitments_test.dart   # expect: green
mv docs/calendar.md.bak docs/calendar.md
fvm flutter test test/policy/calendar_commitments_test.dart   # expect: red again, six rows named
```

The test set this task ends with, one file and six cases:

| Case | Asserts |
|---|---|
| `'every commitment in docs/calendar.md has an owner, a date and an outcome'` | the anchor; the failure message lists incomplete rows by key |
| `'the ledger carries exactly the seven commitments the critique names'` | the key set equals the seven, so a row cannot be quietly dropped |
| `'a recorded date is an ISO civil date'` | `YYYY-MM-DD`; `11 Mar 2026`, `Mar 2026` and `soon` all fail |
| `'a placeholder outcome does not count as recorded'` | `—`, `TBD`, `?`, `pending`, `TODO`, `n/a` are all treated as empty |
| `'every row states what happens if it does not happen'` | the last column is non-empty on all seven — a commitment with no consequence is a wish |
| `'the test reads no clock'` | a source assertion over its own file: no `DateTime.now(`, no `clock.now(` |

The sixth case is a policy test on a policy test, and it earns its place: it is the assertion that stops
somebody adding a recency check in six months and making the suite fail once a year for an hour.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `docs: add the calendar ledger and the test that keeps it honest`

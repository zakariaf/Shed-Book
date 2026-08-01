# N00-T05 — Rule P1 — `struck` / `struck_at` on every table

| | |
|---|---|
| **Epic** | [N00 — Decisions, rulings and the calendar](epic.md) · `00-README` §9 step 0 |
| **Task** | 5 of 9 |
| **Depends on** | N00-T04 |
| **Commit** | one commit · `docs: rule P1 — struck and struck_at on every table` |

## 1. Why this task exists

P1 is the schema-irreversible open conflict: whether every table carries `struck` and
`struck_at`, or only some do. It gates `shed-drift-schema` and `shed-export-and-restore` — a struck
row must still export, and it must still restore. Rule it as a numbered ruling in `CONVENTIONS §6`,
fold it into the decision record, and list every table it applies to.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/skills/02-build-manifest.md` | §4.5 | P1 named as the last schema-irreversible blocking conflict, and the two skills it gates |
| `docs/skills/01-catalogue-critique.md` | the P-table row P1 | both sides, verbatim: *"Indelible Rule 1 means no row is deleted, every query decides whether struck rows count, and both CSV and PDF carry the columns. `03` has no such columns"* |
| `docs/design/indelible.md` | Rule 1, §Marks 5 (the strike line), screen 11 | *"Nothing is ever removed, only struck"*, the 3px madder strike, and *"every CSV carries a `struck` and a `struck_at` column and every struck row is included and marked"* |
| `docs/engineering/03-data-model-and-schema.md` | §2 (`mixin Identified`), §5.7 (`treatments.voided_at`), §6 (the active-tag partial unique index), §9 (FTS5 triggers) | the tables the columns land on, and the three places a strike collides with something that already exists |
| `docs/engineering/CONVENTIONS.md` | §2.8, §4.6, §5.2, §6 (R74 is the highest number today) | where `mixin Identified` is spelled, the column-naming rules, the *strike* vocabulary, and the next free ruling number |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | the ruling adds a column pair to `mixin Identified` and decides which of the 23 tables carry it |
| `shed-conventions` | §6 is the ruling log and a name change is its authority |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/p1_ruled_test.dart`
- **Test** — `'CONVENTIONS §6 carries a numbered ruling for struck and struck_at and names every table it applies to'`
- **Why it is red today** — `docs/skills/02-build-manifest.md` §4.5 lists P1 as open and `CONVENTIONS §6` has no ruling for it.

```bash
fvm flutter test test/policy/p1_ruled_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — write the numbered ruling, list the tables, and update the decision record and every skill
that applies it in the same commit, per the amendment rule.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

| # | File | What changes, and why |
|---|---|---|
| 1 | `docs/engineering/CONVENTIONS.md` §6 | The ruling itself, numbered **R75** (R74 is the highest today), carrying the column names, the shape, the table list and the *"Files that must change"* line every ruling in §6 carries |
| 2 | `docs/engineering/CONVENTIONS.md` §2.8, §4.6 | `mixin Identified`'s shape updated, and the two column names added to the database-naming table beside `occurred_at` and the provenance trio |
| 3 | `docs/research/00-tech-decisions.md` §2 D | Decision #31 (*"History tables, not mutable current fields"*) amended, or a new numbered row added, so the record carries the strike as a persistence convention rather than a design-system aspiration |
| 4 | `docs/engineering/03-data-model-and-schema.md` §2, and every ruled table | The columns on `mixin Identified` (or the second mixin), the paired CHECK, and the three collisions in §5.7, §6 and §9 resolved in the text |
| 5 | `docs/engineering/09-export-formats.md` §3.1, §3.2, §3.3, §7 | The `struck` / `struck_at` columns added to all three CSV shapes and to the JSON backup's row shape. Indelible screen 11 requires them and 09 does not have them today |
| 6 | `docs/engineering/04-migrations-media-backup-restore.md` §7 | Restore preserves the strike: a struck row restores struck, or the one thing the app promises is untrue after a restore |
| 7 | `docs/skills/02-build-manifest.md` §4.5 | P1 moves out of the blocking list and into §4 as a ruled item, with the same shape §4.1 and §4.2 use for P2 and P8 |
| 8 | `.claude/skills/shed-drift-schema/SKILL.md` | The skill §4.5 says is *"not authored until P1 is ruled"* — it now states the ruled rule in its body |
| 9 | `.claude/skills/shed-export-and-restore/SKILL.md` | The export half: a struck row is exported and marked, never filtered out |
| 10 | `test/policy/p1_ruled_test.dart` | The anchor, written first |

### The ruling has to answer five questions, not one

**a · Which tables.** Sixteen of the twenty-three tables carry `mixin Identified` today — `Seasons`,
`Ewes`, `EweSeasons`, `Lambings`, `Lambs`, `FosterEvents`, `CareEvents`, `EweObservations`, `Pens`,
`PenOccupancies`, `Treatments`, `TreatmentWithdrawals`, `Reminders`, `Notes`, `MediaAssets`,
`VocabTerms`. Seven do not — `PenOccupancyLambs`, `ReminderRules`, `TerminologyOverrides`,
`AppSettings`, `Entitlements`, `EweTouches`, `EweSummaries`. Putting the pair on `mixin Identified` is
one edit and gives sixteen tables a strike, including `TreatmentWithdrawals` and `VocabTerms` where
"struck" has no meaning a shepherd would recognise. The alternative is a second mixin over the
record-bearing tables only. Either is defensible; **the ruling has to pick one and list the tables by
name**, because N07-T02 writes `common.dart` from this ruling and nothing else.

**b · The column shape.** Under `STRICT` there is no `BOOLEAN`, and both columns are instants or flags,
never drift `dateTime()` (decision #29). The shape that matches every other paired-nullable column in
the schema:

```dart
// lib/core/db/tables/common.dart — written in N07-T02, from this ruling
late final struck   = boolean().withDefault(const Constant(false))();
late final struckAt = integer().map(const InstantConverter()).nullable()();

// and, on every table that carries them:
//   CHECK (struck IN (0,1))
//   CHECK ((struck = 1) = (struck_at IS NOT NULL))
```

The paired CHECK is the same idiom `treatment_withdrawals` already uses for
`(kind = 'days') = (days IS NOT NULL)`. `struck_at` is UTC epoch millis behind `InstantConverter`,
because it is an instant — a strike happened at a moment.

**c · Which side struck rows fall on, per query.** This is the expensive half and it is why the ruling
belongs in epic 0. Every read has to decide, and the eight statistics in N06 are the dangerous ones: a
struck lambing must leave **both** the numerator and the denominator of lambing percentage, litter size
and assisted rate, or striking a mistyped record changes a number the shepherd will compare against
last year. The pen board's open-occupancy projection, the "in the pens" list, the recents strip, the
FTS5 note search and `ewe_summaries` each need the same sentence. Write the default — *struck rows are
excluded from every count and included in every history and every export* — and name the exceptions.

**d · Export and restore.** Indelible screen 11 is unambiguous: *"Every CSV carries a `struck` and a
`struck_at` column and every struck row is included and marked, because an export that quietly drops the
strikes would undo the one thing this app is for."* The printed footer already promises it —
`STRUCK ENTRIES ARE INCLUDED AND MARKED STRUCK. NOTHING HAS BEEN REMOVED.` A `WHERE struck = 0` in an
export query is therefore a defect, and restore must round-trip the pair.

**e · The word.** `CONVENTIONS §5.2` fixes one word per concept. `treatments` already has `voided_at`
(decision #69, soft-void, because a treatment may already have been printed into a medicine book handed
to a vet). Two columns for "this record was wrong" on one table is exactly the duplication §5 exists to
prevent. The ruling must either map treatments' void onto the strike or say, in one sentence, why a
treatment is voided and everything else is struck — and if it is the latter, `09`'s
`is_voided` / `voided_at_utc` CSV columns keep their names and the strike columns sit beside them.

## 6. Constraints that bind this task

- **Irreversible after N07-T08** — this is the last of the schema-irreversible rulings, and it is the one with the widest blast radius. `00-README` §10 item 4: a change that touches the schema is routed to the owner, not decided by a developer.
- **Rule 1 of Indelible** — *"If a proposal makes information disappear from the page, it is wrong."* A ruling that lets a query hide a struck row from a **history** contradicts the design system of record.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

### The details that are easy to get wrong

- **"A rebuild of every table" overstates the migration and understates the real cost.** Adding a
  nullable column with `ALTER TABLE … ADD COLUMN` is cheap in SQLite, and forward-only additive
  migrations allow it (decision #37). What is not cheap is that every query, every export shape, every
  statistic and every restore mapping written between the snapshot and the ruling silently assumed no
  row could be struck. Rule it now and that is one commit; rule it at N21 and it is N06, N07, N09's
  queries, N21's three CSV shapes and N23's restore, all revisited.
- **A struck ewe and the active-tag partial unique index.** The owner ruled tags *unique among ACTIVE
  animals only* — a partial unique index. `ewes.status` stays a mutable column (R41). If the index
  predicate is `WHERE status = 'active'` and says nothing about `struck`, a struck ewe still holds her
  tag and a shepherd who strikes a mistyped 412 cannot immediately re-enter 412. Decide the predicate
  here, in the ruling, because the index is written in N07-T03.
- **FTS5 and the strike.** `search_docs` is kept in sync by SQL triggers (`03 §9`). If a struck note
  stays searchable, the trigger set is unchanged and the *screen* decides how a struck hit renders. If
  it does not, the triggers change and a struck note becomes unfindable — which is Rule 1 violated at
  the storage layer. Say which.
- **`struck` may carry a default; `days` may not.** `03 §2` bans defaults only on columns that could
  encode veterinary advice. `withDefault(const Constant(false))` on `struck` is correct and necessary —
  the column is `NOT NULL` and every existing row needs a value.
- **Do not write any Dart in this task.** `lib/core/db/tables/common.dart` is N07-T02's file and the
  tree does not exist until N01-T01. The code block above is the ruling's *specification*, not its
  implementation.
- **`python3 tool/validate_skills.py` is in the Verification block for a reason.** This task edits two
  `SKILL.md` bodies. `CLAUDE.md` warns that a skill whose description no longer matches its row in
  `docs/skills/02-build-manifest.md` §3 is worse than a missing skill, and the validator is what catches
  it.
- **The strike is a design-system decision that became a schema decision.** `docs/design/indelible.md`
  is the design system of record and no element of `the-register.md` or `strip-bay.md` may appear — so
  Rule 1 is binding, not advisory. The only question P1 leaves open is the *shape*, never the *whether*.
- **The one time-shaped part of the ruling is `struck_at`.** It is an `Instant` — UTC epoch millis —
  precisely so that a strike recorded at 01:30 on the clocks-back night is unambiguous. When N07 writes
  it, its round trip belongs in the `uk-zone` tier against 01:00–01:59; the ruling should say so, so the
  case is not invented later by somebody who thinks a strike is a civil date.

## 7. Definition of Done

- [ ] `'CONVENTIONS §6 carries a numbered ruling for struck and struck_at and names every table it applies to'` passes, and was seen to fail first for the stated reason
- [ ] `CONVENTIONS §6` carries the numbered ruling and the table list
- [ ] the decision record and `.claude/skills/shed-drift-schema` and `shed-export-and-restore` are updated in this commit
- [ ] `docs/skills/02-build-manifest.md` §4.5 no longer lists P1 as open
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/p1_ruled_test.dart
python3 tool/validate_skills.py
```

Then read the ripple:

```bash
grep -n "P1" docs/skills/02-build-manifest.md          # §4.5 must no longer call it open
grep -rn "struck" docs/engineering/09-export-formats.md # all three CSV shapes now carry the columns
grep -rn "struck" docs/engineering/CONVENTIONS.md       # §2.8, §4.6 and the R75 ruling
```

The test set this task ends with, one file and six cases:

| Case | Asserts |
|---|---|
| `'CONVENTIONS §6 carries a numbered ruling for struck and struck_at and names every table it applies to'` | the anchor: a ruling numbered R75 or higher, naming both columns and listing table names |
| `'the ruling names a table count and the list matches it'` | the stated count and the number of listed tables agree — a list that drifts from its own count is how a table gets missed at N07 |
| `'every listed table exists in 03's @DriftDatabase tables block'` | no ruling may name a table the schema does not have |
| `'02-build-manifest.md §4.5 no longer lists P1 as blocking'` | the manifest and the ruling agree |
| `'the three CSV shapes in 09 carry struck and struck_at'` | Indelible screen 11's promise is in the document that writes the file |
| `'the ruling states the count-versus-history default'` | the text contains an explicit sentence about which side struck rows fall on, so N06 does not have to guess |

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `docs: rule P1 — struck and struck_at on every table`

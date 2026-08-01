# N00-T04 — Rule the four schema-shaped questions

| | |
|---|---|
| **Epic** | [N00 — Decisions, rulings and the calendar](epic.md) · `00-README` §9 step 0 |
| **Task** | 4 of 9 |
| **Depends on** | N00-T01 |
| **Commit** | one commit · `docs: rule the four schema-shaped questions before the freeze` |

## 1. Why this task exists

Four open questions become migrations on somebody else's phone if they survive the freeze
in N07-T08: `WithdrawalTarget.milk`, the temperature column's shape, `Lambs.became_ewe`, and
**lambing ease 5 vs 6** — which the spec's own §17 marks *decide before any data exists* and which
`R44` freezes as an ordinal. Rule all four, name the table each one lands in, and strike the open
rows.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/research/00-tech-decisions.md` | §7.1 items 10, 11, 13, 15; §2 D #31, #51; §2 E #56 | the four questions, the no-`DEFAULT`-on-advice rule, the withdrawal child table and the canonical-units decision |
| `docs/engineering/03-data-model-and-schema.md` | §4.3 (temperature, marked open), §5.8 (`TreatmentWithdrawals`), §5.4 (`Lambings.ease`), §6 (tag uniqueness), §10.1 (`vocab_terms`), Definition of done | the exact columns, CHECKs and indexes each ruling becomes |
| `docs/engineering/05-domain-correctness.md` | §3.2, §5.2, §6.7 | the dairy question, *"do not add a temperature column until that question is answered"*, and why the ease scale stays at five |
| `docs/engineering/CONVENTIONS.md` | §2.7, §2.9, §4.6, §6 (R44, R45, R46), §7 item 3 | `WithdrawalTarget`, `LambingEase`, the column-naming rules, and the next free ruling number |
| `docs/engineering/00-README.md` | §5.2 items 10, 11, 13, 15 and its closing line, §10 | *"Items 10, 11 and 13 are schema-shaped and therefore expire at the first snapshot"* |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-drift-schema` | each ruling names a column, an index or a constraint that N07 will write |
| `shed-safety-rules` | the milk withdrawal target and the ease scale are §12.1 and §12.4 shaped and must not acquire a default |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/schema_shaped_rulings_test.dart`
- **Test** — `'every decision-record row marked schema-shaped carries a ruling and a date'`
- **Why it is red today** — four rows in decision-record §7.1 read OPEN and the freeze is five epics away.

```bash
fvm flutter test test/policy/schema_shaped_rulings_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — rule each row, strike the open row with the reason, and add the resulting column or enum
member to `CONVENTIONS §2` so N07 has one place to read it from.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

The Refactor step has real work in it here. T02 wrote `_ruledRows(String section)` privately inside
`dependency_rulings_test.dart`; this task is its second consumer. Lift it to
`test/support/decision_record.dart`, and add that file to `CONVENTIONS §1`'s tree in the same commit —
§1 is the authority on which files exist, and R57 owns the test tree.

## 5. What you build

No `lib/`, no schema — the schema is N07's. What this task produces is four rulings, each written in
the one place N07 will read it from, and the ripple each one has through the documents that already
apply the open question.

| # | File | What changes, and why |
|---|---|---|
| 1 | `docs/research/00-tech-decisions.md` §7.1 | Items 10, 11, 13 and 15 struck with their reason and an ISO date, using T02's `schema-shaped` tag and `RULED <date> — <sentence>` line |
| 2 | `docs/research/00-tech-decisions.md` §7.0 | Four rows added to the SETTLED table: question, ruling, and *what it binds* |
| 3 | `docs/research/00-tech-decisions.md` §2 D #51, §2 E #56 | The milk-target and unit rows gain the ruling's consequence in the Decision cell |
| 4 | `docs/engineering/00-README.md` §5.2 | Four items struck; the trailing count corrected; the closing sentence *"Items 10, 11 and 13 are schema-shaped and therefore expire at the first snapshot"* rewritten to say they have not expired, they have been answered |
| 5 | `docs/engineering/03-data-model-and-schema.md` §4.3, §5.4, §5.8, §6, §10.1, Definition of done | The open blockquote at §4.3 replaced by the ruling; the affected table code blocks updated so N07 copies a settled shape rather than an argument |
| 6 | `docs/engineering/05-domain-correctness.md` §7 preamble, §3.2, §5.2, §6.7 | The *"Still open"* blockquote loses four items; the temperature and ease paragraphs state the ruling |
| 7 | `docs/engineering/09-export-formats.md` §3.3, §10 row 12 | The `milk_*` CSV columns and the `lambing_ease_1_5` column name follow whatever the ease ruling says |
| 8 | `docs/engineering/CONVENTIONS.md` §2.7, §2.9, §6, §7 item 3 | The enum and column consequences, a numbered ruling per change, and the *"deliberately does not settle"* list shortened |
| 9 | `test/support/decision_record.dart` | The lifted parser (Refactor step), plus its entry in `CONVENTIONS §1`'s tree |
| 10 | `test/policy/schema_shaped_rulings_test.dart` | The anchor, written first |

### The four rulings, and the exact schema each one becomes

**1 · `WithdrawalTarget.milk` — decision-record §7.1 item 10, "is the target market ever a dairy flock?"**
The recommendation on record is to **ship the type now**: it is free today and a migration later. The
sealed type and the child table are already written for two targets in `CONVENTIONS §2.7` and
`03 §5.8`:

```dart
enum WithdrawalTarget { meat('meat'), milk('milk') }          // + fromKey
```

```
treatment_withdrawals(treatment, target, kind, days, clear_date)
  uniqueKeys: {treatment, target}
  CHECK (target IN ('meat','milk'))
  CHECK (kind IN ('days','not_applicable'))
  CHECK ((kind = 'days') = (days IS NOT NULL))
  CHECK ((kind = 'days') = (clear_date IS NOT NULL))
```

Ruling *yes* costs nothing new — the CHECK already lists `milk` and 0..n rows per treatment already
express it. Ruling *no* means deleting `milk` from the enum and the CHECK, and re-admitting it later is
a migration plus a re-read of every withdrawal surface. `WithdrawalMilkings` does not exist in v1 and
nothing converts milkings to days, whichever way this goes.

**2 · The temperature column — §7.1 item 11, "where does temperature appear at all?"**
`03 §4.3` states both sides precisely. **No v1 table stores a temperature.** `MilliCelsius` ships either
way and costs nothing (`05 §5.2`). So the ruling is one of exactly two shapes:

- **Drop it.** `app_settings.temperature_unit` — today `text().withDefault(const Constant('c'))` with
  `CHECK (temperature_unit IN ('c','f'))` — is deleted, and with it the °C/°F row on the Settings screen
  and `temperatureUnitProvider` (`CONVENTIONS` §3, which says it *"ships only if a temperature column
  ships"*). An unused setting is a 3am tax.
- **Ship it.** `care_events.temp_mc INTEGER NULL` — the `warmed` kind is its obvious home — plus
  `CHECK (temp_mc IS NULL OR temp_mc BETWEEN 25000 AND 45000)` as a unit-slip guard, in canonical
  milli-°C (decision #56). Then `temperature_unit` stays and Settings keeps the row.

There is no third shape where the setting ships and the column does not.

**3 · `Lambs.became_ewe` — §7.1 item 13, "does a retained lamb become a `Ewe` row?"**
If yes, `lambs` gains a nullable self-referencing-by-kind FK, hand-indexed like every other FK
(decision #31 — SQLite creates no child-key index automatically):

```dart
late final becameEwe = integer().nullable().references(Ewes, #id, onDelete: KeyAction.setNull)();
// @TableIndex(name: 'idx_lamb_became_ewe', columns: {#becameEwe})
```

It also re-opens the cross-table tag rule at `03 §6`: today *"a lamb tagged 412 and an active ewe tagged
412 can coexist, because they are different tables and v1 has no lamb→ewe promotion"*, and that
sentence is only true while the answer is no. **Do not add a cross-table trigger to paper over it** —
`03 §6` says so by name. Ruling yes means the partial unique index on active tags is revisited in the
same breath.

**4 · Lambing ease, 5 or 6 — §7.1 item 15, and spec §17 says *decide before any data exists*.**
The recommendation on record is **stay at five** and write down that 5 covers elective caesarean.
Five big buttons is the 3am-correct answer, and `R44` has already frozen the type:

```dart
extension type const LambingEase(int code) { }   // validated 1..5, no descriptions in the domain
```

`lambings.ease` is `integer().nullable()` with `CHECK (ease IS NULL OR ease BETWEEN 1 AND 5)`, and the
five labels are `vocab_terms` rows `ease_1`…`ease_5` whose text is an ARB message. If the ruling goes to
six, **these all move together**: the CHECK's upper bound, the extension type's validation, the
`vocab_terms` seed (five rows to six), the ARB messages, the CSV column name `lambing_ease_1_5`
(`09 §3.1`), `assistedRate`'s *"ease ≥ 2"* numerator and its verbatim `definition` string (`05 §6.7`),
and `ShedChoiceRow`'s *ease 1–5 only* contract from N10-T06.

## 6. Constraints that bind this task

- **§12.1 and §12.4 are *decided* here, not held here — which is why deferring one of these four questions is expensive.** `WithdrawalTarget.milk` decides whether a milk withdrawal is *unpersistable* or merely absent; the temperature column's shape decides whether a stored value can be silently re-scaled on read; `Lambs.became_ewe` and the lambing-ease ordinal decide whether a later correction rewrites an entry in place or appends beside it. After N07-T08 the only remaining answer to any of the four is a migration on somebody else's phone.
- **No `DEFAULT` on a column that could encode veterinary advice** (`03 §2` point 5) — withdrawal `days`, `lambings.ease` and `ewe_seasons.status` have none, and no ruling here may add one. §12.1 is held at *unpersistable* by the absence of a default; a default drops it to *documented*, which means deleted.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

### The details that are easy to get wrong

- **`lambings.ease` is deliberately not a vocabulary foreign key.** `03 §2` says it in one line: the
  `ease_*` vocab rows carry only the user-editable *labels* for five integers, and *"widening the scale
  must be a migration someone has to think about"*. Ruling six is therefore a schema change, not a seed
  change, and that friction is the feature.
- **A blank ease is not "unassisted".** Sheep Genetics: *"a blank score indicates the lambing ease was
  not scored."* `05 §6.7` excludes unscored lambings from **both** sides of the assisted rate and
  reports coverage. Any ruling that makes the column non-nullable, or gives it a default, converts a
  §12.4 violation into schema.
- **Dropping `temperature_unit` is a column deletion, and this is the only window in the project where
  that is free.** Migrations are forward-only and never destructive (decision #37): no `DROP COLUMN` on
  user data, ever. Before the first snapshot there is no user data and no snapshot, so the column can
  simply not exist. After N07-T08 it is a column that ships forever, unread.
- **`MilliCelsius` ships whichever way item 11 goes.** `05 §5.2` is explicit; do not delete the extension
  type as part of a "drop the temperature" ruling. The measured reason it exists at all is that storing
  temperature at 0.1 °C silently rewrites **89 of 201** °F entries.
- **`WithdrawalTarget.milk` in the schema is not `milk` in the UI.** `09 §10` row 12 already says the
  `milk_*` columns ship in `treatments.csv` regardless and *"the v1 UI may never write one"*. Ruling the
  schema does not add a screen; do not let the ruling grow a Treatments field.
- **Four rulings, four ripples, one commit.** The amendment rule (`00-README` §10) is not satisfied by
  editing the record: grep the decision numbers and the question numbers across `docs/engineering/`, and
  every document that names them changes here. A doc set where 03 still calls temperature open and the
  record calls it closed is worse than no doc set.
- **A name change is `CONVENTIONS`'s, with a number.** R74 is the highest ruling in the log today, so any
  new column or member added here is **R75 onward**, cited by number afterwards
  (`per CONVENTIONS R75`), never re-argued.
- **Nothing in this task is time-shaped** — the four rulings concern a target enum, an integer
  temperature, a foreign key and an ordinal. The clear-date arithmetic they sit beside *is* time-shaped
  and it is N05-T02's, with its DST cases against 01:00–01:59 in `test/domain/uk_zone/dst_test.dart`.

## 7. Definition of Done

- [ ] `'every decision-record row marked schema-shaped carries a ruling and a date'` passes, and was seen to fail first for the stated reason
- [ ] all four rows carry a ruling, a reason and a date
- [ ] each ruling names the table and column it becomes in N07
- [ ] no ruling introduces a `DEFAULT` on a column that could encode veterinary advice
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/schema_shaped_rulings_test.dart
fvm flutter test test/policy/dependency_rulings_test.dart
```

The second command is not decoration: this task lifts T02's parser into `test/support/`, and the
task that owns a refactor owns proving it broke nothing.

Then read the ripple, because the amendment rule is what this task actually is:

```bash
grep -rn "Open (decision-record §7.1 #11)" docs/engineering/03-data-model-and-schema.md
grep -rn "Still open" docs/engineering/05-domain-correctness.md
grep -rn "open question 1[0135]" docs/engineering/ | grep -iv "ruled\|settled"
```

All three must return nothing.

The test set this task ends with, one file and six cases:

| Case | Asserts |
|---|---|
| `'every decision-record row marked schema-shaped carries a ruling and a date'` | the anchor: zero `schema-shaped` items in §7.1 without a `RULED` line |
| `'each schema-shaped ruling names a table and a column'` | every `RULED` line for a schema-shaped row contains a `snake_case` table name and a column name, so N07 has something to implement |
| `'no ruling introduces a DEFAULT on an advice column'` | the ruling text contains no `withDefault` or `DEFAULT` against `days`, `ease` or `status` |
| `'the lambing ease bound is stated once'` | exactly one upper bound appears across the ruling, `03 §5.4`'s CHECK and `CONVENTIONS §2.9` — five spellings of the same number is how a scale widens by accident |
| `'§7.0 and §7.1 agree'` | every struck §7.1 item has a matching SETTLED row |
| `'no engineering document still calls one of the four open'` | a text sweep of `docs/engineering/` for the four question numbers beside an *open* marker |

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `docs: rule the four schema-shaped questions before the freeze`

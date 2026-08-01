# Storing a value with no precedent in the schema

Load this when a new fact needs a column and no existing column is the same shape. It decides the
*kind*; `docs/engineering/03-data-model-and-schema.md` §4–§5 holds the catalogue and the reasoning,
and `CONVENTIONS.md` §4.6 holds the spelling. Cite both; retype neither.

## Contents

1. [The four questions, in order](#1-the-four-questions-in-order)
2. [Instant or civil date](#2-instant-or-civil-date)
3. [A measurement](#3-a-measurement)
4. [An enum-shaped value](#4-an-enum-shaped-value)
5. [Derived, or observed?](#5-derived-or-observed)
6. [Absence: NULL, sentinel, or no row](#6-absence-null-sentinel-or-no-row)
7. [Irreversible after the first snapshot](#7-irreversible-after-the-first-snapshot)
8. [The checklist for a new column](#8-the-checklist-for-a-new-column)

---

## 1. The four questions, in order

1. **Is it derived?** If it changes with no write, it is never stored (§5).
2. **Is it a time?** Instant or civil date — they are different kinds and get different types (§2).
3. **Is it a measurement?** Canonical integer unit, no `unit` column (§3).
4. **Is it one of a fixed set of words?** CHECK or vocabulary FK (§4).

If the answer to all four is no, it is a plain `text()`/`integer()`/`boolean()` column, and the only
remaining decisions are its CHECK, its nullability and whether the row needs the provenance quad.

## 2. Instant or civil date

**A moment that happened → instant. A square on a calendar → civil date.** A lambing *happened at
03:20*; a withdrawal *clears on a date*; a lamb *died on a day the shepherd knows, not a minute*.

| Kind | Column | CHECK it must carry |
|---|---|---|
| Instant | `integer().map(const InstantConverter())` | the sanity band `BETWEEN 946684800000 AND 4102444800000` |
| Civil date | `text().map(const LocalDateConverter())` | `GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'` |
| Partial civil date | `text().map(const PartialDateConverter())` | the three-branch GLOB (`YYYY`, `YYYY-MM`, `YYYY-MM-DD`) |

- The sanity band catches a **seconds-vs-millis slip**, the one time bug that produces a
  plausible-looking row (a 2026 lambing filed in 1970). Never narrow it to a range a shepherd could
  legitimately trip.
- The GLOB is what makes `ORDER BY` and `end_date >= start_date` correct as plain string comparisons.
- A partial date is never widened. `'2026'` means the shepherd knows the year only.
- `dateTime()` and `store_date_time_values_as_text` are banned everywhere — both are single global
  flags that would force one representation onto both kinds (decisions #29/#30).
- If a *human* can edit or re-date the value, the row needs the full provenance quad (R37) — and it
  must land before the first snapshot, because the quad's columns are `NOT NULL`.
- If the value is a *duration since* something rather than a moment, stop: it is derived (§5).

## 3. A measurement

**Canonical integer unit, always. No `unit` column on any row.** Mass is `Grams`
(`birth_weight_g INTEGER`); temperature is `MilliCelsius` (`*_mc INTEGER`). Conversion happens at the
display edge; the edit form is seeded from canonical and parses the typed text back to canonical.

Why integer canonical rather than a rounded display unit: storing mass at 0.1 kg silently rewrites
132 of 241 lb entries and temperature at 0.1 °C rewrites 89 of 201 °F entries — a spec §12.4 violation
produced purely by a storage choice, invisible in review, in over half of possible entries.

Every measurement column carries a **unit-slip guard** CHECK — a range so wide no real entry can trip
it (`birth_weight_g BETWEEN 200 AND 20000`, `volume_ml BETWEEN 1 AND 2000`). It exists to catch 5 g vs
5 kg. Narrowing it to a range a vet would recognise turns the schema into veterinary advice (§12.2).

There is **no temperature column in v1**. If the owner rules that lamb body temperature ships, it
lands as `care_events.temp_mc INTEGER NULL` with `CHECK (temp_mc IS NULL OR temp_mc BETWEEN 25000 AND
45000)` — not as a new table, and not before the ruling.

## 4. An enum-shaped value

One discriminator decides it: **may the user add a term?**

- **No → `CHECK (col IN ('a','b','c'))`.** Use this when the values are wired to something frozen at
  release — a notification channel id (`care_events.kind`, `reminders.kind`), an export column, a
  storage key. Adding a fifth value is then a migration *and* a channel decision, which is the correct
  amount of friction.
- **Yes → `text().references(VocabTerms, #key, onDelete: KeyAction.restrict)`.** The FK constrains the
  *key*, never the *list*; nothing in SQL stops a key from the wrong list being stored, so
  `test/data/vocab_list_scope_test.dart` asserts per column that every stored key belongs to that
  column's list. Do not add a trigger for it — a trigger fires on restore.
- **Index the FK by hand.** Nullable `vocab_terms(key)` references are the ones people forget, and
  they are exactly what a `RESTRICT` scans when a user hides a term.
- **An ordinal scale is an `INTEGER` with a CHECK, not a vocabulary.** `lambings.ease` is `1..5`; the
  five `ease_*` vocab rows carry only the user-editable labels. Widening the scale must be a migration
  someone has to think about.
- **A stored key is `snake_case`, ASCII and frozen forever**, and where a Dart enum mirrors it, the two
  spellings are byte-identical (`ShedPaletteId`, `WeightUnit`, `PenExitReason`). See CONVENTIONS §2.9.

## 5. Derived, or observed?

| Bucket | Rule | Examples |
|---|---|---|
| Time-relative | **Never stored.** Changes with no write, so a stored copy is wrong within a minute. | hours since penned, days until clear, overdue, ready to turn out |
| Aggregate | Computed on read — a `CREATE VIEW` for row-shaped projections, a `customSelect` with explicit `readsFrom:` for anything with `GROUP BY`. | season summary, losses by cause, lambing spread |
| Counts feeding a display line | A cache table may hold **counts only** — never a percentage, never a formatted string, and the cache is excluded from the backup and rebuilt after a restore. | `ewe_summaries` |
| What the app *told* the user | **Stored**, because it is an observation, not a derivation. | `treatment_withdrawals.clear_date` |
| Looks derived, is not | An observation the event tables cannot reconstruct gets a real table. | `ewe_touches` ("looking at a ewe card" is not an event), `ewe_observations` |

Two structural bans that follow, both of which a plausible implementation reaches for:

- **No mutable "current" column beside a history table** — no `lambs.rearing_dam`, no
  `pens.occupant_ewe`. It is a dual write a future code path gets wrong, and then the list screen and
  the history disagree. Append to the log; derive the current state in a view.
- **No `warnings` column and no `fix()`.** A contradiction is reported by a view
  (`lambing_consistency`) and never corrected. A warning has nowhere to be persisted and holds no
  writer (decision #54).

## 6. Absence: NULL, sentinel, or no row

Three different facts, and the schema models all three where all three exist:

- **`NULL` = not recorded.** `lambs.sex IS NULL`, `lambings.ease IS NULL` ("not scored" is not
  "unassisted"), `seasons.ewes_to_ram IS NULL` ("I did not record it" is not zero).
- **An explicit key = the user looked and could not tell.** `lambs.sex = 'unknown'`.
- **No row at all = a third state.** A `treatment_withdrawals` row missing for a target means
  *NotRecorded*; a row with `kind = 'not_applicable'` means the label says none. Never collapse them,
  and never add a `withdrawal_days INTEGER` back onto `treatments` — a nullable int conflates "the
  label says 0 days" with "I didn't look", and `0` is a real label value.

**No `DEFAULT` and no `clientDefault` on any column that could encode veterinary advice.** The gate is
`test/policy/withdrawal_has_no_default_test.dart`, which parses the committed schema JSON. Do not add
a source heuristic banning numeric literals near "withdrawal" — it fires on the CHECK constraints
themselves and on test fixtures.

## 7. Irreversible after the first snapshot

Doc 04 §1 lists four things that cannot be undone; three of them are decided here, plus the fourth
that belongs to the media path:

1. **The storage kind of every column in the snapshot** — instants `INTEGER` millis, civil dates
   `TEXT`, `store_date_time_values_as_text` never set (#29/#30).
2. **Any `NOT NULL` column added later is a full table rebuild** — so the provenance quad lands on all
   seven quad-carrying tables now (R37), and `notes.occurred_at` with it.
3. **A CHECK cannot be added by `ALTER TABLE`** — so `media_assets.relative_path` carries all three of
   its CHECKs now (R62), and any new column's guard is written the day the column is.
4. **A row class name** — `@DataClassName` before the first snapshot; renaming one afterwards is a
   whole-codebase edit for no behaviour change.

`lambings.declared_birth_type` staying nullable (R6) is the fifth thing that must be right on day one:
the lambing row is written on the first tap, and "not yet tapped" is a fact no default may erase.

## 8. The checklist for a new column

- [ ] It is not derived, not time-relative, and not an aggregate (§5).
- [ ] Its kind is right: instant vs civil date, canonical integer unit, CHECK vs vocabulary FK.
- [ ] It carries its guard CHECK — GLOB, sanity band, unit-slip range or `IN (…)` — written in **SQL**
      column names inside `customConstraints`.
- [ ] It has no `DEFAULT`/`clientDefault` if it could answer a veterinary question.
- [ ] Absence is modelled deliberately: `NULL`, an explicit key, or no row.
- [ ] If it is an FK: explicit `onDelete:`, and a hand-written index whose leading column is the child
      key.
- [ ] If the row can be edited or re-dated: the table carries the full provenance quad, or it gets no
      edit verb.
- [ ] `make gen` ran, and its artefacts are in the same commit.

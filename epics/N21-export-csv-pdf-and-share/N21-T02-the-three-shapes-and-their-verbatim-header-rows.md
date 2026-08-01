# N21-T02 — The three shapes and their verbatim header rows

| | |
|---|---|
| **Epic** | [N21 — Export: CSV, PDF and share](epic.md) · `00-README` §9 step 8 (1 of 3) |
| **Task** | 2 of 8 |
| **Depends on** | N21-T01 |
| **Commit** | one commit · `feat(export): the three CSV shapes with struck rows marked` |

## 1. Why this task exists

One row per lamb, one row per ewe, one row per treatment — spec §7.9's three shapes, each
with its **verbatim** header row. **Every struck row is included and marked**, because a flock book that
silently omits a corrected record is a different document than the one the shepherd thinks they are
sending.

The header rows are the irreversible part. `09 §3.4`: they are `const` in `export_repository.dart`,
frozen by a golden test, and *"renaming one is a breaking change to every spreadsheet a shepherd has
built on top of it."* This file lands on somebody else's laptop the day after the first tap, and you
cannot recall it.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/09-export-formats.md` | **§3.1** (`lambs.csv`, 35 columns, each with its source column and its format) · **§3.2** (`ewes.csv`, 26 columns, and the union rule for a ewe with no participation row) · **§3.3** (`treatments.csv`, 29 columns, and why withdrawals are pivoted into columns) · **§3.4** (the three header rows, verbatim, and where the vocabulary labels come from) · §2.5 (the formatting table this task feeds the writer through) · §1.1 (the scope rule: every artefact except the backup is one season) · §9 (the anti-pattern rows) | every column, its source and its format |
| `docs/engineering/03-data-model-and-schema.md` | §5.2 (`ewes`: `tag`, `tag_digits`, `eid`, `breed`, `date_of_birth`, `source`, `status`) · §5.3 (`ewe_seasons`: the seven stored status keys, `scanned_count`) · **§5.4** (`lambings`: the provenance quad, `local_date`, `declared_birth_type` nullable and load-bearing, `ease` with no default) + the `lambing_consistency` view, printed · **§5.5** (`lambs`: `sex` nullable ≠ `'unknown'`, `status`, `death_date`, `death_cause`, `pet_lamb`, `bottle_feeds`) · **§5.8** (`treatments` + `treatment_withdrawals`: `target`, `kind`, `days`, `clear_date` and their four paired CHECKs) · §5.12 (`vocab_terms.key` — ASCII, stable forever, never translated) · §7 (`lamb_rearing`) | every column name, and every three-valued state a `0` would flatten |
| `epics/N00-.../N00-T05` | the whole task — **R75** | which tables carry `struck` / `struck_at`, how the CSV spells them, and the count-versus-history default |
| `docs/design/indelible.md` | §1.2 Rule 1 · **screen 11** (*"every CSV carries a `struck` and a `struck_at` column and every struck row is included and marked, because an export that quietly drops the strikes would undo the one thing this app is for"*) | the promise this task's anchor test holds |
| `docs/engineering/CONVENTIONS.md` | §2.7 (`WithdrawalPeriod`'s three states, and that the countdown takes a `ClearsOn`) · §2.9 (`Sex`, `LambStatus`, `BirthType`) · §2.13 (`ExportRepository` owns **nothing**) · §4.6 (`snake_case` SQL column names; the event-time column exceptions) · **R43** (`EweSeasonOutcome` is a bucketing, never a replacement for the seven stored keys) · **R45** (`NULL` ≠ `Sex.unknown`) · R60, R61 | **BINDING** on every name in a header row |
| `docs/research/00-tech-decisions.md` | #29 (integer instants, text civil dates) · #32 (identity is `uid`) · #50 (`clear_date` is stored and is what the app told the user) · #54 (contradictions are warned about, never fixed) · #56 (canonical grams) · #61 (`label ?? default`) · #69 (a treatment is soft-voided, not deleted) · #108 (numeric dates only inside CSV, beside an ISO column) | the decisions each derived column applies |
| `docs/engineering/05-domain-correctness.md` | §4 (`RecordedTime`) · §6 (`Grams.inKilograms`) · the `WarningCode` members `localDateDisagrees` and `clearDateDisagrees` | the two derived warning columns |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-export-and-restore` | the shapes, the headers and the struck-row rule |
| `shed-withdrawal` | the three withdrawal states, pivoted into columns without collapsing to a nullable integer |

Two auto-firing skills is the `CLAUDE.md` cap and `shed-withdrawal` takes the second slot because
collapsing *no period entered* and *not applicable* into one empty cell is the failure this task is
one keystroke away from. The query half is `shed-drift-schema`'s and it is not reloaded: the three
statements are printed in §5.2 and every column they select is named there. The strike rule —
an export may never filter a struck row out — is `indelible-marks-and-strikes`' and is stated as a
hard constraint in §6, not left to the skill.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/csv_shapes_test.dart`
- **Test** — `'every struck row is present in the lambs CSV and carries struck_at'`
- **Why it is red today** — the writer exists and there is nothing to write.

```bash
fvm flutter test test/features/csv_shapes_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. Seed one lambing with three lambs against
`NativeDatabase.memory()`, strike one of them (set `struck = 1` and `struck_at` to a known instant),
produce `lambs.csv`, parse it with the strict reader T01 wrote, and assert **three data records, not
two** — the struck lamb is present, its strike column is `1`, and its strike instant is the ISO-8601
UTC millisecond form of the instant you wrote. Then assert the negative that actually catches the
bug: `lamb_uid` of the struck lamb is in the file. A `WHERE struck = 0` fails this test with a count
of two and a message that names the missing uid.

**Green.** The minimum code that passes, and nothing beyond it — three queries, three header rows, struck rows included with their timestamp.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No schema step (**this task stores nothing and adds no column — say so in the commit message**); no
domain step beyond calling `Grams.inKilograms` and `clearDateFor`; no controller, screen, route or
ARB. Step 3 (the write path's file) and step 12 (`test/data/`-style repository tests) are where the
work is, even though nothing here writes.

| # | Path | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/export_repository.dart` | **New.** The three `const` header rows, the three `writeXCsv` methods, and the queries behind them. `CONVENTIONS §1` already lists this file; §2.13 fixes its ownership as *"nothing — read + artefact assembly only"* |
| 2 | `test/features/csv_shapes_test.dart` | **New. The anchor, written first.** Against `NativeDatabase.memory()` through `testDatabase()` |
| 3 | `test/features/csv_header_golden_test.dart` | **New.** The three header strings frozen character for character, with their field counts printed in the `reason:`. `09 §3.4` requires a golden and this is it — a plain string comparison, not a `.png` |
| 4 | `test/domain/uk_zone/local_date_disagrees_test.dart` | **New.** `@Tags(['uk-zone'])`. `local_date_disagrees` compares a **stored** civil date against the civil date of the same instant re-derived in the export-time zone — see §5.4 |

`tool/check_policy.dart` is **not** touched: T01 landed both rules this file needs to satisfy.

### 5.2 The signatures

```dart
// lib/data/export_repository.dart
final class ExportRepository {
  ExportRepository(this._db);
  final AppDatabase _db;

  /// FROZEN (09 §3.4). Appending a column is allowed; renaming or reordering
  /// one breaks every spreadsheet built on the file. The golden test is the
  /// guard and the field count is printed in its failure message.
  static const List<String> lambsHeader = [ … ];       // 09 §3.1 + R75
  static const List<String> ewesHeader = [ … ];        // 09 §3.2 + R75
  static const List<String> treatmentsHeader = [ … ];  // 09 §3.3 + R75

  /// `vocabLabels` is resolved by the Export SCREEN and handed down opaque
  /// (09 §3.4). Nothing below lib/features/ may reach AppLocalizations.
  Future<Uint8List> writeLambsCsv({
    required SeasonId season,
    required CsvWriter writer,
    required Map<String, String> vocabLabels,
  });

  Future<Uint8List> writeEwesCsv({ … });        // same three parameters
  Future<Uint8List> writeTreatmentsCsv({ … });  // same three parameters
}
```

**The header rows.** `09 §3.4` prints all three verbatim at 35, 26 and 29 fields.
**R75 appends `struck` and `struck_at` to each**, per `09 §3.4`'s own freeze rule — *"adding a column
appends to the end of the list"* — so the three files carry **37, 28 and 31** fields. Copy the three
strings out of `09 §3.4`, append the two, and let the golden test print the counts.

> **Read R75 for the CSV spelling before you type the two column names.** Indelible screen 11 and
> this task's anchor say `struck` / `struck_at`; `09 §2.5`'s instant convention is `*_at_utc` and
> `09 §3.3` already exports the soft-void pair as `is_voided` / `voided_at_utc`. R75 is the authority
> that settles which — `N00-T05 §e` puts the question in the ruling explicitly, and its answer decides
> whether the strike columns sit *beside* `is_voided` / `voided_at_utc` or replace them. **The anchor
> test's name stays as written whichever way it lands**; if R75 spells the CSV column `struck_at_utc`,
> the test asserts that column and keeps its name. Do not invent a third spelling here.

### 5.3 The details that are easy to get wrong

- **No export query filters a struck row.** `WHERE struck = 0` is right for every count and wrong for
  every export and every history (R75's default: *struck rows are excluded from every count and
  included in every history and every export*). It fails silently, it looks like tidiness, and the
  printed footer promises the opposite — which makes a filtered export **a false statement inside the
  file**.
- **`lambing_consistency.recorded` is a count, so it is on the other side of that rule.** Column 21
  (`lambs_recorded_for_lambing`) and column 22 (`birth_type_mismatch`) come from a view that counts
  lambs. Read R75's count-versus-history sentence and apply it here rather than guessing: a struck
  lamb leaving the numerator without leaving the denominator is how striking a mistyped record
  changes a number the shepherd compares against last year.
- **`sex` blank and `sex = unknown` are different facts and must never be merged** (R45). Blank is
  *not recorded*; `unknown` is *looked and could not tell*. The column is `TEXT NULL` with a `CHECK`
  that allows the literal `'unknown'`, and the Dart side models `NULL` as `Sex?` and never as
  `Sex.unknown`.
- **`death_cause_label` blank is unattributed, and `dc_unknown` is a cause the user picked.** Same
  shape of error, different column, and here it changes what a loss table means.
- **`meat_withdrawal_state` has three values and none of them is a blank that reads as zero.** The
  two stored `kind` keys (`days`, `not_applicable`) verbatim, plus **`not_recorded`** derived only
  when the child row is absent. `meat_withdrawal_days` blank is **never `0`** — `0` is a real label
  value, and it is why there is no `withdrawal_days` column on `treatments` at all. When the state is
  `not_recorded`, all three companions are blank **including `meat_withdrawal_source`**: emitting
  `as entered by you` beside a blank would be the app asserting a withdrawal period it was never
  told, in the file somebody hands to a vet.
- **`clear_date` is the stored value and is never recomputed at export** (#50). It is the record of
  what the app told the user on the day and printed into the medicine book. Column 26,
  `clear_date_disagrees`, is the *derived* comparison against `clearDateFor(administered_at, days)`
  — it is **shown, never applied**. The same shape twice: warn, print both, correct nothing (§12.4).
- **`local_date_disagrees` is derived in the export-time zone and the stored `local_date` was derived
  at write time.** They can legitimately differ — the phone crossed a border, or the write happened
  in the ambiguous hour. Both values ship, neither is corrected, and the warning column is
  `WarningCode.localDateDisagrees`.
- **`time_original_effective_utc` is blank if and only if `time_source ≠ edited`.** That is the
  paired `CHECK` from `03 §5.4` travelling into the file. If your export can produce a row that
  breaks it, the query lost a join.
- **Order by the stable key, never by `id`.** Integer ids are re-issued on import (#32), so an
  id-ordered export makes every diff between two exports unreadable. `lambs.csv`:
  `lambings.occurred_at`, then `lambs.uid`. `ewes.csv`: `ewes.tag_digits`, then `ewes.tag`, then
  `ewes.uid`. `treatments.csv`: `administered_at`, then `treatments.uid`. These are the **CSV**
  orderings and they are deliberately different from the backup's `ORDER BY uid` (N22) — a CSV is
  read by a human in the order a shepherd thinks in.
- **`ewes.csv` is a UNION, and the second arm is the point.** Every `ewe_seasons` row for the season
  joined to `ewes`, **union** every ewe with `status = 'active'` who has no participation row that
  season, emitted with a blank `season_status`. An export that silently omits an animal the shepherd
  can see in her flock list is the failure this format exists to prevent. A blank cell is honest; an
  absent row is not.
- **`season_status` is one of the seven stored keys, never the four-way `EweSeasonOutcome`** (R43).
  The bucketing is a derived view for statistics and does not round-trip.
- **`tag` is exported exactly as typed and `tag_digits` is never a CSV column.** `tag_digits` is a
  projection; it *is* in the JSON backup (N22), because the backup carries every column and restore
  writes rows verbatim rather than recomputing them. That distinction settles every "does this column
  belong in the CSV?" argument, and the other worked example is `ewes.over_free_cap`: a monetization
  marker, not a fact about a sheep, and **not exported**.
- **`birth_weight_g` and `birth_weight_kg` both ship, and the file does not change when
  `weight_unit` changes.** The header is fixed for all time; two exports from two phones concatenate
  cleanly. The kg column is two decimals with a `.` separator, built from `Grams.inKilograms` — the
  PDF is the artefact that renders the user's unit, because a PDF is a document a human reads.
  *CSV is interchange, PDF is display.*
- **`dose_text` is never parsed, never normalised, never split into a number and a unit.** The app
  has no opinion about a dose (§12.2). It is the shortest column rule in the file and the easiest one
  to "improve".
- **Both the `*_key` and the `*_label` column ship for every vocabulary FK.** The key is what a
  machine joins on and never changes; the label is what a human reads and the user may have edited.
  Neither substitutes for the other.
- **The labels are resolved by the Export screen and passed down, and this is a layer rule, not a
  preference.** `lib/data/` cannot reach `AppLocalizations` (layer rule 4 — no `BuildContext` down
  there), and a controller may not hold one either (`CONVENTIONS §4.4` rule 3). So the screen walks
  `vocab_terms` taking `label ?? <the ARB message for that key>` (#61), hands the map to
  `ExportWriteController`, which hands it to `ExportRepository`, which treats it as opaque data and
  never asks where a label came from. In **this** task the map is a parameter and the tests supply it
  directly; T07 builds the screen that fills it.
- **`ExportRepository` writes nothing, and it is the only repository of which that is true.** No
  `transaction(`, no `into(`, no `update(`, no `delete(`, no `save`-prefixed verb (`db.save_verb`
  fires on the last one). If this task feels like it needs a write, it is stamping `last_exported_at`
  — which is `SettingsRepository`'s, in T08, and is exactly why that repository came forward to N12.
- **Every one of the 37 / 28 / 31 columns maps to a stored fact or to a derivation named in `09 §3`.**
  No column is invented. If a useful-looking value has no row in that table, it does not ship in this
  commit; appending later is legal, and inventing now is not.

### 5.4 The full test set

`test/features/csv_shapes_test.dart` — against `NativeDatabase.memory()` via `testDatabase()`, seeded
through `seeds.dart`'s `seedEwe` / `seedAutoLambing` / `seedEditedLambing` / `seedTreatment`. (The
path is `00-PLAN-CRITIQUE`'s anchor and is preserved verbatim — see the epic's Notes.)

| Case | What it asserts |
|---|---|
| `'every struck row is present in the lambs CSV and carries struck_at'` | **The anchor.** Three lambs, one struck; three data records in the file; the struck lamb's uid present; its strike flag `1` and its strike instant exact |
| `'a struck ewe, a struck lambing and a struck treatment are each present and marked'` | The same property in the other two shapes. One case, three files, because R75 is one ruling |
| `'no export query mentions struck in a WHERE clause'` | Source text over `lib/data/export_repository.dart`. Cheap, and it is the assertion that survives a refactor of the queries |
| `'the three files have 37, 28 and 31 fields and every record is rectangular'` | Parse each with the strict reader; every record — header, data and the six trailer rows — has the same field count |
| `'lambs.csv includes dead, stillborn and untagged lambs'` | `03 §5.5`: a lamb that died before tagging is counted, fully. Three seeded lambs, one `alive`, one `stillborn`, one with `tag IS NULL`; all three in the file |
| `'sex blank and sex unknown are distinct in the file'` | Two lambs; one with `sex IS NULL` → empty field, one with `sex = 'unknown'` → the literal `unknown`. R45 made mechanical |
| `'death_cause_label is blank for an unattributed death and never the word unknown'` | A `status = 'dead'` lamb with `death_cause IS NULL`; the label column is empty and the key column is empty. A second lamb with `dc_unknown` renders the resolved label |
| `'a treatment with no withdrawal row exports not_recorded and three blanks'` | `meat_withdrawal_state` is `not_recorded`; `meat_withdrawal_days`, `meat_clear_date` and `meat_withdrawal_source` are all empty — **not `0`, and not `as entered by you`** |
| `'a withdrawal of 0 days is distinct from no withdrawal'` | `kind = 'days'`, `days = 0` renders state `days`, days `0`, a real `clear_date` and the provenance phrase. This is the pair the nullable-int design exists to keep apart |
| `'not_applicable is exported verbatim and carries no days and no clear date'` | The third state, and the one people forget exists |
| `'a voided treatment is exported with is_voided = 1 and its voided_at'` | #69: the medicine book shows the void and never loses the row, and neither does the CSV |
| `'clear_date_disagrees prints 1 and the stored clear date is unchanged'` | Write a `clear_date` that disagrees with `clearDateFor(administered_at, days)`; the warning column is `1` **and** the stored date is what ships. Warn, never fix |
| `'ewes.csv contains an active ewe with no participation row, with a blank season_status'` | The UNION's second arm. Delete the `ewe_seasons` row and assert she is still a record |
| `'season_status is one of the seven stored keys and never an EweSeasonOutcome member'` | R43. Assert the set of values in the column is a subset of the seven |
| `'over_free_cap and tag_digits are not columns in any CSV'` | Header membership, both directions |
| `'birth_weight_g and birth_weight_kg agree and the file does not change when weight_unit changes'` | Produce the file at `kg`, flip `app_settings.weight_unit` to `lb`, produce it again, `expect(a, b)` byte for byte |
| `'the ordering is deterministic and is never by id'` | Produce twice from two databases seeded in different insertion orders with the same uids; the record order is identical |
| `'a note containing a comma, a quote and a newline survives into lambs.csv'` | T01's property, exercised end to end through the real query rather than through a hand-built row |
| `'a zero-row season still produces three parseable files with headers and trailers'` | Empty database, three files, seven records each |
| `'time_original_effective_utc is blank iff time_source is not edited'` | Over an auto, an entered and an edited lambing. The paired CHECK, travelling into the file |

`test/features/csv_header_golden_test.dart`:

| Case | What it asserts |
|---|---|
| `'the three header rows are frozen'` | Each `const` compared against the literal from `09 §3.4` plus R75's two columns, with the field count in the `reason:` so a failure says *"37 expected, 36 found — a column was dropped"* rather than printing two 400-character strings |

`test/domain/uk_zone/local_date_disagrees_test.dart` — `@Tags(['uk-zone'])` under `TZ=Europe/London`:

| Case | What it asserts |
|---|---|
| `'a lambing written inside the ambiguous hour exports both civil dates and disagrees with neither'` | An `occurred_at` at 01:30 on the clocks-back Sunday, with `local_date` stored at write time. The export re-derives the civil date in the export-time zone, prints both, and sets `local_date_disagrees` from the comparison — it never rewrites `born_local_date` |
| `'a stored local_date that disagrees is printed unchanged with the flag set to 1'` | Store a deliberately different `local_date`; the flag is `1`, the stored value is what ships, and `born_at_utc` is untouched. §12.4 at the one column that could break it |
| `'the two 01:30s of the clocks-back night export different born_at_utc values'` | The ISO column disambiguates what the local column cannot. This is the case that fails if anyone "simplifies" the pair into one column |

## 6. Constraints that bind this task

- **The five safety rules** — §12.1 (`not_recorded` and three blanks, never `0`), §12.4 (`clear_date_disagrees` and `local_date_disagrees` warn and never fix) and §12.5 (the full provenance quad plus its label on every event row). All three are held by columns in the file, which means a regression is visible in a parsed fixture rather than in prose.
- **Indelible Rule 1** — nothing is ever removed, only struck. An export query that filters a struck row contradicts the design system of record **and** the footer the same file prints.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every struck row is present in the lambs CSV and carries struck_at'` passes, and was seen to fail first for the stated reason
- [ ] three shapes, headers verbatim
- [ ] struck rows present and marked
- [ ] no column is invented — every one maps to a stored fact
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the three header rows are `const` in `export_repository.dart` and frozen by a golden that prints the field count
- [ ] the strike columns are spelled the way **R75** spells them, not the way this file guessed
- [ ] `grep -n "WHERE struck" lib/data/export_repository.dart` returns nothing
- [ ] `meat_`/`milk_withdrawal_state` renders three states, blanks are never `0`, and `withdrawal_source` is blank when the state is `not_recorded`
- [ ] `ExportRepository` contains no `transaction(`, `into(`, `update(`, `delete(` or `save`-prefixed verb
- [ ] every CSV ordering is by the stable key named in `09 §3` and no query orders by `id`
- [ ] `drift_schemas/` is untouched — this task adds no column

## 8. Verification

```bash
fvm flutter test test/features/csv_shapes_test.dart
fvm flutter test test/features/csv_header_golden_test.dart
make check
make test
```

Then the DST tier, and the two greps the DoD names:

```bash
TZ=Europe/London fvm flutter test --tags uk-zone

grep -n "WHERE struck\|struck = 0" lib/data/export_repository.dart
# expect nothing

grep -nE "transaction\(|\.into\(|\.update\(|\.delete\(|save[A-Za-z]*\(" lib/data/export_repository.dart
# expect nothing — CONVENTIONS §2.13
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(export): the three CSV shapes with struck rows marked`

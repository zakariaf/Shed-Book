# N21-T03 — The disclaimer trailers, referenced and never re-typed

| | |
|---|---|
| **Epic** | [N21 — Export: CSV, PDF and share](epic.md) · `00-README` §9 step 8 (1 of 3) |
| **Task** | 3 of 8 |
| **Depends on** | N21-T02 |
| **Commit** | one commit · `feat(export): the disclaimer trailers, referenced not re-typed` |

## 1. Why this task exists

§12.3 in the footer of every artefact — referenced from `Disclaimers`, never re-typed, and
proved by a test that greps the source. A re-typed footer drifts, and a drifted footer is the one that
gets quoted back at you.

The mechanism is not *"remember to append the footer"*. `09 §6.2` names three structural defences and
this task is where all three become real for the CSV: `ExportEnvelope` cannot be constructed without
the disclaimer; every writer's signature takes one; and each writer emits the footer **from its own
frame, not from its caller's**. A caller cannot forget what it was never asked to do.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/09-export-formats.md` | **§2.7** (six trailer records, padded, on every CSV including a zero-row one, and why `#` is not a comment marker) · **§6.1** (the three strings, printed) · **§6.2** (the three structural mechanisms, in order of strength) · **§6.3** (the placement matrix — which artefact carries which trailer, and where) · **§6.4** (the three tests, the `joinedStringLiterals` gotcha, and the ASCII dependency) · §9 (`copy.disclaimer_retyped`) | every byte of every trailer, and the tests that hold them |
| `docs/engineering/05-domain-correctness.md` | **§7.4** (`Disclaimers` printed in full; `ExportEnvelope` printed in full; the single-definition test printed; the per-format placement sentence) · §7.3 (`ContentPolicy.allowlist` keyed by `Disclaimers.*` rather than by a literal) · §4.1 (`TimeSource` — the trailer's third line is built from it) | the strings, the type, and the test this task extends |
| `docs/design/indelible.md` | **screen 11** (the printed footer, verbatim: *"SHED BOOK IS A NOTEBOOK, NOT A COMPLIANCE RECORD… STRUCK ENTRIES ARE INCLUDED AND MARKED STRUCK. NOTHING HAS BEEN REMOVED."*) · §12's rule 3 row | the second sentence this task has to place — see §5.3 |
| `docs/engineering/CONVENTIONS.md` | §2.14 (`Disclaimers` — `abstract final class`, three members) · §2.8 (`ExportEnvelope` vs `BackupHeader`, R65) · §4.7 (`copy.disclaimer_retyped` is 04's `disclaimer_referenced_not_retyped`, renamed) · §5.3 (banned words) · §5.4 (copy conventions) | **BINDING** on the class shape and the rule id |
| `docs/engineering/12-testing.md` | §11.1 (a policy test is named for the property, not the file) · §11.4 (the §12 matrix row for rule 3: *"the gate plus one artefact assertion"*) · §1.3 (why the PDF footer is a **string** assertion and never a golden) | where these assertions live and what shape they take |
| `docs/research/00-tech-decisions.md` | #62 (`Disclaimers` is a `const` in exactly one file, referenced never re-typed) | the decision this task enforces |
| `epics/N06-.../N06-T09` | the task | `test/policy/disclaimer_is_defined_once_test.dart` already exists; this task adds a **second** file for a different property, and does not fork the first |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-safety-rules` | §12.3 and the one-file rule are the whole subject |
| `shed-export-and-restore` | which artefact carries which trailer, and in what form |

The cap is two auto-firing skills. `shed-accessibility-and-copy` is not reloaded: the permanently
banned phrases the same scan checks for are listed by name in §5.3, and the copy conventions bind
through `Disclaimers` (N06-T09), which this task references and never re-types. Indelible's printed
footer clause — where a strike may be described in a trailer — is quoted in §5.2's trailer records,
so `indelible-marks-and-strikes` is not needed to write a line of this diff.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/disclaimer_is_referenced_test.dart`
- **Test** — `'every export footer is a reference to Disclaimers and appears as a literal in exactly one file'`
- **Why it is red today** — the CSVs have no footer and the first one written would be typed inline.

```bash
fvm flutter test test/policy/disclaimer_is_referenced_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. It has two halves and they fail differently.
**Half one:** walk `lib/**/*.dart` (skipping `*.g.dart`, `*.drift.dart` and `app_localizations*.dart`),
extract and **join adjacent string literals per file**, and assert the set of files matching
`RegExp(r'statutory\s+medicine|holding\s+register')` is exactly `['lib/domain/policy/disclaimers.dart']`.
**Half two:** for each of the five artefacts this epic produces, assert the produced **bytes** contain
`Disclaimers.exportFooter` — read through the constant, never through a literal in the test. Half one
catches a re-typed footer; half two catches a missing one; neither catches the other.

**Green.** The minimum code that passes, and nothing beyond it — the trailers by reference, and the grep test extended to the export files.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No schema, no controller, no screen, no route. The domain step is a possible fourth `Disclaimers`
const (§5.3), the data step is `CsvWriter._trailer()`'s body, and the rest is tests and one gate row.

| # | Path | What changes in it, and why |
|---|---|---|
| 1 | `lib/domain/policy/disclaimers.dart` | **Edit, conditionally.** If §5.3's ruling adds a fourth const for Indelible's strike clause, it lands here — and this file is on `00-README` §10's **never waved through** list by name. If the ruling amends `exportFooter` instead, `05 §7.4` and `CONVENTIONS §2.14` are amended in the same commit |
| 2 | `lib/domain/policy/content_policy.dart` | **Edit.** `ContentPolicy.allowlist` is keyed by `Disclaimers.*` rather than by a literal (05 §7.3). Any new const joins the allowlist by reference. A re-typed key here is the exact duplication that was caught while the research was being written |
| 3 | `lib/data/csv_writer.dart` | **Edit.** `_trailer()`'s six records get their real bodies: `envelope.disclaimer` (§12.3), `Disclaimers.withdrawalCaveat` (§12.1), the §12.5 line built from `TimeSource.values.map((s) => s.label)`, the zone line, the formula-guard disclosure, and the version line. T01 built the frame; this fills it |
| 4 | `tool/check_policy.dart` | **Confirm, and add only if absent.** `copy.disclaimer_retyped` is E05/N06's row (`CONVENTIONS §4.7` renames 04's `disclaimer_referenced_not_retyped` to it). This is the first task with export files for it to point at — extend its scope to the new writers, plant a violation, watch it fire, delete it |
| 5 | `test/policy/disclaimer_is_referenced_test.dart` | **New. The anchor, written first.** |
| 6 | `test/policy/every_export_carries_the_footer_test.dart` | **New.** `09 §6.4`'s second test: every artefact × {seeded database, **empty** database}. Five artefacts × 2 in this epic; N22 adds the sixth |
| 7 | `test/policy/withdrawal_is_never_defaulted_in_an_export_test.dart` | **New.** `09 §6.4`'s third test, printed there in full. It belongs here because it is a §12.1 property of the *trailer and the provenance columns*, not of the shapes |

`test/policy/disclaimer_is_defined_once_test.dart` (N06-T09) is **not** edited and **not** forked.
`12 §11.1` names a policy test for its property; these are three different properties and they fail
for three different reasons.

### 5.2 The six trailer records

`09 §2.2` prints them; `09 §6.3` places them. Every one of the six is a reference:

```dart
// lib/data/csv_writer.dart
List<String> _trailer() => [
      '# ${envelope.disclaimer}',                          // §12.3
      '# ${Disclaimers.withdrawalCaveat}',                 // §12.1
      '# Times are exported in UTC. Each event carries its source: '
          '${TimeSource.values.map((s) => s.label).join(' · ')}.',   // §12.5
      '# Local times in this file were rendered in $localZoneLabel at export. '
          'The UTC columns are exact.',
      "# Fields beginning = + - @ a tab or a carriage return are prefixed "
          "with ' in this file so a spreadsheet does not evaluate them. "
          'The stored record is unchanged.',
      '# Shed Book ${envelope.appVersion}.',
    ];
```

`09 §6.3`'s placement matrix, for the artefacts this epic produces:

| Artefact | §12.3 `exportFooter` | §12.1 | §12.5 |
|---|---|---|---|
| `lambs.csv` · `ewes.csv` | trailer row 1 | trailer row 2 (#82: the §12.1 **and** §12.3 trailers on all three shapes) | trailer row 3 + the `time_source` / `time_provenance` columns |
| `treatments.csv` | trailer row 1 | trailer row 2, **plus** `Disclaimers.withdrawalProvenance` as the value of `meat_withdrawal_source` / `milk_withdrawal_source` | trailer row 3 + the four provenance columns |
| Flock book PDF | footer on **every page**, 7 pt | — | the provenance mark on every `Born` cell + a legend in the front matter |
| Medicine record PDF | footer on every page **+ a boxed statement under the title** | both strings in the box; `withdrawalProvenance` in every withdrawal cell | provenance mark on every `Date` cell + the legend |

The PDF rows are T04's and T05's to build; this task's job is that the placement is written down and
that the tests iterate all five artefacts rather than the two that exist when it is written.

### 5.3 The details that are easy to get wrong

- **There are two footer sentences in this project and only one of them is `Disclaimers`. Rule it in
  writing, in this commit.** `05 §7.4` pins `exportFooter` verbatim — *"Shed Book is a personal
  notebook. It is not a statutory medicine record, holding register, or movement record, and must not
  be presented as one. All entries are as recorded by the user."* Indelible screen 11 specifies a
  printed footer that says that **and** *"STRUCK ENTRIES ARE INCLUDED AND MARKED STRUCK. NOTHING HAS
  BEEN REMOVED."* Since R75 made the strike real, that second promise now has to appear somewhere.
  Two options, and the choice is recorded in the commit message and the PR body:
  1. **A fourth const — recommended.** `Disclaimers.strikeNotice`, referenced as a **seventh** trailer
     record and as a line in the PDF front matter. `exportFooter` stays byte-identical, so `05 §7.4`'s
     pinned literal, N22's `"_disclaimer"` golden, the medicine-record box and T04's ASCII byte
     assertion all stay as written. Cost: one `CONVENTIONS §2.14` row and one `05 §7.4` amendment.
  2. **Amend `exportFooter`.** Cheaper in the writer, more expensive everywhere else: it changes a
     string three documents print verbatim, and it changes the value N22's backup header golden is
     written against before that golden exists.

  What is **not** an option is a third sentence typed inline in a writer "just for the CSV". That is
  precisely what `copy.disclaimer_retyped` exists to catch, and it is how the two footers start to
  drift.
- **A naive `file.contains('some long phrase')` scan misses long strings, and this was found during
  the research rather than theorised.** Dart wraps a long literal across adjacent string literals, so
  the phrase is never contiguous in the source. `joinedStringLiterals` extracts the literals and
  joins them before matching. **Any scanner in this project that greps for a sentence has the same
  bug unless it does this** — including `copy.disclaimer_retyped` in `tool/check_policy.dart`.
- **`Disclaimers.exportFooter` must stay pure ASCII, and a test has to say so.** T04's PDF byte
  assertion searches the raw bytes for the UTF-8 of the document-information `subject:`. A PDF string
  object holds non-ASCII text as UTF-16BE behind a byte-order mark, at which point a UTF-8 search
  finds nothing and **the safety test goes green for the wrong reason** — which is worse than a
  failing one. Assert `Disclaimers.exportFooter.codeUnits.every((c) => c < 128)` here, in this
  commit, so the constraint is visible before someone "improves" the punctuation with a curly
  apostrophe. If it is ever deliberately broken, the PDF arm of `containsDisclaimer` is rewritten in
  the same commit.
- **`containsDisclaimer` is per-format, and the PDF case is the one that surprises people.** CSV and
  JSON: a UTF-8 byte search finds the sentence directly. **PDF: a byte search for the drawn text does
  not work at all** — text drawn with an embedded TTF is written as glyph indices into that font's
  encoding, so the sentence is simply not present in the bytes, compressed or not. That is why
  `_buildDocument` also puts the string in `subject:`, and why `compress: false` exists as a
  test-only parameter. Write the helper with a `switch` over the artefact kind and a comment saying
  this, or the next person deletes the PDF arm as redundant.
- **The §12.5 trailer line is built from the enum and never typed out.** `TimeSource.values.map((s) =>
  s.label)`. If a fourth source is ever added, the trailer updates itself and 05 §4.4's
  exhaustive-switch test catches anything that did not. A hand-typed list of three labels goes stale
  silently, and the thing it goes stale about is a §12.5 claim.
- **`ContentPolicy.allowlist` is keyed by `Disclaimers.*`, not by a literal.** This caught a real
  duplication while the research was being written: the banned-phrase allowlist had re-typed the
  string it exists to permit. If a fourth const lands, it joins the allowlist by reference in the
  same edit.
- **The words *compliance record* and *official record* appear nowhere in the diff** — not in code,
  not in a comment, not in a test name, not in the commit message. The permanently banned sentence
  *"your data never leaves your phone"* is the other half of the same rule and is checked over `lib/`
  **and `assets/`**.
- **The trailer is emitted by `encode` and is not a parameter.** If a caller can choose to skip it,
  a caller eventually will. Same argument as `footer:` inside `_buildDocument` (T04) and the same
  reason `ExportEnvelope`'s generative constructor is private.
- **A zero-row database still carries every trailer.** 07 §13.2 says so for the CSV and `09 §6.4`'s
  test says so for all six artefacts. The empty case is the one an implementation that builds the
  trailer *from the rows* fails.

### 5.4 The full test set

`test/policy/disclaimer_is_referenced_test.dart`:

| Case | What it asserts |
|---|---|
| `'every export footer is a reference to Disclaimers and appears as a literal in exactly one file'` | **The anchor**, both halves: the literal scan over `lib/` through `joinedStringLiterals` returns exactly `disclaimers.dart`; and each produced artefact's bytes contain `Disclaimers.exportFooter` read through the constant |
| `'a re-typed footer in any writer fails the scan'` | Plant the sentence in a temp file under `lib/data/`, run the scan in-process, assert it fails and names the file. The test that proves the test |
| `'the scan joins adjacent string literals before matching'` | A fixture source with the sentence split across three adjacent literals is detected. Without `joinedStringLiterals` this case passes vacuously, which is the bug |
| `'Disclaimers.exportFooter is pure ASCII'` | `codeUnits.every((c) => c < 128)`. T04's byte assertion depends on it and would otherwise go green for the wrong reason |
| `'ContentPolicy.allowlist is keyed by Disclaimers members and holds no re-typed literal'` | Source text over `content_policy.dart`: no occurrence of the sentence, and every allowlist entry references a `Disclaimers.` member |
| `'the words compliance record and official record appear nowhere under lib/ or assets/'` | Case-insensitive, both phrases |
| `'the sentence "your data never leaves your phone" appears nowhere under lib/ or assets/'` | 07 §13.4's permanently banned copy. It is false the moment a shepherd AirDrops a CSV, and that is the backup story the product depends on |

`test/policy/every_export_carries_the_footer_test.dart` — `09 §6.4`'s loop, over one fixture database
**and one empty database**:

| Case | What it asserts |
|---|---|
| `'<artifact> carries the §12.3 footer, empty database included'` | Iterated over the five artefacts × 2 databases = **10 assertions** in this epic. `containsDisclaimer` is per-format: a UTF-8 byte search for CSV, and the document-information `subject:` at `compress: false` for the two PDFs. N22 adds the JSON arm and the eleventh and twelfth assertions |
| `'every CSV carries all six trailer records, padded, from an empty database'` | Seven records in an empty file, each rectangular |
| `'the §12.5 trailer line names every TimeSource'` | All three labels present, joined from the enum |
| `'the trailer cannot be suppressed by a caller'` | Source text: `CsvWriter.encode`'s signature has no flag, and `_trailer` is private with exactly one call site |

`test/policy/withdrawal_is_never_defaulted_in_an_export_test.dart` — `09 §6.4` prints the first case:

| Case | What it asserts |
|---|---|
| `'a treatment with no withdrawal row exports three blanks and "not_recorded"'` | `meat_withdrawal_state` is `not_recorded`; days, clear date and **source** are all empty — the last one specifically **not** `as entered by you` |
| `'the medicine record renders not recorded and never a blank cell'` | The PDF arm of the same rule, once T05 exists. There is no fourth rendering and never a blank a reader could take for zero |
| `'no export writes a withdrawal value the user did not type'` | Source text over `export_repository.dart` and `pdf_writer.dart`: no `?? 0`, no `?? '0'`, no default beside a withdrawal column |

**Nothing in this task is time-shaped**, so there is no `uk-zone` case: a footer carries no clock.
The one instant it mentions — `envelope.generatedAt`, through the zone line — is T01's, and its DST
case is `test/domain/uk_zone/csv_local_rendering_test.dart`.

## 6. Constraints that bind this task

- **The five safety rules** — **§12.3 is this task's whole subject** and it is held at the strongest level available: the string exists once, no writer can be constructed without it, and no writer's caller can suppress it. §12.1 (the withdrawal caveat and the provenance phrase) and §12.5 (the provenance trailer line) are carried by the same six records. A rule that drops to merely *documented* has been deleted, whatever the prose says.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every export footer is a reference to Disclaimers and appears as a literal in exactly one file'` passes, and was seen to fail first for the stated reason
- [ ] no footer literal outside `disclaimers.dart`
- [ ] every artefact carries its trailer
- [ ] the words *compliance record* and *official record* appear nowhere
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the scan reaches through `joinedStringLiterals`, and a fixture with the sentence split across three literals is detected
- [ ] `Disclaimers.exportFooter` is asserted pure ASCII
- [ ] the Indelible strike clause is placed by a **recorded ruling** — a fourth const or an amendment to `exportFooter` — and never as a third sentence typed inline in a writer
- [ ] every CSV carries all six trailer records **from an empty database**, padded to the header's field count
- [ ] `ContentPolicy.allowlist` holds no re-typed literal
- [ ] the sentence *"your data never leaves your phone"* appears nowhere in `lib/` or `assets/`

## 8. Verification

```bash
fvm flutter test test/policy/disclaimer_is_referenced_test.dart
fvm flutter test test/policy/every_export_carries_the_footer_test.dart
fvm flutter test test/policy/withdrawal_is_never_defaulted_in_an_export_test.dart
make check
make test
```

Then read the property by hand — the thing the tests exist to hold:

```bash
grep -rln "statutory medicine\|holding register" lib/ --include='*.dart' | grep -v '\.g\.dart'
# expect exactly: lib/domain/policy/disclaimers.dart
# (and note this grep is the NAIVE one — it is here to be compared against the
#  test's joinedStringLiterals scan, which finds the wrapped case this misses)

grep -rn "compliance record\|official record\|never leaves your phone" lib/ assets/
# expect nothing
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(export): the disclaimer trailers, referenced not re-typed`

# N21-T05 — The flock book in two volumes and the medicine record

| | |
|---|---|
| **Epic** | [N21 — Export: CSV, PDF and share](epic.md) · `00-README` §9 step 8 (1 of 3) |
| **Task** | 5 of 8 |
| **Depends on** | N21-T04 |
| **Commit** | one commit · `feat(export): the flock book in two volumes, off the UI isolate` |

## 1. Why this task exists

Built **off the UI isolate** — a 400-ewe flock book on the main isolate is a frozen phone —
and split at the row cap into two volumes, because a single PDF that a mail client refuses to attach is
not an export.

Two volumes is the **shape**, not a fallback. A combined 400-ewe / 900-lamb book is the OOM case, and
the two documents have different readers: the ewe book is the flock record, the lamb book is the
season's output. The medicine record is the third document and the highest-stakes one in the product
— it is what somebody hands to a vet or an inspector, which makes it the artefact where §12.1 and
§12.3 matter most and the one that must never be split.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/09-export-formats.md` | **§4.4** (off the UI isolate — the three-step split, `PdfJob` printed, and why only a path and a byte count cross back) · **§4.5** (page furniture, `part N of M`) · **§4.6** (the flock book: two volumes, the statistics block printed, the two table shapes, the `Born` cell and its provenance mark) · **§4.7** (the medicine record: the boxed statement printed, the table, the three withdrawal renderings, the void) · **§4.8** (`kPdfRowsPerVolume`, the split, the on-screen message, *"never truncate silently"*) · **§4.9** (memory, and the five mitigations) · §10 items 1 and 4 | every page of both documents |
| `docs/engineering/05-domain-correctness.md` | §6.2 (the four `definition` strings, verbatim) · §4 (`RecordedTime`, `TimeSource.label`) · §7.4 (`Disclaimers`) | the statistics block and the provenance legend |
| `docs/engineering/CONVENTIONS.md` | §2.6 (`StatResult` — `value` is `double?`, `notComputableReason`, `StatResult.notComputable`) · §2.7 (`WithdrawalPeriod`'s three states) · §2.3 + R68 (`unitsProvider`, `WeightUnit`) · §2.9 + R45 (`Sex`) · **R60** · **R61** (statistic `definition` strings are 05's, verbatim) · §1 (`lib/data/` is flat) | **BINDING** on every value drawn on a page |
| `docs/research/00-tech-decisions.md` | **#125** (only PDF generation and image downscaling go off-isolate) · #83 (split rather than crash; no photos) · #50 (`clear_date` is stored) · #69 (the soft void) · #59/#61 (the `definition` strings) · #56 (integer grams) | why the isolate exists and what may cross it |
| `docs/engineering/03-data-model-and-schema.md` | §5.8 (`treatments.voided_at`, `treatment_withdrawals`) · §5.5 (`lambs`) · §5.2 (`ewes.tag_digits`) | the rows both documents read |
| `epics/N00-.../N00-T05` | **R75** | a struck row is drawn, struck, and never dropped from a document |
| `docs/design/indelible.md` | §Marks 5 (the 3 px madder strike) · screen 11 | how a struck row and a voided treatment look in print |
| `docs/engineering/12-testing.md` | §1.3 (why there is no PDF golden) · §10.6 (`FlockGenerator(seed)`) · §11.6 (`Future.delayed` in a test body is banned) | how a 400-ewe document is produced in a test before the fixtures exist |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-export-and-restore` | the two volumes, the row cap and the medicine record |
| `shed-riverpod-providers` | the isolate boundary, and how the split count reaches the screen without a provider crossing it |

The cap is two. `shed-testing` is not reloaded — the technique for proving work left the UI isolate,
and for producing 400 ewes before a fixture exists, is written out step by step in §5.4. The struck
row and the voided treatment are drawn rather than removed; that is `indelible-marks-and-strikes`'
rule and it is carried here as a constraint in §6 and as two named cases in §5.4, so nothing about it
is left to a skill firing.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/pdf_writer_test.dart`
- **Test** — `'a 400-ewe flock book splits at the row cap and builds off the UI isolate'`
- **Why it is red today** — the builder produces one document and blocks the isolate.

```bash
fvm flutter test test/features/pdf_writer_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. Generate 400 ewes and ~900 lambs with
`FlockGenerator(seed: 42)`, call the flock-book entry point, and assert **four** things: it returns
**two volumes** (ewes and lambs) and never one combined document; the lambs volume, being over
`kPdfRowsPerVolume`, is **itself** two files whose running headers read `part 1 of 2` and
`part 2 of 2`; the sum of the data rows across every produced file equals the number of rows in the
season, so **nothing was truncated**; and the return value of each build is
`({String path, int byteSize})` and **not** a `Uint8List` — assert the static type, because that is
the isolate-memory property and a test can check it for free.

**Green.** The minimum code that passes, and nothing beyond it — the split, the isolate hop, and a frame-time assertion during the build.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No schema (**this task stores nothing**), no controller, no screen, no route, no ARB — except one
string, and it is not authored here. The on-screen split message (*"This season is too large for one
file. Exporting as 3 files."*) is a **T07** ARB message, because T07 owns the screen that renders it;
what this task produces is the **count** that message is built from, returned as data.

| # | Path | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/export_limits.dart` | **New.** `kPdfRowsPerVolume` and `kBackupSizeTripwireBytes` (the second is N22's to use, and lives here because `09 §1.2` puts both in this file). Both carry their `UNVERIFIED` doc comment verbatim — see §5.3 |
| 2 | `lib/data/pdf_writer.dart` | **Edit.** The `PdfJob` record, the two top-level `compute` entry points `buildFlockBookPdf` and `buildMedicineRecordPdf`, `_flockBookBody`, `_medicineRecordBody`, the statistics block and the boxed statement. `_buildDocument` from T04 is unchanged |
| 3 | `lib/data/export_repository.dart` | **Edit.** The read side: the row materialisation that produces `List<List<String>>` **already formatted**, the statistics triples, and the volume split. Still no write — `CONVENTIONS §2.13` has not moved |
| 4 | `test/features/pdf_writer_test.dart` | **Edit. The anchor case is added to T04's file**, which is why the anchor path is the same as T04's. Two tasks, one file, two anchors — say so in the commit message |
| 5 | `test/domain/uk_zone/pdf_born_cell_test.dart` | **New.** `@Tags(['uk-zone'])`. The `Born` cell across the ambiguous hour — see §5.4 |
| 6 | `docs/perf/measurements.md` | **Edit.** §10 item 4: peak RSS generating a 2,000-row volume on the low-end target device, **or** an explicit line saying it has not been measured and the constant is still a working bound |

`tool/check_policy.dart` is **not** touched: T04 landed both rules this file must satisfy, and
`export.pdf_document` is what keeps the two new entry points inside this file.

### 5.2 The signatures

`09 §4.4` prints the job and the entry point. The shape of the payload is the design:

```dart
// lib/data/pdf_writer.dart — top-level functions, as compute() requires.
typedef PdfJob = ({
  String outPath,
  String title,
  ExportEnvelope envelope,
  Uint8List fontBytes,
  List<List<String>> rows,        // already formatted; no domain logic here
  List<String> columnHeaders,
  List<(String label, String value, String definition)> stats,
});

Future<({String path, int byteSize})> buildFlockBookPdf(PdfJob job) async {
  final bytes = await _buildDocument(
    envelope: job.envelope,
    title: job.title,
    base: pw.Font.ttf(ByteData.sublistView(job.fontBytes)),   // §4.2, not .buffer
    body: (c) => _flockBookBody(job),
  );
  final f = await File(job.outPath).writeAsBytes(bytes, flush: true);
  return (path: f.path, byteSize: bytes.length);
}

Future<({String path, int byteSize})> buildMedicineRecordPdf(PdfJob job) async { … }
```

```dart
// lib/data/export_limits.dart
/// UNVERIFIED. A working bound until peak RSS is measured on the low-end
/// target device (09 §10 item 4). At 8 pt landscape A4 this is roughly 50 pages.
const int kPdfRowsPerVolume = 2000;
```

**The three documents.**

| Document | Table columns | Order | Split? |
|---|---|---|---|
| Flock book — **ewes** volume | Tag · Born · Breed · Status · Season outcome · Lambings · Born · Alive · Reared · Assisted · Observations | `tag_digits`, then `tag` | at `kPdfRowsPerVolume` |
| Flock book — **lambs** volume | Tag · Birth dam · Rearing dam · Born · Sex · Birth type · Ease · Weight · Status · Died · Cause · Note | birth dam, then birth time | at `kPdfRowsPerVolume` |
| Medicine record | Date · Animal · Product · Dose · Route · Batch · Meat withdrawal · Clear (meat) · Milk withdrawal · Clear (milk) · Note | `administered_at` ascending | **never** — row counts here are tens, not thousands |

**The statistics block** (ewes volume front matter). One line per statistic, three printed lines each:

```
Lambing percentage            165%
                              lambs born alive per ewe put to the ram
                              660 lambs born alive ÷ 400 ewes put to the ram
```

The middle line is `StatResult.definition`, **verbatim**, from `LambingPercentageChoice.definition`
(R61) — not paraphrased, not shortened, not replaced by the formula. The formula may appear
*alongside* it, as the third line does. This string outlives the app: someone reads this PDF in 2033
and needs to know which of the two conventions produced 165%.

**The boxed statement** (medicine record only, page 1, under the title, `09 §4.7`) is composed inside
`_buildDocument` through `titleBoxUnderHeading` and carries `Disclaimers.exportFooter` and
`Disclaimers.withdrawalCaveat`, both **referenced**. The box is **in addition to** the running footer,
never instead of it.

### 5.3 The details that are easy to get wrong

- **Returning `Uint8List` from `compute` is the mistake this whole design exists to prevent.** It
  copies across the isolate boundary, so a 40 MB document costs 80 MB at the exact moment you are
  trying not to run out of memory. The isolate has `dart:io`; **let it write the file**. Nothing but a
  path and a byte count crosses back, and the anchor test asserts the static return type for that
  reason.
- **A drift connection cannot cross an isolate boundary** (#125). All reads happen on the main
  isolate, in `ExportRepository`, and the payload that crosses is plain data. The domain value types
  are already sendable **because** they are extension types over `int` and `String` — an `Instant` is
  an `int` at runtime, a `LocalDate` is a `String` — so nothing needs converting.
- **`rows` is `List<List<String>>`, fully formatted before it crosses, and this is not laziness.**
  The isolate does no unit conversion, no date formatting and no terminology resolution, because it
  has no `WeightUnit`, no `Terminology` and no ARB. Formatting on the main isolate is also what keeps
  the payload free of anything that can throw halfway through a document.
- **Do not call `rootBundle` from inside `compute`.** It needs the root isolate's binary messenger.
  `fontBytes` is a field on `PdfJob`, resolved by the caller with `rootBundle.load(...)` and
  `Uint8List.sublistView(data)` — **not** `data.buffer.asUint8List()`, for the offset reason in T04
  §5.3. **In this task the bytes are a parameter and the tests read the TTF from disk directly**; the
  one `rootBundle.load` call site in the app lands in T07's `ExportWriteController`. Naming that
  boundary now is what stops a `package:flutter/services.dart` import appearing in `lib/data/`.
- **CSV and JSON stay on the main isolate.** #125 is exhaustive: only PDF generation and image
  downscaling go off-isolate. Isolating a CSV at this volume buys nothing and costs a copy — and it
  would make `CsvWriter`'s trailer a cross-isolate concern for no reason.
- **Two volumes always. It is the shape, not a fallback.** Code that produces one combined document
  "when the season is small" produces a *different artefact* for a small flock, which means the
  medicine-record-sized case is the one nobody ever tests.
- **Never truncate silently and never render "and 431 more rows".** Every row that exists goes into a
  file. When a volume exceeds the cap it splits on a row boundary into `…-lambs-1.pdf`,
  `…-lambs-2.pdf`, each with `part N of M` in the running header, and the user is told plainly. An
  honest message beats a crash; a crash during *"export my season"* is precisely the moment the user
  is trying to protect their data.
- **`kPdfRowsPerVolume = 2000` is UNVERIFIED and its doc comment says so.** Do not delete the comment
  because the tests passed on a desktop — the number is a bound on **peak RSS on a €150 Android phone
  in a cold shed with the camera app still resident**, and the 100–200 MB peak-heap figure in `09
  §4.9` is an estimate, not a measurement. If you cannot measure it in this commit, say so in the PR
  body and leave the constant and its comment exactly as written.
- **`?? 0` on a nullable aggregate in the statistics block is a review-blocking defect.** When
  `StatResult.value` is null the line prints `not computable — <notComputableReason>` and never `0`
  and never `—`. `StatResult.notComputable` exists for exactly this, and a `0%` lambing percentage
  printed into a document somebody keeps is worse than a blank.
- **The `definition` string is verbatim (R61) and the choice is the user's.** Four
  `LambingPercentageChoice` members, four pinned strings, and `app_settings.percentage_definition`
  says which is in force. Print the one that produced the number, not the default.
- **`Born` is `d MMM HH:mm` — `14 Mar 03:20` — and never `dd/MM HH:mm`** (R60, #108). A PDF is read
  by a human and has no ISO column beside it. The year is omitted rather than abbreviated because the
  volume is season-scoped and the season label is in the running header on every page. The medicine
  record's `Date` is `d MMM y HH:mm` **with** the year, because that is the document where a misread
  date is worst.
- **Every date cell carries a provenance mark and the front matter carries the legend.** Asterisk for
  `entered`, dagger for `edited`, nothing for `auto`, and the legend spells all three out using
  `TimeSource.label` — built from the enum, not typed. A mark with no legend is a mark that means
  nothing to the person holding the paper.
- **`Weight` is the display unit from `unitsProvider`** — `4.10 kg` or `9 lb 0 oz` — because a PDF is
  a document a human reads. This is the exact opposite of the CSV rule, and the sentence that decides
  every argument is: **CSV is interchange, PDF is display.** The conversion happens on the main
  isolate, because the isolate has no `WeightUnit`.
- **`Sex` renders `—` for a null and the word `unknown` for the recorded `unknown`.** Same rule as
  the CSV (R45), different glyph, and it is the one place a dash is correct.
- **A voided treatment renders with a strike-through and a `VOID <d MMM y>` marker in the Note
  column. The row is never removed** (#69) — it may already have been printed into a medicine book
  handed to a vet. The same is true of a struck row anywhere in either document (R75): drawn,
  struck, never dropped.
- **`Meat withdrawal` has exactly three renderings: `28 days (as entered by you)`, `not applicable`,
  or `not recorded`.** The parenthetical is `Disclaimers.withdrawalProvenance`, referenced. There is
  no fourth rendering and **there is never a blank cell a reader could take for zero** — that is the
  §12.1 failure this document exists to avoid.
- **`Clear (meat)` is the stored `clear_date`, formatted `d MMM y`, never recomputed** (#50). If
  `clear_date_disagrees`, the cell renders the stored date followed by `(see app)`. **The PDF warns;
  it does not fix.**
- **No photos, ever** (#83). Media goes out as a separate share. This is one of the five memory
  mitigations and the only one a feature request will try to reverse.
- **The medicine record is never split**, and it is a mistake to write the split logic generically
  enough that it could be. Row counts there are tens; a "part 1 of 2" medicine record would look like
  a document with a page missing.
- **`pw.MultiPage` builds its widget tree before paginating and `save()` materialises the whole
  document.** That is why the cap exists at all. Do not add a sixth mitigation before measuring —
  `09 §4.9` names the five and names the measurement.

### 5.4 The full test set

`test/features/pdf_writer_test.dart` — T04's file, extended. `FlockGenerator(seed: 42)` supplies the
volume; the committed fixtures do not exist until N23-T05.

| Case | What it asserts |
|---|---|
| `'a 400-ewe flock book splits at the row cap and builds off the UI isolate'` | **The anchor.** Two volumes; the lambs volume itself split into `part 1 of 2` / `part 2 of 2`; the summed data-row count equals the season's; the return type is `({String path, int byteSize})` |
| `'the build does not block the UI isolate'` | Drive a `Ticker`-free counter on the main isolate while the build runs and assert it advanced. `12 §11.6` bans `Future.delayed` in a test body — use the tester's pump loop or a counting `Future.microtask` chain, not a sleep |
| `'nothing is truncated at any flock size'` | Parameterised at 1, `kPdfRowsPerVolume - 1`, `kPdfRowsPerVolume`, `kPdfRowsPerVolume + 1` rows. The off-by-one at the cap boundary is the one that silently drops the last row |
| `'the flock book is always two volumes, even for a three-ewe season'` | The shape, not a fallback |
| `'the medicine record is never split, at any row count'` | 5,000 treatments still produce one file |
| `'a null statistic prints not computable and never 0'` | A season with zero ewes put to the ram: `StatResult.value` is null, the line reads `not computable — <reason>`, and the bytes contain neither `0%` nor `—` in that position |
| `'every statistic prints its definition verbatim'` | For each of the four `LambingPercentageChoice` members, the drawn text equals `definition` character for character (R61) |
| `'a voided treatment is drawn struck with a VOID marker and is never removed'` | Row present; `VOID` in the Note column; the row count unchanged versus the same fixture without the void |
| `'a struck lamb appears in the lambs volume, struck'` | R75 in the PDF, the counterpart of T02's CSV anchor |
| `'meat withdrawal renders one of exactly three strings and never a blank cell'` | Over the three states; assert the cell is non-empty in all three cases |
| `'a disagreeing clear date renders the stored date followed by (see app)'` | #50 and §12.4 in the artefact a vet reads |
| `'no drawn date is all-numeric in either document'` | R60. Over the produced text of both documents, not just the format strings |
| `'the provenance legend is built from TimeSource and names all three sources'` | The front matter contains all three labels; adding a fourth enum member would change the legend with no edit here |
| `'weight renders in the user\'s unit and the CSV does not'` | The same fixture at `kg` and at `lb`: the PDF text differs, the CSV bytes are identical. One test, both halves of *CSV is interchange, PDF is display* |
| `'sex renders — for null and the word unknown for the recorded unknown'` | R45, in print |
| `'the medicine record carries the boxed statement under the title AND the running footer'` | Both present on page 1; the footer present on every page; the box present only on page 1 |
| `'no photo byte reaches any PDF'` | Seed a lambing with a `media_assets` row and assert the produced bytes contain no `/Image` XObject and no JPEG SOI marker |
| `'only a path and a byte count cross back from the isolate'` | Static type assertion plus a source-text check that neither entry point's return type mentions `Uint8List` |

`test/domain/uk_zone/pdf_born_cell_test.dart` — `@Tags(['uk-zone'])` under `TZ=Europe/London`:

| Case | What it asserts |
|---|---|
| `'two lambings an hour apart in the ambiguous hour both render 01:30 and are adjacent in birth order'` | The `Born` cell cannot disambiguate them and is not supposed to — the ordering comes from `occurred_at`, which is an instant. The case exists so nobody "fixes" the cell by adding an offset suffix, which would be the all-numeric-adjacent change R60 is guarding |
| `'the medicine record\'s Date cell keeps its year across the clocks-back boundary'` | A treatment at 01:30 GMT on the Sunday and one at 01:30 BST an hour earlier both render `d MMM y HH:mm`, in the right order, with the right year |
| `'a clear date computed across a DST boundary matches the stored value'` | `clearDateFor` is domain arithmetic settled in N05; this asserts the **document prints the stored value** and does not recompute it, which is the only way the two could differ |

## 6. Constraints that bind this task

- **The five safety rules** — §12.1 (three renderings, never a blank cell, the provenance phrase referenced), §12.3 (the running footer plus the boxed statement in the medicine record), §12.4 (`(see app)` rather than a recomputed clear date; a void that is drawn rather than removed) and §12.5 (a provenance mark on every date cell plus a legend). All four are visible on paper, which is the only place they can be checked by the person who matters.
- **Indelible Rule 1** — a struck row is drawn struck and never dropped, in a document as in a file.
- **R60 — no drawn date is all-numeric.** `d MMM HH:mm` in the flock book, `d MMM y HH:mm` in the medicine record.
- **Memory is a safety constraint here, not a performance one.** An OOM kill during *"export my season"* loses nothing from the database but teaches the shepherd the export does not work, which is the same as having no backup.
- **Offline** — no network path may be added. G2 and G3 stay green; this task adds no dependency, and `pdf` was audited in T04.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'a 400-ewe flock book splits at the row cap and builds off the UI isolate'` passes, and was seen to fail first for the stated reason
- [ ] the build does not block the UI isolate
- [ ] the split happens at the recorded row cap
- [ ] the medicine record is chronological, per spec §7.5
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the two `compute` entry points return `({String path, int byteSize})` and no `Uint8List` crosses the boundary in either direction
- [ ] the flock book is **always** two volumes, and nothing is ever truncated at any flock size
- [ ] the medicine record is never split
- [ ] `?? 0` appears nowhere near a `StatResult`; a null value prints `not computable — <reason>`
- [ ] every statistic prints `StatResult.definition` verbatim (R61)
- [ ] a voided treatment and a struck row are both **drawn** and never removed
- [ ] `kPdfRowsPerVolume` keeps its `UNVERIFIED` doc comment unless §10 item 4 was actually measured on a real low-end device, and the measurement (or its absence) is recorded in `docs/perf/measurements.md`
- [ ] no photo byte reaches any PDF

## 8. Verification

```bash
fvm flutter test test/features/pdf_writer_test.dart
make check
make test
```

Then the DST tier, and the two properties that a grep proves faster than a test:

```bash
TZ=Europe/London fvm flutter test --tags uk-zone

grep -n "Uint8List" lib/data/pdf_writer.dart | grep -i "return\|Future<"
# expect only _buildDocument's own return — never an entry point's

grep -rn "?? 0\|?? '0'" lib/data/pdf_writer.dart lib/data/export_repository.dart
# expect nothing
```

Then open the artefacts a 400-ewe run produces and look at page 3 of the lambs volume: the table
header repeats, the running header says `part 1 of 2`, the footer is present, and no date is
all-numeric.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(export): the flock book in two volumes, off the UI isolate`

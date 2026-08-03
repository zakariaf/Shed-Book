# N21 — Export: CSV, PDF and share

| | |
|---|---|
| **`00-README` §9 step** | 8 (1 of 3) |
| **Ships in** | **split** — `v1.0.0` T01 T02 T03 T06 T07 T08 · `v1.1.0` T04 T05 (the two PDFs) |
| **Depends on** | N20 |
| **Size** | L |
| **Was** | E18 |
| **Branch** | `epic/n21-export` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |
| **Adds to `pubspec.yaml`** | **Yes — two runtime dependencies**: `pdf` 3.13.0 (T04) and `share_plus` 13.3.0 (T06), both from decision-record §5.1 and nowhere else. Each lands in its own task's commit with its `pubspec.lock` diff read, and each adds a line to `tool/policy_allowlist.txt`'s `[dependencies]` section |
| **Touches native files** | **No** — but `share_plus` merges a `ShareFileProvider` and a `SharePlusPendingIntent` receiver into `AndroidManifest.xml`, and **no `uses-permission`**. That is a merged-manifest change with a zero-permission delta, and G1 is what proves it |
| **Reopens a frozen file** | **Yes, once** — `lib/domain/time/recorded_time.dart` gains `String get label` on `enum TimeSource` (T01). `lib/domain/` finished at N06 and the schema froze at N07; this is the epic's only edit into either, it is additive, and `CONVENTIONS §2.2` is amended in the same commit |

## Goal

The only backup this product has, and the only route records leave the phone by.

Concretely, eight commits produce: a hand-rolled RFC 4180 encoder that is the app's **only** producer
of CSV bytes; the three CSV shapes with their frozen header rows and every struck row present and
marked; the §12.1 + §12.3 + §12.5 trailers emitted by the writer's own frame rather than by its
caller; a PDF builder that is the app's **only** `pw.Document(` site, with a mandatory embedded TTF;
the flock book in two volumes and the medicine record, built on a `compute` isolate that writes the
file itself; `ShareService`, the one seam anything leaves by; `ExportRepository` — the one repository
that writes nothing — with `exportCountsProvider` and the Export screen; and the end-of-day banner,
which is overflow-matrix variant 14.

The JSON backup is **not** here. It is N22, deliberately: the format has a checksum, a canonical
encoder and a forward-compatibility contract, and bundling it with six other artefacts makes both
unreviewable.

## Release scope — P15

**Six tasks ship in `v1.0.0`; T04 and T05 wait for `v1.1.0`.**

| | |
|---|---|
| `v1.0.0` | **T01** `CsvWriter` · **T02** the three shapes and their frozen headers · **T03** the §12.1/§12.3/§12.5 trailers · **T06** `ShareService` · **T07** `ExportRepository` and the Export screen · **T08** the end-of-day banner |
| `v1.1.0` | **T04** `pdf_writer.dart` · **T05** the flock book in two volumes and the medicine record |

**Why the CSV half cannot wait.** It is the *only* route records leave the phone by, and `ShareService`
is what makes N22's JSON backup deliverable at all. Spec §7.9 calls export a safety feature rather than
a convenience, and `v1.0.0` ships into a season during which `13 §11` forbids fixing anything that is
not data loss.

**Why the PDF half can.** The medicine record ships as CSV in `v1.0.0`, with the same trailers, emitted
by the writer's own frame; it opens and prints from any spreadsheet. §12.3 forbids presenting the app
as a compliance record in **either** format, so the PDF is a nicer artefact and not a different claim.

**And deferring it removes a dependency from the release that first argues offline purity in public.**
`pdf` 3.13.0 leaves `v1.0.0`'s graph entirely — one fewer line in `tool/policy_allowlist.txt`'s
`[dependencies]` section, one fewer package for G2 and G3, and a smaller binary against #127's budget.
**T06 still adds `share_plus` 13.3.0**, whose zero-permission manifest merge G1 proves; that half of
this epic's dependency note is unchanged.

## Why the epic sits here

`00-README` §9 puts this at **step 8**, after Treatments (step 7, N20) and before Reminders (step 9,
N24). Its stated reason, not re-derived here:

> *"Export, backup and restore — then `tool/seed.dart`, which writes its demo database through the
> restore path. Restore must exist before the seed script can route through it, and the seed script
> is what makes 400-ewe profiling, the overflow matrix, the goldens and the at-cap monetization tests
> possible at all."*

Three consequences bind this epic's scope:

- It comes **after** N20 because `treatments.csv` and the medicine record are the artefacts with the
  highest stakes, and both render `WithdrawalPeriod`'s three states (`days` / `not_applicable` /
  `not_recorded`). A CSV shape written before the withdrawal child table exists is a CSV shape that
  learns about `not_recorded` late — and `not_recorded` collapsing to `0` in an exported medicine
  record is the app asserting a withdrawal period it was never told, in the document somebody hands
  to a vet.
- It comes **after** N07's freeze because every column in §3's three shapes names a stored column,
  and after **N00-T05's R75 ruling** because `struck` / `struck_at` are on `mixin Identified` and are
  CSV columns. `00-T05` §"details that are easy to get wrong" is explicit about the cost of the
  alternative: *"rule it at N21 and it is N06, N07, N09's queries, N21's three CSV shapes and N23's
  restore, all revisited."*
- It comes **before** N22 and N23 because the JSON backup reuses `ExportEnvelope`, `ShareService` and
  the artefact-assembly shape this epic establishes, and because `test/support/fake_share_service.dart`
  — built in T06 — is what makes N23's export → import → export equality property testable at all
  (`12 §4.2`: *"a fake is a real implementation… you need the bytes, not a `verify`"*).

`00-README` §9's two parallel tracks apply: the **ARB** (T07 and T08 author every user-facing string
in `lib/l10n/app_en.arb` with a `description`) and **accessibility** (every element a
`semanticLabel`, every heading a `headingLevel:`). Neither is a later sweep; N33 only verifies.

## What is observably true when this epic merges

Run these on the merged `main` and watch them pass — this is the demo:

```bash
fvm flutter test test/features/csv_writer_test.dart \
                 test/features/csv_shapes_test.dart \
                 test/features/pdf_writer_test.dart \
                 test/features/export_test.dart \
                 test/features/overflow_matrix_test.dart \
                 test/data/share_service_test.dart \
                 test/policy/disclaimer_is_referenced_test.dart \
                 test/policy/withdrawal_is_never_defaulted_in_an_export_test.dart
make check            # includes the five new export.* rules
make test             # + TZ=Europe/London --tags uk-zone
```

- **Three CSVs and three PDF files leave a real phone through the system share sheet**, land in a
  mail draft or on a USB stick, and open in Excel, Numbers and Google Sheets with `°`, `£` and a
  Welsh `ŵ` intact. Not a screenshot test — tap each of the six rows on the Export screen on a real
  device and open what arrives.
- **A note typed as `-2 lambs born, "she kicked"` survives the round trip**: it opens in Excel as
  text and not as a formula, the embedded comma does not shift a column, and the stored record in
  SQLite is byte-identical to what the shepherd typed.
- **Every struck row is in the file and marked.** `grep -c 'WHERE struck' lib/data/export_repository.dart`
  is **0**, and a struck lamb appears in `lambs.csv` with its strike instant beside it. Indelible's
  screen 11 promise — *"an export that quietly drops the strikes would undo the one thing this app is
  for"* — is a test, not a sentence.
- **Every one of the five artefacts carries its §12.3 trailer, from an empty database as well as a
  seeded one.** `test/policy/disclaimer_is_referenced_test.dart` asserts the string is a literal in
  exactly one file — `lib/domain/policy/disclaimers.dart` — and reaches it through
  `joinedStringLiterals`, because Dart wraps a long string across adjacent literals and a naive
  `contains` misses it.
- **`grep -rn 'pw.Document(\|pw.MultiPage(' lib/` returns exactly `lib/data/pdf_writer.dart`**, and
  `footer:` is set inside `_buildDocument` where no caller can reach it. That is what makes *"the
  disclaimer is on every page of every PDF"* structural rather than a review item.
- **No base-14 font is constructed anywhere.** `Font.helvetica`, `.times`, `.courier`, `.symbol` and
  `.zapfDingbats` are banned by `export.base_14_font`, because they are Latin-1 and **throw** on the
  curly quote an iOS keyboard inserts by itself — while exporting the medicine record for a vet.
- **A 400-ewe flock book builds without freezing the phone**, splits into an ewes volume and a lambs
  volume always, splits again at `kPdfRowsPerVolume` with `part N of M` in the running header, and
  says so on screen: *"This season is too large for one file. Exporting as 3 files."* Nothing is ever
  truncated and no PDF ever says *"and 431 more rows"*.
- **`ExportRepository` has no write path at all.** `grep -n 'transaction(\|into(\|update(\|delete(' lib/data/export_repository.dart`
  returns nothing, which is `CONVENTIONS §2.13`'s *"nothing — read + artefact assembly only"* made
  mechanical, and is why `SettingsRepository` came forward to N12-T02.
- **Nothing on the Export screen is gated by the free tier at any entitlement state** — not over the
  ewe cap, not in season two. `test/features/no_monetization_test.dart` covers it and 07 §13.2's
  over-cap row for this screen reads, in full, *"nothing"*.
- **The end-of-day banner is variant 14 of the 252-cell matrix**, and Quick Entry's confirm key is
  still on screen without scrolling at 375×667 × textScaler 1.3 **with the banner shown**.

Deliberately **not** demonstrable yet, and the reason for each: there is no JSON backup and no
`writeBackup` (N22-T02); no file import (N22-T05); no restore, so no export → import → export
equality (N23-T07); no `tool/seed.dart`, so the 400-ewe measurements in T05 run against
`FlockGenerator` rather than a committed fixture (N23-T04/T05); no temp-directory sweep at launch
(N23-T03 owns `MediaSweeper` in both directions — N21 writes into `getTemporaryDirectory()` and does
not clean it); and no golden of any artefact — `12 §1.3` rules a PDF byte golden out on purpose
(*"a byte assertion on a 60-page document is a re-baselining chore that proves nothing"*).

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/09-export-formats.md` | **§1.1–§1.3** (the six artefacts, the five new files, the nine sibling edits) · **§2** (the encoder printed in full, the nine quoting rows, BOM/CRLF, the formula guard, the six trailer records) · **§3** (the three shapes, column by column, and §3.4's three frozen header rows) · **§4** (`pdf` not `printing`, the mandatory TTF, `_buildDocument`, the isolate split, page furniture, the two volumes, the medicine record's box, the row cap, memory) · **§6** (the §12 strings and the three mechanisms that make them undroppable) · **§8** (the share sheet, printing, `last_exported_at`, media) · **§9** (the anti-pattern table and the five `export.*` rule ids) · **§10** (thirteen unverified items, five of which this epic must run) | every byte that leaves the phone |
| `docs/engineering/07-screens.md` | §13.1–§13.4 (the Export screen: the query, eight states, seven actions, the honest wording and the permanently banned sentence) · §16.1–§16.4 (the end-of-day banner: why a banner and not a notification, the six conditions, the wording, and why it is its own layout variant) | T07 and T08 |
| `docs/engineering/08-platform-integration.md` | §1.1–§1.2 (`_confinedPackages`, `layer.plugin_share_plus`, `layer.path_provider`) · §5 (`ShareService` printed in full, `ShareOutcome`, the four operational rules, and the `last_exported_at` three-way) | T06, and where `getTemporaryDirectory()` may be called from |
| `docs/engineering/12-testing.md` | §1.3 (what is deliberately not tested — the PDF byte golden) · §4.2 (`FakeShareService` and its two tripwires) · §5.1 (`shedContainer` and `pumpApp`, printed) · §5.3 (the closed twelve-file `test/support/` list, incl. `armExportBanner` in `seeds.dart`) · §6.1–§6.4 (the 252-cell matrix, variant 14, the reachability assertion) · §11.1 (a policy test is named for the property) | every test file this epic writes, and where it lives |
| `docs/engineering/03-data-model-and-schema.md` | §5.2 (`ewes`) · §5.4 (`lambings` + the `lambing_consistency` view) · §5.5 (`lambs`) · §5.8 (`treatments` + `treatment_withdrawals`, and why there is no `withdrawal_days` column) · §5.13 (`app_settings`' three banner columns) · §7 (`lamb_rearing`) | every column §3's shapes name |
| `docs/engineering/05-domain-correctness.md` | §4 (`RecordedTime`, `TimeSource`, the three provenance labels verbatim) · §6.2 (the four `definition` strings) · §7.3 (`ContentPolicy`) · §7.4 (`Disclaimers` and `ExportEnvelope`, printed, and the single-definition test) | the strings, and the type that makes them undroppable |
| `docs/engineering/CONVENTIONS.md` | §1 + §1.1 (the tree; layer rules 3, 4, 5, 6, 8) · §2.2 (`Instant`, `LocalDate`, `PartialDate`, `RecordedTime`, `TimeSource`) · §2.7 (`WithdrawalPeriod`'s three states) · §2.8 (`ExportEnvelope` vs `BackupHeader`) · §2.12 (`ShareService`) · §2.13 (`ExportRepository` owns **nothing**) · §2.14 (`Disclaimers`) · §3.1–§3.4 (`shareServiceProvider`, `exportCountsProvider`, `exportControllerProvider`, `exportWriteControllerProvider`) · §4.1–§4.7 (files, types, providers, widget keys, rule ids) · §5.3–§5.4 (banned words, copy conventions) · R18, R32, R33, R45, R48, R57, R58, R60, R61, R65, R68, **R75** | **BINDING** on every path, type, provider, column and word |
| `docs/research/00-tech-decisions.md` | **§5.1 only** for versions (`pdf` 3.13.0, `share_plus` 13.3.0) · §5.3 (`csv` 8.0.0 and `printing` 5.15.0, rejected, with the reason) · #29, #32, #50, #53, #54, #56, #62, #69, #72, #80, #82, #83, #85, #86, #98, #108, #125, #127 | the decisions this epic applies, and the two it must not re-open |
| `docs/design/indelible.md` | §1.2 Rule 1 (*"nothing is ever removed, only struck"*) · §Marks 5 (the 3 px madder strike) · **screen 11** (the six word buttons, the honest status line, the printed footer, and *"every CSV carries a `struck` and a `struck_at` column"*) · §12 rule 3 row | what the Export screen is, and the second footer sentence T03 has to place |
| `epics/N00-.../N00-T05` | the whole task — **R75** | `struck` / `struck_at`: the exact spelling, which tables carry them, which side they fall on per query, and the CSV requirement |
| `epics/00-PLAN-CRITIQUE.md` | §S6 (the banner writes `app_settings`, so `SettingsRepository` came forward to N12-T02, and `last_exported_at` is stamped on `completed` **and** `unknown`, never on `dismissed`) · §"the anchor tests" rows for N21-T01 and N21-T02 | why T08 owns no write of its own, and the two anchors that are fixed |

## Tasks

Strictly sequential: each task depends on the one before it, and the order is the order the code
compiles in. `CsvWriter` cannot emit a trailer before `TimeSource.label` exists; the three shapes
cannot be written before the encoder; the PDF builder has nothing to put in a footer before T03 has
placed the trailers; the flock book cannot be built before there is a builder; nothing can be shared
before there is a share seam; the screen cannot render counts before there is a repository; and the
banner cannot be a matrix variant before Quick Entry has an Export screen to push.

| Task | Depends on | One line |
|---|---|---|
| [N21-T01](N21-T01-csvwriter-hand-rolled-rfc-4180.md) | N20-T07 | `CsvWriter` — hand-rolled RFC 4180 |
| [N21-T02](N21-T02-the-three-shapes-and-their-verbatim-header-rows.md) | N21-T01 | The three shapes and their verbatim header rows |
| [N21-T03](N21-T03-the-disclaimer-trailers-referenced-and-never-re-typed.md) | N21-T02 | The disclaimer trailers, referenced and never re-typed |
| [N21-T04](N21-T04-pdf-writerdart-one-builder-one-embedded-font.md) | N21-T03 | `pdf_writer.dart` — one builder, one embedded font |
| [N21-T05](N21-T05-the-flock-book-in-two-volumes-and-the-medicine-record.md) | N21-T04 | The flock book in two volumes and the medicine record |
| [N21-T06](N21-T06-shareservice-the-share-sheet-and-nowhere-else.md) | N21-T05 | `ShareService` — the share sheet and nowhere else |
| [N21-T07](N21-T07-exportrepository-exportcountsprovider-and-the-export-screen.md) | N21-T06 | `ExportRepository`, `exportCountsProvider` and the Export screen |
| [N21-T08](N21-T08-the-end-of-day-export-banner.md) | N21-T07 · N12-T02 | The end-of-day export banner |

**Three files are written twice in this epic, and that is deliberate.**
`lib/data/export_repository.dart` lands at T02 holding the three `const` header rows and the three
CSV writers, and grows at T07 into `ExportArtifact`, the PDF assembly and the counts query.
`lib/data/pdf_writer.dart` lands at T04 as `_buildDocument` and its page furniture, and grows at T05
into `buildFlockBookPdf` and `buildMedicineRecordPdf`. `test/support/harness.dart` is edited at T06
(`FakeShareService` joins the override list), T07 (`RouteNames.export` joins `kPumpableVariants`) and
T08 (the fourteenth entry and `armExportBanner` in `seeds.dart`). Naming which task writes which half
is the difference between a green task file and a red CI run.

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N20 is merged and `main` is green before this starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version              # must match .fvmrc; the pin is the gate's first check
git checkout -b epic/n21-export
```

**2 — One commit per task, eight commits, in task order.** Each task file names its commit line
verbatim; use it. Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test         # randomised order, + TZ=Europe/London --tags uk-zone
```

Three commits in this epic carry an obligation beyond the ordinary:

- **T01** edits `lib/domain/time/recorded_time.dart`. `lib/domain/` closed at N06 and
  `00-README` §10 puts `lib/domain/withdrawal|stats|time/` high in the irreversibility order. The
  edit is one getter and it is **not optional** — 09 §6.3's §12.5 trailer is built from
  `TimeSource.values.map((s) => s.label)` and there is no `RecordedTime` instance to ask. Amend
  `CONVENTIONS §2.2` in the same commit or the next fixer deletes the getter as a stray name.
- **T04 and T06** each add a runtime dependency. `00-README` §7.4: a dependency change is its own
  commit, its own `flutter pub get`, its own `pubspec.lock` diff, **and its own read of that diff**.
  Read it. `pdf` brings `archive`, `barcode`, `bidi`, `crypto`, `image`, `meta`, `path_parsing`,
  `vector_math` and `xml`; none of them is an HTTP client and G2's transitive allowlist is where you
  prove it. Being in the lockfile is **not** a licence to import: `crypto` arrives through `pdf` and
  is still not a direct dependency, which is exactly why N22's checksum is FNV-1a and not SHA-256.
- **T02** freezes three header rows. Renaming a column later is a breaking change to every
  spreadsheet a shepherd has built on top of the file. Read §3.4 against the diff character by
  character; the golden test is what holds it afterwards.

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the
diff in `00-README` §10's irreversibility order. For this branch that order is:
`pubspec.yaml` + `pubspec.lock` + `tool/policy_allowlist.txt` →
`tool/check_policy.dart` (five new `export.*` rows) →
`lib/domain/time/recorded_time.dart` and `docs/` amendments →
`lib/data/csv_writer.dart`, `pdf_writer.dart`, `export_limits.dart`, `export_repository.dart`,
`share_service.dart` — **every new export format is on the never-waved-through list, however small** →
`lib/l10n/app_en.arb` →
`lib/features/export/**` and `lib/features/quick_entry/**` →
`test/`.

**4 — Open the PR and answer the five §12 questions** in `.github/pull_request_template.md`
**verbatim, in the PR body**. **Four of the five land here** and none may be answered "not applicable":

- **§12.1 (never default a withdrawal period)** — `treatments.csv` and the medicine record render
  `not_recorded` with three blank companions when there is no `treatment_withdrawals` row, and
  **never `0`**. `test/policy/withdrawal_is_never_defaulted_in_an_export_test.dart` is the proof, and
  it asserts `meat_withdrawal_source` is blank rather than `as entered by you`.
- **§12.3 (never a compliance record)** — every artefact carries `Disclaimers.exportFooter`, the
  medicine record carries the boxed statement under its title as well, and the phrases *compliance
  record* and *official record* appear nowhere in the diff.
- **§12.4 (never silently correct an entry)** — the export **warns and never fixes**:
  `local_date_disagrees` and `clear_date_disagrees` are printed columns beside the stored values,
  the stored `clear_date` is never recomputed (#50), and the formula-injection guard is a declared
  transformation of the **export** whose declaration ships inside the file.
- **§12.5 (timestamps carry provenance)** — every event row exports the full quad
  (`*_at_utc`, `captured_at`, `original_effective`, `time_source`) plus its label; the flock book and
  the medicine record carry a provenance mark on every date cell with a legend in the front matter;
  and the trailer line is built from the enum rather than typed out.

§12.2 (never give veterinary advice) is the one this epic does not reach — say so, and say that
`dose_text` is exported verbatim and is never parsed, normalised or split into a number and a unit,
because that is the closest this epic comes to having an opinion about a medicine.

**Also in the PR body: the five §10 items this epic must have run**, each with its answer written
down rather than left as *"seems fine"* — items 1 (does `pdf` 3.13.0 accept the variable font, and
which instance does it embed), 2 (does it subset), 3 (`TableHelper.fromTextArray(headerCount: 1)`
header repeat across `MultiPage`), 5 (`ShareResultStatus`'s member names and per-platform semantics)
and 13 (is the document-information `subject:` findable as UTF-8 in an uncompressed document). Item 4
(`kPdfRowsPerVolume = 2000` against measured peak RSS) needs a real low-end device; if it has not
been measured, say **that**, and leave the constant's `UNVERIFIED` doc comment in place rather than
deleting it because the tests passed on a desktop.

**5 — Wait for the pipelines.** Three jobs run for this epic and each proves a different thing.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` · the `NSAppTransportSecurity` grep (**G5**, text half) | The five new rows: `export.csv_bytes` (a `\r\n` literal or the BOM triple outside `csv_writer.dart`), `export.pdf_document` (`pw.Document(` / `pw.MultiPage(` outside `pdf_writer.dart`), `export.base_14_font`, `export.share_static` (the deprecated `Share.share*`), `export.intl_in_writer`. Plus the ones that already exist and now have something to fire on: **G3** greps `PdfGoogleFonts` and `networkImage` on every push and is the reason `printing` 5.15.0 is banned; **G2** proves `pdf` and `share_plus` and their transitive graph are on the allowlist; `layer.plugin_share_plus` confines `package:share_plus` to one file; `layer.path_provider` is the rule T07 has to satisfy before it can write a temp file; `layer.data_no_material` proves `share_service.dart` imported `dart:ui` and not `material.dart`; `db.save_verb` proves `ExportRepository` grew no `save*(` |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | A **negative**, and that is the point: N21 adds no table and no column, so **nothing under `drift_schemas/` may move**. If this job is red on this branch, either something reached for a schema change to make an export easier — which is the failure `00-README` §9 step 3 exists to prevent — or `flutter: generate: true` regenerated `lib/l10n/app_localizations*.dart` under T07/T08's ARB additions and they were not committed |
| `test` | `libsqlite3-dev` on the runner · `flutter test -P ci-fast` randomised · `TZ=Europe/London --tags uk-zone` · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · the coverage artefact (reported, **never** gated) | Eight test files plus three policy files. The **`uk-zone` leg is load-bearing in four places** and an untagged case passes for the wrong reason in the runner's own zone: T01's `*_at_local` rendering and the trailer's zone line; T02's `local_date_disagrees`, which compares a **stored** civil date against the civil date of the same instant re-derived in the export-time zone; T05's `Born` cell in the flock book; and T08's civil-day derivation for banner conditions 1 and 3. All four target **01:00–01:59**, where a local wall time occurs twice |

Goldens do **not** run on this PR (`v*` or `workflow_dispatch` only, 10× macOS multiplier), and
`12 §1.3` rules out a rendered-PDF golden permanently: goldening a PDF page tests the `pdf` package.
The `android` job runs but is not this epic's gate; it becomes one the moment G1 reports a permission
delta from `share_plus`'s merged manifest, and the expected delta is **zero**.

**6 — Merge, delete the branch, and only then cut N22.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git checkout main && git pull --ff-only
# confirm main is green, then:
git checkout -b epic/n22-json-backup-format
```

N22 writes the JSON backup against the `ExportEnvelope`, the temp-file discipline and the
`ShareService` seam this epic established. Cutting it from anything other than a green merged `main`
means a backup format rebased onto a moving writer.

## Risks, and what is irreversible

**Irreversible in this epic — say it out loud in the PR body:**

- **The three CSV header rows (T02).** `09 §3.4`: *"They are `const` in `export_repository.dart`,
  asserted by a golden test, and **frozen**: adding a column appends to the end of the list, renaming
  one is a breaking change to every spreadsheet a shepherd has built on top of it."* This is a
  published artefact in the ordinary sense — it is on someone else's laptop the day after they first
  tap the button, and you cannot recall it. Get the order and the spelling right in the first commit.
- **The two runtime dependencies (T04, T06).** Not irreversible in git, but irreversible in *claim*:
  `pdf` and `share_plus` enter the transitive graph the offline-purity contract is measured over, and
  `share_plus` enters the merged Android manifest. Re-admitting `printing` — the obvious way to get
  an in-app print dialog — puts a live `http` client in the graph and **breaks the tier-2 offline
  claim G3 exists to prove**. Decision-record §7.1 q16 is the only thing that reopens it, and it is
  an owner conversation, not a pubspec edit.
- **`TimeSource.label` (T01).** A getter is trivially revertible; a getter that three artefact
  formats and a `CONVENTIONS §2.2` catalogue row depend on is not. Land the catalogue amendment in
  the same commit, per `00-README` §10's amendment rule.
- **`Disclaimers`, and any change to it (T03).** `disclaimers.dart` is on `00-README` §10's
  never-waved-through list by name. If the Indelible strike sentence forces a **fourth** const
  (see T03 §5.3), that is a `CONVENTIONS §2.14` change and a `05 §7.4` amendment, not an edit.

**Not irreversible, and must not appear in this diff at all:** `drift_schemas/`,
`lib/core/db/tables/`, `lib/core/db/migrations.dart`. **If a file under any of those shows up on this
branch, stop and find out why.** This epic stores nothing. The schema froze at N07-T08 and every
column §3 names already exists; a missing column is a finding for the owner, not a migration.

| Risk | Why it bites here | What holds it |
|---|---|---|
| **A silently wrong export** | `09`'s opening line: export is the only backup this app has (spec §7.9, *"a safety feature, not a convenience"*), so *"an export that is silently wrong is the worst bug in the product."* It has no user-visible symptom until the phone is gone | Every shape's test asserts against a seeded database **and an empty one**; the ragged-row check is a `throw` and not an `assert`, so it fires in the release build the shepherd actually runs |
| **A struck row is filtered out of an export** | The natural instinct on every query is `WHERE struck = 0`, and it is right for every count and wrong for every export and every history (R75). It fails silently and looks like tidiness | T02's anchor; `grep -c 'WHERE struck' lib/data/export_repository.dart` in the epic DoD; and Indelible screen 11's promise printed in the footer, which makes a filtered export a *false statement inside the file* |
| **The PDF crashes on a curly quote while exporting for a vet** | Base-14 fonts are Latin-1 and **throw** on `'`, `"`, `–`, `…`, `℃`, `ŵ` and a fada — every one of which an iOS keyboard inserts automatically into a note typed at 3am. `dart_pdf` issues #810, #252, #405 are that crash | T04: always embed a TTF, never construct a base-14 font, and `export.base_14_font` fires on all five constructors under `lib/` |
| **`pdf` 3.13.0 may not accept a variable font** | `AtkinsonHyperlegibleNext[wght].ttf` carries `fvar`/`gvar` tables the package's own parser may ignore, mis-render or reject — and #127 caps bundled assets at 5 MB, so a second family is not free | 09 §10 item 1. T04 runs the twenty-minute check — one page, open it in Preview and Acrobat — **and records the answer in the PR body**. The fallback is two static instances counted against the asset budget in `docs/perf/measurements.md` |
| **`ByteData.sublistView` versus `.buffer.asByteData()`** | `.buffer` hands back the whole backing store and discards `offsetInBytes`, so a font loaded through `rootBundle` fails deep inside a table offset with an error that names neither the font nor the offset. It works on the developer's machine whenever the view happens to start at 0 | 09 §4.2's boxed rule, restated in T04 §5.3 and T05 §5.3 with the reverse direction (`Uint8List.sublistView(byteData)`) as well |
| **Returning `Uint8List` from `compute`** | It copies across the isolate boundary, so a 40 MB document costs 80 MB at the exact moment you are trying not to run out of memory. The isolate has `dart:io`; the obvious code does not use it | 09 §4.4 point 3. `buildFlockBookPdf` returns `({String path, int byteSize})` and nothing else, and T05's DoD says so |
| **`layer.path_provider` blocks the temp file** | `getTemporaryDirectory()` needs `package:path_provider`, which `08 §1.2`'s `_confinedPackages` permits in **exactly two files** — `media_store.dart` and `connection.dart` — neither of which is `export_repository.dart`. You discover this at `make check`, after the code is written | T07 §5.3 rules it before the code is written, on N11-T09's precedent: the directory is **passed in**, resolved by the one component that legitimately has the plugin. Whichever way it is ruled, the gate row and its proving case land in the same commit |
| **`no_monetization_test` fails on the export banner** | `test/features/no_monetization_test.dart` asserts the five shed screens contain no `ShedBanner`, and Quick Entry is one of them — while the export banner **is** a `ShedBanner` on Quick Entry. `ui.monetization_surface` exempts `lib/features/quick_entry/` on purpose (11 §12.1), but the widget test does not exempt itself | T08 §5.3: the assertion is by **widget key**, not by `find.byType(ShedBanner)`, and `11 §12.1`'s reasoning — *"scoping the component ban to two folders would have failed the build on a banner the spec calls a safety feature"* — is quoted in the test's `reason:` |
| **`last_exported_at` stamped on the wrong branch** | Stamp on `dismissed` and the banner lies to a shepherd who did not export. Refuse to stamp on `unknown` and the app nags a shepherd who exports every night, which teaches them to ignore the one banner that matters | `08 §11` and `09 §8.3`, restated identically in T06 and T08: stamp on `completed` **and** `unknown`, never on `dismissed`, never before the sheet opens, in its own single-statement transaction, through `SettingsRepository` |
| **A trailer row breaks a strict parser** | RFC 4180 §2.4 requires a rectangular file. A two-field trailer row on a 37-column file breaks the parse on the **last line**, which is exactly where a shepherd's spreadsheet stops importing — and the failure looks like "the export is truncated" | T01: the trailer rows are padded to the header's field count by `encode` itself, and a test parses a produced file with a strict reader |
| **`#` looks like a comment marker** | It is not — RFC 4180 has no comment syntax. The trailer rows are ordinary records whose first field begins `#`. Anyone "fixing" this by adding a real comment convention breaks every parser | T01 §5.3, and the fact that `#` is deliberately **not** in the formula-lead set, so it is never apostrophe-prefixed |
| **Two footers, and only one of them is `Disclaimers`** | `05 §7.4` pins `exportFooter`'s wording; Indelible screen 11 prints a longer sentence that also promises *"STRUCK ENTRIES ARE INCLUDED AND MARKED STRUCK. NOTHING HAS BEEN REMOVED."* Re-typing either is the duplication `copy.disclaimer_retyped` exists to catch | T03 §5.3 rules it in writing and records the ruling: a fourth `Disclaimers` const beside the three, or an amendment to `exportFooter` that also amends `05 §7.4`, `CONVENTIONS §2.14` and N22's `_disclaimer` golden. Not a quiet third string in a writer |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] `lib/data/csv_writer.dart` is the **only** producer of CSV bytes and `lib/data/pdf_writer.dart` the **only** `pw.Document(` / `pw.MultiPage(` site; `export.csv_bytes` and `export.pdf_document` each have a `firesOn` entry in `test/policy/gate_rules_test.dart` and were watched to fire
- [ ] the five `export.*` rule ids exist in `tool/check_policy.dart` **and** in `CONVENTIONS §4.7`'s namespace list, which gains the `export` namespace in this epic
- [ ] the three header rows match `09 §3.4` byte for byte **plus R75's `struck` / `struck_at` columns appended at the end**, frozen by a golden test that prints the field count
- [ ] `grep -rn "WHERE struck" lib/data/export_repository.dart` returns nothing — no export query filters a struck row
- [ ] every artefact carries its §12.3 trailer **from an empty database as well as a seeded one**, and `Disclaimers.exportFooter` appears as a literal in exactly one file, proved through `joinedStringLiterals`
- [ ] a companion test asserts `Disclaimers.exportFooter.codeUnits.every((c) => c < 128)` — the PDF byte assertion is built on it, and a non-ASCII string makes that test pass for the wrong reason
- [ ] no base-14 font is constructed anywhere; `09 §10` item 1 has been run and its answer recorded in the PR body
- [ ] the PDF is built by `compute()`, the isolate writes the file, and only `({String path, int byteSize})` crosses back
- [ ] no date drawn in any PDF is all-numeric (R60): `grep -n "dd/MM" lib/data/pdf_writer.dart` returns nothing
- [ ] every artefact leaves through `ShareService` with a **file path**, `fileNameOverrides` and a real `sharePositionOrigin`; `Rect.zero` appears at no call site; `XFile.fromData` appears nowhere
- [ ] `ExportRepository` contains no `transaction(`, no `into(`, no `update(`, no `delete(` and no `save`-prefixed verb
- [ ] nothing on the Export screen is gated by the free tier at any entitlement state, at any ewe count, in any season
- [ ] the sentence *"your data never leaves your phone"* appears nowhere in `lib/` or `assets/`, and `check_policy` proves it
- [ ] `kPumpableVariants` still has **14** entries and the matrix self-check still derives 252; the export route and the banner variant are two of them
- [ ] four `uk-zone` cases exist and target 01:00–01:59: the CSV local rendering, `local_date_disagrees`, the flock book's `Born` cell, and the banner's civil-day derivation
- [ ] the diff contains no file under `drift_schemas/`, `lib/core/db/tables/` or `lib/core/db/migrations.dart`
- [ ] `pubspec.lock`'s diff was read, not just committed, and `[transitive]` in `tool/policy_allowlist.txt` accounts for every new line

## Demoable on merge

Three CSVs and two PDF volumes leave the phone through the share sheet, every struck row
included and marked, every footer intact and referenced rather than re-typed.

## Notes

**Two anchor test paths sit outside `R57`'s mirror convention, and they are deliberate.**
`test/features/csv_writer_test.dart` and `test/features/csv_shapes_test.dart` test files in
`lib/data/`, which the file-naming table (`CONVENTIONS §4.1`) would mirror into `test/data/`. Both
paths are fixed by `00-PLAN-CRITIQUE`'s anchor table and are preserved verbatim here. **Do not move
them** — the anchor is a contract with the audit, and a renamed anchor is an anchor nobody can check.
If it is ever tidied, it is one commit that moves both files and updates the critique's table, and it
is not this epic's.

**What this epic does not build, and where it lands instead.** `writeBackup`, `BackupHeader`, the
canonical encoder, the checksum and `unknown_json` re-emission are **N22**. `RestoreService`,
`MediaSweeper` (which is what sweeps the temp directory these artefacts are written into),
`restoreInto`, `freshSupportDir()` and the export → import → export equality property are **N23**.
The two committed fixtures — `test/fixtures/flock_400_3seasons.json` and `flock_15_at_cap.json` — are
**N23-T05**, so T05's 400-ewe measurements run against `FlockGenerator(seed)` here and are re-run
against the fixtures there. The `Settings ▸ Diagnostics` share of the redacted log is **N29**; it is
a different artefact with a different rule (#123) and it is not an export.

**`ExportEnvelope`, `BackupHeader` and "the envelope" are three different things** (R65), and this
epic touches only the first. `ExportEnvelope` is the disclaimer-bearing value in
`lib/domain/policy/export_envelope.dart` that every writer takes. `BackupHeader` is N22's. "The
envelope" is the whole `.json` file and names no type at all. If a sentence in a task file would read
the same with two of the three swapped, it is wrong.

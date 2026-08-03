# N22 — The JSON backup format

| | |
|---|---|
| **`00-README` §9 step** | 8 (2 of 3) |
| **Ships in** | `v1.0.0` |
| **Depends on** | N21 |
| **Size** | L |
| **Was** | E19a — split from restore, which has a different risk profile |
| **Branch** | `epic/n22-json-backup-format` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

Author `lib/data/backup_format.dart` and `ExportRepository.writeBackup` — the file the product's whole
recovery story rests on. Five things land: the thirteen-key header with `_disclaimer` **first**; a
canonical encoder that makes two exports of the same data byte-identical; every one of the 21
restorable tables, with its four exclusions named in the source; the forward-compatibility contract that
carries an unknown column through `unknown_json` and back out again; an FNV-1a 64 corruption check
described in words that do not over-claim; and file import with the magic bytes validated by us rather
than by a picker's extension filter.

**Not** the restore path. T05 lands 04 §7.2's three **non-destructive** steps — pick, sniff, validate the
header — and stops. The staging database, the import transaction, the sentinel, the swap, the two-step
confirmation, the sweeps and `tool/seed.dart` are all N23. `lib/data/restore_service.dart` is created
here holding one top-level function and no class; N23-T01 adds the class beneath it.
`00-PLAN-CRITIQUE.md` split E19 for one reason: *"two different risk profiles in one PR: a format
(reviewable) and the app's most destructive code path (not)."* A reviewer reading this branch is reading
an encoder and a parser. That is a job a person can actually do.

## Release scope — P15

**`v1.0.0`, whole — and the format must be whole with it.**

**All 21 restorable tables are serialised, including `reminders` and `reminder_rules`, which no
`v1.0.0` screen reads and which will be empty.** They are in the envelope, in the header's table list
and in the canonical encoder's ordering exactly as if the screens existed.

This is the single load-bearing constraint of the whole release split, and the reason is T03's own
asymmetry: **the forward-compatibility contract carries an unknown *column* through `unknown_json`; it
does not carry an unknown *table*.** A `v1.0.0` backup written without `reminders` and restored into
`v1.1.0` would be a restore that has to invent a missing table — on the one code path where a bug
loses five seasons, discovered by a shepherd, in June, on a new phone.

Ship the format whole and there is no format change between the two releases at all: a backup written
by `v1.0.0` restores into `v1.1.0` byte-for-byte unchanged, and N23-T07's export→import→export
equality property holds **across** the boundary rather than up to it.

## Why the epic sits here

`00-README` §9 puts export, backup and restore at **step 8**, and states the reason rather than leaving
it to be re-derived:

> *"Restore must exist before the seed script can route through it, and the seed script is what makes
> 400-ewe profiling, the overflow matrix, the goldens and the at-cap monetization tests possible at
> all. It also turns the seed into a continuous test of the one code path where a bug loses five
> seasons."*

Three consequences bind this epic's scope:

- It comes **after** N07's freeze because the format serialises the schema. `unknown_json` on all 21
  restorable tables is **N07-T06**, not this epic — 09 §1.3 is explicit that until that column exists
  *"the forward-compatibility rule is inert: a column from a newer backup has nowhere to go and is
  dropped silently."* N22 consumes that column; it does not create it.
- It comes **after** N21 because `ExportRepository`, `ExportEnvelope`, `ShareService` and the
  `getTemporaryDirectory()` seam are N21-T06 and N21-T07. `writeBackup` is a fourth verb on a repository
  that already exists. T01's precise predecessor is **N21-T08**, the last commit of that epic — the
  end-of-day export banner — because it is the commit after which `main` is green with the whole export
  surface merged.
- It comes **before** N23 because `restoreInto` reads what this epic writes. The round-trip equality
  property (N23-T07) is stated over the `tables` value **this** epic defines, and it cannot be written
  until the canonical encoding is settled.

Also from §9, and it applies from the first string in this epic rather than in a later sweep: **the
ARB**. Every refusal sentence in T03, T04 and T05 goes through `lib/l10n/app_en.arb` with a
`description`, and the regenerated `lib/l10n/app_localizations*.dart` is committed in the same commit.
N33 only verifies.

## What is observably true when this epic merges

Run these on the merged `main` and watch them pass — this is the demo:

```bash
fvm flutter test test/features/backup_format_test.dart
fvm flutter test test/features/backup_forward_compat_test.dart
fvm flutter test test/features/backup_import_test.dart
fvm flutter test test/policy/offline_wording_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check && make test
```

- **Two exports of the same database are byte-identical over `tables`.** Not "equivalent", not "the same
  rows" — the same bytes, and therefore the same `checksum.value`. This is the property N23-T07 turns
  into the round trip; without byte equality it can only be an approximate comparison, and an
  approximate comparison of a backup is worth nothing.
- **`_disclaimer` is the first key in the file.** Open any backup in a text editor and the first thing
  you read is that this is a personal notebook and not a statutory medicine record. `tables` is the last
  key, which is what lets the writer stream it without buffering it twice.
- **`writeBackup` emits 21 table keys, always, zeros included** — derived from the registered table list
  minus four named exclusions, never from a typed list. `vocab_terms` is one of the 21: a shepherd who
  renamed *ewe* to *gimmer* and added a death cause gets both back.
- **A column a newer build wrote survives a round trip through an older one.** It lands in
  `unknown_json` on import and comes back out at the row's top level on the next export — merged
  *before* the keys are sorted, with the container itself never emitted under its own name.
- **A backup written by a higher `formatVersion` or a higher `schema` is refused**, in one sentence a
  shepherd can act on, with the numbers it found and the numbers it can read carried on the failure and
  into the diagnostics log.
- **A renamed JPEG is refused before any parse begins.** So is a ZIP, so is a `VACUUM INTO` diagnostics
  copy of the database — each by name, each with the reason.
- **The words *verified* and *secure* appear nowhere near the checksum**, in `lib/`, in `assets/` or in
  `lib/l10n/app_en.arb`. `test/policy/offline_wording_test.dart` holds it, in the same file and against
  the same `const` banned-phrase list N02-T02 authored.
- **No `double` appears anywhere in the encoded body**, and no base64. A backup nobody can read in a
  text editor is a backup nobody can salvage by hand at 2am.

What is deliberately **not** demonstrable yet: the export → import → export equality property. It needs
`restoreInto`, which is N23-T06. This epic proves the *write* half — two exports of one database — and
N23 closes the loop. Say so in the PR body rather than implying the round trip is done.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/09-export-formats.md` | §1.1–§1.3 (the six artifacts, the files this adds, the nine sibling edits) · §5.1–§5.7 (the envelope top to bottom, the two key conventions, what is in and out, forward compatibility, surviving a migration, the checksum and how the file is written) · §7.1–§7.2 (the round-trip property and the thirteen things that must be true for it) · §8.1 (delivery and the file name) · §9 (the anti-patterns and their gate rows) | **the owning document.** Every key, every rule, every gate row |
| `docs/engineering/04-migrations-media-backup-restore.md` | §6.1–§6.9 (what the backup is, the header, the field rules, in and out, forward compatibility, integrity, `importDefaults`, size, the anti-pattern table) · §7.2 steps 1–3 (pick, sniff, validate) · §7.4 (the failure modes and their wording) | the header's own document, and the import steps this epic lands |
| `docs/engineering/08-platform-integration.md` | §6 (`file_selector` 1.1.0, the one call site, `XTypeGroup`, why the MIME filter is not trusted) · §1's `layer.plugin_file_selector` row | the picker seam and its single-call-site rule |
| `docs/engineering/CONVENTIONS.md` | §1 (the tree) · §1.1 layer rules 3, 4, 8 · §2.5 (`ShedFailure`) · §2.8 (`BackupHeader`, `kSchemaVersion`, `AppDatabase`) · §2.13 (`ExportRepository` writes nothing) · §2.14 (`Disclaimers`) · §4.1–§4.2, §4.7 · §5.2–§5.3 (the vocabulary and the banned words) · R18, R20, R52, R65 | **BINDING** on every path, type, provider and word |
| `docs/engineering/03-data-model-and-schema.md` | §5 (every column of every table the writer reads) · §5.12 (`vocab_terms.key` is stable forever) · §5.13 (`ewe_summaries` is a rebuildable cache) | which columns exist and what each one means |
| `docs/engineering/12-testing.md` | §10.5 (provenance across a restore) · §10.6 (the equality property and the header trap) · §11 (`dart_test.yaml`, the `uk-zone` leg) | where the tests live and how the zone leg runs |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #29, #32, #56, #62, #73, #81, #84, #85, #86, #88, #118, #125 | `file_selector` **1.1.0**; `crypto` is **not** a direct dependency and may not be reached for |
| `CLAUDE.md` | the offline-purity section · the banned-words list | *"verified"* and *"secure"* about the backup checksum are banned outright |
| `epics/00-PLAN-CRITIQUE.md` | the E19 split · §11.3 (N22-T03's anchor) · §11.4 (skills per epic) | why this epic exists apart from N23 |

## Tasks

Strictly sequential. Each task depends on the one before it, because `writeBackup` cannot emit a table
before the encoder exists, forward compatibility cannot round-trip a table that is not emitted, the
checksum covers the canonical bytes those tables produce, and the importer validates the header the
first four tasks defined.

| Task | Depends on | One line |
|---|---|---|
| [N22-T01](N22-T01-backup-formatdart-backupheader-and-the-canonical-encoder.md) | N21, merged | `backup_format.dart` — `BackupHeader` and the canonical encoder |
| [N22-T02](N22-T02-writebackup-every-restorable-table-four-exclusions-named.md) | N22-T01 | `writeBackup` — every restorable table, four exclusions named |
| [N22-T03](N22-T03-forward-compatibility-unknown-json-round-trips.md) | N22-T02 | Forward compatibility — `unknown_json` round-trips |
| [N22-T04](N22-T04-the-checksum-described-without-the-words-verified-or-secure.md) | N22-T03 | The checksum, described without the words *verified* or *secure* |
| [N22-T05](N22-T05-file-import-through-file-selector-with-the-magic-bytes-valid.md) | N22-T04 | File import through `file_selector`, with the magic bytes validated by us |

T01 and T04 are two halves of one file and they are deliberately not one commit: T01 lands the encoder
and the header, T04 lands the arithmetic that runs over the encoder's output and the wording that
describes it honestly. Splitting them is what makes the wording reviewable on its own, which is the
whole point of a §12.3 string.

## The PR workflow, concretely

**1 — Cut the branch from merged `main`.** N21 is merged and `main` is green before this starts.

```bash
git checkout main && git pull --ff-only
fvm flutter --version          # must print 3.44.8; .fvmrc is the pin
git checkout -b epic/n22-json-backup-format
```

**2 — One commit per task, five commits, in task order.** Each task file names its commit line verbatim;
use it. Before every commit, in this order: **`/simplify`**, then **`/code-review`**, then
**`/shed-code-review`**, then commit. Every finding is resolved before the commit, not after.

Three commits in this epic carry an extra obligation. **T03, T04 and T05 each add strings to
`lib/l10n/app_en.arb`**, and gen-l10n's output under `lib/l10n/app_localizations*.dart` is committed
(`00-README` §7.1). Regenerate and commit it in the **same** commit as the ARB edit, or the `codegen`
job fails on a diff nobody can see locally.

Run the gates locally before each commit, cheapest-failure-first:

```bash
make check        # check_policy.dart → dart format --set-exit-if-changed → analyze --fatal-infos
make test         # -P ci-fast, randomised order, + TZ=Europe/London --tags uk-zone
```

**3 — Before the PR opens, run `/shed-code-review` once more over the whole branch**, reading the diff in
`00-README` §10's irreversibility order. For this branch that order is: `lib/data/backup_format.dart` and
`lib/data/export_limits.dart` first — *"any new export format"* is on §10's never-waved-through list —
then `lib/data/import_defaults.dart`, then `lib/data/export_repository.dart` and
`lib/data/restore_service.dart`, then `lib/l10n/app_en.arb`, then
`lib/features/settings/restore_flow.dart`, then the tests. Generated l10n output is waved through; read
it only to confirm nobody hand-edited it.

**4 — Open the PR and answer the five §12 questions** in `.github/pull_request_template.md` **verbatim,
in the PR body**. Three of the five genuinely land here and must be answered with what holds them, not
with "n/a":

- **§12.3** — `_disclaimer` is the first key of every backup and `Disclaimers.exportFooter` is
  *referenced*, never re-typed. The single-definition test counts one literal in the codebase.
- **§12.1** — a treatment with no `treatment_withdrawals` row exports **no** withdrawal row. The absence
  is the answer; an import default here would be the one place §12.1 could be defeated (09 §5.6).
- **§12.5** — `occurred_at`, `captured_at`, `original_effective` and `time_source` travel as a unit or
  not at all. A backup that drops the quad launders an edited timestamp into an auto-captured one: a
  §12.5 violation committed by the file format.

**5 — Wait for the pipelines.** Three jobs run for this epic and each proves a different thing.

| Job | What it runs | What it proves for **this** epic |
|---|---|---|
| `gate` | toolchain pin vs `.fvmrc` · `flutter pub get` · `dart tool/check_policy.dart` (**G2 + G3**) · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` · the `NSAppTransportSecurity` grep | The access-control story for the format, mechanically: `copy.base64_backup` (no base64 in the backup), `copy.disclaimer_retyped` (the §12.3 string is referenced), `export.intl_in_writer` (no `package:intl` in `backup_format.dart` — a locale decimal comma would shift the file), `layer.plugin_file_selector` (the picker is reached from exactly one file), `layer.data_no_material` and `layer.single_writer`. **G2 matters more here than anywhere else in the backlog:** the obvious way to build a checksum is `package:crypto`, which sits in the lockfile because `pdf` declares it and is **not** a direct dependency. Reaching for it turns a transitive edge into a load-bearing one without an audit |
| `codegen` | `build_runner build --delete-conflicting-outputs` + `drift_dev make-migrations` + `git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/` | Two things. A **negative**: N22 adds no table and no column, so `drift_schemas/` must not move and no new snapshot may appear. If this job reports a schema diff on this branch, something has quietly added a column to make the format easier — stop, because the freeze is N07's and it is irreversible. And a **positive**: the diff covers `lib/`, which is where gen-l10n writes, so a stale `app_localizations.dart` beside an edited ARB is caught here rather than at N33 |
| `test` | `flutter test -P ci-fast` randomised · `TZ=Europe/London --tags uk-zone` over the whole suite · `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone` · the coverage artefact (reported, **never** gated) | The four test files this epic writes. The **`uk-zone` leg is load-bearing here and not ceremonial**: `exportedAtOffsetMinutes` and `exportedAtZoneAbbreviation` are derived from the device's own offset at the export instant, and the ambiguous 01:00–01:59 hour is the one hour where two different instants render the same local time under two different offsets. An untagged case runs under the runner's zone, which is UTC, and proves nothing about either field |

`android` also runs on every PR (`13 §4.2`), builds the release AAB and asserts **G1**. N22 changes no
native file and no permission — `file_selector` merges none on either platform, which is why it was
chosen over `file_picker` — so it proves nothing this epic authored, but it must stay green. If it goes
red here, look at a dependency, not at the encoder.

Goldens do **not** run on this PR: the `goldens` job is `v*` or `workflow_dispatch` only.

**6 — Merge, delete the branch, and only then cut N23.**

```bash
gh pr merge --squash --delete-branch        # or the repo's configured strategy
git checkout main && git pull --ff-only
# confirm main is green, then:
git checkout -b epic/n23-restore-and-seed
```

N23-T07 asserts byte equality over the `tables` value **this** epic defines. Cutting it from anything
other than a green merged `main` means writing the round-trip property against an encoder that is still
moving underneath it.

## Risks, and what is irreversible

**Irreversible in this epic — say it out loud in the PR body:**

- **The file format itself.** The moment a shepherd exports, a file exists that some future build must
  still be able to read. `formatVersion` is a compatibility promise to every phone that ever wrote one,
  and it is deliberately independent of `schema` — conflating them is what makes a format unfixable
  later (09 §5.2). The canonical key order, the `_uid` foreign-key rule, the vocabulary-key exception,
  the five `uid`-less tables' natural keys and the "every column emitted, `null` included" rule are all
  part of that promise, not implementation detail.
- **The checksum algorithm and its published name.** `"algorithm": "fnv1a64"` is written into every
  file. Changing it later means either two readers or a `formatVersion` bump.
- **Nothing else.** No schema, no migration step, no native file, no store artefact, no `[exempt]` line.
  **If a file under `drift_schemas/`, `lib/core/db/`, `android/` or `ios/` shows up in this branch, stop
  and find out why.**

**Risks specific to N22:**

| Risk | Why it bites here | What holds it |
|---|---|---|
| **`crypto` is one import away and is in the lockfile** | `pdf` declares it, so the import resolves and the build is green. Decision-record §5.1 does not list it as a direct dependency, and G2's transitive allowlist *"records what is in the graph, and it is not a licence to import from it"* (09 §5.7) | T04 writes about fifteen lines of FNV-1a instead. `make check` runs G2 on every push |
| **FNV-1a's offset basis does not fit a Dart `int` literal** | `14695981039346656037` is above `2^63 − 1` and is a compile error written as a decimal literal. Written as `0xcbf29ce484222325` it compiles to the correct 64-bit pattern | T04's gotchas, plus a test over the FNV reference vectors |
| **Ordering by an integer foreign key instead of the parent's `uid`** | `ORDER BY ewe` compiles, runs, and produces a stable order on the exporting phone. After a restore the integer ids are re-issued, so the second export is a *permutation* of the first and byte equality fails somewhere in the middle of a 40,000-row file | T02 orders every table by `uid`, and the five `uid`-less tables by the natural keys 09 §5.3 names — resolved to the parent's `uid`, never to the local integer |
| **`unknown_json` emitted under its own name** | It reads like a column, so emitting it is the obvious thing. Every preserved field is then written twice — once splatted at the top level, once as a JSON string inside the container — and the *second* export nests it again | T03; the round-trip test fails on the second export, which is why N23-T07 exists |
| **The picker's filter looks like validation** | `XTypeGroup(extensions: ['json'])` reads like a guarantee. On Android the MIME type is a suggestion some providers report as `application/octet-stream`; on iOS the uniform type identifier is a document type nobody honours | T05 validates the first bytes ourselves, before any parse and before anything is touched |
| **`readAsBytes()` on the picked file** | The one-line way to sniff the magic bytes, and it loads whatever the shepherd picked — including a 4 GB video selected by mistake at 2am — into memory before deciding it is wrong | T05 reads 512 bytes through a `RandomAccessFile` and streams the copy |
| **Encoding `tables` twice** | The obvious implementation: once for the checksum, once for the file. It doubles peak heap on the largest artefact the app produces, at exactly the moment the shepherd is trying to protect their data — and it is how the two can silently diverge | 09 §5.7's writer encodes once; T01 lands that shape and T04 hashes its output |
| **A `double` sneaks into the body** | One `double` and canonical encoding has its hardest problem back, and the checksum starts flapping across platforms. Mass is integer grams and temperature integer milli-°C precisely so this cannot happen | T02's test walks the decoded body and fails on any `double` |
| **The header is "tidied" into the checksum** | It looks inconsistent that twelve keys are hand-ordered and one value is canonically sorted. It is not: the header carries `exportedAtUtc`, so it legitimately differs between two exports of the same database, and covering it would make the checksum non-reproducible by design | T01 and T04 state it in the code beside the assertion |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] `lib/data/backup_format.dart` and `lib/data/export_limits.dart` exist at the paths `09 §1.2` gives them; `lib/data/` stays flat (R18)
- [ ] the header has the thirteen keys of `09 §5.2` in that order, `_disclaimer` first and `tables` last
- [ ] `writeBackup` emits **21** table keys and **21** `counts` entries, zeros included, derived from the registered table list minus four named exclusions
- [ ] `entitlements`, `ewe_summaries`, `search_docs` and `search_fts` are absent from the file, each with its reason written beside the exclusion in the source
- [ ] no base64, no `double`, no integer primary key and no `unknown_json` key appears anywhere in the body
- [ ] a higher `formatVersion` or a higher `schema` is refused; a lower `schema` is accepted
- [ ] the words *verified*, *secure* and *authentic* appear nowhere near the checksum in `lib/`, `assets/` or `lib/l10n/app_en.arb`
- [ ] `package:crypto` is imported nowhere under `lib/`, and `pubspec.yaml` gains no dependency
- [ ] `package:file_selector` is imported by exactly one file, `lib/features/settings/restore_flow.dart`
- [ ] every string added to `lib/l10n/app_en.arb` has a `description`, and the regenerated `lib/l10n/app_localizations*.dart` is committed in the same commit
- [ ] the diff contains no file under `drift_schemas/`, `lib/core/db/`, `android/` or `ios/`
- [ ] `pubspec.lock` is unchanged

## Demoable on merge

A backup round-trips `unknown_json` untouched, and a backup written by a higher schema is
refused in words a shepherd can act on.

## Notes

**The four exclusions, and the arithmetic behind 21.** `lib/data/models.dart` re-exports 23 row classes
(R20). Two are excluded — `entitlements` (never exported, ignored on import, decision #88) and
`ewe_summaries` (a rebuildable cache whose `rebuilt_at` would break byte equality immediately) — leaving
21. `search_docs` and `search_fts` are the other two exclusions and are not row classes at all: they are
derived, they get no `unknown_json` (N07-T07), and exporting them would double-index on restore. That is
the four. 04 §6.4 as published names only three, and its illustrative `tables` block omits
`vocab_terms`; 09 §1.3 corrects both, and `vocab_terms` is the twenty-first table.

**N23-T07's anchor is not this epic's to write.** `test/policy/backup_round_trips_test.dart` needs
`restoreInto` and `freshSupportDir()`, which are N23-T06. What N22 proves is the export half —
`writeBackup` twice over one database — and that is a strictly weaker claim. Do not name the round trip
as done in this PR body.

# N21-T07 — `ExportRepository`, `exportCountsProvider` and the Export screen

| | |
|---|---|
| **Epic** | [N21 — Export: CSV, PDF and share](epic.md) · `00-README` §9 step 8 (1 of 3) |
| **Task** | 7 of 8 |
| **Depends on** | N21-T06 |
| **Commit** | one commit · `feat(export): the repository, the counts and the Export screen` |

## 1. Why this task exists

`ExportRepository` does **read and artefact assembly only** — it writes nothing, per
`CONVENTIONS §2.13`, which is why `SettingsRepository` came forward to N12. The screen's wording is
honest about what an export is and is not: a notebook's contents, not a compliance record, and the only
backup the shepherd has.

It is also the screen with **no over-cap state at all**. 07 §13.2's over-cap row for this screen
reads, in full, *"nothing"* — export is never gated by the free tier, in any state (#86). Paywalling
the only backup mechanism in an app with no cloud is a data-hostage pattern, and the widget test that
holds it is written here.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§13.1** (`exportCountsQuery` — one `customSelect`, and its `readsFrom` set) · **§13.2** (the eight states, row by row, incl. the frame-1 shape and the over-cap row that reads *"nothing"*) · **§13.3** (seven actions, one tap each, and what each produces) · **§13.4** (§12.3 verbatim above the buttons; §12.1 on two rows; the §12.5 line; the two backup-honesty sentences; and the permanently banned sentence) · §1.2 (the one-query rule) · §1.5 (the §12 disclosure matrix) · §1.7 (headings and semantics) | the screen, state by state and string by string |
| `docs/engineering/09-export-formats.md` | **§1.1** (the six artefacts and their share names) · **§1.2** (`ExportArtifact` and `ExportCounts`, both typedefs printed) · **§1.3** (the sibling edit: `07 §13.1`'s `readsFrom` gains `mediaAssets`) · **§3.4** (where the vocabulary labels come from, and the three-step ownership) · **§4.4** (the font is loaded on the main isolate by the write controller) · **§8.1** (the share call, `sharePositionOrigin` from the tapped row) · §8.2 (printing) · §8.4 (media as a separate share, batched at 50) | the repository's surface and the screen's plumbing |
| `docs/engineering/CONVENTIONS.md` | **§2.13** (`ExportRepository` owns *"nothing — read + artefact assembly only"*) · §3.1 (`exportRepositoryProvider`, `shareServiceProvider`, `mediaStoreProvider`, `unitsProvider`, `terminologyProvider`) · **§3.2** (`exportCountsProvider` — `StreamProvider<ExportCounts>`, in `export_controller.dart`, **autoDispose**) · §3.4 (`exportControllerProvider`, `exportWriteControllerProvider`) · §4.1 (the four file names a feature folder holds) · **§4.4** (a controller holds no `BuildContext`, never formats for display) · §4.5 (widget keys `<screen>.<element>`) · §4.7 (`ui.spinner`, `db.save_verb`, `layer.path_provider`) · R33 (ids cross boundaries), R60, R68 | **BINDING** on every provider, file and key |
| `docs/engineering/08-platform-integration.md` | §1.2 (`_confinedPackages` — `package:path_provider` is permitted in **two** files and neither is this feature) · §5 (`ShareService.shareFiles`'s signature and the `origin` rule) | the temp-directory problem in §5.3 |
| `docs/engineering/12-testing.md` | §5.1 (`pumpApp`) · **§6.1–§6.2** (`kPumpableVariants` — the export route joins it here) · §7.4 (the semantics and tap-target sweeps that iterate the same table) · §11.1 | the harness edit and the tests that inherit it |
| `docs/design/indelible.md` | **screen 11** (six word buttons with the shape stated beneath each; the honest status line `LAST EXPORTED 3 DAYS AGO · 41 ENTRIES SINCE`; `A LOST PHONE IS LOST DATA. THERE IS NO CLOUD COPY.` in full ink and not as a dismissible tip; the printed footer) | the screen's layout and its voice |
| `docs/engineering/11-monetization-and-store.md` | §12.1 (`ui.monetization_surface`) · §12.2 (`test/features/no_monetization_test.dart`) | why this screen has no over-cap state and how that is proved |
| `docs/research/00-tech-decisions.md` | **#86** (export is never gated by the free tier, ever) · #85 (media is a separate share) · #61 (`label ?? default`) · #124 (never the exception message) · #125 | the decisions the screen applies |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-screens-and-routing` | the route, the eight states and the ordered file list for adding a screen |
| `indelible-page-and-screens` | screen 11's layout: word buttons, the shape line beneath each, the printed footer |

This is the pair `CLAUDE.md` names for *add or change a screen*, in that order, and it is the whole
budget. Three more skills own parts of this diff and none of them is reloaded: `exportCountsProvider`,
the two controllers and the one-query rule are printed in §5.2 with the provider spellings 2.6.1
accepts; the repository's read-only shape is §5.1's; and the screen's wording — which carries §12.3
and the offline paragraph — is quoted verbatim in §5.2 from `Disclaimers`, never re-typed.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/export_test.dart`
- **Test** — `'ExportRepository performs no write and the screen states what an export is not'`
- **Why it is red today** — there is no Export screen and no counts to render.

```bash
fvm flutter test test/features/export_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. It has two halves and they fail for different
reasons. **Half one:** read `lib/data/export_repository.dart` and assert it contains no
`transaction(`, no `.into(`, no `.update(`, no `.delete(`, and no identifier matching `save\w*\(` —
`CONVENTIONS §2.13`'s *"nothing"* made mechanical, and the same property `db.save_verb` gates.
**Half two:** pump `ExportScreen` and assert the rendered text contains `Disclaimers.exportFooter`
read **through the constant**, and does **not** contain the strings `compliance record`,
`official record` or `your data never leaves your phone`. Half one catches a repository that grew a
write; half two catches a screen that got tidier and less honest.

**Green.** The minimum code that passes, and nothing beyond it — the repository, the counts provider, the screen, and its ARB strings authored here.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No schema step (**this task stores nothing**). Everything else: data → wiring → controllers → UI →
routing → ARB → tests, in that order.

| # | Path | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/export_repository.dart` | **Edit.** `ExportArtifact`, the artefact-assembly methods that write each of the five files into the supplied directory and return a path/name/size record, and the counts query. Still no write to the database |
| 2 | `lib/data/providers.dart` | **Confirm.** `exportRepositoryProvider` is `FutureProvider<ExportRepository>`, keepAlive, derived from `databaseProvider` — `CONVENTIONS §3.1` already declares it; this is the task where it acquires a class |
| 3 | `lib/features/export/export_controller.dart` | **New.** `typedef ExportCounts`, `exportCountsProvider` (`StreamProvider<ExportCounts>`, **autoDispose** — §3.2) and `ExportController` + `exportControllerProvider` for screen state (which row is building, and the split message's file count) |
| 4 | `lib/features/export/export_write_controller.dart` | **New.** `ExportWriteController extends WriteController`. Every artefact tap goes through `guard()`, which refuses to run concurrently — that is the double-tap defence. **This is the app's one `rootBundle.load` call site for the PDF font** (09 §4.4 step 2), and the place that resolves `vocabLabels` is *not* here (see §5.3) |
| 5 | `lib/features/export/export_screen.dart` | **New.** Seven fixed-height rows, the honest status line, the §12 copy above the buttons, and the `sharePositionOrigin` computed from the tapped row's `RenderBox` |
| 6 | `lib/routing/routes.dart` | **Edit.** `RouteNames.export` and `Routes.export(context)`. `02 §8.1` fixes the count at 13 names and 12 push helpers — this is one of them, and the matrix self-check asserts the 13 |
| 7 | `lib/l10n/app_en.arb` | **Edit.** Every user-facing string on this screen, each with a `description`. **Authored here — there is no later sweep; N33 only verifies** |
| 8 | `test/support/harness.dart` | **Edit.** `kPumpableVariants` gains `RouteNames.export: () => const ExportScreen()`. Four test files iterate that map and inherit the coverage for free |
| 9 | `test/features/export_test.dart` | **New. The anchor, written first.** |
| 10 | `test/features/no_monetization_test.dart` | **Edit.** The Export screen at `unlocked: false, ewesInCurrentSeason: 99` and `seasonCount: 2` renders **nothing** monetization-shaped and every button stays live |
| 11 | `tool/check_policy.dart` | **Edit, only if §5.3's ruling needs it.** If the temp directory is reached by widening `layer.path_provider`'s permitted-file set, the row and its proving case change in this commit |

### 5.2 The signatures

`09 §1.2` prints both typedefs; `CONVENTIONS §3.2` fixes the provider.

```dart
// lib/data/export_repository.dart
typedef ExportArtifact = ({String path, String shareName, int byteSize});

// lib/features/export/export_controller.dart
typedef ExportCounts = ({
  int ewes, int lambs, int treatments,
  int mediaAssets, int mediaBytes,
  Instant? lastExportedAt,
});

/// One drift statement, autoDispose (CONVENTIONS §3.2).
/// readsFrom: {lambs, ewes, treatments, appSettings, mediaAssets}
///                                                   ^^^^^^^^^^^^
/// 09 §1.3's sibling edit to 07 §13.1: ExportCounts carries mediaAssets and
/// mediaBytes for §8.4's "Share photos from this season" row, and without the
/// table in readsFrom the row renders a stale count until an unrelated write
/// happens to invalidate the stream.
final exportCountsProvider = StreamProvider.autoDispose<ExportCounts>(…);
```

**The seven rows** (07 §13.3), each one tap, each 72 pt, each with its shape stated beneath it in
Indelible's record face:

| Row | Widget key | Produces |
|---|---|---|
| `CSV — ONE ROW PER LAMB` | `export.lambs_csv` | `shed-book-2026-lambs.csv` |
| `CSV — ONE ROW PER EWE` | `export.ewes_csv` | `shed-book-2026-ewes.csv` |
| `CSV — ONE ROW PER TREATMENT` | `export.treatments_csv` | `shed-book-2026-treatments.csv` |
| `PDF — FLOCK BOOK 2026` | `export.flock_book_pdf` | two volumes, split further at the cap |
| `PDF — MEDICINE RECORD` | `export.medicine_record_pdf` | the one somebody hands to a vet |
| `JSON — FULL BACKUP` | `export.backup_json` | **N22.** Render the row disabled-with-a-reason or omit it in this commit, and say which in the commit message |
| `SHARE PHOTOS FROM THIS SEASON` | `export.media_share` | the files straight to the sheet, batched at 50, labelled a copy-out and not a restorable backup |

### 5.3 The details that are easy to get wrong

- **`getTemporaryDirectory()` cannot be called from this feature, and you will find out at
  `make check` unless you rule it first.** `08 §1.2`'s `_confinedPackages` permits
  `package:path_provider/` in **exactly two files** — `lib/data/media_store.dart` and
  `lib/core/db/connection.dart` — under `layer.path_provider`. `export_repository.dart` is neither,
  and neither is a controller. Two honest options, on N11-T09's precedent (*"`local_log.dart` may not
  import `package:path_provider`, and that is why `attachTo` takes a `Directory`"*):
  1. **The directory is passed in — recommended.** `MediaStore` gains a
     `Future<Directory> exportScratch()` returning `getTemporaryDirectory()`, and
     `ExportRepository`'s assembly methods take a `Directory outputDir`. `mediaStoreProvider` is
     already in the graph, keepAlive, so the wiring is one `ref.read`. No rule changes, no allowlist
     grows, and the seam that owns "where files live" keeps owning it.
  2. **Widen `layer.path_provider` to a third file.** Legal, and it costs a rule edit, a
     `firesOn` update and a line in the PR body explaining why a second temp-root answer is
     acceptable. `04 §7.5`'s reason for the rule — *"two roots means two answers"* — is the argument
     against.

  **Whichever it is, it is decided before the code is written and recorded in the commit message.**
  Discovering it after the screen is built means rewriting the repository's whole signature set.
- **`ExportRepository` writes nothing, and "nothing" includes the obvious exception.** Not
  `last_exported_at` — that is `SettingsRepository`'s (N12-T02), stamped by the **write controller**
  after the share result, per `08 §11` / `09 §8.3`: on `completed` **and** `unknown`, never on
  `dismissed`, never before the sheet opens, in its own single-statement transaction. This is
  critique defect **S6** and it is the reason that repository exists nine epics early.
- **The vocabulary labels are resolved by the screen, and this is a layer rule with two teeth.**
  `lib/data/` cannot reach `AppLocalizations` (layer rule 4 keeps Flutter's widget layer out and
  there is no `BuildContext` down there); a controller cannot either (`CONVENTIONS §4.4` rule 3 — a
  controller holds no `BuildContext`). So: the **screen** builds `Map<String, String> vocabLabels` by
  walking `vocab_terms` and taking `label ?? <the ARB message for that key>` (#61), passes it into
  `ExportWriteController`, which passes it into `ExportRepository`, which treats it as opaque data
  and never asks where a label came from. A repository — or a controller — reaching for a
  localisation is a layer violation **and** a lie about where terminology lives.
- **`readsFrom` must include `mediaAssets`.** `07 §13.1` lists four tables; `09 §1.3` amends it to
  five, because `ExportCounts` carries `mediaAssets` and `mediaBytes` for the media row. Get this
  wrong and the photo count is stale until an unrelated write happens to invalidate the stream —
  which is the worst kind of wrong, because it is right most of the time.
- **One `customSelect`, not four counts fanned in from Dart.** `07 §1.2`'s one-query rule, and
  `00-README` §8 step 14: *"`combineLatest` over drift streams is a build-breaking defect — fan-in
  happens in SQL."* drift's open issue #3338 (torn `combineLatest`) is why.
- **The counts are read, never estimated.** No `LIMIT`, no sampling, no "about 400". A count the user
  can compare against their own flock list is a count that has to be right.
- **Frame 1 paints seven fixed-height rows with their labels and blank counts.** The labels are
  static and never wait. Nothing shifts when the row lands, and there is **no spinner** —
  `ui.spinner` bans `CircularProgressIndicator` under `lib/features/`. The building state is
  **determinate progress on the row**; the screen never blocks and never covers itself with a modal.
- **The failure state is a persistent SnackBar naming the artefact, and it goes through
  `showFailure`.** `lib/core/ui/feedback.dart` is the **one** file permitted to call `showSnackBar(`
  (R30). Never the exception message (#124) — name the artefact and offer Diagnostics. There is no
  *receipt* on this screen, because nothing was committed: the receipt is for a write, and this
  screen has none.
- **Over-cap is not a state.** #86: export is never gated by the free tier, in any state — not the
  CSVs, not the PDFs, not the backup, not over the ewe cap, not in season two. Every button stays
  live in the empty state too, because a 0-row CSV still carries its disclaimer trailer.
- **`sharePositionOrigin` comes from the tapped row, in the screen.** `final box =
  context.findRenderObject()! as RenderBox; box.localToGlobal(Offset.zero) & box.size;` The screen is
  the only layer with a `RenderBox`, which is why `ShareService` makes it a required parameter rather
  than defaulting it.
- **Every mutation-shaped action goes through `WriteController.guard()`** even though nothing is
  written to the database: `guard()` refuses to run concurrently, and that is the double-tap defence
  for a 30-second PDF build as much as for an insert. Two taps on `PDF — FLOCK BOOK 2026` must start
  one build.
- **The ARB is authored here, in full.** Every string gets a `description`; every element gets a
  `semanticLabel` and a `<screen>.<element>` widget key, all `lower_snake`; every heading gets
  `headingLevel:` and **never** `Semantics(header: true)`, which became a no-op on both platforms in
  3.44 and still compiles. No domain noun appears literally in a message — the term is a placeholder
  fed by `terminologyProvider`.
- **The banned sentence is banned as literal text anywhere in `lib/` and `assets/`:** *"your data
  never leaves your phone."* It stops being true the moment they AirDrop a CSV — which is the backup
  story the product depends on. The only permitted public wording is the tier-1 + tier-2 sentence in
  `13-build-ci-release.md`.
- **The screen says what is true about printing.** The PDF goes to the share sheet and printing
  happens from there. It does not say "printable" and leave the user hunting for a button.
- **Media is labelled a copy-out and not a restorable backup**, because there is no media import: a
  restore brings back `media_assets` rows whose files are gone, and those rows render as *"photo
  taken 14 March, file missing"*, which is more honest than silence.
- **Adding the export route to `kPumpableVariants` is what buys the coverage.** Four files iterate
  that map — the overflow matrix, `semantics_gate_test`, `tap_target_test` and `contrast_test`. The
  matrix's self-check still asserts **13 routes and 14 entries**; this commit fills a slot that was
  already counted, so the arithmetic does not move. T08 fills the fourteenth.

### 5.4 The full test set

`test/features/export_test.dart` — widget tests through `pumpApp`, against
`NativeDatabase.memory()`.

| Case | What it asserts |
|---|---|
| `'ExportRepository performs no write and the screen states what an export is not'` | **The anchor**, both halves: the source contains no `transaction(`, `.into(`, `.update(`, `.delete(` or `save\w*\(`; the rendered text contains `Disclaimers.exportFooter` and none of the three banned phrases |
| `'the seven rows render at frame 1 with their labels painted and their counts blank'` | Pump without settling; assert seven rows of the fixed height with non-empty labels and empty count slots. Nothing shifts when the counts land |
| `'the counts equal the rows in the database, exactly'` | Seed 12 ewes, 31 lambs, 4 treatments; assert 12 / 31 / 4. Then insert one more lamb and assert the stream pushes 32 without a manual refresh |
| `'the media count and byte size update when a media_asset is written'` | The `readsFrom` edit, asserted rather than assumed. Without `mediaAssets` in the set this test hangs at the old value, which is the exact production symptom |
| `'the empty state keeps every button live'` | Empty database: *"Nothing recorded yet."* and seven enabled rows |
| `'nothing on this screen is gated at unlocked false, 99 ewes, season 2'` | #86. Every row live, no upgrade row, no cap row, no disabled state. Lives in `no_monetization_test.dart` as well, iterated from the shared variant table |
| `'two taps on one artefact row start exactly one build'` | `tester.tap(); tester.tap();` — `WriteController.guard()`'s refusal, at the one screen where a build takes thirty seconds |
| `'a failed artefact renders a persistent SnackBar naming the artefact and not the exception'` | #124. The artefact name is present; `e.toString()`'s substrings are absent; the Diagnostics action is present |
| `'no CircularProgressIndicator renders in any state'` | `ui.spinner`, at the screen where a long build makes one tempting |
| `'the share call passes a real origin rect and a file path'` | Through `FakeShareService`: `origin` is not `Rect.zero`, the path exists on disk, `fileNameOverrides` matches the table in `09 §1.1` |
| `'the vocabulary labels reach the repository from the screen and nowhere else'` | Source text: `AppLocalizations` appears in no file under `lib/data/`, and `ExportRepository`'s methods take `vocabLabels` as a parameter |
| `'a user-edited vocabulary label appears in the produced CSV'` | End to end: override `vocab_terms.label` for `rt_oral`, produce `treatments.csv`, assert the `route_label` column carries the override while `route_key` still carries `rt_oral` |
| `'every element carries a semanticLabel and a <screen>.<element> key'` | Iterated over the screen's tree. The sweeps in N33 verify; **this is where it is authored** |
| `'every heading carries headingLevel and no Semantics(header: true) exists'` | #104 |
| `'every user-facing string on this screen is an ARB message with a description'` | No literal in the widget tree; every key present in `app_en.arb` with a non-empty `description` |
| `'the screen never says printable and never says your data never leaves your phone'` | 07 §13.4's two copy rules |
| `'the media row is labelled a copy-out and not a backup'` | The word *backup* does not appear on that row; the sentence about missing files does |
| `'export joins kPumpableVariants and the matrix still derives 252'` | The self-check: 13 routes present, `kPumpableVariants.length == 14` |

**Nothing in this task is time-shaped in a way the DST tier can reach.** The one instant the screen
renders — `lastExportedAt`, as *"LAST EXPORTED 3 DAYS AGO"* — is a duration, and its civil-day
arithmetic belongs to **T08**, where the banner's conditions 1 and 3 use it. Do not invent a
`uk-zone` case here to fill the row; add the assertion where the comparison actually happens.

## 6. Constraints that bind this task

- **The five safety rules** — §12.3 (`Disclaimers.exportFooter` verbatim above the buttons, referenced not re-typed), §12.1 (on the treatments and medicine-book rows) and §12.5 (one line: *"Times are exported with their source: recorded automatically, entered by you, or edited by you."*). All three are `07 §13.4`'s and are authored in the ARB in this commit.
- **3am** — every interactive element ≥ 60 × 60 pt with ≥ 16 pt separation, an 18 pt text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider. Seven 72 pt rows, one tap each.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Export is never gated by the free tier, in any state** (#86). This screen has no over-cap rendering, and `07 §13.2`'s row for it reads, in full, *"nothing"*.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. This task adds no dependency.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'ExportRepository performs no write and the screen states what an export is not'` passes, and was seen to fail first for the stated reason
- [ ] `ExportRepository` has no write path at all
- [ ] the counts are read from data, never estimated
- [ ] the §12.3 wording and the offline paragraph are referenced, not re-typed
- [ ] `export` joins `kPumpableVariants`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the temp-directory route is **ruled and recorded** in the commit message — `MediaStore` accessor or a widened `layer.path_provider` — and `make check` is green either way
- [ ] `readsFrom` includes `mediaAssets`, and a test proves the media count is live
- [ ] the screen resolves `vocabLabels`; no file under `lib/data/` names `AppLocalizations`
- [ ] nothing renders differently at `unlocked: false, ewesInCurrentSeason: 99, seasonCount: 2`
- [ ] no `CircularProgressIndicator` under `lib/features/export/`; the building state is determinate and on the row
- [ ] `Rect.zero` is passed at no call site; the origin comes from the tapped row's `RenderBox`
- [ ] every ARB message has a `description`; every element has a `semanticLabel` and a `<screen>.<element>` key; every heading has `headingLevel:`
- [ ] `RouteNames` still declares 13 names and `kPumpableVariants` still has 14 entries

## 8. Verification

```bash
fvm flutter test test/features/export_test.dart
fvm flutter test test/features/no_monetization_test.dart
fvm flutter test test/features/overflow_matrix_test.dart
make check
make test
```

Then the two properties a grep proves faster than a test:

```bash
grep -nE "transaction\(|\.into\(|\.update\(|\.delete\(|save[A-Za-z]*\(" lib/data/export_repository.dart
# expect nothing — CONVENTIONS §2.13

grep -rn "AppLocalizations" lib/data/
# expect nothing — the labels come down from the screen
```

Then run the app and tap all six artefact rows on a real device: each opens the system share sheet,
each produces a file with the name in `09 §1.1`, and the iPad popover is anchored to the row you
tapped and not to the corner of the screen.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(export): the repository, the counts and the Export screen`

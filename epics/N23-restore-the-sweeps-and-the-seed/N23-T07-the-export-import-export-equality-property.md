# N23-T07 — The export → import → export equality property

| | |
|---|---|
| **Epic** | [N23 — Restore, the sweeps and the seed](epic.md) · `00-README` §9 step 8 (3 of 3) |
| **Task** | 7 of 7 |
| **Depends on** | N23-T06 |
| **Commit** | one commit · `test(policy): the export-import-export equality property` |

## 1. Why this task exists

The property that holds the whole format together: export, import into a fresh database,
export again — and the two files are equal. It is the cheapest possible proof that no column is dropped
on either side, and it will catch the next column somebody forgets to add to the writer.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/09-export-formats.md` | **§7.1** (the property, stated over `tables` and nothing else, and why the header is outside the claim) · **§7.2** (the **thirteen** things that must be true for it to hold — the checklist this test mechanises) · **§7.3** (the printed test, `restoreInto`, and *"run it over the two committed fixtures as well as the generator"*) · §5.7 (the checksum covers the `tables` bytes; the writer encodes once) · §5.3 (canonical key order) | what equality means, and over what |
| `docs/engineering/12-testing.md` | **§10.6** (both layers: `glados` for pure values, a hand-rolled seeded generator for the flock; the header trap; *"one file, two owners, no second copy"*; the accessor functions are private to the file) · §11.5 (the fixtures) · §11.2 (`dart_test.yaml`, the tags, and why there is no preset) · §11.6 (flakiness discipline) | where the test lives, what it is tagged, how it is seeded |
| `docs/engineering/04-migrations-media-backup-restore.md` | §7.8 (the round-trip gate) · §6.3 (the field rules) · §6.9 (the anti-pattern table — *"round-trip test: ids differ, `uid`s match"*) · §6.7 (`importDefaults` completeness) | the same property from the format's side |
| `docs/engineering/CONVENTIONS.md` | §2.13 (`ExportRepository`) · §2.14 (`ExportEnvelope`) · **R57** (the test tree) · **R65** (three things, three words: the envelope, `BackupHeader`, `ExportEnvelope`) · §4.1 (a policy test is named for the **property**, not the file) | **BINDING** on the file's name and on what it may call |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · **#118** (`glados` 1.1.7 for pure value round-trips only; a hand-rolled seeded generator for the flock; *"do not extend it"*) · #4 (`test` is banned as a direct dependency, which is why the glados re-check matters) · #32 (`uid` is the identity) · #56 (integers only) · #88 (the entitlement) · #121 (randomised ordering) | the decisions this task applies |
| `epics/00-PLAN-CRITIQUE.md` | §11.3's `N23-T10` row — `test/policy/backup_round_trips_test.dart` · `'export to import to export produces equal tables bytes, equal checksums, re-issued ids and preserved uids'` **`[audit]`** — *"12 §9 owns where it lives and spells it plural; 09 §7.3 owns what it asserts. One file, two owners, no second copy"* | the fuller assertion this task folds in |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-export-and-restore` | the round trip is the format's central property |
| `shed-testing` | the property test and its generator |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/export_round_trip_test.dart`
- **Test** — `'export to import to export produces equal table bytes'`
- **Why it is red today** — nothing proves the round trip; a dropped column would be invisible until a shepherd restored.

```bash
fvm flutter test test/policy/export_round_trip_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion to the critique's fuller form — the anchor name stays, and the extra claims land
as their own cases in the same file so a failure names which half broke:

- **equal table bytes** — `tablesBytesOf(second) == tablesBytesOf(first)`
- **equal checksums** — `headerOf(second).checksum.value == headerOf(first).checksum.value`
- **re-issued ids** — `idsOf(restored) != idsOf(source)`
- **preserved uids** — `uidsOf(restored) == uidsOf(source)`

and print the seed in every `reason:`, because the only useful thing a failure at seed 137 can tell you
is `reproduce with FlockGenerator(137)`.

**Green.** The minimum code that passes, and nothing beyond it — the property over the seeded 400-ewe database, comparing bytes.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 One file, three spellings — rule it here

The same test is named three different ways in three authoritative places:

| Document | Spelling |
|---|---|
| `12 §10.6` | `test/policy/backup_round_trips_test.dart` (plural) |
| `09 §7.3` | `test/policy/backup_round_trip_test.dart` (singular) |
| this epic's anchor | `test/policy/export_round_trip_test.dart` |

**There is one file.** Keep this task's anchor — `test/policy/export_round_trip_test.dart` — because it
is the name the backlog's own TDD anchor carries and because `CONVENTIONS` §4.1 wants a policy test
named for the **property**, which is what *export round trip* is. Fold `12 §10.6`'s two layers into it,
and amend the two documents in the same commit (`00-README` §10's amendment rule): `12 §10.6` and
`09 §7.3` both point at this path afterwards. Note the correction in the commit message.

If a `backup_round_trip*_test.dart` already exists on the branch from N22, **move it** — do not add a
second file. Two files each asserting two thirds of the property is worse than one asserting all of it,
and `12 §10.6` says so: *"one file, two owners, no second copy."*

### 5.2 The files, in `00-README` §8 order

**Nothing under `lib/` changes** — unless the property fails, in which case the fix is in the writer or
the importer and it belongs in that task's file, not bolted on here. Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `pubspec.yaml` | **Edit, only if `glados` is not already a dev dependency.** `glados: 1.1.7`, from decision-record §5.2 and nowhere else. **Run `flutter pub get` and read the resolution before you commit** — glados is the one dev dependency whose transitive graph touches the `analyzer` constraint that governs `drift_dev`. *"If `flutter pub get` reddens, the property layer is deleted, not the pin."* |
| 2 | `test/support/flock_generator.dart` | **Edit, if T04 left anything out.** The same generator the seed uses; ~80 lines; hand-rolled. It must produce every invariant in §5.4's list, because each one is a real importer bug when it is missing |
| 3 | `test/policy/export_round_trip_test.dart` | **New (or moved).** Layer 1 (`glados` over pure values), layer 2 (200 seeded flocks), and the two committed fixtures. `tablesBytesOf`, `headerOf`, `idsOf` and `uidsOf` are **private top-level functions in this file**, never shared helpers — *"they read a format only this file reads, and putting them in `test/support/` would invite a second caller who does not know the header is outside the checksum"* |
| 4 | `test/policy/export_carries_no_row_ids_test.dart` | **New.** The same property from the other side, and its own file *because it fails differently*: a leaked id that happens to survive re-issue passes the round trip and fails this one |
| 5 | `docs/engineering/12-testing.md`, `docs/engineering/09-export-formats.md` | **Edit.** §10.6 and §7.3 point at the ruled path |

### 5.3 The test, following `09 §7.3` and `12 §10.6`

```dart
// test/policy/export_round_trip_test.dart — spec §7.9.
// 09 §7.1 owns what it asserts; 12 §10.6 owns where it lives, how it is seeded
// and that it runs on every push. This file is the only copy.
@Tags(['policy', 'slow'])
library;

void main() {
  final env = ExportEnvelope.standard(now: appNow(), appVersion: '1.0.0');

  // Layer 1 — pure values, with glados's shrinking, which is the reason to keep it.
  Glados(any.recordedTime).test('a RecordedTime survives its JSON round trip', (t) {
    expect(RecordedTime.fromJson(t.toJson()), t);
  });

  // Layer 2 — the whole flock, hand-rolled, seeded, deterministic.
  for (var seed = 0; seed < 200; seed++) {
    test('export to import to export produces equal table bytes (seed $seed)', () async {
      final source = await testDatabase(seedOnCreate: false);
      await FlockGenerator(seed).populate(source);

      final first    = await ExportRepository(source).writeBackup(envelope: env);
      final restored = await restoreInto(freshSupportDir(), File(first.path));
      final second   = await ExportRepository(restored).writeBackup(envelope: env);

      expect(tablesBytesOf(second), tablesBytesOf(first),
          reason: 'reproduce with FlockGenerator($seed)');
      expect(headerOf(second).checksum.value, headerOf(first).checksum.value,
          reason: 'the checksum covers `tables` and must follow it');
      expect(idsOf(restored), isNot(idsOf(source)));   // 09 §7.2 items 3 and 12
      expect(uidsOf(restored), uidsOf(source));
    });
  }

  // And over the two committed fixtures, which the generator does not produce
  // and which four later epics depend on (09 §7.3's closing line).
  for (final name in const ['flock_400_3seasons.json', 'flock_15_at_cap.json']) { … }
}
```

### 5.4 The details that are easy to get wrong

- **The property is over `tables`, and only `tables`.** The header carries `exportedAtUtc`, so whole-file
  byte equality is impossible **by construction**. `12 §10.6` calls this *"the header trap"*, and the
  first instinct — compare the two files — fails on the first run for a reason that has nothing to do
  with the format. Do not "fix" it by zeroing the timestamp.
- **Both exports come from the same app version.** A cross-version claim is not made and would not be
  true — `09 §5.5` exists precisely because it is not.
- **`ORDER BY uid`, never `ORDER BY id`.** Integer ids are re-issued on import, so id-ordering makes the
  second export a *permutation* of the first and the bytes differ with no column having been lost. The
  five uid-less tables order by their natural keys: `ewe_touches` by `ewe_uid`,
  `pen_occupancy_lambs` by `occupancy_uid` then `lamb_uid`, `reminder_rules` by `kind`,
  `terminology_overrides` by `key`, and `app_settings` not at all — it has exactly one row.
- **`unknown_json` is the subtle one.** It is merged into the row at the top level before the keys are
  sorted, and the column itself is never emitted under its own name. Emit both and the second export
  writes every preserved field twice and nests the container again — which is a failure this test
  catches on run one and nothing else catches at all.
- **Excluded tables must be excluded symmetrically.** `entitlements`, `ewe_summaries`, `search_docs`,
  `search_fts` and its shadow tables, the SQL views and `sqlite_sequence`. `ewe_summaries` is the one
  that fails loudest: it is rebuilt after a restore with a fresh `rebuilt_at`, so exporting it breaks
  equality on every run.
- **Nothing is re-stamped on the way in or out.** `created_at` and `updated_at` come from the file. A
  restore that freshened `updated_at` breaks equality on **every row in the database at once**, which
  makes the failure look like a format bug rather than the one-line importer bug it is.
  `last_exported_at` is stamped *after* the artefact is written (`09 §8.3`), so it is never inside the
  file that describes it — get that ordering wrong and the second export differs from the first in
  `app_settings` alone.
- **No floating-point numbers.** Grams and milli-°C are integers, booleans are `0`/`1` (#56). A
  `double` reintroduces the hardest canonicalisation problem in the format and the checksum starts
  flapping across platforms — which reads as flakiness, and `12 §11.6` is zero-tolerance about that.
- **Text is byte-verbatim.** No trimming, no case folding, no Unicode normalisation. The CSV formula
  guard is nowhere near this code path and must not be reached for.
- **Do not extend the property layer** (#118). `glados` covers pure value round trips and nothing else;
  the flock layer is a hand-rolled ~80-line generator. *"A seeded generator nobody understands in
  season three is worse than a fixture."*
- **Run the glados resolution before you rely on it.** Decision #4 bans `test` as a direct dependency
  because it caps `analyzer <13.0.0` and breaks `drift_dev`. §5.2 lists `glados: 1.1.7` as verified to
  resolve against this stack — so this is a re-check, not a re-litigation. If `flutter pub get`
  reddens, **the property layer is deleted, not the pin**, and layer 2 carries the whole task.
- **The generator's invariants are the test's real content**, and every one is a real importer bug when
  it is absent: a lamb's birth dam exists and its rearing dam may differ (fostering); dead lambs have a
  death date at or after their lambing's `occurred_at`; at least one treatment carries
  `WithdrawalDays`, one `WithdrawalNotApplicable`, and one **no withdrawal row at all**; at least one
  `TimeSource.userEdited` and one `TimeSource.autoCaptured`; unicode in free text; **a culled ewe whose
  tag a live ewe reuses**; an empty flock; and a flock at the free-tier ewe cap.
- **The culled-tag case is the one that proves the upsert.** Import is an upsert on `uid`, never on
  `tag` (#32). A generator without it lets an importer that upserts on tag pass 200 seeds.
- **`export_carries_no_row_ids_test.dart` is a second file on purpose.** The round trip catches an id
  leak only when the leak *also* breaks equality; an id that happens to survive re-issue passes it. The
  second file walks every row object and asserts no key is `id` and none ends `_id`. The five
  vocabulary FKs — `route`, `presentation`, `death_cause`, `kind`, `method` — are allowed **by name,
  never by pattern**: *"a pattern-shaped exemption is one refactor away from exempting the thing it was
  written to catch."*
- **`-P ci-fast` in the Definition of Done is a leg, not a flag.** `12 §11.2` rules that `flutter test`
  has no `-P`/`--preset` — the pass-through list is `--tags`, `--exclude-tags`, `--update-goldens`,
  `--coverage`, `--reporter`, `--concurrency`, `--test-randomize-ordering-seed`, `--name`,
  `--plain-name`, `--total-shards`, `--shard-index`, `--timeout`, `--fail-fast` and nothing else. Read
  that DoD line as *"the fast leg"*: `flutter test --exclude-tags golden`. **Tag the file `slow`**, not
  `flaky` — `slow` is a 3× timeout in `dart_test.yaml` and is **not** excluded from CI; `flaky` is.
  Two hundred restores is slow by design and must still run on every push.
- **Every seed builds its own database and its own support directory.** Randomised ordering (#121)
  will interleave them. `testDatabase()` and `freshSupportDir()` each register their own teardown; do
  not hoist either into a `setUpAll`.

### 5.5 The full test set

| Case | File | What it asserts |
|---|---|---|
| `'export to import to export produces equal table bytes'` | `export_round_trip_test.dart` | **The anchor**, ×200 seeds. `tablesBytesOf` equality, with `reproduce with FlockGenerator(n)` in the reason |
| `'the two checksums are equal'` | same | The checksum follows the `tables` bytes it covers |
| `'integer ids are re-issued and every uid is preserved'` | same | `09 §7.2` items 3 and 12; the reason this file is in `test/policy/` and not `test/data/` |
| `'a RecordedTime survives its JSON round trip'` · `glados` | same | Layer 1 (#118). Shrinking is the reason glados is here at all |
| `'an Instant survives ISO-8601 milliseconds and a Z'` · `glados` | same | `09 §7.2` item 5 — lossless, exactly |
| `'flock_400_3seasons.json round-trips'` | same | `09 §7.3`'s closing instruction — over the committed fixture, not only the generator |
| `'flock_15_at_cap.json round-trips'` | same | The at-cap fixture |
| `'an empty flock round-trips'` | same | The degenerate case: every table an empty array, `counts` all zero, checksum still stable |
| `'a backup with unlocked = 1 imports to unlocked = 0'` | same | #88, asserted here as well because the round trip is where a re-exported entitlement would show up |
| `'a culled ewe whose tag a live ewe reuses survives with both uids'` | same | The upsert-on-`uid` case (#32) |
| `'a treatment with no withdrawal row round-trips as no row'` | same | §12.1 — the absence is the value, and `importDefaults` may never fill it |
| `'a contradictory lambing round-trips unrepaired'` | same | §12.4 — three lambs against a birth type of `twin`, both times |
| `'unknown_json is re-emitted at the row top level and never as its own key'` | same | `09 §7.2` item 8 — the case the second export doubles |
| `'no double appears in either encoded body'` | same | #56, over the bytes |
| `'ewe_summaries and search_docs are absent from both exports'` | same | Symmetric exclusion; `ewe_summaries` fails loudest because `rebuilt_at` moves |
| `'created_at and updated_at are identical across the round trip'` | same | Nothing re-stamped (`09 §7.2` item 13) |
| `'last_exported_at is not inside the file that describes it'` | same | `09 §8.3`'s ordering, asserted from the format's side |
| `'no row object carries a key named id or ending in _id'` | `export_carries_no_row_ids_test.dart` | The other side of the property; the five vocabulary FKs allowed **by name** |
| `'the vocabulary exemption is a name list, not a pattern'` | same | Source-text case — a regex exemption is one refactor from exempting the target |
| `'a flock generated in the ambiguous hour round-trips byte-identically'` · **`@Tags(['uk-zone', 'policy'])`** | `export_round_trip_test.dart` | `TZ=Europe/London`, a generator seed whose events fall at **01:30 on 25 October 2026** — the hour that happens twice. Both exports carry the same epoch millis, the same `"2026-10-25"` civil dates and the same bytes. An importer that re-derives an instant from a local `DateTime`, or a `local_date` from an instant, differs by an hour or a day **only here**, and under the runner's UTC this case passes for the wrong reason |

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **R65's three words.** The **envelope** is the whole `.json` file; **`BackupHeader`** is the header
  block; **`ExportEnvelope`** is the disclaimer-bearing value every writer takes. *"If a sentence would
  read the same with two of those three swapped, it is wrong"* — and this file names all three.
- **CSV is deliberately lossy and is never asserted for round-trip equality** (`12 §10.6`). JSON is the
  backup; CSV and PDF are reports. Being explicit about which artefact is lossless is itself the
  design decision worth writing down.
- **If the property fails, the fix is in the writer or the importer.** Never in the test, never in the
  generator, and never by narrowing the comparison to the tables that happen to pass.

## 7. Definition of Done

- [ ] `'export to import to export produces equal table bytes'` passes, and was seen to fail first for the stated reason
- [ ] byte equality over the full fixture
- [ ] the test names the differing table when it fails
- [ ] the property runs in `-P ci-fast`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] there is **one** round-trip file; `12 §10.6` and `09 §7.3` are amended to name it in this commit
- [ ] the property is stated over `tables` and the header is explicitly outside it
- [ ] both committed fixtures round-trip, as well as the 200 generated flocks
- [ ] the four accessors are private to the file and appear nowhere under `test/support/`
- [ ] `export_carries_no_row_ids_test.dart` exists and exempts the five vocabulary FKs **by name**
- [ ] `glados: 1.1.7` came from decision-record §5.2, `flutter pub get` was run and its resolution read
- [ ] the file is tagged `slow` (a 3× timeout), never `flaky` (excluded from CI)
- [ ] the seed is printed in every failure reason

## 8. Verification

```bash
fvm flutter test test/policy/export_round_trip_test.dart
make check
make test
```

```bash
# The fast leg, spelled the way `flutter test` actually accepts (12 §11.2).
fvm flutter test --exclude-tags golden --test-randomize-ordering-seed random

TZ=Europe/London fvm flutter test --tags uk-zone
fvm flutter test test/policy/                      # the whole §12 tier
fvm flutter test test/policy/export_round_trip_test.dart --plain-name 'seed 137'

# The dependency re-check decision #4 makes mandatory.
fvm flutter pub get                                # read the resolution; do not skim it
```

```bash
ls test/policy/ | grep round_trip                       # expect exactly one file
grep -rn "tablesBytesOf\|headerOf\|idsOf\|uidsOf" test/support/   # expect zero
grep -rn "ORDER BY id" lib/data/export_repository.dart  # expect zero — uid ordering only
grep -n  "export_round_trip" docs/engineering/12-testing.md docs/engineering/09-export-formats.md
grep -rn "flaky" test/policy/export_round_trip_test.dart          # expect zero
git diff --stat -- lib/                                 # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(policy): the export-import-export equality property`

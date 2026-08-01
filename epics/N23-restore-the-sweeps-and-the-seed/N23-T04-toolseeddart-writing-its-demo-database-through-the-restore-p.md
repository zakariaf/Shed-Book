# N23-T04 — `tool/seed.dart` — writing its demo database through the restore path

| | |
|---|---|
| **Epic** | [N23 — Restore, the sweeps and the seed](epic.md) · `00-README` §9 step 8 (3 of 3) |
| **Task** | 4 of 7 |
| **Depends on** | N23-T03 |
| **Commit** | one commit · `feat(tool): seed.dart, writing through the restore path` |

## 1. Why this task exists

`dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42`, deterministic, writing
**through `RestoreService`** rather than through the repositories. That is what makes the seed a
continuous test of the one code path where a bug loses five seasons, and it is why restore had to exist
first.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/04-migrations-media-backup-restore.md` | **§7.1** (*"`tool/seed.dart` writes its deterministic fixtures through this same path… that is not convenience"*) · §7.2 (the flow the seed drives) · §6.2–§6.4 (the file the seed must produce) · §2.3 (`seedOnCreate`) | why the seed routes through restore at all |
| `docs/engineering/09-export-formats.md` | **§5.2** (the thirteen header keys, in fixed order, `_disclaimer` first and `tables` last) · **§5.3** (a real row, canonical key order, the five uid-less tables, the vocabulary-FK exception) · §5.7 (compact, one trailing newline, `tables` encoded **once**) · §7.2 (the thirteen properties the file must satisfy) | the exact bytes the seed writes |
| `docs/engineering/12-testing.md` | **§11.5** (the command, the fixed seed, the fixed clock, the `assert()` + `--dart-define` guard, and the two fixtures by shape) · §5.2 (the two seeding routes) · §10.6 (the domain invariants a generated flock must satisfy) · §3.2 (the host sqlite3 floor) | what "plausible" means, item by item |
| `docs/engineering/CONVENTIONS.md` | §1 (`tool/seed.dart` — *"deterministic demo DB, written THROUGH the restore path"*) · §2.8 (`AppDatabase`, `newUid()`, `configureConnection`) · §2.9 (`BirthType`, `LambingEase`, `Sex`, `LambStatus`, `FosterOutcome`) · §2.13 (the repository set — **and why the seed uses none of it**) · **R15** (`newUid()` is the only `package:uuid` call site) · R12, R13, R42, R46 · §5 | **BINDING** on every name the generated rows carry |
| `docs/engineering/03-data-model-and-schema.md` | §5 (the tables and their `NOT NULL`s) · §5.12 (`vocab_terms` keys: `dc_*`, `mp_*`, `rt_*`, `obs_*`, `fm_*`) · §6 (tag uniqueness among **active** animals) | what a valid row looks like |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · **#74** (the seed, the flags, the two fixtures, the guard) · #73 · #32 (`uid` is the export identity) · #42 (`seedFirstRun`) · #46 (one clock) · #56 (integer grams, integer milli-°C) · #59 (`barren` is `ewe_seasons.status`) · #118 (a seeded generator nobody understands in season three is worse than a fixture) | the decisions this task applies |
| `CLAUDE.md` | **P8** — there is no birth-type chooser; birth type is derived from the tally strokes · the vocabulary · the banned words | what the generated data may and may not contain |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-export-and-restore` | the seed routes through restore and produces the backup format |
| `shed-testing` | the seed is the precondition for the matrix, the goldens and the at-cap tests |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/seed_test.dart`
- **Test** — `'the seed is deterministic for a given --seed and writes through RestoreService'`
- **Why it is red today** — there is no seed, so there is no 400-ewe database to profile, pump or golden against.

```bash
fvm flutter test test/features/seed_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so neither half can pass alone:

1. **Deterministic** — generate twice with `--seed 42` into two temp directories and assert the two
   produced **backup files are byte-identical**, not merely that the row counts match. Byte equality is
   what makes the committed fixtures reviewable in a diff, and it is the assertion `newUid()` breaks.
2. **Through the restore path** — assert the resulting database carries the marks only a restore
   leaves: integer ids re-issued from 1 in insertion order, `foreign_key_check` empty, the FTS index
   populated by a rebuild, and **no** `seedFirstRun` season beyond the ones the file declares. A seed
   that wrote through repositories passes none of those.

**Green.** The minimum code that passes, and nothing beyond it — the script, the deterministic generator, and the restore-path write.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step, no domain step, and nothing under `lib/features/`.** This task's whole `lib/` surface
is the one export that lets a script reach the importer. Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `tool/seed.dart` | **New.** Argument parsing (three flags, hand-rolled — `args` is not in the verified dependency table and nothing enters the pubspec for a dev script), the deterministic generator, the backup writer, and the `RestoreService` call. Guarded by `assert()` **and** a `--dart-define` so it cannot run in a release build (#74) |
| 2 | `test/support/flock_generator.dart` | **New.** `FlockGenerator(seed)` — ~80 lines, `12 §5.3`'s twelfth support file, hand-rolled and deliberately not a `glados` `Any` extension (#118). `tool/seed.dart` and T07's property test call the **same** generator; two generators is two definitions of "plausible" |
| 3 | `lib/data/export_repository.dart` | **Edit, only if needed.** The seed writes a backup file, so it uses N22-T02's `writeBackup` rather than a second encoder. If `writeBackup` cannot be called with an injected `Directory`, that is the change — not a second writer |
| 4 | `README.md` | **Edit.** The three flags, the command, and one sentence on why the seed goes through restore. `00-README` §9 step 8 already carries the reason; do not re-derive it |
| 5 | `test/features/seed_test.dart` | **New.** The anchor and its neighbours (§5.4) |

`test/support/flock_generator.dart` living under `test/` while `tool/seed.dart` imports it is the one
awkward edge here. Two ways out, and the choice goes in the commit message: either the generator moves
to `tool/flock_generator.dart` and `test/support/flock_generator.dart` re-exports it, or the seed
script imports the test path directly (legal — `tool/` is not `lib/` and no layer rule reaches it).
Prefer the first: `12 §5.3` says `test/support/` is twelve files and the list is closed, and a
re-export is not a thirteenth concept.

### 5.2 The signatures

```bash
dart run tool/seed.dart --ewes 400 --seasons 3 --seed 42 [--out <dir>]
```

| Flag | Default | Meaning |
|---|---|---|
| `--ewes` | 400 | ewes in the most recent season |
| `--seasons` | 3 | seasons of history, oldest first |
| `--seed` | 42 | the PRNG seed. Same seed, same bytes |
| `--out` | the platform's temp directory | where the support directory is built. Required for the fixture generation in T05 |

```dart
// tool/seed.dart
Future<void> main(List<String> args) async {
  // #74: it cannot run in a release build. Both guards, because assert() is
  // stripped in release and the define is what makes the refusal loud.
  assert(() { _assertsAreOn = true; return true; }());
  if (!_assertsAreOn || !const bool.fromEnvironment('SHED_SEED')) {
    // Decision #74 calls it "a --dart-define"; the flag `dart run` accepts is
    // spelled `--define` (`flutter run` spells the same thing `--dart-define`).
    // Print the one this script is actually launched with.
    stderr.writeln('tool/seed.dart is a development script. '
                   'Run it with: dart run --define=SHED_SEED=true tool/seed.dart');
    exit(2);
  }
  …
}

// tool/flock_generator.dart  (re-exported by test/support/flock_generator.dart)
final class FlockGenerator {
  FlockGenerator(this.seed, {this.ewes = 400, this.seasons = 3});
  final int seed, ewes, seasons;

  /// The whole flock as the `tables` value of a backup: table name -> rows, every
  /// row a flat map keyed by SQLite column names in snake_case (09 §5.3).
  /// Referentially valid by construction — a lamb's birth_dam exists, a dead
  /// lamb's death date is at or after its lambing's occurred_at, a treatment
  /// references an animal that exists.
  Map<String, List<Map<String, Object?>>> tables();

  /// Deterministic, v7-SHAPED, and NOT newUid(). See §5.3.
  String uidFor(String table, int ordinal);
}
```

The write is the whole point of the task and it is four lines:

```dart
// tool/seed.dart — the seed does NOT touch a repository.
final support = Directory(p.join(outDir.path, 'shed_book_seed'))..createSync(recursive: true);
final backup  = await writeBackupFile(generator.tables(), header, into: outDir);   // N22-T02's writer
final service = RestoreService(support, NoNotifications());
final outcome = await service.restore(incoming: backup, header: header);
```

### 5.3 The details that are easy to get wrong

- **`newUid()` is not deterministic, and it will silently destroy this task.** UUID v7 carries a
  time-ordered prefix and a random tail (`uuid` 4.6.0, R15). Two runs with `--seed 42` would produce
  two files differing in every single `uid`, the committed fixtures would churn on every regeneration,
  and the byte-equality assertion this task exists to hold would be unwritable. **The generator derives
  its uids from its own seeded PRNG**, in the v7 shape so they satisfy the schema, and `tool/seed.dart`
  imports `package:uuid` **not at all** — R15 says `lib/core/db/uid.dart` is the only call site and
  this file is not it.
- **The clock is fixed too.** `withClock(Clock.fixed(...))` around the whole generation, because
  `appNow()` reads the ambient clock and every `created_at`, `updated_at` and `captured_at` in the file
  comes from it. A fixed seed with a live clock is not deterministic; it is deterministic-looking.
- **The seed uses no repository.** `LambingRepository.beginLambing` stamps `appNow()`, runs
  `RecordedTime.capture`, calls `newUid()` and fires a notification schedule. Going through the
  repositories would be easier, would produce different bytes every run, and would not exercise the
  one code path decision #74 exists to exercise. The generator produces **rows**; `RestoreService`
  writes them.
- **`seedFirstRun` must not fire.** The generated backup carries seasons, so T01's condition (*run it
  only if `tables['seasons']` is empty*) must evaluate false. If a phantom `"<year> lambing"` appears
  in the seeded database, the bug is in T01 and this test is what found it.
- **The generated file is a real backup, not a fixture format.** `_disclaimer` first, `_withdrawalNotice`
  second, thirteen header keys in `09 §5.2`'s fixed order, `tables` last and canonical, compact with
  one trailing newline, checksum over the `tables` bytes only, and `counts` carrying **all 21 tables,
  zeros included** — *"a table absent from `counts` is a table nothing verifies."*
- **No floating-point numbers, anywhere.** Mass is integer grams, temperature integer milli-°C (#56).
  A `double` in the generator breaks canonical encoding and makes the checksum flap across platforms
  — and the assertion that catches it is a scan over the encoded body, so it fails loudly.
- **Booleans are `0`/`1`**, matching `STRICT` INTEGER storage. `true`/`false` in the file is a defect
  even though `jsonDecode` would accept it.
- **Every column is emitted, `null` included.** An omitted key and an explicit `null` mean the same
  thing to the importer, *"but only one of them round-trips byte-for-byte"* (`09 §5.3`).
- **The flock must be plausible, and `12 §10.6` lists what that means** — each item is a real importer
  bug when it is missing: a lamb whose birth dam exists and whose rearing dam may differ (fostering);
  dead lambs with a death date at or after their lambing's `occurred_at`; at least one treatment with
  `WithdrawalDays`, at least one `WithdrawalNotApplicable`, and at least one with **no withdrawal row
  at all**; at least one `TimeSource.userEdited` and one `TimeSource.autoCaptured`; unicode in free
  text (`°`, `½`, an em-dash, an emoji); **a culled ewe whose tag a live ewe reuses**; barren ewes
  (`ewe_seasons.status = 'barren'`, R42 — never inferred); and losses.
- **Birth type is derived, never chosen** (P8). The generator writes the lambs and lets the birth type
  follow the count; it does not pick `twin` and then write three lambs — unless it is deliberately
  generating the **contradictory** lambing `12 §11.5` requires, in which case the contradiction is the
  point and nothing may repair it (§12.4).
- **Tags are unique among ACTIVE animals only** (owner ruling §7.0). The generator must produce the
  culled-tag-reuse case, because import is an upsert on `uid` and never on `tag`, and this is the case
  that proves it.
- **`tool/seed.dart` cannot use `path_provider` or `drift_flutter`.** It is a plain Dart script with no
  Flutter binding: `getApplicationSupportDirectory()` throws and `driftDatabase(` needs a plugin. Open
  the file with `NativeDatabase(File(...), setup: configureConnection)` — the same public, top-level
  `configureConnection` the app uses (R12, R13), so the seeded database gets the same seven pragmas in
  the same order as a real one. This is the concrete reason `RestoreService` takes an injected
  `Directory` (T01 §5.2).
- **Both guards, not one.** `assert()` is stripped in release, so it cannot be the whole defence; the
  `--dart-define` is what makes the refusal loud in a build where asserts are gone. #74 names both.
- **`--out` is not optional in practice.** T05 generates the committed fixtures with it. A script that
  can only write to a hard-coded location cannot produce a reviewable artefact.
- **400 ewes over three seasons is low single-digit MB** (`04 §6.8`) — under `kBackupSizeTripwireBytes`
  (20 MB). If the generated file exceeds the tripwire, **measure before assuming it is still fine**;
  the fix is a streaming writer, not an isolate, because a drift connection cannot cross an isolate
  boundary (#125).

### 5.4 The full test set

`test/features/seed_test.dart`.

| Case | What it asserts |
|---|---|
| `'the seed is deterministic for a given --seed and writes through RestoreService'` | **The anchor.** Two runs at `--seed 42` produce byte-identical backup files; the restored database shows re-issued ids, an empty `foreign_key_check` and a rebuilt FTS index |
| `'two different seeds produce different flocks'` | The generator is actually seeded, not constant |
| `'no uid in the generated file came from newUid'` | Source-text case over `tool/` — `package:uuid` is not imported, and the uids are reproducible from the seed alone |
| `'the generated file is a valid backup'` | Header key order, `_disclaimer` first, `tables` last, compact encoding, one trailing newline, checksum recomputes over the `tables` bytes |
| `'counts carries all 21 tables, zeros included'` | `09 §5.2`'s footnote: a table absent from `counts` is a table nothing verifies |
| `'no double appears anywhere in the encoded body'` | Scan the bytes (#56) |
| `'booleans are 0 and 1'` | No `true`/`false` in the encoded body |
| `'every column is emitted, null included'` | Compare each row's key set against the schema's column set |
| `'seedFirstRun does not run for a backup that carries seasons'` | The season count equals `--seasons`; no phantom `"<year> lambing"` |
| `'the generated flock contains a culled ewe whose tag a live ewe reuses'` | The upsert-on-`uid` case; both rows survive the restore |
| `'the generated flock contains a treatment with no withdrawal row'` | Reads as `WithdrawalNotRecorded`; nothing defaults it (§12.1) |
| `'the generated flock contains a contradictory lambing that nothing repairs'` | Three lambs against a birth type of `twin`, unchanged by the restore (§12.4) |
| `'the generated flock contains barren ewes recorded as ewe_seasons.status'` | R42; never inferred from an absence |
| `'the generated flock contains unicode free text that survives the round trip'` | `°`, `½`, an em-dash, an emoji — byte-verbatim (`09 §7.2` item 10) |
| `'the generated flock contains at least one edited and one auto-captured timestamp'` | The provenance quad travels as a unit |
| `'the seed refuses to run without the dart-define'` | Exit code 2 and the message; both guards present |
| `'the generated file is under the 20 MB tripwire at 400 ewes and 3 seasons'` | `04 §6.8`; a failure here means measure, not shrug |
| `'a flock generated across the ambiguous hour keeps its instants and its civil dates'` · **`@Tags(['uk-zone'])`** | `TZ=Europe/London` with the fixed clock pinned to **01:30 on 25 October 2026**. Lambings generated in the repeated hour restore to the same epoch millis and the same `local_date` — `2026-10-25`, never the 24th. This is the case where a generator that builds instants from local `DateTime` components lands an hour and sometimes a day out, and the lambing-spread histogram puts a bar in the wrong column for a season |

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **No new dependency.** `args`, `faker` and every convenience package are outside decision-record §5.
  Three flags parse in fifteen lines; a dev-only dependency is still a dependency in `pubspec.lock`,
  and G2 reads the lockfile.
- **The generator is hand-rolled and stays ~80 lines** (#118, `12 §10.6`). *"A seeded generator nobody
  understands in season three is worse than a fixture."* Do not extend the property layer.
- **The seed may never invent a domain value the user did not enter.** It is generating a *fictional*
  user's entries, which is legitimate — but a withdrawal period, a lambing ease, a birth type, a cause
  of death and a `barren` outcome are all things the fiction must *state*, never things the importer or
  a default may fill in afterwards.

## 7. Definition of Done

- [ ] `'the seed is deterministic for a given --seed and writes through RestoreService'` passes, and was seen to fail first for the stated reason
- [ ] deterministic for a given seed
- [ ] writes through `RestoreService`, not through repositories
- [ ] the three flags work and are documented in `README.md`
- [ ] the generated flock is plausible — barren ewes, losses, fosters, treatments
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] two runs at the same seed produce **byte-identical** backup files
- [ ] `package:uuid` is not imported by `tool/`; the uids are reproducible from the seed alone
- [ ] the clock is fixed for the whole generation
- [ ] the generated file is a valid backup: header order, canonical `tables`, checksum, all 21 `counts`
- [ ] no `double` and no `true`/`false` appears in the encoded body
- [ ] `seedFirstRun` does not run for a backup that carries seasons
- [ ] the flock contains the culled-tag reuse, a treatment with no withdrawal row, a contradictory lambing, barren ewes and unicode free text
- [ ] the script refuses to run without both the `assert()` and the `--dart-define`
- [ ] no new entry in `pubspec.yaml` or `pubspec.lock`

## 8. Verification

```bash
fvm flutter test test/features/seed_test.dart
make check
make test
```

```bash
# The command from 12 §11.5, twice, into two directories — then diff the bytes.
dart run --define=SHED_SEED=true tool/seed.dart --ewes 400 --seasons 3 --seed 42 --out /tmp/seed_a
dart run --define=SHED_SEED=true tool/seed.dart --ewes 400 --seasons 3 --seed 42 --out /tmp/seed_b
diff /tmp/seed_a/*.json /tmp/seed_b/*.json && echo "byte-identical"

TZ=Europe/London fvm flutter test --tags uk-zone
```

```bash
grep -rn "package:uuid" tool/                       # expect zero (R15)
grep -rn "newUid(" tool/                            # expect zero
grep -rn "Repository" tool/seed.dart                # expect zero — the seed uses none
grep -rn "path_provider\|driftDatabase(" tool/      # expect zero — no Flutter binding here
grep -rn "DateTime.now(" tool/                      # expect zero — the clock is fixed
git diff --stat -- pubspec.yaml pubspec.lock        # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(tool): seed.dart, writing through the restore path`

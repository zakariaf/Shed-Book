# N12-T02 — `SettingsRepository` and the four settings providers

| | |
|---|---|
| **Epic** | [N12 — The DI root, settings, the ticker and the harness](epic.md) · `00-README` §9 step 4 (3 of 3) |
| **Task** | 2 of 5 |
| **Depends on** | N12-T01 |
| **Commit** | one commit · `feat(data): SettingsRepository and the four settings providers` |

## 1. Why this task exists

Pulled forward from the Settings epic because the export banner writes `app_settings` in
N21 — `lastExportedAt`, `lastExportPromptedAt`, `exportPromptDismissedForSeason` — and `CONVENTIONS
§2.13` gives `ExportRepository` *nothing: read and artefact assembly only*. The repository and one
**parameterised** test that every setting persists and re-reads; no screen. Critique defect S6.

It is also the **first repository in the project**, so its shape is the shape the other eleven copy:
a concrete `final class` taking `AppDatabase`, no interface, event verbs returning `WriteOutcome`, one
transaction each, and no `Clock` parameter.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/02-state-di-navigation.md` | §4–§5 | the provider graph, the override rules and the harness |
| `docs/engineering/CONVENTIONS.md` | §2.13, §3 | `SettingsRepository`'s ownership of `app_settings`, and every provider name |
| `docs/engineering/12-testing.md` | §4, §6.2 | the seven fakes and the variant table — and what may exist yet |
| `docs/engineering/03-data-model-and-schema.md` | §5.12 (`VocabTerms`, `TerminologyOverrides`) · **§5.13** (`AppSettings`: every column, every `CHECK`, `CHECK (id = 1)`, and why there is no locale column) | the setting list the parameterised test iterates, and every constraint it must not clamp |
| `docs/engineering/CONVENTIONS.md` | §2.2 (`Instant`) · §2.3 (`WeightUnit`) · §2.8 (`InstantConverter`) · §2.11 (`ShedThemeSet`, `ShedPaletteId`) · §2.14 (`Terminology`, `TermLabel`) · §4.6 (column naming) · R29, R35, R40, R68 | `settingsProvider` carries the **row** class; `deepRed`'s key is `'red'`; `themeProvider` is synchronous; `unitsProvider : Provider<WeightUnit>` |
| `docs/engineering/01-architecture.md` | §4.1–§4.3 (event verbs, one transaction, `appNow()` once) · §5.2–§5.3 (`WriteOutcome`, `ShedFailure`, `shedFailureFrom`) | what a repository verb returns and how a `SqliteException` becomes a `ShedFailure` |
| `docs/engineering/06-design-system.md` | §2.1 | `themeProvider` is synchronous and the first frame paints before the database opens |
| `docs/engineering/05-domain-correctness.md` | §8.1 | `Terminology`, `TermLabel`, and where the default labels come from — the one open seam here |
| `docs/engineering/12-testing.md` | §2.2–§2.4 (`atFixed`, the ambiguous hour, the data-tier round trip) · §3.1 (`testDatabase()`) · §3.3 (assert the constraint, not the mock) | how the parameterised test and its `uk-zone` sibling are written |
| `docs/engineering/09-export-formats.md` · `docs/engineering/08-platform-integration.md` | 09 §8.3 · 08 §11 | `last_exported_at` is stamped on `ShareOutcome.completed` **and** `unknown`, never on `dismissed`, never before the sheet opens |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-riverpod-providers` | `settingsProvider`, `themeProvider`, `unitsProvider` and `terminologyProvider` |
| `shed-write-path` | this is the first repository written in the project — event verbs, one transaction, no `save()` — and its shape is the one the other eleven copy |

The parameterised-test technique this task's anchor needs is `12 §3.1`, `§3.3` and `§5.2`, cited in
Sources and spelled out in §5.4; the skill budget is two auto-firing and the two above are the ones
that decide whether the code is right rather than whether the test is tidy.

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/settings_repository_test.dart`
- **Test** — `'every setting persists and re-reads, parameterised over the whole setting list'`
- **Why it is red today** — nothing writes `app_settings`, and N21's banner would have to invent a second writer.

```bash
fvm flutter test test/data/settings_repository_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion into a table, because the point of the test is that the *fifteenth* setting
joins it for free. Declare one `_Setting<T>` record per column carrying its name, a legal value, an
illegal value, the verb that writes it and the getter that reads it, then drive one `for` loop over the
list asserting three things per row: the legal value round-trips through a **close and reopen**; the
illegal value comes back as `WriteFailed` and the stored value is **unchanged**; and the row count of
`app_settings` is still exactly 1. Assert the list's length against the column count read out of the
committed drift schema JSON, so a new column added in a later epic fails this test until it is
represented.

**Green.** The minimum code that passes, and nothing beyond it — the repository, the four providers, and a test that iterates the setting list rather than
naming each one.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Steps 3 (write path), 4 (wiring) and 7 (tests).** No schema: `app_settings` was frozen in N07 and
this task adds no column — say so in the commit message. No domain, no controller, no UI, no ARB
string; the Settings **screen** is N29.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/settings_repository.dart` | **New.** `final class SettingsRepository` — the only writer of `app_settings`, `vocab_terms` and `terminology_overrides` (`CONVENTIONS` §2.13). Its class doc comment names N21 and the three banner columns, so the export epic cannot grow a second writer |
| 2 | `lib/data/providers.dart` | **Edit.** Add `settingsRepositoryProvider`, `settingsProvider`, `themeProvider`, `unitsProvider`, `terminologyProvider`, and delete their lines from T01's ledger. Five new declarations; the file now holds seven |
| 3 | `test/data/settings_repository_test.dart` | **New.** The parameterised anchor, the `CHECK`-rejection half, the one-row assertions, and the provider-arm cases |
| 4 | `test/data/settings_ambiguous_hour_test.dart` | **New.** `@Tags(['uk-zone'])` with the `setUpAll` offset guard. The three `Instant` columns round-tripping 01:30 on 25 October 2026 |

Nothing under `lib/features/` and nothing under `lib/l10n/`. If an ARB string appears in this diff, the
Settings screen has leaked forward.

### 5.2 The signatures

`CONVENTIONS` §2.13 names the class, its file and the tables it owns, and it does **not** name its
verbs. This task fixes them, under `CONVENTIONS` §4.2's rules and §5's vocabulary. Write them as
printed; N29's screen and N21's banner both call these names.

```dart
// lib/data/settings_repository.dart
//
// The ONLY writer of app_settings (CONVENTIONS §2.13). Pulled forward from N29
// because N21's end-of-day export banner writes three of these columns and
// ExportRepository owns "nothing — read + artifact assembly only".
//
// N21 calls `recordExported(at:)` and `recordExportPrompted(at:)`. Per 09 §8.3
// and 08 §11, `recordExported` runs on ShareOutcome.completed AND on unknown,
// NEVER on dismissed and NEVER before the share sheet opens: stamping early
// tells a shepherd their season left the phone when it did not.
final class SettingsRepository {
  SettingsRepository(this._db);
  final AppDatabase _db;

  /// The one row. 03 §5.13: `CHECK (id = 1)`, seeded by `seedFirstRun`.
  Stream<AppSetting> watch();
  Future<AppSetting> read();

  // Display and units — N29's screen.
  Future<WriteOutcome> setWeightUnit(WeightUnit unit);
  Future<WriteOutcome> setTemperatureUnit(TemperatureUnitKey unit);
  Future<WriteOutcome> setPalette(ShedPaletteId palette);
  Future<WriteOutcome> setHighContrast({required bool on});
  Future<WriteOutcome> setLeftHanded({required bool on});
  Future<WriteOutcome> setWakelockEnabled({required bool on});

  // Display arithmetic the user controls — never advice (03 §5.13).
  Future<WriteOutcome> setTurnOutThresholdHours(int hours);
  Future<WriteOutcome> setCycleDays(int days);
  Future<WriteOutcome> setPercentageDefinition(LambingPercentageChoice choice);

  // Season pointer — N28 reads it, N23's restore rewrites it.
  Future<WriteOutcome> setCurrentSeason(SeasonId? season);

  // The export banner's three columns — N21 (critique defect S6).
  Future<WriteOutcome> recordExported(Instant at);
  Future<WriteOutcome> recordExportPrompted(Instant at);
  Future<WriteOutcome> dismissExportPromptForSeason(SeasonId season);

  // Written by ReminderReconciler.reconcile() in the same transaction that
  // records the projection (R40) — N24.
  Future<WriteOutcome> recordReconcileScheduled(Instant at);

  // vocab_terms and terminology_overrides — N29 edits them; N12 only reads.
  Stream<List<VocabTerm>> watchVocabulary(String list);
  Stream<Map<AnimalClass, TermLabel>> watchTerminologyOverrides();
}
```

And the five providers in `lib/data/providers.dart`:

```dart
final settingsRepositoryProvider = FutureProvider<SettingsRepository>((ref) async {
  return SettingsRepository(await ref.watch(databaseProvider.future));
});

/// R29: the ROW class `AppSetting`, not the table class `AppSettings`.
/// `appSettingsProvider` is a banned spelling.
final settingsProvider = StreamProvider<AppSetting>((ref) async* {
  final repo = await ref.watch(settingsRepositoryProvider.future);
  yield* repo.watch();
});

/// SYNCHRONOUS (R29, 06 §2.1). The first frame paints before the database is
/// open, so the non-`AsyncData` arm returns the const night pair. No AsyncValue
/// accessor is used to do it — 02 §2.2 bans all five.
final themeProvider = Provider<ShedThemeSet>((ref) {
  return switch (ref.watch(settingsProvider)) {
    AsyncData(:final value) => buildShedTheme(
        resolvePalette(paletteFromKey(value.palette),
            highContrast: value.highContrast),
      ),
    AsyncError() || AsyncLoading() => kNightThemeSet,
  };
});

/// R68. Derived from settingsProvider; `kg` until the row arrives, which is
/// also `app_settings.weight_unit`'s own default (03 §5.13).
final unitsProvider = Provider<WeightUnit>((ref) {
  return switch (ref.watch(settingsProvider)) {
    AsyncData(:final value) => WeightUnit.fromKey(value.weightUnit),
    AsyncError() || AsyncLoading() => WeightUnit.kg,
  };
});
```

`terminologyProvider` is the one signature this task cannot copy from a document, because two
documents give its defaults two different homes. See the first gotcha below.

### 5.3 The details that are easy to get wrong

- **`terminologyProvider`'s defaults have two homes, and this task must say which it took.**
  `CONVENTIONS` §3.1 puts `terminologyProvider : Provider<Terminology>` in `lib/data/providers.dart`
  *"derived from `settingsProvider` + the seeded defaults"*. `05 §8.1` puts the defaults in
  `lib/features/settings/terminology_bootstrap.dart`, *"which already has a `BuildContext`"*, because
  `lib/data/` and `lib/domain/` are both forbidden from importing `AppLocalizations`. Both cannot be
  true of one expression. Land the provider with the defaults as an **injected**
  `Map<AnimalClass, TermLabel>` — a second provider, `terminologyDefaultsProvider`, declared in
  `lib/data/providers.dart` and returning a `const` map of the shipped en-GB labels — and record in the
  file which of the two documents you followed. **Do not invent a third source of default labels**, and
  do not reach for `AppLocalizations` from `lib/data/`. If you cannot close it, carry it into the PR
  body with both citations (`00-README` §10's amendment rule).
- **`ShedPaletteId.values.byName('red')` throws.** `deepRed`'s stored key is `'red'` (R35) — the one
  member whose key does not match its name. Write `paletteFromKey(String)` as a `.key` lookup over
  `ShedPaletteId.values`, and make an **unrecognised** key resolve to `night` rather than throw. A
  palette string this build does not know must not be a crash on the first frame; it must be a dark
  screen.
- **`settingsProvider` carries `AppSetting`, singular** (R29). The table class is `AppSettings`; the
  row class is `AppSetting` because 03 annotates the table `@DataClassName('AppSetting')`.
  `appSettingsProvider` is a banned spelling and so is `StreamProvider<AppSettings>`.
- **`themeProvider` must not await anything.** It is a `Provider`, not a `FutureProvider`. If it
  awaits, the first frame waits for SQLite and decision #21 is dead. Its non-`AsyncData` arm is the
  `const night` pair authored in N09 — a `const`, so it costs nothing and cannot fail.
- **The exhaustive `switch` has no `default:` and uses no accessor.** `AsyncData`, `AsyncError`,
  `AsyncLoading` — all three, named. `.value`, `.valueOrNull`, `.requireValue`, `.hasValue` and
  `.asData` are banned (`02 §2.2`); four are grepped and bare `.value` is a reviewer item, which is
  exactly why the pattern-matched `AsyncData(:final value)` form is the one to write: the binding is
  local and there is no accessor to grep for.
- **`app_settings` has exactly one row and it already exists.** `seedFirstRun` (N07-T07) inserted it,
  and `CHECK (id = 1)` makes a second unstorable. Every verb is an `update` over `where(id.equals(1))`
  — **never** an upsert, never `insertOnConflictUpdate`. A repository that upserts passes its own test
  on an empty database and fails on a real one.
- **A `CHECK` violation is a `WriteFailed`, never a clamp.** `turn_out_threshold_hours BETWEEN 1 AND 336`,
  `cycle_days BETWEEN 1 AND 60`, `palette IN ('night','amber','red')`,
  `weight_unit IN ('kg','lb')`, `temperature_unit IN ('c','f')`, and the four-value
  `percentage_definition` list. Catch the `SqliteException`, map it through
  **`shedFailureFrom(Object)`** in `lib/data/failure_mapping.dart` (N11-T02), and return
  `WriteFailed(failure)`. Silently rounding 400 hours down to 336 is safety rule 4 — *never silently
  correct a user's entry* — committed by a settings screen.
- **There is no `ShedFailure.from(e, s)`.** One mapping site, one top-level function
  (`01 §5.3`, R4). And this repository must **not** import `lib/domain/validation/` — layer rule
  `layer.data_no_validation` makes a repository structurally incapable of producing a `Warning`
  (R53).
- **No `save*(` anywhere in this file.** `db.save_verb` bans `save\w*\(` under `lib/data/`, and it
  fires on `saveAs(`, `savePoint(` and `savedAt` too. Every verb here is an event verb:
  `setPalette`, `recordExported`, `dismissExportPromptForSeason`.
- **The three `Instant` columns go through `InstantConverter`.** `last_exported_at`,
  `last_export_prompted_at` and `last_reconcile_scheduled` are `integer().map(const InstantConverter())`
  in 03 §5.13. Writing a raw `int` companion value bypasses the converter and stores something that
  reads back wrong; `db.drift_datetime` separately bans drift's `dateTime()`.
- **`current_season` and `export_prompt_dismissed_for_season` are foreign keys** with
  `ON DELETE SET NULL`, and `foreign_keys = ON` (decision #28, R13). A parameterised round trip that
  writes `SeasonId(1)` into either column without seeding a `seasons` row fails on the FK, not on the
  behaviour under test. Seed the season first, or the test measures the wrong thing.
- **`turn_out_threshold_hours` is a display threshold, never a recommendation.** 03 §5.13 says so in
  the schema itself: *"Convention 5's ban is on defaults that answer a veterinary question on the
  user's behalf; 'how long before you nudge me' is not one."* Do not write a doc comment, a test name
  or a commit message that calls it a recommended value — and answer §12.2 in the PR body with this
  column named.
- **`app_settings` has no withdrawal column and must never gain one.** If a later epic wants a default
  withdrawal period stored here, that is safety rule 1 and the answer is no.
- **`wakelock_enabled` is a stored preference; the wakelock itself is N29's gateway.** Writing this
  column now is correct and wiring it to anything is not — `wakelockProvider` does not exist.
- **`temperature_unit` accepts `'c'` and `'f'` although the owner's ruling is °C.** R68's note: a
  `temperatureUnitProvider` ships only if a temperature column ships. Store the setting, do not derive
  a provider from it.
- **The repository takes no `Clock`** (`CONVENTIONS` §2.13). `recordExported(Instant at)` takes the
  instant as an argument, so N21 supplies the one `appNow()` its write path already called. A
  repository that calls `appNow()` itself would stamp a second, later instant than the write it
  belongs to.

### 5.4 The full test set

Two files. Both run against `NativeDatabase.memory()` through `testDatabase()` — except the two
durability cases, which need a real file to reopen.

`test/data/settings_repository_test.dart`:

| Case | What it asserts |
|---|---|
| `'every setting persists and re-reads, parameterised over the whole setting list'` | **The anchor.** One loop over the `_Setting` table: write the legal value, close, reopen, read it back |
| `'the setting list covers every app_settings column'` | The table length equals the column count read out of `drift_schemas/drift_schema_v<N>.json` via `findColumn` (`12 §5.3`). A column added in a later epic fails here until it is represented |
| `'an illegal value is refused and the stored value is unchanged'` | Parameterised over the same table's `illegal` field: `WriteFailed`, and a re-read returns the previous value. Safety rule 4 |
| `'palette rejects dark and accepts night, amber and red'` | Named separately because R35 is the one place a member name and a stored key differ, and `dark` is the historical spelling somebody will try |
| `'turn_out_threshold_hours of 0 and of 337 are both refused, and 1 and 336 are both accepted'` | The boundary, named, so nobody widens the `CHECK` to make a screen easier |
| `'app_settings still holds exactly one row after every verb'` | Runs after the whole loop. `CHECK (id = 1)` plus a `count()` — the assertion that catches an upsert |
| `'settingsProvider emits again when a setting is written'` | Through a `ProviderContainer` with `databaseProvider` overridden; listen, write, expect a second emission. Proves the drift `watch()` is wired and that no `ref.invalidate` is needed (`02 §4.1`) |
| `'themeProvider returns the night pair before the database opens'` | A container whose `databaseProvider` never completes; `themeProvider` still returns a `ShedThemeSet`. This is decision #21 as an assertion |
| `'themeProvider returns the night pair for an unrecognised palette key'` | Write `'chartreuse'` past the repository (a raw companion in the test) and read the provider: night, not a throw |
| `'unitsProvider is kg before the row arrives and follows it after'` | Both arms of the switch |
| `'terminologyProvider resolves a default label and a user override wins over it'` | Two rows in `terminology_overrides`; `labelFor` returns the override for one `AnimalClass` and the default for another |
| `'no AsyncValue accessor appears in providers.dart'` | Source text: `.valueOrNull`, `.requireValue`, `.hasValue`, `.asData`. Bare `.value` is the reviewer item `02 §2.4` names |
| `'SettingsRepository does not import lib/domain/validation/'` | Source text. `layer.data_no_validation` proves it in CI; this proves it in the tier run first |
| `'no save-shaped verb exists on SettingsRepository'` | Source text for `save\w*\(`. Duplicates `db.save_verb` deliberately |

`test/data/settings_ambiguous_hour_test.dart` — `@Tags(['uk-zone'])`, `setUpAll` asserting
`DateTime(2026, 7, 1).timeZoneOffset == Duration(hours: 1)` and failing with the zone it found
(N04-T08's pattern):

| Case | What it asserts |
|---|---|
| `'an export recorded at 01:30 in the repeated hour reads back as 01:30 after a reopen'` | `atFixed(DateTime(2026, 10, 25, 1, 30), () => repo.recordExported(appNow()))` against a real file; close; reopen with `seedOnCreate: false`; `row.lastExportedAt!.local.hour == 1` and `.minute == 30`. This is the `InstantConverter` half of `12 §2.4`, applied to the three columns this repository owns |
| `'the two candidate instants are the only two possible values'` | `epochMillis` equals either `DateTime.utc(2026,10,25,0,30)` or `DateTime.utc(2026,10,25,1,30)` in millis — the same assertion DST-2 makes, one tier up |
| `'a prompt recorded at 01:30 GMT and an export recorded at 01:30 BST are different instants'` | The repeated hour happens twice, and the banner's "once a day" arithmetic in N21 depends on these being orderable. Two writes, one comparison |
| `'a reconcile stamp survives the spring-forward gap unchanged'` | 29 March 2026: write at 00:59, read after the jump; the stored `Instant` is absolute and does not move |

## 6. Constraints that bind this task

- **Never silently correct an entry** (safety rule 4). Every `CHECK` violation surfaces as
  `WriteFailed`; nothing is clamped, rounded or coerced.
- **Never present as a regulatory record, never give veterinary advice** — `turn_out_threshold_hours`
  and `cycle_days` are display arithmetic, and the words used about them in code, tests and the commit
  message must say so.
- **Every write commits immediately.** There is no settings draft, no Apply button and no
  `commit()`; each verb is its own transaction.
- **en_GB, kg, °C, 24 h** — and note that 03 §5.13 deliberately has **no** locale, date-format or
  first-day-of-week column, because a stored copy goes stale when the user changes their phone's
  region. Do not add one.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every setting persists and re-reads, parameterised over the whole setting list'` passes, and was seen to fail first for the stated reason
- [ ] the test is parameterised over the setting list, so a new setting joins it for free
- [ ] `ExportRepository` will write nothing — this is the only `app_settings` writer
- [ ] the four providers exist and are read by `app.dart`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the setting list's length is asserted against the committed drift schema JSON, not against a remembered number
- [ ] every `CHECK` violation returns `WriteFailed` and leaves the stored value unchanged; nothing is clamped
- [ ] `app_settings` still holds exactly one row after every verb; no verb upserts
- [ ] `settingsProvider` is `StreamProvider<AppSetting>`; `appSettingsProvider` appears nowhere
- [ ] `themeProvider` is a synchronous `Provider<ShedThemeSet>` whose non-`AsyncData` arm is the const `night` pair, and an unrecognised palette key resolves to `night` rather than throwing
- [ ] no `AsyncValue` accessor appears in the diff; every read is an exhaustive `switch` with no `default:`
- [ ] no `save*(` verb exists in `lib/data/settings_repository.dart`
- [ ] the class doc comment names N21, the three banner columns, and the completed/unknown/dismissed rule
- [ ] **`terminologyProvider`'s default source is either ruled in this commit with `05 §8.1` or `CONVENTIONS §3.1` amended, or carried into the PR body as open with both cited** — never silently resolved
- [ ] `test/data/settings_ambiguous_hour_test.dart` is tagged `uk-zone`, guards its offset in `setUpAll`, and is reported by `TZ=Europe/London fvm flutter test --tags uk-zone`

## 8. Verification

```bash
fvm flutter test test/data/settings_repository_test.dart
TZ=Europe/London fvm flutter test test/data/settings_ambiguous_hour_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone --reporter expanded   # confirm the new file is counted
make check
make test
```

```bash
grep -n "save" lib/data/settings_repository.dart                  # expect no save-shaped verb
grep -n "insertOnConflictUpdate\|into(" lib/data/settings_repository.dart   # expect zero
grep -rn "appSettingsProvider" lib/ test/                          # expect zero
grep -rn "valueOrNull\|requireValue\|hasValue\|asData" lib/        # expect zero
grep -rn "domain/validation" lib/data/                             # expect zero
grep -c "^final .*Provider = " lib/data/providers.dart             # expect 7
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(data): SettingsRepository and the four settings providers`

# N15-T04 — `NoteRepository` — `notes` and `media_assets`

| | |
|---|---|
| **Epic** | [N15 — Media and notes](epic.md) · `00-README` §9 step 6 (1 of 5) |
| **Task** | 4 of 6 |
| **Depends on** | N15-T03 |
| **Commit** | one commit · `feat(data): NoteRepository with honest timestamps` |

## 1. Why this task exists

The note write with the provenance quad and a **real `occurred_at`** distinct from
`created_at` — because a note written at 7am about a 3am event has two true times and the product
refuses to pretend otherwise (§12.5).

This is also the third hop of R47's capture flow — `CameraService.pick()` → `MediaStore` compresses
and writes → **`NoteRepository` inserts the `media_assets` row** — and the eighth of the twelve
repositories to exist. It owns writes to `notes` and `media_assets` and nothing else touches either
table (`03 §5.14`).

It is the first code in the project that inserts a `notes` row, which means it is the first time the
FTS5 trigger trio `notes_search_ai` / `_au` / `_ad` has ever fired. Those triggers were written blind
in N07-T07 against a table with no writer; if a `COALESCE` is missing from one of them, the failure is
a `NOT NULL` abort raised from a trigger nobody was looking at, on the create path, at 03:20. §5.4
makes that a test rather than a night.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | §5.11 | `Notes` and `MediaAssets` verbatim — `occurred_at`, the quad, the two different subject `CHECK`s, `length(trim(body)) > 0`, `uniqueKeys [{relativePath}]` |
| `docs/engineering/03-data-model-and-schema.md` | §5.14, §9.2 | `NoteRepository` owns both tables and nothing else writes them; the `notes` → `search_docs` trigger and the `COALESCE` rule |
| `docs/engineering/04-migrations-media-backup-restore.md` | §4.6 | `attachPhoto` printed in full, and the three things it is deliberately not doing |
| `docs/engineering/04-migrations-media-backup-restore.md` | §4.4 | `byte_size` written at capture; `sha256` is `NULL` in v1 and why |
| `docs/engineering/08-platform-integration.md` | §4 | the audio refinement of the ordering rule: the `media_assets` row is inserted when recording **starts** |
| `docs/engineering/05-domain-correctness.md` | §4.1, §4.2, §7 | `RecordedTime`, its three factories, `provenanceLabel`'s exhaustive switch, and §12.5's columns |
| `docs/engineering/01-architecture.md` | §4.2, §5.2, §5.3 | event verbs; `WriteOutcome` and the two verbs that may throw; `_write()` and `shedFailureFrom` |
| `docs/engineering/CONVENTIONS.md` | §2.13, §3.1, §4.6, R3, R15, R19, R32, R33, R37, R53 | the repository set is twelve and closed, `noteRepositoryProvider`, the event-time column names, ids cross boundaries and `int` does not, warnings are the controller's |
| `docs/engineering/07-screens.md` | §6.4, §7.3, §6.5 | *"Note / voice note / photo — 1 each"*, and why the **ambiguous** DST hour is deliberately not warned about |
| `shed-book-spec.md` | §7.2, §12.4, §12.5 | the free-text note and the optional voice note; never silently correct; honest timestamps |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | the event verb, the one transaction, the provenance quad, and the rule that nothing side-effecting goes inside a transaction |
| `shed-safety-rules` | §12.5 is two columns and a label here, and §12.4 is the reason a `media_assets` row is never deleted |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/note_repository_test.dart`
- **Test** — `'a note written now about an earlier event stores both times and labels the provenance'`
- **Assertion, spelled out** — with the clock pinned at 07:00 on 14 March 2026, call `addNote` with
  `occurredAt` of 03:20 that morning. Read the row back and assert **four** distinct facts:
  `occurred_at` is 03:20, `created_at` **and** `captured_at` are 07:00 and byte-equal to each other,
  `time_source` is `'entered'` with `original_effective` `NULL`, and the `RecordedTime` rebuilt from
  those columns has `provenanceLabel == 'time entered by you'` — never empty, and never
  `'recorded automatically'`, which is what a single-timestamp implementation silently produces.
- **Why it is red today** — nothing writes a note or attaches a media asset.

```bash
fvm flutter test test/data/note_repository_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the verb, one transaction, both timestamps, the media row.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step and no domain step.** Both tables and both `RecordedTime` factories already exist —
`notes` and `media_assets` were frozen at N07-T08 and `lib/domain/time/recorded_time.dart` landed in
N04. This task is `00-README` §8 step 3 (the write path) and step 4 (wiring), and nothing else.

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/data/note_repository.dart` | **New.** `final class NoteRepository` with four event verbs and one private `_write()`. Takes `AppDatabase`; takes no `Clock` (R19). |
| 2 | `lib/data/failure_mapping.dart` | Read, **not edited**. A `CHECK` violation here arrives as `SQLITE_CONSTRAINT` and correctly falls through to `UnexpectedFailure` — gotcha 12. |
| 3 | `lib/data/providers.dart` | Edit: add `noteRepositoryProvider` — a `FutureProvider<NoteRepository>`, keepAlive, derived from `databaseProvider`. Not a `Provider`: the gateways are synchronous, the repositories are not. |
| 4 | `test/data/note_repository_test.dart` | **New.** The anchor plus §5.4's cases, against `NativeDatabase.memory()` via `testDatabase()` — never a mock (decision #111). |
| 5 | `test/domain/uk_zone/note_times_dst_test.dart` | **New.** `@Tags(['uk-zone'])`. Two honest instants behave differently across a clock change than one does. |
| 6 | `test/support/seeds.dart` | Read, **not edited**. `seedLambing` already gives the anchor a parent row; adding a `seedNote` would put a second writer on a table this repository owns. |

### 5.2 The signatures

Four event verbs. **None returns an id and none throws** — `beginLambing` and `addLamb` are the only
two verbs in the app that do, and that set is closed (R32).

```dart
// lib/data/note_repository.dart
// NoteRepository owns writes to `notes` and `media_assets` (03 §5.14, R47).
// It holds a MediaStore's OUTPUT — a relative path — and never opens a file.

final class NoteRepository {
  NoteRepository(this._db);
  final AppDatabase _db;

  /// `occurredAt` null  ⇒ RecordedTime.capture(now)  ⇒ time_source 'auto'
  /// `occurredAt` given ⇒ RecordedTime.entered(...)  ⇒ time_source 'entered'
  /// At least ONE subject must be non-null — notes' CHECK is `>= 1`, not `= 1`.
  Future<WriteOutcome> addNote({
    EweId? ewe,
    LambId? lamb,
    LambingId? lambing,
    SeasonId? season,
    required String body,
    Instant? occurredAt,
  });

  /// 04 §4.6, verbatim. EXACTLY one subject — media_assets' CHECK is `= 1`.
  Future<WriteOutcome> attachPhoto(
    LambingId lambing, {
    required String relativePath,   // relative only — 04 §4.3
    required int byteSize,
  });

  /// 08 §4: the row is inserted when recording STARTS, with byte_size 0, so a
  /// phone death mid-note leaves a linked truncated file rather than an orphan.
  Future<WriteOutcome> beginVoiceNote(
    LambingId lambing, {
    required String relativePath,
  });

  /// Keyed on relative_path, which is `unique` — so no id has to travel and
  /// this stays a non-throwing verb. Written on stop(), and by the cap's
  /// onCapReached through the same path (08 §4).
  Future<WriteOutcome> completeVoiceNote({
    required String relativePath,
    required int byteSize,
    required int durationMs,
  });
}
```

```dart
// lib/data/providers.dart
final noteRepositoryProvider = FutureProvider<NoteRepository>(
  (ref) async => NoteRepository(await ref.watch(databaseProvider.future)),
);
```

The columns each verb writes, spelled as `03 §5.11` spells them:

| Verb | Writes |
|---|---|
| `addNote` | `uid` = `newUid()` · `created_at` = `updated_at` = `now` · one or more of `ewe`/`lamb`/`lambing`/`season` · `body` · `occurred_at` = `rt.effective` · `captured_at` = `rt.capturedAt` · `original_effective` = `rt.originalEffective` (`NULL` here) · `time_source` = `rt.source.key` |
| `attachPhoto` | `uid` · `created_at` = `updated_at` = `now` · `relative_path` · `kind` = `'photo'` · `byte_size` · `lambing` · `duration_ms` `NULL` · `sha256` `NULL` · `missing_since` `NULL` |
| `beginVoiceNote` | as above with `kind` = `'voice'`, `byte_size` = `0` |
| `completeVoiceNote` | `UPDATE … SET byte_size, duration_ms, updated_at = now WHERE relative_path = ?` |

### 5.3 The details that are easy to get wrong

1. **A `notes` row carries four instants, not two, and `created_at` is not `occurred_at`.** The
   `Identified` mixin gives `created_at` and `updated_at`; the §12.5 quad (R37) gives `occurred_at`,
   `captured_at`, `original_effective` and `time_source`. `03 §5.11`'s own comment is the sentence to
   keep in your head: *"`occurred_at` is WHEN THE THING HAPPENED and is distinct from the mixin's
   `created_at`, which is when the row was written… the timeline sorts on the first."* An
   implementation that writes `occurred_at = now` for a deferred entry compiles, passes every
   `CHECK`, and quietly sorts the shepherd's night by typing order.
2. **`appNow()` is read once per mutation.** Two reads inside one transaction can straddle a second
   boundary and produce `created_at != captured_at` for no reason a reader can explain. `01 §4.2`
   states it as a rule; the anchor asserts it as byte equality.
3. **The paired `time_source` `CHECK` is `(time_source = 'edited') = (original_effective IS NOT NULL)`.**
   Both directions. `'entered'` with a non-null `original_effective` is refused, and so is `'edited'`
   with a null one. `addNote` writes `'auto'` or `'entered'` and always a `NULL`
   `original_effective`; there is no edit verb on `notes` in this task, and adding one means going
   through `RecordedTime.editedTo`, never through a bare `UPDATE`.
4. **`notes`' subject `CHECK` is `>= 1`; `media_assets`' is `= 1`.** A note may hang off a ewe **and**
   a lambing at once — the same observation belongs to both. A media asset belongs to exactly one
   thing. They are neighbouring tables in the same file with different sums, and `care_events` and
   `treatments` use `= 1` while `reminders` uses `<= 1`. Copy each from `03 §5.11`, never from the
   table above it.
5. **`CHECK (length(trim(body)) > 0)` collides with *"the row is created on screen entry, not on
   exit"* and the collision is real.** A note with no body is unstorable, so the row cannot exist
   before there is text. The resolution is **not** a draft: the note is its own committed write, made
   when the text is committed, and every subsequent change is another committed write. What is
   forbidden is accumulating the body in a controller field until Done — that is a draft with a
   different name, and `00-README` §2.4 forbids it. The exact interaction belongs to the screens
   (N16, N26); this task's obligation is to make the empty case impossible rather than to swallow it.
6. **This is the first `notes` insert in the project's life, so it is the first firing of the FTS5
   trigger trio.** `notes_search_ai` writes `search_docs` with `subject_kind = 'note'`,
   `title = 'note'` and `body = notes.body`. `search_docs.title` and `.body` are `NOT NULL` while every
   source column is nullable, so every value a trigger writes is wrapped in `COALESCE(…, '')`
   (`03 §9.2`). Miss it once and the insert aborts with a `NOT NULL` failure raised from a trigger
   nobody is looking at. §5.4 asserts the trigger fired **and** that `search_docs` holds a row — do
   not skip the second half, because a trigger that silently did nothing looks identical to a passing
   test.
7. **Nothing side-effecting goes inside the transaction.** No file write, no notification, no share
   sheet (`03 §5.14`, `01 §4.3`). `MediaStore.writeAtomically` runs **before** `attachPhoto` and
   outside it. That ordering is the whole content of `04 §4.5` and it is what T05 turns into a test;
   here it is what the verb's shape has to permit — a verb that took bytes instead of a relative path
   would make the correct ordering unwritable.
8. **`lib/data/` may not import `lib/domain/validation/` at all** (`layer.data_no_validation`, R53).
   This repository is structurally incapable of producing a `Warning`, which is §12.4 held as a layer
   rule rather than as discipline. `WriteCommitted.warnings` is populated by the **controller**, which
   runs the validators against the freshly-watched row. If you find yourself wanting to warn that a
   note's `occurred_at` is in the future, you are in the wrong file.
9. **`WriteOutcome` is not generic and `warnings` is not `flags`** (R3). Every verb here returns the
   bare `WriteCommitted()` that `_write()` produces. There is no `WriteOutcome<T>`.
10. **Ids cross the boundary; `int` does not** (R33). `EweId`, `LambId`, `LambingId`, `SeasonId` and
    `MediaAssetId` are extension types from `lib/domain/ids.dart`. Unwrap to `.value` only at the
    drift companion, and use `Value(x.value)` for the nullable foreign keys — a bare `x.value` on an
    absent subject writes `null` where drift meant *"leave it out"*, and `Value.absent()` and
    `Value(null)` are different things.
11. **`media_assets.sha256` is `NULL` in v1 and computing one is a dependency decision.** There is no
    hash package in decision-record §5, and nothing enters this project that is not in that table. If
    a content hash ever becomes necessary, `crypto` gets audited by c1's method first and the verified
    version is recorded in §5 — see `04 §6.6` for the dependency-free integrity check the backup uses
    instead.
12. **Do not add a seventh `ShedFailure` variant for a constraint violation.** A `CHECK` failure here
    means the gateway produced a path it should have been incapable of producing, or a caller passed
    two subjects. It arrives as `SQLITE_CONSTRAINT` (19), `shedFailureFrom` maps it to
    `UnexpectedFailure`, `_write()` logs it and the write returns `WriteFailed`. That is correct: it
    is a bug, not a condition a shepherd can act on, and `CONVENTIONS` §2.5 fixes the failure set at
    six. Also — **never put the exception's `message` into the log**, because SQLite messages echo the
    failing SQL and its bound values, which here are note text and tag numbers (decision #124).
13. **`_write()` re-throws programmer errors in debug.** Its `assert(e is! Error, …)` is what stops
    the catch-all turning a bad-state bug into a polite failure you never see. Do not soften it, and
    do not wrap a verb in a second `try`.
14. **`unknown_json` is restore's column, not this repository's.** Both tables carry it (N07-T06) and
    every verb here writes `NULL`. Populating it from a write path would make an export claim it
    round-tripped a field a newer build wrote, which it did not.
15. **`media_assets.kind` is a closed `CHECK`, not a `vocab_terms` foreign key** — `('photo','voice')`
    and no third value. Adding one is a migration, and the schema is frozen.
16. **There is no `save`, and the gate proves it.** `db.save_verb` bans `save\w*\(` under `lib/data/`.
    `addNote`, `attachPhoto`, `beginVoiceNote`, `completeVoiceNote` — event verbs, all four.
17. **A fourth-subject `attachPhoto` is not this task's to invent.** `04 §4.6` prints the lambing
    form, and the Lamb Card (`07 §7.3`) and Ewe Card will each need the same verb with a different
    subject. Add those in the epics that need them (N17, N27) rather than generalising the signature
    now against no caller; `CONVENTIONS` §2.13's canonical-signature list exists so that two documents
    cannot disagree, and one document currently names one shape.

### 5.4 The test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/data/note_repository_test.dart` | `'a note written now about an earlier event stores both times and labels the provenance'` | The anchor, all four facts. |
| | `'addNote with no occurredAt stores time_source auto and occurred_at equal to captured_at'` | The other factory. `RecordedTime.capture` sets both to `now`; `provenanceLabel` is *"recorded automatically"*. |
| | `'created_at, updated_at and captured_at are byte-equal on a fresh note'` | `appNow()` read once. The failure is a one-millisecond drift nobody notices until an export sorts oddly. |
| | `'addNote refuses an empty body and a whitespace-only body'` | `length(trim(body)) > 0`, both shapes. |
| | `'addNote accepts a note naming a ewe and a lambing at once'` | `>= 1`, the permissive direction. |
| | `'addNote refuses a note naming no ewe, lamb, lambing or season'` | `>= 1`, the other direction. |
| | `'inserting a note writes a search_docs row with subject_kind note and non-null title and body'` | The first firing of `notes_search_ai` in the project's life, and the `COALESCE` rule with it. |
| | `'deleting a note removes its search_docs row'` | `notes_search_ad`, and the `recursive_triggers` pragma that makes it fire at all. |
| | `'attachPhoto stores kind photo, the relative path, byte_size, and null sha256 and duration_ms'` | The whole row, column by column. |
| | `'attachPhoto refuses a row naming both a lambing and a lamb'` | `= 1`, which is a *different* sum from the table above it. |
| | `'attachPhoto with an absolute path returns WriteFailed and leaves no row'` | The rollback, and the failure type: `UnexpectedFailure`, not a new variant. |
| | `'two media_assets cannot share one relative_path'` | `uniqueKeys [{relativePath}]` — the retry path in T05 depends on it. |
| | `'beginVoiceNote inserts the row with byte_size 0 before any audio exists'` | 08 §4's ordering. A row that arrives on stop is an orphan the sweeper deletes. |
| | `'completeVoiceNote sets byte_size and duration_ms on the row keyed by relative_path'` | The pairing, without an id travelling. |
| | `'completeVoiceNote on an unknown relative_path writes nothing and returns WriteFailed'` | The one shape that would otherwise be a silent no-op. |
| | `'every verb returns WriteOutcome and none throws on a constraint failure'` | R32's closed set of two throwing verbs stays closed. |
| `test/domain/uk_zone/note_times_dst_test.dart` | `'a note occurring at 01:30 BST and captured at 06:00 GMT on 25 October 2026 stores a five-and-a-half-hour entryLag, not four and a half'` | `@Tags(['uk-zone'])`, `TZ=Europe/London`. The wall clock says 4 h 30; the instants say 5 h 30, and the instants are what is stored. Civil-time arithmetic is wrong here by exactly the amount that is hardest to notice. |
| | `'a note occurring in the ambiguous hour is stored exactly as entered and raises no warning'` | `07 §6.5`: the ambiguous hour is deliberately **not** warned about — the displayed time matches what the user typed, so nothing has been silently corrected from their point of view. |
| | `'a note occurring at 01:30 on 29 March 2026, an hour that does not exist locally, is stored unchanged'` | Spring forward. The repository cannot warn — it cannot import `lib/domain/validation/` — so it must store and not "fix". §12.4 as a layer rule. |

## 6. Constraints that bind this task

- **The five safety rules** — **§12.5** is held here at the *unrepresentable* level: `RecordedTime`'s private generative constructor plus the paired SQL `CHECK`s mean a row with a provenance the columns disagree with cannot be written, and `provenanceLabel` is an exhaustive switch that can never be empty. **§12.4** is held by `layer.data_no_validation`: this file cannot import a validator, so it cannot correct anything. A rule that drops to merely *documented* has been deleted, whatever the prose says.
- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`. The one place this bends — a note body that cannot be empty — is gotcha 5, and it bends into *another committed write*, never into a draft.
- **One transaction, nothing side-effecting inside it** — `_db.transaction()` wraps SQL and only SQL. The file was written before the verb was called.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. It is a **record**, not an entry; the note's two times are its **provenance**, never its metadata.

## 7. Definition of Done

- [ ] `'a note written now about an earlier event stores both times and labels the provenance'` passes, and was seen to fail first for the stated reason
- [ ] `occurred_at` and `created_at` are both stored and both rendered
- [ ] the provenance label is exhaustive and never empty
- [ ] the media asset's path is relative
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
# 1. Red first, then green.
fvm flutter test test/data/note_repository_test.dart

# 2. Two honest instants across both clock changes.
TZ=Europe/London fvm flutter test --tags uk-zone

# 3. Nothing else in the data tier moved.
fvm flutter test test/data/

# 4. Watch the two rules that hold §12.4 fire, then revert.
printf "import '../domain/validation/warning.dart';\n" >> lib/data/note_repository.dart
dart run tool/check_policy.dart ; echo "exit=$?"   # POLICY [layer.data_no_validation] …, exit=1
git checkout -- lib/data/note_repository.dart

printf "Future<void> saveNote() async {}\n" >> lib/data/note_repository.dart
dart run tool/check_policy.dart ; echo "exit=$?"   # POLICY [db.save_verb] …, exit=1
git checkout -- lib/data/note_repository.dart

# 5. Nothing generated moved — no table, no column, no named query.
make gen && git status --short

# 6. Both gates.
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(data): NoteRepository with honest timestamps`

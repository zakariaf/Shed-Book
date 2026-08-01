# N15-T05 — Disk full at 3am

| | |
|---|---|
| **Epic** | [N15 — Media and notes](epic.md) · `00-README` §9 step 6 (1 of 5) |
| **Task** | 5 of 6 |
| **Depends on** | N15-T04 |
| **Commit** | one commit · `feat(data): keep the record, lose only the file, when the disk is full` |

## 1. Why this task exists

The write-ordering rule and the failure mapping that **keeps the record and loses only the
file**. A shed phone is full of photos in March; the record of a triplet lambing must survive a failed
photo write, not be rolled back with it.

`04 §4.5` states the ordering in four steps and step 2 is the one that matters: **the UI shows the
event as saved before the media is written at all.** *"The shepherd can walk away here and nothing is
lost."* A 700 KB file write is the largest thing this app ever does, and it is the only part of the
sequence a full phone can refuse; putting it after the ~500-byte row that a phone with 200 KB free can
still commit is what makes *"assume the phone dies"* true rather than aspirational.

The two directions the failure can take are not symmetric and both land here:

- **The photo path** writes the file first and the row second, so a failure leaves an orphan **file**
  and no row — `MediaSweeper.sweepOrphanFiles()` (N23-T03) trashes it.
- **The voice path** inserts the row first (08 §4), so a failure leaves a **row** and no file — which
  is what `missing_since` is for, and why the row is never deleted.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/04-migrations-media-backup-restore.md` | §4.5 | the four-step ordering, the persistent chip, and **Retry photo** costing one tap |
| `docs/engineering/04-migrations-media-backup-restore.md` | §4.6 | `attachPhoto` and the three things it deliberately does not do; the storage-warning table and the free-space rows that are **not implemented** |
| `docs/engineering/04-migrations-media-backup-restore.md` | §4.8, §4.9, §5.2 | media is moved to `.trash/`, never deleted; deleting a row because the file is gone is a named anti-pattern; `missing_since` goes back to `NULL` when the file reappears |
| `docs/engineering/01-architecture.md` | §5.2, §5.3, §5.4 | `WriteOutcome`; `ShedFailure`'s six variants and `MediaWriteFailed`'s unwritten body; `shedFailureFrom`'s `DriftRemoteException` unwrap; *"a gateway failure never rolls back the SQL"* |
| `docs/engineering/01-architecture.md` | §5.3 note | **never** put a SQLite exception's `message` in a log or a `userMessage` — decision #124 |
| `docs/engineering/CONVENTIONS.md` | §2.5, §5.1, §5.3, R4, R8 | the failure set is six and closed; `shedFailureFrom(Object)` is the one mapping site; **`flag` is a banned word** (gotcha 8) |
| `docs/engineering/12-testing.md` | §4.4 | `mocktail` for **ordering across two seams** — which is exactly the assertion this task needs |
| `docs/skills/02-build-manifest.md` | §4.1 (P2) | there is no SnackBar; the failure renders on the record, not over it |
| `shed-book-spec.md` | §5, §12.4 | assume the phone dies; never silently destroy the user's things |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-bootstrap-and-errors` | `shedFailureFrom` is its subject, and *what the shepherd is told* is the whole of the difference between `DiskFull` and `MediaWriteFailed` |
| `shed-write-path` | the ordering that makes the record survive, and the rule that a gateway failure never rolls back committed SQL |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/media_failure_test.dart`
- **Test** — `'a full disk loses the photo and keeps the lambing record'`
- **Assertion, spelled out** — commit a lambing through `beginLambing`, then drive the capture with a
  `FakeMediaStore` scripted to throw a `FileSystemException` carrying an out-of-space `OSError` on the
  next write. Assert **four** things: the `lambings` row is still selectable and unchanged;
  `media_assets` is empty; the outcome is `WriteFailed(DiskFull())`; and `failure.userMessage` names
  the **photo**, not the record — it must not contain the word *"saved"* in a sentence that could be
  read as *"your lambing was not saved"*, because that is what a shepherd will act on at 03:20.
- **Why it is red today** — nothing orders the writes, so a failed media write would roll back the record with it.

```bash
fvm flutter test test/data/media_failure_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — record first, media second, the mapping to a `ShedFailure` that says exactly what was
lost.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No schema step and no domain step: `missing_since` already exists (N07-T06) as
`integer().map(const InstantConverter()).nullable()()`, and `ShedFailure`'s six variants were declared
in N11-T01. **`MediaWriteFailed`'s `userMessage` is the one that was left as `{ /* … */ }` in
`01 §5.3`, and writing it is this task's.**

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/core/failure.dart` | Edit: write `MediaWriteFailed.userMessage`. It is the sixth of the six strings that are the only user-facing text outside the ARB in v1, and it must name the file and never the record. |
| 2 | `lib/data/failure_mapping.dart` | Edit: `shedFailureFrom` learns `FileSystemException`. Out of space → `DiskFull`; every other filesystem failure → `MediaWriteFailed`. The `DriftRemoteException` unwrap already there stays first. |
| 3 | `lib/data/media_store.dart` | Edit: `writeAtomically` deletes its own `.part` on failure, best-effort, and never throws a second exception doing it (gotcha 12). |
| 4 | `lib/data/note_repository.dart` | Edit: one new verb, `markMediaMissing(String relativePath)` — a plain drift `update()` on `mediaAssets`, **not** a `.drift` named query, so nothing regenerates (gotcha 9). |
| 5 | `test/support/fake_media_store.dart` | Edit: a scripted failure — `failNextWriteWith(Object error)` — so every screen test above this seam can exercise the chip without a real full disk. |
| 6 | `test/data/media_failure_test.dart` | **New.** The anchor plus §5.4's cases. |
| 7 | `test/domain/uk_zone/note_times_dst_test.dart` | Edit: the retry-across-the-fallback case. |
| 8 | `lib/core/db/connection.dart` | Read, **not edited**. Confirm `PRAGMA temp_store = MEMORY` is present (R13, N07-T01); it removes a whole class of `SQLITE_FULL` that fires *with* free space on the main partition. A second pragma site is a defect. |

### 5.2 The signatures

```dart
// lib/core/failure.dart — the sixth userMessage. Plain, non-technical,
// actionable, read at 3am by someone holding a lamb. It says what was lost and
// what still exists, in that order, because the second half is the reassurance.
final class MediaWriteFailed extends ShedFailure {
  const MediaWriteFailed();
  @override
  String get userMessage =>
      'The photo could not be written. Your record is safe. '
      'Free some space and attach it again from the ewe card.';
}
```

```dart
// lib/data/failure_mapping.dart — one function, one mapping site (R4).
// The DriftRemoteException unwrap stays first: drift_flutter runs SQLite on a
// background isolate, so `on SqliteException` never matches an unwrapped throw.
ShedFailure shedFailureFrom(Object error) {
  final e = error is DriftRemoteException ? error.remoteCause : error;
  final s = StackTrace.current;
  return switch (e) {
    SqliteException(:final resultCode, :final extendedResultCode) => /* unchanged */,
    // NEW. A file write is not a SQLite write, and today it falls through to
    // UnexpectedFailure — "Something went wrong and nothing was saved" — which
    // is wrong twice over: the record WAS saved, and the app DOES know what
    // happened. Classify on OSError.errorCode; see gotcha 4 before typing a
    // number.
    FileSystemException(:final osError) =>
        _isOutOfSpace(osError) ? const DiskFull() : const MediaWriteFailed(),
    _ => UnexpectedFailure(e, s),
  };
}
```

```dart
// lib/data/note_repository.dart — the fifth verb.
/// The file is gone and the row stays. 04 §4.9: deleting the row "makes the
/// app lie by omission". The same column is cleared back to NULL by
/// MediaSweeper.sweepMissingFiles() if the file reappears (04 §5.2), because
/// "it is here now" is also true.
Future<WriteOutcome> markMediaMissing(String relativePath);
```

The four steps, from `04 §4.5`, which is what the ordering test asserts:

| Step | What | Where it runs |
|---|---|---|
| 1 | Commit the event row (~500 bytes; succeeds on a phone with 200 KB free) | `LambingRepository.beginLambing` — N14-T02 |
| 2 | The UI shows the event as saved. **The shepherd can walk away here.** | `confirmSaved` — N14-T04 |
| 3 | Compress and write the media to `<relative>.part`, then rename | `MediaStore.writePhoto` / `VoiceRecorder.start` — T02, T03 |
| 4 | Commit a second, tiny transaction inserting the `media_assets` row | `NoteRepository.attachPhoto` — T04 |

### 5.3 The details that are easy to get wrong

1. **`on SqliteException catch (e)` compiles and never matches.** `drift_flutter` runs SQLite on a
   background isolate, so the exception arrives wrapped in a `DriftRemoteException`. `shedFailureFrom`
   unwraps once and then classifies. This is `04 §4.6`'s first named bug and it is invisible in
   review, because the clause is syntactically perfect.
2. **A `FileSystemException` is not a `SqliteException` and today produces the wrong sentence.** It
   falls through to `UnexpectedFailure`, whose message is *"Something went wrong and nothing was
   saved. Try again."* Both halves are false here: the record was saved, and the app knows exactly
   what failed. Extending the mapping is the smallest change that makes the app honest.
3. **`DiskFull` versus `MediaWriteFailed` is the same honesty rule that separates `DiskFull` from
   `StorageWriteFailed`.** `01 §5.3`'s comment on `StorageWriteFailed` is the model: *"The app knows
   the write did not land and does NOT know why. Saying 'you are out of space' here would be the app
   asserting something it cannot see — the same class of error safety rule 4 exists to prevent, aimed
   at the user instead of at the record."* Only an out-of-space `errno` earns `DiskFull`.
4. **Do not hard-code an `errno` from memory.** Read `OSError.errorCode` on a real Android device and
   a real iPhone with a genuinely full container, and write the constant with the platform it came
   from beside it. A container that is full for quota reasons rather than device reasons reports a
   different code on Darwin, and mapping it to *"free some space"* sends the shepherd to delete photos
   that will not help. When in doubt the safe classification is `MediaWriteFailed`, which claims
   nothing.
5. **Never roll back the record when the media fails.** `01 §5.4`: *"A gateway fails … returns its own
   small result to the repository; **never** rolls back the SQL, which is already committed and is the
   fact that matters."* The temptation is a single transaction spanning steps 1–4, which reads tidier
   and loses a triplet lambing because a phone was full.
6. **Never delete a `media_assets` row because its file is gone.** `04 §4.9` lists it as an
   anti-pattern with the reason: it *"makes the app lie by omission"*. *"Photo taken 14 March 03:22 —
   file no longer on this phone"* is a true and useful statement. It is spec §12.4 applied to bytes,
   and the same rule is why deleted media is **moved to `.trash/<yyyy-MM-dd>/`** and purged after 30
   days rather than removed.
7. **`missing_since` is only reachable on the voice path, and that asymmetry is deliberate.** The
   photo path writes the file before the row, so a failure leaves no row to mark — it leaves an orphan
   file, which `sweepOrphanFiles()` trashes. The voice path inserts the row at `start()`, so a failure
   leaves a row whose file never materialised. Marking that row is what lets the ewe card render *"not
   on this phone"* immediately instead of at the next launch's sweep.
8. **`04 §5.2` spells the query `flagMediaMissing` and the counter `rowsFlaggedMissing`, and
   `CONVENTIONS` §5.1 bans the word `flag`.** *"**warning** (`List<Warning>`, spec §12.4) — Never:
   **flag**, issue, problem, validation error"*, and `flags` is on §5.3's absolute list. CONVENTIONS
   is BINDING on words and outranks 04 here. This task is the first that would type either name, so it
   picks one and records it: **`markMediaMissing`**. Raise the query and counter names for N23-T03 in
   the PR body under the amendment rule — the concept there is *"the file is missing"*, not a warning,
   so either CONVENTIONS carries an explicit exception or 04's two names change.
9. **Use drift's `update()`, not a new `.drift` named query.** `04 §5.2` calls
   `_db.flagMediaMissing(asset.id, appNow())`, which is a named query in `queries.drift` — and adding
   one regenerates `database.g.dart`. The `codegen` job's whole contribution to this epic is proving
   that **nothing generated moved**; spend that only when a named query is genuinely needed, which is
   N23's sweep over every row, not this one row by its unique path.
10. **Do not implement the two free-space warning rows.** `04 §4.6`'s table has *"device free < 500
    MB"* and *"< 100 MB"*, and both need ~20 lines of platform channel (`StatFs.getAvailableBytes()` /
    `NSFileManager.attributesOfFileSystem`). `disk_space_plus` is **rejected** — unverified uploader,
    decision-record §5.3. Until the channel exists the rows are not implemented and the Diagnostics
    screen **says so** rather than showing a wrong number. When it does land,
    `ios/Runner/PrivacyInfo.xcprivacy` gains the `E174.1` reason code **in the same commit** (#93):
    shipping the channel and forgetting the manifest is an App Review finding.
11. **There is no SnackBar, and there is no modal on Quick Entry.** P2 removed `showSnackBar(` from
    `feedback.dart` itself (N14-T04), so `showFailure` renders on the record — a persistent,
    dismissible chip reading *"Photo not saved — storage full"* with **Retry photo** on the ewe card.
    `04 §4.5` is explicit: *"Never a modal on Quick Entry (spec §5)."*
12. **`writeAtomically` should remove its own `.part` on failure, and must not turn that into a second
    failure.** On a full disk the staging file is holding the last bytes the shepherd has. Wrap the
    cleanup in its own `try`/ignore: if the delete also fails, the write's original failure is still
    the one that gets reported, and `sweepOrphanFiles()` is the backstop that deletes stray `.part`
    files anyway.
13. **The retry costs one tap because the controller holds the in-memory record and does not navigate
    away** (`04 §4.6`) — not because anything retries automatically. An automatic retry against a full
    disk is a loop, and a loop at 03:20 is a flat battery.
14. **`_write()`'s `assert(e is! Error)` is load-bearing and must not be softened.** A
    `FileSystemException` is not an `Error`, so the disk-full path returns `WriteFailed` cleanly. A
    `StateError` from `FakeMediaStore`'s R62 tripwire **is** an `Error` and will throw loudly in
    debug — which is the intent, and is how you find out a test wired the fake in wrong rather than
    watching it pass for the wrong reason.
15. **Never log the exception's `message`.** SQLite messages echo the failing SQL and sometimes its
    bound values — note text, tag numbers, batch numbers. Log `resultCode` and `extendedResultCode`
    plus a statement identifier you control (decision #124), through `LocalLog`, which is a local file
    and never a network sink.

### 5.4 The test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/data/media_failure_test.dart` | `'a full disk loses the photo and keeps the lambing record'` | The anchor, all four assertions. |
| | `'the record is committed before the media write is attempted'` | `verifyInOrder` across two seams — `12 §4.4` names this as the case `mocktail` exists for. Reverse the order and the anchor still passes; this is the test that would not. |
| | `'the failure names the photo and never claims the record was lost'` | Read `userMessage` and assert on the sentence. The one string a shepherd acts on at 03:20. |
| | `'an out-of-space FileSystemException maps to DiskFull and every other one maps to MediaWriteFailed'` | Gotcha 4, both arms, with the observed `errorCode` recorded beside the platform it came from. |
| | `'SQLITE_FULL wrapped in a DriftRemoteException still maps to DiskFull'` | The unwrap, on the SQL side. Delete the unwrap and this is the only test that notices. |
| | `'SQLITE_IOERR maps to StorageWriteFailed and its message does not say out of space'` | The existing honesty rule, re-asserted because this task is editing the file that holds it. |
| | `'a media write that fails at step 4 leaves an orphan file and no row'` | The photo asymmetry. The file is the sweeper's; nothing is marked. |
| | `'a voice note whose file never materialises leaves the row and marks it missing'` | The voice asymmetry, and the only path `missing_since` is reachable from in this epic. |
| | `'a row with missing_since set is still selectable, still carries its subject, and was not deleted'` | `04 §4.9`'s anti-pattern, as an assertion. |
| | `'markMediaMissing on an unknown relative_path writes nothing and returns WriteFailed'` | The silent-no-op shape. |
| | `'a retry after space is freed attaches the photo without re-entering the event'` | The one-tap recovery, end to end — and the reason `uniqueKeys [{relativePath}]` matters, because the retry mints a **new** relative path rather than reusing the failed one. |
| | `'writeAtomically removes its .part on failure and reports the original error, not the cleanup error'` | Gotcha 12. Two failures, one message. |
| | `'no free-space query exists anywhere in lib/'` | Gotcha 10, held as an assertion so a helpful future contributor has to argue with a test rather than with a comment. |
| `test/domain/uk_zone/note_times_dst_test.dart` | `'a photo retried after the October fallback has a later created_at than the failed attempt, though both wall clocks read 01:30'` | `@Tags(['uk-zone'])`, `TZ=Europe/London`. The retry is an hour later in real time and the same minute on the clock face; the stored instants must order correctly, or the ewe card shows the retry above the attempt it replaced. |
| | `'missing_since written in the repeated hour is an instant, not a civil time, and compares correctly against one written before it'` | The same point on the column this task adds a writer for. |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`. Here that rule has a corollary with teeth: **steps 1 and 4 are two transactions, never one**, and step 3 is outside both.
- **§12.4, applied to bytes** — the app does not silently destroy the user's things. A row whose file is gone keeps its row; deleted media is moved to `.trash/` and purged after 30 days, or sooner if `.trash` exceeds 100 MB, oldest first.
- **§12.2's origination line, aimed at the user instead of at the record** — the app may report what it observed and may never assert a cause it cannot see. That is the whole reason `MediaWriteFailed` exists beside `DiskFull`.
- **No SnackBar, no modal on the 3am path** — P2. The failure is a persistent, dismissible chip on the record, with the retry one tap away on the ewe card.
- **Offline** — no network path may be added. G2 and G3 stay green; nothing in a failure path reports anything anywhere, and `LocalLog` writes a local file with a 256 KB cap and one rotation.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name — and, in this task specifically, **no `flag`** (gotcha 8).

## 7. Definition of Done

- [ ] `'a full disk loses the photo and keeps the lambing record'` passes, and was seen to fail first for the stated reason
- [ ] the record survives a media failure
- [ ] the failure names the file, not the record
- [ ] `missing_since` is set so the sweeper can reconcile later
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
# 1. Red first, then green.
fvm flutter test test/data/media_failure_test.dart

# 2. The retry across the October fallback.
TZ=Europe/London fvm flutter test --tags uk-zone

# 3. The mapping change did not disturb the SQL side.
fvm flutter test test/data/

# 4. Confirm the pragma that removes a class of SQLITE_FULL is already there,
#    in exactly one place.
grep -rn "temp_store" lib/ | wc -l        # expect: 1, in lib/core/db/connection.dart

# 5. Nothing generated moved — markMediaMissing is a drift update(), not a
#    named query.
make gen && git status --short

# 6. Both gates.
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(data): keep the record, lose only the file, when the disk is full`

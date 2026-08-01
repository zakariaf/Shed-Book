# N15 — Media and notes

| | |
|---|---|
| **`00-README` §9 step** | 6 (1 of 5) |
| **Depends on** | N14 |
| **Size** | M |
| **Was** | E12 |
| **Branch** | `epic/n15-media-and-notes` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `codegen` · `test` |

## Goal

The three capture seams — `MediaStore`, `CameraService`, `VoiceRecorder` — the repository that writes
`notes` and `media_assets`, the write ordering that keeps the record when the file is lost, and
`ShedPhoto`. Behind all of it one rule: **only a relative path is ever stored**, and the database
physically refuses anything else.

## Why this epic sits here

`00-README` §9 puts N15 at the head of step 6 — *"The rest of the 3am path: Lambing Entry, Lamb Card,
Foster, Pen Board — plus the one 60 s ticker. These are variations on machinery step 5 already
built."* This epic is the machinery the *rest* of step 6 varies on. `07-screens.md` §6.4 costs
*"Note / voice note / photo — 1 tap each"* on Lambing Entry and §7.3 costs *"Note / photo — 1 each"*
on the Lamb Card. Neither screen can spend that tap against a seam that does not exist, and the layer
rules forbid either of them from constructing a `File` (`layer.features`) or importing `image_picker`
(`layer.plugin_image_picker`) to get around it.

Two upstream facts make it possible now and not earlier:

- **The columns already exist and are frozen.** `notes` and `media_assets` landed in
  [N07-T06](../N07-the-schema-and-the-freeze/N07-T06-the-ancillary-cluster-and-unknown-json.md) with
  `relative_path`'s three `CHECK`s (`CONVENTIONS` R62) and `notes.occurred_at` distinct from
  `created_at` (R37), and the snapshot was written in N07-T08. **This epic writes into that schema and
  never changes it.**
- **The write path exists.** N14 landed `WriteController.guard()`, `feedback.dart` and the two
  throwing verbs. `NoteRepository` is the fourth repository to use `_write()`; it invents nothing.

It sits *before* N16 because Lambing Entry attaches media, and *after* N14 because the receipt it
attaches to is N14's.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/04-migrations-media-backup-restore.md` | §1 item 3, §4.1–§4.9 | the media layout, `MediaStore`'s printed body, the relative-path rule, capture, write ordering, disk full, the storage budget, the anti-pattern table |
| `docs/engineering/04-migrations-media-backup-restore.md` | §5.1–§5.4 | the two sweeps this epic must leave reachable — `MediaSweeper` itself is N23-T03 |
| `docs/engineering/08-platform-integration.md` | §1.1–§1.2 | the gateway rule, the confinement table and the nine `layer.plugin_*` rule ids |
| `docs/engineering/08-platform-integration.md` | §3.1–§3.3, §4 | `CameraService`, EXIF and the budget; `VoiceRecorder`, AAC-LC, the cap and the level meter |
| `docs/engineering/08-platform-integration.md` | §8.2, §8.3, §9 | who asks for camera and microphone and exactly when; `RECORD_AUDIO`; the `media.*` gate rows |
| `docs/engineering/03-data-model-and-schema.md` | §5.11, §5.14, §9.2 | the two tables verbatim, `NoteRepository`'s ownership, the FTS5 trigger that fires on a note insert |
| `docs/engineering/01-architecture.md` | §4.2, §5.2–§5.4 | event verbs, `WriteOutcome`, `ShedFailure`, `shedFailureFrom`, `_write()` |
| `docs/engineering/06-design-system.md` | §4.7, §12 | `ShedPhoto` is the only sanctioned `ColorFiltered`; its row in the component inventory |
| `docs/design/indelible.md` | §4.2, §4.4, §7.3 | the ruled cell — 2px rules, no radius, no shadow, 64 px rows |
| `docs/engineering/12-testing.md` | §4.1–§4.2, §5.1 | three of the seven hand-written fakes and the override list they join |
| `docs/research/00-tech-decisions.md` | §5 | the only source of `image_picker` 1.2.3 · `flutter_image_compress` 2.5.1 · `record` 7.1.1 · `path_provider` 2.1.6 · `uuid` 4.6.0 |
| `shed-book-spec.md` | §7.2, §12.4, §12.5 | the free-text note and the optional voice note; never silently correct; honest timestamps |

## Tasks

| Task | One line | Depends on |
|---|---|---|
| [N15-T01](N15-T01-mediastore-relative-paths-and-nothing-else.md) | `MediaStore` — relative paths, and nothing else | N14-T07 · N07-T06 |
| [N15-T02](N15-T02-cameraservice-over-image-picker.md) | `CameraService` over `image_picker` — resized, re-encoded, EXIF dropped | N15-T01 |
| [N15-T03](N15-T03-voicerecorder-over-record.md) | `VoiceRecorder` over `record` — AAC-LC, capped in the gateway | N15-T02 |
| [N15-T04](N15-T04-noterepository-notes-and-media-assets.md) | `NoteRepository` — `notes` and `media_assets`, with two honest times | N15-T03 |
| [N15-T05](N15-T05-disk-full-at-3am.md) | Disk full at 3am — keep the record, lose only the file | N15-T04 |
| [N15-T06](N15-T06-shedphoto-a-ruled-cell-never-a-thumbnail-grid.md) | `ShedPhoto` — a ruled cell, never a thumbnail grid | N15-T05 |

The chain is linear, and for one reason: T01–T03 each add a fake to `test/support/` **and a parameter
plus an override to `shedContainer()` in `test/support/harness.dart`** (12 §5.1, the rule set in
[N12-T05](../N12-the-di-root-settings-the-ticker-and-the-harness/N12-T05-testsupport-pumpapp-device-and-seedsdart-and-nothing-else.md)).
Three of them in flight at once is a merge conflict in the one file every widget test in the project
builds through.

## What is observably true when this epic merges

Run each of these against the merged `main`. Every one is a claim a developer or the owner can check.

1. **The database cannot hold an absolute path, and the gateway cannot produce one.**
   `fvm flutter test test/data/media_store_test.dart` — the iOS-shaped absolute path
   `/var/mobile/Containers/Data/Application/<uuid>/Library/Application Support/media/2026/03/x.jpg`
   is refused by the `CHECK`, and every string `newRelativePath()` returns for a year of simulated
   capture dates satisfies all three `CHECK`s.
2. **A half-written photo is never a record's attachment.** Kill the write between `writeFrom` and
   `rename` and what is on disk is a `.part` file that no row points at — which
   `MediaSweeper.sweepOrphanFiles()` (N23) deletes, because a `.part` file was never referenced.
3. **A captured photo is 2048 px on its longest edge, under 900 KB, and carries no EXIF.**
   `test/data/camera_service_test.dart` reads the output bytes back and asserts all three. There is
   no GPS in a photo this app stores.
4. **A photo the OS killed us for is recovered, and says so.** `pick()` asks `retrieveLostData()`
   first and returns `recovered: true`, so the attach slot can print *"Recovered from your last
   photo"* instead of silently attributing one record's photo to another.
5. **A recording is AAC-LC in an MPEG-4 `.m4a` on both platforms, and stops itself.**
   `test/data/voice_recorder_test.dart` reads the container's `ftyp` brand, and the cap fires from the
   gateway's own one-shot `Timer` with the UI absent entirely.
6. **A note written at 07:00 about 03:20 stores both times and labels which is which.**
   `test/data/note_repository_test.dart` — `occurred_at` 03:20, `created_at` 07:00,
   `time_source = 'entered'`, `provenanceLabel` *"time entered by you"*, never empty.
7. **A full disk loses the photo and keeps the lambing.**
   `fvm flutter test test/data/media_failure_test.dart` — the `lambings` row is still selectable, the
   failure is `DiskFull`, and its `userMessage` names the file, not the record.
8. **`ShedPhoto` renders as a ruled cell.** No `Card`, no `BoxShadow`, no `GridView`, no
   `BorderRadius`, one `ColorFiltered` and only in the tinted palettes; a row whose file is gone
   renders *"file no longer on this phone"* rather than a broken-image glyph.
9. **Three of the seven fakes exist and every widget test in the project already builds with them.**
   `grep -c overrideWithValue test/support/harness.dart` moves from 0 to 3.
10. **Nothing generated moved.** `make gen && git status --short` prints nothing: this epic adds no
    table, no column and no named query.

**Demoable, on a phone:** attach a photo and a voice note to a lambing, force-quit, delete and
reinstall the app from Xcode so iOS re-issues the container UUID, restore the container, and both
still open — because only `2026/03/<uuid>.jpg` was ever stored.

## The pull request, concretely

**Cut the branch from a green `main`.**

```bash
git switch main && git pull --ff-only
make check && make test          # main must be green BEFORE you branch
git switch -c epic/n15-media-and-notes
```

**One commit per task, T01 → T06, in order.** For each: write the anchor test named in the task's §4,
run it, watch it fail *for the stated reason*, make it pass, then `/simplify` → `/code-review` →
`/shed-code-review` → `git commit` with the exact message in the task's header. No task in this epic
takes an exception to one-commit-per-task.

**Open the PR after T06.**

```bash
git push -u origin epic/n15-media-and-notes
gh pr create --base main --title "N15 — media and notes"
gh pr checks --watch
```

Answer the five §12 questions that `.github/pull_request_template.md` (N01-T07) puts in the body
verbatim. **§12.5 and §12.4 are the two that carry weight here**: name `notes.occurred_at` versus
`notes.created_at` in your own words, and say why a `media_assets` row is never deleted when its file
goes missing.

**Wait for the pipelines. Three jobs run on this epic; each proves something different.**

| Job | Runner | What it runs | What it proves for N15 |
|---|---|---|---|
| `gate` | `ubuntu-latest` | toolchain pin vs `.fvmrc` · `flutter pub get` · `tool/check_policy.dart` (**G2 + G3**) · `dart format --set-exit-if-changed` · `flutter analyze --fatal-infos --fatal-warnings` · the ATS text check | The three plugin imports are each confined to one file (`layer.plugin_image_picker`, `layer.plugin_record`, `layer.plugin_flutter_image_compress`); `getApplicationSupportDirectory()` appears only in `media_store.dart` and `connection.dart` (`layer.path_provider`); no `File(` under `lib/features/` (`layer.features`); `AudioEncoder.opus` and `keepExif: true` are absent (`media.opus`, `media.keep_exif`); no `DateTime.now(` in path construction (`time.dart_clock`); no raw hex in `ShedPhoto` (`token.raw_color`) |
| `codegen` | `ubuntu-latest` | `build_runner build` + `drift_dev make-migrations` + `git diff --exit-code` over `lib/`, `drift_schemas/`, `test/drift/generated/` | **That nothing moved.** This epic adds no table, no column, no `.drift` query. A diff here means someone reached for the schema, and the schema was frozen at N07-T08. It also catches a stale `lib/l10n/app_localizations*.dart` after T06 adds ARB keys |
| `test` | `ubuntu-latest` **+ `libsqlite3-dev`** | `flutter test -P ci-fast` randomised · `TZ=Europe/London flutter test --tags uk-zone` · `TZ=Pacific/Chatham flutter test test/domain --exclude-tags uk-zone` · coverage artefact (reported, never gated) | Every `CHECK` in `media_assets` executed against **real** SQLite, the DST-hour media-shard cases under `test/domain/uk_zone/`, and the three new fakes wired into every widget test that already existed |

**The `android` job does not exist yet.** It is
[N31-T03](../N31-platform-artefacts-g1-g4-and-g5/N31-T03-toolassert-permissionssh-g1-the-android-job-and-the-g4-archi.md).
Until it does, **G1 cannot see that this epic put `android.permission.RECORD_AUDIO` into the merged
manifest** — `record_android` merges it the moment `package:record` is first imported (08 §8.3). It is
an expected entry and it is already on decision-record §3.3's list, but nothing in CI will confirm
that and nothing else was merged with it. The compensating control is manual, belongs in the PR body,
and is one command:

```bash
fvm flutter build appbundle --release
grep -c 'uses-permission' build/app/outputs/logs/manifest-merger-release-report.txt
```

**Merge with a merge commit, not a squash.**

```bash
gh pr merge --merge --delete-branch
```

Six commits, each with its own red-then-green anchor, are the evidence that the TDD rule was
followed. A squash deletes it.

**Then, and only then, cut N16.**

```bash
git switch main && git pull --ff-only
make check && make test          # main green after the merge
git switch -c epic/n16-lambing-entry
```

## Risks, and what is irreversible

> ### ⚠ A stored absolute path is `04 §1`'s third irreversible thing, and it never reproduces on the developer's phone.
>
> On iOS the data container is `/var/mobile/Containers/Data/Application/<UUID>/…` and that UUID is
> **not stable** — [flutter/flutter#23957](https://github.com/flutter/flutter/issues/23957) reports
> three different container UUIDs across successive launches of the same app. An absolute path dies
> after an app update, after a device restore, after every re-install from Xcode, and after a
> device-to-device transfer. **On Android the path happens to be stable, which is exactly why this bug
> ships**: it is green on the developer's Android phone every single time.
>
> Nothing in this epic can add a `CHECK` to defend it — `media_assets`' three `CHECK`s were frozen
> into `drift_schemas/drift_schema_v1.json` at N07-T08, and a `CHECK` cannot be added by
> `ALTER TABLE` afterwards without the full table rebuild of `04 §2.6`, on the one table that points
> at the user's photographs. What this epic can do is make the gateway incapable of producing one, and
> that is T01's whole subject.

| Risk | Why it bites here | What holds it |
|---|---|---|
| **`kVoiceNoteMaxSeconds` ships at 120 and is later lowered to 60** | Raising a cap orphans nothing; **lowering one makes existing recordings unreproducible** (04 §4.4). Open question §7.1 #18 is the owner's and is still open | **Ship 60.** One constant in `lib/data/media_limits.dart`, referenced everywhere including the storage-budget test, so the owner's answer is a one-line change |
| `AudioEncoder.opus` looks like the modern choice | `record` containers Opus as **OGG on Android and CAF on iOS**. A backup made on an Android phone would not play after a restore onto an iPhone, which is the entire point of spec §7.9 | The `media.opus` gate row, plus a test that reads the container brand out of the bytes |
| `flutter_image_compress`'s `minWidth`/`minHeight` are **minimums, not caps** | Passing `2048/2048` may cap the *shorter* edge and leave the longer one above 2048, which is not decision #40 | **Unclosed by both owning documents** (04 §4.4, 08 §3.3). Measure on one portrait and one landscape frame from a real phone; ship the `max(width, height) <= 2048` assertion either way. Record the figure in `docs/perf/measurements.md` |
| `RECORD_AUDIO` enters the merged manifest with no CI job watching | The `android` job is N31. G1 is the only mechanism that reads a *merged* manifest, and it does not run yet | The manual `manifest-merger-release-report.txt` read above, in the PR body |
| A `media_assets` row is deleted because its file is gone | *"Photo taken 14 March 03:22 — file no longer on this phone"* is true and useful; deleting the row makes the app lie by omission. It is spec §12.4 applied to bytes | 04 §4.9's anti-pattern table; the sweep test in N23 asserts the row survives; T05's DoD requires `missing_since`, not a `DELETE` |
| A photo is stored in the database as a `BLOB` | `VACUUM INTO` copies the whole database, so the diagnostics snapshot becomes gigabytes; Android Auto Backup caps at 25 MB per app, so inline photos would silently kill the backup of the **records** | `check_policy` rule `db.blob_column`; and the schema is frozen, so there is nowhere to put one |
| The camera original is kept "just in case" | 1200 photos × 3 MB is **~3.6 GB per season**, against ~300 MB when downscaled at capture. It is 04 §4.7's named failure case and it is entirely self-inflicted | The output-size assertion in the capture test |
| `MediaStore` caches the media root across a restore | `_rootCache` is a per-run cache and is **deliberately never persisted**. A restore replaces the container; a persisted root is an absolute path with extra steps | T01's gotcha list, and a test that constructs two `MediaStore`s against two roots |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `codegen` · `test`
- [ ] `make gen` on a clean checkout leaves `git status --short` empty — this epic changes no generated artefact except `lib/l10n/`
- [ ] `git diff --stat main -- drift_schemas/` is empty: the schema was frozen at N07-T08 and this epic did not touch it
- [ ] `FakeMediaStore`, `FakeCameraService` and `FakeVoiceRecorder` exist, `implements` their gateway, carry the tripwires `12 §4.2` names, and are on `shedContainer()`'s override list
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`

## Demoable on merge

A photo and a voice note attach to a record, land under `<appSupport>/media/YYYY/MM/`, and
survive an app update **because only the relative path was stored**.

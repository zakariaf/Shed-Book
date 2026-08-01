# Restore, and the two orphan sweeps

Load when touching restore, import, or media on disk. `docs/engineering/04-migrations-media-backup-restore.md`
§5 and §7 are BINDING and carry the reasoning; this file is the operative sequence and the invariants.

## Contents

- [The rule](#the-rule)
- [The sequence — 16 steps, two of them destructive](#the-sequence--16-steps-two-of-them-destructive)
- [The confirmation screen](#the-confirmation-screen)
- [The four interrupted-restore outcomes](#the-four-interrupted-restore-outcomes)
- [Nine things a partial restore must never leave behind](#nine-things-a-partial-restore-must-never-leave-behind)
- [Sweep direction 1 — files with no row](#sweep-direction-1--files-with-no-row)
- [Sweep direction 2 — rows with no file](#sweep-direction-2--rows-with-no-file)
- [When the sweeps run](#when-the-sweeps-run)
- [Media after a restore](#media-after-a-restore)
- [What restore never does](#what-restore-never-does)

## The rule

**Replace everything, atomically, through one code path.** Import into a *new* SQLite file beside the
live one, validate it completely, and only then swap. Never merge; never offer merge. There is no
merge code, so there is no merge to accidentally expose.

`RestoreService` (`lib/data/restore_service.dart`) is the only file that renames the live database.
`tool/seed.dart` writes its fixtures through this same path, which is why
`test/fixtures/flock_400_3seasons.json` and `flock_15_at_cap.json` are committed backup files rather
than ad-hoc fixtures.

## The sequence — 16 steps, two of them destructive

Design it as if it will be run once, at 04:00, by an exhausted person on a new phone, with one file
and no second chance, because that is the only time anyone runs it.

| # | Step | Destructive |
|---|---|---|
| 0 | Entered from Settings ▸ Backup & Restore only. Runs through `WriteController.guard()` so a cold double-tap cannot start two restores. | no |
| 1 | Pick with `file_selector`; **copy immediately** to `<temp>/restore/incoming.json` — on Android the picked URI can be a one-shot grant. | no |
| 2 | Sniff the first 512 bytes. `{` → JSON. `PK\x03\x04` → refuse, "this looks like a photo archive". `SQLite format 3\0` → refuse, "this is a diagnostics copy, not a backup". Anything else → refuse. | no |
| 3 | Parse and validate `BackupHeader`: `format`, `formatVersion`, `schema ≤ kSchemaVersion`, `checksum`, `counts`. | no |
| 4 | Confirmation screen (below). | no |
| 5 | Delete stale `restore_staging/`; create `<appSupport>/restore_staging/shed_book.sqlite`, opened with `seedOnCreate: false` so `onCreate` builds today's schema with **no** first-run season. | no |
| 6 | Import in **one transaction**, parents before children in a fixed topological order, `PRAGMA defer_foreign_keys = ON` inside it — never `foreign_keys = OFF`, a no-op inside a transaction. Resolve each `*_uid` to the new integer id from a map built as parents insert. Skip and log entitlement rows. If the backup carries no season, `seedFirstRun` runs at the end of this same transaction — a restored database is never seasonless. | no |
| 7 | Validate staging **before any destruction**: per-table `COUNT(*)` equals `counts`; `PRAGMA foreign_key_check` returns no rows; `PRAGMA quick_check` is `ok`; one `app_settings` row; `current_season` resolves; rebuild FTS (`INSERT INTO search_fts(search_fts) VALUES('rebuild')`) and assert a probe query. | no |
| 8 | `PRAGMA wal_checkpoint(TRUNCATE)`, `close()`, then assert no `-wal`/`-shm` remains beside staging. A stale `-wal` next to a swapped-in main file is corruption. | no |
| 9 | `cancelAll()` on scheduled notifications, then close the live database. | reversible |
| 10 | Write the sentinel `<appSupport>/restore.pending` with `flush: true`. **The last non-destructive step.** | no |
| 11 | Rename live `shed_book.sqlite`, `-wal`, `-shm` into `restore_rollback/`. | **yes** |
| 12 | Rename `restore_staging/shed_book.sqlite` → `<appSupport>/shed_book.sqlite`. | **yes** |
| 13 | Delete the sentinel; delete `restore_staging/`. | no |
| 14 | `ref.invalidate(databaseProvider)` and pop to the root route. Every screen re-watches its own query; no cached pre-restore state exists anywhere. | no |
| 15 | After the first frame: `sweepMissingFiles()`, `sweepOrphanFiles()`, `reconcile()`, `PRAGMA optimize`. | no |
| 16 | Keep `restore_rollback/` until the next clean launch after one successful write, then delete. | no |

Steps 11 and 12 are two adjacent renames within one filesystem; the sentinel written at step 10 makes
the window between them recoverable. Every abort before step 11 leaves the live database untouched
and names its reason in one sentence a shepherd can act on.

## The confirmation screen

Two-step, never a gesture, both controls ≥ 60×60 pt. In this order: what is in the backup ("3 seasons,
412 ewes, 861 lambs, 145 treatments. Made on 14 Jul 2026 by Shed Book 1.1.0" — `d MMM y`, never
all-numeric, R60); what is on this phone now; the unhedged destruction sentence; the media sentence;
then a 60 pt "I understand — continue" and a 72 pt "Replace everything", disabled until the first is
taken and on the opposite side of the screen from Cancel.

**No typed-word confirmation.** A word to type is a keyboard, and this is the app that exists because
keyboards are hard with wet hands. This screen is the one place in the app that may look scary.

## The four interrupted-restore outcomes

`completeInterruptedRestore(Directory)` runs on every launch **before the database is opened**. There
are four reachable states, not two, and conflating them is how an app tells someone their records were
restored when they were not. The switch is over `(live.existsSync(), rollback.existsSync())`:

| State | Meaning | Outcome | What the app says |
|---|---|---|---|
| `(true, false)` | Crashed after the sentinel, before rename 11. Nothing was destroyed. | `notStarted` | "The restore did not start. Your records are unchanged." |
| `(false, true)` | Crashed between 11 and 12. Move the original back, **with both sidecars**. | `rolledBack` | The restore was reversed |
| `(true, true)` | Rename 12 completed; crashed before deleting the sentinel. Staging was fully validated at step 7. | `completed` | Success |
| `(false, false)` | Only reachable if the OS died mid-rename. Move staging in if it exists. | `completed` or `lostBothFiles` | The corruption screen |

`_moveInto` moves the main file **and** `-wal` and `-shm`, because step 11 moved all three and a main
file reunited with a stale `-wal` is corruption. `lostBothFiles` must be impossible to reach in a test
without deleting a file by hand; if the interrupted-restore test ever produces it, the swap ordering
has regressed. There is no "resume an interrupted restore" — the user picks the file again, which is
one tap.

## Nine things a partial restore must never leave behind

After any restore — completed, rolled back or aborted — none of these may exist:

1. A database containing rows from two different backups. *(Staging is a fresh file; the swap is a rename.)*
2. A `-wal` or `-shm` from the previous database beside the new main file. *(Step 8's checkpoint; step 11 moves all three.)*
3. Media rows pointing at absent files without `missing_since` set. *(Step 15's sweep.)*
4. Files in `media/` that no row references, silently deleted. *(The sweep trashes, never deletes.)*
5. The `restore.pending` sentinel. *(The recovery routine deletes it.)*
6. `restore_staging/`. *(Step 13, plus a launch-time sweep as a belt.)*
7. OS notifications scheduled from pre-restore data. *(`cancelAll()` at step 9, `reconcile()` at 15.)*
8. Any in-memory cache of pre-restore rows. *(Invalidating `databaseProvider`.)*
9. An entitlement that came out of a backup file. *(The importer skips it.)*

## Sweep direction 1 — files with no row

Causes: capture wrote the file and the process died before the attach transaction; a restore brought
files the new database does not reference; a `.part` file left by a killed write.

`MediaSweeper.sweepOrphanFiles()` walks the media root against one `SELECT` of known relative paths:

- skip anything under `.trash/`;
- **delete** a `.part` file — nothing ever referenced it;
- if the relative path is not known, `rename` it to `.trash/<YYYY-MM-DD>/<original relative path>`.

**Never delete a real file.** Return a `SweepReport`.

## Sweep direction 2 — rows with no file

Causes: the user wiped the container; an Android cloud restore that excluded `media/`; a records-only
JSON restore.

For every asset with `missing_since IS NULL`, resolve and stat the file; if absent, set `missing_since`
to `appNow()` inside one transaction. **Do not delete the row** — *"photo taken 14 March 03:22, file
no longer on this phone"* is true and useful, and deleting it makes the app lie by omission. A row
whose file reappears is un-flagged by the same sweep: set `missing_since` back to `NULL`, because
"it is here now" is also true.

## When the sweeps run

- **Never before the first frame.** Both run from a post-frame callback after the first real screen has
  rendered, chunked so no single microtask exceeds ~8 ms.
- Once per launch, and once after a restore completes. **Not on resume** — a 20-minute pocket gap
  creates no orphans.
- On the one shared `AppDatabase` instance, so statements queue behind writes. Never a second connection.
- **Reported, not announced.** Counts go to Settings ▸ Diagnostics; a sweep that trashes three files
  interrupts nobody.

## Media after a restore

The v1 backup carries no bytes, so after a records-only restore every media row is flagged
`missing_since` and the completion screen says exactly that: the records are back, the photos stay on
the phone that took them, and each one still shows in the record it belongs to marked "not on this
phone". An iOS iCloud device restore keeps the media and resolves the relative paths against the new
container root — that is the entire payoff for the relative-path rule (R62).

**Media is not importable in v1.** "Share photos from this season" hands files straight to the share
sheet, batched at 50 per share, labelled as a copy-out and not as a restorable backup. Do not design a
media ZIP until `ZipFileEncoder`'s incremental-write behaviour has been verified and recorded.

## What restore never does

Never merges. Never unlocks — the entitlement is never imported. Never runs from the 3am path. Never
touches `media/`, on success or on abort; the only thing that moves media is a sweep, and a sweep only
ever moves to `.trash`. Never leaves the user without an explanation.

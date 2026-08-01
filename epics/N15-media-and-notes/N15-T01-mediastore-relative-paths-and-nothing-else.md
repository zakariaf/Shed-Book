# N15-T01 — `MediaStore` — relative paths, and nothing else

| | |
|---|---|
| **Epic** | [N15 — Media and notes](epic.md) · `00-README` §9 step 6 (1 of 5) |
| **Task** | 1 of 6 |
| **Depends on** | N14-T07 · N07-T06 |
| **Commit** | one commit · `feat(gateway): MediaStore with relative paths only` |

## 1. Why this task exists

The media root under application support, `newRelativePath` (`media/YYYY/MM/`), `resolve`,
`writeAtomically`, and the **one irreversible rule**: only a relative path is ever stored, because an
absolute path breaks the first time iOS re-issues the container UUID on an app update — which is to say
on the first update after lambing.

`04 §1` lists four things you cannot undo and this is the third of them. The other three — the schema
snapshot, a released migration step, a restore — each have a harness, a matrix or a sentinel file
behind them. This one has nothing but the shape of a string. There is no server-side backfill, no
remote kill switch and no way to reach a phone that has never been online; a database full of
`/var/mobile/Containers/Data/Application/<stale-UUID>/…` is a database whose photographs are gone, and
the first person to see it will be a shepherd in March.

The defence is three deep and this task builds the middle layer. The three `CHECK`s (frozen at
N07-T08) make an absolute path unstorable. `resolve()`'s containment check makes an escaping path
unopenable. And `newRelativePath()` is the only producer of the string, so nothing user-authored
reaches the column at all — which is the layer that actually holds, because the other two only fire
after somebody has already made the mistake.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/04-migrations-media-backup-restore.md` | §1 item 3 | *"An absolute media path written to the database is dead the moment the app is updated on iOS"* — decision #40 |
| `docs/engineering/04-migrations-media-backup-restore.md` | §4.2 | the directory layout, the year/month shard, the filename rule, and why exports never go here |
| `docs/engineering/04-migrations-media-backup-restore.md` | §4.3 | `MediaStore`'s body printed in full — `root()`, `newRelativePath`, `resolve`, `writeAtomically` — and what each of the three `CHECK`s actually buys |
| `docs/engineering/04-migrations-media-backup-restore.md` | §4.9, §5.1 | the anti-pattern table, and the `.trash/` / `.part` conventions the sweeper (N23-T03) depends on |
| `docs/engineering/03-data-model-and-schema.md` | §5.11 | `MediaAssets` verbatim — the three `CHECK`s, `uniqueKeys [{relativePath}]`, `missingSince` |
| `docs/engineering/08-platform-integration.md` | §1.1, §1.2 | `MediaStore` is one of the six gateways; `layer.path_provider` and `layer.plugin_flutter_image_compress` |
| `docs/engineering/CONVENTIONS.md` | §2.12, §3.1, R15, R47, R62 | the class and its file, `mediaStoreProvider`, `newUid()` as the one uuid call site, who owns capture, the three `CHECK`s |
| `docs/engineering/12-testing.md` | §4.2, §5.1 | `FakeMediaStore`'s recorded shape and its tripwire; the `shedContainer()` override list |
| `docs/research/00-tech-decisions.md` | §5 | `path_provider` **2.1.6**, `uuid` **4.6.0** — and the fact that `path` is not on the list |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | one class per plugin, one import site, one hand-written fake — and `path_provider` confined to two files |
| `shed-export-and-restore` | the relative path is what makes a backup restorable onto another phone; a restore replaces the container, and every absolute path with it |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/media_store_test.dart`
- **Test** — `'an absolute path is rejected by the relative_path CHECK'`
- **Assertion, spelled out** — insert a `media_assets` row whose `relative_path` is the real shape a
  naive implementation produces —
  `'/var/mobile/Containers/Data/Application/8F2A…/Library/Application Support/media/2026/03/019524f7-8a1c-7b3e-9f04-2c9a1e7d55b0.jpg'`
  — and assert it throws `SqliteException`. Then assert the positive half in the same test: for the
  same captured instant, `MediaStore.newRelativePath('jpg')` returns a string that inserts **without**
  throwing. The test is not about the column alone — N07-T06 already proved that. It is about the
  gateway being structurally incapable of producing anything the column would refuse.
- **Why it is red today** — nothing writes media, and the obvious implementation stores the absolute path the picker returned.

```bash
fvm flutter test test/data/media_store_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the gateway, the atomic write, and `FakeMediaStore` in `test/support/` — extending
`pumpApp`'s override list **in this commit**, per N12-T05's rule.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

There is **no schema step and no domain step** — `media_assets` was frozen at N07-T08 and this task
adds no value type. Say so in the commit body; `00-README` §8 asks for it out loud.

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/data/media_store.dart` | **New.** `final class MediaStore` — `root()`, `newRelativePath()`, `resolve()`, `writeAtomically()`. The only file in the app that knows where media bytes live, and (with `connection.dart`) one of exactly two permitted to call `getApplicationSupportDirectory()`. |
| 2 | `lib/data/providers.dart` | Edit: add `mediaStoreProvider`. A plain `Provider<MediaStore>`, keepAlive — **not** a `FutureProvider`, even though `root()` is async (gotcha 10). |
| 3 | `test/support/fake_media_store.dart` | **New.** `FakeMediaStore implements MediaStore`, backed by a `Map<String, Uint8List>` keyed by relative path, carrying the tripwire `12 §4.2` specifies. |
| 4 | `test/support/harness.dart` | Edit: `shedContainer()` gains `FakeMediaStore? media` and `mediaStoreProvider.overrideWithValue(media ?? FakeMediaStore())`. Its header comment loses N15's media entry from the "still to come" list. |
| 5 | `test/data/media_store_test.dart` | **New.** The anchor plus §5.4's cases, against `testDatabase()` and a `freshSupportDir()`. |
| 6 | `test/domain/uk_zone/media_shard_dst_test.dart` | **New.** `@Tags(['uk-zone'])`. The shard is a **local** civil month and the clocks change twice a year. |
| 7 | `test/support/harness_test.dart` | Edit: one case asserting `mediaStoreProvider` resolves to the fake, with no production override anywhere under `lib/`. |
| 8 | `tool/check_policy.dart` | **Confirm, and add only if absent.** `layer.path_provider` and `layer.plugin_flutter_image_compress` are N03's rows (08 §1.2), but this is the first task in the project with a real file for either to point at. Plant a violation, watch the rule fire, delete it. N03's table is documented as not closed; if a row is missing it lands here, with its proving case, in the same commit. |

### 5.2 The signatures

`04 §4.3` prints the body. These are the four public members and there are no others:

```dart
// lib/data/media_store.dart

/// The only type that knows where media bytes live.
/// lib/features/** never constructs a File. See 01-architecture.md.
final class MediaStore {
  /// The optional resolver exists for test/data/media_store_test.dart, which
  /// runs under flutter_test where the path_provider method channel does not
  /// answer. Production passes nothing. This parameter is a departure from
  /// 04 §4.3's printed class — see gotcha 1 — and is flagged in the PR body.
  MediaStore({Future<Directory> Function()? supportDirectory});

  /// Resolved fresh every run. Deliberately never persisted anywhere.
  Future<Directory> root();

  /// The ONLY string that ever reaches the database.
  /// Always POSIX-separated: "2026/03/019524f7-…-55b0.jpg".
  String newRelativePath(String extension);

  /// Defence in depth. The three CHECKs make an escaping path unstorable, but
  /// a resolver that *can* leave its root is not a resolver.
  Future<File> resolve(String relativePath);

  /// Write to "<target>.part", flush, then rename. Rename within one
  /// filesystem is atomic, so a reader never sees a half-written photo.
  Future<File> writeAtomically(String relativePath, List<int> bytes);
}
```

Wiring, in `CONVENTIONS` §3.1's spelling exactly:

```dart
// lib/data/providers.dart
final mediaStoreProvider = Provider<MediaStore>((ref) => MediaStore());
```

The three constraints the gateway's output must satisfy, restated in the SQL that enforces them
(`03 §5.11`, `CONVENTIONS` R62). These are already inside `drift_schema_v1.json` and **cannot be
added, removed or altered by this task**:

```sql
CHECK (relative_path NOT LIKE '/%')                                -- no absolute path
CHECK (relative_path GLOB '[0-9][0-9][0-9][0-9]/[0-9][0-9]/*.*')   -- YYYY/MM/<name>.<ext>
CHECK (relative_path NOT GLOB '*/*/*/*')                           -- exactly two separators
```

### 5.3 The details that are easy to get wrong

1. **`04 §4.3`'s printed body imports `package:path`, and `path` is not a direct dependency.**
   N00-T03's `pubspec.yaml` carries `path_provider`, not `path`; G2's allowlist (N03-T04) does not
   list it either. `import 'package:path/path.dart' as p;` therefore trips
   `depend_on_referenced_packages` from `flutter_lints` **6.0.0**, and `flutter analyze
   --fatal-infos` — `make check`'s third step and the `gate` job's last — goes red. Decide before you
   type:
   - **Recommended: do not import it.** `newRelativePath` is three string joins. `resolve` validates
     against one `RegExp` that is the Dart transcription of the three `CHECK`s —
     `RegExp(r'^\d{4}/\d{2}/[^/]+\.[^/]+$')` — and a string matching it cannot carry a `..` segment,
     because `..` is two characters and `[^/]+\.[^/]+` needs at least three. That is a *stronger*
     containment check than `p.isWithin`, and it is the same rule the database holds.
   - **The other way is a decision, not an edit.** Adding `path` to `pubspec.yaml` means adding it to
     decision-record §5 (the only source of a version number in this project) *and* a line to
     `tool/policy_allowlist.txt`, which `CLAUDE.md` names as a thing you never do to make a build
     green. Route it; do not do it quietly. N23-T03's `MediaSweeper` inherits whichever you pick, so
     write the answer into the file header.
2. **`GLOB`'s `*` matches `/` in SQLite, so `CHECK` 2 alone does not stop `2026/03/../../x.jpg`.**
   The third `CHECK` does: two separators are already spent on `YYYY/MM/`, leaving no further segment
   to traverse with. All three are load-bearing, none is redundant, and `test/policy/` asserts them off
   the committed schema JSON. If `/simplify` proposes folding them into one, refuse it and say why in
   the review.
3. **The shard is the *local* civil month, not the UTC one.** `appNow().local` — because `YYYY/MM` is
   a human-legible directory, not an instant. A photo taken at 00:30 BST on 1 April 2026 is
   `2026-03-31T23:30Z`; it belongs in `2026/04`, and a UTC shard files it under `2026/03`, silently
   disagreeing with the shepherd's calendar. §5.4 has the case.
4. **`newUid()` from `lib/core/db/uid.dart` is the only `package:uuid` call site in the app (R15).**
   Not `const Uuid().v7()` inline, not a second `Uuid` instance for filenames. UUID **v7** is the
   point: its time-ordered prefix means a directory listing sorts chronologically for free, which is
   what makes the orphan sweep's walk — and any hand-recovery from a device backup — tractable.
5. **The filename is never the tag and never a sequence number.** Tags get corrected, and a rename
   orphans the row. Sequence numbers collide after a restore, because restore renumbers `id` and the
   files came from another phone. Both are in `04 §4.2`'s rule list, and both look reasonable right up
   until the day they are not.
6. **`writeAtomically` must flush before it closes, and rename within one filesystem.** The staging
   file is `'${target.path}.part'` — a *sibling* of the target, which is what makes the rename a
   metadata operation rather than a copy. Writing into `getTemporaryDirectory()` and renaming into the
   media root crosses a filesystem on some Android devices, where `File.rename` degrades to
   copy + delete and stops being atomic. Create `target.parent` first, or the staging open throws
   `FileSystemException` on the first photo of a new month and never before.
7. **A `.part` file left by a killed write is not an error, and cleaning it is not this task's job.**
   `MediaSweeper.sweepOrphanFiles()` (N23-T03) deletes `.part` files outright — nothing ever
   referenced them — and moves every *other* orphan to `.trash/<yyyy-MM-dd>/<rel>` rather than
   deleting it. Add no cleanup here, and do not create `.trash/` here either.
8. **`_rootCache` is per-instance and is deliberately never persisted.** Caching the resolved root in
   `app_settings`, in a static, or anywhere on disk re-introduces the absolute path through the back
   door. It is the same bug with a longer fuse: it survives one update and dies on the next.
9. **`resolve()` is not redundant with the `CHECK`s and must not be simplified away.** The `CHECK`s
   run on write; `resolve()` runs on read, including on paths that arrived in a backup written by a
   different build of the app on a different phone.
10. **`mediaStoreProvider` is a plain `Provider`, keepAlive — not a `FutureProvider`.** `root()` is
    async but construction is not, and `CONVENTIONS` §3.1 spells it as a `Provider`. Making it async
    puts an `await ref.watch(...)` between the shepherd's thumb and the capture, on the 3am path, for
    a directory lookup that is one `stat`.
11. **Do not give `LambingRepository` a `MediaStore` parameter.** `CONVENTIONS` §3.1's note on
    `lambingRepositoryProvider` says *"takes `NotificationScheduler` + `MediaStore`"*, and `12 §3`
    constructs it with three arguments — but §2.13 and **R47** give every `media_assets` write to
    `NoteRepository`, and `MediaStore` is not a writer. Adding the parameter creates a field nothing
    reads. Leave `LambingRepository` and `lambingRepositoryProvider` untouched in this epic and raise
    the discrepancy in the PR body under the amendment rule: it is a naming-authority question, not a
    code change you are entitled to make.
12. **`FakeMediaStore` `implements`, never `extends`** (`12 §4.2`). When 04 or 08 changes a signature
    the fake must be a **compile error**, not a silent divergence. Its tripwire is R62's three `CHECK`s
    in Dart: throw a `StateError` naming the rule on an absolute path, on a backslash-separated path,
    and on a third `/`. A fake that quietly accepts what the database refuses is worse than no fake,
    because every widget test above it then passes for the wrong reason.
13. **Exports never live under the media root.** CSV, PDF and JSON go to `getTemporaryDirectory()` and
    straight into the share sheet (04 §4.2) — that directory is excluded from iCloud and from Android
    Auto Backup, so a stale export cannot inflate a user's backup. `pre_migration/`,
    `restore_staging/`, `restore_rollback/` and `diagnostics/` are **siblings** of `media/`, not
    children; this task creates none of them.
14. **`getApplicationSupportDirectory()`, never `getApplicationDocumentsDirectory()`** (decision #27).
    Documents is user-visible in the Files app, where a shepherd tidying up can delete
    `shed_book.sqlite`. It is also why `UIFileSharingEnabled` is deliberately unset (08 §8.4).

### 5.4 The test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/data/media_store_test.dart` | `'an absolute path is rejected by the relative_path CHECK'` | The anchor, both halves — the iOS container path throws, `newRelativePath()`'s output does not. |
| | `'newRelativePath returns YYYY/MM/<uuid v7>.<ext> with forward slashes only'` | The shape, and that the uid really is a v7: 36 characters, version nibble `7`. |
| | `'every path newRelativePath mints for the twelve months of 2026 inserts successfully'` | Twelve inserts. Catches a zero-padding bug in the month, which would emit `2026/3/…`, fail `CHECK` 2 — and do it in March, in production. |
| | `'2026/3/x.jpg, 2026/03/x, 03/2026/x.jpg and 2026/03/a/b.jpg are each refused'` | One near-miss per `CHECK`: unpadded month, no extension, wrong order, too deep. |
| | `'a backslash-separated path 2026\\03\\x.jpg is refused'` | `CHECK` 2 needs a literal `/`; the first `CHECK` alone lets this through. |
| | `'resolve refuses 2026/03/../../shed_book.sqlite'` | Containment — the one path that would let a photo overwrite the database. |
| | `'resolve returns a File under root() for a legal path, and root() is idempotent'` | The happy path, and that a second `root()` neither re-creates nor moves the directory. |
| | `'writeAtomically round-trips the bytes and leaves no .part file behind'` | The normal write. |
| | `'the target does not exist until the rename completes'` | Assert on the filesystem between `writeFrom` and `rename`: a torn file is never a record's attachment. |
| | `'writeAtomically creates the YYYY/MM directory on the first file of a month'` | `target.parent.create(recursive: true)`. The failure is a `FileSystemException` on the 1st of a month and on no other day. |
| | `'two MediaStores over two roots resolve one relative path to two different files'` | The whole point: the string is portable, the file is not. The restore case in miniature. |
| | `'FakeMediaStore throws naming R62 on an absolute path, a backslash path and a third separator'` | The tripwire fires, so every widget test above it inherits the rule. |
| `test/support/harness_test.dart` | `'shedContainer resolves mediaStoreProvider to FakeMediaStore, and lib/ contains no overrideWithValue'` | The override landed here, in this commit, per N12-T05. |
| `test/domain/uk_zone/media_shard_dst_test.dart` | `'a path minted at 00:30 BST on 1 April 2026 shards to 2026/04, not 2026/03'` | `@Tags(['uk-zone'])`, `TZ=Europe/London`. The instant is `2026-03-31T23:30Z`; the shard follows the shepherd's civil month. |
| | `'both 01:30s on 25 October 2026 shard to 2026/10 and mint two different uids'` | The ambiguous hour, 01:00–01:59 (owner ruling §7.0 #3). `01:30 BST` and `01:30 GMT` are an hour apart in UTC and identical on a wall clock: the shard must be insensitive to that, and the two filenames must still not collide. |
| | `'a path minted at 00:30 GMT on 1 January 2027 shards to 2027/01'` | The year rollover with no DST offset in play, so a failure here is arithmetic rather than zone handling. |

Install time with `withClock` (`12 §2.1`). There is no `FakeClock` and no `clockProvider` — writing
one re-introduces the second clock seam decision #46 exists to prevent.

## 6. Constraints that bind this task

- **Irreversibility** — a stored absolute path is `04 §1` item 3 and no migration repairs it. The
  three `CHECK`s were frozen into `drift_schemas/drift_schema_v1.json` at N07-T08 and **cannot be
  added to now**: `ALTER TABLE` cannot add a `CHECK` without the full table rebuild of `04 §2.6`, on
  the one table that points at the user's photographs.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. `path_provider` merges no Android permission and `MediaStore` opens no socket; **the `path` question in gotcha 1 is a G2 question and must not be answered by editing the allowlist.**
- **Layer rules** — `getApplicationSupportDirectory()` in exactly two files (`layer.path_provider`);
  `package:flutter_image_compress` in exactly one (`layer.plugin_flutter_image_compress`); no `File(`
  anywhere under `lib/features/**` (`layer.features`); no `package:flutter/material.dart` in
  `lib/data/` (layer rule 4).
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. `MediaStore` is the one class in the project permitted the `Store` suffix (`CONVENTIONS` §5.2).

## 7. Definition of Done

- [ ] `'an absolute path is rejected by the relative_path CHECK'` passes, and was seen to fail first for the stated reason
- [ ] only relative paths are stored, and the schema `CHECK` refuses the rest
- [ ] writes are atomic — a torn file is never a record's attachment
- [ ] `FakeMediaStore` exists with a loud tripwire and joins the override list here
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
# 1. Red first, then green.
fvm flutter test test/data/media_store_test.dart

# 2. The shard is a local civil month. Run it in the zone it is about.
TZ=Europe/London fvm flutter test --tags uk-zone

# 3. The override landed, and every widget test that already existed still builds.
fvm flutter test test/support/harness_test.dart test/features/

# 4. Watch the confinement rule fire, then un-plant it.
printf "import 'package:path_provider/path_provider.dart';\n" > lib/features/quick_entry/_plant.dart
dart run tool/check_policy.dart ; echo "exit=$?"   # POLICY [layer.path_provider] …, exit=1
rm lib/features/quick_entry/_plant.dart

# 5. Nothing generated moved — this task adds no table, no column and no query.
make gen && git status --short

# 6. Both gates.
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(gateway): MediaStore with relative paths only`

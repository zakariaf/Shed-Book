# N27-T03 — `ewe_summaries` rebuilt inside the writes that invalidate it

| | |
|---|---|
| **Epic** | [N27 — Ewe Card](epic.md) · `00-README` §9 step 10 (2 of 4) |
| **Task** | 3 of 7 |
| **Depends on** | N27-T02 · N14-T02 · N18-T01 |
| **Commit** | one commit · `feat(data): maintain ewe_summaries inside the writes that invalidate it` |

## 1. Why this task exists

The counts are maintained by the writes that change them — `LambingRepository`'s (N14) and
`FosterRepository`'s (N18). This is a **cross-epic edit to the product's most-reviewed repository**: it
is additive and legal, and the task names the files it re-opens so the reviewer reads them in
irreversibility order. Critique defect S9.

There is a second reason, and it is the one that decides the shape. `ewe_summaries` is **excluded from
the backup** (09 §6, §7.9) because it is a rebuildable cache whose `rebuilt_at` moves on every rebuild
and would break the export → import → export equality property. Nothing in N22 or N23 rebuilds it, and
04 §7's restore validation stops at the FTS index. Without a rebuild verb wired into the restore, a
shepherd who restores a backup opens every card and reads *"No seasons recorded"* against five seasons
of records that are all still there.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | **§5.13 (`EweSummaries` — the eight columns, the `lastObservationSeason` FK with `ON DELETE SET NULL`, `rebuiltAt`, and "a CACHE: rebuildable, excluded from the backup, rebuilt wholesale after a restore")** · §5.14 (**`LambingRepository` owns `lambings`, `lambs`, `care_events`, `ewe_observations` *and* `ewe_summaries`**; the writer list is closed at twelve) · §5.5 (`lambings.ease` nullable), §5.7 (`lambs.status`), §7 (`FosterEvents` is append-only) | which repository writes it, and what the columns are |
| `docs/engineering/CONVENTIONS.md` | §2.13 (the same ownership, plus the canonical verb signatures — `beginLambing` and `addLamb` throw, everything else returns `WriteOutcome`), §2.4 (`WriteOutcome` and its three variants), §2.8 (`RestoreService` writes all tables, once, into a **new** file), §4.6 (column naming), R18, R19, R32, R53 | **BINDING** on the verbs, the return types and the ownership |
| `docs/engineering/01-architecture.md` | §4.2 (**event verbs**; one `appNow()` per mutation; everything in one `_db.transaction()`), §4.3 (nothing side-effecting inside a transaction — no notification, no file write), §5.2–§5.3 (`WriteOutcome`, `shedFailureFrom`) | how the write is shaped |
| `docs/engineering/09-export-formats.md` | **§6 (the four excluded tables, and the `ewe_summaries` row: "a rebuildable cache, rebuilt wholesale after a restore. Exporting it would also break §7's round trip immediately, because `rebuilt_at` moves")** · §7.9 (excluded symmetrically) · §7.3 (the round-trip property) | why the rebuild verb exists at all, and why the table is not in the backup |
| `docs/engineering/04-migrations-media-backup-restore.md` | §7 (the atomic replace-everything restore, step by step; step 7's staging validation and the FTS rebuild that is its nearest neighbour) | where the rebuild call goes, and what it must not disturb |
| `docs/engineering/05-domain-correctness.md` | §6.5 (litter size — `lambsBorn ÷ ewesLambed`, zero-lamb lambings excluded from both sides), §6.7 (assisted = ease ≥ 2; unscored excluded from both sides), §7.5 (a repository is structurally incapable of producing a `Warning`) | what each count means, and what a repository may not do |
| `docs/engineering/07-screens.md` | §4.1 (the header must never wait for an aggregate — which is what the precomputed row buys), §15.1 (undo per verb: `beginLambing` and `addLamb` hard-delete; foster undo is a **compensating event**) | why the counts are precomputed, and every write path that has to keep them true |
| `docs/engineering/12-testing.md` | §3.1–§3.3 (repository tests against `NativeDatabase.memory()`, never a mock), §5.2 (`restoreFixture` goes through `RestoreService`), §11.5 (the fixture loader is a continuous test of the restore path) | the tier this task's tests live in |
| `epics/00-PLAN-CRITIQUE.md` | **S9** (*"Keep the placement; name the files it re-opens so the reviewer reads them in irreversibility order"*) | why this task is written the way it is |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | the invalidating writes and their transactions |
| `shed-drift-schema` | the summary table and what keeps it true |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/ewe_summaries_test.dart`
- **Test** — `'a new lambing updates ewe_summaries inside the same transaction'`
- **Why it is red today** — `ewe_summaries` exists and nothing writes it, so the summary line reads zeros.

```bash
fvm flutter test test/data/ewe_summaries_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it proves **atomicity**, not merely arrival. Two halves:

1. call `beginLambing` on a seeded ewe and assert `ewe_summaries` for her moved in the same call —
   `lambingsRecorded` up by one, `rebuiltAt` moved;
2. make the summary write fail *inside* the transaction (a FK violation on a
   `lastObservationSeason` pointing at a season that does not exist is the cheapest way) and assert
   the **lambing row is absent too**. A summary maintained by a second transaction passes half 1 and
   fails half 2, and half 2 is the one that matters: a partial write here is a card that is wrong
   forever with nothing to notice it.

**Green.** The minimum code that passes, and nothing beyond it — the summary write inside each invalidating transaction, and a rebuild verb for repair.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

| # | File | In `00-README` §8 order |
|---|---|---|
| 1 | `lib/data/lambing_repository.dart` — re-opened, additive | step 3 |
| 2 | `lib/data/foster_repository.dart` — re-opened, additive | step 3 |
| 3 | `lib/data/restore_service.dart` — re-opened, additive | step 3 |
| 4 | `test/data/ewe_summaries_test.dart` | step 7 |

### 5.1 What changes in each, and why

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/lambing_repository.dart` | **Edit, additive.** One private `_writeEweSummary(EweId, {required Instant now})` called from inside the existing `_db.transaction()` of `beginLambing`, `addLamb`, `setEase`, `correctOccurredAt`, `recordObservation` (T06) and every undo that removes one of those rows. Plus the two public rebuild verbs. **No existing verb changes its signature or its return type** — that is what makes this edit legal in a merged file |
| 2 | `lib/data/foster_repository.dart` | **Edit, additive.** `recordFoster` moves a lamb's *rearing* dam, which changes neither dam's `lambsBorn` — so the only count it touches is `seasonsRecorded` when a foster is the first thing recorded against a ewe in a season. Call the same summary write for **both** the new rearing dam and the previous one (the `LAG` in T01's timeline is the read side of the same fact). Cross-repository: `FosterRepository` calls a small shared writer, it does not reach into `LambingRepository` |
| 3 | `lib/data/restore_service.dart` | **Edit, additive.** After the staging database is validated and swapped (04 §7 step 7 onward), call `rebuildAllEweSummaries()`. This is the third re-opened file and the one the critique did not anticipate; name it in the PR body with the others |
| 4 | `test/data/ewe_summaries_test.dart` | **New.** The anchor plus §5.4's cases, against `NativeDatabase.memory()` |

### 5.2 The signatures

Two public verbs and one private writer. Both public verbs return `WriteOutcome` — they are ordinary
writes, not the two exceptions R32 carves out.

```dart
// lib/data/lambing_repository.dart — ADDITIVE. Nothing above this line changes.

/// Recompute one ewe's summary from her own rows and upsert it. Called from
/// inside the transaction of every write that invalidates it — never after,
/// never on a timer, never on launch.
///
/// Public because RestoreService and FosterRepository both need it; private
/// callers inside this file use the same body.
Future<WriteOutcome> rebuildEweSummary(EweId ewe);

/// Repair. 09 §6: ewe_summaries is excluded from the backup, so a restored
/// database has an EMPTY summary table and every card reads zeros until this
/// runs. Called by RestoreService after the swap; also the one honest answer
/// to "the counts look wrong".
Future<WriteOutcome> rebuildAllEweSummaries();
```

The recompute is one statement per ewe, and it is the same arithmetic 05 §6.5 and §6.7 fix — expressed
in SQL because it runs inside a transaction that is already open:

```sql
-- Every count comes from HER rows. Nothing here reads a clock: `now` is the
-- single appNow() the calling verb already took (01 §4.2).
INSERT INTO ewe_summaries
      (ewe, seasons_recorded, lambings_recorded, lambs_born, lambs_born_alive,
       assisted_lambings, scored_lambings, last_observation_season, rebuilt_at)
SELECT :ewe,
       (SELECT COUNT(DISTINCT lg.season) FROM lambings lg WHERE lg.ewe = :ewe),
       (SELECT COUNT(*)                  FROM lambings lg WHERE lg.ewe = :ewe),
       (SELECT COUNT(*) FROM lambs lb WHERE lb.birth_dam = :ewe),
       (SELECT COUNT(*) FROM lambs lb WHERE lb.birth_dam = :ewe
                                       AND lb.status <> 'stillborn'),
       (SELECT COUNT(*) FROM lambings lg WHERE lg.ewe = :ewe AND lg.ease >= 2),
       (SELECT COUNT(*) FROM lambings lg WHERE lg.ewe = :ewe AND lg.ease IS NOT NULL),
       (SELECT o.season FROM ewe_observations o WHERE o.ewe = :ewe
         ORDER BY o.occurred_at DESC, o.id DESC LIMIT 1),
       :now
ON CONFLICT(ewe) DO UPDATE SET
       seasons_recorded = excluded.seasons_recorded,
       lambings_recorded = excluded.lambings_recorded,
       lambs_born = excluded.lambs_born,
       lambs_born_alive = excluded.lambs_born_alive,
       assisted_lambings = excluded.assisted_lambings,
       scored_lambings = excluded.scored_lambings,
       last_observation_season = excluded.last_observation_season,
       rebuilt_at = excluded.rebuilt_at;
```

### 5.3 The details that are easy to get wrong

1. **Recompute, do not increment.** A `+1` is faster and is wrong within one night: an undo hard-deletes
   the lambing (07 §15.1) and a decrement that is missed anywhere leaves the count permanently high,
   with nothing to notice it. A full recompute from her own rows is idempotent, survives being called
   twice, and makes the rebuild verb and the incremental path the **same body** — which is the only
   reason the rebuild can be trusted after a restore.
2. **It goes inside the existing transaction, not beside it.** 01 §4.2: everything in one
   `_db.transaction()`. Two transactions means a window in which the lambing exists and the summary
   does not — and if the process dies in that window (which is the premise of the whole write path:
   *"assume the phone dies"*), the card is wrong forever with no error anywhere. The anchor's second
   half is the assertion that holds this.
3. **`appNow()` is called once per mutation, by the *calling* verb** (01 §4.2). `rebuiltAt` takes the
   same `now` the lambing took. A second `appNow()` inside the summary writer means a row whose
   `rebuilt_at` is later than the event that caused it, which is harmless right up until somebody
   uses it to order anything.
4. **`lambs_born_alive` excludes `stillborn` and nothing else.** `lambs.status` is one of
   `('alive','dead','stillborn','sold')`. `<> 'alive'` counts a **sold** lamb as not born alive and a
   lamb that died at day three as never alive; `= 'alive'` loses every lamb that was born alive and
   later died. The correct predicate is `<> 'stillborn'`, and `CONVENTIONS §5.1` is explicit that
   stillborn *"is its own bucket, never folded into day-0 deaths"*.
5. **`scored_lambings` and `assisted_lambings` are a pair, on purpose** (decision #59, 03 §5.13). They
   are stored together so the assisted rate can exclude unscored lambings from **both** sides and
   report coverage (05 §6.7). Storing only `assisted_lambings` makes the coverage clause in T02
   unrenderable and forces the screen to treat a blank ease as *unassisted*, which is the silent
   inference §12.4 forbids.
6. **`lambings.ease` is nullable and `>= 2` on a NULL is NULL, not false.** In SQLite
   `WHERE ease >= 2` correctly drops NULLs — but `COUNT(*)` over `CASE WHEN ease >= 2 THEN 1 END`
   written carelessly can count them. Write both counts as separate `WHERE` clauses, as above, and
   let the test with one unscored lambing prove it.
7. **`last_observation_season` is a real FK with `ON DELETE SET NULL`** (03 §5.13's doc comment: *"a
   dangling id would render a blank year on the one line the retention feature is built on"*).
   Deleting a season nulls it rather than orphaning it; the recompute then finds the next-newest
   observation on the next write. Do not "fix" a null by reaching for the previous value.
8. **A repository cannot produce a `Warning`, structurally** (R53, 05 §7.5): `lib/data/` may not
   import `lib/domain/validation/`, and `layer.data_no_validation` is a gate row. Both verbs return
   `WriteCommitted()` with the default empty `warnings`. If the counts look contradictory, that is the
   *controller's* business, and on this screen it is nobody's — the card renders facts.
9. **`FosterRepository` does not reach into `LambingRepository`.** Both are flat in `lib/data/` and may
   import each other, but a repository calling another repository's verb inside its own transaction
   couples two writer boundaries. Put the recompute body in one place `lib/data/` can share — the
   simplest honest shape is a private top-level function in `lambing_repository.dart` that both files
   call with the open transaction's executor, and it is exactly what `/simplify` should land on.
10. **A foster does not change either ewe's `lambs_born`.** 05 §6.5: a fostered lamb is counted in the
    **birth** dam's litter, never the receiving ewe's; her *reared* count goes up and her *born* count
    does not, and `ewe_summaries` has no reared column. What a foster can change is
    `seasons_recorded` — write the summary for both the new rearing dam and the previous one anyway,
    because it is idempotent and because getting it wrong is invisible.
11. **`RestoreService` writes all tables, once, into a new file** (§2.8), so the rebuild is legal
    there — but it must run **after the swap**, against the live database, not against the staging one
    04 §7 step 7 validates. Running it in staging means the counts are built from a database that is
    about to be replaced, and the `rebuilt_at` you wrote is the one the round-trip property (09 §7.3)
    is not looking at, which is the good news; the bad news is that the swap can still abort.
12. **Do not add `ewe_summaries` to the backup to avoid the rebuild.** 09 §7.9 says the exclusion is
    symmetric and names this table as the one that *"would fail loudest: it is rebuilt after restore
    with a fresh `rebuilt_at`"*. N23-T07's export → import → export equality property goes red the
    moment it ships in the file.
13. **The `codegen` job is the guard against the tempting fix.** Every time this task is hard, the
    shortcut is a new column — `reared_count`, `last_observation_kind`, `summary_line`. The schema was
    frozen at N07-T08 and each one is a full table rebuild on somebody else's phone in April.

### 5.4 The full test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/data/ewe_summaries_test.dart` | `'a new lambing updates ewe_summaries inside the same transaction'` | **The anchor**, both halves: the counts move, and a failure inside the transaction leaves neither row |
| | `'adding a lamb moves lambs_born and lambs_born_alive together'` | The pair, in one write |
| | `'a stillborn lamb counts in lambs_born and not in lambs_born_alive'` | The `<> 'stillborn'` predicate, the direction that matters |
| | `'a sold lamb counts in lambs_born_alive'` | The other direction — the predicate people write first (`= 'alive'`) fails here |
| | `'a lamb that died at day three counts in lambs_born_alive'` | The second failure mode of `= 'alive'` |
| | `'an unscored lambing raises lambings_recorded and not scored_lambings'` | Decision #59; the input T02's coverage clause needs |
| | `'ease 1 counts as scored and not as assisted'` | 1 = no assistance. Off-by-one on the threshold is silent |
| | `'undoing a lambing returns the counts to their previous values'` | The hard-delete path (07 §15.1) and the reason the write is a recompute, not an increment |
| | `'two lambings in one season count as one season and two lambings'` | `COUNT(DISTINCT season)` — a real case, not a hypothetical |
| | `'recording an observation moves last_observation_season'` | The clause T02 renders |
| | `'deleting a season nulls last_observation_season rather than orphaning it'` | `ON DELETE SET NULL`, asserted rather than assumed |
| | `'a foster does not change either ewe lambs_born'` | 05 §6.5's conservation rule, at the summary layer |
| | `'rebuildEweSummary is idempotent'` | Call it three times; only `rebuilt_at` moves |
| | `'rebuildAllEweSummaries reproduces exactly what the incremental writes produced'` | The two paths are one body. Build a flock by writing, snapshot the table, wipe it, rebuild, compare |
| | `'restoring a backup leaves ewe_summaries populated'` | Through `restoreFixture` (12 §5.2), which goes through `RestoreService`. Without T03's call this renders "No seasons recorded" on 400 cards |
| | `'ewe_summaries is absent from the exported backup'` | 09 §7.9. Cheap here, and it is the assertion that stops somebody "fixing" the restore by exporting the cache |
| `test/features/ewe_card_test.dart` | `'the summary line reflects a lambing recorded one second ago'` | The end-to-end claim, in the tier the user experiences it |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **One transaction per mutation** — the summary write is inside it, not beside it, and nothing
  side-effecting joins it (01 §4.3).
- **No schema change** — `ewe_summaries` has eight columns and keeps them. The `codegen` job proves it.
- **Cross-epic edits are additive only** — no merged verb changes its signature, its return type or its
  transaction boundary. Critique S9.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'a new lambing updates ewe_summaries inside the same transaction'` passes, and was seen to fail first for the stated reason
- [ ] the summary is updated in the same transaction as the event
- [ ] a full rebuild verb exists for repair after a restore
- [ ] the two re-opened repositories are named in the commit message
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `RestoreService` calls `rebuildAllEweSummaries()` after the swap, and the third re-opened file is named in the commit message alongside the other two
- [ ] the incremental path and the rebuild path are the **same body**, proved by a test that compares them
- [ ] `lambs_born_alive` excludes `stillborn` only; a sold lamb and a lamb that died at day three both count
- [ ] `assisted_lambings` and `scored_lambings` both move, and ease 1 counts as scored and not assisted
- [ ] `ewe_summaries` gained no column and is still absent from the backup
- [ ] no verb merged in N14 or N18 changed its signature, return type or transaction boundary

## 8. Verification

```bash
# 1. Red first, for the stated reason.
fvm flutter test test/data/ewe_summaries_test.dart

# 2. Green, plus the two tiers this task re-opens.
fvm flutter test test/data/ewe_summaries_test.dart \
                test/data/lambing_repository_test.dart \
                test/data/foster_repository_test.dart

# 3. The restore path still round-trips.
fvm flutter test test/policy/backup_round_trips_test.dart

# 4. Nothing moved in the schema.
make gen && git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/

# 5. Both gates.
make check
make test
```

```bash
git diff --stat main -- lib/data/            # expect: three files, all additive
grep -n "rebuildAllEweSummaries" lib/data/restore_service.dart   # expect: one call, after the swap
grep -rn "domain/validation" lib/data/       # expect: nothing (R53, layer.data_no_validation)
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(data): maintain ewe_summaries inside the writes that invalidate it`

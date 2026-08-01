---
name: shed-write-path
description: >-
  The single write path — event verbs, the row commits on screen entry not exit, one transaction, no
  aggregate save. Use when recording a lambing, lamb, weight, treatment or note, when storing any
  fact, and whenever a Save button, draft, dirty flag or optimistic UI appears. Do NOT use for undo
  (shed-screens-and-routing).
---

# The single write path

Spec §5: *assume the phone dies.* Every write is committed immediately; there is no draft state to
lose. That is enforced structurally, not by discipline — the write API has no aggregate parameter, so
a draft is unrepresentable.

Authorities, in order: `docs/engineering/CONVENTIONS.md` §2.4, §2.13 and the rulings; then
`docs/engineering/01-architecture.md` §4–§5. They are BINDING and outrank this skill. Read
`01-architecture.md` §4.2 before adding a repository, and CONVENTIONS §2.13 before naming a verb.

**Do NOT use this skill for:** undo, delete or the strike affordance — **shed-screens-and-routing**
owns them. Table, column, index or CHECK definitions — **shed-drift-schema**. Provider shapes,
controllers, `guard()` and warning population — **shed-riverpod-providers**.

## The two verbs that are the product

`beginLambing` and `addLamb` are the only writes that return an id and **throw** (R32).

```dart
Future<LambingId> beginLambing(EweId ewe);                       // throws
Future<LambId>    addLamb(LambingId lambing, {required Sex sex}); // throws
```

- There is no id to hand back on failure and the screen cannot open, so the global error net handles
  it. Call them in `try`/`catch`, never `switch (outcome)` — a `WriteCommitted(:final id)` switch on
  either does not compile. `07-screens.md` §6.1 still shows the wrong shape; R32 overrules it.
- Neither is ever gated by the free tier. That is what makes throwing safe.
- `addLamb` writes the lamb **and** its colostrum/navel reminder rows in the same transaction. There
  is no code path that creates a lamb without them.
- `createEwe` is **not** in this set: the cap policy can refuse it, so it takes an `EntryContext`,
  returns `WriteOutcome`, and the committed variant carries `insertedId`. Two shapes; no third.

Every other write returns `WriteOutcome`. Verb signatures are catalogued in CONVENTIONS §2.13 — read
it, do not invent one. Pen verbs are `enterPen` / `exitPen` on the repository (`turnOut` is the
controller's, R63); foster is `recordFoster(LambId, FosterOutcome)` — `setRearingDam(lambId, eweId?)`
is a banned signature (R64).

## The row is created on screen entry, not on exit

`LambingEntryScreen`'s controller calls `beginLambing()` on its **first build**, before the route is
pushed. From that instant the record exists, attributed to the right ewe, with an honest
auto-captured timestamp. Every later tap is an `UPDATE`.

- The app-bar button says **"Done"**, never "Save". It pops the route and commits nothing.
- An abandoned entry leaves a real row. Correct — *something happened to this ewe at 03:20* is a true
  statement. Offer an explicit delete; **never garbage-collect**, because silent deletion is a spec
  §12.4 violation in the other direction.
- Free-text fields are the only exception, because per-keystroke writes churn every watching stream:
  debounce **400 ms**, commit on focus loss, on route pop (`PopScope`), and on
  `AppLifecycleState.inactive`. Worst-case loss is 400 ms of typing. That number is in
  `CODE-REVIEW-CHECKLIST.md` so it cannot grow.
- The free-tier cap can never block a live entry: `EntryContext.liveEntry` structurally cannot return
  a block — it returns `Allow(overFreeCap: true)`, the row is written and marked over the cap.

## The fixed order inside every verb

1. `final now = appNow();` — **once** per mutation. `appNow()` (`lib/core/time/app_clock.dart`) is the
   app's only wall-clock reader (R23). Two rows written in one mutation must not disagree by a
   millisecond. `clock.now()` and `DateTime.now(` are banned outside that file; repositories take no
   `Clock`, and there is no `clockProvider`.
2. `final when = RecordedTime.capture(now);` — the spec §12.5 provenance quad, written as one unit or
   not at all. Its four column spellings are `CONVENTIONS` R37/R38: read them there, never from
   memory. The time-source column stores a frozen wire key, never a localised string.
3. **Media first, outside the transaction.** `MediaStore` returns a *relative* path. An orphaned file
   is garbage a sweep collects; an orphaned row is a broken record.
4. **All SQL, and only SQL, inside one `_db.transaction`** — including single-statement mutations, so
   the next edit is already inside the boundary. `newUid()` (`lib/core/db/uid.dart`, R15) mints the
   export identity on every insert. **Every statement is `await`ed**: un-awaited work escapes the
   transaction and silently loses data — treat a drift warning about it as P0. Bulk work (restore,
   seeding, batch repeat) is one transaction, not N.
5. **Gateways after the transaction returns.** `ReminderReconciler.reconcile()` is debounced 500 ms,
   off the paint frame (R51; `schedule(` on a reminder object is a banned spelling). **Never call a
   platform channel inside a transaction** — it round-trips through another isolate while holding the
   write lock.

Load `examples/foster_verb.dart` **before writing a new repository verb**: it is the complete shape,
including the `_write` helper, and resolves ordering questions prose cannot. Copy the **shape**, never
the file — CONVENTIONS §2.13 owns the signature, and `lib/data/foster_repository.dart` is
authoritative the moment it exists.

## `WriteOutcome` — three variants, not generic

`lib/core/write_outcome.dart`, defined in CONVENTIONS §2.4: `WriteCommitted{insertedId, warnings}`,
`WriteFailed(ShedFailure)`, `WriteRefused(RefusalReason)`. Banned: `WriteOutcome<T>`, `Ok`, `Error`,
`WriteCommitted{flags}`, a fourth variant added without editing every `switch`.

A write that fails **returns** `WriteFailed`; a read that fails **throws**. A cap refusal is not a
failure and must never be logged as one.

**`lib/data/` may never import `lib/domain/validation/`** (rule `layer.data_no_validation`, R53). This
is the structural mechanism behind safety rule §12.4: a repository that cannot see a `Warning` cannot
invent one, so a repository always returns `WriteCommitted()` with the default empty `warnings`.
**Who populates that list, and when, is stated once — in `shed-riverpod-providers`.** Read it there;
do not restate it here. Warn, never fix; never silently correct an entry.

## Persist before republish

`tap → controller.guard() → repository verb → transaction → COMMIT → drift invalidates the touched
tables → the screen's single watch() re-runs`.

- **No optimistic UI.** Nothing confirms before the transaction returns. The confirmation channels
  fire on `WriteCommitted` only: haptic, the list mutation, and `confirmSaved` / `showFailure` /
  `showCapRow` in `lib/core/ui/feedback.dart` (R30).
- **There is no SnackBar** (ruling P2). `showSnackBar(` is banned everywhere, `feedback.dart`
  included, and any doc sentence describing a "persistent SnackBar with Undo" is superseded. What the
  confirmation *is* belongs to **indelible-states-and-feedback**; all this skill asserts is that
  nothing renders it before the transaction returns.
- **No manual invalidation.** `ref.invalidate` after a write is the classic stale-read bug and is on
  the banned-text list. drift already tracks which tables each stream reads.
- **One SQL statement per screen**, fan-in in SQL, every aggregate through `customSelect` with an
  explicit `readsFrom:`. The `combineLatest` ban and drift#3338's mechanism are
  **shed-riverpod-providers**' — cite it rather than re-arguing it.
- **De-duplicate in the repository, never in the widget.** Set
  `override_hash_and_equals_in_result_sets: true` in `build.yaml` and append `.distinct()`; `List`
  equality is identity, so list results need a comparator. Without it the grid re-lays-out under a
  head torch.

## Gotchas

- `Value.absent()` ≠ `Value(null)`. `lambings.declaredBirthType` is nullable so `beginLambing` can
  insert it absent — **never default a birth type**, that is the app asserting a litter size nobody
  tapped (§12.4).
- Birth type has **no chooser**. It is derived from tally strokes and labelled as derived.
  `setBirthType` exists as a verb; its caller is the tally, never a segmented control.
- `ewe_touches` is keyed on `ewe`, one row per ewe: `insertOnConflictUpdate`, never `insert`.
- A gateway failure never rolls back the SQL. The committed row is the fact that matters.
- A bare `int` never crosses a repository boundary — extension-type ids only (R33). The one exception
  is `WriteCommitted.insertedId`, wrapped at its single reading call site.
- There is no `repo.undo(id)`. Undo is per verb and its semantics (hard delete, compensating event,
  soft-void, no undo at all) belong to **shed-screens-and-routing**; state any window in seconds.

## Banned outright

`save(aggregate)` · `commit()` · `submit()` · any `Draft` or `Pending` model · `isDirty` · a Save
button · a write issued from a widget's `onPressed` straight to `AppDatabase` · `ref.invalidate` after
a write · `combineLatest` over drift streams · a `TextEditingController` read only on a button press ·
a thirteenth repository (the set is twelve and closed, R19) · a repository interface or a mock in a
data test (use `NativeDatabase.memory()`).

## Definition of done

- [ ] No repository method takes a whole aggregate; every one is an event verb named in CONVENTIONS §2.13.
- [ ] `appNow()` appears exactly once per mutation; no `clock.now()` or `DateTime.now(` outside `app_clock.dart`.
- [ ] Exactly one `_db.transaction` per mutation, every statement inside it `await`ed, no platform channel inside it.
- [ ] `newUid()` on every insert; the §12.5 quad written together on every dated row, spelled per R37/R38.
- [ ] `beginLambing` and `addLamb` return an id and throw; every other write returns `WriteOutcome`; no repository returns a non-empty `warnings`.
- [ ] Planting an import of `lib/domain/validation/warning.dart` in a `lib/data/` file fails `tool/check_policy.dart` with `layer.data_no_validation`.
- [ ] A widget test per entry screen proves the row exists before any Done tap, with no Save and no pop.
- [ ] `grep` finds no `showSnackBar(`, no `ref.invalidate` after a write, no `combineLatest`, no `Draft`, no `isDirty`.

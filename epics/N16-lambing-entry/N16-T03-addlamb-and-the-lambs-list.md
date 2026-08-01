# N16-T03 — `addLamb` and the lambs list

| | |
|---|---|
| **Epic** | [N16 — Lambing Entry and the P8 ruling](epic.md) · `00-README` §9 step 6 (2 of 5) |
| **Task** | 4 of 10 |
| **Depends on** | N16-T02a |
| **Commit** | one commit · `feat(data): addLamb — a committed row per stroke` |

## 1. Why this task exists

The second and last verb in the app that returns an id and throws. Each lamb is its own
committed row the moment the stroke lands, so a phone that dies between the second and third lamb loses
nothing.

T02 shipped the verb because a slab you cannot press is not a tally. **This task ships its contract**:
that it throws rather than returning a `WriteOutcome`, that `birth_dam` is fixed at insert and refused
by a trigger afterwards, that the row survives a cold reopen, and that it never originates a sex. It
also prints the lambs themselves — three indented sub-rows under the parent row, each carrying sex,
status and weight, with `DEAD` as a word and no colour whatsoever.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | **§5.5 (`Lambs`: the nullable `sex`, `birth_dam`, the five `CHECK`s, the partial unique tag index)** · §7 (the birth-dam `BEFORE UPDATE` trigger, in `views.drift`) · §2.1 (`mixin Identified` — `created_at`, and P1's `struck` / `struck_at`) | every column and constraint the verb writes into |
| `docs/engineering/CONVENTIONS.md` | §2.13 (**the two throwing verbs**) · §2.1 (`LambId`) · §2.9 (`Sex`, `LambStatus`) · §2.3 (`Grams`) · §4.6 (column names) · R32 · R33 · R45 | the signature, and the types that cross the boundary |
| `docs/engineering/01-architecture.md` | §4.2 (event verbs; the two id-returning verbs) · §5.2–§5.4 (`WriteOutcome`, `ShedFailure`, `shedFailureFrom`) | why this verb is shaped differently from every other |
| `docs/engineering/12-testing.md` | **§3.5 (durability — reopen the file)** · §3.3 (repository tests against `NativeDatabase.memory()`) · §3.6 (never mock drift) · §2.4 (the data-tier ambiguous-hour form) | how the contract is proved |
| `docs/design/indelible.md` | **§9 screen 4 (the three indented 64 px sub-rows, `LAMB 1 · EWE LAMB · ALIVE · 4.1kg`, `DEAD` in full ink with no colour)** · §2.2 (the redundancy table — *"Death is a word"*) · §9's strike paragraph (`LAMB 3 — STRIKE THIS LAMB`, and no minus button) · §7.12 (unset cells print their gap) | how a lamb prints |
| `docs/engineering/10-accessibility-and-i18n.md` | §5.2 (the lamb-row rows of the redundancy table) · §3.2 (the eight label rules) | the four lamb states, in words |
| `docs/engineering/05-domain-correctness.md` | §4.2 (**the provenance quad, and which tables carry it — `Lambs` does not**) · §5.2 (canonical grams) | why a lamb sub-row has no editable event time |
| `docs/engineering/07-screens.md` | §6.4 (the per-lamb tap costs) · §15.1 (`addLamb`'s undo is a hard delete) · §2.2 (the lambs-list empty copy, landed in T09) | what the list may do |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | the verb, the transaction and the immediate commit |
| `shed-drift-schema` | the lambs table's constraints and its birth-dam trigger |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/lambing_repository_test.dart`
- **Test** — `'addLamb returns a LambId, throws on failure, and commits before the widget rebuilds'`
- **Why it is red today** — strokes render but nothing is stored per lamb.

```bash
fvm flutter test test/data/lambing_repository_test.dart   # expect: failing, for the reason above
```

Sharpen all three clauses. **Returns** — the static type is `Future<LambId>`, asserted by using the
value as a `LambId` without a cast. **Throws** — call it with a `LambingId` that does not exist and
expect a throw, not a `WriteFailed`; `foreign_keys = ON` (decision #28) makes that a real
`SqliteException` rather than a contrivance. **Commits before the rebuild** — read the row back with a
second `select` on the same database inside the same test, before any `pump`, so the assertion is
about the transaction and not about the frame.

**Green.** The minimum code that passes, and nothing beyond it — the verb and the list, with the row read back from the database in the test.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step, and say so in the commit message.** `Lambs` and the birth-dam trigger froze at
N07-T04 and N07-T08. This task writes into them and proves the constraints already there.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/lambing_repository.dart` | **Extended.** `addLamb` hardened to its published contract: one `db.transaction`, `appNow()` called exactly once, `newUid()` for the export identity, `birth_dam` read from the lambing row **inside the same transaction**, and the throw path left alone so `01 §4.2`'s global error net handles it. The transaction boundary gets the comment N24 will read (critique defect S10 — reminders are written inside this transaction, not after it) |
| 2 | `lib/data/failure_mapping.dart` | **Touched only if a new `SqliteException` shape appears** — an FK violation on `lambing` already maps. `00-README` §8 step 3 item 11; if this file does not move, say so |
| 3 | `lib/features/lambing/widgets/lamb_row.dart` | **New.** One 64 px indented sub-row per lamb: ordinal, sex, status, weight, tag. `ShedAnimalRow` (N10-T04) is the ewe-shaped row and is **not** this; a lamb sub-row is narrower and carries no summary line |
| 4 | `lib/features/lambing/lambing_entry_screen.dart` | **Extended.** Mounts the list under the tally row, in `l.id ASC` order — stroke order, so the list and the tally cannot disagree |
| 5 | `lib/l10n/app_en.arb` | **Extended.** `LAMB n`, the four status words, the two sex words, the two *not recorded* labels and the row's `semanticLabel` — each with a `description`, each taking the animal noun as a placeholder |
| 6 | `test/data/lambing_repository_test.dart` | **The anchor**, plus the contract cases |
| 7 | `test/data/durability_test.dart` | **Extended** (created at N14-T02 from `12 §3.5`). One case: a lamb row survives `db.close()` and a cold reopen |
| 8 | `test/features/lambing_entry_test.dart` | **Extended.** The list's rendering cases |
| 9 | `test/data/lambing_ambiguous_hour_test.dart` | **Extended.** `created_at` through the repeated hour |

### 5.2 The signatures

```dart
// lib/data/lambing_repository.dart
/// One of exactly two verbs in the app that return an id and THROW (R32,
/// CONVENTIONS §2.13). Every other write returns WriteOutcome. There is no id
/// to hand back on failure and the caller has nowhere to put a WriteOutcome —
/// 07 §6.1's `case WriteCommitted(:final id)` is wrong twice over (R3, R32).
///
/// `sex` is NULLABLE and defaults to null. A slab press records a lamb
/// ARRIVING; nobody has looked at it. `lambs.sex` is `NULL = not recorded`,
/// and `Sex.unknown` means "the shepherd looked and could not tell" (R45) —
/// two different facts. Defaulting to `unknown` would be the app originating
/// one of them, which is §12.4 at the write path.  [Ruled at N16-T02, R75.]
Future<LambId> addLamb(LambingId lambing, {Sex? sex}) async {
  final now = appNow();                       // ONCE per mutation (R23)
  return _db.transaction(() async {
    // birth_dam is denormalised from lambings.ewe and is immutable
    // afterwards — enforced by a BEFORE UPDATE trigger in views.drift, not by
    // Dart. Read it HERE, inside the transaction, never from the screen's copy.
    final parent = await (_db.select(_db.lambings)
          ..where((t) => t.id.equals(lambing.value)))
        .getSingle();
    final id = await _db.into(_db.lambs).insert(LambsCompanion.insert(
          lambing: lambing.value,
          birthDam: parent.ewe,
          uid: newUid(),                      // UUID v7 — lib/core/db/uid.dart
          createdAt: now,
          updatedAt: now,
          sex: Value(sex?.key),
        ));
    // N24 writes the colostrum and navel reminder rows INSIDE this boundary.
    return LambId(id);
  });
}
```

The row, and the one decision it takes about ordering:

```dart
// lib/features/lambing/widgets/lamb_row.dart
/// `LAMB 1 · EWE LAMB · ALIVE · 4.1kg` — 64 px, indented under the parent row.
///
/// ORDER IS STROKE ORDER (`l.id ASC`), and dead lambs are NOT grouped to the
/// bottom here. `10 §5.2` groups by status on the lists that are ABOUT lambs;
/// on this screen the ordinal must agree with the tally beside it, and
/// re-sorting would make `LAMB 3` print second. If that is disputed, it is a
/// screens question for N17/N27, not a local choice.
class LambRow extends StatelessWidget { … }
```

### 5.3 The details that are easy to get wrong

- **`Lambs` has no provenance quad, so a lamb sub-row has no event time and no edit verb.** R37's list
  is `Lambings`, `Treatments`, `CareEvents`, `FosterEvents`, `EweObservations`, `PenOccupancies` and
  `Notes` — not `Lambs`. `05 §4.2` makes the consequence absolute: *"a table without the quad has no
  edit verb."* All the row has is `created_at` from `mixin Identified`, which is **when the row was
  written**, not when the lamb was born. Printing it in the margin beside an `AUTO` stamp is a §12.5
  claim the schema cannot back. Print the ordinal, not a time; the lambing's own time is in the header
  and it is the one that is honest.
- **`birth_dam` is enforced by a trigger, and the test must prove the trigger.** A Dart-side `assert`,
  a private setter or "we just never call update" are all mechanisms that evaporate. Write the lamb,
  then attempt `UPDATE lambs SET birth_dam = …` through the database and expect it to be refused. That
  is the assertion; anything weaker tests the caller rather than the schema.
- **`sex` is `Sex?` and `Sex.unknown` is not its default.** `NULL` means *not recorded*; `'unknown'`
  means *the shepherd looked and could not tell*. R45 exists because merging them destroys the one
  distinction the column is for. The write path must contain no occurrence of `Sex.unknown` at all —
  assert that on the source text, because it is the kind of thing a later "tidy-up" reintroduces.
- **`foreign_keys = ON`, so a bare id is an FK violation rather than a durability test** (`12 §3.5`'s
  own comment). Seed a real ewe and a real lambing before every case; the negative case then uses a
  deliberately absent `LambingId` and gets a genuine `SqliteException`.
- **`appNow()` exactly once per mutation** (R23). Two calls inside one transaction can straddle a
  minute boundary and give `created_at` and `updated_at` different values for one insert. Never
  `clock.now()`, never `DateTime.now(` — both are gate rows, and `test/` is scanned too.
- **The whole insert is one `db.transaction`, and N24 will write inside it.** Critique defect S10:
  reminders are created in the same transaction as the lambing and the treatment, not scheduled
  afterwards. Leave the boundary named in a comment so the next epic extends it rather than opening a
  second one.
- **`DEAD` is a word and never a colour.** `indelible.md` §2.2 is explicit: *"It would be trivially
  easy to make a dead lamb red. It is not, and never will be. Death is a word."* The test asserts the
  colour token on a dead row is the **same** as on an alive row; a review remark is not enough,
  because the colour version looks better in a screenshot.
- **`stillborn` is its own state, never folded into "died at age 0".** `03 §5.5`'s `CHECK` allows
  `alive`, `dead`, `stillborn`, `sold`; `05` counts stillborn in its own bucket; `10 §5.2` gives it
  its own word and its own shape. Rendering it as `DEAD` loses the number the losses breakdown exists
  to carry.
- **A lamb with no tag is fully counted.** `03 §5.5`: *"a lamb that died before tagging is counted,
  fully. Lamb identity is the row, never the tag."* `tag` is nullable at every layer, the unique index
  is partial (`WHERE tag IS NOT NULL AND status = 'alive'`), and the row renders without one.
- **An unrecorded birthweight prints a gap, never `0`.** `indelible.md` §7.12: unset cells print a 2 px
  **dotted** rule and `NOT RECORDED · SKIPPABLE`. Zero is a real weight and the field is optional;
  a `0.0 kg` on a lamb row is the app inventing data. Setting the weight is **N17-T02**'s keypad —
  this task renders it and nothing more.
- **Weight is `Grams` and the display unit comes from `unitsProvider`.** Canonical storage is integer
  grams (`05 §5.2`); `4.1kg` is produced by `lib/core/ui/formatters.dart`, the one `package:intl` call
  site outside `lib/data/`. A `double` in a widget is where a kg/lb bug starts.
- **The `birth_weight_g BETWEEN 200 AND 20000` `CHECK` is a unit-slip guard, not a husbandry
  opinion.** `03 §5.5` says so in the schema comment and §12.2 is why: never narrow it to a range a
  vet would recognise. The domain's `kPlausibleBirthWeight` (1000–10000 g) is a *warning* threshold
  and a different number for a different job — do not reconcile them.
- **Striking a lamb is the row's chooser, and there is no swipe.** `indelible.md` §9: the lamb cell
  opens `LAMB 3 — STRIKE THIS LAMB`, which rules a line through the third stroke and prints
  `TWIN (COUNTED, 1 STRUCK)`. `Dismissible` and `Draggable` are banned outright under `lib/`
  (decision #101) and the gate holds it. The struck row **stays where it was**, ruled through, at
  5.75:1 — it does not move, collapse, fade or disappear.
- **Tapping a lamb row does not push the Lamb Card yet.** `Routes.lambCard` and `LambCardScreen` are
  **N17-T01**. Leave the row's primary action as the strike chooser and a comment naming N17; a
  placeholder push to a screen that does not exist is a compile error, and a disabled row is a dead
  target under a cold thumb.
- **`addLamb`'s undo is a hard delete and it is a margin strike, not a SnackBar.** `07 §15.1` gives
  the verb a hard delete inside the window; **P2** replaces its "SnackBar" window with the time-boxed
  strike in the row's own margin from N14-T05, its window stated in seconds and never surviving
  process death.

### 5.4 The full test set

| File · case | What it asserts |
|---|---|
| `test/data/lambing_repository_test.dart` · `'addLamb returns a LambId, throws on failure, and commits before the widget rebuilds'` | **The anchor.** The static type, a throw on an absent `LambingId`, and a read-back before any pump |
| `test/data/lambing_repository_test.dart` · `'addLamb never originates a sex'` | `sex` is `NULL` after a slab press, and `Sex.unknown` appears nowhere on the write path (source text over `lib/data/`) |
| `test/data/lambing_repository_test.dart` · `'birth_dam is copied from lambings.ewe at insert'` | The value equals the parent's `ewe`, read from the database rather than from the argument |
| `test/data/lambing_repository_test.dart` · `'an UPDATE of birth_dam is refused by the trigger'` | The schema is the mechanism. Attempt the update through the database and expect it refused |
| `test/data/lambing_repository_test.dart` · `'addLamb returns WriteOutcome nowhere'` | Source text: the two throwing verbs are the only two, and neither signature mentions `WriteOutcome` |
| `test/data/lambing_repository_test.dart` · `'appNow is called once per addLamb and created_at equals updated_at'` | One clock read per mutation |
| `test/data/durability_test.dart` · `'a lamb row is durable before the write returns'` | `12 §3.5`'s form: a real file, `db.close()`, a cold `AppDatabase(NativeDatabase(file), seedOnCreate: false)`, then the read |
| `test/features/lambing_entry_test.dart` · `'the lambs list renders in stroke order and a dead lamb is not re-sorted'` | `LAMB 1 / 2 / 3` agree with the tally beside them |
| `test/features/lambing_entry_test.dart` · `'a dead lamb renders the word DEAD and the same colour token as an alive lamb'` | *Death is a word.* The colours are compared, not inspected |
| `test/features/lambing_entry_test.dart` · `'stillborn renders its own word and never DEAD'` | Its own bucket, always |
| `test/features/lambing_entry_test.dart` · `'an unrecorded sex renders NOT RECORDED and Sex.unknown renders its own word'` | The two facts stay two facts on screen |
| `test/features/lambing_entry_test.dart` · `'an unrecorded birthweight prints a dotted rule and NOT RECORDED, never 0'` | The visible gap, `indelible.md` §7.12 |
| `test/features/lambing_entry_test.dart` · `'a lamb with no tag is listed and counted'` | Identity is the row |
| `test/features/lambing_entry_test.dart` · `'a struck lamb stays in place, ruled through, and keeps its ordinal'` | Indelible rule 1: it does not move, collapse, fade or disappear |
| `test/features/lambing_entry_test.dart` · `'no lamb sub-row renders an event time'` | `Lambs` has no provenance quad, so it has nothing honest to print |
| `test/features/lambing_entry_test.dart` · `'the lamb row binds no banned gesture'` | Source text: no `Dismissible`, `Draggable`, `onLongPress`, `onPan`, `onScale`, `onForcePress` |
| `test/data/lambing_ambiguous_hour_test.dart` · `'a lamb created at 01:30 in the repeated hour keeps one unambiguous created_at through a reopen'` | **`uk-zone`.** `atFixed(DateTime(2026, 10, 25, 1, 30), …)`, close, cold start, and `created_at` is one of the two candidate instants and is unchanged |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **The two throwing verbs are exactly two** — `beginLambing` and `addLamb`. Making this one return `WriteOutcome` for consistency is the change R32 exists to refuse.
- **§12.4 at the write path** — a repository may not import `lib/domain/validation/` (R53) and may not originate a value the shepherd did not give. `sex` stays nullable.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'addLamb returns a LambId, throws on failure, and commits before the widget rebuilds'` passes, and was seen to fail first for the stated reason
- [ ] returns an id and throws — the only other verb that does
- [ ] the row is committed before the rebuild
- [ ] `birth_dam` is set here and can never be updated afterwards
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the birth-dam immutability is proved against the **trigger**, not against a Dart guard
- [ ] `sex` is nullable and `Sex.unknown` appears nowhere on the write path
- [ ] `appNow()` is called exactly once per mutation, and `clock.now(` and `DateTime.now(` appear nowhere
- [ ] the whole insert is one transaction, and the boundary carries the comment N24 will read
- [ ] the list renders in stroke order and agrees with the tally beside it
- [ ] a dead lamb carries the word and the same colour token as an alive one
- [ ] `stillborn` is its own word; a lamb with no tag is listed; an unset weight prints a gap, never `0`
- [ ] no lamb sub-row renders an event time
- [ ] the row binds no banned gesture, and a struck lamb stays in place
- [ ] the durability case reopens a real file and is not a mock
- [ ] the ambiguous-hour case exists and is tagged `uk-zone`

## 8. Verification

```bash
fvm flutter test test/data/lambing_repository_test.dart
fvm flutter test test/data/durability_test.dart
fvm flutter test test/features/lambing_entry_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

```bash
grep -rn "Sex.unknown" lib/data/                                        # expect zero
grep -rn "clock.now(\|DateTime.now(" lib/data/ lib/features/lambing/    # expect zero
grep -rn "Dismissible\|Draggable\|onLongPress" lib/features/lambing/    # expect zero
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(data): addLamb — a committed row per stroke`

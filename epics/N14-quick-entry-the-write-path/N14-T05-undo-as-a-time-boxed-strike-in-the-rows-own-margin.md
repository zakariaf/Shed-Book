# N14-T05 — Undo as a time-boxed strike in the row's own margin

| | |
|---|---|
| **Epic** | [N14 — Quick Entry: the write path](epic.md) · `00-README` §9 step 5 (2 of 2) |
| **Task** | 5 of 7 |
| **Depends on** | N14-T04 |
| **Commit** | one commit · `feat(quick_entry): undo as a time-boxed strike in the margin` |

## 1. Why this task exists

Undo is a **strike in the margin of the row itself**, its window stated in seconds, and it
never survives process death — because an undo that outlives the app is a draft state with a friendly
name, and *assume the phone dies* forbids it.

It is also the task that makes P1 pay for itself. `struck` / `struck_at` were ruled onto every table at
N00-T05 and frozen at N07-T08; until now nothing has written them. Indelible's Rule 1 — *nothing is
ever removed, only struck* — stops being a design aspiration here and becomes two columns with a
writer.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §5.4 | the write path and the tap budget |
| `docs/engineering/00-README.md` | §2.4, §8 step 3 | every write commits immediately; the row is created on screen entry |
| `docs/engineering/11-monetization-and-store.md` | §2 | `EntryContext` and decision #91's live-entry rule |
| `docs/engineering/07-screens.md` | **§15.1–§15.6 (undo per verb — amended by this task)** | the per-verb table, the window, why it is §12.4-compliant, that it never survives process death, and that swipe-to-delete stays banned |
| `docs/skills/02-build-manifest.md` | **§4.1 (P2)** · §4.4 defect 2 | undo becomes a time-boxed strike, the window is stated in seconds, and which stamps must clear the 18 px floor |
| `docs/design/indelible.md` | §1.1–§1.2 (Rule 1: nothing is removed, only struck) · §6.2 mark 5 (the strike line: 3 px madder, `transform-origin: left`, doubled in red-shift) · §7.3 (the **Struck** row state, in full) · §8 Screen 3 (`STRIKE` is an in-stream word button; the row does not move) | every pixel of the strike |
| `epics/N00-decisions-rulings-and-the-calendar/N00-T05-rule-p1-struck-struck-at-on-every-table.md` | the whole file | **P1's ruling** — the column names, the tables that carry them, and the export half |
| `docs/engineering/CONVENTIONS.md` | §2.13 (the canonical verb list — **this task adds a row**) · §4.6 (column naming) · §5.1–§5.3 (the *strike* vocabulary; `delete` is not the word) · R31 (`undoLabel`) · R37 | **BINDING**: what the new verb may be called and where it is registered |
| `docs/engineering/01-architecture.md` | §4.5 (undo is per verb, not generic; it does not survive process death) · §7.1 | decision #69, stated as architecture |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-marks-and-strikes` | a strike is its subject and this is the canonical one |
| `shed-screens-and-routing` | undo and delete are its routing concern |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/quick_entry_test.dart`
- **Test** — `'the undo window is stated in seconds and does not survive a restart'`
- **Why it is red today** — nothing undoes a write, and the framework's answer is again a SnackBar action.

```bash
fvm flutter test test/features/quick_entry_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion in two halves. **Stated in seconds:** the rendered affordance contains
`kStrikeWindow.inSeconds.toString()` — read from the constant, never a literal in the test — so a
changed constant changes the copy or the test fails. **Does not survive a restart:** commit a lambing,
tear the widget tree down and `pumpApp` a fresh one against the *same* database, and assert the strike
affordance is absent while the row is still there.

**Green.** The minimum code that passes, and nothing beyond it — the margin strike, the stated window, and a restart test that proves it is gone.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step, and say so in the commit message.** `struck` and `struck_at` were ruled at N00-T05
and frozen at N07-T08. If they are not on `lambings`, **stop** — after the freeze that is a migration on
a table that points at the shepherd's records, and it is an owner conversation.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/lambing_repository.dart` | **Edit.** Add the strike verb. This is the first **edit verb** on `lambings`, which R37 permits only because the table carries the provenance quad |
| 2 | `lib/features/quick_entry/quick_entry_write_controller.dart` | **Edit.** Add `strike(LambingId)` through `guard()`, and build the `SaveReceipt` with its `undo` callback and `undoLabel` |
| 3 | `lib/core/ui/feedback.dart` | **Edit.** Declare `kStrikeWindow` here, beside the three functions, because this is the file that owns the receipt's lifetime |
| 4 | `lib/core/ui/components/shed_receipt.dart` | **Edit.** The margin affordance: the `STRIKE` word button in the row's margin cell, and the `STRUCK HH:mm` stamp that replaces it |
| 5 | `lib/l10n/app_en.arb` | **Edit.** The window message, with `{seconds}` as a placeholder and a `description`. The number is never typed into copy |
| 6 | `docs/engineering/07-screens.md` §15.1, §15.2, §15.4, §15.6 | **Amend.** See §5.3 — three of its rows and its window definition are superseded by P1 and P2 |
| 7 | `test/features/quick_entry_test.dart` | **Edit.** The anchor and the cases below |
| 8 | `test/data/lambing_repository_test.dart` | **Edit.** The repository half: the row stays, the columns move |

### 5.2 The signatures

The verb is **new to `CONVENTIONS §2.13`** — the canonical list has `voidTreatment` for the treatment
soft-void and nothing for a lambing, because P1 post-dates it. Add the row in this commit rather than
inventing a name in a repository file:

```dart
// lib/data/lambing_repository.dart — register in CONVENTIONS §2.13 in this commit.
//
// `strike`, never `delete`, never `remove`, never a generic undo(id):
// decision #69 refuses a generic undo, and CONVENTIONS §5.2 makes *strike* the
// project word. The row STAYS. Indelible Rule 1: nothing is ever removed.
Future<WriteOutcome> strikeLambing(LambingId id);
```

```dart
// lib/core/ui/feedback.dart
/// The strike window, in absolute time. Stated in seconds because P2 forbids
/// defining it as a widget's lifetime, and declared once because the copy and
/// the timer must never disagree: the ARB message takes
/// kStrikeWindow.inSeconds as a placeholder.
const Duration kStrikeWindow = Duration(seconds: 20);
```

```dart
// lib/features/quick_entry/quick_entry_write_controller.dart
Future<void> strike(LambingId id) => guard(() async {
      final repo = await ref.read(lambingRepositoryProvider.future);
      return repo.strikeLambing(id);
    });
```

**The number is not ruled by any document.** `07 §15.2` defined the window as a widget lifetime and P2
abolished that definition without supplying a replacement figure. 20 s is a proposal, not an authority:
long enough to notice a mis-pressed slab with gloves on, short enough that it is gone before the next
lamb. **Record the chosen value as a ruling in the PR body**, because it is a number a shepherd reads
on screen, not an implementation detail.

### 5.3 The details that are easy to get wrong

- **`07 §15.1`'s first two rows say "hard delete", and they are superseded.** *Begin a lambing →
  **hard delete**, allowed only while it has zero child rows* was written before P1 gave every table
  `struck` / `struck_at` and before P2 made undo a strike. Indelible Rule 1 is absolute — *"There is no
  delete. Not banned — absent. The concept of erasure does not exist in the product"* — and P1's own
  ruling requires that every CSV carries the columns and every struck row is exported and marked.
  **Amend `07 §15.1` rows 1 and 2 and `§15.2`'s window in this commit**, struck with their reason,
  per `00-README` §10. A document that still prescribes a hard delete will be followed by N16 for
  `addLamb` and by N18 for foster.
- **A strike is not a delete and not a soft-delete.** The row keeps its position, its legibility and
  its place in every query that is not explicitly filtering. Indelible §7.3: the strike is a 3 px
  madder line across the record column at 50 % height, all row text drops from full and mid ink to
  `--ink-low` — **5.75:1, still fully legible, permanently** — and the margin prints `STRUCK 03:41`.
  *"The row stays in position — it does not move, collapse, or fade."* An animation that collapses the
  row is the bug this sentence exists to prevent.
- **`struck_at` is a real instant from `appNow()`, in the same mutation.** One clock read; the stamp
  the margin prints is that instant formatted by `formatShedTime`, and it is a *machine fact about the
  strike*, not an event time — so it takes no provenance quad of its own and never claims one.
- **The window is measured in absolute time and never in civil time.** `kStrikeWindow` is a `Duration`
  compared against instants, so a window opened at 01:59 on the clocks-back night lasts 20 s and not
  3600 s. This is the same reasoning decision #3 applies to the withdrawal clear date: civil-day
  arithmetic in the UK spring is how you lose an hour.
- **The window is not a `Timer` that outlives the screen** (`07 §15.2`: *"no timer that outlives the
  screen"*). Tie it to the widget that renders the affordance and cancel it on dispose. And do **not**
  reconstruct it after a restart: `01 §4.5` and `07 §15.4` — there is no state restoration, no undo
  affordance is ever rebuilt from storage, and no copy anywhere may say "you can undo this later."
- **The word "Undo" is only used where the record disappears** (`07 §15.3`), and after P1 the record
  never disappears. Quick Entry's affordance is the word `STRIKE`, in `--madder-ink`, as an in-stream
  word button — which is also why `SaveReceipt.undoLabel` is a field and not a constant (R31). Set it
  explicitly here rather than letting the `'UNDO'` default through.
- **`STRUCK HH:mm` keeps the stamp exemption; `AUTO-CAPTURED` does not.**
  `02-build-manifest §4.4` defect 2 names exactly three stamps that are the sole carrier of their
  meaning and must clear the 18 px floor: `DEAD`, `AUTO-CAPTURED`, `DERIVED FROM N STROKES`. The
  strike stamp is accompanied by the strike line itself, so it stays exempt. Do not "fix" all of them.
- **No swipe, ever.** `Dismissible` and `Draggable` are banned outright (decision #101) and Indelible
  §9 lists swipe-to-delete as *absent* rather than banned. The strike is a tap on a ≥ 64 × 64 word
  button in the margin cell — Indelible sizes the margin cell at 68 × 64 and calls it a target in its
  own right.
- **The strike goes through `guard()` like every other mutation**, and it gets a double-tap test.
  Striking twice must leave one strike and one `struck_at`, not two writes and a moved timestamp.
- **`ewe_touches` is not rewound.** The strike changes the lambing row; it does not un-touch the ewe.
  The recents strip is a UI cache of *"she was looked at"*, and that remains true.
- **Every read query on this branch must decide what a struck row means, out loud.** P1's ruling is
  that every query decides. For N14 there is exactly one: `quickEntryDeckProvider`'s recents bucket
  reads `ewe_touches` and is unaffected. The ledger renders struck rows **in place, struck** — that is
  the whole point. Say so in a comment where the query is, so N16 and N26 inherit a decision rather
  than a habit.
- **The CSV and backup halves are not this task's.** P1's ruling puts `struck` and `struck_at` in all
  three CSV shapes and in the JSON backup row shape; those land in N21-T02 and N22. Do not add an
  export column here — but do make sure the columns are written such that N21 can find them.
- **`lib/data/` still may not import `lib/domain/validation/`** (R53). A strike raises no warning and
  never could.

### 5.4 The full test set

| File | Case | What it asserts |
|---|---|---|
| `test/features/quick_entry_test.dart` | `'the undo window is stated in seconds and does not survive a restart'` | **The anchor.** Both halves: the rendered number equals `kStrikeWindow.inSeconds`, and a fresh tree over the same database shows no affordance |
| | `'the affordance is the word STRIKE and never the word UNDO'` | R31 and Indelible §6.1 — every action is a word, and this one is `STRIKE` |
| | `'the copy never contains the word delete'` | Indelible Rule 1, as a source-text assertion over the ARB |
| | `'the struck row stays in position and stays legible'` | Its vertical offset before and after are equal; its text is still found by a keyed finder |
| | `'the strike affordance is at least 64 by 64 and carries a semanticLabel'` | The margin cell is a target in its own right |
| | `'no Dismissible or Draggable appears in the row subtree'` | The gesture ban, at the one place a swipe would be idiomatic |
| | `'a double tap on STRIKE strikes the row once'` | Two taps, **no pump between them**, one `struck_at` |
| | `'the affordance disappears when the window elapses and the row remains'` | `fakeAsync` past `kStrikeWindow`; the row is untouched |
| | `'the affordance disappears when the next write commits'` | One receipt at a time — the next save replaces it (`06 §10.3`) |
| | `'no copy anywhere says the record can be undone later'` | Source text over `app_en.arb`. `07 §15.4` |
| `test/data/lambing_repository_test.dart` | `'strikeLambing sets struck and struck_at and deletes nothing'` | The row count is unchanged; both columns move; every other column is byte-identical |
| | `'strikeLambing writes struck_at from one appNow() and leaves occurred_at alone'` | The event time is not the strike time and must never be overwritten |
| | `'striking twice is idempotent in effect'` | One strike, one `struck_at` — the second call does not move the stamp |
| | `'a struck lambing is still returned by an unfiltered select'` | Nothing is hidden at the data layer; filtering is a query's explicit decision |
| | `'strikeLambing returns WriteOutcome and never throws for a missing row'` | It is not one of the two throwing verbs (R32) |

**The `uk-zone` group.** The window is the time-shaped part. Put it in a
`group('DST', …, tags: 'uk-zone')` that asserts the ambient zone **first and loudly**.

| Case | What it asserts |
|---|---|
| `'this group requires TZ=Europe/London'` | Fails loudly under a wrong `TZ` rather than silently asserting UTC |
| `'DST: a strike window opened at 01:59 on the clocks-back night elapses after kStrikeWindow and not an hour later'` | Absolute time, not civil time. A window computed from local wall-clock arithmetic lasts an extra hour here and nowhere else |
| `'DST: struck_at renders as HH:mm with no offset suffix inside the ambiguous hour'` | The margin stamp is a wall-clock time like every other; the disambiguation lives in the stored instant |

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Safety rule §12.4 — never silently correct.** A strike removes nothing and rewrites no value. The
  app never chooses which of two values is right; it prints both (`07 §15.3`).
- **Write path** — the strike is itself a committed write through `guard()`. There is no pending state,
  no "will be deleted in 20 seconds" queue, and nothing that resolves later.

## 7. Definition of Done

- [ ] `'the undo window is stated in seconds and does not survive a restart'` passes, and was seen to fail first for the stated reason
- [ ] the window is stated in seconds, in words, on screen
- [ ] undo does not survive a restart
- [ ] the undone row is struck, not deleted — P1's columns exist for this
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the verb is `strikeLambing`, returns `WriteOutcome`, and is registered in `CONVENTIONS §2.13` in this commit
- [ ] `kStrikeWindow` is declared once, its `inSeconds` is the ARB placeholder, and no literal number appears in copy or in a test
- [ ] the chosen window value is recorded as a ruling in the PR body
- [ ] `07 §15.1` rows 1 and 2 and `§15.2`'s window are amended in this commit, struck with their reason (P1, P2)
- [ ] the struck row keeps its position, its `occurred_at` and its legibility; the row count does not change
- [ ] the affordance goes through `guard()` and has a double-tap test with no pump between the taps
- [ ] no timer outlives the screen and no affordance is ever rebuilt from storage
- [ ] `drift_schemas/` and `lib/core/db/tables/` are untouched by this diff

## 8. Verification

```bash
fvm flutter test test/features/quick_entry_test.dart
fvm flutter test test/data/lambing_repository_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

```bash
grep -rn "Dismissible\|Draggable\|onHorizontalDrag\|onLongPress" lib/ --include='*.dart'  # expect zero
grep -rni "delete\|undo later\|can be undone" lib/l10n/app_en.arb                          # expect zero
grep -rn "Duration(seconds:" lib/features/quick_entry/ --include='*.dart'                  # expect zero
# the window is kStrikeWindow, declared once in lib/core/ui/feedback.dart
git diff --stat -- drift_schemas/ lib/core/db/tables/                                      # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(quick_entry): undo as a time-boxed strike in the margin`

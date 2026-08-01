# N16-T02 — The lamb tally — strokes with a true five-bar gate

| | |
|---|---|
| **Epic** | [N16 — Lambing Entry and the P8 ruling](epic.md) · `00-README` §9 step 6 (2 of 5) |
| **Task** | 2 of 10 |
| **Depends on** | N16-T01 |
| **Commit** | one commit · `feat(lambing_entry): the lamb tally, with birth type counted not chosen` |

## 1. Why this task exists

One slab per lamb as it arrives, drawn as real five-bar-gate strokes, and **birth type
derived from the count** and labelled `(COUNTED)`. Nobody ever chooses it. This is what makes §12.4
structural instead of procedural: there is no chooser to disagree with the data.

`indelible.md` §7.9 states the same thing from the design side and forbids softening it: *"Birth type:
there is no segmented control, because there is no choice. This is the signature of the direction and
it must not be softened."* This task is the mechanism. The canary it ships — no widget in the tree
carries a `birth_type` key — is what keeps the chooser dead for the life of the project, because four
published artefacts still describe one and T02a has not amended them yet.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/design/indelible.md` | **§6.2 mark 4 (the tally stroke: `8 × 30`, 3 px gap, the five-bar SVG with `M-3 27 L46 3`)** · §6.3 (2 px strokes, butt caps, `currentColor`, no fills except the tally) · §7.1 (the corner slab, 160 × 140) · §7.7 (`COUNTED` is an **unboxed** stamp) · §7.9 (no birth-type control) · §5.1 (a press is a fill change only) · §5.4 (one 10 ms tick on a slab press) · §9 screen 4 | every pixel, mark and motion of the tally |
| `CLAUDE.md` | **P8** · P2 · the 3am floor · the banned words | birth type is derived from the tally strokes and labelled `(COUNTED)`; any skill implying a selector is wrong |
| `docs/engineering/07-screens.md` | §6.3 (the state table) · §6.4 (the tap costs — **superseded on the birth-type row, amended in T02a**) · §15.1 (undo per verb: `addLamb` is a hard delete) | the states, and what the screen costs |
| `docs/engineering/CONVENTIONS.md` | §2.9 (`BirthType` codes 1..5) · §2.13 (**`addLamb` returns an id and throws**) · §2.4 (`WriteOutcome`) · §3.4 (write controllers are always `.autoDispose`) · §4.5 (widget keys) · R32 · R46 · R70 | the verb, the controller and the key |
| `docs/engineering/02-state-di-navigation.md` | §7 (**`WriteController.guard()`**, and the `ref.listen` switch) · §7.1 rules 1 and 4 (guard prevents concurrency, not repetition; the double-tap test has no pump) | why two taps make one lamb and three presses make three |
| `docs/engineering/06-design-system.md` | §12 (the component inventory — **this task adds a row to it**) · §6 (tap targets) · §10.1 (the haptic vocabulary) | where the tally widget lives and what it must obey |
| `docs/engineering/03-data-model-and-schema.md` | §5.5 (`Lambs`, `birth_dam`, the nullable `sex`) · §5.4 (`lambing_consistency`'s two guards) · §2.1 (P1's `struck` / `struck_at`) | what a stroke writes |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.1 (a `CustomPaint` announces nothing) · §3.2 (the eight label rules) · §8 (no domain noun literal in an ARB message) | the tally's semantics and its copy |
| `shed-book-spec.md` | §7.2 · §12.4 | the lambing fields, and never silently correct an entry |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-marks-and-strikes` | the tally, the gate and the counted label are its subject |
| `shed-write-path` | each stroke is its own committed write, immediately |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/lambing_entry_test.dart`
- **Test** — `'three strokes print TRIPLET (COUNTED) and no widget carries a birth_type key'`
- **Why it is red today** — nothing counts lambs, and both `07 §5.4` and `12 §10.1` still describe a five-button birth-type chooser that P8 abolished.

```bash
fvm flutter test test/features/lambing_entry_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion in two ways. Produce the three strokes by **pressing the slab three times**, not
by seeding rows — that is what makes the case prove the whole path, and it is the same three presses
`indelible.md` §9 describes. Then read the count back out of SQLite in the same test
(`SELECT COUNT(*) FROM lambs` is 3), so a label that agrees with a widget field rather than with the
database cannot pass.

**Green.** The minimum code that passes, and nothing beyond it — the tally widget, the derived label, and a tree-walking assertion that no `birth_type` key
exists anywhere.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step, and say so in the commit message.** `lambs` froze at N07-T08. There is a domain step
(one pure function) and a data step (one verb).

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/domain/birth_type.dart` | **Extended** (created at N06-T01). Gains the top-level `BirthType? countedBirthType(int strokes)` beside `expectedLambCount`. Pure, no clock, no Flutter — `00-README` §8 step 2 |
| 2 | `lib/data/lambing_repository.dart` | **Extended.** `addLamb` — one `db.transaction`, `appNow()` called **once**, `RecordedTime.capture(now)`, `newUid()`, `birth_dam` denormalised from `lambings.ewe`. Returns `LambId` and **throws**; it is one of only two verbs that do (R32). Its contract is proved in T03 |
| 3 | `lib/core/ui/components/shed_tally.dart` | **New.** `ShedTally` — the stroke rendering, five-bar form and struck strokes. It lives in `lib/core/ui/components/` and not under `lib/features/lambing/widgets/` because the pen tile (N19) and the withdrawal day tally (N20-T03) print the **same mark**, and layer rule 6 forbids a sibling-feature import. R70: every shared component lives here |
| 4 | `docs/engineering/06-design-system.md` §12 | **Extended, in this commit.** One row added to the component inventory for `ShedTally`. `06 §12` is the inventory of everything the twelve screens need; a component that exists and is not in it is the next reader's licence to build a second one |
| 5 | `lib/features/lambing/lambing_entry_controller.dart` | **Extended.** `LambingWriteController extends WriteController` with `Future<void> addLamb(LambingId)`, and `lambingWriteControllerProvider` — `NotifierProvider.autoDispose<LambingWriteController, WriteState>` (`CONVENTIONS §3.4`, **always** `.autoDispose`). `lambingControllerProvider` is a banned spelling (`07 §6.1`) |
| 6 | `lib/features/lambing/widgets/lamb_tally_row.dart` | **New.** The screen-side row: the slab on the right, `ShedTally` in its fixed 132 px column, and the derived type cell with its unboxed `COUNTED` stamp |
| 7 | `lib/features/lambing/lambing_entry_screen.dart` | **Extended.** Mounts the tally row and the `ref.listen` on `lambingWriteControllerProvider` that turns a `WriteDone` into feedback |
| 8 | `lib/l10n/app_en.arb` | **Extended.** The derived-type words, the `COUNTED` stamp, the struck suffix, the slab label and the tally's semantics string — each with a `description`, and each taking the animal noun as a **placeholder** fed by `terminologyProvider`, never as a literal (`10 §8`) |
| 9 | `test/features/lambing_entry_test.dart` | **Extended.** The anchor, the counted-label cases, the canary, the double-tap case and the geometry cases |
| 10 | `test/design/components_test.dart` | **Extended** (created at N10-T06). `ShedTally`'s own geometry and semantics cases |
| 11 | `test/domain/birth_type_test.dart` | **Extended** (created at N06-T01). `countedBirthType`'s cases |
| 12 | `test/data/lambing_ambiguous_hour_test.dart` | **Extended.** A stroke pressed at 01:30 in the repeated hour |

### 5.2 The signatures

The domain function. The `null` at five and above is load-bearing, exactly as `expectedLambCount`'s is:

```dart
// lib/domain/birth_type.dart
/// The COUNTED type: what N un-struck strokes make.
///
/// Returns null at five and above, and that is deliberate. `BirthType.quintPlus`
/// means "more than four, count NOT declared" — an open-ended DECLARATION. A
/// counted five is not open-ended: the app knows there are exactly five rows.
/// Mapping the count onto `quintPlus` would throw away the number the tally
/// exists to hold, so the presentation edge prints the count itself instead.
BirthType? countedBirthType(int strokes) => switch (strokes) {
      1 => BirthType.single,
      2 => BirthType.twin,
      3 => BirthType.triplet,
      4 => BirthType.quad,
      _ => null,
    };
```

The verb. **`{Sex? sex}`, not `{required Sex sex}`, and this needs a ruling — see §5.3:**

```dart
// lib/data/lambing_repository.dart
/// Returns an id and THROWS — one of only two verbs that do (R32). There is no
/// id to hand back on failure and the caller has nowhere to put a WriteOutcome.
Future<LambId> addLamb(LambingId lambing, {Sex? sex});
```

The write controller, and the screen's one listener:

```dart
// lib/features/lambing/lambing_entry_controller.dart
final class LambingWriteController extends WriteController {
  /// `addLamb` throws rather than returning WriteOutcome, so the guard body
  /// converts: the id is discarded here (the stream re-emits with the new row)
  /// and a failure reaches guard()'s catch-all as an UnexpectedFailure.
  Future<void> addLamb(LambingId lambing) => guard(() async {
        final repo = await ref.read(lambingRepositoryProvider.future);
        await repo.addLamb(lambing);
        return const WriteCommitted();
      });
}

final lambingWriteControllerProvider =
    NotifierProvider.autoDispose<LambingWriteController, WriteState>(
  LambingWriteController.new,
);
```

The mark, straight off `indelible.md` §6.2. Geometry is not negotiable and comes from `context.tokens`:

```dart
// lib/core/ui/components/shed_tally.dart
/// One filled 8 x 30 rect per mark, 3 px gap; the FIFTH mark of any group is a
/// diagonal drawn across the previous four — a true five-bar gate, because a
/// shepherd counting to fourteen lambs in a night should not have to count to
/// fourteen. A struck mark keeps its rect and takes a 3 px madder line through
/// it. There is NO minus control: a tally that can go down is not a tally.
class ShedTally extends StatelessWidget {
  const ShedTally({
    super.key,
    required this.marks,
    required this.semanticLabel,
    this.struck = const <int>{},
  });

  final int marks;
  final String semanticLabel;   // required: a CustomPaint announces NOTHING
  final Set<int> struck;        // zero-based indices of struck marks
}
```

### 5.3 The details that are easy to get wrong

- **The tally must hold no counter.** `int _lambs = 0; setState(() => _lambs++)` is the obvious Flutter
  implementation and it is a draft state with a friendly name. It double-counts under a double-fire,
  it survives a failed write, and it disagrees with the database the moment anything else changes a
  row. `marks` comes from `data.lambs.where((l) => !l.struck).length` on the stream. **A stroke exists
  on screen if and only if a row exists in SQLite** — that is the whole of "every write commits
  immediately", expressed as geometry rather than as a promise, and it is why this task's Definition
  of Done can claim it without a Save button anywhere.
- **`guard()` prevents concurrency, not repetition, and that is exactly right here.** `02 §7.1` rule 1:
  once the first write returns, a second tap is a second write — *"and for 'add lamb' that is
  correct."* Do not add a cooldown; it would drop a legitimate second lamb. The double-tap test has
  **no pump between the taps** (rule 4) — with a pump the first write completes, `state` becomes
  `WriteDone`, and the second tap legitimately produces a second row.
- **`addLamb` throws; it does not return `WriteOutcome`.** R32 and R3. `07 §6.1`'s
  `switch (outcome) { case WriteCommitted(:final id) … }` is wrong twice over — `WriteCommitted` is
  non-generic and its field is `insertedId`. The `guard()` body above is the bridge, and it is the
  only place in the feature that has to bridge.
- **`{required Sex sex}` cannot ship, and this task is where it is noticed.** `CONVENTIONS §2.13`
  publishes `Future<LambId> addLamb(LambingId lambing, {required Sex sex})`. A slab press records a
  lamb *arriving* — nobody has looked at it. `lambs.sex` is nullable and R45 is explicit that `NULL`
  means *not recorded* and is never `Sex.unknown`, which means *"the shepherd looked and could not
  tell"*. Passing `Sex.unknown` to satisfy the signature is the app originating a fact on the
  shepherd's behalf: §12.4, at the write path. **Take the ruling here, in this commit** — a numbered
  ruling in `CONVENTIONS §6`, next free number **R75**, changing §2.13's signature to `{Sex? sex}` and
  listing the files it touches. Do not implement around it and do not leave both spellings live; if
  the ruling cannot be taken, the PR body carries it as open with both sides cited.
- **`birth_dam` is set here and can never be updated.** It is denormalised from `lambings.ewe` at
  insert and enforced by a `BEFORE UPDATE` trigger in `views.drift`, not by Dart. Read it from the
  lambing row inside the same transaction — never from the screen's copy, which is one frame old.
- **`COUNTED` is an *unboxed* stamp and the distinction is readable from ten feet.** `indelible.md`
  §7.7: boxed = a state of the animal (`PENNED`, `DEAD`, `BARREN`); unboxed = a note about the record
  itself (`AUTO`, `EDITED`, `DERIVED`, `COUNTED`, `STRUCK`). Putting a border on `COUNTED` says the
  lamb is counted rather than the type.
- **`COUNTED` is a 14 px stamp and the body floor is 18 px.** `00-PLAN-CRITIQUE.md` names this as
  Indelible artefact defect 2 and gives this task the `COUNTED` half. The typography exemption test is
  N09-T05's; here the label must satisfy it — a stamp is exempt only where it is the **sole carrier**
  of its meaning, and `COUNTED` is not: the strokes beside it carry the same fact. Render the type
  word at the record size and let the stamp be the note about it.
- **Five strokes is a diagonal, not five uprights.** The fifth mark of every group crosses the
  previous four — `M-3 27 L46 3`, `stroke-width: 4`, `stroke-linecap: butt`. Ten lambs is two gates.
  Get this wrong and the whole argument for a tally (counting at a glance) is gone while the widget
  still looks plausible in review.
- **The tally column is 132 px fixed and right-aligned** (`indelible.md` §9). The live row's usable
  width beside the slab is `301 − 160 − 12 = 129 px`, which is why the row prints in two lines. Do not
  let the tally expand: at fourteen lambs the marks stay inside their column, they do not push the tag
  off the row.
- **A `CustomPaint` announces nothing** (`10 §3.1`). `ShedTally` takes a **required** `semanticLabel`
  for the same reason `ShedTapTarget` does. The string is `"3 lambs"` shaped — one number and the
  user's own noun from `terminologyProvider` — and it is resolved by the caller, because layer rule 7
  forbids `lib/core/ui/` from importing riverpod.
- **No domain noun appears literally in an ARB message** (`10 §8`, decision #61). `5 lambs (counted)`
  is a placeholder message with the term fed in; hard-coding "lamb" is the named defect, and this
  screen is where a shepherd who calls them something else notices first.
- **The press is a fill change and one 10 ms tick.** `indelible.md` §5.1: no scale, no lift, no
  ripple — *"a target that shrinks under a cold thumb is a target you miss."* §5.4 gives the slab press
  one 10 ms haptic tick. The new stroke fades 0 → 1 opacity over `--motion-ink` 120 ms with **zero
  translation**, and under reduce-motion the duration resolves to **zero**, not to shorter — the stroke
  still prints, instantly.
- **The slab is the largest target in the app and is capped at 110%.** 160 × 140 at scale 1.0,
  176 × 154 at 200% (`indelible.md` §3.6) — it is a thumb target, not a reading target. Every other
  interactive element on this screen is ≥ 64 × 64 against the 60 pt floor.
- **The canary walks the tree, not the source.** A source grep for `birth_type` under `lib/features/`
  is worth having as a second line, but the assertion that matters iterates every `Key` in the pumped
  widget tree and fails on any whose string contains `birth_type`. That catches a key composed at
  runtime, which a grep does not.
- **There is no `ShedChoiceRow` on this screen yet, and the one that arrives in T04 is ease-only.**
  N10-T06 already carries the doc comment naming P8. If `ShedChoiceRow` appears anywhere in this
  task's diff, a chooser is being built.
- **Undo is a margin strike, not a SnackBar.** `07 §15.1` gives `addLamb`'s undo window as
  *"SnackBar"*; **P2 supersedes it** — `showSnackBar(` appears nowhere in `lib/`, including
  `feedback.dart`, and `test/policy/no_snackbar_test.dart` has been green since N14-T04. Undo is the
  time-boxed strike in the row's own margin built at N14-T05, its window stated in seconds.

### 5.4 The full test set

| File · case | What it asserts |
|---|---|
| `test/features/lambing_entry_test.dart` · `'three strokes print TRIPLET (COUNTED) and no widget carries a birth_type key'` | **The anchor.** Three slab presses, `find.text` on the derived label, `SELECT COUNT(*) FROM lambs` is 3, and the tree walk over every `Key` |
| `test/features/lambing_entry_test.dart` · `'one stroke prints SINGLE, two print TWIN and four print QUAD'` | The 1–4 mapping, through the widget rather than through the domain function |
| `test/features/lambing_entry_test.dart` · `'five strokes print the count itself and never the word for quad or more'` | `countedBirthType` returns null at five; the label prints the number with the terminology noun |
| `test/features/lambing_entry_test.dart` · `'a lambing with no lambs prints NOT RECORDED in the type cell and no type word'` | `07 §6.3`'s opening state. Birth type is **never** defaulted to single |
| `test/features/lambing_entry_test.dart` · `'a struck lamb keeps its stroke and the label reads TWIN (COUNTED, 1 STRUCK)'` | Indelible rule 1 and P1. The count excludes it; the page does not |
| `test/features/lambing_entry_test.dart` · `'a double-fired slab press commits exactly one lamb'` | `guard()`. Two `tester.tap` calls with **no pump between them**, then `pumpAndSettle` |
| `test/features/lambing_entry_test.dart` · `'two presses with a pump between them commit two lambs'` | The other half of `02 §7.1` rule 1 — guard prevents concurrency, not repetition |
| `test/features/lambing_entry_test.dart` · `'the tally widget declares no mutable count'` | Source text over `lib/core/ui/components/shed_tally.dart` and `widgets/lamb_tally_row.dart`: no `setState`, no `StatefulWidget`, no private `int` field |
| `test/features/lambing_entry_test.dart` · `'no ShedChoiceRow is mounted on this screen'` | The chooser cannot arrive by component either |
| `test/features/lambing_entry_test.dart` · `'the slab measures at least 160 by 140 and is capped at 110 percent at textScaler 2.0'` | `indelible.md` §3.6's one capped target |
| `test/features/lambing_entry_test.dart` · `'the tally announces its count with the user term from terminologyProvider'` | Opens `tester.ensureSemantics()`; overrides the term and asserts the announcement changes with it |
| `test/design/components_test.dart` · `'ShedTally draws the fifth mark of each group as a diagonal'` | Five marks give four rects and one diagonal; ten marks give eight rects and two diagonals |
| `test/design/components_test.dart` · `'ShedTally requires a semanticLabel at the type level'` | Source text. A `CustomPaint` announces nothing without one |
| `test/design/components_test.dart` · `'a struck mark keeps its rect and takes a line through it'` | The mark is never removed |
| `test/design/components_test.dart` · `'the stroke fade is opacity-only and resolves to zero under reduce motion'` | `prefersReducedMotion` from N09-T09; zero, not shorter, and the mark still prints |
| `test/domain/birth_type_test.dart` · `'countedBirthType maps one to four and returns null at five and above'` | Cases for 0, 1, 2, 3, 4, 5 and 14 |
| `test/domain/birth_type_test.dart` · `'countedBirthType never returns quintPlus'` | The open-ended member belongs to declaration only |
| `test/data/lambing_ambiguous_hour_test.dart` · `'a lamb added at 01:30 in the repeated hour reads back as 01:30 after a reopen'` | **`uk-zone`.** `atFixed(DateTime(2026, 10, 25, 1, 30), …)`, close the file, cold start, read back `occurred_at.local` and `time_source` |

## 6. Constraints that bind this task

- **P8, and it is an owner ruling** — birth type is derived from the tally strokes and labelled `(COUNTED)`. Four published artefacts still describe a chooser; T02a amends them. Nothing in this diff builds one, and the canary is what proves it after everybody has forgotten why.
- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider. The slab is 160 × 140 and there is no minus control anywhere on the tally.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'three strokes print TRIPLET (COUNTED) and no widget carries a birth_type key'` passes, and was seen to fail first for the stated reason
- [ ] birth type is derived from the strokes, always
- [ ] the label reads `(COUNTED)`
- [ ] no widget in the tree carries a `birth_type` key — the canary that keeps the chooser dead
- [ ] each stroke commits immediately, with no Save button
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the tally holds **no** counter field; `marks` is derived from the stream on every rebuild
- [ ] the fifth mark of every group is a diagonal, and ten lambs render as two gates
- [ ] a struck mark keeps its rect, the count excludes it, and the label carries `1 STRUCK`
- [ ] there is no minus control, no decrement and no `ShedChoiceRow` anywhere in the diff
- [ ] a double-fired press with no pump between the taps commits exactly one lamb
- [ ] `ShedTally` lives in `lib/core/ui/components/` and has a row in `06 §12`'s inventory, added in this commit
- [ ] `ShedTally` requires its `semanticLabel`, and the announcement uses the term from `terminologyProvider`
- [ ] `addLamb`'s `sex` parameter is ruled — a numbered `CONVENTIONS §6` ruling in this commit, or carried into the PR body as open with both sides cited
- [ ] the ambiguous-hour case exists and is tagged `uk-zone`

## 8. Verification

```bash
fvm flutter test test/features/lambing_entry_test.dart
fvm flutter test test/design/components_test.dart
fvm flutter test test/domain/birth_type_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

Prove the canary is doing its job — plant the chooser, watch it fail, delete it:

```bash
# add a ShedChoiceRow keyed 'lambing_entry.birth_type.twin' to the screen
fvm flutter test test/features/lambing_entry_test.dart   # expect the canary to fail by name
git checkout -- lib/features/lambing/
```

```bash
grep -rn "birth_type" lib/features/            # expect zero until T06 adds declared_birth_type
grep -rn "setState\|StatefulWidget" lib/core/ui/components/shed_tally.dart   # expect zero
grep -rn "showSnackBar(" lib/                  # expect zero — P2
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(lambing_entry): the lamb tally, with birth type counted not chosen`

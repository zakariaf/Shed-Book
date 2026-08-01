# N14-T06 — `tap_budget_test.dart` — five taps to a committed lambing row

| | |
|---|---|
| **Epic** | [N14 — Quick Entry: the write path](epic.md) · `00-README` §9 step 5 (2 of 2) |
| **Task** | 6 of 7 |
| **Depends on** | N14-T05 |
| **Commit** | one commit · `test(features): five taps from unlock to a committed lambing row` |

## 1. Why this task exists

Unlock → three digits → confirm → *Lambing*. The row is committed on screen entry, so
**five taps genuinely produce a committed lambing** — that is the claim this epic can honestly hold. The
sixth tap, the first tally stroke, belongs to N16-T02a where the tally exists. Keyed finders only.

The dishonest version of *"under fifteen seconds"* is a widget test that measures elapsed wall time.
`flutter test` runs under `FakeAsync`; the number is meaningless and on CI it is load noise. **Do not
write it.** Taps are what the shepherd spends time on, and taps are deterministic — so the budget is
decomposed and the count is the assertion.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §5.4 | the write path and the tap budget |
| `docs/engineering/00-README.md` | §2.4, §8 step 3 | every write commits immediately; the row is created on screen entry |
| `docs/engineering/11-monetization-and-store.md` | §2 | `EntryContext` and decision #91's live-entry rule |
| `docs/engineering/12-testing.md` | **§10.1 (the three tap budgets, `TapCounter` and `countedTap` printed)** · §5.1 (`pumpApp`) · §5.2–§5.3 (seeding, and why `selectEwe` is private to this file) · §2.1–§2.3 (installing time; the ambiguous hour) | the harness, the counter, and where the helpers live |
| `docs/engineering/07-screens.md` | §5.3 (states, and the `412 →` frame-1 window that costs an extra tap) · §5.5 (order is tap → write → await → change the UI) | why the count depends on the index being resolved |
| `docs/engineering/CONVENTIONS.md` | §4.5 (widget keys) · §1 (`test/` tree) · R57, R59 | the exact key spellings, which are test contracts from this commit on |
| `epics/00-PLAN-CRITIQUE.md` | **S4** (the budget splits 5 + 1) · §11.3 (this anchor) · §11.5 | why five and not six, and where the sixth tap went |
| `docs/skills/02-build-manifest.md` | §4.2 (P8 — birth type is derived from the tally, labelled `(COUNTED)`) | the key this test must never tap |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | the tap budget, its keyed finders and what it may assert today |
| `shed-write-path` | the budget is an assertion about the write path's shape |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/tap_budget_test.dart`
- **Test** — `'unlock to a committed beginLambing row costs 5 taps and no typing'`
- **Why it is red today** — there is no budget test, and the old plan's version tapped a Lambing Entry key that does not exist and that P8 abolished.

```bash
fvm flutter test test/features/tap_budget_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so all three halves are pinned: `expect(c.taps, 5)` — **exactly** five, not
`lessThanOrEqualTo`, because a budget that only has a ceiling silently absorbs a sixth tap;
`expect(c.textEntries, 0)`; and `expect(await countLambings(db), 1)` reading the committed row **out of
the database**, never off the screen.

**Green.** The minimum code that passes, and nothing beyond it — the five-tap path on keyed finders, with the row read back from the database rather than
from the screen.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Tests only.** This task adds no `lib/` file and must not: if the budget cannot be met with what T01
to T05 landed, the fix is in one of those tasks, not here. Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `test/features/tap_budget_test.dart` | **New.** `TapCounter`, the `CountedActions` extension, the private `selectEwe` helper, the anchor and the cases below. It is the file R57 names, and it grows one budget per epic — foster in N18-T05, repeat-treatment in N20-T04 |
| 2 | `test/support/seeds.dart` | **Edit, only if needed.** `seedEwe(db, tag: '412')` already exists. Nothing else belongs here — `selectEwe` is a private top-level function in the budget file, deliberately (`12 §5.3`) |

### 5.2 The signatures

`12 §10.1` prints the counter and the extension; type them as they are, in this file, not in
`test/support/`:

```dart
// test/features/tap_budget_test.dart — spec §5, §15; 07-screens.md §1.3
final class TapCounter {
  int taps = 0;
  int textEntries = 0;
}

extension CountedActions on WidgetTester {
  Future<void> countedTap(Finder f, TapCounter c) async {
    c.taps++;
    await tap(f);
    await pumpAndSettle();
  }
}
```

The five taps, in order, on the keys `CONVENTIONS §4.5` fixes:

| # | Key | What it does |
|---|---|---|
| 1 | `quick_entry.keypad.digit_4` | a digit |
| 2 | `quick_entry.keypad.digit_1` | a digit |
| 3 | `quick_entry.keypad.digit_2` | a digit |
| 4 | `quick_entry.confirm` | the confirm bar, labelled with the **outcome** — "Use 412" here |
| 5 | `quick_entry.event.lambing` | commits `beginLambing`; the row exists from this instant |

`selectEwe(tester, '412')` is a private top-level function in this file that performs taps 1–4 and is
reused by the double-tap case. It is **not** in `test/support/` and must not be moved there: it encodes
a screen's tap sequence, which is `07-screens.md`'s to change, and hoisting it would make every screen
change a harness change and quietly stop the budget test counting what it claims to count
(`12 §5.3`).

### 5.3 The details that are easy to get wrong

- **The old sixth tap is gone and its key must never come back.** `12 §10.1`'s published test spends
  its sixth tap on `find.byKey(const Key('lambing_entry.birth_type.twin'))`. `LambingEntryScreen` does
  not exist until N16, **and P8 abolished the birth-type chooser** — birth type is derived from the
  tally strokes and labelled `(COUNTED)`. Both `07 §5.4`'s six-tap composition and `12 §10.1`'s sixth
  tap are superseded artefacts, and **N16-T02a is the commit that amends them**, together with
  `CONVENTIONS §4.5`'s worked example and R59, which still publish `lambing_entry.birth_type.twin` as
  the model key. This task does not amend them; it leaves a comment naming N16-T02a, so the next reader
  does not "restore" the sixth tap.
- **Assert exactly 5, not at most 5.** `12 §10.1`'s original reads `lessThanOrEqualTo(6)`, which is the
  right shape for a ceiling and the wrong shape for a claim. The epic's demo sentence is *five taps*;
  a `<=` assertion passes at four, which would mean a tap went missing, and at five after someone
  merged two controls that should be separate.
- **The frame-1 window costs an extra tap and will make this test read 6 if you let it.** `07 §5.3`:
  until `tagIndexProvider` resolves, the confirm key reads `412 →` and makes *no existence claim*;
  creating a new ewe in that window costs one extra tap. `pumpApp` ends with `pumpAndSettle()`, so a
  seeded database resolves before the first tap — but assert it rather than assume it: check the
  confirm key's label is the **outcome** ("Use 412") before counting. This is the only place in the app
  where a tap cost varies, and it exists on purpose.
- **`countedTap` pumps and settles after every tap, and that is right here.** It is the double-tap
  test that must not pump (`02 §7.1` rule 4) — different property, different file section. Do not
  "harmonise" them.
- **Read the row from the database, not from the screen.** `countLambings(db)` from
  `test/support/reads.dart` (T02 added it). A budget test that asserts a rendered string proves the
  screen changed, not that the record exists — and *"the only signal that proves the database
  changed"* is the database (`07 §5.5`).
- **No typing, and no system keyboard.** `expect(c.textEntries, 0)` is half of it; the other half is
  that `07 §5.6` bans the system keyboard outright — the OS numeric keypad puts `1` at the top on iOS,
  cannot be sized to 60 pt, cannot carry a "Create 412" key, and a third-party Android IME can render
  bright in a dark shed. Assert `find.byType(EditableText)` finds nothing on this path.
- **Two paths, two budgets, and both are five.** *Use 412* (the ewe exists) and *Create 412* (she does
  not) both cost 3 digits + confirm + Lambing. Write both: the create path is the one that goes through
  `FreeTierPolicy`, and it is the one a cap regression would break.
- **The budget rationale belongs in the file.** `12 §10.1` keeps it as a comment so the next person
  knows why the number is what it is: taps at a generous 1.5 s each — gloved, wet, cold, dark — against
  the 15 s claim, leaving room for unlock and cold start. Five taps is about 7.5 s. Carry the comment
  across and update the arithmetic to five.
- **Do not measure time.** No `Stopwatch`, no `DateTime` difference, no `expect(elapsed, lessThan(...))`.
  `12 §10.1` says it in bold: the number is meaningless under `FakeAsync` and is load noise on CI.
- **`kPumpableVariants` is not touched.** It has one entry from N13-T07 and N14 adds no screen. The
  matrix count is derived from the variant list, never typed.

### 5.4 The full test set

`test/features/tap_budget_test.dart`, through `pumpApp` (N12-T05).

| Case | What it asserts |
|---|---|
| `'unlock to a committed beginLambing row costs 5 taps and no typing'` | **The anchor.** Exactly 5, zero text entries, one committed row read from the database |
| `'the create-on-the-fly path also costs 5 taps'` | No seeded ewe. The confirm key reads "Create 412"; the ewe and the lambing both exist afterwards |
| `'the confirm key is labelled with the outcome before the count begins'` | Guards against counting inside the `412 →` frame-1 window |
| `'no EditableText is reachable on the five-tap path'` | `07 §5.6`'s system-keyboard ban, made mechanical |
| `'the committed row carries an auto-captured time and no declared birth type'` | The row the five taps produce is the honest one: `time_source = 'auto'`, `declared_birth_type` null |
| `'no widget on this path carries a birth_type key'` | P8's canary, one epic early. N16-T02 owns the full version |
| `'selecting a penned ewe from the strip costs 1 tap, then Lambing is the second'` | `07 §5.4`'s tile row — the common case is cheaper than the keypad path, and that is the design |
| `'the budget is unchanged at 400 ewes'` | Seed a large flock; the count is a property of the interaction, not of the data |
| `'the budget is unchanged over the free cap, locked'` | Decision #90. The cap adds no tap, no row and no dialog on the live path |

**The `uk-zone` group.** The row this test commits is time-shaped, so the budget is asserted once more
inside the ambiguous hour. Put it in a `group('DST', …, tags: 'uk-zone')` that asserts the ambient zone
**first and loudly**.

| Case | What it asserts |
|---|---|
| `'this group requires TZ=Europe/London'` | Fails loudly under a wrong `TZ` rather than silently asserting UTC |
| `'DST: five taps at 01:30 on the clocks-back night commit one row with one local_date'` | `withClock` at both instants of the repeated hour: the tap count does not change, and the two rows carry the same `local_date` and different `occurred_at` |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **3am** — this test *is* the 3am claim, decomposed. Five taps, keyed finders, no typing, no system
  keyboard, and no measurement of wall time.
- **P8** — birth type is derived from the tally and labelled `(COUNTED)`; no key named `birth_type`
  appears in the tree.

## 7. Definition of Done

- [ ] `'unlock to a committed beginLambing row costs 5 taps and no typing'` passes, and was seen to fail first for the stated reason
- [ ] five taps, no typing, no system keyboard
- [ ] the assertion reads the committed row from the database
- [ ] a comment names N16-T02a as the home of the sixth tap
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the count is asserted as **exactly** 5, never `lessThanOrEqualTo`
- [ ] both paths are covered — *Use 412* and *Create 412* — and both cost five
- [ ] the confirm key's outcome label is asserted before the count begins, so the frame-1 window cannot inflate it
- [ ] `selectEwe` is a private top-level function in this file and is **not** in `test/support/`
- [ ] no `Stopwatch`, no elapsed-time assertion, and no `lambing_entry.birth_type.twin` anywhere
- [ ] this diff adds no file under `lib/`
- [ ] the `uk-zone` DST group exists, is tagged and fails loudly under a wrong `TZ`

## 8. Verification

```bash
fvm flutter test test/features/tap_budget_test.dart
TZ=Europe/London fvm flutter test test/features/tap_budget_test.dart --tags uk-zone
make check
make test
```

```bash
grep -rn "birth_type" lib/ test/ --include='*.dart'          # expect zero — P8
grep -rn "Stopwatch\|elapsed" test/features/tap_budget_test.dart   # expect zero
grep -rn "selectEwe" test/support/ --include='*.dart'        # expect zero — it is private to the budget file
git diff --stat -- lib/                                      # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(features): five taps from unlock to a committed lambing row`

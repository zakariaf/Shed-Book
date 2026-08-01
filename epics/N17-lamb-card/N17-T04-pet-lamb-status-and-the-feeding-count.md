# N17-T04 — Pet lamb status and the feeding count

| | |
|---|---|
| **Epic** | [N17 — Lamb Card](epic.md) · `00-README` §9 step 6 (3 of 5) |
| **Task** | 4 of 5 |
| **Depends on** | N17-T03 |
| **Commit** | one commit · `feat(lamb_card): pet lamb status and the feeding count` |

## 1. Why this task exists

Spec §7.3's pet lamb / bottle status with a feeding count — the field that tells a
shepherd in April which lambs cost them six weeks of bottles.

It is also the smallest task in the epic with the largest gap between what the design says and what
the frozen schema can hold, and that gap is the whole of §5.3.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | **§5.5** | `pet_lamb BOOLEAN DEFAULT 0`, `bottle_feeds INTEGER DEFAULT 0`, `CHECK (bottle_feeds >= 0)` |
| `docs/engineering/03-data-model-and-schema.md` | **§5.6** | `care_events.kind` is a **closed** `CHECK` of four values, each wired to a notification channel id frozen at release |
| `docs/engineering/07-screens.md` | §7.3 | the tap costs — pet lamb 1 tap, `+1 feed` 1 tap on a 72 pt counter button |
| `docs/design/indelible.md` | **§7.8** | the number stepper: `64 × 64` · `88 × 64` · `64 × 64`, no repeat-on-hold, the At-floor state, the Unset state, and *"never a slider"* |
| `docs/design/indelible.md` | §7.7, §7.13, §8 screen 5 | `PET LAMB` as a **boxed** stamp, the word button that toggles it, and the feed row |
| `docs/engineering/06-design-system.md` | §6, §12 | `ShedTapTarget` is the only sanctioned tap surface, with a required `semanticLabel`; the fifteen-component inventory, which has **no stepper** |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.2, §8.4 | the label rules, and every ARB message carrying a `description` |
| `docs/engineering/09-export-formats.md` | §5 cols 33–34, §4 | `pet_lamb` and `bottle_feeds` are exported columns, and **no exported numeric column may be negative** |
| `docs/engineering/CONVENTIONS.md` | §3.4, §4.5, §5.3 | the closed controller list, widget keys, and the banned words |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | the status and the count are two immediate writes |
| `indelible-controls` | the count control, which is a target, not a stepper with tiny arrows |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/lamb_card_test.dart`
- **Test** — `'incrementing the feeding count commits immediately and the control is at least 64 by 64'`
- **Why it is red today** — nothing records pet lamb status.

```bash
fvm flutter test test/features/lamb_card_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the status toggle, the count control over `ShedTapTarget`, both committing on tap.

Sharpen the assertion: read `lambs.bottle_feeds` back out of the database **inside the same pump
frame** as the tap, and measure the rendered size of the `+` target with `tester.getSize` rather than
asserting the constant you passed in. A size assertion that reads its own input proves nothing.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 steps 3 (the write verbs), 5 (the controller), 6 (UI + ARB) and 7 (tests). **Steps 1
and 2 are skipped and the commit message says so**: both columns are N07-T04's and nothing here
computes.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `test/features/lamb_card_test.dart` | edit | The anchor, written first |
| 2 | `lib/data/lambing_repository.dart` | edit | `setPetLamb`, `recordBottleFeed`, `correctBottleFeeds` — three event verbs, each its own `_db.transaction()`, each returning `WriteOutcome` |
| 3 | `lib/features/lambing/lambing_write_controller.dart` | edit | Three methods through `guard()`. Still **no** `lambCardWriteControllerProvider` |
| 4 | `lib/features/lambing/widgets/pet_lamb_row.dart` | new | The word button that toggles the status and the boxed `PET LAMB` stamp it prints |
| 5 | `lib/features/lambing/widgets/feed_count_cell.dart` | new | `[ − ] [ 4 ] [ + ]` composed from three `ShedTapTarget`s. Feature-local by design — see §5.3 note 5 |
| 6 | `lib/features/lambing/lamb_card_screen.dart` | edit | Both land in the card, beneath the parentage rows |
| 7 | `lib/l10n/app_en.arb` | edit | `lambCardPetLamb`, `lambCardPetLambSet`, `lambCardPetLambClear`, `lambCardFeedCountLabel`, `lambCardFeedCountUnset`, `lambCardFeedIncrement`, `lambCardFeedDecrement`, `lambCardFeedCountSpoken`, each with a `description` |

### 5.2 The signatures

```dart
// lib/data/lambing_repository.dart
// New names, declared here under CONVENTIONS §4.2's event-verb rule and listed in the PR body.

/// The status only. It does NOT touch bottle_feeds — see §5.3 note 3.
Future<WriteOutcome> setPetLamb(LambId lamb, {required bool petLamb});

/// +1, committed. One statement: `bottle_feeds = bottle_feeds + 1`, so two taps
/// racing cannot both read 3 and both write 4.
Future<WriteOutcome> recordBottleFeed(LambId lamb);

/// A correction, not a decrement loop. `feeds` is the value the shepherd means;
/// the CHECK refuses anything below zero and the verb never clamps.
Future<WriteOutcome> correctBottleFeeds(LambId lamb, int feeds);
```

Widget keys, per `CONVENTIONS §4.5`:

```
lamb_card.pet_lamb
lamb_card.feed.increment      lamb_card.feed.decrement      lamb_card.feed.value
```

Semantics, per `10 §3.2`: the `+` target's `semanticLabel` is the ARB string, not the glyph — a
screen reader announcing `+` is announcing nothing. The count itself is a **live region**, so the new
total is spoken after each tap without a second gesture.

### 5.3 The details that are easy to get wrong

1. **Indelible asks for a feed *event*; the frozen schema gives you a *counter*. The counter wins,
   and the reason matters.** `indelible.md` §8 screen 5 says: *"pressing `+` also prints a timestamped
   row into the stream: `FEED 4 — 06:40`. Every feed is an event; the count is just their total."*
   There is no table that can hold that. `care_events.kind` is a **closed** `CHECK` —
   `('colostrum','navel_dip','stomach_tube','warmed')` — and `03 §5.6` states the cost of a fifth
   value in one line: *"each is wired to a notification channel id frozen at release (decision #65).
   Adding a fifth is a schema migration and a channel decision, which is the correct amount of
   friction."* The schema froze at N07-T08. So: **`lambs.bottle_feeds` is the stored fact**, the
   screen prints the total, and no per-feed row is written. Printing `FEED 4 — 06:40` from a counter
   would invent a timestamp the record does not have, which is precision inflation — the same
   §12.4 failure as claiming an hour for a civil death date. Raise the divergence in the PR body;
   do not resolve it with a migration.
2. **`bottle_feeds` has `DEFAULT 0`, and the screen must not render a confident `0`.** The Definition
   of Done says the count is never defaulted to anything but absent, and the two facts are compatible
   once you read them precisely: the column's `0` means *no feeds recorded*, and `pet_lamb` is what
   says whether the count is meaningful at all. `pet_lamb = 0, bottle_feeds = 0` is "not a pet lamb";
   `pet_lamb = 1, bottle_feeds = 0` is "a pet lamb, no feeds recorded yet". The **screen** never
   originates a number the shepherd did not press: until pet-lamb status is set, the cell prints
   Indelible §7.8's Unset state — `—·—` over a 2 px dotted rule with `NOT RECORDED · SKIPPABLE` above
   it — not a `0`.
3. **Clearing pet-lamb status must not zero the count.** The instinct is to tidy: if she is no longer
   a pet lamb, the feeds are meaningless. They are not — *"which lambs cost them six weeks of
   bottles"* is exactly the April question, and a lamb weaned off the bottle is still a lamb that was
   on it. `setPetLamb(lamb, petLamb: false)` writes one column. Unlike T03's death columns there is
   no `CHECK` forcing them to move together, so this is a choice, and the choice is: keep the count.
4. **`+1` is `bottle_feeds = bottle_feeds + 1` in SQL, not read-modify-write in Dart.** Two taps a
   frame apart both reading 3 and both writing 4 loses a feed silently. `guard()` refuses a
   *concurrent* call, which is the double-tap defence, but it does not serialise two deliberate taps
   two seconds apart, and it is not the mechanism for this.
5. **There is no `ShedStepper`, and inventing one is a change to a binding inventory.** `06 §12`
   lists fifteen components and none of them is a stepper; N10 built exactly those. `06 §3.1`'s rule
   settles it: *"A widget that only ever appears on one screen stays in that feature's `widgets/`."*
   The Lamb Card is the only v1 screen with a feed counter, so `feed_count_cell.dart` is
   feature-local, composed from `ShedTapTarget`. If Settings later needs one for reminder intervals,
   **that** is when it moves to `lib/core/ui/components/` — promoting a proven widget is cheap;
   adding a sixteenth component to `06 §12` now goes through the amendment rule.
6. **No repeat-on-hold, and no slider — both are absolute.** Indelible §7.8: *"No repeat-on-hold —
   long-press-only behaviour is banned and hold-to-repeat is its cousin. One press, one step."*
   §7.8 also opens with *"Never a slider — a slider with a cold finger is a random number
   generator."* The gate rows `gesture.dismissible`, `gesture.draggable` and `gesture.tooltip` catch
   the widget classes; a hand-rolled `Timer.periodic` behind an `onLongPress` catches nobody's eye
   except a reviewer's.
7. **At the floor, `−` renders dimmed and does not fire.** Indelible §7.8: *"`−` drops to `--ink-low`
   and does not fire. No error, no shake, no toast."* It stays a ≥ 64 × 64 target — a target that
   changes size under a cold thumb is a target you miss — and its semantics node loses its tap action
   so a screen reader does not announce an activation that will not happen. Do **not** clamp in Dart
   and write `0` anyway: `CHECK (bottle_feeds >= 0)` is the real floor, and `09 §4` depends on it —
   *"no exported numeric column can be negative"* is a global invariant of the CSV writer.
8. **Tapping the value opens the keypad; it is not a third step.** Indelible §7.8: *"Tapping the
   value opens the keypad sheet for direct entry — because stepping from 0 to 41 is 41 presses and
   the shepherd knows the number."* That path calls `correctBottleFeeds`, not `recordBottleFeed`.
   The keypad is integer-only here, so the decimal key renders **inert** and the grid does not
   re-legend (`06 §8`).
9. **`PET LAMB` is a boxed stamp, and the box means something.** Indelible §7.7: boxed = *a state of
   the animal* (`PENNED`, `LAMBED`, `DEAD`, `PET LAMB`); unboxed = *a note about the record itself*
   (`AUTO`, `EDITED`, `COUNTED`, `STRUCK`). Rendering `PET LAMB` unboxed is a small pixel error that
   says the wrong thing from ten feet away, which is the distance this system is designed for.
10. **Neither write has an undo verb.** `07 §15.1` lists no row for either: they correct forward and
    `updated_at` moves. The `+` is not "undone" by a `−` in the receipt sense — the `−` is a
    correction the shepherd makes, visible as the new total. And **P2**: there is no SnackBar to hang
    an undo on. The confirmation is the committed number, re-rendered from the stream.
11. **Nothing here reads `entitlementProvider`.** The Lamb Card is one of the five shed screens
    (`11 §8`, decision #90): nothing monetization-related renders at any entitlement state or hour.
    A feed counter is exactly the kind of "premium feature" affordance that gets added in season two;
    `no_monetization_test.dart` (N30-T08) is what stops it.

### 5.4 The full test set

**`test/features/lamb_card_test.dart`** — extended.

| Case | What it pins |
|---|---|
| `'incrementing the feeding count commits immediately and the control is at least 64 by 64'` | **the anchor.** `tester.getSize(find.byKey(Key('lamb_card.feed.increment')))` ≥ 64 × 64 at scale 1.0, and `bottle_feeds` read back as 1 in the same frame |
| `'the increment control is still at least 64 by 64 at textScale 2.0 with bold text'` | the size is a floor, not a fixed height |
| `'a double tap on plus commits twice, and a concurrent double tap commits once'` | two deliberate taps → 2; `tester.tap(); tester.tap();` inside one frame → 1, through `guard()` |
| `'the count is stored as an increment, not a read-modify-write'` | source read of `lambing_repository.dart`: the statement contains `bottle_feeds + 1` and no `select` of the old value |
| `'the minus control does not fire at zero and exposes no tap action'` | `bottle_feeds` stays 0; no `SemanticsAction.tap` on the node; the target is still ≥ 64 × 64 |
| `'the count renders unset until pet lamb status is set'` | Indelible §7.8's Unset state, not a `0`. Note 2 |
| `'clearing pet lamb status leaves the feeding count intact'` | note 3, as a test, so a future tidy-up fails |
| `'tapping the value opens the keypad and writes a correction'` | `correctBottleFeeds`, and the decimal key is inert |
| `'the pet lamb stamp is boxed and carries the word'` | note 9; and the state is not encoded by colour alone (`10 §5.2`) |
| `'no repeat-on-hold anywhere on this cell'` | source read: no `onLongPress`, no `Timer.periodic`, no `LongPressGestureRecognizer` under `lib/features/lambing/` |
| `'no feed writes a care_events row'` | `countRows(db.careEvents)` is unchanged after ten `+` taps. Note 1, as the test that stops the migration |
| `'the plus target carries a semanticLabel that is not the glyph'` | `10 §3.2` |
| `'no monetization widget renders at any entitlement state or hour'` | the shed-screen rule, asserted locally and again in `no_monetization_test.dart` at N30-T08 |

**`test/data/lambing_repository_test.dart`** — extended.

| Case | What it pins |
|---|---|
| `'correctBottleFeeds with a negative value is refused by the CHECK'` | the `WriteOutcome` is `WriteFailed`, the row is unchanged, and nothing was clamped |
| `'recordBottleFeed is atomic across two interleaved calls'` | fire both without awaiting the first; the final value is 2 |
| `'setPetLamb writes one column'` | `bottle_feeds` and every other column unchanged |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **`00-README` §8 step 1 skipped** — no file under `drift_schemas/` or `lib/core/db/tables/` may appear in the diff. Note 1 is the reason that line is here rather than in a generic checklist.

## 7. Definition of Done

- [ ] `'incrementing the feeding count commits immediately and the control is at least 64 by 64'` passes, and was seen to fail first for the stated reason
- [ ] both writes commit immediately
- [ ] the increment control is at least 64 × 64
- [ ] the count is never defaulted to anything but absent
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/features/lamb_card_test.dart
fvm flutter test test/data/lambing_repository_test.dart
grep -rn "onLongPress\|Timer.periodic\|Slider(" lib/features/lambing/    # expect: nothing
grep -rn "care_events\|careEvents" lib/features/lambing/                 # reads only, never a feed
git diff --name-only main -- drift_schemas/ lib/core/db/tables/          # expect: nothing
dart tool/check_policy.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(lamb_card): pet lamb status and the feeding count`

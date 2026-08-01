# N25-T04 — Mute as a strike, and nothing that nags twice

| | |
|---|---|
| **Epic** | [N25 — Reminders screen](epic.md) · `00-README` §9 step 9 (2 of 2) |
| **Task** | 4 of 6 |
| **Depends on** | N25-T03 |
| **Commit** | one commit · `feat(reminders): mute as a visible strike` |

## 1. Why this task exists

Spec §7.6: *nothing nags twice*. Mute is a **strike** on the row — visible, reversible,
never a deletion — and a muted reminder is never re-projected.

Indelible, Screen 9: *"`MUTE` **does not remove it** — it prints `MUTED 03:44` and strikes the row, which
stays in the list at 5.75:1, because a muted reminder is a decision you made and you may want to see it
at 6am."* And Indelible's Rule 1: *"If a proposal makes information disappear from the page, it is wrong.
Undo is a strike. **Mute is a strike.**"*

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/design/indelible.md` | Screen 9, Rule 1, §"Row states" | `MUTED 03:44`, the 3 px madder line, `--ink-low` at 5.75:1, the row stays in position |
| `docs/design/indelible.md` | §"Stamps", `--motion-strike` | unboxed `MUTED` stamp; 180 ms linear left-to-right; **0 ms** under reduce-motion |
| `docs/engineering/07-screens.md` | §11.1 | muted rows are **listed but never counted**, and sit at the foot of their bucket |
| `docs/engineering/07-screens.md` | §11.4, §15.6 | mute is 1 tap; `Dismissible` and `Draggable` are banned outright |
| `docs/engineering/08-platform-integration.md` | §2.4 | `muted = 0` in `soonestPendingReminders`, byte-identical with `schedulable_total` |
| `docs/engineering/03-data-model-and-schema.md` | §5.10 | `reminders.muted` is a `boolean().withDefault(const Constant(false))` — a mutable column |
| `docs/engineering/06-design-system.md` | §6.2, §12 | `ShedTapTarget` is the only sanctioned tap surface; `tapMin` = 60 |
| `docs/engineering/10-accessibility-and-i18n.md` | §8 | colour is never the only channel; a marker is never the only signal |
| `shed-book-spec.md` | §7.6 | all reminders individually mutable; nothing nags twice |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-marks-and-strikes` | mute is a strike and this is its rendering |
| `shed-platform-gateways` | a muted row must never reach the projection |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/reminders_test.dart`
- **Test** — `'a muted reminder is struck, still visible, and never projected again'`
- **Why it is red today** — nothing mutes, and the obvious implementation deletes the row.

The assertion, sharpened: seed three open reminders, tap `reminders.row.<id>.mute` on the middle one,
then assert **four** things — the row is still found by its key; it carries the `MUTED` stamp and the
strike; `countReminders(db)` is still 3; and `FakeNotificationScheduler.projected` after the follow-up
reconcile contains the other two ids and **not** this one. Then assert `schedulableTotal` fell by one
while the number of rendered rows did not change.

```bash
fvm flutter test test/features/reminders_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the strike, the projection filter, and the read-back.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 Files touched, in `00-README` §8's order

| §8 step | File | What changes, and why |
|---|---|---|
| 1 — schema | **skipped** | `reminders.muted` exists and is frozen. Nothing new is stored |
| 3 — write path | `lib/data/reminder_repository.dart` | **new verbs** `mute(ReminderId)` / `unmute(ReminderId)` — one `UPDATE`, one `appNow()` on `updated_at`, no delete anywhere |
| 5 — controllers | `lib/features/reminders/reminder_write_controller.dart` | `mute` / `unmute` through `guard()`, then `reconcile()` after the transaction returns |
| 5 — controllers | `lib/features/reminders/reminders_controller.dart` | `_partition` sorts muted rows to the **foot of their bucket** without changing which bucket they are in |
| 6 — UI | `lib/features/reminders/widgets/reminder_row.dart` | the `MUTE` word button, the 3 px strike, the unboxed `MUTED HH:mm` stamp, the ink drop to `--ink-low` |
| 6 — UI | `lib/core/ui/components/` | **check before adding.** N10's component inventory owns the strike primitive; if a shared strike exists, use it. A second strike implementation is a `/simplify` finding waiting to happen |
| 6 — ARB | `lib/l10n/app_en.arb` | `MUTE` / `UNMUTE` labels, the `MUTED {time}` stamp, the row's mute-state `semanticLabel` |
| 7 — tests | `test/data/reminder_repository_test.dart` | the repository half |
| 7 — tests | `test/features/reminders_test.dart` | the anchor plus §5.4's cases |

### 5.2 The signatures

```dart
// lib/data/reminder_repository.dart
// Both return WriteOutcome; neither deletes anything, ever.
Future<WriteOutcome> mute(ReminderId id);
Future<WriteOutcome> unmute(ReminderId id);
```

The rendering contract, from Indelible's row-state table — four channels, none of them colour alone:

| Channel | Value |
|---|---|
| Line | 3 px `--madder-ink` across the record column at 50 % row height, `transform-origin: left` |
| Ink | all row text drops from `--ink-full` / `--ink-mid` to `--ink-low` — **5.75:1, still fully legible, permanently** |
| Stamp | `MUTED 03:44`, unboxed, `--t-stamp` (14 px), in `--madder-ink` |
| Position | the foot of its bucket — the row does not leave the bucket, collapse or fade |

Every one of those comes from `context.tokens`. A raw hex under `lib/` is a build-breaking defect
(`token.raw_color`, scoped to `lib/` by R55, with only four `[exempt]` lines and none of them here).

Motion: `--motion-strike` is 180 ms `linear`, left-to-right, and it is *the only animation in the app with
a direction* — linear because the gesture being represented is a pen drawn across a page at constant
speed. Under `prefersReducedMotion` it is **0 ms**: the line is drawn full-width instantly. Resolve it
through `lib/core/ui/motion.dart`'s `prefersReducedMotion`, never through `MediaQuery` directly.

Widget keys: `reminders.row.<id>.mute`, `reminders.row.<id>.unmute`, `reminders.row.<id>.muted_stamp`.

### 5.3 The details that are easy to get wrong

- **The obvious implementation deletes the row, and the second-most-obvious hides it.** Both are wrong for
  the same reason: 07 §11.1 says *"'nothing nags twice' (§7.6) means it does not **fire** twice, not that
  it disappears."* The row stays in the list, in its bucket, forever.
- **Muted rows are listed and not counted, and the copy must not confuse the two.** 07 §11.1 spells out
  the failure: *"a shepherd could count fourteen rows on screen against a line reading 'all 12 are stored
  in the app' and conclude the app had lost two."* `schedulable_total` excludes muted; the list does not.
  Muting therefore **decrements the honest line while the row count on screen stays the same**, and that
  is correct. Assert both halves in one test so nobody "fixes" the discrepancy later.
- **`muted = 0` in `soonestPendingReminders` must stay byte-identical to `schedulable_total`'s.** 08 §2.4:
  *"if the projection and the count applied different eligibility predicates the line would be a lie by
  arithmetic."* N24-T05 wrote the projection predicate; T01 wrote the count's. Do not touch either — this
  task adds the *writer*, not a third predicate.
- **Mute is a word button, never a swipe.** `Dismissible` and `Draggable` are banned outright (decision
  #101, 07 §15.6), and swipe-to-mute is the single most likely wrong instinct here. The persistent word
  button on a ≥ 60 pt `ShedTapTarget` is what gives recoverability without a tracked gesture that fails on
  a marginal capacitive contact through a wet glove.
- **Unmute is legal, and it is the one strike in the app that lifts.** `reminders.muted` is a mutable
  boolean (03 §5.10), not a `struck_at` timestamp, so clearing it removes the strike. 🚩 **If the owner
  later wants "muted 03:44, unmuted 06:02" to be visible history, that is a new column on a table that
  points at the shepherd's records — after the N07-T08 freeze, therefore a forward-only migration on
  somebody else's phone in April.** Record the decision now rather than discovering it in N34.
- **Muting must re-reconcile, and it must do so after the transaction.** Otherwise the muted reminder
  stays on the lock screen until the next resume and fires exactly once more — which is the letter of
  "nothing nags twice" broken by a missing call. Call site #3, debounced 500 ms, never inside
  `db.transaction()` (08 §2.4).
- **`FakeNotificationScheduler` will catch a double projection for you.** 12 §4.3's fake throws on a
  duplicate id with the message *"spec §7.6 'nothing nags twice': reminder N projected twice"*, and on
  more than `ReminderBudget.forPlatform()` projections. Do not re-implement those assertions in the test;
  do make sure the test reaches the fake.
- **The strike must survive a text scale of 2.0 and bold text.** It is drawn at 50 % row height across the
  record column; a strike positioned from a constant pixel offset drifts off the text as the row grows.
  T06's matrix cells will find this; find it here.
- **Colour is never the only channel, and a marker is never the only signal** (decision #106, 10 §8). The
  strike line is a shape, the `MUTED` stamp is a word, and the position at the foot of the bucket is a
  third channel. Remove the colour and the row still reads as muted — that is the test.
- **The stamp is 14 px, which is below the 18 pt floor, and that is permitted for exactly three reasons**
  (Indelible §"The 14px stamp and the 18pt rule"): it is never body text, it is ≤ 12 characters all-caps
  at 0.14 em tracking, and it is never the sole carrier of its meaning. `MUTED 03:44` satisfies all three.
  No other text on this row may go below 18 pt.
- **The stamp's time is `HH:mm`, 24-hour, `en_GB`** — and it is the time the mute happened, formatted by
  `lib/core/ui/formatters.dart`. Not the due time, not a duration.
- **Muting is not "over-cap" and not a cap surface.** Nothing on this screen watches
  `entitlementProvider`.

### 5.4 The full test set

`test/data/reminder_repository_test.dart`

| Case | What it holds |
|---|---|
| `'mute sets muted = 1 and deletes nothing'` | `countReminders` unchanged |
| `'unmute clears muted and the row is unchanged otherwise'` | no other column moves except `updated_at` |
| `'mute moves updated_at with one appNow() call'` | one instant per mutation |
| `'a muted row is excluded from soonestPendingReminders'` | the projection predicate, exercised directly |
| `'a muted row is excluded from schedulable_total but present in the list'` | the two predicates, in one assertion |

`test/features/reminders_test.dart`

| Case | What it holds |
|---|---|
| `'a muted reminder is struck, still visible, and never projected again'` | **the anchor**, §4's assertion |
| `'muting costs one tap on a 60 pt target and there is no swipe path'` | `find.byType(Dismissible)` is `findsNothing` |
| `'the muted row carries the strike, the MUTED stamp and the foot-of-bucket position'` | three channels |
| `'the muted row stays in its bucket and does not collapse or fade'` | Indelible: the row stays in position |
| `'muting decrements the honest line while the rendered row count is unchanged'` | 07 §11.1's confusion trap |
| `'unmuting lifts the strike and the row re-enters the next projection'` | reversibility |
| `'a double tap on MUTE leaves muted = 1, not toggled back'` | `guard()` |
| `'reconcile runs once after a mute, and after the transaction'` | call site #3 |
| `'the strike renders in greyscale and the row still reads as muted'` | decision #106 |
| `'the strike is 0 ms under reduce-motion'` | `--motion-strike`'s reduce-motion row |
| `'the muted row survives textScaler 2.0 with the strike on the text'` | the layout trap; T06 repeats it across the matrix |

`test/features/reminders_dst_test.dart` — `@Tags(['uk-zone'])`

| Case | What it holds |
|---|---|
| `'a reminder muted at 01:30 on 25 October 2026 stamps 01:30, once'` | the repeated hour; one stamp, one instant, and the stamp does not change on re-render |
| `'a reminder overdue across the 29 March 2026 transition is muted into the same bucket it was in'` | the 23-hour civil day does not move a muted row between buckets |

### 5.5 Verification

```bash
fvm flutter test test/data/reminder_repository_test.dart
fvm flutter test test/features/reminders_test.dart
TZ=Europe/London fvm flutter test test/features/reminders_dst_test.dart
rg -n 'Dismissible|Draggable|onHorizontalDrag|onLongPress' lib/features/reminders/  # expect: no matches
rg -n 'delete\(|deleteWhere' lib/data/reminder_repository.dart                      # expect: only undoComplete's care_events delete
rg -n '0x[0-9A-Fa-f]{6,8}' lib/features/reminders/                                  # expect: no matches
make check
make test
```

## 6. Constraints that bind this task

- **Indelible Rule 1 — nothing is ever removed, only struck.** If a proposal makes information disappear
  from the page, it is wrong.
- **3am** — every interactive element ≥ `context.tokens.tapMin` (60) on both axes with ≥ `gapMin` (16)
  separation, the 18 pt text floor (the 14 px stamp is the documented exception), dark only, and none of
  the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. The word for what mute does is **strike**, never *dismiss*, *hide*, *snooze* or *archive*. **Snooze is not in v1** (07 §11.4) and adding it introduces a second time model.

## 7. Definition of Done

- [ ] `'a muted reminder is struck, still visible, and never projected again'` passes, and was seen to fail first for the stated reason
- [ ] nothing is deleted
- [ ] a muted row never reaches `project()`
- [ ] the strike is visible and reversible
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/features/reminders_test.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(reminders): mute as a visible strike`

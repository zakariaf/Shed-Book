# N23-T02 — The restore confirmation that names what it will destroy

| | |
|---|---|
| **Epic** | [N23 — Restore, the sweeps and the seed](epic.md) · `00-README` §9 step 8 (3 of 3) |
| **Task** | 2 of 7 |
| **Depends on** | N23-T01 |
| **Commit** | one commit · `feat(restore): a confirmation that names what it will destroy` |

## 1. Why this task exists

Two steps, and the first one **states plainly what will be destroyed** — this many ewes,
this many lambings, this many treatments, counted from the live database, not described in the
abstract. A shepherd about to lose three seasons deserves the numbers.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/04-migrations-media-backup-restore.md` | **§7.3** (the confirmation — the five statements in order, the two sizes, why there is no typed word) · §7.2 steps 0 and 4 (entered only from Settings; `WriteController.guard()`) · **§7.6** (the media sentence, and the completion screen's exact paragraph) · §7.4 (what each refusal says) · §10 (`d MMM y`, and the widget test that greps for `/`) | every sentence on this screen, and its order |
| `docs/engineering/07-screens.md` | **§14.3 row 11** (Settings ▸ Data: Restore from backup · Delete a season · Delete everything) · **§14.4** (restore is **4 taps**; restore and delete are the only two `showDialog` flows; the season delete is called *"the only `canPop: false` flow in the app"* — **the sentence this task amends**) · §14.5 (§12 on Settings) · §15.1 (restore has **no undo**) · §1.7 (headings) | where the flow lives and what it costs |
| `docs/design/indelible.md` | **§7.13** (the word button; **Destructive** is a struck label and an underline in `--madder-ink`, *"never a filled red button — a filled red button is a thing you press by accident"*) · **§7.14** (the bottom sheet is *"the only overlay in the app"* — the other side of the dialog conflict) · §8 Settings (the two destructive actions, their typed confirmation, and the double rule above them) · §9 (the 3am compliance table) | how it is drawn, and the conflict this task rules |
| `docs/engineering/06-design-system.md` | §6.1 (`tapMin` **60**, `tapPrimary` **72**, `tapHero` 88, `gapMin` 16, **`gapDestructive` 32**) · §6.2 (`ShedTapTarget` is the only sanctioned way to make something tappable) · §7 (the gesture ban) · §12 (`ShedDestructiveButton`: *"never within `gapDestructive` of a frequent action; two-step"*) | the geometry, from tokens and never from literals |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.8 (live regions and the Android re-announce rule) · §8.4 (the ARB conventions — every message `description`-bearing) · §9 (en_GB formats: `d MMM y`, 24 h) · §6.2 (why `showDatePicker`/`showTimePicker` are banned) | what the screen *says* rather than shows |
| `docs/engineering/CONVENTIONS.md` | §2.11 (`ShedTapTarget`; the three feedback functions) · §2.13 (`ExportRepository` — read and assembly only) · §3.4 (`settingsWriteControllerProvider`; there is **no** restore controller) · §4.5 + **R59** (`<screen>.<element>[.<qualifier>]`, `lower_snake`) · **R60** (no human-facing date is all-numeric) · §1.1 layer rules 5 and 6 | **BINDING** on the keys, the provider and the file paths |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · #73 (a typed **or** two-step confirmation — either is permitted) · #22 (`WriteController.guard()` and the double-tap test) · #100, #101 (60 pt floor, the gesture ban) · #103 (commit-then-confirm) · #104 (`headingLevel`) · #106 (colour is never the only channel) · #108 (never an all-numeric date in front of a human) · #85 (records-only, which is what the media sentence is about) | the decisions this screen applies |
| `CLAUDE.md` | **P2** — there is no SnackBar · the 3am floor · the banned copy (*"a lost phone is lost data"* unqualified, *"verified"*/*"secure"*, *"should"*) | the two things this screen is most likely to get wrong |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-states-and-feedback` | the confirmation, its two steps and its wording |
| `shed-accessibility-and-copy` | the wording is the safety mechanism here |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/restore_test.dart`
- **Test** — `'the confirmation names the live counts and requires two steps'`
- **Why it is red today** — restore is one tap away from destroying everything.

```bash
fvm flutter test test/features/restore_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it cannot pass on a hard-coded string:

1. Seed the live database to **known, awkward numbers** — 1 season, 38 ewes, 41 lambs, 6 treatments —
   and hand the screen a `BackupHeader` whose `counts` are different (3 / 412 / 861 / 145).
2. Assert **both** sets render, and that the live set matches a `COUNT(*)` taken in the test, not the
   header's numbers. Swapping the two sources is the bug this case exists to catch.
3. Assert the step-two control is **disabled** before step one is taken and enabled after.
4. Assert that tapping step two calls the service **once** after `tester.tap(); tester.tap();`.

**Green.** The minimum code that passes, and nothing beyond it — the two-step flow with counts read from the live database.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The ruling this task must make first

`indelible.md` §7.14 says the bottom sheet is *"the only overlay in the app"*. `07-screens.md` §14.4
says restore and delete are *"the only two flows in the app permitted to use `showDialog`"*, and
`CODE-REVIEW-CHECKLIST.md` carries the `ui.show_dialog` rule with a two-file exception already written
into it. Both documents are authoritative and one of them is wrong.

**Rule it in writing, in this commit, and amend the losing document in the same commit**
(`00-README` §10's amendment rule). The recommendation, with its reason: keep `showDialog` for these
two flows and amend `indelible.md` §7.14 to say *"the only overlay in the normal flow of the app; the
two destructive confirmations in Settings are modal by design, because a sheet can be dismissed by
tapping outside it and a destruction confirmation must not be"*. If the ruling goes the other way, the
screen becomes a pushed route and `07 §14.4`'s sentence is the one that changes — either way, one
document is edited here and neither is left contradicting the code.

The **second** amendment is not optional. `07 §14.4` says the season delete is *"the only `canPop: false`
flow in the app"*. Restore is the second: once step 12's rename has begun there is nothing to pop back
to. Edit that sentence in this commit.

### 5.2 The files, in `00-README` §8 order

**No schema step, no domain step.** Nothing is stored and nothing is computed. Say so in the commit
message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/export_repository.dart` | **Edit.** A live-side per-table count read. `ExportRepository` already builds `BackupHeader.counts` for N22-T02 — **reuse that query**; a second count implementation is a second answer to *"how many ewes are on this phone?"*. It stays read-only (R19: `ExportRepository` owns writes to nothing) |
| 2 | `lib/features/settings/settings_write_controller.dart` | **Edit.** The restore verb on the existing `settingsWriteControllerProvider`. `CONVENTIONS` §3.4 declares no restore controller and this task does not invent one. Every call goes through `WriteController.guard()`, which refuses to run concurrently (#22) — the cold-fingered double-tap defence |
| 3 | `lib/features/settings/widgets/restore_confirmation.dart` | **New.** The two-step confirmation, and the one `showDialog(` call site this feature is allowed. **Check the path the `ui.show_dialog` rule already names** (`grep -n "ui.show_dialog" tool/check_policy.dart`) and move the *file* to match the rule if they disagree — never the rule to match the file |
| 4 | `lib/features/settings/settings_screen.dart` | **Edit.** The Settings ▸ Data row that opens it. §14.3 row 11, §14.4's 4-tap budget |
| 5 | `lib/l10n/app_en.arb` | **Edit.** Every string below, each with a `description` carrying *why it is worded that way*. There is no later sweep; N33 only verifies |
| 6 | `docs/engineering/07-screens.md` | **Edit.** §14.4's *"the only `canPop: false` flow"*, and §7.14 of `indelible.md` or §14.4's `showDialog` sentence, depending on §5.1's ruling |
| 7 | `test/features/restore_test.dart` | **Edit.** The widget cases append to T01's file |

### 5.3 The five statements, in `04 §7.3`'s order

They are ordered, and the order is the argument: what you are about to gain, what you are about to
lose, what that means, what it does not include, and only then the controls.

```
1  What is in the backup      "3 seasons, 412 ewes, 861 lambs, 145 treatments.
                               Made on 14 Jul 2026 by Shed Book 1.1.0."
2  What is on this phone now  "1 season, 38 ewes, 41 lambs, 6 treatments."
3  The destruction sentence   "Restoring will delete everything now on this phone and
                               replace it with the backup. This cannot be undone from
                               inside the app."
4  The media sentence         "Photos and voice notes are not part of a backup. 452 were
                               recorded on the other phone and will show as
                               'not on this phone'."
5  The two controls           step one: 60 pt  "I understand — continue"
                              step two: 72 pt  "Replace everything" — disabled until step
                                               one is taken, on the OPPOSITE side of the
                                               screen from Cancel
```

Widget keys, `R59` spelling, read by the tests and by N33's four sweeps — spell them once, correctly:

```
settings.restore.backup_summary      settings.restore.live_summary
settings.restore.destruction          settings.restore.media_notice
settings.restore.step_one             settings.restore.replace_everything
settings.restore.cancel
```

The completion screen's paragraph is `04 §7.6`'s, verbatim, and it is one of the two places in the
product where the app admits a limitation in full sentences:

> **Your records are back.** 452 photos and voice notes were recorded on the other phone. Photos are
> not part of a backup in this version — they stay on the phone that took them. Each one still shows
> in the record it belongs to, marked "not on this phone".

### 5.4 The details that are easy to get wrong

- **The live counts are counted, not read.** Statement 2 comes from `COUNT(*)` against the live
  database. Statement 1 comes from the file's `BackupHeader.counts`. Wiring both to the header is the
  single most likely bug on this screen and it renders as a confident, symmetrical, wrong pair of
  numbers.
- **`d MMM y`, never `14/07/2026`** (#108, R60). This screen is read once, at 4am, by someone about to
  destroy their records — an ambiguous `07/13` versus `13/07` here is a §12.5-class failure. The
  widget test greps the **rendered text** for `/` and expects none.
- **No typed word.** Decision #73 permits either a typed confirmation or a two-step one; `04 §7.3`
  chooses two steps and says why: *"a word to type is a keyboard, and this is the app that exists
  because keyboards are hard with wet hands."* The season delete in Settings **does** use a typed
  confirmation (`indelible.md` §8, `07 §14.4`), so the wrong pattern is one screen away and will be
  copied. Restore is two taps in **different places**.
- **The second control is on the opposite side of the screen from Cancel**, and at least
  `gapDestructive` (**32**) from its nearest neighbour. `06 §12`: *"never within `gapDestructive` of a
  frequent action; two-step."* Read the number from `context.tokens`; a literal `32` is a
  build-breaking defect.
- **Never a filled red button.** `indelible.md` §7.13: the destructive state is a label and underline
  in `--madder-ink`, because *"a filled red button is a thing you press by accident"*. Colour is never
  the only channel (#106) — the word `Replace everything` carries the meaning; the ink reinforces it.
- **There is no SnackBar** (P2). Not for the confirmation, not for the outcome, not for the refusal.
  `showSnackBar(` is banned everywhere including `feedback.dart`. The outcome of a restore is a whole
  screen, because it is the one write in the app with no row to point at.
- **There is no undo** (`07 §15.1`, last row). Do not offer one, do not imply one, and do not use the
  word. `SaveReceipt.undoLabel` has no place on this screen.
- **`canPop: false` while the flow is in progress**, from step 10 onward, and use
  `onPopInvokedWithResult` — `onPopInvoked` is deprecated and `--fatal-infos` turns it into a CI
  failure. Before step 10, Cancel is real and costs nothing.
- **`WriteController.guard()` is the double-tap defence, not a debounce.** `if (state is WriteRunning)
  return;` — a second tap during the flow does nothing at all. The test is literally
  `tester.tap(); tester.tap();` (#22), and the assertion is that the service was called **once**.
- **Every banned gesture, on the one screen where a designer would reach for one.** No `Dismissible`
  to cancel, no drag-to-confirm, no long-press-to-hold, no slider. All are `check_policy` rows.
- **The `ui.show_dialog` exception is by path.** Confirm the path the rule already names before you
  create the file. Editing `tool/check_policy.dart` to accommodate a file you just placed is exactly
  what `CLAUDE.md` forbids: *"Never edit `tool/check_policy.dart`, its rule table or its exit code to
  make a build pass."*
- **A refusal is a sentence a shepherd can act on, and it is refused *before* this screen.** The header
  checks (steps 2–3) are N22's and they abort before the confirmation is ever shown — `04 §7.4`. This
  screen never renders for a file that is going to be rejected, which is why it can afford to be blunt.
- **No monetization, no entitlement read.** Export and restore are never gated (#86, #88). Nothing on
  this screen watches `entitlementProvider` or `purchaseServiceProvider`.
- **`headingLevel:`, never `header: true`** (#104; `a11y.header_bool` is a no-op since 3.44). The
  destruction sentence is a live region only if it changes; it does not, so it is not.
- **Layer rule 6.** `lib/features/settings/` may not import `lib/features/export/`, so
  `exportCountsProvider` is out of reach. That is why the count read is on `ExportRepository` and not
  on the export feature's controller.

### 5.5 The full test set

Appended to `test/features/restore_test.dart`.

| Case | What it asserts |
|---|---|
| `'the confirmation names the live counts and requires two steps'` | **The anchor.** Both count sets render; the live set equals a `COUNT(*)` taken in the test; step two is disabled until step one is taken |
| `'the live counts come from the database and not from the backup header'` | Seed live and header to *different* numbers and assert neither appears twice |
| `'the destruction sentence is present and unhedged'` | `04 §7.3`'s statement 3, exactly, from the ARB — no "may", no "might", no "should" |
| `'the media sentence names the count that will show as not on this phone'` | Statement 4, with the header's `media.count` |
| `'no rendered date contains a slash'` | Walk every `Text` in the tree; `d MMM y` only (R60, `04 §10`) |
| `'both controls are at least 60 x 60 and separated by gapDestructive'` | `tester.getRect`, against `context.tokens`, not literals |
| `'the destructive control is not a filled button'` | Its background is the page surface; the ink is `--madder-ink` on the label and underline |
| `'a double tap on Replace everything starts one restore'` | `tester.tap(); tester.tap();` → the service is called once (#22) |
| `'the flow cannot be popped once the swap has begun'` | `canPop: false` from step 10; a system back does nothing |
| `'Cancel before the destructive step leaves the live database untouched'` | Row counts unchanged; no sentinel; no `restore_staging/` |
| `'the completion screen states the media consequence in full'` | `04 §7.6`'s paragraph, from the ARB |
| `'no SnackBar is shown at any point in the flow'` | `find.byType(SnackBar)` is `findsNothing` through every state (P2) |
| `'nothing on the screen watches the entitlement'` | `FakePurchaseService.calls` is empty; no upgrade widget renders at `unlocked: false` |
| `'every string on this screen is an ARB message with a description'` | Source-text case over `app_en.arb`; no literal user-facing string in the widget file |
| `'every interactive element has a semanticLabel and a settings.restore. key'` | Semantics walk, R59 spelling |
| `'the confirmation renders without overflow at the smallest device and textScaler 2.0'` | `Device.small` × 2.0 × bold. This screen has more prose than any other in the app and it is the one most likely to overflow |
| `'the confirmation renders its dates correctly inside the ambiguous hour'` · **`@Tags(['uk-zone'])`** | `TZ=Europe/London`, `atFixed` at **01:30 on 25 October 2026**, with a backup whose `exportedAtUtc` falls in the repeated hour. `d MMM y` is stable across both candidate instants and the date does not slide to the 24th |

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Banned copy, on this screen specifically:** *"a lost phone is lost data"* unqualified, *"verified"*
  or *"secure"* about the checksum, *"your data never leaves your phone"*, and **"should"** anywhere.
  `ContentPolicy` scans ARB messages, so a soft word here is a red build, not a review note.
- **This is the one screen in the app permitted to look frightening.** `04 §7.3`: *"the restore screen
  is the one place in the app that may look scary. Everywhere else, calm."* That is a licence for
  plain sentences, not for red fills, alarm icons or a countdown.

## 7. Definition of Done

- [ ] `'the confirmation names the live counts and requires two steps'` passes, and was seen to fail first for the stated reason
- [ ] the counts are read, not estimated
- [ ] two steps, with the destructive one separated by `gapDestructive`
- [ ] the flow is `canPop: false` while it is in progress
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the live counts come from `COUNT(*)` on the live database, never from the backup header
- [ ] no rendered date contains a `/`
- [ ] there is no typed-word confirmation, and no undo is offered or implied
- [ ] no `SnackBar` appears at any point in the flow (P2)
- [ ] the `showDialog(` call sits at the path `tool/check_policy.dart` already names, and the rule was not edited
- [ ] the overlay conflict (`indelible.md` §7.14 vs `07 §14.4`) is ruled in writing and the losing document is amended in this commit
- [ ] `07 §14.4`'s *"the only `canPop: false` flow in the app"* is corrected in this commit
- [ ] every string is an ARB message with a `description`; no user-facing literal in the widget file

## 8. Verification

```bash
fvm flutter test test/features/restore_test.dart
make check
make test
```

```bash
TZ=Europe/London fvm flutter test --tags uk-zone
fvm flutter test test/design/                    # tap targets, semantics, contrast
fvm flutter test test/features/overflow_matrix_test.dart
```

```bash
grep -n  "ui.show_dialog" tool/check_policy.dart              # the path must match the new file
grep -rn "showDialog(" lib/features/ | wc -l                  # expect exactly two
grep -rn "showSnackBar(" lib/                                 # expect zero (P2)
grep -rn "onPopInvoked:" lib/                                 # expect zero — deprecated
grep -rn "Dismissible\|Draggable\|Slider\|onLongPress" lib/features/settings/   # expect zero
grep -n  "canPop" docs/engineering/07-screens.md              # the amended sentence
grep -rn "should" lib/l10n/app_en.arb                         # expect zero
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(restore): a confirmation that names what it will destroy`

# N18-T04 — The `fosterToSelf` warning and the four rules this screen may not break

| | |
|---|---|
| **Epic** | [N18 — Foster](epic.md) · `00-README` §9 step 6 (4 of 5) |
| **Task** | 4 of 5 |
| **Depends on** | N18-T03 |
| **Commit** | one commit · `feat(foster): the fosterToSelf warning and the four rules` |

## 1. Why this task exists

Fostering a lamb to its own birth dam is a warning, not a refusal — a shepherd may be
correcting an earlier mistaken foster and the app does not know better. Plus the four rules this screen
must not break, each asserted: no birth-dam mutation, no delete, no silent correction, no draft.

`checkFoster` has had **no call site** since N06-T03 wrote it. This is it, and it is the first time in
the project that a validator, a controller and a receipt meet on a shed screen — which is why the four
policy assertions land here rather than in N33.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §8 | Foster |
| `shed-book-spec.md` | §7.3 | birth dam and rearing dam as separate fields, reassignment in two taps or fewer |
| `docs/engineering/03-data-model-and-schema.md` | §5 | `foster_events`, the trigger and the `lamb_rearing` view |
| `docs/engineering/07-screens.md` | §8.4 (all five rules), §8.6 (§12 on this screen), §1.5 | *warn, never block*; the amber strip; and why §12.2 binds hardest here |
| `docs/engineering/05-domain-correctness.md` | §7.5 | `checkFoster`'s shape, the `fosterToSelf` row, and the four structural guarantees a validator has |
| `docs/engineering/CONVENTIONS.md` | §2.6, §2.13, R53 | `Warning` / `WarningCode` / `Reviewed<T>` — no `fix()`, no writer — and the import ban that makes it structural |
| `docs/engineering/00-README.md` | §2.3, §8 step 17, step 27 | the five safety rules as mechanisms; the **controller** runs validation; a §12 rule gets a `test/policy/` assertion named for the property |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.8 item 2, §8.5, §8.7 | warnings are spoken, not only badged; the terminology placeholder; and the closed list of strings that are not ARB messages |
| `shed-book-spec.md` | §12.2, §12.4 | never originate a clinical number; never silently correct an entry |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-safety-rules` | the four rules are its subject and this is the screen most likely to break them |
| `indelible-marks-and-strikes` | the warning's mark and its wording |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/foster_test.dart`
- **Test** — `'fostering to the birth dam warns, commits, and changes nothing else'`
- **Assertion, spelled out** — seed a lamb with **no** foster events, so her current rearing dam is her
  birth dam by arm 1 of `lamb_rearing`; tap that dam's target; then assert all four in one test,
  because the point is that they hold together: the warning strip renders and names
  `WarningCode.fosterToSelf`; the write still committed (one `foster_events` row, `outcome`
  `'to_ewe'`, `rearing_dam` = the birth dam); `readLamb(db, lamb).birthDam` is unchanged; and no other
  row in any table moved — assert on `updatedAt` of the lamb and the lambing, not on a screenshot.
- **Why it is red today** — nothing detects the self-foster case.

```bash
fvm flutter test test/features/foster_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the warning from N06-T03's validator, the commit, and four policy assertions.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 steps 5, 6, 7 — controller, UI, ARB, tests. No schema (there is no `warnings` column
and there never will be), no domain (`checkFoster` and `WarningCode.fosterToSelf` are N06-T02/T03's),
no data (a repository that could produce a warning could persist one — R53).

### 5.1 The files, in order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/features/lambing/foster_controller.dart` | Edit: run `checkFoster` against the **freshly watched** row and expose `List<Warning>` as screen state. §8 step 17: the controller runs validation, never the repository |
| 2 | `lib/features/lambing/foster_write_controller.dart` | Edit: pass the warnings to `confirmSaved` alongside the receipt. The list never gates the call to `recordFoster` — it is computed for the *target the shepherd is about to tap* and again for what was written |
| 3 | `lib/features/lambing/widgets/` | **Reuse** the warning strip N16-T06 built for Lambing Entry. It is in this feature folder, so no layer rule is involved, and a second warning surface would be two vocabularies for one concept |
| 4 | `lib/l10n/app_en.arb` | `warningFosterToSelf` with a `{term}` placeholder and a `description` naming §12.4. See gotcha 9 — this is the one place the doc set has not settled, and the commit says which way it went |
| 5 | `test/features/foster_test.dart` | **Extend.** The anchor plus §5.4's screen cases |
| 6 | `test/policy/foster_only_ever_appends_test.dart` | **New.** The four rules, one case each, named for the property it holds (§8 step 27) |

### 5.2 The signatures

```dart
// lib/features/lambing/foster_controller.dart — the call site checkFoster has been waiting for.
List<Warning> warningsFor(FosterOutcome candidate) => checkFoster(
      lamb: lambId,
      currentRearingDam: _rearing.rearingDam,   // from the lamb_rearing view, NOT lambs.birth_dam
      outcome: candidate,
    );

// lib/features/lambing/foster_write_controller.dart
await guard(() async { … return repo.recordFoster(lamb, outcome); });
// The warnings travel with the committed row, never instead of it (R53, CONVENTIONS §2.4):
confirmSaved(context, receipt, warnings);
```

The four rules, each with the mechanism that holds it and the level it sits at — a rule that has
dropped to merely *documented* has been deleted, whatever the prose says:

| Rule | Mechanism on this screen | Level |
|---|---|---|
| **No birth-dam mutation** | No parameter of `recordFoster` can name a birth dam; `lambs.birth_dam` has a `BEFORE UPDATE` trigger; the birth-dam cell has no tap target in its subtree | unrepresentable + unpersistable |
| **No delete** | `FosterEvents` is append-only; the correction is a compensating event; `corrects` is `ON DELETE RESTRICT` | unpersistable |
| **No silent correction** | `Warning` holds no writer and has no `fix()`; there is no `warnings` column; `lib/data/` cannot import `lib/domain/validation/` | unrepresentable + unpersistable |
| **No draft** | The tile commits; there is no Save button, no `isDirty`, no `commit()`, and the receipt is the committed row (P2) | unconstructible |

### 5.3 The details that are easy to get wrong

1. **`fosterToSelf` compares against the current rearing dam, never the birth dam** (05 §7.5,
   N06-T03). The anchor's scenario is the un-fostered lamb, where the two are the *same ewe* by arm 1
   of the view — which is the common case at 3am and why the test reads the way it does. Implement the
   comparison against `lamb_rearing.rearing_dam` and the anchor passes for the right reason.
2. **The inverse case is the one that catches people: after a foster to B, fostering the lamb *back to
   her birth dam* must NOT warn.** Her current rearing dam is B, so the target is a different ewe and
   nothing about it is a self-foster. A `birthDam == target` implementation passes the anchor and
   fails here — it is in the test set for that reason.
3. **`rearing_dam IS NULL` is a third state, not a match.** `ToBottle()` on a lamb already on a bottle
   does not warn: null-by-intent is not "already on this ewe", and there is no ewe to be on.
4. **The warning never blocks, and the order proves it.** The write goes first or the warning is
   computed for the candidate; either way the assertion is that a `WriteCommitted` came back **and**
   the warning rendered. A `if (warnings.isNotEmpty) return;` anywhere near this path is the defect
   this whole task exists to prevent.
5. **Warnings are recomputed on read and never stored** (05 §7.5 guarantee 2). There is no `warnings`
   column, no `warned_at`, and no boolean on the event saying the shepherd was told.
6. **Fostering onto a ewe who has not lambed is legitimate and is never blocked** (07 §8.4 rule 3,
   spec §7.1). It is not even a warning — she may have lost her own lambs, and making the shepherd go
   and record her lambing first is the exact failure §7.1 names.
7. **There is no teat-count warning, and adding one is a §12.2 violation** (07 §8.4 rule 4). *"The app
   has no business counting a ewe's teats."* Nor is there "she has capacity", "she has milk", or any
   ordering of targets by anything except longest penned and most recently touched.
   `ContentPolicy.bannedInUserFacingText` scans the ARB, so a helpful sentence added here fails the
   gate rather than shipping.
8. **The receipt speaks the warning and changes the haptic** (10 §3.8 item 2). When `warnings` is
   non-empty the receipt label appends the first warning's message and the haptic is
   `warningNotification()`, not `successNotification()`. Both values stay recorded verbatim: the
   announcement flags, it never fixes.
9. **The warning's wording is the one thing the doc set has not settled, and this commit settles it.**
   05 §7.5 gives `fosterToSelf` the message *"That lamb is already on this ewe."* as a domain literal;
   10 §8.5 forbids a domain noun inside a user-facing message; and 10 §8.7's closed list of non-ARB
   strings does **not** include `Warning.message` — *"adding a seventh exception is a review
   conversation, not an edit."* The resolution that costs least and breaks nothing: the **screen**
   renders an ARB message keyed by the `WarningCode` (`warningFosterToSelf`, with `{term}` from
   `terminologyProvider`), and `Warning.message` stays exactly as 05 spells it for the domain tests
   and the export. That is the same split the vocabulary already uses — keys in the database, labels
   in the ARB. Take it, or take the owner's; do not ship a hard-coded *ewe* to a shepherd who renamed
   her a gimmer.
10. **The strip is a mark, not a Material banner.** `indelible.md` §6.2 mark 3: the query mark `?` at
    28 px in the margin, *"the record contradicts itself and I am not going to fix it for you"*, plus
    the word — colour never alone (rule 3). 07 §8.6 calls it a 60 pt amber strip; the geometry floor is
    07's and the vocabulary is Indelible's, and N16-T06 already built the widget that satisfies both.
11. **`Warning` has no `fix()` and `Reviewed<T>` has no `cleaned`** (CONVENTIONS §2.6). If a code path
    here wants to "apply" a warning, the type will not let it, and that is the mechanism — not the
    reviewer's memory.
12. **The four policy assertions are named for the property, not the file** (CONVENTIONS §4.1). They
    belong in `test/policy/` because they are claims about the product, not about a widget: they must
    keep passing when this screen is rewritten.

### 5.4 The full test set

| File | Cases |
|---|---|
| `test/features/foster_test.dart` | **anchor:** `'fostering to the birth dam warns, commits, and changes nothing else'` · `'fostering back to the birth dam after a foster to another ewe raises no warning'` — the inverse case gotcha 2 names · `'fostering to a ewe who has not lambed raises no warning and is never blocked'` · `'ToBottle on a lamb already reared on a bottle raises no warning'` · `'the warning strip renders the ARB message with the user term, not a hard-coded ewe'` — set the terminology overlay to *gimmer* and read the strip · `'the receipt label appends the warning message and the haptic is warningNotification'` |
| `test/policy/foster_only_ever_appends_test.dart` | `'no code path can change a lamb birth dam'` — the trigger plus the absence of any `birth_dam` parameter · `'no code path deletes a foster event'` — after a foster and a correction, both rows are present and a delete is refused by the FK · `'a foster warning never changes what was written'` — the committed row is byte-identical with and without the warning · `'the foster screen has no draft: the row exists before the route pops'` — pop immediately after the tap and read the row back |

Every case in the first file runs through `pumpApp`; every case in the second runs against
`testDatabase()` and asserts the property, not the pixels.

## 6. Constraints that bind this task

- **§12.4 held at *caught by a test*, and §12.2 held at *the app declines to know better*.** Fostering a lamb to its own birth dam is a warning and never a refusal: the shepherd may be correcting an earlier mistaken foster, and blocking it would be a husbandry judgement. The four assertions are the mechanism — no birth-dam mutation, no delete, no silent correction, no draft — and they land here rather than in N33 because this is the first screen where a validator, a controller and a receipt meet.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **§12.2 binds hardest here** (07 §8.6): *"no screen in the app is more tempting to make helpful."*

## 7. Definition of Done

- [ ] `'fostering to the birth dam warns, commits, and changes nothing else'` passes, and was seen to fail first for the stated reason
- [ ] the warning never blocks the write
- [ ] all four rules have an assertion naming the property they hold
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `checkFoster` is called from the controller and from nowhere in `lib/data/`
- [ ] the warning's rendered wording carries the user's term, and the ARB decision in §5.3 gotcha 9 is recorded in the commit message

## 8. Verification

```bash
fvm flutter test test/features/foster_test.dart
fvm flutter test test/policy/
grep -rn "checkFoster" lib/
grep -rn "warnings.isNotEmpty" lib/features/lambing/
make check
make test
```

The first grep must show exactly one call site, in `lib/features/lambing/foster_controller.dart`. The
second is the one to read with your own eyes: every hit must be a *render* decision, never a *write*
decision.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(foster): the fosterToSelf warning and the four rules`

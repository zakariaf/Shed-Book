# N09-T09 — `motion.dart`, the haptic vocabulary, and the P10 ruling

| | |
|---|---|
| **Epic** | [N09 — The design system foundation](epic.md) · `00-README` §9 step 4 (1 of 3) |
| **Task** | 9 of 9 |
| **Depends on** | N09-T08 |
| **Commit** | one commit · `feat(ui): motion, the haptic vocabulary, and the P10 ruling` |

## 1. Why this task exists

The motion tokens, the reduce-motion resolver and the haptic vocabulary. **This task
rules P10**: `06`'s definition of done names four haptics and Indelible §5.4 names five, and
`HapticFeedback.successNotification()` is unverified against the shipped Flutter version. Verify it,
rule the count, and amend the losing document in this commit.

T08 landed the resolver; this task lands the durations, the curves and the vocabulary on top of it.
Haptics matter more here than in most apps: *"under a wet nitrile glove, inside a freezer bag, in the
dark, with the phone at arm's length while you hold a lamb, haptics are the primary feedback channel
and the visual press state is the backup"* (`indelible.md` §5.4). They are also the channel an app
**cannot detect being switched off**, which is why they are never load-bearing.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/design/indelible.md` | §5.1 (**four durations and no fifth**, with their curves) · §5.2 (what must never animate) · §5.3 (the reduce-motion table, and why press survives) · §5.4 (**the five-event haptic vocabulary and its rhythms**) | one side of P10, and every duration |
| `docs/engineering/06-design-system.md` | §10.1 (**the four-member haptic vocabulary, keyed to write outcomes**) · §10.2 (no audio in v1, and why) · §10.3 (commit-then-confirm; the three redundant channels) · Definition of done (*"the haptic vocabulary has exactly four entries"*) | the other side of P10 |
| `docs/engineering/REFERENCES.md` | §22 **E1** (the five-minute SDK check that closes four documents at once) | how to verify `successNotification` rather than argue about it |
| `CLAUDE.md` | **P2 — there is no SnackBar; the confirmation is the committed row** | why the vocabulary lands here and its call sites do not |
| `docs/engineering/CONVENTIONS.md` | §1 (`motion.dart` holds `prefersReducedMotion`) · §2.11 (`confirmSaved` / `showFailure` / `showCapRow` live in `feedback.dart`, which is not this epic's) · §7 item 4 | the file, and the boundary |
| `docs/research/00-tech-decisions.md` | §5 (**Flutter 3.44.8** — the version the check is run against) · #103, #105 | the pinned SDK and the three-channel rule |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-design-system` | motion and haptics are its subject and §5.4 is one side of the conflict |
| `shed-platform-gateways` | whether a platform haptic call exists at the pinned version is a platform fact |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/haptics_test.dart`
- **Test** — `'the haptic vocabulary has exactly the ruled number of entries and names no unverified platform call'`
- **Why it is red today** — P10 is open, and one of the five haptics may not exist at Flutter 3.44.8.

```bash
fvm flutter test test/design/haptics_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it cannot drift from the ruling: the test reads the vocabulary's **length**
and compares it to the number written in the amended document, and it asserts that every member is
referenced **as a symbol**, never as a string — a symbol that does not exist on this SDK is a compile
error, which is the strongest available proof and costs nothing.

**Green.** The minimum code that passes, and nothing beyond it — check the API against the pinned SDK, rule the count, amend the losing document, and let
the test assert the vocabulary size against the ruling rather than a remembered number.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**UI, docs and tests.** No schema, no domain, no data, no wiring, no controller, no ARB string. Say so
in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/motion.dart` | Gains Indelible §5.1's **four durations and two curves** and the ruled **haptic vocabulary**. T08 landed `prefersReducedMotion` in this same file |
| 2 | `docs/design/indelible.md` **or** `docs/engineering/06-design-system.md` | The **P10 amendment**, on whichever document the ruling contradicts, in this commit |
| 3 | `docs/engineering/06-design-system.md` §10 / §11, `07-screens.md` §22 item 7, `10-accessibility-and-i18n.md` §11, `12-testing.md` Open item 7 | **The four stale flags E1 closes.** `06` asserts `successNotification` is real; the other three still carry it as unverified. Run the check and clear all four, or correct `06` — either way, in one commit |
| 4 | `test/design/haptics_test.dart` | **New.** The anchor and the cases in §5.4 |
| 5 | `test/design/reduce_motion_test.dart` | Extended: the four durations now exist, so the per-token reduction table is assertable rather than described |

**Not in this task:** `lib/core/ui/feedback.dart` and the three confirmation functions. `showFailure`
takes a `ShedFailure` from `lib/core/failure.dart`, which is **N11-T01**, and `06`'s own References
flag an unresolved layer question — `CONVENTIONS §1.1` gives `lib/core/ui/` only
`{lib/core/ui/, lib/domain/}`, which forbids the import the canonical signature requires, and the
R16-style amendment has not been made. This task lands the **vocabulary**; the call sites follow it.

### 5.2 The signatures

Indelible §5.1's motion tokens — **four durations and no fifth**:

| Token | Duration | Curve | What |
|---|---|---|---|
| `--motion-press` | **40 ms** | ease-out | a slab or key filling from `--slab` to `--slab-pressed`. Fill only; **no scale, no lift, no ripple** |
| `--motion-ink` | **120 ms** | ease-out | a newly printed glyph fading 0 → 1. **Opacity only. Zero translation.** |
| `--motion-sheet` | **160 ms** | ease-out | the bottom sheet rising. Translate-Y only, no fade, no backdrop blur, no scrim animation |
| `--motion-strike` | **180 ms** | **linear** | the strike line drawing left-to-right, `scaleX(0) → scaleX(1)`, origin left |

`--ease-out` is `cubic-bezier(0.2, 0, 0, 1)`; `--ease-strike` is `linear`, because *"the gesture being
represented is a pen drawn across a page at constant speed"* — it is the only animation in the app
with a direction, and the one place the animation **is** the meaning.

**`ShedTokens.motion` is a single `Duration` and Indelible has four.** `06 §3.3` gives the extension
one `motion` field and `06 §2.5` feeds it from the resolver. The four durations do not vary by
palette, so they belong in `motion.dart` as named constants rather than as three more per-palette
fields — but say so, name them under `CONVENTIONS §4` the way `10 §9.1` declared the `formatShed*`
names, and keep `ShedTokens.motion` as the theme-level duration the resolver zeroes. Do not leave the
mismatch implicit: `06 §1`'s rule is *add the token, never a literal in a widget*, and the same logic
applies to a duration typed into an `AnimatedOpacity`.

The haptic vocabulary, `06 §10.1`'s side:

| Event | Haptic | Fires when |
|---|---|---|
| Key press / selection change | `HapticFeedback.selectionClick()` | pointer **down**, before the state change |
| **Record committed to SQLite** | `HapticFeedback.successNotification()` | the transaction **returned** `WriteCommitted` |
| Warning raised (spec §12.4) | `HapticFeedback.warningNotification()` | the write committed **and** the controller's `List<Warning>` is non-empty |
| Write refused | `HapticFeedback.errorNotification()` | the transaction returned `WriteFailed` |

### 5.3 The details that are easy to get wrong

- **P10 compares two lists that are not the same kind of list, and that is the ruling's whole
  substance.** `06 §10.1`'s four are **API members keyed to write outcomes** — a vocabulary of what
  the *database* just did. `indelible.md` §5.4's five are **rhythms keyed to events** — one 10 ms tick
  for a tally stroke or a keypad digit; **two ticks 60 ms apart** when a tag lands or a row commits;
  **two ticks 120 ms apart** for a strike, *"deliberately slower, a different rhythm from a commit"*;
  one tick when a pen crosses the turn-out threshold with the app open; nothing else. Ruling "four" or
  "five" without saying *of what* settles nothing.
- **Flutter has no two-ticks-60 ms-apart primitive.** Sequencing two `selectionClick()` calls with a
  `Future.delayed` is a custom pattern, and `06 §10.1` is blunt about what it would be worth: *"on iOS
  three or four patterns are genuinely distinguishable through a glove; on Android assume **two**,
  because vendor LRA quality varies enormously and `CONFIRM`/`REJECT` only exist on API 30+."* A
  five-rhythm vocabulary that resolves to two perceivable patterns on half the target devices is a
  vocabulary in the document and not in the shed. Put that in the ruling.
- **Run `REFERENCES §22` E1 before you write the call, and record the result.** It is a five-minute
  grep of the **installed 3.44.8 SDK** and it closes four documents at once: `06 §10` asserts the
  member is real (checked against a local **3.44.6** checkout on 2026-07-27, with §5 recording the SDK
  pins as identical within 3.44), while `07 §22` item 7, `10 §11` and `12`'s Open item 7 all still
  carry it as unverified, and `CONVENTIONS §7` item 4 deliberately declines to rule because it is an
  SDK fact rather than a name. **If the member does not exist, the commit haptic degrades to
  `heavyImpact()` and the design intent is unchanged — the vocabulary is correct, only the spelling is
  in doubt.**
- **Reference every member as a symbol, never as a string.** `HapticFeedback.successNotification` in
  source is a compile-time existence proof; `'successNotification'` in a map key is a runtime hope. It
  is also why the anchor's phrase *"names no unverified platform call"* is satisfiable at all.
- **The success haptic fires when the transaction returns, never on the tap.** *"A false receipt is
  worse than no receipt."* The key-press tick is the opposite — it fires on pointer **down**, before
  the state change, so the finger feels the *key* rather than the result. Two haptics, two opposite
  timings, and swapping them is the mistake.
- **`HapticFeedback.vibrate()` is banned.** On Android it is a long buzz, not a tick.
- **Haptics are *not* disabled by reduce-motion** — they are not motion (`indelible.md` §5.4). They
  are individually disableable in Settings (N29), and **an app cannot detect that they are switched
  off system-wide**, which is why they are one of three redundant channels and never the only one
  (`06 §10.3`, decision #103).
- **Two events deliberately have no haptic, and the omissions are decisions.** The **free-tier cap
  never fires one**: both gated actions are calm-UI and *"a buzz would turn a calm gate into a
  rebuke"*, and `EntryContext.liveEntry` is structurally incapable of being blocked at all. And **a
  contradiction is never "fixed" by a haptic**: the warning pattern says *"this is recorded and it
  disagrees with something"*, not *"try again"* — both values are preserved verbatim, and the haptic is
  the same whether or not the shepherd looks.
- **P2 changes what the confirmation *is*, and the haptic table survives it unchanged.** There is no
  SnackBar; *"the confirmation is that the row is there, in ink, one line above the one being
  written"*, and undo is a time-boxed strike in the row's own margin **with its window stated in
  seconds, never in terms of a widget's lifetime**. So `06 §10.3`'s three channels become: the haptic,
  the printed row, and the visible state change in the underlying list. The haptic vocabulary is the
  part of §10.3 that P2 leaves alone — say so, because a reviewer who knows P2 will reasonably wonder.
- **Under reduce-motion the press flash stays at 40 ms** while ink, sheet and strike go to zero
  (§5.3). T08's test asserts it; this task makes the constants those assertions read.
- **What must never animate, and it is a longer list than it looks.** **Numbers** — no count-ups, no
  odometers, no ticking, ever, because *"a number that is mid-animation is a number you can misread,
  and this app is a record of numbers."* **The chart** — full length in the first painted frame.
  **Rows** — they never reorder, slide or crossfade; a filter change re-prints instantly, because *"a
  crossfade at 3am reads as a lag, and a lag reads as 'it didn't save'."* **Launch** — the first
  painted frame is the page with tonight's page already on it. **Scroll** — no parallax, no sticky
  header collapse. **The spine** — drawn once, never moved; its stillness is doing work. These bind
  N10 and every screen epic; the constants land here so there is nothing to type inline later.
- **There is no sound anywhere in v1** (`06 §10.2`). `SystemSound.play` exists on both platforms and
  is inaudible over a shed fan; anything better needs an audio plugin with platform code, its own
  audio session and a silent-switch policy — a new dependency that must clear the offline allowlist,
  for a benefit nobody can demonstrate. Spec §5 also says *"zero interruptions"*, and sound is the most
  interrupting channel.
- **The amendment rule is not optional here.** If the ruling changes a decision row, strike it **with
  its reason** in `docs/research/00-tech-decisions.md` and change every document that names it in the
  same commit. `00-README` §10: *"A doc set where document 07 applies decision #29 and document 03 no
  longer does is worse than no doc set, because both look authoritative."*

### 5.4 The full test set

`test/design/haptics_test.dart`, plus the extension to `reduce_motion_test.dart`.

| Case | What it asserts |
|---|---|
| `'the haptic vocabulary has exactly the ruled number of entries and names no unverified platform call'` | **The anchor.** The length matches the amended document, and every member is a symbol reference |
| `'every member the vocabulary names resolves on HapticFeedback at 3.44.8'` | Compilation is the proof; the case exists so the proof has a name in the report |
| `'HapticFeedback.vibrate appears nowhere under lib/'` | Source text. On Android it is a long buzz |
| `'the vocabulary is keyed on a write outcome, not on a tap'` | The success entry cannot be reached from a gesture callback — the type is what makes *"fires when the transaction returned"* structural rather than a comment |
| `'the free-tier cap has no vocabulary entry'` | Decision #90 and `06 §10.1`'s first deliberate omission |
| `'a warning and a refusal are different entries'` | A committed-with-warnings write is not a failure, and conflating them would tell a shepherd to try again after a record that already exists |
| `'no audio API is referenced under lib/'` | `SystemSound`, and no audio plugin in `pubspec.yaml` |
| `'the four durations are 40, 120, 160 and 180 milliseconds and there is no fifth'` | Indelible §5.1's budget, asserted so a fifth cannot appear without deleting one |
| `'the strike is the only linear curve'` | Every other token uses the shared ease-out. The strike is linear because a pen crosses a page at constant speed |
| `'under reduce-motion, ink, sheet and strike are zero and press is 40 ms'` | The per-token table, now that the constants exist. Extends T08's file |
| `'haptics are not gated on reduce-motion'` | They are not motion. The resolver and the vocabulary are independent |
| `'the P10 ruling is recorded and the amended document agrees with the vocabulary'` | Reads the count out of the amended section. If the ruling was deferred, this case names it as deferred rather than passing quietly |
| `'no stale unverified flag for successNotification remains in 07, 10 or 12'` | E1's other half — the check closes four documents, not one |

**Nothing here is time-shaped.** A `Duration` is a span, not a clock reading, and no wall time is
read — so there is no `uk-zone` case. T06 has the epic's only one.

## 6. Constraints that bind this task

- **3am** — haptics are the primary feedback channel through a wet glove inside a freezer bag, and the
  40 ms press flash is the backup. Neither may be removed by an accessibility setting that was not
  asking for it.
- **Accessibility and the ARB, authored here** — there is no user-facing string in this task; the
  Settings row that disables haptics individually is N29's, with its own ARB message and
  `description`. N33 only verifies.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. No audio plugin enters `pubspec.yaml` on this task's authority.
- **The amendment rule** — the ruling moves the decision record and every applying document in one
  commit, or it is not a ruling.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the haptic vocabulary has exactly the ruled number of entries and names no unverified platform call'` passes, and was seen to fail first for the stated reason
- [ ] the ruling is written and the losing document amended in this commit
- [ ] every haptic in the vocabulary exists at the pinned Flutter version
- [ ] haptics respect the reduce-motion and system haptic settings
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] **`REFERENCES §22` E1 has been run against the installed 3.44.8 SDK, and its result is recorded** — the three stale unverified flags in `07 §22`, `10 §11` and `12` are cleared, or `06 §10` is corrected
- [ ] the ruling states what the count is *of* — API members keyed to write outcomes, or event rhythms — because the two lists are not comparable as written
- [ ] every member is referenced as a symbol, never as a string
- [ ] the four durations and two curves are named constants; nothing types a `Duration` inline
- [ ] `HapticFeedback.vibrate` and every audio API appear nowhere under `lib/`
- [ ] the free-tier cap and a contradiction each have **no** haptic, and the omissions are documented
- [ ] if a decision row changed, it is struck **with its reason** and every document naming it changed in this commit

## 8. Verification

Run E1 first — it is the evidence the ruling rests on:

```bash
grep -rn "successNotification\|warningNotification\|errorNotification\|selectionClick" \
  .fvm/flutter_sdk/packages/flutter/lib/src/services/haptic_feedback.dart
# expect all four members; note the file's path and the SDK version in the commit message
fvm flutter --version    # must print 3.44.8
```

Then:

```bash
fvm flutter test test/design/haptics_test.dart
fvm flutter test test/design/reduce_motion_test.dart
fvm flutter test test/design/
make check
make test
```

```bash
grep -rn "HapticFeedback.vibrate\|SystemSound" lib/ --include='*.dart'          # expect zero
grep -rn "Duration(milliseconds: [0-9]" lib/ --include='*.dart'                 # expect zero outside motion.dart
grep -rn "unverified" docs/engineering/07-screens.md docs/engineering/10-accessibility-and-i18n.md docs/engineering/12-testing.md | grep -i haptic
# expect zero after E1 is run and the flags are cleared
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): motion, the haptic vocabulary, and the P10 ruling`

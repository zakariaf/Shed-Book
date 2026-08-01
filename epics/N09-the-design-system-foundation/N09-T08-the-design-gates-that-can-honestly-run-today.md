# N09-T08 — The design gates that can honestly run today

| | |
|---|---|
| **Epic** | [N09 — The design system foundation](epic.md) · `00-README` §9 step 4 (1 of 3) |
| **Task** | 8 of 9 |
| **Depends on** | N09-T07 |
| **Commit** | one commit · `test(design): the gates that can honestly run before any screen exists` |

## 1. Why this task exists

`wcag.dart`'s arithmetic, `contrast_test.dart` over the palettes, the single-widget
`tap_target_test.dart` and `reduce_motion_test.dart`. **Deliberately not here:** the semantics sweep and
the tap-target sweep, which iterate `kPumpableVariants` — a table that does not exist until N13 and is
not complete until N33. The old plan put them here and they could not have compiled. Critique defect
S7.

Three of the four files already exist when this task starts — T03 landed `wcag.dart` and
`contrast_test.dart`, T07 landed `tap_target_test.dart`. This task adds the fourth, adds the resolver
it tests, and **makes the set honest**: every file says in a comment which sweep it is *not*, and
where that sweep lands. A gate whose scope is undocumented is a gate that quietly grows or quietly
stops asserting, and both failures are invisible in a green build.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/12-testing.md` | §7.4 (**the split between `semantics_gate_test.dart` and `tap_target_test.dart`, and the 84-run table they share**) · §7.5 (the canary) · §7.6 (why the pixel-sampling contrast run is 42 runs, tagged `slow`) · §6.2 (`kPumpableVariants` — the fourteen-entry table, declared once in `test/support/harness.dart`) | which gate may run when, and where each assertion lives |
| `docs/engineering/10-accessibility-and-i18n.md` | §2.3 (**`prefersReducedMotion`, and the two-branch test**) · §2.2 (the platform flag truth table) · §11 (the anti-pattern list) | the resolver and the two branches it must have |
| `docs/engineering/06-design-system.md` | §2.5 (which flag the theme layer reads and how it feeds `ShedTokens.motion`) · §3.5 (`test/design/` is an addition to 01's test tree) · §6.3 (the two gates, printed in full) | the resolver's home and its consumer |
| `docs/design/indelible.md` | §5.1 (four durations and no fifth) · §5.3 (**under reduce-motion, ink/sheet/strike go to 0 ms and press stays at 40 ms**) | what "reduced" means, exactly, for each token |
| `epics/00-PLAN-CRITIQUE.md` | S7 | why the two sweeps are N33-T02 and N33-T03 |
| `docs/research/00-tech-decisions.md` | §5 · #105 (one resolver ORing both flags) · #115 (`ensureSemantics` before every `meetsGuideline`) | the decision this resolver implements |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-testing` | which gate can run when is exactly its judgement, and it owns the tier split |
| `indelible-design-system` | the gates encode its rules, and §5.3 fixes what each motion token reduces to |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/reduce_motion_test.dart`
- **Test** — `'every animation resolves to zero duration when reduce-motion is on'`
- **Why it is red today** — nothing checks that motion respects the platform flag.

```bash
fvm flutter test test/design/reduce_motion_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it cannot pass on one platform's flag alone: the test has **two branches**,
because each platform only ever exercises one of them. `'android flag alone reduces motion'` sets
`MediaQueryData.disableAnimations` and leaves the platform-dispatcher flag off;
`'ios flag alone reduces motion'` does the reverse. Both must return `true`. And "reduced" is
`Duration.zero` **exactly**, not `Duration(milliseconds: 40)` and not "shorter".

**Green.** The minimum code that passes, and nothing beyond it — the resolver, the gate, and a comment in each gate file naming N33 as the home of the
sweeps.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**UI and tests only.** No schema, no domain, no data, no wiring, no controller, no ARB string. Say so
in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/motion.dart` | **New.** `prefersReducedMotion(BuildContext)` — the one resolver, ORing the Android-only and iOS-only flags. T09 adds the motion **tokens** to this file on top of it |
| 2 | `test/design/reduce_motion_test.dart` | **New.** The anchor, both branches, and the anti-pattern canary |
| 3 | `test/design/wcag.dart` | Unchanged code; gains the comment recording that the **pixel-sampling** half of contrast is 42 runs at N33, in `contrast_test.dart`, tagged `slow` |
| 4 | `test/design/contrast_test.dart` | Gains the comment: this file holds `06 §3.5`'s palette arithmetic **and will hold** `12 §7.6`'s `textContrastGuideline` group at N33 — never a second file |
| 5 | `test/design/tap_target_test.dart` | Gains the comment: single-widget today; the 84-run **geometric** gate, the 16 pt gap check and the tap-action check arrive at **N33-T03**; the tree-walking guidelines and `headingLevel` go to **`semantics_gate_test.dart`** at **N33-T02** |
| 6 | `test/design/gate_inventory_test.dart` | **New, and small.** Asserts the four files exist, that none of them references `kPumpableVariants` yet, and that each carries its scope comment. This is the file that stops a fifth gate appearing silently |

`semantics_gate_test.dart` is **not** created here, not even empty. An empty gate file is worse than a
missing one: it looks like coverage.

### 5.2 The signatures

```dart
// lib/core/ui/motion.dart
/// The only correct cross-platform reduce-motion check on Flutter 3.44:
/// iOS never sets disableAnimations; Android never sets reduceMotion; and
/// MediaQueryData has no reduceMotion property at all. (Decision #105.)
///
/// Depending on MediaQuery.disableAnimationsOf is also what makes this rebuild:
/// _MediaQueryFromView implements didChangeAccessibilityFeatures, so any
/// accessibility-flag change — including the iOS-only one — invalidates
/// MediaQuery and this widget with it.
bool prefersReducedMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;
```

Its one consumer is `ShedTokens.motion`, reached through the narrow `copyWith` T02 authored:
`t.copyWith(motion: prefersReducedMotion(context) ? Duration.zero : t.motion)`. **The wiring is
N11/N12's**, in `themeProvider` and `ShedBookApp`; this task lands the resolver and the test, and
names the obligation in the PR body so it is not lost between epics.

`indelible.md` §5.3 fixes what each token reduces to, and the fourth row is the one that matters:

| Token | Normal | Reduced |
|---|---|---|
| `--motion-ink` | 120 ms | **0 ms** — the glyph is simply there |
| `--motion-sheet` | 160 ms | **0 ms** — the sheet is simply there |
| `--motion-strike` | 180 ms linear | **0 ms** — the line is drawn full-width instantly |
| `--motion-press` | 40 ms | **40 ms, unchanged** |

### 5.3 The details that are easy to get wrong

- **Reading one flag is the whole bug, and it is silent.** There is no cross-platform reduce-motion
  flag: **iOS never sets `disableAnimations`, Android never sets `reduceMotion`, and `MediaQueryData`
  has no `reduceMotion` property at all.** `10 §11` names the failure exactly — *"you test on an
  iPhone with Reduce Motion on, see no change, conclude the API is broken, and ship un-reduced motion
  to the platform where the setting exists."* There is no gate row for it. The two-branch test **is**
  the mechanism.
- **The press flash survives reduce-motion, deliberately, and a test must say so.**
  `indelible.md` §5.3: *"it is a fill change under a thumb, not motion, and it is the confirmation
  that a press through a glove and a freezer bag registered. Removing it would remove the only visual
  feedback available to a user who cannot feel the screen."* An over-eager implementation that zeroes
  every duration passes the anchor and breaks the 3am contract, which is why `'the press flash
  survives at 40 ms'` is a separate case rather than a footnote.
- **Reduced is zero, not shorter.** `Duration.zero`, exactly. `expect(d.inMilliseconds, lessThan(50))`
  is the assertion that lets a 40 ms "compromise" through on the ink token.
- **Faking the iOS branch needs the test platform dispatcher, and the spelling is worth checking
  against the SDK before you rely on it.** The Android branch is easy — wrap in a `MediaQuery` whose
  data has `disableAnimations: true`. The iOS branch is set through the test binding's platform
  dispatcher (`tester.platformDispatcher`), with a fake `AccessibilityFeatures` carrying
  `reduceMotion: true`, and **cleared in `addTearDown`** so it does not leak into the next test in a
  randomised-order run. Resolve both names in the local 3.44.8 checkout the way `06`'s References did
  for every symbol it prints; do not copy a spelling from a blog post.
- **`-P ci-fast` randomises test order**, so any global you set — a platform-dispatcher override, a
  `debugDefaultTargetPlatformOverride` — must be torn down in the same test that set it. A leaked
  accessibility flag makes an unrelated test fail on a different machine, once.
- **Haptics are *not* disabled by reduce-motion.** They are not motion (`indelible.md` §5.4). They are
  individually disableable in Settings, and that switch is N29's. Say it in the resolver's doc comment
  so T09's vocabulary does not get wired to the wrong flag.
- **`accessibleNavigation` is timing only — never branch the layout on it** (`06 §2.5`). It means
  VoiceOver **or** Switch Control on iOS and TalkBack on Android; the correct response is never
  auto-dismiss and never steal focus, not a different tree.
- **Do not create `semantics_gate_test.dart` as a placeholder.** It is N33-T02's, it needs
  `kPumpableVariants` from `test/support/harness.dart` (N12-T05) populated with real screens (N13
  onward), and an empty file in `test/design/` reads as coverage in every listing and every review.
  Critique defect S7 is this mistake, made once, in the plan this epic replaces.
- **Do not pre-empt `12 §7.4`'s split.** When the sweeps arrive: the **tree-walking** guidelines
  (`shedTapTargetGuideline`, `labeledTapTargetGuideline`) plus the `headingLevel` assertion go in
  `semantics_gate_test.dart` — 84 runs, milliseconds each. The **geometric** gate, the 16 pt gap
  check, the tap-action check and the canary stay in `tap_target_test.dart` — another 84 runs. The
  **pixel-sampling** `textContrastGuideline` goes in `contrast_test.dart` — 42 runs, tagged `slow`,
  because it renders and samples every node's pixels and *"running it 84 times on every push buys
  nothing over 42: contrast does not vary with device width, and it is the palette that varies."*
  Put that three-line map in the comment at the head of each file.
- **The pixel-sampling run is non-deterministic on photo-bearing screens** (Ewe Card, Lamb Card,
  Lambing Entry with an attachment) because a seeded photograph's pixels decide the answer. The
  harness seeds those with a **solid-colour placeholder**. That is N33's problem, but the comment you
  leave here is what stops someone at N33 debugging a flake for an afternoon.
- **`test/design/` is an addition to `01 §2.2`'s test tree** and R57 fixes the directory set as
  `test/{domain,data,drift,design,features,policy,support,fixtures}/` plus a top-level
  `integration_test/`. `test/screens/` and `test/integration/` are banned spellings.

### 5.4 The full test set

**`test/design/reduce_motion_test.dart`** — the new gate.

| Case | What it asserts |
|---|---|
| `'every animation resolves to zero duration when reduce-motion is on'` | **The anchor.** Ink, sheet and strike all `Duration.zero` |
| `'android flag alone reduces motion'` | `MediaQuery.disableAnimations` true, platform-dispatcher flag false → `true`. `10 §2.3`'s first branch |
| `'ios flag alone reduces motion'` | The reverse. The branch a developer on one platform never exercises |
| `'both flags off leaves motion unreduced'` | The negative case, so the resolver is not simply returning `true` |
| `'the press flash survives reduce-motion at 40 ms'` | `indelible.md` §5.3's deliberate exception. The only visual feedback left to someone who cannot feel the screen |
| `'reduced is Duration.zero and not merely shorter'` | Exact equality. `lessThan(50)` would pass a 40 ms compromise on the ink token |
| `'a change to the accessibility flag rebuilds the dependent widget'` | `_MediaQueryFromView` implements `didChangeAccessibilityFeatures`, so the dependency is what makes the resolver live rather than read-once |
| `'CANARY: a resolver reading only disableAnimationsOf fails the iOS branch'` | The anti-pattern, written down as a failing expectation so nobody "simplifies" the OR away |
| `'haptics are not gated on reduce-motion'` | The vocabulary is T09's; this case asserts the resolver is not wired to it |

**`test/design/gate_inventory_test.dart`** — the honesty check.

| Case | What it asserts |
|---|---|
| `'test/design/ holds wcag.dart, contrast_test.dart, tap_target_test.dart and reduce_motion_test.dart'` | The four gate files exist and run |
| `'no file in test/design/ references kPumpableVariants'` | S7, made mechanical. When N33 lands the sweeps, this case is updated in the same commit that earns the change |
| `'each gate file states its scope and names where its sweep lands'` | Every file's head comment mentions N33-T02 or N33-T03 or `12 §7.6`. A gate with no stated scope is a gate that grows silently |
| `'semantics_gate_test.dart does not exist yet'` | An empty gate file reads as coverage. This case deletes itself at N33-T02 |

**Nothing here is time-shaped.** `Duration` is a span, not a clock reading, and no wall time is read —
so there is no `uk-zone` case. T06 has the epic's only one.

## 6. Constraints that bind this task

- **3am** — reduce-motion is an accessibility setting a shepherd may have on for reasons that have
  nothing to do with this app, and the press flash is the one confirmation that survives a glove, a
  freezer bag and the dark. Zeroing it would be a regression dressed as compliance.
- **A gate nobody has seen fire is indistinguishable from a broken gate** (`00-README` §9 step 1).
  Every case here is written so its failure names the thing that broke, and the canary is what proves
  the anchor is alive.
- **Honesty about scope** — four files, each saying what it does not do. This task exists because the
  previous plan asserted coverage it could not have had.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every animation resolves to zero duration when reduce-motion is on'` passes, and was seen to fail first for the stated reason
- [ ] the four gate files exist and run
- [ ] no gate iterates `kPumpableVariants`, and each says why in a comment
- [ ] reduce-motion resolves to zero, not to *shorter*
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `prefersReducedMotion` ORs **both** flags and has a passing test per branch
- [ ] the 40 ms press flash survives reduce-motion, with its own case
- [ ] every platform-dispatcher override is torn down in the test that set it (`-P ci-fast` randomises order)
- [ ] `semantics_gate_test.dart` does **not** exist, and `gate_inventory_test.dart` asserts it
- [ ] each gate file's head comment carries `12 §7.4`'s three-line split so N33 knows where to add
- [ ] the obligation to feed `ShedTokens.motion` from the resolver in `themeProvider` / `ShedBookApp` is recorded in the PR body for N11/N12

## 8. Verification

```bash
fvm flutter test test/design/reduce_motion_test.dart
fvm flutter test test/design/gate_inventory_test.dart
fvm flutter test test/design/           # all four gates, plus the inventory
make check
make test
```

Run the design folder twice in a row — randomised ordering is where a leaked accessibility override
shows up:

```bash
fvm flutter test test/design/ --test-randomize-ordering-seed=random
fvm flutter test test/design/ --test-randomize-ordering-seed=random
```

```bash
grep -rn "kPumpableVariants" test/design/                       # expect zero at N09
ls test/design/                                                  # expect four gate files + gate_inventory_test.dart
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `test(design): the gates that can honestly run before any screen exists`

# The Accessibility Nutrition Label

The single authored source of **every accessibility claim this product makes**. Nothing below is
re-typed anywhere; `docs/engineering/10-accessibility-and-i18n.md` §7.1 points here rather than
keeping a second copy that drifts. Same discipline as
[`offline-honesty.md`](offline-honesty.md), and for the same reason: a claim entered into App Store
Connect is outside every scanner this project has, so **you are the gate** (`13 §12` item 9).

**Apple's bar is behavioural, not technical:**

> *"To indicate support for an accessibility feature in the Accessibility Nutrition Labels, users
> must be able to complete **all of the common tasks** of your app using that feature."*

Six of seven is not declarable. `test/policy/accessibility_label_test.dart` parses this file and
fails if a `yes` row cites a test that does not exist, a test name that has been renamed, or a manual
pass that has not happened.

---

## 1. The seven common tasks

Shed Book has no login, so the list is fixed and short. It is a list of **tasks**, and it is not the
same list as the fourteen pumpable variants — unlock is a common task and not a variant; note search
is a variant and not a common task. A sweep that conflates them under-tests the purchase flow, which
is the one task nobody thinks of as accessibility work.

1. First run — the app opens on a usable Quick Entry with no onboarding to get past
2. Unlock, and restoring a purchase on a new phone
3. Quick Entry — pick the animal, tap what happened
4. Lambing Entry — the lambs, the ease, the care checks
5. Pen Board — who is penned, and turning out
6. Treatments — the medicine book and the countdowns
7. Settings — units, terminology, palette, export, restore

## 2. The declaration

**`Declare` is one of `yes`, `no` or `pending`, and `pending` is not a soft yes.** A feature is
`pending` while an evidence row it needs has not been produced; it may not be entered into App Store
Connect in that state, and the release ritual (`/shed-release`, N34-T04) is what moves it.

| Feature | Declare | Evidence |
|---|---|---|
| VoiceOver / TalkBack | pending | `test/design/semantics_gate_test.dart` · `'the canary widget with no semanticLabel fails the sweep'` ; `test/design/tap_target_test.dart` · `'an enabled target exposes SemanticsAction.tap'` ; manual · PENDING |
| Larger Text | yes | `test/features/overflow_matrix_test.dart` · `'the matrix count equals kPumpableVariants.length times the device, scale and bold '` ; `tool/check_policy.dart` · `type.clamp` |
| Sufficient Contrast | yes | `test/design/contrast_test.dart` · `'every text pair in all six palettes reaches 4.5 to 1 and every rule and mark 3 to 1'` ; `test/design/contrast_test.dart` · `'outline clears the 3:1 non-text requirement'` |
| Reduced Motion | yes | `test/design/reduce_motion_test.dart` · `'CANARY: a resolver reading only disableAnimationsOf fails the iOS branch'` ; `test/design/reduce_motion_test.dart` · `'reduced is Duration.zero and not merely shorter'` |
| Dark Interface | yes | `test/design/first_frame_parity_test.dart` · `'the launch colour equals nSurface04'` ; `test/design/first_frame_parity_test.dart` · `'both storyboards paint the ruled page colour'` |
| Differentiate Without Color Alone | pending | `test/features/redundancy_table_test.dart` · `'the rows with no case are exactly the ones whose screen is v1.1.0'` ; manual · PENDING |
| Voice Control | pending | `test/design/semantics_gate_test.dart` · `'the canary widget with no semanticLabel fails the sweep'` ; manual · PENDING |
| Captions | no | undeclared — see §4 |
| Audio Descriptions | no | undeclared — there is no video anywhere in the product, and no plan for one |

### Why three rows are `pending` rather than `yes`

**VoiceOver, Voice Control and Differentiate Without Color Alone are held partly by a hand pass that
has not been run.** The automated half is real and cited above; the half that is missing is
`10 §7.2` rows 1–10 on **one small iPhone and one small Android, in a dark room, holding a torch**,
across every variant, with `app_settings.left_handed` both ways. That is an evening and it cannot be
moved onto a laptop.

Writing `yes` now and running the pass later would be the same defect as a privacy claim no gate
holds — the exact thing this folder exists to prevent. `pending` is the honest state, and the test
enforces that a `pending` row is never read as a declaration.

## 3. Rows that are `yes`, and exactly why each one is safe to claim

- **Larger Text is declarable only because nothing clamps.** `10 §4.2` is blunt: clamp at 1.3× and
  *"you cannot declare Larger Text, which costs you a Nutrition Label row."* The evidence is the
  overflow matrix and the `type.clamp` gate row. **If either is ever weakened, this claim goes with
  it** — that is not a warning, it is what the test above enforces.
- **Sufficient Contrast is re-checked with Bold Text, Increase Contrast and Reduce Transparency on —
  and there is no reduce-transparency flag to read.** Flutter exposes none. The claim is held **by
  construction** instead: `BackdropFilter`, frosted bars and scrims over text are banned outright
  (`06 §2.5`, `10 §11` row 34). Cited that way rather than as a flag that does not exist.
- **Reduced Motion needs *both* flags.** iOS never sets `disableAnimations`; Android never sets
  `reduceMotion`; `MediaQueryData` has no `reduceMotion` property at all. Reading one flag is the bug
  `10 §11` row 10 names, and the canary case cited above is the assertion that it stays read.
- **Dark Interface is held by the four-layer no-white-flash configuration and its parity gate**
  (`06 §9.4`), not by `themeMode: ThemeMode.dark`. A cold launch that flashes white for two frames
  fails this claim on a device and passes every widget test, which is why the evidence is the parity
  gate and the two storyboards.

## 4. Captions — undeclared, and it is a consequence rather than an oversight

The app records voice notes (`record` 7.1.1, AAC-LC `.m4a`) and **cannot transcribe them**. On-device
speech recognition was cut from `v1.0.0` because the recognizer runs in another process whose network
access the manifest cannot constrain (owner ruling §7.0 #6). Declaring Captions would be false.

Ignoring the gap would be worse, so the design constraint that replaces it is a rule rather than a
note:

> **A voice note never carries a fact that exists nowhere else.**

Every fact a shepherd can record has a typed or tapped home in the record. A voice note is a margin
remark beside it, never the only place a lambing, a weight, a treatment or a withdrawal lives.

## 5. The per-screen sweep — `10 §7.2` rows 1–11

**Status: NOT YET RUN.** This section is the dated record, and it is empty on purpose. N34-T04 owns
the pre-release checklist and schedules the repeat; this file is where the result is written down.

Subjects: the eleven pumpable variants that exist in `v1.0.0` (`test/support/harness.dart`), each at
the smallest supported device, with `left_handed` both ways.

| Row | What | Device | Date | Result |
|---|---|---|---|---|
| 1–10 | `10 §7.2`'s per-screen sweep | — | — | not yet run |
| 6b | Smart Invert — **per release, not per screen**. Photos invert and that is accepted; no photo is the sole carrier of meaning | — | — | not yet run |
| 11 | The glove and freezer-bag pass. **Informs the design and does not gate the release** — decision-record §7.1 item 2, still open. Record the result; do not let it block | — | — | not yet run |

## 6. What this project does not produce

**No VPAT, and no claim of EN 301 549 conformance** (`10 §1.3`). The European Accessibility Act
covers a closed list of products and services that this one is not on, and a conformance claim nobody
asked for is a claim somebody has to defend.

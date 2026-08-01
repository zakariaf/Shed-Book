# N10-T05 — `ShedStatusBadge` and `ShedCountdown`

| | |
|---|---|
| **Epic** | [N10 — The component inventory](epic.md) · `00-README` §9 step 4 (2 of 3) |
| **Task** | 5 of 8 |
| **Depends on** | N10-T04 |
| **Commit** | one commit · `feat(ui): ShedStatusBadge and ShedCountdown, never colour alone` |

## 1. Why this task exists

Icon **and** word, always — colour is never the only channel, because a head torch and a
red-shift palette between them destroy hue discrimination. *Not recorded* is a first-class state:
never `0`, never blank, never *—*.

Indelible states the harder version: *"there is no badge. There is a stamp, and it is set in words."*
And for the one status where a colour would be easiest — §2.7's row for a dead lamb — the direction's
answer is **"colour: none, ever. Death is a word."** N09-T02 shipped `statusLoss` as a `ShedTokens`
field and wrote in its own gotchas that the field existing does not license a component to use it as
the only channel. This is the component where that would have happened.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §12 (`ShedStatusBadge`: ≥ 24 tall inside a ≥ `tapMin` parent, one state per status, **icon and word, always, never colour alone**; `ShedCountdown`: `headlineLarge` tabular, states active / clear / **not recorded**, *"never `0`, never blank"*) · §5.1 (`headlineLarge` 32 tabular, `labelMedium` / `labelSmall` at `bodySize`) · §5.4 (tabular figures, and the silent failure) · §11 (four encodings per status: colour **and** shape **and** text **and** position) | both contracts and the four-channel rule |
| `docs/design/indelible.md` | §7.7 (**the stamp** — boxed = a state of the animal, unboxed = a note about the record; the two word lists verbatim; the madder forms) · §7.6 (**the countdown** — 88 px row, day tally, `+n` cap at 28 marks, and the four states including *no colour change to the figure*) · §2.7 (**how status is encoded without relying on colour** — the thirteen-row table, and the `DEAD` row) · §6.1–§6.3 (there is no icon set; six marks; 24 or 28 px boxes only; butt caps, miter joins, `currentColor`) | every word, every mark, every value |
| `docs/engineering/CONVENTIONS.md` | **§2.7** (`sealed WithdrawalStatus` = `ClearsOn` / `NoWithdrawal` / `WithdrawalUnknown`, and *"the countdown widget takes a `ClearsOn`, never a `WithdrawalStatus`"*) · §2.2 (`LocalDate.of(Instant)`, `.daysUntil`) · §1.1 layer rule 7 · R24 (`now` is a parameter) | the parameter type, and the arithmetic that is safe |
| `docs/engineering/07-screens.md` | §10.3 (**the four withdrawal renderings** — countdown, *"Not applicable"*, *"Withdrawal not recorded"*, and clear-date-disagrees) · §10.2 (`Disclaimers.withdrawalCaveat` sits above the control, permanently) | which state renders what |
| `docs/engineering/05-domain-correctness.md` | §3.5 (a zero-day withdrawal still clears **tomorrow**, because the period elapses at the moment of administration and today is a partial day) | why `0 days` is a real value and never means "missing" |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-marks-and-strikes` | statuses, countdowns and every mark are its subject |
| `shed-accessibility-and-copy` | colour-never-alone and the words each state uses |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/components_test.dart`
- **Test** — `'every ShedStatusBadge state carries a word as well as a colour, and notRecorded renders neither 0 nor blank'`
- **Why it is red today** — nothing renders a status, and the obvious first implementation is a coloured dot.

```bash
fvm flutter test test/design/components_test.dart   # expect: failing, for the reason above
```

Sharpen it into an **exhaustive** loop, so a status added in season two cannot skip the rule:

```dart
for (final ShedStamp stamp in ShedStamp.values) {
  await _pumpComponent(tester, ShedStatusBadge(stamp: stamp, label: _labelFor(stamp)));
  final Finder text = find.descendant(
      of: find.byType(ShedStatusBadge), matching: find.byType(Text));
  expect(text, findsOneWidget, reason: '$stamp renders no word');
  expect(tester.widget<Text>(text).data, isNotEmpty);
  expect(tester.widget<Text>(text).data, isNot('0'));
  expect(tester.widget<Text>(text).data, isNot('—'));
}
```

Then the negative half, which is the one that actually bites: pump `ShedCountdown.notRecorded(…)`
and assert `find.text('0')` finds nothing and `find.byType(ShedTally)` finds nothing.

**Green.** The minimum code that passes, and nothing beyond it — both widgets with an exhaustive state switch and a word per state.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**UI and tests only.** No schema, no domain, no data, no wiring, no controller, no ARB entry — every
stamp word arrives as a `label`, because several of them are terminology the user owns and
`terminologyProvider` is a provider this layer cannot read. Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/components/shed_status_badge.dart` | **New.** The `ShedStamp` enum, its boxed/unboxed form, and the mark slot. One component for both of Indelible §7.7's forms, because the *difference* between them is the information: *"you can tell from ten feet away whether a stamp is talking about the sheep or about the writing"* |
| 2 | `lib/core/ui/components/shed_countdown.dart` | **New.** The default constructor over a `ClearsOn`, the two word-only named constructors, and the day tally |
| 3 | `test/design/components_test.dart` | **Extend.** The exhaustive stamp loop, the four countdown states, the `+n` cap, and the two DST cases |

### 5.2 The signatures

```dart
// lib/core/ui/components/shed_status_badge.dart

/// indelible.md §7.7's two lists, and the boundary between them is the whole
/// design: BOXED is a state of the animal, UNBOXED is a note about the record.
enum ShedStampForm { boxed, unboxed }

enum ShedStamp {
  // Boxed — a state of the animal.
  penned(ShedStampForm.boxed),   lambed(ShedStampForm.boxed),
  barren(ShedStampForm.boxed),   withdrawal(ShedStampForm.boxed),
  toLamb(ShedStampForm.boxed),   dead(ShedStampForm.boxed),
  alive(ShedStampForm.boxed),    petLamb(ShedStampForm.boxed),
  over(ShedStampForm.boxed),
  // Unboxed — a note about the record itself.
  auto(ShedStampForm.unboxed),      edited(ShedStampForm.unboxed),
  derived(ShedStampForm.unboxed),   counted(ShedStampForm.unboxed),
  yourEntry(ShedStampForm.unboxed), struck(ShedStampForm.unboxed),
  muted(ShedStampForm.unboxed),     notRecorded(ShedStampForm.unboxed);

  const ShedStamp(this.form);
  final ShedStampForm form;
}

final class ShedStatusBadge extends StatelessWidget {
  const ShedStatusBadge({super.key, required this.stamp, required this.label});

  final ShedStamp stamp;

  /// Always required, always non-empty. There is no state of this widget that
  /// renders a shape and no word — that is `06 §12`'s rule and the assert is
  /// what stops it being merely documented.
  final String label;
}
```

```dart
// lib/core/ui/components/shed_countdown.dart

final class ShedCountdown extends StatelessWidget {
  /// The ONLY constructor that draws a figure and a tally. It takes a
  /// `ClearsOn` and never a `WithdrawalStatus` (CONVENTIONS §2.7), so a
  /// countdown for an unrecorded period stays type-impossible — which is
  /// exactly what `07 §10.3` says it is.
  const ShedCountdown({
    super.key,
    required this.clearsOn,
    required this.now,          // R24: never read a clock; never import lib/core/time/
    required this.productName,
    required this.clearsOnLabel,   // 'CLEARS 12 AUG 2026', already formatted (R60)
    required this.semanticLabel,
  })  : words = null,
        _figureless = false;

  /// `WithdrawalUnknown` — a gap. Words only: no date, no figure, no tally.
  const ShedCountdown.notRecorded({
    super.key,
    required this.productName,
    required String this.words,    // 'Withdrawal not recorded'
    required this.semanticLabel,
  })  : clearsOn = null, now = null, clearsOnLabel = null, _figureless = true;

  /// `NoWithdrawal` — a fact off the label. Distinct from a gap (`07 §10.3`).
  const ShedCountdown.notApplicable({ /* … same shape … */ });

  final ClearsOn? clearsOn;
  final Instant? now;
  final String productName, semanticLabel;
  final String? clearsOnLabel, words;
  final bool _figureless;

  /// indelible.md §7.6: one 2 x 12 mark per remaining day, capped at 28 with
  /// `+n` printed after.
  static const int maxTallyMarks = 28;
}
```

The one line of arithmetic in the file, and it is civil-day arithmetic on purpose:

```dart
  int get _daysRemaining =>
      LocalDate.of(now!).daysUntil(clearsOn!.date);     // NOT now.difference(elapsesAt).inDays
```

### 5.3 The details that are easy to get wrong

- **`now.difference(clearsOn.elapsesAt).inDays` is wrong twice a year, and it is the obvious first
  implementation.** Across UK spring-forward a seven-day period is **168 hours of absolute time but
  167 hours of wall clock**, so integer division gives 6 (`00-PLAN-CRITIQUE` §11.3, DST-5). The
  withdrawal countdown is the worst place in the app to be a day out. Use
  `LocalDate.of(now).daysUntil(clearsOn.date)` — `LocalDate` is a civil date and the arithmetic is
  DST-free by construction. Both `Instant` and `LocalDate` are `lib/domain/time/`'s and importable
  from `lib/core/ui/` (layer rule 7).
- **`0` is a real value and `0 days` never means "missing".** `05 §3.5`: a zero-day withdrawal still
  clears **tomorrow**, because the period elapses at the moment of administration, which is almost
  never local midnight, so today is a partial day. So the countdown may legitimately render one tally
  mark and `LAST DAY`. What may never render is a bare `0` where a period was not recorded — those are
  different constructors and a different sentence.
- **The three withdrawal renderings are three different sentences and merging any two is a safety
  defect.** `07 §10.3`: `WithdrawalUnknown` → *"Withdrawal not recorded"* (a gap); `NoWithdrawal` →
  *"Not applicable"* (a fact off the label); `ClearsOn` → the countdown. *"One is a fact off the label,
  the other is a gap."* Three constructors, no shared "empty" branch, no `??`.
- **`ShedStatusBadge` is not 14 px.** Indelible §7.7 sets `--t-stamp` at 14 and that is a **known
  artefact defect** — `00-PLAN-CRITIQUE.md` §8 records it against the 18 px floor, and the three
  stamps that are the sole carrier of their meaning (`DEAD`, `AUTO-CAPTURED`, `DERIVED FROM N
  STROKES`) are precisely the ones it breaks. `buildShedTextTheme` has no 14 px role — its smallest is
  `bodySize` = 18 — and `token.literal_font_size` fails the build on `fontSize: 14`. Use `labelMedium`
  or `labelSmall`. N09-T05 owns the corrected exemption test; do not re-litigate it here and do not
  reproduce the 14.
- **"Icon" means one of Indelible's six marks, and most stamps have none.** §6.1: *"there is no icon
  set"* — the vocabulary is the dagger `†`, the double dagger `‡`, the query mark `?`, the tally
  stroke, the strike line and the delete key `⌫`, and **no new mark may be added without deleting
  one**. So `06 §12`'s *"icon and word, always"* is satisfied by **word + form**: the box is the
  second channel for an animal state, its absence is the second channel for a record note. Where a
  mark does apply — `†` on the last withdrawal day, `?` on a contradiction — it is drawn at 24 or 28
  px, `currentColor`, 2 px stroke, `StrokeCap.butt`, `StrokeJoin.miter`, **never 16 and never 20**
  (§6.3).
- **`statusLoss` exists as a token and must not be used here.** Indelible §2.7's `DEAD` row reads
  *"colour: **none, ever**"*, and N09-T02's own gotcha closes it: *"map `statusLoss` to full ink and
  let the word carry the meaning; that is the direction's answer and it is not negotiable in a
  component in N10."* A red `DEAD` badge is the single most likely reviewer suggestion on this diff
  and the answer is no.
- **The last-day state changes the mark and the rule, not the figure's colour.** Indelible §7.6:
  `†` in the margin, one tally mark, the word `LAST DAY`, a **doubled rule** beneath — and explicitly
  *"no colour change to the figure."* A countdown that turns amber at 1 day has replaced three
  channels with one.
- **The cleared row stays forever.** §7.6: *"`CLEARED 4 AUG` in `--ink-low`, tally replaced by a 2 px
  solid rule the width the tally used to be. The row stays in the medicine book forever."* The width
  is preserved deliberately — nothing reflows when a countdown clears.
- **`ShedStatusBadge` is not a tap target.** §7.7: *"stamps are not targets, except the margin stamp,
  whose target is the whole 68 × 64 margin cell."* So it does **not** wrap `ShedTapTarget`, and
  `06 §12`'s contract is *"≥ 24 tall inside a ≥ `tapMin` parent"* — the parent supplies the target.
  This is the component the pre-audit wording *"no dimension below 64"* would have made unbuildable
  (`00-PLAN-CRITIQUE` §11.3), so assert 24 here, and assert the parent's 64 in the row test.
- **Both files repeat the epic's standing traps.** No `colorScheme`; no constructed `TextStyle` — the
  days figure goes through `headlineLarge`, which carries `FontFeature.tabularFigures()`, and a fresh
  `TextStyle` drops it and makes the medicine book jitter (`06 §5.4`); token before literal; no
  provider; no clock.

### 5.4 The full test set

`test/design/components_test.dart`, extended. The two DST cases carry `tags: 'uk-zone'` so the
`test` job's `TZ=Europe/London --tags uk-zone` leg runs them; an untagged DST case passes for the
wrong reason.

| Case | What it asserts |
|---|---|
| `'every ShedStatusBadge state carries a word as well as a colour, and notRecorded renders neither 0 nor blank'` | **The anchor.** Exhaustive over `ShedStamp.values`: a non-empty word, never `0`, never `—` |
| `'every boxed stamp draws a border and every unboxed stamp draws none'` | The form is a real second channel and not a naming convention |
| `'ShedStatusBadge is at least 24 tall and is not a ShedTapTarget'` | `06 §12`'s contract, and Indelible §7.7's *stamps are not targets* |
| `'no stamp renders below the 18 px floor'` | Effective `fontSize` ≥ 18 at scale 1.0 for every member. Closes the artefact's 14 px defect at the component boundary |
| `'the dead stamp uses no status colour'` | Its ink equals the primary text ink, not `statusLoss`. Indelible §2.7 |
| `'ShedCountdown renders a tally mark per remaining day'` | 9 days in, 9 marks out |
| `'ShedCountdown caps the tally at 28 marks and prints +n'` | 41 days in: 28 marks and the text `+13` |
| `'the last day renders LAST DAY, a dagger and a doubled rule, and does not recolour the figure'` | Four assertions, one per channel, plus an ink equality against the default state |
| `'a cleared countdown keeps the tally's width as a solid rule'` | Laid-out width of the rule equals the laid-out width of the tally it replaced. Nothing reflows |
| `'ShedCountdown.notRecorded renders words and no figure, no tally and no date'` | `find.text('0')` absent, no tally widget, no date string |
| `'notRecorded and notApplicable render different sentences'` | The gap and the fact off the label are never the same string |
| `'ShedCountdown cannot be constructed from a WithdrawalUnknown'` | Source-text assertion: the default constructor's parameter type is `ClearsOn`, not `WithdrawalStatus`. CONVENTIONS §2.7 held at the type level |
| `'the days figure carries tabularFigures through headlineLarge'` | `fontFeatures` present; no constructed `TextStyle` in the file |
| **`'DST: seven days across UK spring-forward renders seven tally marks, not six'`** | `tags: 'uk-zone'`. The `Instant.difference().inDays` regression, caught. `TZ=Europe/London` |
| **`'DST: the tally is stable through the ambiguous hour 01:00–01:59'`** | `tags: 'uk-zone'`. Both readings of the repeated local hour on the clocks-back night give the same `LocalDate`, so the count does not flicker |
| `'both components render at textScale 2.0 with boldText with no overflow'` | The epic-wide case, these two components' rows |

## 6. Constraints that bind this task

- **Colour is never the only channel** (decision #106, WCAG 1.4.1 Level A; `06 §11`) — every stamp is
  word + form; every countdown state is word + mark + geometry. Verification is Indelible §11 test 4:
  screenshot it, desaturate it fully, read it. If anything has become ambiguous, it fails.
- **§12.1 — never default a withdrawal period.** This component renders a withdrawal figure, so it is
  on the safety path. It originates nothing: it takes a `ClearsOn` that came from
  `computeWithdrawalStatus`, which came from a `WithdrawalPeriod` with a private generative
  constructor. There is no `?? 0`, no `?? const Duration(days: 7)` and no fallback anywhere in these
  two files. A rule that drops to merely *documented* has been deleted.
- **§12.2 — never give veterinary advice.** The countdown renders the user's own number and the app's
  own arithmetic on it. It carries no interpretation, no "safe now", no colour that reads as a verdict.
  `07 §10.2` puts `Disclaimers.withdrawalCaveat` permanently above the control — that is the screen's
  job, and `copy.disclaimer_retyped` fails the build if this file re-types it.
- **3am** — the badge is ≥ 24 tall inside a ≥ `tapMin` parent; the countdown row is `tapHero` (88);
  18 px floor everywhere, dark only, no banned gesture.
- **No ARB entry** — every word is a `label` or a `words` parameter. `10 §3.2` rule 3: the spoken
  label must match the visible word, and only the screen has both.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every ShedStatusBadge state carries a word as well as a colour, and notRecorded renders neither 0 nor blank'` passes, and was seen to fail first for the stated reason
- [ ] every state has an icon and a word
- [ ] *not recorded* renders as its own words
- [ ] a countdown reaching zero says so in words, not by turning a colour
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the `ShedStamp` loop is exhaustive over the enum, not a hand-listed subset
- [ ] the default `ShedCountdown` constructor takes a `ClearsOn` and cannot be built from a `WithdrawalStatus`
- [ ] *not recorded* and *not applicable* are separate constructors rendering separate sentences
- [ ] day arithmetic goes through `LocalDate.daysUntil`, and both `uk-zone` cases pass under `TZ=Europe/London`
- [ ] the dead stamp uses no status colour, and no text in either file renders below 18 px

## 8. Verification

```bash
fvm flutter test test/design/components_test.dart
TZ=Europe/London fvm flutter test test/design/components_test.dart --tags uk-zone
fvm flutter test test/design/
make check
make test
```

```bash
grep -n "statusLoss" lib/core/ui/components/shed_status_badge.dart          # expect zero
grep -n "difference(\|inDays" lib/core/ui/components/shed_countdown.dart    # expect zero
grep -n "WithdrawalStatus" lib/core/ui/components/shed_countdown.dart       # expect zero
grep -nE "fontSize:|TextStyle\(" lib/core/ui/components/shed_*.dart         # expect zero
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): ShedStatusBadge and ShedCountdown, never colour alone`

# N10-T08 — `ShedEmptyState`, `ShedBanner` and `ShedReceiptBar`

| | |
|---|---|
| **Epic** | [N10 — The component inventory](epic.md) · `00-README` §9 step 4 (2 of 3) |
| **Task** | 8 of 8 |
| **Depends on** | N10-T07 |
| **Commit** | one commit · `feat(ui): ShedEmptyState, ShedBanner and ShedReceiptBar` |

## 1. Why this task exists

The empty state occupies **the same box the content will**, so nothing jumps when the
first record arrives. The banner is never modal, never between 22:00 and 06:00, and never on the five
shed screens. The receipt bar renders the committed row itself — P2's *the receipt is the row* made
into a component.

Two of the three carry a rule the product is built on. The empty states **are the onboarding**
(decision #71, `07 §2`) — there is no tour, no sample flock and no what's-new, so the empty state is
the only teaching surface the app has. And the banner is the only monetization component that exists
(`06 §12`): no modal, no interstitial, no self-appearing sheet, no badge, no accent.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §12 (`ShedEmptyState`: **occupies the same box the populated content will**, one line of copy + one action at the same `tapHero` control, *no illustration, no spinner, no tour*; `ShedBanner`: ≥ `tapHero` tall, **two `tapMin` actions**, never modal, never on the 3am path, never 22:00–06:00; `ShedReceiptBar`: ≥ `tapHero` incl. the Undo, live region, text unique per save) · §12's **three free-tier constraints** · §10.3 (**the three redundant channels**, and the house-bar fallback and everything it must then carry itself) | all three contracts |
| `CLAUDE.md` | **P2 — there is no SnackBar.** `showSnackBar(` is banned everywhere, including in `feedback.dart` (`CONVENTIONS §2.11` superseded). *"The confirmation **is** the committed row, in ink, one line above the one being written; undo is a time-boxed strike in that row's margin, its window stated in seconds"* | why `ShedReceiptBar` is the shipped path and not a fallback |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.1 (what `SnackBar` gets free and a house widget does not) · §3.8 (**the live region only re-fires on `didChangeLabel()`**, so the text must differ every time) · the `a11y.announce` row (`SemanticsService.announce` is a **no-op on Android**) | what the receipt bar must carry itself |
| `docs/engineering/11-monetization-and-store.md` | §6.1 (the two surfaces; the upgrade row uses **one** of the two action slots and has no dismiss) · §9.2 (**`isQuietHours(Instant)` is the only definition of 22:00–06:00 in the codebase**, and the DST note) · §12 (`ui.monetization_surface`) · the quiet-window test (*"the test sets the clock, not the entitlement"*) | the predicate and where the banner may be built |
| `docs/engineering/07-screens.md` | §2.2 (**the twelve-row empty-state table**, verbatim copy) · §16.2–§16.4 (the export prompt: six conditions, **06:00–22:00**, two actions, no third *later*, no close X) · §15.1–§15.4 (**undo per verb**; the label is a field, not a constant; undo does not survive process death and the copy must not imply it does) | the copy, the actions and the labels |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-states-and-feedback` | empty states, banners and receipts are exactly its subject |
| `shed-accessibility-and-copy` | the wording of an empty state is most of its value |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/components_test.dart`
- **Test** — `'ShedEmptyState occupies the same box as the content it replaces and ShedBanner refuses to build during quiet hours'`
- **Why it is red today** — nothing renders an empty state, and the layout jump when the first row arrives is invisible until a shepherd meets it.

```bash
fvm flutter test test/design/components_test.dart   # expect: failing, for the reason above
```

Sharpen both halves. The first becomes a **loose-constraints** assertion, because that is the shape of
the real bug — a screen wraps the empty state in something intrinsic and the list jumps when row one
lands:

```dart
await _pumpComponent(tester, const SizedBox(
  width: 375, height: 500,
  child: ShedEmptyState(/* … */),
));
expect(tester.getSize(find.byType(ShedEmptyState)), const Size(375, 500));
```

The second sets the **clock**, never the entitlement — `11 §12` is explicit about which knob the test
turns — and sweeps every hour rather than sampling one:

```dart
for (int h = 0; h < 24; h++) {
  await _pumpComponent(tester, ShedBanner(now: _atLocalHour(h), /* … */));
  final bool quiet = h >= 22 || h < 6;
  expect(find.byType(ShedTapTarget), quiet ? findsNothing : findsWidgets,
      reason: 'hour $h');
}
```

**Green.** The minimum code that passes, and nothing beyond it — three widgets; the banner takes the hour as a parameter and refuses to build in quiet
hours.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**UI and tests, plus one type.** No schema, no domain, no data, no wiring, no controller, no ARB
entry — `07 §2.2`'s twelve empty-state strings and `07 §16.3`'s banner copy belong to the screens
that render them. Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/components/shed_empty_state.dart` | **New.** Fills its parent by construction, so the *same box* rule is geometry rather than discipline |
| 2 | `lib/core/ui/components/shed_banner.dart` | **New.** Takes `now` and refuses to build in quiet hours. The only monetization component in the app, and also the export prompt — one component, two callers, one rule |
| 3 | `lib/core/ui/components/shed_receipt.dart` | **New.** `CONVENTIONS §2.11` names this file exactly — **`shed_receipt.dart`, not `shed_receipt_bar.dart`** — and gives it *"the widget only"* |
| 4 | `lib/core/ui/feedback.dart` | **New, and only the type.** `SaveReceipt` is R31's and §2.11 puts it here; the receipt bar needs it as a parameter type. **Do not land `confirmSaved`, `showFailure` or `showCapRow`** — P2 supersedes §2.11's shapes and `showFailure` needs `ShedFailure` from `lib/core/failure.dart`, which layer rule 7 does not let `lib/core/ui/` import. Say so in a comment at the top of the file |
| 5 | `test/design/components_test.dart` | **Extend.** The box case, the 24-hour sweep, the uniqueness case, the two-action case and the DST case |

### 5.2 The signatures

```dart
// lib/core/ui/components/shed_empty_state.dart

/// Decision #71: the empty states ARE the onboarding. One line of copy and one
/// action, at the same tapHero control the populated screen uses. No
/// illustration, no spinner, no tour, no multi-step anything (`07 §2.2`).
///
/// It fills its parent. That is the whole mechanism behind "occupies the same
/// box the populated content will": a screen puts the list and this widget in
/// the same slot, and nothing can jump.
final class ShedEmptyState extends StatelessWidget {
  const ShedEmptyState({
    super.key,
    required this.copy,       // '07 §2.2', verbatim: 'No animals yet.'
    this.action,              // a ShedPrimaryButton, or nothing (Lamb Card has none)
  });

  final String copy;
  final Widget? action;
}
```

```dart
// lib/core/ui/components/shed_banner.dart

/// Never modal. Never on the five shed screens. Never 22:00–06:00.
///
/// `now` is a parameter because a component in lib/core/ui/ reads no clock and
/// no provider (layer rule 7, R24). The caller passes appNow() or the value it
/// already has from minuteTickProvider.
final class ShedBanner extends StatelessWidget {
  const ShedBanner({
    super.key,
    required this.now,
    required this.message,
    required this.primary,        // ('Export now', onTap) / ('Unlock', onTap)
    this.secondary,               // ('Not this season', onTap) — the upgrade row has none
  });

  final Instant now;
  final String message;
  final ({String label, String semanticLabel, VoidCallback onTap}) primary;
  final ({String label, String semanticLabel, VoidCallback onTap})? secondary;

  @override
  Widget build(BuildContext context) {
    // THE one definition of the window (11 §9.2). Re-typing `h >= 22 || h < 6`
    // here is how the policy and the row end up disagreeing about when the app
    // goes quiet.
    if (isQuietHours(now)) return const SizedBox.shrink();
    // …
  }
}
```

```dart
// lib/core/ui/components/shed_receipt.dart

/// P2: there is no SnackBar. This IS the receipt, and because it is not a
/// SnackBar it inherits none of the framework's wrapping — `06 §10.3` lists
/// what it must therefore carry itself: its own Semantics(liveRegion: true),
/// the same text-uniqueness rule, and its own >= tapMin dismiss.
final class ShedReceiptBar extends StatelessWidget {
  const ShedReceiptBar({
    super.key,
    required this.receipt,
    required this.dismissLabel,
    required this.dismissSemanticLabel,
  });

  final SaveReceipt receipt;      // R31: term, tag, summary, at, undo, undoLabel
  final String dismissLabel, dismissSemanticLabel;

  /// `06 §10.3`: "the live region only re-fires on didChangeLabel(). Two saves
  /// in ten seconds is normal during triplets, so the text MUST differ every
  /// time: tag + summary + wall-clock time guarantees it."
  String get announcement =>
      '${receipt.term} ${receipt.tag} · ${receipt.summary} · ${receipt.at}';
}
```

### 5.3 The details that are easy to get wrong

- **`isQuietHours` is imported, never re-implemented.** `11 §9.2`: *"one predicate, so the policy and
  the upgrade row cannot disagree about when the app goes quiet"*, and the Definition of Done says
  *"`isQuietHours` is the only definition of 22:00–06:00 in the codebase, and both the policy and the
  two rows read it."* It lives in `lib/domain/free_tier.dart`, which layer rule 7 lets this file
  import. `h >= 22 || h < 6` typed into a widget is the defect this whole design exists to stop.
- **The export prompt's window is the *same* predicate, read the other way round.** `07 §16.2`
  condition 6 is *"local time is between 06:00 and 22:00"* — the complement. One component, one call,
  two callers; do not add a second boolean parameter for it.
- **The quiet-hours test sets the clock, not the entitlement.** `06 §12`'s third free-tier constraint
  says so in one sentence, and `11 §12`'s `quiet_window_never_solicits_test.dart` repeats it. A test
  that renders no banner because `unlocked: true` proves nothing about the hour.
- **The file is `shed_receipt.dart`.** `CONVENTIONS §2.11` names it exactly, and gives it *"the
  `ShedReceiptBar` widget and nothing else"*. `shed_receipt_bar.dart` is a rename of a published path
  and a defect.
- **P2 supersedes `06 §10.3`'s implementation but not its requirements list.** There is no `SnackBar`,
  so the receipt bar gets **none** of the framework's `Semantics(container: true, liveRegion: true)`
  wrapping (`10 §3.1`), none of `SnackBar.persist`'s auto-dismiss behaviour, and none of its
  `dismissDirection` handling. It carries its own live region, its own uniqueness rule and its own
  ≥ `tapMin` dismiss target. `Dismissible` is banned outright (`gesture.dismissible`), so there is
  nothing to set `dismissDirection` on.
- **`SemanticsService.announce` is a no-op on Android and is a gate row.** `a11y.announce` fails the
  build on it under `lib/`. The sanctioned path on both platforms is a live region, and Android 16
  deprecates announcements outright in favour of live regions. If the receipt does not speak, the bug
  is the **text not changing**, not the API.
- **Two saves in ten seconds is the normal case, not the edge case.** Triplets. If `announcement`
  can repeat — same tag, same summary, same minute — Android will not re-announce it. `at` is a
  pre-formatted `HH:mm` from `formatters.dart` (R31: *"`at` is pre-formatted `HH:mm`, 24-hour, en_GB
  … never here"*), so two lambs from the same ewe inside one minute produce identical text. Assert
  the uniqueness rule and, if the summary cannot carry it, say so in the PR body — this is a real hole
  and the receipt is the app's only confirmation channel.
- **The undo label is a field, not a constant.** R31 and `07 §15.3`: *"the word 'Undo' is only used
  where the record disappears."* A foster reads **"Correct this"** and a treatment reads **"Void
  this"**, because a compensating event and a soft-void both leave visible history and calling that
  *Undo* would be the app claiming to have erased something it did not. Never default `undoLabel` to
  anything in this component; `SaveReceipt` already defaults it and that is the only place it may.
- **Undo does not survive process death and the copy must not imply it does.** `07 §15.4`: no undo
  affordance is ever reconstructed from storage, and there is no *"you can undo this later"* copy
  anywhere. P2 adds that the window is **stated in seconds**. That sentence is the screen's copy, and
  it arrives as part of `SaveReceipt.summary` or the label — this component renders it and invents
  nothing.
- **The empty state has no illustration and no spinner.** `06 §12` and `07 §2.2`. `ui.spinner` is
  scoped to `lib/features/` (`CONVENTIONS §4.7`) and does not reach this folder, so hold it with the
  source case N10-T03 already added. `Image`, `SvgPicture` and a decorative `Icon` are all wrong: an
  illustration costs bundle budget (decision #127, < 5 MB) and says nothing at 3am.
- **Three empty-state strings on note search, not one.** `07 §2.2`: *"'No notes recorded yet' and 'no
  notes match this' are different facts, and a shepherd who sees the wrong one concludes the app lost
  their notes."* The component takes one `copy` string and cannot enforce that — the note-search
  screen (N26) picks which. Say so in the doc comment so the screen epic does not collapse them.
- **Two actions maximum, and the second is optional.** `06 §12` gives the banner two `tapMin` actions;
  `11 §6.1` says the upgrade row uses **one** of the two slots and has no dismiss, *"because a
  permanent row cannot meaningfully be dismissed"*; `07 §16.3` says the export prompt has both and
  *"there is no third 'later' action and no close X: not answering is already free."* So: one required
  record, one optional, and no `List<Action>` — a list is how a third arrives.
- **`ui.monetization_surface` allows `ShedBanner` in three feature folders, not two.** `11 §12`:
  `lib/features/flock/`, `lib/features/settings/` **and** `lib/features/quick_entry/` — the third is
  the export prompt, which is a safety feature and not monetization. Nothing about that reaches this
  file, but the doc comment should name it so a screen epic does not "fix" the rule.

### 5.4 The full test set

`test/design/components_test.dart`, extended.

| Case | What it asserts |
|---|---|
| `'ShedEmptyState occupies the same box as the content it replaces and ShedBanner refuses to build during quiet hours'` | **The anchor.** The empty state takes its parent's full 375 × 500; the banner renders nothing at 23:30 |
| `'ShedEmptyState takes the maximum of loose constraints, not the minimum'` | Pumped inside a `Column` with loose constraints it still expands. The real bug is an intrinsic wrapper, and this is what catches it before twelve screens have one |
| `'ShedEmptyState renders one line of copy and at most one action'` | One `Text`, zero or one `ShedTapTarget` |
| `'ShedEmptyState constructs no Image, Icon or progress indicator'` | Source text. No illustration, no spinner, no tour |
| `'ShedBanner renders at every hour from 06:00 to 21:59 and at none from 22:00 to 05:59'` | The 24-hour sweep. The clock is the knob, never the entitlement |
| `'ShedBanner reads isQuietHours and defines no window of its own'` | Source text: the file imports `free_tier.dart`, and contains neither `22` nor `06` as an hour literal |
| `'ShedBanner is tapHero tall with two tapMin actions and no third'` | ≥ 88 tall, both actions ≥ 60 (64 in practice), and the API has no way to pass a third |
| `'ShedBanner renders the same pixels with and without a cap value'` | `06 §12`: *"in the same pixels at 0 ewes as at 15."* Two pumps, identical laid-out size |
| `'ShedBanner is not modal and opens no route'` | No `showModalBottomSheet(`, no `showDialog(`, no `Navigator` call in the file |
| `'ShedReceiptBar is tapHero tall including its undo target'` | ≥ 88 overall; the undo target itself ≥ 64 in both axes |
| `'ShedReceiptBar carries its own liveRegion'` | `getSemantics(...).hasFlag(SemanticsFlag.isLiveRegion)`. It inherits none from a framework it no longer uses |
| `'two receipts for the same ewe in the same minute produce different announcement text'` | The `didChangeLabel` rule. If this fails, record the hole in the PR body rather than weakening the case |
| `'the undo label is whatever the receipt carries'` | `UNDO`, `Correct this`, `Void this` — three pumps, three rendered labels, no default in this file |
| `'no file in this commit calls showSnackBar('` | P2, and the same property N14-T04's anchor holds repo-wide |
| **`'DST: the quiet window is unambiguous through 01:00–01:59 on the clocks-back night'`** | `tags: 'uk-zone'`. `11 §9.2`: *"UK/Ireland's ambiguous DST hour sits inside this window under BOTH readings — so the one place in the app where a local hour is genuinely ambiguous is a place where the ambiguity cannot change the answer."* Both readings render no banner |
| `'all three components render at textScale 2.0 with boldText with no overflow'` | The epic-wide case, these three components' rows |

## 6. Constraints that bind this task

- **Zero interruptions** (spec §5) — the banner is never modal, never self-appearing as an overlay,
  never between 22:00 and 06:00 and never on Quick Entry, Lambing Entry, Lamb Card, Foster or Pen
  Board as a monetization surface (decision #90). `06 §12`: *"the whole product thesis is that nothing
  interrupts a lambing night."*
- **P2 — there is no SnackBar.** The confirmation is the committed row. `showSnackBar(` appears
  nowhere in this diff, and `ShedReceiptBar` carries the three things `06 §10.3` says a house bar must
  carry itself.
- **Every write commits immediately** — the receipt renders a fact that already exists. It is never
  shown before the transaction returns (`06 §10.3`: *"a false receipt is worse than no receipt"*), and
  this component has no state that could show one early.
- **3am** — banner ≥ `tapHero` (88) with two ≥ `tapMin` (60, 64 in practice) actions; receipt bar
  ≥ `tapHero` including the undo; empty state's action is the same `tapHero` control the populated
  screen uses. 18 px floor, dark only, no banned gesture — and `Dismissible` in particular is banned
  outright, which is why the receipt has a labelled dismiss instead.
- **No ARB entry** — `07 §2.2`'s twelve empty-state strings and `07 §16.3`'s banner copy are authored
  by the screens that render them, each with its `description`. This commit adds no message.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'ShedEmptyState occupies the same box as the content it replaces and ShedBanner refuses to build during quiet hours'` passes, and was seen to fail first for the stated reason
- [ ] the empty state and the content occupy the same box
- [ ] the banner cannot render between 22:00 and 06:00
- [ ] the receipt bar renders a row, never a toast — `showSnackBar(` is banned everywhere
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the banner calls `isQuietHours` from `lib/domain/free_tier.dart` and defines no window of its own
- [ ] the quiet-hours case sweeps all 24 hours and sets the **clock**, not the entitlement
- [ ] the `uk-zone` case passes under `TZ=Europe/London`
- [ ] `ShedReceiptBar` carries its own `Semantics(liveRegion: true)`, its own ≥ 64 dismiss, and a uniqueness case
- [ ] the file is `shed_receipt.dart`, and `feedback.dart` contains `SaveReceipt` and nothing else
- [ ] the banner exposes exactly two action slots, one of them optional, and no list

## 8. Verification

```bash
fvm flutter test test/design/components_test.dart
TZ=Europe/London fvm flutter test test/design/components_test.dart --tags uk-zone
fvm flutter test test/policy/one_overlay_test.dart
make check
make test
```

```bash
grep -rn "showSnackBar(" lib/                                              # expect zero
grep -n "isQuietHours" lib/core/ui/components/shed_banner.dart             # expect one
grep -nE "\b(22|06)\b" lib/core/ui/components/shed_banner.dart             # expect zero
grep -rn "SemanticsService" lib/core/ui/                                   # expect zero
ls lib/core/ui/components/shed_receipt.dart                                # the path CONVENTIONS §2.11 names
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): ShedEmptyState, ShedBanner and ShedReceiptBar`

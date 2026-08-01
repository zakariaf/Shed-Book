# N13-T06 — The two strips

| | |
|---|---|
| **Epic** | [N13 — Quick Entry: the deck and the keypad](epic.md) · `00-README` §9 step 5 (1 of 2) |
| **Task** | 6 of 7 |
| **Depends on** | N13-T05 |
| **Commit** | one commit · `feat(quick_entry): the penned and recents strips with their own empty copy` |

## 1. Why this task exists

*In the pens*, ascending by `entered_at` — oldest first, because that is the ewe most
likely to need something — and *recents*, the last six animals touched. Both empty states authored into
the ARB, both distinct, because *no ewes penned* and *no recent animals* are different facts.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§5.2** (the deck's two buckets and their orderings; *"no `time_source` is projected here"*) · **§5.3** (the states: loaded, empty day-one copy, error copy, over-cap renders nothing) · §5.1 (where the strips sit and what yields space first) · **§2.2** (the empty-state table: *"Nothing penned yet."* / *"No recent animals."*) · §1.4 (the state vocabulary) · §9.2 (hours-since-penned is computed in Dart, driven by the one ticker) | the two orderings, the two empty strings and the error row |
| `docs/design/indelible.md` | **§7.15** (the recents line: full-width **64 px** ruled lines, six of them — `412 · penned 2h · twin last year`) · §7.3 (the ruled record row and its states) · §7.4 (the ewe row: tag right-aligned in a fixed 76 px column) · §3.5 rule 4 (tags right-align on a tabular grid, and why the left column works) · §4.4 (row heights) · §2.7 (a status is never colour alone) | what a strip line looks like and how the tags align |
| `docs/engineering/CONVENTIONS.md` | **R28** (both strips are `.select`s over one provider) · §4.5 / R59 (widget keys) · §5.1 (**penned**, **tag**, **the deck**) · §2.11 (`ShedRecentsStrip`, `ShedAnimalRow`, `ShedEmptyState`) · §2.14 (`timeSincePenned`) · **R24** (`timeSincePenned(Instant enteredAt, Instant now)` takes `now`; `sincePenned` is a banned name) · R25 (`minuteTickProvider`) | **BINDING** on the providers, the keys and the words |
| `docs/engineering/02-state-di-navigation.md` | **§10.1** (neither strip rebuilds on a keystroke; each watches only its own `.select`) · §4.4 (what `.select` over a collection does and does not buy) · §4.5 (the exhaustive `AsyncValue` switch; *loading is never a spinner*; *error is never silent*) | the rebuild contract and the three arms |
| `docs/engineering/03-data-model-and-schema.md` | §8 (elapsed physical time from epoch millis; the DST worked example; the 60 s boundary-aligned ticker) · `EweTouches` (*"'touched' includes looking at a ewe card without writing anything"*) · §6 (active-only uniqueness) | why the hours figure is arithmetic, not a wall-clock difference |
| `docs/engineering/06-design-system.md` | §12 (`ShedRecentsStrip` — *"Fixed height at frame 1 so nothing shifts"*; `ShedAnimalRow`; `ShedEmptyState` — *"occupies the same box the populated content will"*) · §7 (the gesture ban) | the three components this task composes |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.3 (what Flutter gives you for free — *nothing* for a bespoke tap surface) · §8.4 (ARB conventions; the terminology-placeholder rule) · §9.2 (`formatShed*`) | the semantics and the copy rules |
| `CLAUDE.md` | the gesture ban (*"drag and drag handles"*) · P2 (there is no SnackBar) | one side of the horizontal-scroll conflict |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-states-and-feedback` | the empty states and their wording |
| `shed-screens-and-routing` | the strips are the screen's two read surfaces |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/quick_entry_test.dart`
- **Test** — `'the penned strip is ascending by entered_at and each strip has its own empty copy'`
- **Why it is red today** — the strips do not exist and the deck provider has no reader.

```bash
fvm flutter test test/features/quick_entry_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so the two halves fail separately and say why:

1. **Ordering.** Seed four open pen occupancies with `entered_at` values 31 h, 12 h, 4 h and 40 min
   old, in a deliberately shuffled insertion order. Read the rendered tags **top to bottom** and assert
   the oldest is first. Assert the *reason* in the message: the longest-penned ewe is the one you are
   standing next to (`07 §5.2`).
2. **Two distinct empty strings.** Pump three states — nothing penned but two recents; six penned but
   nothing recent; and neither — and assert the exact copy from `07 §2.2` appears in the right box each
   time: *"Nothing penned yet."* on the pens strip, *"No recent animals."* on the recents strip, and
   **never** one string doing both jobs. A single shared "Nothing here yet" passes a careless test and
   is the defect this case exists to catch.

**Green.** The minimum code that passes, and nothing beyond it — both strips over `ShedRecentsStrip` and `ShedAnimalRow`, with their ARB strings.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema, no domain, no data, no controller.** T03 built the deck; this task reads it. UI (step 6),
ARB (step 6 item 22) and tests (step 7). Say so in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/features/quick_entry/widgets/in_pens_strip.dart` | **New.** `class _InPensStrip` — a `ConsumerWidget` whose *only* watch is `quickEntryDeckProvider.select(… .penned)`, plus `minuteTickProvider` for the hours figure. Renders `ShedAnimalRow` per entry |
| 2 | `lib/features/quick_entry/widgets/recents_strip.dart` | **New.** `class _RecentsStrip` — a `ConsumerWidget` whose only watch is `quickEntryDeckProvider.select(… .recents)`. It watches **no** ticker: the recents strip shows no time at all (`07 §5.2`) |
| 3 | `lib/features/quick_entry/quick_entry_screen.dart` | **Edit.** The two reserved boxes T05 left as placeholders now hold the two strips. Their `Rect`s do not change — the anchor test from T05 must still pass unmodified |
| 4 | `lib/l10n/app_en.arb` | **Edit.** `quickEntryPennedEmpty`, `quickEntryRecentsEmpty`, `quickEntryDeckUnavailable`, `quickEntryDiagnostics`, `quickEntryPennedRowLabel`, `quickEntryHoursPenned` — each with a `description` |
| 5 | `docs/engineering/07-screens.md` §5.1 | **Edit, if the horizontal-scroll conflict in §5.3 is ruled against it.** `00-README` §10's amendment rule: the losing document changes in the same commit |
| 6 | `test/features/quick_entry_test.dart` | **Edit.** The anchor plus the cases in §5.4 |

No repository and no provider is added: R28 already gave both strips one provider, and adding a second
would break the one-statement rule this epic just paid for.

### 5.2 The signatures

The two reads, and nothing else. This is the whole of `02 §10.1`'s contract for these widgets — they
rebuild when *their own* bucket changes and at no other time:

```dart
// lib/features/quick_entry/widgets/in_pens_strip.dart
class _InPensStrip extends ConsumerWidget {
  const _InPensStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final penned = ref.watch(
      quickEntryDeckProvider.select((d) => d.whenData((v) => v.penned)),
    );
    // The ONE ticker in the app (R25). It drives the hours figure and nothing
    // else on this screen. autoDispose, boundary-aligned to the wall-clock
    // minute, yields Instant — never DateTime.
    final now = ref.watch(minuteTickProvider).value ?? appNow();
    …
  }
}
```

The hours figure is domain arithmetic, not a widget's subtraction. `CONVENTIONS` §2.14 and **R24**:

```dart
// lib/domain/penning.dart — N06-T07. Shown for reference only.
// `sincePenned` is a BANNED name; `package:clock` is banned in lib/domain/.
Duration timeSincePenned(Instant enteredAt, Instant now);
```

Widget keys. The qualifier is the **ewe id**, never the tag and never the list index (see §5.3):

```
quick_entry.penned_strip                 the reserved box
quick_entry.penned.<eweId>               one line
quick_entry.penned_strip.empty
quick_entry.recents_strip
quick_entry.recents.<eweId>
quick_entry.recents_strip.empty
quick_entry.deck_error
quick_entry.deck_error.diagnostics
```

The ARB messages, with the descriptions that carry the reasons:

```json
"quickEntryPennedEmpty": "Nothing penned yet.",
"@quickEntryPennedEmpty": {
  "description": "07 §2.2, verbatim. Distinct from quickEntryRecentsEmpty on purpose: 'nothing penned' and 'no recent animals' are different facts, and a shepherd who sees the wrong one concludes the app lost their records. The keypad is unaffected by either."
},
"quickEntryRecentsEmpty": "No recent animals.",
"@quickEntryRecentsEmpty": {
  "description": "07 §2.2, verbatim. See quickEntryPennedEmpty. Never merge the two strings."
},
"quickEntryDeckUnavailable": "Could not read recents.",
"@quickEntryDeckUnavailable": {
  "description": "07 §5.3's error state. One line, naming WHAT could not be read — never the exception message (decision #124), never red-on-yellow (decision #14). The keypad keeps working: a database read failure must not cost the ability to type a tag."
},
"quickEntryHoursPenned": "{hours}h",
"@quickEntryHoursPenned": {
  "description": "Elapsed time since penning, from timeSincePenned(enteredAt, now) — a DURATION, not an event time, so it carries no §12.5 provenance label. Display granularity is hours because the ticker is 60 s (decision #66). The semantics label is the spoken long form; see quickEntryPennedRowLabel.",
  "placeholders": { "hours": { "type": "int" } }
}
```

### 5.3 The details that are easy to get wrong

- **`07 §5.1`'s strips scroll horizontally, and drag is banned. Rule it here.**

  | Side | What it says | Where |
  |---|---|---|
  | `07` | `[ IN THE PENS · 6 tiles ]` and `[ RECENTS · 6 tiles ]`, *"fixed height, horizontally scrolling"* | `07 §5.1` |
  | Indelible + `CLAUDE.md` | The recents are **six full-width 64 px ruled lines** inside the sheet (§7.15). And the gesture ban is absolute: *"swipe-to-delete and every swipe action, **drag and drag handles**, long-press bindings, hold-to-repeat, pinch, force touch, sliders"* | `indelible.md §7.15`, `CLAUDE.md` §2 |

  A horizontally scrolling strip is operated by a lateral drag on a 64 pt-tall element — which is the
  gesture the ban names, and there is **no gate row that catches it**
  (`ListView(scrollDirection: Axis.horizontal)` is not on the banned-identifier list). Vertical page
  scroll is not in question: Indelible §4.5 is explicitly *"one scrolling ruled page"*.

  **The resolution to implement, and to amend `07 §5.1` for in this commit:** six full-width 64 px
  ruled lines per bucket, no horizontal scroll, no `Axis.horizontal` anywhere on this screen. Both
  buckets are already `LIMIT 6` in SQL (T03), so there is nothing to scroll *to* — the horizontal
  scroll in `07 §5.1` was affordance for a list that cannot exceed six rows. If the ruling goes the
  other way, it needs a gate row and a `[exempt]`-style justification, and R56 fixes the day-one exempt
  count at four.
- **A strip line's key qualifier is the ewe *id*, not the tag and not the index.** `CONVENTIONS` §4.5's
  own example is `pen_board.turn_out.3` — an id. Two reasons it cannot be the tag: a tag is *"exactly
  as typed"* and may contain letters, spaces or leading zeros (`RED`, `0412`), which breaks the
  all-`lower_snake` key format (R59); and two ewes may legitimately have carried the same tag across a
  cull. It cannot be the index because the list reorders every minute and *"a key is a test contract"*.
- **`ValueKey(eweId)` on the row widget, separately from the `Key('quick_entry.penned.<id>')`.**
  `02 §10.3` rule 5: value keys let Flutter reuse elements and their state as the list narrows. Use the
  widget key for the test contract and the value key for element reuse — they are different jobs and
  the same string may serve both, but do not drop one for the other.
- **The penned strip is ascending, the recents strip is descending, and the asymmetry is the design.**
  `07 §5.2`: penned is `ORDER BY o.entered_at ASC` — *"longest-penned first: the one you are standing
  next to"*; recents is `ORDER BY t.touched_at DESC`. Rendering both newest-first feels tidier and is
  wrong.
- **The hours figure is elapsed *physical* time and must be computed from epoch millis.** `03 §8`
  rule 1, with the worked example: *"A ewe penned at 22:00 on the Saturday before UK spring-forward and
  seen at 08:00 Sunday has been penned **9 hours**, not the 10 the wall clock suggests."* Call
  `timeSincePenned(enteredAt, now)` from `lib/domain/penning.dart`; do **not** subtract two
  `DateTime`s, and do not reach for `package:clock` — it is banned in `lib/domain/` (R24) and `now` is
  a parameter, always.
- **One ticker, and it is `minuteTickProvider`.** R25 and decision #66:
  `StreamProvider.autoDispose<Instant>` in `lib/core/time/ticker.dart`, boundary-aligned to the
  wall-clock minute, implemented with `Future.delayed` and never `Timer.periodic`. Not a
  `Timer.periodic` per row — *"that is 30 timers and measurable overnight battery"* — and not 30 s,
  because the display granularity is hours and *"cells updating at different moments read as noise
  under a head torch"*. `minuteTickerProvider` and `penTickProvider` are banned spellings.
- **The recents strip watches no ticker.** `07 §5.2` is explicit: *"Neither strip shows a time … the
  recents strip shows nothing but a tag."* Watching the tick there would rebuild six rows a minute, all
  night, for nothing.
- **`31h` is a duration, not an event time, and that is why §12.5 does not bind here.** `07 §5.2`:
  *"§12.5 applies to *displayed event times*, and there are none on this screen."* The moment anyone
  renders `03:20` on a strip line, it needs `RecordedTime.provenanceLabel` beside it and the deck
  statement needs `time_source` projected — which it deliberately does not have. If a task wants a
  clock time on a strip, it is a different task with a schema question attached.
- **"Touched" includes *looking*.** `03`'s `EweTouches` doc comment: *"'Touched' includes looking at a
  ewe card without writing anything, so it is an observation and is not derivable."* One row per ewe,
  upserted; it is a UI cache, not a record, which is why the history-table rule does not apply to it.
  Do not present the recents strip as a history of *actions*.
- **Two distinct empty strings, and the empty state occupies the populated box.** `07 §2.2` gives the
  exact copy; `06 §12`'s `ShedEmptyState` contract is *"occupies the same box the populated content
  will"*, one line of copy plus one action at the same `tapHero` control the populated screen uses, and
  *"no illustration, no spinner, no tour"*. Quick Entry itself is **never empty** — the keypad works at
  frame 1 — so these two strings are strip-local, not screen-level.
- **Error is never silent, and the keypad keeps working.** `07 §5.3`: the strips show
  *"Could not read recents."* on one line and a 60 pt **Diagnostics** control; the keypad is unaffected,
  because *"a database read failure must not cost you the ability to type a tag."* Never render the
  exception message (decision #124) and never red-on-yellow (decision #14). Read the `AsyncValue` with
  an exhaustive `switch` — no accessors, and `valueOrNull` is Riverpod 3 and does not exist here.
- **Over-cap renders nothing at all.** `07 §5.3`: *"No upgrade row, no counter, no colour change."*
  Neither strip may watch `entitlementProvider` (decision #90).
- **Tags right-align in a fixed 76 px column and are tabular.** Indelible §3.5 rule 4 and §7.4:
  *"`12`, `77` and `91` sit under the units column of `412`, `128` and `305`, so the eye runs straight
  down the numerals with no zig-zag. Right-alignment of the tag column is not a preference, it is the
  reason the left column works."* Left-aligning them costs the whole scan.
- **A status is never colour alone.** Indelible §2.7 and decision #106. If a penned line ever gains an
  over-threshold marker, it carries the dagger `†` **and** a word **and** its position — never a red
  tint. Today the line carries no status at all, and adding one is a different task.
- **Neither strip may rebuild on a keystroke.** `02 §10.1`'s table lists both as **never**. Each watches
  exactly one `.select` over `quickEntryDeckProvider` and nothing else. If a strip needs the current
  query — it does not — it would be reading the controller, and the rebuild counter in the anchor test
  would catch it.

### 5.4 The full test set

`test/features/quick_entry_test.dart`, through `pumpApp`, with `test/support/seeds.dart`'s
`seedPen` / `seedPenOccupancy` / `seedTouch` (added in T03).

| Case | What it asserts |
|---|---|
| `'the penned strip is ascending by entered_at and each strip has its own empty copy'` | **The anchor.** Four shuffled occupancies render oldest-first; three empty permutations render the two exact strings in the right boxes |
| `'the recents strip is descending by touched_at and caps at six'` | Seven touches, six lines, newest first |
| `'the penned strip caps at six'` | Seven open occupancies, six lines |
| `'a ewe in both buckets renders in both strips'` | Penned **and** recently touched. Two lines, two keys, no de-duplication — this is normal |
| `'neither strip rebuilds when a digit is typed'` | Build counters on both; type three digits; both counters unchanged (`02 §10.1`) |
| `'a recents change rebuilds only the recents strip'` | The mirror of T03's anchor, seen from the widget side |
| `'no strip uses Axis.horizontal, and no drag gesture exists on this screen'` | The ruling in §5.3, mechanised: source text plus a semantics-tree check for scrollable children |
| `'a strip line's key is quick_entry.<bucket>.<eweId> and never carries the tag'` | Seed a ewe tagged `0412` and one tagged `RED`; both keys are id-shaped and `lower_snake` |
| `'tags right-align in a fixed column and are tabular'` | `12`, `128` and `412` share a right edge; the resolved style carries `FontFeature.tabularFigures()` |
| `'the error state shows one line and a Diagnostics control, and the keypad still works'` | Force the deck stream to error; assert the copy, assert the 60 pt control, then tap a digit and assert the buffer advanced |
| `'the error line never contains the exception message'` | Decision #124. Throw with a recognisable message and assert it is absent from the tree |
| `'the empty state occupies the same box the populated strip will'` | `Rect` equality between the empty and populated renderings — the `06 §12` contract, and the reason T05's anchor still passes |
| `'nothing renders differently over the free cap'` | Six entitlement pumps, identical tree; no strip watches `entitlementProvider` |
| `'every strip line has a semanticLabel naming the tag and, for penned, the hours'` | A bespoke tap surface gets **nothing** for free (`10 §3.3`); the label is the whole content |
| `'hours penned is elapsed physical time across the ambiguous DST hour'` · **`@Tags(['uk-zone'])`** | `TZ=Europe/London`. A ewe penned at **00:30 GMT+1** on the clocks-back night, read at **01:30** in the *repeated* hour: elapsed physical time is **1 h**, and again at the second 01:30 it is **2 h** — while the wall clock reads the same both times. `03 §8`'s rule 1, on the one figure a shepherd uses to decide whether to turn a ewe out |
| `'the strip does not re-render between ticks'` | One `minuteTickProvider` emission produces exactly one rebuild of the penned strip, and zero of the recents strip |

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Penned** / **pen occupancy**, never *housed* or *in the pen* as a state name. **Tag**, never *ear
  tag*, *number* or *ID*. **The deck**, never *picker* or *chooser*.
- **No domain noun appears literally in an ARB message** (decision #61). *Ewe* is a user-editable term
  from the terminology overlay; if a strip label needs one, it arrives as a placeholder fed by
  `terminologyProvider`. That is why the two empty strings say *"Nothing penned yet."* and *"No recent
  animals."* rather than naming ewes.
- **§12.5 does not bind**: no event time is displayed. A duration is not a time.

## 7. Definition of Done

- [ ] `'the penned strip is ascending by entered_at and each strip has its own empty copy'` passes, and was seen to fail first for the stated reason
- [ ] penned ascending by `entered_at`
- [ ] at most six recents
- [ ] two distinct empty strings, both in the ARB with descriptions
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] both strips read `quickEntryDeckProvider` through `.select`; no second provider was added (R28)
- [ ] neither strip rebuilds on a keystroke, proved by a build counter
- [ ] **no `Axis.horizontal` and no drag on this screen**, and the horizontal-scroll conflict is ruled with its losing document amended in this same commit — or carried into the PR body with both sides cited
- [ ] every strip line's key is `quick_entry.<bucket>.<eweId>`, `lower_snake`, and carries no tag text
- [ ] the hours figure comes from `timeSincePenned(enteredAt, now)`; `sincePenned` and `package:clock` appear nowhere
- [ ] the recents strip watches no ticker
- [ ] the error state renders the ARB line, a `Diagnostics` control and never the exception message
- [ ] the empty state occupies the same `Rect` as the populated strip, so T05's anchor still passes unmodified
- [ ] the `uk-zone` hours-penned case exists and fails when the `TZ=Europe/London` leg is removed

## 8. Verification

```bash
fvm flutter test test/features/quick_entry_test.dart
fvm flutter test test/features/                 # T01, T04 and T05's files did not regress
make check
make test
```

```bash
TZ=Europe/London fvm flutter test --tags uk-zone
```

```bash
grep -rn "Axis.horizontal" lib/features/quick_entry/                  # expect zero
grep -rn "sincePenned\b" lib/ test/                                   # expect zero (R24)
grep -rn "package:clock" lib/domain/ lib/features/                    # expect zero
grep -rn "minuteTickerProvider\|penTickProvider" lib/ test/           # expect zero (R25)
grep -rn "entitlementProvider" lib/features/quick_entry/              # expect zero
grep -rn "valueOrNull\|\.value!" lib/features/quick_entry/            # expect zero
grep -n "quickEntryPennedEmpty\|quickEntryRecentsEmpty" lib/l10n/app_en.arb   # expect two distinct messages
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(quick_entry): the penned and recents strips with their own empty copy`

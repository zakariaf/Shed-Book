# N19-T04 — Hours since penned, off the one ticker

| | |
|---|---|
| **Epic** | [N19 — Pen Board](epic.md) · `00-README` §9 step 6 (5 of 5) |
| **Task** | 4 of 7 |
| **Depends on** | N19-T03 |
| **Commit** | one commit · `feat(pen_board): hours since penned, off the one ticker` |

## 1. Why this task exists

Elapsed time from N12-T03's single ticker — every tile updating **in the same frame** on
the minute boundary — and a ready-to-turn-out threshold labelled as **the user's own**, never the app's
recommendation. §12.2: the app may arithmetic-transform a number the user supplied; it may never
originate one that is a clinical or husbandry decision.

The arithmetic is already written and already tested: `timeSincePenned(enteredAt, now)` and
`isReadyToTurnOut(...)` landed in N06-T07, both taking `now` and the threshold as parameters. What
this task adds is the wiring that keeps them honest — one ticker, one frame, and a legend that says
whose number 24 is.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `shed-book-spec.md` | §7.4 (**hours since penned**, and *"colour or badge for ready to turn out based on a **user-set** threshold (e.g. 24 or 48 hours)"*), §12.2 | the number the board exists to show, and whose threshold it is |
| `docs/engineering/07-screens.md` | §9.2 (**the timer**, the ticker's published body, the battery argument, and *"never wrap a pen-board test in `Clock.fixed`"*), §9.3 (the three facts a tile carries and the sizes), §9.6 (**§12.2 — the READY legend names the user's own number**) | the ticker, the readout and the wording |
| `docs/engineering/03-data-model-and-schema.md` | §8 (hours since penned is never stored and never computed in SQL; the three rules that follow) | why the value is derived at render |
| `docs/engineering/01-architecture.md` | §7.2 (**bucket A** — values that change with no write; one app-level boundary-aligned ticker; never a `Timer.periodic` per row) | the mechanism, and the name of the anti-pattern |
| `docs/engineering/02-state-di-navigation.md` | §4.2 (**why `.autoDispose` is load-bearing on the ticker**), §4.4 (`.select` narrows a rebuild), §9.1 (`ref.invalidate(minuteTickProvider)` on resume — N12-T03's line, already written) | the disposal contract this screen must not break |
| `docs/engineering/05-domain-correctness.md` | §2.9 (DST-1: penned Sat 22:00, seen Sun 08:00 is **9 h**), §7.2 (the origination line), §7.5 (*"the pen board's badge is fine because the threshold is user-set… 'past your 24 h threshold', never 'ready'"*) | the arithmetic and the two safety rules |
| `docs/engineering/12-testing.md` | §2.2 (the binding's **advancing** fake clock; `Clock.fixed` freezes), §2.4 (**the two published pen-board DST tests, verbatim**), §2.5 (the three commands) | the anchor's siblings and how to drive a tick |
| `docs/engineering/03-data-model-and-schema.md` | §5.13 (`turn_out_threshold_hours` — a **display** threshold, its `CHECK (… BETWEEN 1 AND 336)`, and why its default is not §12.1's business) | where the number comes from |
| `docs/design/indelible.md` | §8 screen 7 (the header line, **sorted by hours descending**, the hours column hard against the right edge), §5.2 (**rows never reorder**; numbers never animate), §5.4 (the haptic when a pen crosses the threshold: *one tick, nothing else*), §3.5 (tabular numerals) | the ordering, the header and the one haptic |
| `docs/engineering/06-design-system.md` | §5.5 (tabular figures; **never construct a bare `TextStyle` for a numeral**), §11 (32 pt hours, the type scale at 60 cm) | the typography of the number the board exists to show |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-riverpod-providers` | the ticker's fan-out and the same-frame requirement |
| `shed-safety-rules` | the threshold is the user's and the wording must say so |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/pen_board_test.dart`
- **Test** — `'every tile updates in the same frame on the minute boundary and the threshold is labelled as the user's own'`
- **Why it is red today** — nothing computes elapsed time, and twelve tiles would grow twelve timers.

```bash
fvm flutter test test/features/pen_board_test.dart   # expect: failing, for the reason above
```

Sharpen it into the two halves the name promises. **Same frame:** seed twelve open occupancies at
twelve different entry instants, pump the board, record every rendered hours string, then
`tester.pump(const Duration(minutes: 1))` **once** and assert that every string that should have
advanced did so after that single pump — not after two, and not one row at a time. **The user's own:**
set `turn_out_threshold_hours` to something that is not the default (18), pump, and assert the legend
renders the number **18** and the word *your*; assert the literal string `24` appears nowhere on the
screen. A test that only checks the first half passes against twelve `Timer.periodic`s.

**Green.** The minimum code that passes, and nothing beyond it — one ticker, one rebuild, and wording that attributes the threshold.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 5 (the controller's derived value), step 6 (the screen and the ARB) and step 7.** No schema, no
data, no new domain function — `lib/domain/penning.dart` already holds both functions and this task
adds nothing to it. Say the skipped layers in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/features/pens/pen_board_controller.dart` | **Edit.** `PenTile.forTick(now, thresholdHours:, today:)` — the only place `hours` and `status` are assigned, and the board's comparator (`_byHoursDescending`) |
| 2 | `lib/features/pens/pen_board_screen.dart` | **Edit.** Watch `minuteTickProvider` and `settingsProvider.select((s) => s.turnOutThresholdHours)` **here, in the widget**; map the projection through `forTick`; render the hours column and the header line; render the legend |
| 3 | `lib/l10n/app_en.arb` | **Edit.** `penHoursShort` (`{hours}h` — one string, no space, 07 §9.3), `penBoardReadyLegend` (`Ready = your {hours} h threshold`), `penBoardHeaderCounts`, and `pennedForHours` for the spoken sentence T07 assembles. Every one with a `description` |
| 4 | `test/features/pen_board_test.dart` | **Edit.** The anchor plus §5.4's cases |
| 5 | `test/features/pen_board_dst_test.dart` | **New.** `@Tags(['uk-zone'])` — 12 §2.4's two published cases, verbatim, plus the fall-back case |

### 5.2 The signatures

```dart
// lib/features/pens/pen_board_controller.dart — the method T02 declared on PenTile.
//
// The two derived facts, for the instant the ticker just yielded. Nothing here
// is cached and nothing is stored: 01 §7.2 bucket A — a value that changes with
// no write is wrong within a minute of being written down.
PenTile forTick(Instant now, {required int thresholdHours, required LocalDate today}) {
  final Instant? at = enteredAt;
  if (at == null) return copyWith(hours: 0, status: PenTileStatus.empty);

  // lib/domain/penning.dart (R24, N06-T07). Both take `now`; neither reads a
  // clock, and `isReadyToTurnOut` originates neither the threshold nor `now`.
  final Duration elapsed = timeSincePenned(at, now);
  final bool ready =
      isReadyToTurnOut(enteredAt: at, now: now, thresholdHours: thresholdHours);
  final bool underWithdrawal = clearDate != null && !clearDate!.isBefore(today);

  return copyWith(
    hours: elapsed.inHours,
    status: hasLoss
        ? PenTileStatus.loss
        : underWithdrawal
            ? PenTileStatus.attention
            : ready
                ? PenTileStatus.ready
                : PenTileStatus.settling,
  );
}
```

And the read, in the widget and nowhere else:

```dart
// lib/features/pens/pen_board_screen.dart
final AsyncValue<List<PenTile>> board = ref.watch(penBoardProvider);      // keepAlive
final AsyncValue<Instant> tick = ref.watch(minuteTickProvider);           // autoDispose — HERE
final int threshold =
    ref.watch(settingsProvider.select((s) => s.turnOutThresholdHours));   // the USER's number
```

### 5.3 The details that are easy to get wrong

1. **Do not `ref.watch(minuteTickProvider)` inside `penBoardProvider`.** `penBoardProvider` is
   keepAlive (CONVENTIONS §3.2) and the ticker is `.autoDispose` (R25). A keepAlive listener is a
   listener that never goes away, so the ticker would keep waking the process every 60 s all night
   with no board on screen — which is exactly the *"measurable overnight battery"* argument decision
   #66 makes, and the reason 02 §4.2 calls the `.autoDispose` **load-bearing rather than tidiness**.
   The widget watches the tick; when the route pops, the last listener goes.
2. **Nor may the projection be re-subscribed per tick.** If the tick reaches the provider, the
   `async*` body re-runs and drift re-opens the statement every sixty seconds all night. The
   projection is watched once; the tick only changes what is rendered from it.
3. **Never wrap a pen-board test in `withClock(Clock.fixed(…))`.** `Clock.fixed` freezes `now()`, so
   every hours readout stays at its initial value forever and the test passes while measuring 0 h
   (decision #113, 12 §2.2, 07 §9.2 — three documents say it because it has bitten three times). For
   an elapsed-time test, **offset the seed data**: `enteredAt: appNow().plus(const Duration(hours: -23, minutes: -59))`.
   The one legitimate `atFixed` use is a single-instant assertion, and 12 §2.4 requires a comment
   above it saying so.
4. **`tester.pump(const Duration(minutes: 1))` really does move `appNow()`.** The widget binding runs
   every `testWidgets` body inside a `FakeAsync` zone whose clock is installed as `package:clock`'s
   ambient clock, so no fake, no injection and no `package:fake_async` are needed — and the last is
   not a declared dependency and must not become one.
5. **Sort by hours descending, and let the statuses fall out of it.** 06 §11 says *ready* and *loss*
   are "sorted to top" and *empty* to the bottom; Indelible §8 screen 7 says the board is sorted by
   hours descending. Implement Indelible's: hours-descending puts every over-threshold row at the top
   **by construction**, and — this is the load-bearing part — the relative order of two occupied rows
   **never changes on a tick**, so no row moves under a thumb that is already on its way down.
   A comparator that sorts on `status` reorders the board at the exact moment a ewe crosses the
   threshold, which is Indelible §5.2's ban (*"rows never reorder"*) and a mis-tap on a ewe you did
   not mean. The full key is: loss first (it changes only on a write), then hours descending, then
   empty pens last.
6. **Display granularity is hours, and the string is one string.** `9h`, `26h`, no space before the
   `h`, and never `26h 04m` (07 §9.2 — *"no 30-second tick, because the display granularity is
   hours"*; 12 §2.4 matches `find.textContaining('9h')`). Two `Text` widgets side by side break that
   finder and break the semantics sentence with it.
7. **The number goes through a `TextTheme` role that carries `FontFeature.tabularFigures()`, never a
   fresh `TextStyle`.** Constructing one drops `fontFeatures`, and the board starts jittering as
   `412` and `108` take different widths — 06 §5.5's failure mode, and it is silent.
8. **`isReadyToTurnOut` takes the threshold; nothing in this file may default it.** The value comes
   from `settingsProvider`, which reads `app_settings.turn_out_threshold_hours`. A `?? 24` anywhere in
   the widget layer re-originates the number the schema deliberately keeps in one place.
9. **The legend prints the user's number and the word *your*.** 07 §9.6: *"Ready = your 24 h
   threshold"*, with **their** number substituted, and 05 §7.5 is explicit that the badge is
   acceptable *only* because the threshold is user-set — *"'past your 24 h threshold', never
   'ready'"* as a claim on its own. The ARB message takes `{hours}` as a placeholder; a hard-coded
   `24` in a string is a §12.2 defect, and `ContentPolicy` is entitled to catch it.
10. **The haptic fires when a pen crosses the threshold while the app is open — one tick, nothing
    else** (Indelible §5.4). The trap is firing it for every already-over row on the first build:
    twelve ticks the moment the board opens, which reads as a fault. Compare against the *previous*
    tick's status, and fire only on a `settling → ready` transition observed while the screen is
    mounted. No banner, no sound, no notification.
11. **Numbers never animate** (Indelible §5.2). No count-up, no odometer, no crossfade on the hours;
    the value re-prints. `--motion-ink` is an opacity fade for a *newly printed* glyph, not for a
    changing one.
12. **`.select` on the settings row, not a whole-row watch.** The board rebuilding whenever any
    setting changes is the rebuild scope 02 §4.4 exists to narrow, and the selected value is a scalar,
    so `==` is meaningful and the deduplication is real.
13. **After a resume the values are stale until the next tick, and N12-T03 already fixed that** with
    the one legitimate `ref.invalidate(minuteTickProvider)` in `app.dart`. Do not add a second
    invalidate, a `WidgetsBindingObserver` on this screen, or a manual refresh — `stream.invalidate`
    is a gate row and this screen is not the place to spend it.

### 5.4 The full test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/features/pen_board_test.dart` | `'every tile updates in the same frame on the minute boundary and the threshold is labelled as the user's own'` | **The anchor.** Twelve rows, one pump, and the legend carrying the user's 18 |
| | `'the tile crosses the turn-out threshold on a tick, not on a rebuild'` | 12 §2.4's published case: seed at 23 h 59 min, expect no `READY`, pump one minute, expect `READY` |
| | `'the board renders no hours for an empty pen and does not sort it to the top'` | `enteredAt == null` — the arithmetic must not treat a missing instant as the epoch |
| | `'two rows never swap position on a tick'` | Record the order, pump five minutes, assert the order is unchanged. The mis-tap hazard in item 5 |
| | `'a loss row sorts above a longer-penned settling row'` | The one status in the comparator, and it changes only on a write |
| | `'no Timer is pending after the board is popped'` | The `.autoDispose` contract seen from the consumer side: pop the route, pump, and assert no further rebuild |
| | `'the literal 24 appears nowhere on the screen when the user threshold is 18'` | §12.2 as a rendered-text assertion, not a source scan |
| | `'the hours numeral carries tabular figures'` | Read the resolved `TextStyle.fontFeatures` off the rendered widget — the silent 06 §5.5 regression |
| | `'crossing the threshold fires one haptic, and opening a board of three over-threshold pens fires none'` | Item 10, both directions, through the platform-channel recorder |
| `test/features/pen_board_dst_test.dart` `@Tags(['uk-zone'])` | `'a ewe penned at 22:00 GMT reads 9 h at 08:00 BST, not 10'` | 12 §2.4's first published case, verbatim, including the `atFixed` comment |
| | `'the tile crosses the turn-out threshold on a tick, not on a rebuild'` | 12 §2.4's second published case — the one that would silently measure 0 h if it were wrapped in `atFixed` |
| | `'a ewe penned at 22:00 BST on 24 October 2026 reads 11 h at 08:00 GMT, not 10'` | The **fall-back**, the other direction, in the hour that happens twice |
| | `'the ticker keeps a 60 s gap across the ambiguous hour, so no row ticks twice in one wall-clock minute'` | Boundary arithmetic over epoch millis, seen from the board rather than from the ticker |

## 6. Constraints that bind this task

- **§12.2, and the whole rule reduces to one word: *whose*.** The ready-to-turn-out threshold is the shepherd's own number, read from settings and labelled as theirs in the legend. The app may arithmetic-transform a number the user supplied; it may never originate one that is a husbandry decision. A hard-coded 24, a suggested 24 and a legend that omits whose number 24 is are the same defect at three levels of subtlety.
- **§12.2 held at *test on source text* plus a rendered assertion** — `ContentPolicy` catches an
  advisory string; the anchor catches a hard-coded threshold that no regex would. Both, because the
  wording is the whole mechanism here.
- **One ticker, app-wide** — no `Timer.periodic`, no `Stream.periodic`, no per-row timer, and no
  second provider that ticks. `net.sync_timer` is the gate row and it carries no exemption.
- **Nothing derived is stored** — no column, no cache, no field on a row class holds an hour.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every tile updates in the same frame on the minute boundary and the threshold is labelled as the user's own'` passes, and was seen to fail first for the stated reason
- [ ] one ticker for the whole board
- [ ] all tiles update in the same frame
- [ ] the threshold's label names the user as its source
- [ ] the app ships no default threshold value
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `minuteTickProvider` is watched by the **widget**; `penBoardProvider` does not reference it, and popping the board leaves the ticker with no listener
- [ ] `test/features/pen_board_dst_test.dart` is tagged `uk-zone`, guards its offset in `setUpAll`, and carries the *"this atFixed is a single-instant assertion"* comment above its one `atFixed`
- [ ] the board's order is loss, then hours descending, then empty — and a tick never reorders two occupied rows
- [ ] `grep -rn "?? 24\|= 24" lib/features/pens/` returns nothing

> **Read the fifth DoD line against 03 §5.13.** `app_settings.turn_out_threshold_hours` **does** carry
> `withDefault(const Constant(24))`, and that is ruled legitimate: it is a *display* threshold that
> decides when a badge appears and nothing else — it is in no export, no CSV, no PDF, and no other
> column derives from it, so it answers no veterinary question on the user's behalf, and a blank
> threshold would mean no badge ever. What this DoD line forbids is the app **presenting** 24 as a
> recommendation: the legend prints the user's own number, the copy says *your*, and no string
> literal in `lib/features/pens/` contains the number at all. The withdrawal period is the value that
> may never be defaulted (§12.1), and it is not this screen's.

## 8. Verification

```bash
# 1. Red first, for the stated reason.
fvm flutter test test/features/pen_board_test.dart

# 2. Green, then the zone leg — unscoped, so the tag selects the files.
fvm flutter test test/features/pen_board_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone

# 3. Both gates.
make check
make test
```

```bash
grep -rn "minuteTickProvider" lib/features/pens/     # expect: the screen only, never the provider file
grep -rn "Timer\.\|Stream.periodic" lib/features/    # expect nothing
grep -rn "Clock.fixed\|withClock" test/features/pen_board*.dart   # expect: one, commented
grep -rn "TextStyle(" lib/features/pens/             # expect nothing — numerals go through a role
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(pen_board): hours since penned, off the one ticker`

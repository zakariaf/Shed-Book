---
name: shed-screens-and-routing
description: >-
  What a screen is made of, how it is reached, and what it costs in taps — including undo and delete
  per verb. Use when adding, changing or routing to a screen, and when undoing or deleting a record.
  Do NOT use for how it is drawn (indelible-page-and-screens).
---

# Screens and routing

Twelve screens plus note search. This skill owns **what is on a screen, what it costs the shepherd,
how it is reached, and what a verb can take back.** `docs/engineering/07-screens.md` and
`docs/engineering/02-state-di-navigation.md` carry the per-screen prose — cite them, never copy them.

## 0. Two rulings that override the doc set — read first

1. **There is no SnackBar. Anywhere.** `showSnackBar(` is banned in every file *including*
   `lib/core/ui/feedback.dart`; `CONVENTIONS §2.11`'s "the one file permitted to call `showSnackBar(`"
   is superseded and becomes a `check_policy` row with no allowlist entry. `feedback.dart` keeps
   `confirmSaved` / `showFailure` / `showCapRow` and their signatures (R30, R31) and changes only what
   they render — and **what** they render is `indelible-states-and-feedback`'s to state, not this
   skill's. Read every "SnackBar" in `07 §5.5`, `§8.1` and the `§15.1` Window column as *the row's own
   margin*.
2. **There is no birth-type chooser** (ruling P8). Birth type is derived from the lamb tally strokes
   and labelled as derived, which is what makes safety rule §12.4 structural rather than procedural;
   the derivation, the stamp and the one surviving use of `ShedChoiceRow` belong to
   `indelible-marks-and-strikes` and `indelible-controls`. The consequence **this** skill owns: the
   sixth tap of the 6-tap lambing journey is **the first tally stroke**, so `07 §5.4`'s keyed finder
   ~~`lambing_entry.birth_type.twin`~~ is superseded — target `lambing_entry.tally.stroke` instead
   (P8 ruled 2026-08-02, decision-record §7.0b).

## 1. Not this skill

- **How a screen is drawn** — page, band, stream, live row, type: `indelible-page-and-screens`.
- **Whether a write succeeded**, repository verbs, `WriteOutcome`, `WriteController.guard()`:
  `shed-write-path`. This skill owns what undo *means*; that one owns how the write runs.
- **The look of empty, frame 1, error, receipt and the export-prompt line**:
  `indelible-states-and-feedback`. This skill owns *which* states a screen must implement and *when*
  the prompt may fire.
- The strike mark: `indelible-marks-and-strikes`. §12.4's mechanism: `shed-safety-rules`.

## 2. A screen is one drift statement

**Every screen has exactly one *content* statement** (decision #12). It may additionally watch
single-row lookups and the app singletons `settingsProvider`, `entitlementProvider`,
`tagIndexProvider`, `minuteTickProvider`. **No displayed value may be computed from two drift
streams.** If two streams must agree for the screen to be correct, they are one statement. Fan-in
happens in SQL (`WITH … UNION ALL`), never in Dart.

- `combineLatest` over drift streams is a **build-breaking defect**. The mechanism (drift#3338) and
  the provider-side rule are **shed-riverpod-providers**'; what this skill asserts is only that a
  screen has one content statement.
- Every aggregate goes through `customSelect` with an explicit `readsFrom:` (decision #60). Never
  `groupBy` in a Dart-defined view.
- **Nothing on a shed screen may watch `entitlementProvider` or `purchaseServiceProvider`**
  (decision #90). The shed screens: Quick Entry, Lambing Entry, Lamb Card, Foster, Pen Board.

Screen → route helper → feature folder → content query is `07 §1.1`. Provider names and auto-dispose
policy are `CONVENTIONS §3.2`/`§3.4` — exhaustive, and they carry the banned spellings too. Look the
name up there; never invent one, and never recall one.

Briefs, cite by section: `07 §3` Flock · `§4` Ewe Card · `§5` Quick Entry · `§6` Lambing Entry ·
`§7` Lamb Card · `§8` Foster · `§9` Pen Board · `§10` Treatments · `§11` Reminders · `§12` Season
Summary · `§13` Export · `§14` Settings · `§18` note search.

## 3. Every state, every screen

Implement all of `07 §1.4`: **Frame 1, Loaded, Empty, Filtered-empty, Error, Over-cap.** Where a
state is impossible the brief must say why — "impossible" is an answer, silence is not.

- **Frame 1 is a fixed-height placeholder in the same surface colour. Never a spinner.**
  `CircularProgressIndicator` in `lib/features/**` fails `tool/check_policy.dart`. No layout shift
  when data lands.
- **Empty occupies the box the content will occupy**, one line of 18 pt copy, and **exactly one
  action — the same control the populated screen uses** (decision #71). Empty states are the only
  onboarding: no tour, no sample flock, no what's-new, no rating prompt. Use `07 §2.2`'s copy.
- **Filtered-empty is a different string from Empty.** Note search needs three distinct strings — no
  query yet / no notes exist at all / no notes match this. The wrong one makes a shepherd conclude
  the app lost their notes.
- **Over-cap renders nothing on seven of twelve screens** (`07 §19.2`). Two surfaces exist: the
  pinned row atop Flock, and Settings ▸ Unlock. No modal, interstitial, self-appearing sheet, badge
  or colour change. Never mid-entry — `EntryContext.liveEntry` is structurally incapable of returning
  `BlockedByCap`. Never 22:00–06:00. Nothing over the cap is ever deleted, hidden, greyed or made
  read-only.
- **"Not recorded" is a state and is never merged with "not applicable" or with zero.**
  `WithdrawalNotRecorded` (a gap) shows "Withdrawal not recorded", no countdown;
  `WithdrawalNotApplicable` (a fact off the label) shows "Not applicable" (decision #51, `07 §10.3`).
  Foster likewise shows **two** no-ewe targets: `'to_bottle'` is null *by intent*,
  `'removed_unknown'` null *by omission*, the rearing-credit numbers differ, and one string for both
  is the app deciding they are the same — a §12.4 violation (`07 §8.4`).

## 4. The tap budget

A tap is one pointer-down/up on a ≥60×60 pt target. Counting starts with the screen pushed and its
first frame painted — **the tap that navigated here is not counted.** Each keypad digit counts.
Scrolling is not a tap. There are no gestures at all (decision #101), so `Dismissible`, `Draggable`,
`InteractiveViewer` and `onLongPress:` are banned outright.

**CI holds exactly three budgets** (`test/features/tap_budget_test.dart`, keyed finders): unlock →
committed lambing **6**; foster reassignment from the Foster screen **1**; repeat last treatment
**2**. Every other number in `07 §3`–`§14` is a **desk estimate until the field night happens** —
label it as such, never cite it as a guarantee.

## 5. Undo and delete, per verb — this skill is the sole owner

**There is no generic `repo.undo(id)`** (decision #69). Undo is defined per verb; the table is
`07 §15.1` and you read it before touching any verb. What that table cannot say, and this skill
rules:

**The window is 120 seconds from commit, or until the route pops, whichever comes first.** Always in
seconds. Never "until the SnackBar is dismissed", never "until a widget goes away" — the widget that
definition depended on no longer exists. 120 s is `ResumePolicy.staleAfter` (`CONVENTIONS §2.14`):
past two minutes the resume policy resets the Navigator to Quick Entry, so a longer window could
never be honoured.

- **Undo is a time-boxed strike affordance in the row's own margin.** You strike; you never erase.
  No floating overlay, nothing to dismiss.
- Expiry is one `Future.delayed(const Duration(seconds: 120))` in the **screen controller**, clearing
  the marked row. Not `Timer.periodic` and not a second ticker — `minuteTickProvider` is the only
  ticker in the app (`CONVENTIONS` R25) and a minute-aligned tick cannot bound a 120 s window.
- **"Undo" is used only where the record disappears.** Foster reads **"Correct this"** — the reversal
  is a compensating `FosterEvent` whose `corrects` FK is visible forever, and `FosterEvents` is
  append-only so a delete is schema-impossible. Treatment reads **"Void this"** — a soft-void, the
  row stays struck through in the medicine book. The label is `SaveReceipt.undoLabel`, a **field**,
  not a constant; that is exactly why decision #69 refuses a generic `undo(id)`.
- **Three paths have no undo verb at all**: `correctOccurredAt` and `setStatus` correct **forward
  with both values visible**; `deleteSeason` / delete-everything / restore have already cascaded.
- **Undo does not survive process death and the UI must never imply it does** (`07 §15.4`). No state
  restoration (decision #24), no affordance reconstructed from storage, no `undoable_until` column,
  and no copy anywhere reading "you can undo this later".
- **"Cancel" is not a verb.** The row is created on screen entry, not exit (decision #11). No `Save`,
  no `Cancel`, no `isDirty`, no `commit()`; `save\w*\(` in `lib/data/` and an ARB button key starting
  with `save` both fail the build. Backing out of Lambing Entry leaves a true statement behind —
  "a lambing began for 412 at 03:24 and nothing else was recorded" — removed by the strike affordance
  or explicitly from the Ewe Card, never by a background sweep.

## 6. Routing — Navigator 1.0, one typed helper file

`lib/routing/routes.dart` is the one file that imports every feature; it is not a feature, so the
no-sibling-import rule does not apply. Contents: `02 §8.1`. Types: `CONVENTIONS §2.14`.

- **13 `RouteNames`, 12 `Routes` push helpers.** Quick Entry is `MaterialApp.home`, route 0, never
  pushed; `noteSearch` is a route but not a spec §9 screen. Checkable: names minus one equals helpers.
- `RouteSettings(name:)` exists for two reasons only — the diagnostics log and `ModalRoute.withName`
  — and **never** for `pushNamed`. No `routes:` map, no `onGenerateRoute`.
- **Banned**: `go_router` / `GoRoute` / `context.go(...)` (decision #23; CI greps `lib/`, `test/`,
  `pubspec.yaml`), `Navigator.pushNamed`, `Navigator.restorablePush`, a bottom navigation bar, and
  **navigating from a `Notifier`** — controllers have no `BuildContext`; navigate from `ref.listen`
  in the screen, or via `Routes.navigatorKey` for the two context-free callers (notification tap,
  resume policy).
- **After a write, `pop()` back to where the flow started**, not to the root.
  `Routes.popToQuickEntry` is the explicit "next ewe" action, never the default.
- **`canPop` is `true` on every screen** — every write commits immediately, so no "discard unsaved
  changes?" dialog exists. The **single** `canPop: false` is Settings' season-delete /
  delete-everything flow; CI fails on a second.
- `PopScope` uses **`onPopInvokedWithResult`**; `onPopInvoked` is deprecated and
  `flutter analyze --fatal-infos` fails on it. On a screen owning a free-text field `canPop` stays
  `true` and the 400 ms note debounce is flushed on the way out; flushing is idempotent.
- **No state restoration** (decision #24): no `RestorationMixin`, `restorationScopeId`, `Restorable*`
  or iOS restoration ID. Restoring a stale selected ewe at 3am files ewe 128's lambing against 412.
- **Backgrounded > 2 minutes → the Navigator resets to Quick Entry, nothing selected.** Under two
  minutes the stack is untouched. After process death you land on Quick Entry, empty.
- **The write happens before the route** on the lambing path: `beginLambing` returns a `LambingId`
  and **throws** — it and `addLamb` are the only two verbs that do (`CONVENTIONS` R32) — then
  `if (!context.mounted) return;` then `Routes.lambingEntry(...)`. The screen never exists without a
  row. Failure goes to `showFailure(context, shedFailureFrom(error))`; `showShedFailure` is banned
  (R30).

## 7. The end-of-day export prompt

An in-app line at the top of **Quick Entry only** — never a notification (that needs
`POST_NOTIFICATIONS`, requested only from an explicit tap), never on another screen, never mid-entry,
never blocking. **All six conditions in `07 §16.2` must hold** — open that section and check them off
one by one; a five-of-six prompt is the failure this rule exists to prevent. The two most often
dropped are the two that need a clock: first launch of a **local civil day** (civil, not UTC), and
**local time between 06:00 and 22:00**.

- `last_export_prompted_at` is stamped when the prompt **renders**, not when answered, so an
  unanswered prompt does not return the same day.
- Two ≥60 pt actions: "Export now" pushes Export and **starts no work**; "Not this season" writes
  `export_prompt_dismissed_for_season`. No third action, no close X — not answering is already free.
- Banned copy: "backup" meaning anything automatic, "sync" in any form, "your data is safe", and
  **"your data never leaves your phone"** anywhere in `lib/` or `assets/`.
- It is a real layout state: **its own overflow-matrix variant**, and Quick Entry's reachability
  assertion must pass **with it shown**.

## 8. Cross-screen layout consequences (`07 §20`)

Primary actions live in the bottom third, in a persistent ≥88 pt bottom bar plus safe-area inset on
Quick Entry, Lambing Entry, Foster and Pen Board; the top of the screen is information only. **Back
is a bottom-bar button**, not only an AppBar chevron or the system gesture. Every short pick-one flow
is a modal bottom sheet; **its close control and its three typed-out Flutter defaults are
`indelible-controls`'** — build the sheet from there, because `07 §20`'s "72 pt Cancel" and
Indelible §7.14's `CLOSE` button are not the same control and the design system wins.
`showDialog(` is allowlisted to the two destructive Settings files and banned elsewhere in
`lib/features/**`. Row heights and the gap between targets are
**indelible-page-and-screens**' — and the separation figure is **P9, still open**, so do not quote a
number from here into a widget or a test. No screen shows success before its transaction returns
(decision #103).

## 9. Adding a screen — nine files, in this order

1. `lib/routing/routes.dart` — a `RouteNames` entry **and** a typed push helper. First, because the
   13/12 count invariant is the cheapest thing to get wrong.
2. `lib/features/<f>/<screen>_controller.dart` — screen state and the **one** read provider. No
   `BuildContext`, no navigation, no formatting, no drift import, no draft.
3. `lib/features/<f>/<feature>_write_controller.dart` — `NotifierProvider.autoDispose`, **always**
   auto-dispose; every mutation through `WriteController.guard()` (the double-tap defence).
4. `lib/features/<f>/<screen>_screen.dart` (+ `widgets/`) — tokens via `context.tokens`, shared
   controls from `lib/core/ui/components/`, every interactive element ≥60×60 pt with a
   `semanticLabel` and a key spelled `<screen>.<element>[.<qualifier>]`, all `lower_snake`
   (`CONVENTIONS §4.5`). A key is a test contract; renaming one is a breaking change.
5. `lib/l10n/app_en.arb` — every user-facing string with a `description`. No domain noun appears
   literally; the term is a placeholder fed by `terminologyProvider`.
6. `test/features/<f>_test.dart` — through `pumpApp` against
   `DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true)`; omit that flag and
   every stream-touching test fails with a pending-timer error. Start tap-target runs with
   `final handle = tester.ensureSemantics(); addTearDown(handle.dispose);` or the guideline throws
   instead of checking. One `tester.tap(); tester.tap();` per committing action.
7. `test/features/overflow_matrix_test.dart` — **+1 pumpable variant**, then recompute the cell count
   from the variant list rather than editing a number. The arithmetic, the single place the count is
   written down and the self-check that enforces it belong to **shed-testing** (R58) — go there
   before touching the matrix, and never carry a remembered total into a diff.
8. `07-screens.md §2.2` — the empty-state row: copy plus the single action.
9. `07-screens.md §1.5` — the §12 disclosure row, including which disclosures do *not* appear and
   why. A screen with no "§12 on this screen" section is not finished.

Then **load `indelible-page-and-screens`** for how the screen is drawn. Do not attempt the visual
design from this skill.

## 10. Open conflict — P3, the navigation model

Unruled. Both sides, so nobody silently picks one:

- `02-state-di-navigation.md §8` ships a `Navigator` 1.0 stack, 13 `RouteNames`, 12 typed push
  helpers, a back behaviour and a 2-minute resume reset — and `CONVENTIONS §2.14` binds those names.
- `docs/design/indelible.md §7.17`: *"There is no tab bar, no rail, no stack, and no back button —
  pressing `INDEX` and choosing another filter is always one press deeper, never one press back."*

**Meanwhile build §6 as written**, because `CONVENTIONS` is BINDING on the type names and a skill may
not overrule it. Keep every back affordance a labelled bottom-bar control so the INDEX model can be
adopted without re-cutting the stack. **Escalate to the owner before** adding an index sheet,
removing a back affordance, or changing the push-helper count.

## Definition of done

- [ ] One content statement per screen; no displayed value from two drift streams; no `combineLatest`;
      every aggregate a `customSelect` with `readsFrom:`.
- [ ] All six states implemented or declared impossible with a reason; no spinner in any state; Empty
      uses `07 §2.2` copy and offers exactly one action — the populated screen's own control.
- [ ] Undo is per verb per `07 §15.1`; no `undo(id)`; the window is **120 seconds or the route pop,
      whichever is first**, as a `Duration` in the screen controller; the label reads "Undo" only
      where the row disappears, "Correct this" on foster, "Void this" on treatment.
- [ ] No undo affordance is rebuilt after process death; no `showSnackBar(` anywhere; no `Save`,
      `Cancel` or `isDirty`; no birth-type chooser, and the 6-tap budget's last tap is a tally stroke.
- [ ] `RouteNames` minus one equals `Routes` push helpers; no `pushNamed`, `onGenerateRoute`,
      `go_router` or `restorationScopeId`; exactly one `canPop: false` in `lib/`; every `PopScope`
      uses `onPopInvokedWithResult`.
- [ ] The three CI tap budgets pass (6 / 1 / 2); every other tap number is labelled a desk estimate.
- [ ] Matrix cells equal `variants × 3 × 3 × 2`; reachability holds at 375×667 × textScaler 1.3 with
      the export prompt shown; `no_monetization_test.dart` passes on all five shed screens at
      `unlocked: false, ewesInCurrentSeason: 99`; the Flock row does not render 22:00–06:00.
- [ ] The export prompt fires only when all six `07 §16.2` conditions hold and stamps
      `last_export_prompted_at` on render.
- [ ] The screen has a "§12 on this screen" section and every rendered event time carries its
      `RecordedTime.provenanceLabel`.
- [ ] `tool/check_policy.dart` and `flutter analyze --fatal-infos` pass, and
      `indelible-page-and-screens` was loaded before any visual work began.

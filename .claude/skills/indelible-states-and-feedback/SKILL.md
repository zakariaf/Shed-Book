---
name: indelible-states-and-feedback
description: >-
  What a page shows when there is no record, a write returns, or the app must speak about itself. Use
  whenever an empty state, first frame, error, confirmation, receipt, banner, prompt, spinner, toast,
  snackbar or modal is proposed. Do NOT use for whether the write succeeded (shed-write-path).
---

# States and feedback — what the page says about itself

Owns every moment the app is not simply printing a record: the first painted frame, empty and
filtered-empty, the error panel, **the save confirmation**, the once-a-day export prompt, the two
static upgrade rows, the unset-cell gap. These are `06 §12`'s `ShedReceiptBar`, `ShedBanner` and
`ShedEmptyState`. Sources — cite, never copy: `docs/design/indelible.md` §1.3, §5.2, §7.3, §7.11, §8
(screens 3, 11), §9; `docs/engineering/07-screens.md` §1.4, §2.2, §16;
`docs/engineering/06-design-system.md` §9, §10, §12; `docs/engineering/11-monetization-and-store.md`
§8; `docs/engineering/CONVENTIONS.md` §2.11 + R30/R31, BINDING on every name and signature.

**Do NOT use for:** whether a write succeeded, `WriteOutcome`, repository verbs — **shed-write-path**.
Entitlement rules, price, cap copy — **shed-monetization**. Undo's per-verb window and which states a
screen must implement — **shed-screens-and-routing**. The strike mark, `STRUCK`, the query `?` —
**indelible-marks-and-strikes**.

## 0. Ruling P2 — there is no SnackBar. Read first.

`showSnackBar(` is banned **everywhere, including `lib/core/ui/feedback.dart`**: widen the
`gesture.raw_snackbar` row in `tool/check_policy.dart` from `lib/features/` to `lib/`, with **no
allowlist entry**. This supersedes `CONVENTIONS §2.11`'s "the one file permitted to call
`showSnackBar(`" and `06 §10.3`'s persistent-SnackBar channel; indelible §9 bans toasts, snackbars
and modal dialogs outright.

**The receipt is the committed row itself** — in ink, one line above the one being written. The
confirmation is that the row is *there*, not that something floated over it.

- `feedback.dart` becomes the **printed-receipt channel**. `confirmSaved`, `showFailure`, `showCapRow`
  keep their names, file and exact signatures (R30) and `SaveReceipt` keeps its shape (R31); **only
  what they render changes.** `showShedReceipt` / `showShedFailure` remain banned spellings. A
  feedback function holds a `BuildContext` and nothing else — no `WidgetRef`, no provider read, no
  navigation.
- `SaveReceipt.undo` renders as a **time-boxed strike affordance in the committed row's own margin**.
  You strike; you never erase. Nothing floats, so nothing must be dismissed. State the window **in
  seconds** — 120 s or the route pop, whichever is first (owned by **shed-screens-and-routing**);
  "until the SnackBar is dismissed" is the wording that made undo unimplementable.
- `SaveReceipt.undoLabel` is a field, not a constant: "Undo" only where the row disappears, "Correct
  this" on a foster, "Void this" on a treatment (`07 §15.3`).
- `ShedReceiptBar` stays in `lib/core/ui/components/shed_receipt.dart` as **the row's receipt
  affordance** — the margin strike target (≥ `tapHero`, never below `tapMin`) plus the live-region
  node. It inherits no framework wrapping, so it carries its own semantics
  (**shed-accessibility-and-copy** owns that half) and is never swipe-dismissible.

## 1. The save confirmation

Order is fixed and never optimistic (`06 §10.3`, decision #103): **tap → write → await the
transaction → then change the UI.** A local SQLite write is single-digit milliseconds; a false
receipt is worse than no receipt. Three redundant channels, all still required:

1. **Haptic.** `confirmSaved` fires `successNotification()` on an empty `warnings` list,
   `warningNotification()` on a non-empty one (`06 §10.1`) — when the transaction **returned**, never
   on the tap. `HapticFeedback.vibrate()` is banned; on Android it is a long buzz.
2. **The printed row**, above the live row, its time already inked in the margin. It fades in over
   `--motion-ink` 120 ms — **opacity only, zero translation**, 0 ms under reduce-motion. Numbers never
   count up; rows never reorder, slide or crossfade.
3. **The state change in the underlying list** — the ewe rises in the recents, her card gains today's
   event. The only channel still true five seconds later, and the only one proving the *database*
   changed rather than a widget having been shown.

`showFailure` prints one ruled line where the row would have gone, with a `†` in the margin:
`failure.userMessage` verbatim (one of six `ShedFailure` strings, `01 §5.1`), `errorNotification()`
haptic, **never a dialog, never the exception text, never a code, never composed copy.** The
free-tier cap fires **no haptic at all** — both gated actions are calm-UI and a buzz turns a calm gate
into a rebuke.

## 2. The first painted frame

**The first painted frame is `--page` with tonight's page already on it** (indelible §5.2, §9;
`06 §9`). No splash, no logo, no fade-in, no white flash, on either platform — verified by eye on a
cold launch in a dark room and by indelible §11 test 9 (240 fps).

- Frame 1 is a **fixed-height placeholder in the same surface colour**, never a spinner, with **zero
  layout shift** when data lands (`07 §1.4`, decision #21). `CircularProgressIndicator` fails
  `tool/check_policy.dart` (`ui.spinner`): loading is a fixed-height placeholder or it is nothing.
- At frame 1 the keypad is fully interactive, the live row is drawn, the auto-captured time is inked.
  Nothing is awaited, so there is nothing to indicate.
- No minimum splash duration, and **never `flutter_native_splash`** — it would own the native files as
  a second source of truth. The four native layers and the `launch.colour_parity` gate are
  `06 §9.1`–`§9.4`; read them before touching `android/` or `ios/`. **No `values-night/` folder** — a
  phone in light mode would launch white.

**P14 is OPEN — do not silently resolve it.** `NightErrorPanel` hard-codes `#0B0D0E`
(`CONVENTIONS §2.11`, BINDING) and `06`'s DoD says no frame is brighter than `#0B0D0E`, but
Indelible's `--page` is `#0A0A0B`. Interim: **keep both literals exactly as written.** The handoff
`#0B0D0E` → `#0A0A0B` only ever goes darker, which is the invariant that matters at 3am, and both
pass "frame one is not white". The live defect: `launch.colour_parity` asserts `colors.xml` **equals**
the palette hex, which cannot hold while the two differ — it must compare "not brighter than", or one
hex must move. **Escalate before changing either literal or that assertion.**

## 3. Empty and filtered-empty

`ShedEmptyState` **occupies the same box the populated content will**, prints one line of record copy
at ≥18 px, and offers **exactly one action — the same control the populated screen uses**
(decision #71). No illustration, no spinner, no tour, no sample flock, no onboarding: the empty states
*are* the onboarding.

- **Use `07 §2.2`'s copy verbatim**; never invent a string. Note search needs its **three distinct
  strings** (no query yet / no notes exist at all / no notes match this) — the wrong one makes a
  shepherd conclude the app lost their notes.
- **Filtered-empty is a different string from Empty**, action "Clear filters". A filter change
  **re-prints the page instantly**, no crossfade: at 3am a crossfade reads as lag and lag reads as
  "it didn't save".
- Never-empty screens are Quick Entry, Lambing Entry, Lamb Card, Settings — the row exists before the
  screen does. Write "impossible, because…"; silence is not an answer.
- **A zero row is a dotted rule, never a blank line** (§7.11): blank reads as missing data, dotted
  reads as *nothing happened*, and those are different facts. Zero day prints a dotted rule and `0`;
  an empty season prints fourteen dotted rows and `NO LAMBINGS RECORDED IN THIS SEASON`.

## 4. The unset cell — a visible gap, never a hidden field

Where a value would be: a **2 px dotted `--rule`, 40 px long, with a caps label above it** (§7.3).
Never hide, collapse, grey out or auto-fill an unset cell, and never nag. The section footer prints
`EVERY CELL BELOW MAY BE LEFT BLANK. A BLANK CELL PRINTS AS A GAP, NOT AS AN ERROR.`

- **There is never placeholder text inside a field** (§7.12): in the dark a grey placeholder is
  indistinguishable from an entered value, and in the withdrawal-days cell a placeholder number is a
  food-chain risk (safety rule 1). Hints live in the label, above the line.
- `ShedCountdown`'s "not recorded" is a first-class state — **never `0`, never blank** (`06 §12`).
- **The 18 px floor.** A 14 px caps stamp is permitted only when all three of §3.4's conditions hold,
  and the third is that **no stamp is ever the sole carrier of its meaning**. `AUTO-CAPTURED` fails it
  — it is the sole §12.5 provenance label on the row — so **the provenance stamp prints at ≥18 px**,
  worded from `RecordedTime.provenanceLabel` (exhaustive switch, never re-typed). `DEAD` and
  `DERIVED FROM n STROKES` fail the same test (**indelible-controls**, **indelible-marks-and-strikes**).
  `NOT RECORDED · SKIPPABLE` still passes at 14 px **because the dotted gap carries the same fact** —
  remove the dotted rule and the label must go to 18 px too.

## 5. The error panel — two surfaces, never conflated

- **A read threw** (`07 §1.4`, decision #13): the screen's own **Error state** — dark panel, one 18 pt
  line naming what could not be read, a 60 pt **Try again**, a 60 pt **Diagnostics**.
- **A build threw**: `NightErrorPanel` (`lib/core/ui/night_error_panel.dart`), `ErrorWidget.builder`,
  full screen, hard-coded hexes, its own `Directionality`, **no `Theme`, no `MediaQuery`, no
  `TextTheme`** — it may be invoked with none in scope. One line of near-white text, the route name,
  one action: *"Save a copy of my records"*. It holds the single raw-colour exemption,
  `lib/core/ui/night_error_panel.dart :: token.raw_color` in `tool/policy_allowlist.txt`.

Both: **never the exception message** (decision #124), no stack trace, no error code, never
red-on-yellow (decision #14 — the default `ErrorWidget` is a flashbang under a head torch), never a
modal.

## 6. The once-a-day export prompt

**A printed line at the foot of tonight's page**, once a local civil day, dismissible for the season
(§8 screen 11, §9). Never a modal, notification, toast, blocking surface or mid-entry interruption.
`07 §16.2`'s "slot above the tag readout" is that same slot in the old layout — do **not** add a top
banner, and never let the prompt displace or overlap the live row, which is a fixed layer above the
band and cannot be pushed or scrolled away.

- All six `07 §16.2` conditions must hold. The two most often dropped: **local time 06:00–22:00**
  (against `appNow()`) and **first launch of a local civil day** — civil, not UTC.
  `app_settings.last_export_prompted_at` is written when the prompt **renders**, not when answered, so
  an ignored prompt does not return the same day.
- Wording is `07 §16.3` verbatim; both actions ≥60 pt; **no third "later" and no close X** — not
  answering is already free. "Export now" navigates and **starts no work**. Banned wording: "backup"
  meaning anything automatic, "sync" in any form, "your data is safe", any implication the app
  protects records by itself. Export's own required line stays in full ink, never a dismissible tip:
  `A LOST PHONE IS LOST DATA. THERE IS NO CLOUD COPY.`
- It is a real layout state: its own variant in the overflow matrix, and reachability must pass **with
  it shown** (`07 §16.4`).

## 7. The two static upgrade rows

Exactly two surfaces — pinned top of **Flock**, and **Settings ▸ Unlock** (`07 §19.2`, `11 §8`).
Nothing monetization-related renders anywhere else, at any entitlement state, ever.

- **Always present, in the same pixels at 0 ewes as at 22.** No badge, no accent, no colour change to
  red, no modal, no interstitial, no self-appearing sheet, no timed prompt, no haptic.
- **Neither renders 22:00–06:00**, on any screen, at any ewe count: `06 §12` constraint 3 is wider
  than `07 §19.3` and is the one that ships, and the widget test **sets the clock, not the
  entitlement**. Settings ▸ Unlock still works at 23:00 — what is suppressed is soliciting, not
  selling.
- `ShedBanner` renders as **a ruled row in the page's own ruling**: control face, `textSecondary` on
  `surfaceRaised`, 2 px rule, ≥ `tapHero` tall, two ≥ `tapMin` actions on their own line. No fill, no
  radius, no shadow, no elevation, no scrim, no drag handle, no auto-dismiss. If `showCapRow` is
  implemented through `ScaffoldMessenger.showMaterialBanner`, style it until it is indistinguishable
  from a printed row — indelible §1.3 has no cards and no containers.
- The price is `ProductDetails.price`, never a literal; per-`RefusalReason` copy is
  **shed-monetization**'s.

## 8. Never, and why

No spinner or skeleton (`ui.spinner`) — a wait you cannot shorten is a wait you should not draw. No
empty-state illustration. No modal dialog (`ui.show_dialog` allowlists exactly two destructive
files). No surface that appears by itself on a shed screen. No badge count, rating prompt, what's-new,
tour or notification-permission nag. No auto-dismiss, no swipe-to-dismiss (`Dismissible` is banned).
No count-up numbers, growing bars or row crossfades. No sound (`06 §10.2`). No optimistic UI.

## Definition of done

- [ ] `showSnackBar(` appears nowhere in `lib/`, including `feedback.dart`; `gesture.raw_snackbar`
      covers `lib/` with no allowlist entry and exits non-zero on a seeded violation.
- [ ] `feedback.dart` holds `confirmSaved`, `showFailure`, `showCapRow`, `SaveReceipt` at R30/R31
      signatures; none takes a `WidgetRef`, reads a provider or navigates.
- [ ] The receipt is the committed row; undo is a margin strike affordance with its window stated in
      seconds; no floating surface exists to dismiss and none is rebuilt after process death.
- [ ] The success haptic fires after the transaction returns, warnings swap it for the warning haptic,
      the cap path fires none, `HapticFeedback.vibrate()` is absent, and no screen shows a committed
      fact before the write returns.
- [ ] Cold launch on both platforms in a dark room: no frame brighter than `#0B0D0E`, no white, logo
      or fade; frame 1 is fixed-height placeholders and nothing shifts when data lands.
- [ ] P14 is still recorded open or the owner has ruled — nobody has quietly edited `#0B0D0E`,
      `#0A0A0B` or the `launch.colour_parity` assertion.
- [ ] Empty and Filtered-empty use `07 §2.2` copy verbatim, occupy the populated box, offer one
      action; note search ships three distinct strings; zero rows print a dotted rule, never a blank.
- [ ] Every unset cell prints its dotted rule and label; zero hits for placeholder text in a field;
      `ShedCountdown` never renders `0` for "not recorded"; the provenance stamp measures ≥18 px.
- [ ] The Error state offers Try again + Diagnostics and never the exception text; `NightErrorPanel`
      reads no `Theme`/`MediaQuery` and carries the single raw-colour allowlist line.
- [ ] The export prompt fires only when all six `07 §16.2` conditions hold, stamps
      `last_export_prompted_at` on render, prints at the foot of tonight's page without moving the
      live row, and reachability passes with it shown.
- [ ] The upgrade rows render on exactly two screens, identically at 0 and 22 ewes, with no accent or
      badge; a widget test with the clock at 23:30 renders neither.

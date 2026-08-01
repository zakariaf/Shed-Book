# 10 — Accessibility and internationalisation

This document governs everything the app does about assistive technology, platform accessibility settings, text scale, colour redundancy, motor reach, and localisation. It is written for the developer building the widgets: every rule here is either a line you type in a widget, a row in `tool/check_policy.dart`, or a pass in the release sweep. The framing that makes it worth reading is not compliance — **the 3am shepherd already is the low-vision, low-dexterity, one-handed, cognitively-loaded user**, so this document and `06-design-system.md` are describing the same person from two directions. `06-design-system.md` owns `lib/core/ui/**` (tokens, palettes, type, tap geometry, components, feedback); this document owns what those components must say to the semantics tree and what strings they may contain. Where the two touch, 06 owns the pixel and this document owns the label.

> **Decisions applied:** #99 (never clamp text scale; `textScaleFactor` banned) · #100 (60×60 pt tap floor, two gates) · #101 (the gesture ban) · #103 ("saved" is commit-then-confirm through a `liveRegion` with a unique label, never `SemanticsService.announce`) · #104 (`headingLevel: 1..6`; `header:` banned) · #105 (one reduce-motion resolver ORing the Android-only and iOS-only flags) · #106 (colour is never the only channel) · #107 (Apple's Accessibility Nutrition Labels are the ship gate; WCAG 2.2 AA via WCAG2ICT, skipping 2.4.1 / 2.4.5 / 3.2.3 / 3.2.4) · #108 (`flutter_localizations` + gen-l10n/ARB from day one, shipping `en` only; `intl: any`; bare `Locale('en')` first; never an all-numeric human date) · #61 (terminology is a user-owned overlay; no domain noun in any ARB message) · #95/#96 (the high-contrast slot is a real palette; both night-shift palettes ship, labelled honestly) · #98 (w700 weight cap) · #70 (hand-rolled chart with `semanticsBuilder`) · #57 (the keypad is the only numeric entry route) · #115 (`tester.ensureSemantics()` before every `meetsGuideline`) · #10 (one source-scanning gate) · #114 as amended by **CONVENTIONS R58** (252 cells over 14 pumpable variants). Owner rulings §7.0: tag OCR and voice tag entry **cut from v1** (the voice *note* ships); tags unique among **active** animals only; **UK/Ireland first** — `en_GB`, kg, °C, 24-hour, week starts Monday, ambiguous DST hour 01:00–01:59, AHDB percentage convention; the free tier never surfaces mid-entry and never between 22:00 and 06:00.

---

## 1. What binds, what does not, and why you are doing this anyway

### 1.1 Apple's Accessibility Nutrition Labels are the ship gate

App Store Connect's Accessibility Nutrition Labels are voluntary "to start" and then required to submit new apps and updates. They are the gate because they are the only accessibility statement this product will ever be *asked* for, and because the bar Apple sets is behavioural rather than technical:

> "To indicate support for an accessibility feature in the Accessibility Nutrition Labels, users must be able to complete **all of the common tasks** of your app using that feature."

Apple defines common tasks as primary functionality + first launch + login + purchase + settings. Shed Book has no login, so the list is fixed at seven:

**first run · unlock/restore purchase · Quick Entry · Lambing Entry · Pen Board · Treatments · Settings.**

Every one of those seven must be completable with VoiceOver only, and with Voice Control only, before a label is declared. §7 turns that into a checklist.

### 1.2 WCAG 2.2 AA, through WCAG2ICT

WCAG is written for web content; [WCAG2ICT](https://www.w3.org/TR/wcag2ict/) (W3C Group Note, 11 Dec 2025) is the only primary-source mapping onto native software. Target **AA**, and skip **2.4.1 Bypass Blocks, 2.4.5 Multiple Ways, 3.2.3 Consistent Navigation, 3.2.4 Consistent Identification** — regulators exclude them for software.

The criteria that actually bite, and where:

| SC | Level | Where it bites Shed Book | Section |
|---|---|---|---|
| 1.4.1 Use of Color | A | Pen tile status, withdrawal countdown, lamb alive/dead, warning badge | §5 |
| 1.4.3 Contrast (Minimum) | AA | Every palette, measured not eyeballed | `06-design-system.md` §3.5 |
| 1.4.4 Resize Text | AA | Pen board, keypad, Ewe Card at 200% | §4 |
| 1.4.10 Reflow | AA | The pen board must stop being a grid | §3.5 |
| 1.4.11 Non-text Contrast | AA | Tile outlines, status glyphs, key edges, chart bars | §5.3 |
| 1.4.12 Text Spacing | AA | Not readable as a flag on mobile — satisfied by design | §4.5 |
| 2.5.1 Pointer Gestures | A | The gesture ban | §6.2 |
| 2.5.7 Dragging Movements | A | "Move to pen" is two taps, never a drag | §6.2 |
| 2.5.8 Target Size (Minimum) | AA | Trivially met — the floor is 60 pt | §6.1 |
| 4.1.2 Name, Role, Value | A | Every hand-built tap surface | §3 |
| 4.1.3 Status Messages | AA | The save receipt | §3.8 |

### 1.3 The European Accessibility Act does not apply — say so once and move on

The EAA covers a **closed list**: computers and OSes, ATMs and ticketing machines, smartphones, TV equipment, telephony, audio-visual media services, passenger transport, banking, e-books, e-commerce. A one-time-purchase farm notebook is not on it. Ireland is in scope as a jurisdiction; the UK is not, and is governed by the Equality Act 2010's general service-provision duties. Neither creates a mobile-app conformance obligation for this product.

**Do not produce a VPAT. Do not claim EN 301 549 conformance.** Nothing legally forces this work. The week that a VPAT would cost is better spent on the per-screen sweep in §7.2, which is the thing that actually changes whether a shepherd can use the app.

### 1.4 The framing, because it changes what you build

At 03:20 the user is functionally low-vision (head torch, reading glasses in the house), low-dexterity (cold, one thumb, gloves or a freezer bag), cognitively loaded (night eleven, holding a lamb), in a lighting environment that swings from pitch dark to an 800-lumen spot and back. Every accommodation in this document is load-bearing for that user *before* it is load-bearing for anyone with a permanent disability. Write it that way in code comments too: a comment that says "for screen-reader users" invites a future contributor to weigh it against a deadline. A comment that says "this is the string that makes the tile readable at arm's length **and** the string TalkBack speaks" does not.

---

## 2. The platform flag truth table

### 2.1 What each platform actually sets

`dart:ui`'s `AccessibilityFeatures` is a bitfield; the two shells populate different subsets of it, and **the difference is not documented anywhere a developer will trip over it**. This table was read out of the Flutter 3.44 stable tree (`engine/src/flutter/lib/ui/window.dart`, `.../darwin/ios/.../AccessibilityFeatures.swift`, `.../android/io/flutter/view/AccessibilityBridge.java`).

**The toolchain this document is written against is decision-record §2.A #1: Flutter 3.44.8 stable, Dart 3.12.2, pinned via FVM.** The engine files above were read on a 3.44 stable checkout; §5's SDK pins are identical across 3.44.x, so nothing in this table is version-sensitive *within* 3.44. Every one of these rows is re-checked on any minor bump, because a shell-side flag is exactly the kind of thing that changes without a breaking-change page.

| Flutter flag | iOS source | Android source | Set on iOS | Set on Android |
|---|---|---|---|---|
| `accessibleNavigation` | `isVoiceOverRunning` **OR** `isSwitchControlRunning` | touch exploration (TalkBack) | ✅ | ✅ |
| `boldText` | `isBoldTextEnabled` | API 31+ `fontWeightAdjustment >= 300` | ✅ | ✅ (API 31+ only) |
| `disableAnimations` | — | `TRANSITION_ANIMATION_SCALE == 0` | ❌ **never** | ✅ |
| `reduceMotion` | `isReduceMotionEnabled` | — | ✅ | ❌ (`// NOT SUPPORTED`) |
| `highContrast` | `isDarkerSystemColorsEnabled` (Increase Contrast) | — | ✅ | ❌ |
| `invertColors` | `isInvertColorsEnabled` | — | ✅ | ❌ |
| `onOffSwitchLabels` | `isOnOffSwitchLabelsEnabled` | — | ✅ | ❌ |
| `noAnnounce` | not set ⇒ `supportsAnnounce == true` | set **unconditionally** ⇒ `supportsAnnounce == false` | — | ✅ |
| `noAutoPlayAnimatedImages`, `noAutoPlayVideos`, `deterministicCursor` | iOS only (added in 3.44 by PR #178102) | — | ✅ | ❌ |
| *Reduced Transparency* | **not exposed by Flutter at all** | — | — | — |

Two consequences you must code around, both of which contradict advice you will find elsewhere:

1. **There is no cross-platform reduce-motion flag, and `MediaQueryData` has no `reduceMotion` property.** Reading one flag gets you the wrong answer on exactly one platform, silently.
2. **`accessibleNavigation` is not "a screen reader is running."** On iOS it is also true for Switch Control users, who are sighted.

### 2.2 What Shed Book does when each flag is set

A flag the app ignores is a row that says so. "Ignored" is a decision, not an omission.

| Flag | Where the user turns it on | Shed Book's response |
|---|---|---|
| `boldText` | iOS: Settings ▸ Accessibility ▸ Display & Text Size ▸ Bold Text. Android 12+: Settings ▸ Display ▸ Bold text | **Nothing manual.** `Text` merges `FontWeight.bold` (w700) itself. Our w700 cap (§4.6) is the whole response — it is what stops the merge making the heaviest text *lighter*. It is a variant of the overflow matrix, not a code branch. |
| `disableAnimations` (Android) / `reduceMotion` (iOS) | Android: Developer/Accessibility transition scale 0. iOS: Accessibility ▸ Motion ▸ Reduce Motion | `prefersReducedMotion(context)` ORs both and feeds `ShedTokens.motion` (§2.3). Then: route transitions become `Duration.zero` cross-fades; the receipt appears without a slide; the pen tile re-renders on the minute tick without animating; no shimmer; no pulsing overdue badge; theme swaps are already `Duration.zero`. |
| `highContrast` | iOS: Accessibility ▸ Display & Text Size ▸ Increase Contrast. **Android: nowhere** | Selects `MaterialApp.highContrastTheme` / `highContrastDarkTheme`, which hold a genuinely different, higher-contrast palette (decision #95). Because Android never fires it, the same palette is also a Settings switch labelled `High contrast` (CONVENTIONS R35). **Never gate a semantics label or a shape on it** — the redundancy in §5 is unconditional. |
| `accessibleNavigation` | VoiceOver / Switch Control / TalkBack | **Timing only.** Nothing auto-dismisses, nothing steals focus, nothing auto-advances — which is already true unconditionally, so the app reads this flag in exactly zero places. It is listed here so a future contributor knows the omission is deliberate. **Branching layout on it is banned in review.** |
| `invertColors` | iOS Smart/Classic Invert | **Ignored, deliberately.** Flutter exposes no `accessibilityIgnoresInvertColors`, so photos of lambs *will* invert under Classic Invert and we cannot opt out. The mitigation is a design rule, not code: a photo is never the sole carrier of meaning (`06-design-system.md` §4.7). One manual pass under Smart Invert per release (§7.2 row 6b). |
| `onOffSwitchLabels` | iOS: Accessibility ▸ Display & Text Size ▸ On/Off Labels | **Free.** The two Material `Switch`es in the app (`High contrast` — CONVENTIONS R35 — and `Keep screen on` — `07-screens.md` §14) render the I/O glyphs themselves. No code. |
| `supportsAnnounce` | derived; **false on Android, always** | Gates `SemanticsService.sendAnnouncement`. The app calls it **nowhere** — see §3.8 — so the flag is read nowhere and the gate row `a11y.announce` proves it stays that way. |
| `noAutoPlayAnimatedImages` / `noAutoPlayVideos` / `deterministicCursor` | iOS 18+ | **N/A.** The app plays no animated images and no video, and the only editable text is a note field, where `deterministicCursor` is honoured by `EditableText` for free. |
| `textScaler` | OS text-size slider (iOS AX1–AX5, Android up to 200%) | **Never touched.** §4. |
| `alwaysUse24HourFormat` | OS clock setting | **Read nowhere.** Times are 24-hour `HH:mm` unconditionally (§9.4) — the one place the app deliberately overrides a system preference, with its reason stated. |
| *Reduced Transparency* | iOS — no Flutter API | **Designed around.** No `BackdropFilter`, no frosted app bar, no scrim over text, anywhere. You cannot honour a preference you cannot read, so do not create the problem. Already a `06-design-system.md` §2.5 ban. |

### 2.3 The reduce-motion resolver — one function, one file

`06-design-system.md` §2.5 owns the file; this is the contract it satisfies. There is exactly one of these in the app.

```dart
// lib/core/ui/motion.dart
/// The only correct cross-platform reduce-motion check on Flutter 3.44.
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

**Anti-pattern:** reading only `MediaQuery.disableAnimationsOf`. You test on an iPhone with Reduce Motion on, see no change, conclude the API is broken, and ship un-reduced motion to the platform where the setting exists. There is no gate for this — it is a review item and a two-branch unit test:

```dart
// test/design/reduce_motion_test.dart — both branches, because each platform
// only ever exercises one of them.
testWidgets('android flag alone reduces motion', (tester) async { … });
testWidgets('ios flag alone reduces motion', (tester) async { … });
```

---

## 3. Semantics

### 3.1 What you get free, and what you do not

Free: `ElevatedButton`/`TextButton`/`IconButton` (button role + label from the child `Text`), `TextField` (`textField` + `value` + `hint`), routes (`scopesRoute`/`namesRoute`), `SnackBar` (wrapped in `Semantics(container: true, liveRegion: true)`), and `Text`, which applies `MediaQuery.boldTextOf` and `MediaQuery.textScalerOf` itself.

Nothing: `Container`, `GestureDetector` without semantic callbacks, `CustomPaint` without `semanticsBuilder`, `Icon` without `semanticLabel`, and every bespoke tap surface. **That list is a description of this app.** The pen board, the keypad, the pen tile, the recents strip, the ease row and the chart are all hand-built, which is why `ShedTapTarget` takes a `required String semanticLabel` and sets `Semantics(onTap:)` (`06-design-system.md` §6.2) — an unlabelled node is an unnamed stop in a Switch Control scan, and a button node with no tap *action* announces correctly and then refuses to activate.

### 3.2 Label rules

Apple's VoiceOver and Voice Control criteria, restated as house rules. Every one of these is a review item.

1. **Never put the control type in the label.** `'Turn out'`, never `'Turn out button'` — Flutter emits the role.
2. **Never put state in the label.** Use `selected:` / `enabled:` / `checked:`, never `label: 'Pen 4, selected'`.
3. **The label matches the visible text.** This is the Voice Control criterion: if the control reads *Turn out* and the label is *Release from pen*, "Show names" displays the wrong words and "tap turn out" does nothing.
4. **Labels survive out of order.** No "Tap here", no "More", no "This".
5. **Concise.** `'New lambing'`, not `'Press to record a new lambing event'`. At 3am a chatty screen reader is worse than a terse one.
6. **`hint` / `onTapHint` is for a non-obvious outcome only**, and it is spoken after a pause.
7. **Decorative glyphs get `ExcludeSemantics`**, never an empty label.
8. **The label uses the user's noun**, from `terminologyProvider`, never a hard-coded "ewe" (§8.5).

### 3.3 Tag numbers are spelled out, and only the tag

Ewe **412** is "four one two" — that is what is printed on the tag and what the shepherd says. A screen reader reading "four hundred and twelve" is reading a number that appears nowhere in the shed.

There is **one** helper, used by every node that speaks a tag. It is a new name, declared here under CONVENTIONS §4.1. It is a top-level function, not a widget, so it sits **beside** `motion.dart` and `formatters.dart` in `lib/core/ui/` rather than inside `components/` — CONVENTIONS §4.1 reserves `lib/core/ui/components/` for `shed_<thing>.dart` files, and a file called `components/tag_semantics.dart` would be the first exception to a rule with no exceptions.

```dart
// lib/core/ui/tag_semantics.dart
/// Spells the TAG range only, wherever it sits in the sentence. Never the term:
/// "gimmer, four one two", not "g-i-m-m-e-r". (§8.5)
/// Returns a plain AttributedString when `tag` is null or absent from `text`,
/// so a caller never has to branch.
AttributedString spellOutTag(String text, String? tag) {
  final int start = tag == null ? -1 : text.indexOf(tag);
  if (start < 0) return AttributedString(text);
  return AttributedString(
    text,
    attributes: <StringAttribute>[
      SpellOutStringAttribute(range: TextRange(start: start, end: start + tag!.length)),
    ],
  );
}
```

Use it through `attributedLabel:`, never `label:`. Unit-test it against the pen-tile sentence, a bare `'gimmer 412'`, a tag that is also a substring of the term, and a null tag — an off-by-one here spells out half the sentence and nobody notices without a device.

### 3.4 Headings — `headingLevel` only

**`Semantics(header: true)` is a no-op on both iOS and Android as of 3.44.** It still compiles and it still reads correctly in review, so it is the single most likely accessibility regression in this codebase. `headingLevel` greater than 0 maps to `View.setHeading(true)` on Android and `UIAccessibilityTraitHeader` / `accessibilityHeadingLevel` on iOS.

```dart
// WRONG on 3.44 — compiles, passes review, does nothing on either platform.
Semantics(header: true, child: Text(l10n.inThePens))

// RIGHT
Semantics(headingLevel: 2, child: Text(l10n.inThePens))
```

Gated by the existing `a11y.header_bool` row (`header: true` under `lib/`) plus a per-screen widget test asserting at least one node with `headingLevel > 0`. `ShedSectionHeading` emits `headingLevel: 2`; screen titles emit `1` (`06-design-system.md` §12).

Why it matters more here than in a normal app: spec §7.7 makes the Ewe Card the retention feature, and its one-line summary — *"3 seasons · avg 2.0 · assisted twice · prolapsed 2025"* — is meant to be seen **before anything else**. For a sighted user that is a glance. For a VoiceOver user the only equivalent is the rotor set to Headings and one flick. Without `headingLevel`, that user swipes through every field on the card and the retention feature is gone.

The hierarchy below is derived from `07-screens.md`'s per-screen structure and may not invent a section that screen does not render. Where 07 names the words, they are 07's words verbatim — that is the Voice Control criterion (§3.2 rule 3).

| Screen | `headingLevel: 1` | `headingLevel: 2` |
|---|---|---|
| Ewe Card | the user's term + tag ("gimmer 412") | Summary · Timeline — the two things `07-screens.md` §4.2 renders. The card has **one** flat timeline (`ORDER BY at DESC`), not per-season or per-kind sections, so there are no further stops to invent |
| Season Summary | the season label ("2026 lambing") | one per stat card (`07-screens.md` §12.2): Lambing percentage · Average litter size · Barren rate · Assisted rate · Losses · Lambing spread |
| Pen Board | "Pen board" | — (the board is one list, §3.5) |
| Treatments | "Treatments" | the two segments, in 07 §10's words: Countdowns · Medicine book |
| Reminders | "Reminders" | Overdue · Due today · Upcoming (`07-screens.md` §11.3 already specifies `headingLevel: 2` on these three) |
| Flock | "Flock" | — |
| Export | "Export" | Records (the six record artifacts) · Media · What is in the file (the §12 disclosure block, `07-screens.md` §13.4) |
| Settings | "Settings" | one per settings group |
| Lambing Entry · Lamb Card · Foster · Quick Entry · Note search | the screen title | **none** |

Quick Entry, Lambing Entry, Lamb Card, Foster and note search deliberately get no level-2 headings: each is one task, and heading stops would add navigation to screens whose entire purpose is not having any. Note search still carries a level-1 title, because §7.3's gate asserts at least one `headingLevel > 0` node on **all fourteen** variants, not on twelve.

### 3.5 Hard case A — the pen board grid

A 2-D grid is the one layout where linear traversal destroys the information, and Flutter's grid traversal has a long tail of open issues. **Do not fight the grid — make each cell self-describing and hand the screen reader a linear list.** Four rules:

**1. The board is a list, not a table.** `SemanticsRole.list` on the board, `SemanticsRole.listItem` on each tile. Pens are an unordered collection of independent facts, not a matrix with meaningful columns; `table` invites row/column navigation that yields nothing. (The one place `table`/`row`/`cell` *are* correct is the chart's table alternative, §3.7.)

**2. A summary node comes first, in tree order.** The board's glance equivalent: *"12 pens. 3 ready to turn out. 1 under withdrawal. 2 empty."* Build it as the first child so no `sortKey` is needed.

**3. Each tile is one node whose label is a complete sentence** — not "Pen 4" + "412" + "26h" as three nodes. The sentence is in the order a shepherd would say it, and status comes last and only when true.

**4. Row-major tree order is the traversal order.** Build the grid as a `Column` of `Row`s (or a `GridView` with `explicitChildNodes: true`) so tree order already matches reading order. **No `sortKey` anywhere in v1** — `OrdinalSortKey` sorts only among siblings inside one semantics group, silently misbehaves when mixed with unsorted siblings, and is a gate row (`a11y.sort_key`).

```dart
// lib/features/pens/widgets/pen_tile_semantics.dart
/// One sentence per tile. The visible tile paints tag / hours / status; this
/// node is what TalkBack and VoiceOver read, and the two must agree
/// word-for-word on the words that are visible (Voice Control criterion).
String penTileSentence(BuildContext context, PenTile t, Terminology terms) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final TermLabel term = terms.labelFor(t.animalClass);
  return <String>[
    l10n.penNamed(label: t.penLabel),                 // "Pen 4"
    if (t.tag != null) '${term.singular} ${t.tag}',   // "gimmer 412"
    if (t.tag == null) l10n.penEmpty,                 // "Empty"
    if (t.enteredAt != null)
      l10n.pennedForHours(hours: t.hours),            // "penned 26 hours"
    if (t.timeSource == TimeSource.userEdited)
      l10n.timeEditedByYou,                           // §12.5 — never the "~" alone
    switch (t.status) {                               // status LAST, and only if true
      PenTileStatus.ready     => l10n.penReadyThreshold(hours: t.thresholdHours),
      PenTileStatus.attention =>                      // pre-formatted: §8.4 rule 4, §9.1
          l10n.penClearOn(date: formatShedDayMonth(t.clearDate!, context.localeName)),
      PenTileStatus.loss      => l10n.penLossRecorded,
      PenTileStatus.settling  => '',
      PenTileStatus.empty     => '',
    },
  ].where((s) => s.isNotEmpty).join('. ');
}
```

Wrap the visuals, do not merge them:

```dart
Semantics(
  container: true,
  role: SemanticsRole.listItem,
  button: true,
  attributedLabel: spellOutTag(sentence, t.tag),
  onTap: onOpen,                        // the pen action sheet, not a screen route (07 §9.5)
  onTapHint: l10n.hintOpenPen,          // "…double tap to open pen"
  child: ExcludeSemantics(child: ShedPenTile(tile: t)),
)
```

> **Two names this document needs and no sibling defines.** `PenTile` is CONVENTIONS §3.2's element type for `penBoardProvider`, but its **fields** are unspecified, and the five-state `enum PenTileStatus { settling, ready, attention, loss, empty }` is named nowhere — `06-design-system.md` §11 and §12 list the five states in prose only. Both are declared here under CONVENTIONS §4.2 and belong to `lib/features/pens/pen_board_controller.dart`, which owns the projection (CONVENTIONS §3.2). The ten fields the projection must carry — `penId` (the tap target's route argument), `penLabel`, `tag`, `animalClass`, `enteredAt`, `hours`, `timeSource`, `status`, `thresholdHours`, `clearDate` — are the minimum this sentence and its tap handler need; if `02-state-di-navigation.md` or `07-screens.md` fixes a different shape, that shape wins and this sentence is rewritten against it, but it must still carry all ten facts.

**`MergeSemantics` is banned** (gate row `a11y.merge_semantics`). Merging joins child labels **with newlines**, takes the first gesture handler, and gives you no control over sentence order — it breaks the moment a tile grows a badge. `Semantics(label:) + ExcludeSemantics` is the pattern, and it is the same pattern `ShedTapTarget` already uses.

**The §12.2 tension, stated because it will otherwise be resolved wrongly.** Rule 3 above wants the label to match the visible chip, which reads `26h · READY`. Safety rule 2 forbids the app from claiming an animal is fit to turn out. The resolution is that the visible word and the disclosure travel together in both channels: the chip reads `26h · READY`, the board legend reads *"Ready = your 24 h threshold"* with the user's own number, and the spoken sentence is exactly what `penTileSentence` builds — *"Pen 4. gimmer 412. penned 26 hours. Ready — your 24 hour threshold"* (the noun and the timer are lower-case because they come from `TermLabel.singular` and `l10n.pennedForHours` verbatim; §7.3's traversal test asserts that string character-for-character). The visible word is present, so Voice Control matches; the threshold is named, so the app is playing back the user's own rule rather than making a clinical claim. **Never ship a label whose only status word is "Ready" with no threshold, and never ship one that drops the visible word entirely.**

**At large text the grid stops being a grid.** WCAG 1.4.10 forbids two-dimensional scrolling of the same content. The column count comes from the *scaled* metric, never from raw width:

```dart
// lib/features/pens/pen_board_screen.dart
int _penColumns(BuildContext context) {
  final ShedTokens t = context.tokens;
  final double scaled = MediaQuery.textScalerOf(context).scale(t.numeralSize);
  final double width = MediaQuery.sizeOf(context).width;
  // A tile must hold the longest tag at the current scale plus the timer,
  // and can never be narrower than two tap floors.
  final double minTile = math.max(2 * t.tapMin, scaled * 3.2);
  return math.max(1, (width / minTile).floor());
}
```

4 → 3 → 2 → 1 as text grows. At AX5 that is a vertical list — which is exactly what the screen-reader user wanted anyway. One layout, two audiences. **`withClampedTextScaling` to keep 24 tiles on screen is rejected** (§4.2).

### 3.6 Hard case B — the giant numeric keypad

`ShedKeypad` (`lib/core/ui/components/shed_keypad.dart`) is the most important control in the app and the one most likely to be invisible to assistive tech, because it is built out of tap surfaces rather than Material buttons. Geometry belongs to `06-design-system.md` §8.2; semantics belong here.

| Element | Semantics |
|---|---|
| A digit key | `ShedTapTarget(semanticLabel: '<digit>')`. **The label is the digit** — not "Seven key", not "Digit seven" (Voice Control matches the visible glyph). The glyph `Text` is inside `ExcludeSemantics` so it is not announced twice. |
| Backspace | `semanticLabel: l10n.keypadBackspace` ("Backspace"), `onTapHint: l10n.hintDeleteLastDigit`. **No key repeat** — key repeat needs a held contact. |
| The decimal key, inert | `onTap: null` ⇒ `ShedTapTarget` emits `enabled: false`. It keeps its label. The grid never re-legends. |
| The pad container | `Semantics(container: true, explicitChildNodes: true, label: l10n.keypadTagEntry)` so a VoiceOver user hears what they have landed in. |
| The entered tag | **A live region.** `Semantics(liveRegion: true, role: SemanticsRole.status, attributedLabel: <spelled-out digits>)`. Without it a blind user has no idea what they have typed. The buffer changes on every press, so the `didChangeLabel()` requirement (§3.8) is satisfied by construction. |
| The match count | **A second live region**, and its label carries the closest match: `l10n.matchCountClosest(count: n, tag: top)` → *"3 matches, closest 412"*. Counting alone re-announces nothing when 3 matches become a different 3 matches. |
| The confirm bar | `ShedConfirmBar`, labelled with the **outcome** — "Use 412" / "Create 412", tag range spelled out. Never a bare tick, in pixels or in speech. |

The keypad is allowed to grow with text scale and consume more of the screen; the filtered match list gives up rows first. **`FittedBox` is banned** (§4.4).

### 3.7 Hard case C — the lambing-spread chart

Apple is unambiguous: *"Charts and other data visualizations should include accessibility information through a chart API, or include a reasonably complete text alternative."* Flutter has no chart API, so we owe the alternative. `ShedSpreadChart` wraps `SpreadChartPainter` (decision #70). **Three layers, all three required.**

**Layer 1 — a summary sentence, always visible.** Not a tooltip, not a screen-reader-only string: a real line of text under the chart, because the 3am user with no glasses cannot read a 30-bar chart either.

> "Lambing spread, 14 Mar to 2 Apr. 132 lambs over 20 days. Busiest day 21 Mar, 19 lambs. First day 14 Mar, 3 lambs. Last day 2 Apr, 1 lamb."

It is one ARB message with **eight** placeholders — `start`, `end`, `total`, `days`, `busiestDate`, `busiestCount`, `firstCount`, `lastCount` (the first and last dates reuse `start` / `end`). Every date arrives **pre-formatted** as `d MMM` from `formatShedDayMonth` (§8.4 rule 4, §9.2), and every count that can be 1 is an ICU plural, or "1 lamb" ships as "1 lambs" on the one-lamb day. It states facts and never a judgement — "your tupping was tight" is banned by safety rule 2.

**This is a second line, not a replacement.** `07-screens.md` §12.3 already puts one fact under the chart — *"32 of 48 ewes lambed in the first 17 days"*, off `app_settings.cycle_days`. Both lines ship, both are visible text, and neither is screen-reader-only. A developer who reads only one document will delete the other; that is why the pairing is written down here.

**Layer 2 — per-bar semantics.** `CustomPainter` exposes `SemanticsBuilderCallback? get semanticsBuilder`; returning non-null makes the `CustomPaint` contribute nodes.

```dart
// lib/features/season/widgets/spread_chart_painter.dart
@override
SemanticsBuilderCallback get semanticsBuilder => (Size size) {
      final double barWidth = size.width / days.length;
      return <CustomPainterSemantics>[
        for (int i = 0; i < days.length; i++)
          CustomPainterSemantics(
            key: ValueKey<LocalDate>(days[i].date),
            rect: Rect.fromLTWH(i * barWidth, 0, barWidth, size.height),
            properties: SemanticsProperties(
              // "21 Mar, 19 lambs" — never "bar 7 of 20".
              label: strings.barLabel(days[i].date, days[i].count),
              role: SemanticsRole.listItem,
            ),
          ),
      ];
    };

@override
bool shouldRebuildSemantics(SpreadChartPainter old) => old.days != days;
```

`strings` is a pre-localised builder passed in by the widget — a painter has no `BuildContext` and must never reach for one. Zero-count days are in the list and say so ("18 Mar, no lambs"): the gaps *are* the information (`07-screens.md` §12.2).

**Layer 3 — "View as table".** A 60 pt button beside the chart, rendering date/count rows with `SemanticsRole.table` / `row` / `cell` and a `columnHeader` per column. It satisfies WCAG 1.4.1, satisfies Apple's VoiceOver criterion outright, and serves the shepherd who just wants the numbers. It is the cheapest accessibility feature in the app and the only place table roles are correct.

**On reflow.** The chart scrolls horizontally inside its card when bars would fall below a 60 pt tap target (`07-screens.md` §12.3), inside a vertically-scrolling page. That is not a 1.4.10 violation: the criterion excepts content requiring two-dimensional layout for its meaning, and a time-series chart is the canonical example. The table alternative is what makes that exception honest.

### 3.8 Live regions, and the "saved" announcement

There is no Save button (decision #11), so the receipt *is* the proof the row exists. That makes the announcement load-bearing in a way it is not in most apps.

**Never `SemanticsService.announce` and never `sendAnnouncement`.** `announce` is deprecated; `sendAnnouncement` is a **guaranteed no-op on Android**, where `NO_ANNOUNCE` is set unconditionally at bridge construction. This is not a Flutter gap — Android 16 deprecates accessibility announcements outright:

> "Android 16 deprecates accessibility announcements, characterized by the use of `announceForAccessibility` or the dispatch of `TYPE_ANNOUNCEMENT` accessibility events… alternatives better serve a broader range of user needs."

and names `setAccessibilityLiveRegion` for "changes to critical UI" as the replacement — which is precisely what `Semantics(liveRegion: true)` compiles down to. The Flutter answer and the platform answer agree. Gate row `a11y.announce` (already in `06-design-system.md` §3.5) makes it permanent.

**The one path is `confirmSaved`.** Per CONVENTIONS R10/R30 the three feedback functions live in `lib/core/ui/feedback.dart`, which is the only file permitted to call `showSnackBar(`:

```dart
void confirmSaved(BuildContext context, SaveReceipt receipt, List<Warning> warnings);
void showFailure(BuildContext context, ShedFailure failure);
void showCapRow(BuildContext context, RefusalReason reason);
```

> **Checked, not assumed.** `06-design-system.md` §10.3 prints exactly this signature and states that `showShedReceipt` / `showShedFailure` are banned spellings (R30). There is no live conflict here; the earlier one was closed. Do not re-record it — a doc set that carries fixed conflicts in its conflict list trains readers to stop trusting the list (the principle behind CONVENTIONS R38).

Three requirements this document adds to that function:

1. **The label must differ from the previous one, or Android will not re-announce it.** `AccessibilityBridge` only fires a live region on `didChangeLabel()`, and `ACCESSIBILITY_LIVE_REGION_POLITE` is a string comparison. Two saves in ten seconds is normal during triplets. The label is `'${r.term} ${r.tag} · ${r.summary} · ${r.at}'` — the tag and the summary are what make it unique, because `r.at` is `HH:mm` and two writes inside one minute share it. **The uniqueness obligation therefore lands on `SaveReceipt.summary`**, which the write controller builds: every summary names the thing that just changed (`lamb 3`, `ease 2`, `triplets`, `Alamycin · meat 28 d`). A test enumerates the three worst cases and asserts consecutive labels differ:

```dart
// test/features/receipt_label_unique_test.dart
// Three lambs added to one ewe inside one minute; two pen entries inside one
// minute; a repeat treatment across two ewes inside one minute.
expect(labels.toSet().length, labels.length);
```

   The residual case — the identical action, on the identical animal, twice inside one minute — is a genuine duplicate the shepherd deliberately performed, and `WriteController.guard()` already refuses the accidental double-fire. **The fix for any new collision is a more specific `summary`, never a hidden character appended to the label.** A zero-width or trailing-space disambiguator is banned: it is invisible in review, it survives no refactor, and it teaches the next reader that the rule is decorative.

2. **Warnings are spoken, not only badged.** A `WarningCode` badge is a visual channel with no spoken form. When `warnings` is non-empty, the receipt label appends the first warning's `message`, and the haptic is `warningNotification()` rather than `successNotification()` (`06-design-system.md` §10.1). Both values stay recorded verbatim — the announcement flags, it never fixes (spec §12.4).

3. **The receipt is visible and persistent, not transient.** The framework's own caution applies: an announcement may be dropped if the OS is already speaking. `SnackBar.persist` defaults to `action != null` on this SDK, so an action-bearing receipt does not auto-dismiss; `dismissDirection: DismissDirection.none` because swipe is banned. If the receipt is ever replaced by a house `ShedReceiptBar` in an `OverlayEntry`, that widget must carry its own `Semantics(liveRegion: true, role: SemanticsRole.status)` with the same uniqueness rule — it inherits none of `SnackBar`'s framework wrapping.

**Other live regions in the app**, and there are only these: the keypad tag buffer and match count (§3.6); the withdrawal countdown when it crosses to clear; the reminders "overdue" group header when the minute tick moves an item into it. Everything else is a normal node. A live region on a frequently-changing node is a screen reader that will not shut up.

### 3.9 Traversal order

- **Prefer tree order.** Build in reading order and you need no sort keys. Every screen in this app can.
- **`sortKey` is banned in v1** (`a11y.sort_key`). `OrdinalSortKey` reorders only siblings inside one semantics group, and every sibling in that group must also carry an `OrdinalSortKey` or the order is undefined.
- `traversalParentIdentifier` / `traversalChildIdentifier` (3.44) exist for content rendered in an `OverlayPortal` that logically belongs inside a card. The pen action sheet is the only candidate; it is a `ShedBottomSheet` (a route), so it does not need them. If one is ever added, each identifier must be unique.
- **Test every bottom sheet with VoiceOver before shipping.** Modal semantics ordering changed in a past release; the sheet is where it shows up.

---

## 4. Text scaling

### 4.1 The API

`TextScaler`, never `textScaleFactor`. `MediaQueryData.textScaleFactor` has been deprecated since 3.16 and is documented as "will be removed in a future version". The gate row `a11y.scale_factor` bans the literal string `textScaleFactor` under `lib/` — **including the theme layer**, which is where the tempting `_AtLeast(mq.textScaler, 1.0)` wrapper from the raw research would have put it.

| Old | New |
|---|---|
| `MediaQuery.textScaleFactorOf(context)` | `MediaQuery.textScalerOf(context)` |
| `style.fontSize * factor` | `MediaQuery.textScalerOf(context).scale(style.fontSize)` |
| `RichText(textScaleFactor:)` | `RichText(textScaler:)` |
| `copyWith(textScaleFactor: 1.0)` | `MediaQuery.withNoTextScaling(child:)` |

### 4.2 Why clamping is a bug

```dart
// DO NOT DO THIS. Anywhere. For any reason.
MediaQuery(
  data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.2)),
  child: child,
)
```

Three independent reasons, and each alone is disqualifying:

1. **It overrides the OS setting** — which is exactly the setting a shepherd who left their reading glasses in the house has already turned up. This app's whole thesis is honouring that user.
2. **It makes Apple's Larger Text declaration a lie.** The criterion is that users can enlarge text to at least 200% or the system maximum. Clamp at 1.3× and you cannot declare Larger Text, which costs you a Nutrition Label row (§7.1).
3. **It discards Android 14's non-linear curve**, which deliberately grows small text more than large text. `TextScaler.linear` throws the curve away.

`MediaQuery.withClampedTextScaling` and `TextScaler.clamp` are gated (`type.clamp`, `06-design-system.md` §3.5). **There is deliberately no floor either** — a user who set 85% on the OS told the system they read smaller type, and honouring that beats enforcing our 18 pt design floor over their choice. 18 pt is the floor *at scale 1.0*.

**The one sanctioned exception** is Flutter's own: `MediaQuery.withNoTextScaling` around icon fonts and fixed-geometry glyph art, where scaling makes an icon overlap its own box. The *target* around such an icon is still ≥ 60 pt.

**The exception worth naming and rejecting:** clamping the pen board at AX5 so 24 tiles still fit. Rejected. The answer is reflow (§3.5) — fewer columns, then one, then a list. The board stops being glanceable at AX5, and that is the correct trade: a user at AX5 was never going to read a 24-tile grid from arm's length.

If a `TextScaler` subclass is ever added it must override `scale()` only, implement `==`/`hashCode`, and be hoisted out of `build()`. Constructing one inside `build()` makes `MediaQuery.updateShouldNotify` see a changed scaler on **every** rebuild and invalidates every MediaQuery dependant in the tree.

### 4.3 Layout patterns that survive 200% on a dense board

`06-design-system.md` §5.5 owns this table; it is repeated here because it is what the overflow matrix is actually testing.

| Use | Instead of |
|---|---|
| `LayoutBuilder` choosing column count from `MediaQuery.textScalerOf(context).scale(t.numeralSize)` | `GridView.count(crossAxisCount: 4)` |
| `Wrap` for the ease 1–5 row, birth type, any chip row | `Row` + `Expanded` |
| `Column` + `SingleChildScrollView` for every form | a fixed-height `Card` |
| `ConstrainedBox(minHeight:)` + intrinsic height | `SizedBox(height: 56)` |
| Label **above** value (`ShedFieldRow`) | label-left / value-right two-column rows |
| `Flexible` + `softWrap: true` + `maxLines: null` | `maxLines: 1, overflow: TextOverflow.ellipsis` |
| Icon **and** text stacked vertically | icon + text in a `Row` |
| `spacing:` on `Row`/`Column`/`Flex` with `t.gapMin` | `SizedBox` soup that does not reflow |

Two hazards specific to this app:

- **Never ellipsise a user's own words.** Apple: *"Avoid truncating text to the point that it becomes unreadable or ambiguous… Consider allowing the text to wrap."* Notes on the Ewe Card wrap; a product name on a treatment row wraps; a `TermLabel` on a button wraps (which is why 05 §8.4 caps overrides at 24 characters). If a list must truncate, the full text is reachable in one tap.
- **The pen tile timer.** `26h` is fine visually and must be able to take its own line at large scale; the spoken form is always `l10n.pennedForHours` → "penned 26 hours" (§3.5).

### 4.4 `FittedBox` is banned around user-facing text

`FittedBox` looks like the fix for overflow at large text scale and is a **silent clamp**: it shrinks the glyphs the user deliberately enlarged, so the layout passes the overflow matrix while failing the human. It is gated (`type.fitted_box`, `06-design-system.md` §3.5) and is a named line in `CODE-REVIEW-CHECKLIST.md`. Grow the container, wrap the text, or reflow the layout.

### 4.5 Text spacing (WCAG 1.4.12) — satisfied by design, not by a flag

Flutter 3.44's `MediaQueryData` carries `lineHeightScaleFactorOverride`, `letterSpacingOverride`, `wordSpacingOverride` and `paragraphSpacingOverride`, and `Text` applies the first three automatically. **The only engine implementations are web.** On iOS and Android they are permanently `null`.

So do not read them. Satisfy 1.4.12 by construction: **no fixed-height text container anywhere**, and `height: 1.4`–`1.5` baked into the base `TextTheme` so there is headroom rather than a cliff. Writing `if (MediaQuery.maybeLineHeightScaleFactorOverrideOf(context) != null)` is dead code that reads as a feature.

### 4.6 Bold text, and the bug that makes heavy text lighter

`Text.build` does this unconditionally:

```dart
if (MediaQuery.boldTextOf(context)) {
  effectiveTextStyle = effectiveTextStyle!.merge(const TextStyle(fontWeight: FontWeight.bold));
}
```

`FontWeight.bold` is **w700**, and `merge` wins. Any style at w800/w900 therefore becomes w700 when the user turns Bold Text on — your heaviest text gets *lighter*, in exactly the accessibility mode that exists to make it heavier (flutter#139712, open since Dec 2023).

**House rule: no text style in Shed Book exceeds `FontWeight.w700`** (decision #98, gate row `type.weight_cap`). Hierarchy comes from size and colour. In the night-shift palettes, stroke is bought by raising `bodySize` 18→20 and `numeralSize` 40→44 — never by bumping weight. The rejected `weightBump: 100` walked straight into this bug on button labels and pen-tile numerals.

Android caveat: `boldText` only exists on API 31+. On Android 11 and below there is no signal at all, which is another reason the app never branches on it.

---

## 5. Colour is never the only channel

### 5.1 The rule

> **Every state the app renders carries at least three of: colour, shape, word, position. Colour is never one of the three on its own.**

Three reasons bind harder here than in a normal app: red-green colour-vision deficiency affects roughly 1 in 12 men and this user base skews male; **the night-shift palettes deliberately destroy the hue channel**, so a colour-only encoding is unreadable in the mode the spec names twice; and a head torch's colour temperature shifts perceived hue anyway. Apple's criterion is the test: *"If you can't use your own app in grayscale, rethink your app's design."*

### 5.2 The redundancy table — every state the app shows

Colour tokens are `ShedTokens` names (`06-design-system.md` §3.4); a widget never reads `ColorScheme`. Words come from the ARB. This table is the ship gate for §7.2 row 6.

| Where | State | Colour token | Shape | Word | Position |
|---|---|---|---|---|---|
| Pen tile | Settling (< threshold) | `textSecondary` | plain tile, no border | `4h` | default order |
| Pen tile | Ready to turn out | `statusReady` | thick left bar + filled corner triangle | `26h · READY` | sorted to top |
| Pen tile | Under withdrawal / treating | `statusAttention` | dashed outline + circle-slash badge | `12h · CLEAR 14 JUL` | badge on cell |
| Pen tile | Loss recorded | `statusLoss` | diagonal hatch fill | `DEAD` | sorted to top |
| Pen tile | Empty pen | `outline` only | dashed border, no fill | `—` | sorted to bottom |
| `ShedCountdown` | `ClearsOn`, still running | `statusAttention` | circle-slash | `CLEAR 14 JUL` + `as entered by you` | in the treatment row |
| `ShedCountdown` | `ClearsOn`, elapsed | `textPrimary` | plain | `CLEAR` | — |
| Treatment row (**no** `ShedCountdown`) | `NoWithdrawal` | `textSecondary` | plain | `NOT APPLICABLE` | where the countdown would have been |
| Treatment row (**no** `ShedCountdown`) | `WithdrawalUnknown` | `textSecondary` | dashed outline | **`NOT RECORDED`** — never `0`, never blank | where the countdown would have been |
| Lamb row | `alive` | `textPrimary` | plain | the lamb's tag or ordinal | — |
| Lamb row | `dead` | `statusLoss` | hatch fill | `DEAD` + cause | grouped after alive |
| Lamb row | `stillborn` | `statusLoss` | hatch fill + outline | `STILLBORN` — its own word, never folded into "died" | grouped after alive |
| Lamb row | `sold` | `textSecondary` | plain, dimmed | `SOLD` | grouped last |
| Ewe row | `active` / `sold` / `dead` / `culled` | `textPrimary` / `textSecondary` ×3 | plain / strikethrough tag | the status word, always | — |
| Ewe season | `barren` | `textSecondary` | plain | `BARREN` | — |
| Warning badge (§12.4) | any `WarningCode` | `statusAttention` | filled triangle + `!` | the `Warning.message`, in full, on the row that owns the field | inline |
| Reminder | overdue / due today / upcoming | `statusAttention` / `textPrimary` / `textSecondary` | filled dot / open dot / none | the group heading, `headingLevel: 2` | three groups |
| Care checkbox | given / not given | `statusReady` / `outline` | filled tick box / empty box | the kind, always spelled | — |
| Provenance | auto / entered / edited | none — text only | none | `recorded automatically` / `time entered by you` / `time edited by you` | beside the time |
| Free-tier row | over cap | **none** — `textSecondary` on `surfaceRaised`, identical at 3 ewes and at 15 (decision #92) | none | the row copy | Flock top / Settings only |

Three rules that fall out of the table and are easy to get wrong:

- **Shapes must be distinguishable in silhouette** — bar, triangle, dashed outline, hatch, dash. Four differently-coloured circles is one shape. That is exactly Apple's own counter-example.
- **A marker is never the only signal.** The edited-time `~` prefix on a pen tile has no spoken form and no grayscale form, so the word `edited` travels with it in both channels (`07-screens.md` §9.6).
- **The four withdrawal rows split on a *type*, not on a layout choice.** `ShedCountdown` takes a `ClearsOn`, never a `WithdrawalStatus` (CONVENTIONS §2.7; `05-domain-correctness.md` §9 anti-pattern 9; `07-screens.md` §10.3), so a countdown for a period nobody recorded is not merely forbidden — it is unconstructible. `NOT APPLICABLE` and `NOT RECORDED` are painted by the treatment row itself, in the pixels the countdown would have occupied, with no countdown widget in the tree. Writing `ShedCountdown(status)` to "handle all four in one place" is the defect this row exists to prevent, and it is the one place in this table where the compiler is the gate.

### 5.3 The gate

- **Grayscale.** Turn on the OS grayscale filter and read the board. If you cannot, it fails. This is a per-release manual pass (§7.2 row 6), because no automated check exists for it.
- **Non-text contrast (WCAG 1.4.11, 3:1)** for tile outlines, status glyphs and chart bars. `06-design-system.md` §3.5's `test/design/contrast_test.dart` covers text; non-text carriers are checked against the palette table by hand **unless** the 3.44 in-framework evaluation is public. **UNVERIFIED:** the 3.44 release notes list new evaluations in `packages/flutter/lib/src/widgets/_accessibility_evaluations.dart` — non-text colour contrast (`kMinimumRatioNonText = 3.0`), `UnlabeledLeafNodeEvaluation`, title evaluation — but the leading underscore means they may still be private. **Action before writing any hand-rolled non-text contrast check: grep the installed SDK for `kMinimumRatioNonText` and for exported `AccessibilityGuideline` constants.** If public, wire them into the `test/design/` loop and delete the manual step. If private, keep measuring by hand and re-check on every SDK bump.

---

## 6. Motor accessibility

### 6.1 Targets, spacing and slop

`06-design-system.md` §6 owns the numbers; this is why they are accessibility numbers and not generosity.

| Class | Size | ≈ mm | Where |
|---|---|---|---|
| `tapMin` | **60** | 9.5 | absolute floor, everything interactive including Settings rows |
| `tapPrimary` | **72** | 11.4 | keypad keys, recents chips, pen tiles, ease buttons |
| `tapHero` | **88** | 14.0 | the five 3am actions |
| `gapMin` | **16** | 2.5 | between any two targets — double Material's 8 dp |
| `gapDestructive` | **32** | 5.1 | between a destructive target and its nearest neighbour |

60 pt ≈ 9.5 mm matches Parhi et al.'s 9.2 mm (discrete) / 9.6 mm (serial) optimum for one-handed thumb use **with a bare, warm, dry thumb in a lab**. Gloves, cold and a wet screen are all worse than ideal, and tag entry is a serial task. It exceeds Apple's 44, Android's 48 and WCAG AAA's 44, and it is the single highest-leverage accessibility decision in the product.

Four rules the geometry does not express:

- **Hit slop beyond the painted bounds.** `ShedTapTarget` sets `HitTestBehavior.opaque` around a `ConstrainedBox`, so a 32 pt glyph sits inside an 88 pt hit region. A gloved thumb lands 5–8 pt off centre.
- **Flutter clips hit testing to a parent's bounds.** A target that overflows its parent silently drops taps even with `Clip.none`. Restructure the layout; this bug only appears on a real device.
- **Corner and edge exclusion.** The bottom ~20 pt and top ~44 pt are system gesture zones. A 60 pt target starting at y=0 is not a 60 pt target. `MinimumTapTargetGuideline` silently **skips** nodes flush with a screen edge, which is why the geometric gate in `06-design-system.md` §6.3 exists alongside it.
- **Destructive targets get the same size, never the same place.** Delete is never `gapMin` from Save.

### 6.2 The gesture ban is a motor-accessibility requirement

Every action is reachable by a sequence of single discrete taps. WCAG 2.5.1 (A) and 2.5.7 (A), spec §5, decision #101.

| Tempting gesture | The required plain control |
|---|---|
| Swipe-to-delete a lamb | an explicit Delete control inside the lamb card, plus the persistent Undo |
| Long-press to multi-select pens | a "Select" mode toggle button |
| Drag a lamb to another ewe | Foster → pick ewe, two taps (spec §7.3) |
| Pinch to zoom the board | the OS text scale drives density (§3.5) |
| Pull-to-refresh | nothing to refresh — it is offline |
| Shake to undo | the Undo action on the receipt |
| A time-picker dial / a `Slider` / a `CupertinoPicker` | `ShedKeypad` (decision #57, R70) |

**`showDatePicker` and `showTimePicker` do not ship in v1** (gate row `a11y.material_picker`). The time picker's dial is a drag; its keyboard mode opens the system IME, which `06-design-system.md` §8.1 rules out; the date picker's calendar cells are ~32 pt, half the floor. The replacement is what a shepherd actually needs at 07:00 the morning after: **relative buttons — Today / Yesterday / 2 days ago — plus `ShedKeypad` for the time.** `07-screens.md` owns where that control appears on Lambing Entry and Treatments; this document owns the ban and the reason. `GlobalMaterialLocalizations` is still required — it supplies the Material strings and semantics labels the framework uses elsewhere.

If a gesture ever exists at all it is an accelerator, and the button must be discoverable without knowing the gesture exists.

### 6.3 Switch Control and Voice Control

**Switch Control (iOS) / Switch Access (Android)** scan the tree in traversal order, so everything in §3.9 applies, plus two requirements:

- **Every interactive node is reachable and named.** An unlabelled node is an unnamed stop. `ShedTapTarget`'s `required semanticLabel` and `labeledTapTargetGuideline` are the two mechanisms; `accessibility_tools` catches the rest live in debug.
- **Nothing times out.** A switch user takes 20 seconds to reach a button. The receipt persists (§3.8); no sheet auto-dismisses; `isDismissible: false` on every `ShedBottomSheet`.

**Voice Control (iOS)** is the one that dictates how labels are written. Apple: *"Match Voice Control labels to the visible text."* If the control says "Turn out" and the label is "Release from pen", "Show names" shows the wrong words and the spoken command fails. So: **visible text is the source of truth for the label**, icon-only controls carry the name a person would speak *and* where practical a visible word (which at 3am is the right design anyway), and any secondary behaviour is listed as a `customSemanticsActions` entry so it appears in the actions rotor.

Why every action needs a plain button somewhere, in one sentence: Switch Control, Voice Control, a gloved thumb, a wet screen and a phone in a freezer bag all fail at gestures for **different** reasons and succeed at buttons for the **same** one.

> **Open (decision record §7.1 #2): ziplock-bag capacitance.** If the target hardware does not register taps through a freezer bag, decisions #100, #101 and #102 all change and this whole section is rewritten around volume-button shortcuts. It is a hardware test, not a desk decision, and it is unresolved.

---

## 7. The ship gate

### 7.1 The Accessibility Nutrition Label declaration

Declare a feature **only** when all seven common tasks (§1.1) complete with it. Re-evaluate every release; put it in the release checklist, not in someone's memory.

| Feature | Declare? | What must be true | Evidence |
|---|---|---|---|
| **VoiceOver** | Yes | Every task completable eyes-closed; every tap surface named; chart has a text alternative; headings navigable; the save receipt announces | §7.2 row 7 on 14 variants + `test/design/` guideline runs |
| **Voice Control** | Yes | Every visible control's spoken name matches its visible words; no gesture-only action | §7.2 row 8 |
| **Larger Text** | Yes | No clamp anywhere; readable and operable at AX5 / Android 200% + largest display size | §7.2 row 2 + the 252-cell overflow matrix |
| **Dark Interface** | Yes | The app is dark-only and correct in it; no white flash at any launch layer | §7.2 row 1 + `06-design-system.md` §9.4 |
| **Differentiate Without Color Alone** | Yes | §5.2's table holds in grayscale, on every screen | §7.2 row 6 |
| **Sufficient Contrast** | Yes | Measured ratios, not eyeballed; re-checked with Bold Text, Increase Contrast and Reduce Transparency on | `test/design/contrast_test.dart` + §7.2 rows 1, 3, 5 |
| **Reduced Motion** | Yes | Both platform flags honoured; no meaning carried only by motion | §7.2 row 4 + the two-branch unit test |
| **Captions** | **No** | — | See below |
| **Audio Descriptions** | **No** | — | No video anywhere in the app |

**Captions is left undeclared, and the reason is a consequence of an earlier decision.** The app records voice notes (`record` 7.1.1, AAC-LC `.m4a`) and cannot transcribe them: on-device speech recognition was cut from v1 because the recognizer runs in another process whose network access our manifest cannot constrain (owner ruling §7.0 #6). An untranscribed recording is inaccessible to a deaf user **and** to the shepherd's own future self reading the season back. So the rule is a design constraint rather than a caption track:

> **A voice note never carries a fact that exists nowhere else.** The record it attaches to is complete without it. The UI shows the note's duration and its provenance label, and the export ships the file alongside the records rather than in place of them.

Declaring Captions would be false; ignoring the gap would be worse. Say it in the store listing's accessibility notes and in `08-platform-integration.md`.

### 7.2 The per-screen sweep

Run on **one small iPhone and one small Android**, in a dark room, holding a torch. The subjects are the **14 pumpable variants** (12 screens + note search + the export-banner state — CONVENTIONS R58), not 12: Flock · Ewe Card · Quick Entry · Lambing Entry · Lamb Card · Foster · Pen Board · Treatments · Reminders · Season Summary · Export · Settings · Note search · Quick Entry with the export banner shown.

| # | Pass | Definition of done |
|---|---|---|
| 1 | **Dark, default palette** | No white flash from cold launch at any of the four layers. No surface lighter than the palette's `surfaceFillPressed` — the brightest of the five, and the fifth surface arrived with `06 §3.3`'s 2026-08-01 amendment; this row named `surfaceFill` when there were four. Every text/background pair measured, not eyeballed. |
| 2 | **Largest text** (iOS AX5; Android 200% **and** largest display size, simultaneously) | No clipped text, no overlapping text, no horizontal page scroll, every target still ≥ 60 pt, every action still reachable. The pen board has reflowed to ≤ 2 columns. No `FittedBox` has appeared. |
| 3 | **Bold Text on** | Nothing reflows into overflow. Nothing got *lighter* (§4.6). |
| 4 | **Reduce Motion on** — set it on **both** platforms, they are different flags | No slide transitions, no shimmer, no pulsing badge. Nothing became undiscoverable because its animation was the affordance. |
| 5 | **Increase Contrast on (iOS)** | The high-contrast palette engaged; the five status encodings still separable. |
| 6 | **Grayscale filter on** | Every row of §5.2's table still identifiable. Apple's own recommended test. |
| 6b | **Smart Invert on (iOS)** | Nothing becomes unreadable. Photos invert and that is accepted (§2.2); no photo is the sole carrier of meaning. |
| 7 | **VoiceOver / TalkBack, eyes closed** | The full core loop — pick animal, record a lambing, hear the receipt — without looking. Then: open a ewe card, foster a lamb, log a treatment with a withdrawal, read the season chart, export a CSV. |
| 8 | **Voice Control (iOS), "Show names" on** | Every visible control's name matches its visible words. Complete the core loop by voice only. |
| 9 | **Switch Control / Switch Access** | Every interactive node reachable and named; nothing times out; the receipt is still on screen when you get to Undo. |
| 10 | **One thumb, one hand, both handednesses** | Every primary action inside a 60 pt-radius arc of the resting thumb. No two-hand reach on Quick Entry. `app_settings.left_handed` mirrors the keypad's bottom row **and the bottom action bar order**, and nothing else (`07-screens.md` §14.3 row 8 and §20 rule 4; CONVENTIONS R40). Run the sweep with it both ways — a mirrored layout that clips at AX5 is a defect the default layout hides. |
| 11 | **Glove / freezer bag** | Physically test. **Informs design, does not gate release** — it is decision-record §7.1 #2 and it is open. |

**Ship gate: rows 1–10 green on all 14 variants.** Row 11 is an input to the design, not a release blocker. Row 6b is per release, not per screen.

### 7.3 The automated half

Tests live in `test/design/` (semantic and geometric gates, contrast) and `test/features/` (the overflow matrix, per-screen semantics). **`test/a11y/` does not exist** — the test tree is fixed by CONVENTIONS R57.

```dart
// test/design/semantics_gate_test.dart
for (final screen in shedScreens) {           // the 14 variants
  testWidgets('${screen.name}: semantic gate', (tester) async {
    // WITHOUT this handle semanticsOwner is null and every guideline below
    // throws instead of asserting — the gate silently cannot do its job.
    final SemanticsHandle handle = tester.ensureSemantics();
    addTearDown(handle.dispose);

    await tester.pumpWidget(screen.build());
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(shedTapTargetGuideline));  // 60x60, §6.1
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    // Decision #104: at least one real heading per screen.
    expect(
      tester.semantics
          .simulatedAccessibilityTraversal()
          .any((n) => n.headingLevel > 0),
      isTrue,
      reason: 'header: true is a no-op on 3.44 — use headingLevel',
    );
  });
}
```

Three further tests that are cheap and catch the failures this document exists to prevent:

```dart
// test/features/pen_board_traversal_test.dart — one sentence per pen, row-major.
final labels = tester.semantics
    .simulatedAccessibilityTraversal(start: find.byType(PenBoardScreen))
    .map((n) => n.label)
    .toList();
expect(labels.first, startsWith('12 pens'));            // the summary node
expect(labels[1], 'Pen 1. gimmer 412. penned 26 hours. Ready — your 24 hour threshold');

// test/features/locale_resolution_test.dart — decision #108's ordering (§8.3).
expect(resolve(const [Locale('en', 'GB')]), const Locale('en', 'GB'));
expect(resolve(const [Locale('en', 'US')]), const Locale('en'));
expect(resolve(const [Locale('fr', 'FR')]), const Locale('en'));

// test/policy/arb_has_no_domain_noun_test.dart — §8.5's rule, as an assertion.
```

Write every new semantics matcher with **`isSemantics`**; `containsSemantics` was deprecated in 3.41 and blog snippets still use it.

**`accessibility_tools` 2.8.0** is a `dev_dependency` that flags unlabelled targets, sub-48 dp targets and large-font overflow live in the debug app. Two things about it are not obvious and both were flagged in the c1/c3 review: **it is a widget that wraps the app tree, so `lib/` imports it** — wire it behind `kDebugMode` in `lib/app.dart` and add it to `tool/policy_allowlist.txt`'s `[dev_dependencies]` section — and **its 48×48 default is below our floor**, so it complements the house assertion and never replaces it.

---

## 8. Internationalisation groundwork

### 8.1 The decision, and the honest cost for one developer

**Adopt `flutter_localizations` + gen-l10n/ARB in the first commit, shipping exactly one locale: `en`, written in British English.** No translation ships in v1.

*What it costs, once, up front:* three lines in `pubspec.yaml`, a seven-line `l10n.yaml`, one `app_en.arb`, and `AppLocalizations.of(context).foo` instead of `'Foo'` at every call site. Call it two hours plus ten seconds per string for the mandatory `description`. The generated `lib/l10n/app_localizations*.dart` is **committed**, not gitignored — a stale generation must be visible in a diff rather than invisible in a build directory.

*What it buys immediately, before any translation exists* — and this is the real argument, because none of it is about translation:

- **One reviewable file containing every user-facing string.** This app's safety rules (spec §12) are rules about *wording*: "as entered by you", "not a regulatory record", never "you should". `05-domain-correctness.md` §7.3's `ContentPolicy` scan runs over `lib/l10n/*.arb`, so a single file is the difference between a guard that works and a guard that greps twelve screens of widget code and misses the string Dart split across two adjacent literals.
- **`GlobalMaterialLocalizations`**, which you need anyway — it is what makes every Material string and semantics label render en-GB rather than en-US.
- **ICU plurals**, so "no lambs / 1 lamb / 3 lambs" is one data-driven message instead of a `count == 1 ? …` ladder in ten widgets — and, decisively, so that the *noun* in that message can be the user's own word (§8.5).
- **Locale-aware `DateFormat` already initialised**, with no `initializeDateFormatting()` call and no async (§9.5).

*What is expensive to retrofit — the actual case:*

| Retrofit | Cost | Why |
|---|---|---|
| String extraction | **Very high** | Every `Text('…')` in 14 variants found, named, deduplicated, moved. Naming is the slow part; you will rename half of them twice. |
| Plurals | **Very high** | `'$n lamb${n == 1 ? '' : 's'}'` is scattered, and some of it will have been baked into **exported CSV headers and PDF text**, where changing it changes files users already hold. |
| Placeholder order | High | `'$term $tag'` encodes English word order at every call site. |
| Date/number formats | **High and dangerous** | Retrofitting `DateFormat` after shipping means old exports and new exports disagree about what `07/13` means — a §12.5 violation created by a refactor. |
| A second locale | **Low**, if the above is done | Add `app_ga.arb`. |
| RTL | Moderate | Free if `EdgeInsetsDirectional` and `start`/`end` are used from day one. **Do that** — it costs nothing today. |

*What it does not buy, stated plainly:* a US user sees British spelling in v1 (correct for a UK/Ireland-first launch, and later fixed by an `app_en_US.arb` holding ~15 strings); call sites get longer; and there is one more generated file in the diff.

**The trap:** adopting gen-l10n and then interpolating domain nouns into English sentence templates. That is the worst of both worlds, and §8.5 is the rule that prevents it.

### 8.2 The exact configuration

Versions come from decision record §5 and nowhere else.

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  # MUST be `any`. flutter_localizations on 3.44 pins `intl: 0.20.2` EXACTLY,
  # so `intl: ^0.20.3` does not resolve. Re-check after every Flutter upgrade.
  intl: any

flutter:
  generate: true          # read by FlutterManifest.generateLocalizations
```

```yaml
# l10n.yaml — repo root (CONVENTIONS §1). Ships en only.
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
# Every message must carry a description. Ten seconds each; it is where the
# safety rationale for a string lives (§8.4).
required-resource-attributes: true
# AppLocalizations.of(context) with no `!`.
nullable-getter: false
# Named parameters, so a three-placeholder message is readable at the call site.
use-named-parameters: true
```

**`synthetic-package` is dead.** Its own help text on 3.44 reads *"DEPRECATED. This flag cannot be enabled and should be removed."* Any tutorial that sets it predates 3.32.

`06-design-system.md` §2.1 owns `MaterialApp`; this document adds exactly one block to it. The host widget is `ShedBookApp extends ConsumerStatefulWidget` (CONVENTIONS R34), which is what 06 §2.1 already prints — this block goes inside that `build()`, beside 06's theme slots.

```dart
// lib/app.dart — the localisation half. 06 owns the theme half.
MaterialApp(
  title: 'Shed Book',                  // a product name, never localised —
                                       // onGenerateTitle would buy nothing
  localizationsDelegates: const <LocalizationsDelegate<Object>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  // Set EXPLICITLY, not from AppLocalizations.supportedLocales. Order is
  // load-bearing — see §8.3.
  supportedLocales: const <Locale>[
    Locale('en'),        // MUST be first
    Locale('en', 'GB'),
    Locale('en', 'IE'),
  ],
  // … theme slots, themeMode, navigatorKey, home — 06 §2.1
)
```

This works with a single `app_en.arb` because gen-l10n generates `isSupported` on the **language code**, and the lookup falls through the country switch to the language switch — `Locale('en','GB')` resolves to `AppLocalizationsEn` without an `app_en_GB.arb` existing. `MaterialLocalizationEnGb` and `MaterialLocalizationEnIe` both exist in the framework, so British and Irish Material strings and formats come free once the locale resolves.

**Offline check:** nothing here opens a socket. `flutter_localizations` bundles its CLDR date symbols as generated Dart and registers them with `initializeDateFormattingCustom` at delegate-load time; `intl` ships its data in the package; gen-l10n generates source at build time. No asset download, no HTTP, no permission.

### 8.3 The `supportedLocales` ordering trap

`WidgetsApp.basicLocaleListResolution` builds its lookup maps with **first-wins** semantics (`languageLocales[locale.languageCode] ??= locale`). The consequences:

| `supportedLocales` | Device `en-GB` → | Device `en-US` → |
|---|---|---|
| `[Locale('en')]` — what one `app_en.arb` gives you by default | **`en`** → US date order, week starts Sunday ❌ | `en` ✅ |
| `[Locale('en','GB'), Locale('en','IE'), Locale('en')]` | `en_GB` ✅ | **`en_GB`** ❌ — every English speaker on earth gets British formats |
| **`[Locale('en'), Locale('en','GB'), Locale('en','IE')]`** | `en_GB` ✅ | `en` ✅ |

Also: **`MaterialApp.supportedLocales` defaults to `[Locale('en','US')]`.** Leaving it unset is the same bug wearing a different hat.

Nobody notices this until an export is misread, which is why it is a test (`test/features/locale_resolution_test.dart`, §7.3) and not a comment.

### 8.4 ARB conventions

```json
{
  "@@locale": "en",

  "savedReceipt": "{term} {tag} · {summary} · {time}",
  "@savedReceipt": {
    "description": "Live-region save receipt. MUST differ from the previous one or Android will not re-announce it (the live region only fires on didChangeLabel). Uniqueness comes from tag + summary; see 10-accessibility-and-i18n.md §3.8.",
    "placeholders": {
      "term":    { "type": "String", "example": "gimmer" },
      "tag":     { "type": "String", "example": "412" },
      "summary": { "type": "String", "example": "triplets, ease 2" },
      "time":    { "type": "String", "example": "03:22" }
    }
  },

  "pennedForHours": "{hours, plural, =1{penned 1 hour} other{penned {hours} hours}}",
  "@pennedForHours": {
    "description": "Spoken form of the pen-tile timer. The visible form is abbreviated (26h); this is the semantics label.",
    "placeholders": { "hours": { "type": "int" } }
  },

  "withdrawalSource": "Withdrawal period: {days} days, as entered by you",
  "@withdrawalSource": {
    "description": "Spec 12.1 provenance. The wording 'as entered by you' is a SAFETY REQUIREMENT, not a style choice. Do not shorten it. Never show a withdrawal figure without it.",
    "placeholders": { "days": { "type": "int" } }
  },

  "penReadyThreshold": "Ready — your {hours} hour threshold",
  "@penReadyThreshold": {
    "description": "Spec 12.2. The word 'Ready' matches the visible chip (Voice Control), and the threshold is named so the app is playing back the USER'S rule, not making a clinical claim. Never ship 'Ready' alone.",
    "placeholders": { "hours": { "type": "int" } }
  }
}
```

House rules:

1. **Message ids are `screenConcept` or `conceptDetail` in `lowerCamel`, never the English text.** `penReadyThreshold`, not `readyDashYourTwentyFourHourThreshold`.
2. **Every message carries a `description`, and the description carries the safety rationale.** When a future contributor "improves" `withdrawalSource`, the description is what tells them why they must not.

   **Measured on Flutter 3.44.8, 2026-08-01, and it is not what this document used to claim.** `required-resource-attributes: true` fails generation when the **`@key` resource attribute block is missing entirely** — *"Resource attribute "@withdrawalSource" was not found. Please ensure that each resource has a corresponding @resource."* — and **passes** when the block is present but carries no `description`. The flag therefore holds *half* the rule. The other half, that the description exists and is non-empty, is held by `test/policy/l10n_bootstrap_test.dart`'s anchor, which walks every non-`@` key and asserts a non-empty `description` on its metadata. Keep the flag — it is what makes the `@` block mandatory, which is what gives the description somewhere to live — but do not describe it as the whole mechanism, because a rule believed to be enforced by a tool and actually enforced by nothing is worse than one nobody claimed.
3. **No domain noun is ever baked into a message** (§8.5).
4. **Dates and times are never formatted inside a message.** ARB supports `DateTime` placeholders with a `format`; this app does not use them, because `Instant`/`LocalDate` are extension types over `int`/`String` and the one formatting site is `lib/core/ui/formatters.dart` (§9.1). Pass a pre-formatted `String`. One formatting authority, not two.
5. **Nothing in `Disclaimers` is an ARB message.** `Disclaimers.exportFooter`, `.withdrawalProvenance` and `.withdrawalCaveat` are `const`s in `lib/domain/policy/disclaimers.dart` — a translator can soften or drop an ARB string and the app has no mechanism to notice. Same for the six `ShedFailure.userMessage` strings, which must render when the database is unreadable and the widget tree may not be healthy, and same for `RecordedTime.provenanceLabel`. §8.7 is the closed list; adding a seventh exception is a review conversation, not an edit.
6. **`NightErrorPanel` contains hard-coded English.** It renders outside `Theme`, `MediaQuery` and `Localizations` by construction; a `Localizations` lookup there is a crash inside the crash handler.

### 8.5 The terminology-placeholder rule

> **The ARB catalogue owns the *frame*. The terminology map owns the *nouns*. A domain noun never appears literally inside an ARB message; it always arrives as a placeholder.**

This section must agree exactly with `05-domain-correctness.md` §8, and does. `AnimalClass` (7 stable keys) lives in `lib/domain/terminology/animal_class.dart` and goes into the database, the CSV and the JSON backup. `TermLabel(singular, plural)` is the user-editable overlay, resolved by `Terminology.labelFor(AnimalClass)` through `terminologyProvider` (`Provider<Terminology>`).

Wrong, and it is the failure mode that survives code review:

```json
"turnOutPrompt": "Turn out ewe {tag}?"
```

Right:

```json
"turnOutPrompt": "Turn out {term} {tag}?",
"@turnOutPrompt": {
  "description": "{term} is a USER-EDITABLE noun from the terminology overlay (ewe/gimmer/theave/…). Never translate it, never hard-code it. See 05-domain-correctness.md §8.",
  "placeholders": {
    "term": { "type": "String", "example": "gimmer" },
    "tag":  { "type": "String", "example": "412" }
  }
}
```

**Plurals.** ICU cannot pluralise a runtime string: `"{count, plural, other{{count} {term}s}}"` yields "3 gimmers" (fine), "3 tups" (fine) and "3 sheeps" (not fine). So ICU chooses only the *category*, and the map supplies both forms:

```json
"nAnimals": "{count, plural, =0{No {pluralTerm}} =1{1 {singularTerm}} other{{count} {pluralTerm}}}",
"@nAnimals": {
  "placeholders": {
    "count":        { "type": "num" },
    "singularTerm": { "type": "String", "example": "ewe" },
    "pluralTerm":   { "type": "String", "example": "ewes" }
  }
}
```

```dart
final TermLabel l = ref.watch(terminologyProvider).labelFor(AnimalClass.ewe);
Text(AppLocalizations.of(context)
    .nAnimals(count: n, singularTerm: l.singular, pluralTerm: l.plural));
```

Four details that are load-bearing and easy to lose:

- **The placeholders are `singularTerm` / `pluralTerm`, never `singular` / `plural`.** `plural` is an ICU keyword; a placeholder that shadows it inside a plural expression parses today and stops parsing on the next `gen-l10n` release.
- **`count` is `"type": "num"`**, matching Flutter's own plural example.
- **Named arguments, not positional** — `use-named-parameters: true` means the positional spelling does not compile.
- **Never derive a plural by appending "s"** — not in the UI, not in exports, not in a semantics label. The user typed one word; guessing the other is safety rule 4.

**Prefer label/value over sentences.** `Ewes · 132`, not "There are 132 ewes." It is the most legible layout at 3am and at AX5, it survives translation into case-marking languages, and it dodges grammatical agreement entirely. Adopt it as the default for every statistic; reach for `nAnimals` only when a sentence is genuinely unavoidable.

**Semantics labels use the user's noun too.** If the shepherd calls her a theave, TalkBack says "theave 412". A board full of "ewe 412" when the whole flock is gimmers is an app the user stops trusting. The `SpellOutStringAttribute` applies to the **tag range only** (§3.3).

**Seeding, and the never-overwrite rule.** Defaults are ARB messages; seeding happens once, in `lib/features/settings/terminology_bootstrap.dart`, which already has a `BuildContext`. It happens **nowhere else**: `lib/domain/` and `lib/data/` are forbidden by the layer rules from importing `AppLocalizations`, which is exactly why `vocab_terms.label` and `terminology_overrides` are seeded with `NULL`/absent and resolved at the presentation edge. **A locale change or an app update never rewrites a user's term** — that would be silently correcting the user's entry.

The shipped en-GB defaults, one pair per `AnimalClass`:

| `AnimalClass` | ARB keys | Default singular / plural |
|---|---|---|
| `ewe` | `termEweSingular` / `termEwePlural` | ewe / ewes |
| `maidenFemale` | `termMaidenFemaleSingular` / `…Plural` | gimmer / gimmers |
| `eweLamb` | `termEweLambSingular` / `…Plural` | ewe lamb / ewe lambs |
| `ram` | `termRamSingular` / `…Plural` | ram / rams |
| `ramLamb` | `termRamLambSingular` / `…Plural` | ram lamb / ram lambs |
| `wether` | `termWetherSingular` / `…Plural` | wether / wethers |
| `lamb` | `termLambSingular` / `…Plural` | lamb / lambs |

`maidenFemale` is deliberately an unlovely key that belongs to no county, so *gimmer*, *theave*, *shearling ewe* and *hogg* are all equal citizens over one stable key. Many UK users will rename `ram` to *tup* — that is not a defect in the default, it is the entire reason the overlay exists.

**Export headers.** CSV headers and CSV `animal_class` values are **stable English keys**; the PDF flock book uses the **user's** labels; the JSON backup carries enum keys **plus a top-level `terminology` block** so a restore reproduces the shepherd's vocabulary exactly. A user-editable label never becomes a machine value. (`05-domain-correctness.md` §8.3; `09-export-formats.md` implements it.)

**The honest limitation:** two noun forms work cleanly for languages with two plural categories. Irish, Polish and Russian need `few`/`many`. For an English-only v1 this is correct, and adding `TermLabel.few`/`.many` later is an additive change to the record and the ARB. State it rather than discovering it on the first translation.

### 8.6 The 40 vocabulary labels

Per CONVENTIONS R66 there are three homes and no overlap:

- **Keys** → `lib/core/db/seed/first_run.dart`, `vocab_terms` rows with `origin = 'seeded'`, `label = NULL`.
- **Labels** → `lib/l10n/app_en.arb`, one message per key.
- **`assets/content/`** → only authored prose too long to be a UI string, plus one provenance line per list.

The mapping is mechanical: `vocab_terms.key` → `'vocab' + upperCamel(key)`. `dc_starvation` → `vocabDcStarvation`; `ease_1` → `vocabEase1`; `mp_breech` → `vocabMpBreech`. Six lists, forty keys, forty messages (`03-data-model-and-schema.md` §10.1). Parity is a test, not a habit:

```dart
// test/policy/vocab_labels_are_complete_test.dart
// A seeded key with no ARB message renders blank at 3am. Fail the build instead.
expect(seededVocabKeys.map(arbIdForVocabKey).toSet(), equals(arbVocabMessageIds));
```

Two constraints on the writing itself: the lambing-ease descriptions are **paraphrased, never adopted verbatim** — the cited SRUC technical note is image-based and its text and licence **could not be verified** — and the "no verbatim third-party copy" CI check scans **both** `assets/content/` and `lib/l10n/`.

> **Open (decision record §7.1 #15):** lambing ease 5 points or SRUC's 6. If it becomes 6, this is 41 keys and 41 messages plus a schema `CHECK` change. Recommendation on record: stay at 5.

### 8.7 What is deliberately not in the ARB

| Thing | Home | Why |
|---|---|---|
| `Disclaimers.*` | `lib/domain/policy/disclaimers.dart` | A translator can soften a safety string; a `const` referenced everywhere cannot be softened in one place (decision #62). |
| The six `ShedFailure.userMessage` strings | `lib/core/failure.dart` | They must render when the database is unreadable. |
| `RecordedTime.provenanceLabel` — `recorded automatically` / `time entered by you` / `time edited by you` | `lib/domain/time/recorded_time.dart` | `05-domain-correctness.md` §4.1's explicit carve-out: `lib/domain/` may not import `AppLocalizations` (layer rule 1), and the three strings are a §12.5 safety property, not copy. Correct only while v1 ships `en` alone; **if a second locale ever ships, the label moves to the ARB and 05 §4.4's exhaustive-switch test moves with it.** The §5.2 Provenance row must stay byte-identical to the `switch`. |
| `NightErrorPanel`'s copy | `lib/core/ui/night_error_panel.dart` | Renders outside `Localizations` by construction. |
| Stable keys — `time_source`, `WithdrawalTarget`, `LambCount`, `AnimalClass`, vocabulary keys, CSV headers | the enum / the schema | A machine value is a contract, not copy. |
| Anything the user typed | SQLite | Never translated, never normalised, never "corrected". |
| The price | `ProductDetails.price` from the store | Never a literal; gate row `copy.currency_literal`. |

---

## 9. Dates, numbers and units for en_GB

### 9.1 One formatting authority

`lib/core/ui/formatters.dart` is **the only `package:intl` call site in `lib/` outside `lib/data/`** (CONVENTIONS §1, layer rule 7). `06-design-system.md` owns the file; this document owns what it must do. These names are new and are declared here under CONVENTIONS §4:

```dart
// lib/core/ui/formatters.dart
String formatShedDate(LocalDate d, String localeName);       // 'd MMM y'  -> 11 Mar 2026
String formatShedDayMonth(LocalDate d, String localeName);   // 'd MMM'    -> 14 Jul
String formatShedTime(Instant t, String localeName);         // 'HH:mm'    -> 03:21
String formatShedWeight(Grams g, WeightUnit u, String localeName);
String formatShedCount(int n, String localeName);

/// The locale every formatter is passed. Never `null`: a null locale falls back
/// to the system locale, which in a background isolate is en_US.
extension ShedLocaleX on BuildContext {
  String get localeName => Localizations.localeOf(this).toString();  // "en_GB"
}
```

A controller never formats for display (`02-state-di-navigation.md` §4.4 rule 9). A controller that knows `en_GB` is a controller that cannot be unit-tested without a locale.

### 9.2 Never render an all-numeric date to a human

> **Rule: no date a person reads is all-numeric. Not `13/07/2026`, not `07/13/2026`. Every human-facing date spells the month.**

`13/07` and `07/13` are indistinguishable to a reader who does not know which locale resolved, and a **withdrawal clear date misread by six months puts meat into the food chain**. That is the single worst place in the app to be ambiguous, and it costs four characters to remove the ambiguity entirely. CONVENTIONS R60 settled it and `07-screens.md` §10.3 now renders `clear on 11 Mar 2026`; the countdown row is the one place in the app where this rule is safety-critical rather than stylistic.

**This is where the owner's `dd/MM/yyyy` ruling lands, and it looks like a contradiction until you read it properly.** Owner ruling §7.0 #3 records the *region's convention*, and the app's answer to that convention is to never render it — because that convention is precisely what makes a numeric date ambiguous to anyone whose phone is set to another region. The ruling is honoured in the machine columns, where `dd/MM/yyyy` never appears either: ISO-8601 does.

| Surface | Format |
|---|---|
| Any date a human reads | `d MMM y` → `11 Mar 2026` |
| A date inside a tight chip (pen tile, countdown) | `d MMM` → `14 Jul` |
| CSV | **two columns** — `date_iso` (`2026-07-13`) and `date_display` (`13 Jul 2026`) |
| CSV event times | five columns, per `05-domain-correctness.md` §4.3 |
| PDF | `d MMM y`, with the `†` edited-time marker and its footer legend |
| JSON backup | ISO-8601 only |

`date_iso` exists because spreadsheets famously re-interpret `13/07/2026`, and ISO-8601 is the only format Excel and Numbers parse identically. Export is the only backup mechanism this app has (spec §7.9), so this is a backup-integrity rule, not a formatting preference. `DateFormat.yMd` is a gate row (`copy.numeric_date`).

### 9.3 Date entry is the other half of the hazard

**There is no free-text date field anywhere.** A shepherd typing `07/03` means 7 March; a parser that reads it as 3 July has silently corrupted a record and violated §12.4 while looking helpful. And there is no `showDatePicker` either (§6.2).

The control is **relative buttons plus the keypad**: *Today · Yesterday · 2 days ago · Pick a date*, where "pick a date" steps a `d MMM y` value with two 60 pt arrows. A deferred lambing entry made at 07:00 is almost always "last night", so three taps beats any picker with cold hands, and the relative labels are unambiguous in every locale on earth.

Every entered — as opposed to captured — date and time carries its provenance: `RecordedTime.entered(effective:, now:)` and a `provenanceLabel` that is never empty (`05-domain-correctness.md` §4).

### 9.4 Time, week, decimals, units

| Setting | Source | Value | Why |
|---|---|---|---|
| Clock | **fixed, not the device** | 24-hour `HH:mm`, always | CONVENTIONS §5.4: there is no 12-hour path. `MediaQuery.alwaysUse24HourFormatOf` is deliberately unread — see below. |
| First day of week | locale, via `MaterialLocalizations.firstDayOfWeekIndex` | Monday for `en_GB` / `en_IE` | Free once §8.3 is right. **It has no v1 rendering** (no calendar ships); the assertion exists so the day one does, it is already correct. |
| Decimal separator | fixed | `.` — the keypad's decimal key always emits `.` (decision #57) | `double.parse('4,3')` throws and `NumberFormat.parse` for a comma locale throws on `'4.3'`. `parseUserNumber` returns `null` on ambiguity rather than guessing. |
| Weight | **user setting**, `unitsProvider : Provider<WeightUnit>` | kg | Never inferred from locale: a UK smallholder may genuinely want lb, and a wrong inference silently mislabels every weight ever recorded. Canonical storage is integer grams; conversion happens at the widget boundary only. |
| Temperature | user setting | °C | Same reasoning — **but see the open question below.** |

**The 24-hour deviation, stated because it is the one place the app overrides a system preference.** Reading `alwaysUse24HourFormat` would let a device render `3:21 AM`. Three reasons not to: the difference between 03:21 and 15:21 is a data-integrity question in an app used at 3am, and an AM/PM token is the part a tired reader drops; the medicine book handed to a vet must not have two spellings of the same instant; and the save receipt's uniqueness rule (§3.8) depends on a stable time string. The mitigation is that every displayed time carries its provenance label, so there is never a bare number to misread. It is a deliberate deviation, not an oversight.

> **Open (decision record §7.1 #11): where does temperature appear at all?** Spec §7.10 has a °C/°F setting; no v1 table stores a temperature (`03-data-model-and-schema.md` §5). Until the owner rules, **no `temperatureUnitProvider` ships** (CONVENTIONS R68) and no temperature formatter exists. An unused setting is a 3am tax.

### 9.5 `intl` outside the widget tree

After `GlobalMaterialLocalizations.delegate` loads, `DateFormat('d MMM y', 'en_GB')` just works — the delegate calls `initializeDateFormattingCustom` for every bundled locale. No async, no assets, no network.

**That is only true inside the widget tree.** Two paths run outside it:

1. **PDF generation on a background isolate** (decision #125). **The rule is that no `DateFormat` runs off the root isolate**: `ExportRepository` builds the document's view model with every date and time **already formatted** on the root isolate, and `compute()` receives strings. That removes the hazard entirely rather than managing it. If a future shape makes that impractical, the isolate entry point must call `initializeDateFormatting()` from `package:intl/date_symbol_data_local.dart` as its first statement — and a `DateFormat` with a `null` locale in an isolate silently produces `en_US`, which is the exact bug §9.2 exists to prevent.
2. **Anything before `runApp`.** `main()` awaits nothing and formats nothing (decision #21). If that ever changes, the same rule applies.

---

## 10. The gate rows this document adds

`tool/check_policy.dart` is the one source-scanning gate (decision #10). `01-architecture.md` §3.2 owns the driver and the allowlist format; `06-design-system.md` §3.5 owns the design rows. These are this document's, in CONVENTIONS §4.7's namespaces.

Already in the table and listed here so nobody adds a duplicate: `a11y.scale_factor` (`textScaleFactor`) and `a11y.header_bool` (`header: true`) from `01-architecture.md` §3.2; `a11y.announce`, `type.clamp`, `type.fitted_box` and `type.weight_cap` from `06-design-system.md` §3.5; and the **fourteen** `gesture.*` rows — eleven in 06 §3.5 plus `gesture.dismissible` / `gesture.draggable` / `gesture.tooltip`, which are in 01's `_bannedText`. Counting only 06's eleven is how a duplicate `gesture.tooltip` gets added.

**One of those rows is too narrow, and this document is the reason it must widen.** `a11y.announce` is currently `RegExp(r'SemanticsService\.announce')`, which does **not** match `SemanticsService.sendAnnouncement` — §3.8 bans both spellings and §11 row 2 claims the gate catches both, so as written the claim is false and the Android no-op ships. The pattern must become `RegExp(r'SemanticsService\.(announce|sendAnnouncement)\b')`. 06 owns the row; the edit is listed in the cross-document defects at the end of this file.

```dart
// tool/check_policy.dart — added to _bannedPattern (06 §3.5's table).
('a11y.sort_key', RegExp(r'\bOrdinalSortKey\b|sortKey:'), 'lib/',
    'tree order is the traversal order; sortKey only sorts within one group — §3.9'),
('a11y.merge_semantics', RegExp(r'\bMergeSemantics\b'), 'lib/',
    'joins child labels with newlines and takes the first handler — §3.5'),
('a11y.material_picker', RegExp(r'showDatePicker\(|showTimePicker\('), 'lib/',
    'dial is a drag, keyboard mode is the system IME, cells are under 60 pt — §6.2'),
// 'd MMM y' and 'HH:mm' contain no slash or dot; 'dd/MM/yyyy' and 'd.M.y' do.
('copy.numeric_date', RegExp(r"DateFormat\.yMd\b|DateFormat\(\s*'[^']*[/.]"), 'lib/',
    'no all-numeric date a human reads — §9.2'),
('copy.literal_text', RegExp(r'''\b(Text|TextSpan)\(\s*['"]'''), 'lib/features/',
    'every user-facing string is an ARB message — §8.4'),
('copy.arb_domain_noun',
    RegExp(r'\b(ewes?|gimmers?|theaves?|shearlings?|hoggets?|tups?|wethers?)\b',
        caseSensitive: false), 'lib/l10n/',
    'a domain noun is a placeholder, never literal — §8.5'),
```

Three notes on scope, because each is a real edge:

- **`copy.literal_text` is scoped to `lib/features/` only.** `lib/core/ui/` components take their strings as parameters, `feedback.dart` builds its label from a `SaveReceipt`, and `night_error_panel.dart` must contain literal English. Those are reviewed by hand, and none of them needs an `[exempt]` line — the day-one allowlist stays at CONVENTIONS R56's **four** entries.
- **`copy.arb_domain_noun` is scoped to `lib/l10n/` and must skip the `term*Singular` / `term*Plural` messages**, which are the *only* place those words legitimately appear. Implement the skip in the rule, not in the allowlist.
- **Two driver amendments are required, and `01-architecture.md` must accept them.** (a) **The walker does not currently reach the ARB at all.** 01 §3.2's `main()` skips every file that does not end `.dart`, so `copy.arb_domain_noun` — and `05-domain-correctness.md` §7.3's `ContentPolicy` scan, which claims to cover "message values in `lib/l10n/*.arb`" — have nothing to run against. The amendment is one reader that walks `lib/l10n/*.arb`, decodes the JSON, and yields each non-`@`-prefixed message value as a string. It is a *separate* reader from the Dart one: JSON has no adjacent-string-literal problem, so 05's join-before-matching rule applies to the `.dart` half only and must not be copied onto the ARB half, where it would silently concatenate unrelated messages. (b) The generated `lib/l10n/app_localizations*.dart` must be added to the skip list alongside `*.g.dart` and `*.drift.dart`: it is generated, it is committed, its name matches neither existing skip pattern, and every rule that fires on it is firing on the ARB twice.

---

## 11. The consolidated anti-pattern list

Every row is a defect, not a preference.

| # | Banned | Caught by |
|---|---|---|
| 1 | `Semantics(header: true)` | `a11y.header_bool` + a per-screen `headingLevel > 0` test |
| 2 | `SemanticsService.announce` / `SemanticsService.sendAnnouncement` | `a11y.announce`, **once its pattern is widened to both spellings** (§10); it is a silent no-op on Android |
| 3 | A live-region label identical to its predecessor | `test/features/receipt_label_unique_test.dart` |
| 4 | A hidden character appended to make a live-region label "unique" | review — the fix is a more specific `summary` |
| 5 | `textScaleFactor`, anywhere, including the theme layer | `a11y.scale_factor` |
| 6 | `withClampedTextScaling` / `TextScaler.clamp` | `type.clamp` |
| 7 | A `TextScaler` subclass built inside `build()`, or without `==` | review — it invalidates every MediaQuery dependant |
| 8 | `FittedBox` around user-facing text | `type.fitted_box` |
| 9 | `FontWeight.w800` / `w900` | `type.weight_cap` — Bold Text renders them *lighter* |
| 10 | Reading only `disableAnimationsOf`, or only `reduceMotion` | review + the two-branch test in `test/design/` |
| 11 | Branching layout on `accessibleNavigation` | review — it is also true for sighted Switch Control users |
| 12 | `MergeSemantics` | `a11y.merge_semantics` |
| 13 | `OrdinalSortKey` / `sortKey:` | `a11y.sort_key` |
| 14 | `table` / `row` / `cell` roles on the pen board | review — the pens are a list; only the chart's table alternative uses them |
| 15 | A `CustomPaint` with no `semanticsBuilder` | review + the VoiceOver pass |
| 16 | The control type or the state inside a label (`'Save button'`, `'Pen 4, selected'`) | review |
| 17 | A semantics label that does not contain the visible words | review + the Voice Control pass |
| 18 | `SpellOutStringAttribute` over the whole label | review — "g-i-m-m-e-r" |
| 19 | A status encoded by colour alone | §7.2 row 6, grayscale |
| 20 | `showDatePicker` / `showTimePicker` | `a11y.material_picker` |
| 21 | A free-text date field | review — it is a §12.4 corruption vector |
| 22 | `DateFormat.yMd` or any all-numeric human date | `copy.numeric_date` |
| 23 | A string literal in a `Text(` under `lib/features/` | `copy.literal_text` |
| 24 | A domain noun literal in an ARB message | `copy.arb_domain_noun` |
| 25 | `intl: ^0.20.3` or any hand-pinned `intl` | `flutter pub get` fails; decision record §5 |
| 26 | `en_GB` first in `supportedLocales`, or leaving it unset | `test/features/locale_resolution_test.dart` |
| 27 | Pluralising by appending `s` | review — the map holds both forms |
| 28 | Placeholders named `singular` / `plural` | review — `plural` is an ICU keyword |
| 29 | Seeding terminology from `lib/domain/` or `lib/data/` | `layer.domain` / `layer.data` — neither may import `AppLocalizations` |
| 30 | Overwriting a user's term on a locale change or app update | review — it is safety rule 4 |
| 31 | `synthetic-package` in `l10n.yaml` | the flag cannot be enabled on 3.44 |
| 32 | `meetsGuideline` without `tester.ensureSemantics()` | review — the gate throws instead of asserting (decision #115) |
| 33 | `containsSemantics` in a new test | deprecated in 3.41; use `isSemantics` |
| 34 | `BackdropFilter`, frosted bars, scrims over text | `06-design-system.md` §2.5 — no reduced-transparency flag exists |
| 35 | `test/a11y/` | CONVENTIONS R57 — the test tree is fixed |

---

## Definition of done

Tick every line before calling this area finished.

**Platform flags**
- [ ] `prefersReducedMotion` exists in `lib/core/ui/motion.dart`, ORs both flags, and has a test per branch.
- [ ] No widget reads `accessibleNavigation`; no layout branches on any accessibility flag.
- [ ] `highContrastTheme` and `highContrastDarkTheme` hold a genuinely different palette, and the same palette is reachable from a Settings switch.
- [ ] No `BackdropFilter`, no translucent surface, anywhere.

**Semantics**
- [ ] Every `ShedTapTarget` in the app has a `semanticLabel` matching its visible words, and every enabled one exposes `SemanticsAction.tap`.
- [ ] Every one of the **14** variants emits at least one `headingLevel > 0` node; the hierarchy matches §3.4's table and invents no section `07-screens.md` does not render; `header:` appears nowhere.
- [ ] Every pen tile is one node whose label is a complete sentence, in row-major tree order, with a summary node first; asserted by `test/features/pen_board_traversal_test.dart`.
- [ ] Every keypad key, the pad container, the tag buffer and the match count carry the semantics in §3.6's table.
- [ ] The spread chart has all three layers: the visible summary sentence (**both** lines — §3.7's eight-placeholder message and `07-screens.md` §12.3's cycle line), `semanticsBuilder` per bar including zero-count days, and a working "View as table".
- [ ] `ShedCountdown` is constructed only from a `ClearsOn`; `NOT APPLICABLE` and `NOT RECORDED` are rendered by the treatment row with no countdown widget present (§5.2).
- [ ] `confirmSaved` produces a label that differs from its predecessor in the three collision tests, speaks the first warning when `warnings` is non-empty, and never calls `sendAnnouncement`.
- [ ] Tag ranges are spelled out; terms are not.

**Text and colour**
- [ ] `grep -rn "textScaleFactor" lib/ test/` returns nothing.
- [ ] `grep -rn "FittedBox\|withClampedTextScaling\|FontWeight.w800\|FontWeight.w900" lib/` returns nothing.
- [ ] The 252-cell overflow matrix is green, including the reachability assertion at the smallest device × 1.3.
- [ ] Every row of §5.2's redundancy table is readable under the OS grayscale filter, on a device, by a human.
- [ ] The SDK has been grepped for `kMinimumRatioNonText`; the non-text contrast check is either wired in or explicitly recorded as manual.

**Motor**
- [ ] The two tap-target gates (guideline + geometric) pass on all 14 variants, both with `tester.ensureSemantics()`.
- [ ] No `showDatePicker`, no `showTimePicker`, no free-text date field.
- [ ] Every action has a plain-button route; no gesture is the only route to anything.

**i18n**
- [ ] `l10n.yaml` matches §8.2 exactly; `flutter: generate: true` is set; `intl: any`.
- [ ] `supportedLocales` lists bare `Locale('en')` first; `test/features/locale_resolution_test.dart` passes all three cases.
- [ ] `lib/l10n/app_localizations*.dart` is committed and is in the gate's skip list.
- [ ] Every user-facing string under `lib/features/` is an ARB message; every ARB message has a description; the descriptions of the §12 strings state their safety rationale.
- [ ] No domain noun appears literally in any ARB message outside the `term*Singular` / `term*Plural` keys.
- [ ] `nAnimals` uses `singularTerm` / `pluralTerm` and `count` is `num`.
- [ ] All 40 seeded vocabulary keys have a matching ARB message; `test/policy/vocab_labels_are_complete_test.dart` passes.
- [ ] Terminology is seeded exactly once, from `lib/features/settings/terminology_bootstrap.dart`, and a locale change does not alter it — asserted by a test.
- [ ] `Disclaimers.*`, `ShedFailure.userMessage` and `RecordedTime.provenanceLabel` are **not** in the ARB, and §8.7's list has no seventh entry.
- [ ] The three files this document names and no sibling did exist at the paths it gives them: `lib/core/ui/tag_semantics.dart` (`spellOutTag`, §3.3), `lib/core/ui/formatters.dart`'s five `formatShed*` functions plus `ShedLocaleX` (§9.1), and `PenTile` / `PenTileStatus` in `lib/features/pens/pen_board_controller.dart` (§3.5). None of them is under `lib/core/ui/components/`, which CONVENTIONS §4.1 reserves for `shed_<thing>.dart`.

**Formatting**
- [ ] No human-facing date is all-numeric; the withdrawal countdown reads `11 Mar 2026`.
- [ ] CSV carries `date_iso` alongside `date_display`, and the five event-time columns.
- [ ] Every `DateFormat` is passed an explicit locale; none runs off the root isolate.
- [ ] Times are `HH:mm` everywhere and always carry a provenance label.

**Ship gate**
- [ ] Rows 1–10 of §7.2 are green on all 14 variants, on one small iPhone and one small Android, in a dark room.
- [ ] The seven Nutrition Label features in §7.1 are declared in App Store Connect; Captions and Audio Descriptions are left undeclared with the reason recorded.
- [ ] Re-evaluation of the labels is a line in the release checklist, not a memory.

**Still open, and not papered over**
- [ ] Decision record §7.1 #1 — the field night. It is the highest-value unresolved item in the project and it decides whether any of the 3am reasoning above is right.
- [ ] §7.1 #2 — ziplock-bag capacitance. If taps do not register through a bag, §6 is rewritten.
- [ ] §7.1 #11 — whether a temperature field ships at all, and therefore whether °C/°F formatting exists.
- [ ] §7.1 #15 — lambing ease 5 or 6, and therefore 40 or 41 vocabulary messages.
- [ ] §7.1 #18 — the voice-note cap, which bounds the Captions gap in §7.1.
- [ ] **UNVERIFIED:** whether 3.44's in-framework accessibility evaluations are public API (§5.3).
- [ ] **UNVERIFIED, owned by `06-design-system.md`:** whether `HapticFeedback.successNotification()` exists on Flutter 3.44.8 (CONVENTIONS §7 item 4). If it does not, the commit haptic degrades to `heavyImpact()` and nothing in this document changes.

**Cross-document defects this document raises — live**
- [ ] `06-design-system.md` §3.5's `a11y.announce` row is `RegExp(r'SemanticsService\.announce')`, which does not match `SemanticsService.sendAnnouncement`. Widen it to `RegExp(r'SemanticsService\.(announce|sendAnnouncement)\b')` (§10, §11 row 2). Until it lands, §11 row 2 overstates what CI proves.
- [ ] `01-architecture.md` §3.2's driver needs both amendments in §10: an ARB reader (its walker is `.dart`-only today, so `copy.arb_domain_noun` and `05-domain-correctness.md` §7.3's `ContentPolicy` ARB half currently scan nothing), and `lib/l10n/app_localizations*.dart` in the skip list.

**Cross-document defects this document previously raised — closed, verified, and recorded so nobody re-opens them**
- [x] `06-design-system.md` §10.3 now prints `confirmSaved(BuildContext, SaveReceipt, List<Warning>)` and names `showShedReceipt` / `showShedFailure` as banned spellings (R10, R30).
- [x] `06-design-system.md` §2.1 now declares `ShedBookApp extends ConsumerStatefulWidget` (R34).
- [x] `07-screens.md` §10.3 now renders `clear on 11 Mar 2026` (R60), and §18/§5.2 use `tagIndexProvider`, naming `flockTagCacheProvider` a banned spelling (R26).

CONVENTIONS R38's principle applies to this list: a doc set that records fictional conflicts trains readers to stop trusting the conflict list. Anything that moves from the first block to the second is **verified against the sibling file**, not assumed from a memory of having filed it.

---

## References

**W3C / WCAG**
- WCAG 2.2 quick reference — https://www.w3.org/WAI/WCAG22/quickref/
- WCAG2ICT (W3C Group Note, 11 Dec 2025) — https://www.w3.org/TR/wcag2ict/
- Understanding Use of Color (1.4.1) — https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html
- Understanding Contrast (Minimum) (1.4.3) — https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
- Understanding Target Size (Minimum) (2.5.8) — https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html

**Apple — the ship gate**
- Overview of Accessibility Nutrition Labels — https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/
- VoiceOver criteria (charts need a text alternative; no control types in labels) — https://developer.apple.com/help/app-store-connect/manage-app-accessibility/voiceover-evaluation-criteria/
- Voice Control criteria (labels match visible text) — https://developer.apple.com/help/app-store-connect/manage-app-accessibility/voice-control-evaluation-criteria/
- Larger Text criteria (200% or the system maximum; test at AX3 and AX5) — https://developer.apple.com/help/app-store-connect/manage-app-accessibility/larger-text-evaluation-criteria/
- Differentiate Without Color Alone criteria (the grayscale test) — https://developer.apple.com/help/app-store-connect/manage-app-accessibility/differentiate-without-color-alone-evaluation-criteria/
- Sufficient Contrast criteria — https://developer.apple.com/help/app-store-connect/manage-app-accessibility/sufficient-contrast-evaluation-criteria/
- Reduced Motion criteria — https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria/
- UI design tips (44 pt targets, 11 pt minimum text) — https://developer.apple.com/design/tips/

**Android / Google**
- App accessibility guide (48 dp targets; 4.5:1 below 18 sp) — https://developer.android.com/guide/topics/ui/accessibility/apps
- Accessibility help (48×48 dp separated by 8 dp; 48 dp ≈ 9 mm) — https://support.google.com/accessibility/android/answer/7101858
- Android 14 features (200% non-linear font scaling) — https://developer.android.com/about/versions/14/features
- Android 16 behaviour changes — announcements deprecated, `setAccessibilityLiveRegion` recommended — https://developer.android.com/about/versions/16/behavior-changes-all

**Flutter — breaking changes that bite this document**
- `header` / `headingLevel` behaviour change — https://docs.flutter.dev/release/breaking-changes/semantics-header-heading-level
- `textScaleFactor` deprecation — https://docs.flutter.dev/release/breaking-changes/deprecate-textscalefactor
- Android 14 non-linear text scaling migration — https://docs.flutter.dev/release/breaking-changes/android-14-nonlinear-text-scaling-migration
- Localized messages generated into source, not a synthetic package — https://docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source
- `containsSemantics` → `isSemantics` — https://docs.flutter.dev/release/breaking-changes/deprecate-contains-semantics
- Semantics order of overlay entries in modal routes — https://docs.flutter.dev/release/breaking-changes/modal-router-semantics-order
- 3.44 release notes (new accessibility evaluations) — https://docs.flutter.dev/release/release-notes/release-notes-3.44.0
- Internationalization guide — https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization

**Flutter API**
- `AccessibilityFeatures` — https://api.flutter.dev/flutter/dart-ui/AccessibilityFeatures-class.html
- `SemanticsRole` — https://api.flutter.dev/flutter/dart-ui/SemanticsRole.html
- `Semantics` — https://api.flutter.dev/flutter/widgets/Semantics/Semantics.html
- `SemanticsProperties.liveRegion` — https://api.flutter.dev/flutter/semantics/SemanticsProperties/liveRegion.html
- `SemanticsService.sendAnnouncement` — https://api.flutter.dev/flutter/semantics/SemanticsService/sendAnnouncement.html
- `MediaQueryData.supportsAnnounce` — https://api.flutter.dev/flutter/widgets/MediaQueryData/supportsAnnounce.html
- `MediaQuery.textScalerOf` / `TextScaler` — https://api.flutter.dev/flutter/widgets/MediaQuery/textScalerOf.html · https://api.flutter.dev/flutter/painting/TextScaler-class.html
- `MediaQueryData.lineHeightScaleFactorOverride` — https://api.flutter.dev/flutter/widgets/MediaQueryData/lineHeightScaleFactorOverride.html
- `SpellOutStringAttribute` — https://api.flutter.dev/flutter/dart-ui/SpellOutStringAttribute-class.html
- `CustomPainter.semanticsBuilder` / `CustomPainterSemantics` — https://api.flutter.dev/flutter/rendering/CustomPainter/semanticsBuilder.html · https://api.flutter.dev/flutter/rendering/CustomPainterSemantics-class.html
- `OrdinalSortKey` — https://api.flutter.dev/flutter/semantics/OrdinalSortKey-class.html
- `basicLocaleListResolution` — https://api.flutter.dev/flutter/widgets/basicLocaleListResolution.html
- `MaterialLocalizations.firstDayOfWeekIndex` — https://api.flutter.dev/flutter/material/MaterialLocalizations/firstDayOfWeekIndex.html
- `AccessibilityGuideline` / `SemanticsController` — https://api.flutter.dev/flutter/flutter_test/AccessibilityGuideline-class.html · https://api.flutter.dev/flutter/flutter_test/SemanticsController-class.html

**Flutter source read directly** (a 3.44 stable checkout; the pinned toolchain is **3.44.8 / Dart 3.12.2** per decision record §2.A #1, and §5 records the 3.44.x SDK pins as identical, so no symbol below is version-sensitive within 3.44)
- `engine/src/flutter/lib/ui/window.dart` — the `AccessibilityFeatures` bitfield
- `engine/src/flutter/shell/platform/darwin/ios/framework/Source/AccessibilityFeatures.swift`
- `engine/src/flutter/shell/platform/android/io/flutter/view/AccessibilityBridge.java` — `NO_ANNOUNCE` at :517, `disableAnimations` at :444–451, live region at :1106 and :2025, the `// NOT SUPPORTED` enum comments at :2472–2483, `boldText` at :3270
- `packages/flutter/lib/src/widgets/text.dart` :716–750 — the bold-text merge
- `packages/flutter/lib/src/widgets/app.dart` :146–235, :356 — `basicLocaleListResolution`, the `en_US` default
- `packages/flutter_localizations/pubspec.yaml` — the exact `intl` pin
- `packages/flutter_tools/lib/src/commands/generate_localizations.dart` — `synthetic-package` help text

**Flutter issues**
- #139712 (open) — Bold Text makes w800/w900 render *lighter*
- #177801 (open) — `boldText` ignores a custom `TextSpan` weight
- #10603 (closed) — iOS Smart Invert / `accessibilityIgnoresInvertColors` unexposed
- #67814, #36307 — GridView traversal under TalkBack
- PR #178102 — the three iOS motion features added in 3.44
- PR #183569 — non-text colour contrast evaluation (`kMinimumRatioNonText = 3.0`)
- PR #182872 — `UnlabeledLeafNodeEvaluation`

**Other**
- European Accessibility Act — the covered-product list — https://commission.europa.eu/strategy-and-policy/policies/justice-and-fundamental-rights/disability/union-equality-strategy-rights-persons-disabilities-2021-2030/european-accessibility-act_en
- National Sheep Association, *Terms to know* (why terminology is an overlay, not a taxonomy) — https://nationalsheep.org.uk/terms-to-know/
- `accessibility_tools` 2.8.0 — https://pub.dev/packages/accessibility_tools

**Sibling documents cited**
[`CONVENTIONS.md`](CONVENTIONS.md) · [`01-architecture.md`](01-architecture.md) · [`02-state-di-navigation.md`](02-state-di-navigation.md) · [`03-data-model-and-schema.md`](03-data-model-and-schema.md) · [`05-domain-correctness.md`](05-domain-correctness.md) · [`06-design-system.md`](06-design-system.md) · [`07-screens.md`](07-screens.md) · [`08-platform-integration.md`](08-platform-integration.md) · [`09-export-formats.md`](09-export-formats.md) · [`12-testing.md`](12-testing.md) · [`CODE-REVIEW-CHECKLIST.md`](CODE-REVIEW-CHECKLIST.md)

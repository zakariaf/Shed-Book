# 10 — Accessibility, semantics, and internationalisation groundwork

**Project:** Shed Book (offline-only lambing notebook, iOS + Android)
**Toolchain verified against:** Flutter **3.44** stable (the `stable` branch of `flutter/flutter` currently reports `flutter-3.44-candidate.0`), Dart 3.12.2
**Research date:** 2026-07-27
**Everything below was read off primary sources on the day.** Where a claim comes from reading framework/engine source, the file and line are given so you can re-verify with `curl`.

---

## Bottom line

| # | Decision | Confidence | Why (short) |
|---|---|---|---|
| 1 | Treat accessibility as **correctness for situational impairment**, not compliance. The 3am user *is* the low-vision, low-dexterity, one-handed user. | high | Every 3am-test constraint in spec §5 is a WCAG success criterion in disguise. |
| 2 | Target **WCAG 2.2 AA as interpreted by [WCAG2ICT](https://www.w3.org/TR/wcag2ict/)** (W3C Group Note, 11 Dec 2025), plus Apple's Accessibility Nutrition Label criteria. Skip web-only SC (2.4.1, 2.4.5, 3.2.3, 3.2.4). | high | WCAG2ICT is the only primary-source mapping of WCAG onto non-web software; EN 301 549 and Section 508 both lean on it. |
| 3 | **Apple's Accessibility Nutrition Labels are the real ship gate**, not WCAG. Declare VoiceOver, Larger Text, Sufficient Contrast, Differentiate Without Color Alone, Reduced Motion, Dark Interface, Voice Control. | high | Apple: voluntary "to start", then *"you'll be required to share accessibility support details to submit new apps and app updates"*. |
| 4 | **Never clamp text scale globally.** Allowed exceptions: `MediaQuery.withNoTextScaling` around icon fonts only. | high | Clamping silently overrides a user's OS setting; Apple's Larger Text criterion requires 200%+ to actually work. |
| 5 | Use **`TextScaler`**, never `textScaleFactor`. `MediaQueryData.textScaleFactor` is deprecated since 3.16. Size tap targets *from* `MediaQuery.textScalerOf(context).scale(...)`. | high | Verified on api.flutter.dev + the breaking-change page. |
| 6 | **`MediaQuery.disableAnimationsOf` is Android-only. `reduceMotion` is iOS-only and is NOT on `MediaQueryData`.** Write one `reduceMotion` resolver that ORs both. | high | Verified in engine source, both platforms — see the flag table below. This contradicts common Flutter advice. |
| 7 | **`SemanticsService.announce` is deprecated; `sendAnnouncement` is a no-op on Android** (`NO_ANNOUNCE` is set unconditionally). Announce "Saved" with a **`liveRegion`**, and make the label unique each time. | high | `AccessibilityBridge.java:517` sets `NO_ANNOUNCE` always; `:2025` only fires the live region when `didChangeLabel()`. |
| 8 | Adopt **`flutter_localizations` + gen-l10n/ARB on day one**, ship only `en`. Cost is ~2 hours; retrofit cost is a full-app string sweep. | high | Plurals, placeholders and date/number formats are the expensive part, and they are expensive *whether or not* you translate. |
| 9 | **`supportedLocales` must list bare `Locale('en')` FIRST, then `Locale('en','GB')`, `Locale('en','IE')`.** Order is load-bearing. | high | `basicLocaleListResolution` uses `languageLocales[code] ??= locale` (first wins) — putting `en_GB` first would give US users British formats. |
| 10 | **Never render an all-numeric date** (`13/07/2026`) anywhere a human reads it. Use `d MMM y` → `13 Jul 2026`. Numeric dates only inside CSV, with an ISO-8601 column. | high | Spec §12.5 demands honest timestamps; `07/13` vs `13/07` is a silent data-corruption vector. |
| 11 | `intl` must be constrained as **`intl: any`**, not `^0.20.3`. `flutter_localizations` 3.44 pins `intl: 0.20.2` **exactly**. | high | Read from `packages/flutter_localizations/pubspec.yaml` on stable. |
| 12 | **Terminology map is data, not strings.** No domain noun (ewe/gimmer/theave) ever appears literally in an ARB message; every such message takes the term as a placeholder. Store singular *and* plural in the map. | high | Agrees with topic 09's domain-side answer: user-owned vocabulary must never be overwritten by a locale change or an app update. |
| 13 | **Two themes, not four**: `darkTheme` (default) + `highContrastDarkTheme`. Ship a red-shift theme as a third user-selected `ThemeData`. Do not ship a light theme in v1 beyond the framework default. | medium | `MaterialApp.highContrastDarkTheme` is free plumbing; `highContrast` only ever fires on iOS today. |
| 14 | **Colour is never the only channel** on the pen board. Every status carries icon + text + position. Verified contrast ratios given below. | high | Apple's "Differentiate Without Color Alone" criterion + WCAG 1.4.1 (Level A). |
| 15 | Add **`accessibility_tools` 2.8.0 as a `dev_dependency`** (debug-only, no network), plus `meetsGuideline(...)` in widget tests. | medium | Catches unlabelled targets and sub-48dp taps automatically; compiles out of release. |
| 16 | **`Semantics(header: true)` is a no-op on iOS and Android as of 3.44.** Every section heading must use `headingLevel: 1..6`. Ban `header:` in review. | high | Breaking change shipped in 3.44 — see §3.9. It still compiles, so it fails silently. |
| 17 | Give the **Ewe Card and Season Summary a real heading hierarchy** (`headingLevel`). It is the screen-reader equivalent of the sighted "glance", and it is free. | high | Spec §7.7's one-line summary is the retention feature; a screen-reader user must be able to jump to it. |

---

## 1. Which rules actually apply, and to whom

### 1.1 WCAG 2.2 — applies, but through a translation layer

WCAG is written for web content. The W3C's own bridge document for native software is **WCAG2ICT**, published as a **W3C Group Note on 11 December 2025** ([w3.org/TR/wcag2ict](https://www.w3.org/TR/wcag2ict/)). It is explicit that it *"is not a standard — so it does not describe how non-web ICT should conform to it"*, but it is the substrate that EN 301 549 and US Section 508 are built on. It substitutes "web page" → "non-web document or software", and notes that in non-web software *"a separate user agent isn't needed — the software itself performs that function"* — which is why "User Agent Control" exceptions mostly evaporate for us.

Criteria that WCAG2ICT records as excluded by regulators for software: **2.4.1 Bypass Blocks, 2.4.5 Multiple Ways, 3.2.3 Consistent Navigation, 3.2.4 Consistent Identification** (and 2.4.2/3.1.2 for software per EN 301 549). Don't spend time on those.

The criteria that actually bite Shed Book, with exact numbers from [the WCAG 2.2 quick reference](https://www.w3.org/WAI/WCAG22/quickref/):

| SC | Level | Requirement | Where it bites Shed Book |
|---|---|---|---|
| 1.4.1 Use of Color | A | Colour is not the only visual means of conveying information | Pen board "ready to turn out"; withdrawal countdown; lamb alive/dead |
| 1.4.3 Contrast (Minimum) | AA | 4.5:1 text; 3:1 for large text (≥18pt, or ≥14pt bold) | Dark theme under a head torch |
| 1.4.4 Resize Text | AA | Text resizable to 200% without loss of content or function | Pen board grid, keypad, ewe card |
| 1.4.10 Reflow | AA | No two-dimensional scrolling at 320px-equivalent width | Pen board must collapse to a list at large scale |
| 1.4.11 Non-text Contrast | AA | 3:1 for UI components and meaningful graphics | Button borders, chart bars, pen-cell outlines |
| 1.4.12 Text Spacing | AA | Survive line-height 1.5×, para 2×, letter 0.12em, word 0.16em | See §4.4 — Flutter exposes this only on web today |
| 2.5.1 Pointer Gestures | A | All functionality via a simple pointer action | No swipe-to-delete, no drag foster, no pinch |
| 2.5.4 Motion Actuation | A | Motion-triggered functions have a control alternative | If you ever add shake-to-undo |
| 2.5.7 Dragging Movements | A | Drag operations have a single-pointer alternative | Pen board "move to pen" must not be drag-only |
| 2.5.8 Target Size (Minimum) | AA | 24×24 CSS px, or 24px-diameter non-intersecting spacing | Trivially met — spec mandates 60×60 |
| 2.5.5 Target Size (Enhanced) | AAA | 44×44 CSS px | Also met by 60×60 |
| 4.1.2 Name, Role, Value | A | Programmatically determinable name and role | The whole Semantics section below |
| 4.1.3 Status Messages | AA | Status announced without moving focus | The "Saved" announcement — §6.5 |
| 2.3.3 Animation from Interactions | AAA | Interaction-triggered motion can be disabled | Reduce-motion handling — §5.2 |

Note that spec §5's **60×60 pt** exceeds WCAG's AAA 44×44 and Android's 48dp. That's the right call and it is the single highest-leverage accessibility decision in the product.

### 1.2 EN 301 549 / European Accessibility Act — probably out of scope, but say so out loud

The [European Commission's EAA page](https://commission.europa.eu/strategy-and-policy/policies/justice-and-fundamental-rights/disability/union-equality-strategy-rights-persons-disabilities-2021-2030/european-accessibility-act_en) lists a **closed set** of covered products and services: computers and OSes, ATMs/ticketing machines, smartphones, TV equipment, telephony, audio-visual media services, passenger transport, banking services, e-books, and e-commerce. Member States had to transpose it **by June 2022**.

A farm-record app sold once for €10–15 is not on that list. **The EAA almost certainly does not apply to Shed Book itself** (the App Store, as an e-commerce service, is somebody else's problem). Ireland is in scope of the EAA as a jurisdiction; the UK is not, and is governed instead by the Equality Act 2010's general service-provision duties. Neither creates a specific mobile-app conformance obligation for this product.

**So: nothing legally forces this work. Do it anyway, because it is the same work as making the app usable at 3am.** Say this plainly in the engineering doc so nobody wastes a week producing a VPAT.

### 1.3 Apple — the actual gate

Apple ships **Accessibility Nutrition Labels** in App Store Connect. From [the overview](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/):

> "In order to give you time to prepare and evaluate your apps, providing these labels will be voluntary to start. However, … you'll be required to share accessibility support details to submit new apps and app updates to the App Store."

Declarable features: **VoiceOver, Voice Control, Larger Text, Dark Interface, Differentiate Without Color Alone, Sufficient Contrast, Reduced Motion, Captions, Audio Descriptions.** The bar for each is:

> "To indicate support for an accessibility feature in the Accessibility Nutrition Labels, users must be able to complete **all of the common tasks** of your app using that feature."

and "common tasks" is defined as *primary functionality + first launch experience + login + purchase + settings*. For Shed Book that means: **first run, the one-time purchase flow, Quick Entry, Lambing Entry, Pen Board, Treatments, and Settings** must each be completable with VoiceOver only, and with Voice Control only. Captions/Audio Descriptions are N/A (no video).

The specific criteria pages are worth reading in full and are the best single-source checklist we have:

- **Sufficient Contrast**: *"usually 4.5 to 1 for most text elements"*, *"Meeting a 3:1 minimum contrast ratio is commonly recommended for non-text contrast"*, and — importantly — *"Test with accessibility settings enabled: Bold Text, Increase Contrast, and Reduce Transparency"* in both light and dark mode. ([source](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/sufficient-contrast-evaluation-criteria/))
- **Larger Text**: *"You can indicate that your app supports Larger Text if users can enlarge text to at least 200% or the maximum font size for the system."* *"Avoid truncating text to the point that it becomes unreadable or ambiguous."* *"Avoid overlapping text."* *"Don't rely on system-provided assistive technology like Zoom or Hover Text to claim support."* Test at **AX3 and AX5**. ([source](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/larger-text-evaluation-criteria/))
- **Differentiate Without Color Alone**: *"try testing using the Grayscale color filter in Accessibility Display settings … If you can't use your own app in grayscale, rethink your app's design."* ([source](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/differentiate-without-color-alone-evaluation-criteria/))
- **VoiceOver**: *"Charts and other data visualizations should include accessibility information through a chart API, or include a reasonably complete text alternative."* Also: *"Ensure that labels don't include control types like 'checkbox' or states like 'checked.'"* ([source](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/voiceover-evaluation-criteria/))
- **Voice Control**: *"Match Voice Control labels to the visible text. If the Voice Control label is different from the visible text in your app … users may be confused."* ([source](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/voice-control-evaluation-criteria/))
- **Reduced Motion**: kill parallax, blur, depth-of-field, multi-axis/spin, auto-advancing carousels; replace meaningful motion with *"dissolve, highlight fade, color shift"*. ([source](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria/))

Apple's [UI design tips](https://developer.apple.com/design/tips/) restate the baselines: **44pt × 44pt minimum tap target**, **11pt minimum text**.

### 1.4 Google / Android

[Android's app accessibility guide](https://developer.android.com/guide/topics/ui/accessibility/apps): *"For touch interfaces, we recommend that each interactive UI element have a focusable area, or touch target size, of at least 48dp x 48dp."* Contrast: *"If the text is smaller than 18sp, or if the text is bold and smaller than 14sp, use foreground and background colors that result in a color contrast ratio of at least 4.5:1."* [Google's accessibility help](https://support.google.com/accessibility/android/answer/7101858) adds the spacing rule: *"at least 48x48dp, separated by 8dp of space or more"*, and notes 48dp ≈ **9mm physical**.

Android 14 raised the font-scale ceiling to **200%** with a **nonlinear curve** so large text grows less than small text ([Android 14 features](https://developer.android.com/about/versions/14/features)); *"the scaledDensity field is no longer accurate"*. Android also has an independent **Display size** (density) setting — a layout must survive `fontScale = 2.0` **and** the largest display size **simultaneously**, which is where dense grids die.

### 1.5 The user this actually serves

The Shed Book user at 03:20 is, functionally:

- **low vision** (head torch, no reading glasses — glasses are in the house);
- **low dexterity** (cold hands, one thumb, gloves or a freezer bag → poor capacitance, imprecise contact);
- **cognitively loaded** (eleven nights in, holding a lamb);
- **in a hostile lighting environment** (pitch dark → 800-lumen white spot → pitch dark).

Every one of those maps to a permanent-disability accommodation. The correct framing for the engineering doc is: *we are not adding accessibility features for other people; we are building the app for the 3am user, and the accessibility APIs are how we do that.* The permanent-disability users come along for free.

---

## 2. Verified platform truth table — which flags actually work

This is the section most likely to contradict what you have read elsewhere. **All of it was read out of the Flutter 3.44 stable tree today.**

`dart:ui`'s `AccessibilityFeatures` bitfield ([`engine/src/flutter/lib/ui/window.dart`](https://github.com/flutter/flutter/blob/stable/engine/src/flutter/lib/ui/window.dart), ~lines 928–1010):

```
accessibleNavigation  1<<0
invertColors          1<<1
disableAnimations     1<<2
boldText              1<<3   // "Only supported on iOS and Android API 31+."
reduceMotion          1<<4   // "Only supported on iOS."
highContrast          1<<5   // "Only supported on iOS."
onOffSwitchLabels     1<<6   // "Only supported on iOS."
noAnnounce            1<<7   // supportsAnnounce == (noAnnounce bit clear)
noAutoPlayAnimatedImages 1<<8    // iOS only
noAutoPlayVideos         1<<9    // iOS only
deterministicCursor      1<<10   // iOS only
```

**iOS** — [`shell/platform/darwin/ios/framework/Source/AccessibilityFeatures.swift`](https://github.com/flutter/flutter/blob/stable/engine/src/flutter/shell/platform/darwin/ios/framework/Source/AccessibilityFeatures.swift):

| Flutter flag | iOS source | Set? |
|---|---|---|
| `accessibleNavigation` | `UIAccessibility.isVoiceOverRunning` **OR** `isSwitchControlRunning` | ✅ |
| `invertColors` | `isInvertColorsEnabled` | ✅ |
| `boldText` | `isBoldTextEnabled` | ✅ |
| `reduceMotion` | `UIAccessibility.isReduceMotionEnabled` | ✅ |
| `highContrast` | `isDarkerSystemColorsEnabled` (Settings ▸ Accessibility ▸ Increase Contrast) | ✅ |
| `onOffSwitchLabels` | `isOnOffSwitchLabelsEnabled` | ✅ |
| **`disableAnimations`** | — | ❌ **never set on iOS** |
| `noAnnounce` | — | not set ⇒ `supportsAnnounce == true` |

**Android** — [`shell/platform/android/io/flutter/view/AccessibilityBridge.java`](https://github.com/flutter/flutter/blob/stable/engine/src/flutter/shell/platform/android/io/flutter/view/AccessibilityBridge.java):

| Flutter flag | Android source | Set? |
|---|---|---|
| `accessibleNavigation` | touch exploration enabled (TalkBack) | ✅ |
| `disableAnimations` | `Settings.Global.TRANSITION_ANIMATION_SCALE == 0` (line 444–451) | ✅ |
| `boldText` | API 31+ `Configuration.fontWeightAdjustment >= 300` (line 3270) | ✅ |
| `noAnnounce` | set **unconditionally** at line 517 ⇒ `supportsAnnounce == false` | ✅ |
| `invertColors` / `reduceMotion` / `highContrast` / `onOffSwitchLabels` | enum comments literally say `// NOT SUPPORTED` (lines 2472–2483) | ❌ |

### Consequences you must code around

1. **There is no cross-platform "reduce motion" flag.** iOS never sets `disableAnimations`; Android never sets `reduceMotion`; and `MediaQueryData` has **no `reduceMotion` property at all** (see the property list at `widgets/media_query.dart:225–239`). Write one resolver:

```dart
/// The only correct cross-platform reduce-motion check on Flutter 3.44.
///
/// * Android reports reduce-motion as `disableAnimations`
///   (Settings.Global.TRANSITION_ANIMATION_SCALE == 0).
/// * iOS reports it as `reduceMotion` and never sets `disableAnimations`.
///
/// Depending on `MediaQuery.disableAnimationsOf` also makes this rebuild:
/// `_MediaQueryFromView` implements `didChangeAccessibilityFeatures`, so any
/// accessibility-flag change (including reduceMotion) invalidates MediaQuery.
bool prefersReducedMotion(BuildContext context) {
  final bool androidFlag = MediaQuery.disableAnimationsOf(context);
  final bool iosFlag =
      View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;
  return androidFlag || iosFlag;
}
```

2. **`accessibleNavigation` is not "a screen reader is running".** On iOS it is also true for **Switch Control** users, who are sighted. Never use it to swap in a text-only layout or to suppress visual affordances. Use it only for what Flutter itself uses it for — e.g. `SnackBar` does not auto-dismiss when it is true (`material/snack_bar.dart:624`, `:851`).

3. **`highContrast` is iOS-only.** `MaterialApp.highContrastDarkTheme` will never engage on Android. If you want a high-contrast option on Android, it must be an in-app setting.

4. **There is no reduced-transparency flag in Flutter 3.44.** `UIAccessibility.isReduceTransparencyEnabled` is not exposed anywhere in `AccessibilityFeatures`. The author of [PR #178102](https://github.com/flutter/flutter/pull/178102) (which added `autoPlayAnimatedImages`, `autoPlayVideos`, `deterministicCursor` in 3.44) considered seven features and shipped three. **Mitigation for Shed Book: don't ship translucency in the first place.** No frosted-glass app bars, no `BackdropFilter`, no scrims over content. A shed at night has no aesthetic budget for blur, and every blur is a contrast reduction you can't detect or undo.

---

## 3. Semantics in Flutter

### 3.1 What you get for free

Material/Cupertino widgets already emit a semantics tree: `ElevatedButton`/`TextButton`/`IconButton` get the `button` flag and take their label from their child `Text` (or from `IconButton.tooltip`); `TextField` gets `textField` + `value` + `hint`; `AppBar.title` gets `header` (**which on 3.44 no longer does anything on iOS or Android — see §3.9**); routes get `scopesRoute`/`namesRoute`; `SnackBar` is wrapped in `Semantics(container: true, liveRegion: true, onDismiss: …)` (`material/snack_bar.dart:828`); `Text` applies `MediaQuery.boldTextOf` and `MediaQuery.textScalerOf` automatically (`widgets/text.dart:722`, `:746`).

What you get for *nothing*: `Container`, `GestureDetector` without semantic callbacks, `CustomPaint` without `semanticsBuilder`, `Icon` without `semanticLabel`, and any bespoke tap surface. Those are exactly the widgets a hand-built pen board and keypad are made of.

### 3.2 The API surface, as of 3.44

`Semantics` has ~64 named parameters. The ones that matter here (verified against [`Semantics.new`](https://api.flutter.dev/flutter/widgets/Semantics/Semantics.html)):

- **Naming**: `label`, `attributedLabel`, `value`, `attributedValue`, `hint`, `attributedHint`, `tooltip`, `increasedValue`, `decreasedValue`
- **Role/flags**: `button`, `headingLevel` (**use this, not `header` — §3.9**), `image`, `textField`, `link`, `selected`, `checked`, `toggled`, `enabled`, `expanded`, `isRequired`, `hidden`, `liveRegion`
- **Role enum**: `role: SemanticsRole?` — 33 values including `table`, `row`, `cell`, `columnHeader`, `list`, `listItem`, `status`, `alert`, `form`, `progressBar`, `dialog`, `alertDialog`, `menu` ([`SemanticsRole`](https://api.flutter.dev/flutter/dart-ui/SemanticsRole.html))
- **Structure**: `container`, `explicitChildNodes`, `excludeSemantics`, `blockUserActions`, `sortKey`, `identifier`, `traversalParentIdentifier`, `traversalChildIdentifier`, `localeForSubtree`
- **Actions**: `onTap`, `onLongPress`, `onIncrease`, `onDecrease`, `onDismiss`, `customSemanticsActions`, `onTapHint`, `onLongPressHint`

Structural helpers: `MergeSemantics` (fold a subtree into one node — *"if two nodes in the subtree have conflicting semantics, the result may be nonsensical"*, and *"all labels merge into one string separated by newlines"*), `ExcludeSemantics` (*"drops all the semantics of its descendants"*), `BlockSemantics` (*"drops semantics of widgets earlier in the tree"*), and `Text(semanticsLabel:)` for a per-string override (`const Text(r'$$', semanticsLabel: 'Double dollars')`).

**Spell-out attribute — use this for tag numbers.** `SpellOutStringAttribute({required TextRange range})` *"causes the assistive technologies, e.g. VoiceOver, to spell out the string character by character."* Ewe **412** should be read "four one two", not "four hundred and twelve" — because that is what the shepherd calls her and what is written on the tag.

```dart
AttributedString tagLabel(String term, String tag) {
  final String text = '$term $tag';
  return AttributedString(
    text,
    attributes: <StringAttribute>[
      SpellOutStringAttribute(
        range: TextRange(start: term.length + 1, end: text.length),
      ),
    ],
  );
}
```

### 3.3 Labels: Apple's rules are the right rules

From Apple's VoiceOver criteria, restated as house rules:

1. **Never put the control type in the label.** `label: 'Save'`, not `label: 'Save button'` — Flutter already emits the `button` role.
2. **Never put state in the label.** Use `selected:`/`checked:`/`toggled:`/`expanded:`, not `label: 'Pen 4, selected'`.
3. **Labels must survive out of order.** No "Tap here", no "More".
4. **Labels must match the visible text** (Voice Control criterion). If the button reads "Turn out", the label is "Turn out". Where there is no visible text (an icon-only button), the label is the noun-verb a person would say.
5. **Concise.** "New lambing", not "Press to record a new lambing event".
6. **Decorative images get `ExcludeSemantics`**, not an empty label.

`hint` is for *what activation does when it isn't obvious*, and it is spoken after a pause. Use it sparingly — at 3am a chatty screen reader is a worse experience than a terse one.

### 3.4 Hard case A — the pen board grid

**The problem.** A 2-D grid of pens is the one layout where linear screen-reader traversal loses the information. Swiping through 24 unlabelled cells tells you nothing; and Flutter's own traversal for grids has a long tail of issues (e.g. [#67814](https://github.com/flutter/flutter/issues/67814) FocusTraversal glitches in GridView, [#36307](https://github.com/flutter/flutter/issues/36307) cells not fully revealed on TalkBack swipe). Note the historical issue "[Semantics traversal order needs to be implemented on iOS engine](https://github.com/flutter/flutter/issues/14570)" is **closed**, but `sortKey` remains a blunt instrument: `OrdinalSortKey` sorts *only among siblings inside the same semantics group*, and *"all the other specified sort keys in the same semantics group must also be OrdinalSortKeys"*.

**The decision: do not fight the grid. Make each cell self-describing, and give the screen reader a linear list.**

Three-part answer:

1. **Each cell is one merged node whose label is a complete sentence.** Not "Pen 4" + "412" + "26h" as three nodes — one node: *"Pen 4. Gimmer 412. Penned 26 hours. Ready to turn out."* This is what makes swipe-through navigation usable and it is also, not coincidentally, what makes the cell readable from arm's length.
2. **Give the board `SemanticsRole.list` and cells `SemanticsRole.listItem`**, not `table`/`row`/`cell`. The pens are an unordered collection of independent facts, not a matrix with meaningful columns. `table` invites a screen reader to offer row/column navigation that has no meaning here.
3. **Row-major visual order is the traversal order.** Build the grid with a `Column` of `Row`s (or `GridView` with `explicitChildNodes`) so the natural tree order already matches reading order; then you need no `sortKey` at all. Reserve `sortKey` for the one place it's needed: pinning a "board summary" node before the cells.

```dart
/// One pen cell. Visually: a big colour block with an icon, a tag and a timer.
/// Semantically: a single list item with one complete sentence.
class PenCell extends StatelessWidget {
  const PenCell({super.key, required this.pen, required this.terms});

  final PenView pen;          // pen.label, pen.tag, pen.hours, pen.status
  final TerminologyMap terms; // user-owned nouns — see §9

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String term = terms.singularFor(pen.animalClass); // "gimmer"

    // One sentence, in the order a shepherd would say it.
    final String sentence = <String>[
      l10n.penNamed(pen.label),                       // "Pen 4"
      '$term ${pen.tag}',                             // "gimmer 412"
      l10n.pennedForHours(pen.hours),                 // "penned 26 hours"
      if (pen.status == PenStatus.readyToTurnOut)     // status LAST, and only
        l10n.readyToTurnOut,                          //   when it is true
      if (pen.status == PenStatus.underWithdrawal)
        l10n.underWithdrawal,
    ].join('. ');

    return Semantics(
      container: true,
      explicitChildNodes: false, // fold the visual children into this node
      role: SemanticsRole.listItem,
      button: true,
      label: sentence,
      onTapHint: l10n.hintOpenPen, // "open pen"
      child: ExcludeSemantics(
        child: InkWell(
          onTap: () => openPen(context, pen),
          child: _PenCellVisuals(pen: pen, term: term),
        ),
      ),
    );
  }
}
```

Two subtleties in that snippet:

- `ExcludeSemantics` around the visuals, with the label supplied on the parent, is more predictable than `MergeSemantics` — merging concatenates child labels *with newlines* and takes the first gesture handler, which is fragile when the cell later grows a badge.
- `onTapHint` sets the verb VoiceOver appends to the activation gesture, so the user hears "…double tap to open pen" rather than "double tap to activate".

**At ≥200% text scale, the grid must stop being a grid.** WCAG 1.4.10 Reflow forbids 2-D scrolling. Decide the column count from the scaled text, not from the raw screen width:

```dart
int penColumns(BuildContext context) {
  final TextScaler scaler = MediaQuery.textScalerOf(context);
  final double width = MediaQuery.sizeOf(context).width;
  // A cell must fit the longest tag at the current scale, plus the timer,
  // plus 60pt of touch slop, and never be narrower than 60pt.
  final double minCellWidth = math.max(60.0, scaler.scale(20.0) * 6.5);
  return math.max(1, (width / minCellWidth).floor());
}
```

At AX5 this naturally degrades to one column — which is a vertical list, which is exactly what a screen-reader user wanted anyway. One layout, two audiences.

### 3.5 Hard case B — the giant numeric keypad

The keypad is the single most important control in the app, and it is the one most likely to be built out of `GestureDetector` and therefore be invisible to assistive tech.

Rules:

- Each key is `Semantics(button: true, label: '<digit>')` — the label is the digit, matching the visible glyph (Voice Control criterion). Do **not** label it "Seven key" or "Digit seven".
- Wrap the digit `Text` in `ExcludeSemantics` so the digit isn't announced twice.
- The delete key is `label: <l10n.deleteDigit>` ("Delete") with `onTapHint` "delete last digit". It must **not** be long-press-only for "clear all"; provide a separate visible Clear button (WCAG 2.5.1, and spec §5 "no long-press-only actions").
- The whole pad is `Semantics(container: true, explicitChildNodes: true, label: <l10n.tagKeypad>)` so a VoiceOver user hears what they've landed in.
- The current tag buffer is a **live region** so that each keypress is confirmed (see §3.6) — otherwise a blind user has no idea what they've typed.
- The filtered-results count is a second live region: *"3 matches"*.

Sizing that survives text scale without clamping:

```dart
/// A keypad key that grows with the user's text size instead of clipping.
class KeypadKey extends StatelessWidget {
  const KeypadKey({super.key, required this.digit, required this.onPressed});

  final String digit;
  final VoidCallback onPressed;

  /// Spec §7.1: digits at least 40pt. Spec §5: targets at least 60x60pt.
  static const double _baseDigitSize = 44.0;
  static const double _minTarget = 60.0;

  @override
  Widget build(BuildContext context) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double glyph = scaler.scale(_baseDigitSize);
    // The key box tracks the glyph; it never shrinks below the 3am minimum.
    final double side = math.max(_minTarget, glyph * 1.6);

    return Semantics(
      button: true,
      label: digit,
      child: ExcludeSemantics(
        child: SizedBox(
          width: side,
          height: side,
          child: InkResponse(
            onTap: () {
              HapticFeedback.selectionClick();
              onPressed();
            },
            child: Center(
              child: Text(
                digit,
                // No textScaler override here: Text already reads
                // MediaQuery.textScalerOf. The BOX grew to match.
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

The keypad is allowed to consume more of the screen as text grows; the flock list above it scrolls. **Do not** solve keypad overflow with `FittedBox` — that visually undoes the user's font-size setting and will fail Apple's Larger Text criterion.

### 3.6 Hard case C — the season-summary bar chart

Apple is unambiguous: *"Charts and other data visualizations should include accessibility information through a chart API, or include a reasonably complete text alternative."* Flutter has no chart API, so we owe a text alternative.

Two layers, both required:

**Layer 1 — a summary sentence, always present, always visible.** Not a tooltip, not a screen-reader-only string: a real line of text under the chart. The 3am user with no glasses cannot read a 30-bar chart either.

> "Lambing spread, 14 March to 2 April. 132 lambs over 20 days. Busiest day 21 March, 19 lambs. First day 14 March, 3 lambs. Last day 2 April, 1 lamb."

**Layer 2 — per-bar semantics via `CustomPainter.semanticsBuilder`.** `CustomPainter` exposes `SemanticsBuilderCallback? get semanticsBuilder => null;` and returns `List<CustomPainterSemantics>`, each `CustomPainterSemantics({Key? key, required Rect rect, required SemanticsProperties properties, Matrix4? transform, Set<SemanticsTag>? tags})`. When non-null, *"the CustomPaint corresponding to this painter will not create a semantics boundary"* is inverted — it **does** create one and contributes nodes.

```dart
class SpreadChartPainter extends CustomPainter {
  SpreadChartPainter({required this.days, required this.strings});

  final List<DayCount> days;      // date + lamb count
  final SpreadChartStrings strings; // pre-localised label builders

  @override
  void paint(Canvas canvas, Size size) { /* bars */ }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (Size size) {
        final double barWidth = size.width / days.length;
        final int max = days.fold(0, (a, d) => math.max(a, d.count));
        return <CustomPainterSemantics>[
          for (int i = 0; i < days.length; i++)
            CustomPainterSemantics(
              key: ValueKey<DateTime>(days[i].date),
              rect: Rect.fromLTWH(i * barWidth, 0, barWidth, size.height),
              properties: SemanticsProperties(
                // "21 March, 19 lambs" — never "bar 7 of 20".
                label: strings.barLabel(days[i].date, days[i].count),
                // value/increasedValue give VoiceOver a rotor-friendly reading
                value: strings.lambCount(days[i].count),
                role: SemanticsRole.listItem,
              ),
            ),
        ];
      };

  @override
  bool shouldRepaint(SpreadChartPainter old) => old.days != days;

  @override
  bool shouldRebuildSemantics(SpreadChartPainter old) => old.days != days;
}
```

**Also provide a plain table.** A "View as table" button next to the chart, rendering date/count rows with `SemanticsRole.table`/`row`/`cell`. That single button satisfies WCAG 1.4.1, the VoiceOver criterion, and the shepherd who just wants the numbers — and it costs a day.

### 3.7 Live regions and the "Saved" announcement — the part everyone gets wrong

**`SemanticsService.announce` is deprecated** ("after v3.35.0-0.1.pre"): *"Use sendAnnouncement instead. This API is incompatible with multiple windows."* And `sendAnnouncement` itself is discouraged: *"Check to see if it is supported using MediaQuery.supportsAnnounceOf before calling this method."*

**On Android, `supportsAnnounce` is always false.** `AccessibilityBridge.java:517` sets `NO_ANNOUNCE` unconditionally at construction. The `dart:ui` doc explains why: *"Android discourages the uses of direct message announcement, and rather encourages using other semantic properties such as `SemanticsProperties.liveRegion` to convey message to the user."*

That is not a Flutter opinion — it is Android platform policy, and it is worth quoting from the source so nobody "fixes" it later. From [Android 16 behavior changes (all apps)](https://developer.android.com/about/versions/16/behavior-changes-all):

> "Android 16 deprecates accessibility announcements, characterized by the use of `announceForAccessibility` or the dispatch of `TYPE_ANNOUNCEMENT` accessibility events. These can create inconsistent user experiences for users of TalkBack and Android's screen reader, and alternatives better serve a broader range of user needs across a variety of Android's assistive technologies."

Android's own recommended replacements map exactly onto what this document prescribes: `setAccessibilityPaneTitle` for window-level changes, **`setAccessibilityLiveRegion` for "changes to critical UI"** — which is what `Semantics(liveRegion: true)` compiles down to — and error events for validation failures. So the Flutter-side and platform-side answers agree: **the save confirmation is a live region, on both platforms, permanently.** This is not a workaround for a Flutter gap; it is the sanctioned API.

So the "every write commits immediately" confirmation (spec §5) must be a **live region**:

```dart
/// Persistent save confirmation on Quick Entry.
/// Visible AND announced. Not a SnackBar: SnackBars steal the bottom thumb
/// zone, time out, and are the wrong shape for a one-handed 3am flow.
class SaveConfirmation extends StatelessWidget {
  const SaveConfirmation({super.key, required this.receipt});

  final SaveReceipt? receipt;

  @override
  Widget build(BuildContext context) {
    if (receipt == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    // CRITICAL: the label must differ from the previous one, or Android will
    // not re-announce. AccessibilityBridge only fires the live region when
    // `object.hasFlag(IS_LIVE_REGION) && object.didChangeLabel()`.
    // Including the tag AND the wall-clock time guarantees uniqueness.
    final String message = l10n.savedReceipt(
      receipt!.term,                 // "gimmer"
      receipt!.tag,                  // "412"
      receipt!.summary,              // "twins, ease 2"
      receipt!.at,                   // 03:22
    );

    return Semantics(
      liveRegion: true,
      role: SemanticsRole.status,
      container: true,
      child: _ConfirmationBanner(message: message),
    );
  }
}
```

Caveats to write into the code review checklist:

- `liveRegion` on Android maps to `View.ACCESSIBILITY_LIVE_REGION_POLITE` (`AccessibilityBridge.java:1106`) and only re-fires on **label change**.
- The framework itself warns: *"This announcement may not be spoken if the OS accessibility services are already announcing something else"* — so the confirmation must also be **visible and persistent**, not transient. Two saves in ten seconds is normal during triplets.
- If you *do* need a one-shot announcement (e.g. "Free tier limit reached"), guard it:

```dart
if (MediaQuery.supportsAnnounceOf(context)) {
  SemanticsService.sendAnnouncement(
    View.of(context), message, Directionality.of(context),
  );
}
```
It will fire on iOS and be a silent no-op on Android — which is why you must never rely on it for anything load-bearing.

### 3.8 Semantic ordering

- **Prefer tree order.** Build widgets in reading order and you need no sort keys.
- `sortKey: OrdinalSortKey(n)` only reorders **siblings within one semantics group**, and *"all the other specified sort keys in the same semantics group must also be OrdinalSortKeys"*. Mixing is a silent bug.
- Use `traversalParentIdentifier` / `traversalChildIdentifier` (3.44) for content that lives in an `OverlayPortal` but logically belongs inside a card — e.g. the pen-action sheet. Each `traversalParentIdentifier` must be unique.
- Modal ordering changed in a past release; see [Semantics Order of the Overlay Entries in Modal Routes](https://docs.flutter.dev/release/breaking-changes/modal-router-semantics-order). Test any bottom sheet with VoiceOver before shipping.

### 3.9 Headings — and the 3.44 breaking change that silently disables them

**This landed in the exact SDK this project targets and it fails silently, so it is the single most likely accessibility regression in the codebase.**

From [Update semantics header and headingLevel behavior on iOS and Android](https://docs.flutter.dev/release/breaking-changes/semantics-header-heading-level) (landed 3.45.0-0.1.pre, listed against **3.44** on the [breaking-changes index](https://docs.flutter.dev/release/breaking-changes)):

> The `header` property is now a **no-op on iOS and Android** (it remains in the API for future use). Setting `headingLevel` to any value **greater than 0** now maps to `View.setHeading(true)` on Android and to `UIAccessibilityTraitHeader` / `accessibilityHeadingLevel` (iOS 13+) on iOS.

The rationale is a genuine semantic mismatch: "header" in Flutter usually means an app bar or banner, whereas `setHeading`/`UIAccessibilityTraitHeader` mean a *section heading*.

```dart
// WRONG on 3.44 — compiles, passes review, does nothing on either platform.
Semantics(header: true, child: Text('In the pens'))

// RIGHT
Semantics(headingLevel: 1, child: Text('In the pens'))
```

**Why this matters more here than in a typical app.** Spec §7.7 makes the Ewe Card the retention feature, and its one-line summary — *"3 seasons · avg 2.0 · assisted twice · prolapsed 2025"* — is explicitly meant to be *visible before anything else*. For a sighted user that is a glance. For a VoiceOver/TalkBack user the only equivalent is heading navigation: the rotor set to Headings, one flick, straight to the summary. Without `headingLevel`, that user swipes through every field on the card to reach it, and the retention feature is gone.

Heading hierarchy to implement:

| Screen | `headingLevel: 1` | `headingLevel: 2` |
|---|---|---|
| Ewe Card | the ewe's term + tag ("Gimmer 412") | "Summary", "This season", "Previous seasons", "Treatments", "Notes" |
| Season Summary | "Season 2026" | "Lambing percentage", "Losses", "Lambing spread" |
| Pen Board | "Pen board" | — (the board is a list, §3.4) |
| Treatments | "Medicine book" | "Active withdrawals", "History" |
| Settings | "Settings" | each settings group |

Quick Entry deliberately gets **no** headings below level 1: it is one task, and heading stops would only add navigation to a screen whose whole purpose is not having any.

**Enforcement.** Add a CI grep banning `header:` inside `Semantics(`/`SemanticsProperties(`, and a widget test per screen asserting at least one node with `headingLevel > 0`. Also note the related deprecation in 3.41 — [`containsSemantics` → `isSemantics`](https://docs.flutter.dev/release/breaking-changes/deprecate-contains-semantics) — which affects the matchers in §12.1; write new tests with `isSemantics` from the start.

---

## 4. Text scaling

### 4.1 The current API — `TextScaler`, not `textScaleFactor`

`textScaleFactor` was deprecated in **Flutter 3.16** (landed 3.13.0-4.0.pre) in favour of `TextScaler`, to support Android 14's nonlinear curve. `MediaQueryData.textScaleFactor` is marked *"Deprecated. Will be removed in a future version of Flutter. Use textScaler instead."*

```dart
abstract class TextScaler {
  const TextScaler();
  factory TextScaler.linear(double textScaleFactor);
  double scale(double fontSize);
  TextScaler clamp({double minScaleFactor = 0, double maxScaleFactor = double.infinity});
  double get textScaleFactor; // deprecated, "will be removed in a future version"
  static const TextScaler noScaling = _LinearTextScaler(1.0);
}
```

Migration table (from the [breaking-change page](https://docs.flutter.dev/release/breaking-changes/deprecate-textscalefactor)):

| Old | New |
|---|---|
| `MediaQuery.textScaleFactorOf(context)` | `MediaQuery.textScalerOf(context)` |
| `style.fontSize * MediaQuery.textScaleFactorOf(context)` | `MediaQuery.textScalerOf(context).scale(style.fontSize)` |
| `RichText(textScaleFactor: …)` | `RichText(textScaler: …)` |
| `copyWith(textScaleFactor: 1.0)` | `MediaQuery.withNoTextScaling(child: …)` |
| `copyWith(textScaleFactor: min(x, k))` | `MediaQuery.withClampedTextScaling(maxScaleFactor: k, child: …)` |

**Rule for this codebase: `textScaleFactor` must not appear anywhere.** Add a lint/grep in CI.

### 4.2 Why clamping is a bug (and the one place it isn't)

The pattern you will find on Stack Overflow —

```dart
// DO NOT DO THIS.
MediaQuery(
  data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.2)),
  child: child,
)
```

— is wrong here for three separate reasons:

1. It **overrides the user's OS setting**, which is precisely the setting a shepherd who left their reading glasses in the house has turned up.
2. It **fails Apple's Larger Text criterion**: *"users can enlarge text to at least 200% or the maximum font size for the system"*. Clamping at 1.3× means you cannot honestly declare Larger Text support.
3. It **breaks Android 14 nonlinear scaling**, because `TextScaler.linear` throws away the curve.

The narrow, sanctioned exception is Flutter's own: `MediaQuery.withNoTextScaling` around **icon fonts and fixed-geometry glyph art**, where "scaling" would just make an icon overlap its own bounding box. Even then, the *target* around the icon must still be ≥60pt.

There is a second exception worth debating and rejecting: the pen board at AX5. The temptation is `withClampedTextScaling(maxScaleFactor: 1.5)` so 24 pens still fit. **Reject it.** The right answer is reflow (§3.4): fewer columns, then one column, then a list. The board stops being glanceable at AX5 — but a user at AX5 was never going to read a 24-cell grid from arm's length anyway.

### 4.3 Layout patterns that survive 200%+

Test matrix: `fontScale ∈ {1.0, 1.3, 2.0}` × `display size ∈ {default, largest}` × `{portrait}` on a small device (5.4"/iPhone 13 mini class). That's six configurations; run them as golden tests.

Patterns that hold:

| Pattern | Instead of |
|---|---|
| `Wrap` for chip rows and the lambing-ease 1–5 row | `Row` with `Expanded` |
| `Column` + `SingleChildScrollView` for every form | fixed-height `Card` |
| `ConstrainedBox(minHeight:)` + intrinsic height | `SizedBox(height: 56)` |
| Label **above** value | label-left / value-right two-column rows |
| `Flexible` + `softWrap: true` + `maxLines: null` | `maxLines: 1, overflow: TextOverflow.ellipsis` |
| Icon **and** text stacked vertically in a button | icon+text in a `Row` |
| `LayoutBuilder` deciding grid columns from *scaled* metrics (§3.4) | `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4)` |
| `Baseline`-free layout | manual `Padding` tuned to one font size |

Two specific hazards in this app:

- **Ellipsised free-text notes.** Apple: *"Avoid truncating text to the point that it becomes unreadable or ambiguous … Consider allowing the text to wrap to two or more lines instead."* Notes on the ewe card must wrap, not ellipsise. If you must truncate in a list, the full text must be reachable in a detail view.
- **Timers on the pen board.** "26h" is fine visually; the semantics label must say "penned 26 hours" (§3.4), and at large scale the cell must be able to show "26h" on its own line.

### 4.4 The new text-spacing overrides — real, but web-only today

Flutter 3.44's `MediaQueryData` carries four new properties (`widgets/media_query.dart:236–239`, `:711–747`):

```dart
final double? lineHeightScaleFactorOverride;
final double? letterSpacingOverride;
final double? wordSpacingOverride;
final double? paragraphSpacingOverride;
```

and `Text.build` applies the first three automatically (`widgets/text.dart:728–742`), with a framework TODO for paragraph spacing ([#177953](https://github.com/flutter/flutter/issues/177953), [#177408](https://github.com/flutter/flutter/issues/177408)).

**But a code search across `flutter/flutter` for `lineHeightScaleFactorOverride` returns 13 hits, and the only engine implementations are `lib/web_ui/…`.** There is no Android or iOS shell that ever populates these. On mobile they are permanently `null`.

**Consequence:** WCAG 1.4.12 Text Spacing cannot be satisfied by reading a flag on mobile. It must be satisfied **by design** — the layout must simply tolerate 1.5× line height and 0.12em letter spacing without clipping. Practically that means: no fixed-height text containers, and set `height: 1.4`–`1.5` in the base `TextTheme` from the start so there is headroom rather than a cliff.

### 4.5 Bold text — the framework does it, and there is a live bug

`Text.build` at `widgets/text.dart:722`:

```dart
if (MediaQuery.boldTextOf(context)) {
  effectiveTextStyle = effectiveTextStyle!.merge(const TextStyle(fontWeight: FontWeight.bold));
}
```

`FontWeight.bold` is **w700**, and `merge` wins. So:

- Any style you set at **w800/w900 becomes w700 when the user turns Bold Text on** — i.e. your heaviest text gets *lighter*. Open issue [#139712](https://github.com/flutter/flutter/issues/139712) ("With 'bold text' accessibility setting, Text widget makes extra-bold text *less* bold", open since Dec 2023, last touched Oct 2025).
- A custom weight inside a `TextSpan` is not bolded at all — open issue [#177801](https://github.com/flutter/flutter/issues/177801) (opened Oct 2025).
- iOS has a separate open report, [#162804](https://github.com/flutter/flutter/issues/162804).

**House rule: no text style in Shed Book exceeds `FontWeight.w700`.** Use size and colour for hierarchy, not weight above 700. This dodges all three bugs and, incidentally, produces a better dark-theme type ramp (very heavy weights bloom badly on OLED in the dark).

Android caveat: `boldText` only exists on **API 31+** (`Configuration.fontWeightAdjustment >= 300`). On Android 11 and below there is no signal.

---

## 5. The other accessibility flags — what each should change in Shed Book

| Flag | Availability (verified) | What Shed Book must do |
|---|---|---|
| `boldText` | iOS; Android 12+ | Nothing manual — `Text` handles it. Just keep weights ≤ w700 (§4.5) and re-run the golden tests with it on. |
| `disableAnimations` (Android) / `reduceMotion` (iOS) | Android: transition scale 0. iOS: Reduce Motion. **No overlap.** | Use `prefersReducedMotion()` (§2). Then: page transitions become cross-fades of `Duration.zero`; the pen-board "hours since penned" ticker stops animating and just re-renders; the save confirmation appears without a slide; no shimmer, no pulsing "overdue" badge. Apple: replace meaning-bearing motion with *"dissolve, highlight fade, color shift"*. |
| `highContrast` | **iOS only** | Provide `MaterialApp.highContrastDarkTheme`. Because Android never reports it, also expose an in-app "High contrast" switch that applies the same `ThemeData`. |
| `invertColors` | iOS only (Smart/Classic Invert) | Do **not** try to compensate. Flutter does not expose `accessibilityIgnoresInvertColors` ([#10603](https://github.com/flutter/flutter/issues/10603), closed as stale), so photos of lambs *will* invert under Classic Invert. Mitigation: keep photos out of the critical path — never put a photo where the meaning depends on its colour. Test the app once under Smart Invert and make sure nothing becomes unreadable. |
| `accessibleNavigation` | Both (iOS = VoiceOver **or Switch Control**) | Only for timing: don't auto-dismiss anything; extend/disable any auto-advance; don't steal focus. **Never** use it to branch the layout. |
| `onOffSwitchLabels` | iOS only | Free if you use Material `Switch`. Prefer segmented buttons with words over switches anyway — a switch is a poor 3am control. |
| `supportsAnnounce` | iOS/web true, **Android false** | Gate every `sendAnnouncement` call. Prefer `liveRegion`. |
| `autoPlayAnimatedImages`, `autoPlayVideos`, `deterministicCursor` | iOS 18+ only (new in 3.44) | N/A — the app has no autoplay media. `deterministicCursor` is free via `EditableText`. |
| **Reduced transparency** | **Does not exist in Flutter 3.44** | Design around it: no `BackdropFilter`, no translucent app bars, no scrims over text. |
| `alwaysUse24HourFormat` | Both (not an a11y flag, but adjacent) | Drives `TimeOfDay.format`. See §8.4. |

---

## 6. Colour

### 6.1 Never colour alone — and the pen board is the test case

Spec §7.4 says "Colour **or badge** for 'ready to turn out'". That "or" must become "and". WCAG 1.4.1 is Level A, and Apple's criterion is blunt: *"If you can't use your own app in grayscale, rethink your app's design."*

Every pen-board status carries **four** channels:

| Status | Colour | Icon (shape) | Text | Position |
|---|---|---|---|---|
| Settled (< threshold) | neutral grey | none | `12h` | default order |
| Ready to turn out | amber | ▲ filled triangle | `26h · READY` | sorted to top |
| Under withdrawal | sky blue | ⊘ circle-slash | `CLEAR 14 JUL` | badge on cell |
| Needs attention (user flag) | vermillion | ● filled dot + ring | `FLAG` | sorted to top |
| Empty pen | outline only | dashed border | `—` | sorted to bottom |

Shape must be distinguishable in silhouette: **triangle / circle-slash / dot / dash**, not four differently-coloured circles. That is exactly the example Apple gives.

### 6.2 A palette that survives a head torch — with the arithmetic

The base of the colour-universal-design palette is Okabe & Ito's ([jfly.uni-koeln.de/color](https://jfly.uni-koeln.de/color/)); note that the CUD page presents the swatches as a figure, not as text, so treat the hex values below as the widely-circulated CUD set and re-derive from the figure if you want to be pedantic. What matters more, and what I *did* compute, is the contrast, using WCAG's own formulas: `L = 0.2126R + 0.7152G + 0.0722B` (sRGB-linearised) and `(L1 + 0.05) / (L2 + 0.05)`.

Contrast ratios computed against three candidate dark surfaces:

| Colour | on `#000000` | on `#121212` | on `#1A1A1A` |
|---|---|---|---|
| `#FFFFFF` white | 21.00 | 18.73 | 17.40 |
| `#E6E6E6` near-white (body text) | 16.83 | 15.01 | 13.94 |
| `#B3B3B3` muted (secondary) | 10.02 | 8.93 | 8.30 |
| `#F0E442` CUD yellow | 15.88 | 14.17 | 13.16 |
| `#FFB000` amber (READY) | 11.46 | 10.23 | 9.50 |
| `#E69F00` CUD orange | 9.32 | 8.32 | 7.73 |
| `#56B4E9` CUD sky blue (WITHDRAWAL) | 9.10 | 8.12 | 7.54 |
| `#CC79A7` CUD reddish purple | 6.86 | 6.12 | 5.69 |
| `#009E73` CUD bluish green | 6.14 | 5.48 | 5.09 |
| `#D55E00` CUD vermillion (FLAG) | 5.43 | 4.84 | 4.50 |
| `#0072B2` CUD blue | **4.05** | **3.61** | **3.36** |
| `#FF0000` pure red | 5.25 | 4.69 | **4.35** |

**Decisions from that table:**

- **Surface `#121212`**, not `#000000`. Pure black on OLED gives 21:1 but produces visible smearing on scroll and makes the card edges invisible; `#121212` keeps everything ≥ 4.5:1 for the chosen accents.
- **`#0072B2` is out.** 3.61:1 on `#121212` fails 1.4.3 AA for normal text. Use `#56B4E9` for anything blue.
- **Body text `#E6E6E6`, not `#FFFFFF`.** 15:1 is far past the requirement, and pure white on near-black is the classic halation/eye-strain combination for a dark-adapted eye.
- The four status accents — amber `#FFB000`, sky `#56B4E9`, vermillion `#D55E00`, and neutral `#B3B3B3` — are all ≥ 4.5:1 on `#121212` and are separable under deuteranopia/protanopia because they differ in luminance as well as hue (10.2 / 8.1 / 4.8 / 8.9).
- **Vermillion `#D55E00` at 4.84:1 is the weakest link.** Only ever use it at ≥18pt or bold ≥14pt (where the requirement drops to 3:1), or pair it with a white text label on a vermillion chip.

### 6.3 Head torch vs darkness — the real lighting problem

Contrast requirements are computed for a fixed viewing condition; a shed has two. A head torch pointed at a phone screen at 30cm raises the *ambient* luminance enormously, which **reduces effective contrast** (the screen's black is no longer black — it's reflected torchlight). Meanwhile in darkness, high-luminance UI destroys dark adaptation.

Practical consequences:

1. **Design to the head-torch case, not the dark case.** Pick contrast ratios with ~2× headroom over 4.5:1 for anything load-bearing. The table above deliberately has everything ≥ 4.8:1 and the primary text at 15:1.
2. **Do not use "elevation by tint" as the only separator between surfaces.** Material 3's `surfaceContainer` ladder differs by a few percent luminance and disappears under a torch. Use a **1px `#3A3A3A` outline** on cards as well (that's 2.0:1 against `#121212` — below the 3:1 non-text requirement, so the outline is decoration; the *meaning* must still be carried by the label).
3. **No pure-white large fills.** A full-screen white anything is a dark-adaptation grenade. This is also spec §5's "no white flash on launch" — implement that natively (Android `windowBackground` in `styles.xml` set to the dark surface for both `LaunchTheme` and `NormalTheme`; iOS `LaunchScreen.storyboard` background set to the same colour and `UIUserInterfaceStyle` pinned to `Dark`), not in Dart. By the time Dart runs, the flash has already happened.

### 6.4 Red-shift mode

Spec §5 offers "Optional red-shift mode" for night vision. The physiology is real (long-wavelength light spares rod adaptation), but the accessibility implications are sharp:

- **Red-on-black is one of the worst possible combinations for protanopia** (red-blind), because the red channel contributes only 0.2126 of luminance and a protanope loses most of it. `#FF0000` on `#121212` measures 4.69:1 for a normal observer and much less for a protanope.
- **Therefore red-shift must never be the default, and must never be the only theme.** It is a user-selected third theme, alongside `darkTheme` and the high-contrast variant.
- Build it as **amber-shift, not red-shift**: `#FFB000` measures 10.23:1 on `#121212`, preserves most of the night-vision benefit (it is still long-wavelength), and is legible to every common colour-vision deficiency. If the user insists on true red, offer both and label them honestly ("Amber (recommended)" / "Deep red (best for night vision, hardest to read)").
- In red/amber mode you lose the four-way status hue coding entirely. **The icon + text redundancy from §6.1 is what makes red-shift mode shippable at all.** This is the concrete payoff of never using colour alone.

### 6.5 Does high contrast need a separate theme?

Yes, and it's cheap. `MaterialApp` already has the plumbing: `highContrastTheme` / `highContrastDarkTheme` are used *"when the user requests high contrast and the system is in the corresponding brightness mode"*, and fall back to `theme`/`darkTheme` when null (`material/app.dart:1003–1008`).

Two ways to build it:

```dart
// Option A: let Material 3 do it. ColorScheme.fromSeed takes a contrastLevel:
//   "0.0 is the default (normal); -1.0 is the lowest; 1.0 is the highest."
final ColorScheme hcDark = ColorScheme.fromSeed(
  seedColor: shedSeed,
  brightness: Brightness.dark,
  contrastLevel: 1.0,
);

// Option B (recommended here): a hand-built scheme, because the pen-board
// status colours are semantic, not seed-derived, and must keep their
// hue/shape/luminance separation. Bump surface to #000000, text to #FFFFFF,
// outlines to #7A7A7A, and keep the same four accents.
```

**Recommendation: Option B**, because the four status colours are load-bearing and must not be regenerated by a tonal algorithm. Use `contrastLevel` only for incidental chrome.

And because `highContrast` never fires on Android, expose the same theme behind a Settings toggle. That toggle is also useful for a sighted user in a bright shed at midday.

---

## 7. Motor accessibility

### 7.1 Targets and spacing

- **60×60 pt minimum** (spec §5) — already above Apple's 44, Android's 48, WCAG's AAA 44.
- **≥12 pt between adjacent targets** (Google recommends 8dp; go further, cold hands are imprecise). WCAG 2.5.8's spacing exception is defined as a 24px-diameter circle that must not intersect another target — at 60pt targets with 12pt gutters you're comfortably clear.
- **Hit slop beyond the visual bounds.** `InkResponse(radius:)` / a transparent `Padding` inside the tappable, so the *hit* area exceeds the *painted* area. A gloved thumb lands 5–8pt off centre.
- **Destructive actions get the same size but not the same place.** "Delete" must never be adjacent to "Save". Put destructive actions on a different screen edge or behind a confirm step — because spec §12.4 says never silently correct, and spec §5 says assume the phone dies mid-entry.
- **Corner exclusion.** The bottom ~20pt and the top ~44pt are system gesture zones. A 60pt target that starts at y=0 is not a 60pt target.

### 7.2 No gesture-only actions — this is a hard rule

WCAG 2.5.1 (A) and 2.5.7 (A), and spec §5. Concretely:

| Tempting gesture | Required plain-button equivalent |
|---|---|
| Swipe-to-delete a lamb | "Delete" button inside the lamb card |
| Long-press to multi-select pens | "Select" mode toggle button |
| Drag a lamb from one ewe to another (foster) | Two-tap flow: "Foster" → pick ewe (spec §7.3) |
| Pinch to zoom the pen board | "Bigger / smaller board" buttons, or let text scale drive it |
| Pull-to-refresh | nothing to refresh — it's offline |
| Shake to undo | explicit "Undo" chip in the confirmation banner |

If a gesture exists at all it is an *accelerator*, and the button must be discoverable without knowing the gesture exists.

### 7.3 Switch Control and Voice Control

**Switch Control (iOS) / Switch Access (Android)** scan the accessibility tree in traversal order. Everything in §3.8 applies. Two extra requirements:

- Every interactive node must be **reachable** and **have a label** — an unlabelled node is an unnamed stop in the scan. `accessibility_tools`' semantic-label checker catches these in debug.
- **No timeouts.** A switch user takes 20 seconds to reach a button. Nothing in this app should auto-dismiss; `accessibleNavigation` is true for Switch Control on iOS, which is the hook if you ever need it.

**Voice Control (iOS)** is the one that changes how you write labels. Apple: *"Match Voice Control labels to the visible text."* If the button says "Turn out" and its label is "Release from pen", "Show names" will display "Release from pen" and the user saying "tap turn out" gets nothing. So:

- Visible text is the source of truth for the label.
- Icon-only buttons get the name a person would speak, and where practical also carry a visible text label — which at 3am is the right design anyway.
- Any long-press/context behaviour must also exist as a listed action (`customSemanticsActions`) so it appears in the actions rotor.

**Why every action needs a plain button somewhere:** because Switch Control, Voice Control, a gloved thumb, a wet screen, and a phone in a freezer bag all fail at gestures for *different* reasons and succeed at buttons for the same one. There is no accessibility scenario in this app in which a gesture is more reliable than a button.

---

## 8. Haptics and audio as accessibility

Haptics here are not polish; they are the **only confirmation channel that survives a freezer bag, darkness, and a face pointed at a lamb**. `HapticFeedback` (in `package:flutter/services.dart`) gives: `lightImpact`, `mediumImpact`, `heavyImpact`, `selectionClick`, `vibrate`, `successNotification`, `warningNotification`, `errorNotification`.

Proposed vocabulary — small, consistent, and semantic:

| Event | Haptic | Also |
|---|---|---|
| Keypad digit | `selectionClick()` | live-region update of the buffer |
| Animal selected | `lightImpact()` | — |
| Event **committed to SQLite** | `successNotification()` | persistent live-region confirmation banner |
| Validation flag raised (e.g. "twin" with 3 lambs, spec §12.4) | `warningNotification()` | visible, non-blocking flag; **never auto-corrects** |
| Action refused (free-tier cap) | `errorNotification()` | visible explanation |

Rules:

- **The success haptic fires on the DB commit, not on the tap.** Spec §5: "every write is committed immediately". The haptic is a receipt, and a false receipt is worse than none.
- **Haptics are never the only channel.** Some devices have no haptic engine, some users have reduced sensation, and gloves attenuate it badly. Always pair with the visible banner + live region.
- **Audio: use `SystemSound.play(SystemSoundType.click)` and nothing else.** *"Play the specified system sound. If that sound is not present on the system, the call is ignored."* Do **not** bundle a custom "saved" chime: it adds a media dependency, it plays through whatever the user is listening to at 3am, and it is one more thing to make silent. If you ever add a confirmation tone, it must be off by default and settable.
- **Respect silent mode implicitly** by using system sounds only.
- Do **not** add a `vibrate()` on every keypress — `selectionClick` is the correct, subtle, OS-consistent choice, and `vibrate` on Android is a long buzz.

---

## 9. Internationalisation groundwork for an English-first v1

### 9.1 The decision: yes, gen-l10n from day one

**Adopt `flutter_localizations` + gen-l10n/ARB in the first commit, with exactly one locale.**

The honest cost/benefit for a solo dev:

**What it costs (once, up front, ~2 hours):**
- 3 lines in `pubspec.yaml`, a 5-line `l10n.yaml`, one `app_en.arb`.
- `AppLocalizations.of(context)!.foo` instead of `'Foo'`. Slightly more typing, and one more import.
- Generated code lands in `lib/l10n/` and must be gitignored or committed (commit it — it makes CI simpler and diffs visible).

**What it buys immediately, before any translation exists:**
- **A single place where all user-visible text lives.** For an app whose §12 safety rules are about *wording* ("as entered by you", "not a regulatory record", never "you should"), having every string in one reviewable file is worth the cost on its own. You can grep the ARB for "should" and prove the app gives no veterinary advice.
- **`GlobalMaterialLocalizations`**, which you need regardless, because it is what makes the date picker, time picker, and every Material tooltip render in en-GB rather than en-US (§10).
- **ICU plurals**, so "1 lamb / 2 lambs / 0 lambs" is a data-driven message rather than a `count == 1 ? …` ladder scattered across ten widgets.
- **Locale-aware `DateFormat`/`NumberFormat`** already initialised (§10.5).

**What is expensive to retrofit later (this is the actual argument):**

| Retrofit cost | Why |
|---|---|
| **String extraction** | Very expensive. Every `Text('…')` in 12 screens must be found, named, deduplicated and moved. Naming is the slow part — you will rename half of them twice. |
| **Plurals** | Very expensive. Ad-hoc `'$n lamb${n == 1 ? '' : 's'}'` is scattered and each site needs rewriting into ICU. Worse, some will have been baked into *exported CSV headers* and *PDF text*, where changing them changes user-visible files. |
| **Placeholder order** | Expensive. `'$term $tag'` string interpolation encodes English word order at every call site. ARB placeholders make the order a property of the message. |
| **Date/number formats** | Expensive **and dangerous**. Retrofitting `DateFormat` after shipping means old exports and new exports disagree about what `07/13` means. |
| Adding a second locale later | **Cheap** if the above is done. Just add `app_ga.arb`. |
| Adding RTL later | Moderate — but you get most of it free by using `EdgeInsetsDirectional` and `start`/`end` from the beginning. Do that; it costs nothing. |

**The trap to avoid:** teams adopt gen-l10n but keep interpolating domain nouns into English sentence templates. That's the worst of both worlds. See §11.

### 9.2 The exact 3.44 configuration (the docs are partly stale)

The [internationalization guide](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization) still documents `synthetic-package`. **That option is dead.** Flutter 3.32 moved generation into source (["Localized messages are generated into source, not a synthetic package"](https://docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source)), support was removed in the next stable, and in 3.44 the flag's own help text reads:

```
'synthetic-package',
help: 'DEPRECATED. This flag cannot be enabled and should be removed.',
```
(`packages/flutter_tools/lib/src/commands/generate_localizations.dart:44`)

**`pubspec.yaml`:**

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  # MUST be `any`. flutter_localizations 3.44 pins `intl: 0.20.2` EXACTLY
  # (packages/flutter_localizations/pubspec.yaml), while pub.dev's current
  # intl is 0.20.3. `intl: ^0.20.3` will fail to resolve.
  intl: any

flutter:
  generate: true          # required; read by FlutterManifest.generateLocalizations
```

**`l10n.yaml`** (verified defaults from `localizations_utils.dart:349–359`: template `app_en.arb`, output `app_localizations.dart`, class `AppLocalizations`, `nullable-getter: true`, `format: true`):

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
# Force every message to carry a description. Costs 10 seconds per string and
# saves the future translator (and future you) from guessing what "clear" means.
required-resource-attributes: true
# Non-nullable getter: AppLocalizations.of(context) instead of ...!
nullable-getter: false
# Named parameters make call sites self-documenting for multi-placeholder
# messages, which every "term + tag + count" message here is.
use-named-parameters: true
```

**App wiring:**

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart'; // generated into arb-dir

MaterialApp(
  onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
  localizationsDelegates: const <LocalizationsDelegate<Object>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const <Locale>[
    Locale('en'),        // MUST be first — see §10.1
    Locale('en', 'GB'),
    Locale('en', 'IE'),
  ],
  themeMode: ThemeMode.dark,
  darkTheme: shedDarkTheme,
  highContrastDarkTheme: shedHighContrastDarkTheme,
  // No `theme:` light variant beyond the framework default in v1.
);
```

Note: `supportedLocales` is set **explicitly**, not from `AppLocalizations.supportedLocales`. That's deliberate — see §10.1. It works because gen-l10n generates `bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);` (`gen_l10n_templates.dart:233`) and the lookup function falls through a nested country switch to the language switch, so `Locale('en','GB')` resolves to `AppLocalizationsEn` without an `app_en_GB.arb` existing.

**Offline check:** nothing here touches the network. `flutter_localizations` bundles its CLDR date symbols as generated Dart (`generated_date_localizations.dart`) and registers them with `initializeDateFormattingCustom` at delegate-load time. `intl` ships its data in the package. No asset download, no HTTP, no manifest permission.

### 9.3 ARB conventions for this app

```json
{
  "@@locale": "en",

  "savedReceipt": "Saved. {term} {tag}, {summary}, at {time}.",
  "@savedReceipt": {
    "description": "Live-region confirmation after a lambing event is committed to SQLite. Must be unique per save or Android will not re-announce it (AccessibilityBridge only fires on label change).",
    "placeholders": {
      "term": { "type": "String", "example": "gimmer" },
      "tag": { "type": "String", "example": "412" },
      "summary": { "type": "String", "example": "twins, ease 2" },
      "time": { "type": "DateTime", "format": "Hm", "example": "03:22" }
    }
  },

  "lambCount": "{count, plural, =0{no lambs} =1{1 lamb} other{{count} lambs}}",
  "@lambCount": {
    "description": "Number of lambs in a litter or on a chart bar.",
    "placeholders": { "count": { "type": "num" } }
  },

  "pennedForHours": "{hours, plural, =1{penned 1 hour} other{penned {hours} hours}}",
  "@pennedForHours": {
    "description": "Spoken form of the pen-board timer. The visual form is abbreviated (26h); this is the semantics label.",
    "placeholders": { "hours": { "type": "int" } }
  },

  "withdrawalClearOn": "Clear on {date}",
  "@withdrawalClearOn": {
    "description": "Medicine withdrawal end date. NEVER a default value - always derived from the number the user typed off the bottle (spec 12.1).",
    "placeholders": { "date": { "type": "DateTime", "format": "yMMMd" } }
  },

  "withdrawalSource": "Withdrawal period: {days} days, as entered by you",
  "@withdrawalSource": {
    "description": "Provenance label required by spec 12.1. The wording 'as entered by you' is a safety requirement, not a style choice.",
    "placeholders": { "days": { "type": "int" } }
  },

  "timeAutoCaptured": "Time recorded automatically",
  "@timeAutoCaptured": { "description": "Spec 12.5 honest timestamps." },
  "timeEdited": "Time edited by you",
  "@timeEdited": { "description": "Spec 12.5 honest timestamps." },

  "exportFooterNotRegulatory": "This is a personal notebook. It is not a holding register, a movement record, or a statutory medicine book.",
  "@exportFooterNotRegulatory": { "description": "Spec 12.3. Appears in every PDF/CSV footer." }
}
```

House rules:
1. `required-resource-attributes: true` — every message has a description.
2. **Descriptions carry the safety rationale.** When a future contributor "improves" the wording of `withdrawalSource`, the description tells them why they must not.
3. Message IDs are `screenConcept`, never the English text.
4. **No domain nouns baked into messages** — see §11.
5. Formatted dates go through ARB `DateTime` placeholders with explicit `format`, so the format is data, not code.

---

## 10. Regional reality — UK/Ireland first

### 10.1 The locale-resolution trap (verified by reading the algorithm)

`WidgetsApp.basicLocaleListResolution` (`widgets/app.dart:146–235`) builds four hash maps, all with **first-wins** semantics:

```dart
for (final locale in supportedLocales) {
  allSupportedLocales['${locale.languageCode}_${locale.scriptCode}_${locale.countryCode}'] ??= locale;
  languageAndScriptLocales['${locale.languageCode}_${locale.scriptCode}'] ??= locale;
  languageAndCountryLocales['${locale.languageCode}_${locale.countryCode}'] ??= locale;
  languageLocales[locale.languageCode] ??= locale;   //  <-- first wins
  countryLocales[locale.countryCode] ??= locale;
}
```

Match priority per preferred locale: exact (lang+script+country) → lang+script → lang+country → language-only → country-only → `supportedLocales.first`.

Three concrete outcomes:

| `supportedLocales` | Device `en-GB` resolves to | Device `en-US` resolves to |
|---|---|---|
| `[Locale('en')]` (i.e. what gen-l10n gives you from one `app_en.arb`) | **`en`** → `MaterialLocalizationEn` → **`M/d/y`, week starts Sunday** ❌ | `en` ✅ |
| `[Locale('en','GB'), Locale('en','IE'), Locale('en')]` | `en_GB` ✅ | **`en_GB`** ❌ (language-only map was populated by en_GB first) |
| **`[Locale('en'), Locale('en','GB'), Locale('en','IE')]`** | `en_GB` ✅ | `en` ✅ |

**So the ordering in §9.2 is not cosmetic.** Put bare `Locale('en')` first.

`MaterialLocalizationEnGb` and `MaterialLocalizationEnIe` both exist in `generated_material_localizations.dart` (lines 8642 and 8742), so once the locale resolves correctly you get British/Irish Material strings and formats for free. Note also that `MaterialApp.supportedLocales` **defaults to `[Locale('en','US')]`** (`widgets/app.dart:356`) — leaving it unset is the same bug in a different disguise.

### 10.2 Date order is a data-integrity hazard, not a formatting preference

`GlobalMaterialLocalizations` derives everything from `intl` for the resolved locale (`flutter_localizations/lib/src/material_localizations.dart:751–757`):

```dart
compactDateFormat = intl.DateFormat.yMd(localeName);   // en   -> 7/13/2026
                                                       // en_GB-> 13/07/2026
firstDayOfWeekIndex => (_longDateFormat.dateSymbols.FIRSTDAYOFWEEK + 1) % 7;
                                                       // en   -> 0 (Sunday)
                                                       // en_GB-> 1 (Monday)
```

That is the mechanism. Now the policy.

**Rule: Shed Book never renders an all-numeric date to a human.** Not `13/07/2026`, not `07/13/2026`. Every human-facing date uses a spelled month.

```dart
/// The only date formatter Shed Book uses for anything a person reads.
///
/// Why not DateFormat.yMd? Because `13/07` and `07/13` are indistinguishable
/// to a reader who does not know which locale resolved, and a withdrawal
/// "clear on" date that is misread by six months puts meat in the food chain
/// (spec 12.1). Spelling the month removes the ambiguity entirely and costs
/// four characters.
String humanDate(BuildContext context, DateTime d) {
  final String locale = Localizations.localeOf(context).toString(); // "en_GB"
  return DateFormat('d MMM y', locale).format(d);   // "13 Jul 2026"
}

/// Time follows the DEVICE setting, not the locale. On Android this is the
/// system "Use 24-hour format" toggle; on iOS it is "24-Hour Time" or the
/// locale default. Both surface as MediaQueryData.alwaysUse24HourFormat.
String humanTime(BuildContext context, DateTime d) {
  final bool h24 = MediaQuery.alwaysUse24HourFormatOf(context);
  final String locale = Localizations.localeOf(context).toString();
  return DateFormat(h24 ? 'HH:mm' : 'h:mm a', locale).format(d);
}
```

For **input**, never present a free-text date field. Use `showDatePicker` (which gets `firstDayOfWeekIndex` and the correct field order from `MaterialLocalizations` automatically), or — better for the 3am case — offer relative buttons: *Today / Yesterday / 2 days ago / Pick a date*. A deferred lambing entry at 07:00 is almost always "last night", and three taps beats a date picker with cold hands.

For **CSV export**, emit **two** columns: `date_iso` (`2026-07-13`, RFC 3339, unambiguous, sorts correctly in every spreadsheet) and `date_display` (`13 Jul 2026`). Spreadsheets famously re-interpret `13/07/2026`; ISO-8601 is the only format Excel and Numbers both parse identically. This is a backup-integrity issue (spec §7.9: export is the *only* backup mechanism).

### 10.3 Spelling: en-GB is the source language

`app_en.arb` is written in **British English** and is the template. That means:
- "Colour", "grey", "recognise", "flavour", "labelled", "practise" (verb).
- Domain spelling follows UK farming usage: "foster", "tup", "shearling", "turn out" (two words, verb), "turnout" (noun) — but see §11: these are terminology-map values, not catalogue strings, wherever the user can rename them.
- A US user sees British spelling in v1. That's the correct trade for a UK/Ireland-first launch (spec §17.3) and is trivially fixed later by adding `app_en_US.arb` with only the ~15 differing strings.

### 10.4 Units, clock, and week

| Setting | Source | Default | Why |
|---|---|---|---|
| Weight | **User setting** (spec §7.10), stored in DB | **kg** | UK/IE use kg for lamb birthweights. Do not infer from locale — a UK smallholder may genuinely want lb, and a wrong inference silently mislabels every weight ever recorded. |
| Temperature | **User setting** | **°C** | Same reasoning. |
| Clock | **Device** via `MediaQuery.alwaysUse24HourFormatOf` | follows device | Verified: on Android this is *"reported directly from the user settings called 'Use 24-hour format'"* and applies regardless of locale; on iOS it reflects "24-Hour Time" or the locale default. Do not add an app setting for this — the device already has one and it is the one the user set. |
| First day of week | **Locale** via `MaterialLocalizations.firstDayOfWeekIndex` | Monday for en_GB/en_IE | Free once §10.1 is right. `0 = Sunday … 6 = Saturday`. |
| Decimal separator | **Locale** via `NumberFormat` | `.` for en_* | Beware: birthweight input must accept both `4.2` and `4,2` on input even if it renders `4.2`. A shepherd's keyboard may offer either. |

**Store everything in SI in the database** (kg, °C, UTC-offset-aware ISO-8601) and convert only at the presentation and export boundary. Otherwise a user who flips kg→lb halfway through a season silently corrupts the season summary — which would violate spec §12.4 ("never silently correct a user's entry") in the most expensive possible way.

### 10.5 `intl` initialisation — you get it free, with one caveat

`flutter_localizations`' delegate calls `loadDateIntlDataIfNotLoaded()`, which iterates its bundled `dateSymbols` map and calls `date_symbol_data_custom.initializeDateFormattingCustom(...)` for every locale (`flutter_localizations/lib/src/utils/date_localizations.dart`). So **after `GlobalMaterialLocalizations.delegate` has loaded, `DateFormat('d MMM y', 'en_GB')` just works** — no `initializeDateFormatting()`, no async, no assets, no network.

**Caveat:** that's only true inside the widget tree, after the delegate loads. Code that runs *before* `MaterialApp` (a startup migration) or *outside* it (a background isolate generating a PDF) must call `initializeDateFormatting()` from `package:intl/date_symbol_data_local.dart` itself, or pass `null` locale and accept `en_US`. Put this in the export code path's checklist.

---

## 11. The terminology map vs the string catalogue

Spec §7.10 lets the user rename ewe / gimmer / shearling / theave / hogget. Spec §12.4 says never silently correct a user's entry. Those two together settle the design.

### 11.1 The rule

> **The ARB catalogue owns the *frame*. The terminology map owns the *nouns*. A domain noun never appears literally inside an ARB message; it always arrives as a placeholder.**

Wrong:
```json
"turnOutPrompt": "Turn out ewe {tag}?"
```
Right:
```json
"turnOutPrompt": "Turn out {term} {tag}?",
"@turnOutPrompt": {
  "description": "{term} is a USER-EDITABLE noun from the terminology map (ewe/gimmer/theave/...). Never translate it and never hard-code it.",
  "placeholders": {
    "term": { "type": "String", "example": "gimmer" },
    "tag":  { "type": "String", "example": "412" }
  }
}
```

### 11.2 Where each piece lives

| Thing | Home | Translated? | User-editable? |
|---|---|---|---|
| "Turn out", "Save", "Pen board", "Withdrawal ends" | ARB catalogue | yes, later | no |
| "ewe", "gimmer", "shearling", "theave", "hogget", "tup", "wether" | `Settings.terminology_map` in SQLite | **no** | **yes** |
| The *default* terminology map | ARB, as `termEweDefault`, `termLambDefault`, … | yes, later | seeded once |
| Lambing-ease descriptions, death causes, malpresentations (spec §11, ~40 authored terms) | ARB (they are authored copy, and editable lists are a separate concern) | yes, later | the *list* is editable; the shipped defaults come from ARB |
| Anything the user typed (notes, product names, batch numbers) | SQLite | **never** | yes |

### 11.3 Seeding, and the never-overwrite rule

```dart
/// Seed the terminology map ONCE, from the catalogue, on first run.
/// After that the map is user data. Changing the device locale, updating the
/// app, or adding a translation must NEVER rewrite it — that would be silently
/// correcting the user's entry (spec 12.4).
Future<void> seedTerminologyIfAbsent(BuildContext context, SettingsDao dao) async {
  if (await dao.hasTerminologyMap()) return;
  final l10n = AppLocalizations.of(context);
  await dao.writeTerminologyMap(TerminologyMap(
    entries: <AnimalClass, Term>{
      AnimalClass.breedingFemale: Term(
        singular: l10n.termEweDefault,        // "ewe"
        plural:   l10n.termEwePluralDefault,  // "ewes"
      ),
      AnimalClass.youngFemale: Term(
        singular: l10n.termGimmerDefault,
        plural:   l10n.termGimmerPluralDefault,
      ),
      // ...
    },
    seededFromLocale: Localizations.localeOf(context).toString(),
    seededAt: DateTime.now(),
  ));
}
```

Record `seededFromLocale`/`seededAt` so that if a future version ships a better default set you can *offer* an update rather than perform one.

### 11.4 Plurals: the collision, and how to avoid it

ICU plurals cannot pluralise a runtime string. `"{count, plural, other{{count} {term}s}}"` produces "3 gimmers" (fine) and "3 tups" (fine) and "3 sheeps" (not fine) and, in Irish, nonsense.

Three options, in order of preference:

1. **Best — avoid grammatical agreement entirely in the UI.** Label + value, not a sentence: `Ewes  ·  132`, `Lambs born  ·  241`. This is also the most legible layout at 3am and at AX5, and it survives translation into languages with case systems. **Adopt this as the default for all statistics.**
2. **When a sentence is unavoidable, store both forms.** The terminology map holds `singular` and `plural` per class; the ARB message uses ICU only to *choose between two supplied strings*:
   ```json
   "animalCount": "{count, plural, =1{{count} {singular}} other{{count} {plural}}}"
   ```
   The user editing "gimmer" is prompted for "gimmers" in the same dialog. Two fields, one screen, no guessing.
3. **Never** derive a plural by appending `s`. Not in the UI, not in exports, not in semantics labels.

### 11.5 Semantics labels use the user's noun too

If the shepherd calls her a theave, TalkBack must say "theave 412". The `PenCell` snippet in §3.4 already threads `terms` through. This matters more than it looks: a screen-reader user navigating a board full of "ewe 412" when their whole flock is gimmers will not trust the app.

Consequence for the spell-out attribute (§3.2): apply `SpellOutStringAttribute` to the **tag range only**, never to the term — you want "gimmer, four one two", not "g-i-m-m-e-r".

---

## 12. Testing, and the shippable checklist

### 12.1 Automated — cheap, run in CI

```dart
// test/a11y/screens_meet_guidelines_test.dart
void main() {
  for (final entry in shedBookScreens.entries) {
    testWidgets('${entry.key} meets a11y guidelines', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(TestApp(child: entry.value()));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline)); // 48x48
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));     // 44x44
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline)); // all taps labelled
      await expectLater(tester, meetsGuideline(textContrastGuideline));     // WCAG contrast

      handle.dispose();
    });
  }
}
```

Note the built-ins only check 48/44 — **add a house guideline for 60×60**, which the built-ins do not cover:

```dart
await expectLater(tester, meetsGuideline(
  const MinimumTapTargetGuideline(size: Size(60, 60), link: 'spec §5')));
```

**New in 3.44 — check whether these are publicly exposed before writing your own.** The [3.44 release notes](https://docs.flutter.dev/release/release-notes/release-notes-3.44.0) list a fresh set of in-framework accessibility evaluations landing in `packages/flutter/lib/src/widgets/_accessibility_evaluations.dart`:

- **Non-text colour contrast** ([PR #183569](https://github.com/flutter/flutter/pull/183569)) — captures the rendered image and checks UI controls against `kMinimumRatioNonText = 3.0`, i.e. WCAG 1.4.11. This is the one guideline Shed Book most needs and previously had to be checked by hand: pen-tile outlines, status glyphs and keypad key edges are all non-text carriers of meaning.
- **`UnlabeledLeafNodeEvaluation`** ([PR #182872](https://github.com/flutter/flutter/pull/182872)) — catches exactly the hand-built `GestureDetector` surfaces this app is full of.
- **Title evaluation** ([PR #184084](https://github.com/flutter/flutter/pull/184084)).

The leading underscore on the file name means these may still be private on 3.44. **Action: grep the installed SDK for `kMinimumRatioNonText` and for exported `AccessibilityGuideline` constants; if they are public, wire them into the loop above and drop the corresponding manual checks from §12.2.** If they are private, keep measuring non-text contrast by hand against the table in §6.2.

**Traversal order** is testable, which is exactly what the pen board needs:

```dart
testWidgets('pen board reads row-major with one sentence per pen', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(TestApp(child: PenBoardScreen(pens: fixturePens)));

  final labels = tester.semantics
      .simulatedAccessibilityTraversal(start: find.byType(PenBoard))
      .map((n) => n.label)
      .toList();

  expect(labels, <String>[
    'Pen 1. gimmer 412. penned 26 hours. Ready to turn out',
    'Pen 2. ewe 88. penned 4 hours',
    // ...
  ]);
  handle.dispose();
});
```

**Text-scale goldens** — six configurations per screen:

```dart
Widget scaled(Widget child, double scale, {bool bold = false}) => MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale), boldText: bold),
      child: child,
    );
// scale in {1.0, 1.3, 2.0} x bold in {false, true}
```
(`TextScaler.linear` is correct *in tests* — you are deliberately pinning a value. It is wrong in production.)

**`accessibility_tools` 2.8.0** (rebelappstudio.com, verified publisher, published ~8 months before 2026-07-27, MIT, deps: `collection`, `flutter`, `flutter_test` only, **no network**, compiles out of release) as a `dev_dependency`. It flags unlabelled tap targets, sub-48dp targets, missing input/image labels, and large-font overflow, live in the debug app, plus a panel to toggle text scale / bold text / colour-blindness simulation.

### 12.2 Manual — the per-screen sweep

Run this on **one small iPhone and one small Android**, in a dark room, holding a torch.

For each of the 12 screens (spec §9): Flock · Ewe Card · Quick Entry · Lambing Entry · Lamb Card · Foster · Pen Board · Treatments · Reminders · Season Summary · Export · Settings.

| # | Pass | Definition of done |
|---|---|---|
| 1 | **Dark, default** | No white flash from cold launch. No surface lighter than `#2A2A2A`. Every text ≥ 4.5:1 (measured, not eyeballed). |
| 2 | **Largest text** (iOS AX5, Android 200% + largest display size) | No clipped text, no overlapping text, no horizontal scroll, every target still ≥60pt, every action still reachable. Pen board has reflowed to ≤2 columns. |
| 3 | **Bold text on** | Nothing reflows into overflow. No text got *lighter* (the w900 bug, §4.5). |
| 4 | **Reduce motion on** (both platforms — remember they're different flags) | No slide transitions, no shimmer, no pulsing badge. Nothing became *un*discoverable because its animation was the affordance. |
| 5 | **Increase Contrast on (iOS)** | High-contrast theme engaged; the four status colours are still distinguishable. |
| 6 | **Grayscale filter on** | Every pen-board status, every alive/dead lamb, every withdrawal state is still identifiable. (Apple's own recommended test.) |
| 7 | **VoiceOver / TalkBack, eyes closed** | Complete the full 15-second core loop — pick animal, record lambing, hear the confirmation — without looking. Then: open a ewe card, foster a lamb, log a treatment, export a CSV. |
| 8 | **Voice Control (iOS), "Show names"** | Every visible button's spoken name matches its visible text. Complete the core loop by voice only. |
| 9 | **Switch Control (iOS) / Switch Access (Android)** | Every interactive node is reachable, named, and nothing times out. |
| 10 | **One thumb, one hand, right and left** | Every primary action within a 60pt-radius arc of the resting thumb. No two-hand reach on Quick Entry. |
| 11 | **Glove / freezer-bag** | Physically test. Spec §17.4 flags this as an open question — resolve it before locking the interaction model, because if a bag kills capacitive taps the whole design pivots to volume-button shortcuts. |
| 12 | **Airplane mode + no network permission** | App fully functional. (Also: confirm the release Android manifest declares no `INTERNET` permission — Flutter injects it into the *debug/profile* manifests only, and none of the a11y/i18n dependencies here add one.) |

**Ship gate:** rows 1–10 green on all 12 screens. Row 11 informs design, not release. Row 12 is a build-config assertion, run in CI on the release APK/AAB.

### 12.3 Declaring the Apple labels

Once 1–10 pass, declare in App Store Connect: **VoiceOver, Voice Control, Larger Text, Sufficient Contrast, Differentiate Without Color Alone, Reduced Motion, Dark Interface.** Leave Captions and Audio Descriptions undeclared (no media). Apple: *"Re-evaluate your app's support … every time you update the app."* Put it in the release checklist, not in someone's memory.

---

## 13. Rejected alternatives

| Rejected | In favour of | Why it lost |
|---|---|---|
| **`easy_localization` 3.0.8** (unverified uploader, published ~12 months ago, prerelease 4.0.0-dev.0) | `flutter_localizations` + gen-l10n | Runtime **string-key** lookup with no compile-time safety — `context.tr('savd')` compiles and ships. Loads translations from **assets at runtime** (async, can fail), pulls in `shared_preferences` and `easy_logger`, and its loader ecosystem explicitly supports **HTTP** sources. For an app whose thesis is "no network path exists", adding a package whose extension point is remote translation loading is the wrong shape. |
| **`slang` 4.18.0** (tienisto.com, verified, published ~26 days ago, 773 likes) | gen-l10n | Genuinely good: type-safe, compile-time, no network, `dart run slang` without build_runner. It loses on **zero** technical merit and one practical one: gen-l10n is in the SDK, needs no third-party maintenance commitment, is what `GlobalMaterialLocalizations` already uses, and is what every future contributor will recognise. For a solo dev whose risk is abandonment, "in the box" beats "slightly nicer". Revisit only if ARB ergonomics actually become a bottleneck. |
| **`intl_translation` 0.22.0** (dart.dev, verified, published ~12 days ago) | gen-l10n | Flutter's own docs call the `extract_to_arb`/`generate_from_arb` workflow superseded: *"Recommended: Use gen_l10n (the modern tool) instead."* Extra build step, no benefit here. |
| **`flutter_screenutil` 5.9.3** (unverified uploader, published **~2 years ago**) | `MediaQuery.textScalerOf` + real responsive layout | Its whole model is "design at a reference size and scale everything", which fights the OS text scale rather than composing with it. Its README's own escape hatch is `textScaleFactor: 1.0` — the exact anti-pattern (§4.2) that fails Apple's Larger Text criterion. Two years without a stable release, unverified publisher. Hard no. |
| **Global `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)`** | reflow (fewer grid columns → list) | Overrides the user's OS setting, breaks Android 14 nonlinear scaling, and makes the Larger Text declaration a lie. |
| **`SnackBar` for the save confirmation** | a persistent in-place live region | SnackBar gives you `liveRegion` free (verified at `snack_bar.dart:828`), but it occupies the bottom thumb zone, times out, and stacks badly during triplets. Keep SnackBar only for undoable, low-stakes actions. |
| **`SemanticsService.announce` / `sendAnnouncement` for "Saved"** | `liveRegion` | `announce` is deprecated; `sendAnnouncement` is a **guaranteed no-op on Android** (`NO_ANNOUNCE` always set). Relying on it means the primary confirmation is silent for half the userbase. |
| **`table`/`row`/`cell` roles on the pen board** | `list`/`listItem` | Pens are an unordered collection; table roles promise column semantics that don't exist and invite table navigation that yields nothing. |
| **`MergeSemantics` on pen cells** | `Semantics(label:) + ExcludeSemantics` | Merging joins child labels with newlines and takes the first gesture handler — fragile the moment a cell grows a badge, and it gives you no control over sentence order. |
| **Red as the night theme's primary** | amber (`#FFB000`) | `#FF0000` on `#121212` is 4.69:1 for a normal observer and far worse for a protanope; amber is 10.23:1 and nearly as good for scotopic adaptation. |
| **`#000000` app surface** | `#121212` | 21:1 is more contrast than anyone needs, and pure black hides card boundaries and smears on OLED scroll. Reserve `#000000` for the high-contrast theme. |
| **A translucent / blurred app bar** | opaque surfaces | Flutter 3.44 exposes no reduced-transparency flag, so you cannot honour the user's preference. Don't create the problem. |
| **`Locale('en','GB')` first in `supportedLocales`** | bare `Locale('en')` first | `languageLocales[code] ??= locale` is first-wins, so en_GB first gives *every* other English locale British date formats. |
| **`DateFormat.yMd` for human-facing dates** | `d MMM y` | `13/07` vs `07/13` is a silent six-month error on a withdrawal date. |
| **Inferring kg/lb from locale** | explicit user setting | A wrong inference silently mislabels every weight, and spec §12.4 forbids silent correction. |
| **Producing a VPAT / claiming EN 301 549 conformance** | doing the work, claiming nothing | The EAA's covered-service list doesn't include this product. Effort is better spent on the manual sweep. |

---

## 14. Pitfalls

| # | Pitfall | Mitigation |
|---|---|---|
| 1 | **`MediaQuery.disableAnimationsOf` returns false on iOS forever.** You test reduce-motion on an iPhone, see no effect, assume the API is broken, and ship un-reduced motion. | Use `prefersReducedMotion()` from §2. Write a test that asserts both branches. |
| 2 | **`sendAnnouncement` silently does nothing on Android.** The save confirmation is inaudible for TalkBack users and you never notice because you tested on iOS. | `liveRegion` for everything load-bearing; gate any `sendAnnouncement` on `MediaQuery.supportsAnnounceOf`. |
| 3 | **The live region doesn't re-fire for identical text.** Two consecutive twin births produce the same string; the second is silent. Verified: `AccessibilityBridge.java:2025` requires `didChangeLabel()`. | Include the tag *and* the time in the confirmation label. Assert uniqueness in a test. |
| 4 | **`supportedLocales` order silently gives US users British dates** (or UK users US dates). Nobody notices until an export is misread. | `Locale('en')` first. Add a test that asserts `basicLocaleListResolution` maps `en-GB→en_GB`, `en-US→en`, `fr-FR→en`. |
| 5 | **`intl: ^0.20.3` fails to resolve** because `flutter_localizations` pins `intl: 0.20.2` exactly. | `intl: any`. Never pin `intl` by hand. Re-check the pin after every Flutter upgrade. |
| 6 | **Bold Text makes your w900 headings w700** — i.e. *lighter*. Open bug [#139712](https://github.com/flutter/flutter/issues/139712). | Cap all weights at w700. Add a lint or a `TextTheme` unit test asserting no style exceeds w700. |
| 7 | **Text spacing overrides look implemented but are web-only.** You write `if (MediaQuery.maybeLineHeightScaleFactorOverrideOf(context) != null)` and it never fires on mobile. | Don't read them. Bake `height: 1.4`–`1.5` into the base `TextTheme` and make layouts tolerate more. |
| 8 | **`MergeSemantics` produces newline-joined nonsense** as cells grow badges. | `Semantics(label:)` on the parent + `ExcludeSemantics` on the visuals. |
| 9 | **`OrdinalSortKey` mixed with unsorted siblings** reorders unpredictably: unnamed keys traverse before named ones, and all siblings in a group must use the same key type. | Prefer tree order. If you must sort, sort *every* sibling in that group. |
| 10 | **Tag numbers read as cardinals.** "412" becomes "four hundred and twelve"; the shepherd hears a number that isn't on any tag. | `SpellOutStringAttribute` on the tag range only (§3.2, §11.5). |
| 11 | **`FittedBox` used to "fix" text overflow** at large scale. It looks like a fix and is actually a silent clamp. | Grow the container, or reflow. Ban `FittedBox` around user-facing text in code review. |
| 12 | **Elevation-tint-only surface separation vanishes under a head torch.** | Add explicit outlines; never let a tonal difference of <3:1 carry meaning. |
| 13 | **Photos invert under iOS Smart/Classic Invert** and Flutter can't opt out (`accessibilityIgnoresInvertColors` unexposed, [#10603](https://github.com/flutter/flutter/issues/10603)). | Never make a photo the sole carrier of meaning. Test once under Smart Invert. |
| 14 | **Numeric dates in CSV are re-interpreted by Excel.** A UK user's `13/07/2026` becomes text; a US user's becomes 13 July or 7 December depending on machine locale. | Ship `date_iso` (`2026-07-13`) as the machine column, `date_display` as the human one. |
| 15 | **Terminology drift into the ARB.** Someone "simplifies" `"Turn out {term} {tag}?"` to `"Turn out ewe {tag}?"` in a hurry. | The ARB `description` field states the rule; add a CI grep for the domain nouns (`\bewe\b`, `\bgimmer\b`, `\btheave\b`, …) in `app_*.arb` outside the `term*Default` keys. |
| 16 | **Plural-by-suffix.** `'$count ${term}s'` → "3 sheeps". | Store singular+plural in the terminology map; prefer label/value layout (§11.4). |
| 17 | **`generate: true` forgotten** after a `pubspec.yaml` merge → `AppLocalizations` import fails with a confusing "target of URI doesn't exist". | Keep the import path in `lib/l10n/` (real files, committed to git), so a stale generation is visible in the diff rather than invisible in a synthetic package. |
| 18 | **`showDatePicker` opens on Sunday-first** because the locale resolved to bare `en`. Users mis-tap by one column. | Same fix as #4. Add a widget test asserting `MaterialLocalizations.of(context).firstDayOfWeekIndex == 1` under `en_GB`. |
| 19 | **Haptic fires on tap, not on commit.** The user feels "saved" and walks away; the write failed. | Fire `successNotification()` from the DAO's post-commit callback only. |
| 20 | **Accessibility work done last.** Retrofitting Semantics onto 12 screens of hand-built widgets is a week; doing it as you go is minutes per screen. | Add `Semantics` in the same commit as the widget. Make `labeledTapTargetGuideline` a CI gate from commit #1, so it can never regress. |
| 21 | **`Semantics(header: true)` silently stopped working in 3.44.** It compiles, it reads correctly in review, and it does nothing on either mobile platform — so the Ewe Card's summary line becomes unreachable by heading navigation and nobody notices without a device test. | `headingLevel: 1..6` everywhere (§3.9). CI grep banning `header:` in `Semantics(`/`SemanticsProperties(`, plus a per-screen test asserting ≥1 node with `headingLevel > 0`. |
| 22 | **`containsSemantics` deprecated in 3.41** in favour of `isSemantics`; copied-in test snippets from older blog posts will warn or break on the next upgrade. | Write all new semantics matchers with `isSemantics`. |
| 23 | **Hand-rolling a non-text contrast check that 3.44 may already ship.** Duplicated, and yours will drift from `kMinimumRatioNonText`. | Grep the installed SDK first (§12.1). Adopt the framework evaluation if it is public. |

---

## 15. How this serves the 3am test and the offline-only constraint

**The 3am test.** Almost every recommendation above is load-bearing for the shepherd before it is load-bearing for anyone with a permanent disability:

- 60×60 targets with 12pt gutters and hit slop → gloved, cold, imprecise thumbs.
- No colour-alone status → a head torch washes out hue long before it washes out shape.
- One complete sentence per pen cell → the same string that TalkBack reads is the string that makes the cell legible at arm's length.
- No clamped text → the user who left their glasses in the house has already turned the system font up; honouring it *is* the feature.
- Reduce-motion → an animated transition is 300ms of not being able to read the screen while holding a lamb.
- Live-region "Saved" with tag + time → the receipt that lets you put the phone down and trust it, which is what makes the 15-second loop actually 15 seconds.
- Haptics on commit → the only confirmation channel that survives a phone inside a freezer bag.
- Unambiguous dates → a misread withdrawal date is the one bug in this app that can put meat into the food chain.

**Offline-only.** Nothing here opens a socket:

- `flutter_localizations` and `intl` bundle their CLDR data as generated Dart and register it with `initializeDateFormattingCustom` at delegate-load time — no asset fetch, no HTTP, no async surprise.
- gen-l10n generates source at build time; the running app reads nothing external.
- `accessibility_tools` is a `dev_dependency` that compiles out of release and has three dependencies, all local.
- `HapticFeedback` and `SystemSound` are platform channels to the OS.
- The rejected `easy_localization` is rejected partly *because* its loader ecosystem includes HTTP sources.
- No accessibility or localisation decision in this document requires the `INTERNET` permission, so the Android release manifest can continue to declare none.

---

## Sources

Fetched 2026-07-27. Framework/engine line numbers are from the `stable` branch of `flutter/flutter` (`flutter-3.44-candidate.0`).

**W3C / WCAG**
- https://www.w3.org/WAI/WCAG22/quickref/
- https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
- https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
- https://www.w3.org/TR/wcag2ict/

**Apple**
- https://developer.apple.com/design/tips/
- https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/
- https://developer.apple.com/help/app-store-connect/manage-app-accessibility/sufficient-contrast-evaluation-criteria/
- https://developer.apple.com/help/app-store-connect/manage-app-accessibility/larger-text-evaluation-criteria/
- https://developer.apple.com/help/app-store-connect/manage-app-accessibility/differentiate-without-color-alone-evaluation-criteria/
- https://developer.apple.com/help/app-store-connect/manage-app-accessibility/voiceover-evaluation-criteria/
- https://developer.apple.com/help/app-store-connect/manage-app-accessibility/voice-control-evaluation-criteria/
- https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria/

**Android / Google**
- https://developer.android.com/guide/topics/ui/accessibility/apps
- https://support.google.com/accessibility/android/answer/7101858
- https://developer.android.com/develop/ui/compose/accessibility/scalable-content
- https://developer.android.com/about/versions/14/features (via search result summary)

**Flutter docs**
- https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility
- https://docs.flutter.dev/ui/accessibility/ui-design-and-styling
- https://docs.flutter.dev/ui/accessibility/assistive-technologies
- https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization
- https://docs.flutter.dev/release/breaking-changes
- https://docs.flutter.dev/release/breaking-changes/deprecate-textscalefactor
- https://docs.flutter.dev/release/breaking-changes/android-14-nonlinear-text-scaling-migration
- https://docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source
- https://docs.flutter.dev/release/breaking-changes/semantics-header-heading-level
- https://docs.flutter.dev/release/breaking-changes/deprecate-contains-semantics
- https://docs.flutter.dev/release/breaking-changes/modal-router-semantics-order
- https://docs.flutter.dev/release/release-notes
- https://docs.flutter.dev/release/release-notes/release-notes-3.44.0

**Flutter API (api.flutter.dev, stable)**
- https://api.flutter.dev/flutter/painting/TextScaler-class.html
- https://api.flutter.dev/flutter/widgets/MediaQueryData-class.html
- https://api.flutter.dev/flutter/widgets/MediaQueryData/boldText.html
- https://api.flutter.dev/flutter/widgets/MediaQueryData/highContrast.html
- https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html
- https://api.flutter.dev/flutter/widgets/MediaQueryData/alwaysUse24HourFormat.html
- https://api.flutter.dev/flutter/widgets/MediaQueryData/lineHeightScaleFactorOverride.html
- https://api.flutter.dev/flutter/widgets/MediaQuery/textScalerOf.html
- https://api.flutter.dev/flutter/widgets/Semantics-class.html
- https://api.flutter.dev/flutter/widgets/Semantics/Semantics.html
- https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html
- https://api.flutter.dev/flutter/widgets/ExcludeSemantics-class.html
- https://api.flutter.dev/flutter/widgets/Text/semanticsLabel.html
- https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver-class.html
- https://api.flutter.dev/flutter/semantics/SemanticsProperties-class.html
- https://api.flutter.dev/flutter/semantics/SemanticsProperties/liveRegion.html
- https://api.flutter.dev/flutter/semantics/SemanticsProperties/traversalParentIdentifier.html
- https://api.flutter.dev/flutter/semantics/SemanticsService-class.html
- https://api.flutter.dev/flutter/semantics/SemanticsService/announce.html
- https://api.flutter.dev/flutter/semantics/SemanticsService/sendAnnouncement.html
- https://api.flutter.dev/flutter/semantics/OrdinalSortKey-class.html
- https://api.flutter.dev/flutter/dart-ui/SemanticsRole.html
- https://api.flutter.dev/flutter/dart-ui/AccessibilityFeatures-class.html
- https://api.flutter.dev/flutter/dart-ui/SpellOutStringAttribute-class.html
- https://api.flutter.dev/flutter/rendering/CustomPainter/semanticsBuilder.html
- https://api.flutter.dev/flutter/rendering/CustomPainterSemantics-class.html
- https://api.flutter.dev/flutter/services/HapticFeedback-class.html
- https://api.flutter.dev/flutter/services/SystemSound-class.html
- https://api.flutter.dev/flutter/material/MaterialLocalizations-class.html
- https://api.flutter.dev/flutter/material/MaterialApp/highContrastDarkTheme.html
- https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html
- https://api.flutter.dev/flutter/material/SnackBar-class.html
- https://api.flutter.dev/flutter/flutter_localizations/GlobalMaterialLocalizations-class.html
- https://api.flutter.dev/flutter/flutter_test/AccessibilityGuideline-class.html
- https://api.flutter.dev/flutter/flutter_test/iOSTapTargetGuideline-constant.html
- https://api.flutter.dev/flutter/flutter_test/SemanticsController-class.html
- https://api.flutter.dev/flutter/widgets/MediaQuery-class.html (full `<x>Of` / `maybe<x>Of` inventory)
- https://api.flutter.dev/flutter/widgets/MediaQuery/withClampedTextScaling.html
- https://api.flutter.dev/flutter/widgets/MediaQuery/applyTextStyleOverrides.html
- https://api.flutter.dev/flutter/widgets/MediaQuery/boldTextOf.html
- https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html
- https://api.flutter.dev/flutter/widgets/MediaQueryData/supportsAnnounce.html
- https://api.flutter.dev/flutter/widgets/Semantics/localeForSubtree.html
- https://api.flutter.dev/flutter/widgets/basicLocaleListResolution.html
- https://api.flutter.dev/flutter/semantics/AttributedString-class.html
- https://api.flutter.dev/flutter/semantics/SemanticsInputType.html (404 — enum not exposed under this path on 3.44)
- https://api.flutter.dev/flutter/material/MaterialTapTargetSize.html
- https://api.flutter.dev/flutter/material/MaterialLocalizations/firstDayOfWeekIndex.html
- https://api.flutter.dev/flutter/services/HapticFeedback/vibrate.html
- https://api.flutter.dev/flutter/services/SystemSoundType.html

**Flutter GitHub (PRs / issues fetched)**
- https://github.com/flutter/flutter/pull/178102 (iOS motion accessibility features added in 3.44)
- https://github.com/flutter/flutter/pull/183569 (non-text colour contrast evaluation, `kMinimumRatioNonText = 3.0`)
- https://github.com/flutter/flutter/issues?q=is%3Aissue+reduce+transparency+accessibility (confirms no iOS Reduce Transparency API)

**pub.dev (package verification)**
- https://pub.dev/packages/intl · https://pub.dev/packages/intl/changelog
- https://pub.dev/documentation/intl/latest/intl/DateFormat-class.html
- https://pub.dev/packages/slang
- https://pub.dev/packages/easy_localization
- https://pub.dev/packages/flutter_screenutil
- https://pub.dev/packages/flutter_localizations (303-redirects to api.flutter.dev — confirms it is an SDK package, not a pub package)

**Additional W3C / Android pages fetched**
- https://www.w3.org/TR/WCAG22/
- https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html
- https://www.w3.org/WAI/WCAG22/Understanding/non-text-content.html
- https://developer.android.com/about/versions/16/behavior-changes-all (Android 16 deprecates `announceForAccessibility` / `TYPE_ANNOUNCEMENT`; recommends `setAccessibilityLiveRegion`)
- https://jfly.uni-koeln.de/color/ (Okabe & Ito, Color Universal Design)

**Flutter source read directly (stable branch)**
- `engine/src/flutter/lib/ui/window.dart` (AccessibilityFeatures bitfield + docs, ~928–1010)
- `engine/src/flutter/shell/platform/darwin/ios/framework/Source/AccessibilityFeatures.swift`
- `engine/src/flutter/shell/platform/android/io/flutter/view/AccessibilityBridge.java` (517, 444–451, 655–671, 1105–1107, 2025–2027, 2471–2484, 3266–3275)
- `packages/flutter/lib/src/widgets/text.dart` (716–750)
- `packages/flutter/lib/src/widgets/media_query.dart` (88–131, 225–239, 313–347, 593–747, 2333–2353)
- `packages/flutter/lib/src/widgets/app.dart` (146–235, 356)
- `packages/flutter/lib/src/material/app.dart` (245–246, 458–476, 1003–1008)
- `packages/flutter/lib/src/material/snack_bar.dart` (228, 624, 828–851)
- `packages/flutter_localizations/pubspec.yaml`
- `packages/flutter_localizations/lib/src/material_localizations.dart` (94–128, 197, 732–757)
- `packages/flutter_localizations/lib/src/utils/date_localizations.dart`
- `packages/flutter_localizations/lib/src/l10n/generated_material_localizations.dart` (8027, 8642, 8742)
- `packages/flutter_localizations/lib/src/l10n/README.md`
- `packages/flutter_tools/lib/src/commands/generate_localizations.dart` (31–70)
- `packages/flutter_tools/lib/src/localizations/localizations_utils.dart` (329–360)
- `packages/flutter_tools/lib/src/localizations/gen_l10n_templates.dart` (228–300)
- `packages/flutter_tools/lib/src/flutter_manifest.dart` (436–437)

**GitHub issues / PRs**
- https://github.com/flutter/flutter/pull/178102 (iOS motion accessibility features, 3.44)
- https://github.com/flutter/flutter/issues/177801 (open) — boldText ignores TextSpan custom weight
- https://github.com/flutter/flutter/issues/139712 (open) — boldText makes extra-bold text less bold
- https://github.com/flutter/flutter/issues/162804 (open) — boldText false not honoured on iOS
- https://github.com/flutter/flutter/issues/14570 (closed) — iOS semantics traversal order
- https://github.com/flutter/flutter/issues/67814 — FocusTraversal glitches in GridView
- https://github.com/flutter/flutter/issues/36307 — GridView cell not fully revealed under TalkBack
- https://github.com/flutter/flutter/issues/10603 (closed) — iOS Smart Invert
- https://github.com/flutter/flutter/issues/180096 (closed) — remove CalendarDatePicker announcements

**pub.dev package pages**
- https://pub.dev/packages/intl
- https://pub.dev/packages/intl_translation
- https://pub.dev/packages/accessibility_tools
- https://pub.dev/packages/slang
- https://pub.dev/packages/easy_localization
- https://pub.dev/packages/flutter_screenutil
- https://pub.dev/documentation/intl/latest/intl/DateFormat-class.html

**Other**
- https://commission.europa.eu/strategy-and-policy/policies/justice-and-fundamental-rights/disability/union-equality-strategy-rights-persons-disabilities-2021-2030/european-accessibility-act_en
- https://jfly.uni-koeln.de/color/ (Okabe & Ito, Color Universal Design — swatches are a figure, hex values not given as text)

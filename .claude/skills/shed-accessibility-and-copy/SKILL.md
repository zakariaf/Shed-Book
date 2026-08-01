---
name: shed-accessibility-and-copy
description: >-
  What a widget says rather than shows — semantics, headings, text scaling, and every string through
  ARB in en_GB formats. Use when adding or changing any label, string, heading, date or number
  format. Do NOT use for contrast (indelible-design-system).
---

# What a widget says

`docs/engineering/10-accessibility-and-i18n.md` owns this area and carries the truth tables and
catalogues. It, `docs/engineering/CONVENTIONS.md` §5.4 / R60 / R66–R68, and
`docs/research/00-tech-decisions.md` §5 (the only source of version numbers) are **BINDING**. Open
the section; never re-derive a table from memory.

**Do NOT use this skill for** contrast, palettes, type tokens, ink or letterforms
(`indelible-design-system` owns the value); writing the semantics, traversal or overflow assertions
(`shed-testing` owns every gate test — this skill states what must be true, that skill states how it
is proved); or file, type, provider, key and column names (`shed-conventions`). The
one-word-per-concept table and the banned-word list are in `CLAUDE.md`; obey them there.

## 1. Nothing here gets semantics for free

`Container`, `GestureDetector`, `CustomPaint` and every bespoke tap surface contribute **no** node —
a description of this app. `ShedTapTarget` takes a `required semanticLabel` and sets
`Semantics(onTap:)` (§2.11); a labelled node with no tap **action** announces correctly and then
refuses to activate under Switch Control. The three label rules that break (all eight: 10 §3.2):

- **The label contains the visible words.** Voice Control's "Show names" displays your label; if the
  row prints `TURN OUT` and the label says "Release from pen", the spoken command fails.
- **No control type, no state** — `'Turn out'`, never `'Turn out button'` or `'Pen 4, selected'`;
  use `selected:` / `enabled:` / `checked:`.
- **The noun comes from `terminologyProvider`**, never a hard-coded "ewe" (§7).

**Tags are spelled out, and only the tag** — 412 is "four one two", the number printed on the ear.
`spellOutTag(text, tag)` in `lib/core/ui/tag_semantics.dart`, through `attributedLabel:`, never
`label:`; over a whole label it gives you "g-i-m-m-e-r".

**`MergeSemantics` is banned** (`a11y.merge_semantics`) — it joins child labels with **newlines**,
takes the first gesture handler, and fixes no sentence order; use `Semantics(label:) +
ExcludeSemantics(child:)`. **`sortKey` is banned** (`a11y.sort_key`) — build in reading order;
`OrdinalSortKey` sorts only among siblings and is undefined if one sibling lacks it.

## 2. Headings — `headingLevel`, never `header:`

**`Semantics(header: true)` is a no-op on both platforms as of 3.44** — it compiles, passes review,
and does nothing. Titles emit `headingLevel: 1`, sections `2` (`a11y.header_bool` gates the old
spelling). Take the hierarchy from 10 §3.4 and **invent no section the screen does not render**:
Lambing Entry, Lamb Card, Foster, Quick Entry and note search get **no** level-2 headings — each is
one task, and a heading stop is navigation on a screen whose purpose is having none. They keep a
level-1 title, because the gate asserts one `headingLevel > 0` node on all **14** variants (R58).

## 3. Live regions, and the receipt

**Never `SemanticsService.announce`, never `sendAnnouncement`** — the second is a guaranteed no-op
on Android (`NO_ANNOUNCE` is set unconditionally at bridge construction), and Android 16 deprecates
announcements in favour of `setAccessibilityLiveRegion`, which is what `Semantics(liveRegion: true)`
compiles to. Gate row `a11y.announce`, but **10 §10 records that its pattern matches only
`announce`** — treat `sendAnnouncement` as unguarded until the widening lands.

**Owner ruling P2 — there is no SnackBar**, so the receipt inherits no framework semantics wrapping.
What the receipt *is* and how it is drawn belong to **indelible-states-and-feedback**; what it must
*say* is this skill's, and three consequences follow:

1. **The receipt node carries its own semantics** — it inherits none of `SnackBar`'s framework
   wrapping, so it sets `liveRegion: true` and `role: SemanticsRole.status` itself.
2. **Its label must differ from its predecessor** or Android will not re-announce it: the live
   region fires on `didChangeLabel()` and compares strings. Uniqueness lands on
   `SaveReceipt.summary` (`lamb 3`, `ease 2`, `Alamycin · meat 28 d`), because `at` is `HH:mm` and
   two writes inside one minute share it. **Fix a collision with a more specific `summary`, never a
   zero-width or trailing-space disambiguator.**
3. **Warnings are spoken, not only badged** — a non-empty `warnings` appends the first
   `Warning.message`. The announcement flags; it never fixes (spec §12.4).

**Undo is a time-boxed strike affordance in the row's own margin** — you strike, you never erase.
State the window **in seconds**; "until the SnackBar is dismissed" is the wording that made undo
unimplementable. The only other live regions: the keypad buffer, the match count, the withdrawal
countdown as it crosses to clear, the reminders "overdue" heading as the tick moves an item in.

## 4. Text scaling — 200% is the floor, not the ceiling

- `TextScaler`, never `textScaleFactor` (`a11y.scale_factor`, including the theme layer).
- **Clamping is a bug**, and `withClampedTextScaling` / `TextScaler.clamp` / any
  `copyWith(textScaler:)` is gated (`type.clamp`): it overrides the setting a shepherd who left
  their glasses in the house already turned up, makes the Larger Text label a lie, and discards
  Android 14's non-linear curve. **No floor either** — 18 pt is the floor at scale 1.0. Sole
  exception: `MediaQuery.withNoTextScaling` around icon fonts, whose target is still ≥ 60 pt.
- **`FittedBox` around user-facing text is banned** (`type.fitted_box`) — a silent clamp that shrinks
  the glyphs the user deliberately enlarged, passing the overflow matrix while failing the human.
- **No style exceeds `FontWeight.w700`** (`type.weight_cap`): `Text.build` merges `w700`
  unconditionally under Bold Text and `merge` wins, so w800/w900 render **lighter** in the mode that
  exists to make them heavier (flutter#139712). Buy stroke with size, never weight.
- **Never ellipsise a user's own words** — notes, product names and `TermLabel` overrides wrap. A row
  that must hold more text **grows taller**; it never shrinks its glyphs. That is the answer, not a
  clamp. **`10 §3.5`/`§4.2`'s reflowing 4 → 3 → 2 → 1 tile grid does not apply**: Indelible's pen
  board is already one column of twelve ruled 88 pt rows, so there is nothing to reflow — `06 §11`
  and `10 §5.2`'s pen-*tile* model is superseded (**indelible-marks-and-strikes** §7). Any width the
  scaled metric (`textScalerOf(context).scale(...)`) still governs is a *column inside a row*, and it
  wraps to a second line rather than reflowing the page.
- Do not read `lineHeightScaleFactorOverride` / `letterSpacingOverride` / `wordSpacingOverride`:
  the only engine implementations are **web**, so on iOS and Android they are permanently `null`.
  Meet WCAG 1.4.12 by construction instead — no fixed-height text container, ever.

## 5. Colour is never the only channel

Every state carries three of colour, shape, word, position, never colour alone (10 §5). This skill
owns the **word**; `indelible-design-system` owns ink and shape.

- A marker with no spoken form needs a word beside it in both channels — the edited-time dagger
  always travels with its provenance label.
- `NOT APPLICABLE` and `NOT RECORDED` are different words for different states; neither is ever `0`
  or blank. The treatment row paints them where a countdown would sit — `ShedCountdown` takes a
  `ClearsOn` (§2.7), so a countdown for an unrecorded period is unconstructible, not merely banned.
- Three strings are exempted from the stamp size and take the body floor instead, because each is the
  sole carrier of its meaning on its line. **`indelible-design-system` owns that corrected exemption
  test and the two sizes**; this skill only requires that each of the three is also *spoken*, since a
  sole carrier of meaning must exist in both channels.

## 6. Motor accessibility

Target sizes and separation are `06 §6`'s numbers, and **indelible-page-and-screens** carries the
floor Indelible actually builds to — read them there rather than from a number in this file. **Every action is reachable
by single discrete taps**: no swipe-to-delete, long-press multi-select, drag, pinch, pull-to-refresh
or shake-to-undo; a gesture is only ever an accelerator for a discoverable button. **Nothing times
out** — a switch user takes 20 seconds to reach a button, so the receipt persists, no sheet
auto-dismisses, `isDismissible: false` everywhere.

**`showDatePicker` / `showTimePicker` do not ship** (`a11y.material_picker`): the dial is a drag,
its keyboard mode opens the system IME, calendar cells are half the tap floor. **No free-text date
field either** — a shepherd typing `07/03` means 7 March, and a parser reading 3 July has silently
corrupted a record. The control is **relative buttons (Today · Yesterday · 2 days ago) plus
`ShedKeypad`** (R70). `GlobalMaterialLocalizations` is still required for framework strings.

## 7. Every user-facing string is an ARB message

`lib/l10n/app_en.arb`, one locale (`en`, British English), gen-l10n. Copy `l10n.yaml` and the
`pubspec.yaml` block from 10 §8.2 verbatim; three bite: **`intl` takes the unusual constraint the
decision record's dependency table gives it** — `flutter_localizations` pins `intl` exactly, so the
obvious caret will not resolve, and **shed-dependencies-and-toolchain** owns that pin, not this
skill; **`synthetic-package` cannot be enabled on the pinned Flutter**, so a tutorial setting it
predates it; and
`lib/l10n/app_localizations*.dart` is **committed**, so a stale generation shows in a diff.

**`supportedLocales` is explicit and bare `Locale('en')` is FIRST**, then `en_GB`, then `en_IE`.
`basicLocaleListResolution` is first-wins (`languageLocales[code] ??= locale`), so `en_GB` first
gives every English speaker on earth British formats, and leaving it unset defaults to `en_US`.
Nobody notices until an export is misread.

- Ids are `screenConcept` / `conceptDetail` in `lowerCamel`, never the English text.
- **Every message carries a `description`, and a §12 string's description carries its safety
  rationale** — it is what stops a future contributor "improving" `as entered by you`.
- **Never format a date or time inside a message.** Pass a pre-formatted `String`: one authority.
- A string literal in a `Text(` under `lib/features/` is a gate failure (`copy.literal_text`).
- **Six things are deliberately not in the ARB and the list is closed** (10 §8.7): `Disclaimers.*`,
  the six `ShedFailure.userMessage` strings, `RecordedTime.provenanceLabel`, `NightErrorPanel`'s
  copy, every stable machine key, and the price (`copy.currency_literal`). A translator can soften a
  safety string; a `const` cannot be softened in one place. A seventh entry is a review conversation.

## 8. The terminology-placeholder rule

> **The ARB owns the frame; `terminologyProvider` owns the nouns. A domain noun never appears
> literally in a message — it arrives as a placeholder.** (10 §8.5, agreeing with 05 §8.)

`"Turn out {term} {tag}?"`, never `"Turn out ewe {tag}?"` — gated by `copy.arb_domain_noun` over
`lib/l10n/`, skipping only the `term*Singular` / `term*Plural` keys. Resolve through
`Terminology.labelFor(AnimalClass)` (`terminologyProvider : Provider<Terminology>`, R68).

- **ICU cannot pluralise a runtime string** ("3 sheeps"): ICU picks the *category*, the map supplies
  both forms. Placeholders are `singularTerm` / `pluralTerm` — never `singular` / `plural`, because
  `plural` is an ICU keyword that parses today and stops on the next gen-l10n release — and `count`
  is `"type": "num"`. **Never derive a plural by appending "s"**; guessing the user's second word is
  safety rule 4.
- **Prefer label/value to sentences**: `Ewes · 132`, not "There are 132 ewes." Semantics labels use
  the user's noun too; only the tag range is spelled out.
- Seeding happens once, from `lib/features/settings/terminology_bootstrap.dart`, and **a locale
  change or an app update never rewrites a user's term.** `lib/domain/` and `lib/data/` may not
  import `AppLocalizations`, which is why the columns seed `NULL` and resolve at the presentation edge.
- The 40 vocabulary labels map mechanically, `vocab_terms.key` → `'vocab' + upperCamel(key)` (R66);
  a seeded key with no message renders blank at 3am.

## 9. Dates, numbers and units for en_GB

`lib/core/ui/formatters.dart` is the **only** `package:intl` call site in `lib/` outside `lib/data/`
and holds the five `formatShed*` functions plus `ShedLocaleX`. A controller never formats for
display. Every `DateFormat` gets an explicit locale — a `null` locale in a background isolate
silently produces `en_US` — and **no `DateFormat` runs off the root isolate**.

- **No date a human reads is all-numeric** (R60, `copy.numeric_date`): `d MMM y` → `11 Mar 2026`,
  `d MMM` → `14 Jul` in a tight cell. The owner's `dd/MM/yyyy` ruling records the *region's
  convention*; the app's answer is to never render it, because `13/07` and `07/13` are
  indistinguishable and a clear date misread by six months puts meat into the food chain. Numeric
  dates exist only in CSV, as `date_iso` **beside** `date_display` — ISO-8601 is the only format
  Excel and Numbers parse identically, and export is the only backup this app has.
- **Times are 24-hour `HH:mm`, always.** `alwaysUse24HourFormat` is deliberately unread — the one
  system preference the app overrides, because `3:21 AM` drops the token a tired reader needs and
  the receipt's uniqueness rule depends on a stable time string.
- **Every displayed event time carries its provenance label** (§5.4); a bare `03:21` is a review
  failure. Print `RecordedTime.provenanceLabel` verbatim — `recorded automatically` / `time entered
  by you` / `time edited by you` — and **never abbreviate it to a stamp word such as `AUTO`**, both
  because visible and spoken words must be the same string and because a table without R37's
  provenance quad has no edit verb at all.
- Decimal separator is `.`, fixed. Weight is `unitsProvider : Provider<WeightUnit>` (kg), never
  inferred from locale; storage is integer grams. **No `temperatureUnitProvider` ships** until a
  temperature column does (R68).

## 10. Copy per state, and the ship gate

Every brief lists the same states and each needs its own words (`07-screens.md` §1.4): Frame 1 is a
fixed-height placeholder, **never a spinner**; Empty gets one line of 18 pt copy and exactly one
60 pt action, which is the control the populated screen uses; **Filtered-empty reads differently
from Empty**, action "Clear filters"; Error names what could not be read and never prints the
exception message; Over-cap renders **nothing** on 7 of 12 screens. Statistics carry their
`definition` string verbatim from `lib/domain/stats/definitions.dart` (R61) — never a copy typed into
a screen, because those strings are printed into CSVs and PDFs that outlive the app. **There is no
birth-type chooser anywhere** (ruling P8), so no screen has a birth-type control to label;
`indelible-marks-and-strikes` owns what prints in its place.

Declare a Nutrition Label feature **only** when all seven common tasks complete with it, and
re-evaluate from the release checklist, not memory. Seven declared: VoiceOver, Voice Control, Larger
Text, Dark Interface, Differentiate Without Color Alone, Sufficient Contrast, Reduced Motion.
**Captions and Audio Descriptions undeclared** — speech recognition was cut from v1, so a voice note
cannot be transcribed; what makes that honest is **a voice note never carries a fact that exists
nowhere else.** Manual sweep: 10 §7.2's eleven rows over the 14 variants, one small iPhone and one
small Android, dark room. Rows 1–10 green is the gate; row 11 (glove / bag) informs design only.

Read `references/semantics-recipes.md` **when adding or changing a custom-painted or composite
widget** — the pen board, the keypad, the tally and the spread rows. Nothing else here repeats them.

## Definition of done

- [ ] Every `ShedTapTarget` has a `semanticLabel` containing its visible words; every enabled one
      exposes `SemanticsAction.tap`.
- [ ] `grep -rn "header:\|MergeSemantics\|OrdinalSortKey\|sortKey:\|textScaleFactor\|FittedBox\|withClampedTextScaling\|FontWeight.w8\|FontWeight.w9\|showSnackBar(\|SemanticsService\.\|showDatePicker(\|showTimePicker(" lib/`
      returns nothing.
- [ ] All 14 variants emit a `headingLevel > 0` node; no level-2 heading names a section the screen
      does not render.
- [ ] The receipt node sets `liveRegion: true` + `role: SemanticsRole.status` itself, consecutive
      labels differ through `SaveReceipt.summary`, and the undo window is stated in seconds.
- [ ] Every string under `lib/features/` is an ARB message with a `description`; every §12 string's
      description states its safety rationale; no domain noun appears literally outside
      `term*Singular` / `term*Plural`; all 40 vocabulary keys have a message.
- [ ] `supportedLocales` lists bare `Locale('en')` first; the `intl` constraint matches
      decision-record §5.1 character for character; `l10n.yaml` matches 10 §8.2.
- [ ] No human-facing date is all-numeric; the countdown reads `11 Mar 2026`; CSV carries `date_iso`
      beside `date_display`; every time is `HH:mm` and carries its provenance label, unabbreviated.
- [ ] At AX5 every pen row has grown taller, nothing clips, no text is ellipsised or `FittedBox`ed,
      and every target is still 60 pt — the board is one column at every scale and never reflows.
- [ ] `shed-testing`'s semantics, traversal and overflow gates are green on all 14 variants.

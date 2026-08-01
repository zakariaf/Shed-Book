# N09-T06 — `formatters.dart` — the one `package:intl` call site

| | |
|---|---|
| **Epic** | [N09 — The design system foundation](epic.md) · `00-README` §9 step 4 (1 of 3) |
| **Task** | 6 of 9 |
| **Depends on** | N09-T05 |
| **Commit** | one commit · `feat(ui): formatters.dart, the one intl call site` |

## 1. Why this task exists

`d MMM y`, 24-hour `HH:mm`, and **never** an all-numeric human date — because `03/04` is two
different days depending on which side of the Atlantic the reader learned to write, and *"a withdrawal
clear date misread by six months puts meat into the food chain"* (`10 §9.2`). One file, one import, so
the locale rules are in one place when Ireland is followed by somewhere else.

> **Correction to the earlier wording of this task.** `dd/MM/yyyy` is **not** the fallback "where a
> numeric date is unavoidable". Owner ruling §7.0 #3 records `dd/MM/yyyy` as the *region's convention*,
> and the app's answer to that convention is to never render it — because that convention is exactly
> what makes a numeric date ambiguous to a reader whose phone is set elsewhere. Numeric dates exist
> **only inside CSV, as ISO-8601 beside a spelled-month display column** (`10 §9.2`, R60). `dd/MM/yyyy`
> appears nowhere in this app, and `DateFormat.yMd` is a gate row.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/10-accessibility-and-i18n.md` | §9.1 (**the five `formatShed*` signatures and `ShedLocaleX`**) · §9.2 (never an all-numeric human date; the surface table) · §9.3 (date *entry* is the other half of the hazard) · §9.4 (24-hour, Monday-first, decimal separator, units) · §9.5 (`intl` outside the widget tree) · §8.3 (locale resolution order) | what this file must do, name for name |
| `docs/engineering/CONVENTIONS.md` | §1 (`formatters.dart` is *the ONLY `package:intl` call site in `lib/` outside `lib/data/`*) · §1.1 layer rule 7 · §5.4 (copy conventions) · R60 | the path, the import permission, the date rule |
| `docs/design/indelible.md` | §3.5 (tabular figures — every figure in the record *and* in a control) · §2.7 (`AUTO` / `EDITED` provenance stamps) · §7.6 (`CLEARS 12 AUG 2026` on the countdown row) | how the formatted string is rendered, and where the worst failure would land |
| `docs/research/00-tech-decisions.md` | §5 · #108 (`flutter_localizations` + gen-l10n/ARB from day one, `en` only, `intl` declared **`any`**) · #125 (PDF on a background isolate) | the version rule and the isolate rule |
| `docs/engineering/05-domain-correctness.md` | §4 | `RecordedTime.provenanceLabel` — the label this file never produces and never replaces |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-accessibility-and-copy` | it owns date and number formatting, the locale, the 24-hour clock and the never-numeric rule |
| `indelible-design-system` | the rendering rules for figures — tabular everywhere, and a time is never shown without its provenance |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/formatters_test.dart`
- **Test** — `'a human date is never all-numeric and the clock is 24-hour'`
- **Why it is red today** — nothing formats a date, so the first screen would call `DateFormat` inline.

```bash
fvm flutter test test/design/formatters_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion with the values, not the shape: `formatShedDate(LocalDate('2026-03-11'), 'en_GB')`
is exactly `'11 Mar 2026'`; `formatShedTime` of an instant at 03:21 local is exactly `'03:21'` and of
one at 15:21 is exactly `'15:21'`, never `'3:21 AM'`; and no string any formatter returns matches
`RegExp(r'^\d{1,4}[/.]\d{1,2}[/.]\d{1,4}$')`.

**Green.** The minimum code that passes, and nothing beyond it — the formatters, en_GB, Monday-first, and a test over the ambiguous dates.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**UI and tests only.** No schema, no domain (`Instant`, `LocalDate`, `Grams` and `WeightUnit` are
N04's and already exist), no data, no wiring, no controller. **No ARB entry either, and that is a
rule rather than an omission:** `10 §8.3` item 4 — *"dates and times are never formatted inside a
message"*; ARB supports `DateTime` placeholders with a `format` and this app does not use them,
because the one formatting site is this file and a message takes a pre-formatted `String`. Say so in
the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/formatters.dart` | **New.** The five `formatShed*` functions and the `ShedLocaleX` extension. The only file under `lib/` outside `lib/data/` that may `import 'package:intl/intl.dart'` — layer rule 7 names it explicitly |
| 2 | `test/design/formatters_test.dart` | **New.** The anchor, the value cases, and the `uk-zone` DST group |

`pubspec.yaml` is **not** touched: `intl` is already declared `any` (decision #108) and SDK-pinned to
**0.20.2**. Pinning it is a resolution failure waiting to happen — `flutter_localizations` pins it
from the SDK.

### 5.2 The signatures

`10 §9.1` declares these names under `CONVENTIONS §4`. Type them exactly:

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

The surface table these five implement (`10 §9.2`) — and the third row is the one that pays for the
rule:

| Surface | Format | Function |
|---|---|---|
| Any date a human reads | `d MMM y` → `11 Mar 2026` | `formatShedDate` |
| A date inside a tight chip (pen tile, countdown) | `d MMM` → `14 Jul` | `formatShedDayMonth` |
| CSV | **two columns** — `date_iso` (`2026-07-13`) and `date_display` (`13 Jul 2026`) | N21's, built on these |
| PDF | `d MMM y`, with the `†` edited-time marker and its footer legend | N21's |
| JSON backup | ISO-8601 only | N22's |

### 5.3 The details that are easy to get wrong

- **Every `DateFormat` is passed an explicit locale — never `null`, never omitted.** A `DateFormat`
  with a null locale silently produces `en_US`, and in a background isolate that is what you get with
  no warning at all. `10 §9.2` exists to prevent exactly that bug and `§9.5` names the isolate case.
- **Do not call `initializeDateFormatting()` in `lib/`.** After
  `GlobalMaterialLocalizations.delegate` loads, `DateFormat('d MMM y', 'en_GB')` just works — the
  delegate calls `initializeDateFormattingCustom` for every bundled locale, with no async, no assets
  and no network. **But a bare unit test has no delegate**, so `DateFormat('d MMM y', 'en_GB')` in a
  test that does not pump a `MaterialApp` will throw a locale-data error. Fix that **in the test** —
  pump the delegates, or call `initializeDateFormatting('en_GB')` in the test's `setUpAll` — and never
  in `lib/`, where it would add a second initialisation authority.
- **`DateFormat.yMd` and any pattern containing `/` or `.` is a gate row.** `copy.numeric_date`'s
  regex is `RegExp(r"DateFormat\.yMd\b|DateFormat\(\s*'[^']*[/.]")` under `lib/`. `d MMM y` and
  `HH:mm` contain neither character, which is why they are safe; `dd/MM/yyyy` and `d.M.y` are hits.
- **`MediaQuery.alwaysUse24HourFormatOf` is deliberately unread**, and it is the one place this app
  overrides a system preference. `10 §9.4` states all three reasons: the difference between 03:21 and
  15:21 is a data-integrity question in an app used at 3am and the AM/PM token is the part a tired
  reader drops; the medicine book handed to a vet must not carry two spellings of the same instant;
  and the receipt's uniqueness rule depends on a stable time string. Put that sentence in the file, or
  the next contributor will "fix" the omission.
- **`formatShedTime` takes an `Instant`, not a `RecordedTime`, and that is the safety design.** A time
  is never displayed without its provenance label — a bare `03:21` is a review failure
  (`CONVENTIONS §5.4`). `RecordedTime.provenanceLabel` is an exhaustive switch in `lib/domain/` that
  can never be empty, and it stays there. Giving this function a `RecordedTime` would let a call site
  format the instant and drop the label in one step, which is spec §12.5's failure mode wearing a
  helper's clothes. Indelible renders the pair as `03:20` over `AUTO`, or `07:02 †edited` over
  `event 03:20 as entered`.
- **Controllers never format for display** (`02 §4.4` rule 9). *"A controller that knows `en_GB` is a
  controller that cannot be unit-tested without a locale."* These functions are called from widgets,
  and the locale arrives through `context.localeName`.
- **`en_GB` must not be first in `supportedLocales`.** The correct order is
  `[Locale('en'), Locale('en','GB'), Locale('en','IE')]` — putting `en_GB` first means *every English
  speaker on earth gets British formats*. That list lives in `app.dart` (N11-T05) and is asserted by
  `test/features/locale_resolution_test.dart`, but the formatters are what makes the mistake visible,
  so name it in the PR body.
- **No `DateFormat` runs off the root isolate** (decision #125). `ExportRepository` builds the PDF's
  view model with every date and time **already formatted** on the root isolate and `compute()`
  receives strings — that removes the hazard rather than managing it. This is N21's code, but the rule
  is settled here and belongs in this file's doc comment.
- **The decimal separator is fixed to `.`** and never locale-derived: the keypad's decimal key always
  emits `.` (decision #57), `double.parse('4,3')` throws, and `NumberFormat.parse` for a comma locale
  throws on `'4.3'`. Ambiguity resolution is `parseUserNumber`'s in `lib/domain/units/` — it returns
  `null` rather than guessing — and `formatShedWeight` is only the rendering half.
- **Weight is never inferred from the locale.** Canonical storage is integer `Grams`; `WeightUnit`
  comes from `unitsProvider` (`Provider<WeightUnit>`, R68), and conversion happens at the widget
  boundary only. A UK smallholder may genuinely want lb, and a wrong inference silently mislabels
  every weight ever recorded.
- **`formatShedCount` exists so a four-digit count is grouped by the locale rather than by hand**, and
  so that every numeral in the app goes through one place. It renders into a tabular role
  (`indelible.md` §3.5), which is what stops `412` and `108` taking different widths down a column.
- **No temperature formatter ships.** Decision-record §7.1 #11 is open — spec §7.10 has a °C/°F
  setting and no v1 table stores a temperature — so R68 says no `temperatureUnitProvider` ships and no
  temperature formatter exists. *"An unused setting is a 3am tax."*

### 5.4 The full test set

`test/design/formatters_test.dart`. Pure functions, so most cases need no pump — but see the
locale-data note in §5.3.

| Case | What it asserts |
|---|---|
| `'a human date is never all-numeric and the clock is 24-hour'` | **The anchor.** Exact strings, plus the all-numeric regex over every formatter's output |
| `'formatShedDate renders 11 Mar 2026'` | `d MMM y`, spelled month, no leading zero on the day |
| `'formatShedDayMonth renders 14 Jul'` | The tight-chip form used by the pen tile and the withdrawal countdown |
| `'formatShedTime renders 03:21 and 15:21'` | Both halves of the day. `'3:21 AM'` is the failure |
| `'formatShedTime is unchanged when alwaysUse24HourFormat is false'` | Pump a `MediaQuery` with the flag off. The deliberate override, made executable |
| `'formatShedWeight round-trips canonical grams into kg and lb'` | 4100 g → `4.1 kg` and → the lb rendering, with the stored value unchanged. Never rewrite the entry |
| `'formatShedCount groups by locale'` | And returns a string a tabular role can align |
| `'the week starts on Monday for en_GB and en_IE'` | `MaterialLocalizations.firstDayOfWeekIndex == 1`. No calendar ships in v1; the assertion exists so the day one does, it is already right |
| `'package:intl is imported by exactly one file under lib/ outside lib/data/'` | Source text over `lib/**/*.dart` — layer rule 7, made executable here rather than waiting for the gate |
| `'every DateFormat in formatters.dart is passed an explicit locale'` | Source text: no `DateFormat(` call has a single argument |
| `'no DateFormat pattern contains a slash or a dot'` | The `copy.numeric_date` shape, asserted positively so the failure names the pattern |
| `'formatShedTime takes an Instant and not a RecordedTime'` | The signature that makes laundering provenance impossible |

**The `uk-zone` group — this is the epic's only time-shaped code.** Put it in a
`group('DST', …, tags: 'uk-zone')` that asserts the ambient zone **first and loudly**, exactly as
N04-T08's file does, so it can never pass for the wrong reason. The `test` job runs
`TZ=Europe/London --tags uk-zone` over the **whole** suite (`13 §4.2`), so a tagged group in
`test/design/` is picked up; an untagged DST case runs under the runner's own zone and proves nothing.

| Case | What it asserts |
|---|---|
| `'this group requires TZ=Europe/London'` | Fails loudly under a wrong `TZ` rather than silently asserting UTC |
| `'DST: two instants one hour apart in the ambiguous 01:00–01:59 hour both render 01:30'` | The clocks-back night. Two distinct `Instant`s, one local `HH:mm` — which is precisely why the provenance label is not optional and why the withdrawal clear date is computed in absolute time (decision #3), never in civil days |
| `'DST: formatShedDate renders one date for both of those instants'` | The date does not shift under the repeated hour |
| `'DST: the clocks-forward night has no local 01:30 and formatShedTime never invents one'` | The spring-forward gap. `checkLocalWallTimeExists()` in `lib/domain/time/wall_time.dart` is the domain half; this asserts the presentation half does not paper over it |
| `'DST: a time in the ambiguous hour still renders as HH:mm with no offset suffix'` | The app has no 12-hour path and no offset display; the disambiguation lives in the record, not in the string |

## 6. Constraints that bind this task

- **3am** — a misread date is the failure this file exists to prevent, and the withdrawal countdown is
  the worst place in the app to be ambiguous: `CLEARS 12 AUG 2026`, never `12/08/2026`. Indelible §7.6
  renders it in the record face at 20 px with the days figure at 32 px tabular.
- **Safety rule §12.5 — timestamps carry provenance.** This file formats an instant; it never produces
  or replaces `RecordedTime.provenanceLabel`, and its signature makes that structural.
- **Safety rule §12.1 — never default a withdrawal period.** No formatter here has a default value, a
  placeholder or a "same as last time" path. `formatShedCount(0)` renders `0`, and `0` is a real
  label value — *"no row implies `NotRecorded`"* is the schema's job, not a formatter's.
- **Offline** — no network path may be added. `flutter_localizations` bundles its CLDR date symbols as
  generated Dart and `intl` ships its data in the package: no asset download, no HTTP, no permission.
  G2 and G3 stay green.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'a human date is never all-numeric and the clock is 24-hour'` passes, and was seen to fail first for the stated reason
- [ ] `package:intl` is imported in exactly one file under `lib/`
- [ ] no human-facing date is all-numeric
- [ ] the clock is 24-hour and the week starts on Monday
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] all five `formatShed*` functions and `ShedLocaleX` exist under `10 §9.1`'s exact names and signatures
- [ ] every `DateFormat` is passed an explicit locale and no pattern contains `/` or `.`
- [ ] `initializeDateFormatting` appears nowhere under `lib/`
- [ ] `formatShedTime` takes an `Instant`, so no call site can format a time and drop its provenance label in one step
- [ ] **the `uk-zone` DST group exists, is tagged, fails loudly under a wrong `TZ`, and covers the 01:00–01:59 ambiguous hour in both directions**
- [ ] no temperature formatter ships (decision-record §7.1 #11 is open)

## 8. Verification

```bash
fvm flutter test test/design/formatters_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
TZ=Pacific/Chatham fvm flutter test test/design/formatters_test.dart --exclude-tags uk-zone
make check
make test
```

The Chatham leg is the point: it is a +12:45 zone, so a formatter that quietly resolved a locale or a
zone from the device instead of its argument fails there and nowhere else.

```bash
grep -rn "package:intl" lib/ --include='*.dart'
# expect exactly one hit outside lib/data/: lib/core/ui/formatters.dart

grep -rn "DateFormat.yMd\|initializeDateFormatting" lib/ --include='*.dart'   # expect zero
grep -rn "alwaysUse24HourFormat" lib/ --include='*.dart'                      # expect zero
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): formatters.dart, the one intl call site`

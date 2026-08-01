---
name: shed-domain
description: >-
  The pure-Dart domain — no Flutter, drift, Riverpod, intl or clock, and now is always a parameter.
  Use for any calculation, conversion, average, percentage, count, statistic or date arithmetic, and
  for a daylight-saving, DST, timezone, clocks-change or ambiguous-hour bug. Do NOT use for clear
  dates (shed-withdrawal).
---

# The pure-Dart domain

`lib/domain/**` computes. It never reads a clock, a database, a locale or a widget.

**Authority.** `docs/engineering/05-domain-correctness.md` owns this area. `docs/engineering/CONVENTIONS.md` §2.1 (ids), §2.2 (time), §2.3 (units), §2.6 (warnings and statistics), §2.9 (enums mirroring stored keys) owns every name, signature, file path and stored key. Both outrank this skill — open the section, do not re-derive it from memory.

**Do NOT use this skill for** withdrawal periods, clear dates, countdowns or "as entered by you" (`shed-withdrawal`), nor for column spellings, CHECK constraints, converters or stored codes (`shed-drift-schema`).

## 1. The import bans

`lib/domain/**` may not import (05 §1.2, enforced by `tool/check_policy.dart`):

- **`package:flutter/*`** — the domain runs under `dart test`, with no binding.
- **`package:drift/*`, `lib/data/**`, `lib/core/db/**`** — a domain function that knows a repository is one that can be made to write. Statistics take plain records, never rows.
- **`package:clock`** (R24) — pure functions take `Instant now` as a parameter, which makes "did you test the boundary?" a compile-time question. `01-architecture.md` layer rule 1 still lists `clock` as permitted; that is the weaker rule and it loses.
- **`package:intl`, `AppLocalizations`** — a domain that formats has a locale. Exactly two exceptions: `Disclaimers` and `RecordedTime.provenanceLabel`.
- **`package:riverpod` / `flutter_riverpod`, `package:sqlite3`, `package:uuid`** — nothing here is wired, opened or given an identity. `newUid()` lives in `lib/core/db/uid.dart` (R15).

One ban points the other way: **`lib/data/**` may not import `lib/domain/validation/**`.** The code that can write holds no reference to the code that judges.

`tool/check_policy.dart` is this project's single source-scanning gate (decisions #9/#10): one allowlist, one exit code. Add a row to it; never write a second scanning script.

## 2. `now` is always a parameter

- `appNow()` in `lib/core/time/app_clock.dart` is the only wall-clock reader in the app (R23). Repositories, controllers, seeds and sweeps call it; nothing calls `clock.now()`.
- `DateTime.now(` appears in that file and nowhere else (`check_policy` rule `time.dart_clock`, one allowlist entry, so the rule has one reviewable exception).
- **No second clock abstraction** — no `abstract class Clock`, no `SystemClock`, no `clockProvider`. Two seams are worse than none, because a test that fakes one does not fake the other.
- Elapsed-time helpers take both ends: `timeSincePenned(Instant enteredAt, Instant now)` in `lib/domain/penning.dart`. `sincePenned` is a banned name (R24).
- Tests install time at the edge with `withClock(...)`; most domain tests pass an `Instant` and never touch `clock` at all.

## 3. Time

**The rule that decides every field.** A moment that happened is an `Instant`; a square on a calendar is a `LocalDate`. The test is *if the device moved timezones, would this value still refer to the same thing?* Classify a new time-carrying field in 05 §2.2 **before** the column exists.

- Instants are `INTEGER` UTC epoch millis; civil dates are `TEXT 'YYYY-MM-DD'` (decision #29, **irreversible after the first migration snapshot**). Never a drift `dateTime()` column; never set `store_date_time_values_as_text`.
- `PartialDate` (`ewes.date_of_birth`) is a real state, not a defective date. Never widen it, never pad it to 1 January.
- **Elapsed time is absolute** — `Instant.difference` / `Duration`. **Calendar arithmetic is civil** — `LocalDate.plusDays` / `daysUntil`, which route through `DateTime.utc` so no DST can perturb them. `DateTime(y, m, d + n)` near a withdrawal, a reminder or an elapsed-time readout is a defect.
- SQL may compare, order, `BETWEEN`, `GROUP BY`, `MIN`/`MAX` over opaque instants and lexicographic dates. SQL may not add, subtract, truncate to a day or extract a component — SQLite has no timezone database. The five banned SQL time tokens are `check_policy` rules `time.sql_now_1`–`time.sql_now_5` (05 §2.6); bare `strftime`/`datetime` are deliberately not banned.
- `package:timezone` exists only in `lib/data/notification_scheduler.dart` (R48). It never enters the domain.

**The UK ambiguous hour is 01:00–01:59** (owner ruling, `00-README.md` §5.1). Clocks go forward at 01:00 GMT, so that hour does not exist; they go back at 02:00 BST, so it happens twice. Late March is lambing season — this is not a footnote.

- The **nonexistent** hour is warned about: `checkLocalWallTimeExists` in `lib/domain/time/wall_time.dart` returns `WarningCode.timeDoesNotExistLocally`.
- The **ambiguous** hour is deliberately never warned about — the displayed time still matches what the shepherd typed, nothing was silently corrected, and noise at 3am is a defect.
- Zone tests live in `test/domain/uk_zone/` tagged `uk-zone` and **fail, never skip**, when `TZ` is wrong. CI runs the domain suite in `Europe/London` and again in `Pacific/Chatham` with `--exclude-tags uk-zone`; zone-agnostic assertions must be relational ("exactly 168 h"), never absolute wall-clock values.

## 4. `RecordedTime` — provenance is part of the value

Three fields, three facts, none derivable from the others: `effective` (when it happened), `capturedAt` (when we found out, never moves, never editable), `originalEffective` (what we first thought, the **first** value ever held, preserved across an unbounded chain of edits). Shape and factories: CONVENTIONS §2.2.

- `TimeSource` keys are **frozen** — they are written to SQLite, CSV and the JSON backup. Export the key, never the localised label.
- `userEntered` and `userEdited` are different facts: a deferred entry typed at 7am for an 03:20 lambing was never wrong; an edited one was.
- The provenance quad travels together (R37). **A table without the quad has no edit verb** — three loose columns make the §12.5 label true but uninformative.
- Statistics, spread and exports read `effective`. Never `capturedAt`.

## 5. Units

- Canonical storage is **integer `Grams`** and **integer `MilliCelsius`** (decision #56). Chosen by measurement: 0.1 kg silently rewrites 132 of 241 pound entries, 0.1 °C rewrites 89 of 201 Fahrenheit entries. Both are safety-rule-4 violations produced by a storage decision.
- **No `unit` column on any measurement.** `WeightUnit` affects rendering and parsing only; a form is seeded from the canonical value and parses the *typed text* back to canonical, never re-deriving from the old canonical.
- Convert with `round()`. `toInt()` truncates toward zero and is systematically light; `ceil()`/`floor()` bias. Add a boundary test at `x.5`.
- `parseUserNumber` (`lib/domain/units/parse_number.dart`) returns `null` on ambiguity. Null becomes a `Warning`, never a value. Never guess a decimal separator.
- The plausible birth-weight band is one named constant, `kPlausibleBirthWeight` in `lib/domain/validation/lambing_checks.dart`, not a literal at the check site. It warns; it never blocks and never judges. It is provisional pending open question 12.

## 6. Warnings — observe, never repair

- `Warning` has no `fix()`, no `corrected`, no callback, and no reference to a writer. `Reviewed<T>` has no `cleaned` getter. The mutation surface does not exist, so no call-site carelessness can create one.
- **There is no `warnings` column.** Warnings are recomputed on read; a derived value that is never persisted can never diverge and can never be mistaken for user data on export.
- **Warnings never gate a save.** Every write commits immediately; a blocked save is a lost record.
- Validators are pure top-level functions, one per file, shaped `check<Thing>(...) -> List<Warning>`. No class, no `Validator` suffix. Repositories therefore cannot produce warnings; who runs the validators and how the result reaches `WriteCommitted.warnings` is **shed-riverpod-providers**' rule (R53) — read it there.
- The `normalize*` ban (decision #55) is on functions returning a *corrected domain value*. Projections such as `tag_digits` are fine because the typed value survives verbatim; never show a projection to a user.
- Validation of user text **rejects with a reason; it does not sanitise**. Trimming surrounding whitespace is the single accepted exception.

## 7. Statistics

Read `references/statistics.md` **when you add, change or debug a statistic** — it carries every denominator, edge case and not-computable reason.

- `StatResult.value == null` means **not computable**. Never 0 as a stand-in for unknown; never `NaN`; never a blank cell. `notComputableReason` replaces the value on screen and in the export.
- Every headline number renders its `definition` string and its `numerator / denominator` — always, not behind an info icon.
- **The `definition` strings live only in `lib/domain/stats/definitions.dart`** (R61). Read them from that file. Never retype, paraphrase or "improve" one anywhere — including in a screen brief, a test expectation or a comment — because the same string is printed into CSVs and PDFs that outlive the app.
- Two `StatResult`s may be compared only when their `definition` strings are identical; otherwise render "these seasons were measured differently" and no delta.
- `?? 0` is banned outright in `lib/features/season/**` and `lib/features/flock/**` (`check_policy` + the review checklist): it turns "we have not recorded that" into "you scored zero".
- The default `LambingPercentageChoice` is the **AHDB** convention (owner ruling, `00-README.md` §5.1) and stays user-configurable. Its wording is one of R61's four pinned strings: read it from `lib/domain/stats/definitions.dart` and never spell it out — here, in a screen, in a test or in a comment.

## 8. UK / Ireland, terminology and the presentation edge

`en_GB`, kg, °C, 24-hour clock, `dd/MM/yyyy`, week starts Monday (`00-README.md` §5.1). `dd/MM/yyyy` is the *numeric* convention and appears only inside CSV, always beside an ISO-8601 column: **no date shown to a human is ever all-numeric** (decision #108) — `d MMM y`, so `07/13` can never be read as 13 July. All of this formatting happens at the presentation edge; the domain holds values, not strings.

`AnimalClass` keys are stable and go into the database, the CSV and the JSON backup. `maidenFemale` is deliberately dialect-neutral so `gimmer`, `theave` and a translator's word are equal citizens over one key. Never bake a domain noun into an ICU message — pass it as a `String` placeholder (`singularTerm` / `pluralTerm`; `plural` and `singular` are ICU keywords and must not be placeholder names). Never derive a plural by appending "s". CSV headers and machine values use stable English keys; the PDF flock book uses the user's labels.

## 9. Ids and file placement

- Id extension types live in `lib/domain/ids.dart` (R5, CONVENTIONS §2.1). The representation getter is always `.value`; `id.id` and `id.raw` are banned spellings.
- **A bare `int` never crosses a repository, controller, route-helper or provider-family boundary** (R33). Ids cross; ints do not.
- `lib/domain/`'s internal structure is 05 §1.1's subfolders — `time/`, `units/`, `withdrawal/`, `stats/`, `validation/`, `terminology/`, `policy/` — not `01-architecture.md`'s flat list (R17). Put a new file in the subfolder that owns it; do not create a new top-level domain file without checking §1.1 first.

## 10. Gotchas

- **Extension types erase at runtime.** `Instant`, `Grams` and every `extension type X(int)` are the same runtime type, so `is` and `switch` cannot discriminate them. Build extension types only for *canonical* values — `Pounds` and `Fahrenheit` are banned type names.
- `extension type Instant(int) implements Comparable<Instant>` **does not compile** (`int` implements `Comparable<num>`). Hence an explicit `compareTo` and the `Instant.ascending` / `descending` comparators, and no free `.sort()`. Do not fight it.
- **Dart moves a nonexistent local time forward silently, with no exception** — `DateTime(2026, 3, 29, 1, 30)` returns `02:30`. That is Dart correcting the user on our behalf, which is why §7.5 detects it.
- **Widget tests already run an advancing fake clock.** Wrapping an elapsed-time test in `withClock(Clock.fixed(...))` freezes it, so every "hours since penned" readout stays at its seed value and the test silently measures nothing. Offset the seed data instead (decision #113). `package:fake_async` must never become a dependency.
- **`Stream.distinct()` is a no-op without value equality.** Domain records consumed by a repository stream need hand-written `==`/`hashCode`; a `List` needs `listEquals` on top, because a bare `.distinct()` compares list identity and filters nothing.
- `lambings.local_date` is denormalised and must be written by the same repository method, in the same transaction, that writes `effective`. Never recompute historical rows when the device zone changes — it records the shepherd's day as it was lived. A stale value surfaces as `WarningCode.localDateDisagrees`.
- `expectedLambCount` returns **null** for `quintPlus` (R46). "Quad or more" is open-ended, so a contradiction is *undefined*, not false — encoding it as 5 would false-warn on every set of sextuplets.
- `LambingEase` carries an ordinal only (R44). The five descriptions are `vocab_terms` rows with ARB defaults, resolved at the presentation edge — a domain file cannot hold ARB text.
- **There is no birth-type chooser anywhere in the product** (owner ruling P8). Birth type is derived from the tally strokes and labelled as derived; `Lambings.declaredBirthType` is nullable (R6). Never write domain code that assumes someone picked one.
- `lib/domain/season_stats.dart`, `lib/domain/consistency.dart` and `lib/domain/death_cause.dart` **do not exist** (R17). Importing any of them is a defect; the real files are under `stats/`, `validation/` and `vocab_terms` respectively.

## Definition of done

- [ ] No file under `lib/domain/` imports Flutter, drift, Riverpod, sqlite3, intl, `AppLocalizations`, `lib/data/**`, `lib/core/db/**` — or `package:clock` (R24).
- [ ] Every function needing the current time takes `Instant now`; `DateTime.now(` still appears only in `lib/core/time/app_clock.dart`.
- [ ] `dart tool/check_policy.dart` passes, with rows added to it rather than a second scanning script.
- [ ] Every new time-carrying field is classified `Instant` or `LocalDate` in 05 §2.2 before its column exists; no `dateTime()` column anywhere.
- [ ] Every measurement is `Grams` or `MilliCelsius`, converted with `round()`, with no `unit` column and a boundary test at `x.5`.
- [ ] Every statistic returns a `StatResult` whose `definition` came from `lib/domain/stats/definitions.dart`, with a real denominator or a `notComputableReason` — never 0 for unknown.
- [ ] No `fix()`, `corrected` or `cleaned` on `Warning`/`Reviewed`; no `warnings` column; no save blocked by a warning.
- [ ] `flutter test test/domain` passes under `TZ=Europe/London`, and under `TZ=Pacific/Chatham` with `--exclude-tags uk-zone`.
- [ ] `flutter analyze` is clean and `dart format` has been applied.

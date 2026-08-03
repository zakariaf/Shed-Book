# 05 — Domain correctness

This document governs everything in `lib/domain/**` plus the one file in `lib/core/time/` that reads the wall clock: the time model, the withdrawal-period calculation, timestamp provenance, canonical units, the season statistics, the editable terminology map, and spec §12's five safety rules expressed as types and gates rather than as review habits. It is the part of the app that has nothing to do with Flutter and everything to do with not being wrong about a sheep. Read it before you write a line of `lib/domain/`, and read it again before you change one — most of the code here is arithmetic that is invisible when it is wrong.

> **Decisions applied:** #29 (instants `INTEGER`, civil dates `TEXT`), #30 (the cost of #29, stated), #31 (no `DEFAULT` on any column that could encode veterinary advice), #46 (one clock, `package:clock`), #47 (SQL-side time banned), #48 (timezone strategy: `package:timezone` confined to the notification seam), #49 (withdrawal clear date = ceil-to-next-local-midnight of administration + N × 24 h), #50 (`clear_date` is stored, exactly once), #51 (`sealed class WithdrawalPeriod`), #52 (two gates prove "never default a withdrawal"), #53 (`RecordedTime`), #54 (contradictions are `List<Warning>`), #55 (`normalize*` ban scope), #56 (canonical grams and milli-°C), #57 (numeric input), #58 (`StatResult`), #59 (statistic definitions), #60 (`customSelect` + `readsFrom:` for aggregates), #61 (terminology), #62 (`Disclaimers`), #69 (a treatment is soft-voided, never deleted), #108 (gen-l10n options: `use-named-parameters`, `nullable-getter: false`, never an all-numeric human-facing date), #113 (time in widget tests), #118 (property tests for pure value round-trips), #121 (the two-timezone CI run), plus the owner's rulings in decision-record §7.0: UK/Ireland first (`en_GB`, kg, °C, 24-hour, `dd/MM/yyyy`, week starts Monday), ambiguous DST hour **01:00–01:59**, AHDB lambing-percentage convention as the default, tags unique among **active** animals only.
>
> **Three of the four questions this document used to carry were ruled on 2026-08-01** (decision-record §7.0 rows 10, 11 and 15), in N00-T04, five epics before the schema freeze: the dairy target **ships** in the schema (§3.2), **no v1 table stores a temperature** and `app_settings.temperature_unit` is dropped with it (§5.2), and **lambing ease stays 1..5** with point 5 covering elective caesarean (§6.7). `MilliCelsius` still ships regardless. One remains open and is flagged where it bites: **question 12**, lamb-scale resolution and the plausibility band (§5.4), which is product-shaped rather than schema-shaped — grams stay canonical either way, and only the *input step* is unsettled.

[`CONVENTIONS.md`](CONVENTIONS.md) is the naming authority for the whole set and outranks this document on any name, path, type shape, signature or word; the `R<n>` citations below are its ruling numbers.

Siblings you will need: [`01-architecture.md`](01-architecture.md) owns the layer rules and `tool/check_policy.dart`; [`03-data-model-and-schema.md`](03-data-model-and-schema.md) owns the table definitions this document constrains; [`09-export-formats.md`](09-export-formats.md) owns the writers that must carry provenance and definitions; [`12-testing.md`](12-testing.md) owns the harness the tests below run in.

---

## 1. Where the domain lives, and what it may not touch

### 1.1 The file map

```
lib/domain/
  (root)        ids.dart  birth_type.dart  lambing_ease.dart  sex.dart
                foster_outcome.dart  penning.dart  tag_match.dart
                free_tier.dart  reminder_budget.dart
  time/         instant.dart  local_date.dart  partial_date.dart
                recorded_time.dart  wall_time.dart   <- checkLocalWallTimeExists (§7.5)
  units/        grams.dart  milli_celsius.dart  weight_unit.dart  parse_number.dart
  withdrawal/   withdrawal_period.dart  withdrawal_status.dart  clear_date.dart
  stats/        definitions.dart  season_counts.dart  lambing_percentage.dart
                litter_size.dart  barren_rate.dart  assisted_rate.dart
                losses.dart  lambing_spread.dart
  validation/   warning.dart  lambing_checks.dart  foster_checks.dart
                treatment_checks.dart
  terminology/  animal_class.dart  term_label.dart  terminology.dart
  policy/       disclaimers.dart  export_envelope.dart  content_policy.dart

lib/core/time/app_clock.dart      <- the ONLY file allowed to read wall-clock time
lib/core/db/converters.dart       <- the drift TypeConverters (R1). 03 declares them.
```

That tree is [`CONVENTIONS.md`](CONVENTIONS.md) §1's, verbatim. The root files are shared with other documents. This document owns the *types* in `ids.dart` while [`03-data-model-and-schema.md`](03-data-model-and-schema.md) owns which ids exist (R5); it owns `expectedLambCount` in `birth_type.dart` while 03 owns the stored codes 1..5 (R46); it owns `tag_match.dart` (`TagIndexEntry` + `rankTagMatches`, R27) and `penning.dart` (`timeSincePenned`, R24). `lambing_ease.dart`, `sex.dart` and `foster_outcome.dart` carry stored keys 03 owns; `free_tier.dart` is [`01-architecture.md`](01-architecture.md)'s file with 11's members; `reminder_budget.dart` is adopted by [`08-platform-integration.md`](08-platform-integration.md). All of them obey the import bans below like everything else under `lib/domain/`.

**Names other documents must use.** These types are defined here and spelled here. Where a sibling document currently spells them differently, this document wins and the sibling is wrong:

| Canonical | Wrong spellings currently in the set |
|---|---|
| `appNow()` in `lib/core/time/app_clock.dart` | `Instant.now()` — [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md) claims it is "defined once, in `lib/core/time/`". It is not defined at all. |

`Instant.fromDateTime(DateTime)` and `RecordedTime.capture(Instant)` are canonical too, but this table used to list conflicts against them that were phantom: neither `Instant.fromUtc(` nor `RecordedTime.captured(` appears anywhere in the set, and 01 already writes both canonical spellings. The rows are struck rather than "resolved" (R39) — a doc set that records fictional conflicts trains readers to stop trusting the conflict list.

### 1.2 Four import bans, enforced by `tool/check_policy.dart`

| # | `lib/domain/**` may not import | Why |
|---|---|---|
| D1 | `package:flutter/*` | The domain is plain Dart. It is tested with `dart test` speed and no binding. |
| D2 | `package:drift/*`, `lib/data/**`, `lib/core/db/**` | Statistics take plain records, not rows. A domain function that knows about a repository is a domain function that can be made to write. |
| D3 | **`package:clock`** | Pure functions take `Instant now` as a *parameter*. `clock.now()` is called at the edge only. This makes "did you test the boundary?" a compile-time question. |
| D4 | `package:intl`, `AppLocalizations` | Formatting is a presentation concern; a domain that formats is a domain that has a locale. The two exceptions are `Disclaimers` and `RecordedTime.provenanceLabel` (§4.2, §7.4). |

> **D3 amends [`01-architecture.md`](01-architecture.md).** That document's layer rule 1 currently lists `clock` among the packages `lib/domain/` *may* import, and its `_bannedPackages` map has no `lib/domain/` entry for it. That is the weaker rule and it loses. The required edit there is one string: add `'package:clock/'` to `_bannedPackages['lib/domain/']` and strike `clock` from rule 1's "may import" column. Nothing else changes — `lib/core/`, `lib/data/` and `lib/features/` still import `clock` freely, and `lib/core/time/app_clock.dart` is where it is read.

And one ban pointing the other way: **`lib/data/**` may not import `lib/domain/validation/**`.** The code that can write has no reference to the code that judges. That is the strongest available form of "a warning cannot mutate anything" (§7.5).

### 1.3 The one clock

```dart
// lib/core/time/app_clock.dart — the single allowlisted reader of wall-clock time.
import 'package:clock/clock.dart';           // clock 1.1.2 (decision-record §5.1)
import '../../domain/time/instant.dart';

/// Every timestamp in the app originates here. Repositories and controllers
/// call this; pure domain functions take the result as a parameter.
Instant appNow() => Instant(clock.now().millisecondsSinceEpoch);
```

`clock.now()` returns a local `DateTime`; `millisecondsSinceEpoch` is zone-independent, so `appNow()` is a true instant regardless of the device zone. Tests override it with `withClock(...)` from the same package — see §2.8.

**Anti-pattern.** A second clock abstraction. There is no `abstract class Clock`, no `SystemClock`, no `clockProvider`. Two clock seams are worse than none, because a test that fakes one does not fake the other (decision #46).

---

## 2. The time model

### 2.1 The rule that decides every field

> **If it is a moment that happened, it is an `Instant`. If it is a square on a calendar, it is a `LocalDate`. A civil date is never a `DateTime`, and an instant is never a date string.**

The test is not "does it have a time component". It is: *if the device moved to another timezone, would this value refer to the same thing?* A lambing at 03:20 GMT happened at one absolute moment and stays that moment; "the season starts on 1 March" is 1 March wherever you stand.

This is decision #29 and it is **irreversible after the first migration snapshot**. `store_date_time_values_as_text` is never set in `build.yaml`, and drift's `dateTime()` column type does not appear anywhere in the app — its integer mode stores *seconds* and, per drift's own docs, "drift always returns a non-UTC value", and its text mode mixes instant and civil semantics in one column.

### 2.2 The classification, field by field

This table is authoritative for the *kind*. Column spelling is [`03-data-model-and-schema.md`](03-data-model-and-schema.md)'s and is reproduced here exactly — in particular the column that holds `RecordedTime.effective` is named **`occurred_at`**, with exactly three documented exceptions: `treatments.administered_at`, `pen_occupancies.entered_at` and `foster_events.effective_at` (R37). If you add a field carrying time, add a row here first.

| Field | Kind | Column | Why |
|---|---|---|---|
| `Lambing.occurred_at`, `captured_at`, `original_effective` | instant | `INTEGER` epoch ms | A birth happened at a moment; ordering and elapsed-time reminders depend on it. |
| `Lambing.local_date` | civil date (denormalised) | `TEXT 'YYYY-MM-DD'` | The grouping key for the lambing spread. Written from `occurred_at` at insert (§6.9). |
| `PenOccupancy.entered_at`, `exited_at` | instant | `INTEGER` epoch ms | "Hours since penned" is elapsed physical time. |
| `Treatment.administered_at` | instant | `INTEGER` epoch ms | The withdrawal clock starts at the last administration (VICH). A date alone throws away up to 24 h of margin. |
| `TreatmentWithdrawal.clear_date` | civil date, **stored** | `TEXT 'YYYY-MM-DD'` | Decision #50. It is a record of what the app told the user and what got printed in the medicine book. |
| `Lamb.death_date` | civil date | `TEXT 'YYYY-MM-DD'` | The shepherd knows the day, rarely the minute. Forcing a time invents precision. |
| `Season.start_date`, `end_date` | civil date | `TEXT 'YYYY-MM-DD'` | Calendar facts. |
| `Reminder.due_at` | instant | `INTEGER` epoch ms | Fired at an absolute moment; projected into the OS by the reconcile pass ([`08-platform-integration.md`](08-platform-integration.md)). |
| `Ewe.date_of_birth` | **partial** civil date | `TEXT 'YYYY'` / `'YYYY-MM'` / `'YYYY-MM-DD'` | Almost never known to the day. A partial date is a real state — never pad it to 1 January. |
| `EweTouch.touched_at`, all `created_at` / `updated_at` | instant | `INTEGER` epoch ms | Audit anchors (the `Identified` mixin). |
| `AppSetting.last_exported_at`, `last_export_prompted_at` | instant | `INTEGER` epoch ms | Decision #72. |
| `Treatment.voided_at` | instant | `INTEGER` epoch ms | Decision #69 soft void. See §3.10. |
| `PenOccupancy.captured_at`, `original_effective` | instant | `INTEGER` epoch ms | R37: the §12.5 provenance quad lands on `PenOccupancies` too, because the pen tile renders an entry time. The event time is `entered_at`. |
| `FosterEvent.effective_at`, `captured_at`, `original_effective` | instant | `INTEGER` epoch ms | R37. `effective_at` is one of the three documented event-time names. |
| `EweObservation.occurred_at`, `captured_at`, `original_effective` | instant | `INTEGER` epoch ms | R37. |
| `Note.occurred_at`, `captured_at`, `original_effective` | instant | `INTEGER` epoch ms | R37. `notes.occurred_at` is new and is distinct from the `Identified` mixin's `created_at`. |

`Ewe.date_of_birth` is the one field that is neither a clean `Instant` nor a clean `LocalDate`. Model it as `PartialDate` in `lib/domain/time/partial_date.dart` — a `TEXT` column guarded by the three-way GLOB check [`03-data-model-and-schema.md`](03-data-model-and-schema.md) already ships (`'[0-9][0-9][0-9][0-9]'` / `+'-[0-9][0-9]'` / `+'-[0-9][0-9]'`), and a domain type that exposes `int get year`, `int? get month` and `LocalDate? get exactDate`. Never widen it to a full date on read. A length check alone is not enough: `'20x6'` has length 4.

### 2.3 `Instant`

```dart
// lib/domain/time/instant.dart
/// A moment in absolute time, as UTC milliseconds since the epoch.
/// Non-transparent extension type: a bare `int` cannot be passed where an
/// Instant is expected, and it costs no allocation on a 400-row flock list.
extension type const Instant(int epochMillis) {
  factory Instant.fromDateTime(DateTime d) => Instant(d.millisecondsSinceEpoch);

  DateTime get utc   => DateTime.fromMillisecondsSinceEpoch(epochMillis, isUtc: true);
  DateTime get local => DateTime.fromMillisecondsSinceEpoch(epochMillis);

  Instant  plus(Duration d)      => Instant(epochMillis + d.inMilliseconds);
  Duration difference(Instant o) => Duration(milliseconds: epochMillis - o.epochMillis);
  bool     isBefore(Instant o)   => epochMillis < o.epochMillis;
  bool     isAfter(Instant o)    => epochMillis > o.epochMillis;
  int      compareTo(Instant o)  => epochMillis.compareTo(o.epochMillis);

  static int Function(Instant, Instant) get ascending  => (a, b) => a.compareTo(b);
  static int Function(Instant, Instant) get descending => (a, b) => b.compareTo(a);
}
```

`compareTo` is a plain method and the comparators are explicit because **an extension type can only `implements` a supertype of its representation type**: `extension type Instant(int) implements Comparable<Instant>` fails with `extension_type_implements_not_supertype`, since `int` implements `Comparable<num>`. Do not fight this; you get no free `.sort()` and that is fine.

Extension types **erase at runtime**. `Instant` and any other `extension type X(int)` are the same runtime type, so `is`/`switch` on runtime type will not discriminate them. Consequence, applied throughout this document: build extension types only for *canonical* values, never for display values.

### 2.4 `LocalDate`

```dart
// lib/domain/time/local_date.dart
/// A square on a calendar, stored exactly as it is stored in SQLite:
/// a strict ISO 'YYYY-MM-DD' string that sorts lexicographically.
extension type const LocalDate._(String iso) {
  static final RegExp _shape = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  factory LocalDate(int year, int month, int day) {
    final d = DateTime.utc(year, month, day);           // UTC: no DST to perturb it
    if (d.year != year || d.month != month || d.day != day) {
      throw ArgumentError('Not a real date: $year-$month-$day');
    }
    return LocalDate._(_format(d));
  }

  /// Strict. Throws rather than coercing — a malformed date must not become
  /// a plausible one (safety rule 4).
  factory LocalDate.parse(String s) {
    if (!_shape.hasMatch(s)) throw FormatException('Not YYYY-MM-DD', s);
    final d = DateTime.utc(
        int.parse(s.substring(0, 4)), int.parse(s.substring(5, 7)), int.parse(s.substring(8, 10)));
    if (_format(d) != s) throw FormatException('Not a real date', s);
    return LocalDate._(s);
  }

  /// The civil date on which [i] fell, in the device's CURRENT local zone.
  factory LocalDate.of(Instant i) {
    final d = i.local;
    return LocalDate(d.year, d.month, d.day);
  }

  int get year  => int.parse(iso.substring(0, 4));
  int get month => int.parse(iso.substring(5, 7));
  int get day   => int.parse(iso.substring(8, 10));

  /// Calendar arithmetic, done in UTC so no DST can perturb it.
  LocalDate plusDays(int n) {
    final d = DateTime.utc(year, month, day).add(Duration(days: n));
    return LocalDate(d.year, d.month, d.day);
  }

  int daysUntil(LocalDate o) => DateTime.utc(o.year, o.month, o.day)
      .difference(DateTime.utc(year, month, day)).inDays;

  /// The first instant of this civil date in the device's local zone.
  /// In the rare zone where local midnight does not exist, `DateTime(y,m,d)`
  /// returns the first instant that does — which is what we want.
  Instant startOfDayLocal() => Instant.fromDateTime(DateTime(year, month, day));

  int compareTo(LocalDate o) => iso.compareTo(o.iso);   // ISO sorts lexically

  static String _format(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
```

Three properties you get for free by making the representation the ISO string: equality and `hashCode` are `String`'s (so a `LocalDate` is a safe `Map` key), the drift converter is the identity, and `ORDER BY local_date` in SQL is correct and index-friendly with zero conversion.

`plusDays` and `daysUntil` route through `DateTime.utc` deliberately. UTC has no DST, so `Duration(days: n)` there is exactly *n* calendar days. Doing the same on a *local* `DateTime` is the bug in §2.9.

> **Verify at first commit.** The private-representation-constructor spelling `extension type const LocalDate._(String iso)` is the mechanism that forces construction through the validating factories. It is not one of the snippets the research corpus compiled. Run `dart analyze` on this file in commit #1. If your exact SDK rejects it, fall back to a public representation constructor and keep both factories exactly as they are — do not weaken `LocalDate.parse`.

### 2.5 The drift converters

```dart
// lib/core/db/converters.dart  (R1, R21: one file, not a folder)
import 'package:drift/drift.dart';
import '../../domain/time/instant.dart';
import '../../domain/time/local_date.dart';

class InstantConverter extends TypeConverter<Instant, int> {
  const InstantConverter();
  @override Instant fromSql(int fromDb) => Instant(fromDb);
  @override int toSql(Instant value) => value.epochMillis;
}

class LocalDateConverter extends TypeConverter<LocalDate, String> {
  const LocalDateConverter();
  @override LocalDate fromSql(String fromDb) => LocalDate.parse(fromDb);
  @override String toSql(LocalDate value) => value.iso;
}
```

```dart
// in a table definition (canonical versions live in 03-data-model-and-schema.md)
late final occurredAt = integer().map(const InstantConverter())();
late final localDate  = text().map(const LocalDateConverter())();
late final deathDate  = text().map(const LocalDateConverter()).nullable()();
```

Note the direction of the safety: `LocalDateConverter.fromSql` calls the strict parser, so a row that somehow holds `'2026-2-3'` throws on read instead of quietly becoming a different day.

The file holds a third converter, `PartialDateConverter` for `ewes.date_of_birth` (§2.2), built the same way over the strict `PartialDate.parse`. All three declarations belong to [`03-data-model-and-schema.md`](03-data-model-and-schema.md); what this document fixes is the *shape* — `const` `TypeConverter`s, strict parsing on the way in.

### 2.6 What SQL is allowed to do with time

**Banned tokens, everywhere in `lib/**` including `.drift` files:** `CURRENT_TIMESTAMP`, `CURRENT_DATE`, `CURRENT_TIME`, `date('now')`, `datetime('now')`.

The bare tokens `strftime` and `datetime` are **not** banned (decision #47) — they false-positive on legitimate string handling and a rule that gets weakened is a rule that gets deleted.

SQL may: compare, order, `BETWEEN`, `GROUP BY`, `MIN`/`MAX` over opaque `INTEGER` instants and lexicographically sortable `TEXT` dates. SQL may not: add, subtract, truncate to a day, or extract a component from a time value. All time arithmetic happens in Dart, because Dart has the device's zone rules and SQLite does not.

```sql
-- fine: ordering and range, both index-friendly
SELECT * FROM lambings WHERE season = ?1 ORDER BY occurred_at DESC;
SELECT * FROM lambings WHERE local_date BETWEEN ?1 AND ?2;

-- banned: SQLite computing a civil day from an instant, with no timezone database
SELECT date(occurred_at / 1000, 'unixepoch', 'localtime') AS d FROM lambings;
```

The second statement is exactly why `local_date` is denormalised (§6.9). It costs 10 bytes per lambing and removes a whole class of once-per-night off-by-one-day bug.

### 2.7 Timezone strategy

`package:timezone` (0.11.1) exists in this app for one reason: `flutter_local_notifications.zonedSchedule` takes a `tz.TZDateTime`. It is confined to that seam (decision #48):

```dart
// The ONLY place tz appears: a private method on NotificationScheduler, in
// lib/data/notification_scheduler.dart (R48). There is no
// lib/features/reminders/notification_gateway.dart — plugin-adjacent code in a
// feature folder is untestable through the container and unswappable by a fake.
tz.TZDateTime _scheduleTimeFor(Instant when) =>
    tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, when.epochMillis);
```

Everything else uses `Instant` and its `.local` getter, which reads the **OS** zone rules. That is deliberate and contrarian: this app is bought once and may not be updated for three seasons, and a bundled IANA snapshot frozen at build time ages badly while the phone's own rules do not. Decision-record §4 records "bundled IANA snapshot goes stale" as an accepted consequence, bounded by that confinement.

### 2.8 The `DateTime.now()` ban and the CI grep

`DateTime.now(` appears in exactly one file: `lib/core/time/app_clock.dart` — and today it appears there zero times, because `clock.now()` does the reading. The allowlist entry exists so the rule has exactly one reviewable exception point.

`tool/check_policy.dart` already carries the first two rules; do not add duplicates under new ids. [`01-architecture.md`](01-architecture.md) owns the runner and the row type — its `_bannedText` rows are **literal strings**, not regexes, and its `_bannedPackages` map is keyed by path prefix. The rows that enforce this section, spelled the way that file spells them:

| id | where it lives | literal / package | scanned under | exempt | why |
|---|---|---|---|---|---|
| `time.dart_clock` | `_bannedText` (exists) | `DateTime.now(` | `lib/` | `lib/core/time/app_clock.dart` | One clock seam: `appNow()` at the edge, an `Instant` parameter in the core. |
| `time.sql_now_1` … `time.sql_now_5` | `_bannedText` (exists) | `date('now')`, `datetime('now')`, `CURRENT_TIMESTAMP`, `CURRENT_DATE`, `CURRENT_TIME` | `lib/` | — | SQLite has no timezone database. |
| — | `_bannedPackages['lib/domain/']` (**add**) | `package:clock/` | `lib/domain/` | — | Pure functions take `Instant now`. This is the one row this document adds; see the D3 note in §1.2. |

Two scan-scope requirements this document imposes on that runner, because the rules above are worthless without them: generated files (`*.g.dart`) are skipped, and the SQL-time literals are matched **case-insensitively and in `.drift` files as well as `.dart`** — a `.drift` file is where `CURRENT_TIMESTAMP` is most likely to be written.

The two text scans as a shell check, for use before you push:

```bash
# 1. DateTime.now() outside the one allowlisted file
grep -rn --include='*.dart' --exclude='*.g.dart' 'DateTime\.now(' lib/ \
  | grep -v '^lib/core/time/app_clock\.dart:' \
  && { echo 'POLICY FAIL: DateTime.now() outside lib/core/time/app_clock.dart'; exit 1; }

# 2. SQL-side time functions
grep -rniE --include='*.dart' --include='*.drift' --exclude='*.g.dart' \
  "current_timestamp|current_date|current_time|date\('now'\)|datetime\('now'\)" lib/ \
  && { echo 'POLICY FAIL: SQL-side time function'; exit 1; }

exit 0
```

**Testing time.** In pure unit tests, pass `Instant now` explicitly — most domain tests never touch `clock` at all. Where an edge is under test, wrap it:

```dart
withClock(Clock.fixed(DateTime.utc(2026, 3, 4, 3, 20)), () {
  expect(appNow(), Instant(DateTime.utc(2026, 3, 4, 3, 20).millisecondsSinceEpoch));
});
```

In **widget** tests, `AutomatedTestWidgetsFlutterBinding` already installs an *advancing* fake clock, so `tester.pump(const Duration(hours: 25))` really does move `clock.now()`. `Clock.fixed` freezes it, so wrapping a pen-board test in `withClock(Clock.fixed(...))` makes every "hours since penned" readout stay at its initial value forever and the test silently measures 0 h. For elapsed-time widget tests, **offset the seed data instead of pinning `now`** (decision #113). `package:fake_async` is not a declared dependency of this project and must not become one — it arrives inside `flutter_test`, which is all we need.

### 2.9 DST: the measured facts, and the tests that must exist

The owner has settled the region: **UK / Ireland**, so the ambiguous and the nonexistent hour are both **01:00–01:59**. UK clocks go forward at 01:00 GMT (01:00–01:59 never happens) and back at 02:00 BST (01:00–01:59 happens twice). In 2026 those dates are **29 March** and **25 October**. Late March is precisely when UK/Ireland lambing happens, which is why this is not a footnote.

What Dart actually does, measured under `TZ=Europe/London`:

| Probe | Result |
|---|---|
| `20:00 26 Mar + Duration(days: 7)` | `2026-04-02 21:00` — 168 h elapsed |
| civil `+7` keeping 20:00 | `2026-04-02 20:00` — **167 h elapsed, one hour short** |
| autumn: civil `+7` from 22 Oct 20:00 | 169 h elapsed |
| penned Sat 22:00, checked Sun 08:00 across spring-forward | `difference` = **9 h**, wall clock says 10 |
| `DateTime(2026, 3, 29, 1, 30)` | `2026-03-29 02:30` — **silently moved, no exception** |
| `DateTime(2026, 10, 25, 1, 30)` | `01:30` — one of the two possible instants |

Three facts follow. `Duration` arithmetic on `DateTime` is *absolute*-time arithmetic — the right tool for elapsed time, the wrong tool for calendars. `DateTime.difference` is absolute, and `Instant.difference` gives the identical answer. And a nonexistent local time is silently corrected, which is Dart violating safety rule 4 on our behalf, so we detect it (§7.5).

**These tests are mandatory and ship-blocking.** They live in `test/domain/uk_zone/` and carry `@Tags(['uk-zone'])`.

```dart
@Tags(['uk-zone'])
library;

import 'package:flutter_test/flutter_test.dart';
// ... domain imports

void main() {
  setUpAll(() {
    // A skipped safety test is a broken safety test. Fail loudly instead.
    expect(DateTime(2026, 7, 1).timeZoneOffset, const Duration(hours: 1),
        reason: 'Run this file with TZ=Europe/London');
  });

  test('DST-1: hours since penned is ABSOLUTE across the spring-forward', () {
    final penned = Instant.fromDateTime(DateTime(2026, 3, 28, 22, 0)); // Sat 22:00 GMT
    final now    = Instant.fromDateTime(DateTime(2026, 3, 29, 8, 0));  // Sun 08:00 BST
    expect(now.difference(penned), const Duration(hours: 9));
    // The wall clock advanced 10 h. Nine is correct: it is a welfare question
    // about physical hours in a 4x4 pen, and it errs toward turning out later.
  });

  test('DST-2: a lambing recorded in the ambiguous hour round-trips its wall time', () {
    // 01:30 on 25 Oct 2026 happens twice. Dart picks one instant.
    final typed = DateTime(2026, 10, 25, 1, 30);
    final i = Instant.fromDateTime(typed);

    expect(i.local.hour, 1);
    expect(i.local.minute, 30);
    expect(LocalDate.of(i), LocalDate(2026, 10, 25));

    // Exactly one of the two candidate instants, and the export says which.
    final bstCandidate = DateTime.utc(2026, 10, 25, 0, 30).millisecondsSinceEpoch;
    final gmtCandidate = DateTime.utc(2026, 10, 25, 1, 30).millisecondsSinceEpoch;
    expect(i.epochMillis, anyOf(bstCandidate, gmtCandidate));

    // No warning: the displayed time still matches what the user typed, so
    // nothing was silently corrected from the shepherd's point of view.
    expect(checkLocalWallTimeExists(2026, 10, 25, 1, 30), isEmpty);
  });

  test('DST-3: the nonexistent hour IS warned about', () {
    final w = checkLocalWallTimeExists(2026, 3, 29, 1, 30);
    expect(w.single.code, WarningCode.timeDoesNotExistLocally);
    expect(w.single.message, contains('01:30'));
    expect(w.single.message, contains('02:30'));
  });

  test('DST-4: civil-day arithmetic under-counts a 7-day withdrawal by one hour', () {
    final treated = DateTime(2026, 3, 26, 20, 0);
    final civil   = DateTime(treated.year, treated.month, treated.day + 7, 20, 0);
    expect(civil.difference(treated).inHours, 167);                    // the bug
    expect(treated.add(const Duration(days: 7)).difference(treated).inHours, 168); // the rule
  });

  test('DST-5: the clear date is computed in absolute time', () {
    final treated = Instant.fromDateTime(DateTime(2026, 3, 26, 20, 0));
    final status = computeWithdrawalStatus(
      administeredAt: treated,
      period: WithdrawalDays.asEnteredByUser(days: 7, target: WithdrawalTarget.meat),
    ) as ClearsOn;
    expect(status.elapsesAt.local, DateTime(2026, 4, 2, 21, 0)); // 21:00, not 20:00
    expect(status.date, LocalDate(2026, 4, 3));
  });
}
```

**Running them.** CI runs the domain suite twice (decision #121): once in the target zone, once in a hostile one.

```bash
TZ=Europe/London  flutter test test/domain
TZ=Pacific/Chatham flutter test test/domain --exclude-tags uk-zone
```

`Pacific/Chatham` is UTC+12:45 with its own DST; it is the zone that catches any code that assumes whole-hour offsets or a same-day UTC/local mapping. Assertions in the zone-agnostic files must be *relational* ("this elapsed duration is exactly 168 h", "this bar list is dense") rather than absolute wall-clock values.

**Anti-patterns.**
- `DateTime(y, m, d + n)` anywhere near a withdrawal, a reminder, or an elapsed-time readout. Calendar arithmetic is narrowed to season boundaries and display-only date offsets (decision #49).
- Skipping a DST test when the zone is wrong. Fail instead — see `setUpAll` above.
- Warning the user about the *ambiguous* hour. It is one hour a year with zero visible effect, and noise at 3am is a defect.

---

## 3. The withdrawal period — the highest-stakes code in the app

> Spec §7.5: *"The withdrawal period is always entered by the user from the bottle label. The app ships no default values and makes no suggestion."*
> Spec §12.1: *"Never default a medicine withdrawal period… the app stores what they typed and shows its source as 'as entered by you.'"*

A wrong number here puts meat or milk in the food chain. Everything below is arranged so that the wrong value is impossible to construct, impossible to persist, and impossible to display.

### 3.1 Why `int? withdrawalDays` is not merely weak — it is lossy

1. `withdrawalDays ?? 0` is one keystroke away in a null-safety cleanup and *reads as tidy code*.
2. **`0` is a real label value.** Products genuinely print zero-day withdrawals. A nullable int cannot tell "the label says zero" from "I did not look", so code that treats null as zero is indistinguishable from correct code.
3. "Not applicable" (the label states no withdrawal for this species or route) is a third distinct fact and it collapses too.

No amount of care at call sites recovers information the type discarded.

### 3.2 The type

```dart
// lib/domain/withdrawal/withdrawal_period.dart

/// What the withdrawal applies to. One bottle routinely prints two different
/// numbers; one field per treatment is a modelling bug that becomes a food
/// safety bug on a dairy flock.
enum WithdrawalTarget {
  meat('meat'),
  milk('milk');

  const WithdrawalTarget(this.key);
  /// Stable storage/export key. Never the localised label.
  final String key;

  static WithdrawalTarget fromKey(String k) =>
      WithdrawalTarget.values.firstWhere((t) => t.key == k,
          orElse: () => throw FormatException('Unknown withdrawal target', k));
}

/// A withdrawal period is a THREE-STATE value.
sealed class WithdrawalPeriod {
  const WithdrawalPeriod();
}

/// The user read a number off the bottle. [days] MAY be 0 — that is a real
/// label value, not a fallback.
final class WithdrawalDays extends WithdrawalPeriod {
  final int days;
  final WithdrawalTarget target;

  /// Private. No default. No optional parameter. No `int days = 0`.
  const WithdrawalDays._(this.days, this.target);

  /// The ONLY way to build one. Throws rather than coercing.
  factory WithdrawalDays.asEnteredByUser({
    required int days,
    required WithdrawalTarget target,
  }) {
    if (days < 0) throw ArgumentError.value(days, 'days', 'must be >= 0');
    if (days > 1000) throw ArgumentError.value(days, 'days', 'implausible');
    return WithdrawalDays._(days, target);
  }
}

/// The label explicitly states no withdrawal applies. Distinct from zero days
/// and distinct from "I did not look".
final class WithdrawalNotApplicable extends WithdrawalPeriod {
  final WithdrawalTarget target;
  const WithdrawalNotApplicable(this.target);
}

/// The user deliberately skipped it. The app must never invent one, and must
/// never show a countdown or a clear date for this state.
final class WithdrawalNotRecorded extends WithdrawalPeriod {
  const WithdrawalNotRecorded();
}
```

Decision #51 spells the middle state without arguments. It carries `target` here because the persisted marker row is per target — the same decision's "0..n entries per treatment" requires it.

Four mechanisms are stacked, strongest first:

| Mechanism | Level | What it stops |
|---|---|---|
| `sealed` + exhaustive `switch` | unrepresentable | forgetting the not-recorded case at any call site |
| private `WithdrawalDays._` | unconstructible | any construction path that is not the named factory |
| **required named** `days:`, no default | unconstructible | `WithdrawalDays()` compiling at all |
| throwing on `days < 0` | unconstructible | a coerced value entering the system quietly |

An `extension type` cannot give you a *private generative constructor*, which is why this is a hand-written sealed class and not the `extension type` some of the research proposed (decision #51). `freezed` is rejected for the same reason before you even reach its resolution problem: it generates a public constructor and a total `copyWith`.

**What the type deliberately cannot express: milkings.** VICH expresses milk withdrawals in **milkings** as well as days, normally on a 12-hour interval. `WithdrawalDays` cannot hold *"6 milkings"* and **must never be used to**. Converting 6 milkings to 3 days requires assuming a milking interval that the label did not state, which is the app originating a number — safety rule 2 — and then presenting it as the user's own, which is safety rule 4 on top. The v1 rule, in three lines:

- A label that states only milkings is recorded as `WithdrawalNotRecorded` for that target, with the number typed into the treatment **note** field verbatim.
- The UI shows `WithdrawalUnknown` for it. It does not offer a conversion, a calculator, or a hint.
- v2 adds a fourth sealed subtype `WithdrawalMilkings({required int count, required int intervalHours})` — the interval is **required and user-supplied**, for the same reason `days` is. Adding it is a compile-error-guided change at every `switch`, which is the whole point of `sealed`. Whether that fourth subtype ever ships is a v2 question and stays one. What was decision-record §7.1 question 10 (*is the target market ever a dairy flock?*) was **ruled on 2026-08-01** (§7.0 row 10): `WithdrawalTarget.milk` ships in the v1 schema, because retrofitting it is a migration and shipping it now is free. `WithdrawalMilkings` does **not** exist in v1 and nothing converts milkings to days.

The primary-source basis for "the interval must be supplied, not assumed" is EMA/CVMP/SWP/735418/2012 §4.1.2: the milk period *"is initially calculated in milkings and rounded up to the first higher full number of milkings […] because a different milking frequency can be used in practice, the final unit of the milk withdrawal period should be real time."*

### 3.3 The persistence shape

The canonical table lives in [`03-data-model-and-schema.md`](03-data-model-and-schema.md). The *contract* this document imposes on it:

```sql
CREATE TABLE treatment_withdrawals (
  id            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  uid           TEXT NOT NULL UNIQUE,
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL,
  treatment     INTEGER NOT NULL REFERENCES treatments(id) ON DELETE CASCADE,
  target        TEXT NOT NULL,              -- 'meat' | 'milk'
  kind          TEXT NOT NULL,              -- 'days' | 'not_applicable'
  days          INTEGER,                    -- NO DEFAULT. NO clientDefault.
  clear_date    TEXT,                       -- computed once at write time
  CHECK (target IN ('meat','milk')),
  CHECK (kind IN ('days','not_applicable')),
  CHECK ((kind = 'days') = (days IS NOT NULL)),
  CHECK ((kind = 'days') = (clear_date IS NOT NULL)),
  CHECK (days IS NULL OR days >= 0),
  CHECK (clear_date IS NULL
         OR clear_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
  UNIQUE (treatment, target)
) STRICT;
CREATE INDEX idx_withdrawal_clear ON treatment_withdrawals(clear_date);
```

`UNIQUE (treatment, target)` is also the hand-written index decision #31 requires on the `treatment` foreign key — SQLite creates no child-key index by itself, and a leading-column index serves the FK. Do not add a second one.

Read the mapping carefully, because the absence is the mechanism:

| Domain state | Rows for that target |
|---|---|
| `WithdrawalDays(n, target)` | one row, `kind='days'`, `days=n`, `clear_date` set |
| `WithdrawalNotApplicable(target)` | one row, `kind='not_applicable'`, `days IS NULL` |
| `WithdrawalNotRecorded` | **no row** |

**No row means not recorded.** There is no column whose default could quietly mean "zero days", because there is no row at all. This is why the child table beats spec §10's single `withdrawal_days_user_entered` field — a documented, deliberate deviation from the spec's sketch, taken because a non-nullable single `int` column cannot express "I did not look at the bottle", which is the exact confusion §12.1 exists to prevent.

Note the second deviation: `clear_date` sits on the withdrawal row, not on `Treatment`, because a bottle with two numbers clears on two dates.

### 3.4 The output type

`LocalDate? clearDate` reintroduces exactly the null the input type just eliminated, so the output is sealed too.

```dart
// lib/domain/withdrawal/withdrawal_status.dart
sealed class WithdrawalStatus { const WithdrawalStatus(); }

/// The animal is clear for the WHOLE of [date].
final class ClearsOn extends WithdrawalStatus {
  final LocalDate date;
  /// The exact instant the label's period elapses, shown next to the date so
  /// the shepherd can check our arithmetic against their own.
  final Instant elapsesAt;
  final WithdrawalTarget target;
  const ClearsOn(this.date, this.elapsesAt, this.target);
}

final class NoWithdrawal      extends WithdrawalStatus { const NoWithdrawal(); }
final class WithdrawalUnknown extends WithdrawalStatus { const WithdrawalUnknown(); }
```

The countdown widget takes a `ClearsOn`, not a `WithdrawalStatus`. It is therefore *type-impossible* to render a countdown for a period nobody entered. `WithdrawalUnknown` is a state with a name and its own widget — "Withdrawal not recorded" plus a 60 pt "Add it" action — never a blank cell and never an em-dash that might mean zero.

### 3.5 The clear-date algorithm

```dart
// lib/domain/withdrawal/clear_date.dart

/// The ONE function that computes a clear date. Called exactly once per
/// withdrawal row, at write time (decision #50).
///
/// clearDate = ceil-to-next-local-midnight(administeredAt + N x 24 h),
/// computed in ABSOLUTE time. Civil-day arithmetic is banned here.
///
/// The ceil looks like an over-hold and it is not: the regulator already
/// rounded the label number UP (EMA CVMP §4.1.2 — to whole milkings, then to
/// whole 12- or 24-hour multiples). A second rounding in the same direction is
/// safe and bounded by 24 h. Rounding the other way eats the regulator's own
/// margin. Do not "simplify" this. See 05-domain-correctness.md §3.7.
({LocalDate date, Instant elapsesAt}) clearDateFor({
  required Instant administeredAt,
  required int days,
}) {
  final elapsesAt = administeredAt.plus(Duration(hours: days * 24));
  final dayOfElapse = LocalDate.of(elapsesAt);
  final startOfThatDay = dayOfElapse.startOfDayLocal();
  final date = elapsesAt.epochMillis == startOfThatDay.epochMillis
      ? dayOfElapse            // elapses exactly at midnight: that whole day is clear
      : dayOfElapse.plusDays(1);
  return (date: date, elapsesAt: elapsesAt);
}

WithdrawalStatus computeWithdrawalStatus({
  required Instant administeredAt,
  required WithdrawalPeriod period,
}) =>
    switch (period) {
      WithdrawalNotRecorded() => const WithdrawalUnknown(),
      WithdrawalNotApplicable() => const NoWithdrawal(),
      WithdrawalDays(:final days, :final target) => () {
          final r = clearDateFor(administeredAt: administeredAt, days: days);
          return ClearsOn(r.date, r.elapsesAt, target);
        }(),
    };
```

Worked example, the one to keep in your head: treated **Tue 3 Mar 20:00**, 7 days. The period elapses **Tue 10 Mar 20:00**. Ten March is therefore only *partly* clear, so the first fully clear day is **Wed 11 Mar**.

Two edge behaviours, both deliberate:

- **A zero-day withdrawal** elapses at the moment of administration, which is almost never local midnight, so the clear date is *tomorrow*. That is correct: today is a partial day. It is also the case that proves `0` is a real value flowing through real code.
- **A zone with no local midnight** (some historical DST rules skip it). `DateTime(y, m, d)` returns the first instant that does exist that day, the millisecond comparison fails, and we take the next day. The algorithm never rounds *down*.

### 3.6 Why civil-day arithmetic is banned here

Measured, under `TZ=Europe/London`: a civil `+7` across the UK spring-forward yields **167 hours, not 168** — one hour short of a seven-day withdrawal, on a treatment given in late March, which is peak lambing. Test DST-4 in §2.9 pins exactly that number so a future "simplification" fails CI. The second, larger error is quieter: a treatment recorded as a *date* rather than an instant throws away up to 24 h of the period before the arithmetic even starts. That is why `administered_at` is an `Instant`.

### 3.7 The conservative-interpretation argument

VICH — the international veterinary-medicines harmonisation body whose members include the EMA and the FDA — defines the withdrawal period as *"the minimum period between the last administration of a veterinary medicinal product to an animal and the production of foodstuffs from that animal"*, and states that *"where the calculated withdrawal period is a fraction of a day or milking, it is rounded up to the next full day or milking."*

The EMA's milk guideline is the stronger citation, because it describes how a label number is *read* rather than how it was derived. EMA/CVMP/SWP/735418/2012 §4.1.1: *"a milk withdrawal period of 108 hours means that all the milk up to and including the last milking before 108 hours after treatment must be discarded […] milk from the first milking at or after 108 hours is considered safe."* And §4.1.2: *"the final unit of the milk withdrawal period should be real time."*

Three consequences, in order:

1. It is fundamentally an **elapsed-time** quantity — a residue-depletion curve as a function of time since the last dose — that the regulator has already rounded **up** to whole days for the label. It is not "N sleeps". *"At or after N hours"* is the regulator's own phrasing.
2. The clock starts at a **moment**, not at midnight.
3. Because the regulator already rounded up — twice, in the milk case: to whole milkings, then to whole 12- or 24-hour multiples — **a second rounding in the same direction is safe; rounding the other way eats the regulator's own margin.** Ceil-to-next-local-midnight is that second rounding, and it is bounded by 24 h. Put that sentence in the code comment above `clearDateFor`, because the next developer's instinct will be to "fix" the apparent over-hold.

The honest cost: a shepherd counting on their fingers from 3 March gets 10 March, and the app says 11 March. The app is one day more conservative than the folk method, and it must show its working rather than look broken:

> **Clear on Wed 11 Mar** · 7 days as entered by you, from Tue 3 Mar 20:00, ends Tue 10 Mar 20:00.

**A setting to "count whole days from the day of treatment" is rejected outright.** It is a food-safety setting whose wrong value puts meat in the food chain, buried in a screen nobody opens at 3am, and it would let the app produce a number *less* conservative than the label. There is no version of configurable food safety that belongs in a one-time-purchase notebook.

The provenance words are non-negotiable and come from one place (§7.4): `Disclaimers.withdrawalProvenance` — *"as entered by you"* — rendered next to every withdrawal figure, every clear date, and in every export.

### 3.8 Stored once, and what happens when the inputs change

`clear_date` is **the one stored derived value in the app** (decision #50), because it is not really derived: it is a record of what the app told the user on the day, and it is printed into a medicine-book PDF that may be handed to a vet or an abattoir. It is computed exactly once, by `clearDateFor()`, inside the same `db.transaction` that writes the withdrawal row. Its inputs — `administered_at`, `days`, `target` — are stored alongside it forever.

If a later edit changes an input, or a device zone change moves the boundary, the stored value and a fresh computation can disagree. That disagreement is **shown, never applied**:

```dart
// lib/domain/validation/treatment_checks.dart
List<Warning> checkClearDate({
  required Instant administeredAt,
  required int days,
  required LocalDate storedClearDate,
}) {
  final recomputed = clearDateFor(administeredAt: administeredAt, days: days).date;
  if (recomputed.compareTo(storedClearDate) == 0) return const [];
  return [
    Warning(
      WarningCode.clearDateDisagrees,
      'This treatment was saved with a clear date of ${storedClearDate.iso}. '
      'From the details now recorded it would be ${recomputed.iso}.',
      fieldPath: 'withdrawal',
    ),
  ];
}
```

There is no `fix()`. Editing the treatment is a user action that writes a new `clear_date` through the normal repository path; nothing else may rewrite it.

### 3.9 The two gates that prove "never default a withdrawal"

Decision #52 allows **two** gates and no more. The sealed type makes the wrong state unconstructible, so a source heuristic hunting for numeric literals near the word "withdrawal" only fires on `CHECK` constraints and test fixtures, and a gate that gets weakened is worse than no gate.

**Gate 1 — the schema assertion**, in `test/policy/withdrawal_has_no_default_test.dart`. The committed drift schema JSON must show no default of any kind on `days`:

```dart
test('SAFETY RULE 1 (schema): treatment_withdrawals.days has no default', () {
  final schema = jsonDecode(
      File('drift_schemas/drift_schema_v$kSchemaVersion.json').readAsStringSync())
      as Map<String, dynamic>;
  final col = columnOf(schema, table: 'treatment_withdrawals', column: 'days');
  expect(col['defaultValue'], isNull, reason: 'no SQL DEFAULT');
  expect(col['clientDefault'], isNull, reason: 'no clientDefault');
  expect(col['customConstraints'], isNot(contains('DEFAULT')));
});
```

`defaultValue` and `clientDefault` are the key names decision #52 names and the ones [`04-migrations-media-backup-restore.md`](04-migrations-media-backup-restore.md)'s own import-defaults test already reads; the snapshot file naming (`drift_schemas/drift_schema_v<N>.json`) is that document's convention. Read the committed file once at commit #1 and confirm both before relying on this test — a gate that asserts `isNull` on a key that does not exist passes for the wrong reason.

**Gate 2 — the widget test.** The field starts empty, and an untouched field saves as `NotRecorded`:

```dart
testWidgets('SAFETY RULE 1 (UI): an untouched withdrawal field saves as not recorded', (t) async {
  await t.pumpWidget(harness(const TreatmentEntryScreen()));
  expect(find.text('0'), findsNothing);                        // no seeded zero
  expect(find.text('Withdrawal not recorded'), findsOneWidget); // the named state
  await t.tap(find.byKey(const Key('treatment.save')));
  await t.pumpAndSettle();
  final rows = await db.select(db.treatmentWithdrawals).get();
  expect(rows, isEmpty);                                       // absence IS the state
});
```

**Anti-patterns.** `?? 0` anywhere within reach of a withdrawal. A `withDefault(const Constant(0))` on `days`. A medicines lookup table of any kind — the app ships no product database and suggests no value (decision-record §5.3 and spec §11). A countdown widget that accepts `WithdrawalStatus` rather than `ClearsOn`.

### 3.10 The three paths that route around the type

The sealed type stops a bad *value*. These three features get at the withdrawal without constructing one — by copying a good value onto the wrong treatment, or by keeping a stale one alive — so each needs its own rule.

**1. Repeat last treatment (spec §7.5) copies everything except the withdrawal.** Product name, dose, route and batch are copied; `WithdrawalPeriod` starts as `WithdrawalNotRecorded` and the field starts empty. This is the highest-risk feature in the app for §12.1, precisely because pre-filling every field *except one* reads as an oversight to whoever implements it next. The reason is not tidiness, it is NADIS on sheep medicine usage: withdrawal periods *"can change for the same medicine and differ between products with the same active ingredient."* The same trade name, bought twice, can carry two different numbers. Put that sentence in a comment at the copy site or it will be "fixed".

**2. No learned default, ever.** "You usually enter 28 for this product" is a medicines lookup table that the user built by accident, and it fails for exactly the reason above, silently, on the one bottle that changed. There is no allowlist, no confidence threshold and no "we noticed…" prompt. A widget test asserts that the second treatment of an identical product still saves with no withdrawal row.

**3. A soft-voided treatment is excluded from withdrawal surfaces and never recomputed.** Undo of a treatment is a soft void (decision #69): `treatments.voided_at` is set and the row stays, because it may already have been printed into a medicine book handed to a vet. So: every "is she clear?" / countdown / clear-date query filters `voided_at IS NULL`; the withdrawal row, its inputs and its stored `clear_date` are **never** deleted, blanked or recalculated; and the medicine book shows the treatment struck through with its void date, still carrying the withdrawal figure it was saved with. Voiding is not evidence that the animal was never treated — it is evidence that the *record* was wrong — so the app makes no claim either way and shows both facts.

---

## 4. `RecordedTime` — provenance is part of the value

> Spec §12.5: *"Timestamps are honest. Auto-captured time is labelled as such; edited time is labelled as edited."*

### 4.1 The type

```dart
// lib/domain/time/recorded_time.dart
enum TimeSource {
  autoCaptured('auto'),
  userEntered('entered'),
  userEdited('edited');

  const TimeSource(this.key);
  /// Frozen. Written to SQLite, CSV and the JSON backup. Never localised.
  final String key;

  static TimeSource fromKey(String k) =>
      TimeSource.values.firstWhere((s) => s.key == k,
          orElse: () => throw FormatException('Unknown time source', k));

  /// 07 §1.5's three strings, verbatim. ON THE ENUM rather than on RecordedTime
  /// because the CSV's §12.5 trailer line is built from TimeSource.values and a
  /// writer has no instance to ask (09 §1.3). The exhaustive switch does not
  /// weaken by moving — a fourth member is still a compile error here.
  String get label => switch (this) {
        TimeSource.autoCaptured => 'recorded automatically',
        TimeSource.userEntered  => 'time entered by you',
        TimeSource.userEdited   => 'time edited by you',
      };
}

final class RecordedTime {
  /// The value that counts: when the event happened.
  final Instant effective;

  /// When the row was first written. Never changes. Never editable.
  final Instant capturedAt;

  /// Present only when [source] is userEdited: the FIRST effective value ever
  /// held, preserved across an unbounded chain of edits.
  final Instant? originalEffective;

  final TimeSource source;

  const RecordedTime._(this.effective, this.capturedAt, this.originalEffective, this.source);

  /// Auto-captured: effective == the moment of the write.
  factory RecordedTime.capture(Instant now) =>
      RecordedTime._(now, now, null, TimeSource.autoCaptured);

  /// The user typed a time at creation — a deferred entry. It was never wrong.
  factory RecordedTime.entered({required Instant effective, required Instant now}) =>
      RecordedTime._(effective, now, null, TimeSource.userEntered);

  /// There is no setter and no way to clear [originalEffective].
  RecordedTime editedTo(Instant newEffective) => RecordedTime._(
      newEffective, capturedAt, originalEffective ?? effective, TimeSource.userEdited);

  bool get isEdited => source == TimeSource.userEdited;

  /// Never empty: the label is part of the value, by exhaustive switch.
  /// DELEGATES to TimeSource.label (N21-T01) — one switch, on the enum. Two
  /// copies of these three strings is two things to keep in step, and the
  /// second stops being read the moment it stops being wrong.
  String get provenanceLabel => source.label;

  /// The time it takes an entry to reach the app. Only meaningful because
  /// [capturedAt] is immutable; it is how spec §15's "within five minutes of
  /// the event" is measurable at all.
  Duration get entryLag => capturedAt.difference(effective);
}
```

Three fields, three distinct facts, none derivable from the others: `effective` (when it happened), `capturedAt` (when we found out), `originalEffective` (what we first thought). The `userEntered`/`userEdited` split is not pedantry — a deferred entry typed at 7am for a 03:20 lambing was never wrong, whereas an edited one was.

`provenanceLabel` is English in the domain, which is correct today because v1 ships `en` only (decision #108). If a second locale ever ships, the label moves to ARB and the exhaustive-switch test (§4.4) moves with it. The withdrawal provenance string is different — it lives in `Disclaimers` permanently and never goes near ARB, because a translator can soften or drop an ARB string and the app has no mechanism to notice.

### 4.2 The columns

```sql
occurred_at         INTEGER NOT NULL,   -- RecordedTime.effective (see the naming note in §2.2)
captured_at         INTEGER NOT NULL,
original_effective  INTEGER,
time_source         TEXT NOT NULL,
CHECK (time_source IN ('auto','entered','edited')),
CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))
```

`Treatments` spells the first column `administered_at`, `PenOccupancies` spells it `entered_at` and `FosterEvents` spells it `effective_at` — the three documented exceptions (R37); everything else about the quadruple is identical. That last `CHECK` makes "edited but we lost what it was edited from" unstorable. Any entity carrying a user-facing event time carries this whole quadruple: `Lambings`, `Treatments`, `CareEvents`, `FosterEvents`, `EweObservations`, `PenOccupancies`, `Notes`, deaths — R37 adds the last four to the schema before the first snapshot, together with a new `notes.occurred_at`, and until it lands the standing rule is absolute: **a table without the quad has no edit verb.** Three loose columns make the §12.5 label *true but uninformative*; this shape keeps the pre-edit value.

`time_source` is the one column in the quadruple that carries a SQL `DEFAULT` (`'auto'`). That is inside decision #31, which bans a `DEFAULT` on any column *that could encode veterinary advice* — a provenance label is not one, and the default is the only value a row can honestly have at the instant it is first written.

### 4.3 How it renders and how it exports

| Surface | Rule |
|---|---|
| Any screen showing an event time | The provenance label appears in the same visual block as the time. Never a bare `03:21`. |
| Edited times | "03:20 · time edited by you · was 07:00". The original is shown, not merely implied. |
| Lambing spread, statistics | Use `effective`. Never `capturedAt`. |
| Diagnostics / success metrics | Use `entryLag`. Never displayed to the user as a judgement. |
| **PDF** | Append a dagger to an edited time — `03:20 †` — with a footer legend `† time edited by the user`. A PDF with no marker and no legend lies by omission. |
| **CSV** | Five columns, below. |
| **JSON backup** | The whole object, all four fields, so a restore is lossless. |

CSV columns, in every shape that carries an event ([`09-export-formats.md`](09-export-formats.md) owns the writers):

| Column | Content |
|---|---|
| `event_time_local` | `2026-03-04T03:20:00.000+00:00` — ISO 8601 **with offset**: what the shepherd saw |
| `event_time_utc` | `2026-03-04T03:20:00.000Z` — unambiguous, sortable, machine-safe |
| `time_source` | `auto` \| `entered` \| `edited` — the **stable key**, never the label |
| `time_recorded_at_utc` | when the row was written |
| `time_originally_utc` | the pre-edit value, empty unless `edited` |

Both local-with-offset **and** UTC. Local alone is ambiguous in the fall-back hour (§2.9); UTC alone is unreadable to a shepherd who wants to see "03:20".

### 4.4 The tests

```dart
test('provenance label is never empty, for any source', () {
  for (final s in TimeSource.values) {
    final rt = switch (s) {
      TimeSource.autoCaptured => RecordedTime.capture(t0),
      TimeSource.userEntered  => RecordedTime.entered(effective: t0, now: t1),
      TimeSource.userEdited   => RecordedTime.capture(t0).editedTo(t1),
    };
    expect(rt.provenanceLabel, isNotEmpty);
  }
});

test('editing preserves the ORIGINAL across many edits', () {
  var rt = RecordedTime.entered(effective: t7am, now: t7am);
  rt = rt.editedTo(t0330).editedTo(t0320).editedTo(t0315);
  expect(rt.effective, t0315);
  expect(rt.originalEffective, t7am);   // the first value, not the previous one
  expect(rt.capturedAt, t7am);          // never moves
  expect(rt.source, TimeSource.userEdited);
});

test('time_source keys are FROZEN — changing one breaks every export ever written', () {
  expect(TimeSource.values.map((s) => s.key).toList(), ['auto', 'entered', 'edited']);
});
```

**Anti-patterns.** A single `date` column. The three-loose-column shape (an instant, a source, and a "when it was edited" stamp) — it records *that* a time was edited and loses *what it was edited from*, which makes the §12.5 label true but uninformative. A `copyWith` on `RecordedTime` that accepts `capturedAt`. Exporting the localised label instead of the key.

---

## 5. Units

> Spec §7.10: *"Units: kg / lb, °C / °F."*

### 5.1 The canonical-storage rule

> **One canonical unit is stored. Display units are computed at the widget boundary and are never assigned to a variable that flows back toward the database.**

The bug this prevents is the **display-unit round trip**: the user enters 9.5 lb; you store 9.5 with a unit flag; they switch to kg and see 4.309; the edit screen pre-fills 4.3 at 1 dp; they save without touching it; the record is now 4.3 kg = 9.48 lb. The value drifted because nobody edited it — a silent correction with no line of code to blame.

Concretely:

- **No `unit` column on any measurement.** A schema test asserts it.
- The unit preference lives in `app_settings` and affects **rendering and parsing only**. It is typed `enum WeightUnit { kg('kg'), lb('lb') }` in `lib/domain/units/weight_unit.dart`, whose keys are exactly `app_settings.weight_unit`'s CHECK strings; the UI reads it through `unitsProvider` (R68).
- The form controller is seeded from the canonical value each time it opens; on save it parses the **typed text** into canonical. It never re-derives from the old canonical.

**The display defaults are settled, not open** (decision-record §7.0 ruling 3: UK/Ireland first). `app_settings.weight_unit` defaults to `'kg'` and `temperature_unit` to `'c'`, and the app ships `en_GB` with a 24-hour clock and Monday as the first day of the week. The one place the ruling and decision #108 have to be read together is the date format: `dd/MM/yyyy` is the region's *numeric* convention and it appears only inside CSV, always beside an ISO-8601 column. **No date shown to a human is ever all-numeric** — `d MMM y`, so `07/13` can never be read as 13 July. That is why every date in this document's example copy reads *"Wed 11 Mar"*.

### 5.2 Canonical mass = integer grams. Canonical temperature = integer milli-°C.

This is decision #56 and it was chosen by measurement, not taste. Storing mass at 0.1 kg silently rewrites **132 of 241** pound entries at 1 dp (55%) — a user in an imperial county types **1.2 lb** for a tiny hill triplet and the app shows **1.1 lb** on the next screen. Storing temperature at 0.1 °C rewrites **89 of 201** Fahrenheit entries (44%); 0.01 °C is the *minimum* that survives all 201, so milli gives headroom for a 2 dp display without a migration. Integer grams and milli-°C rewrite **none**. Both coarse choices are safety-rule-4 violations produced purely by a storage decision, in roughly half of all possible entries, invisible in code review.

```dart
// lib/domain/units/grams.dart
/// Canonical mass: whole grams. Non-transparent extension type, so a raw `int`
/// cannot be passed where a mass is expected, and it costs no allocation on a
/// 400-row flock list.
extension type const Grams(int value) {
  static const double _gPerLb = 453.59237;     // exact, by definition
  static const double _gPerOz = 28.349523125;  // exact, by definition

  factory Grams.fromKilograms(double kg) => Grams((kg * 1000).round());
  factory Grams.fromPounds(double lb)    => Grams((lb * _gPerLb).round());
  factory Grams.fromPoundsOunces(int lb, double oz) =>
      Grams((lb * _gPerLb + oz * _gPerOz).round());

  double get inKilograms     => value / 1000.0;
  double get inPounds        => value / _gPerLb;
  int    get wholePounds     => inPounds.floor();
  double get remainderOunces => (value - wholePounds * _gPerLb) / _gPerOz;
}
```

```dart
// lib/domain/units/milli_celsius.dart
/// Canonical temperature: thousandths of a degree Celsius.
extension type const MilliCelsius(int value) {
  factory MilliCelsius.fromCelsius(double c) => MilliCelsius((c * 1000).round());
  factory MilliCelsius.fromFahrenheit(double f) =>
      MilliCelsius(((f - 32) * 5 / 9 * 1000).round());

  double get inCelsius    => value / 1000.0;
  double get inFahrenheit => value / 1000.0 * 9 / 5 + 32;
}
```

Use `round()`, never `toInt()` (truncates toward zero — systematically light) and never `ceil()`/`floor()`. Add a boundary test at `x.5`.

**Never build an extension type for a display unit.** `Pounds` and `Fahrenheit` would erase to the same runtime type as `Grams` and `MilliCelsius`, giving false confidence in any `is`/`switch`/serialisation path and inviting somebody to store one. Pounds and Fahrenheit exist only as `double` returns from a getter, consumed immediately by a formatter.

**Where does temperature appear at all? Nowhere.** Decision-record §7.0 row 11, ruled 2026-08-01: no v1 table stores a temperature, and `app_settings.temperature_unit` is dropped with it along with the Settings °C/°F row and `temperatureUnitProvider`. `MilliCelsius` **still ships and is not deleted** — the measured reason it exists is independent of whether a v1 column uses it. **Do not add a temperature column**, because an unused setting is a 3am tax and an unused column is a migration you did not need.

### 5.3 The tests that are the specification

```dart
test('UNITS: a 0.1 lb entry survives a round trip at 1 dp', () {
  for (var tenths = 10; tenths <= 250; tenths++) {         // 1.0 .. 25.0 lb
    final lb = tenths / 10.0;
    final g = Grams.fromPounds(lb);
    expect(double.parse(g.inPounds.toStringAsFixed(1)), closeTo(lb, 1e-9),
        reason: '$lb lb -> ${g.value} g -> ${g.inPounds}');
  }
});

test('UNITS: a 0.1 F entry survives a round trip at 1 dp', () {
  for (var tenths = 950; tenths <= 1150; tenths++) {       // 95.0 .. 115.0 F
    final f = tenths / 10.0;
    final t = MilliCelsius.fromFahrenheit(f);
    expect(double.parse(t.inFahrenheit.toStringAsFixed(1)), closeTo(f, 1e-9));
  }
});

test('UNITS: 0.1 kg canonical WOULD corrupt lb entries — this is why grams', () {
  var corrupted = 0;
  for (var tenths = 10; tenths <= 250; tenths++) {
    final lb = tenths / 10.0;
    final hectograms = (lb * 453.59237 / 100).round();     // the rejected design
    final back = double.parse((hectograms * 100 / 453.59237).toStringAsFixed(1));
    if (back != lb) corrupted++;
  }
  expect(corrupted, 132, reason: 'the measurement behind decision #56');
});
```

The third test looks odd and it stays. It is the executable form of the argument, and it is what fails when somebody "simplifies" the canonical unit in season three.

Add an explicit table of round-trip cases for the same values (decision #118, amended 2026-08-01 — `glados` does not resolve against `drift_dev` at any version and is struck from §5.2, so the pure-value layer is a written table rather than a generator). Do not extend it beyond value types.

### 5.4 Input

Weights use **the in-app 60×60 pt keypad**, the same component as tag entry, with one decimal key that always emits `.` (decision #57). This removes the whole locale problem: `double.parse('4,3')` throws, and `NumberFormat.parse` for a comma locale throws on `'4.3'` — which is worse, because a UK shepherd's phone may be set to French. It also gives 60 pt targets by construction and no keyboard-dismissal jank.

For any free-text numeric field that survives review:

~~The body below resolved `'1,5'` to 1.5.~~ **Amended 2026-08-01 (N04-T06).** Feed the printed
version `'1,5'`: one comma, zero dots, neither guard fires, and it returns **1.5**. That is a guess.
This section's own comment says guessing `'4,3'` means 43 is a silent correction, and then resolves
the same ambiguity in the other direction — which is the same act. A comma is ambiguous in `en_GB`
full stop, so **any comma returns null**.

```dart
// ~~the printed body — struck 2026-08-01~~
//   if (commas > 0 && dots > 0) return null;   // returns 1.5 for '1,5'
//   if (commas > 1 || dots > 1) return null;
//   return double.tryParse(s.replaceAll(',', '.'));
```

A second correction from the same commit: `double.tryParse` is more forgiving than a shepherd's
typing warrants. It accepts `'4.'` as 4.0, and `'1e3'`, `'0x10'`, `'Infinity'` and `'NaN'` as
themselves. A trailing point is a half-typed number and none of the rest can be entered on a keypad
with one decimal key, so the shape is matched before the parse.

```dart
// lib/domain/units/parse_number.dart
/// Rejects ambiguity rather than guessing. Guessing that '4,3' means 43 is a
/// silent correction (safety rule §12.4) — and so is guessing it means 4.3.
double? parseUserNumber(String raw) {
  final s = raw.replaceAll(' ', '');
  if (s.contains(',')) return null;          // ambiguous in en_GB, both ways
  if (!_plain.hasMatch(s)) return null;      // '4.', '1e3', '0x10', 'NaN'
  return double.tryParse(s);
}

final _plain = RegExp(r'^-?\d+(\.\d+)?$');
```

`null` becomes a `Warning`, never a value.

**The input step for a lamb birthweight is unresolved** (open question 12). The field kit is a hanging spring balance or a digital hook scale; the practical readable resolution is 0.1 kg, occasionally 0.05 kg or 50 g. Grams as canonical is right either way — the binding constraint is lb↔kg round-tripping, not scale resolution — so **ship the keypad step at 0.1 kg and treat it as changeable**, and get the twenty minutes with a real shepherd before you tune the plausibility band.

**The plausibility band, exactly, as shipped:** warn when the canonical value is below `Grams(1000)` or above `Grams(10000)`. Both bounds are inclusive-pass — 1.0 kg and 10.0 kg do not warn. The band is derived from AHDB's optimum birthweights for 70–85 kg ewes to a terminal sire (single 4.5–6.0 kg, twin 3.5–4.5 kg, triplet >3.5 kg), widened downward by the 1.0–1.5 kg that hill breeds run lighter and upward for headroom. It is **provisional pending open question 12** and it is a single named constant, not a literal at the check site: `const ({Grams min, Grams max}) kPlausibleBirthWeight = (min: Grams(1000), max: Grams(10000));` in `lib/domain/validation/lambing_checks.dart`. It produces a `Warning` — an observation — never a block and never a judgement.

**Anti-patterns.** `double` for a measurement (SQLite `SUM` and `==` become approximate and a JSON round trip can shift the last digit). `package:decimal` or `package:fixed` (`BigInt` allocations for a problem `int` solves exactly; both are in decision-record §5.3's rejected table). A `unit` column. Seeding an edit form from a display value.

---

## 6. The statistics (spec §7.8)

> *A wrong denominator makes the headline number a lie.* The same toy season — 5 ewes to the ram, 3 lambed, 6 lambs of which 1 stillborn and 1 died at 2 days, 1 ewe recorded barren, 1 with no recorded outcome — yields **120% / 100% / 80% / 200%** under four legitimate published definitions. A bare `double` leaving the domain layer is a lie waiting to be quoted over a gate.

### 6.1 The return type

```dart
// lib/domain/stats/definitions.dart
final class StatResult {
  /// null means NOT COMPUTABLE. Never 0 as a stand-in for unknown.
  final double? value;
  /// Human-readable, rendered under the number and exported verbatim.
  final String definition;
  final int numerator;
  final int denominator;
  final String? notComputableReason;
  final List<String> caveats;

  const StatResult({
    required this.value,
    required this.definition,
    required this.numerator,
    required this.denominator,
    this.notComputableReason,
    this.caveats = const [],
  });

  const StatResult.notComputable({
    required this.definition,
    required String reason,
    this.numerator = 0,
    this.denominator = 0,
    this.caveats = const [],
  })  : value = null,
        notComputableReason = reason;
}
```

UI and export contract, all four parts mandatory:

1. The `definition` string renders **under every headline number, always** — not behind an info icon.
2. `numerator / denominator` renders too ("6 / 5"). It is the cheapest possible way for a shepherd to sanity-check a number that looks wrong, and at 18 pt it costs one line.
3. The CSV and PDF carry the definition string **verbatim** alongside the value.
4. `notComputableReason` is displayed as the value's replacement. No blank cell, no `NaN`, no em-dash that might mean zero.

**`?? 0` is banned outright in `lib/features/season/**` and `lib/features/flock/**`** and is a `tool/check_policy.dart` rule. It is on the code-review checklist as well, because a `?? 0` on a nullable aggregate turns "we have not recorded that" into "you scored zero".

### 6.2 The definition types

```dart
enum LambCount {
  born('born'),          // all lambs delivered, alive or dead  (Sheep Ireland)
  bornAlive('born_alive'), // excludes stillborn                (AHDB)
  reared('reared');      // alive at the end of the season      (AHDB rearing %)
  const LambCount(this.key);
  final String key;
}

enum FlockDenominator {
  ewesPutToRam('ewes_to_ram'),  // AHDB, and Penn State's "more accurate" method
  ewesLambed('ewes_lambed');    // prolificacy
  const FlockDenominator(this.key);
  final String key;
}

typedef LambingPercentageDefinition = ({LambCount count, FlockDenominator per});
```

The record is the *computation* input. It is not what gets stored: the pair admits six combinations and only **four** are offered, because `app_settings.percentage_definition` is a `CHECK`-constrained key ([`03-data-model-and-schema.md`](03-data-model-and-schema.md)). Model the four as a closed enum so an unstorable pair cannot be constructed, and so the exported definition string has exactly one spelling per choice:

```dart
enum LambingPercentageChoice {
  bornAlivePerEweToRam('born_alive_per_ewe_to_ram',
      LambCount.bornAlive, FlockDenominator.ewesPutToRam,
      'lambs born alive per ewe put to the ram'),
  bornInclStillbornPerEweToRam('born_incl_stillborn_per_ewe_to_ram',
      LambCount.born, FlockDenominator.ewesPutToRam,
      'lambs born incl. stillborn per ewe put to the ram'),
  bornAlivePerEweLambed('born_alive_per_ewe_lambed',
      LambCount.bornAlive, FlockDenominator.ewesLambed,
      'lambs born alive per ewe lambed'),
  rearedPerEweToRam('reared_per_ewe_to_ram',
      LambCount.reared, FlockDenominator.ewesPutToRam,
      'lambs reared per ewe put to the ram');

  const LambingPercentageChoice(this.key, this._count, this._per, this.definition);

  /// Stable storage/export key. Identical to the strings in the column's CHECK.
  final String key;
  /// Rendered under the number and exported verbatim. Frozen by a test.
  final String definition;
  final LambCount _count;
  final FlockDenominator _per;

  LambingPercentageDefinition get definitionParts => (count: _count, per: _per);

  /// Settled by the owner (decision-record §7.0): UK/Ireland first, so the
  /// default follows AHDB. The setting remains user-configurable per §7.8.
  static const LambingPercentageChoice ahdbDefault = bornAlivePerEweToRam;
}
```

Two tests hold this together and both are cheap: the four `key` values equal the four strings in the column's `CHECK` (read the committed schema JSON), and the four `definition` strings are pinned literally, because they are printed into CSVs and PDFs that outlive the app.

**"Born alive" versus "born incl. stillborn" is the choice shepherds differ on first**, before they differ on the denominator, because it is the less visible one — OMAFRA's published *"number of lambs born"* explicitly includes stillborn and mummified lambs, AHDB's does not. That is why stillborn treatment is in the definition string itself and not a footnote.

AHDB's house convention counts lambs born **alive** and uses "ewes put to the tup" as the denominator for all five of its lamb-loss KPIs. Sheep Ireland, in the neighbouring country of the same primary market, counts dead lambs in "born"; OMAFRA divides by ewes *lambing*. On one flock — 100 to the ram, 92 lambed, 165 born — OMAFRA reads **179%** and AHDB-style reads **165%**. Fourteen points apart, both correct, both called "lambing percentage" in ordinary speech. That is why §7.8 says the definition is configurable and why the first-run Settings copy names the conventions rather than just the formulas.

### 6.3 The input type and where the counts come from

The domain takes plain records. The data layer produces them with `customSelect` and an explicit `readsFrom:` — **never** a `groupBy` inside a Dart-defined drift `View` (decision #60; drift's Dart-views page documents exactly one shape and says nothing about `groupBy` inside `as()`).

```dart
// lib/domain/stats/season_counts.dart — plain Dart, no drift import
final class SeasonCounts {
  final int? ewesPutToRam;               // null = not entered for this season
  final int ewesLambed;                  // distinct birth dams with >=1 lambing carrying >=1 lamb
  final int lambingsTotal;
  final int lambingsWithLambs;
  final int lambingsScored;              // ease score present
  final int lambingsScoredAssisted;      // ease >= 2
  final int lambsBorn;                   // alive + dead + stillborn
  final int lambsBornAlive;              // excludes stillborn
  final int lambsReared;                 // alive at season end
  final int ewesRecordedBarren;
  final int ewesDiedOrSoldBeforeLambing;
  final int ewesWithNoRecordedOutcome;
  const SeasonCounts({ /* all required */ });

  /// Hand-written value equality over every field. Without it the repository's
  /// `.distinct()` is a no-op that looks like a fix: `Stream.distinct()`
  /// compares with `==`, identity equality never matches, and every drift
  /// re-emit rebuilds the whole Season Summary.
  @override
  bool operator ==(Object o) =>
      o is SeasonCounts &&
      o.ewesPutToRam == ewesPutToRam &&
      o.ewesLambed == ewesLambed /* && ... every other field */;

  @override
  int get hashCode => Object.hash(ewesPutToRam, ewesLambed /* , ... */);
}
```

```dart
// lib/data/season_repository.dart — a SeasonRepository method. lib/data/ is flat
// and there is no SeasonStatsRepository: a repository that only reads is a query
// object wearing a repository's name (R18). The argument is a SeasonId, never a
// bare int (R33).
Stream<SeasonCounts> watchSeasonCounts(SeasonId season) => db
    .customSelect(
      '''
      SELECT
        (SELECT ewes_to_ram FROM seasons WHERE id = ?1)                       AS ewes_to_ram,
        COUNT(DISTINCT CASE WHEN lc.n > 0 THEN l.ewe END)                     AS ewes_lambed,
        COUNT(DISTINCT l.id)                                                  AS lambings_total,
        COUNT(DISTINCT CASE WHEN lc.n > 0 THEN l.id END)                      AS lambings_with_lambs,
        COUNT(DISTINCT CASE WHEN l.ease IS NOT NULL THEN l.id END)            AS lambings_scored,
        COUNT(DISTINCT CASE WHEN l.ease >= 2 THEN l.id END)                   AS lambings_scored_assisted
      FROM lambings l
      LEFT JOIN (SELECT lambing, COUNT(*) AS n FROM lambs GROUP BY lambing) lc
             ON lc.lambing = l.id
      WHERE l.season = ?1
      ''',
      variables: [Variable<int>(season.value)],
      readsFrom: {db.seasons, db.lambings, db.lambs},
    )
    .watch()
    .map(_toCounts)
    .distinct();
```

That statement produces the six lambing-derived counts. The five lamb-derived counts (`lambsBorn`, `lambsBornAlive`, `lambsReared`, and the two loss tallies) and the three ewe-outcome counts come from a second `customSelect` over `lambs` and `ewe_seasons` in the same repository method, combined in Dart before the record is built — **never** by `combineLatest` over two drift streams (decision #12: two streams updated in one transaction can emit at different times, and a torn Season Summary is a wrong headline number). One `watch()` per screen; if you need two statements, put both inside one `customSelect` with a `UNION ALL` or read the second one non-reactively inside the first's `map`.

`readsFrom:` is what makes the stream re-emit when any of those tables change; omit it and the Season Summary silently stops updating. `.distinct()` lives in the repository (decision #12) because drift streams re-run on any write to a *tracked table*, not only on a change to the result — and it only works if the mapped type has value equality, which is why `SeasonCounts` writes its own `==`.

### 6.4 Lambing percentage

```dart
StatResult lambingPercentage(SeasonCounts c, LambingPercentageChoice choice);
```

Numerator by `choice.definitionParts.count`; denominator by `.per`. `StatResult.definition` is `choice.definition` verbatim — never rebuilt from the parts at the call site, or two call sites will word it differently and §6.11 will refuse to compare two identical seasons.

| Edge case | Behaviour |
|---|---|
| `ewes_to_ram` not entered and `per == ewesPutToRam` | `StatResult.notComputable(reason: 'The number of ewes put to the ram has not been entered for this season.')`. **Never fall back to `ewesLambed`** — that silently changes the definition to a different published convention and reads high by however many ewes were barren, sold, died or were never entered (on the OMAFRA/AHDB worked contrast above, 14 points). **Never return 0.** |
| Denominator is 0 | `notComputable`. No division by zero, no `NaN` in a PDF. |
| More ewes lambed than were recorded as put to the ram | **Compute anyway** — over 100% is normal for this metric — and attach the caveat *"3 ewes have lambed but only 2 were recorded as put to the ram."* Warn, do not fix. |
| A ewe with no recorded outcome | Affects nothing in the numerator. She is inside `ewes_to_ram` if the shepherd entered that number, and she is named in a caveat: *"1 ewe has no recorded outcome."* |
| A lamb that died before it was tagged | **Counted, fully.** Lamb identity is the row id; `tag` is nullable at every layer. Anything else loses exactly the losses that matter most. |
| A fostered lamb | Counted **once**. Season-level counts are one row per lamb. Per-dam counts follow §6.8. |

### 6.5 Average litter size

```dart
StatResult averageLitterSize(SeasonCounts c);
```

**Always `lambsBorn ÷ ewesLambed`, always aggregated by birth dam. Not configurable** — "litter size" has one meaning, and offering a choice here invents a disagreement the industry does not have.

| Edge case | Behaviour |
|---|---|
| A lambing with **zero** attached lambs | Excluded from **both** sides, with coverage reported: *"2 lambings have no lambs recorded yet and are excluded."* A lambing always produces at least one lamb even if stillborn, so zero attached lambs always means "not recorded yet" — and because the lambing row is created on screen *entry* (decision #11), this state is common and transient. Including it would deflate the headline. |
| `ewesLambed == 0` | `notComputable`. |
| A fostered lamb | Counted in the **birth** dam's litter, never the receiving ewe's. |

### 6.6 Barren rate

```dart
StatResult barrenRate(SeasonCounts c);
```

> **Only ewes the user has explicitly marked barren are counted.** Absence of a lambing is never evidence of barrenness.

Numerator `ewesRecordedBarren`; denominator `ewesPutToRam`. The rejected alternative — `(ewesToRam − ewesLambed) / ewesToRam` — sweeps in ewes that died, were sold, aborted or were simply never entered. It is a silent inference (safety rule 4) about a commercially sensitive number (spec §4.5), and at 3am on night eleven the absence of data overwhelmingly means "not recorded yet".

| Edge case | Behaviour |
|---|---|
| `ewes_to_ram` not entered | `notComputable`. |
| Ewes with no recorded outcome | Not counted as barren. Caveat: *"4 ewes have no recorded outcome. They are not counted as barren."* |
| Ewes that died or were sold before lambing | Stay in the denominator (AHDB's denominator is ewes put to the tup) and are named in their own caveat. |

Model the outcome explicitly so this is a lookup, not an inference:

```dart
// lib/domain/stats/definitions.dart
/// A DERIVED four-way bucketing over `ewe_seasons.status`'s seven stored keys,
/// used only by the statistics functions. It never round-trips to the database
/// and it never replaces the stored keys, which stay canonical (R43):
///   lambed                   <- 'lambed'
///   recordedBarren           <- 'barren'
///   diedOrSoldBeforeLambing  <- 'died' | 'sold' | 'aborted'
///   notRecorded              <- 'to_ram' | 'scanned' | no row
enum EweSeasonOutcome { lambed, recordedBarren, diedOrSoldBeforeLambing, notRecorded }
```

### 6.7 Assisted rate

```dart
StatResult assistedRate(SeasonCounts c);
```

> **Denominator = lambings *with* an ease score. Both sides exclude unscored lambings. Coverage is always reported.**

Numerator = lambings with ease ≥ 2 (1 = no assistance). Sheep Genetics is explicit: *"a blank score indicates the lambing ease was not scored."* Treating blank as "1 — unassisted" deflates the rate and is exactly the silent inference safety rule 4 forbids.

| Edge case | Behaviour |
|---|---|
| No lambing has a score | `notComputable`, **not** `0%`. |
| Partial coverage | Caveat: *"1 of 3 lambings has no ease score and is excluded from both sides."* |
| Scale divergence | SRUC and Sheep Genetics record ease **per lamb**; the spec puts it on the `Lambing`. For a notebook that is right — per-lamb ease is pedigree recording and spec §13 excludes EBVs. Label the CSV column `lambing_ease_1_5` and make the definition string say *"per lambing"* so a future consumer is not misled. |

The 1–5 scale itself is spec §7.2 and **stays at five — ruled 2026-08-01, decision-record §7.0 row 15, with point 5 documented as covering elective caesarean.** `lambings.ease` is deliberately not a vocabulary foreign key, so widening the scale would be a migration somebody has to think about, and that friction is the feature. A blank ease is not "unassisted": it means not scored, and it is excluded from both sides of the assisted rate below. The shipped descriptions must be **paraphrased at the same semantic granularity**, not copied — decision-record §4 flags verbatim adoption of SRUC TN747 as a licensing and "written from scratch" problem, and the PDF's text could not be verified.

### 6.8 Losses by cause and by age

```dart
/// Stable keys, matching the CHECK on lambs.status.
enum LambStatus {
  alive('alive'), dead('dead'), stillborn('stillborn'), sold('sold');
  const LambStatus(this.key);
  final String key;
}

/// The plain record the domain takes. No drift row reaches this function.
typedef LambOutcome = ({
  int lambId,
  LambStatus status,
  LocalDate lambingDate,    // LocalDate.of(the lambing's effective instant)
  LocalDate? deathDate,     // day resolution; null even when status == dead
  String? causeKey,         // a vocab_terms key, or null = never categorised
});

enum AgeBucket { stillborn, sameDay, day1to3, day4to7, day8to30, over30, unknownAge }

({int total, Map<String, int> byCause, Map<AgeBucket, int> byAge, List<String> caveats})
    lossesBreakdown(List<LambOutcome> lambs);
```

**The bucket boundaries are chosen to match the published figures, not invented.** Teagasc's lamb-mortality breakdown — the numbers an Irish or UK shepherd has actually seen — splits at **day 1–3** and **day 4–7**, with *"the first three days after birth account for 74% of lamb mortality."* A `day1to2` / `day3to7` split straddles that boundary and makes the comparison impossible without arithmetic no one does at the kitchen table. `day8to30` and `over30` subdivide Teagasc's single ">day 7" band; summing them recovers it exactly.

| Edge case | Behaviour |
|---|---|
| Stillborn | **Its own bucket**, never "died at age 0". A stillborn lamb has no age at death, and folding it in double-counts against any "first 24 h losses" figure. |
| Died, no `death_date` | `unknownAge`, counted in the total. |
| Died, no cause | Counted in the total, tallied under **`unattributed`** — *not* under "unknown". "Unknown" is a cause the user can pick; "unattributed" is our word for a blank field. Never merge the two columns. |
| `death_date` before the lambing date | `unknownAge`, plus `WarningCode.deathBeforeBirth` on the record. |
| Died before tagging | Counted, fully. Identity is the row id. Keep a tagless dead lamb in the test fixtures. |
| A fostered lamb that died | Counted **once** at season level. On a ewe card there are two different numbers and they are labelled differently: *"lambs born to her that died"* (aggregated on `birth_dam`) and *"lambs lost while rearing"* (aggregated on the current rearing dam). Never one number. |

Age is computed from **civil dates**: `lambingDate.daysUntil(deathDate)` — 0 → `sameDay`, 1–3 → `day1to3`, 4–7 → `day4to7`, 8–30 → `day8to30`, >30 → `over30`, negative → `unknownAge` plus `deathBeforeBirth`. Because `death_date` has day resolution, the first bucket is labelled *"born and died the same day"*, **never** *"under 24 hours"* — Teagasc can split 0 h from <24 h because a research post-mortem has a death *time*; a civil `death_date` does not, and claiming it would be exactly the silent precision inflation safety rule 4 forbids.

Give `unattributed` a prominent row rather than hiding it. In a *studied* population Teagasc still records 19% of deaths as "diagnosis not reached" — a shepherd seeing a large unattributed share is seeing something real, not a personal failing.

A loss *rate* needs a denominator and must state it: lambs lost ÷ `LambCount.born`. Prefer counts; a rate here is easy to quote wrongly.

### 6.9 Lambing spread

```dart
({List<({LocalDate date, int dayIndex, int births, int ewes})> bars,
  int? ewesInFirstCycleDays,
  int cycleDays}) lambingSpread(List<DayBirths> rows, {int cycleDays = 17});
```

Four rules:

1. **Group by the denormalised `local_date`**, never by UTC and never by a SQL date function. A 00:05 lambing belongs to that day; a 23:55 one to the day before. Getting this wrong is a once-per-night off-by-one for a whole season.
2. **Dense and zero-filled.** A gap day renders as a zero bar rather than being skipped — the *gaps* are the information, because "was my tupping tight?" is a statement about gaps.
3. **Anchored on the first lambing** with a `dayIndex`, so §7.8's comparison against previous seasons overlays two curves that both start at day 0.
4. **Report "ewes lambed in the first 17 days."** The ewe oestrous cycle is about 17 days, so the share lambing within one cycle length is the direct single-number answer. Present it as a fact — *"32 of 48 ewes lambed in the first 17 days"* — never as a judgement. The number comes from `app_settings.cycle_days`, whose column default is 17; the `cycleDays = 17` in the signature above exists only so a unit test can omit it, and **the app always passes the settings value explicitly**. Two defaults that can drift apart is one too many — if you would rather not have the signature default at all, make the parameter `required` and delete it.

The SQL that feeds it, and the one place `GROUP BY` earns `customSelect`:

```dart
// lib/data/season_repository.dart — the second SeasonRepository read (R18, R33).
Stream<List<DayBirths>> watchSpread(SeasonId season) => db
    .customSelect(
      'SELECT l.local_date AS d, COUNT(lb.id) AS births, COUNT(DISTINCT l.ewe) AS ewes '
      'FROM lambings l LEFT JOIN lambs lb ON lb.lambing = l.id '
      'WHERE l.season = ?1 '
      'GROUP BY l.local_date ORDER BY l.local_date',
      variables: [Variable<int>(season.value)],
      readsFrom: {db.lambings, db.lambs},
    )
    .watch()
    .map((rows) => rows
        .map((r) => DayBirths(LocalDate.parse(r.read<String>('d')),
            r.read<int>('births'), r.read<int>('ewes')))
        .toList())
    .distinct(listEquals);   // package:flutter/foundation.dart — List has no value ==
```

`DayBirths` writes its own `==`/`hashCode` for the same reason `SeasonCounts` does, and the list needs `listEquals` on top: a bare `.distinct()` over a `List` compares list *identity* and filters nothing.

**Two `local_date` invariants.** It is derived from `RecordedTime.effective` and it is written by the *same repository method* that writes `effective`, in the same transaction — an edit to the time that leaves `local_date` stale moves a lambing to the wrong bar forever. Add `WarningCode.localDateDisagrees` to the consistency family in §7.5 so a stale value is surfaced, not silently repaired. And if the device zone changes between insert and read, **do not recompute historical rows**: `local_date` is a record of the shepherd's day as it was lived.

Edge cases: no lambings → `bars` empty, `ewesInFirstCycleDays` null, and the chart renders its named empty state (never a spinner, never a zero-height chart). Bar height is *lambs*; the first-cycle figure counts *ewes*; label both.

The chart itself is a hand-rolled `CustomPainter` with `semanticsBuilder` (decision #70) and lives in [`06-design-system.md`](06-design-system.md) / [`07-screens.md`](07-screens.md).

### 6.10 The fostering invariant that makes double-counting impossible

> **Every "born" count aggregates on `birth_dam`. Every "reared" count aggregates on the current rearing dam. The two are never mixed in one query.**

A lamb has exactly one birth dam, so `Σ litterSize(birthDam) == total lambs` by construction. A fostered lamb is never in the receiving ewe's litter size: her *reared* count goes up, her *born* count does not. `rearing_dam IS NULL` means artificially reared and belongs to *no* ewe's reared count — a third state, not a missing value. Death clears neither dam.

`birth_dam` is immutable, enforced by a SQL `BEFORE UPDATE` trigger and by a `final` field with no `copyWith` that accepts it (decision #33); the current rearing dam comes from a SQL **view** over append-only `FosterEvents`. That is [`03-data-model-and-schema.md`](03-data-model-and-schema.md)'s territory; the invariant is tested here:

```dart
test('STATS: fostering preserves litter counts', () async {
  final s = await loadFixture('test/fixtures/flock_400_3seasons.json');
  final byBirthDam = <int, int>{};
  for (final l in s.lambs) {
    byBirthDam.update(l.birthDamId, (n) => n + 1, ifAbsent: () => 1);
  }
  expect(byBirthDam.values.fold(0, (a, b) => a + b), s.lambsBorn);
});
```

### 6.11 Comparing seasons

Spec §7.8 asks for comparison against previous seasons. **Two `StatResult`s may only be compared when their `definition` strings are identical.** If the user changed the percentage definition between seasons, the comparison renders a named state — *"These seasons were measured differently"* plus both definitions — and no delta. A delta between two different definitions is the exact lie this whole section exists to prevent.

---

## 7. The five safety rules as structural mechanisms

Spec §12 says these "should be visible in the code review checklist". A checklist is the weakest available mechanism: it depends on a tired human at 11pm noticing an absence. The hierarchy applied here, strongest first: **unrepresentable** → **unconstructible** → **unpersistable** → **caught by a test on the source text** → **documented**.

### 7.1 The map

| Rule | Mechanism | Level | Proof |
|---|---|---|---|
| §12.1 never default a withdrawal | `sealed WithdrawalPeriod`, private ctor, no row = `NotRecorded` | unconstructible + unpersistable | schema-JSON assertion + widget test (§3.9) |
| §12.2 never give veterinary advice | the origination line + `ContentPolicy` scan with two-way self-tests | test on source text | §7.3 |
| §12.3 never a compliance record | `Disclaimers` const in one file, referenced never re-typed; `ExportEnvelope` has no disclaimer parameter | unconstructible | single-definition test + one golden per format (§7.4) |
| §12.4 never silently correct | `Warning` / `Reviewed<T>` with no writer, no `warnings` column, `lib/data` cannot import `lib/domain/validation` | unrepresentable + unpersistable | §7.5 |
| §12.5 timestamps are honest | `RecordedTime` + the paired `CHECK` | unrepresentable | §4.4 |

### 7.2 Rule 1 — never default a withdrawal period — see §3

### 7.3 Rule 2 — never give veterinary advice

The ambiguity dissolves once you draw the line at **who supplied the number**:

> **The app may arithmetic-transform a number the user supplied. The app may never originate a number that is a clinical decision.**

| Allowed — arithmetic on user data | Forbidden — origination |
|---|---|
| Counting down N days from the N *the user typed* | Suggesting N for a named product |
| "She has been penned 26 hours" | "Ready to turn out" as a clinical claim |
| Average litter size across her recorded seasons | "This ewe should be culled" |
| "4.1 kg" from grams the user weighed | "That is light for a twin" |
| Losses by cause, exactly as the user categorised them | "These losses indicate a nutritional deficiency" |
| The colostrum volume the user recorded | "She needs 215 ml of colostrum" |

That last row is not hypothetical. AHDB publishes *"Make sure lambs receive 50 ml/kg of colostrum within the first four to six hours of life"*; the app holds the birthweight; multiplying is one line and would be *helpful*. It is a dose suggestion and it is banned. Likewise AHDB's *"Birth weights more than 1 kg lighter than these suggest undernutrition of the ewe during late pregnancy"* — the app has the birthweight and the birth type and could render that sentence. It must not.

Note the subtlety in row two: the pen board's badge is fine **because the threshold is user-set**. It is the user's own rule played back, and the label must say so — *"past your 24 h threshold"*, never *"ready"*.

```dart
// lib/domain/policy/content_policy.dart
abstract final class ContentPolicy {
  static final List<({RegExp pattern, String why})> bannedInUserFacingText = [
    (pattern: RegExp(r'\byou should\b', caseSensitive: false), why: 'imperative clinical advice'),
    (pattern: RegExp(r'\b(we|the app) recommends?\b', caseSensitive: false), why: 'app asserting judgement'),
    (pattern: RegExp(r'\brecommended (dose|dosage|amount|rate)\b', caseSensitive: false), why: 'dose suggestion'),
    (pattern: RegExp(r'\b\d+\s?(ml|mg|cc|iu)\s?/\s?kg\b', caseSensitive: false), why: 'a computed dose'),
    (pattern: RegExp(r'\bdiagnos(?!tic)|\bprognos', caseSensitive: false), why: 'diagnosis'),
    (pattern: RegExp(r'\b(indicates?|suggests?) (a |an )?(problem|deficiency|infection|disease)\b',
        caseSensitive: false), why: 'clinical inference from data'),
    (pattern: RegExp(r'\b(normal|healthy|abnormal|too (low|high|light|heavy))\b',
        caseSensitive: false), why: 'clinical judgement on a user value'),
    (pattern: RegExp(r'\bcall (the |your )?vet\b', caseSensitive: false), why: 'instruction, even a safe-sounding one'),
    (pattern: RegExp(r'\b(default|typical|usual|standard) withdrawal\b', caseSensitive: false),
        why: 'implies the app knows a withdrawal period'),
    (pattern: RegExp(r'\b(compliance|regulatory|statutory|official) record\b', caseSensitive: false),
        why: 'safety rule 3'),
  ];

  /// Reviewed exceptions. Keys REFERENCE the single definition; re-typing the
  /// string here breaks the "defined in exactly one place" guard (§7.4).
  static final Map<String, String> allowlist = {
    Disclaimers.exportFooter: 'This is the disclaimer itself (safety rule 3).',
  };
}
```

`call the vet` is banned deliberately: it *sounds* like the safe thing to say and it is still the app making a clinical call about a specific animal at a specific moment.

**Amended 2026-08-01 (N08-T07): `\bdiagnos` gained a `(?!tic)`.** As first printed, the alternative
was `\b(diagnos|prognos)`, and it refused this project's **own mandated vocabulary**. Measured against
the gate before the change: the string literal `'the diagnostics log'` — `CLAUDE.md`'s required word
for `LocalLog` — was a violation, and so was an ARB message reading `"Diagnostics"`, which decision
**#123** requires (*"Settings ▸ Diagnostics shows the last 20 events"*) and which `04 §8.2` also needs
for its temp directory. Three documents mandate the word; one alternative refused it.

The alternative means **clinical** diagnosis, and every dangerous form still fires — *diagnosis*,
*diagnose*, *diagnosed*, *diagnosing*. `diagnostic`/`diagnostics` is a different word in a different
domain. `prognos` is unchanged, because no collision exists for it.

This was ruled rather than exempted on purpose. An `[exempt]` line was unavailable (**R56** fixes the
allowlist at four lines) and an `except:` path in the rule would have excused one file while leaving
the collision waiting for N29's Settings screen — which is precisely how a rule with a standing false
positive gets weakened and then deleted, while guarding safety rule §12.2.

The scan covers string literals in `lib/**.dart` and message values in `lib/l10n/*.arb`, and it is **self-tested in both directions** — a guard that never fires is indistinguishable from a broken guard:

```dart
test('rule 2 guard catches planted offenders', () {
  const offenders = [
    'You should give 2 ml/kg of colostrum.',
    'A low birth weight indicates a problem with ewe nutrition.',
    'Default withdrawal for this product is 28 days.',
    'This is your official record for compliance.',
  ];
  for (final o in offenders) {
    expect(ContentPolicy.bannedInUserFacingText.any((r) => r.pattern.hasMatch(o)), isTrue, reason: o);
  }
});

test('rule 2 guard does not reject legitimate app copy', () {
  const ok = [
    'Birth type is twin but 3 lambs are recorded.',
    'Withdrawal period as entered by you from the product label.',
    '412 · 3 seasons · avg 2.0 · assisted twice',
    'Clear on 11 Mar. Period ends 10 Mar 20:00.',
    'Recorded automatically at 03:21.',
  ];
  for (final s in ok) {
    expect(ContentPolicy.bannedInUserFacingText.where((r) => r.pattern.hasMatch(s)), isEmpty, reason: s);
  }
});
```

**The gotcha that will bite you.** A naive `file.contains('some long phrase')` source scan **misses long strings**, because Dart wraps them across adjacent string literals and the phrase is never contiguous in the source text. The scanner must extract string literals and join them before matching. This defect was found while the research was being written, not theorised.

The other half of rule 2 is the bundled content. Death causes are a **vocabulary the user picks from** — that is fine; it becomes advice the moment the app infers one. **Never pre-select a cause from age-at-death or birthweight**, and never seed a `DEFAULT` on any column that could encode a clinical value (decision #31).

### 7.4 Rule 3 — never a compliance record

```dart
// lib/domain/policy/disclaimers.dart
/// The ONLY place these strings exist. Not in the ARB — a translator can drop
/// or soften an ARB string and the app has no mechanism to notice.
/// `abstract final` cannot be instantiated OR extended, so nobody can subclass
/// it and shadow a string.
abstract final class Disclaimers {
  static const String exportFooter =
      'Shed Book is a personal notebook. It is not a statutory medicine '
      'record, holding register, or movement record, and must not be '
      'presented as one. All entries are as recorded by the user.';

  static const String withdrawalProvenance = 'as entered by you';

  static const String withdrawalCaveat =
      'Withdrawal period as entered by you from the product label. '
      'Shed Book does not know any product and suggests no value. '
      'Check the label.';
}
```

The mechanism is not "remember to append the footer" — it is that **the writer cannot be constructed without it**:

```dart
// lib/domain/policy/export_envelope.dart (R65). The JSON backup's header block
// is a different thing with a different name — `BackupHeader`, 04's and 09's.
final class ExportEnvelope {
  final String disclaimer;
  final Instant generatedAt;
  final String appVersion;
  const ExportEnvelope._(this.disclaimer, this.generatedAt, this.appVersion);

  /// The only constructor. `disclaimer` is not a parameter.
  factory ExportEnvelope.standard({required Instant now, required String appVersion}) =>
      ExportEnvelope._(Disclaimers.exportFooter, now, appVersion);
}
```

Every writer signature takes an `ExportEnvelope`; there is no writer that does not. Placement per format, and one golden test per format asserting the produced bytes contain it: CSV → a final row `# <disclaimer>` in the first field; PDF flock book → a footer on **every** page; medicine-record PDF → footer **plus** a boxed statement under the title, because that is the one somebody hands to an inspector; JSON backup → a top-level `"_disclaimer"` key, first. The Export screen carries a one-liner above the buttons.

```dart
test('SAFETY RULE 3: the disclaimer exists in exactly one file', () {
  final hits = dartFilesUnder('lib/')
      .where((f) => joinedStringLiterals(f).contains(RegExp(r'statutory\s+medicine|holding\s+register')))
      .toList();
  expect(hits, ['lib/domain/policy/disclaimers.dart']);
});
```

This test caught a real duplication while the research was being written: the banned-phrase allowlist had re-typed the disclaimer. The fix — make the allowlist key `Disclaimers.exportFooter` rather than a literal — is also the correct design, and it is what §7.3 now does.

### 7.5 Rule 4 — never silently correct a user's entry

```dart
// lib/domain/validation/warning.dart
/// Advisory only. No fix(), no `corrected` field, no apply(). A Warning cannot
/// mutate anything because it holds nothing mutable and exposes no writer.
final class Warning {
  final WarningCode code;
  final String message;     // what we OBSERVED, never what to do
  final String? fieldPath;  // for scroll-to-field, not for editing
  const Warning(this.code, this.message, {this.fieldPath});
}

enum WarningCode {
  birthTypeLambCountMismatch,
  lambingBeforeSeasonStart,
  lambingInFuture,
  lambingLongBeforeCapture,
  implausibleBirthWeight,
  timeDoesNotExistLocally,
  fosterToSelf,
  deathBeforeBirth,
  duplicateActiveTag,
  clearDateDisagrees,
  localDateDisagrees,
}

/// A value that has been looked at by the validator. Carries the UNCHANGED
/// value plus advisories. There is deliberately no way to get a "cleaned"
/// value out of it.
final class Reviewed<T> {
  final T value;                 // byte-identical to what the user supplied
  final List<Warning> warnings;
  const Reviewed(this.value, this.warnings);
  bool get hasWarnings => warnings.isNotEmpty;
}
```

Read the negative space. `Warning` has no reference to a repository, no `T corrected`, no callback. `Reviewed<T>` has no `T get cleaned`. The API surface for mutation does not exist, so no amount of call-site carelessness produces one.

**Four structural guarantees.**

1. **Validators are pure top-level functions** taking plain data and returning `List<Warning>`. No repository, no `Ref`, no `AppDatabase` — they *cannot* write because they hold no writer. **The entry points, named here so no other document has to invent one:** `List<Warning> checkLambing(Lambing lambing, List<Lamb> lambs)` in `lambing_checks.dart`, `List<Warning> checkFoster(...)` in `foster_checks.dart`, `List<Warning> checkTreatment(...)` in `treatment_checks.dart`, alongside the two already printed above — `checkClearDate({…})` (§3.8) and `checkLocalWallTimeExists(…)` (§7.6). The shape is fixed: `check<Thing>` → `List<Warning>`, one per file, no class, no `Validator` suffix. `12-testing.md` §10.4 calls `checkLambing` and is now calling a named function rather than a placeholder.
2. **The schema has no `warnings` column.** Warnings are recomputed on read. A derived value that is never persisted can never diverge from its source and can never be mistaken for user data on export. A schema test asserts no entity table has such a column.
3. **Warnings never gate the save.** The save button is always live. This is a 3am requirement (spec §5: every write is committed immediately) *and* a correctness one: a blocked save produces a lost record, which is worse than a flagged one.
4. **`lib/data/**` has no import path to `lib/domain/validation/**`.** The code that could write has no reference to the code that judges.

**The consequence for the write path (R53).** Guarantee 4 makes it structurally impossible for a repository to produce a `Warning`, so repositories always return `WriteCommitted(insertedId: …)` with the default empty `warnings`. The **controller** runs these validators against the freshly-watched row and passes the resulting `List<Warning>` to `confirmSaved`. The field stays on `WriteCommitted` — non-generic, `insertedId` and `warnings`, [`01-architecture.md`](01-architecture.md)'s definition — so the two travel together through `WriteDone` and `ref.listen`. `lib/core/write_outcome.dart` importing `lib/domain/validation/warning.dart` is legal: core may import domain, and `lib/domain/validation/` is banned only to `lib/data/`.

**The catalogue.**

| Code | Trigger | Message |
|---|---|---|
| `birthTypeLambCountMismatch` | expected count ≠ attached count, and expected is not open-ended | "Birth type is twin but 3 lambs are recorded." |
| `lambingInFuture` | `effective > now + 2 min` | "This time is in the future." |
| `lambingBeforeSeasonStart` | `LocalDate.of(effective) < seasonStart` | "This is before the season start (2026-03-01)." |
| `lambingLongBeforeCapture` | `capturedAt − effective > 3 d` | "Recorded more than 3 days after the time entered." |
| `timeDoesNotExistLocally` | round-tripping the typed wall time changes it | "The clock skipped 01:30 that night (clocks went forward). Saved as 02:30." |
| `implausibleBirthWeight` | `< Grams(1000)` or `> Grams(10000)` (§5.4) | "0.4 kg is outside the usual range for a lamb." |
| `deathBeforeBirth` | `death_date` < lambing local date | "The death date is before the lambing." |
| `duplicateActiveTag` | tag matches another **active** animal (owner ruling: unique among active only) | "412 is already in use by an active ewe." |
| `fosterToSelf` | target == current rearing dam | "That lamb is already on this ewe." |
| `clearDateDisagrees` | stored clear date ≠ recomputed | §3.8 |
| `localDateDisagrees` | stored `local_date` ≠ `LocalDate.of(effective)` | §6.9 |

Note `duplicateActiveTag`. The owner settled tag uniqueness as **unique among ACTIVE animals only** — a partial unique index. A culled 412 releases the tag; a new 412 is a new row with its own identity and its own history. Create-on-the-fly therefore matches against **active** animals only, and the disambiguation prompt ("there was an earlier 412") moves off the 3am entry path onto the ewe card.

Two details worth their line:

```dart
// lib/domain/birth_type.dart — this file holds `enum BirthType` (with `final int
// code` 1..5, 03's stored codes) AND this top-level function (R46).
/// null for quintPlus is load-bearing: "quad or more" is open-ended, so a
/// contradiction is UNDEFINED, not false. Encoding it as 5 would produce a
/// false warning for every set of sextuplets.
int? expectedLambCount(BirthType t) => switch (t) {
      BirthType.single    => 1,
      BirthType.twin      => 2,
      BirthType.triplet   => 3,
      BirthType.quad      => 4,
      BirthType.quintPlus => null,
    };
```

```dart
/// Did the wall-clock time the user typed actually exist in the device zone?
/// Dart moves a nonexistent local time forward with no exception — that is
/// Dart correcting the user, so we surface it.
List<Warning> checkLocalWallTimeExists(int y, int mo, int d, int h, int mi) {
  final built = DateTime(y, mo, d, h, mi);
  if (built.hour == h && built.minute == mi && built.day == d) return const [];
  return [
    Warning(WarningCode.timeDoesNotExistLocally,
        'The clock skipped ${_hhmm(h, mi)} that night (clocks went forward). '
        'Saved as ${_hhmm(built.hour, built.minute)}.',
        fieldPath: 'time'),
  ];
}
```

The **ambiguous** hour is deliberately not warned about: the displayed time still matches what the user typed, so nothing is silently corrected from their point of view, and the 60 minutes of ambiguity are unambiguous in the exported UTC column anyway.

**How it surfaces at 3am.** ~~A persistent, tappable **60 pt amber strip under the field**~~ — **AMENDED
2026-08-02 (N16-T06): a persistent, tappable query mark `?` in the margin plus a 2 px madder underline
under the offending cell.** `indelible.md §2.2`/`§6.2` own the mark and the system has no status
palette; `CLAUDE.md`'s authority order puts the design system above this document. The rest of this
paragraph is unchanged and still binding. The struck original read: a **60 pt amber strip under the
field** — not a modal, not a red border alone. Tapping it scrolls to the field. It reappears every time the record is opened, because the record is still contradictory. It never blocks, never auto-dismisses, and never appears twice for one field. On the ewe card and the flock list, a small persistent badge, so a contradiction found at 3am is still findable at 9am. In the CSV, a `has_warnings` boolean and a `warnings` column of joined **codes** — codes, not localised messages — so the export tells the truth about the data's condition without claiming to have fixed anything.

**The `normalize*` scope (decision #55).** The ban is on functions that **return a corrected domain value**. Projections are fine: `tag_digits` stored alongside `tag` is not a violation, because the typed value is preserved verbatim and the projection is only ever used to drive the keypad filter. Never show `tag_digits` to a user.

### 7.6 Rule 5 — see §4

---

## 8. Terminology

> Spec §7.10: *"Terminology: ewe / gimmer / shearling / theave / hogget — editable labels, because these vary by county, let alone by country."*

These words are **not synonyms and not a clean taxonomy**. The National Sheep Association's own glossary defines *gimmer* by age plus parity, *shearling* by **dentition**, *hogget* by age (and overloads it with a meat term), and *teg* as two years old — while other regions use *teg* for a sheep in its second year. Three different measuring sticks for overlapping classes, with regional disagreement inside one national body's glossary. There is no canonical taxonomy to normalise to, which kills both naive designs ("one enum, translate it" and "free text, no enum") and leaves exactly one shape.

### 8.1 The shape

```dart
// lib/domain/terminology/animal_class.dart
/// The DOMAIN concept. These keys go into the database, the CSV and the JSON
/// backup, and they never change — not on a rename, not on a translation.
enum AnimalClass {
  ewe,           // adult female that has lambed
  maidenFemale,  // gimmer / theave / shearling ewe / hogg — regional
  eweLamb,
  ram,
  ramLamb,
  wether,
  lamb,          // sex unknown / not yet sexed
}
```

`maidenFemale` is deliberately a neutral, unlovely name that belongs to no county, so the default English label (`gimmer`), a Yorkshire user's override (`theave`) and a future translator's word are all equal citizens over one stable key. Naming the key `gimmer` would privilege one dialect in the data format forever.

```dart
final class TermLabel {
  final String singular, plural;
  const TermLabel(this.singular, this.plural);
}

/// Resolution order: user override -> localised default. Never empty.
final class Terminology {
  final Map<AnimalClass, TermLabel> _defaults;   // supplied by the settings bootstrap
  final Map<AnimalClass, TermLabel> _overrides;  // from TerminologyOverrides
  const Terminology(this._defaults, this._overrides);

  TermLabel labelFor(AnimalClass c) {
    final o = _overrides[c];
    if (o != null && o.singular.trim().isNotEmpty && o.plural.trim().isNotEmpty) return o;
    return _defaults[c]!;   // a missing default is a programming error, not a runtime state
  }
}
```

Storage is a `TerminologyOverrides` table ([`03-data-model-and-schema.md`](03-data-model-and-schema.md)). **Seeding the defaults happens in `lib/features/settings/terminology_bootstrap.dart`**, which already has a `BuildContext` — never in `domain/` or `data/`, both of which are forbidden from importing `AppLocalizations` by the layer rules. A locale change or an app update never overwrites a user's override.

### 8.2 Coexisting with the string catalogue without breaking plurals

> **Never bake a domain noun into an ICU message. Pass it in as a `String` placeholder and let ICU choose only the plural *category*.**

```jsonc
// lib/l10n/app_en.arb — the SENTENCE lives here; the NOUN does not.
"nAnimals": "{count, plural, =0{No {pluralTerm}} =1{1 {singularTerm}} other{{count} {pluralTerm}}}",
"@nAnimals": {
  "placeholders": {
    "count":        { "type": "num" },
    "singularTerm": { "type": "String", "example": "ewe" },
    "pluralTerm":   { "type": "String", "example": "ewes" }
  }
},

// The DEFAULT labels also live in the ARB, so a translator gets a baseline:
"termEweSingular": "ewe",
"termEwePlural": "ewes",
"termMaidenFemaleSingular": "gimmer",
"termMaidenFemalePlural": "gimmers"
// ... one pair per AnimalClass
```

The placeholders are `singularTerm` / `pluralTerm`, never `singular` / `plural`: `plural` is an ICU **keyword**, and a placeholder that shadows a keyword inside a plural expression is the kind of thing that parses today and stops parsing on the next `gen-l10n` release. `"type": "num"` on `count` is what Flutter's own plural example uses.

```dart
final l = terminology.labelFor(AnimalClass.ewe);
Text(AppLocalizations.of(context)
    .nAnimals(count: count, singularTerm: l.singular, pluralTerm: l.plural));
```

Named arguments, not positional: decision #108 sets `use-named-parameters: true`, so the generated signature takes named parameters and the positional spelling does not compile. `nullable-getter: false` is why there is no `!` after `.of(context)`.

The ICU engine picks `=0 / =1 / other` for the locale; the noun is substituted from the user's map. Renaming *ewe* → *yow* therefore cannot break pluralisation, because pluralisation never knew the word.

**The honest limitation:** this supplies two noun forms and works cleanly for languages with two plural categories. Locales with `few`/`many` (Polish, Russian, Irish) would need three or four. For v1 — English only, decision #108 — it is correct; adding `TermLabel.few`/`.many` later is an additive change to the record and to the ARB. **Never derive a plural by appending "s"** — the user is already typing one word, and guessing is safety rule 4 again.

### 8.3 Export headers — the rule that saves the backup

| Artifact | Uses | Why |
|---|---|---|
| **CSV header row** | **stable English keys** (`ewe_tag`, `birth_type`, `withdrawal_days_as_entered`, `animal_class`) | A header that changes when a user renames a label breaks every spreadsheet, script and re-import. Machine columns are a contract. |
| **CSV `animal_class` values** | **enum keys** (`maidenFemale`) | Same reason, and it keeps the JSON backup and the CSV in agreement. |
| **PDF flock book** | the **user's** labels | It is for reading, by the person who chose the words. |
| **JSON backup** | enum keys **plus a top-level `"terminology"` block** with the override map | A restore reproduces the shepherd's vocabulary exactly. Without the block, a restore silently reverts their labels — safety rule 4 at the backup layer. |

The same rule governs every other stable key in the app: `time_source` (`auto`/`entered`/`edited`), `WithdrawalTarget` (`meat`/`milk`), `LambCount`, `FlockDenominator`, death causes, care-event kinds. **A user-editable label never becomes a machine value.** A golden test on each CSV header row pins this.

### 8.4 Validation: reject, do not sanitise

```dart
TermOverrideResult validateOverride(String singular, String plural) {
  final s = singular.trim(), p = plural.trim();
  if (s.isEmpty || p.isEmpty) {
    return const TermOverrideRejected('Both the singular and the plural are needed.');
  }
  if (s.length > 24 || p.length > 24) {
    return const TermOverrideRejected(
        '24 characters maximum, so it still fits the buttons at arm’s length.');
  }
  final bad = RegExp(r'[\n\r\t,"]');
  if (bad.hasMatch(s) || bad.hasMatch(p)) {
    return const TermOverrideRejected('No commas, quotes or line breaks.');
  }
  return TermOverrideAccepted(TermLabel(s, p));
}
```

Stripping the comma silently would be a silent correction; rejecting with a reason is not. Trimming surrounding whitespace is the one accepted exception — invisible, universally expected, and it cannot change meaning. The 24-character cap is a **3am** constraint, not a database one: a label that overflows a 60 pt button under a head torch is a defect.

**Renaming is never a setup step.** Defaults ship, Settings is optional, and spec §5's "no onboarding after first run" holds.

---

## 9. The consolidated anti-pattern list

Every row is a defect, not a preference. The "caught by" column tells you whether a human has to notice.

| # | Banned | Caught by |
|---|---|---|
| 1 | `DateTime.now()` outside `lib/core/time/app_clock.dart` | `check_policy` rule `time.dart_clock` + its one exemption |
| 2 | A second clock abstraction (`abstract class Clock`, `clockProvider`) | review; there is nothing to grep for |
| 3 | `import 'package:clock/…'` inside `lib/domain/**` | `check_policy` `_bannedPackages['lib/domain/']` (§2.8) |
| 4 | `CURRENT_TIMESTAMP` / `CURRENT_DATE` / `CURRENT_TIME` / `date('now')` / `datetime('now')` | `check_policy` rules `time.sql_now_1`–`time.sql_now_5` |
| 5 | drift `dateTime()` columns; `store_date_time_values_as_text` | codegen-freshness CI + schema review |
| 6 | Civil-day arithmetic anywhere near a withdrawal or an elapsed-time readout | DST-4/DST-5 tests |
| 7 | `?? 0` on a nullable aggregate in `season/` or `flock/` | `check_policy` + code-review checklist |
| 8 | A default, `clientDefault` or fallback on `treatment_withdrawals.days` | schema-JSON assertion (gate 1) |
| 9 | A countdown widget accepting `WithdrawalStatus` instead of `ClearsOn` | the type |
| 10 | A medicines/product lookup table of any kind, **including one learned from the user's own history** | review; decision-record §5.3, NADIS (§3.10) |
| 10a | Repeat-last-treatment carrying the withdrawal across | widget test: second identical treatment saves with no withdrawal row (§3.10) |
| 10b | Converting milkings to days anywhere | review; the type cannot express it (§3.2) |
| 10c | A countdown or clear date shown for a soft-voided treatment | every withdrawal query filters `voided_at IS NULL` (§3.10) |
| 11 | A `unit` column on a measurement | schema test |
| 12 | An extension type for a display unit (`Pounds`, `Fahrenheit`) | review; they erase to the same runtime type |
| 13 | `toInt()` in a unit conversion | boundary test at `x.5` |
| 14 | `double` or `decimal`/`fixed` for a measurement | review; decision-record §5.3 |
| 15 | Guessing a decimal separator | `parseUserNumber` returns null |
| 16 | A `warnings` column, a `fix()` method, an `Either<Corrected, List<Warning>>` | schema test + the type has no writer |
| 17 | `lib/data/**` importing `lib/domain/validation/**` | layer rule in `check_policy` |
| 18 | Blocking a save on a warning | widget test per entry screen |
| 19 | Inferring barren from missing lambings; blank ease read as "unassisted" | stats unit tests |
| 20 | Falling back to `ewesLambed` when `ewes_to_ram` is blank | stats unit test |
| 21 | A bare percentage without its `definition` string | `StatResult` has no constructor without it |
| 22 | `groupBy` inside a Dart-defined drift `View` | review; use `customSelect` + `readsFrom:` |
| 23 | Grouping the spread by UTC or by a SQL date function | 23:55 / 00:05 fixture test |
| 24 | User labels in CSV headers or in `animal_class` values | golden test on the header row |
| 25 | A domain noun baked into an ICU message; an ARB placeholder named `plural` or `singular` | ARB review + the rename test |
| 26 | Re-typing a disclaimer string | single-definition test |
| 27 | `normalize*` returning a corrected domain value | review; projections like `tag_digits` are fine |
| 28 | Skipping (rather than failing) a DST test in the wrong zone | `setUpAll` assertion |

---

## Definition of done

Tick every line before you call this area finished.

**Time**
- [ ] `Instant`, `LocalDate` and `PartialDate` exist, with the converters, and `dart analyze` is clean on the `LocalDate._` spelling (§2.4).
- [ ] Every time-carrying column in the schema appears in the §2.2 table and uses `integer()` or `text()` — no `dateTime()` anywhere, `store_date_time_values_as_text` unset.
- [ ] `lib/core/time/app_clock.dart` is the only file matching `DateTime.now(`, and `check_policy` rule `time.dart_clock` proves it.
- [ ] No SQL-side time function anywhere in `lib/`, `.dart` or `.drift`; the `time.sql_now_*` scan is case-insensitive and covers `.drift`.
- [ ] `'package:clock/'` is in `check_policy`'s `_bannedPackages['lib/domain/']`, and `01-architecture.md` rule 1 no longer lists `clock` as importable from `lib/domain/`.
- [ ] `appNow()`, `Instant.fromDateTime` and `RecordedTime.capture` are the spellings used in every document in the set (§1.1).
- [ ] Tests DST-1 to DST-5 exist, are tagged `uk-zone`, fail loudly outside `Europe/London`, and pass.
- [ ] CI runs the domain suite under both `TZ=Europe/London` and `TZ=Pacific/Chatham`.

**Withdrawal**
- [ ] `WithdrawalPeriod` is sealed with a private generative constructor and one entry point; `WithdrawalDays.asEnteredByUser` throws on negative and implausible values.
- [ ] `treatment_withdrawals` exists with no default on `days`, the paired `CHECK`s, and `UNIQUE (treatment, target)`; absence of a row means `NotRecorded`.
- [ ] `clearDateFor()` is the only place a clear date is computed, and it is called exactly once per row inside the write transaction.
- [ ] The zero-day case is tested and yields *tomorrow*.
- [ ] `checkClearDate` exists, is displayed, and nothing applies it.
- [ ] Both §3.9 gates pass: the schema-JSON assertion (`defaultValue` and `clientDefault` keys confirmed against the committed `drift_schemas/drift_schema_v1.json`) and the untouched-field widget test.
- [ ] The clear-date UI shows the date **and** the arithmetic, plus `Disclaimers.withdrawalProvenance`.
- [ ] Repeat-last-treatment copies product, dose, route and batch and leaves the withdrawal empty — proved by a widget test, with the NADIS reason commented at the copy site.
- [ ] No learned or remembered withdrawal value exists anywhere, for any product.
- [ ] Nothing converts milkings to days; a milkings-only label saves as `NotRecorded` with the number in the treatment note.
- [ ] Every withdrawal query filters `voided_at IS NULL`, and no void path deletes, blanks or recomputes a stored `clear_date`.

**Provenance**
- [ ] `RecordedTime` is used by every entity carrying a user-facing event time, with all four columns and the paired `CHECK`.
- [ ] `TimeSource` keys are frozen by a test.
- [ ] Editing preserves `originalEffective` across a chain of edits; `capturedAt` never moves.
- [ ] Every export shape carries the five provenance columns; the PDF carries the dagger and its legend.

**Units**
- [ ] `Grams` and `MilliCelsius` are non-transparent extension types; no display-unit type exists; no `unit` column exists.
- [ ] The 241-value lb round trip, the 201-value °F round trip and the 132-failure counterexample test all pass.
- [ ] Weight entry uses the in-app keypad; `parseUserNumber` rejects ambiguity.
- [ ] The plausibility band is one named constant — `kPlausibleBirthWeight` at `Grams(1000)`–`Grams(10000)` — warns only outside it, and is marked provisional against open question 12.
- [ ] `weight_unit` defaults to `kg` and `temperature_unit` to `c`; no human-facing date is all-numeric.
- [x] No temperature column exists, and none will — ruled 2026-08-01 (§7.0 row 11). `app_settings.temperature_unit` is dropped with it. `MilliCelsius` still ships.

**Statistics**
- [ ] Every statistic is a pure top-level function returning `StatResult`; none returns a bare `double`.
- [ ] `LambingPercentageChoice` has exactly four members; their `key`s equal the four strings in `app_settings.percentage_definition`'s `CHECK`, proved by a test against the committed schema JSON, and their `definition` strings are pinned literally.
- [ ] Aggregates use `customSelect` with an explicit `readsFrom:`; no `groupBy` in a Dart-defined view; no `combineLatest` over two drift streams.
- [ ] Every edge case in §6.4–§6.9 has a named test, including: no `ewes_to_ram`, denominator 0, more lambed than to the ram, a lambing with no lambs, a ewe with no outcome, a tagless dead lamb, a stillborn, a death with no cause, a death before the lambing, a fostered lamb, 23:55 and 00:05 lambings, and a season with no lambings.
- [ ] `AgeBucket` splits at day 3 and day 7 so the summary reads directly against the Teagasc figures.
- [ ] The domain-level fostering conservation test ("STATS: fostering preserves litter counts") passes on `test/fixtures/flock_400_3seasons.json`, alongside `test/data/fostering_conservation_test.dart`.
- [ ] Season comparison refuses to subtract two different definitions.

**Safety rules**
- [ ] The §7.1 table's five mechanisms all exist, with their proofs.
- [ ] The rule-2 guard has both self-tests and its scanner joins adjacent string literals.
- [ ] `Disclaimers` is referenced, never re-typed, and the single-definition test names the file.
- [ ] No entity table has a `warnings` column; `lib/data` cannot reach `lib/domain/validation`.
- [ ] Every entry screen saves with warnings present.

**Terminology**
- [ ] `AnimalClass` keys appear in the DB, CSV and JSON; user labels appear only in the UI and the PDF.
- [ ] No domain noun is literal in any ARB message, and no placeholder is named `plural` or `singular`.
- [ ] Every generated `AppLocalizations` call site uses named arguments (`use-named-parameters: true`).
- [ ] The rename test proves pluralisation survives an arbitrary override.
- [ ] The JSON backup carries the `"terminology"` block and round-trips it.
- [ ] Seeding lives in `lib/features/settings/`, not in `domain/` or `data/`.

---

## References

Only the sources this document cites.

**Decision record and spec (this repository)**
- [`../research/00-tech-decisions.md`](../research/00-tech-decisions.md) — the canonical decision record. §2E, §5, §6, §7.0, §7.1.
- [`../../shed-book-spec.md`](../../shed-book-spec.md) — §5, §7.2, §7.3, §7.5, §7.8, §7.10, §10, §11, §12.

**Medicine withdrawal periods**
- VICH, *Report on calculation of withdrawal periods* (August 2020) — the definition, and "rounded up to the next full day or milking". https://vichsec.org/wp-content/uploads/2024/10/Report%20on%20calculation%20of%20withdrawal%20periods%20-final%20August%202020.pdf
- EMA/CVMP/SWP/735418/2012 Rev. 1, *Guideline on determination of withdrawal periods for milk*, §4.1.1–§4.1.2 — "milk from the first milking **at or after** 108 hours is considered safe"; "the final unit of the milk withdrawal period should be real time". The strongest citation for the absolute-time model (§3.7) and for requiring a user-supplied milking interval (§3.2). https://www.ema.europa.eu/en/documents/scientific-guideline/adopted-guideline-determination-withdrawal-periods-milk-revision-1_en.pdf
- NADIS, *Cattle — Medicine Usage* — the period runs from the last dose. https://www.nadis.org.uk/disease-a-z/cattle/medicine-usage/
- NADIS, *Sheep — Medicine Usage* — withdrawal periods "can change for the same medicine and differ between products with the same active ingredient". The basis for §3.10's repeat-treatment and no-learned-default rules. https://www.nadis.org.uk/disease-a-z/sheep/medicine-usage/
- Fimea, *What is a withdrawal period?* https://fimea.fi/en/veterinary/withdrawal_period_and_mrl/what_is_a_withdrawal_period

**Agricultural definitions**
- AHDB, *Reducing Lamb Losses for Better Returns* — the five KPI formulas (p.5) and birthweight ranges (p.16). https://projectblue.blob.core.windows.net/media/Default/About%20AHDB/Reducing%20Lamb%20Losses%202020.pdf
- Penn State Extension, *Does Your Flock Meet Your Performance Expectations?* — per-ewe-exposed as "the more accurate method". https://extension.psu.edu/does-your-flock-meet-your-performance-expectations
- Sheep Ireland, *How to Record a Lambing Event* — "Number of Lambs born should include both alive and dead lambs". https://www.sheep.ie/how-to-record-a-lambing-event/
- OMAFRA (Ontario), *Measuring sheep flock productivity* — "number of lambs born ÷ number of ewes lambing × 100", and "lambs born" explicitly includes stillborn and mummified lambs. The published counter-convention behind §6.2's worked contrast. https://www.ontario.ca/page/measuring-sheep-flock-productivity
- Teagasc, *Lamb mortality — the main causes and timing* — the day 1–3 / day 4–7 split, "the first three days after birth account for 74% of lamb mortality", and "diagnosis not reached" at 19%. The basis for §6.8's bucket boundaries. https://www.teagasc.ie/news--events/daily/lamb-mortality-the-main-causes-and-timing/
- Sheep Genetics (MLA), *Understanding Lambing Ease ASBVs* — "a blank score indicates the lambing ease was not scored". https://www.sheepgenetics.org.au/globalassets/sheep-genetics/resources/lambing-ease-scoring-guideline.pdf
- National Sheep Association, *Terms to know* — the conflicting gimmer/shearling/hogget/teg definitions. https://nationalsheep.org.uk/terms-to-know/
- Huisman & Brown et al., *Effects of birth–rearing type*, Genet Sel Evol 2015 — birth type and rearing type as distinct traits. https://pmc.ncbi.nlm.nih.gov/articles/PMC4489108/
- SRUC / Farm Advisory Service, *TN747 Recording traits of lambing* — the 1–5 (SRUC: 1–6) lambing-ease scale. **Unverified:** the PDF is image-based and neither its text nor its licence terms could be confirmed; paraphrase, never copy. https://www.sruc.ac.uk/media/3ixfnvl5/tn-747-recording-traits-of-lambing.pdf

**Dart / Flutter**
- `DateTime.add` — "If the resulting DateTime has a different daylight saving offset than `this`… Be careful when working with dates in local time." https://api.dart.dev/stable/dart-core/DateTime/add.html
- `DateTime` — "the difference between two midnights in local time may be less than 24 hours times the number of days between them". https://api.dart.dev/stable/dart-core/DateTime-class.html
- dart.dev, *Extension types* — zero cost, non-transparent, "at run time there is absolutely no trace of the extension type". https://dart.dev/language/extension-types
- dart.dev, *Class modifiers* — `sealed` exhaustiveness. https://dart.dev/language/class-modifiers
- `package:clock` README — `clock.now()`, `Clock.fixed`, `withClock`. https://github.com/dart-lang/clock
- drift, *DateTime migration guide* — the two storage modes and "drift always returns a non-UTC value". https://drift.simonbinder.eu/guides/datetime-migrations/
- Flutter, *Internationalization* — gen-l10n, ARB placeholders inside plural variants. https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization

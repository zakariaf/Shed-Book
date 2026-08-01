# N04-T02 — `LocalDate` — strict parse, never widened

| | |
|---|---|
| **Epic** | [N04 — Domain: time and units](epic.md) · `00-README` §9 step 2 (1 of 3) |
| **Task** | 2 of 8 |
| **Depends on** | N04-T01 |
| **Commit** | one commit · `feat(domain): LocalDate with a strict parse` |

## 1. Why this task exists

`LocalDate` over `TEXT 'YYYY-MM-DD'` with a **strict** parse that throws rather than
guesses, plus `plusDays`, `daysUntil` and `startOfDayLocal`. It can never be derived from a
`PartialDate`, because a year with no month is not a date and pretending otherwise is how a lambing
lands on the first of January.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §2.4 | the type printed in full, including the *"Verify at first commit"* box on the private representation constructor |
| `docs/engineering/05-domain-correctness.md` | §2.1, §2.2, §2.6, §2.9 | the instant-versus-civil-date rule, the field table, why SQL may not truncate a day, and the civil-arithmetic anti-pattern |
| `docs/engineering/CONVENTIONS.md` | §2.2, §4.6 | the member list, and `TEXT 'YYYY-MM-DD'` as the stored shape of every civil-date column |
| `docs/research/00-tech-decisions.md` | §2.E #29, #47, #49 | civil dates are `TEXT`; SQL-side time is banned; the withdrawal clear date is absolute-time arithmetic |
| `docs/engineering/03-data-model-and-schema.md` | the `GLOB` checks on `local_date`, `clear_date`, `death_date`, `start_date`, `end_date` | the SQL guard this type's `iso` must always satisfy |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-domain` | civil dates, their storage shape and their arithmetic |
| `shed-testing` | boundary and rejection cases are the point of this tier |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/time/local_date_test.dart`
- **Test** — `'LocalDate.parse throws on 2026-02-30 and never accepts a PartialDate'`
- **Why it is red today** — the type does not exist and nothing refuses an impossible date.

```bash
fvm flutter test test/domain/time/local_date_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — strict parse, the three operations, and a constructor surface that has no `PartialDate`
overload at all. The second half of the anchor is a **negative compile** assertion: there is no
`LocalDate.fromPartial`, no `PartialDate.toLocalDate` and no widening path anywhere, so the test
asserts it by reading `lib/domain/time/local_date.dart` for the string `PartialDate` and finding none.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 step 2 (domain) and step 7 (tests). Step 1 is skipped: this stores nothing yet.
`LocalDateConverter` — the drift `TypeConverter` whose `fromSql` calls this strict parser, so a row
holding `'2026-2-3'` throws on **read** instead of quietly becoming a different day — is N07's, in
`lib/core/db/converters.dart` (R21: one file, not a folder). Say so in the commit message.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `test/domain/time/local_date_test.dart` | new | The anchor, written first |
| 2 | `lib/domain/time/local_date.dart` | new | The whole task: two validating factories, one from-`Instant` factory, four getters, three operations, one private formatter |
| 3 | `lib/domain/time/instant.dart` | touched? | **No.** `LocalDate.of(Instant)` imports `Instant`; `Instant` learns nothing about `LocalDate`. The dependency points one way and stays that way |

### 5.2 The signature

`05` §2.4 prints this in full and CONVENTIONS §2.2 fixes the member list. Copy it exactly — every line
below is load-bearing and the comments are part of the deliverable:

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

### 5.3 The details that are easy to get wrong

1. **`extension type const LocalDate._(String iso)` is the one spelling in this epic that may not
   compile.** The private representation constructor is what forces every construction through a
   validating factory. `05` §2.4 flags it explicitly: *"It is not one of the snippets the research
   corpus compiled. Run `dart analyze` on this file in commit #1."* Do that. If your SDK rejects it,
   fall back to a **public** representation constructor and keep both factories byte-identical — never
   weaken `LocalDate.parse` to recover the guard you lost. Record which way it went in the commit
   message; N04-T03 copies whichever spelling worked.
2. **The shape regex is not enough and the length check is worse.** `_shape` accepts `'2026-02-30'`
   and `'2026-13-01'`. The kill is the second check: build the date in UTC, re-`_format` it, and
   compare to the input string. `DateTime.utc(2026, 2, 30)` rolls to 2 March and `_format` returns
   `'2026-03-02'`, which is not the input, so it throws. Deleting the round-trip because "the regex
   already validates it" is the single likeliest regression in this file.
3. **`DateTime.utc`, never `DateTime`, inside `plusDays` and `daysUntil`.** UTC has no DST, so
   `Duration(days: n)` there is exactly *n* calendar days. The same code on a *local* `DateTime` is
   the bug `05` §2.9 measures: 20:00 + 7 days across the UK spring-forward is 21:00, and civil `+7`
   keeping 20:00 is 167 hours, one hour short. `startOfDayLocal()` is the deliberate exception — it
   uses the local `DateTime(y, m, d)` constructor because "the first instant of this day here" is
   exactly what it means.
4. **`plusDays` is never valid for a withdrawal period.** It is civil-day arithmetic. Every
   withdrawal computation goes through `clearDateFor` (N05-T02), which adds `Duration(hours: days * 24)`
   to an `Instant`. Put that sentence in the doc comment above `plusDays` — `05` §3.6 exists because
   the "simplification" is one keystroke away and costs the regulator's margin.
5. **`LocalDate.of(Instant)` is zone-dependent, and that is why `lambings.local_date` is
   denormalised.** The same instant is 24 October in one zone and 25 October in another. SQLite cannot
   do this conversion at all (no timezone database), which is why
   `date(occurred_at / 1000, 'unixepoch', 'localtime')` is a banned token and why the civil date is
   written from the instant at insert time (`05` §2.6, §6.9). Never compute a civil day in SQL.
6. **The representation is the ISO string, and three things fall out of that for free.** Equality and
   `hashCode` are `String`'s, so a `LocalDate` is a safe `Map` key. `LocalDateConverter` is the
   identity. And `ORDER BY local_date` in SQL is correct and index-friendly with zero conversion —
   which only holds because `_format` zero-pads to `'0007-01-01'` rather than `'7-1-1'`. Do not
   "simplify" `padLeft`.
7. **`compareTo` compares strings, not dates.** That is correct *only* for the strict shape. It is
   another reason `LocalDate.parse` must never accept `'2026-2-3'`: a single non-padded value poisons
   every sort in the app, silently, in the direction that looks plausible.
8. **`daysUntil` returns `.inDays` of a UTC difference, so it is exact.** Do not swap it for
   `.difference(...).inHours ~/ 24`; do not route it through `.toLocal()`.
9. **There is no `LocalDate.today()`, no `LocalDate.now()` and no clock in this file.** The civil date
   of *now* is `LocalDate.of(appNow())` at the edge (N04-T05). D3 makes it a compile-time question.
10. **No formatting.** `05` §5.1 and CONVENTIONS §5.4: dates a human reads are `d MMM y`, never
    all-numeric, and that rendering lives in `lib/core/ui/formatters.dart`. `iso` is a storage shape,
    not a display shape, and `07-screens.md` §10.3's `clear on 11/03/2026` is a defect (R60). This
    file exposes `iso` and nothing prettier.

### 5.4 The full test set — `test/domain/time/local_date_test.dart`

Zone-agnostic, with one deliberate exception noted below. No `@Tags`.

| Case | What it pins |
|---|---|
| `'LocalDate.parse throws on 2026-02-30 and never accepts a PartialDate'` | **the anchor.** `expect(() => LocalDate.parse('2026-02-30'), throwsFormatException)`, plus a source read of `local_date.dart` finding no occurrence of `PartialDate` |
| `'parse rejects every malformed shape'` | a table: `'2026-2-3'`, `'26-02-03'`, `'2026/02/03'`, `'2026-02-03T00:00'`, `'20260203'`, `'2026-02-03 '`, `''`, `'20x6-02-03'` — all `throwsFormatException` |
| `'parse rejects every impossible date'` | `'2026-13-01'`, `'2026-00-10'`, `'2026-02-30'`, `'2025-02-29'`, `'2026-04-31'`, `'2026-01-32'`, `'2026-01-00'` |
| `'parse accepts the boundaries'` | `'2024-02-29'` (a real leap day), `'2000-02-29'`, `'2026-12-31'`, `'0001-01-01'` |
| `'the constructor throws where parse would'` | `LocalDate(2026, 2, 30)` throws `ArgumentError` — it does **not** roll to 2 March |
| `'a single-digit month and day are zero-padded'` | `LocalDate(7, 1, 1).iso == '0007-01-01'` — the property `ORDER BY` depends on |
| `'plusDays crosses a month, a year and a leap day'` | `2026-01-31 +1 → 2026-02-01`; `2026-12-31 +1 → 2027-01-01`; `2024-02-28 +1 → 2024-02-29`; `2026-03-01 -1 → 2026-02-28` |
| `'daysUntil is exact and signed'` | `2026-03-01.daysUntil(2026-03-08) == 7`; the reverse is `-7`; a date to itself is `0` |
| `'plusDays and daysUntil are inverses'` | for `n` in −400…400: `d.plusDays(n).daysUntil(d) == -n` |
| `'compareTo sorts lexically and chronologically at once'` | a shuffled list of ten dates sorts identically by `compareTo` and by the underlying `iso` strings |
| `'LocalDate is a safe Map key'` | `{LocalDate(2026, 3, 4): 'a'}[LocalDate.parse('2026-03-04')] == 'a'` |
| `'startOfDayLocal round-trips through LocalDate.of'` | `LocalDate.of(d.startOfDayLocal()) == d`, for a spread of dates. **This one is zone-sensitive in principle** — it holds in every zone with a local midnight, which is why the spring-forward form of it lives in N04-T08 |
| `'plusDays across the UK spring-forward is still exactly one civil day'` | `2026-03-28.plusDays(1) == 2026-03-29` and `.daysUntil` is 1 — proving the UTC routing, and passing identically under `TZ=Pacific/Chatham`. The **ambiguous-hour** counterpart, where `LocalDate.of(Instant)` must land on 25 October and not 24, is DST-2 in N04-T08 |

## 6. Constraints that bind this task

- **The five safety rules** — rule 4 (never silently correct an entry), held at **unconstructible**: an impossible date cannot become a `LocalDate` at all, because there is no non-throwing path to one. A parse that clamps would drop that to *documented*, which `05` §7.1 counts as deleted.
- **`layer.domain`** — `dart:*`, `package:meta`, `package:collection` and `lib/domain/` only. No `intl`, no `clock`.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'LocalDate.parse throws on 2026-02-30 and never accepts a PartialDate'` passes, and was seen to fail first for the stated reason
- [ ] an impossible date throws, never clamps
- [ ] `plusDays` is civil-day arithmetic and is documented as **never** valid for withdrawal
- [ ] storage is `TEXT 'YYYY-MM-DD'`, per decision #2
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
dart analyze lib/domain/time/local_date.dart      # the §5.3.1 check — run this FIRST
fvm flutter test test/domain/time/local_date_test.dart
TZ=Pacific/Chatham fvm flutter test test/domain/time/local_date_test.dart
dart tool/check_policy.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): LocalDate with a strict parse`

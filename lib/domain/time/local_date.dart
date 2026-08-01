import 'package:shed_book/domain/time/instant.dart';

/// A square on a calendar, stored exactly as it is stored in SQLite: a strict
/// ISO `'YYYY-MM-DD'` string that sorts lexicographically.
///
/// Three things fall out of the representation being the ISO string, and all
/// three are load-bearing. Equality and `hashCode` are `String`'s, so a
/// `LocalDate` is a safe `Map` key. `LocalDateConverter` (N07) is the identity.
/// And `ORDER BY local_date` in SQL is correct and index-friendly with zero
/// conversion — which only holds because [_format] zero-pads to `'0007-01-01'`
/// rather than `'7-1-1'`. Do not "simplify" the `padLeft`.
///
/// There is no `LocalDate.today()`, no `LocalDate.now()` and no clock here. The
/// civil date of *now* is `LocalDate.of(appNow())`, at the edge. D3 makes that a
/// compile-time question rather than a discipline.
///
/// There is no formatting either. `iso` is a storage shape, not a display
/// shape; a date a human reads is `d MMM y` and lives in
/// `lib/core/ui/formatters.dart` (05 §5.1, CONVENTIONS §5.4).
extension type const LocalDate._(String iso) {
  static final RegExp _shape = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  factory LocalDate(int year, int month, int day) {
    final DateTime d = DateTime.utc(year, month, day); // UTC: no DST to perturb it
    if (d.year != year || d.month != month || d.day != day) {
      throw ArgumentError('Not a real date: $year-$month-$day');
    }
    return LocalDate._(_format(d));
  }

  /// Strict. Throws rather than coercing — a malformed date must not become a
  /// plausible one (safety rule §12.4).
  ///
  /// [_shape] alone is not enough and a length check is worse: the regex accepts
  /// `'2026-02-30'` and `'2026-13-01'`. The kill is the round trip.
  /// `DateTime.utc(2026, 2, 30)` rolls to 2 March and [_format] returns
  /// `'2026-03-02'`, which is not the input, so it throws. Deleting that check
  /// because "the regex already validates it" is the single likeliest
  /// regression in this file.
  factory LocalDate.parse(String s) {
    if (!_shape.hasMatch(s)) {
      throw FormatException('Not YYYY-MM-DD', s);
    }
    final DateTime d = DateTime.utc(
      int.parse(s.substring(0, 4)),
      int.parse(s.substring(5, 7)),
      int.parse(s.substring(8, 10)),
    );
    if (_format(d) != s) {
      throw FormatException('Not a real date', s);
    }
    return LocalDate._(s);
  }

  /// The civil date on which [i] fell, in the device's **current** local zone.
  ///
  /// Zone-dependent, and that is why `lambings.local_date` is denormalised: the
  /// same instant is 24 October in one zone and 25 October in another. SQLite
  /// cannot do this conversion at all — it has no timezone database — which is
  /// why `date(occurred_at / 1000, 'unixepoch', 'localtime')` is a banned token
  /// and why the civil date is written from the instant at insert time
  /// (05 §2.6, §6.9). Never compute a civil day in SQL.
  factory LocalDate.of(Instant i) {
    final DateTime d = i.local;
    return LocalDate(d.year, d.month, d.day);
  }

  int get year => int.parse(iso.substring(0, 4));
  int get month => int.parse(iso.substring(5, 7));
  int get day => int.parse(iso.substring(8, 10));

  /// Calendar arithmetic, done in UTC so no DST can perturb it.
  ///
  /// **Never valid for a withdrawal period.** This is civil-day arithmetic:
  /// the same code on a local `DateTime` makes 20:00 + 7 days into 21:00 across
  /// the UK spring-forward, and civil `+7` keeping 20:00 is 167 hours — one
  /// hour short of a seven-day withdrawal, in late March. Every withdrawal goes
  /// through `clearDateFor`, which adds `Duration(hours: days * 24)` to an
  /// `Instant` (05 §3.6).
  LocalDate plusDays(int n) {
    final DateTime d = DateTime.utc(year, month, day).add(Duration(days: n));
    return LocalDate(d.year, d.month, d.day);
  }

  /// Exact and signed. Not `.difference(…).inHours ~/ 24`, and never routed
  /// through `.toLocal()`.
  int daysUntil(LocalDate o) =>
      DateTime.utc(o.year, o.month, o.day).difference(DateTime.utc(year, month, day)).inDays;

  /// The first instant of this civil date in the device's local zone.
  ///
  /// The one deliberate use of the **local** `DateTime` constructor in this
  /// file, because "the first instant of this day here" is exactly what it
  /// means. In the rare zone where local midnight does not exist,
  /// `DateTime(y, m, d)` returns the first instant that does — which is what we
  /// want.
  Instant startOfDayLocal() => Instant.fromDateTime(DateTime(year, month, day));

  /// Compares **strings**, which is correct only for the strict shape — another
  /// reason [LocalDate.parse] must never accept `'2026-2-3'`. A single
  /// non-padded value poisons every sort in the app, silently, in the direction
  /// that looks plausible.
  int compareTo(LocalDate o) => iso.compareTo(o.iso);

  static String _format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

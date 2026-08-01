/// A moment in absolute time, as UTC milliseconds since the epoch.
///
/// Decision #29: instants are `INTEGER` UTC epoch millis and civil dates are
/// `TEXT 'YYYY-MM-DD'`. This type is what that column wraps, and it is
/// irreversible after the first migration snapshot (N07), which is why it
/// exists before the schema does.
///
/// **Non-transparent**, deliberately: a bare `int` cannot be passed where an
/// `Instant` is expected, and it costs no allocation on a 400-row flock list.
/// Writing `implements int` is worse than wrong — it compiles, and then
/// `someInstant + 1`, `someInstant * 2` and `Grams(4000).compareTo(someInstant)`
/// all become legal. The whole point of the type is that they are not.
///
/// It does **not** `implements Comparable<Instant>`, and cannot: an extension
/// type may only implement a supertype of its representation, and `int`
/// implements `Comparable<num>`. So there is no free `.sort()` — [ascending]
/// and [descending] are why.
///
/// Extension types erase at runtime. `Instant`, `Grams`, `MilliCelsius` and
/// every id in `lib/domain/ids.dart` are all `int` after compilation, so
/// `x is Instant` is true for any `int` and `identical(Instant(0), Grams(0))` is
/// true. Build extension types for **canonical** values only, never for display
/// values, and never write a runtime type test over one.
///
/// There is no `toString()` that formats. D4 bans `package:intl` from the
/// domain, and a type that formats is a type with a locale; formatting lives in
/// `lib/core/ui/formatters.dart`.
extension type const Instant(int epochMillis) {
  factory Instant.fromDateTime(DateTime d) => Instant(d.millisecondsSinceEpoch);

  DateTime get utc => DateTime.fromMillisecondsSinceEpoch(epochMillis, isUtc: true);

  /// Reads the OS zone rules **at the moment you call it**, not at
  /// construction, so the same `Instant` renders as two different `DateTime`s on
  /// two phones. That is deliberate (05 §2.7: a bundled IANA snapshot frozen at
  /// build time ages badly; the phone's own rules do not) and it is why every
  /// assertion in a zone-agnostic test is relational.
  DateTime get local => DateTime.fromMillisecondsSinceEpoch(epochMillis);

  /// Absolute-time arithmetic. `plus(const Duration(days: 7))` adds 168 hours,
  /// not seven calendar days; across the UK spring-forward those differ by an
  /// hour and the difference lands in a withdrawal period. There is deliberately
  /// no `plusDays` here — calendar arithmetic belongs on `LocalDate`.
  Instant plus(Duration d) => Instant(epochMillis + d.inMilliseconds);

  /// `this` − `other`. `now.difference(penned)` is positive when `now` is later.
  Duration difference(Instant o) => Duration(milliseconds: epochMillis - o.epochMillis);

  bool isBefore(Instant o) => epochMillis < o.epochMillis;
  bool isAfter(Instant o) => epochMillis > o.epochMillis;
  int compareTo(Instant o) => epochMillis.compareTo(o.epochMillis);

  static int Function(Instant, Instant) get ascending =>
      (Instant a, Instant b) => a.compareTo(b);
  static int Function(Instant, Instant) get descending =>
      (Instant a, Instant b) => b.compareTo(a);
}

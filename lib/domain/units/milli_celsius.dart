/// Canonical temperature: thousandths of a degree Celsius.
///
/// **Milli, not centi, and the reason is a measurement.** Storing at 0.1 °C
/// rewrites 89 of 201 Fahrenheit entries at one decimal place. 0.01 °C is the
/// *minimum* that survives all 201; milli buys headroom for a two-decimal
/// display later **without a migration**. That is the whole argument for the
/// extra factor of ten, and both loops ship in the test beside it.
///
/// **This type converts and does nothing else.** A temperature in the domain is
/// one autocomplete away from *"38.5 °C — normal"* or *"that's a fever"*, and
/// 05 §7.3's line is the one to keep in your head: the app may
/// arithmetic-transform a number the user supplied; the app may never originate
/// a number that is a clinical decision. A conversion is arithmetic. A
/// judgement about the result is origination. So there is no band, no label, no
/// `isFever`, no `isNormal`, no min/max constant and no `compareTo` until
/// something needs one.
///
/// **`Fahrenheit` is a banned type name** (CONVENTIONS §2.3). It would erase to
/// the same runtime type as this one and as `Grams`, giving false confidence in
/// any `is`, `switch` or serialisation path and inviting somebody to store one.
/// Fahrenheit exists only as a `double` returned by [inFahrenheit] and consumed
/// immediately by a formatter.
///
/// Integer storage is a JSON and a SQL property too, not only a rounding one: a
/// `double` measurement makes SQLite's `SUM` and `==` approximate and a JSON
/// round trip can shift the last digit. The backup is the only copy of the
/// data, and a value that changes on restore is a silent correction with no
/// author.
///
/// Negative and zero are real values. `MilliCelsius(0)` is 0 °C, not "unset".
/// There is no sentinel and no −999. If a column ever ships, absence is `NULL`
/// and it means *not recorded*.
///
/// **No column ships yet, and that is a ruling rather than a sequencing
/// detail.** Open question 11 is unresolved — spec §7.10 has a °C/°F setting and
/// §10's data model has no temperature field. 05 §5.2: this type ships either
/// way and costs nothing; an unused setting is a 3am tax and an unused column is
/// a migration you did not need. There is no `TemperatureUnit` enum either
/// (R68).
extension type const MilliCelsius(int value) {
  /// `round()`, never `toInt()`. Truncation toward zero is systematically low
  /// above freezing and systematically **high** below it, and the asymmetry is
  /// worse than the bias — a lambing shed in late March goes below zero.
  factory MilliCelsius.fromCelsius(double c) => MilliCelsius((c * 1000).round());

  /// The operator order is the specification. `((f - 32) * 5 / 9 * 1000)` is not
  /// interchangeable with `((f - 32) * 5000 / 9)` in IEEE-754: they differ in
  /// the last bit, which is enough to move a `round()` across a boundary and
  /// break the 201-value loop at one input. If a review finds it ugly, the
  /// answer is a comment, not a rearrangement.
  factory MilliCelsius.fromFahrenheit(double f) => MilliCelsius(((f - 32) * 5 / 9 * 1000).round());

  double get inCelsius => value / 1000.0;

  /// Same rule as above: `value / 1000.0 * 9 / 5 + 32`, not `value * 9 / 5000 + 32`.
  double get inFahrenheit => value / 1000.0 * 9 / 5 + 32;
}

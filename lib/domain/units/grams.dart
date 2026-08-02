/// Canonical mass: whole grams.
///
/// Non-transparent extension type, so a raw `int` cannot be passed where a mass
/// is expected, and it costs no allocation on a 400-row flock list.
///
/// **No extension type ever exists for a display unit.** `Pounds` and
/// `Fahrenheit` are banned type names (CONVENTIONS §2.3): they would erase to
/// the same runtime type as this one, giving false confidence in any `is`,
/// `switch` or serialisation path and inviting somebody to store one. Pounds
/// exist only as a `double` returned by a getter and consumed immediately by a
/// formatter.
///
/// **Storage never rounds. Only the display edge does.** This holds an `int`;
/// every getter returns a `double` for immediate rendering. The moment a rounded
/// display value is assigned to a variable that flows back toward the database,
/// 05 §5.1's rule has been broken. A form is seeded from the canonical value and
/// parses the typed text back into canonical; it never re-derives from the old
/// canonical.
///
/// There is no range check here. The plausibility band is `kPlausibleBirthWeight`
/// in `lib/domain/validation/lambing_checks.dart` (N06-T03), it is provisional
/// pending open question 12, and it produces a `Warning` — an observation —
/// never a block and never a judgement.
extension type const Grams(int value) {
  /// Exact, by international definition. **Do not shorten.** `453.592` looks
  /// harmless and breaks the 0.1 lb round trip at the top of the range, which
  /// is the loop that justifies the whole design.
  static const double _gPerLb = 453.59237;
  static const double _gPerOz = 28.349523125;

  /// `round()`, never `toInt()`. `toInt()` truncates toward zero, so every
  /// conversion would be systematically light — on a birthweight, in the
  /// direction that reads as a smaller lamb. Dart's `double.round()` rounds
  /// half **away from zero**.
  factory Grams.fromKilograms(double kg) => Grams((kg * 1000).round());

  factory Grams.fromPounds(double lb) => Grams((lb * _gPerLb).round());

  factory Grams.fromPoundsOunces(int lb, double oz) => Grams((lb * _gPerLb + oz * _gPerOz).round());

  double get inKilograms => value / 1000.0;
  double get inPounds => value / _gPerLb;

  /// `floor()`, deliberately: this is a decomposition for display — `8 lb 3 oz`
  /// — not a rounding of the canonical value, and nothing here is stored. Do
  /// not "make it consistent" with `round()`; `floor()` is what makes the pair
  /// sum back to the original.
  ///
  /// **THIS PAIR IS EXACT AND MUST NOT BE ROUNDED BY ITS CALLER.** See
  /// [poundsOunces], which is the one a display uses.
  int get wholePounds => inPounds.floor();

  double get remainderOunces => (value - wholePounds * _gPerLb) / _gPerOz;

  /// The pair a display prints, **rounded once and carried at sixteen**.
  ///
  /// **THIS EXISTS BECAUSE OF A REAL DEFECT THAT N17-T02'S ANCHOR FOUND.**
  /// `formatShedWeight` printed `wholePounds` beside `remainderOunces.round()` —
  /// two roundings at two different scales — and that names quantities that do
  /// not exist:
  ///
  ///   4 lb → 1814 g → floor(3.9992) = 3 lb, 15.99 oz → **"3 lb 16 oz"**
  ///
  /// Sixteen ounces is a pound. Measured at 1, 4, 9 and 12 lb, three of the four
  /// printed the pound BELOW the one the shepherd typed — and a birthweight is
  /// the number they read most often on a lamb card.
  ///
  /// [wholePounds] and [remainderOunces] are left EXACT, because N04's
  /// round-trip property depends on them summing back to within a gram. The
  /// rounding belongs where the display is, which is here.
  ({int pounds, int ounces}) get poundsOunces {
    final int totalOunces = (value / _gPerOz).round();
    return (pounds: totalOunces ~/ 16, ounces: totalOunces % 16);
  }
}

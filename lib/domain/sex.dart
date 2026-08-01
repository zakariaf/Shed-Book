/// A lamb's sex, as stored in `lambs.sex` (R45).
///
/// **`unknown`'s key is the word, not `'u'`, and a SQL `NULL` is not it.** `NULL`
/// means *"not recorded"* — nobody has said. [Sex.unknown] means *"looked, could
/// not tell"*. They are two different facts, and collapsing them is exactly what
/// the column's nullability exists to prevent. A `?? Sex.unknown` at a read site
/// is that collapse in one keystroke.
enum Sex {
  female('f'),
  male('m'),
  unknown('unknown');

  const Sex(this.key);

  /// **Frozen** by N07's `CHECK (sex IN ('f','m','unknown'))`, then by every CSV
  /// column and every JSON backup.
  final String key;

  /// Throws rather than falling back. An `orElse` returning [Sex.unknown] would
  /// turn a corrupt value into a plausible one.
  static Sex fromKey(String k) => Sex.values.firstWhere(
    (Sex s) => s.key == k,
    orElse: () => throw FormatException('Unknown sex', k),
  );
}

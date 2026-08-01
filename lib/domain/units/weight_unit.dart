/// Rendering and parsing only. **There is no unit column on any measurement.**
///
/// The bug that prevents is the display-unit round trip, and it is worth
/// memorising because it has no line of code to blame: a shepherd enters 9.5 lb
/// → you store 9.5 with a unit flag → they switch to kg and see 4.309 → the edit
/// screen pre-fills 4.3 at one decimal place → they save without touching it →
/// the record is now 4.3 kg = 9.48 lb. *The value drifted because nobody edited
/// it.*
///
/// The keys are byte-identical to `app_settings.weight_unit`'s `CHECK` (R68),
/// written at N07. A mismatch surfaces as a CHECK failure on a real phone, not
/// as a compile error here. The default is `kg` — settled, not open (§7.0
/// ruling 3, UK and Ireland first).
enum WeightUnit {
  kg('kg'),
  lb('lb');

  const WeightUnit(this.key);

  final String key;

  static WeightUnit fromKey(String k) => WeightUnit.values.firstWhere(
    (WeightUnit u) => u.key == k,
    orElse: () => throw FormatException('Unknown weight unit', k),
  );
}

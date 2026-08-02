/// How many lambs the ewe was declared to have carried.
///
/// R46 puts the enum and [expectedLambCount] in one file: 03 owns the codes, 05
/// owns the semantics, and separating them is how the two drift apart.
///
/// Birth type is **derived from the tally strokes and labelled `(COUNTED)`** —
/// ruling P8, there is no birth-type chooser in the product. This enum is the
/// stored shape of that derivation, not a control.
enum BirthType {
  single(1),
  twin(2),
  triplet(3),
  quad(4),
  quintPlus(5);

  const BirthType(this.code);

  /// The stored code in `lambings.declared_birth_type`. **Frozen forever** — N07
  /// writes it into a `CHECK` one epic from now, and it is then a CSV column and
  /// a JSON backup field.
  final int code;

  static BirthType fromCode(int c) => BirthType.values.firstWhere(
    (BirthType t) => t.code == c,
    orElse: () => throw FormatException('Unknown birth type code', '$c'),
  );
}

/// How many lambs that birth type implies — **`null` for [BirthType.quintPlus],
/// and that null is load-bearing.**
///
/// *Quint-or-more* is open-ended, so a contradiction between the declared type
/// and the lamb count is **undefined**, not false. Encoding it as 5 would produce
/// a false `birthTypeLambCountMismatch` for every set of sextuplets — the app
/// inventing a fact, which is safety rule §12.4 with extra steps.
///
/// **`code` is not this.** `BirthType.quintPlus.code == 5` while
/// `expectedLambCount(BirthType.quintPlus) == null`. Reaching for `.code` at
/// N06-T03's validation site is the single mistake this pair exists to prevent.
int? expectedLambCount(BirthType t) => switch (t) {
  BirthType.single => 1,
  BirthType.twin => 2,
  BirthType.triplet => 3,
  BirthType.quad => 4,
  BirthType.quintPlus => null,
};

/// The **COUNTED** type: what *n* un-struck strokes make.
///
/// **Returns null at five and above, and that is deliberate.**
/// [BirthType.quintPlus] means *"more than four, count NOT declared"* — an
/// open-ended DECLARATION. A counted five is not open-ended: the app knows
/// there are exactly five rows. Mapping the count onto `quintPlus` would throw
/// away the number the tally exists to hold, so the presentation edge prints
/// the count itself instead.
///
/// Zero returns null too, and for the same reason from the other side: no
/// strokes is NOT RECORDED, never `single`. P8's whole point is that the type
/// is derived rather than declared, and a derivation that invented `single`
/// from an empty tally would be the app answering for the shepherd.
BirthType? countedBirthType(int strokes) => switch (strokes) {
  1 => BirthType.single,
  2 => BirthType.twin,
  3 => BirthType.triplet,
  4 => BirthType.quad,
  _ => null,
};

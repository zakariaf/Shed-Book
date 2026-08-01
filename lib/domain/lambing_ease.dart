/// The 1..5 lambing-ease ordinal, and **nothing else** (R44).
///
/// N00-T04 ruled it stays an ordinal rather than becoming a named enum: the
/// scale is a scale, 06 §12's `ShedChoiceRow` renders 1–5, and the codes are
/// stored integers.
///
/// **It holds no prose, and the absence is deliberate.** If you find yourself
/// typing *"unassisted"* into this file, stop: 03 §10.1 puts `ease_1`…`ease_5`
/// in `vocab_terms` and 10 §8.6 puts their labels in the ARB. Holding them here
/// would need `AppLocalizations`, which layer rule 1 forbids in `lib/domain/` —
/// so the import you would reach for next is one the gate refuses.
///
/// **The band is checkable, not unconstructible, and that is CONVENTIONS'
/// choice rather than an oversight here.** R44 and §2.9 both spell this
/// `extension type const LambingEase(int code)` — a *public* representation
/// constructor — so `LambingEase(9)` compiles and [LambingEase.of] is the entry
/// point that rejects it. The tests pin both facts rather than pretending only
/// one exists.
///
/// N04-T02 measured that the private form (`extension type const
/// LambingEase._(int code)`, the shape `LocalDate` uses) does resolve on Dart
/// 3.12.2, which would make the 1..5 band unconstructible instead. That is an
/// amendment to a spelling fixed by a numbered ruling, so it is raised for the
/// owner rather than taken here — R44's subject is *descriptions*, and the
/// constructor spelling rides along with it.
extension type const LambingEase(int code) {
  /// Validating. Throws rather than clamping — clamping a 6 to a 5 would be the
  /// app silently correcting a user's entry (§12.4).
  factory LambingEase.of(int code) {
    if (code < 1 || code > 5) {
      throw ArgumentError.value(code, 'code', 'lambing ease is 1..5');
    }
    return LambingEase(code);
  }
}

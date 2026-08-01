/// The **ONLY** place these strings exist.
///
/// **Not in the ARB** (10 §8.7). A translator can drop or soften an ARB string
/// and the app has no mechanism to notice — which is the same reason 05 §4.1's
/// `provenanceLabel` stays out of the ARB while v1 ships `en` alone.
///
/// **`abstract final`**, not `abstract`, not `final`, and not a `class` with a
/// private constructor. `abstract final` cannot be instantiated **or extended**,
/// so nobody can subclass it and shadow a string.
///
/// Safety rule §12.3 lives here at the **unconstructible** level: these are
/// referenced and never re-typed, `ExportEnvelope` has no disclaimer parameter,
/// and `tool/check_policy.dart`'s `copy.disclaimer_retyped` row fails the build
/// if a second file types one out.
///
/// This file is **never waved through in review, however small the diff**
/// (00-README §8 step 10).
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

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

  /// `indelible.md` screen 11's second footer sentence, and it is **its own
  /// const rather than an amendment to [exportFooter]** — ruled in N21-T03.
  ///
  /// R79 made the strike real, so screen 11's promise — *the export includes
  /// struck entries and marks them, and removes nothing* — now has to appear
  /// somewhere. Amending [exportFooter] would have been cheaper in the writer
  /// and more expensive everywhere else: three documents print that string
  /// verbatim, `05 §7.4` pins it, and N22's backup-header golden is written
  /// against it before that golden exists. A fourth const costs one catalogue
  /// row.
  ///
  /// What was never an option is a third sentence typed inline in a writer *just
  /// for the CSV*. That is exactly what `copy.disclaimer_retyped` exists to
  /// catch, and it is how two footers become three.
  static const String strikeNotice =
      'Struck entries are included and marked struck. Nothing has been removed.';

  static const String withdrawalCaveat =
      'Withdrawal period as entered by you from the product label. '
      'Shed Book does not know any product and suggests no value. '
      'Check the label.';
}

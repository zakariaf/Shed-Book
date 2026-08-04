import 'package:shed_book/domain/terminology/animal_class.dart';
import 'package:shed_book/domain/terminology/term_label.dart';

/// The words, resolved: **user override → localised default.** Never empty.
///
/// Rename *ewe* to *gimmer* and every screen says gimmer, without a single
/// `if (term == 'gimmer')` anywhere — because the code switches on
/// [AnimalClass] and only ever renders [labelFor].
///
/// **It holds no default text and cannot fetch any.** Layer rule 1 bans
/// `package:intl` and `AppLocalizations` from `lib/domain/`, so the defaults
/// arrive through the constructor. Seeding happens **once**, in
/// `lib/features/settings/terminology_bootstrap.dart` (N29), which already has a
/// `BuildContext` — never in `domain/` or `data/`, and a locale change or an app
/// update never overwrites a user's override.
final class Terminology {
  const Terminology(this._defaults, this._overrides);

  /// Supplied by the settings bootstrap, from the ARB.
  final Map<AnimalClass, TermLabel> _defaults;

  /// From `TerminologyOverrides` (N07-T06).
  final Map<AnimalClass, TermLabel> _overrides;

  /// **A half-filled override is ignored, not stored-and-rendered.** Both sides
  /// are trimmed and checked before the override is preferred, so a row with a
  /// blank plural falls back to the default rather than rendering an empty
  /// button at 3am.
  ///
  /// `_defaults[c]!` is deliberate: a missing default is a programming error,
  /// not a runtime state. The parity between the seven members and the fourteen
  /// ARB messages is what `test/policy/terminology_survives_a_rename_test.dart`
  /// holds.
  TermLabel labelFor(AnimalClass c) {
    final TermLabel? o = _overrides[c];
    if (o != null && o.singular.trim().isNotEmpty && o.plural.trim().isNotEmpty) {
      return o;
    }
    return _defaults[c]!;
  }

  /// The shepherd's override for [c], or `null` if they have not set one.
  ///
  /// **THE PRESENTATION-EDGE FORM OF [labelFor], AND IT EXISTS BECAUSE THE
  /// DEFAULTS ARE NOT WIRED YET.** `terminologyProvider` is
  /// `const Terminology({}, {})` until N29, so `labelFor` ends in
  /// `_defaults[c]!` and **throws** — `lambing_entry_screen.dart` records the
  /// same trap and works around it by reading the `term*Singular` ARB messages
  /// directly. That workaround needs a way to ask *"has the shepherd renamed
  /// this?"* without falling through to a map that is empty, and this is it.
  ///
  /// It applies the same both-halves rule as [labelFor]: a row with a blank
  /// plural is ignored rather than stored-and-rendered, because **a plural is
  /// never derived by appending an s** (`10 §8.5`) — the shepherd typed one
  /// word and guessing the other is safety rule 4.
  ///
  /// N29 fills `_defaults` from the ARB, after which every caller can go back to
  /// [labelFor]. Until then this is the only non-throwing route.
  TermLabel? overrideFor(AnimalClass c) {
    final TermLabel? o = _overrides[c];
    if (o != null && o.singular.trim().isNotEmpty && o.plural.trim().isNotEmpty) {
      return o;
    }
    return null;
  }
}

/// The outcome of checking one proposed override.
sealed class TermOverrideResult {
  const TermOverrideResult();
}

final class TermOverrideAccepted extends TermOverrideResult {
  const TermOverrideAccepted(this.label);

  final TermLabel label;
}

/// Carries **why**, because a refusal without a reason is the app being
/// unhelpful rather than careful.
final class TermOverrideRejected extends TermOverrideResult {
  const TermOverrideRejected(this.reason);

  final String reason;
}

/// **Reject, do not sanitise.**
///
/// Stripping the comma silently would be a silent correction (§12.4); rejecting
/// with a reason is not. **Trimming surrounding whitespace is the one accepted
/// exception** — invisible, universally expected, and it cannot change meaning.
///
/// The 24-character cap is a **3am constraint, not a database one**: a label
/// that overflows a 60 pt button under a head torch is a defect, and
/// `TerminologyOverrides.singular` carries no length `CHECK`.
///
/// The comma and the quote are rejected because a label goes into the CSV, where
/// either one breaks a column; the line break because it breaks a button.
TermOverrideResult validateOverride(String singular, String plural) {
  final String s = singular.trim();
  final String p = plural.trim();
  if (s.isEmpty || p.isEmpty) {
    return const TermOverrideRejected('Both the singular and the plural are needed.');
  }
  if (s.length > 24 || p.length > 24) {
    return const TermOverrideRejected(
      '24 characters maximum, so it still fits the buttons at arm’s length.',
    );
  }
  final RegExp bad = RegExp('[\n\r\t,"]');
  if (bad.hasMatch(s) || bad.hasMatch(p)) {
    return const TermOverrideRejected('No commas, quotes or line breaks.');
  }
  return TermOverrideAccepted(TermLabel(s, p));
}

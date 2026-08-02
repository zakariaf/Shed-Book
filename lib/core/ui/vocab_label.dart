// lib/core/ui/vocab_label.dart
//
// TWO LINES, AND THREE HOMES WITH NO OVERLAP (R66). The vocabulary keys live in
// `lib/core/db/seed/first_run.dart` with `origin = 'seeded'` and `label = NULL`;
// the shipped words live in `lib/l10n/app_en.arb`, one message per key;
// `assets/content/` holds only long prose and one provenance line per list. This
// function is the seam where the first two meet.
library;

/// The word to print for one vocabulary key.
///
/// **`userLabel ?? shipped`, and nothing cleverer.** A `label?.isEmpty ?? true`
/// check would let an accidental blank fall silently back to the shipped word,
/// hiding an edit the shepherd made — which is safety rule §12.4 (never silently
/// correct a user's entry) in its smallest possible form. `NULL` means *render
/// the shipped default*; an empty string means the shepherd blanked it, and that
/// is their business.
///
/// **PRIMITIVES, NEVER A `VocabTerm`.** Layer rule 7 forbids `lib/core/ui/` from
/// importing `lib/data/`, so a drift row class in this signature makes the file
/// unbuildable — the gate says so before the analyzer does. It also keeps the
/// function testable without a database.
///
/// The `shipped` argument is an already-resolved ARB message rather than a key,
/// because `lib/core/ui/` may not import `lib/l10n/` either: the screen that
/// knows the locale is the screen that supplies the word, the same shape
/// [ShedKeypad] and [ShedTapTarget] already use.
String vocabLabel(String? userLabel, String shipped) => userLabel ?? shipped;

import 'package:shed_book/domain/policy/disclaimers.dart';

/// Safety rule §12.2 — **never give veterinary advice** — as a pattern list.
///
/// The ambiguity dissolves once you draw the line at **who supplied the
/// number**: the app may arithmetic-transform a number the user supplied; it may
/// never originate a number that is a clinical decision.
///
/// Two of the ten are worth reading twice before editing them.
///
/// `call the vet` is banned **deliberately**. It sounds like the safe thing to
/// say and it is still the app making a clinical call about a specific animal at
/// a specific moment.
///
/// The `ml/kg` pattern exists because the temptation is concrete, not
/// hypothetical: AHDB publishes *"Make sure lambs receive 50 ml/kg of colostrum
/// within the first four to six hours of life"*, the app holds the birthweight,
/// and multiplying is one line and would be *helpful*. It is a dose suggestion
/// and it is banned.
///
/// The `\byou should\b` pattern is **narrower** than `check_policy.dart`'s
/// `copy.banned_word` row, which bans `should` outright in our own prose. They
/// are not duplicates and neither may be deleted: one is a word ban in the
/// project's own writing, the other is a phrase ban in user-facing text.
abstract final class ContentPolicy {
  static final List<({RegExp pattern, String why})>
  bannedInUserFacingText = <({RegExp pattern, String why})>[
    (pattern: RegExp(r'\byou should\b', caseSensitive: false), why: 'imperative clinical advice'),
    (
      pattern: RegExp(r'\b(we|the app) recommends?\b', caseSensitive: false),
      why: 'app asserting judgement',
    ),
    (
      pattern: RegExp(r'\brecommended (dose|dosage|amount|rate)\b', caseSensitive: false),
      why: 'dose suggestion',
    ),
    (
      pattern: RegExp(r'\b\d+\s?(ml|mg|cc|iu)\s?/\s?kg\b', caseSensitive: false),
      why: 'a computed dose',
    ),
    // `(?!tic)` is a MEASURED narrowing, ruled 2026-08-01, and it is the one
    // place this list departs from 05 §7.3 as first printed.
    //
    // The alternative means CLINICAL diagnosis — "diagnosis", "diagnose",
    // "diagnosed", "diagnosing" all still fire. It does NOT mean
    // `diagnostic`/`diagnostics`, which is a different word in a different
    // domain and is this project's OWN mandated vocabulary in three places:
    // CLAUDE.md's table ("the diagnostics log" for LocalLog), decision #123
    // ("Settings ▸ Diagnostics shows the last 20 events"), and 04 §8.2's
    // temp directory. Measured before the change: the gate refused the
    // literal 'the diagnostics log' and refused an ARB message "Diagnostics".
    //
    // A rule that refuses the vocabulary its own project mandates acquires an
    // allowlist, then gets weakened, then gets deleted — while guarding
    // §12.2. Narrowing it by one token keeps every clinically dangerous form
    // and removes a whole class of false positives.
    (pattern: RegExp(r'\bdiagnos(?!tic)|\bprognos', caseSensitive: false), why: 'diagnosis'),
    (
      pattern: RegExp(
        r'\b(indicates?|suggests?) (a |an )?(problem|deficiency|infection|disease)\b',
        caseSensitive: false,
      ),
      why: 'clinical inference from data',
    ),
    (
      pattern: RegExp(
        r'\b(normal|healthy|abnormal|too (low|high|light|heavy))\b',
        caseSensitive: false,
      ),
      why: 'clinical judgement on a user value',
    ),
    (
      pattern: RegExp(r'\bcall (the |your )?vet\b', caseSensitive: false),
      why: 'instruction, even a safe-sounding one',
    ),
    (
      pattern: RegExp(r'\b(default|typical|usual|standard) withdrawal\b', caseSensitive: false),
      why: 'implies the app knows a withdrawal period',
    ),
    (
      pattern: RegExp(
        r'\b(compliance|regulatory|statutory|official) record\b',
        caseSensitive: false,
      ),
      why: 'safety rule 3',
    ),
  ];

  /// Reviewed exceptions. **Keys REFERENCE the single definition**; re-typing
  /// the string here would break the *"defined in exactly one place"* guard, and
  /// it would do so in the one file whose job is to hold that guard up.
  static final Map<String, String> allowlist = <String, String>{
    Disclaimers.exportFooter: 'This is the disclaimer itself (safety rule 3).',
    // `Disclaimers.strikeNotice` (N21-T03) is DELIBERATELY NOT HERE. The task
    // said any new const joins this map by reference, and measuring it says
    // otherwise: the notice trips no pattern in `bannedInUserFacingText`, so an
    // entry for it would be dead — and a dead entry weakens the assertion below
    // it, which pins this map at exactly one key. `content_policy_test.dart`
    // asserts the notice is permitted without one, which is the stronger claim.
  };
}

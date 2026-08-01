/// Something the app **observed** about an entry and is telling the user about.
///
/// It has no `fix()`, no `corrected` field and no callback, and it is built that
/// way from the first line: the API surface for mutation does not exist, so no
/// amount of call-site carelessness produces one (05 §7.5). Adding "and here is
/// the value we would have used" is safety rule §12.4 with a friendly face.
///
/// Safety rule §12.4 lives here at the **unrepresentable** level, and it is held
/// again at the unpersistable one: there is no `warnings` column, and
/// `lib/data/` may not import `lib/domain/validation/` at all — the gate row
/// `layer.data_no_validation` is that half.
final class Warning {
  const Warning(this.code, this.message, {this.fieldPath});

  final WarningCode code;

  /// What we observed, **never what to do**. A warning that instructs is advice
  /// (§12.2); a warning that changes a value is a correction (§12.4).
  final String message;

  /// For scroll-to-field, not for editing.
  final String? fieldPath;
}

/// **An export vocabulary, not an implementation detail.**
///
/// The CSV carries a `warnings` column of joined **codes**, never localised
/// messages, so renaming a member after N21 breaks every export ever written.
/// The eleven members and their order are `CONVENTIONS` §2.6's and 05 §7.5's,
/// spelled exactly.
///
/// All eleven land here at N05-T05 rather than one now and ten at N06-T02. That
/// was the choice with the smaller failure mode: writing one member and ten
/// later makes an export vocabulary that is defined twice, and writing all
/// eleven is mechanical and free. N06-T02 finds this enum complete and adds
/// `Reviewed<T>` and `test/policy/warning_has_no_writer_test.dart` beside it.
/// **Where each code is actually raised**, because the next reader's first
/// question is *"who raises this?"* — and three of the four producers are not in
/// the epic that declares the enum.
///
/// | Code | Raised by | Epic |
/// |---|---|---|
/// | `birthTypeLambCountMismatch`, `lambingBeforeSeasonStart`, `lambingInFuture`, `lambingLongBeforeCapture`, `implausibleBirthWeight`, `deathBeforeBirth`, `localDateDisagrees` | `checkLambing`, `lib/domain/validation/lambing_checks.dart` | N06-T03 |
/// | `fosterToSelf` | `checkFoster`, `lib/domain/validation/foster_checks.dart` | N06-T03 |
/// | `clearDateDisagrees` | `checkClearDate`, `lib/domain/validation/treatment_checks.dart` | N05-T05 |
/// | `timeDoesNotExistLocally` | `checkLocalWallTimeExists`, `lib/domain/time/wall_time.dart` | N04-T08 |
/// | `duplicateActiveTag` | **nothing in `CONVENTIONS` §1's tree** | N26 |
///
/// [duplicateActiveTag] has no producer file and **you must not invent one**.
/// There is no `lib/domain/validation/flock_checks.dart` in the tree, and adding
/// one is a tree change needing a numbered ruling. 07 §3.3 computes it in Dart
/// from the same active-tag cache the keypad uses, on the Flock create path, in
/// N26 — it is in no drift statement because it is not in the database.
///
/// `00-README` §10 records a live open contradiction about it: 07 §3.3 says the
/// warning never blocks the create, while 03 §6's partial unique index makes a
/// second *active* animal on the same tag unstorable. One of the two is wrong
/// and it is a domain question. This declaration is the vocabulary N26 needs in
/// order to argue about the behaviour; it is not the resolution.
enum WarningCode {
  birthTypeLambCountMismatch,
  lambingBeforeSeasonStart,
  lambingInFuture,
  lambingLongBeforeCapture,
  implausibleBirthWeight,
  timeDoesNotExistLocally,
  fosterToSelf,
  deathBeforeBirth,
  duplicateActiveTag,
  clearDateDisagrees,
  localDateDisagrees,
}

/// A value that has been looked at by a validator: the **unchanged** value,
/// together with what is questionable about it.
///
/// A screen cannot render the value without seeing the warnings, because they
/// arrive in the same object. That is the whole design — it is why the type
/// exists rather than validators returning a bare `List<Warning>` beside a value
/// somebody has to remember to pair it with.
///
/// **There is deliberately no way to get a "cleaned" value out of it.** No
/// `cleaned`, no `sanitised`, no `normalised`, no `fix()`. [value] is
/// byte-identical to what the user supplied, whitespace and all.
///
/// **It is not `Either`, `Result` or `Validated`.**
/// `Either<Corrected, List<Warning>>` is banned by name (05 §9 row 16). There is
/// no error arm because a warning is never a failure: the write is never
/// blocked, so there is nothing to branch on. A blocked write produces a lost
/// record, which is worse than a warned one — and at 03:20 it is the difference
/// between a record and nothing.
final class Reviewed<T> {
  const Reviewed(this.value, this.warnings);

  /// Byte-identical to what the user supplied.
  final T value;

  final List<Warning> warnings;

  bool get hasWarnings => warnings.isNotEmpty;
}

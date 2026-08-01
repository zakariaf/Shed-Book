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

/// The first of eleven. N06-T02 adds the other ten, additively — its
/// *"eleven members"* assertion is correctly red until then.
enum WarningCode { timeDoesNotExistLocally }

/// Parses a free-text number, **rejecting ambiguity rather than guessing**.
///
/// `'4,3'` may be 4.3 or a mistyped 43, and choosing either is a silent
/// correction (safety rule §12.4). The caller asks; `null` becomes a `Warning`,
/// never a value.
///
/// **This is stricter than 05 §5.4's printed body, deliberately.** As printed,
/// the first guard is `if (commas > 0 && dots > 0) return null;` — feed that
/// `'1,5'` and neither guard fires and it returns 1.5. That is a guess. The
/// document's own comment says guessing `'4,3'` means 43 is a silent correction,
/// and then resolves the same ambiguity in the other direction, which is the
/// same act. A comma is ambiguous in `en_GB` full stop, so any comma returns
/// null. The amendment to §5.4 is raised in the pull request that lands this.
///
/// The cost is near zero, because §5.4 removed the locale problem at the source:
/// weights use the in-app 60 × 60 pt keypad with one decimal key that always
/// emits `.` (#57). This function exists only for any free-text numeric field
/// that survives review — a shrinking set.
///
/// No `package:intl`: `NumberFormat.parse` for a comma locale throws on `'4.3'`,
/// which is *worse* than `double.parse` throwing on `'4,3'`, because a UK
/// shepherd's phone may be set to French (05 §5.4).
///
/// The return type is `double?` and **null is not zero**. `?? 0` anywhere near a
/// call site is §12.4 in its purest form.
double? parseUserNumber(String raw) {
  final String s = raw.replaceAll(' ', '');
  // The load-bearing guard, and the one the amendment above is about.
  if (s.contains(',')) {
    return null;
  }
  // `double.tryParse` is more forgiving than a shepherd's typing warrants: it
  // accepts `'4.'` as 4.0, and `'1e3'`, `'0x10'`, `'Infinity'` and `'NaN'` as
  // themselves. A trailing point is a half-typed number, and every one of the
  // others is a value nobody enters on a keypad with one decimal key. Match the
  // shape first, then parse.
  if (!_plain.hasMatch(s)) {
    return null;
  }
  return double.tryParse(s);
}

final RegExp _plain = RegExp(r'^-?\d+(\.\d+)?$');

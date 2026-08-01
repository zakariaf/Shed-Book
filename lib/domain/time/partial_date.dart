import 'package:shed_book/domain/time/local_date.dart';

/// A date known to the year, sometimes to the month, occasionally to the day.
///
/// A ewe's date of birth is almost never known exactly. **This is a real state,
/// not a missing value**, and it is never padded to 1 January (safety rule
/// §12.4).
///
/// The three stored shapes are exactly the three `ewes.date_of_birth`'s `GLOB`
/// `CHECK` accepts (N07):
///
/// ```
/// 'YYYY'        '2022'        GLOB '[0-9][0-9][0-9][0-9]'
/// 'YYYY-MM'     '2022-03'     GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]'
/// 'YYYY-MM-DD'  '2022-03-14'  GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
/// ```
///
/// There is no `PartialDate.of(Instant)` and no `PartialDate.fromLocalDate`.
/// Narrowing is as banned as widening: nothing in the app has a reason to throw
/// away precision it already has, and a narrowing constructor is a lossy
/// conversion sitting one autocomplete away from the widening one.
///
/// Nothing here reads a clock. *"Is this ewe over four?"* takes an `Instant now`
/// as a parameter at the call site (D3); there is no `age` getter.
extension type const PartialDate._(String iso) {
  static final RegExp _yearOnly = RegExp(r'^\d{4}$');
  static final RegExp _yearMonth = RegExp(r'^\d{4}-\d{2}$');
  static final RegExp _full = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Strict, three-way. Throws rather than coercing.
  ///
  /// A length check is not a validation: `'20x6'` has length 4 and is not a
  /// year (05 §2.2). Shape first, then content — and for the full form,
  /// delegate to [LocalDate.parse], so an impossible day is rejected by the code
  /// that already knows how.
  ///
  /// `'2022-3'` throws, and the padding is not cosmetic. The schema's `GLOB` is
  /// a character-class match, so an unpadded value is unstorable; and the
  /// ordering is lexical over the known prefix, so one unpadded value sorts
  /// `'2022-3'` after `'2022-12'`.
  factory PartialDate.parse(String s) {
    if (_yearOnly.hasMatch(s)) {
      return PartialDate._(s);
    }
    if (_yearMonth.hasMatch(s)) {
      final int month = int.parse(s.substring(5, 7));
      if (month < 1 || month > 12) {
        throw FormatException('Not a real month', s);
      }
      return PartialDate._(s);
    }
    if (_full.hasMatch(s)) {
      return PartialDate._(LocalDate.parse(s).iso);
    }
    throw FormatException('Not YYYY, YYYY-MM or YYYY-MM-DD', s);
  }

  /// Always known.
  int get year => int.parse(iso.substring(0, 4));

  /// Null when the month was never recorded. **Never 1 as a stand-in.**
  int? get month => iso.length >= 7 ? int.parse(iso.substring(5, 7)) : null;

  /// Non-null **only** for the full `'YYYY-MM-DD'` form. There is no other way
  /// to get a `LocalDate` out of a `PartialDate`, and there must never be one.
  ///
  /// `LocalDate(year, month ?? 1, day ?? 1)` is the bug this whole type exists
  /// to prevent. It is one line, it reads as tidy null-safety hygiene, and it
  /// turns *"born sometime in 2022"* into *"born 1 January 2022"* on every ewe
  /// card, every export and every age calculation, for ever. With the return
  /// type nullable there is no lossy conversion to call.
  LocalDate? get exactDate => iso.length == 10 ? LocalDate.parse(iso) : null;

  /// Total. Ties on the known prefix are broken by precision, **least precise
  /// first**: `'2022' < '2022-03' < '2022-03-14' < '2022-04'`.
  ///
  /// A plain method, not `Comparable`: an extension type may only implement a
  /// supertype of its representation, and `String` implements
  /// `Comparable<String>`.
  ///
  /// The tie-break is a decision, not an accident. The alternative — equal, then
  /// unstable — makes a flock list reorder itself between builds.
  int compareTo(PartialDate o) {
    final int shared = iso.length < o.iso.length ? iso.length : o.iso.length;
    final int prefix = iso.substring(0, shared).compareTo(o.iso.substring(0, shared));
    return prefix != 0 ? prefix : iso.length.compareTo(o.iso.length);
  }

  /// `'2022'` · `'March 2022'` · `'14 March 2022'` — **never invents a month or
  /// a day.** An em-dash or a `?` placeholder is worse than the bare year: it
  /// reads as missing data rather than as a fact recorded at the precision it
  /// was known.
  ///
  /// It lives in the domain only because it is a **structural** rendering —
  /// which fields exist — and not a locale-dependent one. The `d MMM y`
  /// formatting of the exact case belongs to `lib/core/ui/formatters.dart` (D4).
  /// If that reads as a stretch in review, the resolution is to move this out,
  /// never to widen [exactDate].
  String get display {
    final int? m = month;
    if (m == null) {
      return '$year';
    }
    final String name = _monthNames[m - 1];
    return iso.length == 10 ? '${int.parse(iso.substring(8, 10))} $name $year' : '$name $year';
  }

  static const List<String> _monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
}

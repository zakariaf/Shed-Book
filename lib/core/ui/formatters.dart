// lib/core/ui/formatters.dart — the ONE package:intl call site under lib/
// outside lib/data/.
//
// Layer rule 7 allows lib/core/ui/ to import package:intl, and this is the file
// it means. A second importer is a second place a date format can be decided,
// and the failure mode of that is a CSV whose two date columns disagree.
//
// TWO RULES THAT DO NOT LOOK LIKE FORMATTING RULES AND ARE:
//
// 1. NO DateFormat RUNS OFF THE ROOT ISOLATE (decision #125). ExportRepository
//    builds the PDF's view model with every date and time ALREADY FORMATTED on
//    the root isolate, and compute() receives strings. That removes the hazard
//    rather than managing it. The code is N21's; the rule is settled here.
//
// 2. CONTROLLERS NEVER FORMAT FOR DISPLAY (02 §4.4 rule 9). "A controller that
//    knows en_GB is a controller that cannot be unit-tested without a locale."
//    These are called from widgets, and the locale arrives through
//    context.localeName.
//
// There is deliberately NO initializeDateFormatting() call in this file. After
// GlobalMaterialLocalizations.delegate loads, DateFormat('d MMM y', 'en_GB')
// just works — the delegate calls initializeDateFormattingCustom for every
// bundled locale, with no async, no assets and no network. A bare unit test has
// no delegate, so that is the TEST's problem to solve, not this file's; adding
// it here would create a second initialisation authority.
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/units/grams.dart';
import 'package:shed_book/domain/units/weight_unit.dart';

/// `11 Mar 2026`. Never `11/03/2026`.
///
/// A numeric date is ambiguous between `en_GB` and `en_US` and the app has users
/// in both conventions the moment a CSV is opened on somebody else's laptop. The
/// spelled month costs three characters and removes the ambiguity entirely.
String formatShedDate(LocalDate d, String localeName) =>
    DateFormat('d MMM y', localeName).format(_utcOf(d));

/// `14 Jul`. The tight-chip form — the pen tile and the withdrawal countdown.
String formatShedDayMonth(LocalDate d, String localeName) =>
    DateFormat('d MMM', localeName).format(_utcOf(d));

/// `03:21`. **Always 24-hour**, and this is the one place the app overrides a
/// system preference — `MediaQuery.alwaysUse24HourFormatOf` is deliberately
/// unread. 10 §9.4 gives three reasons and they are all data-integrity reasons
/// rather than taste:
///
///   * the difference between `03:21` and `15:21` matters in an app used at 3am,
///     and the AM/PM token is exactly the part a tired reader drops;
///   * the medicine book handed to a vet must not carry two spellings of the
///     same instant;
///   * the receipt's uniqueness rule depends on a stable time string.
///
/// **This takes an [Instant], never a `RecordedTime`, and that is the safety
/// design.** A time is never displayed without its provenance label — a bare
/// `03:21` is a review failure (CONVENTIONS §5.4). `RecordedTime.provenanceLabel`
/// is an exhaustive switch in lib/domain/ that can never be empty, and it stays
/// there. Giving this function a `RecordedTime` would let a call site format the
/// instant and drop the label in one step, which is spec §12.5's failure mode
/// wearing a helper's clothes.
String formatShedTime(Instant t, String localeName) =>
    DateFormat('HH:mm', localeName).format(t.local);

/// `4.1 kg` or `9 lb 1 oz`.
///
/// **Never inferred from the locale.** Canonical storage is integer [Grams];
/// [WeightUnit] comes from `unitsProvider` (R68) and conversion happens at the
/// widget boundary only. A UK smallholder may genuinely want lb, and a wrong
/// inference silently mislabels every weight ever recorded.
///
/// The decimal separator is fixed to `.` and never locale-derived: the keypad's
/// decimal key always emits `.` (decision #57). Ambiguity resolution belongs to
/// `parseUserNumber` in lib/domain/units/, which returns null rather than
/// guessing; this is only the rendering half.
String formatShedWeight(Grams g, WeightUnit u, String localeName) => switch (u) {
  WeightUnit.kg => '${g.inKilograms.toStringAsFixed(1)} kg',
  // Decomposed rather than `9.1 lb`, because that is how the trade reads a
  // birthweight.
  //
  // `poundsOunces` AND NOT `wholePounds` BESIDE `remainderOunces.round()`. That
  // was this line until N17-T02, and it rounded twice at two different scales:
  // 4 lb stores as 1814 g, floors to 3 lb with 15.99 oz left, and printed
  // "3 lb 16 oz". Sixteen ounces is a pound. The getter rounds once and carries.
  WeightUnit.lb => () {
    final ({int pounds, int ounces}) p = g.poundsOunces;
    return '${p.pounds} lb ${p.ounces} oz';
  }(),
};

/// A count, grouped by the locale rather than by hand — `1,240` and not `1240`.
///
/// It exists so that every numeral in the app goes through one place and renders
/// into a tabular role (indelible.md §3.5), which is what stops `412` and `108`
/// taking different widths down a column.
String formatShedCount(int n, String localeName) =>
    NumberFormat.decimalPattern(localeName).format(n);

/// An average, to **one decimal**, in the locale's own separator — `2.0` here,
/// `2,0` in a locale that writes it that way.
///
/// **`2.0` AND NEVER `2`.** The trailing zero is what says the number is an
/// average rather than a count: a ewe whose card reads `avg 2` looks like she
/// had two lambs once, and the whole clause is a rate over her lambings. Both
/// digits are forced, so the column does not jitter between `2` and `1.5`.
///
/// It is separate from [formatShedCount] because the two are different claims —
/// a count is exact and an average is not — and a shared formatter would
/// eventually round one of them the other's way.
String formatShedAverage(double v, String localeName) => NumberFormat('0.0', localeName).format(v);

/// The locale every formatter above is passed.
///
/// **Never `null`.** A `DateFormat` with a null locale falls back to the system
/// locale, and in a background isolate that is `en_US` — silently, with no
/// warning. Every call site reaches the locale through here.
///
/// One ordering trap that belongs beside this and lands in `app.dart` (N11-T05):
/// **`en_GB` must not be first in `supportedLocales`.** The correct order is
/// `[Locale('en'), Locale('en','GB'), Locale('en','IE')]` — putting `en_GB`
/// first gives *every English speaker on earth* British formats.
extension ShedLocaleX on BuildContext {
  String get localeName => Localizations.localeOf(this).toString();
}

/// A [LocalDate] as a UTC `DateTime`, which is the only form `DateFormat` can be
/// handed without a zone shifting the civil day. `LocalDate` is a civil date with
/// no instant in it, so building a local `DateTime` here would re-introduce
/// exactly the DST hazard it exists to remove.
DateTime _utcOf(LocalDate d) => DateTime.utc(d.year, d.month, d.day);

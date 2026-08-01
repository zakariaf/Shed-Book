import 'package:drift/drift.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/partial_date.dart';

/// The three converters, in **one file, not a folder** (R21).
///
/// All three are `const`: a `TypeConverter` is constructed once per column
/// declaration, and a non-const one would allocate on every table definition for
/// nothing.
///
/// Every mapping is decision #2's storage shape, and all three are **frozen by
/// N07-T08's snapshot** — not the file, the *representation*. An instant is
/// `INTEGER` epoch millis; a civil date is `TEXT`. Never drift's `dateTime()`
/// (decision #29): it stores either an integer or a text depending on a global
/// build flag, and `store_date_time_values_as_text` flipping later is a silent
/// reinterpretation of every row.
class InstantConverter extends TypeConverter<Instant, int> {
  const InstantConverter();

  @override
  Instant fromSql(int fromDb) => Instant(fromDb);

  @override
  int toSql(Instant value) => value.epochMillis;
}

/// `TEXT`, strict `'YYYY-MM-DD'`, and the identity — [LocalDate] is an extension
/// type over exactly that string, which is what makes `ORDER BY local_date`
/// correct and index-friendly with zero conversion.
class LocalDateConverter extends TypeConverter<LocalDate, String> {
  const LocalDateConverter();

  @override
  LocalDate fromSql(String fromDb) => LocalDate.parse(fromDb);

  @override
  String toSql(LocalDate value) => value.iso;
}

/// `TEXT`, one of `'YYYY'`, `'YYYY-MM'`, `'YYYY-MM-DD'` — the three shapes
/// `ewes.date_of_birth`'s `GLOB` CHECKs accept.
///
/// [PartialDate.parse] throws rather than coercing, so a row that somehow held
/// `'2022-3'` fails loudly on read instead of sorting after `'2022-12'`.
class PartialDateConverter extends TypeConverter<PartialDate, String> {
  const PartialDateConverter();

  @override
  PartialDate fromSql(String fromDb) => PartialDate.parse(fromDb);

  @override
  String toSql(PartialDate value) => value.iso;
}

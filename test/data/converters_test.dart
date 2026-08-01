// test/data/converters_test.dart — the three converters, round-tripped.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/converters.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/partial_date.dart';

void main() {
  test('InstantConverter is UTC epoch millis, both ways', () {
    const InstantConverter c = InstantConverter();
    final Instant i = Instant.fromDateTime(DateTime.utc(2026, 3, 4, 3, 20));

    expect(c.toSql(i), i.epochMillis);
    expect(c.fromSql(i.epochMillis), i);
    expect(c.toSql(c.fromSql(0)), 0, reason: 'the epoch itself round-trips');
    expect(c.toSql(c.fromSql(-1)), -1, reason: 'and so does a pre-epoch instant');
  });

  test('LocalDateConverter is the identity over the strict ISO string', () {
    const LocalDateConverter c = LocalDateConverter();

    expect(c.toSql(LocalDate(2026, 3, 4)), '2026-03-04');
    expect(c.fromSql('2026-03-04'), LocalDate(2026, 3, 4));
    expect(
      c.toSql(LocalDate(7, 1, 1)),
      '0007-01-01',
      reason: 'zero-padded, so ORDER BY is correct',
    );
  });

  test('LocalDateConverter throws on a malformed stored value rather than coercing', () {
    // A row that somehow held '2026-2-3' fails loudly on READ, instead of
    // sorting after '2026-12' for ever.
    const LocalDateConverter c = LocalDateConverter();

    expect(() => c.fromSql('2026-2-3'), throwsFormatException);
    expect(() => c.fromSql('2026-02-30'), throwsFormatException);
  });

  test('PartialDateConverter carries all three shapes and invents nothing', () {
    const PartialDateConverter c = PartialDateConverter();

    for (final String iso in <String>['2022', '2022-03', '2022-03-14']) {
      expect(c.toSql(c.fromSql(iso)), iso, reason: iso);
    }
    final PartialDate yearOnly = c.fromSql('2022');
    expect(yearOnly.month, isNull, reason: 'never padded to January');
    expect(yearOnly.year, 2022);
    expect(() => c.fromSql('2022-3'), throwsFormatException);
  });

  test('an instant recorded in the ambiguous hour round-trips its exact millisecond', () {
    // The DST case, and it is about the STORAGE shape rather than the zone: the
    // converter stores epoch millis, so whichever of the two 01:30 instants Dart
    // chose on 25 October is the one that comes back. Storing a civil string
    // instead — drift's dateTime() under store_date_time_values_as_text — would
    // make the two indistinguishable, for ever, in the one hour a year it
    // matters. That is why decision #29 bans it.
    const InstantConverter c = InstantConverter();
    final int bst = DateTime.utc(2026, 10, 25, 0, 30).millisecondsSinceEpoch;
    final int gmt = DateTime.utc(2026, 10, 25, 1, 30).millisecondsSinceEpoch;

    expect(c.toSql(c.fromSql(bst)), bst);
    expect(c.toSql(c.fromSql(gmt)), gmt);
    expect(bst, isNot(gmt), reason: 'the two candidate instants are distinct integers');
  });

  test('all three converters are const', () {
    // A TypeConverter is constructed once per column declaration; a non-const
    // one allocates on every table definition for nothing.
    const InstantConverter a = InstantConverter();
    const LocalDateConverter b = LocalDateConverter();
    const PartialDateConverter d = PartialDateConverter();

    expect(identical(a, const InstantConverter()), isTrue);
    expect(identical(b, const LocalDateConverter()), isTrue);
    expect(identical(d, const PartialDateConverter()), isTrue);
  });
}
